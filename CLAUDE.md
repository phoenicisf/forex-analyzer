# PhoenicisNex — AI Development Rules

> AI Agent ทุกตัวต้องอ่านไฟล์นี้ก่อนเริ่มทำงาน
> อัปเดตล่าสุด: 2026-05-02

---

## 1. Project Overview

**ชื่อโปรเจค:** PhoenicisNex
**ประเภท:** MetaTrader 5 Expert Advisor (EA) — single-instrument retail Forex EA (EURUSD H4)
**สถานะ:** MVP — greenfield rewrite of `PhoenicisN2.10_stable.mq5` (22k LOC); Design QA certified 2026-05-02
**เอกสารหลัก:** `docs/design-docs/` (ดู Section 8)

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
> **For PhoenicisNex specifically (no GUI):** Tier 1.5 walk = run `simulation/headless-tests/<task>.ini` against fresh state via `mt5-headless-backtest` flow → inspect Tester log + `journal/*.jsonl` per `mt5-log-reader` SKILL → verify journal records vs `trade-journal-schema.yaml` + state.json invariants vs `state-persistence-schema.yaml`. Empirical = headless backtest + log + journal artifacts (no GUI to "click through").
>
> **Status snapshot** (sync จาก `docs/state/impl-plan.md` — first cut by Impl Planner):
>
> | Phase | Tier 1 (Tasks) | Tier 1.5 (Walk) | Tier 2 (Phase Gate) |
> |-------|----------------|------------------|---------------------|
> | P1 Foundation | [✅/⚠️ N/M tasks] | [✅ artifact YYYY-MM-DD / ⚠️ stale / ❌ missing] | [✅ via IMPL-P1-GATE / ⚠️ open] |
> | P2 Core | [...] | [...] | [...] |
> | P3 Polish | [...] | [...] | [...] |
> | P4 Stretch | [...] | [...] | [...] |

## 2. Tech Stack

<!-- AUTO-MANAGED:tech-stack-table — Container row removed (containerization.engine == "none", inferred heuristic) -->

| Layer | Technology |
|---|---|
| Language | MQL5 (MetaQuotes Language 5) — strict; no external DLLs <!-- source: TD-02 §2 + NFR-7.2 --> |
| Runtime | MetaTrader 5 client (Windows; Build ≥ 3815) — intra-process EA <!-- source: ADR-001 + NFR-7.1 --> |
| Architecture | Modular Monolith intra-MT5 (5 layers: core/slots/services/domain/helpers) <!-- source: ADR-001 + ADR-012 --> |
| Storage | File-based — `state.json` (atomic write per ADR-007) + `journal/*.jsonl` (JSON-Lines per ADR-006) + MT5 GlobalVariable mirror; **no RDBMS** <!-- source: TD-04 + ADR-006/007 --> |
| Auth | N/A — solo operator, no network listener; symbol whitelist in OnInit (`_Symbol == "EURUSD"`) <!-- source: NFR-5.3 + FR-1.2 --> |
| Testing | MT5 Strategy Tester (headless via `terminal64.exe /config:tester.ini`) + MetaEditor compile + log review per `mt5-headless-backtest` / `mql-developer` / `mt5-log-reader` SKILLs <!-- source: TD-02 §13 --> |
| Broker | FBS Markets Inc. — Standard account (FBS-Real Build 5833, EET timezone GMT+2/+3 DST) <!-- source: C-5/C-10 + trading-baseline.md --> |

## 3. Architecture Rules (critical only)

<!-- AUTO-MANAGED:deployment-line — removed (containerization.engine == "none") -->

