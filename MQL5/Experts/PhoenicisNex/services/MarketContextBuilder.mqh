//+------------------------------------------------------------------+
//| MarketContextBuilder.mqh — per-tick MarketContext snapshot        |
//| Layer:   services/ — called by Orchestrator once per OnTick       |
//| Source:  ADR-004 (immutable snapshot decision)                    |
//|          TD-02 §5.2 lines 516-533 (class skeleton + API contract) |
//|          TD-02 §3.2 (MarketContext fields + derived signals)       |
//|          ADR-012 (5-layer include discipline: services ↛ slots)   |
//|          NFR-2.3 (tick fidelity — populate ALL fields per tick)   |
//|                                                                   |
//| Key contracts:                                                    |
//|  • Build() returns MarketContext by value (copy semantics, ~720 B)|
//|  • ALL 25 top-level fields populated; none left default-zero      |
//|  • derived block computed from raw fields — no DRY violation      |
//|  • CopyBuffer always preceded by ArraySetAsSeries(buf, true)      |
//|  • Degrade-but-continue: CopyBuffer short → Warn + use partial    |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_MARKETCONTEXTBUILDER_MQH
#define PHOENICISNEX_SERVICES_MARKETCONTEXTBUILDER_MQH

#include "IndicatorService.mqh"  // CIndicatorService (same services/ layer)
#include "Logger.mqh"            // CLogger (same services/ layer)
#include "../domain/MarketContext.mqh"

//+------------------------------------------------------------------+
//| IDX_* mirror — local copy of private IndicatorService indices     |
//| Source: services/IndicatorService.mqh static const block         |
//| Duplication accepted per shared-context §6.B.3 option 3 —        |
//| keeps MarketContextBuilder self-documenting; zero blast radius.   |
//+------------------------------------------------------------------+
static const int MCB_IDX_ICHI_H4    = 0;
static const int MCB_IDX_ICHI_D1    = 1;
static const int MCB_IDX_FORCE_H4   = 2;
static const int MCB_IDX_ADX_H4     = 3;
static const int MCB_IDX_ADX_D1     = 4;
static const int MCB_IDX_WPR_H4     = 5;
static const int MCB_IDX_WPR_D1     = 6;
static const int MCB_IDX_WPR_M15    = 7;
static const int MCB_IDX_BBANDS_H4  = 8;
static const int MCB_IDX_DEMARK_H4  = 9;
static const int MCB_IDX_DEMARK_M15 = 10;
static const int MCB_IDX_STOCH_M10  = 11;
static const int MCB_IDX_STOCH_H4   = 12;
static const int MCB_IDX_STOCH_M15  = 13;  // reserved — ZigZag M5 at IMPL-019+
static const int MCB_IDX_MACD_M10   = 14;
static const int MCB_IDX_MACD_D1    = 15;
static const int MCB_IDX_ZIGZAG_H4  = 16;
static const int MCB_IDX_ZIGZAG_M5  = 17;
static const int MCB_IDX_MA_FAST_H4 = 18;
static const int MCB_IDX_MA_SLOW_H4 = 19;
static const int MCB_IDX_RSI_H4     = 20;
static const int MCB_IDX_RSI_D1     = 21;
static const int MCB_IDX_ATR_H4     = 22;
static const int MCB_IDX_MOMENTUM_H4= 23;

//--- Number of bars to copy for each indicator
#define MCB_BARS_ICHI    3    // tenkan/kijun/senkou require [bar0, bar1, bar2]
#define MCB_BARS_STD     3    // standard lookback for wave/slope computation
#define MCB_BARS_FORCE   4    // ForceFields: f0..f3

//--- IMPL-FIX-011 Session C history-buffer sizes (per CodeWiki §3.6/§3.7/§3.15)
#define MCB_BARS_BB_HIST     15   // §3.6:11 + §3.7 + §3.15:5 BBTop history scan window
#define MCB_BARS_FORCE_HIST  8    // §3.6:9 (peak count) + §3.7:6 (5-of-8) + §3.7:9 (1-of-[2,5))
#define MCB_BARS_DEM_ROLL    25   // §3.6:12 DEM rolling sum window
#define MCB_BARS_ADX_HIST    3    // §3.7:5 ADX-W not-trapped 1..3 bars window
#define MCB_FORCE_PEAK_THR   11.0 // §3.6:9 "peaks > 11" threshold (legacy CodeWiki spec)

