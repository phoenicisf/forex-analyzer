# Code Review Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Target** | `all` (P2 closure delta — IMPL-043 TradeJournal, IMPL-044 trade-journal-schema, IMPL-049 PendingMachineRegistry [XL 4 sub-passes], IMPL-052 EAState) |
| **Date** | 2026-05-03 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | 3 new source files (`services/TradeJournal.mqh` 480 LOC + `services/PendingMachineRegistry.mqh` 772 LOC + `core/EAState.mqh` 224 LOC) + spec lock (`docs/api-specs/trade-journal-schema.yaml` v1) + 2 spike harnesses + cross-consistency vs Round 02 fixes |
| **Cumulative LOC reviewed (Round 03 delta)** | ~1,476 LOC (excl. spec) |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH     | 4 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **11** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | NFR-7.2 = 0 external DLLs preserved; journal path stays inside `MQL5/Files/PhoenicisNex/` sandbox; no `WebRequest` / `#import`; round-02 fix 02.5 (`_ExtractStr` JSON unescape) preserved in StatePersistence callsite chain |
| 2 | Business Logic Correctness | ⚠️ Finding | `EmitForceClear` emits `event_type="force_clear"` ≠ schema enum `pending_force_clear` (Finding 03.1); `LoadFromState` zero-init of `pending_started_bar` triggers immediate force-clear on cold restart, OPPOSITE of comment claim (Finding 03.4) |
| 3 | Error Handling | ⚠️ Finding | `CTradeJournal::WriteEvent` keeps writing past `JOURNAL_HALT_THRESHOLD`; halt escalation gated on caller polling `ShouldHaltSustained` but no caller wired (Finding 03.6); `CEAState::Halt` writes journal event with all required fields zeroed → record fails schema (Finding 03.2) |
| 4 | Performance | ✅ Pass | `TickAll` 8 machines O(1)/tick; `BuildPortfolioSummary` 17-magic loop bounded; `m_overshoot_window[10]` populated O(1); no nested heavy loops |
| 5 | Over-Engineering | ⚠️ Finding | `JOURNAL_OVERSHOOT_WINDOW` populated but never read for ratio/p99 — dead surface (Finding 03.10); `port` parameter on `TickMachine` carried for future-use comment but never dereferenced (line 691 dead-code branch `if(port.GetByMagic(0) == NULL && id == PM_COUNT)` — `id == PM_COUNT` impossible per loop bounds) |
| 6 | Cross-Service Consistency | ⚠️ Finding | TradeJournal struct ↔ schema v1: `event_type=force_clear` ≠ schema enum (Finding 03.1); `slot_id=""` + `symbol=""` from EAState halt event violate enum constraints (Finding 03.2); `magic=0` for M/T/Q force-clear ≠ MAGIC_M/T/Q ≠ schema literal (Finding 03.3) |
| 7 | Test Coverage Gaps | ⚠️ Finding | EAState SelfTest cannot test journal/Logger emission paths because no mock injection (Finding 03.8); PMR SelfTest Case 6 runs round-trip on default-constructed `CStatePersistence` (no AtomicFile path), missing `_ExtractRawValue` JSON parse exercise → Round 02.1 fix not regression-tested by Round 03 work |
| 8 | Architecture Compliance | ✅ Pass | ADR-006 schema_version=1 preserved + halt threshold 10 wired as `JOURNAL_HALT_THRESHOLD`; ADR-007 atomic-write preserved (TradeJournal does NOT use atomic — append-only is correct per JSON-Lines + ADR-006); ADR-008 thresholds M=150/T=80/Q=100 stored in `m_threshold_*_bars` (default ctor + Init); ADR-010 RUNNING/HALTED/HALTED_STABLE machine implemented; ADR-011 `ErrorBypassThrottle` used for halt event |
| 9 | TD Compliance | ⚠️ Finding | TD-02 §5.5/§5.10/§7.0.3 skeletons followed; but TD-02 §5.5 `BuildIndicatorSnapshotSubset` returns hard-coded `"{}"` (Finding 03.5) — schema marks `indicator_snapshot` required + describes "subset of MarketContext"; current empty-object impl satisfies type but not contract intent |
| 10 | Test Quality | ⚠️ Finding | PMR `SelfTest` Case 6 mutates a `CStatePersistence` instance whose underlying file I/O is never executed → covers in-RAM accessor mirror but not the schema-on-disk round-trip the AC text demands; EAState SelfTest passes `NULL` journal so cannot prove Halt's journal-event payload is schema-correct |
| 11 | Empirical AC Closure | ⚠️ Finding | IMPL-052 evidence file (`docs/state/_session-handoff/IMPL-052-evidence-20260503.md` line 18) claims `[boot-cold]`-class E-AC closed via in-process `SelfTest()` because "terminal64.exe headless test execution failed to attach locally" — kind mismatch (Finding 03.9). IMPL-049 E-AC #1 + #2 both `[x]` via SelfTest, with explicit precedent citation to "IMPL-052 header-only `.mqh` precedent"; verbiage flirts with the forbidden "deferred per <task> precedent" closure pattern but evidence file documents structural proof so partial-acceptable per Round 02 standing rule. IMPL-043 E-AC has 1 row deferred via `deferred-ac-registry.md` (sustained-halt log assertion → 2026-05-17 expiry) — registry path correctly used (✅) |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface; P2 = service-layer header-only `.mqh` (entry .mq5 lands at IMPL-018+) |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; thresholds passed as Init params (not env vars) |

---

## Findings

### Finding 03.1: 🔴 CRITICAL — `CPendingMachineRegistry::EmitForceClear` ใช้ `event_type="force_clear"` ขัด schema enum `pending_force_clear` → ทุก force-clear record fail validation

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 752-762 (EmitForceClear journal event build)
- Schema: `docs/api-specs/trade-journal-schema.yaml` line 57 (event_type enum)
- Service: `ea` / services / PendingMachineRegistry

**Code:**
```mql5
// PendingMachineRegistry.mqh:752-762
JournalEvent ev;
ZeroMemory(ev);
ev.timestamp_seconds      = TimeCurrent();
ev.timestamp_microseconds = GetMicrosecondCount();
ev.event_type             = "force_clear";              // ← ผิด
ev.slot_id                = code;                        // "M" | "T" | "Q"
ev.pending_age_bars       = age_bars;
ev.signal_context         = StringFormat("machine=%s reason=age_exceeded count=%d",
                                         code, m_machines[id].force_clear_count);
m_journal.WriteEvent(ev);
```

vs `trade-journal-schema.yaml:57`:
```yaml
event_type:
  type: string
  enum: [entry, exit, modify, reject, halt, halt_stable, pending_force_clear, exit_inferred, discovered]
```

**Problem:**
Schema v1 (locked 2026-05-03 IMPL-044) ระบุ enum value ว่า `pending_force_clear` (line 57 + line 65 description "M/T/Q-Pending hard timeout fired (ADR-008)"). PendingMachineRegistry emit `"force_clear"` (no `pending_` prefix). String literal mismatch → ทุก record ของ M/T/Q force-clear จะ fail JSON Schema validation (additionalProperties=false + enum-bounded). Schema reader (jq script ที่ G4 review uses + Python yamale ใน QA Phase 3T) จะ reject record. ADR-008 + ADR-006 contract broken.

