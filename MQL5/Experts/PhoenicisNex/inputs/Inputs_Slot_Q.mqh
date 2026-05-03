//+------------------------------------------------------------------+
//| Inputs_Slot_Q.mqh — Slot Q input parameters (IMPL-032)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_Q = 212                                            |
//| Source:  CodeWiki §3 Slot Q; TD-02 §5; ADR-008 (Q-Pending/OQ-A2) |
//|                                                                   |
//| NOTE: InpForceClearQ_Bars lives in Inputs_Pending.mqh (ADR-008)  |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| M-size MVP — 3 of N CodeWiki §3.Q conditions implemented;         |
//| advanced Q filters deferred to P4 IMPL-062+.                      |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_Q_MQH
#define PHOENICISNEX_INPUTS_SLOT_Q_MQH

input group "Slot Q"
input bool   InpEnableSlotQ          = true;    // Enable Slot Q (ADX+RSI+MACD pending entry)
input int    InpQMaxOrders           = 1;       // Max simultaneous Q orders (entry guard: no active Q)
input double InpQBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.Q CalculateLotSize)
input double InpQSlPipsFloor         = 50.0;    // SL floor in pips — minimum stop loss distance
input double InpQAdxMin              = 20.0;    // ADX H4 minimum value for trend-dominance condition
input double InpQRsiOversold         = 40.0;    // RSI H4 oversold level for BUY signal
input double InpQRsiOverbought       = 60.0;    // RSI H4 overbought level for SELL signal
input double InpQTpProfitPips        = 40.0;    // Minimum profit gate for exit in pips (ManageExits)
input double InpQMacdSignalThresh    = 0.0;     // MACD M10 histogram threshold for momentum confirmation

#endif // PHOENICISNEX_INPUTS_SLOT_Q_MQH
