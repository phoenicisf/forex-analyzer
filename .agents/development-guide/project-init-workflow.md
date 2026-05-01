# Project Bootstrap Workflow — Development Guide

คู่มือการใช้ `/project-init` เพื่อสร้าง project-specific `CLAUDE.md` + `.claude/rules/` หลังจาก TD approved แล้ว. Engineer subagents ยังคง stack-agnostic — อ่าน rules จาก `.claude/rules/*.md` ตอน runtime ไม่ retrofit.

---

## ภาพรวม

`/project-init` คือ **Phase 2.5** — bridge ระหว่าง Phase 2 (Design QA) กับ Phase 3 (Implement). มันอ่าน approved Technical Design + ADRs + BA context แล้วสร้าง project-specific tooling ที่ "lock" tech stack bias ไว้ที่ TD decisions ไม่ใช่ template defaults.

```
Phase 1         Phase 2           Phase 2.5         Phase 3         Phase 4       Phase 5
DESIGN    →    DESIGN QA    →    BOOTSTRAP    →    IMPLEMENT   →   HARDEN   →   DELIVER
(สร้างเอกสาร)   (กรองคุณภาพ)      (sync rules)       (เขียน code)    (security)   (ส่งมอบ)
                 TD approved       /project-init     /impl-plan
                                                     /impl-task
```

### ทำไมต้องมี Phase 2.5

**ปัญหา:** ถ้า `CLAUDE.md` + `.claude/rules/` ถูกเขียนไว้ก่อน Phase 1D (TD) → จะชี้นำ (bias) architect/engineer decisions ไปทาง template defaults (เช่น template บอก "API: C# .NET 9" → architect bias ไป .NET แม้ว่า Go หรือ Rust จะเหมาะกว่าตาม NFR)

**วิธีแก้:** Derive rules **จาก** TD ไม่ใช่ทางกลับ. Lock stack bias ไว้ที่ TD decision process เท่านั้น.

### เมื่อไหร่ควรใช้

- ✅ หลัง `/td-review` ผ่าน (ไม่มี CRITICAL/HIGH ค้างใน latest rebuttal)
- ✅ ก่อน `/impl-plan` เริ่ม
- ✅ หลัง `/amend td` หรือ `/backtrack td` เปลี่ยน tech stack → รัน `--regen`
- ✅ เมื่อต้องการ targeted edit (เช่น เพิ่ม Redis rules) → รัน `--amend "<desc>"`

### เมื่อไหร่ไม่ควรใช้

- ❌ TD ยังไม่ผ่าน review (ยังมี CRITICAL/HIGH ค้าง)
- ❌ BA 01 ยังไม่มี (ไม่มี project name source)
- ❌ ADRs ยังไม่มี (ไม่มี cross-cutting decisions source)
- ❌ ต้องการเปลี่ยน methodology (นั่นคือ template-level concern ไม่ใช่ project)

---

## `/project-init` Command — 4 Modes

### Mode 1: Fresh (default)

```
/project-init
```

รันครั้งแรกหลัง TD approved. ต้องการให้ `.claude/stack.json` ไม่มีอยู่ก่อน.

**Prerequisites:**
- TD docs (02/03/04) ครบ
- TD latest review round ไม่มี CRITICAL/HIGH ค้าง
- BA 01 มีอยู่
- ≥ 1 ADR มีอยู่

**Output:**
- Root `CLAUDE.md`, `AGENTS.md`
- `.claude/rules/{api,web,worker,security,testing,workflow}.md`
- `.claude/stack.json`
- `.windsurf/rules/*.md`, `.trae/rules/*.md` (IDE mirrors)

### Mode 2: Regen

```
/project-init --regen
```

รัน re-generation หลัง TD เปลี่ยน. Backup existing files → overwrite ด้วย new content.

**When to use:**
- หลัง `/amend td` เปลี่ยน tech stack (เช่น backend framework)
- หลัง `/backtrack td` resolve เสร็จ
- `/next` detect ว่า `stack.json` เก่ากว่า TD commit

**Backup:** ทุกไฟล์ที่ถูก overwrite จะถูก backup เป็น `<path>.bak-<ISO-8601>` ก่อน

### Mode 3: Amend

```
/project-init --amend "add Redis rules for cache layer"
/project-init --amend "tighten testing config — require integration tests for all endpoints"
/project-init --amend "remove worker rules — service dropped from scope"
```

