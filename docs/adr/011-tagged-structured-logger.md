# ADR-011 — Tagged Structured Logger Pattern

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G2, FR-4.2, NFR-3.4, NFR-5.1 |

## Context

EA เดิมใช้ bare `Print()` กระจายโค้ด — ไม่มี tag → grep log ตอน retrospective ใช้ไม่ได้ (CodeWiki §6.2 P2.5). FR-4.2 ต้องการ tagged logger: `[slot=X][ev=...][magic=...]`. Trade journal (FR-4.1) คือ subset specialized ของ log foundation นี้

Logger มี responsibilities หลัก:
1. **Tag enforcement** — ทุก log message มี slot/event/magic tag
2. **Severity routing** — DEBUG/INFO/WARN/ERROR; ERROR + `Alert()` ตาม NFR-5.1
3. **Sink** — MT5 native Experts log ผ่าน `Print()`; optional file sink (Phase 2)
4. **Anti-spam** — repeating ERROR ใน window N → throttle Alert
5. **Performance** — ≤ 0.1 ms/log message (ไม่ช้า OnTick)

## Options Considered

### Option A — Class-based logger with severity methods (chosen)

```mql5
class CLogger {
public:
   void Debug(string slot, string event, int magic, string msg);
   void Info(string slot, string event, int magic, string msg);
   void Warn(string slot, string event, int magic, string msg);
   void Error(string slot, string event, int magic, string msg);  // also calls Alert + journal halt
};
```

Format: `[2026-03-15 14:23:45.123][WARN][slot=BI][ev=lot_clamped][magic=214] lot 5.2 > cap 2.9 — clamped`

### Option B — Free function `LogTagged(...)` ทุกที่

**Rejected:** Free function = global state coupling; ขัด ADR-002 constructor injection discipline

### Option C — Macro-based `#define LOG_INFO(slot, ev, msg)`

**Rejected:** MQL5 preprocessor limited; macro debugging painful + ไม่ type-safe

## Decision

เลือก **Option A — `CLogger` class** ที่ inject ผ่าน constructor (เหมือน IndicatorService, TradeJournal)

**Concrete contract:**

| Field | Value |
|-------|-------|
| **Class** | `CLogger` ใน `services/Logger.mqh` |
| **Methods** | `Debug/Info/Warn/Error(string slot, string event, int magic, string msg)` |
| **Format** | `[YYYY-MM-DD HH:MM:SS.ms][LEVEL][slot=<X>][ev=<eventName>][magic=<N>] <msg>` |
| **Sink (Phase 1)** | MT5 `Print()` only (= MT5 Experts log tab); optional second sink to file = Phase 2 |
| **Severity behavior** | DEBUG: skipped if `InpLogLevel < DEBUG` (default = INFO); INFO/WARN: Print only; ERROR: Print + `Alert()` (with throttle) |
| **Throttle** | ERROR + same `(slot, event)` tuple ภายใน 100 ticks → suppress Alert (still Print); reset ทุก 100 ticks. **Distinct `(slot, event)` tuples throttle independently** — เช่น `(system, journal_write_fail)` กับ `(system, handle_invalid_runtime)` มี throttle counters แยก → ไม่ block Alert ของ event ใหม่ |
| **Halt-trigger bypass** | Errors ที่ trigger `EAState.Halt()` (Phase 1 sole trigger source post-BT-002 2026-05-17: IndicatorService runtime invalid; Phase 2 candidates per ADR-010 Revisit-when: journal sustained-failure, force-clear escalation, equity-floor) → **never throttle Alert**. ทุก halt event = guaranteed Alert popup (NFR-5.1 + ADR-010 amended-BT-002 contract). CircuitBreaker trigger removed per BT-002 (legacy-parity). |
| **Escalation policy** | Same `(slot, event)` ERROR ≥ N consecutive ticks (default N=10, configurable `InpErrorEscalationN`) → upgrade severity: emit secondary Alert พร้อม message *"Sustained error: <slot>/<event> × N — investigate"* + persist `(slot,event)` ใน `logger_metrics.last_throttle_event` (ดู `state-persistence-schema.yaml`) |
| **Throttled counter** | `logger_metrics.throttled_alert_count` increment ทุก suppressed Alert; **cumulative survives restart** via state.json (atomic per ADR-007); reset only via manual delete state.json. Surface ใน HALTED_STABLE Alert message (e.g., *"halted_stable + 47 throttled alerts cumulative — check Experts log"*) → user transparent ว่ามี Alert ถูก suppress รวม cross-restart pattern (NFR-3.4 visibility) |
| **Globals** | none — instance per orchestrator (constructor-injected) |

**Configuration via input:**
```mql5
input ENUM_LOG_LEVEL InpLogLevel = LOG_INFO;   // DEBUG|INFO|WARN|ERROR
input bool InpAlertOnError = true;
```

**Integration with TradeJournal (FR-4.1):**
- `TradeJournal::WriteEvent()` ภายในเรียก `Logger::Info(slot, event, magic, summary)` — log + journal เกิดพร้อมกัน
- ตอน journal write fail → `Logger::Error(...)` (NFR-3.4 no silent failure) — anti-spam throttle จับ

**Integration with halt (FR-7.7 + ADR-010 amended BT-002 2026-05-17):**
- `core/Orchestrator` (on `IndicatorService::AnyHandleInvalid()` → `EAState.Halt("handle_invalid_runtime")`) เรียก `Logger::Error("system", "halt", 0, reason)` → triggers Alert + journal halt. (Former `CircuitBreaker::Halt(reason)` call site removed per BT-002 — see ADR-010 § Revision history.)
- HALTED_STABLE transition → `Logger::Info("system", "halt_stable", 0, "all positions closed")` + Alert (separate from Error throttle)

**Performance budget:**
- Per Print(): ~50-100 µs MT5 native; tag string construction ~10 µs → total ~110 µs/log
- OnTick log volume estimate: 5-10 messages/tick (slot evaluate result + portfolio refresh + journal events) → ~1 ms/tick
- ภายใน NFR-2.1 budget (10% of original tick latency)

## Consequences

**Positive**
- Searchable log: `grep "slot=BI" mt5_experts.log` → BI events เท่านั้น
- Severity routing centralized — Alert behavior testable
- Anti-spam throttle ป้องกัน Alert popup overflow
- Foundation สำหรับ FR-4.1 journal (consistent tagging)

**Negative / trade-off**
- Tag string construction overhead per log (10 µs) — small but multiply by 21 slots = บัง budget
- ERROR + Alert throttle อาจ suppress real consecutive errors of **same (slot,event) tuple** ภายใน 100-tick window → mitigated โดย: (1) distinct events throttle independently (ไม่ block Alert ของ event อื่น), (2) halt-trigger errors never throttle Alert (ดู § Decision § Halt-trigger bypass), (3) escalation policy ที่ ≥ N consecutive (NFR-3.4 ขัด strict reading "0 silent failures" — แต่ user transparent ผ่าน `throttled_alert_count` counter ที่ surface ใน HALTED_STABLE Alert + Print ยัง emit ทุก tick + journal record ทุกครั้ง)
- MT5 Experts log rolls over ที่ ~ 1 MB → live ปีละ ~2-3 MB log overflow; mitigated โดย user manage MT5 log (out of scope)

## Revisit-when

- ถ้า Phase 2 ต้องการ separate log file → add file sink (extend `CLogger` ไม่ modify caller)
- ถ้า measured log overhead > 5% tick latency → reduce log verbosity ของ DEBUG/INFO + introduce sampling
- ถ้า Alert throttle suppress critical event → expose throttle window ผ่าน input
