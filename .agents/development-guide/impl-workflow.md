# Implementation Phase — Development Guide

คู่มือการใช้งาน Phase 3 (Implement) ของ 5-Phase Lifecycle: จาก **SD hints + work inventory** (System Design output) สู่ **phase-grouped working code**.

> ⭐ **Implementation Phase เป็นที่เดียวใน lifecycle ที่ใช้คำว่า "Phase" เป็น content delivery concept**
>
> **Phase Ownership (Option C — Middle Ground):**
> - **SD** ให้ **hints**: `07-future-evolution.md` → Evolution Sequence (hard constraints), `08-product-breakdown.md` → Phase Hints (soft suggestions) + per-task metadata
> - **TD** ส่งต่อ hints พร้อม refinements (เช่น ปรับ risk level จากที่ TD ค้นพบ)
> - **Impl Planner** ทำ **final decision** — honor หรือ override hints ด้วย documented rationale ใน Phasing Rationale
>
> คำว่า "Phase" ในบริบทนี้มี 2 ความหมายที่ต่างกัน:
>   1. **5-Phase Lifecycle "Phase 3: IMPLEMENT"** — ตำแหน่งของเราใน project methodology (BA → SD → UX → TD → Impl → Harden → Deliver)
>   2. **Implementation Phases (P1/P2/P3/P4)** — การแบ่ง delivery ภายใน Phase 3 เอง (Foundation → Core → Polish → Stretch)
>
> คู่มือนี้เน้น #2 เพราะ #1 ครอบคลุมโดย `.agents/development-guide/full-journey.md` และ `methodologies/full-track/constitution/ai-native-development-runbook.md`

---

## ภาพรวม Flow

```
┌────────────────────────────────────────────────────────────────┐
│  ผ่าน Design Phase (5-Phase Lifecycle Phase 1+2) แล้ว           │
│  มี docs/design-docs/08-product-breakdown.md                   │
│     (work inventory + SD Phase Hints + per-task metadata)     │
│  มี docs/design-docs/07-future-evolution.md                    │
│     (scaling triggers + Evolution Sequence)                   │
│  มี docs/adr/ + docs/api-specs/                                │
│  มี docs/technical-design/02, 03, 04 (Impl Planner อ่าน SD-07/08 โดยตรง)│
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-plan  →  Planner Agent สร้าง PHASE-GROUPED plan         │
│  Persona: .agents/skills/andm-impl-planner/SKILL.md                 │
│  Output: docs/state/impl-plan.md + deferred-ac-registry.md     │
│                       + operator-action-registry.md            │
│                                                                │
│  ⭐ Core value:                                                 │
│  1. อ่าน SD Phase Hints + Evolution Sequence                   │
│  2. รัน phase assignment rules ของตัวเอง (independent)          │
│  3. เปรียบเทียบ: align หรือ diverge?                            │
│  4. เขียน Phasing Rationale บันทึก honor/override + เหตุผล      │
│  5. จัด P1 Foundation → P2 Core → P3 Polish → P4 Stretch       │
│  6. กำหนด Phase Gates (9 testable exit rows incl. Tier 1.5     │
│     Walk + Rollback plan)                                      │
│  7. Initialize 2 registries (deferred-AC + operator-action)    │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-plan-review all  →  Plan Reviewer Agent (10 dimensions) │
│  Persona: .agents/skills/andm-impl-plan-reviewer/SKILL.md      │
│  Output: docs/state/impl-plan-claim-review-and-rebuttal/       │
│          claim-review-XX.md                                    │
│  ⭐ Mirror BA/SD/UX/TD review pattern — plan ห้าม start         │
│     /impl-task ก่อนผ่าน review (Shark CMS 2026-04 lesson)     │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              ┌────────────────────────────┐
              │ มี CRITICAL/HIGH findings?  │──Yes──▶ /impl-plan-rebuttal claim-review-XX.md
              └───────┬────────────────────┘                       │
                      │ No                                          ▼
                      ▼                              docs/state/impl-plan-...
              ⏸️ HALT — User approve phase shape       /rebuttal-round-XX.md
                       + hint alignment                              │
                       ▼                                            │
              ◀──────────────────────── loop until ✅ ◀─────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  TIER 1 — TASK CLOSURE                                         │
│  /impl-task IMPL-001  →  Engineer Agent implement              │
│  Persona: .agents/skills/andm-impl-engineer/SKILL.md           │
│  Auto-detect size → XS-S / M / L-XL process                   │
│  Output: working code + tests + commit + 3-file state          │
│          propagation (impl-plan + overview + handoff)          │
│                                                                │
│  ⚠️ Pre-flight blockers (engineer halts if any present):       │
│   - Open AMEND obligations (amendment-log.md Status: 🔄 Open)  │
│     → /next Check 0.5 priority #3 — close obligations first   │
│   - Pending OPS rows (operator-action-registry.md)             │
│     → /next Check 5.7 — operator clears or pivot               │
│   - Expired Deferred-AC rows (deferred-ac-registry.md)         │
│     → /impl-task Phase 1.3.2 HALTs — resolve / renew (max 2)  │
│     → escalate via /impl-plan-review all if AC invalid         │
│   - Open backtrack (backtrack-log.md) — /next Check 0          │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              ┌─────────────────────┐
              │ tasks เหลืออยู่ไหม?  │──Yes──▶  /impl-task IMPL-002
              └───────┬─────────────┘                  ▲
                      │ No                              │
                      ▼                                 │
                                                        │
┌────────────────────────────────────────────────────────────────┐
│  TIER 1.5 — EXPLORATORY WALK (mandatory before Phase Gate)     │
│  Engineer (or operator) — 30-min non-scripted walk             │
│  Cover: every collection / view / locale / role / theme        │
│  Output: docs/state/_session-handoff/                          │
│          <YYYYMMDD>-phase<N>-exploratory-walk.md               │
│  → File CRITICAL findings as IMPL-FIX-* tickets                │
│  → Resolve via /impl-task ──────────────────────────────────────┘
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-review all  →  Code Reviewer Agent (13 dimensions)      │
│  Persona: .agents/skills/andm-code-reviewer/SKILL.md           │
│  Output: docs/code-review/review-round-XX.md                   │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /impl-review-fix review-round-XX.md  →  Fix findings          │
│  Output: docs/code-review/fix-round-XX.md + code fixes         │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              ┌───────────────────────────┐
              │ ยังมี CRITICAL/HIGH ไหม?  │──Yes──▶  /impl-review all
              └───────┬───────────────────┘
                      │ No
                      ▼
┌────────────────────────────────────────────────────────────────┐
│  TIER 2 — PHASE GATE (Empirical Demo + 9 gate rows)            │
│  /impl-task IMPL-P<N>-GATE  →  รัน empirical E2E demo บน       │
│  deployed/running stack + drain Deferred-AC Registry +         │
│  verify Operator Action Registry empty + tick 9 gate rows     │
│  (Structural / Empirical Demo / Tier 1.5 Walk / Live-stack    │
│   health / Code Review (Dim #11/#12/#13) / NFR / Deferred-AC  │
│   drain / Rollback plan / Docs)                                │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              Phase ปิด ✅ → next Phase หรือ → Harden Phase
```

