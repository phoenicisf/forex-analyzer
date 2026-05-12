# 04 — Business Rules: PhoenicisNex

> **Phase:** Phase 1A (BA Requirements Discovery) — Doc 4/5
> **Author:** BA agent (`/ba` workflow, v1.2)
> **Last updated:** 2026-05-12 (BT-001 cascade — Bucket A/B propagation: rule type tag legend `§ 1` + BR-7 intro `§ 8` + BR-7.1/7.2 validation hints + BR-9.5 invariant)
> **Reads:** `01-project-brief.md` (glossary), `02-functional-requirements.md` (FR-X.Y refs), `trading-baseline.md`
> **Audience:** Architect (Phase 1B), Tech Lead (Phase 1D) — แปลงเป็น decision logic + state machine + invariants

## TL;DR

เอกสารนี้รวบ **business rules + decision tables + state machine transitions** ของ EA — ทุกข้อมาจาก CodeWiki §3-§5 (As-Is logic ของ EA เดิม) **บวก** 2 intentional bug-fix rules ของ G4 (BI SL inheritance, ExtraTakeProfit_J magic). ทุก rule ต้อง preserve 1:1 ใน rewrite (ตามสัญญา behavioral parity G3) ยกเว้น 2 rules ที่ user decision 2026-05-01 = **FIX**. หมวดสำคัญที่สุดคือ **slot magic pool conflict** (G/G2 share `MagicG`, B/BI share `MagicB`) — rewrite ต้อง preserve magic conflict 1:1 ในรอบ Phase 1 (จะ resolve ใน Phase 2 เมื่อมี behavioral baseline แล้ว) แต่ใส่ slot-id field ใน comment เพื่อ disambiguate ใน trade journal. **OQ-3.3 ✅ resolved 2026-05-01:** BI SL inheritance semantic = **same SL distance** (BA default — locked ใน BR-7.1). **OQ-8 ✅ resolved 2026-05-01:** Slot U **DELETED** — magic 220 unused, BR-1.1 row strikethrough.

---

## 1. How to read this document

ทุก rule มี structure เดียวกัน:

```
**BR-X.Y — Rule name**
- **Condition:** [trigger ที่ทำให้ rule active]
- **Action:** [ผลลัพธ์เมื่อ condition true]
- **Why:** [Thai rationale — preserve 1:1, fix bug, หรือ derive จาก constraint]
- **Source:** CodeWiki §N | improvement-targets PN.N | user decision date
- **Related FR:** FR-X.Y links ใน 02
- **Validation hint:** วิธี test rule นี้ใน QA Phase
```

**Rule type tag:**
- 🔒 **Preserve 1:1** — ห้ามเปลี่ยน, replicate exact ของ EA เดิม
- ⚠️ **Bug-fix** — intentional change per G4 (drift รวมอยู่ใน NFR-1.1 Bucket A measurement บน rewrite-G4-ON default build; NFR-1.8 Bucket B = informational delta only, post-BT-001 re-baseline 2026-05-12)
- 🔧 **Refactor-safe** — semantic เหมือนเดิมแต่ implementation อาจเปลี่ยน (ผ่าน slot abstraction; concrete API = TD decide)

---

## 2. BR-1 — Slot Magic Pool

หมวดนี้ระบุ magic number ของแต่ละ slot — ตัวเลขเหล่านี้คือ MT5 order tag ที่ใช้แยก position ของแต่ละ strategy. EA ปัจจุบันมี **shared magic** ระหว่าง slot บางคู่ (G/G2, B/BI) ซึ่ง CodeWiki §6.2 ระบุเป็น fragile pattern. เราต้อง **preserve magic conflict 1:1 ใน Phase 1** (เพื่อ behavioral parity) แต่เพิ่ม disambiguation ผ่าน comment field.

### BR-1.1 — Magic Number Pool Table 🔒

**Condition:** EA ส่ง order ใดๆ ไปยัง broker
**Action:** order ต้องใส่ magic ตามตารางด้านล่างเท่านั้น

| Slot | Magic | Defined | Notes |
|------|-------|---------|-------|
| C, D | **200** (`MagicCD`) | CodeWiki `:15003` | Shared pool (D = wrapper ของ C); disambiguation ผ่าน comment field |
| F | **201** (`MagicF`) | `:15004` | — |
| H | **205** (`MagicH`) | `:15005` | — |
| J | **206** (`MagicJ`) | `:15006` | (G4 fix: `ExtraTakeProfit_J` iterate magic นี้) |
| K | **207** (`MagicK`) | `:15007` | — |
| G, G2 | **208** (`MagicG`) | `:15008` | **⚠️ Shared** — disambiguate ผ่าน comment ("G..." vs "G2..."); preserve 1:1 Phase 1 |
| GO | **209** (`MagicGO`) | `:15010` | — |
| M | **210** (`MagicM`) | `:15011` | — |
| L, LX | **211** (`MagicL`) | `:15009` | LX = pyramid ของ L; preserve shared magic 1:1 |
| Q | **212** (`MagicQ`) | `:15012` | — |
| R | **213** (`MagicR`) | `:15013` | — |
| B, BI | **214** (`MagicB`) | `:15014` | **⚠️ Shared** — disambiguate ผ่าน comment ("B..." vs "BI..."); preserve 1:1 Phase 1 |
| BR | **215** (`MagicBR`) | `:15015` | Orphan — เรียกจาก `ExtraTakeProfit_B` exit only |
| I | **216** (`MagicI`) | `:15016` | — |
| S | **217** (`MagicS`) | `:15017` | — |
| P | **218** (`MagicP`) | `:15018` | — |
| T | **219** (`MagicT`) | `:15019` | — |
| ~~U~~ | ~~220~~ | ~~`:15020`~~ | ✅ **DELETED** from rewrite (OQ-8 user decision 2026-05-01) — magic 220 unused, available for Phase 2 |

