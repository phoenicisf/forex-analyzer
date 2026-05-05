//+------------------------------------------------------------------+
//|  Spike_AtomicWrite.mq5 — IMPL-046 atomic-write spike (E1 risk gate)
//|  Verifies MT5 sandbox FileMove(...,FILE_REWRITE) atomic guarantee
//|  per ADR-007 Option A. Standalone — no project #include.
//|
//|  Phase 1: TotalWrites normal atomic writes (default 1000)
//|           — each write parses cleanly + counter equals expected
//|  Phase 2: KillTrials simulated mid-write crashes (default 100)
//|           — anchor write succeeds, then partial .tmp write WITHOUT
//|             rename simulates the ADR-007 step 1-2 crash window
//|             (state.json must be untouched, anchor still parses)
//|
//|  Verdict logged at end:
//|    OPTION_A_LOCKED — both phases 0 corruption → ADR-007 §Spike Result lock
//|    OPTION_B_ACTIVATE — any failure → escalate to 3-file double-buffered swap
//+------------------------------------------------------------------+
#property strict
#property copyright "PhoenicisNex"
#property version   "1.00"

input int    InpTotalWrites = 1000;   // Phase 1 atomic write iterations
input int    InpKillTrials  = 100;    // Phase 2 simulated mid-write crashes
input string InpStateFile   = "PhoenicisNex/spike/state.json";
input string InpTmpFile     = "PhoenicisNex/spike/state.json.tmp";

//+------------------------------------------------------------------+
//| Atomic write: write to .tmp → flush → close → FileMove(.tmp→dst) |
//| Mirrors ADR-007 Option A contract exactly.                       |
//+------------------------------------------------------------------+
bool WriteAtomic(string path, string tmppath, string content)
{
   int h = FileOpen(tmppath, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h == INVALID_HANDLE)
      return(false);
   FileWriteString(h, content);
   FileFlush(h);
   FileClose(h);
   // FILE_REWRITE = overwrite dst if exists; both args use FILE_COMMON-relative
   // sandbox (we pass 0 for src common-flag = local sandbox same as dst).
   if(!FileMove(tmppath, 0, path, FILE_REWRITE))
     {
      FileDelete(tmppath);
      return(false);
     }
   return(true);
}

//+------------------------------------------------------------------+
//| Parse state.json — extract counter field.                        |
//| Returns false if file missing, unreadable, or counter not found. |
//+------------------------------------------------------------------+
bool ParseState(string path, int &counter_out)
{
   counter_out = -1;
   if(!FileIsExist(path))
      return(false);
   int h = FileOpen(path, FILE_READ|FILE_TXT|FILE_ANSI);
   if(h == INVALID_HANDLE)
      return(false);
   string content = "";
   while(!FileIsEnding(h))
      content += FileReadString(h);
   FileClose(h);
   int p = StringFind(content, "\"counter\":");
   if(p < 0)
      return(false);
   string rest = StringSubstr(content, p + 10);
   counter_out = (int)StringToInteger(rest);
   // sanity — file must end with "}" (closing brace) to be considered intact
   StringTrimRight(content);
   int last = StringLen(content) - 1;
   if(last < 0 || StringGetCharacter(content, last) != '}')
      return(false);
   return(true);
}

//+------------------------------------------------------------------+
//| Build a deterministic-ish JSON payload.                          |
//+------------------------------------------------------------------+
string MakePayload(int counter)
{
   string ts = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string hash = "";
   string hex = "0123456789abcdef";
   for(int i = 0; i < 32; i++)
     {
      uchar c = (uchar)StringGetCharacter(hex, MathRand() % 16);
      hash += CharToString(c);
     }
   return(StringFormat(
      "{\"counter\":%d,\"hash\":\"%s\",\"timestamp\":\"%s\",\"payload_size_bytes\":256,\"schema_version\":1}",
      counter, hash, ts));
}

