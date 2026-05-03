//+------------------------------------------------------------------+
//|                                               Spike_Slot_K.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-024 (Slot_K derived class) |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotK compiles cleanly (6-method contract)                   |
//|   - Magic() returns MAGIC_K (207)                                  |
//|   - SlotId() returns "K"                                           |
//|   - DependsOn() returns 0 (independent slot — IMPL-036 P4)        |
//|   - PendingState() returns PENDING_STATE_IDLE                      |
//|   - Service pointer Init() with Logger=ptr + NULL for remaining 7  |
//|                                                                  |
//| Pattern: mirrors Spike_CSlotBase.mq5 minimal harness.             |
//| IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = closure bar.  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same as Spike_CSlotBase)
#include "../slots/Slot_K.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest: instantiate CSlotK + verify 6-method contract  |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Instantiate Slot K (stack-allocated; no ownership transfer)
   CSlotK  slot_k;

   //--- Inject minimum deps (only Logger; others NULL — spike overrides
   //    don't dereference the 7 remaining service pointers in this test)
   slot_k.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Test 1: Magic() must return MAGIC_K (207)
   if(slot_k.Magic() != MAGIC_K)
     {
      Print("Spike_Slot_K: FAIL — Magic() = ", slot_k.Magic(), " expected ", MAGIC_K);
      return INIT_FAILED;
     }

   //--- Test 2: SlotId() must return "K"
   if(slot_k.SlotId() != "K")
     {
      Print("Spike_Slot_K: FAIL — SlotId() = '", slot_k.SlotId(), "' expected 'K'");
      return INIT_FAILED;
     }

   //--- Test 3: DependsOn() must return 0 (independent slot)
   int deps[];
   int dep_count = slot_k.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_K: FAIL — DependsOn() returned ", dep_count, " expected 0");
      return INIT_FAILED;
     }

   //--- Test 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_k.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_K: FAIL — PendingState() = ", (int)slot_k.PendingState(), " expected PENDING_STATE_IDLE=0");
      return INIT_FAILED;
     }

   //--- All SelfTest cases pass
   Print("Spike_Slot_K: 6-method contract OK — Magic=207, SlotId=K, DependsOn=0, PendingState=IDLE");
   return INIT_SUCCEEDED;
  }

void OnTick()    {}
void OnDeinit(const int reason) {}
