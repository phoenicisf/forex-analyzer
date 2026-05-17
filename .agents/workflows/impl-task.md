---
description: Pick a task from the implementation plan, auto-detect size, implement, test, commit, and update handoff. Use `parallel` input to scan for independent ready tasks and HALT for subagent fan-out (Claude Code only).
---

# Workflow: Implement Task

Pick a task from the implementation plan, auto-detect its size, select the appropriate process, implement it with tests, self-review, commit, and update handoff.

Also supports **parallel mode** — input `parallel[ <service|N|ID1,ID2>]` scans impl-plan for independent ready tasks, HALTs with a recommendation, then fans out to multiple `andm-impl-engineer` subagents in one message (Claude Code only).

**Task:** {{input}}

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. `.agents/skills/andm-impl-engineer/SKILL.md` — **your persona definition** (activate the full engineering process defined there)
3. `docs/state/impl-plan.md` — implementation plan with task details
4. `docs/state/overview.md` — current module status
5. Read the relevant handoff file(s) — **load every service the task touches**:
   - Single-layer task (`[api]`/`[web]`/`[worker]`) → read the matching handoff
   - `[slice]` task → read **every** handoff listed in task's "Service scope" field (e.g., slice = api + web → read ทั้ง `docs/state/api/handoff.md` AND `docs/state/web/handoff.md`)
6. Read the relevant `.claude/rules/*.md` — **load rules for every service touched** (slice tasks: multiple rules files)
7. Read the relevant `docs/technical-design/` file(s) — **load every layer the task touches**:
   - API layer: `docs/api-specs/*.yaml`, `02-backend-design.md` (class structure, interfaces, DTOs)
   - Web layer: `03-frontend-design.md` (component tree, state management)
   - DB/migration layer: `04-database-design.md` (column-level schema, indexes)
   - For all: `docs/adr/` (pattern decisions), `docs/qa/01-test-strategy.md` (coverage targets — QA authoritative)
   - **`[slice]` tasks** → load all relevant TD files (typically api-specs + 02 + 03, + 04 ถ้าแตะ DB)

Once read, you are ready to proceed.

---

## Phase 1: Identify Task & Determine Size

### 1.1 Find the Task

Interpret `{{input}}` using the following priority:

**A) Specific Task (default)**
If input is a task ID (e.g., `IMPL-003`) or description → find that exact task in `docs/state/impl-plan.md`.

**B) Resume Mode**
If input is `resume`, `next`, `continue`, or empty → auto-detect the next task:

1. **Read handoff files** — scan all `docs/state/{module}/handoff.md` for:
   - Last completed task (task ID + date)
   - "Next suggested task" field (written by previous session)
   - Known blockers or in-progress work
2. **Read impl-plan** — scan `docs/state/impl-plan.md` for:
   - Tasks with all acceptance criteria `[x]` checked → already done
   - Tasks with some `[x]` but not all → **in-progress** (prioritize resuming these)
   - Tasks with no `[x]` and all dependencies done → **ready to start**
3. **Select next task** using this priority:
   | Priority | Condition | Action |
   |----------|-----------|--------|
   | 1st | Task is **in-progress** (partially checked) | Resume this task |
   | 2nd | Handoff says "next suggested task: IMPL-XXX" | Start IMPL-XXX |
   | 3rd | First **ready** task in dependency order | Start that task |
4. **Report to user** before starting:
   ```
   📋 Resume Analysis:
   - Last completed: IMPL-XXX (by [previous session/agent])
   - In-progress: IMPL-YYY (2/5 acceptance criteria done)
   - Blockers: [none / list]

   → Resuming IMPL-YYY — [task title]
   ```
   Proceed unless user redirects.

**C) No Match**
If no match found → ask the user for clarification.

**D) Parallel Mode (Claude Code only)**
If input starts with `parallel` (e.g., `parallel`, `parallel api`, `parallel 2`) → **skip 1.2/1.4 and jump to Phase 1.5 Parallel Task Recommendation** (see below). Phase 1.3 Phase Gate Compliance still applies — every candidate task in the proposed batch must be in the current open phase; reject any candidate whose phase > current open phase

| Input form | Meaning |
|-----------|---------|
| `parallel` | auto-pick up to 3 independent ready tasks (1 per service by default) |
| `parallel <service>` | scan for ≥2 independent ready tasks within that service (must be different modules/folders) |
| `parallel <N>` | limit to N parallel tasks (2 ≤ N ≤ 3) |
| `parallel <ID1>,<ID2>[,<ID3>]` | user pre-selects the task IDs; workflow verifies independence |

If not running under Claude Code → warn user "parallel mode requires Claude Code (Task tool unavailable); falling back to single-task" → treat input as resume mode (option B).

### 1.2 Load Task Context

Read from the plan:
- **Service scope**: tag (`[api]`/`[web]`/`[worker]`/`[slice]`) + service directories touched (slice tasks list 2+ dirs)
- **Description**: what to build
- **Acceptance Criteria**: definition of done
- **Dependencies**: verify all dependencies are completed (check handoff files for each service touched)
- **Rules**: which `.claude/rules/*.md` to follow (plural for slice tasks)

