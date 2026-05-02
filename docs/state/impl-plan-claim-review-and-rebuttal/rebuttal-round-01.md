# Implementation Plan Rebuttal Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Claim Review** | `claim-review-01.md` |
| **Date** | 2026-05-02 |
| **SKILLs** | andm-impl-plan-defender, code-review |
| **Defender** | Implementation Plan Defender (Principal Tech Lead) |
| **Plan version pre-rebuttal** | First cut by `/impl-plan 1` on 2026-05-02 |
| **Plan version post-rebuttal** | Round 01 patched (this rebuttal) |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` (7 edit clusters: top callout · Phasing Rationale · IMPL-049 description · 21 slot S-AC/E-AC blocks · P4 Phase Gate · scope-tag glossary footer)
- `docs/state/overview.md` (1 row updated — Impl Plan row appended with rebuttal-01 closure note)

**Tasks split:** 0
**Phase reassignments:** 0
**Registry rows added/closed:** 0 (registries were already empty per Phase 1 baseline; no defer raised)
**Escalations filed:** 0
**Forward references introduced:** 0 (verified by grep on `**Dependencies**:` fields — no edges cross from P_n to P_m, m > n)
**Forbidden closure pattern grep post-fix:** 0 hits ✅

**Sanity checks (per defender SKILL § Sanity Checks):**
- Accept rate = 100% (7/7) — 🟠 Warning threshold (>60%) hit. Reviewer's findings were all **valid polish/clarity issues** in a plan that already passed all CRITICAL/HIGH gates (Silent Copy clean, no forward refs, no forbidden closure patterns). Acceptance is appropriate: reviewer caught real readability + reproducibility gaps that would have surfaced as round-trip cost during P3/P4 Phase Gate review. No defensive bias detected — every accepted finding has concrete evidence ใน plan itself.
- Reject rate of CRITICAL = N/A (0 CRITICAL findings)
- All Partial verdicts = 0 — no hedging.

---

## Claim Responses

### Claim 01.1: 🟡 P3 Phase Gate Tier 1.5 row references per-slot smoke ini files (×21) without backing task

**Verdict:** Accept

**Rationale:** Plan's P3 Tier 1.5 row references `simulation/headless-tests/slot_<X>_smoke.ini` × 21 as exit criterion, but no IMPL-XXX task authors them. PR contract ใน TD-02 §13.6 + `.claude/rules/workflow.md` ระบุว่าทุก slot/orchestrator/cross-slot task ต้อง commit `.ini` file คู่กับ source — แต่ contract ไม่ได้ propagate เข้า slot task S-AC. Reviewer's recommendation (a) chosen — adds explicit S-AC bullet ที่ binds plan ↔ workflow rule directly.

**Changes Made:**
- File: `docs/state/impl-plan.md` § P3 § IMPL-019..IMPL-039 (21 tasks)
- What changed: เพิ่ม S-AC bullet `[ ] commit \`simulation/headless-tests/slot_<X>_smoke.ini\` per TD-02 §13.6 PR contract` ทุก task ของ 21 slots (C/D/F/J/H/K/G/G2/GO/I/M/L/LX/Q/R/P/T/S/B/BR/BI). Slot letter substituted per task (e.g. `slot_C_smoke.ini` for IMPL-019, `slot_BI_smoke.ini` for IMPL-039).
- Evidence (post-fix grep): `grep -c "commit \`simulation/headless-tests/slot_" docs/state/impl-plan.md` = **21** (1 per slot task) ✅
- Cascaded: none — no phase shift, no task ID change, no sizing change, no graph re-render. Phase Gate Tier 1.5 row text unchanged (now correctly references files that will exist by Phase Gate close time).

---

### Claim 01.2: 🟡 Phase % deviation from default template not explicitly quantified

**Verdict:** Accept

**Rationale:** Plan's Phasing Rationale paragraph explained semantic departure (P3 = bulk of business value) but didn't surface **quantitative** deviation: P2 = 16% (vs default 40-50% Core), P4 = 25% (vs default 0-10% Stretch). Stakeholder skim test ของ "P2 Core 16%" without quantitative-justification = mis-interpretation risk ("Core under-scoped?"). Reviewer's recommended fix — append % targets table — adopted with strengthened rationale text.

