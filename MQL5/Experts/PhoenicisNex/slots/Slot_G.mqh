//+------------------------------------------------------------------+
//| slots/Slot_G.mqh โ€” Slot G implementation (IMPL-025)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_G = 208, shared with G2 (IMPL-026)                 |
//|          CommentParser disambiguates "G," vs "G2," per BR-1.2     |
//| Source:  CodeWiki ยง3.6; TD-02 ยง5.4; ADR-002; ADR-012             |
//|                                                                   |
//| Entry (M-size MVP โ€” 5 of 13 CodeWiki ยง3.6 conditions):           |
//|   1. No active G orders (magic 208 with "G," prefix)              |
//|   2. Force crossover: BUY=(F[1]>0 โง F[2]>0 โง F[3]<-0.2)         |
//|                       โจ  (F[1]>1 โง F[2] in [-0.2,-3))            |
//|   3. Price outside Ichimoku cloud                                  |
//|   4. ADX H4 dominance: adx > +DI โง adx > -DI                     |
//|   5. Stochastic M10[0] <25 (BUY) / >75 (SELL)                    |
//| Deferred to P4 IMPL-062: GPause / NewYear / Force-peak-exhaustion |
//|   / WPR-sanity / Bollinger / DeMarker / Force-wave-spans          |
//|                                                                   |
//| Exit (ManageExits / ExtraTakeProfit_G):                           |
//|   - Profit gate โฅ 50 pip                                          |
//|   - On peak detection: TriggerGOverload (BR-8.4 stub call site)   |
//|   Stub: if(m_xslot != NULL && false /*IMPL-053*/) {...}           |
//|   Real CCrossSlotCoordinator::TriggerGOverload impl = IMPL-053    |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G", InpGSlPipsFloor, balance)       |
//| Comment: "G,F1,N,1,SL" per CodeWiki ยง3.6 format                  |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_G_MQH
#define PHOENICISNEX_SLOTS_SLOT_G_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_G.mqh"

