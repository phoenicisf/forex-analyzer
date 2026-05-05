//+------------------------------------------------------------------+
//| domain/CSlotBase.mqh — abstract slot contract (ADR-002)           |
//| Layer:   domain/ (abstract base; one cross-layer include allowed) |
//| Schema:  docs/api-specs/slot-abstraction-contract.yaml            |
//| Spec:    docs/technical-design/02-backend-design.md § 3.4         |
//|                                                                  |
//| 6-method behavior contract — every derived slot (21 in P3 IMPL-  |
//| 019..039) MUST override ALL 6. ADR-002 enforces override         |
//| discipline via 2 layers (MQL5 ไม่มี true `=0` pure virtual         |
//| compile-time check ที่ portable across builds — ใช้สอง mechanism  |
//| เสริมแทน):                                                          |
//|                                                                  |
//|   Layer 1 (boot-time)  — `CSlotRegistry::ValidateTopo()` calls   |
//|                          Magic() + SlotId() ทุก slot post-Register;|
//|                          sentinel returns (-1 / "") → INIT_FAILED|
//|   Layer 2 (runtime)    — base virtual body calls Logger.Error +  |
//|                          ExpertRemove() — first invocation halts |
//|                          loud (no silent no-op = no orphan       |
//|                          positions per ADR-002 § Decision)        |
//|                                                                  |
//| #include exception (ADR-012 domain/* "pure types only" rule):    |
//|   This file MUST `#include "../services/Logger.mqh"` because the  |
//|   layer-2 runtime enforcement bodies (Evaluate/ManageExits/      |
//|   DependsOn) call `m_logger.Error(...)` inline — forward-decl ของ |
//|   CLogger คงเก็บ pointer ได้ แต่ method call ต้องการ full class   |
//|   definition ที่ point of expansion. Logger เป็น pure cross-     |
//|   cutting concern (ไม่ depend slots/state/journal/orchestrator)  |
//|   ดังนั้นการ include ที่นี่ไม่สร้าง circular dep + เป็น scoped   |
//|   exception ที่ ADR-002 layer-2 contract บังคับ. Other 7 service  |
//|   pointers (ind/risk/tj/sp/port/pmr/xs) ใช้ forward decl เพราะ   |
//|   base body ไม่ dereference — derived slots include ตามต้องการ.   |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_DOMAIN_CSLOTBASE_MQH
#define PHOENICISNEX_DOMAIN_CSLOTBASE_MQH

#include "EnumTypes.mqh"
#include "MarketContext.mqh"
#include "SlotState.mqh"
#include "../services/Logger.mqh"   // scoped exception — see header note (ADR-002 layer 2)
#include "../helpers/PipMath.mqh"   // ea.md mandate: pip arithmetic via CPipMath (Round-06 06.1)

//--- Forward declarations for the 7 services held only as opaque pointers
//    in the base. Derived slots #include the full headers as needed.
class CIndicatorService;
class CRiskManager;
class CTradeJournal;
class CStatePersistence;
class CPortfolioState;
class CPendingMachineRegistry;
class CCrossSlotCoordinator;

