---
description: Reference playbook for Phase 1.5 Parallel Execution — Claude Code-only subagent fan-out patterns used across full-track workflows and prompt templates
---

# Parallel Execution Playbook (Claude Code Only)

> **This is a REFERENCE doc, not a slash command.**
> Workflows invoke the patterns here via a `## Phase 1.5: Parallel Execution (Claude Code only)` section. Non-Claude-Code IDEs (Windsurf / Cursor / OpenCode / Gemini CLI) skip Phase 1.5 and run the existing serial Phase 2 path unchanged.

---

## 1. When to Use Phase 1.5

Use this decision tree before entering Phase 1.5:

```
Running under Claude Code (Task tool available)?
├── No  → SKIP Phase 1.5 entirely. Go to Phase 2 serial.
└── Yes → Target argument?
          ├── Single file/service (e.g. `docs/ba/02-functional-requirements.md`)
          │   → SKIP (fan-out overhead > benefit for 1 unit)
          └── `all` OR target list has ≥3 independent units?
              ├── No  → SKIP (1–2 units: serial is fine)
              └── Yes → PROCEED to Phase 1.5
```

**Anti-pattern:** do NOT fan out rebuttals (`ba-rebuttal`, `sd-rebuttal`, `td-rebuttal`, `ux-rebuttal`, `qa-rebuttal`) — they need coherent cross-claim narrative, and parallel fixes can race on shared files.

**Anti-pattern:** do NOT fan out inherently sequential workflows (`impl-plan`, `impl-task`, `backtrack`, `next`, `ux-fix`, `project-init`).

---

## 2. Pattern Catalog

Four patterns cover every supported workflow. Pick the one matching your workflow below:

### 2.1 Fan-Out-Docs

**Shape:** N independent documents reviewed/generated in parallel, one agent per doc.

**Used by:** `ba-review`, `sd-review`, `td-review`, `ux-review`, `qa-review`; prompt templates `ba-requirements-prompt.md`, `system-design-master-prompt.md`, `technical-design-master-prompt.md`, `qa-plan-direct-prompt.md`.

**Example:** `ba-review all` — 5 BA docs (01-project-brief through 05-user-flows; v1.2: 06-handoff dropped) → 5 Task calls with `subagent_type="andm-ba-reviewer"`, each scoped to one doc path.

**Worked example (ba-review):**
```
Shared context:   docs/state/_parallel-context/ba-review-round-01.md
Agent 1: andm-ba-reviewer — scope: docs/ba/01-project-brief.md
Agent 2: andm-ba-reviewer — scope: docs/ba/02-functional-requirements.md
Agent 3: andm-ba-reviewer — scope: docs/ba/03-non-functional-requirements.md
Agent 4: andm-ba-reviewer — scope: docs/ba/04-business-rules.md
Agent 5: andm-ba-reviewer — scope: docs/ba/05-user-flows.md
Return contract: ba-finding-fragment (see § 5.1)
Merge: orchestrator composes docs/ba/claim-review-and-rebuttal/claim-review-NN.md
```

### 2.2 Service-Oriented

**Shape:** N independent services reviewed/fixed in parallel, one agent per service directory.

**Used by:** `impl-review`, `red-team`, `impl-review-fix`, `red-team-rebuttal`.

**Example:** `impl-review all` — fan out to 3 agents: `services/api/`, `services/web/`, `services/worker/`.

**Worked example (impl-review):**
```
Shared context:   docs/state/_parallel-context/impl-review-round-01.md
Agent 1: andm-code-reviewer — scope: services/api/   (C# .NET 9 rules + design compliance)
Agent 2: andm-code-reviewer — scope: services/web/   (Next.js rules)
Agent 3: andm-code-reviewer — scope: services/worker/ (Python/Celery rules)
Return contract: impl-review-finding-fragment (see § 5.2)
Merge: orchestrator composes docs/code-review/review-round-NN.md
```

**Race prevention (fix variants only):** each subagent edits files scoped to `services/<its-service>/` only. Orchestrator owns root configs (`.env`, `docker-compose.yml`, root `package.json`, `.gitignore`) and the single report file.

### 2.3 Category-Oriented

**Shape:** N independent categories of work, one agent per category.

**Used by:** `qa-plan-direct-prompt.md` (test case categories).

**Example:** after test strategy `docs/qa/01-test-execution-plan.md` is drafted, fan out 6 agents: one each for TC-FR, TC-API, TC-SEC, TC-DF, TC-NFR, TC-EDGE (optional TC-UX if UX docs available).

