//+------------------------------------------------------------------+
//| services/TickLatencyProbe.mqh — per-stage tick latency probe     |
//| Layer:   services/                                                |
//| Owner:   IMPL-065                                                 |
//| Sources: NFR-2.1 (tick latency overhead ≤ 10% avg, ≤ 20% p95,   |
//|          ≤ 30% p99); IMPL-066 ring-buffer idiom (TradeJournal)   |
//|                                                                   |
//| Usage:   Compiled only when #define ENABLE_TICK_LATENCY is set   |
//|          in PhoenicisNex.mq5 before #include chain. Production   |
//|          build omits this file entirely (zero overhead).         |
//|                                                                   |
//| Pattern: 8 ring buffers (one per OnTick stage), each 200 samples |
//|          deep. Running aggregates (total_us, max_us, count) per  |
//|          stage. Emit `[ev=tick_latency_report]` via Logger every |
//|          1000 ticks and at OnDeinit final flush.                  |
//|          p95 computed by partial-sort on a local copy of ring.   |
//|          p99 computed likewise (index = (int)(count * 0.99)).     |
//|                                                                   |
//| NOT routed through TradeJournal — that would cause recursive     |
//| timing pollution. Logger.Info path only (millisecond granularity |
//| acceptable for a diagnostic report line).                        |
//|                                                                   |
//| Scope (fix-round-17 § 17.6) — 8 of TD-02 §7.2's 14 OnTick steps  |
//| are timed: 1 (refresh), 2 (ctx_build), 7 (portfolio), 8 (pending),|
//| 9 (exit_pass), 11 (entry_pass), 12 (monitor), 13 (state_save).   |
//| Steps 3 (logger boundary), 4 (circuit breaker), 5 (indicator     |
//| handle scan), 5b (xslot SetHalted), 6 (time gates), 10 (holiday  |
//| block), 13b (journal sustained-fail), 14 (HALTED transition) are |
//| OMITTED because each is < 10 µs typical (stub call / boolean     |
//| evaluation / cached scan); their aggregate is dominated by the   |
//| timed 8. NFR-2.1 overhead-% denominator = sum of timed stages    |
//| ONLY. See `docs/state/nfr-2.1-tick-latency.md § Scope` for       |
//| operator-drain expectations.                                     |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_TICKLATENCYPROBE_MQH
#define PHOENICISNEX_SERVICES_TICKLATENCYPROBE_MQH

#ifdef ENABLE_TICK_LATENCY

#include "Logger.mqh"

//--- Stage index constants (doc-order matches OnTick numbered steps)
#define TLPROBE_STAGE_REFRESH   0   // step 1  m_indicators.Refresh()
#define TLPROBE_STAGE_CTX       1   // step 2  m_ctx_builder.Build()
#define TLPROBE_STAGE_PORTFOLIO 2   // step 7  m_portfolio.Refresh()
#define TLPROBE_STAGE_PENDING   3   // step 8  m_pending.TickAll(ctx)
#define TLPROBE_STAGE_EXIT      4   // step 9  RunExitPass + siblings
#define TLPROBE_STAGE_ENTRY     5   // step 11 RunEntryPass + RunEOverload
#define TLPROBE_STAGE_MONITOR   6   // step 12 m_monitor.Update()
#define TLPROBE_STAGE_SAVE      7   // step 13 m_state.Save()
#define TLPROBE_STAGE_COUNT     8
#define TLPROBE_RING_SIZE       200

// fix-round-18 §18.2 — periodic emit cadence (tunable for short tester runs)
#ifndef TLPROBE_PERIODIC_EVERY
#define TLPROBE_PERIODIC_EVERY  1000
#endif

static const string TLPROBE_STAGE_NAMES[TLPROBE_STAGE_COUNT] =
  {
   "refresh", "ctx_build", "portfolio", "pending",
   "exit_pass", "entry_pass", "monitor", "state_save"
  };

