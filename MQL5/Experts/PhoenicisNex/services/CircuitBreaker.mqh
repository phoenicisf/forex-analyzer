//+------------------------------------------------------------------+
//| CircuitBreaker.mqh -- ping-pong detector (BR-3.6 + ADR-010)      |
//| Layer:   services/ -- injected into Orchestrator via constructor |
//| Source:  ADR-010 (halted-state-exit-only), BR-3.6 (ping-pong),   |
//|          TD-02 §5.8 (skeleton), ADR-011 (ErrorBypassThrottle)    |
//|                                                                  |
//| Key contracts:                                                   |
//|  * Ring buffer TradeEvent m_buffer[16] (TD-02 §5.8 schema + ADR-014 fields)
//|  * RecordOpen / RecordClose write (magic, direction, time, position_id, event_type)
//|  * CheckPingPong fires halt-signal on pairs that satisfy ALL:    |
//|     (a) same (magic, direction)                                  |
//|     (b) DIFFERENT event_type (one EVT_OPEN + one EVT_CLOSE)      |
//|     (c) DIFFERENT position_id (different MT5 position)           |
//|     (d) |delta| <= PING_PONG_THRESHOLD_S (3 s; BR-3.6)            |
//|                                                                  |
//| ADR-014 (IMPL-FIX-012 iter-3, 2026-05-17) — added rules (b)+(c)  |
//| after iter-2 Run #4 falsified ADR-013's reason-only filter.      |
//| Rationale:                                                       |
//|   * Pair (close A, close A) impossible (same position can't be   |
//|     closed twice) — but pair (close A, close B) by mass-close    |
//|     helpers (SafePort/OrderGroupStartWorkflow/ForceCutloss)      |
//|     produced false-positive halts at sim 2021-01-27. Rule (b)    |
//|     skips same-event_type pairs => mass-close no longer fires.   |
//|   * Pair (open A, close A) on the SAME position is a normal      |
//|     short-lived trade (intraday scalp), not ping-pong. Rule (c)  |
//|     skips same-position pairs => legitimate quick exits don't    |
//|     fire halt.                                                   |
//|   * TRUE ping-pong = (close A, open B) within 3 s on same        |
//|     (magic, dir) but DIFFERENT positions => satisfies (a)+(b)+(c)|
//|     => fires halt. This is the canonical "rapid close+reopen"    |
//|     malfunction signal per BR-3.6 spec.                          |
//|                                                                  |
//| Producer-side filters (Orchestrator.mqh::OnTradeTransaction):    |
//|  * Symbol filter (NFR-5.3) — own-symbol only                     |
//|  * Magic-range filter — Phoenicis [200..219] only                |
//|  * DEAL_REASON_EXPERT filter (ADR-013) — broker-driven closes    |
//|    (SL/TP/SO/rollover) never feed RecordClose                    |
//|  * Both DEAL_ENTRY_IN (-> RecordOpen) and DEAL_ENTRY_OUT         |
//|    (-> RecordClose) wired post-ADR-014. Pre-ADR-014 only OUT was |
//|    wired -> ring contained only closes -> detector unable to     |
//|    distinguish mass-close from ping-pong. See ADR-014 § Decision.|
//|                                                                  |
//| datetime precision note (Finding 02.2 + 02.9 -- 2026-05-03):     |
//|  MQL5 datetime is seconds-precision (Unix epoch, 64-bit from     |
//|  MT5 Build >= 2361). BR-3.6 spec quotes 3000 ms = 3 s; we store  |
//|  seconds floor and threshold at 3 s so the spec letter is        |
//|  honored under datetime granularity. Pairs with delta in         |
//|  {0, 1, 2, 3} s halt; (3, 5] s warn (near-miss); > 5 s ignored.  |
//|  Sub-second precision is not required at H4 EA cadence           |
//|  (inter-tick noise <= 1 s).                                      |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
#define PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH

#include "Logger.mqh"
//--- PortfolioState include dropped (Finding 02.7) -- CheckPingPong no longer takes
//    CPortfolioState& parameter. Re-add if future enrichment needs slot context.

//+------------------------------------------------------------------+
//| CCircuitBreaker                                                  |
//|                                                                  |
//| Naming: m_* members, PascalCase public, _camelCase private       |
//| (per ea.md naming conventions + ADR-012)                         |
//+------------------------------------------------------------------+
class CCircuitBreaker
  {
public:
   //--- Event-type constants (ADR-014, IMPL-FIX-012 iter-3 2026-05-17)
   //    Public so SelfTest + future debug surfaces reference them by name.
   static const int  EVT_OPEN;     // open event (RecordOpen)
   static const int  EVT_CLOSE;    // close event (RecordClose)

private:
   //--- Ring buffer of recent trade events
   //    (TD-02 §5.8 skeleton; extended in ADR-014 with position_id +
   //    event_type fields after IMPL-FIX-012 iter-2 Run #4 falsified
   //    ADR-013's reason-only filter — mass-close helpers (SafePort/
   //    OrderGroupStartWorkflow) close multiple positions in same tick,
   //    all carrying DEAL_REASON_EXPERT, so ADR-013 filter passes them
   //    but they're closing DIFFERENT positions => not ping-pong.)
   struct TradeEvent
     {
      int      magic;          // slot magic number (200..219)
      int      direction;      // position direction: 1=was-BUY / 0=was-SELL
      datetime time_s;         // seconds-precision (see datetime note in header)
      ulong    position_id;    // ADR-014 — MT5 position id (DEAL_POSITION_ID)
      int      event_type;     // ADR-014 — EVT_OPEN (0) / EVT_CLOSE (1)
     };

   TradeEvent        m_buffer[16];  // ring buffer (TD-02 §5.8 + ADR-014 schema bump)
   int               m_idx;         // next write position (0..15, wraps around)
   int               m_count;       // logical fill count (0..16); capped at 16

   CLogger          *m_logger;      // injected logger (Composition Root)

   //--- Threshold constants (BR-3.6: 3000 ms = 3 s; near-miss = 5 s)
   static const int  PING_PONG_THRESHOLD_S;   // ping-pong halt threshold (seconds)
   static const int  NEAR_MISS_THRESHOLD_S;   // near-miss warn threshold (seconds)

   //--- Private helpers
   bool              _IsRingFull()   const { return m_count >= 16; }
   int               _LogicalSize()  const { return m_count < 16 ? m_count : 16; }

   //--- Internal write -- shared by RecordOpen + RecordClose (ADR-014 extended signature)
   void              _WriteEvent(int magic, int direction, datetime now_s,
                                 ulong position_id, int event_type);

public:
   //--- Default constructor -- zero-init ring buffer
   CCircuitBreaker() : m_idx(0), m_count(0), m_logger(NULL)
     {
      for(int i = 0; i < 16; i++)
        {
         m_buffer[i].magic       = 0;
         m_buffer[i].direction   = 0;
         m_buffer[i].time_s      = 0;
         m_buffer[i].position_id = 0;
         m_buffer[i].event_type  = EVT_CLOSE;
        }
     }

   //--- Init -- inject logger pointer (Composition Root; called at Orchestrator step)
   void              Init(CLogger *logger);

   //--- Called per tick; triggers halt-signal if ping-pong detected.
   //    Returns true if Orchestrator MUST call EAState::SetHalted (IMPL-052).
   //    Operates on internal m_buffer state only.
   //    Caller (Orchestrator IMPL-053): `if(m_breaker.CheckPingPong()) ...`
   bool              CheckPingPong();

   //--- Called by Orchestrator.OnTradeTransaction on DEAL_ENTRY_IN deals
   //    (ADR-014 — was unwired pre-iter-3; now wired so the ring sees
   //    both opens and closes and CheckPingPong can require pairs with
   //    DIFFERENT event_type to fire halt).
   void              RecordOpen(int magic, int direction, datetime now_s,
                                ulong position_id);

   //--- Called by Orchestrator.OnTradeTransaction on DEAL_ENTRY_OUT deals
   //    (ADR-013 — only DEAL_REASON_EXPERT closes feed this; ADR-014 — now
   //    carries position_id so CheckPingPong can require pairs with
   //    DIFFERENT positions to fire halt).
   void              RecordClose(int magic, int direction, datetime now_s,
                                 ulong position_id);

   //--- Inline SelfTest -- exercises CheckPingPong with stubbed events.
   //    Precedent: JsonWriter::SelfTest, IndicatorService::SelfTest.
   //    Returns true if all assertions pass; false + Print on failure.
   bool              SelfTest();

  }; // end class CCircuitBreaker