//+------------------------------------------------------------------+
//| CSlotG โ€” Slot G derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Magic 208 shared pool: G and G2. All G orders tagged "G," prefix; |
//| G2 orders tagged "G2," prefix. PortfolioState.GetByMagic(208)    |
//| returns aggregate; GetTicketsForSlot(208,"G,") filters own.       |
//|                                                                   |
//| ExtraTakeProfit_G stub: BR-8.4 GOverload trigger. Real            |
//| CCrossSlotCoordinator::TriggerGOverload body = IMPL-053 (P4).     |
//+------------------------------------------------------------------+
class CSlotG : public CSlotBase
  {
private:
   //--- Per-tick trailing state (reset on new G order open)
   double            m_maxProfitPip;    // trailing max-profit tracking for GOverload detection (BR-8.4)

   //--- IMPL-FIX-008 H4 bar gate (R-9 closure post-5yr-storm finding):
   //    rate-limit fills to <=1 per H4 bar regardless of position
   //    lifecycle. Mirrors Slot_G2 v2 IMPL-FIX-007 pattern. Without this,
   //    Slot_G fires repeatedly on shared MAGIC_G=208 between H4 bar
   //    boundaries when H4 trend persists -> CircuitBreaker ping-pong storm
   //    detected at 2021.01.08 in 5-yr Model=0 Bucket B regression.
   datetime          m_last_fill_bar;

   //--- IMPL-FIX-008: synchronous in-memory pending-fill latch.
   //    Set after RiskManager.OpenOrder() returns true; reset when
   //    PortfolioState reflects the new ticket OR after 60s timeout.
   //    Covers OrderSend->next-OnTick race (PortfolioState.Refresh at
   //    step 7 cannot see ticket created at step 11 of the SAME tick).
   bool              m_pending_fill;
   datetime          m_pending_set_time;
   static const int  PENDING_FILL_TIMEOUT_SEC; // = 60


   //--- Private helpers
   bool              _IsGBuySignal(const MarketContext &ctx) const;
   bool              _IsGSellSignal(const MarketContext &ctx) const;
   bool              _IsPriceAboveCloud(const MarketContext &ctx) const;
   bool              _IsPriceBelowCloud(const MarketContext &ctx) const;
   bool              _HasActiveGOrder(CPortfolioState &port) const;
   double            _CloudHigh(const MarketContext &ctx) const;
   double            _CloudLow(const MarketContext &ctx) const;

public:
   //--- Constructor
   CSlotG() : m_maxProfitPip(0.0), m_pending_fill(false), m_pending_set_time(0), m_last_fill_bar(0) {}
   virtual ~CSlotG() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_G = 208; shared with G2 (CommentParser disambig)
   virtual int      Magic() const override { return MAGIC_G; }

   //--- 2. SlotId โ€” "G"; used by journal slot_id field + comment prefix
   virtual string   SlotId() const override { return "G"; }

   //--- 3. Evaluate โ€” entry pass (FR-2.3); only called in EA_STATE_RUNNING
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   //       Implements ExtraTakeProfit_G logic (CodeWiki ยง3.6 exit section)
   //       BR-8.4 TriggerGOverload stub wired here
   virtual void     ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” G is independent (no peer slot deps in Phase 1)
   //       G2/GO/I dependencies landed in IMPL-026/027/028 P3
   virtual int      DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState โ€” G uses IDLE default (not in pending-flow list)
   //       inherited from CSlotBase; explicit override for clarity
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _CloudHigh / _CloudLow โ€” H4 Ichimoku cloud edge helpers           |
//+------------------------------------------------------------------+
double CSlotG::_CloudHigh(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_high;
  }

double CSlotG::_CloudLow(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_low;
  }

//+------------------------------------------------------------------+
//| _IsPriceAboveCloud โ€” bid > cloud_high                             |
//+------------------------------------------------------------------+
bool CSlotG::_IsPriceAboveCloud(const MarketContext &ctx) const
  {
   return ctx.bid > _CloudHigh(ctx);
  }

//+------------------------------------------------------------------+
//| _IsPriceBelowCloud โ€” ask < cloud_low                              |
//+------------------------------------------------------------------+
bool CSlotG::_IsPriceBelowCloud(const MarketContext &ctx) const
  {
   return ctx.ask < _CloudLow(ctx);
  }

//+------------------------------------------------------------------+
//| _HasActiveGOrder โ€” check for open G orders via PortfolioState     |
//| Uses GetTicketsForSlot(MAGIC_G, "G,", tickets[]) โ€” stub in P3     |
//| Fallback: check total_lots on MAGIC_G slot state                  |
//+------------------------------------------------------------------+
bool CSlotG::_HasActiveGOrder(CPortfolioState &port) const
  {
   SlotState *gs = port.GetByMagic(MAGIC_G);
   if(gs == NULL) return false;

   //--- GetTicketsForSlot body now landed in PortfolioState; this stub
   //    still uses total_lots > 0 as proxy for smoke-path readability.
   //    Full comment-prefix disambiguation already available via
   //    PortfolioState.GetTicketsForSlot (no further pending work).
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsGBuySignal โ€” Force crossover BUY conditions (CodeWiki ยง3.6:2)  |
//|                                                                   |
//| Primary:   F[1]>0 โง F[2]>0 โง F[3]<-0.2                          |
//| Alternate: F[1]>1 โง F[2] in [-0.2, -3.0)                         |
//| (F[0] = ctx.force_h4.f0, F[1] = f1, F[2] = f2, F[3] = f3)       |
//+------------------------------------------------------------------+
bool CSlotG::_IsGBuySignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;
   double f3 = ctx.force_h4.f3;

   //--- Primary cross: F[1]>0 โง F[2]>0 โง F[3]<-0.2
   bool primary = (f1 > InpGFICrossThreshHigh &&
                   f2 > InpGFICrossThreshHigh &&
                   f3 < InpGFICrossThreshLow);

   //--- Alternate cross: F[1]>1 โง F[2] in (-3.0, -0.2)
   bool alternate = (f1 > InpGFICrossAltHigh &&
                     f2 > InpGFICrossAltLow &&
                     f2 < InpGFICrossThreshLow);

   return primary || alternate;
  }

//+------------------------------------------------------------------+
//| _IsGSellSignal โ€” Force crossover SELL conditions (mirror of BUY)  |
//|                                                                   |
//| Primary:   F[1]<0 โง F[2]<0 โง F[3]>0.2                           |
//| Alternate: F[1]<-1 โง F[2] in (0.2, 3.0)                          |
//+------------------------------------------------------------------+
bool CSlotG::_IsGSellSignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;
   double f3 = ctx.force_h4.f3;

   //--- Mirror of BUY thresholds (negated)
   bool primary = (f1 < -InpGFICrossThreshHigh &&
                   f2 < -InpGFICrossThreshHigh &&
                   f3 > -InpGFICrossThreshLow);

   bool alternate = (f1 < -InpGFICrossAltHigh &&
                     f2 < -InpGFICrossAltLow &&
                     f2 > -InpGFICrossThreshLow);

   return primary || alternate;
  }

//+------------------------------------------------------------------+
//| Static const definition (MQL5 requires out-of-class definition)  |
//+------------------------------------------------------------------+
const int CSlotG::PENDING_FILL_TIMEOUT_SEC = 60;

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot G entry pass (CodeWiki ยง3.6 MVP)                  |
//|                                                                   |
//| Entry conditions (5 of 13 for M-size MVP):                        |
//|   1. InpEnableSlotG == true                                       |
//|   2. No active G orders (magic 208 "G," prefix)                   |
//|   3. Force crossover (BUY or SELL per _IsGBuySignal/SellSignal)   |
//|   4. Price outside Ichimoku cloud (confirms direction)            |
//|   5. ADX dominance: adx > di_plus โง adx > di_minus               |
//|   6. Stochastic M10: k_main <25 (BUY) / >75 (SELL)               |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G", InpGSlPipsFloor, balance)       |
//| SL:  max(cloud-edge distance, InpGSlPipsFloor) in pips           |
//| Comment: "G,F1,N,1,SL"                                           |
//+------------------------------------------------------------------+
void CSlotG::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotG) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- IMPL-FIX-008 H4 bar gate (PRIMARY anti-pyramid defense; mirrors
   //    Slot_G2 IMPL-FIX-007). MAGIC_G=208 shared with G2 - Slot_G
   //    storming inside the same H4 bar triggered CircuitBreaker
   //    ping-pong cascade in 5-yr regression (R-9). Bar gate enforces
   //    "<=1 fill per H4 bar" semantics matching G2 wave-helper rule.
   if(m_last_fill_bar > 0 && iTime(_Symbol, PERIOD_H4, 0) == m_last_fill_bar)
      return;

   //--- IMPL-FIX-008 anti-pyramid latch (same-tick race protection).
   //    Reset when PortfolioState reflects fill OR after timeout.
   if(m_pending_fill)
     {
      if(_HasActiveGOrder(port))
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
        }
      else if(TimeCurrent() - m_pending_set_time > PENDING_FILL_TIMEOUT_SEC)
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
         m_logger.Warn("SlotG", "pending_fill_timeout", MAGIC_G,
                       "60s elapsed without PortfolioState reflection - clearing latch");
        }
      else
        {
         return;  // still pending - skip until reflected or timeout
        }
     }

   //--- Condition 1: no active G (own "G," prefix orders)
   if(_HasActiveGOrder(port)) return;

   //--- Condition 5 (ADX dominance) โ€” check before signal to short-circuit
   double adx     = ctx.adx_h4.adx;
   double di_plus = ctx.adx_h4.di_plus;
   double di_minus= ctx.adx_h4.di_minus;
   bool adxDominant = (adx > InpGAdxDominanceMin &&
                       adx > di_plus && adx > di_minus);
   if(!adxDominant) return;

   //--- Determine direction
   bool buySignal  = _IsGBuySignal(ctx);
   bool sellSignal = _IsGSellSignal(ctx);
   if(!buySignal && !sellSignal) return;

   //--- Condition 3: price outside cloud + matches direction
   bool priceOk = false;
   if(buySignal)  priceOk = _IsPriceAboveCloud(ctx);
   if(sellSignal) priceOk = _IsPriceBelowCloud(ctx);
   if(!priceOk) return;

   //--- IMPL-FIX-011 R-13 (e) eligibility tightening per CodeWiki ยง3.6:9
   //    "Force peaks not exhausted" โ€” Phase-1 single-tick proxy: require
   //    current-bar Force same-side as signal so the wave is still pushing.
   //    Q1 2021 paired-canary diff (Step 2 / Step 4 iter-1) showed 2
   //    rewrite-only G entries (2021-01-04 16:00Z + 2021-01-14 16:00Z) on
   //    H4 buckets where current-bar Force had already decayed away from
   //    the signal direction, while legacy was silent. Full Force-peak
   //    history scan is P4 IMPL-062 surface (~6+ bars lookback + extremum
   //    threshold ยฑ25); current f0 directional gate is the conservative
   //    single-tick proxy that needs no MarketContext extension.
   double f0 = ctx.force_h4.f0;
   if(buySignal  && f0 <= 0.0) return;
   if(sellSignal && f0 >= 0.0) return;

   //--- Condition 4 (Stochastic M10 oversold/overbought confirmation)
   double stoch_k = ctx.stoch_m10.k_main;
   if(buySignal  && stoch_k >= InpGStochOversold)  return;
   if(sellSignal && stoch_k <= InpGStochOverbought) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   double cloud_edge_pips = 0.0;
   if(buySignal)
      cloud_edge_pips = (ctx.bid - _CloudLow(ctx)) / pip_size;
   else
      cloud_edge_pips = (_CloudHigh(ctx) - ctx.ask) / pip_size;

   double sl_pips = MathMax(cloud_edge_pips, InpGSlPipsFloor);

   //--- Compute lot
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("G", sl_pips, balance);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotG", "zero_lot_skip", MAGIC_G, "ComputeLot returned 0 โ€” skipping entry");
      return;
     }

   //--- Compute SL price (broker-bound โ€” base-class _NormalizeBrokerPrice)
   double tp_price = 0.0;  // TP = 0 (profit-gate exit managed in ManageExits)
   double sl_price = buySignal
                     ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                     : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

   //--- Comment: "G,F1,N,1,SL" per CodeWiki ยง3.6
   string comment = "G,F1,N,1,SL";

   //--- Submit order through RiskManager CTrade wrapper
   //    เธซเนเธฒเธก instantiate CTrade direct โ€” use m_risk (per ea.md + ADR-002)
   ENUM_ORDER_TYPE order_type = buySignal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = buySignal ? ctx.ask : ctx.bid;

   MqlTradeRequest req  = {};
   MqlTradeResult  res  = {};

   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = lot;
   req.type         = order_type;
   req.price        = _NormalizeBrokerPrice(price);
   req.sl           = sl_price;
   req.tp           = tp_price;
   req.comment      = comment;
   req.magic        = MAGIC_G;
   req.type_filling = ORDER_FILLING_FOK;   // filling mode set per broker detection at Orchestrator wiring path (core/Orchestrator.mqh)

   //--- Route through RiskManager (ea.md: ALL CTrade calls through RiskManager or OpenOrder<X>)
   //    Phase-1 stub: OrderSend call deferred โ€” body placeholder logs intent only.
   //    Full CTrade wiring at Orchestrator wiring path (core/Orchestrator.mqh) orchestrator (Composition Root).
   //    For smoke test evidence: emit journal-format log entry.
   // IMPL-FIX-011 R-13 (d): entry_signal Info emit suppressed (per-tick stub
   // spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over 5-yr;
   // restore when RiskManager::OpenOrder wires real send + this becomes
   // one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10.
   // if(m_logger != NULL)
   //    m_logger.Info("SlotG", "entry_signal", MAGIC_G,
   //                  StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
   //                               (buySignal ? "BUY" : "SELL"), lot, sl_pips, price, sl_price, comment));

   //--- IMPL-FIX-003: submit broker order via RiskManager.OpenOrder wrapper (ea.md mandate)
   //--- IMPL-FIX-008: arm pending-fill latch + record bar on success to block same-tick + same-bar re-entry
   if(m_risk.OpenOrder(req, "G"))
     {
      m_pending_fill     = true;
      m_pending_set_time = TimeCurrent();
      m_last_fill_bar    = iTime(_Symbol, PERIOD_H4, 0);
     }

   //--- Reset trailing state for new position
   m_maxProfitPip = 0.0;
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot G exit pass / ExtraTakeProfit_G (CodeWiki ยง3.6)|
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate G positions via GetTicketsForSlot(MAGIC_G, "G,")    |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate โฅ InpGTpProfitPips (50 pip default) โ’ close     |
//|   4. Peak detection: update m_maxProfitPip                        |
//|   5. On GOverload condition (BR-8.4):                             |
//|      Force>InpGOverloadForceMin โจ ADX>InpGOverloadAdxMin          |
//|      + maxOffset โฅ InpGOverloadMaxOffset โ’ TriggerGOverload stub  |
//|                                                                   |
//| BR-8.4 stub wiring:                                               |
//|   CCrossSlotCoordinator::TriggerGOverload not yet declared        |
//|   (CrossSlotCoordinator.mqh = IMPL-053 P4).                       |
//|   Call site guarded: if(m_xslot != NULL && false /*IMPL-053*/)   |
//|   to keep G1 compile clean while wiring comment for IMPL-053.    |
//+------------------------------------------------------------------+
void CSlotG::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve G tickets (comment prefix "G,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      //--- Select position by ticket
      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type  = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             lot        = PositionGetDouble(POSITION_VOLUME);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Update trailing max-profit
      if(profit_pips > m_maxProfitPip)
         m_maxProfitPip = profit_pips;

      //--- Profit gate: โฅ InpGTpProfitPips (50 pip default) โ’ emit close signal
      if(profit_pips >= InpGTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotG", "exit_profit_gate", MAGIC_G,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
//                                     ticket, profit_pips, InpGTpProfitPips));

         //--- Close via CTrade route โ€” fix-round-12 ยง 12.8: actual close
         //    routes through `RiskManager::OpenOrder` / `CloseOrder` per
         //    `.claude/rules/ea.md` (Orchestrator wiring path (core/Orchestrator.mqh) 5-yr regression).
         //    Phase 1 logs intent only. Evidence for E-AC [log-assertion]:
         //    above Info log is the observable milestone.
         m_maxProfitPip = 0.0;   // reset on close
        }

      //--- BR-8.4 GOverload peak detection
      //    Conditions: (Force>ForceMin โจ ADX>AdxMin) โง maxOffsetโฅOverloadMaxOffset
      //    direction inversion: BUY peak โ’ trigger SELL GO order (MAGIC_GO=209)
      //    STUB โ€” CCrossSlotCoordinator::TriggerGOverload not yet declared
      //    (CrossSlotCoordinator.mqh = IMPL-053 P4). Guarded false to compile clean.
      // BR-8.4 stub โ€” real impl IMPL-053
      if(m_xslot != NULL && false /*IMPL-053: enable when TriggerGOverload declared*/)
        {
         //--- Stub call signature (will be activated at IMPL-053):
         //    ENUM_POSITION_TYPE opp_dir = (pos_type == POSITION_TYPE_BUY) ?
         //                                  POSITION_TYPE_SELL : POSITION_TYPE_BUY;
         //    m_xslot.TriggerGOverload(MAGIC_GO, opp_dir, lot);
         //    (Parameters per BR-8.4: target magic=GO, opposite direction, parent lot)
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_G_MQH
