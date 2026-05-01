# Workflow: QA Review

> Audit QA Plan deliverables (test execution plan, test cases, traceability matrix) and generate a structured Claim Review file

---

## Phase 0: Onboarding

อ่าน skill definition:
- `.agents/skills/andm-qa-reviewer/SKILL.md`

ปฏิบัติตาม Phase 0 Onboarding ใน SKILL.md ก่อนเริ่มงาน

---

## Phase 1: Preparation

### 1.1 Determine Round Number

```
ตรวจ docs/qa/claim-review-and-rebuttal/
- ถ้าไม่มี folder → round = 01 (สร้าง folder)
- ถ้ามี claim-review-01.md → round = 02
- ถ้ามี claim-review-02.md → round = 03
- ...
```

### 1.2 Load Context (parallel reads)

อ่านพร้อมกัน:

1. **Design benchmark** — `docs/design-docs/02-08` ทั้งหมด (v1.2: 6 docs, gaps 01/06; SD-02 มี Requirements Traceability + ADR Digest sections, BA docs 02-04 authoritative for FR/NFR)
2. **BA authoritative FR/NFR** — `docs/ba/02-functional-requirements.md`, `03-non-functional-requirements.md`, `04-business-rules.md`
3. **TD testability seams** — `docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` (seam points + mock boundaries ที่ QA hook test cases เข้าไป — coverage targets + mock strategy = QA-01 authoritative, ไม่ใช่ TD)
4. **API specs** — `docs/api-specs/*.yaml`
5. **QA deliverables** — `docs/qa/01-test-execution-plan.md`, `02-test-cases/TC-*.md`, `03-traceability-matrix.md`
6. **Impl plan** — `docs/state/impl-plan.md` (for sync verification)
7. **Testing rules** — `.claude/rules/testing.md`
8. **ADRs** — `docs/adr/*.md`
9. **Previous rounds** — `docs/qa/claim-review-and-rebuttal/` ทุกไฟล์ (anti-duplication)

### 1.3 Anti-Duplication Rule

> ❌ ห้าม raise finding ซ้ำกับ round ก่อนที่ verdict = Accept และถูก fix แล้ว
> ✅ raise ได้ถ้า: finding เดิมที่ Reject แล้วยัง disagree, หรือ Partial ที่ fix ไม่ครบ

### 1.4 Engage Persona

เข้า role QA Reviewer — adversarial mindset ตาม SKILL.md

---

## Phase 2: Generate Claims

### 2.1 Systematic Scan

ตรวจทุก 12 attack vectors ตาม SKILL.md:
- Vectors #1-6: Test Execution Plan
- Vectors #7-11: Test Cases
- Vector #12: Traceability Matrix

### 2.2 Cross-Document Consistency Checks

ตรวจ consistency ระหว่าง QA docs กับ design docs:

| Check | Detail |
|-------|--------|
| **Requirement coverage** | ทุก requirement ใน design-docs/01 มี test case? |
| **API endpoint coverage** | ทุก endpoint ใน api-specs มี contract test? |
| **Security coverage** | ทุก threat ใน design-docs/05 มี security test? |
| **Architecture alignment** | test strategy service scope ตรงกับ design-docs/02? |
| **ADR compliance** | decisions ใน ADRs สะท้อนใน test approach? |
| **Impl-plan sync** | test case ↔ impl task mapping ถูกต้อง? |
| **NFR coverage** | NFR targets ใน design-docs/01 มี performance test? |
| **Data flow coverage** | critical data flows ใน design-docs/04 มี integration test? |

### 2.3 Draft Claims

- เขียน findings เป็นภาษาไทย ตาม Claim Format ใน SKILL.md
- จัดกลุ่มตาม severity (CRITICAL → HIGH → MEDIUM → LOW)

### 2.4 Quality Gate Self-Review

ตรวจตัวเองตาม Phase 4 ใน SKILL.md ก่อนส่ง

---

## Phase 3: Output

### 3.1 Create Claim Review File

สร้าง `docs/qa/claim-review-and-rebuttal/claim-review-{NN}.md` ตาม Output Format ใน SKILL.md

โครงสร้าง:
1. Header (date, reviewer, target, version)
2. Severity Summary table
3. Attack Vector Checklist (12 vectors, pass/finding)
4. Findings (grouped by severity, using claim format)
5. Cross-Document Consistency Issues (if any)
6. Summary Table

### 3.2 Report to User

รายงานสรุปเป็นภาษาไทย:
- จำนวน findings per severity
- top 3 critical/high issues
- overall QA plan strength assessment
- recommendation: pass / needs rebuttal

---

## Target Argument

| Argument | Behavior |
|----------|----------|
| `all` | ตรวจ QA deliverables ทั้งหมด (default) |
| `docs/qa/01-test-execution-plan.md` | ตรวจเฉพาะ test execution plan |
| `docs/qa/02-test-cases/` | ตรวจเฉพาะ test cases |
| `docs/qa/03-traceability-matrix.md` | ตรวจเฉพาะ traceability matrix |
