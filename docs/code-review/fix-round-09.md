# Code Review Fix Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Review File** | `docs/code-review/review-round-09.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source code touched** | 3 files (`services/CrossSlotCoordinator.mqh`, `services/PortfolioState.mqh`, `spike/Spike_CrossSlotCoordinator.mq5`) + 1 registry (`docs/state/deferred-ac-registry.md`) |
| **G1 verification** | Spike_CrossSlotCoordinator + Spike_PendingMachineRegistry — both 0 errors / 0 warnings |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 09.1 | `_AggregateWeakMetrics` no magic filter | 🟠 HIGH | **Accept** | CrossSlotCoordinator.mqh + PortfolioState.mqh (new `IsKnownMagic`) | bundled |
| 09.2 | `Run*` emit `_triggered` log on 0-close | 🟠 HIGH | **Accept** | CrossSlotCoordinator.mqh (RunSafePort + RunOrderGroup2; RunForceCutloss already short-circuits) | bundled |
| 09.3 | `m_trade.SetTypeFilling()` never called | 🟡 MEDIUM | **Accept** | CrossSlotCoordinator.mqh (Init + 2 close-fail Warn→Error promotions) | bundled |
| 09.4 | Dead `m_risk` injection | 🟡 MEDIUM | **Accept** | CrossSlotCoordinator.mqh + Spike_CrossSlotCoordinator.mq5 (Init signature 5→4 args) | bundled |
| 09.5 | SelfTest zero close-path coverage | 🟡 MEDIUM | **Partial** (registered as deferred-AC, not coded) | deferred-ac-registry.md (new P4 row, expires 2026-05-18) | bundled |
| 09.6 | `RunOrderGroup2` double `ichi_active` eval | 🔵 LOW | **Accept** | CrossSlotCoordinator.mqh (drop quick-out, single gate via predicate) | bundled |
| 09.7 | `slots_closed_count` semantic mismatch | 🔵 LOW | **Accept** | CrossSlotCoordinator.mqh (rename var + log key + header banner amend) | bundled |

