//+------------------------------------------------------------------+
//| slots/Slot_LX.mqh — Slot LX derived class (IMPL-031)             |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   211 (MAGIC_L per domain/EnumTypes.mqh; shared with L)    |
//| SlotId:  "LX"                                                     |
//| Comment: "LX,pyr,1"                                               |
//|                                                                  |
//| Source:  CodeWiki §3.L (pyramid-on-profitable variant)            |
//|          TD-02 §5.4 (lot dispatch RiskManager::ComputeLot)         |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency — ห้าม #include slots/*)        |
//|                                                                  |
//| Pyramid logic (IMPL-031 MVP):                                     |
//|   1. Own-no-active guard via GetTicketsForSlot(MAGIC_L,"LX,",...) |
//|      — own LX count < InpLXMaxOrders required                     |
//|   2. Parent L gate: GetTicketsForSlot(MAGIC_L,"L,",parent_tickets)|
//|      — must have ≥ 1 parent L position ("L," prefix, NOT "LX,")  |
//|   3. Select first L parent: PositionSelectByTicket(parent[0])     |
//|      → compute profit_pips; pyramid only if >= InpLXPyramidGatePips|
//|   4. Direction inheritance: same direction as profitable L parent  |
//|      (BUY parent → BUY pyramid; SELL parent → SELL pyramid)       |
//|                                                                  |
//| Comment-prefix disambiguation ("LX," vs "L,"):                   |
//|   MAGIC_L (211) is shared between L and LX. PortfolioState uses   |
//|   CommentParser prefix filtering (per IMPL-008) to separate them: |
//|   - GetTicketsForSlot(211, "L,",  ...) → parent L orders only     |
//|   - GetTicketsForSlot(211, "LX,", ...) → own LX pyramid orders    |
//|   All LX OrderSend calls use comment prefix "LX,..." to guarantee |
//|   correct separation. ManageExits iterates "LX," prefix only via  |
//|   the same GetTicketsForSlot API (NOT raw order iteration).        |
//|                                                                  |
//| DependsOn() returns 0: LX depends on L's *runtime state* queried  |
//|   via PortfolioState — NOT a topology dependency. CommentParser    |
//|   disambig is internal. Same precedent as G2 vs G (IMPL-026).     |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - Multi-level pyramid (> 1 add-on layer)                        |
//|   - Advanced pyramid scaling conditions                            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_LX_MQH
#define PHOENICISNEX_SLOTS_SLOT_LX_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_LX.mqh"

