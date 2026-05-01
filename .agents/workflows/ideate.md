---
description: Diverge → converge an initial idea/pain-point into a BA-Ready Brief at docs/foundation-input-sources/ideation-brief.md
---

# Workflow: Idea Refinement (Phase 0)

> **Output:** `docs/foundation-input-sources/ideation-brief.md` — BA-Ready Brief ที่ Phase 1 BA prompt จะอ่านต่ออัตโนมัติ
> **Phase:** Optional pre-phase (ก่อน Phase 1 DESIGN)

**Target:** `{{input}}` — initial pain point / problem statement, หรือ `"resume"`, หรือเว้นว่าง (interactive mode)

---

## Phase 0: Onboarding (อ่านไฟล์เหล่านี้ทันที)

1. `CLAUDE.md` — project rules, domain glossary, stakeholder context
2. `.agents/prompt-templates/idea-refinement-prompt.md` — **persona + 4-step process + output schema** (authoritative)
3. `.agents/agents/andm-ideation-facilitator.md` — subagent wrapper (ถ้า IDE รองรับ subagent fan-out)
4. `docs/foundation-input-sources/` — list ทุกไฟล์ + อ่าน `project-overview.md`, `stakeholder-input.md`, `competitive-analysis.md` (ข้าม placeholder)
5. `docs/foundation-input-sources/ideation-brief.md` — ถ้ามี → check resume mode

---

## Phase 1: Preconditions & Mode Detection

### 1.1 Preconditions

- ✅ มี `docs/foundation-input-sources/project-overview.md` (หรือมี `{{input}}` ยาวพอจะเข้าใจ domain)
- ⚠️ ถ้า `docs/ba/01-project-brief.md` **มีอยู่แล้ว** → warn user: *"มี BA docs อยู่แล้ว — Phase 0 ปกติใช้ก่อน BA. ต้องการทำ Phase 0 เพื่อ reframe/pivot หรือคุณต้องการ `/amend ba` แทน?"*

### 1.2 Mode Detection

| `{{input}}` value | Mode | พฤติกรรม |
|-------------------|------|---------|
| empty | Interactive | ถามทีละ step, รอ user ตอบ |
| `"resume"` | Resume | อ่าน brief เดิม → ถาม append/overwrite/refine |
| quoted string | Single-shot | ใช้ string เป็น initial pain point, ทำ 4 steps ต่อเนื่อง |

### 1.3 Existing Brief Handling

ถ้า `docs/foundation-input-sources/ideation-brief.md` **มีเนื้อหาแล้ว** (ไม่ใช่ placeholder):

1. แสดง preview (section headings + chosen direction)
2. ถาม user 3 options:
   - **(a) Append round** — เพิ่ม "Round 2" section ต่อท้ายไฟล์เดิม (keep history)
   - **(b) Overwrite** — ทำใหม่หมดทุก section
   - **(c) Refine** — เลือก section ที่จะแก้ (§2, §3, §5, §6)
3. รอคำตอบก่อน proceed

---

## Phase 2: 4-Step Idea Refinement

Follow **4 steps จาก `.agents/prompt-templates/idea-refinement-prompt.md` Layer 2**:

1. **Frame** — Sharpen HMW question (ถามกลับถ้า input สั้นเกิน)
2. **Diverge** — สร้าง ≥5 variations ผ่าน ≥3 lenses (Inversion / Constraint Removal / Audience Shift / Simplification / 10x Scale)
3. **Converge** — stress-test 3 axes (Business Value / Feasibility / Risk) → เลือก 1 chosen + optional 1 alternate + "Not Doing" list
4. **Write brief** — ตาม schema §4 Step 4 ของ prompt

**Interactive mode:** present ทีละ step, รอ confirm ก่อนไปต่อ
**Single-shot mode:** ทำทั้ง 4 steps ต่อเนื่อง, present brief ฉบับร่างให้ user review ก่อน write ไฟล์

---

## Phase 3: Quality Gate (ก่อน write ไฟล์)

ตรวจ checklist ใน `idea-refinement-prompt.md` Layer 3:

- [ ] HMW specific + ไม่ prescribe solution
- [ ] ≥5 variations ผ่าน ≥3 lenses ต่างกัน
- [ ] Chosen direction มี rationale ทั้ง BV/F/R
- [ ] "Not Doing" list ไม่ว่าง
- [ ] ≥2 open questions สำหรับ BA
- [ ] **ไม่มี** tech stack / library / architecture pattern ระบุใน brief

ถ้ามี ❌ → loop กลับ step ที่เกี่ยวข้อง อย่า write ไฟล์

---

## Phase 4: Write & Handoff

### 4.1 Write File

เขียน `docs/foundation-input-sources/ideation-brief.md` ตาม schema

Set `Status: ready-for-ba` ใน frontmatter-like header

### 4.2 Summary to User

แสดง:
- Path ของไฟล์ที่สร้าง/แก้
- HMW question ที่เลือก
- Chosen direction title
- Count: variations considered / not-doing items / open questions
- **Next command:** *"พร้อม Phase 1 BA แล้ว — ใช้ prompt `.agents/prompt-templates/ba-requirements-prompt.md` (BA จะอ่าน ideation-brief.md อัตโนมัติจาก foundation-input-sources)"*

### 4.3 Optional Artifacts

ไม่มี — Phase 0 ไม่มี claim-review / rebuttal loop (เป็น Optional pre-phase, ไม่มี governance gate)

---

## Escape Hatches

- **ถ้า user ไม่ตอบ HMW:** เสนอ HMW draft 2-3 options ให้เลือก
- **ถ้า ทุก variation score ต่ำทั้งกระดาน:** บอก user ว่า reframe HMW (กลับ Step 1) ดีกว่าเลือก variation ห่วย
- **ถ้า user ต้องการ skip Phase 0:** บอกว่า skip ได้, ไม่ต้องสร้างไฟล์ — และแนะนำให้ไป `/next` หรือรัน BA prompt ตรงๆ
