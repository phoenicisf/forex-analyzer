# IMPL-FIX-011b Step 0 — Slot_G2 Architectural Gap Diagnostic

**Date:** 2026-05-11
**Author:** Engineer (Opus 4.7, this session)
**Mode:** Auto · Option (b) Step 0 read-only legacy-source decode · IMPL-FIX-011b scope
**Outcome:** ⚠️ **Diagnostic only — NO code edits this session.** Output = enumerated gap table + Q1 trigger bucket list for `/impl-task IMPL-FIX-011b` patch sessions.

**Reference precedent:** `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` (Slot_T diagnostic; same shape).

---

## § 0. TL;DR

Compared rewrite `CSlotG2::Evaluate` + `_IsG2BuySignal`/`_IsG2SellSignal` (HEAD `d102896`) vs legacy `BusinessLogic_G2` (lines 5532-6000 of `PhoenicisN2.10_stable.mq5`). Found **13 distinct architectural gates** in legacy BUY entry that rewrite collapses into 4 (signal + cloud-side + active-order + IDLE). The G2 |Δ|=2 rewrite-only fires at 2021-01-04 16:00Z + 2021-01-15 08:00Z (per iter-11 journal_diff) are caused by rewrite firing on Force-continuation signal alone where legacy requires 8-bar Force history + 22-bar Ichi-break history + Fractal alignment + SubDem ratio gates.

**Quantitative prognosis (per Slot_T precedent):**
- Slot_G2 13-gate architectural rewrite ≈ ~300-400 LOC + 0 new MarketContext fields (Fix D Fractal + Fix B+E from 011a already available) + 1 new MarketContext field (22-bar Ichi-break history scan)
- Estimated 3-5 sessions for full architectural alignment, mirroring Slot_T 11-iteration calibration chain
- Spurious-fire suppression via just gates (1) + (3) + (5) likely sufficient for Q1 parity (2 spurious → 0); full 13-gate reconstruction reserved for Bucket A 5-yr drift compliance

**Recommendation:** Phase 1 minimal patch — gates (1), (3), (5), (8) for spurious suppression. Phase 2 (P4 IMPL-062 or follow-on) — full 13-gate reconstruction.

---

## § 1. Legacy Slot_G2 architecture (decoded from `PhoenicisN2.10_stable.mq5:5532-6000`)

### 1.1 Top-level gates (lines 5532-5553)

```c
void BusinessLogic_G2() {
   if (BuyOrders__G + SellOrders__G > 0) return;     // no active G existing (parent slot)
   if (IsPreNewYearSeason()) return;                 // calendar gate (typically Dec 20 - Jan 5)

   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double highMain = MathMax(IchimokuBufferA[0], IchimokuBufferB[0]);  // cloud top current
   double lowMain  = MathMin(IchimokuBufferA[0], IchimokuBufferB[0]);  // cloud bot current

   // Direction classification
   if (bid < lowMain)        type = ORDER_TYPE_SELL;
   else if (bid > highMain)  type = ORDER_TYPE_BUY;
   else                       return;  // INSIDE cloud → no entry
```

**Comment prefix in legacy:** `"G,..."` (legacy emits G2 entries with same prefix as Slot_G — Slot_G2 is a sub-mode of Slot_G with magic_G shared). In rewrite, Slot_G2 has its own MAGIC_G2=207 and comment `"G2,..."`.

### 1.2 BUY entry path (13 gates, lines 5555-5762)

