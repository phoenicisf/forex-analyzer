# S3: UX/UI Design via Stitch — Greenfield (SD-Only Input)

> มี SD docs แล้วแต่ยังไม่มี BA — ต้องการ prototype UI เร็วด้วย Stitch เพื่อ validate กับ stakeholder

---

## Context

- **สถานะ:** Phase 1B เสร็จ — มี `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06) + `docs/adr/` + `docs/api-specs/`
- **ไม่มี:** BA docs (`docs/ba/` ยังไม่ได้สร้าง)
- **เหตุผล:** Developer ทำ SD เองจาก requirement ที่คุยกับ client ปากเปล่า ยังไม่มี formal BA — ต้องการ UI prototype เร็วเพื่อเอาไป demo ก่อนลงมือทำ BA/TD
- **เป้าหมาย:** ได้ `docs/ux/01-05` (v1.1: UX-06 dropped per SD-as-Master) จาก Stitch + SD docs โดยไม่ต้องรอ BA

---

## Timeline

### Day 1 ช่วงเช้า: เตรียม Stitch

```
Session 1: เปิด agent session ใหม่
Action:    npx skills add google-labs-code/stitch-skills@stitch-design -y
Result:    Stitch skill installed
```

### Day 1 ช่วงเช้า: เริ่ม UX Design (Path B — SD-only)

```
Session 2: เปิด agent session ใหม่
Action:    /ux-design stitch
```

**Agent ทำ Phase 1.0 — Detect Input Path:**

```
Glob docs/ba/05-user-flows.md → ❌ Not found
Glob docs/ba/02-functional-requirements.md → ❌ Not found
→ Path B: SD-only fallback
→ แจ้ง user: "ไม่พบ BA docs — จะใช้ SD docs เป็น primary input 
   ทุก screen ที่ infer จาก SD จะถูก flag ⚠️ ASSUMED"
```

**Agent ทำ Phase 1 — Load Context (Path B):**

```
Read: docs/design-docs/08-product-breakdown.md
  → พบ 4 modules: Auth, Projects, Tasks, Notifications
  → Infer 8 screens: Login, Register, Project List, Project Detail, 
    Task Create, Kanban Board, Notification Center, User Settings

Read: docs/design-docs/04-data-flow.md
  → พบ sequence diagrams: Create Task → Assign → Notify → Real-time Update
  → Infer interaction order: form submit → optimistic update → WebSocket push

Read: docs/api-specs/taskflow-api.yaml
  → พบ 12 endpoints
  → Infer data: Task has title, description, status, assignee, labels, due_date
  → Infer actions: CRUD project, CRUD task, move task, assign, mark complete

Read: docs/design-docs/02-high-level-architecture.md
  → Modular Monolith, WebSocket for real-time
```

### Day 1 ช่วงสาย: Setup Design System

**Agent ทำ Phase 2 — Setup Stitch:**

```
Action:   สร้าง .stitch/DESIGN.md
Prompt:   "TaskFlow เป็น project management tool สำหรับทีมเล็ก
          ต้องการ feel ที่ professional แต่ approachable
          เสนอ 2-3 atmosphere options"
```

**Agent เสนอ 3 ตัวเลือก:**

| Option | Vibe | Primary Color | Feel |
|--------|------|---------------|------|
| A | Modern/Minimal | Deep Blue `#1e40af` | Clean, focused, productivity |
| B | Professional | Slate `#334155` + Indigo accent | Sophisticated, enterprise-feel |
| C | Fun/Playful | Violet `#7c3aed` | Energetic, startup-feel |

**User เลือก: Option A — Modern/Minimal**

```
Action:   สร้าง .stitch/DESIGN.md ด้วย:
          - Primary: Deep Blue #1e40af
          - Secondary: Sky Blue #0ea5e9
          - Neutral: Slate scale
          - Typography: Inter (headings) + system-ui (body)
          - Spacing: 4px base
          - Style: rounded-lg, subtle shadows, generous whitespace
```

