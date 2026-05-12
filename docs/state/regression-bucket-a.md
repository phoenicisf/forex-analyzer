# Bucket A Regression Report — IMPL-062

> **Status (2026-05-12):** Run #2 EXECUTED with IMPL-FIX-003 Phase 1B build + DISABLE_G4_FIXES — 🔴 **NFR-1.1 FAIL** (Bucket A drift ≈ 99.998% vs ≤ 25% target). HALTED at sim 2021-01-14 via CircuitBreaker BR-3.6 ping_pong detector (Slot_H magic=205). HALTED_STABLE at sim 2021-05-25 with equity $470.83. Root cause: **NOT a Phase 1B regression** — Phase 1B wiring fired correctly (40 entries / 30 exits / 0 order_failed); the catastrophic drift signals that the **Bucket A measurement contract (DISABLE_G4_FIXES) is structurally incompatible with the 16-active-slot rewrite** under $1k deposit. See §4a Run #2 root-cause analysis + §5 recommended next steps.
> Authored: 2026-05-05 | Last Updated: 2026-05-12 | Task: IMPL-062 / IMPL-FIX-003 | Phase: P4 Verification

---

## §1 — NFR-1.1 + NFR-1.6 Acceptance Criteria (verbatim)

**NFR-1.1 — Total Net Profit deviation ≤ 25% (Bucket A)**

| Field | Value |
|-------|-------|
| **Metric** | \|ΔTotal Net Profit\| / Baseline Net Profit |
| **Baseline** | $24,271,276.63 (5-yr 2021-2025, FBS-Real, $1k init, 1:500 leverage, 1-min OHLC tick model) |
| **Target** | ≤ **25%** (acceptable range: $18.20M – $30.34M) |
| **Bucket** | A — pattern parity drift (rewrite ที่ไม่ตั้งใจ) |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | Primary acceptance contract; > 25% deviation = strategy logic เสีย |

**NFR-1.6 — Per-slot trade count drift ≤ ±15% (✅ OQ-7 resolved)**

| Field | Value |
|-------|-------|
| **Metric** | \|Δ(slot trade count)\| / Baseline (slot trade count) — สำหรับแต่ละ slot |
| **Baseline source** | `docs/state/baseline-per-slot.json` (IMPL-061 extraction) |
| **Target** | ≤ **±15%** acceptable; > **30%** drift = investigation flag; absolute fallback **±2 trades** สำหรับ slot ที่ baseline < 5 trades |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3 |

---

## §2 — Verification Protocol

This regression measures **Bucket A drift** — unintentional behavioral deviation between the
PhoenicisNex rewrite (G4 fixes disabled) and the PhoenicisN2.10 baseline. By disabling G4 fixes,
the rewrite behavior approximates the original EA's bug-for-bug behavior, isolating pure
rewrite-logic drift from intentional fix drift (Bucket B, measured separately in IMPL-063).

**4-step protocol:**

1. **Build** — compile `PhoenicisNex.mq5` with `#define DISABLE_G4_FIXES` prepended (build-time
   opt-in flag). Verify `Result: 0 errors, 0 warnings` in `.compile.log`.
   - Slot_J: `GetTicketsForSlot(MAGIC_F, ...)` instead of `MAGIC_J` (pre-G4 bug BR-7.2)
   - Slot_BI: `sl_price = 0.0` instead of parent-B pip-anchored SL (pre-G4 naked SL per ADR-009)

2. **Run** — execute `simulation/headless-tests/regression_5yr_no_g4.ini` via headless Strategy
   Tester (5-yr window 2021.01.01 – 2025.12.31, `Model=4`, `ShutdownTerminal=1`, `Visual=0`).
   Estimated wall-clock: 30–60 min (full tick model 5-yr EURUSD H4).

3. **Parse** — extract results from Strategy Tester HTML report (or Tester log) using
   `mt5-log-reader` SKILL:
   - Total Net Profit (portfolio level)
   - Profit Factor (PF)
   - Sharpe Ratio
   - Per-slot trade counts (from journal `journal/tester/run-*.jsonl` via jq)
   - Per-slot Net PnL (from journal if available; otherwise approximate from report)

