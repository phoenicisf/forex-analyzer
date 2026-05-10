# IMPL-FIX-008 Evidence — R-9 Closure (2026-05-10)

> Engineer: Opus 4.7. Session continuation from IMPL-FIX-007 v2 closure (commit `74c9389`).
> User goal: run 5-yr Bucket B regression (`regression_5yr_g4.ini`) to confirm R-8 closure path empirically.
> Outcome: discovered + fixed R-9 (CircuitBreaker storm); discovered R-11 (per-tick perf gap); deferred 5-yr numeric drain pending R-11 fix in separate session.

---

## 1. Defect surfaced (R-9)

**Trigger event:** Bucket B `regression_5yr_g4.ini` Model=0 5-yr run launched after IMPL-FIX-007 v2.
- **First failed launch attempt:** Git Bash MSYS path translation bug — used `//config:` (double-slash) → MSYS converted argument so MT5 received only the data-dir path, not the `/config:` flag. MT5 opened idle. Fix: use single `/config:` (MSYS leaves it alone since not `/letter/`-prefixed).
- **Second failed launch attempt:** committed `regression_5yr_g4.ini` uses `Model=4` (every tick from real ticks). Required tick history download cancelled in 1 sec → "no history data, stop testing".
- **Third failed launch attempt:** ad-hoc `Model=2` (open prices only) — sub-tf indicators (M5/M10/M15) cannot load → OnInit critical error.
- **Fourth launch (Model=0 every-tick from M1)** **STARTED EXECUTION** but at sim=2021.01.08 20:37 entered `CircuitBreaker.CheckPingPong` storm:
  - 99,994 ping_pong events generated in ~3 minutes wall-clock
  - log grew +210 MB (rate ~70 MB/min)
  - **EA did NOT actually halt** — `ev=halt` count = 0, `EA_STATE_HALTED` count = 1 (but tick processing continued)
  - sim time only advanced ~1 sim hour per 5MB log chunk → 200+ GB log projected for full 5-yr (impractical)

## 2. Root cause (3 layers)

| Layer | Defect | Code site | Why |
|-------|--------|-----------|-----|
| Slot-side | Slot_G inherited the IMPL-FIX-007 v2 anti-pyramid gap | `slots/Slot_G.mqh::Evaluate` | v2 IMPL-FIX-007 added `m_last_fill_bar` H4-bar gate to Slot_G2 + Slot_S only. Slot_G shares MAGIC_G=208 with G2. When G storm fires within H4 bar boundaries, ping_pong on (magic=208, dir=1, delta=0s) triggers CircuitBreaker. |
| Service-side | `CheckPingPong()` did not clear ring buffer after detection | `services/CircuitBreaker.mqh:197-259` | Ring buffer `m_buffer[16]` retains stale (magic, dir, time) tuples. After detection, returns true but next-tick scan re-detects same pair. Spam loop unbounded until 16 new events naturally evict — but if EA halted, no new events come in. |
| Orchestrator-side | OnTick called `CheckPingPong` unconditionally | `core/Orchestrator.mqh:594-595` | Per ADR-010 enable matrix, exit-pass + portfolio-refresh + state-save run in HALTED state — but CheckPingPong should be entry-pass-domain only (no point detecting after we already halted). |

## 3. Patches (~50 LOC, 23 files)

### 3.1 Service-side (Orchestrator + CircuitBreaker)

**`core/Orchestrator.mqh:594` (state guard):**
```mql5
// Before:
if(m_breaker.CheckPingPong())
   Halt("circuit_breaker_pingpong");

// After (IMPL-FIX-008):
if(m_state_enum == EA_STATE_RUNNING && m_breaker.CheckPingPong())
   Halt("circuit_breaker_pingpong");
```

**`services/CircuitBreaker.mqh::CheckPingPong()` (buffer-clear after detection):**
```mql5
// Inside the `if(delta <= PING_PONG_THRESHOLD_S)` block, before `return true;`:
m_count = 0;
m_idx   = 0;
return true;
```

### 3.2 Slot-side (Slot_G H4-bar gate)

Mirrors Slot_G2 v2 IMPL-FIX-007 pattern:
- Added `m_last_fill_bar`, `m_pending_fill`, `m_pending_set_time` private fields
- Added `static const int PENDING_FILL_TIMEOUT_SEC = 60` definition
- Updated ctor: `CSlotG() : m_maxProfitPip(0.0), m_pending_fill(false), m_pending_set_time(0), m_last_fill_bar(0) {}`
- Inserted at top of `Evaluate` (BEFORE `_HasActiveGOrder` gate):
  ```mql5
  if(m_last_fill_bar > 0 && iTime(_Symbol, PERIOD_H4, 0) == m_last_fill_bar)
     return;
  if(m_pending_fill) {
     if(_HasActiveGOrder(port)) { m_pending_fill = false; m_pending_set_time = 0; }
     else if(TimeCurrent() - m_pending_set_time > PENDING_FILL_TIMEOUT_SEC) {
        m_pending_fill = false; m_pending_set_time = 0;
        m_logger.Warn("SlotG", "pending_fill_timeout", MAGIC_G, "60s elapsed without PortfolioState reflection - clearing latch");
     }
     else return;
  }
  ```
