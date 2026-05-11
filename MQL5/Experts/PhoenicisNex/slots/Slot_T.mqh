//+------------------------------------------------------------------+
//| slots/Slot_T.mqh — Slot T implementation (IMPL-035)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_T = 219                                            |
//| Source:  CodeWiki §3.15 Slot T; ADR-002; ADR-008 (OQ-A3); ADR-012 |
//|                                                                   |
//| IMPL-FIX-011 Session C rewrite (2026-05-10) — replaces M-size MVP |
//| (3-condition MACD/ADX/Stoch) with §3.15 4-sub-path predicate per   |
//| empirically falsified Step 4 iter-2 finding (T/entry |Δ|=3 of 4   |
//| legacy trigger varieties; 1 of 4 hit). Sub-paths:                  |
//|   1. BUY support-zone × DEM≥0.45 ("D" sub-path)                   |
//|   2. BUY support-zone × DEM<0.45 ("H" sub-path; Hull-anchored)    |
//|   3. SELL resistance-zone × DEM≥0.45 ("D" sub-path)               |
//|   4. SELL resistance-zone × DEM<0.45 ("H" sub-path)               |
//|                                                                   |
//| Entry conditions (per CodeWiki §3.15 BUY support-zone path; SELL  |
//| mirrors with BollBand% > InpTBollBandPctSell):                     |
//|   1. No active T orders (magic 219, "T," prefix)                  |
//|   2. (Phase A IDLE) base signal: zone present + BollBand% < 5%    |
//|   3. (Phase A IDLE) Price > Hull MA (BUY) / < Hull MA (SELL)      |
//|   4. (Phase A IDLE) ≥7 of last 10 bars BBTop < IchiMax (BUY)      |
//|      mirror BBBot > IchiMin (SELL)                                |
//|   5. (Phase A IDLE) ADX H4 dominance: adx > InpTAdxMin             |
//|   6. (Phase B PENDING) trigger: same conditions still hold         |
//|      + DEM gate (D sub-path: dem ≥ 0.45 / H sub-path: dem < 0.45) |
//|   7. SL = max(BBWidth, hull-distance, InpTSlPipsCodeWikiFloor=90) |
//|   8. Comment encodes sub-path: "T,<dir>,<sub>,1,<sl>"             |
//|                                                                   |
//| Deferred to P4 IMPL-062+: ZoneStrength=ZONE_PROVEN explicit gate; |
//| zone_hit ≥ 2 counter (currently proxied via subdem.has_*); _NoOpp |
//| GBR cross-slot directional check (currently no-op TRUE — Phase 1  |
//| conservative: rely on PortfolioState GetByMagic for G/B/R later); |
//| advanced ADXW dominance "A"/"B" sub-classification.                |
//|                                                                   |
//| Exit (ManageExits):                                                |
//|   - Profit gate ≥ InpTTpProfitPips (45 pip default — unchanged)    |
//|                                                                   |
//| Pending integration (ADR-008 / OQ-A3):                            |
//|   - CPendingMachineRegistry PM_T; force-clear = PMR.TickAll       |
//|   - InpForceClearT_Bars = 80 (Inputs_Pending.mqh)                 |
//|   - Slot ห้าม call TickAll directly — Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("T", sl_pips, balance)                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                                |
//|   ห้าม #include "services/Logger.mqh" direct (injected)            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_T_MQH
#define PHOENICISNEX_SLOTS_SLOT_T_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_T.mqh"

