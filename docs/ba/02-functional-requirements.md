# 02 — Functional Requirements: PhoenicisNex

> **Phase:** Phase 1A (BA Requirements Discovery) — Doc 2/5
> **Author:** BA agent (`/ba` workflow, v1.2)
> **Last updated:** 2026-05-01
> **Reads:** `01-project-brief.md` (goals, scope, glossary)
> **Audience:** Architect (Phase 1B) — แปลง requirements เหล่านี้เป็น component design

## TL;DR

เอกสารนี้แตก business goals 4 ข้อ (G1-G4 ใน `01`) เป็น **8 epics + 41 user stories** พร้อม MoSCoW priority และ Given/When/Then acceptance criteria. ทุก user story map กลับไป pain point ใน `improvement-targets.md` และ CodeWiki section/line ที่เกี่ยวข้อง. **MVP signal** ของ user (2026-05-01) ทำให้ลด `Should-Have` เหลือเฉพาะที่ส่งผลโดยตรงต่อ G1 (Maintainability) + G3 (Behavioral Preservation) — perf optimizations และ UX-only items ตกชั้นเป็น `Could-Have` หรือ `Won't-Have`. **All FR-domain open questions ✅ resolved 2026-05-01:** OQ-3 = JSON-lines (BA default), OQ-8 = **DELETE Slot U** (user override of BA default — codebase สะอาดขึ้น).

**Distribution count:** Must 37 / Should 2 / Could 2 / Won't 0 (Won't อยู่ใน `01-project-brief.md § 6`)

---

## 1. How to read this document

ทุก user story ใช้ format มาตรฐาน:

```
**FR-X.Y:** As a [Actor], I want [goal], so that [benefit].
- **Priority:** Must / Should / Could
- **Why:** [Thai rationale — ถ้าไม่มี ธุรกิจเจ็บตรงไหน]
- **Source:** CodeWiki §N (`:line`) | improvement-targets PN.N | foundation-input-sources doc
- **Goal trace:** G1 / G2 / G3 / G4 (จาก `01 § 3`)
- **Acceptance Criteria:**
  - **AC-X.Y.1:** Given [context]
    When [action]
    Then [expected result]
```

ทุก AC ต้อง testable ผ่าน Strategy Tester regression run, trade journal inspection, หรือ MT5 native ตรวจ `OnInit` log.

**Actors** ใน user stories อ้างอิง `01 § 4` — ส่วนใหญ่คือ `Trader` (set parameters, attach EA, review journal), `MT5 Platform` (executes OnTick, persists state), `Strategy Tester` (runs regression).

---

## 2. Epic E1 — Configuration & Tuning

ปัจจุบัน user ปรับ parameter ใดๆ ต้อง edit code → recompile → restart MT5 → state อาจ corrupt; Strategy Tester optimization ทำไม่ได้เลยเพราะ parameter ไม่อยู่ใน input dialog. Epic นี้คือเหตุผลหลักที่ user ตัดสินใจ rewrite ทั้งโปรเจค.

### FR-1.1 — Promote magic numbers to MT5 native `input`

**As a** Trader, **I want** ปรับ ≥ 80 parameters ของ EA ผ่าน MT5 native input dialog ก่อน attach กับ chart, **so that** ผมไม่ต้อง edit code + recompile + restart EA ทุกครั้งที่อยาก tune.

- **Priority:** Must
- **Why:** ปัญหานี้เป็น root cause ที่ทำให้ user เลือก rewrite (Direction D1) — tune parameter ทีต้องใช้เวลา 5–10 นาที/รอบ + เสี่ยง state corruption ตอน restart; Strategy Tester optimization sweep ใช้ไม่ได้เลย
- **Source:** CodeWiki §1.3, §6.1, §6.2 HIGH; improvement-targets P1.1
- **Goal trace:** G1
- **Acceptance Criteria:**
  - **AC-1.1.1:** Given EA compiled binary `.ex5`
    When user attach EA กับ EURUSD H4 chart
    Then MT5 input dialog แสดงพารามิเตอร์อย่างน้อย **80 ตัว** ครอบคลุมทุก magic number ใน CodeWiki §6.1
  - **AC-1.1.2:** Given default input set (ทุก parameter เป็น default value)
    When user run EA Strategy Tester ด้วย period 2021-2025 EURUSD H4 บน FBS-Real Build 5833 ($1k init, 1:500, 1-min OHLC tick model)
    Then ผล Net Profit deviation จาก baseline `$24,271,276.63` อยู่ใน **±25%** (ตาม regression contract `trading-baseline.md`)
  - **AC-1.1.3:** Given parameter ใดๆ ที่ user เปลี่ยนค่าใน input dialog
    When user reattach EA หรือ restart Strategy Tester
    Then EA ใช้ค่าใหม่ทันทีโดย user **ไม่ต้อง recompile**

### FR-1.2 — Symbol whitelist guard

**As a** Trader, **I want** EA ปฏิเสธการ attach กับ chart ที่ไม่ใช่ EURUSD, **so that** ผมไม่เปิด trade ผิด symbol โดยบังเอิญตอน drag-drop EA

- **Priority:** Must
- **Why:** EA เดิม wired กับ EURUSD H4 — ทุก threshold ของ slot tuned สำหรับคู่นี้; ติดผิด chart = trade ผิด symbol = ขาดทุนทันที (CodeWiki §6.3 P1.7)
- **Source:** CodeWiki §6.3; improvement-targets P1.7
- **Goal trace:** G4 (safety)
- **Acceptance Criteria:**
  - **AC-1.2.1:** Given EA attached กับ chart ที่ `_Symbol == "EURUSD"`
    When `OnInit` ทำงาน
    Then EA load สำเร็จ + เริ่ม OnTick ตามปกติ
  - **AC-1.2.2:** Given EA attached กับ chart ที่ `_Symbol != "EURUSD"` (เช่น GBPUSD, XAUUSD)
    When `OnInit` ทำงาน
    Then EA reject load + log error message ระบุชื่อ symbol ที่ผิด + EA ไม่เริ่ม OnTick
  - **AC-1.2.3:** Given user ต้องการขยาย whitelist ในอนาคต (Phase 2)
    When user set `input string InpAllowedSymbols = "EURUSD"` (default) หรือเพิ่มหลายตัวคั่นด้วย comma
    Then guard logic อ่าน list นี้ → match กับ `_Symbol` (Phase 1 ใส่ field แต่ list = "EURUSD" เท่านั้น)

### FR-1.3 — Strategy Tester optimization compatibility

**As a** Trader, **I want** ทุก ≥ 80 input parameter ของ EA enumerate-able ใน Strategy Tester optimization sweep, **so that** ผมหา optimum value ผ่าน MT5 native sweep ได้โดยไม่ต้องเขียน harness เอง

- **Priority:** Must
- **Why:** ปัจจุบันทำ sweep ไม่ได้เลย (parameter ไม่มีใน input dialog) — user เสีย ability ที่ MT5 ให้ฟรี; Phase 2 walk-forward จะต่อยอดจากนี้
- **Source:** CodeWiki §7.2 (parameter optimization sweep config); improvement-targets P1.1
- **Goal trace:** G1
- **Acceptance Criteria:**
  - **AC-1.3.1:** Given EA compiled กับ ≥ 80 inputs (ตาม FR-1.1)
    When user เปิด Strategy Tester → Settings → Inputs tab
    Then ทุก input ปรากฏพร้อมช่อง Start/Step/Stop ครบ (สำหรับ optimization mode)
  - **AC-1.3.2:** Given user run Strategy Tester ใน "Slow complete algorithm" mode บน parameter อย่างน้อย 1 ตัว
    When run จบ
    Then optimization result table มี row ของแต่ละ combination + แสดง Net Profit / PF / DD ของแต่ละ combination

### FR-1.4 — Input validation in OnInit

**As a** Trader, **I want** EA ตรวจสอบความสมเหตุสมผลของ input parameter ตอน boot, **so that** ผมไม่ใส่ค่าผิด (เช่น negative risk, zero divisor) แล้ว EA crash หรือเทรดผิด