//+------------------------------------------------------------------+
//| Init -- inject logger                                            |
//+------------------------------------------------------------------+
void CCircuitBreaker::Init(CLogger *logger)
  {
   m_logger = logger;
   // Emit init probe -- grep pattern: grep -E '\[CircuitBreaker\].*\[ev=cb_init_ok\]'
   if(m_logger != NULL)
      m_logger.Info("CircuitBreaker", "cb_init_ok", 0,
                    "CircuitBreaker initialised; buffer_size=16"
                    " ping_threshold=" + IntegerToString(PING_PONG_THRESHOLD_S) + "s"
                    " near_miss_threshold=" + IntegerToString(NEAR_MISS_THRESHOLD_S) + "s"
                    " schema=ADR-014");
  }

//+------------------------------------------------------------------+
//| _WriteEvent -- write one event into the ring buffer              |
//+------------------------------------------------------------------+
void CCircuitBreaker::_WriteEvent(int magic, int direction, datetime now_s,
                                  ulong position_id, int event_type)
  {
   m_buffer[m_idx].magic       = magic;
   m_buffer[m_idx].direction   = direction;
   m_buffer[m_idx].time_s      = now_s;
   m_buffer[m_idx].position_id = position_id;
   m_buffer[m_idx].event_type  = event_type;
   m_idx = (m_idx + 1) % 16;   // wrap-around
   if(m_count < 16)
      m_count++;
  }

//+------------------------------------------------------------------+
//| RecordOpen -- record an order-open event                         |
//|                                                                  |
//| ADR-014 (iter-3, 2026-05-17) — now actually wired at             |
//| Orchestrator.OnTradeTransaction for DEAL_ENTRY_IN events. Pre-   |
//| iter-3 this method existed but no caller invoked it; the ring    |
//| contained only close events and CheckPingPong fired on close+close
//| pairs which is mass-close, not ping-pong. With RecordOpen wired, |
//| true ping-pong (open+close alternation) can fire halt while      |
//| mass-close (close+close) is correctly skipped.                   |
//|                                                                  |
//| fix-round-12 §12.6 -- defense-in-depth pre-Init guard preserved. |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordOpen(int magic, int direction, datetime now_s,
                                 ulong position_id)
  {
   if(m_logger == NULL)
     {
      Print("[CircuitBreaker][WARN] RecordOpen pre-Init dropped: magic=", magic,
            " dir=", direction, " t=", (int)now_s, " pos=", position_id);
      return;
     }
   _WriteEvent(magic, direction, now_s, position_id, EVT_OPEN);
   m_logger.Debug("CircuitBreaker", "record_open", magic,
                  "dir=" + IntegerToString(direction) +
                  " t=" + IntegerToString((int)now_s) +
                  " pos=" + IntegerToString((long)position_id));
  }

