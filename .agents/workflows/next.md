---
description: Auto-detect current development phase and recommend next action
---

# Workflow: What's Next?

Scan the project state and recommend the next action to take.

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files before doing anything else:

1. `CLAUDE.md` — project rules (REQUIRED)
2. `docs/state/overview.md` — module status (**OPTIONAL** — skip silently if not found, do NOT report as error)
3. `docs/state/backtrack-log.md` — open backtrack entries (**OPTIONAL** — skip silently if not found, do NOT report as error)
4. `docs/state/amendment-log.md` — open amendment obligations (**OPTIONAL** — skip silently if not found, do NOT report as error)

> **Important:** Files #2-#4 are seeded later in the lifecycle (overview.md by BA/SD phase, backtrack-log.md by `/backtrack`, amendment-log.md by `/amend` T3/T4). On fresh projects or projects in early Design phase, these files will not exist — that is normal. Just proceed to Phase 1 without them. Do NOT halt with a "file not found" error.

Once read (or skipped), proceed to Pre-check 0.

---

## Pre-check 0: Unresolved Breakage Override (User Signal + State Memory)

> **Why this comes first:** workflow scan ปกติจะ recommend "next task per phase progression" — แต่ถ้า **functional breakage** ค้างอยู่ (จาก user signal turn นี้ หรือจาก state file ที่ session ก่อนทิ้งไว้), recommendation phase progression นั้นคือคำตอบผิด. Breakage = ground truth, override workflow logic. ดู `_core-behaviors.md § 7 Contemporary User Signal Priority`.
>
> **Critical insight (review-from-gpt2 finding):** session ใหม่บางวัน user แค่พิมพ์ `/next` เปล่าๆ — ถ้าเรา scan แค่ turn ปัจจุบันจะพลาด breakage ที่ session ก่อน register ไว้ใน state files. Pre-check 0 ต้อง scan **ทั้ง user message + state memory** เพื่อ detect unresolved breakage รอบครบ.

### A. Scan current user input + recent conversation context

Detect breakage signals in this turn:

- "ใช้ไม่ได้", "พัง", "broken", "ไม่ทำงาน", "doesn't work"
- "ทำไม X ไม่ X" (questioning a previously-claimed-done feature)
- Reports of HTTP 5xx / blank screens / failed login / locale switcher no-op / form rejection
- Reports of env var / config / migration applied but not taking effect
- "อยากเห็น X ก่อน [DevOps / security / next phase]" — operator wants to verify before progression

### B. Scan state-file memory (parallel reads — silently skip files that don't exist)

Detect unresolved breakage that previous sessions registered:

1. **Latest handoff** (`docs/state/{module}/handoff.md` or `docs/state/current_handoff.md`):
   - Section "Known issues" / "Tech debt" / "Blockers" with non-empty entries
   - "Next suggested task" pointing at IMPL-FIX-* (signal that previous session left fix work undone)
2. **Latest exploratory walk artifact** (`docs/state/_session-handoff/*-phase*-exploratory-walk.md`):
   - "Findings" section with CRITICAL severity rows whose linked IMPL-FIX-* still `[ ]` in impl-plan
3. **Open IMPL-FIX-* tickets** in `docs/state/impl-plan.md`:
   - Grep for `IMPL-FIX-` task IDs whose AC checkboxes still `[ ]`
4. **Deferred-AC Registry** (`docs/state/deferred-ac-registry.md`):
   - Any Active row with `Expires` < today (expired but not resolved)
   - Any Active row with `Risk if missed` = HIGH/CRITICAL
5. **Operator Action Registry** (`docs/state/operator-action-registry.md`):
   - Any Pending row older than 3 days (stale operator backlog)
6. **Latest code review** (`docs/code-review/review-round-XX.md`):
   - CRITICAL findings ที่ยังไม่มี matching `fix-round-XX.md` หรือ fix-round บอกว่ายัง pending

### C. Override decision

**If A or B detect unresolved breakage:**

```
🛑 BREAKAGE OVERRIDE — bypassing workflow scan

Source(s):
  - [User signal this turn]: <quote if applicable>
  - [State memory]: <list specific findings with file paths, e.g., "walk artifact 2026-04-29 has CRITICAL F-11.18 News.content drop, IMPL-FIX-018 still [ ]">

แทนที่จะ scan workflow + recommend next phase task, recommend triage-first:

1. **If reproducible immediately** — `/impl-task IMPL-FIX-XXX` (or open new IMPL-FIX if not yet ticketed)
2. **If state-only signal (e.g., expired Deferred-AC, stale OPS row)** — recommend resolving the registry entry first:
   - Expired Deferred-AC → resolve E-AC now, renew per registry policy (max 2 renewals × 14d), or route through `/impl-plan-review all` if the AC/task decomposition appears invalid (Plan QA loop fixes plan-level concerns). If upstream design is the actual root cause → `/backtrack ba|sd|ux|td` (`/backtrack` does not target impl/impl-plan)
   - Stale Operator Action → operator do action or remove stale row
3. **If defect ใน phase ที่ปิด Tier 2 ไปแล้ว** — question Phase Gate closure + recommend Tier 1.5 Walk re-run + open `IMPL-FIX-*` ticket. If task decomposition / Phase Gate criteria ผิด → `/impl-plan-review all`. If upstream design is root cause → `/backtrack ba|sd|ux|td` (NOT `/backtrack impl` — that target is unsupported)
4. **If reproduce ไม่ได้** (user signal but state silent, OR state signal but cannot reproduce) — ขอ steps + screenshot/log capture จาก user; do NOT progress

ห้าม return phase progression recommendation จนกว่า triage round จบ + breakage signal ถูก resolved หรือ explicitly accepted
```
→ **STOP — Report to user (override path engaged; scan logic skipped)**

**If no breakage signal in either A or B:**
→ Proceed to Phase 1

---

## Phase 1: Detect Current Phase

Scan the project directories in this order. Stop at the **first gap** found:

### Check 0: Open Backtracks
```
Check: docs/state/backtrack-log.md exists?
If yes: scan for entries with Status: 🔄 Open
```

**If open backtrack exists:**
```
Phase: ⚠️ Backtrack In Progress
Status: มี backtrack ค้าง — BT-[NNN]: [title]
  Target Phase: [phase]
  Impacted: [list of invalidated phases]
Next Action: แก้ไข [target phase] deliverables ให้เสร็จ แล้ว re-validate downstream
  → ดู docs/state/backtrack-log.md สำหรับรายละเอียด
  → ดู .agents/development-guide/backtrack-workflow.md สำหรับ process
```
→ **STOP — Report to user (backtrack ต้องจัดการก่อนทำอย่างอื่น)**

**Also check `docs/state/overview.md` for invalidated phases:**
```
If any phase has ❌ Invalidated or ⚠️ Pending re-validation markers:
  → Report these in the status table
  → Recommend re-running/re-validating those phases after backtrack rework is done
```

### Check 0.5: Open Amendment Obligations

> **Why this check exists:** T3/T4 amendments via `/amend` create downstream obligations (e.g., `/amend ba` adding US-019 → must `/amend sd` to update Traceability Matrix + `/ba-review all` to re-validate). `docs/state/amendment-log.md` is the **persistent ledger** for these obligations — Step 5 chat report dies with the session, but `/next` ต้อง surface backlog ทุก session ก่อน recommend phase progression. Same priority pattern as Open Backtracks.
>
> Reference: Glossary "Amendment Log" + `andm-amend-engineer/SKILL.md § Step 5.5`

