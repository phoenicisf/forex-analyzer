//+------------------------------------------------------------------+
//|                                  Spike_PendingMachineRegistry.mq5|
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile gate for IMPL-049 sub-pass (a): exercises class shape, |
//| Init signature, TickAll dispatch, accessor surface, and           |
//| CPendingForce payload BuildPayload/ParsePayload round-trip.       |
//| Per-machine TickMachine bodies are stubs; full SelfTest lands in  |
//| sub-pass (d).                                                     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../services/PendingMachineRegistry.mqh"
#include "../services/Logger.mqh"

CLogger                  g_logger;
CPendingMachineRegistry  g_pmr;

int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   // Init with TD-02 §5.10 default (M=150 / T=80 / Q=100 + BR-6.x defaults).
   // Pass NULL for state/journal/portfolio — sub-pass (a) skeleton tolerates
   // NULL deps (no-op pathways) so the spike compiles + boots without the
   // full DI chain ของ Orchestrator.
   g_pmr.Init(150, 80, 100,
              8, 30, 40, 70, 9,
              NULL, NULL, &g_logger, NULL);

   // Exercise transition surface.
   g_pmr.EnterPending(PM_C, "{\"slot\":\"C\"}", 100);
   if(g_pmr.GetState(PM_C) != PENDING_STATE_PENDING)
     {
      Print("Spike_PMR: EnterPending(PM_C) failed");
      return INIT_FAILED;
     }
   g_pmr.TransitionExecuted(PM_C);
   if(g_pmr.GetState(PM_C) != PENDING_STATE_EXECUTED)
     {
      Print("Spike_PMR: TransitionExecuted(PM_C) failed");
      return INIT_FAILED;
     }
   g_pmr.TransitionIdle(PM_C, "test");
   if(g_pmr.GetState(PM_C) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: TransitionIdle(PM_C) failed");
      return INIT_FAILED;
     }

   // CPendingForce payload round-trip.
   string p = CPendingForce::BuildPayload("C", 12345, 1, 42);
   string  out_origin;
   ulong   out_ticket;
   int     out_dir;
   int     out_bar;
   if(!CPendingForce::ParsePayload(p, out_origin, out_ticket, out_dir, out_bar))
     {
      Print("Spike_PMR: CPendingForce::ParsePayload returned false");
      return INIT_FAILED;
     }
   if(out_origin != "C" || out_ticket != 12345 || out_dir != 1 || out_bar != 42)
     {
      PrintFormat("Spike_PMR: parse mismatch origin=%s ticket=%I64u dir=%d bar=%d",
                  out_origin, out_ticket, out_dir, out_bar);
      return INIT_FAILED;
     }

   // Exercise TickAll dispatch (no-op bodies in sub-pass (a)).
   MarketContext ctx;
   ZeroMemory(ctx);
   ctx.bar_index_h4 = 100;
   CPortfolioState empty_port;
   empty_port.Init(&g_logger);
   g_pmr.TickAll(ctx, empty_port);

   Print("Spike_PendingMachineRegistry: sub-pass (a) skeleton OK");
   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
