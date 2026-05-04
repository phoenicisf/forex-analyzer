//+------------------------------------------------------------------+
//| Logger.mqh — tagged structured logger (ADR-011 + TD-02 §5.7/§9.4)|
//| Layer:   services/ — injects into slots via constructor           |
//| Source:  ADR-011, TD-02 §5.7 lines 814-873, TD-02 §9.4 2036-2102 |
//|          NFR-3.4, NFR-5.1, FR-4.2                                |
//|                                                                  |
//| Key contracts:                                                    |
//|  • Emit Print on every severity level ≥ m_min_level              |
//|  • Emit Alert on ERROR iff m_alert_on_error AND not throttled     |
//|  • Anti-spam throttle: per (slot, ev) tuple in 100-tick window   |
//|  • LRU eviction at 64-entry capacity (worst-case = 21 slots × 3  |
//|    high-cardinality events + 1 headroom, per TD-02 §5.7)         |
//|  • Escalation: N consecutive Error ticks → Alert + reset         |
//|  • 2-phase init: Init() first; SetStatePersistence() after SP    |
//|    construct at OnInit step 4a (Cycle 1 closure per TD-02 §7.4)  |
//+------------------------------------------------------------------+
// INCLUDE GUARD
#ifndef PHOENICISNEX_SERVICES_LOGGER_MQH
#define PHOENICISNEX_SERVICES_LOGGER_MQH

#include "../domain/EnumTypes.mqh"   // ESeverity (LOG_DEBUG..LOG_ERROR) — IMPL-002 ✅
#include "../helpers/Timestamp.mqh"  // FormatTimestampWithMs — IMPL-042 owner

// Forward declaration — full class definition lands at IMPL-047.
// Logger stores a nullable pointer; method calls are stubbed below
// until CStatePersistence is available (§6.C.5).
class CStatePersistence;

//+------------------------------------------------------------------+
//| CLogger                                                          |
//|                                                                  |
//| Throttle buffer capacity: 64 entries (per ADR-011 capacity       |
//| rationale: 21 slots × 3 high-cardinality events = 63; +1 headroom)|
//|                                                                  |
//| Throttle window: 100 ticks per (slot, ev) tuple                  |
//|   ShouldThrottleAlert returns true if the same (slot,ev) key     |
//|   fired an Alert in the last 100 ticks (m_recent_tick_count[idx] |
//|   within 100 of m_tick_counter).                                 |
//|                                                                  |
//| Escalation: EscalateIfThresholdMet tracks consecutive Error ticks |
//|   per (slot,ev); same-tick (delta=0) and adjacent (delta=1) both |
//|   count as continuation; gap > 1 resets to 1.                   |
//|   When count ≥ m_escalation_n → fire Alert + Print [ESCALATE]   |
//|   + reset counter to 0 (per TD-02 §9.4 + ADR-011).              |
//+------------------------------------------------------------------+
class CLogger
  {
private:
   //--- Configuration (set in Init)
   ESeverity         m_min_level;         // minimum severity to emit
   bool              m_alert_on_error;    // emit Alert on ERROR level
   int               m_escalation_n;      // consecutive-error threshold (ADR-011; default = 10)

   //--- Throttle buffer (LRU, capacity = 64)
   string            m_recent_keys[64];         // "(slot):(ev)" tuple key
   int               m_recent_tick_count[64];   // tick_counter at last Alert emit
   int               m_consecutive_count[64];   // ADR-011 escalation: consecutive Error tick count
   int               m_last_tick_seen[64];      // tick_counter of last Error() call (Claim 02.9 fix)
   int               m_recent_count;            // number of populated slots (0..64)

   //--- Per-tick counter (bumped by OnTickBoundary)
   int               m_tick_counter;

   //--- 2-phase init: nullable pointer to StatePersistence (wired at OnInit step 4a)
   CStatePersistence *m_state;

   //--- Init-completion flag — true after CLogger::Init() body completes.
   //    Lets Orchestrator::CleanupPartialInit distinguish "Logger heap-alloc'd
   //    but Init() never called" (Phase A failure between WireServices and
   //    Phase B step 1) from "Logger fully ready" — see fix-round-10 § 10.4.
   bool              m_initialized;

   //--- Private helpers
   string            FormatLine(ESeverity level, string slot, string ev,
                                int magic, string msg) const;
   bool              ShouldThrottleAlert(string slot, string ev);
   void              EscalateIfThresholdMet(string slot, string ev);
   int               FindOrEvictKey(string key);
   string            SeverityToString(ESeverity level) const;
   //--- Deferred bridge — body defined in StatePersistence.mqh after full class def
   //    (IMPL-047 §circular-dep pattern; forward-decl only here)
   void              _SyncThrottle(string key);

public:
   //--- Constructor — zero-init all arrays
   CLogger() : m_min_level(LOG_INFO),
               m_alert_on_error(true),
               m_escalation_n(10),
               m_recent_count(0),
               m_tick_counter(0),
               m_state(NULL),
               m_initialized(false)
     {
      ArrayInitialize(m_recent_tick_count, 0);
      ArrayInitialize(m_consecutive_count, 0);
      ArrayInitialize(m_last_tick_seen,    0);
      for(int i = 0; i < 64; i++)
         m_recent_keys[i] = "";
     }

   //--- Phase 1 init (before StatePersistence exists)
   //    Caller (Orchestrator Composition Root) passes resolved input values:
   //      (ESeverity)InpLogLevel, InpAlertOnError, InpErrorEscalationN
   //    Logger does NOT #include inputs/ (5-layer rule: services ↛ inputs)
   void              Init(ESeverity min_level, bool alert_on_error, int escalation_n);

   //--- Phase 2 setter — Orchestrator calls after StatePersistence.Init()
   //    (DI step 4a per TD-02 §7.4; Cycle 1 closure Logger ↔ StatePersistence)
   void              SetStatePersistence(CStatePersistence *state);

   //--- Severity methods (FR-4.2)
   void              Debug(string slot, string event_name, int magic, string msg);
   void              Info(string slot,  string event_name, int magic, string msg);
   void              Warn(string slot,  string event_name, int magic, string msg);
   void              Error(string slot, string event_name, int magic, string msg);

   //--- Halt-trigger bypass — always Alert, never throttled (ADR-010 halt path)
   void              ErrorBypassThrottle(string slot, string event_name, int magic, string msg);

   //--- Init-state accessor — Orchestrator::CleanupPartialInit checks this
   //    before routing emit through Error/Alert; falls back to Print otherwise.
   bool              IsInitialized() const { return m_initialized; }

   //--- Per-tick callback — Orchestrator calls once per OnTick before slot dispatch
   void              OnTickBoundary();

  }; // end class CLogger

