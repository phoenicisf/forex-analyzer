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
input bool   InpEnableSlotT          = true;    // Enable Slot T (Hull/SubDem/BB% pending entry per §3.15)
input int    InpTMaxOrders           = 1;       // Max simultaneous T orders (entry guard: no active T)
input double InpTBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.T CalculateLotSize)
input double InpTSlPipsFloor         = 55.0;    // SL floor in pips — MVP backward-compat (preserves IMPL-035 default)
input double InpTAdxMin              = 22.0;    // ADX H4 minimum value for trend-dominance condition (§3.15:6)
input double InpTStochOversold       = 25.0;    // Stochastic H4 oversold level (legacy MVP — retained for E-AC compat)
input double InpTStochOverbought     = 75.0;    // Stochastic H4 overbought level (legacy MVP — retained for E-AC compat)
input double InpTTpProfitPips        = 45.0;    // Minimum profit gate for exit in pips (ManageExits)
input double InpTMacdSignalThresh    = 0.0;     // MACD M10 histogram threshold (legacy MVP — retained)

//--- IMPL-FIX-011 Session C — §3.15 4-sub-path inputs
input double InpTSlPipsCodeWikiFloor = 90.0;    // §3.15:9 SL floor (CodeWiki spec; supersedes 55-pip MVP for §3.15 path)
input double InpTBollBandPctBuy      = 5.0;     // §3.15:2 BUY support — BollBand% < this (price near lower band, range 0-100)
input double InpTBollBandPctSell     = 95.0;    // §3.15 mirror SELL resistance — BollBand% > this
input int    InpTBBHistWindow        = 10;      // §3.15:5 BB-history scan window (last N bars; ≤15 hard cap from MCB_BARS_BB_HIST)
input int    InpTBBHistMinAboveCount = 7;       // §3.15:5 minimum bars satisfying BBTop < IchiMax (BUY) / BBBot > IchiMin (SELL)
input double InpTDemThreshD          = 0.45;    // §3.15:7 DEM ≥ this → "D" (day) sub-path; else "H" (Hull) sub-path

#endif // PHOENICISNEX_INPUTS_SLOT_T_MQH
