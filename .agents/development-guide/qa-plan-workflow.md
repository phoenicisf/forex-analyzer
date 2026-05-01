# QA Plan Workflow Guide

วิธีสร้างและตรวจสอบ QA Plan deliverables — ทำงาน **parallel กับ Phase 3 (Implement)**

> ⚠️ **Scope change: QA-01 is now authoritative (SD-as-Master consolidation)**
>
> TD-07 test-strategy ถูก drop — design-level strategy (coverage targets, mock strategy, test data strategy) รวมอยู่ใน `docs/qa/01-test-execution-plan.md` เป็น **single authoritative source** แล้ว
> TD-08 handoff ก็ถูก drop — Impl Planner อ่าน SD 07/08 โดยตรง ไม่ต้องผ่าน intermediate doc

---

## Flow Overview

```
Phase 2 ผ่าน (Design QA approved)
         │
         ├─→ Phase 3: IMPLEMENT (Sprint Plan → Impl Tasks → Code Review)
         │
         └─→ Phase 3Q: QA PLANNING (parallel)
              │
              ├── Step 1: สร้าง QA deliverables (prompt template)
              │      ↓
              ├── Step 2: QA Review (adversarial)
              │      ↓
              ├── Step 3: QA Rebuttal (fix + defend)
              │      ↓
              ├── Step 4: ทำซ้ำจนผ่าน
              │      ↓
              ├── Step 5: QA Plan approved ✅
              │
              └── § 3T: Test Execution (หลัง code review ผ่าน)
                        /qa-execute → /qa-execute-fix → loop → /red-team
```

---

## Step 1: สร้าง QA Deliverables — Prompt Template

### Prerequisites
- ✅ `docs/design-docs/02-08` ครบและผ่าน review (v1.2: 6 docs, gaps 01/06 merged into 02)
- ✅ `docs/adr/` up-to-date
- ✅ `docs/api-specs/*.yaml` ครบ
- ✅ (optional) `docs/state/impl-plan.md` สำหรับ sync

### วิธีใช้

1. เปิด AI Agent session ใหม่
2. Copy prompt จาก `.agents/prompt-templates/qa-plan-direct-prompt.md`
3. Paste เข้า session
4. Agent จะสร้าง:

```
docs/qa/
  01-test-execution-plan.md        ← ⭐ AUTHORITATIVE: scope, test levels (execution + design strategy),
                                     coverage targets, mock strategy, test data strategy, environments,
                                     entry/exit, impl-plan sync, defect mgmt
                                     (TD-07 test-strategy ถูก drop — strategy รวมอยู่ที่นี่แล้ว)
  02-test-cases/
     TC-FR-001.md ... TC-FR-NNN.md     ← Functional test cases
     TC-API-001.md ... TC-API-NNN.md   ← API contract test cases
     TC-SEC-001.md ... TC-SEC-NNN.md   ← Security test cases
     TC-DF-001.md ... TC-DF-NNN.md     ← Data flow test cases
     TC-NFR-001.md ... TC-NFR-NNN.md   ← Non-functional test cases
     TC-EDGE-001.md ... TC-EDGE-NNN.md ← Edge case test cases
     TC-UX-001.md ... TC-UX-NNN.md     ← (optional) UI test cases — ถ้ามี docs/ux/ available
  03-traceability-matrix.md        ← Requirement → Test Case mapping
```

5. **⏸️ HALT** — review ผลลัพธ์ก่อนดำเนินการต่อ

### Input Source

> ⚠️ QA Planning อ่าน **System Design docs เป็นหลัก** + **BA docs (02-functional-requirements, 03-non-functional-requirements, 04-business-rules) สำหรับ FR/NFR ที่ SD 01 reference กลับไป** (SD 01 เป็น traceability matrix ไม่ใช่ full spec)
> ✅ **อนุญาตให้อ่าน `docs/ux/` ได้** — เพื่อสร้าง UI test cases (TC-UX-*) หาก UX deliverables พร้อมใช้งาน

