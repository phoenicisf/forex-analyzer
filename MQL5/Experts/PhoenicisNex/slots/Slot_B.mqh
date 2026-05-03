//+------------------------------------------------------------------+
//| slots/Slot_B.mqh — Slot B derived class (IMPL-037)                |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   214 (MAGIC_B per domain/EnumTypes.mqh; shared with BI)   |
//| SlotId:  "B"                                                      |
//| Comment: "B,..." — BI uses "BI," (IMPL-039 disambig)              |
//|                                                                  |
//| Source:  CodeWiki §3.17 (L-size MVP: 5 of 11 entry conditions)   |
//|          TD-02 §5.4 (lot dispatch RiskManager::ComputeLot)        |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency — ห้าม #include slots/*)        |
//|                                                                  |
//| L-size MVP scope (5 of 11 CodeWiki §3.17 conditions):            |
//|   1. No existing B order (PortfolioState comment-prefix filter)   |
//|      // CodeWiki §3.17 entry condition — single B at a time      |
//|   2. ADX volatility gate: adx_h4.adx > InpBAdxThreshold          |
//|      // CodeWiki §3.17 entry condition — avoid low-volatility    |
//|   3. Cloud distance ≤ InpBCloudDistMaxPips                       |
//|      // CodeWiki §3.17 entry condition #4 — distance from cloud  |
//|   4. Fractal alignment in lookback (anti-trend reversal signal)  |
//|      // CodeWiki §3.17 entry condition #5 — FractalUp/Low match  |
//|   5. Direction proxy via Ichimoku tenkan/kijun (lowMain/highMain) |
//|      // CodeWiki §3.17 BUY: bid<lowMain / SELL: bid>highMain     |
//|                                                                  |
//| BR/BI coupling: IMPL-038 (BR orphan exit-only) + IMPL-039 (BI    |
//|   pyramid child sharing MAGIC_B). Both spawn from ManageExits    |
//|   cascade — STUBBED via guarded `false /*IMPL-053*/` per Slot_G  |
//|   precedent. CrossSlotCoordinator wires real triggers at P4.    |
//|   DependsOn() returns 0 (B is independent; BR/BI depend ON B).  |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - !IsADXPeakValid anti-trend gate (CheckADXWithForcePeakValid2) |
//|   - ≤1 G/I sell counter-position guard                            |
//|   - Fractal count <3, ADXMain dominance <3 bars                   |
//|   - Ichimoku wave-start bar count valid                           |
//|   - SL = min(lowest wave bar, BBBot, lowMain) per CodeWiki        |
//|   - TP percentage = 20 + tpplus(SL-vs-cloud distance)             |
//|   - 8-branch ExtraTakeProfit_B nested exit cascade                |
//|   - DEM/WPR M15 validation in exit branches                       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_B_MQH
#define PHOENICISNEX_SLOTS_SLOT_B_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../inputs/Inputs_Slot_B.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/RiskManager.mqh"

