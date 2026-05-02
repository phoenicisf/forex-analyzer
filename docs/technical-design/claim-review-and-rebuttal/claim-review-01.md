# Technical Design Claim Review Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Target Document** | `all` (TD-02 backend, TD-03 frontend, TD-04 database) |
| **Date** | 2026-05-02 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 5 |
| HIGH | 8 |
| MEDIUM | 5 |
| LOW | 2 |
| **Total** | **20** |

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Reference in Backend Design | ✅ Pass | `02 § 10.1` Class↔ADR↔API spec matrix complete; `slot-abstraction-contract.yaml` referenced; ไม่ restate schema ใน TD |
| 2 | Backend Module Boundaries | ⚠️ Finding | `#include` direction documented (§ 2); BootstrapValidator/SlotRegistry/EAState referenced แต่ class skeleton ขาด → Claim 01.5 |
| 3 | Backend Interface Contracts | ⚠️ Finding | RiskManager.ComputeLot interface ปกปิด BR-4.1 21-formula table → Claim 01.10; PendingMachineRegistry.Init signature uses `...inputs...` → Claim 01.15 |
| 4 | CQRS/Command-Query Separation | ✅ N/A | SD ไม่ได้เลือก CQRS — modular monolith intra-process per ADR-001 |
| 5 | Frontend Component Hierarchy | ✅ Pass | TD-03 N/A justified ครบ (UX phase officially skipped 2026-05-02 + ADR-011 sink lock) |
| 6 | Frontend State Management | ✅ N/A | TD-03 N/A — no custom frontend |
| 7 | Frontend-Backend Contract Alignment | ✅ N/A | TD-03 N/A |
| 8 | Database Schema Completeness | ⚠️ Finding | slot_states map count off-by-one (16 vs 17 magic) → Claim 01.1; logger_metrics GV mirror unsurfaced → Claim 01.16 |
| 9 | Database Index Strategy | ✅ Pass | File-based — rotation + key-based naming = "index" equivalent; TD-04 § 6 documented |
| 10 | Database Migration Safety | ⚠️ Finding | ADR-007 Option B fallback ไม่มี schema model + AtomicFile API ไม่รองรับ → Claim 01.6 |
| 11 | Design Pattern Justification | ✅ Pass | Pattern decisions อยู่ใน ADRs (ADR-001..012); skeletons อยู่ใน TD-02 § 9 |
| 12 | Sequence Diagram Coverage | ⚠️ Finding | TD-04 § 8 rotation diagram contradicts § 6.3 RotateIfNeeded code → Claim 01.14 |
| 13 | Sequence Diagram Accuracy | ⚠️ Finding | OnTick step ordering: m_xslot.SetHalted called AFTER RunExitPass → slot.ManageExits sees stale m_halted → Claim 01.3 |
| 14 | Testability in TD-02/03/04 | ✅ Pass | Constructor injection enforced; seam points = service interfaces; § 13 Definition of Done documented |
| 15 | TD↔QA Alignment | ✅ Pass | § 13.4 maps task type → expected log/journal pattern → QA scenarios |
| 16 | Cross-Domain Consistency | ⚠️ Finding | API schema ↔ DB ↔ TD-02 carry shared "16 entries" off-by-one → Claim 01.1 |
| 17 | Security at Detail Level | ⚠️ Finding | Logger format violates ADR-011 ms-precision contract → Claim 01.9 |
| 18 | Error Handling Strategy | ⚠️ Finding | Journal sustained-fail → halt path declared in ADR-006/TD-04 แต่ ไม่ wired ใน TD-02 OnTick → Claim 01.8; Logger ErrorBypassThrottle caller responsibility undocumented → Claim 01.12 |
| 19 | Implementation Readiness | ⚠️ Finding | OnInit pseudo broken syntax + missing service Init calls → Claim 01.7; JournalEvent struct missing required schema fields → Claim 01.4; StatePersistence GV-recovery semantic ไม่ทำใน Load → Claim 01.11; 2-phase init declared แต่ไม่มี setter method → Claim 01.13 |

---

## Findings

### Claim 01.1: 🔴 CRITICAL — slot_states map count is 17 distinct magics, not 16; off-by-one cascades through TD + schema + concrete buffer

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.3 (`CPortfolioState` skeleton, line 510 + line 518 + line 525), § 10.1 (Class↔ADR matrix line 1606)
- File: `docs/technical-design/04-database-design.md`, Section: § 3.6 heading + line 77 + line 122-124 + line 399 + line 500 (erDiagram caption)
- File (cross-domain origin): `docs/api-specs/state-persistence-schema.yaml` line 129; `docs/adr/005-portfoliostate-via-chashmap.md` line 67

**Problem:**
TD-02 § 5.3 lock buffer size: `int m_magic_list[16];                  // iteration order for Refresh` และ comment ที่ § line 525 `// OnInit: pre-populate 16 entries (1 per distinct magic per BR-1.1)`. TD-04 § 3.6 heading ระบุ "16 entries by magic" + body ระบุ "16 distinct magic = G/G2 + B/BI + C/D + L/LX shared". แต่นับจริงจาก BA-04 BR-1.1 หลัง OQ-8 ลบ Slot U: **magic 200, 201, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219 = 17 distinct magics** (21 slots − 4 shared groups (CD, G/G2, B/BI, L/LX) ที่แต่ละ group 2 slots share 1 magic = 21 − 4 = 17, ไม่ใช่ 16). TD-04 § 3.6 ตารางเองก็ลิสต์ครบ 17 rows (200..219 active + 220 strikethrough U) ขัดกับ heading "16 entries" ในเอกสารเดียวกัน

**Why This Matters:**
1. **Buffer overflow / missing entry:** `m_magic_list[16]` array จะ overflow เมื่อ `RegisterAll()` ใส่ entry ที่ 17 (BR=215 หรือ I=216 หรือ S=217 ฯลฯ) — undefined behavior ใน MQL5; PortfolioState.Refresh() loop จะ skip entry หรือ corrupt heap. 2. **CHashMap entry count mismatch:** ADR-005 ตัด "16 entries รวม, ไม่ใช่ 21" ลงไปใน schema authority แต่จริงคือ 17 — engineer reading schema จะ assume 16, write code ที่ off-by-one. 3. **Cross-domain bug propagation:** TD ห้าม contradict authoritative API spec, แต่ ในกรณีนี้ API spec เองผิด — TD reviewer responsibility คือ flag ขึ้น (ผ่าน `/backtrack sd` หรือ `/amend sd`) ไม่ใช่ silently propagate. TD-02/04 เลือก propagate = ไม่ผ่าน "TD แตก SD ที่ approve แล้ว ไม่ต้องตรวจ consistency" rationalization ที่ andm-td-reviewer persona ระบุห้าม

**Minimum Acceptable Fix:**
1. Escalate ผ่าน `/backtrack sd` to fix `state-persistence-schema.yaml § slot_states description` + `ADR-005 line 67` ที่ระบุ "16 entries" เป็น **17 entries** (with explicit count breakdown: 200, 201, 205-219 = 17 distinct magics)
2. แก้ TD-02 § 5.3: `int m_magic_list[17];` (หรือใช้ dynamic ArrayResize); update comment line 525 "pre-populate 17 entries"
3. แก้ TD-02 § 5.3 line 510 + § 10.1 line 1606 จาก "16 entries" → "17 entries"
4. แก้ TD-04 § 3.6 heading + body + line 399 + erDiagram caption (line 500) จาก "16 entries" → "17 entries"
5. เพิ่ม BootstrapValidator boot-time assertion: `Assert(m_portfolio.MagicCount() == 17)` เพื่อ detect future drift

**Level of Effort:** Low

---

### Claim 01.2: 🔴 CRITICAL — DI cycle Logger ↔ StatePersistence unresolved; Logger.Init at step 1 cannot satisfy `CStatePersistence*` parameter that doesn't exist until step 6

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 Logger.Init signature (line 698) + § 5.6 StatePersistence.Init signature (line 651) + § 7.3 DI wire-up map (lines 1222-1241)

**Problem:**
TD-02 § 5.7 ลงนาม `void Init(ESeverity min_level, bool alert_on_error, CStatePersistence *state)` — Logger ต้องการ StatePersistence pointer (สำหรับ `IncrementLoggerThrottle` per ADR-011 § Throttle policy + § Throttled counter "logger_metrics.throttled_alert_count increment"). § 5.6 StatePersistence.Init signature `void Init(CAtomicFile *atomic, CLogger *logger, CPortfolioState *port)` — StatePersistence ต้องการ Logger pointer (สำหรับ logging save errors). § 7.3 DI map ลำดับ: row 1 = Logger first, row 5 = AtomicFile (Logger), row 6 = StatePersistence (AtomicFile, Logger, **PortfolioState**) — comment ระบุเฉพาะ "PortfolioState ยังไม่มี → use 2-phase init" แก้ SP↔PS cycle เท่านั้น ไม่ acknowledge Logger↔SP cycle. ที่ row 1 Logger.Init ถูก call ก่อนที่ SP จะถูก construct → `m_state` pointer เป็น null/garbage

