//+------------------------------------------------------------------+
//|                              PhoenicisNex_TickLatencyProbe.mq5    |
//|                                       Copyright 2026, PhoenicisNex|
//|                                       https://phoenicisnex.com    |
//+------------------------------------------------------------------+
//| fix-round-18 §18.5 / IMPL-FIX-003 — instrumented build wrapper.   |
//|                                                                   |
//| Identical to PhoenicisNex.mq5 except that ENABLE_TICK_LATENCY is  |
//| defined BEFORE the include chain, which compiles the              |
//| services/TickLatencyProbe.mqh body + the Orchestrator probe       |
//| Stage{Start,End} call sites. Production build keeps PhoenicisNex  |
//| .mq5 unchanged (zero overhead when the wrapper is unused).        |
//|                                                                   |
//| Used by simulation/headless-tests/tick_latency_smoke.ini for the  |
//| IMPL-FIX-003 structural pre-drain (review-round-18 §18.5).        |
//| Empirically asserts the post-fix-round-17 §17.2 invariant         |
//| n_count[ENTRY] < n_count[REFRESH] (entry stage skipped by the     |
//| morning-window / holiday gating at least once in the window).     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, PhoenicisNex"
#property link        "https://phoenicisnex.com"
#property version     "1.00"
#property description "PhoenicisNex EA — ENABLE_TICK_LATENCY instrumented build (IMPL-FIX-003)"
#property strict
#property tester_no_cache

//--- fix-round-18 §18.5 — must precede the include chain so all sites that
//    `#ifdef ENABLE_TICK_LATENCY` (TickLatencyProbe.mqh body + Orchestrator
//    probe call sites) compile-in.
#define ENABLE_TICK_LATENCY 1

#include "core/Orchestrator.mqh"

COrchestrator g_orchestrator;

int OnInit()
  {
   return g_orchestrator.OnInit();
  }

void OnTick()
  {
   g_orchestrator.OnTick();
  }

void OnDeinit(const int reason)
  {
   g_orchestrator.OnDeinit(reason);
  }

double OnTester()
  {
   return g_orchestrator.OnTester();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest      &request,
                        const MqlTradeResult       &result)
  {
   g_orchestrator.OnTradeTransaction(trans, request, result);
  }
