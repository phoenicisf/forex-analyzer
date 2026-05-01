# F6: UX Missing State → /backtrack ux → /amend td

> ระหว่าง implement frontend พบว่า UX ไม่มี empty state สำหรับ project ที่ยังไม่มี task

---

## Context

- **สถานะ:** Phase 3 — implement frontend (IMPL-007)
- **ปัญหา:** Engineer กำลังสร้าง kanban board page แต่ UX `03-page-layouts.md` มีแค่ kanban ที่มี tasks อยู่แล้ว — ไม่มี empty state ("No tasks yet. Create your first task!")
- **ทำไมสำคัญ:** ถ้า hardcode empty state เอง จะไม่ตรงกับ design system (wrong colors, fonts, spacing)

---

## Timeline

### Engineer พบ gap

```
Session: /impl-task IMPL-007 (Frontend pages)
Agent:   กำลัง implement KanbanBoard component
Report:  "⚠️ UX spec ไม่มี empty state สำหรับ kanban board — 
         docs/ux/03-page-layouts.md มีแค่ default state (มี tasks)
         docs/ux/05-interaction-patterns.md ไม่มี empty state pattern สำหรับ kanban
         ไม่สามารถ implement ได้โดยไม่ guess design — แนะนำ /backtrack ux"
```

### Backtrack to UX

```
Session: /backtrack ux
```

**Impact Analysis:**
```markdown
**Trigger:** Frontend implementation ขาด empty state design สำหรับ kanban board
**Backtrack Target:** Phase 1C (UX/UI Design)

### Impacted Deliverables
| Phase | Deliverable | Impact |
|-------|-------------|--------|
| UX | 03-page-layouts.md | ❌ เพิ่ม empty state สำหรับ kanban |
| UX | 05-interaction-patterns.md | ❌ เพิ่ม empty state pattern |
| TD | 03-frontend-design.md | ⚠️ Re-validate — component tree อาจเปลี่ยน |
| Impl | services/web/ | ⚠️ IMPL-007 ต้อง resume หลัง fix |
```

**User: approve**

### Amend UX

```
Session: /amend ux "เพิ่ม empty state สำหรับ kanban board (project ที่ยังไม่มี task) — illustration + CTA button 'Create your first task', ใช้ design tokens จาก 01-design-tokens.md"
```

→ แก้ 2 ไฟล์:
- `03-page-layouts.md`: เพิ่ม kanban empty state layout
- `05-interaction-patterns.md`: เพิ่ม empty state pattern (illustration + CTA)

### Cascade to TD

```
Session: /amend td "update 03-frontend-design.md — เพิ่ม EmptyState component ใน KanbanBoard component tree, props: title, description, actionLabel, onAction"
```

→ แก้ 1 ไฟล์:
- `03-frontend-design.md`: เพิ่ม EmptyState component ใน KanbanBoard children

### Resume Implementation

```
Session: /impl-task IMPL-007 (resume)
→ implement KanbanBoard + EmptyState component ตาม UX + TD ✅
```

### Close Backtrack

```
BT-003 Status: ✅ Resolved
```

---

## Workflow Commands Used

| Step | Command | Sessions | Time |
|------|---------|----------|------|
| 1 | `/impl-task IMPL-007` | 1 | พบ gap |
| 2 | `/backtrack ux` | 1 | 5 min |
| 3 | `/amend ux "..."` | 1 | 10 min |
| 4 | `/amend td "..."` | 1 | 10 min |
| 5 | `/impl-task IMPL-007` (resume) | 1 | continue |
| **Total** | | **5 sessions** | **~30 min recovery** |

---

## Methodology Verdict

✅ **PASS** — Backtrack UX → Amend UX → Cascade TD → Resume impl
- Engineer ตรวจจับ UX gap ระหว่าง implementation (ไม่ guess เอง)
- Recovery เร็ว (~30 min) เพราะ scope เล็ก (1 component)
- Cascade ไป TD ทำให้ component tree ครบ ก่อนกลับไป implement