//+------------------------------------------------------------------+
//| CMarketContextBuilder                                            |
//| Builds immutable per-tick MarketContext snapshot (ADR-004)       |
//+------------------------------------------------------------------+
class CMarketContextBuilder {
private:
   CIndicatorService *m_indicators;
   CLogger           *m_logger;

public:
   //--- Composition Root injection (ADR-002); Logger added per ADR-002 DI rule
   //    Mirrors CIndicatorService::Init(CLogger*) precedent for service-level DI.
   void Init(CIndicatorService *ind, CLogger *lg) {
      m_indicators = ind;
      m_logger     = lg;
   }

   //--- Build per-tick snapshot (~50 µs target per TD-02 §3.2 / TD-03 §2.3)
   //    Returns MarketContext by value (ADR-004 copy semantics; ~720 bytes acceptable)
   MarketContext Build() const;

private:
   //--- Sub-field population helpers (one per sub-struct kind)
   void PopulateIchimoku(int handle, IchimokuFields &out) const;
   void PopulateForce   (int handle, ForceFields    &out) const;
   void PopulateAdx     (int handle, AdxFields      &out) const;
   void PopulateWpr     (int handle, WprFields      &out) const;
   void PopulateBB      (int handle, BBFields       &out) const;
   void PopulateDem     (int handle, DemFields      &out) const;
   void PopulateStoch   (int handle, StochFields    &out) const;
   void PopulateMacd    (int handle, MacdFields     &out) const;
   void PopulateRsi     (int handle, RsiFields      &out) const;
   void PopulateHull    (int handle, HullFields     &out) const;
   void PopulateFractal (int handle, FractalFields  &out) const;
   void PopulateZigZag  (int handle, ZigZagFields   &out) const;
   void PopulateSubDem  (int handle, SubDemFields   &out) const;

   //--- IMPL-FIX-011 Session C history populate helpers (per CodeWiki §3.6/§3.7/§3.15)
   void PopulateBBHistory   (int handle, BBHistoryFields    &out) const;
   void PopulateForceHistory(int handle, ForceHistoryFields &out) const;
   void PopulateDemRolling  (int handle, DemRollingFields   &out) const;
   void PopulateAdxHistory  (int handle, AdxHistoryFields   &out) const;

   //--- Derived signal precompute helpers (ADR-004: computed once, slot reads flag)
   //    Replaces EA เดิม global RunCheckWPRWaveWithIchimoku2 + CheckADXWithForcePeakValid2
   bool ComputeWprWaveSignal    (const MarketContext &ctx) const;
   bool ComputeAdxForcePeakValid(const MarketContext &ctx) const;
   bool ComputeIchiDoubleBounce (const MarketContext &ctx) const;
   int  ClassifyForcePeak       (double f0, double f1, double f2, double f3) const;
};