Targeted user-driven edit. ไม่ re-extract ทั้งหมด. แก้ surgical เฉพาะที่ user บอก.

### Mode 4: Dry-run

```
/project-init --dry-run
/project-init --regen --dry-run
```

Preview mode — แสดง diffs ทุก HALT แต่ไม่ write ไฟล์จริง. ใช้สำหรับ review ก่อน commit real run.

---

## Optional Flags

| Flag | Effect |
|------|--------|
| `--ide=<list>` | Restrict IDE adapter output. Default: `claude,windsurf,trae,antigravity`. Example: `--ide=claude` |
| `--dry-run` | Preview only — show diffs, no writes |

Combined example:
```
/project-init --regen --ide=claude,windsurf --dry-run
```

---

## Phase-by-Phase Walkthrough

### Phase 0: Onboarding (Agent reads these)

Agent อ่านไฟล์ก่อนเริ่ม:
- `CLAUDE.md` (root)
- `.agents/skills/andm-project-init-engineer/SKILL.md`
- `sample-claude-md-slim.md` (template base)
- `docs/state/overview.md` (optional)
- `.claude/stack.json` (optional — regen/amend only)

### Phase 1: Pre-flight Checks

Agent verifies:
- [ ] TD 02/03/04 exist
- [ ] TD latest review round approved (no CRITICAL/HIGH pending)
- [ ] BA 01 exists
- [ ] ≥ 1 ADR exists
- [ ] CLAUDE.md state classified (template / customized / diverged)

**If any MUST-have check fails** → HALT with gap report + specific next steps ("run `/td-rebuttal`" / "add BA 01" / etc.)

**HALT 0 (conditional):** ถ้า fresh mode + CLAUDE.md is Customized/Diverged → agent ถาม:
- `regen` → switch mode
- `merge` → preserve user sections, regenerate stack sections
- `abort` → exit

### Phase 2: Extract Tech Facts

Agent reads in parallel:
- TD-02 (backend language, framework, test, patterns)
- TD-03 (frontend language, framework, styling, test)
- TD-04 (database engine, ORM, migration)
- All ADRs (auth, cache, messaging, observability, deployment)
- BA 01 (project name, mission, domain)
- BA 03 (NFRs — for testing/observability rules)
- api-specs (response envelope, error shape)
- UX 01-02 (optional — token naming, component hierarchy)

**Gap Report:** If MUST-have fields missing → HALT with gap report + "add to TD §X.Y" guidance.

### Phase 3: Generate root CLAUDE.md + AGENTS.md ── HALT 1

Agent drafts:
- `CLAUDE.md` — from slim template + extracted facts + methodology preservation
- `AGENTS.md` — slim multi-IDE pointer

**Methodology sections preserved verbatim:**
- Glossary (Option C Canonical Terms)
- Git Rules
- Agent Workflow Rules
- Golden Rules

**Stack-specific sections generated:**
- §1 Project Overview (name, type, status, docs reference)
- §2 Tech Stack table (all extracted services + DB + Auth + Testing + Container)
- §3 Architecture Rules (methodology baseline + TD-cited stack rules)
- §4 Security Rules (methodology baseline + ADR-cited auth pattern)
- §7b Domain Glossary (from BA)
- §8 Document References (updated paths for polyglot services)

**Source citations** inline as HTML comments: `<!-- source: TD-02 §3.1 -->`

**HALT 1:** Show diff + source citations + gap warnings. User: `approve / revise / skip / abort`

### Phase 4: Generate `.claude/rules/*.md` ── HALT 2

Agent drafts per-service rule files + cross-cutting files:

**Per-service (from `services[]` fact sheet):**
- `api.md` (first backend service)
- `web.md` (first frontend service)
- `worker.md` (first worker service — or DELETE if no worker)
- Additional polyglot services → named after service

**Cross-cutting:**
- `security.md` — regenerated with actual auth pattern
- `testing.md` — regenerated with actual test frameworks
- `workflow.md` — preserved (stack-agnostic)
- `figma-conventions.md` — preserved if UX Mode B; deleted otherwise

**Preserved:** `*.local.md` override files (untouched always)

**HALT 2:** Show per-file diffs + summary table. User: `approve / revise / skip / abort`

### Phase 5: IDE Adapter Mirror

