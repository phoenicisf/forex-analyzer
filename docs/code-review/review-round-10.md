# Code Review Round 10

| Field | Value |
|-------|-------|
| **Round** | 10 |
| **Target** | IMPL-059 — `core/Orchestrator.mqh` (NEW 595 LOC) + `core/SlotRegistry.mqh::RegisterAll` (~96 LOC delta) + `services/IndicatorService.mqh` ODR fix (~89 LOC delta) + `services/CircuitBreaker.mqh` ODR fix (~10 LOC delta) + `_session-handoff/IMPL-059-evidence-20260504.md` |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~790 LOC composition root + topo-order slot heap-news + 26 static-member out-of-class definitions. Cross-references read: `core/BootstrapValidator.mqh::ValidateInputs/Symbol/DetectDigit/SlotRegistry`, `core/EAState.mqh::Init/Halt/RestoreFromState/TryTransitionToStable`, `services/PortfolioState.mqh::RegisterAll/MagicCount/TotalActivePositions`, `services/StatePersistence.mqh::Init/Load/Save/StatePath/GetLoggerThrottledCount`, `services/TradeJournal.mqh::Open/SetHaltSink/ShouldHaltSustained`, `services/Logger.mqh::Init/SetStatePersistence/ErrorBypassThrottle/OnTickBoundary`, `services/TimeGate.mqh::IsMorningWakeup/IsMondaySpreadHigh/HolidayBlock`, `services/CrossSlotCoordinator.mqh::SetHalted` (post fix-round-09) |
| **Plan Staleness Sentinel** | 10 closures since R06 (IMPL-053..058 + IMPL-059 ODR-touch on 2 services + IMPL-013 rolling-close). **Threshold reached** — recommend `/impl-plan-review all` after this review to re-validate plan hygiene |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 3 |
| MEDIUM   | 4 |
| LOW      | 3 |
| **Total**| **11** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | EURUSD whitelist routed via `m_validator.ValidateSymbol()` Phase C guard (line 245). No `WebRequest`/external `#import`/DLL/hardcoded creds. State write goes through `CAtomicFile::CleanupOrphanTmp` + atomic save per ADR-007. |
| 2 | Business Logic Correctness | ⚠️ Finding | (a) `WireServices()` returns void — partial-alloc failures in Phase A are **not detected** before Phase B dereferences pointers (Finding 10.1 CRITICAL); (b) `OnTick` skips entire exit pass when `morning_block=true` (line 466-495) — violates ADR-010 enable matrix "exit pass always runs" + CodeWiki §3.1 morning-window contract (Finding 10.2 HIGH); (c) CircuitBreaker is constructed + `Init`'d + `CheckPingPong`'d every tick but **no caller invokes `m_breaker.RecordOpen/RecordClose`** anywhere in Orchestrator → ping-pong detector receives zero input → BR-3.6 trigger can never fire (Finding 10.3 HIGH). |
| 3 | Error Handling | ⚠️ Finding | `CleanupPartialInit` is NULL-safe per branch ✅; reverse order matches TD-02 §7.4.1 ✅; logger emit BEFORE teardown ✅. But (a) when `dtor_fallback` runs on a never-Init'd logger, `m_logger.ErrorBypassThrottle` is called against a CLogger that never had `Init(min_level, alert_on_error, escalation_n)` called — relies on ctor zero-init being adequate (Finding 10.4 MEDIUM); (b) Phase A heap-alloc failure isn't a recoverable error path (no `return INIT_FAILED` from Phase A — see 10.1). |
| 4 | Performance | ⚠️ Finding | OnTick housekeeping (`m_state.Save` ~800 µs every tick per `services/StatePersistence.mqh` budget) saves with **stale** portfolio counts when `morning_block=true` because `m_portfolio.Refresh()` is gated inside `if(!morning_block)` (Finding 10.5 MEDIUM). Otherwise per-tick budget path matches TD-02 §7.2 (~1100 µs total). No N+1, no unbounded loops, no allocations in OnTick hot path beyond `MarketContext ctx = m_ctx_builder.Build()` (by-value per ADR-004). |
| 5 | Over-Engineering | ⚠️ Finding | `WireSlots()` is a misleading name — it does **no** slot wiring (just returns `m_registry != NULL`); actual heap-news of 21 slots happens inside `m_registry.RegisterAll` invoked from Phase C (line 278). Either rename or remove (Finding 10.6 LOW). `m_state_enum` + `m_halt_reason` cached mirrors are reasonable per-tick optimizations + already justified in header banner. |
| 6 | Cross-Service Consistency | ⚠️ Finding | 5 spec deviations (D-1..D-5) all documented in header banner ✅. But `ValidateSlotRegistry(m_portfolio.MagicCount(), 17)` hardcodes `17` magic — should reference a named constant from `domain/EnumTypes.mqh` or `services/PortfolioState.mqh § BR-1.1` to avoid drift if ADR-005 ever extends magics (Finding 10.7 LOW). |
| 7 | Test Coverage Gaps | ⚠️ Finding | Spike harness exercises only **Phase A construction + dtor fallback NULL-safety**; ALL Phase B init ordering + Phase C 8-guard chain + OnTick F1 14-step pipeline + step 5b precedence are deferred to IMPL-060 entry .mq5 — empirically untested (Finding 10.8 MEDIUM). Acceptable per IMPL-018+ header-only precedent + 3 E-ACs registered to deferred-AC-registry row IMPL-059 expiry 2026-05-18 ✅; but worth flagging that **9 closures** have stacked behind this single live-attach gate. |
| 8 | Architecture Compliance | ✅ Pass | 5-layer dependency direction OK (`core/Orchestrator` → `services/*` + `domain/*` + `helpers/*` + `inputs/*`); ADR-002 Composition Root + Constructor Injection respected; ADR-007 atomic write + orphan tmp recovery wired (line 251); ADR-010 step 5b SetHalted BEFORE RunExitPass ✅ (line 460 PRECEDES line 479); 2-phase init Cycle 1 + Cycle 2 setters at correct offsets (steps 4a/5a per TD-02 §7.4); CleanupPartialInit at all 8 INIT_FAILED sites ✅. |
| 9 | TD Compliance | ⚠️ Finding | TD-02 §7.4 + §7.4.1 verbatim transcription claim mostly holds ✅. Deviations D-1..D-5 honest ✅. But two skeleton-vs-actual divergences are present without header-banner deviation entry: (a) `RunExitPass(const MarketContext&)` accepts `ctx` but iterates calling `s.ManageExits(*m_portfolio)` only — `ctx` is unused at the call site though declared. TD-02 §7.2 line 1545 sketches "ctx-aware exit policies" as future work; for now the parameter is dead-input. The header note acknowledges this but it warrants a deviation row D-6 (Finding 10.9 LOW); (b) OnTick step 14 alert format `"PhoenicisNex halted_stable + %d throttled alerts cumulative"` uses `m_state.GetLoggerThrottledCount()` — TD-02 §7.2 line 1571 doesn't specify message format but ADR-011 + NFR-5.1 require Alert text include the halt reason (currently absent — only count is shown). (Finding 10.10 MEDIUM). |
| 10 | Test Code Quality | ✅ Pass | No regex; spike harness loops bounded; no shared mutable state; per-test runtime O(1). |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `impl-plan.md` for IMPL-059 closure block returns 0 hits for "deferred to operator-runtime" / "deferred to post-launch operator phase" / "structurally complete.*deferred". 3 IMPL-059 E-ACs (Phase C deliberate-fail / Phase B step ordering / OnTick step 5b precedence) all registered in `deferred-ac-registry.md § Active` row "P4 IMPL-059" with explicit Owner Kritsana / Opened 2026-05-04 / Expires 2026-05-18 / detailed Risk-if-missed paragraph — proper Empirical Closure Discipline. ODR fix in IndicatorService + CircuitBreaker is a structural improvement (no E-AC required). |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1; `simulation/headless-tests/orchestrator_smoke.ini` committed but `Visual=0` activation deferred until IMPL-060 entry .mq5 is the runnable surface. Correct disposition per IMPL-018+ precedent. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; Orchestrator consumes only `Inp*` symbols visible via composition-root include of 4 input files (line 82-85). No env var / secret / API key — `[config-audit]` E-AC not triggered. |