- **Priority:** Must
- **Why:** Solo operator ไม่มี QA — ต้อง fail-fast ที่ boot; ปัจจุบัน EA ไม่ validate อะไรเลย (CodeWiki §5.4 OnInit)
- **Source:** CodeWiki §5.4 OnInit; improvement-targets P1.8 (extends to inputs)
- **Goal trace:** G1, G4
- **Acceptance Criteria:**
  - **AC-1.4.1:** Given input ที่มี constraint (เช่น `MainRiskRatio > 0`, `LimitMaxLotSizeRatio > 0`, `FIDValue ∈ [1..100]`)
    When `OnInit` ทำงาน + พบ input ออกจาก range
    Then EA reject load + log error message ระบุ field name + invalid value + expected range
  - **AC-1.4.2:** Given input set ที่ valid ทุกตัว
    When `OnInit` ทำงาน
    Then validation pass + EA log "Input validation: OK" + เริ่ม OnTick

---

## 3. Epic E2 — Slot Strategy Engine

EA เดิมมี 17+ slot ที่ overlap, มี shared magic, มี orphan function — ต้องเก็บ behavioral 1:1 (ตาม Direction D1, D2) แต่ refactor architecture ให้ Audit/AI agent ทำงานกับมันได้.

### FR-2.1 — Preserve all 17+ slots (entry + exit) 1:1

**As a** Trader, **I want** EA ใหม่มีทุก slot ของ EA เดิม (`C`, `D`, `F`, `J`, `H`, `K`, `G`, `G2`, `GO`, `M`, `L`, `LX`, `Q`, `R`, `I`, `P`, `T`, `S`, `B`, `BR`, `BI`) ทำงานเหมือนเดิม, **so that** Backtest result deviation อยู่ใน 25% budget

- **Priority:** Must
- **Why:** Direction D2 = "เก็บทั้ง 17+ ก่อน — ตัด/rename หลังพิสูจน์ behavioral baseline"; ตัด slot ใดๆ ก่อน QA = invalidate baseline contract; ไม่มี slot ไหนที่ confirmed redundant ก่อน live test
- **Source:** CodeWiki §1.5, §3 (per-slot signal logic); ideation-brief D2; improvement-targets P1.6
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-2.1.1:** Given EA ใหม่ run ด้วย default input set
    When QA รัน Strategy Tester regression (period + tick model เดียวกับ baseline)
    Then **ทุก slot ที่ baseline มี ≥ 1 trade ใน 5-yr period** ปรากฏใน rewrite trade list อย่างน้อย 1 trade; slot ที่ baseline = 0 trades (per per-slot extraction ใน NFR-1.6) **ไม่บังคับ** + reuse tolerance rule ของ NFR-1.6 (absolute fallback ±2 trades สำหรับ slot ที่ baseline < 5 trades). Slot `U` ไม่ปรากฏ (deleted per FR-2.2)
  - **AC-2.1.2:** Given trade list จาก regression run
    When QA นับ trade count ต่อ slot เทียบกับ baseline distribution
    Then drift ของแต่ละ slot อยู่ใน **±15%** (per OQ-7 ✅ resolved 2026-05-01); drift > **30%** trigger investigation flag (signal logic อาจหาย)
  - **AC-2.1.3:** Given trade journal entry ของแต่ละ trade (FR-4.1)
    When QA filter ด้วย slot ID
    Then สามารถ retrieve signal context + indicator snapshot ที่ทำให้ slot นั้นเปิด trade ได้ครบ

### FR-2.2 — Slot U deleted from rewrite ✅

**As a** Trader, **I want** Slot U **ไม่ปรากฏ**ใน rewrite — ไม่ copy `BusinessLogic_U` / `ExtraTakeProfit_U` มา + ไม่ reserve `MagicU` (=220), **so that** codebase สะอาดขึ้น + ไม่มี dead code ที่ต้อง maintain

- **Priority:** Must
- **Why:** User decision 2026-05-01 (OQ-8 = **delete**) — Slot U ใน EA เดิม disabled อยู่แล้ว (call site comment-out ใน OnTick) → ไม่เคยเทรดเลย → behavior baseline ไม่ขึ้นกับ Slot U → การลบไม่กระทบ G3 (regression contract); ลบ = clean code + ลด maintenance overhead. ถ้าอนาคตอยากเพิ่ม U กลับ = ต้องเขียนใหม่จาก CodeWiki §3 spec (cost ยอมรับได้เพราะ Phase 2 timeline)
- **Source:** CodeWiki §1.5 (`U` row), §6.2 (Slot U dead code); ideation-brief OQ-8 → user resolved 2026-05-01: **delete**
- **Goal trace:** G3 (preservation), G1 (codebase hygiene)
- **Acceptance Criteria:**
  - **AC-2.2.1:** Given EA source code (Phase 1)
    When developer search source ทั้งหมดสำหรับ `BusinessLogic_U`, `ExtraTakeProfit_U`, `MagicU`
    Then **ไม่พบ** symbol เหล่านี้เลยใน source — ไม่มี file ที่ define + ไม่มี call site ใน orchestrator
  - **AC-2.2.2:** Given EA ใหม่ run regression
    When QA ตรวจ trade list สำหรับ magic 220
    Then ไม่มี trade ที่มี `Magic == 220` ตลอด 5-yr period (เหมือน baseline เพราะของเดิมก็ไม่ทำงาน)
  - **AC-2.2.3:** Given Magic Number Pool ของ rewrite (ตาราง BR-1.1)
    When inspect magic range
    Then magic 220 ไม่ถูก reserve (available สำหรับ Phase 2 ถ้าจะ revive U หรือเพิ่ม slot ใหม่)

> ✅ **OQ-8 resolved 2026-05-01:** User เลือก **delete** — ไม่ copy Slot U code มาเลย

### FR-2.3 — Slot orchestrator: exit-before-entry pass per tick

**As a** MT5 Platform (system actor), **I want** OnTick orchestrator เรียก `manageExits()` ของทุก slot ก่อน เรียก `evaluate()` ของทุก slot, **so that** Behavioral parity ตรงกับ EA เดิม (CodeWiki §2.2)

- **Priority:** Must
- **Why:** EA เดิม run exit pass ก่อน entry pass — ถ้าสลับ order = trade decision ใช้ portfolio state ที่ stale → behavioral drift; AI Reconstruction Note ใน CodeWiki §2 เน้นข้อนี้
- **Source:** CodeWiki §2.2, §7.2 AI Reconstruction Note
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-2.3.1:** Given slot orchestrator design + slot list
    When developer trace OnTick execution order
    Then ทุก `ExtraTakeProfit_X` (manageExits equivalent) call เกิดขึ้น **ก่อน** ทุก `BusinessLogic_X` (evaluate equivalent) call ในแต่ละ tick
  - **AC-2.3.2:** Given QA regression run
    When เปรียบเทียบ trade timestamp pattern ของ rewrite กับ baseline
    Then ไม่พบ pattern ที่ entry เกิดก่อน exit ที่ควรจะปิดในวันเดียวกัน

### FR-2.4 — Cross-slot dependency graph explicit

**As a** Trader, **I want** EA expose dependency relations (`G→GO`, `B→BR`, `B→BI`, `J→C/D`, `S→L/K`, `LX→L pyramid`) เป็น explicit `dependsOn(otherSlot)` field ใน slot abstraction, **so that** ผมหรือ AI agent ที่ maintain โค้ดต่อไปไม่ refactor 1 slot โดยลืมว่ามี slot อื่นอ้างถึง

- **Priority:** Must
- **Why:** CodeWiki §7.2 → "Decouple G→GO, B→BR/BI, J→C/D, S→L/K — model these as explicit `Slot::dependsOn(otherSlot)` edges" — ปัจจุบัน dependency กระจายใน comment string parsing + helper calls, AI agent + human reviewer มองไม่เห็น
- **Source:** CodeWiki §3 (per-slot logic), §7.2 (improvement); improvement-targets P1.6
- **Goal trace:** G1, G3
- **Acceptance Criteria:**
  - **AC-2.4.1:** Given slot abstraction definition (จาก SD/TD)
    When developer query `slot.dependsOn()`
    Then ได้ list ของ slot อื่นที่ slot นี้อ้างถึง (ตามตารางใน CodeWiki §3 + §7.2)
  - **AC-2.4.2:** Given orchestrator startup
    When orchestrator topo-sort slot list ตาม dependency graph
    Then ลำดับ entry pass สอดคล้องกับ EA เดิม (CodeWiki §2.2 OnTick order: C/D/J/H/K/G/G2/I/M/L/LX/Q/R/B/BI ก่อน S/T/P) — **note:** Slot **F**, **GO**, **BR** ไม่อยู่ใน main topo-sort เพราะถูก chain/triggered จาก slot อื่นใน sub-call: F evaluate ภายใน C/D's evaluate path (chain เมื่อ `isFOff==false`); GO เปิดจาก `ExtraTakeProfit_G` (post-exit hook); BR เปิดจาก `ExtraTakeProfit_B` (orphan exit-trigger). ดู `04 § BR-2.1` + `04 § BR-2.2`

