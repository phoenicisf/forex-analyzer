# Technical Design (Detailed Design) — Development Guide

คู่มือการใช้งาน workflow สำหรับสร้างและกรองคุณภาพ Technical Design deliverables — bridge ระหว่าง System Design (architecture) กับ Implementation (code)

> ⚠️ **Scope change: TD reduced from 8 → 3 docs (SD-as-Master consolidation)**
>
> Technical Design ผลิตเฉพาะ `02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` เท่านั้น
> เอกสารที่ถูก drop (01, 05, 06, 07, 08) ย้าย content ไปยัง authoritative sources:
>
> | Dropped | Content ย้ายไปที่ |
> |---------|------------------|
> | **TD-01 API Contracts** | `docs/api-specs/*.yaml` (authoritative — full OpenAPI + validation + error schemas + auth/rate-limit) |
> | **TD-05 Design Patterns** | `docs/adr/` (pattern decisions) + code skeletons inline ใน TD-02 |
> | **TD-06 Sequence Diagrams** | Flow-level ใน SD `04-data-flow.md` + method-level ใน TD-02 § Flow Appendix |
> | **TD-07 Test Strategy** | `docs/qa/01-test-execution-plan.md` (authoritative — design-level strategy รวมอยู่กับ execution plan) |
> | **TD-08 Handoff** | Impl Planner (`/impl-plan`) อ่าน SD `07-future-evolution.md` + `08-product-breakdown.md` โดยตรง |

---

## ภาพรวม Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│  Technical Architect สร้าง docs/technical-design/02, 03, 04          │
│  (ใช้ prompt: .andm/prompt-templates/technical-design-master-*.md)  │
│  Input: SD docs + UX docs + ADRs + .claude/rules/                   │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  /td-review  →  Reviewer Agent ตรวจ → claim-review-01.md            │
│  Persona: .agents/skills/andm-td-reviewer/SKILL.md                       │
│  (Adversarial Engineer — ตรวจ implementability + cross-domain)       │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  /td-rebuttal  →  Defender Agent แก้/โต้ → rebuttal-round-01.md     │
│  Persona: .agents/skills/andm-td-defender/SKILL.md                       │
│  + แก้ไข technical-design/02, 03, 04 ตาม accepted findings          │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
              ┌─────────────────────┐
              │ ผ่าน? พร้อม handoff  │──Yes──▶  Implementation Handoff
              │ ให้ทีม implement?   │          (impl-plan → impl-task)
              └───────┬─────────────┘
                      │ No
                      ▼
              ทำซ้ำ Round 02, 03...
