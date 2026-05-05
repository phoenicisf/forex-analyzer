# Bucket A Regression Report — IMPL-062

> **Status:** STRUCTURAL SKELETON — numeric tables pending operator 5-yr Tester run (E-AC #1 + #2 deferred; see §8).
> Authored: 2026-05-05 | Task: IMPL-062 | Phase: P4 Verification

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

### 4a — Portfolio-level deviation

| Metric | Baseline | Rewrite (no G4) | Absolute Δ | Relative Δ% |
|--------|----------|-----------------|------------|-------------|
| Total Net Profit ($) | 24,271,276.63 | `<TBD>` | `<TBD>` | `<TBD>` |
| Profit Factor | `<TBD from baseline report>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Sharpe Ratio | `<TBD from baseline report>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Total Trades | 231 | `<TBD>` | `<TBD>` | `<TBD>` |
| Max Drawdown % | `<TBD from baseline report>` | `<TBD>` | `<TBD>` | `<TBD>` |

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

| # | Criterion | Source | Pass Threshold | Status |
|---|-----------|--------|----------------|--------|
| 1 | \|Bucket A drift\| = \|ΔNet Profit\| / $24.27M | NFR-1.1 | ≤ 25% (i.e., rewrite Net Profit ∈ [$18.20M, $30.34M]) | `<TBD>` |
| 2 | All 21 per-slot trade count deviations | NFR-1.6 | ≤ ±15% (or ±2 abs for baseline < 5 trades) | `<TBD>` |
| 3 | Profit Factor deviation | NFR-1.8 (informational for Bucket A) | PF does not materially degrade | `<TBD>` |
| 4 | Sharpe Ratio deviation | NFR-1.7 | ΔSharpe ≤ −1.0 | `<TBD>` |

**Overall IMPL-062 verdict:** `<TBD post-execution>` — PASS requires criteria #1 AND #2 both met.

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
