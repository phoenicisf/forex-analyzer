# Implementation Plan Claim Review Round 13

| Field | Value |
|-------|-------|
| **Round** | 13 |
| **Target** | `docs/state/impl-plan.md` (+ state-reconciliation siblings) |
| **Date** | 2026-05-13 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R12 (2026-05-13 earlier today) — 6/6 Accept; BT-001 Path A closure + R11 self-introduced defect drain |
| **Trigger** | Mid-cascade audit pair to R12 within same calendar day — `/impl-plan-review all` invoked after R12 rebuttal commit to verify the BT-001 lifecycle closure landed cleanly across the **3-file state-reconciliation surface** (CLAUDE.md §6 + State Reconciliation Discipline). R12 explicitly deferred 1 surface ("Known follow-up" — `overview.md § Impl Plan` row prepend) citing read-tool length limit; this round verifies whether the deferred-follow-up gap recurred and whether sibling derived-views remain consistent with the now-canonical post-BT-001 framing. |

---

## 📊 At-a-Glance

**Total findings:** 4 (🔴 CRITICAL 1 / 🟠 HIGH 1 / 🟡 MEDIUM 1 / 🔵 LOW 1)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (`deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **0 real hits** ✅. Note: same false-positive class as R11/R12 (11 inline boilerplate hits on `## Plan Staleness Sentinel` counter-convention prose `"FIX-ticket closures ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent"` — greedy `.*` regex spans innocuous string; sanctioned per R11/R12 false-positive disposition).
- **Forward refs (P_n → P_m, m>n):** **0 edges** ✅. Sampled IMPL-062 deps (IMPL-060 P3 ✅ + IMPL-061 P4 ✅ — backward); IMPL-063 deps (IMPL-060 P3 ✅ + IMPL-061 P4 ✅ + IMPL-062 P4 ✅ structural); IMPL-FIX-011a P3 sub-ticket↔parent IMPL-FIX-011 P4 — per R09 §09.5 convention (parent-tracks-paired-bundle-only; sub-ticket P3 independent of parent P4) preserved unchanged by R12 surgery. No new edges introduced.
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013 P4→P3), V=0, N=0. **Not triggered** ✅ (D ≥ 1 + line 2262 explicit confirmation note `"Audit trail self-validates as genuine independent evaluation, not silent copy"`).
- **State reconciliation (4-way):** 🔴 **1 derived-view↔primary-SoT desync** persisting from R12 explicit known-follow-up deferral — `docs/state/overview.md` L19 Impl Plan row still leads with `"✅ BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM)"` framing; **no R12 closure annotation; no "BT-001 lifecycle CLOSED" annotation; no Path A backtrack-log Status flip note**. R12 §Cascaded-Changes "Known follow-up" explicitly defers this with `"single-line wrapping prevented in-session Read of the row in this rebuttal — recommend engineer applies via direct prepend at next session start"` — but the deferral premise (Read-tool length limit blocks edit) is **methodologically wrong**: the `Edit` tool's `old_string` parameter does not require Read of the full line, only a unique substring of the surrounding text; the leading row-prefix `"| Impl Plan | ✅ **BT-001 Step 3 closed via R11 rebuttal 2026-05-13"` is unique tree-wide and would have allowed in-session prepend without a Read step. The deferral compounded a known R12 defect-class into next-round-recurrence (Claim 13.1). 🟠 **+ 1 sibling derived-view stale narrative** — overview.md L20 Impl Tasks row P4 narrative `"P4 17/17 ✅ (IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session)"` carries pre-BT-001 separate-bucket framing (where IMPL-063 was a separate Bucket B paired with IMPL-062 as separate Bucket A); post-R11 §11.1 + R12 §12.2 surgery the topology is now `rewrite-G4-ON ↔ rewrite-G4-OFF within IMPL-063` (informational delta) + IMPL-062 single-pass Bucket A (Claim 13.2). 🟡 **+ 1 Plan Staleness Sentinel narrative stale** — `impl-plan.md` L2274 says `"next IMPL-NNN main task closure (likely IMPL-063 paired Bucket B after /backtrack ba resolves NFR-1.1 contract) will reset Sentinel +1"` — `/backtrack ba` is now closed via BT-001 R12 §12.1 Path A; the parenthetical conditional `"after /backtrack ba resolves NFR-1.1 contract"` is structurally invalid post-BT-001 (Claim 13.3).

### Top 3 to Fix First

1. **Claim 13.1** 🔴 — `overview.md` L19 Impl Plan row still leads with `R11 7/7 Accept` framing; **no R12 closure / no BT-001 lifecycle CLOSED annotation / no Path A backtrack-log Status flip note**. R12 explicitly deferred this with methodologically-incorrect read-tool-length-limit rationale → same State Reconciliation Discipline 3-file gap class as R12 Claim 12.1 (primary SoT ↔ derived view contradiction) recurring at next-finer granularity (derived-derived-view layer: overview.md is itself derived from impl-plan.md, which was reconciled with backtrack-log.md in R12 but the propagation stopped one layer short).
2. **Claim 13.2** 🟠 — `overview.md` L20 Impl Tasks row P4 narrative `"P4 17/17 ✅ (IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session)"` carries pre-BT-001 separate-bucket framing; topology now changed post-R12 §12.2 (informational delta within IMPL-063 itself).
3. **Claim 13.3** 🟡 — `impl-plan.md` L2274 Plan Staleness Sentinel narrative paragraph references `/backtrack ba` as future-pending; BT-001 closed in R12 §12.1 (Path A backtrack-log Status flip). Same Phase Status Notes-class stale-conditional defect (Claim 12.3) recurring at Sentinel-paragraph layer.

