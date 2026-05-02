//+------------------------------------------------------------------+
//| CommentParser.mqh — Shared-magic comment tag utility            |
//| Purpose: Build + parse MT5 order comment field for per-slot      |
//|          disambiguation (BR-1.2 longest-prefix match)            |
//| Layer:   helpers/ — pure utility, no service dependencies        |
//| Source:  TD-02 §4.2 + BR-1.2 + ADR-012                          |
//+------------------------------------------------------------------+
// INCLUDE GUARD
#ifndef PHOENICISNEX_HELPERS_COMMENTPARSER_MQH
#define PHOENICISNEX_HELPERS_COMMENTPARSER_MQH

//+------------------------------------------------------------------+
//| 21 Active Slot IDs (Phase 1) — shared-magic pairs noted          |
//|                                                                  |
//|  Unique-magic slots (14):                                        |
//|    C (magic 200 — shares with D), F, J, H, K, G, GO, M, Q, R,  |
//|    I, P, T, S                                                    |
//|                                                                  |
//|  Shared-magic disambiguation pairs (4 pairs, 8 slots):          |
//|    C / D  (magic 200, MAGIC_CD) — D is force-pending wrapper of C|
//|    G / G2 (magic 208, MAGIC_G ) — G2 prefix MUST be tested before G|
//|    B / BI (magic 214, MAGIC_B ) — BI prefix MUST be tested before B|
//|    L / LX (magic 211, MAGIC_L ) — LX prefix MUST be tested before L|
//|                                                                  |
//|  Canonical magic source: domain/EnumTypes.mqh — do NOT restate;  |
//|  this header documents only the prefix-disambiguation contract.  |
//|                                                                  |
//| BR-1.2 Disambiguation Rule: longest-prefix match                 |
//|   ExtractSlotPrefix looks for "," delimiter and returns the      |
//|   substring before it verbatim — since orders carry the FULL     |
//|   prefix ("G2,", "BI,", "LX,", "D,"), there is NO ambiguity:    |
//|   the literal text before "," IS the canonical slot id.          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Self-Test Fixture Table (all 10 cases)                           |
//|                                                                  |
//| Input comment              | Expected prefix | Note             |
//| -------------------------- | --------------- | ---------------- |
//| "G2,reason=peak_inverse"   | "G2"            | shared-magic G2  |
//| "G,reason=force_high"      | "G"             | unique under G2  |
//| "BI,reason=parent_b"       | "BI"            | shared-magic BI  |
//| "B,reason=standard"        | "B"             | unique under BI  |
//| "LX,reason=tp_extension"   | "LX"            | shared-magic LX  |
//| "L,reason=basic"           | "L"             | unique under LX  |
//| "D,reason=force_pending"   | "D"             | shared-magic D   |
//| "C,reason=cd_pool"         | "C"             | unique under D   |
//| ""                         | ""              | empty → warn     |
//| "unknown"                  | ""              | no comma → warn  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CCommentParser — stateless, no Init() (helpers convention)       |
//|                                                                  |
//| Public API:                                                       |
//|   string Build(string slot_id, string body) const                |
//|   string ExtractSlotPrefix(string comment) const                 |
//|   int    FilterTicketsByPrefix(const ulong &in[], string prefix, |
//|                                ulong &out[]) const               |
//|   static bool SelfTest()                                         |
//+------------------------------------------------------------------+
class CCommentParser
  {
public:
   //--- Constructor (stateless — no Init needed)
   CCommentParser() {}

   //+----------------------------------------------------------------+
   //| Build — construct order comment for outgoing MT5 order         |
   //| Returns: "<slot_id>,<body>"  e.g. "G2,reason=peak_inverse"    |
   //+----------------------------------------------------------------+
   string            Build(string slot_id, string body) const
     {
      return slot_id + "," + body;
     }

   //+----------------------------------------------------------------+
   //| ExtractSlotPrefix — parse slot id from order comment           |
   //| Algorithm: find first "," → everything before it = prefix      |
   //|   If no "," found  → return "" + emit warn Print               |
   //|   If prefix empty or >4 chars or not alphanumeric → "" + warn  |
   //| BR-1.2: full prefix is embedded literally so there is no       |
   //|   ambiguity; no hardcoded list needed.                         |
   //+----------------------------------------------------------------+
   string            ExtractSlotPrefix(string comment) const
     {
      if(StringLen(comment) == 0)
        {
         Print("[Phoenicis][slot=system][ev=comment_parser_unrecognized][comment=]");
         return "";
        }

      int comma_pos = StringFind(comment, ",");
      if(comma_pos <= 0)
        {
         // No comma found or comma is first char — unrecognized
         Print("[Phoenicis][slot=system][ev=comment_parser_unrecognized][comment=" + comment + "]");
         return "";
        }

      string prefix = StringSubstr(comment, 0, comma_pos);

      // Validate: non-empty, ≤4 chars, alphanumeric only
      int prefix_len = StringLen(prefix);
      if(prefix_len == 0 || prefix_len > 4)
        {
         Print("[Phoenicis][slot=system][ev=comment_parser_unrecognized][comment=" + comment + "]");
         return "";
        }

      // Check alphanumeric (A-Z, a-z, 0-9 only)
      for(int i = 0; i < prefix_len; i++)
        {
         ushort ch = StringGetCharacter(prefix, i);
         bool is_upper = (ch >= 'A' && ch <= 'Z');
         bool is_lower = (ch >= 'a' && ch <= 'z');
         bool is_digit = (ch >= '0' && ch <= '9');
         if(!is_upper && !is_lower && !is_digit)
           {
            Print("[Phoenicis][slot=system][ev=comment_parser_unrecognized][comment=" + comment + "]");
            return "";
           }
        }

      return prefix;
     }

   //+----------------------------------------------------------------+
   //| FilterTicketsByPrefix — select tickets whose comment prefix     |
   //|   matches slot_prefix exactly.                                  |
   //| Iterates ticket_ids_in[], PositionSelectByTicket + read         |
   //|   POSITION_COMMENT, delegates to ExtractSlotPrefix().          |
   //| Returns: count appended to ticket_ids_out[].                   |
   //| Note: uses MT5 native position API — acceptable for stateless   |
   //|   helper per TD-02 §4.2 contract.                              |
   //+----------------------------------------------------------------+
   int               FilterTicketsByPrefix(const ulong &ticket_ids_in[],
                                           string slot_prefix,
                                           ulong &ticket_ids_out[]) const
     {
      int in_count    = ArraySize(ticket_ids_in);
      int out_start   = ArraySize(ticket_ids_out);  // preserve existing entries
      int appended    = 0;

      for(int i = 0; i < in_count; i++)
        {
         ulong ticket = ticket_ids_in[i];
         if(!PositionSelectByTicket(ticket))
            continue;

         string comment  = PositionGetString(POSITION_COMMENT);
         string extracted = ExtractSlotPrefix(comment);

         if(extracted == slot_prefix)
           {
            // Grow output array by 1 and store ticket
            ArrayResize(ticket_ids_out, out_start + appended + 1);
            ticket_ids_out[out_start + appended] = ticket;
            appended++;
           }
        }

      return appended;
     }

   //+----------------------------------------------------------------+
   //| SelfTest — hardcoded fixture verification (10 cases)           |
   //|   Called from OnInit when ENABLE_SELFTEST input flag = on       |
   //|   (wired by a later task).                                     |
   //| Emits: [Phoenicis][slot=system][ev=comment_parser_self_test]   |
   //|        [result=pass] or [result=fail]                          |
   //+----------------------------------------------------------------+
   static bool       SelfTest()
     {
      CCommentParser parser;
      bool all_pass = true;

      // --- Helper lambda-style check via inline struct ---
      // MQL5 has no lambdas; we use a local array of test cases.
      // Each case: {input, expected_prefix}

      string inputs[]   = {"G2,reason=peak_inverse",
                           "G,reason=force_high",
                           "BI,reason=parent_b",
                           "B,reason=standard",
                           "LX,reason=tp_extension",
                           "L,reason=basic",
                           "D,reason=force_pending",
                           "C,reason=cd_pool",
                           "",
                           "unknown"
                          };
      string expected[] = {"G2",
                           "G",
                           "BI",
                           "B",
                           "LX",
                           "L",
                           "D",
                           "C",
                           "",
                           ""
                          };

      int n = ArraySize(inputs);
      for(int i = 0; i < n; i++)
        {
         string got = parser.ExtractSlotPrefix(inputs[i]);
         if(got != expected[i])
           {
            Print("[Phoenicis][slot=system][ev=comment_parser_self_test][result=fail]"
                  "[case=" + IntegerToString(i) + "]"
                  "[input=" + inputs[i] + "]"
                  "[expected=" + expected[i] + "]"
                  "[got=" + got + "]");
            all_pass = false;
           }
        }

      // Also verify Build() for one representative case
      string built = parser.Build("G2", "reason=peak_inverse");
      if(built != "G2,reason=peak_inverse")
        {
         Print("[Phoenicis][slot=system][ev=comment_parser_self_test][result=fail]"
               "[case=build][got=" + built + "]");
         all_pass = false;
        }

      if(all_pass)
         Print("[Phoenicis][slot=system][ev=comment_parser_self_test][result=pass]");

      return all_pass;
     }

  }; // end class CCommentParser

#endif // PHOENICISNEX_HELPERS_COMMENTPARSER_MQH
