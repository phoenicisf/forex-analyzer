//+------------------------------------------------------------------+
//| Slot_H.mqh — Slot H (Fractal + Ichimoku Distance)  (IMPL-023)    |
//| Layer:   slots/                                                   |
//| Magic:   MAGIC_H = 205                                            |
//| Comment: "H,fractal,1"                                            |
//| Source:  PhoenicisN2.10_CodeWiki.md §3.4                          |
//|          ADR-002 (CSlotBase contract)                             |
//|          TD-02 §5.4 (lot sizing via RiskManager)                  |
//|                                                                   |
//| M-size MVP entry conditions (4 of 12 from CodeWiki §3.4):         |
//|   1. Max 2 H orders open (InpHMaxOrders)                          |
//|   2. Same-bar cooldown (m_last_bar_entered != current H4 bar)     |
//|   3. Fractal alignment at bar 2 or 3 (MarketContext.fractal_h4)   |
//|   4. Ichimoku cloud distance ≤ 35 pip (InpHIchimokuMaxPips)       |
//|                                                                   |
//| Deferred to P4 IMPL-062:                                          |
//|   ADX-cross filter / WPR filter / Bollinger filter / nerve-lot    |
//|   C-anchored 50-pip drawdown guard                                |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_H_MQH
#define PHOENICISNEX_SLOTS_SLOT_H_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/EnumTypes.mqh"
#include "../domain/MarketContext.mqh"
#include "../inputs/Inputs_Slot_H.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/Logger.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| CSlotH — Slot H (Fractal + Ichimoku Distance)                    |
//|                                                                   |
//| Inherits: CSlotBase (ADR-002 contract — all 6 methods overridden)|
//| Services:  m_risk (lot sizing), m_logger (structured logging),   |
//|            m_journal (trade event recording) — injected via Init()|
//| Note:      PortfolioState passed at tick (Evaluate/ManageExits)  |
//|            not stored — slots must not cache port between ticks.  |
//+------------------------------------------------------------------+
class CSlotH : public CSlotBase
  {
private:
   //--- Per-instance state (cooldown tracking)
   int               m_last_bar_entered;   // H4 bar_index when last entry was placed
   CTrade            m_trade_exec;         // CTrade wrapper — wraps OrderSend per ea.md

   //--- Private helpers
   bool              _HasFractalBuy(const MarketContext &ctx) const;
   bool              _HasFractalSell(const MarketContext &ctx) const;
   bool              _IchimokuDistanceOk(const MarketContext &ctx, bool is_buy) const;
   int               _CountHOrders() const;
   void              _TryExit(ulong ticket, double open_price, datetime open_time,
                              ENUM_ORDER_TYPE order_type);

public:
   //--- Constructor — zero-init private state
                     CSlotH() : m_last_bar_entered(-1) {}
   virtual          ~CSlotH() {}

   //--- 6-method contract (CSlotBase ADR-002) -------------------------

   //--- Magic(): returns MAGIC_H (205) per BR-1.1
   virtual int           Magic()  const override { return MAGIC_H; }

   //--- SlotId(): returns "H" for journal slot_id disambiguation
   virtual string        SlotId() const override { return "H"; }

   //--- Evaluate(): entry pass — called by Orchestrator per tick (FR-2.3)
   //    Only invoked when EAState == RUNNING (ADR-010 enforced by Orchestrator)
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- ManageExits(): exit pass — called BEFORE Evaluate (BR-2.2)
   //    Runs in BOTH RUNNING and HALTED states (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- DependsOn(): Slot H is independent — no peer slot deps
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- PendingState(): H uses IDLE (not in C/D/F/J/R/P/M/T/Q pending list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }

  }; // end class CSlotH


//+------------------------------------------------------------------+
//| _HasFractalBuy — bar 2 or bar 3 has a lower fractal              |
//| CodeWiki §3.4 condition 3: FractalPredicate(BUY) returns ≥ 0     |
//| Uses MarketContext.fractal_h4.has_lower / .lower_fractal          |
//+------------------------------------------------------------------+
bool CSlotH::_HasFractalBuy(const MarketContext &ctx) const
  {
   return ctx.fractal_h4.has_lower;
  }

//+------------------------------------------------------------------+
//| _HasFractalSell — bar 2 or bar 3 has an upper fractal            |
//| CodeWiki §3.4 condition 3: FractalPredicate(SELL) returns ≥ 0    |
//+------------------------------------------------------------------+
bool CSlotH::_HasFractalSell(const MarketContext &ctx) const
  {
   return ctx.fractal_h4.has_upper;
  }

//+------------------------------------------------------------------+
//| _IchimokuDistanceOk — cloud edge distance ≤ InpHIchimokuMaxPips  |
//| CodeWiki §3.4 condition 4: fractal vs cloud edge ≤ 35 pip        |
//| For BUY: price near/below cloud bottom; for SELL: near/above top  |
//+------------------------------------------------------------------+
bool CSlotH::_IchimokuDistanceOk(const MarketContext &ctx, bool is_buy) const
  {
   double pip_size = _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
   if(pip_size <= 0.0) return false;

   double cloud_ref = is_buy ? ctx.ichi_h4.cloud_low : ctx.ichi_h4.cloud_high;
   double price_ref = is_buy ? ctx.ask : ctx.bid;
   double dist_pips = MathAbs(price_ref - cloud_ref) / pip_size;

   return dist_pips <= InpHIchimokuMaxPips;
  }