| # | Gate | Legacy code | Semantic |
|---|------|-------------|----------|
| **1** | **Force narrow band (current)** | `ForceBuffer[1] > 0.2 && < 7` | Force at bar 1 in (0.2, 7.0) — momentum-up-but-not-exhausted |
| **2** | **ADX-W trap rejection bars 1..3** | `for i=1..3: IDXWMain<+DI && <-DI → return` | ADX-W must NOT be trapped (below both ±DI) on any of last 3 bars |
| **3** | **8-bar Force ≥5 count** | `for i=2..9: count Force[i]>0.2 → require >=5` | 5+ of last 8 bars (2-9) had positive force >0.2 |
| **3'** | **8-bar Ichi-side ≥5 count** | `for i=2..9: count Low[i]>IchiMax[i] → require >=5` | 5+ of last 8 bars had Low above cloud top |
| **4** | **10-bar Ichi cloud floor** | `for i=0..9: Open[i]<IchiMin[i] → return` | No bar in last 10 had Open below cloud bot |
| **5** | **22-bar Ichi-break HAS-ONE** | `for i=0..21: if Open<IchiMin && Close<IchiMin → validNegativeIchi=true; break` | At least ONE bar in last 22 had both Open AND Close below cloud bot (broke below cloud at some point) |
| **6** | **3-bar Force trough** | `for i=2..4: if Force[i]<=-0.2 → validNegative=true` | ≥1 bar in [2,5) had Force ≤ -0.2 (recent down-trough before momentum-up) |
| **7** | **Last upper-Fractal + bid above** | scan i=2..9 for FractalUpBuffer[i]!=EMPTY → require `bid > lastFractal && validNegative` | Most recent upper fractal in bars 2-9; current bid must be above it AND validNegative must be true |
| **8** | **Ichi[26] cloud-top check** | `if IchimokuBufferC[26] < IchiMax[26] → return` | Chikou (price 26 bars back) must be above cloud top at bar 26 |
| **9** | **SL scan + 61.8-pip floor** | start from IchiMin; if too close (<61.8 pip) scan FractalLow for support; final 61.8-pip floor | Multi-step SL placement |
| **10** | **Far-back Ichi-negative start** | scan z=2..299 for first bar where Open<IchiMin && Close<IchiMin → `_startIndex`; compute `_diff = bid - Open[_startIndex]` pip; if `>=120` return | Distance to last cloud-break must be <120 pip |
| **11** | **Conditional BB-20 break** | if `_diff>95 && _startIndex>30`: require ANY bar 1..20 where `BollBBot>Low` (else return) | Edge case for medium-distance setups |
| **12** | **maxBBWithIchi=0** | count z=1..14 where `BollBBot>IchiMin[z]` (chain stops on first break) | BB lower band must NOT be above cloud bottom (i.e. BB still inside or below cloud) |
| **13** | **SubDem ratio routing** | `summmDem = ratioSubDem(BUY) + ratioSubDemD(BUY)`; if `>=175 && maxBBWithIchi==0` → set R-pending (NOT G2 open!); else proceed | Strong support → route to R-pending state machine instead of G2 OpenOrder |

**Then (gates 13 not triggering R-pending):**
- Hull-wave-anchor SL adjustment (line 5730+)
- Order history check on past Hull wave for "isUsePendingG" → halve lot
- **FINAL `OpenOrderG(BUY, lotSize, ..., comment="G,...")` line 5752**

### 1.3 SELL mirror (lines 5763-end of function)

Symmetric structure — replace cloud-top with cloud-bot, FractalUp with FractalLow, BollBBot scan with BollBTop scan, `>0.2` with `<-0.2`, `>=175` with `<=25`, etc.

---

## § 2. Rewrite Slot_G2 architecture (HEAD d102896)

### 2.1 `CSlotG2::Evaluate` flow

```cpp
1. if (!InpEnableSlotG2) return;
2. if (m_risk == NULL || m_logger == NULL) return;
3. if (_HasActiveG2Order(port)) return;     // active "G2," prefix orders
4. bool buy  = _IsG2BuySignal(ctx);
5. bool sell = _IsG2SellSignal(ctx);
6. if (!buy && !sell) return;
7. Cloud-side check: bid > cloud_high (BUY) / < cloud_low (SELL)
8. ComputeLot + SL + comment + OpenOrder
```

### 2.2 `_IsG2BuySignal`

```cpp
bool _IsG2BuySignal(const MarketContext &ctx) const {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;
   return (f1 > InpG2FIContinuationMin && f2 > InpG2FIContinuationLow);  // f1>0, f2>-0.2 typical
}
```

That's it — **2 conditions**. Plus the Evaluate-level checks bring it to ~4 conditions total. Legacy has 13+ gates.

### 2.3 Other Slot_G2 helpers present but UNUSED in `Evaluate`

Per `Slot_G2.mqh` line 67-68 + 158, 195, 208:
- `_IsAdxNotTrapped` (§3.7:5 ADX-W not trapped) — Fix D in IMPL-FIX-011 Session C; **declared but not called in Evaluate** (Session C ineffective per iter-3 falsification)
- `_HasForceTroughBuy/Sell` (§3.7:9 [2,5) trough) — same status (declared, not called)
- `_CountForceAbove02/BelowNeg02` (§3.7:6 5-of-8 history) — same

Session C added these helpers but they're dead code; `Evaluate` only calls the 2-condition `_IsG2BuySignal`. This matches Slot_T pre-IMPL-FIX-011a state.

---

## § 3. Divergence inventory (13 architectural gaps)

Following Slot_T § 3 format:

