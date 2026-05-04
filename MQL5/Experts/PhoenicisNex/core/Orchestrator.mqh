//+------------------------------------------------------------------+
//| core/Orchestrator.mqh — composition root + OnInit + OnTick F1   |
//| Layer:   core/                                                    |
//| Owner:   IMPL-059                                                 |
//| Sources: TD-02 §7.1 lines 1439-1491 (skeleton)                   |
//|          TD-02 §7.2 lines 1493-1576 (OnTick F1 14-step pipeline) |
//|          TD-02 §7.3 lines 1578-1611 (DI wire-up table)           |
//|          TD-02 §7.4 lines 1612-1683 (OnInit Phase A/B/C)         |
//|          TD-02 §7.4.1 lines 1685-1735 (CleanupPartialInit)       |
//|          ADR-002 (composition root + constructor injection)      |
//|          ADR-010 (HALTED state machine + enable matrix)          |
//|          ADR-012 (5-layer dependency direction)                  |
//|          Claim 01.3 (m_xslot.SetHalted before RunExitPass)       |
//|          Claim 02.10 (CleanupPartialInit at 8 INIT_FAILED sites) |
//|                                                                   |
//| Header-only by design — Orchestrator is consumed by entry .mq5   |
//| (IMPL-060) AND by spike harness (Spike_Orchestrator.mq5). Per    |
//| BootstrapValidator + SlotRegistry precedent, this header expects |
//| Inp* symbols + service classes to be visible at point of expand. |
//|                                                                   |
//| Spec deviations vs TD-02 §7.4 (logged here to honor "Plan text > |
//| skeleton text" Plan QA precedent — IMPL-053 banner pattern):     |
//|                                                                   |
//|  D-1 MarketContextBuilder.Init takes (ind, lg) — TD shows (ind)  |
//|      only. Wired both deps (matches actual signature).            |
//|  D-2 CircuitBreaker.CheckPingPong() takes zero args — TD shows   |
//|      (port, tick_time). Implementation uses current state    |
//|      internally; OnTick still routes Halt() on positive return.  |
//|  D-3 CrossSlotCoordinator.Init takes (port, tj, lg, pip) — TD    |
//|      shows m_risk as 4th arg. Service-actual wins; pip enables  |
//|      pip-arithmetic for SafePort weak-metric thresholds.        |
//|  D-4 PendingMachineRegistry.Init takes 11 params (8 ints + state |
//|      + journal + logger; no portfolio). TD §7.4 listed portfolio |
//|      as 12th param. Service-actual wins.                         |
//|  D-5 TradeJournal.SetHaltSink(IHaltSink*) added after EAState    |
//|      Init — wires CEAState (which implements IHaltSink) into TJ |
//|      so journal sustained-failure path can call back into halt.  |
//|      Not in TD-02 §7.4 explicit pseudo-code; inferred from      |
//|      IHaltSink.mqh + TradeJournal.SetHaltSink existence.         |
//|                                                                   |
//| Error pattern (per ADR-011 boot-time bypass):                     |
//|   m_logger.ErrorBypassThrottle("system","init_failed_cleanup",0, |
//|                                failure_reason)                    |
//|   Grep: [Phoenicis]...[ev=init_failed_cleanup]                    |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_CORE_ORCHESTRATOR_MQH
#define PHOENICISNEX_CORE_ORCHESTRATOR_MQH

//--- Domain
#include "../domain/EnumTypes.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/SlotState.mqh"
#include "../domain/IHaltSink.mqh"
#include "../domain/CSlotBase.mqh"

//--- Helpers (stateless utilities; no Init() per TD-02 §4)
#include "../helpers/PipMath.mqh"
#include "../helpers/CommentParser.mqh"
#include "../helpers/JsonWriter.mqh"
#include "../helpers/AtomicFile.mqh"

