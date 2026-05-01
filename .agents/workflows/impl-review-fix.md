---
description: Analyze code review findings, implement fixes, and write fix report
---

# Workflow: Process Code Review Findings

Process the given Code Review document — from analysis through code fixes to fix report. Follow the andm-impl-engineer persona for production-grade code quality.

**Review file:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, architecture constraints, document references
2. `.agents/skills/andm-impl-engineer/SKILL.md` — **your persona definition** (activate production-grade implementation mindset)
3. `docs/state/overview.md` — current status of all modules
4. `.claude/rules/security.md` — security rules
5. `.claude/rules/testing.md` — testing rules
6. Per-service rules based on affected services:
   - API: `.claude/rules/api.md`
   - Web: `.claude/rules/web.md`
   - Worker: `.claude/rules/worker.md`
7. Check `docs/code-review/` — previous fix rounds (to understand fix history)

Once read, you are ready to proceed.

---

## Phase 1: Analysis

### 1.1 Load Context (parallel reads)

Execute simultaneously:

1. **The review file** — Read thoroughly, note every finding.
2. **Referenced source files** — Use Grep to find which files are cited in the findings. Read all of them.
3. **Previous fix rounds** — If exists, read the most recent `fix-round-XX.md` to understand fix history.

### 1.2 Analyze Each Finding

For each finding, determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | Why this verdict — cite specific code or evidence |
| **Scope** | Is this pattern present in other files? (use Grep to detect) |
| **Fix Plan** | What exactly will be changed and where |

### 1.3 Pattern Detection

For each accepted finding, use Grep to check if the same pattern exists in other files across the codebase. If found, note all affected files — fixes must be cascaded.

Example: If N+1 query found in `ArticleService`, grep for similar patterns in all other services.

---

## Phase 2: Present Verdicts — ⏸️ HALT

Present the verdict table to the user:

```markdown
## Verdict Summary

| # | Finding | Severity | Verdict | Scope | Fix Plan |
|---|---------|----------|---------|-------|----------|
| 1 | SQL injection in ArticleEndpoints | 🔴 CRITICAL | Accept | 3 files same pattern | Parameterize all queries |
| 2 | Missing pagination in GetAll | 🟠 HIGH | Accept | 2 endpoints | Add PagedResult<T> |
| 3 | Dead code in helpers | 🔵 LOW | Reject | N/A | Code is used in tests |

**Accepted:** X findings (Y cascaded across Z files)
**Rejected:** X findings (with evidence)
**Partial:** X findings
```

**⏸️ HALT — Wait for user approval before proceeding with fixes.**

---

## Phase 2.5: Parallel Execution (Claude Code only — optional)

> **Skip this section** ถ้าไม่ได้ใช้ Claude Code (Windsurf/Cursor/OpenCode/Gemini CLI ข้ามไป Phase 3).
> **Reference:** `.agents/workflows/_parallel-execution-playbook.md` § 2.2 Service-Oriented

### 2.5.1 Eligibility
- User approved verdicts affect ≥2 services → proceed
- All accepted fixes are in ONE service → skip (fan-out ไม่คุ้ม — ไป Phase 3 serial)

### 2.5.2 Write shared context
สร้าง `docs/state/_parallel-context/impl-review-fix-round-<NN>.md` (schema: playbook § 4.3) ด้วย:
- Round number, accepted findings per service (grouped by service), approved verdicts, entry criteria (tests must pass after each fix)

### 2.5.3 Fan out — up to 3 Task calls ใน ONE message

| # | subagent_type | SCOPE | Ownership boundary |
|---|---------------|-------|--------------------|
| 1 | `andm-impl-engineer` | `services/api/` | แก้ไขเฉพาะ `services/api/*`; ห้ามแตะ web/worker |
| 2 | `andm-impl-engineer` | `services/web/` | แก้ไขเฉพาะ `services/web/*`; ห้ามแตะ api/worker |
| 3 | `andm-impl-engineer` | `services/worker/` | แก้ไขเฉพาะ `services/worker/*`; ห้ามแตะ api/web |

Invocation per Task call (playbook § 3):
- `subagent_type: "andm-impl-engineer"`
- prompt: persona + shared-context path + SCOPE service + **ONLY accepted findings for this service** + follow SKILL.md 7-Step Fix Protocol + run service tests after each fix + return a `impl-review-fix-fragment` (same schema as § 5.2 but with `action: fixed|reject-justified|partial` added per finding) + **do NOT write the fix-round report file; orchestrator owns it**

**Race-prevention rules (STRICT):**
- Subagents write only inside their own `services/<name>/` tree.
- Orchestrator owns: root configs (`.env`, `docker-compose.yml`, `package.json` root, `.gitignore`), `.claude/rules/*`, shared types/schemas in `packages/*` if any.
- If a finding requires cross-service change (shared schema, shared rule update) → orchestrator applies it serially AFTER subagents return.

