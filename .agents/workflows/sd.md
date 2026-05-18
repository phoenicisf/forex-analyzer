---
description: Run System Design → produce 6 design docs in docs/design-docs/02-08 (gaps 01/06 merged into 02) + ADRs + API specs (Phase 1B — wraps system-design-master-prompt.md so the agent gets full context every time)
---

# Workflow: System Design (Phase 1B)

> **Output:** `docs/design-docs/02-high-level-architecture.md` (incl. Requirements Traceability + ADR Digest sections) … `08-product-breakdown.md` (6 markdown files; gaps ที่ 01, 06 — v1.2) + `docs/adr/NNN-*.md` + `docs/api-specs/*.yaml` + update `docs/state/overview.md`
> **Phase:** Phase 1 DESIGN → Step 1B
> **Why a workflow (not just a prompt):** copy-paste workflows ลืม onboarding บ่อย — workflow นี้ pin ลำดับ "อ่าน prompt template → อ่าน BA deliverables → 6-step Architect process → quality gate → write" ให้ agent ทำครบทุกครั้ง

**Input:** `{{input}}` — optional focus hint (e.g. *"focus on payment flow"* / *"skip Evolution Sequence — greenfield monolith"* / *"emphasize observability"*); leave empty to follow BA deliverables verbatim.

---

## 🔒 Phase Contract Reminder (Option C — Hints Allowed, Schedule Not)

> SD อธิบาย architecture (what + where + why) และอาจ suggest ordering ได้ — แต่ **ไม่ commit delivery schedule**

| ✅ SD ทำได้ (architectural) | ❌ SD ทำไม่ได้ (schedule leakage) |
|------------------------------|------------------------------------|
| Evolution Sequence ใน `07` (hard, ADR-backed: *"E1 must precede E3 because ADR-005 unified JWT"*) | Sprint numbers (`Sprint 1`) |
| Phase Hints ใน `08` (soft P1/P2/P3/P4 พร้อม architectural rationale) | Calendar dates (`Q2 2026`, `by March 15`) |
| Per-task metadata (risk, must_precede, unlocks, arch_rationale) | Team capacity (`2 devs × 2 weeks`) |
| References ไปหา ADR | Release milestones, go-live commitments |

**Test ก่อนเขียน phase/sequencing content:** คำนี้ตอบ **when**? → ❌ ลบ. ตอบ **why**? → ✅ OK. Vocabulary canonical อยู่ที่ `CLAUDE.md § Glossary`

---

## Phase 0: Onboarding (อ่านไฟล์เหล่านี้ทันที)

อ่าน batch นี้ในรอบเดียว (parallel reads) ก่อนทำอย่างอื่น — หาก skip ขั้นนี้ workflow จะ produce shallow output:

1. `CLAUDE.md` — project rules, tech-stack baseline (ถ้ามี), **Option C glossary** (Evolution Sequence / Phase Hint / Schedule Leakage)
2. **`.andm/prompt-templates/system-design-master-prompt.md`** — **AUTHORITATIVE persona + 6-step process + Language Rule + Readability Contract + Phase Contract + Guardrails + 6-doc output schema (v1.2: gaps 01/06 — merged into 02)**. ทุก rule ใน file นี้ binding — workflow ฉบับนี้เป็น orchestration wrapper, ห้าม restate หรือ paraphrase
3. `.agents/skills/_core-behaviors.md` — 6 behavioral foundations
4. **BA deliverables (primary input)** — อ่านทั้ง 5 ไฟล์ใน `docs/ba/` (v1.2: 06-handoff dropped):
   - `01-project-brief.md` — business context, goals, scope, glossary
   - `02-functional-requirements.md` — user stories + acceptance criteria + MoSCoW (actor list อยู่ที่นี่)
   - `03-non-functional-requirements.md` — perf / security / availability targets (drives architectural decisions)
   - `04-business-rules.md` — validation logic, decision tables (entity model derive จากที่นี่ + user stories)
   - `05-user-flows.md` — user journeys (happy + alternative)
   - (v1.2: BA `06-handoff-to-architecture.md` removed — open questions/risks live ใน relevant doc 02-05 ตาม domain)
5. `docs/foundation-input-sources/` — additional context: project-overview, integration-requirements, infrastructure-constraints, existing-system-audit (ถ้ามี); ข้าม placeholder
6. `docs/foundation-input-sources/notebooklm.md` (OPTIONAL) — notebook registry; ถ้ามี ให้พร้อม query ผ่าน NotebookLM MCP
7. `docs/design-docs/`, `docs/adr/`, `docs/api-specs/` — ตรวจว่ามีไฟล์อยู่แล้วไหม (informs Phase 1.2 mode detection); skip silently ถ้าไม่มี
8. `docs/state/overview.md` — module status (OPTIONAL — skip silently if not found)

