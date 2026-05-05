//+------------------------------------------------------------------+
//| BootstrapValidator.mqh เนโฌโ€ boot-time input range + invariant checks|
//| Layer:   core/                                                    |
//| Owner:   IMPL-015 (ValidateInputs) + IMPL-016 (ValidateSymbol)   |
//| Sources: TD-02 เธขเธ7.0.1 lines 1308-1341; FR-1.4; BR-4.1/4.2/4.3;  |
//|          BR-3.x; BR-9.1; BR-9.3; BR-1.1; ADR-005; ADR-011       |
//|                                                                   |
//| Design:  CBootstrapValidator is header-only. It references Inp*  |
//|          symbols (declared in inputs/*.mqh) that become visible   |
//|          when the entry .mq5 includes both input headers and this  |
//|          header. This file is intentionally non-compilable in     |
//|          isolation เนโฌโ€ header-only by design; G1 compile happens   |
//|          via the entry .mq5 build (production + spike paths     |
//|          both pull this through their respective include chain). |
//|                                                                   |
//| Error pattern (per ADR-011 boot-time bypass):                     |
//|   m_logger.ErrorBypassThrottle("system","invalid_input",0,msg)   |
//|   Grep: [Phoenicis]...[ev=invalid_input]                          |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_CORE_BOOTSTRAPVALIDATOR_MQH
#define PHOENICISNEX_CORE_BOOTSTRAPVALIDATOR_MQH

// Full include of Logger (needed to call ErrorBypassThrottle)
#include "../services/Logger.mqh"   // CLogger เนโฌโ€ IMPL-042 เนยโ€ฆ

// Full includes of all 4 cross-slot input files (Inp* symbol visibility)
// Services layer does not include inputs/ เนโฌโ€ but core/ may (orchestration layer).
// Per ADR-012 dependency direction: core เนยโ€ services เนยโ€ domain เนยโ€ helpers;
// core also orchestrates inputs (composition root pattern, TD-02 เธขเธ9.1).
#include "../inputs/Inputs_General.mqh"   // IMPL-012 เนยโ€ฆ
#include "../inputs/Inputs_TimeGates.mqh" // IMPL-012 เนยโ€ฆ
#include "../inputs/Inputs_Pending.mqh"   // IMPL-012 เนยโ€ฆ
#include "../inputs/Inputs_Logging.mqh"   // IMPL-012 เนยโ€ฆ

// Per-slot input headers needed for ValidateSlotInputs (R15 Finding 15.1).
// Only Inputs_Slot_S participates in the discrete-set check today; other
// per-slot inputs are continuous numerics already covered by Guards 1-39
// in ValidateInputs OR are slot-internal (no boot-time invariant).
#include "../inputs/Inputs_Slot_S.mqh"   // R15 15.1 เนโฌโ€ InpSPercentTp เนยย {5,10,15}

// Forward declarations เนโฌโ€ opaque pointers only; no deref in this file.
// Full class definitions land at IMPL-005 (IndicatorService) and IMPL-007
// (PortfolioState). ValidateInputs does NOT deref these pointers.
class CIndicatorService;
class CPortfolioState;

// EnumTypes provides IsPhoenicisMagicSelfTest() เนโฌโ€ header-only, invoked
// from RunDomainSelfTests below (per fix-round-14 เธขเธ 14.3).
#include "../domain/EnumTypes.mqh"

