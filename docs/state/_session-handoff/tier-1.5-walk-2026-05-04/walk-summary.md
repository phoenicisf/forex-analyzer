# Tier 1.5 Exploratory Walk — 2026-05-04

**Trigger:** IMPL-060 closure unblocked runnable surface; per CLAUDE.md §1 PhoenicisNex-specific definition (no GUI), Tier 1.5 walk = headless backtest + Tester log + journal audit.

**Fixture:** `simulation/headless-tests/bootstrap_smoke.ini` (updated 2026-05-04 — added `FromDate=2024.01.02 ToDate=2024.01.05` + Model=0 to make headless run finite; original IMPL-001 stub had no date range causing infinite history backtest).

**Operator session:** Engineer-driven this turn (foreground MT5 closed; `terminal64.exe /config:bootstrap_smoke.ini` headless run; ShutdownTerminal=1 + Visual=0).

---

## Execution

| Metric | Value |
|---|---|
| Wall-clock duration | 6:50 (Tester reports `Test passed in 0:06:50.521`) |
| Tick count | 304,418 ticks, 18 bars |
| Memory | 97 MB (9 MB history + 64 MB tick data) |
| Final balance | $1000.00 (no positions closed during 3-day window) |
| `OnTester` result | 1000.0 (placeholder = ACCOUNT_EQUITY per IMPL-059 D-5) |
| Tester verdict | ✅ `test Experts\PhoenicisNex\PhoenicisNex.ex5 on EURUSD,H4 thread finished` |
| Total log lines | 1,414,435 (629 MB raw — abridged in `abridged-tester-log.txt`) |

## ✅ Empirical evidence captured (drains deferred-AC rows)

| Event | Log line | Drains row |
|-------|----------|-----------|
| `[ev=logger_init_ok]` `min_level=INFO alert_on_error=true escalation_n=10` | line 252 | IMPL-009 (P1 Logger init) |
| `[ev=pip_math_init][digit_multiplier=10]` | line 253 | IMPL-009 (P1 PipMath digit auto-detect) |
| `[ev=init_ok]` for RiskManager / CircuitBreaker / TimeGate / PortfolioMonitor | lines 254-257 | IMPL-040, IMPL-041, IMPL-044, IMPL-045 (P2 service init markers) |
| `[ev=handles_created] All 24 indicator handles valid (ADR-003 inventory)` | line 267 | NFR-3.2 100% indicator handle validation |
| `[ev=state_corrupt_starting_fresh]` (expected first-run; GV-recovery attempted) | line 268 | IMPL-052 (P2 cold-bootstrap path) |
| `[ev=portfolio_registered] magics registered: 17` | line 269 | **IMPL-007 (P1 PortfolioState OnInit register-all + 17-magic invariant)** |
| `[ev=init_ok] handles=24 slots=21 magics=17 state=EA_STATE_RUNNING` | line 270 | **IMPL-060 (P4 G2 smoke: attach EURUSD H4 → `[ev=init_ok]` within 5 ticks)** ✅ |
| `[ev=enter_pending][machine=C\|M\|T]` + `[ev=transition_executed]` per tick | lines 271-288 | IMPL-049 (P2 PendingMachineRegistry round-trip) |
| `[ev=entry_signal]` for slots C/G2/L/M/S/T (entries fired across 18 bars) | throughout | IMPL-019, IMPL-026, IMPL-029, IMPL-030, IMPL-035, IMPL-036 (P3 slot Evaluate paths) |
| `[ev=deinit_cleanup] reason=1 state=EA_STATE_RUNNING` | tail | IMPL-059 (P4 OnDeinit inverse-order release path) |

**G2 smoke E-AC for IMPL-060: ✅ EMPIRICALLY DRAINED** — `[ev=init_ok]` confirmed in Tester log within first tick of 2024.01.02 00:00:00.

## 🐛 Defects discovered (Tier 1.5 walk caught what scripted spike SelfTest missed)

### IMPL-FIX-001 [HIGH] — Slot_S → RiskManager integration drift: `percent_tp` not threaded

**Symptom:** Every tick of the 3-day window emits:
```
[ERROR][slot=RiskManager][ev=s_pct_tp_invalid][magic=217] percent_tp=1.0000 not in {5,10,15}; S lot = 0.0 (no order)
Alert: [Phoenicis]...same...
```
+ MT5 native `Alert()` popup (NFR-5.1 escalation triggers on `[ERROR]`). EVERY tick = DDoS-level log spam (contributes to 629 MB log file).