**Changes Made:**
- File: `docs/state/impl-plan.md` § Phasing Rationale § Phase Shape Choice
- What changed: เพิ่ม "% Targets vs default template" subsection (5-row markdown table + 1 net-interpretation paragraph) ที่:
   - tabulates P1/P2/P3/P4 default % range vs plan % vs deviation;
   - explains P2 −24% to −34% deviation (infrastructure services cluster small in greenfield rewrite — business value lives in P3 slots, not P2 services);
   - explains P4 +15% to +25% deviation (P4 absorbs Polish + Stretch + Verification simultaneously; ไม่มี Could-Have residue per BA W=0; 8 QA verification tasks IMPL-061..068 cluster here);
   - net interpretation: semantic departure reflects MQL5 OO compile/dependency direction, not user-feature increments.
- Evidence (new text excerpt): *"P2 16% — deliberately smaller than default 40-50% Core because business value lives in slots (P3), not infrastructure services (P2) ... P4 25% — absorbs Polish+Stretch+Verification because BA W=0 (no Could-Have residue) and 8 QA verification tasks (IMPL-061..068) cluster here"*
- Cascaded: none — task counts/phases unchanged.

---

### Claim 01.3: 🟡 Scope tags `[ea-qa]` and `[spec]` introduced without glossary entry

**Verdict:** Accept (option **c** — inline glossary footer in `impl-plan.md`)

**Rationale:** Plan introduces `[ea-qa]` (8 tasks IMPL-061..068) + `[spec]` (2 tasks IMPL-044, IMPL-048) ซึ่งไม่อยู่ใน `.claude/stack.json § service_kinds`. Engineer/reviewer auto-detection on scope tag will hit unknown-token state → CONFUSION halt → round-trip cost.

**Reviewer offered 3 options.** Defender chose **option (c)** because:
- Defender SKILL § Scope explicitly limits modifications to `docs/state/impl-plan.md` + `deferred-ac-registry.md` + `overview.md`. Modifying CLAUDE.md / `.claude/rules/ea.md` / `.claude/stack.json` (option a) is **out of rebuttal scope** — those are project-bootstrap artifacts owned by `/project-init`. Option (b) would collapse semantically distinct task kinds (renaming `[ea-qa]` → `[ea]` loses information; dropping `[spec]` weakens reviewer cue for schema-only PRs).
- Option (c) keeps fix localized to plan artifact + provides immediate disambiguation for engineer/reviewer auto-detection. Hardening to CLAUDE.md / rules can follow via `/amend td` or manual edit if user wants permanent baseline change — flagged in **Cascaded Changes** section as recommended next step.

**Changes Made:**
- File: `docs/state/impl-plan.md` (new section "## Scope Tags Glossary (this plan)" appended before "## End of Plan")
- What changed: เพิ่ม inline glossary footer ที่ define 3 scope tag variants (`[ea]`, `[ea-qa]`, `[spec]`) with: (1) tag, (2) used by N tasks, (3) meaning + verification path, (4) rules apply. Plus reviewer guidance block listing expected `[evidence-kind]` E-AC kinds per variant.
- Evidence (new text excerpt):
   > "[ea-qa] = QA-verification subset of [ea] — instrumented build + regression run + report-only output (`docs/state/<report>.md`); no production code path; reviewer focus = empirical data quality + comparison vs baseline, not slot business logic. **Compiles + runs** via Strategy Tester (G1+G3 still apply); G4 evidence = numerical report + baseline diff"
- Cascaded: none. **Recommended follow-up (out of rebuttal scope):** propagate glossary entries to `CLAUDE.md §3` + `.claude/rules/ea.md` + `.claude/stack.json` via `/amend td` for parallel-mode tooling auto-detection hardening — flagged below in **Cascaded Changes**.

---

### Claim 01.4: 🟡 P4 Phase Gate Live-stack health and NFR check rows duplicate

**Verdict:** Accept (option **a** — split content; preserve SKILL template)

**Rationale:** Plan's P4 Phase Gate had Live-stack health row containing 10 NFR sub-bullets, then NFR check row that pointed back ("see Live-stack health row above"). Role confusion ทั้งคู่ — planner SKILL template แยก Live-stack health (= "deploy artifact bootstraps clean from cold state; smoke probe chain green") กับ NFR check (= "specific numbers — e.g., 'p95 latency < 200 ms on /api/orders'"). Plan รวม content into Live-stack health + leave NFR check empty = template drift + duplicate counting risk in `/next` Check 6 + `/impl-review` Dim #5 scoring.

