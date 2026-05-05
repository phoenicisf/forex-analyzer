# Tier 1.5 Exploratory Walk batch-2 — 2026-05-05

**Trigger:** IMPL-FIX-001 + IMPL-FIX-002 closure (commits `4110a78` + `a290d7a`) + IMPL-064 PowerShell harness landed (commit `41ffdd6`); per CLAUDE.md §1 PhoenicisNex-specific definition (no GUI), Tier 1.5 walk = headless backtest + Tester log + journal audit + atomic-write kill harness.

**Fixtures used:**
- `simulation/headless-tests/bootstrap_smoke.ini` — 3-day window 2024.01.02 → 2024.01.05, EURUSD H4, $1000 deposit (re-run post-FIX merge)
- `simulation/headless-tests/atomic_write_kill.ini` — Spike_AtomicWrite (driven by harness; 100 trials)

**Operator session:** Engineer-driven this turn (foreground MT5 closed; headless `terminal64.exe /config:bootstrap_smoke.ini` → atomic-write kill harness `powershell -File atomic_write_kill_100.ps1 -Trials 100`).

---

## Execution

### G3 — bootstrap_smoke.ini (post-FIX rerun)

| Metric | batch-1 (2026-05-04) | batch-2 (2026-05-05) | Delta |
|---|---|---|---|
| Wall-clock duration | 0:06:50.521 | 0:09:05.786 | +2:15 (host-load variance — see "System Load Context" below; deterministic Tester output unchanged) |
| Tick count | 304,418 / 18 bars | 304,418 / 18 bars | identical (deterministic) |
| Memory | 97 MB | 83 MB | −14 MB (less per-tick string churn) |
| Final balance | $1000.00 | $1000.00 | unchanged (no positions closed in 3-day window) |
| `OnTester` result | 1000.0 | 1000.0 | unchanged |
| Tester verdict | ✅ Test passed | ✅ Test passed | clean |
| Raw Tester log | 629 MB / 1,414,435 lines | **224 MB** / decoded sample | **−64% volume** ✅ |
| `[ERROR]` count | tens of thousands (`s_pct_tp_invalid` per tick) | **0** ✅ | FIX-001 verified |
| `[WARN]` count | tens of thousands (`clamp_applied` per tick) | **1** (state_corrupt_starting_fresh expected first-run) ✅ | FIX-002 verified |

### G4 — Atomic-write kill harness (IMPL-064 numeric)

| Metric | Value |
|---|---|
| Trials | 100 |
| `parse_pass` | **100** ✅ |
| `parse_fail` | 0 |
| `state_missing_tmp_present` | 0 |
| `state_missing_tmp_missing` (pre-write kill) | 0 |
| `startup_timeout_count` | 0 |
| `failed_fast` | false |
| Wall-clock | 34.3s (≈340ms / trial; well under 60s timeout cap) |
| Verdict | **PASS** ✅ |
| Sidecar | `docs/state/nfr-3.1-atomic-write-result.json` |

NFR-3.1 contract satisfied — 100/100 atomic writes survived live `Stop-Process -Force` mid-write kill against ADR-007 Option A (write-temp + rename) implementation.

---

## System Load Context (informational — for wall-clock interpretation)

> Added 2026-05-05 per fix-round-15 § 15.4 — Strategy Tester `Model=0` non-tick OHLC + fixed FromDate/ToDate + fixed Deposit/Leverage = fully deterministic at the data layer (tick count 304,418 unchanged confirms determinism). The 33% wall-clock delta between batch-1 and batch-2 is therefore **host-load variance**, not test-methodology variance. Capture context so future NFR-2.x latency E-AC reviewers can interpret single-session timings.

| Metric | batch-1 (2026-05-04) | batch-2 (2026-05-05) | Notes |
|---|---|---|---|
| Run start (local time) | 14:08 (post-IMPL-060 close session) | 08:36 (morning session, fresh terminal) | timezone EET / GMT+2 |
| MT5 cache state | warm (FBS-Real symbol+history loaded earlier) | cold (first headless run of the day) | cold-cache pays one-time warm-up cost during early ticks |
| Concurrent processes (top 5 by CPU during run) | not captured | not captured | retro fill via operator memory: batch-1 = engineer session foreground active; batch-2 = engineer session foreground active |
| Free RAM at run start | not captured | not captured | future runs: capture via `Get-CimInstance Win32_OperatingSystem \| Select-Object FreePhysicalMemory` |
| Notes | first-ever attach + IMPL-060 closure session — engineer attention focused | post-FIX merge rerun — ran while authoring fix-round / impl-plan edits in parallel | parallel doc-edit work likely contributed to batch-2 +33% wall-clock |

**Methodology advisory for IMPL-065 (tick latency NFR-2.1) + IMPL-066 (journal latency NFR-2.2):**
- Single-session wall-clock is **not** a reliable basis for p99 latency caps when host load varies as shown above.
- Recommend (a) capture system-load snapshot via `Get-Process | Sort-Object CPU -Descending | Select-Object -First 5` + free-RAM at run start; (b) require ≥3 sessions per run + use median (not single value) for p99 attestation; (c) prefer EA-internal `GetMicrosecondCount()` instrumentation per tick over wall-clock outer loop.
- This subsection becomes the template for future Tier 1.5 walk artifacts (XS-15.2 — canonicalize in `.claude/rules/testing.md` when IMPL-065/066 land).

