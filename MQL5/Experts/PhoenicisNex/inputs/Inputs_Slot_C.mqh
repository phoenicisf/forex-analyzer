//+------------------------------------------------------------------+
//| Inputs_Slot_C.mqh — Slot C input parameters (IMPL-019)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_CD = 200 (shared with Slot D)                      |
//| Source:  CodeWiki §3 Slot C + §4; TD-02 §6; ADR-008 (C-Pending)   |
//|                                                                   |
//| NOTE: InpForceClearC_Bars lives in Inputs_Pending.mqh (ADR-008)  |
//|       InpLegacyCBars + InpLegacyCAdxBars also in Inputs_Pending  |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| M-size MVP — 5 of N CodeWiki §3.C conditions implemented;         |
//| advanced filters (C-ADX secondary machine / Bollinger inner-band  |
//|  / Ichimoku D1 cloud / WPR D1 wave / Hull H4 slope filter)        |
//|  deferred to P4 IMPL-062.                                         |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_C_MQH
#define PHOENICISNEX_INPUTS_SLOT_C_MQH

input group "Slot C"
input bool   InpEnableSlotC          = true;    // Enable Slot C (MACD + ADX + Stoch pending entry)
input int    InpCMaxOrders           = 1;       // Max simultaneous C orders (entry guard: no active C)
input double InpCBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.C CalculateLotSize)
input double InpCSlPipsFloor         = 50.0;    // SL floor in pips — minimum stop loss distance
input double InpCAdxMin              = 20.0;    // ADX minimum value for trend-dominance condition (CodeWiki §3.C)
input double InpCStochOversold       = 30.0;    // Stochastic H4 oversold level for BUY signal (CodeWiki §3.C)
input double InpCStochOverbought     = 70.0;    // Stochastic H4 overbought level for SELL signal (CodeWiki §3.C)
input double InpCTpProfitPips        = 40.0;    // Minimum profit gate for exit in pips (ManageExits)
input double InpCMacdSignalThresh    = 0.0;     // MACD M10 histogram threshold for momentum confirmation

#endif // PHOENICISNEX_INPUTS_SLOT_C_MQH
