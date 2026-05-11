# IMPL-FIX-011c Step 0 — Slot_G Architectural Gap Diagnostic

**Date:** 2026-05-11
**Author:** Engineer (Opus 4.7, this session)
**Mode:** Auto · Option (a) IMPL-FIX-011c scope-pivot post-IMPL-FIX-011b closure · read-only legacy-source decode
**Outcome:** ⚠️ **Diagnostic only — NO code edits this session.** Output = enumerated gap table + Q1 trigger bucket list for `/impl-task IMPL-FIX-011c` Phase 1 patch session.

**Reference precedents:**
- `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` (Slot_T diagnostic)
- `_session-handoff/IMPL-FIX-011b-slot-G2-architectural-gap-20260511.md` (Slot_G2 diagnostic + Phase 1 patch lesson: re-verify "dead code" claims by grepping Evaluate body)

---

## § 0. TL;DR

Compared rewrite `CSlotG::Evaluate` + `_IsGBuySignal`/`_IsGSellSignal` (HEAD `1edb3d5`) vs legacy `BusinessLogic_G` (lines 4978-5400+ of `PhoenicisN2.10_stable.mq5`). Rewrite already wires 8 gates (ADX dominance + cloud-side + Stoch confirmation + Force-peaks-not-exhausted + BB-top<IchiMax 15-bar count + DeMarker rolling sum + Force-crossover primary/alternate). Legacy has **~15-18 gates** with substantial additional depth in (i) **isFICrossUp/Dw classification** (3-bar Force pattern matching with alternate), (ii) **Stochastic dual-bar oversold** `Sto[0]<25 OR Sto[1]<25` (rewrite uses single-bar threshold), (iii) **Chikou[26] cloud-edge check + Force-peak count fallback when Chikou invalid**, (iv) **ADX-W +DI vs -DI directional dominance** (`IDXPlusBuffer > IDXMinusBuffer` AND `IDXWPlusBuffer > IDXWMinusBuffer` BUY; mirror SELL), (v) **ADX dominance OR-clause** (`adx > both ±DI on bar 0 OR bar 1` — rewrite uses bar 0 only), (vi) **FI-wave detection + 3-bar minimum window** (`_startLastWaveIndex - _finishLastWaveIndex < 3 → return`), (vii) **GPauseDate cooldown** (31-H4-bar cooldown after manual pause), (viii) **isOverIchi wave-back-history check** (looking back through prior FI wave for cloud-break confirmation), (ix) **isFICrossUp/Dw direction-mismatch reject** (cross-up signal but SELL direction → return; mirror).

Q1 2021 result: **rewrite 1 spurious BUY at 2021-03-18 01:00:00 (`G,F1,N,1,SL`)**; legacy emits **0 G entries Q1** (per iter-12 journal_diff; note legacy "G," comments may include BusinessLogic_G AND BusinessLogic_G2 entries lumped, but Q1 sample had neither fire). Pattern matches Slot_G2 — rewrite fires when legacy doesn't.

**Recommended Phase 1 patch (similar shape to 011b A+G+L):** wire 3-4 high-leverage gates that legacy has but rewrite doesn't:
- **Gate α** `isFICrossUp/Dw` classification refinement (rewrite uses primary/alternate but legacy ALSO classifies "cross direction" + rejects direction-mismatch)
- **Gate β** Stochastic dual-bar OR (`Sto[0]<25 OR Sto[1]<25` — rewrite single-bar)
- **Gate γ** ADX-W +DI vs -DI directional dominance check
- **Gate δ** Chikou[26] cloud-edge check (Phase 1 hard-fail; Phase 2 with Force-peak fallback)

Phase 1 patch estimate: ~30-50 LOC + 0-2 new inputs + 0 new MarketContext fields (reuse existing adx_h4 + stoch_m10 + ichi_h4 historical scalars). 1-session Phase 1 patch.

---

## § 1. Legacy Slot_G architecture (decoded from `PhoenicisN2.10_stable.mq5:4978-5400+`)

### 1.1 Top-level gates (lines 4978-5026)

