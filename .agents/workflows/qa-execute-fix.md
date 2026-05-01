# Workflow: QA Execute Fix

> Analyze failing tests from a QA Execution Report, classify root cause, and route fixes to the correct agent/command. **Loops back to `/qa-execute`** until exit criteria met.

---

## Input

Path to execution report file, e.g.:
- `docs/qa/execution-rounds/execution-round-01.md`

---

## Phase 0: Onboarding

อ่าน:
- `.agents/agents/andm-qa-testing.md` — test file ownership (can fix test-level bugs)
- `.claude/rules/testing.md`

> ⚠️ **Routing principle:** การแก้ต้องเกิดที่ root cause — QA Executor **แก้ได้เฉพาะ test files**. Production bug → `/impl-task`. Spec bug → `/backtrack sd`.

---

## Phase 1: Analysis

### 1.1 Load Context (parallel reads)

1. **Execution report** — ไฟล์ที่ user ระบุ
2. **QA Plan** — `docs/qa/01-test-execution-plan.md`, `02-test-cases/`, `03-traceability-matrix.md`
3. **Design benchmark** — `docs/design-docs/02-08` (v1.2: gaps 01/06; for spec-vs-test arbitration)
4. **Impl plan** — `docs/state/impl-plan.md` (for task routing)
5. **Service handoff** — `docs/state/{api,web,worker}/handoff.md`
6. **Previous defense rounds** — `docs/qa/execution-rounds/defense-round-*.md` (ถ้ามี)

### 1.2 Classify Each Failing TC

ต่อแต่ละ failing / timeout / error TC ใน report — ตัดสิน **root cause**:

| Verdict | Root Cause | Routed To | Owner |
|---------|-----------|-----------|-------|
| ✅ **Code bug** | production code ผิด — test ถูก | `/impl-task <IMPL-ID>` | Backend / Frontend agent |
| 🔶 **Test bug** | test ผิด — code ถูกตาม spec | fix `*.test.ts` / `*.spec.ts` ใน `.agents/agents/andm-qa-testing.md` scope | QA Executor (self) |
| ❌ **Spec bug** | ทั้ง code และ test implement ตาม spec แต่ spec ผิด | `/backtrack sd` | SD Defender |
| 📋 **Plan bug** | test case spec (TC-*.md) ใน QA-02 ผิด — mismatch กับ design | `/qa-rebuttal` | QA Defender |
| ⚠️ **Flake** | intermittent — ไม่ reproduce stable | log `docs/qa/known-flakes.md` + retry | QA Executor |
| 🔧 **Environment** | infra / CI / data setup ผิด | fix env config; log in report | QA Executor |

### 1.3 Analysis Table

แสดงให้ user:

```
| TC ID | Severity | Verdict | Root Cause | Routed To | Est. Effort |
|-------|----------|---------|------------|-----------|-------------|
| TC-FR-003 | 🔴 | Code bug | null check missing in OrderService | /impl-task IMPL-042 | S |
| TC-API-007 | 🟠 | Test bug | assertion ใช้ stale schema | andm-qa-testing self-fix | XS |
| TC-SEC-002 | 🔴 | Spec bug | threat model ไม่ครอบ CSRF flow | /backtrack sd | M |
| TC-NFR-001 | 🟡 | Flake | timing-dependent | log + retry | XS |
```

### ⏸️ HALT — รอ user approve classification

> ❗ ห้าม execute fix จนกว่า user จะ approve verdicts
> User อาจ override root-cause classification ได้

---

## Phase 2: Execute Routing

**หลัง user approve:**

### 2.1 Process Each Failing TC

ทีละ TC ตาม verdict:

#### Code bug → `/impl-task`
- Prepare task brief: TC ID, failure message, suspected file/line, regression test location
- Hand off to impl-engineer (ไม่รัน `/impl-task` ใน session นี้ — แสดง command ให้ user run)

#### Test bug → self-fix
- แก้ test file ใน `services/*/tests/` หรือ `*.test.ts`
- Rerun test เพื่อ verify fix
- **ห้ามแตะ production code** ภายใต้ `src/`

#### Spec bug → `/backtrack sd`
- เขียน defect brief ใน `docs/qa/execution-rounds/defense-round-{NN}.md`
- แสดง backtrack command ให้ user

#### Plan bug → `/qa-rebuttal`
- สร้าง synthetic claim review ใน `docs/qa/claim-review-and-rebuttal/claim-review-from-exec-{NN}.md` (format เดียวกับ `/qa-review` output)
- แสดง rebuttal command