class CSlotBase
  {
protected:
   //--- Constructor-injected services (per ADR-002 — ห้าม global singleton)
   CIndicatorService        *m_indicators;
   CRiskManager             *m_risk;
   CTradeJournal            *m_journal;
   CLogger                  *m_logger;
   CStatePersistence        *m_state;
   CPortfolioState          *m_portfolio;
   CPendingMachineRegistry  *m_pending;
   CCrossSlotCoordinator    *m_xslot;

   //--- Round-06 06.1: pip-arithmetic helper (ea.md mandate). Composition
   //    Root (Phase-2 wiring; see docs/state/deferred-ac-registry.md) calls SetPipMath(); when NULL the protected
   //    helpers fall back to inline 5/3-digit detection (single fallback
   //    site eliminates the 19-way drift Finding 06.1 reported).
   CPipMath                 *m_pip;

public:
                     CSlotBase()
      : m_indicators(NULL), m_risk(NULL), m_journal(NULL), m_logger(NULL),
        m_state(NULL), m_portfolio(NULL), m_pending(NULL), m_xslot(NULL),
        m_pip(NULL) {}
   virtual          ~CSlotBase() {}

   //--- Round-06 06.1 — separate setter (does NOT change Init() arity to
   //    avoid breaking 4 spike harnesses). Composition Root invokes
   //    SetPipMath() right after Init() per ea.md mandate.
   void              SetPipMath(CPipMath *pip) { m_pip = pip; }

   //--- Composition Root injection (called by CSlotRegistry::RegisterAll
   //    per ADR-002 — slot ห้าม resolve services เอง). Pointers may be
   //    NULL only in test harnesses; production wiring fills all 8.
   void              Init(CIndicatorService       *ind,
                          CRiskManager            *rm,
                          CTradeJournal           *tj,
                          CLogger                 *lg,
                          CStatePersistence       *sp,
                          CPortfolioState         *ps,
                          CPendingMachineRegistry *pmr,
                          CCrossSlotCoordinator   *xs)
     {
      m_indicators = ind; m_risk = rm; m_journal = tj; m_logger = lg;
      m_state = sp; m_portfolio = ps; m_pending = pmr; m_xslot = xs;
     }

   //--- 6-method behavior contract (matches slot-abstraction-contract.yaml
   //    § methods 1:1). Default bodies = ADR-002 layer-2 enforcement:
   //    sentinel returns for getters; Error+ExpertRemove for actions.

   //--- Magic() — sentinel -1 → ValidateTopo flags missing override.
   //    Range when overridden: 200..220 per BR-1.1.
   virtual int           Magic()  const { return -1; }

   //--- SlotId() — sentinel "" → ValidateTopo flags missing override.
   //    Used by journal record `slot_id` field for shared-magic disambig.
   virtual string        SlotId() const { return "";   }

   //--- Evaluate() — entry pass for this slot (FR-2.3); derived MUST
   //    override. Default body = loud failure per ADR-002 layer 2.
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port)
     {
      if(m_logger != NULL)
         m_logger.Error("CSlotBase", "missing_override", Magic(), "Evaluate");
      ExpertRemove();
     }

   //--- ManageExits() — exit pass for this slot (FR-2.3); runs in BOTH
   //    RUNNING and HALTED states per ADR-010.
   virtual void          ManageExits(CPortfolioState &port)
     {
      if(m_logger != NULL)
         m_logger.Error("CSlotBase", "missing_override", Magic(), "ManageExits");
      ExpertRemove();
     }

   //--- DependsOn() — fills out_magics[] with peer slots this slot
   //    requires (BR-2.1 + BR-2.2). Returns count written.
   virtual int           DependsOn(int &out_magics[])
     {
      if(m_logger != NULL)
         m_logger.Error("CSlotBase", "missing_override", Magic(), "DependsOn");
      ExpertRemove();
      return 0;
     }

   //--- PendingState() — current pending state per BR-6.x. Safe default
   //    PENDING_STATE_IDLE because most slots do not use the pending
   //    sub-flow; slots that DO (C/D/F/J/R/P/M/T/Q) override.
   virtual EPendingState PendingState() const { return PENDING_STATE_IDLE; }

protected:
   //--- Round-06 06.1 — pip helpers shared by 19 derived slots. When
   //    m_pip is wired (Phase-2 wiring; see docs/state/deferred-ac-registry.md Composition Root) the helpers route
   //    through CPipMath; otherwise a SINGLE fallback site implements
   //    the canonical 5/3-digit detection (matches CPipMath::Init at
   //    helpers/PipMath.mqh:31). Slots ห้าม re-derive this expression.

   //--- Returns price delta for 1 pip (5-digit broker → 0.00010).
   double            _PipSize() const
     {
      if(m_pip != NULL)
         return m_pip.PipToPrice(1.0);
      // Fallback (single site): canonical rule — see CPipMath::Init.
      return _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
     }

   //--- Convert pip count to signed price delta.
   double            _PipsToPrice(double pips) const
     {
      if(m_pip != NULL)
         return m_pip.PipToPrice(pips);
      return pips * _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
     }

   //--- Convert price difference to pip count (always positive — caller
   //    handles sign by direction).
   double            _PriceToPips(double price_diff) const
     {
      if(m_pip != NULL)
         return m_pip.PriceToPip(price_diff);
      return MathAbs(price_diff) / (_Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0));
     }

   //--- Round-06 06.3 — broker-bound price normalization (NormalizeDouble
   //    against current symbol's _Digits). Wraps every sl_price / tp_price
   //    that flows into RiskManager → CTrade::PositionOpen (broker rejects
   //    sub-tick precision with TRADE_RETCODE_INVALID_STOPS = 10016).
   double            _NormalizeBrokerPrice(double price) const
     {
      return NormalizeDouble(price, _Digits);
     }
  };

#endif // PHOENICISNEX_DOMAIN_CSLOTBASE_MQH
