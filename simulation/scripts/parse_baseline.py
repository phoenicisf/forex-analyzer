"""
parse_baseline.py — MT5 Strategy Tester report per-slot baseline parser
=======================================================================
Extracts per-slot trade statistics from a MetaTrader 5 Strategy Tester HTML
report (UTF-16 LE with BOM) and emits a JSON file suitable for regression
regression comparison against the PhoenicisNex rewrite.

Output schema:
  {
    "schema_version": 1,
    "report_source": "<filename>",
    "extracted_at": "<ISO-8601 UTC>",
    "total_net_profit": <float>,
    "total_trades": <int>,
    "slots": [
      {"slot_id": "<id>", "count": <int>, "net_pnl": <float>, "win_rate": <float|null>},
      ...  (exactly 21 entries, canonical order)
    ]
  }

Slot disambiguation (BR-1.2 longest-prefix match):
  The comment column of each MT5 'in' deal encodes the slot ID as the
  substring before the first comma, e.g. "G2,reason=..." → slot "G2".
  Longer prefixes (G2, BI, BR, LX) must resolve before shorter ones (G, B, L).
  Since the literal prefix IS the slot ID (no ambiguity in the text), simple
  split-on-comma extraction is sufficient.

  Legacy P sub-slots (PH, PI, PX) from the old EA map to canonical slot "P".
  Unrecognised prefixes (no comma, empty, 'sl ...', 'tp ...') appear only on
  closing orders and are ignored.

Position matching (FIFO per volume):
  MT5 Deals table interleaves 'in' (open) and 'out' (close) deal rows.
  Profit is carried on the 'out' row; the slot label is on the 'in' row.
  Match: each 'out' deal (type, volume) closes the oldest open 'in' deal with
  the OPPOSITE trade type and the SAME volume. This FIFO queue is keyed by
  (trade_type, volume_str) where type pairs are sell→buy and buy→sell.
  Swap is added to the 'out' deal's profit to match MT5 "Net Profit" semantics.

Win rate rule:
  A trade (position) is a win if its net_pnl (profit + swap) > 0.
  Zero-profit trades count as losses (MT5 convention for commission-free accounts).
  win_rate = wins / count  if count > 0  else null.

Usage:
  python parse_baseline.py [--input PATH] [--output PATH]

Defaults:
  --input   docs/foundation-input-sources/ReportTester-25045474.html
  --output  docs/state/baseline-per-slot.json
"""

import argparse
import json
import re
import sys
from collections import deque
from datetime import datetime, timezone
from html.parser import HTMLParser


# ---------------------------------------------------------------------------
# Canonical slot order (21 slots, Phase 1; Slot U deleted per OQ-8)
# ---------------------------------------------------------------------------
CANONICAL_SLOTS = [
    "C", "D", "F", "J", "H", "K", "G", "G2", "GO",
    "M", "L", "LX", "Q", "R", "I", "P", "T", "S",
    "B", "BR", "BI",
]

# ---------------------------------------------------------------------------
# Legacy sub-slot prefixes from the old EA that map to canonical slot "P".
# PH = P Hedge, PI = P Inversion, PX = P Exit — all sub-strategies of slot P.
# ---------------------------------------------------------------------------
LEGACY_P_PREFIXES = {"PH", "PI", "PX"}

# ---------------------------------------------------------------------------
# Closing trade type is the opposite of the opening type.
# ---------------------------------------------------------------------------
OPPOSITE_TYPE = {"sell": "buy", "buy": "sell"}


# ---------------------------------------------------------------------------
# HTML parser — extract table rows from the MT5 report
# ---------------------------------------------------------------------------

class _TableRowParser(HTMLParser):
    """Collect all <tr> blocks as lists of <td> text content."""

    def __init__(self):
        super().__init__()
        self.rows = []          # list of list[str]
        self._current_row = None
        self._current_cell = None
        self._in_cell = False
        self._depth = 0         # nested tag depth inside <td>

    def handle_starttag(self, tag, attrs):
        if tag == "tr":
            self._current_row = []
        elif tag == "td" and self._current_row is not None:
            self._current_cell = []
            self._in_cell = True
            self._depth = 0
        elif self._in_cell:
            self._depth += 1

    def handle_endtag(self, tag):
        if tag == "tr" and self._current_row is not None:
            self.rows.append(self._current_row)
            self._current_row = None
        elif tag == "td" and self._in_cell and self._depth == 0:
            self._current_row.append("".join(self._current_cell).strip())
            self._current_cell = None
            self._in_cell = False
        elif self._in_cell and self._depth > 0:
            self._depth -= 1

    def handle_data(self, data):
        if self._in_cell:
            self._current_cell.append(data)