//+------------------------------------------------------------------+
//| CopyBuffer wrapper — helper macro-style inline notes             |
//| Every call: ArraySetAsSeries first (ea.md rule); degrade-but-    |
//| continue on short copy (NFR-2.2).                                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Build — populate all 25 top-level fields + derived block         |
//+------------------------------------------------------------------+
MarketContext CMarketContextBuilder::Build() const
  {
   MarketContext ctx;

   // Guard: if any handle is invalid, return sentinel with Warn
   if (m_indicators == NULL || m_indicators.AnyHandleInvalid())
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "build_invalid_handles", 0,
                       "AnyHandleInvalid=true — returning zero-sentinel MarketContext");
      ZeroMemory(ctx);
      return ctx;
     }

   //--- 5 primitive fields ---
   ctx.tick_time    = TimeCurrent();   // EET broker server time (C-10)
   ctx.bid          = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ctx.ask          = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   // spread_pip = (ask - bid) / (_Point * digit_multiplier)
   // digit_multiplier = 10 for 5-digit broker (BR-9.1; PipMath not needed here — inline)
   double digit_mult = (_Digits == 5 || _Digits == 3) ? 10.0 : 1.0;
   ctx.spread_pip   = (ctx.ask - ctx.bid) / (_Point * digit_mult);
   ctx.bar_index_h4 = (int)iBarShift(_Symbol, PERIOD_H4, TimeCurrent(), false);

   //--- 19 sub-struct fields ---
   PopulateIchimoku(m_indicators.GetHandle(MCB_IDX_ICHI_H4),    ctx.ichi_h4);    // IDX_ICHI_H4=0
   PopulateIchimoku(m_indicators.GetHandle(MCB_IDX_ICHI_D1),    ctx.ichi_d1);    // IDX_ICHI_D1=1
   PopulateForce   (m_indicators.GetHandle(MCB_IDX_FORCE_H4),   ctx.force_h4);   // IDX_FORCE_H4=2
   PopulateAdx     (m_indicators.GetHandle(MCB_IDX_ADX_H4),     ctx.adx_h4);     // IDX_ADX_H4=3
   PopulateAdx     (m_indicators.GetHandle(MCB_IDX_ADX_D1),     ctx.adx_d1);     // IDX_ADX_D1=4
   PopulateWpr     (m_indicators.GetHandle(MCB_IDX_WPR_H4),     ctx.wpr_h4);     // IDX_WPR_H4=5
   PopulateWpr     (m_indicators.GetHandle(MCB_IDX_WPR_D1),     ctx.wpr_d1);     // IDX_WPR_D1=6
   PopulateWpr     (m_indicators.GetHandle(MCB_IDX_WPR_M15),    ctx.wpr_m15);    // IDX_WPR_M15=7
   PopulateBB      (m_indicators.GetHandle(MCB_IDX_BBANDS_H4),  ctx.bb_h4);      // IDX_BBANDS_H4=8
   PopulateDem     (m_indicators.GetHandle(MCB_IDX_DEMARK_H4),  ctx.dem_h4);     // IDX_DEMARK_H4=9
   PopulateDem     (m_indicators.GetHandle(MCB_IDX_DEMARK_M15), ctx.dem_m15);    // IDX_DEMARK_M15=10
   PopulateStoch   (m_indicators.GetHandle(MCB_IDX_STOCH_M10),  ctx.stoch_m10);  // IDX_STOCH_M10=11
   PopulateStoch   (m_indicators.GetHandle(MCB_IDX_STOCH_H4),   ctx.stoch_h4);   // IDX_STOCH_H4=12
   PopulateMacd    (m_indicators.GetHandle(MCB_IDX_MACD_M10),   ctx.macd_m10);   // IDX_MACD_M10=14
   PopulateMacd    (m_indicators.GetHandle(MCB_IDX_MACD_D1),    ctx.macd_d1);    // IDX_MACD_D1=15
   PopulateRsi     (m_indicators.GetHandle(MCB_IDX_RSI_H4),     ctx.rsi_h4);     // IDX_RSI_H4=20
   PopulateHull    (m_indicators.GetHandle(MCB_IDX_MA_FAST_H4), ctx.hull_h4);    // IDX_MA_FAST_H4=18 (Hull proxy)
   PopulateFractal (m_indicators.GetHandle(MCB_IDX_ZIGZAG_H4),  ctx.fractal_h4); // IDX_ZIGZAG_H4=16 (fractal via ZZ H4)
   PopulateZigZag  (m_indicators.GetHandle(MCB_IDX_ZIGZAG_M5),  ctx.zigzag_m5);  // IDX_ZIGZAG_M5=17
   PopulateSubDem  (m_indicators.GetHandle(MCB_IDX_MA_SLOW_H4), ctx.subdem_h4);  // IDX_MA_SLOW_H4=19 (subdem H4 proxy)
   PopulateSubDem  (m_indicators.GetHandle(MCB_IDX_RSI_D1),     ctx.subdem_d1);  // IDX_RSI_D1=21 (subdem D1 proxy)

   //--- IMPL-FIX-011 Session C history-based field population
   //    Reuses existing IDX_BBANDS_H4 / IDX_FORCE_H4 / IDX_DEMARK_H4 / IDX_ADX_H4 handles
   //    (no new indicator handles needed — IndicatorService inventory unchanged).
   PopulateBBHistory   (m_indicators.GetHandle(MCB_IDX_BBANDS_H4), ctx.bb_h4_history);    // §3.6:11 + §3.7 + §3.15:5
   PopulateForceHistory(m_indicators.GetHandle(MCB_IDX_FORCE_H4),  ctx.force_h4_history); // §3.6:9 + §3.7:6 + §3.7:9
   PopulateDemRolling  (m_indicators.GetHandle(MCB_IDX_DEMARK_H4), ctx.dem_h4_rolling);   // §3.6:12
   PopulateAdxHistory  (m_indicators.GetHandle(MCB_IDX_ADX_H4),    ctx.adx_h4_history);   // §3.7:5

   //--- 1 derived signals field (computed from raw fields — no DRY violation, ADR-004) ---
   ctx.derived.wpr_wave_signal          = ComputeWprWaveSignal(ctx);
   ctx.derived.adx_force_peak_valid     = ComputeAdxForcePeakValid(ctx);
   ctx.derived.ichi_double_bounce_active= ComputeIchiDoubleBounce(ctx);

   return ctx;
  }

