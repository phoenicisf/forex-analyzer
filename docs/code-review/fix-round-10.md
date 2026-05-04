# Code Review Fix Round 10

| Field | Value |
|-------|-------|
| **Round** | 10 |
| **Review File** | `docs/code-review/review-round-10.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source files touched** | 5 (`core/Orchestrator.mqh`, `services/Logger.mqh`, `domain/EnumTypes.mqh`, `services/PortfolioState.mqh`, `services/StatePersistence.mqh`, `services/TradeJournal.mqh`) + 1 registry (`docs/state/deferred-ac-registry.md`) |
| **G1 verification** | Spike_Orchestrator + Spike_StatePersistence + Spike_TradeJournal + Spike_CrossSlotCoordinator + Spike_Slot_B — all 0 errors / 0 warnings |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 10.1 | `WireServices()` void → Phase A NULL deref | 🔴 CRITICAL | **Accept** | Orchestrator.mqh (header banner D-7 + decl + body + OnInit call site) | bundled |
| 10.2 | `OnTick` skips RunExitPass on morning_block | 🟠 HIGH | **Accept** | Orchestrator.mqh::OnTick | bundled |
| 10.3 | CircuitBreaker producer-side never wired | 🟠 HIGH | **Partial** — handler landed; entry .mq5 plumbing tied to IMPL-060 | Orchestrator.mqh (decl + body + D-8 banner) + registry IMPL-060 cascade plan | bundled |
| 10.4 | dtor_fallback emits via never-Init'd CLogger | 🟡 MEDIUM | **Accept** | Logger.mqh + Orchestrator::CleanupPartialInit | bundled |
| 10.5 | Stale state.json save on morning_block | 🟡 MEDIUM | **Accept** (subsumed by 10.2) | Orchestrator.mqh | bundled |
| 10.6 | `WireSlots()` misnamed | 🔵 LOW | **Accept** | Orchestrator.mqh (drop method + inline check) | bundled |
| 10.7 | Hardcoded magic count `17` at 5+ sites | 🔵 LOW | **Accept** | EnumTypes.mqh + PortfolioState.mqh + StatePersistence.mqh + TradeJournal.mqh + Orchestrator.mqh | bundled |
| 10.8 | Spike covers Phase A only; 36+ E-ACs gated on IMPL-060 | 🟡 MEDIUM | **Partial** — registry meta-section, not Spike harness extension | deferred-ac-registry.md | bundled |
| 10.9 | `RunExitPass(ctx)` ctx unused — D-6 | 🔵 LOW | **Accept** | Orchestrator.mqh header banner | bundled |
| 10.10 | HALTED_STABLE Alert text omits halt reason | 🟡 MEDIUM | **Accept** | Orchestrator.mqh:518 | bundled |
| 10.11 | OnDeinit reuses `init_failed_cleanup` event tag | 🔵 LOW | **Accept** — split via `_TeardownAll` helper | Orchestrator.mqh | bundled |
| XS-10.1 | Multi-task gating block expiring 2026-05-17/18 | — | **Accept** (10.8) | deferred-ac-registry.md cascade plan | bundled |
| XS-10.2 | D-2 + 10.3 compounded silent BR-3.6 failure | — | **Accept** | Orchestrator.mqh D-8 banner | bundled |
| XS-10.3 | ODR index static-assert SelfTest | — | **Reject** | n/a | n/a |

**Accepted:** 11/11 base findings (1 Partial 10.3 + 1 Partial 10.8) + 2/3 cross-service. **Rejected:** 1 (XS-10.3, see below).

## Accepted Findings — Fixes Applied

### Fix for Finding 10.1 (CRITICAL) — `WireServices()` returns bool with per-alloc NULL re-check

**Approach:** Promote `WireServices()` from `void` to `bool`. Each `new T()` is followed by an immediate `if(member == NULL) return false;` re-check. OnInit Phase A calls `if(!WireServices()) { CleanupPartialInit("wire_services_alloc_fail"); return INIT_FAILED; }`. The 19 per-step alloc+check pairs are folded behind a local `PHOENICISNEX_WIRE` macro (`#define`/`#undef` scoped to the body) so adding a new service in the future is a single line that cannot forget the NULL re-check. Logger is allocated FIRST so CleanupPartialInit's emit branch has a Logger to consult; if Logger itself fails to allocate, CleanupPartialInit's Print fallback (Finding 10.4 fix) takes over.

**Changes:**
- `core/Orchestrator.mqh` — header banner D-7 deviation row added; private decl `void WireServices()` → `bool WireServices()`; body rewritten with macro + per-step NULL re-check + `return true`; OnInit Phase A call site routes to CleanupPartialInit at the 9th INIT_FAILED site.
- `WireSlots()` removed entirely (Finding 10.6); the `m_registry != NULL` invariant is now ensured by WireServices's per-alloc NULL re-check + the Phase C `m_registry.RegisterAll` failure path.

### Fix for Finding 10.2 (HIGH) + 10.5 (MEDIUM) — Hoist exit pass + portfolio refresh out of morning_block

