# IMPL-059 Evidence — `core/Orchestrator` (composition root + OnTick F1 + CleanupPartialInit)

**Task:** IMPL-059 [L] [ea] — `core/Orchestrator.mqh`
**Phase:** P4 — Integration
**Closed:** 2026-05-04 (single-task `/impl-task IMPL-059` Phase 2C 12-step decomposition)
**Workflow:** `andm-impl-engineer` SKILL.md Phase 2C + Empirical Closure Discipline
**Owner:** Kritsana (Opus 4.7)

---

## §1 Scope & Premise

IMPL-059 is the composition root that wires every prior P1/P2/P3/P4 artifact together. Per TD-02 §7.1-7.4.1 verbatim transcription. After this task there is one engineering surface left before MVP attach — IMPL-060 entry `.mq5` (S, thin wrapper). The 16+ deferred-AC rows queued behind "needs Orchestrator runnable surface" all unblock once IMPL-060 closes.

**Pattern precedent:** IMPL-053..058 — header-only `services/*` consumed by Orchestrator. Now Orchestrator itself is header-only consumed by entry `.mq5` (IMPL-060). The G1 spike harness (`spike/Spike_Orchestrator.mq5`) compiles the full `core/Orchestrator.mqh` translation unit with all 19 service headers + 21 slot headers transitively included → proves the entire EA compiles cleanly except for the `.mq5` shell.

---

## §2 Changes Shipped

### `core/Orchestrator.mqh` (NEW)

740+ LOC. Verbatim transcription of TD-02 §7.1-7.4.1. Contains:

1. **Class shape** — 19 owned service/helper/core pointers + 2 cached state mirrors (`m_state_enum`, `m_halt_reason`).
2. **Constructor** — initializes all 19 pointers to NULL + state to RUNNING; defensive dtor calls `CleanupPartialInit("dtor_fallback")`.
3. **`WireServices()`** — Phase A heap construction (steps 1-17 per TD-02 §7.3 DI table); each `new` guarded with NULL check for safe re-call.
4. **`WireSlots()`** — delegates to SlotRegistry per ADR-002 (slot lifecycle owner); returns true if registry constructed.
5. **`OnInit()`** — 3 phases with CleanupPartialInit at all 8 INIT_FAILED return sites:
   - Phase A: `WireServices()` + `WireSlots()`
   - Phase B: 16 `Init()` calls + 2 cycle setters (step 4a Logger↔SP, step 5a SP↔Portfolio) + D-5 `m_journal.SetHaltSink(m_ea_state)` (CEAState : IHaltSink)
   - Phase C: 4 pre-Load guards (`ValidateInputs`/`ValidateSymbol`/`DetectDigitMultiplier`/`CreateHandles`) + `m_atomic.CleanupOrphanTmp` (ADR-007 recovery) + `m_state.Load` degrade-on-fail + `m_portfolio.RegisterAll/Refresh` + `m_ea_state.RestoreFromState` (ADR-010 idle-reset) + 4 post-Load guards (`ValidateSlotRegistry`/`RegisterAll`/`ValidateTopo`/`Open`) + Round-06 06.1 SetPipMath loop on 21 slots + final `[ev=init_ok]` Logger emit
6. **`CleanupPartialInit(failure_reason)`** — TD-02 §7.4.1 reverse-order release (step 17 → 1 monotonic descent); Logger released LAST; emits `[ev=init_failed_cleanup]` via ErrorBypassThrottle before tearing logger down.
7. **`OnTick()`** — F1 14-step pipeline (TD-02 §7.2 verbatim):
   - Steps 1-5: indicator refresh → ctx build → tick boundary → CB check → handle invalid runtime check
   - Step 5b: `m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING)` BEFORE RunExitPass (Claim 01.3 fix — ADR-010 enable matrix)
   - Steps 6-11: time gates → portfolio refresh → pending tick → exit pass + 5 cross-slot exit-side helpers → holiday block → conditional entry pass + RunEOverload
   - Steps 12-14: monitor update → state save → journal sustained-fail halt check → HALTED→HALTED_STABLE transition + summary Alert
