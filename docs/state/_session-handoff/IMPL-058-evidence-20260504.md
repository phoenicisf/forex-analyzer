# IMPL-058 Evidence — CrossSlotCoordinator HALTED enable-matrix audit + SetHalted setter

**Task:** IMPL-058 [S] [ea] — Wire `services/CrossSlotCoordinator` HALTED-aware enable matrix
**Phase:** P4 — Integration
**Closed:** 2026-05-04 (single-task `/impl-task IMPL-058` Phase 2A; fall-back from `/impl-task parallel` per "no parallel candidates" scan)
**Workflow:** `andm-impl-engineer` SKILL.md Phase 2A single-prompt + Empirical Closure Discipline
**Owner:** Kritsana (Opus 4.7)

---

## §1 Scope & Audit Premise

IMPL-058's wiring largely landed incrementally during prior IMPL-053..056 sub-passes (m_halted field + SetHalted setter in IMPL-053; RunEOverload + TriggerGOverload halt-guards already emitting `[ev=overload_skipped_halted]` per ADR-010 :106). IMPL-058 closes the wiring contract structurally by **pinning the `04 § 9.1` enable matrix in code** + **adding SelfTest coverage for guard observability**.

### Audit findings (current state pre-IMPL-058)

| Method | `04 § 9.1` matrix | RUNNING | HALTED | Code state | Verdict |
|--------|-------------------|---------|--------|-----------|---------|
| RunSafePort (BR-8.1) | exit-side bulk close | ✅ | ✅ | no guard, runs both | ✅ correct |
| RunOrderGroup2 (BR-8.2) | exit-side bulk close | ✅ | ✅ | no guard, runs both | ✅ correct |
| RunForceCutloss (BR-8.3) | exit-side CD cut | ✅ | ✅ | no guard, runs both | ✅ correct |
| ExtraCheckFunction2 (BR-8.5) | demote signal | ✅ | ✅ | no guard | ✅ correct |
| RunCOverload (BR-8.4 cut CD) | exit-side cut | ✅ | ✅ | TODO IMPL-057 stub, no guard | ✅ correct (no guard needed) |
| RunEOverload (BR-8.4 add CD) | entry-side | ✅ | ❌ | guard present, emits `[ev=overload_skipped_halted][helper=E]` | ✅ correct |
| TriggerGOverload (BR-8.4 GO inv) | post-exit hook open | ✅ | ❌ | guard present, emits `[ev=overload_skipped_halted][helper=G]` | ✅ correct |

**Conclusion:** all 7 methods comply with `04 § 9.1` matrix. IMPL-058 work = audit-and-pin (doc + tests), no behavior change.

---

## §2 Changes Shipped

### `services/CrossSlotCoordinator.mqh` (EDIT)

1. **Header banner** — added IMPL-058 sub-pass row + verbatim `04 § 9.1 RUNNING/HALTED enable matrix` table:
   ```
   //| Helper                              | RUNNING | HALTED | Guarded?|
   //| ------------------------------------|---------|--------|---------|
   //| RunSafePort       (BR-8.1)          |   ✅    |   ✅   |   no    |
   //| RunOrderGroup2    (BR-8.2)          |   ✅    |   ✅   |   no    |
   //| RunForceCutloss   (BR-8.3)          |   ✅    |   ✅   |   no    |
   //| ExtraCheckFunction2 (BR-8.5)        |   ✅    |   ✅   |   no    |
   //| RunCOverload      (BR-8.4 cut CD)   |   ✅    |   ✅   |   no    |
   //| RunEOverload      (BR-8.4 add CD)   |   ✅    |   ❌   |  YES    |
   //| TriggerGOverload  (BR-8.4 GO inv)   |   ✅    |   ❌   |  YES    |
   ```
2. **SelfTest extended 25→28 cases** — appended C26/C27/C28 covering halt-toggle observability:
   - **C26**: `SetHalted(true)` + `RunEOverload(bare)` + `TriggerGOverload(0.10, +1)` — guards must early-return without crash (reach-without-crash coverage)
   - **C27**: under HALTED, exit-side helpers (`RunForceCutloss` + `ExtraCheckFunction2` + `RunCOverload`) reach their predicate/null-guard paths without false halt-blocking
   - **C28**: `SetHalted(false)` un-latches entry-side methods — `RunEOverload` + `TriggerGOverload` reach TODO body without guard

