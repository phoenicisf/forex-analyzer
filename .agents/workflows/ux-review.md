---
description: Review UX/UI deliverables against 22 attack vectors and approve or generate claim review
---

# Workflow: Review UX/UI Design Deliverables

Adversarial review of the UX/UI deliverable package in `docs/ux/`. Scans 22 UX attack vector categories and generates a structured claim review.

**Input:** `{{input}}` — `all` (review everything) or specific file path (e.g., `docs/ux/03-page-layouts.md`)

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack
2. `.agents/skills/andm-ux-reviewer/SKILL.md` — **your persona definition** (activate full adversarial review protocol)
3. `.agents/development-guide/ux-design-workflow.md` — UX quality benchmark
4. `docs/state/overview.md` — current module status
5. Previous claim-review files in `docs/ux/claim-review-and-rebuttal/` (if any — to avoid duplicates)

Once read, you are ready to proceed.

---

## Phase 1: Load Context (MANDATORY — All reads in parallel)

### 1.1 Determine Round Number

Count existing `claim-review-*.md` files in `docs/ux/claim-review-and-rebuttal/` → next round = count + 1

### 1.2 Execute reads simultaneously:

1. **UX Deliverables** — Read all files in `docs/ux/` (01 through 06, plus `00-design-vision.md` **if exists** — optional for Modes A/B/C, required for Mode D)
2. **BA User Flows** — Read `docs/ba/05-user-flows.md` (if exists) or `docs/design-docs/08-product-breakdown.md` (Path B fallback)
3. **Functional Requirements** — Read `docs/ba/02-functional-requirements.md` (if exists) or infer from `docs/api-specs/`
4. **API Contracts** — Read all files in `docs/api-specs/` (data alignment check)
5. **Architecture** — Read `docs/design-docs/02-high-level-architecture.md` (component mapping)
6. **Web Rules** — Read `.claude/rules/web.md` (frontend conventions)
7. **Previous Rounds** — Read previous claim-review + rebuttal files (to skip fixed findings)

### 1.3 Engage Persona

Follow the andm-ux-reviewer persona defined in `.agents/skills/andm-ux-reviewer/SKILL.md`. Activate the full 22-category attack vector scan.

---

## Phase 2: Run 22-Category Attack Vector Scan

Scan every `docs/ux/` file against the 22 UX attack vector categories defined in `.agents/skills/andm-ux-reviewer/SKILL.md`:

1. Design Token Completeness (including functional color roles & depth/elevation)
2. Design Token Consistency
3. Component State Coverage
4. Component Variant Completeness
5. Page Layout Coverage
6. Empty State Design
7. Error State Design
8. Loading State Design
9. Responsive Design
10. Navigation Completeness
11. Accessibility (WCAG AA)
12. Form UX Patterns
13. API Data Alignment
14. Component-Page Mapping
15. Interaction Pattern Clarity
16. Design Handoff Quality
17. Cross-Doc Consistency
18. Priority Alignment
19. Assumption Marking
20. Implementation Feasibility
21. **Design Vision Coherence** *(conditional: Mode D required; Modes A/B/C skip if 00 absent)* — UI ตรงกับ visual theme/atmosphere ที่ประกาศใน `00-design-vision.md` หรือไม่
22. **Do's/Don'ts Violations** — deliverables ละเมิด guardrails ที่กำหนดไว้ใน design vision หรือไม่

For each category:
- Check against the specific criteria in SKILL.md
- Record findings using the Claim Format (SKILL.md Phase 3)
- Classify severity: CRITICAL 🔴 / HIGH 🟠 / MEDIUM 🟡 / LOW 🔵

**Anti-duplication:** Skip findings that were fixed in previous rounds (check rebuttal files).

---

## Phase 2B: Extended Review — Design System & Behavioral Audit (Optional)

> ใช้เมื่อมี code อยู่แล้วใน `services/web/` — เสริม review ด้วย skills เพิ่มเติม

### Design System Audit (if `services/web/` has styling code)

Use `.agents/skills/design-system/SKILL.md` in `audit` mode to score visual consistency:

- Run 10-dimension scoring (color consistency, typography, spacing, components, responsive, dark mode, animation, accessibility, density, polish)
- Run AI slop detection — flag generic AI patterns (gratuitous gradients, overused glassmorphism, stock hero layouts)
- Add findings to the claim review under category **21. Design System Consistency** and **22. AI Slop Detection**

### Click-Path Audit (if `services/web/` has interactive components)

Use `.agents/skills/click-path-audit/SKILL.md` to trace button/form handlers:

- Map state stores and their side-effects
- Audit each touchpoint for 6 bug patterns (Sequential Undo, Async Race, Stale Closure, Missing Transition, Dead Path, useEffect Interference)
- Add findings to the claim review under category **23. Click-Path Behavioral Bugs**

> Note: Categories 21-23 are optional extensions. The core 20-category scan remains mandatory.

---

## Phase 3: Quality Gate & Output

### Quality Gate (must pass before output)

- [ ] ≥3 findings (if fewer → review more carefully)
- [ ] Every finding has specific file + section
- [ ] Every finding has actionable fix
- [ ] No duplicates with previous rounds
- [ ] Cross-doc consistency checked

### If no findings (all 22 categories pass):

Present in Thai:

```
## ✅ UX/UI Design Deliverables — Approved

ทุก deliverable ผ่าน review ครบ 22 categories

| Document | Status |
|----------|--------|
| 00-design-vision | ✅ (if exists — Mode D required, A/B/C optional) |
| 01-design-tokens | ✅ |
| 02-component-inventory | ✅ |
| 03-page-layouts | ✅ |
| 04-navigation-structure | ✅ |
| 05-interaction-patterns | ✅ |

**พร้อม handoff ไป Implementation Phase**
ขั้นตอนถัดไป: `/impl-plan 1`
```

### If findings exist:

Write claim review to `docs/ux/claim-review-and-rebuttal/claim-review-XX.md` using the output format in SKILL.md Phase 5.

Present summary in Thai:

```
## ⚠️ UX/UI Design — พบปัญหา [N] items

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | N |
| 🟠 HIGH | N |
| 🟡 MEDIUM | N |
| 🔵 LOW | N |

**แนะนำ:**
- Option A (full): `/ux-rebuttal claim-review-XX.md` — adversarial rebuttal loop (แก้ + โต้)
- Option B (lite): `/ux-fix claim-review-XX.md` — lightweight fix (แก้ตรงๆ ประหยัด token)
```

---

## Phase 4: HALT — Wait for User Decision

⏸️ Present the report and wait for user to:

1. **Approve** (if no findings) → Mark Phase 2C as complete
2. **`/ux-rebuttal`** → Full adversarial rebuttal loop (Option A)
3. **`/ux-fix`** → Lightweight direct fix (Option B — fewer tokens)
4. **Manual fix** → User fixes docs/ux/ directly → re-run `/ux-review`
