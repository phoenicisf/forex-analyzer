# IMPL-FIX-011 Option A Session 1 — Slot_T Architectural Gap Diagnostic

**Date:** 2026-05-11
**Author:** Engineer (Opus 4.7, this session)
**Mode:** Auto · Option A targeted predicate calibration · Session 1 of Slot_T deep-dive
**Outcome:** ⚠️ **Diagnostic only — NO code edits this session.** Architectural gap too deep for single-session threshold calibration. Recommend Option B `/impl-plan-review all` or scope expansion.

---

## § 0. TL;DR

Compared rewrite `CSlotT::Evaluate` (post-Session-C HEAD `b9079c7`) vs legacy `BusinessLogic_T` + `BusinessLogic_PendingT` (lines 18414-19190 of `PhoenicisN2.10_stable.mq5`). Found **6 distinct architectural divergences** — not threshold mismatches. The Session C approach (CodeWiki §3.15 spec → predicate translation) missed the actual implementation depth because CodeWiki §3.15 is a high-level summary that doesn't capture the 2-phase pending state machine + 4 sub-path resolution + indicator dependencies that legacy uses.

**Quantitative prognosis:**
- Slot_T |Δ|=3 entry + 3 exit cannot drop to ≤0-1 via threshold tuning alone. Closing this gap requires **new MarketContext fields + new pending state machine sub-paths + new indicators (Fractal)** — a 3-5 session architectural rewrite specific to Slot_T.
- The same depth is likely required for Slot_G and Slot_G2 (also failed Session C). Total Option A cost may be 9-15 sessions rather than the projected 3-6.

**Recommendation:** Engineer recommends **escalating to Option B `/impl-plan-review all`** — re-validate IMPL-FIX-011 task decomposition + AC dual-track. The ≥75% gate is unrealistic given the architectural depth required. Decompose into per-slot fix tickets (IMPL-FIX-011a Slot_T / 011b Slot_G2 / 011c Slot_G) with realistic 4-6 session budgets each, OR adjust the AC #4 threshold to acknowledge Phase 1 partial-parity acceptable (e.g., 50% reduction + ±25% Net Profit drift) with full parity deferred to Phase 2.

---

## § 1. Legacy Slot_T architecture (decoded from `PhoenicisN2.10_stable.mq5`)

### 1.1 Two-phase pending state machine

Legacy Slot_T has TWO distinct entry paths gated on pending state:

**`BusinessLogic_T` (line 18414)** — runs when no positions AND no pending:
- Computes `pricePercentRange = CalculatePercentage(BollBTopBuffer[0], BollBBotBuffer[0], _bidPrice)` (BB% scale 0-100)
- Computes `adxwValidText = (IDXWMain[1]<IDXWPlus[1] && IDXWMain[1]<IDXWMinus[1]) ? "B" : "A"` (ADX dominance flag)
- **BUY outer gate (line 18449):** `((Hull[0]<H4Support.hi && H4Support.hi>0) || (Hull[0]<D1Support.hi && D1Support.hi>0)) && pricePercentRange < 5`
- **SELL outer gate (line 18644):** mirror with Resist + pricePercentRange > 95
- Inside outer gate, **5 distinct sub-paths SET pending state then return:**

| Sub-path | Trigger condition | Pending date scope | Comment when resolved |
|---|---|---|---|
| **TB** (`adxwValidText=="B" && IsBUseNearCrossIchi`) | NearCross + ADX-B | H4 bar | `T,P,...` |
| **TB** (`adxwValidText=="B" && __countValidBand<7 && !isDay`) | NearCross + insufficient cloud + non-Day | H4 bar | `T,P,...` |
| **TD** (`isDay && DEM[0]>0.45` BUY / `DEM[0]<0.55` SELL) | DEM trigger on isDay | H4 bar | `T,P,...` |
| **THAF** (`zone_strength==ZONE_PROVEN && !isDay`) | Strong zone non-Day | **M1 bar** (different cadence!) | `T,PF,...` |
| **THAF** (`zone_hit>=2 && DEM>0.41/<0.59 && !isDay`) | Multi-hit zone | H4 bar | `T,PF,...` |
| **TDWD** (`isDay && !(validBBTop && validBBBot)`) | isDay + cloud edge violation | H4 bar | `T,PW,...` |