---

## Findings

### Finding 10.1: 🔴 CRITICAL — `WireServices()` returns void; Phase A heap-alloc failure in any of 19 services silently produces NULL pointer that Phase B dereferences without guard

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 162 (decl), 198 (call site), 207-235 (Phase B unguarded deref), 307-330 (WireServices body)
- Service: ea (Orchestrator)

**Code:**
```mql5
// Line 162 — declared void, no return value
void              WireServices();

// Line 198-205 — Phase A call site: NO failure check on WireServices, only on WireSlots
WireServices();
if(!WireSlots())
  {
   CleanupPartialInit("wire_slots_alloc_fail");
   return INIT_FAILED;
  }

// Line 208-212 — Phase B starts dereferencing immediately, no NULL guard
m_logger.Init((ESeverity)InpLogLevel, InpAlertOnError, InpErrorEscalationN);
m_pip.Init();
m_state.Init(m_atomic, m_logger);
m_logger.SetStatePersistence(m_state);
m_portfolio.Init(m_logger);

// Line 307-330 — body: every alloc is `if(m_*==NULL) m_* = new C*();`
// MQL5 `new T()` returns NULL on heap exhaustion (per MetaQuotes docs:
// "if memory cannot be allocated, NULL is returned"); body has no
// post-alloc NULL re-check, no rollback, no return.
if(m_logger          == NULL) m_logger          = new CLogger();
if(m_pip             == NULL) m_pip             = new CPipMath();
... // 17 more, all unchecked
```

**Problem:**
MQL5 `new T()` returns `NULL` on allocation failure (per MetaQuotes language reference; this is documented behavior, not undefined). `WireServices()` heap-allocates 19 objects (4 helpers + 12 services + 3 core peers) in unchecked sequence. If any allocation fails — for example MT5 process is near memory cap after 10 EA re-attaches in a long live session, or a large indicator buffer pushed allocator into fragmentation — the body returns void with one or more `m_*` still NULL. Phase B at line 208 then calls `m_logger.Init(...)` on a NULL pointer, which crashes the EA (segfault or "access violation reading address 0x00000000" depending on MT5 build) — no `CleanupPartialInit` runs, no `INIT_FAILED` returns, no `Alert()`, no journal entry. NFR-5.1 ("no silent halt / no silent failure") is violated.

`WireSlots()` does check `m_registry != NULL` (line 347), but that single sentinel is insufficient — a NULL `m_logger` or `m_pip` or `m_state` gets through because WireSlots doesn't enumerate them.

TD-02 §7.4.1 + Claim 02.10 ("CleanupPartialInit at 8 INIT_FAILED sites") were designed to cover Phase B/C failures; Phase A heap exhaustion was not explicitly enumerated as a 9th site, but the contract intent (no silent INIT failure) clearly extends here.

**Why This Matters:**
This is the only failure mode in the entire OnInit pipeline that escapes the CleanupPartialInit + INIT_FAILED contract. Production scenario: operator restarts MT5 after a 12-hour live session, several other EAs already attached chewed memory, PhoenicisNex re-attaches → `new CIndicatorService()` returns NULL → `m_indicators.Init(m_logger)` segfaults on the 6th line of Phase B. Operator sees MT5 unhandled exception dialog, NOT the engineered `[ev=init_failed_cleanup][reason=alloc_phase_a]` Logger emit they were trained to grep for. Worse: `CleanupPartialInit` never runs, so the 18 successful `new` allocations leak and re-attach now starts even more memory-pressured.

ADR-002 Composition Root pattern explicitly cites "fail-fast on construction failure" as a design goal; this finding is a direct violation.

