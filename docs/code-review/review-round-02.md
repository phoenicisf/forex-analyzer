# Code Review Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Target** | `all` (P2 6/11 closures — `MQL5/Experts/PhoenicisNex/services/{RiskManager,PortfolioMonitor,StatePersistence,TimeGate,CircuitBreaker}.mqh`) |
| **Date** | 2026-05-03 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | 5 new/significantly-extended source files + AtomicFile/SlotState dependency cross-check; IMPL-040, 045, 047, 050, 051 (IMPL-048 spec-only — out of code-review scope) |
| **Cumulative LOC reviewed (P2 delta)** | ~2,490 LOC (RiskManager 570 + StatePersistence 822 + PortfolioMonitor 313 + TimeGate 376 + CircuitBreaker 363 + cross-check) |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH     | 3 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **10** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1  | Security (OWASP / MQL5 boundary) | ✅ Pass | NFR-7.2 = 0 external DLLs preserved; no `WebRequest` / `#import`; symbol-trust still gated at IndicatorService Init (round-01 fix); no secret/credential surface in P2 services |
| 2  | Business Logic Correctness | ⚠️ Finding | BR-3.6 ping-pong threshold semantic 1000× off (Finding 02.2); J/BI/I parent-lot read uses `total_lots` aggregate (Finding 02.3) |
| 3  | Error Handling | ⚠️ Finding | PortfolioMonitor.Update logs Error every tick on NULL state — no early return + log flood (Finding 02.4); RiskManager.Init zeros config before NULL-guard return (Finding 02.6) |
| 4  | Performance | ✅ Pass | CircuitBreaker O(n²) ≤ 16² = 256 pairs/tick negligible; StatePersistence.SerializeAll one-shot per Save(); StringFind-based parser bounded by file size |
| 5  | Over-Engineering | ✅ Pass | All P2 services map 1:1 to TD-02 §5 skeletons; no premature interface; SelfTest stays static-bounded |
| 6  | Cross-Service Consistency | ⚠️ Finding | StatePersistence pending_payload write `WriteRaw` ↔ read `_ExtractStr` round-trip mismatch (Finding 02.1) |
| 7  | Test Coverage Gaps | ⚠️ Finding | RiskManager SelfTest verifies dispatch + clamp but **does not** exercise round-trip parent-lot read (Finding 02.3 root cause hidden from SelfTest); no SelfTest for StatePersistence Save→Load round-trip (Finding 02.1 root cause hidden) |
| 8  | Architecture Compliance | ✅ Pass | 5-layer include direction respected; Composition Root preserved (services accept Logger/State via Init); no `slots/*` `#include "slots/<other>"` (no slot files in P2) |
| 9  | Technical Design Compliance | ⚠️ Finding | CircuitBreaker `close_time_ms` field name suggests millisecond precision (TD-02 §5.8 verbatim) but storage is datetime seconds + threshold misinterpreted (Finding 02.2 + 02.7) |
| 10 | Test Code Quality | ✅ Pass | All SelfTest fixtures bounded (8 cases RiskManager / 5 PortfolioMonitor / 4 CircuitBreaker); CircuitBreaker SelfTest properly saves/restores ring buffer state; no shared mutable state |
| 11 | Empirical AC Closure | ✅ Pass | All E-AC for IMPL-040/045/047/050/051 closed `[ ]` with "deferred to IMPL-018+" forward-task dependency citing existing precedent (IMPL-005/007/011/050/051). grep `impl-plan.md` for `[x]` + "deferred per <task> precedent" / "deferred to operator-runtime" = 0 hits ✅. SelfTest pattern preserved for structural verification gate |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface (UX phase ⏭ N/A); P2 = service-layer header-only `.mqh` (no live runnable surface yet — entry .mq5 lands at IMPL-018+) |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; ไม่มี env var / secret / API key consumer ใน P2 services (Logger throttle params + ban cooldowns เป็น Init param, not env) — promotes ถ้า Phase 2 cloud journal added |

---

## Findings

### Finding 02.1: 🔴 CRITICAL — `CStatePersistence` `pending_payload` round-trip ขาด → silent data loss ทุก reboot

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/StatePersistence.mqh`
- Lines: 420-423 (Save serialize) ↔ 622 (Load parse) ↔ 706-716 (`_ExtractStr` impl)
- Service: `ea` / services / StatePersistence

**Code:**
```mql5
// Save side (lines 420-423):
if(StringLen(m_pm_payload[i]) > 0)
   mc.WriteRaw("pending_payload", m_pm_payload[i]);   // emits   "pending_payload":<raw-json>
else
   mc.WriteNull("pending_payload");                    // emits   "pending_payload":null

// Load side (line 622):
m_pm_payload[i] = _ExtractStr(mc_json, "pending_payload");

// _ExtractStr impl (lines 706-716):
string search = "\"" + field + "\":\"";   // ← LOOKS FOR "key":" (quoted-string form ONLY)
int pos = StringFind(content, search);
if(pos < 0) return "";                     // ← raw-object form NEVER matches → returns ""
```

**Problem:**
Save writes `pending_payload` ผ่าน `WriteRaw` (no surrounding quotes — payload ถือว่าเป็น opaque JSON object/value per ADR-008 + state-persistence-schema.yaml § pending_machines). Load อ่านผ่าน `_ExtractStr` ที่ค้นหา literal pattern `"pending_payload":"` (มี opening double-quote ถัดจาก colon). เมื่อ payload ถูก serialize เป็น raw object `{...}` หรือเป็น `null`, `_ExtractStr` หา `":"` ตามไม่เจอ → return `""` ทันที. ผลลัพธ์: ทุก reboot, `m_pm_payload[0..7]` = `""` — **silent ทั้งหมด**, ไม่มี Warn / Error.

**Why This Matters:**
ADR-008 § force-clear depends on pending payload context (started_bar + opaque payload เพื่อ resume same-magic state machine post-restart). Round-trip loss = pending machines เสีย restart contract: post-reboot, all 8 pending machines มี `state` + `pending_started_bar` + `force_clear_count` แต่ **payload ว่างหมด** → state machines พบ payload="" ก่อน expected JSON → either crash on parse หรือ silent reset to IDLE → **OQ-A1/A2/A3 force-clear behavior not preserved**. NFR-3.3 (100% field restore) violated. state-persistence-schema.yaml § pending_machines spec: `pending_payload` required + opaque JSON. Round-trip property lost.