**Root cause:**
- `RiskManager::_ComputeLotForS(percent_tp)` requires `percent_tp ∈ {5, 10, 15}` per BR-4.1 (CodeWiki §3.S percentTP-tiered lot calc).
- `slots/Slot_S.mqh:203` calls `m_risk.ComputeLot("S", InpSSlPips, balance)` — only 3 positional args. The 4th arg `extra_multiplier` defaults to **1.0** at `services/RiskManager.mqh:82` → `_ComputeLotForS(1.0)` → no factor match → returns 0 + emits ERROR.
- `inputs/Inputs_Slot_S.mqh` has NO `InpSPercentTp` declaration; the input was missed during IMPL-036 closure (Slot_S structural spike SelfTest doesn't exercise RiskManager full chain — exactly the defect class Tier 1.5 walk is designed to catch).

**Fix scope:** S-size — add `InpSPercentTp = 10.0` (default per CodeWiki §3.S) to `Inputs_Slot_S.mqh` + update Slot_S.mqh:203 to pass `InpSPercentTp` as 4th arg. Re-run G3 to confirm `[ev=s_pct_tp_invalid]` disappears + `[ev=entry_signal]` for S emits with `lot=N.NN` not `lot=0.01` floor-clamped.

**Owner:** Kritsana
**Phase:** P3 (IMPL-036 follow-up) but hot-fix at any time
**ADR/spec impact:** none (BR-4.1 unchanged; this is integration plumbing)

### IMPL-FIX-002 [MEDIUM] — Lot defaults oversized for $1000 deposit → `clamp_applied` WARN every tick

**Symptom:** Every slot's `RiskManager::ClampLot` emits:
```
[WARN][slot=RiskManager][ev=clamp_applied] slot=L raw=150.0000 → clamped=2.9000 [floor=0.0100 cap=2.9000]
[WARN][slot=RiskManager][ev=clamp_applied] slot=G2 raw=105.0000 → clamped=2.9000 [floor=0.0100 cap=2.9000]
...
```

**Root cause:** Per-slot `InpXBaseLot` defaults (10-200) are calibrated for the production $1M+ baseline equity per `ReportTester-25045474.html`, not the $1000 smoke-test deposit. Clamp protection (BR-4.2/4.3 cap = 2.9 lots @ $1000) fires correctly but the WARN-level emission spams every tick.

**Possible fixes (engineer judgment):**
- (a) Promote `clamp_applied` from WARN → DEBUG (operator typically doesn't care unless investigating; volume reduction ~10×).
- (b) Add `clamp_applied` rate-limiter (emit once per slot per session per ADR-008 escalation precedent).
- (c) Document the smoke-test calibration mismatch + accept noise (smoke deposit is artificially small for fast headless run).
- (d) Provide `[deposit_aware]` smoke fixture (e.g., bootstrap_smoke.ini Deposit=1000000 = baseline parity).

**Owner:** Kritsana
**Phase:** P2 (IMPL-040 follow-up) OR P4 (logging hygiene before regression run IMPL-061..063)
**Risk if missed:** False-positive operator alarms during regression sweep + log volume blows past NFR-2.2 5ms p99 budget on disk-bound runs.

## Walk verdict

✅ **PROCEED** — Tier 1.5 walk objectives met:
- Empirical surface is **live and stable** (full 3-day backtest passed without crash, halt, or hang).
- IMPL-060 G2 E-AC `[ev=init_ok]` empirically captured.
- 11+ deferred-AC rows have empirical evidence available in `abridged-tester-log.txt` for batch drain (next session task).
- 2 functional defects surfaced (IMPL-FIX-001 + IMPL-FIX-002) — exactly the defect class scripted spike SelfTest can't catch.

## Artifact retention

- Raw Tester log (629 MB at `Tester/.../Agent-127.0.0.1-3000/logs/20260504.log`) — kept on local disk only (not committed; UTF-16LE binary noise per `.claude/rules/ea.md § Commit Format`).
- Abridged log (33 KB at `abridged-tester-log.txt`) — committed alongside this summary.
- Walk validity: ≤ 14 days per CLAUDE.md §1 Tier 1.5 contract → expires 2026-05-18.

## Next actions

1. Open `IMPL-FIX-001` task in impl-plan (HIGH, S-size, hot-fix today).
2. Open `IMPL-FIX-002` task in impl-plan (MEDIUM, S-size, batch with logging hygiene before IMPL-061..063).
3. Drain the remaining 12+ resolvable P1/P2 deferred-AC rows by citing this artifact (batch close in next `/impl-task` session).
4. Code review R09 (`/impl-review all`) — Tier 1.5 walk results inform the adversarial sweep.
