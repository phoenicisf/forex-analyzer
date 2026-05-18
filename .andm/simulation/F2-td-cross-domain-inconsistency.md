# F2: TD Review พบ API↔DB Inconsistency — Cross-Domain Fix

> TD Reviewer พบว่า API contract field ไม่ตรงกับ DB schema column + frontend ใช้ชื่อ field ผิด

---

## Context

- **สถานะ:** TD docs 02, 03, 04 สร้างเสร็จ (v1.1: SD-as-Master — TD reduced to 3 docs) กำลังเริ่ม Design QA Phase 2D
- **ปัญหา:** API contract `GET /tasks` return field `dueDate` (camelCase) แต่ DB column ชื่อ `deadline` (ต่างชื่อ) และ frontend component ใช้ `task.due_date` (snake_case) — 3 ชื่อต่างกันหมด
- **Severity:** HIGH — Engineer จะสับสน ไม่รู้ map ยังไง

---

## Timeline

### TD Review

```
Session: /td-review all
```

**Agent (TD Reviewer) พบ — attack vector #17 Cross-Domain Consistency:**

```markdown
### Claim 01.3: 🟠 HIGH — Inconsistent Field Naming: Task Due Date

**Location:**
- File: `01-api-contracts.md`, Section: GET /api/tasks response schema
- File: `04-database-design.md`, Section: tasks table
- File: `03-frontend-design.md`, Section: TaskCard component props

**Problem:**
ฟิลด์วันครบกำหนดของ task มี 3 ชื่อต่างกัน:
- API contract: `dueDate` (camelCase) — line 45
- DB column: `deadline` (completely different word) — line 32
- Frontend prop: `task.due_date` (snake_case) — line 78

ไม่มี mapping documentation ว่า 3 ชื่อนี้หมายถึงสิ่งเดียวกัน

**Why This Matters:**
- Backend engineer จะสร้าง DTO mapping ผิด (deadline → dueDate หรือ due_date?)
- Frontend engineer จะ fetch `dueDate` จาก API แต่ใช้ `due_date` ใน component → bug
- Test engineer จะเขียน test ด้วยชื่อ field ไหนก็ไม่รู้

**Minimum Acceptable Fix:**
เลือก 1 naming convention แล้ว update ทุกที่ให้ตรงกัน:
- DB column: `due_date` (snake_case ตาม PostgreSQL convention)
- API response: `dueDate` (camelCase ตาม JSON convention) — mapping: `due_date` → `dueDate`
- Frontend: `dueDate` (ใช้ชื่อเดียวกับ API response)
- Document mapping ใน `01-api-contracts.md` column mapping section

**Level of Effort:** Medium

---

### Claim 01.5: 🟠 HIGH — Missing Error Codes for PATCH /tasks/:id

**Location:**
- File: `01-api-contracts.md`, Section: PATCH /api/tasks/:id

**Problem:**
API contract สำหรับ PATCH /tasks/:id ระบุแค่ success response (200)
ไม่มี error response สำหรับ: 404 (task not found), 403 (not assignee), 409 (concurrent edit conflict)

**Why This Matters:**
Frontend error handling จะไม่ครอบคลุม — ไม่รู้จะแสดง error message อะไรสำหรับแต่ละ case

**Minimum Acceptable Fix:**
เพิ่ม error response schemas: 400 (validation), 403 (not authorized), 404 (not found), 409 (conflict)
พร้อม error body format: `{ error: { code: string, message: string, details: object } }`

**Level of Effort:** Low
```

### TD Rebuttal

```
Session: /td-rebuttal docs/technical-design/claim-review-and-rebuttal/claim-review-01.md
```

**Agent (TD Defender) วิเคราะห์:**

```markdown
| # | Severity | Title | Verdict | Files to Modify | Cross-Domain Risk |
|---|----------|-------|---------|-----------------|-------------------|
| 3 | HIGH | Inconsistent Field Naming | Accept | 01, 03, 04, 07 | High — 4 docs |
| 5 | HIGH | Missing Error Codes | Accept | 01, 03, 06 | Medium — 3 docs |
```

**⏸️ HALT — User: `proceed`**

**Agent แก้ Claim 01.3 (field naming) — 7-step protocol:**

```
Step 1: Announce — Fixing Claim 01.3: Inconsistent Field Naming
Step 2: Fresh Read — อ่าน 01-api-contracts.md section GET /tasks
Step 3: Cross-Doc Check — Grep "deadline|dueDate|due_date" across all TD docs
         Found in: 01 (3 occurrences), 03 (2), 04 (1), 06 (2), 07 (1)
Step 4: Apply Fix —
  04-database-design.md: rename column `deadline` → `due_date`
  01-api-contracts.md: add mapping note "DB: due_date → API: dueDate"
  03-frontend-design.md: change `task.due_date` → `task.dueDate` (match API response)
Step 5: Verify — re-read ทุกจุดที่แก้
Step 6: Cascade Check —
  06-sequence-diagrams.md: update method param จาก "deadline" → "dueDate" (2 occurrences)
  07-test-strategy.md: update test data field name (1 occurrence)
Step 7: Mark Complete ✅
```

**Agent แก้ Claim 01.5 (missing error codes):**

```
Step 4: Apply Fix —
  01-api-contracts.md: เพิ่ม error responses (400, 403, 404, 409) with body schema
  03-frontend-design.md: เพิ่ม error handling cases ใน TaskEditForm component
  06-sequence-diagrams.md: เพิ่ม error path ใน PATCH task sequence diagram
```

**Final Consistency Sweep:**
```
✅ API field "dueDate" — consistent across 01, 03, 06, 07
✅ DB column "due_date" — consistent in 04, mapping documented in 01
✅ Error codes — consistent between 01 (contract) and 03 (frontend handling)
```

---

## Workflow Commands Used

| Step | Command | Result |
|------|---------|--------|
| 1 | `/td-review all` | พบ 6 findings รวม 2 HIGH cross-domain |
| 2 | `/td-rebuttal claim-review-01.md` | Fix 2 claims → cascade across 5 files |
| 3 | `/td-review all` | ผ่าน ✅ |

---

## Methodology Verdict

✅ **PASS** — TD Review จับ cross-domain inconsistency ที่ SD Review จับไม่ได้
- Attack vector #17 (Cross-Domain Consistency) เป็น TD-specific ที่ SD ไม่มี
- 7-step protocol + cascade check ทำให้แก้ 1 จุดแล้ว update ทุกที่ที่เกี่ยว
- Final consistency sweep verify ว่าไม่มี contradiction เหลือ
- ถ้าไม่มี TD phase นี้ → engineer จะเจอ bug ตอน implement (field name mismatch)
