# Code Review Fix Round 11

| Field | Value |
|-------|-------|
| **Round** | 11 |
| **Review File** | `docs/code-review/review-round-11.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source files touched** | 3 (`MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5`, `core/Orchestrator.mqh`, `domain/EnumTypes.mqh`) |
| **G1 verification** | Entry `PhoenicisNex.mq5` 4127 ms + Spike_Orchestrator 612 ms + Spike_EAState 879 ms + Spike_CrossSlotCoordinator 629 ms — all `Result: 0 errors, 0 warnings` |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 11.1 | dtor double-emits `init_failed_cleanup` after every normal OnDeinit | 🔴 CRITICAL | **Accept** | Orchestrator.mqh (member flag + dtor + _TeardownAll) + PhoenicisNex.mq5 (banner) | bundled |
| 11.2 | `OnTradeTransaction` ไม่ filter `_Symbol` / magic range | 🟠 HIGH | **Accept** | Orchestrator.mqh (handler body) + EnumTypes.mqh (`IsPhoenicisMagic`) | bundled |
| 11.3 | Pre-OnInit OnTradeTransaction window | 🟠 HIGH | **Accept** | Orchestrator.mqh (`m_init_complete` flag + handler gate) | bundled |
| 11.4 | `DEAL_TYPE → direction` silent on non-trade types | 🟡 MEDIUM | **Accept** | Orchestrator.mqh (handler body) | bundled |
| 11.5 | RecordClose continues during HALTED | 🟡 MEDIUM | **Accept** | Orchestrator.mqh (state-enum gate in handler) | bundled |
| 11.6 | `OnTester` raw equity — no MQL_OPTIMIZATION warning | 🔵 LOW | **Accept** | Orchestrator.mqh (`OnTester` body) | bundled |
| 11.7 | IMPL-060 Tier 1.5 walk artifact missing | 🟡 MEDIUM | **Reject** (as code fix) — operator action | n/a | n/a |
| 11.8 | Entry .mq5 missing `#property tester_no_cache` | 🔵 LOW | **Accept** | PhoenicisNex.mq5 | bundled |
| XS-11.1 | `_TeardownAll` + dtor + OnDeinit conflicting emit semantics | — | **Accept** (subsumed by 11.1 fix via `m_teardown_done`) | Orchestrator.mqh | bundled |
| XS-11.2 | D-8 banner stale — should be "wired" not "pending" | — | **Accept** | Orchestrator.mqh banner D-8 + new D-9/D-10 rows | bundled |
| XS-11.3 | `IsPhoenicisMagic()` helper centralised | — | **Accept** | EnumTypes.mqh | bundled |

**Accepted:** 7/8 base findings (1 Reject = 11.7 operator-only) + 3/3 cross-service. **Rejected:** 1 (11.7 — flagged for operator walk session, not a code defect; see § Rejected Findings).

---

## Accepted Findings — Fixes Applied

### Fix for Finding 11.1 (CRITICAL) — `m_teardown_done` lifecycle flag suppresses dtor double-emit

**Approach.** Add a private `bool m_teardown_done` member, ctor-initialised `false`. `_TeardownAll()` sets it `true` as its last line. The dtor short-circuits (`if(m_teardown_done) return;`) so the value-typed-global path (`PhoenicisNex.mq5:41 COrchestrator g_orchestrator;`) no longer re-routes through `CleanupPartialInit("dtor_fallback")` after MT5's `OnDeinit` already drained the resources. The dtor's safety-net intent (rare partial-init crash where OnDeinit never runs) is preserved: in that case `m_teardown_done` stays `false` and the original Error-tag emit fires.

**Why this works for both lifecycles.**
- **Happy path (production global):** OnInit → INIT_SUCCEEDED → OnTick* → OnDeinit (runs `_TeardownAll`, sets `m_teardown_done=true`) → dtor (early return, no emit). QA Phase 3T `[log-assertion]` E-ACs grepping `init_failed_cleanup` see ONLY genuine Phase A/C failures.
- **Crash path:** OnInit → Phase B/C aborts → `CleanupPartialInit(reason)` → `_TeardownAll` (sets flag true) → INIT_FAILED → MT5 skips OnDeinit → dtor short-circuits because flag is already true. Still no false emit.
- **True partial-init crash (the original safety net):** OnInit body crashes/throws/exits before reaching `CleanupPartialInit` → flag never set → dtor emits `init_failed_cleanup` reason=`dtor_fallback` as designed.

**Changes:**
- `core/Orchestrator.mqh` — added `bool m_teardown_done` private member; ctor initialiser `m_teardown_done(false)`; dtor early-return guard; `_TeardownAll` sets `m_teardown_done = true` as final line; new D-10 banner row documenting both lifecycle flags.
- `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` — comment block above `g_orchestrator` declaration updated to cite the new gate.

### Fix for Finding 11.2 (HIGH) — `_Symbol` + magic-range filters + canonical `IsPhoenicisMagic()` helper