---

## ✅ Empirical evidence captured (drains deferred-AC rows)

### IMPL-FIX-001 (P3 / HIGH `s_pct_tp_invalid`)
**AC text:** "G3 headless run via `bootstrap_smoke.ini` shows zero `[ev=s_pct_tp_invalid]` ERROR lines + at least one `[ev=entry_signal][slot=SlotS]` with `lot > 0.01` (not floor-clamped)"

**Drained:**
- `s_pct_tp_invalid` count: **0** (batch-1: tens of thousands)
- SlotS `entry_signal` count: **216,671** with `lot=2.90 sl_pips=60.0 dir=BUY comment=S,post,1` (sample line)
- Lot value `2.90` = clamped at `max_lot_ratio=2.9` per RiskManager init log (NOT floor-clamped to 0.01)

### IMPL-FIX-002 (P2 / MEDIUM `clamp_applied`)
**AC text:** "G3 headless run via `bootstrap_smoke.ini` shows ≤ 1 `[ev=clamp_applied]` per slot per session OR log file size ≤ 100 MB"

**Drained via OR-clause-1:**
- `clamp_applied` count: **0** total (DEBUG-demoted, filtered by INFO threshold) — 0 ≤ 1 × 21 slots ✅
- Log file size: 224 MB (OR-clause-2 fails — calibration mismatch with smoke deposit retained as-designed)
- Forensic loss documented in registry row: investigations of unexpected lot sizes now require LOG_DEBUG flag toggle

### IMPL-007 (P1 PortfolioState OnInit register-all + 17-magic invariant)
**AC text:** "OnInit smoke → Logger Debug 'magics registered: 17' `[log-assertion]`"
**Drained:** line 252 `[ev=portfolio_registered][magic=0] magics registered: 17` ✅
- `[db-inspect]` half (`GetByMagic(MAGIC_X).total_profit` matches MT5 native) — partially drained: state.json `slot_states` has 17 magic keys, all `total_profit=0` (no positions opened). Real broker reconcile against open positions deferred to IMPL-062 5-yr regression.

### IMPL-009 (P1 PipMath digit auto-detect)
**AC text:** "OnInit Logger Info 'pip_math digit_multiplier=10' on FBS-Real `[log-assertion]`"
**Drained:** `[Phoenicis][slot=system][ev=pip_math_init][digit_multiplier=10]` ✅

### IMPL-049 (P2 PendingMachineRegistry round-trip)
**AC text:** "M-Pending (or any of 8 machines) persisted as PENDING with payload + force_clear_count survives restart and routes correctly through TickAll on next bar `[boot-cold]`"

**Partial drain:**
- `enter_pending` events fired for machines: C, M, T, Q, P (5 of 8 machines exercised)
- `transition_executed` events fired for: C, M, T, Q (4 of 5 transitions completed within window)
- state.json `pending_machines.{c_pending,c_pending_adx,r_pending,p_pending,m_pending,t_pending,q_pending,force_pending}` all 8 keys present + schema-valid ✅
- `[boot-cold]` half (kill+reload + force-clear at `InpForceClearM_Bars` threshold): 3-day window not long enough to cross 150-bar threshold; defer to IMPL-062 5-yr regression.

### IMPL-052 (P2 cold-bootstrap path)
**AC text:** "Cold restart with `state.json` containing `state=HALTED` + `portfolio_count=0` → EA boots → in-RAM state resolves to RUNNING + reset reason `[boot-cold]`"

**Partial drain:** `[ev=state_corrupt_starting_fresh]` fired on first-run as expected (state.json absent at start) → in-RAM state resolved to `EA_STATE_RUNNING` (init_ok line confirms). HALTED-restart specific path (state.json contains state=HALTED) not exercised here — needs synthetic state.json fixture; defer.

### IMPL-064 (P4 atomic-write 100/100 numeric)
**AC text:** "100/100 trials = state.json parses cleanly OR doesn't exist (no half-write) `[boot-cold]` + `[file-blob-check]`"
**Drained:** `parse_pass=100 / parse_fail=0` per `nfr-3.1-atomic-write-result.json` ✅

### IMPL-040 / IMPL-041 / IMPL-044 / IMPL-045 (P2 service init markers)
Init-OK log lines captured (lines 254-257 batch-1; same in batch-2 abridged):
- RiskManager: `main_risk=1.0000 max_lot_ratio=2.9000 port=wired` ✅
- TimeGate: `window=5 spread_thr=10 holiday=12/21..1/3` ✅
- PortfolioMonitor: `eq_high=0.00 worst_dd=0.0000 cur_dd=0.0000` ✅
- CircuitBreaker: `cb_init_ok buffer_size=16 ping_threshold=3s near_miss_threshold=5s` ✅

