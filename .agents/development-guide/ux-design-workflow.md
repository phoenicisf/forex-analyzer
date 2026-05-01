# UX/UI Design Phase — Development Guide

คู่มือการใช้งาน workflow สำหรับ UX/UI Visual Design: จาก BA user flows สู่ approved UI spec ที่พร้อมส่งต่อให้ Implementation

> ⚠️ **Scope change: UX reduced from 6 → 5 docs (SD-as-Master consolidation)**
>
> UX ผลิตเฉพาะ `00-design-vision.md` + `01-design-tokens.md` + `02-component-inventory.md` + `03-page-layouts.md` + `04-navigation-structure.md` + `05-interaction-patterns.md`
> เอกสาร **UX-06 (handoff-to-implementation)** ถูก drop — TD (02/03) และ Impl Planner อ่าน UX-01..05 โดยตรงเป็น input ไม่ต้องมี intermediate handoff doc

---

## ภาพรวม Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│  ผ่าน Phase 1A (BA) + Phase 1B (System Design) แล้ว                  │
│  มี docs/ba/05-user-flows.md (user journeys)                        │
│  มี docs/design-docs/02-08 (v1.2: gaps 01/06) + docs/api-specs/         │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Step 1: เลือก Design Mode (6 modes)                                 │
│  ┌────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐                     │
│  │ Mode A │ │ Mode B │ │ Mode C   │ │ Mode D   │                     │
│  │ Stitch │ │ Figma  │ │ Existing │ │Reference │                     │
│  │ AI Gen │ │ First  │ │ UI Audit │ │ Driven   │                     │
│  └───┬────┘ └───┬────┘ └────┬─────┘ └────┬─────┘                     │
│      │          │           │            │                           │
│  ┌───┴────┐ ┌───┴────────────────────────┴───┐                       │
│  │ Mode E │ │ Mode F                          │                      │
│  │Frontend│ │ Claude Design (Anthropic Labs) │                       │
│  │Direct  │ │ Interactive — Opus 4.7 vision  │                       │
│  └───┬────┘ └────────────────┬───────────────┘                       │
│      ▼                       ▼                                       │
│  ┌─────────────────────────────────────────────┐                     │
│  │ Step 2: สร้าง/รวบรวม UX Deliverables         │                     │
│  │ Output: docs/ux/00-05                        │                     │
│  └──────────────────────┬──────────────────────┘                     │
└──────────────────────────┬───────────────────────────────────────────┘
                       ▼
              ⏸️ HALT — User/Stakeholder approve UX deliverables
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  Step 3: Handoff to Implementation                                    │
│  andm-impl-engineer อ่าน docs/ux/ เป็น input                               │
│  → สร้าง components, pages, layouts ตาม spec ที่ approved แล้ว          │
│  (Mode F: optional native "Handoff to Claude Code" path ด้วย)          │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 6 Design Modes

โปรเจคแต่ละแบบมี context ต่างกัน — เลือก mode ที่เหมาะสม:

| Mode | เมื่อไหร่ใช้ | เครื่องมือ | Output |
|------|-------------|-----------|--------|
| **A: AI-Generated** | Greenfield, ยังไม่มี design, prototype เร็ว | Stitch + *(optional)* DESIGN.md ref | Wireframes + spec |
| **B: Figma-First** | มี designer / มี Figma file อยู่แล้ว | Figma MCP + *(optional)* DESIGN.md ref | Design system rules + spec |
| **C: Existing UI Audit** | Brownfield, มี UI อยู่แล้ว ต้องจัดระเบียบ | Manual audit + screenshot analysis | Audit report + gap analysis + spec |
| **D: Reference-Driven** | ยังไม่มี Stitch/Figma, ใช้ DESIGN.md เป็นหลัก | User-supplied `design-reference/<name>-DESIGN.md` (acquired per [acquisition guide](./ux-design-reference-acquisition.md)) + customization | Design vision + spec ที่ based on reference |
| **E: Frontend Direct** | สร้าง production UI ตรง (landing, dashboard, app shell) | `frontend-design` + `dashboard-builder` + `liquid-glass-design` | Production UI code + extracted spec |
| **F: Claude Design** | ต้องการ interactive iteration (comments/sliders), มี subscription | Claude Design (Anthropic Labs) — Opus 4.7 vision | Exported HTML/PNG + spec + optional native handoff |