อย่างที่หนัก: loss นี้ **invisible ใน SelfTest** — IMPL-047 SelfTest ไม่มี Save→Load round-trip test (ตามที่ E-AC ทั้งหมด deferred to IMPL-018+). G3/G4 gate ตอน entry .mq5 land จะจับได้ก็ต่อเมื่อ test scenario specifically writes payload + restarts + asserts equal — ซึ่งไม่มี explicit case ใน impl-plan ปัจจุบัน.

**Suggested Fix:**
Option A (preferred — keep payload as opaque JSON object): change `_ExtractStr` callsite for `pending_payload` to `_ExtractSubObj` (already exists at lines 793-809 with brace-depth tracking):
```mql5
//--- pending_machines (8 entries) — payload is opaque JSON object/value, use brace-aware extractor
for(int i = 0; i < PM_COUNT; i++)
  {
   EPendingMachineId mid = (EPendingMachineId)i;
   string mc_json = _ExtractSubObj(pm_json, _PmKey(mid));
   if(StringLen(mc_json) > 2)
     {
      m_pm_state[i]             = _StrToPendingState(_ExtractStr(mc_json, "state"));
      m_pm_started_bar[i]       = (int)_ExtractInt(mc_json, "pending_started_bar");
      m_pm_force_clear_count[i] = (int)_ExtractInt(mc_json, "force_clear_count");
      //--- payload may be a JSON object {...} OR null OR string — handle all 3
      string raw_payload = _ExtractRawValue(mc_json, "pending_payload");  // NEW helper
      m_pm_payload[i] = (raw_payload == "null" ? "" : raw_payload);
     }
  }
```
…where `_ExtractRawValue(content, field)` returns the literal JSON value text (object/array/number/null/string with surrounding quotes intact) by reading until matching close brace/bracket OR end-of-value at `,` / `}`. Mirror existing `_ExtractSubObj` logic.

Option B (degenerate to string): change Save side to `WriteString` and require callers to escape JSON-in-string. Cheaper but harder for future Phase-2 cloud sync.

Add round-trip SelfTest case (immediate verification before IMPL-018+ wiring):
```mql5
//--- StatePersistence::SelfTestRoundTrip (new, called manually IMPL-047b)
//    1. Set pm_payload[PM_C] = "{\"a\":1,\"b\":\"x\"}";
//    2. Save → SerializeAll → WriteAtomic
//    3. Reset members → Load → assert m_pm_payload[PM_C] equals input
```

**Level of Effort:** Low (Option A — 30 LOC + new helper) / Low+roundtrip-test (recommended)

---

### Finding 02.2: 🔴 CRITICAL — `CCircuitBreaker` ping-pong threshold off by **1000×** vs BR-3.6 spec → halt semantic broken

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`
- Lines: 62-63 (constants) + 173-235 (CheckPingPong) + 18-29 (header rationalization)
- Service: `ea` / services / CircuitBreaker

**Code:**
```mql5
//--- Threshold constants (BR-3.6)
static const int  PING_PONG_THRESHOLD_S = 3000;    // ping-pong halt threshold (seconds)
static const int  NEAR_MISS_THRESHOLD_S = 5000;    // near-miss warn threshold (seconds)
...
long delta = (long)m_buffer[i].close_time_ms - (long)m_buffer[j].close_time_ms;
...
if(delta <= (long)PING_PONG_THRESHOLD_S) { /* halt */ }
```

vs `docs/ba/04-business-rules.md` § BR-3.6 line 194:
```
**Condition:** Same position re-opens within **3000 ms** ของ previous close
**Action:** EA halt + Alert (FR-7.7) + journal entry
**Why:** Detect infinite loop / runaway flip-flop ที่กิน balance
```

**Problem:**
BR-3.6 spec ระบุชัด **3000 ms** = 3 seconds (รุ่น runaway flip-flop ที่กิน balance ภายใน sub-minute scale). โค้ดเก็บ `close_time_ms` เป็น `datetime` (seconds-precision per MT5 default; header §datetime-precision-note acknowledges "actual storage is seconds floor"). Constant `PING_PONG_THRESHOLD_S = 3000` หมายถึง **3000 seconds = 50 นาที**. ทุก same-(magic, direction) pair ที่ close 50 นาทีของกัน → halt. BR-3.6 ที่ขอให้ตรวจ "balance-eating runaway loop" (sub-second flip-flop) **ไม่เคย trigger เลย** (loops ที่เร็วกว่า 1 วินาที delta = 0..1 seconds → ก็ ≤ 3000 sec → halt; แต่ false positives จาก legitimate close-and-reopen 10-30 นาทีหลัง = halt ด้วย).

ผลลัพธ์ 2 axis ของ defect:
1. **False positive:** ทุก slot ที่ close trade แล้ว reopen ภายใน 50 นาที (เช่น `OrderGroupStartWorkflow` safe port หรือ `H` slot wave continuation) → halt EA ทุกครั้ง
2. **False negative:** runaway flip-flop ที่ EA bug spawn (sub-second close→reopen) → จับได้แต่ตัวเลข threshold "ผ่าน" เพราะค่า ≤ 3000 sec — แต่ semantic ไม่ตรงกับ BR-3.6 spirit (3-second window guard)

Header §datetime-precision-note (lines 18-29) acknowledge ms-vs-s gap แต่ "pragmatic" justification ขัด BR-3.6 spec letter (3000ms != 3000s). Subsequent SelfTest (cases A-D) verify ที่ 1500/4000/6000 second เครื่องหมาย "s" — ไม่ตรงกับ "3000 ms" ของ spec.

**Why This Matters:**
- BR-3.6 = 🔒 locked business rule per BA `04-business-rules.md` (3000ms verbatim)
- NFR-5.1 (no silent halt) ขัดเล็กน้อย: halt ที่เกิดจาก threshold ผิด = false-positive halt (operator surprise)
- NFR-1.1 behavioral parity: legacy EA `:15796` CircuitBreakerOrder spec = sub-second window. รีไรท์ที่เปิด 50-min window = **Bucket A drift > 25%** เกือบแน่ (กำหนด halt freq สูงกว่ามาก)
- Code Review Dimension #2 Business Logic Correctness — *partial implementation ที่ produce wrong-but-plausible result* — same defect class as round-01 Finding 01.7 CachedScan
- TD-02 §5.8 verbatim "3000ms" preserved in skeleton, แต่ implementation drift ที่นี่ ≠ TD-02 design intent

**Suggested Fix:**
ทางเลือก (preferred): upgrade to millisecond precision per ADR-001 single-tick invariant + GetMicrosecondCount:
```mql5
private:
   struct CloseEvent {
      int    magic;
      int    direction;
      ulong  close_time_us;   // microseconds since some epoch (GetMicrosecondCount)
   };
   static const ulong PING_PONG_THRESHOLD_US = 3000ULL * 1000ULL;   // 3000 ms = 3,000,000 µs
   static const ulong NEAR_MISS_THRESHOLD_US = 5000ULL * 1000ULL;   // 5000 ms = 5,000,000 µs