ที่หนัก: **ADR-008 evidence chain ต้องการ force_clear_count audit ใน journal** (per ADR-008 "Configurable ผ่าน input ... user / QA ปรับได้ใน Strategy Tester optimization sweep"). หาก record fail schema, IMPL-068 (force-clear validation in QA Phase 3T) ก็ไม่มีข้อมูลที่ valid ให้วัด. SelfTest ของ PMR ไม่ได้ตรวจ event_type ที่ออก journal เพราะ Case 5 ใช้ `m_journal=NULL` → silent skip (`if(m_journal != NULL)` line 750). G4 log review ตอน entry .mq5 land จะเห็น file มีบรรทัด "force_clear" แต่ external validator (jq) reject.

**Why This Matters:**
- ADR-006 schema_version=1 lock — drift จาก enum literal = breaking change ที่ต้อง bump version (Lifecycle Plan section ที่ IMPL-044 เพิ่ง lock)
- IMPL-068 (QA Phase 3T force-clear validation) จะ fail before it starts
- NFR-3.3 (100% field restore — ที่นี่ขยาย scope ไปถึง schema integrity) violated
- Round 02.1 fix established schema-on-disk-must-match contract (CStatePersistence pending_payload round-trip); Round 03 introduces same class of defect at a different surface (journal not state.json)

**Suggested Fix:**
Match schema enum verbatim:
```mql5
ev.event_type = "pending_force_clear";   // schema v1 § event_type enum
```
Add SelfTest assertion (mock journal capture) — pre-IMPL-018 wiring:
```mql5
// In Case 5, replace m_journal=NULL with a CMockJournal that records the
// last JournalEvent.event_type and assert == "pending_force_clear".
```
Alternative (escalate via schema): if engineering prefers shorter literal, bump schema_version → 2 + transition window per Lifecycle Plan — not preferred since IMPL-044 just locked v1.

**Level of Effort:** Low (1 string literal + 1 SelfTest case)

---

### Finding 03.2: 🔴 CRITICAL — `CEAState::Halt` + `TryTransitionToStable` ส่ง JournalEvent ที่ required-field-เป็นค่าว่าง → record fail schema (slot_id, symbol, magic)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/EAState.mqh`
- Lines: 53-62 (Halt journal event), 81-90 (TryTransitionToStable journal event)
- Schema: `docs/api-specs/trade-journal-schema.yaml` lines 70-93 (slot_id + magic + symbol enum constraints) + line 19-34 (15 required fields)
- Service: `ea` / core / EAState

**Code:**
```mql5
// core/EAState.mqh:53-62 (Halt)
if(m_journal != NULL)
  {
   JournalEvent ev;
   ZeroMemory(ev);                             // ← clears every field
   ev.timestamp_seconds = TimeCurrent();
   ev.timestamp_microseconds = GetMicrosecondCount();
   ev.event_type = "halt";
   ev.halt_reason = reason;
   m_journal.WriteEvent(ev);
   // slot_id, magic, symbol, ticket_id, lot, price, signal_context,
   // indicator_snapshot, portfolio_summary, triggering_function — all default
  }
```

vs schema lines 70-93:
```yaml
slot_id:
  type: string
  enum: [C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B, BR, BI, system]
  description: "...; 'system' for halt/halt_stable events"

magic:
  type: integer
  minimum: 0
  maximum: 220
  description: "...; 0 for system events"

symbol:
  type: string
  enum: [EURUSD]
  description: "Symbol per C-3 (EURUSD only Phase 1); whitelist enforced FR-1.2"
```

**Problem:**
`JournalEvent` ถูก `ZeroMemory()` แล้วเขียนเฉพาะ `timestamp_*`, `event_type`, `halt_reason`. ส่วน `slot_id` (string default `""`), `symbol` (string default `""`), `signal_context` (default `""`), `triggering_function` (default `""`) ทั้งหมด empty. `magic` default = 0 (acceptable for system events per schema description).

`CTradeJournal::BuildRecord` (TradeJournal.mqh:265-322) เขียน fields ตามลำดับ schema:
- line 272: `w.WriteString("slot_id", ev.slot_id)` → emits `"slot_id":""` (empty literal)
- line 274: `w.WriteString("symbol", ev.symbol)` → emits `"symbol":""`
- line 275: `w.WriteString("signal_context", ev.signal_context)` → emits `"signal_context":""`
- line 278: `w.WriteString("triggering_function", ev.triggering_function)` → emits `"triggering_function":""`

ที่ทุก record มี:
1. `slot_id=""` ไม่อยู่ใน enum → schema validator REJECT (schema enum strict; empty string ≠ "system")
2. `symbol=""` ไม่อยู่ใน enum `[EURUSD]` → REJECT
3. `signal_context=""` allowed (no enum, just description) but loses operator-debug context
4. `triggering_function=""` allowed but loses retrospective audit (FR-3.4 audit) → ใครเป็นคน trigger halt?

ทุก halt + halt_stable record (ที่ schema เพิ่ง lock เพื่อรองรับ event_type=halt + halt_stable per IMPL-044) จะ fail validation. NFR-1.6 audit chain broken — operator post-mortem จะเห็นบรรทัด halt แต่ไม่รู้ slot ที่ trigger / function ที่ call / symbol ที่ active.

**Why This Matters:**
- ADR-010 specifies halt event must carry attribution (FR-7.7 + NFR-5.1 "no silent halt"); current impl strips attribution
- IMPL-044 sample record (evidence file line 81) ใช้ `slot_id=system`, `symbol=EURUSD` — สะท้อน schema intent. Halt path violates own sample
- Round 02.5 fix (StatePersistence `_ExtractStr` unescape) ต้องการ halt_reason มี `"` characters; ที่นี่ halt_reason ผ่านเข้า `WriteString` ที่ JsonWriter escape — OK fix preserved สำหรับ halt_reason แต่ไม่ครอบคลุม empty-required-field issue

**Suggested Fix:**
ปรับ `CEAState::Halt` + `TryTransitionToStable` ให้ populate required fields ตามที่ schema ต้องการ:
```mql5
void CEAState::Halt(string reason)
  {
   if(m_state == EA_STATE_HALTED || m_state == EA_STATE_HALTED_STABLE)
      return;
   m_state = EA_STATE_HALTED;
   m_halt_reason = reason;

   if(m_journal != NULL)
     {
      JournalEvent ev;
      ZeroMemory(ev);
      ev.timestamp_seconds      = TimeCurrent();
      ev.timestamp_microseconds = GetMicrosecondCount();
      ev.event_type             = "halt";
      ev.slot_id                = "system";       // schema § slot_id description
      ev.magic                  = 0;
      ev.symbol                 = _Symbol;        // EURUSD per C-3 / FR-1.2
      ev.halt_reason            = reason;
      ev.signal_context         = StringFormat("halt_reason=%s", reason);
      ev.triggering_function    = "CEAState::Halt";
      m_journal.WriteEvent(ev);
     }
   ...
  }
```
Mirror ใน `TryTransitionToStable` (event_type="halt_stable", same slot_id/symbol).

Same pattern needed in `CPendingMachineRegistry::EmitForceClear` — populate `magic` (MAGIC_M/T/Q lookup), `symbol=_Symbol`, `triggering_function="PendingMachine_X_ForceClear"` per schema description line 181.