| Input | Location | Purpose |
|-------|----------|---------|
| Technical requirements | `docs/design-docs/02-high-level-architecture.md § Requirements Traceability` (top section; v1.2: was SD-01) + `docs/ba/02-functional-requirements.md` + `docs/ba/03-non-functional-requirements.md` (authoritative) | Functional + NFR test cases |
| Architecture | `docs/design-docs/02-high-level-architecture.md` | Service scope, test levels |
| Component details | `docs/design-docs/03-deep-dive.md` | Deep functional + edge cases |
| Data flows | `docs/design-docs/04-data-flow.md` | Integration + data flow tests |
| Security design | `docs/design-docs/05-security.md` | Security test cases |
| Tradeoffs | `docs/design-docs/02-high-level-architecture.md § ADR Digest` (bottom section; v1.2: was SD-06) — link-through to `docs/adr/` for full rationale | Edge case test cases |
| API contracts | `docs/api-specs/*.yaml` | API contract test cases |
| ADRs | `docs/adr/*.md` | Architecture compliance tests |
| UX deliverables (optional) | `docs/ux/01-05` | UI test cases (TC-UX-*) — component states, responsive, a11y |
| Impl plan | `docs/state/impl-plan.md` | Task-test case sync |

> **Note:** TD-07 (test-strategy) และ TD-08 (handoff) ถูก drop ใน SD-as-Master consolidation — **ไม่ต้องอ่าน** เป็น input ของ QA planning แล้ว design-level strategy รวมอยู่ใน QA-01 เป็น authoritative source

---

## Step 2: QA Review — ตรวจคุณภาพ QA docs

### Command

```
/qa-review all
```

### สิ่งที่เกิดขึ้น

1. **QA Reviewer Agent** (adversarial persona) ตรวจ QA deliverables ทั้งหมด
2. ใช้ 12 attack vectors:
   - #1-6: Test Execution Plan (scope, levels+tooling, environments, criteria, impl-plan sync+phase, risk+coverage)
   - #7-11: Test Cases (functional, API, security, negative, quality)
   - #12: Traceability (gaps)
3. Cross-check กับ design docs เพื่อหา coverage gaps
4. Output: `docs/qa/claim-review-and-rebuttal/claim-review-01.md`

### Severity Levels

| Icon | Level | ความหมาย |
|------|-------|----------|
| 🔴 | CRITICAL | Missing coverage สำหรับ critical flow — อาจพลาด production bug |
| 🟠 | HIGH | Test case มีแต่ไม่ถูก/ไม่ครอบคลุม — ผ่านแต่ไม่จับ bug |
| 🟡 | MEDIUM | ปรับปรุงเพื่อเพิ่ม effectiveness |
| ⚪ | LOW | Suggestion / best practice |

---

## Step 3: QA Rebuttal — แก้ไข + โต้แย้ง

### Command

```
/qa-rebuttal docs/qa/claim-review-and-rebuttal/claim-review-01.md
```

### สิ่งที่เกิดขึ้น

1. **QA Defender Agent** อ่าน claim review + QA deliverables + design docs
2. วิเคราะห์ทุก finding → ตัดสิน Accept / Partial / Reject
3. **⏸️ HALT** — แสดง analysis table → รอ user approve ก่อนแก้
4. แก้ไข QA deliverables ตาม verdict
5. ตรวจ consistency sweep (8 checks)
6. Output: `docs/qa/claim-review-and-rebuttal/rebuttal-round-01.md`

### Verdict Framework

| Verdict | Action |
|---------|--------|
| ✅ Accept | Fix QA docs ตาม finding |
| 🔶 Partial | Fix เฉพาะส่วนที่เห็นด้วย |
| ❌ Reject | อธิบายเหตุผลพร้อม evidence |

---

## Step 4: ทำซ้ำจนผ่าน

```
Round 1:  /qa-review all         → claim-review-01.md
          /qa-rebuttal ...       → rebuttal-round-01.md

Round 2:  /qa-review all         → claim-review-02.md  (anti-duplication)
          /qa-rebuttal ...       → rebuttal-round-02.md

Round N:  (ไม่มี CRITICAL/HIGH ค้าง) → ✅ PASS
```

**Exit criteria:**
- ✅ ไม่มี CRITICAL findings ค้าง
- ✅ ไม่มี HIGH findings ค้าง
- ✅ Traceability matrix coverage ≥ 95%
- ✅ ทุก API endpoint มี contract test
- ✅ Security test cases ครอบคลุม OWASP Top 10

