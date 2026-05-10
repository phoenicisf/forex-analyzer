//+------------------------------------------------------------------+
//| slots/Slot_F.mqh โ€” Slot F implementation (IMPL-021)               |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_F = 201 (own; not shared)                          |
//|          Comment prefix "F," in all OrderSend calls               |
//| Source:  CodeWiki ยง5.3 OpenOrderCD chain to BusinessLogic_F;      |
//|          BR-2.1 (CD chain) + BR-2.2 (sub-call dispatch);          |
//|          ADR-002; ADR-012                                         |
//|                                                                   |
//| S-size MVP โ€” header-only contract scaffold:                       |
//|   Slot F is a sub-call slot chained from CD per BR-2.1/2.2.       |
//|   Legacy `OpenOrderCD(type,lot,comment,isFOff=false)` (CodeWiki  |
//|   :14185) chains `BusinessLogic_F` whenever isFOff==false โ€” i.e. |
//|   F runs immediately after a CD entry opens, not on every tick.   |
//|   Slot F is NOT iterated in the main OnTick slot topology;        |
//|   Evaluate() guards sub-call-only activation and early-returns.   |
//|                                                                   |
//| Activation: Orchestrator wiring path (core/Orchestrator.mqh) (CrossSlotCoordinator wires CD-open โ’       |
//|   BusinessLogic_F sub-call). Until then Evaluate() is a no-op     |
//|   beyond enable + service-wired guards (mirrors Slot_GO pattern). |
//|                                                                   |
//| Topology dep (DependsOn): returns [MAGIC_CD] so the Orchestrator  |
//|   topo-sort places F after CD in OnTick order โ€” even though the  |
//|   real invocation is sub-call from CD, declaring the dep keeps    |
//|   slot ordering deterministic and lets future iterators that      |
//|   expect "after CD" assumptions hold.                             |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate โฅ InpFTpProfitPips (40 pip default; same tier    |
//|     as C/D for symmetry โ€” CodeWiki ยง5.3 OpenOrder F-flag matches |
//|     the CD lot-reduction ร— 0.7 tier)                              |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("F", InpFSlPipsFloor, balance) *     |
//|      InpFLotReductionRatio (0.7 โ€” CodeWiki ยง5.3 F-flag tier)      |
//| Comment: "F,FP,N,1,SL" reserved per CodeWiki ยง5.3 dispatcher tag  |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh" โ€” F เธซเนเธฒเธก #include Slot_C/D.mqh |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected via Init)  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_F_MQH
#define PHOENICISNEX_SLOTS_SLOT_F_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_F.mqh"

//+------------------------------------------------------------------+
//| CSlotF โ€” Slot F derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| CD-chain sub-call slot per BR-2.1/2.2: invoked sub-call only from |
//| OpenOrderCD when isFOff==false. Own magic MAGIC_F=201; comment    |
//| prefix "F," in all OrderSend calls (no shared-magic ambiguity).   |
//+------------------------------------------------------------------+
class CSlotF : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveFOrder(CPortfolioState &port) const;

public:
   //--- Constructor / Destructor
   CSlotF() {}
   virtual ~CSlotF() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_F = 201 (own; not shared with any other slot)
   virtual int           Magic()  const override { return MAGIC_F; }

   //--- 2. SlotId โ€” "F"; journal slot_id field + comment prefix "F,"
   virtual string        SlotId() const override { return "F"; }

   //--- 3. Evaluate โ€” sub-call only (chained from CD per BR-2.1/2.2);
   //       early-return guard in Phase 1 MVP (real activation Orchestrator wiring path (core/Orchestrator.mqh))
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” F chains from CD (topo dep on MAGIC_CD)
   //       Sub-call activation is runtime, but topo order also keeps F
   //       after CD for deterministic per-tick slot iteration.
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_CD;
      return 1;
     }

   //--- 6. PendingState โ€” F is not a pending-flow slot; IDLE default
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _HasActiveFOrder โ€” check for open F orders via PortfolioState     |
//| Uses GetTicketsForSlot(MAGIC_F, "F,", tickets[]) โ€” own magic       |
//+------------------------------------------------------------------+
bool CSlotF::_HasActiveFOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_F, "F,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot F entry pass (sub-call only; early-return guard)  |
//|                                                                   |
//| Phase 1 MVP: F is invoked sub-call only from OpenOrderCD's chain  |
//| (CodeWiki ยง5.3 :14185 โ€” "chains BusinessLogic_F if isFOff==false")|
//| not from main OnTick topo. The body early-returns until Orchestrator wiring path (core/Orchestrator.mqh) |
//| activates the CrossSlotCoordinator wiring that calls F.Evaluate   |
//| right after CD entry execution.                                   |
//|                                                                   |
//| When IMPL-053 activates:                                          |
//|   - CD entry signal triggers OpenOrderCD with isFOff=false        |
//|   - Coordinator invokes F.Evaluate (sub-call) with same MarketCtx |
//|   - F entry: own-active guard + lot/SL compute (ร— 0.7 reduction   |
//|     vs CD parent per CodeWiki ยง5.3 F-flag dispatcher tier)        |
//|   - Comment prefix "F," for all OrderSend calls                   |
//+------------------------------------------------------------------+
void CSlotF::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   //--- Sub-call guard: early-return when not enabled or service not wired
   //    (Phase 1 MVP โ€” real signal arrives via OpenOrderCD chain at Orchestrator wiring path (core/Orchestrator.mqh))
   if(!InpEnableSlotF) return;
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Own-active guard: max 1 F order at a time per InpFMaxOrders
   if(_HasActiveFOrder(port)) return;

   //--- Phase-1 stub: no entry signal in main topo โ€”
   //    OpenOrderCD (CD-chain) sub-call wires through core/Orchestrator.mqh
   //    (cross-slot coupling per ea.md) via CrossSlotCoordinator.
   //    Observable E-AC milestone for [log-assertion] once that wires:
   //
   //    double balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double base_lot = m_risk.ComputeLot("F", InpFSlPipsFloor, balance);
   //    double lot      = base_lot * InpFLotReductionRatio;  // ร— 0.7 F-flag tier
   //    string comment  = "F,FP,N,1,SL";                     // CodeWiki ยง5.3 tag
   //    m_logger.Info("SlotF", "entry_signal", MAGIC_F,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s",
   //                               lot, InpFSlPipsFloor, comment));
   //
   //--- CrossSlotCoordinator stub: coupling from CD โ’ F sub-call
   if(m_xslot != NULL && false /* enable when OpenOrderCD chain wired (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: F activation from CD's OpenOrderCD
      //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot F exit pass (40-pip profit gate; mirrors C/D)  |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate F positions via GetTicketsForSlot(MAGIC_F, "F,")     |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate โฅ InpFTpProfitPips (40 pip default) โ’ close      |
//+------------------------------------------------------------------+
void CSlotF::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve F tickets (own magic MAGIC_F=201, comment prefix "F,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_F, "F,", tickets);
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

      //--- Profit gate: โฅ InpFTpProfitPips (40 pip default โ€” mirrors C/D tier)
      if(profit_pips >= InpFTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotF", "exit_profit_gate", MAGIC_F,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
//                                     ticket, profit_pips, InpFTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_F_MQH