- **Architecture Style:** Modular Monolith intra-MT5 process (per ADR-001) — 21 slots + 13 services + 4 helpers + 4 domain types + 3 core classes
- **5-layer file structure:** `core/` → `slots/` → `services/` → `domain/` → `helpers/` (per ADR-012)
- **Service Communication:** Synchronous in-process method calls; intra-process contracts via JSON Schema in `docs/api-specs/*.yaml`
- **Data Ownership:** PortfolioState owns all per-magic state (CHashMap per ADR-005); StatePersistence owns atomic state.json (ADR-007); TradeJournal owns JSON-Lines append (ADR-006)
- **Single-threaded tick:** EA relies on MT5 single-tick invariant (no mutex / re-entrancy protection — per ADR-001 + BA `01 § 6.2 Won't Permanent`)
- **`#include` discipline (per ADR-012, reviewer enforced):**
  - `slots/*` ห้าม `#include "slots/<other>"` — slot-to-slot data ผ่าน `PortfolioState.GetByMagic()` เท่านั้น
  - `services/*` ห้าม `#include "slots/*"` — wrong direction
  - `domain/*` ห้าม `#include "services/*"` — pure types only
  - `helpers/*` ห้าม `#include "services/*"` — pure utility only
- **2-phase init for circular deps:** Cycle 1 (Logger ↔ StatePersistence) at OnInit step 4a; Cycle 2 (StatePersistence ↔ PortfolioState) at step 5a (per TD-02 §7.4)
- **CleanupPartialInit** required at all 8 INIT_FAILED return sites in OnInit Phase C (per TD-02 §7.4.1)
- **ห้าม** เขียน Business Logic ใน `PhoenicisNex.mq5` entry point (≤ 500 LOC; thin OnInit/OnTick/OnDeinit/OnTester wrapper เท่านั้น)
- **ห้าม** call MT5 trade API ตรงจาก slot — ต้องผ่าน CTrade wrapper ใน `RiskManager` หรือ `OpenOrder<X>` helper
- **ห้าม** `slots/*` `#include "services/Logger.mqh"` ตรง — inject ผ่าน constructor (Composition Root pattern, ADR-002)
- รายละเอียด: `.claude/rules/ea.md`

## 4. Security Rules (anti-patterns only)

- **ห้าม** hardcode broker credentials, account number, server password — login เป็น MT5 platform concern, ไม่ใช่ EA
- **ห้าม** เปิด network listener / external HTTP / `WebRequest` / external DLL ใน Phase 1 (NFR-7.2 = 0 external DLLs; Phase 2 trigger ดู TD-03 §5)
- **ห้าม** trust `_Symbol` — OnInit ต้อง reject ถ้า `_Symbol != "EURUSD"` 100% (NFR-5.3 + FR-1.2)
- **ห้าม** silent `ExpertRemove()` — ทุก halt path ต้อง `Alert()` MT5 native + journal entry (NFR-5.1; CodeWiki §6.2 P2.3)
- **ห้าม** `INVALID_HANDLE` ผ่านไป OnTick — OnInit ต้อง validate ทุก ~25 indicator handles, fail-fast 100% (NFR-3.2; FR-7.6)
- **ห้าม** flat write ของ state.json — ใช้ AtomicFile pattern (write temp + rename, per ADR-007 Option A; Option B fallback ที่ TD-02 §4.4)
- **ห้าม** log/persist ข้อมูลที่จะใช้ไป external (Phase 1 = local-only sandbox; Security NFR out-of-scope per BA `03 § 5 Note`)
- รายละเอียด: `.claude/rules/security.md`

## 5. Git Rules

- Commit format: `[type:<service-slug>] short description` + `Why:` explanation
- Types: feat, fix, refactor, test, docs, chore
- **ห้าม** force push ไป main/develop
- ทุก `simulation/headless-tests/<task>.ini` commit ลง git พร้อม PR ที่ contain task (per TD-02 §13.6 reproducibility)
- ทุก `.compile.log` artifact = local-only, **ไม่** commit (UTF-16LE binary noise)

## 6. Agent Workflow Rules

