//+------------------------------------------------------------------+
//| Inputs_Slot_M.mqh — Slot M input parameters (IMPL-029)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_M = 210                                            |
//| Source:  CodeWiki §3 Slot M; TD-02 §5; ADR-008 (M-Pending)        |
//|                                                                   |
//| NOTE: InpForceClearM_Bars lives in Inputs_Pending.mqh (ADR-008)  |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| M-size MVP — 5 of N CodeWiki §3.M conditions implemented;         |
//| advanced filters (M-Pause / MACD-D1 / WPR-wave / Bollinger exit  |
//|  / Hull-slope trailing) deferred to P4 IMPL-062.                  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_M_MQH
#define PHOENICISNEX_INPUTS_SLOT_M_MQH

input group "Slot M"
input bool   InpEnableSlotM          = true;    // Enable Slot M (MACD + ADX pending entry)
input int    InpMMaxOrders           = 1;       // Max simultaneous M orders (entry guard: no active M)
input double InpMBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.M CalculateLotSize)
input double InpMSlPipsFloor         = 50.0;    // SL floor in pips — minimum stop loss distance
input double InpMAdxMin              = 20.0;    // ADX minimum value for trend-dominance condition
input double InpMStochOversold       = 30.0;    // Stochastic H4 oversold level for BUY signal
input double InpMStochOverbought     = 70.0;    // Stochastic H4 overbought level for SELL signal
input double InpMTpProfitPips        = 40.0;    // Minimum profit gate for exit in pips (ManageExits)
input double InpMMacdSignalThresh    = 0.0;     // MACD M10 histogram threshold for momentum confirmation

#endif // PHOENICISNEX_INPUTS_SLOT_M_MQH