> **DESIGN.md คืออะไร?** — plain-text design system file (9 sections) ที่ extract visual identity จากเว็บจริง (Vercel, Linear, Supabase ฯลฯ) ให้ AI agents อ่านแล้วสร้าง UI ตาม style นั้นได้เลย
> ใช้เป็น **optional style reference** กับ Mode A/B ได้ หรือใช้เป็น **source of truth หลัก** ใน Mode D
> วิธีได้ DESIGN.md มา (acquisition) → ดู [`./ux-design-reference-acquisition.md`](./ux-design-reference-acquisition.md) — ANDM ไม่ผูกกับ acquisition method ใดๆ; เลือกจาก 4 options (npx getdesign / browser save / copy from another project / hand-author)

> **Claude Design คืออะไร?** — Anthropic Labs product เปิดตัว 2026-04-17 (research preview). ขับเคลื่อนด้วย Claude Opus 4.7 + vision. Collaborative visual creation: describe → Claude builds → refine ด้วย inline comment / live sliders / direct edits. อ่าน codebase + design files + website capture ได้, export เป็น Canva/PDF/PPTX/HTML, มี native handoff-to-Claude-Code
> **ต้องมี subscription:** Claude Pro / Max / Team / Enterprise (Enterprise ต้อง enable ใน org settings)

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 0: Prerequisites — ต้องมีอะไรก่อน

ก่อนเริ่ม UX/UI Design ต้องมี **อย่างน้อย** Path A หรือ Path B:

#### Path A: มี BA docs (แนะนำ — ข้อมูลครบที่สุด)

- ✅ `docs/ba/05-user-flows.md` — user journeys (happy path + alternatives)
- ✅ `docs/ba/02-functional-requirements.md` — user stories ที่ prioritize แล้ว (entities + actors live here)
- ✅ `docs/design-docs/02-high-level-architecture.md` — service/component mapping
- ✅ `docs/api-specs/` — API contracts (ถ้า frontend ต้อง consume)

#### Path B: มีเฉพาะ SD docs (fallback — ใช้ได้แต่จะมี assumptions)

เมื่อยังไม่มี BA docs สามารถเริ่มจาก SD docs ได้ โดยใช้ docs เหล่านี้แทน:

| แทนที่ | ใช้ SD doc นี้ | ได้อะไร | ข้อจำกัด |
|--------|--------------|---------|----------|
| `ba/05-user-flows.md` | `design-docs/08-product-breakdown.md` | features → infer screens/pages | ไม่มี step-by-step user journey, ต้อง assume flow |
| `ba/05-user-flows.md` | `design-docs/04-data-flow.md` | sequence diagrams → infer interaction order | เป็น system perspective ไม่ใช่ user perspective |
| `ba/02-functional-requirements.md` | `api-specs/*.yaml` | endpoints → infer user actions + data displayed | ไม่มี user story context, ไม่รู้ priority |

**ต้องมีเสมอ (ทั้ง Path A และ B):**
- ✅ `docs/design-docs/02-high-level-architecture.md` — service/component mapping
- ✅ `docs/api-specs/` — API contracts

> ⚠️ **Path B จะสร้าง assumptions** — ทุก screen ที่ infer จาก SD docs จะถูก flag ด้วย `⚠️ ASSUMED` ใน deliverables
> หลังสร้าง BA docs แล้ว ควร `/amend ux` เพื่อ reconcile assumptions กับ actual user flows

ถ้าไม่มีทั้ง BA และ SD → กลับไปทำ Phase 1A/1B ก่อน

---

### Step 1: เลือก Design Mode และเริ่มทำ

#### Mode A: AI-Generated (Stitch / Brainstorming)

**เหมาะกับ:** Greenfield project, ยังไม่มี design, ต้องการ prototype เร็วเพื่อ validate กับ stakeholder

**ขั้นตอน:**

1. **Install Stitch skill** (ถ้ายังไม่มี):
   ```bash
   npx skills add google-labs-code/stitch-skills@stitch-design -y
   ```

2. **(Optional) เลือก Style Reference (user-supplied DESIGN.md):**

   ถ้าอยากให้ Stitch สร้าง UI ที่มี look & feel คล้ายเว็บดังๆ (เช่น Vercel, Linear, Supabase):
   ```bash
   # 1. Acquire DESIGN.md ตาม ux-design-reference-acquisition.md
   #    (เลือก option 1-4 จาก guide; ANDM ไม่ fetch ให้)
   # 2. ผลลัพธ์ต้องอยู่ที่ design-reference/<name>-DESIGN.md เช่น
   #    design-reference/vercel-DESIGN.md

   # 3. Copy ไปที่ project root เพื่อให้ Stitch อ่านอัตโนมัติ
   cp design-reference/vercel-DESIGN.md DESIGN.md
   ```
   - ต้นฉบับใน `design-reference/` ห้ามแก้ — customization ทำใน `docs/ux/00-design-vision.md`
   - ดู [acquisition guide](./ux-design-reference-acquisition.md) §2 สำหรับ 4 acquisition options + §6 สำหรับ Reference Site Selection table

