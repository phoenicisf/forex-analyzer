---
description: Analyze, implement fixes, and write rebuttal for a Technical Design Claim Review round
---

# Workflow: Process Technical Design Claim Review

Process the given Technical Design Claim Review document — from analysis through implementation to rebuttal. Follow the TD defense persona for intellectual honesty when implementing fixes.

**Claim review file:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. `.agents/skills/andm-td-defender/SKILL.md` — **your persona definition** (activate the full persona rules and execution protocol defined there)
3. `.andm/prompt-templates/technical-design-master-prompt.md` — Technical Design quality benchmark (what the Technical Architect was supposed to deliver)
4. `docs/state/overview.md` — current status of all modules
5. Check `docs/technical-design/` — existing technical design documents (your work being reviewed)
6. Check `docs/design-docs/` — System Design documents (architecture constraints you must respect)
7. Check `docs/adr/` — Architecture Decision Records
8. Check `docs/api-specs/` — API contracts
9. Check `docs/ux/` — UX deliverables (for frontend verification)
10. Check `.claude/rules/` — tech stack conventions
11. Check `docs/technical-design/claim-review-and-rebuttal/` — all previous review rounds and rebuttals (to understand fix history)

Once read, you are ready to proceed.

---

## Phase 1: Analysis

### 1.1 Load Context (parallel reads)

Execute simultaneously:

1. **The claim review file** — Read thoroughly, note every claim.
2. **Referenced TD docs** — Use Grep to find which `docs/technical-design/0X-*.md` files are cited in the claims. Read all of them.
3. **SD documents** — Read `docs/design-docs/02-high-level-architecture.md`, `docs/design-docs/03-deep-dive.md` for architecture constraint verification.
4. **ADRs and API specs** — Read all files in `docs/adr/` and `docs/api-specs/` that are referenced or related.
5. **UX deliverables** — Read relevant `docs/ux/` files if claims reference frontend design.
6. **BA deliverables** — Read `docs/ba/02-functional-requirements.md`, `docs/ba/03-non-functional-requirements.md`, `docs/ba/04-business-rules.md` for traceability verification (entity model derives from functional reqs + business rules).
7. **Tech stack rules** — Read `.claude/rules/` files relevant to cited claims.
8. **Previous rebuttal** — If exists, read the most recent `rebuttal-round-XX.md` to understand fix history.

### 1.2 Engage Persona

Follow the andm-td-defender persona defined in `.agents/skills/andm-td-defender/SKILL.md`. Activate the full persona rules and 7-step execution protocol defined there.

### 1.3 Analyze Each Claim

For each claim, determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | Why this verdict — cite specific evidence from the TD doc |
| **Impact Scope** | Which TD docs (`01`-`08`), SD docs, ADRs, or API specs need modification |
| **Cross-Domain Risk** | Will fixing this claim create inconsistency in API↔DB, Frontend↔API, Test↔Requirement? |
| **SD Boundary Check** | Does this fix require changing SD architecture decisions? If yes → recommend `/backtrack sd` |
| **Proposed Fix** | Exact technical change — not vague "will improve" |

### 1.4 Risk Assessment

For each accepted/partial claim, check cross-domain impact using Grep:
- Search for the field/class/component/table being modified across ALL TD docs + SD docs + ADRs + API specs
- Identify every location that references the same concept
- Flag any fix that would create a new inconsistency
- **SD Boundary Rule:** If a fix would require changing SD architecture decisions or ADRs, STOP and recommend `/backtrack sd` instead

### 1.5 Present Analysis to User

Present a summary table in Thai:

```
| # | Severity | Title | Verdict | Files to Modify | Cross-Domain Risk | SD Boundary |
|---|----------|-------|---------|-----------------|-------------------|-------------|
```

Include for each claim:
- Your verdict and 1-sentence rationale
- List of files that need changes
- Any cross-domain risks flagged
- Whether the fix stays within TD boundary or needs SD escalation

**HALT and wait for user approval before proceeding to execution.**

---

## Phase 2: Execution

Upon user approval:

### 2.1 Process Claims One at a Time

For each accepted or partial claim, follow this sequence strictly:

```
Step 1: Announce — State which claim you're fixing (e.g., "Fixing Claim 02.3: HIGH — Missing error codes in API contract for /users endpoint")

Step 2: Fresh Read — Read the target section in the TD doc (do NOT rely on earlier reads — the file may have changed from previous fixes)

Step 3: Cross-Doc Check — Grep for related terms in other TD docs, SD docs, ADRs, API specs, and .claude/rules/ to identify all locations that reference this concept

Step 4: Apply Fix — Use Edit to make the change. Keep changes minimal and focused.

Step 5: Verify — Re-read the modified section to confirm correctness

Step 6: Cascade Check — If the fix changes:
  - API field name → check DB schema (04), frontend components (03), test cases (07), sequence diagrams (06)
  - DB column → check API contracts (01), backend DTOs (02), test data (07)
  - Component name/props → check routing (03), data fetching hooks (03), test scenarios (07)
  - Interface method → check sequence diagrams (06), test mocks (07), design patterns (05)
  - Pattern choice → check all usages across TD docs
  - Grep old value across all TD docs
  - Update references in other TD docs
  - Document what cascaded

Step 7: Mark Complete — Note the claim as done
```

> **Safety Rule:** If a fix would contradict or break content in another TD doc, SD doc, or ADR, STOP and report to the user before proceeding. Do NOT silently create new inconsistencies.

> **SD Boundary Rule:** If a fix requires changing SD architecture decisions or ADRs, recommend `/backtrack sd` and skip the claim until SD is updated.

### 2.2 Handle Rejected Claims

For each rejected claim, prepare a thorough technical justification:
- Cite the specific TD doc section that addresses the concern
- Quote the exact text that the reviewer missed or misread
- Show cross-domain evidence (e.g., "API field X maps to DB column Y as documented in Section Z")
- Explain why the current design is correct/sufficient
- If the reviewer missed context, point to where it exists

---

## Phase 3: Write Rebuttal

### 3.1 Create Rebuttal File

Use Write to create `docs/technical-design/claim-review-and-rebuttal/rebuttal-round-XX.md`:

```markdown
# Technical Design Rebuttal Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Claim Review** | `claim-review-XX.md` |
| **Date** | YYYY-MM-DD |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |

## Summary

| Verdict | Count |
|---------|-------|
| Accepted | N |
| Partial | N |
| Rejected | N |

---

## Claim Responses

### Claim XX.1: [Title]
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: [section name]
- What changed: [specific description in Thai]
- Evidence: [quote the updated text]
- Cascaded to: [list other TD docs updated, if any]

### Claim XX.2: [Title]
**Verdict:** Reject
**Justification:** [technical reasoning with doc citations in Thai — quote exact text that addresses the concern]

### Claim XX.3: [Title]
**Verdict:** Partial
**Accepted Part:** [what was fixed in Thai]
**Rejected Part:** [what was already correct, with evidence in Thai]
**Changes Made:**
- File: `[filename]`, Section: [section name]
- What changed: [specific description]

---

## Cascaded Changes
[List any changes made to TD docs NOT directly cited in the claims, due to cross-domain consistency fixes]

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | N% | [Thai interpretation] |
| Critical Fixes | N | [Thai interpretation] |
| Cross-Domain Fixes | N | [Thai description — cascaded consistency fixes] |
| Net Improvement | [Thai assessment] | |
| Remaining Gaps | N items | [Thai description of what's left] |

## Recommendation
- [ ] **Ready for Implementation Handoff** — all Critical/High claims resolved, cross-domain consistency verified
- [ ] **Request Re-Review** — significant changes made, reviewer should verify
- [ ] **Needs SD Backtrack** — root cause in SD architecture, recommend `/backtrack sd`
- [ ] **Needs Stakeholder Input** — deferred items block further progress
```

---

## Phase 4: Final Consistency Sweep

### 4.1 Verification (parallel checks)

After all fixes are applied, run these checks simultaneously:

1. **API↔DB consistency** — Grep for API field names across DB schema, verify types/names match or mapping documented
2. **API↔Frontend consistency** — Grep for API response fields across frontend component props
3. **DB↔Data Dictionary** — Verify all tables trace back to BA data dictionary entities
4. **Interface↔Sequence Diagrams** — Verify method names in diagrams match interface definitions
5. **Requirement↔Test traceability** — Verify every functional requirement has at least one test scenario
6. **SD compliance** — Verify module structure still matches SD `02-high-level-architecture.md`
7. **Tech stack compliance** — Verify naming conventions match `.claude/rules/`
8. **Pattern consistency** — Verify pattern catalog matches actual usage across backend/frontend design

### 4.2 Fix Any Issues Found

If the sweep finds inconsistencies introduced by the fixes:
- Fix them immediately
- Add them to the "Cascaded Changes" section of the rebuttal

---

## Phase 5: Report

Present a concise summary in Thai:

- Number of claims processed: N accepted / N rejected / N partial
- List of files modified (with change count per file)
- Cross-domain fixes: API↔DB, Frontend↔API, Test↔Requirement fixes
- Path to the new `rebuttal-round-XX.md`
- Any cross-domain issues found and resolved during the consistency sweep
- Highlight any claims that required cascading changes across multiple TD docs
- SD boundary issues: any claims deferred due to SD architecture constraints
- Recommendation: ready for implementation handoff or needs another review cycle
