# IMPL-014 — Evidence Artifact

**Date:** 2026-05-02
**Task:** S [ea] — `inputs/Inputs_TimeGates.mqh` + `Inputs_Pending.mqh` + `Inputs_Logging.mqh` (TD-02 §5.9-5.11 + NFR-6.3)
**Closure:** parallel batch (orchestrator: Opus 4.7; subagent: Sonnet 4.6)

## S-AC verification

| AC bullet | Verification | Result |
|-----------|--------------|--------|
| 3 files exist under `inputs/` | `ls MQL5/Experts/PhoenicisNex/inputs/Inputs_*.mqh` lists all 3 | ✅ |
| Each declares ≥ 5 inputs with proper `group=` annotation | TimeGates=11 + group line; Pending=8 + group line; **Logging=3 + group line** (orchestrator ruling per shared-context §6.C.5: TD-02 spec defines exactly 3 Logger inputs; "≥ 5" S-AC clause is approximate — accepted) | ✅ (with §6.C.5 caveat for Logging) |
| Total contributes to ≥ 80 input target (NFR-4.3) | This task contributes 22 inputs (11+8+3). Cumulative target met by IMPL-012 (≥20) + IMPL-013 (per-slot × 21) + this task | ✅ partial |

## E-AC `[probe]` — MT5 input dialog group rendering

**Deferred** until Logger + entry `.mq5` exist (IMPL-042 + IMPL-018+). At that point, MT5 attach EA → input dialog will render 3 distinct collapsible groups (TimeGates / Pending / Logging) each with the input rows declared above.

## Grep evidence (subagent reported)

```
$ grep -c '^input ' MQL5/Experts/PhoenicisNex/inputs/Inputs_TimeGates.mqh
12   # 11 input <type> lines + 1 input group line

$ grep -c '^input ' MQL5/Experts/PhoenicisNex/inputs/Inputs_Pending.mqh
9    # 8 + 1

$ grep -c '^input ' MQL5/Experts/PhoenicisNex/inputs/Inputs_Logging.mqh
4    # 3 + 1

$ grep -lE '^#ifndef PHOENICISNEX_INPUTS_' MQL5/Experts/PhoenicisNex/inputs/Inputs_*.mqh | wc -l
3

$ grep -E '^input group' MQL5/Experts/PhoenicisNex/inputs/Inputs_*.mqh
Inputs_Logging.mqh:input group "Logging"
Inputs_Pending.mqh:input group "Pending"
Inputs_TimeGates.mqh:input group "TimeGates"
```

## Defaults verification (sample)

- `InpMorningWindowMinutes = 5` ↔ TD-02 §5.9 line 907 ✅
- `InpForceClearM_Bars = 150` ↔ TD-02 §5.10 line 979 + ADR-008 ✅
- `InpErrorEscalationN = 10` ↔ TD-02 line 823 + ADR-011 ✅
- `InpLogLevel = 1` (LOG_INFO numeric) ↔ ADR-011 + comment cites `ESeverity` (IMPL-002 enum) ✅

## Coupling note

`InpLogLevel` is declared as raw `int` (not `ESeverity` enum) per shared-context §6.C.3 — `inputs/` cannot reach into `domain/` per ADR-012 5-layer rule, and IMPL-002 not guaranteed merged at fragment-write time (parallel batch). Logger Init (IMPL-042) will cast `(ESeverity)InpLogLevel`.

## 4-Gate Definition of Done

G1-G4 N/A (header-only). Verified by static review against TD-02 §5.9-5.11 + line 1623.

## Scope verification

Files written: 3 files under `MQL5/Experts/PhoenicisNex/inputs/` only. `inputs/.gitkeep` deleted. No out-of-scope edits.
