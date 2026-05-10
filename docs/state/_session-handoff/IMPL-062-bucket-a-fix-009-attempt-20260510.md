# IMPL-062 Bucket A Run #3 (post-IMPL-FIX-009) — STILL FAILED, but progressed further

**Date:** 2026-05-10 16:43–16:52 (killed at ~9 min wall-clock; sim reached 2021-11-23)
**Spec:** `simulation/headless-tests/regression_5yr_no_g4.ini` with `#define DISABLE_G4_FIXES` build
**Build:** `MQL5/Experts/PhoenicisNex/PhoenicisNex.ex5` 332,386 bytes (DISABLE_G4_FIXES + FIX-009 patches all on)

## Run progression vs prior attempts

| Attempt | Build | Sim time reached | Final balance | Wall-clock | Halt reason |
|---------|-------|------------------|---------------|------------|-------------|
| Run #1 (commit `45bba53`) | DISABLE_G4_FIXES (lot=2.90 cap) | 2021-01-04 17:10:00 | $512.80 | 1m 26s | Day-1 broker stop-out cascade (lot 2.90 × 6 fills exhausted $1000 margin) |
| Run #2 (post-FIX-006, dimensional formula landed) | DISABLE_G4_FIXES (lot 0.10-0.40) | 2021-01-04 (still) | $411.43 | 1m 46s | Day-1 cascade — Slot_G2 OrderSend/OnTradeTransaction race, 76/80 G2 fills in 4-sec |
| Run #3 (post-FIX-007/008/009) | DISABLE_G4_FIXES (lot 0.10-0.40) | **2021-11-23 12:04** (~10.5 sim-months ✅) | depleted via realized P&L losses | 9 min wall-clock (killed) | NOT a code cascade — actual trading-logic depleted account |

## Verification — structural fixes ALL working

- **Lot sizing (FIX-006 dimensional formula):** ticket #2 Slot_C lot=0.30, #3 Slot_M lot=0.40, #4 Slot_T lot=0.36, #6 Slot_Q lot=0.30, #7 Slot_G2 lot=0.10, #8 Slot_G lot=0.19 — all dimensional, none clamped to MAX 2.90 cap ✅
- **Slot_G2/S anti-pyramid (FIX-007 v2 H4-bar gate):** confirmed working — Slot_G2 fired only 1 entry per H4 bar; Slot_S fired ≤1 per H4 bar ✅
- **Slot_G anti-pyramid (FIX-008):** Slot_G fired #8 lot=0.19 + later entries 1/bar ✅
- **CircuitBreaker storm prevented (FIX-008 ring-buffer reset + state guard):** no ping_pong spam observed in this run ✅
- **state.json bar-throttle (FIX-009):** confirmed by 9-min wall-clock for ~10.5 sim-months — pace ~70 sim-day per wall-min, dramatically faster than 6-30 pace pre-FIX-009 ✅

## NEW finding — R-12 (logging hygiene + suspected predicate gap)

`[ev=eoverload_triggered]` Info emit fires **every tick** when persistent WPR/force conditions hold. Sample at log tail (sim 2021-11-23 12:03:44 → 12:04:39 / ~55 sim-sec):

```
[INFO][slot=xslot][ev=eoverload_triggered][magic=200] wpr_abs=74.70 force=-13.68 gap_pip=43.5 lot_div=8.0 halted=false
[INFO][slot=xslot][ev=eoverload_triggered][magic=200] wpr_abs=74.63 force=-13.68 gap_pip=43.5 lot_div=8.0 halted=false
... (repeats ~50× in 55 sim-sec; same wpr/force/gap_pip values; only wpr_abs ticks fluctuate ~1-2%)
```

This is the same defect class as IMPL-FIX-008 R-10 `exit_profit_gate` spam. Source: `services/CrossSlotCoordinator.mqh::RunEOverload` predicate fires every tick when WPR>90 OR Force<-11 + last_gap_pip>=33 conditions persist; the helper lacks a one-shot trigger latch (legacy would fire once per condition activation, then suppress until condition re-arms).

**Direct cost:** log volume — Bucket A run produced ~5.4 GB of log in 9 min before being killed. Projected 5-yr log: ~180 GB.
**Indirect cost:** if `RunEOverload` does any actual side-effect every tick (not just emit), it could be over-triggering exit/scaling logic that legacy fires once per condition.

Other event distribution (5MB head sample — first 9 wall-min of run):
- `ev=entry_sell` × 12,631 — high-rate emit; possibly from a slot's Evaluate that wasn't gated. Needs targeted grep.
- `ev=cd_demote_triggered` × 255 — CD-pool demote firing aggressively (Slot_C/D demote condition); possibly fires per-tick instead of one-shot.
- `ev=new_worst_dd` × 166 — PortfolioMonitor reporting drawdown growing — confirms account losing capital steadily.
- `ev=order_sent` × 6 (in head) — only 6 actual fills in first 5 MB / first wall-min of run.

## Comparison to legacy EA

Legacy `PhoenicisN2.10_stable.ex5` ran the same 5-yr window (2021.01.01 → 2025.12.31) in 0:59:54.317 wall-clock and reached **$24,564,949.07** final balance (+1.2% vs historical baseline $24.27M). 463+ deals across 5 years. Worst DD -11.04%.

The strategy + data + broker config are confirmed sound. Rewrite has trading-logic translation defects beyond what FIX-006/007/008/009 addressed.

## Build state at killpoint

After kill, default build restored:
- `PhoenicisNex.mq5` `#define DISABLE_G4_FIXES` line removed (3-line block reverted)
- G1 recompile PASS — `.ex5` 332,248 bytes at 16:55 (default build, FIX-006/007/008/009 all on, G4-fixes ON)
- Working tree status: clean post-FIX-009 commit; this evidence artifact + legacy_5yr.ini + new state-doc updates pending

## Verdict

**🔴 Bucket A NFR-1.1 ACCEPTANCE SIGNAL FAILED** — drift ≈ 100% (final balance ~0 vs baseline $24.27M) far exceeds ≤ 25% target.

**🔴 R-13 NEW (Open Risk)** — Rewrite trading-logic translation gap beyond R-8 lot-sizing scope. Specifically:
- 18 of 21 slots lack per-slot anti-pyramid latches (only G/G2/S have H4-bar gate)
- xslot helpers (`RunEOverload` confirmed; suspect `RunCOverload`, `RunGOverload`, `RunSafePort`, `RunOrderGroup2`, `RunForceCutloss`, `ExtraCheckFunction2`) lack one-shot trigger latches → fire every tick on persistent conditions
- `cd_demote_triggered` aggregate suggests CD-pool demote logic miscalibrated
- `entry_sell` 12,631 events suggests a slot's per-tick emit pattern that wasn't gated

## Recommended next session

**Author IMPL-FIX-010** task block (L-XL size, multi-slot scope). Investigation method: side-by-side journal-diff between rewrite (rebuild with TradeJournal Logger.Info recording every entry+exit signal with full predicate state) and legacy (extract from Tester log at signal points). Identify divergence locations, fix per-slot Evaluate predicates + helper latches, retest Q1 canary, escalate to 5-yr Bucket A. Estimated 4-8 hours over 2-3 sessions.

**Bucket B regression NOT executed this session** — running it without Bucket A passing first would yield meaningless drift comparison (G4 vs no-G4 attribution requires no-G4 baseline to be valid first).

## Disk hygiene note

Tester log grew from 193 MB → 5.4 GB in 9 min before kill, then was rotated to 3.85 MB by MT5 when legacy run started. Net disk impact: rotated log gone; current log small. No cleanup needed.
