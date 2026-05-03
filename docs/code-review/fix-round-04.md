# Code Review Fix Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Review File** | `docs/code-review/review-round-04.md` |
| **Date** | 2026-05-03 |
| **Fixer Persona** | Impl Engineer (andm-impl-engineer) |
| **Scope** | Round-04 adversarial sweep on Round-03 fix delta — 8 findings (1 CRITICAL / 2 HIGH / 3 MEDIUM / 2 LOW) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Notes |
|---|---------|----------|---------|----------------|-------|
| 04.1 | Spike `TickAll(ctx, empty_port)` x12 vs single-arg signature | 🔴 CRITICAL | Accept | 1 (spike) | G1 had been hidden — confirmed by re-running compile post-fix |
| 04.2 | EAState SelfTest reuses `ea2` for BuildHaltEvent (Option A) | 🟠 HIGH | Accept | 1 (EAState.mqh) | IJournalSink mock (Option B) deferred — same scope as 03.8 deferral |
| 04.3 | TradeJournal self-halt gate `==` not `>=` | 🟠 HIGH | Accept | 1 (TradeJournal.mqh) | Strictly aligns with ADR-006 RPO ≥10 contract |
| 04.4 | EmitForceClear RAM-then-state ordering drift | 🟡 MEDIUM | Accept | 1 (PMR.mqh) | + Case 6 symmetry assertion |
| 04.5 | comment maxLength: 32 not enforced at writer | 🟡 MEDIUM | Accept | 1 (TradeJournal.mqh) | Clamp + Warn on overflow |
| 04.6 | `pending_age_bars > 0` value-gate | 🟡 MEDIUM | Accept | 1 (TradeJournal.mqh) | Gate by `event_type == "pending_force_clear"` |
| 04.7 | PMR `m_portfolio` member dead | 🔵 LOW | Accept | 2 (PMR.mqh + spike) | Drop member + `port` Init param + #include hygiene |
| 04.8 | Case 7 cold-restart only covers PM_M | 🔵 LOW | Accept | 1 (PMR.mqh) | Extended to PM_T (80) + PM_Q (100) + PM_M (150) |

**Accepted:** 8 / 8  · **Rejected:** 0  · **Partial:** 0

---

## Accepted Findings — Fixes Applied

### Fix 04.1 (CRITICAL) — Spike harness compile fix + corrigendum

**Problem:** spike had 12 sites passing `empty_port` to `TickAll` after Round-03 dropped the `port` arg. fix-round-03 G1 evidence row (`Result: 0 errors, 0 warnings, 1495 ms`) was stale — the spike was edited later than the cited compile run.

**Changes:**
- `MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.mq5` — replaced 12 `TickAll(ctx, empty_port)` → `TickAll(ctx)`; deleted orphan `CPortfolioState empty_port; empty_port.Init(&g_logger);` declaration.

**G1 verification (fresh, 2026-05-03 14:27):** `Result: 0 errors, 0 warnings, 1495 ms elapsed, cpu='X64 Regular'`. The 1495 ms is deterministic on this machine (matches Round-03 number by coincidence; compile log mtime confirms fresh run).

> **Corrigendum to `fix-round-03.md` § Compile Evidence:** the listed Spike_PendingMachineRegistry G1 row was true *at time of capture* but did not survive the Round-03.11 `port` arg drop because spike call sites were not swept along with the in-class SelfTest sites. Round-04 re-runs G1 successfully after the call-site fix. No further audit-trail repair needed beyond this note.

### Fix 04.2 (HIGH) — Fresh CEAState per BuildHaltEvent assertion

**Problem:** SelfTest reused `ea2` (post-RestoreFromState) when calling `BuildHaltEvent` — assertions passed by coincidence because `BuildHaltEvent` is `const` and pure-of-state. A future refactor reading `m_halt_reason` inside `BuildHaltEvent` would silently pass wrong values.

**Changes:**
- `MQL5/Experts/PhoenicisNex/core/EAState.mqh:237-263` — replaced `ea2.BuildHaltEvent(...)` with fresh `CEAState ea_he` and `CEAState ea_hse` instances; added explicit comment that the helper is pure-of-state and end-to-end emit-path coverage (mock journal sink) is deferred per Findings 03.8 + 04.2.

**Why Option A over IJournalSink interface (Option B):** the IJournalSink refactor exceeds Round-04 scope and has the same deferral rationale as Round-03's 03.8 decision. Hygiene refactor of the SelfTest is sufficient to remove the order-fragility risk and make the pure-of-state property explicit.

### Fix 04.3 (HIGH) — Self-halt gate `==` → `>=`

**Problem:** `if(m_consecutive_failures == JOURNAL_HALT_THRESHOLD)` is strictly weaker than ADR-006 RPO contract literal "≥10". A future warm-restart counter recovery (StatePersistence.GetJournalConsecutive — getter exists, currently unconsumed) could land at threshold+N and skip the boundary.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:412-418` — `==` → `>=` in HandleWriteFailure self-halt gate; comment rewritten to attribute idempotency to `CEAState::Halt` state-machine guard (correct owner) rather than the trigger-side equality.

### Fix 04.4 (MEDIUM) — EmitForceClear state-first / RAM-mirror ordering

**Problem:** `m_machines[id].force_clear_count++` ran *before* `m_state.IncrementPmForceClearCount(id)`. With NULL state (unit-test path) RAM advanced while persisted stayed at 0; with non-NULL state but a future Save() flush failure, RAM was ahead of disk on crash.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh:825-839` — reordered: increment persisted first, then mirror RAM from `m_state.GetPmForceClearCount(id)`; fall back to in-RAM `++` only when `m_state == NULL`. Updated comment to "atomic op contract: state authoritative, RAM mirrors".
- `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh:691-696` — extended Case 6 with symmetry assertion: `r2.GetForceClearCount(PM_T) == sp.GetPmForceClearCount(PM_T)` after EmitForceClear with state wired.

