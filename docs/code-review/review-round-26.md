# Code Review Round 26

| Field | Value |
|-------|-------|
| **Round** | 26 |
| **Target** | `all` — operator invoked `/impl-review all` after IMPL-FIX-012 iter-1 closure (commit `918e7cb`, 2026-05-14 23:55) + IMPL-063 Bucket B cascade closure (commit `6737978`, 2026-05-14 22:40). New review surface since R25 (commit `b46e0c6`): (a) `core/Orchestrator.mqh::OnTradeTransaction` +13 LOC (3-LOC filter + 8-line ADR-013 cite block) at lines 837-847; (b) `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md` NEW (~210 LOC, Status: Accepted); (c) `docs/state/_session-handoff/IMPL-FIX-012-slot-H-clustering-diagnostic-20260514.md` NEW (~280 LOC). Working tree at session start: **clean** (HEAD = `918e7cb`). |
| **Date** | 2026-05-15 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) Verify IMPL-FIX-012 iter-1 patch (ADR-013 DEAL_REASON_EXPERT filter at `core/Orchestrator.mqh:846-847`) — correctness, filter ordering, MQL5 idioms, ADR alignment. (b) Verify ADR-013 §Decision claims are realized in code (Case F SelfTest addition; SelfTest documentation requirement). (c) Re-run Phase 5 Gate #9 termination test (clauses a–i) tree-wide under the documented mechanism per R24 clause (i) — independent verification of R25 "chain terminated" verdict. (d) Verify IMPL-FIX-012 evidence sidecars exist + filenames match closure-note cites. (e) Confirm fix-round-24 §Latent follow-up (mojibake'd § byte sequences in 5 files) propagated to `deferred-ac-registry.md` or `impl-plan.md` task list. (f) Spot-check Code Review dimensions 1-13 for incidental defect surfaces touched by IMPL-FIX-012 + IMPL-063 cascade. |
| **Plan Staleness Sentinel** | 1 IMPL-NNN main task closure since R09 (IMPL-063 fully closed 2026-05-14 via Run #3 cascade); IMPL-FIX-012 iter-1 sub-iter does not increment counter per `workflow.md` Gate #4 + fix-round-10 precedent. Within 10-closure threshold ✅; no staleness advisory triggered. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 2 |
| LOW      | 2 |
| **Total**| **6** |

> **Verdict:** **Fix-round-25 required.** Independent tree-wide re-run of Gate #9 clause (h) under the documented mechanism (extended exemption regex per R24 §24.1) returns **22 surviving hits** (1 mojibake at `BootstrapValidator.mqh:81` carried from R24 + 19 legacy-file cites + **2 rewrite-file path:line cites at `Slot_B.mqh:209` + `Slot_K.mqh:170` citing `Slot_C.mqh:262-289`**). R25 §Termination Test claim "all 9 clauses verify clean tree-wide simultaneously under the documented mechanisms" does NOT reproduce. Separately, ADR-013 §Decision mandates "add Case F to `CCircuitBreaker::SelfTest()`" but Case F is absent from `services/CircuitBreaker.mqh` (Cases A-E only). Both are HIGH findings. Plus 2 MEDIUM (Slot_B/Slot_K text-violations + mojibake follow-up unregistered) + 2 LOW (filename separator drift + Gate #1 hit-count discrepancy).

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No boundary surface change. Symbol whitelist (NFR-5.3) + no-DLL (NFR-7.2) + atomic-write (ADR-007) all unchanged. ADR-013 patch is intra-process filter, no new attack surface. |
| 2 | Business Logic Correctness | ⚠️ Finding | ADR-013 §Decision Case F SelfTest mandate not realized → **Finding 26.2 HIGH**. Filter logic itself at `Orchestrator.mqh:846-847` is correct (DEAL_REASON_EXPERT skip; ordering after own-symbol/own-magic/DEAL_ENTRY_OUT/DEAL_TYPE guards is sensible — cheapest checks first). Filter intent aligns with BR-3.6 + ADR-010 (EA-runaway-loop detection, not concurrent broker fills). |
| 3 | Error Handling | ✅ Pass | No new failure path. `HistoryDealGetInteger(deal, DEAL_REASON)` returns 0 on bad deal; cast to ENUM_DEAL_REASON of 0 != DEAL_REASON_EXPERT → returns early (safe). Earlier `HistoryDealSelect(deal)` at L813 already validates deal. |
| 4 | Performance | ✅ Pass | One additional `HistoryDealGetInteger` call per close deal. Already in cold path (DEAL_ENTRY_OUT after own-magic match). No hot-tick impact. |
| 5 | Over-Engineering | ✅ Pass | 3-LOC surgical patch at producer side. ADR-013 §Decision §Alternative C (ticket-dedup in CheckPingPong) correctly rejected as more complex. |
| 6 | Cross-Service Consistency | ⚠️ Finding | ADR-013 §Decision text ↔ code drift (Case F absent) per Finding 26.2 + R25 termination claim ↔ documented mechanism reproduction failure per **Finding 26.1 HIGH**. |
| 7 | Test Coverage Gaps | ⚠️ Finding | CircuitBreaker SelfTest Cases A-E unchanged; no Case F per ADR-013 §Decision (Finding 26.2). E-AC #1+#2 deferred to Step 3 Run #4 (registry expiry 2026-05-28) — compliant with Deferred-AC Registry. The producer-side filter is unit-tested only via Orchestrator OnTradeTransaction integration (per ADR-013 §Revisit-when acknowledgement); SelfTest expansion is deferred. |
| 8 | Architecture Compliance | ⚠️ Finding | ADR-013 §Decision text mandates Case F but realization missing → ADR-code drift (Finding 26.2 HIGH). Filter placement (between DEAL_TYPE filter L835 and direction derivation L849) matches the surface specified in ADR-013 §Decision. |
| 9 | Technical Design Compliance | ✅ Pass | TD-02 §5.8 CircuitBreaker skeleton + ADR-010 HALTED-state + ADR-011 ErrorBypassThrottle invariants preserved. ADR-013 explicitly cites TD-02 §5.8 + fix-round-10/11 producer-side wiring history. |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded-loop pathology in test surface. No new test code added. |
| 11 | Empirical AC Closure | ✅ Pass (with caveat) | IMPL-FIX-012 iter-1: S-AC #1-#3 closed with evidence artifacts (`_session-handoff/IMPL-FIX-012-slot-H-clustering-diagnostic-20260514.md` + journal parse + G1 compile log + G2 smoke). E-AC #1+#2 properly deferred via `deferred-ac-registry.md` (expiry 2026-05-28). No forbidden closure pattern (no `[x]` + "deferred to operator-runtime"). **Caveat:** IMPL-063 E-AC #2 (J-Magic fix `[db-inspect]`) closed via structural code grep fallback rather than journal-based DB inspect (0 J exits in 14-day pre-halt window) — closure note explicitly documents the kind mismatch + reason; borderline but acceptable. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface (per CLAUDE.md §1 Tier 1.5 walk = headless backtest + log + journal artifacts). |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer added by IMPL-FIX-012 (per `.claude/rules/testing.md` Prove-It table — `[config-audit]` n/a in Phase 1). |

---

## Findings

### Finding 26.1: 🟠 HIGH — R25 §Termination Test claim ไม่ reproduce ภายใต้ documented mechanism — Gate #9 clause (h) tree-wide returns 22 surviving hits, clause (i) rule-authoring contract violated

**Location:**
- File: `docs/code-review/review-round-25.md`, Line: 51-77 (Termination Test table + Verdict section)
- File: `.claude/rules/workflow.md`, Line: ~104-108 (Gate #9 clause (h) Combined sweep regex + clause (i))
- Service: methodology surface (Phase 5 mechanical gates)

**Code (re-run of R25's documented clause (h) combined regex tree-wide, this session 2026-05-15):**
```text
$ grep -rnE "\b(line [0-9]+(-[0-9]+)?|\.(mqh|mq5):[0-9]+(-[0-9]+)?)\b" \
       MQL5/Experts/PhoenicisNex/ \
    | grep -vE "(TD-02 (§|line)|ADR-[0-9]+ (§|line)| § [0-9]+(\.[0-9]+)? line |(trade-journal-schema|state-persistence-schema|slot-abstraction-contract)\.yaml|MACD line|Signal line|EMA line|SMA line|RSI line)"

# Result: 22 surviving hits across 11 files:
#   core/BootstrapValidator.mqh:81         (1 — mojibake'd §; carried over from R24 §24.1)
#   domain/MarketContext.mqh:83            (1 — legacy line 18644 cite)
#   inputs/Inputs_Slot_G2.mqh:41           (1 — legacy line 5558 cite)
#   inputs/Inputs_Slot_T.mqh:32            (1 — legacy line 18487 cite)
#   services/IndicatorService.mqh:194      (1 — PhoenicisN2.10_stable.mq5:28 + line 98)
#   services/RiskManager.mqh:219           (1 — LibCommon1.1.mq5:835 cite)
#   slots/Slot_B.mqh:209                   (1 — REWRITE-FILE: Slot_C.mqh:262-289)
#   slots/Slot_G.mqh:400                   (1 — legacy line 5071)
#   slots/Slot_G2.mqh:319,337              (2 — legacy line 5558/5766)
#   slots/Slot_K.mqh:170                   (1 — REWRITE-FILE: Slot_C.mqh:262-289)
#   slots/Slot_T.mqh:203,204,250,276,281,285,297,327,361   (11 — legacy line 18449/18454/18487/18644 family)
```

**Problem:**
R25 §Termination Test (review-round-25.md lines 50-64) explicitly declared: *"Chain terminated. All 9 Gate #9 clauses (a)-(i) verify clean tree-wide simultaneously under the documented mechanisms. No hand-classification beyond what clause (i) explicitly authorizes."* The R25 result row for clause (h) reported "**1 surviving hit** at `core/BootstrapValidator.mqh:81`" with the encoding-artifact scope-out per clause (i)(b).

Independent re-run this round of the **same documented regex** (intent + extended exemption per R24 §24.1) tree-wide against `MQL5/Experts/PhoenicisNex/` returns **22 surviving hits**, not 1. The additional 21 hits fall into two classes:

- **(a) 19 legacy-file cites** ("legacy line NNNNN" + `PhoenicisN2.10_stable.mq5:NN` + `LibCommon1.1.mq5:NNN`). These reference the **frozen** legacy MQL5 source files the rewrite is mirroring. Semantically compliant (cited files won't drift) but **mechanically non-exempt-by-regex**. Per clause (i): surviving hits MUST either (i.a) extend the exemption regex with attestation, or (i.b) be enumerated in the fix-round narrative as scope-out exceptions with stated reason. **R25 did neither** — it implicitly hand-classified them as exempt without authoring an extension or enumerating them. This is exactly the R20→R24 chain's "hand-classification without regex extension" defect class that clause (i) was authored to prevent (review-round-24.md §24.1 §"Why no rule edit").

- **(b) 2 rewrite-file path:line cites** at `slots/Slot_B.mqh:209` + `slots/Slot_K.mqh:170` both citing `Slot_C.mqh:262-289` as the "mirror" pattern. These are the **exact** load-bearing rewrite-file line-range anchors that clause (h) was authored to catch (R23 §23.1 site enumeration class). They are realized clause (h) text-violations, **not** scope-out candidates. **R25 missed them entirely** — neither enumerated as scope-out nor flagged as text-violations to re-anchor. Raised separately as Finding 26.3 (per text-violation discipline) but the meta-failure (R25 termination claim) belongs to this finding.

R25's "chain terminated" verdict was therefore **premature**: the documented mechanism does not reproduce R25's claimed pass count. The R12→R24 chain's **5th axis predicted by R24** — "rule-authoring contract" — has materialized at the **reviewer-authoring layer**: a verify-only review can drift from its own published mechanism just as a fix-round narrative can.

**Why This Matters:**
The Phase 5 mechanical-gate suite is the engineering-side audit contract that prevents `[x]` AC closures from drifting silently. If a verify-only round can declare "all clean" while the documented mechanism returns 22 hits, then every future round can do the same and the suite degrades to narrative theatre — exactly the failure mode the R24 §Finding 24.1 retrospective warned about ("Hand-classified exemptions that the documented regex does NOT reproduce are the exact regression class the R20→R23 chain accumulated"). Downstream consequence: a real load-bearing line-anchor drift (like Finding 26.3's `Slot_C.mqh:262-289` cites) can persist undetected for multiple review rounds, surfacing only when a refactor renumbers `Slot_C.mqh` and the cited "mirror" pattern is no longer there — the next engineer reading `Slot_B.mqh:209` mirrors a meaningless line range and silently introduces a behavioral divergence.

**Suggested Fix:**
Apply both branches of clause (i) to dispose of the 22 hits:

```text
# Branch (i)(a) — Extend Gate #9 clause (h) Combined sweep exemption regex with class (ε) for frozen
#                legacy-file cites (PhoenicisN2.10_stable.mq5 + LibCommon1.1.mq5 + "legacy line NNNN"
#                idiom). New exemption fragment:
#   (legacy line [0-9]+|(PhoenicisN2\.10_stable|LibCommon[0-9.]+)\.mq5:[0-9]+|`BollBBot > IchiMin`)
#
# Apply to .claude/rules/workflow.md Gate #9 row (line ~104) Combined sweep regex.
# Authorial attestation MUST appear in the fix-round narrative citing class (ε) addition + reason
# (legacy files frozen; cite drift impossible since legacy file is read-only commit).

# Branch (i)(b) — Enumerate the 2 rewrite-file path:line cites (slots/Slot_B.mqh:209 + slots/Slot_K.mqh:170)
# as Finding 26.3 (separate finding) for re-anchoring per clause (h) text. Do NOT add these to the
# exemption regex — they are realized drift, not scope-out class.

# Final combined regex after fix-round-25 (illustrative):
(TD-02 (§|line)|ADR-[0-9]+ (§|line)| § [0-9]+(\.[0-9]+)? line |(trade-journal-schema|state-persistence-schema|slot-abstraction-contract)\.yaml |MACD line|Signal line|EMA line|SMA line|RSI line|legacy line [0-9]+|(PhoenicisN2\.10_stable|LibCommon[0-9.]+)\.mq5:[0-9]+)

# Post-fix verification: re-run combined regex tree-wide → expect 3 surviving hits
# (1 mojibake at BootstrapValidator.mqh:81 still scope-out per clause (i)(b) encoding-artifact reason;
#  2 rewrite-file cites Slot_B.mqh:209 + Slot_K.mqh:170 → enumerated in Finding 26.3 for re-anchor).
# After Finding 26.3 fix: re-run → 1 surviving hit (mojibake only) → R25-equivalent state legitimately reached.
```

Also update R25's §Termination Test narrative to **strikethrough** the "chain terminated" claim with a forward-pointer to fix-round-25 (state-reconciliation discipline: a review claim that is later falsified must be annotated, not silently overwritten).

**Level of Effort:** Medium (regex extension + 2-line fix-round narrative + R25 strikethrough; ~30 min)

---

### Finding 26.2: 🟠 HIGH — ADR-013 §Decision mandates "add Case F to `CCircuitBreaker::SelfTest()`" but Case F absent in code (ADR-code drift)

**Location:**
- File: `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md`, Line: 41 (§Decision paragraph 3)
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`, Line: 293-425 (`CCircuitBreaker::SelfTest()` method — exits at Case E)
- Service: `ea` (intra-process MQL5)

**Code (ADR-013 §Decision paragraph 3, mandating action):**
```text
SelfTest update: add Case F to `CCircuitBreaker::SelfTest()` documenting the
DEAL_REASON_EXPERT filter requirement at the producer side (Orchestrator owns
the filter, not CircuitBreaker — CircuitBreaker.RecordClose itself remains
agnostic so direct unit tests via SelfTest still work). The SelfTest update
is documentation-only inside CircuitBreaker.mqh; the runtime filter lives in
Orchestrator.
```

**Code (`services/CircuitBreaker.mqh::SelfTest` actual surface, lines 380-410 — exits at Case E):**
```mql5
   //--------------------------------------------------------------------
   // Case E: pre-Init RecordOpen + RecordClose dropped — buffer NOT
   //         mutated + Print fallback emitted (fix-round-13 §13.5;
   //         guards dual-gate added in fix-round-12 §12.6).
   //         ...
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   CLogger *saved_logger = m_logger;
   m_logger = NULL;                          // simulate pre-Init state

   RecordOpen(200, 0, t0);                   // expect: dropped, m_count == 0
   RecordClose(200, 0, t0);                  // expect: dropped, m_count == 0

   m_logger = saved_logger;                  // restore for tail of SelfTest

   if(m_count != 0)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case E:"
            " pre-Init Record* mutated buffer (m_count=", m_count,
            "), expected 0");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case E: pre-Init Record* dropped as expected");

   // Cleanup macro
#undef CB_SELFTEST_RESET

   // --- Restore original state
   m_idx   = saved_idx;
   m_count = saved_count;
   // ... method exits here. NO Case F.
```

**Problem:**
ADR-013 §Decision paragraph 3 explicitly mandates "add Case F to `CCircuitBreaker::SelfTest()` documenting the DEAL_REASON_EXPERT filter requirement". The fix-round commit (`918e7cb`) does not include Case F — `CCircuitBreaker::SelfTest()` still exits at Case E (line 408). Verified via `grep -nE "Case [F-Z]|case F" MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh` → 0 hits.

This is **literal ADR-code drift**: ADR §Decision is normative ("add X") and code reality does not match. ADR-013 §Revisit-when does anticipate future SelfTest expansion ("CircuitBreaker SelfTest expanded to cover producer-side filter (currently filter is unit-tested via Orchestrator-side OnTradeTransaction integration, not CircuitBreaker.SelfTest)"), but that future-work framing is **separate** from the §Decision's "add Case F" mandate which is described as part of the patch surface. The two sections are inconsistent: §Decision says "add Case F now (documentation-only)"; §Revisit-when says "currently filter is unit-tested via Orchestrator integration, not SelfTest" (implying Case F not yet added).

**Why This Matters:**
The ADR is the architectural commitment for a halt-affecting decision (BR-3.6 scope refinement). Future readers of `CircuitBreaker.mqh::SelfTest` will see Cases A-E and be unaware that the producer-side filter exists at all — they may reasonably assume CircuitBreaker is comprehensive in its own halt-trigger surface. The ADR's intent ("documentation-only inside CircuitBreaker.mqh") is exactly to leave a breadcrumb at the test-suite surface so future engineers don't re-derive the false-positive scenario when extending CircuitBreaker. Missing Case F = missing breadcrumb. Lower-grade risk than runtime correctness, but the ADR §Decision being a normative claim that does not hold in code is the canonical Dim #8 Architecture-Compliance defect class.

**Suggested Fix:**
Add a 25-LOC documentation-only Case F block to `services/CircuitBreaker.mqh::SelfTest()` immediately before the `#undef CB_SELFTEST_RESET` cleanup (around line 410). The Case F body MUST be documentation-only (per ADR-013 §Decision: "The SelfTest update is documentation-only inside CircuitBreaker.mqh"); no executable assertions required since the filter lives in Orchestrator:

```mql5
   //--------------------------------------------------------------------
   // Case F: DEAL_REASON_EXPERT filter documented at producer side
   //         (ADR-013, IMPL-FIX-012 2026-05-14).
   //
   //         CircuitBreaker.RecordClose itself is REASON-agnostic — it
   //         records every close it receives and detects ping-pong on
   //         (magic, dir, time) tuples regardless of reason. The
   //         DEAL_REASON_EXPERT filter lives in core/Orchestrator.mqh
   //         ::OnTradeTransaction (the producer side) so that only
   //         EA-driven closes feed RecordClose. Broker-driven closes
   //         (SL/TP/SO/rollover) are skipped at the producer; they
   //         never reach RecordClose at all.
   //
   //         This means Cases A-E above ARE the unit tests for the
   //         detector — they exercise CheckPingPong directly with
   //         synthetic events bypassing the producer-side filter.
   //         The integration-level test for the filter lives in
   //         IMPL-FIX-012 Step 3 Run #4 (G3 5-yr Bucket A retry).
   //
   //         See ADR-013 § Decision Validation for the empirical
   //         evidence trail (IMPL-062 Run #2 + Run #3 byte-identical
   //         false-positive halt class).
   //--------------------------------------------------------------------
   Print("[CircuitBreaker][SelfTest][NOTE] Case F: DEAL_REASON_EXPERT filter"
         " enforced at Orchestrator.OnTradeTransaction (ADR-013). RecordClose"
         " is REASON-agnostic; producer-side filter ensures only EA-driven"
         " closes feed BR-3.6 detector.");
```

Alternative fix: amend ADR-013 §Decision to remove the "add Case F" mandate and rely on §Revisit-when's future-work framing. This is cheaper but weakens the audit trail — pick the code-addition path unless the operator explicitly chooses to defer (in which case register a Deferred-AC Registry row with expiry).

**Level of Effort:** Low (25-LOC SelfTest insert + G1 recompile + grep-verify; ~15 min)

---

### Finding 26.3: 🟡 MEDIUM — `slots/Slot_B.mqh:209` + `slots/Slot_K.mqh:170` ใช้ load-bearing rewrite-file line-range anchor `Slot_C.mqh:262-289` — clause (h) realized text-violation

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh`, Line: 208-217
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh`, Line: 169-178
- File (destination cited): `MQL5/Experts/PhoenicisNex/slots/Slot_C.mqh`, Line: 262-289 (MqlTradeRequest setup + `m_risk.OpenOrder` + `m_pending.TransitionExecuted`)
- Service: `ea` (intra-process MQL5)

**Code (`slots/Slot_B.mqh:208-217`):**
```mql5
      string           comment    = "B,anti,1";

      //--- IMPL-FIX-011d Phase 2 iter-19 (2026-05-12): wire RiskManager.OpenOrder
      //    per IMPL-FIX-003 Phase 1A pattern (mirror Slot_C.mqh:262-289 +
      //    Slot_K.mqh post-iter-18). Slot_B was on the deferred IMPL-FIX-003
      //    Phase 1B follow-up list; legacy fires at Q1 2021-03-04 10:25 with
      //    comment `B,131,9.5,1,5,3,2,73`, rewrite silent because the submit
      //    block never called OpenOrder. Predicate path (anti-trend fractal
      //    reversal + ADX + cloud distance + tenkan/kijun direction) was
      //    already correct from IMPL-037; only the OrderSend wire-up missing.
      //    Same root-cause class as Slot_K iter-17→iter-18 telemetry verdict.
      MqlTradeRequest req  = {};
```

**Code (`slots/Slot_K.mqh:169-178`):**
```mql5
      string           comment    = "K,layer,1";

      //--- IMPL-FIX-011d Phase 2 iter-18 (2026-05-12): wire RiskManager.OpenOrder
      //    per IMPL-FIX-003 Phase 1A pattern (mirror Slot_C.mqh:262-289).
      //    iter-17 telemetry empirically proved all 4 predicate gates PASS at
      //    legacy K fire bar 2021-02-16 20:00:00 (G1=PASS k_open=0; G2=PASS
      //    d1_now=02-16 last=02-09; G3=PASS f1=-1.5631 cross_dw=T alternate;
      //    G4=PASS bid=1.21098 > cloud_high=1.20757 → SELL). Slot_K silence
      //    was NOT a predicate problem — it was an unwired OrderSend stub
      //    on the deferred IMPL-FIX-003 Phase 1B follow-up list.
      MqlTradeRequest req  = {};
```

**Problem:**
Both cites use the physical-line-range anchor `Slot_C.mqh:262-289` as the **load-bearing** mirror pointer. Per `.claude/rules/workflow.md` Gate #9 clause (h) text (R22 + R23 strengthening): *"bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor — drift on file edits silently desyncs the cite without compile-time signal."*

Neither cite is paired with a grep-stable symbolic anchor. The comment claims `Slot_B`/`Slot_K` "mirror" `Slot_C.mqh:262-289` — that line range today contains the `MqlTradeRequest` setup + `m_risk.OpenOrder("C")` + `m_pending.TransitionExecuted(PM_C)` sequence. If `Slot_C.mqh` is later edited (e.g., add 3-line comment block above line 262), the cite silently desyncs: the next engineer reading `Slot_B.mqh:209` follows the `Slot_C.mqh:262-289` pointer and lands on the wrong region (the now-inserted comment + part of the order-submission block). No compile signal; behavioral divergence enters at the next refactor.

This is the **exact** R23 §23.1 defect class (cf. `Slot_GO.mqh:15,99` citing `Slot_G.mqh:392`, `SlotState.mqh:38` citing `OnTradeTransaction (line 791)`) which was supposed to be swept tree-wide and re-anchored to grep-stable symbolic markers. R25 §Termination Test missed both these sites (Finding 26.1 meta-failure root cause).

**Why This Matters:**
Slot_B + Slot_K are the **only** two slots that wire `RiskManager.OpenOrder` post-IMPL-FIX-011d Phase 2 — and the wire-up pattern at Slot_C is the canonical reference. If/when Slot_C undergoes future refactor (e.g., extract MqlTradeRequest setup into a helper, IMPL-FIX-013 anti-pyramid latch, etc.), Slot_C.mqh:262-289 will renumber. The "mirror Slot_C.mqh:262-289" comment becomes architectural noise — actively misleading rather than helpful. Next engineer reads Slot_B.mqh:209 + lands at wrong code at Slot_C.mqh:262-289 + assumes the pattern matched + introduces silent behavioral divergence in Slot_B without knowing.

Additionally, the cite pair is intentional: Slot_B "mirrors Slot_C.mqh:262-289 + Slot_K.mqh post-iter-18" and Slot_K "mirrors Slot_C.mqh:262-289" — there's an indirect chain (Slot_B → Slot_K → Slot_C) where if Slot_K is rewritten, Slot_B's "mirror Slot_K.mqh post-iter-18" pointer also drifts. Compound brittleness.

**Suggested Fix:**
Re-anchor both cites to grep-stable symbolic markers per clause (h) anchor-axis discipline. Pattern: cite the **shape** of the mirrored code (the symbol/method/comment-block marker), not the line range. Line range may remain as ancillary navigation aid but MUST be paired with a symbolic anchor:

```mql5
// slots/Slot_B.mqh:208-217 (proposed re-anchor)
      //--- IMPL-FIX-011d Phase 2 iter-19 (2026-05-12): wire RiskManager.OpenOrder
      //    per IMPL-FIX-003 Phase 1A pattern (mirror Slot_C.mqh's
      //    `MqlTradeRequest req = {}; ... m_risk.OpenOrder(req, "C");
      //    m_pending.TransitionExecuted(PM_C);` order-submission block in
      //    `_Evaluate`'s phase-B entry path; line range ~262-289 ancillary).
      //    Slot_B was on the deferred IMPL-FIX-003 Phase 1B follow-up list...

// slots/Slot_K.mqh:169-178 (proposed re-anchor)
      //--- IMPL-FIX-011d Phase 2 iter-18 (2026-05-12): wire RiskManager.OpenOrder
      //    per IMPL-FIX-003 Phase 1A pattern (mirror Slot_C.mqh's
      //    `MqlTradeRequest req = {}; ... m_risk.OpenOrder(req, "C");
      //    m_pending.TransitionExecuted(PM_C);` order-submission block;
      //    line range ~262-289 ancillary).
      //    iter-17 telemetry empirically proved...
```

The grep-stable anchor `MqlTradeRequest req = {}; ... m_risk.OpenOrder(req, "C"); m_pending.TransitionExecuted(PM_C)` survives renumbering of Slot_C.mqh because the symbolic pattern (req setup → OpenOrder("C") → TransitionExecuted(PM_C)) is unique within Slot_C and a fix-round can `grep` for it post-refactor. Verification post-fix: `grep -nE "Slot_C\.mqh:[0-9]+" MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh` should return 0 hits OR each surviving hit is paired with a `MqlTradeRequest`-class symbolic anchor in the same comment block.

**Level of Effort:** Low (2 comment-block edits + G1 recompile + grep-verify; ~10 min)

---

### Finding 26.4: 🟡 MEDIUM — fix-round-24 §Latent follow-up (mojibake'd `§` byte sequences in 5 files) ไม่ได้ propagate ไป `deferred-ac-registry.md` หรือ `impl-plan.md` task list — orphan cleanup recommendation

**Location:**
- File: `docs/code-review/fix-round-24.md`, Line: 84 (§24.1 Latent issue surfaced) + line 167 (§Summary Latent follow-up)
- File: `docs/state/deferred-ac-registry.md` (Active table — no IMPL-FIX-NNN row for mojibake cleanup)
- File: `docs/state/impl-plan.md` (no task row for mojibake cleanup; `IMPL-FIX-004` row tracks comment-history-exemptions populate work, not this)
- Service: methodology surface (state-reconciliation discipline)

**Code (fix-round-24.md §24.1 line 84):**
```text
**Latent issue surfaced (out of scope for fix-round-24):** the same mojibake'd § byte sequence
appears in 5 files: `core/BootstrapValidator.mqh`, `inputs/Inputs_Slot_BI.mqh`,
`inputs/Inputs_Slot_BR.mqh`, `inputs/Inputs_Slot_GO.mqh`, `services/CircuitBreaker.mqh`. This
is a pre-existing file-transcoding defect predating fix-round-24. Flagged here for follow-up —
not actioned in this round to keep methodology-only scope.
```

**Code (fix-round-24.md §Summary line 167):**
```text
**Latent follow-up (out of scope for R24):** mojibake'd `§` byte sequences in 5 files
(`core/BootstrapValidator.mqh`, `inputs/Inputs_Slot_BI.mqh`, `inputs/Inputs_Slot_BR.mqh`,
`inputs/Inputs_Slot_GO.mqh`, `services/CircuitBreaker.mqh`) — pre-existing file-transcoding
defect; cleanup ticket recommended.
```

**Code (independent verification this round — `od -c` byte dump of `BootstrapValidator.mqh:81` mojibake):**
```text
$ sed -n '81p' MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh
   //    Called from Orchestrator::Init Phase C (TD-02 เธขเธ7.4 line 1654):
                                                          ^^^^^^^^^ mojibake (was §)
```

**Problem:**
fix-round-24 §24.1 surfaced 5 files with mojibake'd `§` byte sequences (Thai-encoding corruption: U+0E40 + control-char U+0087 instead of UTF-8 `\xc2\xa7`) as a **latent file-transcoding defect**. fix-round-24 §Summary recommended a **cleanup ticket**. Today (2026-05-15, 6 days post-fix-round-24), no such ticket exists:

- `grep -nE "mojibake|transcoding|UTF-16|§ byte|§ corruption" docs/state/deferred-ac-registry.md docs/state/impl-plan.md` → 0 hits
- No `IMPL-FIX-NNN` row references the 5-file mojibake cleanup
- The `IMPL-FIX-004` registry row (P5, expiry 2026-05-19) tracks comment-history-exemptions populate work, not this cleanup

Per CLAUDE.md §6 State Reconciliation Discipline: fix-round narratives that surface follow-up work MUST propagate via either (a) a `deferred-ac-registry.md` row (for vendor/operator-wait class), (b) an `impl-plan.md` `IMPL-FIX-NNN` task row (for engineer-side rework), or (c) an `operator-action-registry.md` row (for UIR class). fix-round-24's "cleanup ticket recommended" landed in narrative only — no propagation. The defect is now an **orphan recommendation**: it exists in fix-round-24's audit trail, but the canonical task-list surfaces (registry + impl-plan) are blind to it.

Additionally, the mojibake population is **wider than fix-round-24 enumerated**: tree-wide grep for the byte sequence `\xe0\xb9\x80` (Thai mojibake leading byte) reveals **80+ sites** across `services/Logger.mqh`, `services/CircuitBreaker.mqh::SelfTest` Case banners, `services/PortfolioState.mqh`, and most `.mqh` comment blocks — the corruption is a project-wide Thai-character encoding accident (likely a `Save-As` encoding switch at some point). The 5-file enumeration in fix-round-24 is the surface that surfaced through clause (h)'s grep; the actual blast radius is larger.

**Why This Matters:**
Mojibake in comment blocks does not affect runtime (MQL5 compiler ignores comment-block byte sequences as long as they're not `*/` terminators), but:
1. Comments become unreadable for future engineers — undermining the documentation that ADRs and Phase 5 audit rely on.
2. Clause (h) tree-wide intent grep returns false positives at every mojibake site that **happened to contain a number adjacent to text** (e.g., `BootstrapValidator.mqh:81` — see Finding 26.1).
3. The R12→R24 chain's "axes" discipline assumed clean UTF-8 text — encoding corruption is a separate axis (file-encoding integrity) that needs its own mechanism (e.g., a pre-commit `file --mime-encoding` check rejecting non-UTF-8).
4. As an unticketed follow-up, the work is at risk of indefinite drift (no expiry, no owner, no acceptance criteria).

**Suggested Fix:**
Author `IMPL-FIX-013` in `impl-plan.md` (M [refactor:ea] severity LOW) and a paired row in `deferred-ac-registry.md`:

```markdown
# docs/state/impl-plan.md (P5 section, new task block)
#### IMPL-FIX-013: [M] [refactor:ea] — File-encoding cleanup: restore UTF-8 § + Thai-mojibake repair
- **Phase**: P5 — Delivery (file-encoding hygiene; pre-commit gate candidate)
- **Severity**: LOW (comment-block corruption; no runtime impact)
- **Scope**: `[refactor:ea]` — sweep all `MQL5/Experts/PhoenicisNex/**/*.mqh + *.mq5` for non-UTF-8 byte sequences (Thai mojibake `\xe0\xb9\x80` leading bytes); restore intended `§` + `—` + Thai characters per fix-round-24 §Latent enumeration (5 priority files) + tree-wide audit
- **Description**: (a) Enumerate corrupted sites tree-wide via byte-level grep; (b) compare against last-clean Git revision (`git log --diff-filter=M` on .mqh files pre-2026-05); (c) author `simulation/scripts/fix_mojibake.ps1` (PowerShell since dev system) that takes mojibake → original-character map + does in-place byte substitution; (d) verify via `iconv -f UTF-8 -t UTF-8 //IGNORE` round-trip; (e) commit + re-run G1 + smoke per `.claude/rules/testing.md`.
- **S-AC**:
  - [ ] Cleanup script committed at `simulation/scripts/fix_mojibake.ps1` — PS5.1+PS7 ParseFile PASS
  - [ ] Tree-wide mojibake-byte grep `\xe0\xb9\x80` returns 0 hits post-cleanup
  - [ ] G1 PASS post-cleanup `Result: 0 errors, 0 warnings`
- **E-AC**:
  - [ ] G2 bootstrap_smoke 3-day PASS post-cleanup (behavioral parity vs pre-cleanup) `[log-assertion]` — gated on next operator session
- **Discovered**: 2026-05-09 via fix-round-24 §Latent surface (5 file enumeration); broader surface confirmed 2026-05-15 via R26 byte-level audit (80+ sites)
- **Risk**: low (comment-only; no semantic change)

# docs/state/deferred-ac-registry.md (Active table)
| P5 | IMPL-FIX-013 | E-AC #1 G2 smoke post-cleanup | [log-assertion] | engineer | 2026-05-29 | low — comment-only refactor; behavioral parity expected by construction |
```

Sentinel + State Reconciliation 3-file rule: append to `overview.md` Impl Plan row + `current_handoff.md` Last completed action.

**Level of Effort:** Low for ticket authoring (~10 min). The actual cleanup is Medium (script + tree-wide replace + G1 + smoke; ~1-2 hr).

---

### Finding 26.5: 🔵 LOW — IMPL-FIX-012 closure audit-log row cites evidence file with wrong separator (`.tester.txt` vs actual `-tester.txt`)

**Location:**
- File: `docs/state/impl-plan.md`, Line: 2214 (Audit Log row 2026-05-14 IMPL-FIX-012 iter-1)
- File: `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md`, Line: 102 (References list)
- File: `docs/state/_session-handoff/` (actual filename: `IMPL-062-bucket-a-5yr-run3-20260514-tester.txt`)

**Code (`impl-plan.md` L2214):**
```text
**Step 2 G2 bootstrap_smoke 3-day (this session):** ...
[earlier in row: ] Cited evidence: `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.{jsonl,tester.txt}`
```

**Code (`docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md` L102-103):**
```text
- IMPL-062 Run #3 evidence — `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.{jsonl,tester.txt}`
- IMPL-062 Run #2 evidence — `_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.{txt,jsonl}`
```

**Code (actual files on disk):**
```text
$ ls docs/state/_session-handoff/ | grep "5yr-run3"
IMPL-062-bucket-a-5yr-run3-20260514-tester.txt   ← hyphen separator
IMPL-062-bucket-a-5yr-run3-20260514.jsonl
```

**Problem:**
Closure-note + ADR-013 cite the evidence file using a dot-separator pattern `<base>.{jsonl,tester.txt}` (brace expansion would yield `<base>.jsonl` + `<base>.tester.txt`). The actual filename on disk uses a hyphen separator: `<base>-tester.txt`. Brace expansion of the cite resolves to a file that does NOT exist (`<base>.tester.txt`), while the existing `<base>-tester.txt` is unaddressed.

This is a Phase-5 Gate #8 narrative-section-freshness drift (cite-vs-reality). The `.jsonl` cite is correct (exists); the `.tester.txt` cite is wrong (should be `-tester.txt`).

**Why This Matters:**
Any future tooling/automation that resolves the cite via brace expansion (operator runbook scripts, audit replay protocols, evidence-existence checks) will fail to find the tester log. The Run #4 verification protocol (ADR-013 §Decision Validation §Step 3) references the same cite pattern — if Run #4 produces `<base4>-tester.txt`, the audit might silently miss it. Likewise, future review rounds running E-AC artifact existence checks (Dim #11) would mark the file "missing" when it's actually present under the hyphen-separator name.

**Suggested Fix:**
Two surfaces to correct:

```text
# 1. docs/state/impl-plan.md L2214 + L7 (TL;DR) + L1982 (Status row) — search/replace
#    .tester.txt} → -tester.txt}      (both separated correctly under brace expansion)
# OR collapse brace expansion to explicit pairs:
#    _session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.jsonl
#    + _session-handoff/IMPL-062-bucket-a-5yr-run3-20260514-tester.txt

# 2. docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md L102
#    Same edit. ADR is "Accepted" status — amend in place with cite-correction note in audit trail.
```

Post-fix verification: `ls docs/state/_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514-tester.txt` exists AND all cites in `impl-plan.md` + ADR-013 resolve to extant files (run `grep -oE '_session-handoff/[A-Za-z0-9_.-]+\.(txt|jsonl|md|json)' docs/adr/013-*.md docs/state/impl-plan.md | sort -u | xargs -I {} ls docs/state/{}` — should return 0 missing-file errors).

**Level of Effort:** Low (3-line edits across 2 files; ~5 min)

---

### Finding 26.6: 🔵 LOW — Phase 5 Gate #1 narrative claim "1 sanctioned false-positive" understates actual 2 grep hits

**Location:**
- File: `docs/state/impl-plan.md`, Line: 2214 (Audit Log row 2026-05-14 IMPL-FIX-012 iter-1)
- File: `docs/state/impl-plan.md`, Line: 2318 (Closure Hygiene Status — Phase 5 mechanical gates summary footer)

**Code (claim in L2214):**
```text
**Phase 5 mechanical gates 1+6+11 verified inline:** forbidden-pattern grep on impl-plan.md
= 1 sanctioned false-positive per claim-review-14 §At-a-Glance precedent
(regex .* greediness on "deferred per X" + later "fix-round-10 precedent"; same accepted class)
```

**Code (claim in L2318):**
```text
...gates #1 (forbidden-pattern grep on impl-plan.md = 1 sanctioned false-positive
per claim-review-14 §At-a-Glance precedent — regex .* greediness on "deferred per X"
+ later "fix-round-10 precedent"; same accepted class)...
```

**Code (independent verification this round):**
```bash
$ grep -cnE "deferred per .* precedent|deferred to operator-runtime|structurally complete.*deferred|live verification deferred" docs/state/impl-plan.md
2
$ grep -nE "deferred per .* precedent|..." docs/state/impl-plan.md | awk -F: '{print $1}'
25     # IMPL-FIX-011d Phase 1 audit-log row (S-AC #4 deferred per registry row ... fix-round-10 precedent)
2318   # Closure Hygiene footer paragraph (self-reference: describes the regex pattern in narrative)
```

**Problem:**
Both audit-log narratives (L2214 + L2318) claim Phase 5 Gate #1 sweep returned "1 sanctioned false-positive". Actual sweep returns **2** hits — one at L25 (IMPL-FIX-011d audit row) and one at L2318 itself (the Closure Hygiene footer self-references the forbidden-pattern regex in narrative). Both are legitimately sanctioned false positives (greedy `.*` matching across narrative descriptions, not actual `[x]` AC closure forbidden patterns), but the count is off by one. The self-reference at L2318 — where the footer paragraph contains the exact substring `"deferred per X" + later "fix-round-10 precedent"` literally as narrative — creates the second hit; updating the audit log to claim "1 hit" while L2318 itself causes a second hit makes the claim self-falsifying.

**Why This Matters:**
Phase 5 mechanical gates are a numeric audit contract. A "1 hit" claim vs "2 hits" reality is a small drift, but:
1. It establishes a precedent that gate-1 claims need not match the actual sweep count.
2. The L2318 self-reference is structural — future closures that also reference the regex in narrative will compound the count without updating the claim.
3. Per Finding 26.1 (R25 termination claim drift), narrative claims that don't reproduce under the documented mechanism erode trust in the entire suite.

**Suggested Fix:**
Update both audit-log rows to claim "2 sanctioned false-positives" + enumerate them:

```text
# docs/state/impl-plan.md L2214 (and equivalent L2318) — replace
**Phase 5 mechanical gates 1+6+11 verified inline:** forbidden-pattern grep on impl-plan.md
= 2 sanctioned false-positives per claim-review-14 §At-a-Glance precedent
(both are regex .* greediness on "deferred per X" + later "fix-round-10 precedent" pattern;
hit-1 at L25 IMPL-FIX-011d audit-log row, hit-2 at L2318 Closure Hygiene footer self-reference;
same accepted class — neither is a real `[x]` AC closure forbidden-pattern violation).
```

Alternative (more durable): refactor L2318's self-referential narrative to break the regex match (e.g., rewrite "deferred per X" + later "fix-round-10 precedent" → "deferred-per-X + later fix-round-10-precedent" with hyphens substituting spaces to break the `.*` greedy match). This permanently drops the count to 1.

**Level of Effort:** Low (2-line edit across 2 audit-log rows; ~5 min)

---

## Cross-Service Issues

### CS-26.1 — ADR-013 §Decision ↔ `services/CircuitBreaker.mqh::SelfTest` body drift

Cross-reference of `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md:41` (§Decision paragraph 3: "add Case F to `CCircuitBreaker::SelfTest()`") against `services/CircuitBreaker.mqh:293-425` (`CCircuitBreaker::SelfTest()` method body) shows ADR-mandated action absent in code. See Finding 26.2.

### CS-26.2 — R25 §Termination Test ↔ `.claude/rules/workflow.md` Gate #9 clause (i) documented mechanism mismatch

R25 declared "chain terminated; all 9 clauses verify clean tree-wide simultaneously under documented mechanisms." Re-running the documented clause (h) regex this round returns 22 hits (vs R25's claim of 1). Clause (i) text mandates either exemption-regex extension (with attestation) or scope-out enumeration with stated reason; R25 did neither. See Finding 26.1.

### CS-26.3 — Mojibake propagation across `core/`, `services/`, `inputs/`, `slots/`, `domain/`, `helpers/`

Independent byte-level audit shows the Thai-character-encoding corruption is wider than fix-round-24's 5-file enumeration (80+ sites tree-wide for the `\xe0\xb9\x80` leading-byte pattern). Cross-cutting; needs project-level cleanup ticket. See Finding 26.4.

---

## Phase 5 Mechanical Gate Compliance Check (IMPL-FIX-012 iter-1 closure commit `918e7cb`)

| # | Gate | Engineer's claim | Independent verification | Status |
|---|------|------------------|--------------------------|--------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | "1 sanctioned false-positive" | **2 hits** — both sanctioned class but count off-by-one (Finding 26.6) | ⚠️ Low-severity drift |
| 2 | TL;DR ↔ registry recount | Not invoked (no plan-row count change) | n/a — no registry mutation this round | n/a |
| 3 | TL;DR ↔ matrix denominator | Not invoked | n/a | n/a |
| 4 | Sentinel counter increment | "unchanged at 1 IMPL-NNN closure since R09" | Matches: IMPL-063 closed via cascade 2026-05-14; IMPL-FIX-012 sub-iter doesn't increment per workflow.md Gate #4 | ✅ Pass |
| 5 | overview.md sync | "row 19+20 status string append" | Confirmed: 2 IMPL-FIX-012 mentions in overview.md | ✅ Pass |
| 6 | File integrity post-Edit | "single `## End of Plan` marker + clean trailer" | `grep -c "^## End of Plan" docs/state/impl-plan.md` = 1; tail clean | ✅ Pass |
| 7 | Phase Status Notes sweep | Not invoked | P4 row at L116 reflects post-IMPL-FIX-012 reality (cascade closure + ADR-013 cite) | ✅ Pass |
| 8 | Narrative freshness sweep | Implicit | TL;DR + Open Risks + Next Best Action all updated to post-iter-1 state | ⚠️ Filename separator drift in evidence cite (Finding 26.5) |
| 9a | Originating literal grep | n/a (no comment-routing edit) | 0 hits ✅ | ✅ Pass |
| 9b | Broader-class doubling regex | n/a | 0 hits ✅ | ✅ Pass |
| 9c | Repo-wide intent grep | n/a | 0 source-tree hits; audit-doc hits preserved per clause (c) | ✅ Pass |
| 9d | Closed-task verb-form catalog (dynamic) | n/a | 0 hits ✅ | ✅ Pass |
| 9e | Dynamic closed-task list | n/a | 0 source-tree hits ✅ | ✅ Pass |
| 9f | Destination-existence verification | n/a (no new bin-1 routing comments) | n/a | ✅ Pass |
| 9g | Token-collision pre-check | n/a (no bulk token substitution) | n/a | ✅ Pass |
| 9h | Line-anchor brittleness (R22+R23+R24 extended exemption) | Not invoked | **22 surviving hits tree-wide** — 1 mojibake (R24 carry-over) + 19 legacy-file cites (clause-(i) non-exempt-by-regex) + 2 rewrite-file cites Slot_B.mqh:209 + Slot_K.mqh:170 (realized text-violations); see Finding 26.1 + 26.3 | 🔴 **FAIL** |
| 9i | Exemption-regex tree-wide verifiability (R24 NEW) | Not invoked | Documented mechanism does NOT reproduce R25 claim; 21 surviving hits not enumerated as scope-out exceptions per clause (i) text → rule-authoring contract violated | 🔴 **FAIL** |
| 10 | Stash-clean G1 | "PASS 0err/0warn/4705 ms post-IMPL-FIX-012 patch" | Trust engineer attestation (compile artifact not committed per `.claude/rules/ea.md` §Commit Format) | ✅ Pass (attested) |
| 11 | Working-tree clean post-closure | "pending" at audit-log row, expected clean post-commit | `git status --porcelain` → 0 lines post-commit ✅ | ✅ Pass |

**Verdict on IMPL-FIX-012 iter-1 mechanical gates:** 9 of 11 applicable gates pass; **Gates 9h + 9i FAIL** (Finding 26.1) + Gate #1 minor count drift (Finding 26.6) + Gate #8 evidence-cite separator drift (Finding 26.5). The 9h/9i failures are inherited from R25's premature termination claim — IMPL-FIX-012 iter-1 did not introduce them, but it also did not exercise the gate sweep tree-wide to catch them.

---

## Summary Table

| # | Finding | Severity | Dimension | Title (short) | Location | Fix size |
|---|---------|----------|-----------|---------------|----------|----------|
| 1 | 26.1 | 🟠 HIGH | 6 / 8 / Phase-5 Gate #9 (h)+(i) | R25 termination claim ไม่ reproduce — clause (h) tree-wide returns 22 hits; clause (i) rule-authoring violated | `docs/code-review/review-round-25.md:51-77`; `.claude/rules/workflow.md:104-108` | Medium |
| 2 | 26.2 | 🟠 HIGH | 2 / 8 / Architecture compliance | ADR-013 §Decision mandates Case F SelfTest but Case F absent in code | `docs/adr/013-...:41`; `services/CircuitBreaker.mqh:293-425` | Low |
| 3 | 26.3 | 🟡 MEDIUM | Phase-5 Gate #9 (h) text-violation | Slot_B.mqh:209 + Slot_K.mqh:170 ใช้ rewrite-file line-range anchor (`Slot_C.mqh:262-289`) | `slots/Slot_B.mqh:209`; `slots/Slot_K.mqh:170` | Low |
| 4 | 26.4 | 🟡 MEDIUM | State Reconciliation | fix-round-24 §Latent mojibake follow-up ไม่ propagate → orphan recommendation | `docs/code-review/fix-round-24.md:84,167`; `deferred-ac-registry.md`; `impl-plan.md` | Low (ticket) + Medium (actual cleanup) |
| 5 | 26.5 | 🔵 LOW | Phase-5 Gate #8 narrative freshness | Evidence-cite filename separator drift (`.tester.txt` vs `-tester.txt`) | `impl-plan.md:2214`; `ADR-013.md:102` | Low |
| 6 | 26.6 | 🔵 LOW | Phase-5 Gate #1 count drift | Audit-log claims "1 sanctioned false-positive"; actual sweep returns 2 hits | `impl-plan.md:2214,2318` | Low |

---

## Recommendation

**Fix-round-25 required.** 2 HIGH findings (R25 termination drift + ADR-Case-F drift) are both surfaced this round. The 2 MEDIUM + 2 LOW findings cluster around the same theme (Phase 5 audit-trail precision) and naturally batch into the same fix-round.

**Suggested fix-round-25 scope (priority order):**
1. **Finding 26.2 HIGH** — Add Case F documentation block to `services/CircuitBreaker.mqh::SelfTest()` per ADR-013 §Decision (or amend ADR-013 §Decision to remove the mandate + cite §Revisit-when as the deferral target).
2. **Finding 26.1 HIGH** — Extend Gate #9 clause (h) Combined sweep regex with class (ε) for frozen legacy-file cites (`(legacy line [0-9]+|(PhoenicisN2\.10_stable|LibCommon[0-9.]+)\.mq5:[0-9]+)`); cite extension in fix-round-25 narrative per clause (i)(a) attestation discipline. Update R25 §Termination Test verdict with strikethrough + forward-pointer to fix-round-25.
3. **Finding 26.3 MEDIUM** — Re-anchor `Slot_B.mqh:209` + `Slot_K.mqh:170` mirror cites to grep-stable symbolic markers (`MqlTradeRequest req = {}; ... m_risk.OpenOrder(req, "C"); m_pending.TransitionExecuted(PM_C)` pattern); line ranges may remain as ancillary aids.
4. **Finding 26.4 MEDIUM** — Author `IMPL-FIX-013` row in `impl-plan.md` + `deferred-ac-registry.md` for tree-wide mojibake cleanup. (Cleanup execution itself is out-of-scope for fix-round-25; ticket authorship suffices to close the orphan-recommendation gap.)
5. **Finding 26.5 LOW** — Search/replace `.tester.txt` → `-tester.txt` in `impl-plan.md` + `docs/adr/013-*.md`.
6. **Finding 26.6 LOW** — Update audit-log rows L2214 + L2318 to claim "2 sanctioned false-positives" (or refactor L2318 narrative to break the self-referential regex match).

**Predicted post-fix-round-25 termination test:** clause (h) returns 3 hits (1 mojibake + 2 Slot_B/Slot_K text-violations resolved by Finding 26.3); clause (i) returns clean (legacy-cite class enumerated as exemption (ε) with attestation). Mojibake hit at `BootstrapValidator.mqh:81` continues to scope-out per clause (i)(b) encoding-artifact reason, pending IMPL-FIX-013 actual cleanup.

> **Reviewer note (R12→R26 recurrence chain — 5th axis surfaced):**
> The R12→R24 chain's 4 axes (catalog / destination / anchor / exemption-regex) were declared "terminated" by R25. R26 surfaces a **5th axis**: **reviewer-authoring contract** — even a verify-only review round must reproduce its claims under the documented mechanism, not under hand-classification. R25 reported 1 hit when the documented regex returns 22. The defect is at the same meta-level the R24-predicted "rule-authoring contract" lived at, just one layer higher: the rule is now constraining the **reviewer's own claims**, not just the engineer's fix-round narrative. fix-round-25 should encode this discipline (e.g., add a Gate #9 clause (j) "review-round termination claim re-verification" requiring the reviewer to re-run the full meta-grep + cite the empirical hit count + classify each surviving hit as {realized-drift / exempt-by-regex / scope-out-with-reason}).
>
> Plan Staleness Sentinel post-R26: **1 IMPL-NNN main task closure since R09** (IMPL-063 cascade 2026-05-14 — IMPL-FIX-012 iter-1 sub-iter does not increment counter). Within 10-closure threshold; no staleness advisory triggered.

## End of Review Round 26