3. **Generate UI mockups** ด้วย Stitch:
   - Input: user flows + functional requirements (+ DESIGN.md ถ้ามี)
   - Stitch จะ generate UI ที่สอดคล้องกับ visual style ของ reference site
   - ใช้ Brainstorming visual companion เพื่อ review/เลือก layout options

4. **สร้าง UX deliverables** จาก mockups ที่ approved — ดู Step 2

**Workflow:**
```
# แบบไม่มี reference:
BA user flows → Stitch generate mockups → User review/select → Extract spec → docs/ux/

# แบบมี reference (DESIGN.md):
BA user flows + DESIGN.md → Stitch generate “Vercel-style” mockups → User review → docs/ux/
```

#### Mode B: Figma-First

**เหมาะกับ:** มี designer ทำ Figma แล้ว, หรือใช้ Figma เป็น source of truth

**ขั้นตอน:**

1. **Install Figma skills** (ถ้ายังไม่มี):
   ```bash
   npx skills add figma/mcp-server-guide@implement-design -y
   npx skills add figma/mcp-server-guide@create-design-system-rules -y
   ```

2. **Setup Figma MCP Server** ตาม Figma skill instructions

3. **(Optional) เพิ่ม Style Reference (user-supplied DESIGN.md):**

   ถ้า Figma file ยังไม่มี design system ชัดเจน หรืออยากได้ visual language จากเว็บดังๆ มาเป็น style guide เสริม:
   ```bash
   # 1. Acquire DESIGN.md ตาม ux-design-reference-acquisition.md
   #    (เลือก option 1-4 จาก guide; ANDM ไม่ fetch ให้)
   # 2. ผลลัพธ์อยู่ที่ design-reference/<name>-DESIGN.md เช่น
   #    design-reference/linear-DESIGN.md
   ```
   - ใช้ `design-reference/linear-DESIGN.md` เป็น **visual language guide** ควบคู่กับ Figma layout/structure
   - ดู [acquisition guide](./ux-design-reference-acquisition.md) §2 สำหรับ 4 acquisition options
   - เช่น Figma มี layout แต่ยังไม่มี color system → เอา color palette & depth system จาก DESIGN.md
   - ช่วยเติมเต็ม section ที่ Figma ไม่ครอบ: shadow system, responsive behavior, do's/don'ts
   - ดูตาราง reference sites ใน Mode D ด้านล่าง

4. **ดึง Design System Rules** จาก Figma:
   - ใช้ `create-design-system-rules` skill สร้าง rules จาก Figma file
   - Output: design tokens, component specs
   - ถ้ามี DESIGN.md ใน `design-reference/` → merge design system rules กับ DESIGN.md sections ที่ยังขาด

5. **สร้าง UX deliverables** จาก Figma data — ดู Step 2

**Workflow:**
```
# แบบไม่มี reference:
Figma file → Figma MCP extract → Design system rules → docs/ux/

# แบบมี reference (DESIGN.md):
Figma layout + DESIGN.md visual language → Merge rules → Complete design system → docs/ux/
```

#### Mode C: Existing UI Audit

**เหมาะกับ:** Brownfield project, มี UI อยู่แล้วแต่ไม่มี spec, ต้องจัดระเบียบก่อน implement ต่อ

**ขั้นตอน:**

1. **Audit existing UI**:
   - Screenshot ทุกหน้าหลัก
   - จด patterns ที่ใช้อยู่: สี, font, spacing, components
   - หา inconsistencies

2. **สร้าง gap analysis**:
   - อะไรที่มีอยู่แล้วและ consistent → document ไว้
   - อะไรที่ inconsistent → ต้อง standardize
   - อะไรที่ขาด → ต้องเพิ่ม

3. **สร้าง UX deliverables** จาก audit — ดู Step 2

**Workflow:**
```
Existing UI → Audit + screenshots → Gap analysis → Standardize → docs/ux/
```

#### Mode D: Reference-Driven Design (DESIGN.md เป็นหลัก)

**เหมาะกับ:** ยังไม่มี Figma และยังไม่ใช้ Stitch — ใช้ DESIGN.md เป็น **source of truth หลัก** แล้ว customize ให้เข้ากับโปรเจค

