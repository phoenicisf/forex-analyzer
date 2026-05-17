# IMPL-FIX-012 iter-2 — Run #4 EXECUTED; E-AC #1 NOT MET (new ping_pong false-positive class)

**Date:** 2026-05-17
**Status:** 🔴 **iter-2 COMPLETE — Run #4 reached sim 2021-01-27 then HALTED via `circuit_breaker_pingpong`; ADR-013 partial fix (eliminated Jan-14 broker-driven class) but new EA-driven `OrderGroupStartWorkflow` mass-close false-positive class surfaces 13 sim days later. E-AC #1 ("≥ 3 sim months past Jan-14 without ping_pong halt") NOT MET. iter-3 fix scope identified: extend ADR-013 with `triggering_function` filter OR Option-C ticket-dedup (Option C rejected during iter-1 as overkill, now empirically falsified).**
**Workflow:** `/impl-task IMPL-FIX-012` iter-2 (cap-3 budget; iter-1 closed 2026-05-14; iter-3 conditional)

---

## §1 — Diagnostic chain (this session)

1. **19:58 launch attempt 1** → Tester aborted at 0:00:00.000 with `connection to FBS-Real lost` → `some error after pass finished`. Mis-diagnosed as data-dir lock (OPS-001 registered then reverted after operator note "use this repo own MT5 @origin.txt"). PowerShell `Get-Process -Path` confirmed PID 6916 is from `C:\Program Files\FBS MetaTrader 5\` install, not the repo's `5ph` install per origin.txt.
2. **20:13 + 20:17 launch attempts 2-3** → identical `connection lost ~2s → some error` failures. Bootstrap_smoke probe (20:15) PASSED in 11.8s, proving infrastructure healthy ⇒ failure is Model=4-specific (5-yr real-tick verification fails on stale `.tkc` cache).
3. **OPS-002 registered**: operator to refresh tick cache via 5ph GUI Strategy Tester.
4. **20:29–20:32 operator ran GUI backtest** → refreshed tick cache (`202605.tkc` mtime 20:30) + tester agent log warmed (50 MB resident).
5. **20:35 launch attempt 4 (this session) → ✅ Tester ran**. PID 16944 alive, log growing.
6. **20:39:58 sim 2021-05-19 09:24:42** — last tester log entry from running EA before HALTED_STABLE silent-grind began.
7. **20:46 grep of full tester log found halt event** at `wall=20:31:15.975 sim=2021.01.27 15:45:07.692`:
   ```
   [ERROR][slot=CircuitBreaker][ev=ping_pong][magic=205] ping_pong detected: magic=205 dir=0 delta=0s (threshold=3s)
   [ERROR][slot=system][ev=halt][magic=0] circuit_breaker_pingpong
   ```
8. **20:45 killed PID 16944** (HALTED_STABLE silent grind, no further useful data).

---

## §2 — Run #4 outcome (empirical)

| Field | Value |
|-------|-------|
| Launch (wall) | 2026-05-17 20:35:24 |
| Kill (wall) | 2026-05-17 20:45 (~10 min wall total; effective EA work ~5 min before HALTED_STABLE) |
| `.ex5` build | mtime 2026-05-17 19:56 (post fresh G1 PASS attestation; ADR-013 filter at `core/Orchestrator.mqh:847` confirmed in source) |
| Headless config | `simulation/headless-tests/regression_5yr_g4.ini` (Model=4, FromDate 2021.01.01, ToDate 2025.12.31, Deposit=1000, Leverage=500, ShutdownTerminal=1, Visual=0) |
| Halt event (sim) | **2021-01-27 15:45:07.692** — `circuit_breaker_pingpong` magic=205 (Slot_H) dir=0 delta=0s threshold=3s |
| HALTED_STABLE (sim) | **2021-05-25 10:07:53.056** — all_positions_closed (identical timestamp to Run #2 + Run #3) |
| Sim-days past Jan-14 storm | **13 sim days** (Jan-27 - Jan-14 = 13) ⇒ **< 3 sim months target** |
| Final balance | $593.05 (from $1000 = -$406.95 / -40.7%) |
| Final equity | $593.05 (matches balance at halt_stable; 0 lots, 0 floating P/L) |
| Drift vs $24.27M baseline | ≈ 100% (vs NFR-1.1 ≤ 25% target) |
| Journal records | 127 (69 entry + 56 exit + 1 halt + 1 halt_stable) — schema-valid |

**Per-slot entry counts (pre-halt window):** BI=20, H=13, B=10, L=8, LX=5, BR=3, K=2, S=2, T=2, C=1, G2=1, M=1, Q=1 (13 distinct active slots — broader than Run #3's pre-halt window with 14 slots in 14 days; Run #4 reached 27 sim days giving 13 slots ≥1 entry each)

**Exit `triggering_function` distribution:**
- **44 normal slot-side ManageExits** (empty triggering_function = standard close path)
- **11 `OrderGroupStartWorkflow`** (SafePort batch-close — multiple positions closed in same tick by xslot helper)
- **1 `ForceCutloss`** (another xslot helper batch-close)

---

## §3 — Root cause of NEW Jan-27 false-positive

The halt event differs from Run #2/#3 in TWO axes:

| Axis | Run #2/#3 (Jan-14) | Run #4 (Jan-27) |
|------|--------------------|------------------|
| Sim timestamp | 2021-01-14 14:59:21 | 2021-01-27 15:45:07 |
| Slot_H dir | 1 (closing BUY positions) | **0** (closing SELL positions) |
| Close trigger | broker-side SL fills on identical-SL positions (tickets 71+72 BUY w/ SL=1.21311 hit same tick) | **`OrderGroupStartWorkflow` (SafePort) mass-close** (next exit record at sim 2021-01-27T16:43:25 cites `triggering_function:OrderGroupStartWorkflow, comment:safe_port`) |
| Deal reason | `DEAL_REASON_SL` (broker-driven) | **`DEAL_REASON_EXPERT`** (EA-driven via SafePort) |

ADR-013's filter at `Orchestrator.mqh:847` (`if(reason != DEAL_REASON_EXPERT) return`) correctly skips broker-side closes (Jan-14 class eliminated ✅). But SafePort's batch close is EA-driven so all its closes carry `DEAL_REASON_EXPERT` — they pass the filter and feed CircuitBreaker.RecordClose. When SafePort closes 2+ Slot_H SELL positions in the same tick, CircuitBreaker sees two `magic=205 dir=0 delta=0s` close events → ping_pong false-positive.

**This is exactly the scenario ADR-013 § Alternatives Option C considered and rejected as "more complex than needed":**
> ### Option C — Ticket-deduplication in CircuitBreaker.CheckPingPong
> - **Rejected as more complex than needed.** Would require adding `ulong position_id` to CloseEvent struct + threading through RecordClose API + skipping pairs where `position_id_i != position_id_j`. Achieves same semantic outcome as Option D (this ADR's chosen path) but requires schema change to CloseEvent + larger surface. The DEAL_REASON filter at the producer side is more surgical.

**Run #4 falsifies ADR-013's rejection rationale.** The "more surgical" DEAL_REASON filter handles the broker-driven class but not the EA-mass-close class. Either Option C (ticket-dedup) or a new producer-side filter (skip closes when triggering by xslot mass-close helpers) is now required.

---

## §4 — iter-2 AC results

| AC | Result | Evidence |
|----|--------|----------|
| E-AC #1 — "Run #4 reaches ≥ 3 sim months past Slot_H Jan-14 storm point without `circuit_breaker_pingpong` halt" | ❌ **NOT MET** | Reached Jan-27 (13 sim days < 90 sim days target); ping_pong halt at 2021-01-27 15:45:07 |
| E-AC #2 — "If Run #4 reaches sim 2025-12-31: drift ≤ 25%" | ❌ **N/A** | Didn't reach 2025-12-31 trigger condition; drift ≈ 100% at halt_stable |
| Cap-3 budget status | **iter-2 ❌**; iter-3 conditional unlocks per §5 below | |

ACs stay `[ ]` in impl-plan.md. Deferred-AC P4 IMPL-FIX-012 stays Active (expiry 2026-05-28; 11 days slack). IMPL-062 E-AC #1+#2 stay deferred (paired bundle blocked).

---

## §5 — iter-3 fix scope (next /impl-task session)

**Two implementation candidates** (cost/benefit analysis pending engineer decision at iter-3 entry):

**Option α (preferred — producer-side filter extension):**
- Patch `core/Orchestrator.mqh::OnTradeTransaction` to also skip closes whose `triggering_function` (from request context) ∈ {`OrderGroupStartWorkflow`, `OrderGroupStartWorkflow2`, `ForceCutloss`, `ExtraCheckFunction2`, `SafePort`} — the xslot mass-close helpers
- Requires propagating triggering_function from RiskManager.CloseOrder caller → CTrade → into OnTradeTransaction's deal lookup, OR caching the most-recent xslot-mass-close timestamp in CrossSlotCoordinator and consulting it in OnTradeTransaction
- ~10-30 LOC; ADR-013 amendment (no new ADR — same decision class)

**Option β (Option-C from original ADR-013 alternatives):**
- Extend `CCloseEvent` struct in `services/CircuitBreaker.mqh` with `ulong position_id`
- Plumb position_id through `RecordClose(ulong position_id, ulong magic, int dir, datetime ts)`
- In `CheckPingPong()`, skip pairs where `position_id_i != position_id_j`
- ~30-50 LOC + schema change to CloseEvent; new ADR-014 (semantic delta vs ADR-013)

Option α is more surgical (no internal schema change) but requires plumbing triggering_function from a call site that may not always know it. Option β is bigger but architecturally cleaner — position_id is the true "is this same position being repeatedly closed" signal.

**Recommendation deferred to iter-3 entry**: engineer reads `services/CrossSlotCoordinator.mqh::RunSafePort` + adjacent helpers, decides whether triggering_function propagation is feasible (Option α) or whether position_id plumbing is cleaner (Option β).

**Beyond iter-3:** If iter-3 fix also surfaces a third false-positive class → cap-3 escalation gate: `/impl-plan-review all` (re-decompose IMPL-FIX-012 into multi-task chain) OR `/backtrack sd` (revisit BR-3.6 CircuitBreaker spec).

---

## §6 — State preservation

- **NO AC flipped `[x]`** — E-AC #1 explicitly NOT MET; E-AC #2 N/A; both stay `[ ]`
- **NO impl-plan.md AC mutation this artifact** — Status block update applied as focused edit (iter-1 closure block superseded by iter-2 outcome narrative; no S-AC text edits)
- **NO Plan Staleness Sentinel increment** — FIX-ticket sub-iter per `workflow.md § Phase 5 Gate #4` + fix-round-10 precedent
- **NO commit drafted** — user not yet authorized commit on this finding
- **State Reconciliation 3-file rule honored:** this evidence sidecar + impl-plan.md Status block update + overview.md mention pending operator authorization