- เริ่มงาน: อ่าน CLAUDE.md → อ่าน handoff (single: current_handoff.md / monorepo: overview.md → {module}/handoff.md) → ทำงาน
- จบงาน: อัปเดต handoff เมื่อจบ feature / เปลี่ยน session / ข้ามวัน (ไม่ต้องทุก step ย่อย)
- Task size: XS-S ทำจบใน prompt เดียว / M แบ่ง 2-3 steps / L-XL ใช้ full decomposition
- ADR: ทุกการตัดสินใจ architecture → สร้าง `docs/adr/NNN-title.md` (currently 12 ADRs locked — ADR-013+ for new decisions)
- **Phase Gate ≠ Task Closure (three-tier)** — ดู §1 Three-Tier Closure Convention. Status reports + `/next` ต้อง reconcile ทั้ง 3 tiers (Tier 1 task / Tier 1.5 walk / Tier 2 Phase Gate); ห้ามใช้ Tier 1 อย่างเดียวสรุป "Phase complete". Engineer agents ห้ามปิด AC ด้วย `[x] + "deferred to operator-runtime"` — ใช้ `docs/state/deferred-ac-registry.md` แทน (ดู Glossary § Deferred-AC Registry + Exploratory Walk)
- **State Reconciliation (3-file propagation)** — ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**: (1) `impl-plan.md` (primary SoT — `[x]` AC, Phase Gate, audit log), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*` (transient pointer + artifact). ห้าม update เพียงไฟล์เดียว — drift ระหว่างไฟล์ทำให้ `/next` รายงานผิด, `/impl-task` หยิบ task ผิด, status agents hallucinate phase complete (ดู Glossary § State Single Source of Truth + State Reconciliation Discipline)
- **Plan QA cycle** — `/impl-plan` runs once → MUST follow with `/impl-plan-review all` → ถ้ามี CRITICAL/HIGH → `/impl-plan-rebuttal claim-review-XX.md` → loop until verdict ✅ Ready for Implementation Execution. ห้าม start `/impl-task` ก่อน plan ผ่าน review (mirror BA/SD/UX/TD review pattern)
- **UIR before close** — engineer พบว่าต้องการ operator action (set env var, fetch API key, accept ToS, run privileged step) ก่อนปิด task = ใช้ **UIR template** ใน Confusion Management Protocol → register Pending row ใน `docs/state/operator-action-registry.md` → ห้าม close `[x]` AC ที่ depend on action จนกว่า registry row Done + verified via `[config-audit]` evidence (ดู Glossary § User Input Required + Operator Action Registry)
- **Config-audit gate** — task ที่ consume env var / secret / API key / connection string / feature flag = ต้องมี ≥1 `[config-audit]` E-AC (Mandatory E-AC Trigger #8). Engineer enumerate config items + runtime introspect each resolved from real env (ไม่ใช่ hardcoded test value) + verify `.env.example` ↔ code refs sync. Code Review Dim #13 enforces. *(PhoenicisNex Phase 1 = local-only sandbox, no env var/secret consumer; gate triggers ต่อเมื่อ Phase 2 cloud journal/Telegram added.)*

### 🔴 EA Definition of Done — 4-gate (per user remark 2026-05-02 + TD-02 §13.1)

ทุก IMPL-NNN task ที่ touch `.mq5` หรือ `.mqh` ต้องผ่าน **ทั้ง 4 gates** ก่อน mark complete — ห้าม skip, ห้ามแก้ message ให้ "ผ่าน":

| Gate | Action | Tool / SKILL | Pass criteria |
|------|--------|--------------|---------------|
| **G1 — Compile** | `MetaEditor64.exe /compile:<file.mq5> /log` | `mql-developer` (syntax) + `mt5-log-reader` (parse `.compile.log`) | `.compile.log` มี `Result: 0 errors, 0 warnings` (exit code unreliable per `mt5-log-reader § Wine`); .ex5 produced |
| **G2 — Smoke** | Attach EA → check Experts log first 5 ticks | `mt5-log-reader` | OnInit returns INIT_SUCCEEDED + `[system][ev=init_ok]` + no `[ERROR]` |
| **G3 — Headless backtest** | (slot/orchestrator/cross-slot tasks) `terminal64.exe /config:simulation/headless-tests/<task>.ini` with `Visual=0` + `ShutdownTerminal=1` | `mt5-headless-backtest` (full 10-step flow) | Tester log: EA ทำงานครบ window; milestone count ≥ 1 ของ key event (entry / exit / journal write) |
| **G4 — Log review** | Parse Tester log + `MQL5/Files/PhoenicisNex/journal/tester/run-<ISO>.jsonl` | `mt5-log-reader` (Experts log iconv UTF-16LE → UTF-8 → grep) + jq (journal) | No `[ERROR]` outside expected fail-fast; journal records validate ตรง `trade-journal-schema.yaml` (sample 5) |

> ⚠️ **ห้าม** silent skip gate (แก้ test/log message เพื่อ "ผ่าน") = ขัด TD-02 §13.5 audit contract. Failure escalation: log issue ใน task notes + ≤30 line snippet → fix หรือ `/backtrack sd` / `/amend td`.
>
> **เหตุผล:** MQL5 ecosystem ไม่มี unit test framework ที่ใช้กันแพร่หลาย (per BA `01 § 6.2 Won't Permanent`); empirical verification = compile log + Strategy Tester log + journal artifact. รายละเอียด commands + jq filters: `.claude/rules/testing.md` + `.claude/rules/workflow.md`.

