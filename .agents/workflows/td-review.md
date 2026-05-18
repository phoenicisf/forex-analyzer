---
description: Audit technical design documents and generate a structured Claim Review file
---

# Workflow: Generate Technical Design Claim Review

Audit the given technical design document (or all TD docs) and output findings into a new `claim-review-XX.md` file.

**Target document:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. `.agents/skills/andm-td-reviewer/SKILL.md` — **your persona definition** (activate the full Phase 0-4 process defined there)
3. `.andm/prompt-templates/technical-design-master-prompt.md` — Technical Design quality benchmark (what the Technical Architect was supposed to deliver)
4. `docs/state/overview.md` — current status of all modules
5. Check `docs/technical-design/` — existing technical design documents to review
6. Check `docs/design-docs/` — System Design documents (architecture constraints to verify against)
7. Check `docs/adr/` — Architecture Decision Records
8. Check `docs/api-specs/` — existing high-level API contracts
9. Check `docs/ux/` — UX deliverables (for frontend design verification)
10. Check `.claude/rules/` — tech stack conventions (naming, patterns, project structure)
11. Check `docs/technical-design/claim-review-and-rebuttal/` — previous review rounds and rebuttals (to avoid duplicate findings)

Once read, you are ready to proceed.

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Use Glob to list all files in `docs/technical-design/claim-review-and-rebuttal/`. Find the highest existing `claim-review-XX.md` number. New round = highest + 1. If none exist, start at 01.

### 1.2 Load Context (MANDATORY — All reads in parallel)

Execute these reads simultaneously:

1. **TD quality benchmark** — Read `.andm/prompt-templates/technical-design-master-prompt.md` to understand the expected quality bar and deliverable format.
2. **Target document(s)** — Read the file specified above thoroughly. If `{{input}}` is "all", read the 3 TD docs (`docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md`). **SD-as-Master: TD-01/05/06/07/08 have been dropped** — API contracts → `docs/api-specs/*.yaml` (SD owns), design patterns → ADRs + TD-02 appendix, sequence diagrams → TD-02/03 inline, test strategy → `docs/qa/01-test-execution-plan.md` (QA owns), handoff → Impl Planner reads SD-07/08 directly.
3. **Related TD docs** — Identify documents referenced by or dependent on the target:
   - If target is `02-backend-design.md` → also read `03-frontend-design.md` (consumer), `04-database-design.md` (DB calls), `docs/api-specs/*.yaml` (contracts), ADRs referenced
   - If target is `03-frontend-design.md` → also read `02-backend-design.md` (API calls), `docs/api-specs/*.yaml` (contracts), `docs/ux/01-05` (design inputs)
   - If target is `04-database-design.md` → also read `02-backend-design.md` (data access), `docs/api-specs/*.yaml` (response shapes)
   - Use Grep to find cross-references (`see 0X-`, `ref:`, `described in`) within the target to discover additional deps.
4. **SD documents** — Read `docs/design-docs/02-08` (v1.2: gaps ที่ 01, 06 — merged into 02) for full architecture context, focusing on `02-high-level-architecture.md` (Top: Requirements Traceability for requirement coverage; Body: service boundaries; Bottom: ADR Digest), `03-deep-dive.md` (component details), `04-data-flow.md` (flow accuracy), `08-product-breakdown.md` (task alignment).
5. **ADRs and API specs** — Read all files in `docs/adr/` and `docs/api-specs/` for consistency checking.
6. **UX deliverables** — Read `docs/ux/03-page-layouts.md` and `docs/ux/02-component-inventory.md` for frontend design verification.
7. **BA deliverables** — Read `docs/ba/02-functional-requirements.md` and `docs/ba/03-non-functional-requirements.md` for traceability verification (entity model derives from functional reqs + business rules).
8. **Tech stack rules** — Read `.claude/rules/api.md`, `.claude/rules/web.md`, `.claude/rules/worker.md` for naming convention and pattern compliance.
9. **Latest claim-review rounds** — Read the latest 2-3 `claim-review-XX.md` AND their corresponding `rebuttal-round-XX.md` to understand:
   - What was already found and fixed (avoid duplicates)
   - Patterns of recurring weaknesses

