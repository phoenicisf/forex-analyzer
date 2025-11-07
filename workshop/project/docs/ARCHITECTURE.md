# สถาปัตยกรรมระบบ (Architecture)

วัตถุประสงค์
- เก็บข้อมูลจาก MT5 (Bars/Ticks/Deals) อย่างเป็นระบบ
- แปลงและจัดระเบียบข้อมูลให้พร้อมวิเคราะห์ (CSV -> Parquet แบบแบ่งพาร์ทตามเวลา)
- ตรวจจับแพตเทิร์น Price Action และคอนเท็กซ์ที่เกี่ยวข้อง (เช่นแนวรับแนวต้าน/โซน/แนวโน้ม/ช่วงเวลา)
- วัดผล N-bars ahead, จัดเก็บสรุปลงฐานข้อมูล (SQLite) เพื่อ Query/รายงาน/AI MCP ใช้งาน
- รันอัตโนมัติแบบทำทีละพาร์ท (resume ได้), และสร้างรายงานสรุป

ภาพรวม Flow (End-to-End)
1) MT5 Data Export
   - แหล่งข้อมูล: MT5 (History Center/API ผ่าน MQL5)
   - ส่งออกข้อมูล Bars/Ticks/Deals เป็น CSV ไปที่โฟลเดอร์ MQL5/Files
   - ตัวอย่างสคริปต์ MQL5: ใช้ CopyRates / CopyTicksRange / HistorySelect

2) ETL (CSV -> Parquet)
   - สคริปต์: src/etl/ingest_csv_to_parquet.py
   - งาน: อ่าน CSV, ตรวจ schema/ชนิดข้อมูล, แปลง timestamp, sort/dedup, เขียนเป็น Parquet
   - การแบ่งพาร์ท:
     - Bars: รายเดือน (YYYY/MM)
     - Ticks: รายวัน (YYYY/MM/DD)
     - Deals: รายเดือน (YYYY/MM)
   - ประโยชน์ของ Parquet: บีบอัด, columnar, อ่านเร็ว, ตัดช่วงเวลา/คอลัมน์ได้คล่อง
   - การตั้งค่าผ่าน config: workshop/project/config/config.json (paths, symbol/timeframe, patterns, partitioning, analyzer, scheduler, logging)

3) Analyzer (ตรวจแพตเทิร์น + วัดผล)
   - สคริปต์หลัก: src/analysis/analyze_patterns.py
   - อ่าน Parquet ทีละพาร์ท -> ตรวจแพตเทิร์น Inside/Outside/Pin Bar/Engulfing ตามพารามิเตอร์ใน config
   - วัดผล N-bars ahead (เช่น 1,3,5) และคำนวณ: count, win_rate, mean_return, std_return
   - Direction-specific: สำหรับ bullish ชนะเมื่อ return>0, bearish ชนะเมื่อ return<0 (เก็บในคอลัมน์ direction_rule)
   - เขียนผลลง SQLite ตาม schema: workshop/project/sql/schema.sql
     - partitions_progress: ติดตามสถานะพาร์ท (pending/processing/done/error)
     - bars_monthly_summary: สรุปสถิติเบื้องต้นรายเดือนของ Bars
     - pattern_counts: จำนวนการเกิดแพตเทิร์นรายเดือน
     - pattern_outcomes: ผลลัพธ์ N-bars ต่อแพตเทิร์น/เดือน
   - ข้อดีการแยก ETL กับ Analyzer: ปรับพารามิเตอร์วิเคราะห์ได้เร็วโดยไม่ต้องอ่าน CSV ใหม่, debug ง่าย, ทำงานทีละพาร์ทเร็วกว่า

