//+------------------------------------------------------------------+
//|                                               Spike_Slot_D.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-020 (Slot D derived class  |
//| per ADR-002, Magic=MAGIC_CD=200 (shared with C), SlotId="D",      |
//| 4-line wrapper of C's force-pending workflow per BR-2.1).         |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_CD (200)                               |
//|   Case 2: SlotId() == "D"                                         |
//|   Case 3: DependsOn() returns 1 with [MAGIC_CD] (D wraps C)       |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)     |
//|   Case 5: Magic() in BR-1.1 range [200..220]                      |
//|   Case 6: SlotId() non-empty                                      |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() NULL guard  |
//|       returns PENDING_STATE_IDLE per CSlotD::PendingState override |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_C.mq5 shape (IMPL-019).                |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_D.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot D contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotD instance
   CSlotD slot_d;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_d.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_CD (200, shared with C)
   if(slot_d.Magic() != MAGIC_CD)
     {
      Print("Spike_Slot_D: FAIL case 1 — Magic()=", slot_d.Magic(),
            " expected MAGIC_CD=", MAGIC_CD);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "D"
   if(slot_d.SlotId() != "D")
     {
      Print("Spike_Slot_D: FAIL case 2 — SlotId()='", slot_d.SlotId(),
            "' expected 'D'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 1 with [MAGIC_CD] (D wraps C)
   int deps[];
   int dep_count = slot_d.DependsOn(deps);
   if(dep_count != 1 || ArraySize(deps) != 1 || deps[0] != MAGIC_CD)
     {
      string deps_str = (ArraySize(deps) > 0) ? IntegerToString(deps[0]) : "<empty>";
      Print("Spike_Slot_D: FAIL case 3 — DependsOn()=", dep_count,
            " deps[0]=", deps_str, " expected 1 with [MAGIC_CD=", MAGIC_CD, "]");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_d.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_D: FAIL case 4 — PendingState()=", (int)slot_d.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_d.Magic() < 200 || slot_d.Magic() > 220)
     {
      Print("Spike_Slot_D: FAIL case 5 — Magic()=", slot_d.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_d.SlotId() == "")
     {
      Print("Spike_Slot_D: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotD][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_d.Magic(),
         " SlotId=", slot_d.SlotId(),
         " DependsOn=", dep_count,
         " deps[0]=", deps[0],
         " PendingState=", (int)slot_d.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