### FR-2.5 — Slot abstraction (uniform behavior contract)

**As a** Trader, **I want** EA architecture ที่ orchestrator interact กับทุก slot ผ่าน behavior contract ชุดเดียวกัน (เปิด/ปิด/check pending/dependency), **so that** เพิ่ม/แก้ slot ใหม่ทำได้โดยไม่กระทบ slot อื่น (G1) + AI agent + reviewer ทำงานทีละ slot ได้

- **Priority:** Must
- **Why:** ปัจจุบัน slot = pair ของ free function (`BusinessLogic_X` + `ExtraTakeProfit_X`) ที่อ่าน/เขียน global ทั่ว file 22k LOC → maintenance hazard ตาม CodeWiki §7.2 + improvement-targets P1.6. ระบุเฉพาะ behavior contract — concrete API design (method signature, inheritance model, language construct) = **TD decide**
- **Source:** CodeWiki §7.2 Architecture Improvements
- **Goal trace:** G1
- **Acceptance Criteria:**
  - **AC-2.5.1:** Given slot abstraction implemented
    When orchestrator iterate slot list
    Then orchestrator สามารถเรียก behavior ต่อไปนี้ของแต่ละ slot ผ่าน contract เดียวกัน: (1) get magic identifier, (2) get slot name/ID, (3) **evaluate** signal + open new order ถ้า signal valid (FR-2.3 entry pass), (4) **manageExits** ของ open positions (FR-2.3 exit pass), (5) get pending state (BR-6.x), (6) get dependency list (FR-2.4 dependsOn) — โดย orchestrator ไม่ต้องรู้ slot-specific logic
  - **AC-2.5.2:** Given concrete slot implementation
    When developer compile + run regression
    Then ผ่านทั้ง G3 (behavioral parity) และ G1 (file size ≤ 5,000 LOC ต่อไฟล์ — ดู NFR-4.1) — 1 file ต่อ slot ตาม NFR-4.2
  - **AC-2.5.3:** Given user ต้องการเพิ่ม slot ใหม่ในอนาคต (Phase 2 — เช่น re-introduce Slot U from CodeWiki spec, หรือเพิ่ม slot Z)
    When developer สร้าง slot implementation ใหม่ + register กับ orchestrator + ใส่ลงใน topo-sort order (BR-2.2)
    Then ไม่ต้องแก้ slot อื่นใดๆ + ไม่ต้องแก้ orchestrator core

### FR-2.6 — Centralized indicator snapshot per tick

**As a** Trader, **I want** EA build snapshot ของทุก indicator value (Ichimoku H4/D1, Force, ADX H4/D1, WPR H4/D1/M15, DeMarker H4/M15, Bollinger, Stochastic M10/H4, MACD M10/D1, RSI, Hull, Fractal, ZigZag M5, SubDem H4/D1) **ครั้งเดียวต่อ tick** + ทุก slot อ่านจาก snapshot นั้น, **so that** signal evaluation ไม่ต้องอ่าน global array swarm + indicator query เกิดครั้งเดียว (perf + consistency ภายใน tick)

- **Priority:** Must
- **Why:** CodeWiki §7.2 → "central snapshot stops the ad-hoc reads from giant arrays" — เป็น G1 enabler หลัก; ปัจจุบัน slot อ่าน `IchimokuBufferA[1]`, `ForceBuffer[2]` ฯลฯ จาก global arrays กระจาย maintenance ยาก + slot อาจอ่านค่าต่างกันใน tick เดียวถ้า indicator update ระหว่าง slot. Concrete struct/class shape, field naming, immutability model = **TD decide**
- **Source:** CodeWiki §1.4, §7.2; improvement-targets P1.5/P1.6
- **Goal trace:** G1, G3
- **Acceptance Criteria:**
  - **AC-2.6.1:** Given OnTick start
    When indicator buffer refresh ทำงาน
    Then snapshot มี field ครบทุก indicator ที่ EA เดิมอ่าน (รายชื่อใน CodeWiki §1.4) — ทุก slot อ่านได้จาก snapshot เดียวกันใน tick นั้น
  - **AC-2.6.2:** Given slot evaluate / manageExits
    When slot อ่าน indicator value
    Then อ่านจาก snapshot ที่ orchestrator pass ให้เท่านั้น — ห้ามอ่านจาก global array โดยตรง
  - **AC-2.6.3:** Given trade journal entry (FR-4.1)
    When journal record ถูกเขียน
    Then field `indicator_snapshot` มี subset ของ snapshot ที่ relevant กับ slot นั้น (เพื่อ retrospective analysis)

### FR-2.7 — Per-slot state lookup by magic identifier

**As a** Trader, **I want** EA เก็บ per-slot state (buyCount, sellCount, totalLots, totalProfit, lastOpenDate, pendingState) ที่ slot อ่านได้ผ่าน magic identifier ของตัวเองใน O(1), **so that** ลดการ scan global variable swarm (`BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date`) ที่ EA เดิมใช้ + เปิดทางให้ refactor / test individual slot ได้

- **Priority:** Must
- **Why:** CodeWiki §7.2 → "replace per-slot global swarm with state lookup updated once per tick by ReadTradeData"; G1 enabler — ลด magic-string maintenance + ป้องกัน slot อ่าน stale value. Data structure (associative container, hash table, struct array, ฯลฯ) = **TD decide** ตาม MQL5 native facilities + perf budget
- **Source:** CodeWiki §2.4, §7.2; improvement-targets P1.6
- **Goal trace:** G1, G3
- **Acceptance Criteria:**
  - **AC-2.7.1:** Given OnTick start
    When `ReadTradeData` (หรือ refactored equivalent) ทำงาน
    Then per-slot state มี entry สำหรับทุก magic ใน CodeWiki §1.5 — แต่ละ entry ครอบคลุม `buyCount`, `sellCount`, `totalLots`, `totalProfit`, `lastOpenDate`, `pendingState`, ฯลฯ
  - **AC-2.7.2:** Given slot evaluate / manageExits
    When slot ต้องดู order count ของตัวเอง
    Then lookup ของ slot ตัวเอง (โดย magic) เกิดใน O(1) — ไม่ต้อง iterate ทุก slot

---

## 4. Epic E3 — Order & Risk Management + Bug Fixes

EA เดิมมี risk module ที่ smeared across ~20 helper + 18 global families (CodeWiki §4 AI Reconstruction Note); 2 critical safety bugs ต้อง fix ใน rewrite (G4).

### FR-3.1 — Position sizing per slot (preserve §4.1 multipliers 1:1)

**As a** Trader, **I want** EA คำนวณ lot ของแต่ละ slot ตาม per-slot risk percent + helper trim (ตารางใน CodeWiki §4.1) preserved 1:1, **so that** behavioral parity ตรงกับ baseline

- **Priority:** Must
- **Why:** Lot sizing คือ direct driver ของ Net Profit + Drawdown; deviation ใน lot logic = direct violation G3
- **Source:** CodeWiki §4.1 (per-slot multipliers table); improvement-targets P1.6 (centralize via RiskManager)
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-3.1.1:** Given default input set + market state ใดๆ
    When slot คำนวณ lot
    Then ค่า lot ตรงกับ formula ใน CodeWiki §4.1 (เช่น Slot G = 30% × 0.6 trim = 18%, Slot J = LastBuyLots2 × 0.23 × OpenOrderJ trim, ฯลฯ)
  - **AC-3.1.2:** Given QA regression run
    When เปรียบเทียบ lot value ของ trade ที่ open ในเวลาเดียวกัน (rewrite vs baseline)
    Then ค่า lot deviation ≤ **5%** (allow rounding + helper code path drift ใน bucket A)

### FR-3.2 — SL/TP rules per slot (preserve §4.2 logic)

**As a** Trader, **I want** EA ใช้ SL/TP method ของแต่ละ slot ตาม CodeWiki §4.2 ตาราง, **so that** exit timing ตรงกับ EA เดิม

- **Priority:** Must
- **Why:** SL/TP logic เป็น direct driver ของ win rate + avg loss; แต่ละ slot มี mechanism เฉพาะ (cloud-touch, BB-based, fractal) ที่ห้ามเปลี่ยน
- **Source:** CodeWiki §4.2 (SL/TP table per slot); improvement-targets P1.6
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-3.2.1:** Given trade closed
    When inspect close reason via trade journal (FR-4.1) + ticket history
    Then close reason ตรงกับ SL/TP method ที่ระบุใน CodeWiki §4.2 สำหรับ slot นั้น
  - **AC-3.2.2:** Given QA regression run
    When เปรียบเทียบ Total Net Profit + Profit Factor + Win Rate กับ baseline
    Then อยู่ใน threshold ตาม `trading-baseline.md § Validation Strategy`

### FR-3.3 — Bug fix: BI orders must have SL inherited from B parent (G4)

**As a** Trader, **I want** Slot BI (pyramid child of B) เปิด order ด้วย SL ที่อิง parent B slot, **so that** ผมไม่มี naked exposure จาก pyramid order ตอน trend reverse

- **Priority:** Must
- **Why:** ปัจจุบัน BI เปิดด้วย `SL=0` (CodeWiki §6.2 CRITICAL `:20326 :20357`) → unlimited downside risk; user decision 2026-05-01 = **FIX** (G4); drift จาก fix นี้นับใน **bucket B** ของ regression budget แยกจาก 25% ceiling
- **Source:** CodeWiki §4.2 (BI row), §6.2 CRITICAL; improvement-targets P1.3; ideation-brief OQ-1 resolved
- **Goal trace:** G4
- **Acceptance Criteria:**
  - **AC-3.3.1:** Given BI signal trigger + parent B slot มี active order ที่มี SL
    When BI เปิด pyramid order
    Then BI order มี SL ที่ตั้งจาก B parent ด้วย **same SL distance** (OQ-3.3 ✅ resolved 2026-05-01 — ดู `04 § BR-7.1`)
  - **AC-3.3.2:** Given trade journal entry ของ BI order
    When inspect field `sl`
    Then ค่า > 0 และอ้างถึง B parent's SL reference (record parent ticket ID ใน journal)
  - **AC-3.3.3:** Given QA regression run พร้อม bug fix
    When เปรียบเทียบ Net Profit + PF + DD กับ baseline
    Then bucket B drift documented (ไม่นับใน 25% pattern parity bucket A); PF ลดลง ≤ 0.2 จุด, Max DD% ไม่เพิ่ม

> ✅ **OQ-3.3 resolved 2026-05-01 (rule domain — locked ใน `04 § BR-7.1`):** BI inheritance semantic = **(a) same SL distance** — BI ใช้ pip distance เดียวกับ B parent's SL วัดจาก BI entry price (symmetric per-position risk)

### FR-3.4 — Bug fix: ExtraTakeProfit_J iterates MagicJ (G4)

**As a** Trader, **I want** `ExtraTakeProfit_J` (J slot exit function) iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201), **so that** J orders ถูกจัดการโดย exit logic ของตัวเอง

- **Priority:** Must
- **Why:** ปัจจุบัน J orders ไม่ได้ exit-management ของตัวเองเลย (CodeWiki §6.2 HIGH `:10897` — copy-paste bug); user decision 2026-05-01 = **FIX** (G4); คาดว่า J win rate ลดลงเล็กน้อย (exit เข้มงวดกว่าเดิม) แต่ portfolio-level อาจดีขึ้น
- **Source:** CodeWiki §6.2 HIGH; improvement-targets P1.4; ideation-brief OQ-1 resolved
- **Goal trace:** G4
- **Acceptance Criteria:**
  - **AC-3.4.1:** Given J slot has active order(s) ใน portfolio
    When `ExtraTakeProfit_J` (or refactored equivalent) ทำงาน
    Then function iterate ทุก order ที่มี `Magic == MagicJ (206)` — ไม่ touch order ที่มี `Magic == MagicF (201)`
  - **AC-3.4.2:** Given QA regression run พร้อม bug fix
    When inspect trade journal สำหรับ J slot exits
    Then ทุก J close event มี `triggering_function = "ExtraTakeProfit_J"` (ไม่ใช่ `_F`); F close events ไม่อ้างถึง J
  - **AC-3.4.3:** Given regression result
    When เปรียบเทียบ J slot trade count + win rate + Net Profit กับ baseline
    Then drift ของ J + F slot นับใน bucket B (intentional fix); portfolio-level: PF ไม่ลด, Max DD% ไม่เพิ่ม

### FR-3.5 — Trailing / breakeven behavior preservation

**As a** Trader, **I want** EA preserve ad-hoc trailing logic ของ slot G/GO/M/S ผ่าน "max profit reached + cloud touch" pattern 1:1, **so that** trailing exits ตรงกับ baseline

- **Priority:** Must
- **Why:** CodeWiki §4.2 — Trailing pattern เป็น signature ของ G/GO/M/S; เปลี่ยน = direct G3 violation
- **Source:** CodeWiki §4.2 Trailing/BE row
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-3.5.1:** Given G/GO/M/S slot trade ที่ผ่าน max profit threshold + cloud-touch event
    When trailing logic ทำงาน
    Then trade close + close reason ตรงกับ EA เดิม (verify via trade journal)

### FR-3.6 — LimitMaxLotSizeRatio cap

**As a** Trader, **I want** EA cap ทุก lot calculation ด้วย `LimitMaxLotSizeRatio` (default 2.9) × `SymbolInfoDouble(SYMBOL_VOLUME_MAX)`, **so that** EA ไม่เปิด order ใหญ่เกิน broker limit ตอน pyramid

- **Priority:** Must
- **Why:** Pyramid slots (BI, J, LX, I) สามารถ stack lot ขึ้นเร็ว — broker reject order = trade flow break + behavioral drift
- **Source:** CodeWiki §4.1 `LimitMaxLotSizeRatio`; ideation-brief baseline (peak DD trigger)
- **Goal trace:** G3, G4
- **Acceptance Criteria:**
  - **AC-3.6.1:** Given lot calculation result > `LimitMaxLotSizeRatio × SYMBOL_VOLUME_MAX`
    When OpenOrder helper รับ lot value
    Then ค่า clamped ลงเหลือ cap + log warning (ผ่าน tagged logger FR-4.2)

---

## 5. Epic E4 — Trade Journal & Observability

User pain point อันดับ 2 (Q4.1): *"ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด"*. Epic นี้เป็น G2 และเป็นเงื่อนไขที่ user จะ drop/keep slot ใดๆ ในอนาคต + tune parameter อย่างมีข้อมูล (data-driven retrospective) ภายหลัง.

### FR-4.1 — Per-event trade journal entry

**As a** Trader, **I want** ทุก order entry / exit / modification → record ใน trade journal พร้อม context ครบ, **so that** ผม retrieve trade เก่าได้ตอน retrospective + เรียนรู้จาก trade ที่ขาดทุน

- **Priority:** Must
- **Why:** G2 หลัก — ขาด journal = ไม่สามารถ improve ได้ตลอดอายุการใช้งาน; backtest journal มีอยู่ใน MT5 (HTML report) แต่ไม่มี **signal context** หรือ **indicator snapshot** ที่จำเป็นต่อ retrospective slot-level
- **Source:** ideation-brief Q4.1 user-added; improvement-targets P1.2 + P2.5
- **Goal trace:** G2
- **Acceptance Criteria:**
  - **AC-4.1.1:** Given EA เปิด/ปิด/แก้ order ใดๆ
    When order operation สำเร็จ (broker ack)
    Then journal entry ถูกเขียนภายใน **same tick** + มี field ครบทุก field ใน schema (ดูข้างล่าง)
  - **AC-4.1.2:** Given journal entry แต่ละ record
    When user inspect field
    Then มีอย่างน้อย:
      - `timestamp` (broker server time, ms precision)
      - `event_type` (`entry` / `exit` / `modify`)
      - `slot_id` (`C` / `J` / `BI` / …)
      - `magic` (numeric)
      - `ticket_id` (MT5 position ticket)
      - `symbol`, `order_type` (`buy` / `sell`)
      - `lot`, `price`, `sl`, `tp`, `comment`
      - `signal_context` (which rule(s) ผ่าน — เช่น `"WPRWaveSignal=Yes,CheckIchiBarForC=true,ForcePeak3=ascending"`)
      - `indicator_snapshot` (subset ของ MarketContext ที่ relevant กับ slot — H4 cloud edges, Force[0..2], ADX, WPR, ฯลฯ)
      - `portfolio_summary` (slot order counts, total floating P/L, equity, balance)
      - `triggering_function` (function ที่เรียก OpenOrder/CloseAllPositions — สำหรับ debug FR-3.4 type bugs)
      - `parent_ticket_id` (สำหรับ pyramid slots BI, I, LX — refer parent B/G/L)
  - **AC-4.1.3:** Given journal file
    When user open ใน text editor / spreadsheet
    Then สามารถอ่าน + filter ได้ตาม `slot_id`, `timestamp range`, `event_type` (รายละเอียด format ขึ้นกับ TD เลือก — ดู OQ-3 ข้างล่าง)
  - **AC-4.1.4:** Given journal write operation
    When write ตอน OnTick
    Then latency ≤ 5 ms (NFR-2.2)