> 💡 ถ้าใช้ Stitch (Mode A) หรือ Figma (Mode B) อยู่แล้ว — เพิ่ม DESIGN.md เป็น **optional style reference** ได้เลยในแต่ละ Mode (ดู step 2 ของ Mode A หรือ step 3 ของ Mode B)

**แนวคิด:** ใช้ DESIGN.md files (plain-text design system 9 sections) ที่ extract จากเว็บจริง — workflow อ่านจาก `design-reference/<name>-DESIGN.md` ที่ user/operator วางไว้แล้ว Acquisition method แยกออกจาก workflow ดู [`./ux-design-reference-acquisition.md`](./ux-design-reference-acquisition.md)

**ขั้นตอน:**

1. **เลือก reference site** ที่เหมาะกับ vibe ของโปรเจค (Reference Site Selection table อยู่ที่ acquisition guide §6):

   | ถ้าโปรเจคเป็นแบบนี้ | ลองดู reference เหล่านี้ |
   |---------------------|------------------------|
   | Developer tool / SaaS dashboard | Vercel, Linear, Supabase, Sentry |
   | AI / ML product | Claude, Mistral AI, Cohere |
   | Productivity app | Superhuman, Raycast, Notion |
   | Creative / media tool | RunwayML, ElevenLabs |
   | Clean docs / marketing | Mintlify, Resend, Expo |
   | ผสม reference หลายแบบ | เลือก 2-3 sites แล้ว mix & match (each as separate file in `design-reference/`) |

2. **Acquire DESIGN.md** สำหรับ reference ที่เลือก ตาม [acquisition guide](./ux-design-reference-acquisition.md) §2 — เลือก option:
   - **Option 1**: `npx getdesign@latest add <site>` แล้ว `mv DESIGN.md design-reference/<site>-DESIGN.md` (สะดวก แต่ supply-chain risk)
   - **Option 2**: Browser save จาก `https://getdesign.md/<site>/design-md` แล้วเอา markdown ไป paste ที่ `design-reference/<site>-DESIGN.md` (manual แต่ปลอดภัย)
   - **Option 3**: Copy จาก project อื่นที่มี DESIGN.md ที่ vet แล้ว
   - **Option 4**: Author เอง ตาม template ใน acquisition guide §2 Option 4

   ทุก option จบลงที่: `design-reference/<name>-DESIGN.md` พร้อม Provenance comment block (acquisition guide §4)

3. **Validate** — ตรวจ 9 sections ครบ + Provenance block ครบ ก่อนรัน workflow (acquisition guide §5 Validation Checklist)

4. **สร้าง `docs/ux/00-design-vision.md`** โดย customize จาก reference:
   - เอา structure ของ DESIGN.md (9 sections) มาปรับให้เข้ากับ brand ของโปรเจค
   - เปลี่ยนสี, font, และ accent colors ให้เหมาะกับ product
   - เขียน Do's / Don'ts เฉพาะโปรเจค
   - เขียน Agent Prompt Guide สำหรับ AI coding agents
   - Reference Provenance block ใน 00-design-vision.md ต้อง cite metadata ของไฟล์ใน `design-reference/`

5. **ห้าม edit** ต้นฉบับใน `design-reference/` หลัง acquired — customization ทุกอย่างไปที่ `docs/ux/00-design-vision.md` เท่านั้น

6. **สร้าง UX deliverables** จาก design vision — ดู Step 2

**Workflow:**
```
Choose reference site(s) → Acquire DESIGN.md (per acquisition guide; 4 options) → Validate schema → Customize vision → docs/ux/00-design-vision.md → docs/ux/01-05
```

> 💡 **สรุปการใช้ DESIGN.md กับแต่ละ Mode:**
>
> | กรณี | วิธีใช้ |
> |------|--------|
> | **Mode A + ref** | `design-reference/` → copy ไป root เป็น `DESIGN.md` → Stitch อ่านแล้ว gen UI ตาม style |
> | **Mode B + ref** | อ้างจาก `design-reference/` เป็น visual language guide เสริม Figma layout |
> | **Mode D (เดี่ยว)** | `design-reference/` เป็น source of truth หลัก ไม่ต้องมี Stitch/Figma |

#### Mode E: Frontend Direct (Production-Grade UI Building)

**เหมาะกับ:** ต้องสร้าง production UI ตรงเลย — landing page, dashboard, app shell — โดยไม่ผ่าน mockup tool

