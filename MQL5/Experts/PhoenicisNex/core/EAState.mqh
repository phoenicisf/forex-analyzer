//+------------------------------------------------------------------+
//| core/EAState.mqh — central HALTED state machine (ADR-010)        |
//| Layer:   core/                                                   |
//| Source:  TD-02 §7.0.3, ADR-010, FR-7.7, NFR-5.1                  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_CORE_EASTATE_MQH
#define PHOENICISNEX_CORE_EASTATE_MQH

#include "../domain/EnumTypes.mqh"
#include "../domain/IHaltSink.mqh"
#include "../services/TradeJournal.mqh"
#include "../services/Logger.mqh"

//+------------------------------------------------------------------+
//| class CEAState                                                   |
//| Responsibility: Encapsulate EEAState transitions                 |
//| (RUNNING -> HALTED -> HALTED_STABLE) + Halt() side-effects       |
//+------------------------------------------------------------------+
class CEAState : public IHaltSink
  {
private:
   EEAState        m_state;
   string          m_halt_reason;
   CTradeJournal  *m_journal;
   CLogger        *m_logger;

public:
                     CEAState() : m_state(EA_STATE_RUNNING), m_halt_reason(""), m_journal(NULL), m_logger(NULL) {}

   void              Init(CTradeJournal *tj, CLogger *lg)
     {
      m_state = EA_STATE_RUNNING;
      m_halt_reason = "";
      m_journal = tj;
      m_logger = lg;
     }

   EEAState          GetState() const { return m_state; }
   string            GetHaltReason() const { return m_halt_reason; }

   //+------------------------------------------------------------------+
   //| Halt(reason)                                                     |
   //| Entry point for all halt triggers. Emits journal event + Alert.  |
   //| Idempotent. (ADR-010 + ADR-011 § Halt-trigger bypass)            |
   //+------------------------------------------------------------------+
   void              Halt(string reason)
     {
      if(m_state == EA_STATE_HALTED || m_state == EA_STATE_HALTED_STABLE)
         return;

      m_state = EA_STATE_HALTED;
      m_halt_reason = reason;

      if(m_journal != NULL)
        {
         JournalEvent ev;
         BuildHaltEvent(ev, "halt", reason, "CEAState::Halt", StringFormat("halt_reason=%s", reason));
         m_journal.WriteEvent(ev);
        }

      if(m_logger != NULL)
        {
         // No throttle per ADR-011 line 60
         m_logger.ErrorBypassThrottle("system", "halt", 0, reason);
        }
     }

   //+------------------------------------------------------------------+
   //| BuildHaltEvent — populate JournalEvent for halt/halt_stable      |
   //| Extracted (Finding 03.8) so SelfTest can verify schema-required  |
   //| fields are populated without needing a mock CTradeJournal.       |
   //+------------------------------------------------------------------+
   void              BuildHaltEvent(JournalEvent &ev,
                                    string event_type,
                                    string reason,
                                    string triggering_function,
                                    string signal_context) const
     {
      ZeroMemory(ev);
      ev.timestamp_seconds      = TimeCurrent();
      ev.timestamp_microseconds = GetMicrosecondCount();
      ev.event_type             = event_type;
      ev.slot_id                = "system";          // schema § slot_id description
      ev.magic                  = 0;                  // schema: "0 for system events"
      ev.symbol                 = _Symbol;            // schema enum [EURUSD] per C-3 / FR-1.2
      ev.halt_reason            = reason;
      ev.signal_context         = signal_context;
      ev.triggering_function    = triggering_function;
     }

   //+------------------------------------------------------------------+
   //| TryTransitionToStable                                            |
   //| Promote HALTED -> HALTED_STABLE if portfolio is empty.           |
   //+------------------------------------------------------------------+
   bool              TryTransitionToStable(int active_position_count)
     {
      if(m_state == EA_STATE_HALTED && active_position_count == 0)
        {
         m_state = EA_STATE_HALTED_STABLE;

         if(m_journal != NULL)
           {
            JournalEvent ev;
            BuildHaltEvent(ev, "halt_stable", m_halt_reason,
                           "CEAState::TryTransitionToStable",
                           "all_positions_closed");
            m_journal.WriteEvent(ev);
           }

         if(m_logger != NULL)
           {
            m_logger.ErrorBypassThrottle("system", "halt_stable", 0, "PhoenicisNex halted, all positions closed");
           }
         return true;
        }
      return false;
     }

   //+------------------------------------------------------------------+
   //| RestoreFromState                                                 |
   //| Restore state from state.json + apply ADR-010 idle-reset.        |
   //+------------------------------------------------------------------+
   void              RestoreFromState(EEAState loaded, string loaded_reason, int active_position_count)
     {
      if(loaded == EA_STATE_HALTED || loaded == EA_STATE_HALTED_STABLE)
        {
         if(active_position_count == 0)
           {
            // Reset to RUNNING
            m_state = EA_STATE_RUNNING;
            m_halt_reason = "";
            if(m_logger != NULL)
              {
               m_logger.Info("system", "reset", 0, "Halt reset to RUNNING due to empty portfolio on restart");
              }
           }
         else
           {
            m_state = loaded;
            m_halt_reason = loaded_reason;
            // Fallback: If it says HALTED_STABLE but we have active positions, demote to HALTED
            if(m_state == EA_STATE_HALTED_STABLE && active_position_count > 0)
              {
               m_state = EA_STATE_HALTED;
              }
           }
        }
      else
        {
         m_state = EA_STATE_RUNNING;
         m_halt_reason = "";
        }
     }

   //+------------------------------------------------------------------+
   //| SelfTest (unit test proxy)                                       |
   //+------------------------------------------------------------------+
   bool              SelfTest(CLogger *logger)
     {
      logger.Info("system", "SelfTest_EAState", 0, "Starting CEAState self test");

      // We cannot easily inject a mock journal without interface, so we just test state transitions.
      CEAState ea;
      ea.Init(NULL, NULL);

      if(ea.GetState() != EA_STATE_RUNNING)
        {
         logger.Error("system", "SelfTest_EAState", 0, "Initial state != RUNNING");
         return false;
        }

      ea.Halt("test_reason");
      if(ea.GetState() != EA_STATE_HALTED || ea.GetHaltReason() != "test_reason")
        {
         logger.Error("system", "SelfTest_EAState", 0, "Halt transition failed");
         return false;
        }

      // Try to transition with active positions -> should fail
      if(ea.TryTransitionToStable(1))
        {
         logger.Error("system", "SelfTest_EAState", 0, "Transition to stable succeeded with active > 0");
         return false;
        }

      // Try to transition with 0 positions -> should succeed
      if(!ea.TryTransitionToStable(0))
        {
         logger.Error("system", "SelfTest_EAState", 0, "Transition to stable failed with active == 0");
         return false;
        }

      if(ea.GetState() != EA_STATE_HALTED_STABLE)
        {
         logger.Error("system", "SelfTest_EAState", 0, "State != HALTED_STABLE after transition");
         return false;
        }

      // Test idempotent
      ea.Halt("another_reason");
      if(ea.GetState() != EA_STATE_HALTED_STABLE || ea.GetHaltReason() != "test_reason")
        {
         logger.Error("system", "SelfTest_EAState", 0, "Idempotency failed");
         return false;
        }

      // Test RestoreFromState: reset to RUNNING
      CEAState ea2;
      ea2.Init(NULL, NULL);
      ea2.RestoreFromState(EA_STATE_HALTED, "old_reason", 0);
      if(ea2.GetState() != EA_STATE_RUNNING)
        {
         logger.Error("system", "SelfTest_EAState", 0, "RestoreFromState reset failed");
         return false;
        }

      // Test RestoreFromState: keep HALTED
      CEAState ea3;
      ea3.Init(NULL, NULL);
      ea3.RestoreFromState(EA_STATE_HALTED, "old_reason", 2);
      if(ea3.GetState() != EA_STATE_HALTED || ea3.GetHaltReason() != "old_reason")
        {
         logger.Error("system", "SelfTest_EAState", 0, "RestoreFromState keep HALTED failed");
         return false;
        }

      // Test RestoreFromState: HALTED_STABLE -> demote to HALTED
      CEAState ea4;
      ea4.Init(NULL, NULL);
      ea4.RestoreFromState(EA_STATE_HALTED_STABLE, "old_reason", 1);
      if(ea4.GetState() != EA_STATE_HALTED)
        {
         logger.Error("system", "SelfTest_EAState", 0, "RestoreFromState demote to HALTED failed");
         return false;
        }

      // Halt-event payload integrity (Finding 03.8 → 03.2 verification):
      // exercise BuildHaltEvent directly so we can assert each schema-required
      // field is populated without needing a mock CTradeJournal.
      JournalEvent he;
      ea2.BuildHaltEvent(he, "halt", "test_reason", "CEAState::Halt", "halt_reason=test_reason");
      if(he.event_type != "halt" ||
         he.slot_id != "system" ||
         he.symbol != _Symbol ||
         he.halt_reason != "test_reason" ||
         StringLen(he.triggering_function) == 0 ||
         StringLen(he.signal_context) == 0)
        {
         logger.Error("system", "SelfTest_EAState", 0,
                      "BuildHaltEvent missed required schema fields (Finding 03.2)");
         return false;
        }

      JournalEvent hse;
      ea2.BuildHaltEvent(hse, "halt_stable", "old", "CEAState::TryTransitionToStable", "all_positions_closed");
      if(hse.event_type != "halt_stable" ||
         hse.slot_id != "system" ||
         hse.symbol != _Symbol)
        {
         logger.Error("system", "SelfTest_EAState", 0,
                      "BuildHaltEvent halt_stable variant missed required fields");
         return false;
        }

      logger.Info("system", "SelfTest_EAState", 0, "CEAState self test PASS");
      return true;
     }
  };

#endif // PHOENICISNEX_CORE_EASTATE_MQH