> ✅ **OQ-3 resolved 2026-05-01 (this section):** Trade journal storage format = **(b) JSON-lines** — extensible, machine-parseable, human-readable. TD agent (Phase 1D) lock final schema + retention policy. ดูสรุปใน `02 § 12 OQ-3`.

### FR-4.2 — Tagged structured logger (foundation)

**As a** Trader, **I want** EA logger ที่ prepend `[slot=X][ev=...][magic=...]` กับทุก log message, **so that** ผม grep log ได้แบบ slot-scoped ตอน retrospective + journal สามารถ subscribe จาก log foundation เดียวกัน

- **Priority:** Must
- **Why:** ปัจจุบัน `Print()` calls ไม่มี tag — debug ทำได้ยาก; เป็น foundation ของ FR-4.1 (journal คือ specialized subset ของ tagged log)
- **Source:** CodeWiki §6.2 (no structured logging), §7.1 (tagged logger); improvement-targets P2.5
- **Goal trace:** G2
- **Acceptance Criteria:**
  - **AC-4.2.1:** Given developer log message ใน slot code
    When log emit
    Then output prefix มี `[slot=<X>][ev=<eventName>][magic=<N>]` + timestamp
  - **AC-4.2.2:** Given log file (อาจเป็น MT5 Experts log หรือ separate file)
    When user grep ด้วย `slot=BI`
    Then เจอเฉพาะ event ของ BI slot

### FR-4.3 — Local-only journal storage (MVP signal)

**As a** Trader, **I want** trade journal เก็บใน MT5 sandbox local เท่านั้น (`MQL5/Files/`), **so that** ไม่มี cloud dependency หรือ remote sync — ตาม MVP signal

- **Priority:** Must
- **Why:** User signal 2026-05-01 — *"ไม่ต้องทำ Install หรือ Server"*; remote sync = server-side requirement = out-of-scope
- **Source:** User MVP signal 2026-05-01; `01-project-brief.md § 6.2`
- **Goal trace:** G2 + scope
- **Acceptance Criteria:**
  - **AC-4.3.1:** Given trade journal write
    When EA persist record
    Then file path อยู่ใน `<MT5 data folder>/MQL5/Files/` (sandbox of `FileOpen()`)
  - **AC-4.3.2:** Given EA source code
    When developer search HTTP / WebSocket / network call
    Then **ไม่มี** call ที่เขียน journal record ออกนอก MT5 process

### FR-4.4 — Worst drawdown bookkeeping (preserve WatchProfits)

**As a** Trader, **I want** EA log worst drawdown percentage ตลอดอายุ session + persist ผ่าน GlobalVariable, **so that** ผมเห็นว่า DD เคยลึกสุดเท่าไรหลัง restart

- **Priority:** Must
- **Why:** `WatchProfits` ใน LibMonitor (CodeWiki §5.4) เป็น behavior ของ EA เดิม; ผูกกับ G3 — ห้ามลบ
- **Source:** CodeWiki §5.4 WatchProfits
- **Goal trace:** G2, G3
- **Acceptance Criteria:**
  - **AC-4.4.1:** Given EA running session
    When equity drop ≤ −20% ของ StartupEquity
    Then log entry "DD warning: <pct>%" + update `worst_drawdown_percentage` GlobalVariable
  - **AC-4.4.2:** Given EA OnDeinit
    When EA unload
    Then log สุดท้ายแสดง worst DD ของ session

---

## 6. Epic E5 — State Persistence

EA เดิมเก็บ state ใน GlobalVariable + flat key=value file `<login>_DB.txt`; crash mid-tick = corrupt; rewrite ต้อง preserve restore behavior + เพิ่ม atomicity.

### FR-5.1 — Pending state machines persist across restarts

**As a** MT5 Platform, **I want** ทุก pending state ของแต่ละ slot (CodeWiki §2.5: C-Pending, R-Pending, P-Pending, M-Pending, T-Pending, Q-Pending, Force-Pending) survive EA reload, **so that** EA boot กลับมาทำงานต่อจากจุดเดิม — ไม่เปิด trade ซ้ำหรือพลาด trigger

- **Priority:** Must
- **Why:** EA เดิม persist state ใน `<login>_DB.txt` + GlobalVariable (CodeWiki §2.5, §5.4 LoadGlobal); ขาดข้อนี้ = behavioral parity เสียทุกครั้งที่ MT5 restart
- **Source:** CodeWiki §2.5, §5.4 LoadGlobal/SaveFileDatabase
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-5.1.1:** Given pending state ของ slot ใดๆ active (เช่น `CPendingComment != ""`)
    When user restart MT5 + reattach EA
    Then EA โหลด state กลับมา + พฤติกรรม slot ตรงกับก่อน restart (verify via trade journal pattern + remaining timeout bars)
  - **AC-5.1.2:** Given state field list ใน CodeWiki §1.3 (state variables block)
    When inspect persisted state file หลัง EA shutdown
    Then ทุก field ปรากฏ + ค่าตรงกับ in-memory ตอน last tick

### FR-5.2 — Atomic state write (crash-safe persistence)

**As a** Trader, **I want** state file write ที่ tolerant ต่อ crash mid-write, **so that** ถ้า MT5 crash หรือ Windows restart ระหว่าง EA save state, EA boot กลับมา parse ไฟล์สำเร็จ + state = ก่อน crash (ไม่ corrupt, ไม่ partial)

- **Priority:** Must
- **Why:** ปัจจุบัน `SaveFileDatabase` write โดยตรง (CodeWiki §6.2 P2.4) — crash ระหว่าง write = corrupt file; user solo = ไม่มี monitoring → discover ตอน trade ผิด. ระบุ invariant — implementation pattern (temp+rename, journaling, double-buffered swap, ฯลฯ) = **TD decide**
- **Source:** CodeWiki §6.2; improvement-targets P2.4
- **Goal trace:** G4 (reliability)
- **Acceptance Criteria:**
  - **AC-5.2.1:** Given EA persist state
    When write operation completes
    Then file บนดิสก์อยู่ใน 2 state เท่านั้น: (a) เนื้อหาก่อน write นี้ครบสมบูรณ์, หรือ (b) เนื้อหาหลัง write นี้ครบสมบูรณ์ — **ห้าม** state ระหว่าง partial-write
  - **AC-5.2.2:** Given simulated crash mid-write (kill MT5 process during state persist) ทำซ้ำ 100 ครั้ง
    When user restart MT5 + reattach EA
    Then EA load state file สำเร็จ **100%** ของครั้ง + state = ก่อน crash run นั้น (verify NFR-3.1 atomic write target)

### FR-5.3 — OnDeinit final state flush

**As a** MT5 Platform, **I want** OnDeinit เรียก state flush ครั้งสุดท้ายก่อน EA unload, **so that** ไม่พลาด save ของ tick สุดท้าย

- **Priority:** Should
- **Why:** EA เดิมไม่มี final flush — รอ next-tick `SaveFileDatabase` ที่ไม่มาถ้า EA unload ก่อน (CodeWiki §5.1 OnDeinit notes)
- **Source:** CodeWiki §5.1 OnDeinit
- **Goal trace:** G3 (avoid drift)
- **Acceptance Criteria:**
  - **AC-5.3.1:** Given EA receive OnDeinit (any reason)
    When OnDeinit ทำงาน
    Then state flush + journal flush ก่อน EA unload

---

