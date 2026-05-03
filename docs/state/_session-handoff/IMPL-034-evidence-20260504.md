# IMPL-034 Evidence — Slot_P + P-Pending sub-modes (PSUB_NONE/N/PX/PH/E)

**Task:** IMPL-034 [L] [ea] — `slots/Slot_P.mqh` + P-Pending sub-modes PX/PH/E/N (⚠️ A7 risk)
**Closed:** 2026-05-04
**Phase:** P3 — Slots
**Process:** Phase 2C 7-step decomposition (single-task `/impl-task IMPL-034`); mirrors IMPL-039/IMPL-037 precedent.

## Files changed / added

| Path | Purpose |
|------|---------|
| `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_P.mqh` | 11 inputs (enable/max/lot/SL floor/ADX min/Force PX gate/diff_sl threshold/TP×3 sub-modes/pyramid gate) |
| `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` | CSlotP class — 6 CSlotBase overrides + sub-mode resolution branch |
| `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_P.mq5` | 6-case SelfTest harness |
| `simulation/headless-tests/slot_P_smoke.ini` | Headless smoke ini (60-day window 2021.01.01–2021.03.02) |

## G1 Compile (orchestrator-side MetaEditor64)

```
Spike_Slot_P:  Result: 0 errors, 0 warnings, 435 ms elapsed, cpu='X64 Regular'
```

Sibling regression (PMR + pyramid neighbors) — all clean:

```
Spike_Slot_R:  Result: 0 errors, 0 warnings, 405 ms elapsed
Spike_Slot_M:  Result: 0 errors, 0 warnings, 420 ms elapsed
Spike_Slot_BI: Result: 0 errors, 0 warnings, 424 ms elapsed
Spike_Slot_LX: Result: 0 errors, 0 warnings, 407 ms elapsed
```

## SelfTest coverage (Case 1–6)

1. `Magic() == MAGIC_P (218)`
2. `SlotId() == "P"`
3. `DependsOn() == 0` — P topologically independent (PMR is shared service, not slot dep)
4. `PendingState() == PENDING_STATE_IDLE` with NULL m_pending guard
5. `Magic()` within BR-1.1 range [200..220]
6. `SlotId()` non-empty (sentinel guard)

## Sub-mode handling (per `04 § 4.4` + A7 risk)

| Sub-mode | Trigger | Comment | TP gate (pip) |
|----------|---------|---------|---------------|
| `PSUB_N`  | Initial pending entry, branch unresolved | (payload only) | — |
| `PSUB_PX` | `\|f1\| > InpPForcePxGate` AND `diff_sl_pip ≥ InpPDiffSlPxThreshold` | `P,MA,PX,1,SL` | 7 (InpPTpPipsPx) |
| `PSUB_PH` | default else branch | `P,MA,PH,1,SL` | 15 (InpPTpPipsPh) |
| `PSUB_E`  | own primary P parent profit ≥ InpPPyramidGatePips (bypass PMR) | `PI,MA,E,1,SL` | 25 (InpPTpPipsE) |

Lock-once semantic: once locked to PX/PH (Phase B), `_ResolvePSubMode` is not re-invoked. E path bypasses PMR entirely (mirrors Slot_LX/Slot_BI pyramid pattern).

## A7 risk note (deferred to P4 IMPL-062)

CodeWiki §3.14 advanced filters NOT implemented in MVP:
- Hull MA structure entry filter
- Recent-bar trigger lookback (≤ 8 bars)
- Band gating extremes (`_diffSL ≥ 250` AND `band_ratio > 75`)
- Per-extension Fibonacci pyramid lot calc (E uses sub-mode-agnostic `RiskManager::ComputeLot("P", …)`)

Sub-mode names + transition rules verified vs `04 § 4.4` lines 326-345; semantic match.

## E-AC status

- [ ] Smoke 60-day backtest with only Slot P active → each sub-mode trigger reflected in `state.json § pending_machines.P.sub_mode` `[db-inspect]` + `[log-assertion]` — **DEFERRED** to IMPL-053+ Orchestrator wiring per IMPL-018+ precedent (header-only `.mqh` until entry `.mq5` consumes via Composition Root + RiskManager OrderSend wiring + 60-day Tester run with InpEnableSlotP=true). Registered in `deferred-ac-registry.md` Active row, expiry 2026-05-18.

## Newly unblocked

None — Slot_P has no downstream P3 deps. Remaining P3 = IMPL-013 (per-slot input completion; now 21/21 with this commit) + Phase Gate path.

## Spec deviation note

S-AC plan text (`docs/state/impl-plan.md` line 1131) lists "All 4 sub-modes implemented (PSUB_NONE/N/PX/PH/E)" — this is **5 enum values** counting `PSUB_NONE` (IDLE state). Implementation:
- PSUB_NONE = unset/IDLE; never written as comment, never persisted to JSON (null)
- PSUB_N = transient post-IDLE pending, awaiting branch decision (1-tick max)
- PSUB_PX, PSUB_PH = primary entry sub-modes (lock-once)
- PSUB_E = pyramid extension (bypass PMR; "PI," prefix)

All 5 values handled in `_PSubModeToStr` (PMR), `_ResolvePSubMode` (slot resolution), `_TpPipsForSubMode` (exit gate selection).
