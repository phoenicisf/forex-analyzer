//+------------------------------------------------------------------+
//| PendingMachineRegistry.mqh — 8 pending state machines (IMPL-049)|
//| Layer:   services/                                               |
//| Source:  TD-02 §5.10, ADR-008 (force-clear policy),              |
//|          BR-6.1..6.8 (legacy timeouts), Claim 02.10 (P-Pending). |
//|                                                                  |
//| Sub-pass (a) — registry skeleton + dispatch + CPendingForce      |
//| router. TickMachine bodies + force-clear logic land in (b)/(c);  |
//| state.json round-trip wiring + SelfTest land in (d).             |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_PENDINGMACHINEREGISTRY_MQH
#define PHOENICISNEX_SERVICES_PENDINGMACHINEREGISTRY_MQH

#include "../domain/EnumTypes.mqh"
#include "../domain/MarketContext.mqh"
#include "Logger.mqh"
#include "PortfolioState.mqh"
#include "StatePersistence.mqh"
#include "TradeJournal.mqh"

//+------------------------------------------------------------------+
//| MachineState — RAM cache mirror of state.json pending_machines  |
//| One entry per EPendingMachineId (PM_C..PM_FORCE = 8 slots).      |
//+------------------------------------------------------------------+
struct MachineState
  {
   EPendingState     state;                  // IDLE / PENDING / EXECUTED
   int               pending_started_bar;    // bar_index_h4 when EnterPending called
   string            pending_payload;        // opaque JSON per machine (ADR-008)
   int               force_clear_count;      // monotonic per-machine counter
  };

//+------------------------------------------------------------------+
//| CPendingForce — force-pending payload router                     |
//| Helper for cross-slot force-pending workflow (D-from-C, BR-from-B|
//| parent payloads per BR-2.1 + BR-6.8). Encodes/decodes a small    |
//| JSON envelope stored in MachineState[PM_FORCE].pending_payload.  |
//|                                                                  |
//| Payload schema:                                                  |
//|   {"origin":"C","parent_ticket":12345,"direction":1,"bar":42}    |
//+------------------------------------------------------------------+
class CPendingForce
  {
public:
   //--- Build a force-pending payload string. Caller stores result via
   //    CPendingMachineRegistry::EnterPending(PM_FORCE, payload, bar).
   static string     BuildPayload(string origin_slot, ulong parent_ticket,
                                  int direction, int started_bar)
     {
      string out = "{";
      out += "\"origin\":\""        + origin_slot + "\",";
      out += "\"parent_ticket\":"   + (string)parent_ticket + ",";
      out += "\"direction\":"       + IntegerToString(direction) + ",";
      out += "\"bar\":"             + IntegerToString(started_bar);
      out += "}";
      return out;
     }

   //--- Parse a previously-built payload back to fields. Returns false on
   //    malformed input (caller treats as IDLE). Minimal substring scan;
   //    intentional — JsonWriter is one-way, payloads are opaque to schema.
   static bool       ParsePayload(string payload,
                                  string &out_origin, ulong &out_parent_ticket,
                                  int &out_direction, int &out_bar)
     {
      out_origin        = "";
      out_parent_ticket = 0;
      out_direction     = 0;
      out_bar           = 0;

      if(StringLen(payload) == 0) return false;

      out_origin        = _ExtractStr(payload, "origin");
      out_parent_ticket = (ulong)_ExtractInt(payload, "parent_ticket");
      out_direction     = (int)_ExtractInt(payload, "direction");
      out_bar           = (int)_ExtractInt(payload, "bar");
      return (StringLen(out_origin) > 0);
     }

private:
   //--- Minimal local JSON field extractors (string + int). Scoped private
   //    to CPendingForce — distinct from CStatePersistence::_Extract* which
   //    are class-private. Duplication is intentional to keep PendingForce
   //    self-contained and avoid coupling helpers across services.
   static string     _ExtractStr(const string content, const string field)
     {
      string needle = "\"" + field + "\":\"";
      int p = StringFind(content, needle);
      if(p < 0) return "";
      p += StringLen(needle);
      int q = StringFind(content, "\"", p);
      if(q < 0) return "";
      return StringSubstr(content, p, q - p);
     }

   static long       _ExtractInt(const string content, const string field)
     {
      string needle = "\"" + field + "\":";
      int p = StringFind(content, needle);
      if(p < 0) return 0;
      p += StringLen(needle);
      // skip whitespace
      while(p < StringLen(content) && (StringGetCharacter(content, p) == ' ' ||
                                       StringGetCharacter(content, p) == '\t'))
         p++;
      int q = p;
      ushort ch;
      while(q < StringLen(content))
        {
         ch = StringGetCharacter(content, q);
         if((ch >= '0' && ch <= '9') || ch == '-') q++;
         else break;
        }
      if(q == p) return 0;
      return (long)StringToInteger(StringSubstr(content, p, q - p));
     }
  };