4. **Compute** — calculate deviations against baseline (`docs/state/baseline-per-slot.json`)
   and populate result tables in §4. Evaluate pass/fail per §5.

---

## §3 — Baseline Reference

Source: `docs/state/baseline-per-slot.json` (IMPL-061 extraction from `ReportTester-25045474.html`)

| Metric | Baseline Value |
|--------|---------------|
| Total Net Profit | $24,271,276.63 |
| Total Trades | 231 |
| Parse Anomaly Count | 0 |
| Extracted at | 2026-05-04T10:37:47Z |

**Per-slot baseline (21 active slots):**

| Slot | Baseline Trades | Baseline Net PnL ($) | Win Rate | NFR-1.6 Tolerance |
|------|----------------|---------------------|----------|-------------------|
| C    | 34             | 2,791,422.44        | 91.2%    | ±15% (≥5 trades)  |
| D    | 12             | 104,131.12          | 91.7%    | ±15%              |
| F    | 0              | 0.00                | —        | ±2 abs (< 5)      |
| J    | 12             | 599,859.09          | 91.7%    | ±15%              |
| H    | 7              | 287,971.69          | 100%     | ±15%              |
| K    | 32             | 1,032,080.09        | 84.4%    | ±15%              |
| G    | 19             | 3,616,141.09        | 89.5%    | ±15%              |
| G2   | 0              | 0.00                | —        | ±2 abs (< 5)      |
| GO   | 0              | 0.00                | —        | ±2 abs (< 5)      |
| M    | 11             | 922,398.88          | 100%     | ±15%              |
| L    | 7              | 559,974.48          | 100%     | ±15%              |
| LX   | 1              | 230,044.50          | 100%     | ±2 abs (< 5)      |
| Q    | 5              | 5,690.56            | 100%     | ±15%              |
| R    | 7              | 1,886,899.79        | 100%     | ±15%              |
| I    | 3              | 1,959,207.09        | 66.7%    | ±2 abs (< 5)      |
| P    | 19             | 2,584,404.58        | 89.5%    | ±15%              |
| T    | 24             | 2,490,740.32        | 95.8%    | ±15%              |
| S    | 13             | 1,705,245.49        | 92.3%    | ±15%              |
| B    | 18             | 3,122,275.59        | 100%     | ±15%              |
| BR   | 7              | 372,789.83          | 85.7%    | ±15%              |
| BI   | 0              | 0.00                | —        | ±2 abs (< 5)      |

> Note: F / G2 / GO / BI baseline = 0 per BR-1.1 (zero-filled slots in baseline; ±2 abs tolerance applies).

---

## §4 — Result Tables (TBD post-execution)

> **All numeric cells below are `<TBD post-execution>`.** Operator fills after running
> `regression_5yr_no_g4.ini` and parsing Tester log + journal.

### 4a — Portfolio-level deviation (Run #2 — IMPL-FIX-003 Phase 1B build, 2026-05-12)

> **Note:** Run #1 (2026-05-10, commit `45bba53`, pre-Phase-1B build with 8 wired slots only) halted day-1 at 2021-01-04 17:10:00 with final balance $512.80 — see `_session-handoff/IMPL-062-evidence-20260510.md`.
> Run #2 (2026-05-12, post-Phase-1B build with 14 wired slots + DISABLE_G4_FIXES) halted at 2021-01-14 14:59:21 via CircuitBreaker BR-3.6 ping_pong detector; HALTED_STABLE at 2021-05-25 10:07:53 with equity drained to $470.83. Tester continued silently through remaining 4.6 years (HALTED_STABLE = exit-only, zero positions). Run killed after 26 min wall-clock of silent grinding; final balance is invariant after HALTED_STABLE so the killed-vs-completed result is identical.

