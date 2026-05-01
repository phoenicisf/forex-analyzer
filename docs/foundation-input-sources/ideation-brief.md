# Ideation Brief — PhoenicisNex

> Phase 0 output (`/ideate` workflow equivalent) — capture chosen direction + Not-Doing list + open questions ก่อนเข้า BA
> Last updated: 2026-05-01

## TL;DR

ปัญหา: EA `PhoenicisN2.10_stable.mq5` (22,016 LOC) ให้ผลกำไรดีในการเทรด (target 10–30% MoM, max DD 50%, EA High Risk) แต่ code ไม่มี `input` parameter เลย ไม่มี trade journal มี 17+ slots ที่ overlap กัน และมี 2 safety bugs ที่ live อยู่ในระบบ — บำรุงรักษาไม่ไหว

ทิศทางที่เลือก: **Rewrite จากศูนย์** (Q1.1 = ง) ใช้ `PhoenicisN2.10_CodeWiki.md` เป็น spec, เก็บ slot scaffold ทั้ง 17+ ก่อน (ตัด/ rename หลังพิสูจน์ behavioral baseline), P&L deviation ≤ 25% เทียบ backtest baseline 2020-2025

## Problem Statement

EA ปัจจุบันมีผล **backtest "ค่อนข้างดี"** (ไม่มี live track record — Q2.2) แต่:

- **Zero `input`/`sinput`/`extern` declarations** — tune parameter ทีต้อง edit code → recompile → restart EA → state อาจ corrupt (CodeWiki §1.3 + §6.2 HIGH)
- **ไม่มี trade journal/audit trail** — ดู trade ที่ขาดทุนเก่าไม่ออกว่า slot ไหนทำ, signal context อะไร, indicator value เท่าไรตอนเปิด/ปิด ("ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด" — Q4.1)
- **22,016 LOC ไฟล์เดียว + 5 libraries** — onboarding/debug ใช้เวลามาก, AI agent ก็ติด context limit
- **2 critical safety bugs ที่ค้างใน prod** (CodeWiki §6.2):
  - `BI orders เปิดด้วย SL=0` — naked exposure (CRITICAL `:20326 :20357`)
  - `ExtraTakeProfit_J iterates MagicF (=201) แทน MagicJ (=206)` — J orders ไม่ถูกจัดการโดย exit function ของตัวเอง (HIGH `:10897`)
- **17+ slots overlap + comment-string state schema** — slot อาจ fire พร้อมกันโดยไม่มี mutex; G/G2 และ B/BI ใช้ magic เดียวกัน (CodeWiki §6.2)
- **No symbol whitelist** — attach EA กับ chart อื่นแล้วรัน trade ผิด symbol (CodeWiki §6.3)

## Chosen Direction (decided 2026-05-01)

| # | Question | Decision | Source |
|---|----------|----------|--------|
| D1 | Refactor / parameterize / rewrite? | **Rewrite from scratch** | Q1.1 = ง |
| D2 | จำนวน slot ที่เก็บ | **เก็บทั้ง 17+ ก่อน** — ตัด/rename หลังพิสูจน์ behavioral baseline | Q1.2 |
| D3 | Symbol/timeframe scope | **EURUSD H4 only** — indicator-driven, chart timeframe ไม่ใช่ประเด็น | Q1.3 |
| D4 | Behavioral contract | **Pattern คล้าย + P&L deviation ≤ 25%** (ไม่ต้อง tick-by-tick) | Q5.1 |
| D5 | Slot trim policy | **ทดลองทุก slot ก่อน → drop เมื่อพิสูจน์ผลแย่** | Q5.2 |
| D6 | Stakeholder model | **Solo operator** | Q6.1 |
| D7 | Implementation labor | **AI Agent เขียน, user review/sign-off** | Q6.2 |

## Not-Doing List (Phase 1 — ห้ามแตะ)

หลีกเลี่ยง scope creep โดยกำหนดล่วงหน้า:

- ❌ Multi-symbol / multi-broker portfolio
- ❌ Port platform อื่น (cTrader / NinjaTrader / Python / TradingView)
- ❌ News-filter integration (defer Phase 2 — Q4.2)
- ❌ Web dashboard / Telegram / email alerts (defer Phase 2 — Q3.4 = ไม่มี)
- ❌ กลยุทธ์ใหม่ / signal logic ใหม่ — ใช้ของเดิมเท่านั้น
- ❌ VPS / hosting setup — focus software (Q3.3)
- ❌ Equity-floor circuit breaker — defer Phase 2 (OQ-6 — เปิดเป็น open question)
- ❌ Multi-account / risk allocator
- ❌ Partial-close / trailing-stop variants ใหม่
- ❌ ML / AI overlay บน signal logic

## Open Questions (จะ distribute เข้า BA docs ตาม domain ใน Phase 4.2)

### ✅ Resolved (2026-05-01)

