//+------------------------------------------------------------------+
//| CircuitBreaker.mqh — ping-pong detector (BR-3.6 + ADR-010)      |
//| Layer:   services/ — injected into Orchestrator via constructor  |
//| Source:  ADR-010 (halted-state-exit-only), BR-3.6 (ping-pong),  |
//|          TD-02 §5.8 (skeleton), ADR-011 (ErrorBypassThrottle)   |
//|                                                                  |
//| Key contracts:                                                   |
//|  • Ring buffer CloseEvent m_buffer[16] (TD-02 §5.8 skeleton)    |
//|  • RecordOpen / RecordClose write (magic, direction, time)       |
//|  • CheckPingPong returns true on first (magic,dir) pair where    |
//|    two events occur within 3000 s (BR-3.6 threshold)            |
//|  • Near-miss (3000, 5000] s → Logger.Warn (no halt)             |
//|  • Does NOT call EAState::Halt() — EAState lands at IMPL-052;   |
//|    emits Logger.ErrorBypassThrottle + returns true; Orchestrator |
//|    (IMPL-053) wires the actual EAState::SetHalted(reason) call.  |
//|    (per ADR-010 + shared-context §6 pre-loaded quotes)           |
//|                                                                  |
//| datetime precision note:                                         |
//|  MQL5 datetime is seconds-precision (Unix epoch, 32-bit on       |
//|  older builds; 64-bit from MT5 Build ≥ 2361). The "ms" suffix   |
//|  in the skeleton parameter name (now_ms) is shorthand inherited  |
//|  from the TD-02 §5.8 spec — actual storage is seconds floor.    |
//|  Sub-second resolution would require storing GetMicrosecondCount |
//|  in a separate ulong field per event. For H4 EA operation the    |
//|  seconds floor is pragmatic: open/close events on the same or    |
//|  adjacent tick are separated by 0-1 s; 3000 s = 50-minute window |
//|  which is well above inter-tick noise. Upgrade path: add         |
//|  ulong micros field to CloseEvent and replace datetime compare   |
//|  with micros compare when sub-second is required.                |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
#define PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH

#include "Logger.mqh"
#include "PortfolioState.mqh"

//+------------------------------------------------------------------+
//| CCircuitBreaker                                                  |
//|                                                                  |
//| Naming: m_* members, PascalCase public, _camelCase private       |
//| (per ea.md naming conventions + ADR-012)                         |
//+------------------------------------------------------------------+
class CCircuitBreaker
  {
private:
   //--- Ring buffer of recent (magic, direction, close_time) tuples
   //    (TD-02 §5.8 verbatim skeleton — 16 slots)
   struct CloseEvent
     {
      int      magic;          // slot magic number (200..219)
      int      direction;      // ORDER_TYPE_BUY=0 / ORDER_TYPE_SELL=1
      datetime close_time_ms;  // seconds-precision (see datetime note above)
     };

   CloseEvent        m_buffer[16];  // ring buffer (TD-02 §5.8)
   int               m_idx;         // next write position (0..15, wraps around)
   int               m_count;       // logical fill count (0..16); capped at 16

   CLogger          *m_logger;      // injected logger (Composition Root)

   //--- Threshold constants (BR-3.6)
   static const int  PING_PONG_THRESHOLD_S = 3000;    // ping-pong halt threshold (seconds)
   static const int  NEAR_MISS_THRESHOLD_S = 5000;    // near-miss warn threshold (seconds)

   //--- Private helpers
   bool              _IsRingFull()   const { return m_count >= 16; }
   int               _LogicalSize()  const { return m_count < 16 ? m_count : 16; }

   //--- Internal write — shared by RecordOpen + RecordClose
   void              _WriteEvent(int magic, int direction, datetime now_ms);

public:
   //--- Default constructor — zero-init ring buffer
   CCircuitBreaker() : m_idx(0), m_count(0), m_logger(NULL)
     {
      for(int i = 0; i < 16; i++)
        {
         m_buffer[i].magic         = 0;
         m_buffer[i].direction     = 0;
         m_buffer[i].close_time_ms = 0;
        }
     }

   //--- Init — inject logger pointer (Composition Root; called at Orchestrator step)
   void              Init(CLogger *logger);

   //--- Called per tick; triggers halt-signal if ping-pong detected.
   //    Returns true if Orchestrator MUST call EAState::SetHalted (IMPL-052).
   //    CPortfolioState& parameter reserved for future context enrichment
   //    (e.g. per-slot position count in log message); currently unused.
   bool              CheckPingPong(CPortfolioState &port, datetime now_ms);

   //--- Called by slot post-OrderSend ack to record open events (TD-02 §5.8)
   void              RecordOpen(int magic, int direction, datetime now_ms);

   //--- Called by slot post-OrderClose ack to record close events (TD-02 §5.8)
   void              RecordClose(int magic, int direction, datetime now_ms);

   //--- Inline SelfTest — exercises CheckPingPong with stubbed events.
   //    Precedent: JsonWriter::SelfTest, IndicatorService::SelfTest.
   //    Returns true if all assertions pass; false + Print on failure.
   bool              SelfTest();

  }; // end class CCircuitBreaker