## 7. Glossary (Option C Canonical Terms)

> **Single source of truth** สำหรับ vocabulary ของ Option C phase contract
> ทุกเอกสารใน repo ต้องอ้างอิงคำเหล่านี้ **ตามนิยามด้านล่างเท่านั้น** ห้ามนิยามใหม่ในที่อื่น

<!-- METHODOLOGY:BEGIN Section: Glossary Option C -->

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
| **Honor** | Impl Planner's independent rules ให้ผลลัพธ์ตรงกับ SD hint (บันทึกเป็น ✅ Align) |
| **Implementation Phase** | P1/P2/P3/P4 delivery grouping **ภายใน** Lifecycle Phase 3 — owned by Impl Planner เท่านั้น |
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

<!-- METHODOLOGY:END -->

> **Vocabulary Lookup:** เมื่อสงสัย ให้ grep `CLAUDE.md § Glossary` — ห้าม paraphrase หรือนิยามใหม่ในเอกสารอื่น ให้ link กลับมาที่ section นี้แทน

### 7b. Domain Glossary — PhoenicisNex (per BA `01 § 8`, `8.1`, `8.2`)

| Term | Meaning |
|------|---------|
| **Slot** | Letter-coded sub-strategy ของ EA — แต่ละ slot มี entry function + exit function + magic number ของตัวเอง. Phase 1 มี **21 slots active**: C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B, BR, BI (Slot U deleted per OQ-8) |
| **Magic** | Integer (range 200..219) ที่ MT5 ใช้แท็ก order ของแต่ละ slot — slot อ่าน state ของตัวเองผ่าน magic ใน `PortfolioState.GetByMagic()` O(1) |
| **CD pool** | Slot C และ D ใช้ magic เดียวกัน (`MagicCD` = 200) — D เป็น 4-line wrapper ของ force-pending workflow ของ C |
| **OnTick / OnInit / OnDeinit / OnTester** | MT5 event handlers — pipeline หลักของ EA |
| **MarketContext snapshot** | Indicator-value bundle build ครั้งเดียวต่อ tick + ทุก slot อ่านจาก bundle เดียวกัน (per ADR-004 + TD-02 §3.2) |
| **PortfolioState** | Per-slot state lookup (CHashMap by magic per ADR-005) — แทน global variable swarm `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` ของ EA เดิม |
| **Trade Journal** | JSON-Lines append-only log ที่ `MQL5/Files/PhoenicisNex/journal/{live,tester}/journal-YYYYMM.jsonl` (per ADR-006; schema `docs/api-specs/trade-journal-schema.yaml`) |
| **State Persistence** | Atomic write ของ `state.json` (35 fields / 11 sub-objects per `state-persistence-schema.yaml`); Option A primary + Option B fallback per ADR-007 |
| **Pending state machine** | Per-slot internal state (PENDING / IDLE / EXECUTED) ใน `state.json` — **ไม่ใช่** broker-side pending order; force-clear policy per ADR-008 |
| **Slot orchestrator** | ตัวเรียก `BusinessLogic_X` + `ExtraTakeProfit_X` ตามลำดับ exit-before-entry ทุก tick |
| **HALTED state** | EA state machine จาก ADR-010 — `RUNNING` → `HALTED` → `HALTED_STABLE`; HALTED_STABLE = exit-only |
| **CircuitBreaker** | Ping-pong detector ที่ trigger HALTED state (per BR-3.6 + TD-02 §5.8) |
| **Safe port** | `OrderGroupStartWorkflow` cleanup — ปิด weak orders 10 slots พร้อมกันเมื่อ avg badPIP > 55 + currentProfit > 0 (per CodeWiki §5.5 + BR-8.1) |
| **Bucket A drift** | Behavioral deviation จาก unintended rewrite — ต้อง ≤ 25% Net Profit (NFR-1.1 regression contract) |
| **Bucket B drift** | Behavioral deviation จาก intentional bug fix (G4 BI SL + Magic-J) — separate budget (NFR-1.8) |
| **EET / DST** | Broker server timezone Eastern European Time (GMT+2 winter, GMT+3 summer); DST switch = last Sunday Mar/Oct (C-10) |
| **CodeWiki** | `PhoenicisN2.10_CodeWiki.md` — 8-section analysis ของ EA เดิมที่ใช้เป็น spec ของ rewrite |
| **Baseline** | `ReportTester-25045474.html` — 5-yr 2021-2025 Strategy Tester result (Net Profit $24.27M, PF 8.96, Sharpe 9.17) |
| **G4 BI SL fix** | ADR-009 — `BI` orders open ด้วย SL อิง parent `B` slot pip distance (เลิก naked `SL=0`) |
| **G4 Magic-J fix** | `ExtraTakeProfit_J` iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201) |
| **Force-pending** | Cross-slot pending state ที่ใช้กับ slot CD เมื่อ `ForceDivergentWorking` set flag |
| **Behavioral parity** | Rewrite ต้องเทรดด้วย pattern คล้ายเดิม + Total Net Profit deviation ≤ 25% (NFR-1.1) |

