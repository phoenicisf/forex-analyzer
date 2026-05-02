# Implementation Plan Rebuttal Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Claim Review** | `claim-review-03.md` |
| **Date** | 2026-05-02 |
| **SKILLs** | andm-impl-plan-defender, code-review |
| **Defender** | Implementation Plan Defender (Principal Tech Lead) |
| **Plan version pre-rebuttal** | Round 02 patched + reviewer round-03 audit (state-hygiene focus) |
| **Plan version post-rebuttal** | Round 03 patched (this rebuttal) |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 3 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` (3 edit clusters: top callout `Action ถัดไป` + TL;DR `last action` + Next Best Action checklist · Plan Staleness Sentinel · Mid-Phase Audit Log row append)
- `docs/state/overview.md` (Impl Plan row status `Round 02` → `Round 03` + Impl Tasks row "Plan QA cycle complete (round 03)")

**Tasks split:** 0
**Phase reassignments:** 0
**Registry rows added/closed:** 0
**Escalations filed:** 0
**Forward references introduced:** 0
**Forbidden closure pattern grep post-fix:** 0 hits ✅
**Stale "review pending / none yet / commit pending / awaiting review" markers post-fix:** 0 hits ✅

**Sanity checks (per defender SKILL § Sanity Checks):**
- Accept rate = 100% (3/3). Three rounds of 100% accept indicates reviewer is high-signal — each round catches a distinct propagation defect class that defender genuinely missed. No defensive bias; no over-acceptance.
- Round 02 promised "convention going forward: defender writes audit-log row when action = rebuttal close". Round 03 reviewer caught **3 more** stale readiness markers — the convention covered audit log itself but didn't extend to (a) top callout `Action ถัดไป`, (b) `Next Best Action` checked-box, (c) Plan Staleness Sentinel, (d) `last action` line drift after each rebuttal. **This rebuttal extends the convention** — see Defender Self-Correction below.
- 0 CRITICAL findings sustained across 3 rounds.

---

## Claim Responses

### Claim 03.1: 🟡 MEDIUM — Top-level next action still sends operator back into `/impl-plan-review all` after Ready verdict

**Verdict:** Accept

**Rationale:** Reviewer is correct. Plan first-cut authored these strings before any rebuttal closed (when `/impl-plan-review all` was the legitimate next action). Round 01 changed callout title (`At-a-Glance` → `TL;DR / At-a-Glance`); round 02 changed the `last action` line content — but **neither round touched line 7 `Action ถัดไป` or the line-40 checked-box `Next Best Action` row**. Result: stakeholder skim path internally contradictory — top says "do plan review", `last action` says "rebuttal-01 closed" (already stale by R02), `overview.md § Impl Plan` says "Ready". `/next` Check 5.X reads top callout first — would mis-recommend re-review.

**Changes Made:**
- File: `docs/state/impl-plan.md` line 7 (TL;DR callout `Action ถัดไป`)
   - **Before:** `> **Action ถัดไป:** \`/impl-plan-review all\` (mandatory plan QA cycle ก่อน start P1) → จากนั้น \`/impl-task IMPL-001\``
   - **After:** `> **Action ถัดไป:** \`/impl-task IMPL-001\` (XS \`[ea]\` — folder structure + \`bootstrap_smoke.ini\` scaffold); IMPL-046 (atomic-write spike) parallelizable ASAP after IMPL-001+IMPL-010 land`
- File: `docs/state/impl-plan.md` § Next Best Action (lines 40-43)
   - **Before:** `☑ **Plan QA loop — \`/impl-plan-review all\`** (mandatory ...)` / `☐ Continue Track A — recommended task: **IMPL-001** ... once review verdict ✅`
   - **After:** `☑ **Continue Track A — \`/impl-task IMPL-001\`** ... Plan QA cycle ✅ complete after rebuttal rounds 01→02→03 (verdict: Ready for Implementation Execution per claim-review-03.md + rebuttal-round-03.md). IMPL-046 ... parallelizable ASAP after IMPL-001+IMPL-010 land` / `☐ Plan QA loop — complete; re-run \`/impl-plan-review all\` only if plan changes materially OR Plan Staleness Sentinel triggers (>30d + ≥10 task closures since last review)`
- Evidence (post-fix grep): `grep -nE "awaiting \`/impl-plan-review|commit pending|review pending"` on `impl-plan.md` = **0 hits** ✅
- Cascaded: zero — narrative reordering only; no task body / phase / dependency change.

---

### Claim 03.2: 🟡 MEDIUM — Plan Staleness Sentinel still records "review pending" after two completed review rounds

**Verdict:** Accept (with state-hygiene convention extension)

**Rationale:** Reviewer is correct. Sentinel was scaffolded in plan first-cut with all three fields = pending placeholders. Neither rebuttal-01 nor rebuttal-02 touched it because the defender's mental model treated "audit log row = rebuttal closure marker" without realizing the sentinel is a **separate** marker that `/next` Check 5.8 reads independently. Same propagation defect class as round 02 Claim 02.1 caught for the audit-log row, recurring at the sentinel.

