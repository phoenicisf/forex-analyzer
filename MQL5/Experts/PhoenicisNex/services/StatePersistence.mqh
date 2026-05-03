//+------------------------------------------------------------------+
//| StatePersistence.mqh — Atomic state save/load (IMPL-047)        |
//| Layer:   services/ — Orchestrator injects via Init()+setter      |
//| Source:  ADR-007 (Option A locked), TD-02 §5.6, state-schema v1 |
//|          NFR-3.1 (0% corruption), NFR-3.3 (100% field restore)  |
//|          Claim 01.11 (GV-fallback), Claim 01.13 (NULL guard)     |
//+------------------------------------------------------------------+
// Contract summary:
//   Init(atomic, logger) → phase-1; SetPortfolioState(port) → phase-2
//   Save(state, reason)  → SerializeAll → WriteAtomic → SyncGV
//   Load(state, reason)  → read file → ParseAndApply; on fail → GV hint
//   StatePath() = "PhoenicisNex/state/state.json" (sandbox-relative)
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_STATEPERSISTENCE_MQH
#define PHOENICISNEX_SERVICES_STATEPERSISTENCE_MQH

#include "../helpers/AtomicFile.mqh"   // includes Logger.mqh
#include "../helpers/JsonWriter.mqh"
#include "../helpers/Timestamp.mqh"
#include "PortfolioState.mqh"          // includes Logger.mqh (guarded), SlotState

//--- GlobalVariable key names for watch_profits subset (02 § 6.1.1)
#define GV_KEY_WORST_DD_PCT   "PhoenicisNex.worst_drawdown_pct"
#define GV_KEY_WORST_DD_AT    "PhoenicisNex.worst_drawdown_at"
#define GV_KEY_EQ_HIGH        "PhoenicisNex.equity_high_water_mark"
#define GV_KEY_CUR_DD_PCT     "PhoenicisNex.current_dd_pct"

//--- Pending machine count (PM_C..PM_FORCE = 8)
#define PM_COUNT 8

