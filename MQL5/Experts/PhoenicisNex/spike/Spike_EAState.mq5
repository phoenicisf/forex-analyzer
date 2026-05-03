//+------------------------------------------------------------------+
//|                                                Spike_EAState.mq5 |
//|                                      Copyright 2026, PhoenicisNex|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/EAState.mqh"
#include "../services/Logger.mqh"
#include "../services/TradeJournal.mqh"

CLogger g_logger;
CTradeJournal g_journal;

int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);
   
   CEAState ea;
   // We skip TradeJournal real init to keep it simple, just pass pointers
   ea.Init(&g_journal, &g_logger);
   
   if (!ea.SelfTest(&g_logger)) {
      Print("Spike_EAState: SelfTest failed");
      return INIT_FAILED;
   }
   
   Print("Spike_EAState: SelfTest passed");
   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
