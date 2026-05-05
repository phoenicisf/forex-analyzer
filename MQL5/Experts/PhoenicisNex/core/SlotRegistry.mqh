//+------------------------------------------------------------------+
//| core/SlotRegistry.mqh — slot lifecycle owner + ADR-002 layer-1   |
//| Layer:   core/ (depends domain/ + services/Logger; no slots/*)   |
//| Spec:    docs/technical-design/02-backend-design.md § 7.0.2      |
//|                                                                  |
//| Owns 21 derived `CSlotBase*` instances (P3 IMPL-019..039 build   |
//| these). Sub-pass scope (IMPL-018):                                |
//|   - Class shape + 21-slot capacity                                |
//|   - ValidateTopo() Layer-1 sentinel check on Magic() + SlotId()  |
//|   - Get / Count / ReleaseAll accessors                            |
//|   - SelfTest with negative + positive stub slots                 |
//|                                                                  |
//| Wiring (now landed via slot batch + Orchestrator closure):       |
//|   - RegisterAll() — instantiates 21 derived slots; stub still    |
//|     accepts manual Add() of pre-built CSlotBase* for SelfTest +  |
//|     for spike/harness paths that pre-date the Orchestrator wire  |
//|   - ValidateDependencyOrder() — BR-2.2 literal-order check       |
//|     (vacuously true for empty registry; full check ตอน 21 slots) |
//|                                                                  |
//| BR-2.2 literal slot order (the topo-sorted dispatch sequence):    |
//|   C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B,   |
//|   BR, BI                                                          |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_CORE_SLOTREGISTRY_MQH
#define PHOENICISNEX_CORE_SLOTREGISTRY_MQH

#include "../domain/CSlotBase.mqh"
#include "../services/Logger.mqh"

//--- 21 slot derived classes — included so RegisterAll() can `new` each.
//    BR-2.2 topological order matches the construction loop below.
#include "../slots/Slot_C.mqh"
#include "../slots/Slot_D.mqh"
#include "../slots/Slot_F.mqh"
#include "../slots/Slot_J.mqh"
#include "../slots/Slot_H.mqh"
#include "../slots/Slot_K.mqh"
#include "../slots/Slot_G.mqh"
#include "../slots/Slot_G2.mqh"
#include "../slots/Slot_GO.mqh"
#include "../slots/Slot_M.mqh"
#include "../slots/Slot_L.mqh"
#include "../slots/Slot_LX.mqh"
#include "../slots/Slot_Q.mqh"
#include "../slots/Slot_R.mqh"
#include "../slots/Slot_I.mqh"
#include "../slots/Slot_P.mqh"
#include "../slots/Slot_T.mqh"
#include "../slots/Slot_S.mqh"
#include "../slots/Slot_B.mqh"
#include "../slots/Slot_BR.mqh"
#include "../slots/Slot_BI.mqh"

#define PHOENICISNEX_SLOT_CAPACITY 21

