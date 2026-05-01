# Quick Start — AI-Native Development

> ไม่แน่ใจว่าอยู่ Phase ไหน? ทำอะไรต่อ? ดูตรงนี้
>
> หรือใช้ `/next` ให้ agent ตรวจสถานะอัตโนมัติ

---

## Pre-Phase 0: Idea Refinement (Optional)

**ทำเมื่อ:** เริ่มจาก vague idea หรือ brief ที่ยังไม่ชัด — ก่อนที่ BA จะเริ่มเขียน requirements
**ข้ามได้เมื่อ:** requirements ชัดเจนแล้ว, มี BRD/PRD พร้อม, หรือเป็น brownfield project

**วิธีใช้:**

| Mode | Command | ใช้เมื่อ |
|------|---------|---------|
| Single-shot | `/ideate "Back-Office Admin แก้ stuck payment ช้า"` | มี pain point ชัด 1 ประโยค |
| Interactive | `/ideate` | ยังไม่ชัด ให้ agent ถามกลับทีละ step |
| Resume | `/ideate resume` | มี `ideation-brief.md` อยู่แล้ว อยาก pivot/extend |

**Output:** `docs/foundation-input-sources/ideation-brief.md` (BA prompt อ่านอัตโนมัติ)

**📖 Guide:** `.agents/development-guide/ideate-workflow.md` (มีตัวอย่าง brief ฉบับเต็ม)

> **💡 ข้าม Phase 0 ได้ถ้า:** scope ชัดแล้ว — ไปที่ Phase 1A BA ได้เลย

---

## Pre-Phase 1: Prepare Input Sources

**ทำเมื่อ:** เริ่มโปรเจคใหม่ — เป็น prep สำหรับ Phase 1 DESIGN (ไม่ใช่ phase แยก)

กรอกข้อมูลโปรเจคใน `docs/foundation-input-sources/` — prompt templates ทุกตัวจะอ่านจากที่นี่อัตโนมัติ:

| File | When to Fill | Required? |
|------|-------------|-----------|
| `project-overview.md` | Kickoff | **Yes** — ทุก phase ใช้ |
| `stakeholder-input.md` | Kickoff | **Yes** — BA + SD ใช้ |
| `competitive-analysis.md` | Before BA | Optional |
| `brand-guidelines.md` | Before UX | Optional — ถ้ามี brand identity |
| `integration-requirements.md` | Before SD | Optional — ถ้ามี 3rd-party APIs |
| `infrastructure-constraints.md` | Before SD | Optional — ถ้ามี infra constraints |
| `existing-system-audit.md` | Before SD | Brownfield only |
| `notebooklm.md` | Anytime | Optional — ถ้าใช้ NotebookLM MCP |
| `ideation-brief.md` | Phase 0 output | Optional — สร้างโดย `/ideate` ถ้าทำ Phase 0 |

> **Tip:** เริ่มจากกรอก `project-overview.md` + `stakeholder-input.md` ก็พอ — ที่เหลือเติมทีหลังได้
> ไฟล์ที่เนื้อหาเป็น placeholder จะถูก agent ข้ามไปอัตโนมัติ

---

## Phase 1: Design — สร้างเอกสาร

### 1A: BA Requirements

**ทำเมื่อ:** ยังไม่มี `docs/ba/` หรือไม่ครบ 5 ไฟล์ (v1.2: 06-handoff dropped)

**วิธีใช้:**

| Mode | Command | ใช้เมื่อ |
|------|---------|---------|
| Default | `/ba` | กรอก `docs/foundation-input-sources/project-overview.md` ครบแล้ว ให้ agent ทำเลย |
| Focused | `/ba "<focus hint>"` | ต้องการ scope ก่อน เช่น `/ba "MVP only — ตัด mobile ออก"` |
| Interactive | `/ba` (workflow detect input ขาด → flipped interaction) | มีแค่ไอเดียคร่าวๆ ให้ agent ถามกลับ |

**ทำงานเบื้องหลัง:** workflow `/ba` อ่าน `.agents/prompt-templates/ba-requirements-prompt.md` (authoritative persona + 4-phase process + Language Rule + Readability Contract) + อ่าน `docs/foundation-input-sources/` อัตโนมัติ — ไม่ต้องเติม `[PLACEHOLDER]` ใน prompt

**Output:** `docs/ba/01-05` (5 ไฟล์; v1.2: 06-handoff dropped) + seed `docs/state/overview.md`

> **💡 ต้องการเพิ่มเติม/แก้ไขหลังสร้างแล้ว?** ใช้ `/amend ba "คำอธิบายสิ่งที่ต้องการเปลี่ยน"` — ไม่ต้องรัน workflow ใหม่ทั้งหมด

