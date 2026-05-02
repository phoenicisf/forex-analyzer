# 07 — Future Evolution

> **Phase:** Phase 1B (System Design) — Doc 5/6
> **Author:** Architect agent (`/sd` workflow)
> **Last updated:** 2026-05-02
> **Reads:** `02-high-level-architecture.md`, `docs/adr/*`, `docs/ba/01-project-brief.md § 6` (Won't), `docs/ba/03-non-functional-requirements.md § 5 Note` (Phase 2 trigger)
> **Audience:** Tech Lead (Phase 1D TD), Impl Planner, future Architect (Phase 2+)

## TL;DR

PhoenicisNex Phase 1 = **greenfield rewrite of single-user EA inside MT5 process** — ไม่มี cross-service dependency, ไม่มี multi-instance scale-out, ไม่มี migration จาก legacy production system. **Evolution Sequence ของ Phase 1 internal sequencing = 2 entries** (E1 atomic-write spike chain + E2 CSlotBase contract chain — ดู § 6); multi-service / migration / external API ordering = ไม่อยู่ใน Phase 1 (greenfield monolith). เอกสารนี้รวบ **scaling triggers** (เมื่อไหร่ revisit architecture decision), **migration paths** (จาก JSON-Lines → SQLite, จาก single-instance → multi-account, จาก local → cloud journal), **deprecation considerations** (Hyrum's Law mitigation สำหรับ external observable behavior — trade journal schema, state.json schema, slot magic pool, comment prefix), และ **tech debt list** ที่ Phase 1 leave behind. Ordering ของ Phase 2 work = decision ของ Impl Planner / future PM, ไม่ใช่ SD.

---

## 1. Scaling Triggers

ตารางนี้ระบุ **architectural decisions ที่ควร revisit** เมื่อ system characteristic เปลี่ยน. แต่ละ trigger lists **measurement** ที่ user/QA detect + **ADR ที่กระทบ** + **proposed action**

### 1.1 Performance scaling triggers

| Trigger | Measurement | ADR affected | Proposed action |
|---------|-------------|--------------|------------------|
| Tick latency overhead > 15% (vs NFR-2.1 = 10%) | NFR-2.1 measurement protocol p95 | ADR-002 (virtual call), ADR-003 (indicator service), ADR-004 (struct copy), ADR-005 (CHashMap) | Profile per-stage timing → identify bottleneck → revisit relevant ADR (e.g., switch slot dispatch from virtual to switch-on-enum if ADR-002 dominant cost) |
| Journal write p95 > 10 ms sustained | NFR-2.2 measurement | ADR-006 | Switch from sync write to timer-based async queue (MQL5 Timer event); add per-event sequence number for ordering |
| State.json write > 5 ms sustained | NFR-2.1 budget breach | ADR-007 | Add dirty-bit throttle (skip Save if no state changed); evaluate selective field write |
| Strategy Tester run > 2× original (vs NFR-2.3 = 1.5×) | NFR-2.3 | FR-8.1 cache, ADR-005 CHashMap | Profile tester-mode; tune cache; consider tester-only sparse refresh |
| Indicator buffer size > 200 KB (memory pressure) | MT5 Task Manager memory | ADR-003 | Reduce buffer depth (default 300 bars); buffer compression unlikely needed |

### 1.2 Functional scaling triggers

| Trigger | Measurement / Event | ADR affected | Proposed action |
|---------|---------------------|--------------|------------------|
| Slot count target > 30 (Phase 2 add slot) | User decision to add new strategy | ADR-002, ADR-005, ADR-012 | Revisit slot dispatch (virtual call overhead at 30+); CHashMap entry budget; per-slot input file growth |
| Multi-symbol portfolio | C-3 changed (Phase 2) | ADR-001 (single-process intra-MT5), ADR-005 (PortfolioState scoped to symbol) | Multi-instance MT5 + separate EA copy per symbol (preserve ADR-001) OR per-symbol PortfolioState namespace inside single EA |
| Multi-account / risk allocator | Change to C-9 solo + cross-account | ADR-001 | Multi-instance pattern; possibly add coordinator EA Phase 3 |
| New cross-slot helper function | User strategy evolution | `services/CrossSlotCoordinator` (no ADR — internal extension) | Add method; ADR not needed unless pattern changes |
| External news feed integration | Q4.2 promotion | NFR-7.2 (DLL allowance), ADR-001 | Native MT5 webrequest first; if too limited → Phase 2 DLL allowance + installer |

### 1.3 Reliability scaling triggers

| Trigger | Measurement / Event | ADR affected | Proposed action |
|---------|---------------------|--------------|------------------|
| State.json corrupt > 1% in NFR-3.1 test (assumption A2 fail) | TD spike or QA find | ADR-007 | Switch to ADR-007 Option B double-buffered swap |
| Pending force-clear count > 5/session per machine | Logger warn pattern | ADR-008 | Tune up `InpForceClearX_Bars`; investigate stuck pattern in journal |
| Logger ERROR throttle suppresses real distinct errors | Operator missing critical event | ADR-011 | Lower throttle threshold; introduce per-error-type bypass |
| Journal write fail > 1/day sustained | User report | ADR-006 | Add MT5 folder to AV exclusion; verify disk health; consider fallback Print() sink |
| User reports HALTED but never enters HALTED_STABLE | Trade journal pattern | ADR-010 | Investigate stuck open position with no exit signal; manual close + EA restart; root-cause exit logic for affected slot |

### 1.4 Capacity scaling triggers

| Trigger | Measurement | Proposed action |
|---------|-------------|------------------|
| Journal monthly file > 1 MB | File size on disk | Switch rotation = weekly or daily (ADR-006 input) |
| State.json > 50 KB | File size | Force-clear thresholds too lax; tune down or audit pending payload bloat |
| MT5 Experts log overflow ที่ default 1 MB native cap | MT5 log behavior | User manage MT5 log; consider separate file sink (ADR-011 Phase 2) |
| Total LOC > 30,000 (rewrite slightly larger than monolith เดิม) | Phase 1D TD measurement | Tighten module boundaries; consider precompiled headers (limited MQL5 support) |

---

## 2. Migration Paths

ระบุ **path forward** สำหรับ schema/architecture migrations ที่ Phase 2 อาจต้องทำ

### 2.1 Trade journal: JSON-Lines → SQLite (P3.8)

**Trigger:** user requests query/filter UI, or journal grows > 100 MB, or NFR-7.2 relaxed (DLL allowed)

**Path:**
1. Phase 1 baseline: per-record `schema_version: 1` field (ADR-006)
2. Phase 2 step E1: write SQLite migrator (offline tool, Python) reading JSON-Lines + populating SQLite
3. Phase 2 step E2: dual-write phase — EA writes both JSON-Lines AND SQLite for N months (verification)
4. Phase 2 step E3: switch reader to SQLite; deprecate JSON-Lines (keep archive)
5. Phase 2 step E4: remove JSON-Lines write (cutover)

**Hyrum's law concern:** if user wrote analysis scripts against JSON-Lines → break on cutover. Mitigation: keep JSON-Lines export tool alongside SQLite

### 2.2 State persistence: JSON → SQLite WAL (P3.8 alt)

**Trigger:** state.json > 50 KB OR atomic write reliability concern beyond ADR-007 fallback

**Path:**
1. Phase 1 baseline: `schema_version: 1` in `state.json`
2. Phase 2: design SQLite WAL schema (per-table for each pending machine + ban dates + WatchProfits)
3. Phase 2: migration script JSON → SQLite (offline)
4. Phase 2: switch StatePersistence backend; preserve API (slot doesn't see change)

**Hyrum's law concern:** user inspects `state.json` for debug → migrating to SQLite breaks workflow. Mitigation: `state.json` export tool from SQLite

### 2.3 Single-instance → Multi-account portfolio

**Trigger:** user opens N FBS accounts + wants centralized risk management

**Path:**
1. Each account = own MT5 instance (preserve ADR-001 single-process per instance)
2. Phase 3 introduce **PhoenicisCoord EA** ที่ run บน meta-account; reads each instance's `state.json` + `journal` (read-only mount via shared folder); aggregates cross-account positions
3. PhoenicisCoord publishes recommended position adjustments via shared file `coord-output.json`; instance EAs read + decide

**Architectural rationale:** preserve EA-per-account isolation; coordination = file-based (no DLL, no IPC); slow loop is OK for risk allocator (1-min refresh sufficient)

### 2.4 Local → Cloud journal sync (Phase 2)

**Trigger:** Q3.4 (Telegram) promoted; OR user wants cross-device journal access

**Path:**
1. Phase 2 introduce sidecar agent (Python on user's PC) that watches `journal/*.jsonl` + uploads to cloud (S3, gist, etc.)
2. EA unchanged — still writes local
3. NFR-7.2 unchanged (no DLL in EA)

**Security implication:** § 4 of `05-security.md` triggers AuthN/AuthZ + transport encryption (cloud endpoint); Phase 2 BA work needed

### 2.5 Add new slot Phase 2 (e.g., revive Slot U)

**Trigger:** user decides to re-introduce Slot U (FR-2.2 currently deletes)

**Path:**
1. Write `Slot_U.mqh` from CodeWiki §3 spec (paper exists)
2. Add `Inputs_Slot_U.mqh`
3. Register in `SlotRegistry::RegisterAll()` at correct topo position
4. Magic 220 (currently unused per BR-1.1 deletion) reassigned to U
5. QA regression vs baseline; bucket A drift if any

No ADR change required (architecture supports per AC-2.5.3)

---

## 3. Deprecation Considerations (Hyrum's Law Awareness)

ทุก observable behavior ที่ external user/script อาจ depend on → Phase 1 design ต้อง consider deprecation path

### 3.1 Trade journal schema (ADR-006)

**Observable surface:**
- File path `MQL5/Files/PhoenicisNex/journal/{live|tester}/journal-YYYYMM.jsonl`
- JSON record fields (timestamp, event_type, slot_id, ...)
- Field names (snake_case)

**Hyrum's risk:** user เขียน Python/jq script ที่ depend on field name + path

**Lifecycle plan:**
- Phase 1 = stable schema_version 1 (lock ที่ `docs/api-specs/trade-journal-schema.yaml`)
- Add field = no breaking; consumers must ignore unknown
- Remove/rename field = bump schema_version; provide migration script + N-month dual-write window
- Path change = treat as breaking; user gets advance notice

### 3.2 State.json schema (ADR-007)

Same lifecycle rules as journal — see § 3.1

**Additional concern:** `state.json` is read-write by EA only; user reading is debug-only. Deprecation less risky than journal

### 3.3 Slot magic pool (BR-1.1)

**Observable surface:** order Magic numbers 200..220 visible in MT5 trade history + broker reports

**Hyrum's risk:** user (or external analytics tool) depend on magic = slot ID mapping

**Lifecycle plan:**
- Phase 1 = locked; magic 220 deleted with Slot U (could revive Phase 2)
- Phase 2 if user wants to resolve shared-magic (G/G2, B/BI, C/D, L/LX) → assign new magic + maintain mapping table; comment prefix becomes redundant but kept for backward-readability

### 3.4 Comment prefix convention (BR-1.2)

**Observable surface:** order comment field "C,...", "G2,...", "BI,..."

**Hyrum's risk:** user trade history queries use comment substring

**Lifecycle plan:** Phase 1 stable; Phase 2 if shared-magic resolved → comment prefix becomes optional but kept; deprecate notice 6 months before removal

### 3.5 Input parameter names (NFR-4.3, ADR-012)

**Observable surface:** MT5 input dialog labels + Strategy Tester optimization sweep config

**Hyrum's risk:** user has saved tester `.set` files referencing input names

**Lifecycle plan:**
- Phase 1 lock all ≥ 80 input names + types in `inputs/Inputs_*.mqh`
- Add input = backward compat (default value preserves baseline)
- Rename input = breaking; provide migration `.set` file converter; document in changelog

### 3.6 EA file path / name

**Observable surface:** `MQL5/Experts/PhoenicisNex/PhoenicisNex.ex5` path, EA name in chart attach dialog

**Lifecycle plan:** Phase 1 stable; Phase 2 if rename (e.g., PhoenicisNex2) → keep PhoenicisNex.ex5 alias for backward chart-template compatibility

---

## 4. Tech Debt Phase 1 Leaves Behind

ระบุ explicit ของสิ่งที่ Phase 1 ตัดสินใจ defer + reason — Phase 2 ผู้รับ inherit

| Debt item | Reason for deferral | When to address |
|-----------|---------------------|------------------|
| Shared-magic G/G2 + B/BI + C/D + L/LX | BR-1.1 preserve baseline 1:1 | Phase 2 — resolve when behavioral baseline proven (G3 met across N months live) |
| Equity-floor enforcement (OQ-6) | User decision = monitor-only | Phase 2 — promote when journal data reveals threshold |
| FR-7.7 escalation alert (long-running halt + away user) | MVP signal no Telegram/notification backend | Phase 2 — when notification capability added |
| Security NFR category (AuthN/AuthZ, encryption) | Local-only EA, no surface | Phase 2 — when cloud journal or remote sync added |
| Walk-forward optimization interface (P3.7) | Strategy Tester sweep sufficient MVP | Phase 2 — when manual sweep workflow burdensome |
| Real-time dashboard panel (P3.5) | Solo operator + MT5 native enough | Phase 2 — if multi-account / multi-monitor workflow |
| Per-slot opt-out from Safe port (FR-8.3) | Demoted to Could under MVP | Phase 2 — input added, semantic preserved |
| Slot D / BR / BI sub-folder visibility (P2.2) | Refactor partial covered by ADR-002 1 file/slot | Phase 1 done; if naming further refactor needed → Phase 2 |
| LibCommon1.1 / LibIndicator1.1 / LibSubDem1.6 / LibDatabase1.1 / LibMonitor1.1 audit + integration | TD Phase 1D will assess which lib still useful (some may be replaceable by services in `services/`) | TD Phase 1D + Implementation phase |
| Schema migration tooling (offline) | Out of EA scope | Phase 2 if SQLite migration triggered |

---

## 5. Phase Hint Routing — to Impl Planner

> **Note:** SD ไม่ assign sprint/dates/capacity. ลำดับ Phase 1 work breakdown + per-task metadata อยู่ใน `08-product-breakdown.md`. ของ Phase 2 work breakdown = **Phase 2 BA / SD work** — ไม่อยู่ในเอกสารนี้

---

## 6. Evolution Sequence (Phase 1 internal — hard architectural ordering)

> Architectural ordering constraints — hints สำหรับ Impl Planner. **ไม่ใช่ delivery schedule**
> ทุก step ต้อง backed by architectural rationale (อ้าง ADR + risk + dependency)
> Impl Planner override ได้เฉพาะผ่าน `/backtrack sd` (vs Phase Hints ที่ override ได้พร้อม documented reason)

### 6.1 Phase 1 internal sequence

| # | Evolution Step | Must Precede | Architectural Rationale |
|---|----------------|--------------|--------------------------|
| **E1** | TD spike: verify MT5 sandbox `FileMove` atomic guarantee (IMPL-046) | E1a, E1b | ADR-007 primary path (Option A single state.json + temp+rename) ผูกกับ assumption A2; spike outcome กำหนด design lock — pass = Option A; fail = activate ADR-007 Option B (3-file double-buffered swap; designed-but-not-primary). ทำ IMPL-047/IMPL-049 ก่อน spike = risk re-architect cost |
| E1a | Implement `services/StatePersistence::Save()/Load()` (IMPL-047) | E1c | depends on E1 outcome — Option A vs B ส่ง different schema (single state.json vs 3-file rotation) |
| E1b | Lock `state-persistence-schema.yaml` (IMPL-048) | E1c | schema layout depends on E1 outcome (3-file extension if Option B) |
| E1c | Implement `services/PendingMachineRegistry::TickAll()` + 7 machines + ADR-008 force-clear (IMPL-049) | E2 (slot impl) | pending state machines persist via StatePersistence — design lock prerequisite |
| **E2** | Implement `domain/CSlotBase.mqh` abstract interface + 2-layer override enforcement (IMPL-018) | IMPL-019..039 (21 derived slots) | MQL5 ไม่มี `=0` pure virtual = base class design + sentinel + boot-time check ต้อง stable ก่อน derived class implement ได้ (ADR-002 § Pure-virtual override enforcement) |

### 6.2 Why Phase 1 needs Evolution Sequence (vs round-0 "N/A" claim)

Round-0 draft อ้าง "greenfield monolith → no Evolution Sequence". Re-examination เผยว่า project มี **2 hard architectural orderings ที่ qualify** ตาม sd.md § Phase Contract:

1. **Risk gate ordering** — IMPL-046 spike result drives ADR-007 design lock; IMPL-047/049 cannot lock schema until spike outcome known. นี่คือ "risky new tech ต้อง fail-fast early" pattern ใน prompt template § Evolution Sequence "Include เมื่อ..." rule
2. **Inheritance contract ordering** — CSlotBase abstract base + override-enforcement mechanism = **compile prerequisite** สำหรับ derived classes (ภาษา MQL5 inheritance semantic). ถ้า derived class implement ก่อน base lock = re-impl effort if base contract change

Multi-service / migration / external API constraints ยังไม่มี (ตาม greenfield monolith reasoning เดิม) — so Evolution Sequence จำกัดที่ 2 entries ของ Phase 1 internal sequencing เท่านั้น

### 6.3 Cross-reference

- `08-product-breakdown.md § 3 Phase Hints` — Suggested P1 จะ map กับ E1; Suggested P3 จะ map กับ E2 (ดู rationale annotations)
- IMPL-046, IMPL-018, IMPL-047, IMPL-048, IMPL-049 = task-IDs ของ Evolution Sequence steps (Per-Task Metadata table ใน 08 § 4)
- Phase 2 (multi-account coordinator, cloud journal sync, etc.) จะมี own Evolution Sequence ตอน Phase 2 SD ทำ; Phase 1 internal sequence ไม่ส่งผ่าน Phase 2

> **End of 07 — Future Evolution** — 5 scaling-trigger categories, 5 migration paths, 6 deprecation considerations (Hyrum's law), 10 tech debt items deferred, Evolution Sequence = 2 entries (E1 atomic-write spike chain + E2 CSlotBase contract chain)