8. **`Halt(reason)`** — delegates to `m_ea_state.Halt(reason)` + updates cached mirrors.
9. **`RunExitPass(ctx)`** — iterates registry calling `s.ManageExits(*m_portfolio)` (no ctx; CSlotBase signature deviation from TD).
10. **`RunEntryPass(ctx)`** — iterates registry calling `s.Evaluate(ctx, *m_portfolio)`.
11. **`OnDeinit(reason)`** — final state save + Logger Info `[ev=deinit]` + routes through CleanupPartialInit.
12. **`OnTester()`** — Phase 1 returns `AccountInfoDouble(ACCOUNT_EQUITY)` placeholder (FR-2.5 final tuning at IMPL-061..063).

### `core/SlotRegistry.mqh` (EDIT)

`RegisterAll` body replaced — was stub returning false with "21 derived slot classes pending IMPL-019..039" Logger.Warn. Now heap-news 21 derived slots in BR-2.2 topo order (C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B, BR, BI), `Init`s each with the 8 service pointers, `Add()`s each. Reclaim path on alloc fail or Add reject. 21 new `#include "../slots/Slot_X.mqh"` directives at file head.

### `services/IndicatorService.mqh` (EDIT — IMPL-059 ODR fix)

24 in-class `static const int IDX_X = N;` declarations refactored to in-class declaration only (no value); 24 out-of-class definitions `const int CIndicatorService::IDX_X = N;` appended at file tail. Reason: MQL5 emits error 370 "unresolved static variable" when these are referenced from method bodies of a translation unit that compiles `IndicatorService.mqh` (transitively included by Orchestrator.mqh). Earlier sibling spikes never compiled this header, so the issue was latent. Side-fix: line 366 `(void)scan_fn;` cast → `scan_fn = scan_fn;` no-op self-ref idiom (MQL5 disallows void cast; Round-06 PipMath fix precedent).

### `services/CircuitBreaker.mqh` (EDIT — IMPL-059 ODR fix)

Same pattern: 2 `static const int` (`PING_PONG_THRESHOLD_S`, `NEAR_MISS_THRESHOLD_S`) refactored to in-class decl only + out-of-class definition with values 3 and 5 respectively.

### `spike/Spike_Orchestrator.mq5` (NEW)

Spike harness — Phase A construction + idempotent cleanup smoke. Heap-allocates a fresh `COrchestrator*`, immediately deletes (exercises dtor fallback `CleanupPartialInit("dtor_fallback")` against a never-wired class — proves NULL-safety of every cleanup branch). Then prints `g_orch` state probes (`GetStateEnum`, `GetHaltReason`, `IsLoggerLive`, `IsRegistryLive`) to demonstrate accessor surface. Full Phase B/C exercise deferred to IMPL-060 entry `.mq5` because Phase C `ValidateSymbol` + `CreateHandles` + `m_state.Load` + `m_portfolio.Refresh` need a live EURUSD H4 chart with broker session.

### `simulation/headless-tests/orchestrator_smoke.ini` (NEW)

Per TD-02 §13.6 reproducibility — committed `.ini` for the deferred E-AC smoke run. `Visual=0` + `ShutdownTerminal=1` per G3 contract; activation deferred to IMPL-060 entry `.mq5` runnable surface.

---

## §3 Spec Deviation Log

5 deviations from TD-02 §7.4 — all driven by service-actual signatures diverging from TD pseudo-code (engineer fidelity to actual Init signatures wins per IMPL-053 "Plan text > skeleton text" precedent, applied symmetrically here for "Service-actual signature > skeleton text"):