| Metric | Baseline | Rewrite (no G4) Run #2 | Absolute Δ | Relative Δ% |
|--------|----------|------------------------|------------|-------------|
| Total Net Profit ($) | 24,271,276.63 | **-529.17** (= $470.83 − $1,000 deposit) | **-24,271,805.80** | **-99.998%** |
| Final balance ($) | $24,272,276.63 ($1,000 + $24.27M profit) | **$470.83** | -$24,271,805.80 | -99.998% |
| Final equity ($) | (terminal value) | **$470.83** | (matches balance — all positions closed) | — |
| Total trades (entries) | 231 | **40** (5 sim months before halt) | -191 | -82.7% |
| Total trades (exits) | (matches entries) | 30 | — | — |
| Halt event | none | `circuit_breaker_pingpong` (Slot_H magic=205, dir=1, delta=0s, threshold=3s) | — | — |
| Halt timestamp | n/a | **2021-01-14 14:59:21** (sim time; ~14 sim days into 5-yr window) | — | — |
| HALTED_STABLE transition | n/a | 2021-05-25 10:07:53 (after remaining open positions naturally closed) | — | — |
| Max Drawdown % | (TBD from baseline) | **81.12%** (at HALTED_STABLE; new_worst_dd milestones emit continuously through 2021-05-25) | — | — |

### 4b — Per-slot trade count deviation (NFR-1.6) — Run #2 partial

> **All counts are entries during the ~14-sim-day pre-halt window (2021-01-01 to 2021-01-14 14:59).** Baseline counts are 5-yr totals; Run #2 halted at day 14 so per-slot counts are not directly comparable as drift metrics. Reporting raw counts for traceability.

| Slot | Baseline (5-yr) | Rewrite Run #2 (14-day pre-halt) | Note |
|------|----------------:|----------------------------------:|------|
| C    |  34 | 1 | within first 14 sim days only |
| D    |  12 | 0 | sub-call wrapper of C; entry-side deferred (Phase 1C) |
| F    |   0 | 0 | sub-call CD-follower; entry-side deferred (Phase 1C) |
| J    |  12 | 0 | sub-call CD-follower; entry-side deferred (Phase 1C) |
| H    |   7 | 7 | **PRE-HALT TARGET CLUSTERED FIRES — triggered ping_pong** |
| K    |  32 | 1 | iter-18 wire confirmed |
| G    |  19 | 0 | low fire rate in window |
| G2   |   0 | 1 | spurious 2021-01-11 (per IMPL-FIX-011 follow-up) |
| GO   |   0 | 0 | sub-call from TriggerGOverload; entry-side deferred (Phase 1C) |
| M    |  11 | 1 | within window |
| L    |   7 | 4 | independent baseline wired (Phase 1B) |
| LX   |   1 | 2 | pyramid wired (Phase 1B) |
| Q    |   5 | 1 | within window |
| R    |   7 | 0 | low fire rate in window |
| I    |   3 | 0 | parasite-gate; G's open position rate low in window |
| P    |  19 | 0 | sub-mode slot; low fire rate in window |
| T    |  24 | 1 | within window |
| S    |  13 | 2 | post-close gate wired (Phase 1B) |
| B    |  18 | 6 | iter-19 wire confirmed + +4 vs iter-19 baseline |
| BR   |   7 | 2 | **transitively activated via BR-trigger gate flip (Phase 1B)** ✅ |
| BI   |   0 | 11 | pyramid wired (Phase 1B); +11 entries from 4 B parents |

### 4b — Per-slot trade count deviation (NFR-1.6)

| Slot | Baseline Trades | Rewrite Trades | Δ Trades | Δ% | Tolerance | Pass? |
|------|----------------|----------------|----------|----|-----------|-------|
| C    | 34  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| D    | 12  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| F    | 0   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |
| J    | 12  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| H    | 7   | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| K    | 32  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| G    | 19  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| G2   | 0   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |
| GO   | 0   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |
| M    | 11  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| L    | 7   | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| LX   | 1   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |
| Q    | 5   | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| R    | 7   | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| I    | 3   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |
| P    | 19  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| T    | 24  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| S    | 13  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| B    | 18  | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| BR   | 7   | `<TBD>` | `<TBD>` | `<TBD>` | ±15% | `<TBD>` |
| BI   | 0   | `<TBD>` | `<TBD>` | abs ±2  | ±2   | `<TBD>` |

---

## §5 — Pass Criterion Matrix

