# Technical Design Rebuttal Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Claim Review** | `claim-review-01.md` |
| **Date** | 2026-05-02 |
| **Defender Persona** | andm-td-defender (Principal Technical Architect & Design Defense Specialist) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |
| **Files Modified** | TD-02 (`02-backend-design.md`), TD-04 (`04-database-design.md`), ADR-005, ADR-006, ADR-007 (already aligned), ADR-011 (already aligned), `state-persistence-schema.yaml`, `trade-journal-schema.yaml`, SD `04-data-flow.md` (rotation diagram) |

## Summary

| Verdict | Count | % |
|---------|-------|---|
| **Accept** | 20 | 100% |
| **Partial** | 0 | 0% |
| **Reject** | 0 | 0% |

> **Sanity check:** 100% accept rate triggers "Warning — Design had significant issues — implementation was premature" per andm-td-defender persona. Honest reading: round 01 reviewer caught 5 CRITICAL findings (off-by-one cascading 4 docs + DI cycle + ordering bug + missing required schema fields + 3 missing class skeletons) ที่ TD round-00 ส่งออกได้เพราะ Phase 1D ครั้งแรก ไม่มี previous round เป็น dry-run. รับ 100% เป็น signal ว่า TD ต้องการ round 02 review ก่อน lock — ไม่ใช่ defensive mode.
>
> ทุก finding ผ่าน "evidence or it didn't happen" gate: ทุก verdict cite specific section + line + cross-reference doc. ไม่มีการ fix ที่ create new contradiction (cascade check ผ่าน).

### Severity breakdown

| Severity | Count | All verdicts |
|----------|-------|--------------|
| 🔴 CRITICAL | 5 | 5 Accept |
| 🟠 HIGH | 8 | 8 Accept |
| 🟡 MEDIUM | 5 | 5 Accept |
| 🔵 LOW | 2 | 2 Accept |

---

## Claim Responses

### Claim 01.1: 🔴 CRITICAL — slot_states map count off-by-one (16 vs actual 17 magics)

**Verdict:** Accept

**Rationale:** นับตรงตาม BR-1.1 magic pool หลัง OQ-8 ลบ Slot U: distinct magics = 200, 201, 205-219 = **17 entries** (= 21 slots − 4 shared groups (C/D, G/G2, B/BI, L/LX) ที่ share 1 magic per group = 21 − 4 = 17). TD-04 § 3.6 table เองก็ลิสต์ครบ 17 active magics ขัดกับ heading "16 entries" — internal contradiction confirmed. ADR-005 + state-persistence-schema.yaml ก็ผิดเช่นกัน (cascade origin).

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.3
  - Class `CPortfolioState`: `int m_magic_list[16]` → `int m_magic_list[17]` (+ comment explain pool)
  - "16 entries" prose → "**17 entries**" (BR-1.1 derivation appended: 21 − 4 shared groups)
  - Added `int MagicCount() const` accessor for boot-time invariant assertion
- File: `docs/technical-design/02-backend-design.md` § 10.1 — Class↔ADR matrix: `(16 entries by magic)` → `(**17 entries** by magic per BR-1.1)`
- File: `docs/technical-design/02-backend-design.md` § 7.4 — Phase C: เพิ่ม `if (!m_validator.ValidateSlotRegistry(m_portfolio.MagicCount(), 17)) return INIT_FAILED;` (BR-1.1 boot-time invariant check — catch future Phase 2 drift)
- File: `docs/technical-design/02-backend-design.md` Phase C `m_logger.Info("init_ok"...)` ระบุ `magics=17`
- File: `docs/technical-design/04-database-design.md` § 3.2 — `slot_states` row: `(16 keys by magic)` → `(17 keys by magic)` + derivation
- File: `docs/technical-design/04-database-design.md` § 3.6 — Heading + body: `16 entries by magic` → `17 entries by magic` + magic pool list
- File: `docs/technical-design/04-database-design.md` § 3.9 — Constraint description: `16 distinct values 200..219` → `17 distinct values in pool {200, 201, 205-219}` + assertion location
- File: `docs/technical-design/04-database-design.md` § 10 erDiagram — `STATE_ROOT ||--o{ SLOT_STATE : "16 entries by magic"` → `"17 entries by magic"`
- File: `docs/adr/005-portfoliostate-via-chashmap.md` § Decision § Shared-magic handling — `16 entries รวม` → `**17 entries** รวม` + magic pool list + group derivation (cascade root)
- File: `docs/api-specs/state-persistence-schema.yaml` § slot_states description — `16 magic entries given shared magics` → `17 distinct magic entries (200, 201, 205-219) given 21 slots − 4 shared groups`
- File: `docs/technical-design/02-backend-design.md` § 7.0.1 (new) — `CBootstrapValidator::ValidateSlotRegistry(observed, expected)` boot-time assertion ตาม minimum acceptable fix step 5

**Cascaded changes:** TD-02 + TD-04 + ADR-005 + state-persistence-schema.yaml + (BootstrapValidator skeleton → see Claim 01.5).

---

### Claim 01.2: 🔴 CRITICAL — DI cycle Logger ↔ StatePersistence unresolved

**Verdict:** Accept

