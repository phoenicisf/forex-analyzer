//+------------------------------------------------------------------+
//| slots/Slot_G2.mqh โ€” Slot G2 implementation (IMPL-026)            |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_G = 208, shared with G (IMPL-025)                  |
//|          CommentParser disambiguates "G2," vs "G," per BR-1.2     |
//| Source:  CodeWiki ยง3.G2; TD-02 ยง5.4; ADR-002; ADR-012            |
//|                                                                   |
//| M-size MVP โ€” 3 of CodeWiki ยง3.G2 conditions:                     |
//|   1. No active G2 orders (magic 208 with "G2," prefix)            |
//|   2. Force crossover in continuation range:                       |
//|        BUY  = F[1]>0 โง F[2]>-0.2 (in range, not exhausted)       |
//|        SELL = F[1]<0 โง F[2]<+0.2 (mirror)                         |
//|   3. Price outside Ichimoku cloud (or near retest โ€” bid/cloud edge)|
//| Deferred to P4 IMPL-062: GPause / WPR-sanity / DeMarker /        |
//|   Force-wave-span exhaustion / lot scaling when G already open    |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate โฅ 30 pip (lighter than G's 50)                   |
//|   Stub: if(m_xslot != NULL && false /*IMPL-053*/) {...}           |
//|   Real CCrossSlotCoordinator coupling = IMPL-053                  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G2", InpG2SlPipsFloor, balance)    |
//| Comment: "G2,F1,N,1,SL" per CodeWiki ยง3.G2 format                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected)           |
//|                                                                   |
//| Shared-magic note: PortfolioState.GetByMagic(208) returns G+G2    |
//| aggregate. GetTicketsForSlot(208, "G2,", tickets) filters own G2. |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_G2_MQH
#define PHOENICISNEX_SLOTS_SLOT_G2_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_G2.mqh"

//+------------------------------------------------------------------+
//| CSlotG2 โ€” Slot G2 derived class (ADR-002 CSlotBase contract)      |
//|                                                                   |
//| Wave-helper role: lighter entry conditions + smaller lot factor   |
//| than G. Both share MAGIC_G (208); comment prefix "G2," used in   |
//| all OrderSend calls to disambiguate from G's "G," prefix.        |
//|                                                                   |
//| GetTicketsForSlot(208, "G2,", tickets) filters own orders.        |
//+------------------------------------------------------------------+
class CSlotG2 : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _IsG2BuySignal(const MarketContext &ctx) const;
   bool              _IsG2SellSignal(const MarketContext &ctx) const;
   bool              _IsPriceAboveCloud(const MarketContext &ctx) const;
   bool              _IsPriceBelowCloud(const MarketContext &ctx) const;
   bool              _HasActiveG2Order(CPortfolioState &port) const;
   double            _CloudHigh(const MarketContext &ctx) const;
   double            _CloudLow(const MarketContext &ctx) const;

   //--- IMPL-FIX-011 Session C — §3.7:5/6/9 history-based predicates
   bool              _IsAdxNotTrapped(const MarketContext &ctx) const;          // §3.7:5
   int               _CountForceAbove02(const MarketContext &ctx) const;        // §3.7:6 BUY
   int               _CountForceBelowNeg02(const MarketContext &ctx) const;     // §3.7:6 SELL mirror
   bool              _HasForceTroughBuy(const MarketContext &ctx) const;        // §3.7:9 BUY (≥1 bar in [2,5) Force≤-0.2)
   bool              _HasForceTroughSell(const MarketContext &ctx) const;       // §3.7:9 SELL mirror

   //--- IMPL-FIX-011b Phase 1 patch (2026-05-11) — legacy `BusinessLogic_G2` gates A + G + L
   bool              _HasRecentUpperFractalBidAbove(const MarketContext &ctx) const;  // gate G BUY
   bool              _HasRecentLowerFractalAskBelow(const MarketContext &ctx) const;  // gate G SELL mirror
   int               _MaxBBWithIchiChain(const MarketContext &ctx, bool isBuy) const; // gate L (count first contiguous bars BB-lower>cloud-low BUY / BB-upper<cloud-high SELL)

   //--- IMPL-FIX-007 H4 bar gate (post-G2-smoke strengthening): rate-limit
   //    fills to <= 1 per H4 bar regardless of position lifecycle. Bar gate
   //    is primary anti-pyramid defense (matches task AC literally + CodeWiki
   //    wave-helper-per-bar semantics); pending-fill latch below remains as
   //    defense-in-depth for sub-tick OrderSend race.
   datetime          m_last_fill_bar;

   //--- IMPL-FIX-007: synchronous in-memory pending-fill latch.
   //    Set after RiskManager.OpenOrder() returns true; reset when
   //    PortfolioState reflects the new ticket OR after 60s timeout.
   //    Covers OrderSend->next-OnTick race (PortfolioState.Refresh at
   //    step 7 cannot see ticket created at step 11 of the SAME tick).
   bool              m_pending_fill;
   datetime          m_pending_set_time;
   static const int  PENDING_FILL_TIMEOUT_SEC; // = 60

public:
   //--- Constructor / Destructor
   CSlotG2() : m_pending_fill(false), m_pending_set_time(0), m_last_fill_bar(0) {}
   virtual ~CSlotG2() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_G = 208; shared with G (CommentParser disambig "G2,")
   virtual int      Magic() const override { return MAGIC_G; }

   //--- 2. SlotId โ€” "G2"; used by journal slot_id field + comment prefix
   virtual string   SlotId() const override { return "G2"; }

   //--- 3. Evaluate โ€” entry pass (FR-2.3); only called in EA_STATE_RUNNING
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void     ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” G2 is independent (CommentParser disambig is internal, not topo dep)
   virtual int      DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState โ€” G2 uses IDLE default (not in pending-flow list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _CloudHigh / _CloudLow โ€” H4 Ichimoku cloud edge helpers           |
//+------------------------------------------------------------------+
double CSlotG2::_CloudHigh(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_high;
  }

double CSlotG2::_CloudLow(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_low;
  }

//+------------------------------------------------------------------+
//| _IsPriceAboveCloud โ€” bid > cloud_high                             |
//+------------------------------------------------------------------+
bool CSlotG2::_IsPriceAboveCloud(const MarketContext &ctx) const
  {
   return ctx.bid > _CloudHigh(ctx);
  }

//+------------------------------------------------------------------+
//| _IsPriceBelowCloud โ€” ask < cloud_low                              |
//+------------------------------------------------------------------+
bool CSlotG2::_IsPriceBelowCloud(const MarketContext &ctx) const
  {
   return ctx.ask < _CloudLow(ctx);
  }

//+------------------------------------------------------------------+
//| IMPL-FIX-011 Session C — §3.7:5/6/9 history-based helpers         |
//| Replace single-tick proxies that empirically failed Step 4 iter-2 |
//| (G2/entry |Δ|=2 unchanged after Session B narrow-band+peer-G).    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| _IsAdxNotTrapped — §3.7:5                                         |
//| "ADX-W not trapped between ±DI for bars 1..3"                     |
//| MarketContextBuilder.PopulateAdxHistory sets adxw_no_trap_bars_1_3|
//| = 1 when none of bars 1..2 in 3-bar buffer have ADX trapped       |
//| between both DI lines (per CodeWiki spec).                        |
//+------------------------------------------------------------------+
bool CSlotG2::_IsAdxNotTrapped(const MarketContext &ctx) const
  {
   if(!ctx.adx_h4_history.has_data) return true;  // degrade-but-continue
   return (ctx.adx_h4_history.adxw_no_trap_bars_1_3 == 1);
  }

//+------------------------------------------------------------------+
//| _CountForceAbove02 — §3.7:6 BUY count                             |
//| Count of last 8 bars (force_h4_history.force[0..7]) with          |
//| force > +0.2; gate: count ≥ InpG2ForceMinAbove02BUY (5).          |
//+------------------------------------------------------------------+
int CSlotG2::_CountForceAbove02(const MarketContext &ctx) const
  {
   if(!ctx.force_h4_history.has_data) return 8;  // degrade-but-continue (assume permissive)
   int count = 0;
   for(int i = 0; i < 8; i++)
      if(ctx.force_h4_history.force[i] > 0.2) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _CountForceBelowNeg02 — §3.7:6 SELL mirror                        |
//+------------------------------------------------------------------+
int CSlotG2::_CountForceBelowNeg02(const MarketContext &ctx) const
  {
   if(!ctx.force_h4_history.has_data) return 8;
   int count = 0;
   for(int i = 0; i < 8; i++)
      if(ctx.force_h4_history.force[i] < -0.2) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _HasForceTroughBuy — §3.7:9 BUY                                   |
//| ≥1 bar in [InpG2ForceTroughIdxLow, InpG2ForceTroughIdxHigh)       |
//| with force ≤ InpG2ForceTroughThreshBuy (-0.2 reversal trough).    |
//+------------------------------------------------------------------+
bool CSlotG2::_HasForceTroughBuy(const MarketContext &ctx) const
  {
   if(!ctx.force_h4_history.has_data) return true;  // degrade-but-continue
   int lo = (InpG2ForceTroughIdxLow  > 0) ? InpG2ForceTroughIdxLow  : 0;
   int hi = (InpG2ForceTroughIdxHigh < 8) ? InpG2ForceTroughIdxHigh : 8;
   for(int i = lo; i < hi; i++)
      if(ctx.force_h4_history.force[i] <= InpG2ForceTroughThreshBuy) return true;
   return false;
  }

//+------------------------------------------------------------------+
//| _HasForceTroughSell — §3.7:9 SELL mirror                          |
//+------------------------------------------------------------------+
bool CSlotG2::_HasForceTroughSell(const MarketContext &ctx) const
  {
   if(!ctx.force_h4_history.has_data) return true;
   int lo = (InpG2ForceTroughIdxLow  > 0) ? InpG2ForceTroughIdxLow  : 0;
   int hi = (InpG2ForceTroughIdxHigh < 8) ? InpG2ForceTroughIdxHigh : 8;
   for(int i = lo; i < hi; i++)
      if(ctx.force_h4_history.force[i] >= InpG2ForceTroughThreshSell) return true;
   return false;
  }

//+------------------------------------------------------------------+
//| IMPL-FIX-011b Phase 1 — gate G: Last upper-Fractal + bid-above    |
//| Legacy `BusinessLogic_G2:5628-5637` BUY: scan FractalUpBuffer[2..9]|
//| for most recent non-zero; require `bid > lastFractal && validNeg`.|
//| Rewrite uses Fix D `fractal_h4_history.upper[5]` 5-bar buffer     |
//| (bar 0=current, 4=oldest). Phase 1 conservative: scan [1..4]      |
//| (skip bar 0 to match legacy "2..9"-ish recent-not-current scope). |
//+------------------------------------------------------------------+
bool CSlotG2::_HasRecentUpperFractalBidAbove(const MarketContext &ctx) const
  {
   if(!InpG2RequireFractalCheck) return true;  // gate disabled
   if(!ctx.fractal_h4_history.has_data) return true;  // degrade-but-continue
   for(int i = 1; i < 5; i++)
     {
      double fr = ctx.fractal_h4_history.upper[i];
      if(fr > 0.0)
         return (ctx.bid > fr);  // first non-zero fractal — check bid above
     }
   return false;  // no recent upper fractal → gate fails (was permissive in legacy if validNegative also false)
  }

//+------------------------------------------------------------------+
//| IMPL-FIX-011b Phase 1 — gate G SELL mirror                        |
//+------------------------------------------------------------------+
bool CSlotG2::_HasRecentLowerFractalAskBelow(const MarketContext &ctx) const
  {
   if(!InpG2RequireFractalCheck) return true;
   if(!ctx.fractal_h4_history.has_data) return true;
   for(int i = 1; i < 5; i++)
     {
      double fr = ctx.fractal_h4_history.lower[i];
      if(fr > 0.0)
         return (ctx.ask < fr);
     }
   return false;
  }

//+------------------------------------------------------------------+
//| IMPL-FIX-011b Phase 1 — gate L: maxBBWithIchi chain count         |
//| Legacy `BusinessLogic_G2:5705-5717` BUY: count contiguous bars    |
//| z=1..14 where BollBBot[z] > IchiMin[z] (chain — stops on first    |
//| break). Legacy requires `maxBBWithIchi == 0` (BB-lower must NOT   |
//| be above cloud-bot at bar 1 — i.e. BB still inside/below cloud).  |
//| SELL mirror via BB-upper < cloud-high chain.                      |
//| Uses Fix B `bb_h4_history.bb_bot/bb_top[15]` + Fix B               |
//| `ichi_h4_history.cloud_low/cloud_high[15]`.                       |
//+------------------------------------------------------------------+
int CSlotG2::_MaxBBWithIchiChain(const MarketContext &ctx, bool isBuy) const
  {
   if(!ctx.bb_h4_history.has_data || !ctx.ichi_h4_history.has_data) return 0;
   int count = 0;
   for(int z = 1; z < 15; z++)
     {
      bool breach;
      if(isBuy)
         breach = (ctx.bb_h4_history.bb_bot[z] > ctx.ichi_h4_history.cloud_low [z]);
      else
         breach = (ctx.bb_h4_history.bb_top[z] < ctx.ichi_h4_history.cloud_high[z]);
      if(breach) count++;
      else       break;  // chain stops on first non-breach
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Static const definition (MQL5 requires out-of-class definition)   |
//+------------------------------------------------------------------+
const int CSlotG2::PENDING_FILL_TIMEOUT_SEC = 60;

//+------------------------------------------------------------------+
//| _HasActiveG2Order โ€” check for open G2 orders via PortfolioState   |
//| Uses GetTicketsForSlot(MAGIC_G, "G2,", tickets[]) โ€” comment-disambig|
//+------------------------------------------------------------------+
bool CSlotG2::_HasActiveG2Order(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G2,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsG2BuySignal โ€” Force continuation range BUY (CodeWiki ยง3.G2)   |
//|                                                                   |
//| Lighter condition than G (wave-helper role):                      |
//|   F[1] > InpG2FIContinuationMin (> 0.0)                          |
//|   F[2] > InpG2FIContinuationLow (> -0.2, in continuation range)  |
//|                                                                   |
//| Meaning: Force is still positive but not exhausted โ€” wave helper  |
//| enters after G has fired (continuation into the same wave).       |
//+------------------------------------------------------------------+
bool CSlotG2::_IsG2BuySignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;

   //--- Continuation range: F[1]>0 โง F[2]>-0.2 (still in wave, not reversed)
   //--- IMPL-FIX-011b Phase 1 gate A — legacy `Force[1] < 7` upper bound (line 5558)
   //    Momentum-up-but-not-exhausted; suppresses extreme-spike spurious entries.
   return (f1 > InpG2FIContinuationMin &&
           f1 < InpG2ForceUpperBound   &&
           f2 > InpG2FIContinuationLow);
  }

//+------------------------------------------------------------------+
//| _IsG2SellSignal โ€” Force continuation range SELL (mirror of BUY)  |
//|   F[1] < -InpG2FIContinuationMin (< 0.0)                         |
//|   F[2] < -InpG2FIContinuationLow (< +0.2)                        |
//+------------------------------------------------------------------+
bool CSlotG2::_IsG2SellSignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;

   //--- Mirror of BUY (negated thresholds)
   //--- Mirror of BUY (negated thresholds) + gate A upper bound (legacy line 5766 `Force[1] > -7`)
   return (f1 < -InpG2FIContinuationMin &&
           f1 > -InpG2ForceUpperBound   &&
           f2 < -InpG2FIContinuationLow);
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot G2 entry pass (CodeWiki ยง3.G2 MVP)                |
//|                                                                   |
//| Entry conditions (3 of N for M-size MVP):                         |
//|   1. InpEnableSlotG2 == true                                      |
//|   2. No active G2 orders (magic 208 "G2," prefix)                 |
//|   3. Force crossover in continuation range (BUY or SELL)          |
//|   4. Price outside Ichimoku cloud (confirms direction)            |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G2", InpG2SlPipsFloor, balance)    |
//| Comment: "G2,F1,N,1,SL"                                          |
//+------------------------------------------------------------------+
void CSlotG2::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotG2) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- IMPL-FIX-007 H4 bar gate (PRIMARY anti-pyramid defense post-G2-smoke
   //    finding): match task AC <= 1 fill per H4 bar exactly. CodeWiki §3.G2
   //    wave-helper continuation = next-bar permitted, intra-bar forbidden.
   if(m_last_fill_bar > 0 && iTime(_Symbol, PERIOD_H4, 0) == m_last_fill_bar)
      return;

   //--- IMPL-FIX-007 anti-pyramid latch (same-tick race protection)
   //    Reset when PortfolioState reflects fill OR after timeout.
   if(m_pending_fill)
     {
      if(_HasActiveG2Order(port))
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
        }
      else if(TimeCurrent() - m_pending_set_time > PENDING_FILL_TIMEOUT_SEC)
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
         m_logger.Warn("SlotG2", "pending_fill_timeout", MAGIC_G,
                       "60s elapsed without PortfolioState reflection - clearing latch");
        }
      else
        {
         return;  // still pending - skip until reflected or timeout
        }
     }

   //--- Condition 1: no active G2 (own "G2," prefix orders)
   if(_HasActiveG2Order(port)) return;

   //--- Determine direction
   bool buySignal  = _IsG2BuySignal(ctx);
   bool sellSignal = _IsG2SellSignal(ctx);
   if(!buySignal && !sellSignal) return;

   //--- Condition 3: price outside cloud + matches direction
   bool priceOk = false;
   if(buySignal)  priceOk = _IsPriceAboveCloud(ctx);
   if(sellSignal) priceOk = _IsPriceBelowCloud(ctx);
   if(!priceOk) return;

   //--- IMPL-FIX-011 Session C — §3.7:5 ADX-W not trapped between ±DI bars 1..3
   if(!_IsAdxNotTrapped(ctx)) return;

   //--- IMPL-FIX-011 Session C — §3.7:6 ≥5 of last 8 bars Force>+0.2 (BUY) /
   //    ≥5 of last 8 bars Force<-0.2 (SELL)
   if(buySignal  && _CountForceAbove02(ctx)    < InpG2ForceMinAbove02BUY)  return;
   if(sellSignal && _CountForceBelowNeg02(ctx) < InpG2ForceMinAbove02Sell) return;

   //--- IMPL-FIX-011 Session C — §3.7:9 ≥1 bar in [2,5) with reversal trough
   //    BUY: force ≤ -0.2 (prior negative trough confirms ongoing reversal back up);
   //    SELL: force ≥ +0.2 (mirror)
   if(buySignal  && !_HasForceTroughBuy(ctx))  return;
   if(sellSignal && !_HasForceTroughSell(ctx)) return;

   //--- IMPL-FIX-011b Phase 1 gate G — last upper-Fractal + bid-above (BUY) /
   //    last lower-Fractal + ask-below (SELL); legacy lines 5628-5637 + 5836-5845.
   if(buySignal  && !_HasRecentUpperFractalBidAbove(ctx)) return;
   if(sellSignal && !_HasRecentLowerFractalAskBelow(ctx)) return;

   //--- IMPL-FIX-011b Phase 1 gate L — maxBBWithIchi chain == 0 (BUY: BB-lower
   //    must NOT be above cloud-low in 15-bar chain; SELL mirror via BB-upper
   //    vs cloud-high). Legacy lines 5705-5717 (BUY) + 5913-5925 (SELL).
   if(buySignal  && _MaxBBWithIchiChain(ctx, true ) > InpG2MaxBBWithIchi) return;
   if(sellSignal && _MaxBBWithIchiChain(ctx, false) > InpG2MaxBBWithIchi) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   double cloud_edge_pips = 0.0;
   if(buySignal)
      cloud_edge_pips = (ctx.bid - _CloudLow(ctx)) / pip_size;
   else
      cloud_edge_pips = (_CloudHigh(ctx) - ctx.ask) / pip_size;

   double sl_pips = MathMax(cloud_edge_pips, InpG2SlPipsFloor);

   //--- Compute lot (lighter base factor than G)
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("G2", sl_pips, balance);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotG2", "zero_lot_skip", MAGIC_G,
                    "ComputeLot returned 0 โ€” skipping G2 entry");
      return;
     }

   //--- Compute SL price (broker-bound โ€” base-class _NormalizeBrokerPrice)
   double tp_price = 0.0;
   double sl_price = buySignal
                     ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                     : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

   //--- Comment: "G2,F1,N,1,SL" per CodeWiki ยง3.G2 โ€” disambig from "G,"
   string comment = "G2,F1,N,1,SL";

   //--- Build order request (route through RiskManager โ€” ea.md: เธซเนเธฒเธก instantiate CTrade direct)
   ENUM_ORDER_TYPE order_type = buySignal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = buySignal ? ctx.ask : ctx.bid;

   MqlTradeRequest req = {};
   MqlTradeResult  res = {};

   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = lot;
   req.type         = order_type;
   req.price        = _NormalizeBrokerPrice(price);
   req.sl           = sl_price;
   req.tp           = tp_price;
   req.comment      = comment;
   req.magic        = MAGIC_G;
   req.type_filling = ORDER_FILLING_FOK;   // filling mode set per broker detection at Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder)

   //--- fix-round-12 ยง 12.8 โ€” Phase 1 emits entry_signal Logger.Info as
   //    the observable milestone; actual OrderSend lives in
   //    `RiskManager::OpenOrder` per `.claude/rules/ea.md` (IMPL-017 +
   //    IMPL-062 5-yr regression).
   //    Observable milestone for E-AC [log-assertion]:
   // IMPL-FIX-011 R-13 (d): entry_signal Info emit suppressed (per-tick stub
   // spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over 5-yr;
   // restore when RiskManager::OpenOrder wires real send + this becomes
   // one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10.
   // m_logger.Info("SlotG2", "entry_signal", MAGIC_G,
   //               StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
   //                            (buySignal ? "BUY" : "SELL"), lot, sl_pips, price, sl_price, comment));

   //--- IMPL-FIX-003: submit broker order via RiskManager.OpenOrder wrapper (ea.md mandate)
   //--- IMPL-FIX-007: arm pending-fill latch on success to block same-tick re-entry
   if(m_risk.OpenOrder(req, "G2"))
     {
      m_pending_fill     = true;
      m_pending_set_time = TimeCurrent();
      m_last_fill_bar    = iTime(_Symbol, PERIOD_H4, 0);
     }

   //--- CrossSlotCoordinator stub
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: coupling to G-overload signal
      //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot G2 exit pass (lighter profit gate; 30 pip MVP) |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate G2 positions via GetTicketsForSlot(MAGIC_G, "G2,")  |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate โฅ InpG2TpProfitPips (30 pip default) โ’ close    |
//+------------------------------------------------------------------+
void CSlotG2::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve G2 tickets (comment prefix "G2," โ€” disambig from "G,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G2,", tickets);
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

      //--- Profit gate: โฅ InpG2TpProfitPips (30 pip default โ€” lighter than G's 50)
      if(profit_pips >= InpG2TpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotG2", "exit_profit_gate", MAGIC_G,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
//                                     ticket, profit_pips, InpG2TpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub โ€” deferred (IMPL-053)
      if(m_xslot != NULL && false /*IMPL-053*/)
        {
         //--- Stub: any G2 peak-based cross-slot coupling goes here (IMPL-053)
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_G2_MQH
