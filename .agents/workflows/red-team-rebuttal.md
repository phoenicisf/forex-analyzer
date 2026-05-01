---
description: Analyze Red Team findings, fix vulnerabilities, and write a defense report
---

# Workflow: Red Team Defense & Rebuttal

Process the given Red Team security report — analyze findings, fix vulnerabilities in code, update security documentation, and write a defense report.

**Red Team report:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, security rules
2. `.agents/skills/andm-red-team-defender/SKILL.md` — **your persona definition** (activate the full persona rules and 7-step fix protocol defined there)
3. `.claude/rules/security.md` — mandatory security rules
4. `docs/design-docs/05-security.md` — intended security design
5. `docs/state/overview.md` — current module status
6. Read relevant `.claude/rules/*.md` for affected services (api.md, web.md, worker.md)
7. Check `docs/security/` — all previous red-team rounds and defense reports

Once read, you are ready to proceed.

---

## Phase 1: Analysis

### 1.1 Load Context (parallel reads)

Execute simultaneously:

1. **The red-team report** — Read thoroughly, note every finding.
2. **Vulnerable code** — Use Grep to find which files are cited in the findings. Read all of them.
3. **Security rules** — Read `.claude/rules/security.md` to check if existing rules should have prevented these findings.
4. **Previous defense** — If exists, read the most recent `defense-round-XX.md` to understand fix history.

### 1.2 Engage Persona

Follow the andm-red-team-defender persona defined in `.agents/skills/andm-red-team-defender/SKILL.md`. Activate the full persona rules and 7-step fix protocol.

### 1.3 Analyze Each Finding

For each finding, determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | Why this verdict — cite specific code evidence |
| **Impact Scope** | Which files need modification |
| **Cross-Service Risk** | Does the same vulnerability pattern exist in other services? |
| **Proposed Fix** | Exact technical change |
| **Test Plan** | What regression test to add |

### 1.4 Pattern Detection

Use Grep to check if accepted vulnerability patterns exist elsewhere:
- If SQL injection found in one query → search all services for similar query patterns
- If missing auth on one endpoint → check all endpoints in the same controller/module
- If hardcoded secret found → search entire codebase for similar patterns

### 1.5 Present Analysis to User

Present a summary table in Thai:

```
| # | Severity | Title | Verdict | Files to Fix | Pattern Scope |
|---|----------|-------|---------|--------------|---------------|
```

Include:
- Your verdict and 1-sentence rationale per finding
- List of files that need changes
- Any patterns that require bulk fixes across services
- Whether `.claude/rules/security.md` needs updating

**⏸️ HALT — Wait for user approval before proceeding to execution.**

---

## Phase 2: Execution

Upon user approval:

### 2.1 Fix Vulnerabilities One at a Time

For each accepted or partial finding, follow the **7-Step Vulnerability Fix Protocol** from SKILL.md:

```
Step 1: Announce — State which finding you're fixing

Step 2: Fresh Read — Read the vulnerable file (may have changed)

Step 3: Cross-Check — Grep for same vulnerability pattern across ALL services

Step 4: Apply Fix — Defense-in-depth approach:
  - Input validation (reject bad input)
  - Sanitization (clean input)
  - Safe API usage (parameterized queries, etc.)

Step 5: Add Test — Regression test that:
  - Attempts the exploit from the PoC
  - Verifies fix prevents it
  - Tests edge cases

Step 6: Cascade Fix — Fix all instances found in Step 3
  - Document every additional location fixed

Step 7: Mark Complete
```

> **Safety Rule:** If a fix would change business logic or break functionality, STOP and report to the user.

> **Pattern Rule:** If 3+ findings share the same root cause, add a rule to `.claude/rules/security.md`.

### 2.2 Handle Rejected Findings

For each rejected finding, prepare a technical justification:
- Cite the specific security control that already addresses the concern
- Show the code that implements the protection
- If the attacker missed context, point to where it exists

---

## Phase 3: Update Security Documentation

### 3.1 Update Security Rules

If new patterns were identified, add rules to `.claude/rules/security.md`:
- What the vulnerability was
- What the rule prevents
- Example of correct vs incorrect code

### 3.2 Update Security Design Doc

Update `docs/design-docs/05-security.md` with:
- New mitigations added during this defense round
- Updated threat model if new attack vectors were identified
- STRIDE analysis updates (if applicable)

---

## Phase 4: Write Defense Report

### 4.1 Create the File

Use Write to create `docs/security/defense-round-XX.md`:

```markdown
# Red Team Defense — Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Red Team Report** | `red-team-round-XX.md` |
| **Date** | YYYY-MM-DD |

## Summary

| Verdict | Count |
|---------|-------|
| Accepted | N |
| Partial | N |
| Rejected | N |

## Security Rules Updated
- [ ] `.claude/rules/security.md` — [description of new rules added]
- [ ] `docs/design-docs/05-security.md` — [description of updates]

---

## Finding Responses

### Finding RT-XX.1: [Title]
**Verdict:** Accept
**Changes Made:**
- File: `[filepath]`, Line: [lines]
- What changed: [description in Thai]
- Security control: [validation/sanitization/parameterization/etc.]
- Test added: `[test file path]`
- Cascade fixes: [additional locations, if any]

### Finding RT-XX.2: [Title]
**Verdict:** Reject
**Justification:** [reasoning with code evidence in Thai]

### Finding RT-XX.3: [Title]
**Verdict:** Partial
**Accepted Part:** [what was fixed]
**Rejected Part:** [what was already secure, with evidence]
**Changes Made:** [details]

---

## Cascaded Fixes
[Fixes applied to code NOT directly cited in findings, due to pattern detection]

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | N% | [Thai interpretation] |
| Critical Fixes | N | [Thai interpretation] |
| Patterns Fixed | N across N files | [Thai description] |
| New Security Rules | N | [Thai description] |
| Remaining Gaps | N items | [Thai description] |

## Recommendation
- [ ] **Ready for Production** — all Critical/High findings resolved, security rules updated
- [ ] **Request Re-Audit** — significant code changes made, attacker should verify
- [ ] **Needs Hotfix** — Critical finding requires immediate deployment
```

---

## Phase 5: Final Verification

### 5.1 Run Tests

Run all test suites for affected services to verify fixes don't break existing functionality.

### 5.2 Security Rule Compliance

Grep for patterns that should be caught by the new security rules — verify no remaining violations exist.

---

## Phase 6: Report

Present a concise summary in Thai:

- Number of findings processed: N accepted / N rejected / N partial
- Files modified (with change count per file)
- Tests added (count)
- Security rules updated (Y/N + description)
- Security design doc updated (Y/N)
- Path to the new `defense-round-XX.md`
- Highlight any patterns that required cascade fixes across services
- Recommendation: ready for production or needs another audit cycle
