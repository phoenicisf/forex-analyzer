//+------------------------------------------------------------------+
//|                                               Spike_Slot_M.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-029 (Slot M derived class  |
//| per ADR-002, Magic=210, SlotId="M", M-Pending via PMR PM_M).      |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_M (210)                                 |
//|   Case 2: SlotId() == "M"                                          |
//|   Case 3: DependsOn() returns 0 (M topologically independent)     |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)      |
//|   Case 5: Magic() in BR-1.1 range [200..220]                       |
//|   Case 6: SlotId() non-empty                                       |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() safe guard  |
//|       returns PENDING_STATE_IDLE per CSlotM::PendingState override  |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_G.mq5 shape (IMPL-025).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_M.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot M contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotM instance
   CSlotM slot_m;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_m.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_M (210)
   if(slot_m.Magic() != MAGIC_M)
     {
      Print("Spike_Slot_M: FAIL case 1 — Magic()=", slot_m.Magic(),
            " expected MAGIC_M=", MAGIC_M);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "M"
   if(slot_m.SlotId() != "M")
     {
      Print("Spike_Slot_M: FAIL case 2 — SlotId()='", slot_m.SlotId(),
            "' expected 'M'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (M is topologically independent)
   int deps[];
   int dep_count = slot_m.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_M: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (topologically independent — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_m.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_M: FAIL case 4 — PendingState()=", (int)slot_m.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_m.Magic() < 200 || slot_m.Magic() > 220)
     {
      Print("Spike_Slot_M: FAIL case 5 — Magic()=", slot_m.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_m.SlotId() == "")
     {
      Print("Spike_Slot_M: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotM][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_m.Magic(),
         " SlotId=", slot_m.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_m.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