**Changes Made:**
- File: `docs/state/impl-plan.md` § Plan Staleness Sentinel (lines 1638-1642)
- What changed (3 fields + interpretation paragraph):
   - **Plan approved on:** `_pending — awaiting \`/impl-plan-review all\` approval_` → `2026-05-02 — after \`claim-review-02.md\` + \`rebuttal-round-02.md\` (3/3 Accept; verdict ✅ Ready for Implementation Execution)`
   - **Last review on:** `_none yet_` → `2026-05-02 — \`claim-review-03.md\` (state-hygiene sweep) + \`rebuttal-round-03.md\` (3/3 Accept; readiness markers reconciled)`
   - **Closures since last review:** `0` (unchanged — no IMPL-NNN tasks have closed yet)
   - **Interpretation paragraph:** changed `Currently: review pending; staleness check inactive until first review.` → `Currently: approved + reviewed; staleness check **inactive** until either condition fires (≥ 2026-06-01 calendar date OR ≥ 10 IMPL-NNN closures since 2026-05-02).` — gives `/next` Check 5.8 explicit boundary conditions to evaluate.
- Evidence (post-fix grep): `grep -nE "review pending|none yet"` on `impl-plan.md` = **0 hits** ✅
- Cascaded: zero — sentinel is internal-to-plan metadata; doesn't trigger overview.md or registry edits.

**Plan-approved-on field nuance:** reviewer's recommended fix offered two readings — set to `claim-review-02.md` if no round-03 rebuttal runs, OR `claim-review-03.md` if it does. Defender chose the **claim-review-02.md** marker for `Plan approved on` (because the substantive plan-quality verdict was issued at round 02 — round 03 was a state-hygiene sweep, not a planning rework) and **claim-review-03.md** for `Last review on` (most recent review touchpoint per `/next` Check 5.8 semantics). This separation is intentional + matches the reviewer's first option.

---

### Claim 03.3: 🔵 LOW — Round-02 closure not propagated to every readiness marker

**Verdict:** Accept

**Rationale:** Reviewer is correct. Round 02 fix for Claim 02.1 used the reviewer's exact suggested diff which only mentioned "rebuttal-round-01 closed" because that was the most recent closure when round 02 reviewer authored the diff. After defender **closed** round 02 itself, defender forgot to bump the same line again to reflect round 02 closure. Same omission applied to `overview.md § Impl Tasks` row ("round 01 = ✅..."). Recurrence of the State Reconciliation gap that round 02 Claim 02.1 caught — same propagation defect class, different markers.

**Changes Made:**
- File: `docs/state/impl-plan.md` line 9 (TL;DR `Last updated` / `last action`)
   - **Before:** `> **Last updated:** 2026-05-02 · last action: rebuttal-round-01 closed (7 Accept / 0 Partial / 0 Reject); plan ready for \`/impl-task IMPL-001\``
   - **After:** `> **Last updated:** 2026-05-02 · last action: rebuttal-round-03 closed (3 Accept / 0 Partial / 0 Reject — state-hygiene sweep); plan approved + ready for \`/impl-task IMPL-001\``
   - Note: chose round 03 (most recent closure) rather than round 02 because this rebuttal IS round 03; using round 02 would re-introduce the same 1-round-stale defect at next review.
- File: `docs/state/overview.md` line 20 (Impl Tasks row)
   - **Before:** `Plan QA cycle complete (round 01 = ✅ Ready for Implementation Execution).`
   - **After:** `Plan QA cycle complete (round 03 = ✅ Ready for Implementation Execution per \`claim-review-03.md\` + \`rebuttal-round-03.md\`).`
- Evidence (post-fix grep): `grep -E "round 0[12] = ✅"` on `overview.md` = **0 hits** ✅
- Cascaded: zero — both edits are derived-view markers.

---

## Defender Self-Correction (cumulative across rounds)

This is round 3 of "defender misses propagation; reviewer catches it". Pattern recognition warrants a permanent rule extension. **State Reconciliation Discipline (defender side) — extended convention going forward:**

> **When closing any rebuttal round N, defender MUST update ALL of the following markers (single readiness-marker sweep):**
>
> 1. `impl-plan.md` line 9 — TL;DR `Last updated` / `last action` line → reflect round N closure
> 2. `impl-plan.md` § Action ถัดไป (top callout) → next-action concrete; remove `/impl-plan-review` if Ready
> 3. `impl-plan.md` § Next Best Action checked-box (☑) → checked = current actual next action; unchecked Plan QA row = "complete; re-run only if X"
> 4. `impl-plan.md` § Plan Staleness Sentinel → 3 fields populated (`Plan approved on`, `Last review on`, `Closures since last review`)
> 5. `impl-plan.md` § Mid-Phase Audit Log → append row for round N closure
> 6. `overview.md § Impl Plan` row → status field + closure paragraph appended
> 7. `overview.md § Impl Tasks` row → "Plan QA cycle complete (round N = ✅ ...)" reference
>
> **Verification grep (run before declaring rebuttal complete):**
> ```
> grep -nE "awaiting \`/impl-plan-review|commit pending|review pending|none yet|round 0[1..N-1] = ✅" docs/state/{impl-plan,overview}.md
> ```
> Must return **0 hits** — any hit = stale marker; fix before closing the round.