**Level of Effort:** Low (3-5 field assignments per call site × 3 call sites)

---

### Finding 03.3: 🟠 HIGH — `CPendingMachineRegistry::EmitForceClear` ส่ง `magic=0` แทน MAGIC_M/T/Q + `symbol=""` + `triggering_function=""` → schema fail + audit drift

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 738-770 (EmitForceClear)
- Schema: `docs/api-specs/trade-journal-schema.yaml` lines 76-93 + 173-181 (triggering_function description)
- Service: `ea` / services / PendingMachineRegistry

**Code:**
```mql5
JournalEvent ev;
ZeroMemory(ev);
ev.timestamp_seconds      = TimeCurrent();
ev.timestamp_microseconds = GetMicrosecondCount();
ev.event_type             = "force_clear";   // also Finding 03.1
ev.slot_id                = code;            // "M" | "T" | "Q" — VALID
ev.pending_age_bars       = age_bars;
ev.signal_context         = StringFormat("machine=%s reason=age_exceeded count=%d",
                                         code, m_machines[id].force_clear_count);
m_journal.WriteEvent(ev);
// magic=0, symbol="", order_type="", triggering_function="" — all default
```

vs schema description line 181:
```yaml
triggering_function:
  description: |
    ...
    Examples:
      "BusinessLogic_C", "ExtraTakeProfit_J" ...,
      "OrderGroupStartWorkflow", ...,
      "CircuitBreakerOrder", "PendingMachine_M_ForceClear" (ADR-008)
```

**Problem:**
- `magic=0` ขัด schema description "0 for system events" — M-Pending/T-Pending/Q-Pending ไม่ใช่ system events; ควรเป็น MAGIC_M / MAGIC_T / MAGIC_Q. Validator strict reading (range 0..220 + zero-only-for-system) จะ flag mismatch when slot_id≠"system"
- `symbol=""` violates schema enum `[EURUSD]`
- `triggering_function=""` ขัด schema example ที่ระบุชัด `"PendingMachine_M_ForceClear"` (line 181) — schema author intended this exact attribution
- IMPL-068 force-clear validation จะนับ events per slot — ถ้า magic=0 + symbol="", QA can't filter by slot

อย่างที่หนัก: ตอน entry .mq5 wire journal ใน IMPL-018+, ทุก record ของ M/T/Q force-clear จะมี structurally invalid metadata. SelfTest ของ PMR ไม่จับเพราะ Case 5/6 pass `m_journal=NULL` → emission path ไม่ถูก exercise.

**Why This Matters:**
- ADR-006 audit chain depends on attribution metadata
- Schema explicit example line 181 is contract — engineer added the example knowing the call site
- NFR-1.4 (forensic capability — operator post-mortem) requires triggering_function

**Suggested Fix:**
```mql5
// PendingMachineRegistry.mqh — add magic resolver helper + populate fields
int _IdToMagic(EPendingMachineId id) const
  {
   switch(id)
     {
      case PM_M: return MAGIC_M;
      case PM_T: return MAGIC_T;
      case PM_Q: return MAGIC_Q;
      default:   return 0;
     }
  }

void CPendingMachineRegistry::EmitForceClear(EPendingMachineId id, int age_bars)
  {
   ...
   if(m_journal != NULL)
     {
      JournalEvent ev;
      ZeroMemory(ev);
      ev.timestamp_seconds      = TimeCurrent();
      ev.timestamp_microseconds = GetMicrosecondCount();
      ev.event_type             = "pending_force_clear";   // also Finding 03.1
      ev.slot_id                = code;
      ev.magic                  = _IdToMagic(id);          // MAGIC_M/T/Q
      ev.symbol                 = _Symbol;                 // EURUSD
      ev.pending_age_bars       = age_bars;
      ev.triggering_function    = StringFormat("PendingMachine_%s_ForceClear", code);
      ev.signal_context         = StringFormat("machine=%s reason=age_exceeded count=%d",
                                               code, m_machines[id].force_clear_count);
      m_journal.WriteEvent(ev);
     }
  }
```
Add SelfTest with mock journal that captures last event + assert all 4 fields populated.

**Level of Effort:** Low

---

### Finding 03.4: 🟠 HIGH — `CPendingMachineRegistry::LoadFromState` reset `pending_started_bar=0` → cold-restart triggers immediate force-clear (opposite of comment claim)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 396-413 (LoadFromState)
- Service: `ea` / services / PendingMachineRegistry

**Code:**
```mql5
void              LoadFromState()
  {
   if(m_state == NULL) return;
   for(int i = 0; i < PM_COUNT; i++)
     {
      EPendingMachineId id = (EPendingMachineId)i;
      m_machines[i].state               = m_state.GetPendingState(id);
      m_machines[i].pending_payload     = m_state.GetPendingPayload(id);
      m_machines[i].force_clear_count   = m_state.GetPmForceClearCount(id);
      // pending_started_bar lives only in RAM during a session; state.json
      // round-trips via SetPendingPayload (started_bar arg). On cold boot
      // the timer effectively resets — acceptable per ADR-008 (timeouts are
      // soft: legacy timeout fires on next tick after restart, force-clear
      // requires multi-bar age which a fresh RAM start delays by at most
      // one full threshold window).
      m_machines[i].pending_started_bar = 0;          // ← เริ่มที่ 0
     }
  }
```

**Problem:**
Comment ระบุชัด: "force-clear requires multi-bar age which a fresh RAM start delays by at most one full threshold window". แต่ logic ตรงข้าม:
- `ShouldForceClear` ใช้ `age = current_bar - m_machines[id].pending_started_bar` (line 722)
- After cold restart: `pending_started_bar = 0`; `current_bar` = bar index ของ broker time ปัจจุบัน (e.g. 850000+ for 2026 H4 series — `MarketContext.bar_index_h4` ที่ผ่านเข้า)
- `age = 850000 - 0 = 850000` > thresholds {150, 80, 100} ทันที
- TickMachine ที่ tick แรกหลัง restart → state == PENDING → `ShouldForceClear` = true → **force-clear ทันที**

ผลลัพธ์: ตรงข้ามกับ comment. ทุก M/T/Q machine ที่ persisted PENDING ใน state.json จะถูก force-clear ที่ tick แรกหลัง cold-restart, ทันที emit `pending_force_clear` journal event + counter increment + Logger.Warn. ที่ comment พูดว่า "delays by at most one full threshold window" — actually impacts opposite direction: not delays, accelerates.

`SetPendingPayload(id, payload, started_bar)` ใน `StatePersistence` accept `started_bar` arg แต่ `GetPendingPayload(id)` ไม่ return `started_bar` — เลยไม่มีทาง recovery. The persisted started_bar ใน `m_pm_started_bar[idx]` (private) ไม่ถูก expose ผ่าน public getter → registry ไม่รู้ original timing.

`SaveToState` ที่ pass `m_machines[i].pending_started_bar` ทำให้ data ถูก persist ใน state.json (ผ่าน `_BuildPmJson` ใน StatePersistence ที่ emit "pending_started_bar":...) — แต่ `GetPmStartedBar` getter ไม่มี → recovery dead-end.