## 8. Document References

```
CLAUDE.md                         <- ไฟล์นี้ (critical rules)
AGENTS.md                         <- multi-IDE entry point (slim pointer; primary for Codex CLI + Antigravity)
.claude/rules/                    <- Claude Code (primary)
  ea.md                           <- MQL5 EA service rules (file layout, slot abstraction, services/domain/helpers, OnInit/OnTick)
  security.md                     <- security rules (symbol whitelist, no DLLs, atomic write, no silent halt)
  testing.md                      <- 4-gate Definition of Done + commands per 3 MT5 SKILLs + Prove-It evidence table
  workflow.md                     <- compile / smoke / headless backtest / log review + cold-bootstrap recipe
.windsurf/rules/                  <- Windsurf mirror (identical content)
.trae/rules/                      <- TRAE mirror (identical content)
.codex/rules/                     <- Codex CLI mirror (identical content); .codex/{config.toml, agents/*.toml, prompts/*.md} are methodology-managed
.agents/skills/
  mt5-headless-backtest/SKILL.md  <- headless Strategy Tester run + Tester log parse
  mql-developer/SKILL.md          <- MQL5 syntax / OOP / order management
  mt5-log-reader/SKILL.md         <- MT5 runtime + compile log parsing (UTF-16LE)
docs/
  ba/01-05                        <- BA deliverables (project brief / FR / NFR / BR / user flows)
  design-docs/02-08               <- SD deliverables (HLA / deep-dive / data flow / security / future evolution / product breakdown)
  technical-design/02-04          <- TD deliverables (backend / frontend N/A / database file-based)
  adr/001-012                     <- 12 ADRs
  api-specs/                      <- 4 JSON Schema YAML (intra-process contracts)
  state/overview.md               <- phase status + module status
  state/impl-plan.md              <- (created by /impl-plan)
simulation/headless-tests/        <- committed .ini files for reproducible headless backtest runs
MQL5/Experts/PhoenicisNex/        <- EA source code (created during Phase 3I IMPL-001+)
origin.txt                        <- MT5 install path (e.g. "C:\Program Files\FBS MetaTrader 5ph")
```