**Worked example (qa-plan):**
```
Shared context:   docs/state/_parallel-context/qa-plan-round-01.md
Agent 1: andm-qa-testing — scope: generate TC-FR-*.md under docs/qa/02-test-cases/
Agent 2: andm-qa-testing — scope: generate TC-API-*.md (source: docs/api-specs/*.yaml)
Agent 3: andm-qa-testing — scope: generate TC-SEC-*.md (source: docs/design-docs/05-security.md)
Agent 4: andm-qa-testing — scope: generate TC-DF-*.md (source: docs/design-docs/04-data-flow.md)
Agent 5: andm-qa-testing — scope: generate TC-NFR-*.md (source: docs/ba/03-non-functional-requirements.md)
Agent 6: andm-qa-testing — scope: generate TC-EDGE-*.md (source: docs/design-docs/03-deep-dive.md + ADRs)
Return contract: qa-test-case-fragment (see § 5.4)
Merge: orchestrator writes individual TC-*.md files + docs/qa/03-traceability-matrix.md last (sequential tail)
```

### 2.4 Phase-Readiness-Grid

**Shape:** N independent phase/readiness checks in parallel.

**Used by:** `deliver`.

**Example:** readiness assessment fans out to 4 agents — BA/SD/UX/TD readiness, Impl readiness, Code-review readiness, Security/red-team readiness.

**Worked example (deliver):**
```
Shared context:   docs/state/_parallel-context/deliver-round-01.md
Agent 1: andm-deliver-handoff — scope: Design readiness  (BA + SD + UX + TD completeness + approval)
Agent 2: andm-deliver-handoff — scope: Impl readiness    (impl-plan + task completion + handoff.md)
Agent 3: andm-deliver-handoff — scope: Code-review readiness  (review rounds passed, no CRITICAL/HIGH)
Agent 4: andm-deliver-handoff — scope: Security readiness (red-team rounds passed, no CRITICAL/HIGH)
Return contract: readiness-fragment (see § 5.5)
Merge: orchestrator composes docs/state/overview.md delivery summary + per-module handoff.md
```

---

## 3. Task Tool Invocation Template

Every Phase 1.5 block spawns subagents via the same invocation shape. Copy-paste and fill in the ALL-CAPS placeholders:

```
Use the Task tool — emit ALL N calls in ONE message (parallel) with:

  description:   "<SHORT_TITLE> — <SCOPE_LABEL>"
  subagent_type: "<PERSONA_NAME>"       ← must match a file in .agents/agents/<persona-name>.md
  prompt: |
    Role: you are <PERSONA_NAME>. Full persona: .agents/skills/<persona-name>/SKILL.md

    Shared context file: docs/state/_parallel-context/<WORKFLOW>-round-<NN>.md
    (read this file first — it has round info, anti-duplication claim IDs, entry criteria)

    SCOPE: <EXACT_PATH_OR_LABEL>       ← single doc / single service / single category
    Do NOT touch anything outside this scope.

    Return a fenced markdown fragment matching the schema "<FRAGMENT_SCHEMA_NAME>"
    (see .agents/workflows/_parallel-execution-playbook.md § 5).
    Do NOT write output files — orchestrator will compose the final round file.
```

**Critical rules:**
- **ONE message, N Task calls** — not N messages with 1 call each. Claude Code parallelizes tool calls within a single response.
- **subagent_type must be string-equal** to the `name:` field of a file in `.agents/agents/`. Typos = spawn failure.
- **prompt: must include SCOPE** — the persona is generic; scope narrows it to one doc/service/category.
- **Never ask the subagent to write final output files** — only fragments returned inline.

---

## 4. Shared-Context File

### 4.1 Path convention

```
docs/state/_parallel-context/<workflow-name>-round-<NN>.md
```

Examples:
- `docs/state/_parallel-context/ba-review-round-01.md`
- `docs/state/_parallel-context/impl-review-round-03.md`
- `docs/state/_parallel-context/qa-plan-round-01.md`

### 4.2 Gitignore

Add to the project's `.gitignore` (this is a runtime artifact, not source):

```
# Parallel execution shared-context briefings (runtime only)
docs/state/_parallel-context/
```

`project-init` workflow should seed this gitignore line; if the file already exists and lacks it, append during `/project-init` or `/project-init --regen`.

### 4.3 Required fields

Every shared-context file has the same skeleton:

```markdown
# Parallel Context — <Workflow> Round <NN>

**Generated:** <ISO-8601 timestamp>
**Orchestrator:** main session (Claude Code)
**Round:** <NN>
**Target:** <all | scoped list>

## 1. Target List
- <full list of scopes the orchestrator will fan out to>

## 2. Anti-Duplication (claims already resolved in prior rounds)
- <list of claim IDs from rounds 1..NN-1 — so this round's agents don't re-surface fixed items>

## 3. Entry Criteria (shared)
- <prerequisites all agents must verify before finding issues — e.g. "docs exist", "tests pass">

## 4. Severity Scale
See `.agents/skills/_severity-scale.md`.

## 5. Return Fragment Schema
Return fragments matching `<fragment-schema-name>` — see playbook § 5.
```

### 4.4 Lifecycle

1. **Orchestrator writes** this file fresh at Phase 1.5.2 of every invocation.
2. **Subagents read-only** — never edit.
3. **File is overwritten** on next round (round number is canonical — never reuse stale files).
4. **Not committed to git** — purely runtime scratch.

---

## 5. Return Contract — Fragment Schemas

Subagents return findings as fenced markdown blocks. Orchestrator parses by schema name.

### 5.1 `ba-finding-fragment` — used by `ba-review`

```markdown
​```ba-finding-fragment
scope: <doc path, e.g. docs/ba/02-functional-requirements.md>
agent: andm-ba-reviewer
attack-vectors-run: [<list of vector IDs from SKILL.md>]
findings:
  - id: <agent-local id, e.g. BA-02-001>
    severity: 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | ⚪ LOW
    vector: <vector name>
    location: <file:line or section>
    claim: <one-line issue>
    evidence: <quote or cross-ref>
    suggested-fix: <one-line>
​```
```

### 5.2 `impl-review-finding-fragment` — used by `impl-review`

```markdown
​```impl-review-finding-fragment
scope: <service dir, e.g. services/api>
agent: andm-code-reviewer
dimensions-run: [owasp, correctness, error-handling, performance, over-engineering, cross-service, test-coverage, design-compliance]
findings:
  - id: <CR-API-001>
    severity: 🔴 | 🟠 | 🟡 | ⚪
    dimension: <one of the 8>
    location: <file:line>
    claim: <one-line>
    evidence: <code excerpt or link>
    suggested-fix: <one-line>
​```
```

### 5.3 `red-team-finding-fragment` — used by `red-team`

```markdown
​```red-team-finding-fragment
scope: <service dir>
agent: andm-red-team-attacker
frameworks: [OWASP-Top-10, STRIDE]
findings:
  - id: <RT-API-001>
    severity: 🔴 | 🟠 | 🟡 | ⚪
    framework: OWASP | STRIDE
    category: <e.g. A03 Injection | T: Tampering>
    location: <file:line>
    claim: <vulnerability>
    poc: <proof-of-concept or repro>
    suggested-fix: <one-line>
​```
```

### 5.4 `qa-test-case-fragment` — used by `qa-plan-direct-prompt.md` (Category-Oriented)

```markdown
​```qa-test-case-fragment
scope: <category, e.g. TC-FR | TC-API | TC-SEC | TC-DF | TC-NFR | TC-EDGE | TC-UX>
agent: andm-qa-testing
source-docs: [<list of design doc paths used>]
test-cases:
  - id: <TC-FR-001>
    title: <short>
    preconditions: <list>
    steps: <list>
    expected: <list>
    traceability: [<FR-ID or NFR-ID or API-endpoint>]
​```
```

### 5.5 `readiness-fragment` — used by `deliver`

```markdown
​```readiness-fragment
scope: <Design | Impl | CodeReview | Security>
agent: andm-deliver-handoff
status: ✅ ready | ⚠️ blocked | 🔴 failing
checks:
  - name: <check name>
    result: pass | fail | warn
    evidence: <doc path or metric>
    blocker: <true|false>
blockers:
  - <short description>
```
```

### 5.6 `sd-finding-fragment`, `td-finding-fragment`, `ux-finding-fragment`, `qa-finding-fragment`

Structurally identical to `ba-finding-fragment` — only `scope`, `agent`, and `attack-vectors-run` change. Use `<family>-finding-fragment` as the schema name.

---

## 6. Merge Strategy — Orchestrator as Synthesizer

### 6.1 Core rule

**Subagents NEVER write the final round file.** They return fragments inline. The main-session orchestrator composes the single output file.

**Rationale:**
- **No write races** — one writer, one file.
- **Human-checkable artifact** — one round file per round (matches "never have AI approve AI" constitution rule).
- **Simpler rollback** — revert one file, not 6.

### 6.2 Deduplication