class CSlotRegistry
  {
private:
   CSlotBase        *m_slots[PHOENICISNEX_SLOT_CAPACITY];
   int               m_count;
   CLogger          *m_logger;
   bool              m_owns_slots;   // true = ReleaseAll deletes; false = caller-owned

   //--- BR-2.2 literal-order check (full impl when 21 slots land at
   //    IMPL-019..039). For IMPL-018 sub-pass: vacuously true when
   //    m_count == 0; otherwise verify each slot's DependsOn list
   //    references magic numbers that appear at lower indices.
   //
   //    Non-const because CSlotBase::DependsOn writes out_magics[] —
   //    MQL5 forbids calling non-const methods through pointer fields
   //    held in a const method (error 279). Spec deviation from TD-02
   //    § 7.0.2 (which sketched ValidateTopo as const) is necessary
   //    and harmless: ValidateTopo is invoked once at OnInit only.
   bool              ValidateDependencyOrder()
     {
      // Stub-safe path: with 0 or 1 slot registered, dependency order
      // is vacuously satisfied. For multi-slot harnesses (SelfTest +
      // Orchestrator wiring path), perform the literal-index-precedes-
      // relation check using DependsOn().
      if(m_count <= 1)
         return true;

      for(int i = 0; i < m_count; i++)
        {
         int deps[];
         int dep_count = m_slots[i].DependsOn(deps);
         for(int d = 0; d < dep_count; d++)
           {
            // Find dep magic in m_slots[0..i-1]. Missing = order violation.
            bool found = false;
            for(int j = 0; j < i; j++)
              {
               if(m_slots[j].Magic() == deps[d])
                 {
                  found = true;
                  break;
                 }
              }
            if(!found)
              {
               if(m_logger != NULL)
                  m_logger.Error("SlotRegistry", "topo_order_violation",
                                 m_slots[i].Magic(),
                                 StringFormat("missing_dep_magic=%d at_index=%d",
                                              deps[d], i));
               return false;
              }
           }
        }
      return true;
     }

public:
                     CSlotRegistry()
      : m_count(0), m_logger(NULL), m_owns_slots(true)
     {
      for(int i = 0; i < PHOENICISNEX_SLOT_CAPACITY; i++)
         m_slots[i] = NULL;
     }

                    ~CSlotRegistry()
     {
      // Defensive: if ReleaseAll was not called, do not leak. Test harnesses
      // can flip m_owns_slots = false to keep stack-allocated derived slots.
      ReleaseAll();
     }

   void              Init(CLogger *lg)
     {
      //--- Safe re-init: route through ReleaseAll so heap-allocated slots
      //    are deleted when m_owns_slots == true. A bare reset (m_count=0
      //    + NULL the array) would leak 21 CSlotBase derivatives on the
      //    OnInit re-entry path (CleanupPartialInit per TD-02 §7.4.1).
      ReleaseAll();
      m_logger = lg;
     }

   //--- Test harness accessor — flip ownership before adding stack-
   //    allocated stubs in SelfTest so destructor doesn't `delete` them.
   void              SetOwnsSlots(bool owns) { m_owns_slots = owns; }

   //--- Manual append (used by SelfTest + early Orchestrator harnesses
   //    until IMPL-019..039 fills RegisterAll). Returns false on overflow.
   bool              Add(CSlotBase *slot)
     {
      if(slot == NULL)
        {
         if(m_logger != NULL)
            m_logger.Error("SlotRegistry", "add_null_slot", 0, "");
         return false;
        }
      if(m_count >= PHOENICISNEX_SLOT_CAPACITY)
        {
         if(m_logger != NULL)
            m_logger.Error("SlotRegistry", "capacity_exceeded",
                           0, StringFormat("limit=%d", PHOENICISNEX_SLOT_CAPACITY));
         return false;
        }
      m_slots[m_count] = slot;
      m_count++;
      return true;
     }

   //--- RegisterAll — heap-news 21 derived slots in BR-2.2 topo order +
   //    Init each with the 8 service pointers. Caller (Orchestrator)
   //    invokes SetPipMath on each post-RegisterAll (Round-06 06.1).
   //    Returns false if any allocation fails OR Add() rejects (capacity).
   //    On failure the partially-built array is reclaimed by ReleaseAll
   //    (m_owns_slots=true is the default for production wiring).
   bool              RegisterAll(CIndicatorService *ind, CRiskManager *rm,
                                 CTradeJournal *tj, CLogger *lg,
                                 CStatePersistence *sp, CPortfolioState *ps,
                                 CPendingMachineRegistry *pmr,
                                 CCrossSlotCoordinator *xs)
     {
      // Production-mode ownership: this registry deletes the 21 slots in
      //   ReleaseAll (called from CleanupPartialInit + dtor). Test harnesses
      //   that pass stack-allocated stubs MUST flip via SetOwnsSlots(false).
      m_owns_slots = true;

      // BR-2.2 literal topological order — matches `04 § 2 dispatch order`
      // and the comment-prefix disambig contract in CommentParser.
      CSlotBase *slots[PHOENICISNEX_SLOT_CAPACITY];
      slots[0]  = new CSlotC();
      slots[1]  = new CSlotD();
      slots[2]  = new CSlotF();
      slots[3]  = new CSlotJ();
      slots[4]  = new CSlotH();
      slots[5]  = new CSlotK();
      slots[6]  = new CSlotG();
      slots[7]  = new CSlotG2();
      slots[8]  = new CSlotGO();
      slots[9]  = new CSlotM();
      slots[10] = new CSlotL();
      slots[11] = new CSlotLX();
      slots[12] = new CSlotQ();
      slots[13] = new CSlotR();
      slots[14] = new CSlotI();
      slots[15] = new CSlotP();
      slots[16] = new CSlotT();
      slots[17] = new CSlotS();
      slots[18] = new CSlotB();
      slots[19] = new CSlotBR();
      slots[20] = new CSlotBI();

      for(int i = 0; i < PHOENICISNEX_SLOT_CAPACITY; i++)
        {
         if(slots[i] == NULL)
           {
            if(m_logger != NULL)
               m_logger.Error("SlotRegistry", "alloc_fail", i, "");
            // Reclaim the ones we did allocate before bailing.
            for(int j = 0; j < PHOENICISNEX_SLOT_CAPACITY; j++)
               if(slots[j] != NULL) { delete slots[j]; slots[j] = NULL; }
            return false;
           }
         slots[i].Init(ind, rm, tj, lg, sp, ps, pmr, xs);
         if(!Add(slots[i]))
           {
            // Capacity exceeded should be impossible here (we just sized to
            //   PHOENICISNEX_SLOT_CAPACITY) but Add() also rejects NULL —
            //   defensive cleanup for both cases.
            if(m_logger != NULL)
               m_logger.Error("SlotRegistry", "add_failed_in_register_all", i, "");
            for(int j = i; j < PHOENICISNEX_SLOT_CAPACITY; j++)
               if(slots[j] != NULL) { delete slots[j]; slots[j] = NULL; }
            return false;
           }
        }
      return true;
     }

   //--- ADR-002 Layer 1 — sentinel check + topo order validation.
   //    Loop ทุก slot: ถ้า Magic() == -1 OR SlotId() == "" → log Error
   //    + return false. ตามด้วย ValidateDependencyOrder() ตรวจ BR-2.2.
   //    Non-const (see ValidateDependencyOrder note above).
   bool              ValidateTopo()
     {
      for(int i = 0; i < m_count; i++)
        {
         if(m_slots[i] == NULL)
           {
            if(m_logger != NULL)
               m_logger.Error("SlotRegistry", "slot_null", i, "");
            return false;
           }
         if(m_slots[i].Magic() == -1)
           {
            if(m_logger != NULL)
               m_logger.Error("SlotRegistry", "missing_magic_override",
                              i, m_slots[i].SlotId());
            return false;
           }
         if(m_slots[i].SlotId() == "")
           {
            if(m_logger != NULL)
               m_logger.Error("SlotRegistry", "missing_slot_id_override",
                              m_slots[i].Magic(), "");
            return false;
           }
        }
      return ValidateDependencyOrder();
     }

   //--- Iteration accessors (Orchestrator entry / exit pass)
   int               Count() const { return m_count; }

   CSlotBase        *Get(int idx) const
     {
      if(idx < 0 || idx >= m_count) return NULL;
      return m_slots[idx];
     }

   //--- OnDeinit cleanup — release heap allocations if owned.
   void              ReleaseAll()
     {
      if(m_owns_slots)
        {
         for(int i = 0; i < m_count; i++)
           {
            if(m_slots[i] != NULL)
              {
               delete m_slots[i];
               m_slots[i] = NULL;
              }
           }
        }
      else
        {
         // Caller-owned: just clear the array; caller deletes/destructs.
         for(int i = 0; i < m_count; i++)
            m_slots[i] = NULL;
        }
      m_count = 0;
     }

   //+------------------------------------------------------------------+
   //| SelfTest — exercises the IMPL-018 ADR-002 layer-1 contract       |
   //|                                                                  |
   //| Uses two stack-allocated stub slots (caller-owned, not deleted   |
   //| by ReleaseAll). Cases:                                            |
   //|   1. Empty registry → ValidateTopo true (vacuous)                |
   //|   2. Bad slot (Magic sentinel -1) → ValidateTopo false +         |
   //|      Logger Error `missing_magic_override`                       |
   //|   3. Good slot pair (proper override) → ValidateTopo true        |
   //|   4. Slot with empty SlotId → ValidateTopo false +               |
   //|      Logger Error `missing_slot_id_override`                     |
   //|   5a. NULL-guard surface → Add(NULL) returns false               |
   //|   5b. Capacity overflow surface → 22nd Add returns false         |
   //|   6.  PendingState() default = PENDING_STATE_IDLE                 |
   //+------------------------------------------------------------------+
   static bool       SelfTest(CLogger *logger,
                              CSlotBase *bad_slot,
                              CSlotBase *good_slot_a,
                              CSlotBase *good_slot_b,
                              CSlotBase *empty_id_slot);
  };

