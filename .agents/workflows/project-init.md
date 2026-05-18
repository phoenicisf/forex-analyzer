---
description: Generate project-specific CLAUDE.md + .claude/rules/ from approved Technical Design (Phase 2.5 bridge between Design QA and Implement)
---

# Workflow: Project Bootstrap (post-TD rules generation)

สร้าง project-specific root `CLAUDE.md` + `.claude/rules/*.md` หลังจาก TD approved แล้ว เพื่อ **lock tech stack bias ไว้ที่ TD decisions ไม่ใช่ template defaults**. เป็น Phase 2.5 bridge ระหว่าง Design QA (Phase 2) และ Implement (Phase 3). Engineer subagents (`andm-{backend,frontend,impl}-engineer`, `andm-qa-testing`) ยังคง stack-agnostic — อ่าน rules จาก `.claude/rules/*.md` ตอน runtime ไม่ต้อง retrofit.

**Input:** `{{input}}` — optional flags
- *(no flag)* — fresh run; requires `.claude/stack.json` ไม่มีอยู่ก่อน
- `--regen` — re-run after TD change; backup เดิม → overwrite
- `--amend "<description>"` — targeted edit (e.g. "add Redis rules", "tighten testing config")
- `--dry-run` — show diffs without writing
- `--ide=claude,windsurf,trae,antigravity` — restrict IDE adapter output (default: all 4)

**Examples:**
- `/project-init` — first-time generation after `/td-review` approves
- `/project-init --regen` — after `/amend td` changed backend framework
- `/project-init --amend "add Redis rules for cache layer"` — targeted addition
- `/project-init --ide=claude --dry-run` — preview only

---

## Phase 0: Onboarding (Read These Files NOW)

Read immediately, in parallel:

1. `CLAUDE.md` — root rules (methodology template OR prior-generated project rules)
2. `.agents/skills/andm-project-init-engineer/SKILL.md` — **your persona definition** (activate full protocol)
3. Slim CLAUDE.md template (generation base) — `.andm/constitution/sample-claude-md-slim.md`
   If it doesn't exist → HALT and ask the user to confirm where the methodology was copied (do not invent a template)
4. `docs/state/overview.md` — current module status (OPTIONAL — skip silently if not found)
5. `.claude/stack.json` — prior fingerprint (OPTIONAL — only exists after first run)

Once read (or skipped), proceed to Phase 1.

---

## Phase 1: Pre-flight Checks

### 1.1 Parse Input Flags

Classify mode from `{{input}}`:
- empty → `fresh`
- `--regen` + optional sub-flags → `regen`
- `--amend "<desc>"` → `amend`
- `--dry-run` flag → preview mode (writes nothing at any HALT)
- unrecognized flag → HALT with usage message

### 1.2 Verify TD Approval (HARD-FAIL in fresh/regen modes)

Run in parallel:

```
Check 1: docs/technical-design/02-backend-design.md exists?
Check 2: docs/technical-design/03-frontend-design.md exists?
Check 3: docs/technical-design/04-database-design.md exists?
Check 4: docs/technical-design/claim-review-and-rebuttal/ — latest round has no CRITICAL/HIGH
         pending in the corresponding rebuttal file?
Check 5: docs/adr/ — at least 1 ADR present?
Check 6: docs/ba/01-project-brief.md exists?
```

**If any required check fails in fresh/regen mode** → HALT with specific missing items + next-step recommendation (e.g., "run `/td-rebuttal` to clear findings first"; "run `/td-review` if no reviews exist").

**Amend mode:** only verify `.claude/stack.json` exists. If not, tell user to run `/project-init` fresh first.

### 1.3 Detect Existing CLAUDE.md State

Read root `CLAUDE.md`. Classify by presence of methodology markers:
- **Template** — matches methodology-level template (has `# AI-Native Development Methodology (ANDM) — Project Rules` header, `## Choose Your Methodology` section)
- **Customized** — project-specific rules present (has `# [Project Name]` or actual project name header, no template chooser)
- **Diverged** — has both template and custom sections mixed (rare)

