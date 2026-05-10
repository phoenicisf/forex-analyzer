//+------------------------------------------------------------------+
//| slots/Slot_J.mqh โ€” Slot J implementation (IMPL-022)               |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_J = 206 (own; not shared)                          |
//|          Comment prefix "J," in all OrderSend calls               |
//| Source:  CodeWiki ยง3.J (J = follower trade after CD chain);       |
//|          BR-7.2 (โ ๏ธ G4 critical fix: ExtraTakeProfit_J iterates    |
//|          MagicJ NOT MagicF โ€” original bug never set TP on J);     |
//|          ADR-002; ADR-012                                         |
//|                                                                   |
//| โ ๏ธ G4 FIX โ€” Bucket B (intentional behavioral change vs baseline): |
//|   The original PhoenicisN2.10 `ExtraTakeProfit_J` iterated MagicF |
//|   (=201) instead of MagicJ (=206). Result: J orders never had     |
//|   take-profit gates set, drifting against design intent. This     |
//|   rewrite restores the contract per BR-7.2 โ€” ManageExits queries |
//|   `m_portfolio.GetByMagic(MAGIC_J)` and iterates MAGIC_J tickets. |
//|   NFR-1.8 G4 acceptance budget separate from Bucket A NFR-1.1.    |
//|   Regression sign-off: IMPL-063 (P4 G4-fixes-on full backtest).   |
//|                                                                   |
//| M-size MVP โ€” header-only contract scaffold:                       |
//|   Slot J is a CD-follower (CodeWiki ยง3.J) โ€” its full entry        |
//|   pipeline runs in CrossSlotCoordinator (Orchestrator wiring path (core/Orchestrator.mqh)) which wires   |
//|   CD-entry โ’ J follower invocation. Until then Evaluate() is a    |
//|   no-op beyond enable + service-wired guards. ManageExits is      |
//|   the active surface โ€” it MUST iterate MAGIC_J (G4 fix) and is    |
//|   exercised every tick regardless of orchestrator wiring.         |
//|                                                                   |
//| Topology dep (DependsOn): returns [MAGIC_CD] so the Orchestrator  |
//|   topo-sort places J after CD in OnTick order โ€” CD entry must    |
//|   open before J follower runs.                                    |
//|                                                                   |
//| Exit (ManageExits) โ€” G4 fix surface:                              |
//|   - Iterate โ ๏ธ MAGIC_J tickets via GetByMagic(MAGIC_J) +          |
//|     GetTicketsForSlot(MAGIC_J, "J,", ...) โ€” was MAGIC_F (BR-7.2) |
//|   - Profit gate โฅ InpJTpProfitPips (40 pip default โ€” same tier   |
//|     as C/D/F for symmetry until baseline regression at IMPL-063) |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("J", InpJSlPipsFloor, balance)       |
//|      (no per-slot ratio โ€” J uses base J lot per BR-4.1 J row)     |
//| Comment: "J,..." reserved per CodeWiki ยง3.J disambiguation        |
//|                                                                   |
//| ADR-012 include discipline:                                       |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh" โ€” J เธซเนเธฒเธก #include Slot_C/D/F |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected via Init) |
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
//| CSlotJ โ€” Slot J derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| CD-follower per CodeWiki ยง3.J: triggered after a CD entry opens. |
//| Own magic MAGIC_J=206; comment prefix "J," in OrderSend calls.    |
//| โ ๏ธ G4 fix BR-7.2: ManageExits iterates MAGIC_J (was MAGIC_F).     |
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

   //--- 1. Magic โ€” MAGIC_J = 206 (own; not shared with any other slot)
   virtual int           Magic()  const override { return MAGIC_J; }

   //--- 2. SlotId โ€” "J"; journal slot_id field + comment prefix "J,"
   virtual string        SlotId() const override { return "J"; }

   //--- 3. Evaluate โ€” CD-follower (real signal arrives via CrossSlotCoordinator
   //       at Orchestrator wiring path (core/Orchestrator.mqh)); early-return guard in Phase 1 MVP
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   //       โ ๏ธ G4 fix BR-7.2 surface: iterates MAGIC_J (was MAGIC_F bug)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” J follows CD (topo dep on MAGIC_CD)
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_CD;
      return 1;
     }

   //--- 6. PendingState โ€” J is not a pending-flow slot; IDLE default
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _HasActiveJOrder โ€” check for open J orders via PortfolioState     |
//| โ ๏ธ Uses MAGIC_J (=206) โ€” own magic; comment prefix "J,"            |
//+------------------------------------------------------------------+
bool CSlotJ::_HasActiveJOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot J entry pass (CD-follower; early-return guard)    |
//|                                                                   |
//| Phase 1 MVP: J entry signal is wired from CD-entry events via     |
//| CrossSlotCoordinator (Orchestrator wiring path (core/Orchestrator.mqh)). Until then Evaluate is a no-op  |
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
   //    (Phase 1 MVP โ€” real signal arrives via CrossSlotCoordinator at Orchestrator wiring path (core/Orchestrator.mqh))
   if(!InpEnableSlotJ) return;
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Own-active guard: max InpJMaxOrders simultaneous J orders
   if(_HasActiveJOrder(port)) return;

   //--- Phase-1 stub: no entry signal in main topo โ€”
   //    CD-follower sub-call wires through core/Orchestrator.mqh
   //    (cross-slot coupling per ea.md) via CrossSlotCoordinator.
   //    Observable E-AC milestone for [log-assertion] once that wires:
   //
   //    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   //    double lot     = m_risk.ComputeLot("J", InpJSlPipsFloor, balance);
   //    string comment = "J,FP,N,1,SL";   // CodeWiki ยง3.J tag
   //    m_logger.Info("SlotJ", "entry_signal", MAGIC_J,
   //                  StringFormat("lot=%.2f sl_pips=%.1f comment=%s",
   //                               lot, InpJSlPipsFloor, comment));
   //
   //--- CrossSlotCoordinator stub: coupling from CD-entry โ’ J follower
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator wires CDโ’J (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: J activation from CD-entry event
      //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot J exit pass (40-pip profit gate)               |
//|                                                                   |
//| โ ๏ธ G4 fix BR-7.2 SURFACE โ€” this is the critical correctness path: |
//|   The original PhoenicisN2.10 `ExtraTakeProfit_J` iterated MagicF |
//|   (=201) so J orders never had take-profit gates evaluated.       |
//|   This rewrite restores the contract by iterating MAGIC_J (=206).|
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate J tickets via GetTicketsForSlot(MAGIC_J, "J,")       |
//|      (G4 fix marker โ€” was MAGIC_F (=201) in original)             |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate โฅ InpJTpProfitPips (40 pip default) โ’ close      |
//+------------------------------------------------------------------+
void CSlotJ::ManageExits(CPortfolioState &port)
  {
   if(!InpEnableSlotJ) return;
   if(m_logger == NULL) return;

   //--- โ ๏ธ G4 fix BR-7.2 โ€” iterate MAGIC_J (was MAGIC_F bug in PhoenicisN2.10).
   //    Retrieve J tickets via PortfolioState (own magic MAGIC_J=206, comment
   //    prefix "J,"). The original bug iterated MAGIC_F (=201) which never
   //    matched J tickets, so no take-profit gate was ever evaluated for J.
   ulong tickets[];
#ifdef DISABLE_G4_FIXES
   int n = port.GetTicketsForSlot(MAGIC_F, "J,", tickets);   // pre-G4 buggy behavior (Bucket A baseline โ€” BR-7.2; MAGIC_F was the original bug)
#else
   int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);   // G4 fix BR-7.2
#endif
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1) โ€” also fixes the
   //    3-digit JPY drift the reviewer flagged: this site previously
   //    used `==5 ? 10:1` and dropped the 3-digit branch.
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

      //--- Profit gate: โฅ InpJTpProfitPips (40 pip default โ€” symmetric with C/D/F)
      if(profit_pips >= InpJTpProfitPips)
        {
         //--- fix-round-17 ยง 17.1 โ€” log magic + attestation tag MUST follow the
         //    active build branch so Bucket A regression journal records do not
         //    falsely attest "G4 fix" while running the pre-G4 buggy path.
#ifdef DISABLE_G4_FIXES
         int    magic_for_log = MAGIC_F;   // tickets came from MAGIC_F iteration
         string g4_tag        = "(Bucket A โ€” pre-G4 BR-7.2 path)";
#else
         int    magic_for_log = MAGIC_J;
         string g4_tag        = "(G4 fix BR-7.2)";
#endif
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotJ", "exit_profit_gate", magic_for_log,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close %s",
//                                     ticket, profit_pips, InpJTpProfitPips, g4_tag));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
         //    G4 fix attestation: this code path is reached for MAGIC_J tickets
         //    (the original bug iterated MagicF and never reached here for J).
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_J_MQH
