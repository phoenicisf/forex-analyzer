# NFR-7.3 DST Regression Test — 10 Transitions Mar 2021 → Oct 2025

| Field | Value |
|---|---|
| NFR reference | NFR-7.3 — Time-filter pass rate 100% correct trigger in 1-hour window around last Sunday Mar/Oct |
| FR reference | FR-6.5 — TimeGate IsMorningWakeup / HolidayBlock / IsBanned |
| AC references | AC-6.5.2 + AC-6.5.3 |
| Task ID | IMPL-067 |
| Phase | P4 — Verification |
| Opened | 2026-05-05 |
| Status | Structural COMPLETE — numeric verdict deferred to operator session (deferred-ac-registry row, expiry 2026-05-19) |

---

## 1. Purpose

Verify that `TimeGate` service methods `IsMorningWakeup`, `HolidayBlock`, and `IsBanned` produce correct EET-hour output (±0 tolerance) across all 10 DST transition boundaries in the 2021-2025 backtesting window, as required by NFR-7.3 + FR-6.5.

Specifically:
- **AC-6.5.2:** No new order opens in the 00:00–00:05 broker server-time window on each DST-switch Sunday.
- **AC-6.5.3:** Trade journal `timestamp` field reflects the correct EET shift at each boundary (spring-forward Mar: lose 1 hour; fall-back Oct: replay 1 hour).

Broker server time = EET (GMT+2 winter / GMT+3 summer DST), FBS Markets Inc., Build 5833 (per C-10 + trading-baseline.md).

---

## 2. Source Contract

### 2.1 NFR-7.3 (verbatim from BA `03 § NFR-7.3`)

> | **Metric** | Time-filter pass rate รอบ DST switch boundary |
> | **Target** | **100%** correct trigger ใน 1-hour window รอบ last Sunday Mar/Oct |
> | **Verification** | QA: regression run period ครอบคลุม **10 DST transitions** (Mar 2021..Oct 2025) — verify per FR-6.5 **AC-6.5.2** + **AC-6.5.3** |

### 2.2 AC-6.5.2

ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch (last Sunday Mar / last Sunday Oct แต่ละปี).

### 2.3 AC-6.5.3

Trade journal `timestamp` field สะท้อน DST shift ถูกต้อง:
- Spring-forward (Mar): events before 03:00 EET on DST Sunday carry GMT+2 offset; events at/after 04:00 EET carry GMT+3 offset; no events logged at 03:00–03:59 (skipped hour).
- Fall-back (Oct): events before the 03:00 EET replay carry the original GMT+3 offset; events in the replayed 03:00 hour carry GMT+2 offset — both should appear once each in the journal.

---

## 3. Coverage Matrix

| Transition ID | DST Sunday | Type | INI file | FromDate | ToDate | GMT before | GMT after |
|---|---|---|---|---|---|---|---|
| DST-2021-MAR | 2021-03-28 | Spring-forward | `dst_2021_mar.ini` | 2021.03.25 | 2021.03.31 | +2 | +3 |
| DST-2021-OCT | 2021-10-31 | Fall-back | `dst_2021_oct.ini` | 2021.10.28 | 2021.11.03 | +3 | +2 |
| DST-2022-MAR | 2022-03-27 | Spring-forward | `dst_2022_mar.ini` | 2022.03.24 | 2022.03.30 | +2 | +3 |
| DST-2022-OCT | 2022-10-30 | Fall-back | `dst_2022_oct.ini` | 2022.10.27 | 2022.11.02 | +3 | +2 |
| DST-2023-MAR | 2023-03-26 | Spring-forward | `dst_2023_mar.ini` | 2023.03.23 | 2023.03.29 | +2 | +3 |
| DST-2023-OCT | 2023-10-29 | Fall-back | `dst_2023_oct.ini` | 2023.10.26 | 2023.11.01 | +3 | +2 |
| DST-2024-MAR | 2024-03-31 | Spring-forward | `dst_2024_mar.ini` | 2024.03.28 | 2024.04.03 | +2 | +3 |
| DST-2024-OCT | 2024-10-27 | Fall-back | `dst_2024_oct.ini` | 2024.10.24 | 2024.10.30 | +3 | +2 |
| DST-2025-MAR | 2025-03-30 | Spring-forward | `dst_2025_mar.ini` | 2025.03.27 | 2025.04.02 | +2 | +3 |
| DST-2025-OCT | 2025-10-26 | Fall-back | `dst_2025_oct.ini` | 2025.10.23 | 2025.10.29 | +3 | +2 |