อ่านรายละเอียดใน `.agents/workflows/ux-design.md` § Mode E และ skills ที่เกี่ยวข้อง:
- `.agents/skills/frontend-design/SKILL.md` — visual direction + composition
- `.agents/skills/dashboard-builder/SKILL.md` — data panel layout (dashboard-heavy)
- `.agents/skills/liquid-glass-design/SKILL.md` — iOS-style glass effects (optional)

**Workflow:**
```
Frame interface → Choose visual direction → Build visual system → Compose with intention → Extract to docs/ux/
```

#### Mode F: Claude Design (Anthropic Labs)

**เหมาะกับ:** ต้องการ **interactive visual iteration** — describe → Claude builds → refine ผ่าน inline comments / sliders / direct edits. เหมาะกับทีมที่ต้อง iterate กับ stakeholder หลายรอบ และมี Pro/Max/Team/Enterprise subscription

> ⚠️ **Research preview** (released 2026-04-17). Feature set อาจเปลี่ยน; เตรียม fallback plan (Mode A/D) ไว้

**ขั้นตอน:**

1. **Prerequisites check (CRITICAL — HALT if missing):**
   - ✅ Claude **Pro / Max / Team / Enterprise** subscription
   - ✅ Enterprise: org admin เปิด Claude Design ใน org settings
   - ✅ Browser access to **claude.ai**
   - ถ้าไม่ผ่าน → แนะนำ Mode A (`stitch`) / Mode B (`figma`) / Mode D (`reference`)

2. **Seed Claude Design project** ด้วย brand context:

   | โปรเจคมี... | Seed ด้วย... |
   |------------|-------------|
   | Existing codebase (brownfield) | Codebase upload → auto-derive design system จาก `tailwind.config.ts`, `globals.css` |
   | Marketing website | Website capture URL |
   | Brand guideline (PPTX/DOCX) | Document import |
   | Logo/brand images | Image import |
   | Multi-source | รวมได้ใน project เดียว |

3. **Verify derived design system** — review auto-derived tokens ว่าตรง brand; flag drift + แก้ manually ผ่าน chat

4. **Generate & iterate screens** per user flow:
   - Describe page purpose + key components
   - Claude Design generates initial design
   - Refine: inline comments, sliders (spacing/color/layout), direct text edits
   - Compare 2-3 variants ถ้าไม่แน่ใจ direction
   - Generate responsive variants (mobile/tablet) สำหรับ key pages

5. **Export everything** to `docs/ux/claude-design/`:
   ```
   docs/ux/claude-design/
     README.md                     ← Internal URL + access instructions + changelog
     export-manifest.json          ← screen → URL → timestamp map
     <screen>.html                 ← HTML snapshot (desktop)
     <screen>.png                  ← Screenshot
     <screen>-mobile.html          ← Responsive variant
   ```
   ⚠️ **Internal URLs = auth-gated** — อย่า link ใน public docs; ใช้ HTML snapshots แทน

6. **Extract deliverables** จาก exports → docs/ux/01-05 (+ optional 00) — ดู Step 2

7. **Handoff choices:**
   - **Path A (standard)** — Impl Engineer อ่าน `docs/ux/01-05` + `docs/ux/claude-design/` เป็น visual reference
   - **Path B (native)** — ใช้ Claude Design **"Handoff to Claude Code"** feature seed impl plan อัตโนมัติ (ยังต้องสร้าง docs/ux/01-05 เพื่อ auditability + reviewer agents)

**Workflow:**
```
Verify subscription → Seed Claude Design project → Verify derived system
    → Generate & iterate (comments/sliders/edits) → Export to docs/ux/claude-design/
    → Extract docs/ux/01-05 → Handoff (Path A standard OR Path B native)
```

> 💡 **เมื่อไหร่เลือก Mode F แทน Mode A:**
> - Mode A (Stitch) — one-shot generation, เหมาะกับ rapid prototyping
> - Mode F (Claude Design) — iterative collaboration, เหมาะกับทีมที่ต้อง review/refine หลายรอบกับ stakeholder

---

### Step 2: สร้าง UX Deliverables

ทุก Mode ต้อง produce deliverables เหล่านี้ลงใน `docs/ux/`:

```
docs/ux/
  00-design-vision.md          ← NEW: Visual identity & AI agent guide (inspired by DESIGN.md format)
  01-design-tokens.md
  02-component-inventory.md
  03-page-layouts.md
  04-navigation-structure.md
  05-interaction-patterns.md

  (06-handoff-to-implementation.md — DROPPED in SD-as-Master consolidation;
   TD-02/03 และ Impl Planner อ่าน UX-01..05 โดยตรง)
```

#### File Specifications