### 1.3 Phase Gate Compliance Check (BLOCKING)

ก่อน proceed → verify task's phase ≤ current open phase ใน `docs/state/impl-plan.md`:

1. Identify the task's `**Phase:**` field (P0/P1/P2/P3/P4/P5/...)
2. Walk Phase Gate sections in `impl-plan.md` from earliest → latest:
   - The **current open phase** = the earliest phase whose Phase Gate has any `[ ]` row
3. **Block conditions:**
   - Task's phase > current open phase (e.g., task is P2 but P1 still has `[ ]` rows) → **HALT**
   - Reason: ห้ามเริ่ม later-phase work ก่อน earlier phase ปิด gate (ป้องกัน deferred-AC accumulation)
4. **HALT message template:**

```
🛑 PHASE GATE BLOCK

Task `<task-id>` is Phase <X>, but current open phase is <Y>.

Open `[ ]` rows in Phase <Y> Gate:
- [ ] <row text>
- [ ] <row text>

Options:
  (a) Close Phase <Y> Gate first (rehearse Empirical Demo, drain Deferred-AC Registry, resolve CRITICAL/HIGH code-review findings)
  (b) Override with rationale → log entry in `docs/state/impl-plan.md § Phase Gate Override Log`
       (e.g., "Phase Y blocked on vendor X account; proceeding with Phase Y+1 task Z because it's vendor-independent")
  (c) Backtrack to /impl-plan to re-scope phases

ห้าม proceed without explicit user choice — แม้ว่า task จะ urgent
```

5. If user picks (b) → append to override log + proceed; if (a) or (c) → halt this `/impl-task` invocation

> **Override log format** (in `docs/state/impl-plan.md`):
> ```
> ## Phase Gate Override Log
>
> | Date | Task | From Phase | To Phase | Rationale | Approver |
> |---|---|---|---|---|---|
> | YYYY-MM-DD | IMPL-XXX | Y open | Y+1 task | <one sentence> | <user/role> |
> ```

#### 1.3.1 Operator Action Registry Pending Scan

After phase compliance check passes, also read `docs/state/operator-action-registry.md` (if exists):

1. For each row in `## Pending`:
   - Check `Resume task on completion` column = `{{input}}` task ID OR list contains `{{input}}`
2. **HALT if current task depends on Pending operator action:**

```
🛑 OPERATOR ACTION REQUIRED — TASK BLOCKED

Task `<task-id>` is in `Resume task on completion` for <N> Pending operator action(s):
- OPS-XXX · <action verb + object> · opened <YYYY-MM-DD> · how: <link/command>
- ...

Options:
  (a) Operator perform action now → reply "done OPS-XXX" (or edit registry to move row Pending → Done)
  (b) Reassign task — different task ที่ไม่ depend on this action ready ไหม?
  (c) Cancel — defer this task to next session

ห้าม proceed implementing without operator confirmation — Empirical Closure Discipline จะ fail ตอนปิด AC
```

