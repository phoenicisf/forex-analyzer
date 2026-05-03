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

   // Run inline SelfTest — covers all S-AC + E-AC of IMPL-049 (sub-pass d).
   if(!g_pmr.SelfTest(&g_logger))
     {
      Print("Spike_PendingMachineRegistry: SelfTest FAILED");
      return INIT_FAILED;
     }

   // Init with TD-02 §5.10 default (M=150 / T=80 / Q=100 + BR-6.x defaults).
   // Pass NULL for state/journal — sub-pass (a) skeleton tolerates NULL deps
   // (no-op pathways) so the spike compiles + boots without the full DI
   // chain ของ Orchestrator. Finding 04.7: portfolio arg dropped.
   g_pmr.Init(150, 80, 100,
              8, 30, 40, 70, 9,
              NULL, NULL, &g_logger);

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

   // Exercise TickAll dispatch.
   MarketContext ctx;
   ZeroMemory(ctx);
   ctx.bar_index_h4 = 100;
   g_pmr.TickAll(ctx);

   // === Sub-pass (b) — legacy timeout enforcement =====================

   // PM_C legacy timeout = 8 bars. Enter at bar 100; tick at bar 108
   // should transition IDLE (age=8 ≥ 8).
   g_pmr.EnterPending(PM_C, "{\"slot\":\"C\"}", 100);
   ctx.bar_index_h4 = 107;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_C) != PENDING_STATE_PENDING)
     {
      Print("Spike_PMR: PM_C should still be PENDING at age=7");
      return INIT_FAILED;
     }
   ctx.bar_index_h4 = 108;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_C) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_C should be IDLE after age=8 timeout");
      return INIT_FAILED;
     }

   // PM_R legacy timeout = 40 bars.
   g_pmr.EnterPending(PM_R, "{\"slot\":\"R\"}", 200);
   ctx.bar_index_h4 = 240;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_R) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_R should be IDLE after age=40 timeout");
      return INIT_FAILED;
     }

   // PM_P with sub-mode PX — verify accessor + timeout reason includes mode.
   g_pmr.EnterPPending(PSUB_PX, 250.0, 80.5, 300);
   if(g_pmr.GetState(PM_P) != PENDING_STATE_PENDING)
     {
      Print("Spike_PMR: PM_P should be PENDING after EnterPPending");
      return INIT_FAILED;
     }
   if(g_pmr.GetPSubMode() != PSUB_PX)
     {
      Print("Spike_PMR: GetPSubMode should return PSUB_PX");
      return INIT_FAILED;
     }
   if(MathAbs(g_pmr.GetPDiffSL() - 250.0) > 0.01)
     {
      PrintFormat("Spike_PMR: GetPDiffSL=%.2f expected 250.0", g_pmr.GetPDiffSL());
      return INIT_FAILED;
     }
   if(MathAbs(g_pmr.GetPBandRatio() - 80.5) > 0.01)
     {
      PrintFormat("Spike_PMR: GetPBandRatio=%.2f expected 80.5", g_pmr.GetPBandRatio());
      return INIT_FAILED;
     }
   ctx.bar_index_h4 = 370;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_P) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_P should be IDLE after age=70 timeout");
      return INIT_FAILED;
     }

   // PM_C_ADX legacy timeout = 30 bars.
   g_pmr.EnterPending(PM_C_ADX, "{\"slot\":\"C_ADX\"}", 400);
   ctx.bar_index_h4 = 430;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_C_ADX) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_C_ADX should be IDLE after age=30 timeout");
      return INIT_FAILED;
     }

   // PM_FORCE legacy timeout = 9 bars.
   g_pmr.EnterPending(PM_FORCE,
                      CPendingForce::BuildPayload("C", 99, 1, 500),
                      500);
   ctx.bar_index_h4 = 509;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_FORCE) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_FORCE should be IDLE after age=9 timeout");
      return INIT_FAILED;
     }

   // PM_M / PM_T / PM_Q have NO legacy timeout — should still be IDLE
   // (untouched from initial state) after running long ticks.
   if(g_pmr.GetState(PM_M) != PENDING_STATE_IDLE) { Print("PM_M not IDLE"); return INIT_FAILED; }
   if(g_pmr.GetState(PM_T) != PENDING_STATE_IDLE) { Print("PM_T not IDLE"); return INIT_FAILED; }
   if(g_pmr.GetState(PM_Q) != PENDING_STATE_IDLE) { Print("PM_Q not IDLE"); return INIT_FAILED; }

   // === Sub-pass (c) — force-clear (ADR-008) ==========================

   // PM_M threshold = 150. Age=149 still PENDING; age=150 → IDLE + count++.
   g_pmr.EnterPending(PM_M, "{\"slot\":\"M\"}", 1000);
   ctx.bar_index_h4 = 1149;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_M) != PENDING_STATE_PENDING)
     {
      Print("Spike_PMR: PM_M should still be PENDING at age=149");
      return INIT_FAILED;
     }
   if(g_pmr.GetForceClearCount(PM_M) != 0)
     {
      Print("Spike_PMR: PM_M force_clear_count should be 0 pre-trigger");
      return INIT_FAILED;
     }
   ctx.bar_index_h4 = 1150;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_M) != PENDING_STATE_IDLE)
     {
      Print("Spike_PMR: PM_M should be IDLE after force-clear at age=150");
      return INIT_FAILED;
     }
   if(g_pmr.GetForceClearCount(PM_M) != 1)
     {
      PrintFormat("Spike_PMR: PM_M force_clear_count=%d expected 1",
                  g_pmr.GetForceClearCount(PM_M));
      return INIT_FAILED;
     }

   // PM_T threshold = 80.
   g_pmr.EnterPending(PM_T, "{\"slot\":\"T\"}", 2000);
   ctx.bar_index_h4 = 2080;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_T) != PENDING_STATE_IDLE ||
      g_pmr.GetForceClearCount(PM_T) != 1)
     {
      Print("Spike_PMR: PM_T force-clear at age=80 failed");
      return INIT_FAILED;
     }

   // PM_Q threshold = 100.
   g_pmr.EnterPending(PM_Q, "{\"slot\":\"Q\"}", 3000);
   ctx.bar_index_h4 = 3100;
   g_pmr.TickAll(ctx);
   if(g_pmr.GetState(PM_Q) != PENDING_STATE_IDLE ||
      g_pmr.GetForceClearCount(PM_Q) != 1)
     {
      Print("Spike_PMR: PM_Q force-clear at age=100 failed");
      return INIT_FAILED;
     }

   // PM_C / PM_R / PM_P / PM_FORCE must NOT trigger force-clear path
   // (they have legacy timeout only). Re-enter PM_C and advance well
   // past M-threshold; force_clear_count must remain 0.
   g_pmr.EnterPending(PM_C, "{\"slot\":\"C\"}", 4000);
   ctx.bar_index_h4 = 4007;   // before C legacy timeout (8) so PENDING
   g_pmr.TickAll(ctx);
   if(g_pmr.GetForceClearCount(PM_C) != 0)
     {
      Print("Spike_PMR: PM_C should not have force_clear_count > 0");
      return INIT_FAILED;
     }
   g_pmr.TransitionIdle(PM_C, "test_cleanup");

   Print("Spike_PendingMachineRegistry: sub-pass (a)+(b)+(c) OK");
   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
