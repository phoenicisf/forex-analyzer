# DESIGN.md Acquisition Guide

> **คู่มือนี้สอนวิธีได้ `DESIGN.md` มาวางใน `design-reference/` เพื่อให้ `/ux-design` workflow (Mode A optional / Mode B optional / Mode D primary) อ่านไปใช้**
>
> **Methodology contract:** workflow + prompt-templates อ่านจาก `design-reference/<name>-DESIGN.md` เท่านั้น — ไม่มี automated fetch หรือ curl อะไรอีก ทุก acquisition path เป็น **operator-side action** ที่ทำตามคู่มือนี้แล้ววางไฟล์ลงตาม convention

---

## 1. DESIGN.md คืออะไร

Plain-text design system file ที่ extract visual identity ของเว็บไซต์จริง (Vercel, Linear, Supabase, Stripe ฯลฯ) ออกมาเป็น 9 sections:

1. **Visual Theme & Atmosphere** — narrative ของ visual identity
2. **Color Palette & Roles** — colors แยกตาม role (Primary/Accent, Semantic, Neutral, Surface, Interactive)
3. **Typography Rules** — font family, size scale, weight system
4. **Component Stylings** — key components พร้อม exact values
5. **Layout Principles** — spacing system, grid, whitespace philosophy
6. **Depth & Elevation** — shadow levels (≥3) พร้อม CSS values
7. **Do's and Don'ts** — guardrails สำหรับ AI agents (≥5 + 5)
8. **Responsive Behavior** — breakpoints, touch targets, collapsing strategy
9. **Agent Prompt Guide** — example prompts สำหรับ AI coding agents (≥3)

AI coding agents อ่านไฟล์นี้แล้วสร้าง UI ที่มี look & feel สอดคล้องกับ reference ได้

---

## 2. Acquisition Options

ANDM ไม่ผูกกับ acquisition method ใดๆ — เลือกข้อใดก็ได้ตาม context ของโปรเจค รายการเรียงตาม **friction ต่ำ → สูง**:

### Option 1 — `npx getdesign` (hosted service, 3rd-party)

**ใช้เมื่อ:** อยาก grab DESIGN.md ของเว็บใดเว็บหนึ่งแบบเร็วที่สุด, ยอมรับ supply-chain risk ของการรัน 3rd-party npm ได้

**ขั้นตอน:**
```bash
# จาก project root
npx getdesign@latest add linear.app
# tool จะวาง DESIGN.md ที่ project root โดย default
mkdir -p design-reference
mv DESIGN.md design-reference/linear-DESIGN.md
```

**Pros:**
- ขั้นตอนเดียวจบ
- รองรับเว็บที่ getdesign.md catalog มี (ดู `https://getdesign.md/` หน้าหลักสำหรับ catalog ปัจจุบัน)

**Cons / Risks:**
- ⚠️ **Supply-chain risk** — `npx` รัน package code โดยตรงบนเครื่อง; review `package.json` + post-install scripts ก่อนใช้ใน project ที่ sensitive (ภายในองค์กรที่ห้าม unvetted npm packages — skip option นี้)
- ❌ ไม่ pin version — re-run อาจได้ DESIGN.md เนื้อหาต่าง
- ❌ ไม่ expose source URL/commit ใน output → ต้องเติม Provenance block (§4) เอง
- ❌ ปลายทาง default คือ project root (`./DESIGN.md`) — ต้อง `mv` ไป `design-reference/<name>-DESIGN.md` ตาม ANDM convention เสมอ

### Option 2 — Browser save จาก `getdesign.md` web UI

**ใช้เมื่อ:** ไม่อยากรัน `npx`, ต้องการ review เนื้อหาก่อน save

**ขั้นตอน:**
1. เปิด `https://getdesign.md/<site>/design-md` ใน browser (เช่น `https://getdesign.md/linear.app/design-md`)
2. Locate the rendered DESIGN.md content (ใช้ "Download for Claude" button หรือ View Page Source แล้ว copy markdown ออกมา)
3. Paste ลงไฟล์ใหม่ที่ `design-reference/<name>-DESIGN.md` (เช่น `design-reference/linear-DESIGN.md`)
4. ตรวจ 9 sections (§1) ครบ — ถ้าหายไปบาง section ให้เติมด้วย `n/a` หรือ author เองก่อน proceed

