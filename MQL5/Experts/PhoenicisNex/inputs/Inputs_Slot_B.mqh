//+------------------------------------------------------------------+
//| Inputs_Slot_B.mqh — per-slot input declarations for Slot B       |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   B — Magic 214 (MAGIC_B per domain/EnumTypes.mqh)          |
//|         MAGIC_B shared with BI (IMPL-039) — comment disambig "B," |
//|         BR (IMPL-038) is orphan exit-only spawn; uses MAGIC_BR=215|
//| Source: CodeWiki §3.17 Slot B; TD-02 §5.4; NFR-6.3 group annot.   |
//|                                                                  |
//| L-size MVP scope (5 of 11 CodeWiki §3.17 conditions):            |
//|   1. No active B order guard (comment-prefix "B," excludes BI/BR) |
//|   2. ADX volatility gate (H4 ADX > threshold)                     |
//|   3. Cloud distance ≤ InpBCloudDistMaxPips                        |
//|   4. Fractal alignment in lookback window                         |
//|   5. Direction proxy: bid vs Ichimoku tenkan/kijun lowMain/highMain
//|                                                                  |
//| P4 deferred (IMPL-062):                                          |
//|   - !IsADXPeakValid anti-trend gate (CheckADXWithForcePeakValid2) |
//|   - ≤1 G/I sell counter-position guard                            |
//|   - Fractal count <3 + ADXMain dominance <3 bars                  |
//|   - Ichimoku wave-start bar count                                  |
//|   - SL = min(lowest wave bar, BBBot, lowMain)                     |
//|   - TP percentage = 20 + tpplus(SL-vs-cloud)                      |
//|   - 8-branch ExtraTakeProfit_B exit cascade                       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_B_MQH
#define PHOENICISNEX_INPUTS_SLOT_B_MQH

input group "Slot B"
input bool   InpEnableSlotB          = true;   // Enable Slot B (anti-trend fractal + cloud distance)
input double InpBBaseLot             = 20.0;   // Base lot factor (CodeWiki §3.17 CalculateLotSize base)
input double InpBSlPips              = 80.0;   // Stop-loss in pips (parent SL distance — IMPL-039 BI inherits)
input double InpBTpProfitPips        = 50.0;   // Minimum profit gate for exit in pips
input int    InpBMaxOrders           = 1;      // Max simultaneous B orders (comment-prefix "B," only)
input double InpBAdxThreshold        = 18.0;   // H4 ADX minimum for volatility gate
input double InpBCloudDistMaxPips    = 180.0;  // Cloud distance ceiling per CodeWiki §3.17 cond 4
input int    InpBFractalLookback     = 12;     // Bars to scan for fractal alignment (cond 5)

#endif // PHOENICISNEX_INPUTS_SLOT_B_MQH