### 2.5.4 Merge & continue
- รอ fragments ทุกตัว → collect per-service commit diffs + test results
- ถ้า subagent fail mid-fix → orchestrator rolls back that service's changes and replays serially in Phase 3 for that service only
- ทำต่อ Phase 4 Output — orchestrator เขียน `docs/code-review/fix-round-<NN>.md` ครั้งเดียว
- Footer: `Parallel fix coverage: <successful>/<needed> services; fallback: <list>`

---

## Phase 3: Execute Fixes (after approval)

### 3.1 Fix Order

Apply fixes in this order:
1. **CRITICAL** findings first
2. **HIGH** findings
3. **MEDIUM** findings
4. **LOW** findings

For each fix:
1. Fix the primary file cited in the finding
2. Fix all cascaded files (same pattern in other locations)
3. Add/update tests to cover the fix
4. Verify existing tests still pass

### 3.2 Commit Strategy

Create micro-commits per finding (or per finding group if closely related):

```
[fix:service] short description

Why: Code review round XX finding XX.N — [brief explanation of the issue]
```

### 3.3 Update Security Rules (if applicable)

If any security-related fix introduces a new pattern or rule:
- Update `.claude/rules/security.md` with the new rule
- Update `docs/design-docs/05-security.md` if defense strategy changed

---

## Phase 4: Output

### 4.1 Create Fix Report

Create `docs/code-review/fix-round-XX.md` with this structure:

```markdown
# Code Review Fix Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Review File** | `docs/code-review/review-round-XX.md` |
| **Date** | YYYY-MM-DD |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 1 | [title] | 🔴 CRITICAL | Accept | 3 files | abc1234 |
| 2 | [title] | 🟠 HIGH | Reject | N/A | — |

## Accepted Findings — Fixes Applied

### Fix for Finding XX.1: [Title]

**Verdict:** Accept
**Scope:** [N files with same pattern]
**Changes:**
- `path/to/file.cs` — [what was changed]
- `path/to/other.cs` — [cascaded fix]
- `tests/path/to/test.cs` — [test added/updated]
**Commit:** `[hash] [fix:api] description`

[repeat for each accepted finding]

## Rejected Findings — Evidence

### Rejection of Finding XX.2: [Title]

**Verdict:** Reject
**Evidence:** [specific code or reasoning showing why the finding is invalid]

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | N |
| Accepted | N |
| Rejected | N |
| Partial | N |
| Files Modified | N |
| Tests Added/Updated | N |
| Commits | N |
```

### 4.2 State Reconciliation (3-File Propagation — MANDATORY)

> **Why this discipline:** code review fixes ไม่ใช่ task closure แต่ก็เปลี่ยน file state + อาจ resolve forbidden closure patterns (Dimension #11 CRITICALs) ที่ block phase advance. State drift ทำให้ `/next` Check 5.5 hit divergence + downstream status agents รายงานผิด. ดู CLAUDE.md § Glossary § State Reconciliation Discipline

หลัง commit fixes, propagate state ไปทั้ง 3 ชั้น:

#### Layer 1 — `docs/state/impl-plan.md` (PRIMARY SoT)

- ถ้า fix แก้ forbidden closure pattern (Dimension #11 CRITICAL) → re-tick `[x]` AC ด้วย proper evidence artifact path; remove old "deferred to operator-runtime" note
- ถ้า fix touches task ที่อยู่ใน Mid-Phase Audit replay scope → note ใน Mid-Phase Audit Log row
- ถ้า fix resolves Deferred-AC Active row → move to Resolved table in `docs/state/deferred-ac-registry.md`
- ถ้า fix re-opens previously-closed task (regression discovered) → flip task `[x]` → `[ ]` + add note explaining

#### Layer 2 — `docs/state/overview.md` (DERIVED VIEW)

- ถ้า code-review fixes resolved CRITICAL/HIGH that blocked Phase Gate → update phase status accordingly
- Update "last code-review round" pointer with round number + date

#### Layer 3 — `docs/state/{service}/handoff.md`

Update with:
- Code review round + fix round (e.g., "review-round-03 → fix-round-03")
- Findings resolved (count + brief list)
- Cascaded fixes (file count)
- Any new rules added to `.claude/rules/security.md`
- Status of the service after fixes
- Recommendation: ready for next review round / ready for Red Team / partial (with reason)

**Reconciliation Self-Check (mandatory before commit):**

```
✅ impl-plan.md     — affected ACs + registry rows updated (if forbidden patterns fixed)
✅ overview.md       — phase status + review pointer updated
✅ handoff.md        — fix-round entry + new rules + service status updated
```

ถ้าข้อใดข้อหนึ่ง ❌ — STOP, fix ก่อน commit. ห้ามปล่อย drift.

### 4.3 Report to User

Present a concise summary in Thai:
- Verdicts breakdown (accepted/rejected/partial)
- Count of files modified and tests added
- Commits created
- Recommendation: ready for next review round or ready for Red Team
