//+------------------------------------------------------------------+
//| IndicatorService.mqh — centralized indicator handle owner + cache |
//| Layer:   services/ — injected into MarketContextBuilder via ctor  |
//| Source:  ADR-003 (centralized indicator service decision)         |
//|          TD-02 §5.1 lines 469-510 (class skeleton + API contract) |
//|          FR-7.6 (INVALID_HANDLE fail-fast on OnInit)              |
//|          NFR-3.2 (validate ~25 handles 100%; INIT_FAILED on any)  |
//|          FR-8.1 (300-bar scan cache; invalidate on new H4 bar)    |
//|          ADR-012 (5-layer include discipline: services ↛ slots)   |
//|                                                                   |
//| Key contracts:                                                    |
//|  • CreateHandles() ≥ 24 handles; INIT_FAILED on first invalid     |
//|  • AnyHandleInvalid() runtime fail-fast check                     |
//|  • Refresh() invalidates scan cache on new H4 bar (FR-8.1)       |
//|  • CachedScan() 10-entry FIFO scan cache (insertion-order evict) |
//|  • ReleaseHandles() OnDeinit cleanup                              |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH
#define PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH

#include "Logger.mqh"        // CLogger (same services/ layer — include guard prevents recursion)

//+------------------------------------------------------------------+
//| ScanFnType — function pointer for CachedScan                      |
//| MQL5 function pointer typedef (per TD-02 §5.1 CachedScan note)   |
//+------------------------------------------------------------------+
typedef double (*ScanFnType)(int handle, int depth);