**Rationale:** ตรวจ § 7.3 row 1 (Logger first) vs row 6 (StatePersistence) — Logger.Init เรียกที่ step 1 รับ `CStatePersistence *state` parameter ที่ service ยังไม่ instantiated จนถึง step 6 → null pointer. ADR-011 § Throttled counter contract ที่ระบุ persist ผ่าน state.json ทำไม่ได้ใน early boot phase — confirmed cycle. § 7.3 round-00 ระบุ "2-phase init" แต่ scope แคบเฉพาะ SP↔PS เท่านั้น; Logger↔SP ไม่ acknowledged.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.7 Logger class skeleton:
  - Removed `CStatePersistence *state` จาก `Init(...)` signature → new `Init(ESeverity, bool, int escalation_n)` (no SP dep)
  - Added `void SetStatePersistence(CStatePersistence *state)` setter — Orchestrator เรียก step 6.5 (post-SP.Init)
  - Added comment ระบุ `m_state == NULL` window (Cycle 1 phase A) = throttle counter no-op until setter called; throttle/escalate logic still work
  - Added `m_state != NULL` guard ใน Error() / EscalateIfThresholdMet() body (§ 9.4)
- File: `docs/technical-design/02-backend-design.md` § 7.3 DI map:
  - Restructured ตาราง to call out **Cycle 1: Logger ↔ StatePersistence** + **Cycle 2: StatePersistence ↔ PortfolioState** explicitly with resolution
  - Added row **6.5** `Logger.SetStatePersistence(m_state)` ระหว่าง row 6 (SP.Init) + row 7 (PortfolioState.Init)
  - Added row **7b** `StatePersistence.SetPortfolioState(m_portfolio)` หลัง row 7
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — pseudocode includes both setters at correct call sites

**Cascaded changes:** Tied to Claim 01.13 (SP setter) + Claim 01.7 (OnInit pseudocode).

---

### Claim 01.3: 🔴 CRITICAL — `m_xslot.SetHalted()` called AFTER `RunExitPass`

**Verdict:** Accept

**Rationale:** ตรวจ § 7.2 OnTick lines 1183-1185 — `RunExitPass(ctx)` (calls slot.ManageExits in topo order) ถูกเรียกก่อน `m_xslot.SetHalted(...)`. Slot G ManageExits ภายในเรียก `m_xslot.TriggerGOverload(...)` (per § 9.6 + ADR-010 enable matrix); GOverload ตรวจ `m_halted` — ที่ tick แรกที่ EA halt → m_halted = false (จาก previous tick) → trigger GO order ใหม่ขณะ HALTED = ขัด ADR-010 enable matrix line 900 + FR-7.7.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 7.2 OnTick:
  - Moved `m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING)` to **step 5b** — ทันทีหลัง step 5 (IndicatorService.AnyHandleInvalid → Halt) + ก่อน step 6 (time gates) / step 9 (RunExitPass)
  - Added comment: *"⚠️ SYNC HALTED STATE FIRST — before any code path that can call TriggerGOverload / RunEOverload"*
  - Updated step 9 comment: *"m_xslot.m_halted already correct from step 5b"*

**Cascaded changes:** None (single-file fix).

---

### Claim 01.4: 🔴 CRITICAL — `JournalEvent` struct ขาด `timestamp/schema_version/mode` fields

**Verdict:** Accept

**Rationale:** trade-journal-schema.yaml § required (lines 19-31) lock 11 required fields รวม `timestamp/schema_version/mode`. § 5.5 struct ลิสต์ 15 fields, ไม่มี 3 fields นี้. § 9.5 BuildRecord เขียน `WriteString("timestamp", TimestampWithMs(ev.timestamp))` — `ev.timestamp` field ไม่ declared = MQL5 compile error. `TimestampWithMs()` function ไม่ defined. Schema authority violated.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.5 struct `JournalEvent`:
  - Added `datetime timestamp_seconds` + `ulong timestamp_microseconds` fields (caller populates ที่ event time)
  - Added documentation that `schema_version` + `mode` = TradeJournal-internal (ไม่ require caller populate) — bumped via constant `JOURNAL_SCHEMA_VERSION` (= 1)
  - Added `#define JOURNAL_SCHEMA_VERSION 1` near struct
- File: `docs/technical-design/02-backend-design.md` § 9.5 BuildRecord:
  - Replaced `TimestampWithMs(ev.timestamp)` → `FormatTimestampWithMs(ev.timestamp_seconds, ev.timestamp_microseconds)` (helper from new `helpers/Timestamp.mqh`)
  - Replaced `WriteInt("schema_version", 1)` → `WriteInt("schema_version", JOURNAL_SCHEMA_VERSION)`
  - Reordered fields to match yaml § required order; added explicit `WriteNull(...)` branches for nullable optional fields (ticket_id, order_type, comment) per yaml `[type, "null"]` types
  - Added reviewer checklist comment
- File: `docs/technical-design/02-backend-design.md` § 9.5 — added new `helpers/Timestamp.mqh` skeleton with `FormatTimestampWithMs(datetime sec, ulong micro)` function
- File: `docs/technical-design/02-backend-design.md` § 2 file layout — added `helpers/Timestamp.mqh` row
- File: `docs/technical-design/02-backend-design.md` § 7.2 OnTick step 14 (halt_stable journal) — now populates `ev.timestamp_seconds` + `ev.timestamp_microseconds` (was missing)

**Cascaded changes:** Tied to Claim 01.9 (Logger format ms precision uses same helper).

---

### Claim 01.5: 🔴 CRITICAL — Core class skeletons absent: BootstrapValidator, SlotRegistry detail, EAState machine

**Verdict:** Accept

