# Implementation Plan Rebuttal Round 11

| Field | Value |
|-------|-------|
| **Round** | 11 |
| **Claim Review** | `claim-review-11.md` |
| **Date** | 2026-05-13 |
| **SKILLs** | andm-impl-plan-defender, code-review |
| **Trigger** | BT-001 Step 3 — Impl Plan re-validate after BA Round 05 ✅ + SD Round 06 ✅ closed 2026-05-13 |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` — 8 edit blocks (IMPL-062 task block full rewrite; IMPL-063 title + Description + Risk; Open Risks R-3; Next Best Action top item + R10 §10.2 historical preservation; P4 Phase Gate Empirical Demo; NFR-1.1 check row; IMPL-FIX-011 parent 4× E-AC footnote; IMPL-FIX-003 Phase 1B closure paragraph; TL;DR L7 BT-001 update annotation)
- `docs/state/overview.md` — 1 edit block (Impl Plan row R11 closure note prepended; R10 narrative preserved as `· prior:` chain)
- `docs/state/current_handoff.md` — 1 edit block (Last completed action set to R11 + Prior action chain to SD Round 06)

**Tasks split:** none
**Phase reassignments:** none
**Registry rows added/closed:** none (BT-001 = AC text rewrite + measurement methodology redefinition, not deferred-AC residue)
**Escalations filed:** none

---

## Claim Responses

### Claim 11.1: 🔴 CRITICAL — IMPL-062 task title + Description + S-AC `[x]` lock in DISABLE_G4_FIXES build path banned by BA `03 § NFR-1.1 Verification` post-BT-001
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-062 (L1970-1986)
- Title rewritten: `"IMPL-062: [M] [ea-qa] — Run regression: rewrite default build (G4 fixes ON, single-pass per BT-001) vs baseline → Bucket A drift (NFR-1.1)"` — mirrors SD `08 § 1.10` line 129 verbatim wording.
- Description rewritten: explicit `"ห้ามใช้ #define DISABLE_G4_FIXES per BA 03 § NFR-1.1 Verification BT-001 re-baseline 2026-05-12"` + cite `regression-bucket-a.md § 4a Run #2 root-cause` + `backtrack-log.md § BT-001`.
- S-AC #1 un-`[x]` with `~~strikethrough~~` audit-trail annotation explaining BT-001 invalidation + new `[ ]` S-AC describing default build (no DISABLE_G4_FIXES) + retention of commit `277cdb2` slot guards as forensic toggle per BT-001 Resolution.
- S-AC #2 un-`[x]` with audit-trail annotation explaining repurpose of `regression_5yr_no_g4.ini` as informational Bucket B `rewrite-G4-OFF` leg per IMPL-063 BT-001 framing.
- E-AC #1 rewritten: dropped "build .ex5 with DISABLE_G4_FIXES" instruction; aligned with rewrite-G4-ON single-pass per BA NFR-1.1; prior Run #1/#2 evidence preserved as BT-001 § Empirical Citation audit history.
- E-AC #2 unchanged (`deferred` paired bundle wording still correct).
- Status row R10 §10.4 replaced (see Claim 11.3) — full rewrite to `✅ READY TO RE-EXECUTE` post-BT-001.
- Audit-trail preservation: S-AC `[x]` 2026-05-05 strikethrough annotations explicitly cite BT-001 invalidation reason instead of silent rewrite (per State Reconciliation Discipline).

**Cascaded:** none (no phase reassignment; no Phase × Size matrix update; no Mermaid edge change).

---

