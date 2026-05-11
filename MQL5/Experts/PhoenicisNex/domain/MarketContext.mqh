//+------------------------------------------------------------------+
//| MarketContext.mqh — immutable per-tick snapshot (ADR-004)        |
//| Schema: docs/api-specs/marketcontext-snapshot-schema.yaml         |
//| No methods — pure data; immutability enforced by const& at sites  |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH
#define PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH

#include "EnumTypes.mqh"

//--- Ichimoku indicator fields (H4 and D1 timeframes)
struct IchimokuFields {
   double tenkan[3];          // [bar 0, bar 1, bar 2]
   double kijun[3];
   double senkou_a[3];
   double senkou_b[3];
   double chikou[3];
   double cloud_high;         // derived: max(senkou_a[0], senkou_b[0])
   double cloud_low;          // derived: min(senkou_a[0], senkou_b[0])
};

//--- Force Index indicator fields (H4 timeframe)
struct ForceFields {
   double f0, f1, f2, f3;
   int    peak_pattern;       // -1 descending / 0 neutral / +1 ascending
};

//--- ADX / ADXW indicator fields (H4 and D1 timeframes)
struct AdxFields {
   double adx;
   double di_plus;
   double di_minus;
   double adx_wave;           // ADXW per CodeWiki §1.4
};

//--- Williams %R indicator fields (H4, D1, M15 timeframes)
struct WprFields    { double wpr; double wpr_wave; };

//--- Bollinger Bands indicator fields (H4 timeframe)
struct BBFields     { double bb_top, bb_mid, bb_bot, bb_width, bb_ratio; };

//--- DeMarker indicator fields (H4 timeframe)
struct DemFields    { double dem; };

//--- Stochastic oscillator fields (M10 and H4 timeframes)
struct StochFields  { double k_main; double d_signal; };

//--- MACD indicator fields (M10 and D1 timeframes)
struct MacdFields   { double macd; double signal; double hist; int same_sign_loss_bars; };

//--- RSI indicator fields (H4 timeframe)
struct RsiFields    { double rsi; };

//--- Hull MA indicator fields (H4 timeframe)
struct HullFields   { double hull; double hull_slope; };

//--- Fractal indicator fields (H4 timeframe)
struct FractalFields{ double upper_fractal; double lower_fractal; bool has_upper; bool has_lower; };

//--- ZigZag indicator fields (M5 timeframe)
struct ZigZagFields { double last_high; double last_low; };

//--- Sub-demand/support zone fields (H4 and D1 timeframes)
//    zone_strength + zone_hit added 2026-05-11 IMPL-FIX-011a Fix E per diagnostic § 3 row E.
//    Legacy Slot_T §3.15:2 + §3.15:7 THAF gates on `strength == ZONE_PROVEN` + `zone_hit >= 2`.
//    Real classifier population deferred to P4 SubDemCalcModel indicator wiring — PopulateSubDem
//    currently assigns ZONE_NONE / 0 placeholder (THAF fail-closed until real values land).
struct SubDemFields {
   double         support_zone;
   double         demand_zone;
   bool           has_support;
   bool           has_demand;
   EZoneStrength  zone_strength;   // CodeWiki §4: NONE/WEAK/TESTED/PROVEN
   int            zone_hit;        // count of times zone has been touched/respected
};

//--- Bollinger Bands history (15-bar bb_top + bb_bot buffer per CodeWiki §3.6:11 + §3.7 + §3.15:5)
//    bb_top[0] / bb_bot[0] = current bar (newest); index 14 = oldest; series-indexed.
//    has_data = false if CopyBuffer short on any band/bar (degrade-but-continue per NFR-2.2).
//    Consumers: Slot_G §3.6:11 "15-bar BBTop<IchiMax scan", Slot_T §3.15:5 "≥7 of last 10
//      BBTop<IchiCloudLow / BBBot>IchiCloudHigh", Slot_G2 §3.7 BB conditions.
//    bb_bot[15] added 2026-05-11 (IMPL-FIX-011a Fix B) to support proper SELL mirror scan
//      `bb_bot[i] > cloud_high[i]` per legacy `BollBBot > IchiMin` (line 18644); pre-Fix-B
//      SELL scan reused BUY's `bb_top<cloud_low` count as Phase 1 conservative proxy.
struct BBHistoryFields {
   double bb_top[15];
   double bb_bot[15];   // IMPL-FIX-011a Fix B — §3.15:5 SELL mirror
   bool   has_data;
};

