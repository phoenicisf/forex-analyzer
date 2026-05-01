# Amend Deliverables — Development Guide

คู่มือการแก้ไข/เพิ่มเติม deliverables ที่สร้างไว้แล้ว โดยรักษา cross-document consistency ภายใน phase เดียวกัน

---

## v1.2 Impact Tiering (NEW)

ตั้งแต่ v1.2 เป็นต้นมา amend-workflow รองรับ **T1-T4 tier classification** ก่อน impact analysis เพื่อ scope review cascade ให้พอดี:

| Tier | Trigger | Reviews Triggered | Amendment Log |
|------|---------|-------------------|---------------|
| **T1 — Editorial** | Wording, typo, format, label rename | Scoped section review | Skip (no downstream) |
| **T2 — Semantic (intra-phase)** | Add/change content ภายใน phase, ไม่กระทบ Traceability/API/data model | Full source-phase review only (no downstream) | Skip (no downstream) |
| **T3 — Cross-phase** | กระทบ Traceability Matrix / API specs / data model / user flow / NFR / business-rule-on-existing-US | Source review + scoped downstream review | **MANDATORY** — append AMEND-NNN entry ที่ `docs/state/amendment-log.md` (Step 5.5) |
| **T4 — Architectural** | Architecture style / infra / security / auth / role / ADR-backed | Source + full downstream + ADR mandatory | **MANDATORY** — append AMEND-NNN entry ที่ `docs/state/amendment-log.md` (Step 5.5) |

Agent classify tier ตอน Step 1.5 ของ SKILL.md → user confirm ตอน HALT → execute ตาม tier rules — ลด review cascade ของ T1/T2 amendments ได้ 70-80%

> **Tier Floor Rules (v1.3 — anti-underclassification):** ห้าม classify ต่ำกว่า T3 ถ้า amendment touches endpoint / entity / user-flow shape / feature removal / NFR / business-rule-on-existing-US. ห้ามต่ำกว่า T4 ถ้า touches auth / role / permission / security / arch / infra / ADR-backed. ดูตารางเต็มที่ `andm-amend-engineer/SKILL.md § Step 1.5: Tier Floor Rules`

> **Amendment Log (v1.3):** T3/T4 amendments **ต้อง** append entry ที่ `docs/state/amendment-log.md` ก่อนปิด session — `/next` Check 0.5 จะ block phase progression จน open obligations ถูกเคลียร์. ดู Glossary "Amendment Log" + SKILL.md Step 5.5

ดูรายละเอียดที่ `.agents/skills/andm-amend-engineer/SKILL.md § Step 1.5: Classify Tier`

---

## ภาพรวม Flow

```
┌────────────────────────────────────────────────────────────────┐
│  มี deliverables ที่สร้างแล้ว (BA / SD / UX / TD)               │
│  ต้องการ add / change / remove content บางส่วน                  │
│  (ไม่ใช่ rewrite ทั้ง phase — ถ้า rewrite ให้ rerun prompt)     │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /amend <phase> "<description>"                                │
│  Persona: .agents/skills/                     │
│           andm-amend-engineer/SKILL.md                              │
│  (Senior Design Document Specialist — surgical precision)      │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  Step 1: Parse & Load Context    → อ่าน deliverables ทั้ง phase │
│  Step 2: Impact Analysis         → affected files + downstream  │
│  Step 3: ⏸️ HALT — User Approval                                │
│  Step 4: Execute Amendment       → surgical edits (dependency   │
│                                    order, cascade check)        │
│  Step 5: Report                  → summary + downstream actions │
│  Step 5.5: Append Amendment Log  → T3/T4 only — persistent      │
│                                    ledger ที่ /next Check 0.5    │
│                                    scan ก่อน progression         │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
        ถ้ามี downstream impact → /amend <next-phase> หรือ re-review
        (open obligations จะถูก /next surface ทุก session จนกว่าเคลียร์)
```

---

## เมื่อไรควรใช้ `/amend`

### ใช้ `/amend` เมื่อ:

| สถานการณ์ | ตัวอย่าง |
|-----------|---------|
| เพิ่ม content ใหม่ใน phase ที่สร้างแล้ว | เพิ่ม forgot password flow ใน BA |
| เปลี่ยน architectural decision | เปลี่ยน caching จาก Redis เป็น Memcached ใน SD |
| เพิ่ม/แก้ component หรือ state ใน UX | เพิ่ม empty state สำหรับหน้า dashboard |
| เพิ่ม/แก้ endpoint หรือ schema ใน TD | เพิ่ม DELETE /users/:id ใน API contracts + backend design |
| Clarify รายละเอียดที่ไม่ชัดเจน | เพิ่ม detail ให้ NFR-003 ว่า p99 < 200ms |
| ลบ feature ที่ถูก de-scope | ลบ feature export PDF ออกจาก BA |

### ไม่ควรใช้ `/amend` เมื่อ:

| สถานการณ์ | ใช้อะไรแทน |
|-----------|-----------|
| Root cause อยู่ upstream phase | `/backtrack <target-phase>` |
| ต้อง rewrite ทั้ง phase | Re-run prompt template (BA/SD/UX/TD) |
| แก้ code (implementation) | `/impl-task` หรือ manual edit |
| แก้ impl plan | `/impl-plan-rebuttal` (ถ้ามี plan review finding) หรือ direct edit `docs/state/impl-plan.md` (ถ้า surgical fix เช่นเพิ่ม Phase Gate task) — `/amend` ไม่รับ target `impl-plan` |
| แก้ review findings | `/ba-rebuttal`, `/sd-rebuttal`, `/ux-rebuttal`, `/td-rebuttal` |

---

## Amend vs Backtrack — ตัดสินใจอย่างไร

ทั้ง `/amend` และ `/backtrack` แก้ deliverables ที่สร้างแล้ว แต่ context ต่างกัน:

| เกณฑ์ | `/amend` | `/backtrack` |
|-------|---------|-------------|
| **Trigger** | User ต้องการเปลี่ยนแปลง | Downstream phase พบปัญหา upstream |
| **Direction** | แก้ phase ที่ user ระบุ | ย้อนจาก downstream ไป upstream |
| **Scope ownership** | User กำหนด scope | Agent วิเคราะห์ root cause + scope |
| **Invalidation** | Flag downstream impact (ไม่ invalidate อัตโนมัติ) | Mark invalidated phases ใน overview.md |
| **Backtrack log** | ไม่สร้าง | สร้าง entry ใน `docs/state/backtrack-log.md` |
| **Re-validation** | แนะนำ (optional) | บังคับ re-validate downstream |

**Rule of thumb:** ถ้า user เป็นคนริเริ่มการเปลี่ยน → `/amend` ถ้า agent/review พบ problem ที่ต้องย้อน → `/backtrack`

---

## Command Format + Examples

```
/amend <phase> "<amendment description>"
```

| Parameter | ค่าที่ใช้ได้ | คำอธิบาย |
|-----------|------------|---------|
| `phase` | `ba`, `sd`, `ux`, `td` | Phase ที่ต้องการแก้ไข |
| `description` | Free text (Thai/English) | อธิบายสิ่งที่ต้องการ add/change/remove |

### ตัวอย่าง:

```bash
# BA — เพิ่ม user flow
/amend ba "เพิ่ม user flow สำหรับ forgot password + reset via email"

# SD — เปลี่ยน architectural decision
/amend sd "เปลี่ยน caching strategy จาก Redis เป็น Memcached สำหรับ session store"

# UX — เพิ่ม state ที่ขาด
/amend ux "เพิ่ม empty state สำหรับหน้า dashboard"

# TD — เพิ่ม endpoint
/amend td "เพิ่ม endpoint DELETE /users/:id ใน api-contracts + backend design"

# BA — ลบ feature
/amend ba "ลบ feature export PDF — de-scoped จาก MVP"

# SD — clarify
/amend sd "เพิ่ม rate limiting spec: 100 req/min per user สำหรับ public API endpoints"
```

---

## Step-by-Step Process

### Step 1: Parse & Load Context

Agent จะ:

1. **Parse input** — แยก target phase กับ amendment description
2. **Load ALL deliverables** ของ phase นั้น (ไม่ใช่แค่ไฟล์ที่ "น่าจะ" เกี่ยว)
3. **Load quality benchmark** — อ่าน prompt template ของ phase เพื่อรักษา quality bar เดียวกัน
4. **Check review status** — ดูว่า claim-review ผ่านแล้วหรือยัง (ถ้าผ่านแล้ว amendment อาจ invalidate)

