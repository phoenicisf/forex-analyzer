//+------------------------------------------------------------------+
//| Inputs_Slot_H.mqh — Slot H input parameters (IMPL-023)           |
//| Layer:   inputs/                                                 |
//| Magic:   MAGIC_H = 205                                           |
//| NFR-6.3: group annotation "Slot H"; NFR-4.3: ≥ 5 inputs         |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_H_MQH
#define PHOENICISNEX_INPUTS_SLOT_H_MQH

input group "Slot H"
input bool   InpEnableSlotH         = true;   // Enable Slot H (Fractal + Ichimoku Distance)
input int    InpHMaxOrders          = 2;      // BR-1.1 max concurrent H orders
input int    InpHFractalLookback    = 3;      // Bars to look back for fractal alignment
input double InpHIchimokuMaxPips    = 35.0;   // Max Ichimoku cloud distance (pips) — CodeWiki §3.4 :2776
input double InpHBaseLot            = 15.0;   // Base lot size passed to RiskManager::ComputeLot
input double InpHSlPips             = 90.0;   // SL in pips passed to RiskManager::ComputeLot
input double InpHTpMinPips          = 30.0;   // Minimum profit gate for exit (pips) — CodeWiki §3.4
input int    InpHMaxAgeBars         = 8;      // Max order age in H4 bars before forced exit — CodeWiki §3.4

#endif // PHOENICISNEX_INPUTS_SLOT_H_MQH
