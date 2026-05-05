//+------------------------------------------------------------------+
//|                                               Spike_Slot_L.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-030 (Slot_L derived class) |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotL compiles cleanly (6-method contract)                   |
//|   - Magic() returns MAGIC_L (211)                                  |
//|   - SlotId() returns "L"                                           |
//|   - DependsOn() returns 0 (independent — LX/S dep on L, not here) |
//|   - PendingState() returns PENDING_STATE_IDLE                      |
//|   - Magic in valid BR-1.1 range [200..220]                         |
//|   - SlotId non-empty                                               |
//|                                                                  |
//| Pattern: mirrors Spike_Slot_K.mq5 minimal harness.                |
//| IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = closure bar.  |
//| E-AC smoke wires at IMPL-017 / IMPL-062 (RiskManager::OpenOrder)  |
//|   per ea.md.                                                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same as Spike_CSlotBase)
#include "../slots/Slot_L.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest: instantiate CSlotL + verify 6-method contract  |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Instantiate Slot L (stack-allocated; no ownership transfer)
   CSlotL  slot_l;

   //--- Inject minimum deps (only Logger; others NULL — spike does not
   //    dereference the 7 remaining service pointers in this test)
   slot_l.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Test 1: Magic() must return MAGIC_L (211)
   if(slot_l.Magic() != MAGIC_L)
     {
      Print("Spike_Slot_L: FAIL — Magic() = ", slot_l.Magic(), " expected ", MAGIC_L);
      return INIT_FAILED;
     }

   //--- Test 2: SlotId() must return "L"
   if(slot_l.SlotId() != "L")
     {
      Print("Spike_Slot_L: FAIL — SlotId() = '", slot_l.SlotId(), "' expected 'L'");
      return INIT_FAILED;
     }

   //--- Test 3: DependsOn() must return 0 (independent — LX/S dep ON L, not here)
   int deps[];
   int dep_count = slot_l.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_L: FAIL — DependsOn() returned ", dep_count, " expected 0");
      return INIT_FAILED;
     }

   //--- Test 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_l.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_L: FAIL — PendingState() = ", (int)slot_l.PendingState(), " expected PENDING_STATE_IDLE=0");
      return INIT_FAILED;
     }

   //--- Test 5: Magic in valid BR-1.1 range [200..220]
   if(slot_l.Magic() < 200 || slot_l.Magic() > 220)
     {
      Print("Spike_Slot_L: FAIL — Magic() = ", slot_l.Magic(), " out of BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Test 6: SlotId non-empty
   if(StringLen(slot_l.SlotId()) == 0)
     {
      Print("Spike_Slot_L: FAIL — SlotId() is empty string");
      return INIT_FAILED;
     }

   //--- All SelfTest cases pass
   Print("[Phoenicis][SlotL][ev=spike_self_test][result=pass] Magic=211, SlotId=L, DependsOn=0, PendingState=IDLE, range=OK, id_nonempty=OK");
   return INIT_SUCCEEDED;
  }

void OnTick()    {}
void OnDeinit(const int reason) {}