#### Deliverables ที่ต้องอ่านตาม phase:

| Phase | Deliverables | Quality Benchmark | Claim Review |
|-------|-------------|-------------------|-------------|
| `ba` | `docs/ba/01-05` (5 files; v1.2: 06-handoff dropped) | `prompt-templates/ba-requirements-prompt.md` | `docs/ba/claim-review-and-rebuttal/` |
| `sd` | `docs/design-docs/02-08` (6 files; v1.2: gaps ที่ 01/06 — merged into 02) + `docs/adr/` + `docs/api-specs/` | `prompt-templates/system-design-master-prompt.md` | `docs/design-docs/claim-review-and-rebuttal/` |
| `ux` | `docs/ux/01-05` (5 files; UX-06 dropped per SD-as-Master) | `development-guide/ux-design-workflow.md` | Stakeholder approve |
| `td` | `docs/technical-design/02,03,04` + `docs/api-specs/` + `docs/adr/` + `docs/qa/01-test-execution-plan.md` | `prompt-templates/technical-design-master-prompt.md` | `docs/technical-design/claim-review-and-rebuttal/` |

> **ทำไมต้องอ่านทั้ง phase?** เพราะ amendment 1 จุดอาจ cascade ไปหลายไฟล์ — เช่น เพิ่ม entity ใน BA ต้อง update ทั้ง functional requirements, user flows, business rules, และ handoff

### Step 2: Impact Analysis

Agent วิเคราะห์ 3 มิติ:

#### 2.1 Affected Files

สำหรับแต่ละ deliverable ใน phase:
- **Grep** หา terms ที่เกี่ยวข้องกับ amendment (entity names, flow names, endpoint names)
- **Assess** ว่าต้องแก้ไหม (Yes / No / Maybe)
- **Describe** sections ที่ต้องเปลี่ยน + change size (Minor tweak / Add section / Rewrite section)

#### 2.2 Downstream Impact

ตรวจว่า phase ถัดไปมี deliverables อยู่แล้วหรือยัง:

```
BA → SD, UX         (ถ้ามี → ต้อง re-validate)
SD → UX, TD, Impl   (ถ้ามี → ต้อง re-validate)
UX → TD, Impl       (ถ้ามี → ต้อง re-validate)
TD → Impl            (ถ้ามี → ต้อง re-validate)
```

#### 2.3 Review Status Impact

ถ้า phase ที่แก้ผ่าน claim-review แล้ว → flag ว่า amendment อาจ invalidate review round นั้น

#### ตัวอย่าง Impact Table:

```markdown
## Amendment Impact Analysis

**Request:** เพิ่ม forgot password flow
**Target Phase:** ba

### Affected Files

| # | File | Impact | Sections to Modify | Change Size |
|---|------|--------|-------------------|-------------|
| 1 | `05-user-flows.md` | ✅ Yes | เพิ่ม Flow-08: Forgot Password | Add section |
| 2 | `02-functional-requirements.md` | ✅ Yes | เพิ่ม US-024 ใน Epic + ResetToken entity | Minor tweak |
| 3 | `04-business-rules.md` | ✅ Yes | เพิ่ม rule: token expiry 30 min | Minor tweak |
| 4 | `01-project-brief.md` | ❌ No | — | — |
| 5 | `03-nfr.md` | ❌ No | — | — |

> **v1.2 note:** open question "email service dependency" ไปอยู่ `05-user-flows.md` § Open Questions (flow domain) — BA-06 dropped

### Downstream Impact

| Phase | Status | Impact |
|-------|--------|--------|
| SD | ✅ มี docs | ⚠️ ต้อง re-validate — new email service dependency |
| UX | ✅ มี docs | ⚠️ ต้อง re-validate — new forgot password screen |
| TD | ❌ ยังไม่มี | ไม่กระทบ |

### Review Status Impact

| Review | Status | Impact |
|--------|--------|--------|
| BA Review Round 01 | ✅ ผ่านแล้ว | ⚠️ Amendment อาจ invalidate — recommend re-review |
```

### Step 3: HALT — User Approval

> **CRITICAL: ห้าม proceed โดยไม่ได้ user approve เด็ดขาด**

