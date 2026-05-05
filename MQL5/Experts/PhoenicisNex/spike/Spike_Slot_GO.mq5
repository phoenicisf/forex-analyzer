//+------------------------------------------------------------------+
//|                                              Spike_Slot_GO.mq5   |
//|                                     Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-027 (Slot GO derived class |
//| per ADR-002, Magic=MAGIC_GO=209 own, SlotId="GO").                |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotGO instantiable + 6-method contract spot-check           |
//|   - Magic() == MAGIC_GO (209)                                      |
//|   - SlotId() == "GO"                                              |
//|   - DependsOn() returns 0 (GO is topology-independent;            |
//|     sub-call activation from TriggerGOverload is runtime-only,   |
//|     not a slot topology dependency per ADR-012)                   |
//|   - PendingState() == PENDING_STATE_IDLE                           |
//|   - Magic() in BR-1.1 range [200..220]                            |
//|   - SlotId() non-empty (not sentinel "")                          |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_G2.mq5 stub shape (IMPL-026).         |
//| NOTE: G2-G4 full entry+exit E-ACs wire at Orchestrator wiring path (core/Orchestrator.mqh)     |
//|       (RiskManager::OpenOrder); smoke ini committed for PR contract|
//|       per TD-02 ยง13.6 (see simulation/headless-tests/slot_GO_smoke.ini).|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same pattern as Spike_Slot_G2)
#include "../slots/Slot_GO.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit โ€” SelfTest for Slot GO contract                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotGO instance
   CSlotGO slot_go;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_go.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_GO (209) โ€” own magic, not shared
   if(slot_go.Magic() != MAGIC_GO)
     {
      Print("Spike_Slot_GO: FAIL case 1 โ€” Magic()=", slot_go.Magic(),
            " expected MAGIC_GO=", MAGIC_GO);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "GO"
   if(slot_go.SlotId() != "GO")
     {
      Print("Spike_Slot_GO: FAIL case 2 โ€” SlotId()='", slot_go.SlotId(),
            "' expected 'GO'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (topology-independent; sub-call activation is runtime)
   int deps[];
   int dep_count = slot_go.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_GO: FAIL case 3 โ€” DependsOn()=", dep_count,
            " expected 0 (topology-independent)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (GO not in pending-flow list)
   if(slot_go.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_GO: FAIL case 4 โ€” PendingState()=", (int)slot_go.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_go.Magic() < 200 || slot_go.Magic() > 220)
     {
      Print("Spike_Slot_GO: FAIL case 5 โ€” Magic()=", slot_go.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_go.SlotId() == "")
     {
      Print("Spike_Slot_GO: FAIL case 6 โ€” SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotGO][ev=spike_self_test][result=pass] "
         "6 cases passed โ€” Magic=", slot_go.Magic(),
         " SlotId=", slot_go.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_go.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
