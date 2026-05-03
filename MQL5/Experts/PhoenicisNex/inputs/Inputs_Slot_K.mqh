//+------------------------------------------------------------------+
//| Inputs_Slot_K.mqh — per-slot input declarations for Slot K       |
//| Layer:  inputs/ (no service deps — pure input declarations)       |
//| Slot:   K — Magic 207 (MAGIC_K per domain/EnumTypes.mqh)          |
//| Source: CodeWiki §3.5; TD-02 §5.4; NFR-6.3 group annotation       |
//|                                                                  |
//| P4 deferred items (IMPL-036):                                    |
//|   - Tenkan/Kijun secondary layer conditions                       |
//|   - 2hr C-pending cooldown                                        |
//|   - KExtra pyramiding inputs                                      |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_SLOT_K_MQH
#define PHOENICISNEX_INPUTS_SLOT_K_MQH

input group "Slot K"
input bool   InpEnableSlotK         = true;   // Enable Slot K (Force crossover D1 once-per-day)
input double InpKBaseLot            = 15.0;   // Base lot multiplier factor (CodeWiki §3.5 CalculateLotSize base)
input double InpKSlPips             = 90.0;   // Stop-loss in pips (CodeWiki §3.5 baseline)
input double InpKTpProfitPips       = 20.0;   // Minimum profit gate for exit in pips (CodeWiki §3.5 exit condition 1)
input int    InpKMaxOrders          = 1;      // Max simultaneous K orders (CodeWiki §3.5 entry condition 1)
input double InpKFICrossThreshHigh  = 0.5;    // Force Index threshold: F[1]>this for primary BUY cross (CodeWiki §3.5 isFICrossUp)
input double InpKFICrossThreshLow   = -0.2;   // Force Index threshold: F[3]<this for BUY confirmation (CodeWiki §3.5 isFICrossUp)
input double InpKFICrossAltHigh     = 1.0;    // Force Index alternate threshold: F[1]>this for alternate BUY (CodeWiki §3.5 isFICrossUp)

#endif // PHOENICISNEX_INPUTS_SLOT_K_MQH