Agent mirrors `.claude/rules/*.md` to:
- `.windsurf/rules/*.md` (unless `--ide=` excludes windsurf)
- `.trae/rules/*.md` (unless `--ide=` excludes trae)

Antigravity ใช้ `AGENTS.md` (Phase 3) เป็น primary entry — ไม่ต้อง mirror folder

### Phase 6: Fingerprint + Summary

Agent writes `.claude/stack.json`:
- Schema version
- Timestamp + mode
- TD commit + files + ADRs cited
- Full facts (project, services, database, cross_cutting)
- Output manifest
- IDE targets
- Backups created

Agent presents summary table + source citations + gap warnings + next-step guidance.

**Does NOT auto-commit** — user runs `git commit` when satisfied.

---

## HALT Protocol — Non-negotiable

2-3 HALTs per run:

| HALT | When | User options |
|------|------|--------------|
| **HALT 0** | Fresh mode + CLAUDE.md diverged | `regen` / `merge` / `abort` |
| **HALT 1** | After CLAUDE.md + AGENTS.md draft | `approve` / `revise "<fb>"` / `skip` / `abort` |
| **HALT 2** | After `.claude/rules/*` draft | `approve` / `revise "<fb>"` / `skip` / `abort` |

> ⚠️ **CRITICAL: ห้าม write โดยไม่ได้ user approve**

---

## Coordination with Other Workflows

| Upstream Trigger | Downstream Recommendation |
|------------------|---------------------------|
| `/td-review` approves | User: run `/project-init` |
| `/amend td` changes stack | `/next` recommends `/project-init --regen` |
| `/backtrack td` resolves | `/next` flags `.claude/rules/*` stale; recommend `/project-init --regen` |
| `/project-init` completes | `/next` recommends `/impl-plan 1` |
| Drift detected (via `validate-rules-sync.sh`) | Run `/project-init --regen` |

---

## Gap Handling

Agent's gap policy:

| Gap Level | Example | Behavior |
|-----------|---------|----------|
| **MUST** | Missing project.name, service language, DB engine, auth_flow | Hard-fail — HALT with "add to TD/BA §X.Y" guidance |
| **SHOULD** | Missing test_framework, response_envelope, observability | Warn at HALT 1, allow user to proceed or revise |
| **NICE** | Missing cache, messaging, domain_terms, UX conventions | Silent omission, note in stack.json |

Agent **never invents facts**. If TD is silent → gap report.

---

## Drift Detection

Script: `scripts/validate-rules-sync.sh`

```bash
bash scripts/validate-rules-sync.sh
```

Checks:
1. `.claude/stack.json` exists
2. TD files' last-commit timestamp vs `stack.json.generated_at`
3. ADR files' last-commit timestamp vs `stack.json.generated_at`

**Exit codes:**
- 0 → in sync ✅
- 1 → drift detected ❌ (recommend `/project-init --regen`)
- 2 → no stack.json (recommend `/project-init`)

**CI Integration (optional):** Add to pre-merge check. For MVP, this is opt-in — not mandatory.

---

## Multi-IDE Support

`/project-init` targets 4 IDEs by default:

| IDE | Primary Input | Per-IDE Rules Folder | Notes |
|-----|---------------|----------------------|-------|
| **Claude Code** | `CLAUDE.md` | `.claude/rules/*.md` | Full tier — agents + commands + stack.json |
| **Windsurf** | `CLAUDE.md` | `.windsurf/rules/*.md` | Mirror of `.claude/rules/` |
| **TRAE** | `CLAUDE.md` | `.trae/rules/*.md` | Mirror of `.claude/rules/` |
| **Antigravity** | `AGENTS.md` → `CLAUDE.md` | — (reads root files) | Primary via `AGENTS.md` pointer |

Restrict scope with `--ide=<list>`:
```
/project-init --ide=claude              # Only Claude Code
/project-init --ide=claude,windsurf     # Claude + Windsurf
```

---

## Local Overrides

User can preserve hand-edited rules across regens by suffixing `.local.md`:

```
.claude/rules/api.local.md    ← preserved forever (ignored by generator)
.claude/rules/web.md          ← regenerated each /project-init --regen
```

Agent:
- Catalogues `*.local.md` files in Phase 1
- Lists them as "preserved" in HALT 2 summary
- Records them in `stack.json.local_overrides_preserved`