> **Three-Tier Closure ป้องกัน Phase Gate Hallucination:** task `[x]` ครบ ≠ phase done. ห้าม report "phase complete" จาก Tier 1 อย่างเดียว — `/next` Check 6 ตรวจทั้ง 3 tiers + forbidden closure patterns. ดู CLAUDE.md § Glossary § Phase Gate Hallucination + Exploratory Walk.

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สร้าง Implementation Plan (Phase-Grouped with SD Hints)

```
/impl-plan 1
```
หรือ
```
/impl-plan initial
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Workflow Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → product-breakdown → design docs
2. **Workflow Phase 1 — Load Context:** อ่าน:
   - Work inventory + **Phase Hints (Suggested)** + **Per-Task Metadata** จาก `08-product-breakdown.md`
   - Architecture + **Evolution Sequence** จาก `07-future-evolution.md`
   - ADRs, API specs, TD handoff, service rules
   - **1.1 Extract SD hints** เข้า scratch table (Evolution Sequence + Phase Hints + metadata)
3. **Workflow Phase 2 — Decompose & Size:** แตก epics/stories เป็น tasks → **assign scope tag** (`[api]`/`[web]`/`[worker]`/`[slice]`) → size (XS-XL) → identify dependencies. Cross-layer task ที่ 1 session จบ = `[slice]`; L/XL cross-layer → decompose เป็น **per-slice sub-tasks by default** (ไม่ใช่ per-layer). ดู §Vertical Slicing Strategy ใน `andm-impl-planner/SKILL.md` สำหรับ decision tree
4. **Workflow Phase 2.5 — ⭐ Implementation Phase Decomposition (Option C)** (core value):
   - **2.5.1** เลือก **phase shape** (default: P1 Foundation → P2 Core → P3 Polish → P4 Stretch, หรือ custom ถ้า SD suggest)
   - **2.5.2** **Consume SD hints** protocol:
     - Step A: อ้างอิง scratch table จาก Phase 1.1
     - Step B: สำหรับแต่ละ task รัน phase assignment rules อย่าง independent (Dependency → MoSCoW → Risk → Value → Service-coupling)
     - Step C: เปรียบเทียบ result ของตัวเองกับ SD hint:
       - ✅ **Align** → record as aligned
       - ⚠️ **Diverge** → use own answer, document เหตุผล
       - 🔴 **Violation** (ขัด Evolution Sequence) → STOP, escalate via `/backtrack sd`
       - ◻️ **No hint** → use own answer directly
   - **2.5.3** **Validate** — ไม่มี forward references + ไม่ขัด Evolution Sequence
   - **2.5.4** เขียน **phase gates** (testable exit criteria) ต่อ phase
5. **Workflow Phase 3 — Phase + Dependency Graph:** สร้าง Mermaid diagram 2 แบบ (phase-level + task-level colored by phase)
6. **Workflow Phase 4 — Output:** สร้าง `docs/state/impl-plan.md` พร้อม **SD Hint Alignment audit trail** ใน Phasing Rationale

#### ⏸️ HALT — Agent หยุดรอ approve

Agent จะแสดง summary:
```
Sprint 1 Plan (Phase-Grouped, Option C with SD Hints):

Phasing: P1 Foundation → P2 Core → P3 Polish
Phase Shape Rationale: Foundation ต้องครบก่อนเริ่ม user-facing features;
                       P2 เน้น primary user journey; P3 เสริม observability

SD Hint Alignment:
  Evolution Sequence (from 07-future-evolution.md):
    ✅ E1 (auth extraction) → honored in P1 (IMPL-002)
    ✅ E2 (user migration)  → honored in P2 (IMPL-010)
    ⚠️ E4 (decommission)    → deferred to next sprint (not violation — no hard deadline)

  Phase Hints (from 08-product-breakdown.md):
    ✅ Aligned: IMPL-001, IMPL-002, IMPL-003 (all matched SD P1 suggestion)
    ✅ Aligned: IMPL-010, IMPL-011, IMPL-012 (all matched SD P2 suggestion)
    ⚠️ Diverged: IMPL-005 → SD suggested P2, moved to P1 because TD-04 revealed
                            it's a foundational DB migration blocking multiple P1 tasks
    ◻️ No hint: IMPL-025 (added during TD refinement) → assigned P3 by MoSCoW+Risk

  Divergence rate: 1/15 (7%) — within expected range

