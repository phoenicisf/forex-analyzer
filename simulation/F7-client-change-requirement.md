# F7: Client เปลี่ยน Requirement กลางทาง → /amend ba Cascade

> กำลัง implement อยู่ Client โทรมาบอกว่า "ต้องมี task priority (urgent/high/medium/low) ด้วย ลืมบอกตอนแรก"

---

## Context

- **สถานะ:** Phase 3 — implement เสร็จ 5/8 tasks, กำลังทำ IMPL-006
- **ปัญหา:** Client ต้องการ Task Priority feature ที่ไม่มีใน BA/SD/TD — ต้อง amend ตั้งแต่ BA cascade ลงมา
- **ความซับซ้อน:** มี downstream deliverables ครบทุก phase (BA✅ SD✅ UX✅ TD✅ Impl🔄)

---

## Timeline

### Step 1: Amend BA — เพิ่ม requirement

```
Session: /amend ba "เพิ่ม feature Task Priority — task มี priority ได้ 4 ระดับ: urgent, high, medium, low (default: medium) แสดงเป็น color badge บน kanban card, filter/sort by priority ได้"
```

**Impact Analysis:**

```markdown
### Affected Files (BA)

| # | File | Impact | Change Size |
|---|------|--------|-------------|
| 1 | `02-functional-requirements.md` | ✅ | เพิ่ม US-019: Set task priority, US-020: Filter by priority + acceptance criteria ระบุ field priority + enum PriorityLevel |
| 2 | `04-business-rules.md` | ✅ | เพิ่ม BR-013: default priority = medium, BR-014: color mapping |
| 3 | `05-user-flows.md` | ✅ | Update Flow-03 (Create Task): เพิ่ม priority selection step |
| 4 | `03-non-functional-requirements.md` § Open Questions (v1.2: was BA-06) | ✅ | Flag open question: filter/sort indexing strategy (NFR-perf domain) |

### Downstream Impact ⚠️

| Phase | Status | Impact |
|-------|--------|--------|
| SD | ✅ มี docs | ⚠️ ต้อง amend — DB schema เพิ่ม column, API เพิ่ม filter param |
| UX | ✅ มี docs | ⚠️ ต้อง amend — priority badge component, filter UI |
| TD | ✅ มี docs | ⚠️ ต้อง amend — API contract, DB column, frontend component, test cases |
| Impl | 🔄 In progress | ⚠️ ต้อง amend — code ที่ทำไปแล้ว + เพิ่ม task ใหม่ |

### Review Status Impact
| Review | Status | Impact |
|--------|--------|--------|
| BA Review | ✅ ผ่านแล้ว | ⚠️ ควร re-review (เพิ่ม feature ใหม่) |
| SD Review | ✅ ผ่านแล้ว | ⚠️ ควร re-review หลัง amend SD |
| TD Review | ✅ ผ่านแล้ว | ⚠️ ควร re-review หลัง amend TD |
```

**User: `proceed`** → Agent แก้ 5 BA files

**Report:**
```
✅ BA Amendment Complete — 5 files modified
⚠️ Downstream Actions Needed:
  1. /amend sd "เพิ่ม priority column ใน task table, เพิ่ม filter/sort ใน GET /tasks query params"
  2. /amend ux "เพิ่ม priority badge component, เพิ่ม priority filter ใน kanban toolbar"
  3. /amend td "เพิ่ม priority field ใน API contract + DB schema + frontend + test"
  4. เพิ่ม impl task สำหรับ priority feature
```

### Step 2: Amend SD — cascade

```
Session: /amend sd "เพิ่ม priority field ใน Task entity (enum: urgent/high/medium/low), เพิ่ม filter/sort params ใน GET /tasks, update ADR-002 ว่า Redis cache ต้อง invalidate เมื่อ priority เปลี่ยน"
```

→ แก้ 4 ไฟล์: 02-architecture, 03-deep-dive, ADR-002, api-specs/taskflow-api.yaml

### Step 3: Amend UX — cascade

```
Session: /amend ux "เพิ่ม PriorityBadge component (4 colors: red=urgent, orange=high, blue=medium, gray=low), เพิ่ม priority filter dropdown ใน kanban toolbar, เพิ่ม priority selector ใน create/edit task form"
```

→ แก้ 3 ไฟล์: 02-component-inventory, 03-page-layouts, 05-interaction-patterns