//+------------------------------------------------------------------+
//| PopulateIchimoku — 5 buffers × MCB_BARS_ICHI bars               |
//| iIchimoku buffer_index: 0=Tenkan 1=Kijun 2=SenkouA 3=SenkouB 4=Chikou |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateIchimoku(int handle, IchimokuFields &out) const
  {
   double tenkan[], kijun[], senkouA[], senkouB[], chikou[];
   ArraySetAsSeries(tenkan,  true);
   ArraySetAsSeries(kijun,   true);
   ArraySetAsSeries(senkouA, true);
   ArraySetAsSeries(senkouB, true);
   ArraySetAsSeries(chikou,  true);

   int c0 = CopyBuffer(handle, 0, 0, MCB_BARS_ICHI, tenkan);
   int c1 = CopyBuffer(handle, 1, 0, MCB_BARS_ICHI, kijun);
   int c2 = CopyBuffer(handle, 2, 0, MCB_BARS_ICHI, senkouA);
   int c3 = CopyBuffer(handle, 3, 0, MCB_BARS_ICHI, senkouB);
   int c4 = CopyBuffer(handle, 4, 0, MCB_BARS_ICHI, chikou);

   if (c0 < MCB_BARS_ICHI || c1 < MCB_BARS_ICHI || c2 < MCB_BARS_ICHI ||
       c3 < MCB_BARS_ICHI || c4 < MCB_BARS_ICHI)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("ichi handle=%d copies=%d/%d/%d/%d/%d expected=%d",
                                    handle, c0, c1, c2, c3, c4, MCB_BARS_ICHI));
     }

   // Populate with what we got; default-zero if copy failed (degrade-but-continue)
   for (int i = 0; i < MCB_BARS_ICHI; i++)
     {
      out.tenkan [i] = (i < c0) ? tenkan [i] : 0.0;
      out.kijun  [i] = (i < c1) ? kijun  [i] : 0.0;
      out.senkou_a[i]= (i < c2) ? senkouA[i] : 0.0;
      out.senkou_b[i]= (i < c3) ? senkouB[i] : 0.0;
      out.chikou [i] = (i < c4) ? chikou [i] : 0.0;
     }

   // Derived cloud fields
   out.cloud_high = MathMax(out.senkou_a[0], out.senkou_b[0]);
   out.cloud_low  = MathMin(out.senkou_a[0], out.senkou_b[0]);
  }

//+------------------------------------------------------------------+
//| PopulateForce — Force Index (H4); 4 bars (f0..f3)               |
//| buffer_index 0 = Force line                                       |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateForce(int handle, ForceFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_FORCE, buf);
   if (copied < MCB_BARS_FORCE)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("force handle=%d copied=%d expected=%d",
                                    handle, copied, MCB_BARS_FORCE));
     }
   out.f0 = (copied > 0) ? buf[0] : 0.0;
   out.f1 = (copied > 1) ? buf[1] : 0.0;
   out.f2 = (copied > 2) ? buf[2] : 0.0;
   out.f3 = (copied > 3) ? buf[3] : 0.0;
   out.peak_pattern = ClassifyForcePeak(out.f0, out.f1, out.f2, out.f3);
  }

//+------------------------------------------------------------------+
//| PopulateAdx — ADX / ADXW (H4 and D1)                            |
//| buffer_index: 0=ADX 1=+DI 2=-DI                                  |
//| adx_wave uses buffer 0 (ADXW value) per CodeWiki §1.4            |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateAdx(int handle, AdxFields &out) const
  {
   double bufAdx[], bufPlus[], bufMinus[];
   ArraySetAsSeries(bufAdx,   true);
   ArraySetAsSeries(bufPlus,  true);
   ArraySetAsSeries(bufMinus, true);

   int c0 = CopyBuffer(handle, 0, 0, MCB_BARS_STD, bufAdx);
   int c1 = CopyBuffer(handle, 1, 0, MCB_BARS_STD, bufPlus);
   int c2 = CopyBuffer(handle, 2, 0, MCB_BARS_STD, bufMinus);

   if (c0 < 1 || c1 < 1 || c2 < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("adx handle=%d copies=%d/%d/%d",
                                    handle, c0, c1, c2));
     }
   out.adx      = (c0 > 0) ? bufAdx  [0] : 0.0;
   out.di_plus  = (c1 > 0) ? bufPlus [0] : 0.0;
   out.di_minus = (c2 > 0) ? bufMinus[0] : 0.0;
   // adx_wave = slope proxy: adx[0] - adx[1] (directional momentum per CodeWiki §1.4 ADXW)
   out.adx_wave = (c0 > 1) ? (bufAdx[0] - bufAdx[1]) : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateWpr — Williams %R (H4, D1, M15)                         |