4) ส่วนขยายการวิเคราะห์ (ทำเพิ่มได้เมื่อพร้อม)
   - แนวรับ–แนวต้าน (Support/Resistance) ด้วยวิธี: Fractals/ZigZag/Clustering โซนราคา
   - โครงสร้างราคา/แนวโน้ม: HH/HL/LL/LH, Break of Structure (BOS), Trendline/Channel
   - Regime ความผันผวน: ATR/StdDev -> จัด Low/Medium/High volatility
   - Session/Time: Asia/London/NY และชั่วโมง/วันในสัปดาห์
   - Fair Value Gap/Imbalance (แบบง่าย) และ Range Narrow/Expansion (NR4/NR7)
   - Multi-timeframe alignment: เทรด TF ทำงานที่สอดคล้องกับ HTF bias
   - Risk/Reward outcomes: SL/TP แบบ 1R/2R เทียบกับการวัดผลด้วย return
   - การจัดเก็บผลแบบคอนเท็กซ์: แนะนำเพิ่มตารางเสริม (ไม่บังคับ)
     - sr_levels: เก็บระดับราคา/โซน + touches/strength_score
     - pattern_outcomes_context: เก็บผล N-bars โดยติด tag context (near_sr, htf_uptrend, asian_session, …)

5) Orchestration & Scheduler (สอดคล้องกับกลยุทธ์ Migration + Real-time)
   - แนวทางโดยรวม: ทำ Initial Migration สำหรับแต่ละสัญลักษณ์/TF เพียงครั้งเดียว แล้วตั้ง Scheduler ให้ทำ Real-time แบบ incremental เฉพาะพาร์ทใหม่
   - Initial Migration (ครั้งแรกต่อ symbol/timeframe):
     - สคริปต์: src/orchestration/process_next_partition.py
       - ดึงรายการพาร์ทที่มีใน Parquet -> seed ลง partitions_progress
       - เลือกพาร์ท pending มาทำงานทีละรายการ -> เรียก src/analysis/analyze_patterns.py -> อัปเดตสถานะ (processing -> done/error)
     - PowerShell: workshop/project/scripts/run_all.ps1 ใช้สำหรับทำ ETL -> Orchestrator -> Report ครบชุดในครั้งแรก
     - หลังจบการ migration ให้ถือเป็น baseline และไม่ re-process พาร์ทที่สถานะ done
   - Real-time Scheduler (หลัง migration):
     - ETL append-only: src/etl/ingest_csv_to_parquet.py อ่าน CSV ใหม่จาก MQL5/Files และสร้างพาร์ทใหม่เท่านั้น
     - Orchestration: process_next_partition.py เลือกเฉพาะพาร์ท pending ใหม่ ไม่แตะพาร์ทที่ทำเสร็จแล้ว
     - Analyzer incremental: analyze_patterns.py รันเฉพาะพาร์ทใหม่เพื่อวัดผลและบันทึกลง SQLite
     - การตั้งค่า Task Scheduler (Windows): อ้างอิง workshop/project/docs/SCHEDULER_WINDOWS_TASK.md
       - งาน ETL: ความถี่เหมาะสมกับตลาด (เช่น ทุก 15 นาที/ทุกชั่วโมง)
       - งาน Analyzer: รายชั่วโมง/รายวัน ตามความต้องการสรุปผล
     - Guardrails/Health-check:
       - logging แยกไฟล์, retry/backoff, resume ได้เมื่อเครื่องรีสตาร์ท
       - จำกัด max_partitions ต่อรอบ เพื่อควบคุมเวลาและทรัพยากร
   - สคริปต์อัตโนมัติ (PowerShell) เพิ่มเติม:
     - workshop/project/scripts/run_month.ps1 (วิเคราะห์เฉพาะเดือน/ปี/TF)

6) Reporting
   - สคริปต์: src/report/generate_reports.py
   - ดึงผลจาก SQLite -> สรุป CSV/HTML:
     - bars_monthly_summary.csv, pattern_counts.csv, pattern_outcomes.csv
   - สามารถขยายทำรายงานรายไตรมาส/ราย session/Top-K patterns ได้

