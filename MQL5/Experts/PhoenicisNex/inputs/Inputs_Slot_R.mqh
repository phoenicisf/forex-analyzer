//+------------------------------------------------------------------+
//| Inputs_Slot_R.mqh — Slot R input parameters (IMPL-033)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_R = 213                                            |
//| Source:  CodeWiki §3 Slot R; TD-02 §5; BR-6.3 (R legacy timeout) |
//|                                                                   |
//| NOTE: InpLegacyRBars lives in Inputs_Pending.mqh (BR-6.3)        |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| M-size MVP — 3 of N CodeWiki §3.R conditions implemented;         |
//| advanced filters deferred to P4 IMPL-063+.                        |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_R_MQH
#define PHOENICISNEX_INPUTS_SLOT_R_MQH

input group "Slot R"
input bool   InpEnableSlotR          = true;    // Enable Slot R (RSI + ADX + retracement pending entry)
input int    InpRMaxOrders           = 1;       // Max simultaneous R orders (entry guard: no active R)
input double InpRBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.R CalculateLotSize)
input double InpRSlPipsFloor         = 50.0;    // SL floor in pips — minimum stop loss distance
input double InpRAdxMin              = 20.0;    // ADX minimum value for trend-dominance condition
input double InpRRsiOversold         = 35.0;    // RSI H4 oversold level for BUY signal (retracement gate)
input double InpRRsiOverbought       = 65.0;    // RSI H4 overbought level for SELL signal (retracement gate)
input double InpRTpProfitPips        = 40.0;    // Minimum profit gate for exit in pips (ManageExits)

#endif // PHOENICISNEX_INPUTS_SLOT_R_MQH
