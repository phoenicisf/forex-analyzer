# Implementation Plan Rebuttal Round 08

| Field | Value |
|-------|-------|
| **Round** | 08 |
| **Claim Review** | `claim-review-08.md` |
| **Date** | 2026-05-04 |
| **SKILLs** | andm-impl-plan-defender, code-review |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 4 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` — 4 changes (trailer cleanup, Phase Status P4 Notes rewrite, R-6 narrative refresh, Next Best Action rewrite)
- `.claude/rules/workflow.md` — 1 change (3 new gates #6/#7/#8 added to Phase 5 Closure mechanical gates table + escalation row updated 5→8 gates)

**Tasks split:** none
**Phase reassignments:** none
**Registry rows added/closed:** none (no closure event in this rebuttal — purely state-reconciliation drift fixes)
**Escalations filed:** none

---

## Claim Responses

### Claim 08.1: 🔴 CRITICAL — Trailer file corruption (3× `## End of Plan` markers + 2 dangling content fragments)
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` lines 1755–1767
- What changed: ลบ orphan fragments + duplicate `## End of Plan` headers ทั้งหมด — เหลือเพียง 1 canonical `## End of Plan` marker ที่ปลายไฟล์ (line 1755 หลังลบเศษ)
- Specific deletions:
  - line 1756 (`ew level — engineer should not raise CONFUSION...`) — sed off-by-one fragment ที่ตัดกลางคำว่า "review level"
  - lines 1758–1763 (orphan `---` + duplicate "Reviewer guidance" bullets + duplicate `## End of Plan` ที่ line 1760)
  - lines 1764–1766 (orphan `---` คั่นก่อน duplicate `## End of Plan` สุดท้าย at line 1767)
  - residual line "lan" (artifact ของ first edit pass) — fixed in second edit
- Post-fix verification:
  - `grep -c "^## End of Plan" docs/state/impl-plan.md` → **1** ✅
  - `tail -5 docs/state/impl-plan.md` → ลงท้ายเรียบร้อยด้วย "All 3 variants compile-and-test gate-equivalent..." → `---` → `## End of Plan` ✅
- Cascaded: ดู Cascaded Changes #1 ด้านล่าง (Gate #6 ใหม่ใน workflow.md เพื่อ catch defect class นี้ในอนาคต)

### Claim 08.2: 🟠 HIGH — Phase Status Snapshot P4 row Notes column frozen at pre-IMPL-057 state
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` line 24 (P4 row Notes column)
- What changed: rewrite Notes column tail
  - **ลบ** "🚨 Mid-Phase Audit P4 counter = 5 — THRESHOLD CROSSED. Phase 4 audit triggers BEFORE next P4 task..." block ทั้งย่อหน้า
  - **ลบ** "Next: Phase 4 audit → THEN IMPL-057 (M overload helpers BR-8.4...) → IMPL-059 (L Orchestrator) → IMPL-060 (S entry .mq5)..."
  - **เพิ่ม** "✅ Mid-Phase Audit P4 GREEN 2026-05-04 (Audit Log row §1640)... 8 E-ACs deferred → expiry 2026-05-18... **Next: `/impl-task IMPL-060` (S entry .mq5 thin wrapper)** — closes runnable-surface gap; unblocks 43 deferred-AC rows..."
  - SelfTest narrative updated: 28→36 cases (incorporates IMPL-057 C29-C36 truth tables + IMPL-058 audit + IMPL-059 skeleton)
  - Deferred-AC count synced 5→8 (matches TL;DR claim "8 P4 rows")
- Evidence (new text excerpt): *"**✅ Mid-Phase Audit P4 GREEN 2026-05-04** (Audit Log row 2026-05-04 §1640 — IMPL-057 unblocked... **Next: `/impl-task IMPL-060` (S entry .mq5 thin wrapper)** — closes runnable-surface gap..."*
- Post-fix verification: `grep -nE "Mid-Phase Audit P4 counter = 5|🚨.*THRESHOLD CROSSED" docs/state/impl-plan.md` → **0 hits** ✅
- Cascaded: ดู Cascaded Changes #2 (Gate #7 ใหม่ใน workflow.md = Phase Status Snapshot Notes sweep per closure)

### Claim 08.3: 🟡 MEDIUM — Open Risks R-6 narrative stale (claims P3 has 3 open tasks IMPL-013/034/039)
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § Open Risks line 37 (R-6 row)
- What changed:
  - **ลบ** "+ P3 still has 3 open tasks (IMPL-013/034/039 — IMPL-039 is HIGH RISK G4 fix)"
  - **เพิ่ม** "P3 23/23 ✅ closed 2026-05-04 (IMPL-013/034/039 ทั้งหมดปิดในวันเดียว); P3 retroactive close blocks on same IMPL-060 surface"
  - Recompute timeline: "≈ 28 days nominal" → "P4 chain remaining = IMPL-060 only (S, ~1-2 day) for empirical surface; with today=2026-05-04 → ~13 days slack before first deadline (downgraded from R07-era ~28 days when 6 P4 tasks were open)"
  - Title updated "P2 Phase Gate retroactive-close" → "P2/P3 Phase Gate retroactive-close" (P3 now also blocks on same surface)
  - Earliest mitigation simplified: "prioritize IMPL-053 / IMPL-059 / IMPL-060 first..." → "`/impl-task IMPL-060` next + Tier 1.5 walk via `bootstrap_smoke.ini`"
- Cascaded: ดู Cascaded Changes #3 (Gate #8 ใหม่ใน workflow.md = narrative-section freshness sweep)

### Claim 08.4: 🟡 MEDIUM — "Next Best Action" section frozen at P1-era state
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § Next Best Action lines 41–51
- What changed: full rewrite of 7-line checklist to reflect 2026-05-04 reality:
  - ☑ P1/P2/P3 phases tier 1 closed (with dates + commits)
  - ☑ P4 7/17 closed under Override + EA core surface complete pending IMPL-060
  - ☑ Mid-Phase Audit P4 GREEN 2026-05-04
  - ☐ **`/impl-task IMPL-060`** (top action — pivots TL;DR `Next:` line 13)
  - ☐ Code Review Round R09 — recommended before IMPL-060
  - ☐ Tier 1.5 walk via `bootstrap_smoke.ini` — runnable after IMPL-060
  - ☐ P2 + P3 + P4 Phase Gate close — blocked on IMPL-060+ chain
- Added section header note: *"อัปเดตทุกครั้งที่ปิด task / fix-round / rebuttal — ห้ามคงที่ระหว่างรอบ (per Gate #8 ใน `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`)"*
- Verification: top unchecked item (`☐ /impl-task IMPL-060`) === TL;DR `Next:` pivot ✅
- Cascaded: ดู Cascaded Changes #3 (Gate #8 ใน workflow.md ครอบคลุม Next Best Action sweep ด้วย)

---

## Cascaded Changes

1. **`.claude/rules/workflow.md` — Gate #6 (file integrity post-Edit-batch)**
   - New row: `grep -c "^## End of Plan" docs/state/impl-plan.md == 1` + `tail -3` clean closure check
   - Pass criteria: exactly 1 `## End of Plan` marker; no orphan fragments/partial words/dangling `---`
   - Catches defect class จาก Claim 08.1 (sed off-by-one introduced by R07 cleanup batch)