Agent แสดง impact analysis แล้วรอ user ตัดสินใจ:

| User Response | Action |
|--------------|--------|
| `proceed` | Execute ทุก changes ตาม analysis |
| `ปรับ scope` | User ขยาย/ลด scope → re-analyze |
| `cancel` | ยกเลิก amendment |

### Step 4: Execute Amendment

Agent แก้ไฟล์ตาม **dependency order** (foundational docs ก่อน → dependent docs ทีหลัง):

| Phase | Dependency Order (foundational → dependent; v1.2) |
|-------|---------------------------------------------|
| `ba` | 01-project-brief → 02-functional-req → 04-business-rules → 05-user-flows → 03-nfr |
| `sd` | 02-architecture (incl. Traceability + ADR Digest sections) → 03-deep-dive → 04-data-flow → 05-security → 07-evolution → 08-product-breakdown + ADRs + API specs |
| `ux` | 01-design-tokens → 02-component-inventory → 03-page-layouts → 04-navigation → 05-interaction-patterns |
| `td` | 02-backend-design → 03-frontend-design → 04-database-design → docs/api-specs/*.yaml → docs/adr/ → docs/qa/01-test-execution-plan.md |

สำหรับแต่ละไฟล์:

```
4.1  Announce     — ประกาศว่ากำลังแก้ไฟล์ไหน + แก้อะไร
4.2  Fresh Read   — อ่านไฟล์ใหม่ (อาจมีการเปลี่ยนจาก file ก่อนหน้า)
4.3  Apply Change — ใช้ Edit tool สำหรับ minimal, focused modifications
4.4  Verify       — อ่านซ้ำ confirm ว่าถูกต้อง
4.5  Cascade      — Grep terms ที่เกี่ยวข้องในไฟล์อื่นของ phase เดียวกัน
                    → update cross-references, numbering, summary tables
4.6  Mark Done    — note ว่าไฟล์นี้เสร็จแล้ว
```

#### Safety Rules:

- ถ้า change ขัดแย้งกับ content ในไฟล์อื่นของ phase เดียวกัน → **STOP + report**
- ถ้า amend SD แล้วเปลี่ยน architecture decision → **ต้อง update/create ADR**
- ถ้า amend TD แล้วต้องเปลี่ยน SD → **แนะนำ `/backtrack sd`** แทน (TD ไม่มีสิทธิ์แก้ SD)

### Step 5: Report

Agent สรุปผล:

```markdown
## Amendment Complete

**Request:** เพิ่ม forgot password flow
**Files Modified:** 4 files

| # | File | Changes Made |
|---|------|-------------|
| 1 | `05-user-flows.md` | เพิ่ม Flow-08: Forgot Password (happy + error paths) |
| 2 | `02-functional-requirements.md` | เพิ่ม US-024: Reset password via email |
| 3 | `04-business-rules.md` | เพิ่ม BR-012: Reset token expiry 30 min |
| 4 | `05-user-flows.md` § Open Questions (v1.2) | Flag email service dependency เป็น flow-domain open question |

### Downstream Actions Needed
- [ ] `/amend sd "เพิ่ม email service dependency + reset token API"` — SD docs ต้อง update
- [ ] `/amend ux "เพิ่ม forgot password screen + reset password screen"` — UX docs ต้อง update
- [ ] `/ba-review all` — BA review Round 01 ผ่านแล้ว ควร re-review

### Consistency Verification
- ✅ Cross-references ข้ามไฟล์ใน BA consistent
- ✅ Numbering/ordering correct
- ⚠️ Downstream phases ต้อง re-validate (SD, UX)
```

---

## Phase-Specific Notes

### Amend BA

- เพิ่ม user flow → ต้อง update functional requirements (user story) + business rules (ถ้ามี rule ใหม่) + handoff (ถ้ามี dependency ใหม่)
- เปลี่ยน scope → ต้อง update project brief (scope section) + functional requirements (add/remove user stories)
- เพิ่ม NFR → ต้อง update `03-nfr.md` + handoff (flag ให้ architect)

### Amend SD

- เปลี่ยน architecture → **ต้อง update/create ADR** ใน `docs/adr/`
- เปลี่ยน API → ต้อง update `docs/api-specs/*.yaml` + data flow diagram
- เปลี่ยน Evolution Sequence (07) → เป็น **HARD constraint** — ถ้าต้องเปลี่ยนจริงต้องมี ADR รองรับ
- เปลี่ยน Phase Hints (08) → เป็น SOFT — เปลี่ยนได้แต่ต้อง update architectural rationale

### Amend UX

- เพิ่ม screen/state → ต้อง update page-layouts (03) + อาจกระทบ navigation (04) + interaction patterns (05)
- เปลี่ยน design tokens → ต้อง cascade ไปทุก component ที่ใช้ token นั้น
- เพิ่ม component → ต้อง update component-inventory (02) + page-layouts ที่ใช้ component นั้น

### Amend TD

- เพิ่ม endpoint → ต้อง update `docs/api-specs/*.yaml` (SD owns) + backend design (02) + อาจกระทบ frontend design (03) + database design (04)
- เปลี่ยน schema → ต้อง update database design (04) + backend design (02) ที่ใช้ entity นั้น
- **TD ห้ามแก้ SD deliverables** — ถ้าต้องเปลี่ยน architecture → แนะนำ `/backtrack sd`

---

## Scope & Ownership ของ Amend Engineer

| Permission | Detail |
|-----------|--------|
| **Can modify** | Deliverables ของ target phase เท่านั้น |
| **Can read** | ทุกไฟล์ใน `docs/`, `.claude/rules/`, `prompt-templates/` |
| **Cannot modify** | Deliverables ของ phase อื่น (flag เท่านั้น) |
| **Cannot modify** | Source code (`services/`), impl plan (`docs/state/impl-plan.md`) |

> ถ้า amendment กระทบ phase อื่น → agent จะ **flag ใน report** พร้อมแนะนำ command ถัดไป แต่ไม่แก้เอง

---

## Best Practices

### ควรทำ

- **อ่าน impact analysis ให้ละเอียดก่อน approve** — agent อาจพบ cascade ที่ user ไม่ได้คาดคิด
- **Amend ทีละ phase** — ถ้าต้องแก้ทั้ง BA + SD ให้ `/amend ba` ก่อน แล้วค่อย `/amend sd`
- **Re-review หลัง amend ถ้า claim-review ผ่านแล้ว** — content ที่แก้อาจ invalidate review findings
- **ระบุ description ให้ชัดเจน** — ยิ่งชัดเท่าไหร่ agent จะ scope ได้แม่นเท่านั้น

### ไม่ควรทำ

- **อย่า amend หลาย phase พร้อมกัน** — แต่ละ phase ต้องจบก่อนจึงจะรู้ว่า downstream ต้องแก้อะไร
- **อย่าใช้ amend แทน rewrite** — ถ้าต้องเปลี่ยนเกินครึ่งของ phase ให้ rerun prompt template ดีกว่า
- **อย่าใช้ amend แทน backtrack** — ถ้า root cause อยู่ upstream ให้ `/backtrack` เพื่อบันทึก log + invalidate downstream อย่างเป็นระบบ
- **อย่า skip impact analysis** — แม้จะดูเป็น "แก้เล็กน้อย" ก็ต้องวิเคราะห์ก่อนเสมอ

---

## Cascading Amendments — Pattern ที่พบบ่อย

เมื่อ amend phase หนึ่งแล้วมี downstream impact ต้อง amend phase ถัดไป:

```
/amend ba "เพิ่ม forgot password flow"
   → report แนะนำ: /amend sd, /amend ux
      │
      ├─ /amend sd "เพิ่ม email service + reset token API"
      │     → report แนะนำ: /amend td
      │        │
      │        └─ /amend td "เพิ่ม ResetToken schema + POST /auth/reset endpoint"
      │
      └─ /amend ux "เพิ่ม forgot password + reset password screens"
```

> ทุก step ต้องมี **human approve** — ไม่ auto-cascade

---

## File Structure

```
methodologies/full-track/
  development-guide/
    amend-workflow.md            ← This file
  workflows/
    amend.md                     ← /amend command workflow
  skills/
    andm-amend-engineer/SKILL.md      ← Amend Engineer persona

.claude/commands/
  amend.md                       ← Claude Code slash command bridge

.windsurf/workflows/
  amend.md                       ← Windsurf slash command bridge
```