//+------------------------------------------------------------------+
//| CIndicatorService                                                |
//|                                                                  |
//| Handle index constants (IDX_*) encode the layout of m_handles[]:|
//|   Indices 0..24 populated in CreateHandles(); remaining slots    |
//|   in the 40-element array are unused (m_handles oversize for     |
//|   future extension per TD-02 §5.1 comment).                     |
//|                                                                  |
//| ADR-003 handle inventory (≥24 target):                           |
//|   Ichimoku  H4, D1                = 2  (IDX 0, 1)               |
//|   Force     H4                    = 1  (IDX 2)                   |
//|   ADX       H4, D1                = 2  (IDX 3, 4)               |
//|   WPR       H4, D1, M15           = 3  (IDX 5, 6, 7)            |
//|   Bollinger H4                    = 1  (IDX 8)                   |
//|   DeMarker  H4, M15               = 2  (IDX 9, 10)              |
//|   Stochastic M10, H4, M15         = 3  (IDX 11, 12, 13)         |
//|   MACD      M10, D1               = 2  (IDX 14, 15)             |
//|   ZigZag    H4, M5                = 2  (IDX 16, 17)             |
//|   MA_Fast   H4                    = 1  (IDX 18)                  |
//|   MA_Slow   H4                    = 1  (IDX 19)                  |
//|   RSI       H4, D1                = 2  (IDX 20, 21)              |
//|   ATR       H4                    = 1  (IDX 22)                  |
//|   Momentum  H4                    = 1  (IDX 23)                  |
//|   ──────────────────────────────────────────────                  |
//|   Total created: 24 handles (m_handle_count = 24)               |
//+------------------------------------------------------------------+
class CIndicatorService
  {
private:
   //--- Handle storage (ADR-003 + TD-02 §5.1; oversize 40 for safety)
   int               m_handles[40];
   int               m_handle_count;

   //--- H4 bar tracker for FR-8.1 scan-cache invalidation
   int               m_last_bar_index_h4;

   //--- CachedScan storage (key→value, up to 10 entries — FR-8.1 300-bar scan cache)
   //    Eviction policy: FIFO (insertion-order). Cache hits do NOT refresh
   //    position → frequently-used key may be evicted before rare-but-recent.
   //    True LRU upgrade tracked at IMPL-006-cachedscan (see Finding 01.6).
   string            m_scan_keys[10];
   double            m_scan_values[10];
   int               m_scan_count;

   //--- Logger pointer (constructor-injected per ADR-002 + ea.md DI rule)
   CLogger          *m_logger;

   //--- Symbolic handle index constants (per TD-02 §5.1 note on IDX_* convention)
   //    MarketContextBuilder reads via GetHandle(IDX_*) for named access
   static const int  IDX_ICHI_H4     = 0;   // Ichimoku H4  (ADR-003 inventory row 1)
   static const int  IDX_ICHI_D1     = 1;   // Ichimoku D1
   static const int  IDX_FORCE_H4    = 2;   // Force H4     (slots: C,J,G,GO,M,L,B,P)
   static const int  IDX_ADX_H4      = 3;   // ADX H4       (slots: C,K,G)
   static const int  IDX_ADX_D1      = 4;   // ADX D1
   static const int  IDX_WPR_H4      = 5;   // WPR H4       (slots: C,H,L,S)
   static const int  IDX_WPR_D1      = 6;   // WPR D1
   static const int  IDX_WPR_M15     = 7;   // WPR M15
   static const int  IDX_BBANDS_H4   = 8;   // Bollinger H4 (slots: R,B,BR,BI,P,T,S)
   static const int  IDX_DEMARK_H4   = 9;   // DeMarker H4  (slots: LX,M)
   static const int  IDX_DEMARK_M15  = 10;  // DeMarker M15
   static const int  IDX_STOCH_M10   = 11;  // Stochastic M10 (slot C: ForceCutloss)
   static const int  IDX_STOCH_H4    = 12;  // Stochastic H4  (slot L)
   static const int  IDX_STOCH_M15   = 13;  // Stochastic M15 variant (CodeWiki §1.4)
   static const int  IDX_MACD_M10    = 14;  // MACD M10 (slot C: ForceCutloss, COverload)
   static const int  IDX_MACD_D1     = 15;  // MACD D1
   static const int  IDX_ZIGZAG_H4   = 16;  // ZigZag H4    (CodeWiki §1.4)
   static const int  IDX_ZIGZAG_M5   = 17;  // ZigZag M5
   static const int  IDX_MA_FAST_H4  = 18;  // MA Fast H4   (trend filter shared)
   static const int  IDX_MA_SLOW_H4  = 19;  // MA Slow H4
   static const int  IDX_RSI_H4      = 20;  // RSI H4       (filter shared)
   static const int  IDX_RSI_D1      = 21;  // RSI D1
   static const int  IDX_ATR_H4      = 22;  // ATR H4       (pip-distance reference)
   static const int  IDX_MOMENTUM_H4 = 23;  // Momentum H4  (CodeWiki §1.4)

public:
   //--- Constructor — zero-init all members
                     CIndicatorService() : m_handle_count(0),
                                           m_last_bar_index_h4(0),
                                           m_scan_count(0),
                                           m_logger(NULL)
     {
      ArrayInitialize(m_handles, INVALID_HANDLE);
      ArrayInitialize(m_scan_values, 0.0);
      for(int i = 0; i < 10; i++)
         m_scan_keys[i] = "";
     }

   //--- Phase 1 init: store logger pointer + reset state
   //    NO _Symbol access here — only inside CreateHandles/Refresh (ea.md rule)
   void              Init(CLogger *logger);

   //--- OnInit: create + validate all handles (FR-7.6 / NFR-3.2)
   //    Returns false if ANY handle is INVALID_HANDLE → orchestrator → INIT_FAILED
   bool              CreateHandles();

   //--- OnTick step 1: refresh internal buffers via CopyBuffer × N handles
   //    (~200 µs target per TD-02 §5.1 performance note)
   void              Refresh();

   //--- Runtime fail-fast check (FR-7.6 — rare; OnInit should catch all invalid handles)
   bool              AnyHandleInvalid() const;

   //--- 300-bar scan cache (FR-8.1) — invalidated on new H4 bar (m_last_bar_index_h4 change)
   //    key: caller-defined string label; scan_fn: pointer to bar-depth scan function
   double            CachedScan(string key, ScanFnType scan_fn);

   //--- OnDeinit: release all handles (prevents resource leak per MQL5 idiom)
   void              ReleaseHandles();

   //--- Accessors used by MarketContextBuilder (per TD-02 §5.1)
   int               GetHandle(int idx) const { return m_handles[idx]; }

   //--- Handle count used by Orchestrator init_ok log (Claim 02.5)
   int               HandleCount() const { return m_handle_count; }

  }; // end class CIndicatorService