//+------------------------------------------------------------------+
//| RecordClose -- record an order-close event                       |
//|                                                                  |
//| ADR-013 filter (producer side, Orchestrator.OnTradeTransaction): |
//|   only DEAL_REASON_EXPERT deals feed this; broker-driven closes  |
//|   (SL/TP/SO/rollover) are skipped before reaching RecordClose.   |
//| ADR-014 extension: position_id now passed in so CheckPingPong    |
//|   can dedup pairs with same position (legitimate intraday scalp) |
//|   and pairs with same event_type (mass-close false positive).    |
//|                                                                  |
//| fix-round-12 §12.6 -- defense-in-depth pre-Init guard preserved. |
//+------------------------------------------------------------------+
void CCircuitBreaker::RecordClose(int magic, int direction, datetime now_s,
                                  ulong position_id)
  {
   if(m_logger == NULL)
     {
      Print("[CircuitBreaker][WARN] RecordClose pre-Init dropped: magic=", magic,
            " dir=", direction, " t=", (int)now_s, " pos=", position_id);
      return;
     }
   _WriteEvent(magic, direction, now_s, position_id, EVT_CLOSE);
   m_logger.Debug("CircuitBreaker", "record_close", magic,
                  "dir=" + IntegerToString(direction) +
                  " t=" + IntegerToString((int)now_s) +
                  " pos=" + IntegerToString((long)position_id));
  }

//+------------------------------------------------------------------+
//| CheckPingPong -- scan ring buffer for ping-pong patterns         |
//|                                                                  |
//| Algorithm (ADR-014 — extended from TD-02 §5.8):                  |
//|   For each pair (i, j) in the buffer:                            |
//|   (a) require same (magic, direction)                            |
//|   (b) require DIFFERENT event_type (one EVT_OPEN, one EVT_CLOSE) |
//|   (c) require DIFFERENT position_id (different MT5 position)     |
//|   (d) compute |t2 - t1|                                          |
//|   If delta <= PING_PONG_THRESHOLD_S (3 s = BR-3.6 3000 ms):      |
//|     -> emit ErrorBypassThrottle + return true (Orchestrator halt)|
//|   Elif delta <= NEAR_MISS_THRESHOLD_S (5 s):                     |
//|     -> emit Warn (no halt; near-miss visibility)                 |
//|                                                                  |
//| Rule (b) ensures mass-close (close+close) never fires halt;      |
//| rule (c) ensures legitimate intraday scalp (open A + close A     |
//| on the SAME position) never fires halt. Only true rapid          |
//| close+reopen (close A + open B on same magic+dir but DIFFERENT   |
//| positions) fires halt — that's the canonical ping-pong signal.   |
//+------------------------------------------------------------------+
bool CCircuitBreaker::CheckPingPong()
  {
   int sz = _LogicalSize();
   if(sz < 2)
      return false;  // not enough events to form a pair

   bool near_miss_found = false;

   // O(n^2) over ring buffer (max 16 elements = 120 pairs -- negligible on tick)
   for(int i = 0; i < sz; i++)
     {
      for(int j = i + 1; j < sz; j++)
        {
         // Rule (a): only compare same (magic, direction) pairs
         if(m_buffer[i].magic     != m_buffer[j].magic ||
            m_buffer[i].direction != m_buffer[j].direction)
            continue;

         // Rule (b): skip same-event_type pairs (both opens or both closes).
         //   Same-event_type pairs are NEVER ping-pong:
         //     * close+close = mass-close helper (SafePort/OrderGroupStart/etc.)
         //     * open+open   = pyramid/scaling legitimate
         //   See ADR-014 § Decision and IMPL-FIX-012 iter-2 Run #4 evidence.
         if(m_buffer[i].event_type == m_buffer[j].event_type)
            continue;

         // Rule (c): skip same-position pairs (open A + close A = normal
         //   open/close of the same position; not ping-pong even at delta=0s).
         //   ADR-014 (iter-3): protects against intraday scalp false positives
         //   when RecordOpen+RecordClose fire for the same position in
         //   adjacent ticks.
         if(m_buffer[i].position_id == m_buffer[j].position_id)
            continue;

         // Compute time delta (absolute value; order in ring may not be
         // chronological after wrap-around)
         long delta = (long)m_buffer[i].time_s - (long)m_buffer[j].time_s;
         if(delta < 0)
            delta = -delta;

         if(delta <= (long)PING_PONG_THRESHOLD_S)
           {
            // BR-3.6 ping-pong detected -- emit unthrottled error + signal halt
            string detail = StringFormat(
                              "ping_pong detected: magic=%d dir=%d delta=%ds"
                              " (threshold=%ds); pos_i=%I64u pos_j=%I64u"
                              " evt_i=%d evt_j=%d; returning true -> Orchestrator MUST"
                              " call EAState::SetHalted (IMPL-052 wires this)",
                              m_buffer[i].magic, m_buffer[i].direction,
                              (int)delta, PING_PONG_THRESHOLD_S,
                              m_buffer[i].position_id, m_buffer[j].position_id,
                              m_buffer[i].event_type, m_buffer[j].event_type);

            if(m_logger != NULL)
               m_logger.ErrorBypassThrottle("CircuitBreaker", "ping_pong",
                                            m_buffer[i].magic, detail);
            else
               Print("[CircuitBreaker][ERROR] " + detail);

            // IMPL-FIX-008: reset buffer after detection so subsequent
            // ticks do not re-detect the same stale pair.
            m_count = 0;
            m_idx   = 0;
            return true;  // Orchestrator wires EAState::SetHalted
           }
         else if(delta <= (long)NEAR_MISS_THRESHOLD_S)
           {
            // Near-miss -- warn but do not halt
            near_miss_found = true;
            string warn_msg = StringFormat(
                                "near_miss: magic=%d dir=%d delta=%ds"
                                " (near_miss_threshold=%ds) evt_i=%d evt_j=%d",
                                m_buffer[i].magic, m_buffer[i].direction,
                                (int)delta, NEAR_MISS_THRESHOLD_S,
                                m_buffer[i].event_type, m_buffer[j].event_type);
            if(m_logger != NULL)
               m_logger.Warn("CircuitBreaker", "ping_pong_near_miss",
                             m_buffer[i].magic, warn_msg);
            else
               Print("[CircuitBreaker][WARN] " + warn_msg);
            // Continue scanning -- a tighter pair might still trigger halt
           }
        }
     }

   return false;  // no ping-pong halt condition
  }

