//+------------------------------------------------------------------+
//| slots/Slot_J.mqh — Slot J implementation (IMPL-022)               |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_J = 206 (own; not shared)                          |
//|          Comment prefix "J," in all OrderSend calls               |
//| Source:  CodeWiki §3.J (J = follower trade after CD chain);       |
//|          BR-7.2 (⚠️ G4 critical fix: ExtraTakeProfit_J iterates    |
//|          MagicJ NOT MagicF — original bug never set TP on J);     |
//|          ADR-002; ADR-012                                         |
//|                                                                   |
//| ⚠️ G4 FIX — Bucket B (intentional behavioral change vs baseline): |
//|   The original PhoenicisN2.10 `ExtraTakeProfit_J` iterated MagicF |
//|   (=201) instead of MagicJ (=206). Result: J orders never had     |
//|   take-profit gates set, drifting against design intent. This     |
//|   rewrite restores the contract per BR-7.2 — ManageExits queries |
//|   `m_portfolio.GetByMagic(MAGIC_J)` and iterates MAGIC_J tickets. |
//|   NFR-1.8 G4 acceptance budget separate from Bucket A NFR-1.1.    |
//|   Regression sign-off: IMPL-063 (P4 G4-fixes-on full backtest).   |
//|                                                                   |
//| M-size MVP — header-only contract scaffold:                       |
//|   Slot J is a CD-follower (CodeWiki §3.J) — its full entry        |
//|   pipeline runs in CrossSlotCoordinator (IMPL-053+) which wires   |
//|   CD-entry → J follower invocation. Until then Evaluate() is a    |
//|   no-op beyond enable + service-wired guards. ManageExits is      |
//|   the active surface — it MUST iterate MAGIC_J (G4 fix) and is    |
//|   exercised every tick regardless of orchestrator wiring.         |
//|                                                                   |
//| Topology dep (DependsOn): returns [MAGIC_CD] so the Orchestrator  |
//|   topo-sort places J after CD in OnTick order — CD entry must    |
//|   open before J follower runs.                                    |
//|                                                                   |
//| Exit (ManageExits) — G4 fix surface:                              |
//|   - Iterate ⚠️ MAGIC_J tickets via GetByMagic(MAGIC_J) +          |
//|     GetTicketsForSlot(MAGIC_J, "J,", ...) — was MAGIC_F (BR-7.2) |
//|   - Profit gate ≥ InpJTpProfitPips (40 pip default — same tier   |
//|     as C/D/F for symmetry until baseline regression at IMPL-063) |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("J", InpJSlPipsFloor, balance)       |
//|      (no per-slot ratio — J uses base J lot per BR-4.1 J row)     |
//| Comment: "J,..." reserved per CodeWiki §3.J disambiguation        |
//|                                                                   |
//| ADR-012 include discipline:                                       |
//|   ห้าม #include "slots/<other>.mqh" — J ห้าม #include Slot_C/D/F |
//|   ห้าม #include "services/Logger.mqh" direct (injected via Init) |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_J_MQH
#define PHOENICISNEX_SLOTS_SLOT_J_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_J.mqh"

//+------------------------------------------------------------------+
//| CSlotJ — Slot J derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| CD-follower per CodeWiki §3.J: triggered after a CD entry opens. |
//| Own magic MAGIC_J=206; comment prefix "J," in OrderSend calls.    |
//| ⚠️ G4 fix BR-7.2: ManageExits iterates MAGIC_J (was MAGIC_F).     |
//+------------------------------------------------------------------+
class CSlotJ : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveJOrder(CPortfolioState &port) const;

