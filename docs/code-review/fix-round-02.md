# Code Review Fix Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Review File** | `docs/code-review/review-round-02.md` |
| **Date** | 2026-05-03 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |
| **Scope** | 5 source files in `MQL5/Experts/PhoenicisNex/` (StatePersistence, CircuitBreaker, RiskManager, PortfolioMonitor, TimeGate) + 1 domain file (SlotState) + 1 cascaded service (PortfolioState) |
| **Cumulative LOC delta** | +293 / −83 across 7 files |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 02.1 | StatePersistence pending_payload round-trip broken | 🔴 CRITICAL | Accept | 0 | `97d7c24` (G1) |
| 02.2 | CircuitBreaker BR-3.6 threshold 1000× off | 🔴 CRITICAL | Accept | 0 | `97d7c24` (G1) |
| 02.3 | RiskManager J/BI/I uses `total_lots` aggregate | 🟠 HIGH | Accept | 2 (SlotState + PortfolioState) | `6b23ddf` |
| 02.4 | PortfolioMonitor.Update Error per-tick on NULL state | 🟠 HIGH | Accept | 0 | `214b79a` |
| 02.5 | StatePersistence `_ExtractStr` no JSON unescape | 🟠 HIGH | Accept | 0 | `795e63f` |
| 02.6 | RiskManager.Init zeros prior config before NULL-guard | 🟡 MEDIUM | Accept | 0 (PortfolioMonitor pattern is intentional reset, not same anti-pattern) | `c51f4a1` (G3) |
| 02.7 | CircuitBreaker.CheckPingPong unused params | 🟡 MEDIUM | Accept | 0 | `c51f4a1` (G3) |
| 02.8 | RiskManager._ComputeLotForS silent fallback 0.10 | 🟡 MEDIUM | Accept | 0 | `c51f4a1` (G3) |
| 02.9 | CircuitBreaker `close_time_ms` field name drift | 🔵 LOW | Accept (folded into 02.2) | 0 | `97d7c24` (G1) |
| 02.10 | TimeGate.HolidayBlock NULL-CD comment-vs-code | 🔵 LOW | Accept | 0 | `8fb5300` (G4) |