| # | Question | Resolution |
|---|----------|------------|
| **OQ-1** | Bug-for-bug compatibility vs. fix safety bugs? | **FIX** — BI orders ต้องมี SL (อิงจาก B parent); `ExtraTakeProfit_J` `MagicF` → `MagicJ`. Bug-fix drift จัดอยู่ใน **bucket B** ของ regression budget (ไม่นับใน 25% pattern-parity budget) — ดู `trading-baseline.md` § Validation Strategy |
| **OQ-2** | Server timezone ของ FBS server | **EET** — Winter GMT+2 (last Sunday Oct), Summer GMT+3 DST (last Sunday Mar). Rewrite ต้อง handle DST transition ใน time-filter logic |
| **OQ-4** | Strategy Tester tick model | **1-minute OHLC** (0% real ticks) — FBS Standard ไม่มี real-tick history สำหรับช่วงนี้ Baseline ใช้ model นี้ → rewrite regression test ต้องใช้ model เดียวกัน |
| **OQ-5** | Initial deposit | **$1,000** (used in baseline) |

### ⚠️ Still open — distribute เข้า BA docs

| # | Question | Domain | Default if unanswered |
|---|----------|--------|------------------------|
| **OQ-3** | Trade journal storage: CSV / JSON-lines / SQLite / MT5 GlobalVariable? schema fields? retention period? | FR | BA ระบุ functional need; SD/TD เลือก tech |
| **OQ-6** | Equity-floor switch (close-all เมื่อ DD แตะ X%)? user max DD = 50% acceptable แต่ไม่ enforce — เพิ่มเป็น Could Have ของ Phase 1 ดีไหม? | NFR / Safety | Defer to Phase 2 — แต่ flag ว่าเป็น risk gap ใน BA |
| **OQ-7** | Per-slot trade-count tolerance — drift กี่ % บอก "slot logic หาย"? | NFR (regression) | Default: ±15% ของ trade count, > 30% drift = ตรวจ slot logic |
| **OQ-8** | Slot U disabled — รื้อทิ้ง หรือ revive? CodeWiki §6.2 ระบุว่า dead code | FR (scope) | Per Q5.2: เก็บก่อน (preserve disabled state), ตัดทีหลังถ้าพิสูจน์ว่าไม่จำเป็น |

## Hypotheses to Validate (ผ่าน BA → SD → Impl → QA)

- **H1** — ≥ 80 magic numbers ที่ promote เป็น `input` ทำให้ behavioral parity (≤ 25% drift) ได้ ถ้า default value ตรงกับ current global 1:1
- **H2** — Slot interface + MarketContext snapshot + PortfolioState map (CodeWiki §7.2) ไม่เพิ่ม tick latency เกิน 10% เทียบ EA เดิม
- **H3** — Trade journal layer (write-on-event) ไม่กระทบ trading latency เกิน 5 ms/tick
- **H4** — เก็บทั้ง 17 slots ในรอบ Phase 1 ทำให้ rewrite ใช้เวลาไม่เกินงบที่ตั้งไว้ (กำหนดเวลา/effort ใน TD Phase)
- **H5** — Bug fix ของ BI no-SL + ExtraTakeProfit_J wrong magic เพิ่ม risk-adjusted return (Sharpe / Profit Factor) แทนที่จะลด

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Behavioral drift > 25% หลัง rewrite — slot logic ขัดต่อ baseline | Med | High | Build baseline contract ใน `trading-baseline.md` ก่อนเริ่ม code; QA Phase วัดทุก slot แยก |
| Slot scaffold หลายตัวยังคงไว้แต่ไม่ทำงาน → silent regression | Med | Med | Per-slot trade-count check ใน QA (OQ-7) |
| User เปลี่ยนใจกลางทาง อยากเพิ่ม feature ที่อยู่ใน Not-Doing | Low | High | Lock scope ใน BA `01-project-brief.md`; เปลี่ยนต้องผ่าน `/amend ba` หรือ `/backtrack` |
| FBS server timezone ผิด → time filter ทำงานเพี้ยน | Med | High | Resolve OQ-2 ใน BA Phase 2 ก่อน lock business rules |
| AI agent context-overflow เพราะ 22k LOC | High | Med | Split file early (per CodeWiki §7.2); ใช้ slot-by-slot incremental refactor |
| Baseline backtest data ไม่ available 2020-2025 (FBS broker symbol history) | Low | Med | Fallback: 1-minute OHLC model + document deviation reason |

## Approval Checkpoint

- [x] Direction ตกผลึก (D1–D7)
- [x] Not-Doing list ระบุ explicit
- [x] Open questions พร้อม distribute ไป BA (OQ-3, OQ-6, OQ-7, OQ-8 ยังเปิด — non-blocking)
- [x] Baseline numbers FILLED — `ReportTester-25045474.html` + `trading-baseline.md` (Net Profit $24.27M, PF 8.96, Sharpe 9.17)
- [x] Server timezone confirmed — FBS EET (GMT+2/+3 DST)
- [x] Safety bug decision — **FIX** (BI SL + ExtraTakeProfit_J magic)

→ **Next:** `/ba` (BA Requirements Discovery, Phase 1A) — workflow Phase 1.3 จะเข้า Meta-Prompting mode (input docs ครบแล้ว, มีแค่ 4 open questions ที่ distribute เข้า relevant docs)