**Changes Made:**
- File: `docs/state/impl-plan.md` § P4 § Phase Gate
- What changed: 
   - **Live-stack health row** rewritten to generic boot/pipeline check: *"PhoenicisNex.ex5 attaches on EURUSD H4 chart + cold-bootstrap from absent state.json restores defaults per [ev=state_corrupt_starting_fresh]; OnInit Phase A+B+C completes clean (16 Init + 2 setters + 8 cleanup guards + 17 magics validated); OnTick F1 14-step pipeline runs without exception across smoke window; binary handoff to Strategy Tester succeeds (run completes, ReportTester-<run-id>.html produced)"*
   - **NFR check row** absorbed all 10 NFR sub-bullets (NFR-1.1 / 1.6 / 1.8 / 2.1 / 2.2 / 2.3 / 3.1 / 3.2 / 3.3 / 7.3) with task-ID citations.
- Evidence (post-fix structure): Live-stack health = 1 paragraph + 0 sub-bullets; NFR check = 1 paragraph + 10 sub-bullets. Each row has distinct role per SKILL template.
- Cascaded: none — Phase Gate row count stays at 9; no Mermaid graph impact; no overview reconciliation needed.

---

### Claim 01.5: 🔵 AC verbosity inconsistent across slot tasks

**Verdict:** Accept (full standardization to bullet style across all 21 P3 slot tasks)

**Rationale:** P3 § IMPL-019..039 used 2 styles inconsistently: full bullet style (~7 tasks) vs bracket-condensed shorthand (~14 tasks, e.g. `**S-AC**: [methods + Magic()=205 + "H,"]`). Junior-dev / new-agent ต้อง expand shorthand ใน head — risk ของ structural-only review missing semantic check during PR review. Reviewer's primary recommendation — full bullet phrasing baseline — adopted per task.

**Changes Made:**
- File: `docs/state/impl-plan.md` § P3 § IMPL-019..IMPL-039 (21 slot tasks)
- What changed: ทุก S-AC + E-AC ของ 21 slot tasks rewrote เป็น full bullet style. Each S-AC has:
   1. "All 6 CSlotBase methods overridden"
   2. Magic() / SlotId() / comment prefix specifics (preserves slot-unique semantics: shared-magic for CD/B/G/L pairs; G4 fix code comments for J + BI; sub-call only for GO/BR; entry-gate dependencies for I/S; sub-modes for P; force-clear integration for M/T/Q)
   3. "Compile clean"
   4. "commit `simulation/headless-tests/slot_<X>_smoke.ini` per TD-02 §13.6 PR contract" (also addresses Claim 01.1)
- Each E-AC standardized to: *"Smoke 60-day backtest with only Slot <X> active → ≥ 1 entry+exit cycle journaled `[log-assertion]` + `[db-inspect]`"* (or slot-specific variant for shared-magic disambig / pyramid / sub-call / force-clear / parasite slots).
- Slot-unique semantics **preserved** (not erased by template):
   - IMPL-022 (J): `// G4 fix BR-7.2` code comment + Bucket B classification + g4-fix-attestation entry
   - IMPL-039 (BI): SL inheritance from B parent + `// G4 fix ADR-009` comment + Bucket B classification + g4-fix-attestation entry
   - IMPL-026 (G2), IMPL-031 (LX), IMPL-039 (BI): CommentParser disambig clause
   - IMPL-027 (GO), IMPL-038 (BR): "sub-call only — not in main topo"
   - IMPL-028 (I), IMPL-036 (S): Entry-gate dependency clause
   - IMPL-029 (M), IMPL-032 (Q), IMPL-035 (T): "M/Q/T-Pending state machine integrated via PendingMachineRegistry (IMPL-049)"
   - IMPL-033 (R): "R-Pending uses legacy timeout (`InpLegacyR_Bars`); no ADR-008 force-clear"
   - IMPL-034 (P): "All 4 sub-modes implemented (PSUB_NONE/N/PX/PH/E)" + comment "PI," for E sub-mode
   - IMPL-025 (G): "ExtraTakeProfit_G wires xslot.TriggerGOverload per BR-8.4"
   - IMPL-037 (B): "ExtraTakeProfit_B wires triggers for BR + BI"
- Cascaded: none — task counts/sizing/dependencies unchanged.

**Note on scope:** P4 cross-slot tasks (IMPL-053..058) + 3 P4 QA tasks (IMPL-066/067/068) still use bracket-condensed S-AC syntax. Reviewer's Claim 01.5 was **explicitly scoped to P3 IMPL-019..039** ("21 slot tasks"). P4 condensed-AC normalization is **out of this rebuttal's scope** — defer to next plan-review round if reviewer flags broader pattern.

---

### Claim 01.6: 🔵 IMPL-049 XL single-layer task lacks per-machine sub-task hint

**Verdict:** Accept (lighter touch — description hint, not task split)

