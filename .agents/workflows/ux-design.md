---
description: Create UX/UI design deliverables (design tokens, components, layouts) using Stitch, Figma, existing UI audit, reference-driven design (DESIGN.md), direct frontend building, or Claude Design (Anthropic Labs)
---

# Workflow: Create UX/UI Design Deliverables

Analyze BA user flows and system design docs, then produce a complete UX/UI deliverable package for implementation.

**Design Mode:** {{input}}

> Valid modes: `stitch` (AI-generated), `figma` (Figma-first), `existing` (existing UI audit), `reference` (DESIGN.md-driven), `frontend` (direct production UI), `claude-design` (Anthropic Labs Claude Design), or `auto` (auto-detect)

### 00-design-vision.md Requirement per Mode

| Mode | 00-design-vision.md | Reason |
|------|---------------------|--------|
| `reference` | 🔴 **REQUIRED** | Mode D uses DESIGN.md as source of truth — `00-design-vision.md` is the customized project vision + AI-agent prompt guide |
| `stitch` | 🟡 **OPTIONAL** (skip-by-default) | Stitch generates mockups; tokens extract directly. Create only if project explicitly wants visual guardrails for AI coding agents |
| `figma` | 🟡 **OPTIONAL** (skip-by-default) | Figma IS the design system source; re-formatting to 9-section DESIGN.md is redundant unless project wants AI prompt guide |
| `existing` | 🟡 **OPTIONAL** (skip-by-default) | Audit captures tokens; 9-section format adds ceremony unless project wants to standardize |
| `claude-design` | 🟡 **OPTIONAL** (skip-by-default) | Claude Design auto-derives design system; exports capture tokens. Create only if team wants explicit AI-agent visual guardrails |

If Mode A/B/C/F and 00 is skipped → review agent (`/ux-review`) marks vectors 21+22 as `N/A — 00-design-vision.md not present (Mode X skip-by-default)`.

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. **Mode-specific prompt template** (based on `{{input}}`):
   - `stitch` → `.andm/prompt-templates/ux-design-stitch-prompt.md`
   - `figma` → `.andm/prompt-templates/ux-design-figma-prompt.md`
   - `existing` → `.andm/prompt-templates/ux-design-existing-prompt.md`
   - `reference` → `.andm/prompt-templates/ux-design-reference-prompt.md`
   - `claude-design` → `.andm/prompt-templates/ux-design-claude-design-prompt.md`
   - `auto` → read all 5, then decide after Phase 2
3. `docs/state/overview.md` — current module status
4. `.andm/development-guide/ux-design-workflow.md` — detailed UX design workflow guide

Once read, you are ready to proceed.

---

## Phase 1: Load Context (MANDATORY — All reads in parallel)

### 1.0 Detect Input Path

Check which input documents exist:

```
Glob docs/ba/05-user-flows.md
Glob docs/ba/02-functional-requirements.md
```

- **If both exist → Path A** (BA + SD — full context)
- **If either missing → Path B** (SD-only fallback — flag assumptions)

### Path A: BA docs exist (recommended)

Execute these reads simultaneously:

1. **User Flows** — Read `docs/ba/05-user-flows.md` thoroughly. This is your primary input for page/screen identification.
2. **Functional Requirements** — Read `docs/ba/02-functional-requirements.md` for user stories, acceptance criteria, and the business entities the UI must represent.
3. **Non-Functional Requirements** — Read `docs/ba/03-non-functional-requirements.md` for usability and accessibility targets.
4. **Architecture** — Read `docs/design-docs/02-high-level-architecture.md` for service boundaries and component mapping.
5. **API Contracts** — Read all files in `docs/api-specs/` for data structures the UI must display/submit.
6. **Service Rules** — Read `.claude/rules/web.md` for frontend-specific patterns and conventions.
7. **Existing UX** — Check if `docs/ux/` already has files (partial work from a previous session).

### Path B: BA docs missing (SD-only fallback)

Execute these reads simultaneously:

1. **Product Breakdown** — Read `docs/design-docs/08-product-breakdown.md` — features/modules → infer screens needed. **This replaces** `ba/05-user-flows.md`.
2. **Data Flow** — Read `docs/design-docs/04-data-flow.md` — sequence diagrams → infer interaction order and data payloads.
3. **Architecture** — Read `docs/design-docs/02-high-level-architecture.md` for service boundaries and component mapping.
4. **API Contracts** — Read all files in `docs/api-specs/` — endpoints → infer user actions, pages, and data displayed. **This replaces** `ba/02-functional-requirements.md`.
5. **Service Rules** — Read `.claude/rules/web.md` for frontend-specific patterns and conventions.
6. **Existing UX** — Check if `docs/ux/` already has files (partial work from a previous session).