//+------------------------------------------------------------------+
//| CStatePersistence                                                |
//+------------------------------------------------------------------+
class CStatePersistence
  {
private:
   //--- Paths (sandbox-relative; MT5 implicit MQL5/Files/ prefix)
   string            m_state_dir;        // "PhoenicisNex/state/"
   string            m_state_path;       // "PhoenicisNex/state/state.json"

   //--- Injected deps
   CAtomicFile      *m_atomic;
   CLogger          *m_logger;
   CPortfolioState  *m_portfolio;        // NULL until SetPortfolioState called

   //--- Pending machines (8 entries: PM_C=0 .. PM_FORCE=7)
   EPendingState     m_pm_state[PM_COUNT];
   int               m_pm_started_bar[PM_COUNT];
   string            m_pm_payload[PM_COUNT];       // opaque JSON per machine
   int               m_pm_force_clear_count[PM_COUNT];

   //--- Ban dates (5 fields per BR-3.4)
   datetime          m_ban_c;
   datetime          m_ban_l;
   datetime          m_ban_m;
   datetime          m_k_last_order;
   datetime          m_g_pause;

   //--- WatchProfits (FR-4.4)
   double            m_worst_dd_pct;
   datetime          m_worst_dd_at;
   double            m_equity_high;
   double            m_current_dd_pct;

   //--- Cross-slot signals (CodeWiki §1.3 state variables)
   bool              m_force_buy;
   bool              m_force_sell;
   bool              m_has_c_pending;
   int               m_extra_force_mode;
   bool              m_ichi_above_cloud;

   //--- Journal metrics (ADR-006 RPO counters)
   int               m_journal_write_failures;
   int               m_journal_consecutive_failures;
   datetime          m_journal_last_failure_ts;
   string            m_journal_last_failure_reason;

   //--- Logger metrics (ADR-011 throttle counters)
   int               m_logger_throttled_count;
   string            m_logger_last_throttle_event;

   //--- Dirty bit (default off — write every tick per baseline)
   bool              m_dirty;

   //--- Private serialization helpers
   string            SerializeAll(EEAState ea_state, string halt_reason) const;
   bool              ParseAndApply(string content,
                                   EEAState &out_state, string &out_reason);
   string            _PmKey(EPendingMachineId id) const;
   string            _EAStateToStr(EEAState s) const;
   EEAState          _StrToEAState(string s) const;
   string            _PendingStateToStr(EPendingState s) const;
   EPendingState     _StrToPendingState(string s) const;
   string            _ExtractStr(const string content, const string field) const;
   long              _ExtractInt(const string content, const string field) const;
   double            _ExtractDbl(const string content, const string field) const;
   bool              _ExtractBool(const string content, const string field) const;
   string            _ExtractSubObj(const string content, const string field) const;
   //--- Opaque value extractor: returns literal JSON value text for object/array/null/bool/number/string.
   //    Used for pending_payload (ADR-008) where Save emits raw JSON via WriteRaw and Load must round-trip
   //    the exact value (Finding 02.1 — string-only _ExtractStr would fail on object/null forms).
   string            _ExtractRawValue(const string content, const string field) const;

public:
   //--- Constructor — zero-init
                     CStatePersistence()
      : m_state_dir("PhoenicisNex/state/"),
        m_state_path("PhoenicisNex/state/state.json"),
        m_atomic(NULL), m_logger(NULL), m_portfolio(NULL),
        m_ban_c(0), m_ban_l(0), m_ban_m(0), m_k_last_order(0), m_g_pause(0),
        m_worst_dd_pct(0.0), m_worst_dd_at(0), m_equity_high(0.0),
        m_current_dd_pct(0.0), m_force_buy(false), m_force_sell(false),
        m_has_c_pending(false), m_extra_force_mode(0), m_ichi_above_cloud(false),
        m_journal_write_failures(0), m_journal_consecutive_failures(0),
        m_journal_last_failure_ts(0), m_journal_last_failure_reason(""),
        m_logger_throttled_count(0), m_logger_last_throttle_event(""),
        m_dirty(false)
     {
      for(int i = 0; i < PM_COUNT; i++)
        {
         m_pm_state[i]             = PENDING_STATE_IDLE;
         m_pm_started_bar[i]       = 0;
         m_pm_payload[i]           = "";
         m_pm_force_clear_count[i] = 0;
        }
     }

   //--- Phase-1 init (no PortfolioState dep yet — per DI step 4)
   void              Init(CAtomicFile *atomic, CLogger *logger);

   //--- Phase-2 setter — Orchestrator calls after PortfolioState.Init()
   //    (DI step 5a — Cycle 2 closure per TD-02 §7.3)
   void              SetPortfolioState(CPortfolioState *port) { m_portfolio = port; }

   //--- OnInit Load: parse state.json (or defaults on fail + GV hint)
   //    Returns false if file missing or corrupt (Orchestrator logs warn)
   bool              Load(EEAState &out_ea_state, string &out_halt_reason);

   //--- End-of-tick Save: serialize → WriteAtomic → SyncToGlobalVariable
   //    Defensive guard: m_portfolio NULL → Error + return false
   bool              Save(EEAState ea_state, string halt_reason);

   //--- Push watch_profits subset to MT5 GlobalVariable (post-Save, 02 §6.1.1)
   void              SyncToGlobalVariable();

   //--- GV last-resort recovery (called from Load on parse fail)
   bool              TryRecoverFromGV(double &out_worst_dd, double &out_worst_dd_at,
                                      double &out_eq_high, double &out_cur_dd);

   //--- Path accessors (ADR-007 §Decision; consumed by AtomicFile.CleanupOrphanTmp)
   string            StatePath() const { return m_state_path; }
   string            StateDir()  const { return m_state_dir;  }

   //--- Pending machine accessors (consumers: PendingMachineRegistry IMPL-049)
   string            GetPendingPayload(EPendingMachineId id) const;
   void              SetPendingPayload(EPendingMachineId id, string payload,
                                       int started_bar);
   EPendingState     GetPendingState(EPendingMachineId id) const;
   void              SetPendingState(EPendingMachineId id, EPendingState state);
   int               GetPmForceClearCount(EPendingMachineId id) const;
   void              IncrementPmForceClearCount(EPendingMachineId id);

   //--- Ban date accessors (consumers: TimeGate IMPL-051)
   //    field: "ban_c"|"ban_l"|"ban_m"|"k_last_order"|"g_pause"
   datetime          GetBanDate(string ban_field) const;
   void              SetBanDate(string ban_field, datetime ts);

   //--- WatchProfits accessors (consumers: PortfolioMonitor IMPL-054)
   double            GetWorstDdPct()    const { return m_worst_dd_pct;    }
   datetime          GetWorstDdAt()     const { return m_worst_dd_at;     }
   double            GetEquityHigh()    const { return m_equity_high;     }
   double            GetCurrentDdPct()  const { return m_current_dd_pct;  }
   void              SetWorstDdPct(double v)   { m_worst_dd_pct   = v; }
   void              SetWorstDdAt(datetime t)  { m_worst_dd_at    = t; }
   void              SetEquityHigh(double v)   { m_equity_high    = v; }
   void              SetCurrentDdPct(double v) { m_current_dd_pct = v; }

   //--- Journal failure counters (consumer: TradeJournal IMPL-043)
   void              IncrementJournalFailures();
   void              ResetJournalConsecutive();

   //--- Logger throttle counters (consumer: Logger IMPL-042 post-IMPL-047 wire)
   void              IncrementLoggerThrottle(string slot_event_tuple);
   int               GetLoggerThrottledCount() const { return m_logger_throttled_count; }

  }; // end class CStatePersistence

//+------------------------------------------------------------------+
//| Init — phase-1: store deps, no PortfolioState yet                |
//+------------------------------------------------------------------+
void CStatePersistence::Init(CAtomicFile *atomic, CLogger *logger)
  {
   m_atomic   = atomic;
   m_logger   = logger;
   m_portfolio = NULL;
  }