### Day 1 ช่วงบ่าย: Generate Screens

**Agent ทำ Phase 3 — Generate Screens ทีละหน้า:**

```
Screen 1: Login Page
  Tool:   generate_screen_from_text
  Prompt: "Professional login page, Modern/Minimal vibe.
          DESIGN SYSTEM: Platform Web Desktop-first,
          Palette Deep Blue #1e40af primary, Sky Blue #0ea5e9 accent...
          PAGE STRUCTURE:
          1. Split layout — left: brand illustration, right: login form
          2. Form: email + password + remember me + submit
          3. Links: forgot password, sign up"
  Result: ✅ Generated — user approved

Screen 2: Project List (Dashboard)
  Tool:   generate_screen_from_text
  Prompt: "Dashboard with project cards grid..."
  Result: ✅ Generated — user ขอ edit: "card ใหญ่เกินไป ลดเหลือ 3 columns"
  Tool:   edit_screens → ✅ Refined

Screen 3: Kanban Board  ⚠️ ASSUMED
  Tool:   generate_screen_from_text
  Prompt: "Kanban board with 3 columns: To Do, In Progress, Done.
          Cards show: title, assignee avatar, labels, due date.
          Drag and drop between columns..."
  Note:   ⚠️ Column names (To Do, In Progress, Done) inferred from 
          api-specs status enum — ไม่มี user flow ยืนยัน
  Result: ✅ Generated — user approved

Screen 4: Task Create Modal  ⚠️ ASSUMED
  Tool:   generate_screen_from_text
  Prompt: "Task creation modal overlay..."
  Note:   ⚠️ Form fields inferred from API request schema — 
          ไม่มี user story ยืนยันว่า field ไหน required
  Result: ✅ Generated

Screen 5: Notification Center  ⚠️ ASSUMED
  ...
  
(generate ครบ 8 screens + mobile variants สำหรับ 4 key pages)
```

**⏸️ HALT — User review ทุก screens:**

```
Generated: 8 desktop screens + 4 mobile variants
Approved:  8/8 desktop, 4/4 mobile
Time:      ~2 hours (including 3 edit refinements)
```

### Day 1 ช่วงเย็น: Extract UX Deliverables

**Agent ทำ Phase 4 — Extract Specs จาก Stitch screens:**

```
4.1  docs/ux/01-design-tokens.md
     → Extract จาก .stitch/DESIGN.md (colors, typography, spacing)
     → Map กับ TailwindCSS classes (per .claude/rules/web.md)

4.2  docs/ux/02-component-inventory.md
     → Observe จาก generated screens: Button, Card, Modal, KanbanColumn,
       TaskCard, Avatar, Badge, Sidebar, TopNav, SearchBar...
     → 15 components, ระบุ variants + states

4.3  docs/ux/03-page-layouts.md
     → 8 pages, link ไป .stitch/designs/*.html
     → ⚠️ ASSUMED flags on 5 pages (inferred from SD, ไม่มี BA user flow ยืนยัน)

4.4  docs/ux/04-navigation-structure.md
     → Sitemap จาก screen relationships
     → Route table: /login, /projects, /projects/:id, /settings, etc.

4.5  docs/ux/05-interaction-patterns.md
     → Form validation (from API error responses)
     → Loading: skeleton for cards, spinner for actions
     → Empty states: ⚠️ ASSUMED — "No projects yet" / "No tasks yet"

```

### Day 1: Self-Review

```
Phase 5 — Self-Review:
✅ ทุก inferred screen มี layout
✅ Design tokens ใช้ throughout
✅ Components ครบ (observed จาก Stitch screens)
✅ API alignment ตรง (checked api-specs)
⚠️ 5 out of 8 pages flagged as ASSUMED
⚠️ No user flow validation — flows inferred from product breakdown
```

### ⏸️ HALT — User Approve

