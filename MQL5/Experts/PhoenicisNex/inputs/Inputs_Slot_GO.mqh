//+------------------------------------------------------------------+
//| Inputs_Slot_GO.mqh — Slot GO input parameters (IMPL-027)         |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_GO = 209 (own; not shared)                         |
//| Source:  CodeWiki §3.GO; TD-02 §5.4; NFR-6.3 group annotation    |
//|                                                                   |
//| GO post-exit hook role (echo of G overload):                      |
//|   - G overload echo: BaseLot mirrors G's 30.0                     |
//|   - Invoked sub-call only from G's TriggerGOverload (BR-2.2)      |
//|   - Not iterated in main OnTick topo                              |
//|   - Comment prefix "GO," for order disambiguation                 |
//|                                                                   |
//| S-size MVP — header-only contract scaffold                        |
//|   Real activation: <closed; ref purged fix-round-18 §18.1> (orchestrator wiring TriggerGOverload)|
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_GO_MQH
#define PHOENICISNEX_INPUTS_SLOT_GO_MQH

input group "Slot GO"
input bool   InpEnableSlotGO       = true;    // Enable Slot GO (post-exit hook from G; sub-call only via TriggerGOverload)
input int    InpGOMaxOrders        = 1;       // Max simultaneous GO orders (comment-prefix "GO," per CodeWiki §3.GO)
input double InpGOBaseLot          = 30.0;    // Base lot multiplier factor — mirrors G's 30.0 (overload echo role)
input double InpGOSlPipsFloor      = 50.0;    // SL floor in pips (GO overload echo; same tier as G's floor)
input double InpGOTpProfitPips     = 40.0;    // Minimum profit gate for exit in pips (lighter than G's 50, heavier than G2's 30)

#endif // PHOENICISNEX_INPUTS_SLOT_GO_MQH
