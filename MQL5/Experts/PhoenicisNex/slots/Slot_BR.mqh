//+------------------------------------------------------------------+
//| slots/Slot_BR.mqh โ€” Slot BR implementation (IMPL-038)             |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_BR = 215 (own โ€” not shared)                        |
//|          Comment prefix "BR," in all OrderSend calls              |
//| Source:  CodeWiki ยง3.18 Slot BR; BR-2.2; TD-02 ยง5.4;              |
//|          ADR-002; ADR-012                                         |
//|                                                                  |
//| S-size MVP โ€” header-only contract scaffold:                       |
//|   BR is an orphan exit-only spawn invoked sub-call only from      |
//|   ExtraTakeProfit_B (Slot_B ManageExits) when a B parent closes.  |
//|   Not iterated in main OnTick slot topology โ€” Evaluate() early-   |
//|   returns (sub-call only guard). ManageExits: profit-gate close   |
//|   pattern mirroring Slot_GO.                                       |
//|                                                                  |
//| Activation: Orchestrator wiring path (core/Orchestrator.mqh) (CrossSlotCoordinator wires Slot_B's        |
//|   ManageExits BR-trigger stub `false /*IMPL-053*/` โ’ TriggerBR    |
//|   โ’ BusinessLogic_BR equivalent on this slot).                    |
//|                                                                  |
//| Exit (ManageExits):                                               |
//|   - Profit gate โฅ InpBRTpProfitPips (40 pip default)              |
//|                                                                  |
//| DependsOn() returns 0 โ€” sub-call activation is runtime, not topo: |
//|   Slot_B (parent) has its own DependsOn=0; BR depends ON B by     |
//|   semantic but is invoked via CrossSlotCoordinator, not via the   |
//|   Orchestrator's topo-sorted main pass. Same precedent as Slot_GO.|
//|                                                                  |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_BR_MQH
#define PHOENICISNEX_SLOTS_SLOT_BR_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_BR.mqh"

//+------------------------------------------------------------------+
//| CSlotBR โ€” Slot BR derived class (ADR-002 CSlotBase contract)      |
//|                                                                   |
//| Orphan exit-only spawn role: activated sub-call only from         |
//| Slot_B ExtraTakeProfit_B โ’ CrossSlotCoordinator::TriggerBR        |
//| (BR-2.2). Own magic MAGIC_BR=215; comment prefix "BR," in all     |
//| OrderSend calls (no shared-magic ambiguity with B/BI MAGIC_B=214).|
//|                                                                   |
//| Not iterated in main OnTick slot topology: Evaluate() guards      |
//| sub-call-only activation and early-returns in Phase 1 MVP.        |
//+------------------------------------------------------------------+
class CSlotBR : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` inherited from base (returns pips * pip_size).
   //    Local signed helper for ManageExits price-diff conversion.
   double            _PriceDiffToPips(double price_diff) const
     {
      return price_diff / _PipSize();
     }

   //--- Count open BR orders via PortfolioState comment-prefix filter
   //    MAGIC_BR=215 is own (not shared); "BR," prefix is unambiguous.
   //    Returns int (count) so the caller can compare against InpBRMaxOrders;
   //    a bool collapse would silently cap at 1 regardless of operator input.
   int               _CountBROrders(CPortfolioState &port) const
     {
      ulong tickets[];
      return port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
     }

public:
   //--- Constructor / Destructor
   CSlotBR() {}
   virtual          ~CSlotBR() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic โ€” MAGIC_BR = 215 (own; not shared with any other slot)
   virtual int       Magic() const override { return MAGIC_BR; }

   //--- 2. SlotId โ€” "BR"; used by journal slot_id field + comment prefix
   virtual string    SlotId() const override { return "BR"; }

   //--- 3. Evaluate โ€” sub-call only (not in main topo); early-return guard
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void      ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” BR is independent in topology (sub-call activation runtime)
   //    Same precedent as Slot_GO: the runtime dep on parent B is via
   //    CrossSlotCoordinator, not the Orchestrator's topo-sorted main pass.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState โ€” BR uses IDLE default (not in pending-flow list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot BR entry pass (sub-call only; early-return guard) |
//|                                                                   |
//| Phase 1 MVP: BR is invoked sub-call only from Slot_B ManageExits  |
//| BR-trigger stub (`false /*IMPL-053*/` at Slot_B.mqh). This method |
//| is NOT called from the main OnTick slot topo. The body early-     |
//| returns until IMPL-053 activates Slot_B โ’ CrossSlotCoordinator โ’ |
//| TriggerBR โ’ BusinessLogic_BR equivalent.                          |
//|                                                                   |
//| When IMPL-053 activates:                                          |
//|   - Signal arrives from CrossSlotCoordinator (B-close orphan)     |
//|   - Entry: own-active guard + lot/SL compute + log intent         |
//|   - Comment prefix "BR," for all OrderSend calls                  |
//+------------------------------------------------------------------+
void CSlotBR::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   //--- Sub-call guard: early-return when not enabled or service not wired
   //    (Phase 1 MVP โ€” real signal arrives from TriggerBR at Orchestrator wiring path (core/Orchestrator.mqh))
   if(!InpEnableSlotBR) return;
   if(m_logger == NULL) return;

   //--- Own-active guard: max InpBRMaxOrders BR orders simultaneously
   if(_CountBROrders(port) >= InpBRMaxOrders) return;

   //--- Phase-1 stub: no entry signal in main topo โ€” TriggerBR sub-call
   //    wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).
   //    Observable milestone for E-AC [log-assertion] once that wires:
   //
   //    double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double lot      = m_risk.ComputeLot("BR", InpBRSlPipsFloor, balance);
   //    string comment  = "BR,orphan,1";
   //    m_logger.Info("SlotBR", "entry_signal", MAGIC_BR,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s",
   //                               lot, InpBRSlPipsFloor, comment));
   //
   //--- CrossSlotCoordinator stub: coupling from B โ’ BR sub-call
   if(m_xslot != NULL && false /* enable when TriggerBR wired per BR-2.2 (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: BR activation from B's ExtraTakeProfit_B
      //    wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot BR exit pass (profit-gate close; 40 pip MVP)   |
//|                                                                   |
//| Exit logic (MVP, mirroring Slot_GO pattern):                      |
//|   1. Iterate BR positions via GetTicketsForSlot(MAGIC_BR, "BR,")  |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate โฅ InpBRTpProfitPips (40 pip default) โ’ close     |
//+------------------------------------------------------------------+
void CSlotBR::ManageExits(CPortfolioState &port)
  {
   if(!InpEnableSlotBR) return;
   if(m_logger == NULL) return;

   //--- Retrieve BR tickets (own magic MAGIC_BR=215, comment prefix "BR,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
   if(n <= 0) return;

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double price_diff = (pos_type == POSITION_TYPE_BUY) ?
                          (cur_price - open_price) :
                          (open_price - cur_price);
      double profit_pips = _PriceDiffToPips(price_diff);

      //--- Profit gate: โฅ InpBRTpProfitPips (40 pip default โ€” orphan tier)
      if(profit_pips >= InpBRTpProfitPips)
        {
         m_logger.Info("SlotBR", "exit_profit_gate", MAGIC_BR,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f -> close",
                                    ticket, profit_pips, InpBRTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_BR_MQH