### 1B: System Design

**ทำเมื่อ:** มี BA docs ครบแล้ว แต่ยังไม่มี `docs/design-docs/`

**วิธีใช้:**

| Mode | Command | ใช้เมื่อ |
|------|---------|---------|
| Default | `/sd` | BA ครบ + approved → ให้ agent design ตาม BA โดยตรง |
| Focused | `/sd "<focus hint>"` | ต้องการ steer architectural choice เช่น `/sd "skip Evolution Sequence — greenfield monolith"` หรือ `/sd "focus on payment flow"` |
| Interactive | `/sd` (workflow detect BA gaps → flipped interaction) | BA ขาด NFR / scale targets / integration constraints — agent จะถามกลับ |

**ทำงานเบื้องหลัง:** workflow `/sd` อ่าน `.agents/prompt-templates/system-design-master-prompt.md` (authoritative persona + 6-step process + Phase Contract + Language Rule + Readability Contract) + อ่าน `docs/ba/01-05` (v1.2) + `docs/foundation-input-sources/` อัตโนมัติ — enforce schedule-leakage check ใน Phase 3 quality gate

**Output:** `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06 — merged into 02) + `docs/adr/` + `docs/api-specs/` + update `docs/state/overview.md`

> **💡 ต้องการเพิ่มเติม/แก้ไขหลังสร้างแล้ว?** ใช้ `/amend sd "คำอธิบาย"` — agent จะ amend เฉพาะจุดที่กระทบ + update ADRs

### 1C: UX/UI Design

**ทำเมื่อ:** มี BA + SD docs ครบแล้ว แต่ยังไม่มี `docs/ux/`

**วิธีใช้:**
1. เปิด agent session ใหม่
2. เลือก mode ตาม context ของโปรเจค:

| Mode | Template File | ใช้เมื่อ |
|------|--------------|---------|
| Auto-detect | `/ux-design auto` | ให้ agent เลือก mode เอง |
| AI-Generated | `ux-design-stitch-prompt.md` | Greenfield, ยังไม่มี design |
| Figma-First | `ux-design-figma-prompt.md` | มี Figma file อยู่แล้ว |
| Existing Audit | `ux-design-existing-prompt.md` | มี UI อยู่แล้ว ต้องจัดระเบียบ |
| Reference-Driven | `ux-design-reference-prompt.md` | มี reference website เป็นต้นแบบ visual style |
| Frontend Build | `/ux-design frontend` | สร้าง production UI ตรงเลย (ใช้ `frontend-design` skill) |
| Claude Design | `ux-design-claude-design-prompt.md` | Interactive iteration ผ่าน Claude Design (Anthropic Labs) — ต้องมี Pro/Max/Team/Enterprise subscription |

หรือใช้ command: `/ux-design <mode>` (stitch / figma / existing / reference / frontend / claude-design / auto)

> **Skills ที่ใช้ร่วม:** `design-system` (tokens/audit), `dashboard-builder` (dashboard layout), `liquid-glass-design` (iOS glass style)

**Output:** `docs/ux/01-05` (5 ไฟล์; UX-06 dropped in SD-as-Master consolidation)

**📖 Guide:** `.agents/development-guide/ux-design-workflow.md`

> **💡 ต้องการเพิ่มเติม/แก้ไขหลังสร้างแล้ว?** ใช้ `/amend ux "คำอธิบาย"`

### 1D: Technical Design (Detailed / Low-Level Design)

**ทำเมื่อ:** มี SD + UX docs ครบ (ผ่าน review แล้ว) แต่ยังไม่มี `docs/technical-design/`

**วิธีใช้:**

| Mode | Command | ใช้เมื่อ |
|------|---------|---------|
| Default | `/td` | SD + UX + ADRs + api-specs ครบ → ให้ agent สร้าง detailed design เลย |
| Focused | `/td "<focus hint>"` | ต้องการ scope เฉพาะส่วน เช่น `/td "focus on payment-service backend"` หรือ `/td "frontend only — no DB changes"` |
| Interactive | `/td` (workflow detect SD gaps → flipped interaction) | SD ขาด ADR สำหรับ pattern หลัก หรือ api-specs ไม่ครบ — agent จะถามกลับ |

**ทำงานเบื้องหลัง:** workflow `/td` อ่าน `.agents/prompt-templates/technical-design-master-prompt.md` (authoritative persona + 5-step process + SD-as-Master Scope Contract + Language Rule + Cross-Domain Consistency check) + อ่าน `docs/design-docs/02-08` (v1.2: gaps 01/06) + `docs/ux/01-05` + `docs/adr/` + `docs/api-specs/` + `.claude/rules/` อัตโนมัติ

**Output:** `docs/technical-design/02, 03, 04` (3 ไฟล์ — SD-as-Master consolidation; numbering 01/05/06/07/08 dropped; content moved to api-specs / ADRs / SD-04 / QA-01) + update `docs/state/overview.md`

**📖 Guide:** `.agents/development-guide/td-workflow.md`

> **💡 ต้องการเพิ่มเติม/แก้ไขหลังสร้างแล้ว?** ใช้ `/amend td "คำอธิบาย"` — agent จะ cascade check API↔DB↔Frontend↔Test

---

## Phase 2: Design QA — ตรวจสอบคุณภาพเอกสาร

**ทำเมื่อ:** มี BA + SD + UX + TD docs ครบ ต้องตรวจคุณภาพก่อน implement

```
Step 1:  /ba-review all                    → ตรวจ BA docs
Step 2:  /ba-rebuttal <claim-review-file>   → แก้ + โต้แย้ง findings
         (ทำซ้ำ Step 1-2 จนไม่มี CRITICAL/HIGH ค้าง)