//--- Services
#include "../services/Logger.mqh"
#include "../services/IndicatorService.mqh"
#include "../services/MarketContextBuilder.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/RiskManager.mqh"
#include "../services/TradeJournal.mqh"
#include "../services/StatePersistence.mqh"
#include "../services/CircuitBreaker.mqh"
#include "../services/TimeGate.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../services/CrossSlotCoordinator.mqh"
#include "../services/PortfolioMonitor.mqh"

//--- Core (peer modules)
#include "BootstrapValidator.mqh"
#include "SlotRegistry.mqh"
#include "EAState.mqh"

//--- Inputs (Composition Root pattern owns Inp* visibility — ADR-012)
#include "../inputs/Inputs_General.mqh"
#include "../inputs/Inputs_TimeGates.mqh"
#include "../inputs/Inputs_Pending.mqh"
#include "../inputs/Inputs_Logging.mqh"

//+------------------------------------------------------------------+
//| class COrchestrator — composition root                           |
//|                                                                  |
//| Owns 16 services + 4 helpers + 4 core + 21 derived slots         |
//| (slots owned by m_registry per § 7.0.2). All heap-allocated in   |
//| WireServices / WireSlots; reverse-order release in CleanupPartial|
//| Init (Phase C fail) or OnDeinit (normal shutdown).               |
//+------------------------------------------------------------------+
class COrchestrator
  {
private:
   //--- Helpers (step 2-3 in DI table)
   CPipMath                 *m_pip;             // step 2
   CCommentParser           *m_comment_parser;  // step 3 (helpers row)
   CJsonWriter              *m_json_writer;     // step 3
   CAtomicFile              *m_atomic;          // step 3

   //--- Services (16 total per § 7.3)
   CLogger                  *m_logger;       // step 1
   CStatePersistence        *m_state;        // step 4
   CPortfolioState          *m_portfolio;    // step 5
   CIndicatorService        *m_indicators;   // step 6
   CMarketContextBuilder    *m_ctx_builder;  // step 7
   CRiskManager             *m_risk;         // step 8
   CTradeJournal            *m_journal;      // step 9
   CCircuitBreaker          *m_breaker;      // step 10
   CTimeGate                *m_time;         // step 11
   CPendingMachineRegistry  *m_pending;      // step 12
   CCrossSlotCoordinator    *m_xslot;        // step 13
   CPortfolioMonitor        *m_monitor;      // step 14

   //--- Core peers (steps 15-17)
   CBootstrapValidator      *m_validator;    // step 15
   CSlotRegistry            *m_registry;     // step 16
   CEAState                 *m_ea_state;     // step 17

   //--- Cached EAState mirrors — single-writer (Halt()); read-only elsewhere.
   //    Updated inside Halt() so OnTick branch checks (steps 5b, 11, 13)
   //    avoid pointer indirection through m_ea_state.GetState() per tick.
   EEAState                  m_state_enum;
   string                    m_halt_reason;

public:
                     COrchestrator()
      : m_pip(NULL), m_comment_parser(NULL), m_json_writer(NULL), m_atomic(NULL),
        m_logger(NULL), m_state(NULL), m_portfolio(NULL), m_indicators(NULL),
        m_ctx_builder(NULL), m_risk(NULL), m_journal(NULL), m_breaker(NULL),
        m_time(NULL), m_pending(NULL), m_xslot(NULL), m_monitor(NULL),
        m_validator(NULL), m_registry(NULL), m_ea_state(NULL),
        m_state_enum(EA_STATE_RUNNING), m_halt_reason("")
     {}

                    ~COrchestrator()
     {
      // Defensive: if OnDeinit was not called (rare — MT5 lifecycle
      // ensures OnDeinit on INIT_SUCCEEDED), CleanupPartialInit covers
      // the leak surface.
      CleanupPartialInit("dtor_fallback");
     }

   //--- MT5 lifecycle entry points (called from PhoenicisNex.mq5 IMPL-060)
   int               OnInit();
   void              OnTick();
   void              OnDeinit(const int reason);
   double            OnTester();

   //--- Test harness accessor — Spike_Orchestrator.mq5 inspects state
   //    after OnInit / Phase C fail to assert cleanup ordering.
   EEAState          GetStateEnum() const { return m_state_enum; }
   string            GetHaltReason() const { return m_halt_reason; }
   bool              IsLoggerLive() const { return m_logger != NULL; }
   bool              IsRegistryLive() const { return m_registry != NULL; }

private:
   //--- Phase A — heap-construct everything (no Init yet)
   void              WireServices();

   //--- Phase A continued — heap-construct 21 slots via SlotRegistry
   bool              WireSlots();

   //--- TD-02 §7.4.1 — reverse-order release at all 8 INIT_FAILED sites
   void              CleanupPartialInit(string failure_reason);

   //--- Halt() helper — delegates to CEAState.Halt + updates cached mirrors.
   //    Called from OnTick steps 4 (CB), 5 (handle invalid), 13b (journal halt).
   void              Halt(string reason);

   //--- OnTick sub-passes (TD-02 §7.2 lines 1533-1548)
   void              RunExitPass(const MarketContext &ctx);
   void              RunEntryPass(const MarketContext &ctx);

   //--- HALTED-aware entry pass guard. Returns true ⇒ skip RunEntryPass.
   bool              ShouldSkipEntryPass(const MarketContext &ctx,
                                         bool monday_block, bool holiday_block) const
     {
      if(m_state_enum != EA_STATE_RUNNING) return true;
      if(monday_block || holiday_block)   return true;
      return false;
     }
  };

