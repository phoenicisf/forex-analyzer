//+------------------------------------------------------------------+
//| slots/Slot_D.mqh โ€” Slot D implementation (IMPL-020)               |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_CD = 200 (shared with Slot C โ€” D wraps C)          |
//| Source:  CodeWiki ยง3.2 Slot D; BR-2.1; ADR-002; ADR-012           |
//|                                                                   |
//| XS-size MVP โ€” 4-line wrapper of Slot C's force-pending workflow:  |
//|   Slot D delegates to ForcePendingActionOrder() +                 |
//|   ForceDivergentWorking() (CodeWiki :7692 + :8009 in legacy EA).  |
//|   D shares MAGIC_CD with C; tickets distinguished by comment      |
//|   prefix "D," (vs C's "C,") so GetTicketsForSlot disambiguates.   |
//|                                                                   |
//| Phase 1 MVP scope:                                                |
//|   - All 6 CSlotBase methods overridden (ADR-002 contract)         |
//|   - Magic() = MAGIC_CD; SlotId() = "D"; comment "D," reserved      |
//|   - DependsOn() returns [MAGIC_CD] โ€” D wraps C's force-pending   |
//|     path; topology-wise D follows C in OnTick orchestration       |
//|   - PendingState() โ€” D shares PM_C with C (no own PMR slot);     |
//|     delegates to PMR.GetState(PM_C) with NULL guard              |
//|   - Evaluate(): own-active guard + sub-call delegation stub       |
//|     (real ForcePendingActionOrder logic landed at IMPL-062       |
//|     commit 277cdb2 โ€” see docs/state/regression-bucket-a.md)       |
//|   - ManageExits(): no `ExtraTakeProfit_D` exists in legacy EA โ€”  |
//|     D's exits handled by C's ExtraTakeProfit_CD via shared magic |
//|     (CodeWiki ยง3.2 "no separate ExtraTakeProfit_D"); MVP ManageExits |
//|     iterates "D," tickets only and applies same 40-pip profit     |
//|     gate as C for symmetry; CD-pair exits landed in IMPL-062     |
//|     (commit 277cdb2; cross-slot close-path landed in P4).         |
//|                                                                   |
//| Comment: "D,FP,N,1,SL" per CodeWiki ยง3.2 force-pending tag        |
//| Lot: RiskManager::ComputeLot("D", InpCSlPipsFloor, balance) *     |
//|      InpDLotMultiplier (1.4 โ 2 * 0.7 per legacy)                |
//|                                                                   |
//| Pending integration (BR-2.1 / BR-6.8):                            |
//|   - D shares PM_C with C (no PM_D โ€” wrapper semantics)            |
//|   - Force-pending legacy timeout via InpLegacyForceBars (9 H4)    |
//|   - PMR.TickAll owns force-clear (Orchestrator step 8)            |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh" โ€” D เธซเนเธฒเธก #include Slot_C.mqh    |
//|   (cross-slot data via PortfolioState.GetByMagic + shared magic)  |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected via Init)  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_D_MQH
#define PHOENICISNEX_SLOTS_SLOT_D_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_C.mqh"
#include "../inputs/Inputs_Slot_D.mqh"

//+------------------------------------------------------------------+
//| CSlotD โ€” Slot D derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Shared-magic wrapper of Slot C's force-pending workflow per       |
//| BR-2.1. D opens orders with comment "D," on MAGIC_CD; legacy      |
//| `ForcePendingActionOrder` + `ForceDivergentWorking` semantics     |
//| deferred to P4 IMPL-062 (paired with C's advanced filter set).    |
//+------------------------------------------------------------------+
class CSlotD : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveDOrder(CPortfolioState &port) const;

