//+------------------------------------------------------------------+
//| Inputs_Slot_P.mqh — Slot P input parameters (IMPL-034)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_P = 218                                            |
//| Source:  CodeWiki §3.14 Slot P + §2.5 P_Extra; `04 § 4.4`;        |
//|          BR-6.4 (P legacy timeout); ADR-002.                      |
//|                                                                   |
//| NOTE: InpLegacyPBars lives in Inputs_Pending.mqh (BR-6.4).        |
//|       DO NOT redeclare here.                                      |
//|                                                                   |
//| L-size MVP — 4 sub-modes (PSUB_NONE/N/PX/PH/E) with simplified    |
//| decision branch using BB-distance proxy for `_diffSL` + Force[1]  |
//| fast-path gate. CodeWiki §3.14 advanced filter set (Hull          |
//| structure, recent-bar trigger lookback, band gating extremes,     |
//| Fibonacci pyramid lot calc) deferred to P4 IMPL-062 per A7 risk.  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_P_MQH
#define PHOENICISNEX_INPUTS_SLOT_P_MQH

input group "Slot P"
input bool   InpEnableSlotP          = true;    // Enable Slot P (Bollinger pending entry with PX/PH/E sub-modes)
input int    InpPMaxOrders           = 1;       // Max simultaneous P orders (entry guard: no active P)
input double InpPBaseLot             = 20.0;    // Base lot multiplier factor (CodeWiki §3.14 CalculateLotSize)
input double InpPSlPipsFloor         = 80.0;    // SL floor in pips — minimum stop loss distance (PH default)
input double InpPAdxMin              = 18.0;    // ADX H4 minimum value for trend-dominance condition
input double InpPForcePxGate         = 0.1;     // Force[1] f1 magnitude threshold for PX fast-path (`Force[1] > 0.1`)
input double InpPDiffSlPxThreshold   = 200.0;   // diff_sl pip threshold: ≥ 200 → PX, < 200 → PH (per `04 § 4.4`)
input double InpPTpPipsPx            = 7.0;     // TP profit gate (pips) for PX sub-mode (express path)
input double InpPTpPipsPh            = 15.0;    // TP profit gate (pips) for PH sub-mode (default)
input double InpPTpPipsE             = 25.0;    // TP profit gate (pips) for E (pyramid extension) sub-mode
input double InpPPyramidGatePips     = 30.0;    // Parent P profit (pips) required to spawn E-sub-mode pyramid

#endif // PHOENICISNEX_INPUTS_SLOT_P_MQH