- **Fall-through (direct OpenOrder)**: only if ALL sub-paths fail → comment `T,H/D,A/B,DEM,IsBUse,zone_strength,zone_hit,SL`
- SL formula: `MathMax(_diffHullWith0, _diffBB, 90 floor if BBTop>ICHI_CLOUD_LOW)` where `_diffHullWith0 = (BollBMid[hullThisWaveStartBars-1] - BollBMid[0])` pip-converted

**`BusinessLogic_PendingT` (line 18842)** — runs when pending exists:
- Expiry: pendingIndex > 40 (or > 17 for THAF) → revoke
- 5 distinct trigger sub-paths gated on `TXOrderPendingType`:

| Sub-path | Trigger condition for OpenOrder | Comment |
|---|---|---|
| **TB/TD BUY** | `DEM>0.35` failsafe + `Sto<20` + `__countPeakBand>=countPeakBandThreshold` + `bid<BBBot[1]` + `bid<latestPeakPrice` (countPeakBand = bars where Low<BBBot within pendingIndex history) | `T,P,A/B,DEM,IsBUse` |
| **THAF BUY** | `pendingIndex>3 && FractalLow[3]<Hull[3] && ask<midH4_1 && ratioPriceSubDem<30` | `T,PF,A/B,DEM,IsBUse` |
| **THADEM BUY** | `pendingIndex>1 && (>=2 bars Low<BBBot in history)` | `T,PD,A/B,DEM,IsBUse` |
| **TDWD BUY** | `pendingIndex in (1,30) && ADX-A dominance + BBTop<IchiMin && ask<BBMid && BBTop[1]>IchiMin` | `T,PW,A/B,DEM,IsBUse` |
| (SELL mirrors) | same with direction inverted | `T,P/PF/PD/PW,...` |

### 1.2 Legacy Q1 2021 entries (from `IMPL-FIX-011-q1_legacy_202605102037.txt`)

| Date | Comment | Path | Sub-path verdict |
|---|---|---|---|
| 2021-01-06 02:50 | `T,H,B,0.61,0,V,1,108` SELL | **direct main-path** | All pending sub-paths failed → fall-through |
| 2021-01-19 01:02 | `T,PF,A,0.28,0` SELL | **PendingT THAF** | THAF set earlier; Fractal trigger fired here |
| 2021-02-26 04:00 | `T,PF,B,0.54,0` SELL | **PendingT THAF** | Same — THAF Fractal trigger |
| 2021-03-30 10:46 | `T,H,A,0.27,0,V,1,145` BUY | **direct main-path** | All pending sub-paths failed → fall-through |

**Distribution:** 2 of 4 legacy entries come from THAF-Fractal resolution (a pending state path with Fractal indicator). 0 of 4 come from the "single composite predicate fires immediately" pattern that rewrite implements.

---

## § 2. Rewrite Slot_T architecture (post-Session-C)

`CSlotT::Evaluate` Phase A:
- IDLE → `_IsTBuyBaseSignal` AND/OR `_IsTSellBaseSignal` → if either true, `EnterPending(PM_T, payload)` then return

`_IsTBuyBaseSignal` composite (5 conditions, ALL must be true):
1. `_IsTBuySupportZone`: `has_support && bb_pct < 5`
2. `_IsPriceAboveHull`: `bid > hull`  ← **BUG: legacy inverted (BUY requires bid <= hull)**
3. (no-op TRUE: §3.15:3 opposing G/B/R sells)
4. `_BBTopBelowIchiMaxCount >= 7`: count of last 10 bars where `bb_top[i] < ichi_max[i]` (where `ichi_max = MathMax(cloud_high, tenkan[0], kijun[0])`) ← **BUG: legacy uses `MathMin(SenkouA[z], SenkouB[z])` per-bar (cloud_low at bar z, NOT cloud_high)**
5. `_IsAdxDominant`: `adx > InpTAdxMin`

`CSlotT::Evaluate` Phase B:
- PENDING → `_IsTBuyTrigger` (which just re-runs `_IsTBuyBaseSignal`) → if true, `OpenOrder` → `TransitionExecuted`
- ALL pending entries fire with the SAME composite predicate; no sub-path differentiation

`_ResolveTSubPath`: just `(dem >= 0.45) ? "D" : "H"` — used for COMMENT only, not for distinct trigger logic.

`_ComputeTSlPips`: `MathMax(hull_dist_pips, bb_width_pips, 90)` where `hull_dist_pips = (bid - hull) / pip_size` (current-bar only) — legacy uses `(BollBMid[hullThisWaveStartBars-1] - BollBMid[0])` (wave-anchor distance — multi-bar).

