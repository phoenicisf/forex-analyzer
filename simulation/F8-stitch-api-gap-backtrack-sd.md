# F8: Stitch Generation Reveals SD API Gap → /backtrack sd

> ระหว่าง generate Stitch screens พบว่า API ไม่มี endpoint สำหรับ dashboard widget ที่ต้องการ

---

## Context

- **สถานะ:** Phase 1C — กำลัง generate UX screens ด้วย Stitch (Path A — มี BA docs ครบ)
- **ปัญหา:** User อยาก dashboard แสดง "team workload summary" (ใครมี task กี่ตัว, overdue กี่ตัว) แต่ตรวจ `docs/api-specs/taskflow-api.yaml` ไม่มี aggregation endpoint
- **ทำไมสำคัญ:** ถ้า design หน้า dashboard โดยมี widget ที่ API ไม่รองรับ → frontend ต้อง fetch N requests แล้ว aggregate เอง (performance problem + business logic leak)

---

## Timeline

### ระหว่าง Stitch Phase 3 — Generate Screens

```
Session: /ux-design stitch (กำลังทำ Phase 3.1)

Agent กำลัง generate Dashboard screen:
  Read: docs/ba/05-user-flows.md → Flow-03: View Dashboard
        "ผู้ใช้เห็น overview ของ project: task distribution per member, 
         overdue tasks count, recent activity"

  Read: docs/api-specs/taskflow-api.yaml → 
        ❌ ไม่มี GET /projects/:id/stats endpoint
        ❌ ไม่มี GET /projects/:id/workload endpoint
        มีแค่ GET /projects/:id/tasks (list ทั้งหมด)
```

**Agent รายงาน:**

```
⚠️ API Gap Detected

BA Flow-03 ต้องการแสดง:
  - Task distribution per member (pie chart / bar chart)
  - Overdue tasks count (badge / metric card)
  - Recent activity feed

API มีแค่:
  - GET /projects/:id/tasks → returns list of all tasks
  - ไม่มี aggregation endpoint

ทางเลือก:
  A) Frontend aggregate เอง (fetch all tasks → compute stats)
     ❌ ไม่แนะนำ: business logic leak + N+1 performance
  B) /backtrack sd → เพิ่ม stats endpoint ใน API design
     ✅ แนะนำ: proper backend aggregation
  C) Design dashboard โดยไม่มี stats widget
     ⚠️ ไม่ตรง BA requirement

แนะนำ: /backtrack sd เพื่อเพิ่ม aggregation endpoints
```

### ⏸️ HALT — User ตัดสินใจ

```
User: "backtrack sd — เพิ่ม endpoint"
```

### Backtrack to SD

```
Session: /backtrack sd
```

**Impact Analysis:**

```markdown
## Backtrack Impact Analysis

**Trigger:** UX Design (Stitch) ต้องการ dashboard stats ที่ API ไม่รองรับ
**Current Phase:** Phase 1C (UX/UI Design)
**Backtrack Target:** Phase 1B (System Design)
**Source:** BA Flow-03 vs api-specs/taskflow-api.yaml

### Scope of Change
- เพิ่ม 2 endpoints ใน API design:
  - GET /projects/:id/stats → { total_tasks, completed, in_progress, overdue }
  - GET /projects/:id/workload → [{ member_id, name, task_count, overdue_count }]

### Invalidated Deliverables
| Phase | Deliverable | Impact | Action Needed |
|-------|-------------|--------|---------------|
| SD | 04-data-flow.md | ⚠️ Re-validate | เพิ่ม data flow สำหรับ stats query |
| SD | api-specs/taskflow-api.yaml | ❌ Re-run | เพิ่ม 2 endpoints |
| UX | (กำลังสร้าง) | ⏸️ Paused | รอ API spec update แล้ว resume |

### Effort Estimate
- Rework: S (เพิ่ม 2 endpoints + 1 data flow)
- Re-validation: S
- Total: ~30 min

### Risk of NOT Backtracking
- Frontend ต้อง fetch all tasks + compute stats เอง
- Performance degrade เมื่อ project มี tasks เยอะ (100+ tasks)
- Business logic (overdue calculation) ซ้ำใน frontend + backend
```

**User: approve**

### Amend SD

```
Session: /amend sd "เพิ่ม 2 aggregation endpoints:
  1. GET /projects/:id/stats → return task counts by status + overdue count
  2. GET /projects/:id/workload → return per-member task distribution
  อัปเดต data flow diagram สำหรับ dashboard stats query"
```

