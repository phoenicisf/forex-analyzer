# Code Review Round 11

| Field | Value |
|-------|-------|
| **Round** | 11 |
| **Target** | `all` — focused on IMPL-060 entry point (`PhoenicisNex.mq5` 87 LOC NEW) + post-fix-round-10 deltas in `core/Orchestrator.mqh` (701 LOC) + `services/Logger.mqh` (`m_initialized` flag + `IsInitialized()` accessor) + `domain/EnumTypes.mqh` (`PHOENICISNEX_MAGIC_COUNT`) cascade across `services/PortfolioState.mqh` / `StatePersistence.mqh` / `TradeJournal.mqh` |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~88 LOC NEW (entry .mq5) + ~50 LOC delta (D-7/D-8 banner, _TeardownAll split, OnTradeTransaction handler, magic-count constant). Prior reviewed surface: ~8,950 LOC cumulative (R01..R10). |
| **Plan Staleness Sentinel** | 2 closures since R10 (IMPL-060 + IMPL-013-walk-batch). Plan approved 2026-05-02 (2 d ago). Below threshold; advisory `/impl-plan-review` already recommended in R10 § Recommendation. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **8** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Entry .mq5 contains no `WebRequest` / `#import` DLL / hardcoded creds. Symbol whitelist enforced via `m_validator.ValidateSymbol()` Phase C guard (Orchestrator.mqh:280). EURUSD-only (NFR-5.3 / FR-1.2). `OnTradeTransaction` filters by `TRADE_TRANSACTION_DEAL_ADD` + `DEAL_ENTRY_OUT` ✅ but does not filter by `_Symbol` (Finding 11.4 MEDIUM). |
| 2 | Business Logic Correctness | ⚠️ Finding | (a) Global `g_orchestrator` value-typed instance: `~COrchestrator()` invokes `CleanupPartialInit("dtor_fallback")` AFTER `OnDeinit` already ran `_TeardownAll` — re-emits Error-level `[ev=init_failed_cleanup]` for every normal EA unload, undoing fix-round-10 §10.11 (Finding 11.1 CRITICAL); (b) `OnTradeTransaction` consumes deals from ALL symbols on terminal — multi-symbol portfolio with another EA using magics in 200..219 range produces foreign `RecordClose` events polluting BR-3.6 ring buffer (Finding 11.2 HIGH). |
| 3 | Error Handling | ⚠️ Finding | Entry .mq5 delegates without NULL guard on `g_orchestrator` (which is value type so cannot be NULL ✅). OnInit composition-root failure surfaces are intact via D-7. But `OnTradeTransaction` body (`Orchestrator.mqh:664-686`) early-returns on `m_breaker == NULL` ✅ but **does not check** `m_state_enum` — feeds CB even after HALTED, which is harmless today but contradicts the ADR-010 enable matrix promise that "post-halt no new state evolution" — minor (Finding 11.5 MEDIUM). |
| 4 | Performance | ✅ Pass | Entry .mq5 is 5 thin delegates + 1 global object — no allocations, no hot-path overhead beyond MT5 native dispatch. OnTradeTransaction `HistoryDealSelect` + 4 `HistoryDealGetInteger` calls per close-deal = O(1) per event; volume bounded by MT5 dispatch cap. |
| 5 | Over-Engineering | ⚠️ Finding | Entry .mq5 is correctly thin (87 LOC vs ≤ 500 budget) ✅. But the TRIPLE teardown surface in Orchestrator (`~COrchestrator` → `CleanupPartialInit` → `_TeardownAll`) on the normal-shutdown path is a LIFO of the same list with conflicting semantic emits — should collapse to a single dispatch enum (Finding 11.1 fix proposal). |
| 6 | Cross-Service Consistency | ⚠️ Finding | `OnTester()` placeholder returns `AccountInfoDouble(ACCOUNT_EQUITY)` (Orchestrator.mqh:696-699) — flagged in code as Phase 1 placeholder, but `simulation/headless-tests/<task>.ini` will use this score for any G3 optimizer pass; risk of meaningless rankings if optimizer is enabled before IMPL-061..063 tuning lands (Finding 11.6 LOW). |
| 7 | Test Coverage Gaps | ⚠️ Finding | IMPL-060 closure adds zero spike harness coverage of the entry surface (.mq5 cannot be spike-compiled because it owns OnInit/OnTick/OnDeinit/OnTester/OnTradeTransaction signatures that conflict with spike harness MT5 binding). G2/G3/G4 attempt is the first verification — same concentration risk flagged in R10 § 10.8 still applies + has now compounded by 1 more closure (Finding 11.7 MEDIUM). |
| 8 | Architecture Compliance | ✅ Pass | Entry .mq5 follows ADR-012 ≤ 500 LOC thin-wrapper rule (87 LOC). 5-layer dependency direction unchanged (entry → core → services → domain → helpers). ADR-002 composition root respected. ADR-010 SetHalted-before-RunExitPass precedence preserved (Orchestrator.mqh:522 PRECEDES line 547). 2-phase init Cycles 1+2 intact. |
| 9 | TD Compliance | ⚠️ Finding | TD-02 §13.1 G1-G4 Definition of Done now actually achievable with IMPL-060 ✅. But D-7 + D-8 banner additions in Orchestrator are good audit traces (Finding 10.1/10.3 fix). One residual: `OnTester()` is documented as "FR-2.5 placeholder" — TD-02 does not specify the placeholder semantics + NFR-2.5 wants Sharpe-style score; cite the Phase 1 plan in code or register an E-AC (Finding 11.6 LOW). |
| 10 | Test Code Quality | ✅ Pass | No regex; no unbounded loops; no shared mutable state in spike harnesses; per-test runtime O(1). Spike harness compile evidence in fix-round-10 § Verification (5 spike compiles 0/0). |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `docs/state/impl-plan.md` for "deferred to operator-runtime" / "deferred per .* precedent" / "structurally complete.*deferred" / "live verification deferred" → **0 hits**. IMPL-060 evidence row in `deferred-ac-registry.md § Active` Tier-0 cascade plan with explicit owner + ≤ 14 d expiry (R10 fix-round § 10.8 sub-fix). E-AC kind = `[probe]` + `[log-assertion]` + `[boot-cold]` — properly scoped. |
| 12 | Functional CRUD Walk | ⏭ Skip — about to activate | EA project — Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1. With IMPL-060 entry .mq5 landing, the walk surface is now active for the first time. R10 § 10.8 cascade-drain plan governs. Walk has NOT yet been performed against IMPL-060 deliverable — Phase Gate must NOT be claimed until walk artifact exists (CLAUDE.md §1 gate). |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; entry .mq5 + Orchestrator consume only `Inp*` symbols visible via composition-root include. No env var / secret / API key — `[config-audit]` not triggered (per CLAUDE.md §6). |

