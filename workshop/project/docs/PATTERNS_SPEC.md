# Pattern Specifications

ภาพรวม
- เอกสารนี้กำหนดนิยามทางการของแพตเทิร์นหลัก: Inside, Outside, Pin (Bull/Bear), Engulfing (Bull/Bear)
- ตัวแปรพารามิเตอร์อ่านจาก config เช่น bodyRatioMin, wickRatioMin/Max, minRange, lookback filters ฯลฯ
- การตรวจหาทำบน Parquet Bars พร้อม Derived Features

A) ค่าพื้นฐานที่ใช้
- range = high - low
- body = close - open
- bodyAbs = |body|
- upperWick = high - max(open, close)
- lowerWick = min(open, close) - low
- bodyRatio = bodyAbs / range
- upperWickRatio = upperWick / range
- lowerWickRatio = lowerWick / range
- ข้ามกรณี range ≤ minRange

B) Inside Bar
นิยาม:
- high_t ≤ high_{t-1}
- low_t ≥ low_{t-1}
พารามิเตอร์ที่เกี่ยวข้อง:
- minRange (เพื่อคัดแท่งที่เล็กเกินไปหรือตลาดนิ่ง)
Edge cases:
- แท่ง Doji อาจยังนับเป็น inside ถ้าขอบอยู่ภายใน high/low ของแท่งก่อน

C) Outside Bar
นิยาม:
- high_t ≥ high_{t-1}
- low_t ≤ low_{t-1}
พารามิเตอร์:
- minRange
Edge cases:
- แท่งยาวมาก (long range) อาจเป็นสัญญาณแรง แต่ควรมี guard เช่น maxRange เพื่อหลีกเลี่ยง outlier

D) Pin Bar (Bullish)
นิยามหลัก:
- ทิศทาง bullish มักต้อง lowerWickRatio ≥ wickRatioMin และ bodyRatio ≤ bodyRatioMax
- close ≥ open (หรือ close ใกล้ high)
- ตัวอย่างเชิงสูตร: lowerWickRatio ≥ LWR_MIN และ upperWickRatio ≤ UWR_MAX และ bodyRatio ≤ BR_MAX
Pin Bar (Bearish):
- upperWickRatio ≥ wickRatioMin และ bodyRatio ≤ bodyRatioMax
- close ≤ open (หรือ close ใกล้ low)
พารามิเตอร์:
- BR_MAX (เช่น 0.33), LWR_MIN/UWR_MIN (เช่น ≥ 0.5), UWR_MAX/LWR_MAX (เลือกกำหนด)
Edge cases:
- doji wick ยาวทั้งสองข้าง — ควรคัดออก หรือจัดเป็น neutral ไม่ใช่ pin ชัดเจน
- long upper+lower wick อาจเกิดบน volatility spike

E) Engulfing (Bullish)
นิยามพื้นฐาน (แบบ body engulf):
- bodyAbs_t ≥ bodyAbs_{t-1}
- open_t ≤ close_{t-1}
- close_t ≥ open_{t-1}
และ close_t > open_t
Engulfing (Bearish):
- bodyAbs_t ≥ bodyAbs_{t-1}
- open_t ≥ close_{t-1}
- close_t ≤ open_{t-1}
และ close_t < open_t
พารามิเตอร์:
- minBodyRatio (เช่น ≥ 0.33), filter สำหรับ gap (ถ้ามี)
Edge cases:
- ตลาดที่มี gap อาจทำให้เงื่อนไข open/close ทับซ้อน ต้องกำหนดว่าอนุญาต gap หรือไม่

F) การวัดผล N-bars ahead
สำหรับทุกแพตเทิร์น เมื่อพบที่เวลา t:
- close_fwd_n = close_{t+n}
- return_raw_n = close_fwd_n − close_t
- ชนะสำหรับ bullish: return_raw_n > 0, สำหรับ bearish: return_raw_n < 0
บันทึกสถิติรายเดือนลง pattern_outcomes:
- count, win_rate, mean_return, std_return ต่อ (pattern, n, month)

G) ตัวกรองเบื้องต้น (Initial Filters)
- minRange, minTickVolume
- exclude_outlier_range (เช่น percentile 99)
- session filter (optional): Asian/London/NY
- proximity to S/R (optional): near_sr_only หรือ far_sr_only

H) Naming ใน SQLite
- pattern_counts.pattern ∈ {inside, outside, pin_bull, pin_bear, engulf_bull, engulf_bear}
- pattern_outcomes.pattern ใช้ชื่อเดียวกัน
- direction_rule ∈ {'none','bullish_up','bearish_down'} สำหรับการวัดผลตามทิศทาง

I) การทดสอบและการ validate
- สุ่มตัวอย่างแท่งที่ติดสัญญาณเพื่อดูความถูกต้อง
- ตรวจอัตราการเกิด (pattern_counts) ต่อเดือน ว่ามีค่าในช่วงสมเหตุสมผล
- ตรวจความสม่ำเสมอของ win_rate และ mean/std ว่าไม่ผิดปกติ (เช่น win_rate > 1 หรือ < 0)

J) ขยายผลสำหรับคอนเท็กซ์ (ถ้าต้องการ)
- เพิ่มการคำนวณ tag context เช่น near_sr, htf_uptrend, volatility_regime
- บันทึกลง pattern_outcomes_context แยกต่างหากเพื่อความยืดหยุ่น
