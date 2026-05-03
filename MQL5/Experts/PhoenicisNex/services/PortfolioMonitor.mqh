//+------------------------------------------------------------------+
//| PortfolioMonitor.mqh — Incremental drawdown tracker (IMPL-045)   |
//| Layer:   services/ — Orchestrator injects via Init()             |
//| Source:  TD-02 §5.12, FR-4.4 (WatchProfits), FR-8.2 (incremental|
//|          DD tracker), NFR-5.2 (OQ-6 monitor-only — no halt)      |
//|          state-persistence-schema.yaml § watch_profits           |
//|                                                                  |
//| Responsibilities:                                                |
//|   • Track equity high-water mark + current DD% per tick          |
//|   • Update worst-DD record when new maximum exceeded             |
//|   • Persist all 4 watch_profits fields via CStatePersistence     |
//|   • Pure observer: NO halt trigger (OQ-6 + S-AC #3)             |
//|   • Logger.Info only on new worst-DD (anti-spam rule §6.8)       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_PORTFOLIOMONITOR_MQH
#define PHOENICISNEX_SERVICES_PORTFOLIOMONITOR_MQH

#include "StatePersistence.mqh"   // pulls Logger.mqh transitively (guarded)

//+------------------------------------------------------------------+
//| CPortfolioMonitor — per TD-02 §5.12 verbatim class signature     |
//+------------------------------------------------------------------+
class CPortfolioMonitor
  {
private:
   double            m_equity_high_water_mark;
   double            m_worst_dd_pct;
   datetime          m_worst_dd_at;
   double            m_current_dd_pct;
   CStatePersistence *m_state;
   CLogger           *m_logger;

public:
   //--- Constructor — zero-init; Init() must be called before any method
   CPortfolioMonitor()
      : m_equity_high_water_mark(0.0),
        m_worst_dd_pct(0.0),
        m_worst_dd_at(0),
        m_current_dd_pct(0.0),
        m_state(NULL),
        m_logger(NULL)
     {}

   //--- Init — wire deps + prime members from persisted state (warm restart)
   //    Called at Orchestrator OnInit Phase C (TD-02 §7.4) after
   //    StatePersistence is wired (Composition Root per ADR-002).
   //    Re-Init safe: resets all internal members.
   void Init(CStatePersistence *state, CLogger *logger);

   //--- Update — called end-of-tick (OnTick flow step V)
   //    Updates high-water mark, current DD%, and worst-DD record.
   //    ~30 µs per TD-02 §5.12 annotation; no halt trigger (OQ-6).
   void Update(double current_equity, datetime now);

   //--- Accessors — consumed by HALTED_STABLE Alert message + diagnostics
   double WorstDdPct()   const { return m_worst_dd_pct;   }
   double CurrentDdPct() const { return m_current_dd_pct; }

   //--- SelfTest — structural verification; no real StatePersistence needed
   //    Cases 1-5 per §6.10 SelfTest pattern (IMPL-008/IMPL-051 precedent).
   //    Uses NULL m_state so SetXxx calls are guarded-out; verifies
   //    in-memory member updates via WorstDdPct() / CurrentDdPct() only.
   //    This is documented deferral: live [db-inspect] E-AC deferred to
   //    IMPL-018+ orchestrator wiring per header-only precedent (§5 AC note).
   static bool SelfTest();

  }; // end class CPortfolioMonitor

//+------------------------------------------------------------------+
//| Init — store deps, defensive NULL-guard, prime from persisted    |
//|        state for warm-restart value preservation                 |
//+------------------------------------------------------------------+
void CPortfolioMonitor::Init(CStatePersistence *state, CLogger *logger)
  {
   //--- Defensive zero-init (re-Init safe)
   m_equity_high_water_mark = 0.0;
   m_worst_dd_pct           = 0.0;
   m_worst_dd_at            = 0;
   m_current_dd_pct         = 0.0;
   m_state                  = NULL;
   m_logger                 = NULL;

   //--- NULL-guard logger first (must Print if logger itself is null)
   if(logger == NULL)
     {
      Print("[PortfolioMonitor] Init failed: logger NULL");
      return;
     }
   m_logger = logger;

   //--- NULL-guard state
   if(state == NULL)
     {
      m_logger.Error("PortfolioMonitor", "init_state_null", 0,
                     "CStatePersistence pointer is NULL — warm-restart priming skipped");
      return;
     }
   m_state = state;

   //--- Prime members from persisted state (warm restart preserves values)
   m_equity_high_water_mark = m_state.GetEquityHigh();
   m_worst_dd_pct           = m_state.GetWorstDdPct();
   m_worst_dd_at            = m_state.GetWorstDdAt();
   m_current_dd_pct         = m_state.GetCurrentDdPct();

   m_logger.Info("PortfolioMonitor", "init_ok", 0,
                 StringFormat("eq_high=%.2f worst_dd=%.4f cur_dd=%.4f",
                              m_equity_high_water_mark,
                              m_worst_dd_pct,
                              m_current_dd_pct));
  }