- **Why:** MT5 ใช้ magic แยก order; preserve pool exact = preserve baseline behavior 100%; shared magic ของ G/G2 + B/BI = known fragile pattern (CodeWiki §6.2 P1.6) ที่จะ resolve ใน Phase 2
- **Source:** CodeWiki §1.5 Magic Number Pool
- **Related FR:** FR-2.1, FR-2.4
- **Validation hint:** QA grep order list `Magic` field — ทุก order ต้องอยู่ใน range [200, 220]; cross-check จำนวน distinct magic = 16 (ไม่ใช่ 20 เพราะ shared)

### BR-1.2 — Magic-via-comment disambiguation 🔧

**Condition:** Slot ที่ share magic (G/G2, B/BI, L/LX, C/D) ส่ง order
**Action:** comment field ต้องเริ่มด้วย slot ID ตามด้วย delimiter (เช่น `"G2,..."`, `"BI,..."`, `"LX,..."`, `"D,..."`)
**Why:** Trade journal (FR-4.1) + per-slot regression check (NFR-1.6) ต้องแยก slot ที่ share magic ได้; ใช้ comment เป็น disambiguator ตาม pattern EA เดิม (CodeWiki §3 GetOrderTrendType parses comment)
- **Source:** CodeWiki §3 (per-slot comment patterns), §6.2 P1.6
- **Related FR:** FR-2.1, FR-4.1, NFR-1.6
- **Validation hint:** QA grep order Comment field — ทุก order ของ shared-magic slot มี slot prefix

---

## 3. BR-2 — Slot Dependency Graph

หมวดนี้ระบุ **explicit dependency edges** ระหว่าง slot — Slot orchestrator (FR-2.3, FR-2.4) ต้องรู้ว่า slot ไหนเรียก/อาศัย slot อื่น เพื่อ topo-sort การประเมิน + เพื่อให้ refactor 1 slot ไม่กระทบเงียบๆ.

### BR-2.1 — Dependency Edge Table 🔧

**Condition:** Slot orchestrator topo-sort slot list
**Action:** ใช้ตารางนี้เป็น static dependency graph

| Source | Depends On | Type | Why |
|--------|-----------|------|-----|
| **D** | C (force-pending workflow) | wraps | D เป็น 4-line wrapper ของ C; comment differentiator |
| **F** | C/D pool (BusinessLogic_F chained จาก OpenOrderCD) | chain | F เปิดต่อจาก CD เมื่อ `isFOff==false` |
| **J** | C/D (max 2 follower trades; pip gap +/-) | follow | J = follower trade หลัง CD (CodeWiki §3 Slot J) |
| **GO** | G (`ExtraTakeProfit_G` triggers `GOverload`) | exit-trigger | GO เปิดทิศตรงข้ามตอน G close (peak reversion) |
| **G2** | G (shares magic, alternative trigger pattern) | shared-magic | G2 = lighter version ของ G ใน wave context |
| **I** | G (Fibonacci add-on; closes when G closes) | parasite | I = G-parasite Fibonacci-ratio order |
| **LX** | L (pyramid on profitable L + DEM gate) | pyramid | LX = L's pyramid layer |
| **S** | L/K (post-close wave-peak reversal) | post-close | S เกิดหลัง L หรือ K close |
| **BR** | B (only invoked from `ExtraTakeProfit_B`) | exit-trigger | BR = reverse hedge ของ B; orphan ใน OnTick (CodeWiki §6.2 P2.2) |
| **BI** | B (pyramid child; shares magic; SL inherited per G4) | pyramid + bug-fix | BI = B's pyramid; **G4 fix:** SL ต้องอิง B parent |
| **All slots** | MarketContext + PortfolioState | data dep | ทุก slot อ่าน indicator จาก MarketContext + state จาก PortfolioState |

- **Why:** CodeWiki §7.2 → "Decouple G→GO, B→BR/BI, J→C/D, S→L/K — model these as explicit `Slot::dependsOn(otherSlot)` edges"; ปัจจุบัน dependency กระจายใน free function calls
- **Source:** CodeWiki §3 (per-slot logic), §7.2
- **Related FR:** FR-2.4, FR-2.5
- **Validation hint:** QA inspect slot abstraction (FR-2.5) — ทุก slot expose `dependsOn()` ที่คืน list ตามตารางนี้ (concrete name/return shape = TD decide)