def _parse_html_rows(path: str) -> list:
    """Read UTF-16 LE HTML and return all table rows as lists of cell text."""
    with open(path, encoding="utf-16") as fh:
        html = fh.read()
    parser = _TableRowParser()
    parser.feed(html)
    return parser.rows


# ---------------------------------------------------------------------------
# Summary section — extract total net profit
# ---------------------------------------------------------------------------

def _extract_total_net_profit(html_rows: list) -> float:
    """
    Scan rows for the 'Total Net Profit:' label and return the value.
    The MT5 report uses a non-breaking space (\\xa0) as a thousands separator.
    """
    for row in html_rows:
        for i, cell in enumerate(row):
            if "Total Net Profit" in cell and i + 1 < len(row):
                raw = row[i + 1].replace("\xa0", "").replace(" ", "")
                try:
                    return float(raw)
                except ValueError:
                    pass
    raise ValueError("Could not locate 'Total Net Profit' in HTML report.")


# ---------------------------------------------------------------------------
# Deals section — locate the Deals table rows
# ---------------------------------------------------------------------------

def _find_deals_section_start(html_rows: list) -> int:
    """
    Return the index of the header row of the Deals table (the row containing
    the 'Time', 'Deal', 'Direction' column headers).

    The Deals section starts with a colspan header '<b>Deals</b>' and then
    a column-header row whose cells contain 'Time', 'Deal', 'Direction', etc.
    """
    for idx, row in enumerate(html_rows):
        # The Deals column-header row has 13 cells including 'Direction'
        if len(row) == 13 and "Direction" in row:
            return idx + 1  # data starts on the next row
    raise ValueError("Could not locate the Deals table in HTML report.")


# ---------------------------------------------------------------------------
# Slot prefix extraction
# ---------------------------------------------------------------------------

def _extract_slot_prefix(comment: str) -> str:
    """
    Extract the canonical slot ID from an MT5 order comment field.

    Algorithm: split on the first comma; the text before the comma is the
    slot prefix. Map legacy P sub-slots (PH, PI, PX) to 'P'. Return '' for
    unrecognised prefixes (e.g. closing remarks like 'tp 1.20757').
    """
    if not comment:
        return ""
    comma_pos = comment.find(",")
    if comma_pos <= 0:
        # No comma — may be an 'sl ...', 'tp ...' closing remark; not a slot.
        return ""
    prefix = comment[:comma_pos].strip()
    if prefix in LEGACY_P_PREFIXES:
        return "P"
    return prefix


# ---------------------------------------------------------------------------
# Core parsing — build per-slot trade list
# ---------------------------------------------------------------------------

def _parse_deals(html_rows: list, start_idx: int) -> list:
    """
    Walk the Deals table and match each 'out' deal to its originating 'in'
    deal via FIFO queues keyed by (opening_trade_type, volume_str).

    Returns a list of dicts:
      {"slot_id": str, "net_pnl": float}
    one entry per closed trade.

    Columns (0-based, 13 total):
      0=Time, 1=Deal, 2=Symbol, 3=Type, 4=Direction, 5=Volume, 6=Price,
      7=Order, 8=Commission, 9=Swap, 10=Profit, 11=Balance, 12=Comment
    """
    # open_positions[(opening_type, volume_str)] = deque of {slot_id}
    open_positions: dict[tuple, deque] = {}
    trades: list = []
    unmatched_out_count = 0

    for row in html_rows[start_idx:]:
        if len(row) != 13:
            continue
        direction = row[4]
        trade_type = row[3]
        volume_str = row[5]

        if direction == "in":
            slot_prefix = _extract_slot_prefix(row[12])
            key = (trade_type, volume_str)
            if key not in open_positions:
                open_positions[key] = deque()
            open_positions[key].append(slot_prefix)

        elif direction == "out":
            # The closing order has the opposite trade type to the opening order.
            opening_type = OPPOSITE_TYPE.get(trade_type, "")
            key = (opening_type, volume_str)

            profit_raw = row[10].replace("\xa0", "").replace(" ", "")
            swap_raw = row[9].replace("\xa0", "").replace(" ", "")
            try:
                profit = float(profit_raw)
            except ValueError:
                profit = 0.0
            try:
                swap = float(swap_raw)
            except ValueError:
                swap = 0.0
            net_pnl = profit + swap

            slot_id = ""
            if key in open_positions and open_positions[key]:
                slot_id = open_positions[key].popleft()
                if not open_positions[key]:
                    del open_positions[key]
            else:
                unmatched_out_count += 1

            trades.append({"slot_id": slot_id, "net_pnl": net_pnl})

    if unmatched_out_count:
        print(
            f"[parse_baseline] WARNING: {unmatched_out_count} 'out' deal(s) had no "
            "matching 'in' deal — they are attributed to slot '' and excluded from "
            "per-slot totals.",
            file=sys.stderr,
        )
    if open_positions:
        unclosed = sum(len(q) for q in open_positions.values())
        print(
            f"[parse_baseline] WARNING: {unclosed} 'in' deal(s) were never closed "
            "(open at end of backtest period). These positions are excluded from "
            "per-slot totals.",
            file=sys.stderr,
        )

    return trades


