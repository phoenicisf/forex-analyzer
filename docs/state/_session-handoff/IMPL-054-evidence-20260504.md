# IMPL-054 Evidence — `services/CrossSlotCoordinator::RunOrderGroup2()` (BR-8.2)

**Closed:** 2026-05-04
**Engineer:** Kritsana (orchestrator: Opus 4.7 — single-task `/impl-task IMPL-054` Phase 2B 3-step; fall-back from `/impl-task parallel` per "no parallel candidates" scan — same-file `services/CrossSlotCoordinator.mqh` scope blocks parallel fan-out for IMPL-054/057/058 chain)
**Phase:** P4 — Integration (under Phase Gate Override 2026-05-03 Path A)
**Commit:** `2907e4a`

---

## §1. Files Modified

| Path | Change |
|------|--------|
| `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` | Replaced `RunOrderGroup2` TODO stub with full body; added `_OrderGroup2Triggered(bool, int) const` predicate + `ORDER_GROUP_2_WEAK_ORDER_MIN` define; refactored `_CloseSlotGroup` signature to take `(magic, prefix, triggering_function, comment_tag)` so SafePort + OrderGroup2 share the bulk-close primitive (DRY, 2 callers); extended SelfTest 19 → 25 cases (added C20-C25); updated header banner to credit IMPL-054 sub-pass + document refactor scope |
| `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` | Header banner updated to reflect 25-case SelfTest count + IMPL-054 sub-pass credit |
| `simulation/headless-tests/cross_slot_order_group_2.ini` | NEW — smoke fixture per TD-02 §13.6; activation deferred to IMPL-059+ |

No new spike harness file (re-uses existing `Spike_CrossSlotCoordinator.mq5` — SelfTest is the same entrypoint, now 25 cases).

## §2. G1 Compile Evidence

```
=== Spike_CrossSlotCoordinator (MetaEditor64 /compile /log) ===
Result: 0 errors, 0 warnings, 569 ms elapsed, cpu='X64 Regular'
```

Per `mt5-log-reader § Wine` exit code is unreliable; `Result:` line authoritative. Faster than IMPL-053/055/056 prior runs (838 ms → 569 ms) — incremental cache hit (no new headers introduced; refactor only).

## §3. SelfTest Coverage (25 cases — IMPL-053/055/056 carry-forward + IMPL-054 added)

| # | Case | Assertion | Source |
|---|------|-----------|--------|
| C1-C7 | RunSafePort skeleton + trigger truth-table + target table | (see IMPL-053 evidence) | IMPL-053 |
| C8-C13 | RunForceCutloss signal truth-table + safe-guards | (see IMPL-055 evidence) | IMPL-055 |
| C14-C19 | ExtraCheckFunction2 demote predicate truth-table + NULL guard | (see IMPL-056 evidence) | IMPL-056 |
| **C20** | _OrderGroup2Triggered ichi=false, weak=0 | → false | **IMPL-054** |
| **C21** | _OrderGroup2Triggered ichi=true, weak=2 (boundary) | → false (gate is strict `> 2`) | **IMPL-054** |
| **C22** | _OrderGroup2Triggered ichi=true, weak=3 (first qualifying) | → true | **IMPL-054** |
| **C23** | _OrderGroup2Triggered ichi=true, weak=10 (well above) | → true | **IMPL-054** |
| **C24** | _OrderGroup2Triggered ichi=false, weak=10 (no ichi) | → false (ichi flag dominates) | **IMPL-054** |
| **C25** | RunOrderGroup2 with NULL portfolio + ichi=true | invocation does not crash (defensive guard) | **IMPL-054** |

Truth-table coverage of BR-8.2 OrderGroupStartWorkflow2 trigger predicate (`ichi_double_bounce_active AND weak_count > 2`):
- Empty (C20) → false (ichi off + zero weak)
- Boundary (C21) → false (ichi on but weak == threshold; gate is strict `>`)
- Trigger min (C22) → true (ichi on + weak just above threshold)
- Trigger high (C23) → true (ichi on + weak well above)
- No-ichi (C24) → false (high weak count alone insufficient — ichi flag dominates)
- Defensive (C25) → no crash (early-return on NULL portfolio guard)