public:
   // Caller passes GetMicrosecondCount() at event time
   void RecordOpen(int magic, int direction, ulong now_us);
   void RecordClose(int magic, int direction, ulong now_us);
   bool CheckPingPong(CPortfolioState &port, ulong now_us);
```
+ adapt SelfTest cases A-D to use microsecond deltas (1500 ms = 1,500,000 µs etc.).

ทางเลือก (cheap fallback): **fix the const naming + value** — keep datetime seconds storage but call it explicitly out-of-spec:
```mql5
static const int PING_PONG_THRESHOLD_S = 3;    // BR-3.6 = 3000ms = 3s (datetime seconds floor)
static const int NEAR_MISS_THRESHOLD_S = 5;    // 5000ms = 5s
```
+ update SelfTest cases A-D timestamps to reflect 3-s halt window (1.5/4/6 sec respectively).

ทางเลือก (escalate): `/backtrack sd` — record BR-3.6 ambiguity (ms vs s) + ADR amendment if seconds-precision preferred. Currently BR-3.6 is 🔒 locked → text amendment requires backtrack.

**Level of Effort:** Medium (microsecond upgrade + RecordOpen/Close caller updates) / Low (rename + value fix + SelfTest update)

---

### Finding 02.3: 🟠 HIGH — `CRiskManager::_ComputeLotForJ/BI/I` reads `total_lots` (aggregate) แทน last/parent open lot — wrong lot sizing under any pyramid

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh`
- Lines: 268-289 (J), 299-319 (BI), 329-349 (I)
- Service: `ea` / services / RiskManager

**Code:**
```mql5
double CRiskManager::_ComputeLotForJ(double extra)
  {
   ...
   SlotState *cd = m_portfolio.GetByMagic(MAGIC_CD);
   ...
   //--- total_lots is the best available field (see Implementation note in file header)
   double parent_lot = cd.total_lots;            // ← CUMULATIVE SUM, not last-open
   return parent_lot * 0.23 * extra;
  }

double CRiskManager::_ComputeLotForBI()
  {
   ...
   SlotState *b = m_portfolio.GetByMagic(MAGIC_B);
   ...
   double parent_lot = b.total_lots;             // ← same aggregate confusion
   return parent_lot * 0.236;   // ADR-009: Fibonacci 23.6%
  }

double CRiskManager::_ComputeLotForI()
  {
   ...
   double parent_lot = g.total_lots;             // ← same
   return parent_lot * 0.382;
  }
```

**Problem:**
- ADR-009 (BI Fibonacci 23.6%) + CodeWiki §4.1 row J/I formulas ทั้งหมดอ้าง **per-position parent lot** (latest open ของ parent slot) ไม่ใช่ aggregate.
- `SlotState.total_lots` (domain/SlotState.mqh:35) = sum ของ open positions ใน slot pool. หาก parent CD/B/G มี 3 open positions รวม 0.30 lot:
  - Spec intent: J lot = 0.10 (last open) × 0.23 = 0.023
  - Current impl: J lot = 0.30 (aggregate) × 0.23 = 0.069 — **3× too large**
- Pyramid scenarios (CD = 5 positions × 0.10 = 0.50 aggregate) → BI lot = 0.50 × 0.236 = 0.118 (เกินกว่า ADR-009 cap intent 0.0236 = 5×)
- Risk amplification: BR-4.2 cap (LimitMaxLotSizeRatio × balance / 1000) จะ clamp แต่ NFR-1.1 (Bucket A drift ≤ 25%) ก็ยัง impact ใหญ่ ในวันที่ parent มี 4-5 positions
- File header (lines 11-17) acknowledges this trade-off ชัดเจน: "SlotState has `total_lots` (running aggregate) and no explicit `last_open_lot` field". แต่: documenting the trade-off ≠ acceptable correctness

ที่หนัก: **SelfTest ไม่จับ** — Cases 7-8 ทดสอบเฉพาะ NULL-portfolio guard (`m_portfolio.GetByMagic` return NULL → 0.0). ไม่มี case ใดที่ stub portfolio ที่มี 3 positions × 0.10 อยู่แล้วเช็คว่า J = 0.023 (intent) vs 0.069 (current). G3 headless backtest ตอน entry .mq5 land อาจ blame SR drift 25-50% โดยไม่ trace ลงมาที่ formulas.

**Why This Matters:**
- BR-4.1 + ADR-009 + CodeWiki §4.1 ทั้งหมด lock formula 1:1 — drift = NFR-1.1 violation (Bucket A drift > 25% likely)
- IMPL-039 / IMPL-053 (BI orchestrator wiring) จะใช้ `_ComputeLotForBI()` ตรง → wrong lot will be sent ผ่าน RiskManager.OpenOrder → broker จริง
- Engineer documented the gap as "deferred to IMPL-039/053+ when broker position query (Refresh) is wired" but wiring won't change formula — still reads `total_lots`. The deferral doesn't actually fix anything — it kicks the ball.