//+------------------------------------------------------------------+
//| OnInit — execute spike, log verdict, request shutdown.           |
//+------------------------------------------------------------------+
int OnInit()
{
   PrintFormat("[spike][ev=spike_start][total_writes=%d][kill_trials=%d]",
               InpTotalWrites, InpKillTrials);

   //--- fix-round-13 § 13.3 — Cleanup is gated to the spike's known sandbox
   //    prefix ("PhoenicisNex/spike/"). The original IMPL-046 contract owns
   //    that prefix exclusively. When IMPL-064's atomic_write_kill.ini
   //    redirects InpStateFile to the production state path
   //    ("PhoenicisNex/state/state.json", owned by StatePersistence.mqh),
   //    an unconditional FileDelete here would race the harness's inspect
   //    semantics — and if a future fix to Finding 13.1 ever bridges the
   //    Tester sandbox to the live-terminal sandbox (e.g. via FILE_COMMON),
   //    the unconditional delete would silently destroy live operator state.
   //    Inspect-path cleanup belongs to the harness owner (atomic_write_kill_100.ps1
   //    line ~205, ~252-254), not to the spike's OnInit.
   //
   //    Path classification is logged unconditionally so an operator can audit
   //    the safety property in real time via grep on '[spike][ev=path_guard]'.
   //    R16 16.6 — directory-boundary check: the trailing "/" in the prefix
   //    string forces an exact directory boundary, so neighbours like
   //    "PhoenicisNex/spike-archive/" or "PhoenicisNex/state-backup/" cannot
   //    false-positive (StringFind would not match at position 0). We additionally
   //    require the path to end with "/state.json" (the only filename the harness
   //    is allowed to mutate) — defence-in-depth against accidental refactor.
   bool ends_with_state_json = (StringFind(InpStateFile, "/state.json") ==
                                (int)StringLen(InpStateFile) - 11);
   string path_class = "unknown";
   if(ends_with_state_json)
     {
      if(StringFind(InpStateFile, "PhoenicisNex/spike/") == 0)
         path_class = "sandbox";
      else if(StringFind(InpStateFile, "PhoenicisNex/state/") == 0)
         path_class = "production";
     }
   PrintFormat("[spike][ev=path_guard][class=%s][state=%s][tmp=%s]",
               path_class, InpStateFile, InpTmpFile);

   if(path_class == "sandbox")
     {
      // Spike-owned sandbox — cleanup is safe.
      FileDelete(InpStateFile);
      FileDelete(InpTmpFile);
     }
   else
     {
      // Production or unknown — defer to harness for cleanup. See
      //   atomic_write_kill_100.ps1 (per-trial Remove-Item on $StateTmp).
      PrintFormat("[spike][ev=cleanup_skipped][reason=non-spike-path][class=%s]",
                  path_class);
     }

   //--------------------------------------------------------------
   // PHASE 1 — TotalWrites normal atomic writes
   //--------------------------------------------------------------
   int phase1_write_fails = 0;
   int phase1_parse_fails = 0;
   for(int i = 1; i <= InpTotalWrites; i++)
     {
      string content = MakePayload(i);
      if(!WriteAtomic(InpStateFile, InpTmpFile, content))
        {
         phase1_write_fails++;
         if(phase1_write_fails <= 5)
            PrintFormat("[spike][ev=phase1_write_fail][i=%d][err=%d]", i, GetLastError());
         continue;
        }
      int parsed = -1;
      if(!ParseState(InpStateFile, parsed) || parsed != i)
        {
         phase1_parse_fails++;
         if(phase1_parse_fails <= 5)
            PrintFormat("[spike][ev=phase1_parse_fail][i=%d][parsed=%d]", i, parsed);
        }
     }
   PrintFormat("[spike][ev=phase1_done][writes=%d][write_fails=%d][parse_fails=%d]",
               InpTotalWrites, phase1_write_fails, phase1_parse_fails);

   //--------------------------------------------------------------
   // PHASE 2 — KillTrials simulated mid-write crashes
   // Each trial:
   //   (a) Anchor: full atomic write of known counter (10000 + t)
   //   (b) Crash sim: open .tmp, write partial truncated JSON, close
   //       WITHOUT FileMove. This is exactly the ADR-007 §Atomicity
   //       proof step 1-2 window: state.json untouched, .tmp orphaned.
   //   (c) Verify: parse state.json — must still equal anchor counter.
   //   (d) Cleanup orphan .tmp (simulates next-boot OnInit recovery
   //       per ADR-007 §OnInit recovery contract).
   //--------------------------------------------------------------
   int phase2_state_corrupt = 0;
   int phase2_anchor_fails  = 0;
   for(int t = 1; t <= InpKillTrials; t++)
     {
      int anchor_counter = 10000 + t;
      string anchor_payload = MakePayload(anchor_counter);
      if(!WriteAtomic(InpStateFile, InpTmpFile, anchor_payload))
        {
         phase2_anchor_fails++;
         continue;
        }

      // Simulated crash mid-.tmp-write — do NOT rename
      int h = FileOpen(InpTmpFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
      if(h != INVALID_HANDLE)
        {
         // Truncated mid-string — never closes the JSON brace
         FileWriteString(h, "{\"counter\":99999,\"hash\":\"PARTIAL");
         FileFlush(h);
         FileClose(h);
        }

      int parsed = -1;
      if(!ParseState(InpStateFile, parsed) || parsed != anchor_counter)
        {
         phase2_state_corrupt++;
         if(phase2_state_corrupt <= 5)
            PrintFormat("[spike][ev=phase2_state_corrupt][t=%d][parsed=%d][expected=%d]",
                        t, parsed, anchor_counter);
        }

      // Recovery: cleanup orphan .tmp (matches ADR-007 OnInit contract)
      FileDelete(InpTmpFile);
     }
   PrintFormat("[spike][ev=phase2_done][kill_trials=%d][anchor_fails=%d][state_corrupt=%d]",
               InpKillTrials, phase2_anchor_fails, phase2_state_corrupt);

   //--------------------------------------------------------------
   // VERDICT
   //--------------------------------------------------------------
   bool ok = (phase1_write_fails == 0 &&
              phase1_parse_fails == 0 &&
              phase2_anchor_fails == 0 &&
              phase2_state_corrupt == 0);
   string verdict = ok ? "OPTION_A_LOCKED" : "OPTION_B_ACTIVATE";
   PrintFormat("[spike][ev=spike_complete][p1_writes=%d][p1_parse_fails=%d][p2_kills=%d][p2_state_corrupt=%d][verdict=%s]",
               InpTotalWrites, phase1_parse_fails, InpKillTrials, phase2_state_corrupt, verdict);

   // fix-round-13 § 13.3 — Cleanup live artifacts only if we own the prefix.
   //   Same guard as OnInit start; see [ev=path_guard] above.
   if(StringFind(InpStateFile, "PhoenicisNex/spike/") == 0)
     {
      FileDelete(InpStateFile);
      FileDelete(InpTmpFile);
     }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnTick — no-op; Strategy Tester just runs through the bar window |
//| and shuts down via ShutdownTerminal=1 in the .ini.               |
//+------------------------------------------------------------------+
void OnTick() { }

//+------------------------------------------------------------------+
//| OnDeinit — emit final shutdown line.                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("[spike][ev=spike_deinit][reason=%d]", reason);
}

//+------------------------------------------------------------------+
//| OnTester — required for clean Strategy Tester completion.        |
//+------------------------------------------------------------------+
double OnTester() { return(0.0); }
//+------------------------------------------------------------------+
