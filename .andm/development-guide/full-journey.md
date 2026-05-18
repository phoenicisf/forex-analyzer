# AI-Native Development — Full Journey Guide

ภาพรวมทั้งหมดของ lifecycle ตั้งแต่ไอเดียจนถึง production-ready code ผ่าน multi-agent workflow

---

## The 5 Phases

```
Phase 1        Phase 2          Phase 3           Phase 4          Phase 5
DESIGN    →    DESIGN QA    →   IMPLEMENT    →    HARDEN     →    DELIVER
(สร้าง)        (กรองคุณภาพ)      (เขียน code)      (อุดรูรั่ว)       (ส่งมอบ)
```

```
┌─────────┐   ┌──────────────┐   ┌──────────────────────────────────┐   ┌──────────────┐   ┌──────────┐
│ Phase 1 │   │   Phase 2    │   │          Phase 3                 │   │   Phase 4    │   │ Phase 5  │
│ DESIGN  │──▶│  DESIGN QA   │──▶│  ┌─────────────────────────┐    │──▶│   HARDEN     │──▶│ DELIVER  │
│         │◀──│              │   │  │ 3A-C: IMPLEMENT          │    │   │              │   │          │
│ BA docs │   │ BA review    │   │  │ Sprint plan → Impl tasks │    │   │ Red Team     │   │ Knowledge│
│ SD docs │   │ BA rebuttal  │   │  │ Working code + Tests     │    │   │ Defense      │   │ Base     │
│ ADRs    │   │ SD review    │   │  │ Code review + fixes      │    │   │ Security     │   │ Final    │
│ API specs│  │ SD rebuttal  │   │  └─────────────────────────┘    │   │ rules update │   │ handoff  │
│ UX specs│   │ UX review    │   │         parallel                 │   │              │   │          │
│ TD specs│   │ TD review    │   │  ┌─────────────────────────┐    │   │              │   │          │
│         │   │              │   │  ┌─────────────────────────┐    │   │              │   │          │
│         │   │              │   │  │ 3Q: QA PLANNING          │    │   │              │   │          │
│         │   │              │   │  │ Test strategy + plan     │    │   │              │   │          │
│         │   │              │   │  │ Test cases + traceability│    │   │              │   │          │
│         │   │              │   │  │ QA review + rebuttal     │    │   │              │   │          │
│         │   │              │   │  └─────────────────────────┘    │   │              │   │          │
└─────────┘   └──────────────┘   └──────────────────────────────────┘   └──────────────┘   └──────────┘
          ◀── backtrack (/backtrack ba|sd|ux) ──◀
```

---

## Phase 0: Idea Refinement — ก่อนเริ่ม Design (Optional)

> **เมื่อไหร่ใช้:** เมื่อเริ่มจาก vague idea หรือ brief ที่ยังไม่ชัด — ก่อนที่ BA จะเริ่มเขียน requirements
> **ข้ามได้เมื่อ:** requirements ชัดเจนแล้ว, มี BRD/PRD พร้อม, หรือเป็น brownfield project ที่ scope ถูกกำหนดแล้ว

### กระบวนการ Idea Refinement

```
Diverge (สร้างตัวเลือก)    →    Converge (เลือก + ตัด)    →    BA-Ready Brief
```

**Step 1 — Frame the Problem:**
- ตั้งคำถาม "How Might We...?" (HMW) จาก pain point / opportunity
- Example: "How might we ลดเวลาที่ลูกค้าใช้ในการ checkout จาก 5 นาทีเหลือ 1 นาที?"

**Step 2 — Generate Variations (Divergent Thinking):**
- สร้าง 5-8 variations ผ่าน lenses ต่างๆ:

| Lens | คำถาม | ตัวอย่าง |
|------|--------|---------|
| **Inversion** | ถ้าทำตรงข้ามจะเป็นยังไง? | แทนที่จะลด steps → เพิ่ม steps แต่ทำให้แต่ละ step เร็วขึ้น |
| **Constraint Removal** | ถ้าไม่มี constraint X จะทำอะไร? | ถ้า budget ไม่จำกัด → build custom payment gateway |
| **Audience Shift** | ถ้า user เป็นคนอื่นจะต้องการอะไร? | ถ้าเป็น elderly user → voice-guided checkout |
| **Simplification** | ทำให้เรียบง่ายที่สุดได้แค่ไหน? | 1-click buy (Amazon style) |
| **10x Scale** | ถ้า scale 10 เท่าจะเปลี่ยนอะไร? | ถ้า 10x orders → need queue-based processing |

**Step 3 — Stress Test & Select:**
- ตรวจ feasibility, business value, technical risk ของแต่ละ variation
- เลือก 1-2 directions ที่ดีที่สุด
- สร้าง "Not Doing" list — สิ่งที่ตัดสินใจไม่ทำ (สำคัญเท่ากับสิ่งที่ทำ)

**Step 4 — Output BA-Ready Brief:**
- Problem statement ที่ชัดเจน
- Chosen direction + rationale
- Not Doing list
- Open questions ที่ BA ต้อง explore ต่อ

### Artifacts

| Artifact | Path |
|----------|------|
| **Slash command** | `/ideate "<pain-point>"` หรือ `/ideate` (interactive) หรือ `/ideate resume` |
| **Prompt template** | `.andm/prompt-templates/idea-refinement-prompt.md` |
| **Workflow definition** | `.agents/workflows/ideate.md` |
| **Agent persona** | `.agents/agents/andm-ideation-facilitator.md` |
| **Development guide** | `.andm/development-guide/ideate-workflow.md` (full walkthrough + example brief) |
| **Output file** | `docs/foundation-input-sources/ideation-brief.md` |

> **Output consumption:** `/ba` workflow (wraps `.andm/prompt-templates/ba-requirements-prompt.md`) อ่าน `docs/foundation-input-sources/` อัตโนมัติ — ไม่ต้อง manual handoff ไป Phase 1

---

## Phase 1: Design — สร้างเอกสารออกแบบ

> [!WARNING]
> **Template Inheritance Guard** — ไฟล์นี้เป็น **methodology guide** ไม่ใช่ tech stack specification
> Tech stack และ service names ที่กล่าวถึง (เช่น `services/api`, `services/web`) เป็น **ตัวอย่าง monorepo layout เท่านั้น**
> ให้อ้างอิง tech stack จาก `CLAUDE.md` ของโปรเจค ไม่ใช่จาก guide นี้

### 1A: BA Deliverables