public:
   //--- Constructor / Destructor
   CSlotD() {}
   virtual ~CSlotD() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_CD = 200 (shared with Slot C)
   virtual int           Magic()  const override { return MAGIC_CD; }

   //--- 2. SlotId โ€” "D"; journal slot_id + comment prefix disambig from "C,"
   virtual string        SlotId() const override { return "D"; }

   //--- 3. Evaluate โ€” force-pending wrapper delegate (Phase 1 MVP stub)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” D wraps C's force-pending path (topology dep on MAGIC_CD)
   //       Orchestrator topo-sort places D after C in OnTick order
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_CD;
      return 1;
     }

   //--- 6. PendingState โ€” D shares PM_C with C (no PM_D); NULL guard fallback
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_C);
     }
  };

//+------------------------------------------------------------------+
//| _HasActiveDOrder โ€” check for open D orders via PortfolioState     |
//| Comment prefix "D," for shared-magic C/D disambiguation           |
//+------------------------------------------------------------------+
bool CSlotD::_HasActiveDOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_CD, "D,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot D entry pass (4-line wrapper delegate stub)       |
//|                                                                   |
//| Phase 1 MVP delegate semantics:                                   |
//|   D's real entry signal is the legacy ForcePendingActionOrder     |
//|   helper (CodeWiki :7692) โ€” ADX-W dominance + โฅ3 Force peaks <-9 |
//|   (BUY) / โฅ3 peaks (SELL) + WPR>85 + Hull>bar1, opens with        |
//|   `2 * gLot * 0.7`. ForceDivergentWorking (CodeWiki :8009)        |
//|   updates IsForcePendingActionBuy/SellOrder flags.                |
//|                                                                   |
//|   These advanced helpers are P4 deferred (IMPL-062) alongside     |
//|   Slot C's advanced filter set (Bollinger / Ichimoku / Hull /     |
//|   WPR D1 / Force-peak ranking). MVP body:                         |
//|     - Enable + service-wired guards                               |
//|     - Own-active guard (1 D order at a time per CodeWiki ยง3.2)    |
//|     - Stub log: observable milestone for E-AC [log-assertion]     |
//|       fires once IMPL-062 wires real ForcePendingActionOrder      |
//+------------------------------------------------------------------+
void CSlotD::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotD) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Own-active guard: 1 D order at a time ("D," prefix โ€” shared MAGIC_CD)
   if(_HasActiveDOrder(port)) return;

   //--- Phase 1 stub: real ForcePendingActionOrder + ForceDivergentWorking
   //    helpers deferred to P4 IMPL-062 (paired with C's advanced filters).
   //    Observable E-AC milestone when IMPL-062 wires the helpers:
   //
   //    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double base_lot = m_risk.ComputeLot("D", InpCSlPipsFloor, balance);
   //    double lot     = base_lot * InpDLotMultiplier;  // 2 * gLot * 0.7
   //    string comment = "D,FP,N,1,SL";                 // CodeWiki ยง3.2 tag
   //    m_logger.Info("SlotD", "entry_signal", MAGIC_CD,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s",
   //                               lot, InpCSlPipsFloor, comment));
   //
   //    PMR usage: D shares PM_C โ€” no separate EnterPending call from D;
   //    instead D piggybacks on C's PM_C IsForcePendingAction flags
   //    (legacy ForceDivergentWorking sets them; D reads).
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot D exit pass (40-pip profit gate; CD pair MVP)  |
//|                                                                   |
//| Legacy EA has no `ExtraTakeProfit_D`; D orders are closed via    |
//| `ExtraTakeProfit_CD` because they share MAGIC_CD (CodeWiki ยง3.2). |
//| In MVP we mirror C's 40-pip profit gate over "D,"-tagged tickets |
//| only โ€” once IMPL-062 wires the CD-pair logic, this will fold     |
//| into the shared CD exit pass.                                     |
//+------------------------------------------------------------------+
void CSlotD::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve D tickets only (comment prefix "D," โ€” shared MAGIC_CD with C)
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_CD, "D,", tickets);
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

      //--- Profit gate: โฅ InpCTpProfitPips (40 pip default โ€” mirrors C)
      if(profit_pips >= InpCTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotD", "exit_profit_gate", MAGIC_CD,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
//                                     ticket, profit_pips, InpCTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_D_MQH
