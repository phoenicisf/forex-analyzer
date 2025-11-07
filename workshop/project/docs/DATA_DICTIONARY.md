# Data Dictionary (CSV/Parquet/SQLite)

ภาพรวม
- เอกสารนี้สรุปคอลัมน์ของข้อมูลตั้งแต่ระดับ Raw (CSV) -> Parquet -> ผลลัพธ์ที่ Analyzer เขียนลง SQLite
- มีคอลัมน์อนุมาน/คำนวณ (derived features) ที่ใช้ตรวจแพตเทิร์นและวัดผล N-bars ahead
- มีข้อเสนอสำหรับตาราง/วิวเสริมเพื่อรองรับคอนเท็กซ์เพิ่มเติม (ไม่บังคับ)

A) Bars CSV (จาก MT5)
- Date: วันที่ (รูปแบบจาก MT5 เช่น YYYY.MM.DD)
- Time: เวลา (HH:MM หรือมีวินาที)
- Open, High, Low, Close: ราคา OHLC ต่อแท่ง
- TickVolume: ปริมาณ tick
- Spread: สเปรด (points)
- RealVolume: ปริมาณจริง (ถ้ามี)
หมายเหตุ: ใช้ ETL แปลงเวลาเป็น timestamp (UTC หรือโซนที่กำหนดใน config) และตรวจ/จัดเรียงตามเวลา

B) Ticks CSV (ถ้าใช้)
- Date, Time, Time_msc: เวลาและ millisecond
- Bid, Ask, Last: ราคาตามชนิด tick
- Volume: ปริมาณ
- Flags: สถานะ

C) Deals CSV (ถ้าใช้)
- Ticket, Order: หมายเลขกำกับ
- Date, Time: เวลา
- Type, Entry: ประเภท deal และทิศทางเข้า/ออก
- Lots: ขนาดสัญญา
- Price: ราคา
- Profit, Commission, Swap: กำไร/ค่าคอมมิชชั่น/สวอป
- Symbol: สัญลักษณ์

D) Parquet Bars (หลัง ETL)
- ts: timestamp ของแท่ง (แนะนำเป็น UTC)
- open, high, low, close, tick_volume, spread, real_volume (ถ้ามี)
- symbol, timeframe (จาก config)
- หมายเหตุ: แบ่งพาร์ทเป็นรายเดือน (YYYY/MM)

E) Derived Features สำหรับแพตเทิร์น
- range = high - low
- body = close - open
- bodyAbs = |body|
- bodyRatio = bodyAbs / range
- upperWick = high - max(open, close)
- lowerWick = min(open, close) - low
- upperWickRatio = upperWick / range
- lowerWickRatio = lowerWick / range
- (ตัวเลือก) atr_N = ค่า ATR ระยะ N แท่ง
- หมายเหตุ: ข้ามแท่งที่ range ≤ 0

F) การวัดผล N-bars ahead
- close_fwd_n = close ที่แท่งถัดไปอีก n (เช่น n=1,3,5)
- return_raw_n = close_fwd_n - close
- return_pips_n = return_raw_n / pip_size (ถ้ากำหนด pip_size ใน config)
- ชนะ (win) สำหรับ bullish: return_raw_n > 0, สำหรับ bearish: return_raw_n < 0

G) ตาราง SQLite (ตาม schema.sql)
1) partitions_progress
   - id (PK)
   - symbol, timeframe
   - year, month
   - kind: 'bars' | 'ticks' | 'deals'
   - status: 'pending' | 'processing' | 'done' | 'error'
   - last_offset (nullable)
   - last_processed_at (text)
   - UNIQUE(symbol, timeframe, year, month, kind)
   ใช้ติดตามสถานะ ETL/Analyzer ต่อพาร์ท

2) bars_monthly_summary
   - id (PK)
   - symbol, timeframe, year, month
   - start_ts, end_ts (text)
   - total_bars (int)
   - avg_close (real)
   - avg_range_pips (real)
   - avg_spread (real)
   - avg_tickvol (real)
   - UNIQUE(symbol, timeframe, year, month)
   สรุปเบื้องต้นของแท่งรายเดือน

3) pattern_counts
   - id (PK)
   - symbol, timeframe, year, month
   - pattern (text): inside | outside | pin_bull | pin_bear | engulf_bull | engulf_bear
   - count (int)
   - UNIQUE(symbol, timeframe, year, month, pattern)
   จำนวนการเกิดแพตเทิร์นต่อเดือน

4) pattern_outcomes
   - id (PK)
   - symbol, timeframe, year, month
   - pattern (text)
   - n (int): ระยะ N-bars ahead
   - count (int)
   - win_rate (real)
   - mean_return (real)
   - std_return (real)
   - direction_rule (text): 'none' | 'bullish_up' | 'bearish_down'
   - UNIQUE(symbol, timeframe, year, month, pattern, n, direction_rule)
   ผลลัพธ์การวัด N-bars สำหรับแต่ละแพตเทิร์น

H) ตาราง/วิว เสนอเพิ่มเติม (ตัวเลือก)
- sr_levels (แนวรับ–แนวต้าน)
  - id (PK), symbol, timeframe_src, year, month
  - level_price (real), role ('support'|'resistance')
  - touches_count (int), strength_score (real)
  - first_ts, last_ts, broken_ts (nullable)
  ใช้เก็บระดับสำคัญเพื่อทำเงื่อนไข near S/R

- pattern_outcomes_context
  - id (PK)
  - symbol, timeframe, year, month, pattern, n
  - context_tag (text): near_sr | far_sr | htf_uptrend | asian_session | ...
  - count, win_rate, mean_return, std_return
  ผลลัพธ์แบบติด tag คอนเท็กซ์

- View: pattern_outcomes_quarterly (สรุปถ่วงน้ำหนักรายไตรมาส)
  แนวคิดคำนวณ:
  - quarter = CASE WHEN month IN (1,2,3) THEN 1 WHEN month IN (4,5,6) THEN 2 WHEN month IN (7,8,9) THEN 3 ELSE 4 END
  - total_samples = SUM(count)
  - win_rate_weighted = SUM(win_rate*count)/SUM(count)
  - mean_return_weighted = SUM(mean_return*count)/SUM(count)
  - std_return_pooled ≈ sqrt((Σ count*(std_return^2 + mean_return^2) − total_samples*(mean_return_weighted^2)) / total_samples)
  หมายเหตุ: สูตร std pooled เป็นการประมาณเพื่อใช้งานเชิงสรุป

I) Index/Views ที่แนะนำ
- Index: pattern_outcomes(symbol,timeframe,pattern,n,year,month,direction_rule)
- Views สำหรับรายงาน: monthly_bar_summary_view, pattern_counts_view, pattern_outcomes_view

J) การแปลงหน่วย (Pips/Points)
- กำหนด pip_size ใน config ตามคู่เงิน/สินทรัพย์ เพื่อคำนวณ return_pips ได้ถูกต้อง
- spread ควรพิจารณาเมื่อประเมิน expectancy ที่ใกล้เคียงการเทรดจริง

K) คุณภาพข้อมูล & ข้อควรระวัง
- ตรวจค่า OHLC ว่ามี range > 0 และเวลาต่อเนื่อง
- จัดการข้อมูลซ้ำ (dedup) ใน ETL
- ระวังความแตกต่างของ timezone/วันหยุด/ตลาดปิด
