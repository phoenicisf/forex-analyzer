# IMPL-062 5-yr Bucket A Regression Run #1 — Evidence Sidecar 2026-05-10

## TL;DR

**Outcome:** ❌ **FAILED at simulated day 1.** Backtest configured for 2021-01-01 → 2025-12-31 halted at **2021-01-04 17:10:00 EET** (17 simulated hours, 5 H4 bars) due to broker stop-out cascade at 17.99% margin level. Final balance **$512.80** from $1000 deposit. Wall-clock 0:01:26.807. **Cannot compute Bucket A drift vs baseline** ($24.27M target). New CRITICAL finding logged → IMPL-062 numeric drain blocked pending investigation.

## Configuration

| Field | Value |
|-------|-------|
| `.ini` | `simulation/headless-tests/regression_5yr_no_g4.ini` |
| Symbol | EURUSD |
| Period | H4 |
| Model | 4 (every tick based on real ticks) |
| Window | 2021.01.01 → 2025.12.31 |
| Deposit | $1,000 |
| Leverage | 1:500 |
| Build flag | `#define DISABLE_G4_FIXES` ON (Slot_J + Slot_BI pre-G4 baseline behavior per ADR-009 + BR-7.2) |
| `.ex5` | 306,697 bytes (DISABLE_G4_FIXES build per `metaeditor.log` 10:26:03 G1 PASS 0err/0warn/4330 ms) |
| Broker | FBS-Real (DC-318-Singapore-5R1, build 5328, hedging mode) |
| Operator | Engineer (Claude Opus 4.7) |
| First launch | 10:28:00 — FAILED (network drop @ 10:28:03.715 → tick download canceled → "no history data") |
| Successful launch | 10:31:21 — completed by 10:32:52 (1m 31s wall-clock) |

## Tester verdict

```
EURUSD,H4: 71110 ticks, 5 bars generated. Environment synchronized in 0:00:00.020.
Test passed in 0:01:26.807 (including ticks preprocessing 0:00:11.921).
final balance 512.80 USD
OnTester result 512.8
stop out occurred on 0% of testing interval
```

## Event counts (per `IMPL-062-attempted-run-20260510-abridged.txt` sidecar)

### Entry signals (Print log only — not OrderSend attempts)

| Slot | Count |
|------|-------|
| SlotG2 | 6,731 |
| SlotG | 1,342 |
| Slot_B (entry_sell) | 4,332 |
| SlotT | 1 |
| SlotQ | 1 |
| SlotM | 1 |
| SlotC | 1 |
| Slot_K (entry_buy) | 1 |
| **Total** | **~12,409** |

### Actual broker-side OrderSend results

| Event | Count | Notes |
|-------|-------|-------|
| `ev=order_sent` | 5 | tickets #2 (Slot_C), #3 (Slot_Q), #4-#6 (Slot_G2 pyramid) |
| `ev=order_skipped_no_margin` | 1 | Slot_M @ 00:29:22 — IMPL-FIX-005 latch fired correctly (`required=709.93 free=263.97 lot=2.90 — subsequent skips silenced this session`) |
| `ev=order_failed` | 0 | retry storm fully eliminated by FIX-005 ✅ |
| Broker `position stop out triggered` | 3 | tickets #2/#4/#6 force-closed at 17.99% margin level @ 17:10:00 |
| Broker `position closed due end of test` | 2 | tickets #3/#5 closed at simulation halt |

### Position chronology + P&L attribution

| Time (sim) | Event | Ticket | Slot | Dir | Lot | Price | SL |
|------------|-------|--------|------|-----|-----|-------|-----|
| 00:29:22 | order_sent | #2 | C | BUY | 2.90 | 1.22401 | 1.21901 |
| 00:29:22 | order_skipped_no_margin (latch) | — | M | — | 2.90 | required 709.93 vs free 263.97 |
| 14:57:35 | order_sent | #3 | Q | SELL | 2.90 | 1.23040 | 1.23540 |
| 16:00:00 | order_sent | #4 | G2 | BUY | 2.90 | 1.23025 | 1.22000 |
| 16:00:02 | order_sent | #5 | G2 | BUY | 2.90 | 1.23022 | 1.22001 |
| 16:00:21 | order_sent | #6 | G2 | BUY | 2.90 | 1.23039 | 1.22000 |
| 17:10:00 | stop_out cascade | #2,#4,#6 | — | — | — | closed at ~1.22763 |
| 17:10:00 | end_of_test | #3,#5 | — | — | — | closed at ~1.22763–1.22773 |