**Rationale:** SD `02 § 4.2` Component Catalog ระบุ 3 core components — TD § 4-7 (Domain types + Helpers + 13 services) ไม่มี class skeleton. § 7.1 Orchestrator declares `m_validator` + `m_registry` แต่ไม่มี file skeleton. § 8.1 class diagram มีเฉพาะ stub ของ SlotRegistry. EAState ถูก reduce เป็น enum ใน § 3.1 line 114 — ขัด ADR-010 + SD-02 § 4.2 #5 ที่ระบุชัดว่าเป็น state machine มี Halt() method.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` — เพิ่ม 3 sub-sections ใน § 7 ก่อน § 7.1:
  - **§ 7.0.1 `core/BootstrapValidator.mqh`** — class skeleton พร้อม methods: `ValidateInputs()` (FR-1.4 + BR-4.1/4.2/4.3), `ValidateSymbol()` (FR-1.2 + BR-9.1), `DetectDigitMultiplier()` (BR-9.3), `ValidateSlotRegistry(observed, expected)` (BR-1.1 invariant); injected deps `(CLogger*, CIndicatorService*, CPortfolioState*)` per § 7.3 row 17
  - **§ 7.0.2 `core/SlotRegistry.mqh`** — class skeleton with `CSlotBase* m_slots[21]`, `RegisterAll(...)`, `ValidateTopo()` พร้อม **concrete sentinel-check body** จาก ADR-002 § Decision (loop ทุก slot, check Magic() != -1 + SlotId() != "" + topo dependency order per BR-2.2); accessor `Count() / Get(int)`; `ReleaseAll()` ใน OnDeinit
  - **§ 7.0.3 `core/EAState.mqh`** — class CEAState with `EEAState GetState()`, `Halt(string reason)` (idempotent + emits journal halt event + ErrorBypassThrottle Alert per ADR-010 + ADR-011 § Halt-trigger bypass), `TryTransitionToStable(int active_count)` (HALTED→HALTED_STABLE per AC-7.7.4), `RestoreFromState(...)` (OnInit reset trigger per ADR-010)
- File: `docs/technical-design/02-backend-design.md` § 7.1 Orchestrator class:
  - Added `CEAState *m_ea_state;` field
  - Documented `m_state_enum` + `m_halt_reason` ตอนนี้เป็น cached mirror (single-writer Orchestrator updates inside Halt())
  - `Halt(reason)` body delegate ลง `m_ea_state.Halt(reason)` แล้ว update mirror cache
- File: `docs/technical-design/02-backend-design.md` § 7.3 DI map — added row 19 `CEAState (TradeJournal, Logger)`
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — added `m_ea_state.Init(m_journal, m_logger)` after registry; Phase C added `m_ea_state.RestoreFromState(...)` after state Load
- File: `docs/technical-design/02-backend-design.md` § 7.2 OnTick step 14 — replaced inline `m_state_enum = EA_STATE_HALTED_STABLE` with delegated `m_ea_state.TryTransitionToStable(...)`
- File: `docs/technical-design/02-backend-design.md` § 8.1 class diagram — added `CBootstrapValidator` + `CEAState` classes + dependency arrows from Orchestrator + `CBootstrapValidator → CIndicatorService/CPortfolioState` + `CEAState → CTradeJournal/CLogger`

**Cascaded changes:** Tied to Claim 01.7 (OnInit pseudocode now uses these classes), Claim 01.1 (BootstrapValidator does the BR-1.1 17-magic invariant check), Claim 01.8 (CEAState.Halt is the central halt handler that journal sustained-fail invokes via Orchestrator).

---

### Claim 01.6: 🟠 HIGH — ADR-007 Option B fallback "interface preserved" claim is false

**Verdict:** Accept

**Rationale:** ตรวจ ADR-007 § Option B layout — 3 files (state-A.json + state-B.json + state-meta.bin) + 1-byte single-sector pointer write. AtomicFile API `WriteAtomic(string path, string content, CLogger*)` รับ single path; Option B ต้องการ base directory + active pointer state. Interface fundamentally incompatible. **และ** state-persistence-schema.yaml model เฉพาะ Option A (single state.json) — ไม่มี v2 schema ที่ ADR-007 § Revisit-when ระบุต้อง update.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 4.4 AtomicFile class:
  - **Removed** false claim "interface preserved, downstream ไม่กระทบ"
  - **Added** explicit honesty note (per Claim 01.6 minimum acceptable fix option 4): "Interface NOT preserved across strategies — Option A ใช้ single path, Option B ใช้ base directory + 3 files; แยก method per strategy + dispatcher pattern"
  - Restructured API into 3 method groups:
    - Option A: `WriteAtomic_TempRename(path, content, logger)` + `CleanupOrphanTmp(path, logger)`
    - Option B: `WriteAtomic_DoubleBuffered(base_dir, content, logger)` + `ReadActiveBuffered(base_dir, &out_content, logger)`
    - Strategy selector: `WriteAtomic(path_or_base_dir, content, logger)` — compile-time `#define ATOMIC_STRATEGY_OPTION_B` switch
  - Documented activation contract (3 steps): IMPL-046 spike → flip define → refactor StatePersistence call site (1-2 day rework expected)
- File: `docs/technical-design/02-backend-design.md` § 9.3 Atomic Write Pattern:
  - Updated `CStatePersistence::Save` skeleton to use `#ifdef ATOMIC_STRATEGY_OPTION_B` branch — pass `m_state_dir` (base dir) for Option B vs `m_state_path` (single file) for Option A
  - Added defensive guard `if (m_portfolio == NULL) ... return false;` (Claim 01.13 cascade — surface engineer omission of step 7b setter)

**Cascaded changes:** ADR-007 § Revisit-when contract preserved (Option B activation = unplanned 1-2 day rework, now honestly acknowledged). state-persistence-schema-v2.yaml = Phase 2 deliverable when activation happens (not Phase 1D blocker — TD honestly defer).

---

### Claim 01.7: 🟠 HIGH — TD-02 § 7.4 OnInit pseudo broken syntax + missing 12 service Init() calls

**Verdict:** Accept

