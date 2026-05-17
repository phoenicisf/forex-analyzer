# 01 — Project Brief: PhoenicisNex

> **Phase:** Phase 1A (BA Requirements Discovery) — Doc 1/5
> **Author:** BA agent (`/ba` workflow, v1.2)
> **Last updated:** 2026-05-17 (BT-002 BA cascade — Core EA Capabilities § 5.1 cross-slot housekeeping CircuitBreakerOrder strikethrough + Glossary § 8 Bucket B drift prose update (full-window post-BT-002) + Reference Table § 9 legacy components CircuitBreakerOrder strikethrough + BT-002 cascade citation. Prior: 2026-05-12 BT-001 cascade — Bucket A/B propagation: glossary `§ 8` + Goal G4 KPI `§ 3` + reference table `§ 9`)
> **Audience:** Architect (Phase 1B), Tech Lead (Phase 1D), Sponsor / Trader (sign-off) — ทุกบทบาทในโปรเจคนี้คือ user คนเดียว (solo)

## TL;DR

PhoenicisNex คือการ **rewrite จากศูนย์** ของ EA `PhoenicisN2.10_stable.mq5` (22,016 LOC, MQL5) ซึ่งเทรด EURUSD H4 ทำกำไรดีใน Strategy Tester 5 ปี (Net Profit $24.27M, Profit Factor 8.96, Sharpe 9.17) แต่ **บำรุงรักษาไม่ไหว** เพราะไม่มี `input` parameter (recompile ทุกครั้งที่ tune), ไม่มี trade journal (ดู trade เก่าไม่ออกว่า slot ไหน-signal อะไรทำ), และมี 2 critical safety bugs ที่ live ในของเดิม (BI orders SL=0, ExtraTakeProfit_J iterates magic ผิด). เอกสารนี้ระบุ business goals 4 ข้อ, in/out-of-scope ของ **Phase 1 MVP**, constraints, success KPIs, และ glossary ของศัพท์โดเมนทั้งหมดให้ Architect ใช้ออกแบบต่อ.

**MVP Scope statement (user signal 2026-05-01):** deliverable สุดท้ายคือ **EA file (`.mq5` source + `.ex5` compiled) + library files** วางใน MT5 `Experts/` folder ของ user ด้วยมือ — **ไม่มี installer, ไม่มี server-side component, ไม่มี VPS provisioning, ไม่มี web/Telegram dashboard, ไม่มี cloud sync**. Trade journal เก็บ local-only ใน MT5 sandbox (`MQL5/Files/`).

**Trade-off ที่ user รับรู้แล้ว:** เก็บ slot scaffold **21 slots** (ทุก slot ของ EA เดิมยกเว้น `Slot U` ที่ถูก disabled อยู่แล้ว — user decision 2026-05-01: delete) ในรอบแรก ไม่ตัด slot อื่นก่อนพิสูจน์ baseline — ยอมโค้ดเยอะกว่า minimum เพื่อ behavioral parity. ห้ามเพิ่ม strategy ใหม่หรือ feature ที่ไม่มีในของเดิม.

---

## 1. Identity

ตารางนี้ระบุข้อมูลพื้นฐานของระบบที่กำลังจะ rewrite — Architect ใช้เป็น anchor ตอน design.