**Rounds 01-02 did not have this convention.** Round 03 establishes + applies it. Future rebuttals (none expected) would invoke the same sweep.

---

## Cascaded Changes

> Changes ที่ **ไม่ได้** cite ใน claims โดยตรง — propagation effects + housekeeping.

1. **`docs/state/overview.md` § Impl Plan row:** status field updated `✅ Complete + Rebuttal Round 02` → `✅ Complete + Rebuttal Round 03`; rebuttal-03 closure paragraph appended (per state-reconciliation convention extended this round).
2. **`docs/state/overview.md` § Impl Tasks row:** "round 01" reference bumped to "round 03" (Claim 03.3 second site).
3. **No Phase × Size matrix update:** task count remains 68; size totals unchanged.
4. **No Phase Dependency Graph re-render:** no phase reassignments.
5. **No SD Hint Alignment audit trail update:** classification ✅/⚠️/🔴/◻️ tally unchanged (67/1/0/0).
6. **No registry seeding:** both registries empty.
7. **No forward references introduced.**
8. **No forbidden closure pattern introduced** — grep sustained 0 hits across rounds 01 → 02 → 03.
9. **Mid-Phase Audit Log:** now has 4 rows (first cut + rebuttal-01 + rebuttal-02 + rebuttal-03). Defender writes; engineer ratifies on commit.

### Recommended hardening (out of rebuttal scope) — for user follow-up

**Re: Claim 01.3 propagation (carried over from rebuttal-round-01.md):** invoke `/amend td` to extend scope-tag glossary into `CLAUDE.md §3` + `.claude/rules/ea.md` + `.claude/stack.json § service_kinds`. **Status:** still pending; not re-flagged in round 02 or round 03 (already documented in plan's Scope Tags Glossary footer line referencing `/amend td`). Non-blocking; surfaces only when first `[ea-qa]` task (IMPL-061) starts in P4.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (3/3) | 3 distinct readiness-marker propagation gaps; all valid (defender genuinely missed each one). Pattern across 3 rounds = "reviewer high-signal, defender propagation-discipline maturing"; reflected by Defender Self-Correction § convention extension above |
| Critical Fixes | 0 | Sustained 0 CRITICAL across 3 rounds + 0 HIGH across 2 rounds + 0 MEDIUM at MEDIUM ceiling = 2 (down from 4 in R01 + 1 in R02; up to 2 in R03 because reviewer scoped 2 readiness markers as MEDIUM rather than LOW) |
| Tasks Split | 0 | None warranted |
| Phase Reassignments | 0 | None warranted |
| Net Improvement | State automation safety + propagation discipline codified | (1) `/next` Check 5.8 + Check 5.X now have correct sentinel + top-callout inputs (Claims 03.1 + 03.2); (2) no stale "round 01" or "round 02" derived-marker reference remains anywhere (Claim 03.3); (3) **Defender Self-Correction §** establishes 7-marker sweep convention for future rebuttals — converts implicit propagation rule into explicit checklist + verification grep |
| Escalations | 0 items | None |
| Remaining Gaps | 1 advisory carried | Claim 01.3 hardening (`/amend td` for scope-tag propagation) — still pending, still non-blocking |

**Convergence trend:**
- Round 01: 7 findings (4 MEDIUM / 3 LOW) → 7 Accept · plan substantive defects
- Round 02: 3 findings (1 MEDIUM / 2 LOW) → 3 Accept · cleanup loose-ends + parity gap
- Round 03: 3 findings (2 MEDIUM / 1 LOW) → 3 Accept · state-hygiene + readiness markers
- **Round 04 projected:** 0 findings expected (defender's 7-marker sweep convention should preempt the readiness-marker class; no other known pattern). Optional verify-only sweep available if user wants explicit certification.

---

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all 3 round-03 findings resolved + readiness markers fully reconciled across 7 sites + Defender Self-Correction convention codified to prevent recurrence. Plan is ready for `/impl-task IMPL-001` and any `/next` invocation will read consistent metadata.
- [ ] 🔁 **Request Re-Review** — N/A. All round-03 changes are localized + grep-verified (0 forbidden patterns + 0 stale-pending markers + 0 round-01-or-02-only derived references + 68 tasks intact). Optional round-04 verify-only sweep available if user wants explicit certification stamp; defender estimates "no further substantive findings expected; convention codification should hold."
- [ ] ⛔ **Needs Stakeholder Input** — N/A.

**Engineer next action:** `/impl-task IMPL-001` (XS [ea] — folder structure scaffold + `bootstrap_smoke.ini` stub).

— Implementation Plan Defender (Principal Tech Lead)
2026-05-02