**Suggested Fix:**
1. **Add `last_open_lot` field to `domain/SlotState.mqh`** (per Claim 02.1 hint in TD-02 — likely already-planned but not landed):
   ```mql5
   class SlotState {
   public:
      ...
      double  total_lots;
      double  last_open_lot;       // NEW — set by PortfolioState.Refresh() to most recent OnOrderOpen lot
      ...
   };
   ```
2. **Update `PortfolioState.RegisterAll` + Refresh-on-OnTick** to populate `last_open_lot` per BR-5.x (last position size at OnTradeTransaction).
3. **Update RiskManager.{_ComputeLotForJ, _ComputeLotForBI, _ComputeLotForI}** to read `cd.last_open_lot` / `b.last_open_lot` / `g.last_open_lot` instead of `total_lots`.
4. **Add SelfTest case** (Case 9) with stub portfolio: register magic 200 with `last_open_lot=0.10` + `total_lots=0.30` → assert `_ComputeLotForJ(1.0) == 0.023` not 0.069.
5. **Document in commit:** ADR-009 row BI explicitly = `0.236 × last-open-B-lot`, not `× total-B-lots`.

**Level of Effort:** Medium (3 file edits + 1 SelfTest case + verify on PortfolioState.Refresh contract)

---

### Finding 02.4: 🟠 HIGH — `CPortfolioMonitor::Update` logs `Error` ทุก tick เมื่อ `m_state == NULL` → log flood + ADR-011 anti-spam violation

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PortfolioMonitor.mqh`
- Lines: 124-180 (Update — Step 1 NULL guard)
- Service: `ea` / services / PortfolioMonitor

**Code:**
```mql5
void CPortfolioMonitor::Update(double current_equity, datetime now)
  {
   //--- Step 1: NULL-guard state (monitor-only — do NOT halt per OQ-6)
   if(m_state == NULL)
     {
      if(m_logger != NULL)
         m_logger.Error("PortfolioMonitor", "update_state_null", 0,
                        "m_state is NULL in Update — DD values not persisted");
      //--- In-memory update proceeds so accessors remain readable
     }
   //--- ... (no early return — proceeds to Step 2/3/4 every tick)
   ...
  }
```

**Problem:**
ถ้า PortfolioMonitor ถูก wire โดยที่ `Init` ล้มเหลว (state NULL → `m_state` stays NULL per Init line 92-97 + Init does NOT return early so m_logger is set; but m_state stays NULL) — **ทุกครั้งที่ Orchestrator เรียก `Update` (every tick on EURUSD H4 = 1 tick ~ seconds)** จะ emit `Error` event "update_state_null". ผ่าน Logger.Error route ที่มี throttle (per ADR-011) แต่:
- Logger throttle window per (slot, ev) tuple = same key `("PortfolioMonitor", "update_state_null", 0)` → throttle จะกัน Alert spam **แต่** Print ไม่ throttle → log file flooded with same error per tick
- StatePersistence persist `m_logger_throttled_count` counter → counter blows up ทุก session
- ขัด `.claude/rules/security.md § Halt + Failure Surfacing` "no silent failures" + "anti-spam ≤ 1 per slot per session per ADR-008" (ADR-008 referenced in security.md, ADR-011 in CLAUDE.md — both reflect anti-spam contract)

In-memory update ที่ "proceeds to Step 2-4" ทำให้ accessors readable แต่ก็ไม่ persist → `state.json § watch_profits` stays at last-saved values forever → cold-bootstrap gets stale DD numbers + halt-stable Alert message will use wrong DD figure.

**Why This Matters:**
- PortfolioMonitor = critical observability surface (FR-8.2 incremental DD + warm-restart prime via Init lines 100-104). NULL state = degraded mode but still ticking.
- Operator-side: log file fills disk under sustained NULL-state scenario; engineer triaging "DD log spam" จะมองหา throttle config ก่อน root cause (NULL state).
- TD-02 §5.12 + shared-context §6.8: "anti-spam: log only on new worst (not every tick)" — Step 4 honors this for new-worst, but Step 1 NULL-guard does not.

**Suggested Fix:**
1. Add **early return** with one-time-per-session log (use `m_state_null_logged` boolean):
```mql5
private:
   bool m_state_null_logged;   // NEW — guards one-shot Error per session

void CPortfolioMonitor::Update(double current_equity, datetime now)
  {
   if(m_state == NULL)
     {
      if(!m_state_null_logged && m_logger != NULL)
        {
         m_logger.ErrorBypassThrottle("PortfolioMonitor", "update_state_null", 0,
                                      "m_state is NULL — DD not persisted; this msg suppressed for rest of session");
         m_state_null_logged = true;
        }
      //--- Early return: no in-memory update either; if state vanished mid-session, skip until restored
      return;
     }
   m_state_null_logged = false;   // reset on healthy state
   ...
  }
```
2. Or — make NULL state a fail-fast at Init (return early like Logger NULL guard, line 84-88) so `Update` is never called with NULL state. Currently Init lines 91-97 log Error but does not abort wiring → `Update` callable with NULL state.

**Level of Effort:** Low

---

### Finding 02.5: 🟠 HIGH — `CStatePersistence::_ExtractStr` ขาด JSON-string escape handling → corruption on quote/backslash in halt_reason / slot_ids

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/StatePersistence.mqh`
- Lines: 706-716 (`_ExtractStr`)
- Service: `ea` / services / StatePersistence

**Code:**
```mql5
string CStatePersistence::_ExtractStr(const string content,
                                      const string field) const
  {
   string search = "\"" + field + "\":\"";
   int pos = StringFind(content, search);
   if(pos < 0) return "";
   int start = pos + StringLen(search);
   int end   = StringFind(content, "\"", start);    // ← NAIVE TERMINATOR — ANY '"' wins
   if(end <= start) return "";
   return StringSubstr(content, start, end - start);   // ← does NOT unescape '\\"' / '\\\\'
  }
```

