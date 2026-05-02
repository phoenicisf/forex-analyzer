//+------------------------------------------------------------------+
//| Timestamp.mqh — ms-precision ISO-8601 timestamp formatter         |
//| Layer:  helpers/ — pure utility, no service dependencies          |
//| Source: TD-02 §9.5 lines 2108-2117                                |
//|         ADR-006 (journal schema Z-suffix contract)                |
//|         ADR-011 (Logger timestamp format)                         |
//|         trade-journal-schema.yaml line 36                         |
//+------------------------------------------------------------------+
// INCLUDE GUARD
#ifndef PHOENICISNEX_HELPERS_TIMESTAMP_MQH
#define PHOENICISNEX_HELPERS_TIMESTAMP_MQH

//+------------------------------------------------------------------+
//| FormatTimestampWithMs                                             |
//|                                                                  |
//| Returns an ISO-8601 timestamp string with millisecond precision  |
//| in the form: YYYY-MM-DDTHH:MM:SS.mmmZ                            |
//|                                                                  |
//| Parameters:                                                      |
//|   sec   — datetime (seconds since epoch, from TimeCurrent())     |
//|   micro — microsecond counter (from GetMicrosecondCount())       |
//|                                                                  |
//| Notes:                                                           |
//|   • ms_within_sec = (micro / 1000) % 1000 — extracts the        |
//|     sub-second millisecond component independent of the epoch    |
//|   • "Z" suffix per trade-journal-schema.yaml line 36 + ADR-006   |
//|     sample. Callers that need Experts-log local view (no T, no Z)|
//|     MUST apply StringReplace post-call (see Logger FormatLine).  |
//|   • Free function (not a class) — stateless pure utility.        |
//|   • Owner: IMPL-042 (Logger canonical caller per ADR-011 §Format)|
//|     IMPL-011 (JsonWriter) uses this as caller-responsibility;    |
//|     JsonWriter accepts pre-formatted timestamp strings as input.  |
//+------------------------------------------------------------------+
string FormatTimestampWithMs(datetime sec, ulong micro)
  {
   MqlDateTime dt;
   TimeToStruct(sec, dt);
   ulong ms_within_sec = (micro / 1000) % 1000;
   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02d.%03lluZ",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec,
                       ms_within_sec);
  }

#endif // PHOENICISNEX_HELPERS_TIMESTAMP_MQH