//+------------------------------------------------------------------+
//| CTickLatencyProbe — encapsulates 8 ring buffers + emit logic     |
//+------------------------------------------------------------------+
class CTickLatencyProbe
  {
private:
   //--- Per-stage ring buffers + aggregates (mirrors IMPL-066 idiom)
   //    fix-round-18 §18.6 — counters promoted to ulong to remove the
   //    INT_MAX overflow surface on multi-yr / stress runs (5-yr ≈ 1.6B
   //    samples per stage; 10-yr crosses INT_MAX). avg = total_us/count
   //    cast bug only manifests after overflow, but defensive typing is
   //    cheap.
   ulong   m_samples[TLPROBE_STAGE_COUNT][TLPROBE_RING_SIZE]; // [stage][slot]
   ulong   m_idx[TLPROBE_STAGE_COUNT];          // next write index (mod TLPROBE_RING_SIZE)
   ulong   m_total_us[TLPROBE_STAGE_COUNT];     // running sum
   ulong   m_max_us[TLPROBE_STAGE_COUNT];       // running max
   ulong   m_count[TLPROBE_STAGE_COUNT];        // total samples recorded

   //--- Pending start timestamps (one per stage; set on StageStart, read on StageEnd)
   ulong   m_t0[TLPROBE_STAGE_COUNT];

   //--- Tick counter for periodic emit cadence (every TLPROBE_PERIODIC_EVERY ticks)
   ulong   m_tick_count;

   CLogger *m_logger; // borrowed pointer — NOT owned; do not delete

   //--- Internal: sort a ring-buffer copy and return quantile value
   ulong   _Quantile(const int stage, const double pct);

   //--- Internal: build + emit one report line per stage (full per-stage detail)
   void    _EmitReport(const string trigger);

   //--- fix-round-18 §18.2 — single-line periodic summary (no per-stage loop)
   void    _EmitOneLineSummary(const string trigger);

public:
                     CTickLatencyProbe()
      : m_tick_count(0), m_logger(NULL)
     {
      ArrayInitialize(m_idx,      0);
      ArrayInitialize(m_total_us, 0);
      ArrayInitialize(m_max_us,   0);
      ArrayInitialize(m_count,    0);
      ArrayInitialize(m_t0,       0);
      // MQL5 does not allow ArrayInitialize on 2D arrays — zero each row
      for(int s = 0; s < TLPROBE_STAGE_COUNT; s++)
         for(int i = 0; i < TLPROBE_RING_SIZE; i++)
            m_samples[s][i] = 0;
     }

   void              Init(CLogger *logger) { m_logger = logger; }

   //--- Call at OnTick start (before first stage) to increment counter + check cadence
   void              OnTickStart();

   //--- Mark start/end of a named stage
   void              StageStart(const int stage);
   void              StageEnd(const int stage);

   //--- Force final emit (call from OnDeinit before _TeardownAll)
   void              FinalEmit();
  };

//--- CTickLatencyProbe::OnTickStart
//
// fix-round-18 §18.2 — periodic emit now writes a single Logger.Info line
// (header summary only); full per-stage detail report is reserved for
// FinalEmit() at OnDeinit. Honours XS-17.1 hot-path rule "instrumentation
// NEVER invokes I/O on the hot-path; periodic = Logger only" by reducing
// 9 Logger.Info calls per cadence to 1, eliminating ~270 µs measurement-
// pollutes-host spikes from the NFR-2.1 overhead delta.
void CTickLatencyProbe::OnTickStart()
  {
   m_tick_count++;
   if(m_tick_count % TLPROBE_PERIODIC_EVERY == 0)
      _EmitOneLineSummary("periodic_checkpoint");
  }

//--- CTickLatencyProbe::StageStart
void CTickLatencyProbe::StageStart(const int stage)
  {
   if(stage < 0 || stage >= TLPROBE_STAGE_COUNT) return;
   m_t0[stage] = GetMicrosecondCount();
  }