**Why This Matters:**
- ADR-008 force-clear policy = soft safety net, ไม่ใช่ aggressive auto-cleanup
- NFR-3.3 (100% field restore for state.json) violated indirectly — field is persisted but not restored to RAM
- Operator restart scenario: restart EA between bars → ทุก pending state machine ที่ active ถูก force-clear immediately + journal flooded with bogus pending_force_clear records
- Race: comment claims "legacy timeout fires on next tick after restart" — actually `ExceededLegacyTimeout` ใช้ same `age` calc → legacy machines (C/C_ADX/R/P/FORCE) ก็เจอ bug same direction (immediate IDLE on cold restart)

**Suggested Fix:**
1. **Add getter** to `CStatePersistence`:
```mql5
int CStatePersistence::GetPmStartedBar(EPendingMachineId id) const
  {
   int idx = (int)id;
   return (idx >= 0 && idx < PM_COUNT) ? m_pm_started_bar[idx] : 0;
  }
```
2. **Update `LoadFromState`** to actually load:
```mql5
m_machines[i].pending_started_bar = m_state.GetPmStartedBar(id);
```
3. **Add SelfTest case** (Case 7 — cold restart simulation):
```mql5
// Case 7: persist PENDING with started_bar=100; reload registry; tick at
// bar=120 → state still PENDING (age=20 < thresholds); tick at bar=251
// → state IDLE + force_clear_count=1 (age=151 > 150).
sp.SetPendingState(PM_M, PENDING_STATE_PENDING);
sp.SetPendingPayload(PM_M, "{}", 100);
CPendingMachineRegistry r3;
r3.Init(150, 80, 100, 8, 30, 40, 70, 9, &sp, NULL, logger, NULL);
ctx.bar_index_h4 = 120;
r3.TickAll(ctx, port_stub);
if(r3.GetState(PM_M) != PENDING_STATE_PENDING) return false;
ctx.bar_index_h4 = 251;
r3.TickAll(ctx, port_stub);
if(r3.GetState(PM_M) != PENDING_STATE_IDLE ||
   r3.GetForceClearCount(PM_M) != 1) return false;
```
4. **Update comment** เพื่อสะท้อน real behavior หลัง fix.

**Level of Effort:** Low (1 getter + 1 line in LoadFromState + 1 SelfTest case)

---

### Finding 03.5: 🟠 HIGH — `CTradeJournal::BuildIndicatorSnapshotSubset` คืน `"{}"` hard-code → schema field stays empty forever (FR-3.4 retrospective debug broken)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 327-331
- Schema: `docs/api-specs/trade-journal-schema.yaml` lines 134-148 (indicator_snapshot)
- Service: `ea` / services / TradeJournal

**Code:**
```mql5
string CTradeJournal::BuildIndicatorSnapshotSubset(string slot_id)
  {
   slot_id = slot_id;       // suppress unused warning
   return "{}";              // ← hard-coded empty
  }
```

vs schema:
```yaml
indicator_snapshot:
  type: object
  description: |
    Subset of MarketContext fields relevant to slot's signal context.
    Schema mirrors MarketContext fields per ADR-004 / marketcontext-snapshot-schema.yaml.
    Field set varies per slot; reader must tolerate missing keys.
  examples:
    - ichi_h4_cloud_high: 1.0890
      ichi_h4_cloud_low: 1.0860
      force_h4_0: 12.3
      ...
```

**Problem:**
ทุก journal record (entry / exit / modify / reject / halt / pending_force_clear) ออกด้วย `"indicator_snapshot":{}` ตลอดชาติ. Schema technically passes (empty object satisfies `type: object`) แต่:
- FR-3.4 "retrospective audit / type bug detection" หาย: post-mortem ของ entry ที่ผิดพลาดไม่มี indicator context ตอนเข้า trade
- IMPL-068 + QA Phase 3T baseline parity: ไม่มีทางเทียบ legacy EA's signal context vs rewrite without indicator snapshot
- ADR-004 MarketContext snapshot รวม ~25 fields; schema ตั้งใจเฉพาะ "subset relevant to slot" — current impl ส่งศูนย์ฟิลด์เลย

The `m_ctx_builder` member exists (line 68) and is initialized via Init (line 131) — but BuildIndicatorSnapshotSubset doesn't use it. Stub ที่ engineer commented "valid empty object for scaffold" (line 326) ไม่ใช่ scaffold ของ Phase 1 — IMPL-043 lands ที่ Phase P2 ปลายทาง, ไม่ใช่ ahead-of-time placeholder.

**Why This Matters:**
- ADR-006 schema_version=1 lock = fields ต้อง be populated per intent
- IMPL-068 (QA force-clear validation) needs indicator_snapshot fields to compute drift vs baseline
- NFR-1.4 forensic capability gap

**Suggested Fix:**
Either implement subset extraction OR open Deferred-AC row + document scaffold status:
```mql5
// Option A — implement minimal subset (5 most-used fields per ADR-004):
string CTradeJournal::BuildIndicatorSnapshotSubset(string slot_id)
  {
   if(m_ctx_builder == NULL) return "{}";
   const MarketContext &ctx = m_ctx_builder.Current();   // assumed accessor
   CJsonWriter w;
   w.Begin();
   w.WriteDouble("ichi_h4_cloud_high", ctx.ichi_h4_cloud_high, _Digits);
   w.WriteDouble("ichi_h4_cloud_low",  ctx.ichi_h4_cloud_low,  _Digits);
   w.WriteDouble("force_h4_0",         ctx.force_h4_0,         2);
   w.WriteDouble("adx_h4",             ctx.adx_h4,             2);
   w.WriteDouble("rsi_h4",             ctx.rsi_h4,             2);
   w.End();
   return w.ToString();
  }
```
Option B — register Deferred-AC: add row to `docs/state/deferred-ac-registry.md`:
```
| IMPL-043 | indicator_snapshot subset wiring | engineer | 2026-05-17 | low | Risk: forensic gap on FR-3.4 audits | proxied via portfolio_summary in interim |
```
+ comment in code referencing the row.

**Level of Effort:** Medium (Option A — needs `MarketContextBuilder::Current()` API + 5-10 fields) / Low (Option B — registry row only)

---

### Finding 03.6: 🟠 HIGH — `CTradeJournal::WriteEvent` ไม่ self-halt เมื่อ `m_consecutive_failures ≥ JOURNAL_HALT_THRESHOLD` → halt path requires external poll (no caller wired)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 99-104 (ShouldHaltSustained accessor) + 199-227 (WriteEvent main path)
- ADR: `docs/adr/006-journal-format-jsonl.md` (RPO contract — ≥10 consecutive failures → halt)
- Service: `ea` / services / TradeJournal

**Code:**
```mql5
// TradeJournal.mqh:100-104
bool ShouldHaltSustained(int &out_consecutive) const
  {
   out_consecutive = m_consecutive_failures;
   return m_consecutive_failures >= JOURNAL_HALT_THRESHOLD;
  }

// TradeJournal.mqh:199-227 — WriteEvent (main path)
void CTradeJournal::WriteEvent(const JournalEvent &ev)
  {
   RotateIfNeeded();
   if(m_handle == INVALID_HANDLE && !Open())
     {
      HandleWriteFailure("open_failed_before_write");
      return;     // ← keeps returning silently every tick
     }
   ...
   uint written = FileWriteString(m_handle, record);
   if(written < (uint)StringLen(record))
     {
      HandleWriteFailure(...);
      return;
     }
   FileFlush(m_handle);
   ...
  }
```