3. If user picks (a) and confirms action done → move registry row to Done section (operator's action took effect; engineer will verify via `[config-audit]` evidence later) → proceed
4. If (b) or (c) → halt this `/impl-task` invocation

#### 1.3.2 Deferred-AC Registry Expiry Scan

After phase compliance check passes, also read `docs/state/deferred-ac-registry.md`:

1. Compute today's date
2. For each row in `## Active`, compare `Expires` against today
3. **HALT if any row's expiry < today:**

```
🛑 DEFERRED-AC EXPIRY HALT

Found <N> expired entries in deferred-ac-registry.md:
- Task <task-id> · E-AC <text> · expired <X days> ago · owner <owner>

Options for each expired row:
  (a) Resolve now — run the empirical step, capture evidence, move row to Resolved
  (b) Renew once — push expiry +14 days max with rationale (max 2 renewals total)
  (c) Escalate — `/impl-plan-review all` to re-decompose the task or remove/adjust the AC (Plan QA owns task decomposition + AC dual-track). If the impossibility traces to upstream design flaw → `/backtrack ba|sd|ux|td` (`/backtrack` does not target impl/impl-plan)

ห้าม start new tasks until expired entries resolved or explicitly renewed
```

4. If user picks renewal → cap at 2 renewals per row; on 3rd attempt force escalate to `/impl-plan-review all` (or upstream `/backtrack` if design flaw)
5. Block proceeds only after all expired rows actioned

#### 1.3.3 Cap-3 Decision Gate (IMPL-FIX-NNN tickets only)

> **Glossary:** `GLOSSARY.md § Cap-3 Decision Gate` + `§ IMPL-FIX Sibling Ban`. Applies only when `{{input}}` is an IMPL-FIX-NNN ticket (regression / parity / behavioral defect repair). Skip for IMPL-NNN main tasks.

After phase + registry checks pass, scan iteration history for the IMPL-FIX ticket:

1. **Sibling-naming check (HARD BLOCK):**
   - If `{{input}}` matches regex `IMPL-FIX-\d+[a-z]` or `IMPL-FIX-\d+-[A-Z]+` (e.g., `IMPL-FIX-011a`, `IMPL-FIX-011-FORCE-PERIOD`) → **HALT**:
     ```
     🛑 IMPL-FIX SIBLING BAN

     Ticket `{{input}}` uses forbidden sibling naming (parent letter/suffix on existing IMPL-FIX-NNN).
     Sibling naming inherits new cap-3 per child → effective cap bypass + audit-trail noise.

     Required action: spawn fresh `IMPL-FIX-MMM` with a NEW ticket number, then close parent
     as `[scope-replaced → MMM]` (not `[x]`).

     Reference: GLOSSARY.md § IMPL-FIX Sibling Ban + § Cap-3 Decision Gate
     ```
     Do not proceed with this ticket ID. Operator must re-spawn under a fresh number.

2. **Iteration count check:**
   - Read `impl-plan.md` `IMPL-FIX-NNN` block + grep commit history `git log --grep="IMPL-FIX-NNN iter-" --pretty=format:"%h %s"` for past iteration closures
   - Count successive **falsified** iterations (commit / handoff mentions "FALSIFIES" / "EMPIRICALLY FALSIFIED" / "regression" / "no reduction")
   - If falsified-count ≥ 3 → **HALT — Cap-3 Decision Gate:**

   ```
   🛑 CAP-3 DECISION GATE — IMPL-FIX-NNN

   Ticket `IMPL-FIX-NNN` has <N> falsified iterations. Cap-3 budget exhausted.
   Empirical signal: current hypothesis space cannot close this defect.

   Iteration trail:
     iter-1: <one-line outcome>
     iter-2: <one-line outcome>
     iter-3: <one-line outcome>

   You MUST select ONE explicit option before any 4th iteration:

   (a) BACKTRACK — problem premise (BA/SD/UX/TD) is wrong
       → run `/backtrack ba` / `/backtrack sd` / `/backtrack ux` / `/backtrack td`
       → full cascade reaches impl; close this IMPL-FIX-NNN as [scope-replaced → BT-NNN]

   (b) Re-decompose — premise valid, decomposition wrong
       → spawn ≥1 fresh `IMPL-FIX-MMM` ticket(s) with new sub-scope
       → close this IMPL-FIX-NNN as [scope-replaced → MMM, OOO, ...]
       → each fresh ticket gets its own cap-3
       → FORBIDDEN: `IMPL-FIX-NNNa/b/c` sibling naming (see step 1)

   (c) Defer / partial close — accept partial scope
       → register row in `deferred-ac-registry.md` (owner + expiry ≤14d + risk-if-missed)
       → operator sign-off required (named approver in closure note)
       → closure note must cite specific deferred ACs verbatim
       → close as [x] partial — NOT silent scope-narrow

   FORBIDDEN: continue to iter-4 without picking one of (a)/(b)/(c).
   ห้าม proceed without explicit user choice.
   ```

3. If operator picks (a) → halt this `/impl-task` invocation; route to `/backtrack`
4. If operator picks (b) → halt; route to `/impl-plan-review` for fresh ticket numbering + plan amendment
5. If operator picks (c) → log deferred-AC row, then closure note in `impl-plan.md` cites the registered row + named approver, then close ticket — exit this `/impl-task` invocation without 4th iteration
6. If iteration count < 3 → continue to 1.4

> **Defect class motivating:** PhoenicisNex IMPL-FIX-011 chain (2026-05) — 5 sibling tickets (`011`, `011a/b/c/d`, `011-FORCE-PERIOD`) × cap-3 each = effective cap-15 + 19 iter + 80 handoff artifacts; closed scope-narrow as "entry-parity-complete, exit-deferred" instead of root-cause fix or backtrack. Gate forces the decision at iter-3 instead of letting it implicit-pivot.

### 1.4 Auto-Detect Size & Select Process

| Size | Scope tag | Detection Criteria | Process |
|------|-----------|--------------------|---------|
| **XS-S** | `[api]` / `[web]` / `[worker]` | Single file/function, no cross-module deps, ≤ 2 acceptance criteria | → Go to Phase 2A (Single Prompt) |
| **M** | `[api]` / `[web]` / `[worker]` | Feature within 1 module, 2-5 files, 3-5 acceptance criteria | → Go to Phase 2B (3-Step) |
| **M** | `[slice]` | Thin vertical cross-layer (DB→API→UI), 3-5 acceptance criteria — **default for user-visible features** | → Go to Phase 2B (3-Step, multi-service variant) |
| **L-XL** | `[api]` / `[web]` / `[worker]` | 6+ files within one service, hard dependencies, 5+ acceptance criteria | → Go to Phase 2C (Per-Layer Exception) |
| **L-XL** | `[slice]` | 🚨 Should not reach engineer — Planner must decompose per §Vertical Slicing Strategy | → STOP & escalate (see Phase 2C guard) |

Announce: "Task IMPL-XXX detected as [SIZE] [scope-tag] → using [process name]"

---

## Phase 1.5: Parallel Task Recommendation (Claude Code only)

> **Activated เฉพาะเมื่อ input = `parallel[...]`** (option D ใน 1.1). Skip ถ้าเข้ามาจาก option A/B/C.
> **Reference:** `.agents/workflows/_parallel-execution-playbook.md` § 2.2 Service-Oriented

### 1.5.1 Scan impl-plan for parallel candidates

Read `docs/state/impl-plan.md` และ build a dependency graph. หา tasks ที่ผ่าน **ทุก** criteria:

1. ✅ **Ready** — dependencies ทั้งหมด done (cross-check กับ `docs/state/{module}/handoff.md`), status ไม่ใช่ `done` หรือ `in-progress`
2. ✅ **Mutually independent** — ไม่มี task ใน candidate set ที่ depend on another task ใน set
3. ✅ **Scope-isolated (file-level non-overlap)** — no two tasks in the batch touch the same file/directory. Typical patterns:
   - Different services (`services/api` vs `services/web`) → usually safe
   - Same service, different module subtree (no shared files) → safe
   - `[slice]` task + any other → verify the slice's file set doesn't overlap with sibling tasks. **Max 1 `[slice]` task per parallel batch** (slice has wider blast radius — be conservative)
4. ✅ **Size XS–M** — L/XL tasks มี HALT ระหว่าง steps (Phase 2C) ไม่เหมาะ unattended parallel — **exclude**
5. ✅ **No security-sensitive overlap** — ไม่ allow 2 tasks ที่แตะ auth/crypto/permission พร้อมกัน (one-at-a-time review policy)
6. ✅ **No shared root-config edits** — ถ้า task ต้องแก้ `.env`, `docker-compose.yml`, root `package.json`, `.claude/rules/*` → **exclude** (orchestrator-only territory)

**Filter input variants:**
- `parallel` (no arg) → pick 1 ready task per service, up to 3 tasks total
- `parallel <service>` → ≥2 within that service, must be different module subtrees
- `parallel <N>` → cap at N (2 ≤ N ≤ 3)
- `parallel <ID1>,<ID2>[,<ID3>]` → user-selected; **verify** independence + scope-isolation, reject with reason if violated

**If no candidate set found** (fewer than 2 eligible tasks) → report: `ไม่พบ parallel candidates — eligible ready tasks: [list]` → offer to fall back to option B (resume mode, single task).

### 1.5.2 Present candidates + HALT

Show the user a table in Thai:

```
🔀 Parallel Task Candidates (<N> tasks รันขนานได้ภายใต้ Claude Code)

| # | Task ID | Service | Size | Description | Files to touch | Risk Note |
|---|---------|---------|------|-------------|----------------|-----------|
| 1 | IMPL-012 | api     | M    | Add profile endpoint | services/api/... (3 files) | none |
| 2 | IMPL-015 | web     | S    | Add profile page | services/web/... (2 files) | none |
| 3 | IMPL-018 | worker  | S    | Profile-sync job | services/worker/... (2 files) | none |

📋 Recommended invocation (Claude Code Task tool — <N> calls ใน ONE message):
- subagent_type: "andm-impl-engineer" ต่อ task
- **model: "sonnet"** — บังคับใช้ Sonnet (4.6) สำหรับ subagent implementation work; orchestrator (main session) ยังคงเป็น Opus เพื่อ scope/decision. เหตุผล: Opus 4.7 1M ช้า (~35 sec/call) + แพง สำหรับ tight edit→test loops; Sonnet 4.6 (~8-12 sec/call) ลด wall-clock ~60% โดยคุณภาพ implementation เพียงพอ ตราบเท่าที่ scope แคบ + shared-context ครบ
- Each Task prompt:
  (a) Task ID + full acceptance criteria จาก impl-plan
  (b) Service scope — SCOPE = service dir(s) ที่ task ระบุใน "Service scope" field (single `services/<name>/` สำหรับ single-layer; หลาย dirs สำหรับ `[slice]` tasks); ห้ามแตะไฟล์นอก scope
  (c) Rules file ที่ต้อง follow (`.claude/rules/<name>.md`)
  (d) Follow SKILL.md Phase 2A/2B (size-based) — implement + write tests + run tests
  (e) **Slim-Onboarding directive:** "Use Slim-Onboarding Fast Path (SKILL.md Phase 0). อ่าน shared-context + CLAUDE.md + impl-plan task entry เท่านั้น ห้ามเปิด TD/ADR/handoff ฉบับเต็มเอง ถ้า excerpt ไม่พอ → STOP + ขอ orchestrator quote เพิ่ม"
  (f) **Test Loop Discipline directive:** "ปฏิบัติตาม SKILL.md § Test Loop Discipline — build ครั้งเดียวต้นรอบ, ใช้ `--no-build --no-restore` + filtered tests ระหว่าง iteration (`--filter ~<TaskKeyword>`), full suite 1 ครั้งก่อนปิดงาน. รายงาน 'Final full-suite run' + 'Filtered iteration count' ใน fragment"
  (g) **Override:** ห้าม git commit, ห้าม update handoff.md, ห้าม mark impl-plan
  (h) Return an `impl-task-fragment` inline (see 1.5.4 schema) — diff summary + test results + known issues
- Shared context: `docs/state/_parallel-context/impl-task-parallel-<YYYYMMDD-HHMM>.md`
  (task IDs, scopes, rules refs, anti-duplication list, **+ Pre-loaded Context section** — see 1.5.3)

⚠️ Race-prevention rules (STRICT):
- Subagent writes **only** inside `services/<its-service>/`
- Orchestrator (you, main session) owns: root configs, shared schemas, cross-service rules, git commits, handoff updates, impl-plan check-offs
- ถ้า subagent พบว่าต้องแก้ไฟล์ root-owned → STOP that task, return fragment with `status: blocked, reason: "needs <file>"` → orchestrator handles serially

⏸️ HALT — ขอ approve เพื่อ spawn parallel subagents?
Choices:
  - `yes` / `go` — proceed with fan-out
  - `no` / `cancel` — abort
  - `run <ID>` — switch to single-task mode on specific ID (go to Phase 1.2)
  - `swap <IDx> <IDy>` — replace candidate IDx with IDy, re-verify, re-show
```

**Do not proceed** until user approves. Present the table and wait.

### 1.5.3 On user approval — fan out

1. **Write shared context file** `docs/state/_parallel-context/impl-task-parallel-<YYYYMMDD-HHMM>.md`:
   - Task IDs + full acceptance criteria copied from impl-plan
   - Per-task SCOPE (service dir) + rules file path
   - Entry criteria (tests baseline, e.g. "npm test currently passes at commit <sha>")
   - Anti-duplication list (previous handoff "next suggested task" hints so agents don't claim overlapping work)
   - **Pre-loaded Context section (REQUIRED — enables Slim-Onboarding):** orchestrator quotes ตรงๆ จาก source docs ที่จำเป็นต่อ task เพื่อ subagent ไม่ต้องเปิด full doc:
     ```
     ## 6. Pre-loaded Context

     ### From docs/technical-design/02-backend-design.md (sections relevant to <task>)
     > <verbatim quote — class signatures, DTOs, interfaces ที่ task ต้องใช้>

     ### From docs/adr/<NNN-...>.md
     > <verbatim quote — decision + rationale + constraints>

     ### From docs/state/<service>/handoff.md (last 1-2 entries)
     > <verbatim quote — recent state + known issues + relevant file paths>

     ### From docs/qa/01-test-execution-plan.md
     > <verbatim quote — coverage targets + mock policy for this feature>
     ```
     **กฎ:** quote เฉพาะ section ที่ relevant (ไม่ใช่ทั้งไฟล์); ถ้า task ไม่แตะ DB → ไม่ต้อง quote 04-database-design.md; ถ้า task เป็น `[api]` ล้วน → ไม่ต้อง quote 03-frontend-design.md
2. **Emit N Task calls in ONE message** using the template in 1.5.2 Recommended invocation. ทุก call ต้องมี `model: "sonnet"`.
3. **Wait for all fragments** to return (or fail).

### 1.5.4 Merge & orchestrator-side completion

Each subagent returns an `impl-task-fragment` block:

```
​```impl-task-fragment
task-id: IMPL-XXX
service: api | web | worker | slice
services-touched: [api, web]   # REQUIRED when service: slice — list every service dir touched
status: completed | blocked | partial
files-changed:
  - <path>: <one-line what changed>
tests-added:
  - <path>: <one-line what covered>
tests-result: pass | fail | not-run
final-full-suite-run: pass | fail | skipped   # REQUIRED — full suite run once before completion
filtered-iteration-count: <N>                 # REQUIRED — number of filtered test runs during iteration
acceptance-criteria-met: [<AC-1>, <AC-2>, ...]
blockers: <none | description>
suggested-next-task: <IMPL-YYY | none>
​```
```

> **`services-touched` validation (slice only):** Orchestrator must verify every path in `files-changed` falls under `services/<x>/` for some `x` in `services-touched`. Any path outside that set = scope violation → treat as `status: blocked` and escalate.

Orchestrator steps (serial, one task at a time):

1. **Review each fragment** — check files-changed is inside the claimed service, tests pass, AC met
2. **Commit per-task** — orchestrator runs `git commit` with contextual format per SKILL.md (separate commit per task so git history stays clean, one commit per service)
3. **Update per-service handoff.md** (Phase 3.2 pattern) for each completed task
4. **Mark impl-plan.md** — check off AC for each completed task
5. **If any `status: blocked`** — handle serially (apply the blocker's required root-config change, then re-run that task in single-task mode)
6. **Mid-sprint code review check** (Phase 3.4) — if ≥3 tasks completed in this parallel batch OR any touched security-sensitive code → recommend `/impl-review all`

### 1.5.5 Report to user

Present a summary in Thai:
- Parallel batch: `<N>` tasks attempted, `<successful>` completed, `<blocked>` rolled back to serial
- Files changed total (across services)
- Tests added total
- Commits created (one per task)
- Per-task next suggestions
- Time savings vs serial estimate (rough: wall-clock ≈ slowest task instead of sum)
- Code review recommendation (if triggered)

### 1.5.6 Fallback

- **Any Task fails/declines** → orchestrator re-runs THAT task serially via Phase 2A/2B/2C (depending on size); other tasks' results still commit normally
- **All N Tasks fail** → abort parallel batch, report event, user re-runs with single-task input
- **User declines HALT** → fall back to option B (resume mode) with top-1 candidate as suggestion

---

## Phase 2A: Single Prompt (XS-S Tasks)

### Execute in one pass:

1. **Read** target files + related files
2. **Implement** the change
3. **Write test** — at minimum one test covering the acceptance criteria
4. **Run test** — verify it passes
5. **Self-review** using the Code Review Checklist from SKILL.md
6. → Go to Phase 3 (Commit & Handoff)

---

## Phase 2B: 3-Step Process (M Tasks)

### Step 1: Plan

List the files to create/modify + approach:
- Which files exist and need modification
- Which files need to be created
- Approach for each file
- Test strategy

Present plan and proceed (no HALT needed for M tasks).

### Step 2: Implement + Test

1. Implement changes file by file
2. Write tests for each significant change
3. Run tests to verify

### Step 3: Self-Review

Run the Code Review Checklist from SKILL.md:
- [ ] Security — No injection, XSS, hardcoded secrets, IDOR?
- [ ] Business Logic — Matches acceptance criteria?
- [ ] Error Handling — All error paths covered?
- [ ] Performance — No N+1, unnecessary loops?
- [ ] Over-engineering — No unnecessary abstractions?
- [ ] Tests — Critical paths covered and passing?
- [ ] Naming — Follows `.claude/rules/` conventions?

If issues found, fix them before proceeding.

→ Go to Phase 3 (Commit & Handoff)

---

## Phase 2C: Per-Layer Decomposition (L-XL Exception)

> ⚠️ **This is the EXCEPTION path.** Default for user-visible L/XL work is **per-slice** decomposition — Planner should have already split the task into `[slice]` sub-tasks (IMPL-010a/010b/010c), each M-sized and routed to Phase 2B. See `andm-impl-planner/SKILL.md § Vertical Slicing Strategy`.
>
> **If you reached here with a raw L/XL cross-layer task, STOP and escalate:**
>
> 1. Present to user: *"Task `IMPL-XXX` is L/XL cross-layer and arrived undecomposed. Per §Vertical Slicing Strategy, Planner should split into `[slice]` sub-tasks before engineer execution."*
> 2. Recommend: `/impl-plan-review all` → Planner / Plan Reviewer re-decomposes the task into thin slices (per §Vertical Slicing Strategy), **or** confirm the per-layer exception applies. (`/backtrack` does not target impl/impl-plan — plan-level concerns route through Plan QA loop)
> 3. **Per-layer exception conditions (all three required):**
>    - ✅ API spec locked — endpoint contracts in `docs/api-specs/*.yaml` frozen + reviewed
>    - ✅ DB migrated — schema landed in a prior `[api]` task; this task does not touch migrations
>    - ✅ Layers integration-independent — each layer builds + tests in isolation without end-to-end glue
> 4. If user confirms exception applies → proceed below. Otherwise await Planner re-decomposition.

### Step 1: Decomposition Plan

Break the task into sub-steps:
```
Step 2: Data Model — models, migrations, entities
Step 3: Data Access — repository/data layer
Step 4: Business Logic — service layer
Step 5: API/UI Layer — controllers, endpoints, components
Step 6: Tests — unit + integration
```

Present plan to user.

**⏸️ HALT — Wait for user approval before proceeding.**

### Step 2-6: Execute One at a Time

For each step:
1. **Announce** — "Executing Step N: [description]"
2. **Fresh Read** — Read target files (may have changed from previous steps)
3. **Implement** — Make changes
4. **Verify** — Run relevant tests
5. **Report** — Show what was done

**⏸️ HALT between steps — Wait for user approval.**

After final step:
- Run full Code Review Checklist from SKILL.md
- Fix any issues found

→ Go to Phase 3 (Commit & Handoff)

---

## Phase 3: Commit & Handoff

### 3.1 Commit

Use contextual micro-commit format:
```
[type:service] short description

Why: detailed explanation of business reason
```

If multiple logical changes were made, create separate commits for each.

### 3.2 State Reconciliation (3-File Propagation — MANDATORY)

> **Why this discipline:** `docs/state/impl-plan.md` is **primary State SoT** (CLAUDE.md § Glossary § State Single Source of Truth). `overview.md` + `{module}/handoff.md` + `_session-handoff/*` are **derived views** that downstream consumers (`/next`, `/impl-task`, `/impl-review`, status agents) read. ห้ามอัปเดตเพียงไฟล์เดียว — drift ทำให้ `/next` รายงานผิด, status agents hallucinate phase complete, parallel `/impl-task` หยิบ task ผิด.

After commit, propagate state to **all 3 layers in this order**:

#### Layer 1 — `docs/state/impl-plan.md` (PRIMARY SoT)

- Tick `[x]` AC checkboxes (with inline note per Gate A/B closure rules from §3.3 below)
- Update Phase Gate row(s) ถ้า task ปิด gate (e.g., last task in phase = check Phase Gate "Empirical Demo executed" row)
- Update Mid-Phase Audit Log counter (+1 to current-phase Tasks Closed Since Last Audit)
- ถ้า defer E-AC → add Active row to `docs/state/deferred-ac-registry.md` (do NOT mark `[x]` with closure note; see Phase 3.3 Gate B)

#### Layer 2 — `docs/state/overview.md` (DERIVED VIEW)

- Update phase status if task closure shifted phase progress (e.g., "P2: 5/12 tasks done" → "P2: 6/12 tasks done")
- Update "Last completed task" pointer to current task ID + date
- ถ้า task ปิด phase gate → flip phase status from "🔄 In Progress" → "✅ Complete"

#### Layer 3 — `docs/state/{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*` (TRANSIENT POINTER + ARTIFACT)

Update `docs/state/{module}/handoff.md` with:
- What was implemented
- Files changed (list paths)
- Tests added
- Known issues or tech debt (if any)
- **Next suggested task** from impl-plan — verify this task ID exists in plan AND is ready (deps done) BEFORE writing the pointer

Save E-AC evidence artifact (per Phase 3.3 Gate B) to `docs/state/_session-handoff/<task-id>-evidence-<YYYYMMDD>.{md,txt,png,...}` if task has E-ACs.

**Handoff Artifact Archive (on ticket close `[x]` or `[scope-replaced]`):**

- ถ้า ticket นี้คือ closure ของ IMPL-NNN / IMPL-FIX-NNN → archive related artifacts:
  ```bash
  # Find all artifacts for ticket (excluding last-14-days hot context)
  find docs/state/_session-handoff/ -maxdepth 1 -name "<ticket>*" -mtime +14 -type f
  # If any found AND ticket has no Active row in deferred-ac-registry.md:
  tar -czf docs/state/_session-handoff/archive/<ticket>.tar.gz \
      docs/state/_session-handoff/<ticket>*
  rm docs/state/_session-handoff/<ticket>*-evidence-* 2>/dev/null  # keep iter files only if archived
  ```
- ห้าม archive artifacts ที่ referenced โดย `deferred-ac-registry.md` Active row (still hot context).
- Update `docs/state/{module}/handoff.md` pointer ให้ reference archive path ถ้า downstream อาจค้นหา
- Reference: `GLOSSARY.md § Handoff Artifact Archive Policy`

**Reconciliation Self-Check (mandatory before commit):**

```
✅ impl-plan.md     — [x] AC + Phase Gate row + audit log updated
✅ overview.md       — task count + last completed pointer updated
✅ handoff.md        — work log + next suggested task updated
✅ _session-handoff/ — evidence artifact saved (if E-AC) at <path>
```

ถ้าข้อใดข้อหนึ่ง ❌ — STOP, fix ก่อน commit. ห้ามปล่อย drift.

> **Reference:** CLAUDE.md § Glossary § State Reconciliation Discipline + sample-claude-md-slim.md § 6 Agent Workflow Rules

### 3.3 Mark Task Complete (3 Closure Gates — ALL must pass)

Mark task `{{input}}` complete in `docs/state/impl-plan.md` **only if** all three gates below pass. ปิดด้วย `[x]` + completion date — ห้าม mark complete พร้อมโน้ตว่า "deferred" ใน AC ใดๆ

#### Gate A — Structural ACs

For every S-AC:
- [ ] Test/build/typecheck/lint command run + result count cited in handoff
- [ ] Result is repeatable (test command + flags listed so reviewer can re-run identically)
- [ ] AC checkbox `[x]` ใน `impl-plan.md` มี inline note ที่ระบุ test file + assertion count

#### Gate B — Empirical ACs

For every E-AC (per `[evidence-kind]` declared in impl-plan):
- [ ] Bootstrap deployable per project's run/deploy contract
- [ ] Run the evidence-kind procedure from `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` — pick the correct Kind A-G checklist for the surface this task touches
- [ ] Evidence artifact saved at `docs/state/_session-handoff/<task-id>-evidence-<YYYYMMDD>.{md,txt,png,...}`
- [ ] AC checkbox `[x]` ใน `impl-plan.md` cites the artifact path

If E-AC genuinely cannot be exercised right now (vendor account pending, hardware unavailable, upstream dep blocking) — **DO NOT mark `[x]`**. Instead:
- Open follow-up task `<TASK-ID>-followup-empirical` ใน `impl-plan.md` with the E-AC text verbatim
- Mark current task **BLOCKED** in impl-plan (not `[x]`)
- Add entry to `docs/state/deferred-ac-registry.md` (see §Deferred-AC Registry — owner + expiry ≤14 days + risk-if-missed)
- Re-attempt closure when followup unblocks

**Forbidden:** marking AC `[x]` with closure note "deferred to operator-runtime" / "deferred to post-launch operator phase" / "deferred per <other-task> precedent" — these are explicit Code Review Dimension #11 CRITICAL findings (see `impl-review.md`)

#### Gate C — Self-review checklist

Run the Code Review Checklist from `andm-impl-engineer/SKILL.md § Self-Review`. All items pass; any flagged issue resolved before proceeding.

### 3.4 Mid-Sprint Code Review Check (Optional)

Evaluate whether a mid-sprint code review is warranted:

| Trigger Condition | Action |
|-------------------|--------|
| Task was **L-XL** size | **Recommend** `/impl-review {service}` |
| Task touched **security-sensitive** code (auth, crypto, data access) | **Recommend** `/impl-review {service}` |
| **3+ tasks** completed since last code review | **Recommend** `/impl-review all` |
| Task was **XS-M** and no security-sensitive changes | Skip — review at sprint end |

If recommending a review, include it in the report (3.5) as a suggestion, not a blocker. The user decides whether to run it now or defer to sprint end.

### 3.5 Report to User

Present a concise summary in Thai:
- Task ID and title
- Size detected and process used
- Files created/modified (count)
- Tests added (count)
- Commit message(s)
- Path to updated handoff file
- Recommended next task: `/impl-task IMPL-XXX`
- *(if applicable)* Code review recommendation with reason
- *(if applicable)* Mid-Phase Empirical Audit recommendation (see Phase 4)

---

## Phase 4: Mid-Phase Empirical Audit (Auto-trigger every 5 closed tasks per phase)

> **Defect class motivating this phase:** "Deferred-AC drift" accumulation. Real-project signal (Shark CMS, 2026-04): 53 closed tasks across two phases before first cold-bootstrap audit ran → 11 IMPL-FIX-* recovery tasks + 71% defect rate in deferred-AC pool. Fail-fast checkpoint at 5-task interval catches drift before it accumulates.

### 4.1 Counter

Maintain a per-phase counter in `docs/state/impl-plan.md § Mid-Phase Audit Log`:

```
## Mid-Phase Audit Log

| Phase | Tasks Closed Since Last Audit | Last Audit Date | Last Audit Result | Next Audit Due At |
|---|---|---|---|---|
| P1 | 3 | 2026-04-25 | ✅ Green | 5 closes after 2026-04-25 |
| P2 | 0 | — | — | First close in P2 + 5 |
```

After each successful Phase 3 closure → increment current-phase counter. When counter ≥ 5 → trigger Phase 4 audit before proceeding to next task.

### 4.2 Audit Procedure

When triggered:

1. **Announce HALT:**
   ```
   📋 Mid-Phase Empirical Audit Triggered
   Phase <X> has had 5 closures since last audit. Running cold-bootstrap audit before next task.
   ```

2. **Cold bootstrap** — tear down all stateful components per project's deploy contract; bring up fresh from zero state per `.claude/rules/workflow.md` deploy procedure (commands materialized from `.claude/stack.json`)

3. **Run smoke chain** — execute the project's smoke spec (location declared in `.claude/rules/testing.md`; default `tests/e2e/smoke.*` materialized by `/project-init`)

4. **Replay E-AC artifacts** — for each task closed since last audit (read `Mid-Phase Audit Log`):
   - Open the evidence artifact at `docs/state/_session-handoff/<task-id>-evidence-*`
   - Re-run the evidence-kind procedure (probe / capture / inspect / boot-cold) against the freshly-bootstrapped stack
   - Pass = artifact reproduces against current state; Fail = artifact no longer matches

5. **Classify any failure:**

| Failure mode | Route |
|---|---|
| Smoke spec fails on cold bootstrap | Open `IMPL-FIX-XXX [api+ops]` — infra/bootstrap defect |
| E-AC artifact no longer reproduces | Open `IMPL-FIX-XXX` — regression introduced since closure; route to last task that touched the affected surface |
| Test asserts no longer match (test-side bug) | Route to QA — `/qa-execute-fix` |
| Environment-side issue (network, vendor outage) | Defer with timestamp; do not advance counter; retry within 1 hour |

6. **Block next task** until all opened IMPL-FIX-* tasks closed via normal `/impl-task` flow

### 4.3 Update Audit Log

After audit completes:
- Reset current-phase counter to 0
- Record `Last Audit Date` + `Last Audit Result` (✅ Green / ❌ <count> fixes opened)
- Update `Next Audit Due At` = "5 closes after <today>"

### 4.4 Phase Gate Inheritance

Mid-Phase Audit complements (does not replace) Phase Gate. The Phase Gate at end-of-phase still requires:
- Empirical Demo executed
- Live-stack health green
- Deferred-AC Registry drained
- All Mid-Phase Audit fix tasks resolved

If a Phase Gate is encountered before counter reaches 5 → run final Phase Gate audit instead (broader scope: full Empirical Demo, not just smoke + replay)

### 4.5 Stack-Agnostic Note

ทุก concrete command (teardown / bootstrap / smoke) อ่านจาก `.claude/stack.json` + `.claude/rules/workflow.md` + `.claude/rules/testing.md` — materialized by `/project-init`. Audit procedure ใน workflow นี้ไม่ assume tool ใดๆ — เป็น sequence ของ steps ที่แต่ละ step อ้าง project-specific contract