## 7. Epic E6 — Time Filters & Safety Gates

EA เดิมมี time-based filter หลายตัวที่ต้อง honor 1:1 + handle DST shift ของ FBS server (Constraint C-10).

### FR-6.1 — IsMorningWakeup blocks new orders (00:00–00:05 server time)

**As a** Trader, **I want** EA block ทุก new order ระหว่าง 00:00–00:05 broker server time, **so that** หลีกเลี่ยง spread spike ตอน rollover + รอ tick stable

- **Priority:** Must
- **Why:** EA เดิม return early ที่ OnTick `:270` (CodeWiki §4.3); behavioral fingerprint
- **Source:** CodeWiki §4.3, §2.2
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-6.1.1:** Given current broker server time ∈ [00:00, 00:05)
    When OnTick processes entry pass
    Then ไม่มี slot เปิด new order; exit pass ทำงานปกติ
  - **AC-6.1.2:** Given DST switch boundary (last Sunday Mar/Oct)
    When 00:00–00:05 อยู่ในช่วง DST shift
    Then IsMorningWakeup logic อ่าน server time ถูกต้อง (ใช้ `TimeCurrent()` ไม่ใช่ local time)

### FR-6.2 — IsMondayMorningWakeup spread guard

**As a** Trader, **I want** EA block new order ตอน Monday morning ถ้า spread > 10 pip, **so that** หลีกเลี่ยง weekend gap spike

- **Priority:** Must
- **Why:** OnTick `:261` block (CodeWiki §4.3); spread spike Monday open = entry slip + unfair fill
- **Source:** CodeWiki §4.3
- **Goal trace:** G3, G4
- **Acceptance Criteria:**
  - **AC-6.2.1:** Given Monday + first 1-2 hours ของ trading week + `SYMBOL_SPREAD > 10 × DigitMultipier`
    When OnTick run entry pass
    Then ไม่มี slot เปิด new order
  - **AC-6.2.2:** Given Monday after spread normalize (≤ 10 pip)
    When OnTick run
    Then entry pass ทำงานปกติ

### FR-6.3 — IsNewYearSeason2 + CD==0 block

**As a** Trader, **I want** EA block new orders ระหว่าง Dec 21 – Jan 3 ถ้า CD slot ไม่มี active position, **so that** หลีกเลี่ยง low-liquidity holiday volatility

- **Priority:** Must
- **Why:** OnTick `:297` block (CodeWiki §4.3) — preserve baseline behavior
- **Source:** CodeWiki §4.3
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-6.3.1:** Given current broker server date ∈ [Dec 21, Jan 3] + `portfolio[MagicCD].count == 0`
    When OnTick run entry pass
    Then ไม่มี slot เปิด new order
  - **AC-6.3.2:** Given holiday period + CD slot มี active position
    When OnTick run
    Then entry pass ทำงานปกติ (CD positions ยัง manage exit)

### FR-6.4 — Per-slot ban dates

**As a** Trader, **I want** EA preserve ban duration ของแต่ละ slot (BanCStartDate 24h, BanLStartDate 48h, BanMStartDate 36h, KLastOrderDate same D1, GPauseDate 31h), **so that** post-loss cooldown ตรงกับ baseline

- **Priority:** Must
- **Why:** EA เดิมใช้ ban เพื่อกัน slot fire ติดต่อกันหลัง loss — ตัด = behavioral drift
- **Source:** CodeWiki §4.3, §1.3 state variables
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-6.4.1:** Given slot trigger event ที่ set ban date (เช่น C loss → BanCStartDate)
    When ban duration ยังไม่ครบ
    Then slot นั้นไม่ fire entry signal
  - **AC-6.4.2:** Given ban duration ครบ
    When next OnTick + signal valid
    Then slot fire ปกติ

### FR-6.5 — DST handling for FBS server (EET)

**As a** Trader, **I want** EA อ่าน broker server time แบบที่ DST shift ถูกต้อง (last Sunday Mar = +1h, last Sunday Oct = -1h), **so that** time-based filters ทำงานถูกต้องตลอดปี

- **Priority:** Must
- **Why:** Constraint C-10; DST transition คือ edge case ที่ทำ filter ผิด → trade ใน window ที่ห้าม → behavioral drift; user confirm 2026-05-01 ว่า server = EET GMT+2/+3 DST
- **Source:** Constraint C-10; ideation-brief OQ-2 resolved
- **Goal trace:** G3, G4
- **Acceptance Criteria:**
  - **AC-6.5.1:** Given EA running ที่ DST switch boundary
    When OnTick processes time filter
    Then `TimeCurrent()` (broker server time) shift ถูกต้อง — IsMorningWakeup (00:00–00:05 server time) trigger ใน wallclock window ที่ถูก
  - **AC-6.5.2:** Given QA regression run ครอบคลุม DST transitions ทุกปี (Mar 2021 + Oct 2021 + Mar 2022 + Oct 2022 + ... + Oct 2025 = 10 transitions)
    When QA inspect trade list ของวันที่ DST switch (last Sunday Mar/Oct)
    Then **ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch** — ตรวจ IsMorningWakeup (FR-6.1, BR-3.1) ทำงานถูก ภายใต้ DST shift; ถ้ามี trade ใน window นี้ = DST handling ผิด → fail
  - **AC-6.5.3:** Given trade journal entries (FR-4.1) ของ DST switch days
    When QA filter `timestamp` field รอบ wallclock-DST-shift moment
    Then ทุก entry มี `timestamp` (broker server time) ที่สะท้อน DST shift ถูกต้อง — เช่น Sunday Mar 26 2023 04:00 server-time = wallclock 03:00 Europe/Athens (post-shift); ห้าม timestamp มี gap ที่บ่งชี้ EA misread server time

### FR-6.6 — CircuitBreakerOrder ping-pong protection

**As a** Trader, **I want** EA detect ping-pong (same position re-opens within 3000ms) + halt EA, **so that** ไม่เจอ infinite loop ที่กิน balance ตอน live

- **Priority:** Must
- **Why:** CodeWiki §5.5 CircuitBreakerOrder — preserve safety mechanism
- **Source:** CodeWiki §5.5 `:15796`
- **Goal trace:** G4
- **Acceptance Criteria:**
  - **AC-6.6.1:** Given EA detect 2 trades ของ slot เดียวกัน + opposite direction + Δt < 3000ms
    When CircuitBreaker check ทำงาน
    Then EA halt + log + alert (FR-7.7)

### FR-6.7 — Force-pending 9-bar timeout

**As a** Trader, **I want** EA clear `IsForcePendingActionBuyOrder|SellOrder` หลัง 9 H4 bars elapse without trigger, **so that** stale pending ไม่กระทบ logic ภายหลัง

- **Priority:** Must
- **Why:** CodeWiki §2.5 Force-Pending state machine; OnTick `:249` clear logic
- **Source:** CodeWiki §2.5
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-6.7.1:** Given Force-Pending flag set + 9 H4 bars elapsed
    When OnTick run
    Then flag cleared + log entry

---

## 8. Epic E7 — Cross-slot Coordination & Cleanup

### FR-7.1 — OrderGroupStartWorkflow (Safe port)

**As a** Trader, **I want** EA run "Safe port" cleanup: ถ้า weakOrderCount > 1 + avg badPIP > 55 + currentProfit > 0 → ปิด weak orders ของ 10 slots (CD, J, H, K, L, M, Q, GO, T, S) พร้อมกัน, **so that** หลีก deep DD โดยล็อคกำไรเล็กน้อยที่มี

- **Priority:** Must
- **Why:** CodeWiki §5.5 OrderGroupStartWorkflow — preserve cross-slot safety mechanism (G3)
- **Source:** CodeWiki §5.5 `:328`, §4.3
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-7.1.1:** Given conditions (weakOrderCount > 1, avg badPIP > 55, currentProfit > 0)
    When workflow run
    Then ทุก position ของ 10 slots ที่ระบุปิดในเวลาเดียวกัน
  - **AC-7.1.2:** Given trade journal entries ของ closes
    When inspect close reason
    Then `triggering_function = "OrderGroupStartWorkflow"` + bulk close pattern visible

### FR-7.2 — OrderGroupStartWorkflow2 (Ichimoku double-bounce)

**As a** Trader, **I want** EA run alternate cleanup ผ่าน Ichimoku double-bounce + Force confirmation pattern, **so that** preserve เสริม layer ของ EA เดิม (behavioral parity)

