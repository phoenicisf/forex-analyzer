# Project Overview — PhoenicisNex

> Foundation document สำหรับ BA / SD / TD / Impl pipeline — ทุก prompt template อ่านไฟล์นี้
> Last updated: 2026-05-01

## TL;DR

PhoenicisNex คือการ **rewrite จากศูนย์** ของ EA `PhoenicisN2.10_stable.mq5` (22,016 LOC, MQL5) ให้เป็นโค้ดที่บำรุงรักษาได้ ปรับ parameter ได้โดยไม่ recompile และมี trade journal สำหรับ retrospective — โดยผลการเทรดบน EURUSD H4 ต้อง deviate จาก backtest baseline เดิมไม่เกิน **25% ของ P&L** เก็บ slot scaffold ทั้งหมดในรอบแรก แล้วพิสูจน์ผลก่อนตัด/rename ภายหลัง

## Identity

| Field | Value |
|-------|-------|
| **System Name** | PhoenicisNex |
| **Source Lineage** | rewrite of `Phoenicis-n v2.10` (`MQL5\Experts\PhoenicisN2.10_stable.mq5` + 5 libs) |
| **Domain** | Internal Tool — Algorithmic Forex Trading |
| **Stage** | Migration → **Greenfield rewrite** (CodeWiki เป็น spec; ไม่ branch จาก source โดยตรง) |
| **Platform** | MetaTrader 5 (Windows; MQL5) |
| **Repository / Working tree** | `MQL5\Experts\` (legacy); rewrite output path TBD ใน TD phase |

## Stakeholders

| Role | Person | Responsibilities | Notes |
|------|--------|------------------|-------|
| Owner / Trader | Self (solo) | กำหนดทิศทาง / approve / รัน live / รัน backtest | ใช้ EA คนเดียว — ไม่มี partner / ops team / accountant |
| Reviewer | Self | Sign-off code changes, validate behavioral parity | อ่าน MQL5 ได้สบาย แต่ delegate การเขียนให้ AI Agent |
| Implementer | AI Agent (Claude) | เขียน + refactor + เทส | ตาม BA → SD → TD → Impl pipeline ใน `.claude/commands/` |

## Business Goals & Success KPIs

ลำดับความสำคัญ (เลขน้อย = สำคัญกว่า):

| # | Goal | Success KPI | Why |
|---|------|-------------|-----|
| **G1** | **Maintainability** — code อ่าน/แก้/tune ได้โดยไม่ recompile | ≥ 80 magic numbers (ตาม CodeWiki §6.1) ทั้งหมดเป็น `input`/`sinput` declaration; ไม่มีไฟล์ไหน > 5,000 LOC | ปัจจุบัน tune parameter ทีต้อง edit code → recompile → restart MT5; optimization sweep ผ่าน Strategy Tester ทำไม่ได้ |
| **G2** | **Observability** — ทุก trade ค้นย้อนได้ | ทุก order entry / exit / modification → log record (slot, magic, signal context, indicator snapshot, lot, SL, TP, comment, timestamp) — query/filter ได้ภายหลัง | "ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด" — gap ที่ user เพิ่มในการสัมภาษณ์ |
| **G3** | **Behavioral preservation** — pattern คล้ายเดิม | Backtest 2020-2025 EURUSD H4: \|ΔTotal Net Profit\| ≤ 25% เทียบ baseline (ดู `trading-baseline.md`); Profit Factor ลดลง ≤ 0.2 จุด | ห้ามทำ EA ที่ทำงานดีอยู่แล้วเสีย |
| **G4** | **Safety remediation** — fix critical bugs (decided 2026-05-01) | Bugs ระดับ CRITICAL/HIGH ใน CodeWiki §6.2 — **decision: FIX**: (a) BI orders ต้องมี SL (อิงจาก B parent); (b) `ExtraTakeProfit_J` iterate magic ต้องเป็น `MagicJ` ไม่ใช่ `MagicF`. Deviation จาก fix → bucket B ของ regression budget (`trading-baseline.md`) | BI = naked exposure; J = exit logic ไม่ทำงานเลย → live risk ที่ user ไม่ควรรับสืบทอด |

> **Note on operating envelope** (ไม่ใช่ acceptance criteria): EA เดิมตั้งเป้า 10–30% ROI/เดือน, max drawdown ≤ 50%, จัดเป็น **High Risk** profile. ตัวเลขเหล่านี้สำหรับ live trading; rewrite ไม่ต้องบรรลุตรง — แค่ไม่เสีย behavioral parity ตาม G3

## In-Scope / Out-of-Scope (ระดับสูง — `/ba` จะลงรายละเอียด)

### In-Scope (Must Have ใน Phase 1)
- All 17+ slots ของ EA ปัจจุบัน (C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, P, T, S, B, BR, BI, U) — เก็บ scaffold 1:1, **ตัด/ rename ภายหลัง** เมื่อพิสูจน์ behavioral baseline (Q5.2)
- Parameterize ≥ 80 magic numbers จาก CodeWiki §6.1 → MT5 `input`
- **Trade journal layer** (ค้นย้อนได้ — schema ตัดสินใจใน BA/SD)
- Critical bug remediation per CodeWiki §6.2 (BI no-SL, ExtraTakeProfit_J) — explicit decision ใน BA
- Architecture refactor (slot interface, MarketContext snapshot, PortfolioState map) ตาม CodeWiki §7.2
- Symbol whitelist guard (`OnInit` reject ถ้า `_Symbol != "EURUSD"`)

### Out-of-Scope (Won't Have ในรอบนี้)
- Multi-symbol portfolio (EURUSD เท่านั้น)
- Multi-timeframe ของ chart attach (H4 มาจาก indicator handle ภายใน — chart period ไม่กระทบ)
- Port platform อื่น (cTrader / NinjaTrader / Python / TradingView)
- VPS provisioning / hosting setup (focus software เท่านั้น — Q3.3)
- News-filter integration (Phase 2 — Q4.2)
- Web dashboard / Telegram alerts (Phase 2 — Q3.4 = ไม่มี)
- Equity-floor circuit breaker (Phase 2 — open question)
- กลยุทธ์เทรดใหม่ / signal logic ใหม่ — ของเดิมเท่านั้น
- Multi-account / portfolio split / risk allocator

## Constraints

| # | Constraint | Reason | Negotiable? |
|---|-----------|--------|-------------|
| C-1 | MetaTrader 5 (Windows) | Trading platform | ❌ No |
| C-2 | MQL5 language | Native EA language สำหรับ MT5 | ❌ No |
| C-3 | EURUSD only | EA tuned สำหรับคู่นี้เท่านั้น | ❌ No (รอบนี้) |
| C-4 | H4 indicator timeframe | Signal substrate ทั้งหมด (Ichimoku, ADX, Force, Bollinger, WPR, DeMarker) อยู่บน H4 | ❌ No |
| C-5 | Broker: **FBS Markets Inc — Standard account** | Live broker ของ user | ⚠️ affects spread/swap แต่ไม่เปลี่ยน |
| C-6 | Capital tier: **USD 500 – 1,000** | minimum operating size | ⚠️ |
| C-7 | Leverage: **1:500** | broker setting | ⚠️ |
| C-8 | Risk profile: **High** (10–30% MoM target, 50% max DD acceptable) | User's stated risk appetite | ❌ No |
| C-9 | Solo operator | ไม่มีทีม ops / DevOps / QA — UX ต้องคำนึงถึง | ❌ No |
| C-10 | **Broker server timezone: EET** — Winter GMT+2 (last Sunday Oct → ); Summer GMT+3 DST (last Sunday Mar → ) | กระทบ time filter (`IsMondayMorningWakeup`, `IsNewYearSeason2`, hour-based cooldowns) — DST transition ต้อง handle ใน rewrite | ✅ Confirmed 2026-05-01 |

## Known Pain Points (summary — ดูรายละเอียดใน `improvement-targets.md`)

User-confirmed priorities (อ้างอิง CodeWiki §6.2 + user input Q4.1):

1. **No `input` parameters** — recompile ทุกครั้งที่ tune (CodeWiki §6.2 HIGH)
2. **No trade journal** — เรียนรู้จากความผิดพลาดไม่ได้ (user-added)
3. **2 safety bugs ใน prod** — BI SL=0 (CRITICAL), ExtraTakeProfit_J magic ผิด (HIGH)
4. **22k LOC monolith** — debug / onboarding ไม่ไหว
5. **Slot magic-collision + comment-string state schema** — fragile
6. + อีก ~10 ข้อรอง — ดู `improvement-targets.md`

## Reference Materials

ในโฟลเดอร์ `docs/foundation-input-sources/`:

| File | Role |
|------|------|
| `PhoenicisN2.10_CodeWiki.md` | **As-Is technical analysis** (8 sections, 22k-LOC EA + 5 libs) — ใช้เป็น spec ของ rewrite |
| `improvement-targets.md` | **Ranked pain inventory** (cross-ref CodeWiki §6/§7 + user priorities) |
| `trading-baseline.md` | **Regression contract** ✅ FILLED — baseline จาก `ReportTester-25045474.html` (5-yr 2021-2025, FBS-Real, $1k → $24.27M, PF 8.96, Sharpe 9.17) |
| `ReportTester-25045474.html` | Raw Strategy Tester report — source ของ baseline numbers |
| `ideation-brief.md` | **Phase 0 chosen direction** + Not-Doing list + open questions |
| `notebooklm.md` | 8 NotebookLM notebooks — query ผ่าน MCP (เน้น #5 news, #6 time-series, #8 retail-stats) |

Source-of-truth code: `MQL5\Experts\PhoenicisN2.10_stable.mq5` + libraries `LibCommon1.1`, `LibIndicator1.1`, `LibSubDem1.6`, `LibDatabase1.1`, `LibMonitor1.1`

## Glossary (seed สำหรับ BA — `01-project-brief.md § Glossary` จะขยายต่อ)

| Term | Meaning |
|------|---------|
| **Slot** | letter-coded sub-strategy (C, D, J, H, K, G, M, L, Q, R, I, P, T, S, B, BR, BI, U …) — แต่ละ slot มี entry function + exit function + magic number ของตัวเอง |
| **Magic** (number) | integer ที่ MT5 ใช้แท็ก order ของแต่ละ slot (200..220) เพื่อแยก order ของ EA จาก order อื่น |
| **CD pool** | Slot C และ D ใช้ magic เดียวกัน (200) — D เป็น 4-line wrapper ของ force-pending workflow ของ C |
| **OnTick** | MT5 event handler ที่ run ทุก tick — pipeline หลักของ EA |
| **Pseudo-parameter** | global variable ที่ EA ปัจจุบันใช้แทน `input` declaration — ปรับค่าได้แค่ตอน compile |
| **Pending state machine** | per-slot internal state ที่ EA จัดเก็บใน `<login>_DB.txt` — ไม่ใช่ broker-side pending order |
| **CodeWiki** | `PhoenicisN2.10_CodeWiki.md` — ไฟล์ analysis ที่ใช้เป็น spec ของ rewrite |
| **Baseline** | ผล Strategy Tester ของ `PhoenicisN2.10_stable.mq5` ตาม `trading-baseline.md` ที่ใช้เป็น regression contract |
| **Behavioral parity** | rewrite ต้องเทรดด้วย pattern คล้ายเดิม + Total Net Profit deviation ≤ 25% (ไม่ต้อง tick-by-tick เหมือน) |
| **Bug-for-bug compatibility** | preserve bugs ของเดิมไว้ใน rewrite เพื่อไม่ให้ behavioral parity เสียไป — ตรงข้ามกับการ fix bugs |
| **Slot orchestrator** | ตัวเรียก `BusinessLogic_X` + `ExtraTakeProfit_X` ตามลำดับใน OnTick (ดู CodeWiki §2.2) |
| **MarketContext snapshot** | struct ที่ build ทุก tick เพื่อรวบ indicator values ทั้งหมดในที่เดียว (เป้าหมายของ rewrite ตาม CodeWiki §7.2) |
| **PortfolioState** | `Map<int magic, SlotState>` ที่จะแทน global variable swarm `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` (CodeWiki §7.2) |
