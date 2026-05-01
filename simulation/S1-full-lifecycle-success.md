# S1: Full Lifecycle — Happy Path

> ทีม 1 คน + AI agents ทำโปรเจค TaskFlow ตั้งแต่ต้นจนจบ

---

## Context

- **โปรเจค:** TaskFlow — ระบบจัดการงานสำหรับทีม
- **ทีม:** Developer 1 คน ใช้ AI agents ช่วย
- **Scope:** MVP — สร้าง project, สร้าง task, assign member, kanban board
- **เป้าหมาย:** ผ่านทุก phase ไม่มี backtrack

---

## Timeline

### Day 1: Phase 1A — BA Requirements

```
Session 1: เปิด agent session ใหม่
Action:    Copy ba-requirements-prompt.md → paste เข้า agent
Input:     "ระบบจัดการงานสำหรับทีม 5-10 คน รองรับ kanban board, task assignment, notifications"
Output:    docs/ba/01-05 (5 ไฟล์; v1.2: 06-handoff dropped)
```

**ผลลัพธ์:**
- `01-project-brief.md` — TaskFlow MVP scope
- `02-functional-requirements.md` — 15 user stories (Create Project, Create Task, Assign Member, etc.) + 5 entities (User, Project, Task, Comment, Notification) ฝังใน acceptance criteria
- `05-user-flows.md` — 6 flows (Registration, Create Project, Create Task, Move Task, Assign, Notification) + open questions: real-time strategy for kanban (v1.2: live in flow doc, was BA-06)
- `03-non-functional-requirements.md` — NFR-domain open questions: email delivery for notifications (v1.2: was BA-06)

### Day 1: Phase 1B — System Design

```
Session 2: เปิด agent session ใหม่
Action:    Copy system-design-master-prompt.md → paste
Input:     ชี้ไปที่ docs/ba/01-05 (v1.2)
Output:    docs/design-docs/02-08 (v1.2: 6 docs, gaps 01/06) + docs/adr/ + docs/api-specs/
```

**ผลลัพธ์:**
- เลือก Modular Monolith (ADR-001)
- เลือก PostgreSQL + Redis (ADR-002)
- เลือก WebSocket สำหรับ real-time kanban (ADR-003)
- API specs: `taskflow-api.yaml`

### Day 2: Phase 1C — UX/UI Design

```
Session 3: เปิด agent session ใหม่
Action:    /ux-design auto
Output:    docs/ux/01-05 (v1.1: UX-06 dropped per SD-as-Master)
```

### Day 2: Phase 1D — Technical Design

```
Session 4: เปิด agent session ใหม่
Action:    Copy technical-design-master-prompt.md → paste
Input:     ชี้ไปที่ docs/design-docs/ + docs/ux/ + docs/adr/
Output:    docs/technical-design/02-04 (3 docs) + docs/api-specs/*.yaml + docs/qa/01-test-execution-plan.md
```

**ผลลัพธ์:**
- `api-specs/*.yaml` — 12 endpoints ครบ field types, error codes (SD-owned)
- `02-backend-design.md` — Clean Architecture layers, CQRS handlers
- `03-frontend-design.md` — Component tree ตาม UX, Zustand for state
- `04-database-design.md` — 5 tables + indexes + migration order
- `docs/qa/01-test-execution-plan.md` — 80% coverage target, mock Redis in unit tests

### Day 3: Phase 2 — Design QA

```
Session 5:  /ba-review all          → 5 findings (1 HIGH, 4 MEDIUM)
Session 6:  /ba-rebuttal claim-review-01.md → Accept 4, Reject 1
Session 7:  /ba-review all          → 1 finding (1 LOW) → ผ่าน ✅

Session 8:  /sd-review all          → 7 findings (2 HIGH, 3 MEDIUM, 2 LOW)
Session 9:  /sd-rebuttal claim-review-01.md → Accept 5, Partial 1, Reject 1
Session 10: /sd-review all          → 2 findings (2 LOW) → ผ่าน ✅

Session 11: /ux-review              → stakeholder approve ✅

Session 12: /td-review all          → 6 findings (1 HIGH, 3 MEDIUM, 2 LOW)
Session 13: /td-rebuttal claim-review-01.md → Accept 4, Partial 1, Reject 1
Session 14: /td-review all          → 1 finding (1 LOW) → ผ่าน ✅
```

### Day 4-6: Phase 3 — Implementation

```
Session 15: /impl-plan 1            → 8 tasks (2S, 4M, 2L)
Session 16: /impl-task IMPL-001     → DB schema + migrations (S)
Session 17: /impl-task IMPL-002     → Auth endpoints (M)
Session 18: /impl-task IMPL-003     → Project CRUD (M)
Session 19: /impl-task IMPL-004     → Task CRUD (M)
Session 20: /impl-task IMPL-005     → Kanban WebSocket (L)
Session 21: /impl-task IMPL-006     → Notification system (L)
Session 22: /impl-task IMPL-007     → Frontend pages (M)
Session 23: /impl-task IMPL-008     → Integration tests (S)

Session 24: /impl-review all        → 4 findings (1 HIGH, 3 MEDIUM)
Session 25: /impl-review-fix review-round-01.md → fix all
Session 26: /impl-review all        → 0 findings → ผ่าน ✅
```

### Day 7: Phase 4 — Harden

```
Session 27: /red-team all           → 3 findings (1 CRITICAL, 1 HIGH, 1 MEDIUM)
Session 28: /red-team-rebuttal red-team-round-01.md → fix all
Session 29: /red-team all           → 1 finding (1 LOW) → ผ่าน ✅
```

### Day 7: Phase 5 — Deliver

```
- Update docs/state/ ฉบับสมบูรณ์
- PR → merge to develop
```

---

## Workflow Commands Used (ทั้งหมด)

| Command | Count | Phase |
|---------|-------|-------|
| BA prompt template | 1 | Design |
| SD prompt template | 1 | Design |
| `/ux-design` | 1 | Design |
| TD prompt template | 1 | Design |
| `/ba-review` | 2 | Design QA |
| `/ba-rebuttal` | 1 | Design QA |
| `/sd-review` | 2 | Design QA |
| `/sd-rebuttal` | 1 | Design QA |
| `/ux-review` | 1 | Design QA |
| `/td-review` | 2 | Design QA |
| `/td-rebuttal` | 1 | Design QA |
| `/impl-plan` | 1 | Implement |
| `/impl-task` | 8 | Implement |
| `/impl-review` | 2 | Implement |
| `/impl-review-fix` | 1 | Implement |
| `/red-team` | 2 | Harden |
| `/red-team-rebuttal` | 1 | Harden |
| **Total** | **29 sessions** | **~7 days** |

---

## Methodology Verdict

✅ **PASS** — Methodology ครอบคลุมทุกขั้นตอนของ happy path
- ทุก phase มี command/prompt ชัดเจน
- Review/rebuttal loop จับ issues ก่อน implement
- TD ทำให้ engineer ไม่ต้อง guess design decisions
- Red team จับ security issues ก่อน deliver