//| buffer_index: 0 = WPR value                                      |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateWpr(int handle, WprFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_STD, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("wpr handle=%d copied=%d", handle, copied));
     }
   out.wpr      = (copied > 0) ? buf[0] : 0.0;
   // wpr_wave = slope proxy: wpr[0] - wpr[1]
   out.wpr_wave = (copied > 1) ? (buf[0] - buf[1]) : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateBB — Bollinger Bands (H4)                                |
//| buffer_index: 0=Mid 1=Upper 2=Lower                              |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateBB(int handle, BBFields &out) const
  {
   double bufMid[], bufUp[], bufLo[];
   ArraySetAsSeries(bufMid, true);
   ArraySetAsSeries(bufUp,  true);
   ArraySetAsSeries(bufLo,  true);

   int c0 = CopyBuffer(handle, 0, 0, 1, bufMid);
   int c1 = CopyBuffer(handle, 1, 0, 1, bufUp);
   int c2 = CopyBuffer(handle, 2, 0, 1, bufLo);

   if (c0 < 1 || c1 < 1 || c2 < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("bb handle=%d copies=%d/%d/%d", handle, c0, c1, c2));
     }
   out.bb_mid   = (c0 > 0) ? bufMid[0] : 0.0;
   out.bb_top   = (c1 > 0) ? bufUp [0] : 0.0;
   out.bb_bot   = (c2 > 0) ? bufLo [0] : 0.0;
   out.bb_width = out.bb_top - out.bb_bot;
   // bb_ratio = price position within band [0..1]; mid = 0.5
   out.bb_ratio = (out.bb_width > 0.0)
                  ? ((SymbolInfoDouble(_Symbol, SYMBOL_BID) - out.bb_bot) / out.bb_width)
                  : 0.5;
  }

//+------------------------------------------------------------------+
//| PopulateDem — DeMarker (H4, M15)                                 |
//| buffer_index: 0                                                   |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateDem(int handle, DemFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, 1, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("dem handle=%d copied=%d", handle, copied));
     }
   out.dem = (copied > 0) ? buf[0] : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateStoch — Stochastic (M10, H4)                             |
//| buffer_index: 0=K_main 1=D_signal                                |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateStoch(int handle, StochFields &out) const
  {
   double bufK[], bufD[];
   ArraySetAsSeries(bufK, true);
   ArraySetAsSeries(bufD, true);

   int c0 = CopyBuffer(handle, 0, 0, 1, bufK);
   int c1 = CopyBuffer(handle, 1, 0, 1, bufD);

   if (c0 < 1 || c1 < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("stoch handle=%d copies=%d/%d", handle, c0, c1));
     }
   out.k_main   = (c0 > 0) ? bufK[0] : 0.0;
   out.d_signal = (c1 > 0) ? bufD[0] : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateMacd — MACD (M10, D1)                                    |
//| buffer_index: 0=MACD line 1=Signal line                          |
//| hist = macd - signal; same_sign_loss_bars = consecutive bars      |
//| where hist sign matches current (structural placeholder for P3)  |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateMacd(int handle, MacdFields &out) const
  {
   double bufMacd[], bufSig[];
   ArraySetAsSeries(bufMacd, true);
   ArraySetAsSeries(bufSig,  true);

   int c0 = CopyBuffer(handle, 0, 0, MCB_BARS_STD, bufMacd);
   int c1 = CopyBuffer(handle, 1, 0, MCB_BARS_STD, bufSig);

   if (c0 < 1 || c1 < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("macd handle=%d copies=%d/%d", handle, c0, c1));
     }
   out.macd   = (c0 > 0) ? bufMacd[0] : 0.0;
   out.signal = (c1 > 0) ? bufSig [0] : 0.0;
   out.hist   = out.macd - out.signal;

   // same_sign_loss_bars: count consecutive bars where hist has same sign as current
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   out.same_sign_loss_bars = 0;
   if (c0 >= MCB_BARS_STD && c1 >= MCB_BARS_STD)
     {
      double h0 = bufMacd[0] - bufSig[0];
      double h1 = bufMacd[1] - bufSig[1];
      double h2 = bufMacd[2] - bufSig[2];
      // count bars where sign is same as h0
      if ((h0 > 0 && h1 > 0) || (h0 < 0 && h1 < 0)) out.same_sign_loss_bars++;
      if ((h0 > 0 && h2 > 0) || (h0 < 0 && h2 < 0)) out.same_sign_loss_bars++;
     }
  }

