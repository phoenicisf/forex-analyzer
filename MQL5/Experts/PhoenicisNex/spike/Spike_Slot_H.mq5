//+------------------------------------------------------------------+
//|                                                  Spike_Slot_H.mq5|
//|                                       Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-023 (Slot H)               |
//|                                                                   |
//| Coverage:                                                         |
//|   - CSlotH 6-method contract: Magic/SlotId/DependsOn/PendingState|
//|   - Magic() == MAGIC_H (205)                                      |
//|   - SlotId() == "H"                                               |
//|   - DependsOn() returns 0 (independent)                           |
//|   - PendingState() == PENDING_STATE_IDLE                          |
//|   - Init() wiring accepted without crash (NULL pointers — test)   |
//|                                                                   |
//| Pattern mirrors Spike_CSlotBase.mq5 (IMPL-018 precedent)         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle (same pattern as Spike_CSlotBase)
#include "../slots/Slot_H.mqh"

CLogger   g_logger;
CSlotH    g_slot_h;

//+------------------------------------------------------------------+
//| OnInit — SelfTest for CSlotH 6-method contract surface           |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Inject minimum deps: only Logger needed for base layer-2 bodies.
   //    Other 7 service pointers stay NULL — override methods don't
   //    dereference m_risk / m_journal etc. in SelfTest invocations.
   g_slot_h.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Case 1: Magic() == MAGIC_H (205)
   if(g_slot_h.Magic() != MAGIC_H)
     {
      Print("Spike_Slot_H FAIL: Magic() expected ", MAGIC_H, " got ", g_slot_h.Magic());
      return INIT_FAILED;
     }

   //--- Case 2: SlotId() == "H"
   if(g_slot_h.SlotId() != "H")
     {
      Print("Spike_Slot_H FAIL: SlotId() expected 'H' got '", g_slot_h.SlotId(), "'");
      return INIT_FAILED;
     }

   //--- Case 3: DependsOn() returns 0 (no peer deps — H is independent)
   int deps[];
   int dep_count = g_slot_h.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_H FAIL: DependsOn() expected 0 got ", dep_count);
      return INIT_FAILED;
     }

   //--- Case 4: PendingState() == PENDING_STATE_IDLE
   if(g_slot_h.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_H FAIL: PendingState() expected PENDING_STATE_IDLE got ",
            (int)g_slot_h.PendingState());
      return INIT_FAILED;
     }

   //--- Case 5: ValidateTopo layer-1 check — register CSlotH in registry,
   //    assert Magic/SlotId not sentinel (-1 / "")
   CSlotRegistry registry;
   registry.Init(&g_logger);
   registry.SetOwnsSlots(false);   // stack-allocated slot; no double-free
   if(!registry.Add(&g_slot_h))
     {
      Print("Spike_Slot_H FAIL: registry.Add() rejected CSlotH");
      return INIT_FAILED;
     }
   if(!registry.ValidateTopo())
     {
      Print("Spike_Slot_H FAIL: registry.ValidateTopo() failed for CSlotH");
      return INIT_FAILED;
     }

   Print("Spike_Slot_H: CSlotH 6-method contract OK "
         "(Magic=", g_slot_h.Magic(), " SlotId=", g_slot_h.SlotId(),
         " DependsOn=0 PendingState=IDLE)");
   return INIT_SUCCEEDED;
  }

void OnTick()     {}
void OnDeinit(const int reason) {}
