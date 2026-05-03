//+------------------------------------------------------------------+
//|                                               Spike_Slot_F.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-021 (Slot F derived class  |
//| per ADR-002, Magic=MAGIC_F=201, SlotId="F", CD-chain sub-call     |
//| per BR-2.1/2.2; not in main OnTick topo).                          |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_F (201)                                |
//|   Case 2: SlotId() == "F"                                         |
//|   Case 3: DependsOn() returns 1 with [MAGIC_CD] (F chained from CD)|
//|   Case 4: PendingState() == PENDING_STATE_IDLE (non-pending slot) |
//|   Case 5: Magic() in BR-1.1 range [200..220]                      |
//|   Case 6: SlotId() non-empty                                      |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_D.mq5 (IMPL-020) and Spike_Slot_I.mq5 |
//| (IMPL-028) — both declare topology dep via DependsOn=[parent_magic]|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_F.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot F contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotF instance
   CSlotF slot_f;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_f.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_F (201)
   if(slot_f.Magic() != MAGIC_F)
     {
      Print("Spike_Slot_F: FAIL case 1 — Magic()=", slot_f.Magic(),
            " expected MAGIC_F=", MAGIC_F);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "F"
   if(slot_f.SlotId() != "F")
     {
      Print("Spike_Slot_F: FAIL case 2 — SlotId()='", slot_f.SlotId(),
            "' expected 'F'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 1 with [MAGIC_CD] (F chained from CD)
   int deps[];
   int dep_count = slot_f.DependsOn(deps);
   if(dep_count != 1 || ArraySize(deps) != 1 || deps[0] != MAGIC_CD)
     {
      string deps_str = (ArraySize(deps) > 0) ? IntegerToString(deps[0]) : "<empty>";
      Print("Spike_Slot_F: FAIL case 3 — DependsOn()=", dep_count,
            " deps[0]=", deps_str, " expected 1 with [MAGIC_CD=", MAGIC_CD, "]");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (non-pending slot)
   if(slot_f.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_F: FAIL case 4 — PendingState()=", (int)slot_f.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_f.Magic() < 200 || slot_f.Magic() > 220)
     {
      Print("Spike_Slot_F: FAIL case 5 — Magic()=", slot_f.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_f.SlotId() == "")
     {
      Print("Spike_Slot_F: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotF][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_f.Magic(),
         " SlotId=", slot_f.SlotId(),
         " DependsOn=", dep_count,
         " deps[0]=", deps[0],
         " PendingState=", (int)slot_f.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
