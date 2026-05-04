# IMPL-056 Evidence — `services/CrossSlotCoordinator::ExtraCheckFunction2()` (BR-8.5)

**Closed:** 2026-05-04
**Engineer:** Kritsana (orchestrator: Opus 4.7 — single-task `/impl-task IMPL-056` Phase 2A single-prompt)
**Phase:** P4 — Integration (under Phase Gate Override 2026-05-03 Path A)

---

## §1. Files Modified

| Path | Change |
|------|--------|
| `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` | Replaced `ExtraCheckFunction2` TODO stub with full body + 1 private helper (`_IsCDDemoteCondition`); extended SelfTest 13 → 19 cases (added C14-C19); updated header banner to credit IMPL-056 sub-pass |
| `simulation/headless-tests/cross_slot_extra_check.ini` | NEW — smoke fixture per TD-02 §13.6; activation deferred to IMPL-059+ |

No new source files (re-uses existing `Spike_CrossSlotCoordinator.mq5` harness — SelfTest is the same entrypoint).

## §2. G1 Compile Evidence

```
=== Spike_CrossSlotCoordinator (MetaEditor64 /compile /log) ===
Result: 0 errors, 0 warnings, 838 ms elapsed, cpu='X64 Regular'
```

Per `mt5-log-reader § Wine` exit code is unreliable; `Result:` line authoritative.

## §3. SelfTest Coverage (19 cases — IMPL-053/055 carry-forward + IMPL-056 added)

| # | Case | Assertion | Source |
|---|------|-----------|--------|
| C1-C7 | RunSafePort skeleton + trigger truth-table + target table | (see IMPL-053 evidence) | IMPL-053 |
| C8-C13 | RunForceCutloss signal truth-table + safe-guards | (see IMPL-055 evidence) | IMPL-055 |
| **C14** | _IsCDDemoteCondition empty pool | (0, 0) → false | **IMPL-056** |
| **C15** | _IsCDDemoteCondition single BUY | (1, 0) → true | **IMPL-056** |
| **C16** | _IsCDDemoteCondition single SELL | (0, 1) → true | **IMPL-056** |
| **C17** | _IsCDDemoteCondition paired | (1, 1) → false (CD count==2 → BR-8.5 not triggered) | **IMPL-056** |
| **C18** | _IsCDDemoteCondition over-stacked | (2, 0) → false | **IMPL-056** |
| **C19** | ExtraCheckFunction2 NULL portfolio | invocation does not crash (defensive guard) | **IMPL-056** |

Truth-table coverage of BR-8.5 demote predicate (`buy_count + sell_count == 1`):
- Empty (C14) → false (no positions to demote against)
- Single BUY (C15) → true (matches "one CD position open, unpaired")
- Single SELL (C16) → true (symmetric to BUY)
- Paired (C17) → false (CD count==2 — paired CD is the normal force-mode active state)
- Over-stacked (C18) → false (3+ positions imply multi-cycle activity, not demote condition)
- Defensive (C19) → no crash (early-return on NULL portfolio guard)

## §4. S-AC Closure (3/3 [x])

| # | S-AC text | Closure evidence |
|---|-----------|------------------|
| 1 | Method `ExtraCheckFunction2()` implemented per BR-8.5 / FR-7.4 | `services/CrossSlotCoordinator.mqh::ExtraCheckFunction2` full body: NULL guards on m_portfolio + m_logger; `m_portfolio.GetByMagic(MAGIC_CD)` returns SlotState* (CD pool aggregate per ADR-005); `_IsCDDemoteCondition(buy, sell)` checks count==1 predicate; on trigger emits `Logger.Info("xslot","cd_demote_triggered",MAGIC_CD,"cd_count=1 buy=N sell=N halted=...")` for forensic audit. |
| 2 | Demote-check predicate evaluated against CD pool state per CodeWiki §5 | `_IsCDDemoteCondition(int buy_count, int sell_count) const` returns `(buy_count + sell_count) == 1`; matches CodeWiki §5.5 :157 "demote ExtraForceModeReason if CD count==1" + BA `04 § BR-8.5` "Condition: portfolio[MagicCD].count == 1". Predicate isolated as pure function for SelfTest exercise without portfolio fixture (matches `_SafePortTriggered` IMPL-053 isolation pattern). |
| 3 | Compile clean | Spike_CrossSlotCoordinator G1 0 errors, 0 warnings, 838 ms (MetaEditor64 /compile /log post-edit). |