```
Read: docs/state/amendment-log.md (silently skip if not exists)

Scan: entries with `Status: 🔄 Open`
For each open entry:
  - Count unchecked obligation rows (- [ ] lines under "Downstream obligations:")
  - Compute age: today - Date
  - Note Tier (T3/T4) + Source phase + Files modified
  - Read "Blocks:" list — commands that should not run until obligations close

Detect drift signals:
  - All obligation rows [x] but Status ลังไม่ ✅ Closed → flag for closure (advisory)
  - Status ✅ Closed but ≥1 obligation [ ] → contradiction (advisory; do not block)
  - Open entry age > 30 days + same project → recommend reconsidering scope (maybe should have been /backtrack)
```

**If open AMEND entries exist (any with ≥1 unchecked obligation):**
```
⚠️ Open Amendment Obligations

มี <N> AMEND entries with downstream obligations open:

  - AMEND-XXX (T<3|4>, <BA|SD|UX|TD>, age <X> days): "<short title>"
    Open obligations:
      - [ ] /amend <next-phase> "<follow-up>"
      - [ ] /<phase>-review all
      - [ ] /impl-plan-review all  (if applicable)
    Blocks: /impl-plan, /impl-task, /red-team, /deliver

Status: 🟡 Phase progression blocked — downstream content stale relative to amendment scope
```

**Picking THE primary recommendation when multiple AMEND entries are open (deterministic tie-breaker):**

> Navigation Decision Layer §1.9 must emit ONE primary action. If `amendment-log.md` has >1 open entry, apply the tie-breaker below in order — first rule that produces a unique winner wins:
>
> 1. **Blocks-current-phase first** — entry whose `Blocks:` list includes the command `/next` would otherwise have recommended (e.g., `/impl-task` if Phase 3 is active) wins over entries that block only later phases
> 2. **Oldest entry first** — earlier `Date:` field wins (longest-stale obligation has highest cumulative drift risk)
> 3. **T4 over T3** — architectural amendments cascade more broadly than cross-phase ones
> 4. **Source phase upstream-most** — BA > SD > UX > TD (BA-side obligations gate everything downstream)
>
> **Within a single chosen entry**, always pick the **earliest unchecked obligation** in dependency order (BA → SD → UX → TD; same-phase amend before review; review last). Never recommend skipping middle obligations.

```
Next Action:
  1. Run THE primary obligation (per tie-breaker above) → typically `/amend <next-phase>` or `/<phase>-review all`
  2. หรือ explicit accept staleness — mark obligation rows [x] manually + change entry Status: ✅ Closed + add Closed: date (audit trail required)
  3. หรือ /backtrack <ba|sd|ux|td> ถ้า amendment scope จริงๆใหญ่กว่าที่ classified — convert to backtrack ผ่าน invalidation matrix (`/backtrack` does not target impl/impl-plan)
  → Reference: Glossary "Amendment Log" + Tier Floor Rules
```
→ **STOP — Report to user** (open AMEND obligations are blockers same priority as backtrack)

**If amendment-log absent OR no Open entries:**
→ Proceed to Check 0.7

### Check 0.7: Backtrack/Overview Reconciliation (Drift Detection)

> **Why this check exists:** `/backtrack` updates both `backtrack-log.md` (Status field) + `overview.md` (markers like 🔄 BACKTRACK / ⚠️ Pending re-validation / ❌ Invalidated). Manual edits ที่ปิดอันใดอันหนึ่งโดยไม่ปิดอีกฝั่ง สร้าง drift — overview marks something invalidated indefinitely แต่ backtrack-log Closed เรียบร้อย, หรือ backtrack open แต่ overview ไม่ flag. Drift confuses `/next` priority detection.

```
Read: docs/state/backtrack-log.md
  - Extract: BT-NNN entries + Status (🔄 Open / ✅ Closed)
Read: docs/state/overview.md
  - Grep markers ที่ reference BT-NNN: "🔄 BACKTRACK", "⚠️ Pending re-validation (BT-", "❌ Invalidated (BT-"

Drift checks:
  Direction A (orphan markers): overview มี marker reference BT-NNN, but BT-NNN.Status = ✅ Closed
  Direction B (missing markers): backtrack-log มี BT-NNN.Status = 🔄 Open, but overview ไม่มี marker reference BT-NNN
```

**If drift detected (advisory — does not block):**
```
⚠️ Backtrack/Overview State Drift

Drift type:
  - Direction A (stale markers — N occurrences): <list overview markers ที่ reference closed BT>
    Effect: overview reports phases as invalidated even ที่ rework done — may confuse status reporting
  - Direction B (missing markers — N occurrences): <list open BT-NNN ที่ overview ไม่มี marker>
    Effect: overview hides active backtrack — downstream re-validation may proceed silently

Status: 🟡 Drift muddies backtrack signal — recommend reconcile but does not block /next priority decision
Recommended cleanup:
  Direction A → ลบ stale markers จาก overview.md (closed BT-NNN should not retain Invalidated markers)
  Direction B → เพิ่ม markers ตาม Invalidation Matrix ของ open BT-NNN (ดู `.agents/development-guide/backtrack-workflow.md`)
```
→ **Report to user (advisory — does NOT block; continue to Check 1)**

**If no drift:**
→ Proceed to Check 1

### Check 1: BA Deliverables
```
Glob: docs/ba/*.md
Expected: 5 files (01-project-brief.md through 05-user-flows.md; v1.2: 06-handoff dropped)
```

**If missing or incomplete:**
```
Phase: Design (BA)
Status: BA deliverables ไม่ครบ
Next Action: /ba           — รัน BA requirements discovery (workflow auto-loads prompt + inputs)
  → หรือถ้าต้องการ focus เฉพาะส่วน: /ba "<focus hint>"
  → underlying prompt: .agents/prompt-templates/ba-requirements-prompt.md (workflow ใช้ตัวนี้เป็น authoritative)
```
→ **STOP — Report to user**

### Check 2: System Design Deliverables
```
Glob: docs/design-docs/*.md
Expected: 6 files (02-high-level-architecture.md through 08-product-breakdown.md; v1.2: gaps ที่ 01, 06 — merged into 02)
Also check: docs/adr/*.md (at least 1), docs/api-specs/*.yaml (at least 1)
```

**If missing or incomplete:**
```
Phase: Design (SD)
Status: Design docs ไม่ครบ
Next Action: /sd           — รัน System Design (workflow auto-loads prompt + BA deliverables)
  → หรือถ้าต้องการ focus: /sd "<focus hint>"
  → underlying prompt: .agents/prompt-templates/system-design-master-prompt.md (workflow ใช้ตัวนี้เป็น authoritative)
```
→ **STOP — Report to user**

### Check 3: Design QA — BA Review
```
Glob: docs/ba/claim-review-and-rebuttal/*.md
Check: มี claim-review file หรือยัง? ถ้ามี — check ว่ามี rebuttal คู่กันไหม?
       อ่าน round ล่าสุด — ยังมี CRITICAL/HIGH ค้างไหม?
```

