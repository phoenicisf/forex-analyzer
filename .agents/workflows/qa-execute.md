# Workflow: QA Execute

> Run tests defined in the approved QA Plan, map results back to the traceability matrix, and produce an Execution Report. **Runs continuously alongside Phase 3 (Implement)** — not gated to post-review. Final QA Execute pass closes Phase Gate before Phase 4 (Harden) entry.

---

## Prerequisites

- ✅ Phase 3Q QA Plan approved — `docs/qa/01-test-execution-plan.md`, `02-test-cases/`, `03-traceability-matrix.md`
- ✅ Impl tasks referenced by the TC scope ที่จะรันเขียนเสร็จและ merged แล้ว (per-TC, not whole-phase)

**Timing:**
- **Mid-phase (continuous):** run during Phase 3 against scoped TC subsets — earliest signal of structural-vs-empirical drift; complements Mid-Phase Empirical Audit (`impl-task.md § Phase 4`)
- **Phase Gate:** full QA Execute pass required before Phase Gate closure (Phase 3 → Phase 4 entry) — code review CRITICAL/HIGH must be clear at this point
- ❌ ห้าม serialize "code review ก่อน → QA Execute ทีหลัง" pattern — that produces deferred-empirical drift (Shark CMS 2026-04: 71% defect rate when QA Execute deferred to Phase 4)

---

## Phase 0: Onboarding

อ่าน agent persona:
- `.agents/agents/andm-qa-testing.md` — Lead SDET (owns test files, ไม่แก้ production code)

อ่าน baseline rules:
- `.claude/rules/testing.md`

> ⚠️ **Persona boundary:** QA Executor **ไม่แก้ production code** — ถ้า test fail เพราะ bug ใน code ให้ route ไป `/qa-execute-fix` → `/impl-task` เท่านั้น

---

## Phase 1: Preparation

### 1.1 Determine Round Number

```
ตรวจ docs/qa/execution-rounds/
- ถ้าไม่มี folder → round = 01 (สร้าง folder)
- ถ้ามี execution-round-01.md → round = 02
- ...
```

### 1.2 Load Context (parallel reads)

อ่านพร้อมกัน:

1. **QA Plan (authoritative)** — `docs/qa/01-test-execution-plan.md`
   - Test commands per service (`services/api`, `services/web`, `services/worker`)
   - Coverage targets, entry/exit criteria
   - Test environments, test data strategy
2. **Test cases** — `docs/qa/02-test-cases/TC-*.md` (ทุกไฟล์)
3. **Traceability matrix** — `docs/qa/03-traceability-matrix.md`
4. **Impl plan** — `docs/state/impl-plan.md` (verify referenced tasks merged)
5. **Previous rounds** — `docs/qa/execution-rounds/` ทุกไฟล์ (ถ้ามี)
6. **Known flakes** — `docs/qa/known-flakes.md` (ถ้ามี)

### 1.3 Resolve Target

| Argument | Behavior |
|----------|----------|
| `all` | รัน test suite ทั้งหมดตาม QA-01 |
| `TC-FR-*` / `TC-API-*` / `TC-SEC-*` / `TC-DF-*` / `TC-NFR-*` / `TC-EDGE-*` / `TC-UX-*` | รันเฉพาะ category |
| `TC-FR-001` (single ID) | รันเฉพาะ test case เดียว |
| `services/api` / `services/web` / `services/worker` | รันทุก test ของ service เดียว |
| `--manual` | mode บันทึกผล manual test (ไม่รัน automation) — ข้าม Phase 2 ไป Phase 3 |
| `--report-only <path>` | ข้าม execution, parse เฉพาะ CI artifact ที่ path ระบุ (e.g. JUnit XML, coverage JSON) |

### 1.4 Stack Detection

อ่าน QA-01 section **"Test Commands"** — ถ้าไม่มี ให้ **HALT + แจ้ง user** ว่า QA-01 ต้อง define command ก่อน (ห้าม hardcode framework)

---

## Phase 2: Execute

### 2.0 Pre-flight Hygiene

> ⚠️ **กฎเหล็ก:** ห้ามรัน test รอบใหม่ก่อนตรวจ orphaned process — zombies จาก Ctrl+C รอบก่อนจะ steal CPU + ซ่อน root cause

อ่าน `.claude/stack.json` เพื่อดู test runner ของแต่ละ service แล้วทำตามนี้:

1. **Detect orphaned processes** ตาม stack ที่ใช้:
   - .NET: `tasklist /FI "IMAGENAME eq testhost.exe"` (Windows) / `pgrep -f testhost` (Unix)
   - Vitest: `pgrep -f vitest` หรือ `tasklist /FI "IMAGENAME eq node.exe"` (filter parent runner)
   - Jest: `pgrep -f jest` หรือ equivalent
   - Pytest: `pgrep -f pytest`
2. **HALT ถ้าพบ zombies** — แสดง list (PID + runtime + CPU%) + ขอ confirm ก่อน kill:
   ```
   ⚠️ พบ orphaned test runners (อาจเหลือจาก Ctrl+C รอบก่อน):
   - PID 30004: testhost.exe, runtime 54m, CPU 2139s
   - PID 18824: testhost.exe, runtime 44m, CPU 1580s
   → kill ก่อน proceed? (yes/no/inspect)
   ```
3. **Sanity check** — verify เวลาตั้งแต่ run ก่อนหน้า > 30 sec; clean stale lock files / partial JUnit XML จาก run ก่อน
4. **Hang protection flags** — confirm test commands ใน QA-01 มี hang detection flag (per stack):
   - .NET: `--blame-hang-timeout <ms>` ใน command
   - Vitest: `testTimeout` ใน config + `--bail=1`
   - Pytest: `pytest-timeout` plugin loaded + `--timeout=<sec>`
   ถ้าไม่มี → **MEDIUM finding**, log ใน execution report (ไม่ block run แต่ flag ให้ `/qa-rebuttal` แก้ QA-01)

### 2.1 Run Tests

รัน command ตาม QA-01 ต่อ service — **ทีละ service sequential** (เพื่อไม่ให้ log ปน):

1. **Announce** — บอกว่ากำลังรัน service ไหน command อะไร
2. **Execute** — ใช้ `run_command` (หรือเทียบเท่าของ IDE)
3. **Capture** — เก็บ exit code + stdout/stderr + path ไปที่ JUnit/coverage artifact (ถ้า QA-01 กำหนด output path)
4. **Timeout guard** — ถ้าเกิน timeout ใน QA-01 → mark timeout, ไป service ถัดไป

### 2.2 Parse Results

แปลงเป็น **normalized result records**:

```
{
  "tc_id": "TC-FR-001",
  "status": "pass" | "fail" | "skip" | "timeout" | "error",
  "duration_ms": <int>,
  "service": "api" | "web" | "worker",
  "failure_message": "<if fail>",
  "stack_trace": "<if fail, truncated>",
  "coverage_delta": <optional>
}
```

ที่มา: JUnit XML (`junit.xml`), coverage report, pytest/vitest JSON — ระบุใน QA-01

### 2.3 Manual Mode (ถ้า `--manual`)

แสดง checklist ของ TC-* ที่ marked `manual` ใน 02-test-cases/ → ให้ user กรอก pass/fail/notes ทีละข้อ

---

## Phase 3: Map Results

### 3.1 Update Traceability Matrix

แก้ `docs/qa/03-traceability-matrix.md`:
- เพิ่ม column `Round NN Status` (ถ้ายังไม่มี)
- ต่อแต่ละ requirement → rollup status จาก TC ที่ map:
  - ✅ **Pass** — ทุก TC pass
  - ❌ **Fail** — มี TC fail อย่างน้อย 1
  - ⚠️ **Partial** — มี skip/timeout แต่ไม่ fail
  - ⏭️ **Skipped** — TC ทั้งหมด skip
  - — **Not run** — ไม่มี TC ใน scope รอบนี้

### 3.2 Coverage Check

เทียบกับ coverage target ใน QA-01:
- Line / branch / requirement coverage
- ถ้าต่ำกว่า target → log เป็น finding (ไม่ fail รอบ แต่ต้อง flag)

---

## Phase 4: Write Execution Report

### 4.1 Create Report File

สร้าง `docs/qa/execution-rounds/execution-round-{NN}.md`:

```markdown
# QA Test Execution — Round {NN}

| Field | Value |
|-------|-------|
| Date | YYYY-MM-DD |
| Executor | andm-qa-testing agent / manual |
| Target | all / <filter> |
| QA-01 version | <commit-sha or date> |

## Summary

| Metric | Count |
|--------|-------|
| Total TCs run | N |
| ✅ Pass | N |
| ❌ Fail | N |
| ⏭️ Skip | N |
| ⏱️ Timeout | N |
| 🔥 Error | N |

## Coverage

| Scope | Target | Actual | Status |
|-------|--------|--------|--------|
| Line (api) | 80% | 84% | ✅ |
| ... |

## Failing Test Cases

### TC-FR-003 — <title>
- **Service:** api
- **Requirement:** FR-012
- **Failure:** <message>
- **Stack:** <truncated>
- **Suspected cause:** [code | test | spec | flake | env]
- **Proposed route:** `/impl-task IMPL-NNN` | `andm-qa-testing fix test` | `/backtrack sd` | log flake

## Skipped / Timeout
<list>

## Coverage Gaps vs QA-01 Targets
<list>

## Recommendation
- ☐ Pass → proceed to Phase 4 (/red-team)
- ☐ Needs fix → run /qa-execute-fix docs/qa/execution-rounds/execution-round-{NN}.md
```

### 4.2 Update Traceability Matrix

Commit changes ต่อ `docs/qa/03-traceability-matrix.md` ในรอบเดียวกัน

---

## Phase 5: Report to User

รายงานสรุปเป็นภาษาไทย:
- จำนวน pass / fail / skip
- top 3 failing TCs + suspected cause
- coverage vs target
- exit-criteria status
- recommendation: pass → `/red-team` / needs fix → `/qa-execute-fix`

---

## Exit Criteria (เข้า Phase 4 ได้)

- ✅ ไม่มี CRITICAL/HIGH TC fail ค้าง
- ✅ Coverage ≥ target ใน QA-01
- ✅ ทุก requirement ใน `03-traceability-matrix.md` status = Pass (หรือมี documented waiver)
- ✅ Known flakes documented ใน `docs/qa/known-flakes.md`

---

## Escalation Triggers → Backtrack

| Situation | Action |
|-----------|--------|
| QA-01 ไม่มี test command / target ไม่ชัด | HALT — ขอให้ `/qa-rebuttal` update QA-01 |
| Test case spec ไม่ตรงกับ implemented behavior | `/backtrack sd` หรือ `/qa-rebuttal` (แล้วแต่ root cause) |
| Impl task ที่ TC อ้างยังไม่ merge | HALT — รอ `/impl-task` ให้เสร็จก่อน |
| Flakes ≥ threshold ที่ define ใน QA-01 | log + re-run; ถ้ายัง flaky → `/qa-rebuttal` ปรับ test |
