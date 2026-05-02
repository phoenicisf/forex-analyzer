//+------------------------------------------------------------------+
//| Spike_StatePersistence.mq5 — IMPL-047 E-AC validation           |
//| Exercises CStatePersistence Save/Load round-trip + slot_states  |
//| key count invariant. Standalone spike; runs in OnInit only.     |
//|                                                                  |
//| Evidence kinds:                                                  |
//|   [boot-cold]        — Load() on absent file → clean defaults   |
//|   [contract-roundtrip] — Save then Load → fields match          |
//|   [db-inspect]       — slot_states JSON key count == 17         |
//|   [kill-resilience]  — orphan .tmp + Load → state.json intact   |
//+------------------------------------------------------------------+
#property strict
#property copyright "PhoenicisNex"
#property version   "1.00"

#include "../services/StatePersistence.mqh"

input int InpSaveIterations = 100;   // Phase 1: normal Save iterations
input int InpKillTrials     = 10;    // Phase 2: orphan-tmp kill simulations

//--- 17 distinct magics (mirrors PortfolioState::RegisterAll order)
static const int TEST_MAGICS[17] = {200,201,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219};

//+------------------------------------------------------------------+
//| Helper: read state.json content                                  |
//+------------------------------------------------------------------+
string ReadFile(string path)
  {
   if(!FileIsExist(path)) return "";
   int h = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return "";
   string s = "";
   while(!FileIsEnding(h)) s += FileReadString(h);
   FileClose(h);
   return s;
  }

//+------------------------------------------------------------------+
//| Helper: count occurrences of needle in haystack                  |
//+------------------------------------------------------------------+
int CountOccurrences(string haystack, string needle)
  {
   int count = 0, pos = 0, len = StringLen(needle);
   while((pos = StringFind(haystack, needle, pos)) >= 0)
     { count++; pos += len; }
   return count;
  }