---

## Findings

### Finding 11.1: 🔴 CRITICAL — `g_orchestrator` value-typed global ⇒ dtor on EA unload calls `CleanupPartialInit("dtor_fallback")` AFTER `OnDeinit`'s `_TeardownAll`, polluting log with `init_failed_cleanup` Error for every normal shutdown — undoes fix-round-10 §10.11

**Location:**
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5`, Line: 41 (global value-typed instance); File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 156-162 (dtor body), 395-415 (CleanupPartialInit emit), 641-653 (OnDeinit calls `_TeardownAll`)
- Service: ea (entry + Orchestrator)

**Code:**
```mql5
// PhoenicisNex.mq5:41 — global, value-typed (NOT a pointer)
COrchestrator g_orchestrator;

// Orchestrator.mqh:156-162 — unconditional CleanupPartialInit at dtor
~COrchestrator()
  {
   // Defensive: if OnDeinit was not called (rare — MT5 lifecycle
   // ensures OnDeinit on INIT_SUCCEEDED), CleanupPartialInit covers
   // the leak surface.
   CleanupPartialInit("dtor_fallback");
  }

// Orchestrator.mqh:395-415 — CleanupPartialInit ALWAYS emits Error tag
void COrchestrator::CleanupPartialInit(string failure_reason)
  {
   if(m_logger != NULL && m_logger.IsInitialized())
     {
      m_logger.ErrorBypassThrottle("system", "init_failed_cleanup", 0, failure_reason);
     }
   else
     {
      Print("[Phoenicis][slot=system][ev=init_failed_cleanup] reason=", failure_reason, ...);
     }
   _TeardownAll();
  }