**Approach:** The `if(!morning_block)` block previously gated the entire exit pipeline (`Refresh` / `TickAll` / `RunExitPass` / 5 xslot exit helpers / `HolidayBlock`). Restructured so only the ENTRY pass is gated on morning_block — the exit pass and all housekeeping run every tick. ADR-010 enable matrix promise ("exit pass always runs, even in HALTED") is now actually honored. State.json save (step 13) reads fresh portfolio aggregates because Refresh ran.

**Changes:**
- `core/Orchestrator.mqh::OnTick` — re-flowed steps 6 → 11 with explicit comments citing fix-round-10 § 10.2/10.5 + the BR-3.1 / CodeWiki §3.1 / ADR-010 / ADR-008 contracts at stake. monday_block now computed unconditionally (cheap); holiday_block computed every tick (needed for entry pass gate).

### Fix for Finding 10.3 (HIGH) — CircuitBreaker producer-side handler

**Approach:** Added `COrchestrator::OnTradeTransaction(MqlTradeTransaction&, MqlTradeRequest&, MqlTradeResult&)` MT5 lifecycle method. Filters trade-transaction stream to `TRADE_TRANSACTION_DEAL_ADD` deals with `DEAL_ENTRY_OUT` entry kind (closes only), then calls `m_breaker.RecordClose(magic, direction, time)` with direction derived from `DEAL_TYPE` (closing SELL = was BUY direction=1; closing BUY = was SELL direction=0).

**Partial:** Entry .mq5 (IMPL-060) does not yet exist, so the MT5 lifecycle plumbing (`OnTradeTransaction` global → `g_orch.OnTradeTransaction(...)`) cannot be wired in this round. Added a Tier-1 row in the deferred-AC registry's new "IMPL-060 Cascade Drain Plan" subsection that explicitly tracks this plumbing alongside IMPL-007 PortfolioState OnTradeTransaction populator. Once IMPL-060 lands, both wirings happen in the same entry-point file.

**Changes:**
- `core/Orchestrator.mqh` — public decl + body; D-8 deviation row added to header banner explaining producer-side wiring + entry-point dependency.
- `docs/state/deferred-ac-registry.md` — new "IMPL-060 Cascade Drain Plan" subsection (Tier 1 row for D-8 entry-point plumbing).

### Fix for Finding 10.4 (MEDIUM) — Logger init-state guard in CleanupPartialInit

**Approach:** Added `bool m_initialized` flag to `CLogger`, set `false` in ctor + `true` at end of `Init()`. Public accessor `bool IsInitialized() const`. `CleanupPartialInit` now branches: if Logger is non-NULL AND initialized → `ErrorBypassThrottle`; else → `Print("[Phoenicis][slot=system][ev=init_failed_cleanup] reason=... (logger un-init — Print fallback)")`. The current `ErrorBypassThrottle` body is benign on an un-Init'd CLogger (it only touches `m_alert_on_error` which the ctor sets to true), but routing through Print keeps the safety contract independent of any future CLogger refactor that might dereference `m_state` or throttle arrays.

**Changes:**
- `services/Logger.mqh` — new private member + ctor init + accessor + `m_initialized = true` at end of `Init()`.
- `core/Orchestrator.mqh::CleanupPartialInit` + `OnDeinit` — both gated on `m_logger.IsInitialized()`.

### Fix for Finding 10.6 (LOW) — Drop `WireSlots()`

**Approach:** Per-alloc NULL re-check in WireServices (Finding 10.1 fix) already covers `m_registry != NULL`. WireSlots was a misleading 5-line stub that didn't actually wire any slots. Removed entirely; OnInit Phase A is now a single `if(!WireServices())` gate.

**Changes:**
- `core/Orchestrator.mqh` — private decl removed; body removed; header banner Phase A description simplified.

### Fix for Finding 10.7 (LOW) — `PHOENICISNEX_MAGIC_COUNT` constant

**Approach:** Added `#define PHOENICISNEX_MAGIC_COUNT 17` to `domain/EnumTypes.mqh` (transitively included by all consumers via PortfolioState). Replaced literal `17` at 5 sites across 4 files (reviewer cited 3 sites; full scope was 5 — added Orchestrator + 2 in TradeJournal). Comments at every site retain the human-readable "17 distinct magics" math.

**Changes:**
- `domain/EnumTypes.mqh` — new `#define` after MAGIC_T constants.
- `services/PortfolioState.mqh` — `m_magic_list[17]` → `[PHOENICISNEX_MAGIC_COUNT]`; `int magics[17]` array literal + ArrayCopy + for-loop bound.
- `services/StatePersistence.mqh` — `int magics[17]` array literal + for-loop bound.
- `services/TradeJournal.mqh` — 2 occurrences of `int magics[17]` + for-loop bound (BuildPortfolioSummary slot_counts + total_lots branches).
- `core/Orchestrator.mqh` — `ValidateSlotRegistry(..., 17)` → `..., PHOENICISNEX_MAGIC_COUNT)`.

### Fix for Finding 10.8 (MEDIUM) + XS-10.1 — Cascade drain plan

