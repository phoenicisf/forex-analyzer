//+------------------------------------------------------------------+
//| Inputs_Slot_S.mqh — per-slot input declarations for Slot S       |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   S — Magic 217 (MAGIC_S per domain/EnumTypes.mqh; own)     |
//| Source: CodeWiki §3.S; TD-02 §5.4; NFR-6.3 group annotation       |
//|                                                                   |
//| M-size MVP scope (5 of N CodeWiki §3.S conditions):               |
//|   1. Both L and K parents inactive (post-close proxy gate)        |
//|   2. Own no-active S guard                                        |
//|   3. ADX volatility gate (H4 ADX > InpSAdxMin)                    |
//|   4. WPR threshold confirmation (H4 WPR level)                    |
//|   5. D1 Ichimoku trend alignment filter                           |
//|   6. Profit gate exit (InpSTpProfitPips)                          |
//|                                                                   |
//| P4 deferred (IMPL-062):                                           |
//|   - Stochastic secondary confirmation (stoch_h4)                  |
//|   - Sub-demand zone proximity filter                               |
//|   - Hull MA slope gate                                             |
//|   - DeMarker secondary confirmation                                |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_S_MQH
#define PHOENICISNEX_INPUTS_SLOT_S_MQH

input group "Slot S"
input bool   InpEnableSlotS          = true;    // Enable Slot S (post-close after L or K)
input double InpSBaseLot             = 10.0;    // Base lot multiplier factor (CodeWiki §3.S post-close position)
input double InpSSlPips              = 60.0;    // Stop-loss in pips (CodeWiki §3.S baseline)
input double InpSTpProfitPips        = 35.0;    // Minimum profit gate for exit in pips
input int    InpSMaxOrders           = 1;       // Max simultaneous S orders
input double InpSAdxMin              = 20.0;    // ADX minimum threshold for volatility gate (H4)
input double InpSWprOversold         = -80.0;   // WPR oversold threshold for BUY signal (H4)
input double InpSWprOverbought       = -20.0;   // WPR overbought threshold for SELL signal (H4)
input double InpSPercentTp           = 10.0;    // percent_tp ∈ {5, 10, 15} per BR-4.1; default 10 per CodeWiki §3.S

#endif // PHOENICISNEX_INPUTS_SLOT_S_MQH