//+------------------------------------------------------------------+
//| Update — incremental DD tracking; called end-of-tick             |
//|                                                                  |
//| Logic (per TD-02 §5.12 + shared-context §6.8):                  |
//|  1. NULL-guard m_state — Error log + early return (monitor-only; |
//|     do NOT halt per OQ-6 / S-AC #3)                             |
//|  2. High-water-mark update when equity rises                     |
//|  3. Compute current DD% (guard divide-by-zero)                  |
//|  4. New worst-DD trigger (strictly greater) — persist + log Info |
//|  5. No halt trigger under any condition                         |
//+------------------------------------------------------------------+
void CPortfolioMonitor::Update(double current_equity, datetime now)
  {
   //--- Step 1: NULL-guard state (monitor-only — do NOT halt per OQ-6)
   if(m_state == NULL)
     {
      if(m_logger != NULL)
         m_logger.Error("PortfolioMonitor", "update_state_null", 0,
                        "m_state is NULL in Update — DD values not persisted");
      //--- In-memory update proceeds so accessors remain readable
     }

   //--- Step 2: High-water-mark update
   //    Tolerance 1e-6 guards floating-point transitional noise while still
   //    capturing real equity rises (equity in dollars; not normalized)
   if(current_equity - m_equity_high_water_mark > 1e-6)
     {
      m_equity_high_water_mark = current_equity;
      if(m_state != NULL)
         m_state.SetEquityHigh(m_equity_high_water_mark);
     }

   //--- Step 3: Compute current DD%
   if(m_equity_high_water_mark <= 0.0)
     {
      m_current_dd_pct = 0.0;
     }
   else
     {
      m_current_dd_pct = (m_equity_high_water_mark - current_equity) /
                          m_equity_high_water_mark * 100.0;
      //--- Clamp negative (can occur during high-water update transitional moment)
      if(m_current_dd_pct < 0.0)
         m_current_dd_pct = 0.0;
     }
   if(m_state != NULL)
      m_state.SetCurrentDdPct(m_current_dd_pct);

   //--- Step 4: New worst-DD trigger (strictly greater; tolerance 1e-9)
   if(m_current_dd_pct - m_worst_dd_pct > 1e-9)
     {
      m_worst_dd_pct = m_current_dd_pct;
      m_worst_dd_at  = now;
      if(m_state != NULL)
        {
         m_state.SetWorstDdPct(m_worst_dd_pct);
         m_state.SetWorstDdAt(m_worst_dd_at);
        }
      //--- Anti-spam: log only on new worst (not every tick)
      if(m_logger != NULL)
         m_logger.Info("PortfolioMonitor", "new_worst_dd", 0,
                       StringFormat("dd=%.4f at=%s",
                                    m_worst_dd_pct,
                                    TimeToString(now, TIME_DATE | TIME_MINUTES)));
     }

   //--- Step 5: NO halt trigger (OQ-6 monitor-only; S-AC #3)
  }