Once read (or skipped) → proceed to Phase 1.

---

## Phase 1: Preconditions & Mode Detection

### 1.1 Preconditions (Hard-Fail)

| Check | ผ่าน | ไม่ผ่าน |
|-------|------|---------|
| `docs/ba/01–05` ครบ 5 ไฟล์ (v1.2) | proceed | **HALT** — แนะนำ `/ba` ก่อน (BA เป็น primary input ของ SD) |
| BA Design QA approved (no CRITICAL/HIGH ค้างใน BA claim-review-and-rebuttal/ ล่าสุด) | proceed | ⚠️ **WARN** user: *"พบ findings ค้างใน BA claim-review รอบล่าสุด ([N] CRITICAL, [N] HIGH) — แนะนำให้ `/ba-rebuttal` ก่อน เพื่อให้ requirements stable. proceed without QA approval? (ตอบ y เพื่อยืนยัน)"* รอ confirm |
| `docs/technical-design/` ว่าง (ยังไม่มี TD) | proceed | ⚠️ warn: *"พบ TD docs อยู่แล้ว — re-do SD จะ invalidate TD. ต้องการ `/amend sd "<desc>"` หรือ `/backtrack sd` แทน?"* |

### 1.2 Mode Detection

นับจำนวนไฟล์ที่มีจริงใน `docs/design-docs/` (เฉพาะ 02-08; v1.2: gaps ที่ 01/06 — merged into 02):

| ไฟล์ที่มีอยู่ | Mode | พฤติกรรม |
|---------------|------|---------|
| 0 | **Fresh** | รัน 6-step process เต็ม → write ครบ 6 docs (02-08, gaps 01/06) + ADRs + API specs |
| 1–5 (partial) | **Resume** | ถาม user 3 options: (a) เติมเฉพาะไฟล์ที่ขาด keep ของเดิม (b) restart fresh พร้อม backup เดิมเป็น `*.bak-<ISO-8601>` (c) abort |
| 6 (ครบ) | **Refine / amend hint** | ถาม user: *"SD docs ครบ 6 ไฟล์แล้ว (gaps 01/06 — v1.2) — ต้องการ refine ไฟล์ไหน หรือใช้ `/amend sd "<desc>"` เพื่อ targeted edit?"* |

### 1.3 Flipped Interaction Decision (Layer 2 § Flipped Interaction ของ prompt template)

ประเมินความครบถ้วนของ inputs (BA + foundation-input-sources):

| Evidence | Action |
|----------|--------|
| BA deliverables ขาด key NFR (ไม่มี perf/security/availability targets) หรือ business goal ยัง vague | **Full Flipped Interaction** — 3 steps (Initial Brief → Dynamic Context → Synthesis) ตาม prompt Layer 2 |
| BA ครบประมาณ 80% — ขาด integration / scale / budget context | **Meta-Prompting** — รวม 1–3 คำถามเจาะจง ขึ้นต้นด้วย *"ก่อนเริ่ม design — ขอข้อมูลเพิ่มเติม [N] ข้อ:"* |
| BA + foundation-input-sources ครบทุกประเด็น | **Skip** — proceed direct design ใน Phase 2 |

**Question priority order:** scale targets → consistency requirements → budget/infra constraints → integration constraints → performance SLAs → security/compliance. ถามทีละข้อ — ห้าม dump 20 คำถาม

---

## Phase 2: Execute — follow system-design-master-prompt.md § LAYER 3

ทำตาม **6-step Architect process** ที่ prompt template กำหนด — ห้ามข้าม step:

```
Step 1: UNDERSTAND
  ├── 1.1 Read BA deliverables (01-05; v1.2) — scan open questions ตาม domain (FR→02, NFR→03, rule→04, flow→05)
  │        ⚠️ DO NOT restate BA content — extract traceability deltas เท่านั้น
  ├── 1.2 Build Requirements Traceability Matrix (BA FR-ID → SD section/service) — จะใส่ใน 02 top section
  ├── 1.3 Identify core system pillars (3-5 สิ่งที่ห้ามพัง)
  └── 1.4 List ทุก assumption → mark ⚠️

Step 2: ARCHITECT
  ├── 2.1 เลือก architecture style พร้อม trade-off (≥2 options compared)
  ├── 2.2 Identify services/modules + map components
  ├── 2.3 Design inter-service communication
  ├── 2.4 Design data layer (DB schema, cache strategy)
  └── 2.5 Design infrastructure layer

Step 3: DEEP DIVE
  ├── 3.1 Identify critical technical challenges (scale + system complexity)
  ├── 3.2 แต่ละ challenge: Problem → Approach → Implementation → Failure modes
  └── 3.3 Compare alternatives (Sync/Async, SQL/NoSQL, ฯลฯ)

Step 4: FLOWS
  ├── 4.1 Map major user flows end-to-end
  ├── 4.2 Add timing budgets per step
  ├── 4.3 Define consistency boundaries
  └── 4.4 Handle idempotency

Step 5: HARDEN
  ├── 5.1 Security design (AuthN/AuthZ, encryption, RBAC)
  ├── 5.2 Threat modeling (STRIDE)
  ├── 5.3 Operational risks + mitigation
  └── 5.4 Observability strategy

Step 6: DOCUMENT
  ├── 6.1 Trade-off summary (ADRs — ทุก major decision = 1 ADR)
  ├── 6.2 Future evolution — scaling triggers, migration paths, tech debt, deprecation
  │       + (optional) Evolution Sequence ถ้ามี architectural ordering constraints
  └── 6.3 Work breakdown — epics → stories → tasks พร้อม sizes + dependencies
          + (optional) Phase Hints + per-task metadata ถ้ามี architectural insight จะ suggest ให้ Impl Planner
```

ทุก architecture decision ที่ enumerate alternatives → ใช้ **Decision Strategy** ของ prompt template Layer 2:

```
1. Enumerate options   — อย่างน้อย 2 options
2. Analyze pros/cons   — ใน context ของ "ระบบนี้" (ไม่ใช่ textbook)
3. Choose + justify    — "industry standard" ไม่พอ
4. Define revisit trigger
5. Record as ADR       — major decision → docs/adr/NNN-title.md
```

---

## Phase 3: Quality Gate (ก่อน write ไฟล์ — blocking)

Self-check ตาม `system-design-master-prompt.md` § READABILITY CONTRACT + § GUARDRAILS + § Phase Contract Compliance. ถ้าข้อใดข้อหนึ่งล้มเหลว → กลับ Phase 2 step ที่เกี่ยวข้อง อย่า write file:

### 3.1 Readability Contract (5 ข้อบังคับ ทุก doc 02-08; v1.2: gaps 01/06)

- [ ] **TL;DR** ที่หัวเอกสาร 3–5 บรรทัด — ตอบ 3 คำถาม: ปัญหาที่ออกแบบแก้ + architectural choice หลัก + key trade-off ที่ reader ต้องรู้
- [ ] **`Why:` line** ต่อทุก architectural decision — ระบุ quality attribute / NFR / constraint ที่ขับเคลื่อน (ไม่ใช่แค่ *"we use X"*)
- [ ] **Plain-language explanation** ก่อน technical detail — component / pattern section ขึ้นด้วย 1-sentence *"นี่คือ X ที่ทำ Y"* ก่อน dive schema/config/code
- [ ] **Glossary** ใน `02-high-level-architecture.md § Glossary` — ทุก architecture pattern (Saga, CQRS, strangler fig), acronym (JWT, RBAC, SSE, HPA, PVC), project-specific component → define on first use หรือใน glossary
- [ ] **Mermaid diagram narrative** — ก่อน diagram 1–2 บรรทัดอธิบาย "diagram นี้เล่าอะไร", หลัง diagram 2–3 บรรทัดสรุป key insight

### 3.2 Language Rule (LANGUAGE RULE — MANDATORY)

- [ ] **TL;DR ทุก doc:** ไทย ≥ 80% words + English tech terms (bilingual code-switch)
- [ ] **ทุก H2/H3 with content:** Thai opener 1–2 ประโยคก่อน table/code/diagram
- [ ] **ทุก ADR-referenced decision:** Thai rationale sentence required
- [ ] **Prose Thai coverage ≥ 40%** ของ word count ต่อ doc (ไม่รวม tables/code/diagrams/identifiers)
- [ ] **ห้ามแปล** tech term เป็นไทย — `Redis cache layer`, ไม่ใช่ "ตัวกลางเก็บ cache"

### 3.3 Content Guardrails

- [ ] No shallow answers — ทุก response มี supporting reasoning
- [ ] No generic textbook explanations — specific กับระบบนี้
- [ ] Every decision = reasoning + revisit trigger
- [ ] Every number (pool_size, timeout, rate_limit, TTL) มี formula/derivation
- [ ] No *"configure as needed"* — ระบุ concrete default
- [ ] Mermaid diagram ≥ 1 per architecture doc (02, 03, 04 อย่างน้อย)
- [ ] ADR format ครบ: Title → Status → Supersedes / Superseded-by → Context → Options → Decision → Consequences → Revisit-when