Each window spans ±3 days around the DST Sunday, providing 3 pre-transition H4 bars + DST day + 3 post-transition bars for comparison. H4 period = 6 bars/day × 7 days = 42 bars per ini run.

---

## 4. Verification Protocol

Per ini, the operator session executes the following steps:

### Step 1 — Run headless backtest

```bash
terminal64.exe /config:simulation/headless-tests/<dst_YYYY_mmm>.ini
```

Or via the standard script wrapper:

```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/<dst_YYYY_mmm>.ini \
     /tmp/<dst_YYYY_mmm>_run.txt
```

### Step 2 — Parse Tester Experts log for TimeGate events

```bash
TODAY=$(date +"%Y%m%d")
TESTER_LOG="$DATA_DIR/../../Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -nE "\[ev=morning_wakeup\]|\[ev=holiday_block\]|\[ev=banned_block\]|\[ev=entry_signal\]|\[ERROR\]"
```

Focus on lines timestamped within the DST Sunday ±1 day. Events of interest:
- `[ev=morning_wakeup]` — should fire once per day at first H4 bar ≥ 06:00 EET.
- `[ev=holiday_block]` — should NOT fire on DST Sunday unless it is also a holiday.
- `[ev=banned_block]` — should NOT fire at 06:00+ EET (banned window is midnight).
- `[ev=entry_signal]` — must NOT appear in 00:00–00:05 EET on DST Sunday (AC-6.5.2 gate).

### Step 3 — Parse journal for timestamp coherence (AC-6.5.3)

```bash
JOURNAL="MQL5/Files/PhoenicisNex/journal/tester/run-<ISO>.jsonl"

# All events on DST Sunday — inspect timestamp field
jq -r 'select(.timestamp | startswith("<YYYY-MM-DD>")) | {event_type, timestamp, slot_id}' "$JOURNAL"

# Spring-forward check: no events with timestamp hour == "03" on DST Sunday
jq -r 'select(.timestamp | test("<DST-SUNDAY>T03")) | {event_type, timestamp}' "$JOURNAL"
# Expected: empty output (skipped hour)

# Fall-back check: events at 03:xx EET appear with both +02:00 and +03:00 suffixes
jq -r 'select(.timestamp | test("<DST-SUNDAY>T03")) | .timestamp' "$JOURNAL" | sort | uniq
# Expected: 2 distinct offset variants for the replayed hour
```

### Step 4 — Verify AC-6.5.2 (zero entry events 00:00–00:05 EET on DST Sunday)

```bash
# Count entry events in midnight window on DST Sunday
jq '[select(.event_type=="entry_signal" and (.timestamp | test("<DST-SUNDAY>T00:0[0-5]")))] | length' "$JOURNAL"
# Expected: 0
```

---

## 5. Expected Behavior Per AC

### 5.1 AC-6.5.2 — Zero entries in 00:00–00:05 EET on DST Sunday

TimeGate `IsBanned` must return `true` for all H4 bar opens within the 00:00–00:05 EET window. On a DST transition day, this window is particularly sensitive because the broker server clock adjusts at 03:00 EET. The midnight window (00:00–00:05) is well before the adjustment and must behave identically to any non-DST Sunday midnight.

Pass condition: `jq '[... entry_signal ... midnight window ...] | length'` returns `0` for all 10 ini runs.

### 5.2 AC-6.5.3 — Journal timestamps reflect DST shift correctly

**Spring-forward (Mar — DST-2021-MAR, DST-2022-MAR, DST-2023-MAR, DST-2024-MAR, DST-2025-MAR):**

