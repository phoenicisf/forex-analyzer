//+------------------------------------------------------------------+
//| Inputs_Slot_T.mqh — Slot T input parameters (IMPL-035)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_T = 219                                            |
//| Source:  CodeWiki §3 Slot T; TD-02 §5; ADR-008 (T-Pending)        |
//|                                                                   |
//| NOTE: InpForceClearT_Bars lives in Inputs_Pending.mqh (ADR-008)  |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| M-size MVP — 3 of N CodeWiki §3.T conditions implemented;         |
//| advanced filters deferred to P4 IMPL-062+.                        |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_T_MQH
#define PHOENICISNEX_INPUTS_SLOT_T_MQH

input group "Slot T"
input bool   InpEnableSlotT          = true;    // Enable Slot T (MACD + ADX pending entry)
input int    InpTMaxOrders           = 1;       // Max simultaneous T orders (entry guard: no active T)
input double InpTBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.T CalculateLotSize)
input double InpTSlPipsFloor         = 55.0;    // SL floor in pips — minimum stop loss distance
input double InpTAdxMin              = 22.0;    // ADX H4 minimum value for trend-dominance condition
input double InpTStochOversold       = 25.0;    // Stochastic H4 oversold level for BUY signal
input double InpTStochOverbought     = 75.0;    // Stochastic H4 overbought level for SELL signal
input double InpTTpProfitPips        = 45.0;    // Minimum profit gate for exit in pips (ManageExits)
input double InpTMacdSignalThresh    = 0.0;     // MACD M10 histogram threshold for momentum confirmation

#endif // PHOENICISNEX_INPUTS_SLOT_T_MQH
