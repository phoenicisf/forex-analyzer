# IMPL-FIX-011d Phase 2 iter-17 — Slot_K Predicate-Decision Telemetry Setup

**Date:** 2026-05-12
**Author:** Engineer (Opus 4.7, this session)
**Mode:** Auto · Option (a) from yesterday's iter-16 verdict (TL;DR: "Slot_K Phase 2 telemetry post-period-21 → find next blocker")
**Outcome:** ⚠️ **Telemetry harness landed; awaiting operator paired-canary run.** No verdict produced this session — engineer side prepared the discriminator emit.

---

## § 1. Background

iter-15 (commit `57397d7` 2026-05-11) telemetry surfaced cross-cutting Force-period defect (legacy 21 vs rewrite 13 at `services/IndicatorService.mqh::CreateHandles`). At 2021-02-16 20:00 with period=13:

```
rewrite Force values: f1=2.882, f2=-0.072, f3=1.538
legacy isFICrossUp primary  (F[1]>0.5 && F[2]>0   && F[3]<-0.2): f2=-0.072 < 0   → FAILS
legacy isFICrossUp alternate (F[1]>1   && F[2]<-0.2):              f2=-0.072 > -0.2 → FAILS
```

iter-16 (commit `ed6e742`/`4fb8a95` 2026-05-11) bulk-fixed the Force period in `IndicatorService.mqh`:

```mql5
m_handles[IDX_FORCE_H4] = iForce(_Symbol, PERIOD_H4, 21, MODE_SMA, VOLUME_TICK);
```

**iter-16 Q1 cross-slot verdict (mixed cascade):**

| Slot | rewrite entries | legacy | |Δ| | Verdict |
|------|----------------:|-------:|----:|---------|
| C    | 1 | 1 | 0 | ✅ matched |
| K    | 0 | 1 | 1 | ❌ STILL silent (Force-period was 1 of N blockers) |
| G    | 0 | 0 | 0 | ✅ improved (iter-13 1→0) |
| G2   | 1 | 0 | 1 | ⚠️ NEW spurious (different bucket from iter-9..12) |
| T    | 1 | 4 | 3 | ⚠️ entry-parity regressed; 4 iter-11 spurious DROPPED |
| M    | 1 | 2 | 1 | ⚠️ count drift |
| B/BR/D/H/P | 0 | 1 each | 1 | ❌ unchanged long-tail silence |

Slot_K |Δ|=1 unchanged from iter-13/14/15 → Force-period was a necessary (not sufficient) condition for K to fire.

---

## § 2. Hypothesis space (next blocker beyond Force-period)

Rewrite Slot_K has 4 entry conditions; with Force-period now correct, candidate blockers at 2021-02-16 20:00:

| Gate | Predicate | Block hypothesis |
|------|-----------|------------------|
| **G1** count_k_open | `_CountKOrders(port) >= InpKMaxOrders` | Unlikely — D1 guard typically prevents pyramid; if `m_last_order_d1_time > 0` from prior tick rolling state, gate could block. Telemetry confirms |
| **G2** D1 once-per-day | `iTime(D1,0) <= m_last_order_d1_time` | Possible if rewrite previously had a fire on this D1 bar that legacy didn't reach (no — both legs silent on prior K fires per iter-13 journal_diff K=0/1). Telemetry needed |
| **G3** Force crossover | `_IsFICrossUp(f) \|\| _IsFICrossDw(f)` | Most likely lifted by period-21; new f1/f2/f3 values must satisfy primary `(f1>0.5 && f2>0 && f3<-0.2)` OR alternate `(f1>1 && f2<-0.2)`. Telemetry quantifies |
| **G4** cloud-direction | `bid<cloud_low` (BUY) OR `bid>cloud_high` (SELL) | Possible if bid is INSIDE cloud — neither buy_signal nor sell_signal fires regardless of Force pass. Telemetry quantifies |

**Legacy comment `K,34,61,15,B,0.56,37.59`** suggests legacy reaches signal stage with depth-bars=34 + pip-distances + ratios — which means at minimum legacy passes its own gates 1-4 + the additional gates beyond rewrite scope (post-cross 300-bar scan, fractal pip-distance, isOverIchi, Hull-distance, etc per CodeWiki §3.5). Telemetry on rewrite gates 1-4 is sufficient to identify which of the 4 currently silences Slot_K.

---

## § 3. Telemetry harness (engineer-side this session)

### 3.1 Patch summary

`MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh`:

1. New private helper `_IsTargetDebugBar(ctx)` — gates emit to **2021-02-16 16:00..00:00 UTC** (covers legacy K H4 fire bar 20:00..00:00 + 1 bar of context before).
2. New private helper `_DebugEmitGate(ctx, gate, verdict, detail)` — `PrintFormat("[FIX011d-iter17-K][...]")` (mirrors Slot_T iter-10 pattern; survives any Logger severity filter).
3. Inserted **5 emit sites** in `Evaluate`:
   - `G1_count` — k_open vs InpKMaxOrders
   - `G2_d1guard` — iTime(D1,0) vs m_last_order_d1_time
   - `G3_force` — f1/f2/f3 + cross_up/cross_dw verdicts + threshold inputs
   - `G4_cloud` — bid vs cloud_low/cloud_high + buy/sell sig + position-vs-cloud label (BELOW/ABOVE/INSIDE)
   - `REACH` — final pre-OrderSend log (only emitted if all 4 gates passed; today this should NEVER emit per iter-16 verdict)