| ID | Site | TD pseudo-code | Actual | Resolution |
|----|------|----------------|--------|------------|
| D-1 | OnInit step 7 | `m_ctx_builder.Init(m_indicators)` | `Init(ind, lg)` (2 args) | Wire both deps |
| D-2 | OnTick step 4 | `CheckPingPong(*port, ctx.tick_time)` | `CheckPingPong()` zero-arg | Use as-is; service tracks state internally |
| D-3 | OnInit step 13 | `m_xslot.Init(port, tj, lg, m_risk)` | `Init(port, tj, lg, pip)` | Wire `m_pip` (4th arg = CPipMath, not CRiskManager) |
| D-4 | OnInit step 12 | `m_pending.Init(...8 ints, state, journal, logger, portfolio)` | 11-param signature (no portfolio) | Wire 11 args |
| D-5 | After step 17 | (not in TD-02 §7.4 explicit listing) | Add `m_journal.SetHaltSink(m_ea_state)` | CEAState : IHaltSink — wires sustained-failure callback |

All deviations documented in `Orchestrator.mqh` header banner per IMPL-053 precedent.

---

## §4 Dep Resolution

`Deps` field of IMPL-059 in impl-plan: `ALL prior tasks (foundation P1 + services P2 + slots P3 + cross-slot IMPL-053..058)`. Status check:
- P1 17/17 ✅ closed 2026-05-02
- P2 11/11 ✅ closed (under Phase Gate Override Path A 2026-05-03)
- P3 23/23 ✅ closed 2026-05-04 (IMPL-018 + 21 slots + IMPL-013 input rolling-close)
- Cross-slot IMPL-053..058 ✅ all closed 2026-05-04

No dep override needed. Phase Gate Override Path A 2026-05-03 (operator Kritsana) keeps P4 unblocked.

---

## §5 G1 Compile (PowerShell Start-Process MetaEditor64)

```
C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe /compile:Spike_Orchestrator.mq5 /log
```

**Result:**
```
Result: 0 errors, 0 warnings, 608 ms elapsed, cpu='X64 Regular'
```

✅ **G1 PASS** — 608 ms (cold-cache; full transitive include of all 19 service headers + 21 slot headers + 4 helper headers + 4 core peers + all 5 input headers).

### Sibling Regression Sweep (post ODR-fix)

| Spike | Result | Latency |
|-------|--------|---------|
| Spike_AtomicWrite | 0err/0warn | 414 ms |
| Spike_CSlotBase | 0err/0warn | 617 ms |
| Spike_CrossSlotCoordinator | 0err/0warn | 660 ms |
| Spike_PendingMachineRegistry | 0err/0warn | 1494 ms |
| Spike_EAState | 0err/0warn | 1045 ms |
| Spike_Slot_C..BI (21 slots) | 0err/0warn each | 472..584 ms |

**Total: 26/26 spike harnesses 0err/0warn after IMPL-059 ODR fix in IndicatorService + CircuitBreaker.** No regression introduced.

---

## §6 SelfTest Result

`Spike_Orchestrator.mq5 OnInit` runs:
1. Heap-news a fresh `COrchestrator*` + immediately `delete` → exercises dtor fallback path through `CleanupPartialInit("dtor_fallback")` against never-wired class. All 19 NULL-safety branches in CleanupPartialInit exercise without segfault.
2. Print `g_orch` state probes — confirms class shape callable: `state=EA_STATE_RUNNING reason='' logger_live=0 registry_live=0` (pre-OnInit; pointers all NULL by ctor invariant).

**Verdict:** Phase A heap construction + dtor fallback path verified. Full OnInit Phase B/C verification deferred to IMPL-060 (live attach) per §7 below.

---

## §7 G2/G3/G4 — Deferred to IMPL-060+ Runnable Surface

Per IMPL-018+ header-only precedent: `core/Orchestrator.mqh` is consumed by `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` (IMPL-060, does not yet exist). G2 attach + G3 headless backtest + G4 log review activate at IMPL-060 surface.

