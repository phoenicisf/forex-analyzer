//+------------------------------------------------------------------+
//| slots/Slot_BI.mqh โ€” Slot BI derived class (IMPL-039)              |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   214 (MAGIC_B per domain/EnumTypes.mqh; shared with B)    |
//| SlotId:  "BI"                                                     |
//| Comment: "BI,pyr,1"                                               |
//|                                                                  |
//| Source:  CodeWiki ยง3.19 Slot BI (pyramid child of B)              |
//|          ADR-009 (โ ๏ธ G4 critical SL inheritance fix)              |
//|          TD-02 ยง5.4 (lot dispatch RiskManager::ComputeLot)         |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency โ€” เธซเนเธฒเธก #include slots/*)        |
//|                                                                  |
//| โ ๏ธ G4 critical fix per ADR-009 โ€” Bucket B drift (NFR-1.8):         |
//|   PhoenicisN2.10 baseline (CodeWiki ยง6.2 :20326 :20357) opened    |
//|   BI orders with naked SL=0 โ’ unbounded downside on adverse move. |
//|   This rewrite restores the contract: SL inherited from parent B's|
//|   pip distance applied at BI entry price (Option A โ€” earliest     |
//|   B parent ticket = base risk anchor). Edge cases per ADR-009:    |
//|     - No B parent active     โ’ fallback InpBISlFallbackPips        |
//|     - Parent SL == 0 (legacy)โ’ fallback InpBISlFallbackPips        |
//|     - Direction-flip vs B    โ’ MathAbs + sign by BI direction      |
//|     - 5-digit precision      โ’ CPipMath m_pip via _PipsToPrice()   |
//|                                                                  |
//| Pyramid logic (L-size MVP โ€” mirrors Slot_LX precedent):           |
//|   1. Own-no-active guard via GetTicketsForSlot(MAGIC_B,"BI,",...) |
//|   2. Parent B gate: GetTicketsForSlot(MAGIC_B,"B,",parent_tickets)|
//|      โ€” must have โฅ 1 parent B position ("B," prefix, NOT "BI,")  |
//|      "BI,..." does NOT start with "B," (StringFind mismatches at  |
//|      index 1 โ€” ',' vs 'I') so prefix filter is correct.           |
//|   3. Select earliest B parent (parent_tickets[0]) per ADR-009     |
//|      anchor semantic; compute parent SL pip distance.             |
//|   4. Pyramid gate: parent B profit_pips >= InpBIPyramidGatePips   |
//|   5. Direction inheritance: same direction as profitable B parent |
//|   6. SL inheritance: bi_entry_price ยฑ sl_distance_price per ADR-9 |
//|                                                                  |
//| Comment-prefix disambiguation ("BI," vs "B,"):                   |
//|   MAGIC_B (214) is shared between B and BI. PortfolioState uses   |
//|   CommentParser prefix filtering (per IMPL-008) to separate them: |
//|   - GetTicketsForSlot(214, "B,",  ...) โ’ parent B orders only     |
//|   - GetTicketsForSlot(214, "BI,", ...) โ’ own BI pyramid orders    |
//|   Same precedent as Slot_LX vs Slot_L (IMPL-031).                |
//|                                                                  |
//| DependsOn() returns 0: BI depends on B's *runtime state* queried  |
//|   via PortfolioState โ€” NOT a topology dependency. Same precedent  |
//|   as Slot_LX (IMPL-031) + Slot_G2 (IMPL-026).                    |
//|                                                                  |
//| Spec deviation note (IMPL-039 S-AC #3 vs ADR-009):                |
//|   S-AC text reads "OrderSend SL parameter = parent B's open price |
//|   ยฑ m_pip.ToPoints(parent_sl_pip) per direction" โ€” but ADR-009    |
//|   Option A locks BI.sl = BI.entry_price ยฑ sl_distance_price       |
//|   (anchored at BI's own entry, not parent's open). Implementation |
//|   follows ADR-009 (architectural primary). Pip arithmetic uses    |
//|   _PipsToPrice() (CSlotBase helper, Round-06 06.1) which routes   |
//|   through CPipMath when wired or canonical 5/3-digit fallback.    |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - ADR-009 Bollinger fallback (BBBot โ’ 10 / BBTop + 10) โ€” needs  |
//|     M15 BB indicator in MarketContext (MVP fallback = pip floor).  |
//|   - signal_context journal field "sl_inherit=B_parent_<ticket>"   |
//|     โ€” needs Orchestrator wiring path (core/Orchestrator.mqh) TradeJournal write wiring.                  |
//|   - Multi-level pyramid (> 1 BI add-on layer)                     |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_BI_MQH
#define PHOENICISNEX_SLOTS_SLOT_BI_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_BI.mqh"

