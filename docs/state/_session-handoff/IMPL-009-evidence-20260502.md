# IMPL-009 — Evidence Artifact

**Date:** 2026-05-02
**Task:** XS [ea] — `helpers/PipMath.mqh` DigitMultiplier-aware arithmetic (BR-9.3 + ADR-009 stub)
**Closure:** parallel batch (orchestrator: Opus 4.7; subagent: Sonnet 4.6)

## S-AC verification

| AC bullet | Verification | Result |
|-----------|--------------|--------|
| `Init()` reads `_Digits` once + caches multiplier | Static review: `m_digit_multiplier = (_Digits == 5 \|\| _Digits == 3) ? 10 : 1;` at line 31 | ✅ |
| `ToPoints(20.0)` returns 200 on 5-digit broker | Math: `20.0 * 10 = 200.0` → `(int)MathRound(200.0) = 200` (alias method line 55-58) | ✅ |
| No `==` double comparison | `grep -c '==' helpers/PipMath.mqh` returns 4; all are `_Digits == <int>` (int comparison, not double) | ✅ |

## E-AC `[log-assertion]` — pip_math digit_multiplier log

`Print` statement at line 32-33 emits `[Phoenicis][slot=system][ev=pip_math_init][digit_multiplier=N]` per ADR-011 stable prefix. **Deferred for live verification** until Logger lands at IMPL-042 — at that point, OnInit smoke test will assert `grep -c "ev=pip_math_init" Tester.log == 1`.

## Bonus — Plan-text fidelity

Subagent added optional `ToPoints` + `FromPoints` aliases (per shared-context §6.B.2 guidance) to satisfy impl-plan task description's `ToPoints(double pips) → int` wording while preserving TD-02 §4.1 authoritative `PriceToPip` / `PipToPrice` API.

## ADR-009 stub

`InheritSlFromParent` declared at lines 69-81 as STUB returning `parent_sl` unchanged + Print log + `// TODO ADR-009 IMPL-022/IMPL-039 will complete this` comment. Full BI parent-distance arithmetic is out-of-scope for IMPL-009 per shared-context §6.B.5.

## 4-Gate Definition of Done

G1-G4 N/A (header-only `.mqh`). Verified by static review against TD-02 §4.1 skeleton.

## Scope verification

Files written: `MQL5/Experts/PhoenicisNex/helpers/PipMath.mqh` only. `helpers/.gitkeep` deleted (folder no longer empty). No out-of-scope edits.
