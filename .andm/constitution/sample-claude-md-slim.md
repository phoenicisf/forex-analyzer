# [Project Name] - AI Development Rules

> AI Agent ทุกตัวต้องอ่านไฟล์นี้ก่อนเริ่มทำงาน
> อัปเดตล่าสุด: [วันที่]
>
> **Note:** นี่คือ slim template (~60 บรรทัด) สำหรับ root CLAUDE.md — รายละเอียดอยู่ใน `.claude/rules/*.md`
> <!-- ลบ note นี้เมื่อนำ template ไปใช้ในโปรเจคจริง -->

---

## 1. Project Overview

**ชื่อโปรเจค:** [ชื่อ]
**ประเภท:** [Web App / API / Mobile / Library]
**สถานะ:** [MVP / Production / Maintenance]
**เอกสารหลัก:** `docs/design-docs/` (ดู Section 8 สำหรับรายละเอียด)

<!-- AUTO-MANAGED:phase-status — generated/refreshed by /project-init from docs/state/impl-plan.md Phase Gate sections. Do NOT hand-edit unless project is in lean mode without impl-plan. -->

> 🔴 **READ FIRST — Three-Tier Closure Convention**
>
> A Lifecycle Phase is **complete** only when **all three tiers** close. ห้าม conclude "Phase X done" จาก Tier 1 อย่างเดียว — นั่นคือ **Phase Gate Hallucination** (เคยเกิดจริง: status agent อ่าน 290/291 [x] task ACs แล้ว report "Phase 3 almost done" ทั้งที่ P2/P3 Phase Gate ยัง `[ ]` หมด เพราะ tasks ปิดด้วย "deferred to operator-runtime").
>
> | Tier | What | Closure marker | Owner |
> |------|------|----------------|-------|
> | **Tier 1 — Task Closure** | Per-task ACs (`[x]` ครบ) — backend correctness asserted | `docs/state/impl-plan.md` task checklist | Impl Engineer |
> | **Tier 1.5 — Exploratory Walk** | 30-min non-scripted operator walk ทุก surface (collection / view / locale / role / theme) — หา functional defects ที่ scripted tests missed | `docs/state/_session-handoff/<date>-phase<N>-exploratory-walk.md` artifact + IMPL-FIX-* tickets resolved | Operator session (human or agent driving live UI) |
> | **Tier 2 — Phase Gate Closure** | Empirical end-to-end demo บน deployed/running system + cold-bootstrap health + Deferred-AC drained | `docs/state/impl-plan.md` "## Phase Gate" sections + `IMPL-Pn-GATE` task | Impl Engineer + Operator session |
>
> **Rule:** ถ้า task มี **E-AC** ที่ verifiable เฉพาะตอน deployed/running → ปิดด้วย structural test pass อย่างเดียวไม่ได้ ต้องมี evidence artifact (`docs/state/_session-handoff/<task-id>-evidence-*`). คำต้องห้าม: `[x]` + "deferred to operator-runtime" / "deferred per <task> precedent". ดู Glossary § Empirical Closure Discipline + Phase Gate Blocking + Exploratory Walk.
>
> **Why Tier 1.5 exists:** real-project audit (Shark CMS, 2026-04) ran 5 scripted Phase Gates (Tier 2 directly after Tier 1) → missed 9 functional defects ที่ 30-min non-scripted operator walk หาเจอใน 1 session. Scripted ≠ exploratory; complementary not substitutable.
>
> **Status snapshot** (sync จาก `docs/state/impl-plan.md`):
>
> | Phase | Tier 1 (Tasks) | Tier 1.5 (Walk) | Tier 2 (Phase Gate) |
> |-------|----------------|------------------|---------------------|
> | P1 Foundation | [✅/⚠️ N/M tasks] | [✅ artifact YYYY-MM-DD / ⚠️ stale / ❌ missing] | [✅ via IMPL-P1-GATE / ⚠️ open] |
> | P2 Core | [...] | [...] | [...] |
> | P3 Polish | [...] | [...] | [...] |
> | P4 Stretch | [...] | [...] | [...] |

