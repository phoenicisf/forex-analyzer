//+------------------------------------------------------------------+
//| Inputs_General.mqh — cross-slot general inputs (FR-1.1)          |
//| CodeWiki §1.3 defaults; NFR-4.3 (≥80 total); NFR-6.3 group ann.  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_INPUTS_GENERAL_MQH
#define PHOENICISNEX_INPUTS_GENERAL_MQH

input group "General"
input double         InpInteruptRatioDecrease     = 8.0;       // Lot reduction divisor in EOverload — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpMainOverloadRatioDecrease = 4.0;       // Main overload divisor — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input bool           InpUseCOverload              = true;      // Enable COverload safety net — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input bool           InpUseOverloadAutoRange      = true;      // Auto wave range for overload — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input bool           InpOverLoadUseLastLot        = true;      // Reuse last lot in overload — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input int            InpFIDValue                  = 21;        // Force Index period (H4 + M2) — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input bool           InpTradeOnHNN                = false;     // Allow H slot in "NN" sub-mode — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input ENUM_TIMEFRAMES InpZigZagPeriod             = PERIOD_M5; // ZigZag timeframe — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpLADXMLevel                = 30.0;      // L slot ADX threshold — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpLADXMLevelMin             = 22.0;      // L slot ADX floor — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input int            InpJPip1StBetweenC           = -10;       // Min pip gap from C trade for J entry — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input int            InpJPip1StBetweenD           = -13;       // Min pip gap from D trade for J entry — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpFRatioDecrease            = 1.0;       // F slot lot scale — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpJRatioDecrease            = 2.3;       // J slot lot scale — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpGRatioDecrease            = 10.0;      // G slot lot scale — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpGORatioDecrease           = 10.0;      // GO slot lot scale — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpHRatioDecrease            = 10.0;      // H slot lot scale — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input int            InpGRisk                     = 15;        // G slot risk percent — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpMainRiskRatio             = 1.0;       // Risk denominator for GetSizeLot2 (LibCommon) — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input double         InpLimitMaxLotSizeRatio      = 2.9;       // Max lot pyramid cap (LibCommon) — CodeWiki §1.3 / FR-1.1 / NFR-4.3
input int            InpNormalTakeProfitPIP       = 48;        // Standard TP distance baseline (LibCommon) — CodeWiki §1.3 / FR-1.1 / NFR-4.3

#endif // PHOENICISNEX_INPUTS_GENERAL_MQH