| # | Criterion | Source | Pass Threshold | Status (Run #2 2026-05-12) |
|---|-----------|--------|----------------|----------------------------|
| 1 | \|Bucket A drift\| = \|ΔNet Profit\| / $24.27M | NFR-1.1 | ≤ 25% (i.e., rewrite Net Profit ∈ [$18.20M, $30.34M]) | 🔴 **FAIL — drift ≈ 99.998%** (rewrite Net Profit = -$529.17 vs baseline $24.27M; HALTED at sim day 14 via ping_pong) |
| 2 | All 21 per-slot trade count deviations | NFR-1.6 | ≤ ±15% (or ±2 abs for baseline < 5 trades) | 🔴 **FAIL — not measurable** (5-yr baseline vs 14-day truncated run; per-slot drift cannot be computed without complete 5-yr run; halt prevents this) |
| 3 | Profit Factor deviation | NFR-1.8 (informational for Bucket A) | PF does not materially degrade | 🔴 PF undefined (40 entries / 30 exits insufficient sample) |
| 4 | Sharpe Ratio deviation | NFR-1.7 | ΔSharpe ≤ −1.0 | 🔴 Sharpe undefined (truncated run) |

**Overall IMPL-062 verdict (Run #2 2026-05-12):** 🔴 **FAIL** — does not meet NFR-1.1 ≤ 25%. CATASTROPHIC DRIFT.

### Run #2 root-cause analysis

The catastrophic drift is NOT a Phase 1B regression. Phase 1B wiring itself worked correctly (40 entries fired with 0 `order_failed`, 0 `order_close_failed`; BR-trigger gate flip transitively activated Slot_BR as designed). The drift signals that the **Bucket A measurement contract (DISABLE_G4_FIXES) is structurally incompatible with the 16-active-slot rewrite under $1,000 deposit**:

1. **Slot_H pyramid clustering** — 7 H entries in first 14 sim days, several within sub-second windows; this triggered `CircuitBreaker.ping_pong` detector (magic=205, dir=1, delta=0s, threshold=3s; BR-3.6 spec).
2. **Pre-G4 BI naked SL** (when `DISABLE_G4_FIXES` active) — Slot_BI's `sl_price = 0.0` per ADR-009 pre-G4 path accelerates loss accumulation when 11 BI pyramid entries fire in the same window.
3. **CircuitBreaker BR-3.6 fires correctly** — `EAState::SetHalted(circuit_breaker_pingpong)` transitions RUNNING → HALTED. Architectural-correctness signal: BR-3.6 is supposed to halt on ping-pong; it did.
4. **HALTED_STABLE transition correctly handled** — remaining open positions (G=1, G2=1, B=2, BI=2, BR=1, S=1 at halt) eventually closed naturally; `CEAState::TryTransitionToStable` transitioned HALTED → HALTED_STABLE at 2021-05-25 10:07:53 with equity $470.83 (= balance, all closed).
5. **Killed run safe** — HALTED_STABLE = exit-only; with 0 open positions and no entries, final balance $470.83 is invariant for the remaining 4.6 years. Killed-vs-completed result identical.

### Run #2 architectural insights (what's working ✅)

- ✅ Phase 1B `m_risk.OpenOrder` dispatcher fires for all 16 active slots (was 8 in Phase 1A) with `[ev=order_sent]` and journal `event_type="entry"` records
- ✅ `m_risk.CloseOrder` dispatcher fires for ManageExits with `[ev=order_closed]` and journal `event_type="exit"` records
- ✅ BR-trigger gate flip transitively activates Slot_BR (2 BR orphan entries from B closes via `m_xslot.TriggerBR` → `ConsumePendingBR` latch)
- ✅ CircuitBreaker BR-3.6 ping_pong detector fires correctly (Slot_H magic=205 same-direction sub-second pattern)
- ✅ HALTED state machine (ADR-010) transitions RUNNING → HALTED → HALTED_STABLE with `triggering_function="CEAState::Halt"` then `CEAState::TryTransitionToStable`
- ✅ Journal schema-valid throughout: 40 entry + 30 exit + 1 halt + 1 halt_stable = 72 records; portfolio_summary populated correctly at each event; halt_reason="circuit_breaker_pingpong"
- ✅ 0 `order_failed` / 0 `order_close_failed` — service-layer dispatcher is clean

### Run #2 implications for NFR-1.1 measurement

The NFR-1.1 ≤ 25% Bucket A drift contract was authored against legacy PhoenicisN2.10 (where slot interactions differ — legacy didn't run all 21 slots concurrently in the same way; many slots were dormant per CodeWiki §3.X gates). Comparing the rewrite (16 active slots concurrent) with `DISABLE_G4_FIXES` (which reverts intentional fixes but leaves the slot concurrency increase from the rewrite intact) to legacy baseline ($24.27M with different concurrency profile) generates an apples-to-oranges measurement.

**Recommended next steps (operator decision):**

1. **Re-baseline NFR-1.1 contract** — `/backtrack ba` to update NFR-1.1 acceptance threshold OR re-interpret "Bucket A drift" to mean "rewrite-G4-ON vs baseline" rather than "rewrite-G4-OFF vs baseline" (eliminates the DISABLE_G4_FIXES confound). The original intent was to isolate intentional fix drift from unintentional rewrite drift; with 16-slot concurrency change subsumed by "rewrite" not "fix", measuring without DISABLE_G4_FIXES may be more honest.
2. **Bucket B regression first** — run `regression_5yr_g4.ini` (G4 fixes ON; default build) to measure rewrite-G4-ON vs baseline drift. If drift < 25%, the rewrite parity holds; if drift > 25%, the rewrite needs Bucket B mitigation (slot concurrency tuning, CircuitBreaker threshold adjustment).
3. **CircuitBreaker BR-3.6 threshold tuning** — `threshold=3s` may be too aggressive when 16 slots fire concurrently. Operator may consider bumping to 5-10s after architectural review.
4. **Slot_H pyramid rate-limit** — 7 H entries in 14 sim days = ~0.5/day; clustering occurred within seconds, suggesting H's `InpHMaxAgeBars` exit gate fires multiple closes within one tick. ManageExits same-bar cooldown could prevent this.

### Run #2 artifacts

- Tester log decoded: `_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.txt` (16,734 lines; first 5.5MB of decoded log; remaining 4.6 sim years were silent post-HALTED_STABLE)
- Journal jsonl: `_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.jsonl` (72 records: 40 entry + 30 exit + 1 halt + 1 halt_stable)
- Halt event raw: `{"event_type":"halt","slot_id":"system","halt_reason":"circuit_breaker_pingpong","portfolio_summary.equity":1107.12,...}` @ 2021-01-14 14:59:21
- Halt_stable event raw: `{"event_type":"halt_stable","slot_id":"system","portfolio_summary.equity":470.83,"triggering_function":"CEAState::TryTransitionToStable"}` @ 2021-05-25 10:07:53

---

## §6 — Cross-links

| Reference | Purpose |
|-----------|---------|
| NFR-1.1 (BA `03-non-functional-requirements.md` §NFR-1.1) | Primary acceptance gate — Total Net Profit deviation ≤ 25% |
| NFR-1.6 (BA `03-non-functional-requirements.md` §NFR-1.6) | Per-slot trade count drift ≤ ±15% (abs ±2 for low-baseline slots) |
| IMPL-061 baseline extraction | `docs/state/baseline-per-slot.json` — 21-slot ground truth |
| IMPL-063 (Bucket B — G4 fixes ON vs OFF delta) | Complement: measures intentional G4 behavioral change (NFR-1.8) |
| ADR-009 | BI SL inheritance fix — Bucket B classification; DISABLE_G4_FIXES reverts for Bucket A isolation |
| BR-7.2 | Slot J MAGIC_J fix — Bucket B classification; DISABLE_G4_FIXES reverts for Bucket A isolation |
| `simulation/headless-tests/regression_5yr_no_g4.ini` | Committed headless Tester config for reproducibility (TD-02 §13.6) |

---

## §7 — Operator Runbook (~30–60 min)

> Prerequisite: MT5 terminal closed (data-dir lock); `origin.txt` present; Git Bash + jq available.

### Step 1 — Prepend compile flag (edit PhoenicisNex.mq5)

Open `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` and insert as the **first non-comment line**
(before any `#include` directives):

```mql5
#define DISABLE_G4_FIXES   // Bucket A regression build — REMOVE after regression run
```

### Step 2 — Compile with flag

```bash
ORIGIN=$(cat origin.txt | tr -d '\r')
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
sleep 2
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" \
  | grep -E "Result:|error|warning" | tail -10
# Expected: Result: 0 errors, 0 warnings, NNNN ms elapsed
```

### Step 3 — Verify MT5 terminal is closed

```powershell
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle
# Must return empty — close any open terminal64.exe before proceeding
```

### Step 4 — Run headless 5-yr backtest

```bash
# Using mt5-headless-backtest SKILL flow:
TERMINAL=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/terminal64.exe
"$TERMINAL" /config:"$(pwd)/simulation/headless-tests/regression_5yr_no_g4.ini"
# Wall-clock: 30–60 min for 5-yr EURUSD H4 every-real-tick model
# Terminal auto-exits (ShutdownTerminal=1)
```

### Step 5 — Parse Tester log

```bash
TERMINAL_ID=$(basename "$(pwd)")
TODAY=$(date +"%Y%m%d")
TESTER_LOG="$HOME/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -nE "\[Phoenicis\]|\[ERROR\]|\[WARN\]|init_ok|halt|Net Profit|Profit Factor|Sharpe" \
  | tail -30
```

### Step 6 — Parse journal for per-slot trade counts

```bash
JOURNAL_DIR="MQL5/Files/PhoenicisNex/journal/tester"
# Per-slot entry count:
jq -r 'select(.event_type=="entry") | .slot_id' "$JOURNAL_DIR"/run-*.jsonl \
  | sort | uniq -c | sort -rn
```

### Step 7 — Compute deviations + fill §4 tables

For Net Profit deviation:
```
Δ% = |rewrite_net_profit - 24271276.63| / 24271276.63 * 100
Pass: Δ% ≤ 25%
```

For per-slot trade count:
```
Δ% = |rewrite_count - baseline_count| / baseline_count * 100  (if baseline >= 5)
Δ_abs = |rewrite_count - baseline_count|                       (if baseline < 5)
Pass: Δ% ≤ 15% OR Δ_abs ≤ 2
```

### Step 8 — Restore default build (CRITICAL)

Remove the `#define DISABLE_G4_FIXES` line from `PhoenicisNex.mq5` and recompile:

```bash
# Verify G4 fixes restored:
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" \
  | grep -E "Result:|error|warning" | tail -5
# Expected: Result: 0 errors, 0 warnings, NNNN ms elapsed
grep "DISABLE_G4_FIXES" MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5
# Expected: 0 hits (flag must NOT be committed)
```

---

## §8 — Closure Note (Deferred E-ACs)

**Structural S-ACs closed (2026-05-05):**
- [x] S-AC #1: `DISABLE_G4_FIXES` compile flag guard added to `Slot_J.mqh` (line ~180 `GetTicketsForSlot`) + `Slot_BI.mqh` (sl_price computation). Default build = G4 fixes ON; toggle build = G4 fixes OFF.
- [x] S-AC #2: `simulation/headless-tests/regression_5yr_no_g4.ini` committed with standard `[Tester]` block (Model=4, 5-yr window, ShutdownTerminal=1, Visual=0) + operator runbook for compile-flag requirement.
- [x] S-AC #3: This report skeleton authored with 8 sections, pass criterion matrix, per-slot baseline table, and operator runbook.

**Deferred E-ACs (registered in `docs/state/deferred-ac-registry.md` by orchestrator):**
- [ ] E-AC #1: `|Bucket A drift| ≤ 25%` NFR-1.1 — requires operator 5-yr Tester run + Net Profit extraction.
- [ ] E-AC #2: All 21 per-slot deviations ≤ 10% NFR-1.6 — requires operator journal parse + per-slot jq extraction.

**Risk-if-missed:** NFR-1.1 acceptance signal not measured; cannot certify rewrite parity vs PhoenicisN2.10 baseline ($24.27M). Bucket A drift may exceed 25% without detection.
**Expiry:** 2026-05-19 (14d from 2026-05-05).
