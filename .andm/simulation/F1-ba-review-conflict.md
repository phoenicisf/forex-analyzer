# F1: BA Review พบ Requirement ขัดแย้ง — Rebuttal Loop

> BA Reviewer พบว่า requirement 2 ข้อขัดแย้งกัน ไม่สามารถ implement ทั้งคู่ได้

---

## Context

- **สถานะ:** BA docs 01-05 สร้างเสร็จ (v1.2: 06-handoff dropped) กำลังเริ่ม Design QA
- **ปัญหา:** FR-005 ระบุว่า "Task ถูก assign ได้แค่ 1 คน" แต่ FR-012 ระบุว่า "หลายคนร่วม work บน task เดียวกันได้"
- **Severity:** CRITICAL — ออกแบบ DB schema ไม่ได้ถ้าไม่ resolve

---

## Timeline

### Round 1: BA Review

```
Session: /ba-review all
```

**Agent (BA Reviewer) พบ:**

```markdown
### Claim 01.1: 🔴 CRITICAL — Contradicting Assignment Model

**Location:**
- File: `02-functional-requirements.md`, Section: Epic-02 Task Management
- File: `02-functional-requirements.md`, Section: Epic-03 Collaboration

**Problem:**
FR-005 ระบุว่า "แต่ละ task มี assignee ได้ 1 คนเท่านั้น" (single-assignee model)
แต่ FR-012 ระบุว่า "สมาชิกหลายคนสามารถร่วม work บน task เดียวกันได้ พร้อมแสดง activity log" (multi-collaborator model)

ทั้ง 2 requirements ไม่สามารถ true พร้อมกันได้ — ถ้า assign ได้แค่ 1 คน แล้วหลายคนร่วม work ยังไง?

**Why This Matters:**
Architect จะไม่รู้ว่า Task entity ควรมี `assignee_id` (FK เดียว) หรือ `task_members` (M2M table)
ถ้าเลือกผิดตั้งแต่ schema design จะต้อง migrate ทีหลัง ซึ่ง costly

**Minimum Acceptable Fix:**
ตัดสินใจ 1 ใน 3 ทาง:
A) Single assignee + read-only collaborators (assignee ทำ, คนอื่นดูได้)
B) Multi-assignee (หลายคน assign ได้)
C) Single assignee + sub-tasks (แตก task ย่อยให้คนอื่น)

**Level of Effort:** Medium
```

### Round 1: BA Rebuttal

```
Session: /ba-rebuttal docs/ba/claim-review-and-rebuttal/claim-review-01.md
```

**Agent (BA Defender) วิเคราะห์:**

```markdown
| # | Severity | Title | Verdict | Files to Modify |
|---|----------|-------|---------|-----------------|
| 1 | CRITICAL | Contradicting Assignment Model | Accept | 03, 06, 07, 08 |
```

**⏸️ HALT — User ตัดสินใจ:**

> User: "เลือก Option A — single assignee + collaborators ที่ดูและ comment ได้แต่ไม่ใช่ assignee"

**Agent แก้ 4 ไฟล์:**

```
02-functional-requirements.md:
  - FR-005: คงเดิม "task มี assignee 1 คน" (Task entity ยังมี assignee_id เดี่ยว)
  - FR-012: แก้เป็น "สมาชิกสามารถเป็น collaborator บน task — ดู, comment, แต่ไม่ใช่ assignee"
  - เพิ่ม FR-012a: "collaborator ไม่สามารถเปลี่ยน status ของ task ได้ เฉพาะ assignee"
  - acceptance criteria ระบุ entity: TaskCollaborator (task_id, user_id, added_at)

05-user-flows.md:
  - Flow-05 (Assign): คงเดิม — assign 1 คน
  - Flow-XX (Collaborate): เพิ่ม — add collaborator, view activity, comment

02-functional-requirements.md § Open Questions (v1.2: was BA-06):
  - เพิ่ม open question: "Assignment model = single assignee + collaborators (M2M) — Architect ตัดสินใจ schema"
```

### Round 2: BA Review

```
Session: /ba-review all
```

**ผลลัพธ์:** 2 findings (1 MEDIUM, 1 LOW) — ไม่มี CRITICAL/HIGH → **ผ่าน ✅**

---

## Workflow Commands Used

| Step | Command | Result |
|------|---------|--------|
| 1 | `/ba-review all` | พบ CRITICAL contradiction |
| 2 | `/ba-rebuttal claim-review-01.md` | User ตัดสินใจ → agent แก้ 4 ไฟล์ |
| 3 | `/ba-review all` | ผ่าน (ไม่มี CRITICAL/HIGH) |

---

## Methodology Verdict

✅ **PASS** — Review/rebuttal loop จับ requirement contradiction ได้
- Reviewer ระบุปัญหาพร้อม 3 options ให้ user เลือก
- HALT point ให้ human ตัดสินใจ (ไม่ให้ AI ตัดสินเอง)
- Defender แก้ cross-doc (FR + user flows + data dictionary + handoff)
- Round 2 verify ว่า fix ถูกต้อง
