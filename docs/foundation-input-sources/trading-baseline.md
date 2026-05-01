# Trading Baseline — Regression Contract

> ผล Strategy Tester ของ `PhoenicisN2.10_stable.mq5` ที่ใช้เป็น **regression contract** สำหรับ rewrite
> Rewrite ของ PhoenicisNex ต้อง deviate ไม่เกิน **25% ของ Total Net Profit** (ดู `project-overview.md` Goal G3, Q5.1)
> **🟢 STATUS: FILLED — baseline run completed 2026-05-01**
> **Source artifact:** `ReportTester-25045474.html` (อยู่ใน folder เดียวกัน)

## TL;DR

User รัน Strategy Tester บน FBS-Real (live server data) ด้วย $1,000 initial / 1:500 leverage / 5 ปี (2021-2025) → ผล **Net Profit $24.27M (≈ 24,000× initial), Profit Factor 8.96, Sharpe 9.17, Win Rate 92.21%**. ตัวเลขนี้เป็น **regression contract** — rewrite ต้อง deviate ≤ 25% บน **Total Net Profit** + ห้าม Profit Factor ลดลง > 0.2 จุด

## Test Setup (actual — จาก `ReportTester-25045474.html`)

| Field | Value | Note |
|-------|-------|------|
| Account / Server | **FBS-Real (Build 5833)** | live broker data — ไม่ใช่ demo |
| Company | FBS Markets Inc. | per stakeholder constraint C-5 |
| Expert | `PhoenicisN2.10_stable` | unmodified source |
| Symbol | EURUSD | per project constraint C-3 |
| Chart Timeframe (Tester period) | **M2** | tester period — EA ใช้ H4 indicators ภายในผ่าน handle |
| Backtest Period | **2021.01.03 → 2025.12.30** (≈ 5 ปี) | ครอบคลุม USD strength + Fed hike (2022-23) + post-Fed-pivot (2024-25); **ไม่รวม COVID 2020** |
| Initial Deposit | **$1,000.00** | OQ-5 → resolved |
| Currency | USD | |
| Leverage | **1:500** | per stakeholder constraint C-7 |
| **History Quality** | **0% real ticks** | OQ-4 → resolved as **"1-minute OHLC" fallback model** — FBS Standard ไม่มี real-tick history สำหรับช่วงนี้ |
| Bars | 927,621 | M2 candles |
| Ticks (interpolated) | 96,822,138 | |

## Headline Results

### Profit & Loss

| Metric | Value | Note |
|--------|-------|------|
| **Total Net Profit (USD)** | **24,271,276.63** | ROI ≈ 24,000× ($1k → $24.27M); compound ≈ 17%/month avg = consistent with 10–30% MoM target |
| Gross Profit | 27,322,148.64 | |
| Gross Loss | −3,050,872.01 | |
| **Profit Factor** | **8.96** | Gross Profit / \|Gross Loss\| — สูงมาก (top decile) |
| **Recovery Factor** | **15.41** | Net Profit / Max DD |
| Expected Payoff | 105,070.46 | per-trade avg |
| AHPR | 1.0488 (4.88%) | Arithmetic Holding Period Return per trade |
| GHPR | 1.0447 (4.47%) | Geometric HPR |
| Margin Level (final) | 1066.70% | |
| Z-Score | −2.18 (97.07%) | random walk significance — ลำดับ trade ไม่ random ที่ 97% confidence |
| LR Correlation | 0.96 | linear regression of equity curve fit ดีมาก |
| LR Standard Error | 2,578,101.36 | |

### Drawdown

| Metric | Value | Note |
|--------|-------|------|
| Balance Drawdown Absolute | 0.00 | balance ไม่เคยลงต่ำกว่า initial $1,000 |
| Balance Drawdown Maximal | $992,157.00 (4.11%) | absolute peak-to-trough |
| Balance Drawdown Relative | 4.93% ($389,958.00) | |
| Equity Drawdown Absolute | 12.85 | |
| Equity Drawdown Maximal | $1,574,582.26 (6.39%) | |
| **Equity Drawdown Relative** | **32.93% ($146,676.88)** | ⚠️ **flag**: relative DD สูง — เกิดช่วงต้น account size ยังเล็ก แต่ % ตรงนั้นถึง 1/3 ของ equity ขณะนั้น = consistent กับ "High Risk" profile (C-8) |

> **ข้อสังเกต**: ช่องว่างระหว่าง Balance DD Maximal (4.11%) กับ Equity DD Relative (32.93%) บอกว่า EA มี **floating drawdown** ลึกบางครั้ง (open exposure ลึก) ก่อนกลับมาขายทำกำไร — เป็น characteristic ของ pyramid/recovery slots (G/GO, B/BR/BI, J)

### Trades

| Metric | Value | Note |
|--------|-------|------|
| **Total Trades** | **231** | ≈ 46 trades/year — selective |
| Total Deals | 462 | entries + exits |
| **Profit Trades** | 213 (92.21%) | |
| Loss Trades | 18 (7.79%) | |
| Short Trades (won %) | 123 (92.68%) | symmetric |
| Long Trades (won %) | 108 (91.67%) | |
| Largest profit trade | $1,580,059.34 | |
| Largest loss trade | −$657,657.00 | |
| Avg profit trade | $128,273.00 | |
| Avg loss trade | −$169,492.89 | **avg loss > avg win** — positive expectancy มาจาก high win rate, ไม่ใช่ high R:R |
| Max consecutive wins | **43** ($9,698,686.30) | — |
| **Max consecutive losses** | **2** (−$992,157.00) | ทนทานต่อ losing streak |
| Avg consecutive wins | 14 | |
| Avg consecutive losses | 1 | |