| Phase | XS | S | M | L | XL | Total |
|-------|----|----|----|----|----|-------|
| P1    | 1  | 3  | 2  | 0  | 0  | 6    |
| P2    | 0  | 2  | 3  | 1  | 0  | 6    |
| P3    | 2  | 0  | 1  | 0  | 0  | 3    |

Cross-phase dependency check: ✅ no forward references
Evolution Sequence check:     ✅ all honored
Phase gates:
  P1 → dev env runs e2e + auth smoke test passes
  P2 → user can complete primary flow e2e
  P3 → all Must/Should done + p95 < 200ms

Recommend starting with: IMPL-001 (S, api — DB schema setup) [P1]
```

**User ตอบ:**
- `approve` → plan ถูกบันทึก
- `merge P2 and P3` → re-plan ด้วย 2 phases
- `P4 ใส่ด้วย` → เพิ่ม stretch phase
- `ปรับ IMPL-003 เป็น L` → แก้ size แล้ว approve
- `เพิ่ม task สำหรับ seed data` → เพิ่มแล้ว approve

#### Output:
```
docs/state/impl-plan.md
```
(มี phasing rationale + phase sections + phase gates + task list ต่อ phase)

---

### Step 2: Implement ทีละ Task

```
/impl-task IMPL-001
```
หรือ
```
/impl-task สร้าง auth login API endpoint
```

#### Auto-Detect Size → เลือก Process อัตโนมัติ:

| Size | ตัวอย่าง | Process |
|------|---------|---------|
| **XS-S** | เพิ่ม env variable, สร้าง simple CRUD (`[api]`/`[web]`/`[worker]`) | Single prompt: implement → test → commit |
| **M** | Auth login flow (single-layer `[api]`) **หรือ** thin `[slice]` cross-layer ที่ 1 session จบ (form + endpoint + DB insert) | 3-step: plan → implement+test → self-review |
| **L-XL** | Feature ข้าม layer แต่ 1 session ไม่จบ | **Decompose เป็น per-slice sub-tasks** (IMPL-010a/010b/010c — thin vertical slices) — each sub-task ยิง end-to-end. Per-layer decomp (model → repo → service → controller) อนุญาตเฉพาะเมื่อ API spec locked + DB migrated + layers integration-independent |

#### ตัวอย่าง XS-S (Single Prompt):

```
Agent: "Task IMPL-001 detected as S → using Single Prompt process"
Agent: สร้าง DB migration + entity → เขียน test → run test ✅ → commit
Agent: "[feat:api] add articles table migration
        Why: Product breakdown requires content CRUD — schema must exist first"
```

#### ตัวอย่าง M (3-Step):

```
Agent: "Task IMPL-003 detected as M → using 3-Step process"

Step 1 (Plan):
  - แก้ไข: auth.service.ts, auth.controller.ts, auth.test.ts
  - สร้างใหม่: refresh-token.service.ts

Step 2 (Implement + Test):
  - สร้าง service + controller + tests
  - Run tests ✅

Step 3 (Self-Review):
  - ✅ Security: JWT validation ครบ, HttpOnly cookie
  - ✅ Error handling: invalid token → 401
  - Commit + handoff update
```

#### ตัวอย่าง L (Per-Slice Decomposition — default pattern):

```
Task IMPL-007 "User Registration" (L, cross-layer) →
Planner decompose เป็น 3 thin slices:
  IMPL-007a [slice] (M) — happy-path registration (form → POST /register → redirect)
  IMPL-007b [slice] (S) — validation + error UX (client + server)
  IMPL-007c [slice] (M) — email verification flow

Each sub-task ยิง end-to-end + commit แยก per-service + update handoff ทั้ง api+web
```

```
/impl-task IMPL-007a →

Agent: "Task IMPL-007a detected as M [slice] → 3-Step process (cross-layer)"

Step 1 (Plan):
  - services/api/: auth.controller.ts, auth.service.ts, users.repo.ts
  - services/web/: app/register/page.tsx, components/register-form.tsx

Step 2 (Implement + Test):
  - POST /register endpoint + integration test
  - Register form page + e2e test
  - Run tests ✅

Step 3 (Self-Review):
  - ✅ Contract alignment: form payload === API schema (verified ใน single session)
  - Commit แยก 2 ก้อน:
      [feat:api] POST /register endpoint
      [feat:web] registration form page
  - Update handoff: ทั้ง api/handoff.md + web/handoff.md
```

#### ตัวอย่าง XL (Per-Layer Exception — contract locked):

```
Task IMPL-020 "Payment Integration" (XL) —
Conditions ครบ: (a) API spec locked ใน payments.yaml แล้ว (b) DB migration landed P1 (c) layers independent
Planner decompose per-layer:
  IMPL-020-api (M) — /api/payments endpoints
  IMPL-020-web (M) — checkout UI (ใช้ mock จนกว่า API พร้อม)
  IMPL-020-worker (M) — webhook handler

