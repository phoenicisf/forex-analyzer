//+------------------------------------------------------------------+
//| Inputs_Slot_BR.mqh — per-slot input declarations for Slot BR     |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   BR — Magic MAGIC_BR=215 (own; not shared)                 |
//|         BR is orphan exit-only; comment prefix "BR,"              |
//|         Spawned sub-call only from ExtraTakeProfit_B (BR-2.2)     |
//| Source: CodeWiki §3.18 Slot BR; BR-2.2; TD-02 §5.4; NFR-6.3       |
//|                                                                  |
//| S-size MVP — header-only contract scaffold                        |
//|   Real activation: <closed; ref purged fix-round-18 §18.1> CrossSlotCoordinator wires           |
//|   ExtraTakeProfit_B (Slot_B ManageExits) → TriggerBR sub-call.    |
//|   Slot_B.mqh BR-trigger stub guarded `false /*IMPL-053*/`.        |
//|                                                                  |
//| Not in main OnTick topo (Evaluate sub-call-only guard).           |
//| ManageExits: profit-gate close pattern mirroring Slot_GO.         |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_BR_MQH
#define PHOENICISNEX_INPUTS_SLOT_BR_MQH

input group "Slot BR"
input bool   InpEnableSlotBR        = true;   // Enable Slot BR (orphan exit-only spawn from ExtraTakeProfit_B; BR-2.2)
input int    InpBRMaxOrders         = 1;      // Max simultaneous BR orders (comment-prefix "BR," only)
input double InpBRBaseLot           = 20.0;   // Base lot factor — mirrors parent B's 20.0 (orphan echo role)
input double InpBRSlPipsFloor       = 80.0;   // SL floor in pips (parent B SL distance per CodeWiki §3.18)
input double InpBRTpProfitPips      = 40.0;   // Minimum profit gate for exit in pips (orphan tier; lighter than B's 50)

#endif // PHOENICISNEX_INPUTS_SLOT_BR_MQH