**Accepted:** 6/7 (Option (a) rename for 09.7). **Partial:** 1/7 (09.5 → deferred-AC registry per reviewer's alternate). **Rejected:** 0.

## Accepted Findings — Fixes Applied

### Fix for Finding 09.1 — Magic-set filter in `_AggregateWeakMetrics`

**Approach:** Add silent membership predicate `bool CPortfolioState::IsKnownMagic(int magic)` (distinct from `GetByMagic` which Warns on miss — needed for hot loops). Insert filter immediately after EURUSD whitelist.

**Changes:**
- `services/PortfolioState.mqh` — public `IsKnownMagic(int magic)` declaration + body (returns `m_map.TryGetValue(magic, s)`); non-const because `CHashMap.TryGetValue` is non-const.
- `services/CrossSlotCoordinator.mqh::_AggregateWeakMetrics` — `if(!m_portfolio.IsKnownMagic((int)mg)) continue;` after EURUSD gate. Comment cites Finding 09.1 + the cross-EA / manual / copy-trade leakage rationale.

### Fix for Finding 09.2 — Guard `_triggered` log on actual close count

**Approach:** Wrap the Info log in `if(tickets_closed_count > 0)` and emit a dedicated `Warn("…_no_op")` when the trigger condition fired but `_CloseSlotGroup` returned 0 across all targets (today's behavior under the `GetTicketsForSlot` stub). Pattern applied to `RunSafePort` + `RunOrderGroup2`. `RunForceCutloss` already short-circuits at `if(closed <= 0) return;` (line 572) so no change needed.

**Changes:**
- `RunSafePort` — new `safe_port_no_op` Warn branch + early-return; existing Info renamed to `tickets_closed=` (see 09.7).
- `RunOrderGroup2` — new `order_group_2_no_op` Warn branch + early-return; existing Info renamed.
- Both Warn messages include the gate context (`weak`, `avg_bad_pip`, `pl`, `halted`) plus `stub=GetTicketsForSlot` so the reader knows why the close set was empty.

### Fix for Finding 09.3 — Detect filling-policy in Init + escalate close-fail

**Approach:** In `Init`, query `SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)` and call `m_trade.SetTypeFilling(...)` with the preferred mode (IOC > FOK > RETURN). Promote both `*_close_fail` log calls from `Warn` to `Error` so ADR-011 Alert escalation fires per NFR-5.1.

**Changes:**
- `Init` body — bitmask-driven SetTypeFilling block; comment cites BR-1.5 + ea.md MQL5 idiom #4.
- `_CloseSlotGroup` — `Warn` → `Error` on `!ok` branch.
- `_CloseCDPositionsInLoss` — same `Warn` → `Error` promotion for `force_cutloss_close_fail`.

### Fix for Finding 09.4 — Drop `m_risk` dead dependency

**Approach:** Remove the `CRiskManager*` member, ctor init, Init parameter, body assignment, and `#include "RiskManager.mqh"`. Update spike Init call to drop the trailing NULL.

**Changes:**
- `services/CrossSlotCoordinator.mqh` — 5 deletion sites (include, member field, ctor init, Init param, Init body); class header doc adds a one-line comment explaining the deliberate non-injection.
- `spike/Spike_CrossSlotCoordinator.mq5:31` — `Init(NULL, NULL, &g_logger, NULL, NULL)` → `Init(NULL, NULL, &g_logger, NULL)`.

### Fix for Finding 09.6 — Drop `RunOrderGroup2` quick-out

**Approach:** Per reviewer's option "consolidate the gate to one place" — remove the `if(!ichi_active) return;` quick-out and let `_OrderGroup2Triggered(ctx.derived.ichi_double_bounce_active, weak_count)` be the single gate. Cost: one extra `_AggregateWeakMetrics` pass when ichi=false (single position-loop iteration — negligible).

**Changes:**
- `RunOrderGroup2` — drop 3 lines; pass derived flag inline to predicate.

### Fix for Finding 09.7 — Rename `slots_closed_count` → `tickets_closed_count`

**Approach:** Reviewer Option (a) — rename variable + log key to match actual semantics (per-ticket close calls, not slot-group count).

**Changes:**
- `RunSafePort` — `slots_closed_count` → `tickets_closed_count`; log key `slots_closed=%d` → `tickets_closed=%d`; return value name updated.
- `RunOrderGroup2` — same rename.
- File header banner — extended spec deviation block explaining the semantics + citing Finding 09.7.

### Partial Fix for Finding 09.5 — Register as deferred-AC

**Approach:** Per reviewer's explicit alternate ("register this gap in `deferred-ac-registry.md` as P4 row tied to IMPL-007 landing"). Building `CPortfolioStateFake` now (~80 LOC) duplicates fixture infrastructure that IMPL-007 + IMPL-053+ smoke already provides; cheaper to wait one task cycle.

**Changes:**
- `docs/state/deferred-ac-registry.md` — new Active row at top of P4 group: "CrossSlotCoordinator close-path empirical exercise" — covers `_AggregateWeakMetrics` magic-filter, `_CloseSlotGroup`, `_CloseCDPositionsInLoss`. Owner Kritsana, opened 2026-05-04, expires 2026-05-18 (≤14d). Risk-if-missed: regression in `IsKnownMagic` cast or `_CloseSlotGroup` per-ticket loop slips through to QA Phase 3T.

## Rejected Findings

None.

## Summary

| Metric | Value |
|--------|-------|
| Total findings | 7 |
| Accepted | 6 |
| Partial | 1 (09.5 → deferred-AC) |
| Rejected | 0 |
| Source files modified | 3 |
| Registry rows added | 1 |
| Tests added/updated | 0 (predicates already covered; close-path coverage deferred per 09.5) |
| Commits | 1 (bundled — single-service surface) |
| G1 status | Spike_CrossSlotCoordinator 0/0; Spike_PendingMachineRegistry 0/0 |

## Recommendation

Ready for **review-round-10** (or — if reviewer judges the coordinator surface stable — promote toward the IMPL-059 Orchestrator wiring window when the close-path empirical row drains via IMPL-007). The 2 HIGH findings (09.1 + 09.2) are now closed at structural+observability layer; the remaining empirical surface is the close-path itself, which the registry row pins until IMPL-007 lands.