- **Priority:** Must
- **Why:** CodeWiki §5.5 OrderGroupStartWorkflow2 — preserve baseline
- **Source:** CodeWiki §5.5 `:512`
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-7.2.1:** Given Ichimoku double-bounce pattern detected + weakOrderCount > 2 + Force confirms
    When workflow run
    Then close pattern ตรงกับ EA เดิม (verify via journal)

### FR-7.3 — ForceCutloss (CD safety)

**As a** Trader, **I want** EA trigger CD loss-cap ผ่าน Stochastic M10 + MACD D1 confirmation, **so that** preserve CD-specific exit safety

- **Priority:** Must
- **Source:** CodeWiki §5.5 `:9009`
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-7.3.1:** Given CD trade in loss + Stochastic M10 + MACD D1 confirm
    When ForceCutloss trigger
    Then CD position closed + log

### FR-7.4 — ExtraCheckFunction2 (CD count == 1 demote)

**As a** Trader, **I want** EA demote `ExtraForceModeReason` เมื่อ CD slot count == 1, **so that** preserve baseline (behavioral parity)

- **Priority:** Must
- **Source:** CodeWiki §2.2 OnTick block
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-7.4.1:** Given CD slot count == 1
    When ExtraCheckFunction2 run
    Then `ExtraForceModeReason` cleared/demoted

### FR-7.5 — EOverload / COverload / GOverload

**As a** Trader, **I want** EA preserve overload helpers: EOverload (peak-reversion CD add), COverload (cut CD on MACD same-sign losses), GOverload (inverse hedge after G close), **so that** behavioral parity preserved

- **Priority:** Must
- **Source:** CodeWiki §5.5
- **Goal trace:** G3
- **Acceptance Criteria:**
  - **AC-7.5.1:** Given conditions ของแต่ละ overload helper
    When helper triggered
    Then trade pattern (extra order, cut size, hedge) ตรงกับ EA เดิม

### FR-7.6 — Indicator handle validation in OnInit

**As a** Trader, **I want** EA validate ทุก indicator handle (~30 handles ใน CodeWiki §1.4) ใน OnInit + reject EA load ถ้ามี `INVALID_HANDLE`, **so that** ไม่มี silent failure ของ signal logic ตอนรัน live ที่ผมจะไม่รู้ตัว

- **Priority:** Must
- **Why:** ปัจจุบัน OnInit ไม่ validate handle (CodeWiki §6.2 P1.8) → INVALID_HANDLE = `CopyBuffer` ใช้ stale buffer = trade ผิด silently → live risk
- **Source:** CodeWiki §6.2, §5.1 OnInit notes; improvement-targets P1.8
- **Goal trace:** G4
- **Acceptance Criteria:**
  - **AC-7.6.1:** Given OnInit สร้าง indicator handle (~30 handles)
    When handle return value == `INVALID_HANDLE`
    Then OnInit reject load + log error message ระบุ indicator name + parameter set
  - **AC-7.6.2:** Given OnInit สำเร็จทั้งหมด
    When EA log
    Then "Indicator handles: 30/30 valid" + EA เริ่ม OnTick

### FR-7.7 — CircuitBreaker controlled halt + alert

**As a** Trader, **I want** ถ้า CircuitBreaker (FR-6.6) หรือ indicator-handle failure (FR-7.6) trigger → EA เข้า halted state แบบ controlled (manage exits ต่อ, ไม่เปิด entry) + แสดง alert ผ่าน MT5 native `Alert()` (ไม่ใช่ silent ExpertRemove), **so that** open positions ไม่กลายเป็น orphan + ผมรู้ทันทีว่าเกิดอะไรตอน live

- **Priority:** Must
- **Why:** ปัจจุบัน CircuitBreaker เรียก `ExpertRemove()` เงียบ → user ไม่รู้ว่า EA หาย (CodeWiki §6.2 P2.3); upgrade Should → Must เพราะ trigger sources (FR-6.6, FR-7.6) priority = Must — notification เป็นส่วนเดียวกันของ safety contract; under MVP signal — ใช้ MT5 native Alert (popup + sound) แทน Telegram. Halted-state semantic ต้องชัดว่า exit pass ทำงานต่อ ไม่งั้น open positions กลายเป็น naked exposure (G4 violation)
- **Source:** CodeWiki §6.2 P2.3; improvement-targets P2.3; MVP signal
- **Goal trace:** G2 (observability), G4
- **Acceptance Criteria:**
  - **AC-7.7.1:** Given CircuitBreaker trigger
    When EA halt logic ทำงาน
    Then EA stop เปิด new orders + log full reason + เรียก `Alert("PhoenicisNex CircuitBreaker triggered: <reason>")` ใน MT5 platform
  - **AC-7.7.2:** Given EA in halted state
    When user inspect
    Then EA ยัง attached กับ chart (ไม่ ExpertRemove) + ไม่ trade ต่อ (ดู AC-7.7.3) + journal entry "halted" written
  - **AC-7.7.3:** Given EA in halted state, When OnTick events arrive,
    Then EA execute **exit pass อย่างเดียว** (manageExits ของทุก slot ทำงานต่อ — TP/SL/trailing/cloud-touch logic ของ EA เดิมยังจัดการ open positions) + **skip entry pass** (ไม่มี slot เปิด new market order, ไม่มี pending state machine fire) — เพื่อให้ open positions ปิดตาม strategy เดิมและไม่กลายเป็น orphan exposure
  - **AC-7.7.4:** Given EA in halted state, When `manageExits` ของทุก slot run แล้ว portfolio[*].count == 0 (ปิดหมด),
    Then EA emit second journal entry "halt-stable" + Alert "PhoenicisNex halted, all positions closed" + remain attached (ผู้ใช้ตัดสินใจ detach ด้วยมือ)

> **Known gap (Phase 2):** Long-running halt + open positions ที่ไม่ปิดเอง + user ไม่ได้ยิน Alert (PC mute / away) = naked exposure window. Phase 2 จะพิจารณา escalation policy (e.g., auto-close หลัง N hours, Telegram notification) — defer Phase 1 เพราะ scope MVP solo + ไม่มี server/notification backend

---

## 9. Epic E8 — Performance & Caching

### FR-8.1 — 300-bar scan cache till H4 close

**As a** Trader, **I want** EA cache 300-bar scan result (used by `IChiThisWaveStartBars`, `CheckGapFromIchi`, `CheckForceWaveMaxValue`) ระหว่าง bar เดียวกัน + invalidate ตอน bar close, **so that** OnTick latency ลดลง + Strategy Tester run เร็วขึ้น

- **Priority:** Should
- **Why:** ปัจจุบัน 300-bar scan run ทุก tick (CodeWiki §6.2 P2.1) → CPU + backtest 5 ปีช้ากว่าจำเป็น; under MVP signal — Should ไม่ใช่ Must เพราะ behavior ไม่เปลี่ยน + เพียง perf
- **Source:** CodeWiki §6.2, §7.1; improvement-targets P2.1
- **Goal trace:** G1 (perf), G3 (no behavior change)
- **Acceptance Criteria:**
  - **AC-8.1.1:** Given OnTick within same H4 bar
    When 300-bar scan helpers called multiple times
    Then ผลลัพธ์มาจาก cache (verify via debug counter)
  - **AC-8.1.2:** Given new H4 bar close
    When next OnTick
    Then cache invalidated + scan run fresh
  - **AC-8.1.3:** Given before/after rewrite + same parameter
    When QA วัด tick latency
    Then average tick latency ลดลง (NFR-2.1)

### FR-8.2 — Drawdown loop optimization

**As a** Trader, **I want** EA cache + incremental update ของ drawdown calculation loop, **so that** loop ไม่ช้าตามอายุ order (perf only — behavior ไม่เปลี่ยน)

- **Priority:** Could
- **Why:** ปัจจุบัน inner loop iterate จาก order's open bar ถึง bar 0 (CodeWiki §6.2 P2.8) — ช้าตามอายุ order; under MVP signal — Could (ไม่ critical, ผลกระทบ minor)
- **Source:** CodeWiki §6.2, improvement-targets P2.8
- **Goal trace:** G1 (perf only)
- **Acceptance Criteria:**
  - **AC-8.2.1:** Given long-lived order (อายุ > 30 H4 bars)
    When DD calculation
    Then ใช้ incremental cached result + loop ไม่ scan ทั้งหมดทุก tick