//+------------------------------------------------------------------+
//| PopulateRsi — RSI (H4)                                           |
//| buffer_index: 0                                                   |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateRsi(int handle, RsiFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, 1, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("rsi handle=%d copied=%d", handle, copied));
     }
   out.rsi = (copied > 0) ? buf[0] : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateHull — Hull MA (H4 via MA_FAST_H4 proxy)                 |
//| buffer_index: 0                                                   |
//| hull_slope = slope proxy: hull[0] - hull[1]                      |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateHull(int handle, HullFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_STD, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("hull handle=%d copied=%d", handle, copied));
     }
   out.hull       = (copied > 0) ? buf[0] : 0.0;
   out.hull_slope = (copied > 1) ? (buf[0] - buf[1]) : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateFractal — Fractal via ZigZag H4 proxy                    |
//| buffer_index: 0 = ZigZag high-side; 1 = ZigZag low-side         |
//| (fractal_h4 populated from ZigZag H4 buffers)                   |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateFractal(int handle, FractalFields &out) const
  {
   double bufHi[], bufLo[];
   ArraySetAsSeries(bufHi, true);
   ArraySetAsSeries(bufLo, true);

   int c0 = CopyBuffer(handle, 0, 0, MCB_BARS_STD, bufHi);
   int c1 = CopyBuffer(handle, 1, 0, MCB_BARS_STD, bufLo);

   if (c0 < 1 || c1 < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("fractal handle=%d copies=%d/%d", handle, c0, c1));
     }
   // Search for most recent non-zero fractal value (EMPTY_VALUE = 2147483647.0 in MT5)
   out.upper_fractal = 0.0;
   out.lower_fractal = 0.0;
   out.has_upper     = false;
   out.has_lower     = false;

   for (int i = 0; i < c0; i++)
     {
      if (bufHi[i] > 0 && bufHi[i] < 1e10) { out.upper_fractal = bufHi[i]; out.has_upper = true; break; }
     }
   for (int i = 0; i < c1; i++)
     {
      if (bufLo[i] > 0 && bufLo[i] < 1e10) { out.lower_fractal = bufLo[i]; out.has_lower = true; break; }
     }
  }

//+------------------------------------------------------------------+
//| PopulateZigZag — ZigZag (M5)                                     |
//| buffer_index: 0 = ZigZag swing points                            |
//| last_high / last_low = most recent non-zero swing values         |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateZigZag(int handle, ZigZagFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   // Copy more bars to find recent swing highs and lows
   int copied = CopyBuffer(handle, 0, 0, 50, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("zigzag handle=%d copied=%d", handle, copied));
     }

   out.last_high = 0.0;
   out.last_low  = 0.0;
   double prev   = 0.0;

   for (int i = 0; i < copied; i++)
     {
      if (buf[i] > 0 && buf[i] < 1e10)
        {
         if (out.last_high == 0.0) { out.last_high = buf[i]; }
         else if (buf[i] < out.last_high && out.last_low == 0.0) { out.last_low = buf[i]; break; }
         else if (buf[i] > out.last_high) { out.last_high = buf[i]; }
         prev = buf[i];
        }
     }
   // Fallback: if last_low still zero, populate with bid as safe non-zero
   if (out.last_low == 0.0 && out.last_high > 0.0)
      out.last_low = out.last_high * 0.999;
  }

//+------------------------------------------------------------------+
//| PopulateSubDem — Sub-demand/support zone (H4 and D1 proxy)      |
//| PLACEHOLDER IMPL-006 — uses MA proxy until dedicated subdem      |
//| indicator is wired in P3 slot tasks (IMPL-019..039)              |
//| buffer_index: 0 = MA line                                        |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateSubDem(int handle, SubDemFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_STD, buf);
   if (copied < 1)
     {
      if (m_logger != NULL)
         m_logger.Warn("market_context", "copybuffer_short", 0,
                       StringFormat("subdem handle=%d copied=%d", handle, copied));
     }
   double ma0 = (copied > 0) ? buf[0] : 0.0;
   double ma1 = (copied > 1) ? buf[1] : 0.0;

   // Use MA as proxy zone boundary (real subdem from CodeWiki §4 added at P3)
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   out.support_zone = MathMin(ma0, ma1);
   out.demand_zone  = MathMax(ma0, ma1);
   out.has_support  = (out.support_zone > 0.0);
   out.has_demand   = (out.demand_zone  > 0.0);
  }