รัน serial หรือ parallel (ถ้า scope-isolated). Per-layer ok เพราะ contract ไม่ drift
```

---

### Step 3: ทำซ้ำจนครบ Sprint

```
/impl-task IMPL-002
/impl-task IMPL-003
/impl-task IMPL-004
...
```

- Agent จะ **อ่าน handoff ก่อนเริ่มทุกครั้ง** เพื่อรู้สถานะล่าสุด
- Agent จะ **ตรวจ dependencies** ก่อนเริ่ม — ถ้า dependency ยังไม่เสร็จจะแจ้งเตือน
- Agent จะ **update handoff** หลังจบแต่ละ task

---

### Step 3.5: Code Review (หลัง Sprint Tasks เสร็จ)

เมื่อ tasks ทั้งหมดใน sprint เสร็จแล้ว ให้รัน code review ก่อนเข้า Harden Phase:

```
/impl-review all
```

Agent จะตรวจ code ตาม **13 dimensions**: Security, Business Logic, Error Handling, Performance, Over-Engineering, Cross-Service Consistency, Test Coverage, Architecture Compliance, TD Compliance, Test Code Quality, Empirical AC Closure (Dim #11), Functional CRUD Walk (Dim #12), Configuration Completeness (Dim #13). Full list: `andm-code-reviewer/SKILL.md § Phase 1`

เมื่อได้ review findings:

```
/impl-review-fix docs/code-review/review-round-01.md
```

Agent จะ:
1. วิเคราะห์แต่ละ finding → Accept/Reject/Partial
2. ตรวจ pattern scope (grep ดูว่ามี pattern เดียวกันที่อื่นไหม)
3. **⏸️ HALT** แสดง verdict table → รอ user approve
4. แก้ code → cascade fix → เพิ่ม tests → micro-commits → update handoff

ทำซ้ำจนไม่มี CRITICAL/HIGH ค้าง (ปกติ 1-2 rounds)

**📖 Guide:** `.agents/development-guide/impl-review-workflow.md`

---

### Step 4: Phase Gate Check → ไป Phase ถัดไป หรือ Harden

เมื่อทำ tasks ครบใน phase ปัจจุบัน + code review ผ่านแล้ว ให้ตรวจ **Phase Gate** จาก plan:

```markdown
### P1 — Foundation Gate
- [x] Acceptance: dev env runs e2e + auth smoke test passes
- [x] Code review: no CRITICAL/HIGH open
- [x] NFR check: n/a for P1
- [x] Docs: handoff files updated
- [x] Demo: "login flow works end-to-end"
```

- ถ้า **phase gate ยังไม่ผ่าน** → กลับไปทำ tasks ที่ค้าง หรือสร้าง task เพิ่ม ถ้าพบ gap ระหว่าง implement
- ถ้า **phase gate ผ่าน**:
  - ยังมี phase ถัดไป → เริ่ม phase ถัดไป (continue `/impl-task` หรือเริ่ม sprint ใหม่ด้วย `/impl-plan 2`)
  - จบทุก phase แล้ว → เข้า Harden Phase
    ```
    /red-team all
    ```

---

## ⭐ Understanding Implementation Phases (P1 → P4) + SD Hints (Option C)

> ส่วนนี้อธิบายเชิงลึกว่า Implementation Phases ทำงานยังไง พร้อมกับ contract ระหว่าง SD hints และ Impl Planner decisions

### ทำไมต้องแบ่ง Phase?

| เหตุผล | คำอธิบาย |
|--------|---------|
| **Ship value incrementally** | ทุก phase ต้องส่งมอบของที่ใช้ได้จริง — ไม่ใช่ครึ่งทางของ internal layer |
| **De-risk early** | งานเสี่ยง (tech ใหม่, perf-critical, external integration) อยู่ phase ต้นๆ เพื่อให้ล้มเร็ว |
| **Honor dependencies** | Infrastructure (DB, auth) ต้องมาก่อน feature work — phase บังคับ order |
| **Rollback points** | Phase gate = จุด rollback ธรรมชาติถ้า phase ถัดไปพบว่า design ผิด |
| **Stakeholder communication** | "จบ P1 Foundation แล้ว" สื่อสารง่ายกว่า "ทำ 23/87 tasks แล้ว" |

### SD Hints Contract (Option C)

**SD ให้ 3 ประเภทของ hints:**

| Hint Type | ที่ | Strength | เมื่อไหร่ Impl Planner honor |
|-----------|-----|---------|----------------------------|
| **Evolution Sequence** (E1/E2/...) | `07-future-evolution.md` | 🔴 **HARD** (backed by ADR) | เสมอ — override ด้วย `/backtrack sd` เท่านั้น |
| **Phase Hints** (P1/P2/P3/P4 suggestions) | `08-product-breakdown.md` | 🟡 **SOFT** (architectural suggestion) | Default — override ได้พร้อม document reason |
| **Per-Task Metadata** (risk, must_precede, unlocks) | `08-product-breakdown.md` | 🟢 **INPUT** data | เป็น input ของ assignment rules |

**ตัวอย่าง Evolution Sequence:**
```
| # | Step | Must Precede | Rationale |
|---|------|--------------|-----------|
| E1 | Extract auth service | E2, E3 | ADR-005: unified JWT |
| E2 | Migrate users to new auth | E4 | Cannot test without real users |
| E3 | Refactor payment to new auth | — | ADR-007 |
| E4 | Decommission legacy auth | — | Safe only after E2 validated |
```

**ตัวอย่าง Phase Hints:**
```
### Suggested P1 — Foundation
- IMPL-001 (DB schema) — reason: all downstream work depends
- IMPL-002 (Auth extraction) — reason: Evolution E1 (ADR-005)
- IMPL-003 (Auth middleware) — reason: unblocks auth-protected endpoints