//+------------------------------------------------------------------+
//| _CountHOrders — count open positions tagged with "H," comment    |
//| CodeWiki §3.4 condition 1: max 2 H orders                        |
//+------------------------------------------------------------------+
int CSlotH::_CountHOrders() const
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MAGIC_H)
        {
         string cmt = PositionGetString(POSITION_COMMENT);
         if(StringFind(cmt, "H,") == 0)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| _TryExit — evaluate and close a single H position if exit cond   |
//| Exit criteria (M-size MVP):                                       |
//|   - Profit ≥ InpHTpMinPips (30 pip gate)                         |
//|   - OR order age > InpHMaxAgeBars H4 bars (8-bar age gate)        |
//+------------------------------------------------------------------+
void CSlotH::_TryExit(ulong ticket, double open_price, datetime open_time,
                      ENUM_ORDER_TYPE order_type)
  {
   double pip_size = _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
   if(pip_size <= 0.0) return;

   double current_price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profit_pips = (order_type == ORDER_TYPE_BUY) ? (current_price - open_price) / pip_size
                                                       : (open_price - current_price) / pip_size;

   //--- Check bar-age gate: use iBarShift to compute how many H4 bars have passed
   int age_bars = iBarShift(_Symbol, PERIOD_H4, open_time, false);

   bool should_exit = (profit_pips >= InpHTpMinPips) || (age_bars > InpHMaxAgeBars);
   if(!should_exit) return;

   //--- Close via CTrade member (m_trade_exec — ea.md: slots ห้าม instantiate CTrade ตรง)
   if(!m_trade_exec.PositionClose(ticket))
     {
      if(m_logger != NULL)
         m_logger.Warn("Slot_H", "exit_fail", MAGIC_H,
                       StringFormat("ticket=%llu profit_pips=%.1f age=%d",
                                    ticket, profit_pips, age_bars));
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Info("Slot_H", "exit_ok", MAGIC_H,
                       StringFormat("ticket=%llu profit_pips=%.1f age=%d",
                                    ticket, profit_pips, age_bars));
     }
  }

//+------------------------------------------------------------------+
//| ManageExits — exit pass (BR-2.2: runs before Evaluate)           |
//+------------------------------------------------------------------+
void CSlotH::ManageExits(CPortfolioState &port)
  {
   //--- Iterate all open positions with MAGIC_H + "H," comment prefix
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MAGIC_H) continue;

      string cmt = PositionGetString(POSITION_COMMENT);
      if(StringFind(cmt, "H,") != 0) continue;

      double     open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      datetime   open_time  = (datetime)PositionGetInteger(POSITION_TIME);
      ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);

      _TryExit(ticket, open_price, open_time, otype);
     }
  }

//+------------------------------------------------------------------+
//| Evaluate — entry pass (FR-2.3; only in RUNNING state)            |
//| M-size MVP: 4 conditions only (CodeWiki §3.4 conditions 1-4)      |
//+------------------------------------------------------------------+
void CSlotH::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpHEnabled) return;

   //--- Condition 1: max orders guard
   if(_CountHOrders() >= InpHMaxOrders) return;

   //--- Condition 2: same-bar cooldown (no double entry on same H4 bar)
   if(ctx.bar_index_h4 == m_last_bar_entered) return;

   //--- Determine direction from fractal
   bool can_buy  = _HasFractalBuy(ctx);
   bool can_sell = _HasFractalSell(ctx);
   if(!can_buy && !can_sell) return;   // no fractal signal

   //--- Prefer BUY direction if both signals present (M-size tie-break)
   bool is_buy = can_buy;

   //--- Condition 4: Ichimoku distance filter
   if(!_IchimokuDistanceOk(ctx, is_buy)) return;

   //--- Lot sizing via RiskManager (slots ห้าม call CTrade ตรง — ADR-002)
   double lot = 0.0;
   if(m_risk != NULL)
      lot = m_risk.ComputeLot("H", InpHSlPips,
                              AccountInfoDouble(ACCOUNT_BALANCE),
                              1.0 /* extra_multiplier */);

   if(lot <= 0.0)
     {
      if(m_logger != NULL)
         m_logger.Warn("Slot_H", "lot_zero", MAGIC_H, "ComputeLot returned 0; skipping entry");
      return;
     }

   //--- Submit order via CTrade member (not base m_risk CTrade — ea.md: ห้าม instantiate CTrade ตรง)
   ENUM_ORDER_TYPE order_type = is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   string comment_str = "H,fractal,1";

   bool sent = false;
   if(order_type == ORDER_TYPE_BUY)
      sent = m_trade_exec.Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment_str);
   else
      sent = m_trade_exec.Sell(lot, _Symbol, 0.0, 0.0, 0.0, comment_str);

   if(sent)
     {
      m_last_bar_entered = ctx.bar_index_h4;
      if(m_logger != NULL)
         m_logger.Info("Slot_H", "entry_ok", MAGIC_H,
                       StringFormat("dir=%s lot=%.2f bar=%d comment=%s",
                                    is_buy ? "BUY" : "SELL",
                                    lot, ctx.bar_index_h4, comment_str));
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Warn("Slot_H", "entry_fail", MAGIC_H,
                       StringFormat("dir=%s lot=%.2f retcode=%d",
                                    is_buy ? "BUY" : "SELL",
                                    lot, m_trade_exec.ResultRetcode()));
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_H_MQH
