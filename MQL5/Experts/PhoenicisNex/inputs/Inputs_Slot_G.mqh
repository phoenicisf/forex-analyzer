//+------------------------------------------------------------------+
//| Inputs_Slot_G.mqh — Slot G input parameters (IMPL-025)           |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_G = 208 (shared with G2; disambiguation via "G,")  |
//| Source:  CodeWiki §3.6; TD-02 §5.4; NFR-6.3 group annotation      |
//|                                                                   |
//| P4 deferred items (IMPL-062):                                     |
//|   - GPause / NewYear / Force-peak-exhaustion conditions            |
//|   - WPR-sanity filter                                             |
//|   - Bollinger-touch precision exit (advanced trail)               |
//|   - DeMarker filter                                               |
//|   - Force-wave-span conditions                                    |
//|   - Pending-lot scaling (*0.7 when pending state)                 |
//|                                                                   |
//| NOTE: TriggerGOverload BR-8.4 stub wired here; real coordinator   |
//|       implementation = IMPL-053 (CCrossSlotCoordinator P4).       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_G_MQH
#define PHOENICISNEX_INPUTS_SLOT_G_MQH

input group "Slot G"
input bool   InpEnableSlotG         = true;    // Enable Slot G (Force crossover + Ichimoku + ADX + Stoch)
input int    InpGMaxOrders          = 1;       // Max simultaneous G orders (entry condition 1 — no active G)
input double InpGBaseLot            = 30.0;    // Base lot multiplier factor (CodeWiki §3.6 CalculateLotSize base)
input double InpGSlPipsFloor        = 61.8;    // SL floor in pips — Fibonacci 61.8 minimum (CodeWiki §3.6)
input double InpGFICrossThreshHigh  = 0.0;     // Force Index threshold: F[1]>this for BUY cross (CodeWiki §3.6)
input double InpGFICrossThreshLow   = -0.2;    // Force Index threshold: F[3]<this for BUY confirmation
input double InpGFICrossAltHigh     = 1.0;     // Force Index alternate: F[1]>this for alternate BUY
input double InpGFICrossAltLow      = -3.0;    // Force Index alternate: F[2] lower bound for alt-BUY range
input double InpGAdxDominanceMin    = 20.0;    // ADX minimum value for dominance condition (CodeWiki §3.6:4)
input double InpGStochOversold      = 25.0;    // Stochastic oversold level for BUY (CodeWiki §3.6:5)
input double InpGStochOverbought    = 75.0;    // Stochastic overbought level for SELL (CodeWiki §3.6:5)
input double InpGTpProfitPips       = 50.0;    // Minimum profit gate for exit in pips (CodeWiki §3.6)
input double InpGOverloadForceMin   = 15.0;    // Force threshold to trigger GOverload — BR-8.4 (stub)
input double InpGOverloadAdxMin     = 49.0;    // ADX threshold to trigger GOverload — BR-8.4 (stub)
input double InpGOverloadMaxOffset  = 20.0;    // Min maxOffset pip to trigger GOverload — BR-8.4 (stub)

//--- IMPL-FIX-011 Session C — §3.6:9/11/12 history-based predicates
input int    InpGForcePeakMaxAbove11 = 3;      // §3.6:9 ≤ this many bars in 8-bar window with |Force|>11 (peaks not exhausted)
input int    InpGBBHistWindow        = 15;     // §3.6:11 BB-history scan window (last N bars; ≤15 hard cap)
input int    InpGBBHistMinBelow      = 1;      // §3.6:11 minimum bars satisfying BBTop < IchiMax (BUY) — Phase-1 conservative; legacy "any 15-bar BBTop<IchiMax presence" at min ≥1
input double InpGDemRollingThreshBuy = 175.0;  // §3.6:12 BUY pending if rolling DEM sum × 100 ≥ this
input double InpGDemRollingThreshSell= 25.0;   // §3.6:12 SELL pending if rolling DEM sum × 100 ≤ this

#endif // PHOENICISNEX_INPUTS_SLOT_G_MQH