> **Anti-Duplication Rule:** If an issue was raised in a previous round AND has a fix in the rebuttal, do NOT raise it again unless the fix is demonstrably incomplete.

### 1.3 Engage Persona

Follow the andm-td-reviewer persona defined in `.agents/skills/andm-td-reviewer/SKILL.md`. Activate the full Phase 0-4 process defined there.

---

## Phase 2: Generate Claims

### 2.1 Systematic Scan — Technical Design Attack Vector Checklist

Walk through the **20 technical design review categories** (defined in SKILL.md Phase 1) against the target document. For each category, either raise a finding OR explicitly note it was checked and why it doesn't apply.

| # | Category | What to Check |
|---|----------|--------------|
| 1 | **API Contract Completeness** | ทุก endpoint มี detailed contract ไหม? field-level types/validation ครบไหม? error schemas ครบไหม? |
| 2 | **API Contract Consistency** | naming conventions consistent ไหม? auth per endpoint ไหม? pagination/sorting uniform ไหม? |
| 3 | **Backend Module Boundaries** | responsibilities แยกชัดไหม? ไม่มี God classes? dependency flow ถูกต้องไหม? |
| 4 | **Backend Interface Contracts** | service interfaces มี method signatures ไหม? DTOs ครบไหม? exception types documented ไหม? |
| 5 | **CQRS/Command-Query Separation** | (ถ้า SD เลือก CQRS) commands/queries แยกถูกต้องไหม? handlers มี clear side effects ไหม? |
| 6 | **Frontend Component Hierarchy** | component tree match UX layouts ไหม? props/interfaces defined ไหม? reuse maximized ไหม? |
| 7 | **Frontend State Management** | state ownership ชัดเจนไหม? mutation patterns defined ไหม? cache invalidation มีไหม? |
| 8 | **Frontend-Backend Contract Alignment** | data fetching match API contracts ไหม? types synced ไหม? error handling ครบไหม? |
| 9 | **Database Schema Completeness** | ทุก entity มี table ไหม? column types/nullability ครบไหม? constraints defined ไหม? |
| 10 | **Database Index Strategy** | indexes match query patterns ไหม? composite index order ถูกต้องไหม? |
| 11 | **Database Migration Safety** | migration order defined ไหม? backward-compatible ไหม? rollback strategy มีไหม? |
| 12 | **Design Pattern Justification** | ทุก pattern มี "why" เจาะจงไหม? alternatives considered ไหม? correct layer ไหม? |
| 13 | **Sequence Diagram Coverage** | ทุก user flow มี diagram ไหม? error paths แสดงไหม? timing annotations มีไหม? |
| 14 | **Sequence Diagram Accuracy** | method names match interfaces ไหม? service names match SD ไหม? DB ops match schema ไหม? |
| 15 | **Test Strategy Adequacy** | coverage targets realistic ไหม? test type split justified ไหม? mock strategy appropriate ไหม? |
| 16 | **Test Case Traceability** | ทุก requirement มี test scenario ไหม? ทุก endpoint มี contract test ไหม? |
| 17 | **Cross-Domain Consistency** | API fields match DB columns ไหม? frontend props match API response ไหม? test data match seed ไหม? |
| 18 | **Security at Detail Level** | input validation per field ไหม? injection prevention ไหม? CSRF handling ไหม? |
| 19 | **Error Handling Strategy** | error codes consistent ข้าม layers ไหม? error boundaries ครบไหม? retry/fallback defined ไหม? |
| 20 | **Implementation Readiness** | ไม่มี "TBD" ไหม? dependencies ชัดเจนไหม? impl-plan derivable ไหม? |

**No artificial caps on findings.** Generate as many valid findings as the document warrants.

### 2.2 Cross-Domain Consistency