---

## § 3. Divergence inventory (6 architectural gaps)

| # | Gap | Legacy | Rewrite | Severity | Fix scope |
|---|---|---|---|---|---|
| **A** | **Hull direction inversion** | BUY: `bid <= Hull` (mean-reversion oversold) | BUY: `bid > Hull` (trend-following) — **OPPOSITE** | 🔴 CRITICAL signal inversion | 2-line surgical fix in `_IsPriceAboveHull`/`_IsPriceBelowHull` |
| **B** | **Ichi cloud edge — wrong field + wrong scan field** | `BollBTop[z] < MathMin(SenkouA[z], SenkouB[z])` (BB top below cloud bottom) | `bb_top[i] < MathMax(cloud_high, tenkan[0], kijun[0])` (BB top below cloud TOP using current-bar tenkan/kijun) | 🔴 CRITICAL semantic mismatch | Need new MarketContext field `ichi_h4_history.cloud_low[15]` + rewrite `_IchiMaxH4` semantics. Beyond 1-line fix. |
| **C** | **Pending sub-path resolution missing** | 5 distinct sub-paths set different pending sub-types (`TB`/`TD`/`THAF`/`THADEM`/`TDWD`); each has different trigger logic in `BusinessLogic_PendingT` | Single composite predicate; sub-path is just a COMMENT label, no distinct trigger logic | 🔴 CRITICAL architectural | Need 5-state pending sub-type field in PMR payload + 5 distinct trigger predicates in Phase B. New work item. |
| **D** | **Fractal indicator missing** | `FractalLowBuffer[3]` + `FractalUpBuffer[3]` gate THAF triggers (2 of 4 Q1 entries) | No Fractal indicator wired | 🔴 CRITICAL — blocks 50% of legacy Q1 fires | Add `IDX_FRACTAL_H4` handle + `MarketContext.fractal_h4` field + populate at builder. New work item. |
| **E** | **Zone strength / zone_hit metadata** | `SubDemCalcModelH4Support.strength == ZONE_PROVEN` + `.zone_hit >= 2` gate THAF paths | `subdem_h4.has_support` boolean only; no strength/hit count | 🟠 HIGH | Extend `MarketContext.subdem_h4` with `strength` enum + `zone_hit` int. Mid-scope work item. |
| **F** | **SL anchor uses wrong distance** | `_diffHullWith0 = (BollBMid[hullThisWaveStartBars-1] - BollBMid[0])` — wave-anchored multi-bar | `(bid - hull) / pip_size` — current-bar only | 🟠 HIGH | Add `_HullThisWaveStartBars(direction, scope)` helper + history scan logic. Mid-scope. |

---

## § 4. Q1 entry prognosis under hypothetical fixes

### 4.1 Single-session fix (Fix A only — Hull direction inversion)

| Bucket | Legacy fires? | Rewrite fires currently (iter-3)? | Rewrite fires after Fix A? | Net effect |
|---|---|---|---|---|
| 2021-01-06 02:50 SELL | ✅ `T,H,B` direct | ❌ | ❓ Need bb_pct>95 ✓ + ask>=Hull ✓ + 10/7 BB>cloud_max ❓ + ADX-dom ❓ + zone-resist ❓ — partial match possible | uncertain — likely still ❌ |
| 2021-01-19 01:02 SELL | ✅ `T,PF` THAF | ❌ | ❌ (Fractal missing) | unchanged ❌ |
| 2021-02-26 04:00 SELL | ✅ `T,PF` THAF | ❌ | ❌ (Fractal missing) | unchanged ❌ |
| 2021-03-11 08:00 BUY | ❌ | ✅ rewrite-only | ❌ after Fix A (bid > Hull was the spurious trigger) | suppressed → 0 |
| 2021-03-30 10:46 BUY | ✅ `T,H,A` direct | ❌ | ❓ Need bb_pct<5 ✓ + bid<=Hull ✓ + 10/7 BB<cloud_min ❓ — partial | uncertain |

**Best-case Fix A only:** rewrite goes from 1 (wrong bucket) to maybe 1-2 (right buckets) → T/entry |Δ| stays at 3 OR drops to 2-1. **Worst-case:** rewrite goes from 1 → 0 (all conditions miss after correction) → T/entry |Δ| INCREASES to 4. Either way, the 75% gate cannot be met by Fix A alone.

