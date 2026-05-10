"""
journal_diff.py — IMPL-FIX-011 Step 2 paired-canary divergence analyzer
=======================================================================
Compares a rewrite TradeJournal JSONL stream against a legacy MT5 Strategy
Tester Print stream on the same window/symbol, groups events by
(slot_id, event_type, h4_bucket), and ranks per-slot divergence with
hypothesis (a)/(b)/(c)/(d)/(e) classification per IMPL-FIX-011 task block
+ Step 1 paired-canary finding (per-slot eligibility-predicate divergence
hypothesis (e) added as 5th candidate).

Hypotheses (from IMPL-FIX-011 task block + Step 1 artifact):
  (a) Per-slot anti-pyramid H4-bar gate missing — rewrite multi-fills
      within the same H4 bar while legacy fires once
  (b) Xslot helper missing one-shot trigger latch (RunSafePort,
      RunOrderGroup2, RunForceCutloss, ExtraCheckFunction2) — not
      detectable from journal records (helper-level, not slot-level)
  (c) CD-pool demote miscalibrated — `cd_demote_triggered` cadence drift
      vs legacy CD demote events (legacy stream has no CD demote signal,
      so this hypothesis is detectable only by aggregate cadence)
  (d) `entry_*` per-tick Print spam — log-volume defect orthogonal to
      journal records; flagged at file-blob level, not per-slot
  (e) Per-slot eligibility-predicate divergence — rewrite fires slot X
      where legacy doesn't (or vice versa) regardless of pyramid count

Inputs:
  --rewrite <path>   Path to rewrite TradeJournal JSONL (one JSON object/line).
                     Must contain fields: timestamp, event_type, slot_id.
  --legacy  <path>   Path to legacy MT5 Tester Print stream (UTF-8 decoded
                     log; PhoenicisN2.10_stable Print prefix lines).
  --out     <path>   (Optional) Output Markdown report path. If omitted,
                     writes to stdout.
  --json    <path>   (Optional) Sidecar JSON dump of the diff aggregate.

Output:
  Markdown report with:
    1. Per-leg telemetry summary (record counts + slot mix)
    2. Per-(slot, event) divergence ranking (top 10 by |delta|)
    3. Per-H4-bucket drilldown for top-3 divergence slots
    4. Hypothesis (a/b/c/d/e) classification per top divergence source
    5. Decision-gate verdict per IMPL-FIX-011 task block

Design notes:
  - Python stdlib only (no jq, no pandas) — runs in any env per
    parse_baseline.py precedent.
  - Slot ID extracted via CommentParser grammar (helpers/CommentParser.mqh):
    first comma-delimited token of comment shape == canonical slot id.
    Same disambiguation as parse_baseline.py (BR-1.2 longest-prefix).
  - H4 bucket: timestamp floored to nearest 4-hour boundary in UTC
    (00:00, 04:00, 08:00, 12:00, 16:00, 20:00). EURUSD H4 broker bars
    align to UTC+0/+2/+3 EET; UTC bucketing keeps comparison stable
    across DST transitions.
  - Legacy Print stream parsing: anchored on Trade `market buy/sell`
    lines (open vs close discriminated by `, close #N` substring).
    Slot id resolved from the comment-shape Print that immediately
    follows on the same sim_timestamp + (for closes) from the
    `Close good potsition:` Print.

Reference:
  - IMPL-FIX-011 Step 1 artifact: docs/state/_session-handoff/IMPL-FIX-011-q1-paired-20260510.md
  - CommentParser grammar: MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh
  - Precedent: simulation/scripts/parse_baseline.py (HTML/Tester report parser)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

# --------------------------------------------------------------------------- #
# Canonical slot inventory — must mirror MQL5/Experts/PhoenicisNex/helpers/   #
# CommentParser.mqh § "21 Active Slot IDs" + BR-1.1.                          #
# --------------------------------------------------------------------------- #
KNOWN_SLOTS = {
    "C", "D", "F", "J", "H", "K", "G", "G2", "GO", "M",
    "L", "LX", "Q", "R", "I", "P", "T", "S", "B", "BI", "BR",
}

# Legacy P sub-slots (PH/PI/PX) → canonical "P" per parse_baseline.py § slot-disambig
P_SUBSLOTS = {"PH", "PI", "PX"}

# --------------------------------------------------------------------------- #
# Time helpers                                                                #
# --------------------------------------------------------------------------- #
H4_SECONDS = 4 * 3600


def floor_to_h4(dt: datetime) -> datetime:
    """Floor `dt` to the start of its 4-hour UTC bucket (00/04/08/12/16/20)."""
    epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)
    delta = dt.astimezone(timezone.utc) - epoch
    bucket_seconds = (int(delta.total_seconds()) // H4_SECONDS) * H4_SECONDS
    return epoch + _td_seconds(bucket_seconds)


def _td_seconds(seconds: int):
    from datetime import timedelta
    return timedelta(seconds=seconds)


def parse_iso8601(ts: str) -> datetime:
    """Parse rewrite TradeJournal `timestamp` field (ISO-8601 with trailing Z)."""
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    return datetime.fromisoformat(ts)


def parse_legacy_sim_timestamp(s: str) -> datetime | None:
    """Parse legacy MT5 sim-timestamp `YYYY.MM.DD HH:MM:SS` → UTC datetime."""
    try:
        dt = datetime.strptime(s.strip(), "%Y.%m.%d %H:%M:%S")
        return dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


# --------------------------------------------------------------------------- #
# Slot-id extractor — mirrors CommentParser.mqh::ExtractSlotPrefix             #
# --------------------------------------------------------------------------- #
def extract_slot_prefix(comment: str) -> str:
    """Return slot id from `<SLOT>,<body>` comment shape, or "" on miss.

    BR-1.2 longest-prefix-match: literal token before first comma IS the
    canonical slot id. Legacy P sub-slots (PH/PI/PX) collapse to "P".
    Unknown prefixes return "" (caller decides how to log).
    """
    if not comment or "," not in comment:
        return ""
    head = comment.split(",", 1)[0].strip()
    if head in P_SUBSLOTS:
        return "P"
    return head if head in KNOWN_SLOTS else ""


# --------------------------------------------------------------------------- #
# Rewrite JSONL reader                                                        #
# --------------------------------------------------------------------------- #
def load_rewrite_events(path: Path) -> list[dict]:
    """Read TradeJournal JSONL into a list of event dicts.

    Schema-required keys per docs/api-specs/trade-journal-schema.yaml:
      timestamp (ISO-8601), event_type (entry|exit|...), slot_id (canonical)
    Other keys (magic, ticket_id, comment, etc.) preserved as-is.
    """
    events = []
    with path.open("r", encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError as e:
                print(
                    f"[warn] rewrite line {lineno}: JSON decode fail: {e}",
                    file=sys.stderr,
                )
                continue
            ts = rec.get("timestamp")
            if not ts:
                continue
            try:
                dt = parse_iso8601(ts)
            except ValueError:
                continue
            slot = rec.get("slot_id", "")
            # Normalize legacy P sub-slots if rewrite ever emits them (defensive).
            if slot in P_SUBSLOTS:
                slot = "P"
            rec["_dt"] = dt
            rec["_h4_bucket"] = floor_to_h4(dt).isoformat()
            rec["slot_id"] = slot
            events.append(rec)
    return events


# --------------------------------------------------------------------------- #
# Legacy Tester log parser                                                    #
# --------------------------------------------------------------------------- #
RE_LOG_LINE = re.compile(
    r"^(?P<prefix>CS\s+\d+\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+"
    r"(?P<source>[^\t]+?)\s+"
    r"(?P<rest>.*)$"
)
RE_PHOENICIS_PRINT = re.compile(
    r"^PhoenicisN2\.10_stable\s*\(EURUSD,H4\)$"
)
RE_TRADE_LABEL = re.compile(r"^Trade$")
RE_SIM_TS = re.compile(r"^(?P<ts>\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2}:\d{2})\s{2,}(?P<msg>.*)$")
RE_TRADE_OPEN = re.compile(
    r"^market\s+(?P<dir>buy|sell)\s+(?P<lot>\d+\.\d+)\s+EURUSD"
    r"(?!\s*,\s*close)"  # negative lookahead: NOT a close
)
RE_TRADE_CLOSE = re.compile(
    r"^market\s+(?P<dir>buy|sell)\s+(?P<lot>\d+\.\d+)\s+EURUSD\s*,\s*close\s+#(?P<ticket>\d+)"
)
RE_TRADE_END_OF_TEST = re.compile(r"^position closed due end of test")
RE_CLOSE_GOOD_POSITION = re.compile(r"^Close good potsition:\s*(?P<comment>.+)$")
RE_CLOSE_BY = re.compile(r"^\*\s*Close by\s+(?P<reason>.+)$")
RE_ORDER_OPEN = re.compile(r"^OrderOpen:(?P<slot>[A-Z][A-Z0-9]*)\s+(?P<comment>.+)$")
RE_COMMENT_SHAPE = re.compile(r"^(?P<head>[A-Z][A-Z0-9]*),")


def _split_log_line(line: str) -> tuple[str, str] | None:
    """Split a Tester log line into (source_kind, after-source-text).

    Returns:
      ("Trade",      "<sim-ts>   market ...")              if this is a Trade event
      ("Phoenicis",  "<sim-ts>   <message body>")          if this is an EA Print
      None                                                  for everything else (Trades,
                                                            History, Symbols, Tester, ...)
    """
    # Format: "CS\t<thread>\t<HH:MM:SS.mmm>\t<source>\t<rest>"
    parts = line.rstrip("\n").split("\t")
    if len(parts) < 5:
        return None
    source = parts[3].strip()
    rest = "\t".join(parts[4:]).strip()
    if RE_TRADE_LABEL.match(source):
        return ("Trade", rest)
    if RE_PHOENICIS_PRINT.match(source):
        return ("Phoenicis", rest)
    return None


def _strip_sim_ts(rest: str) -> tuple[datetime | None, str]:
    """From `YYYY.MM.DD HH:MM:SS   <body>` extract (datetime, body)."""
    m = RE_SIM_TS.match(rest)
    if not m:
        return (None, rest)
    return (parse_legacy_sim_timestamp(m.group("ts")), m.group("msg").strip())


def load_legacy_events(path: Path) -> list[dict]:
    """Parse legacy Tester log into a list of strategy-side events.

    Each event dict has:
      timestamp (datetime, UTC)
      event_type ('entry' or 'exit')
      slot_id (canonical, '' if unresolved)
      comment (the comment shape that disambiguated the slot, '' if from `Close by`)
      direction ('buy' or 'sell')
      lot (float)
      ticket_id (int, only set for closes)
      _h4_bucket (ISO-8601 string)
      _resolved_via ('order_open' | 'comment_shape' | 'close_good_position' | 'close_by_phrase' | 'unresolved')
    """
    # Read lines into memory — Tester logs for Q1 are ~30 KB; 5-yr would be larger
    # but this script targets paired-canary windows where rewrite log is the bulk.
    raw_lines = path.read_text(encoding="utf-8", errors="replace").splitlines()

    # Pre-classify each line into (source_kind, sim_ts, body, raw)
    parsed: list[dict] = []
    for raw in raw_lines:
        sp = _split_log_line(raw)
        if sp is None:
            continue
        kind, rest = sp
        sim_ts, body = _strip_sim_ts(rest)
        parsed.append({"kind": kind, "sim_ts": sim_ts, "body": body, "raw": raw})

    events: list[dict] = []

    for i, p in enumerate(parsed):
        if p["kind"] != "Trade":
            continue
        body = p["body"]
        sim_ts = p["sim_ts"]
        if sim_ts is None:
            continue
        if RE_TRADE_END_OF_TEST.match(body):
            continue  # Tester forced closure; not strategy-side

        m_close = RE_TRADE_CLOSE.match(body)
        if m_close:
            ticket = int(m_close.group("ticket"))
            direction = m_close.group("dir")
            lot = float(m_close.group("lot"))
            slot, comment, via = _resolve_close_slot(parsed, i)
            events.append({
                "timestamp": sim_ts,
                "event_type": "exit",
                "slot_id": slot,
                "comment": comment,
                "direction": direction,
                "lot": lot,
                "ticket_id": ticket,
                "_h4_bucket": floor_to_h4(sim_ts).isoformat(),
                "_resolved_via": via,
            })
            continue

        m_open = RE_TRADE_OPEN.match(body)
        if m_open:
            direction = m_open.group("dir")
            lot = float(m_open.group("lot"))
            slot, comment, via = _resolve_open_slot(parsed, i)
            events.append({
                "timestamp": sim_ts,
                "event_type": "entry",
                "slot_id": slot,
                "comment": comment,
                "direction": direction,
                "lot": lot,
                "ticket_id": None,
                "_h4_bucket": floor_to_h4(sim_ts).isoformat(),
                "_resolved_via": via,
            })
            continue

    return events


def _is_trade_action(body: str) -> bool:
    """True iff this Trade-source body is an actual market action (open or
    close), not an informational `deal performed` / `order performed` /
    `take profit triggered` follow-up. Used to bound the print scan.
    """
    return bool(RE_TRADE_OPEN.match(body) or RE_TRADE_CLOSE.match(body))


def _resolve_open_slot(parsed: list[dict], anchor_idx: int) -> tuple[str, str, str]:
    """For a `market buy/sell` open at parsed[anchor_idx], scan forward up
    to the NEXT trade-action event (market buy/sell or close) for the
    slot-disambiguating comment-shape line. Prefer `OrderOpen:<SLOT>` Print
    when present.

    Bounded by next trade action (NOT every Trade-source line — MT5 emits
    `deal performed` / `order performed` as Trade-source informational
    follow-ups on the same sim_timestamp, which must NOT terminate the
    print scan).
    """
    fallback_comment_shape = None
    for j in range(anchor_idx + 1, len(parsed)):
        q = parsed[j]
        if q["kind"] == "Trade" and _is_trade_action(q["body"]):
            break
        if q["kind"] != "Phoenicis":
            continue
        body = q["body"]
        m_oo = RE_ORDER_OPEN.match(body)
        if m_oo:
            slot_raw = m_oo.group("slot")
            comment = m_oo.group("comment").strip()
            slot = _normalize_slot(slot_raw)
            return (slot, comment, "order_open")
        m_cs = RE_COMMENT_SHAPE.match(body)
        if m_cs and fallback_comment_shape is None:
            head = m_cs.group("head")
            slot = _normalize_slot(head)
            if slot:
                fallback_comment_shape = (slot, body)
    if fallback_comment_shape:
        return (fallback_comment_shape[0], fallback_comment_shape[1], "comment_shape")
    return ("", "", "unresolved")


def _resolve_close_slot(parsed: list[dict], anchor_idx: int) -> tuple[str, str, str]:
    """For a `market ..., close #N` close at parsed[anchor_idx], scan forward
    until the next Trade event for either `Close good potsition: <comment>`
    (preferred) or fall back to parsing slot from `* Close by <reason>` phrase.
    Hard stop on next Trade prevents attributing the NEXT trade's prints.
    """
    fallback_close_by_slot = None
    fallback_close_by_text = None
    for j in range(anchor_idx + 1, len(parsed)):
        q = parsed[j]
        if q["kind"] == "Trade" and _is_trade_action(q["body"]):
            break
        if q["kind"] != "Phoenicis":
            continue
        body = q["body"]
        m_cgp = RE_CLOSE_GOOD_POSITION.match(body)
        if m_cgp:
            comment = m_cgp.group("comment").strip()
            slot = extract_slot_prefix(comment)
            if slot:
                return (slot, comment, "close_good_position")
        m_cb = RE_CLOSE_BY.match(body)
        if m_cb and fallback_close_by_slot is None:
            reason = m_cb.group("reason").strip()
            # Pattern A: "Close <SLOT> <suffix>"  e.g. "Close T Top Band"
            # Pattern B: "ExtraTakeProfit <SLOT> <suffix>" e.g. "ExtraTakeProfit M NN"
            # Pattern C: "ExtraForceTakeProfit [N]" — no slot info; skip
            tokens = reason.split()
            slot_guess = ""
            if len(tokens) >= 2:
                if tokens[0] == "Close" and tokens[1] in KNOWN_SLOTS:
                    slot_guess = tokens[1]
                elif tokens[0] == "ExtraTakeProfit" and tokens[1] in KNOWN_SLOTS:
                    slot_guess = tokens[1]
            if slot_guess:
                fallback_close_by_slot = slot_guess
                fallback_close_by_text = reason
    if fallback_close_by_slot:
        return (fallback_close_by_slot, fallback_close_by_text or "", "close_by_phrase")
    return ("", "", "unresolved")


def _normalize_slot(slot_raw: str) -> str:
    """Normalize a raw `OrderOpen:<X>` slot label to canonical 21-slot inventory."""
    if slot_raw in P_SUBSLOTS:
        return "P"
    return slot_raw if slot_raw in KNOWN_SLOTS else ""


# --------------------------------------------------------------------------- #
# Diff aggregator                                                             #
# --------------------------------------------------------------------------- #
def aggregate(events: list[dict], leg_name: str) -> dict:
    """Aggregate events into nested counters.

    Returns:
      {
        'leg': leg_name,
        'total': int,
        'by_event_type': Counter,
        'by_slot': Counter,                       # entries only
        'by_slot_event': dict[(slot, event)] = int,
        'by_slot_event_bucket': dict[(slot, event, bucket)] = int,
      }
    """
    total = 0
    by_event_type: Counter = Counter()
    by_slot: Counter = Counter()
    by_slot_event: dict = defaultdict(int)
    by_slot_event_bucket: dict = defaultdict(int)
    unresolved = 0
    for e in events:
        slot = e.get("slot_id", "")
        event_type = e.get("event_type", "")
        bucket = e.get("_h4_bucket", "")
        total += 1
        by_event_type[event_type] += 1
        if event_type == "entry":
            by_slot[slot or "<unresolved>"] += 1
        if not slot:
            unresolved += 1
            continue
        by_slot_event[(slot, event_type)] += 1
        by_slot_event_bucket[(slot, event_type, bucket)] += 1
    return {
        "leg": leg_name,
        "total": total,
        "unresolved": unresolved,
        "by_event_type": by_event_type,
        "by_slot": by_slot,
        "by_slot_event": dict(by_slot_event),
        "by_slot_event_bucket": dict(by_slot_event_bucket),
    }


def diff_per_slot_event(rewrite: dict, legacy: dict) -> list[dict]:
    """Produce per-(slot, event) divergence rows sorted by |delta| desc.

    Each row:
      {
        'slot_id', 'event_type',
        'rewrite_count', 'legacy_count', 'delta', 'abs_delta',
        'rewrite_buckets' (count of distinct H4 buckets the rewrite fired in),
        'legacy_buckets'  (same for legacy),
        'max_intra_bucket_rewrite' (max count rewrite emitted in any single
                                    H4 bucket — anti-pyramid signal for
                                    hypothesis (a)),
        'max_intra_bucket_legacy',
      }
    """
    keys = set(rewrite["by_slot_event"].keys()) | set(legacy["by_slot_event"].keys())
    rows = []
    for (slot, event) in keys:
        rc = rewrite["by_slot_event"].get((slot, event), 0)
        lc = legacy["by_slot_event"].get((slot, event), 0)
        delta = rc - lc
        rewrite_buckets = sum(
            1 for (s, e, b) in rewrite["by_slot_event_bucket"]
            if s == slot and e == event
        )
        legacy_buckets = sum(
            1 for (s, e, b) in legacy["by_slot_event_bucket"]
            if s == slot and e == event
        )
        max_intra_rw = max(
            (v for (s, e, b), v in rewrite["by_slot_event_bucket"].items()
             if s == slot and e == event),
            default=0,
        )
        max_intra_lg = max(
            (v for (s, e, b), v in legacy["by_slot_event_bucket"].items()
             if s == slot and e == event),
            default=0,
        )
        rows.append({
            "slot_id": slot,
            "event_type": event,
            "rewrite_count": rc,
            "legacy_count": lc,
            "delta": delta,
            "abs_delta": abs(delta),
            "rewrite_buckets": rewrite_buckets,
            "legacy_buckets": legacy_buckets,
            "max_intra_bucket_rewrite": max_intra_rw,
            "max_intra_bucket_legacy": max_intra_lg,
        })
    rows.sort(key=lambda r: (-r["abs_delta"], r["slot_id"], r["event_type"]))
    return rows


def classify_hypothesis(row: dict) -> tuple[str, str]:
    """Classify a divergence row into a primary hypothesis (a/b/c/d/e/none).

    Returns (label, rationale).

    Heuristic:
      - If both rewrite_count and legacy_count are 0 → 'none' (not a divergence)
      - If rewrite_count > 0 AND legacy_count == 0 → '(e) eligibility' (rewrite-only)
      - If rewrite_count == 0 AND legacy_count > 0 → '(e) eligibility' (legacy-only)
      - If both > 0 AND max_intra_bucket_rewrite >= 2 AND max_intra_bucket_rewrite >
        max_intra_bucket_legacy → '(a) anti-pyramid' (multi-fill within H4)
      - Else → '(e) eligibility' if |delta| >= 2 else '(none) parity'
    """
    rc = row["rewrite_count"]
    lc = row["legacy_count"]
    if rc == 0 and lc == 0:
        return ("(none)", "no events on either leg")
    if rc > 0 and lc == 0:
        return (
            "(e) eligibility",
            f"rewrite-only — fires {rc} entries in {row['rewrite_buckets']} H4 buckets while legacy is silent",
        )
    if rc == 0 and lc > 0:
        return (
            "(e) eligibility",
            f"legacy-only — fires {lc} entries while rewrite is silent",
        )
    # Both legs active
    if (
        row["max_intra_bucket_rewrite"] >= 2
        and row["max_intra_bucket_rewrite"] > row["max_intra_bucket_legacy"]
    ):
        return (
            "(a) anti-pyramid",
            f"rewrite multi-fills (max {row['max_intra_bucket_rewrite']}/H4) where legacy fires {row['max_intra_bucket_legacy']}/H4",
        )
    if row["abs_delta"] >= 2:
        return (
            "(e) eligibility",
            f"both legs active but count drift |delta|={row['abs_delta']} (rewrite={rc} vs legacy={lc})",
        )
    return ("(none) parity", f"rewrite={rc} ≈ legacy={lc} within ±1")


# --------------------------------------------------------------------------- #
# Markdown report writer                                                      #
# --------------------------------------------------------------------------- #
def _fmt_h4_bucket(iso_str: str) -> str:
    """Pretty-format a UTC ISO bucket string for the report."""
    if not iso_str:
        return "-"
    try:
        dt = datetime.fromisoformat(iso_str)
        return dt.strftime("%Y-%m-%d %H:%MZ")
    except ValueError:
        return iso_str


def render_markdown(
    rewrite_events: list[dict],
    legacy_events: list[dict],
    rewrite_agg: dict,
    legacy_agg: dict,
    rows: list[dict],
    rewrite_path: Path,
    legacy_path: Path,
) -> str:
    out: list[str] = []
    out.append("# IMPL-FIX-011 Step 2 — Q1 2021 Paired Journal Diff")
    out.append("")
    out.append(f"**Generated:** {datetime.now(timezone.utc).isoformat(timespec='seconds')}")
    out.append(f"**Script:** `simulation/scripts/journal_diff.py`")
    out.append(f"**Inputs:**")
    out.append(f"- Rewrite: `{rewrite_path}` ({len(rewrite_events)} events)")
    out.append(f"- Legacy:  `{legacy_path}` ({len(legacy_events)} events)")
    out.append("")

    # Section 1 — per-leg telemetry
    out.append("## 1. Per-leg telemetry")
    out.append("")
    out.append("| Metric | Rewrite | Legacy |")
    out.append("|---|---|---|")
    out.append(f"| Total events | {rewrite_agg['total']} | {legacy_agg['total']} |")
    out.append(f"| Entry events | {rewrite_agg['by_event_type'].get('entry', 0)} | {legacy_agg['by_event_type'].get('entry', 0)} |")
    out.append(f"| Exit events | {rewrite_agg['by_event_type'].get('exit', 0)} | {legacy_agg['by_event_type'].get('exit', 0)} |")
    out.append(f"| Unresolved slot_id | {rewrite_agg['unresolved']} | {legacy_agg['unresolved']} |")
    out.append("")

    out.append("### 1a. Entry slot mix (per leg)")
    out.append("")
    out.append("| Slot | Rewrite entries | Legacy entries |")
    out.append("|---|---:|---:|")
    all_slots = sorted(
        set(rewrite_agg["by_slot"].keys()) | set(legacy_agg["by_slot"].keys()),
        key=lambda s: (s != "<unresolved>", s),
    )
    for slot in all_slots:
        rc = rewrite_agg["by_slot"].get(slot, 0)
        lc = legacy_agg["by_slot"].get(slot, 0)
        marker = ""
        if rc > 0 and lc == 0:
            marker = " 🟥 rewrite-only"
        elif lc > 0 and rc == 0:
            marker = " 🟦 legacy-only"
        elif rc != lc:
            marker = " ⚠️ count drift"
        out.append(f"| `{slot}` | {rc} | {lc} |{marker} |")
    out.append("")

    # Section 2 — per-(slot, event) divergence ranking
    out.append("## 2. Per-(slot, event) divergence ranking — top 10")
    out.append("")
    out.append("| Rank | Slot | Event | Rewrite | Legacy | Δ | \\|Δ\\| | RW buckets | LG buckets | Max RW/H4 | Max LG/H4 | Hypothesis | Rationale |")
    out.append("|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|")
    top_rows = [r for r in rows if r["abs_delta"] > 0][:10]
    for i, r in enumerate(top_rows, 1):
        h, rationale = classify_hypothesis(r)
        out.append(
            f"| {i} | `{r['slot_id']}` | {r['event_type']} | "
            f"{r['rewrite_count']} | {r['legacy_count']} | {r['delta']:+d} | {r['abs_delta']} | "
            f"{r['rewrite_buckets']} | {r['legacy_buckets']} | "
            f"{r['max_intra_bucket_rewrite']} | {r['max_intra_bucket_legacy']} | "
            f"**{h}** | {rationale} |"
        )
    out.append("")

    # Section 3 — H4 bucket drilldown for top-3 slots
    out.append("## 3. H4-bucket drilldown — top-3 divergence slots (entries only)")
    out.append("")
    top3_slots = []
    for r in rows:
        if r["event_type"] != "entry":
            continue
        if r["abs_delta"] == 0:
            continue
        if r["slot_id"] not in top3_slots:
            top3_slots.append(r["slot_id"])
        if len(top3_slots) >= 3:
            break
    for slot in top3_slots:
        out.append(f"### Slot `{slot}` — entry events per H4 bucket")
        out.append("")
        rw_buckets = {
            b: v for (s, e, b), v in rewrite_agg["by_slot_event_bucket"].items()
            if s == slot and e == "entry"
        }
        lg_buckets = {
            b: v for (s, e, b), v in legacy_agg["by_slot_event_bucket"].items()
            if s == slot and e == "entry"
        }
        all_buckets = sorted(set(rw_buckets.keys()) | set(lg_buckets.keys()))
        if not all_buckets:
            out.append("(no entries on either leg)")
            out.append("")
            continue
        out.append("| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |")
        out.append("|---|---:|---:|---:|")
        for b in all_buckets:
            rc = rw_buckets.get(b, 0)
            lc = lg_buckets.get(b, 0)
            out.append(f"| {_fmt_h4_bucket(b)} | {rc} | {lc} | {rc - lc:+d} |")
        out.append("")

    # Section 4 — hypothesis classification rollup
    out.append("## 4. Hypothesis classification rollup (top-10 divergence)")
    out.append("")
    hclass: Counter = Counter()
    rationales: dict[str, list[str]] = defaultdict(list)
    for r in top_rows:
        h, _ = classify_hypothesis(r)
        hclass[h] += 1
        rationales[h].append(f"{r['slot_id']}/{r['event_type']} (|Δ|={r['abs_delta']})")
    out.append("| Hypothesis | Top-10 rows | Slots/events |")
    out.append("|---|---:|---|")
    for h in sorted(hclass.keys(), key=lambda x: -hclass[x]):
        examples = ", ".join(rationales[h][:6])
        out.append(f"| {h} | {hclass[h]} | {examples} |")
    out.append("")

    # Section 5 — IMPL-FIX-011 task-block decision gate
    out.append("## 5. IMPL-FIX-011 decision gate (per task-block Step 2 §)")
    out.append("")
    # Count distinct slots in top divergence (any |Δ| ≥ 1, entry events only)
    diverging_entry_slots = sorted({
        r["slot_id"] for r in rows
        if r["event_type"] == "entry" and r["abs_delta"] >= 1
    })
    n_div = len(diverging_entry_slots)
    out.append(f"Distinct entry slots with |Δ| ≥ 1: **{n_div}** — `{', '.join(diverging_entry_slots) if diverging_entry_slots else 'none'}`")
    out.append("")
    if n_div <= 3:
        out.append("**Verdict — concentrated:** divergence is concentrated in 1-3 slots → Steps 3-4 sufficient at task-block estimate (~60-180 min for Step 3; cap 3 iterations Step 4).")
    elif n_div <= 7:
        out.append("**Verdict — moderate:** divergence spans 4-7 slots → Steps 3-4 likely 1-2 sessions; revisit scope at Step 4 iteration 1 if divergence reduction < 75%.")
    else:
        out.append(f"**Verdict — dispersed (escalate):** divergence spans {n_div}+ slots → escalate scope estimate to upper bound per task-block (8 hr / 3 sessions). Step 3 patches must be batched + tested incrementally to avoid regressions.")
    out.append("")

    # Section 6 — hypothesis (d) per-tick spam note (file-level, orthogonal)
    out.append("## 6. Hypothesis (d) per-tick `entry_*` Print spam — out-of-band note")
    out.append("")
    out.append("Hypothesis (d) is a logging-volume defect orthogonal to journal records:")
    out.append("the `entry_signal` / `entry_buy` / `entry_sell` Print emits fire per-tick")
    out.append("when conditions persist, but they do NOT show up in this diff because")
    out.append("`TradeJournal` (the JSONL stream) emits one record per actual `OrderSend`")
    out.append("not per Print. Step 1 artifact §4 already empirically confirmed this")
    out.append("hypothesis (1.41 GB tester log over Q1 ≈ 30 GB / 5-yr extrapolation).")
    out.append("")
    out.append("Step 3 of IMPL-FIX-011 must therefore *also* sweep the per-tick `entry_*`")
    out.append("Prints (mirror the IMPL-FIX-008 R-10 stub-suppress pattern that targeted")
    out.append("`exit_profit_gate`) — this is gating on Step 5 5-yr Bucket A retry being")
    out.append("operator-feasible (~30 GB log breaks the iconv decode budget).")
    out.append("")

    # Section 7 — hypothesis (b) and (c) status notes
    out.append("## 7. Hypothesis (b) xslot helpers + (c) CD-pool demote — status")
    out.append("")
    out.append("- **(b)** `RunSafePort` / `RunOrderGroup2` / `RunForceCutloss` /")
    out.append("  `ExtraCheckFunction2` — these helpers do NOT emit slot-tagged")
    out.append("  journal records (they emit Logger.Info events with helper-level tags);")
    out.append("  this diff cannot detect their per-tick emit pattern. Q1 sample did NOT")
    out.append("  surface their spam in Step 1 5-MB tail; defer per task-block guidance")
    out.append("  ('apply only if Step 2 journal-diff shows per-tick emit on those")
    out.append("  helpers — defensive deferral'). Reconfirm at Step 5 5-yr Bucket A.")
    out.append("- **(c)** CD-pool demote — `cd_demote_triggered` Logger.Info emit is")
    out.append("  not a TradeJournal record (no `event_type=cd_demote_triggered` in the")
    out.append("  rewrite JSONL); detection requires Tester log grep. Defer until")
    out.append("  hypothesis (d) per-tick `entry_*` spam is suppressed in Step 3 (the")
    out.append("  spam currently drowns CD-demote Print signal in Step 1 1.41 GB log).")
    out.append("")

    # Section 8 — caveat / data quality
    out.append("## 8. Data-quality caveats")
    out.append("")
    out.append("- Legacy parser resolves slot_id via 4 mechanisms (priority order):")
    out.append("  `OrderOpen:<SLOT>` Print prefix → comment-shape Print → `Close good")
    out.append("  potsition:` comment → `* Close by` phrase pattern. Each event records")
    out.append("  which mechanism resolved it (see `_resolved_via` field in JSON")
    out.append("  sidecar).")
    out.append("- `<unresolved>` rows in section 1a are events where none of the 4")
    out.append("  mechanisms succeeded — typically Tester forced end-of-test closes")
    out.append("  (filtered) or unusual close paths. If unresolved count is non-zero,")
    out.append("  inspect raw log for missed cases before trusting top-10 ranking.")
    out.append("- H4 bucket boundaries are UTC-aligned (00/04/08/12/16/20). EURUSD H4")
    out.append("  broker bars align to UTC+0/+2/+3 EET; UTC bucketing keeps comparison")
    out.append("  stable across DST. Per-bar slot eligibility is approximated by H4")
    out.append("  bucket count (off-by-one possible at DST transitions; not an issue")
    out.append("  for Q1 2021 which has no DST switch in the EURUSD window).")
    out.append("")
    return "\n".join(out) + "\n"


# --------------------------------------------------------------------------- #
# JSON sidecar writer                                                         #
# --------------------------------------------------------------------------- #
def _row_to_json(row: dict) -> dict:
    h, rationale = classify_hypothesis(row)
    out = dict(row)
    out["hypothesis"] = h
    out["rationale"] = rationale
    return out


def render_json(
    rewrite_events: list[dict],
    legacy_events: list[dict],
    rewrite_agg: dict,
    legacy_agg: dict,
    rows: list[dict],
    rewrite_path: Path,
    legacy_path: Path,
) -> dict:
    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "rewrite_input": str(rewrite_path),
        "legacy_input": str(legacy_path),
        "rewrite_event_count": len(rewrite_events),
        "legacy_event_count": len(legacy_events),
        "rewrite_unresolved": rewrite_agg["unresolved"],
        "legacy_unresolved": legacy_agg["unresolved"],
        "rewrite_by_event_type": dict(rewrite_agg["by_event_type"]),
        "legacy_by_event_type": dict(legacy_agg["by_event_type"]),
        "rewrite_by_slot": dict(rewrite_agg["by_slot"]),
        "legacy_by_slot": dict(legacy_agg["by_slot"]),
        "divergence_rows": [_row_to_json(r) for r in rows],
    }


# --------------------------------------------------------------------------- #
# Entry point                                                                 #
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rewrite", required=True, type=Path, help="Rewrite TradeJournal JSONL path")
    ap.add_argument("--legacy", required=True, type=Path, help="Legacy MT5 Tester Print stream path (UTF-8)")
    ap.add_argument("--out", type=Path, default=None, help="Markdown report output path (default stdout)")
    ap.add_argument("--json", type=Path, default=None, help="JSON sidecar output path (optional)")
    args = ap.parse_args()

    if not args.rewrite.exists():
        print(f"[error] rewrite input not found: {args.rewrite}", file=sys.stderr)
        return 2
    if not args.legacy.exists():
        print(f"[error] legacy input not found: {args.legacy}", file=sys.stderr)
        return 2

    rewrite_events = load_rewrite_events(args.rewrite)
    legacy_events = load_legacy_events(args.legacy)

    rewrite_agg = aggregate(rewrite_events, "rewrite")
    legacy_agg = aggregate(legacy_events, "legacy")
    rows = diff_per_slot_event(rewrite_agg, legacy_agg)

    md = render_markdown(
        rewrite_events, legacy_events, rewrite_agg, legacy_agg, rows,
        args.rewrite, args.legacy,
    )
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(md, encoding="utf-8")
        print(f"[ok] markdown report -> {args.out}")
    else:
        sys.stdout.write(md)

    if args.json:
        payload = render_json(
            rewrite_events, legacy_events, rewrite_agg, legacy_agg, rows,
            args.rewrite, args.legacy,
        )
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"[ok] json sidecar  -> {args.json}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