---

## Step 5: QA Plan Approved

เมื่อผ่าน review → QA Plan พร้อมสำหรับ:
- **Test execution (Phase 3T)** — ใช้ `/qa-execute all` ดู § 3T ด้านล่าง
- **Code review reference** — reviewer ใช้ test cases เป็น checklist
- **Red team input** — security test cases เป็น baseline สำหรับ red team

---

## § 3T: Test Execution (Phase 3 → Phase 4 Bridge)

> ทำหลัง code review ผ่าน + QA Plan approved — ก่อนเข้า Phase 4 (Harden)

### Commands

| Command | Purpose | Output |
|---------|---------|--------|
| `/qa-execute all` | รัน test suite ทั้งหมดตาม QA-01 | `docs/qa/execution-rounds/execution-round-NN.md` + updated `03-traceability-matrix.md` |
| `/qa-execute TC-FR-001` | รันเฉพาะ test case | (same, scoped) |
| `/qa-execute services/api` | รันเฉพาะ service | (same, scoped) |
| `/qa-execute --manual` | checklist mode (ไม่รัน automation) | report เดียวกัน |
| `/qa-execute --report-only <path>` | parse CI artifact ที่รัน external แล้ว | report เดียวกัน |
| `/qa-execute-fix <report>` | classify failing TCs + route fixes | `docs/qa/execution-rounds/defense-round-NN.md` |

### Fix Routing (verdict framework)

| Verdict | Root Cause | Routed To |
|---------|-----------|-----------|
| ✅ **Code bug** | production code ผิด | `/impl-task <IMPL-ID>` |
| 🔶 **Test bug** | test ผิด — code ถูกตาม spec | andm-qa-testing self-fix (ใน `services/*/tests/`) |
| ❌ **Spec bug** | design doc ผิด | `/backtrack sd` |
| 📋 **Plan bug** | TC-*.md ใน QA-02 ผิด | `/qa-rebuttal` |
| ⚠️ **Flake** | intermittent | log `docs/qa/known-flakes.md` + retry |
| 🔧 **Environment** | CI/infra/data | fix config inline |

### Loop

```
/qa-execute all              → execution-round-01.md
/qa-execute-fix exec-01      → defense-round-01.md + routed commands
(user รัน routed commands: /impl-task, /backtrack sd, /qa-rebuttal)
/qa-execute all              → execution-round-02.md
...
ทุก requirement pass + coverage ≥ target → ✅ proceed to /red-team
```

### Exit criteria (เข้า Phase 4)

- ✅ ไม่มี CRITICAL/HIGH TC fail ค้าง
- ✅ Coverage ≥ target ที่ QA-01 กำหนด
- ✅ ทุก requirement ใน `03-traceability-matrix.md` status = Pass (หรือมี documented waiver)
- ✅ Known flakes documented

### Persona

- **andm-qa-testing (Lead SDET)** — `.agents/agents/andm-qa-testing.md`
- ⚠️ **ห้ามแก้ production code** — test file ownership เท่านั้น, bug ใน `src/` ต้อง route ไป `/impl-task`

**📖 Workflows:** `.agents/workflows/qa-execute.md`, `.agents/workflows/qa-execute-fix.md`

---

## Parallel Timeline กับ Implementation

```
Week 1          Week 2          Week 3          Week 4
├── Impl ──────────────────────────────────────────┤
│   Sprint Plan → Tasks → Tasks → Code Review      │
│                                                   │
├── QA Plan ───────────────┤                        │
│   QA docs → Review → Fix │                        │
│                          │                        │
│                    QA Plan ready ──→ (inform code review)
│                                 ──→ (ready for test execution)
```

### Sync Points กับ Implementation

| Sync Point | เมื่อไหร่ | Action |
|-----------|----------|--------|
| **impl-plan created** | หลัง `/impl-plan` | QA Plan map test cases → impl task IDs |
| **impl-plan changed** | ระหว่าง sprint | QA Defender update `01-test-execution-plan.md` sync table |
| **QA Plan approved** | หลังผ่าน review | Share test cases กับ code reviewer เป็น reference |
| **Code review** | หลัง sprint tasks เสร็จ | Code reviewer ใช้ test cases เป็น coverage checklist |

