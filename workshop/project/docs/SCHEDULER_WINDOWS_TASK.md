# Windows Task Scheduler (Initial Migration + Real-time Fetch)

เป้าหมาย (กลยุทธ์ใหม่)
- ทำ History Analyze แบบครั้งเดียว (Initial Migration) ต่อคู่เงิน/TF ที่กำหนด เพื่อประมวลผลข้อมูลย้อนหลังทั้งหมดให้ครบ
- หลังจากนั้น ให้รันเฉพาะ Real-time Fetch/Analyze แบบ incremental ต่อเนื่อง โดยอิงจากข้อมูลใหม่ที่ MT5 เขียนออกมาเท่านั้น

สคริปต์ที่ใช้
- workshop/project/scripts/run_all.ps1
  - ทำงาน: เรียก ETL (CSV→Parquet) และ Analyzer (ตรวจแพตเทิร์น+คำนวณ outcomes) ตามช่วงเวลาที่กำหนด
  - แนะนำใช้สำหรับ Initial Migration (ทำทีเดียวจนจบย้อนหลังทั้งหมด)
- workshop/project/scripts/run_month.ps1
  - ทำงาน: ประมวลผลทีละเดือน/พาร์ติชั่น เหมาะสำหรับการควบคุมช่วงเล็ก ๆ หรือ rerun เฉพาะเดือน
- Python ETL/Analyzer
  - ETL: workshop/project/src/etl/ingest_csv_to_parquet.py
  - Analyzer: workshop/project/src/analysis/analyze_patterns.py

ส่วนที่ 1: Initial Migration (ครั้งเดียว)
1) เปิด Task Scheduler → Create Task…
   - General: Name = "PA Initial Migration (EURUSD M1)", Run whether user is logged on or not, Run with highest privileges
2) Triggers: เลือกแบบ ONCE หรือกำหนดเวลารอบเดียว (เช่น คืนนี้ 02:00)
3) Actions: New…
   - Program/script: powershell.exe
   - Add arguments:
     -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\workshop\project\scripts\run_all.ps1" -Symbol "EURUSD" -Timeframe "M1" -Start "2020-01" -End "2025-12" -MaxPartitions 9999
   - Start in: C:\path\to\repo_root
4) Settings
   - Stop the task if it runs longer than: 4 hours (ปรับตามขนาดข้อมูล)
   - If the task fails, restart every: 30 minutes, Attempt: 3 times
5) เมื่อ Initial Migration เสร็จสมบูรณ์: Disable/ลบ Task นี้ เพื่อป้องกันการรันซ้ำ

ตัวอย่าง schtasks สำหรับ Initial Migration
```powershell
schtasks /Create /TN "PA_Initial_EURUSD_M1" ^
  /TR "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:\path\to\workshop\project\scripts\run_all.ps1\" -Symbol \"EURUSD\" -Timeframe \"M1\" -Start \"2020-01\" -End \"2025-12\" -MaxPartitions 9999" ^
  /SC ONCE /ST 02:00
```

ส่วนที่ 2: Real-time Fetch/Analyze (ต่อเนื่อง, incremental)
ข้อกำหนด
- ให้ MT5 เปิดอยู่และสคริปต์ Exporter (เช่น AIAnalyzer) เขียน CSV ใหม่ลง MQL5/Files อย่างต่อเนื่อง (ทุก 1–5 นาที)
- ETL/Analyzer จะรันแบบสั้น ๆ เพื่อ ingest/analyze เฉพาะข้อมูลใหม่

A) Task: Real-time ETL (อินเจสท์ข้อมูลใหม่)
1) Create Task → General: Name = "PA Realtime ETL (EURUSD M1)", Run whether user is logged on or not, Run with highest privileges
2) Triggers: New…
   - Schedule: Every 5 minutes (หรือ 1–15 นาที ตามทรัพยากร)