//+------------------------------------------------------------------+
//| Init — Phase 1: store logger pointer; reset operational state     |
//| No _Symbol access here (per ea.md: only CreateHandles/Refresh)   |
//+------------------------------------------------------------------+
void CIndicatorService::Init(CLogger *logger)
  {
   m_logger             = logger;
   m_handle_count       = 0;
   m_last_bar_index_h4  = 0;
   m_scan_count         = 0;
   ArrayInitialize(m_handles, INVALID_HANDLE);
   ArrayInitialize(m_scan_values, 0.0);
   for(int i = 0; i < 10; i++)
      m_scan_keys[i] = "";
  }

//+------------------------------------------------------------------+
//| CreateHandles — populate ≥24 handles + fail-fast on first invalid |
//|                                                                  |
//| Source: ADR-003 handle inventory + TD-02 §5.1                    |
//| NFR-3.2: validate ALL handles 100%; return false on first        |
//|   INVALID_HANDLE → orchestrator calls CleanupPartialInit +        |
//|   returns INIT_FAILED (per TD-02 §7.4.1 + ea.md error handling)  |
//|                                                                  |
//| Parameter tuples: MQL5 documented defaults used where CodeWiki   |
//| §1.4 did not specify exact values (marked TODO IMPL-005-tune).   |
//+------------------------------------------------------------------+
bool CIndicatorService::CreateHandles()
  {
   // Reset before (re-)creation
   ArrayInitialize(m_handles, INVALID_HANDLE);
   m_handle_count = 0;

   //--- Row 1: Ichimoku (H4 + D1) — ADR-003 inventory row 1
   //    Defaults: Tenkan=9, Kijun=26, Senkou=52 (MQL5 standard defaults)
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 1 exact Ichimoku periods
   m_handles[IDX_ICHI_H4]  = iIchimoku(_Symbol, PERIOD_H4, 9, 26, 52);
   m_handles[IDX_ICHI_D1]  = iIchimoku(_Symbol, PERIOD_D1, 9, 26, 52);

   //--- Row 2: Force Index (H4) — ADR-003 inventory row 2
   //    Slots: C, J, G, GO, M, L, B, P
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 2 Force period
   m_handles[IDX_FORCE_H4] = iForce(_Symbol, PERIOD_H4, 13, MODE_SMA, VOLUME_TICK);

   //--- Row 3: ADX (H4 + D1) — ADR-003 inventory row 3
   //    Slots: C, K, G
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 3 ADX period
   m_handles[IDX_ADX_H4]   = iADX(_Symbol, PERIOD_H4, 14);
   m_handles[IDX_ADX_D1]   = iADX(_Symbol, PERIOD_D1, 14);

   //--- Row 4: WPR (H4 + D1 + M15) — ADR-003 inventory row 4
   //    Slots: C, H, L, S
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 4 WPR period
   m_handles[IDX_WPR_H4]   = iWPR(_Symbol, PERIOD_H4, 14);
   m_handles[IDX_WPR_D1]   = iWPR(_Symbol, PERIOD_D1, 14);
   m_handles[IDX_WPR_M15]  = iWPR(_Symbol, PERIOD_M15, 14);

   //--- Row 5: Bollinger Bands (H4) — ADR-003 inventory row 5
   //    Slots: R, B, BR, BI, P, T, S
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 5 BB parameters
   m_handles[IDX_BBANDS_H4] = iBands(_Symbol, PERIOD_H4, 20, 0, 2.0, PRICE_CLOSE);

   //--- Row 6: DeMarker (H4 + M15) — ADR-003 inventory row 6
   //    Slots: LX, M
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 6 DeMarker period
   m_handles[IDX_DEMARK_H4]  = iDeMarker(_Symbol, PERIOD_H4, 14);
   m_handles[IDX_DEMARK_M15] = iDeMarker(_Symbol, PERIOD_M15, 14);

   //--- Row 7: Stochastic (M10 + H4 + M15) — ADR-003 inventory row 7
   //    Slots: C (ForceCutloss), L; M15 = additional variant (CodeWiki §1.4)
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 7 Stochastic %K/%D/slowing
   m_handles[IDX_STOCH_M10] = iStochastic(_Symbol, PERIOD_M10, 5, 3, 3,
                                           MODE_SMA, STO_LOWHIGH);
   m_handles[IDX_STOCH_H4]  = iStochastic(_Symbol, PERIOD_H4, 5, 3, 3,
                                           MODE_SMA, STO_LOWHIGH);
   m_handles[IDX_STOCH_M15] = iStochastic(_Symbol, PERIOD_M15, 5, 3, 3,
                                           MODE_SMA, STO_LOWHIGH);

   //--- Row 8: MACD (M10 + D1) — ADR-003 inventory row 8
   //    Slots: C (ForceCutloss, COverload)
   //    TODO IMPL-005-tune: verify CodeWiki §1.4 row 8 MACD fast/slow/signal
   m_handles[IDX_MACD_M10]  = iMACD(_Symbol, PERIOD_M10, 12, 26, 9, PRICE_CLOSE);
   m_handles[IDX_MACD_D1]   = iMACD(_Symbol, PERIOD_D1,  12, 26, 9, PRICE_CLOSE);

   //--- Additional handles to reach ≥24 total (CodeWiki §1.4 references)

   //--- ZigZag (H4 + M5) — CodeWiki §1.4 ZigZag reference
   //    TODO IMPL-005-tune: verify ZigZag ExtDepth/Deviation/Backstep params
   // MT5 ships the bundled ZigZag at MQL5/Indicators/Examples/ZigZag.ex5
   // (escape backslash for the iCustom path string).
   m_handles[IDX_ZIGZAG_H4] = iCustom(_Symbol, PERIOD_H4, "Examples\\ZigZag", 12, 5, 3);
   m_handles[IDX_ZIGZAG_M5] = iCustom(_Symbol, PERIOD_M5,  "Examples\\ZigZag", 12, 5, 3);

   //--- MA Fast + Slow (H4) — trend filter (CodeWiki §1.4 MA filter)
   //    TODO IMPL-005-tune: verify MA periods and applied price
   m_handles[IDX_MA_FAST_H4] = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_SMA, PRICE_CLOSE);
   m_handles[IDX_MA_SLOW_H4] = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_SMA, PRICE_CLOSE);

   //--- RSI (H4 + D1) — filter (CodeWiki §1.4 RSI reference)
   //    TODO IMPL-005-tune: verify RSI period
   m_handles[IDX_RSI_H4] = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
   m_handles[IDX_RSI_D1] = iRSI(_Symbol, PERIOD_D1, 14, PRICE_CLOSE);

   //--- ATR (H4) — pip-distance reference (CodeWiki §1.4 ATR reference)
   //    TODO IMPL-005-tune: verify ATR period
   m_handles[IDX_ATR_H4] = iATR(_Symbol, PERIOD_H4, 14);

   //--- Momentum (H4) — CodeWiki §1.4 Momentum reference
   //    TODO IMPL-005-tune: verify Momentum period
   m_handles[IDX_MOMENTUM_H4] = iMomentum(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);

   // Total handles created: 24 (IDX 0..23)
   // Now validate all — fail-fast on first INVALID_HANDLE (NFR-3.2 + FR-7.6)
   int total = 24;
   for(int i = 0; i < total; i++)
     {
      if(m_handles[i] == INVALID_HANDLE)
        {
         // No silent failure (security.md + NFR-5.1) — boot-time bypass per ADR-011
         // Reason: throttled Logger.Error suppresses Alert on second invalid handle
         // within same boot or post-CleanupPartialInit re-attach (Finding 01.4).
         m_logger.ErrorBypassThrottle("indicators", "invalid_handle", i,
                        StringFormat("handle[%d] == INVALID_HANDLE after iXxx() call; "
                                     "symbol=%s — returning false → INIT_FAILED", i, _Symbol));
         // Release any handles that DID succeed before bailing (Finding 01.1):
         // m_handle_count is still 0 here, so orchestrator's ReleaseHandles()
         // would loop 0..0 → leak everything. Do the cleanup inline.
         for(int j = 0; j < total; j++)
            if(j != i && m_handles[j] != INVALID_HANDLE)
              {
               IndicatorRelease(m_handles[j]);
               m_handles[j] = INVALID_HANDLE;
              }
         return false;  // orchestrator → CleanupPartialInit → INIT_FAILED (TD-02 §7.4.1)
        }
     }

   m_handle_count = total;  // lock in count only after all validated

   m_logger.Info("indicators", "handles_created", 0,
                 StringFormat("All %d indicator handles valid (ADR-003 inventory)", m_handle_count));
   return true;
  }

