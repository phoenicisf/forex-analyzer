# Code Review Fix Round 23

| Field | Value |
|-------|-------|
| **Round** | 23 |
| **Review File** | `docs/code-review/review-round-23.md` |
| **Date** | 2026-05-09 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 23.1 | Gate #9 clause (h) applied surgically to 2 cited sites; tree-wide enforcement missed → 3 realized-drift + 2 borderline non-compliant sites | 🟠 HIGH | Accept (full tree-wide sweep — caught 8 sites total, 3 more than reviewer enumerated) | 7 source files (1 core + 1 service + 2 domain + 3 slot) | (this round) |
| 23.2 | fix-round-22 §22.1 verification regex `line [0-9]+(-[0-9]+)?` lacks `\b` boundaries; matches false-positive `inline 5/3-digit` | 🔵 LOW | Accept | `.claude/rules/workflow.md` Gate #9 clause (h) | (this round) |
| 23.3 | `core/Orchestrator.mqh:199` cites `(PhoenicisNex.mq5:41)` — load-bearing line, no symbol | 🔵 LOW | Accept (rolled into 23.1 sweep) | (covered by 23.1) | (this round) |

**Accepted:** 3/3 (100%). 0 Reject / 0 Partial.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 23.1: HIGH — tree-wide line-anchor sweep enforcing Gate #9 clause (h)