## 2. Tech Stack

<!-- AUTO-MANAGED:tech-stack-table — the `Container` row is conditional on `cross_cutting.containerization.engine`: populated by /project-init when engine != "none"; removed when engine == "none" (fresh/regen modes); preserved as-is in merge mode if hand-customized. -->

| Layer | Technology |
|---|---|
| Language | [e.g. TypeScript strict mode] |
| Backend | [e.g. Node.js + Express] |
| Frontend | [e.g. Next.js 14 App Router] |
| Database | [e.g. PostgreSQL 16 + Redis] |
| Auth | [e.g. Keycloak] |
| Testing | [e.g. Jest + Supertest] |
| Container | [e.g. Docker Compose] |

## 3. Architecture Rules (critical only)

<!-- AUTO-MANAGED:deployment-line — the `Deployment:` bullet below follows the same conditional rule as the Container row in §2 (engine != "none" → populate; engine == "none" → remove on fresh/regen; preserve on merge). -->

- ใช้ [Architecture Style] — e.g. Modular Monolith / Clean Architecture
- Service Communication: [e.g. REST (sync) + Message Queue (async)]
- Deployment: [e.g. Monorepo, independently deployable containers]
- Data Ownership: [e.g. แต่ละ service own DB schema ของตัวเอง]
- **ห้าม** เขียน Business Logic ใน Controller
- **ห้าม** เรียก Repository จาก Controller ตรง — ต้องผ่าน Service
- รายละเอียด: `.claude/rules/architecture.md`

## 4. Security Rules (anti-patterns only)

- **ห้าม** hardcode secrets, API keys, connection strings
- **ห้าม** ใช้ string concatenation ใน SQL — ต้อง parameterized queries
- **ห้าม** return sensitive data (password hash, stack traces) ใน API response
- **ห้าม** trust client-side input โดยไม่ validate
- Automated enforcement: ESLint no-hardcoded-secrets + pre-commit hook + CI secret scanning
- รายละเอียด: `.claude/rules/security.md`

## 5. Git Rules

- Commit format: `[type] short description` + `Why:` explanation
- Types: feat, fix, refactor, test, docs, chore
- **ห้าม** force push ไป main/develop

## 6. Agent Workflow Rules

