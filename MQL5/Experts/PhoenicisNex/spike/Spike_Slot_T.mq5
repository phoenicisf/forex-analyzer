//+------------------------------------------------------------------+
//|                                               Spike_Slot_T.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-035 (Slot T derived class  |
//| per ADR-002, Magic=219, SlotId="T", T-Pending via PMR PM_T).      |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_T (219)                                 |
//|   Case 2: SlotId() == "T"                                          |
//|   Case 3: DependsOn() returns 0 (T topologically independent)     |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)      |
//|   Case 5: Magic() in BR-1.1 range [200..220]                       |
//|   Case 6: SlotId() non-empty                                       |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() safe guard  |
//|       returns PENDING_STATE_IDLE per CSlotT::PendingState override  |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_M.mq5 shape (IMPL-029).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_T.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot T contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotT instance
   CSlotT slot_t;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_t.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_T (219)
   if(slot_t.Magic() != MAGIC_T)
     {
      Print("Spike_Slot_T: FAIL case 1 — Magic()=", slot_t.Magic(),
            " expected MAGIC_T=", MAGIC_T);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "T"
   if(slot_t.SlotId() != "T")
     {
      Print("Spike_Slot_T: FAIL case 2 — SlotId()='", slot_t.SlotId(),
            "' expected 'T'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (T is topologically independent)
   int deps[];
   int dep_count = slot_t.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_T: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (topologically independent — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_t.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_T: FAIL case 4 — PendingState()=", (int)slot_t.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_t.Magic() < 200 || slot_t.Magic() > 220)
     {
      Print("Spike_Slot_T: FAIL case 5 — Magic()=", slot_t.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_t.SlotId() == "")
     {
      Print("Spike_Slot_T: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotT][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_t.Magic(),
         " SlotId=", slot_t.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_t.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
