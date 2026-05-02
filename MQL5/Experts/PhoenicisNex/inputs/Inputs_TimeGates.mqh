//+------------------------------------------------------------------+
//| Inputs_TimeGates.mqh — time gate cross-slot inputs (BR-3.x)      |
//| TD-02 §5.9 CTimeGate::Init params; NFR-6.3 group annotation       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_TIMEGATES_MQH
#define PHOENICISNEX_INPUTS_TIMEGATES_MQH

input group "TimeGates"
input int InpMorningWindowMinutes   = 5;   // BR-3.1 — minutes after 00:00 broker time (EET)
input int InpMondaySpreadThreshold  = 10;  // BR-3.2 / BR-3.7 — spread threshold in points for Monday gate
input int InpHolidayStartMonth      = 12;  // BR-3.3 — holiday blackout start month (Dec)
input int InpHolidayStartDay        = 21;  // BR-3.3 — holiday blackout start day
input int InpHolidayEndMonth        = 1;   // BR-3.3 — holiday blackout end month (Jan)
input int InpHolidayEndDay          = 3;   // BR-3.3 — holiday blackout end day
input int InpBanCCooldownBars       = 5;   // BR-3.4 — slot C cooldown in H4 bars after ban event
input int InpBanLCooldownBars       = 5;   // BR-3.4 — slot L cooldown in H4 bars after ban event
input int InpBanMCooldownBars       = 5;   // BR-3.4 — slot M cooldown in H4 bars after ban event
input int InpKLastOrderCooldownBars = 4;   // BR-3.4 — slot K last-order cooldown in H4 bars
input int InpGPauseCooldownBars     = 3;   // BR-3.4 — slot G pause cooldown in H4 bars

#endif // PHOENICISNEX_INPUTS_TIMEGATES_MQH
