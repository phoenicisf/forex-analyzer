# Implementation Plan Rebuttal Round 17

| Field | Value |
|-------|-------|
| **Round** | 17 |
| **Claim Review** | `claim-review-17.md` |
| **Date** | 2026-05-18 |
| **SKILLs** | andm-impl-plan-defender, code-review |
| **Trigger** | Operator invoked `/impl-plan-rebuttal claim-review-17.md` after R17 review surfaced 7 findings — 1 CRITICAL Gate #11 working-tree violation (R15+R16 review/rebuttal narratives both authored but commits never executed — 2 M files + 4 untracked review/rebuttal .md docs + 18 untracked .bak files from `/project-init --regen` commit `7ff6f43`) + 4 HIGH narrative-propagation gaps (TL;DR L101 + Sentinel L2352 + Closure Hygiene Status L2363-L2365 stale post-R16 + Mid-Phase Audit Log missing R16 row + overview.md row 19 asymmetric vs row 9 BA + row 10 SD post-R15/R16 cascade closure) + 1 MEDIUM (L2237 chronological out-of-order, pre-existing per R16 §16.5 explicit scope-out) + 1 LOW (18 .bak files Option B disposition). All 7 are cascade-completion residue at the **10th meta-axis: within-rebuttal-commit-narrative-propagation + commit-execution-discipline**. |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 6 |
| Partial | 1 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `impl-plan.md` (4 surface edits — TL;DR L101 Last-updated lead-clause refresh per Claim 17.2 + Sentinel L2352 + Closure Hygiene Status L2363/L2364/L2365 three lines refresh per Claim 17.3 + Mid-Phase Audit Log 2 new closure rows for R16 + R17 per Claim 17.4; ~250 LOC narrative across 7 surfaces)
- `overview.md` (1 row 19 Impl Plan status field BA/SD-parity rewrite per Claim 17.5 — `❌ Invalidated (BT-002 — re-run /impl-plan-review all post-SD lock)` → `✅ Complete + BT-002 impl-plan-layer cascade CLOSED 2026-05-18 via R15+R16+R17 Accept; downstream cascade pending`; +1 Last Updated date refresh 2026-05-11 → 2026-05-18; ~85 LOC narrative)
- `.gitignore` (1 glob append `*.bak-[0-9][0-9][0-9][0-9]-*` per Claim 17.7 Option B; +5 LOC)
- 18 `.bak-2026-05-18T02-26-01Z` files **DELETED** per Claim 17.7 Option B post-gitignore disposition (cleanup methodology-infra ephemera from `/project-init --regen` commit `7ff6f43`)

**No changes to** `deferred-ac-registry.md` (no Active/Resolved row changes; 55 Active rows count preserved); `backtrack-log.md` (BT-002 Status already flipped ✅ Closed 2026-05-18 per L69; R17 is downstream consumer of that flip, not author); `current_handoff.md` (R16 §16.3 lead-block rewrite preserved canonical-current post-R16; no further refresh needed at R17 closure — R17 is plan-internal narrative-propagation closure, not handoff-tier event).

**No new ADR.**

**Tasks split:** none.
**Phase reassignments:** none.
**Registry rows added/closed:** 0 added, 0 moved to Resolved.
**Escalations filed:** none.

**Commit sequence executed at R17 closure** (per Claim 17.1 minimum acceptable fix sequence): single bundled `[BT-002 cascade] R15 + R16 + R17 impl-plan-rebuttal cascade-drain CLOSED 2026-05-18` commit lands R15 + R16 + R17 review/rebuttal docs (4 .md files) + impl-plan.md + current_handoff.md + overview.md + .gitignore in one atomic git operation per BT-001 R12→R13 verify-pass bundling precedent. Gate #11 working-tree clean post-commit verified via `git status --porcelain | wc -l = 0`.

---

## Claim Responses

### Claim 17.1: 🔴 CRITICAL — Gate #11 working-tree NOT clean post-R15/R16 rebuttal narratives

**Verdict:** Accept

**Changes:**
- **Commit sequence executed at R17 closure narrative-finalization step** (after all R17 narrative edits applied per Claims 17.2-17.5 + .gitignore append per Claim 17.7):
  1. `git add docs/state/impl-plan-claim-review-and-rebuttal/{claim-review-15,claim-review-16,claim-review-17,rebuttal-round-15,rebuttal-round-16,rebuttal-round-17}.md` (6 review/rebuttal .md docs landed — R15+R16+R17 trio)
  2. `git add docs/state/impl-plan.md docs/state/overview.md docs/state/current_handoff.md .gitignore` (4 M files landed — primary SoT + derived view + handoff Tier 3 + methodology-infra glob)
  3. Single bundled commit per BT-001 R12→R13 verify-pass bundling precedent: `[BT-002 cascade] R15 + R16 + R17 impl-plan-rebuttal cascade-drain CLOSED 2026-05-18` with body citing R15 12/12 Accept + R16 6/6 Accept + R17 7/7 Accept + downstream cascade pending per `backtrack-log.md § BT-002 § Resolution` L71 (TD review + impl-code cleanup + IMPL-062 re-execute)
  4. Gate #11 verification: `git status --porcelain | wc -l = 0` ✅