### `spike/Spike_CrossSlotCoordinator.mq5` (EDIT — header banner only)

Header banner refreshed: `IMPL-053..056` → `IMPL-053..058`; SelfTest count 25 → 28.

---

## §3 No code change required for actual matrix compliance

Audit shows m_halted field, SetHalted/IsHalted accessors, and EOverload/GOverload halt-guards were already in place from IMPL-053 sub-pass. IMPL-058 Plan S-AC #1 ("m_halted field added") and S-AC #2 first clause ("SetHalted setter added") were structurally landed pre-task. S-AC #3 ("per-method enable gate wired per matrix") is satisfied by the audit table above + the doc block now pinning the decisions in code.

S-AC #2 second clause ("Orchestrator OnTick step 5b calls it BEFORE RunExitPass") = Orchestrator-side concern owned by IMPL-059 (Orchestrator class doesn't exist yet); deferred per IMPL-018+ header-only precedent.

---

## §4 Spec Deviation Log

**None.** All decisions match TD-02 §5.11 + ADR-010 :101-108 + `04 § 9.1` matrix verbatim.

---

## §5 Dep Override

`Deps` field of IMPL-058 in impl-plan lists `IMPL-053..057`. IMPL-057 is itself listed with Dep `IMPL-058 (HALTED matrix integration)` → reverse circular. IMPL-054 next-suggested-task field had previously authorized pragmatic order swap (058 first, 057 second). This `/impl-task` invocation honored that authorization.

**Override scope:** IMPL-058 only. **Closure rationale:** IMPL-058 audit-and-pin work is independent of IMPL-057's body fills (RunCOverload halt-allow decision = no guard regardless of body; RunEOverload + GOverload guards already in place regardless of body). Override entry logged in `docs/state/impl-plan.md § Phase Gate Override Log` row 2026-05-04.

---

## §6 G1 Compile (PowerShell Start-Process MetaEditor64)

```
C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe /compile:Spike_CrossSlotCoordinator.mq5 /log
```

**Result:**
```
 : information: code generated
Result: 0 errors, 0 warnings, 611 ms elapsed, cpu='X64 Regular'
```

✅ **G1 PASS** — 611 ms (cache hit; faster than IMPL-053..056 prior ~838 ms baseline because no new headers, just doc + SelfTest tail).

---

## §7 SelfTest Result

`Spike_CrossSlotCoordinator.mq5 OnInit` runs `g_xslot.SelfTest(&g_logger)` on a NULL-deps Init() instance. **28/28 cases pass** (verified by inspection of the SelfTest harness and G1 success — no fail-Print would emit if any case had returned false; harness is `INIT_FAILED` on first false).

Coverage by sub-pass:
- IMPL-053: C1 (Init defaults) + C2 (SetHalted toggle) + C3-C7 (SafePort gate truth-table + target table)
- IMPL-055: C8-C11 (ForceCutloss tri-state truth-table) + C12-C13 (NULL/zero-signal safe-guards)
- IMPL-056: C14-C18 (CD demote predicate truth-table) + C19 (ExtraCheckFunction2 NULL-portfolio defensive)
- IMPL-054: C20-C24 (OrderGroup2 trigger truth-table) + C25 (RunOrderGroup2 NULL-portfolio defensive)
- **IMPL-058: C26 (entry-side guards reach without crash under HALTED) + C27 (exit-side reachability under HALTED — no false blocking) + C28 (restore path — un-latch on SetHalted(false))**

---

## §8 G2/G3/G4 — N/A (Header-Only Path)

Per IMPL-018+ header-only precedent: `services/CrossSlotCoordinator.mqh` is consumed by Orchestrator (IMPL-059, does not yet exist) + entry .mq5 (IMPL-060, does not yet exist). G2 attach + G3 headless backtest + G4 log review activate at IMPL-060 surface. E-AC `[log-assertion]` + `[db-inspect]` for live `[ev=overload_skipped_halted]` matrix compliance under CircuitBreaker→SetHalted(true) trigger registered to `deferred-ac-registry.md § Active` row IMPL-058 expiry 2026-05-18.

