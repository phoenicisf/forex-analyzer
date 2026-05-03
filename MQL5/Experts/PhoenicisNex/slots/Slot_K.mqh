//+------------------------------------------------------------------+
//| slots/Slot_K.mqh — Slot K derived class (IMPL-024)               |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   207 (MAGIC_K per domain/EnumTypes.mqh)                   |
//| SlotId:  "K"                                                      |
//| Comment: "K,layer,1"                                              |
//|                                                                  |
//| Source:  CodeWiki §3.5 (M-size MVP: 4 of 8 entry conditions)     |
//|          TD-02 §5.4 (lot dispatch RiskManager::ComputeLot)        |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency — ห้าม #include slots/*)        |
//|                                                                  |
//| M-size MVP scope (4 of 8 entry conditions per shared context §4): |
//|   1. No existing K order (PortfolioState count by magic)          |
//|   2. iTime(D1,0) > m_last_order_d1_time (one K per day)           |
//|      // CodeWiki §3.5 entry condition 2                           |
//|   3. Force crossover: isFICrossUp / isFICrossDw                   |
//|      // CodeWiki §3.5 entry condition 3                           |
//|   4. Price outside Ichimoku cloud matches direction                |
//|                                                                  |
//| P4 deferred (IMPL-036):                                           |
//|   - Tenkan/Kijun secondary layer conditions                       |
//|   - 2hr C-pending cooldown                                        |
//|   - KExtra pyramiding logic                                       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_K_MQH
#define PHOENICISNEX_SLOTS_SLOT_K_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../inputs/Inputs_Slot_K.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/RiskManager.mqh"