The 3 IMPL-059 E-ACs all require live attach + chart + broker session:
- E-AC #1 (`Phase C deliberate fail smoke`) — needs MT5 chart attach with `_Symbol="GBPUSD"` to trigger ValidateSymbol fail; verifies `[ev=init_failed_cleanup][reason=validate_symbol]` Logger emit + 0 leaked heap (re-attach success on EURUSD post-fail).
- E-AC #2 (`Full attach OnInit Phase B step ordering`) — needs Tester run with LOG_DEBUG so each Logger.Debug step1..step17 is visible; verifies dependency-order step sequence matches §7.3 DI table.
- E-AC #3 (`OnTick step 5b SetHalted(true) BEFORE RunExitPass`) — needs CircuitBreaker trip during Tester run; verifies journal halt event timestamp ordering vs RunExitPass invocation.

All 3 E-ACs registered to `deferred-ac-registry.md § Active` row IMPL-059 expiry 2026-05-18 (combined; activation = IMPL-060 entry `.mq5` + Tester run with intentional symbol mismatch + LOG_DEBUG fixture + CB trip simulation).

---

## §8 Sibling Regression Side-Effect: ODR Fix in 2 Service Files

`services/IndicatorService.mqh` + `services/CircuitBreaker.mqh` had latent ODR violations: 24 + 2 in-class `static const int X = N;` declarations that MQL5 emits error 370 "unresolved static variable" when referenced from method bodies of a translation unit that compiles the full header. The pattern `(static const int X = N;` only) had been working in ALL prior sibling spikes because IndicatorService.mqh and CircuitBreaker.mqh were never transitively included until Orchestrator.mqh.

**Fix:** in-class decl only (no `= N`); out-of-class definition with the value at file tail. Pattern:
```mql5
class CIndicatorService {
   static const int IDX_X;   // declaration only
};
const int CIndicatorService::IDX_X = 0;   // out-of-class def
```

26 sibling spike regression check post-fix → **0 regressions** (all 26 still 0err/0warn).

This is a structural improvement that benefits all future translation units that include these headers — not a deviation; it brings the headers into MQL5 ODR compliance.

---

## §9 Self-Review Checklist (Phase 2C Final Step)

- ✅ **Security** — No secrets, no injection paths; `_Symbol` whitelist enforced via `ValidateSymbol` Phase C guard; no network listener / DLL / WebRequest; all heap allocations balanced by `CleanupPartialInit` reverse-order release per ADR-002 + Claim 02.10
- ✅ **Business Logic** — Matches TD-02 §7.1-7.4.1 verbatim; 5 spec deviations (D-1..D-5) all justified by service-actual signature divergence + documented in header banner
- ✅ **Error Handling** — Every Init() returning `false` has matching `CleanupPartialInit(reason)` + `return INIT_FAILED` (8 sites enumerated per TD-02 §7.4.1); state.json corrupt = degrade-but-continue (Logger.Warn + RUNNING fallback); journal sustained fail in OnTick = `Halt("journal_write_fail_sustained")`; CleanupPartialInit NULL-safe at every branch
- ✅ **Performance** — OnTick housekeeping path always runs even when morning_block forces skip (state save + monitor update + halt-stable transition guarantee invariants); cached `m_state_enum` mirror eliminates pointer-deref through m_ea_state on every tick branch check (steps 5b, 11, 13)
- ✅ **Over-engineering** — No abstractions added beyond TD spec; followed verbatim transcription pattern; no "OrchestrationPhase" enum / no extracted "Wirer" helper class / no template magic. Workhorse imperative MQL5 matching the spec exactly
- ✅ **Tests** — Spike harness exercises Phase A construction + dtor fallback NULL-safety; remaining 3 E-ACs deferred to IMPL-060 runnable surface (proper Empirical Closure Discipline per ea.md `services/* MUST NOT #include slots/*`-style boundary; Orchestrator E-ACs need real chart attach to verify)
- ✅ **Naming** — `m_*` member fields; `WireServices`/`WireSlots`/`CleanupPartialInit`/`Halt`/`RunExitPass`/`RunEntryPass`/`ShouldSkipEntryPass` PascalCase methods matching TD-02 §7.1 skeleton names

