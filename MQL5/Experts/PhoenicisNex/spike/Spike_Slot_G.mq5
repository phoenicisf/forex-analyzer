//+------------------------------------------------------------------+
//|                                               Spike_Slot_G.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-025 (Slot G derived class  |
//| per ADR-002, Magic=208 shared with G2, SlotId="G").               |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotG instantiable + 6-method contract spot-check            |
//|   - Magic() == MAGIC_G (208)                                       |
//|   - SlotId() == "G"                                               |
//|   - DependsOn() returns 0 (independent slot in Phase 1)           |
//|   - PendingState() == PENDING_STATE_IDLE                           |
//|   - Init() with Logger ptr (other 7 NULL — test harness)          |
//|                                                                   |
//| Pattern: mirrors Spike_CSlotBase.mq5 stub shape (IMPL-018).       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same pattern as Spike_CSlotBase)
#include "../slots/Slot_G.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot G contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotG instance
   CSlotG slot_g;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_g.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_G (208)
   if(slot_g.Magic() != MAGIC_G)
     {
      Print("Spike_Slot_G: FAIL case 1 — Magic()=", slot_g.Magic(),
            " expected MAGIC_G=", MAGIC_G);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "G"
   if(slot_g.SlotId() != "G")
     {
      Print("Spike_Slot_G: FAIL case 2 — SlotId()='", slot_g.SlotId(),
            "' expected 'G'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (G is independent in Phase 1)
   int deps[];
   int dep_count = slot_g.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_G: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (independent)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_g.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_G: FAIL case 4 — PendingState()=", (int)slot_g.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_g.Magic() < 200 || slot_g.Magic() > 220)
     {
      Print("Spike_Slot_G: FAIL case 5 — Magic()=", slot_g.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_g.SlotId() == "")
     {
      Print("Spike_Slot_G: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotG][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_g.Magic(),
         " SlotId=", slot_g.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_g.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