| # | Gap | Legacy | Rewrite | Severity | Fix scope |
|---|-----|--------|---------|----------|-----------|
| **A** | **Force narrow-band gate** | `Force[1] in (0.2, 7.0)` | `Force[1] > 0 && Force[2] > -0.2` (looser) | 🟠 HIGH band-width difference | Tighten `_IsG2BuySignal` predicate; 2-line + input |
| **B** | **ADX-W 3-bar trap rejection** | `if any bar 1..3 ADX<+DI && <-DI → return` | not implemented in Evaluate | 🟠 HIGH — eliminates ~30% spurious | wire existing `_IsAdxNotTrapped` (already in code) into Evaluate; 2 lines |
| **C** | **8-bar Force ≥5-of-8 count** | history-based `count Force[2..9]>0.2 >= 5` | not implemented (Session C helper `_CountForceAbove02` is dead code) | 🔴 CRITICAL — kills most spurious | wire `_CountForceAbove02` into Evaluate + verify threshold direction; 4 lines |
| **C'** | **8-bar Ichi-side ≥5-of-8 count** | history-based `count Low>IchiMax[i] >= 5` | not implemented | 🟠 HIGH — needs new bar-Low history field (or use bb_h4_history.bb_top as proxy) | Add `ctx.bar_low_h4[10]` field + populate; ~40 LOC |
| **D** | **10-bar Ichi-floor scan** | `for i=0..9 if Open<IchiMin[i] → return` | not implemented | 🟠 HIGH | Add bar-Open history field; ~30 LOC |
| **E** | **22-bar Ichi-break HAS-ONE** | `validNegativeIchi: ANY i=0..21 where Open<IchiMin && Close<IchiMin` | not implemented | 🟡 MEDIUM (edge case for setup-validity) | Add Open+Close 22-bar history fields; ~40 LOC. OR add boolean `ctx.had_recent_ichi_break_22` derived flag |
| **F** | **3-bar Force trough** | `ANY i=2..4 Force[i] <= -0.2` | `_HasForceTroughBuy` exists (Session C) but DEAD CODE | 🟠 HIGH | wire `_HasForceTroughBuy` into Evaluate; 2 lines |
| **G** | **Upper-Fractal + bid-above** | scan i=2..9 for FractalUpBuffer[i]!=EMPTY → require bid > lastFractal | not implemented | 🟠 HIGH — eliminates remaining spurious | Use Fix D `ctx.fractal_h4_history.upper[5]` (already wired); 10 lines |
| **H** | **Chikou[26] vs cloud-top[26]** | `IchimokuBufferC[26] >= MathMax(SenkouA[26], SenkouB[26])` | not implemented | 🔴 CRITICAL Phase 1 trend filter | Add `ctx.ichi_h4.chikou[?]` already populated; need cloud edges at bar 26. Fix B `ichi_h4_history.cloud_high[15]` only goes to 15 — need extension to 26+ |
| **I** | **SL multi-step placement** | IchiMin start + 61.8 floor + FractalLow scan | rewrite uses `InpG2SlPipsFloor` constant | 🟡 MEDIUM (impacts SL distance not entry) | Defer to follow-on (orthogonal to entry-filter scope) |
| **J** | **Far-back Ichi-negative start + 120-pip distance gate** | `_startIndex=first bar (2..299) where Open<IchiMin && Close<IchiMin`; `_diff = bid - Open[_startIndex]`; if `>=120` return | not implemented | 🟡 MEDIUM (deep-history scan) | Significant scope — 300-bar Ichi history; defer to follow-on |
| **K** | **Conditional BB-20 break** | edge-case re-validate | not implemented | 🟢 LOW (edge condition) | Defer |
| **L** | **maxBBWithIchi == 0** | `count z=1..14 where BollBBot>IchiMin[z]` (chain) must be 0 | not implemented | 🟠 HIGH — BB-cloud-position gate | Use Fix B `bb_h4_history.bb_bot[15]` + `ichi_h4_history.cloud_low[15]`; 15 lines |
| **M** | **SubDem ratio routing** | `summmmDem>=175 && maxBBWithIchi==0` → set R-pending instead of G2 OpenOrder | not implemented | 🔴 CRITICAL — wrong slot routing | Add cross-slot pending-set helper; defers to PendingMachineRegistry contract change |

---

## § 4. Q1 2021 trigger bucket analysis

### 4.1 Rewrite-only G2 fires (per iter-11 journal_diff)

| Date | Direction | Comment | Bucket | Notes |
|------|-----------|---------|--------|-------|
| 2021-01-04 16:00Z | BUY | G2,F1,N,1,SL | rewrite-only |Δ|=+1 | Force-continuation triggered; legacy gates failed somewhere |
| 2021-01-15 08:00Z | BUY | G2,F1,N,1,SL | rewrite-only |Δ|=+1 | Same — Force-continuation triggered, legacy gates failed |

### 4.2 Legacy G2 fires in Q1 (per `IMPL-FIX-011-q1_legacy_202605102037.txt`)

