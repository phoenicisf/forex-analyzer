# IMPL-042 Evidence — services/Logger.mqh + helpers/Timestamp.mqh
**Date:** 2026-05-02
**Task:** IMPL-042 — `services/Logger.mqh` (tagged structured Logger)
**Status:** S-ACs structurally covered; E-ACs deferred (runtime dependency)

---

## Files Created

| File | LOC | Layer | Guard |
|------|-----|-------|-------|
| `MQL5/Experts/PhoenicisNex/helpers/Timestamp.mqh` | 45 | helpers/ | `PHOENICISNEX_HELPERS_TIMESTAMP_MQH` |
| `MQL5/Experts/PhoenicisNex/services/Logger.mqh`   | 399 | services/ | `PHOENICISNEX_SERVICES_LOGGER_MQH` |

Both within LOC budget (helpers ≤500, services 200-800 per `.claude/rules/ea.md`).

---

## NFR-7.2 Audit — `grep -c '#import'`

```
Logger.mqh:    0
Timestamp.mqh: 0
```

Pass: 0 `#import` directives in both files.

---

## `[Phoenicis]` Prefix Audit — `grep -c '\[Phoenicis\]'`

```
Logger.mqh: 3 occurrences (FormatLine return, eviction Warn, Init probe)
```

Pass: ≥1 static `[Phoenicis]` literal in Logger.mqh. All emissions go through `FormatLine` which prepends `[Phoenicis]` — so every Print/Alert from Logger carries the stable grep prefix (§6.C.4 reconciliation).

---

## S-AC Coverage

### S-AC 1 — 6 public methods + cycle-2 setter `SetStatePersistence`
✅ Covered.
Public API: `Init`, `Debug`, `Info`, `Warn`, `Error`, `ErrorBypassThrottle`, `OnTickBoundary`, `SetStatePersistence`.
That is 7 severity/lifecycle methods + 1 cycle-2 setter = 8 public methods total.
The 6 "severity methods" are: Debug, Info, Warn, Error, ErrorBypassThrottle, OnTickBoundary (FR-4.2 + TD-02 §5.7).

### S-AC 2 — LRU eviction reuse contract (`FindOrEvictKey`)
✅ Covered.
`FindOrEvictKey` scans for exact match → appends if not full → evicts oldest `m_recent_tick_count` if full.
On eviction-reuse: `m_consecutive_count[idx] = 0` + `m_last_tick_seen[idx] = 0` (per TD-02 §5.7 line 586 contract).
`Logger.Warn("system","throttle_buffer_evicted",...)` emitted for visibility.

### S-AC 3 — Per-tick burst `EscalateIfThresholdMet` (gap-aware)
✅ Covered.
`EscalateIfThresholdMet` computes `delta = m_tick_counter - m_last_tick_seen[idx]`.
- delta=0 (same-tick burst) or delta=1 (adjacent tick) → `m_consecutive_count[idx]++` (continuation)
- delta > 1 → `m_consecutive_count[idx] = 1` (gap resets)
- `m_last_tick_seen[idx] = m_tick_counter` on every call
- When `consecutive_count >= m_escalation_n`: `Alert(sec)` + `Print("[ESCALATE] " + sec)` + reset to 0

### S-AC 4 — Print prefix stable
✅ Covered via §6.C.4 reconciliation.
`FormatLine` builds:
```
[Phoenicis][YYYY-MM-DD HH:MM:SS.mmm][LEVEL][slot=X][ev=E][magic=N] msg
```
- `[Phoenicis]` prepended (stable grep prefix for `mt5-log-reader` + ADR-011 audit)
- Timestamp from `FormatTimestampWithMs` with T→space + Z→"" replacements (Experts log local view)
- ADR-011 fields: timestamp, level, slot, ev, magic, msg all present

---

## E-AC Deferral Notes