Use Grep across all `docs/technical-design/*.md` + `docs/design-docs/*.md` + `docs/adr/*.md` + `docs/api-specs/*.md` + `docs/ux/*.md` to verify consistency:

| Check | How |
|-------|-----|
| API field → DB column names | Grep for field names from API contracts across DB schema |
| API field → Frontend props | Grep for response fields across frontend component design |
| DB table → Data dictionary | Grep for table names across BA data dictionary |
| Interface methods → Sequence diagrams | Grep for method names across sequence diagrams |
| Component names → UX pages | Grep for component names across UX page layouts |
| Pattern usage → Pattern catalog | Grep for pattern names across backend/frontend design |
| SD architecture compliance | Compare module structure with SD `02-high-level-architecture.md` |
| Tech stack conventions | Compare naming/patterns with `.claude/rules/` |

Raise contradictions as separate claims.

### 2.3 Draft Claims

Write claims in **Thai**, using the adversarial tone from the andm-td-reviewer persona.

Use the **structured format from SKILL.md Phase 3**:

```
### Claim XX.N: [SEVERITY_ICON] [SEVERITY] — Title

**Location:**
- File: `[filename]`, Section: [section name]

**Problem:**
[2-4 sentences with specific citations from the technical design document]

**Why This Matters:**
[Real-world impact: "เมื่อ implement จะเกิด X เพราะ Y" or "Engineer จะต้อง guess เพราะ Z ไม่ถูก define"]

**Minimum Acceptable Fix:**
[Specific, actionable fix — not vague "add more detail"]

**Level of Effort:** [Low / Medium / High]
```

Classify severity strictly per the **Severity Classification Matrix** (SKILL.md Phase 2):
- **CRITICAL** — missing interface for cross-service call, DB schema contradicts API contract, no test for payment flow, fundamental design inconsistency
- **HIGH** — incomplete DTOs, missing error codes, index strategy mismatches query patterns, frontend-backend misalignment
- **MEDIUM** — pattern in wrong layer, missing sequence diagram for non-critical flow, unrealistic coverage target
- **LOW** — naming convention inconsistency, missing code skeleton, documentation gap

### 2.4 Quality Gate (Self-Review Before Output)

Before writing the file, verify every item:

- [ ] Every claim cites a specific location (file + section + quoted text)
- [ ] No claim repeats an already-fixed issue from previous rebuttals
- [ ] Severity matches the criteria matrix (not guessed)
- [ ] Every claim has a specific, actionable "Minimum Acceptable Fix"
- [ ] Summary table is prepared
- [ ] Technical Design Attack Vector Checklist was fully scanned (skipped categories noted with reason)
- [ ] Total findings >= 3 (if fewer, re-examine — you probably missed something)
- [ ] Findings are written in Thai with English technical terms
- [ ] Cross-domain consistency verified (API ↔ DB ↔ Frontend ↔ Test ↔ SD)

> If any check fails, revise the claims before proceeding.

---

## Phase 3: Output

### 3.1 Create the File

Use Write to create `docs/technical-design/claim-review-and-rebuttal/claim-review-XX.md` with this structure:

```markdown
# Technical Design Claim Review Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target Document** | `[filename or "all"]` |
| **Date** | YYYY-MM-DD |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Contract Completeness | ✅ Pass / ⚠️ Finding | [brief note] |
| 2 | API Contract Consistency | ✅ Pass / ⚠️ Finding | [brief note] |
[... all 20 categories ...]

---

## Findings

[All claims ordered by severity: CRITICAL → HIGH → MEDIUM → LOW]

---

## Cross-Domain Issues

[Contradictions found during Phase 2.2 — API↔DB, Frontend↔API, Test↔Requirement mismatches]

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
```

### 3.2 Report to User

Present a concise summary in Thai:
- Round number and target document
- Count of findings per severity level
- File path to the generated claim review
- Top 2-3 most critical findings highlighted
- Cross-domain issues flagged
- Recommendation: ready for rebuttal or needs immediate attention
