//+------------------------------------------------------------------+
//| PipMath.mqh — DigitMultiplier-aware arithmetic (BR-9.3 + ADR-009)|
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_HELPERS_PIPMATH_MQH
#define PHOENICISNEX_HELPERS_PIPMATH_MQH

//+------------------------------------------------------------------+
//| CPipMath — Pip conversion utility for 4-digit and 5-digit brokers |
//|                                                                  |
//| FBS Standard EURUSD is a 5-digit broker (_Digits == 5):         |
//|   m_digit_multiplier = 10 (1 pip = 10 points)                   |
//| 4-digit broker (_Digits == 4):                                   |
//|   m_digit_multiplier = 1  (1 pip = 1 point)                     |
//|                                                                  |
//| Source: TD-02 §4.1 + BR-9.3 + ADR-009 stub                      |
//+------------------------------------------------------------------+
class CPipMath
  {
private:
   int               m_digit_multiplier;     // 10 for 5-digit broker (FBS), 1 for 4-digit

public:
   //--- Constructor — multiplier not valid until Init() called
   CPipMath() : m_digit_multiplier(1) {}

   //--- Detect digit count from _Digits and cache multiplier (call once at OnInit)
   void              Init()
     {
      // BR-9.3: 5-digit EURUSD broker (FBS Standard) uses _Digits==5; 3-digit JPY pairs also ×10
      // PhoenicisNex is EURUSD-only so the 5/4-digit branch is the operative path
      m_digit_multiplier = (_Digits == 5 || _Digits == 3) ? 10 : 1;
      Print("[Phoenicis][slot=system][ev=pip_math_init][digit_multiplier=" +
            IntegerToString(m_digit_multiplier) + "]");
     }

   //--- Accessor
   int               DigitMultiplier() const { return m_digit_multiplier; }

   //--- Convert price difference to pip count (always positive)
   //    PriceToPip(Ask - Bid) → spread in pips
   double            PriceToPip(double price_diff) const
     {
      return MathAbs(price_diff) / (_Point * m_digit_multiplier);
     }

   //--- Convert pip count to price difference (signed by caller's direction)
   //    PipToPrice(20.0) on 5-digit → 0.00200 (= 200 points)
   double            PipToPrice(double pip) const
     {
      return pip * _Point * m_digit_multiplier;
     }

   //--- Thin alias: pip count → integer point count (plan-text S-AC fidelity per §6.B.2)
   //    ToPoints(20.0) on 5-digit → 200
   int               ToPoints(double pips) const
     {
      return (int)MathRound(pips * m_digit_multiplier);
     }

   //--- Thin alias: integer point count → pip count
   double            FromPoints(int points) const
     {
      return (double)points / m_digit_multiplier;
     }

   //--- BI SL fix per ADR-009 — inherit same SL distance as B parent (returns absolute SL price)
   //    STUB ONLY for IMPL-009: returns parent_sl unchanged pending IMPL-022/IMPL-039
   //    TODO ADR-009 IMPL-022/IMPL-039 will complete this with full parent pip-distance arithmetic
   double            InheritSlFromParent(double bi_entry,
                                         ENUM_ORDER_TYPE bi_dir,
                                         double parent_open,
                                         double parent_sl) const
     {
      // Suppress unused-parameter warnings (MQL5 strict mode)
      (void)bi_entry;
      (void)bi_dir;
      (void)parent_open;

      Print("[Phoenicis][slot=system][ev=inherit_sl_stub] ADR-009 stub — returns parent_sl unchanged");
      return parent_sl;
     }
  };

#endif // PHOENICISNEX_HELPERS_PIPMATH_MQH
