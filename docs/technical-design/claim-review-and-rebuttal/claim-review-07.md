# Technical Design Claim Review Round 07 — BT-002 Cascade Discovery

| Field | Value |
|-------|-------|
| **Round** | 07 (post-certification cascade-discovery round) |
| **Target Document** | `all` (`02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md`) |
| **Date** | 2026-05-18 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design, mql-developer |
| **Trigger** | BT-002 (`backtrack-log.md § BT-002`) — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity per cap-3 iter chain ADR-013 → ADR-014 falsified. SD-side cascade CLOSED 2026-05-17 (commits `aebec01` → `0be2a51` → `111f092` → `32c56c0` → `e385ad0`, R07→rebuttal-05→R08→rebuttal-06→R09 = 0 findings). BA-side cascade CLOSED 2026-05-18 (commit `863493e` → rebuttal-round-05 1 LOW closed). **`backtrack-log.md § BT-002 § Impacted phases — TD` lists `02-backend-design.md § 5.8` + 10 cross-refs + `04-database-design.md` re-validate as pending downstream cascade out-of-scope of BT-002 BA-closure**. Round 07 = first TD-side audit post-BT-002. |
| **Outcome** | ❌ **Not ready for Implementation Handoff** — TD-side BT-002 cascade un-applied; 2 CRITICAL + 4 HIGH + 6 MEDIUM + 2 LOW drifts vs SD/BA/ADR/api-spec authoritative sources. |

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 2 |
| 🟠 HIGH | 4 |
| 🟡 MEDIUM | 6 |
| 🔵 LOW | 2 |

> **Total findings: 14** — Round-over-round trajectory: 20 → 9 → 8 → 3 → 1 → 0 → **14**. The Round 06 (2026-05-02) certification stamp remains correct **for the design surface that was reviewed**; the new findings are NOT regressions against prior fixes — they are **un-propagated BT-002 cascade surfaces** that landed 2026-05-17/18 against an untouched TD. Per CLAUDE.md § 7 Glossary § Plan Staleness Sentinel: certified-once ≠ certified-forever; upstream changes invalidate downstream certification.

---

## BT-002 Cascade Discovery — Context

**Why a new round opened after a "Handoff Certified" verdict:**

Between Round 06 closure (2026-05-02) and today (2026-05-18), the following authoritative changes landed (none touched TD-02/03/04):