- Wrapped `m_risk.OpenOrder(req, "G")`:
  ```mql5
  if(m_risk.OpenOrder(req, "G")) {
     m_pending_fill     = true;
     m_pending_set_time = TimeCurrent();
     m_last_fill_bar    = iTime(_Symbol, PERIOD_H4, 0);
  }
  ```

### 3.3 Slot_S R-10 close-intent latch

Q1 canary post-FIX-008 revealed R-10: `Slot_S::ManageExits` Phase-1 stub emits `m_logger.Info(..., "exit_profit_gate", ...)` every tick when position lingers at gate (broker-close wiring deferred to `RiskManager::CloseOrder` Phase 2). 14k records per 5 sim-hr → ~24 GB log per 5-yr.

Added `ulong m_close_logged_ticket;` field + ctor init + emit gate `if(profit_pips >= InpSTpProfitPips && ticket != m_close_logged_ticket)` + set `m_close_logged_ticket = ticket` after emit. One-shot per ticket; reset implicitly when ticket vanishes (broker-close from end-of-test or SL hit).

### 3.4 Bulk-suppress 21-slot exit_profit_gate stub emits

Same Phase-1 stub pattern (`m_logger.Info(..., "exit_profit_gate", ...)`) duplicated across all 21 `Slot_*.mqh` files. Bulk-applied minimum-scope mitigation:
- Comment-out 22 emit sites (Slot_P has 2 — exit_profit_gate + exit_profit_gate_pyramid)
- 4-line `IMPL-FIX-008 R-10` banner header per site explaining intent + restoration trigger
- 3 dangling `if(m_logger != NULL)` no-body cases (Slot_H, Slot_K, Slot_L) patched to empty `{}` block to silence MQL5 warning 69 ("empty controlled statement found")

**Restoration trigger:** when `RiskManager::CloseOrder` lands in Phase 2 + slots wire actual broker-close call, restore the `Info` emit but make it post-close one-shot (single observable milestone per close, not per tick).

## 4. Verification artifacts

### 4.1 G1 compile

```
$ "$METAEDITOR" //compile:"MQL5\Experts\PhoenicisNex\PhoenicisNex.mq5" //log
[...]
Result: 0 errors, 0 warnings, 5442 ms elapsed, cpu='X64 Regular'
```

### 4.2 G2 smoke (3-day Model=0 bootstrap_smoke.ini)

```
Tester: automatical testing finished
Event counts in last 500KB:
  ev=order_sent: 0   (recorded earlier in run)
  ev=halt: 0
  ev=ping_pong: 0
  ev=deinit_cleanup: 1
  EA_STATE_HALTED: 0
  [ERROR]: 0
Journal records: 8 (run-20240102-000000-089.jsonl)
```

No regression on IMPL-FIX-007 v2 fix (8 records matches previous baseline).

### 4.3 Q1 2021 canary (post-FIX-008, sim=2021.01.01 — sim=2021.01.14)

- Storm point sim=2021.01.08 20:37 (where pre-FIX-008 5-yr run had 99,994 ping_pong events) **passed cleanly**: pp=0 halt=0 err=0 in monitor 50KB sliding window
- Whole-file UTF-16LE-encoded needle scan (`'ev=ping_pong'.encode('utf-16-le')` for proper byte-pattern match in UTF-16LE log file) confirms:
  - 99,994 ping_pong events at log offset >1.2GB = leftover from earlier 13:32 5-yr Model=0 storm run **before** FIX-008
  - **0 ping_pong events generated by current code**
- R-9 closed empirically.

## 5. R-11 (NEW Open Risk — per-tick performance gap)

Q1 canary pace measurement:
- Wall-clock 4 min / sim 14 sim-days / 90 target sim-days = ~26 min wall projected for Q1 = ~26-min/90-days = 0.29 sec/sim-day
- 5-yr extrapolation: 1825 sim-days × 0.29 sec/sim-day = ~9 min wall... (math is rough; actual observed pace 6-30 sim-day per wall-min)

Wait — observed steady-state 0.11-1.06 sim-hr per wall-sec → 5-yr extrapolation 2-15 hr wall-clock.

