---
description: Analyze impact and execute a phase backtrack when downstream discovers upstream problems
---

# Workflow: Phase Backtrack

ย้อนกลับไป phase ก่อนหน้าเมื่อ downstream พบปัญหาที่แก้ local ไม่ได้

> **Input:** `{{input}}` — target phase to backtrack to: `ba`, `sd`, `ux`, or `td`
> **Example:** `/backtrack sd` — ย้อนไปแก้ System Design

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules
2. `.andm/development-guide/backtrack-workflow.md` — **full backtrack guide, invalidation matrix, process**
3. `docs/state/overview.md` — current phase status
4. `docs/state/backtrack-log.md` — previous backtrack history (if exists)

Once read, proceed.

---

## Phase 1: Validate Backtrack Target

Parse `{{input}}` to determine target phase:

| Input | Target Phase | Deliverables Location |
|-------|-------------|----------------------|
| `ba` | Phase 1A: BA Requirements | `docs/ba/` |
| `sd` | Phase 1B: System Design | `docs/design-docs/`, `docs/adr/`, `docs/api-specs/` |
| `ux` | Phase 1C: UX/UI Design | `docs/ux/` |
| `td` | Phase 1D: Technical Design | `docs/technical-design/` |

**If input is invalid or missing:**
```
❌ ต้องระบุ target phase: /backtrack ba | /backtrack sd | /backtrack ux | /backtrack td
```
→ **STOP**

---

## Phase 2: Gather Context

### 2.1 Identify Current Phase

Read `docs/state/overview.md` to determine what phase the project is currently in.

### 2.2 Validate Backtrack Direction

Check that the backtrack target is actually UPSTREAM of the current phase:

```
Phase order: BA(1A) → SD(1B) → UX(1C) → TD(1D) → Impl(3) → Harden(4)
```

**If target is NOT upstream:**
```
❌ ไม่สามารถ backtrack ไป [target] ได้ — [target] อยู่ downstream หรือเป็น phase ปัจจุบัน
```
→ **STOP**

### 2.3 Ask for Trigger

Ask the user to describe:
1. **What problem was found?** — อะไรที่ทำให้ต้อง backtrack
2. **Where was it found?** — ไฟล์/finding/command อะไร
3. **Why can't it be fixed locally?** — ทำไมแก้ใน phase ปัจจุบันไม่ได้

If user has already provided this context, proceed.

---

## Phase 3: Impact Analysis (MANDATORY)

### 3.1 Determine Invalidated Phases

Use the Invalidation Matrix from `.andm/development-guide/backtrack-workflow.md`:

```
If CHANGED →     BA        SD        UX        TD        Impl Plan   Impl Code   Code Review   Red Team
──────────────────────────────────────────────────────────────────────────────────────────────────────────
BA                 —        ⚠️         ⚠️         ⚠️          ❌            ❌           ❌            ❌
SD                 —         —         ⚠️         ❌          ❌            ❌           ❌            ❌
UX                 —         —          —         ⚠️          ⚠️            ⚠️           ❌            ❌
TD                 —         —          —          —          ❌            ❌           ❌            ❌
```

### 3.2 Scan Existing Deliverables

For each phase that would be impacted, check if deliverables actually exist:

```
Read: docs/ba/*.md            → BA deliverables exist?
Read: docs/design-docs/*.md   → SD deliverables exist?
Read: docs/ux/*.md             → UX deliverables exist?
Read: docs/technical-design/*.md → TD deliverables exist?
Read: docs/state/impl-plan.md → Impl plan exists?
Glob: services/*/              → Implementation code exists?
Read: docs/code-review/*.md    → Code reviews exist?
Read: docs/security/*.md       → Red Team audits exist?
```

Only list deliverables that **actually exist** as impacted.

### 3.3 Generate Impact Report

Write the analysis in this format:

```markdown
## 🔄 Backtrack Impact Analysis

**Trigger:** [ปัญหาที่พบ]
**Current Phase:** [Phase ปัจจุบัน]
**Backtrack Target:** [Phase ที่จะย้อนไป]
**Source:** [ไฟล์/finding ต้นเหตุ]

### Scope of Change
- [สิ่งที่ต้องเปลี่ยนใน target phase]

### Impacted Deliverables

| Phase | Deliverable | Exists? | Impact | Action Needed |
|-------|-------------|---------|--------|---------------|
| [phase] | [file] | ✅/❌ | ⚠️ Re-validate / ❌ Re-run | [คำอธิบาย] |

### Effort Estimate
- **Rework (target phase):** [S/M/L]
- **Re-validation (downstream):** [S/M/L]
- **Total estimated:** [timeframe]

### Risk of NOT Backtracking
- [ผลที่ตามมาถ้าไม่ย้อน]
```

