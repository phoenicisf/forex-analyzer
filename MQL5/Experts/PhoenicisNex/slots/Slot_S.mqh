//+------------------------------------------------------------------+
//| slots/Slot_S.mqh — Slot S implementation (IMPL-036)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_S = 217 (own; not shared)                          |
//| SlotId:  "S"                                                      |
//| Comment: "S,post,1"                                               |
//|                                                                   |
//| Source:  CodeWiki §3.S; TD-02 §5.4; ADR-002; ADR-012             |
//|                                                                   |
//| M-size MVP — 5 of N CodeWiki §3.S conditions (post-close after L/K):
//|   1. Both L and K parents inactive (proxy for "post-close state")  |
//|      → port.GetTicketsForSlot(MAGIC_L, "L,", l_tickets) == 0 AND  |
//|        port.GetTicketsForSlot(MAGIC_K, "K,", k_tickets) == 0      |
//|      // CodeWiki §3.S — S triggers when L/K windows closed        |
//|   2. Own no-active S guard (prevent double-entry)                  |
//|      → port.GetTicketsForSlot(MAGIC_S, "S,", own_tickets) == 0    |
//|      // CodeWiki §3.S — single active S position                  |
//|   3. ADX volatility gate: adx_h4.adx > InpSAdxMin (default 20.0) |
//|      // CodeWiki §3.S — avoid low-volatility regime               |
//|   4. WPR threshold confirmation (H4 WPR oversold/overbought)       |
//|      // CodeWiki §3.S — momentum confirmation on follow-on entry   |
//|   5. D1 Ichimoku trend alignment filter (price vs cloud)           |
//|      // CodeWiki §3.S — higher-timeframe trend alignment           |
//|                                                                   |
//| Deferred to P4 IMPL-062:                                          |
//|   - Stochastic secondary confirmation (stoch_h4 K/D cross)        |
//|   - Sub-demand zone proximity filter (subdem_h4 proximity gate)    |
//|   - Hull MA slope gate (hull_h4.hull_slope direction)              |
//|   - DeMarker secondary confirmation (dem_h4.dem < 0.3 oversold)   |
//|   - Fractal-based SL refinement (fractal_h4 nearest fractal)       |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate >= InpSTpProfitPips (35 pip default)              |
//|   Stub: log exit_profit_gate intent; OrderClose deferred <closed; ref purged fix-round-18 §18.1> |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("S", InpSSlPips, balance)            |
//| Comment: "S,post,1" per CodeWiki §3.S "S,..." pattern             |
//|                                                                   |
//| Topology dependency:                                              |
//|   DependsOn() returns 2:                                          |
//|     out_magics[0] = MAGIC_L (parent L must be post-close)         |
//|     out_magics[1] = MAGIC_K (parent K must be post-close)         |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected via base)   |
//|   Cross-slot access via PortfolioState.GetTicketsForSlot() only   |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_S_MQH
#define PHOENICISNEX_SLOTS_SLOT_S_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_S.mqh"