**Problem:**
JsonWriter (round-01 Finding 01.9 fix) ตอนนี้ escape control chars + backslash + double-quote per RFC 8259 §7. Save side correctly produces `"halt_reason":"corrupt at \"foo.json\""`. Load side `_ExtractStr` ค้น first `"` หลัง start → ตรงตำแหน่ง `\"` (ไม่ใช่ closing `"`) → `end` เป็น position ของ escape-quote → return string ขาด ที่ `corrupt at \\` (truncated mid-content). Worse: subsequent fields ใน parser อาจ accidentally read garbage จากตำแหน่ง broken.

ในขณะนี้ Phase 1 มี 3 callsite ของ `_ExtractStr` ที่อาจมี escaped chars:
1. `ea_halt_reason` (line 586) — caller-supplied error reason. ทุก halt reason ที่มี `"` (เช่น "spike fail at \"AtomicFile.WriteAtomic\"") จะ corrupt round-trip
2. `pending_payload` (line 622) — Finding 02.1 ก็ใช้ `_ExtractStr`; ถ้า fix Finding 02.1 ด้วย Option B (string form) → ก็ต้องแก้ unescape ที่นี่
3. `ea_state` (line 583) — only `RUNNING/HALTED/HALTED_STABLE` enum values, ไม่ contain quotes → safe

**Why This Matters:**
- NFR-3.3 (100% field restore) violated for any halt_reason containing quote/backslash
- ADR-006 + ADR-007 atomic-write contract = byte-perfect round-trip; current broken contract leaks halt reason text
- security.md § Local-only Data Discipline + halt path requires "Alert + journal entry" — if halt_reason corrupt, journal entry has wrong reason, operator post-mortem misled

**Suggested Fix:**
Add JSON-string-aware termination + unescape:
```mql5
string CStatePersistence::_ExtractStr(const string content,
                                      const string field) const
  {
   string search = "\"" + field + "\":\"";
   int pos = StringFind(content, search);
   if(pos < 0) return "";
   int start = pos + StringLen(search);
   //--- find closing '"' that is NOT preceded by an odd number of backslashes
   int n = StringLen(content);
   int end = -1;
   for(int i = start; i < n; i++)
     {
      if(StringGetCharacter(content, i) != '"') continue;
      //--- count immediate preceding backslashes
      int bs = 0;
      int k  = i - 1;
      while(k >= start && StringGetCharacter(content, k) == '\\') { bs++; k--; }
      if((bs & 1) == 0) { end = i; break; }   // even backslashes → not escape → real terminator
     }
   if(end < 0) return "";
   string raw = StringSubstr(content, start, end - start);
   //--- unescape: \" → ", \\ → \, \n → newline, \r → CR, \t → tab, \uXXXX → char
   string out = "";
   int len = StringLen(raw);
   for(int i = 0; i < len; i++)
     {
      ushort c = StringGetCharacter(raw, i);
      if(c == '\\' && i + 1 < len)
        {
         ushort nx = StringGetCharacter(raw, i + 1);
         if(nx == '"')      { out += "\""; i++; continue; }
         if(nx == '\\')     { out += "\\"; i++; continue; }
         if(nx == 'n')      { out += "\n"; i++; continue; }
         if(nx == 'r')      { out += "\r"; i++; continue; }
         if(nx == 't')      { out += "\t"; i++; continue; }
         if(nx == 'u' && i + 5 < len)
           {
            string hex = StringSubstr(raw, i + 2, 4);
            int code = (int)StringToInteger("0x" + hex);
            out += ShortToString((ushort)code);
            i += 5; continue;
           }
        }
      out += ShortToString(c);
     }
   return out;
  }
```
+ add SelfTest case to StatePersistence (deferred to IMPL-018+ wiring) covering `halt_reason = "x \"y\" z"` round-trip.

**Level of Effort:** Medium (15 LOC + helper-style unescape)

---

### Finding 02.6: 🟡 MEDIUM — `CRiskManager::Init` zeros prior config **before** NULL-logger guard returns → re-init with NULL logger leaves manager half-broken

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh`
- Lines: 95-123 (Init)
- Service: `ea` / services / RiskManager

**Code:**
```mql5
void CRiskManager::Init(double main_risk_ratio,
                        double limit_max_lot_size_ratio,
                        CPortfolioState *port,
                        CLogger *logger)
  {
   //--- Defensive re-init: reset on second call (MT5 input-change re-init)
   m_main_risk_ratio          = 0.0;
   m_limit_max_lot_size_ratio = 0.0;
   m_portfolio                = NULL;
   m_logger                   = NULL;        // ← Step A: zero everything

   //--- NULL-guard logger — cannot use Logger.Error if logger itself is null
   if(logger == NULL)
     {
      Print("[Phoenicis][RiskManager][ev=init_warn] logger is NULL — RiskManager Init aborted");
      return;                                // ← Step B: bail with EVERYTHING zeroed
     }
   ...
  }
```

**Problem:**
`Init` ออกแบบ defensive re-init (MT5 input change ทำให้ Init เรียกซ้ำ). โครงสร้าง:
1. zero everything → 2. validate logger → 3. return if NULL
ลำดับขั้น 1 ก่อน 3 = ถ้า logger NULL ใน re-init call (orchestrator bug or transient), prior valid config (main_risk_ratio + limit_max_lot_size_ratio + portfolio) **ถูก zero ทิ้ง** ทันที. หลัง return, `ComputeLot` calls จะใช้ `base = balance × 0.0 = 0` → ทุก lot = 0 → `ClampLot` floor up to SYMBOL_VOLUME_MIN = 0.01 → orders open at 0.01 lot ทุก slot โดย operator ไม่ทราบ.

ในขณะที่ Logger.Error path ขาดไป (logger NULL) → Print แค่บรรทัดเดียว → operator likely miss in tester log noise.

**Why This Matters:**
- BR-4.1 lot formula bypass — ทุก slot lot = 0 → clamp to floor 0.01
- security.md § Halt + Failure Surfacing — degraded state without Alert
- Re-init scenario rare in production (operator ไม่ค่อย change MT5 input mid-run) แต่ regression-prone ในระหว่าง dev iteration

**Suggested Fix:**
Validate **before** zero (preserve atomic upgrade):
```mql5
void CRiskManager::Init(double main_risk_ratio,
                        double limit_max_lot_size_ratio,
                        CPortfolioState *port,
                        CLogger *logger)
  {
   //--- Validate inputs first — preserve prior state if validation fails
   if(logger == NULL)
     {
      Print("[Phoenicis][RiskManager][ev=init_warn] logger is NULL — RiskManager Init aborted; prior config retained");
      return;
     }

   //--- All inputs valid: atomic upgrade
   m_main_risk_ratio          = main_risk_ratio;
   m_limit_max_lot_size_ratio = limit_max_lot_size_ratio;
   m_portfolio                = port;
   m_logger                   = logger;

   m_logger.Info("RiskManager", "init_ok", 0, ...);
  }
