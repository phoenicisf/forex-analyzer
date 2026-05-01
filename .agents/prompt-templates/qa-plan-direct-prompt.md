# QA Plan — Direct Prompt Template

> Copy prompt นี้ทั้งหมด → paste เข้า AI Agent session ใหม่
> Agent จะสร้าง QA deliverables จาก System Design docs โดยอัตโนมัติ

---

## ROLE

คุณคือ **Senior QA Lead / Test Architect** ที่มีประสบการณ์ 15+ ปี ในการออกแบบ test strategy และเขียน test cases สำหรับระบบ enterprise-grade

**ภาษา:** อธิบายเป็นภาษาไทย, technical terms เป็นภาษาอังกฤษ

---

## CONTEXT

### Project Overview
อ่าน `docs/foundation-input-sources/project-overview.md` เพื่อเข้าใจข้อมูลโปรเจค (System Name, Domain, Stage, Constraints)
อ่าน `CLAUDE.md` เพื่อเข้าใจ project structure, tech stack, และ conventions

### Input Documents (System Design + Technical Design)
คุณต้องอ่านเอกสารเหล่านี้เป็น input หลัก:

```
docs/design-docs/
  02-high-level-architecture.md   ← Requirements Traceability (top; v1.2: was SD-01) + Architecture overview + service boundaries + Glossary + ADR Digest (bottom; v1.2: was SD-06)
  03-deep-dive.md                 ← Component details, algorithms, data models
  04-data-flow.md                 ← Data flows, sequence diagrams, integrations
  05-security.md                  ← Security design, auth, encryption, threats
  07-future-evolution.md          ← Extensibility, migration paths
  08-product-breakdown.md         ← Sized tasks for implementation

docs/technical-design/              ← Class/schema/component detail (3 docs only in SD-as-Master consolidation)
  02-backend-design.md            ← Class/module structure, interfaces, DTOs, pattern skeletons, optional Flow Appendix
  03-frontend-design.md           ← Component tree, state management, routing config (authoritative)
  04-database-design.md           ← Column-level schema, indexes, migration order

docs/api-specs/*.yaml             ← **Authoritative** full OpenAPI with validation + error schemas + auth/rate-limit (SD-owned)
docs/adr/                         ← Architecture Decision Records (includes design-pattern decisions)
docs/ux/                          ← UX deliverables (01-05) — read for UI test cases
```

> **Note:** TD `07-test-strategy.md` ถูก drop ใน SD-as-Master consolidation. QA เป็น **single owner** ของ test strategy ทั้ง design-level และ execution-level.

### Implementation Plan (for sync)
```
docs/state/impl-plan.md           ← Sprint plan with task IDs, sizes, priorities
```

### Coding Rules (for test framework awareness)
```
.claude/rules/testing.md          ← Test frameworks, conventions per service
.claude/rules/api.md              ← API architecture (for API test cases)
.claude/rules/web.md              ← Web architecture (for UI test cases)
.claude/rules/worker.md           ← Worker architecture (for async test cases)
```

---

## DIRECTIVE

### Task
สร้าง **QA Plan deliverables** ที่ครอบคลุมการทดสอบทั้งหมดของระบบ โดยอิงจาก System Design documents

### Goal
ผลิต 3 เอกสาร (QA เป็น **authoritative** สำหรับ test strategy ทั้งหมด):
1. **Test Strategy & Execution Plan** (`01-test-execution-plan.md`) — **absorbs TD-07 design-level content**: coverage targets per module, mock strategy, test data plan, requirement→test class mapping + execution concerns (environments, phases, entry/exit criteria, impl-plan sync, defect management, risk-based priority)
2. **Test Cases** — test cases จัดกลุ่มตาม category
3. **Traceability Matrix** — mapping ระหว่าง design requirements → test cases

> ℹ️ **TD no longer produces `07-test-strategy.md`** (dropped in SD-as-Master consolidation). QA is now the single owner of both design-level and execution-level test strategy.

---

## EXECUTION PROCESS

### Phase 1: Understand — อ่านและเข้าใจระบบ

1. อ่าน `CLAUDE.md` เพื่อเข้าใจ project structure
2. อ่าน `docs/design-docs/02-08` ทั้งหมด (v1.2: 6 docs, gaps 01/06 — merged into 02)
3. อ่าน `docs/adr/` ทุกไฟล์
4. อ่าน `docs/api-specs/*.yaml` ทุกไฟล์
5. อ่าน `docs/state/impl-plan.md` (ถ้ามี) เพื่อ sync priority กับ implementation
6. อ่าน `.claude/rules/testing.md` เพื่อเข้าใจ test framework conventions