- Pre-transition (Fri + Sat + Sun before 03:00): timestamps carry `+02:00` suffix.
- Post-transition (Sun 04:00 EET onwards + Mon + Tue): timestamps carry `+03:00` suffix.
- Skipped hour 03:00–03:59 EET: no journal events should have this hour in the timestamp (H4 bar starting at 02:00 EET ends before 03:00; next bar starts at 04:00 post-shift).

**Fall-back (Oct — DST-2021-OCT, DST-2022-OCT, DST-2023-OCT, DST-2024-OCT, DST-2025-OCT):**

- Pre-transition (Thu + Fri + Sat + Sun before 04:00 EET): timestamps carry `+03:00` suffix.
- Replayed hour: the H4 bar 02:00–06:00 EET spans the 04:00→03:00 rollback. Events logged in this bar may carry either offset; both are acceptable as long as no gap or duplicate-hour anomaly appears in the `morning_wakeup` sequence.
- Post-transition (Sun 03:00 EET onwards + Mon + Tue): timestamps carry `+02:00` suffix.

### 5.3 TimeGate `IsMorningWakeup` — daily firing at ≥ 06:00 EET

Per FR-6.5: `IsMorningWakeup` should return `true` exactly once per trading day at the first H4 bar open at or after 06:00 EET. On an H4 chart, the 06:00 EET bar is the canonical morning-wakeup bar.

- For each of the 7 days in the ±3-day window, the Experts log should show exactly one `[ev=morning_wakeup]` event.
- The EET hour label of that event must be `06` regardless of DST offset (i.e., the TimeGate correctly translates broker server UTC time to EET).
- A missing `morning_wakeup` or one firing at `05` or `07` = off-by-1-hour bug = FAIL.

---

## 6. Pass Criterion Matrix

A transition is **PASS** when ALL three conditions hold:
1. AC-6.5.2: zero `entry_signal` events in 00:00–00:05 EET on DST Sunday.
2. AC-6.5.3: journal `timestamp` field carries correct EET offset before and after boundary; no events in skipped hour (spring-forward) / no anomalous duplicate-hour gap (fall-back).
3. TimeGate: exactly one `morning_wakeup` per day at EET hour `06`; no `morning_wakeup` at `05` or `07`.

A transition is **FAIL** when any of the three conditions does not hold.

| Transition ID | AC-6.5.2 | AC-6.5.3 | TimeGate hour | Verdict |
|---|---|---|---|---|
| DST-2021-MAR | TBD | TBD | TBD | **TBD** |
| DST-2021-OCT | TBD | TBD | TBD | **TBD** |
| DST-2022-MAR | TBD | TBD | TBD | **TBD** |
| DST-2022-OCT | TBD | TBD | TBD | **TBD** |
| DST-2023-MAR | TBD | TBD | TBD | **TBD** |
| DST-2023-OCT | TBD | TBD | TBD | **TBD** |
| DST-2024-MAR | TBD | TBD | TBD | **TBD** |
| DST-2024-OCT | TBD | TBD | TBD | **TBD** |
| DST-2025-MAR | TBD | TBD | TBD | **TBD** |
| DST-2025-OCT | TBD | TBD | TBD | **TBD** |

Overall NFR-7.3 verdict: **TBD** — requires operator session (§9 runbook).

---

## 7. Result Placeholder Table

To be populated by operator session after running all 10 inis.