**If no reviews yet:**
```
Phase: Design QA (BA)
Status: ยังไม่ได้ตรวจ BA docs
Next Action: /ba-review all
```

**If has reviews but CRITICAL/HIGH pending:**
```
Phase: Design QA (BA Rebuttal)
Status: มี findings ค้าง [N] CRITICAL, [N] HIGH
Next Action: /ba-rebuttal docs/ba/claim-review-and-rebuttal/claim-review-XX.md
```
→ **STOP — Report to user**

### Check 4: Design QA — SD Review
```
Glob: docs/design-docs/claim-review-and-rebuttal/*.md
Same logic as Check 3 but for design docs
```

**If no reviews yet:**
```
Phase: Design QA (SD)
Status: ยังไม่ได้ตรวจ design docs
Next Action: /sd-review all
```

**If has reviews but CRITICAL/HIGH pending:**
```
Phase: Design QA (SD Rebuttal)
Status: มี findings ค้าง
Next Action: /sd-rebuttal docs/design-docs/claim-review-and-rebuttal/claim-review-XX.md
```
→ **STOP — Report to user**

### Check 4.5: UX/UI Design Deliverables
```
Glob: docs/ux/*.md
Expected: 5 files (01-design-tokens.md through 05-interaction-patterns.md); UX-06 was dropped in SD-as-Master consolidation
```

**If missing or incomplete:**
```
Phase: Design (UX/UI)
Status: UX/UI deliverables ไม่ครบ
Next Action: ใช้ workflow สร้าง UX deliverables
  → /ux-design auto (หรือ stitch / figma / existing / reference / frontend / claude-design)
  → ดู .agents/development-guide/ux-design-workflow.md
```
→ **STOP — Report to user**

**If exists but not yet approved (no approval marker in docs/state/overview.md):**
```
Phase: Design QA (UX Review)
Status: UX deliverables สร้างแล้ว แต่ยังไม่ approved
Next Action: /ux-review
```
→ **STOP — Report to user**

### Check 4.7: Technical Design Deliverables
```
Glob: docs/technical-design/*.md
Expected: 3 files (02-backend-design.md, 03-frontend-design.md, 04-database-design.md) — SD-as-Master: TD-01/05/06/07/08 dropped
```

**If missing or incomplete:**
```
Phase: Design (TD)
Status: Technical Design deliverables ไม่ครบ
Next Action: /td           — รัน Technical Design (workflow auto-loads prompt + SD/UX/ADR/api-specs)
  → หรือถ้าต้องการ focus: /td "<focus hint>" (เช่น "frontend only — no DB changes")
  → underlying prompt: .agents/prompt-templates/technical-design-master-prompt.md (workflow ใช้ตัวนี้เป็น authoritative + enforces SD-as-Master scope contract)
  → ดู .agents/development-guide/td-workflow.md
```
→ **STOP — Report to user**

### Check 4.8: Design QA — TD Review
```
Glob: docs/technical-design/claim-review-and-rebuttal/*.md
Check: มี claim-review file หรือยัง? ถ้ามี — check ว่ามี rebuttal คู่กันไหม?
       อ่าน round ล่าสุด — ยังมี CRITICAL/HIGH ค้างไหม?
```

**If no reviews yet:**
```
Phase: Design QA (TD)
Status: ยังไม่ได้ตรวจ Technical Design docs
Next Action: /td-review all
```

**If has reviews but CRITICAL/HIGH pending:**
```
Phase: Design QA (TD Rebuttal)
Status: มี findings ค้าง
Next Action: /td-rebuttal docs/technical-design/claim-review-and-rebuttal/claim-review-XX.md
```
→ **STOP — Report to user**

### Check 4.9: Project Bootstrap (Phase 2.5)

```
Check: .claude/stack.json exists?
       If yes: compare stack.json.generated_at vs git-log latest commit of
               docs/technical-design/02/03/04 + docs/adr/*.md
       If any TD/ADR committed after generated_at → stale
```

**If `.claude/stack.json` missing + TD approved (no CRITICAL/HIGH in latest TD rebuttal):**
```
Phase: Bootstrap (Phase 2.5)
Status: TD approved แต่ยังไม่ได้ bootstrap project rules
Next Action: /project-init
  → Derive CLAUDE.md + .claude/rules/* จาก TD
  → 2-3 HALT protocol (HALT 0 conditional + HALTs 1-2 mandatory) — user approve per output group
  → ดู .agents/development-guide/project-init-workflow.md
```
→ **STOP — Report to user**

**If `.claude/stack.json` exists + TD or ADRs committed after `generated_at`:**
```
Phase: Bootstrap Regen (Phase 2.5)
Status: TD/ADR เปลี่ยนหลังจาก last /project-init run — rules อาจ stale
Next Action: /project-init --regen
  → Backup existing rules → regen from latest TD
  → ดู scripts/validate-rules-sync.sh สำหรับ drift check
```
→ **STOP — Report to user**

**If `.claude/stack.json` in sync → proceed to Check 5.**

### Check 5: Implementation Plan (Phase 3 Gate)
```
Check: docs/state/impl-plan.md exists?
```

**If missing:**
```
Phase: Implement (Planning)
Status: ยังไม่มี implementation plan
Next Action: /impl-plan 1
Note: impl-plan เป็น blocker — ต้องสร้างก่อน QA จะ sync task IDs ได้
```
→ **STOP — Report to user**

### Check 5.25: Implementation Plan QA (Plan Review/Rebuttal)
```
Glob: docs/state/impl-plan-claim-review-and-rebuttal/*.md
Check: มี claim-review file หรือยัง? ถ้ามี — มี rebuttal คู่กันไหม?
       อ่าน round ล่าสุด — ยังมี CRITICAL/HIGH ค้างไหม?
```

> **Why this check exists:** real-project audit (Shark CMS, 2026-04) ran `/impl-plan` once with no review pair → 9 functional defects + 11 IMPL-FIX-* recovery tasks across two phases. This check enforces the same review/rebuttal pair pattern that BA/SD/UX/TD already use.

**If no plan reviews yet:**
```
Phase: Implement (Plan Review)
Status: Plan สร้างแล้ว ยังไม่ได้ตรวจ — ห้าม start `/impl-task` ก่อน plan ผ่าน review
Next Action: /impl-plan-review all
```
→ **STOP — Report to user**

**If has reviews but CRITICAL/HIGH pending:**
```
Phase: Implement (Plan Rebuttal)
Status: มี plan review findings ค้าง [N] CRITICAL, [N] HIGH
Next Action: /impl-plan-rebuttal docs/state/impl-plan-claim-review-and-rebuttal/claim-review-XX.md
```
→ **STOP — Report to user**

### Check 5.5: State Reconciliation (Single-Source-of-Truth Discipline)

> **Why this check exists:** Plan + overview + registry + handoff drift silently → `/next` recommends wrong task, `/impl-task` picks stale next-pointer, status agents hallucinate phase complete. This check catches drift before it propagates.