//+------------------------------------------------------------------+
//| Init — inject logger                                             |
//+------------------------------------------------------------------+
void CCircuitBreaker::Init(CLogger *logger)
  {
   m_logger = logger;
   // Emit init probe — grep pattern: grep -E '\[CircuitBreaker\].*\[ev=cb_init_ok\]'
   if(m_logger != NULL)
      m_logger.Info("CircuitBreaker", "cb_init_ok", 0,
                    "CircuitBreaker initialised; buffer_size=16"
                    " ping_threshold=" + IntegerToString(PING_PONG_THRESHOLD_S) + "s"
                    " near_miss_threshold=" + IntegerToString(NEAR_MISS_THRESHOLD_S) + "s");
  }

//+------------------------------------------------------------------+
//| _WriteEvent — write one event into the ring buffer               |
//+------------------------------------------------------------------+
void CCircuitBreaker::_WriteEvent(int magic, int direction, datetime now_ms)
  {
   m_buffer[m_idx].magic         = magic;
   m_buffer[m_idx].direction     = direction;
   m_buffer[m_idx].close_time_ms = now_ms;
   m_idx = (m_idx + 1) % 16;   // wrap-around
   if(m_count < 16)
      m_count++;
  }

//+------------------------------------------------------------------+
//| RecordOpen — record an order-open event                          |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordOpen(int magic, int direction, datetime now_ms)
  {
   _WriteEvent(magic, direction, now_ms);
   if(m_logger != NULL)
      m_logger.Debug("CircuitBreaker", "record_open", magic,
                     "dir=" + IntegerToString(direction) +
                     " t=" + IntegerToString((int)now_ms));
  }

//+------------------------------------------------------------------+
//| RecordClose — record an order-close event                        |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordClose(int magic, int direction, datetime now_ms)
  {
   _WriteEvent(magic, direction, now_ms);
   if(m_logger != NULL)
      m_logger.Debug("CircuitBreaker", "record_close", magic,
                     "dir=" + IntegerToString(direction) +
                     " t=" + IntegerToString((int)now_ms));
  }

//+------------------------------------------------------------------+
//| CheckPingPong — scan ring buffer for ping-pong patterns          |
//|                                                                  |
//| Algorithm:                                                        |
//|   For each pair of events in the buffer sharing the same         |
//|   (magic, direction), compute |t2 - t1|.                         |
//|   If delta ≤ PING_PONG_THRESHOLD_S (3000 s = BR-3.6):           |
//|     → emit ErrorBypassThrottle + return true (Orchestrator halts)|
//|   Elif delta ≤ NEAR_MISS_THRESHOLD_S (5000 s):                   |
//|     → emit Warn (no halt; near-miss visibility)                  |
//|                                                                  |
//| NOTE: Does NOT call EAState::Halt() — EAState class lands at     |
//| IMPL-052. CircuitBreaker emits Logger.ErrorBypassThrottle and    |
//| returns true; Orchestrator (IMPL-053) wires SetHalted() call.    |
//| (per ADR-010 + shared-context §6 constraint)                     |
//+------------------------------------------------------------------+
bool CCircuitBreaker::CheckPingPong(CPortfolioState &port, datetime now_ms)
  {
   int sz = _LogicalSize();
   if(sz < 2)
      return false;  // not enough events to form a pair

   bool near_miss_found = false;

   // O(n^2) over ring buffer (max 16 elements = 120 pairs — negligible on tick)
   for(int i = 0; i < sz; i++)
     {
      for(int j = i + 1; j < sz; j++)
        {
         // Only compare same (magic, direction) pairs
         if(m_buffer[i].magic     != m_buffer[j].magic ||
            m_buffer[i].direction != m_buffer[j].direction)
            continue;

         // Compute time delta (absolute value; order in ring may not be chronological
         // after wrap-around, so use abs to be safe)
         long delta = (long)m_buffer[i].close_time_ms - (long)m_buffer[j].close_time_ms;
         if(delta < 0)
            delta = -delta;

         if(delta <= (long)PING_PONG_THRESHOLD_S)
           {
            // BR-3.6 ping-pong detected — emit unthrottled error + signal halt
            string detail = StringFormat(
                              "ping_pong detected: magic=%d dir=%d delta=%ds"
                              " (threshold=%ds); returning true — Orchestrator MUST"
                              " call EAState::SetHalted (IMPL-052 wires this)",
                              m_buffer[i].magic, m_buffer[i].direction,
                              (int)delta, PING_PONG_THRESHOLD_S);

            if(m_logger != NULL)
               m_logger.ErrorBypassThrottle("CircuitBreaker", "ping_pong",
                                            m_buffer[i].magic, detail);
            else
               Print("[CircuitBreaker][ERROR] " + detail);

            return true;  // Orchestrator wires EAState::SetHalted
           }
         else if(delta <= (long)NEAR_MISS_THRESHOLD_S)
           {
            // Near-miss — warn but do not halt
            near_miss_found = true;
            string warn_msg = StringFormat(
                                "near_miss: magic=%d dir=%d delta=%ds"
                                " (near_miss_threshold=%ds)",
                                m_buffer[i].magic, m_buffer[i].direction,
                                (int)delta, NEAR_MISS_THRESHOLD_S);
            if(m_logger != NULL)
               m_logger.Warn("CircuitBreaker", "ping_pong_near_miss",
                             m_buffer[i].magic, warn_msg);
            else
               Print("[CircuitBreaker][WARN] " + warn_msg);
            // Continue scanning — a tighter pair might still trigger halt
           }
        }
     }

   return false;  // no ping-pong halt condition
  }

