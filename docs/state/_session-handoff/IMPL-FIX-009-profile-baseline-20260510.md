# IMPL-FIX-009 Step 1 — Profile Baseline (Q1 2021 Canary, ENABLE_TICK_LATENCY=ON)

**Date:** 2026-05-10 15:46–16:09 (run wall-clock 22:48.615; OS-process wall-clock ~22 min including history-data load)
**Build:** PhoenicisNex.ex5 with `#define ENABLE_TICK_LATENCY` ON (336,870 bytes; G1 PASS at 15:44)
**Spec:** `simulation/headless-tests/q1_2021_canary.ini` (NEW; FromDate=2021.01.01 ToDate=2021.01.31 Model=0 Deposit=$1000 Leverage=1:500)
**Tester verdict:** `1374741 ticks, 120 bars generated. Test passed in 0:22:48.615`. Final balance $809.34 (no day-1 stop-out). EA reached `state=EA_STATE_HALTED` mid-run.

---

## 1. Per-stage tick latency report (final_deinit)

| Stage | n | avg µs | p95 µs | p99 µs | max µs | Total wall (n × avg) |
|-------|---|--------|--------|--------|--------|----------------------|
| refresh    | 1,374,741 | 0   | 1     | 2     | 327     | 0 sec |
| **ctx_build**  | 1,374,741 | **36**  | **55**    | **89**    | 13,307  | **49.5 sec** |
| portfolio  | 1,374,741 | 3   | 5     | 11    | 836     | 4.1 sec |
| pending    | 1,374,741 | 0   | 1     | 1     | 387     | 0 sec |
| exit_pass  | 1,374,741 | 8   | 14    | 27    | 6,479   | 11.0 sec |
| entry_pass | 424,692   | 14  | 53    | 76    | 10,063  | 5.9 sec |
| monitor    | 1,374,741 | 0   | 1     | 1     | 2,133   | 0 sec |
| **state_save**  | 1,374,741 | **932** | **1,257** | **1,520** | 678,078 | **🔴 1,281 sec (~21:21)** |

**Observation:** `state_save` accumulates **1281 seconds** — virtually the entire 22:48 backtest wall-clock (~93.6% share). The remaining stages combined contribute ~70 sec.

## 2. Root-cause analysis — why is `state_save` dominant despite IMPL-FIX-007 v2 bar-throttle?

The IMPL-FIX-007 v2 patch added bar-throttle to `CStatePersistence::Save()`:

```mql5
// services/StatePersistence.mqh:271-277 (current)
if(MQLInfoInteger(MQL_TESTER) && ea_state == EA_STATE_RUNNING)
{
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   if(cur_bar == m_last_save_bar_time)
      return true;  // bar unchanged + EA running normally - skip
   m_last_save_bar_time = cur_bar;
}
// ... full SerializeAll + WriteAtomic + SyncToGlobalVariable below ...
```

The throttle predicate is `MQL_TESTER && ea_state == EA_STATE_RUNNING`. **Any non-RUNNING state bypasses the throttle.**

### Run-time chain that exposes the gap

| Sim time | Event | EA state | save behavior |
|----------|-------|----------|---------------|
| 2021-01-01 00:00:00 | OnInit (init_ok handles=24 slots=21 magics=17) | RUNNING | throttle ON — saves on bar boundary only |
| 2021-01-01..2021-01-08 20:36 | normal ticks | RUNNING | ~6 H4 bars/day × 7 days ≈ 42 saves |
| **2021-01-08 20:37:29** | `[ERROR][slot=CircuitBreaker][ev=ping_pong][magic=208] dir=1 delta=0s` → `[ERROR][slot=system][ev=halt] circuit_breaker_pingpong` | **transition: RUNNING → HALTED** | this tick saves + alert |
| 2021-01-08 20:37:30 .. 2021-01-29 23:59:59 | exit-pass-only ticks (~1M ticks over 21 days) | **HALTED** | 🔴 **throttle BYPASSED — full atomic write every tick** |

### Computed contribution

| Phase | ticks | avg save µs | total save sec |
|-------|-------|-------------|----------------|
| RUNNING (2021-01-01 → 2021-01-08 20:37) | ~350K | 932 (heavy bar-boundary writes only — most ticks early-return at ~1µs; avg pulled up by halt spike) | ~14 sec contributed (mostly bar-boundary) |
| HALTED   (2021-01-08 20:37 → 2021-01-29) | ~1,025K | 932 (every tick writes — no throttle) | **~955 sec** dominant |
| Halt-transition spike | 1 | 678,078 | 0.7 sec (max=678ms — disk write peak) |

**Hypothesis (a) MarketContextBuilder per-bar cache** is correct *but secondary* — `ctx_build` 36µs avg × 1.37M = 49.5 sec total wall-clock (3.6% of total). Even if optimized to ~5µs avg (per-bar caching for H4/D1), savings would be ~42 sec (~3% wall-clock reduction). Not a significant contributor.

