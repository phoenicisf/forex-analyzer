//+------------------------------------------------------------------+
//|                                               Spike_Slot_C.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-019 (Slot C derived class  |
//| per ADR-002, Magic=MAGIC_CD=200, SlotId="C", C-Pending PM_C).     |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_CD (200)                               |
//|   Case 2: SlotId() == "C"                                         |
//|   Case 3: DependsOn() returns 0 (C is CD chain root —            |
//|            D depends on C, not C-on-D; PMR is shared service)    |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)     |
//|   Case 5: Magic() in BR-1.1 range [200..220]                      |
//|   Case 6: SlotId() non-empty                                      |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() NULL guard  |
//|       returns PENDING_STATE_IDLE per CSlotC::PendingState override |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_M.mq5 shape (IMPL-029).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_C.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot C contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotC instance
   CSlotC slot_c;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_c.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_CD (200)
   if(slot_c.Magic() != MAGIC_CD)
     {
      Print("Spike_Slot_C: FAIL case 1 — Magic()=", slot_c.Magic(),
            " expected MAGIC_CD=", MAGIC_CD);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "C"
   if(slot_c.SlotId() != "C")
     {
      Print("Spike_Slot_C: FAIL case 2 — SlotId()='", slot_c.SlotId(),
            "' expected 'C'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (C is CD chain root — D depends on C)
   int deps[];
   int dep_count = slot_c.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_C: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (CD chain root — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_c.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_C: FAIL case 4 — PendingState()=", (int)slot_c.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_c.Magic() < 200 || slot_c.Magic() > 220)
     {
      Print("Spike_Slot_C: FAIL case 5 — Magic()=", slot_c.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_c.SlotId() == "")
     {
      Print("Spike_Slot_C: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotC][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_c.Magic(),
         " SlotId=", slot_c.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_c.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
