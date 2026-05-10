# IMPL-FIX-006 — Evidence Artifact

**Date:** 2026-05-10
**Task:** IMPL-FIX-006 [L-XL] [ea] — RiskManager.ComputeLot dimensional formula bug
**Closes:** R-8 (Open Risks); unblocks IMPL-062 5-yr regression retry

## Summary

Per CodeWiki §4.1 dimensional formula `lot = riskMoney / (slPips × pipValue)`, rewrote `CRiskManager::ComputeLot` for 17 direct-lot slots (C/D/F/G/G2/GO/M/L/LX/Q/R/P/T/B/BR/H + S/K via private variants); 3 parent-anchored slots (J/BI/I) verified formula-correct (no change). Added `_PipValue()` and `_RiskMoneyToLot()` helpers; updated `_ComputeLotForS` + `_ComputeLotForK` signatures to accept `sl_pips` and apply division.

## Files Changed

- `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh` (1 file, ~110 LOC delta)

## Gate G1 — Compile (PASS)

```
$ MetaEditor64.exe /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log
Result: 0 errors, 0 warnings, 4199 ms elapsed, cpu='X64 Regular'
```

## Gate G2 — Smoke (PASS — empirical dimensional verification)

`bootstrap_smoke.ini` (Model=0 every-tick, 2024.01.02..2024.01.05 EURUSD H4 deposit=$1000).

Wall-clock 36 s. Tester log diff bytes 21,386,892 (decoded UTF-16LE → UTF-8 to `/tmp/fix006_smoke_decoded.txt`).

### Init chain (clean)

```
[INFO][slot=system][ev=logger_init_ok] Logger initialised; min_level=INFO
[INFO][slot=RiskManager][ev=init_ok][magic=0] main_risk=1.0000 max_lot_ratio=2.9000 port=wired
[INFO][slot=portfolio][ev=portfolio_registered][magic=0] magics registered: 17
[INFO][slot=system][ev=init_ok][magic=0] handles=24 slots=21 magics=17 state=EA_STATE_RUNNING
```

### `[ev=order_sent]` lot values (dimensional, 19 events total)

| Slot | Magic | Lot | SL distance (pips) | RiskMoney calc |
|------|-------|-----|--------------------|-----------------|
| S    | 217   | 0.17 (×16 entries) | 60 (1.10478→1.09878) | $1000 × 10% = $100 / (60 × $10) ≈ 0.166 → 0.17 |
| C    | 200   | 0.30 (×1)          | 50 (1.10479→1.09979) | $1000 × 1.0 × 0.15 × 1.0 = $150 / (50 × $10) = 0.30 |
| M    | 210   | 0.40 (×1)          | 50                   | $1000 × 1.0 × 0.20 × 1.0 = $200 / (50 × $10) = 0.40 |
| T    | 219   | 0.36 (×1)          | 55 (1.10479→1.09929) | $1000 × 1.0 × 0.20 × 1.0 = $200 / (55 × $10) ≈ 0.36 |

**All lot values scale dimensionally with SL distance** — no longer pinned at 2.90 cap.

### Counters

- `[ev=order_sent]`: 19 (was 5 in run #1 with 4 hitting cap)
- `[ev=clamp_applied]`: **0** (raw lots fall within `[floor, cap]` naturally — primary structural signal of fix)
- `[ev=order_failed]`: **0** (NO_MONEY storm gone)
- `[ev=order_skipped_no_margin]`: 1 (IMPL-FIX-005 anti-spam latch fired once + silenced — defense in depth)
- `[ev=compute_lot_invalid_inputs]`: 0
- `[ERROR]`: 0

### Pre-fix vs post-fix comparison

| Signal | Pre-fix (run #1 2026-05-10) | Post-fix (this run) |
|--------|------------------------------|---------------------|
| Lot values | All clamped to 2.90 cap | 0.17 / 0.30 / 0.36 / 0.40 (dimensional) |
| `clamp_applied` events | Every order | 0 |
| `order_failed` events | 31,409 (RC=10019 NO_MONEY) | 0 |
| Margin-call cascade | 17:10:00 day-1 ($1000 → $512.80 in 17h) | None — natural sizing absorbs balance shifts |
| Dimensional invariant | Broken (`sl_pips` ignored) | Verified (Case 10 SelfTest: doubling sl_pips → halving lot) |

## Gate G3 — 5-yr regression (DEFERRED to operator session — paired with IMPL-062 numeric drain)

`regression_5yr_no_g4.ini` (FromDate=2021.01.01 ToDate=2025.12.31, ~30-60 min wall-clock) requires operator runtime to:
1. Build `.ex5` with `#define DISABLE_G4_FIXES` flag
2. Launch `terminal64.exe /config:simulation/headless-tests/regression_5yr_no_g4.ini` headlessly
3. Parse Net Profit + per-slot deviation from journal
4. Verify Bucket A drift ≤ 25% (NFR-1.1) + per-slot deviation ≤ 10% (NFR-1.6)

Registered in `deferred-ac-registry.md` (paired bundle expiry 2026-05-19, blocks IMPL-062 numeric drain).

## SelfTest

- Case 1-2: per-slot pct multiplier table verification (riskMoney semantics — preserved numeric assertion)
- Cases 3-9: pre-existing — S percentTP factor / unknown slot guard / ClampLot floor+cap / NULL portfolio guards / J formula / J unwired-path
- **Case 10 NEW:** dimensional invariant — `_RiskMoneyToLot($100, 50pip, "C") / _RiskMoneyToLot($100, 100pip, "C") ≈ 2.0` (within 1% tolerance); plus `_RiskMoneyToLot($100, 0pip, "C")` returns 0.0 (fail-loud guard)

## Side-finding (out of FIX-006 scope; routes to IMPL-FIX-007 if observable drift)

**Slot_S pyramid stacking** — 16 same-direction Buy entries in 11 min at 30-60 sec cadence (00:05:30..00:16:59) on a continuous WPR-oversold + EMA-trend-aligned signal. Same defect class as `Slot_G2._HasActiveG2Order` race flagged in the IMPL-FIX-006 task block "Secondary concern" line — Slot_S has no `_HasActiveSOrder` guard. Final balance −$239 at end of 3-day window is attributable to this stacking + 60-pip drawdown, NOT to dimensional sizing (clamp count = 0). Monitor in 5-yr regression run; open IMPL-FIX-007 covering both G2 + S anti-pyramid gates if Bucket A drift > 25%.

## Evidence files

- This artifact: `docs/state/_session-handoff/IMPL-FIX-006-evidence-20260510.md`
- Decoded smoke log: `/tmp/fix006_smoke_decoded.txt` (local-only, 46,426 lines)
- Compile log: `MQL5/Experts/PhoenicisNex/PhoenicisNex.log` (local-only, UTF-16LE)
