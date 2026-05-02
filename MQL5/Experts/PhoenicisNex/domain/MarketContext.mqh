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
struct SubDemFields { double support_zone; double demand_zone; bool has_support; bool has_demand; };

//--- Pre-computed cross-indicator signals (computed once per tick by MarketContextBuilder)
struct DerivedSignals {
   bool wpr_wave_signal;            // RunCheckWPRWaveWithIchimoku2 result
   bool adx_force_peak_valid;       // CheckADXWithForcePeakValid2 result
   bool ichi_double_bounce_active;
};

//+------------------------------------------------------------------+
//| MarketContext — immutable per-tick snapshot (ADR-004)             |
//| Size: ~720 bytes; always passed by const& (never by value)        |
//| 25 top-level fields: 5 primitives + 19 sub-structs + 1 derived   |
//+------------------------------------------------------------------+
struct MarketContext {
   // --- 5 primitive fields ---
   datetime tick_time;         // broker server time (EET, DST per C-10)
   double   bid;
   double   ask;
   double   spread_pip;        // (ask-bid) / (_Point * digit_multiplier)
   int      bar_index_h4;      // current H4 bar index (FR-8.1 cache key)

   // --- 19 sub-struct fields ---
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

   // --- 1 derived signals field ---
   // Note: schema YAML name is "derived_signals"; struct field name is "derived"
   // (TD-02 convention; acceptable per naming delta documented in evidence artifact)
   DerivedSignals  derived;
};

#endif // PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH
