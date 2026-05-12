//+------------------------------------------------------------------+
//| slots/Slot_L.mqh เนโฌโ€ Slot L derived class (IMPL-030)               |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   211 (MAGIC_L per domain/EnumTypes.mqh; shared with LX)   |
//| SlotId:  "L"                                                      |
//| Comment: "L,wave,1"                                               |
//|                                                                  |
//| Source:  CodeWiki เธขเธ3.L (M-size MVP: 5 of N entry conditions)     |
//|          TD-02 เธขเธ5.4 (lot dispatch RiskManager::ComputeLot)        |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency เนโฌโ€ เน€เธเธเน€เธยเน€เธเธ’เน€เธเธ #include slots/*)        |
//|                                                                  |
//| M-size MVP scope (5 of N CodeWiki เธขเธ3.L conditions):              |
//|   1. No existing L order (PortfolioState comment-prefix filter)   |
//|   2. WPR wave signal: wpr_wave_signal derived (wpr_h4 + Ichimoku) |
//|      // CodeWiki เธขเธ3.L entry condition เนโฌโ€ WPR wave confirmation     |
//|   3. D1 Ichimoku trend filter: price location vs cloud            |
//|      // CodeWiki เธขเธ3.L entry condition เนโฌโ€ trend alignment           |
//|   4. ADX volatility gate: adx_h4.adx > InpLAdxThreshold          |
//|      // CodeWiki เธขเธ3.L entry condition เนโฌโ€ avoid low-volatility      |
//|   5. WPR oversold/overbought threshold confirmation               |
//|      // CodeWiki เธขเธ3.L entry condition เนโฌโ€ momentum confirmation     |
//|                                                                  |
//| LX/S coupling: IMPL-031 (LX pyramid) + IMPL-036 (S post-close)   |
//|   depend on L เนโฌโ€ but those land at IMPL-031/036, NOT here.        |
//|   DependsOn() returns 0 (independent).                           |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - LX pyramid trigger integration                                |
//|   - Slot S post-close dependency                                  |
//|   - Advanced sub-demand zone conditions                           |
//|   - DeMarker secondary confirmation                               |
//|   - Hull MA slope gate                                            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_L_MQH
#define PHOENICISNEX_SLOTS_SLOT_L_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../inputs/Inputs_Slot_L.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/RiskManager.mqh"