```
Pattern: validate → only then mutate. Mirror BootstrapValidator (round-01 Finding 01.8 acceptance) — guards before mutation.

**Level of Effort:** Low (5 LOC re-order)

---

### Finding 02.7: 🟡 MEDIUM — `CCircuitBreaker::CheckPingPong` unused parameters `port` + `now_ms` accept type but no effect → Code Review Dim #5 + dead code

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`
- Lines: 88-91 (signature) + 173-235 (impl)
- Service: `ea` / services / CircuitBreaker

**Code:**
```mql5
//--- CPortfolioState& parameter reserved for future context enrichment
//    (e.g. per-slot position count in log message); currently unused.
bool CheckPingPong(CPortfolioState &port, datetime now_ms);
...
bool CCircuitBreaker::CheckPingPong(CPortfolioState &port, datetime now_ms)
  {
   int sz = _LogicalSize();
   if(sz < 2) return false;
   //--- port and now_ms never read in body
   ...
  }
```

**Problem:**
ทั้ง `port` (CPortfolioState&) และ `now_ms` (datetime) เป็น parameters ที่ implementation ไม่ได้ใช้. Comment ระบุ "reserved for future context enrichment" — Code Review Dim #5 (Over-Engineering) ห้าม future-design parameter ที่ไม่ active. ขั้นต่ำที่ควรทำ:
- ลบ `port` + `now_ms` ออกจาก signature → caller (Orchestrator IMPL-053) เรียก `m_breaker.CheckPingPong()` no-arg
- เก็บ TD-02 §5.8 verbatim skeleton as comment ถ้าจำเป็น แต่ contract code ต้องสะท้อนสภาพปัจจุบัน

แม้จะไม่ blocking, การพา `CPortfolioState&` ผ่าน method สำคัญ = sneaky coupling: ถ้า future engineer "use it because it's there" → introduces unintended slot↔breaker coupling that ADR-012 forbids. Better to remove until needed; resurrect with explicit doc when it matters.

**Why This Matters:**
- Code Review Dim #5 Over-Engineering — premature parameter
- Header doc lines 91-93 vs body confuse engineers (เห็น signature, เปิดบอดี้, ไม่เจอ usage → debug rabbit hole)
- TD-02 §5.8 specs `bool CheckPingPong(CPortfolioState &port, datetime now_ms)` verbatim — but TD-02 also Path B intent statement (TD review-round-05 Claim 05.1) identifies §5 skeleton ≠ exhaustive contract. Removing unused params is structural polish, not skeleton drift.

**Suggested Fix:**
Option A — drop unused params:
```mql5
bool CheckPingPong();   // no args; uses internal m_buffer state only
```
Caller (Orchestrator IMPL-053) becomes:
```mql5
if(m_breaker.CheckPingPong())
   m_ea_state.SetHalted("ping_pong");
```

Option B — keep signature but mark `[[maybe_unused]]`-equivalent in MQL5 (no native attribute, use comment):
```mql5
//--- port + now_ms reserved for future enrichment (DO NOT remove — TD-02 §5.8 skeleton lock)
bool CheckPingPong(CPortfolioState &port, datetime now_ms);
```
+ assert in body: `(void)port; (void)now_ms;` (suppress compiler warning if any).

Recommendation: Option A. Skeleton skeleton ≠ frozen — round-04 Path B intent is just that.

**Level of Effort:** Low

---

### Finding 02.8: 🟡 MEDIUM — `CRiskManager::_ComputeLotForS` silent fallback to 0.10 when percentTP not in {5,10,15} → masks invalid input

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh`
- Lines: 362-379 (`_ComputeLotForS`)
- Service: `ea` / services / RiskManager

**Code:**
```mql5
double CRiskManager::_ComputeLotForS(double percent_tp)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double factor  = 0.10;   // default

   if(MathAbs(percent_tp - 5.0)  < 0.5) factor = 0.05;
   else if(MathAbs(percent_tp - 10.0) < 0.5) factor = 0.10;
   else if(MathAbs(percent_tp - 15.0) < 0.5) factor = 0.15;
   else
     {
      if(m_logger != NULL)
         m_logger.Warn("RiskManager", "s_pct_tp_fallback", MAGIC_S,
                       StringFormat("percent_tp=%.1f not in {5,10,15} — using 0.10", percent_tp));
     }

   return balance * factor;
  }
