# F5: Red Team พบ Critical Vulnerability → /backtrack td

> Red Team พบว่า API endpoint ไม่มี rate limiting + input validation ที่ TD กำหนดไว้ แต่ root cause อยู่ที่ TD spec ไม่ครบ ไม่ใช่ code ผิด

---

## Context

- **สถานะ:** Phase 4 (Harden) — Red Team round 1
- **ปัญหา:** Red Team พบว่า `POST /api/tasks` ไม่มี rate limiting และ field `description` ไม่มี max length validation — attacker สามารถ spam task creation + inject 10MB text ใน description ได้
- **ทำไม backtrack ไม่ใช่แค่ fix code:** ตรวจสอบแล้ว TD `01-api-contracts.md` ก็ไม่ได้ระบุ rate limit หรือ max length สำหรับ endpoint นี้ — ปัญหาอยู่ที่ design spec ไม่ครบ ถ้าแก้แค่ code จะขาด documentation trail

---

## Timeline

### Red Team Round 1

```
Session: /red-team all
```

**Agent (Red Team Attacker) พบ:**

```markdown
### Finding RT-01.1: 🔴 CRITICAL — No Rate Limiting on Task Creation

**Endpoint:** POST /api/tasks
**Attack:** Automated script creates 10,000 tasks in 1 minute

**Impact:** 
- Database storage exhaustion
- Notification system overwhelmed (10,000 emails/push)
- Kanban board unusable

**Evidence:** 
ตรวจ code — ไม่มี rate limiting middleware สำหรับ endpoint นี้
ตรวจ docs/api-specs/*.yaml — ไม่มี rate limit spec สำหรับ POST /tasks

**Root Cause:** TD spec ไม่ได้ระบุ rate limit → engineer ไม่ได้ implement

---

### Finding RT-01.2: 🔴 CRITICAL — No Input Length Validation on Task Description

**Endpoint:** POST /api/tasks, field: description
**Attack:** Send 10MB string as description

**Impact:**
- Single request consumes excessive memory
- Database bloat (TEXT column without check constraint)
- API response time degradation when loading task lists

**Evidence:**
ตรวจ code — FluentValidation ไม่มี MaxLength rule สำหรับ description
ตรวจ docs/api-specs/*.yaml — field description ระบุ type: string แต่ไม่มี maxLength
ตรวจ docs/technical-design/04-database-design.md — column description ใช้ TEXT type ไม่มี check constraint

**Root Cause:** TD spec ไม่ได้ระบุ field constraints → engineer ไม่ได้ validate
```

### Red Team Defense — Root Cause Analysis

```
Session: /red-team-rebuttal docs/security/red-team-round-01.md
```

**Agent (Red Team Defender) วิเคราะห์:**

```markdown
| # | Severity | Title | Verdict | Root Cause |
|---|----------|-------|---------|------------|
| 1 | CRITICAL | No Rate Limiting | Accept | TD spec gap — recommend /backtrack td |
| 2 | CRITICAL | No Input Validation | Accept | TD spec gap — recommend /backtrack td |
```

**Agent report:**

```
⚠️ ทั้ง 2 findings มี root cause อยู่ที่ TD spec ไม่ครบ:
- 01-api-contracts.md ไม่มี rate limit per endpoint
- 01-api-contracts.md ไม่มี field constraints (maxLength, pattern)
- 04-database-design.md ไม่มี check constraints

แนะนำ:
1. /backtrack td — แก้ TD specs ให้ครบ
2. แล้ว fix code ตาม TD ที่ update
3. Re-run /red-team
```

### ⏸️ HALT — User approve backtrack

> User: "approve — backtrack ไป TD แก้ spec ก่อน แล้วค่อย fix code"

### Backtrack Execution

```
Session 1: /backtrack td
  → Record BT-002, impact analysis shows: TD needs update, Impl code needs re-fix

Session 2: /amend td "เพิ่ม rate limiting spec ทุก endpoint ใน 01-api-contracts.md (POST: 30/min, GET: 100/min, PATCH: 30/min, DELETE: 10/min) และเพิ่ม field constraints ทุก field (maxLength, pattern, required) ใน 01-api-contracts.md และเพิ่ม check constraints ใน 04-database-design.md"

Agent impact analysis:
  01-api-contracts.md: ✅ เพิ่ม rate limit table + field constraints ทุก endpoint
  04-database-design.md: ✅ เพิ่ม CHECK constraints (description <= 10000 chars, title <= 200 chars)
  02-backend-design.md: ✅ เพิ่ม RateLimitingMiddleware ใน DI registration
  07-test-strategy.md: ✅ เพิ่ม test cases สำหรับ rate limiting + validation

→ User: proceed → Agent แก้ 4 ไฟล์

Session 3: /td-review all
  → 0 CRITICAL/HIGH → ผ่าน ✅

Session 4: กลับไป fix code ตาม TD ที่ update
  /impl-task IMPL-009 (new task: add rate limiting + validation)
  → เพิ่ม rate limiting middleware
  → เพิ่ม FluentValidation rules ตาม TD spec
  → เพิ่ม DB check constraints via migration

Session 5: /red-team all
  → 1 finding (LOW: missing Content-Security-Policy header) → ผ่าน ✅

Close BT-002: ✅ Resolved
```

---

## Workflow Commands Used

| Step | Command | Result |
|------|---------|--------|
| 1 | `/red-team all` | พบ 2 CRITICAL — root cause ที่ TD |
| 2 | `/red-team-rebuttal round-01` | Defender ยืนยัน root cause = TD gap |
| 3 | `/backtrack td` | Impact analysis + record BT-002 |
| 4 | `/amend td "..."` | แก้ TD specs (4 ไฟล์) |
| 5 | `/td-review all` | Verify TD fixes |
| 6 | `/impl-task IMPL-009` | Fix code ตาม updated TD |
| 7 | `/red-team all` | Re-audit → ผ่าน ✅ |
| **Total** | **7 sessions** | **Recovery ~0.5 day** |

---

## Methodology Verdict

✅ **PASS** — Red Team → Backtrack TD → Amend → Re-implement → Re-audit flow ครบ
- Red Team ตรวจจับ root cause ว่าอยู่ที่ TD spec (ไม่ใช่แค่ code)
- Backtrack ไม่ได้ลงไปแค่แก้ code — แก้ที่ design spec ให้ถูกก่อน
- `/amend td` แก้ TD specs พร้อม cascade (API→DB→Backend→Test)
- Code fix ตาม TD ที่ update → มี documentation trail ครบ
- Re-audit verify ว่า vulnerability ถูก fix ทั้ง design + code level