```
Agent summary:
"สร้าง UX deliverables 5 ไฟล์ จาก Stitch (Path B: SD-only; v1.1: UX-06 dropped)
- 8 screens generated + 4 mobile variants
- 15 components inventoried
- ⚠️ 5 pages เป็น ASSUMED (infer จาก SD ไม่มี BA ยืนยัน)
- แนะนำ: หลังสร้าง BA docs → /amend ux เพื่อ reconcile"

User: approved ✅
```

---

## Day 3 (ภายหลัง): Reconcile หลังมี BA

```
สถานการณ์: Developer สร้าง BA docs เสร็จแล้ว (docs/ba/01-05; v1.2)
Action:    /amend ux "reconcile assumptions กับ BA user flows ที่สร้างใหม่ — 
           ตรวจทุก ⚠️ ASSUMED ใน docs/ux/ ว่ายังตรงกับ user flows หรือไม่"
```

**Agent ทำ reconciliation:**

```
ตรวจ ⚠️ ASSUMED 5 จุด:

1. Kanban columns: To Do / In Progress / Done
   BA: ✅ ตรง — Flow-04 ระบุ 3 statuses เดียวกัน
   → ลบ ⚠️ ASSUMED

2. Task Create form fields
   BA: ⚠️ ต่าง — BA ระบุ "due_date" เป็น optional ไม่ใช่ required
   → แก้ 05-interaction-patterns.md: due_date validation = optional
   → แก้ 03-page-layouts.md: Task Create Modal note

3. Notification Center layout
   BA: ✅ ตรง — Flow-06 ยืนยัน in-app + email notifications
   → ลบ ⚠️ ASSUMED

4. User Settings page
   BA: ⚠️ เพิ่ม — BA มี Flow สำหรับ "Change notification preferences" ที่ไม่มีใน settings
   → แก้ 03-page-layouts.md: เพิ่ม notification preferences section
   → แก้ 04-navigation-structure.md: เพิ่ม /settings/notifications route

5. Project Detail empty state
   BA: ✅ ตรง — Flow-03 มี alternative path "first task"
   → ลบ ⚠️ ASSUMED

Result: 2 จุดต้องแก้, 3 จุดถูกต้อง → ⚠️ ASSUMED ทั้งหมดถูก resolved ✅
```

---

## Workflow Commands Used

| Step | Command | Sessions | Time |
|------|---------|----------|------|
| 1 | Install Stitch skill | 1 | 5 min |
| 2 | `/ux-design stitch` (Path B) | 1 | ~3 hours |
| 3 | User review + approve | — | 30 min |
| 4 | `/amend ux "reconcile..."` (หลังมี BA) | 1 | 30 min |
| **Total** | | **3 sessions** | **~4 hours + 30 min reconcile** |

---

## Methodology Verdict

✅ **PASS** — Stitch + SD-only input ใช้งานได้จริง

**ข้อดี:**
- ได้ UI prototype เร็ว (~3 hours) โดยไม่ต้องรอ BA
- Stakeholder เห็น visual mockups ก่อนลงทุน BA เต็มรูปแบบ
- `⚠️ ASSUMED` flags ป้องกันไม่ให้ assumptions หลุดไปถึง implementation โดยไม่รู้
- Reconcile หลังมี BA ใช้เวลาแค่ ~30 min (แก้ 2 จุดจาก 5)

**ข้อจำกัด:**
- ไม่มี user flow → ไม่รู้ step-by-step journey → navigation อาจไม่ optimal
- Priority ไม่มี → assume ทุก feature เป็น Must Have → อาจ over-design
- Error/edge case flows ไม่ครบ → empty states, error states เป็น assumptions

**แนะนำ:**
- ใช้ Path B เมื่อต้องการ **speed to demo** — ได้ mockups เร็ว ค่อย refine ทีหลัง
- ถ้ามีเวลา → สร้าง BA ก่อน (Path A) จะได้ UX ที่แม่นยำกว่า
- **ห้าม** เริ่ม Implementation จาก Path B UX โดยไม่ reconcile กับ BA ก่อน
