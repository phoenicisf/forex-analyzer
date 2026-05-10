//+------------------------------------------------------------------+
//| slots/Slot_GO.mqh โ€” Slot GO implementation (IMPL-027)             |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_GO = 209 (own โ€” not shared)                        |
//|          Comment prefix "GO," in all OrderSend calls              |
//| Source:  CodeWiki ยง3.GO; TD-02 ยง5.4; ADR-002; ADR-012            |
//|                                                                   |
//| S-size MVP โ€” header-only contract scaffold:                       |
//|   GO is a post-exit hook invoked sub-call only from G's           |
//|   TriggerGOverload (BR-2.2). It is NOT iterated in main OnTick   |
//|   slot topology. Evaluate() early-returns (sub-call only guard).  |
//|   ManageExits: profit-gate close pattern mirroring Slot_G2.       |
//|                                                                   |
//| Activation: Orchestrator wiring path (core/Orchestrator.mqh) (CrossSlotCoordinator wires G โ’ GO call)   |
//|   Slot_G.mqh — grep marker "IMPL-053: enable when TriggerGOverload  |
//|   declared"; TriggerGOverload currently stubbed false.            |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate โฅ InpGOTpProfitPips (40 pip default)             |
//|   Stub: if(m_xslot != NULL && false /*IMPL-053*/) {...}           |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("GO", InpGOSlPipsFloor, balance)    |
//| Comment: "GO," prefix per CodeWiki ยง3.GO                          |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_GO_MQH
#define PHOENICISNEX_SLOTS_SLOT_GO_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_GO.mqh"

//+------------------------------------------------------------------+
//| CSlotGO โ€” Slot GO derived class (ADR-002 CSlotBase contract)      |
//|                                                                   |
//| Post-exit hook role: activated sub-call only from G's             |
//| TriggerGOverload (BR-2.2). Own magic MAGIC_GO=209; comment        |
//| prefix "GO," in all OrderSend calls (no shared-magic ambiguity). |
//|                                                                   |
//| Not iterated in main OnTick slot topology: Evaluate() guards      |
//| sub-call-only activation and early-returns in Phase 1 MVP.        |
//+------------------------------------------------------------------+
class CSlotGO : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveGOOrder(CPortfolioState &port) const;

public:
   //--- Constructor / Destructor
   CSlotGO() {}
   virtual ~CSlotGO() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_GO = 209 (own; not shared with any other slot)
   virtual int       Magic() const override { return MAGIC_GO; }

   //--- 2. SlotId โ€” "GO"; used by journal slot_id field + comment prefix
   virtual string    SlotId() const override { return "GO"; }

   //--- 3. Evaluate โ€” sub-call only (not in main topo); early-return guard in Phase 1 MVP
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void      ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” GO is independent in topology (sub-call activation is runtime, not topo dep)
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState โ€” GO uses IDLE default (not in pending-flow list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _HasActiveGOOrder โ€” check for open GO orders via PortfolioState   |
//| Uses GetTicketsForSlot(MAGIC_GO, "GO,", tickets[]) โ€” own magic    |
//+------------------------------------------------------------------+
bool CSlotGO::_HasActiveGOOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_GO, "GO,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot GO entry pass (sub-call only; early-return guard) |
//|                                                                   |
//| Phase 1 MVP: GO is invoked sub-call only from G's TriggerGOverload|
//| (BR-2.2, currently stubbed false at Slot_G.mqh — grep marker     |
//| "IMPL-053: enable when TriggerGOverload declared"). This method  |
//| is NOT called from the main OnTick slot topo. The body early-     |
//| returns until IMPL-053 activates TriggerGOverload โ’ GO call.     |
//|                                                                   |
//| When IMPL-053 activates:                                          |
//|   - Signal arrives from G's TriggerGOverload (overload echo)      |
//|   - Entry: own-active guard + lot/SL compute + log intent         |
//|   - Comment prefix "GO," for all OrderSend calls                  |
//+------------------------------------------------------------------+
void CSlotGO::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   //--- Sub-call guard: early-return when not enabled or service not wired
   //    (Phase 1 MVP โ€” real signal arrives from TriggerGOverload at Orchestrator wiring path (core/Orchestrator.mqh))
   if(!InpEnableSlotGO) return;
   if(m_logger == NULL) return;

   //--- Own-active guard: max 1 GO order per InpGOMaxOrders
   if(_HasActiveGOOrder(port)) return;

   //--- Phase-1 stub: no entry signal in main topo โ€” TriggerGOverload sub-call
   //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
   //    Observable milestone for E-AC [log-assertion] once that wires:
   //
   //    double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double lot      = m_risk.ComputeLot("GO", InpGOSlPipsFloor, balance);
   //    string comment  = "GO,OL,N,1,SL";
   //    m_logger.Info("SlotGO", "entry_signal", MAGIC_GO,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s", lot, InpGOSlPipsFloor, comment));
   //
   //--- CrossSlotCoordinator stub: coupling from G โ’ GO sub-call
   if(m_xslot != NULL && false /* enable when TriggerGOverload wired (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: GO activation from G's TriggerGOverload
      //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot GO exit pass (profit-gate close; 40 pip MVP)   |
//|                                                                   |
//| Exit logic (MVP, mirroring Slot_G2 pattern):                      |
//|   1. Iterate GO positions via GetTicketsForSlot(MAGIC_GO, "GO,")  |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate โฅ InpGOTpProfitPips (40 pip default) โ’ close    |
//+------------------------------------------------------------------+
void CSlotGO::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve GO tickets (own magic MAGIC_GO=209, comment prefix "GO,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_GO, "GO,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

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
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Profit gate: โฅ InpGOTpProfitPips (40 pip default โ€” between G's 50 and G2's 30)
      if(profit_pips >= InpGOTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotGO", "exit_profit_gate", MAGIC_GO,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
//                                     ticket, profit_pips, InpGOTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub โ€” deferred (IMPL-053)
      if(m_xslot != NULL && false /*IMPL-053*/)
        {
         //--- Stub: any GO peak-based cross-slot coupling goes here (IMPL-053)
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_GO_MQH
