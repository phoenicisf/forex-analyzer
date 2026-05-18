# AI-Native Development Methodology (ANDM) — Full Track Runbook

> วิถีการทำงานจริง — จากไอเดียโปรเจคจนส่งมอบ
> Source of truth สำหรับ ANDM Full Track lifecycle
> ใช้คู่กับ AI-Native IDE (Claude Code / Windsurf / Antigravity) + Knowledge Base Tool (เช่น NotebookLM)

> 📚 **Source-repo contributors only:** When editing files in this track folder directly (ANDM template maintenance), follow **Track Boilerplate Integrity Rule** — track-internal files must reference only track-local paths (no `methodologies/<other-track>/...`, no `real-problems/...`, no `../../...`). Reference `CLAUDE.md` means downstream's CLAUDE.md (derived from `.andm/constitution/sample-claude-md-slim.md`); content must exist there. Full rule + rationale at ANDM source repo's root `CLAUDE.md § Track Boilerplate Integrity Rule`. Downstream project users (engineers using Full Track in their own projects) can ignore this note.

### Who This Runbook Is For

| | |
|---|---|
| **Target** | Developer ที่อ่านและเขียนโค้ดได้ — ใช้ AI เป็นเครื่องมือเร่งงาน ไม่ใช่แทนที่ skill |
| **Prerequisite** | เข้าใจ git workflow, testing concepts, basic software architecture |
| **Not for** | คนที่ไม่เคยเขียนโค้ดมาก่อน — AI ช่วยเขียนได้ แต่ต้องอ่านและ debug โค้ดได้เองด้วย |

---

### Quick Start (5 นาที)

> อ่านแค่ 5 ข้อนี้ก็เริ่มทำงานได้ — รายละเอียดแต่ละ Phase อยู่ด้านล่าง

1. **Design** — สร้าง BA requirements (5 docs; v1.2: 06-handoff dropped) → System Design (6 docs + ADRs + API specs; v1.2: gaps 01/06 — merged into 02) → UX/UI Design (5 docs; UX-06 dropped) → Technical Design (3 docs; SD-as-Master) — ใช้ prompt templates เป็น guide
2. **Design QA** — Adversarial review + rebuttal loop สำหรับ BA, SD, UX, TD — ทุก round ต้องมีคน approve ก่อนปิด
3. **Implement** — สร้าง sprint plan → implement ทีละ task (auto-detect size) → code review → QA planning (parallel) — ทุก commit ต้องมี "Why"
4. **Harden** — Red Team ให้ AI โจมตี code (OWASP + STRIDE) → Defense loop จนอุดทุกรู → คน review findings ก่อนปิด
5. **Deliver** — รวมเอกสารเข้า Knowledge Base ถาวร → อัปเดต handoff ฉบับสมบูรณ์ → วัดผล (ต้องมี baseline)

---

## สารบัญ