### Verdict

- [ ] ✅ **Ready for Implementation Execution**
- [x] ⚠️ **Needs Rebuttal Round** — 1 CRITICAL blocks (overview.md L19 R12-deferred-follow-up not yet landed; primary↔derived-view desync persists 1 layer below where R12 reconciled). Run `/impl-plan-rebuttal claim-review-13.md`.
- [ ] ⛔ **Immediate Attention**

> Rebuttal scope: **state-reconciliation-only at derived-view layer** — `overview.md` L19 + L20 prepend / rewrite + impl-plan.md L2274 Sentinel parenthetical removal + impl-plan.md L7 TL;DR Sentinel-gates-status refresh (LOW finding). No AC content changes; no task splits; no phase reassignments. Effort: Low (3-4 single-line edits across 2 files; ~10-20 LOC total). Likely 4/4 Accept verify-pass pattern (similar to R10 prose-only rebuttal).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Unchanged since R01–R12; rationale + Phase % targets ครบ; no BT-001 phase-shape impact propagating into Phase Shape Choice |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean (H=68, A=67, D=1, line 2262 confirmation note); SD Round 06 verify-only confirmed `08 § 1.10` line 129 cascade landed; no E1/E2 Evolution Sequence violation |
| 3 | Task Decomposition & Sizing | ✅ Pass | IMPL-062 + IMPL-063 partial-re-open audit-trail correctly preserved via R11 §11.1 + R12 §12.2/12.4 strikethrough + new `[ ]` + Closed paragraph append pattern; Phase × Size matrix denominator preserved per R12 §12.4 verdict |
| 4 | AC — Dual-Track Compliance | ✅ Pass | IMPL-063 S-AC #2/#3 R12 surgery symmetric to R11 §11.1 (caught in R12); all S-AC + E-AC dual-track preserved post-cascade; no forbidden-pattern hits |
| 5 | Phase Gates — Testable Exit | ✅ Pass | P4 Phase Gate rows correctly carry R11 §11.2 update (Empirical Demo + NFR-1.1 check); Tier 1.5 Exploratory Walk row + Rollback Plan row preserved |
| 6 | Deferred-AC Registry Init | ✅ Pass | IMPL-062 row deferred-reason correctly carries R12 §12.5 BT-001 update append (L68); Resolved table preserved; no expiry decision drift |
| 7 | Cross-Phase Dependency | ✅ Pass | No forward refs; sub-ticket↔parent dependency convention (R09 §09.5) preserved |
| 8 | State-File Consistency | ⚠️ Findings 13.1 + 13.2 + 13.3 | overview.md L19 Impl Plan row R12-deferred-follow-up not landed (CRITICAL 13.1); overview.md L20 Impl Tasks row P4 narrative pre-BT-001 framing (HIGH 13.2); impl-plan.md L2274 Sentinel paragraph `/backtrack ba` conditional stale (MEDIUM 13.3) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4/month-year schedule leakage introduced; registry expiries + 2026-05-13 dates are working-paper-dates (allowed per R10 disposition) |
| 10 | Readability — Reader Empathy | ⚠️ Finding 13.4 | TL;DR L7 inline Sentinel boilerplate `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R09 ... Phase 5 mechanical gates 1+6+11 pending fix-round commit. State Reconciliation 3-file rule honored."` is stale (post-R11+R12 the Sentinel canonical block at L2271 says last review 2026-05-13 R12; Gate #7 + #8 verified explicitly per Closure Hygiene Status L2283). Reader sees inline narrative contradicting canonical block — minor reader-skim friction. |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 13.1: 🔴 CRITICAL — `overview.md` L19 Impl Plan row R12 closure annotation never landed; R12 §Cascaded-Changes "Known follow-up" deferred citing read-tool length limit (methodologically incorrect rationale — Edit tool's old_string uniqueness rules accommodate prepend without full-line Read); primary↔derived-view state reconciliation gap persists 1 layer below where R12 reconciled (backtrack-log↔impl-plan), exactly the defect class R12 Claim 12.1 was authored to prevent

**Location:**
- **R12 deferral source:** `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-12.md § Cascaded Changes § Known follow-up` (lines 123-124): `"docs/state/overview.md § Impl Plan row should prepend an R12 closure note ... The single-line wrapping prevented in-session Read of the row in this rebuttal — recommend engineer applies via direct prepend at next session start."`
- **Actual stale state in derived-view:** `docs/state/overview.md` L19 (Impl Plan row) — current row begins `"| Impl Plan | ✅ **BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM)** — IMPL-062 task block re-authored ..."`. **No** annotation referencing R12 closure / BT-001 lifecycle CLOSED / Path A backtrack-log Status flip / R12 §12.1-12.6 surgery surfaces. The row presents the post-R11 state as if it were terminal.
- **Primary SoT, post-R12 (canonical now):** `docs/state/backtrack-log.md § BT-001 § Status` L29 `"✅ Resolved 2026-05-13"` + Resolution L31 populated with R12 §12.1 Path A 5-step cascade audit trail + `docs/state/impl-plan.md § Plan Staleness Sentinel` L2271 `"Last review on: 2026-05-13 — claim-review-12.md + rebuttal-round-12.md (R12 6/6 Accept; BT-001 closure ...)"` + `docs/state/current_handoff.md § Last completed action` L5-7 `"🟢 Impl Plan Rebuttal Round 12 ✅ CLOSED 2026-05-13 — BT-001 closure ... BT-001 lifecycle CLOSED."`

**Problem:**

Per CLAUDE.md §6 + § Glossary "State Reconciliation Discipline" (3-file propagation rule): **every closure event must propagate (1) impl-plan.md primary SoT → (2) overview.md derived count + phase status → (3) {module}/handoff.md + `_session-handoff/<task-id>-evidence-*` transient pointer + artifact**. R12 closed BT-001 lifecycle in the primary SoT (backtrack-log.md) + propagated to impl-plan.md primary state + propagated to current_handoff.md cascade chain table (transient pointer) + propagated to deferred-ac-registry.md (sibling SoT for deferred E-AC). But **R12 explicitly stopped propagation at the derived-view layer 2** (overview.md), citing read-tool length limit as the reason.

The deferral rationale is **methodologically incorrect**:

1. The `Edit` tool's `old_string` parameter requires uniqueness, not a full-line match. The row-prefix `"| Impl Plan | ✅ **BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM)** — IMPL-062 task block re-authored"` (the first ~250 characters of L19) is **unique tree-wide** (grep verified: matches only this row in the entire repo) and would have allowed in-session prepend with the form `Edit(old_string="| Impl Plan | ✅ **BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM)**", new_string="| Impl Plan | ✅ **BT-001 lifecycle CLOSED 2026-05-13 via R12 Path A — backtrack-log.md § BT-001 Status flipped Resolved + Resolution populated + overview.md BT-001 markers trim noted; R12 6/6 Accept (2 CRITICAL + 2 HIGH + 2 MEDIUM); IMPL-063 S-AC #2/#3 un-`[x]`'d symmetric to R11 §11.1; Phase Status P4 Notes column rewritten; IMPL-062 Closed paragraph appended; deferred-ac-registry IMPL-062 row deferred-reason updated; current_handoff cascade chain Steps 3/4/5 flipped ✅/⏭/✅. ✅ BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM)**")`. No Read step required.