//+------------------------------------------------------------------+
//| SelfTest body — kept out-of-class to avoid the inline forward    |
//| decl gymnastics. Caller passes 4 stack-allocated stubs that      |
//| satisfy specific shapes (see Spike_CSlotBase.mq5).                |
//+------------------------------------------------------------------+
bool CSlotRegistry::SelfTest(CLogger *logger,
                             CSlotBase *bad_slot,
                             CSlotBase *good_slot_a,
                             CSlotBase *good_slot_b,
                             CSlotBase *empty_id_slot)
  {
   if(logger == NULL) return false;
   logger.Info("system", "SelfTest_SlotRegistry", 0, "Starting CSlotRegistry self test");

   // --- Case 1 — empty registry validates vacuously
   CSlotRegistry r1;
   r1.Init(logger);
   r1.SetOwnsSlots(false);
   if(!r1.ValidateTopo())
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 1 fail: empty registry should validate true");
      return false;
     }

   // --- Case 2 — bad slot (Magic sentinel) → ValidateTopo false
   CSlotRegistry r2;
   r2.Init(logger);
   r2.SetOwnsSlots(false);
   if(!r2.Add(bad_slot))
     { logger.Error("system","SelfTest_SlotRegistry",0,"Case 2 fail: Add"); return false; }
   if(r2.ValidateTopo())
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 2 fail: bad slot should fail ValidateTopo (Magic sentinel)");
      return false;
     }

   // --- Case 3 — good slot pair → ValidateTopo true
   CSlotRegistry r3;
   r3.Init(logger);
   r3.SetOwnsSlots(false);
   if(!r3.Add(good_slot_a) || !r3.Add(good_slot_b))
     { logger.Error("system","SelfTest_SlotRegistry",0,"Case 3 fail: Add good slots"); return false; }
   if(!r3.ValidateTopo())
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 3 fail: good slot pair should validate true");
      return false;
     }
   if(r3.Count() != 2)
     { logger.Error("system","SelfTest_SlotRegistry",0,"Case 3 fail: Count != 2"); return false; }

   // --- Case 4 — empty SlotId → ValidateTopo false
   CSlotRegistry r4;
   r4.Init(logger);
   r4.SetOwnsSlots(false);
   if(!r4.Add(empty_id_slot))
     { logger.Error("system","SelfTest_SlotRegistry",0,"Case 4 fail: Add"); return false; }
   if(r4.ValidateTopo())
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 4 fail: empty-SlotId slot should fail ValidateTopo");
      return false;
     }

   // --- Case 5a — NULL-guard surface (Add(NULL) returns false)
   //     Round-06 06.4 split: this case ONLY exercises the NULL guard
   //     branch at Add() (slot==NULL); the capacity branch is exercised
   //     separately in Case 5b below.
   CSlotRegistry r5a;
   r5a.Init(logger);
   r5a.SetOwnsSlots(false);
   if(r5a.Add(NULL))
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 5a fail: Add(NULL) should return false");
      return false;
     }

   // --- Case 5b — capacity overflow surface (22nd Add returns false)
   //     Round-06 06.4: previously the comment claimed "capacity overflow"
   //     but the body only tested NULL-guard, leaving the m_count >=
   //     PHOENICISNEX_SLOT_CAPACITY branch at Add() uncovered. Fill the
   //     registry to capacity using the same caller-owned good_slot_a stub,
   //     then assert the next Add rejects.
   CSlotRegistry r5b;
   r5b.Init(logger);
   r5b.SetOwnsSlots(false);
   for(int k = 0; k < PHOENICISNEX_SLOT_CAPACITY; k++)
     {
      if(!r5b.Add(good_slot_a))
        {
         logger.Error("system", "SelfTest_SlotRegistry", 0,
                      StringFormat("Case 5b fail: Add #%d unexpectedly rejected", k));
         return false;
        }
     }
   if(r5b.Add(good_slot_a))
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 5b fail: 22nd Add() should reject (capacity_exceeded)");
      return false;
     }

   // --- Case 6 — PendingState default
   if(good_slot_a.PendingState() != PENDING_STATE_IDLE)
     {
      logger.Error("system", "SelfTest_SlotRegistry", 0,
                   "Case 6 fail: PendingState default must be PENDING_STATE_IDLE");
      return false;
     }

   logger.Info("system", "SelfTest_SlotRegistry", 0,
               "CSlotRegistry self test PASS (7 cases — sentinel + slot-id + null-guard + capacity + pending default)");
   return true;
  }

#endif // PHOENICISNEX_CORE_SLOTREGISTRY_MQH