```c
void BusinessLogic_G() {
   if (BuyOrders__G + SellOrders__G > 0) return;  // no active G

   // GPauseDate cooldown — 31-H4-bar ban after manual pause
   if (GPauseDate > 0) {
      int banIndex = iBarShift(_Symbol, PERIOD_H4, GPauseDate, true);
      if (banIndex <= 31) return;
   }

   if (IsPreNewYearSeason()) return;  // calendar gate

   // FI-Cross-Up classification (BUY signal candidate)
   bool isFICrossUp = (Force[1] > 0 && Force[2] > 0 && Force[3] < -0.2);
   if (!isFICrossUp)
      isFICrossUp = (Force[1] > 1 && Force[2] in [-3.0, -0.2));  // alternate

   // FI-Cross-Dw classification (SELL signal candidate)
   bool isFICrossDw = (Force[1]<0 && Force[2]<0 && (Force[3]>0.2 ||
                       (Force[3]>0 && Force[4]>0)));
   if (!isFICrossDw)
      isFICrossDw = (Force[1] < -1 && Force[2] in (0.2, 3.0));  // alternate

   // Direction classification (inside Ichi cloud → return)
   if (bid < lowMain)      type = SELL;
   else if (bid > highMain) type = BUY;
   else                     return;

   // Direction-mismatch reject (cross-up signal but direction = SELL → return)
   if (isFICrossUp && type == SELL) return;
   if (isFICrossDw && type == BUY)  return;
```

### 1.2 BUY entry chain (isFICrossUp branch, lines 5027-5087)

```c
if (isFICrossUp) {
   // Gate β1 — H4 bar open must be above cloud
   if (iOpen[0] < highMain) return;

   // Gate β2 — Stochastic M10 dual-bar OR oversold
   if (!(Sto10[0] < 25 || Sto10[1] < 25)) return;

   // Gate γ1 — Chikou[26] cloud-top check (with fallback)
   iChiThisWaveStartBarsG = IChiThisWaveStartBars(SELL);
   double highMain26 = MathMax(IchiA[26], IchiB[26]);
   if (Chikou[26] < highMain26) {
      // Chikou invalid → check Force-peak fallback in wave window
      isIchi26Valid = false;
      int fPeakCount = 0;
      bool isFPeak = false;
      for (z = 2; z < iChiThisWaveStartBarsG; z++) {
         if (Force[z] > 11 && Force[z+1]<Force[z] && Force[z-1]<Force[z])
            fPeakCount++;
         if (Force[z] >= 25) { isFPeak = true; break; }
      }
      if (fPeakCount >= 3 || isFPeak) return;  // exhausted force peaks
   }

   // Gate δ1 — ADX +DI > -DI AND ADX-W +DI > -DI
   if (IDXPlus[0] <= IDXMinus[0] || IDXWPlus[0] <= IDXWMinus[0]) return;

   // Gate ε1 — ADX dominance OR-clause (bar 0 OR bar 1)
   if (!((IDXMain[0] > IDXPlus[0] && IDXMain[0] > IDXMinus[0]) ||
         (IDXMain[1] > IDXPlus[1] && IDXMain[1] > IDXMinus[1]))) return;
}
```

### 1.3 SELL entry chain (isFICrossDw branch, lines 5089-5147)

Symmetric mirror of BUY chain — Sto>75, lowMain comparison, Chikou>lowMain26, IDXPlus<IDXMinus + IDXWPlus<IDXWMinus, ADX dominance OR-clause.

### 1.4 FI-Wave detection (lines 5149-5400+)

```c
// Find previous FI wave (used for cloud-break-back history check)
int _startLastWaveIndex, _finishLastWaveIndex;
GFindFIWaveBefore(type, 1, _startLastWaveIndex, _finishLastWaveIndex, mode);

// Gate ζ — wave must be ≥3 bars wide
if (_startLastWaveIndex - _finishLastWaveIndex < 3) return;

// Gate η — within prior wave window, find at least one bar where price was clearly above (BUY) / below (SELL) cloud
bool isOverIchi = false;
for (i = _startLastWaveIndex; i >= _finishLastWaveIndex; i--) {
   if (type == SELL && Open[i]>highMain[i] && Close[i]>highMain[i]) {
      isOverIchi = true; break;
   } else if (type == BUY && Open[i]<lowMain[i] && Close[i]<lowMain[i]) {
      isOverIchi = true; break;
   }
}
if (!isOverIchi) return;
// ... [additional gates beyond line 5180 not yet decoded — likely SL placement, Hull wave-anchor, lot sizing, OpenOrderG]
```

---

## § 2. Rewrite Slot_G architecture (HEAD 1edb3d5)

### 2.1 `CSlotG::Evaluate` flow (~10 gates wired)