## §4. S-AC Closure (3/3 [x])

| # | S-AC text | Closure evidence |
|---|-----------|------------------|
| 1 | Method `RunOrderGroup2()` implemented per BR-8.2 / FR-7.2 | `services/CrossSlotCoordinator.mqh::RunOrderGroup2` full body: NULL guards on `m_portfolio` + `m_logger`; quick-out on `ctx.derived.ichi_double_bounce_active == false`; `_AggregateWeakMetrics` derives `weak_count`; `_OrderGroup2Triggered(ichi_active, weak_count)` AND-gate; `_FillSafePortTargets` populates 11-entry shared target table; per-pair `_CloseSlotGroup(magic, prefix, "OrderGroupStartWorkflow2", "order_group_2")` issues per-ticket CTrade.PositionClose + journal `triggering_function="OrderGroupStartWorkflow2"` (schema enum allowed `trade-journal-schema.yaml:179`); Logger Info `[ev=order_group_2_triggered]` for forensic audit. |
| 2 | Trigger gated on `MarketContext.derived.ichi_double_bounce_active == true` (per ADR-004 derived signal) | RunOrderGroup2 body line 1: `bool ichi_active = ctx.derived.ichi_double_bounce_active; if(!ichi_active) return;` — quick-out matches the spec's primary gate. `_OrderGroup2Triggered` re-asserts the flag inside the AND-gate predicate (defensive double-check, also testable in isolation). MarketContext consumed via `const MarketContext &ctx` per ADR-004 immutability. |
| 3 | Compile clean | Spike_CrossSlotCoordinator G1 0 errors, 0 warnings, 569 ms (MetaEditor64 /compile /log post-edit). |

## §5. E-AC Status (1 deferred / 0 resolved)

| # | E-AC text | Status |
|---|-----------|--------|
| 1 | Smoke: stub MarketContext with Ichimoku double-bounce flag set → close-all triggered + journal `[ev=order_group_2_triggered]` `[log-assertion]` + `[db-inspect]` | **Deferred** — `[log-assertion]` part requires running EA via Strategy Tester to capture Logger Print output (block on IMPL-059+ Orchestrator wiring + IMPL-060 entry .mq5 + 3-position synthetic fixture in target slot set + real `derived.ichi_double_bounce_active=true` signal). `[db-inspect]` part requires per-ticket exit journal records to land in `journal/tester/run-*.jsonl` with `triggering_function="OrderGroupStartWorkflow2"` (schema enum allowed). **Compound prerequisite:** `ComputeIchiDoubleBounce` is currently PLACEHOLDER returning `false` per `MarketContextBuilder.mqh:577` (TODO IMPL-FUTURE — needs H4 history scan ≥50 bars beyond ADR-004 single-tick snapshot). Smoke fixture committed at `simulation/headless-tests/cross_slot_order_group_2.ini`. Registered in `deferred-ac-registry.md § Active` row IMPL-054 expiry 2026-05-18. |

> **Scope note:** IMPL-054 is M — it implements the trigger predicate + bulk-close + Logger trigger event + journal records (full RunOrderGroup2). The Ichi-bounce derived signal computation refinement (currently PLACEHOLDER false) is owned by MarketContextBuilder (P3+ slot integration). Pattern matches IMPL-053 (RunSafePort body shipped but smoke deferred to runnable surface) and IMPL-055/056 (CD-pair safety triplet shipped but smoke deferred). **Refactor note:** `_CloseSlotGroup` signature changed from `(magic, prefix)` to `(magic, prefix, triggering_function, comment_tag)` — only callers were `RunSafePort` (now passes `"OrderGroupStartWorkflow", "safe_port"`) and the new `RunOrderGroup2` (passes `"OrderGroupStartWorkflow2", "order_group_2"`); CTrade fail-log tag template also generalized (`"safe_port_close_fail"` → `comment_tag + "_close_fail"`).

## §6. HALTED Matrix Compliance (`04 § 9.1` / ADR-010)