//+------------------------------------------------------------------+
//| OnInit — 3-phase composition root                                |
//|   Phase A: WireServices + WireSlots (heap construction only)     |
//|   Phase B: 16 service Init() + 2 cycle setters (steps 4a + 5a)   |
//|   Phase C: 8 validation/recovery guards; each on fail invokes    |
//|            CleanupPartialInit + returns INIT_FAILED              |
//+------------------------------------------------------------------+
int COrchestrator::OnInit()
  {
   // === Phase A — heap construction ============================
   WireServices();
   if(!WireSlots())
     {
      // SlotRegistry::Init failed or one of 21 ctor allocations
      // returned NULL. Cleanup whatever was already wired.
      CleanupPartialInit("wire_slots_alloc_fail");
      return INIT_FAILED;
     }

   // === Phase B — Init in dependency order (TD-02 §7.3) ==========
   m_logger.Init((ESeverity)InpLogLevel, InpAlertOnError, InpErrorEscalationN);   // step 1
   m_pip.Init();                                                                  // step 2 (BR-9.3 5-digit auto)
   // step 3 — helpers (CCommentParser/CJsonWriter/CAtomicFile) = stateless,
   //          no Init() per TD-02 §4 (Claim 02.2). Constructed in WireServices.
   m_state.Init(m_atomic, m_logger);                                              // step 4
   m_logger.SetStatePersistence(m_state);                                          // step 4a — Cycle 1 close
   m_portfolio.Init(m_logger);                                                     // step 5
   m_state.SetPortfolioState(m_portfolio);                                         // step 5a — Cycle 2 close
   m_indicators.Init(m_logger);                                                    // step 6
   m_ctx_builder.Init(m_indicators, m_logger);                                     // step 7  (D-1)
   m_risk.Init(InpMainRiskRatio, InpLimitMaxLotSizeRatio, m_portfolio, m_logger);  // step 8
   m_journal.Init(m_ctx_builder, m_portfolio, m_logger, m_state);                  // step 9
   m_breaker.Init(m_logger);                                                        // step 10
   m_time.Init(InpMorningWindowMinutes, InpMondaySpreadThreshold,
               InpHolidayStartMonth, InpHolidayStartDay,
               InpHolidayEndMonth, InpHolidayEndDay,
               InpBanCCooldownBars, InpBanLCooldownBars, InpBanMCooldownBars,
               InpKLastOrderCooldownBars, InpGPauseCooldownBars,
               m_pip, m_state, m_logger);                                          // step 11
   m_pending.Init(InpForceClearM_Bars, InpForceClearT_Bars, InpForceClearQ_Bars,
                  InpLegacyCBars, InpLegacyCAdxBars, InpLegacyRBars,
                  InpLegacyPBars, InpLegacyForceBars,
                  m_state, m_journal, m_logger);                                   // step 12 (D-4)
   m_xslot.Init(m_portfolio, m_journal, m_logger, m_pip);                          // step 13 (D-3)
   m_monitor.Init(m_state, m_logger);                                              // step 14
   m_validator.Init(m_logger, m_indicators, m_portfolio);                          // step 15
   m_registry.Init(m_logger);                                                       // step 16
   m_ea_state.Init(m_journal, m_logger);                                            // step 17

   // D-5 — wire CEAState as TradeJournal halt-sink (CEAState : IHaltSink).
   //   Lets TradeJournal.WriteEvent route sustained-failure callbacks back
   //   into the central halt machine without circular include.
   m_journal.SetHaltSink(m_ea_state);

   // === Phase C — validation + recovery (8 guards, each with Cleanup) ==
   if(!m_validator.ValidateInputs())
     { CleanupPartialInit("validate_inputs");        return INIT_FAILED; }
   if(!m_validator.ValidateSymbol())
     { CleanupPartialInit("validate_symbol");        return INIT_FAILED; }
   if(!m_validator.DetectDigitMultiplier())
     { CleanupPartialInit("detect_digit_multiplier"); return INIT_FAILED; }

   // ADR-007 § Recovery — wipe orphan .tmp left by mid-write crash.
   m_atomic.CleanupOrphanTmp(m_state.StatePath(), m_logger);

   if(!m_indicators.CreateHandles())
     { CleanupPartialInit("indicator_handles");      return INIT_FAILED; }

   // state.json load — degrade-but-continue on corrupt (per § 7.4 line 1659).
   if(!m_state.Load(m_state_enum, m_halt_reason))
     {
      m_logger.Warn("system", "state_corrupt_starting_fresh", 0,
                    "GV-recovery attempted for watch_profits subset (per 02 § 6.1.1)");
      m_state_enum = EA_STATE_RUNNING;
      m_halt_reason = "";
     }

   // PortfolioState population: pre-allocate 17 SlotState entries, then reconcile vs broker.
   m_portfolio.RegisterAll();
   m_portfolio.Refresh();

   // Restore CEAState from loaded state.json + apply ADR-010 idle-reset.
   m_ea_state.RestoreFromState(m_state_enum, m_halt_reason,
                               m_portfolio.TotalActivePositions());
   m_state_enum  = m_ea_state.GetState();
   m_halt_reason = m_ea_state.GetHaltReason();

   if(!m_validator.ValidateSlotRegistry(m_portfolio.MagicCount(), 17))
     { CleanupPartialInit("slot_registry_invariant"); return INIT_FAILED; }

   if(!m_registry.RegisterAll(m_indicators, m_risk, m_journal, m_logger,
                              m_state, m_portfolio, m_pending, m_xslot))
     { CleanupPartialInit("slot_register_all");      return INIT_FAILED; }

   // Round-06 06.1 — wire CPipMath into every slot post-RegisterAll
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.SetPipMath(m_pip);
     }

   if(!m_registry.ValidateTopo())
     { CleanupPartialInit("slot_validate_topo");     return INIT_FAILED; }

   if(!m_journal.Open())
     { CleanupPartialInit("journal_open");           return INIT_FAILED; }

   m_logger.Info("system", "init_ok", 0,
                 StringFormat("handles=%d slots=%d magics=%d state=%s",
                              m_indicators.HandleCount(),
                              m_registry.Count(),
                              m_portfolio.MagicCount(),
                              EnumToString(m_state_enum)));
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| WireServices — Phase A heap construction                         |
//+------------------------------------------------------------------+
void COrchestrator::WireServices()
  {
   // Construction order = DI table § 7.3 step 1 → 17. Helpers (step 3)
   // bundled together; no Init() needed (stateless utilities).
   if(m_logger          == NULL) m_logger          = new CLogger();
   if(m_pip             == NULL) m_pip             = new CPipMath();
   if(m_comment_parser  == NULL) m_comment_parser  = new CCommentParser();
   if(m_json_writer     == NULL) m_json_writer     = new CJsonWriter();
   if(m_atomic          == NULL) m_atomic          = new CAtomicFile();
   if(m_state           == NULL) m_state           = new CStatePersistence();
   if(m_portfolio       == NULL) m_portfolio       = new CPortfolioState();
   if(m_indicators      == NULL) m_indicators      = new CIndicatorService();
   if(m_ctx_builder     == NULL) m_ctx_builder     = new CMarketContextBuilder();
   if(m_risk            == NULL) m_risk            = new CRiskManager();
   if(m_journal         == NULL) m_journal         = new CTradeJournal();
   if(m_breaker         == NULL) m_breaker         = new CCircuitBreaker();
   if(m_time            == NULL) m_time            = new CTimeGate();
   if(m_pending         == NULL) m_pending         = new CPendingMachineRegistry();
   if(m_xslot           == NULL) m_xslot           = new CCrossSlotCoordinator();
   if(m_monitor         == NULL) m_monitor         = new CPortfolioMonitor();
   if(m_validator       == NULL) m_validator       = new CBootstrapValidator();
   if(m_registry        == NULL) m_registry        = new CSlotRegistry();
   if(m_ea_state        == NULL) m_ea_state        = new CEAState();
  }

