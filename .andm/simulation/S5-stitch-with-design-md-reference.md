# S5: Stitch greenfield + DESIGN.md reference augmentation

> มี BA + SD ครบแล้ว, อยากให้ Stitch generate UI ที่มี personality ระดับ Vercel/Linear โดยไม่ต้องออกแบบ design system เอง — ใช้ user-supplied DESIGN.md ที่ acquired ตาม `.andm/development-guide/ux-design-reference-acquisition.md` เป็น visual language guide เสริม

---

## Context

- **สถานะ:** Phase 1C (UX/UI Design) — BA + SD ครบแล้ว, ยังไม่มี Figma file, ยังไม่มี brand guidelines
- **มี:** `docs/ba/01-05` (v1.2), `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06), `docs/api-specs/`, Stitch skill installed
- **ไม่มี:** designer ประจำ, Figma license, time-budget สำหรับ design system จากศูนย์
- **เป้าหมาย:** ได้ `docs/ux/00-05` ภายใน 2 วัน ที่มี visual identity ระดับ production แทนที่จะเป็น "generic SaaS look" จาก Stitch
- **เลือก pattern:** Mode A (Stitch) + optional user-supplied DESIGN.md reference

---

## Timeline

### Day 1 ช่วงเช้า: เลือก Reference Site

```
Session 1: PM + tech lead เปิด .andm/development-guide/ux-design-workflow.md
           → อ่านตาราง "Reference Site Selection Guide" ใน Mode D section
           → cross-ref กับ .andm/development-guide/ux-design-reference-acquisition.md §6
```

**Decision matrix ที่ใช้เลือก:**

| Reference | Vibe | เหมาะกับ TaskFlow ไหม |
|-----------|------|---------------------|
| Vercel | Minimal, mono-tone, tight typography | ✅ ตรงกับ "professional but approachable" |
| Linear | Sharp gradients, dark-first, micro-shadows | ✅ เหมาะกับ kanban/task UI |
| Supabase | Green-accent, dev-tool feel | ❌ developer-tool เกินไป |
| Notion | Soft, beige, document-heavy | ❌ ไม่ใช่ task tracker |

**สรุป:** ใช้ **hybrid Vercel + Linear** — Vercel เป็น base typography/spacing, Linear เป็น depth/elevation system

---

### Day 1 ช่วงบ่าย: Acquire Reference Files

```
Session 2: Operator เปิด acquisition guide → เลือก Option 2 (Browser save)
           เพราะ TaskFlow เป็น project ภายในที่ห้ามรัน 3rd-party npm package โดยไม่ vet
Action:    เปิด https://getdesign.md/vercel/design-md → save markdown content
           เปิด https://getdesign.md/linear.app/design-md → save markdown content
```

**Output (user-placed manually):**

```
design-reference/
  vercel-DESIGN.md       ← saved 2026-04-08
  linear-DESIGN.md       ← saved 2026-04-08
```

**Provenance header ที่ operator เติมเองตาม acquisition guide §4:**

```markdown
<!--
  source: https://getdesign.md/vercel/design-md
  fetched: 2026-04-08
  acquired_via: option-2-browser-save
  acquired_by: @taskflow.lead
  notes: License reviewed against Vercel public marketing pages 2026-04-08; no proprietary content copied.
-->
# Vercel DESIGN.md
...
```

---

### Day 1 ช่วงเย็น: Customize → Root DESIGN.md

```
Session 3: UX lead เปิด design-reference/vercel-DESIGN.md อ่านจบ
Action:    cp design-reference/vercel-DESIGN.md DESIGN.md
           แล้วเปิด DESIGN.md edit:
           - accent color #0070f3 → brand color #6366f1 (TaskFlow indigo)
           - merge depth/elevation table จาก linear.app-DESIGN.md
           - เพิ่ม TaskFlow-specific Do's/Don'ts (≥5+5)
