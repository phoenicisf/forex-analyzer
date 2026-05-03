//+------------------------------------------------------------------+
//| slots/Slot_L.mqh — Slot L derived class (IMPL-030)               |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   211 (MAGIC_L per domain/EnumTypes.mqh; shared with LX)   |
//| SlotId:  "L"                                                      |
//| Comment: "L,wave,1"                                               |
//|                                                                  |
//| Source:  CodeWiki §3.L (M-size MVP: 5 of N entry conditions)     |
//|          TD-02 §5.4 (lot dispatch RiskManager::ComputeLot)        |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency — ห้าม #include slots/*)        |
//|                                                                  |
//| M-size MVP scope (5 of N CodeWiki §3.L conditions):              |
//|   1. No existing L order (PortfolioState comment-prefix filter)   |
//|   2. WPR wave signal: wpr_wave_signal derived (wpr_h4 + Ichimoku) |
//|      // CodeWiki §3.L entry condition — WPR wave confirmation     |
//|   3. D1 Ichimoku trend filter: price location vs cloud            |
//|      // CodeWiki §3.L entry condition — trend alignment           |
//|   4. ADX volatility gate: adx_h4.adx > InpLAdxThreshold          |
//|      // CodeWiki §3.L entry condition — avoid low-volatility      |
//|   5. WPR oversold/overbought threshold confirmation               |
//|      // CodeWiki §3.L entry condition — momentum confirmation     |
//|                                                                  |
//| LX/S coupling: IMPL-031 (LX pyramid) + IMPL-036 (S post-close)   |
//|   depend on L — but those land at IMPL-031/036, NOT here.        |
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
//| CSlotL — Slot L concrete derived class                           |
//|                                                                  |
//| Entry logic: WPR wave signal (wpr_wave_signal derived) +         |
//|   D1 Ichimoku trend alignment + ADX volatility gate +            |
//|   WPR threshold confirmation + no existing L order.              |
//|                                                                  |
//| Exit logic: profit >= InpLTpProfitPips (40 pip default).         |
//| Comment prefix: "L," — LX uses "LX," (IMPL-031 disambiguation).  |
//+------------------------------------------------------------------+
class CSlotL : public CSlotBase
  {
private:
   //--- Pip-to-price conversion helper (handles 4-digit vs 5-digit broker)
   double            _PipsToPrice(double pips) const
     {
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double point_mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
      return pips * _Point * point_mult;
     }

   //--- Count open L orders via PortfolioState comment-prefix filter
   //    MAGIC_L is shared with LX — filter by "L," prefix to own only.
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
         return +1;  // above cloud — BUY trend
      if(ctx.bid < cloud_low)
         return -1;  // below cloud — SELL trend
      return 0;      // inside cloud — no clear trend
     }

public:
   //--- Constructor: no member state beyond base
   CSlotL() {}
   virtual          ~CSlotL() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() — returns MAGIC_L (211) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_L; }

   //--- 2. SlotId() — used by journal record `slot_id` field
   virtual string    SlotId() const override { return "L"; }

   //--- 3. Evaluate() — entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 5 of N CodeWiki §3.L conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotL)
         return;

      //--- Entry condition 1: no existing L order open
      //    Uses comment-prefix "L," filter — LX orders (magic=211 + "LX,") excluded.
      if(_CountLOrders(port) >= InpLMaxOrders)
         return;

      //--- Entry condition 2: ADX volatility gate
      //    CodeWiki §3.L — avoid low-volatility regime
      if(ctx.adx_h4.adx < InpLAdxThreshold)
         return;

      //--- Entry condition 3: D1 Ichimoku trend filter
      //    CodeWiki §3.L — align with higher-timeframe trend
      int trend_dir = _D1TrendDirection(ctx);
      if(trend_dir == 0)
         return;  // price inside cloud — no trade

      //--- Entry condition 4: WPR wave signal (derived, computed once per tick)
      //    CodeWiki §3.L — wpr_wave_signal = RunCheckWPRWaveWithIchimoku2 result
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

      //--- Lot sizing via RiskManager (no direct CTrade — ADR-002 rule)
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

      //--- Build order parameters
      ENUM_ORDER_TYPE  order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double           price      = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist    = _PipsToPrice(InpLSlPips);
      double           sl_price   = buy_signal ? (price - sl_dist) : (price + sl_dist);
      string           comment    = "L,wave,1";

      //--- Submit order via RiskManager (which wraps CTrade per ea.md)
      //    RiskManager::OpenOrder wired at IMPL-053+ Orchestrator skeleton.
      //    Until then: log intent so SelfTest/smoke verifies entry path
      //    without panicking on NULL CTrade.
      if(m_logger != NULL)
         m_logger.Info("Slot_L", buy_signal ? "entry_buy" : "entry_sell",
                       Magic(),
                       StringFormat("lot=%.2f price=%.5f sl=%.5f comment=%s",
                                    lot, price, sl_price, comment));
     }

   //--- 4. ManageExits() — exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit condition: profit >= InpLTpProfitPips.
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotL)
         return;

      //--- Iterate open orders for magic MAGIC_L, comment prefix "L,"
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;
         if(OrderGetInteger(ORDER_MAGIC) != MAGIC_L)
            continue;

         //--- Comment-prefix filter: only "L," orders (not "LX," from IMPL-031)
         string order_comment = OrderGetString(ORDER_COMMENT);
         if(StringFind(order_comment, "L,") != 0)
            continue;

         //--- Get current profit in pips
         double open_price  = OrderGetDouble(ORDER_PRICE_OPEN);
         double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

         double price_diff = 0.0;
         if(otype == ORDER_TYPE_BUY)
            price_diff = current_bid - open_price;
         else if(otype == ORDER_TYPE_SELL)
            price_diff = open_price - current_ask;

         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         double point_mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
         double profit_pips = price_diff / (_Point * point_mult);

         //--- Exit condition: profit >= InpLTpProfitPips gate (40 pip default)
         if(profit_pips < InpLTpProfitPips)
            continue;

         if(m_logger != NULL)
            m_logger.Info("Slot_L", "exit_profit_gate", Magic(),
                          StringFormat("ticket=%llu profit_pips=%.1f comment=%s",
                                       ticket, profit_pips, order_comment));

         //--- Close order via RiskManager (CTrade wired at IMPL-053+)
         //    Log intent only until wiring complete (same pattern as Evaluate).
        }
     }

   //--- 5. DependsOn() — L is independent (no peer slot deps)
   //    LX + S depend ON L (reverse direction) — those land at IMPL-031/036.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() — L does not use pending sub-flow;
   //    safe default PENDING_STATE_IDLE (overridden here explicitly
   //    for documentation clarity per CSlotBase contract ADR-002).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_L_MQH
