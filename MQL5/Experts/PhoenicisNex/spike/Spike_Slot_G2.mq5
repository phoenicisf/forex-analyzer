//+------------------------------------------------------------------+
//|                                              Spike_Slot_G2.mq5   |
//|                                     Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-026 (Slot G2 derived class |
//| per ADR-002, Magic=208 shared with G, SlotId="G2").               |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotG2 instantiable + 6-method contract spot-check           |
//|   - Magic() == MAGIC_G (208)                                       |
//|   - SlotId() == "G2"                                              |
//|   - DependsOn() returns 0 (independent — CommentParser disambig   |
//|     "G2," vs "G," is internal, not a topology dependency)         |
//|   - PendingState() == PENDING_STATE_IDLE                           |
//|   - Magic() in BR-1.1 range [200..220]                            |
//|   - SlotId() non-empty (not sentinel "")                          |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_G.mq5 stub shape (IMPL-025).          |
//| NOTE: G2-G4 full entry+exit E-ACs deferred to IMPL-053+           |
//|       Orchestrator wiring (smoke ini committed for PR contract per |
//|       TD-02 §13.6; see simulation/headless-tests/slot_G2_smoke.ini)|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (same pattern as Spike_Slot_G)
#include "../slots/Slot_G2.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot G2 contract                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotG2 instance
   CSlotG2 slot_g2;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   slot_g2.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_G (208) — shared with G per CommentParser pattern
   if(slot_g2.Magic() != MAGIC_G)
     {
      Print("Spike_Slot_G2: FAIL case 1 — Magic()=", slot_g2.Magic(),
            " expected MAGIC_G=", MAGIC_G);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "G2" (not "G" — disambig critical)
   if(slot_g2.SlotId() != "G2")
     {
      Print("Spike_Slot_G2: FAIL case 2 — SlotId()='", slot_g2.SlotId(),
            "' expected 'G2'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (CommentParser disambig is internal; not topo dep)
   int deps[];
   int dep_count = slot_g2.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_G2: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (independent)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (G2 not in pending-flow list)
   if(slot_g2.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_G2: FAIL case 4 — PendingState()=", (int)slot_g2.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_g2.Magic() < 200 || slot_g2.Magic() > 220)
     {
      Print("Spike_Slot_G2: FAIL case 5 — Magic()=", slot_g2.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_g2.SlotId() == "")
     {
      Print("Spike_Slot_G2: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotG2][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_g2.Magic(),
         " SlotId=", slot_g2.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_g2.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