```

**⚠️ Guardrail:** ห้ามแก้ไฟล์ใน `design-reference/` — ต้นฉบับต้องอยู่ pristine สำหรับ traceability

---

### Day 2 ช่วงเช้า: Run Stitch Generation

```
Session 4: เปิด agent session ใหม่
Action:    /ux-design stitch
```

**Agent ทำ Phase 1 — Onboarding:**

```
Read: .andm/prompt-templates/ux-design-stitch-prompt.md
  → พบ optional reference step
Glob: design-reference/*.md
  → พบ vercel-DESIGN.md + linear.app-DESIGN.md → reference mode active
Glob: DESIGN.md (root)
  → ✅ พบ — Stitch จะอ่านอัตโนมัติเป็น style guide
```

**Agent ทำ Phase 3 — Generate Screens:**

```
Action:   เรียก Stitch generate screens สำหรับ 8 user flows
Result:   Stitch ใช้ root DESIGN.md เป็น visual context
          → ทุก screen มี Vercel-like minimalism + Linear-like depth
          → accent color = #6366f1 (ตาม brand customization)
```

---

### Day 2 ช่วงเที่ยง: HALT for Review

```
Agent:  "Generated 8 screens. กรุณา review ที่ .stitch/designs/
        แล้วเลือก approve ทั้งหมด หรือระบุ screen ที่ต้อง iterate"
User:   "approve ทั้งหมด — accent color match brand แล้ว"
```

---

### Day 2 ช่วงบ่าย: Write 00-05 Deliverables

**Agent ทำ Phase 4 — Write Deliverables:**

| File | Source | Note |
|------|--------|------|
| `00-design-vision.md` | DESIGN.md (root) + design-reference/* | ครบ 9 sections + Reference Provenance block |
| `01-design-tokens.md` | extracted จาก root DESIGN.md | functional color roles + depth/elevation table 4 levels |
| `02-component-inventory.md` | observed จาก Stitch screens | ทุก component reference token จาก 01 |
| `03-page-layouts.md` | Stitch generated screens | link ไป `.stitch/designs/*.html` |
| `04-navigation-structure.md` | derived จาก user flows | route table 8 routes |
| `05-interaction-patterns.md` | DESIGN.md Do's/Don'ts + flows | form, loading, empty, error |

**Snippet จาก `00-design-vision.md` Reference Provenance block:**

```markdown
## Reference Provenance

This design vision is customized from user-supplied references at `design-reference/` (acquired per `.andm/development-guide/ux-design-reference-acquisition.md`):

| Source | Acquired Via | Acquired By | Fetched | Used For |
|--------|--------------|-------------|---------|----------|
| `design-reference/vercel-DESIGN.md` (origin: https://getdesign.md/vercel/design-md) | option-2-browser-save | @taskflow.lead | 2026-04-08 | Typography, spacing, mono-tone palette |
| `design-reference/linear-DESIGN.md` (origin: https://getdesign.md/linear.app/design-md) | option-2-browser-save | @taskflow.lead | 2026-04-08 | Depth/elevation system, kanban patterns |

**Customizations from originals:**
- Accent color: `#0070f3` (Vercel) → `#6366f1` (TaskFlow indigo brand)
- Added 8 TaskFlow-specific Do's/Don'ts (kanban-focused)
- Removed Vercel's marketing-page typography scale (oversized)
```

**Snippet — 1 Do + 1 Don't:**

```markdown
## Do's and Don'ts

✅ **Do** — ใช้ shadow-as-border สำหรับ kanban cards (Linear pattern)
   `box-shadow: 0 0 0 1px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04);`

❌ **Don't** — ใช้ font-weight 700 กับ body text
   เหตุผล: ขัดกับ Vercel-inspired tight tracking → ใช้ 500 หรือ 600 เท่านั้น
```

---

### Day 2 ช่วงเย็น: UX Review

```
Session 5: เปิด agent session ใหม่
Action:    /ux-review all
```

**Agent ทำ Phase 1 — Load 22-Category Scan:**

```
Read: .agents/skills/andm-ux-reviewer/SKILL.md → 22 attack vectors active
Read: docs/ux/00-05 (รวม 00-design-vision.md)
```

**ผลการ scan ของ vector ใหม่:**

| # | Category | Result |
|---|----------|--------|
| 21 | Design Vision Coherence | ✅ Pass — 9 sections ครบ, Reference Provenance block ระบุ source/commit |
| 22 | Do's/Don'ts Violations | ✅ Pass — ตรวจ 02-component-inventory.md → ไม่มี component ที่ใช้ font-weight 700 กับ body |

**สรุป review:** 0 CRITICAL, 1 MEDIUM (touch target ใน mobile kanban — ไม่เกี่ยว reference) → `/ux-fix` แก้ใน 15 นาที

---

## Workflow Commands Used

| Step | Command | Sessions | Time |
|------|---------|----------|------|
| Acquire references | Browser save จาก getdesign.md (Option 2) → paste ที่ `design-reference/<name>-DESIGN.md` ตาม [acquisition guide](../development-guide/ux-design-reference-acquisition.md) | UX lead | ~10 min |
| Customize root DESIGN.md | manual edit | UX lead | ~2 hr |
| Generate UI | `/ux-design stitch` | 1 agent session | ~1 day |
| Review | `/ux-review all` | 1 agent session | ~30 min |
| Fix MEDIUM finding | `/ux-fix <claim-review file>` | 1 agent session | ~15 min |
| **Total** | | **5 sessions** | **~2 days** |

---

## Comparison: ถ้าไม่มี DESIGN.md reference

| มิติ | ❌ ไม่มี reference | ✅ มี reference |
|------|------------------|---------------|
| Visual personality | "generic SaaS look" — ดูเหมือน boilerplate | Vercel/Linear-inspired identity ชัดเจน |
| Token decisions | Stitch เดาเอง → AI slop risk สูง | extracted จาก proven design system |
| Do's/Don'ts | ต้อง invent เอง → reviewer #22 ตรวจยาก | ยึดจาก reference + customization → testable |
| Time-to-vision | ~3-4 วัน (ออกแบบ + iterate) | ~2 วัน (customize + generate) |
| Traceability | ไม่มี source → drift ตรวจยาก | Reference Provenance block + commit pin |

---

## Methodology Verdict

✅ **Pros:**
- ได้ design system ระดับ production ภายใน 2 วัน
- Reference Provenance block ทำให้ trace ที่มาได้แม้ผ่านไป 1 ปี
- Vector #21/#22 ทำหน้าที่เป็น automated guardrail — ไม่ต้องอาศัย human judgment ล้วน
- AI coding agents (Phase 3 implementation) ได้ root `DESIGN.md` ที่ consistent กับ `docs/ux/00-design-vision.md`

⚠️ **Cons:**
- Acquisition เป็น operator-side action — ทีมต้องตัดสินใจเองว่าใช้ option ไหน (npx getdesign / browser save / copy / hand-author) ตาม security/policy ของโปรเจค
- ต้อง customize อย่างน้อย accent color + Do's/Don'ts — ไม่งั้นโดน "copy verbatim" warning จาก reference prompt guardrails
- Reference อาจไม่ครอบคลุมทุก component ของโปรเจค (เช่น kanban-specific) → ยังต้อง design เพิ่มเอง
- Provenance metadata ต้องเติมเองตาม acquisition guide §4 — ถ้าลืมเติม workflow HALT ที่ Phase 2 validation

💡 **Recommendation:**
- ใช้ pattern นี้กับ greenfield SaaS / dashboard / dev-tool ทุกตัวที่ยังไม่มี brand guidelines
- ระหว่าง customize, ตั้งใจเปลี่ยนอย่างน้อย: accent color, font fallback, ≥5 project-specific Do's/Don'ts
- เก็บ `design-reference/` ใน git เสมอ เพื่อ future drift detection (แต่ตรวจ license ก่อน commit สาธารณะ)
- ถ้าทีมต้องการ reproducibility สูง — ใช้ Option 3 (copy from internal mirror project) แทน Option 1/2 ที่ขึ้นกับ getdesign.md uptime + schema