2. **`.claude/rules/workflow.md` — Gate #7 (Phase Status Snapshot Notes sweep)**
   - New row: every closure must touch the Notes column of the relevant Phase Status Snapshot row (not just TL;DR + Sentinel + Audit Log)
   - Pass criteria: Notes column does NOT contradict TL;DR / Audit Log narrative / Sentinel; no stale "🚨 THRESHOLD CROSSED" or stale "Next:" pointing to closed task
   - Catches defect class จาก Claim 08.2 (intra-plan parallel-narrative scope drift)

3. **`.claude/rules/workflow.md` — Gate #8 (narrative-section freshness sweep)**
   - New row: re-read § Open Risks + § Next Best Action per closure; rewrite/strikethrough invalidated rows
   - Pass criteria: no Open Risks row references closed tasks as still-open; Next Best Action top unchecked item === TL;DR `Next:` pivot
   - Catches defect class จาก Claim 08.3 + Claim 08.4 (parallel-narrative sections diverging from TL;DR canonical)

4. **`.claude/rules/workflow.md` — Failure escalation row updated** "all 5 gates" → "all 8 gates"; expanded artifact-fix list to include trailer cleanup + Phase Status Notes sweep + Open Risks/Next Best Action refresh

5. **`.claude/rules/workflow.md` — "Why this is here" rationale paragraph extended** เพื่อ document defect class ของ R08 (rebuttal-introduced trailer corruption + intra-plan parallel-narrative drift) + ระบุว่า Gates #6-#8 push enforcement ไป **rebuttal-output verification + intra-plan parallel-narrative sweep** (TL;DR ไม่ใช่ canonical source เพียงแห่งเดียว — Phase Status / Open Risks / Next Best Action ก็เป็น reader-facing snapshots ที่ต้อง sync)

> **Note on Plan Staleness Sentinel:** R08 is a *review round* not a *closure*; Sentinel "Closures since last review" remains **0** (set ที่ R07 closure). No bump required.
>
> **Note on overview.md:** ตรวจแล้ว — Last Updated = 2026-05-04 ✅ ตรงกับวันที่ rebuttal; ไม่ต้อง re-sync (R08 ไม่ใช่ task closure event)
>
> **Note on Deferred-AC Registry:** ไม่ touched — no AC text changed, no new defer registered, no Active row resolved

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (4/4) | ทุก finding มี evidence ชัดเจน + minimum acceptable fix concrete; ไม่มี false positive |
| Critical Fixes | 1 | Claim 08.1 — file integrity defect; impact = `/next` + `/impl-task` parsers อาจหยุดที่ `## End of Plan` ตัวแรก แล้วพลาด table changes |
| Tasks Split | 0 | textual cleanup round เท่านั้น; ไม่มี AC restructure |
| Phase Reassignments | 0 | ไม่มี dependency edge เปลี่ยน |
| Net Improvement | trailer integrity restored + 3 narrative-parallel sections (Phase Status P4 Notes / R-6 / Next Best Action) sync กลับมาที่ 2026-05-04 reality + 3 new closure-time gates ใน workflow.md ป้องกัน defect class ของ R06→R07→R08 cycle | |
| Escalations | 0 | ไม่มี Evolution Sequence violation / SD-as-Master conflict |
| Remaining Gaps | 0 | reviewer note recommendation (3 new gates) implemented ครบ |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all CRITICAL/HIGH claims resolved; trailer integrity restored; intra-plan parallel-narrative sections sync; Gates #6-#8 added to break R06→R07→R08 regression cycle (post-this-rebuttal cleanup work itself was verified against new gates)
- [ ] 🔁 Request Re-Review
- [ ] ⛔ Needs Stakeholder Input

**Next operator action:** `/impl-task IMPL-060` (S [ea] entry `PhoenicisNex.mq5` thin wrapper) — gating task for empirical surface; unblocks 43 deferred-AC rows expiring 2026-05-17/18.