After collecting all fragments:

1. **Key by `(file, line, vector-or-dimension)` tuple.** If two agents flag the same tuple, merge into one finding.
2. **Higher severity wins** on merge. E.g. agent-A says HIGH, agent-B says CRITICAL → record CRITICAL.
3. **Union the evidence lists** — preserve both quotes if they differ.
4. **Anti-dup against shared-context § 2** — drop findings already resolved in prior rounds.

### 6.3 Output file composition

1. Assemble frontmatter (round number, targets scanned, agents used, run timestamp).
2. Group findings by severity (CRITICAL → HIGH → MEDIUM → LOW).
3. Within each severity, group by scope (doc / service / category).
4. Append "parallel execution metadata" footer listing agent-count, fallback events (if any).
5. Write to the single canonical path (see workflow's Phase 1.5 spec).

### 6.4 Severity scale

Use the shared scale at `.agents/skills/_severity-scale.md` — all fragments and merged output share the same 4 levels.

---

## 7. Fallback Rules

### 7.1 Partial return

If any Task call fails (budget, concurrency cap, error, decline):

1. **Do NOT fail the whole round.** Collect fragments that DID return.
2. For each missing scope, run the serial Phase 2 path for JUST that scope (re-read doc, apply vectors, produce findings inline in the orchestrator session).
3. Note the fallback in the round-file footer: `Parallel coverage: <successful>/<total> scopes; serial fallback applied for: <list>`.

### 7.2 All-Task fallback

If zero Task calls succeed (e.g. Claude Code session lost Task tool mid-run):

1. Log the event in the round-file footer.
2. Re-enter Phase 2 as though Phase 1.5 never ran.
3. Output is identical to the serial path (just slower).

### 7.3 Non-Claude-Code IDE

Phase 1.5 starts with `> **Skip this section** ถ้าไม่ได้ใช้ Claude Code`. Windsurf/Cursor/OpenCode/Gemini CLI readers see the guard and jump to Phase 2. The block is inert — no parsing, no spawn attempt, no side effects.

---

## 8. Scope — How Phase 1.5 Relates to `/next` Phase 3 Parallel Region

These are **orthogonal** concerns. Do not confuse them.

| Concept | Granularity | Who decides | Artifact |
|---------|-------------|-------------|----------|
| **`/next` Phase 3 Parallel Region** | INTER-workflow scheduling | User picks which workflow to run next (Impl track vs QA track) | `docs/state/overview.md`, `docs/state/impl-plan.md` |
| **Phase 1.5 (this playbook)** | INTRA-workflow execution | Orchestrator picks how a single workflow runs internally (serial vs fan-out) | `docs/state/_parallel-context/<workflow>-round-<NN>.md` |

You can have BOTH active simultaneously: `/next` recommends running `/impl-review all` in parallel with `/qa-review all`, and each of those internally uses Phase 1.5 to fan out to 3 agents per service or 3 agents per QA doc.

---

## 9. Validation Checklist

Before shipping any new Phase 1.5 block, verify:

- [ ] `## Phase 1.5:` heading exists between Phase 1 and Phase 2
- [ ] First line references `_parallel-execution-playbook.md` and names the pattern (Fan-Out-Docs / Service-Oriented / Category-Oriented / Phase-Readiness-Grid)
- [ ] Leading `> Skip this section if not Claude Code` guard is present
- [ ] `subagent_type` values each map to a file in `.agents/agents/<name>.md`
- [ ] Shared-context file path follows § 4.1 convention
- [ ] Return Contract schema name matches one in § 5
- [ ] Merge phase assigns file-write to orchestrator (not subagents)
- [ ] Fallback section present (partial return + non-CC IDE skip)

---

## 10. Glossary (Playbook-Local)

| Term | Meaning |
|------|---------|
| **Orchestrator** | The main Claude Code session running the workflow. Reads prompts, spawns Task calls, merges fragments, writes output. |
| **Subagent** | A Task-tool-spawned sub-session with a specific persona. Read-only output (fragments returned inline). |
| **Fragment** | A fenced markdown block subagent returns matching a Return Contract schema (§ 5). |
| **Shared-context file** | Runtime briefing at `docs/state/_parallel-context/` — orchestrator writes, subagents read. |
| **Round** | One full pass of the workflow (round-01, round-02, …). Anti-dup context from prior rounds lives in § 2 of shared-context file. |
| **Fan-out** | The act of emitting N Task calls in one message for N independent scopes. |
| **Merge** | Orchestrator-side deduplication + severity reconciliation + composition into single round file. |