```
Read in parallel:
  - docs/state/impl-plan.md      (primary SoT)
  - docs/state/overview.md       (derived view)
  - docs/state/deferred-ac-registry.md  (deferred E-AC primary SoT — if exists)
  - latest entry from docs/state/{module}/handoff.md (or current_handoff.md)

Verify (3 reconciliation rules):

A. impl-plan ↔ overview
   - ทุก phase status ใน overview match impl-plan Phase Gate state ไหม?
   - Total task count ใน overview match plan?
   - "Last completed task" ใน overview match latest [x] in impl-plan?

B. impl-plan ↔ deferred-ac-registry (if registry exists)
   - ทุก Active row → task ID exists ใน plan ไหม?
   - ทุก [x] AC ใน plan ที่มี closure note "deferred" → registry มี Resolved row ไหม?
     (no Resolved row = forbidden pattern — see Check 6 forbidden patterns)

C. impl-plan ↔ handoff
   - "Next suggested task" pointer ใน handoff → task ID exists + ready (deps done) ใน plan?
   - Evidence artifact paths cited ใน [x] ACs → ไฟล์ exists ใน _session-handoff/?
```

**If any divergence found:**
```
⚠️ State Reconciliation Drift Detected

Drift type: [A: overview / B: registry / C: handoff]
Details:
  - <specific divergence — e.g., "overview reports P2 done but impl-plan has 3 [ ] tasks in P2">
  - <...>

Status: 🔴 State drift blocks reliable next-task recommendation
Next Action: 
  Option (a) Reconcile manually — open ไฟล์ที่ drift แล้วซิงค์ตาม impl-plan.md (primary SoT)
  Option (b) Re-run last impl-plan rebuttal cycle — `/impl-plan-review all` → fix → reconcile
  Option (c) Skip and proceed at user's risk — report what `/next` would recommend BUT flag drift
```
→ **STOP — Report to user** (drift must be resolved before reliable phase 3 navigation)

**If no divergence:**
→ Proceed to Check 5.7

### Check 5.7: Operator Action Registry (Pending Backlog)

> **Why this check exists:** UIR (User Input Required) halts in `/impl-task` register Pending operator actions ที่ engineer ต้องการให้คนทำให้ — set env var / get API key / accept ToS / configure SaaS dashboard. ถ้า operator ไม่ทำ → linked tasks block. `/next` ต้อง surface backlog ให้ operator เห็นก่อนนำเสนอ next task.

```
Read: docs/state/operator-action-registry.md (if exists — silently skip if missing)

Scan ## Pending table:
  - Count rows
  - For each row, note: action + how-to-do-it link/command + Resume task on completion
  - Compute age: today - Opened
  - Flag stale: age > 3 days = ⚠️ (operator backlog growing)
```

**If Pending table non-empty:**
```
⚠️ Operator Action Backlog

มี <N> pending operator actions ที่ block downstream tasks:

  - OPS-XXX · <action verb + object> · age <X days> · resume: IMPL-XXX
    How: <link/command>
  - ...

Status: 🟡 Plan executable แต่หลาย task ที่ depend on these actions block
Next Action:
  - Operator perform actions ทีละข้อ → reply "done OPS-XXX" หรือ edit registry
  - หรือ /impl-task <other-task-id> ที่ไม่ depend on Pending OPS
  - หรือ /impl-plan-review all ถ้า OPS เก่ามาก (>14d) — re-validate plan; tasks อาจไม่ relevant แล้ว (`/backtrack` รับเฉพาะ ba/sd/ux/td — plan-level concerns route ผ่าน Plan QA loop)
```
→ **STOP — Report to user** (operator decides whether to clear backlog now or pivot)

**If Pending empty:**
→ Proceed to Check 5.8

### Check 5.8: Plan Staleness Sentinel

> **Why this check exists:** plan ที่ approved ไว้นานแล้ว + ทำงานต่อเนื่องเป็นสิบ tasks มัก drift จาก reality (scope shift, dependency change, risk re-prioritized) แต่ไม่มีกลไก trigger re-review. ผลคือ engineer ทำตาม plan เก่าที่ไม่ตรงกับ situation จริง. Sentinel นี้ surface ว่า "plan อาจเก่าแล้ว ลองรัน /impl-plan-review ใหม่ก่อน continue"

```
Read: docs/state/impl-plan.md frontmatter
  - Extract: Date field (sprint approval date)
  - Compute: age_days = today - Date

Read: docs/state/impl-plan-claim-review-and-rebuttal/ (latest claim-review-XX.md)
  - If exists: extract last review Date
  - Compute: tasks_closed_since_review = count [x] tasks with closure date > last review Date

Triggers (any one fires):
  - age_days > 30 AND no claim-review-*.md exists yet
  - age_days > 30 AND tasks_closed_since_review > 10
  - impl-plan.md edited since last review Date (file mtime > last claim-review-XX.md Date — direct edits to add Phase Gate tasks, fix-tickets, or scope adjustments may have bypassed Plan QA)
```

**If trigger fires:**
```
⚠️ Plan Staleness Sentinel

Plan approved <X days> ago, <N> tasks closed since last review (or never reviewed).
Reality may have drifted from plan — risk of working from stale phasing/AC.

Status: 🟡 Plan executable แต่ confidence ลดลงตามเวลา
Next Action: 
  Option (a) Run `/impl-plan-review all` (recommended — re-validate phasing, AC dual-track, registry hygiene)
  Option (b) Continue with current plan + acknowledge staleness — note ใน next handoff
  Option (c) Re-plan: `/impl-plan <next-sprint>` ถ้า scope ขยาย/หด มาก
```
→ **Report to user (advisory, not blocking — operator decides)** then proceed to Phase 3 Parallel Region

**If no trigger:**
→ Proceed to Phase 3 Parallel Region

---

## Phase 3 Parallel Region (Checks 6–7Q)

> ⚠️ **Logic change from sequential to parallel**
>
> เมื่อ `docs/state/impl-plan.md` exists แล้ว → Phase 3 เข้าสู่ **2 parallel tracks** (ตาม `.agents/development-guide/qa-plan-workflow.md` § Parallel Timeline):
>
> - **Track A (Implementation):** Check 6 (Impl Tasks) → Check 7 (Code Review)
> - **Track B (QA Planning):** Check 6Q (QA Deliverables) → Check 7Q (QA Review/Rebuttal)
>
> Track A และ Track B รันพร้อมกันได้ (QA Plan ควรผ่าน review ก่อนหรือพร้อมกับ code review — test cases ใช้เป็น coverage checklist ของ code reviewer)
>
> **Scan behavior:** Do NOT stop at first gap. เก็บ gap ทั้งหมดจาก Track A + Track B เป็น `parallel_candidates[]` แล้วรายงานพร้อมกันใน Phase 2 Report หลังจบ parallel region
>
> **Exit gate (proceed to Check 8 Red Team):** ทุก Track A + Track B checks ผ่านทั้งหมด (impl tasks done ✅ + code review approved ✅ + QA Plan approved ✅)

### Check 6: Implementation Tasks (Track A) — Three-Tier Reconciliation