```

**Problem:**
- Silent fallback to 0.10 = mid-tier when caller passes invalid percentTP. BR-4.1 row S formula = `balance × percentTP/100`. Caller passing `0` (uninitialized) → factor 0.10 → lot = balance × 0.10 = $100/lot at $1000 balance. Spec violation.
- Tolerance `< 0.5` allows fuzzy match (5.0 vs 5.49 both → 0.05) — for input that should be exact integer enum {5,10,15}, fuzzy admit obscures bugs at caller side
- ขัด round-01 fix philosophy (Finding 01.7 CachedScan): "stub current = silent wrong-result, not controlled fail"

**Why This Matters:**
- IMPL-035 (Slot S) จะ wire `ComputeLot("S", sl, balance, percentTP=Inputs.S_PercentTP)` — if Inputs_Slot_S.mqh fails to set default → 0 → silent 0.10 factor → S lot 2× expected at percentTP=5 setting
- BR-4.1 lock = no fallback default per slot — every formula has explicit factor

**Suggested Fix:**
Reject invalid input (ErrorBypassThrottle + return 0.0):
```mql5
double CRiskManager::_ComputeLotForS(double percent_tp)
  {
   double factor = 0.0;
   if(MathAbs(percent_tp - 5.0)  < 0.001) factor = 0.05;
   else if(MathAbs(percent_tp - 10.0) < 0.001) factor = 0.10;
   else if(MathAbs(percent_tp - 15.0) < 0.001) factor = 0.15;
   else
     {
      if(m_logger != NULL)
         m_logger.ErrorBypassThrottle("RiskManager", "s_pct_tp_invalid", MAGIC_S,
                                      StringFormat("percent_tp=%.4f not in {5,10,15}; "
                                                   "S lot = 0.0 (no order)", percent_tp));
      return 0.0;   // fail-loud, not silent-wrong
     }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   return balance * factor;
  }
```
+ tighten tolerance from `< 0.5` to `< 0.001` (input ought to be integer enum).

**Level of Effort:** Low

---

### Finding 02.9: 🔵 LOW — `CCircuitBreaker::CloseEvent.close_time_ms` field name implies milliseconds, stored as datetime (seconds) → contract drift

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`
- Lines: 18-29 (header rationalization) + 48-53 (struct) + 70 + 91 (signatures)
- Service: `ea` / services / CircuitBreaker

**Code:**
```mql5
//--- (header note lines 18-29 acknowledges the gap)
//|  The "ms" suffix in the skeleton parameter name (now_ms) is shorthand inherited
//|  from the TD-02 §5.8 spec — actual storage is seconds floor.

struct CloseEvent
  {
   int      magic;
   int      direction;
   datetime close_time_ms;  // seconds-precision (see datetime note above)
  };

void RecordOpen(int magic, int direction, datetime now_ms);
bool CheckPingPong(CPortfolioState &port, datetime now_ms);
```

**Problem:**
Engineer flagged the contract drift in header comment but didn't rename. Future maintainers (or even adversarial Red Team in Phase 4 HARDEN) reading `close_time_ms` will assume millisecond stored — most defects of Finding 02.2 trace to this field naming. Fix Finding 02.2 (microsecond upgrade) → rename to `close_time_us`. Fix Finding 02.2 (cheap fallback / second-precision retain) → rename to `close_time_s`.

**Why This Matters:**
- Code Review Dim #9 TD Compliance — TD-02 §5.8 verbatim "close_time_ms" but field semantic ≠ name
- Adjacent Finding 02.2 would fix this incidentally — flagged separately for clarity in case 02.2 takes Option B (cheap rename) and inadvertently leaves field name stale

**Suggested Fix:**
Tied to Finding 02.2 fix path. If Option A (microsecond upgrade): `close_time_ms` → `close_time_us`. If Option B (rename const + retain seconds): `close_time_ms` → `close_time_s` + `now_ms` → `now_s`.

**Level of Effort:** Low (rename — folded into 02.2)

---

### Finding 02.10: 🔵 LOW — `CTimeGate::HolidayBlock` returns `true` (block) when `GetByMagic(200) == NULL` — fail-safe is too aggressive

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TimeGate.mqh`
- Lines: 289-306 (HolidayBlock)
- Service: `ea` / services / TimeGate

**Code:**
```mql5
bool CTimeGate::HolidayBlock(datetime server_now, CPortfolioState &port) const
  {
   if(!IsNewYearSeason2(server_now))
      return false;

   //--- CD-count gate per BR-3.3: block new entries only when CD positions active
   //    CD pool uses MagicCD = 200 (per domain glossary CLAUDE.md §7b)
   SlotState *cd_state = port.GetByMagic(200);
   if(cd_state == NULL)
     {
      //--- GetByMagic logs warn for unregistered magic; treat as no positions
      return true;   // ← holiday active, assume block (safe default)
     }

   int cd_total = cd_state.buy_count + cd_state.sell_count;
   return (cd_total > 0);
  }
```

**Problem:**
BR-3.3 spec: holiday season + **CD has open positions** → block new. ถ้า CD slot ไม่ register (RegisterAll bug or pre-Init call) → `GetByMagic(200)` return NULL. Code comment says "treat as no positions" — แต่ `return true` = block ทุกอย่าง = treat as **lots of positions**. Contradicts comment + over-blocks during entire holiday window when slot bookkeeping is broken.

Counter-argument: holiday season + missing slot data = unsafe → block is safer. Defensible. **But:** logging level is silent (only `GetByMagic` Warn — sub-spec) and operator sees "no entries during Dec 21 - Jan 3" without know why. ถ้า CD bookkeeping broken = bigger problem ที่ should HALT, not silently extend block.

**Why This Matters:**
- Comment says one thing ("treat as no positions") + code does another (return true = block) → maintainer rabbit hole
- BR-3.3 spec wants explicit positions-active gate; over-block is functional drift toward stricter behavior
- NFR-1.1 behavioral parity: legacy EA likely returns false (allow) when CD count = 0 — over-block during full Dec 21 - Jan 3 window = visible behavior drift

**Suggested Fix:**
Pick a discipline + match comment to code:
```mql5
SlotState *cd_state = port.GetByMagic(200);
if(cd_state == NULL)
  {
   //--- Fail-loud: CD bookkeeping missing during holiday is a precondition violation.
   //    Default to "no positions" (allow) per BR-3.3 spec literal, but emit Error.
   if(m_logger != NULL)
      m_logger.Error("TimeGate", "holiday_cd_state_null", 200,
                     "CD slot not registered during HolidayBlock check; treating as 0 positions");
   return false;
  }