//+------------------------------------------------------------------+
//| CBootstrapValidator                                              |
//|                                                                  |
//| Verbatim class skeleton from TD-02 เธขเธ7.0.1 lines 1308-1341.      |
//| 4 public methods:                                                |
//|  เนโฌเธ ValidateInputs()      เนโฌโ€ FR-1.4 range checks (IMPL-015 owner) |
//|  เนโฌเธ ValidateSymbol()      เนโฌโ€ FR-1.2 + BR-9.1 (IMPL-016 owner)     |
//|  เนโฌเธ DetectDigitMultiplier()เนโฌโ€ BR-9.3 5-digit detect (stub)        |
//|  เนโฌเธ ValidateSlotRegistry()เนโฌโ€ BR-1.1 17-magic invariant (ADR-005)  |
//+------------------------------------------------------------------+
class CBootstrapValidator
  {
private:
   CLogger           *m_logger;      // injected; never NULL after Init
   CIndicatorService *m_indicators;  // opaque pointer เนโฌโ€ not deref'd in ValidateInputs
   CPortfolioState   *m_portfolio;   // opaque pointer เนโฌโ€ used only by ValidateSlotRegistry

public:
   //--- Composition-Root injection (TD-02 เธขเธ9.1; no service-locator)
   void Init(CLogger *lg, CIndicatorService *ind, CPortfolioState *port)
     {
      m_logger     = lg;
      m_indicators = ind;
      m_portfolio  = port;
     }

   //--- FR-1.4 เนโฌโ€ validate every Inp* range (IMPL-015)
   //    Returns false on first invalid input.
   //    Every violation logs via ErrorBypassThrottle (ADR-011 boot-time bypass เนโฌโ€
   //    boot-time alerts must NEVER be throttled per NFR-5.1 + security.md เธขเธHalt).
   //    Called from Orchestrator::Init Phase C (TD-02 เธขเธ7.4 line 1654):
   //      if (!m_validator.ValidateInputs()) return INIT_FAILED;
   //    CleanupPartialInit ownership: completed at Orchestrator wiring path (core/Orchestrator.mqh)
   //    per impl-plan.
   bool ValidateInputs() const;

   //--- FR-1.2 + BR-9.1 เนโฌโ€ symbol whitelist (IMPL-016 body; stub returns true)
   bool ValidateSymbol() const;

   //--- BR-9.3 เนโฌโ€ 5-digit broker autodetect (PipMath owns; validator gates)
   bool DetectDigitMultiplier() const;

   //--- BR-1.1 invariant เนโฌโ€ exactly 17 distinct magics (ADR-005)
   bool ValidateSlotRegistry(int observed_count, int expected_count) const;

   //--- fix-round-14 เธขเธ 14.3 เนโฌโ€ domain-SelfTest umbrella (currently wraps
   //    IsPhoenicisMagicSelfTest; future SelfTests for CommentParser /
   //    JsonWriter / etc. land here per XS-14.2 backlog).
   //
   //    Phase 1 caller: spike-only (Spike_Orchestrator already invokes
   //    IsPhoenicisMagicSelfTest directly; once the Orchestrator OnInit
   //    Phase B wire is added เนโฌโ€ Phase 2, Orchestrator wiring path (core/Orchestrator.mqh) / IMPL-062 owner เนโฌโ€
   //    that path will call this umbrella instead of the raw helper).
   //    Header-only method; no production caller yet. See EnumTypes.mqh
   //    เธขเธ "Wiring status" for the honest spike-vs-production matrix.
   bool RunDomainSelfTests() const;

   //--- R15 15.1 เนโฌโ€ per-slot input discrete-set / range invariants.
   //    Distinct from ValidateInputs (which targets cross-slot inputs in
   //    Inputs_General/TimeGates/Pending/Logging). Currently enforces:
   //      เนโฌเธ InpSPercentTp เนยย {5, 10, 15} per BR-4.1 (FIX-001 defense-in-depth)
   //    Future per-slot discrete-set inputs land here. Called from
   //    Orchestrator::OnInit Phase C between ValidateInputs and ValidateSymbol.
   bool ValidateSlotInputs() const;
  };