**Agent แก้ 2 ไฟล์:**

```
Amending api-specs/taskflow-api.yaml:
  เพิ่ม paths:
    /projects/{projectId}/stats:
      get:
        summary: Get project statistics
        responses:
          200:
            schema:
              total_tasks: integer
              by_status: { todo: int, in_progress: int, done: int }
              overdue_count: integer
    /projects/{projectId}/workload:
      get:
        summary: Get team workload distribution
        responses:
          200:
            schema:
              members: [{ member_id, display_name, task_count, overdue_count }]

Amending design-docs/04-data-flow.md:
  เพิ่ม sequence diagram: Dashboard Stats Query
    Browser → API → PostgreSQL (aggregate query) → API → Browser
    Note: ใช้ SQL aggregate function, ไม่ fetch all tasks
```

**Report:**

```
✅ SD Amendment Complete — 2 files modified
Downstream: UX (in progress) ต้อง resume ด้วย updated API spec
```

### บันทึก Backtrack

```
docs/state/backtrack-log.md:

## BT-001 — Dashboard Stats API Gap

- **Date:** 2026-04-07
- **Triggered by:** UX Design (Stitch screen generation)
- **Source:** BA Flow-03 vs api-specs gap
- **Backtrack from:** Phase 1C (UX) → Phase 1B (SD)
- **Reason:** Dashboard ต้อง aggregated stats ที่ API ไม่มี endpoint
- **Impact:** 2 files modified (api-spec + data-flow)
- **Status:** ✅ Resolved
```

### Resume Stitch — Generate Dashboard with Stats

```
Session: /ux-design stitch (resume)

Agent: อ่าน updated api-specs/taskflow-api.yaml
  → เห็น stats + workload endpoints

Generate Dashboard screen:
  Tool:   generate_screen_from_text
  Prompt: "Project dashboard page, Modern/Minimal vibe.
          DESIGN SYSTEM: ...
          PAGE STRUCTURE:
          1. Header: project name + breadcrumb
          2. Stats row: 4 metric cards (Total, To Do, In Progress, Overdue)
             — data from GET /projects/:id/stats
          3. Workload section: horizontal bar chart showing tasks per member
             — data from GET /projects/:id/workload  
          4. Kanban board preview: 3 columns with first 5 tasks each
          5. Recent activity feed sidebar"
  Result: ✅ Generated — user approved

→ Continue generating remaining screens...
→ Phase 4: Extract specs → docs/ux/01-05 (v1.1: UX-06 dropped per SD-as-Master)
→ Phase 5: Self-review ✅
→ ⏸️ HALT — User approve ✅
```

---

## Workflow Commands Used

| Step | Command | Sessions | Time |
|------|---------|----------|------|
| 1 | `/ux-design stitch` (start) | 1 | hit API gap |
| 2 | `/backtrack sd` | 1 | 5 min (impact analysis) |
| 3 | `/amend sd "..."` | 1 | 15 min |
| 4 | `/ux-design stitch` (resume) | 1 | continue |
| **Total** | | **4 sessions** | **~20 min recovery** |

---

## Methodology Verdict

✅ **PASS** — Stitch generation ช่วยตรวจจับ API gap ที่ BA/SD review อาจพลาด

**ข้อดี:**
- Stitch ทำให้ต้อง "คิดเป็นหน้าจอจริง" → เจอ gap ที่ abstract design docs ไม่เห็น
- Agent ตรวจ API spec alignment อัตโนมัติก่อน generate → จับ gap เร็ว
- Backtrack scope เล็ก (S-size) → recovery เร็ว ~20 min
- API spec ถูกแก้ก่อนเริ่ม implement → ไม่ต้อง refactor code ทีหลัง

**บทเรียน:**
- **"Visual design catches what text reviews miss"** — เมื่อต้อง generate UI จริง ทำให้ต้อง map data กับ visual elements → เจอ gap ที่ review เอกสารอย่างเดียวไม่เจอ
- Dashboard/analytics pages มักเป็นจุดที่ API gap ซ่อนอยู่ — เพราะต้อง aggregation ที่ CRUD endpoints ไม่รองรับ
- ควร review API specs เทียบกับ BA user flows **ก่อน** เริ่ม UX design — แต่ถ้าพลาดมา Stitch ก็จับได้