**ใครทำ:** BA Agent
**Command:** `/ba` (หรือ `/ba "<focus hint>"`)
**Workflow:** `.agents/workflows/ba.md` (wraps `.andm/prompt-templates/ba-requirements-prompt.md` + adds Phase 0 onboarding + Phase 3 quality gate enforcement)
**Output:** `docs/ba/01-05` (v1.2: 06-handoff dropped)

```
docs/ba/
  01-project-brief.md
  02-functional-requirements.md
  03-non-functional-requirements.md
  04-business-rules.md
  05-user-flows.md
```

> **v1.2 change:** `06-handoff-to-architecture.md` removed — open questions/risks live ใน relevant doc ตาม domain (FR→02, NFR→03, rule→04, flow→05)

### 1B: System Design Deliverables

**ใครทำ:** Architect Agent
**Command:** `/sd` (หรือ `/sd "<focus hint>"`)
**Workflow:** `.agents/workflows/sd.md` (wraps `.andm/prompt-templates/system-design-master-prompt.md` + adds Phase 0 onboarding + Phase 3 quality gate including schedule-leakage check)
**Output:** `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06 — merged into 02) + `docs/adr/` + `docs/api-specs/`

```
docs/design-docs/
  02-high-level-architecture.md    ← Requirements Traceability + Components/services/communication + Glossary + ADR Digest (v1.2: absorbed 01 + 06)
  03-deep-dive.md                  ← Critical technical challenges
  04-data-flow.md                  ← Sequence diagrams, timing budgets
  05-security.md                   ← Defense layers, threat model
  07-future-evolution.md           ← Scaling triggers + migration paths + Evolution Sequence (E1/E2/...)
  08-product-breakdown.md          ← Work inventory + Phase Hints (Suggested P1-P4) + Per-Task Metadata