| transition_id | from_date | to_date | morning_wakeup_count | banned_block_count | entry_count_in_00_05 | journal_timestamp_check | verdict |
|---|---|---|---|---|---|---|---|
| DST-2021-MAR | 2021.03.25 | 2021.03.31 | TBD | TBD | TBD | TBD | TBD |
| DST-2021-OCT | 2021.10.28 | 2021.11.03 | TBD | TBD | TBD | TBD | TBD |
| DST-2022-MAR | 2022.03.24 | 2022.03.30 | TBD | TBD | TBD | TBD | TBD |
| DST-2022-OCT | 2022.10.27 | 2022.11.02 | TBD | TBD | TBD | TBD | TBD |
| DST-2023-MAR | 2023.03.23 | 2023.03.29 | TBD | TBD | TBD | TBD | TBD |
| DST-2023-OCT | 2023.10.26 | 2023.11.01 | TBD | TBD | TBD | TBD | TBD |
| DST-2024-MAR | 2024.03.28 | 2024.04.03 | TBD | TBD | TBD | TBD | TBD |
| DST-2024-OCT | 2024.10.24 | 2024.10.30 | TBD | TBD | TBD | TBD | TBD |
| DST-2025-MAR | 2025.03.27 | 2025.04.02 | TBD | TBD | TBD | TBD | TBD |
| DST-2025-OCT | 2025.10.23 | 2025.10.29 | TBD | TBD | TBD | TBD | TBD |

Column definitions:
- `morning_wakeup_count` — count of `[ev=morning_wakeup]` events across all 7 days in window (expected: 5 trading days × 1 = 5; Saturday/Sunday non-trading = 0 or 1 depending on broker schedule).
- `banned_block_count` — count of `[ev=banned_block]` events in window (informational; midnight-hour suppression events).
- `entry_count_in_00_05` — count of `entry_signal` events with EET timestamp 00:00–00:05 on DST Sunday specifically (AC-6.5.2 gate; expected: 0).
- `journal_timestamp_check` — PASS / FAIL / SKIP (SKIP if no journal events produced in window, which is acceptable for a 6-day window with no trade signals).
- `verdict` — PASS / FAIL per §6 criterion.

---

## 8. Cross-References

| Reference | Relevance |
|---|---|
| NFR-7.3 | Primary requirement (100% correct trigger in 1-hour DST window) |
| FR-6.5 | `IsMorningWakeup` / `HolidayBlock` / `IsBanned` functional spec |
| AC-6.5.2 | Zero-entry midnight gate on DST Sunday |
| AC-6.5.3 | Journal timestamp DST-coherence check |
| C-10 | Broker server timezone = EET GMT+2/+3 (FBS Markets, EET DST last Sun Mar/Oct) |
| IMPL-050 | TimeGate service owner (IsMorningWakeup + IsBanned + HolidayBlock implementation) |
| IMPL-064 | Precedent for deferred-numeric-run report skeleton (nfr-3.1-atomic-write-result.md) |
| IMPL-068 | Parallel precedent (nfr-2.2-journal-latency.md — same deferred-numeric-run pattern) |
| ADR-004 | MarketContext snapshot built once per tick — TimeGate reads from snapshot |
| `simulation/headless-tests/timegate_smoke.ini` | Existing TimeGate DST smoke for 2026 window (IMPL-050); DST regression ini files for 2021-2025 extend this pattern |
| `docs/ba/03-non-functional-requirements.md § NFR-7.3` | Verbatim source for §2.1 above |

---

## 9. Operator Runbook

### Prerequisites

1. MT5 terminal install path confirmed in `origin.txt`.
2. `PhoenicisNex.mq5` compiled to `PhoenicisNex.ex5` (G1 pass — `0 errors, 0 warnings`).
3. No foreground `terminal64.exe` process running (data-dir lock prevents headless launch).
4. Historical EURUSD H4 data for 2021–2025 downloaded in MT5 Strategy Tester history (required for `Model=4` tick-based backtest).

### Step A — Sequential 10-run loop

```bash
for ini in simulation/headless-tests/dst_2021_mar.ini \
           simulation/headless-tests/dst_2021_oct.ini \
           simulation/headless-tests/dst_2022_mar.ini \
           simulation/headless-tests/dst_2022_oct.ini \
           simulation/headless-tests/dst_2023_mar.ini \
           simulation/headless-tests/dst_2023_oct.ini \
           simulation/headless-tests/dst_2024_mar.ini \
           simulation/headless-tests/dst_2024_oct.ini \
           simulation/headless-tests/dst_2025_mar.ini \
           simulation/headless-tests/dst_2025_oct.ini; do
  name=$(basename "$ini" .ini)
  echo "=== Running $name ==="
  bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
       "$ini" "/tmp/${name}_run.txt"
  echo "=== Done $name ==="
done
```