**Rationale:** ตรวจ lines 1255-1257 — `if (!m_pip.Init(), /* comment */) goto init_ok_skip;` = comma operator returning void → invalid syntax. § 7.3 ลิสต์ 18 services แต่ § 7.4 มีเฉพาะ ValidateInputs/ValidateSymbol/CreateHandles/Load/RegisterAll/ValidateTopo/Open/Logger.Info — ไม่มี Init() calls สำหรับ 12 services. Composition root pattern (ADR-002) บังคับ wire ทุก dependency; null pointers + null-deref crash ทันที.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit:
  - Replaced broken pseudocode with 3-phase structure: **Phase A** (WireServices + WireSlots = construct on heap) → **Phase B** (Init in dependency order, 18 services + 2 setters) → **Phase C** (validation + recovery)
  - Phase B includes ทุก 18 service Init calls + step 6.5 `Logger.SetStatePersistence(m_state)` + step 7b `StatePersistence.SetPortfolioState(m_portfolio)` (Cycle 1 + Cycle 2 close)
  - Phase B includes new core class init: `m_ea_state.Init(m_journal, m_logger)` (Claim 01.5 cascade)
  - Phase C includes BootstrapValidator boot-time invariant check `ValidateSlotRegistry(m_portfolio.MagicCount(), 17)` (Claim 01.1 cascade) + AtomicFile orphan cleanup + IndicatorService handles + StatePersistence Load + EAState restore + SlotRegistry RegisterAll/ValidateTopo + Journal Open
  - Removed `goto init_ok_skip` + comma-operator hack
  - Added reviewer checklist comment

**Cascaded changes:** All preceding CRITICAL claims (01.1/01.2/01.5/01.13) consumed via OnInit pseudocode.

---

### Claim 01.8: 🟠 HIGH — Journal sustained-failure → halt path declared but not wired in OnTick

**Verdict:** Accept

**Rationale:** ADR-006 § Failure handling table line 82 lock contract; TD-04 § 3.7 line 165 mirror; § 4.3 halt_reason enum lists `journal_write_fail_sustained`. แต่ § 7.2 OnTick (lines 1149-1216) ไม่มี check; § 5.5 declares `HandleWriteFailure` แต่ไม่มี body skeleton; § 9.5 BuildRecord ไม่ branch ไปที่ HandleWriteFailure. Halt trigger missing — schema documents unfulfilled intent.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.5 TradeJournal:
  - Added public method `bool ShouldHaltSustained(int &out_consecutive) const` body skeleton (returns `m_consecutive_failures >= JOURNAL_HALT_THRESHOLD`; surfaces consecutive count for log message)
  - Added `void HandleWriteFailure(string reason)` private method — increments counter + Logger.Error + sets metric on SP
  - Added `ResetConsecutiveOnSuccess()` private — reset counter on successful write (cumulative `write_failures` preserved)
  - Added `#define JOURNAL_HALT_THRESHOLD 10` (per ADR-006 RPO contract)
- File: `docs/technical-design/02-backend-design.md` § 7.2 OnTick:
  - Added **step 13b** — Journal sustained-failure halt check after StatePersistence.Save: poll `ShouldHaltSustained` → if true `Halt("journal_write_fail_sustained")` (delegated to CEAState which emits journal halt + ErrorBypassThrottle Alert per ADR-006 RPO chain)
- File: `docs/api-specs/trade-journal-schema.yaml` § halt_reason enum — added `journal_write_fail_sustained` value (was missing — schema-level fix)

**Cascaded changes:** API spec cascade (added enum value); CEAState skeleton (Claim 01.5) consumes the halt call.

---

### Claim 01.9: 🟠 HIGH — Logger format violates ADR-011 millisecond-precision contract

**Verdict:** Accept

**Rationale:** ADR-011 § Format ระบุ `[YYYY-MM-DD HH:MM:SS.ms][LEVEL]...`. § 9.4 FormatLine ใช้ `TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)` ซึ่ง returns `"YYYY.MM.DD HH:MM:SS"` (no ms; dot separator). Mismatch → retrospective log analysis (per `mt5-log-reader` skill) ไม่สามารถ correlate event ระหว่าง slots ที่ < 1 sec resolution + CircuitBreaker ping-pong threshold = 3000 ms ไม่ debug-able.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 9.4 FormatLine:
  - Replaced `TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)` with `FormatTimestampWithMs(TimeCurrent(), GetMicrosecondCount())` — single source of ms format ที่ TradeJournal ใช้ (Claim 01.4 cascade: same `helpers/Timestamp.mqh::FormatTimestampWithMs`)
  - Apply `StringReplace(ts, "T", " ")` (ADR-011 sep = space; journal keeps ISO 'T')
  - Apply `StringReplace(ts, "Z", "")` (Experts log local view; journal keeps Z)
- File: `docs/technical-design/02-backend-design.md` § 9.4 — Updated `Error()` body to call `EscalateIfThresholdMet(slot, ev)` after Print + Alert + counter increment (Claim 01.12 cascade)

**Cascaded changes:** Helper file (`helpers/Timestamp.mqh`) shared with TradeJournal — single point of ms format = correlation guarantee between Experts log + journal record.

---

### Claim 01.10: 🟠 HIGH — RiskManager.ComputeLot conceals BR-4.1 21-formula table

**Verdict:** Accept

**Rationale:** § 5.4 declares `ComputeLot(slot_id, sl_pips, balance, multiplier)` + comment "per-slot lot calc" — TD ไม่ surface dispatch. BR-4.1 ระบุ 21 different formulas (C=15%×1..2.5, J=`LastBuyLots2 × 0.23`, BI=23.6%×B parent, etc.). Engineer reading TD-02 ไม่มีทางรู้ formula = เอาความเข้าใจคลาดเคลื่อน 1 slot = direct G3 (NFR-1.1) drift.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.4:
  - Updated class fields: added `CPortfolioState *m_portfolio` (for J/BI/I formulas ที่ require parent slot read)
  - Updated `Init(...)` signature to include `CPortfolioState *port`
  - Added 5 private helper methods: `ComputeLotForJ`, `ComputeLotForBI`, `ComputeLotForI`, `ComputeLotForS`, `ComputeLotForK`
