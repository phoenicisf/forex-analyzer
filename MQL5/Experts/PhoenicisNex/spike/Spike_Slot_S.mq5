//+------------------------------------------------------------------+
//|                                               Spike_Slot_S.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-036 (Slot S derived class  |
//| per ADR-002, Magic=217, SlotId="S", non-PMR post-close after L/K).|
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_S (217)                                |
//|   Case 2: SlotId() == "S"                                         |
//|   Case 3: DependsOn() returns 2, deps[0]==MAGIC_L, deps[1]==MAGIC_K|
//|   Case 4: PendingState() == PENDING_STATE_IDLE (non-PMR slot)     |
//|   Case 5: Magic() in BR-1.1 range [200..220]                      |
//|   Case 6: SlotId() non-empty                                      |
//|                                                                   |
//| Note: All service pointers NULL in test harness; CSlotS safely    |
//|       handles NULL m_logger/m_risk (guards before dereference).   |
//|       PendingState() always returns PENDING_STATE_IDLE (non-PMR). |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_M.mq5 shape + Spike_Slot_I.mq5       |
//|          DependsOn variant (but returns 2 deps, not 1).           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_S.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot S contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotS instance
   CSlotS slot_s;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (non-PMR slot: PendingState() always PENDING_STATE_IDLE)
   slot_s.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_S (217)
   if(slot_s.Magic() != MAGIC_S)
     {
      Print("Spike_Slot_S: FAIL case 1 — Magic()=", slot_s.Magic(),
            " expected MAGIC_S=", MAGIC_S);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "S"
   if(slot_s.SlotId() != "S")
     {
      Print("Spike_Slot_S: FAIL case 2 — SlotId()='", slot_s.SlotId(),
            "' expected 'S'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 2, deps[0]==MAGIC_L, deps[1]==MAGIC_K
   //    S is a post-close follower: depends on both L (MAGIC_L=211) and K (MAGIC_K=207)
   int deps[];
   int dep_count = slot_s.DependsOn(deps);
   if(dep_count != 2)
     {
      Print("Spike_Slot_S: FAIL case 3a — DependsOn()=", dep_count,
            " expected 2 (L + K post-close deps)");
      return INIT_FAILED;
     }
   if(deps[0] != MAGIC_L)
     {
      Print("Spike_Slot_S: FAIL case 3b — deps[0]=", deps[0],
            " expected MAGIC_L=", MAGIC_L);
      return INIT_FAILED;
     }
   if(deps[1] != MAGIC_K)
     {
      Print("Spike_Slot_S: FAIL case 3c — deps[1]=", deps[1],
            " expected MAGIC_K=", MAGIC_K);
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (non-PMR slot)
   if(slot_s.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_S: FAIL case 4 — PendingState()=", (int)slot_s.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_s.Magic() < 200 || slot_s.Magic() > 220)
     {
      Print("Spike_Slot_S: FAIL case 5 — Magic()=", slot_s.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_s.SlotId() == "")
     {
      Print("Spike_Slot_S: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotS][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_s.Magic(),
         " SlotId=", slot_s.SlotId(),
         " DependsOn=", dep_count,
         " deps[0]=", deps[0], "(MAGIC_L) deps[1]=", deps[1], "(MAGIC_K)",
         " PendingState=", (int)slot_s.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
