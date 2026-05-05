//+------------------------------------------------------------------+
//|                                              Spike_Slot_BR.mq5    |
//|                                      Copyright 2026, PhoenicisNex |
//| G1 compile + SelfTest harness for IMPL-038 (Slot_BR derived class) |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotBR compiles cleanly (6-method contract)                  |
//|   - Magic() returns MAGIC_BR (215, own โ€” not shared)              |
//|   - SlotId() returns "BR"                                         |
//|   - DependsOn() returns 0 (sub-call only; orphan exit-only)       |
//|   - PendingState() returns PENDING_STATE_IDLE                     |
//|   - Magic in valid BR-1.1 range [200..220]                        |
//|   - SlotId non-empty                                              |
//|                                                                  |
//| Pattern: mirrors Spike_Slot_B.mq5 / Spike_Slot_GO.mq5 minimal     |
//| harness. IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = bar. |
//| E-AC smoke wires at Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder)  |
//|   + CrossSlotCoordinator BR-trigger wiring (BR-2.2) per ea.md.    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../slots/Slot_BR.mqh"

CLogger  g_logger;

//+------------------------------------------------------------------+
//| OnInit โ€” SelfTest: instantiate CSlotBR + verify 6-method contract |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Instantiate Slot BR (stack-allocated; no ownership transfer)
   CSlotBR  slot_br;

   //--- Inject minimum deps (only Logger; others NULL โ€” spike does not
   //    dereference the 7 remaining service pointers in this test)
   slot_br.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- Test 1: Magic() must return MAGIC_BR (215)
   if(slot_br.Magic() != MAGIC_BR)
     {
      Print("Spike_Slot_BR: FAIL - Magic() = ", slot_br.Magic(), " expected ", MAGIC_BR);
      return INIT_FAILED;
     }

   //--- Test 2: SlotId() must return "BR"
   if(slot_br.SlotId() != "BR")
     {
      Print("Spike_Slot_BR: FAIL - SlotId() = '", slot_br.SlotId(), "' expected 'BR'");
      return INIT_FAILED;
     }

   //--- Test 3: DependsOn() must return 0 (sub-call only; not in main topo)
   int deps[];
   int dep_count = slot_br.DependsOn(deps);
   if(dep_count != 0)
     {
      Print("Spike_Slot_BR: FAIL - DependsOn() returned ", dep_count, " expected 0");
      return INIT_FAILED;
     }

   //--- Test 4: PendingState() must return PENDING_STATE_IDLE
   if(slot_br.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_Slot_BR: FAIL - PendingState() = ", (int)slot_br.PendingState(), " expected PENDING_STATE_IDLE=0");
      return INIT_FAILED;
     }

   //--- Test 5: Magic in valid BR-1.1 range [200..220]
   if(slot_br.Magic() < 200 || slot_br.Magic() > 220)
     {
      Print("Spike_Slot_BR: FAIL - Magic() = ", slot_br.Magic(), " out of BR-1.1 range [200..220]");
      return INIT_FAILED;
     }

   //--- Test 6: SlotId non-empty
   if(StringLen(slot_br.SlotId()) == 0)
     {
      Print("Spike_Slot_BR: FAIL - SlotId() is empty string");
      return INIT_FAILED;
     }

   //--- All SelfTest cases pass
   Print("[Phoenicis][SlotBR][ev=spike_self_test][result=pass] Magic=215, SlotId=BR, DependsOn=0, PendingState=IDLE, range=OK, id_nonempty=OK");
   return INIT_SUCCEEDED;
  }

void OnTick()    {}
void OnDeinit(const int reason) {}