> ⚠️ **Path B: SD-only limitations** — ต้อง flag ใน deliverables:
> - ทุก screen ที่ infer จาก SD docs → mark `⚠️ ASSUMED` (ยังไม่ confirm จาก user flows)
> - ไม่มี step-by-step user journey → flow ระหว่างหน้าเป็น assumption
> - ไม่มี user story priority → assume ทุก feature เป็น Must Have
> - หลังสร้าง BA docs แล้ว → ควร `/amend ux` เพื่อ reconcile assumptions กับ actual user flows

---

## Phase 2: Detect or Confirm Design Mode

### If `{{input}}` is `auto`:

Detect the appropriate mode:

| Condition | Mode |
|-----------|------|
| User has Claude Pro/Max/Team/Enterprise **and** wants interactive visual iteration (comments/sliders) | **claude-design** |
| `services/web/` has existing UI components with pages already built | **existing** |
| User mentions Figma URL or `.figma` references exist in docs | **figma** |
| `design-reference/*-DESIGN.md` already exists, OR user mentions reference site (Vercel, Linear, etc.) and is willing to acquire DESIGN.md per `.andm/development-guide/ux-design-reference-acquisition.md` | **reference** |
| Greenfield project, no existing frontend code | **stitch** |
| User wants to build production UI directly (landing page, dashboard, app shell) | **frontend** |

> **Note on Mode F (`claude-design`)** — auto-detect only suggests; always confirm subscription eligibility with the user before committing. If not eligible, fall back to `stitch` / `figma` / `reference`.

Present the detected mode to the user and wait for confirmation before proceeding.

### If `{{input}}` is `stitch`, `figma`, `existing`, `reference`, `frontend`, or `claude-design`:

Use the specified mode directly.

---

## Phase 3: Generate UX Deliverables (Mode-Specific)

### Mode A: `stitch` (AI-Generated)

> 🔧 **Stitch MCP must be configured first.** If this is the first time using Stitch in this environment OR `mcp__stitch__list_projects` fails, follow [`.andm/development-guide/ux-design-stitch-mcp-setup.md`](../../.andm/development-guide/ux-design-stitch-mcp-setup.md) before proceeding (proxy + API key setup, broken-config recovery, fallback to Mode D when MCP unreachable).

1. **(Optional) Load style reference from `design-reference/`:**
   - Check if `design-reference/` has files matching `*-DESIGN.md` (e.g., `vercel-DESIGN.md`)
   - If yes → copy chosen reference to project root as `DESIGN.md` (Stitch reads root automatically as visual guide); originals stay un-edited in `design-reference/`
   - If no and user wants reference → HALT + point to `.andm/development-guide/ux-design-reference-acquisition.md` for acquisition options
   - If user explicitly skips reference → proceed without one
   - See `.andm/development-guide/ux-design-workflow.md` Mode A step 2 for details
