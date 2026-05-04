//+------------------------------------------------------------------+
//|                                  Spike_CrossSlotCoordinator.mq5 |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile gate for IMPL-053..058 + IMPL-057: exercises          |
//| CCrossSlotCoordinator Init signature, SafePort trigger gate,     |
//| target-table integrity, ForceCutloss signal truth-table,         |
//| ExtraCheckFunction2 demote predicate, OrderGroupStartWorkflow2   |
//| trigger predicate, HALTED enable-matrix audit (entry-side guard +|
//| exit-side reachability), and BR-8.4 overload-helper predicate    |
//| truth-tables (EOverload + COverload) + reach-without-crash on    |
//| GOverload via inline SelfTest (now 36 cases — IMPL-053 7 +       |
//| IMPL-055 6 + IMPL-056 6 + IMPL-054 6 + IMPL-058 3 + IMPL-057 8). |
//| Full BR-8.x runtime smoke arrives at IMPL-059+ Orchestrator wire.|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../services/CrossSlotCoordinator.mqh"
#include "../services/Logger.mqh"

CLogger                  g_logger;
CCrossSlotCoordinator    g_xslot;

int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   // Init() with NULL deps — SelfTest exercises trigger-gate logic only;
   // platform-side _AggregateWeakMetrics is not exercised in spike (no
   // open positions during spike OnInit) and would early-return on the
   // (m_portfolio == NULL || m_pip == NULL) guard regardless.
   g_xslot.Init(NULL, NULL, &g_logger, NULL);

   if(!g_xslot.SelfTest(&g_logger))
     {
      Print("Spike_CrossSlotCoordinator: SelfTest FAILED");
      return INIT_FAILED;
     }
   Print("Spike_CrossSlotCoordinator: SelfTest OK");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason) {}

void OnTick() {}
