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
//|    two events occur within 3 s (BR-3.6 = 3000 ms = 3 s)         |
//|  • Near-miss (3 s, 5 s] → Logger.Warn (no halt)                 |
//|  • Does NOT call EAState::Halt() — EAState lands at IMPL-052;   |
//|    emits Logger.ErrorBypassThrottle + returns true; Orchestrator |
//|    (IMPL-053) wires the actual EAState::SetHalted(reason) call.  |
//|    (per ADR-010 + shared-context §6 pre-loaded quotes)           |
//|                                                                  |
//| datetime precision note (Finding 02.2 + 02.9 — 2026-05-03):     |
//|  MQL5 datetime is seconds-precision (Unix epoch, 32-bit on       |
//|  older builds; 64-bit from MT5 Build ≥ 2361). BR-3.6 spec quotes |
//|  3000 ms = 3 s; we store seconds floor and threshold at 3 s so   |
//|  the spec letter is honored under datetime granularity. Pairs    |
//|  with delta ∈ {0, 1, 2, 3} s halt; (3, 5] s warn (near-miss);   |
//|  > 5 s ignored. Sub-second precision is not required at H4 EA    |
//|  cadence (inter-tick noise ≈ 1 s). Upgrade path (IMPL-053+ if    |
//|  needed): add `ulong close_time_us` field via GetMicrosecondCount|
//|  + bump constants to micros (3 000 000 / 5 000 000).             |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
#define PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH

#include "Logger.mqh"
//--- PortfolioState include dropped (Finding 02.7) — CheckPingPong no longer takes
//    CPortfolioState& parameter. Re-add if future enrichment needs slot context.

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
      datetime close_time_s;   // seconds-precision (see datetime note above; Finding 02.9 rename)
     };

   CloseEvent        m_buffer[16];  // ring buffer (TD-02 §5.8)
   int               m_idx;         // next write position (0..15, wraps around)
   int               m_count;       // logical fill count (0..16); capped at 16

   CLogger          *m_logger;      // injected logger (Composition Root)

   //--- Threshold constants (BR-3.6: 3000 ms = 3 s; near-miss = 5 s — Finding 02.2)
   static const int  PING_PONG_THRESHOLD_S;   // ping-pong halt threshold (seconds; BR-3.6 = 3000 ms) — IMPL-059 ODR fix; value at out-of-class def
   static const int  NEAR_MISS_THRESHOLD_S;   // near-miss warn threshold (seconds) — IMPL-059 ODR fix

   //--- Private helpers
   bool              _IsRingFull()   const { return m_count >= 16; }
   int               _LogicalSize()  const { return m_count < 16 ? m_count : 16; }

   //--- Internal write — shared by RecordOpen + RecordClose
   void              _WriteEvent(int magic, int direction, datetime now_s);

public:
   //--- Default constructor — zero-init ring buffer
   CCircuitBreaker() : m_idx(0), m_count(0), m_logger(NULL)
     {
      for(int i = 0; i < 16; i++)
        {
         m_buffer[i].magic        = 0;
         m_buffer[i].direction    = 0;
         m_buffer[i].close_time_s = 0;
        }
     }

   //--- Init — inject logger pointer (Composition Root; called at Orchestrator step)
   void              Init(CLogger *logger);

   //--- Called per tick; triggers halt-signal if ping-pong detected.
   //    Returns true if Orchestrator MUST call EAState::SetHalted (IMPL-052).
   //    Operates on internal m_buffer state only — TD-02 §5.8 originally
   //    declared (CPortfolioState&, datetime) but neither was read in body
   //    (Finding 02.7); dropped per Code Review Dim #5 over-engineering rule.
   //    Caller (Orchestrator IMPL-053): `if(m_breaker.CheckPingPong()) ...`
   bool              CheckPingPong();

   //--- Called by slot post-OrderSend ack to record open events (TD-02 §5.8)
   void              RecordOpen(int magic, int direction, datetime now_s);

   //--- Called by slot post-OrderClose ack to record close events (TD-02 §5.8)
   void              RecordClose(int magic, int direction, datetime now_s);

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
void CCircuitBreaker::_WriteEvent(int magic, int direction, datetime now_s)
  {
   m_buffer[m_idx].magic        = magic;
   m_buffer[m_idx].direction    = direction;
   m_buffer[m_idx].close_time_s = now_s;
   m_idx = (m_idx + 1) % 16;   // wrap-around
   if(m_count < 16)
      m_count++;
  }

//+------------------------------------------------------------------+
//| RecordOpen — record an order-open event                          |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordOpen(int magic, int direction, datetime now_s)
  {
   _WriteEvent(magic, direction, now_s);
   if(m_logger != NULL)
      m_logger.Debug("CircuitBreaker", "record_open", magic,
                     "dir=" + IntegerToString(direction) +
                     " t=" + IntegerToString((int)now_s));
  }