//+------------------------------------------------------------------+
//| Refresh — invalidate scan cache on new H4 bar (FR-8.1)           |
//|                                                                  |
//| Called: OnTick step 1 (per TD-02 §5.1 OnTick contract)          |
//| Performance: no heap allocation (ea.md §4 hot-path rule)        |
//|                                                                  |
//| TODO IMPL-005-refresh: CopyBuffer × N handles per OnTick contract |
//|   Full implementation deferred to IMPL-006 (MarketContextBuilder) |
//|   which defines per-buffer layout. IndicatorService exposes       |
//|   GetHandle(IDX_*) for MCB to call CopyBuffer directly.          |
//+------------------------------------------------------------------+
void CIndicatorService::Refresh()
  {
   int bars_h4 = iBars(_Symbol, PERIOD_H4);
   if(bars_h4 != m_last_bar_index_h4)
     {
      // New H4 bar — invalidate the scan cache (FR-8.1 cache invalidation)
      m_scan_count         = 0;
      m_last_bar_index_h4  = bars_h4;
      // Reset scan arrays for clean eviction state
      for(int i = 0; i < 10; i++)
         m_scan_keys[i] = "";
      ArrayInitialize(m_scan_values, 0.0);
     }

   // TODO IMPL-005-refresh: CopyBuffer × N handles per OnTick contract
   //   (deferred: MarketContextBuilder owns per-buffer extraction at IMPL-006)
  }