//+------------------------------------------------------------------+
//| CSlotBI โ€” Slot BI derived class (ADR-002 CSlotBase contract)      |
//|                                                                  |
//| Pyramid child of Slot B sharing MAGIC_B=214; comment prefix      |
//| "BI," in all OrderSend calls disambiguates from parent B "B,".   |
//| โ ๏ธ G4 SL inheritance fix per ADR-009 in Evaluate() entry path.   |
//+------------------------------------------------------------------+
class CSlotBI : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice` / `_PriceToPips` / `_PipSize` inherited from base.

   //--- Check whether BI already has active pyramid orders
   //    Uses "BI," prefix โ€” will NOT count parent B orders ("B,")
   bool              _HasActiveBIOrder(CPortfolioState &port) const
     {
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_B, "BI,", tickets);
      return n >= InpBIMaxOrders;
     }

   //--- Fetch parent B tickets (prefix "B," โ€” excludes own "BI,")
   //    StringFind("B,", "BI,...") returns -1 (mismatch at i=1: ',' vs 'I'),
   //    so prefix filter is correct under shared-magic CommentParser contract.
   int               _GetParentBTickets(CPortfolioState &port, ulong &out_tickets[]) const
     {
      return port.GetTicketsForSlot(MAGIC_B, "B,", out_tickets);
     }

   //--- Compute unrealized profit in pips for the currently selected position.
   //    Caller must call PositionSelectByTicket() before invoking.
   double            _SelectedProfitPips() const
     {
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_px  = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_px   = (pos_type == POSITION_TYPE_BUY)
                                    ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double price_diff = (pos_type == POSITION_TYPE_BUY)
                          ? (cur_px - open_px)
                          : (open_px - cur_px);
      return _PriceToPips(price_diff);
     }

public:
   //--- Constructor / Destructor
   CSlotBI() {}
   virtual          ~CSlotBI() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() โ€” returns MAGIC_B (214) per domain/EnumTypes.mqh
   //    Shared with parent B (IMPL-037); CommentParser "BI," disambig.
   virtual int       Magic() const override { return MAGIC_B; }

   //--- 2. SlotId() โ€” "BI"; used by journal `slot_id` field
   virtual string    SlotId() const override { return "BI"; }

   //--- 3. Evaluate() โ€” entry pass; called per tick by Orchestrator.
   //    โ ๏ธ G4 fix per ADR-009 โ€” SL inherited from parent B pip distance.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotBI)
         return;

      //--- Guard: service pointers must be wired (Composition Root via Init)
      if(m_risk == NULL || m_logger == NULL)
         return;

      //--- Own-no-active guard: skip if BI pyramid already open
      //    Uses "BI," prefix filter โ€” "B," parent orders are NOT counted.
      if(_HasActiveBIOrder(port))
         return;

      //--- Parent B gate: need โฅ 1 parent B position ("B," prefix only)
      ulong parent_tickets[];
      int parent_count = _GetParentBTickets(port, parent_tickets);
      if(parent_count <= 0)
         return;

      //--- Select earliest B parent (parent_tickets[0]) per ADR-009 Option A
      //    "earliest-opened B parent SL distance = base risk anchor"
      //    PortfolioState fills ticket_ids[] in registration order, which
      //    maps to broker open-time order under FIFO push semantics.
      ulong  parent_ticket = parent_tickets[0];
      if(!PositionSelectByTicket(parent_ticket))
         return;

      double parent_open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double parent_sl    = PositionGetDouble(POSITION_SL);
      double profit_pips  = _SelectedProfitPips();
      ENUM_POSITION_TYPE parent_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      //--- Pyramid gate: parent B must be profitable >= InpBIPyramidGatePips
      if(profit_pips < InpBIPyramidGatePips)
         return;

      //--- Direction inheritance: same direction as profitable B parent
      bool buy_signal = (parent_type == POSITION_TYPE_BUY);

      //--- Lot sizing via RiskManager (no direct CTrade โ€” ADR-002 rule)
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("BI", InpBISlFallbackPips, balance);
      if(lot <= 0.0)
        {
         m_logger.Warn("Slot_BI", "zero_lot_skip", MAGIC_B,
                       "ComputeLot returned 0 โ€” skipping BI pyramid entry");
         return;
        }

      //--- โ ๏ธ G4 fix ADR-009 โ€” SL inherited from parent B pip distance.
      //    sl_distance_pip = |parent_open โ’ parent_sl| in pips
      //    Edge case fallbacks (per ADR-009 ยง Edge case fallbacks):
      //      1. parent_sl == 0 (legacy pre-fix)        โ’ InpBISlFallbackPips
      //      2. computed sl_distance_pip == 0 (degen)  โ’ InpBISlFallbackPips
      //    Phase-1 MVP: Bollinger fallback (BBBot โ’ 10 / BBTop + 10) deferred
      //    to IMPL-062 since M15 BB indicator not yet in MarketContext;
      //    pip floor preserves the "non-zero SL" G4 contract until then.
      double sl_distance_pip = 0.0;
      string sl_inherit_tag  = "";
      if(parent_sl > 0.0)
        {
         sl_distance_pip = _PriceToPips(parent_open - parent_sl);
         sl_inherit_tag  = StringFormat("sl_inherit=B_parent_%I64u", parent_ticket);
        }
      if(sl_distance_pip <= 0.0)
        {
         sl_distance_pip = InpBISlFallbackPips;
         sl_inherit_tag  = "sl_inherit=fallback_pip_floor";
        }

      //--- BI entry price + SL anchored at BI entry per ADR-009 Option A.
      double bi_entry      = buy_signal ? ctx.ask : ctx.bid;
      double sl_distance   = _PipsToPrice(sl_distance_pip);
#ifdef DISABLE_G4_FIXES
      double sl_price      = 0.0;   // pre-G4 naked SL (Bucket A baseline; ADR-009 documents the fix โ€” original PhoenicisN2.10 had SL=0)
#else
      double sl_price      = buy_signal
                             ? _NormalizeBrokerPrice(bi_entry - sl_distance)
                             : _NormalizeBrokerPrice(bi_entry + sl_distance);   // G4 fix per ADR-009
#endif
      string comment       = "BI,pyr,1";

      //--- fix-round-17 ยง 17.1 โ€” attestation tag MUST follow active build
      //    branch so Bucket A regression journal records do not falsely
      //    attest "G4 fix ADR-009" while running the pre-G4 naked-SL path.
#ifdef DISABLE_G4_FIXES
      string g4_tag = "(Bucket A โ€” pre-G4 ADR-009 naked SL path)";
#else
      string g4_tag = "(G4 fix ADR-009)";
#endif

      //--- IMPL-FIX-003 Phase 1B (2026-05-12): wire RiskManager.OpenOrder
      //    per Phase 1A pattern (mirror Slot_K iter-18 + Slot_B iter-19).
      //    Slot_BI is the pyramid child of Slot_B (shared MAGIC_B=214,
      //    "BI," comment-prefix disambig). G4 fix ADR-009 Option A applies
      //    real SL (parent_pip distance) per active build branch above.
      ENUM_ORDER_TYPE order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      MqlTradeRequest req = {};
      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = order_type;
      req.price        = _NormalizeBrokerPrice(bi_entry);
      req.sl           = sl_price;
      req.tp           = 0.0;
      req.comment      = comment;
      req.magic        = MAGIC_B;
      req.type_filling = ORDER_FILLING_FOK;

      m_risk.OpenOrder(req, "BI");
     }

   //--- 4. ManageExits() โ€” exit pass; runs in BOTH RUNNING and HALTED (ADR-010)
   //    Iterates own "BI," orders only via GetTicketsForSlot disambig (Slot B
   //    refrains from touching BI tickets per Slot_B.mqh ยง ManageExits note).
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotBI)
         return;
      if(m_logger == NULL)
         return;

      //--- Retrieve BI pyramid tickets via "BI," prefix โ€” "B," orders excluded
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_B, "BI,", tickets);
      if(n <= 0)
         return;

      for(int i = 0; i < n; i++)
        {
         ulong ticket = tickets[i];
         if(!PositionSelectByTicket(ticket))
            continue;

         double profit_pips = _SelectedProfitPips();

         //--- Exit condition: BI pyramid profit >= InpBITpProfitPips (30 pip)
         //--- IMPL-FIX-003 Phase 1B (2026-05-12): wire RiskManager.CloseOrder
         //    (mirror Slot_K iter-18 OpenOrder pattern, exit-side symmetric).
         if(profit_pips >= InpBITpProfitPips)
           {
            if(m_risk != NULL)
               m_risk.CloseOrder(ticket, "BI");
           }
        }
     }

   //--- 5. DependsOn() โ€” BI depends on B's runtime state via PortfolioState query
   //    Not a topology dependency โ€” CommentParser disambig is internal.
   //    Same precedent as Slot_LX (IMPL-031) + Slot_G2 (IMPL-026).
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() โ€” BI does not use pending sub-flow (IDLE default)
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_BI_MQH