**Problem:**
ADR-006 RPO escalation: `consecutive_write_failures ≥ 10` → halt EA + Alert. Current impl:
1. `HandleWriteFailure` increments counter but **never checks threshold internally** (line 386-393)
2. `ShouldHaltSustained` is a passive accessor — caller must poll
3. **No caller wires this** — IMPL-049 PendingMachineRegistry doesn't poll; IMPL-052 EAState doesn't poll; entry .mq5 ยังไม่มี

ผลลัพธ์: ถ้า journal disk full / antivirus locks file mid-write → counter climbs 10, 20, 50, 100... ไม่มีใครปลุก `EAState.Halt("journal_write_fail_sustained")`. Schema enum `halt_reason` ระบุ `journal_write_fail_sustained` เป็นค่า expected (line 189), แต่ no path emits it.

IMPL-043 evidence (line 612) ระบุชัด: "deferred-ac-registry row opened 2026-05-03; ShouldHaltSustained structurally verified; EAState.Halt() caller wiring blocked on IMPL-052". ตอนนี้ IMPL-052 (EAState) ก็ closed แล้ว แต่ wiring ระหว่าง TradeJournal ↔ EAState ยังไม่เกิด — Deferred-AC row ยัง valid (expires 2026-05-17). คือไม่ใช่ regression ของ Round 03 directly แต่ Round 03 fail to wire even though both sides exist.

**Why This Matters:**
- ADR-006 RPO contract = hard SLO: ≥10 failures → halt; ขาด wiring = silent risk
- Deferred-AC registry row about to expire (2026-05-17) — 14 day window per `deferred-ac-registry.md` schema — wiring must land before expiry or schedule renewal
- NFR-5.1 "no silent halt" → reverse: silent NON-halt when halt expected

**Suggested Fix:**
Wire EAState into TradeJournal (or vice versa) at orchestrator composition root (IMPL-053+) — but to enable test before then, add internal self-halt to TradeJournal:
```mql5
// TradeJournal.mqh — inject CEAState pointer
private:
   CEAState *m_ea_state;     // NEW

void CTradeJournal::Init(... , CEAState *eas)
  {
   ...
   m_ea_state = eas;
  }

void CTradeJournal::HandleWriteFailure(string reason)
  {
   m_consecutive_failures++;
   if(m_state != NULL) m_state.IncrementJournalFailures();
   if(m_logger != NULL)
      m_logger.Error("system", "journal_write_fail", 0, reason);
   //--- Self-halt at threshold (ADR-006 RPO escalation)
   if(m_consecutive_failures >= JOURNAL_HALT_THRESHOLD && m_ea_state != NULL)
      m_ea_state.Halt("journal_write_fail_sustained");
  }
```
+ Renew Deferred-AC row OR close it with evidence after wiring lands.

**Level of Effort:** Low (1 dependency injection + 1 conditional in HandleWriteFailure)

---

### Finding 03.7: 🟡 MEDIUM — `CPendingForce::_ExtractStr` (PendingMachineRegistry private) replicates Round 02.5 unescape bug → payload corruption on `\"` in origin field

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 85-94 (CPendingForce::_ExtractStr private helper)
- Cross-ref: Round 02 Finding 02.5 (StatePersistence.mqh:706-716) — same naive matcher already fixed
- Service: `ea` / services / PendingMachineRegistry

**Code:**
```mql5
// PendingMachineRegistry.mqh:85-94 — re-introduces Round 02.5 anti-pattern
static string     _ExtractStr(const string content, const string field)
  {
   string needle = "\"" + field + "\":\"";
   int p = StringFind(content, needle);
   if(p < 0) return "";
   p += StringLen(needle);
   int q = StringFind(content, "\"", p);   // ← naive — same bug as 02.5
   if(q < 0) return "";
   return StringSubstr(content, p, q - p);  // ← no unescape
  }
```

**Problem:**
Round 02.5 ติดตั้ง escape-aware terminator + unescape ที่ `CStatePersistence::_ExtractStr`. CPendingForce ใน Round 03 introduces fresh duplicate ที่ขาด fix เดียวกัน. Comment ระบุ "Duplication is intentional to keep PendingForce self-contained" (line 82-84) — แต่ duplication preserves bug class.

Force-pending payload schema (line 41-42 docstring):
```
{"origin":"C","parent_ticket":12345,"direction":1,"bar":42}
```

`origin` field ปัจจุบันถูก slot literal {"C","D","B","BR"} เท่านั้น → real-world ไม่เจอ escape characters. แต่:
1. Future expansion (NEW slot codes ที่อาจมี punctuation) → silent bug
2. State pollution: ถ้า attacker / corrupt state.json injects malformed payload (e.g. `{"origin":"C\"d","parent_ticket":...}`) → `_ExtractStr` truncate ที่ first `"` — return "C\\" → `(StringLen(out_origin) > 0)` true → registry treats as valid → routing decision based on garbage origin

ตรงคู่กัน `_ParsePSubMode` (line 190-204) + `_ParsePDouble` (line 206-231) ใน registry — ใช้ payload ที่ engineer ของ registry สร้างเอง, less risk; but same defensive contract should apply.

**Why This Matters:**
- Code Review Dim #6 cross-service consistency: Round 02 fix philosophy (validate-before-trust) ไม่ propagate
- Forward-compat hazard: any future schema extension ที่ allow string with escape chars จะ regress
- DRY violation: Round 02.5 fix ใน StatePersistence ควร promote ไปเป็น helper ใน `helpers/JsonReader.mqh` (ยังไม่มี) แล้ว reuse

**Suggested Fix:**
Option A — extract shared helper:
```mql5
// helpers/JsonReader.mqh (NEW) — reuse across services
class CJsonReader
  {
public:
   static string ExtractEscapedString(const string content, const string field);
   static long   ExtractInt(const string content, const string field);
   static double ExtractDouble(const string content, const string field);
   ...
  };
```
Then both `CStatePersistence::_ExtractStr` (Round 02.5 fix) and `CPendingForce::_ExtractStr` delegate to it. Single source of truth.

Option B — inline copy of Round 02.5 fix into CPendingForce (cheap; preserves "self-contained" comment intent but reproduces full algorithm).

**Level of Effort:** Low (Option B) / Medium (Option A — but pays off for future readers like SD review tooling)

---

### Finding 03.8: 🟡 MEDIUM — `CEAState::SelfTest` cannot exercise journal/Logger emission → halt-event-payload integrity untested

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/EAState.mqh`
- Lines: 140-221 (SelfTest)
- Service: `ea` / core / EAState

**Code:**
```mql5
bool SelfTest(CLogger *logger)
  {
   logger.Info("system", "SelfTest_EAState", 0, "Starting CEAState self test");
   // We cannot easily inject a mock journal without interface, so we just test state transitions.
   CEAState ea;
   ea.Init(NULL, NULL);          // ← journal=NULL, logger=NULL inside CEAState
   ...
   ea.Halt("test_reason");
   if(ea.GetState() != EA_STATE_HALTED || ea.GetHaltReason() != "test_reason") {...}
   ...
  }