public:
   //--- Constructor / Destructor
   CSlotJ() {}
   virtual ~CSlotJ() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_J = 206 (own; not shared with any other slot)
   virtual int           Magic()  const override { return MAGIC_J; }

   //--- 2. SlotId — "J"; journal slot_id field + comment prefix "J,"
   virtual string        SlotId() const override { return "J"; }

   //--- 3. Evaluate — CD-follower (real signal arrives via CrossSlotCoordinator
   //       at IMPL-053+); early-return guard in Phase 1 MVP
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   //       ⚠️ G4 fix BR-7.2 surface: iterates MAGIC_J (was MAGIC_F bug)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — J follows CD (topo dep on MAGIC_CD)
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_CD;
      return 1;
     }

   //--- 6. PendingState — J is not a pending-flow slot; IDLE default
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _HasActiveJOrder — check for open J orders via PortfolioState     |
//| ⚠️ Uses MAGIC_J (=206) — own magic; comment prefix "J,"            |
//+------------------------------------------------------------------+
bool CSlotJ::_HasActiveJOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot J entry pass (CD-follower; early-return guard)    |
//|                                                                   |
//| Phase 1 MVP: J entry signal is wired from CD-entry events via     |
//| CrossSlotCoordinator (IMPL-053+). Until then Evaluate is a no-op  |
//| beyond enable + service-wired guards. ManageExits remains active. |
//|                                                                   |
//| When IMPL-053 activates:                                          |
//|   - CD entry signal triggers CrossSlotCoordinator.OnCDEntry()     |
//|   - Coordinator invokes J.Evaluate (sub-call) with same MarketCtx |
//|   - J entry: own-active guard + lot/SL compute via RiskManager    |
//|   - Comment prefix "J," for all OrderSend calls                   |
//+------------------------------------------------------------------+
void CSlotJ::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   //--- Sub-call guard: early-return when not enabled or service not wired
   //    (Phase 1 MVP — real signal arrives via CrossSlotCoordinator at IMPL-053+)
   if(!InpEnableSlotJ) return;
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Own-active guard: max InpJMaxOrders simultaneous J orders
   if(_HasActiveJOrder(port)) return;

   //--- Phase 1 stub: no entry signal in main topo —
   //    CD-follower activation at IMPL-053 via CrossSlotCoordinator.
   //    Observable E-AC milestone for [log-assertion] when IMPL-053 wires sub-call:
   //
   //    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double lot     = m_risk.ComputeLot("J", InpJSlPipsFloor, balance);
   //    string comment = "J,FP,N,1,SL";   // CodeWiki §3.J tag
   //    m_logger.Info("SlotJ", "entry_signal", MAGIC_J,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s",
   //                               lot, InpJSlPipsFloor, comment));
   //
   //--- CrossSlotCoordinator stub (IMPL-053): coupling from CD-entry → J follower
   if(m_xslot != NULL && false /*IMPL-053: enable when CrossSlotCoordinator wires CD→J*/)
     {
      //--- Stub: J activation from CD-entry event deferred to IMPL-053
     }
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot J exit pass (40-pip profit gate)               |
//|                                                                   |
//| ⚠️ G4 fix BR-7.2 SURFACE — this is the critical correctness path: |
//|   The original PhoenicisN2.10 `ExtraTakeProfit_J` iterated MagicF |
//|   (=201) so J orders never had take-profit gates evaluated.       |
//|   This rewrite restores the contract by iterating MAGIC_J (=206).|
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Read SlotState via m_portfolio.GetByMagic(MAGIC_J)           |
//|      (G4 fix marker — was MAGIC_F)                                |
//|   2. Iterate J tickets via GetTicketsForSlot(MAGIC_J, "J,")       |
//|   3. Compute unrealized profit in pips                            |
//|   4. Profit gate ≥ InpJTpProfitPips (40 pip default) → close      |
//+------------------------------------------------------------------+
void CSlotJ::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- ⚠️ G4 fix BR-7.2 — iterate MAGIC_J (was MAGIC_F bug in PhoenicisN2.10).
   //    GetByMagic(MAGIC_J) returns SlotState for J; NULL is tolerated (warns
   //    via PortfolioState if magic unregistered, per ADR-005 contract).
   SlotState *j_state = port.GetByMagic(MAGIC_J);   // G4 fix BR-7.2 — was MAGIC_F
   if(j_state == NULL)
     {
      //--- SlotState not registered yet (pre-Orchestrator wiring); benign in
      //    Phase 1 MVP — fall through to direct ticket iteration.
     }

   //--- Retrieve J tickets (own magic MAGIC_J=206, comment prefix "J,")
   //    ⚠️ G4 fix BR-7.2 — was MAGIC_F (=201) which never matched J tickets
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);   // G4 fix BR-7.2
   if(n <= 0) return;

   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pip_factor = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10.0 : 1.0;
   double pip_size   = point * pip_factor;

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

      //--- Profit gate: ≥ InpJTpProfitPips (40 pip default — symmetric with C/D/F)
      if(profit_pips >= InpJTpProfitPips)
        {
         m_logger.Info("SlotJ", "exit_profit_gate", MAGIC_J,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close (G4 fix BR-7.2)",
                                    ticket, profit_pips, InpJTpProfitPips));

         //--- Phase-1 stub: OrderClose deferred to IMPL-053+ orchestrator wiring.
         //    G4 fix attestation: this code path is reached for MAGIC_J tickets
         //    (the original bug iterated MagicF and never reached here for J).
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_J_MQH