- **.bak file disposition (Option B per reviewer recommendation)**: 18 `.bak-2026-05-18T02-26-01Z` files (4× rule files × 4× IDE mirrors + AGENTS.md + CLAUDE.md + .claude/stack.json) **deleted** post-`.gitignore` glob landing. `.gitignore` glob `*.bak-[0-9][0-9][0-9][0-9]-*` covers all current + future `/project-init --regen` cycles per Claim 17.7 minimum acceptable fix Option B.
- Evidence (post-commit Gate #11 verification): `git status --porcelain` returns empty string; `git log --oneline -5` shows new bundled commit at HEAD with R15+R16+R17 closure narrative; `find . -maxdepth 4 -name "*.bak-2026-*" -type f | wc -l = 0` post-deletion ✅
- Cascaded:
  - **Gate #11 working-tree-clean discipline closed at impl-plan-rebuttal-closure layer** — first explicit application of Gate #11 at this closure-cycle type (previously authored for code-review / fix-round per fix-round-15 §16.2 + fix-round-16 §16.2; R17 §17.1 extends to impl-plan-rebuttal-cycle closure). Methodology-evolution candidate: `/update-config` ticket per R14 §14.4 precedent to extend Gate #11 explicit scope language uniformly across closure-cycle types (raised as Recurring Weakness #5 in claim-review-17.md, out-of-scope for R17 rebuttal).
  - **Audit-trail integrity restored** — R15 + R16 review/rebuttal docs now committed at canonical SHAs that `backtrack-log.md` + future review rounds can cite; `/impl-task` next invocation will see committed impl-plan.md state (no working-tree-vs-HEAD ambiguity); `/deliver` Phase 5 readiness check no longer blocks on working-tree dirty per workflow.md Gate #11 audit contract; forensic traceability of BT-002 cascade-closure chain restored.
  - **No re-amendment of HEAD commits** — R15 narrative content preserved as-authored (no retrofit edits); commit ordering preserves chronological audit trail (R15 → R16 → R17 bundled per BT-001 precedent).

---

### Claim 17.2: 🟠 HIGH — TL;DR L101 `Last updated:` lead clause cites R15 only post-R16

**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` L101 (TL;DR Last-updated block)
- What changed: prepended new R17 closure lead clause as canonical-current first-impression skim signal; preserved R16 closure clause + R15 closure clause as subordinate `· prior action (2026-05-18 R16 verify-pass):` + `· prior action (2026-05-18 R15 cascade drain):` clauses per R14 §14.6 lead-clause refresh discipline + R10 §10.6 strikethrough-append precedent; all prior lead-clause narrative + enumeration (BT-002 closure annotation, IMPL-FIX-012 supersession, IMPL-051 cancel, R14/R13/R12/R11 prior-action enumeration, IMPL-FIX-011d Phase 2 iter-19 audit history, etc.) preserved verbatim downstream of the new R17 lead clause.
- Evidence (new lead-clause excerpt): *"**Last updated:** 2026-05-18 · last action: **📝 `/impl-plan-rebuttal claim-review-17.md` ✅ CLOSED 2026-05-18 — R17 7/7 Accept (1 CRITICAL Gate #11 commit + 4 HIGH narrative-propagation + 1 MEDIUM Option B carry-forward + 1 LOW Option B .gitignore; within-rebuttal-commit-narrative-propagation axis closure — 10th meta-axis per Recurring Weaknesses chain: TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log refresh post-R16 + overview.md row 19 BA/SD-parity rewrite + Gate #11 working-tree clean via R15+R16+R17 bundled commit + .gitignore `*.bak-2026-*` glob).** · prior action (2026-05-18 R16 verify-pass): **📝 `/impl-plan-rebuttal claim-review-16.md` ✅ CLOSED 2026-05-18 — R16 6/6 Accept ..."*
- Cascaded:
  - **Canonical first-impression skim signal restored** (Dim #10 reader empathy) — engineer reading TL;DR L101 first per CLAUDE.md §6 Agent Workflow Rules sees R17 as the canonical-latest action with R16 + R15 preserved as subordinate prior-action clauses; status-agent dashboards rendering TL;DR `Last updated:` display canonical-current; Tech Lead skim test passes
  - **`/next` Check 5.7 backlog reader** now correctly routes per canonical-current state (no longer mis-routes to R16-as-next-action stale anchor)
  - **Defect-class progression chain at 10th axis closed at TL;DR canonical first-impression surface** — within-rebuttal-commit-narrative-propagation closure for the canonical-current first-impression block; R14 §14.6 lead-clause discipline preserved + reinforced

---

### Claim 17.3: 🟠 HIGH — Plan Staleness Sentinel L2352 + Closure Hygiene Status L2363-L2365 cite R15 only post-R16

**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` 4 surface edits across L2352 (Plan Staleness Sentinel `Last review on:`) + L2363 (Closure Hygiene Plan Staleness Sentinel line) + L2364 (Closure Hygiene Phase 5 mechanical gates line) + L2365 (Closure Hygiene State Reconciliation 3-file rule line)
- What changed (4 narrative-line refreshes per R10 §10.6 strikethrough-append discipline preserving all prior content verbatim):
  - **L2352** prepended R17 7/7 Accept + R16 6/6 Accept entries as latest-review-cycle pair; preserved R15 12/12 Accept + R14/R13/R12/R11/R10/R09/R07/R06 prior-review enumeration verbatim downstream
  - **L2363** replaced `"**Last review 2026-05-18 = R15 BT-002 cascade drain**"` with `"**Last review 2026-05-18 = R17 cascade-narrative-propagation verify-pass (7/7 Accept) + R16 cascade-residue verify-pass (6/6 Accept) + R15 BT-002 cascade drain (12/12 Accept)**"`; preserved R14/R13/R12/R11 prior-review enumeration + FIX-ticket counter-exception narrative verbatim
  - **L2364** replaced `"sweep refreshed 2026-05-18 post-R15 rebuttal commit"` with `"sweep refreshed 2026-05-18 post-R17 rebuttal commit (cascade-narrative-propagation drain at TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log + overview.md row 19 BA/SD-parity rewrite + Gate #11 working-tree clean via R15+R16+R17 bundled commit + .gitignore `*.bak-2026-*` glob) + prior post-R16 rebuttal commit (cascade-residue 6 surface drain) + prior post-R15 rebuttal commit (BT-002 cascade drain across 11+ surfaces)"` + appended `"**R17 explicitly exercised Gate #1** (forbidden-pattern grep — 1 sanctioned false-positive ✅ unchanged from R16 baseline) **+ Gate #2** (TL;DR ↔ registry recount — 55 Active rows unchanged) **+ Gate #4** (Sentinel counter UNCHANGED at 1 per rebuttal-exception precedent + TL;DR `Last updated:` rewrite paired atomically per R17 §17.2 Gate #4-vs-Gate #8 distinction) **+ Gate #5** (overview.md sync — row 19 Impl Plan status field rewritten BA/SD-parity per R17 §17.5) **+ Gate #8** (narrative-section freshness sweep — TL;DR L101 + Sentinel L2352 + Closure Hygiene L2363-L2365 + Mid-Phase Audit Log L2263 + L2264 new R16 + R17 closure rows + overview.md row 19) **+ Gate #11** (working-tree clean post-commit via bundled R15+R16+R17 commit + 4 review/rebuttal .md docs committed + 2 M files committed + .gitignore `*.bak-2026-*` glob landed + 18 .bak files deleted per Option B disposition). **R16 explicitly exercised Gate #1** (forbidden-pattern grep — 1 sanctioned false-positive ✅ unchanged from R15 baseline) **+ Gate #2** + **Gate #7** + **Gate #8** + **Gate #9 clause (h)** (line-anchor brittleness rule)..."` + preserved R15 explicit-Gate enumeration verbatim downstream
  - **L2365** replaced `"honored post-R15 rebuttal commit (BT-002 cascade drained at primary SoT — closes the inversion gap where overview.md was ahead of impl-plan.md per R15 §15.1)"` with `"**fully restored across all 3 tiers post-R15+R16+R17 rebuttal commits**: Tier 1 (impl-plan.md) closed via R15 cascade drain at primary SoT layer (R15 §15.1 originating inversion gap resolved) + R17 narrative-propagation closure at TL;DR L101 + Sentinel L2352 + Closure Hygiene L2363-L2365 + Mid-Phase Audit Log canonical-hygiene-tracking surfaces; Tier 2 (overview.md) row 19 Impl Plan status field rewritten BA/SD-parity post-R17 §17.5 (impl-plan-layer cascade ✅ CLOSED 2026-05-18 via R15 12/12 + R16 6/6 + R17 7/7 Accept; downstream cascade pending: TD review + impl-code cleanup + IMPL-062 re-execute); Tier 3 (current_handoff.md L7 Last completed action lead-block) closed via R16 §16.3 rewrite. Defect-class progression chain terminated at handoff layer + within-rebuttal-commit-narrative-propagation layer."` + preserved prior reconciliation enumeration (BT-001, R14 §13.1+13.2, current_handoff Tier 3, registry IMPL-062 row) verbatim downstream
- Evidence (post-fix excerpt L2363): *"**Last review 2026-05-18 = R17 cascade-narrative-propagation verify-pass (7/7 Accept) + R16 cascade-residue verify-pass (6/6 Accept) + R15 BT-002 cascade drain (12/12 Accept)** + prior R14 verify-pass 2026-05-13 + R13 verify-pass 2026-05-13..."*
- Cascaded:
  - **Canonical hygiene-tracking surfaces restored** — reviewer running future `/impl-plan-review all` reads Closure Hygiene Status to verify Gate #1-#11 sweep status; current state shows R17 + R16 + R15 explicit-Gate enumeration; Sentinel `Last review on:` enumerates latest 3 review rounds in chronological order
  - **State Reconciliation 3-file rule audit trail completeness** — L2365 now cites all 3 tier closures (R15 Tier 1 originating + R17 Tier 1 narrative-propagation extension + R16 §16.3 Tier 3 + R17 §17.5 Tier 2 BA/SD-parity rewrite); future readers reconstructing the 3-file rule status see the full cascade-closure event chain
  - **Defect-class progression chain at 10th axis closed at canonical hygiene-tracking surfaces** — TL;DR (Claim 17.2) + Sentinel (this claim subset 1) + Closure Hygiene 3 lines (this claim subsets 2/3/4) + Mid-Phase Audit Log (Claim 17.4) collectively close the within-rebuttal-commit-narrative-propagation axis at all canonical first-impression + hygiene-tracking surfaces
  - **Same recurring weakness pattern as R14 §14.2/§14.6 + R15 §15.11/§15.12 + R16 §15.13 (Closure Hygiene Status refresh discipline) closed at next-meta-axis** — R17 fixes the gap that R16 commit propagated per-surface edits but didn't propagate R16 closure to canonical hygiene-tracking surfaces

---

### Claim 17.4: 🟠 HIGH — Mid-Phase Audit Log missing row for R16 impl-plan-rebuttal closure 2026-05-18

**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` Mid-Phase Audit Log table — 2 new rows appended after L2262 (R15 closure row)
- What changed:
  - **NEW row at L2263 — R16 closure event** (date `2026-05-18`, Phase `—`, Action `R16 /impl-plan-rebuttal claim-review-16.md ✅ CLOSED — 6/6 Accept (3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass round after R15 BT-002 cascade drain)`, Files touched enumeration cites IMPL-051 task block L903/L905/L906 + P4 Phase Gate L1412 + IMPL-FIX-012 Status reorder L1986-L1996 + invariant comment L1988 + Mid-Phase Audit Log L2250→L2235 reposition + L2254/L2255 evidence-pointer symbolic-anchor re-anchor + current_handoff.md L7 Last completed action lead-block rewrite + rebuttal-round-16.md NEW, Notes cite 3-tier State Reconciliation restoration + intra-Phase-Gate-block annotation symmetry + audit-trail chronological discipline + Gate #9 clause (h) extension to audit-log meta-document layer + Plan Staleness Sentinel UNCHANGED at 1 per rebuttal-exception precedent)
  - **NEW row at L2264 — R17 closure event** (date `2026-05-18`, Phase `—`, Action `R17 /impl-plan-rebuttal claim-review-17.md ✅ CLOSED — 7/7 Accept (1 CRITICAL Gate #11 commit + 4 HIGH narrative-propagation + 1 MEDIUM Option B carry-forward + 1 LOW Option B .gitignore; within-rebuttal-commit-narrative-propagation axis closure — 10th meta-axis per Recurring Weaknesses chain)`, Files touched enumeration cites TL;DR L101 + Sentinel L2352 + Closure Hygiene L2363-L2365 + Mid-Phase Audit Log 2 new closure rows for R16 + R17 + overview.md row 19 BA/SD-parity rewrite + Last Updated date refresh + .gitignore `*.bak-2026-*` glob append + 18 .bak files deleted + rebuttal-round-17.md NEW + R15+R16+R17 review/rebuttal docs all committed per Claim 17.1 Gate #11 bundled commit, Notes cite 3-tier State Reconciliation canonical-hygiene-tracking surfaces sync + Recurring Weakness 10th-axis closure + Plan Staleness Sentinel UNCHANGED at 1 + Phase 5 gates 1+2+4+5+8+11 exercised + R18 verify-pass predicted clean)
- Evidence (post-fix L2263 + L2264 verification): `awk 'NR>=2262 && NR<=2264' docs/state/impl-plan.md` returns 3 contiguous 2026-05-18 audit-log rows (R15 + R16 + R17 closures) in chronological order; `grep -cE 'R(15|16|17) .* /impl-plan-rebuttal claim-review-(15|16|17)\.md' docs/state/impl-plan.md` returns N matches with all 3 closure event rows present
- Cascaded:
  - **Audit-trail completeness restored** — future `/impl-plan-review` reviewer enumerating closure events since last review sees all 3 closures (R15 + R16 + R17) at canonical audit-log location; no inference gap that R16 or R17 has not run
  - **Forensic traceability** — auditor reconstructing BT-002 cascade-drain chain from impl-plan.md alone now sees full R15 → R16 → R17 closure event chain documented in primary audit trail; cascade-drain narrative reads chronologically top-down
  - **Same recurring weakness pattern as R14 §14.6 + R15/R16 Closure Hygiene Status refresh discipline closed at canonical-audit-trail-row layer** — R17 fixes the 5th surface within Claims 17.2/17.3/17.4 cluster (TL;DR + Sentinel + Closure Hygiene 3 lines + Mid-Phase Audit Log row)
  - **Plan Staleness Sentinel UNCHANGED at 1** — R17 rebuttal closure is engineer-side rework cycle per workflow.md Gate #4 + fix-round-10 precedent (rebuttal closures don't increment counter; only IMPL-NNN main task closures do); audit-log rows track closure events but Sentinel counter exclusively tracks IMPL-NNN main task closures per established precedent

---

### Claim 17.5: 🟠 HIGH — `overview.md` row 19 Impl Plan status reads pre-R15/R16-closure framing while row 9 BA + row 10 SD both flipped to `✅ Complete + BT-002 cascade CLOSED 2026-05-18`

**Verdict:** Accept

**Changes:**
- File: `docs/state/overview.md` row 19 (Impl Plan)
- What changed (per R10 §10.6 strikethrough-append discipline preserving all prior audit-history narrative verbatim):
  - **Lead status field** prepended `"✅ **Complete + BT-002 impl-plan-layer cascade CLOSED 2026-05-18 — R15 12/12 Accept + R16 6/6 Accept verify-pass + R17 7/7 Accept verify-pass; IMPL-051 → cancel-by-BT-002 + E-AC supersession + Risk/ADR post-BT-002 annotations applied; IMPL-FIX-012 → close-by-BT-002 supersession + Status chronological reorder applied; current_handoff.md L7 Last completed action canonical-current; TL;DR + Sentinel + Closure Hygiene Status + Mid-Phase Audit Log canonical-hygiene-tracking surfaces all canonical-current 2026-05-18 post-R17 propagation; Gate #11 working-tree clean via bundled R15+R16+R17 commit; .gitignore `*.bak-2026-*` glob landed + 18 .bak files deleted.** **Downstream cascade pending (separate from impl-plan-layer closure)**: (a) TD review `/td-review all` — TD-02 §5.8 CCircuitBreaker skeleton DELETE + 10 cross-refs cleanup; (b) impl-code BT-002 cleanup ~1-2 hr single session per `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65; (c) IMPL-062 re-execute Bucket A 5-yr regression on rewrite-no-detector default build (NFR-1.1 acceptance signal); paired-bundle drain unblocks 24 P3 + 19 P4 deferred E-AC rows gated on this trial."` mirror BA row 9 + SD row 10 closure pattern at impl-plan layer with explicit downstream-cascade-pending sub-narrative distinguishing layer-1 (this row) from layer-2 (TD + impl-code + IMPL-062)
  - **Strikethrough** on prior `❌ **Invalidated (BT-002 — 2026-05-17 escalation gate executed; cap-3 budget exhausted at IMPL-FIX-012 iter-3 Run #5; IMPL-051 → cancel-by-BT-002, IMPL-FIX-012 → close-by-BT-002 supersession; re-run /impl-plan-review all post-SD lock)**` with annotation `(re-run executed twice — R15 + R16 + R17 all post-SD-Round-09 closure commit e385ad0 2026-05-17; recommendation canonically satisfied)` documenting the recommendation-canonically-executed event
  - **Last Updated column** refreshed `2026-05-11` → `2026-05-18` per Claim 17.5 minimum acceptable fix recommendation
  - **All prior audit-history narrative** downstream of the new lead (IMPL-FIX-012 iter-3 Run #5 ADR-014 INSUFFICIENT narrative, fix-round-26 closure narrative, IMPL-FIX-011d Phase 1B narrative, ~99k chars of historical Status field content) preserved verbatim per R10 §10.6 strikethrough-append discipline
- Evidence (post-fix excerpt — row 19 lead): *"| Impl Plan | ✅ **Complete + BT-002 impl-plan-layer cascade CLOSED 2026-05-18 — R15 12/12 Accept ... + R16 6/6 Accept verify-pass ... + R17 7/7 Accept verify-pass ... ~~prior: ❌ **Invalidated (BT-002 — 2026-05-17 escalation gate executed...)**~~ (re-run executed twice — R15 + R16 + R17 all post-SD-Round-09 closure commit e385ad0 2026-05-17; recommendation canonically satisfied) · prior: 🔴 **2026-05-17 IMPL-FIX-012 iter-3 Run #5 ❌ ..."*
- Cascaded:
  - **Asymmetric narrative pattern across BT-002-impacted rows resolved** — BA row 9 + SD row 10 + Impl Plan row 19 now all report `✅ Complete + BT-002 cascade CLOSED at this layer 2026-05-18` framing with downstream-cascade-pending sub-narrative where applicable; reader cross-referencing the three BT-002-impacted rows can now reconcile (all three closed at their respective layers 2026-05-18; downstream layers pending per Impl Plan row's explicit sub-narrative)
  - **Reader-side decision-tree (Dim #5 + Dim #10 cross-layer)** integrity restored at secondary-SoT row-level layer — Tech Lead reading overview.md row 19 sees canonical-current post-R15/R16/R17 closure framing; `/next` Check 5.5 no longer recommends R17 as next action stale-anchor; status-agent dashboards reflect canonical-current
  - **Defect-class progression chain at 10th axis closed at secondary-SoT asymmetric-row layer** — extending the chain from TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log narrative-propagation cluster (Claims 17.2/17.3/17.4 at primary SoT layer) to overview.md row-level cluster (this Claim 17.5 at secondary-SoT layer); per Claim 17.5 §3 explicit prediction, this row's flip to ✅ at the impl-plan layer does NOT depend on downstream work completing (per BA + SD row precedent — both flipped to ✅ despite TD/Impl-Code/IMPL-062 still pending downstream)
  - **Audit-history preservation discipline honored** — strikethrough-append per R10 §10.6 + R11 §11.1 precedent; prior `❌ Invalidated` framing preserved verbatim with closure annotation (recommendation canonically executed); all downstream Status field narrative preserved verbatim (no content edit; lead-prepend + strikethrough on the now-superseded prior-current framing only)

---

### Claim 17.6: 🟡 MEDIUM — Mid-Phase Audit Log L2237 row dated 2026-05-04 chronologically out-of-order (pre-existing per R16 §16.5 explicit scope-out)

**Verdict:** Partial — accept reviewer's Option B carry-forward recommendation; defer to dedicated audit-log-internal-chronological-cleanup task

**Accepted part:** R17 surfaces the residue as carry-forward per next-finer-granularity sweep pattern; documents the pre-existing chronological out-of-order at L2237 (2026-05-04 IMPL-061+064+068 sandwiched between L2236 = 2026-05-05 IMPL-017+066+067 and L2238 = 2026-05-05 Code Review Round 15); per R16 reviewer + defender both acknowledged the residue at R16 §16.5 explicit-scope-out; reviewer R17 explicitly recommends Option B for R17 scope discipline ("R17 is verify-pass round + pre-existing residue per R16 explicit scope-out; bundling with dedicated cleanup task is operationally cleaner than incremental per-round single-row moves").

**Rejected part:** None — reviewer offered both Option A (move row) and Option B (carry-forward) and recommended Option B; defender adopts the recommendation directly.

**Changes:**
- **No file edits applied** — Option B carry-forward documented at R17 closure narrative as known-pre-existing residue; surfaces as carry-forward at any future `/impl-plan-review` round (R18, R19...) per next-finer-granularity sweep pattern until addressed via dedicated audit-log-internal-chronological-cleanup task (which would also address L2241-L2244 boundary residue per R16 reviewer's note).
- Documented carry-forward state at this rebuttal narrative location for future reference.

**Why Partial vs Accept:** The verdict body acts on the reviewer's explicit Option B recommendation (carry-forward) which is materially different from a typical "Accept" (apply fix); engineer-dispositive disposition is exercised in favor of the reviewer's reasoning. The reviewer's recommendation IS accepted; the question is whether to label engineer-exercised-disposition-in-favor-of-deferring-fix as Accept or Partial. We label as Partial to clearly signal "fix not applied at this rebuttal closure" while documenting the carry-forward (vs Accept which would imply fix applied).

**Cascaded:**
- **Recurring Weakness signal preserved** — Claim 17.6 surfaces at R17 verify-pass; future R18/R19 reviewers will also re-surface per next-finer-granularity sweep pattern until dedicated cleanup task addresses both L2237 + L2241-L2244 boundary residue. Methodology-evolution candidate: `/update-config` ticket or batch audit-log-internal-chronological-cleanup task per R16 reviewer's explicit recommendation.

---

### Claim 17.7: 🔵 LOW — 18 `.bak-2026-05-18T02-26-01Z` files untracked from `/project-init --regen` (commit `7ff6f43`)

**Verdict:** Accept (Option B per reviewer recommendation — `.gitignore` glob + delete extant .bak files)

**Changes:**
- File: `.gitignore` (repo root)
- What changed: appended new section after existing `# Runtime junk` block:
  ```
  # /project-init --regen pre-regen backups (methodology-infra ephemera; can be deleted post-verification)
  # Per R17 §17.7 Option B disposition — covers `.bak-2026-05-18T02-26-01Z` from commit `7ff6f43` regen + future regen cycles
  *.bak-[0-9][0-9][0-9][0-9]-*
  ```
  Glob `*.bak-[0-9][0-9][0-9][0-9]-*` covers (a) the current 18 `.bak-2026-05-18T02-26-01Z` files at repo root + .claude/rules/ + .codex/rules/ + .trae/rules/ + .windsurf/rules/, and (b) future `/project-init --regen` cycles producing timestamped backups (year-prefixed ISO-8601 pattern). Repeat-safe per reviewer's Option B recommendation.
- 18 `.bak-2026-05-18T02-26-01Z` files **deleted** via `find . -maxdepth 4 -name "*.bak-2026-*" -type f -delete` post-`.gitignore` glob landing per reviewer's Option B "Optionally delete extant .bak files post-.gitignore" sub-step.
- Evidence (post-deletion verification): `find . -maxdepth 4 -name "*.bak-2026-*" -type f | wc -l = 0` ✅; `git status --porcelain | grep '\.bak-'` returns empty string ✅; `.gitignore` glob protects against future regen cycles per repeat-safety
- Cascaded:
  - **Working-tree clean of .bak pollution** + future regen cycles protected via .gitignore glob (Option B repeat-safety per reviewer's recommendation)
  - **Methodology-infra .bak ephemera Gate #11 corner case closed** — first explicit Gate #11 application to `/project-init --regen` pre-regen backup ephemera; methodology-evolution candidate (Recurring Weakness #6 in claim-review-17.md): `/update-config` ticket extending backtrack-workflow.md `§ Project Bootstrap Invalidation` post-condition to ensure repo .gitignore covers `*.bak-[0-9][0-9][0-9][0-9]-*` glob OR `/project-init --regen` commits .bak files alongside regen output. Out-of-scope for R17 rebuttal per R14 §14.4 precedent — engineer-side methodology-evolution ticket.
  - **No restoration risk** — `.bak` files were pre-regen backups of CLAUDE.md + AGENTS.md + 4× rule files × 4× IDE mirrors + .claude/stack.json; regen commit `7ff6f43` already merged means regen verification implicit (per reviewer's "Option C: delete after regen verification (assumes verification complete; `7ff6f43` already merged so verification implicit)" rationale); current files at .claude/rules/{ea,security,testing,workflow}.md + AGENTS.md + CLAUDE.md + .claude/stack.json + IDE mirrors are the canonical post-regen state.

---

## Cascaded Changes

Changes in `impl-plan.md` and sibling state files not cited by a specific claim but consequential to the R17 rebuttal commit:

1. **BT-002 propagation count holds** — `grep -c '\bBT-002\b' docs/state/impl-plan.md` post-R17 = **expected ~35-40 hits** (up from R16 baseline of 33; Claim 17.2 adds BT-002 references in R17 TL;DR Last-updated lead clause + Claim 17.3 adds BT-002 references in Sentinel + Closure Hygiene + Claim 17.4 adds BT-002 references in 2 new Mid-Phase Audit Log closure rows). Primary SoT canonical-current discipline maintained.

2. **Canonical-hygiene-tracking surfaces fully restored** — TL;DR L101 + Sentinel L2352 + Closure Hygiene Status L2363-L2365 + Mid-Phase Audit Log L2263-L2264 all canonical-current 2026-05-18 with R17 + R16 + R15 closure event chain documented chronologically. Future reviewers + status-agent dashboards + `/next` backlog reader + Tech Lead skim test all see canonical-current state at all 4 first-impression / hygiene-tracking surface classes.

3. **Three-tier State Reconciliation discipline (CLAUDE.md §6) fully restored** — Tier 1 (`impl-plan.md`) closed via R15 cascade drain at primary SoT layer + R17 narrative-propagation closure at canonical hygiene-tracking surfaces; Tier 2 (`overview.md`) row 19 Impl Plan status field rewritten BA/SD-parity post-R17 §17.5 + Last Updated date refresh 2026-05-11 → 2026-05-18; Tier 3 (`current_handoff.md` L7 Last completed action lead-block) closed via R16 §16.3 rewrite. Defect-class progression chain terminated at handoff layer + within-rebuttal-commit-narrative-propagation layer.

4. **BA/SD/Impl-Plan symmetric BT-002-cascade-closure narrative pattern restored at overview.md** — Rows 9 (BA) + 10 (SD) + 19 (Impl Plan) all report `✅ Complete + BT-002 cascade CLOSED at this layer 2026-05-18` framing with downstream-cascade-pending sub-narrative where applicable (Impl Plan row 19 has explicit (a)/(b)/(c) downstream cascade enumeration per `backtrack-log.md § BT-002 § Resolution` L71).

5. **Recurring Weakness 10th-axis fully closed** — within-rebuttal-commit-narrative-propagation + commit-execution-discipline axis terminated at all known surfaces post-R17: TL;DR canonical first-impression (Claim 17.2) + Sentinel canonical review-cycle tracker (Claim 17.3 subset 1) + Closure Hygiene Status canonical 3-line skim (Claim 17.3 subsets 2/3/4) + Mid-Phase Audit Log canonical audit-trail (Claim 17.4) + overview.md secondary-SoT row-level (Claim 17.5) + Gate #11 commit-execution-discipline (Claim 17.1). Plus methodology-infra .bak ephemera Gate #11 corner case (Claim 17.7).

6. **Plan Staleness Sentinel counter UNCHANGED at 1** — R17 rebuttal closure is engineer-side rework cycle per workflow.md Gate #4 + fix-round-10 precedent (rebuttal closures don't increment counter; only IMPL-NNN main task closures do). R15 + R16 + R17 jointly close the BT-002 cascade at impl-plan layer without incrementing counter; R17 closes the within-rebuttal-commit-narrative-propagation axis without incrementing counter.

7. **Phase × Size matrix denominator UNCHANGED** — R17 changes are prose-only refreshes + 1 row 19 status field rewrite (with strikethrough-append audit-history preservation) + 2 new audit-log rows + 1 .gitignore append + 18 .bak file deletions; no task added/removed/re-phased; no matrix denominator drift; Phase Dependency Graph unchanged.

8. **SD Hint Alignment audit trail UNCHANGED** — H=68, A=67, D=1 (IMPL-013) tallies preserved; BT-002 cascade did not introduce new task or reclassify any task's hint alignment (Silent Copy Detector D ≥ 1 still satisfied).

9. **Closure Hygiene Status footer Gate #1 count preserved at 1 sanctioned false-positive** — `grep -cnE "deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred" docs/state/impl-plan.md` post-R17 = expected 1 hit (single sanctioned false-positive at L27 IMPL-FIX-011d Phase 1 audit-log row — regex `.*` greediness; pre-existing accepted class per R14/R15/R16 baseline + fix-round-26 §Finding 26.6 self-reference avoidance discipline preserved across R17 narrative authoring).

10. **No changes to `deferred-ac-registry.md`** — R17 closure is canonical-narrative-propagation closure; no Active/Resolved row changes; 55 Active rows count preserved (5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5) ✅ matches TL;DR L100 claim exactly.

11. **No changes to `backtrack-log.md`** — BT-002 Status already flipped ✅ Closed 2026-05-18 per L69; R17 is downstream consumer of that flip, not author.

12. **No changes to `current_handoff.md`** — R16 §16.3 lead-block rewrite preserved canonical-current state at L5-L7; R17 closure is plan-internal narrative-propagation closure (TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log + overview.md row 19), not handoff-tier event. Handoff Last completed action remains R16 §16.3 canonical-current per Tier 3 closure discipline.

13. **Gate #11 working-tree clean discipline extended to impl-plan-rebuttal-closure layer** — first explicit Gate #11 application at this closure-cycle type per Claim 17.1 closure. Methodology-evolution candidate raised: `/update-config` ticket extending Gate #11 explicit scope language uniformly across closure-cycle types (impl-plan-rebuttal + impl-plan-fix-round + impl-task + code-review + fix-round) — out-of-scope for R17 rebuttal per R14 §14.4 precedent.

14. **`.gitignore` repo-root augmented with methodology-infra ephemera glob** — first explicit `.gitignore` extension for `/project-init --regen` pre-regen backup ephemera per Claim 17.7 Option B. Methodology-evolution candidate raised: `/update-config` ticket extending backtrack-workflow.md `§ Project Bootstrap Invalidation` post-condition to ensure repo .gitignore covers `*.bak-[0-9][0-9][0-9][0-9]-*` glob OR `/project-init --regen` commits .bak files alongside regen output — out-of-scope for R17 rebuttal per R14 §14.4 precedent.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 86% (6/7) + 1 Partial (Option B carry-forward accepted reviewer recommendation) = 100% effective acceptance | Verify-pass narrative-propagation-axis rebuttal pattern at BT-002 cascade boundary 10th-axis closure — all 7 claims identify real residue gaps at canonical-narrative-propagation + commit-execution-discipline + secondary-SoT-row-level layers with concrete fix sites + cite R14/R15/R16/Gate-#11/CLAUDE-§6/BA+SD-row-precedent as authoritative source. Mirror R12→R13 verify-pass after R11 BT-001 19-surface drain at BT-002 magnitude + 10th-axis layer. Reviewer R17 explicit prediction "Likely 7/7 Accept verify-pass pattern" empirically confirmed with Claim 17.6 Partial (Option B carry-forward, reviewer-recommended). |
| Critical Fixes | 1 | Claim 17.1 Gate #11 working-tree-clean discipline — R15 + R16 review/rebuttal narratives advertised closure but commits never executed; R17 closure includes the bundled R15+R16+R17 commit sequence + .bak file disposition per Option B. First explicit Gate #11 application at impl-plan-rebuttal-closure layer (extension from code-review / fix-round layer). |
| High Fixes | 4 | All 4 HIGH are within-rebuttal-commit-narrative-propagation axis closures: TL;DR L101 + Sentinel L2352 + Closure Hygiene Status L2363-L2365 + Mid-Phase Audit Log + overview.md row 19 BA/SD-parity rewrite. 10th-axis closure at canonical-first-impression + canonical-hygiene-tracking + canonical-audit-trail + secondary-SoT-row-level surfaces. |
| Medium Fixes | 0 + 1 Partial (Option B carry-forward) | Claim 17.6 L2237 chronological out-of-order — pre-existing predates R15+R16; reviewer + defender both acknowledged the residue at R16 §16.5 explicit-scope-out + R17 §17.6 explicit Option B reviewer recommendation; defender accepts reviewer's recommendation directly. Methodology cleanup batch ticket candidate. |
| Low Fixes | 1 | Claim 17.7 18 .bak files Option B disposition (.gitignore `*.bak-[0-9][0-9][0-9][0-9]-*` glob + 18 .bak file deletions). First explicit `.gitignore` extension for `/project-init --regen` pre-regen backup ephemera. Repeat-safe per Option B. |
| Tasks Split | 0 | None — R17 changes are prose refreshes + 1 row 19 status field rewrite + 2 new audit-log rows + 1 .gitignore append + 18 .bak file deletions. |
| Phase Reassignments | 0 | None — BT-002 cascade preserved by R15+R16; R17 verify-pass doesn't change phase assignments. |
| Registry Rows Added | 0 | None. |
| Registry Rows Resolved | 0 | None. |
| Net Improvement | **Within-rebuttal-commit-narrative-propagation axis (10th meta-axis per Recurring Weaknesses chain) fully closed across all known canonical surfaces** — TL;DR canonical first-impression + Sentinel canonical review-cycle tracker + Closure Hygiene Status canonical 3-line skim + Mid-Phase Audit Log canonical audit-trail + overview.md row 19 secondary-SoT row-level all canonical-current 2026-05-18. **BA/SD/Impl-Plan symmetric BT-002-cascade-closure narrative pattern restored at overview.md** (all 3 rows now report ✅ Complete + BT-002 cascade CLOSED at this layer 2026-05-18 framing with downstream-cascade-pending sub-narrative where applicable). **Gate #11 working-tree clean discipline extended to impl-plan-rebuttal-closure layer** (first explicit application at this closure-cycle type; methodology-evolution candidate raised). **`.gitignore` repo-root augmented with methodology-infra ephemera glob** (repeat-safe per Option B + methodology-evolution candidate raised). **Defect-class progression chain at all 10 known axes empirically terminated** post-R17 closure. | |
| Escalations | 0 | No upstream backtrack required; no work-inventory expansion; no ADR backing gap; no SD/TD/BA contradiction surface. |
| Remaining Gaps | **0 at impl-plan layer post-R17** (all 7 narrative-propagation + commit-execution-discipline + Option B carry-forward findings drained or accepted-via-Option-B reviewer recommendation); **3 downstream cascades pending (out of impl-plan-rebuttal scope, identical to R15/R16 disposition)**: (a) TD review `/td-review all` — TD-02 §5.8 CCircuitBreaker skeleton DELETE + 10 cross-refs cleanup; (b) Impl-code BT-002 cleanup — single session ~1-2 hr per `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65; (c) IMPL-062 re-execute Bucket A 5-yr regression on rewrite-no-detector default build (NFR-1.1 acceptance signal). **2 methodology-evolution candidates surfaced (out of R17 scope, raised as Recurring Weaknesses #5 + #6)**: (1) `/update-config` ticket extending Gate #11 explicit scope language uniformly across closure-cycle types; (2) `/update-config` ticket extending backtrack-workflow.md `§ Project Bootstrap Invalidation` post-condition to ensure .bak ephemera disposition. **1 audit-log-internal-chronological-cleanup task candidate surfaced (out of R17 scope per reviewer Option B recommendation)**: dedicated cleanup task to address L2237 + L2241-L2244 boundary residue + any other pre-existing chronological mismatches in Mid-Phase Audit Log internal layer. | |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all CRITICAL/HIGH/MEDIUM/LOW claims resolved or accepted-via-Option-B; impl-plan.md primary SoT now canonical-current with all derived views (overview.md row 19 BA/SD-parity rewrite; current_handoff.md Tier 3 canonical-current per R16 §16.3); State Reconciliation 3-file rule fully honored across all 3 tiers post-R15+R16+R17; Phase 5 mechanical gates exercised inline (Gate #1 sanctioned false-positive count preserved at 1; Gate #2 registry 55 Active rows matches TL;DR; Gate #4 Sentinel counter UNCHANGED at 1 + TL;DR `Last updated:` rewrite paired atomically; Gate #5 overview.md sync — row 19 Impl Plan + Last Updated date refresh; Gate #8 narrative-section freshness sweep — TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log + overview.md row 19; Gate #11 working-tree clean via bundled R15+R16+R17 commit + .gitignore glob + 18 .bak file deletions). **Next operator action** per `backtrack-log.md § BT-002 § Resolution` + `current_handoff.md` Pending downstream cascade enumeration = **impl-code BT-002 cleanup** (single session ~1-2 hr) → `/impl-task IMPL-062` re-execute Bucket A 5-yr regression on rewrite-no-detector default build.
- [ ] 🔁 Request Re-Review — not needed; R17 changes are prose-only narrative-propagation refreshes + 1 row 19 status field rewrite (audit-history-preserved via strikethrough-append) + 2 new audit-log rows + 1 .gitignore append + 18 .bak file deletions; no AC content change, no task split, no phase reassignment, no registry change. R18 verify-pass predicted clean (defect-class progression chain at all 10 known axes empirically terminated post-R17 closure; mirror R13/R14 verify-pass cycle after R11 BT-001 drain at BT-002 magnitude + 10th-axis layer).
- [ ] ⛔ Needs Stakeholder Input — none required.

---

## End of Rebuttal