//+------------------------------------------------------------------+
//| Init — Phase 1: store config, no StatePersistence dep yet         |
//+------------------------------------------------------------------+
void CLogger::Init(ESeverity min_level, bool alert_on_error, int escalation_n)
  {
   m_min_level       = min_level;
   m_alert_on_error  = alert_on_error;
   m_escalation_n    = (escalation_n > 0) ? escalation_n : 10;
   m_tick_counter    = 0;
   m_recent_count    = 0;
   m_state           = NULL;
   ArrayInitialize(m_recent_tick_count, 0);
   ArrayInitialize(m_consecutive_count, 0);
   ArrayInitialize(m_last_tick_seen,    0);
   for(int i = 0; i < 64; i++)
      m_recent_keys[i] = "";

   // Emit init_ok probe — E-AC [log-assertion] evidence anchor.
   // Grep pattern: grep -E '\[Phoenicis\].*\[ev=logger_init_ok\]'
   // Full orchestrator init_ok emitted by Orchestrator (IMPL-053) which
   // calls Logger.Info("system","init_ok",0,"...") — deferred until IMPL-053.
   // This stub ensures the prefix infrastructure is wired now.
   string init_line = FormatLine(LOG_INFO, "system", "logger_init_ok", 0,
                                 "Logger initialised; min_level=" +
                                 SeverityToString(min_level) +
                                 " alert_on_error=" + (alert_on_error ? "true" : "false") +
                                 " escalation_n=" + IntegerToString(m_escalation_n));
   Print(init_line);
   m_initialized = true;   // fix-round-10 § 10.4 — signal Orchestrator cleanup-emit safety
  }

//+------------------------------------------------------------------+
//| SetStatePersistence — Phase 2 setter (Cycle 1 closure)            |
//+------------------------------------------------------------------+
void CLogger::SetStatePersistence(CStatePersistence *state)
  {
   m_state = state;
  }

//+------------------------------------------------------------------+
//| Debug                                                            |
//+------------------------------------------------------------------+
void CLogger::Debug(string slot, string ev, int magic, string msg)
  {
   if(m_min_level > LOG_DEBUG)
      return;
   Print(FormatLine(LOG_DEBUG, slot, ev, magic, msg));
  }

