# 03 — Non-Functional Requirements: PhoenicisNex

> **Phase:** Phase 1A (BA Requirements Discovery) — Doc 3/5
> **Author:** BA agent (`/ba` workflow, v1.2)
> **Last updated:** 2026-05-01
> **Reads:** `01-project-brief.md` (goals), `02-functional-requirements.md` (FR cross-ref), `trading-baseline.md` (regression numbers)
> **Audience:** Architect (Phase 1B), Tech Lead (Phase 1D), QA (Phase 3T)

## TL;DR

เอกสารนี้ระบุ **NFR เชิง measurable** ของ rewrite — ทุก target เป็นตัวเลขเทียบกับ baseline ใน `trading-baseline.md` หรือ source ใน CodeWiki. NFR แบ่งเป็น **8 หมวด**: Behavioral Parity (regression contract), Performance, Reliability, Maintainability, Safety, Configurability, Compatibility, Usability. **ห้ามมี NFR ที่ใช้คำว่า "เร็ว"/"เสถียร"/"ใช้ง่าย" โดยไม่มีตัวเลข** — ทุก target ต้อง testable ผ่าน Strategy Tester regression, MT5 native log, หรือ trade journal inspection. **All NFR-domain open questions ✅ resolved 2026-05-01:** OQ-6 = monitor-only Phase 1 (BA default); OQ-7 = ±15% / >30% (BA default).

