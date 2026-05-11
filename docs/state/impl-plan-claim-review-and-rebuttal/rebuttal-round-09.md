# Implementation Plan Rebuttal Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Claim Review** | `claim-review-09.md` |
| **Date** | 2026-05-11 |
| **SKILLs** | andm-impl-plan-defender, code-review |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` — TL;DR entry prepended; IMPL-FIX-011 parent block re-classified (Phase + S-AC #4 + Description deprecation + Decomposition deprecation + Status R09 paragraph prepended); 4 new sub-ticket blocks inserted (IMPL-FIX-011a/b/c/d)
- `docs/state/deferred-ac-registry.md` — new Active row IMPL-FIX-011 parent (expiry 2026-06-30) inserted above Resolved rows
- `docs/state/overview.md` — row 19 Notes appended with R09 paragraph

**Tasks split:** IMPL-FIX-011 → IMPL-FIX-011 (P4 parent orchestration) + IMPL-FIX-011a (P3 Slot_T, L) + IMPL-FIX-011b (P3 Slot_G2, L) + IMPL-FIX-011c (P3 Slot_G, L) + IMPL-FIX-011d (P3 Slot_B + long-tail, M)
**Phase reassignments:** parent ticket multi-phase `spans P3+P4` → resolved to single P4 (parent) + 4× P3 (sub-tickets)
**Registry rows added/closed:** 1 added (IMPL-FIX-011 parent; expiry 2026-06-30), 0 closed
**Escalations filed:** none (diagnostic § 5.1.3 question about FIX vs IMPL class noted in plan parent block as future-state — operator may invoke `/backtrack sd` later if desired)

---

## Claim Responses

### Claim 09.1: 🔴 CRITICAL — IMPL-FIX-011 เป็น L-XL multi-slot mega-task ที่ violate decomposition rule + empirically falsified 3 รอบ
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-FIX-011 — parent retained as P4 orchestration ticket holding 4 paired-bundle E-ACs only; per-slot architectural-alignment work split into 4 P3 sub-tickets per engineer diagnostic § 5.1.1
- File: `docs/state/impl-plan.md` — 4 new sub-ticket blocks inserted ก่อน IMPL-061: IMPL-FIX-011a [L] Slot_T (6 architectural gaps per diagnostic § 3) / IMPL-FIX-011b [L] Slot_G2 + Step 0 diagnostic prerequisite / IMPL-FIX-011c [L] Slot_G + Step 0 prerequisite / IMPL-FIX-011d [M] Slot_B + conditional long-tail
- File: `docs/state/deferred-ac-registry.md` — new parent row IMPL-FIX-011 with 4 paired-bundle E-ACs + expiry 2026-06-30 (7-week realistic horizon vs prior FIX-006/007/009 absorb-window which was 2-week 2026-05-19)
- Evidence (new text): _"parent of P3 sub-tickets IMPL-FIX-011a/b/c/d post-R09 re-decomposition"_; sub-tickets carry per-slot S-ACs (session-close not deferred)
- Cascaded: TL;DR new entry; overview.md row 19 Notes append; parent block Description hypothesis taxonomy + 5-step Decomposition annotated `[DEPRECATED post-R09 — audit trail only]` (preserved as audit trail for Sessions A/B/C history)

### Claim 09.2: 🔴 CRITICAL — S-AC #4 "≥75% top-5 per-slot |Δ| reduction" gate authored before architectural depth was known; now empirically unreachable
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-FIX-011 parent S-AC #4 — struck through with explicit pointer to sub-tickets; replaced with per-slot enumerated-bucket AC inside each of IMPL-FIX-011a (Slot_T 4 known Q1 buckets from diagnostic § 1.2: 2021-01-06 02:50 / 01-19 01:02 / 02-26 04:00 / 03-30 10:46 + suppress rewrite-only 03-11 08:00) / 011b (Slot_G2 via Step 0 diagnostic) / 011c (Slot_G via Step 0 diagnostic) / 011d (Slot_B 2021-03-04 08:00 + conditional long-tail)
- Parent retains 4 paired-bundle E-ACs (5-yr Bucket A NFR-1.1 + per-slot NFR-1.6 + Bucket B NFR-1.8 + IMPL-063 chain) tied to NFR contract at delivery scale; aggregate ≥75% Q1 gate dropped (Q1 was 3-month sample of 5-yr contract per Finding 09.2 rationale)
- Each sub-ticket S-AC enumerates legacy trigger buckets explicitly per Finding 09.4 (eliminates bucket-shift defect class that aggregate-hides per iter-2/iter-3 evidence)

### Claim 09.3: 🟠 HIGH — Hypothesis space (a)/(b)/(c)/(d)/(e) is non-MECE; (e) "eligibility-predicate divergence" subsumes ≥6 architectural sub-classes
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-FIX-011 parent Description "Hypothesis space" block — annotated **DEPRECATED post-R09** with rationale (Slot_T diagnostic § 3 enumerates 6 sub-classes); preserved as audit trail of Steps 1-3 Sessions A/B/C analysis
- Sub-tickets 011b + 011c each carry **Step 0 architectural-gap diagnostic prerequisite** before any patch commit (mirror Slot_T diagnostic pattern: read-only legacy-source decode + per-slot gap table + Q1 trigger bucket enumeration with sub-path classifiers)
- Sub-ticket 011a already has 6-gap table from diagnostic § 3 — proceeds directly to per-gap patches without separate Step 0 session

### Claim 09.4: 🟠 HIGH — Per-slot empirical gates absent; AC text uses aggregate "within ~10% on top-5 slots" framing that single-tick proxies cannot satisfy
**Verdict:** Accept
**Changes:**
- Folded into 09.2 fix — each sub-ticket S-AC enumerates legacy Q1 trigger buckets explicitly with sub-path classifiers; aggregate "within ~10% on top-5" framing dropped from parent + replaced with per-slot `|Δ| ≤ 1 entry+exit combined` plus enumerated-bucket-must-fire + rewrite-only-fire-must-be-0 contract
- Bucket-shift defects (G2 01-08→01-04+01-15; G 01-14→03-30) are now caught explicitly by enumeration + the "rewrite-only-fire count = 0" clause

### Claim 09.6: 🟠 HIGH — TL;DR `Next:` line points to "Option A continuation" while engineer diagnostic explicitly recommends Option B
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` TL;DR — new entry **prepended** at top dated 2026-05-11 documenting R09 re-decomposition outcome + Option B accepted + sub-ticket list + new registry row + rebuttal report path + recommended next action `/impl-task IMPL-FIX-011a` (Slot_T diagnostic § 3 provides 6-gap fix shape) OR parallel Step 0 diagnostic for 011b/c
- Pre-R09 TL;DR entries preserved as audit trail (one-commit-cycle drift now visible: iter-3 Option A entry → R09 Option B entry, in temporal order)