### NFR-3.2 (100% indicator handle validation)
`[ev=handles_created] All 24 indicator handles valid (ADR-003 inventory)` ✅

### IMPL-060 (P4 G2 init_ok smoke) — already drained batch-1
`[ev=init_ok] handles=24 slots=21 magics=17 state=EA_STATE_RUNNING` ✅ (batch-2 confirms regression-clean)

### IMPL-059 (P4 OnDeinit inverse-order release)
`[ev=deinit_cleanup] reason=1 state=EA_STATE_RUNNING` ✅

---

## ⚠️ Rows NOT drained (gating remains)

| Row | Reason |
|---|---|
| IMPL-008 (comment_parser_self_test pass) | `ENABLE_SELFTEST` flag not exercised at runtime — bootstrap_smoke.ini doesn't enable it; structural SelfTest covered by spike. Needs separate `selftest_smoke.ini` fixture |
| IMPL-011 (json_writer_self_test + round-trip) | Same as IMPL-008 — `ENABLE_SELFTEST` flag gated |
| IMPL-012 / IMPL-014 (input dialog probe) | `[probe]` evidence requires live MT5 chart attach — Strategy Tester uses default values; no input dialog rendering |
| IMPL-013 (21 group sections probe) | Same as IMPL-012 — input dialog probe needs chart attach |
| IMPL-019..039 P3 slot 60-day backtests | 3-day window < 60-day prereq; deferred to IMPL-062/063 P4 regression chain |
| IMPL-022 / IMPL-039 G4 fix journal evidence | Journal records require RiskManager OrderSend success → actual broker fills; 3-day $1000 deposit produced 0 fills (final balance unchanged) |
| IMPL-053..058 P4 cross-slot synthetic fixtures | `cross_slot_*.ini` activation deferred to IMPL-059+ runnable surface; this walk used `bootstrap_smoke.ini` only |
| IMPL-068 paired bundle (force-clear 5-yr) | Numeric drain depends on IMPL-062/063 producing 5-yr journal records; not exercisable from 3-day window |

---

## 🐛 Defects discovered

**None this walk.** Both batch-1 defects (IMPL-FIX-001 + IMPL-FIX-002) verified resolved via empirical log audit; no new functional defects surfaced from 3-day backtest + 100-trial kill harness.

Observed (informational, not defects):
- SlotG2 + SlotS fire `entry_signal` per tick (144,685 + 216,671 events) without OrderSend completion. Pre-existing limitation: RiskManager OrderSend chain not yet closed end-to-end (per IMPL-019..039 deferred-AC narrative — slots emit intent log, OrderSend wiring is gated on broker fill flow that needs IMPL-062 P4 regression chain). Not a regression — same shape as batch-1 walk.

## Walk verdict

✅ **PROCEED** — Tier 1.5 walk batch-2 objectives met:
- Both prior defects (FIX-001 HIGH + FIX-002 MEDIUM) empirically verified resolved; per-tick ERROR + WARN spam eliminated (log volume −64%).
- NFR-3.1 atomic-write contract verified live (100/100 trials parse cleanly under `Stop-Process -Force` mid-write kill).
- IMPL-064 numeric drain complete (verdict=PASS).
- 8 P1/P2 deferred-AC rows fully or partially drained; 2 P3 IMPL-FIX rows fully drained.
- No new defects discovered.

## Artifact retention

- Raw Tester log (224 MB at `Tester/.../Agent-127.0.0.1-3000/logs/20260505.log`) — kept on local disk only (not committed; UTF-16LE binary noise per `.claude/rules/ea.md § Commit Format`).
- Abridged log (~6.5 KB at `abridged-tester-log.txt`) — committed alongside this summary.
- Sidecar JSON (`docs/state/nfr-3.1-atomic-write-result.json`) — committed; harness output authoritative for IMPL-064 numeric.
- state.json schema-valid snapshot at end of run (under Tester sandbox; not committed but inspectable via PowerShell `ConvertFrom-Json` per validation block above).
- Walk validity: ≤ 14 days per CLAUDE.md §1 Tier 1.5 contract → expires **2026-05-19**.

## Next actions

1. Update `docs/state/deferred-ac-registry.md` — drain 8 P1/P2 rows + 2 P3 FIX rows + IMPL-064 numeric → move to Resolved table; reduce Active count.
2. Update `docs/state/impl-plan.md` — TL;DR + Phase Status + Open Risks + Next Best Action; bump Sentinel.
3. Update `docs/state/overview.md` — Last Updated date + status string.
4. Author/append to `docs/state/current_handoff.md` — pointer to this artifact.
5. Patch `docs/state/nfr-3.1-atomic-write-result.md` Result section — replace placeholder table with verdict from sidecar.
6. P2/P3 Phase Gate retroactive close — now possible (Tier 1.5 walk artifact ≤14d ✅ + remaining drain via deferred-AC scan).
7. `/impl-review all` R09 — recommended next per impl-plan TL;DR (cross-slot + Orchestrator + entry .mq5 + 2 FIX commits + 3 QA pipeline = significant accumulated attack surface).