- File: `docs/technical-design/02-backend-design.md` § 5.4.1 (new) — **Per-slot formula dispatch table** mirror BR-4.1 row-by-row:
  - 21 explicit `if` branches (C/D/F/J/H/K/G/G2/GO/I/M/L/LX/Q/R/P/T/S/B/BR/BI) ที่แต่ละ row link คืน formula text ตาม BR-4.1
  - Unknown slot_id → `Logger.Error("RiskManager", "unknown_slot_id", ...)` + return 0.0 (fail-loud per ADR-002)
  - Documented `extra_multiplier` semantic per slot (peak / wave / percentTP varies)
  - Reviewer checklist: ทุก slot ใน BR-1.1 (21 entries) ต้องมี explicit branch
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — `m_risk.Init(...)` updated signature to include `m_portfolio`

**Cascaded changes:** RiskManager Init dependencies updated — DI map § 7.3 row 10 implicitly updated to add PortfolioState.

---

### Claim 01.11: 🟠 HIGH — StatePersistence.Load missing GV-recovery semantic per `02 § 6.1.1`

**Verdict:** Accept

**Rationale:** SD `02 § 6.1.1` lock invariant: state.json corrupt + GV intact → Load() defaults + read GV subset (worst_drawdown_*, equity_high_water_mark) เป็น last-resort hint. TD-04 § 5.2 line 274 mirror. § 5.6 round-00 Load signature `bool Load(EEAState&, string&)` ไม่ accept GV-fallback path → invariant violated; corrupt-recovery zeros out worst_drawdown.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.6 StatePersistence:
  - Added private helper `bool TryRecoverFromGV(double &out_worst_dd, double &out_worst_dd_at, double &out_eq_high_water, double &out_current_dd)` — read 4 GV ผ่าน `GlobalVariableGet(...)`; return true if all 4 keys present
  - Added Load() doc-comment: *"ถ้า state.json corrupt + GV intact → recover watch_profits subset จาก GV per `02 § 6.1.1`"*
  - Added GetLoggerThrottledCount() accessor (used by HALTED_STABLE Alert message)
- File: `docs/technical-design/02-backend-design.md` § 12 — added new **§ 12.4 StatePersistence.Load with GV-fallback recovery** sequence diagram showing parse fail → defaults → TryRecoverFromGV → log Warn + journal `state_corrupt_recovered_via_gv` event
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit — Logger.Warn message updated to ระบุ "GV-recovery attempted for watch_profits subset"

**Cascaded changes:** Sequence diagram added without breaking existing ones (Mermaid v11.14 sanitized — no parens / Unicode).

---

### Claim 01.12: 🟠 HIGH — Logger escalation policy from ADR-011 not implemented

**Verdict:** Accept

**Rationale:** ADR-011 § Decision § Escalation policy (line 60) lock: ≥ N consecutive same-(slot,event) → secondary Alert + persist `(slot,event)` ใน `logger_metrics.last_throttle_event`. § 5.7 round-00 มี `m_recent_keys[64]` + `m_recent_tick_count[64]` แต่ไม่มี consecutive-count tracking, ไม่มี `EscalateIfNeeded()`, ไม่มี input `InpErrorEscalationN`. Schema field `last_throttle_event` exists but no writer.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.7 Logger:
  - Added field `int m_escalation_n;` (= InpErrorEscalationN, default 10 per ADR-011)
  - Added field `int m_consecutive_count[64];` parallel array to `m_recent_keys`
  - Added `void EscalateIfThresholdMet(string slot, string event_name);` private method
  - Added `int FindOrEvictKey(string key);` private — LRU eviction when buffer full (Claim 01.20 cascade)
  - Updated `Init(...)` signature to accept `int escalation_n`
- File: `docs/technical-design/02-backend-design.md` § 9.4 Logger Pattern:
  - Implemented `EscalateIfThresholdMet` body — increment consecutive_count; if ≥ m_escalation_n → emit secondary Alert + Print "[ESCALATE]" + persist last_throttle_event + reset counter
  - `Error()` body now calls `EscalateIfThresholdMet(slot, ev)` after throttle path
  - `ErrorBypassThrottle()` does **not** call escalate (halt-trigger errors ไม่ throttle ไม่ escalate)
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — `m_logger.Init(InpLogLevel, InpAlertOnError, InpErrorEscalationN)` (signature aligned)

**Cascaded changes:** `inputs/Inputs_Logging.mqh` ต้องเพิ่ม `input int InpErrorEscalationN = 10;` — documented in § 5.7 comment.

---

### Claim 01.13: 🟠 HIGH — StatePersistence "2-phase init" mechanism: setter method missing

**Verdict:** Accept

**Rationale:** § 7.3 row 6 footnote promised "2-phase init" but § 5.6 round-00 class API มี single-phase `Init(CAtomicFile, CLogger, CPortfolioState)` ที่ takes port at construction. Pattern inconsistency vs Logger ↔ SP cycle (Claim 01.2). MQL5 ห้าม pass-by-reference inside class field; setter pattern เป็น only viable.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.6 StatePersistence:
  - Split `Init(CAtomicFile, CLogger, CPortfolioState)` → `Init(CAtomicFile *atomic, CLogger *logger)` (phase 1, no PortfolioState dep)
  - Added `void SetPortfolioState(CPortfolioState *port)` setter (phase 2)
  - Added defensive guard ใน Save body skeleton: `if (m_portfolio == NULL) { m_logger.Error(...); return false; }` (per Claim 01.13 minimum acceptable fix)
  - Added comment: *"set ผ่าน SetPortfolioState() (2-phase per § 7.3)"*