**Suggested Fix:**
Convert `WireServices` to bool + add NULL re-check + make the OnInit caller route through `CleanupPartialInit`:
```mql5
// Header decl
bool              WireServices();

// Body
bool COrchestrator::WireServices()
  {
   if(m_logger == NULL)         m_logger          = new CLogger();
   if(m_logger == NULL)         return false;          // first because we need it for emit
   if(m_pip == NULL)            m_pip             = new CPipMath();
   if(m_pip == NULL)            return false;
   // ... continue for all 19, each followed by NULL re-check + return false
   if(m_ea_state == NULL)       m_ea_state        = new CEAState();
   if(m_ea_state == NULL)       return false;
   return true;
  }

// OnInit call site
if(!WireServices())
  {
   CleanupPartialInit("wire_services_alloc_fail");
   return INIT_FAILED;
  }
if(!WireSlots())
  { CleanupPartialInit("wire_slots_alloc_fail"); return INIT_FAILED; }
```
The first failure attempt to allocate `m_logger` itself can't emit (logger doesn't exist yet) — `CleanupPartialInit` already handles that gracefully (the body checks `m_logger != NULL` before emit). Add a 9th INIT_FAILED site to TD-02 §7.4.1 + a deviation banner row. LoE: Low (~25 line changes).

**Level of Effort:** Low (Orchestrator.mqh body + header banner D-6 row + TD-02 §7.4.1 amend)

---

### Finding 10.2: 🟠 HIGH — `OnTick` skips RunExitPass + 5 cross-slot exit-side helpers when `morning_block=true` — violates ADR-010 "exit pass always runs" + CodeWiki §3.1 morning-window contract

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 462-495 (OnTick steps 6-11), 477-484 (RunExitPass + 5 xslot exit helpers all gated inside `if(!morning_block)`)
- Service: ea (Orchestrator)

**Code:**
```mql5
// 6. Time gates (cheap)
bool morning_block = m_time.IsMorningWakeup(ctx.tick_time);
bool monday_block  = false;
bool holiday_block = false;
if(!morning_block)
  {
   monday_block = m_time.IsMondaySpreadHigh(ctx.tick_time, ...);

   // 7. PortfolioState refresh
   m_portfolio.Refresh();

   // 8. PendingMachineRegistry tick
   m_pending.TickAll(ctx);

   // 9. EXIT PASS (always runs — even in HALTED per ADR-010; m_xslot.m_halted
   //    already correct from step 5b).
   RunExitPass(ctx);
   m_xslot.RunForceCutloss(ctx);
   m_xslot.ExtraCheckFunction2();
   m_xslot.RunSafePort(ctx);
   m_xslot.RunOrderGroup2(ctx);
   m_xslot.RunCOverload(ctx);

   // 10. Holiday block (after exit pass; before entry pass)
   holiday_block = m_time.HolidayBlock(ctx.tick_time, *m_portfolio);

   // 11. ENTRY PASS (skip in HALTED or any time-block)
   if(!ShouldSkipEntryPass(ctx, monday_block, holiday_block))
     {
      RunEntryPass(ctx);
      m_xslot.RunEOverload(ctx);
     }
  }
```

**Problem:**
The block guarded by `if(!morning_block)` (line 466) gates **both** the entry pass AND the exit pass + all 5 cross-slot exit-side helpers (RunForceCutloss / ExtraCheckFunction2 / RunSafePort / RunOrderGroup2 / RunCOverload). The intent of `IsMorningWakeup` (per BR-3.1 + CodeWiki §3.1) is to suppress NEW entries during the broker's morning rollover window — exits / take-profit / safe-port / force-cutloss must continue to run because (a) open positions still need TP/SL management during morning window; (b) ADR-010 enable matrix explicitly requires exit pass to run even in HALTED state — and HALTED is a stricter constraint than morning_block, so morning_block must not be more restrictive than HALTED.

The comment at line 477-478 even acknowledges this: "EXIT PASS (always runs — even in HALTED per ADR-010; m_xslot.m_halted already correct from step 5b)." — but the surrounding `if(!morning_block)` block contradicts the "always runs" promise.

`m_pending.TickAll(ctx)` (step 8) and `m_portfolio.Refresh()` (step 7) are also gated — both have legitimate reasons to run on every tick: TickAll force-clears legacy timeouts (per ADR-008) which must not silently freeze for morning-window minutes; Refresh updates SlotState aggregates that downstream `m_state.Save` (step 13) writes to disk — gating Refresh leaves stale data in state.json (cross-couples with Finding 10.5).

CodeWiki §3.1 (referenced by Inputs_TimeGates.mqh:`InpMorningWindowMinutes`) describes morning window as "no new entry attempts" — silent on exits. Since the EA-original was monolithic OnTick, exits naturally continued; the rewrite introduces a regression.

**Why This Matters:**
Bucket A drift NFR-1.1 risk: under realistic backtest, morning-window minutes (e.g., InpMorningWindowMinutes=30 default) account for ~2% of H4 ticks. If 20+ open positions are held across morning window, every TP target is missed for that window → cumulative net-profit loss + behavioral parity drift. Worse: BR-8.3 ForceCutloss + BR-8.1 SafePort emergency exits cannot fire during morning window → if a flash-DD event coincides with morning rollover (a real scenario per FBS server log), the EA cannot defend. ADR-010 enable matrix makes this contract explicit; `OnTick` violates it.

**Suggested Fix:**
Hoist exit pass + portfolio refresh + pending tick OUT of the `if(!morning_block)` block. Only entry-side calls should be gated:
```mql5
// 6. Time gates
bool morning_block = m_time.IsMorningWakeup(ctx.tick_time);
int  spread_pts    = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
bool monday_block  = m_time.IsMondaySpreadHigh(ctx.tick_time, spread_pts);

// 7. PortfolioState refresh — MUST run every tick (step 13 Save reads it)
m_portfolio.Refresh();

// 8. PendingMachineRegistry tick — MUST run (force-clear legacy timeouts)
m_pending.TickAll(ctx);

// 9. EXIT PASS — always runs (ADR-010 + Finding 10.2)
RunExitPass(ctx);
m_xslot.RunForceCutloss(ctx);
m_xslot.ExtraCheckFunction2();
m_xslot.RunSafePort(ctx);
m_xslot.RunOrderGroup2(ctx);
m_xslot.RunCOverload(ctx);

// 10. Holiday block (cheap; needed for entry-pass gate)
bool holiday_block = m_time.HolidayBlock(ctx.tick_time, *m_portfolio);

// 11. ENTRY PASS — gated on morning AND HALTED AND time-blocks
if(!morning_block && !ShouldSkipEntryPass(ctx, monday_block, holiday_block))
  {
   RunEntryPass(ctx);
   m_xslot.RunEOverload(ctx);
  }
```
This restores ADR-010 contract + protects exit semantics during morning + Monday-spread windows. Add SelfTest (or deferred E-AC) verifying `RunExitPass` Print emit fires during simulated morning-window tick.