#### Flake → log + retry
- Append ไปที่ `docs/qa/known-flakes.md` (สร้างถ้ายังไม่มี) — include TC ID, symptom, suspected cause, retry count
- Rerun **เฉพาะ TC นั้น** 3 ครั้ง — ถ้ายัง fail ≥ 2/3 → promote เป็น Test bug

#### Environment → fix config
- แก้ CI config / test data / seed — commit แยก
- Log ใน report

### 2.2 Handle Rejected Verdicts

ถ้า user override verdict จาก analysis table → follow new verdict, log reasoning ใน defense report

---

## Phase 3: Write Defense Report

### 3.1 Determine Round Number

```
round = matching execution round number
ตรวจ docs/qa/execution-rounds/
- execution-round-01.md + no defense → defense round = 01
- execution-round-01.md + defense-round-01.md → ใหม่คือ defense-round-02 (rerun round)
```

### 3.2 Create Defense Report

สร้าง `docs/qa/execution-rounds/defense-round-{NN}.md`:

```markdown
# QA Defense — Round {NN}

| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Defender | andm-qa-testing agent |
| Input | docs/qa/execution-rounds/execution-round-{NN}.md |

## Verdict Summary

| Verdict | Count |
|---------|-------|
| ✅ Code bug → /impl-task | N |
| 🔶 Test bug → self-fix | N |
| ❌ Spec bug → /backtrack sd | N |
| 📋 Plan bug → /qa-rebuttal | N |
| ⚠️ Flake → logged | N |
| 🔧 Environment → config fix | N |

## Per-TC Resolution

### TC-FR-003
- **Verdict:** Code bug
- **Root cause:** NullReferenceException in `OrderService.Calculate()` line 87
- **Routed to:** `/impl-task IMPL-042`
- **Status:** Awaiting impl-engineer
- **Regression test:** TC-FR-003 already in suite, no new test needed

### TC-API-007
- **Verdict:** Test bug
- **Root cause:** assertion ใช้ field ที่ถูก rename ใน API-012
- **Fix applied:** Updated `services/api/tests/orders.test.ts:45`
- **Rerun result:** ✅ Pass

## Cascaded Changes

| File | Change |
|------|--------|
| services/api/tests/orders.test.ts | Updated assertion field name |
| docs/qa/known-flakes.md | Added TC-NFR-001 |

## Hand-off Commands (for user)

```
/impl-task IMPL-042          # for TC-FR-003
/backtrack sd                # for TC-SEC-002
/qa-rebuttal docs/qa/claim-review-and-rebuttal/claim-review-from-exec-01.md
```

## Recommendation
- ☐ Wait for routed fixes → rerun `/qa-execute all`
- ☐ All self-fixed → rerun `/qa-execute <failing-TCs>` immediately
```

---

## Phase 4: Consistency Sweep

หลังแก้ test bugs + routing พร้อม:

1. **Traceability matrix ยังตรง** — TC IDs ไม่หาย
2. **Test file imports valid** — ไม่ broken ref
3. **Known flakes ไม่ซ้ำ** — dedup by TC ID
4. **Routed task IDs exist** — IMPL-NNN ที่อ้างมีใน `docs/state/impl-plan.md`

---

## Phase 5: Report to User

รายงานสรุปเป็นภาษาไทย:
- classification counts (code/test/spec/plan/flake/env)
- จำนวนที่ self-fixed แล้ว
- commands ที่ user ต้อง run ต่อ
- recommendation: wait for routed fixes vs rerun เลย

---

## Loop

```
/qa-execute all              → execution-round-01.md
/qa-execute-fix exec-01      → defense-round-01.md + route fixes
(user runs routed commands)
/qa-execute all              → execution-round-02.md
/qa-execute-fix exec-02      → defense-round-02.md
...
All pass                     → proceed to /red-team (Phase 4 Harden)
```

---

## Escalation Triggers

| Situation | Action |
|-----------|--------|
| Same TC fail ≥ 3 rounds ด้วย verdict เดียวกัน | Escalate to human — อาจต้อง `/backtrack` ไปเฟสอื่น |
| Spec bug สะสม ≥ 5 TC | `/backtrack sd` แล้ว rerun QA Plan ทั้ง phase 3Q |
| Flake rate > 10% ของ suite | `/qa-rebuttal` — revise test data / mock strategy ใน QA-01 |