//+------------------------------------------------------------------+
//| ValidateInputs เนโฌโ€ FR-1.4 range checks (เนยเธ…30 fail-fast guards)     |
//|                                                                  |
//| Guard count: 39 individual if-blocks (matches body Guards 1..39).|
//|                                                                  |
//| Input sources:                                                    |
//|  Inputs_General.mqh  เนโฌโ€ 21 inputs; 16 validatable (5 bool/enum   |
//|                         skipped); yields 17 if-blocks (incl.    |
//|                         relational LADX floor < threshold)      |
//|  Inputs_TimeGates.mqhเนโฌโ€ 11 inputs; all int, yields 11 if-blocks  |
//|  Inputs_Pending.mqh  เนโฌโ€ 8  inputs; all int, yields 8 if-blocks   |
//|  Inputs_Logging.mqh  เนโฌโ€ 3  inputs; 1 bool skipped; yields 3 if-  |
//|                         blocks (LogLevel low, LogLevel high,     |
//|                         EscalationN)                             |
//|                         Total: 17 + 11 + 8 + 3 = 39              |
//|                                                                  |
//| Fail-fast: return false on the first violated guard.             |
//| No batch collection of all errors (per shared-context เธขเธ6.C.2).  |
//+------------------------------------------------------------------+
bool CBootstrapValidator::ValidateInputs() const
  {
   // ================================================================
   // SECTION 1 เนโฌโ€ Inputs_General.mqh (FR-1.4 + BR-4.1/4.2/4.3)
   // ================================================================

   // Guard 1: InpInteruptRatioDecrease เนโฌโ€ lot reduction divisor (>0, เนยเธ100)
   // Ratio denominator: zero or negative => division-by-zero risk in EOverload
   if(InpInteruptRatioDecrease <= 0.0 || InpInteruptRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpInteruptRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpInteruptRatioDecrease));
      return false;
     }

   // Guard 2: InpMainOverloadRatioDecrease เนโฌโ€ main overload divisor (>0, เนยเธ100)
   if(InpMainOverloadRatioDecrease <= 0.0 || InpMainOverloadRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpMainOverloadRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpMainOverloadRatioDecrease));
      return false;
     }

   // Guard 3: InpFIDValue เนโฌโ€ Force Index period (>0, เนยเธ10000) per FR-1.4
   if(InpFIDValue <= 0 || InpFIDValue > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpFIDValue=%d (expected > 0 and <= 10000)", InpFIDValue));
      return false;
     }

   // Guard 4: InpLADXMLevel เนโฌโ€ L slot ADX threshold (>0, เนยเธ100)
   // ADX is always in range 0..100; threshold must be positive
   if(InpLADXMLevel <= 0.0 || InpLADXMLevel > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLADXMLevel=%.4f (expected > 0.0 and <= 100.0)", InpLADXMLevel));
      return false;
     }

   // Guard 5: InpLADXMLevelMin เนโฌโ€ L slot ADX floor (>0, เนยเธ100)
   if(InpLADXMLevelMin <= 0.0 || InpLADXMLevelMin > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLADXMLevelMin=%.4f (expected > 0.0 and <= 100.0)", InpLADXMLevelMin));
      return false;
     }

   // Guard 6: InpLADXMLevelMin < InpLADXMLevel (floor must be below threshold)
   if(InpLADXMLevelMin >= InpLADXMLevel)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLADXMLevelMin=%.4f must be < InpLADXMLevel=%.4f",
                      InpLADXMLevelMin, InpLADXMLevel));
      return false;
     }

   // Guard 7: InpJPip1StBetweenC เนโฌโ€ may be negative (min pip gap from C; default=-10)
   // Relax lower bound to -1000 per directive เธขเธImplementation directives
   if(InpJPip1StBetweenC < -1000 || InpJPip1StBetweenC > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpJPip1StBetweenC=%d (expected >= -1000 and <= 10000)",
                      InpJPip1StBetweenC));
      return false;
     }

   // Guard 8: InpJPip1StBetweenD เนโฌโ€ may be negative (min pip gap from D; default=-13)
   if(InpJPip1StBetweenD < -1000 || InpJPip1StBetweenD > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpJPip1StBetweenD=%d (expected >= -1000 and <= 10000)",
                      InpJPip1StBetweenD));
      return false;
     }

   // Guard 9: InpFRatioDecrease เนโฌโ€ F slot lot scale (>0, เนยเธ100)
   if(InpFRatioDecrease <= 0.0 || InpFRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpFRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpFRatioDecrease));
      return false;
     }

   // Guard 10: InpJRatioDecrease เนโฌโ€ J slot lot scale (>0, เนยเธ100)
   if(InpJRatioDecrease <= 0.0 || InpJRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpJRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpJRatioDecrease));
      return false;
     }

   // Guard 11: InpGRatioDecrease เนโฌโ€ G slot lot scale (>0, เนยเธ100)
   if(InpGRatioDecrease <= 0.0 || InpGRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpGRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpGRatioDecrease));
      return false;
     }

   // Guard 12: InpGORatioDecrease เนโฌโ€ GO slot lot scale (>0, เนยเธ100)
   if(InpGORatioDecrease <= 0.0 || InpGORatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpGORatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpGORatioDecrease));
      return false;
     }

   // Guard 13: InpHRatioDecrease เนโฌโ€ H slot lot scale (>0, เนยเธ100)
   if(InpHRatioDecrease <= 0.0 || InpHRatioDecrease > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpHRatioDecrease=%.4f (expected > 0.0 and <= 100.0)",
                      InpHRatioDecrease));
      return false;
     }

   // Guard 14: InpGRisk เนโฌโ€ G slot risk percent (>0, เนยเธ10000)
   if(InpGRisk <= 0 || InpGRisk > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpGRisk=%d (expected > 0 and <= 10000)", InpGRisk));
      return false;
     }

   // Guard 15: InpMainRiskRatio เนโฌโ€ risk denominator; special BR-4.1 range (0.0, 10.0]
   if(InpMainRiskRatio <= 0.0 || InpMainRiskRatio > 10.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpMainRiskRatio=%.4f (expected > 0.0 and <= 10.0 per BR-4.1)",
                      InpMainRiskRatio));
      return false;
     }

   // Guard 16: InpLimitMaxLotSizeRatio เนโฌโ€ max lot pyramid cap; BR-4.2 range (0.0, 100.0]
   if(InpLimitMaxLotSizeRatio <= 0.0 || InpLimitMaxLotSizeRatio > 100.0)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLimitMaxLotSizeRatio=%.4f (expected > 0.0 and <= 100.0 per BR-4.2)",
                      InpLimitMaxLotSizeRatio));
      return false;
     }

   // Guard 17: InpNormalTakeProfitPIP เนโฌโ€ TP distance baseline (>0, เนยเธ10000)
   if(InpNormalTakeProfitPIP <= 0 || InpNormalTakeProfitPIP > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpNormalTakeProfitPIP=%d (expected > 0 and <= 10000)",
                      InpNormalTakeProfitPIP));
      return false;
     }

   // ================================================================
   // SECTION 2 เนโฌโ€ Inputs_TimeGates.mqh (BR-3.x time gate checks)
   // ================================================================

   // Guard 18: InpMorningWindowMinutes เนโฌโ€ BR-3.1 (>0, เนยเธ10000)
   // Zero minutes means no morning window เนโฌโ€ explicitly invalid (gate would never open)
   if(InpMorningWindowMinutes <= 0 || InpMorningWindowMinutes > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpMorningWindowMinutes=%d (expected > 0 and <= 10000 per BR-3.1)",
                      InpMorningWindowMinutes));
      return false;
     }

   // Guard 19: InpMondaySpreadThreshold เนโฌโ€ BR-3.2 / BR-3.7 spread threshold (>0, เนยเธ10000)
   if(InpMondaySpreadThreshold <= 0 || InpMondaySpreadThreshold > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpMondaySpreadThreshold=%d (expected > 0 and <= 10000 per BR-3.2/3.7)",
                      InpMondaySpreadThreshold));
      return false;
     }

   // Guard 20: InpHolidayStartMonth เนโฌโ€ BR-3.3 (1..12)
   if(InpHolidayStartMonth < 1 || InpHolidayStartMonth > 12)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpHolidayStartMonth=%d (expected 1..12 per BR-3.3)",
                      InpHolidayStartMonth));
      return false;
     }

   // Guard 21: InpHolidayStartDay เนโฌโ€ BR-3.3 (1..31)
   if(InpHolidayStartDay < 1 || InpHolidayStartDay > 31)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpHolidayStartDay=%d (expected 1..31 per BR-3.3)",
                      InpHolidayStartDay));
      return false;
     }

   // Guard 22: InpHolidayEndMonth เนโฌโ€ BR-3.3 (1..12)
   if(InpHolidayEndMonth < 1 || InpHolidayEndMonth > 12)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpHolidayEndMonth=%d (expected 1..12 per BR-3.3)",
                      InpHolidayEndMonth));
      return false;
     }

   // Guard 23: InpHolidayEndDay เนโฌโ€ BR-3.3 (1..31)
   if(InpHolidayEndDay < 1 || InpHolidayEndDay > 31)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpHolidayEndDay=%d (expected 1..31 per BR-3.3)",
                      InpHolidayEndDay));
      return false;
     }

   // Guard 24: InpBanCCooldownBars เนโฌโ€ BR-3.4 slot C cooldown (>0, เนยเธ10000)
   if(InpBanCCooldownBars <= 0 || InpBanCCooldownBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpBanCCooldownBars=%d (expected > 0 and <= 10000 per BR-3.4)",
                      InpBanCCooldownBars));
      return false;
     }

   // Guard 25: InpBanLCooldownBars เนโฌโ€ BR-3.4 slot L cooldown (>0, เนยเธ10000)
   if(InpBanLCooldownBars <= 0 || InpBanLCooldownBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpBanLCooldownBars=%d (expected > 0 and <= 10000 per BR-3.4)",
                      InpBanLCooldownBars));
      return false;
     }

   // Guard 26: InpBanMCooldownBars เนโฌโ€ BR-3.4 slot M cooldown (>0, เนยเธ10000)
   if(InpBanMCooldownBars <= 0 || InpBanMCooldownBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpBanMCooldownBars=%d (expected > 0 and <= 10000 per BR-3.4)",
                      InpBanMCooldownBars));
      return false;
     }

   // Guard 27: InpKLastOrderCooldownBars เนโฌโ€ BR-3.4 slot K cooldown (>0, เนยเธ10000)
   if(InpKLastOrderCooldownBars <= 0 || InpKLastOrderCooldownBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpKLastOrderCooldownBars=%d (expected > 0 and <= 10000 per BR-3.4)",
                      InpKLastOrderCooldownBars));
      return false;
     }

   // Guard 28: InpGPauseCooldownBars เนโฌโ€ BR-3.4 slot G pause cooldown (>0, เนยเธ10000)
   if(InpGPauseCooldownBars <= 0 || InpGPauseCooldownBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpGPauseCooldownBars=%d (expected > 0 and <= 10000 per BR-3.4)",
                      InpGPauseCooldownBars));
      return false;
     }

   // ================================================================
   // SECTION 3 เนโฌโ€ Inputs_Pending.mqh (ADR-008 force-clear thresholds)
   // ================================================================

   // Guard 29: InpForceClearM_Bars เนโฌโ€ ADR-008 slot M pending timeout (>0, เนยเธ10000)
   if(InpForceClearM_Bars <= 0 || InpForceClearM_Bars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpForceClearM_Bars=%d (expected > 0 and <= 10000 per ADR-008)",
                      InpForceClearM_Bars));
      return false;
     }

   // Guard 30: InpForceClearT_Bars เนโฌโ€ ADR-008 slot T pending timeout (>0, เนยเธ10000)
   if(InpForceClearT_Bars <= 0 || InpForceClearT_Bars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpForceClearT_Bars=%d (expected > 0 and <= 10000 per ADR-008)",
                      InpForceClearT_Bars));
      return false;
     }

   // Guard 31: InpForceClearQ_Bars เนโฌโ€ ADR-008 slot Q pending timeout (>0, เนยเธ10000)
   if(InpForceClearQ_Bars <= 0 || InpForceClearQ_Bars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpForceClearQ_Bars=%d (expected > 0 and <= 10000 per ADR-008)",
                      InpForceClearQ_Bars));
      return false;
     }

   // Guard 32: InpLegacyCBars เนโฌโ€ BR-6.1 slot C pending timeout (>0, เนยเธ10000)
   if(InpLegacyCBars <= 0 || InpLegacyCBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLegacyCBars=%d (expected > 0 and <= 10000 per BR-6.1)",
                      InpLegacyCBars));
      return false;
     }

   // Guard 33: InpLegacyCAdxBars เนโฌโ€ BR-6.2 slot C-ADX pending timeout (>0, เนยเธ10000)
   if(InpLegacyCAdxBars <= 0 || InpLegacyCAdxBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLegacyCAdxBars=%d (expected > 0 and <= 10000 per BR-6.2)",
                      InpLegacyCAdxBars));
      return false;
     }

   // Guard 34: InpLegacyRBars เนโฌโ€ BR-6.3 slot R pending timeout (>0, เนยเธ10000)
   if(InpLegacyRBars <= 0 || InpLegacyRBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLegacyRBars=%d (expected > 0 and <= 10000 per BR-6.3)",
                      InpLegacyRBars));
      return false;
     }

   // Guard 35: InpLegacyPBars เนโฌโ€ BR-6.4 slot P pending timeout (>0, เนยเธ10000)
   if(InpLegacyPBars <= 0 || InpLegacyPBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLegacyPBars=%d (expected > 0 and <= 10000 per BR-6.4)",
                      InpLegacyPBars));
      return false;
     }

   // Guard 36: InpLegacyForceBars เนโฌโ€ BR-6.8 force-pending workflow timeout (>0, เนยเธ10000)
   if(InpLegacyForceBars <= 0 || InpLegacyForceBars > 10000)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLegacyForceBars=%d (expected > 0 and <= 10000 per BR-6.8)",
                      InpLegacyForceBars));
      return false;
     }

   // ================================================================
   // SECTION 4 เนโฌโ€ Inputs_Logging.mqh (ADR-011 logger config)
   // ================================================================

   // Guard 37: InpLogLevel lower bound เนโฌโ€ must be >= LOG_DEBUG (0)
   // ESeverity enum: LOG_DEBUG=0, LOG_INFO=1, LOG_WARN=2, LOG_ERROR=3
   if(InpLogLevel < (int)LOG_DEBUG)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLogLevel=%d (expected >= %d = LOG_DEBUG per ADR-011)",
                      InpLogLevel, (int)LOG_DEBUG));
      return false;
     }

   // Guard 38: InpLogLevel upper bound เนโฌโ€ must be <= LOG_ERROR (3)
   if(InpLogLevel > (int)LOG_ERROR)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpLogLevel=%d (expected <= %d = LOG_ERROR per ADR-011)",
                      InpLogLevel, (int)LOG_ERROR));
      return false;
     }

   // Guard 39: InpErrorEscalationN เนโฌโ€ consecutive-error threshold (>= 1 per ADR-011)
   // Zero would disable escalation entirely เนโฌโ€ not permitted
   if(InpErrorEscalationN < 1)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpErrorEscalationN=%d (expected >= 1 per ADR-011)",
                      InpErrorEscalationN));
      return false;
     }

   // ================================================================
   // All guards passed
   // ================================================================
   return true;
  }