Original PhoenicisN2.10 baseline: 5-yr in 40-60 min per project memory + user expectation.

**Hypothesis space (for IMPL-PERF-001 or IMPL-FIX-009 next-session investigation):**
- (a) MarketContextBuilder rebuilt every tick when only H4 bar boundary indicator updates needed (could cache per-bar)
- (b) PortfolioState.Refresh loops PositionsTotal every tick when broker positions are mostly static between ticks (could refresh only on PositionsTotal-changed event via OnTradeTransaction)
- (c) per-slot Evaluate lacks short-circuit early-return for "no signal possible until next H4 bar" (e.g. `_HasActive*Order` already-true skip path)
- (d) Logger.Info formatting overhead even when level filters out (`m_min_level` checked AFTER `FormatLine()` call which builds the full string)

**Recommended methodology:** profile per-tick wall-clock allocation across services + slot Evaluate sites via `TickLatencyProbe` (IMPL-065 framework — already lands the 8-stage StageStart/StageEnd hooks behind `#ifdef ENABLE_TICK_LATENCY`); identify top 1-2 hotspots; apply targeted caching/early-return.

**Effort estimate:** 2-4 hours profile + optimize + retest.

## 6. Reproducible commands

```bash
# 1. G1 compile (after applying patches)
ORIGIN=$(python -c "import sys; data=open('origin.txt','rb').read(); print(data[2:].decode('utf-16-le').strip() if data[:2]==b'\xff\xfe' else data.decode('utf-16-le').strip())")
"${ORIGIN}\\MetaEditor64.exe" //compile:"MQL5\\Experts\\PhoenicisNex\\PhoenicisNex.mq5" //log
# Verify .compile.log: "Result: 0 errors, 0 warnings, NNNN ms elapsed"

# 2. G2 smoke (3-day no regression check)
TESTER_FILES="/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Tester/A12EC900AF5AF5023ECB36F7FB72E396/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex"
rm -f "$TESTER_FILES/state/state.json" "$TESTER_FILES/journal/tester/"*.jsonl
"${ORIGIN}\\terminal64.exe" /config:"C:\\Users\\kritsana.ye\\AppData\\Roaming\\MetaQuotes\\Terminal\\A12EC900AF5AF5023ECB36F7FB72E396\\simulation\\headless-tests\\bootstrap_smoke.ini"
# Verify journal: 8 records run-20240102-000000-NNN.jsonl
# Verify Tester log: "automatical testing finished" + 0 [ERROR]

# 3. R-9 closure verification (whole-file UTF-16LE-encoded needle scan)
python -c "
import os
log = r'C:\Users\kritsana.ye\AppData\Roaming\MetaQuotes\Terminal\A12EC900AF5AF5023ECB36F7FB72E396\Tester\logs\20260510.log'
needle = 'ev=ping_pong'.encode('utf-16-le')
sz = os.path.getsize(log)
matches = 0
first_offset = None
with open(log,'rb') as f:
    pos = 0
    while pos < sz:
        f.seek(pos); chunk = f.read(10*1024*1024 + 4096)
        cnt = chunk.count(needle)
        if cnt and first_offset is None: first_offset = pos + chunk.find(needle)
        matches += cnt
        pos += 10*1024*1024
print(f'ping_pong: total={matches}  first_at_offset={first_offset}')
# Pre-FIX-008 events live at offset >1.2GB (leftover from earlier 13:32 storm)
# Post-FIX-008 runs append above that offset; whole-file scan above the leftover shows 0
"
```

## 7. R-9 closure status

- ✅ **R-9 RESOLVED 2026-05-10** via IMPL-FIX-008 (3-patch service-side + slot-side + 21-slot bulk-suppress)
- ⚠️ **R-11 NEW** — per-tick perf gap blocks 5-yr regression numeric drain in reasonable wall-clock; mitigation deferred to IMPL-PERF-001 / IMPL-FIX-009 separate session

## 8. Files modified

```
modified:   MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh           # state guard
modified:   MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh     # buffer-clear post-detection
modified:   MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh                # H4-bar gate (mirror G2 v2)
modified:   MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh                # R-10 close-intent latch + bulk-suppress
modified:   MQL5/Experts/PhoenicisNex/slots/Slot_{B,BI,BR,C,D,F,G2,GO,H,I,J,K,L,LX,M,P,Q,R,T}.mqh  # bulk-suppress
new:        docs/state/_session-handoff/IMPL-FIX-008-evidence-20260510.md  # this file
```

Working tree clean post-commit. Ad-hoc `_adhoc_*.ini` files removed (not committed).