//+------------------------------------------------------------------+
//| WireSlots — delegates to SlotRegistry::RegisterAll                |
//|                                                                  |
//| The 21-slot heap allocation lives inside SlotRegistry per ADR-002|
//| (slot lifecycle owner). Orchestrator only confirms registry      |
//| object exists; actual slot ctors fire during RegisterAll which   |
//| is called from Phase C after services are Init'd (slots need     |
//| service pointers at Init).                                       |
//+------------------------------------------------------------------+
bool COrchestrator::WireSlots()
  {
   // SlotRegistry was constructed in WireServices. All other prep work
   // (slot heap-news + Init + SetPipMath) happens inside Phase C call to
   // m_registry.RegisterAll(...). This stub returns true so Phase A/B can
   // proceed; failure surface is in Phase C if RegisterAll returns false.
   return (m_registry != NULL);
  }

//+------------------------------------------------------------------+
//| CleanupPartialInit — TD-02 §7.4.1 reverse-order release          |
//|                                                                  |
//| MT5 lifecycle: INIT_FAILED skips OnDeinit. We must release every  |
//| heap allocation + open handle before returning INIT_FAILED to    |
//| avoid leaks across re-attach cycles.                              |
//|                                                                  |
//| Order: monotonic descent step 17 → 1. Logger released LAST so    |
//| ErrorBypassThrottle visibility survives the body.                 |
//+------------------------------------------------------------------+
void COrchestrator::CleanupPartialInit(string failure_reason)
  {
   // Step 0 — emit failure reason BEFORE we tear down logger.
   if(m_logger != NULL)
      m_logger.ErrorBypassThrottle("system", "init_failed_cleanup", 0, failure_reason);

   if(m_ea_state != NULL)
     { delete m_ea_state;       m_ea_state       = NULL; }   // step 17

   if(m_registry != NULL)
     {
      m_registry.ReleaseAll();
      delete m_registry;
      m_registry = NULL;
     }                                                        // step 16

   if(m_validator != NULL)
     { delete m_validator;      m_validator      = NULL; }   // step 15
   if(m_monitor != NULL)
     { delete m_monitor;        m_monitor        = NULL; }   // step 14
   if(m_xslot != NULL)
     { delete m_xslot;          m_xslot          = NULL; }   // step 13
   if(m_pending != NULL)
     { delete m_pending;        m_pending        = NULL; }   // step 12
   if(m_time != NULL)
     { delete m_time;           m_time           = NULL; }   // step 11
   if(m_breaker != NULL)
     { delete m_breaker;        m_breaker        = NULL; }   // step 10

   if(m_journal != NULL)
     {
      m_journal.Close();
      delete m_journal;
      m_journal = NULL;
     }                                                        // step 9

   if(m_risk != NULL)
     { delete m_risk;           m_risk           = NULL; }   // step 8
   if(m_ctx_builder != NULL)
     { delete m_ctx_builder;    m_ctx_builder    = NULL; }   // step 7

   if(m_indicators != NULL)
     {
      m_indicators.ReleaseHandles();
      delete m_indicators;
      m_indicators = NULL;
     }                                                        // step 6

   if(m_portfolio != NULL)
     {
      m_portfolio.ReleaseAll();
      delete m_portfolio;
      m_portfolio = NULL;
     }                                                        // step 5

   if(m_state != NULL)
     { delete m_state;          m_state          = NULL; }   // step 4

   // Helpers (step 3) — no Release/Close; just delete.
   if(m_atomic != NULL)
     { delete m_atomic;         m_atomic         = NULL; }
   if(m_json_writer != NULL)
     { delete m_json_writer;    m_json_writer    = NULL; }
   if(m_comment_parser != NULL)
     { delete m_comment_parser; m_comment_parser = NULL; }

   if(m_pip != NULL)
     { delete m_pip;            m_pip            = NULL; }   // step 2

   // Logger released LAST — required above for ErrorBypassThrottle visibility
   if(m_logger != NULL)
     { delete m_logger;         m_logger         = NULL; }   // step 1
  }