**Why This Matters:**
1. **Compile + boot crash:** Logger.Init(...) ที่ step 1 ได้รับ null pointer หรือ garbage; ทันที ที่ Logger.Error() ใดเรียก `m_state.IncrementLoggerThrottle(...)` (per § 9.4 line 1539) → null-pointer dereference. EA ตาย ก่อน OnInit เสร็จ. 2. **Engineer ทำงานเสีย time:** § 7.3 ระบุ "2-phase init" แต่ระบุ scope แคบเฉพาะ SP↔PS — engineer reading § 7.3 จะ assume 2-phase pattern resolves อะไรก็ได้, implement Logger.Init แล้วเจอ runtime crash. 3. **ขัด `04 § 8` flow** ที่ระบุ "Logger.Error (throttled)" สำหรับ journal write fail — throttled counter ผ่าน SP, แต่ SP ยังไม่ exist ตอน Logger emit error ใน early OnInit phase

**Minimum Acceptable Fix:**
1. แก้ § 5.7 Logger class: เพิ่ม setter method `void SetStatePersistence(CStatePersistence *state)` + remove `CStatePersistence *state` จาก `Init(...)` signature; document ว่า throttle counter recording "ปิด" จนกว่า SetStatePersistence ถูกเรียก (boot phase early-error เก็บไม่ได้ — acceptable เพราะ ไม่มี state.json อยู่แล้ว)
2. แก้ § 7.3 DI map: เพิ่ม row 6.5 "Logger.SetStatePersistence(m_state)" ที่ run หลัง row 6 (StatePersistence init)
3. หรือ alternative: refactor `IncrementLoggerThrottle` ให้ **เก็บ in-memory เฉพาะใน Logger** + flush ลง state.json ที่ SP.Save() ผ่าน accessor `Logger.ConsumeThrottleMetric()` — เลือกทางใดทางหนึ่ง + document ใน § 5.7 + ADR-011 update

**Level of Effort:** Medium

---

### Claim 01.3: 🔴 CRITICAL — `m_xslot.SetHalted()` called AFTER `RunExitPass` → slot.ManageExits → TriggerGOverload reads stale `m_halted` from previous tick, violating ADR-010 enable matrix

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.2 OnTick pipeline lines 1183-1185 + § 9.6 post-exit hook line 1586 + § 5.11 line 868 SetHalted setter

**Problem:**
§ 7.2 OnTick pipeline ระบุ:
```
// 9. EXIT PASS (always runs even in HALTED — per ADR-010)
RunExitPass(ctx);                       // calls slot.ManageExits in topo order
m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING);
```
RunExitPass เรียก slot.ManageExits ก่อน SetHalted ถูก update. § 9.6 post-exit hook pattern + § 6.2 slot template line 1047-1048 ระบุ "G slot → m_xslot.TriggerGOverload(...)" ภายใน slot.ManageExits — เมื่อ G ปิด position. § 5.11 + § 9.6 line 1590 ระบุ "TriggerGOverload ภายในตรวจ m_halted → ถ้า HALTED → return". แต่ m_halted ยัง = false (จาก setter call ของ tick ก่อนหน้าที่ EA ยังเป็น RUNNING); ตอน slot.ManageExits ใน tick ที่ Halt() เพิ่งถูก call ที่ step 4-5 → m_state_enum = HALTED แต่ m_xslot.m_halted ยัง = false → TriggerGOverload ส่ง OrderSend ไปเปิด GO order = **ขัด ADR-010 enable matrix** (GOverload disabled in HALTED row line 900)

**Why This Matters:**
1. **G4 contract violation:** ADR-010 § enable matrix line 900 ระบุชัด `TriggerGOverload | ✅ post-exit hook | ❌ HALTED`. ใน tick แรกที่ EA halt (CircuitBreaker pingpong / handle_invalid_runtime) → G ที่กำลัง exit จะ trigger GO order ใหม่ = **เปิด new order ตอน halted** — ขัด FR-7.7 + AC-7.7.3 "halted = no new entry". 2. **Race-window bug** ที่ regression test ที่ AC-7.7.3 ตัวเองอาจไม่จับ (ถ้า test setup attach EA แล้ว halt ทันที → no G position to ManageExits in halt tick). 3. **Schema event_type=halt journal record** จะมี G entry event ตามมาทันที = retrospective analyst confused

**Minimum Acceptable Fix:**
แก้ § 7.2 OnTick pipeline ลำดับ: ย้าย `m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING);` **ก่อน** step 9 `RunExitPass(ctx)` (ทันทีหลัง step 5 IndicatorService.AnyHandleInvalid()). ตำแหน่งใหม่:

```mql5
// 5. Indicator runtime fail-fast
if (m_indicators.AnyHandleInvalid()) Halt("handle_invalid_runtime");

// 5b. Sync halt state to cross-slot coordinator BEFORE any slot can call TriggerGOverload
m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING);

// 6. Time gates ...
// ...
// 9. EXIT PASS — slot.ManageExits will see correct m_halted via post-exit hooks
RunExitPass(ctx);
```

ระบุ comment เกี่ยวกับ ordering invariant + reviewer checklist item: "SetHalted ต้องอยู่ก่อน RunExitPass ทุกครั้งที่ Halt() ถูก call ใน same tick"

**Level of Effort:** Low

---

### Claim 01.4: 🔴 CRITICAL — `JournalEvent` struct ขาด required schema fields (`timestamp`, `schema_version`, `mode`); `BuildRecord` อ่าน `ev.timestamp` ที่ struct ไม่มี → compile-error

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.5 TradeJournal struct definition (lines 573-590) + § 9.5 BuildRecord skeleton (line 1551)
- Cross-reference: `docs/api-specs/trade-journal-schema.yaml` lines 19-31 (required fields list)

**Problem:**
§ 5.5 struct `JournalEvent` ลิสต์ 15 fields: event_type, slot_id, magic, ticket_id, symbol, order_type, lot, price, sl, tp, comment, signal_context, triggering_function, parent_ticket_id, halt_reason, pending_age_bars. **ขาด** `timestamp`, `schema_version`, `mode` ที่ trade-journal-schema.yaml ระบุ `required: [timestamp, schema_version, mode, event_type, slot_id, magic, symbol, signal_context, indicator_snapshot, portfolio_summary, triggering_function]`. § 9.5 BuildRecord line 1551 เขียน `w.WriteString("timestamp", TimestampWithMs(ev.timestamp));` — อ่าน `ev.timestamp` field ที่ไม่ได้ declared ใน struct → MQL5 compile error "undeclared identifier"

