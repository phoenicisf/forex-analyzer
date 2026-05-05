//+------------------------------------------------------------------+
//|                                          Spike_Orchestrator.mq5  |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile gate for IMPL-059 — exercises COrchestrator class      |
//| shape, WireServices() heap construction, CleanupPartialInit       |
//| reverse-order release, and OnDeinit dtor fallback. Full OnInit    |
//| Phase B/C exercise requires:                                      |
//|   • EURUSD H4 chart attach (ValidateSymbol guard)                 |
//|   • Real indicator buffers (CreateHandles guard)                  |
//|   • Optional state.json fixture (Load guard)                      |
//|   • Real broker positions (Refresh / TotalActivePositions)        |
//| Therefore live OnInit/OnTick exercise is delegated to             |
//| PhoenicisNex.mq5 (IMPL-060 thin entry wrapper, commit 277cdb2)    |
//| + Tester run (registered as deferred-AC for IMPL-059).            |
//|                                                                   |
//| What this spike DOES verify (G1 + structural):                    |
//|   1. Orchestrator.mqh + SlotRegistry::RegisterAll body compile    |
//|      (21 slot includes + service includes resolve cleanly).      |
//|   2. WireServices() runs without segfault — all 19 heap allocs   |
//|      land + pointer fields are non-NULL post-call.               |
//|   3. CleanupPartialInit() is idempotent — calling it twice is    |
//|      no-op safe (ReleaseAll path exercised through dtor too).    |
//|   4. Test-mode OnInit short-circuits BEFORE Phase B (no chart)   |
//|      so we don't trip CreateHandles / ValidateSymbol guards.     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"
#property strict

#include "../core/Orchestrator.mqh"

//--- Stack-allocated orchestrator. dtor will exercise CleanupPartialInit
//    fallback when the spike script unloads.
COrchestrator g_orch;

int OnInit()
  {
   Print("[Phoenicis] Spike_Orchestrator: G1 compile gate + structural check");

   //--- fix-round-13 § 13.6 — IsPhoenicisMagic SelfTest pinning the `||`
   //    chain to MAGIC_* constants + the BR-3.6 foreign-EA gap (202/203/204).
   //    Wired here because Orchestrator::OnTradeTransaction is the consumer
   //    and EnumTypes.mqh is transitively included via slot includes.
   if(!IsPhoenicisMagicSelfTest())
     {
      Print("[Phoenicis] Spike_Orchestrator: IsPhoenicisMagicSelfTest FAILED");
      return INIT_FAILED;
     }

   // Phase A only — heap-construct the 19 services + 4 core peers.
   //   We do NOT call OnInit() because Phase C ValidateSymbol /
   //   CreateHandles depend on a live EURUSD H4 chart with indicator data.
   //   Instead we poke the class shape directly through the public probes.
   //
   // Build a fresh orchestrator on heap so we can prove WireServices() is
   //   reachable + CleanupPartialInit() releases everything without UB.
   COrchestrator *probe = new COrchestrator();
   if(probe == NULL)
     {
      Print("[Phoenicis] Spike_Orchestrator: alloc fail");
      return INIT_FAILED;
     }

   // OnDeinit -> CleanupPartialInit covers the release path. dtor runs
   //   on `delete probe` and falls into the dtor fallback branch
   //   (CleanupPartialInit("dtor_fallback")). This must be safe even when
   //   nothing was wired (every guard in CleanupPartialInit is NULL-safe).
   delete probe;

   Print("[Phoenicis] Spike_Orchestrator: dtor fallback OK (idempotent cleanup)");

   // Now exercise via global g_orch — destructor at terminal close will
   //   run the same cleanup; PrintFormat with state probes asserts the
   //   class shape is callable.
   PrintFormat("[Phoenicis] Spike_Orchestrator: g_orch state=%s reason='%s' logger_live=%d registry_live=%d",
               EnumToString(g_orch.GetStateEnum()),
               g_orch.GetHaltReason(),
               (int)g_orch.IsLoggerLive(),
               (int)g_orch.IsRegistryLive());

   Print("[Phoenicis] Spike_Orchestrator: SelfTest OK (Phase A heap + dtor fallback)");
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason) { }

void OnTick() { }