| Date | Surface | Change |
|------|---------|--------|
| 2026-05-14 | ADR-013 created | iter-1 surgical DEAL_REASON_EXPERT filter (response to IMPL-062 Run #3 halt) |
| 2026-05-17 | ADR-014 created → both ADR-013 + ADR-014 status flipped to **`Superseded by BT-002`** | iter-2 schema-extending dedup falsified by iter-3 Slot_BI pyramid same-tick class (Run #5 sim 2021-01-06) — operator authorized Option 1 detector removal |
| 2026-05-17 | SD 6 docs (`02..08`) + ADR-010 + `trade-journal-schema.yaml` | BT-002 cascade applied — CircuitBreaker service removed, BR-3.6 demoted/struck, FR-6.6 strikethrough, FR-7.7 rewritten to handle-invalid-only, halt_reason enum stripped, Component Catalog row #14 removed, Communication Matrix updated, IMPL-051 CANCELLED |
| 2026-05-18 | BA `02 § FR-6.6` + `04 § BR-3.6` + `03 § NFR-1.x/NFR-5.1/FR-7.7` | BR-3.6 + FR-6.6 demoted to Won't permanent; NFR-5.1 + FR-7.7 narrative rewritten; BA-side cascade CLOSED |
| ❌ pending | **TD-02 / TD-03 / TD-04** | All 3 docs still carry `Last updated: 2026-05-02`; CCircuitBreaker class skeleton, 10 enumerated cross-refs, halt_reason enum drift NOT touched |

**Authoritative obligation for TD propagation** (verbatim from `docs/state/backtrack-log.md § BT-002 § Impacted phases — TD`):

> **TD** — `02-backend-design.md § 5.8` (lines 875-898) CCircuitBreaker class skeleton DELETE; cross-refs at lines 66, 854, 1418, 1456, 1506, 1599, 1763, 1828, 1898, 2099 — cascade cleanup; `04-database-design.md` re-validate (no CB state in `state-persistence-schema.yaml` per ADR-014 § Migration; expected grep clean)

Round 07 = the structured audit that surfaces every drift instance from that obligation **plus** the secondary surfaces (service counts, frontend Alert trigger list, freshness stamps) that the backtrack-log enumeration did not pre-emptively flag.

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Reference in Backend Design | ⚠️ Finding | TD-02 § 5.8 contradicts `trade-journal-schema.yaml § halt_reason` enum (post-BT-002); TD-04 § 4.3 enum restate also out-of-sync → Claims 07.1 + 07.2 |
| 2 | Backend Module Boundaries | ⚠️ Finding | CCircuitBreaker still listed as service in module tree (TD-02 line 66) + DI table row 10 → Claims 07.4 + 07.11 |
| 3 | Backend Interface Contracts | ⚠️ Finding | CCircuitBreaker public surface (`CheckPingPong`, `RecordOpen`, `RecordClose`, `Init`) still spec'd → Claim 07.1 |
| 4 | CQRS/Command-Query Separation | ⏭️ N/A | EA architecture; no CQRS pattern |
| 5 | Frontend Component Hierarchy | ⏭️ N/A | TD-03 = N/A justified (no frontend) |
| 6 | Frontend State Management | ⏭️ N/A | TD-03 = N/A |
| 7 | Frontend-Backend Contract Alignment | ⚠️ Finding | TD-03 § 2 Alert trigger list still names "CircuitBreaker triggered" → Claim 07.12 |
| 8 | Database Schema Completeness | ✅ Pass | state.json schema (TD-04 § 3) intact — no CB state was ever persisted (ADR-014 § Migration confirms) |
| 9 | Database Index Strategy | ✅ Pass | journal rotation + per-run namespace stable |
| 10 | Database Migration Safety | ✅ Pass | No CB-related schema bump; ADR-006/007 Revisit-when intact |
| 11 | Design Pattern Justification | ⚠️ Finding | ADR-013 + ADR-014 status (`Superseded by BT-002`) not reflected anywhere in TD-02 § 10 trace matrix — historical audit pointer missing → Claim 07.14 (LOW) |
| 12 | Sequence Diagram Coverage | ⚠️ Finding | TD-02 § 7.4 OnTick step 4 still calls `m_breaker.CheckPingPong()` → Claim 07.3 |
| 13 | Sequence Diagram Accuracy | ⚠️ Finding | TD-02 § 8.1 classDiagram still shows `class CCircuitBreaker` block + `COrchestrator --> CCircuitBreaker` edge → Claim 07.5 |
| 14 | Testability in TD-02/03/04 | ✅ Pass | No new seam-point drift |
| 15 | TD↔QA Alignment | ✅ Pass | QA-01 untouched; G1-G4 contract intact |
| 16 | Cross-Domain Consistency | ⚠️ Finding | TD-04 § 4.3 halt_reason enum vs `trade-journal-schema.yaml § halt_reason` enum DRIFT → Claim 07.2 |
| 17 | Security at Detail Level | ✅ Pass | symbol whitelist + handle fail-fast spec stable |
| 18 | Error Handling Strategy | ⚠️ Finding | CEAState skeleton comment (line 1418) + Logger ErrorBypassThrottle comment (lines 854, 2099) still cite CircuitBreaker as halt-trigger caller → Claims 07.8 + 07.9 |
| 19 | Implementation Readiness | ⚠️ Finding | Engineer cannot derive valid implementation from TD without first reconciling 14 drift sites; "no TBD" stance preserved but content actively contradicts BA/SD/ADR post-BT-002 → all CRITICAL/HIGH claims |

**Total: 9/19 categories ⚠️ Findings (4 N/A — UX/CQRS not applicable, 6 ✅ Pass)**

---

## Findings

### Claim 07.1: 🔴 CRITICAL — TD-02 § 5.8 CCircuitBreaker class skeleton ยังคง live ทั้ง block หลัง BT-002 ลบ service ทิ้งทั้งตัว

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.8 (lines 875-898) — full class skeleton block (header + `Responsibility` line + `class CCircuitBreaker { ... }` MQL5 declaration with `CloseEvent` struct + `m_buffer[16]` + `m_idx` + `m_logger` private fields + `Init` + `CheckPingPong` + `RecordOpen` + `RecordClose` public methods)
- File: `docs/technical-design/02-backend-design.md` § 2 file tree line 66 (`│   ├── CircuitBreaker.mqh`) — references the source file that BT-002 mandates DELETE

**Problem:**
TD-02 § 5.8 header literally reads ` ### 5.8 services/CircuitBreaker.mqh — ping-pong detector (BR-3.6)` และ Responsibility line ระบุ `detect same position re-open within 3000ms → trigger HALT (FR-6.6)`. แต่ทั้ง **BR-3.6 + FR-6.6 ถูก demote ที่ BA layer** (BA cascade commit `863493e` 2026-05-18, rebuttal-round-05 closed) และ **`docs/state/backtrack-log.md § BT-002 § Impacted phases — TD` สั่งตรง**: *"`02-backend-design.md § 5.8` (lines 875-898) CCircuitBreaker class skeleton DELETE"*. SD-side ปิด BT-002 cascade ครบ 9 surfaces ผ่าน R07/R08/R09 verify ที่ 0 findings (commits `0be2a51`/`111f092`/`32c56c0`/`e385ad0`); ADR-013 + ADR-014 `Status` flipped เป็น `Superseded by BT-002 2026-05-17`; SD `02 § 4.2` Component Catalog เอา row #14 CircuitBreaker ออก (line 302 footnote: *"Removed per BT-002 2026-05-17: `CircuitBreaker` service (former row #14)"*). TD-02 § 5.8 จึงเป็น **single point of contradiction** ระหว่าง 6 SD docs + ADR-010 amended + ADR-013/014 superseded + BA BR-3.6 demoted + api-spec halt_reason enum stripped — ทั้งหมดบอก "เลิก" แต่ TD-02 ยังบอก "build me".

**Why This Matters:**
Implementation Engineer (Phase 3I) อ่าน TD-02 § 5.8 → derive `services/CircuitBreaker.mqh` file → ผ่าน G1 compile (no compile error, MQL5 class declaration syntactically valid) → ผ่าน G2 smoke (Init does nothing harmful) → **ผ่าน Phase Gate ได้ทั้งที่ implementation contradict BT-002 ตรงๆ**. เมื่อ Code Reviewer Round 27+ ตรวจ source vs ADR-010 amended + SD `02 § 4.2` → ทุก IMPL ticket ที่ touch `services/CircuitBreaker.mqh` ต้อง revert + redo (per backtrack-log "DELETE `services/CircuitBreaker.mqh`; strip `Record{Open,Close}` dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from `core/Orchestrator.mqh::OnTradeTransaction`; remove `CheckPingPong` call from `OnTick`; DELETE `spike/Spike_CircuitBreaker.mq5`"). Sprint waste = entire IMPL-051 task block + cascade fix in OnTick + OnTradeTransaction wiring. นอกจากนี้ TD-02 § 1 TL;DR ตัวเองระบุ *"trade journal record schema = authoritative ที่ `trade-journal-schema.yaml`"* — schema ไม่มี `circuit_breaker_pingpong` แล้ว แต่ § 5.8 ระบุว่า class ที่ emit reason นั้นยังต้อง implement ⇒ TD-02 self-contradicts.

**Minimum Acceptable Fix:**
1. **DELETE TD-02 § 5.8 ทั้ง section** (lines 875-898) — header + Responsibility + class skeleton MQL5 block ทั้งหมด
2. **DELETE TD-02 § 2 file tree line 66** `│   ├── CircuitBreaker.mqh` — file จะถูกลบจาก project tree per `services/` listing
3. หลัง deletion update **§ 1 section index** (line 24 ระบุ `Services × 13`) → ตามที่ Claim 07.10 ระบุ
4. Append BT-002 cascade-completion stamp ใน TD-02 header `Last updated:` (per Claim 07.13)
5. Optional defensive: ใส่ short prose note (~2-3 บรรทัด) ใน § 5 header ว่า "former § 5.8 CCircuitBreaker removed per BT-002 2026-05-17 — see ADR-010 § Revision history + ADR-013/014 status=Superseded + backtrack-log.md § BT-002 § Impacted phases" — เพื่อให้ future reader ที่ search "CircuitBreaker" ใน TD-02 หาเจอ historical pointer

**Level of Effort:** Medium — section deletion + file tree edit + section index decrement + ~3 cite touch-ups; ~15 minutes engineer time

---

### Claim 07.2: 🔴 CRITICAL — TD-04 § 4.3 halt_reason enum ขัดแย้งกับ authoritative `trade-journal-schema.yaml`

**Location:**
- File: `docs/technical-design/04-database-design.md`, Section: § 4.3 line 226
- Quoted text: `` `[circuit_breaker_pingpong, handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null]` ``

**Problem:**
TD-04 § 4.3 ระบุ halt_reason enum 5 ค่า (รวม `circuit_breaker_pingpong`). แต่ authoritative source `docs/api-specs/trade-journal-schema.yaml` line 190 ระบุ enum เพียง **4 ค่า**: `[handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null]` (line 195 explicit: *"`circuit_breaker_pingpong` REMOVED per BT-002 2026-05-17 (legacy-parity; cap-3 iter chain ADR-013 → ADR-014 falsified — see ADR-010 § Revision history). Breaking change OK in Phase 1 (no external consumers per ADR-006)"*). TD-02 § 1 TL;DR ตัวเองยอมรับว่า *"trade journal record schema = authoritative ที่ `trade-journal-schema.yaml`"* + CLAUDE.md § 7 Glossary § "TD Scope Contract" + "SD-as-Master" ระบุ api-specs เป็น single source of truth ที่ TD reference + ไม่ restate. TD-04 § 4.3 จึง restate enum ผิด — เป็น **direct contract drift** ระหว่าง 2 docs ของ TD package เองด้วย (TD-02 ยอมรับ schema authoritative; TD-04 restate ไม่ตรง schema).

**Why This Matters:**
1. **QA G4 log review (per `.claude/rules/testing.md § G4`)** ใช้ jq filter ตรวจ journal record vs schema. ถ้า engineer write halt event ที่ `halt_reason="circuit_breaker_pingpong"` (per TD-04 spec) → schema validator (jq `.halt_reason | IN("handle_invalid_runtime","equity_floor_phase2","journal_write_fail_sustained",null)`) reject → CRITICAL G4 fail.
2. **Code Reviewer** ที่อ่าน TD-04 § 4.3 จะ derive enum constant ใน `domain/EnumTypes.mqh` ผิด — backtrack-log § BT-002 ระบุ `verify domain/EnumTypes.mqh for HALT_PINGPONG constant removal` ก็ถูกข้าม.
3. **CLAUDE.md § 7 Glossary § "SD-as-Master"** ระบุ *"downstream deliverables (UX/TD/QA) เก็บเฉพาะ phase-unique content และ reference กลับมายัง SD แทนการ restate"* — TD-04 § 4.3 restate ผิด = double damage (restate ทำให้ drift; should reference yaml + delete enum value list).
4. Severity = **CRITICAL** per matrix: *"DB schema contradicts API contract"* — exact match definition (TD-04 = "DB" deliverable per § 4 header; yaml = API contract).

**Minimum Acceptable Fix:**
1. Edit TD-04 § 4.3 line 226: เปลี่ยน enum value list เป็น `[handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null]` (4 ค่า) + append `*see trade-journal-schema.yaml § halt_reason (authoritative); circuit_breaker_pingpong removed per BT-002 2026-05-17*` reference annotation
2. Verify TD-04 § 4.4 event_type taxonomy table (lines 232-241) ไม่มี row ที่ implicit depend `halt_reason=circuit_breaker_pingpong` — already grep clean ที่ line 237 (`halt` source = `Orchestrator::Halt` generic ไม่ระบุ trigger)
3. Append BT-002 cascade-completion stamp ใน TD-04 header `Last updated:` (per Claim 07.13)

**Level of Effort:** Low — 1 enum line edit + 1 annotation; ~5 minutes engineer time

---

### Claim 07.3: 🟠 HIGH — TD-02 § 7.4 OnTick pseudo-code step 4 ยังเรียก `m_breaker.CheckPingPong()` + `Halt("circuit_breaker_pingpong")`

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnTick flow (lines 1506-1510)
- Quoted text:
  ```
  // 4. CircuitBreaker check (~5 µs)
  if (m_breaker.CheckPingPong(*m_portfolio, ctx.tick_time)) {
     Halt("circuit_breaker_pingpong");
     // fall through to exit pass
  }
  ```

**Problem:**
OnTick pseudo-code step 4 ยังเป็น call site แรกของ pipeline ที่ check ping-pong + halt ด้วย reason `circuit_breaker_pingpong`. แต่ BT-002 backtrack-log § BT-002 § Impl Code ระบุชัด: *"remove `CheckPingPong` call from `OnTick`"* + *"DELETE `services/CircuitBreaker.mqh`"*. SD `04-data-flow.md § 1.1` mermaid sequence diagram ก็ลบ CB participant + ping-pong alt-branch ทิ้งแล้ว (per SD `04` line 5 header + line 119 note + line 545 access matrix row). SD `02 § 5.1` Communication Matrix line 325 update: *"`Orchestrator → EAState.Halt(reason="handle_invalid_runtime")` | direct on `AnyHandleInvalid()` check | replaces former `CircuitBreaker → EAState.Halt` path"*. TD-02 OnTick = primary derivation source สำหรับ `core/Orchestrator.mqh::OnTick` body — engineer code นี้ down ทันที.

**Why This Matters:**
1. Engineer ที่ copy/paste OnTick pseudo-code → compile `m_breaker.CheckPingPong(...)` ที่อ้าง non-existent member → **G1 compile fail** (CRITICAL gate per `.claude/rules/testing.md`) ถ้า § 5.8 ถูกลบไปแล้ว แต่ § 7.4 ยังอ้าง.
2. Halt reason string literal `"circuit_breaker_pingpong"` ที่ผ่านไป `Halt()` → จะถูก validate vs trade-journal-schema.yaml halt_reason enum → schema validator reject → G4 log review fail.
3. SD `04 § 9` mermaid alt-branch ลบไปแล้ว แต่ TD-02 ยัง spec call site — sequence diagram accuracy gap (per Phase 1 Category 13 attack vector).

**Minimum Acceptable Fix:**
1. DELETE TD-02 § 7.4 lines 1506-1510 (step 4 entirely) — ทั้ง comment + if-block
2. Renumber steps 5-14 หรือ leave numbering gap ทิ้ง (skip 4) — เลือกแบบหลังจะลด churn ที่ step labels; แต่ต้อง add brief intro line ที่ skipped index พร้อม BT-002 pointer
3. Update step 13b journal sustained-failure halt site (lines 1557-1562) — comment ระบุ `Claim 01.8 fix` ไม่กระทบ CB removal; ยังคงต้องอยู่
4. Sync update `Halt("...")` valid reason set กับ trade-journal-schema.yaml authoritative enum (Claim 07.2)

**Level of Effort:** Low — 5-line deletion + step renumber decision; ~5 minutes engineer time

---

### Claim 07.4: 🟠 HIGH — TD-02 § 7.3 DI table row #10 + § 7.4 Phase B `m_breaker.Init(m_logger)` ยังคง wire CCircuitBreaker

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.3 DI wire-up map line 1599 — row 10: `` | 10 | `CCircuitBreaker` | (Logger) | | ``
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase B line 1636 — `m_breaker.Init(m_logger);`
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.1 Orchestrator skeleton line 1456 — `CCircuitBreaker          *m_breaker;` (private field declaration)

**Problem:**
TD-02 § 7.3 DI table ระบุ 16 service rows (step 1-17 minus step 3 helpers + 2 cycle setters per Round 03 Claim 03.4 numbering convention); row 10 = CCircuitBreaker. § 7.4 OnInit Phase B mirror DI table ด้วย 16 `Init()` calls; line 1636 = `m_breaker.Init(m_logger)`. § 7.1 COrchestrator class skeleton declare `CCircuitBreaker *m_breaker` private field. ทั้ง 3 site เป็น "engineer's primary derivation source" สำหรับ composition root wiring (per CLAUDE.md § 3 Architecture Rules + ADR-002 Composition Root pattern + ADR-012 § 5 layer discipline). BT-002 ลบ CCircuitBreaker service ทั้งตัวที่ SD `02 § 4.2 Component Catalog` line 302 + IMPL-051 CANCELLED ที่ SD `08 § 1.7` line 103 + SD `08 § 4` per-task metadata line 286 — แต่ TD-02 § 7.3 / § 7.4 / § 7.1 ทั้ง 3 surfaces ไม่ touched.

**Why This Matters:**
1. Engineer wire `m_breaker` ใน COrchestrator → DI table row 10 → Phase B `Init()` call. ถ้า § 5.8 class ถูกลบ (Claim 07.1 fix applied) แต่ § 7.1/7.3/7.4 ยัง declare/wire/init → **G1 compile fail** ทุกที่ที่ touch `m_breaker` (undeclared identifier).
2. SD `08 § 4` per-task metadata line 286 IMPL-051 `CANCELLED-BT-002` — Impl Planner ที่อ่าน TD-02 § 7.3 + SD `08 § 4` simultaneously จะ deadlock: SD ยกเลิก task, TD spec ให้ wire — engineer ไม่รู้ตามใคร.
3. § 7.3 *"Numbering convention (Claims 03.4 + 04.3)"* note (line 1584) มี hardcoded count "16 services + 1 helpers row" + "Total table rows = 19" — count breaks หลัง CB removal (15 services + 1 helpers row + 2 setters = 18 rows). Round 03 + Round 04 numbering claims ที่ stabilize ไว้ break ทันที — Claim 07.10 separately addresses count drift.

**Minimum Acceptable Fix:**
1. DELETE TD-02 § 7.3 line 1599 — row `| 10 | ` `CCircuitBreaker` ` | (Logger) | |`; renumber rows 11-17 → 10-16 (หรือ leave gap with brief pointer)
2. DELETE TD-02 § 7.4 line 1636 — `m_breaker.Init(m_logger);`
3. DELETE TD-02 § 7.1 line 1456 — `CCircuitBreaker          *m_breaker;` field declaration; verify no other site references `m_breaker` (full grep clean)
4. Update § 7.3 line 1584 numbering convention text: `16 services` → `15 services`; `16 Init calls` → `15 Init calls`; `Total table rows = 19` → `Total table rows = 18`; `× 16 services + 3 helpers` → `× 15 services + 3 helpers` (4 spots in that paragraph) — Claim 07.10 cascade
5. Update § 7.4 line 1683 reviewer checklist: same count decrements

**Level of Effort:** Medium — 3 deletion sites + 1 count-paragraph rewrite + downstream count cascade per Claim 07.10; ~20 minutes engineer time

---

### Claim 07.5: 🟠 HIGH — TD-02 § 8.1 Mermaid classDiagram ยังคงมี `class CCircuitBreaker` block + `COrchestrator --> CCircuitBreaker` ownership edge + `-CCircuitBreaker* m_breaker` field

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 8.1 classDiagram
  - Line 1763: `-CCircuitBreaker* m_breaker` (private field ของ COrchestrator class block — Round 04 Claim 04.2 fix added this 19-field set)
  - Lines 1828-1830: `class CCircuitBreaker { +CheckPingPong(port,now) bool }` (standalone class block)
  - Line 1898: `COrchestrator --> CCircuitBreaker` (ownership edge)

**Problem:**
Round 05 Path B intent statement (per `rebuttal-round-05.md § Claim 05.1`) ระบุชัด § 8.1 = "summary view" + "visual dependency arrows + ownership relationships" — แม้ Mermaid block จะเป็น navigation aid (per Round 04 + Round 05 disambiguation), **ownership edge + class block ยังเป็น authoritative "is this service in the system" signal**. SD `02 § 4.2 Component Catalog footer` line 302 + SD `08 § 1.7` ระบุ CCircuitBreaker = removed. TD-02 § 8.1 diagram ยังแสดง = drift กับ SD ตรงๆ. Round 04 Claim 04.2 fix expand COrchestrator block จาก 11→19 fields (Z2 cluster — class block field count ต้อง match skeleton); CCircuitBreaker เป็น 1 ใน 19 fields นั้น — หลัง BT-002 ต้อง = 18 fields.

**Why This Matters:**
1. Mermaid render = ownership relationship visualization → engineer ที่ดู diagram see CCircuitBreaker → wire it into COrchestrator → repeat Claim 07.4 wiring error one layer above.
2. Round 04 + Round 05 anti-regression gates G3 (`COrchestrator class block field count = 19`) ตอนนี้ break post-BT-002 — count ต้อง = 18; engineer running Round 04 gate verify จะ see "expected 18, got 19" → flag as drift (correct behavior).
3. § 8.1 class diagram ผ่าน round-04 + round-05 ตรงเพราะ "summary view" disambiguation — BUT summary view ก็ต้อง reflect actual services that exist. แสดง class ที่ไม่มี code = false navigation aid.

**Minimum Acceptable Fix:**
1. DELETE TD-02 § 8.1 line 1763 — `-CCircuitBreaker* m_breaker` field จาก COrchestrator class block; field count drops 19→18
2. DELETE TD-02 § 8.1 lines 1828-1830 entire `class CCircuitBreaker` block
3. DELETE TD-02 § 8.1 line 1898 — `COrchestrator --> CCircuitBreaker` ownership edge
4. Update post-BT-002 anti-regression gate values (Round 04/05 G3 = 19 → 18, G4 = 4 unchanged) — engineer running Round 06 anti-regression suite should produce updated gates document หรือ Claim 07.13 BT-002 stamp annotation

**Level of Effort:** Low — 3 deletion sites in single section; ~5 minutes engineer time

---

### Claim 07.6: 🟠 HIGH — TD-02 § 7.4.1 CleanupPartialInit step 10 (`delete m_breaker`) จะ fail G1 compile หลัง Claim 07.1 fix applied

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 CleanupPartialInit body line 1705
- Quoted text: `if (m_breaker != NULL)        { delete m_breaker;        m_breaker        = NULL; }  // step 10`

**Problem:**
Round 02 Claim 02.10 fix added CleanupPartialInit helper + Round 03 Claim 03.2 hardened ที่ § 7.4.1 monotonic reverse Init order (step 17 → step 1). Step 10 = `delete m_breaker`. หลัง Claim 07.1 (DELETE § 5.8 skeleton) + Claim 07.4 (DELETE § 7.1 field declaration) — `m_breaker` ไม่มี declared anywhere. § 7.4.1 ยัง reference → **undeclared identifier compile error** (MQL5 strict mode per `mql-developer` skill convention). § 7.4.1 ที่ Round 03 invest หนักไว้ (header count + full enumeration + monotonic descent + semantic anchor at line 1722) จะ break ทันทีหลัง BT-002 cleanup.

**Why This Matters:**
1. Round 06 G2 anti-regression gate (Init() call count in Phase B = 16) ก็ break (post-BT-002 = 15) — Claim 07.4 cascade.
2. Phase C call sites count = 8 (per § 7.4.1 line 1722 semantic anchor) — **unaffected** เพราะ 8 sites = ValidateInputs, ValidateSymbol, DetectDigitMultiplier, CreateHandles, ValidateSlotRegistry, RegisterAll, ValidateTopo, journal.Open. CB ไม่อยู่ใน 8 sites (correct — CB never had INIT_FAILED gate at OnInit, only OnTick CheckPingPong).
3. Engineer ที่ apply BT-002 cleanup ตาม backtrack-log obligation จะ encounter compile-fail unless TD-02 § 7.4.1 step 10 ลบ synchronously.

**Minimum Acceptable Fix:**
1. DELETE TD-02 § 7.4.1 line 1705 — `if (m_breaker != NULL) { delete m_breaker; m_breaker = NULL; } // step 10`
2. Step number 9 + 11 unchanged (monotonic descent ยังคง correct — 17→16→15→14→13→12→11→[skip 10]→9→...); หรือ renumber 17-11 → 16-10 ให้ contiguous (เลือก leave gap จะลด churn ที่ step 17-11 cite labels)
3. Verify § 7.4.1 narrative paragraph (lines 1685-1697) — `delete m_breaker` mention ไม่มี (grep clean); narrative bullet count ต้อง decrement ถ้ามี explicit count

**Level of Effort:** Low — 1-line deletion + renumber decision; ~5 minutes engineer time

---

### Claim 07.7: 🟡 MEDIUM — TD-04 § 9 Access Pattern Matrix line 500 ยังคงมี row `CircuitBreaker | (writes halt event via TJ)`

**Location:**
- File: `docs/technical-design/04-database-design.md`, Section: § 9 Access Pattern Matrix line 500
- Quoted text: `| ` `CircuitBreaker` ` | — | — | (writes halt event via TJ) | — | — | — |`

**Problem:**
TD-04 § 9 access pattern matrix = "which service queries which table" data flow consistency check. Row CircuitBreaker ระบุว่า write halt event via TJ. หลัง BT-002 CB service deleted — service ไม่มี code ที่จะ write halt event อีก. Halt invocation now flows direct จาก `Orchestrator::OnTick` → `IndicatorService::AnyHandleInvalid()` check → `m_ea_state.Halt("handle_invalid_runtime")` → CEAState ภายในจัด journal halt event (per TD-02 § 7.0.3 line 1420-1423 side-effect tuple). ✅ **Single-writer property** claim ที่ line 505 (*"ทุก field มี single owner service; ไม่มี cross-service write conflict"*) ยังคง true post-BT-002 — แต่ matrix surface ที่อ้าง CB row ทำให้ false signal.

**Why This Matters:**
1. QA reviewer ที่ตรวจ data flow consistency (Phase 3 quality gate per § 3.6) จะ flag "CircuitBreaker เขียน halt event แต่ class ไม่มี code" — drift visible.
2. Code reviewer Round 27+ ที่ใช้ § 9 matrix เป็น truth source สำหรับ "which service has write authority on journal" จะ assume CB ยังต้องมี implementation.
3. Phase 2 trigger candidate (per ADR-010 amended) คือ equity-floor + journal-sustained-failure — neither uses dedicated service; both flow direct from Orchestrator → CEAState. Matrix ต้อง reflect new path.

**Minimum Acceptable Fix:**
1. DELETE TD-04 § 9 line 500 — `CircuitBreaker` row entirely
2. Optional add explanatory note ใต้ matrix: *"Halt event writes (event_type=halt) routed via `Orchestrator → CEAState.Halt()` direct path post-BT-002 2026-05-17 (former CircuitBreaker row removed; only `IndicatorService::AnyHandleInvalid()` runtime guard surfaces halt in Phase 1 per ADR-010 amendment + SD `02 § 5.1` Communication Matrix line 325)"*
3. Verify § 9 matrix row count + line 505 single-writer claim still consistent

**Level of Effort:** Low — 1 row deletion + 1 optional note; ~5 minutes engineer time

---

### Claim 07.8: 🟡 MEDIUM — TD-02 § 7.0.3 CEAState skeleton comment line 1418 ยังคงระบุ CircuitBreaker เป็น halt trigger source

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.0.3 CEAState skeleton line 1418
- Quoted text: `// Entry point ของ all halt triggers: CircuitBreaker, IndicatorService runtime invalid,`
- Context (line 1419): `//   journal sustained-failure (ADR-006), force-clear escalation (ADR-008 — future)`

**Problem:**
CEAState skeleton (Round 03 + Round 04 hardening — § 7.0.3 + § 5.7 + class diagram coherence) ระบุ Halt() entry point comment list 4 trigger sources: CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure, force-clear escalation. ADR-010 amended BT-002 2026-05-17 (per ADR-013/014 superseded status + SD `02 § 1.1` FR-7.7 row line 62: *"Controlled halt (handle-invalid runtime; CB ping-pong removed per BT-002 2026-05-17)"*) เหลือ trigger sources = `IndicatorService::AnyHandleInvalid()` runtime + Phase 2 candidates (equity-floor, journal-sustained-failure). CircuitBreaker ออก. SD `05-security.md § 7.2` line 233 update: *"Phase 1 sole trigger source post-BT-002 2026-05-17; CB ping-pong removed"*. TD-02 § 7.0.3 comment ระบุชัดๆ ว่า "all halt triggers" — กลายเป็น misleading list.

**Why This Matters:**
1. Engineer ที่อ่าน CEAState skeleton เพื่อ verify Halt() side-effect tuple → infer trigger taxonomy ผิดเป็น 4 sources (ครั้นค้นไป ADR-010 amended ก็จะ confuse — TD บอก 4, ADR amended บอก 1 sole Phase 1 + 2 Phase 2 candidates).
2. Code reviewer ตรวจ Halt() call sites ใน Orchestrator → expect 4 callers per TD-02 comment → grep พบเพียง 1 (handle_invalid_runtime) + 1 (journal_write_fail_sustained per § 7.4 step 13b) = 2 → flag as "missing CB call site + missing force-clear call site" — incorrect signal.
3. Force-clear escalation ใน comment ยังเป็น future trigger (Phase 2) — เก็บไว้ได้; CB ต้องลบ.

**Minimum Acceptable Fix:**
1. Edit TD-02 § 7.0.3 line 1418-1419 comment: เปลี่ยน `CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure (ADR-006), force-clear escalation (ADR-008 — future)` → `IndicatorService runtime invalid (Phase 1 sole automated trigger post-BT-002 2026-05-17 per ADR-010 amendment), journal sustained-failure (Phase 2 candidate per ADR-006 RPO contract escalation), equity-floor (Phase 2 candidate per ADR-010 § Revisit-when)`
2. Reference ADR-010 § Revision history เป็น authoritative source

**Level of Effort:** Low — 2-line comment edit; ~3 minutes engineer time

---

### Claim 07.9: 🟡 MEDIUM — TD-02 § 5.7 Logger ErrorBypassThrottle comments (lines 854 + 2099) ยังคง cite CircuitBreaker เป็น halt-trigger caller

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 Logger interface line 854
- Quoted text: `// Halt-trigger bypass (CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure)`
- File: `docs/technical-design/02-backend-design.md`, Section: § 9.4 Logger ErrorBypassThrottle implementation line 2099
- Quoted text: `// Note: เฉพาะ halt-trigger errors (CircuitBreaker / handle_invalid / journal_sustained / force-clear)`

**Problem:**
ADR-011 § Halt-trigger bypass (referenced ที่ § 5.7 + § 9.4) ระบุ Logger.ErrorBypassThrottle = never throttle Alert, called ONLY ตอน halt-trigger fires. Round 03 + Round 04 fix established comment list ของ caller set: 3 sources at line 854 (CB, handle-invalid, journal-sustained) + 4 sources at line 2099 (CB, handle-invalid, journal-sustained, force-clear). หลัง BT-002 ADR-010 amended: CB ออกจาก trigger set. Per CLAUDE.md § 4 Security Rules: *"ห้าม silent ExpertRemove — every halt path MUST Alert MT5 native + journal entry"* — halt path = handle_invalid_runtime (Phase 1 sole) + Phase 2 candidates. คอมเมนต์ TD-02 ที่ list CB ทำให้ engineer คิดว่าต้อง implement ErrorBypassThrottle call site จาก CCircuitBreaker (ที่ไม่มีแล้ว).

**Why This Matters:**
1. Engineer ที่อ่าน Logger spec → derive Caller responsibility section — list CB ⇒ wrong (CB ไม่เป็น caller post-BT-002).
2. Code Review Dim #11 + #13 (per CLAUDE.md § 6 + .claude/rules/security.md "halt path → Alert MT5 native + journal entry") trace call sites ที่ ErrorBypassThrottle invoked → expect CB site → grep ไม่พบ → false positive flag.
3. ADR-011 § Halt-trigger bypass ตัวเองยัง mention CircuitBreaker หรือไม่ — out of scope สำหรับ TD review (ADR is SD-owned); แต่ TD comment ที่ restate ADR ต้อง sync กับ ADR-010 amendment ที่ CB removal.

**Minimum Acceptable Fix:**
1. Edit TD-02 § 5.7 line 854: เปลี่ยน `(CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure)` → `(IndicatorService runtime invalid Phase 1; Phase 2 candidates: equity-floor, journal sustained-failure per ADR-010 amendment BT-002)`
2. Edit TD-02 § 9.4 line 2099: เปลี่ยน `(CircuitBreaker / handle_invalid / journal_sustained / force-clear)` → `(handle_invalid Phase 1 sole / journal_sustained Phase 2 / equity_floor Phase 2 / force-clear Phase 2 future)` 
3. Verify ADR-011 reference still correct (ADR-011 § Halt-trigger bypass scope ยังครอบคลุม after CB removal — bypass mechanism unchanged, only caller list shrinks)

**Level of Effort:** Low — 2 comment edits in 2 sites; ~5 minutes engineer time

---

### Claim 07.10: 🟡 MEDIUM — TD-02 service count statements ทั้ง 5 spots ยังคงระบุ "13 services" / "16 services" / "16 Init calls" — count drift post-BT-002

**Location:**
- File: `docs/technical-design/02-backend-design.md`, multiple sections
  - Line 24: `§ 5 | Services × 13 — interface + key methods + DI dependencies` (section index)
  - Line 465: `## 5. Services Layer (13 services)` (§ 5 header)
  - Line 1584: `**16 services + 1 helpers row** ... (16 × Init() call ที่ Phase B; ...) class-level count = 16 services + 3 helper classes + 2 setter operations; total Phase B Init() calls = 16. § 7.4 wording "× 16 services + 3 helpers" counts classes (mathematically consistent with this row): 1 helpers row × 3 helper classes = 3.` (§ 7.3 numbering convention paragraph)
  - Line 1683: `> Reviewer checklist: ทุก service ใน § 7.3 (× 16 services + 3 helpers (no Init)) ต้องมี exactly 1 Init(...) call ใน Phase B (= 16 Init calls); ...` (§ 7.4 reviewer checklist)
  - Line 2512: `> End of 02 — Backend Design — 5 layers (core/slots/services/domain/helpers), 13 services + 21 slots + 4 helpers + 4 domain types, ...` (End-of-doc footer)

**Problem:**
Round 03 (Claims 03.4 + 04.3) เครียดเสน่หากับ numbering — count "13 services" + "16 services" (DI table includes 3 core classes + 3 helpers + 13 services = 16 + helpers rows) + "16 Init calls" ผ่าน 5 spots ใน TD-02 ที่ต้อง consistent. หลัง BT-002 ลบ CCircuitBreaker = 12 services (file tree count) / 15 services (DI table including 3 core) / 15 Init calls. ทั้ง 5 spots ต้อง decrement synchronously หรือ section จะ self-contradict.

**Why This Matters:**
1. Round 03/04 anti-regression contract (G2 = `Init() call count in Phase B = 16`) ตอนนี้ stale — engineer running Round 06 G2 gate vs post-BT-002 source code (15 calls) → fail incorrectly; ต้อง update gate spec.
2. § 7.3 numbering convention paragraph (line 1584) เป็น primary derivation source สำหรับ "how many services to wire" — engineer count 16 + apply BT-002 cleanup that removes 1 → confused arithmetic.
3. End-of-doc footer (line 2512) = quick-reference summary; first thing readers see ตอน scan doc — bad count = bad first impression.

**Minimum Acceptable Fix:**
1. Edit line 24: `Services × 13` → `Services × 12`
2. Edit line 465: `(13 services)` → `(12 services)`
3. Edit line 1584: 4 hardcoded counts: `16 services + 1 helpers row` → `15 services + 1 helpers row`; `16 × Init()` → `15 × Init()`; `Total table rows = 19` → `Total table rows = 18`; `16 services + 3 helper classes` → `15 services + 3 helper classes`; `total Phase B Init() calls = 16` → `total Phase B Init() calls = 15`; `× 16 services + 3 helpers` → `× 15 services + 3 helpers`
4. Edit line 1683: `× 16 services + 3 helpers` → `× 15 services + 3 helpers`; `= 16 Init calls` → `= 15 Init calls`
5. Edit line 2512: `13 services` → `12 services`
6. Verify CLAUDE.md `§ 2 Tech Stack` row "Architecture: Modular Monolith intra-MT5 (5 layers: core/slots/services/domain/helpers)" ระบุ "13 services" — out-of-scope สำหรับ TD review (CLAUDE.md is project-level), but flag for awareness

**Level of Effort:** Medium — 5 spots × 2-3 number edits each; ~15 minutes engineer time (mechanical but must verify each ที่ตรงและไม่ break Round 03/04 Claim citations)

---

### Claim 07.11: 🟡 MEDIUM — TD-02 § 2 file tree line 66 ยังคงระบุ `services/CircuitBreaker.mqh` หลัง BT-002 ลบไฟล์

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 2 Project File Layout line 66
- Quoted text: `│   ├── CircuitBreaker.mqh`

**Problem:**
TD-02 § 2 file tree = canonical project layout reference (per ADR-012). backtrack-log § BT-002 § Impl Code ระบุ: *"DELETE `services/CircuitBreaker.mqh`"*. ตราบที่ TD § 2 ยัง list ไฟล์ — engineer following ADR-012 layout discipline จะ create file → contradict BT-002 cleanup.

**Why This Matters:**
1. CLAUDE.md § 3 Architecture Rules ระบุ "5-layer file structure" — file tree เป็น primary navigation; engineer cross-check existing source vs TD § 2 tree.
2. ADR-012 layer discipline (per CLAUDE.md): *"slots/* ห้าม #include slots/<other>"* + *"services/* ห้าม #include slots/*"* — discipline enforce per-file presence; file ที่ list แต่ไม่มี code = silent linter false positive.
3. Per `.claude/rules/ea.md § Project Structure` mirror TD § 2 — out-of-scope สำหรับ TD review แต่ flag for consistency awareness ที่ CLAUDE.md / `.claude/rules/ea.md` ต้อง update synchronously.

**Minimum Acceptable Fix:**
1. DELETE TD-02 § 2 line 66 — `│   ├── CircuitBreaker.mqh` from `services/` block
2. Verify `services/` block remaining files = 11 (post-deletion): IndicatorService, MarketContextBuilder, PortfolioState, RiskManager, TradeJournal, StatePersistence, Logger, TimeGate, PendingMachineRegistry, CrossSlotCoordinator, PortfolioMonitor — match Claim 07.10 count = 12 services? 
3. **Count reconciliation**: TD § 2 file tree shows 12 services (current pre-BT-002); after deletion = 11; but Claim 07.10 ระบุ post-BT-002 = 12 services — DISCREPANCY needs resolution. **Re-count current pre-BT-002 = 12 files listed at lines 59-70 (IndicatorService through PortfolioMonitor)**. Post-BT-002 = 11. Claim 07.10 § 5 header "(13 services)" — current value includes CircuitBreaker but file tree only shows 12 files. **Pre-existing inconsistency** between § 5 header (13) and § 2 file tree (12) — flag separately as historical drift.

**Level of Effort:** Low — 1-line deletion + count reconciliation per Claim 07.10; ~5 minutes engineer time

---

### Claim 07.12: 🟡 MEDIUM — TD-03 § 2 Operator Surface line 42 Alert popup trigger list ยังคง mention "CircuitBreaker triggered"

**Location:**
- File: `docs/technical-design/03-frontend-design.md`, Section: § 2 Operator Surface Inventory line 42
- Quoted text (trigger column ของ MT5 Alert popup row): `CircuitBreaker triggered, IndicatorService runtime invalid, journal sustained-failure, force-clear, HALTED_STABLE transition`

**Problem:**
TD-03 = N/A justification doc (no custom frontend; MT5 native UI = operator surface). § 2 surface inventory table line 42 ระบุ Alert popup trigger sources 5 events — รวม "CircuitBreaker triggered". SD `05-security.md § 7.2` line 233 update post-BT-002: *"Phase 1 sole trigger source post-BT-002 2026-05-17; CB ping-pong removed. Phase 2 trigger candidates per ADR-010 Revisit-when: equity-floor, journal-sustained-failure"* — Alert popup trigger list ต้อง sync. SD `02 § 7.3` ระบุ Logger sink = `Print()` + `Alert()` only — Alert call sites mapped จาก halt triggers; post-BT-002 = handle_invalid only (Phase 1).

**Why This Matters:**
1. TD-03 = single operator-facing reference (no other UI spec exists); ผิดที่นี่ = user expects Alert ตอน CB trigger → never fires (CB doesn't exist) → user might think Alert popup broken.
2. SD `05-security.md § 2.5 DoS row` + § 7.2 observability ระบุ "infinite re-entry loop" เป็น accepted residual risk post-BT-002 (line 272: *"BT-002 accepted residual risk — infinite re-entry loop"*); TD-03 Alert list ยัง imply CB will fire = false safety signal.
3. § 2 surface inventory ใช้สำหรับ user onboarding / runbook composition — false trigger = false expectation.

**Minimum Acceptable Fix:**
1. Edit TD-03 § 2 line 42 trigger column: เปลี่ยน `CircuitBreaker triggered, IndicatorService runtime invalid, journal sustained-failure, force-clear, HALTED_STABLE transition` → `IndicatorService runtime invalid (Phase 1 sole automated halt trigger post-BT-002 2026-05-17 per ADR-010 amendment), journal sustained-failure (Phase 2 candidate), equity-floor (Phase 2 candidate per OQ-6), force-clear, HALTED_STABLE transition`
2. Append note ที่ § 2 หรือ § 5 Phase 2 Triggers: *"BT-002 2026-05-17 — CircuitBreaker ping-pong detector removed (legacy-parity per cap-3 iter chain ADR-013 → ADR-014 falsified). Phase 1 Alert source set reduces accordingly"*

**Level of Effort:** Low — 1 trigger column edit + 1 optional note; ~5 minutes engineer time

---

### Claim 07.13: 🔵 LOW — TD-02 + TD-03 + TD-04 `Last updated:` stamps ทั้ง 3 ยังคงเป็น 2026-05-02 (pre-BT-002 by 16 days)

**Location:**
- File: `docs/technical-design/02-backend-design.md` line 5: `> **Last updated:** 2026-05-02`
- File: `docs/technical-design/03-frontend-design.md` line 6: `> **Last updated:** 2026-05-02`
- File: `docs/technical-design/04-database-design.md` line 5: `> **Last updated:** 2026-05-02`

**Problem:**
ทั้ง 6 SD docs (`02-08`) ได้ update `Last updated:` header เป็น 2026-05-17 พร้อม BT-002 cascade-completion stamp (e.g., SD `02 § 1.1` line 5: *"Last updated: 2026-05-17 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; cap-3 iter ADR-013 → ADR-014 superseded; ... Prior: 2026-05-12 BT-001 cascade ...)"*). TD docs ทั้ง 3 stamps ยังคง 2026-05-02 — no BT-002 acknowledgment. Per CLAUDE.md § 7 Glossary § "State Reconciliation Discipline" + § "Plan Staleness Sentinel": certification stamps + Last-Updated annotations เป็น primary signal สำหรับ document freshness.

**Why This Matters:**
1. Engineer quick-scanning TD header → see `Last updated: 2026-05-02` → assume TD aware of all changes up to that date only → wrong (TD aware of BT-001 ที่ปิดไป 2026-05-13 ก่อน TD cert, แต่ TD ไม่ aware ของ BT-002 ที่ 2026-05-17/18).
2. Anti-Duplication Rule (per claim-review SKILL.md Phase 1 + this round Phase 0): future reviewer that opens Round 08 จะ verify Round 07 fixes — stale Last-Updated เป็น primary signal ที่ Round 07 fix-round ต้อง bump.
3. SD docs ทุกตัวมี explicit "Prior: 2026-05-12 BT-001 cascade" historical breadcrumb — TD ควร mirror format เพื่อ audit trail consistency.

**Minimum Acceptable Fix:**
1. Edit TD-02 line 5: `> **Last updated:** 2026-05-02` → `> **Last updated:** 2026-05-18 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; cap-3 iter ADR-013 → ADR-014 superseded; § 2 file tree CircuitBreaker.mqh removed, § 5.8 class skeleton DELETED, § 7.0.3 + § 7.1 + § 7.3 + § 7.4 + § 7.4.1 + § 8.1 + § 9.4 wire-up/cleanup/diagram cascade cleaned, § 10 ADR digest annotated. Prior: 2026-05-02 Round 06 handoff certification)`
2. Edit TD-03 line 6: similar format — note § 2 Alert trigger list update
3. Edit TD-04 line 5: similar format — note § 4.3 halt_reason enum sync + § 9 access matrix update
4. (Mirror SD post-cascade stamp pattern exactly — engineer reads SD as template per CLAUDE.md § 6 + § 7)

**Level of Effort:** Low — 3 header edits with templated content; ~10 minutes engineer time

---

### Claim 07.14: 🔵 LOW — TD-02 § 10 Cross-Domain Trace Matrix ไม่มี row หรือ note สำหรับ ADR-013 + ADR-014 (Superseded by BT-002)

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 10.1 Class ↔ ADR ↔ API spec lines 2180-2192
- Quoted text (table closes at ADR-012 line 2192 `| File layout | ADR-012 | — | — |`); no row covers ADR-013/014

**Problem:**
TD-02 § 10.1 trace matrix maps class ↔ ADR ↔ API spec ↔ DB. Header (line 2179) ระบุ *"ตรวจว่า TD ↔ API specs ↔ DB ↔ ADR consistent — ใช้สำหรับ Phase 3 Quality Gate"*. ADR-013 + ADR-014 ถูก create 2026-05-14/17 + immediately superseded by BT-002 — ทั้ง 2 ADRs preserved as audit history (per ADR-013 line 5 + ADR-014 line 5 Status field). § 10.1 ไม่มี row + ไม่มี footer note ที่ระบุ "ADR-013/014 superseded by BT-002 — preserved as audit history of cap-3 iter chain". SD `02 § 9 ADR Digest` lines 472-473 ระบุ rows สำหรับ ADR-013 + ADR-014 explicit + status `Superseded by BT-002`. TD trace matrix should mirror.

**Why This Matters:**
1. Future Phase 3 Quality Gate ที่ใช้ § 10.1 เป็น traceability source — ADR-013/014 absent = quality-gate-blind to BT-002 falsification narrative.
2. Code reviewer Round 27+ ที่ search "ADR-013" / "ADR-014" ใน TD package เพื่อหา historical context = empty grep hit; ต้องไป SD `02 § 9` หรือ ADR files โดยตรง — extra step.
3. CLAUDE.md § 6 ADR discipline: *"ทุกการตัดสินใจ architecture → สร้าง docs/adr/NNN-title.md (currently 12 ADRs locked — ADR-013+ for new decisions)"* — count "12 ADRs locked" itself stale post-BT-002 (now 12 active + 2 superseded = 14 total per SD `02 § 9` footer line 475: *"12 active ADRs + 2 superseded"*). TD § 10.1 should reflect.

**Minimum Acceptable Fix:**
1. Append TD-02 § 10.1 after line 2192 row `File layout`:
   ```
   | (former) `CCircuitBreaker` | ADR-013 + ADR-014 (**Superseded by BT-002** 2026-05-17 — preserved as audit history of cap-3 iter chain; service removed legacy-parity) | — (former `circuit_breaker_pingpong` halt_reason removed from `trade-journal-schema.yaml` per BT-002) | — |
   ```
2. Optional add footer note ที่ § 10 header: *"BT-002 2026-05-17 — CircuitBreaker service removal cascade: ADR-013/014 superseded; SD `02 § 4.2` Component Catalog row #14 removed; api-spec `trade-journal-schema.yaml § halt_reason` enum stripped. See backtrack-log.md § BT-002"*

**Level of Effort:** Low — 1 row addition + 1 optional footer note; ~5 minutes engineer time

---

## Cross-Domain Issues

| # | Domain Pair | Issue | Severity | Relevant Claim |
|---|-------------|-------|----------|----------------|
| X1 | TD-04 § 4.3 ↔ `trade-journal-schema.yaml § halt_reason` | TD restate enum ผิด — includes `circuit_breaker_pingpong` ที่ yaml ลบไปแล้ว per BT-002 | CRITICAL | 07.2 |
| X2 | TD-02 § 5.8 / § 7.0.3 / § 7.4 ↔ ADR-010 amended + ADR-013 + ADR-014 Status | TD spec service ที่ ADRs marked superseded; TD comment list trigger sources ที่ ADR-010 amended pruned ออก | CRITICAL | 07.1 + 07.8 |
| X3 | TD-02 § 7.3 DI table / § 7.4 Phase B ↔ SD `02 § 4.2` Component Catalog + SD `08 § 4` IMPL-051 | TD wires service ที่ SD removed + IMPL ticket cancelled | HIGH | 07.4 |
| X4 | TD-02 § 7.4 OnTick step 4 ↔ SD `04 § 1.1` mermaid + `04 § 9.1` enable matrix | TD OnTick has CheckPingPong call ที่ SD sequence diagram + enable matrix ลบไปแล้ว | HIGH | 07.3 |
| X5 | TD-02 § 8.1 classDiagram ↔ SD `02 § 4.2` Component Catalog | TD class block + ownership edge ระบุ class ที่ SD removed | HIGH | 07.5 |
| X6 | TD-02 § 7.4.1 CleanupPartialInit step 10 ↔ TD-02 § 5.8 + § 7.1 ↔ BT-002 source-tree delete mandate | post-cleanup ของ § 5.8 + § 7.1 จะทำให้ § 7.4.1 step 10 undeclared identifier compile fail | HIGH | 07.6 |
| X7 | TD-04 § 9 access pattern matrix ↔ SD `02 § 5.1` Communication Matrix | TD claims CB writes halt event; SD updates halt path to direct Orchestrator → CEAState | MEDIUM | 07.7 |
| X8 | TD-02 § 7.0.3 + § 5.7 + § 9.4 comments ↔ ADR-010 amended trigger sources | comments list CB as caller; ADR-010 amended pruned | MEDIUM | 07.8 + 07.9 |
| X9 | TD-02 service count statements (5 spots) ↔ SD `02 § 4.2` Component Catalog 25-component total minus CB | count drift propagates from missing decrement | MEDIUM | 07.10 |
| X10 | TD-02 § 2 file tree ↔ BT-002 § Impl Code DELETE mandate ↔ `.claude/rules/ea.md § Project Structure` mirror | file listed in TD tree that backtrack-log mandates DELETE | MEDIUM | 07.11 |
| X11 | TD-03 § 2 Alert trigger list ↔ SD `05 § 7.2` observability + `05 § 7.3` | TD lists CB trigger; SD observability ลบไปแล้ว | MEDIUM | 07.12 |
| X12 | TD-02/03/04 `Last updated:` ↔ SD 6 docs + ADR-010/013/014 + api-spec post-BT-002 stamp | TD stamps frozen at 2026-05-02; authoritative sources updated 2026-05-17/18 | LOW | 07.13 |
| X13 | TD-02 § 10.1 Cross-Domain Trace Matrix ↔ ADR-013 + ADR-014 + SD `02 § 9` ADR Digest | TD trace matrix has no rows or footer for ADR-013/014 (superseded by BT-002, preserved as audit) | LOW | 07.14 |

> **Single Theme:** All 14 findings = BT-002 cascade un-applied to TD package. No fix is independent — they form a coordinated rebuttal cycle.

---

## Recommendation

- [x] ❌ **NOT ready for Implementation Handoff** — TD-side BT-002 cascade un-applied; cannot proceed with Phase 3I from current TD state
- [x] **Re-Review required** — Round 08 verify-only sweep after rebuttal-round-06 applies BT-002 cascade to TD
- [x] **No SD/ADR/api-spec backtrack required** — SD-side + BA-side cascade already CLOSED at Rounds R07-R09 + BA Round 06; this round = TD-side completion only
- [x] **Cascade target documents:** TD-02 (12 surfaces — § 2, § 5.7, § 5.8, § 7.0.3, § 7.1, § 7.3, § 7.4, § 7.4.1, § 8.1, § 9.4, § 10.1, end-of-doc footer + Last Updated header), TD-03 (1 surface — § 2 line 42 + Last Updated header), TD-04 (3 surfaces — § 4.3 enum + § 9 matrix row 500 + Last Updated header)

### Expected Rebuttal Effort

| Phase | Surface count | Effort estimate |
|-------|---------------|------------------|
| TD-02 deletion (Claims 07.1 + 07.3 + 07.4 + 07.5 + 07.6 + 07.11) | 8 deletion sites | 30 min |
| TD-02 comment + count edits (Claims 07.8 + 07.9 + 07.10) | 8 edit sites | 20 min |
| TD-04 + TD-03 edits (Claims 07.2 + 07.7 + 07.12) | 3 edit sites | 10 min |
| Last-Updated stamps + § 10.1 trace (Claims 07.13 + 07.14) | 3 + 1 sites | 15 min |
| Self-verification grep (post-rebuttal anti-regression) | — | 10 min |
| **Total** | **23 sites across 3 docs** | **~90 min** |

### Recommended Sequence

1. Apply Claim 07.1 (§ 5.8 DELETE) — removes primary skeleton
2. Apply Claim 07.4 + 07.6 (§ 7.1 field + § 7.4 Init + § 7.4.1 cleanup step 10) — removes wire/cleanup
3. Apply Claim 07.3 + 07.5 (§ 7.4 OnTick + § 8.1 diagram) — removes call site + diagram
4. Apply Claim 07.11 + 07.10 (§ 2 file tree + 5-spot count decrement) — sync count
5. Apply Claim 07.8 + 07.9 (§ 7.0.3 + § 5.7 + § 9.4 comments) — sync trigger comments
6. Apply Claim 07.2 + 07.7 (TD-04 enum + access matrix) — sync DB design
7. Apply Claim 07.12 (TD-03 Alert trigger) — sync operator surface
8. Apply Claim 07.13 + 07.14 (Last-Updated stamps + § 10.1 trace) — close audit trail
9. Run grep verification: `grep -nE "CircuitBreaker|CheckPingPong|circuit_breaker_pingpong|BR-3\.6|FR-6\.6|RecordOpen|RecordClose|m_breaker|CloseEvent" docs/technical-design/*.md` — expected post-fix hits: 0 in code/skeleton positions; ≤2 in historical annotation positions (Claim 07.13 stamp text + optional Claim 07.14 audit row)
10. Re-validate service counts: §§ 1/5/7.3/7.4/end — must all consistently show 12 services / 15 Init calls / 18 DI rows

### Anti-Regression Gates (Round 08 verify-only sweep should run)

| Gate | Command | Expected post-fix |
|------|---------|--------------------|
| G1 (CB skeleton DELETE) | `grep -cE "class CCircuitBreaker" docs/technical-design/02-backend-design.md` | 0 |
| G2 (CheckPingPong eradicate) | `grep -cE "CheckPingPong\|m_breaker" docs/technical-design/02-backend-design.md` | 0 |
| G3 (TD-04 halt_reason sync) | `grep -E "halt_reason.*circuit_breaker_pingpong" docs/technical-design/04-database-design.md` | 0 hits |
| G4 (TD-03 Alert trigger sync) | `grep -E "CircuitBreaker triggered" docs/technical-design/03-frontend-design.md` | 0 hits |
| G5 (service count consistency) | `grep -cE "13 services\|16 services\|16 Init calls" docs/technical-design/02-backend-design.md` | 0 hits (replaced by 12 / 15 / 15) |
| G6 (Last Updated stamps) | `grep "Last updated:" docs/technical-design/*.md` | All 3 show 2026-05-18 + BT-002 cascade note |
| G7 (cross-doc consistency) | `grep -rE "CircuitBreaker\|CheckPingPong" docs/technical-design/ docs/design-docs/ docs/api-specs/` | TD = 0 code-position hits; SD + api-spec only historical annotation hits |

---

## Notes for Defender (rebuttal-round-06)

This round's findings have **single root cause**: BT-002 backtrack landed AFTER TD Round 06 certification, with explicit mandate at `backtrack-log.md § BT-002 § Impacted phases — TD` to propagate. Defender should:

1. **Not contest scope** — backtrack-log enumeration is authoritative; expand scope ที่ 4 additional surfaces (Claim 07.10 service count, 07.11 file tree, 07.12 TD-03 line 42, 07.14 ADR trace) per "next-finer-granularity sweep" pattern (mirrors SD R20→R23 chain methodology — each rebuttal pass surfaces ~1-2 more granular sites until terminal close).
2. **Apply systematically** — 23 sites is mechanical; total ~90 min. No design judgment needed; all edits are deletion/sync-to-authoritative-source.
3. **Bump Last-Updated stamps with cascade note** — mirror SD post-cascade format exactly (Claim 07.13 fix template provided).
4. **No SD/ADR/api-spec touch** — SD + BA cascade CLOSED already; TD is the last surface. Defender SHOULD NOT propose changes to SD/ADR/yaml (they are already correct post-BT-002).
5. **Round 08 verify-only expected = 0 findings** — ถ้า defender ปิด 14 finding ทั้งหมด clean → Round 08 = re-certification.

### Round-Over-Round Trend (BT-002 superimposed)

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Phase context |
|-------|----------|------|------|--------|------|----|
| 01 | 20 | 5 | 8 | 5 | 2 | Initial scan |
| 02 | 9 | 1 | 2 | 5 | 1 | Convergence pass-1 |
| 03 | 8 | 0 | 3 | 3 | 2 | Convergence pass-2 |
| 04 | 3 | 0 | 0 | 0 | 3 | Polish |
| 05 | 1 | 0 | 0 | 0 | 1 | Path B intent statement |
| 06 | 0 | 0 | 0 | 0 | 0 | ✅ Handoff Certification (2026-05-02) |
| **07 (current — BT-002 cascade)** | **14** | **2** | **4** | **6** | **2** | **Re-opened by upstream BT-002 backtrack** |
| 08 (projected) | 0 | 0 | 0 | 0 | 0 | Verify-only re-certification expected |

> **Why a re-open is methodology-compliant:** CLAUDE.md § 7 Glossary § "Plan Staleness Sentinel" + § "State Reconciliation Discipline" recognize that *certified-once ≠ certified-forever*; upstream backtracks (BT-NNN) invalidate downstream certifications when the cascade enumeration includes the certified deliverable. BT-002 explicitly enumerates TD as `Pending downstream cascade` (per `backtrack-log.md § BT-002 § Resolution`). Round 07 is the **mandated re-open**, not a regression on Round 06 quality.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 07.1 | 🔴 CRITICAL | CCircuitBreaker class skeleton ยังคง live ทั้ง block หลัง BT-002 ลบ service ทิ้งทั้งตัว | TD-02 § 5.8 lines 875-898 + § 2 line 66 | Medium |
| 07.2 | 🔴 CRITICAL | halt_reason enum ขัดแย้งกับ authoritative `trade-journal-schema.yaml` | TD-04 § 4.3 line 226 | Low |
| 07.3 | 🟠 HIGH | OnTick pseudo-code step 4 ยังเรียก `m_breaker.CheckPingPong()` + `Halt("circuit_breaker_pingpong")` | TD-02 § 7.4 lines 1506-1510 | Low |
| 07.4 | 🟠 HIGH | DI table row #10 + Phase B Init + Orchestrator field ยังคง wire CCircuitBreaker | TD-02 § 7.3 line 1599 + § 7.4 line 1636 + § 7.1 line 1456 | Medium |
| 07.5 | 🟠 HIGH | classDiagram ยังคงมี `class CCircuitBreaker` + ownership edge + field | TD-02 § 8.1 lines 1763, 1828-1830, 1898 | Low |
| 07.6 | 🟠 HIGH | CleanupPartialInit step 10 (`delete m_breaker`) จะ fail G1 compile หลัง Claim 07.1/07.4 fix applied | TD-02 § 7.4.1 line 1705 | Low |
| 07.7 | 🟡 MEDIUM | Access Pattern Matrix row ยังคงมี CircuitBreaker writes halt event via TJ | TD-04 § 9 line 500 | Low |
| 07.8 | 🟡 MEDIUM | CEAState skeleton comment ระบุ CircuitBreaker เป็น halt trigger source | TD-02 § 7.0.3 line 1418 | Low |
| 07.9 | 🟡 MEDIUM | Logger ErrorBypassThrottle comments cite CircuitBreaker เป็น halt-trigger caller | TD-02 § 5.7 line 854 + § 9.4 line 2099 | Low |
| 07.10 | 🟡 MEDIUM | Service count statements 5 spots ยังคง "13/16/16 services / Init calls" — count drift | TD-02 lines 24, 465, 1584, 1683, 2512 | Medium |
| 07.11 | 🟡 MEDIUM | File tree ยังคงระบุ `services/CircuitBreaker.mqh` | TD-02 § 2 line 66 | Low |
| 07.12 | 🟡 MEDIUM | TD-03 Alert popup trigger list ยังคง "CircuitBreaker triggered" | TD-03 § 2 line 42 | Low |
| 07.13 | 🔵 LOW | `Last updated:` stamps ทั้ง 3 ยังคงเป็น 2026-05-02 (pre-BT-002 by 16 days) | TD-02 line 5 + TD-03 line 6 + TD-04 line 5 | Low |
| 07.14 | 🔵 LOW | § 10 Cross-Domain Trace Matrix ไม่มี row หรือ note สำหรับ ADR-013 + ADR-014 (Superseded by BT-002) | TD-02 § 10.1 line 2192 + § 10 header | Low |

> **Total: 14 findings (2 CRITICAL + 4 HIGH + 6 MEDIUM + 2 LOW) across 3 TD docs × 23 edit sites; expected rebuttal effort ~90 min.** Trajectory contradicts Round 06 "0 findings — certified" stamp because BT-002 upstream backtrack landed 15+ days after that certification — this is the methodology-compliant re-open, not a regression.
