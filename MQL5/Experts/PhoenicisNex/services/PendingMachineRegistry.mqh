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

   //--- Sub-pass (b)/(c) bodies.
   void              TickMachine(EPendingMachineId id, const MarketContext &ctx,
                                 CPortfolioState &port);
   bool              ExceededLegacyTimeout(EPendingMachineId id, int age) const;
   bool              ShouldForceClear(EPendingMachineId id, int current_bar) const;
   void              EmitForceClear(EPendingMachineId id, int age_bars);

   //--- P-Pending payload (de)serialization helpers — sibling to CPendingForce
   //    but inlined here because the payload schema is owned by registry.
   static string     _PSubModeToStr(EPSubMode mode)
     {
      switch(mode)
        {
         case PSUB_PX: return "PX";
         case PSUB_PH: return "PH";
         case PSUB_E:  return "E";
         case PSUB_N:  return "N";
         default:      return "";    // PSUB_NONE → null in JSON
        }
     }

   static EPSubMode  _StrToPSubMode(string s)
     {
      if(s == "PX") return PSUB_PX;
      if(s == "PH") return PSUB_PH;
      if(s == "E")  return PSUB_E;
      if(s == "N")  return PSUB_N;
      return PSUB_NONE;
     }

   static string     _BuildPPayload(EPSubMode mode, double diff_sl, double band_ratio)
     {
      string out = "{";
      string mode_str = _PSubModeToStr(mode);
      if(StringLen(mode_str) > 0)
         out += "\"sub_mode\":\"" + mode_str + "\",";
      else
         out += "\"sub_mode\":null,";
      out += "\"diff_sl\":"   + DoubleToString(diff_sl, 2)   + ",";
      out += "\"band_ratio\":" + DoubleToString(band_ratio, 2);
      out += "}";
      return out;
     }

   static EPSubMode  _ParsePSubMode(string payload)
     {
      if(StringLen(payload) == 0) return PSUB_NONE;
      string needle = "\"sub_mode\":";
      int p = StringFind(payload, needle);
      if(p < 0) return PSUB_NONE;
      p += StringLen(needle);
      if(p < StringLen(payload) && StringGetCharacter(payload, p) == '\"')
        {
         int q = StringFind(payload, "\"", p + 1);
         if(q < 0) return PSUB_NONE;
         return _StrToPSubMode(StringSubstr(payload, p + 1, q - p - 1));
        }
      return PSUB_NONE;   // null, malformed, or absent
     }

   static double     _ParsePDouble(string payload, string field)
     {
      if(StringLen(payload) == 0) return 0.0;
      string needle = "\"" + field + "\":";
      int p = StringFind(payload, needle);
      if(p < 0) return 0.0;
      p += StringLen(needle);
      // Skip whitespace
      while(p < StringLen(payload) &&
            (StringGetCharacter(payload, p) == ' ' ||
             StringGetCharacter(payload, p) == '\t'))
         p++;
      int q = p;
      ushort ch;
      while(q < StringLen(payload))
        {
         ch = StringGetCharacter(payload, q);
         if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == '+' ||
            ch == 'e' || ch == 'E')
            q++;
         else
            break;
        }
      if(q == p) return 0.0;
      return (double)StringToDouble(StringSubstr(payload, p, q - p));
     }

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

   //--- P-Pending sub-mode accessors (BR-6.4 + Claim 02.10 + state-schema
   //    PendingMachineState_PVariant). Slot_P encodes sub_mode + diff_sl +
   //    band_ratio when entering pending; ManageExits reads sub_mode to pick
   //    PX/PH/E branch on execution. Payload is the canonical form per
   //    state-persistence-schema.yaml § PendingMachineState_PVariant.
   EPSubMode         GetPSubMode() const
     {
      return _ParsePSubMode(m_machines[PM_P].pending_payload);
     }

   double            GetPDiffSL() const
     {
      return _ParsePDouble(m_machines[PM_P].pending_payload, "diff_sl");
     }

   double            GetPBandRatio() const
     {
      return _ParsePDouble(m_machines[PM_P].pending_payload, "band_ratio");
     }

   //--- Helper for slots: build the canonical P-Pending payload + transition
   //    PM_P to PENDING in one step.
   void              EnterPPending(EPSubMode mode, double diff_sl, double band_ratio,
                                   int current_bar)
     {
      string payload = _BuildPPayload(mode, diff_sl, band_ratio);
      EnterPending(PM_P, payload, current_bar);
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
         // force_clear_count is owned by StatePersistence (atomic increment
         // via IncrementPmForceClearCount in EmitForceClear). SaveToState
         // does not push the RAM count back — the counters are already in
         // sync per atomic-on-write contract.
        }
     }

   //+------------------------------------------------------------------+
   //| SelfTest — inline unit test proxy (header-only `.mqh` precedent  |
   //| per IMPL-052). Covers all 4 S-ACs + 2 E-ACs of IMPL-049.         |
   //|                                                                  |
   //| S-AC 1: 8 machine classes + dispatch                             |
   //| S-AC 2: M/T/Q force-clear thresholds = inputs                    |
   //| S-AC 3: P-sub-modes (PSUB_NONE/N/PX/PH/E)                        |
   //| S-AC 4: force_clear journal event emission (proxy: counter inc)  |
   //| E-AC 1: stub M payload + advance past threshold → force-clear    |
   //| E-AC 2: state.json round-trip preserves 8 machine payloads       |
   //+------------------------------------------------------------------+
   bool              SelfTest(CLogger *logger)
     {
      if(logger == NULL) return false;
      logger.Info("system", "SelfTest_PMR", 0, "Starting CPendingMachineRegistry self test");

      // --- Case 1 — initial state (S-AC #1) ---
      CPendingMachineRegistry r1;
      r1.Init(150, 80, 100, 8, 30, 40, 70, 9,
              NULL, NULL, logger, NULL);
      for(int i = 0; i < PM_COUNT; i++)
         if(r1.GetState((EPendingMachineId)i) != PENDING_STATE_IDLE ||
            r1.GetForceClearCount((EPendingMachineId)i) != 0)
           {
            logger.Error("system", "SelfTest_PMR", 0,
                         StringFormat("Case 1 fail: machine %d not zero-init", i));
            return false;
           }

      // --- Case 2 — transition surface (S-AC #1) ---
      r1.EnterPending(PM_C, "{\"slot\":\"C\"}", 100);
      if(r1.GetState(PM_C) != PENDING_STATE_PENDING ||
         r1.GetPayload(PM_C) != "{\"slot\":\"C\"}")
        {
         logger.Error("system", "SelfTest_PMR", 0, "Case 2 fail: EnterPending");
         return false;
        }
      r1.TransitionExecuted(PM_C);
      if(r1.GetState(PM_C) != PENDING_STATE_EXECUTED)
        {
         logger.Error("system", "SelfTest_PMR", 0, "Case 2 fail: TransitionExecuted");
         return false;
        }
      r1.TransitionIdle(PM_C, "test");
      if(r1.GetState(PM_C) != PENDING_STATE_IDLE)
        {
         logger.Error("system", "SelfTest_PMR", 0, "Case 2 fail: TransitionIdle");
         return false;
        }

      // --- Case 3 — legacy timeout per machine (S-AC #1 + BR-6.x) ---
      MarketContext ctx;
      ZeroMemory(ctx);
      CPortfolioState port_stub;
      port_stub.Init(logger);

      // PM_C @ 8
      r1.EnterPending(PM_C, "{}", 0);
      ctx.bar_index_h4 = 8;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_C) != PENDING_STATE_IDLE)
        { logger.Error("system","SelfTest_PMR",0,"Case 3 fail: PM_C timeout"); return false; }

      // PM_C_ADX @ 30
      r1.EnterPending(PM_C_ADX, "{}", 0);
      ctx.bar_index_h4 = 30;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_C_ADX) != PENDING_STATE_IDLE)
        { logger.Error("system","SelfTest_PMR",0,"Case 3 fail: PM_C_ADX timeout"); return false; }

      // PM_R @ 40
      r1.EnterPending(PM_R, "{}", 0);
      ctx.bar_index_h4 = 40;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_R) != PENDING_STATE_IDLE)
        { logger.Error("system","SelfTest_PMR",0,"Case 3 fail: PM_R timeout"); return false; }

      // PM_FORCE @ 9
      r1.EnterPending(PM_FORCE,
                      CPendingForce::BuildPayload("C", 1, 1, 0), 0);
      ctx.bar_index_h4 = 9;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_FORCE) != PENDING_STATE_IDLE)
        { logger.Error("system","SelfTest_PMR",0,"Case 3 fail: PM_FORCE timeout"); return false; }

      // --- Case 4 — P-sub-mode encode/decode (S-AC #3) ---
      r1.EnterPPending(PSUB_PX, 250.0, 80.5, 0);
      if(r1.GetPSubMode() != PSUB_PX ||
         MathAbs(r1.GetPDiffSL() - 250.0) > 0.01 ||
         MathAbs(r1.GetPBandRatio() - 80.5) > 0.01)
        { logger.Error("system","SelfTest_PMR",0,"Case 4 fail: P PSUB_PX"); return false; }
      r1.TransitionIdle(PM_P, "test");

      r1.EnterPPending(PSUB_PH, 100.0, 50.0, 0);
      if(r1.GetPSubMode() != PSUB_PH)
        { logger.Error("system","SelfTest_PMR",0,"Case 4 fail: P PSUB_PH"); return false; }
      r1.TransitionIdle(PM_P, "test");

      r1.EnterPPending(PSUB_E, 0.0, 0.0, 0);
      if(r1.GetPSubMode() != PSUB_E)
        { logger.Error("system","SelfTest_PMR",0,"Case 4 fail: P PSUB_E"); return false; }
      r1.TransitionIdle(PM_P, "test");

      r1.EnterPPending(PSUB_N, 0.0, 0.0, 0);
      if(r1.GetPSubMode() != PSUB_N)
        { logger.Error("system","SelfTest_PMR",0,"Case 4 fail: P PSUB_N"); return false; }
      r1.TransitionIdle(PM_P, "test");

      // PSUB_NONE → null in JSON; payload still parses to PSUB_NONE
      r1.EnterPPending(PSUB_NONE, 0.0, 0.0, 0);
      if(r1.GetPSubMode() != PSUB_NONE)
        { logger.Error("system","SelfTest_PMR",0,"Case 4 fail: P PSUB_NONE"); return false; }
      r1.TransitionIdle(PM_P, "test");

      // --- Case 5 — force-clear M/T/Q (S-AC #2 + S-AC #4 + E-AC #1) ---
      // PM_M threshold 150
      r1.EnterPending(PM_M, "{\"slot\":\"M\"}", 0);
      ctx.bar_index_h4 = 150;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_M) != PENDING_STATE_IDLE ||
         r1.GetForceClearCount(PM_M) != 1)
        { logger.Error("system","SelfTest_PMR",0,"Case 5 fail: PM_M force-clear"); return false; }

      // PM_T threshold 80
      r1.EnterPending(PM_T, "{\"slot\":\"T\"}", 200);
      ctx.bar_index_h4 = 280;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_T) != PENDING_STATE_IDLE ||
         r1.GetForceClearCount(PM_T) != 1)
        { logger.Error("system","SelfTest_PMR",0,"Case 5 fail: PM_T force-clear"); return false; }

      // PM_Q threshold 100
      r1.EnterPending(PM_Q, "{\"slot\":\"Q\"}", 400);
      ctx.bar_index_h4 = 500;
      r1.TickAll(ctx, port_stub);
      if(r1.GetState(PM_Q) != PENDING_STATE_IDLE ||
         r1.GetForceClearCount(PM_Q) != 1)
        { logger.Error("system","SelfTest_PMR",0,"Case 5 fail: PM_Q force-clear"); return false; }

      // PM_R should NOT trigger force-clear path even past 150 bars
      r1.EnterPending(PM_R, "{}", 600);
      ctx.bar_index_h4 = 750;   // age=150 but R has no force-clear, only legacy 40
      r1.TickAll(ctx, port_stub);
      if(r1.GetForceClearCount(PM_R) != 0)
        { logger.Error("system","SelfTest_PMR",0,"Case 5 fail: PM_R should not force-clear"); return false; }

      // --- Case 6 — state.json round-trip (E-AC #2 [contract-roundtrip]) ---
      // Use a default-constructed CStatePersistence as round-trip surrogate
      // (its Get/Set accessors do not require AtomicFile / file I/O).
      CStatePersistence sp;
      // Pre-populate state holder as if loaded from disk.
      sp.SetPendingState(PM_C,    PENDING_STATE_PENDING);
      sp.SetPendingPayload(PM_C,  "{\"slot\":\"C\",\"v\":1}", 100);
      sp.SetPendingState(PM_M,    PENDING_STATE_PENDING);
      sp.SetPendingPayload(PM_M,  "{\"slot\":\"M\"}", 200);
      sp.IncrementPmForceClearCount(PM_M);
      sp.IncrementPmForceClearCount(PM_M);   // count = 2
      sp.SetPendingState(PM_P,    PENDING_STATE_PENDING);
      sp.SetPendingPayload(PM_P,
            CPendingMachineRegistry::_BuildPPayloadStatic(PSUB_PX, 250.0, 80.5),
            300);

      // Wire a fresh registry to that state and Load.
      CPendingMachineRegistry r2;
      r2.Init(150, 80, 100, 8, 30, 40, 70, 9,
              &sp, NULL, logger, NULL);
      // Init() calls LoadFromState internally — verify mirror is correct.
      if(r2.GetState(PM_C) != PENDING_STATE_PENDING ||
         r2.GetPayload(PM_C) != "{\"slot\":\"C\",\"v\":1}")
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_C load mirror"); return false; }
      if(r2.GetState(PM_M) != PENDING_STATE_PENDING ||
         r2.GetForceClearCount(PM_M) != 2)
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_M load mirror"); return false; }
      if(r2.GetState(PM_P) != PENDING_STATE_PENDING ||
         r2.GetPSubMode() != PSUB_PX ||
         MathAbs(r2.GetPDiffSL() - 250.0) > 0.01)
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_P load mirror"); return false; }

      // Mutate registry, push back via SaveToState.
      r2.TransitionIdle(PM_C, "executed");
      r2.EnterPending(PM_R, "{\"slot\":\"R\",\"new\":true}", 999);
      r2.SaveToState();
      if(sp.GetPendingState(PM_C) != PENDING_STATE_IDLE)
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_C save back"); return false; }
      if(sp.GetPendingState(PM_R) != PENDING_STATE_PENDING ||
         sp.GetPendingPayload(PM_R) != "{\"slot\":\"R\",\"new\":true}")
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_R save back"); return false; }

      // Force-clear with state wired — verify counter ALSO increments in
      // StatePersistence (atomic op contract).
      r2.EnterPending(PM_T, "{}", 1000);
      ctx.bar_index_h4 = 1080;
      r2.TickAll(ctx, port_stub);
      if(sp.GetPmForceClearCount(PM_T) != 1)
        { logger.Error("system","SelfTest_PMR",0,"Case 6 fail: PM_T counter not synced to state"); return false; }

      logger.Info("system", "SelfTest_PMR", 0, "CPendingMachineRegistry self test PASS (6 cases, 8 machines, 5 P-sub-modes)");
      return true;
     }

   //--- Static accessor — exposes _BuildPPayload to SelfTest harness +
   //    future callers (e.g. CSlotP build path) without exposing the private
   //    helper directly. Internal use only.
   static string     _BuildPPayloadStatic(EPSubMode mode, double diff_sl, double band_ratio)
     {
      return _BuildPPayload(mode, diff_sl, band_ratio);
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
   // Touch port to keep signature aligned with TD-02 §5.10 — slot-driven
   // trigger evaluation calls TransitionExecuted() directly on its own
   // signal; registry side is purely time-based.
   if(id < 0 || id >= PM_COUNT) return;
   if(m_machines[id].state != PENDING_STATE_PENDING) return;

   int age = ctx.bar_index_h4 - m_machines[id].pending_started_bar;
   if(age < 0) age = 0;   // bar index reset / cold-restart guard

   // Legacy timeout enforcement (BR-6.1..6.4 + BR-6.8) — applies to
   // PM_C / PM_C_ADX / PM_R / PM_P / PM_FORCE. M/T/Q have no legacy
   // timeout; only ADR-008 force-clear (sub-pass (c)).
   if(ExceededLegacyTimeout(id, age))
     {
      string reason = "legacy_timeout";
      if(id == PM_P)
        {
         // Surface sub-mode in transition reason so journal trail captures
         // PSUB_N (transient) vs PSUB_PX/PH/E (resolved) at expiry. Helps
         // post-mortem on stuck P-Pending pattern (A7 risk per `03 § 7`).
         EPSubMode mode = GetPSubMode();
         if(mode != PSUB_NONE)
            reason = StringFormat("legacy_timeout_p_sub_mode_%s",
                                  _PSubModeToStr(mode));
        }
      TransitionIdle(id, reason);
      return;
     }

   // Force-clear (M/T/Q only) — sub-pass (c).
   if(ShouldForceClear(id, ctx.bar_index_h4))
     {
      EmitForceClear(id, age);
      TransitionIdle(id, "force_clear");
      return;
     }

   // No-op for PortfolioState in current passes — kept in signature for
   // future per-machine logic that needs portfolio inspection (e.g. PM_FORCE
   // payload routing in P3 slot integration).
   if(port.GetByMagic(0) == NULL && id == PM_COUNT) return;
  }