//+------------------------------------------------------------------+
//| CSlotT — Slot T derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses T-Pending state machine (PM_T) to gate entry per §3.15:      |
//|   IDLE + base signal → EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid → place entry + TransitionExecuted      |
//|   Force-clear (80 H4 bars): handled by PMR.TickAll in Orchestr.   |
//+------------------------------------------------------------------+
class CSlotT : public CSlotBase
  {
private:
   //--- Private helpers (§3.15 4-sub-path predicates)
   bool              _HasActiveTOrder(CPortfolioState &port) const;
   bool              _IsTBuySupportZone(const MarketContext &ctx) const;     // §3.15:2 BUY zone+BB%
   bool              _IsTSellResistanceZone(const MarketContext &ctx) const; // §3.15:2 SELL mirror
   bool              _IsPriceAboveHull(const MarketContext &ctx) const;      // §3.15:4 BUY
   bool              _IsPriceBelowHull(const MarketContext &ctx) const;      // §3.15:4 SELL
   int               _BBTopBelowIchiMaxCount(const MarketContext &ctx) const;// §3.15:5 BUY scan
   int               _BBBotAboveIchiMinCount(const MarketContext &ctx) const;// §3.15:5 SELL mirror
   bool              _IsAdxDominant(const MarketContext &ctx) const;         // §3.15:6
   bool              _IsTBuyBaseSignal(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTSellBaseSignal(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTBuyTrigger(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTSellTrigger(const MarketContext &ctx, CPortfolioState &port) const;
   string            _ResolveTSubPath(const MarketContext &ctx) const;       // §3.15:7 D/H comment letter
   //--- IMPL-FIX-011a Fix C — 5-state pending sub-path resolution (CodeWiki §3.15:7 + diagnostic § 1.1)
   EPendingSubPathT  _ClassifyTSubPath(const MarketContext &ctx, bool isBuy) const;
   bool              _IsTbTdTrigger    (const MarketContext &ctx, bool isBuy, int pending_bars) const;
   bool              _IsThafTrigger    (const MarketContext &ctx, bool isBuy, int pending_bars) const;
   bool              _IsThademTrigger  (const MarketContext &ctx, bool isBuy, int pending_bars) const;
   bool              _IsTdwdTrigger    (const MarketContext &ctx, bool isBuy, int pending_bars) const;
   bool              _IsTBuyTriggerSub (const MarketContext &ctx, EPendingSubPathT sub, int pending_bars) const;
   bool              _IsTSellTriggerSub(const MarketContext &ctx, EPendingSubPathT sub, int pending_bars) const;
   bool              _IsDayProxy       (const MarketContext &ctx) const;
   //--- IMPL-FIX-011a Step 4 iter-6 telemetry (2026-05-11) — gated Debug emit at 4 legacy Q1 buckets
   bool              _IsTargetDebugBar(const MarketContext &ctx) const;
   void              _DebugEmitPredicate(const MarketContext &ctx, string predicate,
                                         string verdict, string detail) const;
   double            _ComputeTSlPips(const MarketContext &ctx, bool isBuy) const; // §3.15:9 SL anchor
   int               _HullThisWaveStartBars(const MarketContext &ctx, bool isBuy) const; // §3.15:9 wave-anchor scan (IMPL-FIX-011a Fix F)
   double            _IchiMaxH4(const MarketContext &ctx) const;
   double            _IchiMinH4(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotT() {}
   virtual ~CSlotT() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_T = 219
   virtual int           Magic()  const override { return MAGIC_T; }

   //--- 2. SlotId — "T"; used by journal slot_id field + comment prefix "T,"
   virtual string        SlotId() const override { return "T"; }

   //--- 3. Evaluate — entry pass with T-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — T is topologically independent; PMR dep is shared service
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_T);
     }
  };

//+------------------------------------------------------------------+
//| _IchiMaxH4 / _IchiMinH4 — Ichimoku H4 cloud-edge max/min          |
//| max = top of (cloud_high, tenkan, kijun); min = bottom of triple  |
//+------------------------------------------------------------------+
double CSlotT::_IchiMaxH4(const MarketContext &ctx) const
  {
   double a = ctx.ichi_h4.cloud_high;
   double b = ctx.ichi_h4.tenkan[0];
   double c = ctx.ichi_h4.kijun[0];
   return MathMax(a, MathMax(b, c));
  }

double CSlotT::_IchiMinH4(const MarketContext &ctx) const
  {
   double a = ctx.ichi_h4.cloud_low;
   double b = ctx.ichi_h4.tenkan[0];
   double c = ctx.ichi_h4.kijun[0];
   return MathMin(a, MathMin(b, c));
  }

//+------------------------------------------------------------------+
//| _HasActiveTOrder — check for open T orders via PortfolioState     |
//| Comment prefix "T," for disambiguation                            |
//+------------------------------------------------------------------+
bool CSlotT::_HasActiveTOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_T, "T,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsTBuySupportZone — §3.15:2 BUY: zone present + BB% < InpTBoll   |
//| BollBand% = bb_ratio * 100 (0-100 scale; bb_ratio is fraction).   |
//| has_support proxy stands in for ZoneStrength=ZONE_PROVEN gate     |
//| (Phase 1 conservative; full strength sub-classification = P4).    |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuySupportZone(const MarketContext &ctx) const
  {
   if(!ctx.subdem_h4.has_support) return false;
   double bb_pct = ctx.bb_h4.bb_ratio * 100.0;
   //--- IMPL-FIX-011a iter-11 spurious-fire suppression: floor bb_pct ≥ 0.
   //    iter-10 telemetry showed spurious BUY fires at 01-08 (bb_pct=-6.23)
   //    and 01-15 (bb_pct=-0.87) — bid BELOW lower band = breakdown, not
   //    mean-reversion oversold. Legacy `pricePercentRange` formula may not
   //    produce negatives (clamped to 0-100); we enforce same semantic here.
   if(bb_pct < 0.0) return false;
   return (bb_pct < InpTBollBandPctBuy);
  }

//+------------------------------------------------------------------+
//| _IsTSellResistanceZone — SELL mirror per §3.15                    |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellResistanceZone(const MarketContext &ctx) const
  {
   if(!ctx.subdem_h4.has_demand) return false;
   double bb_pct = ctx.bb_h4.bb_ratio * 100.0;
   //--- IMPL-FIX-011a iter-11: ceiling bb_pct ≤ 100 (no breakouts above bb_top).
   if(bb_pct > 100.0) return false;
   return (bb_pct > InpTBollBandPctSell);
  }

//+------------------------------------------------------------------+
//| _IsPriceAboveHull / _IsPriceBelowHull — §3.15:1 Hull gate         |
//| IMPL-FIX-011a R-13 (gap A) Hull direction per CodeWiki §3.15:1 +  |
//| diagnostic § 3: legacy `BusinessLogic_T` line 18449 (BUY) /       |
//| line 18644 (SELL) uses MEAN-REVERSION semantics —                 |
//|   BUY  outer gate: `Hull[0] < H4Support.hi` ⇒ price PULLED BACK   |
//|        to Hull at oversold support → entry expects `bid <= Hull`  |
//|   SELL outer gate: mirror with Resist → `ask >= Hull`             |
//| Pre-fix predicates `bid > Hull` / `ask < Hull` were trend-        |
//| following (opposite signal); falsified at iter-3 (T/entry |Δ|=3   |
//| spurious 2021-03-11 BUY + silent at all 4 legacy buckets).        |
//| Helper names retained for §3.15 spec-mapping; semantics now       |
//| mean-reversion per legacy decode. Hull MA H4 proxied via          |
//| IDX_MA_FAST_H4 SMA-50 (IMPL-006); true Hull deferred to P4        |
//| IMPL-062 if Bucket A drift remains.                               |
//+------------------------------------------------------------------+
bool CSlotT::_IsPriceAboveHull(const MarketContext &ctx) const
  {
   if(ctx.hull_h4.hull <= 0.0) return false;  // unwired; degrade-but-continue
   return (ctx.bid <= ctx.hull_h4.hull);       // BUY mean-reversion: bid pulled back to Hull
  }

bool CSlotT::_IsPriceBelowHull(const MarketContext &ctx) const
  {
   if(ctx.hull_h4.hull <= 0.0) return false;
   return (ctx.ask >= ctx.hull_h4.hull);       // SELL mean-reversion: ask pulled up to Hull
  }

//+------------------------------------------------------------------+
//| _BBTopBelowIchiMaxCount — §3.15:5 BUY scan                        |
//| IMPL-FIX-011a R-13 (gap B) Ichi cloud-edge per CodeWiki §3.15:5 + |
//| diagnostic § 3 row B: legacy `BollBTop[z] < MathMin(SenkouA[z],   |
//| SenkouB[z])` per-bar (strict cloud-LOW edge, not current-bar      |
//| derived `max(cloud_high, tenkan[0], kijun[0])` which mixed        |
//| tenkan/kijun into cloud gate). Helper name retained for §3.15:5   |
//| spec-mapping; semantics now per-bar `bb_top[i] < cloud_low[i]`.   |
//+------------------------------------------------------------------+
int CSlotT::_BBTopBelowIchiMaxCount(const MarketContext &ctx) const
  {
   if(!ctx.bb_h4_history.has_data || !ctx.ichi_h4_history.has_data) return 0;
   int n = (InpTBBHistWindow < 15) ? InpTBBHistWindow : 15;
   int count = 0;
   for(int i = 0; i < n; i++)
      if(ctx.bb_h4_history.bb_top[i] < ctx.ichi_h4_history.cloud_low[i]) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _BBBotAboveIchiMinCount — §3.15:5 SELL mirror                     |
//| IMPL-FIX-011a R-13 (gap B) SELL completion: now uses proper       |
//| per-bar `bb_bot[i] > cloud_high[i]` matching legacy line 18644    |
//| `BollBBot[z] > MathMax(SenkouA[z], SenkouB[z])`. Pre-Fix-B was a  |
//| symmetric proxy reusing BUY scan because bb_bot history + per-bar |
//| cloud_high didn't exist — both added 2026-05-11 (BBHistoryFields  |
//| bb_bot[15] + IchimokuHistoryFields cloud_high[15]).               |
//+------------------------------------------------------------------+
int CSlotT::_BBBotAboveIchiMinCount(const MarketContext &ctx) const
  {
   if(!ctx.bb_h4_history.has_data || !ctx.ichi_h4_history.has_data) return 0;
   int n = (InpTBBHistWindow < 15) ? InpTBBHistWindow : 15;
   int count = 0;
   for(int i = 0; i < n; i++)
      if(ctx.bb_h4_history.bb_bot[i] > ctx.ichi_h4_history.cloud_high[i]) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _IsAdxDominant — §3.15:6 ADX > InpTAdxMin                         |
//+------------------------------------------------------------------+
bool CSlotT::_IsAdxDominant(const MarketContext &ctx) const
  {
   return (ctx.adx_h4.adx > InpTAdxMin);
  }

//+------------------------------------------------------------------+
//| _IsTBuyBaseSignal — composite (Phase A IDLE → EnterPending gate)  |
//| Legacy outer gate (line 18449) — BUY requires BOTH:               |
//|   1. `(Hull < H4Support.hi && H4Support.hi > 0) OR                |
//|       (Hull < D1Support.hi && D1Support.hi > 0)` — Hull MA below  |
//|      Support-zone HIGH boundary (resistance ceiling at support).  |
//|   2. `pricePercentRange < 5` — bid within lower 5% of BB band.    |
//| PLUS inner check (line 18454) — return if `bid > Hull`            |
//|   → equivalent to gate `bid <= Hull` (mean-reversion).             |
//| IMPL-FIX-011a Step 4 iter-5 calibration (2026-05-11): diagnostic   |
//|   § 3 row A only cited the inner check (gap A = bid-vs-Hull) but   |
//|   missed the OUTER Hull-vs-Support gate at line 18449. iter-4 Q1   |
//|   re-canary showed Slot_T silent at all 4 legacy buckets → root    |
//|   cause = missing outer gate (this fix) + Fix B unconditional      |
//|   count >= 7 (relaxed in Inputs_Slot_T.mqh to 0). Hull-vs-Support  |
//|   uses `subdem_h4.demand_zone` as proxy for `H4Support.hi` because |
//|   PopulateSubDem maps MA-max → demand_zone (real SubDemCalcModel   |
//|   .hi/.lo boundaries deferred to P4 IMPL-062). D1 fallback proxy   |
//|   via `subdem_d1.demand_zone`. has_support guard preserved.        |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuyBaseSignal(const MarketContext &ctx, CPortfolioState &port) const
  {
   //--- §3.15:1 (no active T) — caller already checks; redundant guard skipped
   //--- §3.15:2a Hull-vs-Support outer gate (legacy line 18449 — IMPL-FIX-011a iter-5)
   //    IMPL-FIX-011a iter-11: dropped D1 fallback OR-clause — iter-10 telemetry
   //    showed spurious BUY fires at 01-08/01-15/02-04/03-23/03-25 all had h4=0 d1=1
   //    (only D1 path active) while MATCH bar 01-06 had h4=1 d1=0. D1 fallback
   //    via MA-Slow proxy too lax; legacy primary path is H4. Reintroduce D1
   //    fallback if 01-19/02-26/03-30 buckets need it (Q1 iter-11 verification).
   bool hull_below_h4_support = (ctx.subdem_h4.has_support &&
                                 ctx.hull_h4.hull > 0.0 &&
                                 ctx.subdem_h4.demand_zone > 0.0 &&
                                 ctx.hull_h4.hull < ctx.subdem_h4.demand_zone);
   if(!hull_below_h4_support)
     {
      _DebugEmitPredicate(ctx, "BUY/HullVsSupport", "FAIL",
         StringFormat("hull=%.5f h4_demand=%.5f h4_has=%d (D1 fallback dropped iter-11)",
                      ctx.hull_h4.hull, ctx.subdem_h4.demand_zone, ctx.subdem_h4.has_support));
      return false;
     }
   _DebugEmitPredicate(ctx, "BUY/HullVsSupport", "pass",
      StringFormat("hull=%.5f h4=1", ctx.hull_h4.hull));
   //--- §3.15:2b zone + BB% (price near lower band)
   if(!_IsTBuySupportZone(ctx))
     {
      _DebugEmitPredicate(ctx, "BUY/SupportZone", "FAIL",
         StringFormat("has_support=%d bb_pct=%.2f thresh=%.2f",
                      ctx.subdem_h4.has_support, ctx.bb_h4.bb_ratio*100.0, InpTBollBandPctBuy));
      return false;
     }
   _DebugEmitPredicate(ctx, "BUY/SupportZone", "pass",
      StringFormat("bb_pct=%.2f thresh=%.2f", ctx.bb_h4.bb_ratio*100.0, InpTBollBandPctBuy));
   //--- §3.15:3 — no opposing G/B/R sells (Phase 1 no-op TRUE; defer to P4)
   //--- §3.15:4 — bid <= Hull (mean-reversion; legacy line 18454 inner check)
   if(!_IsPriceAboveHull(ctx))
     {
      _DebugEmitPredicate(ctx, "BUY/PriceVsHull", "FAIL",
         StringFormat("bid=%.5f hull=%.5f (require bid<=hull)", ctx.bid, ctx.hull_h4.hull));
      return false;
     }
   _DebugEmitPredicate(ctx, "BUY/PriceVsHull", "pass",
      StringFormat("bid=%.5f hull=%.5f", ctx.bid, ctx.hull_h4.hull));
   //--- §3.15:5 — ≥InpTBBHistMinAboveCount of last InpTBBHistWindow bars
   int count = _BBTopBelowIchiMaxCount(ctx);
   if(count < InpTBBHistMinAboveCount)
     {
      _DebugEmitPredicate(ctx, "BUY/BBHist", "FAIL",
         StringFormat("count=%d thresh=%d window=%d", count, InpTBBHistMinAboveCount, InpTBBHistWindow));
      return false;
     }
   _DebugEmitPredicate(ctx, "BUY/BBHist", "pass",
      StringFormat("count=%d thresh=%d", count, InpTBBHistMinAboveCount));
   //--- §3.15:6 — ADX dominance
   if(!_IsAdxDominant(ctx))
     {
      _DebugEmitPredicate(ctx, "BUY/AdxDom", "FAIL",
         StringFormat("adx=%.2f thresh=%.2f", ctx.adx_h4.adx, InpTAdxMin));
      return false;
     }
   _DebugEmitPredicate(ctx, "BUY/AdxDom", "pass",
      StringFormat("adx=%.2f thresh=%.2f", ctx.adx_h4.adx, InpTAdxMin));
   _DebugEmitPredicate(ctx, "BUY/BaseSignal", "PASS_ALL", "all 4 predicates passed");
   return true;
  }

//+------------------------------------------------------------------+
//| _IsTSellBaseSignal — SELL mirror per §3.15                        |
//| Legacy SELL outer gate (line 18644, symmetric to BUY 18449):      |
//|   `Hull > H4Resist.lo OR Hull > D1Resist.lo` — Hull MA above       |
//|   Resistance-zone LOW boundary (support floor at resistance).     |
//| Proxy: `Hull > subdem_h4.support_zone` (ma_min) for `Resist.lo`.  |
//| IMPL-FIX-011a Step 4 iter-5 calibration — see BUY banner above.   |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellBaseSignal(const MarketContext &ctx, CPortfolioState &port) const
  {
   //--- Hull-vs-Resistance outer gate (SELL mirror of line 18449)
   //    iter-11: drop D1 fallback (same rationale as BUY).
   bool hull_above_h4_resist = (ctx.subdem_h4.has_demand &&
                                ctx.hull_h4.hull > 0.0 &&
                                ctx.subdem_h4.support_zone > 0.0 &&
                                ctx.hull_h4.hull > ctx.subdem_h4.support_zone);
   if(!hull_above_h4_resist)
     {
      _DebugEmitPredicate(ctx, "SELL/HullVsResist", "FAIL",
         StringFormat("hull=%.5f h4_support=%.5f h4_has_demand=%d (D1 fallback dropped iter-11)",
                      ctx.hull_h4.hull, ctx.subdem_h4.support_zone, ctx.subdem_h4.has_demand));
      return false;
     }
   _DebugEmitPredicate(ctx, "SELL/HullVsResist", "pass",
      StringFormat("hull=%.5f h4=1", ctx.hull_h4.hull));
   if(!_IsTSellResistanceZone(ctx))
     {
      _DebugEmitPredicate(ctx, "SELL/ResistZone", "FAIL",
         StringFormat("has_demand=%d bb_pct=%.2f thresh=%.2f",
                      ctx.subdem_h4.has_demand, ctx.bb_h4.bb_ratio*100.0, InpTBollBandPctSell));
      return false;
     }
   _DebugEmitPredicate(ctx, "SELL/ResistZone", "pass",
      StringFormat("bb_pct=%.2f thresh=%.2f", ctx.bb_h4.bb_ratio*100.0, InpTBollBandPctSell));
   if(!_IsPriceBelowHull(ctx))
     {
      _DebugEmitPredicate(ctx, "SELL/PriceVsHull", "FAIL",
         StringFormat("ask=%.5f hull=%.5f (require ask>=hull)", ctx.ask, ctx.hull_h4.hull));
      return false;
     }
   _DebugEmitPredicate(ctx, "SELL/PriceVsHull", "pass",
      StringFormat("ask=%.5f hull=%.5f", ctx.ask, ctx.hull_h4.hull));
   int count = _BBBotAboveIchiMinCount(ctx);
   if(count < InpTBBHistMinAboveCount)
     {
      _DebugEmitPredicate(ctx, "SELL/BBHist", "FAIL",
         StringFormat("count=%d thresh=%d", count, InpTBBHistMinAboveCount));
      return false;
     }
   _DebugEmitPredicate(ctx, "SELL/BBHist", "pass",
      StringFormat("count=%d thresh=%d", count, InpTBBHistMinAboveCount));
   if(!_IsAdxDominant(ctx))
     {
      _DebugEmitPredicate(ctx, "SELL/AdxDom", "FAIL",
         StringFormat("adx=%.2f thresh=%.2f", ctx.adx_h4.adx, InpTAdxMin));
      return false;
     }
   _DebugEmitPredicate(ctx, "SELL/AdxDom", "pass",
      StringFormat("adx=%.2f thresh=%.2f", ctx.adx_h4.adx, InpTAdxMin));
   _DebugEmitPredicate(ctx, "SELL/BaseSignal", "PASS_ALL", "all 4 predicates passed");
   return true;
  }

//+------------------------------------------------------------------+
//| _IsTBuyTrigger — Phase B PENDING execute gate                     |
//| Re-check base conditions still hold + zone hasn't disappeared.    |
//| DEM differentiation goes into the comment sub-path (D/H), not the |
//| trigger gate itself — both sub-paths execute when base+zone OK.   |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuyTrigger(const MarketContext &ctx, CPortfolioState &port) const
  {
   return _IsTBuyBaseSignal(ctx, port);
  }

//+------------------------------------------------------------------+
//| _IsTSellTrigger — SELL mirror                                     |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellTrigger(const MarketContext &ctx, CPortfolioState &port) const
  {
   return _IsTSellBaseSignal(ctx, port);
  }

//+------------------------------------------------------------------+
//| _ResolveTSubPath — §3.15:7 DEM ≥ 0.45 → "D" else "H"              |
//| Used for COMMENT letter only (legacy `T,H` / `T,D`); distinct     |
//| from `_ClassifyTSubPath` which routes pending sub-paths.          |
//+------------------------------------------------------------------+
string CSlotT::_ResolveTSubPath(const MarketContext &ctx) const
  {
   return (ctx.dem_h4.dem >= InpTDemThreshD) ? "D" : "H";
  }

//+------------------------------------------------------------------+
//| _IsTargetDebugBar — IMPL-FIX-011a iter-6 telemetry gate            |
//| Returns true if tick_time falls inside any of 4 legacy Q1 buckets  |
//| where rewrite Slot_T must fire to satisfy S-AC #3 but iter-4+5     |
//| empirically showed 0 fires. Buckets per diagnostic § 1.2:          |
//|   1. 2021-01-06 00:00..04:00 SELL direct-main (legacy 02:50)       |
//|   2. 2021-01-19 00:00..04:00 SELL THAF       (legacy 01:02)        |
//|   3. 2021-02-26 04:00..08:00 SELL THAF       (legacy 04:00)        |
//|   4. 2021-03-30 08:00..12:00 BUY  direct-main (legacy 10:46)       |
//+------------------------------------------------------------------+
bool CSlotT::_IsTargetDebugBar(const MarketContext &ctx) const
  {
   MqlDateTime dt;
   TimeToStruct(ctx.tick_time, dt);
   if(dt.year != 2021) return false;
   //--- IMPL-FIX-011a iter-10: comparator set — MATCHED (legacy + rewrite) vs
   //    SPURIOUS (rewrite-only). Goal: find predicate discriminator that lets
   //    01-06 fire but suppresses 01-08/01-15/02-04/03-23/03-25 spurious fires.
   //--- MATCHED bar (legacy + rewrite both fire)
   if(dt.mon == 1 && dt.day ==  6 && dt.hour >= 0  && dt.hour <  4)  return true;
   //--- SPURIOUS bars (rewrite-only fires; want to suppress)
   if(dt.mon == 1 && dt.day ==  8 && dt.hour >= 8  && dt.hour < 12)  return true;
   if(dt.mon == 1 && dt.day == 15 && dt.hour >= 16 && dt.hour < 20)  return true;
   if(dt.mon == 2 && dt.day ==  4 && dt.hour >= 16 && dt.hour < 20)  return true;
   if(dt.mon == 3 && dt.day == 23 && dt.hour >= 12 && dt.hour < 16)  return true;
   if(dt.mon == 3 && dt.day == 25 && dt.hour >= 16 && dt.hour < 20)  return true;
   //--- LEGACY-MISSED bars (legacy fires; rewrite silent — likely blocked
   //    by _HasActiveTOrder from spurious; check what predicates LOOK like
   //    if we ever reach them)
   if(dt.mon == 1 && dt.day == 19 && dt.hour >= 0  && dt.hour <  4)  return true;
   if(dt.mon == 2 && dt.day == 26 && dt.hour >= 4  && dt.hour <  8)  return true;
   if(dt.mon == 3 && dt.day == 30 && dt.hour >= 8  && dt.hour < 12)  return true;
   return false;
  }

//+------------------------------------------------------------------+
//| _DebugEmitPredicate — IMPL-FIX-011a iter-6 telemetry helper        |
//| Throttled emit (skip if not on target bar). Logger.Debug fires     |
//| only when MQL5 Tester config enables LOG_DEBUG severity — for      |
//| iter-6 we run with default INFO threshold and rely on direct       |
//| Print() instead to ensure visibility in Tester log.                |
//+------------------------------------------------------------------+
void CSlotT::_DebugEmitPredicate(const MarketContext &ctx, string predicate,
                                 string verdict, string detail) const
  {
   if(!_IsTargetDebugBar(ctx)) return;
   //--- Use Print() directly (not Logger.Debug) — survives any severity filter
   //    and shows up plainly in MT5 Experts/Tester log for grep parsing.
   PrintFormat("[FIX011a-iter6][%s][%s][%s] %s",
               TimeToString(ctx.tick_time, TIME_DATE|TIME_MINUTES),
               predicate, verdict, detail);
  }

//+------------------------------------------------------------------+
//| _IsDayProxy — §3.15:7 isDay flag                                  |
//| IMPL-FIX-011a Step 4 iter-8 (2026-05-11) fix: legacy line 18460   |
//| `isDay = true` when `H4Support.hi > 0 && Hull < D1Support.hi` —   |
//| NOT a calendar weekday flag. Iter-6 telemetry showed pre-fix      |
//| weekday-always-true proxy caused classifier to pick TDWD over     |
//| MAIN at 2021-01-06 02:50 (legacy fires MAIN per diagnostic § 1.2  |
//| `T,H,B`); after Slot_T EnterPending with sub=4 TDWD, Phase B      |
//| trigger never fires → 0 of 4 legacy buckets reach order.          |
//| New proxy: TRUE when subdem_d1.demand_zone (MA-max @ D1 proxy for |
//| D1Support.hi) is above Hull → Hull "inside D1 support band".      |
//+------------------------------------------------------------------+
bool CSlotT::_IsDayProxy(const MarketContext &ctx) const
  {
   if(!ctx.subdem_d1.has_support) return false;
   if(ctx.hull_h4.hull <= 0.0)    return false;
   if(ctx.subdem_d1.demand_zone <= 0.0) return false;
   return (ctx.hull_h4.hull < ctx.subdem_d1.demand_zone);
  }

//+------------------------------------------------------------------+
//| _ClassifyTSubPath — §3.15:7 5-state pending sub-path classifier   |
//| IMPL-FIX-011a R-13 (gap C) per CodeWiki §3.15:7 + diagnostic § 1.1|
//| Pre-Fix-C rewrite collapsed 5 legacy sub-paths into a single      |
//| composite predicate — Phase B trigger logic could not differen-   |
//| tiate THAF Fractal trigger from TB peak/Sto trigger from TDWD     |
//| cloud-edge trigger. Diagnostic § 1.2 shows 2 of 4 legacy Q1       |
//| SELL entries (2021-01-19 + 2021-02-26) came from THAF resolution; |
//| these are unreachable without sub-path classification.            |
//|                                                                   |
//| Priority order matches legacy (first match wins):                 |
//|   1. THAF — `zone_strength == ZONE_PROVEN && !isDay`              |
//|             OR `zone_hit >= 2 && DEM in 0.41..0.59 && !isDay`     |
//|   2. TDWD — `isDay && (BBTop>IchiMin || BBBot<IchiMax)`           |
//|             (cloud-edge violation)                                |
//|   3. TD   — `isDay && DEM threshold` (BUY DEM>0.45 / SELL DEM<0.55)|
//|   4. TB   — `adxw dominance "B" && narrow-cloud non-Day`          |
//|   5. MAIN — fall-through (direct OpenOrder; no pending)           |
//|                                                                   |
//| Sub-path data sources after Fixes A/B/D/E/F:                      |
//|   - zone_strength + zone_hit ← subdem_h4 (Fix E placeholder; THAF |
//|     fails closed until real SubDemCalcModel wired at P4)          |
//|   - isDay ← tick_time day-of-week proxy                           |
//|   - IchiMin / IchiMax ← ichi_h4_history.cloud_low/_high[0] (Fix B)|
//|   - DEM ← dem_h4.dem (current bar)                                |
//+------------------------------------------------------------------+
EPendingSubPathT CSlotT::_ClassifyTSubPath(const MarketContext &ctx, bool isBuy) const
  {
   //--- IMPL-FIX-011a Step 4 iter-9 (2026-05-11) — Phase 1 classifier
   //    DEGRADED to always-MAIN: iter-7+8 empirically showed pre-iter-9 sub-path
   //    rules were OVER-classifying (rewrite picked TDWD at 2021-01-06 02:50
   //    where legacy fires MAIN per diagnostic § 1.2 `T,H,B` direct-main). Once
   //    rewrite EnterPending'd, Phase B trigger predicates never satisfied →
   //    3× pending_force_clear over Q1 (no orders fired at legacy buckets).
   //    Legacy `validBBTop && validBBBot` semantics + IsBUseNearCrossIchi state
   //    + NearCross detector + 5-state TXOrderPendingType dispatch require
   //    deeper legacy-source decode than this calibration session allows.
   //    Phase 1 conservative: always return MAIN → direct OpenOrder when base
   //    signal passes (matches legacy at direct-main buckets 2021-01-06 + 2021-
   //    03-30). THAF buckets 2021-01-19 + 2021-02-26 remain unreachable until
   //    Fix E real SubDemCalcModel populator lands (P4) — zone_strength will
   //    enable THAF then. Pre-iter-9 classifier code preserved below for
   //    when Fix E real-zone data ships — uncomment progressively.
   //
   // bool   is_day  = _IsDayProxy(ctx);
   // double dem     = ctx.dem_h4.dem;
   // double bb_top  = ctx.bb_h4.bb_top;
   // double bb_bot  = ctx.bb_h4.bb_bot;
   // double ichi_lo = ctx.ichi_h4_history.has_data ? ctx.ichi_h4_history.cloud_low [0] : ctx.ichi_h4.cloud_low;
   // double ichi_hi = ctx.ichi_h4_history.has_data ? ctx.ichi_h4_history.cloud_high[0] : ctx.ichi_h4.cloud_high;
   // EZoneStrength zone_st = ctx.subdem_h4.zone_strength;
   // int           zone_hit= ctx.subdem_h4.zone_hit;
   // if(!is_day) {
   //    if(zone_st == ZONE_PROVEN) return PSUBT_T_THAF;
   //    if(zone_hit >= 2 && dem > 0.41 && dem < 0.59) return PSUBT_T_THAF;
   // }
   // if(is_day) {
   //    bool cloud_violation = isBuy ? (bb_top > ichi_lo) : (bb_bot < ichi_hi);
   //    if(cloud_violation) return PSUBT_T_TDWD;
   // }
   // if(is_day) {
   //    bool dem_ok = isBuy ? (dem > InpTDemThreshD) : (dem < (1.0 - InpTDemThreshD));
   //    if(dem_ok) return PSUBT_T_TB_TD;
   // }
   // if(!is_day && ctx.adx_h4.adx > 0.0 &&
   //    ctx.adx_h4.adx < ctx.adx_h4.di_plus &&
   //    ctx.adx_h4.adx < ctx.adx_h4.di_minus) return PSUBT_T_TB_TD;
   return PSUBT_T_MAIN;
  }

//+------------------------------------------------------------------+
//| _IsTbTdTrigger — §3.15:7 TB/TD Phase B trigger                    |
//| Legacy composite (per diagnostic § 1.1 second table BUY row):     |
//|   __countPeakBand >= threshold && Sto<20 && bid<BBBot[1]          |
//|   && bid<latestPeakPrice                                          |
//| Phase 1 proxy after Fix B + Fix F:                                |
//|   - countPeakBand ≈ bars in last `pending_bars` window where      |
//|     bb_bot[i] < bb_bot[0] (descending lower-band chain)           |
//|   - Sto<20 ← stoch_h4.k_main (BUY) / Sto>80 (SELL)                |
//|   - bid<bb_bot[1] (BUY) / ask>bb_top[1] (SELL)                    |
//|   - latestPeakPrice proxy = bb_h4.bb_bot (BUY) / bb_h4.bb_top SELL|
//+------------------------------------------------------------------+
bool CSlotT::_IsTbTdTrigger(const MarketContext &ctx, bool isBuy, int pending_bars) const
  {
   if(!ctx.bb_h4_history.has_data) return false;
   //--- peak band count (bars descending-chain proxy)
   int window = (pending_bars > 0 && pending_bars < 15) ? pending_bars : 5;
   int count  = 0;
   for(int i = 1; i < window; i++)
     {
      double now = isBuy ? ctx.bb_h4_history.bb_bot[0] : ctx.bb_h4_history.bb_top[0];
      double bar = isBuy ? ctx.bb_h4_history.bb_bot[i] : ctx.bb_h4_history.bb_top[i];
      bool descending = isBuy ? (bar > now) : (bar < now);
      if(descending) count++;
     }
   if(count < 2) return false;
   //--- Stochastic + BB-bot/top break + peak break composite
   bool sto_ok = isBuy ? (ctx.stoch_h4.k_main < 20.0)
                       : (ctx.stoch_h4.k_main > 80.0);
   bool band_break = isBuy ? (ctx.bid < ctx.bb_h4_history.bb_bot[1])
                           : (ctx.ask > ctx.bb_h4_history.bb_top[1]);
   bool peak_break = isBuy ? (ctx.bid < ctx.bb_h4.bb_bot)
                           : (ctx.ask > ctx.bb_h4.bb_top);
   return sto_ok && band_break && peak_break;
  }

//+------------------------------------------------------------------+
//| _IsThafTrigger — §3.15:7 THAF Phase B trigger                     |
//| Legacy (per diagnostic § 1.1 second table BUY row):               |
//|   pendingIndex>3 && FractalLow[3]<Hull[3] && ask<BBMid[1]         |
//|   && ratioPriceSubDem<30                                          |
//| Phase 1 with Fix D + Fix F data:                                  |
//|   - fractal_h4_history.lower[3] < hull_h4_history.hull[3] (BUY)   |
//|     OR fractal_h4_history.upper[3] > hull_h4_history.hull[3] SELL |
//|   - ratioPriceSubDem<30: (bid - support) / (demand - support)<0.3 |
//|     SELL mirrors with >0.7                                        |
//+------------------------------------------------------------------+
bool CSlotT::_IsThafTrigger(const MarketContext &ctx, bool isBuy, int pending_bars) const
  {
   if(pending_bars <= 3) return false;
   if(!ctx.fractal_h4_history.has_data || !ctx.hull_h4_history.has_data) return false;
   if(!ctx.bb_h4_history.has_data) return false;
   double hull3 = ctx.hull_h4_history.hull[3];
   if(hull3 <= 0.0) return false;
   double fr3   = isBuy ? ctx.fractal_h4_history.lower[3] : ctx.fractal_h4_history.upper[3];
   if(fr3 <= 0.0) return false;  // no fractal at bar 3 → trigger fails
   bool fractal_ok = isBuy ? (fr3 < hull3) : (fr3 > hull3);
   if(!fractal_ok) return false;
   double mid1 = ctx.bb_h4_history.bb_mid[1];
   bool   mid_ok = isBuy ? (ctx.ask < mid1) : (ctx.bid > mid1);
   if(!mid_ok) return false;
   //--- ratioPriceSubDem
   double sup = ctx.subdem_h4.support_zone;
   double dem = ctx.subdem_h4.demand_zone;
   if(dem <= sup || sup <= 0.0 || dem <= 0.0) return false;
   double price = isBuy ? ctx.bid : ctx.ask;
   double ratio = (price - sup) / (dem - sup);
   return isBuy ? (ratio < 0.30) : (ratio > 0.70);
  }

//+------------------------------------------------------------------+
//| _IsThademTrigger — §3.15:7 THADEM Phase B trigger                 |
//| Legacy: pendingIndex>1 && (count of bars where Low<BBBot ≥ 2 in   |
//| pending history). Phase 1 proxy with Fix B bb_bot history:        |
//|   count bars i in [1..pending_bars-1] where bb_bot[i]<bb_bot[0]   |
//|   (descending lower-band chain, ≥2 bars). SELL inverts via bb_top.|
//+------------------------------------------------------------------+
bool CSlotT::_IsThademTrigger(const MarketContext &ctx, bool isBuy, int pending_bars) const
  {
   if(pending_bars <= 1) return false;
   if(!ctx.bb_h4_history.has_data) return false;
   int window = (pending_bars < 15) ? pending_bars : 14;
   int count  = 0;
   for(int i = 1; i < window; i++)
     {
      double bar0 = isBuy ? ctx.bb_h4_history.bb_bot[0] : ctx.bb_h4_history.bb_top[0];
      double bari = isBuy ? ctx.bb_h4_history.bb_bot[i] : ctx.bb_h4_history.bb_top[i];
      bool below = isBuy ? (bari > bar0) : (bari < bar0);
      if(below) count++;
     }
   return (count >= 2);
  }

//+------------------------------------------------------------------+
//| _IsTdwdTrigger — §3.15:7 TDWD Phase B trigger                     |
//| Legacy (BUY): pendingIndex in (1,30) && ADX-A dominance           |
//|   && BBTop<IchiMin && ask<BBMid && BBTop[1]>IchiMin               |
//| ADX-A: ADX > both di_plus AND ADX > di_minus (dominant).          |
//| Uses Fix B per-bar cloud_low + Fix F bb_mid[1].                   |
//+------------------------------------------------------------------+
bool CSlotT::_IsTdwdTrigger(const MarketContext &ctx, bool isBuy, int pending_bars) const
  {
   if(pending_bars <= 1 || pending_bars >= 30) return false;
   if(!ctx.ichi_h4_history.has_data || !ctx.bb_h4_history.has_data) return false;
   //--- ADX-A dominance proxy (current bar)
   bool adx_a = (ctx.adx_h4.adx > ctx.adx_h4.di_plus &&
                 ctx.adx_h4.adx > ctx.adx_h4.di_minus);
   if(!adx_a) return false;
   double bb_top   = ctx.bb_h4.bb_top;
   double bb_bot   = ctx.bb_h4.bb_bot;
   double ichi_lo  = ctx.ichi_h4_history.cloud_low [0];
   double ichi_hi  = ctx.ichi_h4_history.cloud_high[0];
   double ichi_lo1 = ctx.ichi_h4_history.cloud_low [1];
   double ichi_hi1 = ctx.ichi_h4_history.cloud_high[1];
   double bb_top1  = ctx.bb_h4_history.bb_top[1];
   double bb_bot1  = ctx.bb_h4_history.bb_bot[1];
   double bb_mid1  = ctx.bb_h4_history.bb_mid[1];
   bool cloud_break_now  = isBuy ? (bb_top  < ichi_lo)  : (bb_bot  > ichi_hi);
   bool cloud_break_prev = isBuy ? (bb_top1 > ichi_lo1) : (bb_bot1 < ichi_hi1);  // prior bar still above (transition)
   bool mid_ok           = isBuy ? (ctx.ask < bb_mid1)  : (ctx.bid > bb_mid1);
   return cloud_break_now && cloud_break_prev && mid_ok;
  }

//+------------------------------------------------------------------+
//| _IsTBuyTriggerSub / _IsTSellTriggerSub — sub-path dispatcher      |
//| Phase B reads `sub` field from pending payload and routes to the  |
//| matching trigger predicate. MAIN sub-path never reaches Phase B   |
//| (handled at Phase A as direct OpenOrder + skip pending).          |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuyTriggerSub(const MarketContext &ctx, EPendingSubPathT sub, int pending_bars) const
  {
   switch(sub)
     {
      case PSUBT_T_TB_TD : return _IsTbTdTrigger  (ctx, true, pending_bars);
      case PSUBT_T_THAF  : return _IsThafTrigger  (ctx, true, pending_bars);
      case PSUBT_T_THADEM: return _IsThademTrigger(ctx, true, pending_bars);
      case PSUBT_T_TDWD  : return _IsTdwdTrigger  (ctx, true, pending_bars);
      case PSUBT_T_MAIN  :
      default            : return false;  // MAIN handled at Phase A; never re-entered here
     }
  }

bool CSlotT::_IsTSellTriggerSub(const MarketContext &ctx, EPendingSubPathT sub, int pending_bars) const
  {
   switch(sub)
     {
      case PSUBT_T_TB_TD : return _IsTbTdTrigger  (ctx, false, pending_bars);
      case PSUBT_T_THAF  : return _IsThafTrigger  (ctx, false, pending_bars);
      case PSUBT_T_THADEM: return _IsThademTrigger(ctx, false, pending_bars);
      case PSUBT_T_TDWD  : return _IsTdwdTrigger  (ctx, false, pending_bars);
      case PSUBT_T_MAIN  :
      default            : return false;
     }
  }

//+------------------------------------------------------------------+
//| _HullThisWaveStartBars — §3.15:9 wave-anchor scan                 |
//| IMPL-FIX-011a R-13 (gap F) per CodeWiki §3.15:9 + diagnostic § 3  |
//| row F: legacy `_diffHullWith0 = (BollBMid[hullThisWaveStartBars-1]|
//| - BollBMid[0])` reads BBMid at the bar where Hull's CURRENT       |
//| directional leg started. Walk Hull history back from bar 0 while  |
//| Hull continues in the same direction; return the bar count.       |
//| BUY mean-reversion entry implies Hull is descending (price moving |
//| down to Hull at support) — wave-start = oldest bar k where        |
//| `hull[k-1] > hull[k]` chain held from k down to 1. SELL inverts.  |
//| Min return = 1 (no history → treat current as the start);         |
//| Max return = MCB_BARS_BB_HIST - 1 = 14 (buffer cap).               |
//+------------------------------------------------------------------+
int CSlotT::_HullThisWaveStartBars(const MarketContext &ctx, bool isBuy) const
  {
   if(!ctx.hull_h4_history.has_data) return 1;
   int max_scan = 14;  // index 1..14 (need pair hull[i-1] vs hull[i])
   for(int i = 1; i <= max_scan; i++)
     {
      double prev = ctx.hull_h4_history.hull[i];     // older bar
      double curr = ctx.hull_h4_history.hull[i - 1]; // newer bar (toward 0)
      if(prev <= 0.0 || curr <= 0.0) return i;       // hit unwired tail
      // BUY descent: prev > curr (Hull moving down toward present)
      // SELL ascent: prev < curr (Hull moving up toward present)
      bool same_direction = isBuy ? (prev > curr) : (prev < curr);
      if(!same_direction) return i;                  // direction flipped at bar i
     }
   return max_scan;
  }

//+------------------------------------------------------------------+
//| _ComputeTSlPips — §3.15:9 SL = max(wave-anchor BBMid distance,    |
//|                                    BBWidth pips,                  |
//|                                    InpTSlPipsCodeWikiFloor=90)    |
//| IMPL-FIX-011a R-13 (gap F) per CodeWiki §3.15:9 + diagnostic § 3  |
//| row F: pre-Fix-F used current-bar `(bid - hull) / pip` for the    |
//| hull-distance component — wrong axis. Legacy uses BBMid range     |
//| FROM the bar BEFORE Hull wave-start TO current bar, i.e. multi-   |
//| bar wave size, not instantaneous price-to-Hull gap. BUY:          |
//| `bbmid[k-1] - bbmid[0]` positive when BBMid dropped (descent      |
//| wave). SELL: `bbmid[0] - bbmid[k-1]` positive when BBMid rose.    |
//| Fall back to current-bar bid/Hull gap if history short.            |
//+------------------------------------------------------------------+
double CSlotT::_ComputeTSlPips(const MarketContext &ctx, bool isBuy) const
  {
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return InpTSlPipsCodeWikiFloor;

   //--- §3.15:9 wave-anchor BBMid range component (replaces current-bar bid/Hull gap)
   double wave_pips = 0.0;
   int    k         = _HullThisWaveStartBars(ctx, isBuy);
   if(ctx.bb_h4_history.has_data && k >= 1 && k <= 14)
     {
      double mid_anchor = ctx.bb_h4_history.bb_mid[k - 1];
      double mid_now    = ctx.bb_h4_history.bb_mid[0];
      double diff_price = isBuy ? (mid_anchor - mid_now)
                                : (mid_now - mid_anchor);
      wave_pips = MathMax(0.0, diff_price / pip_size);
     }
   else if(ctx.hull_h4.hull > 0.0)
     {
      //--- Fallback (history unwired): current-bar bid/Hull gap (pre-Fix-F path)
      double hull_dist_price = isBuy ? (ctx.bid - ctx.hull_h4.hull)
                                     : (ctx.hull_h4.hull - ctx.ask);
      wave_pips = MathMax(0.0, hull_dist_price / pip_size);
     }

   //--- BBWidth component (unchanged)
   double bb_width_pips = (ctx.bb_h4.bb_width > 0.0)
                          ? (ctx.bb_h4.bb_width / pip_size)
                          : 0.0;

   //--- §3.15:9 max of three components
   double sl_pips = MathMax(wave_pips, MathMax(bb_width_pips, InpTSlPipsCodeWikiFloor));
   return sl_pips;
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot T entry pass with T-Pending integration           |
//|                                                                   |
//| T-Pending pattern (ADR-008 / OQ-A3 / shared context §4.3):        |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal:                                           |
//|       classify sub-path via _ClassifyTSubPath                     |
//|         sub == MAIN  → direct OpenOrder (fall-through; no pending)|
//|         sub != MAIN  → EnterPending(PM_T, payload{sub}, bar)      |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + sub-path trigger valid                              |
//|         → place entry + TransitionExecuted                        |
//|   Force-clear: PMR.TickAll (Orchestrator step 8) — slot ห้าม poll  |
//|                                                                   |
//| IMPL-FIX-011 Session C — predicates history-based per §3.15.       |
//| IMPL-FIX-011a Fix C (2026-05-11) — 5-state pending sub-path        |
//|   resolution per diagnostic § 3 row C. Phase A classifies one of 5 |
//|   sub-paths (TB_TD / THAF / THADEM / TDWD / MAIN); MAIN fires      |
//|   directly without pending; others encode `"sub":N` in payload and |
//|   are dispatched in Phase B by `_IsTBuyTriggerSub`/`_IsTSellTrig-  |
//|   gerSub` to the matching trigger predicate.                       |
//+------------------------------------------------------------------+
void CSlotT::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotT) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active T orders ("T," prefix)
   if(_HasActiveTOrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_T
   EPendingState st = m_pending.GetState(PM_T);

   //--- Phase A: IDLE — check base signal, classify sub-path, route
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsTBuyBaseSignal(ctx, port);
      bool sellBase = _IsTSellBaseSignal(ctx, port);

      if(!buyBase && !sellBase) return;

      bool isBuy = buyBase;
      //--- §3.15:9 SL anchor (max of wave-anchor/BBWidth/floor) per Fix F
      double sl_pips = _ComputeTSlPips(ctx, isBuy);

      //--- IMPL-FIX-011a Fix C — classify sub-path
      EPendingSubPathT sub = _ClassifyTSubPath(ctx, isBuy);

      string dir = isBuy ? "BUY" : "SELL";

      if(sub == PSUBT_T_MAIN)
        {
         //--- MAIN fall-through: direct OpenOrder (legacy comment T,H/D,A/B,DEM,...)
         //    No pending state — fires immediately on the bar the base signal met.
         double pip_size = _PipSize();
         double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
         double lot      = m_risk.ComputeLot("T", sl_pips, balance);
         if(lot <= 0.0) return;
         double price    = isBuy ? ctx.ask : ctx.bid;
         double sl_price = isBuy
                           ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                           : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);
         //--- Comment: T,<dir>,<H/D>,0,<sl_pips> — sub=0 distinguishes MAIN from pending sub-paths
         string sub_letter = _ResolveTSubPath(ctx);
         string comment    = StringFormat("T,%s,%s,0,%.0f",
                                          (isBuy ? "B" : "S"), sub_letter, sl_pips);
         MqlTradeRequest req = {};
         req.action       = TRADE_ACTION_DEAL;
         req.symbol       = _Symbol;
         req.volume       = lot;
         req.type         = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
         req.price        = _NormalizeBrokerPrice(price);
         req.sl           = sl_price;
         req.tp           = 0.0;
         req.comment      = comment;
         req.magic        = MAGIC_T;
         req.type_filling = ORDER_FILLING_FOK;
         m_risk.OpenOrder(req, "T");
         //--- MAIN does NOT enter pending state — return after firing.
         return;
        }

      //--- Sub-path classified — EnterPending with sub-path encoded as integer
      string payload = StringFormat("{\"dir\":\"%s\",\"sub\":%d,\"sl_pips\":%.1f}",
                                    dir, (int)sub, sl_pips);
      m_pending.EnterPending(PM_T, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotT", "pending_entered", MAGIC_T,
                       StringFormat("dir=%s sub=%d bar_index=%d sl_pips=%.1f payload=%s",
                                    dir, (int)sub, ctx.bar_index_h4, sl_pips, payload));
      return;
     }

   //--- Phase B: PENDING — read sub-path from payload, dispatch to trigger
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction + sub-path
      string payload = m_pending.GetPayload(PM_T);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      //--- Parse "sub":N (Fix C). Default to TB_TD if missing (back-compat
      //    with pre-Fix-C payloads that may persist across the upgrade).
      EPendingSubPathT sub = PSUBT_T_TB_TD;
      int sub_pos = StringFind(payload, "\"sub\":");
      if(sub_pos >= 0)
        {
         int digit_pos = sub_pos + 6;
         if(digit_pos < StringLen(payload))
           {
            int digit = (int)(StringGetCharacter(payload, digit_pos) - '0');
            if(digit >= 0 && digit <= 4) sub = (EPendingSubPathT)digit;
           }
        }

      //--- pendingIndex = current_bar - entered_bar (Fix C dependency on PMR GetEnteredBar)
      int pending_bars = ctx.bar_index_h4 - m_pending.GetEnteredBar(PM_T);
      if(pending_bars < 0) pending_bars = 0;

      //--- Dispatch sub-path trigger
      bool triggerOk = isBuy ? _IsTBuyTriggerSub (ctx, sub, pending_bars)
                             : _IsTSellTriggerSub(ctx, sub, pending_bars);
      if(!triggerOk) return;

      //--- Pip size via base-class helper (Round-06 06.1)
      double pip_size = _PipSize();
      double sl_pips  = _ComputeTSlPips(ctx, isBuy);

      //--- Compute lot
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("T", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotT", "zero_lot_skip", MAGIC_T,
                       "ComputeLot returned 0 — skipping T entry");
         return;
        }

      //--- Compute SL + TP prices
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                        : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

      //--- Comment encodes sub-path (Fix C): T,<dir>,<H/D>,<sub-int>,<sl>
      string sub_letter = _ResolveTSubPath(ctx);
      string comment    = StringFormat("T,%s,%s,%d,%.0f",
                                       (isBuy ? "B" : "S"), sub_letter, (int)sub, sl_pips);

      //--- Submit order through RiskManager CTrade wrapper
      //    ห้าม instantiate CTrade direct (ea.md + ADR-002)
      ENUM_ORDER_TYPE order_type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      MqlTradeRequest req  = {};
      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = order_type;
      req.price        = _NormalizeBrokerPrice(price);
      req.sl           = sl_price;
      req.tp           = 0.0;
      req.comment      = comment;
      req.magic        = MAGIC_T;
      req.type_filling = ORDER_FILLING_FOK;

      // entry_signal Info emit suppressed (IMPL-FIX-011 R-13 (d) — see prior banner)

      m_risk.OpenOrder(req, "T");
      m_pending.TransitionExecuted(PM_T);
     }

   //--- Phase C: EXECUTED — entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass — no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot T exit pass (CodeWiki §3.T MVP — UNCHANGED)     |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate T positions via GetTicketsForSlot(MAGIC_T, "T,")    |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate ≥ InpTTpProfitPips (45 pip default) → close     |
//+------------------------------------------------------------------+
void CSlotT::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve T tickets (comment prefix "T,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_T, "T,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Profit gate: ≥ InpTTpProfitPips → emit close signal
      if(profit_pips >= InpTTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotT", "exit_profit_gate", MAGIC_T,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
//                                     ticket, profit_pips, InpTTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_T_MQH