**Counts:** Must **26** / Should **4** / Could **0** (Won't อยู่ใน `01 § 6`)

---

## 1. NFR-1 — Behavioral Parity (Regression Contract)

หมวดนี้คือ **acceptance contract หลัก** ของ rewrite — ใช้ baseline ใน `trading-baseline.md` ที่มาจาก `ReportTester-25045474.html`. ทุก target อ้างตัวเลขจริง.

### NFR-1.1 — Total Net Profit deviation ≤ 25% (Bucket A)

| Field | Value |
|-------|-------|
| **Metric** | \|ΔTotal Net Profit\| / Baseline Net Profit |
| **Baseline** | $24,271,276.63 (5-yr 2021-2025, FBS-Real, $1k init, 1:500 leverage, 1-min OHLC tick model) |
| **Target** | ≤ **25%** (acceptable range: $18.20M – $30.34M) |
| **Bucket** | A — pattern parity drift (rewrite ที่ไม่ตั้งใจ) |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | Primary acceptance contract; > 25% deviation = strategy logic เสีย |
| **Verification** | QA Phase: รัน Strategy Tester period + tick model เดียวกัน → คำนวณ deviation จาก headline result table |
| **Source** | `trading-baseline.md § Validation Strategy`, ideation-brief D4 |

### NFR-1.2 — Profit Factor degradation ≤ 0.2 points

| Field | Value |
|-------|-------|
| **Metric** | Baseline PF − Rewrite PF |
| **Baseline PF** | 8.96 |
| **Target** | ≤ **0.2** (i.e. rewrite PF ≥ 8.76) |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | PF เป็น quality gate รอง — ถ้า Net Profit ผ่านแต่ PF drop = win/loss ratio เสียหาย |
| **Verification** | QA: คำนวณ PF จาก headline result |
| **Source** | `trading-baseline.md` |

### NFR-1.3 — Total Trades drift ≤ ±15%

| Field | Value |
|-------|-------|
| **Metric** | \|ΔTotal Trades\| / Baseline Total Trades |
| **Baseline** | 231 trades over 5 ปี |
| **Target** | ≤ **15%** (range: 196 – 266 trades) |
| **Investigation flag** | drift > **30%** trigger investigation |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | Trade count drift มากกว่า 30% = signal logic หาย (slot ไม่ fire เลย) หรือ entry condition relaxed เกิน |
| **Verification** | QA: นับ trade count จาก headline result + ตรวจ flag ถ้า drift > 30% |
| **Source** | `trading-baseline.md`, ideation-brief OQ-7 default |

### NFR-1.4 — Win Rate drift ≤ ±5 percentage points

| Field | Value |
|-------|-------|
| **Metric** | \|ΔWin Rate\| (absolute pp) |
| **Baseline** | 92.21% |
| **Target** | ≤ **5 pp** (range: 87.21% – 97.21%) |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | Secondary check — Net Profit ผ่านได้แม้ win rate drop ถ้า avg-win ขึ้น แต่ shift > 5pp = strategy character เปลี่ยน |
| **Verification** | QA: headline result Win Rate field |
| **Source** | `trading-baseline.md` |

### NFR-1.5 — Max Equity Drawdown % no worse than +10 pp

| Field | Value |
|-------|-------|
| **Metric** | Rewrite Max Equity DD% − Baseline Max Equity DD% |
| **Baseline Max Equity DD% (Maximal)** | 6.39% absolute |
| **Target** | ≤ **+10 pp** (rewrite Max Equity DD% Maximal ≤ 16.39%) |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3, G4 |
| **Why** | Risk envelope — ถ้า DD ลึกขึ้นมาก แม้ Net Profit ยัง ≤ 25% drift แสดงว่า risk profile เปลี่ยน → user ไม่ควรรับ |
| **Verification** | QA: headline Drawdown section |
| **Source** | `trading-baseline.md`, C-8 risk profile |

### NFR-1.6 — Per-slot trade count drift ≤ ±15% (✅ OQ-7 resolved)

| Field | Value |
|-------|-------|
| **Metric** | \|Δ(slot trade count)\| / Baseline (slot trade count) — สำหรับแต่ละ slot |
| **Baseline source** | Extract จาก `ReportTester-25045474.html` order list (regex on Comment field) — extraction จะทำใน QA Phase |
| **Target (✅ user resolved 2026-05-01)** | ≤ **±15%** acceptable; > **30%** drift = investigation flag (signal logic regression suspicion); absolute fallback **±2 trades** สำหรับ slot ที่ baseline < 5 trades (avoid percentage instability ที่ low base) |
| **Bucket** | A |
| **Priority** | Must |
| **Goal trace** | G3 |
| **Why** | Catch slot-level regression ที่ portfolio-level NFR-1.1 อาจกลบไว้ — slot ใดเทรดน้อยลงมาก แม้ portfolio Net Profit ยังผ่าน = signal logic ของ slot นั้นเสีย |
| **Verification** | QA Phase: parser extract per-slot stats → compare กับ baseline distribution |
| **Source** | `trading-baseline.md § Per-Slot Breakdown`, ideation-brief OQ-7 ✅ user resolved 2026-05-01 |
| **Architecture note (unblock SD)** | Architect/TD design regression check function (or QA harness) **parameterized over a per-slot baseline table** — table loaded at QA time จาก `ReportTester-25045474.html` extraction. Architect ไม่ blocked รอ baseline data; QA Phase 3T จะ populate table ก่อน rerun regression. Schema ของ table: `(slot_id, baseline_count, tolerance_mode ∈ {percentage, absolute}, threshold)` — TD lock final shape ใน Phase 1D |

> ✅ **OQ-7 resolved 2026-05-01:** ±15% / >30% — locked ตาม BA default; QA Phase 3T ใช้ rule นี้ + ปรับเป็น absolute fallback ถ้า slot ใดมี baseline trade < 5 ครั้งใน 5 ปี

### NFR-1.7 — Sharpe ratio degradation ≤ 1.0

| Field | Value |
|-------|-------|
| **Metric** | Baseline Sharpe − Rewrite Sharpe |
| **Baseline** | 9.17 |
| **Target** | ≤ **1.0** (rewrite Sharpe ≥ 8.17) |
| **Bucket** | A |
| **Priority** | Should |
| **Goal trace** | G3 |
| **Why** | Risk-adjusted return — secondary check; Sharpe ที่สูงเกิน 8 = top decile, drop 1 จุดยังอยู่ใน top decile |
| **Verification** | QA: headline Sharpe field |
| **Source** | `trading-baseline.md` |

### NFR-1.8 — Bug fix drift documented (Bucket B — OQ-1 resolved)

หมวดย่อยสำหรับ **intentional fix drift** จาก G4 (BI SL + ExtraTakeProfit_J magic). Bucket B แยกจาก 25% pattern parity ceiling.

| Field | Value |
|-------|-------|
| **Sources counted in Bucket B** | (1) BI SL fix (FR-3.3); (2) ExtraTakeProfit_J magic fix (FR-3.4) |
| **Acceptable** | Net Profit อาจขึ้น/ลง — **document ทุก case แยก**; PF ต้องไม่ลด, Max DD% ต้องไม่เพิ่ม |
| **Failure trigger** | ถ้า bug-fix ทำให้ Net Profit ลด > 25% = bug นั้น "ตัดได้กำไร" → ขอ user re-decide ก่อน proceed |
| **Priority** | Must |
| **Goal trace** | G4 |
| **Verification** | QA Phase: เปรียบเทียบ baseline vs (rewrite without fix) vs (rewrite with fix) — แยก 2 รอบ; document delta แต่ละ run |
| **Source** | `trading-baseline.md § Deviation Budget`, ideation-brief OQ-1 |

---

## 2. NFR-2 — Performance

EA run ทุก tick → CPU/latency เป็น hard constraint; backtest 5 ปีก็ต้อง finish ในเวลาที่ user ทนได้.

### NFR-2.1 — Tick latency overhead ≤ 10% vs original

| Field | Value |
|-------|-------|
| **Metric** | (Rewrite avg tick latency − Original avg tick latency) / Original avg tick latency |
| **Target** | ≤ **10%** average + ≤ **20%** at p95 + ≤ **30%** at p99 |
| **Priority** | Must |
| **Goal trace** | G1 (perf), G3 |
| **Why** | Slot abstraction + indicator snapshot + per-slot state lookup (FR-2.5/2.6/2.7) ใส่ indirection layer → เสี่ยง overhead; ขีดจำกัด 10% avg เพื่อให้ live tick ทันต่อ broker fill ใน volatile market (Hypothesis H2 ใน ideation-brief); p95/p99 ขีดจำกัดเพิ่มเพื่อกัน outlier hide ใน average |
| **Measurement protocol** | (a) **Instrumentation:** QA insert timestamp capture ที่ OnTick start + end ของทั้ง original EA และ rewrite (เพิ่ม-ลบ instrumentation = QA work; method = TD decide). (b) **Sample size:** ≥ 5,000 ticks ต่อ run ของ regression period (2021-2025 EURUSD H4, 1-min OHLC tick model). (c) **Aggregation:** report avg + p95 + p99 ของ tick latency distribution ทั้งคู่. (d) **Environment parity:** วัดทั้งคู่บนเครื่องเดียวกัน (user's Windows machine), MT5 build เดียวกัน, no other CPU-heavy process. (e) **Original instrumentation:** QA add temporary timestamp ลง EA เดิม (ลบหลังวัดเสร็จ — ไม่ commit) |
| **Verification** | QA Phase: ทำตาม Measurement protocol → คำนวณ deviation จาก aggregation → pass/fail ตาม Target; ถ้า fail ที่ p95/p99 แต่ผ่าน avg → flag for investigation (อาจ infrequent spike แต่ห้าม regress live trade) |
| **Source** | ideation-brief Hypothesis H2; CodeWiki §7.2 |

### NFR-2.2 — Trade journal write latency ≤ 5 ms/tick

| Field | Value |
|-------|-------|
| **Metric** | Time spent on journal write per tick (ms) |
| **Target** | ≤ **5 ms/tick** average + ≤ **10 ms/tick** at p95 |
| **Priority** | Must |
| **Goal trace** | G2, G3 |
| **Why** | Journal เป็น Must (FR-4.1) แต่ห้ามทำให้ tick ช้า; 5ms ใน FBS server = ภายใน 1 tick window ปกติ; Hypothesis H3 |
| **Measurement protocol** | (a) **Instrumentation:** QA insert timestamp รอบ journal write block (start/end). (b) **Sample size:** วัดเฉพาะ tick ที่มี journal write event (entry/exit/modify/halt) — sample ≥ 200 events จาก regression run. (c) **Aggregation:** avg + p95. (d) **Overshoot behavior:** ถ้า journal write > 5ms ติดต่อกัน N ครั้งใน window M ticks (N/M = TD decide) → emit tagged warning ผ่าน FR-4.2 logger + **continue trade flow** (degrade-but-continue — ห้าม block tick หรือ drop journal record; ถ้า disk slow แต่ trade ยังต้องทำงาน) |
| **Verification** | QA Phase: ทำตาม Measurement protocol → pass/fail ที่ avg + p95 thresholds |
| **Source** | ideation-brief Hypothesis H3 |

### NFR-2.3 — Strategy Tester 5-yr run time

| Field | Value |
|-------|-------|
| **Metric** | Run time ของ 5-yr regression run (2021-2025 EURUSD H4) บนเครื่อง user (Windows) |
| **Target** | Run time ของ rewrite ≤ **1.5×** original (ภายใต้ default tester settings + 1-min OHLC tick model) |
| **Priority** | Should |
| **Goal trace** | G1 |
| **Why** | Slow backtest = user run sweep ไม่ไหว; cap เป็น Should (ไม่ใช่ Must) เพราะ FR-8.1 (300-bar cache) จะช่วย — ถ้าผ่าน cache ครบ run time น่าจะ ≤ 1× original |
| **Verification** | QA Phase: เปรียบเทียบ Strategy Tester run time |
| **Source** | improvement-targets P2.1 |

---

## 3. NFR-3 — Reliability

EA run unattended; ไม่มี ops team — ทุก failure mode ต้อง self-recover หรือ fail-fast loud.

### NFR-3.1 — Atomic state file write

| Field | Value |
|-------|-------|
| **Metric** | State file integrity หลัง simulated mid-write crash |
| **Target** | **0%** corrupt files หลัง random kill 100 รอบระหว่าง state write |
| **Priority** | Must |
| **Goal trace** | G4 |
| **Why** | ปัจจุบัน flat write = corrupt risk (CodeWiki §6.2 P2.4) — user solo = ไม่มี monitoring → discover ตอน trade ผิด |
| **Verification** | QA: kill MT5 process random ระหว่าง write × 100 → reattach EA → verify state load สำเร็จ |
| **Source** | CodeWiki §6.2, FR-5.2 |

### NFR-3.2 — Indicator handle fail-fast

| Field | Value |
|-------|-------|
| **Metric** | EA boot กับ invalid handle |
| **Target** | EA reject load **100%** ของ INVALID_HANDLE case + log + ไม่เริ่ม OnTick |
| **Priority** | Must |
| **Goal trace** | G4 |
| **Why** | ปัจจุบัน OnInit ไม่ validate (CodeWiki §6.2 P1.8) → silent failure = trade ผิด live |
| **Verification** | QA: simulate invalid indicator (เช่น referenced custom indicator missing) → verify EA reject |
| **Source** | CodeWiki §6.2, FR-7.6 |

### NFR-3.3 — State restore equivalence

| Field | Value |
|-------|-------|
| **Metric** | State variables ใน RAM หลัง EA reload เทียบกับก่อน unload |
| **Target** | **100%** field equivalence — ทุก state variable ใน CodeWiki §1.3 + pending state machines (§2.5) |
| **Priority** | Must |
| **Goal trace** | G3, G4 |
| **Verification** | QA: snapshot state ก่อน unload → reload → diff state |
| **Source** | CodeWiki §5.4 LoadGlobal, FR-5.1 |

### NFR-3.4 — No silent failures

| Field | Value |
|-------|-------|
| **Metric** | จำนวน exception/error path ที่เงียบ (ไม่ log, ไม่ alert) |
| **Target** | **0** silent failure paths ใน OnInit + OnTick critical sections (order open/close, state persist, indicator handle) |
| **Priority** | Must |
| **Goal trace** | G2, G4 |
| **Why** | Solo operator ไม่มีทางรู้ปัญหาถ้าไม่มี log/alert |
| **Verification** | QA: code review checklist + manual log inspection |
| **Source** | CodeWiki §6.2 — silent ExpertRemove + Print() noise gap |

---

## 4. NFR-4 — Maintainability

G1 ของ project — ทุก target นี้คือ enabler ให้ user/AI agent ทำงานต่อกับ codebase หลังส่งมอบ.

### NFR-4.1 — File size ≤ 5,000 LOC each

| Field | Value |
|-------|-------|
| **Metric** | LOC ต่อไฟล์ (`.mq5` source) |
| **Target** | ≤ **5,000 LOC/file** ทุกไฟล์ |
| **Priority** | Must |
| **Goal trace** | G1 |
| **Why** | 22k LOC monolith ปัจจุบัน — debug + AI agent context ใช้ไม่ไหว (CodeWiki §7.2); 5,000 = file ที่ AI tool + human reviewer scroll/load ครั้งเดียว |
| **Verification** | QA: `wc -l` ทุกไฟล์ใน MQL5/Experts/PhoenicisNex/* |
| **Source** | CodeWiki §7.2, project-overview G1 |

### NFR-4.2 — Slot abstraction compliance: 1 file per slot

| Field | Value |
|-------|-------|
| **Metric** | Slot count ÷ slot file count |
| **Target** | **1:1** — แต่ละ slot อยู่ในไฟล์เดียว (เช่น `Slot_C.mqh`, `Slot_J.mqh`); orchestrator + slot abstraction shared module แยกออกอีก ≤ 3 ไฟล์ — concrete naming + structure = TD decide |
| **Priority** | Must |
| **Goal trace** | G1 |
| **Why** | FR-2.5 enabler — refactor 1 slot ไม่ touch slot อื่น |
| **Verification** | QA: file structure inspection + count slot files vs slot list ใน `01 § 5.1` |
| **Source** | CodeWiki §7.2 |

### NFR-4.3 — Input parameter count ≥ 80

| Field | Value |
|-------|-------|
| **Metric** | จำนวน `input`/`sinput` declarations ใน EA |
| **Target** | ≥ **80** (ครอบคลุมทุก row ใน CodeWiki §6.1) |
| **Priority** | Must |
| **Goal trace** | G1 |
| **Verification** | QA: grep `^(input\|sinput)\s` count + cross-ref กับ CodeWiki §6.1 row checklist |
| **Source** | CodeWiki §6.1, FR-1.1 |

### NFR-4.4 — Glossary present + referenced

| Field | Value |
|-------|-------|
| **Metric** | Glossary entries + cross-reference rate |
| **Target** | `01 § 8` มี ≥ **20 entries**; ทุก domain term ที่ใช้ใน 02-05 ปรากฏใน glossary หรือ defined first-use |
| **Priority** | Must |
| **Goal trace** | G1 (onboarding) |
| **Verification** | BA self-check + Architect review |
| **Source** | `ba-requirements-prompt.md § Readability Contract` |

---

## 5. NFR-5 — Safety

หมวดนี้คือ G4 + safety hygiene — ทุก target มาจาก improvement-targets P1.x หรือ CodeWiki §6.

### NFR-5.1 — EA halt with notification (no silent ExpertRemove)

| Field | Value |
|-------|-------|
| **Metric** | EA shutdown event ที่ไม่ alert user |
| **Target** | **0** silent shutdowns — ทุก halt path ต้องเรียก `Alert()` (MT5 native popup + sound) + ใส่ journal entry |
| **Priority** | Must |
| **Goal trace** | G2, G4 |
| **Why** | ปัจจุบัน CircuitBreaker เรียก `ExpertRemove()` เงียบ (CodeWiki §6.2 P2.3) — user ไม่รู้ EA หาย; under MVP signal — ใช้ MT5 native Alert (ไม่มี Telegram). Upgrade Should → Must เพราะ trigger paths (FR-6.6 CircuitBreaker, FR-7.6 indicator handle invalid) priority = Must — notification เป็นส่วนเดียวกันของ G4 safety contract |
| **Verification** | QA: trigger CircuitBreaker scenario → verify Alert popup + journal entry |
| **Source** | CodeWiki §6.2 P2.3, FR-7.7 |

### NFR-5.2 — Equity-floor monitor (no enforce in MVP — ✅ OQ-6 resolved)

| Field | Value |
|-------|-------|
| **Metric** | Worst drawdown %, current DD %, equity high-water mark |
| **Target** | ทุก field log + persist via GlobalVariable (FR-4.4 WatchProfits); **ไม่มี close-all enforcement** ใน Phase 1 |
| **Priority** | Must (monitor); Could-Have (enforcement — Phase 2) |
| **Goal trace** | G2 (observability), G4 (potential) |
| **Why** | OQ-6 default = defer enforcement Phase 2; user max DD = 50% acceptable แต่ "monitor without enforce" ก็เป็น risk gap; under MVP signal — เก็บ monitor only |
| **Verification** | QA: regression run → verify worst DD logged + GlobalVariable populated |
| **Source** | improvement-targets P3.2, ideation-brief OQ-6 ✅ user resolved 2026-05-01 (defer enforcement Phase 2) |

> ✅ **OQ-6 resolved 2026-05-01:** monitor-only Phase 1 — locked; equity-floor enforcement defer Phase 2

### NFR-5.3 — Symbol whitelist enforcement

| Field | Value |
|-------|-------|
| **Metric** | EA boot กับ chart symbol ผิด |
| **Target** | **100%** rejection rate ใน OnInit เมื่อ `_Symbol != "EURUSD"` |
| **Priority** | Must |
| **Goal trace** | G4 |
| **Verification** | QA: attach EA กับ GBPUSD/XAUUSD chart → verify reject + log |
| **Source** | FR-1.2, CodeWiki §6.3 |

> **Note — Security NFR category (out-of-scope, Phase 1):** หมวด Security NFR ถูก out-of-scope อย่างเป็นทางการ — ไม่ใช่ silent skip. เหตุผล: (a) **Local-only EA** — run ใน MT5 sandbox เครื่อง user, ไม่มี network listener, ไม่มี external API call, ไม่มี multi-user (attack surface = local OS access, handled by Windows user account); (b) **No PII transit** — trade journal เก็บ local-only (FR-4.3) ใน `MQL5/Files/`, ไม่มี personal data ออกจากเครื่อง; (c) **No external DLLs** — NFR-7.2 บังคับ 0 imports = ไม่มี supply-chain attack surface; (d) **Single-user** — C-9 solo operator, ไม่มี auth/authz requirement; (e) **No remote sync** — MVP signal 2026-05-01 ไม่มี cloud/telemetry. **Phase 2 re-evaluation trigger:** ถ้าเพิ่ม cloud journal, Telegram/email notification, multi-account, หรือ remote dashboard → Security NFR category ต้อง added พร้อม authentication, transport encryption, key management. Architect Phase 1B ไม่ต้องเพิ่ม NFR ใน Phase 1 design — entry trigger สำหรับ Phase 2 อยู่ที่นี่

---

## 6. NFR-6 — Configurability

หมวดนี้คือ G1 enabler ตรง — ถ้า user tune parameter ไม่สะดวก = rewrite เสียจุดประสงค์หลัก. กำหนด measurable target ของ MT5 native input dialog (≥ 80 inputs ทุนได้, reattach ≤ 30s), Strategy Tester optimization compatibility, และ slot-grouping ของ input UI.

### NFR-6.1 — All input parameters tunable without recompile

| Field | Value |
|-------|-------|
| **Metric** | Parameter ที่ user เปลี่ยน + reattach EA ได้ผล tonight |
| **Target** | **100%** ของ ≥ 80 inputs (NFR-4.3); reattach time ≤ **30 seconds** |
| **Priority** | Must |
| **Goal trace** | G1 |
| **Verification** | QA: change parameter ใน input dialog → reattach EA → verify behavior changed |
| **Source** | FR-1.1, project-overview G1 |

### NFR-6.2 — Strategy Tester optimization compatibility

| Field | Value |
|-------|-------|
| **Metric** | Input ที่ enumerate-able ใน optimization tab |
| **Target** | **100%** ของ numeric inputs (int/double/bool/enum); string inputs (เช่น symbol whitelist) ไม่ต้อง enumerate |
| **Priority** | Must |
| **Goal trace** | G1 |
| **Verification** | QA: เปิด Strategy Tester Inputs tab → verify Start/Step/Stop fields populated |
| **Source** | FR-1.3 |

### NFR-6.3 — Input grouping by slot

| Field | Value |
|-------|-------|
| **Metric** | Input ที่ group ตาม slot ผ่าน `group=` annotation หรือ comment header |
| **Target** | ทุก slot-specific input อยู่ใน group ของ slot นั้น (เช่น `group="Slot G"`); cross-slot (FIDValue, NormalTakeProfitPIP, LimitMaxLotSizeRatio) อยู่ใน `group="General"` |
| **Priority** | Should |
| **Goal trace** | G1 (UX of input dialog) |
| **Why** | 80+ inputs ไม่ group = user หาตัวที่จะ tune ไม่เจอ |
| **Verification** | QA: เปิด input dialog → verify visual grouping |
| **Source** | improvement-targets P1.1 ("UI grouping ตาม slot") |

---

## 7. NFR-7 — Compatibility

หมวดนี้ระบุขอบเขต **environment** ที่ rewrite ต้องทำงานได้ — MT5 build floor, ห้ามมี external DLL (เพื่อให้ "วาง .ex5 แล้วรัน" ตาม MVP signal), และ EET DST handling (constraint C-10) ที่กระทบ time-filter ทุกข้อ.

### NFR-7.1 — MT5 platform target

| Field | Value |
|-------|-------|
| **Metric** | MT5 build version ที่ EA load ได้ |
| **Target** | MT5 Build **3815 ขึ้นไป** (current FBS-Real Build = 5833 — ทดสอบขั้นต่ำที่ MetaQuotes รองรับ) |
| **Priority** | Must |
| **Goal trace** | C-1 |
| **Verification** | QA: load EA บน MT5 build อย่างน้อย 2 versions |
| **Source** | C-1, baseline FBS-Real Build 5833 |

### NFR-7.2 — MQL5 standard library only (no external DLLs in MVP)

| Field | Value |
|-------|-------|
| **Metric** | External DLL imports |
| **Target** | **0** external DLLs (`#import` directives เฉพาะ MQL5 standard library/system) |
| **Priority** | Must |
| **Goal trace** | C-9, MVP signal |
| **Why** | External DLL = installer requirement (registry, Windows Defender) — ขัด MVP signal "ไม่ต้องทำ Install"; standard MQL5 lib + native file API พอเขียน journal/state ได้ |
| **Verification** | QA: grep `#import` ใน source |
| **Source** | MVP signal 2026-05-01, C-9 |

### NFR-7.3 — EET DST handling

| Field | Value |
|-------|-------|
| **Metric** | Time-filter pass rate รอบ DST switch boundary |
| **Target** | **100%** correct trigger ใน 1-hour window รอบ last Sunday Mar/Oct |
| **Priority** | Must |
| **Goal trace** | C-10, G3 |
| **Verification** | QA: regression run period ครอบคลุม **10 DST transitions** (Mar 2021, Oct 2021, Mar 2022, Oct 2022, Mar 2023, Oct 2023, Mar 2024, Oct 2024, Mar 2025, Oct 2025) — verify per FR-6.5 **AC-6.5.2** (ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch) + **AC-6.5.3** (trade journal `timestamp` field สะท้อน DST shift ถูกต้อง) |
| **Source** | C-10, FR-6.5 (AC-6.5.2 / AC-6.5.3) |

---

## 8. NFR-8 — Usability (under MVP)

User เป็น solo operator ที่เห็น EA ผ่าน MT5 native input dialog เท่านั้น — ไม่มี wizard, ไม่มี config tool, ไม่มี documentation site. หมวดนี้ระบุ ergonomic constraint ของ dialog (label/tooltip width) + ห้ามมี external config file ที่ user ต้องแก้นอก MT5.

### NFR-8.1 — Input dialog readable on default MT5 layout

| Field | Value |
|-------|-------|
| **Metric** | Input dialog ที่ visible ใน MT5 default window size |
| **Target** | ทุก input label + comment ≤ **40 characters width**; ทุก input description (`tooltip`) ≤ **80 characters** |
| **Priority** | Should |
| **Goal trace** | G1 (configurability UX) |
| **Why** | Solo operator ใช้ default MT5 window; label ยาวเกิน = ตัด text → user งงตอน tune |
| **Verification** | BA review + UX self-check; QA: visual inspection input dialog |
| **Source** | C-9 solo |

### NFR-8.2 — No external config files for normal tuning

| Field | Value |
|-------|-------|
| **Metric** | จำนวน config files ที่ user ต้องแก้ (นอกเหนือ MT5 input dialog) สำหรับการ tune ปกติ |
| **Target** | **0** — ทุก parameter tune ผ่าน MT5 native input dialog เท่านั้น |
| **Priority** | Must |
| **Goal trace** | G1, MVP signal |
| **Why** | MVP signal — ไม่มี installer/setup wizard; user ต้องไม่แก้ `.txt` หรือ `.ini` ภายนอก |
| **Verification** | QA: documentation review + user simulation (set parameter → verify ผ่าน input dialog เท่านั้น) |
| **Source** | MVP signal, FR-1.1 |

---

## 9. NFR Summary Table

| ID | Category | Target (quantified) | Priority | Goal |
|----|----------|----------------------|----------|------|
| NFR-1.1 | Behavioral parity | \|ΔNet Profit\| ≤ 25% | Must | G3 |
| NFR-1.2 | Behavioral parity | ΔPF ≥ −0.2 | Must | G3 |
| NFR-1.3 | Behavioral parity | ΔTrades ≤ ±15% (>30% flag) | Must | G3 |
| NFR-1.4 | Behavioral parity | ΔWin Rate ≤ ±5pp | Must | G3 |
| NFR-1.5 | Behavioral parity | ΔMax Equity DD% ≤ +10pp | Must | G3, G4 |
| NFR-1.6 | Behavioral parity | Per-slot trades ±15% (✅ OQ-7) | Must | G3 |
| NFR-1.7 | Behavioral parity | ΔSharpe ≤ −1.0 | Should | G3 |
| NFR-1.8 | Bucket B drift | PF ไม่ลด, Max DD% ไม่เพิ่ม | Must | G4 |
| NFR-2.1 | Performance | Tick latency overhead ≤ 10% | Must | G1, G3 |
| NFR-2.2 | Performance | Journal write ≤ 5 ms/tick | Must | G2, G3 |
| NFR-2.3 | Performance | Strategy Tester runtime ≤ 1.5× original | Should | G1 |
| NFR-3.1 | Reliability | Atomic write 100% across kill-100 | Must | G4 |
| NFR-3.2 | Reliability | Indicator handle fail-fast 100% | Must | G4 |
| NFR-3.3 | Reliability | State restore 100% field equivalence | Must | G3, G4 |
| NFR-3.4 | Reliability | 0 silent failures in OnInit/OnTick | Must | G2, G4 |
| NFR-4.1 | Maintainability | ≤ 5,000 LOC/file | Must | G1 |
| NFR-4.2 | Maintainability | 1:1 slot:file mapping | Must | G1 |
| NFR-4.3 | Maintainability | ≥ 80 inputs | Must | G1 |
| NFR-4.4 | Maintainability | Glossary ≥ 20 entries | Must | G1 |
| NFR-5.1 | Safety | 0 silent shutdowns | Must | G2, G4 |
| NFR-5.2 | Safety | Equity-floor monitor only (✅ OQ-6) | Must (monitor) | G2, G4 |
| NFR-5.3 | Safety | Symbol whitelist 100% rejection | Must | G4 |
| NFR-6.1 | Configurability | 100% inputs tunable, reattach ≤ 30s | Must | G1 |
| NFR-6.2 | Configurability | 100% numeric inputs in optimization | Must | G1 |
| NFR-6.3 | Configurability | Slot-grouped inputs | Should | G1 |
| NFR-7.1 | Compatibility | MT5 Build ≥ 3815 | Must | C-1 |
| NFR-7.2 | Compatibility | 0 external DLLs | Must | C-9, MVP |
| NFR-7.3 | Compatibility | DST switch 100% correct | Must | C-10, G3 |
| NFR-8.1 | Usability | Label ≤ 40ch, tooltip ≤ 80ch | Should | G1 |
| NFR-8.2 | Usability | 0 external config for tuning | Must | G1, MVP |

**Counts:** Must **26** / Should **4** / Could **0**

---

## 10. Resolved Questions — NFR domain

User resolved both NFR-domain open questions ใน BA review 2026-05-01.

### ✅ OQ-6 — Equity-floor switch → **monitor-only Phase 1**

**User decision (2026-05-01):** **(a) Defer enforcement Phase 2** — accept BA default

**Phase 1 behavior:**
- เก็บ NFR-5.2 ตามเดิม (monitor-only ผ่าน `WatchProfits` — log worst DD + persist via GlobalVariable)
- **ไม่มี close-all enforcement** ใน Phase 1
- User รับผิดชอบเอง — ถ้า live ขาดทุนเกิน 50% ต้อง manual halt (detach EA จาก chart)

**Risk acknowledgment:** "monitor without enforce" เป็น known risk gap (improvement-targets P3.2) — Phase 2 จะ promote เป็น FR หลังจาก user มี data จาก trade journal มากพอ

**Resolution path forward:** Phase 2 (after baseline proven + journal data accumulated) — user evaluate ว่าจะ enforce ที่ threshold ไหน

---

### ✅ OQ-7 — Per-slot trade-count tolerance → **±15% / >30% drift**

**User decision (2026-05-01):** **(a) ±15% acceptable / >30% drift = investigate** — accept BA default

**QA validation rule (locked):**
- Drift ของแต่ละ slot ≤ **±15%** ของ baseline trade count = pass
- Drift > **30%** = trigger investigation flag (signal logic regression suspicion)
- Average: 231 baseline trades / 21 active slots (Slot U deleted) ≈ 11 trades/slot avg → ±15% × 11 ≈ ±1.7 trades/slot tolerance

**Edge case to revisit ใน QA Phase:** ถ้า baseline per-slot stats extracted แล้วพบ slot ที่ trade น้อยกว่า 5 ครั้งใน 5 ปี = tolerance ต้อง absolute **±2 trades** (locked, ตรงกับ NFR-1.6 line 98) ไม่ใช่ percentage — QA agent ใช้ ±2 ตรงๆ ตอน per-slot extraction; ห้ามตีความเป็น "approximately" หรือ "example"

**Resolution path forward:** QA Phase 3T ใช้ rule นี้เป็น regression check; ปรับ absolute fallback ตอน extract per-slot baseline ออกมาดู

---

> **End of 03 — Non-Functional Requirements** — 30 NFRs (Must 26 / Should 4 / Could 0), all NFR-domain open questions ✅ resolved 2026-05-01