//--- CTickLatencyProbe::StageEnd
void CTickLatencyProbe::StageEnd(const int stage)
  {
   if(stage < 0 || stage >= TLPROBE_STAGE_COUNT) return;
   if(m_t0[stage] == 0) return; // StageStart not called — skip
   ulong dt = GetMicrosecondCount() - m_t0[stage];
   m_t0[stage] = 0;

   // Accumulate per-stage ring + aggregates (IMPL-066 idiom)
   m_total_us[stage] += dt;
   if(dt > m_max_us[stage]) m_max_us[stage] = dt;
   m_samples[stage][(int)(m_idx[stage] % (ulong)TLPROBE_RING_SIZE)] = dt;
   m_idx[stage]++;
   m_count[stage]++;
  }

//--- CTickLatencyProbe::_Quantile — sort ring copy, return floor(pct * n) element
ulong CTickLatencyProbe::_Quantile(const int stage, const double pct)
  {
   int n = (int)MathMin(m_count[stage], (ulong)TLPROBE_RING_SIZE);
   if(n <= 0) return 0;

   ulong buf[];
   ArrayResize(buf, n);
   for(int i = 0; i < n; i++)
      buf[i] = m_samples[stage][i];

   // Insertion sort (200 elements max — acceptable)
   for(int i = 1; i < n; i++)
     {
      ulong key = buf[i];
      int j = i - 1;
      while(j >= 0 && buf[j] > key)
        {
         buf[j + 1] = buf[j];
         j--;
        }
      buf[j + 1] = key;
     }

   int qi = (int)MathFloor(pct * (n - 1));
   if(qi < 0) qi = 0;
   if(qi >= n) qi = n - 1;
   return buf[qi];
  }

//--- CTickLatencyProbe::_EmitReport
void CTickLatencyProbe::_EmitReport(const string trigger)
  {
   if(m_logger == NULL) return;

   // Header line
   m_logger.Info("system", "tick_latency_report", 0,
                 StringFormat("trigger=%s ticks=%llu", trigger, m_tick_count));

   // Per-stage lines
   for(int s = 0; s < TLPROBE_STAGE_COUNT; s++)
     {
      if(m_count[s] == 0)
        {
         m_logger.Info("system", "tick_latency_report", 0,
                       StringFormat("  stage=%-12s n=0 (not sampled)",
                                    TLPROBE_STAGE_NAMES[s]));
         continue;
        }

      ulong avg_us = (m_count[s] > 0) ? (m_total_us[s] / m_count[s]) : 0;
      ulong p95_us = _Quantile(s, 0.95);
      ulong p99_us = _Quantile(s, 0.99);
      ulong max_us = m_max_us[s];
      ulong n      = m_count[s];

      m_logger.Info("system", "tick_latency_report", 0,
                    StringFormat("  stage=%-12s n=%llu avg=%lluus p95=%lluus p99=%lluus max=%lluus",
                                 TLPROBE_STAGE_NAMES[s], n,
                                 avg_us, p95_us, p99_us, max_us));
     }
  }

//--- CTickLatencyProbe::_EmitOneLineSummary — fix-round-18 §18.2
//
// One Logger.Info line; no per-stage loop, no _Quantile calls. Operator
// reads "ticks=N (per-stage detail at OnDeinit)" and waits for FinalEmit
// for the full report. Keeps periodic checkpoint cost to ~30 µs (single
// Print + file write) instead of ~270 µs (9 calls + 8× insertion-sort).
void CTickLatencyProbe::_EmitOneLineSummary(const string trigger)
  {
   if(m_logger == NULL) return;
   m_logger.Info("system", "tick_latency_periodic", 0,
                 StringFormat("trigger=%s ticks=%llu (per-stage detail at OnDeinit)",
                              trigger, m_tick_count));
  }

//--- CTickLatencyProbe::FinalEmit
void CTickLatencyProbe::FinalEmit()
  {
   _EmitReport("final_deinit");
  }

#endif // ENABLE_TICK_LATENCY

#endif // PHOENICISNEX_SERVICES_TICKLATENCYPROBE_MQH
