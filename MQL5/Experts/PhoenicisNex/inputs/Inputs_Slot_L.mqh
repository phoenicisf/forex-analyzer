//+------------------------------------------------------------------+
//| Inputs_Slot_L.mqh — per-slot input declarations for Slot L       |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   L — Magic 211 (MAGIC_L per domain/EnumTypes.mqh)          |
//|         MAGIC_L shared with LX (IMPL-031) — comment disambig "L," |
//| Source: CodeWiki §3.L; TD-02 §5.4; NFR-6.3 group annotation       |
//|                                                                  |
//| M-size MVP scope (5 of N CodeWiki §3.L conditions):              |
//|   1. No active L order guard                                      |
//|   2. WPR wave signal (wpr_wave_signal derived signal)             |
//|   3. Price location relative to Ichimoku cloud (D1 trend filter)  |
//|   4. ADX volatility gate (H4 ADX > threshold)                     |
//|   5. Profit gate exit (InpLTpProfitPips)                          |
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - LX pyramid trigger (IMPL-031)                                 |
//|   - Slot S post-close dependency (IMPL-036)                       |
//|   - Advanced sub-demand zone conditions                           |
//|   - DeMarker secondary confirmation                               |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_L_MQH
#define PHOENICISNEX_INPUTS_SLOT_L_MQH

input group "Slot L"
input bool   InpEnableSlotL          = true;   // Enable Slot L (WPR wave + Ichimoku trend)
input double InpLBaseLot             = 20.0;   // Base lot multiplier factor (CodeWiki §3.L CalculateLotSize base)
input double InpLSlPips              = 80.0;   // Stop-loss in pips (CodeWiki §3.L baseline)
input double InpLTpProfitPips        = 40.0;   // Minimum profit gate for exit in pips
input int    InpLMaxOrders           = 1;      // Max simultaneous L orders (comment-prefix disambig "L,")
input double InpLAdxThreshold        = 20.0;   // ADX minimum threshold for volatility gate (H4)
input double InpLWprOversold         = -80.0;  // WPR oversold threshold for BUY signal
input double InpLWprOverbought       = -20.0;  // WPR overbought threshold for SELL signal

#endif // PHOENICISNEX_INPUTS_SLOT_L_MQH