//+------------------------------------------------------------------+
//| SelfTest -- inline stub-driven verification                      |
//|                                                                  |
//| Test cases (BR-3.6 threshold = 3 s; near-miss = 5 s;             |
//| ADR-014 rules require different event_type + different position):|
//|  A) close A + open B 1 s apart, same (magic=200, dir=0),         |
//|     different position_ids -> ping-pong fires (canonical signal) |
//|  B) close A + open B 4 s apart, same (magic=201, dir=1),         |
//|     different position_ids -> near-miss warn (3 < d <= 5)        |
//|  C) close A + open B 6 s apart, same (magic=202, dir=0),         |
//|     different position_ids -> no fire (d > both thresholds)      |
//|  D) close A + open B at t0+1, DIFFERENT magics -> no fire        |
//|  E) pre-Init RecordOpen + RecordClose -> buffer NOT mutated      |
//|     (fix-round-13 §13.5 pre-Init guard preserved)                |
//|  F) (NOTE) DEAL_REASON_EXPERT filter at Orchestrator.OnTrade     |
//|     Transaction (ADR-013 — producer-side broker-driven filter)   |
//|  G) (NEW ADR-014) 2 close events on same (magic=205, dir=0)      |
//|     DIFFERENT positions at delta=0s -> NO fire (mass-close       |
//|     false-positive class confirmed by IMPL-FIX-012 iter-2 Run    |
//|     #4 at sim 2021-01-27 via OrderGroupStartWorkflow SafePort    |
//|     batch close; ADR-013 reason filter alone insufficient)       |
//|  H) (NEW ADR-014) 1 open + 1 close on SAME position_id at        |
//|     delta=0s -> NO fire (legitimate intraday scalp / quick exit) |
//|                                                                  |
//| Returns true = all assertions passed.                            |
//| Prerequisite: Init must be called before SelfTest.               |
//+------------------------------------------------------------------+
bool CCircuitBreaker::SelfTest()
  {
   bool all_pass = true;

   // --- Save and reset state so SelfTest is isolated
   TradeEvent saved_buffer[16];
   int        saved_idx   = m_idx;
   int        saved_count = m_count;
   for(int i = 0; i < 16; i++)
      saved_buffer[i] = m_buffer[i];

   // Helper macro -- inline reset
#define CB_SELFTEST_RESET() { m_idx=0; m_count=0; for(int _r=0;_r<16;_r++){m_buffer[_r].magic=0;m_buffer[_r].direction=0;m_buffer[_r].time_s=0;m_buffer[_r].position_id=0;m_buffer[_r].event_type=EVT_CLOSE;} }

   datetime t0 = (datetime)1000000;   // arbitrary base epoch
   ulong    pos_a = 100001;           // synthetic position ids
   ulong    pos_b = 100002;
   ulong    pos_c = 100003;

   //--------------------------------------------------------------------
   // Case A: close A + open B 1 s apart, same (magic=200, dir=0),
   //         different position_ids -> ping-pong fires (canonical signal)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(200, 0, t0,     pos_a);
   RecordOpen (200, 0, t0 + 1, pos_b);

   bool result_a = CheckPingPong();
   if(!result_a)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case A:"
            " expected true (close A + open B 1s apart, diff pos => ping-pong),"
            " got false");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case A: ping-pong detected as expected");

   //--------------------------------------------------------------------
   // Case B: close A + open B 4 s apart, same (magic=201, dir=1),
   //         different position_ids -> near-miss warn (3 < d <= 5; no halt)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(201, 1, t0,     pos_a);
   RecordOpen (201, 1, t0 + 4, pos_b);

   bool result_b = CheckPingPong();
   if(result_b)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case B:"
            " expected false (4s gap in near-miss zone), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case B: near-miss no-halt as expected");

   //--------------------------------------------------------------------
   // Case C: close A + open B 6 s apart, same (magic=202, dir=0),
   //         different position_ids -> no fire (no trigger; no near-miss)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(202, 0, t0,     pos_a);
   RecordOpen (202, 0, t0 + 6, pos_b);

   bool result_c = CheckPingPong();
   if(result_c)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case C:"
            " expected false (6s > both thresholds), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case C: no-trigger as expected");

   //--------------------------------------------------------------------
   // Case D: close A + open B at t0+1, DIFFERENT magics -> no fire
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(200, 0, t0,     pos_a);
   RecordOpen (201, 0, t0 + 1, pos_b);

   bool result_d = CheckPingPong();
   if(result_d)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case D:"
            " expected false (different magic), got true");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case D: different-magic no-trigger as expected");

   //--------------------------------------------------------------------
   // Case E: pre-Init RecordOpen + RecordClose dropped -> buffer NOT
   //         mutated + Print fallback emitted (fix-round-13 §13.5;
   //         guards dual-gate added in fix-round-12 §12.6).
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   CLogger *saved_logger = m_logger;
   m_logger = NULL;                          // simulate pre-Init state

   RecordOpen (200, 0, t0, pos_a);           // expect: dropped, m_count == 0
   RecordClose(200, 0, t0, pos_a);           // expect: dropped, m_count == 0

   m_logger = saved_logger;                  // restore for tail of SelfTest

   if(m_count != 0)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case E:"
            " pre-Init Record* mutated buffer (m_count=", m_count,
            "), expected 0");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case E: pre-Init Record* dropped as expected");

   //--------------------------------------------------------------------
   // Case F: DEAL_REASON_EXPERT filter documented at producer side
   //         (ADR-013, IMPL-FIX-012 iter-1 2026-05-14).
   //
   //         CircuitBreaker.RecordClose itself is REASON-agnostic.
   //         The DEAL_REASON_EXPERT filter lives in
   //         core/Orchestrator.mqh::OnTradeTransaction (the producer
   //         side) so that only EA-driven closes feed RecordClose.
   //         Broker-driven closes (SL/TP/SO/rollover/etc.) are skipped
   //         at the producer; they never reach RecordClose at all.
   //
   //         See ADR-013 § Decision Validation.
   //--------------------------------------------------------------------
   Print("[CircuitBreaker][SelfTest][NOTE] Case F: DEAL_REASON_EXPERT filter"
         " enforced at Orchestrator.OnTradeTransaction (ADR-013). RecordClose"
         " is REASON-agnostic; producer-side filter ensures only EA-driven"
         " closes feed BR-3.6 detector.");

   //--------------------------------------------------------------------
   // Case G (NEW ADR-014): 2 close events on same (magic=205, dir=0)
   //         DIFFERENT positions at delta=0s -> NO fire
   //
   //         This is the mass-close false-positive class confirmed by
   //         IMPL-FIX-012 iter-2 Run #4 (2026-05-17, sim 2021-01-27
   //         15:45:07): OrderGroupStartWorkflow (SafePort) batch-closed
   //         2+ Slot_H SELL positions in the same tick. All closes
   //         carry DEAL_REASON_EXPERT so ADR-013's reason filter
   //         doesn't catch them, but they're closing DIFFERENT
   //         positions => not ping-pong. ADR-014 rule (b)
   //         (different event_type required) skips this class.
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordClose(205, 0, t0, pos_a);
   RecordClose(205, 0, t0, pos_b);     // same magic+dir+time, diff position

   bool result_g = CheckPingPong();
   if(result_g)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case G:"
            " expected false (mass-close: 2 closes same magic+dir+time"
            " diff positions = ADR-014 rule (b) skip), got true."
            " This is the IMPL-FIX-012 iter-2 Run #4 regression class.");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case G: mass-close (close+close)"
            " no-fire as expected (ADR-014 rule (b) different event_type required)");

   //--------------------------------------------------------------------
   // Case H (NEW ADR-014): 1 open + 1 close on SAME position_id at
   //         delta=0s -> NO fire (legitimate intraday scalp / quick exit)
   //
   //         A position opened and closed in the same tick is a normal
   //         intraday scalp pattern, not ping-pong. ADR-014 rule (c)
   //         (different position_id required) skips this class.
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   RecordOpen (206, 0, t0, pos_a);
   RecordClose(206, 0, t0, pos_a);     // same magic+dir+time+position

   bool result_h = CheckPingPong();
   if(result_h)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case H:"
            " expected false (open+close same position = normal trade"
            " ADR-014 rule (c) skip), got true.");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case H: open+close same position"
            " no-fire as expected (ADR-014 rule (c) different position_id required)");

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
      Print("[CircuitBreaker][SelfTest] One or more cases FAILED -- see above");

   return all_pass;
  }

//+------------------------------------------------------------------+
//| Static-member out-of-class definitions (IMPL-059 ODR fix +        |
//| ADR-014 event-type constants)                                    |
//+------------------------------------------------------------------+
const int CCircuitBreaker::PING_PONG_THRESHOLD_S = 3;
const int CCircuitBreaker::NEAR_MISS_THRESHOLD_S = 5;
const int CCircuitBreaker::EVT_OPEN              = 0;
const int CCircuitBreaker::EVT_CLOSE             = 1;

#endif // PHOENICISNEX_SERVICES_CIRCUITBREAKER_MQH
