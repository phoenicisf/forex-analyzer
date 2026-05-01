# Code Review Phase — Development Guide

คู่มือการใช้งาน workflow สำหรับ Code Review Phase: ตรวจสอบคุณภาพ code หลัง implementation ก่อนเข้า Harden Phase

---

## ภาพรวม Flow

```
┌────────────────────────────────────────────────────────────────┐
│  ผ่าน Implementation Phase แล้ว                                 │
│  มี working code + tests ใน services/api/, web/, worker/        │
│  Sprint tasks ทั้งหมดถูก mark complete ใน impl-plan              │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-review all  →  Code Reviewer Agent ตรวจ code             │
│  Persona: .agents/skills/andm-code-reviewer/SKILL.md                 │
│  Output: docs/code-review/review-round-XX.md                    │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-review-fix review-round-XX.md  →  Fix findings           │
│  Persona: .agents/skills/andm-impl-engineer/SKILL.md                 │
│  Output: docs/code-review/fix-round-XX.md + code fixes          │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              ┌─────────────────────────┐
              │ ยังมี CRITICAL/HIGH ไหม? │──Yes──▶  /impl-review all (ทำอีกรอบ)
              └───────┬─────────────────┘
                      │ No
                      ▼
              Code ผ่าน QA → Harden Phase (/red-team all)
```

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: รัน Code Review

```
/impl-review all
```
หรือเจาะจง service:
```
/impl-review services/api/
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → impl-plan → design docs → rules
2. **Phase 1 — Load Context:** อ่าน source code + tests + API specs + ADRs + previous reviews
3. **Phase 2 — Systematic Scan:** ตรวจ 13 dimensions (Security, Business Logic, Error Handling, Performance, Over-Engineering, Cross-Service Consistency, Test Coverage, Architecture Compliance, TD Compliance, Test Code Quality, Empirical AC Closure, Functional CRUD Walk, Configuration Completeness — full list: `andm-code-reviewer/SKILL.md § Phase 1`)
4. **Phase 3 — Output:** สร้าง `docs/code-review/review-round-XX.md`

#### Output:
```
docs/code-review/review-round-01.md
```

---

### Step 2: แก้ Findings

```
/impl-review-fix docs/code-review/review-round-01.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 1 — Analysis:** Agent อ่าน review → วิเคราะห์แต่ละ finding → ตัดสิน Accept/Reject/Partial → ตรวจ pattern scope (Grep ดูว่ามี pattern เดียวกันที่อื่นไหม)
2. **Phase 2 — Present Verdicts:** แสดง verdict table → ⏸️ HALT รอ approve

Agent จะแสดง:
```
Verdict Summary:
- Accept: 8 findings (5 cascaded across 12 files)
- Reject: 2 findings (with evidence)
- Partial: 1 finding

Recommend proceeding with fixes?
```

**User ตอบ:**
- `approve` → agent ทำ fixes ทั้งหมด
- `reject finding 3` → ข้าม finding 3
- `ทำเฉพาะ CRITICAL/HIGH` → fix เฉพาะ severity สูง

3. **Phase 3 — Execute Fixes:** แก้ code → เพิ่ม/แก้ tests → cascade fix → micro-commits → update handoff
4. **Phase 4 — Output:** สร้าง `docs/code-review/fix-round-01.md`

#### Output:
```
docs/code-review/fix-round-01.md
+ code fixes + test updates + commits + handoff update
```

---

### Step 3: ทำซ้ำจนผ่าน

```
/impl-review all          ← round 2
/impl-review-fix review-round-02.md
...
```

- Agent จะ **ไม่ raise finding ซ้ำ** ที่แก้ไปแล้ว (Anti-Duplication Rule)
- ปกติ **1-2 rounds** เพียงพอ

---

### Step 4: ไป Harden Phase

เมื่อ code review ผ่าน (ไม่มี CRITICAL/HIGH ค้าง):

```
/red-team all
```

---

## 13 Review Dimensions

> **Authoritative source:** `.agents/skills/andm-code-reviewer/SKILL.md` § Phase 1 (full table with detailed checks per dimension). ตารางนี้เป็น quick reference เท่านั้น — เนื้อหารายละเอียดอยู่ใน SKILL.md

| # | Dimension | ดูอะไร |
|---|-----------|--------|
| 1 | **Security (OWASP)** | Injection, AuthN/AuthZ, sensitive data, CSRF, input validation |
| 2 | **Business Logic** | Requirements match, edge cases, error states, business rules |
| 3 | **Error Handling** | Exception levels, logging context, no silent swallow, retry |
| 4 | **Performance** | N+1, unbounded collections, async/await, unnecessary allocs |
| 5 | **Over-Engineering** | Unnecessary abstractions, premature generalization, dead code |
| 6 | **Cross-Service Consistency** | API contract match, entity naming, error codes |
| 7 | **Test Coverage Gaps** | Critical paths, edge cases, integration tests |
| 8 | **Architecture Compliance** | High-level architecture match, ADR compliance, data flow, security measures |
| 9 | **Technical Design Compliance** | API specs (field types/error codes), backend class structure, frontend component tree, DB column-level schema |
| 10 | **Test Code Quality & Defensive Patterns** | Regex catastrophic backtracking, timeouts, bounded loops, fixture cleanup, no shared mutable state |
| 11 | **Empirical AC Closure Verification** | E-AC `[x]` มี evidence artifact ใน `_session-handoff/` ไหม? Reproducible? Kind matches declared? Forbidden closure pattern ("deferred to operator-runtime") = CRITICAL |
| 12 | **Functional CRUD Walk** | Trigger: review touches user-visible surface. Walk live system in BOTH locales + BOTH themes + BOTH auth roles before findings written. Catches importMap drift / hardcoded i18n / locale-switcher no-op |
| 13 | **Configuration Completeness** | Trigger: code consumes env var / secret / API key / connection string / feature flag. Verify `.env.example` ↔ code refs sync, no silent fallback for production secrets, `[config-audit]` evidence artifact present + reviewed for runtime introspection |

### เปรียบเทียบกับ Red Team

| | Code Review | Red Team |
|---|---|---|
| **เมื่อไร** | หลัง implement, ก่อน harden | หลัง code review ผ่าน |
| **มุมมอง** | Quality Engineer (กว้าง 13 dimensions) | Security Auditor (เจาะลึก OWASP + STRIDE) |
| **ดู code** | ✅ ทั้ง quality + correctness | ✅ เฉพาะ security |
| **ดู design compliance** | ✅ | ❌ |
| **ดู test coverage** | ✅ | ❌ |
| **ดู performance** | ✅ | ❌ |
| **PoC exploit** | ❌ | ✅ |
| **ทำ threat modeling** | ❌ | ✅ (STRIDE) |

---

## File Structure

```
.claude/commands/
  impl-review.md                    ← /impl-review command definition
  impl-review-fix.md                ← /impl-review-fix command definition

.agents/skills/
  andm-code-reviewer/SKILL.md            ← Reviewer persona (Senior Code Reviewer)
  andm-impl-engineer/SKILL.md            ← Engineer persona (fixes code)

.agents/workflows/
  impl-review.md                    ← Platform-agnostic review workflow
  impl-review-fix.md                ← Platform-agnostic fix workflow

docs/code-review/
  review-round-01.md                ← Review findings (created by /impl-review)
  fix-round-01.md                   ← Fix report (created by /impl-review-fix)
  review-round-02.md                ← Round 2...
  fix-round-02.md
```

---

## Agent Personas

### Code Reviewer (`.agents/skills/andm-code-reviewer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Code Reviewer / Adversarial Quality Engineer |
| **Mindset** | find defects before production finds them |
| **Owns** | `docs/code-review/review-round-XX.md` |
| **Cannot modify** | source code, design docs, ADRs |
| **Key tool** | 13-dimension checklist + cross-service verification + live-system functional walk + runtime config introspection |

### Impl Engineer as Fixer (`.agents/skills/andm-impl-engineer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Full-Stack Engineer (fixing mode) |
| **Mindset** | ship fixes with tests, cascade patterns |
| **Can modify** | `services/api/`, `services/web/`, `services/worker/` |
| **Key tool** | Pattern detection (Grep) + cascade fixing |
| **Commit format** | `[fix:service] description \n\n Why: Code review round XX finding XX.N` |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้า code review พบปัญหาที่ fix ใน code ไม่ได้เพราะ root cause อยู่ upstream:

| Trigger | ตัวอย่าง | Backtrack To | Action |
|---------|---------|-------------|--------|
| **Design compliance impossible** | API contract ขัดกับ UI requirement — ต้อง redesign | SD | `/backtrack sd` |
| **Cross-service consistency ล้มเหลว** | Service A กับ B ใช้ data model คนละแบบ — design ไม่ consistent | SD | `/backtrack sd` |
| **Architecture pattern ไม่เหมาะ** | Codebase ทั้งหมดต้อง restructure เพราะ boundary ผิด | SD | `/backtrack sd` |

> ⚠️ ถ้า code review finding ชี้ไปที่ design flaw → อย่าแค่ fix code, ต้อง backtrack แก้ design
> **📖 Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/impl-review` หรือ `/impl-review-fix` เพื่อ fresh context
- **Review "all" ดีกว่า review ทีละ service** — เพราะจับ cross-service inconsistency ได้
- **ไม่ต้อง fix ทุก LOW finding** — focus ที่ CRITICAL/HIGH ก่อน
- **Code review ≠ Red Team** — code review ดูกว้าง 13 dimensions (incl. functional CRUD walk + config completeness + empirical AC closure), red team เจาะลึก security
- **ปกติ 1-2 rounds** เพียงพอ — ถ้าเกิน 3 rounds อาจต้อง review implementation process
