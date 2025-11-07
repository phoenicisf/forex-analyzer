# Price Action Analytics Project (Workshop)

โปรเจกต์นี้รวบรวมไฟล์และโครงสร้างสำหรับระบบวิเคราะห์ Price Action ขนาดใหญ่ ประกอบด้วย ETL (CSV -> Parquet), Analyzer (ตรวจสัญญาณและวัดผล), Scheduler (ทำงานอัตโนมัติ), และ SQLite/CSV สำหรับสรุปผล

โครงสร้าง
- docs/: คู่มือและสเปค
- config/: เทมเพลตคอนฟิก
- sql/: สคีมา SQLite
- src/: โค้ด ETL และ Analyzer
- scripts/: สคริปต์ PowerShell ตัวอย่างสำหรับรัน
- requirements.txt: ไลบรารีที่ต้องติดตั้ง

เริ่มต้นใช้งาน (Step-by-step Run บน Windows)

1) ติดตั้ง Python และไลบรารีที่ต้องใช้
   - เวอร์ชันแนะนำ: Python 3.10+ (หรือใหม่กว่า)
   - ติดตั้งไลบรารี:
     ```powershell
     pip install -r .\workshop\project\requirements.txt
     ```

2) เตรียมไฟล์คอนฟิก
   - คัดลอกเทมเพลตเป็นไฟล์ใช้งานจริง:
     ```powershell
     Copy-Item .\workshop\project\config\config.template.json .\workshop\project\config\config.json
     ```
   - เปิดแก้ไข .\workshop\project\config\config.json โดยกำหนดค่าให้ถูกต้อง โดยเฉพาะ:
     - data_dir: โฟลเดอร์ CSV ที่ MT5 เขียนออก (เช่น MQL5/Files)
     - parquet_dir: โฟลเดอร์ปลายทางสำหรับไฟล์ Parquet ที่ระบบจะสร้าง
     - sqlite_path: เส้นทางไฟล์ฐานข้อมูล SQLite สำหรับเก็บผลลัพธ์วิเคราะห์
     - symbol, timeframes: คู่สกุลและ TF ที่ต้องการวิเคราะห์ (เช่น EURUSD, ["M1"])
     - analyzer.next_bars / pinbar / engulfing: พารามิเตอร์การวัดผลและนิยามแพตเทิร์น

3) รัน ETL (CSV → Parquet แบบพาร์ติชั่น)
   - คำสั่งตัวอย่าง (จากโฟลเดอร์ Terminal/...):
     ```powershell
     python .\workshop\project\src\etl\ingest_csv_to_parquet.py --config .\workshop\project\config\config.json
     ```
   - สิ่งที่คาดหวัง:
     - สร้างพาธ Parquet ภายใต้ parquet_dir ตามโครงสร้าง: <symbol>/bars/<TF>/year=YYYY/month=MM/*.parquet
     - หากมี Ticks/Deals จะสร้างใน <symbol>/ticks และ <symbol>/deals ตามพาร์ติชั่นที่กำหนด

4) รัน Analyzer (อ่าน Parquet → ตรวจแพตเทิร์น → วัดผล N-bars → SQLite)
   - คำสั่งตัวอย่าง:
     ```powershell
     python .\workshop\project\src\analysis\analyze_patterns.py --config .\workshop\project\config\config.json
     ```
   - สิ่งที่คาดหวัง:
     - ตาราง pattern_signals และ pattern_outcomes ถูกสร้าง/เพิ่มข้อมูลในไฟล์ SQLite ตามค่า sqlite_path
     - ผลสรุปจะถูกบันทึกต่อพาร์ติชั่น และสามารถนำไปทำรายงานรวมภายหลังได้

5) ตั้ง Schedule (อัตโนมัติทุกคืน/ทุกชั่วโมง)
   - ใช้คู่มือใน docs/SCHEDULER_WINDOWS_TASK.md
   - แนวทางทั่วไป: ตั้ง Task A (ETL) และ Task B (Analyzer) โดยเว้นระยะเวลาให้ ETL ทำงานเสร็จก่อน
   - ตั้งค่า retry/timeout ตาม run_window_minutes ใน config

6) ตรวจสอบผลลัพธ์และ Troubleshooting
   - หาก Analyzer แจ้ง [SKIP] ไม่มีคอลัมน์เวลา ts/time ให้ตรวจสอบว่า ETL สร้างคอลัมน์ ts แล้ว หรือว่าชื่อคอลัมน์เวลาของ CSV เป็น time
   - หากผลลัพธ์ count ต่ำผิดปกติ ให้ตรวจสอบพารามิเตอร์แพตเทิร์นใน config (เช่น body_ratio_max, wick_ratio_min)
   - ตรวจสอบสิทธิ์และพาธของ data_dir ว่าชี้ไปที่โฟลเดอร์ MQL5/Files ที่มีไฟล์ CSV จริง

ทางเลือกสำหรับการตรวจเร็ว (Ad-hoc)
   - ใช้สคริปต์ PowerShell workshop/analyze_jan2025.ps1 เพื่อทดลองวิเคราะห์เฉพาะเดือน 01/2025 แบบรวดเร็ว
   - เหมาะสำหรับ sanity-check ก่อนรัน ETL/Analyzer ครบทั้งปี/หลายพาร์ติชั่น

หมายเหตุ
- ไฟล์ MT5 Exporter (EURUSD_Data_Extractor.mq5) อยู่ใน MQL5/Scripts และเขียน CSV ไปยัง MQL5/Files
- สามารถใช้ PowerShell analyze_jan2025.ps1 เป็นตัวอย่างการตรวจเร็ว
