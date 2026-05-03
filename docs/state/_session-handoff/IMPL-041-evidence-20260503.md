# IMPL-041 Evidence — RiskManager ClampLot (inherited close)

**Date:** 2026-05-03
**Closure mode:** docs-only inherited close after IMPL-040 implementation + Code Review Round 02 fix sweep
**Code owner artifact:** `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh`
**Primary upstream evidence:** `docs/state/_session-handoff/IMPL-040-evidence-20260503.md`

## Why this task closes without a new code diff

`IMPL-041` is a narrow XS extraction of `CRiskManager::ClampLot()`, but the method body was already implemented inside `IMPL-040` when `RiskManager.mqh` landed. The plan, overview, and handoff all already describe IMPL-041 as "body already integrated into IMPL-040; trivial close". This pass reconciles state only.

## S-AC inherited evidence

| AC | Evidence |
|---|---|
| Returns clamped lot >= `SYMBOL_VOLUME_MIN` and <= cap | `ClampLot()` reads `SYMBOL_VOLUME_MIN`, `SYMBOL_VOLUME_MAX`, `ACCOUNT_BALANCE`, computes `cap = m_limit_max_lot_size_ratio * balance / 1000.0`, forces `cap >= floor`, then clamps `raw_lot` into `[floor, cap]`. Structural checks already present in `CRiskManager::SelfTest()` case 5 (`ClampLot(0.0,"C")`) and case 6 (`ClampLot(99.0,"C")`). |
| Logger Warn when raw lot is outside `[floor, cap]` | `ClampLot()` emits `m_logger.Warn("RiskManager", "clamp_applied", ...)` when `was_clamped == true`. |

## E-AC inherited evidence

| E-AC | Evidence / rationale |
|---|---|
| Smoke: `ClampLot(raw=99.0, slot=C)` on `$1000` balance returns `<=` BR-4.2 cap `[log-assertion]` | The exact input surface is already covered structurally by SelfTest case 6 (`ClampLot(99.0,"C")`). Live log-assertion remains coupled to the same header-only wire-up boundary as IMPL-040: no entry `.mq5` includes `RiskManager.mqh` yet, so the repo's existing header-only precedent keeps runtime smoke bundled to IMPL-018+ orchestration. This task inherits that closure posture rather than duplicating code or inventing a second runtime surface. |

## Gate note

- **G1:** no new source delta; inherited baseline remains `Spike_StatePersistence` compile = `0 errors / 0 warnings` from IMPL-040 evidence.
- **G2-G4:** no new runnable surface introduced by this close; inheritance follows the current P2 header-only precedent already recorded on IMPL-040.

## Result

IMPL-041 can be marked closed as an inherited-scope task. The implementation and proof surface already live under IMPL-040; this artifact exists to make the closure explicit and keep state files consistent.