---

## §7 — Evidence artifacts (this session)

| Artifact | Path | Size |
|----------|------|------|
| Run #4 journal (verbatim) | `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-20260517.jsonl` | 127 records / 82 KB |
| Run #4 abridged Tester log | `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-20260517-tester-abridged.txt` | 89 lines (halt events + sim-time samples + final 20 lines) |
| THIS narrative | `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-blocked-20260517.md` | (note: filename kept for git-history continuity from initial mis-diagnosis; content now reflects Run #4 actual outcome — "blocked" is no longer accurate but renaming would break audit trail of OPS-001 → OPS-002 chain) |
| Run #4 full Tester log (88 MB raw UTF-16LE) | `/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Tester/A12EC900AF5AF5023ECB36F7FB72E396/Agent-127.0.0.1-3000/logs/20260517.log` | 88 MB (NOT committed per `.claude/rules/ea.md` "do NOT commit Tester logs") |

---

## §8 — Cross-references

- `impl-plan.md § IMPL-FIX-012` — Status updated this session with iter-2 outcome
- `deferred-ac-registry.md` P4 IMPL-FIX-012 row — stays Active (expiry 2026-05-28; iter-3 will close)
- `deferred-ac-registry.md` P4 IMPL-062 row — stays Active (same expiry; cascade-blocked on iter-3)
- `operator-action-registry.md` OPS-002 — moved to Done (operator ran GUI backtest at 20:29-20:32 refreshed cache; subsequent headless launch succeeded)
- `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md § Alternatives § Option C` — empirically falsified rejection rationale; iter-3 will amend OR author ADR-014
- `_session-handoff/IMPL-FIX-012-slot-H-clustering-diagnostic-20260514.md` — iter-1 Step 0 narrative (preserved for audit)
- Open Risk R-3 — updated this session to reflect iter-2 finding + iter-3 scope
- Open Risk R-13 — Slot_H long-tail class refined: now bifurcated into (a) Jan-14 broker-driven SL ✅ resolved by ADR-013 + (b) Jan-27 EA-driven mass-close ❌ pending iter-3

---

**End of artifact.**