| Field | Value |
|-------|-------|
| **System Name** | PhoenicisNex |
| **Source Lineage** | Greenfield rewrite of `Phoenicis-n v2.10` — `MQL5/Experts/PhoenicisN2.10_stable.mq5` + 5 libs (`LibCommon1.1`, `LibIndicator1.1`, `LibSubDem1.6`, `LibDatabase1.1`, `LibMonitor1.1`) |
| **Domain** | Internal Tool — Algorithmic Forex Trading (single-instrument retail EA) |
| **Stage** | Migration → Greenfield rewrite (CodeWiki เป็น spec, ไม่ branch ออกจาก source โดยตรง) |
| **Platform** | MetaTrader 5 (Windows; MQL5 native) |
| **Deliverable Form** | EA source + compiled binary + library files. ติดตั้งโดยวางใน `MQL5\Experts\` ด้วยมือ. **Not** an installable package, **not** a service. |
| **Distribution** | Single-user (solo trader). ไม่มี broker upload, ไม่มี marketplace, ไม่มี shared deployment. |

---

## 2. Problem Statement

EA ปัจจุบันมีผล backtest ดีมาก (5-yr 2021-2025: $1k → $24.27M, win rate 92.21%, max consecutive losses เพียง 2 — ดู `trading-baseline.md`) แต่ codebase ทำให้ user ทำงานต่อไม่ได้:

1. **ไม่มี `input`/`sinput`/`extern` declarations เลย** (CodeWiki §1.3, §6.2 HIGH) — tune parameter ทีต้อง edit code → recompile → restart EA. Strategy Tester optimization sweep ทำไม่ได้เพราะ parameter ไม่อยู่ใน input dialog.
2. **ไม่มี trade journal / audit trail** (Q4.1 user-added gap) — ดู trade ขาดทุนเก่าไม่ออกว่า slot ไหนทำ, signal context อะไร, indicator value เท่าไรตอนเปิด/ปิด. *"ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด"* — quote user 2026-05-01.
3. **22,016 LOC ไฟล์เดียว + 5 library files** (CodeWiki §7.2) — debug ทีพังตรงโน้น; AI agent ก็ติด context limit ทำงาน slot-by-slot ลำบาก.
4. **2 critical/high safety bugs ค้างใน prod** (CodeWiki §6.2):
   - **CRITICAL** — `BI` orders เปิดด้วย `SL=0` → naked exposure ลิมิต 0 (`:20326 :20357`)
   - **HIGH** — `ExtraTakeProfit_J` iterate `MagicF` (=201) แทน `MagicJ` (=206) → J orders ไม่ได้ exit-management ของตัวเองเลย (`:10897`)
5. **17+ slots overlap + comment-string state schema** (CodeWiki §6.2) — `G/G2` share `MagicG`, `B/BI` share `MagicB`; slot อาจ fire พร้อมกันโดยไม่มี mutex; comment parsing เปราะต่อ format drift.
6. **No symbol whitelist** (CodeWiki §6.3) — attach EA กับ chart อื่นแล้วรัน → เสี่ยงเปิด trade บน symbol ผิด.

ผลรวม: user ต้อง rewrite — ไม่ใช่ refactor — เพราะ 22k LOC monolith ปรับโครงไม่ไหว.

---

## 3. Business Goals & Success KPIs

ลำดับความสำคัญ (เลขน้อย = สำคัญกว่า). ทุก KPI ต้องวัดได้และเทียบกับ baseline ใน `trading-baseline.md`.

| # | Goal | Success KPI | Why (ถ้าไม่มีจะเจ็บตรงไหน) |
|---|------|-------------|----------------------------|
| **G1** | **Maintainability** — code อ่าน/แก้/tune ได้โดยไม่ recompile | ≥ 80 magic numbers (CodeWiki §6.1) ทั้งหมดเป็น `input`/`sinput` ใน MT5 input dialog; ทุกไฟล์ ≤ 5,000 LOC | ปัจจุบัน tune ที = recompile + restart MT5 + state อาจ corrupt; Strategy Tester sweep ทำไม่ได้ → user ไม่สามารถ optimize ได้ตลอดอายุการใช้งาน |
| **G2** | **Observability** — ทุก trade ค้นย้อนได้ | ทุก order entry/exit/modification → trade journal record (slot, magic, signal context, indicator snapshot, lot, SL, TP, comment, timestamp) ที่ query/filter ได้ภายหลัง | *"ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด"* (user Q4.1) — ขาด journal = ไม่มีทาง improve strategy ภายหลัง |
| **G3** | **Behavioral preservation** — เทรด pattern คล้ายเดิม | Backtest 2021-2025 EURUSD H4 บน FBS Standard: \|ΔTotal Net Profit\| ≤ **25%** ของ baseline ($24.27M ≈ ±$6.07M); Profit Factor ลดลง ≤ 0.2 จุด (≥ 8.76) | ห้ามทำ EA ที่ทำงานดีอยู่แล้วเสีย — user สูญเสียมูลค่ากำไร backtest ที่ตรวจสอบแล้ว |
| **G4** | **Safety remediation** — fix 2 critical bugs | (a) `BI` orders ต้องมี SL อิง parent `B` slot (semantic locked "same SL distance" per OQ-3.3 — `04 § BR-7.1`); (b) `ExtraTakeProfit_J` iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201). G4 fix contribution วัดผ่าน **NFR-1.1 Bucket A** (rewrite-G4-ON vs baseline ≤ 25%, default build, fix contribution included) + **NFR-1.8 informational delta** (no acceptance gate, post-BT-001 re-baseline 2026-05-12) | BI = naked exposure (live ขาดทุนได้ไม่จำกัด); J bug = exit logic ของ J ไม่ทำงานเลย → live risk ที่ user ไม่ควรรับสืบทอด (decision: FIX, 2026-05-01) |

> **Operating envelope (ไม่ใช่ acceptance criteria)** — EA เดิมตั้งเป้า 10–30% ROI/เดือน, max drawdown ≤ 50% (User C-8 = High Risk profile). ตัวเลขเหล่านี้สำหรับ live; rewrite ไม่ต้องบรรลุตรง — แค่ไม่เสีย behavioral parity ตาม **G3**.

---

## 4. Stakeholders / Actors

โปรเจคนี้เป็น solo operation — บทบาททั้งหมดเป็น user คนเดียว ยกเว้น AI Agent ที่เป็น implementer.

| Actor | Type | Role | Interaction กับระบบ |
|-------|------|------|---------------------|
| **Trader / Owner** | Human (solo) | กำหนดทิศทาง, set `input` parameters, attach EA กับ chart, รัน Strategy Tester, review trade journal, sign-off code | ผ่าน MT5 native UI (input dialog, chart, Strategy Tester, file explorer สำหรับดู journal) |
| **AI Agent (Claude)** | Tooling | เขียน code, refactor, test ตาม BA → SD → TD → Impl pipeline | ผ่าน `.agents/workflows/*.md` — ไม่ใช่ runtime actor |
| **MT5 Platform** | System | Indicator engine, OnTick events, order execution gateway, state persistence (`MQL5/Files/`) | ผ่าน MQL5 API (`iCustom`, `iIchimoku`, `CTrade.OrderSend`, `GlobalVariable*`) |
| **Broker (FBS Markets Inc — Standard)** | External system | Fill orders, provide spread/swap, supply historical data | ผ่าน MT5 server connection (FBS-Real Build 5833, EET timezone GMT+2/+3 DST) |
| **Strategy Tester** | System (within MT5) | Backtest harness สำหรับ regression validation | รับ EA + input set + symbol + period → คืน trade list + headline metrics |

> **No third-party services** — ไม่มี API external (news provider, analytics, telemetry), ไม่มี cloud, ไม่มี shared infrastructure.

> **System actor convention (scope = user stories ใน `02-functional-requirements.md` เท่านั้น):** User stories ใน `02-functional-requirements.md` ใช้ `Trader`, `MT5 Platform`, `Strategy Tester`, `Broker` ตามตารางข้างบน. Internal EA components (slot logic, risk-management helper, pending-state machine, market-context bundle, per-slot state lookup) **ไม่ใช่ stakeholder actor** — เป็น implementation detail ที่ Architect/TD design ขึ้นมาเพื่อตอบ requirement; user story กับ AC ที่อ้างถึง component เหล่านี้จะใช้ phrasing แบบ "EA must..." / "the system shall..." (Trader = subject ของ user story, EA = subject ของ behavioral requirement).
>
> **Out of scope of this convention:** Flow diagrams ใน `05-user-flows.md` (sections F1.2/F2.2/F3.2/F7.2 ฯลฯ) ระบุ "Actors involved" ของแต่ละ flow เป็น **participant naming** ของ component ที่ flow แตะ — รวม system internals (Slot orchestrator, MarketContext, PortfolioState, RiskManager, TradeJournal, Cross-slot helpers, MT5 file system) ตาม BA practice ของ flow documentation. การ list system internals ในตาราง flow Actors **ไม่ใช่** การเลื่อนพวกมันเป็น stakeholder actor — เป็นแค่ "ตัวที่ flow นี้ touch" สำหรับ Architect Phase 1B ใช้ extract participant relationships ตอน design component boundaries.

---

## 5. In-Scope (Phase 1 MVP)

ทุก item ใน scope นี้ Architect ต้อง honor และ deliver. รายละเอียด user stories อยู่ใน `02-functional-requirements.md`.

### 5.1 Core EA Capabilities

- **21 slots ของ EA ปัจจุบัน** — preserve scaffold 1:1 ตาม CodeWiki §1.5: `C`, `D`, `F`, `J`, `H`, `K`, `G`, `G2`, `GO`, `M`, `L`, `LX`, `Q`, `R`, `I`, `P`, `T`, `S`, `B`, `BR`, `BI` — **Slot `U` ถูกลบทิ้ง** (deleted per OQ-8 user decision 2026-05-01; ของเดิม disabled อยู่แล้ว = ลบไม่กระทบ baseline)
- **Slot orchestrator** — exit pass ก่อน entry pass ทุก tick (ตาม CodeWiki §2.2)
- **Cross-slot dependencies** — `G→GO`, `B→BR`, `B→BI`, `J→C/D`, `S→L/K`, `LX→L pyramid` (CodeWiki §3, §7.2) — explicit ใน slot abstraction (FR-2.5; concrete representation = TD decide)
- **Cross-slot housekeeping** — `OrderGroupStartWorkflow` (Safe port), `OrderGroupStartWorkflow2`, `ForceCutloss`, `COverload`, `EOverload`, `GOverload`, ~~`CircuitBreakerOrder`~~ — **REMOVED per BT-002 2026-05-17 (legacy-parity)**; rewrite ไม่ implement ping-pong detector (cap-3 iter chain ADR-013 → ADR-014 falsified 3 false-positive halt classes per `backtrack-log.md § BT-002`)

### 5.2 Configuration & Tuning

- **Parameterization** — promote ≥ 80 magic numbers จาก CodeWiki §6.1 → MT5 native `input`/`sinput`. Default value = current global 1:1 (เพื่อ backtest reproducibility ตามสมมติฐาน H1)
- **Strategy Tester compatibility** — input set ทั้งหมดต้อง enumerate-able ใน optimization sweep
- **Symbol whitelist** — `OnInit` reject ถ้า `_Symbol != "EURUSD"` (CodeWiki §6.3, P1.7)

### 5.3 Trade Journal & Observability

- **Per-event journal** — ทุก order entry/exit/modification → record อย่างน้อย: timestamp, slot ID, magic, action type, ticket, lot, price, SL, TP, comment, signal context (rule ที่ผ่าน), indicator snapshot (Ichimoku H4 cloud edges, Force, ADX, WPR, etc.), portfolio state hash, equity, balance.
- **Storage** = local file ใน MT5 `MQL5/Files/` sandbox **only**. ไม่มี remote sync (per MVP signal). Format = **JSON-lines** (OQ-3 ✅ resolved 2026-05-01); schema lock ใน TD Phase 1D.
- **Tagged logging foundation** — replace bare `Print()` ด้วย structured logger (`[slot=X][ev=...][magic=...]`) — ใช้ร่วมกับ trade journal (CodeWiki §7.1, P2.5)

### 5.4 Safety & Reliability

- **Bug fix #1 (CRITICAL):** BI orders ต้องเปิดด้วย SL อิง B parent slot (G4)
- **Bug fix #2 (HIGH):** `ExtraTakeProfit_J` iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201) (G4)
- **Indicator handle validation** — ทุก ~30 indicator handles ต้อง validate ใน `OnInit`; fail-fast + log + reject EA load ถ้ามี `INVALID_HANDLE` (CodeWiki §6.2 P1.8)
- **State persistence** — pending state machines + GlobalVariable + DB.txt restore ครบทุก field; write ต้อง atomic (crash mid-tick = ไฟล์ไม่ corrupt; รายละเอียด invariant ใน FR-5.2) ป้องกัน mid-tick crash corrupt state (CodeWiki §6.2 P2.4)
- **DST handling** — broker server timezone EET (GMT+2 winter, GMT+3 summer DST transitions ใน last Sunday Mar/Oct). Time filters (`IsMondayMorningWakeup`, `IsNewYearSeason2`, hour-based bans) ต้อง handle DST shift ถูกต้อง

### 5.5 Architecture Refactor (G1 enabler — behavior contract only; concrete API + data structures = TD decide)

- **Slot abstraction** — orchestrator interact กับทุก slot ผ่าน behavior contract ชุดเดียวกัน (entry evaluate, manage exits, pending state, dependency list) — ดู FR-2.5
- **Centralized indicator snapshot** — สร้างทุก tick, รวม indicator values ทั้งหมดในที่เดียว, ทุก slot อ่านจาก snapshot เดียวกันใน tick นั้น — ดู FR-2.6
- **Per-slot state lookup** — slot อ่าน state ของตัวเอง (counts, lots, profit, lastOpenDate, pendingState) ผ่าน magic identifier ใน O(1) แทน global swarm `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` — ดู FR-2.7
- **File split** — 22k LOC → 1 ไฟล์/slot + libs; ทุกไฟล์ ≤ 5,000 LOC

### 5.6 Deliverable Form

- **`.mq5` source files** + **`.ex5` compiled binary** + library files
- ใช้งาน: user copy ไฟล์ลง `MQL5\Experts\` ของ MT5 ด้วยมือ → restart MT5 → attach EA กับ EURUSD H4 chart → เปิด input dialog → set parameters → run
- **No installer, no setup wizard, no automation script**

---

## 6. Out-of-Scope

แบ่งเป็น 2 ระดับ — **Won't (Phase 1)** = defer ไปอนาคต, **Won't (Permanent)** = ตัดถาวรตาม project constraints.

### 6.1 Won't Have — Phase 1 (defer Phase 2 หรือภายหลัง)

| Item | Reason | Notes |
|------|--------|-------|
| News-filter integration | User Q4.2 = "ยังไม่มี"; defer Phase 2 | NotebookLM #2 (calendar API) + #5 (news trading) มีข้อมูลพร้อมใช้เมื่อต้องการ |
| Equity-floor circuit breaker (close-all เมื่อ DD ≥ X%) | OQ-6 ✅ resolved 2026-05-01 = defer Phase 2; Phase 1 เก็บ monitor-only via `WatchProfits` | locked |
| Real-time dashboard panel | UX feature; defer Phase 2 | Solo operator — ไม่จำเป็น |
| Walk-forward optimization interface | Nice-to-have; Phase 2 | Strategy Tester native sweep พอใช้ใน MVP |
| Partial-close / advanced trailing variants | Strategy locked (D1) — ของเดิมไม่มี | — |
| sqlite persistence (replace text DB) | P2.4 atomic write จะ partial-cover; full sqlite = Phase 2 | Trade journal format จะคำนึงถึง future migration path |

### 6.2 Won't Have — Permanent (out of project scope ทั้ง Phase 1 + Phase 2)

| Item | Reason |
|------|--------|
| **Installer / setup wizard** | MVP signal 2026-05-01 — user copy `.mq5/.ex5` ด้วยมือ |
| **Server-side component** (web service, REST API, gRPC, MQTT) | MVP signal 2026-05-01 — เก็บทุกอย่างใน MT5 process |
| **VPS / hosting setup / deployment automation** | MVP signal 2026-05-01 + Q3.3 — focus software เท่านั้น |
| **Web dashboard / mobile app** | Solo operator + MVP signal — ไม่จำเป็น |
| **Telegram / email / webhook notifications** | Q3.4 = "ไม่มี" + MVP signal |
| **Cloud trade journal / remote sync / analytics** | MVP signal — journal เก็บ local ใน `MQL5/Files/` เท่านั้น |
| **Multi-symbol portfolio** | Constraint C-3 — EURUSD only |
| **Cross-broker support** | Constraint C-5 — FBS only |
| **Port platform อื่น** (cTrader / NinjaTrader / Python / TradingView) | Constraints C-1, C-2 — MT5/MQL5 only |
| **Strategy alteration / new signal logic / ML overlay** | Direction D1 — strategy locked, copy ของเดิม 1:1 |
| **Multi-account / portfolio split / risk allocator** | Solo single-account |
| **Re-entrancy / mutex protection** | CodeWiki §6.3 — relies on single-threaded broker tick (acceptable) |
| **Unit tests** | CodeWiki §6.3 — MQL5 ecosystem ไม่ค่อย support; QA Phase ใช้ Strategy Tester regression แทน |
| **Slippage control parameter** | CodeWiki §6.3 — FBS Standard default พอใช้ใน MVP; live drift ยอมรับใน operating envelope |

---

## 7. Constraints

ข้อจำกัดที่ทุก downstream phase ต้อง honor — ห้าม Architect/Tech Lead ตั้งคำถามใหม่.

> **Marker convention:** ❌ No = hard constraint (Phase 1 + Phase 2 ห้ามเปลี่ยน); 🟡 Soft = negotiable Phase 2 พร้อม impact assessment (Phase 1 lock); ⚠️ marker **สงวนไว้สำหรับ assumption / bug-fix flag** ใน FR/BR/AC เท่านั้น — **ไม่** ใช้ใน constraint table

| # | Constraint | Reason | Negotiable? |
|---|-----------|--------|-------------|
| **C-1** | MetaTrader 5 (Windows) only | Trading platform ของ user | ❌ No |
| **C-2** | MQL5 language | Native EA language สำหรับ MT5 | ❌ No |
| **C-3** | EURUSD symbol only | EA tuned สำหรับคู่นี้ — `OnInit` reject อื่น | ❌ No (Phase 1) |
| **C-4** | H4 indicator timeframe | Signal substrate ทั้งหมด (Ichimoku, ADX, Force, Bollinger, WPR, DeMarker) อยู่บน H4 ผ่าน indicator handle ภายใน — chart period ไม่กระทบ | ❌ No |
| **C-5** | Broker FBS Markets Inc. — Standard account | Live broker ของ user | 🟡 Soft — ผลกระทบ spread/swap แต่ไม่เปลี่ยน |
| **C-6** | Capital tier USD 500 – 1,000 | Minimum operating size | 🟡 Soft |
| **C-7** | Leverage 1:500 | Broker setting | 🟡 Soft |
| **C-8** | Risk profile: High (10–30% MoM target, 50% max DD acceptable) | User's stated risk appetite (operating envelope, not AC) | ❌ No |
| **C-9** | Solo operator | ไม่มีทีม ops/DevOps/QA — UX ผ่าน MT5 native dialog เท่านั้น | ❌ No |
| **C-10** | Broker server timezone EET (GMT+2 winter, GMT+3 summer DST transitions ใน last Sunday Mar/Oct) | Confirmed 2026-05-01 — กระทบ time filter | ❌ No |
| **C-11** | Backtest baseline = `ReportTester-25045474.html` (5-yr 2021-2025, FBS-Real Build 5833, $1k init, 1:500 leverage, 1-minute OHLC tick model 0% real ticks) | Regression contract ตาม `trading-baseline.md` — ใช้ tick model + period นี้ตอน QA | ❌ No |
| **C-12** | Deliverable form: `.mq5` + `.ex5` + libs ใน `MQL5/Experts/` ด้วยมือ; ไม่มี installer/server/VPS | MVP signal user 2026-05-01 — *"สุดท้ายต้องการแค่ EA ไม่ต้องทำ Install หรือ Server"* | ❌ No |

---

## 8. Glossary

ศัพท์โดเมน + acronym + ชื่อระบบภายในที่ใช้ตลอด BA package. ห้าม downstream agent เดาความหมายเอง.

| Term | Meaning |
|------|---------|
| **Slot** | Letter-coded sub-strategy ของ EA — แต่ละ slot มี entry function + exit function + magic number ของตัวเอง. Rewrite Phase 1 มี **21 slots active**: `C`, `D`, `F`, `J`, `H`, `K`, `G`, `G2`, `GO`, `M`, `L`, `LX`, `Q`, `R`, `I`, `P`, `T`, `S`, `B`, `BR`, `BI`. Slot `U` ของ EA เดิมถูกลบทิ้งใน rewrite (per OQ-8 user decision 2026-05-01) |
| **Magic** (number) | Integer ที่ MT5 ใช้แท็ก order ของแต่ละ slot (range 200..220 per CodeWiki §1.5) เพื่อแยก order ของ EA จาก order อื่น. Rewrite ใช้ 200..219 (220 = MagicU = ไม่ใช้ เพราะ U ถูกลบ) |
| **CD pool** | Slot `C` และ `D` ใช้ magic เดียวกัน (`MagicCD` = 200) — `D` เป็น 4-line wrapper ของ force-pending workflow ของ `C` |
| **OnTick** | MT5 event handler ที่ run ทุก tick — pipeline หลักของ EA (CodeWiki §2.2) |
| **OnInit** | MT5 event handler ที่ run ตอน EA load — สร้าง indicator handles, restore state, validate symbol |
| **Pseudo-parameter** | Global variable ที่ EA ปัจจุบันใช้แทน `input` declaration — ปรับค่าได้แค่ตอน compile (เป้าหมายของ G1 = แทนที่ด้วย `input`) |
| **Pending state machine** | Per-slot internal state ที่ EA จัดเก็บใน `<login>_DB.txt` — **ไม่ใช่** broker-side pending order; เป็น in-EA state ที่บอกว่า slot รอ trigger เปิด market order |
| **CodeWiki** | `PhoenicisN2.10_CodeWiki.md` — ไฟล์ analysis 8-section ที่ใช้เป็น spec ของ rewrite (CodeWiki §X = section X ของไฟล์นั้น) |
| **Baseline** | ผล Strategy Tester ของ `PhoenicisN2.10_stable.mq5` ตาม `trading-baseline.md` ที่ใช้เป็น regression contract |
| **Behavioral parity** | Rewrite ต้องเทรดด้วย pattern คล้ายเดิม + Total Net Profit deviation ≤ 25% (ไม่ต้อง tick-by-tick เหมือน) |
| **Bug-for-bug compatibility** | Preserve bugs ของเดิมไว้ใน rewrite เพื่อไม่ให้ behavioral parity เสียไป — **ตรงข้าม** กับการ fix bugs (decision G4 = FIX, ไม่ preserve) |
| **Bucket A drift** | Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). **Includes** intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`) |
| **Bucket B drift** | Informational delta `rewrite-G4-ON − rewrite-G4-OFF` ที่บันทึก sign + magnitude ของ intentional G4 fix contribution — **no acceptance gate** per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12). Post-BT-002 2026-05-17: `DISABLE_G4_FIXES` build runs end-to-end ของ 5-yr window ได้โดยไม่มี CircuitBreaker halt artifact (BR-3.6 detector removed legacy-parity per `backtrack-log.md § BT-002`); pre-BT-002 partial-pre-halt-window concept obsoleted — full-window measurement ตอนนี้ available |
| **Slot orchestrator** | ตัวเรียก `BusinessLogic_X` + `ExtraTakeProfit_X` ตามลำดับ exit-before-entry ทุก tick (CodeWiki §2.2) |
| **MarketContext snapshot** | Indicator-value bundle ที่ build ครั้งเดียวต่อ tick + ทุก slot อ่านจาก bundle เดียวกัน (เป้าหมายของ rewrite ตาม CodeWiki §7.2) — concrete struct/class shape ลงรายละเอียดใน TD |
| **PortfolioState** | Per-slot state lookup (buyCount/sellCount/totalLots/totalProfit/lastOpenDate/pendingState) ที่ slot อ่านได้ผ่าน magic identifier ใน O(1) แทน global variable swarm `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` ของ EA เดิม (CodeWiki §7.2) — concrete data structure (associative container, struct array, ฯลฯ) = TD decide |
| **Trade Journal** | Local file (format = JSON-lines per OQ-3 ✅ 2026-05-01) ใน `MQL5/Files/` ที่บันทึกทุก order event ของ EA — **ไม่ใช่** MT5 broker history (ซึ่งเก็บเฉพาะ trade summary) |
| **Force-pending** | Cross-slot pending state ที่ใช้กับ slot CD เมื่อ `ForceDivergentWorking` set flag (CodeWiki §2.5) |
| **Safe port** | คำเรียก `OrderGroupStartWorkflow` cleanup — ปิด weak orders 10 slots พร้อมกันเมื่อ avg badPIP > 55 + currentProfit > 0 (CodeWiki §5.5) |
| **Bug-fix bucket** | (deprecated post-BT-001 2026-05-12) — เดิมหมายถึง 2-bucket deviation budget แยก Bucket A pattern parity จาก Bucket B intentional fix; ปัจจุบัน Bucket B ไม่เป็น budget แล้ว — ดู NFR-1.8 + `03 § NFR-1 Empirical Citation` แทน |
| **Regression contract** | Acceptance threshold ที่ rewrite ต้องผ่านใน QA: \|ΔNet Profit\| ≤ 25%, ΔPF ≥ −0.2, ΔTrade count ±15%, ΔWin rate ±5pp (ดู `trading-baseline.md`) |
| **EET** | Eastern European Time — broker server timezone ของ FBS (Winter GMT+2; Summer GMT+3 DST). DST switch = last Sunday of March (start) / October (end) |
| **DST** | Daylight Saving Time — broker server shift +1 hour; กระทบ time filters ใน EA |
| **input dialog** | MT5 native UI สำหรับ set EA `input` parameters ก่อน attach กับ chart |
| **`MQL5/Files/`** | MT5 sandbox folder ที่ EA เขียน/อ่านไฟล์ได้ผ่าน `FileOpen()` — local-only, no remote sync |
| **MoSCoW** | Prioritization scheme — Must/Should/Could/Won't (ดู `02-functional-requirements.md`) |
| **AC** | Acceptance Criteria — Given/When/Then format ใน user stories (`02-functional-requirements.md`) |
| **NFR** | Non-Functional Requirement — ดู `03-non-functional-requirements.md` |
| **OQ-N** | Open Question N — ดู ideation-brief.md และ Open Questions section ใน 02-05 |
| **H1** | Hypothesis #1 — default `input` value = current global setting 1:1 → backtest reproducibility (ideation-brief). ใช้เป็น regression baseline |
| **H2** | Hypothesis #2 — slot abstraction + indicator snapshot + per-slot state lookup จะใส่ indirection overhead ≤ 10% tick latency (ideation-brief; verified by NFR-2.1) |
| **H3** | Hypothesis #3 — trade journal write-on-event ≤ 5 ms/tick avg ที่ FBS server tick rate (ideation-brief; verified by NFR-2.2) |

### 8.1 Trading Indicators (referenced ใน FR/BR/Flow ทุกที่)

ทุก indicator ใช้ผ่าน MT5 native handle (`iCustom`, `iIchimoku`, `iMACD`, ฯลฯ) — definition โดย MetaQuotes; CodeWiki §1.4 list parameter set + timeframes ที่ EA เดิมใช้. รายชื่อด้านล่างคือ shorthand ที่ใช้ตลอด BA package — ไม่ใช่ TD spec.

| Indicator | Used by slot | Timeframe | 1-line meaning |
|-----------|--------------|-----------|----------------|
| **Ichimoku** (`iIchimoku`) | C, D, F, J, H, K, G, GO, M, L, LX, Q, R, B, BR, BI, P, T, S | H4, D1 | Cloud (Senkou A/B) ใช้เป็น dynamic SR; Tenkan/Kijun = momentum lines; Chikou = lagging confirm |
| **Force Index** (`iForce` หรือ custom) | C, J, G, GO, M, L, B, P | H4 | Volume-weighted price momentum — ascend/descend sequence ใช้เป็น signal trigger (เช่น `ForcePeak3=ascending`) |
| **ADX** (`iADX`) | C, K, G | H4, D1 | Directional strength — ใช้เป็น trend filter (`ADXW` = ADX wave) + cooldown gate |
| **WPR** (Williams %R, `iWPR`) | C, H, L, S | H4, D1, M15 | Overbought/oversold oscillator — extreme + wave pattern ใช้เป็น exit/entry signal |
| **Bollinger Bands** (`iBands`) | R, B, BR, BI, P, T, S | H4 | BBTop/BBBot/BBWidth — ใช้เป็น SL anchor (เช่น "≥ 90 pip from BBand") + breakout filter |
| **DeMarker** (`iDeMarker`) | LX, M | H4, M15 | Cycle oscillator — ใช้เป็น pyramid gate (LX) + entry confirm (M) |
| **Stochastic** (`iStochastic`) | C (ForceCutloss), L | M10, H4 | Cross-confirm signal (เช่น Stochastic M10 + MACD D1 = ForceCutloss trigger) |
| **MACD** (`iMACD`) | C (ForceCutloss, COverload) | M10, D1 | Momentum confirm; same-sign losses ≥ 7 bars trigger COverload |
| **RSI** (`iRSI`) | helper indicators | H4 | Reference oscillator |
| **Hull Moving Average** | T, P | H4 | Smooth trend reference; Hull-based SL anchor (ดู BR-5.1 T row) |
| **Fractal** (`iFractals`) | G, K | H4 | Swing-high/low marker — ใช้เป็น SL anchor (G fractal floor) + TP target (K) |
| **ZigZag** | wave detection | M5 | Zig-zag pattern — wave-peak detection สำหรับ S/L logic |
| **SubDem** (custom indicator) | — | H4, D1 | Custom support/demand zones (CodeWiki §1.4); referenced โดย DrawProfitTags visual hook |

> **Why these matter:** Indicator value ใน MarketContext snapshot (FR-2.6) = subset ของ list นี้; trade journal `indicator_snapshot` field (FR-4.1) บันทึก subset relevant ต่อแต่ละ slot. PM/Architect อ่าน FR/BR ที่อ้าง "WPRWaveSignal", "ForcePeak3=ascending", "cloud-touch" จะรู้ว่ามาจาก indicator ตัวไหน

### 8.2 EA Helper Function Naming (ระบบเดิม + rewrite preserve)

EA เดิมใช้ naming convention ของ helper function ที่ FR/BR/Flow อ้างถึงตลอด — list ด้านล่างคือ pattern ไม่ใช่ TD's API spec (concrete refactor target = TD ตัดสินใจ).

| Pattern | ตัวอย่าง | Meaning |
|---------|----------|---------|
| `BusinessLogic_<X>` | `BusinessLogic_C`, `BusinessLogic_J`, `BusinessLogic_M` | Entry function ของ slot X — evaluate signal + condition + เปิด market order ถ้า trigger valid |
| `BusinessLogic_<X>_Pending` | `BusinessLogic_PendingT`, `BusinessLogic_P_Pending` | Pending-state evaluator — รับ tick + ตัดสินใจว่า pending state จะ EXECUTED หรือ IDLE |
| `ExtraTakeProfit_<X>` | `ExtraTakeProfit_C`, `ExtraTakeProfit_J`, `ExtraTakeProfit_G` | Exit function ของ slot X — manageExits, trailing, post-exit hooks (เช่น `ExtraTakeProfit_G` triggers `GOverload`) |
| `OpenOrder<X>` | `OpenOrderCD`, `OpenOrderH`, `OpenOrderG` | Helper ที่ apply lot trim + submit order ผ่าน MT5 `CTrade` |
| `Calculate<X>` | `CalculateLotSize` | Helper ที่คำนวณ base lot ตาม risk% × balance |
| `<Slot><Action>Date` (state) | `BanCStartDate`, `BanLStartDate`, `KLastOrderDate` | Per-slot ban/cooldown state — ดู BR-3.4 |
| Cross-slot helpers | `OrderGroupStartWorkflow`, `OrderGroupStartWorkflow2`, `ForceCutloss`, `EOverload`, `COverload`, `GOverload`, ~~`CircuitBreakerOrder`~~ (REMOVED in rewrite per BT-002 2026-05-17 legacy-parity — legacy MQ5 ยังมี function นี้, rewrite ไม่ port), `WatchProfits`, `ReadTradeData`, `LoadGlobal`, `SaveFileDatabase`, `RegisterB`, `LotInitial2`, `FindCP`, `TickLoadBuffer`, `RunCheckWPRWaveWithIchimoku2`, `CheckADXWithForcePeakValid2`, `ExtraCheckFunction2` | ดู FR-7.x + BR-8.x + flow F1/F6 — แต่ละตัว preserve 1:1 trigger + action ตาม CodeWiki §5.5 / §2.2; ยกเว้น CircuitBreakerOrder ที่ BT-002 ลบทิ้ง (per `backtrack-log.md § BT-002`) |

> **Why these matter:** Trade journal `triggering_function` field (FR-4.1, F7.5 schema) เก็บชื่อ function ที่เปิด/ปิด order — ใช้ตอน retrospective ว่า trade ถูก fire จาก path ไหน. CodeWiki section ที่ relevant = §3 (per-slot logic), §4 (lot/SL/TP), §5 (cross-slot helpers), §2 (orchestration). TD จะ refactor pair `BusinessLogic_<X>` + `ExtraTakeProfit_<X>` ให้อยู่ใน slot abstraction (FR-2.5) — naming อาจเปลี่ยนหลัง refactor

---

## 9. Reference Materials

ทุกเอกสารใน `docs/foundation-input-sources/` ที่ใช้เป็น source-of-truth — Architect/Tech Lead/QA หยิบไป cross-reference ได้.

| File | Role |
|------|------|
| `project-overview.md` | Identity + stakeholders + constraints |
| `ideation-brief.md` | Phase 0 chosen direction (D1-D7) + Not-Doing list + open questions |
| `improvement-targets.md` | Ranked pain inventory (P1-P4) cross-reference CodeWiki §6/§7 |
| `trading-baseline.md` | Regression contract + Bucket A (rewrite-G4-ON vs baseline per NFR-1.1) + Bucket B (informational delta per NFR-1.8 — no acceptance gate, post-BT-001 re-baseline 2026-05-12) |
| `PhoenicisN2.10_CodeWiki.md` | As-Is technical analysis (8 sections) ใช้เป็น spec ของ rewrite |
| `ReportTester-25045474.html` | Raw Strategy Tester report — source ของ baseline numbers |
| `notebooklm.md` | 8 NotebookLM notebooks (queryable via MCP) — เน้น #5 news, #6 time-series, #8 retail-stats |

---

## 10. Resolved Questions for Architect (Phase 1B)

✅ **All 5 BA-domain open questions resolved 2026-05-01** — Architect (Phase 1B) ไม่ต้องตอบ Q เพิ่มจากฝั่ง BA, focus ที่ tech decisions ของ SD phase ได้เลย:

| Open Q | Domain | Status (2026-05-01) | Doc |
|--------|--------|--------------------|------|
| **OQ-3** Trade journal storage format | FR | ✅ JSON-lines (BA default) | `02 § 12` |
| **OQ-3.3** BI SL inheritance semantic | Rule | ✅ same SL distance (BA default) | `04 § 12` |
| **OQ-6** Equity-floor switch | NFR (safety) | ✅ monitor-only Phase 1 (BA default) | `03 § 10` |
| **OQ-7** Per-slot trade-count tolerance | NFR (regression) | ✅ ±15% / >30% (BA default) | `03 § 10` |
| **OQ-8** Slot U disposition | FR (scope) | ✅ **DELETE** (user override of BA default) | `02 § 12` |

### 10.1 Open Questions Raised for Architect (post-rebuttal-01)

⚠️ **Architecture-domain Open Questions** — Phase 1B Architect ต้อง resolve ตอน design state cleaner / pending state machines. BA flag เป็น OQ-A1/A2/A3 และไม่ propose ตัวเลข เพราะเป็นเรื่องของ **HOW** (force-clear safety policy = state cleaner design):

| Open Q | Domain | Doc | Resolver | Status |
|--------|--------|-----|----------|--------|
| **OQ-A1** (M-Pending force-clear safety policy) | Architecture | `04 § BR-6.5` | Architect Phase 1B | ⏸ pending |
| **OQ-A2** (T-Pending force-clear safety policy) | Architecture | `04 § BR-6.6` | Architect Phase 1B | ⏸ pending |
| **OQ-A3** (Q-Pending force-clear safety policy) | Architecture | `04 § BR-6.7` | Architect Phase 1B | ⏸ pending |

**Why raised:** EA เดิมไม่มี hard timeout สำหรับ M/T/Q-Pending state — invalidation มี 2 แบบเท่านั้น (trigger condition met หรือ signal flip). ถ้า price stuck ใน range + signal ไม่ flip → state อาจค้าง PENDING ตลอด session → state file โต. Architect ต้องตัดสินใจ trade-off ระหว่าง "no force-clear" (preserve baseline) vs "safety force-clear with state file growth bound" + document reasoning ใน SD ADR

**Phase 2 deferred items (referenced):**
- **FR-7.7 escalation alert** (long-running halt + user away) — Phase 2 BA, doc `02 § FR-7.7 known gap`
- **Security NFR category** (auth/transport encryption/key management) — Phase 2 BA, trigger เมื่อมี cloud journal/Telegram/multi-account, doc `03 § 5 Security note`

> **End of 01 — Project Brief**