---

## Phase 4: ⏸️ HALT — User Approval

Present the impact analysis and wait for user decision:

1. **✅ Approve backtrack** → proceed to Phase 5
2. **🔄 Modify scope** → adjust what to change, re-analyze
3. **❌ Reject** → user will find workaround in current phase
4. **💬 Need more info** → investigate further before deciding

> ⚠️ **CRITICAL: ห้าม proceed โดยไม่ได้ user approve เด็ดขาด**

---

## Phase 5: Record Backtrack

### 5.1 Create/Append Backtrack Log

If `docs/state/backtrack-log.md` doesn't exist, create it with header:

```markdown
# Backtrack Log

บันทึกการย้อน phase — append-only, ห้ามลบ entries เก่า

---
```

Append new entry:

```markdown
## BT-[NNN] — [Short Title]

- **Date:** [YYYY-MM-DD]
- **Triggered by:** [Phase/Agent ที่พบปัญหา]
- **Source:** [finding file/reference]
- **Backtrack from:** Phase [current] → Phase [target]
- **Reason:** [สาเหตุโดยย่อ]
- **Impacted phases:** [list]
- **Status:** 🔄 Open
- **Resolution:** _(pending)_
```

### 5.2 Update Overview

Update `docs/state/overview.md` with backtrack markers.

Add or update the phase status section to reflect:
- Target phase → `🔄 BACKTRACK — rework in progress (BT-NNN)`
- ⚠️ phases → `⚠️ Pending re-validation (BT-NNN)`
- ❌ phases → `❌ Invalidated (BT-NNN)`

---

## Phase 6: Provide Rework Guidance

Based on the backtrack target, recommend specific commands/actions:

### If backtracking to BA:

```
แนะนำ:
1. เปิด session ใหม่ → แก้ไข docs/ba/ เฉพาะจุดที่ impact
2. Re-run: /ba-review all (ตรวจ BA docs อีกครั้ง)
3. Re-run: /ba-rebuttal [latest claim-review file]
4. แล้ว re-validate downstream: SD → UX → Impl (ตาม impact matrix)
```

### If backtracking to SD:

```
แนะนำ:
1. เปิด session ใหม่ → แก้ไข docs/design-docs/ + docs/adr/ + docs/api-specs/ เฉพาะจุดที่ impact
2. Re-run: /sd-review all (ตรวจ design docs อีกครั้ง)
3. Re-run: /sd-rebuttal [latest claim-review file]
4. แล้ว re-validate downstream: UX → Impl (ตาม impact matrix)
```

### If backtracking to UX:

```
แนะนำ:
1. เปิด session ใหม่ → แก้ไข docs/ux/ เฉพาะจุดที่ impact
2. Re-run: /ux-review (ตรวจ UX deliverables อีกครั้ง)
3. แล้ว re-validate downstream: TD → Impl (ตาม impact matrix)
```

### If backtracking to TD:

```
แนะนำ:
1. เปิด session ใหม่ → แก้ไข docs/technical-design/ เฉพาะจุดที่ impact
2. Re-run: /td-review all (ตรวจ TD docs อีกครั้ง)
3. Re-run: /td-rebuttal [latest claim-review file]
4. bash scripts/validate-rules-sync.sh  (ยืนยัน drift)
5. /project-init --regen  (regenerate CLAUDE.md + .claude/rules/* จาก TD ใหม่ — Phase 2.5)
6. แล้ว re-validate downstream: Impl (ตาม impact matrix)
```

### Commit Convention

ทุก commit ระหว่าง backtrack ต้องมี prefix:

```
[BACKTRACK BT-NNN] <descriptive message>
```

---

## Phase 7: Report Summary

Present final summary to user:

```markdown
## ✅ Backtrack Initiated — BT-[NNN]

| Item | Value |
|------|-------|
| **Target Phase** | [phase] |
| **Trigger** | [short description] |
| **Impacted Phases** | [N] phases |
| **Backtrack Log** | `docs/state/backtrack-log.md` |
| **Next Action** | [first command to run] |

### Re-validation Checklist
- [ ] [Target phase] — rework complete
- [ ] [Phase X] — re-validated
- [ ] [Phase Y] — re-validated
- [ ] Close BT-[NNN] in backtrack-log.md
```

→ **STOP — User proceeds with rework**