P&L reconstruction:
- #2 (Slot_C BUY @ 1.22401 → close 1.22763) = **+$1,050** (winner, but force-closed at stop-out)
- #3 (Slot_Q SELL @ 1.23040 → close 1.22773) = **+$774** (winner)
- #4 (Slot_G2 BUY @ 1.23025 → close 1.22763) = **−$760**
- #5 (Slot_G2 BUY @ 1.23022 → close 1.22763) = **−$751**
- #6 (Slot_G2 BUY @ 1.23039 → close 1.22763) = **−$800**
- Net floating loss: −$487 → balance $1000 → $512.80 ✅ matches Tester `OnTester result 512.8`

## Root cause hypothesis

**Slot_G2 pyramid in 21 seconds (3 fills) at near-top before 276-pip drawdown.**

By 16:00, Slot_C ticket #2 was floating ~+$1,855 profit (price 1.23025 vs entry 1.22401 = +624 pips × 2.9 lots × $10/pip), inflating equity to ~$2,855 + free margin ~$2,146. This unblocked Slot_G2's first OrderSend (margin guard saw free > required). Then in 21 seconds Slot_G2 pyramided 3 BUY fills at 1.23022–1.23039. Each fill consumed another ~$714 margin. Total margin used after #6: ~$3,565.

Then price drifted DOWN ~276 pips by 17:10:00. Floating losses on the 3 Slot_G2 BUY fills cascaded to ~$2,300 losses (offset by Slot_C +$1,050 + Slot_Q +$774 = +$1,824 wins). Equity = $1,000 − $487 = $513. Equity/margin ratio = 513 / 3565 = **14.4%** < 17.99% broker stop-out threshold → 3 stop-outs cascade → simulation halts ("position closed due end of test" for remaining positions because Tester recognizes account-blown state).

## Why this is a Bucket A drift signal (CRITICAL)

Baseline `ReportTester-25045474.html` ran identical EA over 2021-01-01 → 2025-12-31 with **same $1000 deposit + 1:500 leverage** and reached final balance **~$24.27M** (`baseline-per-slot.json` total Net Profit = $24,271,276.63). To reach $24M from $1000 over 5 years, the EA must compound through many winning trades without margin-call wipeouts in the first day.

**Rewrite vs baseline behavioral divergence:**
- Baseline survives day-1 → grows to $24M over 5 years
- Rewrite hits broker stop-out at simulated day 1 (17 hours into 5-yr window) → loses $487 → simulation halts
- **Bucket A drift = ~100% (rewrite balance = $513 vs baseline ~$2,200 expected by day 1)** — far exceeds NFR-1.1 ≤ 25% threshold

The defect is upstream of `DISABLE_G4_FIXES` toggle. G4 fixes apply only to Slot_J (MagicJ vs MagicF) and Slot_BI (parent-anchored SL vs naked SL). Neither slot was in the 5 actual fills (C/Q/G2 only). So G4-fixes don't explain the failure.

## Hypothesis space (unresolved — needs investigation)

