---
description: Amend existing deliverables — add, change, or remove content in a specific phase's documents with cross-document consistency
---

# Workflow: Amend Deliverables

Make surgical amendments to existing phase deliverables without rewriting from scratch. Maintains cross-document consistency within the phase and flags downstream impact.

**Input:** `{{input}}` — format: `<phase> "<amendment description>"`
- `phase`: `ba`, `sd`, `ux`, or `td`
- `amendment`: what to add, change, or remove (in Thai or English)

**Examples:**
- `/amend ba "เพิ่ม user flow สำหรับ forgot password + reset via email"`
- `/amend sd "เปลี่ยน caching strategy จาก Redis เป็น Memcached สำหรับ session store"`
- `/amend td "เพิ่ม endpoint DELETE /users/:id ใน api-contracts + backend design"`
- `/amend ux "เพิ่ม empty state สำหรับหน้า dashboard"`

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, constraints
2. `.agents/skills/andm-amend-engineer/SKILL.md` — **your persona definition** (activate the full 5-step amendment protocol)
3. `docs/state/overview.md` — current status (if exists)

Once read, proceed to Phase 1.

---

## Phase 1: Parse & Load Context

### 1.1 Parse Input

Extract from `{{input}}`:
- **Target phase** — `ba`, `sd`, `ux`, or `td`
- **Amendment description** — what to add/change/remove

**If input is invalid:**
```
❌ Format: /amend <phase> "<description>"
   phase: ba | sd | ux | td
   Example: /amend ba "เพิ่ม forgot password flow"
```
→ **STOP**

### 1.2 Load Phase Context (MANDATORY — All reads in parallel)

Based on target phase, read ALL deliverables:

**If target = `ba`:**
1. Read `docs/ba/01-05` — all 5 BA deliverables (v1.2: 06-handoff dropped, open questions live in 02-05 by domain)
2. Read `.agents/prompt-templates/ba-requirements-prompt.md` — quality benchmark
3. Check `docs/ba/claim-review-and-rebuttal/` — review status

**If target = `sd`:**
1. Read `docs/design-docs/02-08` — 6 SD deliverables (v1.2: gaps ที่ 01/06 — merged into 02 as Requirements Traceability + ADR Digest sections)
2. Read `docs/adr/` — all ADRs
3. Read `docs/api-specs/` — API contracts
4. Read `.agents/prompt-templates/system-design-master-prompt.md` — quality benchmark
5. Check `docs/design-docs/claim-review-and-rebuttal/` — review status

**If target = `ux`:**
1. Read `docs/ux/01-05` — all 5 UX deliverables (UX-06 dropped in SD-as-Master consolidation; Impl Engineer reads 01-05 directly)
2. Read `.agents/development-guide/ux-design-workflow.md` — quality benchmark

**If target = `td`:**
1. Read `docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` — 3 TD deliverables (SD-as-Master: TD-01/05/06/07/08 dropped)
2. Read `docs/api-specs/*.yaml` — authoritative API contracts (SD owns; replaces TD-01)
3. Read `docs/adr/` — design pattern rationale (replaces TD-05/06)
4. Read `docs/qa/01-test-execution-plan.md` if exists — coverage targets (replaces TD-07; QA-01 authoritative)
5. Read `.agents/prompt-templates/technical-design-master-prompt.md` — quality benchmark
6. Check `docs/technical-design/claim-review-and-rebuttal/` — review status

**Also read (for downstream impact):**
- Glob `docs/` subdirectories to know which phases have deliverables (for downstream impact flagging)

### 1.3 Engage Persona

Follow the andm-amend-engineer persona defined in `.agents/skills/andm-amend-engineer/SKILL.md`. Activate the full 5-step amendment protocol.

---

## Phase 2: Impact Analysis

### 2.0 Classify Tier (v1.2 — NEW)

ก่อนลงรายละเอียด file impact ให้ classify amendment เข้า 4 tiers เพื่อ scope review cascade. ดู SKILL.md Step 1.5 สำหรับ decision algorithm + **Tier Floor Rules (anti-underclassification)**:

| Tier | Trigger | Reviews |
|------|---------|---------|
| **T1 Editorial** | Wording, typo, format, label rename | Scoped section review |
| **T2 Semantic** | Add/change content ภาย phase, ไม่กระทบ traceability/API/data model | Full source-phase review only (no downstream) |
| **T3 Cross-phase** | กระทบ Traceability Matrix / API specs / data model / user flow / NFR / business rule for existing US | Source + scoped downstream review + **MANDATORY amendment-log entry (Phase 5.5)** |
| **T4 Architectural** | Architecture style / infra / security / auth / role / ADR-backed | Source + full downstream + ADR mandatory + **MANDATORY amendment-log entry (Phase 5.5)** |

**Tier Floor Rules — ห้าม classify ต่ำกว่า:**

| Touch | Min |
|-------|-----|
| endpoint / entity / user flow shape / feature removal / NFR / business-rule-on-existing-US | T3 |
| auth / role / permission / security / arch / infra / tech stack / ADR-backed | T4 |

ดู SKILL.md Step 1.5 สำหรับ full Tier Floor table.

**Output before Phase 2.1:**

```markdown
## Tier Classification
**Proposed Tier:** [T1/T2/T3/T4]
**Reasoning:** [ทำไมถึงเลือก tier นี้ — cite Tier Floor Rule ถ้ามีข้อบังคับ]
**Reviews Triggered:** [list ของ review commands ที่ต้องรันหลัง amend จบ]
**Amendment Log:** [Required for T3/T4 / Skipped for T1/T2]
```

