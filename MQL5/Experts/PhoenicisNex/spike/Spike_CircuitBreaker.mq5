//+------------------------------------------------------------------+
//|                                          Spike_CircuitBreaker.mq5|
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for CCircuitBreaker (BR-3.6 + ADR-010)|
//|                                                                  |
//| Coverage (mirrors Spike_PendingMachineRegistry.mq5 invocation     |
//| pattern):                                                         |
//|   - CCircuitBreaker compiles cleanly (services/CircuitBreaker.mqh)|
//|   - Logger Init → CircuitBreaker Init wires non-NULL m_logger     |
//|   - SelfTest exercises Cases A–E:                                 |
//|       A) ping-pong detected (Δ ≤ 3 s threshold) → CheckPingPong=true|
//|       B) near-miss (3 s < Δ ≤ 5 s) → no halt + Warn emitted       |
//|       C) Δ > 5 s → no trigger / no near-miss                      |
//|       D) different (magic, dir) pair → no trigger                 |
//|       E) pre-Init RecordOpen/RecordClose dropped (NULL-logger     |
//|          guard added in fix-round-12 § 12.6 + Case E added in     |
//|          fix-round-13 § 13.5)                                     |
//|                                                                  |
//| fix-round-14 § 14.2 — wires CCircuitBreaker::SelfTest() into a    |
//|   runnable spike. Without this harness, Cases A–E provide zero    |
//|   runtime regression detection (the SelfTest method has no other  |
//|   caller in the codebase: production OnInit only calls Init,      |
//|   never SelfTest). With this spike attached the regression gate   |
//|   that R13 § 13.5 motivated actually executes at G1 boot.         |
//|                                                                  |
//| Pattern: mirrors Spike_PendingMachineRegistry.mq5 (logger first,  |
//|   then service, then SelfTest invocation; INIT_FAILED on miss).   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"
#property strict

#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body
#include "../services/CircuitBreaker.mqh"

CLogger          g_logger;
CCircuitBreaker  g_breaker;

//+------------------------------------------------------------------+
//| OnInit — Logger init → CircuitBreaker init → SelfTest             |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("[Phoenicis] Spike_CircuitBreaker: G1 compile gate + SelfTest exercise start");

   //--- Logger first (CCircuitBreaker::Init takes CLogger* — must be live)
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Wire breaker to logger so SelfTest's Init-precondition holds
   //    (Cases A–D require live m_logger; Case E swaps NULL in/out
   //     internally to simulate pre-Init dispatch).
   g_breaker.Init(&g_logger);

   if(!g_breaker.SelfTest())
     {
      Print("[Phoenicis] Spike_CircuitBreaker: SelfTest FAILED");
      return INIT_FAILED;
     }

   Print("[Phoenicis] Spike_CircuitBreaker: SelfTest PASS (5 cases A–E)");
   return INIT_SUCCEEDED;
  }

void OnTick() { }
void OnDeinit(const int reason) { }
double OnTester() { return(0.0); }