```

**Problem:**
SelfTest validates state machine transitions (4 cases — initial / Halt / TryTransitionToStable / Restore variants) แต่:
1. Journal pointer ที่ `Init(NULL, NULL)` → `m_journal=NULL` → `if(m_journal != NULL)` skip → **ไม่ได้ test ว่า JournalEvent fields ถูก populate ครบ** (cf. Finding 03.2 — required fields not populated; this finding would catch it if mock journal existed)
2. Same for Logger.ErrorBypassThrottle path — never exercised
3. Idempotency test (line 182-187) verifies `GetHaltReason() != "test_reason"` (preserved) but NOT that journal received exactly ONE halt event (idempotent contract per ADR-010)

Engineer wrote "We cannot easily inject a mock journal without interface" — true in MQL5 (no native mocking framework). But MQL5 supports interface emulation via abstract base class:
```mql5
class IJournalSink
  {
public:
   virtual void WriteEvent(const JournalEvent &ev) = 0;
  };
```
Or simpler — testable by changing `m_journal` type to `IJournalSink*` then SelfTest creates a `CMockJournal : IJournalSink` recording last event.

**Why This Matters:**
- Finding 03.2 (halt event missing required fields) would have been caught at SelfTest if mock existed
- IMPL-052 evidence claims `[boot-cold]` E-AC closed via SelfTest (Finding 03.9) — ไม่ exercise journal emission → evidence-kind even more suspect

**Suggested Fix:**
Add lightweight mock journal:
```mql5
class CMockJournalSink
  {
public:
   JournalEvent last_event;
   int          call_count;
   CMockJournalSink() : call_count(0) { ZeroMemory(last_event); }
   void WriteEvent(const JournalEvent &ev) { last_event = ev; call_count++; }
  };
```
Refactor `CEAState::m_journal` to accept either pointer (template OR interface). SelfTest:
```mql5
CMockJournalSink mock;
ea.Init(&mock, &logger);   // assuming Init accepts mock-compatible pointer
ea.Halt("test");
if(mock.call_count != 1) { ... }
if(StringLen(mock.last_event.slot_id) == 0) {
   logger.Error("system", "SelfTest_EAState", 0,
                "Halt event slot_id empty — schema violation");
   return false;
}
ea.Halt("again");
if(mock.call_count != 1) {
   logger.Error("system", "SelfTest_EAState", 0,
                "Idempotent: second Halt should not re-emit journal");
   return false;
}
```

**Level of Effort:** Medium (interface refactor + mock + 3 SelfTest assertions)

---

### Finding 03.9: 🟡 MEDIUM — IMPL-052 closure evidence-kind drift: `[boot-cold]` AC closed via in-process `SelfTest()` because "terminal64.exe headless test execution failed"

**Location:**
- Evidence: `docs/state/_session-handoff/IMPL-052-evidence-20260503.md` lines 17-19
- Source AC: `docs/state/impl-plan.md` IMPL-052 row (E-AC #2: Cold restart with state=HALTED + portfolio_count=0 → reset to RUNNING)
- Service: `ea` / core / EAState

**Code (evidence text):**
```
- **[x] Smoke: invoke Halt("test")** — verified via `SelfTest()`. Local
  `terminal64.exe` headless tester invocation failed to start silently due to
  environment limits, so E-AC assertions were embedded directly into the
  unit-test `SelfTest` method which compiles and passes.
- **[x] Cold restart with state=HALTED + portfolio_count=0 → reset to RUNNING**
  — verified explicitly in `SelfTest` using `RestoreFromState` with
  `portfolio_count=0` → asserts `RUNNING`.
```

**Problem:**
Per `.agents/workflows/impl-review.md` Phase 2.3 closure rules:
> `[boot-cold]` → bootstrap command + smoke chain output from a freshly-torn-down environment

In-process `SelfTest()` ที่ instantiate `CEAState` + เรียก `RestoreFromState(EA_STATE_HALTED, "old_reason", 0)` ในหนึ่ง process เดียว = unit test ของ method, **ไม่ใช่ cold-bootstrap**. The AC text "Cold restart" implies:
1. Start EA with state.json containing HALTED + 0 positions
2. EA boots fresh (new process, new memory)
3. Verify resulting in-RAM state is RUNNING + reset reason

`SelfTest` proxy หาก `RestoreFromState` method ถูกเรียกตามต้องการ — but skip:
- AtomicFile open/parse
- StatePersistence Load round-trip ที่ Round 02.1 fix แก้
- Any orchestrator-side reset side effect

แม้ structurally OK, AC text ระบุ "cold restart" ชัด → kind mismatch per Dim #11 closure rules. Evidence file even self-acknowledges: "terminal64.exe headless tester invocation failed to start silently due to environment limits" — engineer aware of gap, used SelfTest as fallback.

ที่ critical: precedent ที่ IMPL-049 evidence file (line 32) cited: "Live journal write deferred to IMPL-018+ Orchestrator wiring per IMPL-052 header-only `.mqh` precedent" — IMPL-052 establishes a precedent ที่อนุญาต SelfTest แทน boot-cold. IMPL-049 ก็พึ่ง precedent นี้ → systematic drift.

CLAUDE.md § Glossary § Empirical Closure Discipline: "ห้าม `[x]` + 'deferred per <task> precedent'" — IMPL-049 evidence ใช้ทำ exact phrase ("per IMPL-052 header-only `.mqh` precedent") → forbidden pattern. แต่ counter-argument: header-only `.mqh` ไม่มี ortable boot path, structural test = best available proxy. Round 02 (review-round-02.md row 11 Status) ✅ pass'd same pattern.

**Why This Matters:**
- IMPL-052 + IMPL-049 + IMPL-043 all use "structural SelfTest" pattern — drift if not formalized via Deferred-AC
- IMPL-068 + Tier 1.5 walk + P2 Phase Gate empirical demo ต้อง re-verify all these E-ACs at IMPL-018+ once entry .mq5 wires DI chain
- Closure-rule strict reading = Round 03 should flag CRITICAL; pragmatic reading = MEDIUM with explicit Deferred-AC promotion path

**Suggested Fix:**
Either:
A. **Promote to Deferred-AC**: open rows in `docs/state/deferred-ac-registry.md` for:
   - IMPL-052 E-AC #2 (cold restart) — owner: engineer; expiry: 2026-05-17 (concurrent with IMPL-043 row); risk-if-missed: state.json HALTED reset path silently broken at IMPL-018+ entry .mq5
   - IMPL-049 E-AC #1 + #2 (force-clear journal write + state.json round-trip) — same expiry
B. **Leave as-is** (current state) but add explicit IMPL-053+ reverify-at-orchestrator-wire row to impl-plan IMPL-053 Audit Log: "verify IMPL-052/049/043 deferred E-ACs at first orchestrator boot".

Option B is operationally cheaper. Option A is more disciplined per Glossary § Empirical Closure Discipline.

**Level of Effort:** Low (registry rows OR audit-log line)

---

### Finding 03.10: 🔵 LOW — `CTradeJournal::m_overshoot_window[10]` populated but never read for ratio/p99 computation → dead code

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 17 (`#define JOURNAL_OVERSHOOT_WINDOW 10`) + 64 (member array) + 402-412 (TrackLatency)
- Service: `ea` / services / TradeJournal

