//+------------------------------------------------------------------+
//|                                               Spike_Slot_P.mq5   |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-034 (Slot P derived class  |
//| per ADR-002, Magic=218, SlotId="P", P-Pending sub-modes via PMR   |
//| PM_P with PSUB_NONE/N/PX/PH/E per `04 § 4.4`).                    |
//|                                                                   |
//| Coverage:                                                         |
//|   Case 1: Magic() == MAGIC_P (218)                                 |
//|   Case 2: SlotId() == "P"                                          |
//|   Case 3: DependsOn() returns 0 (P topologically independent)     |
//|   Case 4: PendingState() == PENDING_STATE_IDLE (NULL pending)      |
//|   Case 5: Magic() in BR-1.1 range [200..220]                       |
//|   Case 6: SlotId() non-empty                                       |
//|                                                                   |
//| Note: m_pending = NULL in test harness; PendingState() safe guard  |
//|       returns PENDING_STATE_IDLE per CSlotP::PendingState override  |
//|                                                                   |
//| P-Pending: legacy timeout (InpLegacyPBars = 70 H4 bars; BR-6.4);  |
//| no ADR-008 force-clear — PMR internal; slot-side API identical to |
//| M/Q/T except for sub-mode lifecycle (lock-once N→PX/PH).          |
//|                                                                   |
//| Pattern: mirrors Spike_Slot_R.mq5 shape (IMPL-033).               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_P.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for Slot P contract                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocate CSlotP instance
   CSlotP slot_p;

   //--- Inject Logger only; other 7 service ptrs NULL in test harness
   //    (m_pending = NULL → PendingState() returns PENDING_STATE_IDLE safely)
   slot_p.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() must return MAGIC_P (218)
   if(slot_p.Magic() != MAGIC_P)
     {
      Print("Spike_Slot_P: FAIL case 1 — Magic()=", slot_p.Magic(),
            " expected MAGIC_P=", MAGIC_P);
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() must return "P"
   if(slot_p.SlotId() != "P")
     {
      Print("Spike_Slot_P: FAIL case 2 — SlotId()='", slot_p.SlotId(),
            "' expected 'P'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() must return 0 (P is topologically independent)
   int deps[];
   int dep_count = slot_p.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_P: FAIL case 3 — DependsOn()=", dep_count,
            " expected 0 (topologically independent — PMR is shared service not slot dep)");
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() must return PENDING_STATE_IDLE (NULL PMR guard)
   if(slot_p.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_P: FAIL case 4 — PendingState()=", (int)slot_p.PendingState(),
            " expected PENDING_STATE_IDLE=", (int)PENDING_STATE_IDLE);
      return INIT_FAILED;
     }

   //--- Case 5: Magic() is in valid range 200..220 (BR-1.1)
   if(slot_p.Magic() < 200 || slot_p.Magic() > 220)
     {
      Print("Spike_Slot_P: FAIL case 5 — Magic()=", slot_p.Magic(),
            " outside BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Case 6: SlotId() non-empty (not sentinel "")
   if(slot_p.SlotId() == "")
     {
      Print("Spike_Slot_P: FAIL case 6 — SlotId() returned sentinel \"\"");
      return INIT_FAILED;
     }

   Print("[Phoenicis][SlotP][ev=spike_self_test][result=pass] "
         "6 cases passed — Magic=", slot_p.Magic(),
         " SlotId=", slot_p.SlotId(),
         " DependsOn=", dep_count,
         " PendingState=", (int)slot_p.PendingState());

   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
