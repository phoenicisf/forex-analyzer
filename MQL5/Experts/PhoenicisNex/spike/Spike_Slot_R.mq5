//+------------------------------------------------------------------+
//|                                               Spike_Slot_R.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-033 (Slot R derived class  |
//| per ADR-002, Magic=213, SlotId="R", R-Pending via PMR PM_R).      |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_R (213)                                 |
//|   Case 2: SlotId() == "R"                                          |
//|   Case 3: DependsOn() returns 0 (R topologically independent)     |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)      |
//|   Case 5: Magic() in BR-1.1 range [200..220]                       |
//|   Case 6: SlotId() non-empty                                       |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() safe guard  |
//|       returns PENDING_STATE_IDLE per CSlotR::PendingState override  |
//|                                                                   |
//| R-Pending: legacy timeout (InpLegacyRBars = 40); no ADR-008       |
//| force-clear — PMR internal; slot-side API identical to M/Q/T.     |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_M.mq5 shape (IMPL-029).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_R.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot R contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotR instance
   CSlotR slot_r;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_r.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_R (213)
   if(slot_r.Magic() != MAGIC_R)
     {
      Print("Spike_Slot_R: FAIL case 1 — Magic()=", slot_r.Magic(),
            " expected MAGIC_R=", MAGIC_R);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "R"
   if(slot_r.SlotId() != "R")
     {
      Print("Spike_Slot_R: FAIL case 2 — SlotId()='", slot_r.SlotId(),
            "' expected 'R'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (R is topologically independent)
   int deps[];
   int dep_count = slot_r.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_R: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (topologically independent — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_r.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_R: FAIL case 4 — PendingState()=", (int)slot_r.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_r.Magic() < 200 || slot_r.Magic() > 220)
     {
      Print("Spike_Slot_R: FAIL case 5 — Magic()=", slot_r.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_r.SlotId() == "")
     {
      Print("Spike_Slot_R: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotR][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_r.Magic(),
         " SlotId=", slot_r.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_r.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
