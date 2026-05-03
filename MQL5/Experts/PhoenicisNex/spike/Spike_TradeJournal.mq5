//+------------------------------------------------------------------+
//| Spike_TradeJournal.mq5 — IMPL-043 compile/runtime smoke harness |
//| Exercises TradeJournal open/write/close in OnInit only.         |
//+------------------------------------------------------------------+
#property strict
#property copyright "PhoenicisNex"
#property version   "1.00"

#include "../services/TradeJournal.mqh"

string ReadFileContent(string path)
  {
   if(!FileIsExist(path))
      return "";
   int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return "";
   string content = "";
   while(!FileIsEnding(handle))
      content += FileReadString(handle);
   FileClose(handle);
   return content;
  }

int OnInit()
  {
   Print("[Phoenicis][spike][ev=impl043_start] Spike_TradeJournal beginning");

   CLogger logger;
   logger.Init(LOG_INFO, false, 10);

   CTradeJournal journal;
   journal.Init(NULL, NULL, &logger, NULL);

   if(!journal.Open())
     {
      Print("[Phoenicis][spike][ev=impl043_open_fail]");
      return INIT_FAILED;
     }

   JournalEvent ev;
   ev.timestamp_seconds      = TimeCurrent();
   ev.timestamp_microseconds = GetMicrosecondCount();
   ev.event_type             = "halt";
   ev.slot_id                = "system";
   ev.magic                  = 0;
   ev.ticket_id              = 0;
   ev.symbol                 = "EURUSD";
   ev.order_type             = "";
   ev.lot                    = 0.0;
   ev.price                  = 0.0;
   ev.sl                     = 0.0;
   ev.tp                     = 0.0;
   ev.comment                = "";
   ev.signal_context         = "spike=impl043";
   ev.triggering_function    = "Spike_TradeJournal";
   ev.parent_ticket_id       = 0;
   ev.halt_reason            = "spike_test";
   ev.pending_age_bars       = 0;

   for(int i = 0; i < 200; i++)
     {
      ev.signal_context = StringFormat("spike=impl043 i=%d", i);
      journal.WriteEvent(ev);
     }

   int consecutive = 0;
   bool should_halt = journal.ShouldHaltSustained(consecutive);
   if(should_halt || consecutive != 0)
     {
      Print("[Phoenicis][spike][ev=impl043_halt_false_positive][consecutive=", consecutive, "]");
      journal.Close();
      return INIT_FAILED;
     }
   Print("[Phoenicis][spike][ev=impl043_halt_check_ok][consecutive=0]");

   journal.Close();

   if((bool)MQLInfoInteger(MQL_TESTER))
     {
      Print("[Phoenicis][spike][ev=impl043_complete][mode=tester][writes=200]");
      return INIT_SUCCEEDED;
     }

   string live_path = "PhoenicisNex/journal/live/journal-" +
                      StringSubstr(TimeToString(TimeCurrent(), TIME_DATE), 0, 4) +
                      StringSubstr(TimeToString(TimeCurrent(), TIME_DATE), 5, 2) + ".jsonl";
   string content = ReadFileContent(live_path);
   if(StringFind(content, "\"event_type\":\"halt\"") < 0)
     {
      Print("[Phoenicis][spike][ev=impl043_write_fail][path=" + live_path + "]");
      return INIT_FAILED;
     }

   Print("[Phoenicis][spike][ev=impl043_complete][mode=live][path=" + live_path + "]");
   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) { Print("[Phoenicis][spike][ev=impl043_deinit][reason=", reason, "]"); }
