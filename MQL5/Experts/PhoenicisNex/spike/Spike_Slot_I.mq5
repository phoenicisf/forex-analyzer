//+------------------------------------------------------------------+
//|                                               Spike_Slot_I.mq5   |
//|                                     Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-028 (Slot I derived class  |
//| per ADR-002, Magic=216 own, SlotId="I", G-parasite Fibonacci).    |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotI instantiable + 6-method contract spot-check            |
//|   - Magic() == MAGIC_I (216)                                       |
//|   - SlotId() == "I"                                               |
//|   - DependsOn() returns 1 AND deps[0] == MAGIC_G (208)            |
//|     (parasite topology dependency — distinct from G2/LX which     |
//|      return 0; I's dep is on a different magic = MAGIC_G)          |
//|   - PendingState() == PENDING_STATE_IDLE                           |
//|   - Magic() in BR-1.1 range [200..220]                            |
//|   - SlotId() non-empty (not sentinel "")                          |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_G2.mq5 shape (IMPL-026).              |
//| NOTE: G2-G4 full entry+exit E-ACs wire at <closed; ref purged fix-round-18 §18.1>     |
//|       (RiskManager::OpenOrder); smoke ini committed for PR contract|
//|       per TD-02 §13.6 (see simulation/headless-tests/slot_I_smoke.ini).|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same pattern as Spike_Slot_G2)
#include "../slots/Slot_I.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot I contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotI instance
   CSlotI slot_i;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_i.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_I (216)
   if(slot_i.Magic() != MAGIC_I)
     {
      Print("Spike_Slot_I: FAIL case 1 — Magic()=", slot_i.Magic(),
            " expected MAGIC_I=", MAGIC_I);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "I"
   if(slot_i.SlotId() != "I")
     {
      Print("Spike_Slot_I: FAIL case 2 — SlotId()='", slot_i.SlotId(),
            "' expected 'I'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 1 AND deps[0] == MAGIC_G
   //    (G-parasite topology dependency — not internal disambig like G2/LX)
   int deps[];
   int dep_count = slot_i.DependsOn(deps);
   if(dep_count != 1)
     {
      Print("Spike_Slot_I: FAIL case 3a — DependsOn()=", dep_count,
            " expected 1 (G-parasite dep)");
      return INIT_FAILED;
     }
   if(deps[0] != MAGIC_G)
     {
      Print("Spike_Slot_I: FAIL case 3b — deps[0]=", deps[0],
            " expected MAGIC_G=", MAGIC_G);
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (I not in pending-flow list)
   if(slot_i.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_I: FAIL case 4 — PendingState()=", (int)slot_i.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_i.Magic() < 200 || slot_i.Magic() > 220)
     {
      Print("Spike_Slot_I: FAIL case 5 — Magic()=", slot_i.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_i.SlotId() == "")
     {
      Print("Spike_Slot_I: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotI][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_i.Magic(),
         " SlotId=", slot_i.SlotId(),
         " DependsOn=", dep_count,
         " deps[0]=", deps[0],
         " (MAGIC_G=", MAGIC_G, ")",
         " PendingState=", (int)slot_i.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