### 3.4 Phase Contract Compliance (Option C — CRITICAL)

- [ ] **No schedule leakage** — grep all 6 docs (02-08, gaps 01/06) for forbidden vocab: *Sprint N*, *Q1/Q2/Q3/Q4 YYYY*, *Week N*, *Month N*, *by [date]*, *N devs × N weeks*, *go-live*, *release N.N*. ถ้าเจอ → **ลบ** ก่อน write
- [ ] **Phase Hints labeled correctly** — ถ้ามี section นี้ใน `08-product-breakdown.md` ต้อง title ว่า **"Phase Hints (Suggested)"** เท่านั้น. ห้าม "Plan", "Assignment", "Schedule", "Roadmap"
- [ ] **Evolution Sequence backed by ADR** — ทุก E step (ใน `07-future-evolution.md`) มี architectural rationale + ADR citation. ใช้ language *"ADR-XXX requires"*, *"cannot test without"*, *"breaks contract if"*. ห้าม *"before Q2"*, *"after MVP launch"*, *"when team has capacity"*
- [ ] **Missing Phase Hints / Evolution Sequence ≠ defect** — skip ได้ถ้าโปรเจคไม่มี ordering insight (greenfield monolith ไม่ต้องมี)

### 3.5 SD-as-Master Boundary (CRITICAL — ห้าม restate)

- [ ] **`02-high-level-architecture.md` Top section** เป็น **Requirements Traceability** — banner ชี้ BA docs (02-04) เป็น authoritative + Requirements Traceability Matrix (BA FR-ID → SD section/service). **ห้าม copy-paste FR/NFR prose จาก BA**
- [ ] **`02-high-level-architecture.md` Bottom section** เป็น **ADR Digest** — table link ไปหา ADR เต็มใน `docs/adr/`. **ห้าม restate ADR content เป็น prose**
- [ ] **API contracts** เขียนใน `docs/api-specs/*.yaml` (full OpenAPI: field-level validation + error schemas per status code 400/401/403/404/409/422/500 + auth scheme + rate-limit + pagination/filter/sort). TD จะอ่าน YAML นี้เป็น source of truth — ไม่มี TD-01 แยก
- [ ] **Pattern decisions** เขียนเป็น ADR (Repository, CQRS, Strangler, ฯลฯ) — implementation skeleton จะอยู่ใน TD

### 3.6 Audience Self-Check

- [ ] BA / PM อ่านแล้วเชื่อมได้ไหมว่า architectural decision ตอบ requirement ข้อไหน?
- [ ] Tech Lead รับไปสั่งทีมได้ไหม โดยไม่ต้องถามกลับ *"ทำไมเลือกตัวนี้"*?
- [ ] Junior dev อ่าน `02-high-level-architecture.md` จบ อธิบายภาพใหญ่ระบบให้เพื่อนได้ไหม?

ถ้ามี ❌ → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 → ห้าม write file จนกว่าจะ ✅ ครบทุกข้อ

---

## Phase 4: Write & Handoff

### 4.1 Write the 6 Deliverables (v1.2: gaps 01/06 — merged into 02)

เขียนทั้ง 6 ไฟล์ใน `docs/design-docs/` ตาม schema ใน prompt template § LAYER 3 → Output Package — เขียน **sequential** (doc ถัดไปอาจอ้าง doc ก่อนหน้า):