7) MCP/AI Integration & Token Guardrails
   - วิธีใช้ AI กับข้อมูลอย่างประหยัด token:
     - ดึงผลสรุปเฉพาะช่วง (เช่นรายไตรมาสล่าสุด 8 ไตรมาส) ไม่ดึงดิบทั้งหมด
     - ใช้ Views/Materialized summaries ใน SQLite สำหรับ query ที่ใช้บ่อย
     - จำกัด max_rows/max_months และส่งเฉพาะคอลัมน์สำคัญ (symbol,timeframe,year,month,pattern,win_rate,mean,std)
   - แนวทางสรุปถ่วงน้ำหนักรายไตรมาส (ตัวอย่าง):
     - total_samples = SUM(count)
     - win_rate_weighted = SUM(win_rate*count)/SUM(count)
     - mean_return_weighted = SUM(mean_return*count)/SUM(count)
     - std_return_pooled ≈ sqrt((Σ n_i*(sd_i^2 + m_i^2) − N*M^2)/N)
   - AI สามารถเรียกสคริปต์สรุป/Query ผ่าน MCP แล้วคืนผล JSON/CSV ขนาดเล็ก

โครงสร้างไฟล์สำคัญ
- สคริปต์ ETL: workshop/project/src/etl/ingest_csv_to_parquet.py
- สคริปต์ Analyzer: workshop/project/src/analysis/analyze_patterns.py
- สคริปต์ Orchestration: workshop/project/src/orchestration/process_next_partition.py
- สคริปต์ Reports: workshop/project/src/report/generate_reports.py
- สคริปต์ PowerShell: workshop/project/scripts/run_all.ps1, run_month.ps1
- Config: workshop/project/config/config.json (ปรับพารามิเตอร์ทั้งหมด)
- Schema DB: workshop/project/sql/schema.sql (SQLite)
- สเปกแพตเทิร์น: workshop/project/docs/PATTERNS_SPEC.md
- พจนานุกรมข้อมูล: workshop/project/docs/DATA_DICTIONARY.md

Quick Start
- ติดตั้งไลบรารี: pip install -r workshop/project/requirements.txt
- Initial Migration (ครั้งแรกต่อสัญลักษณ์/TF):
  - เตรียม CSV จาก MT5 (Bars/Ticks/Deals) ลง MQL5/Files
  - ETL: python workshop/project/src/etl/ingest_csv_to_parquet.py --config workshop/project/config/config.json --kind bars
  - Orchestrator: python workshop/project/src/orchestration/process_next_partition.py --config workshop/project/config/config.json
  - รายงาน: python workshop/project/src/report/generate_reports.py --config workshop/project/config/config.json
- Real-time Scheduler:
  - ดูคู่มือ: workshop/project/docs/SCHEDULER_WINDOWS_TASK.md
  - ตั้ง Task 2 งาน: ETL (append-only) + Analyzer (incremental)

ข้อควรระวัง & แนวทางปรับแต่ง
- ตั้งค่าพาร์ทให้พอดีกับปริมาณข้อมูล (Bars รายเดือน, Ticks รายวัน) เพื่อให้ RAM ใช้ไม่สูง
- ระวังค่าลอยตัว/แท่งที่ range ≤ 0 ให้ข้ามหรือแก้ไข
- ปรับ thresholds ของแพตเทิร์นใน config เพื่อทำ backtest/optimization
- เสริม Index/Views ใน SQLite สำหรับ Query เร็วขึ้น (เช่น index: symbol,timeframe,pattern,n,year,month,direction_rule)

Roadmap (แผนต่อยอด)
- เพิ่มตาราง/วิวสำหรับรายไตรมาส (pattern_outcomes_quarterly)
- เพิ่มการวิเคราะห์ S/R และ context outcomes
- รองรับหลายสัญลักษณ์/TF พร้อมกัน
- ตัวเลือกฐานข้อมูลสำหรับงาน ML: DuckDB/Postgres/ClickHouse/TimescaleDB (ขึ้นกับขนาดและการใช้งาน)
- เพิ่มชุดคำสั่ง Query presets สำหรับ AI/MCP