//+------------------------------------------------------------------+
//| CSlotB — Slot B concrete derived class                          |
//|                                                                  |
//| Entry logic: anti-trend fractal reversal + cloud distance +     |
//|   ADX volatility + Ichimoku tenkan/kijun direction proxy +     |
//|   no existing B order.                                          |
//|                                                                  |
//| Exit logic: profit >= InpBTpProfitPips (50 pip default) +       |
//|   STUBBED BR-trigger hook (IMPL-053+ via CrossSlotCoordinator).|
//| Comment prefix: "B," — BI uses "BI," (IMPL-039 disambig).      |
//+------------------------------------------------------------------+
class CSlotB : public CSlotBase
  {
private:
   //--- Pip-to-price conversion helper (handles 4-digit vs 5-digit broker)
   double            _PipsToPrice(double pips) const
     {
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double point_mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
      return pips * _Point * point_mult;
     }

   //--- Price difference in pips (handles 4-digit vs 5-digit broker)
   double            _PriceDiffToPips(double price_diff) const
     {
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double point_mult = (digits == 3 || digits == 5) ? 10.0 : 1.0;
      return price_diff / (_Point * point_mult);
     }

   //--- Count open B orders via PortfolioState comment-prefix filter
   //    MAGIC_B is shared with BI — filter by "B," prefix to own only.
   //    Note: "BI," does NOT start with "B," followed by comma terminator;
   //    PortfolioState.GetTicketsForSlot uses StringFind(prefix, comment)==0
   //    so "B," matches both "B,..." and "BI,..." — so we explicitly check
   //    in StringFind helper that comment[1] is comma (cheap disambig).
   int               _CountBOrders(CPortfolioState &port) const
     {
      ulong tickets[];
      // GetTicketsForSlot returns prefix matches; "B," is a 2-char prefix.
      // BI orders carry "BI,..." → StringFind("B,", "BI,...") returns -1
      // (mismatch at index 1: ',' vs 'I'). So this filter is correct.
      return port.GetTicketsForSlot(MAGIC_B, "B,", tickets);
     }

   //--- Cloud distance in pips between bid and nearest cloud edge
   //    CodeWiki §3.17 cond 4: price-distance from cloud <180 pips
   double            _CloudDistancePips(const MarketContext &ctx) const
     {
      double cloud_high = ctx.ichi_h4.cloud_high;
      double cloud_low  = ctx.ichi_h4.cloud_low;
      double dist;
      if(ctx.bid > cloud_high)
         dist = ctx.bid - cloud_high;
      else if(ctx.bid < cloud_low)
         dist = cloud_low - ctx.bid;
      else
         dist = 0.0;  // inside cloud
      return _PriceDiffToPips(dist);
     }

   //--- Direction proxy: BUY when bid<lowMain (anti-trend below cloud),
   //    SELL when bid>highMain (anti-trend above cloud), 0 otherwise.
   //    "lowMain"/"highMain" approximated by Ichimoku tenkan/kijun min/max
   //    until full CodeWiki §1 indicator suite lands at IMPL-062.
   int               _AntiTrendDirection(const MarketContext &ctx) const
     {
      double tenkan = ctx.ichi_h4.tenkan[0];
      double kijun  = ctx.ichi_h4.kijun[0];
      double lowMain  = MathMin(tenkan, kijun);
      double highMain = MathMax(tenkan, kijun);
      if(ctx.bid < lowMain)
         return +1;  // anti-trend BUY (price dipped below tenkan/kijun)
      if(ctx.bid > highMain)
         return -1;  // anti-trend SELL
      return 0;
     }

   //--- Fractal alignment check: at least one fractal bar in lookback
   //    matching the BUY/SELL signal direction.
   //    CodeWiki §3.17 cond 5: FractalUp in [4..StartAwayFromIchiIndex)
   //    matching bid/open conditions. MVP: presence of fractal_h4 lower
   //    fractal for BUY, upper fractal for SELL.
   bool              _FractalAligned(const MarketContext &ctx, int direction) const
     {
      if(direction == +1)
         return ctx.fractal_h4.has_lower;
      if(direction == -1)
         return ctx.fractal_h4.has_upper;
      return false;
     }

public:
   //--- Constructor: no member state beyond base
   CSlotB() {}
   virtual          ~CSlotB() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() — returns MAGIC_B (214) per domain/EnumTypes.mqh
   //    Shared with BI (IMPL-039); CommentParser disambiguates by
   //    comment prefix ("B," vs "BI,") at PortfolioState filter sites.
   virtual int       Magic() const override { return MAGIC_B; }

   //--- 2. SlotId() — used by journal record `slot_id` field
   virtual string    SlotId() const override { return "B"; }

   //--- 3. Evaluate() — entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    L-size MVP: 5 of 11 CodeWiki §3.17 conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotB)
         return;

      //--- Entry condition 1: no existing B order open
      //    Uses comment-prefix "B," filter — BI orders ("BI,") excluded.
      if(_CountBOrders(port) >= InpBMaxOrders)
         return;

      //--- Entry condition 2: ADX volatility gate
      //    CodeWiki §3.17 — avoid low-volatility regime
      if(ctx.adx_h4.adx < InpBAdxThreshold)
         return;

      //--- Entry condition 3: cloud distance ≤ ceiling
      //    CodeWiki §3.17 cond 4 — price-distance from cloud <180 pips
      if(_CloudDistancePips(ctx) > InpBCloudDistMaxPips)
         return;

      //--- Entry condition 4: anti-trend direction proxy
      //    CodeWiki §3.17 — BUY when bid<lowMain / SELL when bid>highMain
      int direction = _AntiTrendDirection(ctx);
      if(direction == 0)
         return;  // bid inside tenkan/kijun band — no anti-trend signal

      //--- Entry condition 5: fractal alignment in lookback
      //    CodeWiki §3.17 cond 5 — FractalUp/Low matching direction
      if(!_FractalAligned(ctx, direction))
         return;

      //--- Lot sizing via RiskManager (no direct CTrade — ADR-002 rule)
      if(m_risk == NULL)
        {
         if(m_logger != NULL)
            m_logger.Error("Slot_B", "risk_manager_null", Magic(), "Evaluate");
         return;
        }
      double lot = m_risk.ComputeLot("B", InpBSlPips,
                                     AccountInfoDouble(ACCOUNT_BALANCE));
      if(lot <= 0.0)
         return;

      //--- Build order parameters
      bool             buy_signal = (direction == +1);
      ENUM_ORDER_TYPE  order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double           price      = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist    = _PipsToPrice(InpBSlPips);
      double           sl_price   = buy_signal ? (price - sl_dist) : (price + sl_dist);
      string           comment    = "B,anti,1";

      //--- Submit order via RiskManager (which wraps CTrade per ea.md)
      //    RiskManager::OpenOrder wired at IMPL-053+ Orchestrator skeleton.
      //    Until then: log intent so SelfTest/smoke verifies entry path
      //    without panicking on NULL CTrade.
      if(m_logger != NULL)
         m_logger.Info("Slot_B", buy_signal ? "entry_buy" : "entry_sell",
                       Magic(),
                       StringFormat("lot=%.2f price=%.5f sl=%.5f comment=%s",
                                    lot, price, sl_price, comment));
     }

   //--- 4. ManageExits() — exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit condition: profit >= InpBTpProfitPips.
   //    Hosts BR-trigger + BI pyramid hooks (BOTH stubbed to IMPL-053+).
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotB)
         return;

      //--- Iterate open orders for magic MAGIC_B, comment prefix "B,"
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;
         if(OrderGetInteger(ORDER_MAGIC) != MAGIC_B)
            continue;

         //--- Comment-prefix filter: only "B," orders (not "BI," from IMPL-039)
         //    StringFind("BI,...", "B,") returns -1 (mismatch index 1).
         string order_comment = OrderGetString(ORDER_COMMENT);
         if(StringFind(order_comment, "B,") != 0)
            continue;
         // Defensive: explicitly exclude any "BI," that might slip the index check
         if(StringFind(order_comment, "BI,") == 0)
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

         double profit_pips = _PriceDiffToPips(price_diff);

         //--- BR-trigger hook (BR-2.2 orphan exit-only spawn)
         //    CodeWiki §3.18 — BusinessLogic_BR called from inside
         //    ExtraTakeProfit_B when a B order closes. Real wiring lands
         //    at IMPL-053 CrossSlotCoordinator; gated `false` keeps G1
         //    compile clean and intent visible per Slot_G precedent.
         //    Pre-close trigger: emit hook before OrderClose returns.
         if(m_xslot != NULL && false /*IMPL-053 — BR-2.2 orphan exit*/)
           {
            // m_xslot.TriggerBR(MAGIC_BR, otype, OrderGetDouble(ORDER_VOLUME_CURRENT),
            //                   profit_pips, "S" /*br_mode placeholder*/);
           }

         //--- BI pyramid hook (CodeWiki §3.19 — BI shares MAGIC_B)
         //    BI force-close on B parent gone is owned by IMPL-039 BI's
         //    own ManageExits (ADR-009 G4 SL fix). Reference here only.
         //    No action required from Slot B side.

         //--- Exit condition: profit >= InpBTpProfitPips gate (50 pip default)
         if(profit_pips < InpBTpProfitPips)
            continue;

         if(m_logger != NULL)
            m_logger.Info("Slot_B", "exit_profit_gate", Magic(),
                          StringFormat("ticket=%llu profit_pips=%.1f comment=%s",
                                       ticket, profit_pips, order_comment));

         //--- Close order via RiskManager (CTrade wired at IMPL-053+)
         //    Log intent only until wiring complete (same pattern as Evaluate).
        }
     }

   //--- 5. DependsOn() — B is independent (no peer slot deps)
   //    BR (IMPL-038) + BI (IMPL-039) depend ON B (reverse direction).
   //    Orchestrator topo-sort places B before BR/BI in OnTick pass.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() — B does not use pending sub-flow;
   //    safe default PENDING_STATE_IDLE (overridden here explicitly
   //    for documentation clarity per CSlotBase contract ADR-002).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_B_MQH
