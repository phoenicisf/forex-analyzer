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

   //--- Private helpers
   bool              _HasFractalBuy(const MarketContext &ctx) const;
   bool              _HasFractalSell(const MarketContext &ctx) const;
   bool              _IchimokuDistanceOk(const MarketContext &ctx, bool is_buy) const;
   int               _CountHOrders(CPortfolioState &port) const;
   void              _TryExit(ulong ticket, double open_price, datetime open_time,
                              ENUM_POSITION_TYPE pos_type);

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
   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return false;

   double cloud_ref = is_buy ? ctx.ichi_h4.cloud_low : ctx.ichi_h4.cloud_high;
   double price_ref = is_buy ? ctx.ask : ctx.bid;
   double dist_pips = MathAbs(price_ref - cloud_ref) / pip_size;

   return dist_pips <= InpHIchimokuMaxPips;
  }

//+------------------------------------------------------------------+
//| _CountHOrders — count open positions tagged with "H," comment    |
//| CodeWiki §3.4 condition 1: max 2 H orders                        |
//| Uses canonical PortfolioState.GetTicketsForSlot per ADR-005 +    |
//| ADR-012 (slot data goes through the central choke point).        |
//+------------------------------------------------------------------+
int CSlotH::_CountHOrders(CPortfolioState &port) const
  {
   ulong tickets[];
   return port.GetTicketsForSlot(MAGIC_H, "H,", tickets);
  }

//+------------------------------------------------------------------+
//| _TryExit — evaluate exit conditions on a single H position       |
//| Exit criteria (M-size MVP):                                       |
//|   - Profit ≥ InpHTpMinPips (30 pip gate)                         |
//|   - OR order age > InpHMaxAgeBars H4 bars (8-bar age gate)        |
//|                                                                   |
//| Phase-1 stub: log-intent only — actual close goes through         |
//| RiskManager wrapper at <closed; ref purged fix-round-18 §18.1> (ea.md: ALL CTrade calls via     |
//| RiskManager). Pattern mirrors 17 sibling slots (Slot_BR canonical)|
//+------------------------------------------------------------------+
void CSlotH::_TryExit(ulong ticket, double open_price, datetime open_time,
                      ENUM_POSITION_TYPE pos_type)
  {
   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return;

   double current_price = (pos_type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                          : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profit_pips = (pos_type == POSITION_TYPE_BUY) ? (current_price - open_price) / pip_size
                                                        : (open_price - current_price) / pip_size;

   //--- Check bar-age gate: use iBarShift to compute how many H4 bars have passed
   int age_bars = iBarShift(_Symbol, PERIOD_H4, open_time, false);

   bool should_exit = (profit_pips >= InpHTpMinPips) || (age_bars > InpHMaxAgeBars);
   if(!should_exit) return;

   //--- Phase-1 stub: log intent — m_risk.CloseOrder(ticket) wires at <closed; ref purged fix-round-18 §18.1>
   //    Observable milestone for E-AC [log-assertion] when wired.
   if(m_logger != NULL)
      m_logger.Info("Slot_H", "exit_profit_gate", MAGIC_H,
                    StringFormat("ticket=%I64u profit_pips=%.1f age=%d",
                                 ticket, profit_pips, age_bars));
  }

//+------------------------------------------------------------------+
//| ManageExits — exit pass (BR-2.2: runs before Evaluate)           |
//| Uses canonical PortfolioState.GetTicketsForSlot per ADR-005 +    |
//| ADR-012 (slot data goes through the central choke point).        |
//+------------------------------------------------------------------+
void CSlotH::ManageExits(CPortfolioState &port)
  {
   if(!InpEnableSlotH) return;

   //--- Retrieve H tickets (own magic MAGIC_H=205, comment prefix "H,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_H, "H,", tickets);
   if(n <= 0) return;

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];
      if(!PositionSelectByTicket(ticket)) continue;

      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      datetime           open_time  = (datetime)PositionGetInteger(POSITION_TIME);
      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      _TryExit(ticket, open_price, open_time, pos_type);
     }
  }

//+------------------------------------------------------------------+
//| Evaluate — entry pass (FR-2.3; only in RUNNING state)            |
//| M-size MVP: 4 conditions only (CodeWiki §3.4 conditions 1-4)      |
//+------------------------------------------------------------------+
void CSlotH::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotH) return;

   //--- Condition 1: max orders guard
   if(_CountHOrders(port) >= InpHMaxOrders) return;

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

   //--- Submit order via RiskManager wrapper (ea.md: ALL CTrade calls
   //    through RiskManager — slots ห้าม instantiate CTrade ตรง).
   //    Phase-1 stub: log intent only; m_risk.OpenOrderH(...) wires at <closed; ref purged fix-round-18 §18.1>.
   //    SL is computed (not naked 0) so when wiring lands the stop-loss is
   //    threaded into OrderSend; mirrors 17 sibling slots (e.g. Slot_B sl_price).
   ENUM_ORDER_TYPE order_type = is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   string comment_str = "H,fractal,1";

   //--- Pip size via base-class helper (Round-06 06.1).
   //    sl_price wrapped with _NormalizeBrokerPrice (Round-06 06.3) — broker
   //    rejects sub-tick precision with TRADE_RETCODE_INVALID_STOPS (10016).
   double pip_size = _PipSize();
   double price    = is_buy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                            : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl_price = is_buy
                     ? _NormalizeBrokerPrice(price - InpHSlPips * pip_size)
                     : _NormalizeBrokerPrice(price + InpHSlPips * pip_size);

   if(m_logger != NULL)
      m_logger.Info("Slot_H", is_buy ? "entry_buy" : "entry_sell", MAGIC_H,
                    StringFormat("lot=%.2f price=%.5f sl=%.5f bar=%d comment=%s",
                                 lot, price, sl_price, ctx.bar_index_h4, comment_str));

   //--- Update cooldown bar — prevents re-entry on same H4 bar even when
   //    OrderSend wiring lands and the actual broker call may fail. Same
   //    semantic as updating m_last_order_d1_time after intent log in Slot_K.
   m_last_bar_entered = ctx.bar_index_h4;
  }

#endif // PHOENICISNEX_SLOTS_SLOT_H_MQH