## §5. E-AC Status (1 deferred / 0 resolved)

| # | E-AC text | Status |
|---|-----------|--------|
| 1 | Smoke: stub CD pool with demote condition → check returns true + journal `[ev=cd_demote_triggered]` `[log-assertion]` + `[db-inspect]` | **Deferred** — `[log-assertion]` part requires running EA via Strategy Tester to capture Logger Print output (block on IMPL-059+ Orchestrator wiring + IMPL-060 entry .mq5 + 1-CD-position synthetic fixture); `[db-inspect]` part requires wiring `cross_slot_state.extra_force_mode_reason` field mutation (state-persistence-schema.yaml § cross_slot_state line 119-121) which is owned by IMPL-047 StatePersistence + IMPL-059 Orchestrator (CrossSlotCoordinator currently lacks CrossSlotState reference; injection deferred per XS scope). Smoke fixture committed at `simulation/headless-tests/cross_slot_extra_check.ini`. Will register row in `deferred-ac-registry.md § Active` row IMPL-056 expiry 2026-05-18. |

> **Scope note:** IMPL-056 is XS — it implements the predicate + Logger trigger event only. The actual `extra_force_mode_reason` integer field mutation is a separate concern owned downstream (IMPL-047 schema-load + IMPL-059 Orchestrator state-write). Per impl-plan IMPL-056 description ("Demote-check predicate evaluated against CD pool state") and BA `04 § BR-8.5` Action ("Demote ExtraForceModeReason"), this XS sub-pass establishes the **trigger detection + audit emission**; downstream Orchestrator wires the **state mutation**. Pattern matches IMPL-053 (RunSafePort emits log + journal but cross_slot_state ichi_double_bounce_buffer not yet wired) and IMPL-055 (ForceCutloss closes positions but no cross_slot_state field involvement at all).

## §6. HALTED Matrix Compliance (`04 § 9.1` / ADR-010)

| Method | Implementation guard | Notes |
|--------|----------------------|-------|
| `ExtraCheckFunction2` | None — runs in BOTH RUNNING+HALTED | Logger Info reports `halted=true/false` for forensic visibility. No order activity (pure state-trigger event); HALTED-allowed semantics trivially satisfied. |

TD-02 §5.11 enable matrix table row 4: ✅ RUNNING + ✅ HALTED. Implementation matches.

## §7. Newly Unblocked

- **IMPL-054** (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce) — last remaining sibling cross-slot method on `CrossSlotCoordinator.mqh` (independent of IMPL-055/056; deps IMPL-019..039 already satisfied)
- **IMPL-057** (M overload helpers BR-8.4 EOverload/COverload/GOverload) — depends on IMPL-058 wire-up
- **IMPL-058** (S HALTED enable matrix wire-up) — depends on IMPL-053..057 chain complete (IMPL-053/055/056 ✅; pending IMPL-054 + IMPL-057)

CD-pair safety triplet (IMPL-053 SafePort + IMPL-055 ForceCutloss + IMPL-056 ExtraCheckFunction2) now complete at coordinator level.

## §8. Phase Status Snapshot

P4 2/11 → **3/11**. Mid-Phase Audit P4 counter = 3 (threshold 5 not crossed). Plan Staleness Sentinel = 6 closures since R06 (still below 10-closure threshold).

## §9. Next Suggested Task

`/impl-task IMPL-054` (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce — last sibling on CrossSlotCoordinator.mqh) **OR** `/impl-task IMPL-057` after IMPL-058 prereq satisfied. Per Open Risk R-6 mitigation, prioritize IMPL-053..058 chain to unblock 36+ deferred-AC rows expiring 2026-05-17/18.