### Position Holding Time

| Metric | Value |
|--------|-------|
| Min holding | 0:00:26 |
| Max holding | 483:30:00 (≈ 20 days) |
| **Avg holding** | **82:10:46** (≈ 3.4 days) |

### MFE / MAE Correlations

| Metric | Value | Note |
|--------|-------|------|
| Correlation (Profits, MFE) | 0.88 | ปิดที่ใกล้ peak → exit logic แน่น |
| Correlation (Profits, MAE) | −0.00 | trade ที่มี drawdown ลึก = ไม่จำเป็นต้องแพ้ |
| Correlation (MFE, MAE) | −0.3476 | trade ที่ไป favorable มาก = drawdown ตื้น |

## Per-Slot Breakdown — DEFERRED to QA Phase

Comment field ใน trade list มี slot identifier (T, D, K, M, C, H, B, BR, P, J, G, S, PX ฯลฯ) — extract ผ่าน regex จาก `ReportTester-25045474.html` ได้

**Why defer:** BA/SD/TD ไม่ต้องการ per-slot stats; QA จะใช้สำหรับ regression test (per-slot trade count tolerance — OQ-7) ก็พอ

**Action สำหรับ QA Phase:** สร้าง parser สำหรับ extract `(slot, count, net_pnl, win_rate)` จาก HTML order list หรือ CSV export

## Validation Strategy (เมื่อ rewrite เสร็จ — ใช้โดย QA Phase)

ใช้ baseline นี้เป็น regression test:

| Check | Threshold | Why |
|-------|-----------|-----|
| **\|ΔTotal Net Profit\|** | **≤ 25% ของ $24,271,276.63** ≈ ±$6.07M (range $18.20M – $30.34M) | Goal G3 — primary acceptance |
| ΔProfit Factor | ลดลง ≤ 0.2 จุด (≥ 8.76) | Quality gate |
| ΔTotal Trades | ±15% ของ 231 ≈ 196 – 266 | drift > 30% = signal logic หาย (OQ-7 default) |
| ΔWin Rate | ±5 pp ของ 92.21% ≈ 87.21% – 97.21% | secondary check |
| ΔMax Equity Drawdown Maximal % | ไม่แย่ลงเกิน 10 pp ของ 6.39% (= ≤ 16.39%) | risk envelope |
| Per-slot trade count | ±15% ของ baseline แต่ละ slot | catch slot-level regression (extract ใน QA) |
| ΔSharpe | ลดลง ≤ 1.0 จุด (≥ 8.17) | secondary |

### Deviation Budget — 2 Buckets (per OQ-1 decision = "Fix safety bugs")

User ตัดสินใจ **fix safety bugs** (BI no-SL → เพิ่ม SL; ExtraTakeProfit_J `MagicF` → `MagicJ`). Bug fixes คาดว่าจะทำให้ผลดีขึ้น ไม่แย่ลง:

| Bucket | Sources | Acceptable? | Notes |
|--------|---------|-------------|-------|
| **A. Pattern parity drift** | code rewrite ที่ไม่ตั้งใจ — slot logic, lot calc, indicator wiring | ≤ 25% (within deviation budget) | ตัวหลักของ acceptance |
| **B. Intentional bug-fix drift** | BI SL fix + ExtraTakeProfit_J magic fix | OK ถ้า: PF ไม่ลด, Max DD% ไม่เพิ่ม, Net Profit อาจขึ้น/ลง — **document ทุก case** | ถ้า bug fix ทำให้ Net Profit ลด > 25% = signal ว่า bug "ตัดได้กำไร" → ขอ user re-decide |

## Open Questions (cross-ref `ideation-brief.md`)

ที่ยังเปิดอยู่หลัง baseline:

- ⚠️ **OQ-3** — Trade journal schema (CSV / SQLite / JSON-lines / GlobalVariable) → BA Phase
- ⚠️ **OQ-6** — Equity-floor switch (Could Have ของ Phase 1?) → BA Phase
- ⚠️ **OQ-7** — Per-slot trade-count tolerance (default ±15%, > 30% drift = investigate) — confirm ใน QA
- ⚠️ **OQ-8** — Slot U disposition (preserve disabled / revive / delete) → BA Phase, default = preserve disabled

ปิดแล้ว:
- ✅ **OQ-1** — fix safety bugs (decided 2026-05-01) — bucket B deviation
- ✅ **OQ-2** — FBS server tz = EET (GMT+2 winter / GMT+3 summer DST)
- ✅ **OQ-4** — tick model = "1-minute OHLC" (0% real ticks; FBS Standard limit)
- ✅ **OQ-5** — initial deposit = $1,000

## Reference Artifacts

ในโฟลเดอร์ `docs/foundation-input-sources/`:
- `ReportTester-25045474.html` — full Strategy Tester report (settings + headline + per-trade order list)
- (optional) `ReportTester-25045474.png` — balance equity curve graph (referenced ใน HTML)
- (optional) `ReportTester-25045474-hst.png` — bars graph
- (optional) `ReportTester-25045474-mfemae.png` — MFE/MAE chart
- (optional) `ReportTester-25045474-holding.png` — position holding time chart