- File: `docs/technical-design/02-backend-design.md` § 7.3 DI map row 6/6.5/7/7b — explicit ตำแหน่ง setter calls (Claim 01.2 cascade)
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — pseudocode includes both setter calls
- File: `docs/technical-design/02-backend-design.md` § 9.3 — Save() body skeleton includes the defensive guard

**Cascaded changes:** Pattern standardized for both circular deps (Cycle 1 + Cycle 2) per § 7.3 explicit table.

---

### Claim 01.14: 🟡 MEDIUM — TD-04 § 8 sequence + ADR-006 say FileMove; § 6.3 code does FileClose+FileOpen

**Verdict:** Accept

**Rationale:** SD `04 § 8` line 510 + ADR-006 § Decision ระบุ "FileMove(old, archive)". TD-04 § 6.3 RotateIfNeeded code = FileClose + FileOpen new path (no rename). Per-month dedicated filename → rename ไม่จำเป็น. Internal contradiction across 3 docs. Picked Option A (no rename) per Claim 01.14 minimum acceptable fix recommendation (less disk I/O at month boundary; semantic match per-month naming).

**Changes Made:**

- File: `docs/technical-design/04-database-design.md` § 6.3:
  - Added Claim 01.14 alignment note explaining Option A choice + cross-reference to ADR-006 + SD `04 § 8` updated synchronously
  - Updated comment: *"close handle ของ old + open new monthly-named file (no rename)"*
  - Added INVALID_HANDLE error path: `m_logger.Error("system","journal_rotate_open_fail",...)` + fallthrough to next WriteEvent fail (chains ADR-006 RPO escalation per Claim 01.8)
  - Added success-path Logger.Info `journal_rotated`
- File: `docs/adr/006-trade-journal-jsonlines.md` § Decision § Concrete contract — `close handle + rename + open new file` → `close handle + open new monthly-named file. **No rename** เพราะแต่ละเดือนมี dedicated filename...`
- File: `docs/design-docs/04-data-flow.md` § 8 (line 510) — sequence diagram: `FileClose(old) + FileMove(old, archive) + FileOpen(new)` → `FileClose(old) + FileOpen(new monthly-named) — no rename per ADR-006/Claim 01.14`

**Cascaded changes:** SD `04-data-flow.md` updated (cross-domain consistency) + ADR-006 § Decision updated (root contract). Three sources now aligned.

---

### Claim 01.15: 🟡 MEDIUM — PendingMachineRegistry / TimeGate Init signature uses `...inputs...` placeholder

**Verdict:** Accept

**Rationale:** `...inputs...` = TBD-by-explicit-placeholder. Engineer ต้องอ่าน ADR-008 + BR-3.x + BR-6.x เพื่อ derive signature — defeats TD purpose ("engineer หยิบไป code ได้ทันที"). § 7.3 row 13/14 ก็ไม่ list inputs.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.9 TimeGate:
  - Added 5 missing fields: `m_ban_c_cooldown_bars`, `m_ban_l_cooldown_bars`, `m_ban_m_cooldown_bars`, `m_k_last_order_cooldown_bars`, `m_g_pause_cooldown_bars` (per BR-3.4)
  - Replaced `void Init(...inputs..., CPipMath *pip, CStatePersistence *state, CLogger *logger);` with explicit 11-input signature (morning_window_minutes, monday_spread_threshold, holiday_start/end month/day, 5 ban cooldown bars + 3 service pointers)
- File: `docs/technical-design/02-backend-design.md` § 5.10 PendingMachineRegistry:
  - Added 5 missing fields: `m_legacy_c_bars`, `m_legacy_c_adx_bars`, `m_legacy_r_bars`, `m_legacy_p_bars`, `m_legacy_force_bars` (per BR-6.1/6.2/6.3/6.4/6.8)
  - Replaced `void Init(...inputs..., CStatePersistence *state, ...)` with explicit 12-input signature (3 force-clear thresholds + 5 legacy timeouts + 4 service pointers)
- File: `docs/technical-design/02-backend-design.md` § 7.4 OnInit Phase B — `m_time.Init(...)` + `m_pending.Init(...)` calls now use explicit named-input pseudocode

**Cascaded changes:** None (signatures self-contained).

---

### Claim 01.16: 🟡 MEDIUM — TD-04 § 3.8 logger_metrics missing "Mirror to GV?" column

**Verdict:** Accept

**Rationale:** § 3.8 round-00 = 6-column table; § 3.4 watch_profits = 7-column table (มี "Mirror to GV?"). § 5.1 GV table includes `PhoenicisNex_logger_throttled_alert_count` mirroring `state.logger_metrics.throttled_alert_count` แต่ § 3.8 ไม่ surface — engineer ที่อ่าน § 3.8 isolated จะ assume only watch_profits ผ่าน GV → SyncToGlobalVariable code ขาด 1 GV write.

**Changes Made:**

- File: `docs/technical-design/04-database-design.md` § 3.8 logger_metrics — added "Mirror to GV?" column (matches § 3.4 style):
  - `throttled_alert_count` → ✅ `PhoenicisNex_logger_throttled_alert_count` (per § 5.1)
  - `last_throttle_event` → — (string ไม่สามารถเก็บใน GV ที่รองรับ double เท่านั้น)

**Cascaded changes:** None (single-table fix; § 5.1 already lists the GV — now § 3.8 surfaces it).

---