### Claim 09.5: 🟡 MEDIUM — IMPL-FIX-011 declares multi-phase `**Phase**: spans P3 + P4 + possibly P3` — breaks Phase Gate Blocking semantics
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § IMPL-FIX-011 Phase field rewritten to single phase: **P4 (parent)** for paired-bundle drain; sub-tickets ทั้ง 4 declared single-phase P3 (Per-Slot Implementation)
- xslot-helper latches (if `(b)` hypothesis surfaces at 5-yr scale) intentionally NOT pre-authored — defer authoring until 5-yr Bucket A retry empirically surfaces per-tick emit on remaining 4 helpers (parity with IMPL-FIX-010 conditional-authoring trigger noted in parent Description block + Finding 09.5 fix recommendation)

### Claim 09.7: 🟡 MEDIUM — Deferred-AC registry expiry alignment + paired-bundle pointer needs update on re-decomposition
**Verdict:** Accept
**Changes:**
- File: `docs/state/deferred-ac-registry.md` — new Active row IMPL-FIX-011 inserted at end of Active table (above ~~RESOLVED~~ rows):
  - Owner: Kritsana
  - Opened: 2026-05-11
  - **Expires: 2026-06-30** (~7 weeks; supersedes prior FIX-006/007/009 absorb-window of 2026-05-19)
  - 4 paired-bundle E-ACs documented verbatim from parent task block
  - Risk-if-missed: 🔴 HIGH — if Slot_T/G2/G per-slot AC close but 5-yr Bucket A retry still halts day-1 or > 25% drift → escalate `/backtrack sd` for ADR-013 contract change
- Sub-ticket S-ACs are session-close not deferred (each carries its own per-slot enumerated-bucket Q1 re-canary AC + composite G1 + G2 smoke)
- Existing FIX-006/007/009 row wording about "extend expiry to absorb IMPL-FIX-011 closure window" left as-is (those rows have their own paired-bundle drain contract; not stale enough to warrant edit)

---

## Cascaded Changes

Changes ที่ไม่ได้ cite ใน claims โดยตรงแต่จำเป็นเพื่อ State Reconciliation 3-file rule:

1. **`impl-plan.md` TL;DR** — new entry prepended at top (R09 closure summary + decomposition outcome + sub-ticket list + recommended next action)
2. **`impl-plan.md` § IMPL-FIX-011 parent Status** — R09 paragraph prepended; pre-R09 Status entries preserved as audit trail with explicit label
3. **`impl-plan.md` § IMPL-FIX-011 parent Description (Hypothesis space)** — annotated `[DEPRECATED post-R09]` per Finding 09.3
4. **`impl-plan.md` § IMPL-FIX-011 parent Decomposition** — annotated `[5-step single-task decomposition superseded; sub-tickets carry forward per-slot workflow]` per Findings 09.1/09.2
5. **`overview.md` row 19 Notes** — R09 paragraph appended per CLAUDE.md §6 State Reconciliation 3-file rule
6. **`deferred-ac-registry.md`** — new Active row IMPL-FIX-011 parent (no row was previously present despite plan referencing one — Finding 09.7 captured the gap)
7. **Plan Staleness Sentinel** — unchanged at 0 IMPL-NNN closures since R25 (FIX-ticket re-decomposition is planner-output not engineer-closure, per workflow.md Gate #4 + fix-round-10 precedent)
8. **Phase × Size matrix** — no entry; FIX tickets do not increment matrix counts per recent precedent (FIX-001..FIX-010 all excluded). Sub-tickets follow same rule.
9. **Phase Dependency Graph** — no Mermaid re-render needed (FIX tickets are not nodes in current graph; parent + sub-tickets keep parent-of-paired-bundle relationship internal to FIX-011 block)
10. **SD Hint Alignment audit trail** — unchanged (FIX tickets fall outside SD Hint Alignment scope per workflow.md; H=68/A=67/D=1 unchanged)

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (7/7) | ทุก finding มีหลักฐาน empirical (3 iter falsification + diagnostic § 3-§ 5) + แมพตรงกับ workflow/SKILL rule — ไม่มี finding ที่ defendable ด้วย Phasing Rationale citation |
| Critical Fixes | 2 | 09.1 decomposition + 09.2 AC threshold replacement — ทั้งคู่ก่อนหน้านี้ block engineer ไม่ให้ปิด task อย่าง honest (อีก 9-12 sessions ของ falsified iter รออยู่ถ้าไม่ re-decompose) |
| Tasks Split | 1 → 5 | IMPL-FIX-011 (L-XL parent + 4 sub: 3×L + 1×M); diagnostic § 4.3 estimate ~1,200 LOC × 12-15 sessions ของ {T,G2,G} แตก scope ออกเป็น dispatch-able units |
| Phase Reassignments | 1 multi-phase → 5 single-phase | parent `spans P3+P4` → parent P4 + 4×P3 sub-tickets; resolves `/impl-task` Phase 1.3 grep ambiguity per Finding 09.5 |
| Net Improvement | สูง | Plan ปัจจุบันมี **dispatch-able sub-tickets** ที่ engineer สามารถ pick ได้ทันที (011a มี 6-gap fix shape from diagnostic § 3) แทนที่ open-ended falsification loop. Empirical Closure Discipline restored — sub-ticket S-AC enumerates concrete buckets, ไม่ใช่ aggregate ที่ engineer rationalize ลงไม่ได้ | |
| Escalations | 0 | ไม่มี Evolution Sequence violation หรือ upstream contract change required (สำหรับ R09 scope); FIX vs IMPL class question จาก diagnostic § 5.1.3 noted as future-state — operator escalate ผ่าน `/backtrack sd` ภายหลังได้ |
| Remaining Gaps | 0 (R09 scope) | All 7 findings accept-resolved within rebuttal cycle. Note: 011b/c Step 0 diagnostic sessions ยังไม่ run — engineer จะผลิตที่ task execution time (parity with 011a diagnostic which preceded sub-ticket authoring) |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all Critical/Major claims resolved; sub-tickets carry concrete dispatchable AC; engineer สามารถเริ่ม `/impl-task IMPL-FIX-011a` (Slot_T) ทันที พร้อม 6-gap fix shape จาก diagnostic § 3
- [ ] 🔁 Request Re-Review
- [ ] ⛔ Needs Stakeholder Input

**Recommended next operator action:** dispatch `/impl-task IMPL-FIX-011a` (Slot_T — diagnostic already maps the 6 fixes). OR if parallel capacity available, spawn `/impl-task IMPL-FIX-011b` Step 0 diagnostic session in parallel (read-only legacy decode; no MarketContext schema race with 011a since Step 0 produces artifact-only, no code edits).
