//+------------------------------------------------------------------+
//| JsonWriter.mqh — Pure-MQL5 JSON object + JSON-Lines serializer   |
//| Layer:  helpers/ — pure utility, no service dependencies         |
//| Source: TD-02 §4.3 + ADR-006 (JSON-Lines journal) +              |
//|         ADR-007 (atomic state write) + NFR-7.2 (0 ext DLLs)      |
//+------------------------------------------------------------------+
// INCLUDE GUARD
#ifndef PHOENICISNEX_HELPERS_JSONWRITER_MQH
#define PHOENICISNEX_HELPERS_JSONWRITER_MQH

// NFR-7.2: NO #import directives — pure MQL5 only.
// ADR-012: helpers/ must NOT #include services/* — pure utility.

//+------------------------------------------------------------------+
//| CJsonWriter — stateful JSON object builder                        |
//|                                                                  |
//| Usage pattern (per TD-02 §4.3):                                  |
//|   CJsonWriter w;                                                  |
//|   w.Begin();                                                      |
//|   w.WriteString("event_type", "entry");                           |
//|   w.WriteInt("magic", 200);                                       |
//|   w.WriteDouble("lot", 0.1, 2);                                   |
//|   w.WriteBool("is_buy", true);                                    |
//|   w.End();                                                        |
//|   string json = w.ToString();  // → {"event_type":"entry",...}   |
//|                                                                  |
//| JSON-Lines (per ADR-006):                                         |
//|   string jline = CJsonWriter::BuildJsonLine(w.ToString());        |
//|   // → {"event_type":"entry",...}\n                               |
//|                                                                  |
//| String escape contract (§6.C.1, order matters):                  |
//|   1. Backslash  \  → \\                                          |
//|   2. Double quote " → \"                                         |
//|   3. Newline    \n → \\n                                         |
//|   4. Carriage return \r → \\r                                    |
//|   5. Tab        \t → \\t                                         |
//|                                                                  |
//| Timestamp fields: caller provides pre-formatted ISO-8601 string   |
//|   ("YYYY-MM-DDTHH:MM:SS.mmmZ" per trade-journal-schema.yaml)     |
//|   via WriteString/WriteDateTime. helpers/Timestamp.mqh (IMPL-042) |
//|   is the canonical formatter; not included here (§6.D).          |
//+------------------------------------------------------------------+
class CJsonWriter
  {
private:
   string            m_buffer;         // JSON string being built
   bool              m_first_field;    // comma logic: skip comma before first key

   //+----------------------------------------------------------------+
   //| AppendComma — emit "," separator before all fields except first |
   //+----------------------------------------------------------------+
   void              AppendComma()
     {
      if(!m_first_field)
         m_buffer += ",";
      m_first_field = false;
     }

   //+----------------------------------------------------------------+
   //| EscapeString — apply 5-char + control-char escape (§6.C.1)     |
   //| Order is critical: backslash first to avoid double-escaping.   |
   //| RFC 8259 §7: ALL U+0000..U+001F must be escaped (Finding 01.9).|
   //+----------------------------------------------------------------+
   string            EscapeString(string raw) const
     {
      // 1. Backslash must be escaped first (otherwise re-escapes later passes)
      StringReplace(raw, "\\", "\\\\");
      // 2. Double quote
      StringReplace(raw, "\"", "\\\"");
      // 3. Newline
      StringReplace(raw, "\n", "\\n");
      // 4. Carriage return
      StringReplace(raw, "\r", "\\r");
      // 5. Tab
      StringReplace(raw, "\t", "\\t");

      // 6. Remaining control chars 0x00..0x08, 0x0B..0x0C, 0x0E..0x1F
      //    must be \uXXXX escaped (RFC 8259 §7). 0x09/0x0A/0x0D are already
      //    handled above (raw bytes were replaced with their 2-char form;
      //    iteration sees only the literal `\`+`t/n/r` post-replace).
      string out = "";
      int n = StringLen(raw);
      for(int i = 0; i < n; i++)
        {
         ushort ch = StringGetCharacter(raw, i);
         if(ch < 0x20)
            out += StringFormat("\\u%04x", ch);
         else
            out += ShortToString(ch);
        }
      return out;
     }

public:
   //--- Constructor — initialise to empty/reset state
   CJsonWriter() : m_buffer(""), m_first_field(true) {}

   //+----------------------------------------------------------------+
   //| Begin — reset state and emit opening brace "{"                 |
   //+----------------------------------------------------------------+
   void              Begin()
     {
      m_buffer      = "{";
      m_first_field = true;
     }

   //+----------------------------------------------------------------+
   //| End — emit closing brace "}" (does NOT append newline)         |
   //| For JSON-Lines newline use BuildJsonLine(ToString()) after End  |
   //+----------------------------------------------------------------+
   void              End()
     {
      m_buffer += "}";
     }

   //+----------------------------------------------------------------+
   //| WriteString — emit "key":"escaped_value"                       |
   //| Applies 5-char escape per §6.C.1 (backslash \ " \n \r \t).    |
   //+----------------------------------------------------------------+
   void              WriteString(string key, string value)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":\"" + EscapeString(value) + "\"";
     }

   //+----------------------------------------------------------------+
   //| WriteInt — emit "key":integer_value (no quotes)                |
   //| Accepts long to cover int/uint/long/ulong ranges.              |
   //+----------------------------------------------------------------+
   void              WriteInt(string key, long value)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":" + IntegerToString(value);
     }

   //+----------------------------------------------------------------+
   //| WriteLong — alias to WriteInt for semantic clarity              |
   //+----------------------------------------------------------------+
   void              WriteLong(string key, long value)
     {
      WriteInt(key, value);
     }

   //+----------------------------------------------------------------+
   //| WriteDouble — emit "key":value with given decimal precision     |
   //| Uses DoubleToString for clean decimal (no float noise).        |
   //+----------------------------------------------------------------+
   void              WriteDouble(string key, double value, int digits)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":" + DoubleToString(value, digits);
     }

   //+----------------------------------------------------------------+
   //| WriteBool — emit "key":true  or  "key":false  (JSON keyword)   |
   //+----------------------------------------------------------------+
   void              WriteBool(string key, bool value)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":" + (value ? "true" : "false");
     }

   //+----------------------------------------------------------------+
   //| WriteNull — emit "key":null  (JSON null keyword)               |
   //+----------------------------------------------------------------+
   void              WriteNull(string key)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":null";
     }

   //+----------------------------------------------------------------+
   //| WriteRaw — emit "key":<raw_json> verbatim (no escaping)        |
   //| Use for pre-built nested objects or arrays.                    |
   //| Per TD-02 §4.3: caller guarantees raw_json is valid JSON.      |
   //+----------------------------------------------------------------+
   void              WriteRaw(string key, string raw_json)
     {
      AppendComma();
      m_buffer += "\"" + EscapeString(key) + "\":" + raw_json;
     }

   //+----------------------------------------------------------------+
   //| WriteDateTime — emit "key":"<iso_string>"                      |
   //| Preferred: caller passes pre-formatted ISO-8601 string          |
   //|   (e.g. "2026-05-02T14:23:45.123Z" per ADR-006/schema).        |
   //| Epoch fallback: if iso_string is "", synthesize a minimal       |
   //|   ISO-8601 string ("YYYY-MM-DDTHH:MM:SSZ") from epoch_fallback  |
   //|   — schema-compliant string (Finding 01.11). Previous behaviour |
   //|   emitted a bare integer which violates trade-journal-schema.   |
   //| Note: helpers/Timestamp.mqh (IMPL-042 owner) provides           |
   //|   FormatTimestampWithMs(datetime,ulong) as the canonical path.  |
   //+----------------------------------------------------------------+
   void              WriteDateTime(string key, string iso_string, datetime epoch_fallback = 0)
     {
      string s = iso_string;
      if(StringLen(s) == 0)
        {
         // Synthesize minimal ISO-8601 from epoch (no millisecond precision —
         // canonical formatter Timestamp.mqh owns the .mmmZ form per §6.D).
         MqlDateTime dt;
         TimeToStruct(epoch_fallback, dt);
         s = StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
        }
      WriteString(key, s);
     }

   //+----------------------------------------------------------------+
   //| ToString — return accumulated JSON string                       |
   //| Must call End() before ToString() to close the object.         |
   //+----------------------------------------------------------------+
   string            ToString() const { return m_buffer; }

   //+----------------------------------------------------------------+
   //| BuildJsonLine (static) — append JSON-Lines newline terminator   |
   //| Per ADR-006: JSON-Lines format = 1 JSON object per line (\n).  |
   //| Usage: string line = CJsonWriter::BuildJsonLine(w.ToString());  |
   //+----------------------------------------------------------------+
   static string     BuildJsonLine(string content)
     {
      return content + "\n";
     }

   //+----------------------------------------------------------------+
   //| SelfTest — structural smoke for AC coverage (§6.C.2)           |
   //|                                                                 |
   //| Builds a synthetic JournalEvent-like object with all 11 fields  |
   //| required by trade-journal-schema.yaml (per §6.A.1):            |
   //|   timestamp, schema_version, mode, event_type, slot_id, magic, |
   //|   symbol, signal_context, indicator_snapshot (obj), portfolio_  |
   //|   summary (obj), triggering_function                            |
   //|                                                                 |
   //| Also tests:                                                     |
   //|   - All 5-char escape sequences (§6.C.1): \ " \n \r \t         |
   //|   - Round-trip re-parse of key fields via StringFind            |
   //|   - BuildJsonLine newline suffix                                |
   //|   - WriteBool / WriteNull / WriteRaw / WriteDouble / WriteInt   |
   //|                                                                 |
   //| NOTE on E-AC [contract-roundtrip]:                              |
   //|   Full round-trip (serialize → write .jsonl → jq . parse)      |
   //|   is deferred to orchestrator/journal-write runtime (IMPL-043+) |
   //|   and runtime jq validation at G4 gate (IMPL-018+).            |
   //|   This selftest satisfies the structural portion via StringFind |
   //|   re-parse within MQL5 — sufficient for header-only phase.     |
   //|                                                                 |
   //| NOTE on FormatTimestampWithMs:                                  |
   //|   helpers/Timestamp.mqh does not exist yet (IMPL-042 owner per  |
   //|   §6.D). SelfTest uses a literal ISO-8601 stub string.         |
   //|                                                                 |
   //| Emits:                                                          |
   //|   [Phoenicis][slot=system][ev=json_writer_selftest_pass]        |
   //|   or [ev=json_writer_selftest_fail][msg=...]                    |
   //+----------------------------------------------------------------+
   static bool       SelfTest()
     {
      bool all_pass = true;
      string fail_msg = "";

      //--- Build a synthetic trade-journal JournalEvent object -------
      // Stub ISO-8601 timestamp (Timestamp.mqh owner = IMPL-042; §6.D)
      string stub_ts = "2026-05-02T14:23:45.123Z";

      // Nested objects as pre-built raw JSON strings (WriteRaw)
      string indicator_snap =
         "{\"ema_fast\":1.08520,\"ema_slow\":1.08450,\"rsi\":54.2,\"atr\":0.00120}";
      string portfolio_sum  =
         "{\"open_trades\":2,\"total_pnl\":125.50,\"dd_pct\":1.23}";

      // Test string with all 5 escape chars (§6.C.1 contract)
      string escape_test = "a\\b\"c\nd\re\tf";
      string expected_escaped = "a\\\\b\\\"c\\nd\\re\\tf";

      CJsonWriter w;
      w.Begin();
      // Field 1: timestamp (Z-suffix per schema; string via WriteString)
      w.WriteString("timestamp", stub_ts);
      // Field 2: schema_version (int)
      w.WriteInt("schema_version", 1);
      // Field 3: mode
      w.WriteString("mode", "tester");
      // Field 4: event_type
      w.WriteString("event_type", "entry");
      // Field 5: slot_id
      w.WriteString("slot_id", "C");
      // Field 6: magic (int)
      w.WriteInt("magic", 200);
      // Field 7: symbol
      w.WriteString("symbol", "EURUSD");
      // Field 8: signal_context — contains all 5 escape chars
      w.WriteString("signal_context", escape_test);
      // Field 9: indicator_snapshot (nested object via WriteRaw)
      w.WriteRaw("indicator_snapshot", indicator_snap);
      // Field 10: portfolio_summary (nested object via WriteRaw)
      w.WriteRaw("portfolio_summary", portfolio_sum);
      // Field 11: triggering_function
      w.WriteString("triggering_function", "BusinessLogic_C");
      // Extra fields testing remaining primitives:
      w.WriteDouble("lot_size", 0.10, 2);
      w.WriteBool("is_buy", true);
      w.WriteNull("parent_ticket_id");
      w.WriteLong("ticket_id", 123456789L);
      w.WriteDateTime("entry_time", stub_ts);
      w.WriteDateTime("stale_fallback", "", (datetime)1746187425);  // epoch fallback path
      w.End();

      string json = w.ToString();

      //--- Structural re-parse assertions (via StringFind) -----------

      // 1. Verify timestamp field present and Z-suffix maintained
      string ts_field  = "\"timestamp\":\"2026-05-02T14:23:45.123Z\"";
      if(StringFind(json, ts_field) < 0)
        {
         all_pass = false;
         fail_msg = "timestamp field not found or malformed";
        }

      // 2. Verify schema_version integer (no quotes)
      if(all_pass && StringFind(json, "\"schema_version\":1") < 0)
        {
         all_pass = false;
         fail_msg = "schema_version not found as integer";
        }

      // 3. Verify event_type string
      if(all_pass && StringFind(json, "\"event_type\":\"entry\"") < 0)
        {
         all_pass = false;
         fail_msg = "event_type field not found";
        }

      // 4. Verify escape contract: signal_context must contain the 5-char-escaped form
      if(all_pass && StringFind(json, "\"signal_context\":\"" + expected_escaped + "\"") < 0)
        {
         all_pass = false;
         fail_msg = "escape contract failed for signal_context; got: " + json;
        }

      // 5. Verify nested object written raw (no double-quoting of braces)
      if(all_pass && StringFind(json, "\"indicator_snapshot\":{\"ema_fast\":") < 0)
        {
         all_pass = false;
         fail_msg = "indicator_snapshot nested object malformed";
        }

      // 6. Verify bool emitted as bare keyword (not quoted)
      if(all_pass && StringFind(json, "\"is_buy\":true") < 0)
        {
         all_pass = false;
         fail_msg = "is_buy bool not found as bare keyword";
        }

      // 7. Verify null emitted as bare keyword
      if(all_pass && StringFind(json, "\"parent_ticket_id\":null") < 0)
        {
         all_pass = false;
         fail_msg = "parent_ticket_id null not found";
        }

      // 8. Verify WriteDouble with 2 decimal places
      if(all_pass && StringFind(json, "\"lot_size\":0.10") < 0)
        {
         all_pass = false;
         fail_msg = "lot_size double not found";
        }

      // 9. Verify WriteLong via ticket_id
      if(all_pass && StringFind(json, "\"ticket_id\":123456789") < 0)
        {
         all_pass = false;
         fail_msg = "ticket_id long not found";
        }

      // 10. Verify WriteDateTime ISO path re-uses WriteString
      if(all_pass && StringFind(json, "\"entry_time\":\"2026-05-02T14:23:45.123Z\"") < 0)
        {
         all_pass = false;
         fail_msg = "entry_time WriteDateTime ISO path not found";
        }

      // 11. Verify WriteDateTime epoch fallback emits synthesized ISO-8601
      //     string (Finding 01.11) — recompute expected from same epoch.
      MqlDateTime dt_exp;
      TimeToStruct((datetime)1746187425, dt_exp);
      string expected_fallback = StringFormat(
            "\"stale_fallback\":\"%04d-%02d-%02dT%02d:%02d:%02dZ\"",
            dt_exp.year, dt_exp.mon, dt_exp.day,
            dt_exp.hour, dt_exp.min, dt_exp.sec);
      if(all_pass && StringFind(json, expected_fallback) < 0)
        {
         all_pass = false;
         fail_msg = "stale_fallback WriteDateTime ISO synth not found; expected="
                    + expected_fallback;
        }

      // 13. Verify control-char escape (Finding 01.9): U+0001 → ""
      if(all_pass)
        {
         CJsonWriter wctl;
         wctl.Begin();
         string ctl_in = "x" + ShortToString((ushort)0x01) + "y";
         wctl.WriteString("ctl", ctl_in);
         wctl.End();
         if(StringFind(wctl.ToString(), "\"ctl\":\"x\\u0001y\"") < 0)
           {
            all_pass = false;
            fail_msg = "control-char escape failed; got: " + wctl.ToString();
           }
        }

      // 14. Verify key escape (Finding 01.10): key with quote/backslash escapes
      if(all_pass)
        {
         CJsonWriter wk;
         wk.Begin();
         wk.WriteString("a\"b\\c", "v");
         wk.End();
         if(StringFind(wk.ToString(), "\"a\\\"b\\\\c\":\"v\"") < 0)
           {
            all_pass = false;
            fail_msg = "key escape failed; got: " + wk.ToString();
           }
        }

      // 12. Verify BuildJsonLine appends exactly one newline
      string jline = CJsonWriter::BuildJsonLine(json);
      int jline_len = StringLen(jline);
      int json_len  = StringLen(json);
      if(all_pass && jline_len != json_len + 1)
        {
         all_pass = false;
         fail_msg = "BuildJsonLine did not append exactly 1 newline char";
        }
      if(all_pass && StringGetCharacter(jline, jline_len - 1) != '\n')
        {
         all_pass = false;
         fail_msg = "BuildJsonLine last char is not newline";
        }

      //--- Emit result -----------------------------------------------
      if(all_pass)
        {
         Print("[Phoenicis][slot=system][ev=json_writer_selftest_pass]");
        }
      else
        {
         Print("[Phoenicis][slot=system][ev=json_writer_selftest_fail][msg=" + fail_msg + "]");
        }

      return all_pass;
     }

  }; // end class CJsonWriter

#endif // PHOENICISNEX_HELPERS_JSONWRITER_MQH
