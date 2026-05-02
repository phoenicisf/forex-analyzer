# IMPL-047 — StatePersistence Save/Load Evidence (Evolution E1a)

**Date:** 2026-05-03
**Owner:** Kritsana (Impl Engineer)
**Verdict:** ✅ **ALL_PASS** — `CStatePersistence` Save/Load per ADR-007 Option A implemented and validated; 5/5 E-AC checks green.
**Branch context:** `main` commit `f9c2321`

## 1. Implementation summary

| Component | File | Notes |
|-----------|------|-------|
| `CStatePersistence` class | `services/StatePersistence.mqh` | Full 35-field JSON schema; atomic save via `CAtomicFile::WriteAtomic`; `Load` + `TryRecoverFromGV` |
| Logger wiring | `services/Logger.mqh` | `_SyncThrottle` deferred bridge; body defined in `StatePersistence.mqh` |
| Compile fixes | `domain/SlotState.mqh`, `services/PortfolioState.mqh` | `struct→class` (error 299); switch int literals (error 188); drop `const` (error 279) |
| Spike EA | `spike/Spike_StatePersistence.mq5` | 5-check OnInit spike; returns `INIT_FAILED` to terminate tester |
| Tester config | `simulation/headless-tests/state_persistence_smoke.ini` | FBS-Real EURUSD H4 2021-01-04→2021-01-05 |

## 2. G1 Compile

**Compiler:** `C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe`
**Target:** `MQL5/Experts/PhoenicisNex/spike/Spike_StatePersistence.mq5`
**Result:** `0 errors, 0 warnings, 1331 ms elapsed, cpu='X64 Regular'`
**Log:** `spike/Spike_StatePersistence.compile.log`

## 3. G3/G4 Headless backtest + log review

**Terminal:** `C:\Program Files\FBS MetaTrader 5ph\terminal64.exe`
**Config:** `simulation/headless-tests/state_persistence_smoke.ini`
**Tester log:** `Tester/logs/20260503.log` (terminal `A12EC900AF5AF5023ECB36F7FB72E396`)

### Spike output (Core 01 log lines)

| Check | Event | Result |
|-------|-------|--------|
| A — boot-cold | `[ev=check_a_pass] boot-cold defaults ok` | ✅ |
| B — contract-roundtrip | `[ev=check_b_pass] roundtrip ok tag=iter=99` | ✅ |
| C — db-inspect | `[ev=check_c_pass] slot_states key_count=17 ok` | ✅ |
| D — kill-resilience | `[ev=check_d_pass] kill-resilience ok tmp_gone=true` | ✅ |
| E — GV sync | `[ev=check_e_pass] GV keys present ok` | ✅ |

**Final verdict line:**
```
[Phoenicis][spike][ev=impl047_complete][verdict=ALL_PASS][pass=5][fail=0] IMPL-047 E-AC spike done
```

## 4. Pre-existing compile fixes (not in IMPL-047 scope but required for compilation)

Three pre-existing bugs in `PortfolioState.mqh` / `SlotState.mqh` were blocking G1:

| Error | Root cause | Fix |
|-------|-----------|-----|
| error 188 (17×) | `static const int MAGIC_*` used as switch-case labels — not compile-time constants in MQL5 | Replaced with integer literals (200, 201, 205…) |
| error 143/252 (3×) | `(void)expr` cast not valid in MQL5 | Removed `(void)` suppression lines in `GetTicketsForSlot` stub |
| error 279 (2×) | `TotalActivePositions()` + `TotalFloatingPL()` declared `const` but call non-const `CHashMap::TryGetValue` | Removed `const` qualifier from both method declarations and definitions |
| error 299 | `SlotState` declared as `struct` — MQL5 `CHashMap<int,SlotState*>` requires class types | Changed `struct SlotState` → `class SlotState { public: ... }` |