```

**Problem:**
Because `g_orchestrator` is a **value-typed** global (not a pointer like `COrchestrator *g_orch = new ...`), the MQL5 runtime invokes `~COrchestrator()` automatically when the EA terminates / chart closes / terminal exits — **after** MT5 has already called `OnDeinit(reason)` which already invoked `_TeardownAll()` (which sets every member pointer to NULL). At dtor time:

1. `OnDeinit` ran first → emitted `[ev=deinit_cleanup]` Info → `_TeardownAll` set `m_logger = NULL` + every other pointer NULL.
2. Dtor then runs `CleanupPartialInit("dtor_fallback")` → branches into `else` (since `m_logger == NULL`) → emits `Print("[Phoenicis][slot=system][ev=init_failed_cleanup] reason=dtor_fallback ...")` to Experts log.

Every. Single. Normal. EA. Unload. Produces an `[ev=init_failed_cleanup]` Print as if Phase A failed. This **directly undoes** the entire fix-round-10 §10.11 fix whose stated goal was: *"QA Phase 3T `[log-assertion]` E-ACs that grep for `init_failed_cleanup` will now exclusively count true Phase A/C failures, not normal shutdowns."* The fix split CleanupPartialInit from `_TeardownAll` so OnDeinit could route around the Error tag — but the dtor still routes through CleanupPartialInit, defeating the split for the value-typed global case.

Worse: the second `_TeardownAll` invocation inside CleanupPartialInit is a no-op (every guard `if(m_X != NULL)` short-circuits) but the emit ALWAYS fires (no NULL guard around the Print branch). This means a dtor-after-OnDeinit always pollutes the log.

This pattern was implicitly acceptable in R10 because the spike harnesses use `COrchestrator *o = new COrchestrator(); ... delete o;` (heap pointers) — the dtor fallback was tested against the partial-Phase-A scenario where OnDeinit never ran. But the production entry path uses a value-typed global, where dtor *always* runs *after* OnDeinit on the happy path.

**Why This Matters:**
QA Phase 3T E-ACs (IMPL-061..068) that audit `[ev=init_failed_cleanup]` count will see a false-positive on every Tester run end + every G2 smoke EA detach + every G3 backtest finalize. The metric becomes useless as a Phase A/C fail signal. Worse: `simulation/headless-tests/bootstrap_smoke.ini` ends with `ShutdownTerminal=1` — every smoke run produces this spurious Error in Experts log, which an operator running G4 log-review will (correctly) flag as a defect.

This also defeats the safety net intent: if a real partial-OnInit failure occurs and dtor fires (e.g., MT5 crash mid-Phase-B), the operator cannot distinguish "real partial-init dtor fallback" from "normal shutdown dtor". NFR-5.1 ("no silent failure") inverts to "no signal failure" — every shutdown looks like a failure, so real failures are buried.

**Suggested Fix:**
Add a `m_teardown_done` flag (or check whether all members are already NULL) before the dtor's CleanupPartialInit invocation. Preferred: introduce a teardown-mode enum:

```mql5
// Orchestrator.mqh — add private state flag
private:
   bool m_teardown_done;       // true after _TeardownAll runs once

   COrchestrator() : ..., m_teardown_done(false) {}

   ~COrchestrator()
     {
      // Skip dtor-fallback emit when normal OnDeinit already tore down.
      // Only emit if we're entering dtor with services still live (true
      // partial-init crash where OnDeinit never ran — the original intent).
      if(m_teardown_done) return;
      CleanupPartialInit("dtor_fallback");
     }

   void _TeardownAll()
     {
      // ... existing body ...
      m_teardown_done = true;     // last line
     }
```

Add a SelfTest case in Spike_Orchestrator: heap-construct + call OnDeinit explicitly + then `delete o` → verify ZERO `init_failed_cleanup` emits in Experts log. LoE: Low (~5 line change + 1 SelfTest case).

**Level of Effort:** Low

---

### Finding 11.2: 🟠 HIGH — `OnTradeTransaction` ไม่ filter ตาม `_Symbol` — multi-symbol terminal feeds foreign deal events ของ EA อื่นเข้า CircuitBreaker BR-3.6 ring buffer

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 664-686 (OnTradeTransaction body)
- Service: ea (Orchestrator)

**Code:**
```mql5
void COrchestrator::OnTradeTransaction(const MqlTradeTransaction &trans, ...)
  {
   if(m_breaker == NULL) return;
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong deal = trans.deal;
   if(!HistoryDealSelect(deal)) return;

   ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT) return;

   int magic = (int)HistoryDealGetInteger(deal, DEAL_MAGIC);
   ENUM_DEAL_TYPE dt = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
   int direction = (dt == DEAL_TYPE_SELL) ? 1 : 0;
   datetime t = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);

   m_breaker.RecordClose(magic, direction, t);   // <-- no symbol guard, no magic-range guard
  }