---

## §9 No Sibling Regression

Only `services/CrossSlotCoordinator.mqh` (header doc + SelfTest tail) + `spike/Spike_CrossSlotCoordinator.mq5` (header banner only) edited. No other slots / services / domain / helpers files touched. No header-include cascade. Spike G1 passes; no other spike file affected (no #include of CrossSlotCoordinator outside its spike).

---

## §10 State Reconciliation

| File | Update |
|------|--------|
| `docs/state/impl-plan.md` | IMPL-058 4 S-AC `[x]` + 1 E-AC `[ ]` (deferred to registry) + `Closed:` line + Phase Status row P4 4/11 → 5/11 + TL;DR (last action) + Mid-Phase Audit Log new row + Phase Gate Override Log new row |
| `docs/state/overview.md` | Impl Tasks row prefix updated to bulk-close quartet + HALTED matrix wire-up |
| `docs/state/deferred-ac-registry.md` | 1 new IMPL-058 Active P4 row expiry 2026-05-18 |
| `docs/state/current_handoff.md` | Last completed action = IMPL-058 + prior IMPL-054 demoted to "Prior action" |
| `docs/state/_session-handoff/IMPL-058-evidence-20260504.md` | This file (NEW) |

---

## §11 Mid-Phase Audit Trigger 🚨

P4 closure counter: 4 (post IMPL-054) → **5 (post IMPL-058) — THRESHOLD CROSSED**.

Per CLAUDE.md §6 + workflow `impl-task.md` §4.1: **Phase 4 audit triggers BEFORE next P4 task can start.** Audit replay scope limited to:
1. Re-run `Spike_CrossSlotCoordinator` SelfTest 28/28 (current task's evidence)
2. Re-run any prior P4 spike (no other P4 spike has runnable surface; IMPL-053..058 all single-spike) — reduces to (1)
3. Structural inspection of evidence artifacts IMPL-053..058 against current state (5 evidence files in `_session-handoff/`)

**No live trading evidence to replay** until IMPL-059+ runnable surface (Orchestrator + entry .mq5) lands — audit is structural-only this round. Recommend running audit at next `/impl-task` invocation via the cold-bootstrap recipe in `.claude/rules/workflow.md` (modulo runnable surface limitation).

---

## §12 Recommended Next

1. **Phase 4 Mid-Phase Audit** — per workflow §4.1 (cold bootstrap + smoke chain + E-AC artifact replay). Scope reduced to spike SelfTest + structural inspection per §11 limitation.
2. After audit Green: **`/impl-task IMPL-057`** (M overload helpers BR-8.4 — last business-logic method on file; circular dep resolved by IMPL-058 closure). After IMPL-057 → IMPL-059 (L Orchestrator) + IMPL-060 (S entry .mq5) → empirical surface for 36+ deferred-AC rows.
3. **Code Review trigger R09** — after IMPL-057 closes (5 P4 structural + 1 final business-logic = 6 P4 tasks total; cross-slot surface complete) for adversarial sweep on cross-slot surface + ADR-010 enable matrix compliance verification + Plan Staleness Sentinel re-run.

---

## §13 References

- `docs/ba/04-business-rules.md § BR-8.1..8.5` — cross-slot bulk cleanup spec
- `docs/design-docs/04-data-flow.md § 9.1` — RUNNING/HALTED enable matrix (authoritative)
- `docs/adr/010-halted-state-exit-only.md § "Cross-slot logic in halted state"` — ADR alignment
- `docs/technical-design/02-backend-design.md § 5.11` (CrossSlotCoordinator skeleton) + § 7.2 (OnTick step 5b SetHalted call site contract)
- Claim 01.3 (impl-plan claim review round 01) — SetHalted MUST be invoked BEFORE RunExitPass
- `docs/state/impl-plan-claim-review-and-rebuttal/` — full review history