### Claim 11.2: 🔴 CRITICAL — R10's BLOCKED annotations on 9 sites treat `/backtrack ba` as future-pending; BT-001 closed 2026-05-13
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md`
  - L122 (Open Risks R-3): replaced `⚠️ CONTRACT RE-BASELINE REQUIRED 2026-05-12 (R10 §10.2 update)` framing with `✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2 pivot)`; preserved Run #1 + Run #2 numerics as BT-001 § Empirical Citation audit history; new next-action pointer to re-execute IMPL-062 per rewrite-G4-ON single-pass.
  - L171 (Next Best Action top item): struck through `☐ Operator decision on /backtrack ba scope` (R10 §10.2 (i)/(ii)/(iii) options) as `✅ RESOLVED 2026-05-12 via BT-001`; new top NEXT = `☐ /impl-task IMPL-062` re-execute Bucket A 5-yr default build; historical Option (i)/(ii)/(iii) block preserved by appending `R10 §10.2 (pre-BT-001)` label to existing audit-history block.
  - L1401 (P4 Phase Gate Empirical Demo): replaced `⚠️ BLOCKED 2026-05-12 (R10 §10.4) — pending /backtrack ba NFR-1.1 contract re-baseline` with `✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2)` + methodology summary + Run #1/#2 audit-history pointer.
  - L1406 (NFR-1.1 check row): replaced `⚠️ BLOCKED 2026-05-12 (R10 §10.4) — pending /backtrack ba re-baseline` with `✅ CONTRACT RESOLVED 2026-05-12 via BT-001 (R11 §11.2): methodology redefined rewrite-G4-ON vs baseline single-pass`.
  - L1818-1821 (IMPL-FIX-011 parent 4× E-AC footnote): each `2026-05-12 (R10 §10.4): BLOCKED on R-3 contract re-baseline via /backtrack ba` annotation replaced with `2026-05-12 (R11 §11.2, post-BT-001): ✅ contract resolved` + appropriate per-row context (Bucket A single-pass methodology; per-slot deviation unblocked transitively; Bucket B demoted informational).
  - L1986 (IMPL-062 Status R10 §10.4): replaced full Status block (see Claim 11.3 below).

**Methodology improvement (R11 §11.2 recommendation):** the reviewer recommended adding a new Gate #12 to `workflow.md § Phase 5 Closure mechanical gates` for "Upstream BA/SD Last-updated check" — engineer MUST grep `Last updated:` in `docs/ba/*.md` + `docs/design-docs/0*.md` + `docs/state/backtrack-log.md § Status` before authoring any "BLOCKED on /backtrack X" annotation. **Scope decision:** this rebuttal is in-scope for impl-plan content fixes; the methodology improvement is documented here as a recommendation but not implemented in this round (workflow.md edit deferred to a follow-up `/update-config` or methodology-rebuttal — outside impl-plan-rebuttal scope per `andm-impl-plan-defender/SKILL.md`). Reviewer is free to file as separate ticket.

**Cascaded:** none (annotation rewrite only; no AC change beyond the strikethroughs already counted in 11.1).

---

### Claim 11.3: 🟠 HIGH — IMPL-062 task-block Status "do NOT rerun until contract resolves" actively wrong post-BT-001
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` L1986
- Full Status block rewrite:
  > `**Status (R11 §11.3, 2026-05-13, post-BT-001):** ✅ READY TO RE-EXECUTE — Run #1 (2026-05-10 day-1 stop-out) + Run #2 (2026-05-12 99.998% drift) both under DISABLE_G4_FIXES build attested measurement-contract incompatibility per BA 03 § NFR-1.1 Verification Empirical Citation; BT-001 BA Round 05 + SD Round 06 closed 2026-05-13 redefining NFR-1.1 = rewrite-G4-ON vs baseline single-pass. Next execution = default build (no DISABLE_G4_FIXES) over 5-yr 2021-2025, paired with IMPL-063 informational Bucket B. Prior Run #1/#2 evidence preserved at _session-handoff/IMPL-062-bucket-a-5yr-partial-20260510.{md,txt} + IMPL-FIX-003-bucket-a-5yr-partial-20260512.{txt,jsonl} + regression-bucket-a.md § 4a/§ 5 § Empirical Citation. Prior R10 §10.4 BLOCKED annotation (~~"BLOCKED on /backtrack ba contract re-baseline; do NOT rerun until contract resolves"~~) ✅ RESOLVED 2026-05-12 via BT-001 — annotation premise was that /backtrack ba is future-pending, but BT-001 chain was already at Step 3 (R10 itself) and BA+SD cascade had landed earlier that day.`

The wrong-direction `"do NOT rerun"` halt instruction is replaced with explicit `✅ READY TO RE-EXECUTE` + the BT-001 Resolution direction (run default build, single-pass).

**Cascaded:** none.

---

### Claim 11.4: 🟠 HIGH — IMPL-FIX-003 Phase 1B Closure paragraph TL;DR-vs-task-block drift on registry pointer
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` L1643 (IMPL-FIX-003 Phase 1B Closure paragraph last sentence)
- Rewrite: `"G2/G3/G4 ✅ tracked at deferred-ac-registry.md § Active row IMPL-FIX-003 Phase 1B (expiry 2026-05-26, owner Kritsana, evidence-kinds probe + log-assertion + file-blob-check per R10 §10.5) — closure 2026-05-12 deferred operator session per foreground MT5 lock; pattern byte-identical to Slot_K iter-18 + Slot_B iter-19 (G1 PASS attests no syntax error per mt5-log-reader § Compile semantics); empirical attach/smoke/log verification deferred to Tier 1.5 walk batch-4 OR IMPL-062 Run #3 retry post-BT-001."`

Task-block now carries the same registry pointer that R10 §10.5 added to TL;DR + the registry itself. Closes the same drift class R10 introduced Gates #7/#8 to prevent, now applied at task-block layer.

**Cascaded:** none.

---

### Claim 11.5: 🟠 HIGH — current_handoff.md Last-completed-action durability gap (R10 closure overwritten by sibling SD Round 06)
**Verdict:** Accept (routes via Cascaded Changes per State Reconciliation Discipline)

**Changes:**
- File: `docs/state/current_handoff.md`
- New `Last completed action` block set to R11 rebuttal closure (this round) — durably reflects most-recent close.
- New `Prior action (2026-05-13 earlier)` chain row preserves SD Review Round 06 closure summary; original "Last completed action" body for SD Round 06 retained immediately below as `Previous action (2026-05-12 SD Rebuttal Round 04)` block remains untouched (already in file structure).

**Methodology improvement (R11 §11.5 recommendation):** the reviewer recommended adding a new Gate #13 to `workflow.md § Phase 5 Closure mechanical gates` for "Handoff Last-completed-action durability check" — when multiple `/X-rebuttal` or `/X-review` actions close in same day, engineer MUST verify final state of `current_handoff.md` reflects MOST RECENT close OR carries both as primary + prior-action chain. **Scope decision:** same as Claim 11.2 — recommendation documented; workflow.md edit deferred to follow-up methodology-rebuttal.

**Cascaded:** durability of this rebuttal's own current_handoff.md edit is now verified — R11 is the Last completed action and SD Round 06 is the Prior action chain row; if a future sibling action closes today, that closure must itself chain to R11.

---

### Claim 11.6: 🟡 MEDIUM — IMPL-063 framing "vs baseline" obsolete vs BA NFR-1.8 BT-001 informational delta
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-063 (L1989-2007)
- Title rewritten: `"IMPL-063: [M] [ea-qa] — Measure Bucket B informational delta rewrite-G4-ON − rewrite-G4-OFF (NFR-1.8 BT-001 informational; no acceptance gate)"`.
- Description rewritten: severity downgrade `🔴 HIGH` → `🟡` per BA `03 § NFR-1.8 BT-001 redefined` (line 123/130) Must → Should demotion; explicit `"No pass/fail threshold; no user re-decide trigger"` per BT-001; partial pre-CircuitBreaker BR-3.6 halt window of G4-OFF build per IMPL-062 Run #2 finding acknowledged.
- Input citation updated: `"NFR-1.8 (Bucket B informational, BT-001 redefined rewrite-G4-ON − rewrite-G4-OFF delta — no threshold), ADR-009, BR-7.2, IMPL-062 (Bucket A baseline = rewrite-G4-ON single-pass)"`.
- Risk: `"high (G4 acceptance; potential user re-decide)"` → `"medium (BT-001 demoted NFR-1.8 Must → Should; no re-decide trigger; informational only)"`.
- S-AC text left unchanged (still describes G4-OFF build prerequisite for delta computation; BT-001 acknowledges partial measurement window per IMPL-062 Run #2 finding — annotation embedded in Description).

**Cascaded:** none (no phase reassignment).

---

### Claim 11.7: 🟡 MEDIUM — TL;DR L7 4-option `/backtrack ba` recommended-next-steps body now historical post-BT-001
**Verdict:** Accept

**Changes:**
- File: `docs/state/impl-plan.md` L7 (TL;DR top entry 2026-05-12 IMPL-062 Run #2 catastrophic-fail narrative)
- Appended `**Update 2026-05-13 (R11 §11.7, post-BT-001 closure):**` annotation immediately before the existing trailing boilerplate. Annotation explicitly states Option (1) variant was selected → BT-001 closed → Options (2)/(3)/(4) preserved as historical alternatives but superseded; NFR-1.8 demoted Must → Should informational delta; next action = re-execute IMPL-062 per rewrite-G4-ON single-pass.

Reader landing on TL;DR top entry now sees the post-BT-001 resolution state directly without needing to scroll to Open Risks R-3 or Phase Gate Empirical Demo.

**Cascaded:** none.

---

## Cascaded Changes

Changes propagated to sibling state files (not directly cited in claims but required by State Reconciliation Discipline 3-file rule per CLAUDE.md §6):

1. **`docs/state/overview.md` § Phase Status § Impl Plan row** — R11 closure prepended; R10 prose-only narrative preserved as `· prior:` chain to maintain audit history.
2. **`docs/state/current_handoff.md` § Last completed action** — set to R11 (this rebuttal) per Claim 11.5 durability fix; SD Round 06 chained as Prior action; closes State Reconciliation gap surfaced by R11 §11.5.
3. **No Phase × Size matrix update** — no task split / no phase reassignment.
4. **No Phase Dependency Graph (Mermaid) update** — no new dependency edges.
5. **No SD Hint Alignment audit trail update** — no phase classification change.
6. **No Plan Staleness Sentinel increment** — rebuttal-closure-only round; FIX-tickets + rebuttal artifacts do not increment per workflow.md Gate #4 + fix-round-10 precedent. Sentinel unchanged at 0 IMPL-NNN closures since R09.
7. **No `deferred-ac-registry.md` change** — BT-001 = measurement-methodology rewrite + AC text fix, not new deferred E-AC. Existing IMPL-FIX-003 Phase 1B row (R10 §10.5) + IMPL-FIX-011 parent row (R09 §09.7) unaffected.
8. **Audit-trail discipline:** all 5 R10 §10.4 BLOCKED annotation sites + 4 IMPL-FIX-011 parent footnote annotations explicitly preserve the original wording with `~~strikethrough~~` + `RESOLVED via BT-001` annotation (per CLAUDE.md State Reconciliation Discipline — do not silently rewrite previously-authored rebuttal text; mark struck-through + add resolution annotation).

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (7/7) | ทุก claim มี upstream evidence (BA `03` 2026-05-12 + SD `08` 2026-05-12 + SD Round 06 closure 2026-05-13) ที่ verifiable; ไม่มีข้ออ้างที่ defender จะ reject ได้ |
| Critical Fixes | 2 | 11.1 + 11.2 — ทั้งคู่เป็น cross-document desync ที่ engineer ดูแล้วต้องสะดุดทันที (S-AC `[x]` lock ใน banned build path + 9 BLOCKED annotations ที่ทิศทางผิด) |
| Tasks Split | 0 | BT-001 = AC text rewrite, ไม่ใช่ task decomposition change |
| Phase Reassignments | 0 | No phase moves; IMPL-062/063 remain P4 |
| Net Improvement | impl-plan ↔ BA/SD vocabulary alignment คืน single-voice post-BT-001; `/impl-task IMPL-062` ตอนนี้ unblocked + อ่าน Status row จะได้ direction ที่ถูกต้อง (rewrite-G4-ON single-pass) | |
| Escalations | 0 items | No Evolution Sequence violations; no ADR rewrite needed |
| Remaining Gaps | 0 in-scope | Methodology-improvement recommendations (Gate #12 BA/SD Last-updated check; Gate #13 handoff durability check) flagged in claims 11.2 + 11.5 but deferred to follow-up workflow.md edit — reviewer free to file as separate ticket |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — BT-001 Step 3 (impl-plan re-validate) closed cleanly; next action = `/impl-task IMPL-062` re-execute Bucket A 5-yr regression on rewrite default build (G4-ON, single-pass per BT-001) paired with IMPL-063 informational Bucket B same operator session. BT-001 Step 4 (TD verify, optional parallel) and Step 5 (close BT-001 + trim overview markers) remain pending per `current_handoff.md § BT-001 cascade chain status`.
- [ ] 🔁 Request Re-Review
- [ ] ⛔ Needs Stakeholder Input