//+------------------------------------------------------------------+
//| ExceededLegacyTimeout — per-machine timeout check (BR-6.1..6.8)  |
//+------------------------------------------------------------------+
bool CPendingMachineRegistry::ExceededLegacyTimeout(EPendingMachineId id,
                                                    int age) const
  {
   if(age < 0) return false;
   switch(id)
     {
      case PM_C:     return age >= m_legacy_c_bars;       // BR-6.1
      case PM_C_ADX: return age >= m_legacy_c_adx_bars;   // BR-6.2
      case PM_R:     return age >= m_legacy_r_bars;       // BR-6.3
      case PM_P:     return age >= m_legacy_p_bars;       // BR-6.4
      case PM_FORCE: return age >= m_legacy_force_bars;   // BR-6.8
      default:       return false;                          // M/T/Q — force-clear only
     }
  }

//+------------------------------------------------------------------+
//| ShouldForceClear — ADR-008 force-clear policy (M/T/Q only)       |
//| M=InpForceClearM_Bars (default 150), T=80, Q=100 H4 bars.        |
//+------------------------------------------------------------------+
bool CPendingMachineRegistry::ShouldForceClear(EPendingMachineId id,
                                               int current_bar) const
  {
   if(id != PM_M && id != PM_T && id != PM_Q) return false;
   if(m_machines[id].state != PENDING_STATE_PENDING) return false;

   int age = current_bar - m_machines[id].pending_started_bar;
   if(age < 0) return false;

   switch(id)
     {
      case PM_M: return age >= m_threshold_m_bars;
      case PM_T: return age >= m_threshold_t_bars;
      case PM_Q: return age >= m_threshold_q_bars;
      default:   return false;
     }
  }