### Step 4: Amend TD — cascade (biggest impact)

```
Session: /amend td "เพิ่ม priority field ทุกที่: 01-api-contracts (request/response + filter param), 02-backend-design (PriorityLevel enum + TaskDto), 03-frontend-design (PriorityBadge + PriorityFilter components), 04-database-design (priority column + index), 06-sequence-diagrams (create task flow update), 07-test-strategy (priority filter test cases)"
```

**Impact Analysis shows 6/8 TD files affected:**

```markdown
| # | File | Impact | Change Size |
|---|------|--------|-------------|
| 1 | `01-api-contracts.md` | ✅ | เพิ่ม priority ใน POST/PATCH body + GET query param |
| 2 | `02-backend-design.md` | ✅ | เพิ่ม PriorityLevel enum + update TaskDto |
| 3 | `03-frontend-design.md` | ✅ | เพิ่ม PriorityBadge + PriorityFilter components |
| 4 | `04-database-design.md` | ✅ | เพิ่ม priority column (enum) + index |
| 5 | `06-sequence-diagrams.md` | ✅ | Update create task sequence |
| 6 | `07-test-strategy.md` | ✅ | เพิ่ม priority filter test cases |
| 7 | `05-design-patterns.md` | ❌ | ไม่กระทบ |
| 8 | `08-handoff-to-implementation.md` | ✅ | Update decision registry |
```

→ Agent แก้ 7 ไฟล์ พร้อม cascade check (API field `priority` consistent ข้าม DB, Frontend, Test)

### Step 5: Quick Re-review (optional but recommended)

```
Session: /td-review all
→ 0 CRITICAL/HIGH → ผ่าน ✅ (reviewer ยืนยันว่า priority field consistent ทุกที่)
```

### Step 6: Update impl-plan + add new task

```
Session: /amend td "update 08-handoff-to-implementation.md — เพิ่ม task สำหรับ priority feature"

จากนั้น:
Session: /impl-plan 1 (re-plan with priority feature)
→ เพิ่ม IMPL-009: Add priority column migration (S)
→ เพิ่ม IMPL-010: Priority CRUD + filter API (M)
→ เพิ่ม IMPL-011: Priority UI components (M)

Session: /impl-task IMPL-009 → migration ✅
Session: /impl-task IMPL-010 → API ✅
Session: /impl-task IMPL-011 → Frontend ✅
```

---

## Total Recovery Effort

| Step | Command | Sessions | Time |
|------|---------|----------|------|
| Amend BA | `/amend ba` | 1 | 15 min |
| Amend SD | `/amend sd` | 1 | 20 min |
| Amend UX | `/amend ux` | 1 | 15 min |
| Amend TD | `/amend td` | 1 | 30 min |
| Re-review TD | `/td-review all` | 1 | 20 min |
| Re-plan | `/impl-plan 1` | 1 | 15 min |
| Implement priority | `/impl-task` ×3 | 3 | 2 hr |
| **Total** | | **9 sessions** | **~3-4 hr** |

---

## Methodology Verdict

✅ **PASS** — `/amend` cascade chain (BA→SD→UX→TD→Impl) รองรับ requirement change กลางทาง
- `/amend` ทำ impact analysis ก่อนแก้ทุกครั้ง — user เห็นว่ากระทบอะไรบ้าง
- Cascade chain ชัดเจน: BA→SD→UX→TD→Impl (แต่ละ step มี report + downstream recommendation)
- ไม่ต้อง redo ทั้ง phase — แก้เฉพาะจุดที่เพิ่ม priority feature
- Cross-domain consistency ถูกรักษา (field name consistent ทุก layer)
- Total effort ~3-4 hr แทนที่จะ redo ทุกอย่างตั้งแต่ต้น

### ⚠️ สิ่งที่ methodology ไม่ได้ทำอัตโนมัติ
- **User ต้องสั่ง cascade เอง** — `/amend ba` ไม่ได้ auto-trigger `/amend sd` → user ต้องสั่งตาม recommendation ทีละ step
- **ข้อดี:** Human-in-the-loop ได้ review ทุก step, สามารถ adjust scope ระหว่างทาง
- **ข้อเสีย:** ต้อง copy recommendation จาก step ก่อนมาเป็น input ของ step ถัดไป