2. **Generate desktop screens (primary)** using Stitch:
   - For each user flow → identify screens/pages needed
   - Generate at desktop resolution first (`deviceType: DESKTOP`) — most ops dashboards / SaaS targets desktop primary
   - For undecided atmosphere/composition → use `generate_variants` to produce 2-3 layout options of ONE pivotal screen, let user pick before batch-generating the rest
   - Present each result to user with `outputComponents.text` + `outputComponents.suggestion` per [text-to-design.md Step 4](../skills/stitch-design/workflows/text-to-design.md#4-present-ai-feedback-outputcomponents)
3. **Generate mobile variants** for **key user-flow screens only** (login, primary task, dashboard home) — NOT every screen:
   - `deviceType: MOBILE` (375px target)
   - Skip mobile entirely if project = single-user desktop ops dashboard (e.g., localhost-only tool)
4. **Refine via `edit_screens`** for targeted polish — track latest screen ID per page slug (each edit returns NEW ID)
5. **Apply design system** consistency check via `apply_design_system` if 5+ screens already generated (re-applies tokens; helpful if early screens drifted before design system was finalized)
6. **Extract design tokens** from generated mockups + `.stitch/DESIGN.md`
7. **List components** needed to build the selected layouts
8. **Proceed to Phase 4**

> 🔁 **Generating ≥10 screens?** Consider [`stitch-loop` skill](../skills/stitch-loop/SKILL.md) — autonomous baton-pattern multi-page builder driven by `.stitch/SITE.md` + `.stitch/next-prompt.md`. Designed for marketing sites / multi-page brochure work; not needed for typical 5-8 page ops dashboards.

### Mode B: `figma` (Figma-First)

1. **Read Figma design system** using Figma MCP:
   - Extract colors, typography, spacing from Figma styles
   - Extract component list from Figma components
   - Extract page layouts from Figma frames
2. **(Optional) Supplement with style reference from `design-reference/`:**
   - Check if `design-reference/` has files matching `*-DESIGN.md`
   - If Figma lacks complete design system (e.g., missing color roles, shadows, responsive) → use the reference as visual language guide
   - Merge Figma rules with DESIGN.md sections that Figma doesn't cover; cite both sources in `00-design-vision.md` Reference Provenance block
   - If reference needed but `design-reference/` ว่าง → point user to `.andm/development-guide/ux-design-reference-acquisition.md`
   - See `.andm/development-guide/ux-design-workflow.md` Mode B step 3 for details
3. **Map Figma frames** to user flows from BA
4. **Identify gaps** — user flows without Figma frames
5. **Proceed to Phase 4**

### Mode C: `existing` (Existing UI Audit)

1. **Audit current UI**:
   - List all existing pages/routes in `services/web/`
   - Identify existing components (check for component library usage)
   - Extract current color/font/spacing patterns
2. **Create audit report** — save to `docs/ux/audit-report.md`:
   - What exists and is consistent
   - What is inconsistent (needs standardization)
   - What is missing (gaps vs BA user flows)
3. **Standardize** — define tokens and components based on existing patterns
4. **(Optional) Run design-system audit** — use `.agents/skills/design-system/SKILL.md` to score visual consistency across 10 dimensions and detect AI slop patterns
5. **Proceed to Phase 4**

### Mode D: `reference` (Reference-Driven Design via DESIGN.md)

> ใช้เมื่อยังไม่มี Stitch/Figma — อ่าน DESIGN.md ที่ user/operator วางมาที่ `design-reference/<name>-DESIGN.md` เป็น source of truth หลัก แล้ว customize เข้ากับโปรเจค
> ถ้าใช้ Stitch หรือ Figma อยู่แล้ว — เพิ่ม DESIGN.md เป็น optional style reference ได้ใน Mode A (step 1) หรือ Mode B (step 2)

> **Methodology contract:** workflow นี้ **ไม่ fetch/download/install** อะไรทั้งสิ้น — อ่านจาก `design-reference/<name>-DESIGN.md` เท่านั้น วิธีได้ไฟล์มาเป็น operator-side action ตาม `.andm/development-guide/ux-design-reference-acquisition.md` (4 options: npx getdesign / browser save / copy from another project / hand-author)

1. **Verify input** — list `design-reference/*.md`:
   - ถ้าโฟลเดอร์ว่าง / ไม่มีไฟล์ที่ลงท้ายด้วย `-DESIGN.md` → **HALT** + แจ้ง user ให้ทำตาม `.andm/development-guide/ux-design-reference-acquisition.md` ก่อนรันใหม่
   - ถ้ามีหลายไฟล์ — list ให้ user เลือกว่าใช้ตัวไหนเป็น primary reference (อันอื่นเป็น secondary mix-and-match)
2. **Validate schema** — เปิดไฟล์ที่เลือก ตรวจ:
   - 9 sections ครบ (Visual Theme / Colors / Typography / Components / Layout / Depth / Do's-Don'ts / Responsive / Agent Prompt Guide)
   - Provenance comment block อยู่ที่หัวไฟล์ (`source: ...`, `fetched: ...`, `acquired_via: ...`)
   - ถ้าไม่ครบ → HALT + cite acquisition guide §5 Validation Checklist
3. **Create `docs/ux/00-design-vision.md`** by customizing the validated DESIGN.md:
   - Adapt 9 sections to project brand (Visual Theme, Colors, Typography, Components, Layout, Depth, Do's/Don'ts, Responsive, Agent Prompt Guide)
   - เปลี่ยนสี/font/accent ให้เหมาะกับ product
   - เขียน Do's/Don'ts เฉพาะโปรเจค (อย่างน้อย 5 Do + 5 Don't)
   - เขียน Agent Prompt Guide อย่างน้อย 3 ตัวอย่าง
   - เพิ่ม Reference Provenance block ที่อ้างกลับไปยัง provenance ของไฟล์ใน `design-reference/`
4. **ห้าม edit ต้นฉบับ** ใน `design-reference/` — customization ทุกอย่างไปที่ `docs/ux/00-design-vision.md` เท่านั้น (ตาม acquisition guide §3)
5. **Generate UX deliverables** from design vision → Proceed to Phase 4

### Mode E: `frontend` (Production-Grade UI Building)

> ใช้เมื่อต้องการสร้าง UI ตรงเลย — landing page, dashboard, app shell — โดยไม่ผ่าน mockup tool
> อ่าน `.agents/skills/frontend-design/SKILL.md` สำหรับ visual direction และ composition guidelines

1. **Frame the interface** — determine purpose, audience, emotional tone
2. **Choose visual direction** (ask user):
   - Brutally minimal / Editorial / Industrial / Luxury / Playful
   - Geometric / Retro-futurist / Soft organic / Maximalist
3. **Build visual system** — type hierarchy, color palette, spacing rhythm, motion rules
4. **Compose with intention** — asymmetry, overlap, whitespace as design element
5. **For dashboard-heavy projects** — use `.agents/skills/dashboard-builder/SKILL.md` for data panel layout strategy
6. **For iOS-style glass effects** — reference `.agents/skills/liquid-glass-design/SKILL.md` for Liquid Glass patterns
7. **Proceed to Phase 4** — extract specs into standard deliverable format

### Mode F: `claude-design` (Anthropic Labs Claude Design)

> ใช้เมื่อต้องการ **interactive visual iteration** กับ Claude ผ่าน Claude Design web app (claude.ai)
> ขับเคลื่อนด้วย **Claude Opus 4.7** vision (research preview, released 2026-04-17)
> อ่าน `.andm/prompt-templates/ux-design-claude-design-prompt.md` สำหรับรายละเอียดเต็ม

1. **Prerequisites check (CRITICAL — HALT if missing):**
   - ✅ Claude **Pro / Max / Team / Enterprise** subscription
   - ✅ Enterprise: org admin เปิด Claude Design ใน org settings แล้ว
   - ✅ Browser access to **claude.ai**
   - ถ้าไม่ผ่าน → HALT + แนะนำ Mode A (`stitch`) / Mode B (`figma`) / Mode D (`reference`)
2. **Seed Claude Design project** ด้วย brand context ที่เหมาะกับโปรเจค:
   - Existing codebase (brownfield) → codebase upload → auto-derive design system
   - Marketing site → website capture URL
   - Brand guideline → import PPTX/DOCX/XLSX
   - Logo/images → image import
   - รวม multi-source ได้ใน project เดียว
3. **Verify derived design system** — Claude Design auto-derive colors/typography/spacing; ต้อง review ว่าตรง brand ก่อน approve
4. **Generate & iterate screens** per user flow:
   - Describe → Claude Design builds → refine (inline comment / slider / direct edit)
   - Compare 2-3 variants เมื่อไม่แน่ใจ direction
   - Lock in approved version, generate mobile/tablet responsive variants
5. **Export everything** to `docs/ux/claude-design/`:
   - HTML per screen (preserves interactivity)
   - PNG screenshots
   - `export-manifest.json` (screen → internal URL → timestamp)
   - `README.md` (access instructions + changelog) — **internal URLs เป็น auth-gated; อย่า link ใน public docs**
6. **Extract deliverables** from exports → Phase 4 (standard `docs/ux/01-05` + optional 00)
7. **Handoff choices:**
   - **Path A (standard):** Impl Engineer อ่าน `docs/ux/01-05` + `docs/ux/claude-design/` เป็น visual reference
   - **Path B (native):** ใช้ Claude Design "Handoff to Claude Code" feature seed impl plan อัตโนมัติ (ยังต้องสร้าง `docs/ux/01-05` เพื่อ auditability)
8. **Proceed to Phase 4**

> ⚠️ **Research preview stability risk** — ถ้า Claude Design breaks ระหว่างทำงาน ให้ fallback เป็น Mode A (stitch) สำหรับ screen ที่เหลือ และ document fallback ใน `docs/ux/claude-design/README.md`

---

## Phase 4: Write Deliverables

Create all 7 files in `docs/ux/`. Follow the format defined in `.andm/development-guide/ux-design-workflow.md`.

> **Design System Enhancement (Optional):** After writing `01-design-tokens.md`, consider running the design-system skill in `generate` mode (`.agents/skills/design-system/SKILL.md`) to produce a `DESIGN.md` + `design-tokens.json` + `design-preview.html` preview page. This gives engineers a live-preview reference alongside the markdown specs.

### 4.0 Write `docs/ux/00-design-vision.md`

Contents (9 sections per DESIGN.md format):
- Visual Theme & Atmosphere — narrative of visual identity
- Color Palette & Roles — colors by role: Primary/Accent, Semantic, Neutral, Surface, Interactive
- Typography Rules — font family, size hierarchy, weight system
- Component Stylings — key component specs with exact values
- Layout Principles — spacing system, grid, whitespace philosophy
- Depth & Elevation — shadow levels (≥3) with exact CSS values
- Do's and Don'ts — guardrails for AI agents (≥5 Do + 5 Don't)
- Responsive Behavior — breakpoints, touch targets, collapsing strategy
- Agent Prompt Guide — example prompts for AI coding agents (≥3 examples)

> **If Mode D (reference):** customize from `design-reference/*.md`
> **If Mode A/B/C/E/F:** derive from generated/extracted design decisions; Agent Prompt Guide still recommended

### 4.1 Write `docs/ux/01-design-tokens.md`

Contents:
- Color palette with **functional roles** (Primary/Accent, Semantic, Neutral Scale, Surface/Overlay, Interactive) and CSS variable names
- Typography scale (font families, sizes, weights, line-heights)
- Spacing system (consistent scale, e.g., 4px base)
- Border radius, shadows (**depth & elevation table ≥ 3 levels** with exact CSS), z-index layers
- Breakpoints (mobile, tablet, desktop)
- If using TailwindCSS → map tokens to Tailwind config

### 4.2 Write `docs/ux/02-component-inventory.md`

Contents:
- Component list with: name, variants, props, states (default/hover/active/disabled/loading/error)
- Priority: Must Have / Should Have / Could Have
- Library source: shadcn/ui, Radix, custom, etc.
- Group by category: Navigation, Forms, Data Display, Feedback, Layout

### 4.3 Write `docs/ux/03-page-layouts.md`

Contents:
- One section per page/screen identified from user flows
- Layout structure (header, sidebar, main, footer placement)
- Components used on each page
- Data requirements (which API endpoint feeds this page)
- Responsive behavior notes
- Wireframe: ASCII art, Mermaid diagram, or link to Stitch/Figma

### 4.4 Write `docs/ux/04-navigation-structure.md`

Contents:
- Sitemap as Mermaid `graph TD`
- Route table: path, page component, auth required, dynamic segments
- Navigation hierarchy: primary nav, secondary nav, breadcrumbs
- Deep link support

### 4.5 Write `docs/ux/05-interaction-patterns.md`

Contents:
- Form patterns: validation display, inline errors, submit behavior
- Loading states: skeleton, spinner, progressive loading
- Empty states: illustration + CTA
- Error states: inline, toast, full-page
- Responsive breakpoint behavior per key page
- Transitions and animations (if applicable)

### 4.6 ~~Write `docs/ux/06-handoff-to-implementation.md`~~ — **REMOVED (SD-as-Master consolidation)**

UX-06 was dropped because it restated 01-05 content. Impl Engineer now reads `docs/ux/01-05` (+ `00-design-vision.md` if exists) directly. Setup notes, package lists, and impl-plan task recommendations move to:
- **Package lists / setup** → `docs/technical-design/03-frontend-design.md` (lives with component tree)
- **Open questions** → `docs/state/overview.md` or per-module handoff
- **Impl-plan task recommendations** → consumed by Impl Planner from SD `08-product-breakdown.md` directly

---

## Phase 5: Self-Review

Before presenting to user, verify:

- [ ] **Design Vision** — `00-design-vision.md` has all 9 sections (especially Do's/Don'ts and Agent Prompt Guide)
- [ ] **Completeness** — every user flow from `05-user-flows.md` has a page layout in `03-page-layouts.md`
- [ ] **Token Roles** — design tokens in `01` include functional color roles and depth/elevation table
- [ ] **Consistency** — design tokens in `01` are actually used in component specs in `02`
- [ ] **Vision Alignment** — components and layouts align with Do's/Don'ts from `00-design-vision.md`
- [ ] **API Alignment** — data shown on pages matches `docs/api-specs/` response schemas
- [ ] **Navigation** — every page in `03` has a route in `04`
- [ ] **Interaction** — every form in page layouts has patterns defined in `05`
- [ ] **No placeholders** — no TBD, TODO, or incomplete sections

Fix any issues inline before proceeding.

---

## Phase 6: HALT — Present to User

Present a summary in Thai:

- Design mode used
- Number of pages/screens defined
- Number of components in inventory
- Key design decisions made
- Open questions or assumptions (marked with ⚠️)
- Link to all 7 deliverable files (00-06)

**⏸️ Wait for user to review and approve before marking Phase 1C as complete.**

If user requests changes → update deliverables → re-run self-review → present again.