### Suggested P2 — Core
- IMPL-010 (User migration) — reason: Evolution E2
- IMPL-011 (Order endpoint) — reason: primary user value FR-001
```

### Impl Planner's Consume-Compare-Document Flow

```
┌─────────────────────────┐
│ 1. Read SD hints         │
│    (Evolution Sequence   │
│     + Phase Hints +      │
│     per-task metadata)   │
└──────────┬──────────────┘
           ▼
┌─────────────────────────┐
│ 2. Run own phase         │
│    assignment rules      │
│    (Dependency → MoSCoW  │
│     → Risk → Value →     │
│     Service-coupling)    │
└──────────┬──────────────┘
           ▼
┌─────────────────────────┐
│ 3. Compare result vs     │
│    SD hint for each task │
└──────────┬──────────────┘
           ▼
┌─────────────────────────────────────────┐
│ 4. Classify each task:                   │
│    ✅ Align      — same answer            │
│    ⚠️ Diverge    — different + reason     │
│    🔴 Violation  — contradicts Evolution  │
│                    → STOP, /backtrack sd  │
│    ◻️ No hint    — use own rules          │
└──────────┬──────────────────────────────┘
           ▼
┌─────────────────────────┐
│ 5. Write Phasing         │
│    Rationale audit trail │
│    (mandatory)           │
└─────────────────────────┘
```

**ตัวอย่าง Phasing Rationale ที่ดี:**

```markdown
### Phase Shape Choice
เลือก P1 Foundation → P2 Core → P3 Polish (skip P4 — no Could-Haves in sprint).
Inherited SD's suggested shape; adjusted only IMPL-005 assignment based on TD discovery.

### SD Hint Alignment
Evolution Sequence:
  ✅ E1 honored (IMPL-002 in P1)
  ✅ E2 honored (IMPL-010 in P2)
  ⚠️ E4 deferred to next sprint — decommission not blocking current delivery

Phase Hints:
  ✅ Aligned: IMPL-001, IMPL-002, IMPL-003, IMPL-010, IMPL-011 (5/6 matched)
  ⚠️ Diverged: IMPL-005 → SD suggested P2, moved to P1
      Reason: TD-04 (database-design.md) revealed IMPL-005 is a foundational
              schema migration that unblocks IMPL-001, IMPL-002, and IMPL-003.
              Moving to P1 prevents forward reference in P1→P2 dependency chain.

Divergence rate: 1/6 task hints overridden (17%) — within normal range.
```

### Complete Worked Example: 10-Task Scratch → Audit Trail Auto-Generation

> ตัวอย่างเต็มรูปแบบ แสดง flow จาก scratch table → generated audit trail สำหรับ realistic 10-task sprint

**Scenario:** E-commerce checkout sprint, 10 tasks, mix ของทุก classification

**Step 1 — Impl Planner's Scratch Table (from Phase 1.1, filled during Phase 2.5.2):**

```
| Task     | SD Hint Phase | Risk | Must Precede       | Unlocks            | Arch Rationale        | My Rule Result | Classification                                              |
|----------|---------------|------|--------------------|--------------------|------------------------|----------------|-------------------------------------------------------------|
| IMPL-001 | P1            | low  | IMPL-002, IMPL-003 | DB-dependent work  | foundational schema    | P1             | ✅ Align                                                   |
| IMPL-002 | P1            | high | IMPL-004           | auth-protected API | ADR-005 E1             | P1             | ✅ Align                                                   |
| IMPL-003 | P1            | low  | IMPL-005           | DB migrations      | foundational           | P1             | ✅ Align                                                   |
| IMPL-004 | P2            | med  | IMPL-006           | Evolution E2       | user auth flow         | P2             | ✅ Align                                                   |
| IMPL-005 | P2            | high | IMPL-006, IMPL-007 | order processing   | primary value FR-001   | P1             | ⚠️ Diverge (TD-04 found this is a migration blocker)       |
| IMPL-006 | P2            | med  | IMPL-008           | checkout flow      | Must-Have FR-002       | P2             | ✅ Align                                                   |
| IMPL-007 | P2            | low  | —                  | —                  | Must-Have FR-003       | P2             | ✅ Align                                                   |
| IMPL-008 | P3            | low  | —                  | —                  | Should-Have FR-010     | P4             | ⚠️ Diverge (stakeholder confirmed Could-Have not Should)   |
| IMPL-009 | —             | —    | —                  | —                  | —                      | P3             | ◻️ No hint                                                 |
| IMPL-010 | —             | —    | —                  | —                  | —                      | P3             | ◻️ No hint                                                 |
```

**Step 2 — Silent Copy Detector Check:**

```
H (tasks with SD hint) = 8
A (✅ Align)            = 6
D (⚠️ Diverge)          = 2
V (🔴 Violation)        = 0
N (◻️ No hint)          = 2