| Method | Implementation guard | Notes |
|--------|----------------------|-------|
| `RunOrderGroup2` | None — runs in BOTH RUNNING+HALTED | Logger Info reports `halted=true/false` for forensic visibility. Mirrors RunSafePort semantics (exit-side bulk-close helper); HALTED-allowed per TD-02 §5.11 enable matrix table row 2 ✅✅. |

TD-02 §5.11 enable matrix table row 2: ✅ RUNNING + ✅ HALTED. Implementation matches.

## §7. Spec Compliance Notes

- **Return type:** `void RunOrderGroup2(const MarketContext&)` — matches TD-02 §5.11 skeleton verbatim. **No spec deviation** (unlike IMPL-053 which returned `int slots_closed_count` per Plan-text override). Logger event includes `slots_closed=N` for observability without changing the public contract.
- **Journal enum:** `triggering_function="OrderGroupStartWorkflow2"` matches `trade-journal-schema.yaml § triggering_function` enum line 179 verbatim.
- **Shared bulk-close primitive:** `_CloseSlotGroup` refactor justified by 2 real call sites (SafePort + OrderGroup2) — not premature abstraction. Both helpers walk the same 11-entry target table; only the gate predicate + journal label differ. Adheres to ea.md "Minimal changes" + "No over-engineering" principles.
- **Naming consistency:** `_OrderGroup2Triggered` mirrors `_SafePortTriggered` naming (`_<Helper>Triggered`); `m_*`/`_camelCase` per ea.md naming conventions.

## §8. Newly Unblocked

- **IMPL-057** (M overload helpers BR-8.4 EOverload/COverload/GOverload) — depends on IMPL-058 wire-up (sequential same-file scope)
- **IMPL-058** (S HALTED enable matrix wire-up) — depends on IMPL-053..057 chain complete (IMPL-053/054/055/056 ✅; pending IMPL-057)

**Bulk-close quartet (IMPL-053 SafePort + IMPL-055 ForceCutloss + IMPL-056 ExtraCheckFunction2 + IMPL-054 OrderGroup2) now complete at coordinator level.** Cross-slot business-logic surface fully landed; remaining P4 chain = overload helpers + HALTED matrix wire-up + Orchestrator + entry .mq5 + QA verification.

## §9. Phase Status Snapshot

P4 3/11 → **4/11**. Mid-Phase Audit P4 counter = 4 (threshold 5 not crossed; next closure will trigger Phase 4 audit). Plan Staleness Sentinel = 7 closures since R06 (still below 10-closure threshold).

## §10. Next Suggested Task

`/impl-task IMPL-057` (M overload helpers BR-8.4 EOverload/COverload/GOverload — last business-logic method on `CrossSlotCoordinator.mqh`; HALTED guard already in place for E + G via stubs ⚠️ but C exit-side allowed in HALTED) — note IMPL-057 deps include IMPL-058 per impl-plan, so order is IMPL-058 first if reading deps strictly. Pragmatic order: **IMPL-058** (S, simple wire-up — `m_halted` field + setter already exist; just per-method enable gate documentation) THEN IMPL-057 (M, business logic on top of stable enable matrix). After IMPL-057+058 → IMPL-059 (L Orchestrator) + IMPL-060 (S entry .mq5) → empirical surface unblocked for P2/P3/P4 Phase Gates + 36+ deferred-AC rows expiring 2026-05-17/18.

## §11. Mid-Phase Audit Trigger Warning

Counter at P4 = 4. **Next closure (IMPL-057 or IMPL-058) will trip the 5-task threshold** → Phase 4 Mid-Phase Empirical Audit will trigger before any P4 task IMPL-059+ can start. Audit procedure (per impl-task workflow §4.2): cold bootstrap + smoke chain + replay E-AC artifacts for IMPL-053/054/055/056. **Caveat:** all 4 P4 closures have header-only E-AC deferrals registered (no live Tester runs yet); audit artifact replay will be limited to SelfTest re-run + structural inspection until IMPL-059+ runnable surface lands. Recommend documenting this constraint in audit log when triggered.
