---
description: Run BA requirements discovery → produce 5 BA deliverables in docs/ba/01-05 (Phase 1A — v1.2: 06-handoff dropped; wraps ba-requirements-prompt.md so the agent gets full context every time)
---

# Workflow: BA Requirements Discovery (Phase 1A)

> **Output:** `docs/ba/01-project-brief.md` … `05-user-flows.md` (5 markdown files; v1.2: 06-handoff dropped — open questions/risks live ใน 02-05 ตาม domain) + seed `docs/state/overview.md`
> **Phase:** Phase 1 DESIGN → Step 1A
> **Why a workflow (not just a prompt):** copy-paste workflows ลืม onboarding บ่อย — workflow นี้ pin ลำดับ "อ่าน prompt template → อ่าน inputs → 4-phase execute → quality gate → write" ให้ agent ทำครบทุกครั้ง

**Input:** `{{input}}` — optional focus hint (e.g. system name, scope adjective like *"MVP only"* or *"include mobile"*); leave empty to follow `docs/foundation-input-sources/project-overview.md` verbatim.

---

## Phase 0: Onboarding (อ่านไฟล์เหล่านี้ทันที)

อ่าน batch นี้ในรอบเดียว (parallel reads) ก่อนทำอย่างอื่น — หาก skip ขั้นนี้ workflow จะ produce shallow output:

1. `CLAUDE.md` — project rules, methodology glossary (Option C terms), domain context (ถ้าโปรเจคเป็น downstream)
2. **`.andm/prompt-templates/ba-requirements-prompt.md`** — **AUTHORITATIVE persona + 4-phase process + Language Rule + Readability Contract + Guardrails + 5-doc output schema (v1.2: 06-handoff dropped — open questions distributed across 02-05 by domain)**. ทุก rule ใน file นี้ binding — workflow ฉบับนี้เป็น orchestration wrapper, ห้าม restate หรือ paraphrase rules
3. `.agents/skills/_core-behaviors.md` — 6 behavioral foundations (surface assumptions, push back, flipped interaction, simplicity, scope discipline, verify don't assume)
4. `docs/foundation-input-sources/` — ทำ Glob ดู file list, อ่านทุกไฟล์ที่ **ไม่ใช่ placeholder example**:
   - `project-overview.md` (REQUIRED — System Name, Domain, Stage, Stakeholders, Constraints)
   - `ideation-brief.md` (OPTIONAL — Phase 0 output, มี chosen direction + Not-Doing list + open questions)
   - `stakeholder-input.md`, meeting transcripts (`*.vtt`), MoM, product briefs, interview notes (อ่านทั้งหมดที่มีเนื้อหาจริง)
5. `docs/foundation-input-sources/notebooklm.md` (OPTIONAL — notebook registry; ถ้ามี ให้พร้อม query ผ่าน NotebookLM MCP ในระหว่าง Phase 2)
6. `docs/ba/` — ตรวจว่ามีไฟล์อยู่แล้วไหม (informs Phase 1.2 mode detection); skip silently ถ้าไม่มี
7. `docs/state/overview.md` — module status (OPTIONAL — skip silently if not found, สร้างใหม่ใน Phase 4.2 ถ้าไม่มี)

Once read (or skipped) → proceed to Phase 1.

---

## Phase 1: Preconditions & Mode Detection

### 1.1 Preconditions

| Check | Action ถ้าผ่าน | Action ถ้าไม่ผ่าน |
|-------|-----------------|---------------------|
| `docs/foundation-input-sources/project-overview.md` มีอยู่ + ไม่ใช่ placeholder | proceed | **HALT** — บอก user ให้กรอกอย่างน้อย: System Name + Domain + Stage + Stakeholders ก่อน หรือ confirm ว่าจะให้ Flipped Interaction ดึงออกมาเอง |
| `docs/design-docs/` ว่าง (ยังไม่มี SD) | proceed | ⚠️ warn user: *"พบ SD docs อยู่แล้ว — ปกติ BA มาก่อน SD. ต้องการ `/amend ba "<desc>"` (แก้ BA ปัจจุบัน) หรือ `/backtrack ba` (ย้อนแล้ว invalidate downstream) แทนหรือไม่? ถ้ายืนยันจะ re-do BA → confirm"* รอ user ตอบก่อน proceed |

### 1.2 Mode Detection

นับจำนวนไฟล์ที่มีจริงใน `docs/ba/` (เฉพาะ 01–05; v1.2):

| ไฟล์ที่มีอยู่ | Mode | พฤติกรรม |
|---------------|------|---------|
| 0 | **Fresh** | รัน 4-phase process เต็ม → write ครบ 5 docs |
| 1–4 (partial) | **Resume** | ถาม user 3 options: (a) เติมเฉพาะไฟล์ที่ขาด keep ของเดิม (b) restart fresh พร้อม backup เดิมเป็น `*.bak-<ISO-8601>` (c) abort |
| 5 (ครบ) | **Refine / amend hint** | ถาม user: *"BA docs ครบ 5 ไฟล์แล้ว (v1.2: 06-handoff dropped) — ต้องการ refine ไฟล์ไหน หรือใช้ `/amend ba "<desc>"` เพื่อ targeted edit?"*. ถ้าตอบ refine → ระบุไฟล์ที่จะแก้ → run flipped interaction เฉพาะ scope นั้น |

### 1.3 Flipped Interaction Decision (Layer 2 § Flipped Interaction ของ prompt template)

ประเมิน input จาก foundation-input-sources:

| Evidence ที่อ่านได้ | Action |
|---------------------|--------|
| มีแค่ `project-overview.md` (ไม่มี interviews / briefs / ideation-brief) | **Full Flipped Interaction** — 3 steps (Initial Brief → Dynamic Context → Synthesis) ตาม prompt Layer 2 |
| มี input docs พอประมาณ แต่มี gaps (เช่น ขาด NFR, edge cases, business rules) | **Meta-Prompting** — รวม 1–3 คำถามเจาะจงขึ้นต้นด้วย *"ก่อนเริ่มวิเคราะห์ — ขอข้อมูลเพิ่มเติม [N] ข้อ:"* |
| Input docs ครบทุกประเด็น (FR, NFR, business rules, edge cases ระบุชัด) | **Skip** — proceed direct analysis ใน Phase 2 |

**Question Display rule:** UI รองรับ Dialog/Modal → 1 Dialog = 1 คำถาม; UI ไม่รองรับ → inline พร้อม `🔲` prefix. Meta-Prompting รวมคำถามสั้นๆ ได้

---

## Phase 2: Execute — follow ba-requirements-prompt.md § LAYER 3

ทำตาม **4-phase Discovery process** ที่ prompt template กำหนด — ห้ามข้าม step:

```
Phase 1: DISCOVER
  ├── 1.1 Read input docs + notebooks (ทำใน Phase 0 แล้ว)
  ├── 1.2 Identify actors (feed เข้า user stories — ไม่มี separate stakeholder doc)
  ├── 1.3 Map current state (As-Is) ถ้ามี
  └── 1.4 Define scope boundaries (In-Scope / Out-of-Scope)

Phase 2: ANALYZE
  ├── 2.1 Extract functional requirements → user stories
  ├── 2.2 Define NFRs (ต้องมี measurable targets)
  ├── 2.3 Identify business rules + validation logic
  ├── 2.4 Map user flows + business processes
  └── 2.5 Identify edge cases, exceptions, failure scenarios

Phase 3: STRUCTURE
  ├── 3.1 Prioritize ทุก requirement (MoSCoW)
  ├── 3.2 เขียน acceptance criteria ทุก user story (Given/When/Then)
  ├── 3.3 Build process flow diagrams (Mermaid)
  └── 3.4 Compile assumptions + open questions

Phase 4: PACKAGE
  ├── 4.1 Assemble 5 BA deliverables (01-05)
  ├── 4.2 Distribute open questions/risks ตาม domain (FR→02, NFR→03, rule→04, flow→05)
  └── 4.3 Audience self-check (PM/Architect/Sponsor readability)
```

ทุก decision / clarification ที่ต้องการให้ user ตอบ → **Flipped Interaction** (ทีละข้อ, acknowledge, ปรับคำถามถัดไป). ห้ามเดา. ถ้า user บอก *"proceed with what you have"* → switch assumption mode, mark ทุก gap ⚠️ + เก็บใน open questions ของ relevant doc ตาม domain (FR→02, NFR→03, rule→04, flow→05; v1.2)

---

## Phase 3: Quality Gate (ก่อน write ไฟล์ — blocking)

Self-check ตาม `ba-requirements-prompt.md` § READABILITY CONTRACT + § GUARDRAILS. ถ้าข้อใดข้อหนึ่งล้มเหลว → กลับ Phase 2 step ที่เกี่ยวข้อง อย่า write file:

### 3.1 Readability Contract (4 ข้อบังคับ ทุก doc 01–05; v1.2)

- [ ] **TL;DR** ที่หัวเอกสาร 2–3 บรรทัด ภาษาชาวบ้าน — ตอบ 2 คำถาม: ปัญหาแก้ให้ใคร + เอกสารนี้ตอบอะไร
- [ ] **`Why:` line** ต่อทุก requirement / user story / business rule / NFR — อธิบาย "ถ้าไม่มีข้อนี้ ธุรกิจเจ็บตรงไหน"
- [ ] **Glossary** ใน `01-project-brief.md § Glossary` — ทุก domain term + acronym (SKU, AR, OEM, cut-off D-1, ฯลฯ) ที่ junior dev / PM ใหม่อาจงง → define
- [ ] **Audience self-check** — PM ใหม่ / Architect ที่ไม่อยู่ meeting / Sponsor อ่านแล้ว sign-off ได้?

### 3.2 Language Rule (LANGUAGE RULE — MANDATORY)

- [ ] **TL;DR ทุก doc:** ไทย ≥ 80% words + English tech terms (bilingual code-switch)
- [ ] **ทุก H2/H3 with content:** มี Thai opener 1–2 ประโยคก่อน table/list/Mermaid
- [ ] **ทุก user story / business rule / NFR:** Thai `Why:` rationale required
- [ ] **Prose Thai coverage ≥ 40%** ของ word count ต่อ doc (ไม่รวม tables/code/Mermaid/identifiers)
- [ ] **ห้ามแปล** actor/entity/file path เป็นไทย — `Back-Office Admin`, ไม่ใช่ "ผู้ดูแลหลังบ้าน"

### 3.3 Content Guardrails

- [ ] ทุก user story format: *"As a [actor], I want [goal] so that [benefit]"*
- [ ] ทุก acceptance criteria format: *Given / When / Then* (keywords อยู่ภาษาอังกฤษ, narrative ภาษาไทย)
- [ ] ทุก requirement มี MoSCoW priority (Must / Should / Could / Won't)
- [ ] **No tech-stack / architecture / framework** mentions (BA = WHAT, ไม่ใช่ HOW; tech decisions เป็นของ Architect ใน Phase 1B)
- [ ] **In-Scope / Out-of-Scope** boundary ระบุชัดใน `01-project-brief.md`
- [ ] Assumptions mark ⚠️ + ใส่ใน relevant doc ตาม domain (FR→02, NFR→03, rule→04, flow→05) ใน Open Questions section
- [ ] NFRs quantified (เช่น `< 200ms p95`, `99.9% uptime` — ไม่ใช่ *"เร็ว"* / *"เสถียร"*)
- [ ] Mermaid diagram ≥ 1 ใน `05-user-flows.md` (flowchart หรือ sequenceDiagram)
- [ ] **ไม่มี technical hints ใน BA doc ไหนเลย** — Architect owns tech decisions; BA raise เฉพาะ open questions ใน relevant doc 02-05 ตาม domain

ถ้ามี ❌ → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 → ห้าม write file จนกว่าจะ ✅ ครบทุกข้อ

---

## Phase 4: Write & Handoff

### 4.1 Write the 5 Deliverables (v1.2: 06-handoff dropped)

เขียนทั้ง 5 ไฟล์ใน `docs/ba/` ตาม schema ใน prompt template § LAYER 3 → Output Package:

| # | File | Key Artifacts |
|---|------|---------------|
| 01 | `01-project-brief.md` | elevator pitch, success KPIs, In/Out scope, **Glossary** |
| 02 | `02-functional-requirements.md` | user stories grouped by epic, MoSCoW table, traceability to goals |
| 03 | `03-non-functional-requirements.md` | measurable NFR table (perf / security / availability / usability) |
| 04 | `04-business-rules.md` | decision tables, validation logic, state machines (ถ้ามี) |
| 05 | `05-user-flows.md` | Mermaid flowchart / sequenceDiagram per flow (happy + alternative + error) |

**Additional artifacts (ถ้าใช้):**
- `docs/diagrams/` — process flow / user journey Mermaid (referenced from 05)
- `docs/ba/sign-off.md` — stakeholder sign-off tracker (ถ้าโปรเจคต้องการ)

### 4.2 Seed Project State (REQUIRED — ตาม prompt § Final Step)

1. ถ้า `docs/state/overview.md` **ยังไม่มี** → สร้างใหม่ด้วย template ใน prompt template § Final Step (Phase Status table — Design (BA) / SD / UX / TD / Design QA / Impl / Code Review / Red Team)
2. ถ้า **มีอยู่แล้ว** → update **เฉพาะแถว `Design (BA)`** เป็น `✅ Complete` + วันที่วันนี้ + notes (เช่น *"5 docs in `docs/ba/` (v1.2: 06-handoff dropped), MoSCoW: M=N S=N C=N W=N, N open questions distributed across 02-05 for SD"*)
3. **ห้ามแตะแถวอื่น** — phase อื่น update ด้วยตัวเอง

### 4.3 HALT — Present Summary to User

แสดงสรุปเป็นภาษาไทย:

- จำนวน user stories แยก MoSCoW (Must / Should / Could / Won't)
- NFRs สำคัญ + targets (เช่น *"API p95 < 200ms, 99.9% uptime, GDPR-compliant data retention 90 วัน"*)
- จำนวน business rules + edge cases ที่ระบุ
- Open questions / assumptions (⚠️ — ให้ user correct ก่อน SD phase)
- Mermaid flow count ใน `05-user-flows.md`
- Path ของไฟล์ที่สร้างทั้งหมด
- **Next command suggestions:**
  - `/ba-review all` — รัน Design QA (adversarial review) ก่อน lock BA
  - `/sd` — ข้าม QA ไป System Design ทันที (ใช้เฉพาะถ้า BA ผ่านสายตามนุษย์แล้ว)

⏸️ **รอ user review + approve ก่อน mark phase complete**

ถ้า user request edits → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 quality gate → re-present

---

## Escape Hatches

| สถานการณ์ | Action |
|-----------|--------|
| `project-overview.md` เป็น placeholder ล้วน | HALT + ขอให้ user กรอก หรือ confirm Flipped Interaction mode (อย่าเดา project facts) |
| Stakeholder input ขัดแย้งกัน | document ทั้ง 2 ข้าง ใน relevant doc § Open Questions ตาม domain (FR→02, NFR→03, rule→04, flow→05; v1.2), อย่าแอบเลือกข้างเดียว |
| Scope drifting ระหว่างสัมภาษณ์ | ย้าย speculative items เข้า `01 § Out-of-Scope` (Won't Have) พร้อม rationale แทนที่จะ silently dropเ |
| User บอก *"skip questions, just write"* | switch assumption mode, mark ทุก gap ⚠️, highlight ใน Open Questions section ของ relevant doc 02-05 prominently |
| NotebookLM MCP fail ซ้ำหลายครั้ง | notify user, proceed without it (อย่า block — input docs น่าจะมีข้อมูลพอ) |
| Realize ระหว่างทำว่า business goal ยังไม่ชัด | STOP + แนะนำ user ใช้ `/ideate` ก่อน (Phase 0) — อย่าฝืนเขียน BA จาก vague goal |