### BR-2.2 — Topo-sort invariant 🔒

**Condition:** Slot orchestrator entry pass run
**Action:** Order ของ entry pass ต้อง preserve EA เดิม (CodeWiki §2.2):

```
C → D → J → H → K → G → G2 → I → M → L → LX → Q → R → B → BI
จากนั้น → S → T → P → P_Pending → P_Extra
(U deleted from rewrite per OQ-8 — ไม่มีใน topo-sort)
```

**Slots ไม่อยู่ใน main topo-sort** — F, GO, BR ทำงานเป็น sub-call ของ slot อื่นแทน standalone step:

| Slot | Caller | Trigger location | Reason ไม่ standalone |
|------|--------|------------------|----------------------|
| **F** | `OpenOrderCD` (chain) | ภายใน C/D's evaluate path เมื่อ `isFOff==false` | F = sub-strategy ของ CD pool — chain semantic ตาม BR-2.1 |
| **GO** | `ExtraTakeProfit_G` (post-exit hook) | ตอน G order close → เปิด GO ทิศตรงข้าม (peak reversion) | GO = exit-trigger only — ไม่มี standalone signal |
| **BR** | `ExtraTakeProfit_B` (orphan, exit-only) | ตอน B exit เงื่อนไขพิเศษ → BR reverse hedge | BR = orphan slot ตาม CodeWiki §6.2 P2.2 |

- **Why:** Entry order มีผลต่อ `PortfolioState` ที่ slot ภายหลังอ่าน — เปลี่ยน order = different state visible = behavioral drift; F/GO/BR ที่ chained/triggered ต้องเก็บ semantic เดิม (ห้าม promote เป็น standalone step ใน Phase 1 = behavioral drift)
- **Source:** CodeWiki §2.2 OnTick block, §3 (per-slot caller mapping), §6.2 P2.2
- **Related FR:** FR-2.3, FR-2.4
- **Validation hint:** QA log slot evaluation order ใน 1 tick → 18 standalone slots ตรงกับ list หลัก; F/GO/BR ปรากฏใน log โดย `triggering_function` = `OpenOrderCD` / `ExtraTakeProfit_G` / `ExtraTakeProfit_B`

---

## 4. BR-3 — Trade Filter & Time Gate Rules

หมวดนี้คือ **time-based AND condition-based block** ที่ EA ใช้ป้องกัน trade ใน window ที่ liquidity ต่ำ/spread สูง.

### BR-3.1 — IsMorningWakeup gate 🔒

**Condition:** `TimeCurrent()` (broker server time) ∈ [00:00, 00:05) ของวันใดๆ
**Action:** OnTick `return early` หลัง exit pass — ไม่มี slot เปิด new entry; exit pass ทำงานปกติ
- **Why:** หลีกเลี่ยง spread spike ตอน rollover; EA เดิม return ที่ `:270`
- **Source:** CodeWiki §4.3, §2.2
- **Related FR:** FR-6.1
- **Validation hint:** QA filter trade list — ไม่มี trade open เวลา 00:00–00:05 server time

### BR-3.2 — Monday spread guard 🔒

**Condition:** `IsMondayMorningWakeup()` true (Monday + first trading hours) AND `SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > 10 × DigitMultipier`
**Action:** OnTick return early ที่ `:261` — block new entry
- **Why:** Weekend gap → spread spike Monday open → unfair fill
- **Source:** CodeWiki §4.3
- **Related FR:** FR-6.2
- **Validation hint:** QA check Monday morning trade timestamps + spread snapshot

### BR-3.3 — New Year holiday block 🔒

**Condition:** `IsNewYearSeason2()` true (broker server date ∈ [Dec 21, Jan 3]) AND `portfolio[MagicCD].count == 0`
**Action:** OnTick return early ที่ `:297` — block new entry; existing positions managed normally
- **Why:** Low-liquidity holiday volatility; CD active = ไม่ block (ปล่อย CD exit logic ทำงาน)
- **Source:** CodeWiki §4.3
- **Related FR:** FR-6.3
- **Validation hint:** QA check trade list ใน Dec 21 – Jan 3 ของแต่ละปี baseline

### BR-3.4 — Per-Slot Ban Cooldown Table 🔒

**Condition:** Per-slot ban date set จาก trigger event
**Action:** Slot ไม่ fire entry signal จนกว่า cooldown ผ่าน

| Ban Date Variable | Cooldown | Slot |
|-------------------|----------|------|
| `BanCStartDate` | **24 H1 bars** (~1 day) | C |
| `BanLStartDate` | **48 H1 bars** (~2 days) | L |
| `BanMStartDate` | **36 H1 bars** (~1.5 days) | M |
| `KLastOrderDate` | **same D1 bar** (24h since open) | K |
| `GPauseDate` | **31 H1 bars** | G |

- **Why:** Post-loss cooldown ป้องกัน slot fire ติดต่อกันใน losing streak
- **Source:** CodeWiki §4.3, §1.3 state vars
- **Related FR:** FR-6.4
- **Validation hint:** QA verify slot ไม่ fire ในช่วง cooldown หลัง trigger event