Trigger? H > 5 AND D == 0 → FALSE (D = 2)
Result: Detector does NOT trigger. Proceed to audit trail generation.
```

**Step 3 — Auto-Generated Audit Trail (grouped from scratch table by Classification):**

````markdown
## Phasing Rationale

### Phase Shape Choice
Chose default P1→P2→P3 with optional P4 for overflow Should/Coulds.
Inherited SD's suggested shape with minor adjustments: IMPL-005 moved earlier
(TD-04 discovery), IMPL-008 pushed to stretch (stakeholder re-prioritization).

### SD Hint Alignment (Option C Audit Trail)

**Evolution Sequence (from 07-future-evolution.md):**
- ✅ E1 (auth extraction, IMPL-002) → honored in P1
- ✅ E2 (user migration, IMPL-004) → honored in P2

**Phase Hints (from 08-product-breakdown.md):**

*Aligned (6 tasks):*
- ✅ IMPL-001 (DB schema) → SD hint P1 = my result P1
- ✅ IMPL-002 (auth extraction) → SD hint P1 = my result P1
- ✅ IMPL-003 (DB migrations) → SD hint P1 = my result P1
- ✅ IMPL-004 (auth flow) → SD hint P2 = my result P2
- ✅ IMPL-006 (checkout flow) → SD hint P2 = my result P2
- ✅ IMPL-007 (product catalog) → SD hint P2 = my result P2

*Diverged (2 tasks):*
- ⚠️ IMPL-005 (order processing) → SD suggested P2, moved to **P1**
  - **Reason:** TD-04 (database-design.md § Migration Plan) revealed that
    IMPL-005 includes a foundational schema migration that unblocks IMPL-001
    and IMPL-003. Moving to P1 prevents a forward reference in the
    dependency chain (P1 tasks would otherwise depend on a P2 task).
- ⚠️ IMPL-008 (wishlist feature) → SD suggested P3, moved to **P4 Stretch**
  - **Reason:** Stakeholder survey (2026-04-05) confirmed wishlist is a
    Could-Have, not a Should-Have. SD's MoSCoW classification in 02-high-level-architecture.md § Requirements Traceability (v1.2: was 01-requirements.md)
    marked it as Should, but the refined stakeholder feedback downgrades it.
    Keeping in P3 would dilute the Polish phase gate with non-essential work.

*No SD hint (2 tasks):*
- ◻️ IMPL-009 (observability dashboards) → assigned P3 by NFR rule (NFR-005)
- ◻️ IMPL-010 (email notifications) → assigned P3 by Should-Have rule

**Divergence Summary:** 2 out of 8 SD-hinted tasks overridden (25%) — slightly
above the typical 10-20% range but all divergences have concrete TD or
stakeholder-driven justification. No Evolution Sequence violations.
````

**Notes on the example:**

- Every task has a row in the scratch, and every row has a non-empty Classification → Step D completeness gate passes ✅
- Silent Copy Detector did not trigger (2 divergences > 0) — good
- Audit trail is grouped directly from the scratch (not typed separately)
- Both divergences cite specific evidence (TD-04, stakeholder survey date)
- No hint tasks are explicitly listed with rule citation (NFR-005, Should-Have rule)

### Vocabulary Cheatsheet (Say This, Not That)

> **Canonical definitions** อยู่ที่ `CLAUDE.md § Glossary` — ที่นี่คือ quick reference สำหรับการพูดและเขียน

| Say this | Not this | Why |
|----------|----------|-----|
| **Phase Hints (Suggested)** | Phase Plan / Assignment / Schedule / Roadmap | "Plan" implies SD owns decision; SD only hints |
| **Lifecycle Phase 3: IMPLEMENT** | "Phase 3" / "the implementation phase" (ambiguous) | Disambiguates from Implementation Phase P1-P4 |
| **Implementation Phase P1/P2/P3/P4** | Sprint 1/2/3 / Milestone 1 | P-phases are architectural, not time-boxed |
| **Evolution Step E1 (ADR-005)** | Migration Step 1 / Wave 1 | E-steps must cite ADR rationale |
| **Honored / Diverged / No hint** | "Followed SD" / "Changed SD" / "Ignored" | Canonical audit-trail vocabulary |
| **"unblocks" / "depends on" / "Must-Have"** | "before launch" / "after MVP" / "when ready" | Architectural language, not calendar |

> **Quick rule:** ถ้าคำที่จะใช้บ่งบอก *when* (เวลา, sprint, calendar, capacity) → ผิด ให้ใช้คำที่บ่งบอก *why* (dependency, architectural reason, MoSCoW, risk) แทน

### No-Hints Path (When SD Provides No Sequencing Hints)

> **Pure-independent-rules runs are 100% legitimate.** Not every project needs Evolution Sequence or Phase Hints.

**When this happens:**
- Greenfield monolith with no cross-service dependencies
- Simple CRUD application with obvious dependency order
- Team is small and architect decides SD ordering hints would add no value

**What Impl Planner does:**
1. Scratch table (Phase 1.1) is empty: *"No SD hints — running independent rules only"*
2. Phase 2.5 Step A (consume hints) → skipped
3. Phase 2.5 Step B (independent rules) → run normally
4. Phase 2.5 Step C (compare) → skipped (nothing to compare)
5. Step D completeness gate → every task still needs Classification, but all will be `◻️ No hint`
6. Silent Copy Detector → does not trigger (H = 0)
7. Phasing Rationale audit trail states: *"No SD hints provided; all tasks assigned by independent Dependency→MoSCoW→Risk→Value→Service-coupling rules. Classification: all ◻️ No hint."*

**This is NOT a defect and NOT a backtrack trigger.** `sd-review` will not raise a finding for missing Evolution Sequence / Phase Hints. `/impl-plan` will not warn or prompt.

### Default Phase Taxonomy

| Phase | Purpose | Phase Gate Example | % Total Work |
|-------|---------|---------------------|--------------|
| **P1: Foundation** | Infra, shared plumbing, auth, DB schema, CI/CD | Dev env รัน e2e + auth smoke test ผ่าน | 20-30% |
| **P2: Core** | MVP slice — primary user value | Primary flow ใช้ได้ e2e + critical tests ผ่าน | 40-50% |
| **P3: Polish** | Should-Haves, NFR targets, observability | Must + Should ครบ + perf ตาม NFR | 20-30% |
| **P4: Stretch** *(optional)* | Could-Haves, experiments | Could-Haves ship หรือ defer to backlog | 0-10% |

### Custom Phase Shapes (เมื่อ default ไม่ fit)

| Project Type | Phase Shape |
|--------------|-------------|
| **API-only backend** | P1 Contracts → P2 Core Endpoints → P3 Hardening |
| **Data migration** | P1 Shadow Write → P2 Dual Read → P3 Cutover → P4 Decommission |
| **Greenfield SaaS** | P1 Foundation → P2 Paid Onboarding → P3 Billing + Admin → P4 Growth |
| **Brownfield refactor** | P1 Test Net → P2 Extract → P3 Replace → P4 Delete |

ทุก custom shape ต้องมี **Phasing Rationale** อธิบายว่าทำไมเลือก shape แบบนี้สำหรับ project นี้ (1 paragraph, อ้าง MoSCoW + risk + dependency + user value)

### Phase Assignment Rules (ใช้ตามลำดับ first-match)

1. **Dependency rule** — task ไปไม่ได้เร็วกว่า phase ล่าสุดของ hard dependencies
2. **MoSCoW rule** — Must → P1/P2, Should → P3, Could → P4, Won't → ไม่อยู่ใน plan
3. **Risk rule** — งานเสี่ยงสูงไป phase เร็วสุดที่ dependency ยอมให้ (fail fast)
4. **Value rule** — ใน phase เดียวกัน งานที่ unlock user value มาก่อน
5. **Service-coupling rule** — tasks แตะ module/file เดียวกัน ควรอยู่ phase เดียวกัน (ลด merge pain)

### Red Flag: Cross-Phase Dependency ผิดทาง

ถ้าพบว่า task ใน P1 depend บน task ใน P2 (forward reference):

- **หยุดแล้ว re-examine** — มักจะเป็น phase ผิด ไม่ใช่ dependency
- **Option A:** ย้าย P1 task ไป P2 (หรือหลังจากนั้น)
- **Option B:** แยก foundation stub (interface/contract เท่านั้น) ไว้ P1, implementation จริงไว้ P2
- **Option C:** คิดใหม่ — อาจต้อง merge P1+P2 หรือเพิ่ม P1.5
- **ห้าม:** ปล่อยให้ forward reference ค้างใน plan

### Phase Gate Discipline

ทุก phase ต้องมี **testable exit criteria** — ไม่มี hand-waving. ถ้าเขียน gate ที่ test ไม่ได้ แปลว่า phase scope ไม่ชัด — กลับไป re-scope

```markdown
❌ "phase เสร็จเมื่อ feature พร้อมใช้"           ← ใช้ไม่ได้, ไม่ testable
✅ "phase เสร็จเมื่อ smoke test
    'login → create order → checkout' ผ่าน,
    p95 < 300ms, ไม่มี CRITICAL/HIGH open"    ← testable, clear
