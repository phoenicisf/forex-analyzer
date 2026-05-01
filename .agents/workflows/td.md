---
description: Run Technical Design → produce 3 TD docs in docs/technical-design/02,03,04 (Phase 1D — wraps technical-design-master-prompt.md so the agent gets full context every time)
---

# Workflow: Technical Design (Phase 1D)

> **Output:** `docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` (3 docs — SD-as-Master consolidation; numbering 02/03/04 preserved intentionally) + update `docs/state/overview.md`
> **Phase:** Phase 1 DESIGN → Step 1D
> **Why a workflow (not just a prompt):** copy-paste workflows ลืม onboarding บ่อย — workflow นี้ pin ลำดับ "อ่าน prompt template → อ่าน SD/UX/ADR/api-specs → 5-step Architect-to-Engineer process → quality gate → write" ให้ agent ทำครบทุกครั้ง

**Input:** `{{input}}` — optional focus hint (e.g. *"focus on payment-service backend"*, *"frontend only — no DB changes"*); leave empty to follow SD + UX deliverables verbatim.

---

## 🔒 TD Scope Contract Reminder (SD-as-Master Consolidation)

> TD ผลิต **3 docs เท่านั้น** (02/03/04). Numbering gaps (01/05/06/07/08) preserved intentionally — content moved to authoritative sources

| TD ทำได้ (class/schema/component detail) | TD ทำไม่ได้ (เก็บที่อื่น) |
|--------------------------------------------|----------------------------|
| `02-backend-design.md` — class/module structure, DTOs, CQRS handlers, repository pattern, DI map, code skeletons inline | ❌ **TD-01 API contracts** → `docs/api-specs/*.yaml` (SD-owned, full OpenAPI) |
| `03-frontend-design.md` — component tree, state management, routing config, data fetching | ❌ **TD-05 Pattern decisions** → `docs/adr/` (decision); skeleton inline ใน TD-02 |
| `04-database-design.md` — column-level schema, constraints, indexes, migrations, seed data | ❌ **TD-06 Sequence diagrams** → flow-level ใน SD `04-data-flow.md`; method-level optional `## Flow Appendix` ใน TD-02 |
| Optional `## Flow Appendix` ใน 02 สำหรับ non-obvious method-level sequences | ❌ **TD-07 Test strategy** → `docs/qa/01-test-execution-plan.md` (QA-owned) |
| Cross-domain note ที่เกิดระหว่าง TD (เช่น schema↔API mismatch) inline ใน doc ที่ใช้ | ❌ **TD-08 Handoff** → Impl Planner อ่าน SD-07/08 โดยตรง |

**Test ก่อนเขียน:** ถ้าเนื้อหาเป็น API field-level validation → ไป YAML; pattern decision → ไป ADR; flow sequence → ไป SD-04; test scenario → ไป QA-01. **TD เก็บเฉพาะ implementation skeleton (class/component/schema)**

---

## Phase 0: Onboarding (อ่านไฟล์เหล่านี้ทันที)

อ่าน batch นี้ในรอบเดียว (parallel reads) ก่อนทำอย่างอื่น — หาก skip ขั้นนี้ workflow จะ produce shallow output:

1. `CLAUDE.md` — project rules, **tech-stack baseline** (ถ้า project รัน `/project-init` แล้ว tech stack จะ specific; ถ้ายังเป็น template → ใช้ตัวอย่างใน sample stack table แต่ flag ว่ารอ TD lock)
2. **`.agents/prompt-templates/technical-design-master-prompt.md`** — **AUTHORITATIVE persona + 5-step process + Language Rule + Scope Contract + Guardrails + 3-doc output schema**. ทุก rule ใน file นี้ binding — workflow ฉบับนี้เป็น orchestration wrapper, ห้าม restate หรือ paraphrase
3. `.agents/skills/_core-behaviors.md` — 6 behavioral foundations
4. **SD deliverables (primary input)** — อ่านทั้ง 6 ไฟล์ใน `docs/design-docs/` (v1.2: gaps ที่ 01, 06 — merged into 02):
   - `02-high-level-architecture.md` — **(Top)** Requirements Traceability Matrix (ใช้ตรวจ TD coverage). **(Body)** service boundaries, communication, components ที่ TD ต้องเข้าไป design internals. **(Bottom)** ADR Digest (link ไปหา ADR เต็มใน `docs/adr/`)
   - `03-deep-dive.md` — critical challenges, internals (high-level)
   - `04-data-flow.md` — flow-level sequences (TD's Flow Appendix รับช่วงเฉพาะที่ insufficient)
   - `05-security.md` — AuthN/AuthZ, threat model
   - `07-future-evolution.md` — scaling triggers, Evolution Sequence (informs TD migration design)
   - `08-product-breakdown.md` — work inventory (informs TD scope; **อย่า re-package** — Impl Planner อ่านโดยตรง)
5. **UX deliverables (frontend input)** — อ่าน `docs/ux/01-05`:
   - `01-design-tokens.md` — colors / typography / spacing → TD-03 styling
   - `02-component-inventory.md` — components / variants / states → TD-03 component tree
   - `03-page-layouts.md` — page wireframes → TD-03 routing + component composition
   - `04-navigation-structure.md` — sitemap, nav labels (TD-03 owns routing implementation)
   - `05-interaction-patterns.md` — forms, loading, error states
6. **BA deliverables (cross-reference)** — อ่าน `docs/ba/02-functional-requirements.md`, `03-non-functional-requirements.md`, `04-business-rules.md` (entity model derive จากที่นี่ + user stories), `05-user-flows.md`
7. **ADRs** — อ่านทุกไฟล์ใน `docs/adr/` (constraints + pattern decisions ที่ TD ต้อง honor)
8. **API specs** — อ่านทุกไฟล์ใน `docs/api-specs/*.yaml` (full OpenAPI = source of truth สำหรับ API field-level; TD-02 references YAML, ไม่ duplicate)
9. **Tech stack rules** — อ่านทุกไฟล์ใน `.claude/rules/*.md` (naming conventions, project structure, patterns) — ถ้ายังไม่มี → flag user ว่าต้อง `/project-init` หลัง TD approved (Phase 2.5)
10. `docs/foundation-input-sources/project-overview.md` — business constraints
11. `docs/technical-design/`, `docs/qa/01-test-execution-plan.md` — ตรวจว่ามีไฟล์อยู่แล้วไหม (informs Phase 1.2 mode detection); skip silently ถ้าไม่มี
12. `docs/state/overview.md` — module status (OPTIONAL — skip silently if not found)

Once read (or skipped) → proceed to Phase 1.

---

## Phase 1: Preconditions & Mode Detection

### 1.1 Preconditions (Hard-Fail)

| Check | ผ่าน | ไม่ผ่าน |
|-------|------|---------|
| `docs/design-docs/02–08` ครบ 6 ไฟล์ (gaps ที่ 01, 06 — v1.2) | proceed | **HALT** — แนะนำ `/sd` ก่อน (SD เป็น primary input ของ TD) |
| SD Design QA approved (no CRITICAL/HIGH ค้างใน SD claim-review-and-rebuttal/ ล่าสุด) | proceed | ⚠️ **WARN**: *"พบ findings ค้างใน SD claim-review รอบล่าสุด ([N] CRITICAL, [N] HIGH) — แนะนำ `/sd-rebuttal` ก่อน เพื่อให้ architecture stable. proceed without SD QA approval? (y/n)"* รอ confirm |
| `docs/ux/01–05` ครบ 5 ไฟล์ (project มี frontend) | proceed | ⚠️ **WARN**: *"UX docs ไม่ครบ — TD-03 frontend design จะ derive จาก BA user flows + assumptions ⚠️. แนะนำ `/ux-design auto` ก่อน. proceed? (y/n)"* — ถ้า project เป็น API-only ตอบ y และ mark TD-03 เป็น "N/A — API-only" |
| `docs/adr/` มี ≥ 1 ADR | proceed | **HALT** — SD ที่ไม่มี ADR เลย = incomplete; กลับไป `/sd-rebuttal` |
| `docs/api-specs/*.yaml` มี ≥ 1 (project มี API) | proceed | **HALT** — TD-02 references YAML; ถ้าไม่มี YAML → กลับไป `/sd` หรือ `/amend sd` เพื่อ produce API specs |
| `services/` ว่าง หรือ `docs/state/impl-plan.md` ยังไม่มี (TD ยังไม่ผ่าน implementation) | proceed | ⚠️ warn: *"พบ impl-plan / services code อยู่แล้ว — re-do TD จะ invalidate downstream. ต้องการ `/amend td "<desc>"` หรือ `/backtrack td` แทน?"* |

### 1.2 Mode Detection

นับจำนวนไฟล์ที่มีจริงใน `docs/technical-design/` (เฉพาะ 02/03/04):

| ไฟล์ที่มีอยู่ | Mode | พฤติกรรม |
|---------------|------|---------|
| 0 | **Fresh** | รัน 5-step process เต็ม → write ครบ 3 docs |
| 1–2 (partial) | **Resume** | ถาม user 3 options: (a) เติมเฉพาะไฟล์ที่ขาด keep ของเดิม (b) restart fresh พร้อม backup เดิมเป็น `*.bak-<ISO-8601>` (c) abort |
| 3 (ครบ) | **Refine / amend hint** | ถาม user: *"TD docs ครบ 3 ไฟล์แล้ว — ต้องการ refine ไฟล์ไหน หรือใช้ `/amend td "<desc>"` (จะ cascade check API↔DB↔Frontend)?"* |

### 1.3 Flipped Interaction Decision (Layer 2 § Flipped Interaction ของ prompt template)

ประเมินความครบถ้วนของ inputs (SD + UX + ADRs + api-specs):

| Evidence | Action |
|----------|--------|
| SD มี gap ใหญ่ที่ block detailed design (เช่น service boundary ไม่ชัด, ADR ไม่มีสำหรับ pattern หลัก, api-specs ไม่มี error schemas) | **Full Flipped Interaction** — 3 steps ตาม prompt Layer 2 |
| Multiple valid patterns possible และไม่มี ADR ตัดสิน (เช่น Saga vs 2PC, sync vs async, REST vs GraphQL — แต่ ADR ไม่ระบุ) | **Meta-Prompting** — ถาม user preference เจาะจง (1–3 ข้อ ขึ้นต้นด้วย *"ก่อนเริ่ม design — ขอข้อมูลเพิ่มเติม [N] ข้อ:"*) |
| SD + UX + ADR ครบทุกประเด็น | **Skip** — proceed direct design ใน Phase 2 |

**Question priority order:** decisions ที่กระทบหลาย doc ก่อน (เช่น CQRS choice กระทบทั้ง 02 + 03) → narrow detail (DTO field naming) ทีหลัง

---

## Phase 2: Execute — follow technical-design-master-prompt.md § LAYER 3

ทำตาม **5-step Architect-to-Engineer process** ที่ prompt template กำหนด — ห้ามข้าม step. Phase 2/6/7/8 ของ prompt **REMOVED** (SD-as-Master); ทำเฉพาะ 1/3/4/5:

```
Step 1: ABSORB
  ├── 1.1 อ่าน SD deliverables (02-08; v1.2: gaps 01/06 — merged into 02) — เริ่มที่ 02 (architecture incl. Requirements Traceability + ADR Digest) + 08 (work breakdown)
  ├── 1.2 อ่าน UX deliverables (01-05) — สำหรับ frontend component tree
  ├── 1.3 อ่าน ADRs — constraints บน design decisions
  ├── 1.4 อ่าน .claude/rules/ — tech stack conventions
  └── 1.5 Extract: service list, component boundaries, data models, user flows, tech choices
        ⚠️ DO NOT restate SD/UX/BA content — TD เก็บ implementation detail เท่านั้น

(Step 2 REMOVED — API contracts authoritative ใน docs/api-specs/*.yaml)

Step 3: BACKEND DESIGN → 02-backend-design.md
  ├── 3.1 Design class/module structure ตาม .claude/rules/ conventions
  ├── 3.2 Service interfaces + method signatures + return types
  ├── 3.3 DTOs (Request/Response/Internal) per feature
  ├── 3.4 ถ้า CQRS → Command + Query handlers
  ├── 3.5 Repository interfaces + data access patterns
  ├── 3.6 DI registration map
  ├── 3.7 Mermaid classDiagram per service
  ├── 3.8 Pattern code skeletons inline (Repository, CQRS handlers, ฯลฯ) — decision อยู่ใน ADR, skeleton อยู่ที่นี่
  └── 3.9 (OPTIONAL) ## Flow Appendix — method-level sequences เฉพาะ flows ที่ SD-04 ไม่ครอบคลุม. ข้ามถ้าเป็น CRUD

Step 4: FRONTEND DESIGN → 03-frontend-design.md
  ├── 4.1 Map UX page layouts → component tree
  ├── 4.2 Component props/interfaces
  ├── 4.3 State management (local vs global vs server state)
  ├── 4.4 Routing structure ตาม UX navigation (TD-03 authoritative for routing)
  ├── 4.5 Data fetching hooks (SWR / React Query / framework idiom)
  ├── 4.6 Error boundary hierarchy
  └── 4.7 Mermaid component hierarchy diagram

Step 5: DATABASE DESIGN → 04-database-design.md
  ├── 5.1 Expand SD data model → column-level (types, lengths, nullability, defaults)
  ├── 5.2 Constraints (PK, FK, unique, check)
  ├── 5.3 Index strategy ที่ match query patterns จาก api-specs
  ├── 5.4 Migration plan (order, backward compat, rollback)
  ├── 5.5 Seed data สำหรับ dev/test
  ├── 5.6 Data access patterns (which service queries which tables)
  └── 5.7 Mermaid erDiagram + DDL snippets

(Steps 6/7/8 REMOVED — pattern decisions → ADR; test strategy → QA-01; handoff → Impl Planner reads SD)
```

ทุก decision ใช้ **Decision Strategy** ของ prompt template Layer 2: Check ADRs first → Check `.claude/rules/` → enumerate alternatives (≥2) → justify with specifics. ห้ามใช้ *"best practice"* ลอยๆ

---

## Phase 3: Quality Gate (ก่อน write ไฟล์ — blocking)

Self-check ตาม `technical-design-master-prompt.md` § READABILITY CONTRACT + § GUARDRAILS + § Anti-Patterns. ถ้าข้อใดข้อหนึ่งล้มเหลว → กลับ Phase 2 step ที่เกี่ยวข้อง อย่า write file:

### 3.1 Readability Contract (5 ข้อบังคับ ทุก doc 02/03/04)

- [ ] **TL;DR** ที่หัวเอกสาร 3-5 บรรทัด — ตอบ 3 คำถาม: doc นี้ออกแบบ component อะไร + key pattern choice หลัก + dependency / consumer ที่ reader ต้องรู้
- [ ] **Pattern decision rationale** ทุก pattern (Repository, CQRS, Strangler, error-boundary, ฯลฯ) — อธิบาย *"เหมาะกับเคสเรา เพราะ..."* + อ้าง ADR ที่บันทึก decision
- [ ] **Class / component / table responsibility** — single-sentence Thai opener ก่อน code/Mermaid block
- [ ] **Glossary / first-use definition** — pattern + framework idiom + project-specific component (เช่น MediatR pipeline behavior, React Server Component, partial index)
- [ ] **Mermaid diagram narrative** — Thai narrative ก่อน + หลัง diagram (อธิบายว่า class/component/ER เล่าอะไร)

### 3.2 Language Rule (LANGUAGE RULE — MANDATORY)

- [ ] **TL;DR ทุก doc:** ไทย ≥ 80% words + English tech terms (bilingual code-switch)
- [ ] **ทุก H2/H3 with content:** Thai opener 1-2 ประโยคก่อน code/class/diagram
- [ ] **ทุก pattern choice / DTO / repository decision:** Thai rationale required
- [ ] **Prose Thai coverage ≥ 40%** ของ word count ต่อ doc (ไม่รวม code/tables/diagrams/identifiers)
- [ ] **ห้ามแปล** class/method/field name เป็นไทย — `IOrderRepository`, ไม่ใช่ "อินเทอร์เฟซคลังคำสั่งซื้อ"

### 3.3 Content Guardrails

- [ ] No "TBD" — resolve ทุกจุด หรือ Flipped Interaction ถาม user
- [ ] Every API field validation → ยังอยู่ใน `docs/api-specs/*.yaml` (TD references, ไม่ duplicate)
- [ ] Every class/module = single responsibility (อธิบายได้ใน 1 ประโยค)
- [ ] Every component (TD-03) trace กลับไปหา UX deliverable ได้
- [ ] Every database table (TD-04) trace กลับไปหา BA entity ได้
- [ ] Code skeletons = interface/class signature เท่านั้น (ไม่ใช่ full implementation)
- [ ] Mermaid diagram ≥ 1 per doc

### 3.4 Scope Contract Compliance (SD-as-Master — CRITICAL)

- [ ] **No TD-01/05/06/07/08 created** — content ที่จะใส่ใน 01 → ตรวจว่า api-specs มีครบไหม (ถ้าไม่มี → กลับ `/amend sd` หรือ `/sd-rebuttal`); 05 → ตรวจ ADR; 06 → ตรวจ SD-04 หรือ inline `## Flow Appendix` ใน 02; 07 → ส่งไป QA-01; 08 → ไม่ต้องทำ
- [ ] **TD-02 §3.8 pattern code skeletons** linked ไปหา ADR ที่บันทึก pattern decision (ไม่ duplicate decision text)
- [ ] **TD-03 routing config** เป็น authoritative — UX-04 navigation labels อ้างอิงเฉยๆ
- [ ] **TD-04 schema** column names match API field names ใน api-specs (หรือ document mapping ไว้ใน TD-02 ถ้า diverge)

### 3.5 Cross-Domain Consistency (CRITICAL)

- [ ] **API ↔ DB:** ทุก field ใน `api-specs/*.yaml` response ต้อง trace ไปได้ที่ column ใน TD-04 (หรือ derived field พร้อม mapping)
- [ ] **DB ↔ Backend:** ทุก table ใน TD-04 มี repository / DAO interface ใน TD-02
- [ ] **Backend ↔ Frontend:** ทุก endpoint ใน api-specs ที่ frontend consume → มี data fetching hook / API client method ใน TD-03
- [ ] **UX ↔ Frontend:** ทุก page ใน UX-03 → มี component + route ใน TD-03

### 3.6 Architecture Alignment

- [ ] **Respect SD/ADR** — ห้าม override architecture choice; ถ้าจำเป็นต้อง diverge → escalate ผ่าน `/backtrack sd`
- [ ] **Follow `.claude/rules/`** — naming conventions (PascalCase / camelCase / snake_case ตามภาษา), project structure, patterns
- [ ] **SD→TD traceability** — ทุก component ใน TD trace กลับไปหา service/module ใน SD `02-high-level-architecture.md`

### 3.7 Audience Self-Check

- [ ] BA / PM อ่านแล้วเห็นไหมว่า requirement ข้อไหน → component ตัวไหน?
- [ ] Senior dev รับไปเขียน code ได้ไหม โดยไม่ต้องตัดสินใจ design เอง?
- [ ] Junior dev อ่าน TD-02 เข้าใจ class structure + DI flow ได้ไหม?
- [ ] DBA อ่าน TD-04 รัน migration ได้ไหม โดยไม่ต้องเดา constraints?

ถ้ามี ❌ → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 → ห้าม write file จนกว่าจะ ✅ ครบทุกข้อ

---

## Phase 4: Write & Handoff

### 4.1 Write the 3 Deliverables

เขียนทั้ง 3 ไฟล์ใน `docs/technical-design/` ตาม schema ใน prompt template § Output Format — เขียน **sequential** (doc ถัดไปอาจอ้าง doc ก่อนหน้า):

| # | File | Key Artifacts |
|---|------|---------------|
| 02 | `02-backend-design.md` | Mermaid classDiagram per service, DTOs, CQRS handlers, repository interfaces, DI map, pattern code skeletons (linked to ADRs), optional `## Flow Appendix` |
| 03 | `03-frontend-design.md` | Mermaid component hierarchy, route table, props/state, data fetching hooks, error boundaries |
| 04 | `04-database-design.md` | Mermaid erDiagram, DDL snippets, migration order, seed data, access patterns |

**Numbering 02/03/04 preserved** — gaps (01/05/06/07/08) intentional; ห้ามเลื่อนเลขเป็น 01/02/03

### 4.2 Update Authoritative Sources (ถ้าจำเป็น)

- ถ้าเจอ API field ที่ขาดใน YAML → **อย่าเขียนใน TD**; กลับไปเพิ่มใน `docs/api-specs/*.yaml` หรือ `/amend sd` (SD owns API specs)
- ถ้าเจอ pattern decision ใหม่ที่ยังไม่มี ADR → สร้าง ADR ใหม่ใน `docs/adr/NNN-title.md` (ใช้ Title → Status → Context → Options → Decision → Consequences → Revisit-when format)
- ถ้าเจอ test scenario สำคัญ → flag user ว่าต้อง add ใน `docs/qa/01-test-execution-plan.md` (อย่าเขียนใน TD)
- ถ้าเจอ method-level flow ที่ SD-04 ไม่ครอบคลุม → เพิ่ม `## Flow Appendix` ใน TD-02 (optional)

### 4.3 Update Project State (REQUIRED)

1. ถ้า `docs/state/overview.md` ยังไม่มี → สร้างใหม่ด้วย template (BA phase ควรสร้างไว้แล้ว — ถ้าไม่มี ใช้ template จาก BA prompt § Final Step)
2. Update **เฉพาะแถว `Design (TD)`** เป็น `✅ Complete` + วันที่วันนี้ + notes (เช่น *"3 docs in `docs/technical-design/` (02/03/04 — SD-as-Master); N new ADRs created for pattern decisions; cross-domain check ✅ API↔DB↔Frontend↔UX consistent"*)
3. **ห้ามแตะแถวอื่น** — phase อื่น update ด้วยตัวเอง

### 4.4 HALT — Present Summary to User

แสดงสรุปเป็นภาษาไทย:

- **Backend (TD-02):** count ของ services / classes / interfaces / DTOs; pattern code skeletons ที่ใช้ (Repository / CQRS / ฯลฯ); ADRs referenced; Flow Appendix? (yes / skipped — CRUD only)
- **Frontend (TD-03):** count ของ pages / components / routes; state management strategy; data fetching pattern (SWR / React Query / fetch directly); error boundary tier
- **Database (TD-04):** count ของ tables / columns / indexes; migration order; seed data scope
- **New ADRs created** (ถ้ามี) — list ชื่อไฟล์
- **Cross-domain consistency:** ✅ API↔DB column match / ⚠️ N mismatches (พร้อม mapping ที่ document ไว้)
- **Open assumptions** ⚠️ — รายการที่ user ต้อง confirm (ปกติ derive จาก SD gaps)
- **Path** ของไฟล์ที่สร้างทั้งหมด
- **Next command suggestions:**
  - `/td-review all` — รัน Design QA (cross-domain consistency + design pattern review) ก่อน lock TD
  - `/project-init` — bootstrap CLAUDE.md + .claude/rules/ จาก approved TD (Phase 2.5 — ใช้เฉพาะหลัง TD ผ่าน QA)

⏸️ **รอ user review + approve ก่อน mark phase complete**

ถ้า user request edits → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 quality gate → re-present

---

## Escape Hatches

| สถานการณ์ | Action |
|-----------|--------|
| SD docs ขาดบางไฟล์ (เช่น ไม่มี ADR สำหรับ pattern หลัก หรือ api-specs ไม่ครบ field validation) | HALT + แนะนำ `/amend sd "<desc>"` หรือ `/sd-rebuttal` ก่อน; อย่า design จาก partial SD |
| UX docs ไม่มี (project มี frontend) | WARN — แนะนำ `/ux-design auto` ก่อน; ถ้า user ยืนยัน proceed → derive frontend จาก BA user flows + api-specs, mark assumptions ⚠️ + แนะนำ `/amend td` หลัง UX สร้างเสร็จ |
| Project เป็น API-only / no frontend | mark TD-03 เป็น *"N/A — API-only project"* พร้อม justification + ระบุว่า API consumer docs อยู่ใน `docs/api-specs/*.yaml` |
| Project เป็น stateless / no DB | mark TD-04 เป็น *"N/A — stateless service"* พร้อม justification |
| ADR conflict (พบว่า ADR เก่ากับ design ใหม่ขัดกัน) | HALT — flag user แก้ก่อน proceed; อย่าแอบ override existing ADR |
| Multiple valid patterns (เช่น Repository vs Active Record, Saga vs 2PC) — ไม่มี ADR ตัดสิน | Flipped Interaction ถาม user; ถ้า user ไม่อยู่ → state เป็น assumption ⚠️ + create ADR ใหม่ใน Phase 4.2 |
| Realize ระหว่างทำว่า SD architecture ขัดกับ tech-stack rules ใน `.claude/rules/` | STOP + escalate ผ่าน `/backtrack sd` แทนที่จะ silent override |
| User พยายามใส่ test cases / API field validation / pattern decision rationale ลงใน TD | ปฏิเสธ + อธิบาย Scope Contract; route ไป QA-01 / api-specs YAML / ADR ตามลำดับ |