---

## §10 State Reconciliation

| File | Update |
|------|--------|
| `docs/state/impl-plan.md` | IMPL-059 7 S-AC `[x]` + 3 E-AC `[ ]` (deferred to registry) + `Closed:` line + Phase Status row P4 6/11 → 7/11 + TL;DR (last action) + Mid-Phase Audit Log new row |
| `docs/state/overview.md` | Impl Tasks row prefix updated — "CrossSlotCoordinator service surface complete pending IMPL-059 Orchestrator wiring" → "Orchestrator composition root complete pending IMPL-060 entry .mq5"; deferred-AC unblock vista noted |
| `docs/state/deferred-ac-registry.md` | 1 new IMPL-059 Active P4 row expiry 2026-05-18 (combined Phase C deliberate-fail + step-ordering + step-5b-precedence smoke; 3 E-ACs bundled per IMPL-053+ precedent) |
| `docs/state/current_handoff.md` | Last completed action = IMPL-059 + prior IMPL-057 demoted to "Previous action" |
| `docs/state/_session-handoff/IMPL-059-evidence-20260504.md` | This file (NEW) |

---

## §11 Mid-Phase Audit Counter & Code Review Trigger

P4 closure counter: 1 (post IMPL-057 reset) → 2 by IMPL-059 closure. **Threshold 5 not crossed** (3 closures away).

**Code Review trigger R09 condition** (cross-slot surface complete + Orchestrator complete = 7 P4 tasks closed since R06): **strongly recommend `/impl-review all`** before IMPL-060 to cover the entire integration surface (Orchestrator + 6 cross-slot bodies + ODR-fix touch on 2 service files). Plan Staleness Sentinel = 9 closures since R06; below 10-closure threshold but very close — review will reset.

---

## §12 Recommended Next

1. **`/impl-review all`** — adversarial sweep on Orchestrator + ODR fix + entire cross-slot surface (R09 condition met).
2. After review Green: **`/impl-task IMPL-060`** (S entry `.mq5` thin wrapper — 4 events delegate to Orchestrator). After IMPL-060 → empirical surface unblocks: P1/P2 Phase Gate retroactive close + 36+ deferred-AC rows expiring 2026-05-17/18 (P1 6 rows + P2 5 rows + P3 24 rows + P4 IMPL-053..059 rows = 36+).
3. **Mid-Phase Audit P4 counter** = 2 post this closure; threshold 5 not crossed.

---

## §13 References

- `docs/technical-design/02-backend-design.md § 7.1-7.4.1` — full Orchestrator skeleton + OnInit + OnTick + CleanupPartialInit pseudo-code (verbatim source)
- `docs/adr/002-composition-root-and-injection.md` — Composition Root + Constructor Injection pattern enforcement
- `docs/adr/010-halted-state-exit-only.md` — RUNNING/HALTED enable matrix + Reset trigger (idle reset on EA reattach + portfolio empty)
- `docs/adr/012-folder-structure-and-include-discipline.md` — 5-layer dependency direction (`core/` → `services/` → `domain/` → `helpers/`)
- `docs/state/_session-handoff/IMPL-057-evidence-20260504.md` — last cross-slot business-logic method closure (predecessor to this file)
- `docs/state/_session-handoff/IMPL-058-evidence-20260504.md` — HALTED enable matrix audit confirming step 5b OnTick wiring requirement
- `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh § static-member out-of-class definitions` — IMPL-059 ODR fix doc block
- `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh § static-member out-of-class definitions` — same
