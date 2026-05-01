# Workflow: QA Rebuttal

> Analyze QA Claim Review findings, implement fixes to QA deliverables, and write a structured rebuttal report

---

## Phase 0: Onboarding

อ่าน skill definition:
- `.agents/skills/andm-qa-defender/SKILL.md`

ปฏิบัติตาม Phase 0 Onboarding ใน SKILL.md ก่อนเริ่มงาน

---

## Phase 1: Analysis

### 1.1 Load Context (parallel reads)

อ่านพร้อมกัน:

1. **Claim review file** — ไฟล์ที่ user ระบุ (e.g. `docs/qa/claim-review-and-rebuttal/claim-review-01.md`)
2. **QA deliverables** — `docs/qa/01-03` ทั้งหมด (01-test-execution-plan, 02-test-cases/, 03-traceability-matrix)
3. **Design benchmark** — `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06; SD-02 มี Requirements Traceability + ADR Digest sections)
4. **BA authoritative FR/NFR** — `docs/ba/02-functional-requirements.md`, `03-non-functional-requirements.md`, `04-business-rules.md`
5. **TD testability seams** — `docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` (seam points + mock boundaries — coverage + mock strategy = QA-01 authoritative, ไม่ใช่ TD)
6. **API specs** — `docs/api-specs/*.yaml`
7. **Impl plan** — `docs/state/impl-plan.md` (for sync)

### 1.2 Engage Persona

เข้า role QA Defender — constructive defense mindset ตาม SKILL.md

### 1.3 Analyze Each Claim

สำหรับแต่ละ finding ใน claim review:

| Analysis Item | Description |
|--------------|-------------|
| **Verdict** | Accept / Partial / Reject |
| **Rationale** | ทำไมถึงตัดสินแบบนี้ |
| **Impact Scope** | ไฟล์ไหนที่ต้องแก้ |
| **Cross-Doc Risk** | การแก้จะ impact QA docs อื่นหรือไม่ |
| **Proposed Fix** | สิ่งที่จะทำ (concrete) |

### 1.4 Risk Assessment

ก่อนแก้ไข — ตรวจว่า:
- จะแก้กี่ test cases?
- traceability matrix จะเปลี่ยนอะไร?
- มี risk ที่การแก้จะ break consistency?

### 1.5 Present Analysis to User

แสดง analysis table สรุปทุก findings:

```
| ID | Severity | Verdict | Proposed Fix | Impact |
|----|----------|---------|-------------|--------|
| QA-01-001 | 🔴 | Accept | Add TC-SEC-004 | +1 test case, matrix update |
| QA-01-002 | 🟠 | Partial | Revise TC-FR-002 steps | 1 test case update |
| QA-01-003 | 🟡 | Reject | N/A (out of scope) | None |
```

### ⏸️ HALT — รอ user approve ก่อนแก้ไข

> ❗ ห้ามแก้ไข QA deliverables จนกว่า user จะ approve analysis
> User อาจ override verdict ได้

---

## Phase 2: Execution

**หลัง user approve แล้ว:**

### 2.1 Process Claims (ทีละ claim)

ใช้ 7-Step Claim Processing Protocol จาก SKILL.md:

1. **Announce** — บอกว่ากำลัง process finding ไหน
2. **Fresh Read** — อ่าน design docs section ที่เกี่ยวข้องอีกครั้ง
3. **Cross-Doc Check** — ตรวจ impact กับ QA docs อื่น
4. **Apply Fix** — แก้ไข QA deliverable
5. **Verify** — อ่านซ้ำหลัง fix
6. **Cascade Check** — update traceability matrix ถ้าจำเป็น
7. **Mark Complete** — บันทึก

### 2.2 Handle Rejected Claims

สำหรับ finding ที่ Reject:
- เขียน technical justification พร้อม evidence จาก design docs
- อ้างเหตุผลว่าทำไม current QA approach ถูกต้องแล้ว

---

## Phase 3: Write Rebuttal

### 3.1 Determine Round Number

```
ตรวจ docs/qa/claim-review-and-rebuttal/
- ถ้ามี claim-review-01.md แต่ไม่มี rebuttal → round = 01
- ถ้ามี rebuttal-round-01.md → round = 02
- ...
```

### 3.2 Create Rebuttal File

สร้าง `docs/qa/claim-review-and-rebuttal/rebuttal-round-{NN}.md` ตาม Output Format ใน SKILL.md

โครงสร้าง:
1. Header (date, defender, input, version)
2. Summary (Accept/Partial/Reject counts)
3. Claim Responses (verdict + rationale + changes per finding)
4. Cascaded Changes table
5. Strength Assessment (before/after)
6. Recommendation (pass / needs another round)

---

## Phase 4: Consistency Sweep

หลังแก้ไขทุก claim แล้ว — ตรวจ consistency:

ทำ parallel checks:

1. **Test case IDs unique** — ไม่มี duplicate TC-* IDs
2. **Traceability complete** — ทุก test case ใน `02-test-cases/` มีอยู่ใน matrix
3. **Impl-plan sync** — `Related Impl Task` ใน test cases ยังตรงกับ impl-plan
4. **Strategy-plan alignment** — test plan numbers ตรงกับ strategy scope
5. **Category consistency** — test case categories ตรงกับ strategy test levels
6. **Priority alignment** — CRITICAL test cases map กับ CRITICAL features ใน design docs
7. **API spec coverage** — ทุก endpoint ยังมี contract test
8. **Security coverage** — ทุก threat ใน design-docs/05 ยังมี security test

ถ้าพบ inconsistency → fix ทันที + บันทึกใน Cascaded Changes

---

## Phase 5: Report

รายงานสรุปเป็นภาษาไทย:
- จำนวน Accept / Partial / Reject
- สิ่งที่เปลี่ยนแปลงหลัก (new test cases, updated coverage)
- QA plan strength assessment (before/after)
- recommendation: pass / ต้อง review อีกรอบ