**Rationale:** IMPL-049 = `XL [ea]` single-layer with 8 inner machine classes + cross-machine dispatch + state.json round-trip. Engineer SKILL § Per-Layer Exception ระบุว่า L-XL `[api]/[ea]` engineer applies HALT-protocol — but absent decomposition cue, engineer may bundle 8 machines into 1 commit = 5,000 LOC PR. Reviewer offered 2 options: (a) description hint; (b) split into IMPL-049a/b/c/d. Defender chose **(a)** — description hint preserves engineer's HALT decision authority per SKILL while providing concrete sub-pass cue. Engineer can still split at impl-time if reviewer-throughput risk materializes.

**Changes Made:**
- File: `docs/state/impl-plan.md` § P2 § IMPL-049 § Description
- What changed: appended "Decomposition hint (engineer-side)" block after force-clear journal event description. 4 suggested sub-passes:
   1. Registry skeleton + dispatch (CPendingForce + dispatch loop)
   2. Legacy timeout machines (CPendingC / CPendingCAdx / CPendingR / CPendingP w/ 4 sub-modes)
   3. Force-clear machines per ADR-008 (CPendingM / CPendingT / CPendingQ with `InpForceClearM/T/Q_Bars` thresholds + journal `[ev=force_clear]` event)
   4. State integration (state.json round-trip + journal event wiring + force_clear_count aggregation)
- Engineer-side latitude preserved: "Engineer may instead split IMPL-049 into IMPL-049a/b/c/d during impl-time HALT if commit surface area >5,000 LOC threatens reviewer throughput; document split decision in Mid-Phase Audit Log."
- Cascaded: none — IMPL-049 stays 1 task XL [ea]; sizing unchanged; dependencies unchanged. Mid-Phase Audit Log is the agreed escape hatch for impl-time split.

---

### Claim 01.7: 🔵 TL;DR / executive summary not explicitly labeled

**Verdict:** Accept (lighter touch — title rename, not new section)

**Rationale:** Plan's At-a-Glance callout serves de facto TL;DR role (5 bullets answering "ตอนนี้อยู่ phase ไหน / เหลืออะไร / ต้องระวังอะไร") but lacked explicit "TL;DR" label per planner SKILL Dim #10. Reviewer offered 2 options: (a) new `## TL;DR` section; (b) rename callout title. Defender chose **(b)** — title rename to `📋 **TL;DR / At-a-Glance**` makes label findable for stakeholder skim while preserving existing 5-bullet content + update discipline.

**Changes Made:**
- File: `docs/state/impl-plan.md` (top, line 3 — callout title)
- What changed: `> 📋 **At-a-Glance**` → `> 📋 **TL;DR / At-a-Glance**`
- Evidence (post-fix line 3): *"> 📋 **TL;DR / At-a-Glance** (อัปเดตทุกครั้งที่ปิด task / เกิด finding ใหม่)"*
- Cascaded: none — content of callout unchanged; all 5 bullets preserved (current phase, open risks, next action, deferred-AC count, last updated).

---

## Cascaded Changes

> Changes ที่ **ไม่ได้** cite ใน claims โดยตรง — propagation effects + housekeeping.

1. **`docs/state/overview.md` § Impl Plan row:** appended rebuttal-01 closure note (round 01 = 7 Accept / 0 Partial / 0 Reject / 0 Escalate; 4 MEDIUM + 3 LOW resolved; verdict Ready for Implementation Execution sustained). No row count change (still 1 row per phase). No phase status field changed.

2. **No Phase × Size matrix update needed:** task count remains 68 (4 P1+P2+P3+P4 column totals unchanged: P1=17, P2=11, P3=23, P4=17; size totals unchanged: XS=7, S=23, M=29, L=8, XL=1).

3. **No Phase Dependency Graph re-render needed:** no phase reassignments occurred. Mermaid graphs (Phase Dependency + Task Dependency) untouched.

4. **No SD Hint Alignment audit trail update needed:** classification ✅/⚠️/🔴/◻️ tally unchanged (67 ✅ / 1 ⚠️ / 0 🔴 / 0 ◻️). IMPL-013 P4→P3 divergence justification still stands.

5. **No registry seeding:** `deferred-ac-registry.md` Active table remains empty (no new defer raised by any accepted claim). `operator-action-registry.md` Active table remains empty (no UIR halt; no env-var/secret consumer in Phase 1 per BA `01 § 6.2 Won't Permanent`).

6. **No forward references introduced:** walked all 68 `**Dependencies**:` fields post-fix — every hard dep stays in same or earlier phase. Plan's self-validation note (`**Cross-phase dependency check:** ✅ no forward references found`) remains accurate.

7. **No forbidden closure pattern introduced:** post-fix grep `deferred to operator-runtime|deferred to post-launch|deferred per .* precedent|structurally complete.*deferred|live verification deferred` on `docs/state/impl-plan.md` = **0 hits** ✅.

8. **Mid-Phase Audit Log:** no new row added by this rebuttal (audit log = engineer-owned; defender does not write to it). First row remains "2026-05-02 — Plan generated by `/impl-plan` (first cut)".

### Recommended hardening (out of rebuttal scope) — for user follow-up

**Re: Claim 01.3 option (a) — propagate scope-tag glossary to project-bootstrap artifacts:**
- File: `CLAUDE.md §3 (Architecture Rules)` — add 2 lines explaining `[ea-qa]` + `[spec]` as `[ea]`-derived variants
- File: `.claude/rules/ea.md` (Project Structure section) — note `[ea-qa]` instrumented-build pattern + `[spec]` schema-only pattern
- File: `.claude/stack.json` `service_kinds` array — extend from `["ea"]` to `["ea", "ea-qa", "spec"]` OR add `service_kind_aliases` map
- **Why this matters:** parallel-mode tooling (`/impl-task`, `/impl-review`) auto-detects scope tag; permanent baseline = avoid re-explaining in every plan iteration.
- **How to apply:** invoke `/amend td` (since stack.json + CLAUDE.md derive from TD via `/project-init`) OR manually edit if user prefers direct path.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (7/7) | Reviewer caught 7 valid polish/clarity gaps; ไม่มี false-positive จากเชิง defender perspective. Reviewer's claim review pre-scans (forbidden closure / forward ref / Silent Copy / state reconciliation) ทั้งหมด clean — findings เป็น downstream-readability ที่ surface ตอน Phase Gate close ถ้าไม่แก้ |
| Critical Fixes | 0 | ไม่มี CRITICAL/HIGH ใน round 01 — plan's first cut quality สูง (foundation: Silent Copy clean, dual-track AC compliant, Phase Gate testable, registries initialized, forbidden patterns absent, no forward refs) |
| Tasks Split | 0 | IMPL-049 เลือก description hint แทน split (engineer SKILL precedent for L-XL `[ea]` HALT-protocol latitude) |
| Phase Reassignments | 0 | No reviewer raised phase boundary issue; only IMPL-013 divergence (P4→P3) which already had Service-coupling justification — not flagged in this round |
| Net Improvement | High readability + reproducibility uplift | (1) P3 Phase Gate ↔ slot AC binding closed (Claim 01.1+01.5 combined); (2) % targets transparent for stakeholder skim (Claim 01.2); (3) scope-tag disambig prevents engineer CONFUSION halts (Claim 01.3); (4) P4 Phase Gate row roles restored to SKILL template (Claim 01.4); (5) IMPL-049 decomposition cue prevents 5,000-LOC PR risk (Claim 01.6); (6) TL;DR label findability for stakeholder skim (Claim 01.7) |
| Escalations | 0 items | No Evolution Sequence violation requested; no upstream backtrack required |
| Remaining Gaps | 1 advisory | Recommended hardening: propagate Claim 01.3 scope-tag glossary to CLAUDE.md / `.claude/rules/ea.md` / `.claude/stack.json` via `/amend td` (out of rebuttal scope; non-blocking for IMPL-001 start) |

---

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all 7 findings resolved; plan retains verdict ✅ from reviewer's claim review (pre-scans clean, 0 CRITICAL/HIGH); polish improvements close P3/P4 Phase Gate ambiguity at low effort.
- [ ] 🔁 **Request Re-Review** — N/A (4 MEDIUM resolved with complete fixes; 3 LOW resolved; reviewer's recommendation said `~1 hour, save 1-2 round-trip tomorrow` — actual effort matched estimate).
- [ ] ⛔ **Needs Stakeholder Input** — N/A.

**Engineer next action:** `/impl-task IMPL-001` (XS [ea] — folder structure scaffold + `bootstrap_smoke.ini` stub).

**Optional follow-up after first slot tasks land (P3 ramp-up):** invoke `/amend td` for Claim 01.3 hardening (propagate scope-tag glossary to CLAUDE.md / `.claude/rules/ea.md` / `.claude/stack.json`) — non-blocking for IMPL-001..018 work; surfaces only when first `[ea-qa]` task (IMPL-061) starts in P4.

— Implementation Plan Defender (Principal Tech Lead)
2026-05-02