//+------------------------------------------------------------------+
//| Info                                                             |
//+------------------------------------------------------------------+
void CLogger::Info(string slot, string ev, int magic, string msg)
  {
   if(m_min_level > LOG_INFO)
      return;
   Print(FormatLine(LOG_INFO, slot, ev, magic, msg));
  }

//+------------------------------------------------------------------+
//| Warn                                                             |
//+------------------------------------------------------------------+
void CLogger::Warn(string slot, string ev, int magic, string msg)
  {
   if(m_min_level > LOG_WARN)
      return;
   Print(FormatLine(LOG_WARN, slot, ev, magic, msg));
  }

//+------------------------------------------------------------------+
//| Error — throttled Alert; escalation tracking                      |
//+------------------------------------------------------------------+
void CLogger::Error(string slot, string ev, int magic, string msg)
  {
   // Always Print regardless of Alert throttle (NFR-5.1: Print fires 5× per E-AC)
   string line = FormatLine(LOG_ERROR, slot, ev, magic, msg);
   Print(line);

   if(m_alert_on_error)
     {
      if(!ShouldThrottleAlert(slot, ev))
        {
         Alert(line);
        }
      else
        {
         // Throttled — record suppressed count in StatePersistence if available
         _SyncThrottle(slot + ":" + ev);
        }
     }

   EscalateIfThresholdMet(slot, ev);
  }

//+------------------------------------------------------------------+
//| ErrorBypassThrottle — always Alert, never throttled               |
//| Use for halt-trigger paths (ADR-010 + NFR-5.1 halt path)          |
//+------------------------------------------------------------------+
void CLogger::ErrorBypassThrottle(string slot, string ev, int magic, string msg)
  {
   string line = FormatLine(LOG_ERROR, slot, ev, magic, msg);
   Print(line);
   if(m_alert_on_error)
      Alert(line);
  }

//+------------------------------------------------------------------+
//| OnTickBoundary — increment tick counter (call once per OnTick)    |
//+------------------------------------------------------------------+
void CLogger::OnTickBoundary()
  {
   m_tick_counter++;
  }

//+------------------------------------------------------------------+
//| FormatLine — §6.C.4 reconciliation:                               |
//|   Prepend [Phoenicis] stable grep prefix (per IMPL-008/009/014)   |
//|   then ADR-011 format: [TS][LEVEL][slot=X][ev=E][magic=N] msg     |
//|   Timestamp: ISO-8601 from FormatTimestampWithMs; then            |
//|     T → space  (ADR-011 sep = space; journal keeps T)             |
//|     Z → ""     (strip; Experts log local view)                    |
//|                                                                  |
//| Result format example:                                            |
//|   [Phoenicis][2026-05-02 14:23:45.123][INFO][slot=system]         |
//|              [ev=init_ok][magic=0] msg here                       |
//+------------------------------------------------------------------+
string CLogger::FormatLine(ESeverity level, string slot, string ev,
                           int magic, string msg) const
  {
   string ts = FormatTimestampWithMs(TimeCurrent(), GetMicrosecondCount());
   StringReplace(ts, "T", " ");   // ADR-011: space separator for Experts log view
   StringReplace(ts, "Z", "");    // strip Z suffix (journal uses Z; Experts log local)
   return StringFormat("[Phoenicis][%s][%s][slot=%s][ev=%s][magic=%d] %s",
                       ts, SeverityToString(level), slot, ev, magic, msg);
  }

//+------------------------------------------------------------------+
//| SeverityToString — ADR-011 level labels                           |
//+------------------------------------------------------------------+
string CLogger::SeverityToString(ESeverity level) const
  {
   switch(level)
     {
      case LOG_DEBUG: return "DEBUG";
      case LOG_INFO:  return "INFO";
      case LOG_WARN:  return "WARN";
      case LOG_ERROR: return "ERROR";
      default:        return "UNKNOWN";
     }
  }

//+------------------------------------------------------------------+
//| ShouldThrottleAlert — returns true if (slot,ev) tuple fired an    |
//| Alert within the last 100 ticks.                                  |
//| Side-effect: if NOT throttled, records this tick as the new       |
//| baseline for the tuple (registers or updates m_recent_tick_count).|
//+------------------------------------------------------------------+
bool CLogger::ShouldThrottleAlert(string slot, string ev)
  {
   string key = slot + ":" + ev;
   int idx    = FindOrEvictKey(key);

   // Check if an Alert was already emitted within the last 100 ticks
   int delta = m_tick_counter - m_recent_tick_count[idx];
   if(m_recent_keys[idx] == key && delta < 100)
      return true;  // throttle — Alert was emitted recently

   // Not throttled — update record and allow Alert to fire
   m_recent_keys[idx]       = key;
   m_recent_tick_count[idx] = m_tick_counter;
   return false;
  }