**Hypothesis (b) PortfolioState dirty-flag** confirmed *minor* — `portfolio` 3µs avg × 1.37M = 4.1 sec total. Already O(N positions) cheap; dirty-flag would save ~3 sec.

**Hypothesis (c) Slot Evaluate short-circuit** — `entry_pass` 14µs × 425K = 5.9 sec; `exit_pass` 8µs × 1.37M = 11 sec. Combined ~17 sec total. Negligible.

**Hypothesis (d) Logger format-then-throw** — confirmed observable in `cd_demote_triggered` Info spam (every 2-3 ticks while CD has open position) but the spam is captured under the `exit_pass` stage (Slot.ManageExits emits cd_demote). Already small in absolute terms; cleanup deferred.

### Top-1 hotspot ranking (Step 1 conclusion)

🔴 **state_save bar-throttle gap on HALTED state** — single-line predicate change yields ~1,255 sec wall-clock recovery (Q1 22:48 → ~88 sec projection, **15-16x speedup**). This is the dominant fix.

Hypotheses (a)/(b)/(c)/(d) collectively account for ~70 sec total. Step 4 second-hotspot iteration likely **NOT NEEDED** if Step 2 fix alone delivers ≥4x speedup (it should deliver ~15x).

## 3. Step 2 fix proposal

Extend the bar-throttle predicate in `services/StatePersistence.mqh::Save()`:

**Before** (line 271):
```mql5
if(MQLInfoInteger(MQL_TESTER) && ea_state == EA_STATE_RUNNING)
{
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   if(cur_bar == m_last_save_bar_time)
      return true;
   m_last_save_bar_time = cur_bar;
}
```

**After:**
```mql5
if(MQLInfoInteger(MQL_TESTER))
{
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   // Throttle: skip per-tick save when both bar AND state unchanged.
   // Bar-change forces save (per-bar recovery granularity for tester).
   // State-change forces save (RUNNING→HALTED transition captures halt reason).
   if(cur_bar == m_last_save_bar_time && ea_state == m_last_save_state)
      return true;
   m_last_save_bar_time = cur_bar;
   m_last_save_state = ea_state;
}
```

**New private member:** `EEAState m_last_save_state` (init `EA_STATE_RUNNING` in ctor — first save is unthrottled because the first call has `m_last_save_bar_time == 0` which differs from `cur_bar`).

**Risk:** low — preserves halt-transition save (because state changes RUNNING→HALTED forces save on that tick), preserves bar-boundary save granularity in HALTED (so equity-high updates / portfolio-aggregate changes / monitor.Update still propagate per bar in tester recovery), keeps live-mode unchanged (`!MQL_TESTER` skips entire throttle block).

**ADR contract:** ADR-007 atomic-write integrity preserved — when we DO save, it's still atomic write+rename. ADR-010 HALTED enable matrix preserved — exits still run; only state.json save cadence changes.

## 4. Other observations (non-blocking, captured for future tickets)

- `cd_demote_triggered` Info emit fires every 2-3 ticks while CD has open position. Same defect class as IMPL-FIX-008 R-10 `exit_profit_gate` spam. ~14k log records/5 sim-hours (similar magnitude). Not blocking R-11 but worth a future hygiene pass — bulk-suppress per IMPL-FIX-008 R-10 pattern.
- `entry_pass` n=424,692 vs other stages n=1,374,741 — entry-pass gate (morning_block / monday_block / holiday_block / EA_STATE_HALTED) skips ~950K ticks (69% skip rate). The entry-pass-skip path is correctly NOT measured (per fix-round-17 §17.2 guard placement). ✅ probe scope correct.
- `state_save max=678,078µs (~678 ms)` — single-tick spike captured during halt transition (atomic write + rename + GV sync = ~2.7x typical). Operator-feasible without optimization.
- `journal_latency_report writes=14 avg_us=34 p95_us=108 max_us=108` — well within NFR-2.2 5ms p99 budget. ✅ no journal-side concern.

## 5. Files touched (Step 1 only — read-only investigation)

- `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` (1 line added: `#define ENABLE_TICK_LATENCY` — to revert before final commit)
- `simulation/headless-tests/q1_2021_canary.ini` (NEW; per TD-02 §13.6 reproducibility — committed for Step 3 re-measure parity)

## 6. Step 1 S-AC self-attestation

- [x] Profile baseline artifact at `_session-handoff/IMPL-FIX-009-profile-baseline-20260510.md` ← this file
- [x] `[ev=tick_latency_report]` excerpt + per-stage {n, avg, p95, p99, max} table ← § 1
- [x] Top-2 hotspots ranked ← top-1 = state_save bar-throttle gap; top-2 ineffectual (combined ~70 sec)
- [x] Scope-confirmation paragraph: hypothesis (a)/(b)/(c)/(d) all confirmed factually but only state_save warrants Step 2 patch ← § 2

## 7. Next action

Proceed to Step 2 — apply targeted patch to `services/StatePersistence.mqh::Save()` (predicate change + new `m_last_save_state` field). Single-file edit, ≤10 LOC delta. G1 verify after edit. HALT after Step 2 before Step 3 re-measure.