//+------------------------------------------------------------------+
//| CSlotLX — Slot LX derived class (ADR-002 CSlotBase contract)      |
//|                                                                  |
//| Pyramid role: enters a pyramid order when a parent L position     |
//| (comment "L,") is sufficiently profitable. Both share MAGIC_L     |
//| (211); comment prefix "LX," in all OrderSend calls distinguishes  |
//| LX pyramids from L parent orders via CommentParser (IMPL-008).    |
//|                                                                  |
//| GetTicketsForSlot(211, "LX,", tickets) filters own LX orders.     |
//| GetTicketsForSlot(211, "L,",  tickets) reads parent L orders.     |
//+------------------------------------------------------------------+
class CSlotLX : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` and `_PipSize()` inherited from base.

   //--- Check whether LX already has active pyramid orders
   //    Uses "LX," prefix — will NOT count parent L orders ("L,")
   bool              _HasActiveLXOrder(CPortfolioState &port) const
     {
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_L, "LX,", tickets);
      return n >= InpLXMaxOrders;
     }

   //--- Fetch parent L tickets (prefix "L," — excludes own "LX,")
   int               _GetParentLTickets(CPortfolioState &port, ulong &out_tickets[]) const
     {
      return port.GetTicketsForSlot(MAGIC_L, "L,", out_tickets);
     }

   //--- Compute unrealized profit in pips for a selected position
   //    Caller must call PositionSelectByTicket() before invoking this.
   double            _PositionProfitPips() const
     {
      ENUM_POSITION_TYPE pos_type  = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_px   = PositionGetDouble(POSITION_PRICE_OPEN);
      double             pip_sz    = _PipSize();

      double cur_px = (pos_type == POSITION_TYPE_BUY)
                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double profit_pips = (pos_type == POSITION_TYPE_BUY)
                           ? (cur_px - open_px) / pip_sz
                           : (open_px - cur_px) / pip_sz;
      return profit_pips;
     }

public:
   //--- Constructor / Destructor
   CSlotLX() {}
   virtual          ~CSlotLX() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() — returns MAGIC_L (211) per domain/EnumTypes.mqh
   //    Shared with parent L (IMPL-030); CommentParser "LX," disambig.
   virtual int       Magic() const override { return MAGIC_L; }

   //--- 2. SlotId() — "LX"; used by journal `slot_id` field
   virtual string    SlotId() const override { return "LX"; }

   //--- 3. Evaluate() — entry pass; called per tick by Orchestrator
   //    Pyramid gate: parent L profitable >= InpLXPyramidGatePips.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotLX)
         return;

      //--- Guard: service pointers must be wired (Composition Root via Init)
      if(m_risk == NULL || m_logger == NULL)
         return;

      //--- Own-no-active guard: skip if LX pyramid already open
      //    Uses "LX," prefix filter — "L," orders are NOT counted here
      if(_HasActiveLXOrder(port))
         return;

      //--- Parent L gate: need ≥ 1 parent L position ("L," prefix only)
      ulong parent_tickets[];
      int parent_count = _GetParentLTickets(port, parent_tickets);
      if(parent_count <= 0)
         return;

      //--- Select first parent L position; compute its unrealized profit
      if(!PositionSelectByTicket(parent_tickets[0]))
         return;

      double profit_pips = _PositionProfitPips();

      //--- Pyramid gate: parent L must be profitable >= InpLXPyramidGatePips
      if(profit_pips < InpLXPyramidGatePips)
         return;

      //--- Direction inheritance: same direction as profitable L parent
      ENUM_POSITION_TYPE parent_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      bool buy_signal  = (parent_type == POSITION_TYPE_BUY);
      bool sell_signal = (parent_type == POSITION_TYPE_SELL);

      //--- Lot sizing via RiskManager (no direct CTrade — ADR-002 rule)
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("LX", InpLXSlPips, balance);
      if(lot <= 0.0)
        {
         m_logger.Warn("Slot_LX", "zero_lot_skip", MAGIC_L,
                       "ComputeLot returned 0 — skipping LX pyramid entry");
         return;
        }

      //--- Build order parameters (direction matches parent L)
      int              digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double           pip_sz   = _PipSize();
      double           price    = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist  = InpLXSlPips * pip_sz;
      double           sl_price = buy_signal
                                  ? NormalizeDouble(price - sl_dist, digits)
                                  : NormalizeDouble(price + sl_dist, digits);
      string           comment  = "LX,pyr,1";

      //--- Phase-1 stub: OrderSend deferred to IMPL-053+ orchestrator wiring.
      //    Log intent — observable milestone for E-AC [log-assertion].
      m_logger.Info("Slot_LX", buy_signal ? "entry_pyramid_buy" : "entry_pyramid_sell",
                    MAGIC_L,
                    StringFormat("parent_ticket=%I64u parent_profit_pips=%.1f "
                                 "dir=%s lot=%.2f price=%.5f sl=%.5f comment=%s",
                                 parent_tickets[0], profit_pips,
                                 (buy_signal ? "BUY" : "SELL"),
                                 lot, price, sl_price, comment));

      //--- CrossSlotCoordinator stub (IMPL-053)
      if(m_xslot != NULL && false /*IMPL-053: enable when CrossSlotCoordinator declared*/)
        {
         //--- Stub: LX pyramid coupling deferred to IMPL-053
        }
     }

   //--- 4. ManageExits() — exit pass; runs in BOTH RUNNING and HALTED (ADR-010)
   //    Iterates own "LX," orders only via GetTicketsForSlot disambig.
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotLX)
         return;
      if(m_logger == NULL)
         return;

      //--- Retrieve LX pyramid tickets via "LX," prefix — "L," orders excluded
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_L, "LX,", tickets);
      if(n <= 0)
         return;

      double pip_sz = _PipSize();

      for(int i = 0; i < n; i++)
        {
         ulong ticket = tickets[i];
         if(!PositionSelectByTicket(ticket))
            continue;

         double profit_pips = _PositionProfitPips();

         //--- Exit condition: pyramid profit >= InpLXTpProfitPips (25 pip default)
         if(profit_pips >= InpLXTpProfitPips)
           {
            string pos_comment = PositionGetString(POSITION_COMMENT);
            m_logger.Info("Slot_LX", "exit_profit_gate", MAGIC_L,
                          StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f "
                                       "comment=%s → close",
                                       ticket, profit_pips, InpLXTpProfitPips,
                                       pos_comment));

            //--- Phase-1 stub: OrderSend close deferred to IMPL-053+
           }
        }
     }

   //--- 5. DependsOn() — LX depends on L's *runtime state* via PortfolioState query
   //    Not a topology dependency — CommentParser disambig is internal (same as G2).
   //    Returns 0 (independent topology) per MVP guidance in parallel context §3.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() — LX does not use pending sub-flow (IDLE default)
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_LX_MQH