```

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สร้าง Technical Design Documents (ก่อนเริ่ม review)

Technical Architect ใช้ prompt template สร้างเอกสาร **3 ไฟล์** ใน `docs/technical-design/` (consolidated in SD-as-Master — 5 docs dropped):

```
docs/technical-design/
  02-backend-design.md             ← Class/module structure, interfaces, DTOs, CQRS handlers, DI map,
                                     pattern code skeletons (decisions in ADRs), optional Flow Appendix
  03-frontend-design.md            ← Component tree, state management, routing config (authoritative),
                                     data fetching, error boundaries
  04-database-design.md            ← Column-level schema, constraints, indexes, migrations, seed data

  (01-api-contracts.md — DROPPED; authoritative schemas in docs/api-specs/*.yaml)
  (05-design-patterns.md — DROPPED; pattern decisions in docs/adr/, code skeletons inline in 02)
  (06-sequence-diagrams.md — DROPPED; flow-level in SD 04-data-flow, method-level in 02 § Flow Appendix)
  (07-test-strategy.md — DROPPED; owned by docs/qa/01-test-execution-plan.md — authoritative)
  (08-handoff-to-implementation.md — DROPPED; Impl Planner reads SD 07/08 directly)
```

**Input ที่ต้องมีก่อน:**
- ✅ `docs/design-docs/02-08` — System Design deliverables (v1.2: 6 docs, gaps 01/06 merged into 02; architecture constraints)
- ✅ `docs/adr/` — Architecture Decision Records (includes design-pattern decisions)
- ✅ `docs/api-specs/*.yaml` — **Authoritative** full OpenAPI with validation + error schemas + auth/rate-limit
- ✅ `docs/ux/01-05` — UX/UI deliverables (สำหรับ frontend design; UX-06 dropped in SD-as-Master)
- ✅ `docs/ba/` — BA deliverables (สำหรับ traceability)

**Prompt template:**
- `.andm/prompt-templates/technical-design-master-prompt.md`

**วิธีใช้:** Copy prompt template → paste เข้า agent session ใหม่ → กรอก [SYSTEM NAME HERE] และ Context → agent จะสร้าง 3 ไฟล์ (02, 03, 04)

---

### Step 2: สั่ง Review (เปิด session ใหม่)

#### Review ทั้งหมด:
```
/td-review all
```

#### Review ทีละไฟล์:
```
/td-review docs/technical-design/02-backend-design.md
/td-review docs/technical-design/03-frontend-design.md
/td-review docs/technical-design/04-database-design.md
```

> **Valid targets:** `02`, `03`, `04`, หรือ `all` — ไม่มี 01/05/06/07/08 อีกต่อไป (ดู Scope Change callout ด้านบน)

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → TD quality benchmark → `.claude/rules/`
2. **Phase 1 — Preparation:** หา round number, อ่าน target + related TD docs + SD docs + ADRs + UX + BA
3. **Phase 2 — Generate Claims:** Scan 19 technical design attack vector categories + cross-domain consistency (api-specs YAML↔DB↔Frontend)
4. **Phase 3 — Output:** สร้างไฟล์ claim review + รายงานสรุปเป็นภาษาไทย

#### Output:
```
docs/technical-design/claim-review-and-rebuttal/claim-review-01.md
```

ประกอบด้วย:
- Severity summary (CRITICAL / HIGH / MEDIUM / LOW)
- Technical Design Attack Vector Checklist (19 categories — Pass/Finding)
- Findings เรียงตาม severity พร้อม citations
- Cross-domain issues (API↔DB, Frontend↔API, Test↔Requirement mismatches)
- Summary table

---

### Step 3: สั่ง Rebuttal (เปิด session ใหม่)

```
/td-rebuttal docs/technical-design/claim-review-and-rebuttal/claim-review-01.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → TD quality benchmark
2. **Phase 1 — Analysis:** วิเคราะห์ทุก claim → ตัดสิน Accept / Reject / Partial → ตรวจ SD boundary → แสดงตาราง summary

3. **⏸️ HALT — รอ user approve**

   Agent จะแสดงตารางสรุปแล้วหยุดรอ user:
   ```
   | # | Severity | Title                                 | Verdict | Files to Modify     | Cross-Domain Risk | SD Boundary |
   |---|----------|---------------------------------------|---------|---------------------|-------------------|-------------|
   | 1 | CRITICAL | Error codes missing vs api-specs      | Accept  | 02 + api-specs/*    | High              | OK          |
   | 2 | HIGH     | DB index missing for search query     | Accept  | 04                  | Medium            | OK          |
   | 3 | HIGH     | Component tree != UX layout           | Accept  | 03                  | Low               | OK          |
   | 4 | MEDIUM   | Flow appendix missing for checkout    | Partial | 02 § Flow Appendix  | Low               | OK          |
   | 5 | LOW      | Missing code skeleton for helper      | Accept  | 02                  | Low               | OK          |
   ```

   > **Note:** TD-01/05/06/07/08 ถูก drop — cross-domain fixes ที่เคยชี้ไปยังไฟล์เหล่านั้นจะย้ายไปยัง authoritative source:
   > API errors → `docs/api-specs/*.yaml`; pattern decisions → ADR; sequence diagrams → TD-02 § Flow Appendix; test strategy → `docs/qa/01-test-execution-plan.md`; handoff → Impl Planner อ่าน SD 07/08 โดยตรง

   **User ตอบ:**
   - `proceed` → ดำเนินการตาม verdict ที่เสนอ
   - `ปรับ claim 4 เป็น accept` → แก้ verdict แล้วดำเนินการ
   - `reject claim 5, ที่เหลือ proceed` → ปรับเฉพาะจุด

4. **Phase 2 — Execution:** แก้ไข TD docs ทีละ claim (7-step protocol) + cascade check (API↔DB↔Frontend↔Test)
5. **Phase 3 — Write Rebuttal:** สร้างไฟล์ rebuttal report
6. **Phase 4 — Consistency Sweep:** ตรวจ cross-domain consistency ทุกมิติ
7. **Phase 5 — Report:** สรุปผลเป็นภาษาไทย

#### Output:
```
docs/technical-design/claim-review-and-rebuttal/rebuttal-round-01.md
```

ประกอบด้วย:
- Summary (Accepted / Partial / Rejected counts)
- Claim responses ทุก claim พร้อม evidence
- Cascaded changes (cross-domain fixes)
- Strength assessment
- Recommendation (Ready / Re-Review / Needs SD Backtrack / Needs Stakeholder Input)

---

### Step 4: ทำซ้ำ (ถ้ายังไม่ผ่าน)

```
/td-review all
/td-rebuttal docs/technical-design/claim-review-and-rebuttal/claim-review-02.md
```

- Round number จะ auto-detect (02, 03, ...)
- Agent จะ **ไม่ raise finding ซ้ำ** ที่ fix แล้วใน round ก่อน (anti-duplication rule)
- แต่ถ้า fix ไม่สมบูรณ์ จะ raise ใหม่พร้อมอ้างอิง round ก่อน

---

### Step 5: Handoff to Implementation

เมื่อ rebuttal report ระบุ **"Ready for Implementation Handoff ✅"**:

- TD documents (`docs/technical-design/02, 03, 04`) พร้อมเป็น implementation blueprint
- `/impl-plan` อ่าน `docs/design-docs/07-future-evolution.md` + `08-product-breakdown.md` โดยตรง (TD-08 handoff ถูก drop ใน SD-as-Master consolidation)
- Engineer สามารถเริ่ม code ได้ทันทีโดยไม่ต้องตัดสินใจ design เอง
- ใช้ `/impl-plan` สร้าง sprint plan → `/impl-task` implement ทีละ task

---

## File Structure

```
.claude/commands/
  td-review.md                      ← /td-review command definition
  td-rebuttal.md                    ← /td-rebuttal command definition

.agents/skills/
  andm-td-reviewer/SKILL.md            ← Reviewer persona (adversarial engineer)
  andm-td-defender/SKILL.md            ← Defender persona (constructive architect)

.andm/prompt-templates/
  technical-design-master-prompt.md    ← TD master prompt

docs/technical-design/
  02-backend-design.md              ← Class/module structure + pattern skeletons + optional Flow Appendix
  03-frontend-design.md             ← Component tree + state management + routing config
  04-database-design.md             ← Column-level schema + indexes + migrations
  (01, 05, 06, 07, 08 — DROPPED in SD-as-Master consolidation)
  claim-review-and-rebuttal/
    claim-review-01.md              ← Round 1 findings
    rebuttal-round-01.md            ← Round 1 responses + fixes
    claim-review-02.md              ← Round 2 findings (ถ้ามี)
    rebuttal-round-02.md            ← Round 2 responses + fixes
```

---

## Agent Personas

### TD Reviewer (`.agents/skills/andm-td-reviewer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Principal Technical Design Reviewer / Adversarial Engineer |
| **Mindset** | ตรวจว่า design ทุกชิ้นสามารถ implement ได้จริง ไม่มี gap ไม่มี contradiction |
| **Owns** | `claim-review-XX.md` |
| **Cannot modify** | TD deliverables (02, 03, 04), SD docs, ADRs |
| **Key tool** | Technical Design Attack Vector Checklist (19 categories) + cross-domain consistency |
| **Language** | Thai (findings) + English (technical terms) |

### TD Defender (`.agents/skills/andm-td-defender/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Principal Technical Architect & Design Defense Specialist |
| **Mindset** | ยอมรับคำวิจารณ์ที่ถูกต้อง โต้แย้งด้วยหลักฐาน technical |
| **Owns** | `rebuttal-round-XX.md` |
| **Can modify** | TD deliverables (02, 03, 04) |
| **Key tool** | 7-step claim processing + cross-domain cascade check |
| **Language** | Thai (arguments) + English (technical terms) |

---

## ความแตกต่างจาก SD Workflow

| Aspect | SD Workflow | TD Workflow |
|--------|------------|-------------|
| **Level** | Architecture (WHAT + WHERE) | Implementation-ready (HOW + EXACT SHAPE) |
| **Target docs** | `docs/design-docs/02-08` (v1.2: gaps 01/06) | `docs/technical-design/02, 03, 04` (3 docs after SD-as-Master consolidation) |
| **Attack vectors** | 20 SD categories (architecture quality) | 19 TD categories (implementability + cross-domain) |
| **Cross-doc scope** | Design docs + ADRs + API specs + BA NFRs | TD docs + SD docs + ADRs + API specs + UX + BA + .claude/rules/ |
| **Consistency check** | Component names, numbers, tech stack | API↔DB, Frontend↔API, Test↔Requirement, SD compliance |
| **SD Boundary Rule** | N/A | ถ้า fix ต้องเปลี่ยน SD architecture → `/backtrack sd` |
| **Handoff to** | TD (technical design) | Implementation (impl-plan → impl-task) |
| **Commands** | `/sd-review`, `/sd-rebuttal` | `/td-review`, `/td-rebuttal` |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้า TD review/rebuttal พบปัญหาที่แก้ใน TD ไม่ได้ → ต้อง backtrack:

| Trigger | ตัวอย่าง | Action |
|---------|---------|--------|
| **SD architecture ไม่รองรับ** | Service boundary ผิดทำให้ class structure ใน 2 service ซ้อนกัน | `/backtrack sd` |
| **ADR constraint ขัดกับ detail design** | ADR เลือก monolith แต่ feature ต้อง async — class design ทำไม่ได้ | `/backtrack sd` |
| **API spec ขัดกับ data flow** | SD data flow ระบุ POST แต่ API spec เขียน PUT — TD ต่อไม่ได้ | `/backtrack sd` |
| **UX missing page/state** | UX ไม่มี error state สำหรับ form — frontend design ทำไม่ครบ | `/backtrack ux` |
| **BA requirement ขาดหาย** | User flow ไม่ cover edge case ที่ต้อง design test strategy | `/backtrack ba` |

> ⚠️ อย่า patch TD ด้วย assumptions — ถ้า root cause อยู่ที่ upstream → backtrack ก่อน
> **📖 Guide:** `.andm/development-guide/backtrack-workflow.md`

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/td-review` หรือ `/td-rebuttal` เพื่อให้ agent onboard ใหม่ด้วย persona ที่ถูกต้อง
- **Review all** สำหรับ comprehensive cross-domain scan — ถ้า review ทีละไฟล์จะ miss cross-domain issues
- **ตรวจ HALT point** ใน rebuttal — agent จะหยุดรอ approve ก่อนแก้ไข TD docs
- **Cross-domain consistency** คือจุดแข็งของ TD review — ตรวจว่า API field ≈ DB column ≈ Frontend prop ≈ Test data
- **ปกติ 2-3 rounds** เพียงพอสำหรับ TD documents ที่มีคุณภาพดี
- **สร้าง TD หลัง SD + UX ผ่าน review** — TD ต้องอ้างอิง SD decisions ที่ confirmed แล้ว
- **ใช้ร่วมกับ .claude/rules/** — TD reviewer จะตรวจ naming conventions, patterns ตาม tech stack rules ของโปรเจค