**In fresh mode + Customized or Diverged:** HALT 0 — show first 30 lines of existing CLAUDE.md and ask:
- `regen` → switch to regen mode (backup + overwrite)
- `merge` → preserve user's custom sections, regenerate stack sections only
- `abort` → exit without changes

---

## Phase 2: Extract Tech Facts

Follow SKILL.md Phase 2 fact-extraction schema. Read in parallel:

- `docs/technical-design/02-backend-design.md`
- `docs/technical-design/03-frontend-design.md`
- `docs/technical-design/04-database-design.md`
- `docs/adr/*.md` (all)
- `docs/ba/01-project-brief.md`
- `docs/ba/03-non-functional-requirements.md` (for domain language)
- `docs/api-specs/*.yaml` (response envelope, error shape)
- `docs/ux/01-design-tokens.md` (optional — for web rules)
- `docs/ux/02-component-inventory.md` (optional)

Emit in-memory fact sheet:

```yaml
project:
  name: <from BA 01>
  mission: <from BA 01>
  type: <Web App | API | Mobile | Library | Service>
  status: <MVP | Production | Maintenance>
  domain_terms: [<from BA 01/03>]

services:
  - name: api
    language: <from TD-02>
    framework: <from TD-02>
    test_framework: <from TD-02 or .claude/rules/testing.md fallback>
    patterns: [<Clean Architecture | CQRS | Hexagonal | ...>]
    naming_conventions: <from TD-02>
    response_envelope: <from api-specs>
  - name: web
    language: <from TD-03>
    framework: <from TD-03>
    styling: <from TD-03>
    state_mgmt: <from TD-03>
    test_framework: <from TD-03>
  - name: worker    # OMIT if TD has no worker
    language: <...>
    framework: <...>
    test_framework: <...>
  # Polyglot: emit additional entries per service in TD

database:
  engine: <from TD-04>
  version: <from TD-04>
  orm: <from TD-04>
  migration_tool: <from TD-04>

cross_cutting:
  auth_flow: <from ADR>
  cache: <from ADR — 'none' if absent>
  messaging: <from ADR — 'none' if absent>
  observability: <from ADR — 'none' if absent>
  containerization:
    engine: <Docker Compose | Kubernetes | Vercel + Railway | none>
    source: <ADR-NNN | TD-02 §X | inferred (heuristic: <rule>)>
    rationale: <one-line reason>

api_conventions:
  style: <REST | GraphQL | gRPC>
  response_envelope: <exact shape>
  error_shape: <exact shape>
  versioning: <strategy>

ux_conventions:        # optional
  token_naming: <from UX-01>
  component_hierarchy: <from UX-02>
  figma_used: <true if UX Mode B — detected from Figma references>

source_citations:
  td_commit: <git log -1 --format=%H -- docs/technical-design/>
  adrs_cited: [<filenames>]
  api_specs_cited: [<filenames>]
```

### 2.1 Gap Report

Compare against required fields (SKILL.md Phase 2 Gap Policy):
- **MUST have (hard-fail):** project.name, every service's {language, framework}, database.engine, cross_cutting.auth_flow
- **SHOULD have (warn):** test_framework per service, response_envelope, observability, cross_cutting.containerization.engine
- **NICE (silent):** cache, messaging, domain_terms, ux_conventions

If any MUST-have missing → HALT with gap report + specific "add to TD §X.Y" guidance. Do not invent defaults.

### 2.2 Containerization Inference Fallback

If TD-02 / ADRs are silent on deployment/containerization (no explicit source for `cross_cutting.containerization.engine`), run the heuristic in `SKILL.md` Phase 2 Gap Policy → Inference Fallback table:
- Polyglot (≥ 2 different `services[].language`) → propose `Docker Compose`
- services + database + (`cache != 'none'` OR `messaging != 'none'`) → propose `Docker Compose`
- Worker / queue service exists → propose `Docker Compose`
- Single service + managed/serverless host → propose `none`
- Otherwise → propose `none`