**Why This Matters:**
1. **Compile-time fail:** IMPL-043 (TradeJournal::WriteEvent) จะ fail G1 gate ทันทีที่ engineer attempt compile. 2. **Schema authority violated:** TD ห้าม remove field จาก authoritative YAML; การ omit `timestamp/schema_version/mode` จาก JournalEvent struct = effective remove (caller can't populate). 3. **TimestampWithMs() function ไม่ defined ที่ใด** ใน TD-02 + helpers/ — engineer ไม่มี skeleton ของ helper สำหรับ millisecond-precision timestamp (per ADR-006 sample line 67 + yaml format date-time with ms required line 36). 4. **Schema_version drift risk:** ถ้า engineer hardcode `WriteInt("schema_version", 1)` ใน BuildRecord แทนที่จะจาก field → schema bump ที่ Phase 2 ต้องแก้ในที่เดียว vs catalog หลายจุด

**Minimum Acceptable Fix:**
1. แก้ § 5.5 JournalEvent struct เพิ่ม fields ที่ขาด:
   ```mql5
   struct JournalEvent {
      datetime timestamp_seconds;     // broker server time at event
      ulong    timestamp_microseconds; // GetMicrosecondCount() snapshot for ms precision
      // schema_version + mode populated internally by TradeJournal — not in caller-provided struct
      string event_type;
      ...existing 15 fields...
   };
   ```
2. แก้ § 9.5 BuildRecord ให้ TradeJournal เป็น authority สำหรับ schema_version + mode (จาก compile-time const + `MQLInfoInteger(MQL_TESTER)` detect):
   ```mql5
   w.WriteString("timestamp", FormatTimestampWithMs(ev.timestamp_seconds, ev.timestamp_microseconds));
   w.WriteInt("schema_version", JOURNAL_SCHEMA_VERSION);  // const = 1
   w.WriteString("mode", m_is_tester ? "tester" : "live");
   ```
3. เพิ่ม `helpers/Timestamp.mqh` skeleton ที่ define `FormatTimestampWithMs()` + remove undefined `TimestampWithMs()` reference — หรือ inline implementation ใน TradeJournal helper section
4. Reviewer checklist: ทุก field ใน yaml `required` list ต้อง mappable ไปยัง JournalEvent struct field หรือ TradeJournal-internal generated value (with comment ระบุ which)

**Level of Effort:** Medium

---

### Claim 01.5: 🔴 CRITICAL — Core class skeletons absent: `CBootstrapValidator`, `CSlotRegistry` (only stub in class diagram), `CEAState` state-machine class — engineer cannot implement IMPL-015/016/018/052 from TD-02 alone

**Location:**
- File: `docs/technical-design/02-backend-design.md`, missing sections — referenced ที่ § 7.1 (line 1126-1129) + § 7.4 (lines 1253, 1265-1266) + § 8.1 class diagram (lines 1380-1384) + ADR-012 file layout § 2 (lines 53-55)
- Cross-reference: `docs/design-docs/02-high-level-architecture.md § 4.2` Component Catalog rows #3 (BootstrapValidator), #4 (SlotRegistry), #5 (EAState)

**Problem:**
SD `02 § 4.2` lists 3 core components ที่ TD ต้องระเอียดเป็น class skeleton: `BootstrapValidator` (FR-1.2/1.4 + BR-9.1/9.3), `SlotRegistry` (BR-2.2 topo validate + ADR-002 § Layer 1 sentinel check), `EAState` (RUNNING/HALTED/HALTED_STABLE state machine per ADR-010). TD-02 § 4-5 (Domain types + Helpers + 13 services) **ไม่มี class skeleton ใดของ 3 components นี้**. § 7.1 Orchestrator line 1126 declares `CBootstrapValidator *m_validator;` + line 1127 `CSlotRegistry *m_registry;` แต่ไม่มี file `core/BootstrapValidator.mqh` skeleton ที่บอก method signatures + dependencies. § 8.1 class diagram line 1380-1384 มีเฉพาะ stub `class CSlotRegistry { -CSlotBase* m_slots[21]; +RegisterAll() bool; +ValidateTopo() bool }` — ไม่มี ADR-002 sentinel-check logic. EAState ถูก reduce เป็น enum ใน § 3.1 line 114 แต่ ADR-010 + SD-02 § 4.2 #5 ระบุชัดว่าเป็น "state machine" (มี Halt() method, transition rules, journal hook)

**Why This Matters:**
1. **Engineer block:** IMPL-015 (`BootstrapValidator::ValidateInputs`), IMPL-016 (`ValidateSymbol`), IMPL-018 (`SlotRegistry::ValidateTopo` + ADR-002 sentinel enforcement), IMPL-052 (`EAState` machine) — 4 implementation tasks ทั้งหมดอ้างอิง class ที่ TD ไม่ define. Engineer ต้อง infer signature จาก ADR text + SD prose = exactly the kind of "guess" ที่ andm-td-reviewer persona ห้าม ("Engineer จะต้อง guess เพราะ Z ไม่ถูก define"). 2. **ADR-002 § Pure-virtual override enforcement layer 1** lock concrete code: `bool SlotRegistry::ValidateTopo() { for ... if (m_slots[i].Magic() == -1 || m_slots[i].SlotId() == "") { ...; return false; } ... }`. TD-02 ไม่ surface code นี้ใน § 5/7 — engineer reading TD ไม่รู้ว่าต้อง implement sentinel check (ADR-002 อยู่นอก code skeleton scope ของ TD). 3. **EAState state machine มี non-trivial transitions** (RUNNING→HALTED ที่ Halt() call จาก CircuitBreaker / IndicatorService runtime invalid / journal sustained-fail; HALTED→HALTED_STABLE ที่ portfolio.count==0; reset to RUNNING on EA reattach per ADR-010). โดยปราศจาก class skeleton ที่ pin transition guards + journal hook, engineer จะ implement scattered transition logic ใน Orchestrator monolith — ขัด ADR-002 single-responsibility goal

**Minimum Acceptable Fix:**
เพิ่ม 3 sub-sections ใน TD-02 § 4 หรือ § 7 (ก่อน § 7.1 Orchestrator):
1. **§ 7.0.1 `core/BootstrapValidator.mqh`** — class CBootstrapValidator with methods: `bool ValidateInputs()` (FR-1.4 range checks per BR-4.1/4.2/4.3 inputs); `bool ValidateSymbol()` (FR-1.2 EURUSD whitelist); `bool DetectDigitMultiplier()` (BR-9.3); injected deps: `CLogger*, CIndicatorService*, CPortfolioState*` per § 7.3 row 17
2. **§ 7.0.2 `core/SlotRegistry.mqh`** — class CSlotRegistry with: `CSlotBase* m_slots[21]; bool RegisterAll(); bool ValidateTopo();` + concrete sentinel-check body จาก ADR-002 § Decision (call slot.Magic() + slot.SlotId() ของ ทุก entry, return false ถ้า returns -1 / "") + topo dependency validation per BR-2.2 literal order
3. **§ 7.0.3 `core/EAState.mqh`** — class CEAState (or struct + free functions) with: `EEAState GetState()`, `void Halt(string reason, CTradeJournal*, CLogger*)` (emits journal halt event + Logger.ErrorBypassThrottle + Alert), `bool TryTransitionToStable(CPortfolioState&)`, `void ResetToRunning()`. Document `Halt()` call sites: CircuitBreaker, IndicatorService runtime invalid, journal sustained-fail (per Claim 01.8)

**Level of Effort:** Medium-High (3 classes, ~150-300 LOC skeleton total)

---

### Claim 01.6: 🟠 HIGH — ADR-007 Option B fallback path "interface preserved" claim is false; `CAtomicFile::WriteAtomic(path, content, logger)` cannot represent 3-file double-buffered swap

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 4.4 AtomicFile interface (lines 423-438) + § 9.3 atomic write pattern + § 12.2 sequence diagram
- Cross-reference: `docs/adr/007-state-persistence-atomic-temp-rename.md § Option B` (lines 34-76, 3-file rotation: state-A.json + state-B.json + state-meta.bin) + `docs/api-specs/state-persistence-schema.yaml` (single state.json layout only)

**Problem:**
TD-02 § 4.4 declares `bool WriteAtomic(string path, string content, CLogger *logger);` พร้อม comment line 425 "ถ้า A2 spike (IMPL-046) fail → swap implementation เป็น Option B (3-file double-buffered swap) — interface preserved, downstream ไม่กระทบ". Claim ผิด: Option B per ADR-007 ต้องการ:
1. Read active pointer (`state-meta.bin` 1-byte single-sector read)
2. Compute inactive = (active=='A') ? 'B' : 'A'
3. Write full payload to `state-<inactive>.json`
4. Flush; then 1-byte write to `state-meta.bin` flipping pointer
5. Recovery: ถ้า parse `state-<active>.json` fail → fallback to `state-<other>.json`

`WriteAtomic(path, content, logger)` API: caller ส่ง 1 path, รับ 1 content. ไม่มีทางที่ implementation จะรู้ว่า "active" คือ A หรือ B; ไม่มีทางที่ caller จะ pass "intent" (write-and-flip-pointer vs read-active). Interface fundamentally incompatible. **และ** `state-persistence-schema.yaml` model เฉพาะ Option A (single state.json) — ไม่มี 3-file schema ที่ ADR-007 § Revisit-when ระบุต้อง update ถ้า activate Option B

**Why This Matters:**
1. **A2 spike (IMPL-046) failure scenario blocks impl:** ถ้า spike วัดว่า `FileMove` ไม่ atomic (per `03 § 7` risk A2) — TD ปัจจุบันไม่มี ready-to-activate Option B path. Engineer + Architect ต้อง refactor TD-02 § 4.4 + 5.6 + 9.3 + state-persistence-schema.yaml ใน Phase 1D ที่ tight schedule = unplanned 1-2 day rework. 2. **ADR-007 § Revisit-when contract violated:** ADR ระบุ "If atomic test fails → activate Option B (designed in ADR-007)" — แต่ TD ไม่ได้ design `state-persistence-schema.yaml` v2 หรือ alternative `WriteAtomicWithSwap` API. "Designed-but-not-primary fallback" status ไม่ถูก honored. 3. **TD-02 § 5.6 StatePersistence class** uses single `m_state_path` field — no multi-path support; refactor ที่ A2 fail scenario จะ touch StatePersistence + AtomicFile + schema simultaneously

**Minimum Acceptable Fix:**
1. แก้ § 4.4 AtomicFile API to accept Option-B-aware interface:
   ```mql5
   class CAtomicFile {
   public:
      // Option A path
      bool WriteAtomic_TempRename(string path, string content, CLogger *logger);

      // Option B path (activated only if IMPL-046 A2 spike fails)
      bool WriteAtomic_DoubleBuffered(string base_dir, string content, CLogger *logger);
      bool ReadActiveBuffered(string base_dir, string &out_content, CLogger *logger);

      // Strategy selector (compile-time conditional or runtime config)
      bool WriteAtomic(string base_path_or_dir, string content, CLogger *logger);  // dispatches
   };
   ```
2. แก้ § 5.6 StatePersistence to track both possible states (single path + 3-file dir); document "compile-time ATOMIC_STRATEGY=A_TEMP_RENAME default; switch to B_DOUBLE_BUFFERED if IMPL-046 fails"
3. Escalate via `/backtrack sd` to add `state-persistence-schema-v2.yaml` (Option B 3-file layout) — ADR-007 § Revisit-when promises this; SD must deliver before Phase 1D lock OR accept that Option B activation = blocked Phase 1D rework
4. หรือ alternative: explicitly remove "interface preserved" claim from § 4.4 + § 9.3 + ADR-007 — be honest that Option B activation = full refactor

**Level of Effort:** Medium

---

### Claim 01.7: 🟠 HIGH — TD-02 § 7.4 OnInit pseudocode has compile-broken comma-operator + missing `Init()` calls for ≥ 8 services

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit flow (lines 1249-1273)

**Problem:**
§ 7.4 lines 1255-1257 ระบุ:
```mql5
if (!m_pip.Init(),
    /* DigitMultiplier auto-detected per BR-9.3 */)                  goto init_ok_skip;
init_ok_skip:
```
**Compile-broken:** comma operator returns the second expression (the comment, which is empty/void). `if(!m_pip.Init(), <void>)` is invalid syntax. แม้ MQL5 ที่ tolerate การ misuse — `goto` ที่ตามไป skip ทันที. ที่จริงน่าจะเป็น `if (!m_pip.Init()) return INIT_FAILED;` แต่ pseudocode เขียนผิด. **และ** OnInit pseudo ขาด `Init(...)` calls ของ services ที่ § 7.3 row 1-18 ลิสต์: Logger.Init, AtomicFile.Init, PortfolioState.Init, IndicatorService.Init, MarketContextBuilder.Init, RiskManager.Init, TradeJournal.Init, CircuitBreaker.Init, TimeGate.Init, PendingMachineRegistry.Init, CrossSlotCoordinator.Init, PortfolioMonitor.Init, BootstrapValidator (skeleton missing — Claim 01.5), SlotRegistry (skeleton missing — Claim 01.5). § 7.4 มีเฉพาะ ValidateInputs/ValidateSymbol/CreateHandles/Load/RegisterAll/ValidateTopo/Open + Logger.Info — **ไม่มี Init() ของ 12 services**. Composition root pattern (ADR-002) บังคับ wire ทุก dependency ที่ OnInit; โดยไม่มี `Init()` call ลำดับชัดเจน → null pointers + null-deref crash

**Why This Matters:**
1. **Engineer compile fail ทันที** เมื่อ implement IMPL-059 (Orchestrator) จาก § 7.4 pseudocode literally — `if(!m_pip.Init(), comment)` ไม่ compile ใน strict mode + behavior unclear ใน lenient mode. 2. **Service objects เหลือเป็น zombie:** Service ที่ `new` ใน WireServices() แต่ไม่ called Init() = state uninitialized (m_logger = null, m_handles[] = 0, m_buffer[] = empty). ทันที่ slot.Evaluate() เรียก service method = null-deref. 3. **2-phase init contract** ที่ § 7.3 promised (PortfolioState pointer set after step 7) — § 7.4 pseudocode ไม่ surface ว่า set pointer call ที่ไหน. Engineer ต้อง guess

**Minimum Acceptable Fix:**
แก้ § 7.4 OnInit ให้เป็น linear sequence ของ Init calls + early-return on each failure, ตาม dependency order ใน § 7.3:
```mql5
int COrchestrator::OnInit() {
   WireServices();   // construct all services on heap (no Init yet)
   WireSlots();

   // Phase B: Init in dependency order
   m_logger.Init(InpLogLevel, InpAlertOnError, /*state=*/NULL);  // 2-phase: state set later
   m_pip.Init();
   m_comment.Init();
   m_json.Init();
   m_atomic.Init(m_logger);
   m_portfolio.Init(m_logger);
   m_state.Init(m_atomic, m_logger, m_portfolio);
   m_logger.SetStatePersistence(m_state);  // 2-phase completion (Claim 01.2 fix)
   m_indicators.Init(m_logger);
   m_ctx_builder.Init(m_indicators);
   m_risk.Init(InpFIDValue / InpMainRiskRatio, InpLimitMaxLotSizeRatio, m_logger);
   m_journal.Init(m_ctx_builder, m_portfolio, m_logger, m_state);
   m_breaker.Init(m_logger);
   m_time.Init(<inputs>, m_pip, m_state, m_logger);
   m_pending.Init(InpForceClearM_Bars, InpForceClearT_Bars, InpForceClearQ_Bars,
                  m_state, m_journal, m_logger, m_portfolio);
   m_xslot.Init(m_portfolio, m_journal, m_logger, m_risk);
   m_monitor.Init(m_state, m_logger);
   m_validator.Init(m_logger, m_indicators, m_portfolio);
   m_registry.Init(m_logger);

   // Phase C: validation + recovery
   if (!m_validator.ValidateInputs())             return INIT_FAILED;
   if (!m_validator.ValidateSymbol())             return INIT_FAILED;
   if (!m_pip.AutoDetectDigitMultiplier())        return INIT_FAILED;
   m_atomic.CleanupOrphanTmp(m_state.StatePath(), m_logger);  // ADR-007 recovery
   if (!m_indicators.CreateHandles())             return INIT_FAILED;
   if (!m_state.Load(m_state_enum, m_halt_reason)) {
      m_logger.Warn("system", "state_corrupt_starting_fresh", 0, "");
      m_state_enum = EA_STATE_RUNNING;
   }
   m_portfolio.RegisterAll();
   m_portfolio.Refresh();
   if (!m_registry.RegisterAll())                 return INIT_FAILED;
   if (!m_registry.ValidateTopo())                return INIT_FAILED;
   if (!m_journal.Open())                         return INIT_FAILED;
   m_logger.Info("system", "init_ok", 0, ...);
   return INIT_SUCCEEDED;
}
```
ลบ `goto init_ok_skip;` + comma-operator hack ทั้งหมด

**Level of Effort:** Low

---

### Claim 01.8: 🟠 HIGH — Journal sustained-failure → halt path declared in ADR-006 + TD-04 but not wired in TD-02 OnTick pipeline; `consecutive_write_failures ≥ 10` never triggers `EAState.Halt()`

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.5 TradeJournal.HandleWriteFailure (line 628 declaration only) + § 7.2 OnTick (no halt-check call) — vs `docs/technical-design/04-database-design.md § 3.7` (line 165) + ADR-006 § Failure handling RPO contract

**Problem:**
ADR-006 § Failure handling table (line 82) lock contract: "ถ้า `consecutive_write_failures ≥ 10` → `EAState.Halt(\"journal_write_fail_sustained\")` (ADR-010) → Alert + halt entry pass + user inspect". TD-04 § 3.7 line 165 mirror "Trigger halt escalation ที่ ≥ 10 (ADR-006 RPO contract)". § 4.3 line 226 lists `journal_write_fail_sustained` ใน halt_reason enum. **แต่** TD-02 § 7.2 OnTick pipeline (lines 1149-1216) ไม่มี check ของ `consecutive_write_failures` ใดๆ. § 5.5 declares `void HandleWriteFailure(string reason)` private method (line 628) แต่ไม่มี body skeleton; § 9.5 BuildRecord (lines 1547-1574) ไม่ branch ไปที่ HandleWriteFailure. § 7.1 Orchestrator class doesn't have any "check journal escalation" method. → Halt trigger missing

**Why This Matters:**
1. **G2 audit trail loss:** ที่ disk full / sustained AV interference scenario → journal events drop silently > 10 ครั้งติด, EA continues opening/closing orders without journal record = G2 audit gap (FR-4.1 violation). User เห็นเฉพาะ Logger.Error throttled. 2. **ADR-006 contract violation:** ADR-006 promises bounded loss + escalation; TD doesn't deliver mechanism. 3. **Schema includes `journal_write_fail_sustained` halt_reason but no code path emits it** — schema becomes documentation of unfulfilled intent

**Minimum Acceptable Fix:**
1. แก้ § 5.5 add public method `bool TradeJournal::ShouldHaltSustained(int &out_consecutive)` ที่ Orchestrator polls each tick:
   ```mql5
   bool ShouldHaltSustained(int &out_consecutive) const {
      out_consecutive = m_consecutive_failures;
      return m_consecutive_failures >= JOURNAL_HALT_THRESHOLD;  // const = 10 per ADR-006
   }
   ```
2. แก้ § 7.2 OnTick step 13 (after StatePersistence.Save) เพิ่ม:
   ```mql5
   // 13b. Journal sustained-failure halt check (ADR-006 RPO contract)
   int consecutive;
   if (m_state_enum == EA_STATE_RUNNING && m_journal.ShouldHaltSustained(consecutive)) {
      Halt("journal_write_fail_sustained");
      m_logger.ErrorBypassThrottle("system", "halt", 0,
                                    StringFormat("journal write failures = %d (≥ %d)",
                                                 consecutive, JOURNAL_HALT_THRESHOLD));
   }
   ```
3. § 5.5 add private body skeleton ของ `HandleWriteFailure(reason)` ที่ increment counter + reset on success; document where caller invokes (in `WriteEvent` after FileWriteString return-error branch)

**Level of Effort:** Low

---

### Claim 01.9: 🟠 HIGH — Logger format violates ADR-011 millisecond-precision contract; `TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)` ไม่มี ms field

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 9.4 Logger.FormatLine (lines 1527-1531)
- Cross-reference: `docs/adr/011-tagged-structured-logger.md` § Decision § Format row (line 55) — `[YYYY-MM-DD HH:MM:SS.ms][LEVEL]...`

**Problem:**
§ 9.4 line 1528-1531 ระบุ:
```mql5
string CLogger::FormatLine(ESeverity level, string slot, string ev, int magic, string msg) const {
   return StringFormat("[%s][%s][slot=%s][ev=%s][magic=%d] %s",
                       TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
                       SeverityToString(level), slot, ev, magic, msg);
}
```
`TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)` produces `"YYYY.MM.DD HH:MM:SS"` (no ms — `TimeCurrent()` ใน MQL5 returns seconds). ADR-011 § Decision § Format ระบุ contract: `[YYYY-MM-DD HH:MM:SS.ms][LEVEL]...`. mismatch: (1) date separator dot vs hyphen, (2) **ขาด `.ms` ที่ contract ระบุ** — ผลคือ retrospective log analysis (per `mt5-log-reader` skill workflow) ไม่สามารถ correlate event ที่ same-second resolution ระหว่าง slots

**Why This Matters:**
1. **G2 audit precision loss:** trade-journal record มี millisecond precision (per yaml line 36 + ADR-006 sample), แต่ Experts log fallback (when journal write fail, per ADR-011 § Severity behavior) มีเฉพาะ second resolution → diff timestamp ระหว่าง journal record + Experts log entry = 0.x sec offset, ทำให้ correlation analysis fail. 2. **CircuitBreaker debug:** BR-3.6 ping-pong threshold = 3000 ms; debugging ping-pong scenario ผ่าน Experts log ไม่ได้เพราะ resolution coarse > 3 sec

**Minimum Acceptable Fix:**
แก้ § 9.4 FormatLine ให้ include millisecond:
```mql5
string CLogger::FormatLine(ESeverity level, string slot, string ev, int magic, string msg) const {
   datetime now_sec = TimeCurrent();
   ulong ms_within_sec = (GetMicrosecondCount() / 1000) % 1000;
   string ts_str = TimeToString(now_sec, TIME_DATE | TIME_SECONDS);
   StringReplace(ts_str, ".", "-");  // align with ADR-011 hyphen separator
   return StringFormat("[%s.%03llu][%s][slot=%s][ev=%s][magic=%d] %s",
                       ts_str, ms_within_sec,
                       SeverityToString(level), slot, ev, magic, msg);
}
```
หรือ alternative: relax ADR-011 contract to "second precision" via ADR amendment + accept lower-fidelity correlation. Pick one + document

**Level of Effort:** Low

---

### Claim 01.10: 🟠 HIGH — `RiskManager::ComputeLot(slot_id, sl_pips, balance, multiplier)` interface conceals BR-4.1 21-formula table; engineer cannot derive lot logic from TD-02 alone

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.4 RiskManager class (lines 547-565) + § 6.2 slot template (line 1007 invocation)
- Cross-reference: `docs/ba/04-business-rules.md § 5 BR-4.1` per-slot lot multiplier table (lines 218-241)

**Problem:**
§ 5.4 RiskManager class declares:
```mql5
double ComputeLot(string slot_id, double sl_pips, double balance, double extra_multiplier = 1.0);
```
+ comment "per-slot lot calc — formula table per BR-4.1 (preserve §4.1 1:1)". § 6.2 slot template invokes: `m_risk.ComputeLot("<X>", sl_pips, AccountInfoDouble(ACCOUNT_BALANCE))`. **แต่** TD-02 ไม่มี code skeleton หรือ table-driven dispatch ที่บอก engineer ว่า ComputeLot จะ branch ตาม slot_id อย่างไร — BR-4.1 ระบุ 21 formula ที่ต่างกัน (C=15%×1..2.5 peak multi, H=15%×0.1..2.55, J=`LastBuyLots2 × 0.23`, G=30%×0.6, BI=23.6% ของ parent B, P=15%(8% สำหรับ P_Extra), S=percentTP∈{5,10,15}, ฯลฯ). ทั้งหมดถูกซ่อนหลัง string parameter

**Why This Matters:**
1. **TBD ที่หลบในที่:** "TBD" ที่ andm-td-reviewer persona ห้าม — TD ลด BR-4.1 ที่มี 21 row ลงเป็น 1 method signature โดยไม่ surface dispatch + per-slot formula. Engineer reading TD-02 ไม่มีทางรู้ว่า J formula = `LastBuyLots2 × 0.23` ต้องอ่าน balance จาก PortfolioState (ของ slot CD ที่ shared magic = MagicCD) — extra dependency ที่ method signature ไม่ reveal. 2. **G3 (NFR-1.1) drift risk:** ความเข้าใจคลาดเคลื่อนของ 1 slot formula = direct Net Profit drift; per-slot test coverage ของ IMPL-061 (per-slot baseline parser) จับ effect แต่ไม่ track root cause back to ComputeLot impl. 3. **MainRiskRatio derivation:** § 5.4 Init takes `main_risk_ratio` แต่ BR-4.1 ใช้ `FIDValue / MainRiskRatio` — engineer ไม่ surface ว่า ComputeLot ใช้ ratio + balance อย่างไร

**Minimum Acceptable Fix:**
1. เพิ่ม § 5.4.1 RiskManager Per-slot Formula Table — mirror ของ BA BR-4.1 ในเชิง implementation:
   ```mql5
   double CRiskManager::ComputeLot(string slot_id, double sl_pips, double balance, double extra_multiplier) {
      double base = balance * m_main_risk_ratio;
      if (slot_id == "C")  return base * 0.15 * extra_multiplier;       // 15% × peak 1..2.5
      if (slot_id == "H")  return base * 0.15 * extra_multiplier;       // 15% × 0.1..2.55
      if (slot_id == "J")  return ComputeLotForJ(extra_multiplier);     // LastBuyLots2 × 0.23 × OpenOrderJ
      if (slot_id == "K")  return ComputeLotForK(...);
      if (slot_id == "G")  return base * 0.30 * 0.6 * extra_multiplier; // 30% × OpenOrderG 0.6
      if (slot_id == "G2") return base * 0.15 * 0.7 * extra_multiplier;
      ...
      if (slot_id == "BI") return ComputeLotForBI(parent_b_lot);        // 23.6% ของ B parent
      ...
      m_logger.Error("RiskManager", "unknown_slot_id", 0, slot_id);
      return 0.0;
   }
   ```
2. เพิ่ม helper methods สำหรับ slots ที่ formula ต้อง read external state (J, BI, I, S) — document signature
3. Cross-reference table BR-4.1 row → ComputeLot branch + signal_context audit trail
4. Reviewer checklist: ทุก slot ใน BR-1.1 magic table มี explicit branch ใน ComputeLot

**Level of Effort:** Medium

---

### Claim 01.11: 🟠 HIGH — `StatePersistence::Load` API ไม่ expose GV-fallback recovery mechanism ที่ `02 § 6.1.1` Sync rule promised + `04 § 5.3` recovery scenario

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.6 StatePersistence.Load signature (line 654)
- Cross-reference: `docs/design-docs/02-high-level-architecture.md § 6.1.1` Sync rule "state.json corrupt + GV intact" row + `04 § 5.3` recovery table "Crash recovery (state.json corrupted — defense-in-depth fail)" + TD-04 § 5.2 line 274

**Problem:**
SD `02 § 6.1.1` lock invariant: ที่ state.json corrupt + GV intact → "StatePersistence.Load() defaults (per `04 § 5.3`) + **read GV ของ subset fields** เป็น last-resort hint สำหรับ `worst_drawdown_*` + `equity_high_water_mark`". `04 § 5.3` line 448 mirror. TD-04 § 5.2 line 274 ระบุ "read GV ของ subset fields เป็น last-resort hint สำหรับ `worst_drawdown_*` + `equity_high_water_mark`; pending machines + ban dates **ไม่** recover from GV". **แต่** TD-02 § 5.6 StatePersistence.Load signature: `bool Load(EEAState &out_ea_state, string &out_halt_reason);` — return only ea_state + halt_reason. ไม่มี out parameter หรือ method ที่ recover watch_profits subset จาก GV. § 5.6 + § 9.3 ไม่มี skeleton ของ GV-read fallback. ปัจจุบันถ้า state.json corrupt → defaults applied + zero-out worst_drawdown — invariant violated

**Why This Matters:**
1. **NFR-3.3 violation:** "100% field equivalence หลัง reload" promised แต่ corrupt-recovery path ทำเฉพาะ partial (defaults). 2. **User pain point #2 unaddressed in failure mode:** worst DD bookkeeping survives MT5 crash via GV safety net per ADR-007 design intent — TD doesn't implement; user loses retrospective DD baseline if state.json single-fault corrupt. 3. **TD-04 § 5.2 recovery table promises behavior that TD-02 cannot deliver** = cross-domain inconsistency

**Minimum Acceptable Fix:**
แก้ § 5.6 StatePersistence:
1. Add private helper method `bool TryRecoverFromGV(WatchProfitsSubset &out_recovered)` ที่ read 4 GV (worst_drawdown_pct, worst_drawdown_at, equity_high_water_mark, current_dd_pct per TD-04 § 5.1) ผ่าน `GlobalVariableGet(...)`; return true ถ้าได้ครบ subset
2. แก้ Load() body ให้ branch: parse state.json → if success use parsed; if parse fail / file missing → call TryRecoverFromGV, populate watch_profits-only defaults พร้อม Logger.Warn `"state_corrupt_recovered_via_gv"` (per `02 § 6.1.1`); pending machines + ban dates start fresh
3. Document Load() signature comment: "On parse failure with GV intact, watch_profits subset recovered from GV last-known values; pending machines / ban dates always reset to defaults"
4. เพิ่ม § 12 Flow Appendix sequence ของ recovery path (parse fail → GV read → partial restore + warn + journal `state_corrupt_recovered_via_gv` event)

**Level of Effort:** Low-Medium

---

### Claim 01.12: 🟠 HIGH — Logger escalation policy from ADR-011 (`≥ N consecutive same (slot,event) → secondary Alert`) ไม่ implemented ใน § 5.7 class skeleton

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 Logger class (lines 685-716)
- Cross-reference: `docs/adr/011-tagged-structured-logger.md` § Decision § Escalation policy (line 60) + § Throttled counter (line 61)

**Problem:**
ADR-011 lock 2 mechanism ที่เกี่ยวกับ ERROR throttling: (1) **Throttle**: Same (slot, event) ภายใน 100 ticks → suppress Alert. (2) **Escalation policy**: ≥ N consecutive ticks (default N=10, configurable `InpErrorEscalationN`) → emit secondary Alert + persist `(slot,event)` ใน `logger_metrics.last_throttle_event`. § 5.7 Logger class declares `m_recent_keys[64], m_recent_tick_count[64]` สำหรับ throttle window — covers (1). **ไม่มี** field หรือ method สำหรับ escalation tracking — ไม่มี `m_consecutive_count` per (slot,event), ไม่มี `EscalateIfNeeded()`. ไม่มี input `InpErrorEscalationN` ใน `inputs/Inputs_Logging.mqh` mention. ADR-011 contract ไม่ถูก honored

**Why This Matters:**
1. **ADR-011 § Throttle policy contract violation:** "User transparent ผ่าน throttled_alert_count counter" + "secondary Alert ที่ N consecutive" — TD ไม่ implement → user sustained-error scenario ไม่เห็น secondary Alert. 2. **NFR-3.4 "0 silent failures" weakened:** ADR-011 already acknowledged that throttle "อาจ suppress real consecutive errors" (line 93) — escalation = mitigation. ไม่มี mitigation = silent failure window. 3. **state-persistence-schema § logger_metrics.last_throttle_event field unused:** field exists ใน schema แต่ไม่มี writer in TD-02 → field stays null forever

**Minimum Acceptable Fix:**
แก้ § 5.7 Logger:
1. Add fields: `int m_consecutive_count[64]; ulong m_last_event_tick[64];` (parallel arrays กับ m_recent_keys)
2. Add method `void EscalateIfThresholdMet(string slot, string ev)` ที่ check `m_consecutive_count[idx] >= m_escalation_n` → emit secondary `Alert("Sustained error: <slot>/<event> × N — investigate")` + `m_state.SetLastThrottleEvent(slot + ":" + ev)` + reset counter
3. แก้ Error() / ErrorBypassThrottle() เรียก EscalateIfThresholdMet() แต่ละครั้ง
4. Add `m_escalation_n` field + accept ใน Init: `void Init(ESeverity min_level, bool alert_on_error, int escalation_n, CStatePersistence *state)`; default reads `InpErrorEscalationN` (configurable per ADR-011)
5. Document `inputs/Inputs_Logging.mqh` ต้องมี `input int InpErrorEscalationN = 10;`

**Level of Effort:** Low-Medium

---

### Claim 01.13: 🟠 HIGH — StatePersistence "2-phase init" mechanism ที่ § 7.3 declares ไม่มี setter method ใน § 5.6 class skeleton

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.6 StatePersistence Init signature (line 651) + § 7.3 DI map row 6 (line 1229)

**Problem:**
§ 7.3 row 6 footnote: `"6 | CStatePersistence | (AtomicFile, Logger, PortfolioState) — but PortfolioState ยังไม่มี → use 2-phase init: construct now, set portfolio pointer after step 7"`. § 5.6 class API:
```mql5
void Init(CAtomicFile *atomic, CLogger *logger, CPortfolioState *port);
```
Single-phase `Init()` ที่ takes `port` ที่ construction time. **ไม่มี** `SetPortfolioState(CPortfolioState *port)` setter ที่ § 7.3 promised. ทำ 2-phase init ตามที่ § 7.3 say คือ construct StatePersistence → call Init แต่ ส่ง NULL สำหรับ port → call Init ใหม่หลัง step 7 = call Init ซ้ำ ที่ไม่มี documentation behavior. หรือ engineer pass NULL → null-deref ตอน Save/Load. กลไกที่ § 7.3 promise ไม่มี method หลังบ้าน

**Why This Matters:**
1. **Engineer block:** IMPL-047 (StatePersistence.Save+Load) cannot resolve null pointer ที่ § 7.3 implies but § 5.6 ไม่ provide setter for. 2. **Pattern inconsistency:** Logger ↔ SP cycle (Claim 01.2) ก็ต้อง 2-phase setter — TD ไม่ standardize. 3. **MQL5 pointer setup limitation:** MQL5 ห้าม pass-by-reference inside class field; setter pattern เป็น only viable + must be explicit

**Minimum Acceptable Fix:**
แก้ § 5.6 StatePersistence:
```mql5
class CStatePersistence {
   ...
public:
   void Init(CAtomicFile *atomic, CLogger *logger);   // phase 1: no port dependency
   void SetPortfolioState(CPortfolioState *port);     // phase 2: set after PortfolioState init
   ...
};
```
+ document ใน § 7.3 row 6 ที่ correct call sequence:
```
Phase B step 6:  m_state.Init(m_atomic, m_logger);      // phase 1
Phase B step 7:  m_portfolio.Init(m_logger);
Phase B step 7b: m_state.SetPortfolioState(m_portfolio); // phase 2
```
+ Add assertion in Save/Load: `if (m_portfolio == NULL) { m_logger.Error(...); return false; }` (defensive guard ถ้า engineer ลืมเรียก setter)

**Level of Effort:** Low

---

### Claim 01.14: 🟡 MEDIUM — TD-04 § 8 Trade Journal Write Sequence diagram (line 510) ระบุ "FileMove(old, archive)" ตอน rotation; § 6.3 RotateIfNeeded code ไม่มี FileMove

**Location:**
- File: `docs/design-docs/04-data-flow.md` § 8 sequence (line 510) — wait this is SD doc; let me check TD-04 only
- File: `docs/technical-design/04-database-design.md`, Section: § 6.3 RotateIfNeeded code body (lines 308-321)
- File: `docs/design-docs/04-data-flow.md` § 8 line 510 (`FileClose(old) + FileMove(old, archive) + FileOpen(new)`)

**Problem:**
SD `04 § 8` sequence diagram line 510:
```
alt rotation needed
    TJ->>FS: FileClose(old) + FileMove(old, archive) + FileOpen(new)
end
```
TD-04 § 6.3 RotateIfNeeded body:
```mql5
FileClose(m_handle);
string new_path = StringFormat("journal/live/journal-%04d%02d.jsonl", now_dt.year, now_dt.mon);
m_handle = FileOpen(new_path, FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);
m_current_month = month_start;
m_active_path = new_path;
```
**No FileMove call.** การ rotate ใน implementation = close handle + open new file at new path; ไม่ rename old path. SD diagram says "rename to archive". Inconsistent

Inspecting carefully: ADR-006 § Decision says "Rotation check: ที่จุดเริ่ม TradeJournal::WriteEvent() — ถ้า month เปลี่ยน → close handle + rename + open new file". ADR ระบุ "rename" — TD-04 implementation doesn't rename. ADR + SD say rename; TD-04 doesn't. ADR-006 contract violated by TD-04

**Why This Matters:**
1. **File naming pattern broken:** ADR-006 § Decision design ระบุว่า old file ต้อง renamed ตอน rotation. ที่จริงแล้วถ้า rotate by month — `journal-202604.jsonl` already named correctly; ไม่ต้อง rename → ADR + SD ผิด. แต่ถ้า rotate semantic = "current.jsonl" → rename to "archive" — TD ไม่ได้ใช้ pattern นั้น. Internal inconsistency between TD-04 § 6.3 + SD § 8 + ADR-006 — engineer reading 3 sources ได้ 3 versions
2. **JSON-Lines append-only invariant** at month boundary: if old `journal-202604.jsonl` left intact, new `journal-202605.jsonl` opened — correct. SD diagram + ADR phrasing "FileMove(old, archive)" suggest rename behavior that TD's per-month-named files makes redundant. Choose one + align all 3 sources

**Minimum Acceptable Fix:**
เลือก one approach + align ทุก doc:
- **Option A (preferred — simpler):** TD-04 § 6.3 ใช้ "close + open new path" (per-month naming). Update SD `04 § 8` sequence diagram: remove "FileMove(old, archive)" — only "FileClose(old) + FileOpen(new)". Update ADR-006 § Decision: "rotation = close handle + open new monthly-named file (no rename, since each month has dedicated filename)"
- **Option B (more complex):** Implement rename pattern. แก้ TD-04 § 6.3:
  ```mql5
  string archive_path = StringFormat("journal/live/archive-%04d%02d.jsonl", prev_year, prev_month);
  FileClose(m_handle);
  FileMove(m_active_path, archive_path, FILE_REWRITE);
  m_handle = FileOpen(new_path, ...);
  ```
- Default to Option A (less disk I/O at month boundary) + document choice

**Level of Effort:** Low

---

### Claim 01.15: 🟡 MEDIUM — `PendingMachineRegistry::Init(...)` signature ใช้ placeholder `...inputs...` — engineer ไม่รู้ว่า constructor parameters คืออะไร

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.10 PendingMachineRegistry.Init signature (line 803-804)

**Problem:**
§ 5.10 line 803:
```mql5
public:
   void Init(...inputs..., CStatePersistence *state, CTradeJournal *journal,
             CLogger *logger, CPortfolioState *port);
```
`...inputs...` placeholder ไม่ specify ว่า "inputs" คือ field ไหน. § 5.10 lines 793-795 mention `m_threshold_m_bars`, `m_threshold_t_bars`, `m_threshold_q_bars` — น่าจะมาจาก inputs `InpForceClearM_Bars / InpForceClearT_Bars / InpForceClearQ_Bars` (per ADR-008). แต่ TD ไม่ pin signature. § 5.9 TimeGate ก็ใช้ pattern คล้าย: `void Init(...inputs..., CPipMath *pip, CStatePersistence *state, CLogger *logger);` — same vagueness

**Why This Matters:**
1. **TBD ที่ skeleton level:** andm-td-reviewer persona ระบุห้าม "TBD"; placeholder `...inputs...` = TBD โดย explicit. 2. **Engineer ต้องอ่าน ADR-008 + BR-3.x + BR-6.x เพื่อ derive signature** — defeats purpose ของ TD class skeleton ("engineer หยิบไป code ได้ทันที" per § TL;DR). 3. **DI wire-up map § 7.3 ก็ไม่ list inputs** — row 14 PendingMachineRegistry depends on (StatePersistence, TradeJournal, Logger, PortfolioState) only

**Minimum Acceptable Fix:**
แก้ § 5.10 ให้ explicit:
```mql5
void Init(int threshold_m_bars,        // InpForceClearM_Bars (ADR-008 default 150)
          int threshold_t_bars,        // InpForceClearT_Bars (default 80)
          int threshold_q_bars,        // InpForceClearQ_Bars (default 100)
          int legacy_c_timeout_bars,   // BR-6.1 default 8
          int legacy_c_adx_timeout_bars, // BR-6.2 default 30
          int legacy_r_timeout_bars,   // BR-6.3 default 40
          int legacy_p_timeout_bars,   // BR-6.4 default 70
          int legacy_force_timeout_bars, // BR-6.8 default 9
          CStatePersistence *state,
          CTradeJournal *journal,
          CLogger *logger,
          CPortfolioState *port);
```
ทำเช่นเดียวกันสำหรับ § 5.9 TimeGate.Init (morning_window_minutes, monday_spread_threshold, holiday_start_month/day, holiday_end_month/day, ban_c_cooldown_bars, ban_l_cooldown_bars, ฯลฯ per BR-3.x)

**Level of Effort:** Low

---

### Claim 01.16: 🟡 MEDIUM — TD-04 § 3.8 logger_metrics ไม่ surface GV mirror สำหรับ `throttled_alert_count` ที่ § 5.1 GV table includes; cross-domain field ownership unclear

**Location:**
- File: `docs/technical-design/04-database-design.md`, Section: § 3.8 logger_metrics sub-schema (lines 169-174) + § 5.1 GV variables row 5 (line 266)

**Problem:**
§ 3.8 logger_metrics sub-schema describes 2 fields (`throttled_alert_count`, `last_throttle_event`) — **no "Mirror to GV?" column** like watch_profits has at § 3.4. § 5.1 GV variables table (line 266) lists `PhoenicisNex_logger_throttled_alert_count` mirroring `state.logger_metrics.throttled_alert_count`. Reader of § 3.8 alone doesn't know GV mirror exists — must cross-read § 5.1. § 3.4 watch_profits has explicit "Mirror to GV?" column making this clear; § 3.8 omits same column = inconsistent table style

**Why This Matters:**
1. **Documentation gap:** TD-04 § 3.x "Mirror to GV?" pattern broken at § 3.8 — engineer reading 1 section ใน isolation จะ assume only watch_profits subset ผ่าน GV. 2. **§ 5.1 GV table ระบุ 5 entries** but if § 3.8 ไม่ surface, ทำ engineer มองข้าม mirror requirement → StatePersistence::SyncToGlobalVariable code ขาด 1 GV write. 3. **NFR-3.4 transparency contract** ของ ADR-011 (line 61 throttled_alert_count "surface ใน HALTED_STABLE Alert message") — TD-02 § 7.2 line 1211 implements correctly, but cross-domain trace at TD-04 incomplete

**Minimum Acceptable Fix:**
แก้ § 3.8 ให้ใช้ table style เดียวกับ § 3.4 — เพิ่ม "Mirror to GV?" column:
| Column | Type | Nullable | Default | Constraint | Mirror to GV? | Description |
|--------|------|----------|---------|------------|----------------|-------------|
| `throttled_alert_count` | integer | no | 0 | ≥ 0 | ✅ `PhoenicisNex_logger_throttled_alert_count` (per § 5.1) | ... |
| `last_throttle_event` | string \| null | yes | null | format `"<slot>:<event>"` | — (string can't store ใน GV double-only) | ... |

**Level of Effort:** Low

---

### Claim 01.17: 🟡 MEDIUM — TD-04 § 6.3 RotateIfNeeded MQL5 code uses C++ brace-init (`MqlDateTime{...}`) ที่ MQL5 compiler ไม่รองรับ

**Location:**
- File: `docs/technical-design/04-database-design.md`, Section: § 6.3 RotateIfNeeded body (lines 312-313)

**Problem:**
§ 6.3 line 313:
```mql5
datetime month_start = StructToTime(MqlDateTime{now_dt.year, now_dt.mon, 1, 0, 0, 0});
```
MQL5 compiler ไม่ support C++ uniform-init syntax `Type{...}`. MQL5 ต้อง field-by-field assignment:
```mql5
MqlDateTime month_dt;
month_dt.year = now_dt.year;
month_dt.mon  = now_dt.mon;
month_dt.day  = 1;
month_dt.hour = 0;
month_dt.min  = 0;
month_dt.sec  = 0;
datetime month_start = StructToTime(month_dt);
```
Engineer copy-paste § 6.3 code → compile fail (G1 gate fail)

**Why This Matters:**
1. **G1 gate compile fail** ทันทีที่ IMPL-043 (TradeJournal write logic) — `mql-developer` skill convention enforces field-by-field; TD-04 example violates. 2. **TD-04 ระบุ MQL5 code skeleton** — ต้อง compile clean (per andm-td-reviewer "Implementation Readiness" criteria + persona's "Engineer ต้อง implement ได้โดยไม่ ambiguous" priority)

**Minimum Acceptable Fix:**
แก้ § 6.3 ใช้ field-by-field assignment (snippet ด้านบน). Reviewer checklist: ทุก MQL5 code skeleton ใน TD-02/03/04 ต้อง compile-test ก่อน lock — minimum check `mqlinspect`-style syntax sweep หรือ MetaEditor compile

**Level of Effort:** Low

---

### Claim 01.18: 🔵 LOW — TD-02 § 6.2 slot template invokes `m_time.SetBan("<X>", ctx.tick_time)` for any slot but BR-3.4 lists only C/L/M/K/G as having ban dates → silent error path

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 6.2 slot template (line 1025) + § 5.9 TimeGate.SetBan signature (line 775)
- Cross-reference: `docs/ba/04-business-rules.md § 4 BR-3.4` ban cooldown table (lines 173-179)

**Problem:**
§ 6.2 slot template line 1025:
```mql5
m_time.SetBan("<X>", ctx.tick_time);  // BR-3.4 if applicable
```
"if applicable" ใน comment แต่ ไม่มี mechanism ที่ enforce. § 5.9 SetBan signature accepts any slot_id string — silently does nothing? logs warning? state-persistence-schema § ban_dates supports only 5 keys (`ban_c_start_date, ban_l_start_date, ban_m_start_date, k_last_order_date, g_pause_date`). ถ้า engineer copy template literally ลง Slot_F.mqh + call SetBan("F", ...) → no ban_f_start_date field → silent error or unknown behavior

**Why This Matters:**
1. **Silent failure path:** NFR-3.4 "0 silent failures" — undefined behavior on unknown slot_id. 2. **Template misleading:** "if applicable" ไม่บอก engineer ว่าต้องเช็คตารางไหนแล้ว conditional include. 3. **Schema enforcement absent:** state-persistence-schema doesn't enum-restrict ban_dates keys

**Minimum Acceptable Fix:**
1. แก้ § 5.9 TimeGate.SetBan ให้ enforce slot allowlist:
   ```mql5
   void CTimeGate::SetBan(string slot_id, datetime server_now) {
      if (slot_id != "C" && slot_id != "L" && slot_id != "M" && slot_id != "K" && slot_id != "G") {
         m_logger.Error("TimeGate", "ban_unknown_slot", 0, slot_id);
         return;
      }
      ...
   }
   ```
2. แก้ § 6.2 slot template comment + sample: ระบุชัด "ใส่เฉพาะ slot ใน BR-3.4 ban table {C, L, M, K, G}"; non-applicable slots → omit SetBan call entirely. Per-slot file (Slot_F.mqh, Slot_J.mqh, etc.) ต้องไม่ include SetBan

**Level of Effort:** Low

---

### Claim 01.19: 🔵 LOW — TD-02 § 13.4 jq commands assume bash environment; project Windows + powershell guidance ขาด

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 13.4 Log review workflow (lines 1820-1832)

**Problem:**
§ 13.4 jq examples ใช้ bash syntax:
```bash
head -5 MQL5/Files/PhoenicisNex/journal/tester/run-<ISO>.jsonl | jq .
jq -r .event_type ... | sort | uniq -c
jq 'select(.slot_id=="BI" ...)' run-*.jsonl
```
Project environment (per system context) = Windows 11 + PowerShell. PowerShell native ไม่มี `jq` binary by default; pipe syntax different (`Select-Object` vs `head`); glob `run-*.jsonl` works in PS but `sort | uniq -c` ไม่มี native equivalent. § 13 Developer Workflow doesn't disclaim or provide PS alternative

**Why This Matters:**
1. **Workflow blocked for native PS user:** Engineer ที่ run G4 audit จะ copy-paste fail. 2. **`mt5-log-reader` skill mentions Git Bash availability** — TD ไม่ surface dependency. 3. **Headless backtest workflow § 13.3 ใช้ bash env vars** (ORIGIN=$(cat origin.txt)) ก็ assume bash

**Minimum Acceptable Fix:**
1. เพิ่ม § 13 disclaimer ที่ top: "All shell snippets ใน § 13 assume Git Bash (bundled with Git for Windows). Windows users without Git Bash → install via `https://git-scm.com` หรือ use WSL"
2. หรือ provide PS-native alternative สำหรับ key commands:
   ```powershell
   # Per-event-type count (PS alternative)
   Get-Content run-*.jsonl | ConvertFrom-Json | Group-Object event_type | Select-Object Count, Name
   ```
3. Note: jq-windows binary does exist (`jq-win64.exe`) — provide install pointer

**Level of Effort:** Low

---

### Claim 01.20: 🟡 MEDIUM — Logger throttle ring buffer size 64 with 100-tick window — capacity rationale undocumented; may overflow at sustained high-cardinality error

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 Logger m_recent_keys/m_recent_tick_count fields (lines 691-693)

**Problem:**
§ 5.7 declare:
```mql5
string m_recent_keys[64];
int    m_recent_tick_count[64];
int    m_recent_count;
```
ADR-011 spec says throttle window = 100 ticks. ทุก distinct (slot, event) tuple ต้อง track within window. ระบบมี 21 slots × N event types — distinct tuple pool อาจ > 64 entries ใน high-error scenario (e.g., journal sustained-fail across multiple slots emitting reject events). ถ้า > 64 → buffer overflow handling undefined; § 5.7 ไม่ระบุ eviction policy (LRU? oldest? error?)

**Why This Matters:**
1. **NFR-3.4 transparency edge case:** ที่ > 64 distinct (slot,event) within 100 ticks → some throttling state lost = Alert behavior unpredictable. 2. **No degradation contract:** engineer ไม่รู้ว่าตอนเต็มจะทำอย่างไร — fail-fast? evict oldest? skip throttle (= flood)?

**Minimum Acceptable Fix:**
1. Document capacity rationale: "64 entries ครอบคลุม worst-case = 21 slots × 3 ดี-cardinality events (entry/exit/reject) = 63 distinct tuples; 64 = +1 headroom"
2. Document eviction policy: "ที่ buffer full + new tuple → evict entry ที่ tick_count oldest (LRU)" — แล้ว Logger.Warn `"throttle_buffer_evicted"` (visibility for tuning)
3. หรือ alternative: bump buffer to 128 (no eviction needed) + keep simple ring overwrite at full
4. Add Logger.Init parameter `int throttle_buffer_size` to allow input tuning

**Level of Effort:** Low

---

## Cross-Domain Issues

| # | Issue | Sources affected |
|---|-------|------------------|
| X1 | "16 entries" off-by-one shared across SD ADR-005 + state-persistence-schema.yaml + TD-02 § 5.3 + TD-04 § 3.6 | ADR-005, schema YAML, TD-02, TD-04 — Claim 01.1 |
| X2 | ADR-007 Option B promised by ADR + TD-02 § 4.4 comment but unmodeled by AtomicFile API + state-persistence-schema | ADR-007, TD-02 § 4.4/5.6, schema YAML — Claim 01.6 |
| X3 | ADR-006 RPO contract (`consecutive_write_failures ≥ 10` → halt) mirrored in TD-04 § 3.7 + journal halt_reason enum but not wired in TD-02 OnTick | ADR-006, TD-04, TD-02 § 7.2 — Claim 01.8 |
| X4 | trade-journal-schema.yaml requires `timestamp/schema_version/mode` but TD-02 JournalEvent struct missing fields | YAML, TD-02 § 5.5 — Claim 01.4 |
| X5 | `02 § 6.1.1` GV-recovery rule for state.json corrupt + `04 § 5.3` recovery row not implemented in TD-02 § 5.6 Load API | SD `02`, SD `04`, TD-02, TD-04 § 5.2 — Claim 01.11 |
| X6 | Rotation behavior contradiction: ADR-006 + SD `04 § 8` say "FileMove(old, archive)"; TD-04 § 6.3 code does FileClose+FileOpen only | ADR-006, SD `04`, TD-04 — Claim 01.14 |
| X7 | ADR-011 escalation policy + format spec promises ms precision + N-consecutive secondary alert; TD-02 Logger violates both | ADR-011, TD-02 § 5.7/9.4 — Claims 01.9, 01.12 |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 01.1 | 🔴 CRITICAL | slot_states map count off-by-one (16 vs actual 17 magics) | TD-02 § 5.3, TD-04 § 3.6, schema YAML, ADR-005 | Low |
| 01.2 | 🔴 CRITICAL | DI cycle Logger ↔ StatePersistence unresolved | TD-02 § 5.7 + § 7.3 | Medium |
| 01.3 | 🔴 CRITICAL | SetHalted called after RunExitPass → stale m_halted in TriggerGOverload | TD-02 § 7.2 | Low |
| 01.4 | 🔴 CRITICAL | JournalEvent struct missing `timestamp`/`schema_version`/`mode` required fields | TD-02 § 5.5 + § 9.5 | Medium |
| 01.5 | 🔴 CRITICAL | Core class skeletons absent: BootstrapValidator, SlotRegistry detail, EAState machine | TD-02 § 4-7 | Medium-High |
| 01.6 | 🟠 HIGH | ADR-007 Option B fallback "interface preserved" claim is false | TD-02 § 4.4/5.6, schema YAML | Medium |
| 01.7 | 🟠 HIGH | TD-02 § 7.4 OnInit pseudo broken syntax + missing 12 service Init() calls | TD-02 § 7.4 | Low |
| 01.8 | 🟠 HIGH | Journal sustained-fail → halt path declared but not wired in OnTick | TD-02 § 5.5 + § 7.2 | Low |
| 01.9 | 🟠 HIGH | Logger format violates ADR-011 ms-precision contract | TD-02 § 9.4 | Low |
| 01.10 | 🟠 HIGH | RiskManager.ComputeLot conceals BR-4.1 21-formula table | TD-02 § 5.4 + § 6.2 | Medium |
| 01.11 | 🟠 HIGH | StatePersistence.Load missing GV-recovery semantic per `02 § 6.1.1` | TD-02 § 5.6 | Low-Medium |
| 01.12 | 🟠 HIGH | Logger escalation policy from ADR-011 not implemented | TD-02 § 5.7 | Low-Medium |
| 01.13 | 🟠 HIGH | StatePersistence "2-phase init" mechanism: setter method missing | TD-02 § 5.6 + § 7.3 | Low |
| 01.14 | 🟡 MEDIUM | TD-04 § 8 sequence + ADR-006 say FileMove; § 6.3 code does FileClose+FileOpen | TD-04 § 6.3 + § 8 + ADR-006 | Low |
| 01.15 | 🟡 MEDIUM | PendingMachineRegistry / TimeGate Init signature uses `...inputs...` placeholder | TD-02 § 5.10 + § 5.9 | Low |
| 01.16 | 🟡 MEDIUM | TD-04 § 3.8 logger_metrics missing "Mirror to GV?" column for throttled_alert_count | TD-04 § 3.8 + § 5.1 | Low |
| 01.17 | 🟡 MEDIUM | TD-04 § 6.3 MQL5 code uses C++ brace-init not supported by MQL5 | TD-04 § 6.3 | Low |
| 01.18 | 🔵 LOW | § 6.2 slot template SetBan call has no slot_id allowlist check | TD-02 § 6.2 + § 5.9 | Low |
| 01.19 | 🔵 LOW | § 13.4 jq commands assume bash; Windows native PS workflow undocumented | TD-02 § 13.3-13.4 | Low |
| 01.20 | 🟡 MEDIUM | Logger throttle buffer size 64 vs 100-tick window: rationale + eviction policy missing | TD-02 § 5.7 | Low |

---

> **Recommendation:** จาก 5 CRITICAL findings — 3 เป็น code-skeleton bugs (01.3, 01.4, 01.7) + 1 เป็น sensitive cross-domain inconsistency (01.1) + 1 เป็น missing class skeletons (01.5) — TD ยัง **NOT ready for implementation handoff**. ต้องผ่าน rebuttal round 02 (และอาจรอบที่ 3) เพื่อ:
> 1. Escalate Claim 01.1 ผ่าน `/backtrack sd` (schema + ADR-005 fix) เพราะ origin คือ SD documents
> 2. Resolve DI cycle (Claim 01.2) ก่อน IMPL-018 lock — ส่งผลกระทบ Logger + StatePersistence + Orchestrator wiring
> 3. แก้ class skeleton gaps (Claim 01.5) ก่อน Phase 2 Implementation Engineer หยิบ TD ไป IMPL-015/016/018/052
> 4. Fix HALTED ordering bug (Claim 01.3) — G4 contract violation; severity ทับกับ behavioral parity G3 invariant
>
> Total effort estimate: ~3-5 day rebuttal cycle to address CRITICAL + HIGH findings; MEDIUM/LOW deferred to round 02 rebuttal เป็น batch