Recommended practice:
- Use `*.local.md` for **small additive rules** (team-specific conventions, temporary workarounds)
- Use `/project-init --amend` for **structural rule changes** (those should persist across regens)

---

## Common Scenarios

### Scenario 1: Fresh Project after TD Approval

```
1. /td-review all                            → finds findings
2. /td-rebuttal claim-review-01.md           → fixes findings
3. /td-review all                            → approves (no CRITICAL/HIGH)
4. /project-init                             → generates CLAUDE.md + rules + agents + mirrors
5. (review diffs at each HALT, approve)
6. git commit -m "feat(project-init): ..."   → commit generated files
7. /impl-plan 1                              → proceed to Phase 3
```

### Scenario 2: TD Amendment Mid-Sprint

```
1. Sprint 2 discovers need for Redis cache layer
2. /amend td "add Redis + document caching strategy in 02-backend-design.md"
3. /td-review all                            → re-approves TD
4. /project-init --regen                     → rules reflect new cache layer
5. (review diffs, approve)
6. git commit
7. Continue /impl-task
```

### Scenario 3: Targeted Rule Addition

```
Team decides testing bar should be stricter.

1. /project-init --amend "require integration tests for all public endpoints in .claude/rules/testing.md"
2. (review diff, approve)
3. git commit
```

### Scenario 4: Polyglot Stack

```
TD lists: Go API + TypeScript Web + Python ML worker

/project-init generates:
- .claude/rules/api.md           (Go + Fiber/Gin conventions)
- .claude/rules/web.md           (TypeScript + whatever framework)
- .claude/rules/ml-worker.md     (Python + Celery or async)
- CLAUDE.md Tech Stack table lists all 3 services
- Engineer subagents stay generic; they read all 3 rules files at runtime
```

### Scenario 5: Drop a Service

```
Project decides to drop the worker service.

1. /amend td "remove worker service — all async work handled via API background tasks"
2. /td-review all                            → approves
3. /project-init --regen
   - Detects no worker in fact sheet
   - Stages .claude/rules/worker.md for DELETE
4. (review diffs, approve)
5. git commit (note: old worker.md backup preserved as .bak-<ts>)
```

---

## File Layout After Bootstrap

```
<project-root>/
├── CLAUDE.md                              ← project-specific (was template)
├── AGENTS.md                              ← multi-IDE entry point
├── .claude/
│   ├── rules/
│   │   ├── api.md                         ← stack-specific
│   │   ├── web.md                         ← stack-specific
│   │   ├── worker.md                      ← stack-specific (or absent)
│   │   ├── security.md                    ← methodology + stack-specific
│   │   ├── testing.md                     ← methodology + stack-specific
│   │   ├── workflow.md                    ← methodology (preserved)
│   │   ├── figma-conventions.md           ← methodology (kept if Mode B)
│   │   └── *.local.md                     ← user overrides (preserved)
│   ├── agents/                              ← untouched by /project-init (engineer subagents stay generic)
│   ├── commands/                          ← methodology-level (untouched)
│   └── stack.json                         ← fingerprint
├── .windsurf/
│   ├── rules/*.md                         ← mirror of .claude/rules/
│   └── workflows/                         ← methodology-level (untouched)
├── .trae/
│   └── rules/*.md                         ← mirror of .claude/rules/
└── docs/ ...                              ← untouched by /project-init
```

---

## Related Files

- Workflow: `.agents/workflows/project-init.md`
- Skill: `.agents/skills/andm-project-init-engineer/SKILL.md`
- Subagent: `.claude/agents/andm-project-init-engineer.md`
- Command wrapper (Claude Code): `.claude/commands/project-init.md`
- Command wrapper (Windsurf): `.windsurf/workflows/project-init.md`
- Drift validator: `scripts/validate-rules-sync.sh`
- Template source (try in order, use first that exists):
  - `constitution/sample-claude-md-slim.md` (downstream-project layout — methodology extracted to repo root)
  - `methodologies/full-track/constitution/sample-claude-md-slim.md` (template-repo layout — running inside this template repo)

---

## Glossary Lookup

สำหรับ Option C terminology (Evolution Sequence, Phase Hint, Honor/Divergence, etc.) → ดู root `CLAUDE.md § Glossary`.

`/project-init` เป็น **Phase 2.5** — ไม่ใช่ Lifecycle Phase ใหม่ (ยังใช้ 5-Phase model). มันคือ **bridge workflow** เฉพาะจุด.