### BR-3.5 — Force-Pending timeout 🔒

**Condition:** `IsForcePendingActionBuyOrder` หรือ `IsForcePendingActionSellOrder` set + 9 H4 bars passed without trigger
**Action:** Clear flag ที่ OnTick `:249`
- **Source:** CodeWiki §2.5 Force-Pending state, §2.2
- **Related FR:** FR-6.7

### BR-3.6 — CircuitBreaker ping-pong 🔒

**Condition:** Same position re-opens within **3000 ms** ของ previous close
**Action:** EA halt + Alert (FR-7.7) + journal entry
- **Why:** Detect infinite loop / runaway flip-flop ที่กิน balance
- **Source:** CodeWiki §5.5 CircuitBreakerOrder `:15796`
- **Related FR:** FR-6.6, FR-7.7
- **Validation hint:** QA simulate ping-pong scenario → verify halt + alert

### BR-3.7 — Spread guard at OnTick start 🔒

**Condition:** `SYMBOL_SPREAD > 10 × DigitMultipier` AND `IsMondayMorningWakeup()` (rule-3.2 reuses)
**Action:** Return early — no entry pass
- **Source:** CodeWiki `:261`
- **Related FR:** FR-6.2

---

## 5. BR-4 — Position Sizing & Lot Cap Rules

EA เดิมมี formula ของ lot ต่อ slot กระจายใน CodeWiki §4.1 — บาง slot ใช้ % คงที่, บาง slot multiply ด้วย helper trim, บาง slot pyramid lot ของ parent. หมวดนี้ lock formula ทุก row 1:1 + เพิ่ม cap (LimitMaxLotSizeRatio) + floor (SYMBOL_VOLUME_MIN) เพื่อกัน broker reject.

### BR-4.1 — Per-slot Lot Multiplier Table 🔒

**Condition:** Slot คำนวณ lot
**Action:** Apply formula + helper trim ตามตารางใน CodeWiki §4.1 (preserve 1:1)

| Slot | CalculateLotSize % | Helper Trim | Effective % |
|------|--------------------|-------------|-------------|
| C | 15% | (none) | 15% × 1..2.5 (peak multiplier) |
| H | 15% × 0.1..2.55 | (OpenOrderH none) | 1.5..38% |
| J | based on `LastBuyLots2 × 0.23` | OpenOrderJ × 1..3.95 | varies |
| K | base | OpenOrderK | base |
| G | 30% | OpenOrderG ×0.6 | 18% |
| G2 | 15% | ×0.7 | 10.5% |
| GO | closeLotsize ×1.0 | OpenOrderGO ×0.9 | 0.9× closing G size |
| L | ~20% | (LX) ×0.7 | 14% |
| LX | ≤12% | ×0.7 | ≤8.4% |
| M | computed | OpenOrderM ×0.8 | varies |
| Q | pyramided | OpenOrderQ ×0.8 | 80% of pyramid |
| R | 20% | OpenOrder ×0.7 (R flag) | 14% |
| B | 20+tpplus% | OpenOrder ×0.9 (B flag) | ~18% + tpplus |
| BR | 5..30% | OpenOrder ×0.8 (BR flag) | varies |
| BI | **23.6%** ของ parent B | (direct OpenOrder) | 23.6% of B |
| I | LastGLots × (1 + 0.618 × rangePct) | (direct OpenOrder) | varies |
| P | 15% (8% for P_Extra) | (direct OpenOrder) | 15% / 8% |
| T | 15% (drops to 0.5..10%) | (direct OpenOrder) | varies |
| S | percentTP ∈ {5,10,15} | (direct OpenOrder) | 5/10/15% |
| ~~U~~ | ~~15%~~ | ~~(direct OpenOrder)~~ | ✅ **DELETED** (OQ-8 user decision 2026-05-01) — row removed from rewrite |

- **Why:** Lot sizing เป็น direct driver ของ Net Profit + DD; preserve 1:1 = G3
- **Source:** CodeWiki §4.1
- **Related FR:** FR-3.1, NFR-1.1
- **Validation hint:** QA pick 5 random trades → verify lot ตรงกับ formula

### BR-4.2 — LimitMaxLotSizeRatio cap 🔒

**Condition:** Calculated lot > `LimitMaxLotSizeRatio (default 2.9) × SymbolInfoDouble(SYMBOL_VOLUME_MAX)`
**Action:** Clamp lot ลงเหลือ cap value + log warning
- **Why:** Pyramid stack อาจคำนวณ lot เกิน broker limit → broker reject = trade flow break
- **Source:** CodeWiki §4.1 LimitMaxLotSizeRatio
- **Related FR:** FR-3.6
- **Validation hint:** QA verify lot ใน trade list ≤ cap ทุก trade

### BR-4.3 — Min lot floor 🔒

**Condition:** Calculated lot < `SymbolInfoDouble(SYMBOL_VOLUME_MIN)`
**Action:** Clamp lot ขึ้นเหลือ min volume
- **Source:** CodeWiki §4.1 Clamp formula
- **Related FR:** FR-3.1