//+------------------------------------------------------------------+
//| OnTick — F1 14-step pipeline (TD-02 §7.2)                         |
//+------------------------------------------------------------------+
void COrchestrator::OnTick()
  {
   // 1. Refresh indicator buffers (~200 µs)
   m_indicators.Refresh();

   // 2. Build per-tick MarketContext snapshot (~50 µs)
   MarketContext ctx = m_ctx_builder.Build();

   // 3. Logger tick boundary (throttle window)
   m_logger.OnTickBoundary();

   // 4. CircuitBreaker check (D-2 — zero-arg signature)
   if(m_breaker.CheckPingPong())
      Halt("circuit_breaker_pingpong");
      // fall through to exit pass

   // 5. Indicator runtime fail-fast
   if(m_indicators.AnyHandleInvalid())
      Halt("handle_invalid_runtime");

   // 5b. SYNC HALTED STATE — must precede RunExitPass per ADR-010 enable
   //     matrix (Claim 01.3 fix). Slot.ManageExits → post-exit hooks read
   //     m_xslot.m_halted; setting after ExitPass would violate matrix.
   m_xslot.SetHalted(m_state_enum != EA_STATE_RUNNING);

   // 6. Time gates (cheap)
   bool morning_block = m_time.IsMorningWakeup(ctx.tick_time);
   bool monday_block  = false;
   bool holiday_block = false;
   if(!morning_block)
     {
      monday_block = m_time.IsMondaySpreadHigh(ctx.tick_time,
                        (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));

      // 7. PortfolioState refresh (~100 µs)
      m_portfolio.Refresh();

      // 8. PendingMachineRegistry tick (force-clear emits journal+log if triggered)
      m_pending.TickAll(ctx);

      // 9. EXIT PASS (always runs — even in HALTED per ADR-010; m_xslot.m_halted
      //    already correct from step 5b).
      RunExitPass(ctx);
      m_xslot.RunForceCutloss(ctx);
      m_xslot.ExtraCheckFunction2();
      m_xslot.RunSafePort(ctx);
      m_xslot.RunOrderGroup2(ctx);
      m_xslot.RunCOverload(ctx);

      // 10. Holiday block (after exit pass; before entry pass)
      holiday_block = m_time.HolidayBlock(ctx.tick_time, *m_portfolio);

      // 11. ENTRY PASS (skip in HALTED or any time-block)
      if(!ShouldSkipEntryPass(ctx, monday_block, holiday_block))
        {
         RunEntryPass(ctx);
         m_xslot.RunEOverload(ctx);
        }
     }

   // === housekeeping (always runs, even when morning_block forced skip) ===

   // 12. PortfolioMonitor (~30 µs)
   m_monitor.Update(AccountInfoDouble(ACCOUNT_EQUITY), ctx.tick_time);

   // 13. StatePersistence atomic save (~800 µs)
   m_state.Save(m_state_enum, m_halt_reason);

   // 13b. Journal sustained-failure halt check (ADR-006 RPO contract — Claim 01.8)
   int consecutive_journal_fails = 0;
   if(m_state_enum == EA_STATE_RUNNING &&
      m_journal.ShouldHaltSustained(consecutive_journal_fails))
     {
      Halt("journal_write_fail_sustained");
     }

   // 14. HALTED → HALTED_STABLE transition (ADR-010 + AC-7.7.4)
   if(m_ea_state.TryTransitionToStable(m_portfolio.TotalActivePositions()))
     {
      // Cached mirror update + summary Alert with throttled-count digest
      m_state_enum = m_ea_state.GetState();
      Alert(StringFormat("PhoenicisNex halted_stable + %d throttled alerts cumulative — check Experts log",
                         m_state.GetLoggerThrottledCount()));
     }
  }

