# Delivery Handoff — Development Guide

คู่มือการใช้งาน workflow สำหรับ Deliver Phase: assess delivery readiness + finalize handoff documentation + produce delivery summary

---

## ภาพรวม Flow

```
┌────────────────────────────────────────────────────────────────┐
│  ผ่าน Harden Phase แล้ว                                        │
│  - ไม่มี CRITICAL/HIGH vulnerability ค้างใน docs/security/      │
│  - Code review, Red Team, QA Plan ผ่านครบ                      │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /deliver <scope>  →  Deliver Handoff Engineer                 │
│  Persona: .agents/skills/             │
│           andm-deliver-handoff/SKILL.md                             │
│  (Readiness assessment + handoff finalization)                 │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  Phase 1: Assess Readiness     → readiness checklist (ตาราง)   │
│  Phase 2: Generate Handoff     → overview.md + per-module      │
│                                   handoff.md + delivery summary │
│  Phase 3: ⏸️ HALT — Human Review                               │
│  Phase 4: Finalize             → commit docs/state/            │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              Production deploy / Knowledge base setup
```

---

## เมื่อไรควรรัน (Entry Criteria)

ก่อนสั่ง `/deliver` ต้อง confirm ว่า:

- ✅ **Phase 1 Design** — BA (8), SD (8), UX (6), TD (8) docs + ADRs + API specs ครบ
- ✅ **Phase 2 Design QA** — BA/SD/UX/TD review & rebuttal rounds ผ่าน (ไม่มี CRITICAL/HIGH)
- ✅ **Phase 3 Implement** — impl-plan tasks ส่วนใหญ่ `status: done` + code review passed + ทุก Phase Gate (Tier 2) ปิด `[x]`
- ✅ **Phase 4 Harden** — Red Team audit ผ่าน, `05-security.md` + `.claude/rules/security.md` updated
- ✅ **Working tree clean** — ไม่มี uncommitted changes ที่เกี่ยวกับ production code

### Hard Blockers (state files must be empty/closed)

`/deliver` **ห้ามรัน** ถ้ามีรายการต่อไปนี้ค้างใน state — agent จะ HALT + รายงาน blocker:

| Blocker | File | Reason |
|---------|------|--------|
| Open backtrack | `docs/state/backtrack-log.md` (Status: 🔄 Open) | Downstream phases อาจยัง invalidated; cannot certify ready-to-deliver |
| Open AMEND obligations | `docs/state/amendment-log.md` (Status: 🔄 Open with unchecked rows) | T3/T4 amendment downstream ไม่ครบ — design content stale relative to scope |
| Active Deferred-AC entries | `docs/state/deferred-ac-registry.md` (## Active table non-empty) | E-ACs ยังไม่ได้ exercise on real system — Empirical Closure Discipline violation |
| Pending OPS rows | `docs/state/operator-action-registry.md` (## Pending table non-empty) | UIR actions (env vars, API keys, ToS) ยังไม่ทำ — runtime config untested |
| Forbidden closure patterns | grep `impl-plan.md` for "deferred to operator-runtime" / "deferred per X precedent" | Phase Gate Hallucination risk (Code Review Dim #11 CRITICAL) |

> ⚠️ ถ้า phase ก่อนหน้ายังไม่ครบ → andm-deliver-handoff agent จะ flag ใน readiness checklist และอาจแนะนำให้ `/backtrack ba\|sd\|ux\|td` (สำหรับ design root cause) หรือ `/impl-plan-review all` (สำหรับ plan-level concerns) ก่อน. `/backtrack` ไม่รองรับ target นอก ba/sd/ux/td.

---

## Command + Scope Options

### Full project handoff:
```
/deliver all
```

### Per-module handoff:
```
/deliver api
/deliver web
/deliver worker
```

- `all` (default) → scan ทุก module + produce full delivery summary
- `<module>` → generate handoff เฉพาะ service เดียว (ใช้สำหรับ partial delivery หรือ phased rollout)

---

## Inputs Required

Agent จะอ่านไฟล์/โฟลเดอร์ต่อไปนี้ตอน Phase 0 Onboarding:

| Input | Location | ใช้เพื่อ |
|-------|----------|---------|
| Project rules | `CLAUDE.md` | tech stack + architecture constraints |
| Module status | `docs/state/overview.md` | current state ของแต่ละ module |
| Impl plan | `docs/state/impl-plan.md` | task completion count (done/deferred) |
| System overview | `docs/design-docs/02-high-level-architecture.md` | architecture context |
| ADRs | `docs/adr/` | architectural decisions ทั้งหมด |
| Security | `docs/security/` | red team + defense rounds |
| Code review | `docs/code-review/` | review findings + fix rounds |
| QA plan | `docs/qa/` | test strategy + traceability |
| Per-module handoffs | `docs/state/*/handoff.md` | module-level context |

---

## Outputs Produced

| Output | Location | Owner |
|--------|----------|-------|
| Readiness checklist (ตาราง) | presented inline | andm-deliver-handoff agent |
| Updated module status | `docs/state/overview.md` | andm-deliver-handoff agent |
| Final handoff ต่อ module | `docs/state/<module>/handoff.md` | andm-deliver-handoff agent |
| Delivery summary report | presented inline + committed | andm-deliver-handoff agent |

**Delivery summary ประกอบด้วย:**
- Scope delivered (Must-Have / Should-Have complete counts)
- Quality gates passed (BA, SD, UX, TD, Code Review, Red Team, QA)
- Known issues (severity + impact + suggested fix)
- Deferred items (task ID + reason + priority for next sprint)
- Deployment notes (env-specific, feature flags, migration steps)
- Metrics (เทียบ baseline vs actual — ถ้ามี baseline)

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สั่ง Deliver Handoff (เปิด session ใหม่)

```
/deliver all
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → state files → design docs → ADR → security → code review → QA
2. **Phase 1 — Readiness Assessment:**
   - Design completeness (BA 8, SD 8, UX 6, TD 8, ADR, API specs)
   - QA status (review/rebuttal passed per phase)
   - Implementation status (done vs deferred tasks)
   - Code health (`git status`, test results, commit context)
3. **Phase 2 — Generate Handoff:**
   - Update `docs/state/overview.md` (final module status table)
   - Update per-module `docs/state/*/handoff.md` (What Was Built / Architecture Decisions / Known Issues / How to Run / Dependencies / Key Files)
   - Produce delivery summary report

#### Output (inline):
```
## Delivery Readiness

| Area         | Status | Details                          |
|--------------|--------|----------------------------------|
| BA Docs (8)  | ✅     | 8 files, review passed           |
| SD Docs (8)  | ✅     | 8 files, review passed           |
| UX Docs (6)  | ⚠️     | 6 files, 1 LOW finding open      |
| TD Docs (8)  | ✅     | 8 files, review passed           |
| ADRs         | ✅     | 5 decisions                      |
| API Specs    | ✅     | 3 specs                          |
| Impl Plan    | ⚠️     | 44/47 tasks done (3 deferred)    |
| Code Review  | ✅     | Round 2 passed                   |
| Red Team     | ✅     | Round 2 passed                   |
| QA Plan      | ✅     | Complete                         |
```

---

### Step 2: ⏸️ HALT — Human Review

Agent หยุดรอ user approve ก่อน finalize:

- `approve` → commit updated `docs/state/` + mark delivered
- `revise` → ระบุ section ที่ต้องแก้ → regenerate
- `block` → list blocking issues ที่ต้อง fix ก่อน deliver (เช่น CRITICAL security finding ที่ยังไม่ถูก resolve)

> ⚠️ **ห้าม mark project as delivered โดยไม่ได้ human approve** — ยึด Golden Rule "อย่าให้ AI อนุมัติ AI"

---

### Step 3: Finalize

เมื่อ user ตอบ `approve`:

1. Commit `docs/state/overview.md` + `docs/state/*/handoff.md` ด้วย contextual commit message
2. Report final status + recommended next steps:
   - Deploy preparation
   - Knowledge base setup (NotebookLM / RAG / wiki)
   - Monitoring dashboard setup
   - Handoff to maintenance team

---

## Common Issues / Failure Modes

| ปัญหา | สาเหตุ | วิธีแก้ |
|-------|--------|---------|
| Readiness checklist มี ❌ หลายช่อง | Phase ก่อนหน้ายังไม่ครบจริง | `/backtrack <phase>` กลับไปแก้ก่อน deliver |
| Impl plan มี task `status: in-progress` | ค้างงาน — ไม่ใช่ deferred | จบงานด้วย `/impl-task` หรือ mark deferred อย่างเป็นทางการ |
| Red Team ยังมี HIGH/CRITICAL ค้าง | ข้าม harden phase | `/red-team-rebuttal` ปิดให้ครบก่อน |
| Git working tree ไม่ clean | มี WIP ที่ไม่เกี่ยวกับ handoff | commit หรือ stash ก่อนสั่ง `/deliver` |
| Per-module handoff content เก่า | Copy ของเดิมมาใช้โดยไม่ verify | Agent ต้อง verify จาก git state + file contents จริง (persona rule) |
| ไม่มี baseline metrics | Project ใหม่ — เพิ่งเริ่มใช้ AI workflow | skip metrics section — อย่าใส่ตัวเลขที่ไม่มี baseline เทียบ |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้า readiness assessment เปิดเผยปัญหา structural ที่ handoff แก้ไม่ได้:

| Trigger | ตัวอย่าง | Backtrack To | Action |
|---------|---------|-------------|--------|
| **Deferred tasks เยอะจนกระทบ scope** | Must-Have features 5/12 deferred | BA | `/backtrack ba` (redefine MVP) |
| **Architecture drift** | Code ไม่ตรงกับ SD diagram หลายจุด | SD | `/backtrack sd` |
| **Missing compliance deliverable** | ไม่มี audit trail ที่ compliance ต้องการ | BA / SD | `/backtrack` ตาม level ที่ขาด |
| **Test coverage ต่ำกว่า threshold** | Critical paths ไม่มี test | Impl | กลับไปเขียน test ก่อน deliver |

> 📖 **Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## File Structure

```
.claude/commands/
  deliver.md                            ← /deliver command definition

methodologies/full-track/
  skills/andm-deliver-handoff/SKILL.md       ← Deliver Handoff Engineer persona
  workflows/deliver.md                  ← workflow spec

docs/state/
  overview.md                           ← final module status table
  <module>/handoff.md                   ← per-module final handoff

docs/                                   ← inputs (read-only for deliver agent)
  ba/, design-docs/, ux/, technical-design/, adr/, api-specs/
  code-review/, security/, qa/
```

---

## Agent Persona

### Deliver Handoff Engineer (`.agents/skills/andm-deliver-handoff/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Delivery Engineer / Knowledge Transfer Specialist |
| **Mindset** | make the next person successful — assume reader has never seen this codebase |
| **Owns** | `docs/state/overview.md` (final), `docs/state/*/handoff.md` (final), delivery report |
| **Can read** | all `docs/`, `services/`, `.claude/rules/`, `methodologies/`, git history |
| **Cannot modify** | source code, design docs, ADRs — documents state, does not change system |
| **Key principles** | Completeness over perfection, verify claims against reality, quantify when possible |

---

## Completion Checklist (Definition of Done)

เมื่อ `/deliver` จบแบบสมบูรณ์ ต้องผ่านทุกข้อ:

- [ ] Readiness checklist แสดงครบทุก area (ไม่มี ❌ ที่ block delivery)
- [ ] `docs/state/overview.md` มี final module status table ลงวันที่ล่าสุด
- [ ] ทุก module มี `docs/state/<module>/handoff.md` updated (What Was Built, Known Issues, How to Run, Dependencies, Key Files ครบ)
- [ ] Delivery summary ระบุ scope delivered + quality gates + known issues + deferred items อย่างชัดเจน
- [ ] Known issues แต่ละรายการระบุ severity + suggested fix
- [ ] Deferred items แต่ละรายการระบุ reason + priority for next sprint
- [ ] **Human approved** delivery summary (ไม่ใช่ AI อนุมัติเอง)
- [ ] Updated `docs/state/` ถูก commit ด้วย contextual message (Why ไม่ใช่แค่ What)
- [ ] Recommended next steps ถูกสื่อสาร (deploy / KB setup / monitoring / maintenance handoff)

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/deliver` — persona onboarding ต้อง fresh
- **อย่า copy handoff เดิมมาใช้** — agent ต้อง verify กับ git state + file contents จริง
- **Quantify ทุกอย่าง** — "3 of 47 tasks deferred" ดีกว่า "some tasks deferred"
- **Honest about known issues** — document จริง ๆ ดีกว่าซ่อนไว้ให้คนถัดไปเจอเอง
- **Metrics เป็น optional** — ถ้าไม่มี baseline จาก 2-3 sprints ก่อนใช้ AI workflow → ข้าม section
- **Per-module handoff คือ onboarding doc** — เขียนให้ dev ใหม่อ่านแล้วรันระบบได้โดยไม่ต้องถามใคร
- **Knowledge base setup เป็น manual step** — หลัง `/deliver` ผ่าน → รวมเอกสารเข้า NotebookLM/wiki เอง (ดู full-journey.md § 5B)