//+------------------------------------------------------------------+
//| EscalateIfThresholdMet — gap-aware consecutive Error tick tracker  |
//|                                                                  |
//| Semantic (per TD-02 §9.4 + S-AC):                                 |
//|   same-tick (delta=0) and adjacent (delta=1) both = continuation  |
//|   gap > 1 → reset consecutive_count to 1                          |
//|   when consecutive_count ≥ m_escalation_n →                       |
//|     Alert "Sustained error..." + Print "[ESCALATE] ..."           |
//|     + reset to 0                                                  |
//+------------------------------------------------------------------+
void CLogger::EscalateIfThresholdMet(string slot, string ev)
  {
   string key = slot + ":" + ev;
   int idx    = FindOrEvictKey(key);

   int delta = m_tick_counter - m_last_tick_seen[idx];

   // delta=0 (same tick burst) or delta=1 (adjacent tick) → continuation
   if(delta == 0 || delta == 1)
     {
      m_consecutive_count[idx]++;
     }
   else
     {
      // Gap > 1 — not a sustained run; reset to 1
      m_consecutive_count[idx] = 1;
     }
   m_last_tick_seen[idx] = m_tick_counter;

   if(m_consecutive_count[idx] >= m_escalation_n)
     {
      string sec = StringFormat(
                     "Sustained error: %s/%s \xd7 %d consecutive ticks \x2014 investigate",
                     slot, ev, m_consecutive_count[idx]);
      Alert(sec);
      Print("[ESCALATE] " + sec);
      _SyncThrottle(slot + ":" + ev);
      m_consecutive_count[idx] = 0;
     }
  }

//+------------------------------------------------------------------+
//| FindOrEvictKey — LRU lookup + eviction                            |
//|                                                                  |
//| Algorithm:                                                        |
//|   1. Linear scan for exact key match → return idx                 |
//|   2. If buffer not full → append new entry at m_recent_count      |
//|   3. If full → evict entry with oldest m_recent_tick_count (LRU)  |
//|      + emit Logger.Warn "throttle_buffer_evicted" for visibility  |
//|      + reset m_consecutive_count[idx]=0 + m_last_tick_seen[idx]=0 |
//|        (eviction-reuse contract per TD-02 §5.7 line 586 + S-AC)  |
//|                                                                  |
//| Returns: index ≥ 0 into m_recent_keys[64] arrays                 |
//+------------------------------------------------------------------+
int CLogger::FindOrEvictKey(string key)
  {
   // Step 1: scan for exact match
   for(int i = 0; i < m_recent_count; i++)
     {
      if(m_recent_keys[i] == key)
         return i;
     }

   // Step 2: buffer has free slots — append
   if(m_recent_count < 64)
     {
      int idx = m_recent_count;
      m_recent_keys[idx]       = key;
      m_recent_tick_count[idx] = m_tick_counter;
      m_consecutive_count[idx] = 0;
      m_last_tick_seen[idx]    = 0;
      m_recent_count++;
      return idx;
     }

   // Step 3: buffer full — evict LRU (oldest m_recent_tick_count)
   int evict_idx  = 0;
   int oldest_tick = m_recent_tick_count[0];
   for(int i = 1; i < 64; i++)
     {
      if(m_recent_tick_count[i] < oldest_tick)
        {
         oldest_tick = m_recent_tick_count[i];
         evict_idx   = i;
        }
     }

   // Emit eviction warn for visibility (per TD-02 §5.7 capacity rationale)
   Print(FormatLine(LOG_WARN, "system", "throttle_buffer_evicted", 0,
                   "LRU evict key=" + m_recent_keys[evict_idx] +
                   " (tick=" + IntegerToString(oldest_tick) + ") for key=" + key));

   // Reset eviction-reuse state (S-AC: consecutive_count=0 + last_tick_seen=0)
   m_recent_keys[evict_idx]       = key;
   m_recent_tick_count[evict_idx] = m_tick_counter;
   m_consecutive_count[evict_idx] = 0;
   m_last_tick_seen[evict_idx]    = 0;

   return evict_idx;
  }

#endif // PHOENICISNEX_SERVICES_LOGGER_MQH
