# IMPL-050 Evidence — TimeGate.mqh — 2026-05-03

## Summary

Implemented `MQL5/Experts/PhoenicisNex/services/TimeGate.mqh` per TD-02 §5.9 skeleton.
Created `simulation/headless-tests/timegate_smoke.ini` for DST smoke test.

---

## 1. Skeleton Compliance

| Method | TD-02 §5.9 signature | Implemented | Notes |
|--------|----------------------|-------------|-------|
| `Init(...)` | 13 params + 3 dep pointers | ✅ Line 65–79 | Exact signature match |
| `IsMorningWakeup(datetime)` | const | ✅ Line 82 | BR-3.1 |
| `IsMondaySpreadHigh(datetime, int)` | const | ✅ Line 86 | BR-3.2/BR-3.7 |
| `IsNewYearSeason2(datetime)` | const | ✅ Line 90 | BR-3.3 |
| `HolidayBlock(datetime, CPortfolioState&)` | const | ✅ Line 94 | BR-3.3 + CD-count gate |
| `IsBanned(string, datetime)` | const | ✅ Line 98 | BR-3.4 |
| `SetBan(string, datetime)` | void | ✅ Line 103 | BR-3.4 |
| `IsBanAllowedSlot(string)` | private const | ✅ Line 58 | Claim 01.18 allowlist inline |

**Method count:** 7 public + 3 private (`IsBanAllowedSlot`, `_BanFieldForSlot`, `_CooldownSecondsForSlot`) = 10 total. Skeleton defines 7 public — 3 private helpers added for implementation clarity (not skeleton violations).

**Private member vars (skeleton exact):**
- `m_morning_window_minutes`, `m_monday_spread_threshold`, `m_holiday_start_month/day`, `m_holiday_end_month/day` ✅
- `m_ban_c_cooldown_bars`, `m_ban_l_cooldown_bars`, `m_ban_m_cooldown_bars`, `m_k_last_order_cooldown_bars`, `m_g_pause_cooldown_bars` ✅
- `m_pip`, `m_state`, `m_logger` ✅ (pointer deps)

---

## 2. Allowlist Enforcement Evidence

**Allowlist guard appears in two places (Claim 01.18):**

`IsBanned` — line cite: `if(!IsBanAllowedSlot(slot_id))` with `m_logger.Error("TimeGate","ban_unknown_slot",...)` + `return false`

`SetBan` — line cite: `if(!IsBanAllowedSlot(slot_id))` with `m_logger.Error("TimeGate","ban_unknown_slot",...)` + early return (no state write)

`IsBanAllowedSlot` private guard (line ~58):
```mql5
return slot_id == "C" || slot_id == "L" || slot_id == "M" ||
       slot_id == "K" || slot_id == "G";
```

Unknown slots receive `ban_unknown_slot` error log — not silently ignored per NFR-3.4.

---

## 3. DST Handling Note

DST handling comment block at file header (lines 13–20 of TimeGate.mqh):

```
// DST handling:
//   All time checks use TimeCurrent() which returns broker server
//   time (EET = GMT+2 winter / GMT+3 summer DST).
//   Relying on broker-native server time means DST transitions
//   (last Sunday March → +1h; last Sunday October → -1h) are
//   transparent: FR-6.5 + NFR-7.3. DO NOT call TimeGMT() /
//   TimeLocal() — those strip broker DST context.
//   DST transition example: 2021-03-28 00:00 GMT+2 → 03:00 GMT+3
//   TimeCurrent() reflects this natively; no manual offset needed.
```

All time methods (`IsMorningWakeup`, `IsMondaySpreadHigh`, `IsNewYearSeason2`, `HolidayBlock`) receive `datetime server_now` from caller, which is `TimeCurrent()` in the Orchestrator tick handler. No `TimeGMT()` or `TimeLocal()` calls in the implementation.

---

## 4. G1 Result

**PhoenicisNex.mq5 does not yet exist** — only spike files are present in `MQL5/Experts/PhoenicisNex/spike/`. G1 on the main entry point is deferred to the first consumer (Orchestrator at IMPL-014+), per IMPL-005/007/011 precedent documented in shared context.

**No-regression proxy G1:** Compiled `spike/Spike_StatePersistence.mq5` which transitively includes `services/StatePersistence.mqh` → `services/PortfolioState.mqh` → `services/Logger.mqh` → `helpers/AtomicFile.mqh` → `helpers/PipMath.mqh` (full services layer except TimeGate). Result: **0 errors, 0 warnings** (metaeditor.log entry confirms).

`TimeGate.mqh` is not yet included by any consumer — G1 on `TimeGate.mqh` itself deferred. Evidence artifact: `spike/Spike_StatePersistence.compile.log` — `Result: 0 errors, 0 warnings, 1331 ms elapsed`

**Filtered iteration count:** 1 successful proxy G1 run (3 MetaEditor invocations total; 2 were path-resolution debugging attempts).

---

## 5. SetBan — StatePersistence API Used

`SetBan` calls `m_state.SetBanDate(ban_field, ban_end)` where `ban_field` is one of `{"ban_c","ban_l","ban_m","k_last_order","g_pause"}`. This matches `CStatePersistence::SetBanDate(string ban_field, datetime ts)` public API at `StatePersistence.mqh` lines 358–365. No missing accessor — not blocked.

The in-memory state update is persisted on the next `Save()` call (ADR-007 Option A flow). This is documented in the `SetBan` implementation comment.

---

## 6. S-AC + E-AC Pass/Fail Table

| AC | Type | Status | Notes |
|----|------|--------|-------|
| 5 methods per TD-02 §5.9 skeleton | S-AC 1 | ✅ Pass | All 7 public methods + Init implemented; signatures exact |
| Ban cooldown cycle per slot allowlist {C,L,M,K,G} | S-AC 1 | ✅ Pass | `IsBanAllowedSlot` guards both `IsBanned` and `SetBan` |
| DST-aware: Mar 28 / Oct 25 transitions handled | S-AC 2 | ✅ Pass (structural) | `TimeCurrent()` used exclusively; broker EET native |
| Smoke: DST start/end → no off-by-1-hour bug `[log-assertion]` | E-AC 1 | ⚠️ Deferred | G3 headless backtest deferred — PhoenicisNex.mq5 entry does not exist yet; `timegate_smoke.ini` created and committed for when Orchestrator wires TimeGate. Registered in deferred-AC registry per project convention |
| state.json `bans` sub-object updates after ban `[db-inspect]` | E-AC 2 | ⚠️ Deferred | Same reason as E-AC 1 — no orchestrator wiring yet; `SetBanDate` path verified structurally via `StatePersistence.mqh` API review |

**Deferred E-ACs:** Both E-ACs require orchestrator wiring (PhoenicisNex.mq5 + Orchestrator.mqh instantiating CTimeGate). Per shared context precedent (IMPL-005/007/011), header-only `.mqh` G3/G4 deferral is acceptable when entry point does not exist. `timegate_smoke.ini` artifact created for reproducible replay when wiring is complete.

---

## 7. Files Changed

| File | Status | Description |
|------|--------|-------------|
| `MQL5/Experts/PhoenicisNex/services/TimeGate.mqh` | NEW | Full CTimeGate implementation, ~230 LOC |
| `simulation/headless-tests/timegate_smoke.ini` | NEW | DST smoke window 2026-Mar-26..Mar-30 |
| `docs/state/_session-handoff/IMPL-050-evidence-20260503.md` | NEW | This file |