Step 3:  /sd-review all                    → ตรวจ design docs
Step 4:  /sd-rebuttal <claim-review-file>   → แก้ + โต้แย้ง findings
         (ทำซ้ำ Step 3-4 จนไม่มี CRITICAL/HIGH ค้าง)

Step 5:  /ux-review                        → ตรวจ UX deliverables (22 core + 3 extended)
         (Extended: design-system audit, slop-detect, click-path audit — ถ้ามี code)
         (User/Stakeholder approve → ⏸️ HALT)

Step 6:  /td-review all                    → ตรวจ Technical Design docs
Step 7:  /td-rebuttal <claim-review-file>   → แก้ + โต้แย้ง findings
         (ทำซ้ำ Step 6-7 จนไม่มี CRITICAL/HIGH ค้าง)
```

**ผ่านเมื่อ:** ไม่มี CRITICAL/HIGH ค้าง + ADRs up-to-date + UX approved + TD cross-domain consistent

---

## Phase 3: Implement — เขียน Code + QA Planning (Parallel)

**ทำเมื่อ:** Design QA ผ่านแล้ว มี `08-product-breakdown.md` (work inventory + Phase Hints) + `07-future-evolution.md` (Evolution Sequence) พร้อม

> ⭐ **Phase 3 = ที่ Impl Planner ทำ final phase decision (Option C)** — SD ให้ **architectural hints** (Evolution Sequence + Phase Hints), Impl Planner honor หรือ override พร้อม documented rationale

### 3A-C: Implementation

```
Step 1:  /impl-plan 1                      → สร้าง phase-grouped plan
         (Agent อ่าน SD's Evolution Sequence + Phase Hints + per-task metadata
          → รัน phase assignment rules ของตัวเอง
          → เปรียบเทียบ align/diverge
          → สร้าง P1 Foundation → P2 Core → P3 Polish → P4 Stretch
          → เขียน SD Hint Alignment audit trail ใน Phasing Rationale)
         (ตรวจ plan → approve)

Step 2:  /impl-task IMPL-001               → implement task แรกใน P1 (Foundation)
Step 3:  /impl-task IMPL-002               → implement task ถัดไป
         (ทำจนครบ P1 → ตรวจ phase gate → ต่อ P2)
         (ทำซ้ำจนจบทุก phase)

Step 4:  /impl-review all                  → ตรวจ code ทั้ง sprint (หลังจบแต่ละ phase)
Step 5:  /impl-review-fix <review-file>     → แก้ findings
         (ทำซ้ำ Step 4-5 จนไม่มี CRITICAL/HIGH ค้าง)
```

**Default Phase Taxonomy:**
- **P1 Foundation** (20-30%) — infra, auth, DB, CI/CD → gate: dev env e2e + smoke test
- **P2 Core** (40-50%) — MVP primary user value → gate: primary flow e2e + critical tests
- **P3 Polish** (20-30%) — Should-Haves, NFRs, observability → gate: Must/Should + NFR targets
- **P4 Stretch** (0-10%, optional) — Could-Haves → gate: ship or defer

**SD Hint Consumption (Option C):**
- Evolution Sequence = hard constraint → honor (backtrack ถ้า violate)
- Phase Hints = soft suggestion → honor หรือ override + document reason
- Per-task metadata (risk, must_precede, unlocks) = input ของ assignment rules

### 3Q: QA Planning (Parallel — ไม่ต้องรอ code)

```
Step 1:  Copy prompt จาก qa-plan-direct-prompt.md → paste เข้า agent session ใหม่
         (Agent สร้าง docs/qa/01-03 จาก design docs + BA FR/NFR)