### FR-8.3 — Per-slot opt-out from Safe port (demoted to Could under MVP)

**As a** Trader, **I want** input flag ต่อ slot เพื่อ opt-out จาก OrderGroupStartWorkflow bulk close, **so that** ผมเก็บ slot ที่ไม่ควรปิดได้

- **Priority:** Could
- **Why:** Under MVP signal — UX feature, ไม่ critical สำหรับ MVP; ของเดิมไม่มี = baseline ไม่เสีย
- **Source:** improvement-targets P2.6
- **Goal trace:** G1 (configurability)
- **Acceptance Criteria:**
  - **AC-8.3.1:** Given input `InpSafePortOptOut_<slot> = true` สำหรับ slot ใดๆ
    When OrderGroupStartWorkflow trigger
    Then slot นั้นไม่ถูก bulk-closed

---

## 10. MoSCoW Summary Table

| ID | User Story (สั้น) | Priority | Goal | Source |
|----|-------------------|----------|------|--------|
| FR-1.1 | Promote ≥80 magic numbers → MT5 input | Must | G1 | §6.1 |
| FR-1.2 | Symbol whitelist guard | Must | G4 | §6.3 P1.7 |
| FR-1.3 | Strategy Tester optimization | Must | G1 | §7.2 |
| FR-1.4 | Input validation OnInit | Must | G1, G4 | §5.1 |
| FR-2.1 | Preserve all 17+ slots 1:1 | Must | G3 | §1.5 §3 |
| FR-2.2 | Slot U deleted from rewrite | Must | G3, G1 | OQ-8 ✅ resolved |
| FR-2.3 | Exit-before-entry pass | Must | G3 | §2.2 |
| FR-2.4 | Cross-slot dependency graph | Must | G1, G3 | §7.2 |
| FR-2.5 | Slot abstraction (uniform contract) | Must | G1 | §7.2 |
| FR-2.6 | Indicator snapshot per tick | Must | G1, G3 | §7.2 |
| FR-2.7 | Per-slot state lookup by magic | Must | G1, G3 | §7.2 |
| FR-3.1 | Position sizing per-slot 1:1 | Must | G3 | §4.1 |
| FR-3.2 | SL/TP rules per-slot | Must | G3 | §4.2 |
| FR-3.3 | BI SL fix (G4) | Must | G4 | §6.2 CRITICAL ⚠️ |
| FR-3.4 | ExtraTakeProfit_J magic fix | Must | G4 | §6.2 HIGH |
| FR-3.5 | Trailing/BE preservation | Must | G3 | §4.2 |
| FR-3.6 | LimitMaxLotSizeRatio cap | Must | G3, G4 | §4.1 |
| FR-4.1 | Per-event journal entry | Must | G2 | Q4.1 OQ-3 ✅ JSON-lines |
| FR-4.2 | Tagged structured logger | Must | G2 | P2.5 |
| FR-4.3 | Local-only journal storage | Must | G2 | MVP signal |
| FR-4.4 | Worst DD bookkeeping | Must | G2, G3 | §5.4 |
| FR-5.1 | Pending state persist | Must | G3 | §2.5 |
| FR-5.2 | Atomic state write | Must | G4 | P2.4 |
| FR-5.3 | OnDeinit final flush | Should | G3 | §5.1 |
| FR-6.1 | IsMorningWakeup block | Must | G3 | §4.3 |
| FR-6.2 | Monday spread guard | Must | G3, G4 | §4.3 |
| FR-6.3 | New Year holiday block | Must | G3 | §4.3 |
| FR-6.4 | Per-slot ban dates | Must | G3 | §4.3 |
| FR-6.5 | DST handling EET | Must | G3, G4 | C-10 |
| FR-6.6 | CircuitBreaker ping-pong | Must | G4 | §5.5 |
| FR-6.7 | Force-pending 9-bar timeout | Must | G3 | §2.5 |
| FR-7.1 | Safe port (OrderGroup#1) | Must | G3 | §5.5 |
| FR-7.2 | Ichimoku bounce (OrderGroup#2) | Must | G3 | §5.5 |
| FR-7.3 | ForceCutloss CD safety | Must | G3 | §5.5 |
| FR-7.4 | ExtraCheckFunction2 | Must | G3 | §2.2 |
| FR-7.5 | EOverload/COverload/GOverload | Must | G3 | §5.5 |
| FR-7.6 | Indicator handle validation | Must | G4 | P1.8 |
| FR-7.7 | CircuitBreaker controlled halt | Must | G2, G4 | P2.3 |
| FR-8.1 | 300-bar scan cache | Should | G1, G3 | P2.1 |
| FR-8.2 | DD loop optimization | Could | G1 | P2.8 |
| FR-8.3 | Safe-port opt-out flag | Could | G1 | P2.6 (MVP demote) |

**Counts:** Must **37** / Should **2** / Could **2** / Won't **0** (Won't อยู่ใน `01 § 6`)

---

## 11. Traceability — Goal → Functional Requirement

| Goal | FRs ที่เกี่ยวข้อง |
|------|-------------------|
| **G1 Maintainability** | FR-1.1, FR-1.3, FR-1.4, FR-2.4, FR-2.5, FR-2.6, FR-2.7, FR-8.1, FR-8.2, FR-8.3 |
| **G2 Observability** | FR-4.1, FR-4.2, FR-4.3, FR-4.4, FR-7.7 |
| **G3 Behavioral preservation** | FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-2.6, FR-2.7, FR-3.1, FR-3.2, FR-3.5, FR-3.6, FR-4.4, FR-5.1, FR-5.3, FR-6.1, FR-6.2, FR-6.3, FR-6.4, FR-6.5, FR-6.7, FR-7.1, FR-7.2, FR-7.3, FR-7.4, FR-7.5, FR-8.1 |
| **G4 Safety remediation** | FR-1.2, FR-1.4, FR-3.3, FR-3.4, FR-3.6, FR-5.2, FR-6.2, FR-6.5, FR-6.6, FR-7.6, FR-7.7 |

---

## 12. Resolved Questions — FR domain

User resolved both FR-domain open questions ใน BA review 2026-05-01.

### ✅ OQ-3 — Trade journal storage format → **JSON-lines**

**User decision (2026-05-01):** **(b) JSON-lines** — accept BA default

**Why JSON-lines:**
- Extensible — เพิ่ม field ใน signal_context / indicator_snapshot ภายหลังได้โดยไม่ break ของเก่า
- Human-readable — user เปิดดูใน Notepad++ / VS Code ได้
- Machine-parseable — Python / Excel import ผ่าน script ง่าย
- Size acceptable: 5-yr backtest ≈ 231 trades × ~500 bytes/record ≈ 115 KB; live ปีละ ~50 trades → trivial

**Resolution path forward:** TD agent (Phase 1D) lock final schema + retention policy (default = no rotation, file size monitored ผ่าน FR-7.7 alert ถ้าเกิน threshold ที่ TD กำหนด)

---

### ✅ OQ-8 — Slot U disposition → **DELETE**

**User decision (2026-05-01):** **(c) Delete** — Slot U ไม่ปรากฏใน rewrite (override BA default)

**Why delete (user reasoning):** Slot U ใน EA เดิม disabled อยู่แล้ว → baseline ไม่ขึ้นกับ U → ลบทิ้ง = clean code + ลด maintenance overhead; ถ้าอนาคตอยาก revive = เขียนใหม่จาก CodeWiki §3 spec (Phase 2 timeline ยอมรับ cost นี้ได้)

**Implementation impact:**
- FR-2.2 rewritten — Slot U deleted (FR-2.2 above)
- BR-1.1 magic table — magic 220 marked ✅ deleted (available สำหรับ Phase 2)
- BR-2.2 topo-sort — U row removed
- BR-4.1 / BR-5.1 — U row removed from lot/SL/TP tables
- F1 OnTick flow (`05`) — U step removed from diagram
- Total slots in rewrite: 21 (ลบจาก 22 ของ EA เดิม — C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B, BR, BI)

---

> **End of 02 — Functional Requirements** — 41 user stories, **45 acceptance criteria** (FR-2.2 added 1 AC; FR-6.5 added 1 AC for DST deterministic; FR-7.7 added 2 AC for halt semantic), MoSCoW (Must 37 / Should 2 / Could 2), all FR-domain open questions ✅ resolved 2026-05-01