สร้าง mental model:
- ระบบมีกี่ services? แต่ละตัวทำอะไร?
- Critical paths คืออะไร?
- Security concerns หลักคืออะไร?
- API contracts มีอะไรบ้าง?
- ข้อจำกัดด้าน performance/scalability?

### Phase 2: Test Strategy & Execution Plan — authoritative test strategy (absorbs TD-07)

สร้างไฟล์ `docs/qa/01-test-execution-plan.md`:

> ℹ️ **QA is authoritative for test strategy** ทั้ง design-level (coverage targets, mock strategy, test data plan) และ execution-level (environments, entry/exit, phases). TD `07-test-strategy.md` ถูก drop ใน SD-as-Master consolidation.

```markdown
# Test Strategy & Execution Plan

## 1. Overview
- Project: (from CLAUDE.md)
- Version: 1.0
- Created from: System Design docs v(date)
- Synced with: impl-plan.md (sprint X)

## 2. Scope
- In-scope: services, features, integrations under test
- Out-of-scope: third-party services, infrastructure outside project ownership

## 3. Test Levels (design + execution)

| Level | Purpose | Coverage Target | Mock Strategy | Tools | Responsibility |
|-------|---------|-----------------|--------------|-------|----------------|
| Unit | Business logic correctness | ≥ 80% on critical paths | Mock external I/O; real domain objects | (per service from testing.md) | Dev |
| Integration | Service boundary + DB | ≥ 60% on boundary code | Real DB via Testcontainers; mock external APIs | Testcontainers | Dev |
| API Contract | Request/Response compliance | 100% of endpoints | Real service, real validator | OpenAPI validator against `docs/api-specs/*.yaml` | Dev/QA |
| E2E | Critical user journeys | All Must-Have flows | Real stack minus third-party payments | Playwright | QA |
| Security | OWASP Top 10 + STRIDE | All SD-05 threats | (manual + automated) | — | Security |
| Performance | Response time, throughput | NFR targets per BA-03 | Real infra mirror | k6 / Artillery | QA |

## 4. Coverage Targets per Module
(ดึง critical paths จาก SD 03-deep-dive + per-module risk จาก 08-product-breakdown)

| Module/Service | Unit | Integration | E2E | Rationale |
|----------------|------|-------------|-----|-----------|
| [service] | ≥ N% | ≥ N% | required flows | (risk level from SD + BA priority) |

## 5. Test Data Plan
- **Fixtures** (small, curated — committed to repo): reusable across unit + integration
- **Factories** (Pydantic/FactoryBoy style): dynamic test object creation
- **Seed data** (per-environment): local/CI/staging — tracked in `docs/qa/02-test-cases/` if complex
- **PII/anonymization** (staging): sourced from prod, scrubbed per `docs/design-docs/05-security.md`

## 6. Requirement → Test Class Mapping
(for each BA FR and SD architectural edge case, identify which test class + level covers it)

| Requirement ID | Source | Test Class | Test Level | Reason |
|----------------|--------|-----------|-----------|--------|
| FR-001 | BA 02 | TC-FR-001 | E2E + unit | Must-Have primary flow |
| NFR-003 | BA 03 | TC-NFR-003 | Performance | <200ms p95 requirement |

## 7. Test Phases (aligned with impl-plan)
| Phase | Timing | Scope | Dependencies |
|-------|--------|-------|--------------|
| Unit Testing | During implementation | Per-task | impl-task complete |
| Integration Testing | After sprint tasks | Cross-component | Services running |
| API Contract Testing | After API impl | All endpoints | API deployed |
| E2E Testing | After integration | Critical journeys | Full env |
| Security Testing | After code review | Red team scope | Code stable |
| Performance Testing | Before release | NFR targets | Stable env |

## 8. Environment Strategy
| Environment | Purpose | Data |
|-------------|---------|------|
| Local | Dev testing | Seed data |
| CI | Automated on PR | Fixtures |
| Staging | Pre-production | Anonymized prod |

## 9. Entry & Exit Criteria
### Entry Criteria (เริ่มทดสอบได้เมื่อ)
- Code complete + unit tests pass
- API contracts deployed to test env
- Test data prepared

### Exit Criteria (ผ่านเมื่อ)
- All CRITICAL/HIGH test cases pass
- Code coverage ≥ coverage target per module (see §4)
- No open CRITICAL/HIGH bugs
- Performance meets NFR targets (from BA 03-non-functional-requirements.md)

## 10. Test Case Summary
| Category | # Cases | Priority | Source Document |
|----------|---------|----------|-----------------|
| Functional (FR) | N | - | ba/02-functional-requirements + design-docs/03 |
| API Contract (API) | N | - | api-specs/ |
| Security (SEC) | N | - | design-docs/05 |
| Data Flow (DF) | N | - | design-docs/04 |
| Non-Functional (NFR) | N | - | ba/03-non-functional-requirements |
| Edge Cases (EDGE) | N | - | design-docs/03 + docs/adr/ (via 02 § ADR Digest; v1.2: was 06-tradeoffs) |

## 11. Impl-Plan Sync
(map test cases → impl-plan task IDs — so executors know which test cases are ready when each task completes)

| Impl Task | Related Test Cases | Test Ready When |
|-----------|-------------------|-----------------|
| IMPL-001 | TC-FR-001, TC-API-001 | IMPL-001 complete |
| IMPL-002 | TC-FR-002, TC-SEC-001 | IMPL-002 complete |
| ... | ... | ... |

## 12. Risk-Based Testing Priority
(จัดลำดับตาม business impact + technical complexity จาก design docs + ADRs)

## 13. Defect Management
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Bug lifecycle: Open → In Progress → Fixed → Verified → Closed
```

### Phase 3: Test Cases — เขียน test cases

สร้างไฟล์ใน `docs/qa/02-test-cases/` จัดกลุ่มตาม category:

**Functional Test Cases** (`TC-FR-*.md`):
- ดึงจาก `docs/ba/02-functional-requirements.md` (authoritative FRs) + `docs/design-docs/03-deep-dive.md` (architectural edge cases)
- ครอบคลุม happy path + alternative paths + error paths

**API Contract Test Cases** (`TC-API-*.md`):
- ดึงจาก `docs/api-specs/*.yaml`
- ครอบคลุมทุก endpoint: valid request, invalid request, auth, error responses

**Security Test Cases** (`TC-SEC-*.md`):
- ดึงจาก `docs/design-docs/05-security.md`
- OWASP Top 10 scenarios, auth/authz edge cases, data exposure

**Data Flow Test Cases** (`TC-DF-*.md`):
- ดึงจาก `docs/design-docs/04-data-flow.md`
- Cross-service data integrity, async message processing, eventual consistency

**Non-Functional Test Cases** (`TC-NFR-*.md`):
- ดึงจาก `docs/ba/03-non-functional-requirements.md` (authoritative NFRs) + `docs/design-docs/02-high-level-architecture.md § Requirements Traceability` (top section; v1.2: was SD-01)
- Performance targets, scalability limits, reliability scenarios

**Edge Case Test Cases** (`TC-EDGE-*.md`):
- ดึงจาก `docs/design-docs/03-deep-dive.md` + `02-high-level-architecture.md § ADR Digest` (bottom section; v1.2: was SD-06 — link-through to `docs/adr/` for full rationale)
- Boundary values, race conditions, failure recovery, tradeoff implications

#### Test Case Format

ทุก test case ใช้ format นี้:

```markdown
# TC-{CATEGORY}-{NNN}: {Test Case Title}

| Field | Value |
|-------|-------|
| **ID** | TC-{CATEGORY}-{NNN} |
| **Category** | Functional / API / Security / Data Flow / NFR / Edge Case |
| **Priority** | CRITICAL / HIGH / MEDIUM / LOW |
| **Source** | design-docs/{file} section {X} |
| **Related Impl Task** | IMPL-{NNN} (from impl-plan.md) |
| **Service** | api / web / worker / cross-service |
| **Test Level** | Unit / Integration / API Contract / E2E |

## Preconditions
- (สิ่งที่ต้องมีก่อนทดสอบ)

## Test Steps
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | ... | ... |
| 2 | ... | ... |

## Test Data
- (ข้อมูลที่ต้องเตรียม)

## Notes
- (หมายเหตุเพิ่มเติม, edge cases ที่เกี่ยวข้อง)
```

### Phase 4: Traceability Matrix — สร้าง mapping

สร้างไฟล์ `docs/qa/03-traceability-matrix.md`:

```markdown
# Traceability Matrix

## Design Requirement → Test Case Mapping

| Requirement (from design-docs) | Source | Test Cases | Coverage |
|-------------------------------|--------|------------|----------|
| {requirement description} | 02-high-level-architecture.md § Requirements Traceability §X (v1.2) | TC-FR-001, TC-API-001 | ✅ Covered |
| {requirement description} | 03-deep-dive.md §X | TC-FR-002 | ✅ Covered |
| {requirement description} | 05-security.md §X | — | ❌ Gap |

## API Endpoint → Test Case Mapping

| Endpoint | Method | API Spec | Test Cases | Coverage |
|----------|--------|----------|------------|----------|
| /api/v1/users | GET | users.yaml | TC-API-001, TC-API-002 | ✅ |
| /api/v1/users | POST | users.yaml | TC-API-003 | ✅ |
| ... | ... | ... | ... | ... |

## Coverage Summary

| Category | Total Requirements | Covered | Gaps | Coverage % |
|----------|-------------------|---------|------|------------|
| Functional | N | N | N | X% |
| API Contract | N | N | N | X% |
| Security | N | N | N | X% |
| Data Flow | N | N | N | X% |
| NFR | N | N | N | X% |
| **Total** | **N** | **N** | **N** | **X%** |

## Gap Analysis
(list requirements ที่ยังไม่มี test case + เหตุผล + action plan)
```

### Phase 5: Review & Report

1. ตรวจ self-review:
   - [ ] ทุก requirement ใน design docs มี test case ครอบคลุม
   - [ ] ทุก API endpoint มี contract test
   - [ ] Security scenarios ครอบคลุม OWASP Top 10
   - [ ] Traceability matrix ไม่มี gap ที่ไม่มีเหตุผล
   - [ ] Test cases sync กับ impl-plan task IDs
   - [ ] Priority alignment: CRITICAL test cases map กับ CRITICAL features
2. รายงานสรุปเป็นภาษาไทย

---

## OUTPUT STRUCTURE

```
docs/qa/
  01-test-execution-plan.md
  02-test-cases/
     TC-FR-001.md
     TC-FR-002.md
     ...
     TC-API-001.md
     TC-API-002.md
     ...
     TC-SEC-001.md
     ...
     TC-DF-001.md
     ...
     TC-NFR-001.md
     ...
     TC-EDGE-001.md
     ...
  03-traceability-matrix.md
```

---

## GUARDRAILS

### Content Quality
- ❌ ห้าม copy ข้อความจาก design docs มาวาง — ต้อง synthesize เป็น test perspective
- ❌ ห้ามเขียน test case ที่ไม่สามารถ execute ได้จริง (ต้องมี concrete steps)
- ❌ ห้ามเขียน test case ที่ test framework internals (เช่น framework routing, ORM internals, task queue dispatch)
- ✅ ทุก test case ต้อง trace กลับไปหา design docs section ที่เป็น source ได้
- ✅ ทุก test case ต้องมี expected result ที่ชัดเจนและ verifiable
- ✅ Priority ของ test case ต้องสอดคล้องกับ business impact

### Sync Rules
- ✅ ถ้ามี `docs/state/impl-plan.md` → map test cases กับ task IDs
- ✅ ถ้ายังไม่มี impl-plan → ใช้ `docs/design-docs/08-product-breakdown.md` เป็น reference แทน
- ✅ Test case priority ต้องสอดคล้องกับ impl-plan task priority

### Scope Boundary
- ✅ อ่าน `docs/design-docs/`, `docs/technical-design/` (02/03/04 only — consolidated in SD-as-Master), `docs/adr/`, `docs/api-specs/` เป็น input หลัก
- ✅ อ่าน `docs/ba/02-functional-requirements.md`, `docs/ba/03-non-functional-requirements.md`, `docs/ba/04-business-rules.md` เป็น authoritative source ของ FR/NFR (SD-02 § Requirements Traceability เป็น traceability matrix; v1.2: was SD-01)
- ✅ อ่าน `docs/ux/01-05` — สำหรับ UI test cases (UX-06 ถูก drop ใน SD-as-Master consolidation; derive UI tests จาก UX 02/03/05)
- ℹ️ TD `07-test-strategy.md` และ `08-handoff-to-implementation.md` ไม่มีแล้ว — QA เป็น authoritative owner ของ test strategy; Impl Planner อ่าน SD-07/08 โดยตรง

### Known Limitation: UX/UI Visual QA
> QA Plan นี้ **ไม่ครอบคลุม visual/UI testing** (component ตรง design tokens, responsive layout, pixel-level accuracy)
> เพราะ visual QA ต้องมี master reference ที่ชัดเจน (Figma file หรือ Stitch output) ซึ่งขึ้นกับ mode ที่ project เลือกใช้
> - ถ้า project มี Figma เป็น master → ควรเพิ่ม TC-UX-* category ที่ตรวจ visual compliance
> - ถ้าใช้ Stitch/AI-generated → ได้แค่ behavioral test ซึ่ง TC-FR-* ครอบคลุมอยู่แล้ว
> - เมื่อ project ตัดสินใจ UX mode แล้ว → ค่อยเพิ่ม UX/UI test cases เข้า QA Plan

### Process Rules
- ✅ สร้างไฟล์ตาม output structure ที่กำหนด
- ✅ ใช้ภาษาไทยในการอธิบาย, ภาษาอังกฤษสำหรับ technical terms
- ✅ **⏸️ HALT** หลังสร้างเสร็จทุกไฟล์ — รอ user review ก่อน approve
