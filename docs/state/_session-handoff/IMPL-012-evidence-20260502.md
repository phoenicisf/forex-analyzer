# IMPL-012 — Evidence Artifact

**Date:** 2026-05-02
**Task:** M [ea] — `inputs/Inputs_General.mqh` (cross-slot inputs, FR-1.1 + NFR-4.3 + NFR-6.3)
**Closure:** parallel batch (orchestrator: Opus 4.7; subagent: Sonnet 4.6)

## S-AC verification

| AC bullet | Verification | Result |
|-----------|--------------|--------|
| ≥ 20 `input` declarations w/ `group="General"` annotation | `grep -c '^input '` returns 22 (21 declarations + 1 group line); `grep '^input group'` returns `input group "General"` | ✅ |
| All defaults match CodeWiki §1.3 baseline | All 21 rows verified against §6.B table in shared-context verbatim — types, names (Inp-prefixed), defaults identical | ✅ |
| No DLL types (NFR-7.2) | `grep -c '#import'` returns 0 | ✅ |

## E-AC `[probe]` — MT5 input dialog group rendering

**Deferred** until entry `.mq5` exists (IMPL-018+) and `Inputs_General.mqh` is `#include`d by it. At that point, MT5 attach EA → input dialog will render a "General" group with 21 input rows as declared. This follows IMPL-014 precedent (same deferral pattern for TimeGates/Pending/Logging groups).

Evidence stub: file exists and declares `input group "General"` + 21 typed declarations — structure is correct for MT5 dialog rendering once wired into entry point.

## Grep evidence

```
$ grep -c '^input ' MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh
22   # 21 input <type> declarations + 1 input group line

$ grep -c '#import' MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh
0    # NFR-7.2 satisfied

$ grep -E '^input group' MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh
input group "General"

$ grep -E '^#ifndef|^#define|^#endif' MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh
#ifndef PHOENICISNEX_INPUTS_GENERAL_MQH
#define PHOENICISNEX_INPUTS_GENERAL_MQH
#endif // PHOENICISNEX_INPUTS_GENERAL_MQH
```

## Defaults verification (all 21 rows)

| Input name | Type | Default | CodeWiki §6.B source | Verified |
|---|---|---|---|---|
| `InpInteruptRatioDecrease` | double | 8.0 | InteruptRatioDecrease = 8 | ✅ |
| `InpMainOverloadRatioDecrease` | double | 4.0 | MainOverloadRatioDecrease = 4 | ✅ |
| `InpUseCOverload` | bool | true | UseCOverload = true | ✅ |
| `InpUseOverloadAutoRange` | bool | true | UseOverloadAutoRange = true | ✅ |
| `InpOverLoadUseLastLot` | bool | true | OverLoadUseLastLot = true | ✅ |
| `InpFIDValue` | int | 21 | FIDValue = 21 | ✅ |
| `InpTradeOnHNN` | bool | false | TradeOnHNN = false | ✅ |
| `InpZigZagPeriod` | ENUM_TIMEFRAMES | PERIOD_M5 | ZigZagPeriod = PERIOD_M5 | ✅ |
| `InpLADXMLevel` | double | 30.0 | LADXMLevel = 30 | ✅ |
| `InpLADXMLevelMin` | double | 22.0 | LADXMLevelMin = 22 | ✅ |
| `InpJPip1StBetweenC` | int | -10 | JPip1StBetweenC = -10 | ✅ |
| `InpJPip1StBetweenD` | int | -13 | JPip1StBetweenD = -13 | ✅ |
| `InpFRatioDecrease` | double | 1.0 | FRatioDecrease = 1 | ✅ |
| `InpJRatioDecrease` | double | 2.3 | JRatioDecrease = 2.3 | ✅ |
| `InpGRatioDecrease` | double | 10.0 | GRatioDecrease = 10 | ✅ |
| `InpGORatioDecrease` | double | 10.0 | GORatioDecrease = 10 | ✅ |
| `InpHRatioDecrease` | double | 10.0 | HRatioDecrease = 10 | ✅ |
| `InpGRisk` | int | 15 | GRisk = 15 | ✅ |
| `InpMainRiskRatio` | double | 1.0 | MainRiskRatio = 1 (LibCommon) | ✅ |
| `InpLimitMaxLotSizeRatio` | double | 2.9 | LimitMaxLotSizeRatio = 2.9 (LibCommon) | ✅ |
| `InpNormalTakeProfitPIP` | int | 48 | NormalTakeProfitPIP = 48 (LibCommon) | ✅ |

## NFR-1.1 compliance note

All 21 defaults match CodeWiki §1.3 verbatim — no deviation from baseline. Changing these defaults at runtime would diverge from the 5-yr backtest baseline (PF 8.96, Sharpe 9.17, Net Profit $24.27M). NFR-1.1 Bucket A drift ≤ 25% preserved.

## ENUM_TIMEFRAMES note

`InpZigZagPeriod` uses MQL5 built-in `ENUM_TIMEFRAMES` — this is NOT a DLL type; it is part of the MQL5 standard library. NFR-7.2 constraint (0 external DLLs) is satisfied.

## LOC budget

File is 28 lines total — well within ≤ 200 LOC budget per NFR-4.1 / `.claude/rules/ea.md`.

## 4-Gate Definition of Done

G1-G4 N/A (header-only; no entry `.mq5` yet). Static review confirms:
- Proper include guard `PHOENICISNEX_INPUTS_GENERAL_MQH`
- Single `input group "General"` line immediately after guard per shared-context §2 contract
- 21 typed `input` declarations, all `Inp`-prefixed per ea.md naming convention
- No `#import` directives (NFR-7.2 = 0 external DLLs)
- Every declaration on its own line with trailing `// <role> [<source>]` comment

## Scope verification

Files written: `MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh` only. No other files touched. `.claude/`, `docs/state/overview.md`, `docs/state/impl-plan.md` not modified.