//--- Fractal H4 multi-bar buffer (real iFractals indicator; bars [0..4] series-indexed)
//    upper[i] / lower[i] = fractal price at bar i (0=current, 4=oldest); 0.0 = no fractal at that bar.
//    Consumer: Slot_T §3.15:7 THAF trigger `FractalLowBuffer[3] < Hull[3]` (BUY) /
//      `FractalUpBuffer[3] > Hull[3]` (SELL) — i.e. fractal at bar 3 vs Hull at bar 3.
//    Distinct from existing ZZ-proxy `fractal_h4` (current-bar only) populated from
//      IDX_ZIGZAG_H4 — consumed by Slot_H/B/S already; left intact to avoid disturbing
//      those slots. This new field is real iFractals via IDX_FRACTAL_H4 (=24).
//    has_data = false if CopyBuffer short on either Upper or Lower buffer.
//    Added 2026-05-11 IMPL-FIX-011a Fix D per diagnostic § 3 row D.
struct FractalHistoryFields {
   double upper[5];
   double lower[5];
   bool   has_data;
};

//--- Ichimoku cloud-edge history (15-bar per-bar cloud edges per CodeWiki §3.15:5)
//    cloud_low[i]  = MathMin(senkou_a[i], senkou_b[i]) — bottom edge at bar i (legacy IchiMin)
//    cloud_high[i] = MathMax(senkou_a[i], senkou_b[i]) — top edge at bar i (legacy IchiMax)
//    Index 0 = current bar (newest); index 14 = oldest; series-indexed.
//    has_data = false if CopyBuffer short on SenkouA/SenkouB (degrade-but-continue per NFR-2.2).
//    Consumer: Slot_T §3.15:5 per-bar `bb_top[i] < cloud_low[i]` (BUY) / `bb_bot[i] > cloud_high[i]`
//      (SELL) scan. Pre-Fix-B rewrite used current-bar `MathMax(cloud_high, tenkan[0], kijun[0])`
//      as IchiMax proxy — semantically wrong (mixes tenkan/kijun into cloud-edge gate). Legacy
//      `BollBTop[z] < MathMin(SenkouA[z], SenkouB[z])` is strict cloud-only per-bar.
//    Added 2026-05-11 IMPL-FIX-011a Fix B per diagnostic § 3 row B.
struct IchimokuHistoryFields {
   double cloud_low[15];
   double cloud_high[15];
   bool   has_data;
};

//--- Force Index history (8-bar Force buffer per CodeWiki §3.6:9 + §3.7:6 + §3.7:9)
//    force[0] = current bar (newest); force[7] = oldest; series-indexed.
//    peak_count_above11 = count of bars in window where |force| > 11 (§3.6:9 "≤3 prior >11 peaks").
//    has_data = false if CopyBuffer short.
//    Consumers: Slot_G §3.6:9 peak-exhaustion, Slot_G2 §3.7:6 (≥5 of 8 bars Force>0.2) + §3.7:9 (≥1 bar in [2,5) Force ≤ -0.2).
struct ForceHistoryFields {
   double force[8];
   int    peak_count_above11;
   bool   has_data;
};

//--- DeMarker rolling sum (25-bar sum × 100 per CodeWiki §3.6:12)
//    rolling_sum_x100 = sum(dem_h4 over last 25 bars) * 100.
//    Threshold: ≥175 → BUY pending (high momentum); ≤25 → SELL pending (low momentum).
//    has_data = false if CopyBuffer short.
//    Consumer: Slot_G §3.6:12 "DeMarker thresholds: BUY pending if total ratio ≥175; SELL ≤25".
struct DemRollingFields {
   double rolling_sum_x100;
   bool   has_data;
};