//+------------------------------------------------------------------+
//| Load — read state.json; fallback to GV subset on parse fail      |
//+------------------------------------------------------------------+
bool CStatePersistence::Load(EEAState &out_ea_state, string &out_halt_reason)
  {
   out_ea_state   = EA_STATE_RUNNING;
   out_halt_reason = "";

   if(!FileIsExist(m_state_path))
      return false;   // fresh boot — no state file

   int handle = FileOpen(m_state_path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
     {
      if(m_logger != NULL)
         m_logger.Warn("system", "state_open_fail", 0,
                       StringFormat("path=%s err=%d", m_state_path, GetLastError()));
      return false;
     }

   string content = "";
   while(!FileIsEnding(handle))
      content += FileReadString(handle);
   FileClose(handle);

   if(!ParseAndApply(content, out_ea_state, out_halt_reason))
     {
      //--- Parse fail → apply defaults + try GV hint (Claim 01.11)
      out_ea_state    = EA_STATE_RUNNING;
      out_halt_reason = "";
      double gv_dd, gv_dd_at, gv_high, gv_cur;
      if(TryRecoverFromGV(gv_dd, gv_dd_at, gv_high, gv_cur))
        {
         m_worst_dd_pct   = gv_dd;
         m_worst_dd_at    = (datetime)(long)gv_dd_at;
         m_equity_high    = gv_high;
         m_current_dd_pct = gv_cur;
         if(m_logger != NULL)
            m_logger.Warn("system", "state_corrupt_recovered_via_gv", 0,
                          StringFormat("path=%s watch_profits restored from GV", m_state_path));
        }
      else
        {
         if(m_logger != NULL)
            m_logger.Warn("system", "state_corrupt_starting_fresh", 0,
                          StringFormat("path=%s GV also missing — all defaults", m_state_path));
        }
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Save — serialize + atomic write + SyncToGlobalVariable           |
//+------------------------------------------------------------------+
bool CStatePersistence::Save(EEAState ea_state, string halt_reason)
  {
   if(m_portfolio == NULL)
     {
      if(m_logger != NULL)
         m_logger.Error("system", "state_save_no_portfolio", 0,
                        "SetPortfolioState not called before Save (DI step 5a missing)");
      return false;
     }
   if(m_atomic == NULL || m_logger == NULL)
      return false;

   string content = SerializeAll(ea_state, halt_reason);
   if(!m_atomic.WriteAtomic(m_state_path, content, m_logger))
      return false;

   SyncToGlobalVariable();
   return true;
  }

//+------------------------------------------------------------------+
//| SyncToGlobalVariable — push watch_profits subset (02 §6.1.1)    |
//+------------------------------------------------------------------+
void CStatePersistence::SyncToGlobalVariable()
  {
   GlobalVariableSet(GV_KEY_WORST_DD_PCT, m_worst_dd_pct);
   GlobalVariableSet(GV_KEY_WORST_DD_AT,  (double)(long)m_worst_dd_at);
   GlobalVariableSet(GV_KEY_EQ_HIGH,      m_equity_high);
   GlobalVariableSet(GV_KEY_CUR_DD_PCT,   m_current_dd_pct);
  }

//+------------------------------------------------------------------+
//| TryRecoverFromGV — read 4 watch_profits doubles from GV         |
//+------------------------------------------------------------------+
bool CStatePersistence::TryRecoverFromGV(double &out_worst_dd,
                                         double &out_worst_dd_at,
                                         double &out_eq_high,
                                         double &out_cur_dd)
  {
   if(!GlobalVariableCheck(GV_KEY_WORST_DD_PCT) ||
      !GlobalVariableCheck(GV_KEY_WORST_DD_AT)  ||
      !GlobalVariableCheck(GV_KEY_EQ_HIGH)       ||
      !GlobalVariableCheck(GV_KEY_CUR_DD_PCT))
      return false;

   out_worst_dd    = GlobalVariableGet(GV_KEY_WORST_DD_PCT);
   out_worst_dd_at = GlobalVariableGet(GV_KEY_WORST_DD_AT);
   out_eq_high     = GlobalVariableGet(GV_KEY_EQ_HIGH);
   out_cur_dd      = GlobalVariableGet(GV_KEY_CUR_DD_PCT);
   return true;
  }

//+------------------------------------------------------------------+
//| GetPendingPayload / SetPendingPayload                            |
//+------------------------------------------------------------------+
string CStatePersistence::GetPendingPayload(EPendingMachineId id) const
  {
   int idx = (int)id;
   if(idx < 0 || idx >= PM_COUNT) return "";
   return m_pm_payload[idx];
  }

void CStatePersistence::SetPendingPayload(EPendingMachineId id, string payload,
                                          int started_bar)
  {
   int idx = (int)id;
   if(idx < 0 || idx >= PM_COUNT) return;
   m_pm_payload[idx]     = payload;
   m_pm_started_bar[idx] = started_bar;
  }

EPendingState CStatePersistence::GetPendingState(EPendingMachineId id) const
  {
   int idx = (int)id;
   return (idx >= 0 && idx < PM_COUNT) ? m_pm_state[idx] : PENDING_STATE_IDLE;
  }

void CStatePersistence::SetPendingState(EPendingMachineId id, EPendingState state)
  {
   int idx = (int)id;
   if(idx >= 0 && idx < PM_COUNT) m_pm_state[idx] = state;
  }

int CStatePersistence::GetPmForceClearCount(EPendingMachineId id) const
  {
   int idx = (int)id;
   return (idx >= 0 && idx < PM_COUNT) ? m_pm_force_clear_count[idx] : 0;
  }

void CStatePersistence::IncrementPmForceClearCount(EPendingMachineId id)
  {
   int idx = (int)id;
   if(idx >= 0 && idx < PM_COUNT) m_pm_force_clear_count[idx]++;
  }

//+------------------------------------------------------------------+
//| GetBanDate / SetBanDate                                          |
//+------------------------------------------------------------------+
datetime CStatePersistence::GetBanDate(string ban_field) const
  {
   if(ban_field == "ban_c")        return m_ban_c;
   if(ban_field == "ban_l")        return m_ban_l;
   if(ban_field == "ban_m")        return m_ban_m;
   if(ban_field == "k_last_order") return m_k_last_order;
   if(ban_field == "g_pause")      return m_g_pause;
   return 0;
  }

void CStatePersistence::SetBanDate(string ban_field, datetime ts)
  {
   if(ban_field == "ban_c")        m_ban_c        = ts;
   else if(ban_field == "ban_l")   m_ban_l        = ts;
   else if(ban_field == "ban_m")   m_ban_m        = ts;
   else if(ban_field == "k_last_order") m_k_last_order = ts;
   else if(ban_field == "g_pause") m_g_pause      = ts;
  }

//+------------------------------------------------------------------+
//| Journal / Logger metric counters                                 |
//+------------------------------------------------------------------+
void CStatePersistence::IncrementJournalFailures()
  {
   m_journal_write_failures++;
   m_journal_consecutive_failures++;
   m_journal_last_failure_ts = TimeCurrent();
  }

void CStatePersistence::ResetJournalConsecutive()
  {
   m_journal_consecutive_failures = 0;
  }

void CStatePersistence::IncrementLoggerThrottle(string slot_event_tuple)
  {
   m_logger_throttled_count++;
   m_logger_last_throttle_event = slot_event_tuple;
  }

//+------------------------------------------------------------------+
//| SerializeAll — build complete state.json JSON string             |
//| Schema: docs/api-specs/state-persistence-schema.yaml v1         |
//+------------------------------------------------------------------+
string CStatePersistence::SerializeAll(EEAState ea_state,
                                       string halt_reason) const
  {
   string ts = FormatTimestampWithMs(TimeCurrent(), GetMicrosecondCount());

   CJsonWriter w;
   w.Begin();
   w.WriteInt("schema_version", 1);
   w.WriteString("last_save_timestamp", ts);
   w.WriteString("ea_state", _EAStateToStr(ea_state));
   if(StringLen(halt_reason) > 0)
      w.WriteString("ea_halt_reason", halt_reason);
   else
      w.WriteNull("ea_halt_reason");

   //--- pending_machines sub-object
   string pm_json = "";
   {
      CJsonWriter pm;
      pm.Begin();
      for(int i = 0; i < PM_COUNT; i++)
        {
         EPendingMachineId mid = (EPendingMachineId)i;
         CJsonWriter mc;
         mc.Begin();
         mc.WriteString("state", _PendingStateToStr(m_pm_state[i]));
         mc.WriteInt("pending_started_bar", m_pm_started_bar[i]);
         mc.WriteInt("force_clear_count", m_pm_force_clear_count[i]);
         if(StringLen(m_pm_payload[i]) > 0)
            mc.WriteRaw("pending_payload", m_pm_payload[i]);
         else
            mc.WriteNull("pending_payload");
         mc.End();
         pm.WriteRaw(_PmKey(mid), mc.ToString());
        }
      pm.End();
      pm_json = pm.ToString();
   }
   w.WriteRaw("pending_machines", pm_json);

   //--- ban_dates sub-object
   {
      CJsonWriter bd;
      bd.Begin();
      bd.WriteInt("ban_c",        (long)m_ban_c);
      bd.WriteInt("ban_l",        (long)m_ban_l);
      bd.WriteInt("ban_m",        (long)m_ban_m);
      bd.WriteInt("k_last_order", (long)m_k_last_order);
      bd.WriteInt("g_pause",      (long)m_g_pause);
      bd.End();
      w.WriteRaw("ban_dates", bd.ToString());
   }

   //--- watch_profits sub-object
   {
      CJsonWriter wp;
      wp.Begin();
      wp.WriteDouble("worst_drawdown_pct",    m_worst_dd_pct,   4);
      wp.WriteInt("worst_drawdown_at",         (long)m_worst_dd_at);
      wp.WriteDouble("equity_high_water_mark", m_equity_high,    2);
      wp.WriteDouble("current_dd_pct",         m_current_dd_pct, 4);
      wp.End();
      w.WriteRaw("watch_profits", wp.ToString());
   }

   //--- cross_slot_signals sub-object
   {
      CJsonWriter cs;
      cs.Begin();
      cs.WriteBool("is_force_pending_action_buy_order",  m_force_buy);
      cs.WriteBool("is_force_pending_action_sell_order", m_force_sell);
      cs.WriteBool("has_c_pending",                      m_has_c_pending);
      cs.WriteInt("extra_force_mode",                    m_extra_force_mode);
      cs.WriteBool("ichi_above_cloud",                   m_ichi_above_cloud);
      cs.End();
      w.WriteRaw("cross_slot_signals", cs.ToString());
   }

   //--- slot_states sub-object (17 entries from PortfolioState)
   {
      CJsonWriter ss;
      ss.Begin();
      if(m_portfolio != NULL)
        {
         int magics[17] = {200,201,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219};
         for(int i = 0; i < 17; i++)
           {
            SlotState *s = m_portfolio.GetByMagic(magics[i]);
            CJsonWriter se;
            se.Begin();
            if(s != NULL)
              {
               //--- slot_ids array
               string ids_json = "[";
               for(int j = 0; j < ArraySize(s.slot_ids); j++)
                 {
                  if(j > 0) ids_json += ",";
                  ids_json += "\"" + s.slot_ids[j] + "\"";
                 }
               ids_json += "]";
               se.WriteRaw("slot_ids", ids_json);
               se.WriteInt("buy_count",   s.buy_count);
               se.WriteInt("sell_count",  s.sell_count);
               se.WriteDouble("total_lots",   s.total_lots,   2);
               se.WriteDouble("total_profit", s.total_profit, 2);
               se.WriteInt("last_open_date",  (long)s.last_open_date);
               //--- ticket_ids array
               string tids = "[";
               for(int j = 0; j < ArraySize(s.ticket_ids); j++)
                 {
                  if(j > 0) tids += ",";
                  tids += IntegerToString((long)s.ticket_ids[j]);
                 }
               tids += "]";
               se.WriteRaw("ticket_ids", tids);
               //--- ticket_max_profit_pip array
               string tmpp = "[";
               for(int j = 0; j < ArraySize(s.ticket_max_profit_pip); j++)
                 {
                  if(j > 0) tmpp += ",";
                  tmpp += DoubleToString(s.ticket_max_profit_pip[j], 2);
                 }
               tmpp += "]";
               se.WriteRaw("ticket_max_profit_pip", tmpp);
               se.WriteString("pending_state",   _PendingStateToStr(s.pending_state));
               if(StringLen(s.pending_payload) > 0)
                  se.WriteString("pending_payload", s.pending_payload);
               else
                  se.WriteNull("pending_payload");
              }
            se.End();
            ss.WriteRaw(IntegerToString(magics[i]), se.ToString());
           }
        }
      ss.End();
      w.WriteRaw("slot_states", ss.ToString());
   }

   //--- journal_metrics sub-object
   {
      CJsonWriter jm;
      jm.Begin();
      jm.WriteInt("write_failures",        m_journal_write_failures);
      jm.WriteInt("consecutive_failures",  m_journal_consecutive_failures);
      jm.WriteInt("last_failure_ts",       (long)m_journal_last_failure_ts);
      if(StringLen(m_journal_last_failure_reason) > 0)
         jm.WriteString("last_failure_reason", m_journal_last_failure_reason);
      else
         jm.WriteNull("last_failure_reason");
      jm.End();
      w.WriteRaw("journal_metrics", jm.ToString());
   }

   //--- logger_metrics sub-object
   {
      CJsonWriter lm;
      lm.Begin();
      lm.WriteInt("throttled_alert_count", m_logger_throttled_count);
      if(StringLen(m_logger_last_throttle_event) > 0)
         lm.WriteString("last_throttle_event", m_logger_last_throttle_event);
      else
         lm.WriteNull("last_throttle_event");
      lm.End();
      w.WriteRaw("logger_metrics", lm.ToString());
   }

   w.End();
   return w.ToString();
  }

//+------------------------------------------------------------------+
//| ParseAndApply — minimal StringFind-based JSON parser             |
//| Validates schema_version == 1; populates all internal fields.   |
//+------------------------------------------------------------------+
bool CStatePersistence::ParseAndApply(string content,
                                      EEAState &out_state,
                                      string &out_reason)
  {
   if(StringLen(content) < 10) return false;

   //--- Validate schema_version
   long sv = _ExtractInt(content, "schema_version");
   if(sv != 1)
     {
      if(m_logger != NULL)
         m_logger.Warn("system", "state_schema_version_mismatch", 0,
                       StringFormat("expected=1 got=%d", (int)sv));
      return false;
     }

   //--- ea_state + ea_halt_reason
   string ea_str = _ExtractStr(content, "ea_state");
   if(StringLen(ea_str) == 0) return false;
   out_state  = _StrToEAState(ea_str);
   out_reason = _ExtractStr(content, "ea_halt_reason");

   //--- ban_dates
   string bd_json = _ExtractSubObj(content, "ban_dates");
   m_ban_c        = (datetime)_ExtractInt(bd_json, "ban_c");
   m_ban_l        = (datetime)_ExtractInt(bd_json, "ban_l");
   m_ban_m        = (datetime)_ExtractInt(bd_json, "ban_m");
   m_k_last_order = (datetime)_ExtractInt(bd_json, "k_last_order");
   m_g_pause      = (datetime)_ExtractInt(bd_json, "g_pause");

   //--- watch_profits
   string wp_json     = _ExtractSubObj(content, "watch_profits");
   m_worst_dd_pct     = _ExtractDbl(wp_json, "worst_drawdown_pct");
   m_worst_dd_at      = (datetime)_ExtractInt(wp_json, "worst_drawdown_at");
   m_equity_high      = _ExtractDbl(wp_json, "equity_high_water_mark");
   m_current_dd_pct   = _ExtractDbl(wp_json, "current_dd_pct");

   //--- cross_slot_signals
   string cs_json      = _ExtractSubObj(content, "cross_slot_signals");
   m_force_buy         = _ExtractBool(cs_json, "is_force_pending_action_buy_order");
   m_force_sell        = _ExtractBool(cs_json, "is_force_pending_action_sell_order");
   m_has_c_pending     = _ExtractBool(cs_json, "has_c_pending");
   m_extra_force_mode  = (int)_ExtractInt(cs_json, "extra_force_mode");
   m_ichi_above_cloud  = _ExtractBool(cs_json, "ichi_above_cloud");

   //--- pending_machines (8 entries)
   string pm_json = _ExtractSubObj(content, "pending_machines");
   for(int i = 0; i < PM_COUNT; i++)
     {
      EPendingMachineId mid = (EPendingMachineId)i;
      string mc_json = _ExtractSubObj(pm_json, _PmKey(mid));
      if(StringLen(mc_json) > 2)
        {
         m_pm_state[i]             = _StrToPendingState(_ExtractStr(mc_json, "state"));
         m_pm_started_bar[i]       = (int)_ExtractInt(mc_json, "pending_started_bar");
         m_pm_force_clear_count[i] = (int)_ExtractInt(mc_json, "force_clear_count");
         //--- pending_payload is opaque JSON (object|null|string) per ADR-008 — use raw extractor
         //    (Finding 02.1 — _ExtractStr's "key":" pattern would never match raw object/null forms)
         string raw_pp = _ExtractRawValue(mc_json, "pending_payload");
         m_pm_payload[i]           = (raw_pp == "null" || StringLen(raw_pp) == 0) ? "" : raw_pp;
        }
     }

   //--- journal_metrics
   string jm_json                  = _ExtractSubObj(content, "journal_metrics");
   m_journal_write_failures        = (int)_ExtractInt(jm_json, "write_failures");
   m_journal_consecutive_failures  = (int)_ExtractInt(jm_json, "consecutive_failures");
   m_journal_last_failure_ts       = (datetime)_ExtractInt(jm_json, "last_failure_ts");
   m_journal_last_failure_reason   = _ExtractStr(jm_json, "last_failure_reason");

   //--- logger_metrics
   string lm_json               = _ExtractSubObj(content, "logger_metrics");
   m_logger_throttled_count     = (int)_ExtractInt(lm_json, "throttled_alert_count");
   m_logger_last_throttle_event = _ExtractStr(lm_json, "last_throttle_event");

   return true;
  }

//+------------------------------------------------------------------+
//| _PmKey — map EPendingMachineId to JSON key name                  |
//+------------------------------------------------------------------+
string CStatePersistence::_PmKey(EPendingMachineId id) const
  {
   switch(id)
     {
      case PM_C:     return "c_pending";
      case PM_C_ADX: return "c_pending_adx";
      case PM_R:     return "r_pending";
      case PM_P:     return "p_pending";
      case PM_M:     return "m_pending";
      case PM_T:     return "t_pending";
      case PM_Q:     return "q_pending";
      case PM_FORCE: return "force_pending";
      default:       return "unknown_pending";
     }
  }

//+------------------------------------------------------------------+
//| _EAStateToStr / _StrToEAState                                    |
//+------------------------------------------------------------------+
string CStatePersistence::_EAStateToStr(EEAState s) const
  {
   switch(s)
     {
      case EA_STATE_RUNNING:       return "RUNNING";
      case EA_STATE_HALTED:        return "HALTED";
      case EA_STATE_HALTED_STABLE: return "HALTED_STABLE";
      default:                     return "RUNNING";
     }
  }

EEAState CStatePersistence::_StrToEAState(string s) const
  {
   if(s == "HALTED")        return EA_STATE_HALTED;
   if(s == "HALTED_STABLE") return EA_STATE_HALTED_STABLE;
   return EA_STATE_RUNNING;
  }

//+------------------------------------------------------------------+
//| _PendingStateToStr / _StrToPendingState                          |
//+------------------------------------------------------------------+
string CStatePersistence::_PendingStateToStr(EPendingState s) const
  {
   switch(s)
     {
      case PENDING_STATE_IDLE:     return "IDLE";
      case PENDING_STATE_PENDING:  return "PENDING";
      case PENDING_STATE_EXECUTED: return "EXECUTED";
      default:                     return "IDLE";
     }
  }

EPendingState CStatePersistence::_StrToPendingState(string s) const
  {
   if(s == "PENDING")  return PENDING_STATE_PENDING;
   if(s == "EXECUTED") return PENDING_STATE_EXECUTED;
   return PENDING_STATE_IDLE;
  }

//+------------------------------------------------------------------+
//| _ExtractStr — find "field":"value" → return unescaped value      |
//| Returns "" if field missing or null.                             |
//|                                                                  |
//| Finding 02.5 — JSON escape contract:                             |
//|  Save side (helpers/JsonWriter.mqh::EscapeString) writes RFC 8259 |
//|  §7-compliant escapes: \" \\ \n \r \t \uXXXX. The naive          |
//|  StringFind(content, "\"", start) terminator misinterprets escaped|
//|  '\"' as the closing quote → halt_reason / pending_payload string|
//|  values truncated mid-content + downstream parser reads garbage. |
//|                                                                  |
//| Fix: backslash-aware terminator scan (count preceding backslashes |
//| — even = real terminator, odd = escaped). Then unescape the raw  |
//| substring before returning.                                       |
//+------------------------------------------------------------------+
string CStatePersistence::_ExtractStr(const string content,
                                      const string field) const
  {
   string search = "\"" + field + "\":\"";
   int pos = StringFind(content, search);
   if(pos < 0) return "";
   int start = pos + StringLen(search);
   int n = StringLen(content);

   //--- Find closing '"' that is NOT preceded by an odd number of backslashes
   int end = -1;
   for(int i = start; i < n; i++)
     {
      if(StringGetCharacter(content, i) != '"') continue;
      int bs = 0;
      int k  = i - 1;
      while(k >= start && StringGetCharacter(content, k) == '\\') { bs++; k--; }
      if((bs & 1) == 0) { end = i; break; }   // even backslashes → real terminator
     }
   if(end < 0 || end <= start) return "";

   string raw = StringSubstr(content, start, end - start);

   //--- Unescape: \" → " · \\ → \ · \n → 0x0A · \r → 0x0D · \t → 0x09 · \uXXXX → char
   string out  = "";
   int    rlen = StringLen(raw);
   for(int i = 0; i < rlen; i++)
     {
      ushort c = StringGetCharacter(raw, i);
      if(c == '\\' && i + 1 < rlen)
        {
         ushort nx = StringGetCharacter(raw, i + 1);
         if(nx == '"')  { out += "\"";          i++; continue; }
         if(nx == '\\') { out += "\\";          i++; continue; }
         if(nx == 'n')  { out += ShortToString(0x0A); i++; continue; }
         if(nx == 'r')  { out += ShortToString(0x0D); i++; continue; }
         if(nx == 't')  { out += ShortToString(0x09); i++; continue; }
         if(nx == 'u' && i + 5 < rlen)
           {
            //--- Parse 4-hex-digit unicode escape
            int code = 0;
            bool ok  = true;
            for(int h = 0; h < 4; h++)
              {
               ushort hc = StringGetCharacter(raw, i + 2 + h);
               int dig;
               if(hc >= '0' && hc <= '9')      dig = hc - '0';
               else if(hc >= 'a' && hc <= 'f') dig = hc - 'a' + 10;
               else if(hc >= 'A' && hc <= 'F') dig = hc - 'A' + 10;
               else { ok = false; break; }
               code = (code << 4) | dig;
              }
            if(ok)
              {
               out += ShortToString((ushort)code);
               i += 5;
               continue;
              }
           }
         //--- Unknown escape: emit literal '\' then re-loop on next char
        }
      out += ShortToString(c);
     }
   return out;
  }

//+------------------------------------------------------------------+
//| _ExtractInt — find "field":integer → return long                 |
//+------------------------------------------------------------------+
long CStatePersistence::_ExtractInt(const string content,
                                    const string field) const
  {
   string search = "\"" + field + "\":";
   int pos = StringFind(content, search);
   if(pos < 0) return 0;
   int start = pos + StringLen(search);
   //--- skip whitespace
   while(start < StringLen(content) &&
         (StringGetCharacter(content, start) == ' ')) start++;
   //--- check for null
   if(StringSubstr(content, start, 4) == "null") return 0;
   //--- read digits (and optional minus)
   string num = "";
   int n = StringLen(content);
   for(int i = start; i < n && i < start + 24; i++)
     {
      ushort c = StringGetCharacter(content, i);
      if((c >= '0' && c <= '9') || (c == '-' && StringLen(num) == 0))
         num += ShortToString(c);
      else
         break;
     }
   return StringLen(num) > 0 ? StringToInteger(num) : 0;
  }

//+------------------------------------------------------------------+
//| _ExtractDbl — find "field":number → return double                |
//+------------------------------------------------------------------+
double CStatePersistence::_ExtractDbl(const string content,
                                      const string field) const
  {
   string search = "\"" + field + "\":";
   int pos = StringFind(content, search);
   if(pos < 0) return 0.0;
   int start = pos + StringLen(search);
   while(start < StringLen(content) &&
         StringGetCharacter(content, start) == ' ') start++;
   if(StringSubstr(content, start, 4) == "null") return 0.0;
   string num = "";
   int n = StringLen(content);
   for(int i = start; i < n && i < start + 32; i++)
     {
      ushort c = StringGetCharacter(content, i);
      if((c >= '0' && c <= '9') || c == '.' || c == 'e' || c == 'E' ||
         (c == '-' && StringLen(num) == 0))
         num += ShortToString(c);
      else
         break;
     }
   return StringLen(num) > 0 ? StringToDouble(num) : 0.0;
  }

//+------------------------------------------------------------------+
//| _ExtractBool — find "field":true/false → return bool             |
//+------------------------------------------------------------------+
bool CStatePersistence::_ExtractBool(const string content,
                                     const string field) const
  {
   string search = "\"" + field + "\":";
   int pos = StringFind(content, search);
   if(pos < 0) return false;
   int start = pos + StringLen(search);
   while(start < StringLen(content) &&
         StringGetCharacter(content, start) == ' ') start++;
   return StringSubstr(content, start, 4) == "true";
  }

//+------------------------------------------------------------------+
//| _ExtractSubObj — find "field":{...} → return complete {...}      |
//| Uses brace counting for correct nesting.                        |
//+------------------------------------------------------------------+
string CStatePersistence::_ExtractSubObj(const string content,
                                         const string field) const
  {
   string search = "\"" + field + "\":{";
   int pos = StringFind(content, search);
   if(pos < 0) return "{}";
   int obj_start = pos + StringLen(search) - 1;   // position of '{'
   int depth = 0;
   int n = StringLen(content);
   for(int i = obj_start; i < n; i++)
     {
      ushort ch = StringGetCharacter(content, i);
      if(ch == '{')      depth++;
      else if(ch == '}') { depth--; if(depth == 0) return StringSubstr(content, obj_start, i - obj_start + 1); }
     }
   return "{}";
  }

//+------------------------------------------------------------------+
//| _ExtractRawValue — return literal JSON value text after "field": |
//|                                                                  |
//| Handles all JSON value kinds (RFC 8259 §3):                      |
//|   • object  {...}  — depth-tracked, string-aware (Finding 02.1)  |
//|   • array   [...]  — depth-tracked, string-aware                 |
//|   • string  "..."  — escape-aware terminator                     |
//|   • null / true / false / number — read until value terminator   |
//|     (',' / '}' / ']' / whitespace)                              |
//|                                                                  |
//| Used for opaque-payload fields (pending_payload per ADR-008).    |
//| Returns "" if field missing; otherwise the raw value text exactly|
//| as it appears (caller checks for "null" literal).                |
//+------------------------------------------------------------------+
string CStatePersistence::_ExtractRawValue(const string content,
                                           const string field) const
  {
   string search = "\"" + field + "\":";
   int pos = StringFind(content, search);
   if(pos < 0) return "";
   int start = pos + StringLen(search);
   int n = StringLen(content);
   //--- skip whitespace
   while(start < n && StringGetCharacter(content, start) == ' ') start++;
   if(start >= n) return "";
   ushort first = StringGetCharacter(content, start);

   //--- Object {...} or Array [...] — depth-track matching close, ignore quotes inside strings
   if(first == '{' || first == '[')
     {
      ushort open_ch  = first;
      ushort close_ch = (first == '{') ? (ushort)'}' : (ushort)']';
      int depth = 0;
      bool in_str = false;
      bool esc = false;
      for(int i = start; i < n; i++)
        {
         ushort c = StringGetCharacter(content, i);
         if(in_str)
           {
            if(esc)            { esc = false; continue; }
            if(c == '\\')      { esc = true; continue; }
            if(c == '"')       { in_str = false; }
            continue;
           }
         if(c == '"')          { in_str = true; continue; }
         if(c == open_ch)      depth++;
         else if(c == close_ch)
           {
            depth--;
            if(depth == 0)
               return StringSubstr(content, start, i - start + 1);
           }
        }
      return "";
     }

   //--- String "..." — backslash-aware terminator
   if(first == '"')
     {
      for(int i = start + 1; i < n; i++)
        {
         ushort c = StringGetCharacter(content, i);
         if(c == '\\') { i++; continue; }   // skip escaped char
         if(c == '"')  return StringSubstr(content, start, i - start + 1);
        }
      return "";
     }

   //--- null / true / false / number — read until value terminator
   int end = start;
   while(end < n)
     {
      ushort c = StringGetCharacter(content, end);
      if(c == ',' || c == '}' || c == ']' ||
         c == ' ' || c == '\n' || c == '\r' || c == '\t')
         break;
      end++;
     }
   return StringSubstr(content, start, end - start);
  }

//+------------------------------------------------------------------+
//| CLogger::_SyncThrottle — deferred body (IMPL-047 bridge)        |
//| Body defined here because CStatePersistence is now fully known. |
//| Logger.mqh declares the method; body lives post-class-def.      |
//+------------------------------------------------------------------+
void CLogger::_SyncThrottle(string key)
  {
   if(m_state != NULL)
      m_state.IncrementLoggerThrottle(key);
  }

#endif // PHOENICISNEX_SERVICES_STATEPERSISTENCE_MQH