docs/adr/NNN-title.md
docs/api-specs/*.yaml
```

> ⚠️ **SD ให้ architectural hints ได้ แต่ไม่ทำ delivery schedule (Option C)** — SD อาจมี Evolution Sequence (ใน 07, hard constraints) และ Phase Hints (ใน 08, soft suggestions) ได้ทั้งหมดต้องมี architectural rationale. **Final phasing decision + sprint numbers + timelines** เป็นหน้าที่ของ Impl Planner ใน Phase 3 (`/impl-plan`).

### 1C: UX/UI Design Deliverables

**ใครทำ:** UX Designer Agent (หรือ Human Designer)
**Mode:** เลือกตาม context ของโปรเจค
**Input:** `docs/ba/05-user-flows.md` + `docs/design-docs/02-high-level-architecture.md` + `docs/api-specs/`
**Output:** `docs/ux/01-05` (UX-06 dropped in SD-as-Master consolidation)

| Mode | เมื่อไหร่ใช้ | เครื่องมือ |
|------|-------------|----------|
| **A: AI-Generated** | Greenfield, ยังไม่มี design | Stitch (Google) / Brainstorming visual companion |
| **B: Figma-First** | มี designer / มี Figma file | Figma + Figma MCP server |
| **C: Existing UI Audit** | Brownfield, มี UI อยู่แล้ว | Manual audit + screenshot analysis |
| **D: Frontend Build** | ต้องสร้าง production UI ตรง (landing page, dashboard, app shell) | `frontend-design` + `dashboard-builder` + `liquid-glass-design` skills |
| **E: Reference-Driven** | มี reference website เป็นต้นแบบ visual style | `ux-design-reference-prompt.md` + user-supplied `design-reference/*-DESIGN.md` (acquisition per [`ux-design-reference-acquisition.md`](./ux-design-reference-acquisition.md)) |
| **F: Claude Design** | ต้องการ interactive visual iteration (comments/sliders), มี Pro/Max/Team/Enterprise subscription | `ux-design-claude-design-prompt.md` + Claude Design (Anthropic Labs) |

```
docs/ux/
  01-design-tokens.md              ← Colors, typography, spacing, shadows
  02-component-inventory.md        ← Components + variants + states + priority
  03-page-layouts.md               ← Wireframe/layout ทุกหน้า
  04-navigation-structure.md       ← Sitemap + breadcrumb UX + nav labels + auth guards (routing authority: TD 03-frontend-design)
  05-interaction-patterns.md       ← Forms, loading, empty, error, responsive

  (06-handoff-to-implementation.md — DROPPED in SD-as-Master consolidation;
   TD-02/03 และ Impl Planner อ่าน UX-01..05 โดยตรง)
```

**📖 Guide:** `.andm/development-guide/ux-design-workflow.md`

> **Output ของ 1C (UX) เป็น input ของ 1D (TD)** — ต้องสร้าง UX deliverables ให้ครบก่อนเริ่ม Technical Design

### 1D: Technical Design Deliverables (Detailed / Low-Level Design)

**ใครทำ:** Technical Architect Agent
**Command:** `/td` (หรือ `/td "<focus hint>"`)
**Workflow:** `.agents/workflows/td.md` (wraps `.andm/prompt-templates/technical-design-master-prompt.md` + adds Phase 0 onboarding + Phase 3 quality gate including SD-as-Master scope contract + cross-domain consistency check)
**ต้องมีก่อน:** ✅ SD docs ครบ + ✅ UX docs ครบ (ผ่าน review ยิ่งดี) + ✅ ADRs ≥ 1 + ✅ api-specs/*.yaml ≥ 1
**Input:** `docs/design-docs/02-08` (v1.2: gaps 01/06) + `docs/ux/01-05` + `docs/adr/` + `docs/api-specs/` + `.claude/rules/`
**Output:** `docs/technical-design/02, 03, 04` (01/05/06/07/08 dropped in SD-as-Master; numbering preserved)

```
docs/technical-design/
  02-backend-design.md             ← Class/module structure, interfaces, DTOs, CQRS handlers, DI map,
                                     pattern code skeletons (decisions in ADRs), optional Flow Appendix
  03-frontend-design.md            ← Component tree, state management, routing config (authoritative),
                                     data fetching, error boundaries
  04-database-design.md            ← Column-level schema, constraints, indexes, migrations, seed data

  (01, 05, 06, 07, 08 — DROPPED in SD-as-Master consolidation; numbering gaps preserved intentionally)
```

> ⚠️ **TD-01/05/06/07/08 were removed in SD-as-Master consolidation** — content moved to authoritative sources:
>
> | Dropped | Content moved to |
> |---------|------------------|
> | **TD-01 API Contracts** | `docs/api-specs/*.yaml` (full OpenAPI + validation + error schemas + auth/rate-limit) |
> | **TD-05 Design Patterns** | `docs/adr/` (pattern decisions) + code skeletons inline ใน TD-02 |
> | **TD-06 Sequence Diagrams** | Flow-level ใน SD `04-data-flow.md` + method-level ใน TD-02 § Flow Appendix |
> | **TD-07 Test Strategy** | `docs/qa/01-test-execution-plan.md` (authoritative — design + execution strategy รวมกัน) |
> | **TD-08 Handoff** | Impl Planner อ่าน SD `07-future-evolution.md` + `08-product-breakdown.md` โดยตรง |
>
> File numbering (02/03/04) ถูก preserved เพื่อให้ downstream tooling, ADRs, และ code-review citations ที่อ้างเลขไฟล์เดิมยังใช้ได้

**📖 Guide:** `.andm/development-guide/td-workflow.md`

---

## Phase 2: Design QA — กรองคุณภาพเอกสาร

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
| แก้ตรง (Option B) | `/ux-fix claim-review-01.md` | — | fixed docs/ux/ + report |
| ทำซ้ำ | `/ux-review all` | UX Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-ux-reviewer/SKILL.md` ��� Adversarial UX Consultant (22 UX attack vectors)
- `.agents/skills/andm-ux-defender/SKILL.md` — Constructive UX Defense (Accept/Partial/Reject)

> **Option A vs B:** ใช้ `/ux-rebuttal` (Option A) เป็นค่า default — มี structured verdict + evidence
> ถ้า token budget จำกัดหรือ findings เป็น LOW/MEDIUM → ใช้ `/ux-fix` (Option B) ประหยัดกว่า ~50%

**📖 Guide:** `.andm/development-guide/ux-design-workflow.md` → Step 3

**Extended Review (Optional — เมื่อมี code ใน `services/web/`):**

| # | Category | Skill Used | ตรวจอะไร |
|---|----------|-----------|---------|
| 23 | Design System Consistency | `design-system` (audit) | คะแนน 10 มิติ: color, typography, spacing, components, responsive, dark mode, animation, a11y, density, polish |
| 24 | AI Slop Detection | `design-system` (slop-detect) | Generic AI patterns: gratuitous gradients, overused glassmorphism, stock hero layouts |
| 25 | Click-Path Behavioral Bugs | `click-path-audit` | 6 bug patterns: Sequential Undo, Async Race, Stale Closure, Missing Transition, Dead Path, useEffect Interference |

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

### เมื่อผ่าน Phase 2:
- ✅ BA docs ผ่าน review (ไม่มี CRITICAL/HIGH ค้าง)
- ✅ Design docs ผ่าน review
- ✅ ADRs up-to-date
- ✅ API specs consistent
- ✅ UX deliverables approved (design tokens, components, layouts) — UX-01..05
- ✅ TD docs ผ่าน review (cross-domain consistency: API-specs↔DB↔Frontend↔UX) — TD-02, 03, 04
- ✅ Impl Planner พร้อมอ่าน SD `07-future-evolution.md` + `08-product-breakdown.md` โดยตรงเป็น implementation blueprint (TD-08 handoff dropped in SD-as-Master)

---

## Phase 2.5: Project Bootstrap — Derive CLAUDE.md from Approved TD

> **Bridge workflow** ระหว่าง Design QA (Phase 2) กับ Implement (Phase 3) — ไม่ใช่ lifecycle phase ใหม่ แต่เป็น one-shot generator ที่ derive project rules จาก approved TD
>
> **ทำไมต้อง Phase 2.5:** ถ้าเขียน `CLAUDE.md` + `.claude/rules/*` ก่อน Phase 1D (TD) — จะ bias architect/engineer ไปทาง template defaults (เช่น template บอก "API: C# .NET 9" → architect bias ไป .NET แม้ว่า Go/Rust จะเหมาะกว่าตาม NFR). Phase 2.5 lock stack bias ไว้ที่ TD decisions ไม่ใช่ template.

### 2.5A: Generate Project-Specific Rules

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| สร้าง project rules | `/project-init` | Project-Init Engineer | root `CLAUDE.md` + `AGENTS.md` + `.claude/rules/*.md` + `.claude/stack.json` + IDE mirrors (engineer subagents stay generic — no retrofit) |
| Re-gen หลัง TD เปลี่ยน | `/project-init --regen` | Project-Init Engineer | same output + `.bak-<ts>` backups of old files |
| Targeted edit | `/project-init --amend "<desc>"` | Project-Init Engineer | surgical edit of existing generated rules |

**Persona:** `.agents/skills/andm-project-init-engineer/SKILL.md` — Senior Platform Engineer / Project Scaffolding Specialist

**Process (2-3 HALT protocol — HALT 0 conditional, HALTs 1-2 mandatory):**
1. **Pre-flight** — verify TD approved (no CRITICAL/HIGH pending); classify existing CLAUDE.md state (template / customized / diverged)
2. **Extract tech facts** — parse TD 02/03/04 + ADRs + BA 01 + api-specs + UX 01-02 into structured fact sheet
3. **Gap check** — if MUST-have facts missing (project.name, service language, DB engine, auth_flow) → HALT with gap report; do not invent defaults
4. **⏸️ HALT 1** — user reviews root `CLAUDE.md` + `AGENTS.md` diff
5. **⏸️ HALT 2** — user reviews `.claude/rules/*.md` per-file diffs
6. **Mirror** — propagate to `.windsurf/rules/` + `.trae/rules/` (unless `--ide=` restricts)
7. **Fingerprint** — write `.claude/stack.json` with TD commit + ADRs cited + service facts
8. **Summary** — suggest commit message; user commits when satisfied (no auto-commit)

> ℹ️ Engineer subagents (`andm-{backend,frontend,impl}-engineer`, `andm-qa-testing`) stay stack-agnostic. They read `.claude/rules/*.md` at runtime. `/project-init` never edits subagent files — that's what keeps them portable across projects.

**📖 Guide:** `.andm/development-guide/project-init-workflow.md`

### Multi-IDE Output (4 tiers)

| Tier | Target IDE | Input | Per-IDE Rules |
|------|-----------|-------|---------------|
| T1 | All IDEs (universal) | root `CLAUDE.md` | — |
| T1b | Antigravity + fallback | root `AGENTS.md` | — |
| T2 | Claude Code | `CLAUDE.md` + `.claude/rules/*` + `.claude/stack.json` | Full tier (`.claude/agents/*` are methodology-managed, not retrofitted) |
| T3 | Windsurf | `CLAUDE.md` + `.windsurf/rules/*` | Mirror of `.claude/rules/` |
| T4 | TRAE | `CLAUDE.md` + `.trae/rules/*` | Mirror of `.claude/rules/` |

Restrict with `--ide=<list>` (default: all 4).

### Drift Detection

Script: `bash scripts/validate-rules-sync.sh` — exits non-zero if TD/ADR changes after last `/project-init` run. Optional pre-commit / CI hook.

### เมื่อผ่าน Phase 2.5:
- ✅ Root `CLAUDE.md` reflects actual tech stack from TD (ไม่ใช่ template defaults)
- ✅ `.claude/rules/*.md` per-service files derived จาก TD (cited in inline comments)
- ✅ Engineer subagents stay generic — they read `.claude/rules/*.md` at runtime (portable across projects)
- ✅ `.claude/stack.json` fingerprint recorded (TD commit + ADRs cited)
- ✅ IDE mirrors (`.windsurf/rules/`, `.trae/rules/`) created ตาม `--ide` flag
- ✅ `*.local.md` override files preserved ถ้ามี
- ✅ Ready for `/impl-plan` — Impl Planner reads `CLAUDE.md` + `.claude/rules/` + `.claude/stack.json` เป็น project context

---

## Phase 3: Implement — เขียน Code (Phase-Grouped with SD Hints)

> ⭐ Phase 3 = ที่ Impl Planner ทำ **final phase decision** — SD ให้ **architectural hints** (Evolution Sequence + Phase Hints ใน 07 และ 08), TD ส่งต่อ hints, Impl Planner honor หรือ override พร้อม documented rationale ตาม Option C protocol

### 3A: สร้าง Phase-Grouped Implementation Plan (Option C) + Plan QA Loop

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| สร้าง plan | `/impl-plan 1` | Impl Planner | `docs/state/impl-plan.md` (P1/P2/P3/P4 + phase gates + SD Hint Alignment audit trail) |
| ตรวจ plan | `/impl-plan-review all` | Impl Plan Reviewer | `docs/state/impl-plan-claim-review-and-rebuttal/claim-review-01.md` (10 dimensions) |
| แก้ + โต้ | `/impl-plan-rebuttal claim-review-01.md` | Impl Plan Defender | `rebuttal-round-01.md` + plan updates |
| ทำซ้ำ | `/impl-plan-review all` | Impl Plan Reviewer | `claim-review-02.md` ... จนผ่าน |

> **Why Plan QA loop is mandatory:** real-project audit (Shark CMS, 2026-04) ran `/impl-plan` once with no review pair → 53 closed tasks across two phases → 9 functional defects + 11 IMPL-FIX-* recovery tasks. Plan QA mirrors BA/SD/UX/TD review pattern that catches Silent Copy / forbidden closure pre-authoring / phase boundary violations / state drift before engineer execution.

**Persona:** `.agents/skills/andm-impl-planner/SKILL.md` — Tech Lead / Sprint Planner **ผู้เดียวที่ถือ final Phasing Decision**

**Default Phase Taxonomy:**
- **P1 Foundation** (20-30%) — infra, auth, DB, CI/CD → gate: dev env e2e + smoke test
- **P2 Core** (40-50%) — MVP primary user value → gate: primary flow e2e + critical tests
- **P3 Polish** (20-30%) — Should-Haves, NFRs, observability → gate: Must/Should done + NFR targets
- **P4 Stretch** (0-10%, optional) — Could-Haves → gate: ship or defer to backlog

> Custom phase shapes available (API-only, data migration, brownfield refactor) — ดู `.agents/skills/andm-impl-planner/SKILL.md`

**Option C Protocol:**
1. อ่าน SD's **Evolution Sequence** (hard constraints, ADR-backed) จาก `07-future-evolution.md`
2. อ่าน SD's **Phase Hints** (soft suggestions) + **Per-Task Metadata** จาก `08-product-breakdown.md`
3. รัน phase assignment rules ของตัวเอง (Dependency → MoSCoW → Risk → Value → Service-coupling) อย่าง independent
4. เปรียบเทียบ: align ✅ / diverge ⚠️ / violation 🔴 (backtrack) / no hint ◻️
5. Document ทุก task ใน **Phasing Rationale — SD Hint Alignment** audit trail (mandatory)

### 3B: Implement ทีละ Task (ภายใน Phase)

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ทำ task | `/impl-task IMPL-001` | Impl Engineer | working code + tests + commit |
| ทำ task | `/impl-task IMPL-002` | Impl Engineer | working code + tests + commit |
| ... | ... | ... | ... |

**Persona:** `.agents/skills/andm-impl-engineer/SKILL.md` — Senior Full-Stack Engineer

**Auto-detect size:**
- **XS-S** → single prompt
- **M** → 3-step (plan → implement → review) — applies to `[api]`/`[web]`/`[worker]` **and** `[slice]` (multi-service variant)
- **L-XL** → per-layer decomposition with HALT per step *(exception path only — default is Planner decomposing into `[slice]` sub-tasks; see `andm-impl-planner/SKILL.md § Vertical Slicing Strategy`)*

**📖 Workflows:** `.agents/workflows/impl-plan.md`, `impl-plan-review.md`, `impl-plan-rebuttal.md`, `impl-task.md` *(narrative impl-workflow guide retired — read workflows directly; for MVP / market-race work use Ship Track instead)*

### 3C: Code Review (หลัง Sprint Tasks เสร็จ)

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| ตรวจ code | `/impl-review all` | Code Reviewer | `docs/code-review/review-round-01.md` |
| แก้ + โต้ | `/impl-review-fix review-round-01.md` | Impl Engineer | `docs/code-review/fix-round-01.md` |
| ทำซ้ำ | `/impl-review all` | Code Reviewer | `review-round-02.md` ... |

**Personas:**
- `.agents/skills/andm-code-reviewer/SKILL.md` — Adversarial Quality Engineer (13 review dimensions incl. Empirical AC Closure / Functional CRUD walk / Configuration Completeness — full table: SKILL.md § Phase 1)
- `.agents/skills/andm-impl-engineer/SKILL.md` — Senior Full-Stack Engineer (fixing mode)

**📖 Workflows:** `.agents/workflows/impl-review.md`, `impl-review-fix.md` *(narrative guide retired — read workflows directly)*

### 3Q: QA Planning (Parallel กับ 3A-3C)

> ทำงาน **parallel** กับ Implementation — ไม่ต้องรอ code เสร็จ
> Input มาจาก `docs/design-docs/` เท่านั้น (ไม่อ่าน BA docs โดยตรง)

**ใครทำ:** QA Planner (prompt template) → QA Reviewer + QA Defender (review loop)

| Step | Command/Action | Agent | Output |
|------|---------------|-------|--------|
| สร้าง QA docs | Prompt template `qa-plan-direct-prompt.md` | QA Planner | `docs/qa/01-03` |
| ตรวจ QA docs | `/qa-review all` | QA Reviewer | `docs/qa/claim-review-and-rebuttal/claim-review-01.md` |
| แก้ + โต้ | `/qa-rebuttal claim-review-01.md` | QA Defender | `docs/qa/claim-review-and-rebuttal/rebuttal-round-01.md` |
| ทำซ้ำ | `/qa-review all` | QA Reviewer | `claim-review-02.md` ... |

**Personas:**
- `.agents/skills/andm-qa-reviewer/SKILL.md` — Adversarial QA Consultant (15 attack vectors)
- `.agents/skills/andm-qa-defender/SKILL.md` — Constructive QA Defense (Accept/Partial/Reject)

**Sync กับ Implementation:**
- ถ้ามี `docs/state/impl-plan.md` → map test cases กับ impl task IDs
- ถ้ายังไม่มี → ใช้ `docs/design-docs/08-product-breakdown.md` เป็น reference

```
docs/qa/
  01-test-execution-plan.md        ← ⭐ AUTHORITATIVE: scope, test levels (execution + design strategy),
                                     coverage targets, mock strategy, test data, environments, entry/exit,
                                     phases, impl-plan sync, defect mgmt
                                     (TD-07 test-strategy dropped in SD-as-Master — strategy รวมอยู่ที่นี่)
  02-test-cases/
     TC-FR-*.md                    ← Functional test cases
     TC-API-*.md                   ← API contract test cases
     TC-SEC-*.md                   ← Security test cases
     TC-DF-*.md                    ← Data flow test cases
     TC-NFR-*.md                   ← Non-functional test cases
     TC-EDGE-*.md                  ← Edge case test cases
     TC-UX-*.md                    ← (optional) UI test cases — ถ้ามี docs/ux/ available
  03-traceability-matrix.md        ← Requirement → Test Case mapping
  claim-review-and-rebuttal/
     claim-review-XX.md
     rebuttal-round-XX.md
```

**📖 Workflows:** `.agents/workflows/qa-review.md`, `qa-rebuttal.md` *(narrative guide retired)*

### 3T: QA Test Execution (Phase 3 → Phase 4 Bridge)

> ทำหลัง code review ผ่าน + QA Plan approved — ก่อนเข้า Phase 4

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| รัน tests | `/qa-execute all` | andm-qa-testing (SDET) | `docs/qa/execution-rounds/execution-round-01.md` + updated `03-traceability-matrix.md` |
| Classify + route fixes | `/qa-execute-fix docs/qa/execution-rounds/execution-round-01.md` | andm-qa-testing | `docs/qa/execution-rounds/defense-round-01.md` + routed commands |
| ทำซ้ำ | `/qa-execute ...` → `/qa-execute-fix ...` | andm-qa-testing | `execution-round-02.md`, `defense-round-02.md`, ... |

**Flow:**
1. `/qa-execute` รัน automated tests ตาม command ที่ define ใน `docs/qa/01-test-execution-plan.md` (authoritative)
2. Parse JUnit/coverage artifacts → map ผลกลับ `03-traceability-matrix.md` (mark ✅/❌/⚠️ ต่อ requirement)
3. Failing TCs → `/qa-execute-fix` classify root cause (code/test/spec/plan/flake/env) + route:
   - **Code bug** → `/impl-task <IMPL-ID>`
   - **Test bug** → andm-qa-testing self-fix (ใน `services/*/tests/`)
   - **Spec bug** → `/backtrack sd`
   - **Plan bug** → `/qa-rebuttal`
   - **Flake** → log `docs/qa/known-flakes.md` + retry
4. Manual test → `/qa-execute --manual` (checklist-driven)

**Personas:**
- `.agents/agents/andm-qa-testing.md` — Lead SDET (owns test files, ห้ามแก้ production code)

**📖 Workflows:** `.agents/workflows/qa-execute.md`, `qa-execute-fix.md` *(narrative guide retired)*

> ⚠️ Test commands ต้อง define ใน QA-01 (authoritative) — workflow จะ HALT ถ้าไม่เจอ ไม่ hardcode framework เพื่อคง stack-agnostic

### เมื่อผ่าน Phase 3:
- ✅ Working code ใน `services/api/`, `services/web/`, `services/worker/`
- ✅ Tests ผ่านทุก service
- ✅ Handoff files up-to-date
- ✅ Commits มี contextual "Why"
- ✅ Code review ผ่าน (ไม่มี CRITICAL/HIGH ค้าง)
- ✅ Cross-service consistency verified
- ✅ Design doc compliance verified
- ✅ QA Plan approved (test strategy, test cases, traceability matrix)
- ✅ Test cases sync กับ impl-plan task IDs
- ✅ QA test execution complete — results mapped to traceability matrix

---

## Phase 4: Harden — ตรวจสอบความปลอดภัย

### 4A: Red Team Security Audit

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| โจมตี code | `/red-team all` | Red Team Attacker | `docs/security/red-team-round-01.md` |
| แก้ + โต้ | `/red-team-rebuttal red-team-round-01.md` | Red Team Defender | `docs/security/defense-round-01.md` |
| ทำซ้ำ | `/red-team all` | Red Team Attacker | `red-team-round-02.md` ... |

**Personas:**
- `.agents/skills/andm-red-team-attacker/SKILL.md` — Security Auditor (OWASP Top 10 + STRIDE on code)
- `.agents/skills/andm-red-team-defender/SKILL.md` — Security Engineer (7-step fix + pattern detection)

**📖 Workflows:** `.agents/workflows/red-team.md`, `red-team-rebuttal.md` *(narrative guide retired — for on-demand security audit without phase-gate ceremony, use Ship Track's `/red-team`)*

### เมื่อผ่าน Phase 4:
- ✅ ไม่มี CRITICAL/HIGH vulnerability ค้าง
- ✅ `.claude/rules/security.md` ถูก update ด้วย rules ใหม่
- ✅ `docs/design-docs/05-security.md` ถูก update
- ✅ Regression tests ครอบคลุม security fixes
- ✅ **Human reviewed** findings ก่อนปิด loop

---

## Phase 5: Deliver — ส่งมอบ

### 5A: Final Delivery Handoff

| Step | Command | Agent | Output |
|------|---------|-------|--------|
| สร้าง delivery handoff | `/deliver all` | Deliver Handoff Engineer | updated `docs/state/` + delivery summary |

**Persona:** `.agents/skills/andm-deliver-handoff/SKILL.md` — Senior Delivery Engineer / Knowledge Transfer Specialist

**Process:**
1. **Readiness Assessment** — scan ทุก phase deliverable, check QA status, count completed vs deferred tasks
2. **Finalize Handoff** — update `docs/state/overview.md` + per-module handoffs + delivery summary
3. **⏸️ HALT** — human review delivery summary before finalizing
4. **Commit** — commit updated state files

### 5B: Knowledge Base Setup (Manual)

รวมเอกสารเข้า Knowledge Base Tool (เช่น NotebookLM, RAG pipeline, wiki):
- ทุก ADR จาก `docs/adr/`
- Design Docs + Technical Design + BA + UX specs
- API Specs + Architecture Diagrams
- `CLAUDE.md` + `.claude/rules/`

### 5C: Metrics (Optional)

เทียบ baseline vs actual (cycle time, bug rate, onboarding time)
> ⚠️ ต้องมี baseline จาก 2-3 sprints ก่อนใช้ AI workflow — ถ้าไม่มี baseline ตัวเลขจะไม่มีความหมาย

### 5D: Demo Video (Optional)

ใช้ `ui-demo` skill (`.agents/skills/ui-demo/SKILL.md`) บันทึก demo video ด้วย Playwright + cursor overlay สำหรับ onboarding, stakeholder presentation, documentation

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
| **Bootstrap** | `/project-init` | สร้าง project CLAUDE.md + rules จาก approved TD (engineer subagents stay generic) | หลัง TD approved ก่อน impl-plan |
| **Bootstrap** | `/project-init --regen` | Re-gen หลัง TD เปลี่ยน (backup + overwrite) | หลัง `/amend td` หรือ `/backtrack td` resolve |
| **Bootstrap** | `/project-init --amend "<desc>"` | Targeted edit ของ generated rules | เมื่อต้องการเพิ่ม/ปรับ rule เฉพาะจุด |
| **Navigation** | `/amend <phase> "<desc>"` | แก้ไข/เพิ่มเติม deliverables (ba/sd/ux/td) — T3/T4 amendments append entry to `docs/state/amendment-log.md` (Step 5.5; Tier Floor Rules prevent under-classification) | เมื่อต้องการเพิ่ม/เปลี่ยน/ลบ content หลังสร้างแล้ว |
| **Navigation** | `/backtrack <phase>` | ย้อน phase + impact analysis (target ∈ ba/sd/ux/td เท่านั้น; impl/impl-plan concerns route ผ่าน `/impl-plan-review`) | เมื่อ downstream พบปัญหา upstream design |
| **Navigation** | `/next` | auto-detect phase + recommend next action; scans backtrack-log + amendment-log + State Reconciliation drift + Plan Staleness ก่อน recommend (Pre-check 0 + Checks 0–5.8) | เมื่อไม่แน่ใจว่าทำอะไรต่อ — daily session navigator |
| **Implement** | `/impl-plan <sprint>` | สร้าง sprint plan | หลัง design QA ผ่าน |
| **Implement (Plan QA)** | `/impl-plan-review <target>` | ตรวจ implementation plan (10 dimensions) | หลัง `/impl-plan` |
| **Implement (Plan QA)** | `/impl-plan-rebuttal <file>` | แก้ + โต้ plan review findings | หลัง `/impl-plan-review` มี CRITICAL/HIGH |
| **Implement** | `/impl-task <task-id>` | implement task | หลัง impl-plan approved |
| **Implement** | `/impl-review <target>` | ตรวจ code quality + design compliance | หลัง sprint tasks เสร็จ |
| **Implement** | `/impl-review-fix <file>` | แก้ code review findings | หลัง impl-review |
| **QA Plan** | `/qa-review <target>` | ตรวจ QA Plan deliverables | หลังสร้าง QA docs (parallel กับ impl) |
| **QA Plan** | `/qa-rebuttal <file>` | แก้/โต้ QA findings | หลัง qa-review |
| **Harden** | `/red-team <target>` | security audit code | หลัง code review ผ่าน |
| **Harden** | `/red-team-rebuttal <file>` | fix vulnerabilities | หลัง red-team |
| **Deliver** | `/deliver <scope>` | final delivery handoff + readiness assessment | หลัง red team ผ่าน |

---

## Agent Persona Summary

> **Note:** This table includes the 17 core personas plus key supporting/tool-specific personas referenced in this walkthrough. For the full 46-skill catalog (core + supporting + tool-specific + utility + frontend-tools), see `.agents/workflows/manifest.json` → `skill-categories`. The canonical core roster (17) is defined in that manifest and mirrored in `CLAUDE.md` and `README.md`.

| Persona | SKILL.md | Role | Phase |
|---------|----------|------|-------|
| **BA Reviewer** | `.agents/skills/andm-ba-reviewer/` | Adversarial BA Consultant | Design QA |
| **BA Defender** | `.agents/skills/andm-ba-defender/` | Constructive BA Defense | Design QA |
| **SD Reviewer** | `.agents/skills/andm-sd-reviewer/` | Adversarial Architect | Design QA |
| **SD Defender** | `.agents/skills/andm-sd-defender/` | Constructive Architect | Design QA |
| **TD Reviewer** | `.agents/skills/andm-td-reviewer/` | Adversarial Engineer | Design QA |
| **TD Defender** | `.agents/skills/andm-td-defender/` | Constructive Technical Architect | Design QA |
| **QA Reviewer** | `.agents/skills/andm-qa-reviewer/` | Adversarial QA Consultant | Implement (QA Plan) |
| **QA Defender** | `.agents/skills/andm-qa-defender/` | Constructive QA Defense | Implement (QA Plan) |
| **Impl Planner** | `.agents/skills/andm-impl-planner/` | Tech Lead / Sprint Planner | Implement |
| **Impl Plan Reviewer** | `.agents/skills/andm-impl-plan-reviewer/` | Adversarial Tech Lead — 10 dimensions | Implement (Plan QA) |
| **Impl Plan Defender** | `.agents/skills/andm-impl-plan-defender/` | Constructive plan defense | Implement (Plan QA) |
| **Impl Engineer** | `.agents/skills/andm-impl-engineer/` | Senior Full-Stack Engineer | Implement |
| **Code Reviewer** | `.agents/skills/andm-code-reviewer/` | Adversarial Quality Engineer | Implement |
| **Red Team Attacker** | `.agents/skills/andm-red-team-attacker/` | Security Auditor | Harden |
| **Red Team Defender** | `.agents/skills/andm-red-team-defender/` | Security Engineer | Harden |
| **UX Reviewer** | `.agents/skills/andm-ux-reviewer/` | Adversarial UX Consultant (22 attack vectors) | Design QA |
| **UX Defender** | `.agents/skills/andm-ux-defender/` | Constructive UX Defense | Design QA |
| **Amend Engineer** | `.agents/skills/andm-amend-engineer/` | Senior Design Document Specialist | Navigation |
| **UX Designer** | (manual / Stitch / Figma) | UX/UI Visual Designer | Design |
| **Frontend Designer** | `.agents/skills/frontend-design/` | Production-grade UI Builder (9 visual directions) | Design (via `/ux-design frontend`) |
| **Design System** | `.agents/skills/design-system/` | Design Token Generator / Visual Auditor / Slop Detector | Design + Design QA |
| **Click-Path Auditor** | `.agents/skills/click-path-audit/` | Behavioral Bug Hunter (6 state interaction patterns) | Design QA (extended) |
| **Dashboard Builder** | `.agents/skills/dashboard-builder/` | Operational Dashboard Architect | Design (via `/ux-design frontend`) |
| **Deliver Handoff Engineer** | `.agents/skills/andm-deliver-handoff/` | Delivery Readiness + Final Handoff | Deliver |
| **UI Demo Recorder** | `.agents/skills/ui-demo/` | Playwright Demo Video Producer | Deliver |
| **Liquid Glass Guide** | `.agents/skills/liquid-glass-design/` | iOS 26+ Glass Effect Reference | Design (reference only) |

---

## Complete File Structure

```
.agents/                                  ← Methodology source of truth (workflows + skills + agents)
  workflows/                              ← Workflow definitions (platform-agnostic, canonical source)
    manifest.json                         ← Workflow registry (command → skill mapping)
    ba-review.md                          ← /ba-review
    ba-rebuttal.md                        ← /ba-rebuttal
    sd-review.md                          ← /sd-review
    sd-rebuttal.md                        ← /sd-rebuttal
    td-review.md                          ← /td-review
    td-rebuttal.md                        ← /td-rebuttal
    ux-design.md                          ← /ux-design
    ux-review.md                          ← /ux-review
    ux-rebuttal.md                        ← /ux-rebuttal
    ux-fix.md                             ← /ux-fix
    impl-plan.md                          ← /impl-plan
    impl-plan-review.md                   ← /impl-plan-review (Plan QA loop — mirror BA/SD/UX/TD)
    impl-plan-rebuttal.md                 ← /impl-plan-rebuttal
    impl-task.md                          ← /impl-task
    impl-review.md                        ← /impl-review
    impl-review-fix.md                    ← /impl-review-fix
    qa-review.md                          ← /qa-review
    qa-rebuttal.md                        ← /qa-rebuttal
    red-team.md                           ← /red-team
    red-team-rebuttal.md                  ← /red-team-rebuttal
    amend.md                              ← /amend
    backtrack.md                          ← /backtrack
    next.md                               ← /next
  skills/                                 ← Agent personas + support skills (49 total, SKILL.md per skill)
    _core-behaviors.md                    ← Behavioral foundation (6 rules — ทุก persona ต้องปฏิบัติตาม)
    _severity-scale.md                    ← Severity taxonomy (shared across reviewers)
    # Core personas (19) — adversarial/constructive pairs + lifecycle engineers
    andm-ba-reviewer/SKILL.md
    andm-ba-defender/SKILL.md
    andm-sd-reviewer/SKILL.md
    andm-sd-defender/SKILL.md
    andm-td-reviewer/SKILL.md
    andm-td-defender/SKILL.md
    andm-ux-reviewer/SKILL.md
    andm-ux-defender/SKILL.md
    andm-qa-reviewer/SKILL.md
    andm-qa-defender/SKILL.md
    andm-impl-planner/SKILL.md
    andm-impl-plan-reviewer/SKILL.md      ← Plan QA reviewer (10 dimensions)
    andm-impl-plan-defender/SKILL.md      ← Plan QA defender
    andm-impl-engineer/SKILL.md
    andm-code-reviewer/SKILL.md
    andm-red-team-attacker/SKILL.md
    andm-red-team-defender/SKILL.md
    andm-amend-engineer/SKILL.md
    andm-deliver-handoff/SKILL.md
    # Supporting skills (11) — shared knowledge bases + patterns
    api-patterns/SKILL.md
    architecture/SKILL.md
    brainstorming/SKILL.md
    business-analyst/SKILL.md
    code-review/SKILL.md
    database-design/SKILL.md
    db-migration/SKILL.md
    documentation-templates/SKILL.md
    handoff/SKILL.md
    product-designer/SKILL.md
    software-architecture/SKILL.md
    # Tool-specific skills (9) — Figma + Stitch integrations
    figma-code-connect-components/SKILL.md
    figma-create-design-system-rules/SKILL.md
    figma-create-new-file/SKILL.md
    figma-generate-design/SKILL.md
    figma-generate-library/SKILL.md
    figma-implement-design/SKILL.md
    figma-use/SKILL.md
    stitch-design/SKILL.md
    stitch-loop/SKILL.md
    # Utility skills (3) — meta/tooling
    find-skills/SKILL.md
    health-check/SKILL.md
    skill-creator/SKILL.md
    # Frontend-tools skills (6) — UI builders + visual auditors (ฝังใน ux-design / ux-review)
    frontend-design/SKILL.md              ← Production-grade UI (ฝังใน ux-design Mode D)
    design-system/SKILL.md                ← Token gen / audit / slop-detect (ฝังใน ux-design + ux-review)
    click-path-audit/SKILL.md             ← Behavioral bug detection (ฝังใน ux-review #23)
    dashboard-builder/SKILL.md            ← Dashboard layout strategy (ฝังใน ux-design Mode D)
    ui-demo/SKILL.md                      ← Demo video recording (ฝังใน ux-fix + Phase 5)
    liquid-glass-design/SKILL.md          ← iOS 26+ glass effects (reference)

.andm/prompt-templates/                   ← Authoritative prompt content (consumed by workflows; can also be copy-pasted)
  quick-start.md                          ← Phase detection + next action guide
  ba-requirements-prompt.md               ← BA prompt (consumed by /ba workflow)
  system-design-master-prompt.md          ← SD prompt (consumed by /sd workflow)
  technical-design-master-prompt.md       ← TD prompt (consumed by /td workflow)
  ux-design-stitch-prompt.md              ← UX prompt (Stitch/AI-generated mode)
  ux-design-figma-prompt.md               ← UX prompt (Figma-first mode)
  ux-design-existing-prompt.md            ← UX prompt (existing UI audit mode)
  ux-design-reference-prompt.md           ← UX prompt (reference-driven / DESIGN.md mode)
  ux-design-claude-design-prompt.md       ← UX prompt (Claude Design — Anthropic Labs, Opus 4.7 vision)
  qa-plan-direct-prompt.md                ← QA Plan prompt (direct mode)

.claude/commands/                           ← Claude Code slash command adapters (delegates to .agents/workflows/)
.windsurf/workflows/                        ← Windsurf workflow adapters (delegates to .agents/workflows/)

docs/
  ba/
    01-05 BA deliverables (v1.2: 06-handoff dropped)
    claim-review-and-rebuttal/
  design-docs/
    02-08 design deliverables (v1.2: gaps 01/06 — merged into 02)
    claim-review-and-rebuttal/
  technical-design/
    02, 03, 04 technical design deliverables (01/05/06/07/08 dropped — SD-as-Master)
    claim-review-and-rebuttal/
  adr/
  api-specs/
  ux/
    00-05 UX/UI deliverables (06 handoff dropped — SD-as-Master)
    claim-review-and-rebuttal/
  qa/
    01-test-execution-plan.md
    02-test-cases/TC-*.md
    03-traceability-matrix.md
    claim-review-and-rebuttal/
  code-review/
    review-round-XX.md
    fix-round-XX.md
  security/
    red-team-round-XX.md
    defense-round-XX.md
  state/
    overview.md                           ← Phase status (derived view; updated with backtrack/invalidation markers)
    impl-plan.md                          ← Primary State SoT (tasks, Phase Gates, SD Hint Alignment, Mid-Phase Audit Log)
    backtrack-log.md                      ← /backtrack append-only log (BT-NNN entries; Status: 🔄 Open / ✅ Closed)
    amendment-log.md                      ← /amend T3/T4 obligations log (AMEND-NNN; scanned by /next Check 0.5 as priority #3)
    deferred-ac-registry.md               ← Deferred E-AC tracking (max +14d × 2 renewals; expiry-scanned by /impl-task)
    operator-action-registry.md           ← UIR Pending operator actions (env vars, API keys, ToS, etc.)
    impl-plan-claim-review-and-rebuttal/  ← Plan QA cycle output (mirror of BA/SD/UX/TD review)
    _session-handoff/                     ← Per-task evidence artifacts + Tier 1.5 Exploratory Walk artifacts
    api/handoff.md
    web/handoff.md
    worker/handoff.md

.andm/development-guide/
  full-journey.md                   ← This file (overall lifecycle)
  ba-claim-review-workflow.md       ← BA QA guide
  sd-claim-review-workflow.md       ← SD QA guide
  td-workflow.md                    ← Technical Design guide (create + review/rebuttal)
  ux-design-workflow.md             ← UX/UI design guide
  amend-workflow.md                 ← Amend deliverables guide
  # NOTE: impl-workflow.md, impl-review-workflow.md, qa-plan-workflow.md, red-team-workflow.md, deliver-workflow.md retired in 2026-05-07 cleanup
  #       → read .agents/workflows/<name>.md directly, OR use Ship Track for MVP / market-race work
  backtrack-workflow.md             ← Backtrack process guide

services/
  api/                              ← Backend API (tech stack ตาม CLAUDE.md)
  web/                              ← Frontend Web (tech stack ตาม CLAUDE.md)
  worker/                           ← Background Worker (tech stack ตาม CLAUDE.md)
```

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

## Phase Backtrack — ย้อน Phase เมื่อพบปัญหา Upstream

กระบวนการทั้งหมดสามารถ **ย้อนกลับ** ได้เมื่อ downstream phase พบปัญหาที่แก้ local ไม่ได้:

```
ตัวอย่าง Backtrack Scenarios:

SD Review พบ BA requirement ขัดแย้ง       → /backtrack ba
TD Review พบ SD architecture ไม่รองรับ    → /backtrack sd
Implementation พบ TD design infeasible    → /backtrack td
UX Design พบ missing user flows           → /backtrack ba
Red Team พบ architecture flaw             → /backtrack sd
```

### Invalidation Matrix

| If Changed → | SD | UX | TD | Impl Plan | Impl Code | Code Review | Red Team |
|-------------|----|----|-----|-----------|-----------|-------------|----------|
| **BA** | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ | ❌ | ❌ |
| **SD** | — | ⚠️ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **UX** | — | — | ⚠️ | ⚠️ | ⚠️ | ❌ | ❌ |
| **TD** | — | — | — | ❌ | ❌ | ❌ | ❌ |

- ⚠️ = needs re-validation (อาจจะยังถูก)
- ❌ = invalidated (ต้อง re-run)

### Amend Process

1. **Parse** — แยก target phase กับ amendment description
2. **Load Context** — อ่าน deliverables ทั้ง phase + quality benchmark
3. **Impact Analysis** — วิเคราะห์ affected files + downstream impact + review status
4. **⏸️ HALT** — user approve ก่อน execute (ห้าม auto-proceed)
5. **Execute** — surgical edits ตาม dependency order + cascade check
6. **Report** — summary + downstream actions needed

**📖 Guide:** `.andm/development-guide/amend-workflow.md`

### Backtrack Process

1. **Identify** — ระบุปัญหาและ upstream root cause
2. **Impact Analysis** — วิเคราะห์ deliverables ที่จะถูก invalidate (`/backtrack` ทำให้อัตโนมัติ)
3. **⏸️ HALT** — user approve ก่อน backtrack (ห้าม auto-backtrack)
4. **Record** — บันทึกใน `docs/state/backtrack-log.md`
5. **Rework** — แก้ upstream deliverables เฉพาะจุด
6. **Re-validate** — ตรวจ downstream ที่ถูก impact
7. **Close** — update backtrack log เมื่อเสร็จ

**📖 Guide:** `.andm/development-guide/backtrack-workflow.md`

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