---

## File Structure

```
docs/qa/
  01-test-execution-plan.md
  02-test-cases/
     TC-FR-*.md
     TC-API-*.md
     TC-SEC-*.md
     TC-DF-*.md
     TC-NFR-*.md
     TC-EDGE-*.md
  03-traceability-matrix.md
  claim-review-and-rebuttal/
     claim-review-01.md
     rebuttal-round-01.md
     claim-review-02.md
     rebuttal-round-02.md
     ...
```

---

## Agent Personas

| Persona | Skill | Role |
|---------|-------|------|
| **QA Planner** | (prompt template) | สร้าง QA deliverables จาก design docs |
| **QA Reviewer** | `.agents/skills/andm-qa-reviewer/SKILL.md` | Adversarial — 15 attack vectors, coverage gaps |
| **QA Defender** | `.agents/skills/andm-qa-defender/SKILL.md` | Constructive — Accept/Partial/Reject + fix |

---

## Differences from Other Review Workflows

| Aspect | BA Review | SD Review | QA Review |
|--------|-----------|-----------|-----------|
| **Input source** | BA docs | Design docs | QA docs (verified against design docs) |
| **Attack vectors** | 20 (BA-specific) | 20 (architecture) | 15 (test quality + coverage) |
| **Cross-check with** | Stakeholder needs | BA docs + code feasibility | Design docs + API specs + impl-plan |
| **Unique focus** | Business completeness | Technical soundness | Test coverage + executability |
| **Sync with** | — | BA docs | impl-plan (task IDs) |

---

## Escalation Triggers → Backtrack

| Situation | Action |
|-----------|--------|
| Design docs มี ambiguity ที่ทำให้เขียน test case ไม่ได้ | `/backtrack sd` — ขอ clarify design docs |
| API spec ไม่ match กับ design docs | `/backtrack sd` — ขอ fix API spec |
| Security design ไม่ครอบคลุมพอสำหรับ security tests | `/backtrack sd` — ขอ expand security design |
| Impl-plan เปลี่ยนจนทำให้ test plan sync ไม่ได้ | Re-sync test plan (ไม่ต้อง backtrack) |

---

## UX/UI Visual QA (Optional — ขึ้นกับ UX mode)

> ✅ **SD-as-Master update:** QA Planning อนุญาตอ่าน `docs/ux/01-05` เพื่อสร้าง TC-UX-* category ได้เลย ไม่ต้องรอ visual master file

| UX Mode | Visual QA ได้หรือไม่ | เหตุผล |
|---------|---------------------|--------|
| **Figma-First** | ✅ ได้เต็มรูปแบบ | มี Figma file + UX specs เป็น visual master |
| **Stitch/AI-Generated** | ⚠️ ได้ระดับ spec (ไม่ pixel-perfect) | มี UX text specs แต่ไม่มี visual master |
| **Existing UI Audit** | ⚠️ บางส่วน | มี UI + audit แต่อาจไม่มี formal spec ครบ |
| **Reference-Driven** | ⚠️ ได้ตาม design vision | มี `00-design-vision.md` + Do's/Don'ts เป็น baseline |

**TC-UX-* scope** (เมื่อมี UX deliverables):
- **Design token compliance** — colors, typography, spacing ตรง `docs/ux/01-design-tokens.md`
- **Component states** — default/hover/active/disabled/loading/error ตรง `docs/ux/02-component-inventory.md`
- **Page layout coverage** — ทุก user flow มี test ที่ verify page layout ตรง `docs/ux/03-page-layouts.md`
- **Responsive breakpoints** — mobile / tablet / desktop ตรง spec
- **Accessibility** — WCAG AA compliance

---

## Tips

1. **เริ่ม QA Planning ทันทีที่ Design QA ผ่าน** — ไม่ต้องรอ implementation เริ่ม
2. **ใช้ session ใหม่ทุกครั้ง** — persona ต้อง fresh ทุก round
3. **Sync กับ impl-plan เมื่อพร้อม** — ถ้ายังไม่มี impl-plan ให้ใช้ product-breakdown แทน
4. **Human approve ทุก HALT** — อย่าให้ AI approve AI
5. **Share test cases กับ code reviewer** — เพิ่ม test coverage visibility