### Claim 01.17: 🟡 MEDIUM — TD-04 § 6.3 MQL5 code uses C++ brace-init not supported by MQL5

**Verdict:** Accept

**Rationale:** Line 313 round-00: `datetime month_start = StructToTime(MqlDateTime{now_dt.year, now_dt.mon, 1, 0, 0, 0});` — MQL5 compiler rejects C++ uniform-init `Type{...}`. `mql-developer` skill convention enforces field-by-field. Engineer copy-paste = G1 gate compile fail.

**Changes Made:**

- File: `docs/technical-design/04-database-design.md` § 6.3 RotateIfNeeded:
  - Replaced `MqlDateTime{...}` brace-init with field-by-field assignment (year/mon/day/hour/min/sec)
  - Added inline comment: *"MQL5 ไม่มี C++ uniform-init — Claim 01.17"*
  - Added § 6.3 narrative note above code: *"MQL5 syntax fix (Claim 01.17): Original code used C++ uniform-init `MqlDateTime{...}` — MQL5 compiler rejects."*

**Cascaded changes:** None (single-file MQL5 syntax fix).

---

### Claim 01.18: 🔵 LOW — § 6.2 slot template SetBan has no slot_id allowlist check

**Verdict:** Accept

**Rationale:** § 6.2 line 1025 round-00: `m_time.SetBan("<X>", ctx.tick_time);` with comment "if applicable" — no enforcement. § 5.9 SetBan accepts any slot_id; state-persistence-schema § ban_dates supports only 5 keys. Engineer copy template ลง Slot_F.mqh + call SetBan("F", ...) → silent error or unknown behavior. NFR-3.4 "0 silent failures" violated.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.9 TimeGate:
  - Added private helper `bool IsBanAllowedSlot(string slot_id) const` returning true only for {C, L, M, K, G}
  - Updated SetBan / IsBanned doc-comment: *"slot_id allowlist enforced — calls outside list → Logger.Error('TimeGate','ban_unknown_slot',...) + early return (no silent failure per NFR-3.4)"*
- File: `docs/technical-design/02-backend-design.md` § 6.2 slot template:
  - Updated SetBan comment: *"⚠️ SetBan ONLY for slots ใน BR-3.4 allowlist {C, L, M, K, G} — other slots OMIT this call. TimeGate.SetBan ภายในมี allowlist guard per Claim 01.18"*
  - Updated invocation line: *"BR-3.4 — keep ONLY if X ∈ {C, L, M, K, G}"*

**Cascaded changes:** None (template clarity + service guard).

---

### Claim 01.19: 🔵 LOW — § 13.4 jq commands assume bash; Windows native PS workflow undocumented

**Verdict:** Accept

**Rationale:** Project environment = Windows 11 + PowerShell. § 13 round-00 ใช้ bash syntax (head, jq, sort, uniq -c) ที่ PowerShell native ไม่มี → engineer copy-paste fail. `mt5-log-reader` skill mentions Git Bash availability — TD ไม่ surface dependency.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 13 — added shell environment disclaimer at top of section: *"All shell snippets ใน § 13 assume Git Bash (bundled with Git for Windows). Required deps: jq via winget install jqlang.jq or jq-win64.exe..."* + WSL alternative note + PS-native alternative cross-reference
- File: `docs/technical-design/02-backend-design.md` § 13.4 — added **PowerShell-native alternative** sub-block with 3 equivalent commands (per-event-type count, per-slot entry count, G4 BI SL audit) using `ConvertFrom-Json | Group-Object | Select-Object`
- Added performance note: *"PowerShell ConvertFrom-Json อ่าน JSON-Lines ได้แต่ slow > 10k records; Git Bash + jq เร็วกว่า ~10× สำหรับ regression run"*

**Cascaded changes:** None (workflow doc clarification).

---

### Claim 01.20: 🟡 MEDIUM — Logger throttle buffer 64 vs 100-tick window: rationale + eviction policy missing

**Verdict:** Accept

**Rationale:** § 5.7 round-00 declares `string m_recent_keys[64]` ไม่มี rationale; ADR-011 ไม่ระบุ eviction policy. ระบบ 21 slots × N event types — distinct tuple pool อาจ > 64 ใน high-error scenario → buffer overflow undefined; NFR-3.4 transparency edge case.

**Changes Made:**

- File: `docs/technical-design/02-backend-design.md` § 5.7 Logger fields — added rationale + eviction policy block-comment:
  ```
  // Capacity rationale (per ADR-011): worst-case = 21 slots × 3 high-cardinality events
  //   (entry/exit/reject) = 63 distinct tuples; 64 = +1 headroom.
  // Eviction policy: ที่ buffer full + new tuple → evict entry ที่ tick_count oldest (LRU)
  //   + emit Logger.Warn `"throttle_buffer_evicted"` for visibility (tunable via Init param).
  ```
- File: `docs/technical-design/02-backend-design.md` § 5.7 — added private method `int FindOrEvictKey(string key)` declaration (LRU eviction)
- File: `docs/technical-design/02-backend-design.md` § 9.4 — `EscalateIfThresholdMet` body uses `FindOrEvictKey` (cascade with Claim 01.12)

**Cascaded changes:** None (single-class clarification).

---

## Cascaded Changes (cross-domain consistency fixes)

These changes were made to artifacts NOT directly cited in claim Locations, due to cross-domain consistency cascade:

| File | Change | Triggered by |
|------|--------|---------------|
| `docs/api-specs/state-persistence-schema.yaml` | Updated `slot_states` description "16 magic entries" → "17 distinct magic entries (200, 201, 205-219) given 21 slots − 4 shared groups" | Claim 01.1 (cross-domain X1) |
| `docs/adr/005-portfoliostate-via-chashmap.md` § Decision § Shared-magic handling | "16 entries รวม" → "**17 entries** รวม" + magic pool list + group derivation | Claim 01.1 (cross-domain X1) |
| `docs/adr/006-trade-journal-jsonlines.md` § Decision § Concrete contract | Removed FileMove from rotation phrasing; added "no rename" note | Claim 01.14 (cross-domain X6) |
| `docs/design-docs/04-data-flow.md` § 8 (line 510) | Updated sequence diagram: removed FileMove(old, archive); added Claim 01.14 cross-reference comment | Claim 01.14 (cross-domain X6) |
| `docs/api-specs/trade-journal-schema.yaml` § halt_reason enum | Added `journal_write_fail_sustained` enum value + description | Claim 01.8 (cross-domain X3) |
| `docs/technical-design/02-backend-design.md` § 2 file layout tree | Added `helpers/Timestamp.mqh` row | Claim 01.4 (new helper for ms format) |
| `docs/technical-design/02-backend-design.md` § 8.1 class diagram | Added `CBootstrapValidator` + `CEAState` classes + 6 dependency arrows | Claim 01.5 (new core classes need diagram representation) |
| `docs/technical-design/02-backend-design.md` § 12 (Flow Appendix) | Added § 12.4 StatePersistence.Load with GV-fallback recovery sequence diagram | Claim 01.11 (recovery path needed visual) |

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **Accept Rate** | 20/20 = 100% | Round 01 reviewer ทำงานหนัก — แตะทั้ง code skeleton bugs (5 CRITICAL) + interface design gaps + cross-domain inconsistencies. Round 00 TD ส่งออกไปได้เพราะ Phase 1D ครั้งแรก ไม่มี dry-run; รับ 100% เป็น signal ว่า round 02 review จำเป็น |
| **Critical Fixes** | 5 (all CRITICAL accepted) | (01.1 cross-domain off-by-one × 4 docs cascade) + (01.2 DI cycle Logger↔SP) + (01.3 SetHalted ordering = ADR-010 contract) + (01.4 schema-required field gap) + (01.5 missing class skeletons that block IMPL-015/016/018/052) |
| **Cross-Domain Fixes** | 8 (X1-X7 + 1 helper file) | ADR-005 + state-persistence-schema (count) / SD `04 § 8` + ADR-006 (rotation) / ADR-007 § Revisit-when (Option B honesty) / trade-journal-schema (halt_reason enum bump) / new helpers/Timestamp.mqh (ms format single point) / new § 12.4 sequence (GV-recovery visualization) |
| **Net Improvement** | Significant (compile-broken syntax + null-deref crashes + ADR contract violations + schema-required field omissions all caught + fixed) | TD round-00 ที่ engineer หยิบไป implement จะ block ที่ 4 G1 gate fails (compile errors ใน 01.4 + 01.7 + 01.17 + 01.13) + 2 runtime crashes (01.2 + 01.13 null-deref) ภายใน first hour. Round-01 fix → engineer มี clean compile path + correct semantic |
| **Remaining Gaps** | 0 from this round | Round 01 = 20 findings → all addressed. ⚠️ Open assumptions (A1-A7) preserved — those carry forward to QA Phase 3T spike (IMPL-046 atomic write, IMPL-068 force-clear thresholds, IMPL-034 P-Pending E/N) — ไม่ใช่ TD round-02 scope |

### Round-over-round trend (informational — first round)

| Round | Findings | Critical | High | Medium | Low | Resolved this round |
|-------|----------|----------|------|--------|-----|----------------------|
| 01 (current) | 20 | 5 | 8 | 5 | 2 | 20 (100%) |

> สำหรับ TD-rebuttal cycle goal — convergence to 0 findings ภายใน 3-4 rounds (parallel to BA + SD trajectory ที่ใช้ 3-4 rounds ลด CRITICAL → 0). Round 02 ควรเน้น re-verify 5 CRITICAL fixes (off-by-one cascade ครบ + DI cycle resolution + ordering bug fix + schema field completeness + new core class skeleton ครบ method body).

---

## Recommendation

- [x] **Request Re-Review (round 02)** — significant changes made across 9 files (5 TD-related + 2 ADR + 2 schema + 1 SD); reviewer should verify:
  - Off-by-one (01.1) cascade ครบ ทั้ง 4 docs + ADR + schema
  - DI cycle resolution (01.2 + 01.13) — สอง setter calls (step 6.5 + 7b) ใน OnInit pseudocode + Save() defensive guard
  - Ordering bug fix (01.3) — SetHalted ที่ step 5b vs after-step-9
  - Schema field completeness (01.4 + 01.8) — JournalEvent struct + halt_reason enum value
  - New core class skeletons (01.5) — CBootstrapValidator + CSlotRegistry detail + CEAState method bodies
  - Atomic write honesty (01.6) — false claim removed; dispatcher pattern documented; activation 1-2 day rework expected
- [ ] ~~Ready for Implementation Handoff~~ — premature; round 02 should verify cascade fixes ก่อน lock TD
- [ ] ~~Needs SD Backtrack~~ — no SD architecture decisions changed (only ADR-005/006 + SD `04 § 8` aligned with TD/ADR-007 Option B already designed); cycle deps + ordering bug are TD-internal implementation issues
- [ ] ~~Needs Stakeholder Input~~ — no deferred items block further progress; A1-A7 risks carry forward to QA Phase 3T (per existing TD plan)

> **Total effort estimate:** Round 02 review window ~ 3-5 day; if zero new findings → ready for Implementation Handoff. Open assumptions A1-A7 carry to QA Phase 3T spike (IMPL-046 atomic write, IMPL-068 force-clear, IMPL-034 P-Pending) — independent of TD lock.