**Approach.** Two filters added inside `OnTradeTransaction` BEFORE `RecordClose`:
1. `if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol) return;` — replicates NFR-5.3 boundary at the trade-transaction surface.
2. `if(!IsPhoenicisMagic(magic)) return;` — rejects manual closes (magic=0) and other-EA magics outside `[200..219]`.

The magic-range gate is exposed as a free function `bool IsPhoenicisMagic(int)` in `domain/EnumTypes.mqh` so any other surface that processes raw magic ids (current: `services/CrossSlotCoordinator.mqh::_AggregateWeakMetrics`; future: Phase 2 multi-EA wiring) can share the same canonical truth-source. Range `[200..219]` matches `MAGIC_*` constants already in EnumTypes.mqh; Slot U=220 is intentionally excluded per OQ-8.

**Changes:**
- `domain/EnumTypes.mqh` — added `bool IsPhoenicisMagic(int magic) { return magic >= 200 && magic <= 219; }` directly below `PHOENICISNEX_MAGIC_COUNT`.
- `core/Orchestrator.mqh::OnTradeTransaction` — symbol filter + `IsPhoenicisMagic` filter inserted between `DEAL_ENTRY_OUT` guard and `RecordClose`.

### Fix for Finding 11.3 (HIGH) — `m_init_complete` flag gates trade-transaction surface

**Approach.** Add a private `bool m_init_complete` member (ctor-init `false`). `OnInit` sets it `true` immediately before `return INIT_SUCCEEDED`. `_TeardownAll` resets it to `false` (defensive — pairs with the teardown-done flag). `OnTradeTransaction` short-circuits on `!m_init_complete` BEFORE touching `m_breaker`, so close events that arrive in the pre-OnInit window during MT5 broker reconnect cannot reach an un-Init'd CircuitBreaker (per MT5 docs note: OnTradeTransaction can fire before OnInit completes during recovery).

This is Option-A from the review (orchestrator-side gate) rather than Option-B (RecordClose-side gate). Chosen because: (a) the gate centralises lifecycle policy in one place (Orchestrator owns the composition root); (b) zero per-call cost on the hot path inside CCircuitBreaker; (c) covers ALL future trade-transaction-driven surfaces by gating at the dispatcher.

**Changes:**
- `core/Orchestrator.mqh` — `m_init_complete` member; ctor init false; OnInit sets true on success; `_TeardownAll` resets false; OnTradeTransaction first-line guard.

### Fix for Finding 11.4 (MEDIUM) — Defensive non-trade deal-type guard

**Approach.** Add explicit `if(dt != DEAL_TYPE_BUY && dt != DEAL_TYPE_SELL) return;` after the `DEAL_ENTRY_OUT` guard. The earlier guard already excludes deposit/credit/bonus deals on FBS hedging accounts (C-5), but the explicit check is grep-evident protection against Phase 2 broker-mode change. Inline comment documents the netting-mode (`DEAL_ENTRY_INOUT`) limitation as out-of-scope per BA `03 § 5 Note`.

**Changes:**
- `core/Orchestrator.mqh::OnTradeTransaction` — type guard + 5-line comment above the `direction` calculation.

### Fix for Finding 11.5 (MEDIUM) — HALTED-state gate

**Approach.** Add `if(m_state_enum != EA_STATE_RUNNING) return;` to OnTradeTransaction. Halt-window drain events (from CrossSlotCoordinator exit-pass + manual operator closes during HALTED) no longer poison the BR-3.6 ring buffer. Restart-loop risk (rapid re-trip after halt → drain → un-halt → first tick re-trips on stale ring slots) eliminated. Cleaner than `m_breaker.Reset()` on un-halt because it preserves the BR-3.6 cross-process audit trail (the ring is naturally pruned by the 5 s near-miss / 3 s ping-pong window after un-halt).

**Changes:**
- `core/Orchestrator.mqh::OnTradeTransaction` — state-enum gate immediately after the init-complete + breaker-NULL gate.

### Fix for Finding 11.6 (LOW) — `MQL_OPTIMIZATION` warning in OnTester

**Approach.** Wrap the existing `AccountInfoDouble(ACCOUNT_EQUITY)` return with a `MQLInfoInteger(MQL_OPTIMIZATION)`-gated `Print` that emits a stable `[Phoenicis][slot=system][ev=ontester_placeholder]` prefix. Operator-facing warning: optimization-enabled runs against the Phase 1 placeholder bias toward leverage-heavy outcomes; final Sharpe-style score lands at IMPL-061..063. The Print fires only when optimizer is enabled, so non-optimization G3 runs (per TD-02 §13.3 `Optimization=0`) emit nothing.

**Changes:**
- `core/Orchestrator.mqh::OnTester` — 5-line warning block + 3-line stable comment.

### Fix for Finding 11.8 (LOW) — `#property tester_no_cache`

**Approach.** Add `#property tester_no_cache` to the entry `.mq5` `#property` block. Pins Strategy Tester to fresh tick stream each run; protects committed `simulation/headless-tests/<task>.ini` reproducibility against a future MT5 build that changes Tester-cache defaults. `#property tester_file "PhoenicisNex/state/state.json"` was NOT added because state files are opened at runtime via `FileOpen` under the `MQL5/Files/` sandbox root which Tester sees natively (verified in earlier IMPL-047 StatePersistence work).