> ⚠️ **CRITICAL: Task closure (`[x]` ACs) ≠ Exploratory Walk done ≠ Phase Gate closure**
>
> A phase is "done" only when **all three tiers** close: (Tier 1) all task `[x]` ACs verified, (Tier 1.5) Exploratory Walk artifact exists + ≤14d old + CRITICAL findings resolved, (Tier 2) Phase Gate row `[x]`. This check MUST scan all three tiers + reject forbidden closure patterns. Reporting "all tasks done" when Phase Gates are still `[ ]` OR walk artifact missing/stale is the **Phase Gate Hallucination** (see `_core-behaviors.md` Behavior #6 Verify, Don't Assume).

```
Read: docs/state/impl-plan.md
      docs/state/_session-handoff/  (glob walk artifacts: *-phase<N>-exploratory-walk.md)

Scan Tier 1 — Task Closure:
  Find: tasks ที่ status ยังไม่ done (ไม่มี [x] ครบทุก acceptance criteria)
  Also detect: ≥2 ready tasks ที่ mutually independent + scope-isolated → parallel-eligible

Scan Tier 1.5 — Exploratory Walk Freshness:
  For each phase ที่ Tier 1 ครบแล้ว (or has IMPL-P*-GATE task pending):
    - Glob `docs/state/_session-handoff/*-phase<N>-exploratory-walk.md`
    - Check artifact exists + dated ≤14 days from today
    - Check artifact's "Findings" section: all CRITICAL = resolved (linked IMPL-FIX-* tickets ปิดแล้ว)
  Status:
    - Missing artifact → 🔴 walk required before P*-GATE nomination
    - Stale artifact (>14d) → 🔴 walk re-run required
    - Artifact present + fresh + CRITICAL resolved → ✅ Tier 1.5 done

Scan Tier 2 — Phase Gate Closure:
  Find: Phase Gate sections (P1/P2/P3/P4 หรือ IMPL-P*-GATE) ที่ยังมี - [ ] rows
  Note: Phase Gate rows ปกติ live ที่ "## Phase Gate" headers หรือ task IDs ลงท้ายด้วย "-GATE"

Scan forbidden closure patterns (Empirical Closure Discipline violation):
  Grep impl-plan.md for:
    - "deferred to operator-runtime"
    - "deferred to post-launch operator phase"
    - "deferred per .* precedent"
    - "structurally complete.*deferred"
  Each occurrence on a [x]-marked AC line = Code Review Dimension #11 CRITICAL violation
```

**Decision matrix (Tier 1 × Tier 1.5 × Tier 2):**

| Tier 1 (Tasks) | Tier 1.5 (Walk) | Tier 2 (Phase Gates) | Forbidden Patterns | Status |
|----------------|------------------|----------------------|-------------------|--------|
| Incomplete | (irrelevant) | Open | (any) | `⚠️ Tier 1 in progress` — recommend `/impl-task` |
| Complete `[x]` | Missing/Stale | Open `[ ]` | None | `🔴 Tier 1 done, Tier 1.5 PENDING` — recommend exploratory walk before P*-GATE |
| Complete `[x]` | Fresh ✅ | Open `[ ]` | None | `🔴 Tier 1+1.5 done, Tier 2 BLOCKED` — Phase Gate empirical demo pending |
| Complete `[x]` | (any) | Open `[ ]` | Found ≥1 | `🔴🔴 HALLUCINATION RISK` — forbidden closure patterns present; tasks marked `[x]` without empirical evidence |
| Complete `[x]` | Fresh ✅ | Closed `[x]` | None | ✅ Phase complete — proceed |

**If incomplete tasks (Tier 1):**
```
Track A Candidate:
Phase: Implement (Tasks)
Status: ⚠️ เหลือ tasks อีก [N] tasks — ถัดไปคือ IMPL-XXX
Next Action: /impl-task IMPL-XXX
```

**If Tier 1 complete but Tier 1.5 walk missing or stale:**
```
Track A Candidate:
Phase: Implement (Tier 1.5 Exploratory Walk — Pending)
Status: 🔴 Tier 1 task closure 100% (N/N ACs [x]) แต่ exploratory walk artifact ขาด/หมดอายุ
        Phase: P<N>
        Walk artifact expected: docs/state/_session-handoff/<date>-phase<N>-exploratory-walk.md
        Found: <none / artifact dated YYYY-MM-DD age <X> days>
        ⚠️ ห้าม nominate IMPL-P<N>-GATE — Phase Gate Tier 1.5 row จะ block. Walk ต้องทำก่อน
Next Action: Run 30-min non-scripted operator walk per andm-impl-engineer/SKILL.md § Tier 1.5 Exploratory Walk Protocol
  - Bootstrap deployable from cold state
  - เปิด live system in real browser/client (ไม่ใช่ headless)
  - เดินทุก collection / view / locale / role / theme — note functional defects
  - Write artifact ที่ docs/state/_session-handoff/<YYYYMMDD>-phase<N>-exploratory-walk.md
  - File CRITICAL findings เป็น IMPL-FIX-* tickets, resolve ก่อนปิด Phase Gate row
  → ดู `andm-impl-engineer/SKILL.md § Tier 1.5 Exploratory Walk Protocol` + Glossary "Exploratory Walk"
```

**If Tier 1 complete + Tier 1.5 fresh but Tier 2 open:**
```
Track A Candidate:
Phase: Implement (Phase Gate Empirical Verification — Tier 2)
Status: 🔴 Tier 1 task closure 100% (N/N ACs [x]) + Tier 1.5 walk fresh ✅ แต่ Phase Gate Tier 2 ยัง [ ] — เหลือ [M] gate rows ค้าง
        Phases ที่มี gate ยังเปิด: [P2, P3, ...]
        ⚠️ ห้าม report เป็น "Phase Implement เกือบเสร็จ" — empirical demo ยังไม่ได้รัน
Next Action:
  - ถ้ายังไม่มี IMPL-Pn-GATE task → edit `docs/state/impl-plan.md` directly to add IMPL-Pn-GATE task (mirror IMPL-P5-GATE pattern in same file); update overview.md + log entry ใน Mid-Phase Audit Log. ถ้าการเพิ่ม gate task เผยให้เห็น phasing flaw ขนาดใหญ่ → `/impl-plan-review all` แทน
  - ถ้ามีแล้ว → /impl-task IMPL-Pn-GATE (รัน empirical demo + tick gate boxes)
  → ดู `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` + Glossary "Phase Gate Blocking"
```

**If forbidden patterns found:**
```
🔴🔴 HALT — HALLUCINATION RISK DETECTED
พบ [N] occurrences ของ forbidden closure patterns บน [x] ACs:
  - <file>:<line> — "<pattern>"
  ...
Code Review Dimension #11 = CRITICAL violation. ห้ามตีว่า task เหล่านี้เสร็จจริง
Next Action: /impl-review all (จะ raise CRITICAL findings) → /impl-review-fix → re-verify empirically
```

**Additional hint — ถ้าเจอ parallel-eligible tasks ≥2 ตัว (Claude Code only):**
```
💡 Parallel opportunity detected
พบ [M] independent ready tasks ข้าม services:
  - IMPL-XXX (api, size <X>)
  - IMPL-YYY (web, size <Y>)
  - IMPL-ZZZ (worker, size <Z>)
Suggested: /impl-task parallel  — จะ HALT เพื่อแนะนำ fan-out ผ่าน andm-impl-engineer subagents
(ดู impl-task.md § Phase 1.5 Parallel Task Recommendation)
```
→ **Add to parallel_candidates** (do NOT stop — continue scanning)

### Check 6Q: QA Plan Deliverables (Track B)
```
Glob: docs/qa/*.md + docs/qa/02-test-cases/*.md
Expected:
  - docs/qa/01-test-execution-plan.md
  - docs/qa/02-test-cases/ (≥1 TC-*.md file — e.g. TC-FR-001.md, TC-API-001.md)
  - docs/qa/03-traceability-matrix.md
```

**If missing or incomplete:**
```
Track B Candidate:
Phase: Implement (QA Planning — parallel กับ impl)
Status: QA Plan deliverables ไม่ครบ
Next Action: ใช้ prompt template สร้าง QA docs
  → copy `.agents/prompt-templates/qa-plan-direct-prompt.md` → paste เข้า agent ใหม่
  → ดู `.agents/development-guide/qa-plan-workflow.md`
  → Input: docs/design-docs/02-08 (v1.2: gaps 01/06) + docs/api-specs/ + docs/adr/ + docs/ba/01-05 + docs/ux/ (optional)
         + docs/state/impl-plan.md (for task ID sync)
```
→ **Add to parallel_candidates** (do NOT stop — continue scanning)

### Check 7: Code Review (Track A — sequential after Check 6)
```
Glob: docs/code-review/*.md
Check: review-round files exist? ถ้ามี — check fix-round คู่กัน + CRITICAL/HIGH ค้าง?
Note: ควรรอให้ Check 6 (impl tasks) done ก่อนถึงจะ trigger code review อย่างสมเหตุสมผล
      แต่ยังเก็บเป็น candidate ได้ถ้า user ต้อง partial review ระหว่าง sprint
```

**If impl tasks done + no reviews yet:**
```
Track A Candidate:
Phase: Implement (Code Review)
Status: Sprint เสร็จแล้ว ยังไม่ได้ review code
Next Action: /impl-review all
Note: ideally ทำหลัง QA Plan approved (test cases = coverage checklist)
```

**If has reviews but CRITICAL/HIGH pending:**
```
Track A Candidate:
Phase: Implement (Code Review Fix)
Status: มี code review findings ค้าง
Next Action: /impl-review-fix docs/code-review/review-round-XX.md
```
→ **Add to parallel_candidates** (do NOT stop — continue scanning)

### Check 7Q: QA Review / Rebuttal (Track B — sequential after Check 6Q)
```
Prerequisite: Check 6Q passed (QA deliverables ครบ)
Glob: docs/qa/claim-review-and-rebuttal/*.md
Check: มี claim-review file หรือยัง? ถ้ามี — check ว่ามี rebuttal-round คู่กันไหม?
       อ่าน round ล่าสุด — ยังมี CRITICAL/HIGH ค้างไหม?
```

**If QA deliverables exist but no reviews yet:**
```
Track B Candidate:
Phase: Implement (QA Review)
Status: QA Plan สร้างแล้ว ยังไม่ได้ตรวจ
Next Action: /qa-review all
```

**If has reviews but CRITICAL/HIGH pending:**
```
Track B Candidate:
Phase: Implement (QA Rebuttal)
Status: มี QA findings ค้าง
Next Action: /qa-rebuttal docs/qa/claim-review-and-rebuttal/claim-review-XX.md
```
→ **Add to parallel_candidates** (do NOT stop — continue scanning)

### Phase 3 Parallel Region Exit Gate

After Checks 6, 6Q, 7, 7Q scanned:

**If `parallel_candidates[]` not empty:**
→ **STOP — Report ALL candidates to user as parallel options** (see Phase 2 Report § Parallel Recommendations)

**If empty (ทุก track ผ่าน — impl tasks done ✅ + code review approved ✅ + QA Plan approved ✅):**
→ Proceed to Check 8 (Phase 4 Harden)

### Check 8: Red Team Security Audit
```
Glob: docs/security/*.md
Check: red-team-round files exist? ถ้ามี — check defense-round คู่กัน + CRITICAL/HIGH ค้าง?
```

**If no audits yet:**
```
Phase: Harden (Red Team)
Status: ยังไม่ได้ทำ security audit
Next Action: /red-team all
```

**If has audits but CRITICAL/HIGH pending:**
```
Phase: Harden (Red Team Defense)
Status: มี security findings ค้าง
Next Action: /red-team-rebuttal docs/security/red-team-round-XX.md
```
→ **STOP — Report to user**

### Check 9: Delivery Handoff
```
Check: docs/state/overview.md — has "Final" marker or delivery summary?
       Or: all phases above passed but no /deliver run yet?
```

**If no delivery handoff yet:**
```
Phase: Deliver
Status: ทุก phase ผ่านแล้ว — ยังไม่ได้ทำ final delivery handoff
Next Action: /deliver all
```
→ **STOP — Report to user**

### Check 10: All Done
```
Phase: Done!
Status: ทุก phase ผ่านหมดแล้ว + delivery handoff complete
Next Action: PR → merge → deploy → Knowledge Base setup
```

---

## Phase 1.9: Navigation Decision Layer (Synthesize → ONE Primary Action)

> **Why this layer exists** (review-from-gpt2 finding): output แบบ status table + parallel candidates list ทำให้ daily user ต้องตีความเองว่า "วันนี้ควรเริ่มตรงไหน". `/next` ต้องเป็น **daily session navigator** ที่ตอบคำถามเดียวให้ชัด: "วันนี้ทำอะไรเป็นอันดับ 1, ทำไม, อะไรที่ห้ามทำก่อน, ความมั่นใจแค่ไหน". Layer นี้ synthesize ทุก check ใน Phase 1 + Pre-check 0 result → ส่งออก **ONE primary recommendation** พร้อม metadata ที่จำเป็นต่อการตัดสินใจ.

### 1.9.1 Priority Order (first-match wins)

Walk this list top-to-bottom. The **first** condition that fires becomes the primary recommendation:

| # | Condition | Primary action | Confidence |
|---|-----------|----------------|------------|
| 1 | Pre-check 0 fired (user signal OR state-memory breakage) | Triage breakage first (per Pre-check 0 § C output) | High |
| 2 | Open backtrack (Check 0) | Resolve target backtrack phase | High |
| 3 | Open amendment obligations (Check 0.5) | Run earliest unchecked obligation in chain (typically `/amend <downstream-phase>` then re-review) | High |
| 4 | BA/SD/UX/TD deliverables incomplete (Checks 1-4.7) | Run the missing deliverable workflow | High |
| 5 | Design QA pending or rebuttal CRITICAL/HIGH (Checks 3-4.8) | Run review or rebuttal | High |
| 6 | Bootstrap missing or stale (Check 4.9) | `/project-init` or `/project-init --regen` | High |
| 7 | Impl plan missing (Check 5) | `/impl-plan 1` | High |
| 8 | Plan QA pending or CRITICAL/HIGH (Check 5.25) | `/impl-plan-review all` or `/impl-plan-rebuttal` | High |
| 9 | State Reconciliation drift (Check 5.5) | Reconcile drift before continuing | High |
| 10 | Operator Action Backlog non-empty (Check 5.7) | Clear backlog or pivot to non-blocking task | Medium-High (depends on backlog age) |
| 11 | Plan Staleness Sentinel fires (Check 5.8) | Recommend `/impl-plan-review all` (advisory; user may accept staleness) | Medium |
| 12 | Tier 1 (Task Closure) incomplete (Check 6) | `/impl-task <next-ready-id>` or `/impl-task parallel` | High |
| 13 | Tier 1 done, Tier 1.5 Walk missing/stale (Check 6) | Run Tier 1.5 Exploratory Walk (per andm-impl-engineer SKILL § Tier 1.5 protocol) | High |
| 14 | Tier 1+1.5 done, Tier 2 Phase Gate open (Check 6) | `/impl-task IMPL-P<N>-GATE` (or edit `impl-plan.md` directly to add gate task first if missing — `/amend` does not target impl-plan) | High |
| 15 | Code Review pending or CRITICAL/HIGH (Check 7) | `/impl-review all` or `/impl-review-fix` | High |
| 16 | QA Plan deliverables / review pending (Checks 6Q, 7Q — Track B) | Run QA Plan workflow or review/rebuttal | Medium-High (parallel-eligible with Track A) |
| 17 | Red Team pending or CRITICAL/HIGH (Check 8) | `/red-team all` or `/red-team-rebuttal` | High |
| 18 | Delivery handoff missing (Check 9) | `/deliver all` | High |
| 19 | All Done (Check 10) | PR → merge → deploy → Knowledge Base | High |

> **Backtrack/overview drift (Check 0.7) is advisory** — does not appear in priority order; mention in confidence calibration if detected (drift may muddy other signals)

> **Parallel-track override (Phase 3 only):** ถ้าทั้ง #12/#14 (Track A) และ #16 (Track B) eligible พร้อมกัน — primary = Track B if QA Plan ยังไม่ approved (because it gates code review checklist); else primary = Track A. Always mention the parallel option in "Do not do yet" section so user knows it exists.

### 1.9.2 Primary Recommendation Output (MANDATORY format)

After applying §1.9.1 priority order, format the primary recommendation as:

```markdown
## 📍 Today's Recommended First Action

**Do first:** `<exact command>` — <one-line action description>

**Why first:** <reason from state + risk; cite the check that fired and its evidence — e.g., "Pre-check 0 detected unresolved IMPL-FIX-018 (Lexical field render bug) จาก walk artifact 2026-04-29; phase 2 progression blocks until resolved">

**Do NOT do yet:** <explicit list of next-step commands user might be tempted to run but shouldn't until primary done>
- <e.g., "❌ /impl-task IMPL-P3-GATE — Phase 2 Tier 1.5 walk findings ยังเปิด">
- <e.g., "❌ /red-team all — Phase 3 Tier 2 ยัง [ ]">

**Confidence:** High / Medium / Low — <one-line reason>
- High = state files agree, single fired condition, no ambiguity
- Medium = competing priorities (e.g., parallel tracks), or advisory check fired (Plan Staleness)
- Low = breakage signal but state silent (cannot reproduce), or state files conflict (drift unresolved)

**If this feels wrong:** <what user should verify to challenge the recommendation>
- <e.g., "Open `docs/state/_session-handoff/2026-04-29-phase2-exploratory-walk.md` — if all CRITICAL findings actually resolved (closed IMPL-FIX-* tickets), Pre-check 0 should not have fired; report drift in walk artifact">

**Files to open before starting:**
- <relative path 1 — e.g., `docs/state/impl-plan.md` § task IMPL-XXX>
- <relative path 2 — e.g., `.claude/rules/api.md`>
- <relative path 3 — e.g., `docs/api-specs/auth.yaml`>
```

### 1.9.3 Confidence Calibration Rules

Apply these rules when picking confidence label:

| Signal | Effect on confidence |
|--------|----------------------|
| Pre-check 0 fired with both A (user signal) + B (state memory) agreeing | High |
| Pre-check 0 fired with only A or only B | Medium |
| Single phase check fires (e.g., only Check 6 Tier 1) with no drift | High |
| State Reconciliation drift detected (Check 5.5) | Medium — drift muddies all downstream signals |
| Plan Staleness fires (Check 5.8) | Medium — advisory, not blocking |
| Operator Action Backlog has rows >7 days old | Medium — workflow probably abandoned, need user decision |
| Multiple competing checks fire (e.g., Tier 1 incomplete + Code Review pending mid-sprint) | Medium — recommendation correct but priority order is opinionated |
| Pre-check 0 user signal but state files silent (cannot reproduce) | Low — recommend triage but flag uncertainty |
| Breakage signal but `/next` cannot identify target task | Low — explicit "ขอ steps จาก user" |

### 1.9.4 Parallel-eligible cases — still pick ONE primary

In Phase 3 Parallel Region (Track A + Track B both have candidates), Navigation Decision Layer **does not** present a list. It picks ONE primary using §1.9.1 priority + parallel-track override rule, then mentions the parallel alternative in **"Do NOT do yet"** as an explicit allowed-parallel option:

```
**Do NOT do yet (but parallel-eligible — your call):**
- /impl-task IMPL-018 (Track A) — can run in parallel with Track B if you have capacity for two tracks today
```

This forces the daily decision while preserving optionality.

### 1.9.5 Self-Validation Scenario Matrix (Regression Guard)

> **Why this matrix exists:** priority order in §1.9.1 is opinionated — without explicit fixtures, `/next` could regress to giving wrong recommendations after future edits. Mental-test these 5 scenarios after any change to §1.9.1 or Pre-check 0; if expected behavior breaks, fix the priority order before merging.

| # | Scenario | Expected Primary | Expected Confidence | Why |
|---|----------|------------------|---------------------|-----|
| **A** | walk artifact has CRITICAL F-XX still `[ ]` AND Tier 1 has open ready tasks | Triage IMPL-FIX-XX (linked to walk finding) — NOT the next ready task | High | Pre-check 0 Path B fires (state-memory breakage) → priority #1 wins over #12 (Tier 1 incomplete). Walk-finding takes precedence over routine progression |
| **B** | overview reports "P2 done" but impl-plan has 3 `[ ]` tasks in P2 | Reconcile state drift first — manually sync overview to impl-plan SoT, OR re-run last impl-plan-rebuttal cycle | High | Check 5.5 fires → priority #9 wins over #12/#14. Drift muddies all downstream signals — must resolve before progression |
| **C** | Tier 1 ครบ (every `[x]`), but no `_session-handoff/*-phase<N>-exploratory-walk.md` artifact (or artifact > 14d old) | Run Tier 1.5 Exploratory Walk per `andm-impl-engineer/SKILL.md § Tier 1.5 protocol` — NOT IMPL-P<N>-GATE | High | Check 6 Three-Tier Reconciliation: Tier 1 done + Tier 1.5 missing → priority #13 wins over #14. Phase Gate Tier 1.5 row blocks gate closure anyway |
| **D** | Track A has ready impl tasks; Track B has no QA Plan deliverables yet (Check 6Q empty) | Track B (`/qa-plan` workflow) — primary; Track A mentioned in "Do NOT do yet (parallel-eligible)" | Medium-High | Parallel-track override (§1.9.4): QA Plan gates code review checklist; advance Track B first to unblock Track A's review phase |
| **E** | User says "X พัง" this turn, but state files all clean (no walk findings, no IMPL-FIX, no expired registry) | Triage X — but Confidence = Low; explicitly ask user for repro steps + screenshot/log + verify environment | Low | Pre-check 0 Path A fires but Path B silent → §1.9.3 calibration: "user signal but state silent (cannot reproduce)" = Low confidence; recommend triage but flag uncertainty + do not progress |
| **F** | amendment-log has AMEND-NNN (T3, BA→SD chain, age 3d) with `/amend sd` obligation `[ ]` AND Tier 1 has open ready tasks | Run `/amend sd "<follow-up description from amend log>"` — NOT `/impl-task` | High | Check 0.5 fires → priority #3 wins over #12. Downstream content stale relative to amendment scope; phase progression must wait until obligations close |
| **G** | T4 amend just executed (e.g., changed auth from JWT → session) — amendment-log has full chain `/amend sd → /amend td → /amend ux → /sd-review → /td-review` all `[ ]` | Run **earliest** obligation in chain order (typically `/amend sd` first); subsequent obligations close as their phase finishes | High | T4 amends always cascade in dependency order BA→SD→UX→TD→reviews. Engineer ห้าม skip middle phase — each obligation depends on prior obligation completing |
| **H** | User types `/backtrack <non-design-target>` (`impl`, `impl-plan`, `impl-task`, `code`, etc.) — or system tempted to recommend it (e.g., OPS backlog age >14d, expired Deferred-AC, undecomposed L/XL task) | Reject command — `/backtrack` validates target ∈ {ba, sd, ux, td} **only**. Route by concern: task/AC decomposition or Phase Gate criteria → `/impl-plan-review all` (Plan QA loop); code defect in closed phase → `/impl-review all` + `IMPL-FIX-*` ticket + Tier 1.5 walk re-run; upstream design root cause → `/backtrack ba\|sd\|ux\|td` | High | `/backtrack` reserved for design-phase rework with invalidation matrix; impl/impl-plan/code changes flow through Plan QA loop or Code Review loop (Wave 1 added Plan QA pair). Suggesting any unsupported target = command hallucination — same defect class regardless of which non-design target is named |
| **I** | overview marks SD ❌ Invalidated (BT-005), but backtrack-log BT-005.Status: ✅ Closed | Flag drift to user (Check 0.7 Direction A) — recommend trim overview marker; `/next` should not block progression based on stale marker | Medium | Closed backtrack should not silently block; drift is data-quality issue, not a real block. Advisory not blocking — do not promote drift to priority order |

**Test protocol:** when editing §1.9.1 priority table or Pre-check 0 scan logic, walk through all 9 scenarios mentally. If any scenario's expected output cannot be reproduced from the current rules, the change introduces a regression. Add new scenarios when new check categories are added (e.g., if Check 5.9 lands, add scenario J).

**Living document:** scenarios added based on real session friction (Shark CMS 2026-04 produced A + C + E; review-from-gpt3 added F + G + H + I after `/amend` log infrastructure landed). Reviewer + operator may extend this matrix when they catch a recommendation that "felt wrong" — capture as next available letter before fixing priority order.

---

## Phase 2: Report to User

Present the result in Thai with this **mandatory ordering** (Navigation Decision Layer comes first, status table second, parallel options third):

> **Format contract:** the report MUST start with the Navigation Decision Layer output (§1.9.2). The status table is supporting evidence, not the primary answer. Daily users read top-to-bottom — primary recommendation must be visible without scrolling.

### Section 1 (REQUIRED — first thing user sees) — Navigation Decision

Output the §1.9.2 Primary Recommendation block verbatim:

```markdown
## 📍 Today's Recommended First Action

**Do first:** ...
**Why first:** ...
**Do NOT do yet:** ...
**Confidence:** ...
**If this feels wrong:** ...
**Files to open before starting:** ...
```

### Section 2 (REQUIRED — supporting evidence) — Status Snapshot

```
## สถานะโปรเจค

| Phase | Status |
|-------|--------|
| 🔄 Backtrack    | ✅ ไม่มี / ⚠️ มี open: BT-NNN |
| 📝 Amendments   | ✅ ไม่มี Open / ⚠️ N Open AMEND obligations (oldest <X days>) |
| 🔍 Backtrack/Overview Drift | ✅ ซิงค์ / ⚠️ Direction A: <N stale markers> / Direction B: <N missing markers> |
| Design (BA)     | ✅ ครบ / ❌ ไม่มี / ⚠️ ไม่ครบ |
| Design (SD)     | ✅ ครบ / ❌ ไม่มี / ⚠️ ไม่ครบ |
| Design QA (BA)  | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |
| Design QA (SD)  | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |
| UX/UI Design    | ✅ ครบ+approved / ❌ ยังไม่มี / ⚠️ ไม่ครบ / 🔍 รอ approve |
| Design (TD)     | ✅ ครบ / ❌ ไม่มี / ⚠️ ไม่ครบ |
| Design QA (TD)  | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |
| Bootstrap       | ✅ stack.json sync / ❌ ยังไม่ bootstrap / ⚠️ stack.json stale (TD เปลี่ยน) |
| Impl Plan       | ✅ มี / ❌ ยังไม่มี |
| Plan QA         | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |
| State Reconciliation | ✅ ซิงค์ / ⚠️ drift detected (impl-plan ↔ overview / registry / handoff) |
| Operator Action Backlog | ✅ ว่าง / ⚠️ N Pending (oldest <X days>) |
| Plan Staleness | ✅ fresh / ⚠️ approved <X days> ago + <N> closures since review (recommend re-review) |
| Impl Tasks — Tier 1 (Task Closure) | ✅ ทุก task `[x]` ACs / ⚠️ เหลือ N tasks |
| Exploratory Walk — Tier 1.5 | ✅ artifact fresh (≤14d) / 🔴 missing/stale — Pn pending |
| Phase Gates — Tier 2 (Empirical Demo) | ✅ ทุก Phase Gate `[x]` / 🔴 Tier 1+1.5 done, Tier 2 BLOCKED — Pn gate ยัง `[ ]` / 🔴🔴 forbidden closure patterns พบ N รายการ |
| QA Plan (B)     | ✅ ครบ+approved / ❌ ยังไม่มี / ⚠️ ไม่ครบ / 🔍 รอ review / ⚠️ มี findings ค้าง |
| Code Review (A) | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |
| Red Team        | ✅ ผ่าน / ❌ ยังไม่ตรวจ / ⚠️ มี findings ค้าง |

```

### Section 3 (CONDITIONAL — Phase 3 only) — Parallel-Track Acknowledgement

ถ้าอยู่ใน Phase 3 Parallel Region และทั้ง Track A + Track B มี candidates → primary recommendation (Section 1) เลือกตาม §1.9.4 แล้ว, แต่ Section 3 list parallel alternatives เป็น context. **Section 3 ไม่ใช่คำตอบหลัก** — primary in Section 1 remains the recommended single starting point.

```markdown
**Parallel-eligible alternatives (your call — primary above remains the recommended single starting point):**

**Track A — Implementation:**
- [Candidate from Check 6 — Impl Tasks — if any]
- [Candidate from Check 7 — Code Review — if any]

**Track B — QA Planning:**
- [Candidate from Check 6Q — QA Deliverables — if any]
- [Candidate from Check 7Q — QA Review/Rebuttal — if any]

**Parallel hint:** Track B (QA Plan) มักเดินก่อนหรือพร้อม Track A เพราะ test cases = coverage checklist สำหรับ code review
```

> **Daily navigator contract:** primary recommendation (Section 1) is mandatory; status table (Section 2) is supporting context; parallel list (Section 3) appears only in Phase 3. Daily user reading top-to-bottom sees the answer first, evidence second, optionality third — not buried in a status table they have to interpret.