//+------------------------------------------------------------------+
//| Halt — central halt entry point (cached-mirror update)           |
//+------------------------------------------------------------------+
void COrchestrator::Halt(string reason)
  {
   if(m_ea_state == NULL) return;
   m_ea_state.Halt(reason);
   m_state_enum  = m_ea_state.GetState();
   m_halt_reason = m_ea_state.GetHaltReason();
  }

//+------------------------------------------------------------------+
//| RunExitPass — invoke ManageExits across 21 slots in BR-2.2 order |
//+------------------------------------------------------------------+
void COrchestrator::RunExitPass(const MarketContext &ctx)
  {
   // Note: ManageExits(CPortfolioState&) per CSlotBase contract (no ctx arg).
   //   ctx is plumbed into RunExitPass for symmetry with RunEntryPass +
   //   future use (e.g. context-dependent exit policies). MQL5 does not
   //   warn on unused const-ref parameters so no suppression idiom needed.
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.ManageExits(*m_portfolio);
     }
  }

//+------------------------------------------------------------------+
//| RunEntryPass — invoke Evaluate across 21 slots in BR-2.2 order   |
//+------------------------------------------------------------------+
void COrchestrator::RunEntryPass(const MarketContext &ctx)
  {
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.Evaluate(ctx, *m_portfolio);
     }
  }