```
+ add SelfTest case (deferred to IMPL-018+) covering CD-NULL path.

**Level of Effort:** Low

---

## Cross-Service Issues

| Issue | Files | Finding |
|-------|-------|---------|
| State save/load round-trip contract: `WriteRaw` vs `_ExtractStr` mismatch | `services/StatePersistence.mqh` lines 420-423 ↔ 622 ↔ 706-716 | 02.1 |
| BR-3.6 spec millisecond ↔ implementation second drift | `docs/ba/04-business-rules.md` § BR-3.6 ↔ `services/CircuitBreaker.mqh` lines 62-63 | 02.2 |
| RiskManager parent-lot read uses `total_lots` aggregate ↔ ADR-009 + CodeWiki §4.1 row J/I/BI intent (last_open_lot) ↔ `domain/SlotState.mqh` missing field | `services/RiskManager.mqh` lines 268-349 ↔ `domain/SlotState.mqh` lines 29-42 ↔ ADR-009 | 02.3 |
| JSON-string escape contract: JsonWriter escapes (post Finding 01.9) ↔ StatePersistence does not unescape | `helpers/JsonWriter.mqh` lines 63-76 (escapes) ↔ `services/StatePersistence.mqh` `_ExtractStr` | 02.5 |
| TD-02 §5.8 skeleton signature drift (port + now_ms unused after Path B intent statement) | `services/CircuitBreaker.mqh` lines 88-91 ↔ TD-02 §5.8 verbatim ↔ TD round-05 Path B | 02.7 |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 02.1 | 🔴 CRITICAL | 6 Cross-Service Consistency | StatePersistence pending_payload round-trip broken (WriteRaw ↔ _ExtractStr) | StatePersistence.mqh:420-423/622/706-716 | Low |
| 02.2 | 🔴 CRITICAL | 2 Business Logic | CircuitBreaker BR-3.6 threshold 1000× off (3000s vs 3000ms) | CircuitBreaker.mqh:62-63/173-235 | Low/Medium |
| 02.3 | 🟠 HIGH | 2 Business Logic / 9 TD Compliance | RiskManager J/BI/I uses `total_lots` aggregate ≠ last_open_lot intent | RiskManager.mqh:268-349 + SlotState.mqh:29-42 | Medium |
| 02.4 | 🟠 HIGH | 3 Error Handling | PortfolioMonitor.Update logs Error every tick on NULL state (anti-spam violation) | PortfolioMonitor.mqh:124-180 | Low |
| 02.5 | 🟠 HIGH | 6 Cross-Service Consistency | StatePersistence._ExtractStr no JSON-string unescape → halt_reason corruption | StatePersistence.mqh:706-716 | Medium |
| 02.6 | 🟡 MEDIUM | 3 Error Handling | RiskManager.Init zeros prior config before NULL-guard return | RiskManager.mqh:95-123 | Low |
| 02.7 | 🟡 MEDIUM | 5 Over-Engineering | CircuitBreaker.CheckPingPong unused params `port` + `now_ms` | CircuitBreaker.mqh:88-91/173-235 | Low |
| 02.8 | 🟡 MEDIUM | 2 Business Logic | RiskManager._ComputeLotForS silent fallback 0.10 masks invalid percentTP | RiskManager.mqh:362-379 | Low |
| 02.9 | 🔵 LOW | 9 TD Compliance | CircuitBreaker `close_time_ms` field name implies ms, stores datetime seconds | CircuitBreaker.mqh:48-53/70/91 | Low |
| 02.10 | 🔵 LOW | 2 Business Logic / 3 Error Handling | TimeGate.HolidayBlock comment-vs-code contradiction on NULL CD path | TimeGate.mqh:289-306 | Low |

---

## Recommendation

**Verdict:** ❌ **Not Ready for P2 Phase Gate** — 2 CRITICAL findings (02.1 + 02.2) เป็น contract violations ที่จะ block G3/G4 gate ตอน entry .mq5 + IMPL-049 (PendingMachineRegistry consumer) land.

**Top priority fixes:**
1. **02.1** (30-45 min): StatePersistence pending_payload round-trip — adds `_ExtractRawValue` helper + parser dispatch + round-trip SelfTest. **Blocks IMPL-049 entire pending machine registry**: post-reboot payload "" → state machine corrupt resume.
2. **02.2** (30-60 min): CircuitBreaker threshold semantic — choose Option A (microsecond upgrade) or Option B (rename const + value to 3 seconds). **Blocks NFR-1.1 behavioral parity** + BR-3.6 spec compliance.
3. **02.3** (45-90 min): RiskManager parent-lot field — add `last_open_lot` to SlotState + populate at PortfolioState.Refresh + update 3 helpers. **Blocks NFR-1.1 Bucket A drift ≤ 25% target** for any pyramid scenario (J/BI/I across 5-yr backtest).

Bundle plan for `/impl-review-fix`:
- **G1 (CRITICAL bundle):** 02.1 + 02.2 — both blocking; commit together as `[fix:ea] code-review-02 bundle 1`
- **G2 (HIGH bundle):** 02.3 + 02.4 + 02.5 — separate commits per fix per round-01 fix-round precedent
- **G3 (MEDIUM bundle):** 02.6 + 02.7 + 02.8 — single commit `[refactor:ea] code-review-02 polish bundle`
- **G4 (LOW bundle):** 02.9 (folded into 02.2) + 02.10 — single commit

**Anti-regression check (pre-fix-round prereq):** rerun round-01 grep after fixes land:
- `grep -nE "iCustom\(.*\"ZigZag\"" services/IndicatorService.mqh` = 0 hits (round-01 Finding 01.2)
- `grep -n "Logger.Error.*invalid_handle" services/IndicatorService.mqh` = 0 hits (Finding 01.4 — should be ErrorBypassThrottle)
- ตรวจว่า `CleanupPartialInit` ไม่หายจาก IndicatorService partial-failure path (Finding 01.1)

**Empirical verification deferral**: ทุก E-AC ของ P2 IMPL-040/045/047/050/051 ปัจจุบัน `[ ]` deferred to IMPL-018+ orchestrator wiring (per header-only precedent). Fixes ของรอบนี้ structurally sound + SelfTest-guarded; runtime verification gated by entry .mq5 — ตรง round-01 conclusion. Add round-trip SelfTest case ของ Finding 02.1 (StatePersistence) ก่อน IMPL-018 land = early-warn surface สำหรับ payload contract.