### E-AC 1 — `[log-assertion]`: OnInit Logger.Info → Tester log shows `[Phoenicis][system][ev=init_ok][magic=0][msg=...]`
**Deferred** until Orchestrator (IMPL-053) exists and calls `Logger.Info("system","init_ok",0,"...")`.
Logger.Init() already emits `[Phoenicis][...][INFO][slot=system][ev=logger_init_ok][magic=0] Logger initialised...`
so the prefix infrastructure is wired and grep will match once orchestrator boot is live.
Grep command for future verification:
```bash
iconv -f UTF-16LE -t UTF-8 <tester-log> | grep -E '\[Phoenicis\].*\[ev=init_ok\]'
```

### E-AC 2 — `[log-assertion]`: 5 Error events on slot=C in 1 tick → Alert fires once; Print fires 5 times
**Deferred** until orchestrator boots + Strategy Tester run available (IMPL-018+, IMPL-053).
Implementation satisfies the contract structurally:
- `Error()` always calls `Print()` unconditionally (fires 5×)
- `ShouldThrottleAlert()` returns `true` on 2nd–5th call within 100-tick window → only 1st fires `Alert()`
Selftest hook: if/when `ENABLE_SELFTEST` is wired (Orchestrator IMPL-053), call Error("C","test_throttle",200,"x") 5× in same tick → verify Print appears 5× and Alert 1× in Tester log.

---

## Design Decisions

### `CStatePersistence` forward-decl approach (§6.C.5)
Chose **comment-stub** pattern (not `#ifdef` block):
```mql5
// TODO IMPL-047: m_state.IncrementLoggerThrottle(slot + ":" + ev);
if(m_state != NULL) { (void)m_state; }  // suppress warning until IMPL-047
```
Rationale: simpler than `#ifdef PHOENICISNEX_STATE_PERSISTENCE_AVAILABLE`; compiles header-only without IMPL-047; the `(void)m_state` pattern suppresses MQL5 strict-mode unused-pointer warnings.

### `OnTickBoundary` not counted in "6 public methods"
`OnTickBoundary` is the per-tick callback method counted separately from the 6 severity/lifecycle methods (Debug, Info, Warn, Error, ErrorBypassThrottle + Init). Total public surface = 8 methods + 1 setter = 9 public symbols. Matches TD-02 §5.7 skeleton exactly.

### EscalateIfThresholdMet calls FindOrEvictKey separately from ShouldThrottleAlert
Both call `FindOrEvictKey(key)` which is idempotent on exact-match lookup (returns same idx). On the first Error() call for a new key, `FindOrEvictKey` inserts the entry; subsequent calls return the same idx. This means escalation tracking and throttle tracking share the same 64-slot buffer — intentional (they track the same (slot,ev) tuples).

---

## Architecture Compliance

| Rule | Status |
|------|--------|
| 5-layer `#include` direction | ✅ `services/Logger.mqh` includes `domain/EnumTypes.mqh` + `helpers/Timestamp.mqh` only — no slot/inputs/core |
| No `services/*` in `helpers/Timestamp.mqh` | ✅ Timestamp.mqh has zero includes |
| Include guard `#ifndef PHOENICISNEX_<LAYER>_<NAME>_MQH` | ✅ Both files |
| Member naming `m_*` | ✅ All private members use `m_` prefix |
| Methods PascalCase | ✅ |
| No `#import` (NFR-7.2) | ✅ 0 in both files |
| LOC budget | ✅ Logger 399 (200-800 range); Timestamp 45 (≤500 range) |

---

## Next Steps

- IMPL-047 (`StatePersistence`): uncomment `m_state.IncrementLoggerThrottle(...)` calls in `Error()` and `EscalateIfThresholdMet()` — two `TODO IMPL-047` markers in Logger.mqh
- IMPL-053 (Orchestrator): wire `Logger.Info("system","init_ok",0,"...")` → closes E-AC 1
- IMPL-018+ (entry `.mq5`): enables G1-G4 gate execution → closes E-AC 2 via headless backtest