//+------------------------------------------------------------------+
//| OnDeinit — inverse-order release per `04 § 5.4`                  |
//|                                                                  |
//| Routes through CleanupPartialInit so a single code path covers    |
//| both INIT_FAILED Phase C exits and normal MT5 shutdown.           |
//+------------------------------------------------------------------+
void COrchestrator::OnDeinit(const int reason)
  {
   if(m_logger != NULL)
      m_logger.Info("system", "deinit", 0,
                    StringFormat("reason=%d state=%s",
                                 reason, EnumToString(m_state_enum)));

   // Final state save before tear-down — best-effort.
   if(m_state != NULL)
      m_state.Save(m_state_enum, m_halt_reason);

   CleanupPartialInit(StringFormat("deinit_reason_%d", reason));
  }

//+------------------------------------------------------------------+
//| OnTester — custom Strategy Tester score (FR-2.5 placeholder)     |
//|                                                                  |
//| Phase 1 returns AccountInfoDouble(ACCOUNT_EQUITY) — final tuning |
//| at IMPL-061..063 regression run. NFR-2.5 expects Sharpe-style    |
//| optimizer score; current placeholder unblocks G3 backtest run    |
//| without committing to a specific weighting.                       |
//+------------------------------------------------------------------+
double COrchestrator::OnTester()
  {
   return AccountInfoDouble(ACCOUNT_EQUITY);
  }

#endif // PHOENICISNEX_CORE_ORCHESTRATOR_MQH