### 3.2 G1 verification

```
.ex5 produced fresh:  PhoenicisNex.ex5 mtime 2026-05-12 09:28:21 (post-edit Slot_K.mqh 09:27:25)
.compile.log Result:  0 errors, 0 warnings, 5694 ms elapsed
```

⚠️ Note: `.compile.log` mtime did not update on the 2nd refresh attempt (known MetaEditor caching quirk per `mt5-log-reader § Wine` — exit code unreliable). The `.ex5` was rebuilt successfully (352,226 bytes new). G1 PASS by .ex5 evidence.

### 3.3 Operator action required (Q1 canary run)

To produce iter-17 verdict, operator must:

1. **Free the foreground terminal** — close FBS-Demo BTCUSD chart per impl-plan operator action note (data-dir lock prevents headless launch)
2. **Run Q1 canary** (~5 min):
   ```bash
   bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
        simulation/headless-tests/q1_2021_canary.ini /tmp/iter17_run.txt
   ```
3. **Parse telemetry** — grep the Tester log for `[FIX011d-iter17-K]`:
   ```bash
   TESTER_LOG="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/<TID>/Agent-127.0.0.1-3000/logs/$(date +%Y%m%d).log"
   iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
     | grep -nE "\[FIX011d-iter17-K\]" \
     > docs/state/_session-handoff/IMPL-FIX-011d-iter17-telemetry-raw.txt
   ```

4. **Expected raw output shape** (one line per gate per tick within target window):
   ```
   [FIX011d-iter17-K][2021.02.16 16:00][G1_count][PASS] k_open=0 max=1
   [FIX011d-iter17-K][2021.02.16 16:00][G2_d1guard][PASS] d1_now=2021.02.16 00:00 last_order_d1=1970.01.01 00:00
   [FIX011d-iter17-K][2021.02.16 16:00][G3_force][BLOCK|PASS] f1=... f2=... f3=... cross_up=T|F cross_dw=T|F thr_hi=0.50 thr_lo=-0.20 alt_hi=1.00
   [FIX011d-iter17-K][2021.02.16 16:00][G4_cloud][BLOCK|PASS] bid=... cloud_lo=... cloud_hi=... buy_sig=T|F sell_sig=T|F pos_vs_cloud=BELOW|ABOVE|INSIDE
   ```

5. **Verdict path:**
   - First `BLOCK` per H4 bar identifies the discriminator
   - If REACH emits at 20:00..00:00 → all 4 gates pass + Slot_K fires (iter-17 ✅ closes parent S-AC #3)
   - If G3 BLOCKs → period-21 still doesn't satisfy crossover predicate → next blocker = Force values themselves (per-bar magnitude vs threshold inputs)
   - If G4 BLOCKs → bid INSIDE cloud → next blocker = cloud direction (architectural gap; legacy's mean-reversion path may have additional offsets or the cloud-edge tolerance differs)
   - If G1/G2 BLOCKs → state-machine drift (unexpected; would point to PortfolioState pre-population or D1 pre-stamp bug)

---

## § 4. Closure status

**S-AC #1** (Step 0 diagnostic) — already MET in 011d Phase 1 (commit `461ec46`).
**S-AC #2** (Slot_K patches G1-clean) — direction-fix structurally G1-clean; telemetry G1 PASS this session; awaits paired-canary outcome to determine if further patches needed.
**S-AC #3** (Slot_B |Δ|≤1; **engineer reading**: parent S-AC pivots to whichever long-tail slot Phase 1 targets — currently Slot_K) — STILL NOT MET (iter-16 |Δ|=1 unchanged); iter-17 telemetry → next-blocker discovery → next-session patch.
**S-AC #4** (G2 smoke ≥ $200) — pending.

**Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25 (FIX sub-ticket Phase 2 partial does not increment per workflow.md Gate #4 + fix-round-10 precedent).

**Phase 5 mechanical gates:**
- Gate 1 (forbidden-pattern grep) — N/A this session (no AC `[x]` flips)
- Gate 6 (file integrity) — verified `## End of Plan` single-instance preserved post-edit
- Gate 11 (working-tree clean) — pending commit

---

## § 5. Operator next-decision options

After running canary + parsing telemetry:

- **(a)** Apply patch indicated by first-BLOCK gate → iter-18 re-canary
- **(b)** If G3 BLOCKs and Force values look "right but predicate too strict" → calibrate `InpKFICrossThreshHigh/ThreshLow/AltHigh` inputs (no code change; input-tuning iteration)
- **(c)** If G4 BLOCKs (bid INSIDE cloud) → architectural patch: add cloud-edge tolerance OR widen direction predicate per CodeWiki §3.5 detail (read post-cross 300-bar scan for context)
- **(d)** Defer 011d Phase 2 → continue with Slot_B Phase 1 (independent of Slot_K Force-period chain)
- **(e)** Accept Slot_K silence as recoverable margin → hand-off to Phase 4 paired-bundle drain

---

## § 6. Files changed this session

| File | Net LOC | Description |
|------|--------:|-------------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh` | +56 / -3 | 2 new private helpers (`_IsTargetDebugBar`, `_DebugEmitGate`) + 5 emit sites in `Evaluate` |
| `docs/state/_session-handoff/IMPL-FIX-011d-k-phase2-iter17-telemetry-20260512.md` (this file) | NEW | Engineer-side setup + operator handoff |
