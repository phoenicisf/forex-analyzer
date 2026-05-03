//+------------------------------------------------------------------+
//| Inputs_Slot_BI.mqh — per-slot input declarations for Slot BI     |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   BI — Magic MAGIC_B=214 (shared with parent B; comment    |
//|         disambig "BI," vs "B,")                                   |
//| Source: CodeWiki §3.19 Slot BI; ADR-009 (G4 SL inheritance fix); |
//|         TD-02 §5.4; NFR-6.3 group annotation                      |
//|                                                                  |
//| L-size MVP — header-only G4 SL fix scaffold:                      |
//|   BI = pyramid child of Slot B sharing MAGIC_B=214; comment "BI,"|
//|   ⚠️ G4 critical fix per ADR-009: BI orders open with SL inherited|
//|   from parent B's pip distance applied at BI entry price (NOT     |
//|   naked SL=0 per CodeWiki §6.2 :20326 :20357 baseline bug).      |
//|                                                                  |
//| Real activation: IMPL-053+ Composition Root + RiskManager        |
//|   OrderSend wiring + Tester run.                                  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_BI_MQH
#define PHOENICISNEX_INPUTS_SLOT_BI_MQH

input group "Slot BI"
input bool   InpEnableSlotBI         = true;   // Enable Slot BI (pyramid child of B; G4 SL fix per ADR-009)
input int    InpBIMaxOrders          = 1;      // Max simultaneous BI orders (comment-prefix "BI," only)
input double InpBIBaseLot            = 14.0;   // Base lot factor (lighter than parent B's 20.0 per pyramid tier)
input double InpBIPyramidGatePips    = 30.0;   // Parent B profit pips required before BI pyramid entry
input double InpBITpProfitPips       = 30.0;   // Minimum profit gate for BI exit (pyramid tier; lighter than B's 50)
input double InpBISlFallbackPips     = 80.0;   // Fallback SL pips if no B parent active or parent SL=0 (ADR-009 fallback)

#endif // PHOENICISNEX_INPUTS_SLOT_BI_MQH