**Level of Effort:** Low (~10 line restructure)

---

### Finding 10.3: 🟠 HIGH — `m_breaker.RecordOpen/RecordClose` never wired — CircuitBreaker receives zero events → BR-3.6 ping-pong detector can never fire

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 220 (`m_breaker.Init(m_logger)` only call), 449 (`m_breaker.CheckPingPong()` consumer)
- Cross-reference: `services/CircuitBreaker.mqh` lines 65-130 (RecordOpen / RecordClose / _WriteEvent never invoked from Orchestrator); also no MT5 `OnTradeTransaction` handler in Orchestrator
- Service: ea (Orchestrator + CircuitBreaker)

**Code:**
```mql5
// Line 220 — Init only; no producer-side wiring
m_breaker.Init(m_logger);

// Line 449 — consumer-side check every tick, on an empty ring buffer
if(m_breaker.CheckPingPong())
   Halt("circuit_breaker_pingpong");

// CircuitBreaker.mqh exposes RecordOpen + RecordClose + _WriteEvent
// (line 60-130) — but `grep -n "m_breaker\.Record" core/Orchestrator.mqh`
// returns 0 hits. No OnTradeTransaction handler defined either.
```

**Problem:**
`CCircuitBreaker` is a stateful detector — it accumulates OrderClose events into its 16-slot ring buffer via `RecordClose(magic, direction, time)` and looks for two events on the same `(magic, direction)` pair within 3 seconds. The class header (CircuitBreaker.mqh line 14-15) explicitly says "Orchestrator (IMPL-053) wires the actual EAState::SetHalted(reason) call" — implying Orchestrator is also responsible for calling `RecordClose` from a trade-transaction hook.

In the current Orchestrator there is **no** call to `RecordOpen` or `RecordClose`, and **no** `OnTradeTransaction` MT5 lifecycle handler that would route close events to the breaker. So `CheckPingPong()` runs every tick against an empty ring → always returns `false` → `Halt("circuit_breaker_pingpong")` is unreachable code → BR-3.6 ("close-then-immediate-reopen guard") is non-functional.

This is the second instance of "trigger logic exists but production path is dead" we have seen this round (cross-reference fix-round-09 09.2 — RunSafePort emitted `_triggered` log on 0 closes; that was fixed but the surrounding architecture has the same disease here). Empirically the bug is invisible in spike harness because Spike_Orchestrator only exercises Phase A construction.

**Why This Matters:**
BR-3.6 ping-pong is a primary safety mechanism: if a slot opens + immediately closes + immediately re-opens (e.g., logic-error infinite loop, broker-side requote rejection storm), CircuitBreaker is supposed to trip and HALT the EA. Without producer-side wiring, this defense is silently absent. Operator runs live, a ping-pong defect lands in P3 slot logic during P5 hardening, EA churns 100 trades/minute, account drains, no Halt fires → catastrophic. NFR-5.1 + ADR-010 + BR-3.6 all assume CircuitBreaker is wired end-to-end.

**Suggested Fix:**
Add `OnTradeTransaction` MT5 lifecycle method to `COrchestrator` + route every DEAL_ENTRY_OUT event to `m_breaker.RecordClose`:
```mql5
// Header
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result);

// Body
void COrchestrator::OnTradeTransaction(const MqlTradeTransaction &trans,
                                       const MqlTradeRequest &request,
                                       const MqlTradeResult &result)
  {
   if(m_breaker == NULL) return;
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong deal = trans.deal;
   if(!HistoryDealSelect(deal)) return;
   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT) return;     // only closes feed BR-3.6

   int magic = (int)HistoryDealGetInteger(deal, DEAL_MAGIC);
   ENUM_DEAL_TYPE dt = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
   int direction = (dt == DEAL_TYPE_SELL) ? 0 : 1;   // closing SELL = was BUY etc.
   datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);

   m_breaker.RecordClose(magic, direction, t);
   // (Optional: also forward to PortfolioState for SlotState mutation
   //  — IMPL-007 OnTradeTransaction populator is a separate row in
   //  deferred-ac-registry; landing here is natural pairing.)
  }
```
Then expose `OnTradeTransaction` from entry .mq5 (IMPL-060) → forward to `g_orch.OnTradeTransaction(...)`. Also add a deferred E-AC: "smoke fixture: simulate 2 close events on same (magic,direction) within 2 seconds → CheckPingPong returns true + Halt fires" — if not feasible inline, register in `deferred-ac-registry.md` paired with IMPL-060. LoE: Medium (handler + entry .mq5 plumbing + 1 SelfTest case).

**Level of Effort:** Medium (~30 LOC handler + entry .mq5 wiring + deferred-AC row)

---