//+------------------------------------------------------------------+
//| SelfTest — 5 structural cases; NULL m_state throughout           |
//|                                                                  |
//| Note on deferral: SetXxx calls on real StatePersistence require   |
//| a fully wired Orchestrator environment (OnInit phase C complete). |
//| These calls are guarded-out here by passing NULL m_state.        |
//| Full [db-inspect] E-AC deferred to IMPL-018+ orchestrator wiring |
//| per header-only precedent (IMPL-005/007/011 pattern).            |
//+------------------------------------------------------------------+
bool CPortfolioMonitor::SelfTest()
  {
   bool all_pass = true;
   int  fail_case = 0;
   string fail_reason = "";

   //--- Case 1: NULL-guard — Init(NULL, NULL) must not crash; prints diagnostic
   {
      CPortfolioMonitor mon;
      mon.Init(NULL, NULL);
      //--- If we reach here without crash/assert, guard worked
      //--- WorstDdPct() / CurrentDdPct() should remain 0.0 (zero-init from constructor)
      if(MathAbs(mon.WorstDdPct())   > 1e-9 ||
         MathAbs(mon.CurrentDdPct()) > 1e-9)
        {
         all_pass  = false;
         fail_case = 1;
         fail_reason = "non-zero accessors after NULL-NULL Init";
        }
   }

   //--- Case 2: NULL-guard Update — Update with NULL state must not crash;
   //    current_dd accessor remains safe (in-memory update still proceeds)
   if(all_pass || fail_case != 1)
     {
      CPortfolioMonitor mon;
      //--- Bypass Init (both NULL) then call Update directly — m_state stays NULL
      mon.Update(100.0, TimeCurrent());
      //--- With no prior high-water mark (0.0), equity 100 rises → high-water=100,
      //    current_dd should be 0 (no drawdown from new high)
      if(MathAbs(mon.CurrentDdPct()) > 1e-6)
        {
         all_pass  = false;
         fail_case = 2;
         fail_reason = StringFormat("expected current_dd=0.0 got=%.6f", mon.CurrentDdPct());
        }
     }

   //--- Case 3: Direct member-state test — set up known state then verify DD calc
   //    high=10000, equity=9000 → expected current_dd_pct = 10.0%
   if(all_pass || fail_case == 0)
     {
      CPortfolioMonitor mon;
      //--- Manually prime via Init(NULL state, NULL logger) then manipulate via Update
      //    First Update at 10000 to establish high-water mark
      mon.Update(10000.0, TimeCurrent());
      //--- Now Update at 9000 to produce 10% DD
      mon.Update(9000.0, TimeCurrent());
      double expected_dd = 10.0;
      if(MathAbs(mon.CurrentDdPct() - expected_dd) > 1e-6)
        {
         all_pass  = false;
         fail_case = 3;
         fail_reason = StringFormat("expected current_dd=10.0 got=%.6f", mon.CurrentDdPct());
        }
     }

   //--- Case 4: New-worst trigger verification
   //    After case-3 state: high=10000, equity drop to 9000 → worst_dd should be 10.0
   //    m_state is NULL so SetWorstDdPct is skipped; verify in-memory via WorstDdPct()
   if(all_pass || fail_case == 0)
     {
      CPortfolioMonitor mon;
      mon.Update(10000.0, TimeCurrent());   // establish high-water
      mon.Update(9000.0,  TimeCurrent());   // drop 10%
      double expected_worst = 10.0;
      if(MathAbs(mon.WorstDdPct() - expected_worst) > 1e-6)
        {
         all_pass  = false;
         fail_case = 4;
         fail_reason = StringFormat("expected worst_dd=10.0 got=%.6f", mon.WorstDdPct());
        }
      //--- Also verify: second Update at 9000 (same level) must NOT re-trigger worst
      double worst_before = mon.WorstDdPct();
      mon.Update(9000.0, TimeCurrent());
      if(MathAbs(mon.WorstDdPct() - worst_before) > 1e-9)
        {
         all_pass  = false;
         fail_case = 4;
         fail_reason = "worst_dd changed on non-new-worst Update (should be stable)";
        }
     }

   //--- Case 5: Equity rise — high-water moves, current_dd resets to 0
   //    high=10000, then equity=11000 → high-water moves to 11000, current_dd=0
   if(all_pass || fail_case == 0)
     {
      CPortfolioMonitor mon;
      mon.Update(10000.0, TimeCurrent());   // high=10000
      mon.Update(9000.0,  TimeCurrent());   // worst_dd=10%
      mon.Update(11000.0, TimeCurrent());   // equity rises above high-water
      //--- High-water now 11000; current_dd should be 0 (at new high, no drawdown)
      if(MathAbs(mon.CurrentDdPct()) > 1e-6)
        {
         all_pass  = false;
         fail_case = 5;
         fail_reason = StringFormat("expected current_dd=0.0 after equity rise, got=%.6f",
                                    mon.CurrentDdPct());
        }
      //--- worst_dd should still be 10.0 (equity rise does not reset worst record)
      if(MathAbs(mon.WorstDdPct() - 10.0) > 1e-6)
        {
         all_pass  = false;
         fail_case = 5;
         fail_reason = StringFormat("worst_dd should remain 10.0 after equity rise, got=%.6f",
                                    mon.WorstDdPct());
        }
     }

   if(all_pass)
     {
      Print("[ev=portfolio_monitor_self_test][result=pass]");
      return true;
     }
   else
     {
      Print(StringFormat("[ev=portfolio_monitor_self_test][result=fail][case=%d][reason=%s]",
                         fail_case, fail_reason));
      return false;
     }
  }

#endif // PHOENICISNEX_SERVICES_PORTFOLIOMONITOR_MQH