3) Actions:
   - Program/script: python.exe
   - Add arguments:
     "C:\path\to\workshop\project\src\etl\ingest_csv_to_parquet.py" --config "C:\path\to\workshop\project\config\config.json"
   - Start in: C:\path\to\repo_root
4) Settings:
   - Stop the task if it runs longer than: 15 minutes
   - If the task fails, restart every: 5 minutes, Attempt: 3 times

B) Task: Real-time Analyzer (วิเคราะห์เฉพาะพาร์ติชั่นล่าสุด)
1) Create Task → General: Name = "PA Realtime Analyzer (EURUSD M1)", Run whether user is logged on or not, Run with highest privileges
2) Triggers: New…
   - Schedule: Every 15 minutes (หรือ 15–30 นาที)
   - ตั้งให้เริ่มทำงานหลัง Real-time ETL ~2–3 นาที เพื่อให้มีไฟล์ Parquet ล่าสุด
3) Actions:
   - Program/script: python.exe
   - Add arguments:
     "C:\path\to\workshop\project\src\analysis\analyze_patterns.py" --config "C:\path\to\workshop\project\config\config.json"
   - Start in: C:\path\to\repo_root
4) Settings:
   - Stop the task if it runs longer than: 20 minutes
   - If the task fails, restart every: 5 minutes, Attempt: 3 times

ตัวอย่าง schtasks สำหรับ Real-time
```powershell
# รัน ETL ทุก 5 นาที
schtasks /Create /TN "PA_RT_ETL_EURUSD_M1" ^
  /TR "\"C:\\Python311\\python.exe\" \"C:\\path\\to\\workshop\\project\\src\\etl\\ingest_csv_to_parquet.py\" --config \"C:\\path\\to\\workshop\\project\\config\\config.json\"" ^
  /SC MINUTE /MO 5

# รัน Analyzer ทุก 15 นาที
schtasks /Create /TN "PA_RT_ANALYZE_EURUSD_M1" ^
  /TR "\"C:\\Python311\\python.exe\" \"C:\\path\\to\\workshop\\project\\src\\analysis\\analyze_patterns.py\" --config \"C:\\path\\to\\workshop\\project\\config\\config.json\"" ^
  /SC MINUTE /MO 15
```

แนวทาง Guardrails & Health-Check (สำคัญ)
- หลีกเลี่ยงการรันซ้อน (overlap): ตั้ง Settings ให้ไม่เริ่มงานใหม่ถ้างานเดิมยังไม่จบ หรือให้หยุดงานเดิมก่อน
- Log: บันทึก stdout/stderr ไปที่ workshop/logs/ พร้อม timestamp เพื่อตรวจสอบได้ง่าย
- Progress: ใช้ตาราง progress/jobs_state ใน SQLite เก็บ last_processed_ts/partition เพื่อให้ Analyzer รู้ว่าเคยทำถึงไหนแล้ว
- Dedup: ETL ใช้ DISTINCT/ORDER BY ts เพื่อลดการซ้ำ หาก CSV มีการ append รายครั้ง
- Scope: Real-time วิเคราะห์เฉพาะพาร์ติชั่นล่าสุด (เช่น month ปัจจุบัน) เพื่อลดเวลาและโอกาสชน

การตรวจสอบผลลัพธ์
- ตรวจไฟล์ SQLite ตามเส้นทางใน config (เช่น workshop/analysis.db) ว่ามี pattern_signals, pattern_outcomes ถูกเติมอย่างต่อเนื่อง
- ทำรายงานรวม (รายวัน/รายชั่วโมง/รายเดือน) จาก SQLite หรือส่งออก CSV/HTML ในช่วงเวลาที่ต้องการ

หมายเหตุ
- หากต้องการหยุด Real-time ชั่วคราว: Disable Tasks ที่ตั้งไว้ (ETL/Analyzer)
- หากเปลี่ยนคู่เงิน/TF: ทำ Initial Migration ครั้งเดียวสำหรับคู่เงิน/TF ใหม่ จากนั้นเปิด Real-time Tasks สำหรับชุดใหม่