//+------------------------------------------------------------------+
//| AnyHandleInvalid — runtime fail-fast check (FR-7.6)              |
//|                                                                  |
//| Returns true if any m_handles[i] == INVALID_HANDLE               |
//| Orchestrator calls after CreateHandles and periodically if needed |
//+------------------------------------------------------------------+
bool CIndicatorService::AnyHandleInvalid() const
  {
   for(int i = 0; i < m_handle_count; i++)
     {
      if(m_handles[i] == INVALID_HANDLE)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| CachedScan — 300-bar scan cache (FR-8.1)                         |
//|                                                                  |
//| Algorithm:                                                        |
//|   1. Linear scan m_scan_keys for key → return cached value       |
//|   2. If not found and m_scan_count < 10 → insert new entry       |
//|   3. If cache full (m_scan_count == 10) → evict oldest (index 0) |
//|      via rotate-left pattern + insert at tail                    |
//|                                                                  |
//| scan_fn invocation: full call deferred until handle↔IDX mapping  |
//|   is enumerated by MarketContextBuilder (IMPL-006+).             |
//|   TODO IMPL-005-cachedscan: full scan_fn invocation per FR-8.1  |
//|   (pass correct handle index to scan_fn once MCB IDX mapping known)|
//+------------------------------------------------------------------+
double CIndicatorService::CachedScan(string key, ScanFnType scan_fn)
  {
   // Step 1: check cache hit
   for(int i = 0; i < m_scan_count; i++)
     {
      if(m_scan_keys[i] == key)
         return m_scan_values[i];  // cache hit — no recompute (FR-8.1 300-bar scan savings)
     }

   // Step 2/3: cache miss — fail-loud until IDX↔key mapping is wired (Finding 01.7).
   //   Stub had called scan_fn with m_handles[0] regardless of key → silent
   //   wrong-result (Ichimoku H4 returned for Force/ZigZag scans, etc.).
   //   Until IMPL-006 (MCB) defines the key→IDX convention, refuse to compute.
   //   No insert into cache — keep cache valid for the day the mapping lands.
   if(m_logger != NULL)
      m_logger.Warn("indicators", "cached_scan_unwired", 0,
                    "CachedScan called before IDX-mapping wired; key=" + key + " — returning 0.0");
   (void)scan_fn;
   return 0.0;
  }

//+------------------------------------------------------------------+
//| ReleaseHandles — release all indicator handles (OnDeinit)         |
//|                                                                  |
//| Calls IndicatorRelease for each valid handle; resets count to 0. |
//| Prevents resource leak per MQL5 indicator handle lifecycle rule.  |
//+------------------------------------------------------------------+
void CIndicatorService::ReleaseHandles()
  {
   for(int i = 0; i < m_handle_count; i++)
     {
      if(m_handles[i] != INVALID_HANDLE)
         IndicatorRelease(m_handles[i]);
     }
   m_handle_count = 0;
   ArrayInitialize(m_handles, INVALID_HANDLE);
  }

#endif // PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH
