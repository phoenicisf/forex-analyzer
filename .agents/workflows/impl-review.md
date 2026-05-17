---
description: Review implementation code for quality, security, and design compliance
---

# Workflow: Generate Code Review

Review the given service code (or all services) and output findings into a new `review-round-XX.md` file.

**Target:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, architecture constraints, document references
2. `.agents/skills/andm-code-reviewer/SKILL.md` — **your persona definition** (activate the full Phase 0-4 process defined there)
3. `docs/state/overview.md` — current status of all modules
4. `docs/state/impl-plan.md` — current sprint plan (what was implemented)
5. Check `docs/code-review/` — previous review rounds (to avoid duplicate findings)

Once read, you are ready to proceed.

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Use Glob to list all files in `docs/code-review/`. Find the highest existing `review-round-XX.md` number. New round = highest + 1. If none exist, start at 01.

### 1.2 Load Context (MANDATORY — All reads in parallel)

Execute these reads simultaneously:

1. **Per-service rules** — Based on target:
   - API: `.claude/rules/api.md`
   - Web: `.claude/rules/web.md`
   - Worker: `.claude/rules/worker.md`
   - If "all": read all three
2. **Security rules** — `.claude/rules/security.md`
3. **Testing rules** — `.claude/rules/testing.md`
4. **Design documents** — Read relevant docs:
   - `docs/design-docs/02-high-level-architecture.md` (architecture compliance)
   - `docs/design-docs/04-data-flow.md` (data flow compliance)
   - `docs/design-docs/05-security.md` (security compliance)
5. **ADRs** — Read all `docs/adr/*.md` to verify decisions are followed
6. **API specs** — Read `docs/api-specs/*.yaml` to verify contract compliance
7. **Source code** — Systematically scan the target service(s):
   - Use Glob to find all source files in the target
   - Read key files: entry points, services, controllers/endpoints, data access, configuration
   - Use Grep to find patterns of interest (hardcoded strings, TODO/FIXME, error handling, SQL queries)
8. **Test code** — Scan test files to assess coverage:
   - Use Glob to find test files
   - Verify critical paths have corresponding tests
9. **Latest review rounds** — Read the latest 2-3 review rounds AND their corresponding fix rounds to understand:
   - What was already found and fixed (avoid duplicates)
   - Patterns of recurring issues

> **Anti-Duplication Rule:** If an issue was raised in a previous round AND has a fix in the fix-round, do NOT raise it again unless the fix is demonstrably incomplete.

### 1.3 Engage Persona

Follow the andm-code-reviewer persona defined in `.agents/skills/andm-code-reviewer/SKILL.md`. Activate the full Phase 0-4 process defined there.

---

## Phase 2: Generate Findings

### 2.1 Systematic Scan — Code Review Attack Vector Checklist

Walk through the **review dimensions** against the target code. For each dimension, either raise findings OR explicitly note it was checked and no issues were found.

| # | Dimension | What to Check |
|---|-----------|--------------|
| 1 | **Security (OWASP Top 10)** | Injection, AuthN/AuthZ, sensitive data exposure, CSRF, input validation |
| 2 | **Business Logic Correctness** | Requirements match, edge cases, error states, business rules |
| 3 | **Error Handling** | Exception levels, logging context, no silent swallowing, retry strategy |
| 4 | **Performance** | N+1 queries, unbounded collections, async/await, unnecessary allocations |
| 5 | **Over-Engineering** | Unnecessary abstractions, premature generalization, dead code |
| 6 | **Cross-Service Consistency** | API contract match, schema alignment, entity naming, error codes |
| 7 | **Test Coverage Gaps** | Critical paths tested, edge cases, integration tests, untested branches |
| 8 | **Architecture Compliance** | Implementation matches `docs/design-docs/02-high-level-architecture.md`? ADR decisions followed? Data flow matches `04-data-flow.md`? Security measures match `05-security.md`? |
| 9 | **Technical Design Compliance** | API impl matches `docs/api-specs/*.yaml` (field types, validation, error codes)? Backend matches `02-backend-design.md` (interfaces, DTOs)? Frontend matches `03-frontend-design.md` (components, state)? DB matches `04-database-design.md` (columns, constraints, indexes)? |
| 10 | **Test Code Quality & Defensive Patterns** | Regex catastrophic backtracking risk (nested quantifiers, ambiguous greedy `.*` กับ multi-line input, alternation overlap)? Regex calls มี timeout (C# `TimeSpan`, Node `re2`/`safe-regex2`, Python `regex.TIMEOUT`)? Loops ใน tests มี explicit upper bound (ไม่มี `while(true)`)? Test fixtures มี cleanup (Dispose/teardown — ไม่มี process / file / connection leak)? ไม่มี shared mutable state ระหว่าง cases? Per-test runtime คาดเดาได้ (ไม่มี "depends on data size" ที่ unbounded)? |
| 11 | **Empirical AC Closure Verification** | Task with E-AC: handoff มี evidence artifact ที่ระบุใน `docs/state/_session-handoff/<task-id>-evidence-*` หรือไม่? Artifact reproducible? Probe/capture/inspect output ตรงกับ AC text? AC checkbox `[x]` พร้อม "deferred to operator-runtime" / "deferred to post-launch operator phase" / "deferred per <task> precedent" → CRITICAL finding (closure-rule violation per `andm-impl-engineer/SKILL.md § Forbidden Closure Patterns`). E-AC ระบุ `[evidence-kind]` แต่ artifact เป็น in-process test log → HIGH finding (kind mismatch — empirical kinds require live-system observation, not test runner output) |
| 12 | **IMPL-FIX Sibling Ban** | Grep `docs/state/impl-plan.md` + `docs/code-review/` + `docs/state/_session-handoff/` filenames for pattern `IMPL-FIX-\d+[a-z]` หรือ `IMPL-FIX-\d+-[A-Z]+`. Any match = CRITICAL finding (Cap-3 Decision Gate bypass via sibling naming). Required remediation: rename sibling tickets to fresh `IMPL-FIX-MMM` numbers, close original parent as `[scope-replaced → MMM, ...]`. Also check iteration trail per IMPL-FIX ticket: if ≥3 falsified iterations exist without a Cap-3 Decision Gate audit-trail entry (BACKTRACK / re-decompose / defer with operator sign-off) → HIGH finding (silent 4th iteration). Reference: `GLOSSARY.md § IMPL-FIX Sibling Ban` + `§ Cap-3 Decision Gate` |
| 13 | **Handoff Artifact Archive Hygiene** | Glob `docs/state/_session-handoff/<closed-ticket>*` for tickets closed `[x]` หรือ `[scope-replaced]` > 14 days ago + not referenced by `deferred-ac-registry.md` Active row. Any unarchived match = LOW finding (cleanup needed) if count <10, MEDIUM if 10-30, HIGH if >30 (per-ticket sprawl risk). Verify archive directory `docs/state/_session-handoff/archive/<ticket>.tar.gz` exists for archived tickets + handoff.md pointers updated if referenced. Reference: `GLOSSARY.md § Handoff Artifact Archive Policy` |

**No artificial caps on findings.** Generate as many valid findings as the code warrants.

### 2.2 Cross-Service Verification

Use Grep across services to verify consistency:

| Check | How |
|-------|-----|
| API contract compliance | Compare endpoint signatures in code vs `docs/api-specs/*.yaml` |
| Entity naming | Grep for entity names across services — verify consistent naming |
| Error code consistency | Grep for error codes/status codes — verify consistent usage |
| Configuration alignment | Check env vars and config match across services |

Raise contradictions as separate findings.

### 2.2.5 Defect Class Recurrence Check (METHODOLOGY-REDESIGN Trigger)

> **Glossary:** `GLOSSARY.md § METHODOLOGY-REDESIGN Ticket`. Stops the "fix the rule to fix the fix that fixed the rule" meta-loop before clause-explosion.

Before drafting findings, scan recent review-round history (last 3 rounds — `docs/code-review/review-round-{N-2..N-1}.md` + this round in-progress):

1. **Identify clause patches** — findings in prior rounds that result in a Gate / checklist clause being added or strengthened (e.g., "Gate #9 clause (h) added", "Dimension #N strengthened with exemption regex")
2. **Detect repetition** — same Gate / clause receiving clause additions across **3 consecutive rounds** (N-2, N-1, N) for the same defect class (same root cause, same surface, same evasion pattern)
3. **HALT trigger:** if recurrence detected →

   ```
   🛑 DEFECT CLASS RECURRENCE — METHODOLOGY-REDESIGN REQUIRED

   Gate / Clause: <name + ID, e.g., "Gate #9 clause">
   Defect class: <one-line description>
   Rounds affected: R<N-2>, R<N-1>, R<N (current)>
   Clause growth: <e.g., "clause (g) → (h) → (i)">

   The mechanism (grep / regex / checklist) is being patched repeatedly to catch defects
   it structurally cannot reliably detect. Adding clause (j) is FORBIDDEN until redesign closes.

   Required action: spawn `docs/code-review/methodology-redesign/METHODOLOGY-REDESIGN-NNN.md`:
     (1) Name the defect class + 3-round evidence trail (link rounds)
     (2) Question whether current mechanism can ever reliably catch the class
     (3) Propose alternative — AST analysis / structural tool / dedicated workflow step / scope removal
     (4) Owner + close date + methodology-owner sign-off

   This review round closes WITHOUT adding a new clause to <Gate name>.
   Other unrelated findings proceed as normal.
   ```

4. If trigger fires → reviewer SKIPs the affected clause-patch finding for this round; documents the deferral in `## Methodology Findings` section instead (defer-with-reason format)
5. If no trigger → proceed to 2.3

> **Defect class motivating:** PhoenicisNex Gate #9 explosion 2026-05 — 7 review rounds × 5 axes × 9 clauses ≈ 3,000 words of regex specification; 5th axis ("reviewer-authoring contract") still open at R26 with no halt mechanism. Sample retro: `real-problems/methodology-retrospective-day17.md § 4.1`

### 2.3 E-AC Evidence Cross-Check (Mandatory if any task in scope has E-AC)

For every task in the review scope where `impl-plan.md` declared one or more **Empirical ACs**:

1. **Locate evidence artifact:** open `docs/state/_session-handoff/<task-id>-evidence-*` referenced by the AC checkbox
2. **Verify it exists** — missing artifact while AC `[x]` → **CRITICAL** finding "E-AC closed without evidence artifact"
3. **Verify kind match** — artifact must match the `[evidence-kind]` declared in AC:
   - `[probe]` → external request log (command + headers + body + status); rejected if it's a Vitest/xUnit/pytest test log
   - `[gui-capture]` → image/DOM dump from rendered surface; rejected if it's a snapshot test artifact
   - `[log-assertion]` → process log excerpt with correlation-id; rejected if it's a mocked logger spy
   - `[queue-inspect]` / `[db-inspect]` / `[file-blob-check]` → introspection output from the actual broker/store; rejected if it's an in-memory mock
   - `[boot-cold]` → bootstrap command + smoke chain output from a freshly-torn-down environment
   - `[contract-roundtrip]` → response captured + validated against committed spec file
4. **Verify artifact text matches AC text** — partial match or mismatch → **HIGH** finding "E-AC evidence does not satisfy AC scope"
5. **Reject deferred-to-operator-runtime closure notes** — any AC `[x]` whose closure note contains "deferred to operator-runtime", "deferred to post-launch operator phase", or "deferred per <other-task> precedent" → **CRITICAL** finding (Dimension #11 violation; closure rule per `andm-impl-engineer/SKILL.md § Forbidden Closure Patterns`)

> **Why this dimension is mandatory:** real-project audit (Shark CMS, 2026-04) found 71% of E-ACs marked `[x]` were unverified at runtime — code review accepted closure based on structural test pass alone. Closure-rule enforcement at code-review time is the cheapest gate to catch this drift before phase advance

### 2.4 Draft Findings

Write findings in **Thai**, using the adversarial reviewer tone.

Use this structured format:

```
### Finding XX.N: [SEVERITY_ICON] [SEVERITY] — Title

**Location:**
- File: `[file path]`, Line: [line number or range]
- Service: [api / web / worker]

**Code:**
```[language]
[exact code snippet — 3-10 lines]
```

**Problem:**
[2-4 sentences with specific citations from the code — reference rules, design docs, or patterns being violated]

**Why This Matters:**
[Real-world impact]

**Suggested Fix:**
```[language]
[concrete code fix]
```

**Level of Effort:** [Low / Medium / High]
```

Classify severity strictly:
- **CRITICAL** 🔴 — data loss, security breach, broken core business logic
- **HIGH** 🟠 — significant quality issue, performance degradation under load
- **MEDIUM** 🟡 — code smell, partial issue, workaround exists
- **LOW** 🔵 — best practice violation, minor improvement

### 2.4 Quality Gate (Self-Review Before Output)

Before writing the file, verify every item:

- [ ] Every finding cites specific file path and line number
- [ ] Every finding includes the actual problematic code snippet
- [ ] No finding repeats an already-fixed issue from previous rounds
- [ ] Severity matches the classification matrix
- [ ] Every finding has a concrete suggested fix (code, not prose)
- [ ] Code Review Attack Vector Checklist was fully scanned
- [ ] Total findings >= 3
- [ ] Findings are in Thai with English technical terms

---

## Phase 3: Output

### 3.1 Create the File

Create `docs/code-review/review-round-XX.md` with this structure:

```markdown
# Code Review Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target** | `[service path or "all"]` |
| **Date** | YYYY-MM-DD |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP) | ✅ Pass / ⚠️ Finding | [brief note] |
| 2 | Business Logic | ✅ Pass / ⚠️ Finding | [brief note] |
| 3 | Error Handling | ✅ Pass / ⚠️ Finding | [brief note] |
| 4 | Performance | ✅ Pass / ⚠️ Finding | [brief note] |
| 5 | Over-Engineering | ✅ Pass / ⚠️ Finding | [brief note] |
| 6 | Cross-Service Consistency | ✅ Pass / ⚠️ Finding | [brief note] |
| 7 | Test Coverage Gaps | ✅ Pass / ⚠️ Finding | [brief note] |
| 8 | Design Doc Compliance | ✅ Pass / ⚠️ Finding | [brief note] |
| 9 | Test Code Quality | ✅ Pass / ⚠️ Finding | [brief note] |

---

## Findings

[All findings ordered by severity: CRITICAL → HIGH → MEDIUM → LOW]

---

## Cross-Service Issues

[Contract mismatches, naming inconsistencies found during Phase 2.2]

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
```

### 3.2 Report to User

Present a concise summary in Thai:
- Round number and target
- Count of findings per severity level
- File path to the generated review
- Top 2-3 most critical findings highlighted
- Recommendation: ready for fix round or needs immediate attention