| # | File | Content | Key Artifacts |
|---|------|---------|---------------|
| 00 | `00-design-vision.md` | Visual theme & atmosphere, design philosophy, color palette with roles, depth & elevation system, do's & don'ts, agent prompt guide | DESIGN.md-format vision doc |
| 01 | `01-design-tokens.md` | Colors (primary, secondary, semantic), typography scale, spacing system, border-radius, shadows, breakpoints | Token table with CSS variable names |
| 02 | `02-component-inventory.md` | Component list with variants, props, states (default/hover/active/disabled/loading/error) | Component table, priority (Must/Should/Could) |
| 03 | `03-page-layouts.md` | Wireframe/layout ของแต่ละ page — structure level ไม่ใช่ pixel-perfect | Mermaid diagram หรือ ASCII layout หรือ link ไป Figma/Stitch |
| 04 | `04-navigation-structure.md` | Sitemap, nav hierarchy, breadcrumb UX rules, nav labels, auth guards. **Routing implementation authority: `docs/technical-design/03-frontend-design.md`** (thin reference here — UX owns navigation UX, TD owns route config) | Mermaid `graph TD` sitemap, route table |
| 05 | `05-interaction-patterns.md` | Form patterns, validation display, loading/empty/error states, responsive behavior, transitions | Pattern table per component type |

#### Quality Criteria สำหรับแต่ละ deliverable