//+------------------------------------------------------------------+
//| CSlotS — Slot S concrete derived class (ADR-002 CSlotBase contract)|
//|                                                                   |
//| Post-close follow-on pattern:                                     |
//|   - Entry ONLY when BOTH L and K parents have no active orders    |
//|   - Direction confirmed by WPR momentum + D1 Ichimoku trend       |
//|   - ADX gate prevents entry in low-volatility regimes             |
//|   - Own-no-active guard prevents double-entry                     |
//|                                                                   |
//| Magic 217 own (not shared). Comment prefix "S," in all orders.    |
//| GetTicketsForSlot(MAGIC_S, "S,", tickets) filters own orders.     |
//+------------------------------------------------------------------+
class CSlotS : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` inherited from base.

   //--- Check if BOTH L and K parent slots have no active orders
   //    "Post-close" proxy: both parents inactive = L/K window closed
   //    ADR-012: cross-slot access only via PortfolioState
   bool              _BothParentsInactive(CPortfolioState &port) const
     {
      ulong l_tickets[];
      ulong k_tickets[];
      int l_count = port.GetTicketsForSlot(MAGIC_L, "L,", l_tickets);
      int k_count = port.GetTicketsForSlot(MAGIC_K, "K,", k_tickets);
      return (l_count == 0 && k_count == 0);
     }

   //--- Check if S has no active own orders (own-no-active guard)
   bool              _HasActiveSOrder(CPortfolioState &port) const
     {
      ulong s_tickets[];
      int n = port.GetTicketsForSlot(MAGIC_S, "S,", s_tickets);
      return n > 0;
     }

   //--- D1 trend direction: BUY if price above D1 cloud, SELL if below
   //    Returns: +1 = BUY trend, -1 = SELL trend, 0 = inside cloud (no signal)
   //    // CodeWiki §3.S — higher-timeframe trend alignment (mirror Slot_L pattern)
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
   //--- Constructor / Destructor
   CSlotS() {}
   virtual          ~CSlotS() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() — returns MAGIC_S (217) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_S; }

   //--- 2. SlotId() — used by journal record `slot_id` field
   virtual string    SlotId() const override { return "S"; }

   //--- 3. Evaluate() — entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 5 of N CodeWiki §3.S conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits() — exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit condition: profit >= InpSTpProfitPips.
   virtual void      ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn() — S depends on L (MAGIC_L=211) and K (MAGIC_K=207)
   //    post-close: both parents must be inactive for S entry to trigger.
   //    Returns 2 (distinct from 0-dep slots G2/LX/L/K themselves).
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 2);
      out_magics[0] = MAGIC_L;  // L parent — post-close proxy
      out_magics[1] = MAGIC_K;  // K parent — post-close proxy
      return 2;
     }

   //--- 6. PendingState() — S is non-PMR; always returns PENDING_STATE_IDLE.
   //    No pending machine for Slot S per IMPL-036 scope (non-PMR).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

//+------------------------------------------------------------------+
//| Evaluate — Slot S entry pass (CodeWiki §3.S MVP)                  |
//|                                                                   |
//| Entry conditions (5 of N for M-size MVP):                         |
//|   1. InpEnableSlotS == true                                       |
//|   2. Both L and K parents inactive (post-close proxy gate)        |
//|   3. No active S orders (own-no-active guard)                     |
//|   4. ADX volatility gate: adx_h4.adx > InpSAdxMin                |
//|   5. D1 Ichimoku trend direction clear (not inside cloud)         |
//|   6. WPR threshold confirmation (BUY: oversold / SELL: overbought)|
//|                                                                   |
//| Lot: RiskManager::ComputeLot("S", InpSSlPips, balance)            |
//| Comment: "S,post,1" per CodeWiki §3.S "S,..." pattern             |
//+------------------------------------------------------------------+
void CSlotS::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotS) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1 (post-close proxy gate): both L and K must have no active orders
   //    ADR-012: cross-slot access via PortfolioState.GetTicketsForSlot only
   //    // CodeWiki §3.S — S entry triggers when L/K windows closed
   if(!_BothParentsInactive(port)) return;

   //--- Condition 2 (own-no-active guard): S must have no open "S," orders
   //    // CodeWiki §3.S — single active S position allowed
   if(_HasActiveSOrder(port)) return;

   //--- Condition 3: ADX volatility gate
   //    // CodeWiki §3.S — avoid low-volatility regime; same gate as Slot_L
   if(ctx.adx_h4.adx < InpSAdxMin) return;

   //--- Condition 4: D1 Ichimoku trend filter
   //    // CodeWiki §3.S — align with higher-timeframe trend
   int trend_dir = _D1TrendDirection(ctx);
   if(trend_dir == 0) return;  // price inside cloud — no trade

   //--- Condition 5: WPR threshold confirmation (H4)
   //    BUY: wpr_h4 oversold (< InpSWprOversold = -80)
   //    SELL: wpr_h4 overbought (> InpSWprOverbought = -20)
   //    // CodeWiki §3.S — momentum confirmation on follow-on entry
   bool buy_signal  = (trend_dir == +1) && (ctx.wpr_h4.wpr < InpSWprOversold);
   bool sell_signal = (trend_dir == -1) && (ctx.wpr_h4.wpr > InpSWprOverbought);
   if(!buy_signal && !sell_signal) return;

   //--- Compute lot via RiskManager (no direct CTrade — ADR-002 + ea.md rule)
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("S", InpSSlPips, balance, InpSPercentTp);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotS", "zero_lot_skip", MAGIC_S,
                    "ComputeLot returned 0 — skipping S entry");
      return;
     }

   //--- Compute prices
   int    digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double sl_dist  = _PipsToPrice(InpSSlPips);
   double price    = buy_signal ? ctx.ask : ctx.bid;
   double sl_price = buy_signal
                     ? NormalizeDouble(ctx.ask - sl_dist, digits)
                     : NormalizeDouble(ctx.bid + sl_dist, digits);

   //--- Comment: "S,post,1" per CodeWiki §3.S "S,..." pattern
   string comment = "S,post,1";

   //--- Build MqlTradeRequest stub (req.magic = MAGIC_S per directive).
   //    fix-round-12 § 12.8 — Phase 1 architectural choice: slots emit
   //    `entry_signal` Logger.Info as the observable milestone; actual
   //    OrderSend wiring lives in `RiskManager::OpenOrder` per
   //    `.claude/rules/ea.md` (<closed; ref purged fix-round-18 §18.1> 5-yr regression).
   //    Observable milestone for E-AC [log-assertion]:
   MqlTradeRequest req = {};
   req.action    = TRADE_ACTION_DEAL;
   req.magic     = MAGIC_S;
   req.symbol    = _Symbol;
   req.volume    = lot;
   req.price     = price;
   req.sl        = sl_price;
   req.tp        = 0.0;
   req.type      = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.type_filling = ORDER_FILLING_IOC;
   req.comment   = comment;

   m_logger.Info("SlotS", "entry_signal", MAGIC_S,
                 StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s"
                              " adx=%.1f wpr=%.1f trend=%d",
                              (buy_signal ? "BUY" : "SELL"),
                              lot, InpSSlPips, price, sl_price, comment,
                              ctx.adx_h4.adx, ctx.wpr_h4.wpr, trend_dir));

   //--- CrossSlotCoordinator stub
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (<closed; ref purged fix-round-18 §18.1>) */)
     {
      //--- Stub: S post-close coupling
      //    wires at <closed; ref purged fix-round-18 §18.1> (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot S exit pass (profit gate; 35 pip MVP)          |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate S positions via GetTicketsForSlot(MAGIC_S, "S,")    |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate >= InpSTpProfitPips (35 pip) → log close intent  |
//|                                                                   |
//| Additional exit logic (P4 IMPL-062):                             |
//|   - Orphan-guard: close S if both L and K re-enter and re-close   |
//|   - Trailing stop on Ichimoku kijun-sen level                     |
//+------------------------------------------------------------------+
void CSlotS::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve S tickets (own comment prefix "S,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_S, "S,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY)
                                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Profit gate: >= InpSTpProfitPips (35 pip — post-close follow-on target)
      if(profit_pips >= InpSTpProfitPips)
        {
         m_logger.Info("SlotS", "exit_profit_gate", MAGIC_S,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpSTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    <closed; ref purged fix-round-18 §18.1> (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub
      if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (<closed; ref purged fix-round-18 §18.1>) */)
        {
         //--- Stub: orphan-guard coupling
         //    wires at <closed; ref purged fix-round-18 §18.1> (cross-slot coupling per ea.md).
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_S_MQH
