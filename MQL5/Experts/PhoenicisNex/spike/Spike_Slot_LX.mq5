//+------------------------------------------------------------------+
//|                                             Spike_Slot_LX.mq5    |
//|                                     Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-031 (Slot LX derived class |
//| per ADR-002, Magic=211 shared with L, SlotId="LX").               |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotLX instantiable + 6-method contract spot-check           |
//|   - Magic() == MAGIC_L (211) โ€” shared with parent L               |
//|   - SlotId() == "LX" (distinct from parent L's "L" โ€” disambig)   |
//|   - DependsOn() returns 0 (LX depends on L runtime state via      |
//|     PortfolioState query, not topology โ€” CommentParser disambig   |
//|     is internal; same precedent as G2 vs G, IMPL-026)             |
//|   - PendingState() == PENDING_STATE_IDLE                           |
//|   - Magic() in BR-1.1 range [200..220]                            |
//|   - SlotId() non-empty (not sentinel "")                          |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_G2.mq5 (shared-magic case, IMPL-026). |
//| NOTE: G2-G4 full entry+exit E-ACs wire at Orchestrator wiring path (core/Orchestrator.mqh)     |
//|       (RiskManager::OpenOrder); smoke ini committed for PR contract|
//|       per TD-02 ยง13.6 (see simulation/headless-tests/slot_LX_smoke.ini).|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same pattern as Spike_Slot_G2)
#include "../slots/Slot_LX.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit โ€” SelfTest for Slot LX contract                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotLX instance
   CSlotLX slot_lx;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_lx.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_L (211) โ€” shared with parent L per CommentParser pattern
   if(slot_lx.Magic() != MAGIC_L)
     {
      Print("Spike_Slot_LX: FAIL case 1 โ€” Magic()=", slot_lx.Magic(),
            " expected MAGIC_L=", MAGIC_L);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "LX" (not "L" โ€” comment-prefix disambig critical)
   if(slot_lx.SlotId() != "LX")
     {
      Print("Spike_Slot_LX: FAIL case 2 โ€” SlotId()='", slot_lx.SlotId(),
            "' expected 'LX'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0
   //    LX depends on L's runtime state via PortfolioState query API.
   //    CommentParser "LX," vs "L," disambig is internal โ€” not a topology dep.
   //    Same reasoning as G2 vs G (IMPL-026): returns 0 (independent topology).
   int deps[];
   int dep_count = slot_lx.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_LX: FAIL case 3 โ€” DependsOn()=", dep_count,
            " expected 0 (runtime state dep via PortfolioState, not topology)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (LX not in pending-flow list)
   if(slot_lx.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_LX: FAIL case 4 โ€” PendingState()=", (int)slot_lx.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_lx.Magic() < 200 || slot_lx.Magic() > 220)
     {
      Print("Spike_Slot_LX: FAIL case 5 โ€” Magic()=", slot_lx.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_lx.SlotId() == "")
     {
      Print("Spike_Slot_LX: FAIL case 6 โ€” SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotLX][ev=spike_self_test][result=pass] "
         "6 cases passed โ€” Magic=", slot_lx.Magic(),
         " SlotId=", slot_lx.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_lx.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