### 4.2 What it takes to hit ≥75% reduction on Slot_T alone

To hit 0 entries on rewrite that legacy doesn't fire AND fire all 4 legacy buckets, rewrite needs:
- Fix A (Hull direction) ✓ 2-line
- Fix B (Ichi cloud edge field + history) ✓ ~50 LOC + MarketContext extension
- Fix C (5-state pending sub-path) ✓ ~150 LOC + PMR payload schema change
- Fix D (Fractal indicator wiring) ✓ ~80 LOC + IndicatorService + MarketContext extension
- Fix E (zone strength + zone_hit metadata) ✓ ~50 LOC + MarketContext extension
- Fix F (Hull wave-anchor SL) ✓ ~60 LOC + helper

**Total estimate: ~400 LOC across 5+ files + 3 new MarketContext fields + 1 new indicator handle.**

Per workflow.md size detection: this is **L-XL scope per slot** — should not arrive at engineer as a single ticket per CLAUDE.md §6 / impl-plan size rules. Belongs in `/impl-plan-review` decomposition.

### 4.3 Extrapolation to Slot_G2 + Slot_G

Session C also failed for G2/G with similar pattern (bucket-shifted history-dependent predicates). Slot_G2 (CodeWiki §3.7) and Slot_G (§3.6) likely have similar architectural depth — pending state machines, multi-bar histories, indicator dependencies not in MarketContext.

**If Slot_T = 400 LOC × 5+ sessions, total Option A for {T, G2, G} ≈ 1,200 LOC × 12-15 sessions.** Not 3-6 as originally estimated.

---

## § 5. Recommendations

### 5.1 Primary recommendation — escalate to Option B

`/impl-plan-review all` to re-validate IMPL-FIX-011 task decomposition. Specifically:

1. **Split IMPL-FIX-011 into 3 separate fix tickets:**
   - `IMPL-FIX-011a` Slot_T architectural alignment (5-7 sessions; ~400 LOC; new MarketContext fields)
   - `IMPL-FIX-011b` Slot_G2 architectural alignment (similar depth)
   - `IMPL-FIX-011c` Slot_G architectural alignment (similar depth)
   - `IMPL-FIX-011d` Slot_B + remaining long-tail slots (legacy fires; rewrite silent)

2. **Adjust S-AC #4 threshold:** the ≥75% reduction gate was authored before architectural depth was known. Realistic Phase 1 target may be 30-50% reduction with the understanding that full parity is Phase 2 scope.

3. **Re-validate Phase Hint Alignment:** if these architectural fixes are P4 scope, they should be planned tasks not FIX tickets. Consider promoting to `IMPL-069/070/071` if SD doesn't already cover.

### 5.2 Secondary recommendation — if operator wants Option A continuation anyway

Make Fix A (Hull direction inversion — 2 lines) + Fix B partial (extend `ichi_h4_history.cloud_low[15]` field + use in `_BBTopBelowIchiMaxCount`) in next session. Re-canary; expected outcome: marginal improvement (maybe 33% → 40-50% on top-5) but NOT ≥75%. Use empirical result to inform Option B decomposition.

### 5.3 NOT recommended — speculative threshold tuning

Adjusting `InpTBBHistMinAboveCount` from 7 to 5 or 9, or `InpTBollBandPctBuy` from 5 to 8 — these don't address the architectural gaps. Would burn wall-clock without empirical gain. (This was the iter-2 falsification pattern for Slot_G2.)

---

## § 6. State Reconciliation

This session NO MQL5 source changes — diagnostic only.

| Artifact | Status |
|---|---|
| `MQL5/Experts/PhoenicisNex/slots/Slot_T.mqh` | unchanged |
| `MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh` | unchanged |
| `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh` | unchanged |
| `docs/state/_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` (this file) | NEW |

No iter-4 re-canary this session — diagnostic doc IS the deliverable. Operator decision required to proceed with either:
- (a) Continue Option A with reduced expectations (Session 2 = Fix A + partial Fix B)
- (b) Escalate to Option B `/impl-plan-review all` (engineer recommended)
- (c) Continue Option A as originally scoped (~12-15 sessions for {T, G2, G})

**No Phase 5 mechanical gate triggers** — this is a diagnostic artifact commit, not a task closure. Plan Staleness Sentinel unchanged.
