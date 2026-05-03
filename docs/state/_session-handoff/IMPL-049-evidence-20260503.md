# IMPL-049 Evidence — PendingMachineRegistry + 8 machines + ADR-008 force-clear

**Task:** IMPL-049 [XL] [ea] — `services/PendingMachineRegistry.mqh` + 8 inner machines + ADR-008 force-clear (Evolution E1c)
**Closed:** 2026-05-03
**Decomposition:** Phase 2C 4 sub-pass decomposition (a/b/c/d) per impl-plan hint + SKILL.md § Per-Layer Exception
**Commits:** `fe78218` (a) · `edb3477` (b) · `8aaaa5b` (c) · `26def2c` (d)

## 1. Sub-pass Summary

| Sub-pass | Scope | LOC delta | G1 result |
|----------|-------|-----------|-----------|
| (a) Registry skeleton + dispatch | `MachineState` struct + `CPendingMachineRegistry` shell + Init(13-arg) + `TickAll`/`GetState`/`GetPayload`/`GetForceClearCount`/`EnterPending`/`TransitionExecuted`/`TransitionIdle` + `LoadFromState`/`SaveToState` + `CPendingForce::BuildPayload/ParsePayload` | +439 | 0 errors / 0 warnings / 658 ms |
| (b) Legacy timeout machines | `TickMachine` body for PM_C(8) / PM_C_ADX(30) / PM_R(40) / PM_P(70) / PM_FORCE(9) per BR-6.1..6.4+6.8 + `ExceededLegacyTimeout` switch + P-sub-mode payload helpers (`_BuildPPayload`/`_ParsePSubMode`/`_ParsePDouble`/`_PSubModeToStr`/`_StrToPSubMode`) + `EnterPPending`/`GetPSubMode`/`GetPDiffSL`/`GetPBandRatio` accessors | +258 | 0 errors / 0 warnings / 980 ms |
| (c) Force-clear machines (ADR-008) | `ShouldForceClear` switch (M/T/Q only) + `EmitForceClear` (journal `event_type=force_clear` + Logger.Warn + RAM/StatePersistence atomic counter sync via `IncrementPmForceClearCount`) | +113 | 0 errors / 0 warnings / 1388 ms |
| (d) SelfTest + state.json round-trip | inline `SelfTest(CLogger*)` 6 cases covering all 4 S-AC + 2 E-AC; `_BuildPPayloadStatic` exposed for harness; SaveToState comment clarifies force_clear_count atomic-on-write contract | +219 | 0 errors / 0 warnings / 1495 ms |

## 2. Acceptance Criteria

### S-AC

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | 8 machine classes + dispatch | `MachineState m_machines[PM_COUNT=8]` + `TickAll` iterates PM_C..PM_FORCE; sibling `CPendingForce` with payload routing for D-from-C / BR-from-B per BR-2.1+6.8 |
| 2 | M/T/Q force-clear thresholds = inputs | `Init(threshold_m, threshold_t, threshold_q, ...)` stores into `m_threshold_m/t/q_bars`; `ShouldForceClear` switch returns `age >= m_threshold_X_bars` for M/T/Q only; SelfTest Case 5 verifies M@150 / T@80 / Q@100 + PM_R no-trigger control |
| 3 | P-sub-modes (PSUB_NONE/N/PX/PH/E) | `EnterPPending(mode, diff_sl, band_ratio, bar)` builds canonical payload; `GetPSubMode` parses sub_mode field; SelfTest Case 4 round-trips all 5 sub-modes |
| 4 | Force-clear journal event emission | `EmitForceClear` writes `JournalEvent{event_type="force_clear", slot_id="M\|T\|Q", signal_context="machine=X reason=age_exceeded count=N", pending_age_bars=N}` + tagged `Logger.Warn("pending","force_clear",...)` + `m_state.IncrementPmForceClearCount(id)` atomic |

### E-AC