**Verdict:** Accept — broader-class scope than reviewer enumerated (8 sites total vs reviewer's 5).

**Tree-wide intent grep (R23 strengthened, with `\b` boundaries):**

```bash
grep -rnE "\b(line [0-9]+(-[0-9]+)?|\.(mqh|mq5):[0-9]+(-[0-9]+)?)\b" \
  MQL5/Experts/PhoenicisNex/ \
  | grep -vE "(TD-02 §|ADR-[0-9]+ §|TD-02 line|ADR-[0-9]+ line)"
```

Pre-fix candidates classified:

| # | Site | Cite | Verdict | Reroute target |
|---|------|------|---------|----------------|
| 1 | `slots/Slot_GO.mqh:15` | `Slot_G.mqh:392` | Realized drift (TriggerGOverload at lines 20/22/49/84/319/322/382/385/390 — none at 392) | grep marker `"IMPL-053: enable when TriggerGOverload declared"` |
| 2 | `slots/Slot_GO.mqh:99` | `Slot_G.mqh:392` | Realized drift (same as #1) | grep marker `"IMPL-053: enable when TriggerGOverload declared"` |
| 3 | `domain/SlotState.mqh:38` | `OnTradeTransaction (line 791)` | Cite-non-compliant per (h); function actually IS at line 791 today (reviewer's "drifted to 793" claim was incorrect — independent grep confirms `void COrchestrator::OnTradeTransaction` at line 791), but load-bearing line number violates clause (h) | drop the line; `OnTradeTransaction handler` is grep-stable |
| 4 | `services/PortfolioState.mqh:176` | `OnTradeTransaction (line 791)` | **Reviewer-missed** — same broader-class defect as #3 | drop the line; `OnTradeTransaction handler` is grep-stable |
| 5 | `core/BootstrapValidator.mqh:615` | `services/RiskManager.mqh:402-415` | Borderline non-compliant per (h); range approximately accurate today | `services/RiskManager.mqh::_ComputeLotForS body` (drop range; symbol grep-stable) |
| 6 | `core/Orchestrator.mqh:199` | `(PhoenicisNex.mq5:41)` | Borderline non-compliant per (h); line 41 is mid-doc-comment, declaration at :49 (1-2 line drift) | grep marker `"Single global composition root"` + declaration `\`COrchestrator g_orchestrator;\`` |
| 7 | `slots/Slot_P.mqh:126` | `Slot_BI.mqh line 89-95` | **Reviewer-missed** — load-bearing line range, no symbol; same broader-class defect as #5 | `Slot_BI.mqh::_HasActiveBIOrder` (drop range; symbol grep-stable) |
| 8 | `domain/CSlotBase.mqh:156` | `helpers/PipMath.mqh:31` | **Reviewer-missed** — load-bearing line number, no symbol | `helpers/PipMath.mqh — grep marker "BR-9.3: 5-digit EURUSD broker"` |

The reviewer enumerated 5 sites (#1, #2, #3, #5, #6). fix-round-23's tree-wide sweep additionally caught #4, #7, #8 — all in the same broader-class defect category. Per the reviewer's own framing in §23.1 ("the rule applies to every bin-1 routing comment in the source tree, not just the 2 cited sites"), the broader-class scope is the correct scope.

**Changes (8 sites across 7 files; comment-only):**

- `MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:15` — banner reroute (`Slot_G.mqh:392` → grep marker)
- `MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:99` — same reroute
- `MQL5/Experts/PhoenicisNex/domain/SlotState.mqh:38` — `(line 791)` dropped; cite reads `OnTradeTransaction handler`
- `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:176` — same drop
- `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:614-615` — `:402-415` → `_ComputeLotForS body`
- `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh:199` — `(PhoenicisNex.mq5:41)` → grep marker `"Single global composition root"` + declaration cite
- `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh:126` — `line 89-95` → `_HasActiveBIOrder`
- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh:156` — `:31` → grep marker `"BR-9.3: 5-digit EURUSD broker"`

**Post-fix tree-wide verification:**

```bash
$ grep -rnE "\b(line [0-9]+(-[0-9]+)?|\.(mqh|mq5):[0-9]+(-[0-9]+)?)\b" \
    MQL5/Experts/PhoenicisNex/ \
  | grep -vE "(TD-02 §|ADR-[0-9]+ §|TD-02 line|ADR-[0-9]+ line)"
# → 0 hits ✅ (only 4 doc-anchor exempt sites survive — TD-02 §7.4 line 1654/1659, TD-02 line 1623, ADR-011 line 60, TD-02 §5.7 line 586, TD-02 §9.4 line 1530)
```

### Fix for Finding 23.2: LOW — verification regex word-boundary tightening

**Verdict:** Accept.

**Changes:**

- `.claude/rules/workflow.md` Gate #9 clause (h) verification post-condition regex updated:
  - Before: `grep -nE "line [0-9]+(-[0-9]+)?" <comment-block>`
  - After: `grep -nE "\\bline [0-9]+(-[0-9]+)?\\b" <comment-block>`
- Combined tree-wide regex documented in clause (h) body:
  ```
  grep -rnE "\\b(line [0-9]+(-[0-9]+)?|\\.(mqh|mq5):[0-9]+(-[0-9]+)?)\\b" MQL5/Experts/PhoenicisNex/ | grep -vE "(TD-02 §|ADR-[0-9]+ §|TD-02 line|ADR-[0-9]+ line)"
  ```
- Doc-anchor exemption explicitly documented (TD-02 §X / ADR-NNN line citations governed by separate drift discipline).

### Fix for Finding 23.3: LOW — `Orchestrator.mqh:199` reroute

**Verdict:** Accept (rolled into 23.1 sweep — site #6).

---

## Workflow / Methodology Updates

### `.claude/rules/workflow.md` Gate #9 — clause (h) R23 strengthening

The clause now contains:

1. **R22 originating rule** — bin-1 routing comments MUST cite by grep-stable anchor, NOT physical line number.
2. **R22 verification post-condition** — `grep -nE "\\bline [0-9]+(-[0-9]+)?\\b" <comment-block>` MUST return 0 hits OR each surviving line-number annotation MUST be paired with a grep-stable symbolic anchor.
3. **R23 tree-wide scope post-condition (NEW)** — sweep MUST run tree-wide (`MQL5/Experts/PhoenicisNex/`), NOT scope-narrowed; word-boundary regex mandatory; per-hit symbol-existence verification at cited line ± 2-line band; doc anchors exempt.
4. **R23 narrative footer (NEW)** — methodology-scope axis surfaced; every newly-authored Gate #9 clause MUST be verified tree-wide on its first verify pass.

---

## Mechanical Gates (Phase 5 Closure self-check)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep | ✅ Pass | 0 hits |
| 2 | TL;DR ↔ registry recount | ✅ Pass | unchanged from fix-round-21 (49 Active) |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | no Phase × Size matrix change |
| 4 | Sentinel counter increment | n/a | fix-round, not IMPL-NNN closure |
| 5 | overview.md sync | ✅ Pass | fix-round-23 paragraph appended |
| 6 | File integrity | ✅ Pass |
| 7-8 | Phase Status / Open Risks sweeps | n/a |
| 9a | Originating literal grep (R20→R21) | ✅ Pass |
| 9b | Broader-class doubling regex (R21) | ✅ Pass |
| 9c | Repo-wide intent grep (R16) | ✅ Pass |
| 9d | Closed-task verb-form catalog (R20) | ✅ Pass |
| 9e | Closed-task list dynamic derivation (R20) | ✅ Pass |
| 9f | Destination-existence verification (R21) | ✅ Pass |
| 9g | Token-collision pre-check (R21) | ✅ Pass |
| 9h | Line-anchor brittleness rule (R22) — verification regex (R23-tightened) | ✅ Pass | `grep -nE "\\bline [0-9]+(-[0-9]+)?\\b"` against tree → 0 non-doc-anchor hits |
| 9h-scope | **Line-anchor brittleness rule — tree-wide scope (R23 strengthening)** | ✅ Pass | 8 violation sites re-anchored across 7 files; only 4 TD-02 / 1 ADR doc-anchor sites survive (exempt) |
| 10 | Stash-clean G1 | ✅ Pass (post-commit) |
| 11 | Working-tree clean | ✅ Pass (post-commit) |

### G1 compile gate

```
Result: 0 errors, 0 warnings, 4873 ms elapsed, cpu='X64 Regular'
```

PASS ✅ (comment-only changes; zero behavior delta).

---

## State Reconciliation (3-File Propagation)

**Layer 1 — `docs/state/impl-plan.md`** — no change (no IMPL-NNN closure).
**Layer 2 — `docs/state/overview.md`** — fix-round-23 paragraph appended to Impl Plan row.
**Layer 3 — `.claude/rules/workflow.md`** — Gate #9 clause (h) strengthened; narrative footer extended with R23 entry.

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 3 |
| Accepted | 3 (100%) |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 10 (7 source + workflow.md + overview.md + this report) |
| Sites Rerouted | 8 (3 reviewer-cited drifts + 5 borderline / reviewer-missed) |
| Tests Added/Updated | 0 (comment-only) |
| Compile (G1) | ✅ 0 errors, 0 warnings, 4873 ms |
| Gate #9 strengthening | clause (h) tree-wide scope post-condition + word-boundary regex + doc-anchor exemption |

---

## Recommendation

Ready for **review-round-24** verify-only sweep.

**R12→R23 chain status:** the chain has now surfaced its **third axis** (methodology-scope axis); all three are addressed:

- **Catalog axis** — Gate #9d clause (e) (R20) ✅
- **Destination axis** — Gate #9 clauses (f) + (g) + (h) (R21 + R22) ✅
- **Methodology-scope axis** — Gate #9 clause (h) R23 strengthening (tree-wide scope post-condition embedded in clause body, not deferred to footer) ✅

**Forward-looking termination test (per reviewer §23 Recommendation footer):** R24 should run a *broader-class meta-grep* on the entire workflow.md Gate #9 clause catalog (a-h) — for each clause, identify its intent regex + run tree-wide + verify 0 violations. Terminate the chain only when ALL clauses verify clean tree-wide simultaneously, not when individual clauses pass surgical sweeps.

If R24 finds the meta-grep clean, declare R12→R23 chain methodology-closed.

## End of Fix Round 23