Or as a glob (executes alphabetically — same order):

```bash
for ini in simulation/headless-tests/dst_*.ini; do
  name=$(basename "$ini" .ini)
  bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
       "$ini" "/tmp/${name}_run.txt"
done
```

Expected wall-clock time: each ±3-day H4 window at `Model=4` with real-tick data is approximately 1–2 minutes. Total: **10–20 minutes** for the full 10-run batch.

### Step B — Batch log parse (all 10 runs)

```bash
for name in dst_2021_mar dst_2021_oct dst_2022_mar dst_2022_oct \
            dst_2023_mar dst_2023_oct dst_2024_mar dst_2024_oct \
            dst_2025_mar dst_2025_oct; do
  echo "=== $name Experts log ==="
  iconv -f UTF-16LE -t UTF-8 "/tmp/${name}_run.txt" 2>/dev/null \
    | grep -nE "\[ev=morning_wakeup\]|\[ev=banned_block\]|\[ev=entry_signal\]|\[ERROR\]" \
    | head -50
done
```

### Step C — Journal batch parse

```bash
TODAY=$(date +"%Y%m")
JOURNAL_DIR="MQL5/Files/PhoenicisNex/journal/tester"

# After each run, the journal file is named journal-YYYYMM.jsonl or run-<ISO>.jsonl
# Adjust pattern to match actual file name produced by TradeJournal.mqh
for jfile in "$JOURNAL_DIR"/run-*.jsonl "$JOURNAL_DIR"/journal-${TODAY}.jsonl; do
  [ -f "$jfile" ] || continue
  echo "=== $(basename $jfile) ==="
  # Sample 5 records
  head -5 "$jfile" | jq '{event_type, timestamp, slot_id}'
  # Count entry events in midnight 00:00-00:05 window (AC-6.5.2)
  echo "Entry events in 00:00-00:05 window:"
  jq '[select(.event_type=="entry_signal" and (.timestamp | test("T00:0[0-5]")))] | length' "$jfile"
  # Timestamp offset check (AC-6.5.3): list distinct offsets
  echo "Distinct timestamp offsets:"
  jq -r '.timestamp | capture("(?P<off>[+-][0-9]{2}:[0-9]{2})$") | .off' "$jfile" 2>/dev/null | sort | uniq -c
done
```

### Step D — Populate §7 result table

After the batch completes, fill in the `morning_wakeup_count`, `banned_block_count`, `entry_count_in_00_05`, `journal_timestamp_check`, and `verdict` columns from the grep/jq output. Update §6 pass/fail matrix. If all 10 = PASS, update this file's Status header to `✅ PASS` and cite the date.

### Step E — Commit evidence sidecar

Per Empirical Closure Discipline (CLAUDE.md §7 + §6):

```bash
# Save run logs as evidence sidecars
cp /tmp/dst_*_run.txt docs/state/_session-handoff/
# Commit with impl-plan.md AC closure
git add simulation/headless-tests/dst_*.ini docs/state/nfr-7.3-dst-regression.md \
        docs/state/_session-handoff/dst_*_run.txt
git commit -m "[feat:ea-qa] IMPL-067 DST regression 10 transitions — verdict PASS/FAIL

Why: NFR-7.3 100% time-filter pass rate at DST boundary; AC-6.5.2 zero midnight entries + AC-6.5.3 journal timestamp coherence. Evidence: 10 headless backtest run logs + journal parse."
```

---

## 10. Deferred E-AC Registry Row (suggested — orchestrator adds)

```
| IMPL-067 | E-AC: TimeGate output matches expected EET hour ±0 at each of 10 DST transitions [log-assertion]+[db-inspect] | needs operator session running 10 dst_*.ini files + parsing Experts log + journal — approx 10-20 min operator wall-clock | 2026-05-19 | NFR-7.3 time-filter 100% target unverified; DST off-by-1-hour bugs remain undetected if missed | Active |
```