### Finding 10.4: 🟡 MEDIUM — `dtor_fallback` path calls `m_logger.ErrorBypassThrottle` on a never-`Init`'d CLogger — relies on undocumented zero-init being adequate

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 139-145 (dtor → CleanupPartialInit), 360-364 (CleanupPartialInit emit on m_logger that may not have been Init'd)
- Cross-reference: `services/Logger.mqh::ErrorBypassThrottle` (touches m_min_level, m_alert_on_error, m_state, m_throttle_window — all set by `Init`, NOT by ctor)
- Service: ea

**Code:**
```mql5
// Line 139-145 — dtor unconditionally calls CleanupPartialInit
~COrchestrator()
  {
   CleanupPartialInit("dtor_fallback");
  }

// Line 360-364 — emit BEFORE teardown; no check for Init state
void COrchestrator::CleanupPartialInit(string failure_reason)
  {
   if(m_logger != NULL)
      m_logger.ErrorBypassThrottle("system", "init_failed_cleanup", 0, failure_reason);
   ...
  }
```

**Problem:**
The Spike_Orchestrator harness explicitly tests "heap-news a fresh COrchestrator + immediately delete" (per evidence §6) — this exercises the dtor fallback path against a class where `WireServices()` has never been called, which means `m_logger == NULL` and the emit is skipped. ✅ on that path.

But there is another path: `OnInit` enters Phase A successfully, `WireServices()` allocates `m_logger = new CLogger()` ✅, then Phase A's `WireSlots()` returns false → `CleanupPartialInit("wire_slots_alloc_fail")` runs at line 203. At this moment `m_logger` is **non-NULL but never Init'd** (line 208 `m_logger.Init(...)` runs in Phase B which never started). `ErrorBypassThrottle` is then called on a Logger whose internal state (`m_min_level`, `m_alert_on_error`, `m_escalation_n`, `m_state` pointer, throttle window arrays) is still at ctor zero-init. Behavior depends on whether CLogger ctor zero-initializes adequately — `services/Logger.mqh` does have a default ctor (line 95-ish per pattern) but `ErrorBypassThrottle` may dereference `m_state` (StatePersistence pointer) which is NULL pre-Init.

If `ErrorBypassThrottle` ever touches `m_state` (e.g., to call `m_state.IncrementLoggerThrottle` for accounting per ADR-011), this is a NULL deref.

**Why This Matters:**
The defect is silent under spike testing (which never exercises the partial-Phase-A path) but will surface the first time an operator hits a real Phase A failure between WireServices and WireSlots. NFR-5.1 ("no silent halt") is precisely the kind of defense this finding undermines — the cleanup emit is supposed to be the last-resort visibility mechanism for Phase A failures.

**Suggested Fix:**
Either (a) move the emit to after a probe of "Logger usable" state, or (b) use a fallback `Print` when Logger is non-NULL but un-Init'd:
```mql5
void COrchestrator::CleanupPartialInit(string failure_reason)
  {
   if(m_logger != NULL && m_logger.IsInitialized())   // new bool accessor
      m_logger.ErrorBypassThrottle("system", "init_failed_cleanup", 0, failure_reason);
   else
      Print("[Phoenicis][slot=system][ev=init_failed_cleanup] reason=", failure_reason,
            " (logger un-init — using Print fallback)");
   ...
  }
```
Add `bool CLogger::IsInitialized() const { return m_initialized; }` + set `m_initialized=true` at end of `CLogger::Init`. Alternative (b): make `ErrorBypassThrottle` itself NULL-safe on its internal `m_state` deref. Either fix prevents the partial-init NULL-deref. LoE: Low.

**Level of Effort:** Low (1 accessor + 1 ctor flag + 1 line in CleanupPartialInit)

---

### Finding 10.5: 🟡 MEDIUM — `m_state.Save` on morning_block ticks writes stale portfolio counts because `m_portfolio.Refresh()` is gated inside the morning_block conditional

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 472 (Refresh inside `if(!morning_block)`), 503 (Save outside; runs every tick)
- Service: ea

**Code:**
```mql5
if(!morning_block)
  {
   ...
   m_portfolio.Refresh();    // line 472 — only when not morning_block
   ...
  }

// === housekeeping (always runs) ===
m_monitor.Update(AccountInfoDouble(ACCOUNT_EQUITY), ctx.tick_time);   // line 500
m_state.Save(m_state_enum, m_halt_reason);                             // line 503 — always
```

**Problem:**
`m_state.Save` serializes the current `SlotState` snapshot per ADR-005 + ADR-007. During morning_block ticks, `m_portfolio.Refresh()` is skipped → SlotState aggregates (buy_count, sell_count, total_lots, total_profit, ticket_ids[]) are stale (from the last non-morning_block tick). The atomic write to `state.json` writes that stale snapshot. If MT5 then crashes mid-morning-window, the Load on next boot recovers a state.json that thinks portfolio composition is X positions with Y total_profit, but the broker actually has X' positions with Y' total_profit (due to closes/opens MT5 missed because Refresh was skipped — though ADR-001 single-tick invariant means closes can't happen during morning_block from EA-side; still, broker-side TP/SL hits can fire mid-window).

This couples to Finding 10.2 — both fixes are unified by hoisting `m_portfolio.Refresh()` out of the `if(!morning_block)` block.

**Why This Matters:**
state.json drift = boot-cold recovery drift = NFR-3.1 violation. Operator expects the journal + state.json snapshot to be authoritative; if morning-window writes corrupt the snapshot for ~30 minutes per day, every restart during/just-after morning window inherits stale data.

**Suggested Fix:**
Same as Finding 10.2 — hoist `m_portfolio.Refresh()` and `m_pending.TickAll(ctx)` out of the morning_block conditional. Refresh is ~100 µs per TD-02 §7.2 budget, well within tick budget even on morning ticks.

**Level of Effort:** Low (subsumed by Finding 10.2 fix)

---

### Finding 10.6: 🔵 LOW — `WireSlots()` is misnamed — body does no slot wiring; actual heap-news happens 70 lines later inside `m_registry.RegisterAll`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 165 (decl), 199 (call), 341-348 (body), 278-280 (actual wiring site)
- Service: ea

**Code:**
```mql5
// Line 341-348 — body does nothing slot-related
bool COrchestrator::WireSlots()
  {
   // SlotRegistry was constructed in WireServices. All other prep work
   // (slot heap-news + Init + SetPipMath) happens inside Phase C call to
   // m_registry.RegisterAll(...). This stub returns true so Phase A/B can
   // proceed; failure surface is in Phase C if RegisterAll returns false.
   return (m_registry != NULL);
  }

// Line 278-280 — the *actual* slot wiring lives in Phase C
if(!m_registry.RegisterAll(m_indicators, m_risk, m_journal, m_logger,
                           m_state, m_portfolio, m_pending, m_xslot))
  { CleanupPartialInit("slot_register_all"); return INIT_FAILED; }
```

**Problem:**
The class is at the start of its life — readers will repeatedly grep for "where do the 21 slots get heap-allocated?" and bounce off `WireSlots()` (which sounds like the answer) before tracing through to the Phase C `m_registry.RegisterAll` call site. The header banner line 332-339 explains why this stub exists, but the name lies. Either rename to `EnsureSlotRegistryConstructed()` or merge the check directly into `OnInit` Phase A as a one-line guard:
```mql5
// In OnInit Phase A:
WireServices();
if(m_registry == NULL) { CleanupPartialInit("registry_alloc_fail"); return INIT_FAILED; }
```

**Why This Matters:**
Code clarity / future-engineer onboarding cost. Not a defect today, but Composition Root readability matters because IMPL-060+ entry .mq5 + IMPL-061..068 QA Phase 3T all read this file as the canonical wiring map.

**Suggested Fix:**
Drop `WireSlots` entirely + inline its single check. Update header banner § Phase A to remove the WireSlots step. LoE: Low (~5 line deletion + 1 line inline + banner amend).

**Level of Effort:** Low

---

### Finding 10.7: 🔵 LOW — `ValidateSlotRegistry(m_portfolio.MagicCount(), 17)` hardcodes magic count 17 — should reference a named constant

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Line: 275
- Cross-reference: `services/PortfolioState.mqh:140` (`int magics[17]`) — same hardcoded literal already
- Service: ea

**Code:**
```mql5
if(!m_validator.ValidateSlotRegistry(m_portfolio.MagicCount(), 17))
  { CleanupPartialInit("slot_registry_invariant"); return INIT_FAILED; }
```

**Problem:**
`17` appears in 3 separate places (Orchestrator line 275, PortfolioState `int magics[17]` array literal, PortfolioState `for(int i = 0; i < 17; i++)` loop). If ADR-005 ever adds a new shared-magic pair (e.g., a future Phase 2 G3 sub-slot sharing MAGIC_G), all three sites must be hand-edited — drift risk.

**Why This Matters:**
Maintainability. Not a defect today (BR-1.1 17-magic invariant is locked) but small refactor cost prevents future drift.

**Suggested Fix:**
Add to `domain/EnumTypes.mqh`:
```mql5
#define PHOENICISNEX_MAGIC_COUNT 17     // BR-1.1 + ADR-005 — distinct magics across 21 slots
```
Then replace literal `17` at 3 sites. Same pattern as `PHOENICISNEX_SLOT_CAPACITY 21` in SlotRegistry.mqh (which is well-handled). LoE: Low.

**Level of Effort:** Low

---

### Finding 10.8: 🟡 MEDIUM — Spike harness covers only Phase A + dtor; Phase B/C/OnTick coverage is 100% deferred to IMPL-060 — 9 closures stack behind a single live-attach gate

**Location:**
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5` (full file — per evidence §6 "heap-news + immediately delete")
- Cross-reference: `_session-handoff/IMPL-059-evidence-20260504.md § 7` (3 E-ACs deferred); `deferred-ac-registry.md § Active` row IMPL-059 expiring 2026-05-18
- Service: ea

**Problem:**
The spike harness exercises *only* Phase A heap construction + dtor fallback NULL-safety. Phase B 16-Init dependency-order chain, Phase C 8-guard cleanup chain, OnTick F1 14-step pipeline, step 5b SetHalted-precedence, ODR-fixed static const refs from method bodies — **none** of these are touched by the spike. They are all funneled into 3 deferred E-ACs that activate only when IMPL-060 entry .mq5 lands + Tester run executes.

This is acceptable per IMPL-018+ header-only precedent (already cited in evidence), but the **scale** is concerning: per the deferred-AC registry row, the IMPL-059 row "blocks 36+ other deferred-AC rows from P1/P2/P3/P4 that all wait on Orchestrator runnable surface". A single Tester run on IMPL-060 must validate ~36+ E-ACs simultaneously — this is a **single point of empirical failure** that, if it surfaces a regression, will trigger a cascade of fix-rounds across all four phases.

CLAUDE.md §1 Tier 1.5 Exploratory Walk requirement says "30-min non-scripted operator walk" — for this EA the equivalent is "headless Tester run + journal audit." The current plan posts that single walk against IMPL-060 closure. If the walk detects, e.g., "step 5b runs AFTER RunExitPass" (i.e., my Finding 10.2 + a related Claim 01.3 regression), every IMPL-053..058 + IMPL-059 task closure gets retroactively suspect because their structural verifications never proved the integration order.

**Why This Matters:**
Defect concentration. Mid-Phase Audit per CLAUDE.md threshold rules — single-task gate carrying 36+ E-ACs is a defect-cluster trap that Phase Gate Hallucination is supposed to prevent.

**Suggested Fix:**
Add at least *one* synthetic-mocking SelfTest case to Spike_Orchestrator that exercises at least a fragment of Phase B without live broker:
```mql5
// SelfTest C2 — Phase A + partial Phase B (no chart attach)
COrchestrator *o = new COrchestrator();
// Manual fill m_logger via friend hook so Phase B can start
o.WireServicesForTest();      // new method — exercises full WireServices()
// Verify all 19 pointers non-NULL
if(!o.IsLoggerLive() || !o.IsRegistryLive()) { /* fail */ }
// Cannot run Phase B m_state.Init etc. — file system permission needed
delete o;
```
And/or: introduce a "dry-run OnInit" path that skips MQL5 broker calls (`SymbolInfoInteger`, `iIchimoku`, etc.) under a compile-time `SPIKE_HARNESS` flag — exercises Phase B/C control flow without broker. Either approach catches step-ordering regressions at `services/CrossSlotCoordinator.mqh::SelfTest` level granularity rather than waiting for IMPL-060 attach. LoE: Medium.

Alternatively, register an explicit "IMPL-060 cascade-risk monitor" row at `deferred-ac-registry.md` that lists all 36+ rows waiting on this gate + makes drain plan explicit (which order they unblock when IMPL-060 lands).

**Level of Effort:** Medium (Spike_Orchestrator harness extension or compile-flag dry-run)

---

### Finding 10.9: 🔵 LOW — `RunExitPass` accepts `const MarketContext &ctx` but doesn't use it; should be deviation D-6 in header banner

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 537-548
- Service: ea

**Code:**
```mql5
void COrchestrator::RunExitPass(const MarketContext &ctx)
  {
   // Note: ManageExits(CPortfolioState&) per CSlotBase contract (no ctx arg).
   //   ctx is plumbed into RunExitPass for symmetry with RunEntryPass +
   //   future use (e.g. context-dependent exit policies). MQL5 does not
   //   warn on unused const-ref parameters so no suppression idiom needed.
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.ManageExits(*m_portfolio);    // <-- ctx not forwarded
     }
  }
```

**Problem:**
TD-02 §7.2 line 1545 sketches RunExitPass as "iterate slots calling ManageExits with ctx" — actual `CSlotBase::ManageExits(CPortfolioState&)` signature has no ctx parameter (per IMPL-018 CSlotBase contract). So the deviation is real but undocumented in the D-1..D-5 deviation banner. The inline comment acknowledges it; promoting it to D-6 keeps the deviation log complete + grep-scannable.

**Why This Matters:**
Deviation log integrity. The 5 documented deviations form an audit trail that future readers (impl-plan-review, code-reviewer-future-rounds) compare against; an undeclared 6th deviation in the same file weakens the trail.

**Suggested Fix:**
Add to header banner:
```
//|  D-6 RunExitPass(const MarketContext&) accepts ctx but CSlotBase    |
//|      ManageExits signature is (CPortfolioState&) only (per IMPL-018|
//|      contract) — ctx is plumbed for symmetry with RunEntryPass +   |
//|      future ctx-aware exit policies; not forwarded to slots today. |
```
LoE: Low.

**Level of Effort:** Low (3 line banner addition)

---

### Finding 10.10: 🟡 MEDIUM — HALTED_STABLE Alert text omits halt reason — operator sees count but not why

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 514-520
- Service: ea

**Code:**
```mql5
// 14. HALTED → HALTED_STABLE transition (ADR-010 + AC-7.7.4)
if(m_ea_state.TryTransitionToStable(m_portfolio.TotalActivePositions()))
  {
   m_state_enum = m_ea_state.GetState();
   Alert(StringFormat("PhoenicisNex halted_stable + %d throttled alerts cumulative — check Experts log",
                      m_state.GetLoggerThrottledCount()));
  }
```

**Problem:**
The Alert message tells the operator the EA reached HALTED_STABLE + how many throttled alerts accumulated, but **omits the halt reason** (`m_halt_reason`). NFR-5.1 + ADR-010 require halt-state surfacing to be self-explanatory; an Alert that only says "halted_stable + 47 throttled alerts cumulative" forces the operator to hunt through Experts log to find the originating cause (which by definition was throttled or scrolled off).

ADR-011 ErrorBypassThrottle exists precisely so the originating halt cause is **always** emitted unthrottled — the Alert here should mirror that contract by including the reason verbatim.

**Why This Matters:**
Mean-time-to-diagnose. The halt → halted_stable transition fires once per halt cycle; this is the operator's primary debugging signal. Missing the reason field forces a log dive at exactly the worst time (live incident).

**Suggested Fix:**
```mql5
Alert(StringFormat("PhoenicisNex HALTED_STABLE reason=%s + %d throttled alerts cumulative — check Experts log",
                   m_halt_reason,
                   m_state.GetLoggerThrottledCount()));
```
LoE: Low (1 line).

**Level of Effort:** Low

---

### Finding 10.11: 🔵 LOW — `OnDeinit` reuses CleanupPartialInit which emits `init_failed_cleanup` event tag — wrong semantic for normal shutdown

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 568-580 (OnDeinit), 360-364 (CleanupPartialInit emit always tagged "init_failed_cleanup")
- Service: ea

**Code:**
```mql5
void COrchestrator::OnDeinit(const int reason)
  {
   if(m_logger != NULL)
      m_logger.Info("system", "deinit", 0,
                    StringFormat("reason=%d state=%s", reason, EnumToString(m_state_enum)));
   if(m_state != NULL)
      m_state.Save(m_state_enum, m_halt_reason);
   CleanupPartialInit(StringFormat("deinit_reason_%d", reason));
  }

// CleanupPartialInit always emits this tag, regardless of caller:
m_logger.ErrorBypassThrottle("system", "init_failed_cleanup", 0, failure_reason);
```

**Problem:**
The CleanupPartialInit emit hardcodes event-tag `init_failed_cleanup` and severity Error. When OnDeinit (normal shutdown — operator removed EA from chart, or MT5 closed cleanly) routes through CleanupPartialInit, the Tester log gets an Error-level `[ev=init_failed_cleanup][reason=deinit_reason_0]` entry — semantically wrong (deinit_reason_0 = REASON_PROGRAM is normal shutdown, not init failure).

QA Phase 3T (IMPL-061..068) `[log-assertion]` E-ACs that grep for `[ev=init_failed_cleanup]` will count every normal shutdown as a false-positive init failure → metric drift.

**Why This Matters:**
Log audit integrity. The pattern `service|event|severity` is the canonical audit triple per ADR-006 + journal-schema; conflating "init failed" with "normal deinit" pollutes downstream tooling.

**Suggested Fix:**
Either (a) split CleanupPartialInit into a private `_TeardownAll(reason, event_tag, is_error)` helper:
```mql5
private:
  void _TeardownAll(string reason, string event_tag, bool is_error);
public:
  void CleanupPartialInit(string reason)  // still public for external use
   { _TeardownAll(reason, "init_failed_cleanup", true); }
  void OnDeinit(const int reason)
   {
    ...
    _TeardownAll(StringFormat("deinit_reason_%d", reason), "deinit_cleanup", false);
   }
```
Or (b) pass an enum {INIT_FAIL, NORMAL_DEINIT, DTOR_FALLBACK} into CleanupPartialInit + branch the emit. LoE: Low.

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-10.1 — IMPL-007 deferred row + IMPL-053..056 close-path empirical row + IMPL-059 row form a multi-task gating block expiring 2026-05-17/18

The deferred-AC registry now has an interlocking set of rows where (a) IMPL-007 PortfolioState `OnTradeTransaction` populator unblocks `GetTicketsForSlot` empirical exercise, (b) close-path empirical row depends on IMPL-007 + Orchestrator runnable, (c) IMPL-059 row depends on IMPL-060 entry .mq5. This means a single live attach on IMPL-060 must validate the bulk of P1+P4 empirical surface. Recommend adding a meta-row in registry that maps the dependency graph + suggests parallel deferred-AC drain order. (Already mentioned in registry IMPL-059 row "Compound dependency: this row blocks 36+ other rows" — promote to a separate ordering / drain-plan paragraph.)

### XS-10.2 — D-2 deviation `CheckPingPong()` zero-arg + Finding 10.3 RecordOpen/Close unwired = compounded silent BR-3.6 failure

Independently each is recoverable; together they imply CircuitBreaker is wholly non-functional today (header banner D-2 says "service tracks state internally" — which is true syntactically, but with no events fed in the internal state is empty). The deviation banner should be amended: D-2 currently says "Use as-is; service tracks state internally" — should add "consumer-side wiring (RecordOpen/RecordClose from OnTradeTransaction) is a separate IMPL-060+ concern; until wired, CheckPingPong returns false on every tick".

### XS-10.3 — ODR fix in IndicatorService + CircuitBreaker is structurally correct but no test asserts the index values match prior `static const int X = N;` literals

After moving `IDX_ICHI_H4` etc. from inline `= 0` to out-of-class `const int CIndicatorService::IDX_ICHI_H4 = 0;`, the values must match the original assumed indices used in `iIchimoku/iForce/...` calls (CreateHandles body lines 185-258). A typo at any out-of-class definition (e.g., `IDX_FORCE_H4 = 3` instead of `2`) silently swaps two indicators forever. Recommend adding a SelfTest case to IndicatorService that asserts each `IDX_*` matches its expected ordinal (0..23 monotonically), runnable from spike harness. LoE: Low (~30 line static-assert-style SelfTest).

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 10.1 | 🔴 CRITICAL | Error Handling | `WireServices()` returns void; Phase A heap-alloc failure unguarded → Phase B NULL deref | Orchestrator.mqh:162,198,307-330 | Low |
| 10.2 | 🟠 HIGH | Business Logic | `OnTick` skips RunExitPass + 5 xslot exit helpers when `morning_block=true` — violates ADR-010 | Orchestrator.mqh:466-495 | Low |
| 10.3 | 🟠 HIGH | Business Logic | `m_breaker.RecordOpen/RecordClose` never wired — BR-3.6 ping-pong detector receives zero events | Orchestrator.mqh:220,449 | Medium |
| 10.4 | 🟡 MEDIUM | Error Handling | dtor_fallback emits via never-Init'd CLogger (between WireServices and Phase B) | Orchestrator.mqh:139-145, 360-364 | Low |
| 10.5 | 🟡 MEDIUM | Performance | `m_portfolio.Refresh()` gated inside morning_block → state.json saves stale aggregates | Orchestrator.mqh:472,503 | Low |
| 10.6 | 🔵 LOW | Over-Engineering | `WireSlots()` is misnamed — body does no slot wiring; actual heap-news in Phase C | Orchestrator.mqh:165,341-348 | Low |
| 10.7 | 🔵 LOW | TD Compliance | Magic count `17` hardcoded at 3 sites — should be `PHOENICISNEX_MAGIC_COUNT` | Orchestrator.mqh:275 + PortfolioState.mqh:140,163 | Low |
| 10.8 | 🟡 MEDIUM | Test Coverage | Spike covers only Phase A + dtor; 36+ deferred-ACs concentrated on IMPL-060 single live-attach gate | Spike_Orchestrator.mq5 + registry | Medium |
| 10.9 | 🔵 LOW | TD Compliance | `RunExitPass(ctx)` accepts ctx but doesn't forward — undocumented deviation D-6 | Orchestrator.mqh:537-548 | Low |
| 10.10 | 🟡 MEDIUM | Error Handling | HALTED_STABLE Alert text omits halt reason — operator sees count but not cause | Orchestrator.mqh:518-519 | Low |
| 10.11 | 🔵 LOW | Cross-Service Consistency | OnDeinit reuses CleanupPartialInit which emits `init_failed_cleanup` for normal shutdown | Orchestrator.mqh:568-580, 360-364 | Low |

---

## Recommendation

**Needs immediate attention** — 1 CRITICAL + 3 HIGH findings before fix-round-10.

**Fix priority order:**
1. **10.1 (CRITICAL)** — Phase A heap-alloc failure path; ~25 LOC fix; protects NFR-5.1 contract on the only escape route from CleanupPartialInit discipline
2. **10.2 (HIGH)** — morning_block exit-pass skip; ~10 LOC restructure; restores ADR-010 enable matrix; bundled fix also closes 10.5
3. **10.3 (HIGH)** — CircuitBreaker producer-side wiring; ~30 LOC OnTradeTransaction handler + entry .mq5 plumbing; restores BR-3.6 ping-pong defense (note: pairs with IMPL-060 because OnTradeTransaction must also be exposed from .mq5)
4. **10.5 (MEDIUM)** — bundled with 10.2 fix
5. **10.4 (MEDIUM)** — Logger un-init NULL-deref; ~5 LOC fix
6. **10.10 (MEDIUM)** — Alert reason — 1 LOC fix
7. **10.8 (MEDIUM)** — spike coverage / drain-plan; either Spike_Orchestrator extension OR registry meta-row paragraph
8. **10.6, 10.7, 10.9, 10.11 (LOW)** — cosmetic / maintainability; bundle into the same fix-round commit if convenient

**Plan Staleness Sentinel hit:** 10 closures since R06 — strongly recommend `/impl-plan-review all` after fix-round-10 closure to re-validate plan hygiene before IMPL-060 closes the empirical gate.

**On structural quality:** the verbatim-transcription discipline is excellent — TD-02 §7.4 maps almost line-for-line to OnInit body, deviations D-1..D-5 are honestly logged, ODR fix is the right tool for the right problem (and the side-fix in `services/IndicatorService.mqh:370` of the void-cast idiom shows attention to MQL5 quirks). The defects above are all *boundary* issues (Phase A, OnTick gating, producer-side wiring) — the verbatim core is solid.