//+------------------------------------------------------------------+
//| EmitForceClear — journal event + counter increment + Logger.Warn |
//| Schema: [ev=force_clear][machine=M/T/Q][reason=age_exceeded]     |
//+------------------------------------------------------------------+
void CPendingMachineRegistry::EmitForceClear(EPendingMachineId id, int age_bars)
  {
   if(id != PM_M && id != PM_T && id != PM_Q) return;

   // Counter increment — RAM cache + StatePersistence atomic op.
   m_machines[id].force_clear_count++;
   if(m_state != NULL)
      m_state.IncrementPmForceClearCount(id);

   string code = _IdToCode(id);

   // Journal event (ADR-008 + trade-journal-schema event_type=force_clear).
   if(m_journal != NULL)
     {
      JournalEvent ev;
      ZeroMemory(ev);
      ev.timestamp_seconds      = TimeCurrent();
      ev.timestamp_microseconds = GetMicrosecondCount();
      ev.event_type             = "force_clear";
      ev.slot_id                = code;
      ev.pending_age_bars       = age_bars;
      ev.signal_context         = StringFormat("machine=%s reason=age_exceeded count=%d",
                                               code, m_machines[id].force_clear_count);
      m_journal.WriteEvent(ev);
     }

   // Tagged Logger trail (ADR-011) — Warn severity (operator-visible but
   // non-halt; force-clear is a soft policy outcome, not an error).
   if(m_logger != NULL)
      m_logger.Warn("pending", "force_clear", 0,
                    StringFormat("machine=%s age=%d count=%d",
                                 code, age_bars, m_machines[id].force_clear_count));
  }

#endif // PHOENICISNEX_SERVICES_PENDINGMACHINEREGISTRY_MQH