| # | File | Key Artifacts |
|---|------|---------------|
| 02 | `02-high-level-architecture.md` | **(Top)** Traceability Matrix + summary stats + banner ชี้ BA authoritative. **(Body)** Mermaid `graph TB`, component→service mapping, **Glossary**. **(Bottom)** ADR digest table (ADR# / Title / Status / Chosen / Trade-off / Revisit-When / Link). _v1.2: absorbed former 01 + 06_ |
| 03 | `03-deep-dive.md` | Problem → Approach → Implementation → Failure modes per critical challenge |
| 04 | `04-data-flow.md` | Mermaid `sequenceDiagram`, consistency boundaries, idempotency, timing budgets |
| 05 | `05-security.md` | STRIDE analysis, AuthN/AuthZ, rate limiting, secret management |
| 07 | `07-future-evolution.md` | scaling-trigger table, migration paths, deprecation considerations + (optional) **Evolution Sequence** |
| 08 | `08-product-breakdown.md` | work breakdown, dependency map + (optional) **Phase Hints (Suggested)** + **Per-Task Metadata** |

### 4.2 Write Additional Artifacts

| Artifact | Location | Required? |
|----------|----------|-----------|
| ADRs (1 per major decision รวมถึง pattern decisions) | `docs/adr/NNN-title.md` | **REQUIRED** ≥ 1 |
| API contracts (full OpenAPI) | `docs/api-specs/*.yaml` | **REQUIRED** ถ้ามี API; field-level validation + error schemas per status + auth + rate-limit |
| Mermaid diagrams (reusable) | `docs/diagrams/` | OPTIONAL — embed ใน docs โดยตรง หรือ split |

### 4.3 Update Project State (REQUIRED — ตาม prompt § Final Step)

1. ถ้า `docs/state/overview.md` ยังไม่มี → สร้างใหม่ด้วย template (BA phase ควรสร้างไว้แล้ว — ถ้าไม่มี ใช้ template จาก BA prompt § Final Step)
2. Update **เฉพาะแถว `Design (SD)`** เป็น `✅ Complete` + วันที่วันนี้ + notes (เช่น *"6 docs in `docs/design-docs/` (v1.2: gaps 01/06 — merged into 02), N ADRs (incl. pattern decisions), M API contracts with full validation + error schemas, Evolution Sequence: yes/no, Phase Hints variant: FULL/MINIMAL/none"*)
3. **ห้ามแตะแถวอื่น** — phase อื่น update ด้วยตัวเอง

### 4.4 HALT — Present Summary to User

แสดงสรุปเป็นภาษาไทย:

- **Architecture style chosen** + 1-line trade-off justification (เช่น *"modular monolith เพราะทีม 3 คน + peak 50 RPS"*)
- **Service/module list** + bounded contexts
- **Critical technical challenges** ที่ identified ใน Step 3 (พร้อม chosen approach)
- **Major flows** ที่ documented ใน `04-data-flow.md`
- **ADR count** + list (ADR-001 ... ADR-NNN พร้อม title สั้น)
- **API contracts** count + endpoints overview
- **Evolution Sequence** status — *"E1...E4 documented"* หรือ *"skipped — greenfield monolith ไม่มี ordering constraints"*
- **Phase Hints** variant — FULL / MINIMAL / skipped
- **Schedule leakage check** — *"grep clean ✅"* (ยืนยันว่าไม่มี Sprint/dates/capacity leak)
- **Open assumptions** ⚠️ — ให้ user correct ก่อน TD/UX phase
- Path ของไฟล์ที่สร้างทั้งหมด
- **Next command suggestions:**
  - `/sd-review all` — รัน Design QA (adversarial architecture review) ก่อน lock SD
  - `/ux-design auto` — ข้ามไป UX design (ใช้เฉพาะถ้า SD ผ่านสายตามนุษย์แล้ว)

⏸️ **รอ user review + approve ก่อน mark phase complete**

ถ้า user request edits → กลับ Phase 2 step ที่เกี่ยวข้อง → re-run Phase 3 quality gate → re-present

---

## Escape Hatches

| สถานการณ์ | Action |
|-----------|--------|
| BA docs ขาดบางไฟล์ (เช่น ไม่มี `04-business-rules.md` หรือ `05-user-flows.md`) | HALT + แนะนำ `/ba` เพื่อทำ BA ให้ครบ; อย่า design จาก partial requirements |
| BA มี CRITICAL/HIGH ค้างใน claim-review-and-rebuttal/ | WARN user; รอ confirmation ก่อน proceed (ปกติแนะนำให้ `/ba-rebuttal` ให้ stable ก่อน) |
| NFR ไม่มี measurable targets (BA escape ผ่าน) | WARN — แนะนำ `/amend ba` เพื่อ quantify NFRs ก่อน. ถ้า user ยืนยัน proceed → mark assumptions ⚠️ ใน SD |
| มี ADR conflict (พบ inconsistency ระหว่าง ADRs ที่มีอยู่กับ decision ใหม่) | HALT — flag ให้ user แก้ก่อน proceed; อย่าแอบ override existing ADR |
| ผู้ใช้พยายามใส่ schedule (sprint numbers / dates / team capacity) ลงใน SD | ปฏิเสธ + อธิบาย Phase Contract (Option C); ย้ายเป็น Evolution Sequence (architectural ordering) หรือ defer ให้ Impl Planner |
| Realize ระหว่างทำว่า BA goals ขัดกัน | STOP + escalate ผ่าน `/backtrack ba` แทนที่จะเดา resolution เอง |
| NotebookLM MCP fail ซ้ำหลายครั้ง | notify user, proceed without it (BA + foundation-input-sources น่าจะมีข้อมูลพอ) |