```cpp
1. if (!InpEnableSlotG) return;
2. service-pointer guard
3. _HasActiveGOrder(port) → return
4. ADX dominance: adx > InpGAdxDominanceMin AND adx > di_plus AND adx > di_minus  (BAR 0 ONLY — legacy uses OR-clause bar 0 OR bar 1)
5. _IsGBuySignal OR _IsGSellSignal (primary OR alternate Force-crossover)
6. Cloud-side: bid > cloud_high (BUY) / < cloud_low (SELL)
7. Stochastic M10: stoch_k < InpGStochOversold (BUY) / > InpGStochOverbought (SELL) — SINGLE BAR (legacy uses bar 0 OR bar 1)
8. _IsForcePeaksNotExhausted (Session C: 8-bar |F|>11 peak count ≤3)
9. _BBTopBelowIchiMaxCount ≥ InpGBBHistMinBelow (Fix B 15-bar count)
10. _IsDemRollingBuyOk / _IsDemRollingSellOk (Session C 25-bar DEM ≥175 BUY / ≤25 SELL)
```

### 2.2 `_IsGBuySignal` (~lines 182-198)

```cpp
bool primary   = (f1 > InpGFICrossThreshHigh && f2 > InpGFICrossThreshHigh && f3 < InpGFICrossThreshLow);
bool alternate = (f1 > InpGFICrossAltHigh   && f2 > InpGFICrossAltLow    && f2 < InpGFICrossThreshLow);
return primary || alternate;
```

Mirror SELL with negated thresholds.

---

## § 3. Divergence inventory (~10 unwired legacy gates)

Following Slot_T § 3 + Slot_G2 § 3 format:

| # | Gap | Legacy | Rewrite | Severity | Fix shape |
|---|-----|--------|---------|----------|-----------|
| **α** | **isFICrossUp/Dw direction-mismatch reject** | Cross-up signal AND direction=SELL → return (lines 5022-5025); mirror | Not implemented — Evaluate evaluates both buySignal+sellSignal simultaneously then runs cloud-side direction check | 🟠 HIGH — eliminates direction-confused entries | Add `isFICrossUp = _IsGBuySignal(ctx)`, `isFICrossDw = _IsGSellSignal(ctx)`; if buySignal AND price_below_cloud (would be SELL direction) → return; mirror. ~6 LOC |
| **β1** | **iOpen[0] vs cloud-edge** | BUY: `iOpen[0] < highMain → return`; SELL mirror (line 5032 + 5091) | Not implemented — rewrite uses bid-vs-cloud only | 🟡 MEDIUM — confirms H4 bar opened on correct side of cloud | Add `ctx.bar_open_h4` field OR use ichi_h4.cloud_high vs Open from existing history. ~5 LOC + possibly new MC field |
| **β2** | **Stochastic dual-bar OR** | BUY: `!(Sto[0]<25 OR Sto[1]<25) → return` (line 5036); mirror | rewrite checks single bar only (`stoch_m10.k_main`) | 🟠 HIGH — legacy more permissive in window; rewrite over-restricts THEN under-restricts at spurious bars where Sto[0]>25 but Sto[1]<25 | Add `stoch_m10.k_prev` (bar 1) to MarketContext OR use existing `stoch_m10.d_signal` as proxy. ~8 LOC + 1 MC field |
| **γ1** | **Chikou[26] cloud-edge check with Force-peak fallback** | BUY: `if (Chikou[26] < highMain26) { scan wave for Force peaks; if >=3 peaks OR any peak>=25 → return }`; mirror with `Chikou>lowMain26` (lines 5042-5068) | Not implemented | 🔴 CRITICAL — trend-confirmation Phase 1 gate | Need `ichi_h4.chikou[27]` field OR scalar Chikou[26] + cloud_max[26]/cloud_min[26]. ~15 LOC + MC fields. Fallback Force-peak count of |F|>11 peaks can reuse `force_h4_history.peak_count_above11` (Fix D); deeper |F|>=25 needs new derived flag |
| **δ1** | **ADX-W +DI > -DI directional dominance** | BUY: `IDXPlus[0]<=IDXMinus[0] OR IDXWPlus[0]<=IDXWMinus[0] → return` (line 5071); mirror at 5130 | rewrite only checks `adx > both ±DI` (sum dominance, not direction) | 🟠 HIGH — legacy requires +DI > -DI for BUY; rewrite allows BUY when ADX is dominant but +DI < -DI (bearish dominance) | Add 2 conditions: `if buySignal && (di_plus<=di_minus || adxw_plus<=adxw_minus) return`; mirror. Reuse existing `adx_h4.di_plus/di_minus`. Need `adx_h4.di_plus_wave/di_minus_wave` for ADX-W variant OR drop ADX-W half (Phase 1 conservative). ~6 LOC |
| **ε1** | **ADX dominance OR-clause bar 0 OR bar 1** | `(IDXMain[0]>+DI[0] && >IDXMinus[0]) OR (IDXMain[1]>+DI[1] && >-DI[1])` (lines 5076-5087) | rewrite uses bar 0 only | 🟡 MEDIUM — strictly more permissive than rewrite (allows bar 1 dominance to pass) | Add `adx_h4_history.adx[0..2] + di_plus[0..2] + di_minus[0..2]` (Fix B has this) — wire 2-bar OR check. ~5 LOC |
| **ζ** | **GFindFIWaveBefore wave-detection + ≥3-bar window** | Sets `_startLastWaveIndex, _finishLastWaveIndex`; if `_start - _finish < 3 → return` (lines 5154-5160) | Not implemented | 🟡 MEDIUM — wave-back-history detector ensures genuine FI-Cross context not noise spike | Significant scope — `GFindFIWaveBefore` is itself complex. Defer to Phase 2 |
| **η** | **isOverIchi prior-wave cloud-break HAS-ONE** | Within prior FI wave window, require ≥1 bar where Open AND Close on correct side of cloud (lines 5162-5180); else return | Not implemented | 🟡 MEDIUM — relies on gate ζ wave-detection; same Phase 2 deferral |
| **θ** | **GPauseDate cooldown** | 31-H4-bar ban after manual pause flag set (lines 4983-4990) | Not implemented; rewrite has no manual-pause concept | 🟢 LOW — manual-pause is operator state not market state; Phase 2 if persistence wiring lands |
| **κ** | **isPreNewYearSeason** calendar gate | Returns true Dec 20 - Jan 5 typical (line 4992) | Not implemented | 🟢 LOW — calendar gate; can defer |

