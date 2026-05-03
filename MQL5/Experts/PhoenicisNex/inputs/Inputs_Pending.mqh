//+------------------------------------------------------------------+
//| Inputs_Pending.mqh — pending state machine inputs (ADR-008)       |
//| TD-02 §5.10 CPendingMachineRegistry::Init params; NFR-6.3 group   |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_PENDING_MQH
#define PHOENICISNEX_INPUTS_PENDING_MQH

input group "Pending"
input int InpForceClearC_Bars  = 100;  // ADR-008 force-clear C-Pending (H4 bars)
input int InpForceClearM_Bars  = 150;  // ADR-008 — force-clear threshold for slot M pending (H4 bars)
input int InpForceClearT_Bars  = 80;   // ADR-008 — force-clear threshold for slot T pending (H4 bars)
input int InpForceClearQ_Bars  = 100;  // ADR-008 — force-clear threshold for slot Q pending (H4 bars)
input int InpLegacyCBars       = 8;    // BR-6.1 — legacy timeout for slot C pending (H4 bars)
input int InpLegacyCAdxBars    = 30;   // BR-6.2 — legacy timeout for slot C-ADX pending (H4 bars)
input int InpLegacyRBars       = 40;   // BR-6.3 — legacy timeout for slot R pending (H4 bars)
input int InpLegacyPBars       = 70;   // BR-6.4 — legacy timeout for slot P pending (H4 bars)
input int InpLegacyForceBars   = 9;    // BR-6.8 — legacy timeout for force-pending workflow (H4 bars)

#endif // PHOENICISNEX_INPUTS_PENDING_MQH