---

## 6. BR-5 — Stop-Loss / Take-Profit Rules (per slot)

ทุก rule preserve 1:1 ตาม CodeWiki §4.2 ยกเว้น **BI** (G4 fix — ดู BR-7.1).

### BR-5.1 — SL/TP Method per Slot 🔒

**Condition:** Slot เปิด market order
**Action:** กำหนด SL + TP ตามตารางด้านล่าง

| Slot | SL Method | TP Method | Notes |
|------|-----------|-----------|-------|
| **C/D** | Implicit (ExtraTakeProfit_CD manages) | Implicit (cloud-touch / Force decay / timeout) | — |
| **J** | Implicit (relies on CD pool exit) | Implicit | (G4 fix: J uses own ExtraTakeProfit_J — BR-7.2) |
| **H** | Implicit | WPR extremes + Ichimoku touch | — |
| **K** | Implicit | Profit + cloud-mid + fractal | — |
| **G** | Cloud edge / fractal / 61.8 pip floor | Trailing via maxProfitPIP + cloud touch | — |
| **GO** | Inherited from G | Trailing + cloud touch | — |
| **L** | Implicit (managed) | Multi-rule cascade | — |
| **M** | Implicit | Cloud touch + trailing in NN mode | — |
| **Q** | None (cloud-touch only) | Cloud touch in profit | — |
| **R** | BBBot/BBTop ± 10 pip (computed at entry) | Multi-tiered by orderIndex | — |
| **B** | min(wave low, BBBot, lowMain) | 20+tpplus% pseudo-TP, complex exit | — |
| **BR** | Mode-dependent (5..120 pip) | Mode-dependent | — |
| **BI** | **⚠️ G4 FIX: Inherit from B parent** (ดู BR-7.1) | Auto-cut when parent B closes | **CHANGED** from `SL=0` |
| **I** | 0 | Auto-cut when G closes | — |
| **P** | Lowest_close(20) ∩ BBBot ∩ lowMain | 300 pip base, scaled by Hull | — |
| **T** | max(Hull, BBWidth, 90 pip floor) | Implicit | — |
| **S** | ≥ 90 pip from BBand | Implicit | — |
| ~~**U**~~ | ~~±70 pip from cloud~~ | ~~Implicit (inert)~~ | ✅ **DELETED** (OQ-8 user decision 2026-05-01) — row removed from rewrite |

- **Why:** SL/TP เป็น direct driver ของ exit timing → win rate + avg loss; G3 contract
- **Source:** CodeWiki §4.2
- **Related FR:** FR-3.2

### BR-5.2 — Trailing/Breakeven 🔒

**Condition:** Slot ∈ {G, GO, M, S} + ผ่าน `maxProfitPIP` threshold + cloud-touch event
**Action:** Trail stop / close per cloud-touch pattern (ad-hoc per slot)
- **Source:** CodeWiki §4.2 Trailing/BE row
- **Related FR:** FR-3.5

---

## 7. BR-6 — Pending State Machines

EA เดิมรัน **multiple parallel pending state machines** ที่ persist ใน GlobalVariable + DB.txt; rewrite ต้อง preserve transition table 1:1.

### BR-6.1 — C-Pending 🔒

```
IDLE
  ─ trigger: BusinessLogic_C เห็น signal valid + condition match ─→
PENDING (CPendingComment="C,...")
  ─ trigger: price reaches trigger ภายใน 8 H4 bars ─→ EXECUTED → IDLE
  ─ trigger: 8 H4 bars timeout ─→ IDLE
```

- **Source:** CodeWiki §2.5
- **Related FR:** FR-5.1, FR-2.5

### BR-6.2 — C-Pending-ADX 🔒

Same shape เป็น C-Pending แต่ timeout = **30 bars**, comment ลงท้าย `,A` (CPendingCommentADX)
- **Source:** CodeWiki §2.5

### BR-6.3 — R-Pending 🔒

```
IDLE
  ─ trigger: R buy condition met ─→
R_BUY_PENDING (RBuyOrderPendingDate set)
  ─ trigger: 40 bars OR price returns to cloud ─→ IDLE
  ─ trigger: price > _pendingPrice ─→ EXECUTED → IDLE
(mirror สำหรับ SELL: RSellOrderPendingDate)
```

- **Source:** CodeWiki §2.5

### BR-6.4 — P-Pending (most complex) 🔒

```
IDLE
  ─ trigger: BusinessLogic_P เห็น big SL หรือ extreme bands ─→
PENDING (PPendingCommand = "ts,dir,diffSL,bandRatio")
  ─ each tick: BusinessLogic_P_Pending evaluates ─→
    ├── PX mode (Force trigger หรือ _diffSL≥200)
    ├── PH mode (default)
    └── EXECUTED with sub-variant (E/N) → IDLE
  ─ trigger: 70-bar timeout OR Bollinger violation ─→ IDLE
```

- **Source:** CodeWiki §2.5

### BR-6.5 — M-Pending 🔒