---

## § 4. Q1 2021 trigger bucket analysis

### 4.1 Rewrite-only Slot_G fires (per iter-12 journal_diff)

| Date | Direction | Comment | Bucket | Notes |
|------|-----------|---------|--------|-------|
| 2021-03-18 01:00:00 | BUY | G,F1,N,1,SL | rewrite-only |Δ|=+1 | Force-crossover triggered; one or more of legacy gates α/β2/γ1/δ1 must have failed |

### 4.2 Legacy Slot_G fires in Q1

journal_diff classifies `legacy by_slot: G` not present in counts — **legacy emits 0 G entries in Q1 2021** (consistent with Slot_G2 pattern where legacy comment "G," routes to slot_id=G but no actual G or G2 entries fired in Q1). Note: legacy `BusinessLogic_G` is structurally distinct from `BusinessLogic_G2`; the journal_diff parser may merge them by comment prefix but per Step 0 Slot_G2 § 1.3 we noted both functions emit comment starting `"G,"`. In Q1 sample, neither parent G nor G2 fired in legacy.

### 4.3 What it takes to suppress 1 rewrite-only fire at 2021-03-18 01:00

Without telemetry at 2021-03-18 01:00..04:00, candidate discriminators are:

1. **Gate α direction-mismatch:** if legacy classified isFICrossUp=true AT 2021-03-18 01:00 but bid was actually in SELL range (below lowMain) → reject. Unlikely cause for BUY-direction rewrite fire.

2. **Gate β2 Stoch dual-bar:** if `Sto[0] >= 25` AND `Sto[1] >= 25` at 2021-03-18 01:00 → legacy gate fails. Likely cause if Stoch was rising past 25 at that bar.

3. **Gate γ1 Chikou[26]:** if `Chikou[26] < highMain[26]` at 2021-03-18 (looking back to 2021-01-20 area) AND Force-peak fallback exceeded → legacy rejects. Possible if pre-March trend wasn't strong enough.

4. **Gate δ1 ADX-W directional:** if `IDXPlus[0] <= IDXMinus[0]` (no +DI dominance) at 2021-03-18 → legacy rejects. Possible — ADX directional in 03-18 may have been balanced.

5. **Gate ε1 ADX bar 0 OR bar 1:** rewrite uses bar 0 only; if bar 0 fails but bar 1 passes (legacy permissive), legacy would FIRE where rewrite doesn't — opposite direction of discrimination (won't help suppress).

**Highest-likelihood discriminator:** gate β2 (Stochastic dual-bar) — empirical signal at 03-18 was likely a Stoch>25 single-bar miss while legacy required Sto[0]<25 OR Sto[1]<25.

Without per-bar telemetry, best to apply gate α + β2 + δ1 (all 3 are low-LOC + use existing infrastructure) and re-canary. If iter-13 still fires spurious 03-18, add telemetry harness mirroring IMPL-FIX-011a iter-6 pattern.

### 4.4 Extrapolation to 5-yr Bucket A

Q1 sample: 1 spurious G fire over 3 months. 5-yr extrapolation: ~20 spurious G fires (linear). NFR-1.6 per-slot deviation ≤10% — likely contributes minor drift if legacy 5-yr has ~0 G entries. Lower urgency than G2 (which had 2 spurious in Q1 ≈ 40 in 5-yr).