//--- ADX history (3-bar adx/+DI/-DI buffer per CodeWiki §3.6:6 + §3.7:5)
//    adx[0..2] / di_plus[0..2] / di_minus[0..2] series-indexed (newest=[0]).
//    adxw_no_trap_bars_1_3 = 1 when bars 1..3 do NOT have ADX trapped between ±DI (§3.7:5),
//    else 0. "Trapped" = ADX < both di_plus AND di_minus on the bar.
//    has_data = false if CopyBuffer short.
//    Consumers: Slot_G2 §3.7:5 ADX-W trap check; Slot_G uses adx_h4 currents directly (no history needed).
//    NB: §3.6:6 "no opposite cross within 300-bar lookback" deferred — proxy via current
//    ADX-W dominance is sufficient for Phase 1 single-tick gate; full 300-bar buffer would
//    cost ~7.2 KB per snapshot. Add later if 5-yr Bucket A surfaces drift.
struct AdxHistoryFields {
   double adx[3];
   double di_plus[3];
   double di_minus[3];
   int    adxw_no_trap_bars_1_3;
   bool   has_data;
};

//--- Pre-computed cross-indicator signals (computed once per tick by MarketContextBuilder)
struct DerivedSignals {
   bool wpr_wave_signal;            // RunCheckWPRWaveWithIchimoku2 result
   bool adx_force_peak_valid;       // CheckADXWithForcePeakValid2 result
   bool ichi_double_bounce_active;
};

//+------------------------------------------------------------------+
//| MarketContext — immutable per-tick snapshot (ADR-004)             |
//| Size: ~1180 bytes (was ~720B; +460B from IMPL-FIX-011 Session C   |
//|       MarketContext extension: BB-history 15B-double + Force      |
//|       8B-double + DEM 1B-double + ADX 9B-double + scalars)        |
//| Always passed by const& (never by value) — extension cost minimal |
//| 29 top-level fields: 5 primitives + 23 sub-structs + 1 derived   |
//|   (was 25 = 5 + 19 + 1; +4 sub-structs for §3.6/§3.7/§3.15        |
//|   history-based predicates per IMPL-FIX-011 Session C)            |
//+------------------------------------------------------------------+
struct MarketContext {
   // --- 5 primitive fields ---
   datetime tick_time;         // broker server time (EET, DST per C-10)
   double   bid;
   double   ask;
   double   spread_pip;        // (ask-bid) / (_Point * digit_multiplier)
   int      bar_index_h4;      // current H4 bar index (FR-8.1 cache key)

   // --- 23 sub-struct fields (was 19; +4 history fields per IMPL-FIX-011 Session C) ---
   IchimokuFields  ichi_h4;
   IchimokuFields  ichi_d1;
   ForceFields     force_h4;
   AdxFields       adx_h4;
   AdxFields       adx_d1;
   WprFields       wpr_h4;
   WprFields       wpr_d1;
   WprFields       wpr_m15;
   BBFields        bb_h4;
   DemFields       dem_h4;
   DemFields       dem_m15;
   StochFields     stoch_m10;
   StochFields     stoch_h4;
   MacdFields      macd_m10;
   MacdFields      macd_d1;
   RsiFields       rsi_h4;
   HullFields      hull_h4;
   FractalFields   fractal_h4;
   ZigZagFields    zigzag_m5;
   SubDemFields    subdem_h4;
   SubDemFields    subdem_d1;

   // --- IMPL-FIX-011 Session C history-based predicate fields ---
   //     Source: CodeWiki §3.6:9/11/12 (Slot_G), §3.7:5/6/9 (Slot_G2), §3.15:5 (Slot_T).
   //     Populated once per tick by MarketContextBuilder (ADR-004 immutability preserved).
   BBHistoryFields       bb_h4_history;     // §3.6:11 + §3.7 + §3.15:5 — 15-bar bb_top + bb_bot scan
   ForceHistoryFields    force_h4_history;  // §3.6:9 + §3.7:6 + §3.7:9 — 8-bar Force buffer + peak count
   DemRollingFields      dem_h4_rolling;    // §3.6:12 — 25-bar DEM rolling sum × 100
   AdxHistoryFields      adx_h4_history;    // §3.7:5 — 3-bar ADX/+DI/-DI history + adxw_no_trap_bars_1_3
   IchimokuHistoryFields ichi_h4_history;   // §3.15:5 — 15-bar per-bar cloud_low/cloud_high (IMPL-FIX-011a Fix B)
   FractalHistoryFields  fractal_h4_history;// §3.15:7 — 5-bar real iFractals buffer for THAF (IMPL-FIX-011a Fix D)

   // --- 1 derived signals field ---
   // Note: schema YAML name is "derived_signals"; struct field name is "derived"
   // (TD-02 convention; acceptable per naming delta documented in evidence artifact)
   DerivedSignals  derived;
};

#endif // PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH
