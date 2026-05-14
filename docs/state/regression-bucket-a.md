# Bucket A Regression Report — IMPL-062

> **Status (2026-05-14):** Run #3 EXECUTED with rewrite-G4-ON default build (BT-001 single-pass methodology) — 🔴 **NFR-1.1 FAIL** (Bucket A drift = 100.0022% vs ≤ 25% target). HALTED at sim 2021-01-14 14:59:21 via CircuitBreaker BR-3.6 ping_pong (Slot_H magic=205, dir=1, delta=0s, threshold=3s) — **identical halt class as Run #2**. HALTED_STABLE at sim 2021-05-25 10:07:53 with equity **$470.83** (byte-identical to Run #2). **G4 fix contribution = $0 at portfolio level** — IMPL-063 informational delta `rewrite-G4-ON − rewrite-G4-OFF` = $0 (halt fires before BI/J differential matters). 11/11 BI entries verified `sl != 0` (G4 BI SL fix working at slot level ✅) but proximate trigger of ping_pong is **Slot_H pyramid clustering** (7 H entries in 14 sim days, sub-second windows) — a slot NOT addressed by IMPL-FIX-011a/b/c/d (which targeted T/G/G2/B/K only). Reveals **R-13 long-tail trading-logic translation gap** as the actual NFR-1.1 blocker, not the BT-001 measurement methodology (which closed correctly). New IMPL-FIX-012 follow-up authored to target Slot_H same-bar cooldown.
> Prior Status (2026-05-12): Run #2 with DISABLE_G4_FIXES → 🔴 FAIL (drift ≈ 99.998%; same halt class). Triggered BT-001 measurement-methodology re-baseline. BT-001 closed 2026-05-13; Run #3 confirms BT-001 was necessary but not sufficient.
> Authored: 2026-05-05 | Last Updated: 2026-05-14 (Run #3 + IMPL-FIX-012 follow-up) | Task: IMPL-062 / IMPL-063 / IMPL-FIX-012 | Phase: P4 Verification

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

## §4 — Result Tables

### 4a — Portfolio-level deviation (Run #3 — rewrite-G4-ON default build, 2026-05-14, BT-001 single-pass methodology)

> **Operator session:** 2026-05-14 22:22:39 launch → 22:40 killed (per Run #2 precedent — HALTED_STABLE invariant after sim 2021-05-25; silent grind through 2025-12-31 produces zero new info). G1 PASS pre-flight `Result: 0 errors, 0 warnings, 4977 ms` (default build, no `#define DISABLE_G4_FIXES`); G3 launched `regression_5yr_g4.ini`; G4 parse via `simulation/scripts/impl062_parse_run.sh` + Python journal scan. Evidence: `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.{jsonl,tester.txt}` (72 records + abridged Tester log).

| Metric | Baseline | Rewrite (G4-ON) Run #3 | Absolute Δ | Relative Δ% |
|--------|----------|------------------------|------------|-------------|
| Total Net Profit ($) | 24,271,276.63 | **-529.17** (= $470.83 − $1,000 deposit) | **-24,271,805.80** | **-100.0022%** |
| Final balance ($) | $24,272,276.63 ($1,000 + $24.27M profit) | **$470.83** | -$24,271,805.80 | -100.0022% |
| Final equity ($) | (terminal value) | **$470.83** | (matches balance — all positions closed) | — |
| Total trades (entries) | 231 | **40** (5 sim months before halt) | -191 | -82.7% |
| Total trades (exits) | (matches entries) | 30 | — | — |
| Halt event | none | `circuit_breaker_pingpong` (Slot_H magic=205, dir=1, delta=0s, threshold=3s) | — | — |
| Halt timestamp | n/a | **2021-01-14 14:59:21** (sim time; ~14 sim days into 5-yr window) | — | — |
| HALTED_STABLE transition | n/a | **2021-05-25 10:07:53** (after remaining open positions naturally closed) | — | — |
| Max Drawdown % | (TBD baseline) | **81.12%** (at HALTED_STABLE; matches Run #2 EXACTLY) | — | — |

**Run #3 vs Run #2 comparison (G4 fix portfolio impact):** $0 — final equity, halt timestamp, halt_stable timestamp, slot_counts at halt all **byte-identical** between Run #3 (G4-ON) and Run #2 (G4-OFF). Confirms IMPL-063 informational delta `rewrite-G4-ON − rewrite-G4-OFF` = **$0**.

### 4a-r2 — Portfolio-level deviation (Run #2 — IMPL-FIX-003 Phase 1B build, 2026-05-12, DISABLE_G4_FIXES, **superseded by Run #3 + BT-001 closure 2026-05-13**)

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

### 4b — Per-slot trade count deviation (NFR-1.6) — Run #3 (rewrite-G4-ON) 14-day pre-halt window (2026-05-14)

> **All counts are entries during the ~14-sim-day pre-halt window (2021-01-01 to 2021-01-14 14:59).** Baseline counts are 5-yr totals; Run #3 halted at sim day 14 so per-slot counts are not comparable as 5-yr drift metrics. Reporting raw counts for traceability + cross-check vs Run #2 (which had identical halt class).

| Slot | Baseline (5-yr) | Run #3 (14-day pre-halt G4-ON) | Run #2 (14-day pre-halt G4-OFF) | Δ Run #3 vs Run #2 | Note |
|------|----------------:|-------------------------------:|--------------------------------:|-------------------:|------|
| C    |  34 | 1 | 1 | 0 | identical — within first 14 sim days only |
| D    |  12 | 0 | 0 | 0 | sub-call wrapper of C; entry-side deferred (Phase 1C) |
| F    |   0 | 0 | 0 | 0 | sub-call CD-follower; entry-side deferred (Phase 1C) |
| J    |  12 | 0 | 0 | 0 | sub-call CD-follower; entry-side deferred (Phase 1C) — no J fires in window so G4 magic-J fix not exercised |
| H    |   7 | 7 | 7 | 0 | **PRE-HALT TARGET CLUSTERED FIRES — triggered ping_pong (identical to Run #2)** |
| K    |  32 | 1 | 1 | 0 | iter-18 wire confirmed |
| G    |  19 | 0 | 0 | 0 | low fire rate in window |
| G2   |   0 | 1 | 1 | 0 | spurious 2021-01-11 (per IMPL-FIX-011 follow-up) |
| GO   |   0 | 0 | 0 | 0 | sub-call from TriggerGOverload; entry-side deferred (Phase 1C) |
| M    |  11 | 1 | 1 | 0 | within window |
| L    |   7 | 4 | 4 | 0 | independent baseline wired (Phase 1B) |
| LX   |   1 | 2 | 2 | 0 | pyramid wired (Phase 1B) |
| Q    |   5 | 1 | 1 | 0 | within window |
| R    |   7 | 0 | 0 | 0 | low fire rate in window |
| I    |   3 | 0 | 0 | 0 | parasite-gate; G's open position rate low in window |
| P    |  19 | 0 | 0 | 0 | sub-mode slot; low fire rate in window |
| T    |  24 | 1 | 1 | 0 | within window |
| S    |  13 | 2 | 2 | 0 | post-close gate wired (Phase 1B) |
| B    |  18 | 6 | 6 | 0 | iter-19 wire confirmed |
| BR   |   7 | 2 | 2 | 0 | transitively activated via BR-trigger gate flip (Phase 1B) ✅ |
| BI   |   0 | 11 | 11 | 0 | pyramid wired (Phase 1B); +11 entries from 4 B parents — **G4 SL fix verified: 11/11 entries with `sl != 0`** ✅ (Run #2 had `sl = 0` per DISABLE_G4_FIXES; Run #3 has parent-pip-anchored SL per ADR-009) |

**Per-slot Run #3 vs Run #2:** **0 delta on every slot count.** G4 fixes (BI parent-SL + J magic-J) are correctly applied at the slot level (BI verified 11/11) but the halt fires before the per-slot differential matters at portfolio scale.

### 4b-r2 — Per-slot trade count deviation (NFR-1.6) — Run #2 partial

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

| # | Criterion | Source | Pass Threshold | Status (Run #3 2026-05-14, BT-001 single-pass) | Status (Run #2 2026-05-12, DISABLE_G4_FIXES, superseded) |
|---|-----------|--------|----------------|------------------------------------------------|----------------------------------------------------------|
| 1 | \|Bucket A drift\| = \|ΔNet Profit\| / $24.27M | NFR-1.1 (BT-001 redefined: rewrite-G4-ON vs baseline single-pass) | ≤ 25% (i.e., rewrite Net Profit ∈ [$18.20M, $30.34M]) | 🔴 **FAIL — drift = 100.0022%** (rewrite Net Profit = -$529.17 vs baseline $24.27M; HALTED at sim day 14 via Slot_H ping_pong; **identical halt class as Run #2 → BT-001 measurement re-baseline necessary but not sufficient**) | 🔴 FAIL — drift ≈ 99.998% (HALTED via same ping_pong) |
| 2 | All 21 per-slot trade count deviations | NFR-1.6 | ≤ ±15% (or ±2 abs for baseline < 5 trades) | 🔴 **N/A — not measurable** (5-yr baseline vs 14-day truncated run; halt prevents 5-yr completion; per-slot pre-halt counts byte-identical to Run #2 — see §4b) | 🔴 N/A — same as Run #3 (truncated) |
| 3 | Profit Factor deviation | NFR-1.8 (informational for Bucket A) | PF does not materially degrade | 🔴 PF undefined (40 entries / 30 exits insufficient sample) | 🔴 PF undefined |
| 4 | Sharpe Ratio deviation | NFR-1.7 | ΔSharpe ≤ −1.0 | 🔴 Sharpe undefined (truncated run) | 🔴 Sharpe undefined |

**Overall IMPL-062 verdict (Run #3 2026-05-14, post-BT-001):** 🔴 **FAIL** — does not meet NFR-1.1 ≤ 25%. CATASTROPHIC DRIFT (same magnitude as Run #2). **G4 fix portfolio impact = $0** (Run #3 vs Run #2 final equity delta = $0; halt timestamps identical). **Root cause is NOT BT-001 measurement methodology** (BT-001 closed correctly 2026-05-13). **Root cause IS R-13 long-tail trading-logic gap** — specifically Slot_H pyramid clustering pattern that triggers `circuit_breaker_pingpong` at sim 2021-01-14 14:59:21, regardless of whether DISABLE_G4_FIXES is on or off. IMPL-FIX-011a/b/c/d only addressed Slot_T/G/G2/B/K (per Q1 paired canary divergence findings); Slot_H clustering pattern is the next slot in the long-tail chain that needs targeted predicate calibration. **Follow-up: IMPL-FIX-012 authored** (Slot_H pyramid same-bar cooldown — see §6 cross-links).

### Run #3 root-cause analysis (2026-05-14, BT-001 single-pass methodology)

The catastrophic drift is **NOT a BT-001 closure regression**. BT-001 (closed 2026-05-13) correctly redefined the measurement methodology from "rewrite-G4-OFF vs baseline" → "rewrite-G4-ON vs baseline single-pass" — eliminating the DISABLE_G4_FIXES vs 16-active-slot-rewrite confound. Run #3 executed precisely the BT-001-mandated configuration (default G4-ON build, no `#define DISABLE_G4_FIXES`, single-pass against `regression_5yr_g4.ini`).

**The Run #3 finding is that BT-001 was necessary but not sufficient.** With G4 fixes ON:

1. **Same halt timestamp as Run #2** — `2021-01-14 14:59:21` (sub-millisecond precision identical)
2. **Same halt class** — `circuit_breaker_pingpong` Slot_H magic=205, dir=1, delta=0s, threshold=3s
3. **Same HALTED_STABLE timestamp** — `2021-05-25 10:07:53`
4. **Same final equity** — $470.83 (matches Run #2 to the cent)
5. **Same per-slot entry counts in 14-day pre-halt window** — byte-identical to Run #2 across all 21 slots
6. **G4 BI SL fix verified working** — 11/11 BI entries with `sl != 0` (Run #2 had `sl = 0` per ADR-009 pre-G4 baseline) ✅
7. **G4 J magic-J fix not exercised** — 0 J entries fire in 14-day pre-halt window (Slot_J is CD-follower; CD chain has only 1 fire in window)

**Conclusion:** G4 fixes ARE correctly applied at the slot level (BI verified 11/11 with proper SL inheritance) but the halt fires before the per-slot differential matters at portfolio scale. The proximate trigger of `circuit_breaker_pingpong` is **Slot_H pyramid clustering** — 7 H entries in 14 sim days, several within sub-second windows. Slot_H is **not** addressed by IMPL-FIX-011a/b/c/d (which targeted T/G/G2/B/K predicates per Q1 paired canary divergence ranking). Slot_H is the next slot in the **R-13 long-tail trading-logic translation gap** (per impl-plan Open Risks R-13).

**Per Run #3 evidence + Open Risks R-13 long-tail framing — Slot_H is the next IMPL-FIX target.** New ticket IMPL-FIX-012 authored to investigate Slot_H pyramid same-bar cooldown (per regression-bucket-a.md §5 step 4 recommendation) + per-bar throttle on `_TryExit` close path (Slot_H's H4-bar age-gate may fire multiple closes within one tick).

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

### Run #3 artifacts (2026-05-14)

- Tester log abridged: `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514-tester.txt` (317 lines; init + entry/exit/halt events + DD milestones every 5%)
- Journal jsonl: `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.jsonl` (72 records: 40 entry + 30 exit + 1 halt + 1 halt_stable; **byte-identical record count + timestamps + slot_counts vs Run #2**)
- Halt event raw: `{"event_type":"halt","slot_id":"system","halt_reason":"circuit_breaker_pingpong","portfolio_summary.equity":1107.12,...}` @ 2021-01-14 14:59:21
- Halt_stable event raw: `{"event_type":"halt_stable","slot_id":"system","portfolio_summary.equity":470.83,"triggering_function":"CEAState::TryTransitionToStable"}` @ 2021-05-25 10:07:53
- G1 compile log: `Result: 0 errors, 0 warnings, 4977 ms elapsed` (default G4-ON build; `#define DISABLE_G4_FIXES` confirmed absent via grep exit=1 + verified via §4b BI sl != 0 evidence)
- Operator session: 22:22:39 launch → 22:40 killed (per HALTED_STABLE-invariant precedent; full silent grind to 2025-12-31 would have produced zero new info per Run #2 §4 documented behavior)
- Parse script: `simulation/scripts/impl062_parse_run.sh` (NEW) — bash + jq pipeline; companion PowerShell pipeline used due to jq path issue in this shell

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
| `simulation/headless-tests/regression_5yr_no_g4.ini` | Committed headless Tester config for reproducibility (TD-02 §13.6) — used in Run #2 (DISABLE_G4_FIXES) |
| `simulation/headless-tests/regression_5yr_g4.ini` | Committed headless Tester config — used in Run #3 (rewrite-G4-ON default build, BT-001 single-pass methodology) |
| `backtrack-log.md § BT-001` | Resolved 2026-05-13 — measurement-methodology re-baseline (necessary precondition for Run #3) |
| IMPL-FIX-012 (NEW 2026-05-14) | Slot_H pyramid same-bar cooldown follow-up — addresses R-13 long-tail proximate trigger of `circuit_breaker_pingpong` revealed by Run #3 |
| Open Risks R-13 (impl-plan.md) | Long-tail trading-logic translation gap — Run #3 confirms R-13 still active for non-T/G/G2/B/K slots; Slot_H is next IMPL-FIX target |

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

**Deferred E-ACs (originally registered in `docs/state/deferred-ac-registry.md`):**
- [ ] E-AC #1: `|Bucket A drift| ≤ 25%` NFR-1.1 — **🔴 EXERCISED via Run #3 (2026-05-14) → drift = 100.0022% — FAIL**. Cannot close `[x]`. Stays Active in registry pending IMPL-FIX-012 (Slot_H pyramid same-bar cooldown) closure + Run #4 retry.
- [ ] E-AC #2: All 21 per-slot deviations ≤ 10% NFR-1.6 — **🔴 N/A** — truncated 14-day pre-halt window vs 5-yr baseline = not measurable; halt prevents 5-yr completion. Stays Active in registry; same blocker as E-AC #1 (gated on IMPL-FIX-012 → Run #4).

**Run #3 outcome (2026-05-14):** Measurement methodology now correct (BT-001 closed; default G4-ON build, single-pass per BA `03 § NFR-1.1 Verification`); empirical drift catastrophic but G4 fix portfolio impact = $0 (matches Run #2 byte-identical); reveals R-13 long-tail trading-logic gap (Slot_H pyramid clustering) as the actual NFR-1.1 blocker. Follow-up IMPL-FIX-012 authored.

**Risk-if-missed:** NFR-1.1 acceptance signal still not satisfied; rewrite parity vs PhoenicisN2.10 baseline ($24.27M) NOT certified. P4 Tier 2 Phase Gate close + MVP NFR-1.1 acceptance signal blocked until IMPL-FIX-012 closure → Run #4 retry passes ≤ 25%.
**Expiry:** 2026-05-28 (14d from Run #3 closure 2026-05-14; renewal #1 of max 2 per registry policy).
