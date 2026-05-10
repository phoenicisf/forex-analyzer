//+------------------------------------------------------------------+
//| Inputs_Slot_G2.mqh — Slot G2 input parameters (IMPL-026)         |
//| Layer:   inputs/ (no service deps — pure input declarations)      |
//| Magic:   MAGIC_G = 208 (shared with G; disambiguation via "G2,") |
//| Source:  CodeWiki §3.G2; TD-02 §5.4; NFR-6.3 group annotation    |
//|                                                                   |
//| G2 wave-helper role (lighter than G):                             |
//|   - Smaller base lot factor (20.0 vs G's 30.0)                    |
//|   - Narrower Force crossover window (continuation range only)     |
//|   - Lighter profit gate (30 pip default vs G's 50)                |
//|   - Fewer entry conditions (3-4 of N vs G's 5 of 13)             |
//|                                                                   |
//| M-size MVP — 3 of CodeWiki §3.G2 conditions; advanced filters    |
//|   (GPause / WPR / DeMarker / wave-span exhaustion) deferred to    |
//|   P4 IMPL-062.                                                    |
//|                                                                   |
//| NOTE: CommentParser disambig from "G," is internal (not topo).    |
//|       DependsOn() returns 0 — independent slot topology.          |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_G2_MQH
#define PHOENICISNEX_INPUTS_SLOT_G2_MQH

input group "Slot G2"
input bool   InpEnableSlotG2           = true;   // Enable Slot G2 (lighter wave-helper; shared MAGIC_G=208)
input int    InpG2MaxOrders            = 1;      // Max simultaneous G2 orders (comment-prefix disambig "G2,")
input double InpG2BaseLot              = 20.0;   // Base lot multiplier factor — lighter than G's 30.0 (CodeWiki §3.G2)
input double InpG2SlPipsFloor          = 50.0;   // SL floor in pips — lighter floor than G's 61.8 (CodeWiki §3.G2)
input double InpG2FIContinuationMin    = 0.0;    // Force Index min for continuation range BUY signal (F[1]>this)
input double InpG2FIContinuationLow    = -0.2;   // Force Index: F[2] must be in continuation range > this
input double InpG2TpProfitPips         = 30.0;   // Minimum profit gate for exit in pips — lighter than G's 50

//--- IMPL-FIX-011 Session C — §3.7:5/6/9 history-based predicates
input int    InpG2ForceMinAbove02BUY   = 5;      // §3.7:6 BUY: ≥ this many of last 8 bars with Force > +0.2
input int    InpG2ForceMinAbove02Sell  = 5;      // §3.7:6 SELL mirror: ≥ this many of last 8 bars with Force < -0.2
input int    InpG2ForceTroughIdxLow    = 2;      // §3.7:9 trough scan window low bound (bars-back inclusive)
input int    InpG2ForceTroughIdxHigh   = 5;      // §3.7:9 trough scan window high bound (bars-back exclusive)
input double InpG2ForceTroughThreshBuy = -0.2;   // §3.7:9 BUY: ≥1 bar in [2,5) with Force ≤ this (reversal trough)
input double InpG2ForceTroughThreshSell= 0.2;    // §3.7:9 SELL mirror: ≥1 bar in [2,5) with Force ≥ this

#endif // PHOENICISNEX_INPUTS_SLOT_G2_MQH