**00 - Design Vision** (ใช้ [DESIGN.md format](https://stitch.withgoogle.com/docs/design-md/format/) เป็น template):
- ต้องมี **9 sections** ตาม DESIGN.md standard:

| Section | คำอธิบาย | ตัวอย่าง |
|---------|----------|----------|
| 1. Visual Theme & Atmosphere | narrative บรรยาย visual identity ของโปรเจค | "เว็บนี้ใช้ minimalism แบบ Vercel — พื้นขาวสะอาด, type ตัวใหญ่ tight tracking" |
| 2. Color Palette & Roles | สีแยกตามบทบาท: Primary, Accent, Semantic, Neutral, Surface | `--color-accent: #0a72ef` ใช้สำหรับ CTA เท่านั้น |
| 3. Typography Rules | font family, size hierarchy, weight system, letter-spacing rules | Inter 400/500/600, -0.02em ที่ display size |
| 4. Component Stylings | spec ของ key components พร้อม exact values | Button: bg `#171717`, radius 6px, padding 8px 16px |
| 5. Layout Principles | spacing system, grid, whitespace philosophy, border-radius scale | 4px grid, `--radius-sm: 4px` … `--radius-xl: 16px` |
| 6. Depth & Elevation | shadow/elevation levels แต่ละระดับ | Level 0 (flat) → Level 3 (full card shadow stack) |
| 7. Do's and Don'ts | guardrails เพื่อป้องกัน AI agent สร้าง UI ผิด style | ✅ ใช้ shadow-as-border, ❌ อย่าใช้ weight 700 กับ body text |
| 8. Responsive Behavior | breakpoints, touch targets, collapsing strategy | mobile 375px, tablet 768px, desktop 1280px |
| 9. Agent Prompt Guide | ตัวอย่าง prompt สำหรับ AI coding agents สร้าง UI ตาม spec | "Create a card: white bg, shadow stack: ..." |

- ถ้าใช้ **Mode D** — ต้องระบุ reference site(s) ที่ใช้เป็น inspiration และอะไรที่ customize แล้ว
- ถ้าใช้ **Mode F** — ต้องระบุว่า Claude Design auto-derive จาก source อะไร (codebase / website / docs) และ section ไหนที่ override/customize ด้วย manual input
- ถ้าใช้ **Mode A/B/C/E/F** — section 9 (Agent Prompt Guide) ยังควรมีเพื่อให้ AI agent มี reference ในการสร้าง components
- Do's / Don'ts ต้องมีอย่างน้อย 5 Do + 5 Don't
- Agent Prompt Guide ต้องมี example prompts อย่างน้อย 3 ตัวอย่าง (เช่น hero section, card, navigation)

**01 - Design Tokens:**
- ทุก token ต้องมี CSS variable name เช่น `--color-primary-500`, `--spacing-4`
- ต้องครอบคลุม: colors (≥5 shades), typography (≥4 sizes), spacing (≥6 steps)
- ถ้าใช้ framework (เช่น TailwindCSS) — map tokens กับ Tailwind classes
- **Color roles** ต้องแยกตามบทบาท (ไม่ใช่แค่ primary/secondary):
  - Primary & Accent — brand colors, CTA
  - Semantic — success/warning/error/info
  - Neutral Scale — text hierarchy (#171717 → #fafafa)
  - Surface & Overlay — bg, card, modal backdrop
  - Interactive — link, focus ring, selection
- **Depth & Elevation** ต้องมี shadow table อย่างน้อย 3 ระดับ (flat / subtle / elevated) พร้อม exact CSS values

**02 - Component Inventory:**
- ทุก component ต้องระบุ: name, variants, props, states
- Priority: Must Have / Should Have / Could Have
- ระบุว่าใช้ library ไหน (เช่น shadcn/ui, Radix) หรือ custom

**03 - Page Layouts:**
- ทุก page จาก user flows ต้องมี layout
- ระบุ: components ที่ใช้, data ที่ต้อง fetch, responsive behavior
- Mode A: link ไป Stitch mockup
- Mode B: link ไป Figma frame
- Mode C: screenshot + annotated layout
- Mode D: link ไป customized `00-design-vision.md` + `design-reference/*.md`
- Mode E: link ไป `services/web/` production code + screenshots
- Mode F: link ไป `docs/ux/claude-design/<screen>.html` (HTML export) + screenshot PNG

**04 - Navigation Structure:**
- ทุก route ต้อง map กับ page layout
- ระบุ: auth required?, role-based access?, dynamic segments?
- Breadcrumb logic ชัดเจน

**05 - Interaction Patterns:**
- ทุก form ต้องระบุ validation rules + error display
- Loading states: skeleton vs spinner vs progressive
- Empty states: illustration + CTA
- Responsive: mobile-first breakpoints

---

### Step 3: Review & Approve

UX deliverables ต้องถูก review ก่อน handoff ไป implementation:

#### Option A: Adversarial Review (แนะนำ — consistent กับ BA/SD/TD)

```
/ux-review all         → UX Reviewer สแกน 22 attack vectors → claim-review-01.md
/ux-rebuttal claim-review-01.md  → UX Defender แก้ + โต้ → rebuttal-round-01.md
/ux-review all         → re-review → claim-review-02.md (ถ้ายังมี findings)
...ทำซ้ำจนไม่มี CRITICAL/HIGH ค้าง
```

**22 UX Attack Vector Categories:**
1. Design Token Completeness & Consistency
2. Component State & Variant Coverage
3. Page Layout Coverage (ทุก user flow)
4. Empty / Error / Loading State Design
5. Responsive Design & Breakpoints
6. Navigation Completeness
7. Accessibility (WCAG AA)
8. Form UX Patterns
9. API Data Alignment
10. Cross-Doc Consistency
11. **Design Vision Coherence** — UI ตรงกับ visual theme/atmosphere ที่ประกาศใน 00-design-vision.md หรือไม่
12. **Do's/Don'ts Violations** — deliverables ละเมิด guardrails ที่กำหนดไว้ใน design vision หรือไม่
13+ more...

**Personas:**
- `.agents/skills/andm-ux-reviewer/SKILL.md` — Adversarial UX Consultant
- `.agents/skills/andm-ux-defender/SKILL.md` — Constructive UX Defense

**Output:** `docs/ux/claim-review-and-rebuttal/`

#### Option B: Lightweight Fix (เมื่อ token budget จำกัด)

```
/ux-review all         → feedback list
/ux-fix claim-review-01.md  → แก้ตรงๆ ไม่มี adversarial verdict → fix report
/ux-review all         → re-check
```

**เมื่อไรใช้ Option B:**
- Findings ส่วนใหญ่เป็น LOW/MEDIUM (ไม่มี CRITICAL)
- Round 2+ ที่เหลือ findings ไม่กี่จุด
- Token budget จำกัด — Option B ใช้ ~50% ของ Option A

#### Approval

- ⏸️ HALT — ให้ user/stakeholder review ก่อนเริ่ม implementation
- ถ้ามี findings → เลือก `/ux-rebuttal` (A) หรือ `/ux-fix` (B) → review อีกรอบ
- ถ้าผ่าน (ไม่มี CRITICAL/HIGH ค้าง) → proceed to Phase 3 (Implementation)

---

### Step 4: Handoff to Implementation

เมื่อ UX deliverables ผ่าน approve แล้ว (UX-06 handoff doc ถูก drop ใน SD-as-Master — ดูนายหน้า input ตรง):

1. **andm-impl-engineer** อ่าน `docs/ux/00-05` โดยตรง — เริ่มจาก `02-component-inventory.md` (Must Haves) + `03-page-layouts.md` (ต่อ user flow) + `01-design-tokens.md` (theming)
2. **andm-impl-engineer** copy `docs/ux/00-design-vision.md` ไปเป็น `DESIGN.md` ที่ project root เพื่อให้ AI coding agents อ่านได้อัตโนมัติ (ต้นฉบับ reference ยังอยู่ที่ `design-reference/`)
3. **andm-impl-planner** ใช้ `docs/ux/02-component-inventory.md` เพื่อสร้าง frontend tasks ใน impl-plan
4. **td-architect** (`docs/technical-design/03-frontend-design.md`) reference `docs/ux/02-05` สำหรับ component tree + routing + state mapping
5. **andm-code-reviewer** ตรวจว่า implementation ตรงกับ UX spec + design vision (Do's/Don'ts)

**andm-impl-engineer Onboarding Addition:**
```
7. Check `docs/ux/00-05` — UX/UI spec to implement (design tokens, components, layouts)
```

---

## Output Files Summary

```
docs/ux/
  00-design-vision.md              ← Visual identity, do's/don'ts, agent prompt guide
  01-design-tokens.md              ← Colors (role-based), typography, spacing, depth/elevation
  02-component-inventory.md        ← Components + variants + states + priority
  03-page-layouts.md               ← Wireframe/layout ทุกหน้า
  04-navigation-structure.md       ← Sitemap + breadcrumb UX + nav labels + auth guards (routing authority: TD 03-frontend-design)
  05-interaction-patterns.md       ← Forms, loading, empty, error, responsive

  (06-handoff-to-implementation.md — DROPPED in SD-as-Master consolidation;
   TD และ Impl Planner อ่าน UX-00..05 โดยตรง)
```

**Mode-specific extras:**

| Mode | Extra Files |
|------|-------------|
| A: AI-Generated | `.superpowers/brainstorm/` (Stitch mockup files) |
| B: Figma-First | `.claude/rules/design-system.md` (from Figma MCP) |
| C: Existing Audit | `docs/ux/audit-report.md` + `docs/ux/screenshots/` |
| D: Reference-Driven | `design-reference/<name>-DESIGN.md` (user-supplied; acquisition per [`ux-design-reference-acquisition.md`](./ux-design-reference-acquisition.md)) |
| E: Frontend Direct | — (UI code lives in `services/web/` directly; specs extracted post-hoc) |
| F: Claude Design | `docs/ux/claude-design/` (HTML + PNG exports + `export-manifest.json` + README with internal URL + changelog) |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้าระหว่าง UX design พบปัญหาที่แก้ใน UX ไม่ได้:

| Trigger | ตัวอย่าง | Backtrack To | Action |
|---------|---------|-------------|--------|
| **Missing user flow** | ไม่มี flow สำหรับ empty state / first-time user | BA | `/backtrack ba` |
| **User story ไม่สอดคล้องกับ UI** | "ดูข้อมูลทุกอย่างในหน้าเดียว" — data มากเกินไป | BA | `/backtrack ba` |
| **Data dictionary ไม่ครบ** | UI ต้องแสดงข้อมูลที่ BA ไม่ได้ระบุ | BA | `/backtrack ba` |
| **API ไม่รองรับ UI flow** | ต้อง real-time update แต่ API เป็น REST polling | SD | `/backtrack sd` |
| **Component ต้อง data ที่ API ไม่มี** | Dashboard widget ต้อง aggregated metric ไม่มี endpoint | SD | `/backtrack sd` |
| **Navigation ขัดกับ routing** | Multi-step wizard vs SPA routing conflict | SD | `/backtrack sd` |

> ⚠️ อย่า design ด้วย assumptions — ถ้า upstream ไม่ครบ → backtrack ก่อน
> **📖 Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## เมื่อไหร่ถือว่า Phase 1C ผ่าน

- ✅ `docs/ux/00-05` ครบถ้วน (UX-06 ถูก drop ใน SD-as-Master)
- ✅ `00-design-vision.md` มีครบ 9 sections (โดยเฉพาะ Do's/Don'ts และ Agent Prompt Guide)
- ✅ ทุก user flow จาก BA มี page layout
- ✅ Design tokens defined พร้อม functional color roles และ depth/elevation
- ✅ Component inventory ครบ Must Have ทั้งหมด
- ✅ Navigation structure ตรงกับ user flows
- ✅ UI สอดคล้องกับ design vision (Do's/Don'ts ไม่ถูกละเมิด)
- ✅ User/Stakeholder approved
- ✅ TD และ Impl Planner สามารถ consume UX-00..05 โดยตรงเป็น input