2. **Even if** the Read tool's token-limit prevented loading the full line, the `Read` tool's `offset` + `limit` parameters allow partial-line context retrieval (e.g., `Read(file_path=..., offset=19, limit=1)` reads exactly line 19; the 90,653-character payload would have been truncated at ~25k-token cap, but the leading 1-2k characters would have been visible). The leading characters are sufficient context to identify the unique edit anchor.

3. The R12 narrative offers no fallback path (e.g., "engineer at next session run grep + apply prepend"). It simply pushes the obligation forward without an expiry or owner. This is exactly the **deferred-improvement-without-expiry pattern** R12 itself flagged as recurring weakness #3 (`"deferred-improvements-without-expiry is itself a recurring weakness — per fix-round/methodology-improvement-debt class"`). R12 acknowledged the pattern but committed it anyway.

**Why this matters:**

1. **State Reconciliation Discipline 3-file rule explicit violation** (CLAUDE.md §6 + Glossary): the rule names **`overview.md` as Layer 2 derived view** in the propagation chain. R12 closed the lifecycle event at Layer 0 (backtrack-log.md primary SoT) + Layer 1 (impl-plan.md primary state-of-tasks SoT) + Layer 3 (current_handoff.md + sibling registry), skipping Layer 2. The 3-file rule's invariant is that **all 3 files agree at any read time**; the current state has 3 files saying "BT-001 closed 2026-05-13" + 1 derived view saying "BT-001 Step 3 closed via R11" (R11 was the cascade-validation event; the lifecycle close event was R12). Status agents + `/next` orchestrators reading L19 will see R11 closure framing + miss the R12 lifecycle close.