- เริ่มงาน: อ่าน CLAUDE.md → อ่าน handoff (single: current_handoff.md / monorepo: overview.md → {module}/handoff.md) → ทำงาน
- จบงาน: อัปเดต handoff เมื่อจบ feature / เปลี่ยน session / ข้ามวัน (ไม่ต้องทุก step ย่อย)
- Task size: XS-S ทำจบใน prompt เดียว / M แบ่ง 2-3 steps / L-XL ใช้ full decomposition
- ADR: ทุกการตัดสินใจ architecture → สร้าง `docs/adr/NNN-title.md`
- **Phase Gate ≠ Task Closure (three-tier)** — ดู §1 Three-Tier Closure Convention. Status reports + `/next` ต้อง reconcile ทั้ง 3 tiers (Tier 1 task / Tier 1.5 walk / Tier 2 Phase Gate); ห้ามใช้ Tier 1 อย่างเดียวสรุป "Phase complete". Engineer agents ห้ามปิด AC ด้วย `[x] + "deferred to operator-runtime"` — ใช้ `docs/state/deferred-ac-registry.md` แทน (ดู Glossary § Deferred-AC Registry + Exploratory Walk)
- **State Reconciliation (3-file propagation)** — ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**: (1) `impl-plan.md` (primary SoT — `[x]` AC, Phase Gate, audit log), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*` (transient pointer + artifact). ห้าม update เพียงไฟล์เดียว — drift ระหว่างไฟล์ทำให้ `/next` รายงานผิด, `/impl-task` หยิบ task ผิด, status agents hallucinate phase complete (ดู Glossary § State Single Source of Truth + State Reconciliation Discipline)
- **Plan QA cycle** — `/impl-plan` runs once → MUST follow with `/impl-plan-review all` → ถ้ามี CRITICAL/HIGH → `/impl-plan-rebuttal claim-review-XX.md` → loop until verdict ✅ Ready for Implementation Execution. ห้าม start `/impl-task` ก่อน plan ผ่าน review (mirror BA/SD/UX/TD review pattern)
- **UIR before close** — engineer พบว่าต้องการ operator action (set env var, fetch API key, accept ToS, run privileged step) ก่อนปิด task = ใช้ **UIR template** ใน Confusion Management Protocol → register Pending row ใน `docs/state/operator-action-registry.md` → ห้าม close `[x]` AC ที่ depend on action จนกว่า registry row Done + verified via `[config-audit]` evidence (ดู Glossary § User Input Required + Operator Action Registry)
- **Config-audit gate** — task ที่ consume env var / secret / API key / connection string / feature flag = ต้องมี ≥1 `[config-audit]` E-AC (Mandatory E-AC Trigger #8). Engineer enumerate config items + runtime introspect each resolved from real env (ไม่ใช่ hardcoded test value) + verify `.env.example` ↔ code refs sync. Code Review Dim #13 enforces
- **Frontmatter on deliverables (T1.1)** — ทุก BA/SD/TD/UX/QA/SPEC/DEC ต้องมี YAML frontmatter เป็นบรรทัดแรกของไฟล์ ก่อน `# title`: `summary` (≤200 chars) + `provenance` counts ({extracted, inferred, ambiguous} จาก marker จริงเท่านั้น) + `sources` (paths/URLs). Engineer finalize หลัง first draft. ดู Glossary § Frontmatter Convention
- **Inline provenance markers on high-stakes claims (T1.3)** — NFR thresholds, decisions, contradictions, scope boundaries → mark ด้วย `^[extracted: path ¶N]` / `^[inferred: reason]` / `^[ambiguous: A vs B]`. ห้าม mark common sense / framework defaults / every sentence (เกิน 50% = noise). ดู Glossary § Inline Provenance Markers + `.agents/skills/_core-behaviors.md § 8`
- **LLM Wiki hard exclusion** — `docs/security/*` findings, threat models, incident postmortems, secrets/customer PII/legal/compliance docs ห้ามเข้า shared LLM Wiki / cloud summarization / hot cache. ใช้ redacted summary เท่านั้นถ้าต้องการ cross-link

## 7. Glossary (Option C Canonical Terms)

> **Single source of truth** สำหรับ vocabulary ของ Option C phase contract
> ทุกเอกสารใน repo ต้องอ้างอิงคำเหล่านี้ **ตามนิยามด้านล่างเท่านั้น** ห้ามนิยามใหม่ในที่อื่น