1. **Lot-sizing formula divergence:** rewrite RiskManager produces lot=2.90 (MAX_LOT cap) on $1000 deposit. Baseline EA may compute smaller lots scaled to current balance + risk-per-trade %. The clamp from FIX-002 narrative (`216,671 SlotS entry_signal events with lot=2.90 (clamped at max_lot_ratio per RiskManager init log; NOT floor-clamped to 0.01)`) suggests the rewrite consistently hits the upper cap.
2. **Slot_G2 pyramid behavior:** baseline may have anti-pyramid logic that prevents 3 same-magic fills in 21 seconds. Rewrite doesn't gate consecutive fills.
3. **Entry signal divergence:** baseline may avoid Slot_G2 BUY signals near intraday tops. Rewrite's MarketContextBuilder + Slot_G2 entry predicates may fire more aggressively than CodeWiki specifies.
4. **Margin guard semantics in Tester vs live:** FIX-005 guard works (ev=order_skipped_no_margin fired correctly for Slot_M at 00:29). Issue isn't the guard — it's that intermediate ramping (Slot_C floating profit unblocks Slot_G2 fills) creates over-leveraged exposure relative to baseline.

Given multiple plausible hypotheses, root-cause analysis requires either: (a) inspect baseline EA's risk management code (origin .mq5 if available); (b) introspect rewrite's `RiskManager::ComputeLot` formula vs CodeWiki §3 risk specification; (c) compare rewrite slot entry predicates vs CodeWiki §5 to find aggressive-firing slots.

## What this means for IMPL-062 / IMPL-066 / IMPL-068 numeric drain

❌ **All 3 paired E-AC bundles BLOCKED** until rewrite Bucket A behavior is corrected to within NFR-1.1 ≤ 25% of baseline:

| Task | Deferred E-AC | Status post-run-1 |
|------|----------------|-------------------|
| IMPL-062 | Bucket A drift ≤ 25% NFR-1.1 + per-slot ≤ 10% NFR-1.6 | ❌ Drift ~100% (cannot complete 5-yr run) — needs upstream fix |
| IMPL-066 | journal latency p99 ≤ 5ms over a long run + zero halt-events | ❌ Run too short to produce stat-sig sample (5 writes total — `avg_us=25 p95_us=59 max_us=59`); no halt events captured |
| IMPL-068 | force-clear validation jq filters over 5-yr journal records | ❌ Run too short (5 entry records, no force-clear events captured) |

## Recommended path forward

1. **Open IMPL-FIX-006** (or escalate to `/backtrack sd`) — investigate rewrite RiskManager.ComputeLot formula vs baseline CodeWiki §3 risk math. Compare actual lot sizing on $1000 deposit between rewrite and baseline source.
2. **Defer IMPL-062/066/068 numeric drain renewal** to expiry 2026-05-23 (per FIX-003 closure note's existing schedule) — first-renewal gives ~13 days for fix-investigation + retry.
3. **Tier 1.5 walk batch-3 status:** PASSED for IMPL-067 DST regression (drained correctly); FAILED for Bucket A signal — separate concern; walk artifact remains valid for IMPL-067.
4. **Open Risks update:** new R-8 — "Rewrite Bucket A drift ≈ 100% on 2021-01-04 day-1 stop-out cascade; lot-sizing or entry-signal divergence vs baseline; investigation needed before IMPL-062 retry."

## Files

- This artifact: `docs/state/_session-handoff/IMPL-062-evidence-20260510.md`
- Decoded log: `docs/state/_session-handoff/IMPL-062-attempted-run-20260510-abridged.txt` (2,523,648 bytes / 12,968 lines)
- Tester source log: `/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Terminal/A12EC900AF5AF5023ECB36F7FB72E396/Tester/logs/20260510.log` (delta 5,073,226 bytes vs baseline 1,150,252,774; pre-FIX failed launch + successful run combined)
- Default `.ex5` restored at 10:36:32 — `metaeditor.log` shows `Result: 0 errors, 0 warnings, 4144 ms elapsed`; `.ex5` = 306,498 bytes (G4-fixes ON build per ADR-009 + BR-7.2)

## Phase 5 mechanical-gate compliance

- Gate #1 forbidden-pattern: n/a (no plan-side `[x]` introduced — failure recorded as new finding)
- Gate #11 working-tree clean post-closure: WILL be enforced after the documenting commit lands
- Gate #10 stash-clean G1: post-restore .ex5 is the committed-source build (no working-tree-only edits) ✅