2. **R12 §12.1 defect class recurrence at next-finer granularity**: R12 Claim 12.1 caught backtrack-log↔impl-plan annotation contradiction at the **primary↔derived-view layer** (defect-class progression R12 §Recurring-Weaknesses called the "5th axis: upstream-lifecycle-state-of-an-upstream-event"). R13 now catches the **derived-view↔derived-derived-view layer** (overview.md is itself a derived view of impl-plan.md; impl-plan.md was reconciled with backtrack-log.md primary SoT in R12; the propagation stopped one layer short). Same shape as the R12→R13 chain mirrors the R10→R11→R12 chain (each round caught the prior round's reconciliation gap at the next-finer granularity).

3. **Operator-side consequence**: A Tech Lead / PM running `/next` later today reads `overview.md` first per `andm-impl-plan-reviewer/SKILL.md` Dim #10 reader-skim discipline. They see L19 "BT-001 Step 3 closed via R11 rebuttal" + scroll to overview.md L18 (or any other surface mentioning BT-001) + may notice the still-present BT-001 markers in `Design (BA)` row L10 `"BT-001 still impacts SD per backtrack-log.md § Impacted phases — SD → next /sd-review all"` (this BA-row marker is now obsolete since SD Round 06 closed; should have been trimmed per R12 §12.1 Cascaded Changes "overview.md BT-001 markers trim noted in R12 §Cascaded Changes" — but the trim itself never landed). The aggregate impression from overview.md reading: BT-001 is mid-cascade with `/sd-review all` still pending. The actual state per backtrack-log.md primary SoT: BT-001 lifecycle ✅ CLOSED. Contradiction across multiple overview.md surfaces.

4. **Methodology-improvement-debt accumulation**: R12 §Closure-Discipline-Note explicitly chose to NOT add a new `workflow.md` Gate this round (citing "per claim-review-12.md § Recurring Weaknesses #3 caution against deferred-improvement-without-expiry"). But the alternative — capturing the lesson in Cascaded-Changes narrative — only works if **the rebuttal itself completes the full reconciliation**. R12 left 1 surface unreconciled + relied on engineer-side narrative discipline. The narrative discipline failed at R12's own closure (Layer 2 propagation skipped), which is the predictable failure mode of "ad-hoc narrative discipline without codified gate."

**Minimum acceptable fix:**

Two-part fix:

**Part A — land the deferred propagation (R13 rebuttal Cascaded Changes):**

1. **`docs/state/overview.md` L19 Impl Plan row prepend** — use Edit tool with row-leading unique anchor (no Read step required). Prepend annotation BEFORE the existing R11-framing:
   ```
   ✅ **BT-001 lifecycle CLOSED 2026-05-13 via R12 Path A** — `backtrack-log.md § BT-001` Status flipped 🔄 Open → ✅ Resolved + Resolution populated with 5-step cascade audit trail (R12 §12.1); IMPL-063 S-AC #2/#3 un-`[x]`'d symmetric to R11 §11.1 IMPL-062 surgery (R12 §12.2); Phase Status P4 Notes column rewritten post-BT-001 (R12 §12.3); IMPL-062 Closed paragraph appended with partial-re-open annotation (R12 §12.4); deferred-ac-registry IMPL-062 row deferred-reason updated post-BT-001 (R12 §12.5); current_handoff cascade chain Steps 3/4/5 flipped ✅/⏭/✅ (R12 §12.6); R12 6/6 Accept. **Next action = operator `/impl-task IMPL-062` per rewrite-G4-ON single-pass default build, paired with IMPL-063 informational Bucket B same operator session (~30-60 min wall-clock).** · prior: ✅ BT-001 Step 3 closed via R11 rebuttal 2026-05-13 (7/7 Accept — 2 CRITICAL + 3 HIGH + 2 MEDIUM) ...
   ```

2. **`docs/state/overview.md` BT-001 markers trim** — search for any `BT-001 still impacts SD`, `BT-001 pending`, `BT-001 cascade in flight` style markers in other rows (BA row L10 + any other surface) → strikethrough with `~~...~~` + replace with `BT-001 ✅ CLOSED 2026-05-13` per CLAUDE.md `/next` Check 0.7 Direction A. The R12 §12.1 Cascaded Changes claim `"trim overview BT-001 markers per Check 0.7 Direction A (overview.md row update)"` was advertised but never executed — same gap class as the Impl Plan row prepend.

3. **Update Layer 2 Last Updated stamp** on overview.md Impl Plan row date column (currently `2026-05-13` per overview row schema — already correct date, but verify on Edit pass; if mismatched, fix).

**Part B — methodology hygiene (Cascaded Changes Closure Discipline Note):**

Engineer authoring R13 rebuttal Closure Discipline Note should explicitly state that R12's "Known follow-up" deferral pattern is **forbidden by 3-file rule**: any state reconciliation that R12 advertises as Cascaded-Changes-and-not-yet-landed MUST either (a) be landed inline before the rebuttal closes, OR (b) be registered as a registry row with owner + expiry ≤14d. R12's deferral met neither condition. This lesson is captured as Cascaded-Changes narrative discipline (no new `workflow.md` Gate to avoid Gate-debt accumulation per R12's own anti-pattern flag).

**Effort:** Low (Part A = 2 Edit tool calls on overview.md; Part B = 1 paragraph in R13 rebuttal Cascaded-Changes narrative; total ~30-50 LOC + 1 narrative).

---

### 🟠 HIGH

#### Claim 13.2: 🟠 HIGH — `overview.md` L20 Impl Tasks row P4 narrative carries pre-BT-001 separate-bucket framing `"IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session"`; post-R12 §12.2 surgery the topology is now `rewrite-G4-ON ↔ rewrite-G4-OFF within IMPL-063 itself` (informational delta — single task, paired-bundle .ini)

**Location:** `docs/state/overview.md` L20 (Impl Tasks row), opening narrative segment: `"🔄 In Progress — **P1 17/17 ✅ closed · P2 11/11 ✅ + 🟡 Gate Override 2026-05-03 (Path A) · P3 23/23 ✅ · P4 17/17 ✅ (IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session)** + IMPL-FIX-003 ✅ + IMPL-FIX-005 ✅ + IMPL-FIX-006 ✅ 2026-05-10 + ..."`

**Problem:**

The L20 narrative parenthetical describes IMPL-063's closure as `"Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session"` — this is the **pre-BT-001 topology** where:
- IMPL-062 was the Bucket A acceptance gate (rewrite-G4-OFF vs baseline)
- IMPL-063 was a separate Bucket B (rewrite-G4-ON vs rewrite-G4-OFF), paired with IMPL-062's `regression_5yr_no_g4.ini` as the G4-OFF leg

Post-BT-001 (per R11 §11.6 + R12 §12.2):
- IMPL-062 = rewrite-G4-ON vs baseline single-pass (Bucket A; default build no `DISABLE_G4_FIXES`)
- IMPL-063 = informational delta `rewrite-G4-ON − rewrite-G4-OFF` within IMPL-063 itself (Should-priority informational; absorbs `regression_5yr_no_g4.ini` as its own G4-OFF leg per BT-001 take-over from IMPL-062 — see impl-plan.md L1979 + L1999 R12 surgery)

The L20 narrative's `"numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session"` framing references the obsolete paired-bundle topology (IMPL-063↔IMPL-062 as separate buckets paired together) which IMPL-062 task block (L1988 R12 §12.4 append) explicitly invalidated: `"Post-BT-001 cascade: numeric drain on default build (G4-ON, single-pass) produces both NFR-1.1 Bucket A measurement + IMPL-063 G4-ON leg of informational Bucket B in one operator session (paired-bundle topology differs from pre-BT-001 IMPL-062-vs-IMPL-063-as-separate-buckets framing)."`

**Why this matters:**

1. **Same defect class as Claim 12.3** (Phase Status Snapshot P4 row Notes pre-BT-001 PIVOT framing) recurring at overview.md derived-view layer. R12 fixed the Phase Status P4 Notes column (intra impl-plan.md surface) but the symmetric surface in overview.md (Impl Tasks row P4 narrative) was missed by R12 §Cascaded Changes (only Impl Plan row L19 was flagged; Impl Tasks row L20 wasn't).

2. **Reader-skim impact**: Tech Lead reading overview.md (canonical entry-point per CLAUDE.md §6 + `/next` Check) sees Impl Tasks row P4 narrative saying `"numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session"` (pre-BT-001 paired-bundle separate-buckets framing) → infers operator must run **two** separate-bucket regressions. Per post-BT-001 (Impl Plan L1988 + L2010), operator runs **one** default-build session that produces both NFR-1.1 Bucket A + IMPL-063 G4-ON leg simultaneously + a second G4-OFF leg (forensic toggle build) for the informational delta — same operator-session count but different topology semantic. Reader gets contradictory operator-action signal from overview.md vs impl-plan.md.

3. **R11 §11.1 + R12 §12.2 asymmetry recurrence pattern**: same defect axis as R11 missing IMPL-063 symmetric surgery (R12 §12.2) — fix-scope intent (BT-001 vocabulary cascade) was wider than literal target (impl-plan.md task blocks). R12 §Cascaded Changes claimed `"overview.md § Impl Plan row update documented as cascaded follow-up but not edited this round (see Known Follow-ups)"` — only flagged the **Impl Plan row** (L19), not the **Impl Tasks row** (L20). Same fix-scope-narrower-than-defect-class recurrence.

**Minimum acceptable fix:**

L20 Impl Tasks row P4 narrative parenthetical replace:

`"P4 17/17 ✅ (IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session)"` → `"P4 17/17 ✅ ~~(pre-BT-001: IMPL-063 structural closed 2026-05-10 — Bucket B regression .ini + report skeleton; numeric drain paired with IMPL-062 + IMPL-FIX-006 operator session)~~ **(post-BT-001 R12 §12.2/12.4):** IMPL-062 + IMPL-063 partial-re-open structurally per R11 §11.1 + R12 §12.2 S-AC un-`[x]` surgery (1/3 + 1/3 S-AC `[x]` respectively; remaining un-strikethrough new `[ ]`); Closed paragraphs preserve original 2026-05-05/10 closure stats as audit history; current effective closure pending operator default-build single-pass run producing **rewrite-G4-ON Bucket A (NFR-1.1) + IMPL-063 G4-ON leg of informational Bucket B in one session + G4-OFF leg via forensic toggle build for informational delta** — paired-bundle topology now `rewrite-G4-ON ↔ rewrite-G4-OFF within IMPL-063` (informational delta), not `IMPL-062-vs-IMPL-063-as-separate-buckets`. Matrix denominator 17/17 preserved per R12 §12.4 verdict (no task split / no phase reassignment; the un-`[x]` reflects re-validation pending under redefined contract)."`

**Effort:** Low (1 in-place row narrative parenthetical replace; ~15-20 LOC). Cascaded with Claim 13.1 fix (same overview.md file, 1 commit).

---

### 🟡 MEDIUM

#### Claim 13.3: 🟡 MEDIUM — `impl-plan.md` L2274 Plan Staleness Sentinel narrative paragraph references `/backtrack ba` as future-pending (`"after /backtrack ba resolves NFR-1.1 contract"`); BT-001 closed in R12 §12.1 Path A (backtrack-log.md Status flipped ✅ Resolved); same Phase Status Notes-class stale-conditional defect (Claim 12.3) recurring at Sentinel-paragraph layer

**Location:** `docs/state/impl-plan.md` L2274 § Plan Staleness Sentinel narrative paragraph (between the canonical Sentinel state block and the Closure Hygiene Status block):

`"> Per /next Check 5.8: plan staleness recommendation triggers when (approved > 30d ago) AND (no review OR > 10 closures since review). Currently within threshold; next IMPL-NNN main task closure (likely IMPL-063 paired Bucket B after /backtrack ba resolves NFR-1.1 contract) will reset Sentinel +1. ..."`

**Problem:**

The parenthetical `"(likely IMPL-063 paired Bucket B after /backtrack ba resolves NFR-1.1 contract)"` carries two pre-BT-001 vocabulary defects:

1. `"IMPL-063 paired Bucket B"` — pre-BT-001 framing where IMPL-063 was a separate Bucket B paired with IMPL-062 as separate Bucket A. Post-BT-001 (per R11 §11.6 + R12 §12.2) IMPL-063 is the informational Bucket B delta within itself, not a paired separate-bucket. **Same defect class as Claim 13.2** at sentinel-paragraph layer.

2. `"after /backtrack ba resolves NFR-1.1 contract"` — pre-BT-001 framing where `/backtrack ba` was future-pending. Post-BT-001 (R12 §12.1 Path A) BT-001 is ✅ Resolved 2026-05-13; `/backtrack ba` ran 2026-05-12 + cascade closed via BA Round 04 + Round 05 + SD Round 04 + Round 06 + Impl Plan R11 + R12. The conditional `"after /backtrack ba resolves"` describes a never-future event. **Same defect class as Claim 12.3** (Phase Status Notes column pre-BT-001 PIVOT framing) at sentinel-paragraph layer.

R12's mechanical-gate sweep (Gate #7 Phase Status Notes sweep + Gate #8 narrative-section freshness sweep per workflow.md) explicitly verified post-R12 per `## Closure Hygiene Status` L2283 (`"Gate #7 + Gate #8 explicitly invoked this round to fix R11-introduced P4 Notes column stale framing (Claim 12.3)"`). But the Sentinel narrative paragraph at L2274 is structurally adjacent to the canonical Sentinel block (L2271) and the Closure Hygiene Status block (L2280-2284) — Gate #8 ("narrative-section freshness sweep") covers `## Open Risks` + `## Next Best Action` per workflow.md text + the implicit canonical reader-surface set, but the Plan Staleness Sentinel narrative paragraph (the prose between the table-shaped Sentinel block and Closure Hygiene table) wasn't in Gate #8's explicit enumeration → missed by R12 mechanical-gate sweep.

**Why this matters:**

1. **Same Phase Status Notes-class recurrence pattern**: R10 §10.2 drafted the P4 Notes paragraph with pre-BT-001 PIVOT framing; R11 missed it in BT-001 RESOLVED sweep; R12 §12.3 caught + fixed P4 Notes; R13 now catches the symmetric stale-conditional at Sentinel-paragraph layer. Pattern: narrative-parallel surface authored at round N+0, missed by round N+1's bulk-sweep, caught by round N+2. R10→R11→R12→R13 chain at narrative-prose-stale-framing axis.

2. **Operator-side decision-tree impact (minor)**: An engineer reading `## Plan Staleness Sentinel` for `/next` context sees the parenthetical `"(after /backtrack ba resolves NFR-1.1 contract)"` → infers `/backtrack ba` is still pending → may attempt to re-trigger `/backtrack` (which would either no-op or open a duplicate BT-002). Real-world impact bounded (the canonical Sentinel block L2271 says `"Last review 2026-05-13 R12 ... BT-001 closure"` immediately above, so contradiction is intra-section); but the parenthetical itself describes an impossible future state.

3. **MEDIUM not HIGH** because: (a) the surrounding context (L2271 canonical Sentinel block + L2283 Closure Hygiene mentioning BT-001 closure) immediately resolves the ambiguity for any careful reader; (b) the paragraph is methodology/advisory not load-bearing for engineer dispatch; (c) cascades cleanly via the same R13 rebuttal commit as Claim 13.1 + 13.2.

**Minimum acceptable fix:**

L2274 parenthetical replace:

`"next IMPL-NNN main task closure (likely IMPL-063 paired Bucket B after /backtrack ba resolves NFR-1.1 contract) will reset Sentinel +1"` → `"next IMPL-NNN main task closure (likely IMPL-062 single-pass Bucket A + IMPL-063 informational Bucket B G4-ON leg drained in one operator session per BT-001 R12 §12.1 closure; G4-OFF leg via forensic toggle build for informational delta) will reset Sentinel +1"`

**Effort:** Low (1 in-place parenthetical replace; ~5 LOC).

---

### 🔵 LOW

#### Claim 13.4: 🔵 LOW — `impl-plan.md` L7 TL;DR inline Sentinel boilerplate `"Phase 5 mechanical gates 1+6+11 pending fix-round commit. State Reconciliation 3-file rule honored."` is stale at end of 2026-05-12 IMPL-062 Run #2 entry; post-R11 + R12 the canonical Sentinel block + Closure Hygiene block at L2271/L2283 supersede; minor reader-skim friction

**Location:** `docs/state/impl-plan.md` L7 (TL;DR 2026-05-12 IMPL-062 Run #2 entry, near end of 3990-char block, before the R11 §11.7 update annotation): `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R09 (impl-plan-review chain; FIX-ticket closures ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent). Phase 5 mechanical gates 1+6+11 pending fix-round commit. State Reconciliation 3-file rule honored."`

**Problem:**

The inline boilerplate triad (Sentinel + Phase 5 gates + 3-file rule) is the per-TL;DR-entry style that R10 §10.6 explicitly **deprecated** in favor of the canonical `## Plan Staleness Sentinel` block (L2266-2274) + `## Closure Hygiene Status` block (L2278-2284). R10 §10.6 explicitly says (per L5 Reader-empathy note): `"Closure Hygiene Status (canonical, ไม่ duplicate per entry): see ## Plan Staleness Sentinel + ## Closure Hygiene Status blocks below for Sentinel counter + Phase 5 mechanical-gate status + State Reconciliation 3-file rule status. Per-entry boilerplate intentionally retained inline for audit traceability per fix-round-10 precedent."`

So the inline boilerplate is **retained intentionally per fix-round-10 precedent** as audit history of the closure event's mechanical-gate state at the time of closure. That's R10's documented design choice (not a defect). But the specific text `"Phase 5 mechanical gates 1+6+11 pending fix-round commit"` is **specifically about the 2026-05-12 IMPL-062 Run #2 entry's closure event** — the "pending fix-round commit" was the operator's commit `e75dc2c` (Bucket A 5-yr Run #2 closure) at end-of-2026-05-12. Post-commit, gates 1+6+11 were no longer "pending" but the inline narrative wasn't refreshed. Then R11 ran with its own fix-round (rebuttal-round-11.md commit `a89573d`) + R12 ran with its own fix-round (rebuttal-round-12.md commit pending) — both of which exercise Gates 1-11 per their respective Closure Discipline Notes, but the L7 entry's inline narrative still says "1+6+11 pending."

**Why this matters:**

1. **Audit-history-vs-current-state ambiguity**: R10's design choice (retain inline boilerplate per-entry) optimizes for audit traceability — the inline narrative captures the entry-author's view of gates at commit time. Updating it post-commit would erase that history. But the current text format `"Phase 5 mechanical gates 1+6+11 pending fix-round commit"` reads in **present tense** as if currently pending. Either re-tense ("**were** pending at 2026-05-12 commit `e75dc2c`; subsequent R11/R12 rebuttals re-exercised the full gate set per their Closure Discipline Notes") or accept the ambiguity as audit-discipline cost. R12 chose to preserve inline boilerplates verbatim per fix-round-10 precedent; R13 reviewer agrees the audit-trail discipline is sensible.

2. **LOW not MEDIUM/HIGH** because: (a) the ambiguity is reader-skim friction only, not engineer-dispatch-blocking; (b) R10 § 10.6 design choice is documented + audit history is the more valuable disposition; (c) any reader confused by the inline narrative is immediately resolved by reading L2271 canonical Sentinel block (4 lines below the entry in the typical reading flow).

3. **Optional fix-scope (R13 reviewer note)**: if the rebuttal engineer wants tighter present-tense hygiene, the minimum change would be replacing `"Phase 5 mechanical gates 1+6+11 pending fix-round commit"` with `"Phase 5 mechanical gates 1+6+11 pending at 2026-05-12 commit e75dc2c (subsequent R11/R12 rebuttals re-exercised the full gate set per Closure Discipline Notes)"`. But this is **advisory only** — R10 §10.6 precedent allows verbatim retention.

**Minimum acceptable fix:**

Two options (engineer-side decision):

**Option A (verbatim retention per R10 § 10.6 precedent):** No change. R13 reviewer accepts the audit-trail-vs-currency tradeoff.

**Option B (tense-tighten):** L7 inline replace `"Phase 5 mechanical gates 1+6+11 pending fix-round commit"` → `"Phase 5 mechanical gates 1+6+11 pending at 2026-05-12 commit e75dc2c (subsequent R11/R12 rebuttals re-exercised full gate set per workflow.md gates #1-#11)"`.

R13 reviewer recommends **Option A** (preserves R10 §10.6 design choice + audit traceability; reader is resolved by 4-line scroll to L2271 canonical block). Listed as LOW finding rather than skipped because future readers (engineer, status agent, PM) reading L7 in isolation may not realize the L2271 canonical block exists.

**Effort:** Either Low (Option A = 0 LOC) or Low (Option B = 1 in-place replace; ~3 LOC).

---

## Cross-Document Issues

This round catches **2 cross-document state-reconciliation gaps** all rooted in R12's "Known follow-up" deferral:

| Contradiction | Primary SoT | Derived view (overview.md) |
|---------------|-------------|-----|
| BT-001 lifecycle ✅ Resolved 2026-05-13 (post-R12 §12.1) | `docs/state/backtrack-log.md § BT-001` L29-31 + `impl-plan.md § Plan Staleness Sentinel` L2271 + `current_handoff.md § Last completed action` L5-7 | `overview.md` L19 Impl Plan row still leads with R11 framing only (Claim 13.1); BA row L10 may still carry `"BT-001 still impacts SD"` marker (Claim 13.1 part 2 — verify-pass) |
| IMPL-062/063 post-BT-001 paired-bundle topology = informational delta within IMPL-063 | `docs/state/impl-plan.md` L1988 Closed appendix (R12 §12.4) + L2010 IMPL-063 Closed appendix (R12 §12.2) | `overview.md` L20 Impl Tasks row P4 narrative still says `"numeric drain paired with IMPL-062 + IMPL-FIX-006"` separate-bucket framing (Claim 13.2) |

No new Evolution Sequence violation. No ADR backing gap. No BA↔plan or SD↔plan vocabulary desync at impl-plan.md primary surface (R11 §11.1/11.6 + R12 §12.2/12.4 drained those).

---

## Recurring Weaknesses (rounds 06-12)

1. **State-reconciliation defect-class progression continues at next-finer granularity each round** (per R12 § Recurring Weaknesses #1):
   - R06/R07: TL;DR↔registry drift (within `impl-plan.md`).
   - R08: Phase Status Notes + Open Risks + Next Best Action (intra-narrative-parallel sections).
   - R09: TL;DR↔diagnostic-artifact drift (one external artifact).
   - R10: TL;DR↔Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh (intra-narrative-parallel batch).
   - R11: upstream-vs-impl-plan (BA `03` + SD `08` Last-updated 2026-05-12 vs impl-plan IMPL-062/063 pre-BT-001 framing) — caught BA-as-Master cascade gap.
   - R12: upstream-lifecycle-state-vs-derived-view (`backtrack-log.md § BT-001 Status` primary lifecycle SoT vs impl-plan ~19 surface annotations) — caught at 5th meta-axis.
   - **R13 (this round)** catches the **derived-view↔derived-derived-view** layer: R12 reconciled backtrack-log↔impl-plan but `overview.md` (itself derived from impl-plan.md) wasn't propagated; defect-class progression now at **6th axis** — propagation depth-of-cascade. Same shape as the R20→R23 chain at source-code-layer (catalog/destination/anchor/exemption-regex) added each round.

2. **R12's own rebuttal introduced 1 self-deferred defect** (Claim 13.1): R12 § Cascaded Changes § Known follow-up explicitly deferred `overview.md` Impl Plan row prepend + BT-001 markers trim, citing read-tool length limit. The premise is methodologically incorrect (Edit tool's old_string uniqueness doesn't require full-line Read). R12 § Closure Discipline Note acknowledged the deferred-improvement-without-expiry recurring-weakness class but committed the same anti-pattern by deferring this 1 surface. Predictable cycle (R10→R11→R12→R13 each round catches prior round's deferred residue).

3. **Methodology-improvement-debt accumulation pattern**: R11 § 11.2 recommended Gate #12 (Upstream BA/SD Last-updated check) + R11 § 11.5 recommended Gate #13 (Handoff Last-completed-action durability) — neither landed in `workflow.md` (verified by R12 grep). R12 § Closure Discipline Note explicitly chose NOT to add a Gate this round, citing R12 § Recurring Weaknesses #3 anti-pattern flag (deferred-improvement-without-expiry). R13 reviewer agrees the methodological caution is valid — adding gates that are then deferred ≠ progress. But the alternative (Cascaded-Changes-narrative-discipline) only works if the rebuttal actually completes the reconciliation. R12's own narrative-discipline failed at Layer 2 propagation, validating the original concern.

   **R13 reviewer recommendation (informal, no separate Claim)**: when a rebuttal advertises a Cascaded-Change-and-not-yet-landed item, the rebuttal MUST either (a) land it inline before closure, OR (b) register it as a `deferred-ac-registry.md` row with owner + expiry ≤14d. R12's "Known follow-up" met neither condition. Codifying this rule in `workflow.md` Gate #15 or in `andm-impl-plan-defender/SKILL.md § Confusion Management Protocol` is the structural fix. Pre-registering as deferred-ac registry row (not workflow.md gate) avoids the gate-debt accumulation concern. R13 reviewer suggests engineer-side decision on whether to land Gate #15-or-equivalent in R13 rebuttal Closure Discipline Note OR as a separate `/update-config` ticket with expiry ≤14d. Either is acceptable; status quo (no codification) accepts the recurrence-class risk.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 13.1 | 🔴 CRITICAL | `overview.md` L19 Impl Plan row R12 closure annotation never landed; R12 deferred citing methodologically-incorrect read-tool length limit; primary↔derived-view state reconciliation gap persists 1 layer below where R12 reconciled (same defect class as R12 Claim 12.1) | `overview.md` L19 + L10 (BA row BT-001 marker trim) | Low (2 Edit tool calls + 1 narrative paragraph) |
| 13.2 | 🟠 HIGH | `overview.md` L20 Impl Tasks row P4 narrative pre-BT-001 separate-bucket framing `"IMPL-063 structural closed ... Bucket B regression ... numeric drain paired with IMPL-062"`; topology now informational delta within IMPL-063 | `overview.md` L20 | Low (1 in-place narrative replace; cascades with 13.1) |
| 13.3 | 🟡 MEDIUM | `impl-plan.md` L2274 Plan Staleness Sentinel narrative parenthetical references `/backtrack ba` as future-pending + `IMPL-063 paired Bucket B` separate-bucket framing; both invalidated by BT-001 R12 §12.1 closure | `impl-plan.md` L2274 | Low (1 parenthetical replace) |
| 13.4 | 🔵 LOW | `impl-plan.md` L7 TL;DR inline Sentinel boilerplate `"Phase 5 mechanical gates 1+6+11 pending fix-round commit"` reads in present tense; R10 §10.6 audit-trail precedent allows verbatim retention but tense-tighten optional | `impl-plan.md` L7 | Low (Option A = 0 LOC; Option B = 1 replace) |

---

## End of Review