//+------------------------------------------------------------------+
//| RecordClose — record an order-close event                        |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordClose(int magic, int direction, datetime now_s)
  {
   _WriteEvent(magic, direction, now_s);
   if(m_logger != NULL)
      m_logger.Debug("CircuitBreaker", "record_close", magic,
                     "dir=" + IntegerToString(direction) +
                     " t=" + IntegerToString((int)now_s));
  }

//+------------------------------------------------------------------+
//| CheckPingPong — scan ring buffer for ping-pong patterns          |
//|                                                                  |
//| Algorithm:                                                        |
//|   For each pair of events in the buffer sharing the same         |
//|   (magic, direction), compute |t2 - t1|.                         |
//|   If delta ≤ PING_PONG_THRESHOLD_S (3 s = BR-3.6 3000 ms):      |
//|     → emit ErrorBypassThrottle + return true (Orchestrator halts)|
//|   Elif delta ≤ NEAR_MISS_THRESHOLD_S (5 s):                      |
//|     → emit Warn (no halt; near-miss visibility)                  |
//|                                                                  |
//| NOTE: Does NOT call EAState::Halt() — EAState class lands at     |
//| IMPL-052. CircuitBreaker emits Logger.ErrorBypassThrottle and    |
//| returns true; Orchestrator (IMPL-053) wires SetHalted() call.    |
//| (per ADR-010 + shared-context §6 constraint)                     |
//+------------------------------------------------------------------+
bool CCircuitBreaker::CheckPingPong()
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
         long delta = (long)m_buffer[i].close_time_s - (long)m_buffer[j].close_time_s;
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
//| Test cases (BR-3.6 threshold = 3 s; near-miss = 5 s):            |
//|  A) 3 close events 1 s apart, same (magic=200, dir=0) →          |
//|     CheckPingPong must return true (delta=1 ≤ 3 threshold)       |
//|  B) 2 close events 4 s apart, same (magic=201, dir=1) →          |
//|     CheckPingPong must return false (near-miss zone 3<delta≤5)   |
//|  C) 2 close events 6 s apart, same (magic=202, dir=0) →          |
//|     CheckPingPong must return false (no trigger, no near-miss)   |
//|  D) 2 events different magics — no ping-pong (no pair match)     |
//|                                                                  |
//| Pseudo-trace (Case A):                                            |
//|  Reset → RecordClose(200,0,T0) → RecordClose(200,0,T0+1)         |
//|   → RecordClose(200,0,T0+2) → CheckPingPong                      |
//|   Pair (0,1): delta=1 ≤ 3 → should return true                  |
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
#define CB_SELFTEST_RESET() { m_idx=0; m_count=0; for(int _r=0;_r<16;_r++){m_buffer[_r].magic=0;m_buffer[_r].direction=0;m_buffer[_r].close_time_s=0;} }

   //--------------------------------------------------------------------
   // Case A: 3 close events 1 s apart, same (magic=200, dir=0) → true
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   datetime t0 = (datetime)1000000;   // arbitrary base epoch
   RecordClose(200, 0, t0);
   RecordClose(200, 0, t0 + 1);
   RecordClose(200, 0, t0 + 2);

   bool result_a = CheckPingPong();
   if(!result_a)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case A:"
            " expected true (1 s gap ≤ 3 s threshold), got false");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case A: ping-pong detected as expected");

   //--------------------------------------------------------------------
   // Case B: 2 close events 4 s apart, same (magic=201, dir=1) → false
   //         (near-miss warn emitted; no halt)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(201, 1, t0);
   RecordClose(201, 1, t0 + 4);

   bool result_b = CheckPingPong();
   if(result_b)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case B:"
            " expected false (4 s gap in near-miss zone 3<d≤5), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case B: near-miss no-halt as expected");

   //--------------------------------------------------------------------
   // Case C: 2 close events 6 s apart, same (magic=202, dir=0) → false
   //         (no trigger; no near-miss)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(202, 0, t0);
   RecordClose(202, 0, t0 + 6);

   bool result_c = CheckPingPong();
   if(result_c)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case C:"
            " expected false (6 s gap > both thresholds), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case C: no-trigger as expected");

   //--------------------------------------------------------------------
   // Case D: different magic same time → no ping-pong → false
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(200, 0, t0);
   RecordClose(201, 0, t0 + 1);   // different magic, close in time — must NOT trigger

   bool result_d = CheckPingPong();
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

//+------------------------------------------------------------------+
//| Static-member out-of-class definitions (IMPL-059 ODR fix)        |
//+------------------------------------------------------------------+
const int CCircuitBreaker::PING_PONG_THRESHOLD_S = 3;
const int CCircuitBreaker::NEAR_MISS_THRESHOLD_S = 5;

#endif // PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