**Pros:**
- ไม่ต้องรัน 3rd-party code
- Review เนื้อหาก่อน accept ได้

**Cons:**
- Manual steps มากกว่า; ขึ้นกับ HTML structure ของ getdesign.md ที่ change ได้
- ไม่มี provenance metadata อัตโนมัติ — เติมเอง (§4)

### Option 3 — Copy from another team's project / archived snapshot

**ใช้เมื่อ:** องค์กรมีหลายโปรเจคที่ใช้ reference เดียวกัน, มี snapshot ที่ถูก vet แล้ว

**ขั้นตอน:**
```bash
# จาก project root
mkdir -p design-reference
cp /path/to/other-project/design-reference/linear-DESIGN.md \
   design-reference/linear-DESIGN.md
```

**Pros:**
- Reproducible — ทีมใช้ source เดียวกันทุกครั้ง
- ถ้า snapshot มี Provenance block ที่ระบุ source URL + fetch date จะสืบกลับได้
- ไม่มี supply-chain risk เพิ่ม

**Cons:**
- ต้องมี internal mirror หรือ peer project ที่เก็บไฟล์ไว้
- เนื้อหาอาจเก่ากว่า upstream — ตรวจ `fetched:` field ใน Provenance ก่อนใช้

### Option 4 — Author DESIGN.md เองตาม schema

**ใช้เมื่อ:** ไม่มี reference site ที่อยาก clone (โปรเจคต้องการ aesthetic ใหม่), หรือต้องการรวม inspiration จากหลาย source แล้วผ่านการคิดเอง

**ขั้นตอน:**
1. สร้าง `design-reference/<project-name>-DESIGN.md` (เช่น `acme-internal-DESIGN.md`)
2. เขียน 9 sections ตาม schema (§1) — ใช้ template ด้านล่าง
3. ระบุ Provenance ว่า `source: hand-authored by <author> on <date>`

**Template (paste แล้วเติม):**

```markdown
<!--
  source: hand-authored
  author: <your name>
  authored: <YYYY-MM-DD>
  inspired_by: <list of reference sites if any>
-->

# DESIGN.md — <project name>

## 1. Visual Theme & Atmosphere
<2-3 paragraphs describing the visual narrative, mood, target user emotion>

## 2. Color Palette & Roles
### Primary / Accent
- `--color-primary-500: #...` — <when to use>
- `--color-accent-500: #...` — <when to use>

### Semantic
- `--color-success: #...`
- `--color-warning: #...`
- `--color-error: #...`
- `--color-info: #...`

### Neutral Scale (≥7 steps)
- `--color-neutral-50: #...`
- ... up to `--color-neutral-950`

### Surface / Overlay
- `--color-bg-body: #...`
- `--color-bg-card: #...`
- `--color-bg-overlay: #...`

### Interactive
- `--color-interactive-default: #...`
- `--color-interactive-hover: #...`
- `--color-interactive-active: #...`
- `--color-interactive-disabled: #...`

## 3. Typography Rules
- Font family (body): <name>
- Font family (display): <name or same as body>
- Font family (mono): <name>
- Type scale: 12 / 14 / 16 / 18 / 20 / 24 / 32 / 48 (px or rem)
- Weights used: 400 / 500 / 600 / 700 (only those declared)
- Line-height: body 1.5, headings 1.2

## 4. Component Stylings
For each key component, specify exact values:
- **Button (primary)**: bg `--color-primary-500`, text `#fff`, padding `8px 16px`, radius `6px`, hover `--color-primary-600`
- **Card**: bg `--color-bg-card`, border `1px solid --color-neutral-200`, radius `8px`, padding `16px`
- **Input**: bg `--color-bg-body`, border `1px solid --color-neutral-300`, focus ring `--color-primary-500 / 30%`
- (เพิ่มเติม: Modal, Toast, Tab, Badge, ฯลฯ)

## 5. Layout Principles
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 (px)
- Container max-width: <value>
- Grid columns (desktop): <value>
- Whitespace philosophy: <2-3 sentences>

## 6. Depth & Elevation
- Level 0: no shadow (flat)
- Level 1: `box-shadow: 0 1px 2px rgba(0,0,0,0.06)`
- Level 2: `box-shadow: 0 4px 8px rgba(0,0,0,0.08)`
- Level 3: `box-shadow: 0 12px 24px rgba(0,0,0,0.12)`
(at least 3 declared levels)

## 7. Do's and Don'ts
### Do's (≥5)
1. Always use `--color-primary-500` for primary CTAs
2. Maintain ≥4.5:1 contrast for body text
3. ...

### Don'ts (≥5)
1. Never mix more than 2 accent colors per page
2. Never use drop shadows above level 3
3. ...

## 8. Responsive Behavior
- Mobile breakpoint: <px>
- Tablet breakpoint: <px>
- Desktop breakpoint: <px>
- Touch target minimum: 44×44 px
- Collapsing strategy (nav, sidebar, table): <description>

## 9. Agent Prompt Guide
Example prompts for AI coding agents (≥3):

### Example 1 — Building a primary CTA
> "Create a primary button using `--color-primary-500` background, white text, `--space-2 --space-4` padding, `--radius-md` border-radius. Hover state shifts to `--color-primary-600`. Match the spacing rhythm in §5."

### Example 2 — Building a card layout
> "..."

### Example 3 — Handling empty state
> "..."
```

**Pros:**
- 100% control; no external dep; no provenance ambiguity
- Schema เป็น ANDM contract — ทำเองได้ตรงสุด

**Cons:**
- Effort สูง (~2-4 hr/file)
- ต้องมี design taste พอที่จะ author content ที่ AI agent ใช้ได้

---

## 3. Placement Convention

ทุก option ต้อง **end up** ที่ path เดียวกันเพื่อ workflow อ่านได้:

```
<project-root>/
└── design-reference/
    ├── linear-DESIGN.md       ← reference 1 (Mode D primary OR Mode A/B optional)
    ├── vercel-DESIGN.md       ← reference 2 (mix-and-match)
    └── <project>-DESIGN.md    ← hand-authored (Option 4)
```

Naming: `<source-name>-DESIGN.md` — kebab-case, no spaces, suffix `DESIGN.md` (uppercase D)

**ห้าม:**
- ❌ วาง DESIGN.md ที่ project root โดยตรง (ยกเว้น Mode A Stitch ที่ต้องการให้ Stitch อ่านอัตโนมัติ — ในกรณีนั้น `cp` จาก `design-reference/<source>-DESIGN.md` ไปที่ root เป็น step สุดท้าย)
- ❌ Edit ต้นฉบับใน `design-reference/` หลัง download — มันคือ reference ห้ามแก้ ทำ customization ใน `docs/ux/00-design-vision.md` เท่านั้น
- ❌ Commit DESIGN.md ที่ contain license-restricted content โดยไม่ตรวจ — verify เว็บต้นทางว่าอนุญาตให้ derive design system summary หรือไม่ (ส่วนใหญ่ visual style ไม่ copyrightable แต่ logo/font binary อาจจะ)

---

## 4. Provenance Metadata (Mandatory)

ทุก DESIGN.md ใน `design-reference/` ต้องมี HTML comment block ที่หัวไฟล์เพื่อ traceability:

```markdown
<!--
  source: <URL หรือ "hand-authored">
  fetched: <YYYY-MM-DD>
  acquired_via: <option-1-npx-getdesign | option-2-browser-save | option-3-copy-from-<project> | option-4-hand-authored>
  acquired_by: <your name or @handle>
  notes: <optional — license check, supply-chain review status, etc.>
-->
```

**ตัวอย่าง:**
```markdown
<!--
  source: https://getdesign.md/linear.app/design-md
  fetched: 2026-04-28
  acquired_via: option-2-browser-save
  acquired_by: @kritsana.ye
  notes: Reviewed against Linear public marketing pages 2026-04-28; no proprietary content copied.
-->

