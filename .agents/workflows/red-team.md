---
description: Run security audit (OWASP + STRIDE) on codebase and generate a Red Team findings report
---

# Workflow: Red Team Security Audit

Perform a code-level security audit using OWASP Top 10 and STRIDE methodology. Output findings into a new `red-team-round-XX.md` file.

**Target:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, security rules
2. `.agents/skills/andm-red-team-attacker/SKILL.md` — **your persona definition** (activate the full Phase 0-4 process defined there)
3. `.claude/rules/security.md` — mandatory security rules (your baseline — violations of these are automatic findings)
4. `docs/design-docs/05-security.md` — intended security design (compare intent vs reality)
5. `docs/state/overview.md` — current module status
6. Check `docs/security/` — previous red-team rounds and defense reports (to avoid duplicate findings)

Once read, you are ready to proceed.

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Use Glob to list all files in `docs/security/`. Find the highest existing `red-team-round-XX.md` number. New round = highest + 1. If none exist, start at 01.

### 1.2 Load Context (MANDATORY — All reads in parallel)

Execute these reads simultaneously:

1. **Security baseline** — Read `.claude/rules/security.md` for rules that MUST be enforced.
2. **Security design** — Read `docs/design-docs/05-security.md` for intended security controls.
3. **Service-specific rules** — Read the relevant `.claude/rules/*.md` for the target service(s).
4. **Target code** — Read the codebase in the target directory:
   - If `{{input}}` is a specific service (e.g., `services/api/`), focus on that service
   - If `{{input}}` is "all", scan all services (`services/api/`, `services/web/`, `services/worker/`)
5. **Previous rounds** — Read the latest 2-3 `red-team-round-XX.md` AND their corresponding `defense-round-XX.md` to understand:
   - What was already found and fixed (avoid duplicates)
   - Patterns of recurring vulnerabilities

> **Anti-Duplication Rule:** If a vulnerability was raised in a previous round AND has a fix in the defense report, do NOT raise it again unless the fix is demonstrably incomplete.

> **LLM Wiki Hard Exclusion:** `docs/security/*` is sensitive raw material. Do not feed red-team reports, threat models, vulnerability details, secrets, customer PII, or incident notes into shared LLM Wiki / `wiki-ingest` / hot cache / cloud summarization. If another workflow needs visibility, create a redacted summary with pointers to the raw file; never copy exploit payloads or secrets into the shared wiki layer.

### 1.3 Engage Persona

Follow the andm-red-team-attacker persona defined in `.agents/skills/andm-red-team-attacker/SKILL.md`. Activate the full Phase 0-4 process defined there.

---

## Phase 2: Attack

### 2.1 Systematic Scan — Code Security Attack Vector Checklist

Walk through the **20 security categories** (defined in SKILL.md Phase 1) against the target codebase. For each category, either raise a finding OR explicitly note it was checked and is clean.

| # | Category | Focus |
|---|----------|-------|
| 1 | SQL Injection | parameterized queries, ORM raw queries |
| 2 | XSS | input sanitization, output encoding, CSP |
| 3 | Authentication | JWT, password hashing, token management |
| 4 | Authorization / IDOR | role checks, object-level auth |
| 5 | CSRF | tokens, SameSite cookies |
| 6 | Mass Assignment | DTO allowlists, writable fields |
| 7 | Rate Limiting | login, password reset, API throttling |
| 8 | Secret Management | hardcoded secrets, .env, .gitignore |
| 9 | Input Validation | type, length, format, range, file upload |
| 10 | Error Handling / Info Leakage | stack traces, DB schema exposure |
| 11 | Dependency Vulnerabilities | known CVEs, outdated packages |
| 12 | Logging & Monitoring | PII in logs, audit trail |
| 13 | File Upload | type validation, size limit, path traversal |
| 14 | Encryption | TLS, data at rest, PII fields |
| 15 | Session Management | timeout, concurrent sessions, invalidation |
| 16 | Business Logic Flaws | workflow bypass, race conditions |
| 17 | API Security | CORS, HTTP methods, response headers |
| 18 | Worker/Queue Security | payload validation, poison messages, DLQ |
| 19 | Database Security | migrations, least privilege, connection pool |
| 20 | Infrastructure | Docker non-root, health endpoint exposure |

**No artificial caps on findings.** Generate as many valid findings as the code warrants.

### 2.2 Cross-Service Consistency

If auditing multiple services, use Grep to check:

| Check | How |
|-------|-----|
| Shared secrets | Grep for API keys, tokens, connection strings across all services |
| Auth consistency | Verify JWT validation is identical across API and Web |
| CORS alignment | Verify CORS origins match between API config and Web domain |
| Error format | Verify error responses don't leak internals in any service |

### 2.3 Draft Findings

Write findings in **Thai**, using the adversarial attacker tone.

Use the **structured format from SKILL.md Phase 3** — must include:
- Exact file path + line number
- Vulnerable code snippet
- Step-by-step attack scenario
- Proof of concept (curl/payload)
- OWASP category reference

### 2.4 Quality Gate (Self-Review Before Output)

Before writing the file, verify every item per SKILL.md Phase 4:

- [ ] Every finding cites exact file path + line number + code snippet
- [ ] No finding repeats an already-fixed issue from previous defense rounds
- [ ] Severity matches the classification matrix
- [ ] Every finding has a proof-of-concept
- [ ] Attack Vector Checklist fully scanned (skipped categories noted)
- [ ] Total findings >= 3
- [ ] Findings in Thai with English technical terms
- [ ] Business logic flaws checked (not just OWASP generic)

---

## Phase 3: Output

### 3.1 Create the File

Use Write to create `docs/security/red-team-round-XX.md` with this structure:

```markdown
# Red Team Security Audit — Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target** | `[service path or "all"]` |
| **Date** | YYYY-MM-DD |
| **Auditor Persona** | Red Team Attacker (Security Auditor) |
| **Methodology** | OWASP Top 10 + STRIDE |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | N |
| HIGH | N |
| MEDIUM | N |
| LOW | N |

---

## Code Security Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | SQL Injection | ✅ Clean / ⚠️ Finding | [brief note] |
| 2 | XSS | ✅ Clean / ⚠️ Finding | [brief note] |
[... all 20 categories ...]

---

## Findings

[All findings ordered by severity: CRITICAL → HIGH → MEDIUM → LOW]

---

## Cross-Service Issues

[Issues found during Phase 2.2, if applicable]

---

## Summary Table

| # | Severity | Title | Location | OWASP | Effort |
|---|----------|-------|----------|-------|--------|
```

### 3.2 Report to User

Present a concise summary in Thai:
- Round number and target
- Count of findings per severity level
- File path to the generated report
- Top 2-3 most critical findings highlighted
- Recommendation: ready for defense rebuttal or needs immediate hotfix
