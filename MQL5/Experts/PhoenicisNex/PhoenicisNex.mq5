//+------------------------------------------------------------------+
//|                                                  PhoenicisNex.mq5 |
//|                                       Copyright 2026, PhoenicisNex|
//|                                       https://phoenicisnex.com    |
//+------------------------------------------------------------------+
//| IMPL-060 — Entry point thin wrapper.                              |
//|                                                                   |
//| Per ADR-012 + CLAUDE.md §3 + .claude/rules/ea.md (≤ 500 LOC):     |
//|   • NO business logic in this file                                |
//|   • Single global COrchestrator owns 16 services + 4 helpers +    |
//|     4 core peers + 21 derived slots                               |
//|   • All MT5 lifecycle events thin-delegate to g_orchestrator      |
//|                                                                   |
//| Input declarations are pulled in transitively:                    |
//|   core/Orchestrator.mqh → inputs/{General,TimeGates,Pending,      |
//|   Logging}.mqh; core/SlotRegistry.mqh → 21× slots/Slot_<X>.mqh    |
//|   → 21× inputs/Inputs_Slot_<X>.mqh.                               |
//|                                                                   |
//| MT5 lifecycle contract (https://www.mql5.com/en/docs/event_handlers): |
//|   OnInit              — symbol/period validation, indicator       |
//|                          handle creation, state restore           |
//|   OnTick              — F1 14-step pipeline (TD-02 §7.2)          |
//|   OnDeinit            — inverse-order release                     |
//|   OnTester            — Strategy Tester custom score              |
//|   OnTradeTransaction  — close-deal feed → CircuitBreaker BR-3.6   |
//|                          (D-8 / fix-round-10 § 10.3)              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"
#property description "PhoenicisNex EA — single-instrument EURUSD H4 modular monolith"
#property strict

#include "core/Orchestrator.mqh"

//--- Single global composition root.
//    Default-constructed (all member pointers NULL); WireServices()
//    runs on first OnInit() invocation. Dtor on EA unload routes
//    through CleanupPartialInit("dtor_fallback") as a defensive net
//    in case OnDeinit was skipped (per Orchestrator.mqh § dtor).
COrchestrator g_orchestrator;

//+------------------------------------------------------------------+
//| OnInit — delegate to composition root                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   return g_orchestrator.OnInit();
  }

//+------------------------------------------------------------------+
//| OnTick — delegate to F1 pipeline                                 |
//+------------------------------------------------------------------+
void OnTick()
  {
   g_orchestrator.OnTick();
  }

//+------------------------------------------------------------------+
//| OnDeinit — delegate to inverse-order release                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_orchestrator.OnDeinit(reason);
  }

//+------------------------------------------------------------------+
//| OnTester — delegate to custom score                              |
//+------------------------------------------------------------------+
double OnTester()
  {
   return g_orchestrator.OnTester();
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction — feed CircuitBreaker BR-3.6 close stream     |
//|   D-8 / fix-round-10 § 10.3: producer-side wiring required so    |
//|   the ping-pong detector receives non-empty input.               |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest      &request,
                        const MqlTradeResult       &result)
  {
   g_orchestrator.OnTradeTransaction(trans, request, result);
  }

//+------------------------------------------------------------------+