When inference fires, set `containerization.source` to `inferred (heuristic: <which-rule-fired>)` and write the rationale. **Do NOT write the inferred value to `.claude/stack.json` yet** — surface it to the user at HALT 1 along with the gap warnings, then write only after explicit user `approve`. User can `revise "use Kubernetes"` / `revise "no container"` / `revise "<other>"` at HALT 1 to override the proposal before any file is touched.

---

## Phase 3: Generate root CLAUDE.md + AGENTS.md ── HALT 1

### 3.1 Build CLAUDE.md content

Start from the slim template (resolved in Phase 0 step 3 — `.andm/constitution/sample-claude-md-slim.md`). Apply substitutions:

1. **§1 Project Overview** — fill `[ชื่อ]`, `[ประเภท]`, `[สถานะ]` from `project.*` facts.
   **AUTO-MANAGED:phase-status block** — preserve the "🔴 READ FIRST — Three-Tier Closure Convention" callout verbatim (it's a methodology-owned anti-hallucination scaffold; never strip). Status snapshot table:
   - **Fresh mode** (no `docs/state/impl-plan.md` yet) — render placeholder rows verbatim from template (`[✅/⚠️ N/M tasks]` etc.); Impl Planner ออก first cut หลัง `/impl-plan 1`
   - **Regen / merge mode** with impl-plan present — parse `docs/state/impl-plan.md`:
     - For each Implementation Phase (P1..P4): count `[x]` vs `[ ]` task ACs → Tier 1 cell
     - For each Implementation Phase: glob `docs/state/_session-handoff/*-phase<N>-exploratory-walk.md` → Tier 1.5 cell (✅ artifact dated within 14d / ⚠️ stale / ❌ missing)
     - For each Implementation Phase: scan "## Phase Gate" or `IMPL-Pn-GATE` task rows → Tier 2 cell (✅ ถ้า [x] ครบ / 🔴 ถ้าเหลือ [ ] / ⚠️ ถ้ายังไม่มี gate task เลย)
     - Grep forbidden closure patterns ("deferred to operator-runtime" / "deferred per .* precedent") → ถ้าพบ ≥1 บน [x] ACs → mark Tier 1 cell ด้วย 🔴🔴 + count
   - **Never** silently equate Tier 1 = Tier 1.5 = Tier 2 — these are independent dimensions
2. **§2 Tech Stack table** — replace placeholders with extracted stack; add rows per polyglot service; always include DB, Auth, Testing rows. Container row is **conditional**:
   - `containerization.engine != "none"` → populate Container row with `engine + version` and append source citation comment (`<!-- source: <containerization.source> -->`)
   - `containerization.engine == "none"` AND mode in {fresh, regen} → REMOVE the Container row from rendered output (do not leave the `[e.g. Docker Compose]` placeholder)
   - mode == merge AND existing Container row is hand-customized (does not match the template's `[e.g. Docker Compose]` placeholder verbatim) → preserve as-is, do not overwrite or delete; log as "preserved hand-customized Container row" in HALT 1 summary
3. **§3 Architecture Rules** — preserve methodology baseline rules; append stack-specific key rules from TD-02/03 (e.g., "ใช้ CQRS + MediatR ในทุก feature" if TD-02 says so); cite TD section. The "Deployment:" line follows the **same conditional rule as the Container row** above (populate / remove / preserve based on `containerization.engine` + mode).
4. **§4 Security Rules** — preserve methodology baseline; append stack-specific notes (e.g., "Auth: Keycloak JWT per ADR-004")
5. **§5 Git Rules** — preserve verbatim from template
6. **§6 Agent Workflow Rules** — preserve verbatim
7. **§7 Glossary (Option C Canonical Terms)** — preserve verbatim from template + add **§7b Domain Glossary** subsection from `project.domain_terms` facts
8. **§8 Document References** — preserve structure; update service paths to match actual services generated (e.g., add `.claude/rules/ml-worker.md` if polyglot)

### 3.2 Preserve Methodology Sections

Demarcate methodology-owned sections with markers (verbatim zone):

```markdown
<!-- METHODOLOGY:BEGIN Section: Glossary Option C -->
...verbatim from template...
<!-- METHODOLOGY:END -->
```

### 3.3 Cite Sources

For each generated stack-specific rule, add source citation comment:

```markdown
- ใช้ Actix-Web framework + SQLx สำหรับ DB access  <!-- source: TD-02 §3.1 -->
```

### 3.4 Emit `AGENTS.md` (Tier 1b — slim pointer)

Generate root `AGENTS.md` as a slim pointer file (~25 lines):

```markdown
# AGENTS.md — AI Agent Entry Point

> Multi-IDE Agent Primer. All Claude-compatible agents (Claude Code, Windsurf, TRAE, Antigravity, etc.) should read [CLAUDE.md](./CLAUDE.md) as the authoritative source of project rules.

## Quick Context
- **Project:** <project.name>
- **Type:** <project.type>
- **Methodology:** Full Track (see `.andm/constitution/`)
- **Tech Stack (summary):**
  - Backend: <language + framework>
  - Frontend: <language + framework>
  - Database: <engine>
  - <additional services if polyglot>

## Where to Look
- **Rules (canonical):** [CLAUDE.md](./CLAUDE.md)
- **Per-IDE rule adapters:** `.claude/rules/`, `.windsurf/rules/`, `.trae/rules/`
- **Workflow commands:** `.claude/commands/` (or `.windsurf/workflows/`)
- **Design docs:** `docs/design-docs/`, `docs/technical-design/`, `docs/ba/`, `docs/ux/`

Last generated by `/project-init` on <ISO-8601>. Do not edit manually — regenerate via `/project-init --regen`.
```

### 3.5 HALT 1 — User Diff Review

Present:
- **Mode:** fresh / regen / amend / dry-run
- **CLAUDE.md diff** (unified diff against existing file; if fresh on template → full new content)
- **AGENTS.md diff**
- **Source citations** (footnote list mapping each new rule to TD section / ADR)
- **Gap warnings** (from 2.1 — any SHOULD-have fields missing)

Ask user:
- `approve` → write files (backup existing to `*.bak-<ts>` if regen), proceed to Phase 4
- `revise "<feedback>"` → collect feedback, regenerate affected sections, re-HALT
- `skip` → leave CLAUDE.md + AGENTS.md untouched, proceed to Phase 4 (rules only)
- `abort` → exit without changes

> ⚠️ **CRITICAL: ห้าม write โดยไม่ได้ user approve ใน HALT 1**

---

## Phase 4: Generate .claude/rules/*.md ── HALT 2

### 4.1 Per-service rule files

For each service in `services[]`, generate `.claude/rules/<name>.md` using SKILL.md rule-template patterns:
- **Project Structure** section — reflect actual framework layout
- **Naming Conventions** section — from TD or framework defaults
- **Architecture Rules** section — dependency flow, module boundaries, patterns
- **Service-Specific Rules** — framework idioms (e.g., Actix request handlers, FastAPI dependency injection)
- **Testing** — actual test framework + commands
- **Error Handling** — language-specific error pattern

Rule file naming:
- First backend → `.claude/rules/api.md`
- First frontend → `.claude/rules/web.md`
- First async/worker → `.claude/rules/worker.md`
- Additional polyglot services → `.claude/rules/<service-name>.md` (slug from `services[].name`)

### 4.2 Cross-cutting rule files

- `.claude/rules/security.md` — regenerate:
  - Retain methodology OWASP baseline
  - Append stack-specific: actual auth flow (Keycloak/Auth0/custom), JWT vs session, framework-specific CSRF handling
- `.claude/rules/testing.md` — regenerate:
  - Retain Empirical Closure Discipline section back-pointer (`andm-impl-engineer/SKILL.md § Empirical Closure Discipline`)
  - Replace per-service test frameworks with actual ones from facts (`stack.json.services[].test_framework`)
  - **Materialize per-service-kind Prove-It evidence table** — for each service in `stack.json.services[]`, emit a stack-specific row mapping the abstract evidence-kinds (probe/gui-capture/log-assertion/queue-inspect/db-inspect/file-blob-check/boot-cold/contract-roundtrip) to concrete tools available in that stack (e.g., `[probe]` for an Actix-Web service → `cargo run` + `curl` or `httpie`; `[probe]` for a Spring Boot service → `mvn spring-boot:run` + `curl` or `RestAssured`). Generation rules:
    - Lookup `services[].language` + `framework` + `test_framework` → derive concrete commands from the language's idiomatic tooling
    - Cite `stack.json` fields used (so reviewer can audit derivation)
    - For evidence-kinds not applicable to this service kind (e.g., `[gui-capture]` on a worker-only service) → mark `n/a`
    - DO NOT invent tools not declared in `stack.json` or the language's standard toolchain — surface gap as `<!-- TD gap: testing tool for [evidence-kind] unspecified -->` instead
- `.claude/rules/workflow.md` — preserve verbatim (stack-agnostic git/PR/handoff/ADR rules)
- `.claude/rules/figma-conventions.md` — preserve if `ux_conventions.figma_used == true`; else delete
- `.claude/rules/docker.md` — generate IFF `cross_cutting.containerization.engine != "none"`:
  - Use SKILL.md Phase 6 `docker.md` skeleton as the base
  - Per-service Dockerfile sub-sections derived from `services[].language` (one sub-section per polyglot service; pick canonical multi-stage pattern per language from the skeleton's snippet table)
  - Compose Layout section enumerates every service from `services[]` plus DB / cache / messaging facts
  - Cite `.agents/workflows/impl-task.md:130` (orchestrator-only ownership of `docker-compose.yml`)
  - Cite `.agents/workflows/red-team.md:83` finding #20 (non-root user, no health-endpoint exposure)
  - If `containerization.source` starts with "inferred" → prepend top-of-file note "Derived by `/project-init` heuristic; revise via `/project-init --amend` if incorrect"
  - In regen mode: if prior generation produced this file but new facts have `engine == "none"` → mark `.claude/rules/docker.md` as DELETE in the HALT 2 diff (and back up to `.claude/rules/docker.md.bak-<ts>` before removal)

### 4.3 Delete obsolete rule files

If prior generation had `.claude/rules/worker.md` but current facts have no worker → stage for deletion. Show in diff with "DELETE" marker.

### 4.3a Empirical Verification Scaffold (mandatory if any HTTP/UI/worker surface or container)

**Generation trigger:** any of the following is true in `stack.json`:
- ≥1 service with HTTP/RPC entry surface
- ≥1 service with user-visible UI (frontend / web / mobile / desktop)
- `cross_cutting.containerization.engine != "none"`
- ≥1 service with `framework` indicating async worker (queue consumer / scheduled job)

**If none apply** (pure CLI / pure library / serverless function with no HTTP) → log "Empirical scaffold skipped — no live-system surface detected" + skip section.

**Files to generate** (paths chosen per the canonical layout for the dominant language; surface as proposals at HALT 2):

1. **Smoke spec** — at the project's idiomatic E2E test location
   - Web/full-stack project → `tests/e2e/smoke.<ext>` using the project's E2E framework
     (Playwright / Cypress / WebdriverIO / Selenium / Puppeteer for web; Appium / Detox / Maestro for mobile; Tauri-test for desktop — pick from `services[].framework` + UI conventions)
   - API-only project → `tests/integration/smoke.<ext>` using the project's HTTP test framework
     (RestAssured / SuperTest / Postman+Newman / xUnit+TestServer / pytest+httpx — pick from `services[].test_framework`)
   - Worker-only project → `tests/integration/smoke.<ext>` using publish-and-assert pattern
     (broker-specific: kafka-streams test / NATS testkit / Celery's `task.apply()` integration mode / etc.)
   - Smoke spec content: (a) entry surface reachable + 200/expected-status, (b) every referenced asset/dependency URL in the rendered entry surface returns success, (c) deep-health probe chain green
2. **E2E run config** — only if the chosen E2E framework requires one (e.g., `playwright.config.ts`, `cypress.config.ts`, `wdio.conf.ts`); skip for frameworks where smoke spec is self-contained (e.g., RestAssured)
3. **Cold-bootstrap recipe** — added as a section in `.claude/rules/workflow.md`:
   - "Bootstrap from cold" command sequence for this project (compose up / k8s apply / serverless deploy / cargo run / etc. — derived from `containerization.engine` + `services[].entry_command`)
   - "Teardown" inverse command sequence
   - Smoke spec invocation command
4. **CI hook** (advisory — do not auto-write CI files; surface as recommendation at HALT 2)
   - "Suggested CI step: run smoke spec against bootstrapped stack on every PR — file: `<CI-vendor-default-path>`"

**Stack-agnostic constraints:**
- Never hardcode Playwright / Vitest / docker-compose / curl as the only choice — every tool selection must derive from `stack.json` or the language's standard toolchain
- If the dominant stack lacks a canonical E2E framework → emit a stub spec in the language's standard test framework + add `<!-- TD gap: project lacks E2E framework convention; suggest framework selection -->` warning to HALT 2
- For polyglot projects (multiple `services[].language`), generate one smoke spec per service-kind cluster (web cluster + API cluster + worker cluster) rather than forcing one framework across all
- Do NOT generate any service-internal scaffolds (controllers/routes/components) — those are engineer's territory

### 4.4 Preserve local overrides

If `.claude/rules/*.local.md` exists for any file → log as "preserved: user override" and do not touch. Mention in summary.

### 4.5 HALT 2 — User Diff Review

Present:
- Per-file diff (unified diff against existing file)
- Summary table: added | modified | deleted | preserved-local
- Gap warnings (any rule section marked with `<!-- TD gap: ... -->`)

Ask user: `approve | revise "<feedback>" | skip | abort`.

### 4.6 Write (on approve)

In regen mode: backup existing `.claude/rules/*.md` → `.claude/rules/*.md.bak-<ISO-8601>`. Then write new files. Delete files marked for deletion.

---

## Phase 5: IDE Adapter Mirror

Skip any IDE not in `--ide=` flag (default: all 4).

### 5.1 Claude Code (primary — already done)

`.claude/rules/*.md` + `.claude/stack.json` — already written in Phase 4.

### 5.2 Windsurf

Mirror `.claude/rules/*.md` → `.windsurf/rules/*.md` (content identical; Windsurf reads from its own rules folder).

If `.windsurf/rules/` doesn't exist → create. Do not touch `.windsurf/workflows/` (methodology-managed).

### 5.3 TRAE

Mirror `.claude/rules/*.md` → `.trae/rules/*.md`. Create directory if absent.

### 5.4 Antigravity

Primary entry is `AGENTS.md` at root (already generated in Phase 3.4). No separate mirror folder needed. If future Antigravity convention requires `.antigravity/` → add in a follow-up PR.

---

## Phase 6: Emit Stack Fingerprint + Summary

### 6.1 Write `.claude/stack.json`

```json
{
  "schema_version": "1",
  "generated_at": "<ISO-8601>",
  "generated_by": "/project-init",
  "mode": "fresh | regen | amend",
  "td_source": {
    "commit": "<git hash of latest TD change>",
    "files": [
      "docs/technical-design/02-backend-design.md",
      "docs/technical-design/03-frontend-design.md",
      "docs/technical-design/04-database-design.md"
    ],
    "adrs": ["ADR-001", "ADR-004", "..."]
  },
  "project": { "name": "...", "type": "...", "status": "..." },
  "services": [ ...per-service facts... ],
  "database": { ... },
  "cross_cutting": {
    "auth_flow": "...",
    "cache": "...",
    "messaging": "...",
    "observability": "...",
    "containerization": {
      "engine": "Docker Compose | Kubernetes | Vercel + Railway | none",
      "source": "ADR-NNN | TD-02 §X | inferred (heuristic: <rule>)",
      "rationale": "<one-line reason>"
    }
  },
  "ide_targets": ["claude", "windsurf", "trae", "antigravity"],
  "outputs": {
    "root": ["CLAUDE.md", "AGENTS.md"],
    "claude_rules": [".claude/rules/api.md", ".claude/rules/web.md", ...],
    "windsurf_rules": [".windsurf/rules/api.md", ...],
    "trae_rules": [".trae/rules/api.md", ...]
  },
  "local_overrides_preserved": [".claude/rules/api.local.md"],
  "backups_created": [".claude/rules/api.md.bak-2026-04-18T..."]
}
```

### 6.2 Present Summary in Thai

```markdown
## Project Bootstrap Summary

**Mode:** fresh | regen | amend
**Generated at:** <timestamp>
**TD commit:** <hash>

### Files
| Category | Created | Modified | Deleted | Preserved (local) |
|----------|---------|----------|---------|-------------------|
| Root | AGENTS.md | CLAUDE.md | — | — |
| Claude rules | .claude/rules/* | — | worker.md (no worker) | api.local.md |
| Windsurf | .windsurf/rules/* | — | — | — |
| TRAE | .trae/rules/* | — | — | — |
| Fingerprint | .claude/stack.json | — | — | — |

### Source Citations
- Tech stack derived from: `docs/technical-design/02-backend-design.md` §3.1 (Backend: <language + framework>)
- Auth flow: ADR-004 (<auth strategy>)
- Database: `docs/technical-design/04-database-design.md` §2 (<engine + ORM>)
- Response envelope: `docs/api-specs/<file>.yaml` §components.responses

### Gap Warnings
- [ ] No observability pattern documented — rules omit OTel/logging conventions
- [ ] Messaging not specified — worker rules use generic patterns

### Backups
Previous files backed up to: `*.bak-<ISO-8601>`

### Next Steps
1. **Review** generated content — git diff to sanity-check
2. **Commit** as: `feat(project-init): bootstrap CLAUDE.md + rules from approved TD`
3. **Proceed** to `/impl-plan 1` to generate implementation plan
4. **If TD changes later** → run `/project-init --regen`
```

### 6.3 Suggest Commit (do NOT auto-commit)

Propose commit message:
```
feat(project-init): generate project-specific CLAUDE.md + rules from approved TD

Why: Phase 2.5 bootstrap — derives project rules from docs/technical-design/*
to lock tech stack bias to TD decisions rather than template defaults.

Generated:
- CLAUDE.md (project overview, tech stack, rules references)
- AGENTS.md (multi-IDE entry point)
- .claude/rules/{api,web,worker,security,testing,workflow[,docker]}.md
  (docker.md only when containerization.engine != "none")
- .claude/stack.json (fingerprint — includes containerization.engine + source)
- .windsurf/rules/*, .trae/rules/* (IDE mirrors)

Source: TD commit <hash>, ADRs: <list>
```

User runs `git commit` when satisfied.

---

## Coordination with Other Workflows

| Trigger | Recommendation |
|---------|---------------|
| `/next` detects no `.claude/stack.json` + TD approved | Recommend `/project-init` |
| `/next` detects `stack.json` older than TD files | Recommend `/project-init --regen` |
| `/amend td` completes | Hint: "TD changed — run `/project-init --regen` if stack affected" |
| `/backtrack td` resolves | Flag `.claude/rules/*` as potentially stale; suggest `/project-init --regen` |
| `/impl-plan` pre-flight | Soft warning if no `stack.json` (not a hard block — override allowed) |

---

## Safety Rules

- ❌ Never modify `.agents/skills/`, `.agents/workflows/`, `.andm/development-guide/`, `.andm/prompt-templates/` (methodology source of truth)
- ❌ Never modify `methodologies/` (canonical source)
- ❌ Never modify root `README.md` (methodology-level content)
- ❌ Never touch production code under `services/*/src/`
- ❌ Never touch design docs (`docs/ba/`, `docs/design-docs/`, `docs/technical-design/`, `docs/ux/`, `docs/adr/`, `docs/api-specs/`)
- ✅ Always backup existing generated files before overwrite (`.bak-<ISO-8601>` suffix)
- ✅ Always preserve `.local.md` override files untouched
- ✅ Always hard-fail if TD not approved (in fresh/regen modes)
- ✅ Always HALT per output group — never write without explicit user approve
- ✅ Always cite TD/ADR sources for generated content