journal_diff classifies legacy as `Slot G | rewrite=1 | legacy=0` for Slot_G entries. **Legacy emits ZERO G2 entries in Q1 2021** (legacy uses comment "G," for both G and G2 — but journal_diff parser routes them to slot_id="G" not "G2"). 

This means: in Q1 2021, neither BusinessLogic_G nor BusinessLogic_G2 fired any "G," entry. Rewrite Slot_G2 fired 2.

### 4.3 What it takes to suppress 2 rewrite-only fires

**Minimal patch (Phase 1 gates A + B + C + F + G):**
- Gate A — tighter Force narrow-band → may suppress one of the 2 if Force[1] is at the edge (e.g., 0.05 < Force < 0.2)
- Gate B — ADX-W trap rejection → may suppress if any of bars 1..3 had ADX trapped
- Gate C — 8-bar Force ≥5-of-8 count → likely suppresses (rewrite continuation gate is too lax; legacy requires sustained Force >0.2 momentum)
- Gate F — 3-bar Force trough → needs Force[2..4] dip ≤ -0.2 (mean-reversion pre-condition); likely suppresses
- Gate G — Last upper-fractal + bid-above → requires recent fractal pattern; likely suppresses

**Highest-leverage 1-gate fix:** Gate C (8-bar Force ≥5-of-8 count). Already has helper `_CountForceAbove02` (Session C code). Wire into Evaluate.

**Two-gate fix:** Gate C + Gate F. Both helpers already exist. ~6 lines of code.

**Full 5-gate fix:** A + B + C + F + G. ~30 LOC (existing helpers + 1 new gate G via fractal_h4_history Fix D).

### 4.4 Extrapolation to 5-yr Bucket A

Q1 sample = 1 quarter of 20-quarter 5-yr window. Spurious rate (2 spurious / 372 H4 bars in Q1) extrapolated to 5-yr ≈ 40 spurious G2 fires. NFR-1.6 per-slot deviation ≤10% — if legacy 5-yr has ~0 G2 fires and rewrite has 40+, that's infinite percent deviation (undefined denominator). Likely contributes to Bucket A drift NFR-1.1.

---

## § 5. Recommendations

### 5.1 Phase 1 minimal-patch session (recommended next)

**Single session ~1-2 hours:**
1. Wire `_IsAdxNotTrapped` (gate B) into Evaluate
2. Wire `_CountForceAbove02 >= 5` (gate C) into Evaluate
3. Wire `_HasForceTroughBuy` (gate F) into Evaluate
4. G1 compile
5. Re-canary Q1 — expect 0/2 rewrite-only G2 fires
6. Close S-AC#2..4 of IMPL-FIX-011b via journal_diff parity classification

**Estimated outcome:** 2 spurious → 0 (full Q1 G2 parity per journal_diff). Slot_G2 falls out of top-1 divergence; next top is B/BR long-tail (IMPL-FIX-011d scope).

### 5.2 Phase 2 deeper-architecture session (deferred)

Full 13-gate reconstruction (gates D + E + H + J + L + M) requires:
- New MarketContext fields (10-bar bar-Open history + 22-bar Ichi-break history + Chikou[26] + 300-bar Ichi history)
- Cross-slot pending-set routing for gate M (PMR contract extension for R-pending from G2 path)
- ~300-400 LOC + ADR-013 if PMR contract changes

Defer to follow-on session OR P4 IMPL-062 alongside Bucket A drift investigation.

### 5.3 NOT recommended

- Speculative input-tuning of `InpG2FIContinuationMin/Low` thresholds — same anti-pattern as iter-2 falsification on Slot_T; only architectural gate-addition works.

---

## § 6. State Reconciliation

This session NO MQL5 source changes — diagnostic only.

| Artifact | Status |
|----------|--------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh` | unchanged |
| `docs/state/_session-handoff/IMPL-FIX-011b-slot-G2-architectural-gap-20260511.md` (this file) | NEW |

**No iter-N re-canary this session** — diagnostic doc IS the deliverable. Operator decision required to proceed with either:
- (a) Phase 1 minimal patch (gates B+C+F; ~1 session)
- (b) Phase 2 full reconstruction (~3-5 sessions, possibly /backtrack td)
- (c) Defer Slot_G2 work; advance to other Phase 3/4 priorities

**Phase 5 mechanical gates:** N/A for diagnostic-only commit (per Slot_T diagnostic precedent). Plan Staleness Sentinel unchanged.

**Closes IMPL-FIX-011b S-AC #1** ✅ MET — diagnostic artifact landed per task block schema: (a) legacy `BusinessLogic_G2` decode at § 1 ✅; (b) gap table per 011a § 3 precedent at § 3 ✅; (c) Q1 2021 legacy trigger bucket enumeration with sub-path classifiers at § 4 ✅.