**Changes:**
- `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` — added `#property tester_no_cache` directive + 3-line context comment.

### Fix for XS-11.1 / XS-11.2 / XS-11.3 — Banner refresh + helper centralisation

XS-11.1 is mechanically resolved by 11.1 + 11.3 fixes (the dtor / OnDeinit / CleanupPartialInit topology now has a single emit per surface; the `_Teardown(ETeardownReason)` enum suggested in the review was rejected as over-engineering — a single boolean flag covers the only real bug + adds 1 LOC). D-8 banner amended in Orchestrator.mqh from "Entry .mq5 (IMPL-060) MUST forward" → "WIRED (PhoenicisNex.mq5:80-85)". Two new banner rows added: D-9 (multi-layer OnTradeTransaction guard topology — 5 layers a..e) + D-10 (lifecycle flags). XS-11.3 resolved by `IsPhoenicisMagic()` placement in `domain/EnumTypes.mqh` (canonical SoT).

---

## Rejected Findings — Evidence

### Rejection of Finding 11.7 (MEDIUM) — IMPL-060 Tier 1.5 walk artifact

**Verdict:** Reject (as a code fix). **Rationale:** the finding is correct as a process gate but not a code defect — there is no source file change that resolves it. The work required is operator-side: run `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/bootstrap_smoke.ini /tmp/bootstrap_run.txt`, capture Tester log + journal sample, author `docs/state/_session-handoff/IMPL-060-evidence-walk-2026-05-04.md`, and surface defects as IMPL-FIX-* tickets per the Tier 1.5 spec.

The recent commit `2bb1906 [chore:state] Tier 1.5 walk batch-1 — IMPL-060 G2 drained + 2 defects surfaced` indicates a partial walk DID happen and surfaced this very review's findings (11.1 + 11.2/3/4/5 are the BR-3.6 pollution defects an operator would observe in a smoke run). This fix-round closes those code defects so the **next** walk session can produce a clean artifact. A subsequent operator session must execute the walk + author the handoff — that is outside the impl-review-fix workflow scope per `.agents/workflows/impl-review-fix.md` (which targets code findings only).

The `deferred-ac-registry.md § Active` IMPL-059 + IMPL-060 cascade-drain rows already track this — no registry update needed in this fix-round (registry rows expire 2026-05-17/18 and the operator walk before that date will close them).

---

## Files Modified

| File | Lines changed | Findings addressed |
|------|---------------|---------------------|
| `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` | +9, banner refresh | 11.1 (banner), 11.8 |
| `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh` | +51 banner, +2 members + ctor inits, dtor guard, OnInit `m_init_complete=true`, `_TeardownAll` flag set, OnTradeTransaction filters (5 gates), OnTester warning | 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, XS-11.1, XS-11.2 |
| `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh` | +9 (IsPhoenicisMagic helper) | 11.2, XS-11.3 |

Total: 3 files, ~70 LOC delta (mostly banner + comments; ~25 LOC actual logic).

## G1 Verification

| Compile target | Time | Result |
|----------------|------|--------|
| `PhoenicisNex.mq5` (entry) | 4127 ms | 0 errors, 0 warnings |
| `Spike_Orchestrator.mq5` | 612 ms | 0 errors, 0 warnings |
| `Spike_EAState.mq5` | 879 ms | 0 errors, 0 warnings |
| `Spike_CrossSlotCoordinator.mq5` | 629 ms | 0 errors, 0 warnings |

G2/G3/G4 verification gated on operator Tier 1.5 walk per Finding 11.7 § Rejection. After the walk session completes, expected log signature on a normal smoke run + EA detach:
- 0× `[ev=init_failed_cleanup]` (was: 1× per shutdown before fix 11.1)
- 0× `RecordClose` events from foreign-symbol or out-of-range magic (was: depends on multi-EA terminal state before fix 11.2)
- 1× `[ev=init_ok]` + 1× `[ev=deinit_cleanup]` per attach/detach cycle.

## Summary

| Metric | Value |
|--------|-------|
| Total Findings (incl. cross-service) | 11 |
| Accepted | 10 |
| Rejected | 1 (11.7 — operator action, not code) |
| Files Modified | 3 |
| Tests Added/Updated | 0 (no new spike harness; lifecycle flags are testable only at G2/G3 against running EA — same surface concentration risk flagged in R10 § 10.8) |
| Commits | 1 (bundled) |
| G1 compiles | 4/4 — 0 errors, 0 warnings |

## Recommendation

**Ready for Tier 1.5 exploratory walk.** All CRITICAL + HIGH code defects from R11 are closed; operator can now run `simulation/headless-tests/bootstrap_smoke.ini` against a clean state and observe a polluted-free Experts log. Walk artifact + IMPL-060 evidence handoff is the next gating step before `/impl-task` selects IMPL-061..063.

**Do NOT yet trigger:** `/impl-plan-review all` (Plan Staleness Sentinel still flagged from R10) — defer until after the walk closes IMPL-060 evidence so the review captures the post-walk state in one pass.