//+------------------------------------------------------------------+
//| ClassifyForcePeak — -1/0/+1 per CodeWiki §1.4 Force peak pattern|
//| Ascending (f0>f1>f2>f3) → +1; Descending → -1; else → 0        |
//+------------------------------------------------------------------+
int CMarketContextBuilder::ClassifyForcePeak(double f0, double f1, double f2, double f3) const
  {
   if (f0 > f1 && f1 > f2 && f2 > f3) return  1;  // ascending force
   if (f0 < f1 && f1 < f2 && f2 < f3) return -1;  // descending force
   return 0;                                        // neutral
  }

//+------------------------------------------------------------------+
//| ComputeWprWaveSignal                                             |
//| Coarse placeholder: oversold (WPR<-80) + positive wave          |
//| PLACEHOLDER IMPL-006 — refine in P3 slot integration            |
//| Full logic: CodeWiki §1.4 RunCheckWPRWaveWithIchimoku2           |
//+------------------------------------------------------------------+
bool CMarketContextBuilder::ComputeWprWaveSignal(const MarketContext &ctx) const
  {
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   return (ctx.wpr_h4.wpr < -80.0 && ctx.wpr_h4.wpr_wave > 0);
  }

//+------------------------------------------------------------------+
//| ComputeAdxForcePeakValid                                         |
//| Coarse placeholder: ADX > 25 + force peak pattern != 0          |
//| PLACEHOLDER IMPL-006 — refine in P3 slot integration            |
//| Full logic: CodeWiki §1.4 CheckADXWithForcePeakValid2            |
//+------------------------------------------------------------------+
bool CMarketContextBuilder::ComputeAdxForcePeakValid(const MarketContext &ctx) const
  {
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   return (ctx.adx_h4.adx > 25.0 && ctx.force_h4.peak_pattern != 0);
  }

//+------------------------------------------------------------------+
//| ComputeIchiDoubleBounce                                          |
//| TODO IMPL-FUTURE — depends on H4 history scan (≥50 bars)        |
//| Safe default: false until P3 slot tasks provide scan context    |
//| PLACEHOLDER IMPL-006 — refine in P3 slot integration            |
//+------------------------------------------------------------------+
bool CMarketContextBuilder::ComputeIchiDoubleBounce(const MarketContext &ctx) const
  {
   // PLACEHOLDER IMPL-006 — refine in P3 slot integration
   // TODO IMPL-FUTURE — requires multi-bar history scan beyond ADR-004 single-tick snapshot
   return false;
  }

//+------------------------------------------------------------------+
//| IMPL-FIX-011 Session C — history-based population helpers         |
//| Per CodeWiki §3.6:9/11/12 (Slot_G), §3.7:5/6/9 (Slot_G2),         |
//| §3.15:5 (Slot_T). Replace single-tick proxies that empirically    |
//| failed Step 4 iter-2 (per artifact IMPL-FIX-011-q1-postpatch-     |
//| 20260510-iter2.md § 0 verdict synthesis).                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| PopulateBBHistory — 15-bar bb_top history from Bollinger H4       |
//| buffer_index 1 = Upper band; series-indexed (newest=[0]).         |
//| Used by Slot_G §3.6:11 + Slot_G2 §3.7 + Slot_T §3.15:5.           |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateBBHistory(int handle, BBHistoryFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 1, 0, MCB_BARS_BB_HIST, buf);
   out.has_data = (copied >= MCB_BARS_BB_HIST);
   if(!out.has_data && m_logger != NULL)
      m_logger.Warn("market_context", "copybuffer_short", 0,
                    StringFormat("bb_history handle=%d copied=%d expected=%d",
                                 handle, copied, MCB_BARS_BB_HIST));
   for(int i = 0; i < MCB_BARS_BB_HIST; i++)
      out.bb_top[i] = (i < copied) ? buf[i] : 0.0;
  }

//+------------------------------------------------------------------+
//| PopulateForceHistory — 8-bar Force buffer + peak count > 11       |
//| buffer_index 0 = Force line; series-indexed (newest=[0]).         |
//| peak_count_above11 = bars where |force| > MCB_FORCE_PEAK_THR (11) |
//| Used by Slot_G §3.6:9 + Slot_G2 §3.7:6 + §3.7:9.                  |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateForceHistory(int handle, ForceHistoryFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_FORCE_HIST, buf);
   out.has_data = (copied >= MCB_BARS_FORCE_HIST);
   if(!out.has_data && m_logger != NULL)
      m_logger.Warn("market_context", "copybuffer_short", 0,
                    StringFormat("force_history handle=%d copied=%d expected=%d",
                                 handle, copied, MCB_BARS_FORCE_HIST));
   out.peak_count_above11 = 0;
   for(int i = 0; i < MCB_BARS_FORCE_HIST; i++)
     {
      double v = (i < copied) ? buf[i] : 0.0;
      out.force[i] = v;
      if(MathAbs(v) > MCB_FORCE_PEAK_THR) out.peak_count_above11++;
     }
  }