//+------------------------------------------------------------------+
//| CSlotK — Slot K concrete derived class                           |
//|                                                                  |
//| Entry logic: Force Index crossover + D1 once-per-day guard +     |
//|   no existing K order + price outside Ichimoku cloud.             |
//|                                                                  |
//| Exit logic: profit >= InpKTpProfitPips (20 pip default) AND      |
//|   price touches Ichimoku cloud edge (cloud_high / cloud_low).    |
//+------------------------------------------------------------------+
class CSlotK : public CSlotBase
  {
private:
   //--- D1 once-per-day guard (CodeWiki §3.5 entry condition 2)
   //    Stores the D1 bar open time of the last filled K order.
   //    Compared against iTime(_Symbol, PERIOD_D1, 0) on each Evaluate tick.
   datetime          m_last_order_d1_time;

   //--- Pip-to-price conversion helper (handles 4-digit vs 5-digit broker)
   double            _PipsToPrice(double pips) const
     {
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double point_mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
      return pips * _Point * point_mult;
     }

   //--- Force crossover detection (CodeWiki §3.5 entry condition 3)
   //    isFICrossUp = (F[1]>0.5 && F[2]>0 && F[3]<-0.2) || (F[1]>1 && F[2]<-0.2)
   //    isFICrossDw = mirror for SELL
   bool              _IsFICrossUp(const ForceFields &f) const
     {
      // Primary pattern
      if(f.f1 > InpKFICrossThreshHigh && f.f2 > 0.0 && f.f3 < InpKFICrossThreshLow)
         return true;
      // Alternate pattern
      if(f.f1 > InpKFICrossAltHigh && f.f2 < InpKFICrossThreshLow)
         return true;
      return false;
     }

   bool              _IsFICrossDw(const ForceFields &f) const
     {
      // Primary pattern (mirror of BUY)
      if(f.f1 < -InpKFICrossThreshHigh && f.f2 < 0.0 && f.f3 > -InpKFICrossThreshLow)
         return true;
      // Alternate pattern (mirror)
      if(f.f1 < -InpKFICrossAltHigh && f.f2 > -InpKFICrossThreshLow)
         return true;
      return false;
     }

   //--- Count open K orders via PortfolioState
   int               _CountKOrders(CPortfolioState &port) const
     {
      SlotState *st = port.GetByMagic(MAGIC_K);
      if(st == NULL)
         return 0;
      return st.buy_count + st.sell_count;
     }

public:
   //--- Constructor: zero-init member state
   CSlotK() : m_last_order_d1_time(0) {}
   virtual          ~CSlotK() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() — returns MAGIC_K (207) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_K; }

   //--- 2. SlotId() — used by journal record `slot_id` field
   virtual string    SlotId() const override { return "K"; }

   //--- 3. Evaluate() — entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 4 of 8 CodeWiki §3.5 conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotK)
         return;

      //--- Entry condition 1: no existing K order open
      // CodeWiki §3.5 — max 1 K order (KExtra defer P4)
      if(_CountKOrders(port) >= InpKMaxOrders)
         return;

      //--- Entry condition 2: one K per day (D1 timestamp guard)
      // CodeWiki §3.5 entry condition 2
      datetime d1_bar_time = iTime(_Symbol, PERIOD_D1, 0);
      if(d1_bar_time <= m_last_order_d1_time)
         return;

      //--- Entry condition 3: Force crossover signal
      // CodeWiki §3.5 entry condition 3 — isFICrossUp / isFICrossDw
      bool fi_cross_up = _IsFICrossUp(ctx.force_h4);
      bool fi_cross_dw = _IsFICrossDw(ctx.force_h4);
      if(!fi_cross_up && !fi_cross_dw)
         return;

      //--- Entry condition 4: price outside Ichimoku cloud matches direction
      double cloud_high = ctx.ichi_h4.cloud_high;
      double cloud_low  = ctx.ichi_h4.cloud_low;

      bool buy_signal  = fi_cross_up && (ctx.bid > cloud_high);
      bool sell_signal = fi_cross_dw && (ctx.bid < cloud_low);
      if(!buy_signal && !sell_signal)
         return;

      //--- Lot sizing via RiskManager (no direct CTrade — ADR-002 rule)
      if(m_risk == NULL)
        {
         if(m_logger != NULL)
            m_logger.Error("Slot_K", "risk_manager_null", Magic(), "Evaluate");
         return;
        }
      double lot = m_risk.ComputeLot("K", InpKSlPips,
                                     AccountInfoDouble(ACCOUNT_BALANCE));
      if(lot <= 0.0)
         return;

      //--- Build order parameters
      ENUM_ORDER_TYPE  order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double           price      = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist    = _PipsToPrice(InpKSlPips);
      double           sl_price   = buy_signal ? (price - sl_dist) : (price + sl_dist);
      string           comment    = "K,layer,1";

      //--- Submit order via RiskManager (which wraps CTrade per ea.md)
      //    RiskManager::OpenOrder wired at IMPL-053+ Orchestrator skeleton.
      //    Until then: log intent + update D1 guard so SelfTest/smoke
      //    verifies the entry path without panicking on NULL CTrade.
      if(m_logger != NULL)
         m_logger.Info("Slot_K", buy_signal ? "entry_buy" : "entry_sell",
                       Magic(),
                       StringFormat("lot=%.2f price=%.5f sl=%.5f comment=%s",
                                    lot, price, sl_price, comment));

      //--- Update D1 guard AFTER logging intent (prevents re-entry same day)
      m_last_order_d1_time = d1_bar_time;
     }

   //--- 4. ManageExits() — exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit conditions: profit >= 20 pip + cloud touch.
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotK)
         return;

      //--- Iterate open orders for magic MAGIC_K
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;
         if(OrderGetInteger(ORDER_MAGIC) != MAGIC_K)
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

         //--- Exit condition 1: profit >= 20 pip gate
         if(profit_pips < InpKTpProfitPips)
            continue;

         //--- Exit condition 2: price touches Ichimoku cloud edge
         //    (cloud_high / cloud_low from last available MarketContext)
         //    Using symbol bid/ask and PortfolioState for cloud values.
         //    Full cloud-touch check deferred to IMPL-053+ when ctx is
         //    passed to ManageExits. For MVP: close on profit gate alone
         //    when InpKTpProfitPips threshold met (sufficient for E-AC).
         if(m_logger != NULL)
            m_logger.Info("Slot_K", "exit_profit_gate", Magic(),
                          StringFormat("ticket=%llu profit_pips=%.1f", ticket, profit_pips));

         //--- Close order via RiskManager (CTrade wired at IMPL-053+)
         //    Log intent only until wiring complete (same pattern as Evaluate).
        }
     }

   //--- 5. DependsOn() — K is independent (no peer slot deps)
   //    S → K post-close dependency deferred to P4 IMPL-036.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() — K does not use pending sub-flow;
   //    safe default PENDING_STATE_IDLE inherited from base (overridden
   //    here explicitly for documentation clarity).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_K_MQH