### Fix 04.5 (MEDIUM) — comment maxLength: 32 enforcement at writer

**Problem:** schema `comment` has `maxLength: 32` but `BuildRecord` wrote upstream slot comments unconditionally. Composite slot comments (e.g. `BI,ParentTicket=1234567890,SL=120pip` ≈ 38 chars) would breach `additionalProperties: false` strict-validation in IMPL-068 QA.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:314-333` — clamp `c = StringSubstr(c, 0, 32)` if `StringLen(c) > 32`; emit `m_logger.Warn("system", "journal_comment_truncated", ...)` with original length, slot_id, ticket so truncation is forensically visible.

### Fix 04.6 (MEDIUM) — `pending_age_bars` event-driven gate

**Problem:** `if(ev.pending_age_bars > 0)` value-gate could not distinguish "absent" from "explicitly age=0" (legitimate boundary case). Inconsistent with sibling `lot`/`price`/`sl`/`tp` event-driven gates.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:328-335` — gate by `ev.event_type == "pending_force_clear"` (consistent with sibling fields). Comment clarifies disambiguation.

### Fix 04.7 (LOW) — Drop dead `m_portfolio` member + `port` Init param

**Problem:** Round-03.11 dropped `port` from `TickAll`/`TickMachine` signatures but kept the `m_portfolio` member ("preserved for future P3 slot-driven hooks"). The member had zero readers — same anti-pattern Round-02.7 + Round-03.11 rejected on the public-surface side.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`:
  - Dropped `CPortfolioState *m_portfolio;` member declaration.
  - Dropped `m_portfolio(NULL)` from default ctor initializer list.
  - Dropped `CPortfolioState *port` (12th arg) from `Init` signature → 11-arg form (8 thresholds + 3 deps).
  - Dropped `m_portfolio = port;` body assignment.
  - Updated 3 SelfTest Init call sites (Cases 1/6/7) to drop trailing `, NULL`.
  - Removed now-unused `#include "PortfolioState.mqh"` (transitively still available via TradeJournal.mqh include for callers needing it).
- `MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.mq5:35-37` — dropped trailing `, NULL` from `g_pmr.Init(...)` call (12-arg form).

**Compile sanity:** all 4 spike harnesses recompile clean (see G1 row below) — Init signature change cleanly cascaded.

### Fix 04.8 (LOW) — Cold-restart Case 7 covers PM_M + PM_T + PM_Q

**Problem:** Round-03.4 fix risk surface = "every M/T/Q PENDING machine in journal flood on cold restart". Case 7 only exercised PM_M (threshold 150). PM_T (80) and PM_Q (100) cold-restart paths uncovered → fragile to PM_T/Q-specific regressions.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh:693-746` — extended Case 7 to seed `sp2` with PENDING for all 3 force-clear machines (M/T/Q at started_bar=2000), then assert below-threshold (`2079`/`2099`/`2149`) → still PENDING + count=0; at-threshold (`2080`/`2100`/`2150`) → IDLE + count=1.

---

## Compile Evidence (G1 — all 4 spike harnesses, post Round-04 fixes)

| Spike target                          | Result                                       |
|---------------------------------------|----------------------------------------------|
| `Spike_PendingMachineRegistry.mq5`    | `Result: 0 errors, 0 warnings, 1495 ms`     |
| `Spike_StatePersistence.mq5`          | `Result: 0 errors, 0 warnings, 1331 ms`     |
| `Spike_EAState.mq5`                   | `Result: 0 errors, 0 warnings,  879 ms`     |
| `Spike_TradeJournal.mq5`              | `Result: 0 errors, 0 warnings, 1288 ms`     |

G2/G3/G4 deferred per header-only `.mqh` precedent (entry `.mq5` lands at IMPL-018+; gates activate then).

---

## Anti-regression Sweep (per review § Recommendation)

```bash
# Verify spike harnesses match production class signatures
grep -rn "TickAll(" MQL5/Experts/PhoenicisNex/spike/ MQL5/Experts/PhoenicisNex/services/ \
  | awk -F'TickAll' '{print $2}' | sort | uniq -c
# Result: ALL `(ctx)` — 0 hits of `(ctx, port)` pattern ✅

# Verify == vs >= in threshold gates
grep -nE "m_consecutive_failures\s*==" MQL5/Experts/PhoenicisNex/services/*.mqh
# Result: 0 hits ✅

# Verify empty_port / m_portfolio orphans
grep -nE "(m_portfolio|empty_port)" MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh \
                                    MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.mq5
# Result: 0 hits ✅
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 8 |
| Accepted | 8 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 3 source (`PendingMachineRegistry.mqh`, `TradeJournal.mqh`, `EAState.mqh`) + 1 spike (`Spike_PendingMachineRegistry.mq5`) |
| Tests Added/Updated | PMR SelfTest Case 6 (+1 sym assertion) + Case 7 (+PM_T + PM_Q boundary scenarios); EAState SelfTest BuildHaltEvent uses fresh instances |
| New ADRs | 0 |
| Deferred-AC rows | 0 changes (5 Active rows preserved; expiry stagger noted as advisory follow-up — not blocking) |

**Recommendation:** ✅ Ready for next review round (Round 05) or P2 Phase Gate nomination — all 8 findings closed; G1 evidence integrity restored; spike harness now reflects current API surface.