```

**Problem:**
MT5's `OnTradeTransaction` is fired for **every** trade event on the account — across all symbols and all magic numbers, including manual closes by the operator and closes by other EAs running concurrently in different chart windows. The handler does not filter by:
1. `HistoryDealGetString(deal, DEAL_SYMBOL) == _Symbol` — foreign-symbol close on a multi-symbol account feeds CB.
2. `magic ∈ {200..219}` — manual close (magic=0) or another EA's magic feeds CB.

Consequence: CircuitBreaker's 16-slot ring buffer (per `services/CircuitBreaker.mqh § _WriteEvent`) collects (foreign_magic, direction, time) tuples. If the operator runs another EA on GBPUSD that uses magic 207 (which collides with PhoenicisNex's MAGIC_K=207), and that EA happens to close 2 sells within 3 s, `CheckPingPong()` returns true on the next PhoenicisNex tick → `Halt("circuit_breaker_pingpong")` fires → PhoenicisNex halts on a foreign-EA event that has nothing to do with it.

Less catastrophic but still bad: the ring buffer is a fixed 16 slots; foreign-magic events evict legitimate PhoenicisNex events, blunting the actual BR-3.6 detector against real PhoenicisNex ping-pong (the very defect BR-3.6 is supposed to catch).

This is the security/isolation analog of Finding 09.1 (`_AggregateWeakMetrics` no magic filter) which was fixed in fix-round-09. The same hygiene must apply here.

**Why This Matters:**
BR-3.6 is a primary safety mechanism per ADR-010 + NFR-5.1. False-positive halt = revenue loss (no entries during halt) + operator confusion ("EA halted but I see no Phoenicis errors"). False-negative dilution (foreign events evicting Phoenicis events from the ring) = silent BR-3.6 weakening — the worst-of-both: an operator believes BR-3.6 is armed but it can't see the actual ping-pong because foreign noise filled the buffer.

NFR-5.3 ("`_Symbol` whitelist 100%") is enforced at OnInit Phase C but lapses at the trade-transaction surface — same defect class, different boundary.

**Suggested Fix:**
Add two filters before `RecordClose`:

```mql5
   // Filter 1 — own-symbol only (NFR-5.3 boundary at trade-transaction surface).
   string deal_symbol = HistoryDealGetString(deal, DEAL_SYMBOL);
   if(deal_symbol != _Symbol) return;

   // Filter 2 — own-magic range (PhoenicisNex magics are 200..219 per ADR-005 + EnumTypes.mqh).
   int magic = (int)HistoryDealGetInteger(deal, DEAL_MAGIC);
   if(magic < 200 || magic > 219) return;

   ENUM_DEAL_TYPE dt = ...;
   ...
   m_breaker.RecordClose(magic, direction, t);
```

Better: expose `bool IsPhoenicisMagic(int)` from `domain/EnumTypes.mqh` so the magic range is canonical (mirror of `PHOENICISNEX_MAGIC_COUNT` introduced in fix-round-10 § 10.7). Add a SelfTest in Spike_CircuitBreaker that simulates 3 foreign-magic + 3 wrong-symbol events + 2 own-magic-own-symbol events → assert ring buffer holds only the 2 latter. LoE: Low.

**Level of Effort:** Low

---

### Finding 11.3: 🟠 HIGH — Entry .mq5 forwards `OnTradeTransaction` events that arrive **before** `OnInit` completes — D-8 producer-side wiring is active during a window where `m_breaker` may be NULL or un-Init'd

**Location:**
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5`, Lines: 80-85 (OnTradeTransaction global delegate); File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 664-668 (handler body)
- Service: ea (entry + Orchestrator)

**Code:**
```mql5
// PhoenicisNex.mq5:80-85 — unconditional delegation
void OnTradeTransaction(const MqlTradeTransaction &trans, ...)
  {
   g_orchestrator.OnTradeTransaction(trans, request, result);
  }

// Orchestrator.mqh:664-668 — only NULL-guards m_breaker
void COrchestrator::OnTradeTransaction(...)
  {
   if(m_breaker == NULL) return;
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ...
  }
```