//+------------------------------------------------------------------+
//| ValidateSymbol เนโฌโ€ FR-1.2 + BR-9.1 EURUSD whitelist               |
//|                                                                  |
//| Rejects any chart symbol other than "EURUSD". Called from        |
//| Orchestrator OnInit Phase B (step 2) before any slot or service  |
//| init. On rejection: ErrorBypassThrottle (ADR-011 boot bypass) +  |
//| Alert() native popup (NFR-5.1) + return false เนยโ€ INIT_FAILED.    |
//| (Implemented IMPL-016)                                           |
//+------------------------------------------------------------------+
bool CBootstrapValidator::ValidateSymbol() const
  {
   if(_Symbol != "EURUSD")
     {
      string msg = StringFormat("symbol=%s expected=EURUSD (FR-1.2 + BR-9.1)", _Symbol);
      m_logger.ErrorBypassThrottle("system", "symbol_not_whitelist", 0, msg);
      Alert("PhoenicisNex requires EURUSD เนโฌโ€ current chart symbol is " + _Symbol);
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| DetectDigitMultiplier เนโฌโ€ BR-9.3 5-digit broker autodetect        |
//|                                                                  |
//| PipMath (helpers/PipMath.mqh) owns the actual digit detection.  |
//| This validator gates at boot time: if PipMath detects an         |
//| unsupported digit mode it returns false. Currently stub.         |
//|                                                                  |
//| TODO IMPL-007-or-pip: wire PipMath::IsValid5Digit() here.       |
//+------------------------------------------------------------------+
bool CBootstrapValidator::DetectDigitMultiplier() const
  {
   // TODO IMPL-007-or-pip: BR-9.3 5-digit autodetect (PipMath owns this; validator just gates)
   return true;
  }

//+------------------------------------------------------------------+
//| ValidateSlotRegistry เนโฌโ€ BR-1.1 invariant: exactly 17 distinct    |
//| magics registered (ADR-005 CHashMap<int,SlotState*> pool).       |
//|                                                                  |
//| Called from Orchestrator after PortfolioState::RegisterAll():    |
//|   if (!m_validator.ValidateSlotRegistry(m_portfolio.MagicCount(),|
//|                                         17)) return INIT_FAILED; |
//| (TD-02 เธขเธ7.4; orchestrator owner = Orchestrator wiring path (core/Orchestrator.mqh))                    |
//+------------------------------------------------------------------+
bool CBootstrapValidator::ValidateSlotRegistry(int observed_count,
                                               int expected_count) const
  {
   if(observed_count != expected_count)
     {
      m_logger.ErrorBypassThrottle("system", "slot_registry_invariant", 0,
         StringFormat("observed=%d expected=%d (BR-1.1 17-magic per ADR-005)",
                      observed_count, expected_count));
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| RunDomainSelfTests เนโฌโ€ umbrella for domain-layer SelfTests          |
//|                                                                  |
//| Currently wraps IsPhoenicisMagicSelfTest (per fix-round-13 เธขเธ 13.6 |
//| body + fix-round-14 เธขเธ 14.3 wiring honesty).                       |
//|                                                                  |
//| Caller contract:                                                  |
//|   - Phase 1: spike harnesses already invoke the underlying tests  |
//|     directly (Spike_Orchestrator เนยโ€ IsPhoenicisMagicSelfTest);     |
//|     this umbrella exists so Phase 2 production OnInit can call    |
//|     the umbrella once instead of N separate SelfTests.            |
//|   - Phase 2: Orchestrator::OnInit Phase B step 1 will call:       |
//|         if(!m_validator.RunDomainSelfTests()) return INIT_FAILED; |
//|     before ValidateSymbol. (Owner: Orchestrator wiring path (core/Orchestrator.mqh) / IMPL-062.)     |
//|                                                                  |
//| Failure path: per-SelfTest body Prints `[SelfTest][FAIL] เนโฌเธ` lines |
//| identifying which case failed; this method emits one              |
//| ErrorBypassThrottle so the boot-time alert path also fires        |
//| (NFR-5.1 + ADR-011 boot-time bypass).                             |
//+------------------------------------------------------------------+
bool CBootstrapValidator::RunDomainSelfTests() const
  {
   if(!IsPhoenicisMagicSelfTest())
     {
      m_logger.ErrorBypassThrottle("system", "domain_selftest_fail", 0,
         "IsPhoenicisMagicSelfTest reported one or more failures เนโฌโ€"
         " see prior [EnumTypes][SelfTest][FAIL] lines");
      return false;
     }
   //--- room for future SelfTests (CommentParser / JsonWriter / etc.)
   //    per XS-14.2 backlog (Phase 2 IMPL-NNN bulk wire-up).
   return true;
  }

//+------------------------------------------------------------------+
//| ValidateSlotInputs เนโฌโ€ per-slot input discrete-set / range checks   |
//|                                                                  |
//| Defense-in-depth against operator-driven regression of FIX-001    |
//| defect class (per-tick `[ev=s_pct_tp_invalid]` ERROR + zero-lot   |
//| Slot S orders) when MT5 input dialog or Strategy Tester           |
//| optimization sweep sets InpSPercentTp outside the BR-4.1 set       |
//| {5, 10, 15} (per R15 Finding 15.1).                                |
//|                                                                  |
//| Tolerance 0.001 mirrors RiskManager::_ComputeLotForS consumer at   |
//| services/RiskManager.mqh:402-415 เนโฌโ€ keep in sync if either side     |
//| changes.                                                          |
//|                                                                  |
//| Fail path (consistent with ValidateInputs Guard pattern):         |
//|   ErrorBypassThrottle("system","invalid_input",0,เนโฌเธ) per ADR-011  |
//|   boot-time bypass + return false เนยโ€ Orchestrator INIT_FAILED.     |
//+------------------------------------------------------------------+
bool CBootstrapValidator::ValidateSlotInputs() const
  {
   // R15 15.1 เนโฌโ€ InpSPercentTp must be one of {5, 10, 15} per BR-4.1.
   if(MathAbs(InpSPercentTp - 5.0)  >= 0.001 &&
      MathAbs(InpSPercentTp - 10.0) >= 0.001 &&
      MathAbs(InpSPercentTp - 15.0) >= 0.001)
     {
      m_logger.ErrorBypassThrottle("system", "invalid_input", 0,
         StringFormat("InpSPercentTp=%.4f outside valid set {5,10,15} per BR-4.1; "
                      "Slot S would emit s_pct_tp_invalid every tick + "
                      "non-functional (FIX-001 defect class regression)",
                      InpSPercentTp));
      return false;
     }
   //--- room for future per-slot discrete-set inputs (XS-15.1 Phase-2 audit).
   return true;
  }

#endif // PHOENICISNEX_CORE_BOOTSTRAPVALIDATOR_MQH
