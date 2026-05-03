//+------------------------------------------------------------------+
//|                                               Spike_Slot_Q.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-032 (Slot Q derived class  |
//| per ADR-002, Magic=212, SlotId="Q", Q-Pending via PMR PM_Q /      |
//| ADR-008 force-clear OQ-A2).                                       |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_Q (212)                                 |
//|   Case 2: SlotId() == "Q"                                          |
//|   Case 3: DependsOn() returns 0 (Q topologically independent)     |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)      |
//|   Case 5: Magic() in BR-1.1 range [200..220]                       |
//|   Case 6: SlotId() non-empty                                       |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() safe guard  |
//|       returns PENDING_STATE_IDLE per CSlotQ::PendingState override  |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_M.mq5 shape (IMPL-029).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_Q.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot Q contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotQ instance
   CSlotQ slot_q;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_q.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_Q (212)
   if(slot_q.Magic() != MAGIC_Q)
     {
      Print("Spike_Slot_Q: FAIL case 1 — Magic()=", slot_q.Magic(),
            " expected MAGIC_Q=", MAGIC_Q);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "Q"
   if(slot_q.SlotId() != "Q")
     {
      Print("Spike_Slot_Q: FAIL case 2 — SlotId()='", slot_q.SlotId(),
            "' expected 'Q'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (Q is topologically independent)
   int deps[];
   int dep_count = slot_q.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_Q: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (topologically independent — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_q.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_Q: FAIL case 4 — PendingState()=", (int)slot_q.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_q.Magic() < 200 || slot_q.Magic() > 220)
     {
      Print("Spike_Slot_Q: FAIL case 5 — Magic()=", slot_q.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_q.SlotId() == "")
     {
      Print("Spike_Slot_Q: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotQ][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_q.Magic(),
         " SlotId=", slot_q.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_q.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
