//+------------------------------------------------------------------+
//| Inputs_Slot_F.mqh — Slot F input parameters (IMPL-021)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_F = 201 (own; not shared)                          |
//| Source:  CodeWiki §5.3 OpenOrderCD chain to BusinessLogic_F;      |
//|          BR-2.1 (CD chain) + BR-2.2 (sub-call dispatch); ADR-002   |
//|                                                                   |
//| Slot F role (chained from CD per BR-2.1/2.2):                     |
//|   - Sub-call invoked from `OpenOrderCD(...isFOff=false)` after a  |
//|     CD entry opens (CodeWiki §5.3 :14185 — "chains BusinessLogic_F |
//|     if isFOff==false"); not iterated in main OnTick topo          |
//|   - Comment prefix "F," for order disambiguation                  |
//|   - "F" flag in legacy OpenOrder dispatcher selects per-slot lot  |
//|     reduction (CodeWiki §5.3 :15620 dispatcher table)             |
//|                                                                   |
//| S-size MVP — header-only contract scaffold                        |
//|   Real activation: <closed; ref purged fix-round-18 §18.1> (CrossSlotCoordinator wires CD-open  |
//|   → BusinessLogic_F sub-call). Phase 1 Evaluate early-returns.    |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_F_MQH
#define PHOENICISNEX_INPUTS_SLOT_F_MQH

input group "Slot F"
input bool   InpEnableSlotF        = true;    // Enable Slot F (CD-chain sub-call via BR-2.1/2.2; opens after CD entry)
input int    InpFMaxOrders         = 1;       // Max simultaneous F orders (comment-prefix "F,")
input double InpFLotReductionRatio = 0.7;     // Per-slot lot reduction vs CD parent (CodeWiki §5.3 OpenOrder "F" flag tier)
input double InpFSlPipsFloor       = 50.0;    // SL floor in pips for F entries (mirrors C tier)
input double InpFTpProfitPips      = 40.0;    // Minimum profit gate for exit in pips (mirrors C/D 40-pip gate)

#endif // PHOENICISNEX_INPUTS_SLOT_F_MQH