**Accepted:** 10 / 10 — **Rejected:** 0 — **Partial:** 0
**Pattern detection:** Init() patterns scanned across all 9 services — 02.6 confirmed RiskManager-only (PortfolioMonitor's zero-on-reInit zeroes trackers as intentional warm-restart reset, validated logger before assignment, so different pattern). Round-01 anti-regression grep clean: ZigZag path (`Examples\\ZigZag`), `ErrorBypassThrottle` for invalid_handle, BootstrapValidator validate-then-mutate — all preserved.

---

## Accepted Findings — Fixes Applied

### Fix 02.1 — StatePersistence pending_payload round-trip
**Files:** `services/StatePersistence.mqh`
**Changes:**
- Added `_ExtractRawValue(content, field)` helper: RFC 8259 §3 value extractor handling object `{...}` (depth-tracked, string-aware), array `[...]` (depth-tracked), string `"..."` (escape-aware terminator), and primitive (`null`/`true`/`false`/number — read until `,` `}` `]` whitespace).
- Switched `pending_payload` Load callsite from `_ExtractStr` (string-only matcher `"key":"`) to `_ExtractRawValue`. Treat literal `"null"` and empty result as no-payload.
- Updated header callout citing ADR-008 + Finding 02.1 fix.
**Why:** Save uses `WriteRaw` (raw JSON value) for `pending_payload` per opaque-payload contract, but `_ExtractStr`'s search pattern `"key":"` never matched object/null forms → all 8 pending machines silently lost their payload on every reboot (NFR-3.3 violation, would corrupt OQ-A1/A2/A3 force-clear behavior post-restart).
**Commit:** `97d7c24` (G1 bundle)

### Fix 02.2 + 02.9 — CircuitBreaker BR-3.6 threshold + field rename
**File:** `services/CircuitBreaker.mqh`
**Changes:**
- `PING_PONG_THRESHOLD_S = 3000` → `3` (BR-3.6 = 3000 ms = 3 seconds under datetime second-floor precision).
- `NEAR_MISS_THRESHOLD_S = 5000` → `5`.
- `CloseEvent.close_time_ms` → `close_time_s` (struct + 3 method signatures + impls).
- Header datetime-precision note rewritten to explain the seconds-floor / ms-spec mapping.
- SelfTest cases A/B/C/D timestamps re-targeted: 1500/4000/6000/100 → 1/4/6/1 sec deltas (Case A halt at delta=1 ≤ 3, Case B near-miss at delta=4, Case C ignore at delta=6, Case D different-magic no-trigger).
**Why:** Const value of 3000 was interpreted as seconds → 50-minute halt window, false-positive on every legitimate close-and-reopen. NFR-1.1 Bucket A drift risk + BR-3.6 spec-letter violation. Microsecond upgrade (Option A) deferred as IMPL-053+ optional path; current fix matches spec under current datetime granularity.
**Commit:** `97d7c24` (G1 bundle, folded 02.9 rename)

### Fix 02.3 — RiskManager parent-lot read (last_open_lot)
**Files:** `domain/SlotState.mqh`, `services/PortfolioState.mqh`, `services/RiskManager.mqh`
**Changes:**
- `domain/SlotState.mqh` — added `double last_open_lot` field (default 0.0; populated by PortfolioState OnTradeTransaction handler at IMPL-053+).
- `services/PortfolioState.mqh::RegisterAll` — initialize `s.last_open_lot = 0.0`.
- `services/PortfolioState.mqh::Refresh` — reset `s.last_open_lot = 0.0` (re-populated by step 2 broker loop sketch).
- `services/PortfolioState.mqh` — updated IMPL-053+ broker-loop sketch to record `last_open_lot` based on `PositionGetInteger(POSITION_TIME)` max.
- `services/RiskManager.mqh::_ComputeLotForJ` — reads `cd.last_open_lot * 0.23 * extra` (BR-4.1 row J literal `LastBuyLots2 × 0.23`).
- `services/RiskManager.mqh::_ComputeLotForBI` — reads `b.last_open_lot * 0.236` (ADR-009 Fibonacci 23.6% of B-last).
- `services/RiskManager.mqh::_ComputeLotForI` — reads `g.last_open_lot * 0.382` (BR-4.1 row I phase-1 simplification).
- All three: if `last_open_lot ≤ 0` → emit `Warn parent_last_open_lot_unwired` + return 0.0 (fail-loud per round-01 Finding 01.7 philosophy).
- SelfTest case 9 added: stub portfolio with `total_lots=0.30` + `last_open_lot=0.10` → assert J = 0.023 (correct), BI = 0.0236, unwired-path returns 0.0.
**Why:** BR-4.1 spec literal references "LastBuyLots2" and "LastGLots" — last-opened parent lot, not aggregate. Reading `total_lots` instead → 3-5× lot inflation under any pyramid scenario, threatening NFR-1.1 Bucket A drift > 25%.
**Commit:** `6b23ddf`

### Fix 02.4 — PortfolioMonitor NULL-state anti-spam
**File:** `services/PortfolioMonitor.mqh`
**Changes:**
- Added `m_state_null_logged` member bool (one-shot guard).
- Constructor + Init() initialize/reset to false.
- `Update()` Step 1: first NULL detection → `ErrorBypassThrottle` once (Alert path, throttle bypassed for boot-time degraded mode visibility); subsequent NULL Updates skip log; flag clears when state restored mid-session.
- In-memory DD tracking still proceeds per OQ-6 monitor-only contract.
**Why:** `Logger.Error` per tick on NULL state flooded Print log + spun `IncrementLoggerThrottle` counter, violating ADR-011 anti-spam contract (≤1 Alert per slot per session).
**Commit:** `214b79a`

### Fix 02.5 — StatePersistence `_ExtractStr` JSON escape-aware
**File:** `services/StatePersistence.mqh`
**Changes:**
- Backslash-aware terminator scan: count preceding `\` for parity (even = real terminator, odd = escaped) before accepting `"` as string close.
- Unescape pass: `\"` `\\` `\n` `\r` `\t` plus `\uXXXX` 4-hex-digit unicode. Unknown escape sequences pass through literally (defensive).
**Why:** After round-01 fix 01.9 made `JsonWriter.EscapeString` RFC 8259 §7 compliant, naive terminator caused string truncation mid-content on any `halt_reason` containing `"` or `\`. NFR-3.3 round-trip violation.
**Affects callsites:** `ea_halt_reason`, `last_failure_reason` (defensive coverage on enum-only paths too).
**Commit:** `795e63f`

### Fix 02.6 — RiskManager.Init validate-then-mutate
**File:** `services/RiskManager.mqh`
**Changes:**
- Reordered Init() to validate inputs FIRST; mutation only after validation passes.
- NULL-logger Print fallback now reports retained `main_risk_ratio` + `max_lot_ratio` for operator visibility (proves no wipe occurred).
- Removed pre-zero block (redundant since mutation is now atomic post-validation).
**Why:** Pre-zero before NULL-guard return wiped valid prior config on re-Init failure → silent 0.01-lot orders downstream when `ComputeLot * 0` floored to broker minimum.
**Commit:** `c51f4a1` (G3 bundle)

### Fix 02.7 — CircuitBreaker.CheckPingPong drop unused params
**File:** `services/CircuitBreaker.mqh`
**Changes:**
- `CheckPingPong(CPortfolioState&, datetime)` → `CheckPingPong()` (declaration + impl + 4 SelfTest call sites + stub_port instance removed).
- Removed `#include "PortfolioState.mqh"` (sneaky-coupling guard).
- Header note updated explaining the drop + caller contract.
**Why:** Code Review Dim #5 (over-engineering) — premature parameters that body never read.
**Commit:** `c51f4a1` (G3 bundle)

### Fix 02.8 — RiskManager._ComputeLotForS reject invalid input
**File:** `services/RiskManager.mqh`
**Changes:**
- Tolerance tightened `< 0.5` → `< 0.001` (input is integer enum {5,10,15}).
- Silent fallback `factor = 0.10` removed.
- Invalid percentTP → `ErrorBypassThrottle("s_pct_tp_invalid", ..., MAGIC_S)` + return 0.0.
**Why:** Silent fallback masked Inputs_Slot_S default-set bug (caller passes 0 → factor 0.10 → 2× lot at intended 5% setting). Matches round-01 Finding 01.7 fail-loud rule.
**Commit:** `c51f4a1` (G3 bundle)

### Fix 02.10 — TimeGate.HolidayBlock NULL-CD path
**File:** `services/TimeGate.mqh`
**Changes:**
- NULL-CD path: emit `Logger.Error("holiday_cd_state_null", ..., 200)` + `return false` (allow per BR-3.3 spec literal).
- Comment updated to match code; explains operator visibility for RegisterAll wiring gap.
**Why:** Comment said "treat as no positions" but code returned `true` (block). Over-blocking entire Dec 21 - Jan 3 window during a wiring bug = visible NFR-1.1 behavioral drift vs legacy EA.
**Commit:** `8fb5300`

---

## Rejected Findings — Evidence

ไม่มี — 10/10 accepted.

---

## G1-G4 Status

| Gate | Status | Reason |
|------|--------|--------|
| G1 Compile | ⏭ Skip | Entry `.mq5` (`PhoenicisNex.mq5`) ยัง not landed (IMPL-018+) — header-only `.mqh` files defer G1 per IMPL-001..045 precedent. Fixes are structurally sound; G1 will run rom-end at orchestrator wire-up. |
| G2 Smoke | ⏭ Skip | Same precedent (header-only). |
| G3 Headless | ⏭ Skip | Same precedent. |
| G4 Log review | ⏭ Skip | Same precedent. |

**Verification surface ของ round นี้:** Static review (Read + Edit) + SelfTest expansion:
- **CircuitBreaker SelfTest:** 4 cases re-targeted to new threshold semantics (still 4 cases; assertions adjusted).
- **RiskManager SelfTest:** Added case 9 (3 sub-assertions covering J formula correctness, BI formula correctness, and unwired-path fail-loud branch). Total cases now 9 (was 8).
- **StatePersistence SelfTest:** No new case yet; round-trip Save→Load test suggested by reviewer (Finding 02.1 paragraph) deferred to IMPL-018+ when CStatePersistence can write to real `MQL5/Files/` sandbox. SelfTest infrastructure exists but real-file round-trip needs entry .mq5 to spin up CAtomicFile + Logger DI.

All fixes structurally sound; runtime verification gated by entry `.mq5` (per existing impl-plan precedent — ไม่ใช่ regression ของ round นี้).

---

## Anti-regression check (round-01 fixes preserved)

```
$ grep -nE "iCustom\(.*\"ZigZag\"" services/IndicatorService.mqh
(0 hits — round-01 Finding 01.2 fix preserved; uses "Examples\\ZigZag")

$ grep -n "Logger.Error.*invalid_handle" services/IndicatorService.mqh
(0 hits — round-01 Finding 01.4 fix preserved; uses ErrorBypassThrottle)

$ grep -nE "CleanupPartialInit" core/BootstrapValidator.mqh services/IndicatorService.mqh
(present — round-01 Finding 01.1 partial-failure cleanup preserved)
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 10 |
| Accepted | 10 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 6 (StatePersistence.mqh, CircuitBreaker.mqh, RiskManager.mqh, PortfolioMonitor.mqh, TimeGate.mqh, SlotState.mqh) + 1 cascaded (PortfolioState.mqh) |
| Tests Added/Updated | 1 SelfTest case added (RiskManager case 9 with 3 sub-assertions) + 4 SelfTest cases re-targeted (CircuitBreaker A/B/C/D timestamps) |
| Commits | 6 (`97d7c24` G1 bundle, `6b23ddf` 02.3, `214b79a` 02.4, `795e63f` 02.5, `c51f4a1` G3 bundle, `8fb5300` 02.10) |

**Recommendation:** Ready for next code review round หรือ proceed กับ remaining P2 tasks (IMPL-041 trivial close + IMPL-043 TradeJournal L). Empirical verification ของ Round 02 fixes gated by IMPL-018+ entry .mq5 land — same precedent as Round 01 fixes.

**Next code review trigger:** หลัง IMPL-049 (PendingMachineRegistry XL) lands — will exercise StatePersistence pending_payload round-trip path end-to-end + CircuitBreaker integration with EAState.SetHalted (IMPL-052/053 wiring).