//+------------------------------------------------------------------+
//| CSlotL เนโฌโ€ Slot L concrete derived class                           |
//|                                                                  |
//| Entry logic: WPR wave signal (wpr_wave_signal derived) +         |
//|   D1 Ichimoku trend alignment + ADX volatility gate +            |
//|   WPR threshold confirmation + no existing L order.              |
//|                                                                  |
//| Exit logic: profit >= InpLTpProfitPips (40 pip default).         |
//| Comment prefix: "L," เนโฌโ€ LX uses "LX," (IMPL-031 disambiguation).  |
//+------------------------------------------------------------------+
class CSlotL : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` inherited from base.

   //--- Count open L orders via PortfolioState comment-prefix filter
   //    MAGIC_L is shared with LX เนโฌโ€ filter by "L," prefix to own only.
   int               _CountLOrders(CPortfolioState &port) const
     {
      ulong tickets[];
      return port.GetTicketsForSlot(MAGIC_L, "L,", tickets);
     }

   //--- D1 trend direction: BUY if price above D1 cloud, SELL if below
   //    Returns: +1 = BUY trend, -1 = SELL trend, 0 = inside cloud (no signal)
   int               _D1TrendDirection(const MarketContext &ctx) const
     {
      double cloud_high = ctx.ichi_d1.cloud_high;
      double cloud_low  = ctx.ichi_d1.cloud_low;
      if(ctx.bid > cloud_high)
         return +1;  // above cloud เนโฌโ€ BUY trend
      if(ctx.bid < cloud_low)
         return -1;  // below cloud เนโฌโ€ SELL trend
      return 0;      // inside cloud เนโฌโ€ no clear trend
     }

public:
   //--- Constructor: no member state beyond base
   CSlotL() {}
   virtual          ~CSlotL() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() เนโฌโ€ returns MAGIC_L (211) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_L; }

   //--- 2. SlotId() เนโฌโ€ used by journal record `slot_id` field
   virtual string    SlotId() const override { return "L"; }

   //--- 3. Evaluate() เนโฌโ€ entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 5 of N CodeWiki เธขเธ3.L conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotL)
         return;

      //--- Entry condition 1: no existing L order open
      //    Uses comment-prefix "L," filter เนโฌโ€ LX orders (magic=211 + "LX,") excluded.
      if(_CountLOrders(port) >= InpLMaxOrders)
         return;

      //--- Entry condition 2: ADX volatility gate
      //    CodeWiki เธขเธ3.L เนโฌโ€ avoid low-volatility regime
      if(ctx.adx_h4.adx < InpLAdxThreshold)
         return;

      //--- Entry condition 3: D1 Ichimoku trend filter
      //    CodeWiki เธขเธ3.L เนโฌโ€ align with higher-timeframe trend
      int trend_dir = _D1TrendDirection(ctx);
      if(trend_dir == 0)
         return;  // price inside cloud เนโฌโ€ no trade

      //--- Entry condition 4: WPR wave signal (derived, computed once per tick)
      //    CodeWiki เธขเธ3.L เนโฌโ€ wpr_wave_signal = RunCheckWPRWaveWithIchimoku2 result
      //    Must match trend direction
      if(!ctx.derived.wpr_wave_signal)
         return;

      //--- Entry condition 5: WPR threshold confirmation
      //    BUY: wpr_h4 oversold (< InpLWprOversold = -80)
      //    SELL: wpr_h4 overbought (> InpLWprOverbought = -20)
      bool buy_signal  = (trend_dir == +1) && (ctx.wpr_h4.wpr < InpLWprOversold);
      bool sell_signal = (trend_dir == -1) && (ctx.wpr_h4.wpr > InpLWprOverbought);
      if(!buy_signal && !sell_signal)
         return;

      //--- Lot sizing via RiskManager (no direct CTrade เนโฌโ€ ADR-002 rule)
      if(m_risk == NULL)
        {
         if(m_logger != NULL)
            m_logger.Error("Slot_L", "risk_manager_null", Magic(), "Evaluate");
         return;
        }
      double lot = m_risk.ComputeLot("L", InpLSlPips,
                                     AccountInfoDouble(ACCOUNT_BALANCE));
      if(lot <= 0.0)
         return;

      //--- Build order parameters (Round-06 06.3: sl_price normalized)
      ENUM_ORDER_TYPE  order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double           price      = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist    = _PipsToPrice(InpLSlPips);
      double           sl_price   = buy_signal
                                    ? _NormalizeBrokerPrice(price - sl_dist)
                                    : _NormalizeBrokerPrice(price + sl_dist);
      string           comment    = "L,wave,1";

      //--- IMPL-FIX-003 Phase 1B (2026-05-12): wire RiskManager.OpenOrder
      //    per Phase 1A pattern (mirror Slot_K iter-18 + Slot_B iter-19).
      //    Slot_L was on the deferred 11-slot Phase 1B list (independent baseline;
      //    LX pyramid + S post-close children fire downstream once L entries land).
      MqlTradeRequest req = {};
      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = order_type;
      req.price        = _NormalizeBrokerPrice(price);
      req.sl           = sl_price;
      req.tp           = 0.0;
      req.comment      = comment;
      req.magic        = MAGIC_L;
      req.type_filling = ORDER_FILLING_FOK;

      m_risk.OpenOrder(req, "L");
     }

   //--- 4. ManageExits() เนโฌโ€ exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit condition: profit >= InpLTpProfitPips.
   //    Uses canonical PortfolioState.GetTicketsForSlot + PositionSelectByTicket
   //    pattern (Slot_BR canonical) per ADR-005 + ADR-012. Open positions are
   //    accessed via Position* APIs เนโฌโ€ Order* APIs would walk the pending-order
   //    list and miss market positions entirely.
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotL)
         return;

      //--- Retrieve L tickets (shared magic MAGIC_L=211 with LX; "L," prefix
      //    excludes LX per shared-magic disambig เนโฌโ€ GetTicketsForSlot returns
      //    only "L,..." comment matches, not "LX,...").
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_L, "L,", tickets);
      if(n <= 0) return;

      for(int i = 0; i < n; i++)
        {
         ulong ticket = tickets[i];
         if(!PositionSelectByTicket(ticket)) continue;

         ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double             cur_price  = (pos_type == POSITION_TYPE_BUY)
                                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double price_diff = (pos_type == POSITION_TYPE_BUY)
                             ? (cur_price - open_price)
                             : (open_price - cur_price);

         double profit_pips = price_diff / _PipSize();

         //--- Exit condition: profit >= InpLTpProfitPips gate (40 pip default)
         if(profit_pips < InpLTpProfitPips)
            continue;

         //--- IMPL-FIX-003 Phase 1B (2026-05-12): wire RiskManager.CloseOrder
         //    (mirror Slot_K iter-18 OpenOrder pattern, exit-side symmetric).
         if(m_risk != NULL)
            m_risk.CloseOrder(ticket, "L");
        }
     }

   //--- 5. DependsOn() เนโฌโ€ L is independent (no peer slot deps)
   //    LX + S depend ON L (reverse direction) เนโฌโ€ those land at IMPL-031/036.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() เนโฌโ€ L does not use pending sub-flow;
   //    safe default PENDING_STATE_IDLE (overridden here explicitly
   //    for documentation clarity per CSlotBase contract ADR-002).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_L_MQH