| Term | Definition |
|------|-----------|
| **Deferred-AC Registry** | `docs/state/deferred-ac-registry.md` — single sanctioned destination สำหรับ E-ACs ที่ exercise ตอน task closure ไม่ได้ (vendor account ยังไม่มา / hardware ไม่ถึง). Schema: owner + expiry ≤14 วัน + risk-if-missed. แทน forbidden pattern `[x]` + "deferred to operator-runtime". Block `/deliver` ถ้า Active table ไม่ว่าง |
| **Divergence** | Impl Planner กำหนด phase ที่ต่างจาก SD hint โดย document เหตุผล (architectural / MoSCoW / risk) ใน audit trail |
| **E-AC (Empirical AC)** | Acceptance Criterion ที่ verifiable เฉพาะเมื่อ exercise deployed/running system. ต้อง declare `[evidence-kind]` (probe / gui-capture / log-assertion / queue-inspect / db-inspect / file-blob-check / boot-cold / contract-roundtrip / config-audit). Mandatory ≥1 ต่อ task ที่ touch network/gateway/deploy/persistence/UI/async/security control/env-var-or-secret-consumer |
| **`[config-audit]`** | E-AC kind สำหรับ task ที่ consume env var / secret / API key / connection string / feature flag — engineer enumerate config items + runtime introspect resolution + verify `.env.example` ↔ code refs sync. ป้องกัน Shark CMS env-var defect (`[x]` ปิดด้วย mock config, prod fail) |
| **Operator Action Registry** | `docs/state/operator-action-registry.md` — Pending operator actions ที่ UIR halt registers (set env var, get API key, accept ToS). Distinct from Deferred-AC: session-scoped not vendor-wait. `/impl-task` halts on Pending row blocking current task; `/next` Check 5.7 surfaces backlog |
| **Plan Staleness Sentinel** | `/next` Check 5.8 advisory — ถ้า plan approved >30d ago + (no review หรือ >10 closures since review) → recommend `/impl-plan-review` re-validate. Stops "approved-once-drift-forever" |
| **Rollback Plan (Phase Gate row)** | Mandatory Phase Gate row: 1-paragraph specifying what reverts + data preservation + revert order + named operator. Generic "revert commits" = MEDIUM finding |
| **User Input Required (UIR)** | Engineer-side halt protocol when operator must do out-of-band action (set env var, fetch API key, accept ToS, run privileged step). Template in `andm-impl-engineer/SKILL.md § Confusion Management Protocol`. Distinct from CONFUSION (don't know option) / MISSING REQUIREMENT (spec unclear) / Deferred-AC (vendor wait). Halt → register Pending → operator do action → engineer verify via `[config-audit]` |
| **Empirical Closure Discipline** | Golden Rule #9: task ที่มี E-AC ปิดด้วย structural test pass อย่างเดียวไม่ได้ — ต้องมี evidence artifact ที่ `docs/state/_session-handoff/<task-id>-evidence-*` จาก deployed/running system. Forbidden: `[x]` + "deferred to operator-runtime" / "deferred per <task> precedent". Enforced by Code Review Dimension #11 (CRITICAL on violation) |
| **Evolution Sequence** | 🔴 **HARD-constraint** ordering (E1/E2/.../EN) ใน `07-future-evolution.md` backed by ADRs. Impl Planner override ได้เฉพาะผ่าน `/backtrack sd` เท่านั้น |
| **Exploratory Walk (Tier 1.5)** | Non-scripted operator session (30 min) เดินทุก collection/view/locale/role/theme ก่อน nominate Phase Gate. หา functional defects ที่ scripted tests missed. Artifact: `docs/state/_session-handoff/<date>-phase<N>-exploratory-walk.md`. Mandatory Phase Gate row — Phase Gate ปิดไม่ได้จนกว่า walk artifact exists + ≤14d + CRITICAL findings resolved. ป้องกัน defect class จาก Shark CMS 2026-04 (9 bugs ใน 30 min walk ที่ 5 scripted Phase Gates miss) |
| **Evolution Step** | แถวเดียวใน Evolution Sequence (E1, E2, ...) พร้อม architectural rationale + ADR citation |
| **Frontmatter Convention (T1.1)** | YAML block at the very top of every BA/SD/TD/UX/QA/SPEC/DEC deliverable, before `# title`: `summary` (≤200 chars), `provenance` counts (`{extracted, inferred, ambiguous}` from actual high-stakes markers only), `sources` (array of paths/URLs). Template-suggested by `/ba`, `/sd`, `/td`, `/spec`, `/sd-lite`, `/ux-lite`, `/decide`. Engineer finalizes after first draft. **No automated enforcement** — manual eyeball; lint adoption deferred. Source-grounding: enables future LLM Wiki primitives. Companion: Inline Provenance Markers |
| **LLM Wiki Hard Exclusion** | Sensitive artifacts must never be fed into shared LLM Wiki / `wiki-ingest` / hot cache / cloud summarization: `docs/security/*`, threat models, red-team findings, vulnerability registers, incident postmortems, secrets/customer PII/legal/compliance docs. Use a redacted summary with pointers to raw files if cross-link visibility is needed |
| **Honor** | Impl Planner's independent rules ให้ผลลัพธ์ตรงกับ SD hint (บันทึกเป็น ✅ Align) |
| **Implementation Phase** | P1/P2/P3/P4 delivery grouping **ภายใน** Lifecycle Phase 3 — owned by Impl Planner เท่านั้น |
| **Inline Provenance Markers (T1.3)** | Markdown convention for high-stakes claims: `^[extracted: docs/path ¶N]` (verbatim from source), `^[inferred: reason]` (logical extension), `^[ambiguous: A says X, B says Y]` (sources disagree). **Judgment-based** — engineer marks high-stakes claims (NFR thresholds, decisions, contradictions, scope boundaries) only — not every sentence. Frontmatter counts these markers; do not estimate percentages. Behavioral guidance in `.agents/skills/_core-behaviors.md § 8` |
| **Invalid Label** | Phase Hints section ที่ title ว่า "Plan", "Assignment", "Schedule", หรือ "Roadmap" — ต้อง relabel เป็น "Hints (Suggested)" |
| **Lifecycle Phase** | 5-Phase methodology: Phase 1 DESIGN → Phase 2 DESIGN QA → Phase 3 IMPLEMENT → Phase 4 HARDEN → Phase 5 DELIVER |
| **Override** | Impl Planner ตั้งใจ diverge จาก soft Phase Hint พร้อม documented reason (ทำได้เฉพาะ soft hints — Evolution Sequence ต้อง backtrack) |
| **Phase Gate Blocking** | Phase Gate rows ใน `impl-plan.md` ต้อง `[x]` ครบก่อน Phase N+1 tasks เริ่มได้. `/impl-task` Phase 1.3 enforces by HALT-ing เมื่อ task's phase > current open phase. Override ต้อง log ใน `Phase Gate Override Log` |
| **Phase Gate Hallucination** | Anti-pattern: status agent อ่าน Tier 1 task closure ([x] ACs ครบ) แล้วสรุป "Phase complete" โดยไม่ตรวจ Tier 1.5 Exploratory Walk + Tier 2 Phase Gate boxes. ป้องกันโดย Three-Tier Closure scan ใน `/next` Check 6 + §1 callout ใน root CLAUDE.md |
| **Phase Hint** | 🟡 **SOFT** architectural suggestion (P1/P2/P3/P4) ใน `08-product-breakdown.md` section "Phase Hints (Suggested)". Impl Planner may override with documented reason |
| **Phasing Rationale** | Mandatory paragraph + `SD Hint Alignment` audit trail ใน `docs/state/impl-plan.md` ที่ document honor/diverge ทุก task |
| **Schedule Leakage** | การมีคำว่า sprint numbers, calendar dates, quarters, months, หรือ team capacity ใน SD docs → raises MEDIUM finding |
| **SD Hint Alignment** | Audit trail subsection ที่ list ทุก task พร้อม classification: ✅ Align / ⚠️ Diverge / 🔴 Violation / ◻️ No hint |
| **SD-as-Master** | `docs/design-docs/` (System Design) เป็น **single source of truth** สำหรับ architecture + work inventory; downstream deliverables (UX/TD/QA) เก็บเฉพาะ phase-unique content และ reference กลับมายัง SD แทนการ restate |
| **State Single Source of Truth (State SoT)** | `docs/state/impl-plan.md` = primary SoT สำหรับ task list / phase / Phase Gate / SD Hint Alignment / Mid-Phase Audit Log. `docs/state/deferred-ac-registry.md` = primary SoT สำหรับ deferred E-AC. `docs/state/overview.md` + `{module}/handoff.md` + `_session-handoff/*` = **derived views**, ห้ามเก็บ data ขัดแย้งกับ primary. `/next` Check 5.5 + `/impl-plan-review` Dimension #8 enforce |
| **State Reconciliation Discipline** | ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal → propagate state 3 ชั้น: (1) `impl-plan.md` (primary), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*`. ห้าม update เพียงไฟล์เดียว |
| **TD Scope Contract** | TD ผลิตเฉพาะ `02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md`. TD-01 content → `docs/api-specs/*.yaml`; TD-05/06 → `docs/adr/` + TD-02 appendix; TD-07 → `docs/qa/01-test-execution-plan.md`; TD-08 → Impl Planner อ่าน SD-07/08 โดยตรง. Numbering gaps (01/05/06/07/08) ถูก preserve intentionally เพื่อ backward compatibility |
| **UX Scope Contract** | UX ผลิตเฉพาะ `00-design-vision.md` + `01-05` (design-tokens, component-inventory, page-layouts, navigation-structure, interaction-patterns). UX-06 (handoff-to-implementation) ถูก drop — TD และ Impl Planner อ่าน UX-01..05 โดยตรงเป็น input |

> **Vocabulary Lookup:** เมื่อสงสัย ให้ grep `CLAUDE.md § Glossary` — ห้าม paraphrase หรือนิยามใหม่ในเอกสารอื่น ให้ link กลับมาที่ section นี้แทน

## 8. Document References

```
CLAUDE.md                         <- ไฟล์นี้ (critical rules)
.claude/rules/
  architecture.md                 <- module structure, design patterns
  security.md                     <- security rules detail + .gitignore
  code-style.md                   <- naming, async/await, imports
  testing.md                      <- coverage, test naming, run commands + per-service-kind Prove-It evidence table (materialized from .claude/stack.json by /project-init — re-run /project-init --regen when stack changes so abstract evidence-kinds [probe / gui-capture / log-assertion / queue-inspect / db-inspect / file-blob-check / boot-cold / contract-roundtrip] remap to current stack tools)
  # monorepo: เพิ่ม per-service rules เช่น web.md, api.md, workflow.md (กฎเฉพาะภาษา/framework)
.agents/skills/                   <- Agent persona definitions (platform-agnostic)
docs/
  ba/                             <- BA deliverables (01-05) — v1.2: 06-handoff-to-architecture.md dropped
    01-project-brief.md           <- Problem statement, key actors, success metrics
    ...
    05-user-flows.md              <- End-to-end user journeys (open questions live in relevant doc 02-05)
    claim-review-and-rebuttal/    <- BA review findings + rebuttals
  technical-design/                <- Technical Design specs (Backend, Frontend, DB — 3 docs after SD-as-Master consolidation)
    02-backend-design.md          <- Class/module structure, interfaces, DTOs, CQRS handlers, DI map (+ optional Flow Appendix)
    03-frontend-design.md         <- Component tree, state management, routing, data fetching, error boundaries
    04-database-design.md         <- Column-level schema, constraints, indexes, migrations, seed data
    claim-review-and-rebuttal/    <- TD review findings + rebuttals
  design-docs/                    <- Blueprint สถาปัตยกรรม (v1.2: 6 docs, gaps ที่ 01/06 — merged into 02)
    02-high-level-architecture.md <- Requirements Traceability + Components + Communication + Infra + Glossary + ADR Digest
    03-deep-dive.md               <- Critical technical challenges
    04-data-flow.md               <- Data flows, sequence diagrams
    05-security.md                <- Defense layers, auth, threat model
    07-future-evolution.md        <- Scaling triggers + migration paths + Evolution Sequence (E1/E2/... with ADR rationale)
    08-product-breakdown.md       <- Work inventory + Phase Hints (Suggested P1-P4) + Per-Task Metadata; Impl Planner makes final phase decision via /impl-plan
    claim-review-and-rebuttal/    <- SD review findings + rebuttals
  adr/                            <- ทุกการตัดสินใจ + เหตุผล
  api-specs/                      <- OpenAPI YAML contracts
  security/                       <- Red team findings + defense reports
  code-review/                    <- Code review findings + fix reports
  state/current_handoff.md        <- สถานะปัจจุบัน (single project)
  state/{module}/handoff.md      <- สถานะแต่ละ module (monorepo)
  state/overview.md              <- ภาพรวมสถานะทุก module (monorepo)
```