```

### เมื่อ Phase Gate ไม่ผ่าน

- **Gate fail แต่ว่า tasks ใน plan ครบ:** พบ gap — สร้าง task เพิ่ม ใน phase เดิม (update impl-plan.md)
- **Gate fail เพราะ design ผิด:** `/backtrack sd` หรือ `/backtrack td` — อย่า patch ใน code
- **Gate fail เพราะ requirement ผิด:** `/backtrack ba`
- **Gate fail เพราะ risk ไม่คาดคิด:** re-plan phase — อาจ split phase หรือ merge กับ phase ถัดไป

---

---

## Resume & Handoff Scenarios

### Scenario 1: กลับมาทำต่อ (ไม่รู้ทำถึงไหน)

```
/impl-task resume
```

หรือ
```
/impl-task next
```

Agent จะ:
1. อ่าน **handoff files** ทุก module → หา task ล่าสุดที่เสร็จ + task ที่ค้างอยู่
2. อ่าน **impl-plan** → หา tasks ที่ acceptance criteria ยังไม่ครบ
3. แสดง **Resume Analysis**:
   ```
   📋 Resume Analysis:
   - Last completed: IMPL-003 (2026-03-26)
   - In-progress: IMPL-004 (2/5 acceptance criteria done)
   - Blockers: none

   → Resuming IMPL-004 — JWT refresh token rotation
   ```
4. เริ่มทำ task ต่อ (หรือรอ user redirect)

### Scenario 2: รับงานต่อจากคนอื่น / Agent อื่น

```
/impl-task resume
```

**สิ่งที่ Agent ทำเหมือน Scenario 1** — แต่จะอ่าน handoff ละเอียดกว่า:

- ตรวจ **"Known issues or tech debt"** ที่ agent ก่อนหน้าทิ้งไว้
- ตรวจ **git log** ล่าสุด — ดูว่า commit สุดท้ายตรงกับ handoff ไหม
- ถ้า handoff กับ code ไม่ตรงกัน → แจ้ง user ก่อนเริ่ม

```
📋 Resume Analysis:
- Handoff by: previous session (2026-03-25)
- Last completed: IMPL-005
- Known issues: "API rate limiter ยังไม่มี test สำหรับ concurrent requests"
- Next suggested: IMPL-006

⚠️ Note: Handoff mentions tech debt on IMPL-005
→ Recommend: fix tech debt first, then start IMPL-006