# ---------------------------------------------------------------------------
# Aggregate per-slot statistics
# ---------------------------------------------------------------------------

def _aggregate_slots(trades: list) -> dict:
    """
    Aggregate trade list into per-slot {count, net_pnl, wins} dict.
    Slots absent from trades get zero-filled entries.
    """
    stats: dict[str, dict] = {}
    for slot_id in CANONICAL_SLOTS:
        stats[slot_id] = {"count": 0, "net_pnl": 0.0, "wins": 0}

    for trade in trades:
        slot_id = trade["slot_id"]
        if slot_id not in stats:
            # Unrecognised or empty slot — skip
            continue
        stats[slot_id]["count"] += 1
        stats[slot_id]["net_pnl"] += trade["net_pnl"]
        if trade["net_pnl"] > 0:
            stats[slot_id]["wins"] += 1

    return stats


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def _build_output(
    report_source: str,
    total_net_profit: float,
    stats: dict,
    trades: list,
) -> dict:
    """Construct the final output JSON structure."""
    # Total trades = count of closed trades with a recognised slot
    total_trades = sum(s["count"] for s in stats.values())

    slot_list = []
    for slot_id in CANONICAL_SLOTS:
        s = stats[slot_id]
        count = s["count"]
        net_pnl = round(s["net_pnl"], 2)
        win_rate = round(s["wins"] / count, 6) if count > 0 else None
        slot_list.append(
            {
                "slot_id": slot_id,
                "count": count,
                "net_pnl": net_pnl,
                "win_rate": win_rate,
            }
        )

    return {
        "schema_version": 1,
        "report_source": report_source,
        "extracted_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "total_net_profit": total_net_profit,
        "total_trades": total_trades,
        "slots": slot_list,
    }


def parse_baseline(input_path: str, output_path: str) -> dict:
    """
    Parse the MT5 Strategy Tester HTML report at *input_path* and write the
    per-slot baseline JSON to *output_path*.

    Returns the output dict (idempotent — running twice with the same input
    produces equivalent output, modulo extracted_at timestamp).
    """
    import os

    html_rows = _parse_html_rows(input_path)
    total_net_profit = _extract_total_net_profit(html_rows)
    deals_start = _find_deals_section_start(html_rows)
    trades = _parse_deals(html_rows, deals_start)
    stats = _aggregate_slots(trades)
    output = _build_output(
        report_source=os.path.basename(input_path),
        total_net_profit=total_net_profit,
        stats=stats,
        trades=trades,
    )

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(output, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    # Validation summary to stdout
    slot_pnl_sum = sum(s["net_pnl"] for s in output["slots"])
    delta = abs(slot_pnl_sum - total_net_profit)
    print(f"[parse_baseline] Slots: {len(output['slots'])}")
    print(f"[parse_baseline] Total net profit (HTML): {total_net_profit:,.2f}")
    print(f"[parse_baseline] Sum of per-slot net_pnl: {slot_pnl_sum:,.2f}")
    print(f"[parse_baseline] Delta: {delta:,.2f}")
    print(f"[parse_baseline] Total trades attributed: {output['total_trades']}")
    print(f"[parse_baseline] Output written to: {output_path}")

    return output


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Parse MT5 Strategy Tester HTML report into per-slot baseline JSON."
    )
    parser.add_argument(
        "--input",
        default="docs/foundation-input-sources/ReportTester-25045474.html",
        help="Path to the MT5 HTML report (UTF-16 LE with BOM).",
    )
    parser.add_argument(
        "--output",
        default="docs/state/baseline-per-slot.json",
        help="Path for the output JSON file.",
    )
    args = parser.parse_args()
    parse_baseline(args.input, args.output)


if __name__ == "__main__":
    main()