//+------------------------------------------------------------------+
//| CPendingMachineRegistry                                          |
//+------------------------------------------------------------------+
class CPendingMachineRegistry
  {
private:
   //--- Per-machine RAM cache (mirrors state.json on Init; flushed end-of-tick)
   MachineState      m_machines[PM_COUNT];

   //--- Force-clear thresholds (ADR-008)
   int               m_threshold_m_bars;
   int               m_threshold_t_bars;
   int               m_threshold_q_bars;

   //--- Legacy timeouts (BR-6.1..6.4 + BR-6.8)
   int               m_legacy_c_bars;
   int               m_legacy_c_adx_bars;
   int               m_legacy_r_bars;
   int               m_legacy_p_bars;
   int               m_legacy_force_bars;

   //--- Injected deps (Composition Root in Orchestrator)
   CStatePersistence *m_state;
   CTradeJournal     *m_journal;
   CLogger           *m_logger;
   CPortfolioState   *m_portfolio;

   //--- Sub-pass (b)/(c) bodies — stub here, return without action.
   void              TickMachine(EPendingMachineId id, const MarketContext &ctx,
                                 CPortfolioState &port);
   bool              ShouldForceClear(EPendingMachineId id, int current_bar) const;
   void              EmitForceClear(EPendingMachineId id, int age_bars);

   //--- Stable string id for log/journal events (matches BR-6.x slot codes).
   string            _IdToCode(EPendingMachineId id) const
     {
      switch(id)
        {
         case PM_C:     return "C";
         case PM_C_ADX: return "C_ADX";
         case PM_R:     return "R";
         case PM_P:     return "P";
         case PM_M:     return "M";
         case PM_T:     return "T";
         case PM_Q:     return "Q";
         case PM_FORCE: return "FORCE";
        }
      return "?";
     }

public:
                     CPendingMachineRegistry()
      : m_threshold_m_bars(150),
        m_threshold_t_bars(80),
        m_threshold_q_bars(100),
        m_legacy_c_bars(8),
        m_legacy_c_adx_bars(30),
        m_legacy_r_bars(40),
        m_legacy_p_bars(70),
        m_legacy_force_bars(9),
        m_state(NULL), m_journal(NULL), m_logger(NULL), m_portfolio(NULL)
     {
      for(int i = 0; i < PM_COUNT; i++)
        {
         m_machines[i].state               = PENDING_STATE_IDLE;
         m_machines[i].pending_started_bar = 0;
         m_machines[i].pending_payload     = "";
         m_machines[i].force_clear_count   = 0;
        }
     }

   //--- Init — 13-arg form per TD-02 §5.10 (8 thresholds/timeouts + 4 deps).
   //    Called by Orchestrator Composition Root after StatePersistence + Journal
   //    + Logger + PortfolioState are themselves initialised (DI step ~13).
   void              Init(int threshold_m_bars,
                          int threshold_t_bars,
                          int threshold_q_bars,
                          int legacy_c_bars,
                          int legacy_c_adx_bars,
                          int legacy_r_bars,
                          int legacy_p_bars,
                          int legacy_force_bars,
                          CStatePersistence *state,
                          CTradeJournal *journal,
                          CLogger *logger,
                          CPortfolioState *port)
     {
      m_threshold_m_bars   = threshold_m_bars;
      m_threshold_t_bars   = threshold_t_bars;
      m_threshold_q_bars   = threshold_q_bars;
      m_legacy_c_bars      = legacy_c_bars;
      m_legacy_c_adx_bars  = legacy_c_adx_bars;
      m_legacy_r_bars      = legacy_r_bars;
      m_legacy_p_bars      = legacy_p_bars;
      m_legacy_force_bars  = legacy_force_bars;
      m_state              = state;
      m_journal            = journal;
      m_logger             = logger;
      m_portfolio          = port;

      // Pull warm cache from state.json (sub-pass (a) skeleton — full body in (d))
      LoadFromState();
     }

   //--- TickAll — Orchestrator OnTick step 8 (per TD-02 §9.4 line 1530).
   //    Iterates all 8 machines; per-machine bodies stubbed in (a), filled in (b)/(c).
   void              TickAll(const MarketContext &ctx, CPortfolioState &port)
     {
      for(int i = 0; i < PM_COUNT; i++)
         TickMachine((EPendingMachineId)i, ctx, port);
     }

   //--- Slot read accessors (called from Slot_X.mqh PendingState() override)
   EPendingState     GetState(EPendingMachineId id) const
     {
      if(id < 0 || id >= PM_COUNT) return PENDING_STATE_IDLE;
      return m_machines[id].state;
     }

   string            GetPayload(EPendingMachineId id) const
     {
      if(id < 0 || id >= PM_COUNT) return "";
      return m_machines[id].pending_payload;
     }

   int               GetForceClearCount(EPendingMachineId id) const
     {
      if(id < 0 || id >= PM_COUNT) return 0;
      return m_machines[id].force_clear_count;
     }

   //--- Slot transition helpers (Evaluate / ManageExits call these)
   void              EnterPending(EPendingMachineId id, string payload, int current_bar)
     {
      if(id < 0 || id >= PM_COUNT) return;
      m_machines[id].state               = PENDING_STATE_PENDING;
      m_machines[id].pending_started_bar = current_bar;
      m_machines[id].pending_payload     = payload;
      if(m_logger != NULL)
         m_logger.Info("pending", "enter_pending", 0,
                       StringFormat("machine=%s bar=%d", _IdToCode(id), current_bar));
     }

   void              TransitionExecuted(EPendingMachineId id)
     {
      if(id < 0 || id >= PM_COUNT) return;
      m_machines[id].state = PENDING_STATE_EXECUTED;
      if(m_logger != NULL)
         m_logger.Info("pending", "transition_executed", 0,
                       StringFormat("machine=%s", _IdToCode(id)));
     }

   void              TransitionIdle(EPendingMachineId id, string reason)
     {
      if(id < 0 || id >= PM_COUNT) return;
      m_machines[id].state               = PENDING_STATE_IDLE;
      m_machines[id].pending_started_bar = 0;
      m_machines[id].pending_payload     = "";
      if(m_logger != NULL)
         m_logger.Info("pending", "transition_idle", 0,
                       StringFormat("machine=%s reason=%s", _IdToCode(id), reason));
     }

   //--- State round-trip primitives (full integration in sub-pass (d)).
   //    LoadFromState pulls all 8 entries from CStatePersistence accessors;
   //    SaveToState pushes back. Defensive — NULL m_state is no-op so callers
   //    unaware of init order don't crash.
   void              LoadFromState()
     {
      if(m_state == NULL) return;
      for(int i = 0; i < PM_COUNT; i++)
        {
         EPendingMachineId id = (EPendingMachineId)i;
         m_machines[i].state               = m_state.GetPendingState(id);
         m_machines[i].pending_payload     = m_state.GetPendingPayload(id);
         m_machines[i].force_clear_count   = m_state.GetPmForceClearCount(id);
         // pending_started_bar lives only in RAM during a session; state.json
         // round-trips via SetPendingPayload (started_bar arg). On cold boot
         // the timer effectively resets — acceptable per ADR-008 (timeouts are
         // soft: legacy timeout fires on next tick after restart, force-clear
         // requires multi-bar age which a fresh RAM start delays by at most
         // one full threshold window).
         m_machines[i].pending_started_bar = 0;
        }
     }

   void              SaveToState()
     {
      if(m_state == NULL) return;
      for(int i = 0; i < PM_COUNT; i++)
        {
         EPendingMachineId id = (EPendingMachineId)i;
         m_state.SetPendingState(id, m_machines[i].state);
         m_state.SetPendingPayload(id, m_machines[i].pending_payload,
                                   m_machines[i].pending_started_bar);
        }
     }
  };