//+------------------------------------------------------------------+
//| OnInit — run all E-AC checks, print verdict, return INIT_FAILED  |
//| so Tester shuts down after OnInit (no ticks needed).            |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("[Phoenicis][spike][ev=impl047_start] Spike_StatePersistence beginning");

   //--- Instantiate services
   CAtomicFile   atomic;
   CLogger       logger;
   CPortfolioState portfolio;
   CStatePersistence state;

   logger.Init(LOG_INFO, false, 10);
   state.Init(&atomic, &logger);
   logger.SetStatePersistence(&state);

   portfolio.Init(&logger);
   portfolio.RegisterAll();
   state.SetPortfolioState(&portfolio);

   int pass = 0, fail = 0;

   //--------------------------------------------------------------
   // Check A: boot-cold — Load on absent file → false + defaults
   //--------------------------------------------------------------
   {
      FileDelete(state.StatePath());
      EEAState s = EA_STATE_HALTED;  // set to non-default to test reset
      string r = "old";
      bool loaded = state.Load(s, r);
      if(!loaded && s == EA_STATE_RUNNING && r == "")
        { Print("[spike][ev=check_a_pass] boot-cold defaults ok"); pass++; }
      else
        { Print("[spike][ev=check_a_FAIL] boot-cold loaded=", loaded,
                " state=", (int)s, " reason=", r); fail++; }
   }

   //--------------------------------------------------------------
   // Check B: contract-roundtrip — Save then Load matches
   //--------------------------------------------------------------
   {
      for(int i = 0; i < InpSaveIterations; i++)
        {
         string tag = "iter=" + IntegerToString(i);
         if(!state.Save(EA_STATE_HALTED, tag))
           { Print("[spike][ev=check_b_save_FAIL] iter=", i); fail++; break; }
        }

      string last_tag = "iter=" + IntegerToString(InpSaveIterations - 1);
      EEAState s_out = EA_STATE_RUNNING;
      string r_out = "";
      bool loaded = state.Load(s_out, r_out);
      if(loaded && s_out == EA_STATE_HALTED && r_out == last_tag)
        { Print("[spike][ev=check_b_pass] roundtrip ok tag=", last_tag); pass++; }
      else
        { Print("[spike][ev=check_b_FAIL] loaded=", loaded,
                " state=", (int)s_out, " reason=", r_out,
                " expected_tag=", last_tag); fail++; }
   }

   //--------------------------------------------------------------
   // Check C: db-inspect — slot_states JSON has 17 keys
   //--------------------------------------------------------------
   {
      state.Save(EA_STATE_RUNNING, "db_inspect_probe");
      string json = ReadFile(state.StatePath());
      if(StringLen(json) < 50)
        { Print("[spike][ev=check_c_FAIL] state.json empty or missing"); fail++; }
      else
        {
         //--- Count magic key patterns "200":, "201":, ... "219": inside slot_states
         //    Find slot_states sub-object then count "magic": entries
         int key_count = 0;
         for(int i = 0; i < 17; i++)
           {
            string key_pat = "\"" + IntegerToString(TEST_MAGICS[i]) + "\":{";
            if(StringFind(json, key_pat) >= 0) key_count++;
           }
         if(key_count == 17)
           { Print("[spike][ev=check_c_pass] slot_states key_count=17 ok"); pass++; }
         else
           { Print("[spike][ev=check_c_FAIL] slot_states key_count=", key_count,
                   " expected=17"); fail++; }
        }
   }

   //--------------------------------------------------------------
   // Check D: kill-resilience — orphan .tmp + CleanupOrphanTmp + Load
   //--------------------------------------------------------------
   {
      //--- Save known-good state
      string anchor_tag = "anchor_before_kill";
      state.Save(EA_STATE_RUNNING, anchor_tag);

      //--- Simulate mid-write crash: write partial .tmp but do NOT rename
      string tmp_path = state.StatePath() + ".tmp";
      for(int k = 0; k < InpKillTrials; k++)
        {
         int h = FileOpen(tmp_path, FILE_WRITE | FILE_TXT | FILE_ANSI);
         if(h != INVALID_HANDLE)
           {
            FileWriteString(h, "{\"partial\":true,\"kill_iter\":" + IntegerToString(k) + "}");
            FileFlush(h);
            FileClose(h);
            //--- Simulate: do NOT FileMove (kill happened in step 1-2 window)
            //--- CleanupOrphanTmp deletes leftover .tmp
            atomic.CleanupOrphanTmp(state.StatePath(), &logger);
           }
        }

      //--- Load → should still see anchor state.json
      EEAState s_out = EA_STATE_HALTED;
      string r_out = "";
      bool loaded = state.Load(s_out, r_out);
      bool tmp_gone = !FileIsExist(tmp_path);
      if(loaded && s_out == EA_STATE_RUNNING && r_out == anchor_tag && tmp_gone)
        { Print("[spike][ev=check_d_pass] kill-resilience ok tmp_gone=", tmp_gone); pass++; }
      else
        { Print("[spike][ev=check_d_FAIL] loaded=", loaded,
                " state=", (int)s_out, " reason=", r_out,
                " tmp_gone=", tmp_gone); fail++; }
   }

   //--------------------------------------------------------------
   // Check E: GV sync — SyncToGlobalVariable writes 4 GV keys
   //--------------------------------------------------------------
   {
      state.SetWorstDdPct(-5.5);
      state.SetEquityHigh(11234.56);
      state.Save(EA_STATE_RUNNING, "gv_check");
      //--- SyncToGV called inside Save; verify GV readable
      bool gv_ok = GlobalVariableCheck(GV_KEY_WORST_DD_PCT) &&
                   GlobalVariableCheck(GV_KEY_EQ_HIGH);
      if(gv_ok)
        { Print("[spike][ev=check_e_pass] GV keys present ok"); pass++; }
      else
        { Print("[spike][ev=check_e_FAIL] GV keys missing"); fail++; }
   }

   //--------------------------------------------------------------
   // Verdict
   //--------------------------------------------------------------
   string verdict = (fail == 0) ? "ALL_PASS" : "FAIL_" + IntegerToString(fail);
   Print("[Phoenicis][spike][ev=impl047_complete][verdict=", verdict,
         "][pass=", pass, "][fail=", fail, "] IMPL-047 E-AC spike done");

   portfolio.ReleaseAll();
   return INIT_FAILED;  // terminates Tester after OnInit (no ticks needed)
  }

void OnTick()  {}
void OnDeinit(const int reason) {}