//+------------------------------------------------------------------+
//| SelfTest — inline stub-driven verification                       |
//|                                                                  |
//| Test cases:                                                       |
//|  A) 3 close events 1500 s apart, same (magic=200, dir=0) →       |
//|     CheckPingPong must return true (delta=1500 ≤ 3000 threshold) |
//|  B) 2 close events 4000 s apart, same (magic=201, dir=1) →       |
//|     CheckPingPong must return false (near-miss warn only)         |
//|  C) 2 close events 6000 s apart, same (magic=202, dir=0) →       |
//|     CheckPingPong must return false (no trigger, no near-miss)    |
//|                                                                  |
//| Pseudo-trace:                                                     |
//|  Reset → RecordClose(200,0,T0) → RecordClose(200,0,T0+1500)      |
//|   → RecordClose(200,0,T0+3000) → CheckPingPong                   |
//|   Pair (0,1): delta=1500 ≤ 3000 → should return true            |
//|                                                                  |
//| Returns true = all assertions passed.                             |
//| Prerequisite: Init must be called before SelfTest.               |
//+------------------------------------------------------------------+
bool CCircuitBreaker::SelfTest()
  {
   bool all_pass = true;

   // --- Save and reset state so SelfTest is isolated
   CloseEvent saved_buffer[16];
   int        saved_idx   = m_idx;
   int        saved_count = m_count;
   for(int i = 0; i < 16; i++)
      saved_buffer[i] = m_buffer[i];

   // Helper lambda equivalent — inline reset
#define CB_SELFTEST_RESET() { m_idx=0; m_count=0; for(int _r=0;_r<16;_r++){m_buffer[_r].magic=0;m_buffer[_r].direction=0;m_buffer[_r].close_time_ms=0;} }

   // Stub CPortfolioState — CheckPingPong accepts ref but does not call any method on it yet
   // (current impl uses it only as a passthrough per TD-02 §5.8 + shared-context §4 task 3 note)
   CPortfolioState stub_port;

   //--------------------------------------------------------------------
   // Case A: 3 close events 1500 s apart, same (magic=200, dir=0) → true
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   datetime t0 = (datetime)1000000;   // arbitrary base epoch
   RecordClose(200, 0, t0);
   RecordClose(200, 0, t0 + 1500);
   RecordClose(200, 0, t0 + 3000);

   bool result_a = CheckPingPong(stub_port, t0 + 3001);
   if(!result_a)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case A:"
            " expected true (1500 s gap ≤ 3000 threshold), got false");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case A: ping-pong detected as expected");

   //--------------------------------------------------------------------
   // Case B: 2 close events 4000 s apart, same (magic=201, dir=1) → false
   //         (near-miss warn emitted; no halt)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(201, 1, t0);
   RecordClose(201, 1, t0 + 4000);

   bool result_b = CheckPingPong(stub_port, t0 + 4001);
   if(result_b)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case B:"
            " expected false (4000 s gap in near-miss zone), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case B: near-miss no-halt as expected");

   //--------------------------------------------------------------------
   // Case C: 2 close events 6000 s apart, same (magic=202, dir=0) → false
   //         (no trigger; no near-miss)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(202, 0, t0);
   RecordClose(202, 0, t0 + 6000);

   bool result_c = CheckPingPong(stub_port, t0 + 6001);
   if(result_c)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case C:"
            " expected false (6000 s gap > both thresholds), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case C: no-trigger as expected");

   //--------------------------------------------------------------------
   // Case D: different magic same time → no ping-pong → false
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(200, 0, t0);
   RecordClose(201, 0, t0 + 100);   // different magic, close in time — must NOT trigger

   bool result_d = CheckPingPong(stub_port, t0 + 101);
   if(result_d)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case D:"
            " expected false (different magic), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case D: different-magic no-trigger as expected");

   // Cleanup macro
#undef CB_SELFTEST_RESET

   // --- Restore original state
   m_idx   = saved_idx;
   m_count = saved_count;
   for(int i = 0; i < 16; i++)
      m_buffer[i] = saved_buffer[i];

   if(all_pass)
      Print("[CircuitBreaker][SelfTest] All cases PASSED");
   else
      Print("[CircuitBreaker][SelfTest] One or more cases FAILED — see above");

   return all_pass;
  }

#endif // PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
