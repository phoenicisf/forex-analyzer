//+------------------------------------------------------------------+
//|                                               Spike_Slot_B.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-037 (Slot_B derived class) |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotB compiles cleanly (6-method contract)                   |
//|   - Magic() returns MAGIC_B (214, shared with BI)                  |
//|   - SlotId() returns "B"                                           |
//|   - DependsOn() returns 0 (independent — BR/BI dep on B, not here)|
//|   - PendingState() returns PENDING_STATE_IDLE                      |
//|   - Magic in valid BR-1.1 range [200..220]                         |
//|   - SlotId non-empty                                               |
//|                                                                  |
//| Pattern: mirrors Spike_Slot_L.mq5 minimal harness.                |
//| IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = closure bar.  |
//| E-AC smoke wires at <closed; ref purged fix-round-18 §18.1> (RiskManager::OpenOrder)  |
//|   + CrossSlotCoordinator BR-trigger wiring per ea.md.             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_B.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest: instantiate CSlotB + verify 6-method contract  |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Instantiate Slot B (stack-allocated; no ownership transfer)
   CSlotB  slot_b;

   //--- Inject minimum deps (only Logger; others NULL — spike does not
   //    dereference the 7 remaining service pointers in this test)
   slot_b.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Test 1: Magic() must return MAGIC_B (214)
   if(slot_b.Magic() != MAGIC_B)
     {
      Print("Spike_Slot_B: FAIL — Magic() = ", slot_b.Magic(), " expected ", MAGIC_B);
      return INIT_FAILED;
     }

   //--- Test 2: SlotId() must return "B"
   if(slot_b.SlotId() != "B")
     {
      Print("Spike_Slot_B: FAIL — SlotId() = '", slot_b.SlotId(), "' expected 'B'");
      return INIT_FAILED;
     }

   //--- Test 3: DependsOn() must return 0 (independent — BR/BI dep ON B, not here)
   int deps[];
   int dep_count = slot_b.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_B: FAIL — DependsOn() returned ", dep_count, " expected 0");
      return INIT_FAILED;
     }

   //--- Test 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_b.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_B: FAIL — PendingState() = ", (int)slot_b.PendingState(), " expected PENDING_STATE_IDLE=0");
      return INIT_FAILED;
     }

   //--- Test 5: Magic in valid BR-1.1 range [200..220]
   if(slot_b.Magic() < 200 || slot_b.Magic() > 220)
     {
      Print("Spike_Slot_B: FAIL — Magic() = ", slot_b.Magic(), " out of BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Test 6: SlotId non-empty
   if(StringLen(slot_b.SlotId()) == 0)
     {
      Print("Spike_Slot_B: FAIL — SlotId() is empty string");
      return INIT_FAILED;
     }

   //--- All SelfTest cases pass
   Print("[Phoenicis][SlotB][ev=spike_self_test][result=pass] Magic=214, SlotId=B, DependsOn=0, PendingState=IDLE, range=OK, id_nonempty=OK");
   return INIT_SUCCEEDED;
  }

void OnTick()    {}
void OnDeinit(const int reason) {}