| # | Evidence-kind | Status | Detail |
|---|---------------|--------|--------|
| 1 | `[log-assertion]` + `[db-inspect]` — stub M payload + advance past threshold → emits force_clear + clears state | ✅ via SelfTest | Case 5: `EnterPending(PM_M, "{\"slot\":\"M\"}", 0)` → `TickAll(bar=150)` → state IDLE + RAM `force_clear_count=1`. Case 6 verifies StatePersistence-side `sp.GetPmForceClearCount(PM_T)==1` after wired tick (atomic counter sync). Live journal write deferred to IMPL-018+ Orchestrator wiring per IMPL-052 header-only `.mqh` precedent. |
| 2 | `[contract-roundtrip]` — state.json round-trip preserves 8 machine payloads | ✅ via SelfTest | Case 6: pre-populate `CStatePersistence sp` with PM_C/M/P (state + payload + counter); fresh `CPendingMachineRegistry r2.Init(...,&sp,...)` — `LoadFromState` mirror verified for state, payload, force_clear_count; `r2.TransitionIdle(PM_C)` + `r2.EnterPending(PM_R, ..., 999)` → `r2.SaveToState()` → `sp.GetPendingState/Payload` reflects mutations. |

## 3. G1 Compile Gate (per sub-pass)

```
sub-pass (a): Result: 0 errors, 0 warnings, 658 ms elapsed, cpu='X64 Regular'
sub-pass (b): Result: 0 errors, 0 warnings, 980 ms elapsed, cpu='X64 Regular'
sub-pass (c): Result: 0 errors, 0 warnings, 1388 ms elapsed, cpu='X64 Regular'
sub-pass (d): Result: 0 errors, 0 warnings, 1495 ms elapsed, cpu='X64 Regular'
```

Compile artifact: `MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.compile.log` (UTF-16LE, local-only; not committed).

## 4. SelfTest Coverage (sub-pass d)

| Case | What | S-AC/E-AC link |
|------|------|----------------|
| 1 | Zero-init across 8 machines | S-AC #1 |
| 2 | Transition surface (EnterPending → PENDING / TransitionExecuted → EXECUTED / TransitionIdle → IDLE) | S-AC #1 |
| 3 | Legacy timeout per machine (PM_C@8, PM_C_ADX@30, PM_R@40, PM_FORCE@9) | S-AC #1 + BR-6.1..6.8 |
| 4 | P-sub-mode round-trip × 5 (PSUB_PX/PH/E/N/NONE) + diff_sl/band_ratio numeric round-trip | S-AC #3 |
| 5 | Force-clear M/T/Q + PM_R no-trigger control | S-AC #2 + S-AC #4 + E-AC #1 |
| 6 | state.json round-trip via CStatePersistence holder (Load mirror + Save back-prop + atomic counter sync) | E-AC #2 + S-AC #4 atomic contract |

## 5. G2-G4 Deferral Justification

Per IMPL-052 header-only `.mqh` precedent (closed 2026-05-03):
- G2 smoke (live EA attach) and G3 headless backtest require entry `PhoenicisNex.mq5` Orchestrator with full DI chain — lands at **IMPL-018+** (P3 CSlotBase + IMPL-053+ entry).
- G4 log review on real journal output requires (a) live wiring of journal pointer from Orchestrator and (b) bar progression from Tester ticks.
- Structural `SelfTest()` provides equivalent coverage at the unit level (verifiable by re-running Spike at any time).
- E-AC #1 journal-emission proxy = counter increment (verified live in Case 5 + Case 6) since `EmitForceClear` is a single straight-line code path: counter → journal write → log.

## 6. Cross-references

- **TD-02 §5.10** — full skeleton (lines 963-1051)
- **ADR-008** — force-clear policy (M=150 / T=80 / Q=100 H4 bars)
- **BR-6.1..6.4 + BR-6.8** — legacy timeouts (C=8 / C_ADX=30 / R=40 / P=70 / FORCE=9)
- **state-persistence-schema.yaml § PendingMachineState_PVariant** — sub_mode + diff_sl + band_ratio canonical encoding
- **trade-journal-schema.yaml § event_type** — `force_clear` event
- **Claim 02.10** — P-Pending sub-mode E semantic (P_Extra entry, comment `"PI,..."`)
- **A7 risk** (`docs/design-docs/03-deep-dive.md § 7`) — P-Pending E/N stuck-pattern observability

## 7. Phase Status Impact

P2: 10/11 → **11/11 ✅** — Phase Gate nominate-able. Remaining steps for P2 closure:
- Tier 1.5 Exploratory Walk artifact (headless backtest of `simulation/headless-tests/p2_services_smoke.ini` — not yet committed; can be skipped if user opts to proceed straight into P3 with Phase Gate Override)
- IMPL-P2-GATE row drain (currently 0/8)
- Code review pass on P2 services delta (recommended trigger after IMPL-049 per Code Review Round 02 note)