//+------------------------------------------------------------------+
//| TickMachine — per-machine dispatch (stubbed in sub-pass (a))     |
//| Sub-pass (b) fills C / C_ADX / R / P legacy-timeout branches.    |
//| Sub-pass (c) fills M / T / Q force-clear branches.               |
//| PM_FORCE has no time-based action — timeout enforced via legacy  |
//| C-equivalent path in (b).                                        |
//+------------------------------------------------------------------+
void CPendingMachineRegistry::TickMachine(EPendingMachineId id,
                                          const MarketContext &ctx,
                                          CPortfolioState &port)
  {
   // Skeleton no-op — bodies land in (b)/(c).
   if(id < 0 || id >= PM_COUNT) return;
   if(m_machines[id].state != PENDING_STATE_PENDING) return;
   // Touch ctx + port to keep signature stable across sub-passes.
   if(ctx.bar_index_h4 < 0 && port.GetByMagic(0) == NULL) return;
  }

//+------------------------------------------------------------------+
//| ShouldForceClear — stub (sub-pass (c))                           |
//+------------------------------------------------------------------+
bool CPendingMachineRegistry::ShouldForceClear(EPendingMachineId id,
                                               int current_bar) const
  {
   if(id < 0 || id >= PM_COUNT) return false;
   if(current_bar < 0)         return false;
   return false;
  }

//+------------------------------------------------------------------+
//| EmitForceClear — stub (sub-pass (c))                             |
//+------------------------------------------------------------------+
void CPendingMachineRegistry::EmitForceClear(EPendingMachineId id, int age_bars)
  {
   if(id < 0 || id >= PM_COUNT) return;
   if(age_bars < 0)             return;
  }

#endif // PHOENICISNEX_SERVICES_PENDINGMACHINEREGISTRY_MQH