**Approach:** Per reviewer's alternate path ("register meta-row paragraph"). Added a new "IMPL-060 Cascade Drain Plan" subsection to `deferred-ac-registry.md` between the Active table and Resolved table. Tiers the ~36 deferred rows by dependency: Tier 0 composition root + cheap log-assertions / Tier 1 PortfolioState OnTradeTransaction + CircuitBreaker entry-point plumbing / Tier 2 cross-slot close-path / Tier 3 per-slot 60-day Tester runs / Tier 4 boot-cold + persistence cycles. Recommends a Tier-0+1 cheap smoke first, then scoped fixtures in dependency order.

Did NOT extend Spike_Orchestrator with synthetic-mocking SelfTest — LoE/value tradeoff: header-only IMPL-018+ precedent already justifies Spike scope; cascade documentation gives reader the same "where's the risk" map without duplicating Phase B init logic in spike fixtures.

### Fix for Finding 10.9 (LOW) — D-6 deviation banner row

**Approach:** Added D-6 to the header banner deviation log, documenting that `RunExitPass(const MarketContext &ctx)` accepts ctx for symmetry with RunEntryPass + future ctx-aware exit policies, but `CSlotBase::ManageExits(CPortfolioState&)` per IMPL-018 contract has no ctx parameter, so ctx is not forwarded today.

### Fix for Finding 10.10 (MEDIUM) — Halt reason in HALTED_STABLE Alert

**Approach:** 1-line change in OnTick step 14. Alert StringFormat now includes `m_halt_reason` ahead of the throttled-count digest:

> `PhoenicisNex HALTED_STABLE reason=<reason> + N throttled alerts cumulative — check Experts log`

### Fix for Finding 10.11 (LOW) — Split `_TeardownAll` helper

**Approach:** Extracted pure resource-release sequence into private `void _TeardownAll()` (no emit). `CleanupPartialInit(reason)` keeps the `init_failed_cleanup` Error emit then calls `_TeardownAll`. `OnDeinit(reason)` emits `deinit_cleanup` (Info severity) then calls `_TeardownAll` directly — no longer routes through `CleanupPartialInit`. QA Phase 3T `[log-assertion]` E-ACs that grep for `init_failed_cleanup` will now exclusively count true Phase A/C failures, not normal shutdowns.

**Note:** The dtor fallback (`~COrchestrator()`) still calls `CleanupPartialInit("dtor_fallback")` — by intent: if dtor runs without OnInit having been called (anomaly per MT5 lifecycle), the `init_failed_cleanup` Error tag is the right semantic.

## Rejected Findings — Evidence

### Rejection of Finding XS-10.3: ODR index static-assert SelfTest

**Verdict:** Reject (defer; not blocked).

**Evidence:** The IDX_* indices (e.g., `IDX_ICHI_H4`, `IDX_FORCE_H4`) are sequentially assigned 0..23 in the same file (`services/IndicatorService.mqh`) where they are consumed (`CreateHandles`). The ODR fix moved their definitions out-of-class but the values match the original ordinal sequence by construction. A drift would require a hand-edit of the out-of-class definitions to a non-sequential value — and any such drift would manifest immediately as wrong-indicator-output during G3 backtest (e.g., `iIchimoku` returned via `IDX_FORCE_H4` would produce nonsensical entry signals visible in the first Tester run). Adding a SelfTest now duplicates static-assertable information without adding empirical value beyond what G3 already provides. Documenting as deliberate non-fix.

## Verification

```
G1 Compile (Spike_Orchestrator):       Result: 0 errors, 0 warnings, 606 ms elapsed
G1 Compile (Spike_StatePersistence):   Result: 0 errors, 0 warnings, 1491 ms elapsed
G1 Compile (Spike_TradeJournal):       Result: 0 errors, 0 warnings, 1095 ms elapsed
G1 Compile (Spike_CrossSlotCoordinator): Result: 0 errors, 0 warnings, 653 ms elapsed
G1 Compile (Spike_Slot_B):             Result: 0 errors, 0 warnings, 483 ms elapsed
```

G2/G3/G4 deferred to IMPL-060 entry .mq5 + Tester run per IMPL-018+ precedent and the cascade drain plan now documented in the registry.

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 11 base + 3 cross-service = 14 |
| Accepted | 9 base + 2 cross-service |
| Partial | 2 (10.3 entry-point pending; 10.8 registry over Spike extension) |
| Rejected | 1 (XS-10.3) |
| Files Modified | 6 source (`Orchestrator.mqh`, `Logger.mqh`, `EnumTypes.mqh`, `PortfolioState.mqh`, `StatePersistence.mqh`, `TradeJournal.mqh`) + 1 registry (`deferred-ac-registry.md`) |
| Tests Added/Updated | 0 new spike — Tier 0 G1 sweep verified across 5 spikes |
| Commits | 1 bundled (per fix-round-09 precedent — single batch atomic w/ G1 evidence) |

**Recommendation:** ✅ Ready for next review round. Plan Staleness Sentinel hit (10 closures since R06) — recommend `/impl-plan-review all` before IMPL-060 lands.