> User override tier ได้ ตอน HALT (Phase 3). ถ้า user override **ลงต่ำกว่า** Tier Floor — ต้องบันทึกเหตุผลใน Phase 5.5 amendment-log entry แม้ว่า T1/T2 จะไม่ create entry ปกติก็ตาม (override = audit trail required). Tier ขับ downstream impact assessment (Phase 2.2) + amendment-log decision (Phase 5.5)

### 2.1 Identify Affected Files

For each deliverable file in the target phase:
1. **Grep** for terms related to the amendment (entity names, flow names, component names, endpoint names)
2. **Assess** whether the file needs modification
3. **Describe** what sections need changes and what type (add/change/remove)

### 2.2 Assess Downstream Impact (gated by Tier)

> **v1.2 rule:** ถ้า tier = T1 หรือ T2 → ข้าม downstream check (ไม่กระทบ downstream ตามนิยาม). ถ้า T3 หรือ T4 → ตรวจ downstream ตามตารางด้านล่าง

Check which downstream phases have existing deliverables:

| Phase Flow | Check |
|-----------|-------|
| BA → SD | If amending BA, check if `docs/design-docs/` exists |
| BA → UX | If amending BA, check if `docs/ux/` exists |
| BA/SD → TD | If amending BA or SD, check if `docs/technical-design/` exists |
| SD/TD → Impl | If amending SD or TD, check if `docs/state/impl-plan.md` exists |
| Any → Review | Check if claim-review files exist for the target phase |

### 2.3 Present Impact Table

Show the full impact analysis following the format in SKILL.md Step 2:
- Affected files table (with sections and change size)
- Downstream impact table (which phases need re-validation)
- Review status impact (whether existing reviews are invalidated)

---

## Phase 3: ⏸️ HALT — User Approval

Present the impact analysis and wait:

- `proceed` → execute all changes as analyzed
- `ปรับ scope` → user narrows/expands the amendment, re-analyze
- `cancel` → abort amendment

> ⚠️ **CRITICAL: ห้าม proceed โดยไม่ได้ user approve**

---

## Phase 4: Execute Amendment

Upon user approval, process each affected file following SKILL.md Step 4:

```
For each file (in dependency order — foundational docs first):
  4.1 Announce — State which file and what changes
  4.2 Fresh Read — Read the target file
  4.3 Apply Changes — Use Edit for minimal modifications
  4.4 Verify — Re-read modified section
  4.5 Cascade Check — Grep related terms across other files in same phase
      - Update cross-references
      - Update numbering/ordering
      - Update summary tables and traceability matrices
  4.6 Mark Complete
```

**Dependency order by phase (v1.2):**

| Phase | Order (foundational → dependent) |
|-------|--------------------------------|
| `ba` | 01-project-brief → 02-functional-req → 04-business-rules → 05-user-flows → 03-nfr |
| `sd` | 02-architecture (incl. Traceability + ADR Digest sections) → 03-deep-dive → 04-data-flow → 05-security → 07-evolution → 08-product-breakdown + ADRs + API specs |
| `ux` | 00-design-vision → 01-design-tokens → 02-component-inventory → 03-page-layouts → 04-navigation → 05-interaction-patterns |
| `td` | 02-backend-design → 03-frontend-design → 04-database-design → docs/api-specs/*.yaml → docs/adr/ → docs/qa/01-test-strategy.md |

**Safety Rules:**
- If a change contradicts content in another file within the same phase → STOP and report
- If amending SD and it changes an architecture decision → update or create corresponding ADR
- If amending TD and it would require SD change → recommend `/backtrack sd` instead
- If amending TD and it changes tech stack (language, framework, DB, auth) → after approval run `bash scripts/validate-rules-sync.sh`; if drift detected, run `/project-init --regen` to refresh CLAUDE.md + `.claude/rules/*`

---

## Phase 5: Report

Present a concise summary in Thai following SKILL.md Step 5:

- Files modified with specific changes per file
- Downstream actions needed (amend other phases / re-review / re-validate)
- Consistency verification status
- Recommended next command(s) — ถ้า phase = td และ stack ได้รับผลกระทบ → แนะนำ `/project-init --regen` ใน recommended next commands

---

## Phase 5.5: Persist Amendment Log (T3 / T4 only — MANDATORY)

> **Skip rule:** T1 (Editorial) และ T2 (Semantic intra-phase) **ไม่** create amendment-log entries — โดยนิยามไม่กระทบ downstream. T3/T4 ต้อง create entry **เสมอ** มิฉะนั้น `/next` จะ recommend downstream tasks ที่ depend on stale upstream.

ตาม SKILL.md Step 5.5 — append entry ที่ `docs/state/amendment-log.md`:

1. **สร้างไฟล์ถ้ายังไม่มี** ด้วย header (ดู SKILL.md Step 5.5 schema)
2. **Append AMEND-NNN entry** (numbering: ต่อจาก latest entry +1)
3. **Required fields:** Date, Source phase, Tier, Tier reasoning, Request, Files modified, Downstream obligations checklist, Blocks list, Status: 🔄 Open
4. **Confirm** to user: "AMEND-NNN logged at `docs/state/amendment-log.md`. /next จะ surface obligations เป็น priority #3"

**Closing protocol** (when downstream obligations later resolved):
- Engineer/agent ที่ปิด obligation สุดท้าย — แก้ entry: Status → ✅ Closed, set Closed: date
- Closure อาจเกิดข้าม sessions — agent ปลายน้ำต้องอ่าน amendment-log ก่อน confirm task done

**Reference:** Glossary "Amendment Log" + `andm-amend-engineer/SKILL.md § Step 5.5`
