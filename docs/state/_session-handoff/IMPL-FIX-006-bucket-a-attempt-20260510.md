# IMPL-FIX-006 Bucket A Drain Attempt — 2026-05-10

**Status:** 🔴 **DRAIN HALTED** — IMPL-FIX-007 (Slot_G2 + Slot_S anti-pyramid race) blocking.
**Outcome:** Bucket A regression halted day-1 again ($411.43 final balance vs $24.27M baseline). Drift ≈ 100% — far exceeds NFR-1.1 ≤ 25% target.

## Scope of this attempt

After IMPL-FIX-006 (RiskManager.ComputeLot dimensional formula) + IMPL-063 structural closure earlier today, the user authorized paired-bundle 5-yr regression drain. This artifact captures the Bucket A run only — Bucket B aborted because the dimensional fix is insufficient on its own.

## Run setup

- Build: `#define DISABLE_G4_FIXES` prepended to `PhoenicisNex.mq5` (IMPL-062 Bucket A reference build)
- Compile: G1 PASS `Result: 0 errors, 0 warnings, 4199 ms`
- Tester ini: `simulation/headless-tests/regression_5yr_no_g4.ini` (Model=4 every-real-tick, 2021.01.01–2025.12.31, deposit=$1000, leverage=1:500)

## Run outcome

| Metric | Value |
|--------|-------|
| Wall-clock (test execution only) | 1m 46.245s (test thread) / 2m 13s (process from launch to exit) |
| Simulated time advanced | 5 H4 bars (2021.01.04 00:00 → 16:56) — same day-1 halt pattern as run #1 (2026-05-10) |
| Ticks processed | 68,584 |
| Final balance | **$411.43** (was $512.80 in run #1; somehow worse) |
| `OnTester result` | 411.43 |
| Stop-out attribution | "stop out occurred on 0% of testing interval" — broker margin-call cascade, end-of-test forced position closures |

## Empirical signals

| Signal | Pre-fix (run #1 2026-05-10) | Post-FIX-006 (this run) | Interpretation |
|--------|------------------------------|--------------------------|----------------|
| `[ev=order_sent]` count | 5 | **80** | More entries (size dimensional now → margin guard fires later) |
| `[ev=clamp_applied]` count | every order | **0** | ✅ IMPL-FIX-006 dimensional fix verified |
| `[ev=order_failed]` count | 31,409 (RC=10019) | 0 | ✅ NO_MONEY storm gone |
| `[ev=order_skipped_no_margin]` | (not yet implemented) | 1 | ✅ IMPL-FIX-005 anti-spam latch fires once |
| Per-slot `order_sent` distribution | C/Q/G2 (mixed) | **76/80 = 95% Slot_G2**; C/M/Q/T = 1 each | 🔴 **G2 anti-pyramid race confirmed** |

## Root cause (NEW — IMPL-FIX-007 scope)

`Slot_G2._HasActiveG2Order()` uses `port.GetTicketsForSlot(MAGIC_G, "G2,", tickets)` to gate entries. Same pattern in `Slot_S._HasActiveSOrder()`. Both gates check PortfolioState's per-magic ticket list.

**The race:** `PortfolioState` is populated via `OnTradeTransaction` event handler (per ADR-005 + IMPL-007 contract). `RiskManager::OpenOrder` calls `OrderSend` and on `TRADE_RETCODE_DONE` writes a journal entry — but does NOT synchronously update PortfolioState. The next `OnTick` invocation re-evaluates Slot_G2; if `OnTradeTransaction` hasn't yet fired for the prior fill, `GetTicketsForSlot` returns 0 → anti-pyramid gate misses → second order fires.

**Evidence (from this run's Tester log):**

```
2021-01-04 16:00:00 ticket=6  G2 BUY 0.10 @ 1.23025 (first fill)
2021-01-04 16:00:02 ticket=7  G2 BUY 0.10 @ 1.23022 (2 sec later — gate failed)
2021-01-04 16:00:02 ticket=8  G2 BUY 0.10 @ 1.23025 (same second as #7)
2021-01-04 16:00:03 ticket=9  G2 BUY 0.10 @ 1.23025
2021-01-04 16:00:03 ticket=10 G2 BUY 0.10 @ 1.23022
2021-01-04 16:00:03 ticket=11 G2 BUY 0.10 @ 1.23022
2021-01-04 16:00:04 ticket=12 G2 BUY 0.10 @ 1.23021
2021-01-04 16:00:04 ticket=13 G2 BUY 0.10 @ 1.23017
2021-01-04 16:00:04 ticket=14 G2 BUY 0.10 @ 1.23017
2021-01-04 16:00:04 ticket=15 G2 BUY 0.10 @ 1.23018
... (76 G2 fills total within ~4-15 minutes window) ...
```

10 fills in 4 seconds (2021-01-04 16:00:00..04) at near-identical prices = textbook OrderSend / OnTradeTransaction race.

## Action

1. ✅ Default build restored (`#define DISABLE_G4_FIXES` removed; G1 PASS clean — flag NOT in mainline)
2. ✅ IMPL-FIX-007 task block authored in `docs/state/impl-plan.md` — Slot_G2 + Slot_S synchronous anti-pyramid latch (immediate in-memory flag set on OrderSend success; reset by OnTradeTransaction confirmation OR timeout)
3. ✅ IMPL-FIX-006 / IMPL-062 / IMPL-063 deferred-AC bundles updated in registry — paired-bundle drain BLOCKED on IMPL-FIX-007 implementation
4. ⏸ Bucket B drain NOT attempted (would exhibit identical defect pattern; G4 fixes target J + BI, not G2)
5. ⏸ R-8 closure pending IMPL-FIX-007 + retry of Bucket A drain

## Files

- This artifact: `docs/state/_session-handoff/IMPL-FIX-006-bucket-a-attempt-20260510.md`
- Decoded Tester log delta: `/tmp/bucket_a_decoded.txt` (4.2 MB, 10,237 lines, local-only)
- Compile log: `MQL5/Experts/PhoenicisNex/PhoenicisNex.log` (UTF-16LE, local-only)
- Tester source: `/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Tester/A12EC900AF5AF5023ECB36F7FB72E396/Agent-127.0.0.1-3000/logs/20260510.log` (cumulative)