**Code:**
```mql5
#define JOURNAL_OVERSHOOT_WINDOW 10
...
ulong m_overshoot_window[JOURNAL_OVERSHOOT_WINDOW];
int   m_overshoot_idx;
...
void CTradeJournal::TrackLatency(ulong elapsed_us)
  {
   m_overshoot_window[m_overshoot_idx] = elapsed_us;
   m_overshoot_idx = (m_overshoot_idx + 1) % JOURNAL_OVERSHOOT_WINDOW;

   ulong elapsed_ms = elapsed_us / 1000;
   if(elapsed_ms > JOURNAL_WARN_LATENCY_MS && m_logger != NULL)
      m_logger.Warn("system", "journal_write_slow", 0, ...);
  }
// m_overshoot_window[] never read — only written
```

**Problem:**
NFR-2.2 = `[5 ms p99]` cap. Current impl warns on ANY single write > 5 ms → ตรงข้าม "p99" semantic (warn on 1% tail, not every overshoot). Ring buffer `m_overshoot_window[10]` fills but never gets sorted/percentiled. Code Review Dim #5 = dead surface; NFR-2.2 partial implementation.

NFR-2.2 spec wording: "p99 within 5 ms over a 10-write window". Engineer ตั้งใจสร้าง ring buffer (size 10 = window) but missing the percentile pass.

**Why This Matters:**
- NFR-2.2 verification gate at Phase 4 HARDEN
- Logger flooded by every transient overshoot (e.g. antivirus scan ของ disk = momentary 8ms write) — false positive load
- Round 02.4 (PortfolioMonitor anti-spam) addressed similar pattern; same discipline missing here

**Suggested Fix:**
Implement p99 (or simpler — ratio) check:
```mql5
void CTradeJournal::TrackLatency(ulong elapsed_us)
  {
   m_overshoot_window[m_overshoot_idx] = elapsed_us;
   m_overshoot_idx = (m_overshoot_idx + 1) % JOURNAL_OVERSHOOT_WINDOW;

   //--- Count writes exceeding 5ms in the last 10 writes (proxy for p99 since
   //    proper sort is overkill for n=10).
   int overshoot_count = 0;
   for(int i = 0; i < JOURNAL_OVERSHOOT_WINDOW; i++)
      if(m_overshoot_window[i] > (ulong)JOURNAL_WARN_LATENCY_MS * 1000)
         overshoot_count++;

   //--- Warn only when >1 of last 10 (proxy for >10% tail = breach of p99=5ms)
   if(overshoot_count >= 2 && m_logger != NULL)
      m_logger.Warn("system", "journal_write_slow", 0,
                    StringFormat("path=%s overshoots=%d/10 latest_ms=%llu threshold_ms=%d",
                                 m_active_path, overshoot_count,
                                 elapsed_us / 1000, JOURNAL_WARN_LATENCY_MS));
  }
```

**Level of Effort:** Low

---

### Finding 03.11: 🔵 LOW — `CPendingMachineRegistry::TickMachine` line 691 dead branch `if(port.GetByMagic(0) == NULL && id == PM_COUNT)` — `id == PM_COUNT` impossible

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 685-691 (TickMachine end-of-function comment)
- Service: `ea` / services / PendingMachineRegistry

**Code:**
```mql5
   // No-op for PortfolioState in current passes — kept in signature for
   // future per-machine logic that needs portfolio inspection (e.g. PM_FORCE
   // payload routing in P3 slot integration).
   if(port.GetByMagic(0) == NULL && id == PM_COUNT) return;
}
```

**Problem:**
- `id == PM_COUNT` is structurally impossible: TickAll iterates `for(int i = 0; i < PM_COUNT; i++) TickMachine((EPendingMachineId)i, ...)` — i max = PM_COUNT-1 = 7
- The `if` is a "use the param to suppress unused warning" trick — same anti-pattern as Round 02 Finding 02.7 (CircuitBreaker port + now_ms unused params)
- Also the code already returns early at line 654 (`if(id < 0 || id >= PM_COUNT) return;`) — bounds-check duplicate
- magic=0 is registered (system entry) so `GetByMagic(0)` likely returns non-NULL; even if NULL, the AND with impossible condition makes whole branch unreachable

**Why This Matters:**
- Round 02 Finding 02.7 fix philosophy (drop unused params) NOT applied here — instead engineer chose Option B equivalent (suppress via dead if)
- Confuses future readers: "why does TickMachine care about magic=0 at PM_COUNT boundary?"
- Code Review Dim #5 (Over-Engineering) — same defect class as 02.7 reintroduced

**Suggested Fix:**
```mql5
// Remove dead branch entirely. PortfolioState reference is held in m_portfolio
// (line 144) — slots that need portfolio-aware logic in future passes can read
// from that member, not the parameter passed through TickAll. If parameter
// truly unused after sub-pass (c) is closed, drop it from TickAll signature too:
//
//   void TickAll(const MarketContext &ctx);   // no port arg
//
// Slot P3 integration (M-Pending payload validation) reads m_portfolio directly.
```
+ Remove `CPortfolioState &port` from TickAll/TickMachine signatures if no future caller needs it; if needed, store via Init only.

**Level of Effort:** Low

---

## Cross-Service Issues

| Issue | Files | Finding |
|-------|-------|---------|
| event_type literal mismatch with schema enum (`force_clear` vs `pending_force_clear`) | `services/PendingMachineRegistry.mqh:756` ↔ `docs/api-specs/trade-journal-schema.yaml:57` | 03.1 |
| JournalEvent required-field zero-fill from `ZeroMemory` ↔ schema enum constraints (slot_id/symbol/triggering_function) | `core/EAState.mqh:53-90`, `services/PendingMachineRegistry.mqh:752-762` ↔ `trade-journal-schema.yaml:70-93,173-181` | 03.2 + 03.3 |
| state.json contract: `m_pm_started_bar` persisted but no getter exposed → registry recovery dead-end | `services/StatePersistence.mqh:316-323` (Set only) ↔ `services/PendingMachineRegistry.mqh:411` (LoadFromState resets to 0) | 03.4 |
| ADR-006 RPO halt path incomplete: TradeJournal counts but never escalates; EAState exists but not wired | `services/TradeJournal.mqh:99-104,386-393` ↔ `core/EAState.mqh:45-69` | 03.6 |
| Duplicate naive JSON `_ExtractStr` ignoring Round 02.5 fix | `services/PendingMachineRegistry.mqh:85-94` ↔ `services/StatePersistence.mqh:706-716` (post Round 02.5) | 03.7 |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 03.1 | 🔴 CRITICAL | 6 Cross-Service | EmitForceClear `event_type="force_clear"` ขัด schema enum `pending_force_clear` | PendingMachineRegistry.mqh:756 | Low |
| 03.2 | 🔴 CRITICAL | 6 Cross-Service / 3 Error Handling | EAState.Halt + TryTransitionToStable: required JournalEvent fields ZeroMemory'd → record fail schema (slot_id="" symbol="") | EAState.mqh:53-90 | Low |
| 03.3 | 🟠 HIGH | 6 Cross-Service | EmitForceClear: magic=0 + symbol="" + triggering_function="" → schema fail + audit drift | PendingMachineRegistry.mqh:752-762 | Low |
| 03.4 | 🟠 HIGH | 2 Business Logic | LoadFromState resets pending_started_bar=0 → cold-restart triggers immediate force-clear (opposite of comment) | PendingMachineRegistry.mqh:396-413 + StatePersistence.mqh missing getter | Low |
| 03.5 | 🟠 HIGH | 9 TD Compliance / 6 Cross-Service | BuildIndicatorSnapshotSubset hard-codes "{}" → FR-3.4 forensic audit broken | TradeJournal.mqh:327-331 | Medium / Low |
| 03.6 | 🟠 HIGH | 3 Error Handling | TradeJournal.WriteEvent does not self-halt at JOURNAL_HALT_THRESHOLD; ShouldHaltSustained never polled | TradeJournal.mqh:99-104,386-393 ↔ EAState.mqh | Low |
| 03.7 | 🟡 MEDIUM | 5 Over-Engineering / 6 Cross-Service | CPendingForce::_ExtractStr replicates Round 02.5 unescape bug | PendingMachineRegistry.mqh:85-94 | Low / Medium |
| 03.8 | 🟡 MEDIUM | 7 Test Coverage / 10 Test Quality | EAState.SelfTest cannot test journal emission paths (NULL deps) | EAState.mqh:140-221 | Medium |
| 03.9 | 🟡 MEDIUM | 11 E-AC Closure | IMPL-052 `[boot-cold]` E-AC closed via SelfTest, environment limit cited; precedent now used by IMPL-049/043 | impl-plan.md IMPL-052 row + IMPL-052-evidence-20260503.md:17-19 | Low |
| 03.10 | 🔵 LOW | 5 Over-Engineering | TradeJournal m_overshoot_window populated but never read (NFR-2.2 p99 missing) | TradeJournal.mqh:64,402-412 | Low |
| 03.11 | 🔵 LOW | 5 Over-Engineering | TickMachine line 691 dead branch (`id == PM_COUNT` impossible); Round 02.7 anti-pattern reintroduced | PendingMachineRegistry.mqh:685-691 | Low |