# Linear DESIGN.md
...
```

**ทำไมต้องมี:**
- Re-sync detection — ถ้า upstream เปลี่ยน schema ทีมตรวจได้
- License audit — ตรวจสอบย้อนได้ว่าใครรับผิดชอบและทำเมื่อไหร่
- ANDM `00-design-vision.md` Reference Provenance block อ้างกลับมาที่ field เหล่านี้

---

## 5. Validation Checklist (ก่อน proceed `/ux-design reference`)

ก่อนรัน workflow ตรวจให้ครบ:

- [ ] ไฟล์อยู่ที่ `design-reference/<name>-DESIGN.md` (ตาม convention §3)
- [ ] Provenance metadata block มีครบ (§4)
- [ ] 9 sections ใน DESIGN.md ครบ (§1) — หาก section ไหนเป็น `n/a` ระบุไว้ชัดเจนแทนที่จะปล่อยว่าง
- [ ] License/supply-chain note ใน Provenance block (ถ้าใช้ Option 1) ระบุชัดว่า reviewed แล้ว
- [ ] ไม่ commit binary asset (logo SVG/PNG, fonts) ที่ DESIGN.md อ้างถึง — link ไป external CDN หรือ document download instruction แทน

ถ้า checklist ผ่านครบ → รัน `/ux-design reference` ได้เลย; workflow จะ HALT ถ้าไฟล์หายหรือ schema ไม่ครบ

---

## 6. Reference Site Selection Guide

ถ้ายังไม่รู้จะใช้ reference อะไร เลือกตาม project archetype:

| ถ้าโปรเจคเป็นแบบนี้ | ลองดู reference เหล่านี้ |
|---------------------|------------------------|
| Developer tool / SaaS dashboard | Vercel, Linear, Supabase, Sentry |
| AI / ML product | Claude, Mistral AI, Cohere |
| Productivity app | Superhuman, Raycast, Notion |
| Creative / media tool | RunwayML, ElevenLabs, Figma |
| Clean docs / marketing | Mintlify, Resend, Expo |
| E-commerce / consumer | Stripe, Revolut, Wise |
| Mix หลายแบบ | เลือก 2-3 sites แล้วผสม mix & match — แต่ละไฟล์อยู่ใน `design-reference/` แยกกัน |

หลังเลือก → ใช้ Option ใดก็ได้ใน §2 เพื่อ acquire DESIGN.md ของแต่ละ reference

---

## 7. ทำไมต้อง decouple acquisition จาก workflow

ในอดีต `/ux-design reference` workflow hardcode raw GitHub URLs จาก `VoltAgent/awesome-design-md` เพื่อ `curl` DESIGN.md อัตโนมัติ ปัญหาที่เจอ (2026-04-28 audit):

1. **Upstream restructured** — VoltAgent ลบ DESIGN.md ทุกไฟล์ออกจาก GitHub repo (เหลือแค่ stub README.md), redirect ไป hosted service `getdesign.md` ที่ต้องใช้ `npx getdesign@latest add <site>` — ทุก raw URL ที่ workflow ใช้กลายเป็น 404 silently
2. **Workflow ผูกกับ 3rd-party schema** — เมื่อ schema upstream เปลี่ยน workflow พังโดยไม่มีสัญญาณ
3. **Supply-chain risk hardcoded** — บังคับใช้ `npx` หมายความว่าโปรเจค sensitive ไม่มี opt-out ที่ปลอดภัย

**Fix (2026-04-28):** workflow + prompt-templates ลบ acquisition logic ออกทั้งหมด → อ่านจาก `design-reference/<name>-DESIGN.md` ที่ user/operator วางมาแล้ว ตามที่คู่มือนี้ระบุ ANDM ไม่รับผิดชอบ acquisition; user/operator มี freedom เลือก option ที่เข้ากับ context (security policy, time budget, license requirements) ของแต่ละโปรเจค

---

## 8. ดูเพิ่มเติม

- `.agents/workflows/ux-design.md § Mode D` — workflow ที่บริโภคไฟล์จาก `design-reference/`
- `.andm/prompt-templates/ux-design-reference-prompt.md` — prompt ที่ AI agent ใช้
- `.andm/development-guide/ux-design-workflow.md` — full UX workflow journey (Step 1 + Step 2)
