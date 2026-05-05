//+------------------------------------------------------------------+
//|                                              Spike_Slot_BI.mq5    |
//|                                      Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-039 (Slot_BI derived class) |
//|                                                                  |
//| ⚠️ G4 critical fix per ADR-009 — Bucket B drift NFR-1.8.          |
//| BI = pyramid child of Slot B; shared MAGIC_B=214; comment "BI,". |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotBI compiles cleanly (6-method contract)                  |
//|   - Magic() returns MAGIC_B (214, shared with parent B)           |
//|   - SlotId() returns "BI"                                         |
//|   - DependsOn() returns 0 (runtime-state dep, not topology;       |
//|     mirrors Slot_LX precedent)                                    |
//|   - PendingState() returns PENDING_STATE_IDLE                     |
//|   - Magic in valid BR-1.1 range [200..220]                        |
//|   - SlotId non-empty                                              |
//|                                                                  |
//| Pattern: mirrors Spike_Slot_LX.mq5 / Spike_Slot_BR.mq5 minimal    |
//| harness. IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = bar. |
//| E-AC smoke + G4 attestation wire at IMPL-017 / IMPL-062           |
//|   (RiskManager::OpenOrder) + 60-day Tester run with B+BI active   |
//|   per IMPL-039 E-AC.                                              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_BI.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest: instantiate CSlotBI + verify 6-method contract |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Instantiate Slot BI (stack-allocated; no ownership transfer)
   CSlotBI  slot_bi;

   //--- Inject minimum deps (only Logger; others NULL — spike does not
   //    dereference the 7 remaining service pointers in this test)
   slot_bi.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Test 1: Magic() must return MAGIC_B (214, shared with parent B)
   if(slot_bi.Magic() != MAGIC_B)
     {
      Print("Spike_Slot_BI: FAIL - Magic() = ", slot_bi.Magic(), " expected MAGIC_B=", MAGIC_B);
      return INIT_FAILED;
     }

   //--- Test 2: SlotId() must return "BI"
   if(slot_bi.SlotId() != "BI")
     {
      Print("Spike_Slot_BI: FAIL - SlotId() = '", slot_bi.SlotId(), "' expected 'BI'");
      return INIT_FAILED;
     }

   //--- Test 3: DependsOn() must return 0 (runtime-state dep via PortfolioState
   //    query; CommentParser shared-magic disambig is internal — not a topology
   //    dependency. Same precedent as Slot_LX vs Slot_L (IMPL-031).
   int deps[];
   int dep_count = slot_bi.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_BI: FAIL - DependsOn() returned ", dep_count, " expected 0");
      return INIT_FAILED;
     }

   //--- Test 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_bi.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_BI: FAIL - PendingState() = ", (int)slot_bi.PendingState(), " expected PENDING_STATE_IDLE=0");
      return INIT_FAILED;
     }

   //--- Test 5: Magic in valid BR-1.1 range [200..220]
   if(slot_bi.Magic() < 200 || slot_bi.Magic() > 220)
     {
      Print("Spike_Slot_BI: FAIL - Magic() = ", slot_bi.Magic(), " out of BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Test 6: SlotId non-empty
   if(StringLen(slot_bi.SlotId()) == 0)
     {
      Print("Spike_Slot_BI: FAIL - SlotId() is empty string");
      return INIT_FAILED;
     }

   //--- All SelfTest cases pass
   Print("[Phoenicis][SlotBI][ev=spike_self_test][result=pass] (G4 fix ADR-009) ",
         "Magic=214(shared B), SlotId=BI, DependsOn=0, PendingState=IDLE, range=OK, id_nonempty=OK");
   return INIT_SUCCEEDED;
  }

void OnTick()    {}
void OnDeinit(const int reason) {}