---

## Anti-regression Check (Round 01 + Round 02 fixes preserved)

| Round | Finding | Check | Status |
|-------|---------|-------|--------|
| 01.2 | ZigZag path | `grep -nE "iCustom\(.*\"ZigZag\"" services/IndicatorService.mqh` | ✅ 0 hits (Examples\\ZigZag preserved) |
| 01.4 | invalid_handle ErrorBypassThrottle | `grep -n "Logger.Error.*invalid_handle" services/IndicatorService.mqh` | ✅ 0 hits (uses ErrorBypassThrottle) |
| 01.7 | last_open_lot init / fail-loud | `grep -n last_open_lot services/PortfolioState.mqh services/RiskManager.mqh` | ✅ Round 02.3 fix preserved, propagated through to PendingMachineRegistry indirectly |
| 02.1 | StatePersistence pending_payload `_ExtractRawValue` | (read services/StatePersistence.mqh; PMR LoadFromState calls `m_state.GetPendingPayload(id)` which uses fix path) | ✅ Preserved; not exercised by Round 03 SelfTest (Case 6 uses default-constructed CStatePersistence — accessor only, no JSON roundtrip) |
| 02.2 | CircuitBreaker BR-3.6 threshold | `grep -n PING_PONG_THRESHOLD_S CircuitBreaker.mqh` | ✅ value=3 preserved |
| 02.5 | StatePersistence `_ExtractStr` JSON unescape | (read StatePersistence.mqh:706+) | ✅ Preserved; **but NEW duplicate at PendingMachineRegistry.mqh:85-94 replicates the bug** — see Finding 03.7 |
| 02.7 | CircuitBreaker dropped unused params | (read CircuitBreaker.mqh CheckPingPong) | ✅ Preserved; **but NEW similar pattern at PMR TickMachine line 691** — see Finding 03.11 |
| 02.9 | close_time_s field rename | `grep -n close_time_ CircuitBreaker.mqh` | ✅ close_time_s preserved |

---

## Recommendation

**Verdict:** ❌ **Not Ready for P2 Phase Gate** — 2 CRITICAL + 4 HIGH = schema-on-disk contract integrity broken at multiple call sites. The class of defect (schema field violations + ZeroMemory laziness) blocks IMPL-068 (QA force-clear validation) + Tier 1.5 walk's journal artifact validation. Fixes are individually small (Low/Medium effort) but together form a contract-coherence pass that must land before entry .mq5 (IMPL-018+) wires journal output to disk.

**Top priority fixes:**
1. **03.1 + 03.2 + 03.3 (CRITICAL/HIGH bundle, ~30 min total):** populate JournalEvent required fields at the 3 call sites (EAState.Halt, EAState.TryTransitionToStable, PMR.EmitForceClear) + fix `event_type="pending_force_clear"` literal. **Blocks ADR-006 schema_version=1 contract** + IMPL-044 just-locked v1 integrity.
2. **03.4 (HIGH, ~20 min):** add `GetPmStartedBar` getter + load in `LoadFromState` + SelfTest case 7. **Blocks operator-restart safety** (currently every restart force-clears all M/T/Q PENDING machines in journal flood).
3. **03.6 (HIGH, ~15 min):** wire `CTradeJournal::HandleWriteFailure` → `m_ea_state->Halt("journal_write_fail_sustained")`. **Closes ADR-006 RPO contract loop** + Deferred-AC row IMPL-043 expiry 2026-05-17.

Bundle plan for `/impl-review-fix`:
- **G1 (CRITICAL/HIGH bundle):** 03.1 + 03.2 + 03.3 + 03.4 + 03.6 — schema integrity + restart safety + halt wiring; commit `[fix:ea] code-review-03 schema-contract bundle`
- **G2 (HIGH polish):** 03.5 (indicator_snapshot Option A or B) — separate commit
- **G3 (MEDIUM bundle):** 03.7 + 03.8 + 03.9 — duplication / mock journal / Deferred-AC promotion; commit `[refactor:ea] code-review-03 quality bundle`
- **G4 (LOW bundle):** 03.10 + 03.11 — single commit `[refactor:ea] code-review-03 polish`

**Empirical verification deferral:** All E-AC of IMPL-043/049/052 ปัจจุบัน rely on SelfTest precedent. Round 03.9 flags this as MEDIUM (not CRITICAL) per pragmatic reading consistent with Round 02 standing rule, but recommends Deferred-AC row promotion for IMPL-052 + IMPL-049 closure (mirror IMPL-043 path) before P2 Phase Gate nomination. Empirical demo at IMPL-053+ orchestrator wire-up will retire all 3 rows simultaneously when entry .mq5 boots.

**Anti-regression follow-up:** Round 03 Findings 03.7 + 03.11 indicate the team is **re-introducing patterns** Round 02 fixed (naive `_ExtractStr` + unused-param-suppression-via-dead-branch). Recommend adding lint/grep gate before Round 04: 

```bash
# pre-commit lint candidates
grep -nE 'StringFind\(content, *"\\""\)' services/*.mqh | grep -v _ExtractEscapedString
# expect 0 hits — any naive single-quote terminator scan must be replaced with the
# Round 02.5 escape-aware terminator (or shared helpers/JsonReader.mqh)
```

Add to `.claude/rules/ea.md § Naming Conventions` post-Round 03 fix:
> **JSON parsing in services:** ห้าม use raw `StringFind` for `"key":"` terminator scan — must call `helpers/JsonReader.mqh` (or replicate the Round 02.5 escape-aware algorithm verbatim with `// matches StatePersistence._ExtractStr` comment). New duplicates trigger HIGH finding.
