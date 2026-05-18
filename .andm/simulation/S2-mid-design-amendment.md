# S2: Mid-Design Amendment — เพิ่ม Feature หลังทำ BA เสร็จ

> ทำ BA เสร็จแล้ว ปิด session ไปนอน ตื่นมามีไอเดียเพิ่ม "task template" feature

---

## Context

- **สถานะ:** BA docs 01-05 สร้างเสร็จแล้ว (v1.2: 06-handoff dropped) กำลังจะเริ่ม SD
- **ปัญหา:** Developer คิดได้ว่าต้องมี "Task Template" — ให้ user สร้าง template ของ task ที่ใช้บ่อย แล้วสร้าง task จาก template ได้
- **ความกังวล:** ถ้า re-run BA prompt ใหม่ทั้งหมด อาจเสียงานที่ทำไปแล้ว

---

## Timeline

### เช้าวัน Day 2: คิดได้เพิ่ม

```
สถานการณ์: เปิด session ใหม่ มี docs/ba/01-05 (v1.2) อยู่แล้ว
ต้องการ:   เพิ่ม Task Template feature เข้า BA docs ทุกไฟล์ที่เกี่ยว
```

### ใช้ /amend command

```
Session: /amend ba "เพิ่ม feature Task Template — user สร้าง template ของ task ที่ใช้บ่อย (ชื่อ, description, labels, assignee default) แล้วสร้าง task จาก template ได้ ลด repeated work"
```

### Agent ทำ Impact Analysis

```markdown
## Amendment Impact Analysis

**Request:** เพิ่ม Task Template feature
**Target Phase:** BA

### Affected Files

| # | File | Impact | Sections to Modify | Change Size |
|---|------|--------|-------------------|-------------|
| 1 | `02-functional-requirements.md` | ✅ Yes | เพิ่ม Epic: Task Templates (US-016, US-017, US-018) + entity TaskTemplate (fields: name, description, default_labels, default_assignee) ใน acceptance criteria | Add section |
| 2 | `04-business-rules.md` | ✅ Yes | เพิ่ม rules: template field validation, max templates per project | Minor tweak |
| 3 | `05-user-flows.md` | ✅ Yes | เพิ่ม Flow-07: Create Template, Flow-08: Create Task from Template | Add section |
| 4 | `01-project-brief.md` | ❌ No | scope ไม่เปลี่ยน — เป็น feature เสริมใน MVP | — |
| 5 | `03-non-functional-requirements.md` | ❌ No | NFR ไม่เปลี่ยน | — |

> **v1.2 note:** open question "new entity relationship Task↔TaskTemplate (Architect ตัดสินใจ schema)" ไปอยู่ใน `02-functional-requirements.md` § Open Questions แทน เพราะเป็น entity-related (FR domain) — BA-06 dropped

### Downstream Impact

| Phase | Status | Impact |
|-------|--------|--------|
| SD | ❌ ยังไม่มี | ไม่กระทบ — SD จะอ่าน BA ที่ amend แล้ว |
| UX | ❌ ยังไม่มี | ไม่กระทบ |
| TD | ❌ ยังไม่มี | ไม่กระทบ |

### Review Status Impact
ยังไม่มี claim-review → ไม่กระทบ
```

### User ตอบ: `proceed`

### Agent แก้ 4 ไฟล์

```
Amending 02-functional-requirements.md: เพิ่ม Epic-04: Task Templates (3 user stories) + entity TaskTemplate ใน acceptance criteria
Amending 04-business-rules.md: เพิ่ม BR-011: template name unique per project, BR-012: max 20 templates per project
Amending 05-user-flows.md: เพิ่ม Flow-07 + Flow-08 with happy/error paths
Amending 02-functional-requirements.md § Open Questions: เพิ่ม open question: new entity, template→task creation logic (Architect ตัดสินใจ schema) [v1.2: was BA-06]
```

### Report

```
✅ Amendment Complete — 5 files modified

Downstream Actions Needed: ไม่มี (SD/UX/TD ยังไม่ได้สร้าง)
Consistency Verification: ✅ Cross-references consistent
Next Action: เริ่ม SD ได้เลย — รัน `/sd` (workflow wraps system-design-master-prompt.md)
```

---

## Methodology Verdict

✅ **PASS** — `/amend` command รองรับเคสนี้อย่างสมบูรณ์
- Impact analysis ระบุไฟล์ที่กระทบได้ถูกต้อง (5/8)
- Downstream ไม่กระทบเพราะยังไม่มี SD/UX/TD
- ไม่ต้อง re-run BA prompt ใหม่ทั้งหมด
- Cross-document consistency ถูกรักษา