---

## § 5. Recommendations

### 5.1 Phase 1 minimal-patch session (recommended next)

**Single session ~1-2 hours, mirroring 011b A+G+L pattern:**

Apply 3 gates in order of highest expected suppression effect:

1. **Gate β2 Stochastic dual-bar OR** (~8 LOC + 1 MC field `stoch_m10.k_prev`):
   - Add `stoch_m10.k_prev` (bar 1) to MarketContext or use existing iStochastic CopyBuffer to read bar 1 in PopulateStoch
   - Evaluate: `if (buySignal && !(stoch_m10.k_main<25 || stoch_m10.k_prev<25)) return;` + mirror

2. **Gate δ1 ADX-W directional dominance** (~6 LOC, zero new MC fields):
   - Evaluate: `if (buySignal && (adx_h4.di_plus <= adx_h4.di_minus)) return;` + SELL mirror via `di_plus >= di_minus`
   - Phase 1 conservative: drop ADX-W (`adxw_plus/minus`) half — accept ADX-only directional gate; full ADX-W in Phase 2

3. **Gate α direction-mismatch** (~6 LOC, zero new MC fields):
   - Already implicit via Evaluate cloud-side check (gate 6 in §2.1) — verify equivalent semantics. May already be covered. If `buySignal=true` and `_IsPriceAboveCloud=false` (bid<cloud), Evaluate already returns at line 385. So gate α is effectively wired.

**Net Phase 1 patch: ~14 LOC + 1 new MarketContext field (stoch_m10.k_prev).** G1 + Q1 re-canary; expect 1 spurious → 0.

### 5.2 Phase 2 deeper-architecture session (deferred)

- Gate γ1 Chikou[26] + Force-peak fallback (~15 LOC + Chikou history field + cloud_max/min[27] history)
- Gate ζ + η FI-wave detection + isOverIchi (~50-100 LOC; new helper class)
- Gate β1 H4 bar open-vs-cloud (~5 LOC + bar_open_h4 field)
- Gate ε1 ADX bar 0 OR bar 1 (~5 LOC — uses Fix B adx_h4_history)
- Gates θ, κ (GPauseDate + isPreNewYearSeason calendar) — Phase 2/3 backlog

Defer to follow-on alongside P4 IMPL-062 Bucket A drift investigation OR IMPL-FIX-011c-phase2 ticket.

### 5.3 NOT recommended

- Speculative threshold tuning of `InpGFICrossThreshHigh`/etc — same anti-pattern surfaced in iter-3 Slot_G2 work and 011a iter-2 falsifications. Only architectural-gate-additions work.

### 5.4 Telemetry fallback

If Phase 1 patch β2+δ1 fails to suppress 2021-03-18 01:00 fire, add `_IsTargetDebugBar` for 2021-03-18 + spurious-comparison telemetry per IMPL-FIX-011a iter-10 pattern.

---

## § 6. State Reconciliation

This session NO MQL5 source changes — diagnostic only.

| Artifact | Status |
|----------|--------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh` | unchanged |
| `docs/state/_session-handoff/IMPL-FIX-011c-slot-G-architectural-gap-20260511.md` (this file) | NEW |

**No iter-N re-canary this session** — diagnostic doc IS the deliverable. Operator decision required to proceed with either:
- (a) Phase 1 minimal patch (gates β2 + δ1; ~1 session) — recommended
- (b) Phase 2 full reconstruction (~3-5 sessions)
- (c) Defer Slot_G work; advance to other Phase 3/4 priorities (e.g., IMPL-FIX-011d long-tail)

**Phase 5 mechanical gates:** N/A for diagnostic-only commit (per Slot_T/Slot_G2 diagnostic precedent). Plan Staleness Sentinel unchanged.

**Closes IMPL-FIX-011c S-AC #1** ✅ MET — diagnostic artifact landed per task block schema: (a) legacy `BusinessLogic_G` decode at § 1 ✅; (b) gap table per 011a/011b § 3 precedent at § 3 ✅; (c) Q1 2021 trigger bucket enumeration at § 4 ✅.

**Step 0 accuracy lesson from 011b:** before claiming "wire dead-code helpers" in Phase 1 recommendation, re-grep Evaluate body for actual call-sites. For this Slot_G diagnostic, rewrite Evaluate already wires 8+ gates (§ 2.1) — Phase 1 recommendation explicitly identifies NEW gates not yet wired (gate β2 needs new MC field; gate δ1 zero MC fields; gate α likely already implicit via cloud-side check).