```
IDLE
  ─ trigger: BusinessLogic_M store snapshot ─→
MPENDING (MPendingAtPrice, MPendingAtRefPrice, MPendingLot)
  ─ trigger: price moves > thresholds ─→ EXECUTED with +25% lot bonus → IDLE
  ─ invalidation: M slot's signal flip (BusinessLogic_M re-evaluation มาแบบ opposite direction) ─→ IDLE
```

- **Timeout/invalidation:** EA เดิมไม่มี hard wallclock/bar timeout ของ M-Pending ใน CodeWiki §2.5 — invalidation มี 2 แบบเท่านั้น: (a) trigger condition met (price ผ่าน thresholds) → EXECUTED, (b) M's signal source flip → store snapshot ใหม่ทับ
- **Architecture-domain Open Question (OQ-A1):** ถ้า price stuck ใน range + signal ไม่ flip → state อาจค้าง PENDING ตลอด session. Architect (Phase 1B) ต้องตัดสินใจ **safety force-clear** (เช่น 100 H4 bar fallback) เพื่อป้องกัน state file โต + GlobalVariable namespace pollution — BA flag เป็น OQ-A1 ไม่ propose ตัวเลขเพราะเกี่ยวกับ state-cleaner design (HOW)
- **Source:** CodeWiki §2.5
- **Related FR:** FR-5.1, FR-5.2

### BR-6.6 — T-Pending 🔒

```
IDLE
  ─ BusinessLogic_T ─→ TPENDING (TBuyOrderPendingDate หรือ TSellOrderPendingDate)
  ─ BusinessLogic_PendingT confirms ─→ EXECUTED → IDLE
```

- **Timeout/invalidation:** Trigger event = `BusinessLogic_PendingT` confirmation (EA เดิม CodeWiki §3 Slot T section). ขอบเขต confirmation ที่ Architect ต้องอ่าน CodeWiki §3 Slot T section + ideation-brief เพื่อแปลง confirmation logic เป็น decision table (TD's job เพราะเป็น HOW). EA เดิมไม่มี hard timeout
- **Architecture-domain Open Question (OQ-A2):** safety force-clear ของ T-Pending (เผื่อ confirmation ไม่มา) — BA flag เป็น OQ-A2 ที่ Architect resolve
- **Source:** CodeWiki §2.5, §3 Slot T

### BR-6.7 — Q-Pending 🔒

```
IDLE
  ─ trigger: per QPendingCode logic per slot ─→
QPENDING (QPendingCode ∈ {0, 1, 2, 3})
  ─ code-specific resolution per CodeWiki §3 Slot Q ─→ EXECUTED → IDLE
```

- **Timeout/invalidation:** Code-specific resolution ตาม QPendingCode value (CodeWiki §3 Slot Q section บรรยาย logic ของ code 0/1/2/3). EA เดิมไม่มี hard wallclock/bar timeout
- **Architecture-domain Open Question (OQ-A3):** safety force-clear ของ Q-Pending — Architect resolve ตอน design state cleaner
- **Source:** CodeWiki §2.5, §3 Slot Q

> **OQ-A1/A2/A3 routing:** Architecture-domain — Architect (Phase 1B) ต้องตัดสินใจ safety force-clear policy ตอน design state cleaner. ถ้า user ยัง prefer "no force-clear" (M/T/Q-Pending คงเข้ามาอย่างเดียว) Architect document ใน design doc พร้อม impact assessment (state file growth, GlobalVariable retention)

### BR-6.8 — Force-Pending (cross-slot) 🔒

```
IDLE
  ─ ForceDivergentWorking sets flag ─→
IsForcePendingActionBuyOrder|SellOrder = true
  ─ > 9 H4 bars elapsed without trigger ─→ IDLE (cleared OnTick :249)
  ─ ForcePendingActionOrder fires ─→ EXECUTED → IDLE
```

- **Source:** CodeWiki §2.5, §2.2 OnTick

### BR-6.9 — Persistence invariant 🔒

**Condition:** EA เขียน state file
**Action:** ทุก state field ใน CodeWiki §1.3 (state variables block) + pending state ของแต่ละ machine ต้อง persist (atomic write per FR-5.2)
- **Source:** CodeWiki §1.3, §5.4

---

## 8. BR-7 — Bug Fix Semantics ⚠️ (G4)

หมวดนี้คือ 2 intentional rule changes ที่ user decision 2026-05-01 = **FIX**. G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (rewrite-G4-ON vs baseline ≤ 25%, default build, contribution included) + NFR-1.8 informational delta (no acceptance gate, BT-001 re-baseline 2026-05-12) — ดู `03 § NFR-1 Empirical Citation` + `trading-baseline.md`.

### BR-7.1 — BI SL inheritance ⚠️ (CRITICAL fix) ✅ semantic resolved

**Condition:** Slot BI signal trigger + parent B slot มี active position(s) ที่มี SL set
**Action:** BI order ต้องเปิดด้วย SL ที่อิง parent B — semantic = **same SL distance** (user decision 2026-05-01)
**Locked semantic:** **(a) same SL distance** — BI ใช้ pip distance เดียวกับ B parent's SL วัดจาก BI entry price (symmetric per-position risk; preserve risk model ที่ EA เดิมใช้กับ slot G/R/P)

- **Why:** ปัจจุบัน BI เปิดด้วย `SL=0` (CodeWiki §6.2 CRITICAL `:20326 :20357`) → naked exposure unlimited; user decision 2026-05-01 = FIX with semantic (a)
- **Source:** CodeWiki §6.2 CRITICAL P1.3, ideation-brief OQ-1 resolved, OQ-3.3 user resolved 2026-05-01
- **Related FR:** FR-3.3
- **Validation hint:** QA inspect BI trade journal entries — `sl > 0` ทุกราย; verify `(BI_entry - BI_sl)` ≈ `(B_entry - B_sl)` ใน pip distance; portfolio-level drift roll up via NFR-1.1 Bucket A (rewrite-G4-ON build); NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable)