**Problem:**
Per MT5 documentation (https://www.mql5.com/en/docs/event_handlers/ontradetransaction), `OnTradeTransaction` can fire **before** `OnInit` completes — specifically during EA recovery: when MT5 reconnects to the broker after a network drop, queued trade events fire as the EA is re-attaching. In this window:
- `m_breaker` may be NULL (if WireServices hasn't run) — guard ✅ handles this.
- `m_breaker` may be non-NULL but `m_breaker.Init(m_logger)` not yet called (if Phase A succeeded but Phase B step 10 hasn't run) — `RecordClose` then runs against an un-Init'd ring buffer where `m_logger` is also NULL. `RecordClose` body in `services/CircuitBreaker.mqh:149` calls `_WriteEvent` which may dereference `m_logger`.

The `m_breaker == NULL` guard alone is insufficient. The same issue applies if `OnTradeTransaction` fires AFTER `OnDeinit`'s `_TeardownAll` (e.g., a final close-event arrives while EA is being unloaded) — `m_breaker` was set NULL by `_TeardownAll` ✅ guard handles this. But a fire DURING `_TeardownAll` (in the brief window before `m_breaker` is freed) is technically possible since MT5 OnDeinit is called from the UI thread and trade events arrive on a different dispatch — though intra-process MT5 EA is single-threaded by ADR-001 so this is theoretical.

The Phase-A-incomplete window is the real issue; recovery-after-disconnect is a real production scenario per FBS server log notes.

**Why This Matters:**
A NULL deref in `RecordClose → _WriteEvent → m_logger.Debug(...)` during recovery causes MT5 unhandled exception → operator sees "access violation" dialog instead of the engineered fail-fast. Same NFR-5.1 silent-halt class as Finding 10.1 (which fixed Phase-B-from-Phase-A but not Phase-B-from-OnTradeTransaction).

**Suggested Fix:**
Add a more restrictive guard — require `m_breaker` AND something proving Phase B step 10 ran. Two options:

```mql5
// Option A — inspect EA state (cleanest)
void COrchestrator::OnTradeTransaction(...)
  {
   // EA must be past Phase B step 10 (Init complete) before CB consumes events.
   // m_ea_state.IsInitialized() (or similar) signals OnInit returned INIT_SUCCEEDED.
   if(m_breaker == NULL || m_ea_state == NULL) return;
   if(!m_ea_state.IsRunning() && !m_ea_state.IsHalted()) return;  // RUNNING or HALTED, not pre-Init
   ...
  }

// Option B — gate inside CCircuitBreaker::RecordClose
void CCircuitBreaker::RecordClose(int magic, int direction, datetime now_s)
  {
   if(m_logger == NULL) return;     // Init not run yet
   _WriteEvent(...);
  }
```

Option B is more robust (defends in depth, doesn't require the caller to know CB's init state). Add to CCircuitBreaker SelfTest: pre-Init RecordClose call → assert no crash + Print fallback used. LoE: Low.

**Level of Effort:** Low

---

### Finding 11.4: 🟡 MEDIUM — `OnTradeTransaction` direction encoding silently flips for closing-by-opposite (close-half / hedge close) — magic-direction tuple becomes ambiguous

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 678-682
- Service: ea (Orchestrator)

**Code:**
```mql5
ENUM_DEAL_TYPE dt = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
// Closing deal type is opposite of the original position direction:
//   DEAL_TYPE_SELL closes a long  ⇒ direction = 1 (was BUY)
//   DEAL_TYPE_BUY  closes a short ⇒ direction = 0 (was SELL)
int direction = (dt == DEAL_TYPE_SELL) ? 1 : 0;
```

**Problem:**
The mapping `DEAL_TYPE → direction` assumes the deal is a closing transaction (entry==OUT) so the deal type is opposite the position direction. The earlier guard (`if(entry != DEAL_ENTRY_OUT) return`) ensures entry==OUT, ✅. But MT5 also produces `DEAL_ENTRY_INOUT` (used by netting accounts when a single deal closes one position and opens another in opposite direction) — the guard rejects INOUT events entirely, missing the close component. For hedging accounts (FBS Real per C-5/C-10) this is fine since INOUT doesn't apply, but if the operator deploys to a netting account in Phase 2, BR-3.6 silently misses the close half of every reversal.

Also: `DEAL_TYPE_BALANCE`, `DEAL_TYPE_CREDIT`, `DEAL_TYPE_BONUS` etc. (deposit / credit deals) all hit the `else` branch and encode as direction=0, then `RecordClose(magic, 0, t)` is called — these aren't real closes. The earlier `entry != DEAL_ENTRY_OUT` guard rejects them ✅ since they don't have DEAL_ENTRY_OUT semantics — verified in MT5 docs. So this defect is theoretical for the FBS hedging account but worth a comment + assert.

**Why This Matters:**
Phase 2 broker change risk + future-defect class. The current encoding is correct for hedging-mode FBS (C-5) but silently fails for netting brokers. NFR-1.1 behavioral parity contract was scoped to FBS-hedging only — but if Phase 2 evolves to multi-broker per BA `03 § 5 Note`, the trade-transaction code must already handle netting.

**Suggested Fix:**
Add explicit guard against non-trade deal types + a comment citing the netting limitation:

```mql5
   // Reject non-trade deal types (deposit/credit/bonus etc.) defensively;
   // the entry==OUT guard above already does this for FBS hedging accounts,
   // but documenting + asserting protects against Phase 2 broker change.
   if(dt != DEAL_TYPE_BUY && dt != DEAL_TYPE_SELL) return;

   // Hedging-mode mapping (C-5 + ADR-001). Netting-mode brokers (DEAL_ENTRY_INOUT
   // for partial-close-and-reverse) require separate handling — out-of-scope
   // per Phase 1 BA `03 § 5 Note`; revisit if multi-broker evolves.
   int direction = (dt == DEAL_TYPE_SELL) ? 1 : 0;
```

LoE: Low (3-line change + comment).

**Level of Effort:** Low

---

### Finding 11.5: 🟡 MEDIUM — `OnTradeTransaction` continues recording closes after EA halts — wastes ring slots + noise during HALTED/HALTED_STABLE windows

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 664-686
- Service: ea (Orchestrator)

**Code:**
```mql5
void COrchestrator::OnTradeTransaction(...)
  {
   if(m_breaker == NULL) return;
   // <-- no m_state_enum check
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ...
   m_breaker.RecordClose(magic, direction, t);
  }
```

**Problem:**
Once the EA has reached `EA_STATE_HALTED` (or HALTED_STABLE), no new entries fire (per ADR-010 enable matrix) → therefore there cannot be new ping-pong situations driven by PhoenicisNex actions. But CrossSlotCoordinator's exit pass + closes from external sources continue to feed `RecordClose`, padding the ring buffer with halt-window events. When the EA is later un-halted (manual operator restart), the first non-halt tick may immediately re-trip `CheckPingPong()` because the ring still holds rapid HALTED-window closes.

The `_TeardownAll` of HALTED_STABLE doesn't reset the breaker's ring. So state leaks across halt → restart cycle.

**Why This Matters:**
Restart-loop risk. Operator halts the EA after a flash-DD, drains positions (which feed RecordClose via the exit pass), then restarts → BR-3.6 immediately re-trips on the drain events from the halt cycle → second halt → operator must wait 3s window → ratelimit-style restart loop.

**Suggested Fix:**
Either (a) gate `RecordClose` on `m_state_enum == EA_STATE_RUNNING`, or (b) call `m_breaker.Reset()` (add this method if not present) on halt-state-restore in OnInit Phase C step `RestoreFromState`. Option (b) is cleaner because it preserves the cross-process audit trail; Option (a) is simpler.

```mql5
   // Gate option A
   if(m_state_enum != EA_STATE_RUNNING) return;
```

LoE: Low (1 line + 1 SelfTest case in Spike_CircuitBreaker for halt-cycle restart).

**Level of Effort:** Low

---

### Finding 11.6: 🔵 LOW — `OnTester()` returns raw equity — no NFR-2.5 Sharpe-style optimizer score; G3 optimizer runs (if any) will rank backtests by absolute equity, biasing toward high-leverage outcomes

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 696-699
- Service: ea (Orchestrator)

**Code:**
```mql5
double COrchestrator::OnTester()
  {
   return AccountInfoDouble(ACCOUNT_EQUITY);
  }
```

**Problem:**
The body comment (line 691-694) acknowledges this is a Phase 1 placeholder pending IMPL-061..063 tuning. But (a) no E-AC currently flags "OnTester returns equity not Sharpe" as a risk; (b) `simulation/headless-tests/bootstrap_smoke.ini` does have `Optimization=0` per TD-02 §13.3 ✅ — so this only bites if an operator manually flips Optimization=1 before IMPL-061 lands. The placeholder is functional but not signposted in the deferred-AC registry as a known dependency.

NFR-2.5 expects the score to encode profit + risk-adjusted return per CodeWiki §1; pure equity is monotonically correlated with profit at lev=500 (per C-7) which biases optimizer toward dangerous parameter sets in any future tuning.

**Why This Matters:**
Future operator footgun — particularly during Phase 5 hardening if the operator wants to optimize parameters before the proper Sharpe formula lands. Today only a documentation gap.

**Suggested Fix:**
Either (a) register an explicit deferred-AC row pointing at IMPL-061..063 OnTester finalization, with `Risk-if-missed: optimizer ranks by raw equity → leverage bias`, or (b) at minimum add a Print warning when the Tester run uses optimization mode:

```mql5
double COrchestrator::OnTester()
  {
   // Phase 1 placeholder per FR-2.5; final Sharpe-style score lands at
   // IMPL-061..063 (see deferred-ac-registry § OnTester score row).
   // Loud warning if optimizer is enabled — raw-equity ranking biases
   // toward high-leverage outcomes (C-7 lev=500).
   if(MQLInfoInteger(MQL_OPTIMIZATION))
      Print("[Phoenicis][slot=system][ev=ontester_placeholder] WARNING: ",
            "Optimization enabled but OnTester returns raw equity; ",
            "rankings will be biased — see IMPL-061..063");
   return AccountInfoDouble(ACCOUNT_EQUITY);
  }
```

LoE: Low (~6 line warning + registry row).

**Level of Effort:** Low

---

### Finding 11.7: 🟡 MEDIUM — Entry .mq5 + IMPL-060 closure stack 37+ deferred-AC rows behind the very first Tester run; G3/G4 walk has not yet executed — Phase Gate cannot close until walk artifact exists

**Location:**
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` (full file — first compile of entry surface)
- Cross-reference: `docs/state/deferred-ac-registry.md § IMPL-060 Cascade Drain Plan` (R10 § 10.8 fix)
- Service: ea

**Problem:**
R10 § 10.8 raised this as a single-point empirical-failure concentration concern; fix-round-10 chose to address it via documentation (registry cascade plan) rather than spike harness extension. R10 was correct to accept that path — but the concentration is now an actual blocker since IMPL-060 has landed without a cascade-drain walk artifact attached.

CLAUDE.md §1 Three-Tier Closure: Tier 1.5 walk artifact = headless backtest + Tester log + journal audit. The plan currently has 0 such artifacts at `_session-handoff/` for IMPL-060, and `simulation/headless-tests/bootstrap_smoke.ini` has not been executed against the post-IMPL-060 binary (per recent commits: `[chore:state] Tier 1.5 walk batch-1 — IMPL-060 G2 drained + 2 defects surfaced` does suggest a partial walk happened, but the evidence handoff for IMPL-060 itself is in-flight + the 2 defects surfaced are not documented in commit message).

**Why This Matters:**
Phase Gate Hallucination risk per CLAUDE.md §1 (red callout). If `/next` reads `[x]` task ACs for IMPL-060 but no Tier 1.5 artifact + no Tier 2 Phase Gate IMPL-Pn-GATE row, status agents may report "P4 complete" — exactly the defect class that CLAUDE.md §1 was designed to prevent.

**Suggested Fix:**
Before any `/impl-task` selects IMPL-061..068, the operator must:
1. Run `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/bootstrap_smoke.ini /tmp/bootstrap_run.txt`.
2. Capture Tester log + journal sample → write `docs/state/_session-handoff/IMPL-060-evidence-walk-2026-05-04.md`.
3. Promote the 2 surfaced defects into IMPL-FIX-* tickets per Tier 1.5 spec.
4. Update `docs/state/deferred-ac-registry.md § Active` IMPL-060 row to either Resolved (if walk passes) or extend expiry with new findings.

LoE: Medium (~30 min walk + artifact authoring; the actual code is presumably correct, this is a state-reconciliation discipline finding).

**Level of Effort:** Medium

---

### Finding 11.8: 🔵 LOW — Entry .mq5 has no `#property tester_*` directives — Strategy Tester runs may use defaults that don't match TD-02 §13.3 standard `[Tester]` block

**Location:**
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5`, Lines: 28-32 (`#property` block)
- Service: ea (entry)

**Code:**
```mql5
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"
#property description "PhoenicisNex EA — single-instrument EURUSD H4 modular monolith"
#property strict
```

**Problem:**
MQL5 supports `#property tester_indicator` / `#property tester_file` / `#property tester_library` / `#property tester_no_cache` properties that pin Tester behavior. The entry .mq5 declares none — Tester defaults apply. For PhoenicisNex specifically:
- No custom tester_indicators are used (all indicators are core MT5).
- No file dependencies declared, but `state.json` + `journal/*.jsonl` are read/written under `MQL5/Files/PhoenicisNex/`.
- Lacking `#property tester_no_cache` could cause Tester to use stale cache between consecutive G3 runs.

Not a correctness bug today — defaults work — but explicit declarations protect reproducibility per TD-02 §13.6 + .claude/rules/testing.md.

**Why This Matters:**
G3 reproducibility = audit contract. A future MT5 build that changes Tester defaults silently invalidates committed `simulation/headless-tests/<task>.ini` files. Explicit `#property` declarations pin behavior.

**Suggested Fix:**
Add at minimum:
```mql5
#property tester_no_cache       // force fresh tick stream each G3 run
```

If state.json / journal directories must be Tester-visible, also declare:
```mql5
#property tester_file "PhoenicisNex/state/state.json"
```

(Optional — the file is read at runtime via FileOpen so the property may be unnecessary; verify with G3 dry run.) LoE: Low.

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-11.1 — `_TeardownAll` + `~COrchestrator()` + `OnDeinit` form 3 entry surfaces into the same release sequence with conflicting emit semantics

The teardown surface is now: (a) `OnDeinit` → `_TeardownAll` (Info, deinit_cleanup) ✅; (b) `CleanupPartialInit("Phase X fail")` → `_TeardownAll` (Error, init_failed_cleanup) ✅; (c) `~COrchestrator()` → `CleanupPartialInit("dtor_fallback")` → `_TeardownAll` (Error) ❌ when value-typed global. Finding 11.1 fixes the dtor case but the underlying topology — three entry surfaces, two emit kinds, one teardown body — should be unified behind a single dispatch helper:

```mql5
enum ETeardownReason { TEARDOWN_NORMAL, TEARDOWN_INIT_FAIL, TEARDOWN_DTOR_FALLBACK };
void _Teardown(ETeardownReason r, string detail);
```

Each public surface (`OnDeinit`, `CleanupPartialInit`, `~COrchestrator`) routes through `_Teardown` with the right enum + emit semantics chosen by switch. Eliminates the dtor/ondeinit double-emit class entirely.

### XS-11.2 — D-8 banner (Orchestrator.mqh:50-56) cites "Entry .mq5 (IMPL-060) must forward MT5 OnTradeTransaction lifecycle" — IMPL-060 has now landed and forwards correctly ✅ — banner should be amended to "wired" instead of pending

The D-8 deviation row reads as if entry .mq5 is still pending. With IMPL-060 in main, the wiring is live. Update the banner to reflect closed-loop status + cite the entry .mq5 line numbers (PhoenicisNex.mq5:80-85). LoE: Low (3-line banner amend).

### XS-11.3 — `OnTradeTransaction` magic-range guard (per Finding 11.2) and `IsPhoenicisMagic()` helper would also benefit `services/CrossSlotCoordinator.mqh::_AggregateWeakMetrics` (which currently iterates PortfolioState — assumed already filtered) and any future Phase 2 multi-EA wiring. Worth adding the helper centrally in `domain/EnumTypes.mqh` alongside `PHOENICISNEX_MAGIC_COUNT`.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 11.1 | 🔴 CRITICAL | Business Logic / Error Handling | Value-typed global `g_orchestrator` ⇒ dtor double-emits `init_failed_cleanup` after every normal OnDeinit | PhoenicisNex.mq5:41 + Orchestrator.mqh:156-162, 395-415 | Low |
| 11.2 | 🟠 HIGH | Security / Business Logic | `OnTradeTransaction` ไม่ filter ตาม `_Symbol` หรือ magic range — foreign EA events feed BR-3.6 | Orchestrator.mqh:664-686 | Low |
| 11.3 | 🟠 HIGH | Error Handling | `OnTradeTransaction` may fire pre-OnInit-complete; `m_breaker` Init not asserted | PhoenicisNex.mq5:80-85 + Orchestrator.mqh:664-668 | Low |
| 11.4 | 🟡 MEDIUM | Business Logic | `DEAL_TYPE → direction` mapping silent on netting / non-trade deal types | Orchestrator.mqh:678-682 | Low |
| 11.5 | 🟡 MEDIUM | Business Logic | RecordClose continues during HALTED — buffer poisoning across halt cycle | Orchestrator.mqh:664-686 | Low |
| 11.6 | 🔵 LOW | TD Compliance | OnTester returns raw equity; placeholder not flagged in deferred-AC registry | Orchestrator.mqh:696-699 | Low |
| 11.7 | 🟡 MEDIUM | Test Coverage / State Reconciliation | IMPL-060 walk artifact missing; 37+ deferred-ACs gated on Tier 1.5 walk that hasn't run | PhoenicisNex.mq5 (entry surface) + registry | Medium |
| 11.8 | 🔵 LOW | TD Compliance | Entry .mq5 missing `#property tester_no_cache` — G3 reproducibility risk | PhoenicisNex.mq5:28-32 | Low |

---

## Recommendation

**Needs immediate attention** — 1 CRITICAL + 2 HIGH findings to fix BEFORE the Tier 1.5 exploratory walk, otherwise the walk artifact will be polluted by 11.1 (false-positive `init_failed_cleanup` Errors on every smoke run) and the BR-3.6 detector observed during the walk will be testing the wrong filter scope (11.2/11.3).

**Fix priority:**
1. **11.1 (CRITICAL)** — `m_teardown_done` flag in `~COrchestrator()` — restores fix-round-10 §10.11 contract for value-typed global path (~5 LOC + 1 SelfTest).
2. **11.2 (HIGH)** — `_Symbol` + magic-range filter in `OnTradeTransaction` — protects BR-3.6 from foreign-event pollution (~5 LOC + helper).
3. **11.3 (HIGH)** — `m_logger == NULL` guard inside `CCircuitBreaker::RecordClose` — defends pre-OnInit window (~3 LOC + SelfTest).
4. **11.5 (MEDIUM)** — `m_state_enum != EA_STATE_RUNNING` gate (~1 LOC).
5. **11.4 (MEDIUM)** — non-trade deal-type guard + netting comment (~3 LOC).
6. **11.7 (MEDIUM)** — Tier 1.5 walk artifact authoring (~30 min) — must complete before IMPL-061 picks up.
7. **11.6, 11.8 (LOW)** — bundle as cosmetic in same fix-round commit.

**Plan Staleness Sentinel:** Still flagged from R10 (10 closures since R06 + 2 more since R10 = 12). `/impl-plan-review all` still recommended before IMPL-061 selection.

**On structural quality:** IMPL-060 entry .mq5 is genuinely thin (87 LOC vs 500 budget) and faithfully delegates 5 lifecycle handlers. The defect cluster above is concentrated in two areas: (a) the value-typed-global vs heap-pointer assumption mismatch with R10 §10.11 fix (Finding 11.1), and (b) the unfiltered OnTradeTransaction surface (11.2/11.3/11.4/11.5). Both are "boundary" issues — the verbatim core compositional logic remains solid.