Step 2:  /qa-review all                    → ตรวจ QA deliverables
Step 3:  /qa-rebuttal <claim-review-file>   → แก้/โต้ findings
         (ทำซ้ำ Step 2-3 จนไม่มี CRITICAL/HIGH ค้าง)
```

**📖 Guide:** `.agents/development-guide/qa-plan-workflow.md`

**ผ่านเมื่อ:** Tests ผ่าน + Code review ผ่าน + QA Plan approved + Handoff updated

---

## Phase 3T: QA Execute — รัน Test Plan + Classify Failures

**ทำเมื่อ:** Phase 3 Implement เขียนโค้ดเสร็จ + QA Plan (Phase 3Q) approved → ต้องรัน tests ตาม plan ก่อนเข้า Phase 4 Harden

```
Step 1:  /qa-execute all                   → รัน tests จาก approved QA Plan
         (Agent อ่าน docs/qa/01-test-execution-plan.md → run tests
          → map results to traceability matrix
          → produce docs/qa/execution-rounds/execution-round-NN.md)

Step 2:  /qa-execute-fix <report-file>      → classify failing tests + route fixes
         (Agent classify per failure: code / test / spec / plan / flake / env
          → route ไป /impl-task, /impl-review-fix, /amend, /qa-rebuttal ตาม class)
         (ทำซ้ำ Step 1-2 จนไม่มี failing tests ค้าง)
```

**Target options:**
- `all` — รัน test suite ทั้งหมด
- `TC-FR-001` — รัน test case ID เฉพาะ
- `services/api` — รันเฉพาะ service
- `--manual` — record manual test execution (ไม่มี automation)
- `--report-only <path>` — skip run, อ่าน existing report

**ผ่านเมื่อ:** Tests ทุกตัวใน QA Plan ผ่าน + traceability matrix ครบ + Execution Report approved

---

## Phase 4: Harden — Security Audit

**ทำเมื่อ:** Code + Code Review ผ่านแล้ว

```
Step 1:  /red-team all                     → security audit
Step 2:  /red-team-rebuttal <finding-file>  → fix vulnerabilities
         (ทำซ้ำ Step 1-2 จนไม่มี CRITICAL/HIGH ค้าง)
```

**ผ่านเมื่อ:** ไม่มี CRITICAL/HIGH vulnerability + security docs updated

---

## Phase 5: Deliver — ส่งมอบ

**ทำเมื่อ:** Harden ผ่านแล้ว

```
Step 1:  /deliver all                       → readiness assessment + final handoff
         (Agent ตรวจ deliverables ทุก phase → สร้าง delivery summary → update docs/state/)
         (Human approve → finalize)

Step 2:  รวมเอกสารเข้า Knowledge Base (NotebookLM / wiki) — manual
Step 3:  PR → merge to develop → deploy
Step 4:  (Optional) บันทึก demo video: `/ui-demo <url> [feature-description]`
```

**ผ่านเมื่อ:** Delivery summary approved + docs/state/ finalized + handoff complete
   - สร้าง WebM video พร้อม cursor overlay + subtitles
   - ใช้สำหรับ onboarding, stakeholder presentation, documentation

---

## Quick Detection: ฉันอยู่ตรงไหน?

| ถ้าไม่มีไฟล์เหล่านี้... | คุณอยู่ Phase | ทำอะไรต่อ |
|-------------------------|--------------|----------|
| ยังไม่มี problem statement ชัด + ไม่มี `ideation-brief.md` | 0 (optional) | `/ideate "<pain-point>"` หรือข้ามไป Phase 1A ถ้า scope ชัดแล้ว |
| `docs/ba/` ว่าง | 1A | `/ba` (หรือ `/ba "<focus>"`) |
| `docs/design-docs/` ว่าง | 1B | `/sd` (หรือ `/sd "<focus>"`) |
| `docs/ux/` ว่าง | 1C | `/ux-design auto` หรือใช้ UX prompt template |
| `docs/technical-design/` ว่าง | 1D | `/td` (หรือ `/td "<focus>"`) |
| ไม่มี `claim-review-and-rebuttal/` | 2 | `/ba-review all` |
| ไม่มี `docs/state/impl-plan.md` | 3A | `/impl-plan 1` |
| ไม่มี code ใน `services/` | 3B | `/impl-task IMPL-001` |
| ไม่มี `docs/qa/` | 3Q | ใช้ QA Plan prompt template (parallel กับ impl) |
| ไม่มี `docs/code-review/` | 3C | `/impl-review all` |
| ไม่มี `docs/security/` | 4 | `/red-team all` |
| ทุกอย่างครบ | 5 | Deliver! |