> ✅ **OQ-3.3 resolved 2026-05-01:** Semantic locked = (a) same SL distance — SD agent (Phase 1B) ลงรายละเอียด exact pip arithmetic; TD lock implementation ใน Phase 1D

### BR-7.2 — ExtraTakeProfit_J magic correction ⚠️ (HIGH fix)

**Condition:** OnTick exit pass calls `ExtraTakeProfit_J` (or refactored slot J `manageExits()`)
**Action:** Function iterate **`MagicJ` (=206)** เท่านั้น — ห้าม touch `MagicF` (=201)
- **Why:** ปัจจุบัน function iterate `MagicF` แทน `MagicJ` (CodeWiki §6.2 HIGH `:10897`) → J orders ไม่ได้ exit-management ของตัวเองเลย; F โดน double-managed; user decision 2026-05-01 = FIX
- **Source:** CodeWiki §6.2 HIGH P1.4, ideation-brief OQ-1 resolved
- **Related FR:** FR-3.4
- **Expected drift:** J win rate ลดเล็กน้อย (exit เข้มงวดกว่าเดิม), F อาจดีขึ้นเล็กน้อย, portfolio-level อาจดีขึ้น
- **Validation hint:** QA inspect trade journal — ทุก J close event มี `triggering_function = "ExtraTakeProfit_J"` (ไม่ใช่ "_F"); F close ไม่อ้างถึง J; per-slot J/F drift check via NFR-1.6 (rewrite-G4-ON build); NFR-1.8 informational delta optional

---

## 9. BR-8 — Cross-slot Bulk Cleanup Rules

EA เดิมมี cleanup mechanism ที่ทำงานข้าม slot — Safe-port (lock กำไรเล็กน้อยก่อน DD ลึก), Ichimoku double-bounce, ForceCutloss (CD only), overload helpers (E/C/G), และ ExtraCheckFunction2 (CD count==1 demote). หมวดนี้ preserve trigger conditions + actions 1:1 จาก CodeWiki §5.5 — เปลี่ยนใดๆ = portfolio-level behavior drift.

### BR-8.1 — OrderGroupStartWorkflow (Safe port) 🔒

**Condition (all AND):**
- `weakOrderCount > 1` (จำนวน orders ที่อยู่ใน loss territory เกิน threshold)
- average bad-PIP excursion ของ weak orders > **55 pips**
- combined `currentProfit > 0` (portfolio รวมยังบวก)

**Action:** Close ALL positions ของ slots `{CD, J, H, K, L, M, Q, GO, T, S}` พร้อมกัน
- **Why:** "Safe port" — ล็อค small profit ที่มีก่อน DD ลึกขึ้น (CodeWiki §5.5 P2.6)
- **Source:** CodeWiki §5.5 `:328`
- **Related FR:** FR-7.1
- **Validation hint:** QA simulate scenario → verify bulk close pattern + journal `triggering_function=OrderGroupStartWorkflow`

### BR-8.2 — OrderGroupStartWorkflow2 (Ichimoku double-bounce) 🔒

**Condition:** Ichimoku double-bounce pattern detected + `weakOrderCount > 2` + Force confirmation
**Action:** Bulk close ตาม pattern ที่ EA เดิมระบุ (CodeWiki §5.5 `:512`)
- **Source:** CodeWiki §5.5
- **Related FR:** FR-7.2

### BR-8.3 — ForceCutloss (CD-only) 🔒

**Condition:** CD trade ใน loss + Stochastic M10 + MACD D1 confirm cut signal
**Action:** Close CD position
- **Source:** CodeWiki §5.5 `:9009`
- **Related FR:** FR-7.3

### BR-8.4 — Overload helpers 🔒

| Helper | Condition | Action | Source |
|--------|-----------|--------|--------|
| **EOverload** | Peak-reversion (WPR>90 OR Force<−11/−12) + ≥33 pip last gap | Add extra CD order; lot ÷ `InteruptRatioDecrease` (default 8) | `:9395` |
| **COverload** | Repeated MACD same-sign losses ≥7 bars + weak ADXW | Cut CD size | `:9277` |
| **GOverload** | G order closes (called from `ExtraTakeProfit_G`) | Open inverse-direction GO order | `:9493` |

