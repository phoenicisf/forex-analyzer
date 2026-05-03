//+------------------------------------------------------------------+
//| Inputs_Slot_I.mqh — Slot I input parameters (IMPL-028)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_I = 216 (own; not shared)                          |
//| Source:  CodeWiki §3.I; TD-02 §5.4; NFR-6.3 group annotation     |
//|                                                                   |
//| Slot I — G-parasite Fibonacci:                                    |
//|   - Entry gated by G having an active open position               |
//|   - Fibonacci retracement entry (price retraced from G open)      |
//|   - Inherits direction from parent G order (BUY→BUY, SELL→SELL)  |
//|   - Shorter-horizon profit gate (25 pip vs G's 50)                |
//|   - DependsOn() returns 1 with out_magics[0]=MAGIC_G (topo dep)  |
//|                                                                   |
//| S-size MVP — 3 of N CodeWiki §3.I conditions:                     |
//|   1. Parasite gate: G must have active "G," order                 |
//|   2. Own-no-active guard: no existing "I," order                  |
//|   3. Direction inheritance from G parent + Fib retrace price gate |
//| Advanced filters (GPause / wave-span / ADX deferred) = P4 IMPL-062|
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_I_MQH
#define PHOENICISNEX_INPUTS_SLOT_I_MQH

input group "Slot I"
input bool   InpEnableSlotI        = true;   // Enable Slot I (G-parasite Fibonacci entry; MAGIC_I=216)
input int    InpIMaxOrders         = 1;      // Max simultaneous I orders (own "I," prefix)
input double InpIBaseLot           = 15.0;   // Base lot multiplier factor — lighter than G's (CodeWiki §3.I)
input double InpISlPips            = 60.0;   // Stop-loss floor in pips for I entry (CodeWiki §3.I)
input double InpITpProfitPips      = 25.0;   // Minimum profit gate for exit in pips — shorter-horizon than G's 50
input int    InpILookbackBars      = 20;     // Lookback bars for Fibonacci range high/low calculation
input double InpIFibLevel          = 0.5;    // Fibonacci retracement level gate (0.0–1.0; default 0.5 = 50% retrace)

#endif // PHOENICISNEX_INPUTS_SLOT_I_MQH