Proceed with IMPL-006 or fix debt first?
```

### Scenario 3: ไม่มี impl-plan เลย

```
/impl-task resume
```

Agent จะแจ้ง:
```
❌ ไม่พบ docs/state/impl-plan.md
→ ต้องสร้าง plan ก่อน: /impl-plan 1
```

### Quick Reference — Resume Commands

| สั่งว่า | ผลลัพธ์ |
|---------|--------|
| `/impl-task IMPL-003` | ทำ task เฉพาะที่ระบุ |
| `/impl-task resume` | หา task ที่ค้าง → ทำต่อ |
| `/impl-task next` | หา task ถัดไปที่พร้อมทำ |
| `/impl-task continue` | เหมือน resume |
| `/next` | ดูสถานะทั้งโปรเจค (ไม่ใช่แค่ impl) |

---

## Daily Workflow

```
🌅 เช้า
├─ เช็ค docs/state/overview.md — ดูสถานะ modules
├─ เช็ค docs/state/{module}/handoff.md — ดู task ที่ค้าง
└─ เลือก task ถัดไปจาก impl-plan

🌞 กลางวัน
├─ /impl-task IMPL-XXX (2-3 tasks ต่อวัน)
├─ Review code ที่ Agent สร้าง
└─ ตัดสินใจ Architecture → เขียน ADR ถ้ามี

🌆 ก่อนเลิกงาน
├─ ตรวจ handoff files ว่า up-to-date
├─ Commit + Push
└─ (optional) สั่ง Agent ทำ task ข้ามคืน
```

---

## File Structure

```
.claude/commands/
  impl-plan.md                      ← /impl-plan command definition
  impl-task.md                      ← /impl-task command definition

.agents/skills/
  andm-impl-planner/SKILL.md             ← Planner persona (Tech Lead)
  andm-impl-engineer/SKILL.md            ← Engineer persona (Senior Full-Stack)

.claude/rules/
  api.md                            ← API service rules (tech stack ตาม CLAUDE.md)
  web.md                            ← Web service rules (tech stack ตาม CLAUDE.md)
  worker.md                         ← Worker service rules (tech stack ตาม CLAUDE.md)
  workflow.md                       ← Task sizing, commit, handoff
  security.md                       ← Security rules
  testing.md                        ← Testing rules

docs/state/
  impl-plan.md                      ← Current sprint plan (created by /impl-plan)
  overview.md                       ← Module status overview
  api/handoff.md                    ← API service handoff
  web/handoff.md                    ← Web service handoff
  worker/handoff.md                 ← Worker service handoff

services/
  api/                              ← Backend API (modified by /impl-task)
  web/                              ← Frontend Web (modified by /impl-task)
  worker/                           ← Background Worker (modified by /impl-task)
```

---

## Agent Personas

### Impl Planner (`.agents/skills/andm-impl-planner/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Tech Lead / Sprint Planner |
| **Mindset** | plan for execution, not for documents; **phase-first thinking** |
| **Owns** | `docs/state/impl-plan.md` **+ the entire phasing contract** (no one else decides *when* each task ships) |
| **Cannot modify** | design docs, ADRs, source code |
| **Key tools** | (1) **Implementation Phasing Strategy** — default P1→P4 taxonomy + phase assignment rules (Dependency → MoSCoW → Risk → Value → Service-coupling), (2) Task sizing matrix (XS-XL), (3) Phase gate checklists, (4) Cross-phase dependency validation, (5) **Vertical Slicing Strategy** — scope tag decision tree (`[api]`/`[web]`/`[worker]`/`[slice]`) + per-slice vs per-layer decomposition rules |

### Impl Engineer (`.agents/skills/andm-impl-engineer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Full-Stack Engineer |
| **Mindset** | ship working code with tests |
| **Can modify** | `services/api/`, `services/web/`, `services/worker/` |
| **Key tool** | Auto-detect size → select process + code review checklist |
| **Commit format** | `[type:service] description \n\n Why: reason` — `[slice]` tasks ให้ commit แยก per-service (เช่น `[feat:api]` + `[feat:web]`) ไม่ใช่ commit รวม |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้าระหว่าง implement พบปัญหาเหล่านี้ที่แก้ใน code ไม่ได้:

| Trigger | ตัวอย่าง | Backtrack To | Action |
|---------|---------|-------------|--------|
| **API design infeasible** | Endpoint ต้อง join 5 tables — performance ไม่ผ่าน | SD | `/backtrack sd` |
| **Architecture ไม่รองรับ** | Microservice boundary ผิด — distributed tx ทุกที่ | SD | `/backtrack sd` |
| **Data model ไม่ถูก** | Schema ไม่รองรับ query pattern จริง | SD | `/backtrack sd` |
| **Tech stack ไม่เหมาะ** | Library ไม่รองรับ feature ที่ต้องการ | SD | `/backtrack sd` |
| **Business rule ขัดแย้ง** | Rule A + Rule B ไม่สามารถ true พร้อมกัน | BA | `/backtrack ba` |
| **NFR ไม่ realistic** | "Response < 50ms" สำหรับ complex calc — infeasible | BA | `/backtrack ba` |

> ⚠️ อย่า workaround ใน code ถ้า root cause อยู่ที่ design — สร้าง technical debt
> **📖 Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/impl-task` เพื่อ fresh context
- **XS-S tasks ทำได้เร็วมาก** — สั่ง 3-5 tasks ต่อ session ได้
- **M tasks** ไม่ต้อง HALT — agent ทำจบได้ใน session เดียว
- **L-XL tasks** จะ HALT ทุก step — review ทุก step ก่อน approve
- **ตรวจ self-review checklist** ที่ agent ทำ — ถ้าพบ issue ให้แก้ก่อน approve
- **Handoff auto-update** — agent จะ update handoff ทุกครั้งที่จบ task สำคัญ
- **ปกติ 1-2 sprints** เพียงพอสำหรับ MVP