- **Source:** CodeWiki §5.5
- **Related FR:** FR-7.5

### BR-8.5 — ExtraCheckFunction2 🔒

**Condition:** `portfolio[MagicCD].count == 1`
**Action:** Demote `ExtraForceModeReason`
- **Source:** CodeWiki §2.2 OnTick block
- **Related FR:** FR-7.4

---

## 10. BR-9 — System Invariants

หมวดนี้คือ **rule ที่ต้อง true ตลอด** ไม่ผูกกับ event เดียว.

### BR-9.1 — Symbol invariant 🔒

**Invariant:** `_Symbol == "EURUSD"` ตลอดอายุ EA session
**Enforcement:** OnInit reject load (FR-1.2, NFR-5.3)
- **Source:** C-3, FR-1.2

### BR-9.2 — Single-thread tick invariant 🔒

**Invariant:** OnTick run ทีละ tick (no re-entrancy)
**Enforcement:** Rely on broker single-threaded tick delivery (CodeWiki §6.3 — explicitly out-of-scope ใน Phase 1, P4.7)
- **Source:** CodeWiki §6.3, `01 § 6.2` Won't Permanent

### BR-9.3 — DigitMultipier invariant 🔒

**Invariant:** `DigitMultipier = 10` ถ้า broker ใช้ 5-digit pricing (FBS Standard); = 1 ถ้า 4-digit
**Enforcement:** Auto-detect ใน OnInit; ทุก pip arithmetic คูณด้วย `DigitMultipier`
- **Source:** CodeWiki §1.1

### BR-9.4 — Magic range invariant 🔒

**Invariant:** Magic ของ EA ∈ [200, 220] เท่านั้น
**Enforcement:** BR-1.1 table — ทุก OpenOrder helper ใส่ magic จากตาราง
- **Source:** CodeWiki §1.5

### BR-9.5 — Behavioral parity invariant 🔒

**Invariant:** Backtest 2021-2025 EURUSD H4 ของ rewrite default build (G4 fixes ON) อยู่ใน regression budget (NFR-1.1 ถึง NFR-1.7) — **single-pass measurement บน rewrite-G4-ON build เท่านั้น** (BT-001 re-baseline 2026-05-12; `DISABLE_G4_FIXES` build halts pre-window per IMPL-062 Run #2 → ห้ามใช้เป็น verification vehicle ต่อ NFR-1.1). Bucket B (NFR-1.8) = **informational delta** ที่ record sign + magnitude ถ้า `DISABLE_G4_FIXES` build รัน partial pre-CircuitBreaker window ได้ — ไม่ใช่ acceptance gate.
- **Source:** `trading-baseline.md`, NFR-1.x, BT-001 (2026-05-12) re-baseline — ดู `03 § NFR-1 Empirical Citation`

---

## 11. Decision Tables Summary

ตารางนี้สรุป rule ที่เป็น decision matrix (multi-input → action) — ใช้สำหรับ unit-test design.

| Rule | Inputs | Output | BR ref |
|------|--------|--------|--------|
| Slot magic assignment | Slot ID | Magic number (200..220) | BR-1.1 |
| Comment disambiguation | Slot ID + shared-magic group | Comment prefix | BR-1.2 |
| Slot evaluation order | Tick start | Slot list ใน order | BR-2.2 |
| Time gate | Server time + Spread + Day + Holiday window | Block flag | BR-3.1 ถึง BR-3.7 |
| Lot calculation | Slot + Account balance + risk% + slPips | Final lot (after cap/floor) | BR-4.1 ถึง BR-4.3 |
| SL/TP per slot | Slot + Entry context | SL value + TP value | BR-5.1 |
| BI SL inheritance (G4 fix) | BI signal + B parent SL | BI SL value = same SL distance (locked 2026-05-01) | BR-7.1 |
| Pending state transition | Current state + tick condition | Next state | BR-6.x |
| Safe-port trigger | weakOrderCount + avg badPIP + currentProfit | Bulk close flag | BR-8.1 |
| Overload helpers | Per-helper conditions | Add/cut/hedge action | BR-8.4 |

---

## 12. Resolved Questions — Rule domain

### ✅ OQ-3.3 (BR-7.1) — BI SL inheritance semantic → **same SL distance**

**User decision (2026-05-01):** **(a) same SL distance** — accept BA default

**Why:** Symmetric per-position risk model — BI ใช้ pip distance เดียวกับ B parent's SL วัดจาก BI entry price; preserve risk model ที่ EA เดิมใช้กับ slot อื่น (G, R, P); option (b) absolute price มี edge case ที่ BI entry ไกลจาก B = SL ใกล้เกินไป โดน wipe ทันที

**Resolution path forward:** SD agent (Phase 1B) ลงรายละเอียด exact SL pip number (อิงจาก B's SL distance ตอน BI fires); TD lock implementation ตอน Phase 1D

---

> **End of 04 — Business Rules** — 9 rule categories, ~40 explicit rules, 8 pending state machines, 5 invariants, all rule-domain open questions ✅ resolved 2026-05-01