//+------------------------------------------------------------------+
//| PopulateDemRolling — 25-bar DEM rolling sum × 100                 |
//| buffer_index 0 = DEM value; series-indexed (newest=[0]).          |
//| rolling_sum_x100 = sum(dem[0..24]) × 100; CodeWiki §3.6:12 spec   |
//| thresholds: ≥175 → BUY pending; ≤25 → SELL pending.               |
//| Used by Slot_G §3.6:12 BUY/SELL pending gates.                    |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateDemRolling(int handle, DemRollingFields &out) const
  {
   double buf[];
   ArraySetAsSeries(buf, true);
   int copied = CopyBuffer(handle, 0, 0, MCB_BARS_DEM_ROLL, buf);
   out.has_data = (copied >= MCB_BARS_DEM_ROLL);
   if(!out.has_data && m_logger != NULL)
      m_logger.Warn("market_context", "copybuffer_short", 0,
                    StringFormat("dem_rolling handle=%d copied=%d expected=%d",
                                 handle, copied, MCB_BARS_DEM_ROLL));
   double sum = 0.0;
   for(int i = 0; i < copied; i++) sum += buf[i];
   out.rolling_sum_x100 = sum * 100.0;
  }

//+------------------------------------------------------------------+
//| PopulateAdxHistory — 3-bar ADX/+DI/-DI buffer + adxw-no-trap flag |
//| buffer_index: 0=ADX 1=+DI 2=-DI; series-indexed (newest=[0]).     |
//| adxw_no_trap_bars_1_3: 1 if bars 1..3 ALL have ADX >= di_plus OR  |
//| ADX >= di_minus (i.e., NOT trapped between both DI lines on any   |
//| of bars 1..3); 0 otherwise. CodeWiki §3.7:5 spec.                  |
//| Used by Slot_G2 §3.7:5 ADX-W trap gate.                            |
//+------------------------------------------------------------------+
void CMarketContextBuilder::PopulateAdxHistory(int handle, AdxHistoryFields &out) const
  {
   double bufAdx[], bufPlus[], bufMinus[];
   ArraySetAsSeries(bufAdx,   true);
   ArraySetAsSeries(bufPlus,  true);
   ArraySetAsSeries(bufMinus, true);

   int c0 = CopyBuffer(handle, 0, 0, MCB_BARS_ADX_HIST, bufAdx);
   int c1 = CopyBuffer(handle, 1, 0, MCB_BARS_ADX_HIST, bufPlus);
   int c2 = CopyBuffer(handle, 2, 0, MCB_BARS_ADX_HIST, bufMinus);

   out.has_data = (c0 >= MCB_BARS_ADX_HIST &&
                   c1 >= MCB_BARS_ADX_HIST &&
                   c2 >= MCB_BARS_ADX_HIST);
   if(!out.has_data && m_logger != NULL)
      m_logger.Warn("market_context", "copybuffer_short", 0,
                    StringFormat("adx_history handle=%d copies=%d/%d/%d expected=%d",
                                 handle, c0, c1, c2, MCB_BARS_ADX_HIST));
   for(int i = 0; i < MCB_BARS_ADX_HIST; i++)
     {
      out.adx[i]      = (i < c0) ? bufAdx  [i] : 0.0;
      out.di_plus[i]  = (i < c1) ? bufPlus [i] : 0.0;
      out.di_minus[i] = (i < c2) ? bufMinus[i] : 0.0;
     }

   //--- §3.7:5 "ADX-W not trapped between ±DI for bars 1..3"
   //    Trapped on bar i = (adx[i] < di_plus[i]) AND (adx[i] < di_minus[i])
   //    "Not trapped 1..3" = NONE of bars 1, 2 are trapped (we have 3 bars [0,1,2]
   //    so "1..3" maps to indices 1 and 2 in our 3-element series-indexed buffer;
   //    bar 0 is "current" which CodeWiki treats separately).
   bool any_trapped = false;
   for(int i = 1; i < MCB_BARS_ADX_HIST; i++)
     {
      if(out.adx[i] < out.di_plus[i] && out.adx[i] < out.di_minus[i])
        {
         any_trapped = true;
         break;
        }
     }
   out.adxw_no_trap_bars_1_3 = any_trapped ? 0 : 1;
  }

#endif // PHOENICISNEX_SERVICES_MARKETCONTEXTBUILDER_MQH
