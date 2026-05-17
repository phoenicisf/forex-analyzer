# System Design Rebuttal Round 06

| Field | Value |
|-------|-------|
| **Round** | 06 |
| **Claim Review** | `claim-review-08.md` |
| **Date** | 2026-05-17 |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |
| **Predecessor** | rebuttal-round-05 (2026-05-17; 7 accept / 0 reject of 7 Round 07 findings — commit `111f092`) → claim-review-08 (2026-05-17; 1 HIGH + 1 LOW residual cascade-completion gaps — verify-only post-rebuttal-05 sweep) |
| **Trigger** | Round 08 surfaces 2 residual cascade-completion gaps that rebuttal-05 did not cover: (a) `08` TL;DR L11 task count + range stale (body recounted via rebuttal-05 Claim 07.1 but TL;DR parallel-narrative deferred at the time as "out-of-scope of Claim 07.1 literal cite"); (b) `03 § 6` Decision Justification row label "Halted state semantic" not re-synced when rebuttal-05 Claim 07.7 merged `02 § 8` Glossary canonical to "HALTED state machine (HALTED / HALTED_STABLE)". Both are completion + cross-doc cite sync class — same R20→R23 "next-finer-granularity sweep" pattern documented in `.claude/rules/workflow.md`. |

> **Naming note:** Filename = `rebuttal-round-06.md` (next sequential rebuttal artifact after rebuttal-round-05). Cycle counter aligns with claim review numbering: claim-review-08 → rebuttal-round-06.

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 2 |
| Partial | 0 |
| Rejected | 0 |

**Accept Rate:** 100% (2/2) — both findings = mechanical cascade-completion (TL;DR ↔ body recount parallel-narrative drift + Decision table cite sync); no defensive-judgment-call rationale. Honest acknowledgment: 08.1 was deferred during rebuttal-05 analysis as "out-of-scope of Claim 07.1 literal cite" — the right call would have been to include it then; this rebuttal-06 closes that 1-round latency gap (per R20 → R23 "next-finer-granularity sweep" pattern in workflow.md).

**Files modified:**
- `docs/design-docs/08-product-breakdown.md` (2 edits — TL;DR L11 task count + range + epic count recount; header L5 BT-002 + Round 08 cite append)
- `docs/design-docs/03-deep-dive.md` (2 edits — § 6 Decision Justification row L334 label sync to canonical "HALTED state machine"; header L5 BT-002 + Round 08 cite append)

**ADRs updated/created:** 0 — no architectural decision change; mechanical cascade-completion + cite sync only.

**API specs updated:** 0.

---

## Claim Responses

### Claim 08.1: 🟠 HIGH — `08` TL;DR L11 task count "~60 implementation tasks (IMPL-001 ถึง IMPL-060)" stale; body recounted to "~67 / IMPL-001 ถึง IMPL-068" post-BT-002 + post-rebuttal-05

**Verdict:** Accept

**Rationale:** Reviewer ถูก — TL;DR L11 = single source of truth สำหรับ Impl Planner / TD agent / QA agent / Tech Lead ที่ scan SD docs ก่อน dive body. Pre-fix TL;DR:
- "**~60 implementation tasks** (IMPL-001 ถึง IMPL-060)"

Body post-rebuttal-05 (commit `111f092`):
- `§ 5` P2 row Total: "**~67 implementation tasks**" (post-BT-002 — was ~68; IMPL-051 cancelled)
- `§ 1.10` enumerated tasks: IMPL-061 ถึง **IMPL-068** (8 QA-Verification tasks: baseline parser + Bucket A regression + Bucket B delta + atomic-write kill test + tick latency + journal latency + DST regression + force-clear validation)
- `§ 4` Per-Task Metadata: last row = IMPL-068
- End-of-doc footer: "67 implementation tasks across 9 epics"

3 inconsistent counts across same doc (TL;DR ~60 / body § 5 ~67 / overview.md SD row narrative ~67) — Phase 5 mechanical gate #2 ("TL;DR ↔ matrix denominator") check pattern class defect. Same root cause class as Round 07 Claim 07.1 (Phase Hint Summary § 5 stale) — both = rebuttal-output verification gap ที่ parallel-narrative sections drift when primary surface fixes.

Additional inconsistency: TL;DR says "**8 epics** (mapped 1:1 ของ BA epics E1-E8 + 1 SD-only epic for cross-cutting hardening)" — actual count = **9 epics** (8 BA-mapped + SD-FOUND foundation services epic visible at `§ 1.1` + SD-QA verification epic at `§ 1.10`). End-of-doc footer correctly states "67 implementation tasks across 9 epics". Fix bundles both count + range + epic-count recount in single edit.

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` TL;DR (L11) + header (L5)
- What changed:
  - TL;DR L11: "**8 epics** (mapped 1:1 ของ BA epics E1-E8 + 1 SD-only epic for cross-cutting hardening), **~60 implementation tasks** (IMPL-001 ถึง IMPL-060)" → "**9 epics** (mapped 1:1 ของ BA epics E1-E8 + 1 SD-only epic SD-FOUND for foundation services + 1 SD-only epic SD-QA for verification), **~67 implementation tasks** (IMPL-001 ถึง IMPL-068; post-BT-002 — was ~68; IMPL-051 `CircuitBreaker::CheckPingPong` cancelled per BT-002 2026-05-17 legacy-parity — see § 1.7 + § 5 footer + end-of-doc footer)"
  - Header L5 append: "+ Round 08 TL;DR recount — ... TL;DR L11 task count + range + epic count recount post-BT-002 per Round 08 Claim 08.1"
- Evidence (new TL;DR L11 prefix): *"เอกสารนี้แตก SD ออกเป็น **work inventory** ที่ Impl Planner หยิบไป assign phase + sprint. **9 epics** (mapped 1:1 ของ BA epics E1-E8 + 1 SD-only epic SD-FOUND for foundation services + 1 SD-only epic SD-QA for verification), **~67 implementation tasks** (IMPL-001 ถึง IMPL-068; post-BT-002 — was ~68; IMPL-051 `CircuitBreaker::CheckPingPong` cancelled per BT-002 2026-05-17 legacy-parity — see § 1.7 + § 5 footer + end-of-doc footer), per-task metadata = risk + must_precede + unlocks + arch_rationale + ADR ref. ..."*
- ADR updated: none

---

### Claim 08.2: 🔵 LOW — `03 § 6` Decision Justification row L334 label "Halted state semantic" out-of-sync with `02 § 8` Glossary canonical "HALTED state machine (HALTED / HALTED_STABLE)" post-rebuttal-05 merge

**Verdict:** Accept

**Rationale:** Reviewer ถูก — rebuttal-05 Claim 07.7 merged `02 § 8` Glossary 2 duplicate entries (L447 "Halted state semantic" + L451 "HALT vs HALT_STABLE") เข้าด้วยกัน ภายใต้ canonical headword "**HALTED state machine (HALTED / HALTED_STABLE)**". `03 § 6` Decision Justification table row L334 ใช้ Decision-column label "Halted state semantic" — phrase ที่ Glossary canonical ไม่ enumerate แล้ว post-rebuttal-05. Cross-doc grep ของ "Halted state semantic" ตอนนี้ return 1 hit (this orphan row) แทน Glossary canonical hit. Soft sync = improve cite consistency + reader trust + future amendment burden reduction.

LOW severity เพราะ:
- Decision-table context (not direct Glossary lookup) — reader ยัง understand label without strict canonical match
- ADR-010 reference intact (decision rationale ครบ)
- Not a duplicate (different section + different context)
- Cosmetic micro-glitch, ไม่ block implementation

แต่ fix simple (1-line edit) + ปิด cross-doc cite drift trajectory ก่อน implementation team consume.

**Changes:**
- File: `docs/design-docs/03-deep-dive.md` § 6 Decision Justification table (L334) + header (L5)
- What changed:
  - Decision-column label: "Halted state semantic" → "HALTED state machine (HALTED / HALTED_STABLE)" (sync to `02 § 8` Glossary canonical)
  - Alternative-column: "Stop everything immediately" → "Stop everything immediately (legacy approach)" (minor clarification that strict-halt = pre-ADR-010 alternative)
  - Why-rejected column: appended ADR-010 invariant cite — "Open positions become orphan = G4 violation; **ADR-010 entry-pass-skip + exit-pass-continue invariant preserves G4**" (link rejection rationale to ADR-010 explicit semantic)
  - ADR-010 cite: bump to "(ADR-010 amended BT-002)" — reflects post-BT-002 amendment status (consistent with `02 § 9` ADR Digest L470 entry + Glossary canonical entry L447 `02 § 8`)
  - Header L5 append: "+ Round 08 cite sync — ... § 6 Decision Justification row L334 label sync to canonical 'HALTED state machine (HALTED / HALTED_STABLE)' per Round 08 Claim 08.2 (mirror `02 § 8` Glossary post-rebuttal-05 merge)"
- Evidence (new `03 § 6` L334): *"| HALTED state machine (HALTED / HALTED_STABLE) | Exit-pass-only + HALTED_STABLE (ADR-010 amended BT-002) | Stop everything immediately (legacy approach) | Open positions become orphan = G4 violation; ADR-010 entry-pass-skip + exit-pass-continue invariant preserves G4 |"*
- ADR updated: none

---

## Cascaded Changes

ทุก fix Round 06 อยู่ใน scope ของ claim citations ตรง — ไม่มี hidden cascade เพิ่ม. Verify-sweep ของ Phase 4 consistency check ของ rebuttal-06:

| Pattern grepped | Pre-rebuttal-06 hits in SD docs | Post-rebuttal-06 hits in SD docs | Status |
|---|---|---|---|
| `~60 implementation tasks` | 1 (`08` TL;DR L11) | 0 | ✅ |
| `IMPL-001 ถึง IMPL-060` | 1 (`08` TL;DR L11) | 0 | ✅ |
| `Halted state semantic` | 1 (`03 § 6` row L334) | 0 | ✅ |
| `~67 implementation tasks` post-fix (new TL;DR addition) | 1 (`08 § 5` footer post-rebuttal-05) | 2 (`08 § 5` footer + `08` TL;DR L11 new) | ✅ Single-voice |
| `IMPL-001 ถึง IMPL-068` post-fix (new TL;DR addition) | 0 | 1 (`08` TL;DR L11 new) | ✅ |
| `HALTED state machine (HALTED` post-fix (Decision row sync) | 1 (`02 § 8` Glossary L447 post-rebuttal-05) | 2 (`02 § 8` + `03 § 6` row L334 new) | ✅ Single-voice |

ทุก residual hit ของ patterns เหล่านี้อยู่ใน `docs/design-docs/claim-review-and-rebuttal/claim-review-*.md` หรือ `rebuttal-round-*.md` (read-only per sd-defender SKILL ownership matrix; preserved as review audit history per Phase 5 mechanical gate #9 clause (c) discipline).

**Language Rule compliance:** ทุก edit ใช้ bilingual code-switched style. TL;DR rewrite ใน `08` — Thai narrative preserved (เอกสารนี้แตก / ที่ Impl Planner หยิบ / per-task metadata) + English tech terms (epics, IMPL-NNN, BT-002, `CircuitBreaker::CheckPingPong`, legacy-parity) untranslated. `03 § 6` row sync — English-only table content already (Decision-Alternative-WhyRejected columns are English compact-table); preserved style; tech terms (HALTED / HALTED_STABLE / ADR-010 / G4 / entry-pass-skip / exit-pass-continue) untranslated. ✅ Mechanical Thai-ratio check unnecessary — table content not subject to Thai-narrative threshold per claim-review-08 § Language check qualitative pass.

**Anti-Duplication trail:** Round 03 cumulative-counter cascade (force_clear_count + throttled_alert_count) — untouched ✅ Pass. Round 04/05 Bucket A/B BT-001 framing — untouched + still semantically valid post-BT-002 ✅ Pass. 7/7 Round 07 findings + 2/2 Round 08 findings = 9 findings resolved across rebuttal-05 + rebuttal-06 chain; verify-sweep shows single-voice across all 18 BT-002 propagation surfaces + 5 cascade-completion surfaces.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (2/2) | Both = mechanical cascade-completion (no defensive judgment); reviewer scoping ถูก |
| Critical Fixes | 0 | BT-002 cascade fundamentals + post-rebuttal-05 cascade closure landed coherently; 2 findings = TL;DR parallel-narrative drift + Decision table cite sync, ไม่ใช่ design integrity |
| ADRs Updated | 0 | No architectural decision change; cascade-completion + cite sync only |
| Net Improvement | TL;DR ↔ body single-voice restored (3 counts ตอนนี้ aligned: TL;DR ~67 / body § 5 ~67 / overview.md ~67); 1 orphan-phrase row label synced to canonical headword | สาย R-3 trajectory clean — TL;DR is the first reader-impression surface, single-voice essential for downstream Impl Planner / TD / QA confidence |
| Remaining Gaps | 0 SD-internal expected | Round 09 verify-only re-review expected 0 finding (final cycle close — mirror Round 03→04 + Round 05→06 clean-closure pattern). ถ้ายังมี finding = next-finer-granularity sweep ของ R20 → R23 chain; iterate until clean. Cross-layer flagged: chained `/backtrack ba` pending operator authorization (intentional sequencing per backtrack-log) + state-doc cascade for symbol-anchor pattern (Impl Planner domain) |

## Recommendation

- [x] ✅ **Ready for Round 09 verify-only re-review** — all 2 Round 08 findings resolved with mechanical edits + cross-doc consistency verified single-voice. Expect 0 finding from Round 09 (final cycle close).
- [ ] 🔁 **Request Re-Review** — N/A; mechanical fixes only, no architectural decision change. Round 09 = standard verify-only re-review per BT-002 closure sequence.
- [ ] ⛔ **Needs Stakeholder Input** — N/A within SD scope. Chained `/backtrack ba` + state-doc cascade-completion = operator-driven next steps per intentional sequencing.

### Post-Rebuttal Sequencing (per `claim-review-08 § Recommended action sequence`)

1. ✅ Rebuttal Round 06 (this file) — closes Round 08 findings (2 accept / 0 partial / 0 reject)
2. Operator update `docs/state/overview.md` Design (SD) row → append `+ rebuttal-round-06 (Round 08 cascade-completion — 2 accept; ready for Round 09 final verify)`; Last Updated bump to 2026-05-17
3. Next: `/sd-review all` Round 09 → expect 0 finding final verify-only (mirror Round 03→04 + Round 05→06 clean-closure pattern)
4. หลัง Round 09 clean → operator authorize chained `/backtrack ba` (BR-3.6 + FR-6.6 demotion at BA layer per `backtrack-log.md § BT-002 Proposed change § Chained /backtrack ba`)
5. หลัง BA cascade clean → operator populate `backtrack-log.md § BT-002 Resolution` cell + flip Status `🔄 Open` → `✅ Closed`; trim `docs/state/overview.md` "🔄 BACKTRACK — SD" markers per Check 0.7 Direction A discipline
6. Optional parallel after Step 3: `/td-review all` re-validate (TD package may need BT-002 cascade — `backtrack-log.md § BT-002 Impacted phases — TD` flags `02-backend-design.md § 5.8` CCircuitBreaker skeleton DELETE + 10 cross-refs)

> **End of Rebuttal Round 06** — 2 findings closed (0 CRITICAL / 1 HIGH / 0 MEDIUM / 1 LOW); BT-002 cascade-completion + cross-doc cite sync in SD narrative sections done; ready for Round 09 final verify-only re-review.
