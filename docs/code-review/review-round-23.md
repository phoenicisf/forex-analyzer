# Code Review Round 23

| Field | Value |
|-------|-------|
| **Round** | 23 |
| **Target** | `all` — operator invoked `/impl-review review-round-23` after fix-round-22 closure (commit `746f109`). Verify-only sweep per fix-round-22 Recommendation. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/` + `docs/state/*` + `.claude/rules/*`. Working tree at session start: clean. |
| **Date** | 2026-05-09 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) fix-round-22 §22.1 line-anchor reroute — does the new grep marker `"wire CPipMath into every slot post-RegisterAll"` resolve at `core/Orchestrator.mqh`? (b) §22.2 banner gerund — does `wiring through` re-introduce R21 doubling-defect class? (c) Phase-5 mechanical-gate compliance for fix-round-22 itself. (d) **Gate #9 clause (h) — methodology-rule SCOPE compliance**: was clause (h) applied to ALL bin-1 routing comments with line-anchor brittleness, or only to the 2 cited CSlotBase.mqh sites? Run an independent broader-class sweep against the source tree for the rule's *intent* (load-bearing physical-line anchors with no symbolic fallback). |
| **Plan Staleness Sentinel** | 0 closures since R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor to fix-round-22). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 0 |
| LOW      | 2 |
| **Total**| **3** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No new boundary surface. |
| 2 | Business Logic Correctness | ✅ Pass | Comment-only sweep; production runtime unchanged. fix-round-22 G1 PASS (4534 ms). |
| 3 | Error Handling | ✅ Pass | No regression. |
| 4 | Performance | ✅ Pass | XS-17.1 hot-path rule unchanged. |
| 5 | Over-Engineering | ✅ Pass | Gate #9 clause (h) is a compact rule; no premature framework. |
| 6 | Cross-Service Consistency | ⚠️ **Finding** | **23.1 HIGH** — Gate #9 clause (h) (line-anchor brittleness rule) was applied to the 2 cited CSlotBase.mqh sites only, not to the broader source-tree scope the rule logically governs. Independent intent grep `\\bline [0-9]+\\b` + `:[0-9]+(-[0-9]+)?` source-line citations finds **3 actual line-anchor drift defects** (cited lines no longer point at the cited symbols) + 2 borderline non-compliant sites. Same scope-narrower-than-rule failure mode the R12→R20 chain demonstrated, now manifesting on Gate #9 clause (h). |
| 7 | Test Coverage Gaps | ✅ Pass | No new test surface. |
| 8 | Architecture Compliance | ✅ Pass | Independently verified `core/Orchestrator.mqh:364` grep marker `"wire CPipMath into every slot post-RegisterAll"` exists at destination ✅. fix-round-22 §22.1 reroute is destination-correct on the 2 cited sites. |
| 9 | Technical Design Compliance | ✅ Pass | No api-spec / TD-02..04 drift. |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded-loop pathology. |
| 11 | Empirical AC Closure | ✅ Pass | No new E-AC; IMPL-FIX-004 row unchanged. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox. |

---

## Findings

### Finding 23.1: 🟠 HIGH — Gate #9 clause (h) (line-anchor brittleness rule) was applied to the 2 cited `domain/CSlotBase.mqh` sites only, NOT to the broader source-tree scope the methodology rule logically governs. Independent intent grep finds **3 cited line numbers that have ALREADY drifted off their target symbols** (concrete realized brittleness, not hypothetical) + 2 borderline non-compliant sites. Same SCOPE-NARROWER-THAN-RULE failure mode the R12→R20 chain repeatedly demonstrated — now manifesting on Gate #9 clause (h)'s first verify pass.

**Location:** Multiple files; representative drift sites:

| # | Site | Cite | Actual location | Drift |
|---|------|------|-----------------|-------|
| 1 | `slots/Slot_GO.mqh:15` | `Slot_G.mqh:392: TriggerGOverload currently stubbed false` | `Slot_G.mqh` has `TriggerGOverload` at lines 20, 22, 49, 84, 319 — **none at 392** | ✅ Drifted |
| 2 | `slots/Slot_GO.mqh:99` | `(BR-2.2, currently stubbed false at Slot_G.mqh:392)` | Same as #1 — `Slot_G.mqh:392` does not contain `TriggerGOverload` | ✅ Drifted |
| 3 | `domain/SlotState.mqh:38` | `core/Orchestrator.mqh::OnTradeTransaction (line 791)` | Banner block ends at `:792`; function `void COrchestrator::OnTradeTransaction` is at **line 793**, not 791 | ✅ Drifted (~2 lines) |
| 4 | `core/BootstrapValidator.mqh:615` | `services/RiskManager.mqh:402-415` (no symbolic anchor in cite) | `_ComputeLotForS` body at `:402+` (cite is approximately accurate today) | ⚠️ Load-bearing line range with NO symbol — non-compliant per (h) |
| 5 | `core/Orchestrator.mqh:199` | `(PhoenicisNex.mq5:41)` (no symbolic anchor in cite) | Cited `value-typed global path` at `:41` | ⚠️ Load-bearing line number with NO symbol — non-compliant per (h) |

Reference: fix-round-22 §22.1 narrative claim ("Bin-1 routing comments MUST cite the destination by grep-stable anchor ... NOT by physical line number"); workflow.md Gate #9 clause (h) text; review-round-22 §22.1 Suggested Fix's general-rule framing ("apply to all bin-1 routing comments").

**Code (drift evidence):**
```mql5
// slots/Slot_GO.mqh:14-15  (banner — Slot_G.mqh:392 is dangling)
//| Activation: Orchestrator wiring path (core/Orchestrator.mqh) (CrossSlotCoordinator wires G → GO call)   |
//|   Slot_G.mqh:392: TriggerGOverload currently stubbed false.       |

// slots/Slot_GO.mqh:98-100  (sub-call commentary — Slot_G.mqh:392 is dangling)
//| Phase 1 MVP: GO is invoked sub-call only from G's TriggerGOverload|
//| (BR-2.2, currently stubbed false at Slot_G.mqh:392). This method |

// domain/SlotState.mqh:38  (OnTradeTransaction is at line 793, cite says 791)
   // Populated by core/Orchestrator.mqh::OnTradeTransaction (line 791)

// Independent grep verification (run this round):
$ grep -nE "TriggerGOverload" MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh
20: ...   - On peak detection: TriggerGOverload (BR-8.4 stub call site)
22: ...   Real CCrossSlotCoordinator::TriggerGOverload impl = IMPL-053
49: ... CCrossSlotCoordinator::TriggerGOverload body = IMPL-053 (P4).
84:    //       BR-8.4 TriggerGOverload stub wired here
319: ...      + maxOffset ≥ InpGOverloadMaxOffset → TriggerGOverload stub

# → 0 hits at line 392; cite is dangling.
```

**Problem:**
fix-round-22 §22.1 introduced Gate #9 clause (h) as a **methodology rule** ("Bin-1 routing comments MUST cite the destination by grep-stable anchor ... NOT by physical line number") — meaning the rule applies to every bin-1 routing comment in the source tree, not just the 2 cited sites in the originating finding. The R12→R20 chain that just terminated had this exact failure mode 9 times: rule is authored generally, fix is applied surgically to cited sites only, next reviewer surfaces the rule's broader-class violations.

R22 §22.1 Suggested Fix even named this anti-pattern explicitly:
> "This is the same anti-pattern as embedding `IMPL-053+` literals in slot comments (R12→R20 chain): the literal is correct at edit time but doesn't survive context drift."

But the same anti-pattern just recurred on the rule itself: clause (h) was authored R22-day-1 and applied surgically the same day to 2 sites; R23-day-1 (this round) finds 3 already-drifted line anchors elsewhere — drift that PRECEDES clause (h)'s authoring AND would have been caught by a tree-wide sweep enforcing clause (h)'s intent.

The drift is **realized**, not hypothetical. `Slot_G.mqh:392` does not exist as a TriggerGOverload anchor (the symbol lives at lines 20/22/49/84/319). The fix-round-22 verification regex `grep -nE "line [0-9]+(-[0-9]+)?" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh` was scope-narrowed to one file — exactly the regression class fix-round-15 §9b accidentally introduced (caught by R16 §16.3 + 16.7) — and re-narrowed again here.

This is the **10th iteration** of the scope-narrower-than-defect-class chain. R22 declared chain termination based on the substituted-token axis (no R21 doubling regression — true) but missed that the methodology rule itself had a broader scope than the surgical fix.

**Why This Matters:**
HIGH (not MEDIUM) because the drift is **realized and demonstrable** — a reader following any of the 3 drifted cites lands on a wrong location, breaking the destination-correctness guarantee that the entire R12→R22 chain was constructed to deliver. Sites #4 and #5 are non-realized (today's content matches today's line numbers) but are structurally non-compliant per clause (h)'s text — they're load-bearing line numbers with no symbolic fallback, and the next edit to either file silently desyncs them with no compile-time signal.

The R22 closure narrative explicitly framed itself as a chain-termination round ("R12→R22 chain status: TERMINATED at both axes"). That declaration is **invalid**: a methodology rule that surfaces 3 realized-drift defects on its first verify pass has not terminated; it has surfaced its first wave of pre-existing violations.

**Suggested Fix:**
Tree-wide sweep enforcing Gate #9 clause (h) intent across all bin-1 routing comments:

```bash
# Stage 1 — enumerate candidate line-anchor citations:
grep -rnE "\\b(line [0-9]+(-[0-9]+)?|\\.(mqh|mq5):[0-9]+(-[0-9]+)?)" \
     MQL5/Experts/PhoenicisNex/ \
  | grep -vE "(trade-journal-schema\\.yaml|state-persistence-schema\\.yaml|TD-02 (§|line)|ADR-[0-9]+ (§|line)|MACD line|Signal line)" \
  > /tmp/line-anchor-candidates.txt
# (excluding doc anchors which are governed by a different drift discipline)

# Stage 2 — for each candidate, verify the cited symbol exists at the cited line:
#   - parse `<file>:<line>` or `<symbol> (line N)` form
#   - grep the destination file for the cited symbol
#   - assert symbol's actual line matches cited line ± 2 (allow banner-comment band)

# Stage 3 — sites failing Stage 2 are realized drift; reword to grep marker:
#
#   slots/Slot_GO.mqh:15 →
#     "TriggerGOverload (Slot_G.mqh — grep marker 'BR-8.4 TriggerGOverload
#      stub wired here'; currently stubbed false)"
#
#   slots/Slot_GO.mqh:99 →
#     "(BR-2.2, currently stubbed false at Slot_G.mqh — grep marker
#      'BR-8.4 TriggerGOverload stub wired here')"
#
#   domain/SlotState.mqh:38 →
#     "Populated by core/Orchestrator.mqh::OnTradeTransaction handler"
#     (drop the line number; method name is grep-stable)
#
#   core/BootstrapValidator.mqh:615 →
#     "services/RiskManager.mqh::_ComputeLotForS body — keep in sync
#      if either side changes"
#     (drop the :402-415 range; method name is grep-stable)
#
#   core/Orchestrator.mqh:199 →
#     "fix-round-11 § 11.1 — value-typed global path (single global
#      declaration in PhoenicisNex.mq5 — grep marker 'Single global
#      composition root')"
```

And tighten Gate #9 clause (h) verification regex (per Finding 23.2 below):

```bash
# Replace fix-round-22 §22.1 verification:
#   grep -nE "line [0-9]+(-[0-9]+)?" <file>     # LOOSE — matches "inline 5/3-digit"
# with:
#   grep -nE "\\bline [0-9]+(-[0-9]+)?\\b|\\.(mqh|mq5):[0-9]+(-[0-9]+)?" <tree>
# Then for each surviving hit, verify symbol presence in same comment block.
```

Add to clause (h) the explicit broader-scope post-condition:
> "Verification post-condition (R23 strengthening): the line-anchor sweep MUST run tree-wide (`MQL5/Experts/PhoenicisNex/`), NOT scope-narrowed to the cited file. For each surviving hit, the engineer MUST verify the cited symbol actually exists at the cited line ± 2-line band; sites failing verification are realized drift and MUST be re-anchored."

**Level of Effort:** Medium (~1-2 hours wall-clock — tree-wide enumeration ~50-100 candidate lines, per-site classify {realized drift / non-compliant / compliant doc anchor}, reword 3-5 violations, extend Gate #9 clause (h) verification post-condition).

---

### Finding 23.2: 🔵 LOW — fix-round-22 §22.1 verification regex `grep -nE "line [0-9]+(-[0-9]+)?" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh` is **too loose** — it lacks `\b` word-boundary anchors and matches the substring `line 5` inside `inline 5/3-digit detection` at `CSlotBase.mqh:70` (which is unrelated to source-line citations — it refers to inline 5/3-digit broker arithmetic). The reported "0 hits" claim is incidentally correct only because the matched substring isn't a routing anchor; the regex itself doesn't differentiate.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, Line 70 (false-positive substring `line 5/3-digit`)
- Reference: fix-round-22 §22.1 verification block ("`grep -nE \"line [0-9]+(-[0-9]+)?\"` → 0 hits")

**Code:**
```mql5
// domain/CSlotBase.mqh:69-71
   //    When NULL the protected helpers fall back to inline 5/3-digit
   //    detection (single fallback site eliminates the 19-way drift
   //    Finding 06.1 reported).

// Re-running fix-round-22 §22.1 verification regex this round:
$ grep -nE "line [0-9]+(-[0-9]+)?" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh
70:   //    When NULL the protected helpers fall back to inline 5/3-digit
# → 1 hit (false-positive on "inline 5"); fix-round-22 reported 0 hits.
```

**Problem:**
fix-round-22 §22.1 verification used `grep -nE "line [0-9]+(-[0-9]+)?"` against CSlotBase.mqh and reported "0 hits (no line-number anchors remain)". The regex pattern `line [0-9]+` matches the substring `line 5` inside `inline 5/3-digit` at line 70 — a false positive (the word "inline" is unrelated to source-line citations).

The reported 0-hit count is wrong on this file. Either (a) fix-round-22 ran a different command than the one cited in the report, or (b) the grep version on the engineer's environment defaulted to word-boundary matching, or (c) the report transcribed the wrong number. The substantive defect (no real line-number anchors remaining in CSlotBase.mqh after the reroute) is correctly achieved — but the verification artifact in the fix-round narrative is non-reproducible against the regex literal it cites.

This is a methodology-precision LOW: the verification regex SHOULD be `grep -nE "\\bline [0-9]+(-[0-9]+)?\\b"` to avoid false-positives, OR Gate #9 clause (h)'s post-condition should explicitly state "any hit on the verification regex MUST be classified as routing-anchor or non-routing-anchor before declaring 0 hits — substring matches inside compound words like `inline`, `outline`, `airline`, `pipeline` are non-routing".

**Why This Matters:**
LOW because (a) the substantive sweep was correct on CSlotBase.mqh; (b) the false-positive surfaces only at one site in one file. But the regex precision matters for tree-wide application (Finding 23.1's Suggested Fix) — if the same loose regex is used against the whole `MQL5/Experts/PhoenicisNex/` tree, it will surface dozens of false positives (every `inline`, `pipeline`, `airline`-like compound) that the engineer must hand-classify, increasing the cost of clause (h) enforcement.

**Suggested Fix:**
Tighten Gate #9 clause (h) verification regex with word boundaries:

```bash
# Original (loose):
grep -nE "line [0-9]+(-[0-9]+)?" <file>

# Tightened (R23):
grep -nE "\\bline [0-9]+(-[0-9]+)?\\b" <file>

# Combined with file:line citation form:
grep -rnE "(\\bline [0-9]+(-[0-9]+)?\\b|\\.(mqh|mq5):[0-9]+(-[0-9]+)?)" <tree>
```

And update fix-round-22's narrative footer to acknowledge the false-positive sensitivity (or amend the verification regex retroactively in the workflow.md narrative).

**Level of Effort:** Low (~5 min — regex update in workflow.md; no source code change).

---

### Finding 23.3: 🔵 LOW — `core/Orchestrator.mqh:199` comment cites `(PhoenicisNex.mq5:41)` as the value-typed global declaration site, but the cited line is in the middle of a documentation comment block, not at a global declaration. The actual global declaration appears later in the file. Methodology-borderline non-compliant per Gate #9 clause (h) (load-bearing line number with no symbolic anchor).

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Line 199
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5`, Line 41 (cited destination — actual content: `// Default-constructed (all member pointers NULL); WireServices()`)

**Code:**
```mql5
// core/Orchestrator.mqh:199-200
      // fix-round-11 § 11.1 — value-typed global path (PhoenicisNex.mq5:41)
      // invokes this dtor AFTER MT5's OnDeinit already ran _TeardownAll.

// PhoenicisNex.mq5:39-42 (cited destination)
//--- Single global composition root.
//    Default-constructed (all member pointers NULL); WireServices()
//    invocation gated to OnInit; layered Cleanup pattern per ADR-002.
COrchestrator g_orch;
```

**Problem:**
The cite `(PhoenicisNex.mq5:41)` is a load-bearing line number with no symbolic anchor — clause (h) prefers `(grep marker "Single global composition root")` or `(global g_orch declaration in PhoenicisNex.mq5)`. The actual `g_orch` declaration appears at line 42, not 41 (line 41 is the third line of the doc comment block introducing it). Either (a) the comment intends to reference the doc block (line 41) rather than the declaration (line 42), or (b) the line was correct at fix-round-11-time and has drifted by 1 line.

This is the same defect class as Finding 23.1 sites #4 and #5 — load-bearing line number, no symbol. Raising as a separate LOW because the cite is borderline (off by 1) rather than dangerously dangling like the `Slot_G.mqh:392` sites.

**Why This Matters:**
LOW because the drift is 1 line and the contextual reader can easily locate `g_orch` from the surrounding file. But the methodology demands clause (h) compliance: a cite of `(PhoenicisNex.mq5 — grep marker "Single global composition root")` would be drift-immune AND identical-cost to the line-number form.

**Suggested Fix:**

```mql5
// core/Orchestrator.mqh:199 (revised)
      // fix-round-11 § 11.1 — value-typed global path (PhoenicisNex.mq5
      // — grep marker "Single global composition root"; declaration:
      // `COrchestrator g_orch;`)
```

(Consolidate with Finding 23.1 tree-wide reroute pass.)

**Level of Effort:** Low (~2 min — single comment edit; rolled into Finding 23.1 sweep).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-23.1 | 🟠 HIGH | Methodology-rule SCOPE compliance failure: Gate #9 clause (h) authored R22 + applied surgically R22 to 2 sites, but tree-wide enforcement skipped — 3 realized-drift sites + 2 borderline non-compliant sites surface on R23 verify pass | `slots/Slot_GO.mqh:15,99` + `domain/SlotState.mqh:38` + `core/BootstrapValidator.mqh:615` + `core/Orchestrator.mqh:199` | 10th iteration of the scope-narrower-than-rule failure mode (R12→R20 chain pattern repeating on a meta-level — the rule itself is the new substitution unit); see Finding 23.1 for sweep recipe + clause (h) post-condition strengthening |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 23.1 | Gate #9 clause (h) applied surgically to 2 cited sites; tree-wide enforcement missed → 3 realized-drift line anchors + 2 borderline violations elsewhere | 🟠 HIGH | `slots/Slot_GO.mqh:15,99`; `domain/SlotState.mqh:38`; `core/BootstrapValidator.mqh:615`; `core/Orchestrator.mqh:199` | ea (cross-cutting) | M (~1-2h tree-wide sweep + reroute 3-5 violations + clause (h) post-condition strengthen) |
| 23.2 | fix-round-22 §22.1 verification regex `line [0-9]+(-[0-9]+)?` lacks `\b` word-boundary; matches false-positive `inline 5/3-digit` at CSlotBase.mqh:70 | 🔵 LOW | `domain/CSlotBase.mqh:70` (false-positive substring) | ea-methodology | Low (~5 min — regex tighten in workflow.md) |
| 23.3 | `core/Orchestrator.mqh:199` cites `(PhoenicisNex.mq5:41)` — load-bearing line number, no symbolic anchor; 1-line drift on the actual `g_orch` declaration | 🔵 LOW | `core/Orchestrator.mqh:199` | ea | Low (~2 min — rolled into 23.1 sweep) |

---

## Phase-5 Mechanical Gate Compliance Check (fix-round-22 itself)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | ✅ Pass | 0 hits. |
| 2 | TL;DR ↔ registry recount | ✅ Pass | unchanged from fix-round-21 (49 Active). |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | no Phase × Size matrix change. |
| 4 | Sentinel counter increment | n/a | fix-round, not IMPL-NNN closure. |
| 5 | overview.md sync | ✅ Pass | fix-round-22 paragraph appended to Impl Plan row status. |
| 6 | File integrity (post-Edit-batch) | ✅ Pass | tail clean. |
| 7 | Phase Status Snapshot Notes sweep | n/a | no Phase Status row Notes invalidated. |
| 8 | Narrative-section freshness sweep | n/a | no Open Risks / Next Best Action invalidated. |
| 9a | Originating literal grep | ✅ Pass | line-anchors at CSlotBase.mqh removed. |
| 9b | Broader-class doubling regex | ✅ Pass | `wire[ds]? at .* wiring` → 0 hits (R21 doubling not regressed; gerund `wiring through` does not collide). |
| 9c | Repo-wide intent grep | ⚠️ **Finding 23.1** | The intent of clause (h) is "no load-bearing physical-line anchors". Independent tree-wide grep finds 5 violation candidates; 3 are realized drift. Gate #9c was scope-narrowed to CSlotBase.mqh — the same regression class fix-round-15 §9b accidentally introduced (caught by R16 §16.3 + 16.7). |
| 9d | Closed-task verb-form catalog (dynamic 68-task list) | ✅ Pass (unchanged from fix-round-20). |
| 9e | Closed-task list dynamic derivation | ✅ Pass (unchanged). |
| 9f | Destination-existence verification (R21) | ✅ Pass | `wire CPipMath into every slot post-RegisterAll` grep marker exists at `core/Orchestrator.mqh:364`. |
| 9g | Token-collision pre-check (R21) | ✅ Pass | `wiring through` at 1 banner site; not in any `wire[ds]? at <token>` doubling pattern. |
| 9h | **Line-anchor brittleness rule (R22) — verification regex** | ⚠️ **Finding 23.2** | Verification regex `grep -nE "line [0-9]+(-[0-9]+)?"` matches false-positive `inline 5/3-digit`; reported 0-hit claim is wrong on the regex literal (incidentally correct on the substantive sweep). |
| 9h-scope | **Line-anchor brittleness rule (R22) — tree-wide scope** | ❌ **Finding 23.1 FAIL** | Sweep scope-narrowed to `domain/CSlotBase.mqh`; tree-wide enforcement skipped. 3 realized-drift + 2 borderline violations surface on R23 verify pass. |
| 10 | Stash-clean G1 (R16) | ✅ Pass (post-commit, equivalent to working-tree-clean). |
| 11 | Working-tree clean post-closure | ✅ Pass (post-commit; `git status --porcelain` → 0 lines). |

**Verdict on fix-round-22 mechanical gates:** Gates #1, #2, #3, #5, #6, #9 a/b/d/e/f/g, #10, #11 pass. Gates #9c (repo-wide intent), #9h (verification regex precision), and #9h-scope (tree-wide application) FAIL — all three failures are methodology-rule SCOPE compliance, the same defect class the R12→R20 chain demonstrated 9 times.

---

## Recommendation

Ready for **fix-round-23**. Priority order:

1. **Finding 23.1 (HIGH)** — tree-wide line-anchor sweep enforcing Gate #9 clause (h) intent across `MQL5/Experts/PhoenicisNex/`. Reroute the 3 realized-drift sites (`Slot_GO.mqh:15,99`, `SlotState.mqh:38`) + 2 borderline violations (`BootstrapValidator.mqh:615`, `Orchestrator.mqh:199`) to grep-stable symbolic anchors. Strengthen clause (h) post-condition to mandate tree-wide sweep + symbol-existence verification at cited line ± 2-line band.
2. **Finding 23.2 (LOW)** — tighten Gate #9 clause (h) verification regex to use `\b` word-boundary anchors; amend fix-round-22 narrative footer (or workflow.md inline) to reflect the corrected regex.
3. **Finding 23.3 (LOW)** — roll into Finding 23.1's tree-wide sweep.

> **Reviewer note (R12→R23 recurrence chain — 10th iteration manifest):**
> R22 declared chain termination ("R12→R22 chain status: TERMINATED at both axes"). That declaration was **premature**. The chain has not terminated; it has **shifted scale** — from substituted-token defects (R12-R21) to methodology-rule scope-compliance defects (R22 → R23). The structural failure mode is identical: a rule is authored generally, applied surgically, and the next reviewer surfaces the rule's broader-class violations.
>
> The chain's third axis — **methodology-rule scope compliance** — is now visible:
> - **Catalog axis** — Gate #9d clause (e) (closed-task list dynamic; R20)
> - **Destination axis** — Gate #9 clauses (f) destination-existence + (g) token-collision (R21)
> - **Anchor axis** — Gate #9 clause (h) line-anchor brittleness (R22) — *applied surgically, tree-wide enforcement still pending* (R23 finding)
> - **Methodology-scope axis (NEW)** — every newly-authored Gate #9 clause MUST be verified tree-wide on its first verify pass, NOT scope-narrowed to the cited sites
>
> **Suggested termination test** for fix-round-23: after the tree-wide sweep, re-run a *broader-class meta-grep* on the entire `.claude/rules/workflow.md` Gate #9 clause catalog (a-h) — for each clause, identify its intent regex + run tree-wide + verify 0 violations. Terminate the chain only when ALL clauses verify clean tree-wide simultaneously, not when individual clauses pass surgical sweeps.
>
> **Plan Staleness Sentinel post-R23:** unchanged from R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor to fix-round-22). Sentinel resets on next P4 closure.

## End of Review Round 23