0. [Bootstrap: Repo Setup (pre-lifecycle)](#bootstrap-repo-setup-pre-lifecycle) — เตรียมโปรเจคให้ AI ทำงานได้ (ทำครั้งเดียว)
1. [Phase 1: Design](#phase-1-design) — สร้างเอกสารออกแบบ (BA → SD → UX → TD)
2. [Phase 2: Design QA](#phase-2-design-qa) — กรองคุณภาพเอกสารด้วย adversarial review
3. [Phase 3: Implement](#phase-3-implement) — เขียน Code + QA Planning
4. [Phase 4: Harden](#phase-4-harden) — ตรวจสอบความปลอดภัย
5. [Phase 5: Deliver & Maintain](#phase-5-deliver--maintain) — ส่งมอบ + ดูแลต่อ
6. [Navigation & Amendment](#navigation--amendment) — ย้อน phase, แก้ไข deliverables, auto-detect next action
7. [Agent Personas](#agent-personas) — ตาราง personas ทั้งหมด
8. [Command Quick Reference](#command-quick-reference) — ตาราง commands ทั้งหมด
9. [Quick Reference — File Structure](#quick-reference--file-structure) — โครงสร้างเอกสารทั้งหมด
10. [Golden Rules](#golden-rules) — กฎสำคัญที่ต้องยึดถือ

---

## Bootstrap: Repo Setup (pre-lifecycle)

> **เป้าหมาย:** เตรียมโปรเจคให้ AI ทำงานได้อย่างมีประสิทธิภาพ ทำครั้งเดียวตอนเริ่มโปรเจค

### 1. สร้าง CLAUDE.md — กฎกลางของโปรเจค

**ไฟล์นี้คือ "รัฐธรรมนูญ"** ที่ AI ทุกตัวอ่านก่อนเริ่มงาน

> **สำคัญ: CLAUDE.md ต้องสั้นที่สุดเท่าที่เป็นไปได้** — ยิ่งยาว AI ยิ่งมีโอกาสมองข้ามกฎสำคัญ (lost in the middle problem) แนะนำไม่เกิน 50-100 บรรทัดสำหรับ root file

#### Layered Approach (แนะนำ)
```
CLAUDE.md                          ← critical rules เท่านั้น (tech stack, security ห้ามเด็ดขาด, architecture pattern หลัก)
.claude/rules/security.md          ← รายละเอียด security rules
.claude/rules/code-style.md        ← รายละเอียด code style
.claude/rules/testing.md           ← รายละเอียด testing rules
```
Agent จะอ่าน rules ย่อยเพิ่มเมื่อทำ task ที่เกี่ยวข้อง — หลาย IDE (Claude Code, Windsurf) รองรับ hierarchical rules files

**Monorepo (หลายภาษา):** แยก rules ตาม service เพิ่มจาก shared rules
```
CLAUDE.md                              ← shared rules (security, git, architecture กลาง)
.claude/rules/
├── security.md                        ← shared — ทุก service ใช้
├── testing.md                         ← shared — testing philosophy กลาง
├── web.md                             ← React/Next.js specific
├── api.md                             ← Go/Express specific
└── workflow.md                        ← Python/Temporal specific
```

#### เนื้อหา CLAUDE.md (root) ต้องครอบคลุม:

```markdown
# [ชื่อโปรเจค] - AI Development Rules

## Tech Stack
[ภาษา, framework, database, infra ที่ใช้]

## Architecture Rules
[module structure, design patterns, ข้อห้าม]

## Security Rules
[ห้าม hardcode secrets, ต้อง sanitize, ต้อง validate]

## Git Commit Rules
[format, convention — ต้องอธิบาย "Why" เสมอ]

## Code Style
[naming, async/await, imports, test naming]
```

#### Template ตัวอย่าง

| Template | ใช้เมื่อ |
|---|---|
| `sample-claude-md-slim.md` (~60 บรรทัด) | **แนะนำ** — root file สั้น + อ้างอิง `.claude/rules/*.md` |

### 2. ตั้งค่า MCP — เชื่อมต่อ Data Sources (optional)

> **MCP เป็น optional** — ไม่มี MCP ก็ทำงานได้ แค่ต้อง copy-paste schema/data เข้า context เอง

ให้ Agent ติดตั้ง MCP Server ที่จำเป็น:
- [ ] Database MCP (PostgreSQL / MongoDB / etc.)
- [ ] File System MCP (ถ้าเอกสารอยู่นอก repo)
- [ ] อื่นๆ ตามโปรเจค

> ⚠️ **Connection string ต้องอ่านจาก .env** ห้าม hardcode ใน prompt

**Fallback ถ้า MCP ไม่ work:** dump schema เป็น `.sql` file ใส่ `docs/` แล้วให้ AI อ่านจาก file แทน

### 3. Scaffold โครงสร้างโปรเจค

**สั่ง Agent สร้างโครงสร้างโฟลเดอร์** จาก Design Docs:

ตรวจสอบว่ามี:
- [ ] โครงสร้าง module ตาม Design Docs
- [ ] `docker-compose.yml` สำหรับ local dev
- [ ] Seed data (ถ้ามี)
- [ ] `docs/state/` สำหรับ handoff files

### 4. สร้าง Custom Skills ที่ใช้ซ้ำบ่อย

Skills = สอน Agent ทำงานตาม pattern ของทีม สร้างครั้งเดียว ใช้ซ้ำตลอดโปรเจค

```
.agents/skills/[skill-name]/SKILL.md
```

**เมื่อไรควรสร้าง Skill:**
- ทำซ้ำ > 3 ครั้ง
- มี steps > 5 ขั้นตอน
- ต้องการ consistent output format ทุกครั้ง

### 5. ตั้ง Guardrails — ป้องกัน Agent ทำพัง

- [ ] ตั้ง Terminal Execution Policy (Off / Auto / Turbo)
- [ ] ตั้ง `.gitignore` สำหรับ `.env`, credentials
- [ ] ตั้ง Browser URL Allowlist (ถ้าใช้ Browser Subagent)
- [ ] ตั้ง **Automated Security Enforcement** — กฎสำคัญใน CLAUDE.md ต้องมี automated check คู่กัน:
  - ESLint rules (no-hardcoded-secrets)
  - Pre-commit hooks (ตรวจ secrets ใน code)
  - CI pipeline secret scanning (เช่น gitleaks, trufflehog)

### 6. ตั้ง Claude Code Hooks — Automated Quality Checks

ตั้ง hooks ใน `.claude/settings.json` เพื่อให้ Claude Code ตรวจสอบอัตโนมัติ:

- [ ] **Block `--no-verify`** — ป้องกัน agent ข้าม pre-commit hooks
- [ ] **Block secrets in commits** — ป้องกัน commit message ที่มี credentials
- [ ] **Protect linter configs** — ป้องกัน agent แก้ config แทน fix code
- [ ] **Block force push main** — ป้องกัน force push ไป main/master
- [ ] **Bash audit log** — log ทุก command ที่ agent รัน
- [ ] **Batch format** — auto-format ไฟล์ที่แก้ไขหลังแต่ละ response

เลือก profile ตาม phase: `minimal` (design) → `standard` (implement) → `strict` (harden)

**📖 Guide:** `.andm/constitution/hooks-setup.md`

### ✅ จบ Setup เมื่อ:

| Deliverable | ตรวจสอบ |
|---|---|
| `CLAUDE.md` + `.claude/rules/` | AI อ่านแล้วรู้กฎทั้งหมด |
| MCP Connections (optional) | Agent อ่าน DB schema ได้เอง |
| Project Scaffold | โครงสร้างโฟลเดอร์พร้อม |
| Guardrails | ตั้ง policy + .gitignore เรียบร้อย |
| Claude Code Hooks | `.claude/settings.json` มี hooks configured |

---

## Phase 1: Design

> **เป้าหมาย:** จากไอเดีย/Requirement → ได้ Blueprint ที่พร้อม review แล้วเริ่มโค้ดดิ้ง

> [!WARNING]
> **Template Inheritance Guard** — Runbook นี้เป็น **methodology guide** ไม่ใช่ tech stack specification
> Tech stack และ service names ที่กล่าวถึงเป็น **ตัวอย่าง monorepo layout เท่านั้น**
> ให้อ้างอิง tech stack จาก `CLAUDE.md` ของโปรเจค

### Step 0: รวบรวมเอกสารเข้า Knowledge Base Tool

**ทำไม:** ให้ AI มี "สมองกลาง" ที่รู้ทุกอย่างเกี่ยวกับโปรเจค — ถามอะไรก็ตอบได้จากเอกสารจริง ไม่มัว hallucinate

**ใช้ Knowledge Base Tool** เช่น NotebookLM, RAG pipeline, Cursor/Windsurf project indexing หรือแม้แต่ `docs/` folder ที่ AI อ่านได้จาก context:
- [ ] BRD / PRD / User Stories
- [ ] API Spec ระบบเดิม (ถ้ามี migration)
- [ ] Database Schema ระบบเดิม
- [ ] คู่มือ 3rd-party ที่เกี่ยวข้อง (Auth provider, Storage, etc.)
- [ ] SLA / Budget / Timeline / Constraints

> **หลักการ:** เอกสารต้อง live ใน repo (git-tracked) เสมอ — Knowledge Base tool เป็นแค่ layer อ่านทับ ไม่ใช่แหล่งเก็บหลัก

### 1A: BA Deliverables (Business Analysis)

**ใครทำ:** BA Agent
**Prompt:** `.andm/prompt-templates/ba-requirements-prompt.md`
**Output:** `docs/ba/01-05` (v1.2: 06-handoff dropped)

สกัด Requirements ด้วย Knowledge Base Tool 3 รอบ:

| รอบ | Prompt | Deliverable |
|---|---|---|
| 1 | "สกัด Functional Requirements แบ่ง Must Have / Should Have / Nice to Have" | ตาราง Requirements พร้อมแหล่งอ้างอิง |
| 2 | "สกัด Non-Functional Requirements: Performance, Scalability, Security, SLA" | ตาราง NFR พร้อมค่าเป้าหมาย |
| 3 | "หา Edge Cases และ Failure Points ที่ซ่อนอยู่ ระบุ Impact" | ตาราง Edge Cases ที่ทีมอาจมองข้าม |

จากนั้นใช้ BA prompt template สร้าง deliverables ครบ 5 ไฟล์:

```
docs/ba/
  01-project-brief.md
  02-functional-requirements.md
  03-non-functional-requirements.md
  04-business-rules.md
  05-user-flows.md
```

> **v1.2 change:** `06-handoff-to-architecture.md` ถูกตัดออก — open questions / risks ใส่เข้า relevant doc ตาม domain (FR gap → 02, NFR gap → 03, rule gap → 04, flow gap → 05). SD agent อ่าน BA 01-05 ตรงๆ

**📖 Guide:** `.andm/development-guide/ba-claim-review-workflow.md`

### 1B: System Design Deliverables

**ใครทำ:** Architect Agent
**Prompt:** `.andm/prompt-templates/system-design-master-prompt.md`
**Input:** BA deliverables ทั้งหมด (`docs/ba/01-05`)
**Output:** `docs/design-docs/02-08` (6 docs — gaps ที่ 01, 06 เจตนา) + `docs/adr/` + `docs/api-specs/`

วิเคราะห์ Architecture Trade-offs ด้วย AI:

```
Prompt: "คุณคือ Enterprise Solution Architect
ข้อจำกัด: [ทีมกี่คน, เวลาเท่าไร, tech stack ที่ถนัด, ผู้ใช้กี่คน]
วิเคราะห์ Trade-off ระหว่าง [ตัวเลือก A] vs [ตัวเลือก B] vs [ตัวเลือก C]
เปรียบเทียบ: MVP Speed, Scalability, Maintainability, Operational Cost, Team Fit
ฟันธงเลือก พร้อมสรุปเหตุผล"
```

**📦 Deliverable:** บันทึกผลเป็น ADR (Architecture Decision Record) ทุกครั้งที่ตัดสินใจ

```
docs/design-docs/
├── 02-high-level-architecture.md  ← Requirements Traceability + Components + Communication + Infra + Glossary + ADR Digest
├── 03-deep-dive.md                ← Critical technical challenges with deep analysis
├── 04-data-flow.md                ← Data flows with sequence diagrams & timing budgets
├── 05-security.md                 ← Defense layers, auth, threat model
├── 07-future-evolution.md         ← Scaling triggers + migration paths + Evolution Sequence (E1/E2/... with ADR rationale)
└── 08-product-breakdown.md        ← Work inventory + Phase Hints (Suggested P1-P4) + Per-Task Metadata

docs/adr/NNN-title.md
docs/api-specs/*.yaml
```

> **v1.2 change:** `01-requirements.md` (traceability) merge เป็น top section ของ `02-high-level-architecture.md`; `06-tradeoffs.md` (ADR digest) merge เป็น bottom section ของ `02`. Numbering เก็บ stable (gaps ที่ 01, 06) เพื่อลด churn ของ cross-references

> ⚠️ **SD Phase Contract — Option C (Hints Allowed, Schedule Not):**
>
> System Design ออกแบบ architecture (what + where + why) และ**อาจให้ architectural hints** เกี่ยวกับ ordering ได้ แต่**ไม่ทำ delivery schedule**
>
> **SD CAN include:**
> - `07-future-evolution.md` → Evolution Sequence (hard constraints, ADR-backed)
> - `08-product-breakdown.md` → Phase Hints (soft P1-P4 suggestions) + per-task metadata (risk, must_precede, unlocks, arch_rationale)
>
> **SD CANNOT include:**
> - Sprint numbers, calendar dates, team capacity, release milestones tied to business schedule
> - Phase Hints labeled as "Plan"/"Assignment" (ต้องเป็น "Hints (Suggested)")
> - Hints without architectural rationale
>
> **Impl Planner owns the final phasing** (`/impl-plan` → `docs/state/impl-plan.md`):
> - อ่าน SD hints เป็น input
> - รัน phase assignment rules ของตัวเอง (independent)
> - Honor หรือ override พร้อม document rationale ใน Phasing Rationale
> - Evolution Sequence เป็น hard constraint (backtrack ถ้า violate), Phase Hints เป็น soft suggestion (override ได้พร้อม reason)

> **ทำไมแยกไฟล์:** SDD ไฟล์เดียวมักยาว 2,000+ บรรทัด — Agent ต้องอ่านทั้งหมดทุกครั้งแม้ทำแค่ task เล็กๆ แยกไฟล์ทำให้สั่ง "อ่าน 02-high-level-architecture.md แล้วสร้าง module X" ได้เลย

สร้าง Diagrams + API Contract (ใช้ Multi-Agent ทำพร้อมกันได้):
- [ ] **Architecture Diagram** (Mermaid.js) — ภาพรวมระบบ
- [ ] **Sequence Diagram** — flow หลักๆ เช่น user journey สำคัญ
- [ ] **ER Diagram** — database schema
- [ ] **OpenAPI Spec** — API contract ของแต่ละ module

> **ตรวจสอบ rendered diagram ทุกครั้ง** — AI มักสร้าง Mermaid syntax ที่มี edge cases/errors ใช้ Mermaid Live Editor verify ก่อน commit

**📖 Guide:** `.andm/development-guide/sd-claim-review-workflow.md`

### 1C: UX/UI Design Deliverables

**ใครทำ:** UX Designer Agent (หรือ Human Designer)
**Mode:** เลือกตาม context ของโปรเจค
**Input:** `docs/ba/05-user-flows.md` + `docs/design-docs/02-high-level-architecture.md` + `docs/api-specs/`
**Output:** `docs/ux/01-05`

| Mode | เมื่อไหร่ใช้ | เครื่องมือ |
|------|-------------|----------|
| **A: AI-Generated** | Greenfield, ยังไม่มี design | Stitch (Google) / Brainstorming visual companion |
| **B: Figma-First** | มี designer / มี Figma file | Figma + Figma MCP server |
| **C: Existing UI Audit** | Brownfield, มี UI อยู่แล้ว | Manual audit + screenshot analysis |
| **D: Frontend Build** | ต้องสร้าง production UI ตรง (landing page, dashboard, app shell) | `frontend-design` + `dashboard-builder` + `liquid-glass-design` skills |
| **E: Reference-Driven** | มี reference website เป็นต้นแบบ visual style | `ux-design-reference-prompt.md` + user-supplied `design-reference/*-DESIGN.md` (acquisition per `.andm/development-guide/ux-design-reference-acquisition.md`) |
| **F: Claude Design** | ต้องการ interactive visual iteration (comments/sliders), มี Pro/Max/Team/Enterprise subscription | Claude Design (Anthropic Labs) — Opus 4.7 vision, research preview 2026-04-17 |

**Command:** `/ux-design <mode>` (stitch / figma / existing / reference / frontend / claude-design / auto)

```
docs/ux/
  01-design-tokens.md              ← Colors, typography, spacing, shadows
  02-component-inventory.md        ← Components + variants + states + priority
  03-page-layouts.md               ← Wireframe/layout ทุกหน้า
  04-navigation-structure.md       ← Sitemap + breadcrumb UX + nav labels + auth guards (routing authority: TD 03-frontend-design)
  05-interaction-patterns.md       ← Forms, loading, empty, error, responsive
```

**Command:** `/ux-design <mode>` (stitch / figma / existing / reference / frontend / claude-design / auto)
**📖 Guide:** `.andm/development-guide/ux-design-workflow.md`

> **Output ของ 1C (UX) เป็น input ของ 1D (TD)** — ต้องสร้าง UX deliverables ให้ครบก่อนเริ่ม Technical Design

### 1D: Technical Design Deliverables (Detailed / Low-Level Design)

**ใครทำ:** Technical Architect Agent
**Prompt:** `.andm/prompt-templates/technical-design-master-prompt.md`
**ต้องมีก่อน:** ✅ SD docs ครบ + ✅ UX docs ครบ (ผ่าน review ยิ่งดี)
**Input:** `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06 — merged into 02) + `docs/ux/01-05` + `docs/adr/` + `docs/api-specs/` + `.claude/rules/`
**Output:** `docs/technical-design/02, 03, 04` (SD-as-Master: api-specs + ADRs + QA-01 absorb the rest)

```
docs/technical-design/
├── 02-backend-design.md             ← Class/module structure, interfaces, DTOs, CQRS handlers, DI map (+ optional Flow Appendix for method-level sequences)
├── 03-frontend-design.md            ← Component tree, state management, routing, data fetching, error boundaries
└── 04-database-design.md            ← Column-level schema, constraints, indexes, migrations, seed data
```

**Dropped in SD-as-Master consolidation:**
- `01-api-contracts.md` → `docs/api-specs/*.yaml` (SD-owned OpenAPI — validation, error schemas, auth, rate-limit)
- `05-design-patterns.md` → `docs/adr/` (pattern decisions) + TD-02 (code skeletons inline)
- `06-sequence-diagrams.md` → `docs/design-docs/04-data-flow.md` (flow-level) + TD-02 `## Flow Appendix` (method-level, optional)
- `07-test-strategy.md` → `docs/qa/01-test-strategy.md` (QA-01 authoritative for design+execution test strategy)
- `08-handoff-to-implementation.md` → Impl Planner reads `docs/design-docs/07-future-evolution.md` + `08-product-breakdown.md` directly

> **ทำไมต้องมี TD แยกจาก SD:** SD อยู่ระดับ architecture (WHAT + WHERE) — TD อยู่ระดับ implementation-ready (HOW + EXACT SHAPE) engineer สามารถเริ่ม code จาก TD ได้ทันทีโดยไม่ต้องตัดสินใจ design เอง

**📖 Guide:** `.andm/development-guide/td-workflow.md`

### ✅ จบ Phase 1 เมื่อมีครบ:

| Deliverable | ไฟล์ |
|---|---|
| BA Requirements (5 docs) | `docs/ba/01-05` |
| Design Docs (6 docs) | `docs/design-docs/02-08` (gaps ที่ 01, 06) |
| ADR (ทุกการตัดสินใจ) | `docs/adr/NNN-xxx.md` |
| API Specs | `docs/api-specs/*.yaml` |
| UX/UI Design (5 docs) | `docs/ux/01-05` |
| Technical Design (3 docs) | `docs/technical-design/02, 03, 04` |

---

## Phase 2: Design QA

> **เป้าหมาย:** กรองคุณภาพเอกสารด้วย adversarial review — ทำให้ Design แข็งแกร่งก่อนเริ่มโค้ด

ทุก review/rebuttal cycle ทำตามรูปแบบเดียวกัน:

```
Reviewer Agent → โจมตีจุดอ่อน (claim review)
      ↓
Defender Agent → เสนอ fix + โต้แย้ง (rebuttal)
      ↓
⏸️ HALT — คน review ก่อนปิด loop
      ↓
Reviewer Agent → ตรวจ round ถัดไป (skip findings ที่ fix แล้ว)
      ↓
ทำซ้ำจนไม่มี CRITICAL/HIGH ค้าง
```

> ⚠️ **Human-in-the-loop สำคัญ:** อย่าให้ loop จบโดย AI อนุมัติ AI กันเอง — คนต้อง review findings ก่อนปิด loop

### 2A: BA Review & Rebuttal Cycle

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ BA docs | `/ba-review all` | BA Reviewer | `docs/ba/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ | `/ba-rebuttal claim-review-01.md` | BA Defender | `docs/ba/claim-review-and-rebuttal/rebuttal-round-01.md` |
| ทำซ้ำ | `/ba-review all` | BA Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-ba-reviewer/SKILL.md` — Adversarial Consultant (18 BA attack vectors)
- `.agents/skills/andm-ba-defender/SKILL.md` — Constructive Defense (Accept/Partial/Reject)

**📖 Guide:** `.andm/development-guide/ba-claim-review-workflow.md`

### 2B: System Design Review & Rebuttal Cycle

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ design docs | `/sd-review all` | SD Reviewer | `docs/design-docs/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ | `/sd-rebuttal claim-review-01.md` | SD Defender | `docs/design-docs/claim-review-and-rebuttal/rebuttal-round-01.md` |
| ทำซ้ำ | `/sd-review all` | SD Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-sd-reviewer/SKILL.md` — Adversarial Architect (20 SD attack vectors)
- `.agents/skills/andm-sd-defender/SKILL.md` — Constructive Architect (+ ADR update rule)

**📖 Guide:** `.andm/development-guide/sd-claim-review-workflow.md`

### 2C: UX/UI Design Review & Rebuttal Cycle

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ UX docs | `/ux-review all` | UX Reviewer | `docs/ux/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ (Option A) | `/ux-rebuttal claim-review-01.md` | UX Defender | `docs/ux/claim-review-and-rebuttal/rebuttal-round-01.md` |
| แก้ตรง (Option B) | `/ux-fix claim-review-01.md` | — | fixed docs/ux/ + fix report |
| ทำซ้ำ | `/ux-review all` | UX Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-ux-reviewer/SKILL.md` — Adversarial UX Consultant (22 UX attack vectors)
- `.agents/skills/andm-ux-defender/SKILL.md` — Constructive UX Defense (Accept/Partial/Reject)

> **Option A vs B:** ใช้ `/ux-rebuttal` เป็น default — ถ้า token budget จำกัด → ใช้ `/ux-fix` ประหยัดกว่า ~50%

**📖 Guide:** `.andm/development-guide/ux-design-workflow.md` → Step 3

### 2D: Technical Design Review & Rebuttal Cycle

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ TD docs | `/td-review all` | TD Reviewer | `docs/technical-design/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ | `/td-rebuttal claim-review-01.md` | TD Defender | `docs/technical-design/claim-review-and-rebuttal/rebuttal-round-01.md` |
| ทำซ้ำ | `/td-review all` | TD Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-td-reviewer/SKILL.md` — Adversarial Engineer (19 TD attack vectors + cross-domain consistency)
- `.agents/skills/andm-td-defender/SKILL.md` — Constructive Architect (7-step protocol + cascade check)

**📖 Guide:** `.andm/development-guide/td-workflow.md`

### ✅ จบ Phase 2 เมื่อ:

- ✅ BA docs ผ่าน review (ไม่มี CRITICAL/HIGH ค้าง)
- ✅ Design docs ผ่าน review
- ✅ ADRs up-to-date
- ✅ API specs consistent
- ✅ UX deliverables approved (design tokens, components, layouts)
- ✅ TD docs ผ่าน review (cross-domain consistency: API↔DB↔Frontend↔Test)
- ✅ ได้ TD-02/03/04 พร้อมเป็น implementation blueprint (Impl Planner อ่าน SD-07/08 โดยตรง)

---

## Phase 3: Implement

> **เป้าหมาย:** จาก Design Blueprint + SD Hints → **Phase-Grouped Working Code** + Tests + QA Plan
>
> ⭐ **Phase 3 เป็นที่เดียวใน lifecycle ที่ Impl Planner ตัดสินใจ delivery phasing** — SD ให้ **architectural hints** (Evolution Sequence, Phase Hints, per-task metadata), TD ส่งต่อ hints พร้อม refinements, Impl Planner ทำ **final decision** ด้วย honor/override protocol

### 3A: สร้าง Phase-Grouped Plan (Option C with SD Hints)

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| สร้าง plan | `/impl-plan 1` | Impl Planner | `docs/state/impl-plan.md` (มี P1/P2/P3/P4 + phase gates + SD Hint Alignment audit trail) |

**Persona:** `.agents/skills/andm-impl-planner/SKILL.md` — Tech Lead / Sprint Planner **ผู้เดียวที่ถือ final Phasing Decision**

#### Implementation Phase Taxonomy (Default)

| Phase | Purpose | Phase Gate | % Work |
|-------|---------|------------|--------|
| **P1: Foundation** | Infra, auth, DB schema, CI/CD | Dev env runs e2e + smoke test | 20-30% |
| **P2: Core** | MVP slice — primary user value | Primary flow e2e + critical tests | 40-50% |
| **P3: Polish** | Should-Haves, NFRs, observability | All Must/Should + NFR targets met | 20-30% |
| **P4: Stretch** *(optional)* | Could-Haves, experiments | Ship or defer to backlog | 0-10% |

> **Custom phase shapes** (API-only, data migration, brownfield refactor, etc.) — ดู `.agents/skills/andm-impl-planner/SKILL.md` section "Implementation Phasing Strategy"

#### SD Hint Consumption (Option C Protocol)

**Step A — Read SD hints:**
- **Evolution Sequence** จาก `07-future-evolution.md` (hard constraints, ADR-backed)
- **Phase Hints** จาก `08-product-breakdown.md` (soft P1-P4 suggestions)
- **Per-Task Metadata** (risk, must_precede, unlocks, arch_rationale)

**Step B — รัน phase assignment rules อย่าง independent:**

1. **Dependency rule** — task ไปไม่ได้เร็วกว่า phase ล่าสุดของ hard dependencies
2. **MoSCoW rule** — Must → P1/P2, Should → P3, Could → P4, Won't → excluded
3. **Risk rule** — งานเสี่ยงสูงไป phase เร็วสุดที่ dependency ยอมให้ (fail fast)
4. **Value rule** — ใน phase เดียวกัน งานที่ unlock user value มาก่อน
5. **Service-coupling rule** — tasks แตะ module/file เดียวกัน ควรอยู่ phase เดียวกัน

**Step C — เปรียบเทียบ result ของตัวเองกับ SD hints:**

- ✅ **Align** (result ตรงกับ SD hint) → use it, note alignment
- ⚠️ **Diverge** (result ต่างจาก SD hint) → use own answer, document reason
- 🔴 **Violation** (result ขัด Evolution Sequence) → STOP, `/backtrack sd`
- ◻️ **No hint** → use own answer directly

**Step D — Document ใน Phasing Rationale ของ `impl-plan.md` (mandatory)**

> ⚠️ **ห้ามมี forward references** — task ใน P1 ห้าม depend บน task ใน P2+ ถ้าพบต้อง re-plan
> ⚠️ **ห้าม silent copy หรือ silent override** — ทุก task ต้อง record alignment status

### 3B: Implement ทีละ Task

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ทำ task | `/impl-task IMPL-001` | Impl Engineer | working code + tests + commit |
| ทำ task | `/impl-task IMPL-002` | Impl Engineer | working code + tests + commit |
| ... | ... | ... | ... |

**Persona:** `.agents/skills/andm-impl-engineer/SKILL.md` — Senior Full-Stack Engineer

#### เลือก Process ตามขนาด Task (Auto-detect)

| ขนาด | ตัวอย่าง | วิธีทำ |
|---|---|---|
| **XS-S** | Bug fix, config change, เพิ่ม field | สั่ง AI ทำจบใน prompt เดียว ไม่ต้องแบ่ง step |
| **M** | Feature เดียวภายใน module เดียว | 3 steps: Plan → Implement → Test |
| **L-XL** | Feature ข้าม module / มี dependency ซับซ้อน | Full decomposition with HALT per step |

> **Guideline ไม่ใช่กฎตายตัว** — developer ตัดสินเองว่าต้องแบ่งละเอียดแค่ไหน

**📖 Workflows:** `.agents/workflows/impl-plan.md`, `impl-plan-review.md`, `impl-plan-rebuttal.md`, `impl-task.md` *(narrative impl-workflow guide retired in 2026-05-07 cleanup; for MVP / market-race work use Ship Track instead)*

### 3C: Code Review (หลัง Sprint Tasks เสร็จ)

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ code | `/impl-review all` | Code Reviewer | `docs/code-review/review-round-01.md` |
| แก้ + โต้ | `/impl-review-fix review-round-01.md` | Impl Engineer | `docs/code-review/fix-round-01.md` |
| ทำซ้ำ | `/impl-review all` | Code Reviewer | `review-round-02.md` ... |

**Personas:**
- `.agents/skills/andm-code-reviewer/SKILL.md` — Adversarial Quality Engineer (13 review dimensions)
- `.agents/skills/andm-impl-engineer/SKILL.md` — Senior Full-Stack Engineer (fixing mode)

**13 Review Dimensions** (full table + per-dimension checks ใน `andm-code-reviewer/SKILL.md § Phase 1` — authoritative source):

1. Security (OWASP Top 10) · 2. Business Logic Correctness · 3. Error Handling · 4. Performance · 5. Over-Engineering · 6. Cross-Service Consistency · 7. Test Coverage Gaps · 8. Architecture Compliance · 9. Technical Design Compliance · 10. Test Code Quality & Defensive Patterns · 11. **Empirical AC Closure Verification** (CRITICAL on forbidden closure patterns like `[x]` + "deferred to operator-runtime") · 12. **Functional CRUD Walk** (live-system walk in BOTH locales + BOTH themes + BOTH auth roles when review touches user-visible surface) · 13. **Configuration Completeness** (env var / secret / API key consumed at runtime — `[config-audit]` evidence + `.env.example` ↔ code refs sync)

> Dimensions #11/#12/#13 added post-Shark CMS 2026-04 audit to close defect classes that previous 8-dimension scope missed: structural-only closure ที่ E-AC ยังไม่ verify, scripted snapshot tests ที่ผ่านแต่ admin form ไม่ render fields จริง, และ env-var-blind closure ที่ runtime config path never exercised. ดู CLAUDE.md § Glossary § Empirical Closure Discipline + Exploratory Walk + `[config-audit]` Evidence Kind.

**📖 Workflows:** `.agents/workflows/impl-review.md`, `impl-review-fix.md` *(narrative guide retired)*

### 3Q: QA Planning (Parallel กับ 3A-3C)

> ทำงาน **parallel** กับ Implementation — ไม่ต้องรอ code เสร็จ
> Input มาจาก `docs/design-docs/` เท่านั้น (ไม่อ่าน BA docs โดยตรง)

| Step | Command/Action | Agent | Output |
|------|---------------|-------|--------|
| สร้าง QA docs | Prompt template `qa-plan-direct-prompt.md` | QA Planner | `docs/qa/01-03` |
| ตรวจ QA docs | `/qa-review all` | QA Reviewer | `docs/qa/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ | `/qa-rebuttal claim-review-01.md` | QA Defender | `docs/qa/claim-review-and-rebuttal/rebuttal-round-01.md` |
| ทำซ้ำ | `/qa-review all` | QA Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-qa-reviewer/SKILL.md` — Adversarial QA Consultant (15 attack vectors)
- `.agents/skills/andm-qa-defender/SKILL.md` — Constructive QA Defense (Accept/Partial/Reject)

```
docs/qa/
  01-test-execution-plan.md        ← Scope, test levels (execution), environments, entry/exit, phases, impl-plan sync, defect mgmt
                                     (Design-level strategy — coverage targets, mock strategy — owned by docs/qa/01-test-strategy.md — authoritative)
  02-test-cases/
     TC-FR-*.md                    ← Functional test cases
     TC-API-*.md                   ← API contract test cases
     TC-SEC-*.md                   ← Security test cases
     TC-DF-*.md                    ← Data flow test cases
     TC-NFR-*.md                   ← Non-functional test cases
     TC-EDGE-*.md                  ← Edge case test cases
  03-traceability-matrix.md        ← Requirement → Test Case mapping
```

**📖 Workflows:** `.agents/workflows/qa-review.md`, `qa-rebuttal.md`, `qa-execute.md`, `qa-execute-fix.md` *(narrative guide retired)*

### วิธีทำงานแต่ละวัน

```
🌅 เช้า
├─ เช็ค Handoff File — อ่าน overview.md → {module}/handoff.md
├─ Review Artifacts — ดู plan, screenshots, diffs
└─ Approve / ให้ Feedback ผ่าน comment

🌞 กลางวัน
├─ สั่งงาน Agent (/impl-task, /impl-review, etc.)
├─ Review โค้ดที่ Agent สร้าง
└─ ตัดสินใจ Architecture + เขียน ADR ถ้ามีจุดที่ต้องเลือก

🌆 ก่อนเลิกงาน
├─ สรุป Handoff → docs/state/ (overview.md + {module}/handoff.md)
├─ สั่ง Agent ทำ task ข้ามคืน (ถ้ามี)
└─ Commit + Push
```

### วิธีใช้ Multi-Agent

> ⚠️ **Multi-Agent ยังเป็น experimental** — ใช้เมื่อ task แยกกันชัดเจน 100% เท่านั้น

**Prerequisite Checklist — ตรวจก่อนใช้ multi-agent:**
- [ ] Task A กับ Task B ไม่แตะไฟล์เดียวกัน
- [ ] ไม่มี dependency ระหว่าง output ของทั้งสอง
- [ ] มีคน monitor ทั้งสอง agent ได้

> **กฎ:** Agent ทุกตัวต้อง **เริ่ม** ด้วย `อ่าน CLAUDE.md + handoff` และ **จบ** ด้วย `อัปเดต handoff` (เฉพาะเมื่อจบ task หรือเปลี่ยน session)

### Handoff — เมื่อไรต้องอัปเดต

**อัปเดต handoff เฉพาะจุดสำคัญ** — ไม่ใช่ทุก step:
- ✅ จบ feature / จบ task ใหญ่
- ✅ เปลี่ยน session / clear context
- ✅ ข้ามวัน / ส่งต่อให้คนอื่น
- ❌ ไม่ต้องอัปเดตทุก step ย่อย (overhead สูงเกินจริง)

> **💡 Automated Handoff:** แทนเขียน handoff เอง ให้ AI generate จาก git diff — ลด overhead

#### Monorepo Strategy

**เมื่อไรควรใช้ per-module handoff:**
- มี **> 3 modules/services** ที่พัฒนาพร้อมกัน
- มี **> 1 developer/agent** ทำงานคนละ module พร้อมกัน
- Single handoff file เริ่ม **conflict บ่อย**

```
docs/state/
├── overview.md                    ← สรุปภาพรวมว่าแต่ละ module สถานะเป็นยังไง
├── impl-plan.md                   ← Sprint plan
├── api/handoff.md                 ← handoff เฉพาะ API module
├── web/handoff.md                 ← handoff เฉพาะ Web module
└── worker/handoff.md              ← handoff เฉพาะ Worker module
```

### Git Commits — ต้องบอก "ทำไม"

```
❌ "update code"
✅ "[feat] add content workflow API

Why: BRD requires editorial workflow (Draft → Review → Published)
with audit trail. Each transition validates role and records
in workflow_transitions table"
```

### เมื่อ Agent เริ่มเพี้ยน — Clear Context

**สัญญาณเตือน:**
- Agent แก้ไฟล์ที่ไม่เกี่ยว
- Agent ลืมสิ่งที่เพิ่งทำ
- Response ช้าลงผิดปกติ
- Agent สร้างโค้ดที่ขัดกับโค้ดเดิม

**วิธีแก้:**
1. สั่ง: "สรุปสถานะลง handoff"
2. Clear Context / เปิด Session ใหม่
3. สั่ง: "อ่าน CLAUDE.md แล้วอ่าน handoff แล้วทำงานต่อ"

### 3T: QA Test Execution (Phase 3 → Phase 4 Bridge)

> **เป้าหมาย:** รัน test cases จาก QA Plan (`docs/qa/02-test-cases/`) กับ code จริง — ปิด loop ระหว่าง QA planning กับ actual testing

**เมื่อไร:** หลัง code review ผ่าน + QA Plan approved, ก่อนเข้า Phase 4

**วิธีทำ:**
1. รัน automated tests ตาม `docs/qa/01-test-execution-plan.md` (unit + integration + e2e ที่กำหนดไว้)
2. Map test results กลับไปที่ `docs/qa/03-traceability-matrix.md` — mark pass/fail ต่อ requirement
3. ถ้ามี test cases ที่ต้อง manual testing → document results ใน `docs/qa/test-execution-report.md`
4. Fix failing tests (กลับไป `/impl-task` หรือ `/impl-review-fix`)

> ⚠️ **Phase นี้เป็น manual/CI-driven** — ไม่มี dedicated slash command เพราะการรัน test ขึ้นกับ CI pipeline ของแต่ละโปรเจค Agent ช่วยได้ตรง: รัน test suite, วิเคราะห์ failures, map results กลับ traceability matrix

### ✅ จบ Phase 3 เมื่อ:

| Deliverable | ตรวจสอบ |
|---|---|
| Working Code | `services/api/`, `services/web/`, `services/worker/` รัน + ทดสอบได้จริง |
| Tests ผ่าน | Unit + Integration ผ่านทุก service |
| Code Review ผ่าน | ไม่มี CRITICAL/HIGH ค้าง |
| QA Plan approved | Test strategy, test cases, traceability matrix ครบ |
| QA Test Execution | Test cases executed, results mapped to traceability matrix |
| Handoff up-to-date | `docs/state/` อัปเดตล่าสุด |
| Git Commits | Micro-commits มี "Why" ทุก commit |

---

## Phase 4: Harden

> **เป้าหมาย:** ตรวจสอบ อุดรู ทำให้แข็งแกร่ง ก่อนส่งมอบ

### 4A: Red Team Security Audit

> ⚠️ **AI Red Team เป็นแค่ first pass** — ไม่ทดแทน manual security review โดย security engineer LLM ถูก train มาให้ helpful ไม่ได้ถูก train มาให้โจมตี ให้ prompt ที่ specific กับ project เพื่อผลลัพธ์ที่ดีขึ้น

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| โจมตี code | `/red-team all` | Red Team Attacker | `docs/security/red-team-round-01.md` |
| แก้ + โต้ | `/red-team-rebuttal red-team-round-01.md` | Red Team Defender | `docs/security/defense-round-01.md` |
| ทำซ้ำ | `/red-team all` | Red Team Attacker | `red-team-round-02.md` ... |

**Personas:**
- `.agents/skills/andm-red-team-attacker/SKILL.md` — Security Auditor (OWASP Top 10 + STRIDE + 20 security categories + PoC exploits)
- `.agents/skills/andm-red-team-defender/SKILL.md` — Security Engineer (7-step fix + pattern detection + security rules update)

**📖 Workflows:** `.agents/workflows/red-team.md`, `red-team-rebuttal.md` *(narrative guide retired — for on-demand security audit without phase-gate ceremony, use Ship Track's `/red-team`)*

### 4B: Operational Risk Review

ตรวจสอบเพิ่มเติมนอกเหนือ security:
- [ ] Cache invalidation ทำงานถูกต้อง?
- [ ] Concurrent operations มี locking?
- [ ] Background jobs มี retry + alert เมื่อ fail?
- [ ] Data migration handle null/missing data?

### ✅ จบ Phase 4 เมื่อ:

- ✅ ไม่มี CRITICAL/HIGH vulnerability ค้าง
- ✅ `.claude/rules/security.md` ถูก update ด้วย rules ใหม่
- ✅ `docs/design-docs/05-security.md` ถูก update
- ✅ Regression tests ครอบคลุม security fixes
- ✅ **Human reviewed** findings ก่อนปิด loop

> **หมายเหตุ:** `05-security.md` เป็น living document — เริ่มร่างตั้งแต่ Design Phase แล้ว enrich ด้วย Red Team findings ใน Harden Phase (Threat Model, Mitigation Plan, STRIDE results) ไม่ต้องแยกไฟล์

---

## Phase 5: Deliver & Maintain

> **เป้าหมาย:** ส่งมอบ + สร้างระบบให้คนใหม่มาต่อได้

### 1. สร้าง Project Oracle — Knowledge Base ถาวร

**รวมเอกสารทั้งหมดเข้า Knowledge Base Tool** (เช่น NotebookLM, RAG pipeline, หรือ project indexing ของ IDE):
- ทุก ADR จาก `docs/adr/`
- `CLAUDE.md` + Design Docs + Technical Design
- API Specs + Architecture Diagrams
- BA requirements + UX specs

**ผลลัพธ์:** คนใหม่ถามได้ทุกอย่าง
```
"ทำไมเลือก pg_trgm แทน Elasticsearch?"
"ถ้าจะเพิ่ม feature X ต้องแก้ไฟล์ไหนบ้าง?"
"มี security rule อะไรที่ต้องระวัง?"
→ Knowledge Base ตอบได้ทั้งหมดจากเอกสาร
```

### 2. Handoff สำหรับ Maintenance

อัปเดต handoff ฉบับสมบูรณ์ (`docs/state/overview.md` + per-module handoff):
- สถานะ feature ทั้งหมด
- Known issues / Tech debt
- ขั้นตอนการ deploy
- Contact points

### 3. วัดผล

> **สำคัญ:** วัด baseline ก่อนเริ่มใช้ AI workflow อย่างน้อย 2-3 sprints — ถ้าไม่มี baseline ตัวเลขจะไม่มีความหมาย

| ตัวชี้วัด | วิธีวัด | Baseline |
|---|---|---|
| Development time (cycle time) | Ticket created → PR merged | วัดจาก 2-3 sprints ก่อนใช้ AI |
| Onboarding time | คนใหม่เริ่ม contribute ได้ภายในกี่วัน? | วัดจากคนก่อนหน้า |
| Bugs found before deploy | Red Team + Code Review เจอกี่ตัว? | เทียบกับ sprint ก่อนหน้า |
| Delivery cycle | Sprint velocity (story points) | วัดจาก 2-3 sprints ก่อนใช้ AI |
| Code review rejection rate | PR ที่ต้องแก้ / PR ทั้งหมด | วัดจาก sprint ก่อนหน้า |
| Developer satisfaction | Survey (1-5) | ทำ survey ก่อนเริ่มใช้ AI |

**ข้อควรระวัง:** อย่า cherry-pick — วัดทุก task ไม่ใช่เฉพาะ task ที่ AI ทำได้ดี

---

## Navigation & Amendment

กระบวนการพัฒนาปกติเป็น linear แต่ในความเป็นจริงอาจต้องย้อนกลับหรือแก้ไข deliverables ที่สร้างแล้ว:

```
                    Backtrack Flows
                    ──────────────

┌─────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Phase 1  │   │   Phase 2    │   │   Phase 3    │   │   Phase 4    │
│ DESIGN   │◀──│  DESIGN QA   │◀──│  IMPLEMENT   │◀──│   HARDEN     │
│          │   │              │   │              │   │              │
│ BA ◀─────────── SD review   │   │              │   │              │
│ SD ◀─────────── Code review │◀──│── Red Team   │   │              │
│ UX ◀─────────── Impl finds  │   │              │   │              │
└─────────┘   └──────────────┘   └──────────────┘   └──────────────┘

Forward:  ────▶  (ปกติ)
Backward: ◀────  (backtrack — ต้อง human approve)
```

### `/backtrack` — ย้อน Phase เมื่อ Downstream พบปัญหา Upstream

**ใช้เมื่อ:** downstream phase พบปัญหาที่ **แก้ใน phase ตัวเองไม่ได้** เพราะ root cause อยู่ upstream

```
/backtrack ba       ← ย้อนไปแก้ BA requirements
/backtrack sd       ← ย้อนไปแก้ System Design
/backtrack ux       ← ย้อนไปแก้ UX/UI Design
/backtrack td       ← ย้อนไปแก้ Technical Design
```

**ตัวอย่าง Backtrack Triggers:**
- SD Review พบ BA requirement ขัดแย้ง → `/backtrack ba`
- TD Review พบ SD architecture ไม่รองรับ → `/backtrack sd`
- Implementation พบ TD design infeasible → `/backtrack td`
- Red Team พบ architecture flaw → `/backtrack sd`

#### Invalidation Matrix

เมื่อ backtrack ไป phase ใด phase ถัดไปทั้งหมดถูก impact:

| If Changed → | SD | UX | TD | Impl Plan | Impl Code | Code Review | Red Team |
|-------------|----|----|-----|-----------|-----------|-------------|----------|
| **BA** | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| **SD** | — | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **UX** | — | — | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ |
| **TD** | — | — | — | ❌ | ❌ | ❌ | ❌ |

- ⚠️ = needs re-validation (อาจจะยังถูก)
- ❌ = invalidated (ต้อง re-run)

#### Backtrack Process

1. **Identify** — ระบุปัญหาและ upstream root cause
2. **Impact Analysis** — วิเคราะห์ deliverables ที่จะถูก invalidate (`/backtrack` ทำให้อัตโนมัติ)
3. **⏸️ HALT** — user approve ก่อน backtrack (ห้าม auto-backtrack)
4. **Record** — บันทึกใน `docs/state/backtrack-log.md`
5. **Mark** — update `docs/state/overview.md` ด้วย backtrack markers
6. **Rework** — แก้ upstream deliverables เฉพาะจุด (commit prefix `[BACKTRACK BT-XXX]`)
7. **Re-validate** — ตรวจ downstream ที่ถูก impact
8. **Close** — update backtrack log เมื่อเสร็จ

**📖 Guide:** `.andm/development-guide/backtrack-workflow.md`

### `/amend` — แก้ไข Deliverables โดยไม่ต้อง Backtrack

**ใช้เมื่อ:** ต้องการเพิ่ม/เปลี่ยน/ลบ content ใน phase ที่สร้างแล้ว **โดยไม่มีปัญหาจาก downstream**

```
/amend ba "เพิ่ม forgot password flow"
/amend sd "เปลี่ยน caching strategy จาก Redis เป็น Memcached"
/amend ux "เพิ่ม empty state สำหรับหน้า dashboard"
/amend td "เพิ่ม endpoint DELETE /users/:id"
```

**Persona:** `.agents/skills/andm-amend-engineer/SKILL.md` — Senior Design Document Specialist

**Amend Process:**
1. **Parse** — เข้าใจสิ่งที่ต้อง add/change/remove
2. **Impact Analysis** — วิเคราะห์ไฟล์ที่กระทบ + downstream impact
3. **⏸️ HALT** — user approve ก่อน execute
4. **Execute** — แก้ไขเฉพาะจุด (surgical, ไม่ rewrite ทั้ง doc)
5. **Report** — สรุปการเปลี่ยนแปลง + flag downstream ที่ต้อง re-validate

### Backtrack vs Amend — ตัดสินใจอย่างไร

| เกณฑ์ | `/backtrack` | `/amend` |
|-------|-----------|---------|
| Root cause อยู่ upstream, block downstream | ✅ ใช่ | ❌ ไม่ใช่ |
| แค่อยาก evolve/เพิ่ม scope | ❌ ไม่ต้อง | ✅ ใช่ |
| Impact กว้าง (หลาย feature) | ✅ backtrack | ⚠️ พิจารณา |
| เป็น architecture concern | ✅ backtrack | ❌ ไม่ควร patch |
| Downstream phases ถูก invalidate | ✅ มี invalidation matrix | ❌ แค่ flag ให้ทราบ |
| มี backtrack log + markers | ✅ มี | ❌ ไม่มี |

**Rule of thumb:** ถ้าต้อง "assume" อะไรที่ upstream ควรระบุไว้ → backtrack | ถ้าแค่อยากเพิ่มของใหม่ → amend

### `/next` — Auto-detect Phase & Recommend Next Action

**ใช้เมื่อ:** ไม่แน่ใจว่าทำอะไรต่อ

```
/next
```

Agent จะอ่าน project state (`docs/state/overview.md`, existing deliverables) แล้วแนะนำ command ที่ควรรันถัดไป

---

## Agent Personas

| Persona | SKILL.md | Role | Phase |
|---------|----------|------|-------|
| **BA Reviewer** | `.agents/skills/andm-ba-reviewer/` | Adversarial BA Consultant (20 attack vectors) | Design QA |
| **BA Defender** | `.agents/skills/andm-ba-defender/` | Constructive BA Defense (Accept/Partial/Reject) | Design QA |
| **SD Reviewer** | `.agents/skills/andm-sd-reviewer/` | Adversarial Architect (20 attack vectors) | Design QA |
| **SD Defender** | `.agents/skills/andm-sd-defender/` | Constructive Architect (+ ADR updates) | Design QA |
| **TD Reviewer** | `.agents/skills/andm-td-reviewer/` | Adversarial Engineer (20 attack vectors + cross-domain) | Design QA |
| **TD Defender** | `.agents/skills/andm-td-defender/` | Constructive Architect (7-step + cascade check) | Design QA |
| **QA Reviewer** | `.agents/skills/andm-qa-reviewer/` | Adversarial QA Consultant (15 attack vectors) | Implement (QA Plan) |
| **QA Defender** | `.agents/skills/andm-qa-defender/` | Constructive QA Defense (Accept/Partial/Reject) | Implement (QA Plan) |
| **Impl Planner** | `.agents/skills/andm-impl-planner/` | Tech Lead / Sprint Planner | Implement |
| **Impl Engineer** | `.agents/skills/andm-impl-engineer/` | Senior Full-Stack Engineer | Implement |
| **Code Reviewer** | `.agents/skills/andm-code-reviewer/` | Adversarial Quality Engineer (13 dimensions incl. Empirical AC Closure / Functional CRUD walk / Configuration Completeness) | Implement |
| **Red Team Attacker** | `.agents/skills/andm-red-team-attacker/` | Security Auditor (OWASP + STRIDE) | Harden |
| **Red Team Defender** | `.agents/skills/andm-red-team-defender/` | Security Engineer (7-step fix) | Harden |
| **UX Reviewer** | `.agents/skills/andm-ux-reviewer/` | Adversarial UX Consultant (22 attack vectors) | Design QA |
| **UX Defender** | `.agents/skills/andm-ux-defender/` | Constructive UX Defense | Design QA |
| **Amend Engineer** | `.agents/skills/andm-amend-engineer/` | Senior Design Document Specialist | Navigation |
| **Deliver Handoff Engineer** | `.agents/skills/andm-deliver-handoff/` | Delivery Readiness + Final Handoff | Deliver |
| **UX Designer** | (manual / Stitch / Figma) | UX/UI Visual Designer | Design |

---

## Command Quick Reference

| Phase | Command | Description | เมื่อไร |
|-------|---------|-------------|---------|
| **Design** | `/ux-design <mode>` | สร้าง UX deliverables (stitch / figma / existing / reference / frontend / claude-design / auto) | หลังมี BA + SD docs ครบ |
| **Design QA** | `/ba-review <target>` | ตรวจ BA docs | หลังสร้าง BA deliverables |
| **Design QA** | `/ba-rebuttal <file>` | แก้/โต้ BA findings | หลัง ba-review |
| **Design QA** | `/sd-review <target>` | ตรวจ design docs | หลังสร้าง design deliverables |
| **Design QA** | `/sd-rebuttal <file>` | แก้/โต้ SD findings | หลัง sd-review |
| **Design QA** | `/ux-review <target>` | ตรวจ UX deliverables (22 core + 3 extended attack vectors) | หลังสร้าง UX deliverables |
| **Design QA** | `/ux-rebuttal <file>` | แก้/โต้ UX findings (Option A — full) | หลัง ux-review |
| **Design QA** | `/ux-fix <file>` | แก้ UX findings ตรงๆ (Option B — lite) | หลัง ux-review (ประหยัด token) |
| **Design QA** | `/td-review <target>` | ตรวจ technical design docs | หลังสร้าง TD deliverables |
| **Design QA** | `/td-rebuttal <file>` | แก้/โต้ TD findings | หลัง td-review |
| **Implement** | `/impl-plan <sprint>` | สร้าง sprint plan | หลัง design QA ผ่าน |
| **Implement** | `/impl-task <task-id>` | implement task (auto-detect size) | หลัง impl-plan approved |
| **Implement** | `/impl-review <target>` | ตรวจ code quality + design compliance | หลัง sprint tasks เสร็จ |
| **Implement** | `/impl-review-fix <file>` | แก้ code review findings | หลัง impl-review |
| **QA Plan** | `/qa-review <target>` | ตรวจ QA Plan deliverables | หลังสร้าง QA docs (parallel กับ impl) |
| **QA Plan** | `/qa-rebuttal <file>` | แก้/โต้ QA findings | หลัง qa-review |
| **Harden** | `/red-team <target>` | security audit code (OWASP + STRIDE) | หลัง code review ผ่าน |
| **Harden** | `/red-team-rebuttal <file>` | fix vulnerabilities | หลัง red-team |
| **Deliver** | `/deliver <scope>` | final delivery handoff + readiness assessment | หลัง red team ผ่าน |
| **Navigation** | `/amend <phase> "<desc>"` | แก้ไข/เพิ่มเติม deliverables (ba/sd/ux/td) | เมื่อต้องการ evolve content |
| **Navigation** | `/backtrack <phase>` | ย้อน phase + impact analysis | เมื่อ downstream พบปัญหา upstream |
| **Navigation** | `/next` | auto-detect phase + recommend next action | เมื่อไม่แน่ใจว่าทำอะไรต่อ |

---

## Quick Reference — File Structure

```
project/
├── CLAUDE.md                        ← กฎกลาง (AI ทุกตัวอ่าน)
├── .claude/rules/                   ← Per-topic AI rules
│   ├── security.md
│   ├── testing.md
│   ├── web.md
│   ├── api.md
│   └── workflow.md
├── .agents/                        ← Methodology source of truth
│   ├── skills/                      ← Agent personas (SKILL.md per persona)
│   ├── workflows/                   ← Platform-agnostic workflow definitions
│   │   └── manifest.json            ← Workflow registry
│   └── agents/                      ← Claude Code subagents
├── .andm/
│   ├── constitution/                ← Runbook + sample CLAUDE.md template
│   ├── development-guide/           ← Step-by-step workflow guides
│   ├── prompt-templates/            ← Direct-use prompts (BA, SD, UX, TD, QA)
│   │   └── quick-start.md           ← Phase detection + next action guide
│   └── simulation/                  ← Methodology test scenarios
├── docs/
│   ├── ba/                          ← BA deliverables (01-05) + claim-review
│   │   ├── 01-project-brief.md
│   │   ├── ...
│   │   ├── 05-user-flows.md
│   │   └── claim-review-and-rebuttal/
│   ├── design-docs/                 ← System Design (02-08, gaps ที่ 01/06) + claim-review
│   │   ├── 02-high-level-architecture.md  # incl. Requirements Traceability + ADR Digest
│   │   ├── 03-deep-dive.md
│   │   ├── 04-data-flow.md
│   │   ├── 05-security.md
│   │   ├── 07-future-evolution.md
│   │   ├── 08-product-breakdown.md
│   │   └── claim-review-and-rebuttal/
│   ├── technical-design/            ← Technical Design (02, 03, 04) + claim-review
│   │   ├── 02-backend-design.md
│   │   ├── 03-frontend-design.md
│   │   ├── 04-database-design.md
│   │   └── claim-review-and-rebuttal/
│   ├── ux/                          ← UX/UI deliverables (01-05) + claim-review
│   │   ├── 01-design-tokens.md
│   │   ├── ...
│   │   ├── 05-interaction-patterns.md
│   │   └── claim-review-and-rebuttal/
│   ├── adr/                         ← Architecture Decision Records
│   ├── api-specs/                   ← OpenAPI YAML contracts
│   ├── qa/                          ← QA Plan deliverables
│   │   ├── 01-test-execution-plan.md
│   │   ├── 02-test-cases/TC-*.md
│   │   ├── 03-traceability-matrix.md
│   │   └── claim-review-and-rebuttal/
│   ├── code-review/                 ← Code review rounds
│   │   ├── review-round-XX.md
│   │   └── fix-round-XX.md
│   ├── security/                    ← Red team rounds
│   │   ├── red-team-round-XX.md
│   │   └── defense-round-XX.md
│   └── state/                       ← Project state & handoff
│       ├── overview.md
│       ├── impl-plan.md
│       ├── backtrack-log.md
│       ├── api/handoff.md
│       ├── web/handoff.md
│       └── worker/handoff.md
├── services/                        ← Source code (tech stack ตาม CLAUDE.md)
│   ├── api/
│   ├── web/
│   └── worker/
└── .env                             ← Secrets (อยู่ใน .gitignore)
```

> Development-guide notes: `impl-workflow.md`, `impl-review-workflow.md`, `qa-plan-workflow.md`, `red-team-workflow.md`, `deliver-workflow.md` retired in 2026-05-07 cleanup → read `.agents/workflows/<name>.md` directly. For MVP / market-race work, use Ship Track instead.

---

## Typical Timeline

| Phase | Duration | Rounds |
|-------|----------|--------|
| **Design (BA)** | 1-2 days | — |
| **BA Review/Rebuttal** | 2-3 rounds (1 day) | 2-3 |
| **Design (SD)** | 1-2 days | — |
| **SD Review/Rebuttal** | 2-3 rounds (1 day) | 2-3 |
| **UX/UI Design** | 0.5-1 day | — |
| **UX Approve** | 1 round (0.5 day) | 1 |
| **Technical Design (TD)** | 0.5-1 day | — |
| **TD Review/Rebuttal** | 2-3 rounds (1 day) | 2-3 |
| **Implementation** | 1-2 sprints (2-5 days) | — |
| **QA Planning** | 1-2 days (parallel กับ impl) | 2-3 |
| **Code Review** | 2-3 rounds (1 day) | 2-3 |
| **Red Team** | 2-3 rounds (1 day) | 2-3 |
| **Deliver** | 0.5 day | — |
| **Total** | ~2.5 weeks for MVP | — |

---

## Golden Rules

1. **เปิด session ใหม่ทุกครั้ง** — persona onboarding ต้อง fresh
2. **Human-in-the-loop** — ทุก HALT point ต้องมีคนตรวจก่อน approve
3. **อย่าให้ AI อนุมัติ AI** — review/rebuttal loop ต้องมีคน approve ก่อนปิด
4. **Anti-duplication** — ทุก round จะไม่ raise finding ซ้ำที่ fix แล้ว
5. **Contextual commits** — ทุก commit ต้องมี "Why" ไม่ใช่แค่ "What"
6. **Living documents** — security rules, design docs จะ evolve ตลอด lifecycle
7. **Measure** — วัด baseline ก่อนเริ่ม เพื่อเปรียบเทียบหลังจบ
8. **Backtrack > Patch** — ถ้า root cause อยู่ upstream → ย้อนแก้ อย่า patch downstream
9. **Empirical Closure** — task ที่มี Empirical AC ปิดด้วย structural test pass อย่างเดียวไม่ได้ ต้องมี evidence artifact จาก deployed/running system + Phase Gates blocking + Deferred-AC Registry สำหรับ legitimate defers (post-Shark-CMS dogfood revision 2026-04 — closes "deferred operator-runtime" loophole that produced 71% defect rate in real-project audit)

---

> **หลักคิดสำคัญ:** เราคือ **Senior Developer ที่มี AI เป็นเครื่องมือ** — วางแผน, สั่งการ, ตรวจรับ, และรับผิดชอบผลลัพธ์ แต่ยังต้อง **อ่านโค้ดได้ ยังต้อง debug ได้** เพียงแต่ไม่ต้องพิมพ์ทุกบรรทัดเอง
>
> ⚠️ **ข้อควรระวัง:** AI สร้างโค้ดที่ "ดูถูก" แต่มี bug ซ่อนได้เสมอ — โดยเฉพาะด้าน security และ performance ยิ่ง developer มี skill level สูง ยิ่ง review ได้ดี ยิ่งได้ผลลัพธ์ที่ดี Skill level ของ developer ยังคงสำคัญมาก
