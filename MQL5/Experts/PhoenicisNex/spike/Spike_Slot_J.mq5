//+------------------------------------------------------------------+
//|                                               Spike_Slot_J.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-022 (Slot J derived class  |
//| per ADR-002, Magic=MAGIC_J=206, SlotId="J", CD-follower per       |
//| CodeWiki §3.J + ⚠️ G4 fix BR-7.2 — ManageExits iterates MAGIC_J). |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_J (206)         ⚠️ G4 fix BR-7.2        |
//|   Case 2: SlotId() == "J"                                         |
//|   Case 3: DependsOn() returns 1 with [MAGIC_CD] (J follows CD)    |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (non-pending slot) |
//|   Case 5: Magic() in BR-1.1 range [200..220]                      |
//|   Case 6: SlotId() non-empty                                      |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_F.mq5 (IMPL-021) — both declare topo  |
//|   dep via DependsOn=[MAGIC_CD] (CD-chain follower / sub-call).    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_J.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot J contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotJ instance
   CSlotJ slot_j;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_j.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_J (206) — ⚠️ G4 fix BR-7.2 surface
   if(slot_j.Magic() != MAGIC_J)
     {
      Print("Spike_Slot_J: FAIL case 1 — Magic()=", slot_j.Magic(),
            " expected MAGIC_J=", MAGIC_J, " (G4 fix BR-7.2)");
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "J"
   if(slot_j.SlotId() != "J")
     {
      Print("Spike_Slot_J: FAIL case 2 — SlotId()='", slot_j.SlotId(),
            "' expected 'J'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 1 with [MAGIC_CD] (J follows CD)
   int deps[];
   int dep_count = slot_j.DependsOn(deps);
   if(dep_count != 1 || ArraySize(deps) != 1 || deps[0] != MAGIC_CD)
     {
      string deps_str = (ArraySize(deps) > 0) ? IntegerToString(deps[0]) : "<empty>";
      Print("Spike_Slot_J: FAIL case 3 — DependsOn()=", dep_count,
            " deps[0]=", deps_str, " expected 1 with [MAGIC_CD=", MAGIC_CD, "]");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (non-pending slot)
   if(slot_j.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_J: FAIL case 4 — PendingState()=", (int)slot_j.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_j.Magic() < 200 || slot_j.Magic() > 220)
     {
      Print("Spike_Slot_J: FAIL case 5 — Magic()=", slot_j.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_j.SlotId() == "")
     {
      Print("Spike_Slot_J: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotJ][ev=spike_self_test][result=pass] "
         "6 cases passed (G4 fix BR-7.2) — Magic=", slot_j.Magic(),
         " SlotId=", slot_j.SlotId(),
         " DependsOn=", dep_count,
         " deps[0]=", deps[0],
         " PendingState=", (int)slot_j.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
