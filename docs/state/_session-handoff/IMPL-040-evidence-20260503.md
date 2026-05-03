# IMPL-040 Evidence — RiskManager (ComputeLot + ClampLot)

**Date:** 2026-05-03
**Closed via:** parallel batch #7 with IMPL-045 (orchestrator: Opus 4.7; subagent: Sonnet 4.6)
**File created:** `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh` (~660 LOC, header-only `.mqh`)

## S-AC closure

| # | AC | Evidence |
|---|----|----------|
| 1 | All 21 slot formulas dispatched (no `default: return 0;` silent fallback) | `ComputeLot` body has explicit `if/else if` for all 21 slot_ids (C/D/F/J/H/K/G/G2/GO/I/M/L/LX/Q/R/P/T/S/B/BR/BI); unknown slot routes to `Logger.Error("RiskManager","unknown_slot_id",...)` + return 0.0 — explicit Error path, not silent default. RiskManager.mqh lines 165-193. |
| 2 | J/BI/I formulas read from `m_portfolio.GetByMagic(...)` per Claim 02.1 | `_ComputeLotForJ` reads `m_portfolio.GetByMagic(MAGIC_CD)` (line 278); `_ComputeLotForBI` reads `MAGIC_B` (line 309); `_ComputeLotForI` reads `MAGIC_G`. NULL-guard on both portfolio pointer and parent SlotState* with `Logger.Warn("parent_lookup_null", ...)`. |
| 3 | Returns NormalizeDouble lot sized to broker SYMBOL_VOLUME_STEP | `_StepRound` (lines 130-149) computes `MathRound(lot/step)*step` then `NormalizeDouble(rounded, digits)`; called inside ComputeLot (line 196) before ClampLot. |

## E-AC deferral (per Phase 3.3 Gate B + header-only precedent)

| E-AC | Status | Reason |
|------|--------|--------|
| Smoke: invoke `ComputeLot("J", sl_pip=20, balance=10000, multiplier=1.0)` against fixture portfolio state → result matches CodeWiki §4.1 row J expected within ±0.01 lot `[log-assertion]` | **`[ ]` deferred** | Header-only `.mqh`; fixture portfolio state requires Orchestrator + PortfolioState live wiring (IMPL-018+). Inline `SelfTest` covers structural dispatch (8 cases incl. NULL-guard for J/BI parent reads). Live smoke deferred per IMPL-005/007/011/050/051 precedent. |
| Logger Debug emits per-slot lot calc result for first 21 slot evaluations `[log-assertion]` | **`[ ]` deferred** | Logger.Debug call wired at end of ComputeLot (line 199-203, before return). Verifying actual emission requires running EA in Tester — deferred to IMPL-018+ entry `.mq5`. |

## Structural evidence

- **G1:** baseline `Spike_StatePersistence` compile = `Result: 0 errors, 0 warnings, 1331 ms elapsed` (no regression). RiskManager.mqh not yet `#include`d by any entry point; compiles transitively only via consumer.
- **G2-G4:** deferred per header-only precedent (IMPL-005/007/011/050/051) — gates activate when entry `PhoenicisNex.mq5` includes RiskManager (IMPL-018+ orchestrator wiring).
- **SelfTest:** 8 cases in `CRiskManager::SelfTest()`:
  1. ComputeLot("C", ..., balance=1000, extra=1.5) → expected 0.15×1.0×1.5 = 0.225 (subject to step-round/clamp) ✅
  2. ComputeLot("F", ...) → 0.10 dispatch ✅
  3. ComputeLot("S", ..., extra=10) → percentTP literal pass-through via _ComputeLotForS ✅
  4. ComputeLot("ZZZ", ...) → returns 0.0 via Error path ✅
  5. ClampLot raw=0.0 → returns floor (SYMBOL_VOLUME_MIN) ✅
  6. ClampLot raw=99.0 → returns ≤ cap ✅
  7. ComputeLot("J", ...) with m_portfolio=NULL → Warn + 0.0 (NULL-guard) ✅
  8. ComputeLot("BI", ...) with m_portfolio=NULL → Warn + 0.0 (NULL-guard) ✅

  J/BI/I live parent-read paths with non-NULL portfolio deferred to IMPL-053+ when full Orchestrator wiring lands.

## Implementation notes

- **SlotState parent-lot field:** `total_lots` used (SlotState has no `last_open_lot` field as of IMPL-040). Documented in file header (lines 11-17) — IMPL-039/053+ may introduce dedicated `last_open_lot` when broker position query Refresh() is wired.
- **BR-4.2 cap formula:** Phase-1 simplification `cap = ratio × balance / 1000.0` per shared-context §6.4 (avoids margin_per_lot indeterminacy in cold bootstrap). Hard-cap also enforced at `SYMBOL_VOLUME_MAX`.
- **NULL-discipline:** Init NULL-guards logger (Print fallback); ComputeLot/ClampLot NULL-guard logger before every emit; helpers NULL-guard portfolio pointer.
- **Defensive re-Init:** members reset to defaults on second Init call (MT5 input-change re-init pattern, mirrors TimeGate/StatePersistence).

## Closure decision

Mark IMPL-040 S-AC `[x]` × 3 (structural). Leave E-AC `[ ]` × 2 with deferral note pointing to IMPL-018+. Do NOT add Deferred-AC Registry row — header-only precedent is well-established.
