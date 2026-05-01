# Phoenicis-n v2.00 — Code Wiki

> **Wiki Version:** 1.0  
> **Source Analyzed:** `Experts/PhoenicisN2.10_stable.mq5` (22,016 LOC) + libraries `LibCommon1.1`, `LibIndicator1.1`, `LibSubDem1.6`, `LibDatabase1.1`, `LibMonitor1.1`  
> **Date:** 2026-04-09  
> **Purpose:** AI-readable documentation for reconstruction, audit, and incremental improvement of the EA.

---

## 📋 Section 1: EA Overview

### 1.1 Identity

| Field | Value |
|-------|-------|
| Strategy Type | **Multi-slot, mean-reversion + trend-continuation hybrid** running ~17 letter-coded sub-strategies in parallel under one symbol |
| Primary Timeframe | **PERIOD_H4** (signal evaluation); D1 (regime filter); M10/M15 (confirmation); M5 (ZigZag, OnTick clock) |
| Asset Class | Forex (3/5-digit detection enables `DigitMultipier=10` for points→pips conversion) |
| Execution Style | Market orders via `CTrade`, with custom in-EA "pending" state machines (no broker pendings) |
| Position Sizing | Risk-percent-based via `CalculateLotSize(percent, slPips)` + per-slot static multipliers, capped by `LimitMaxLotSizeRatio=2.9` |
| Magic Number Pool | 200..220 (one per slot, see §1.5) |

### 1.2 Strategy Summary

Phoenicis-n is a **portfolio of independent letter-coded entry signals** (C, D, J, H, K, L, LX, G, G2, GO, M, Q, R, I, P, T, S, B, BR, BI, U) all operating on a single symbol. Each "slot" has:

1. A `BusinessLogic_<X>()` entry function called sequentially in `OnTick()`.
2. An `ExtraTakeProfit_<X>()` exit/management function called sequentially in `OnTick()`.
3. A unique `Magic<X>` integer used to filter positions in history scans.

The unifying signal substrate is the **Ichimoku H4 cloud** (`IchimokuBufferA/B`) combined with **Force Index H4** (`ForceBuffer`, period=21=`FIDValue`), **ADX H4 + ADX Wilder H4 + ADX D1**, **WPR H4(14/100) and D1(14/100)**, **DeMarker H4 (14/42)**, **Hull MA H4(55,2.1)**, **Bollinger Bands H4(20,2)**, **Fractals H4**, **ZigZag M5**, **Stochastic M10/H4**, **MACD M10/D1**, plus a custom **SubDem** support/resistance zone library. Slots differentiate themselves by which permutation of these signals constitutes a valid entry, and by their drawdown/recovery role (some are first-shot entries, some are pyramiders, some are reverse-recovery hedges).

There is **no slippage control parameter, no news filter, no `input` keyword anywhere** — every threshold is hardcoded as a global. This is the EA's most significant code-quality liability.

### 1.3 Input Parameters Reference

> ⚠ **CRITICAL FINDING**: The EA has **zero `input`/`sinput`/`extern` declarations**. Every "parameter" is a hardcoded global variable. The user cannot tune the EA without recompiling. The table below documents the most influential of these pseudo-parameters.

| Pseudo-Parameter | Type | Default | Role | Notes |
|---|---|---|---|---|
| `EAName` | `#define` | `"Phoenicis-n"` | Magic-comment prefix, GlobalVariable namespace | — |
| `Version` | `#define` | `"2.00"` | Version tag | — |
| `InteruptRatioDecrease` | `double` | `8` | Lot reduction divisor in EOverload | `[MAGIC NUMBER]` |
| `MainOverloadRatioDecrease` | `double` | `4` | Main overload divisor | `[MAGIC NUMBER]` |
| `UseCOverload` | `bool` | `true` | Enable COverload safety net | — |
| `UseOverloadAutoRange` | `bool` | `true` | Auto wave range for overload | — |
| `OverLoadUseLastLot` | `bool` | `true` | Reuse last lot in overload | — |
| `FIDValue` | `int` | `21` | Force Index period (H4 + M2) | `[MAGIC NUMBER]` |
| `TradeOnHNN` | `bool` | `false` | Allow H slot in "NN" sub-mode | `[REVIEW]` |
| `ZigZagPeriod` | `ENUM_TIMEFRAMES` | `PERIOD_M5` | ZigZag timeframe | `[MAGIC NUMBER]` |
| `LADXMLevel` | `double` | `30` | L slot ADX threshold | `[MAGIC NUMBER]` |
| `LADXMLevelMin` | `double` | `22` | L slot ADX floor | `[MAGIC NUMBER]` |
| `JPip1StBetweenC` | `int` | `-10` | Min pip gap from C trade for J entry | `[MAGIC NUMBER]` |
| `JPip1StBetweenD` | `int` | `-13` | Same, for D | `[MAGIC NUMBER]` |
| `FRatioDecrease` | `double` | `1` | F slot lot scale | `[MAGIC NUMBER]` |
| `JRatioDecrease` | `double` | `2.3` | J slot lot scale | `[MAGIC NUMBER]` |
| `GRatioDecrease`/`GORatioDecrease`/`HRatioDecrease` | `double` | `10` | Slot lot scales | `[MAGIC NUMBER]` |
| `GRisk` | `int` | `15` | G slot risk percent | `[MAGIC NUMBER]` |
| `MainRiskRatio` | `double` | `1` (LibCommon) | Risk denominator for `GetSizeLot2` | `[MAGIC NUMBER]` |
| `LimitMaxLotSizeRatio` | `double` | `2.9` (LibCommon) | Max lot pyramid cap | `[MAGIC NUMBER]` |
| `NormalTakeProfitPIP` | `int` | `48` (LibCommon) | Standard TP distance baseline | `[MAGIC NUMBER]` |

State variables (NOT parameters but persisted across runs via `GlobalVariable*`/`<login>_DB.txt`):

`OrderForceTimeStamp`, `IsForcePendingActionSellOrder/BuyOrder`, `ForcePendingActionOrderDate`, `GPauseDate`, `FirstSetOrderDate`, `QPendingCode/Lot/Date`, `CPendingComment/Type/BuyLot/SellLot/DateStart`, `CPendingCommentADX/...`, `RBuyOrderPendingDate`, `RSellOrderPendingDate`, `MPendingAtPrice/AtRefPrice/Lot`, `LastLongRunDate`, `PPendingCommand`, `TBuyOrderPendingDate`, `TSellOrderPendingDate`, `TXOrderPendingType`, `BanCStartDate`, `BanLStartDate`, `BanMStartDate`, `KLastOrderDate`, `StartupEquity`, `worst_drawdown_percentage`.

### 1.4 Dependencies

- **Built-in MT5 indicators** (created in `OnInit()`):
  - `iIchimoku` H4 (9,26,52) → `IchimokuHandle` + buffers A/B/T/K/C
  - `iIchimoku` D1 (9,26,52) → `IchimokuDHandle` (buffers A/B)
  - `iIchimoku` H4 (9,26,52) reused as `Ichimoku26Handle` (buffers A26/B26 with shift −26 for forward cloud)
  - `iMACD` M10 (12,26,9, CLOSE) → `MACDHandle`
  - `iMACD` D1 → `MACDHandle4` (signal buffer only)
  - `iStochastic` H4 (5,3,3, EMA, LOW/HIGH) → `StoHandle` + signal
  - `iStochastic` M10 (5,3,3) → `Sto10Handle`
  - `iWPR` H4 14 → `WPRHandle`; H4 100 → `WPR100Handle`; D1 14 → `WPR14DHandle`; D1 100 → `WPR100DHandle`; M15 14/100 → `WPR_M15_*`
  - `iForce` H4 (21, SMA, TICK) → `ForceHandle`; M2 (21, SMA, TICK) → `ForceMHandle`
  - `iFractals` H4 → `FractalHandle`
  - `iADX` H4 14 → `IDXHandle`; `iADXWilder` H4 14 → `IDXWHandle`
  - `iADX` D1 → `ADXD1Handle`; `iADXWilder` D1 → `ADXD1WHandle`
  - `iDeMarker` H4 (42) → `DEMHandle`; (14) → `DEM14Handle`; M15 (28) → `DEM_M15_28_Handle`
  - `iBands` H4 (20,0,2,CLOSE) → `BollBHandle`
  - `iRSI` H4 (14,CLOSE) → `RSIHandle`
- **Custom indicators**:
  - `iCustom("Examples\\ZigZag", 32,5,2)` on M5 → `ZigZagHandle`
  - `iCustom("iHull", 55, 2.1)` on H4 → `Hull55_2_1Handle`
- **Include files** (`#include` from EA):
  - `<Trade/Trade.mqh>` — standard `CTrade`
  - `LibSubDem1.6.mq5` — support/resistance zone calculator (`SubDemCalcModel` struct, `ExtractZoneAction`, `ZoneToStr`, `ZoneStrengthToStr`)
  - `LibDatabase1.1.mq5` — `<login>_DB.txt` key/value file persistence (`GetKeyPair`, `MyGlobalVariableSet`, `ReadFileDatabase`, `SaveFileDatabase`)
  - `LibMonitor1.1.mq5` — `WatchProfits`, `DrawProfitTags`, drawdown bookkeeping
  - `LibCommon1.1.mq5` — math helpers, time filters, lot calculator, indicator buffer globals (transitively pulls in `LibIndicator1.1.mq5`)
- **Libraries NOT included by EA but referenced by other libraries** (`LibOrder1.1`, `LibLogicP/S/T/U/B`) — these contain alternative implementations of the same Magic constants and order helpers but are NOT linked into Phoenicis-n. The EA inlines its own copies starting at line 15003.
- **External resources**: A text file `<account_login>_DB.txt` in the MT5 Files folder.

### 1.5 Magic Number Pool

| Slot | Magic | Defined | Strategy Role |
|---|---|---|---|
| CD (C and D share pool) | 200 | `:15003` | Primary signal — cloud break + Force peak triple |
| F | 201 | `:15004` | Force-divergent confirmation |
| H | 205 | `:15005` | Fractal + Ichimoku distance + ADX cross |
| J | 206 | `:15006` | Follower trade after C/D (max 2) |
| K | 207 | `:15007` | Force crossover with Ichimoku layer logic |
| G | 208 | `:15008` | Force crossover + ADX + Ichimoku wave (also G2) |
| GO | 209 | `:15010` | G-Overload (reverse hedge after G peak close) |
| M | 210 | `:15011` | ADX-W valley + WPR-Ichimoku alignment (with PendingM) |
| L | 211 | `:15009` | ADX + cloud break + C-pending gate (with LX add-on) |
| Q | 212 | `:15012` | Pending state machine with WPR extremes |
| R | 213 | `:15013` | Pending: BUY/SELL with Bollinger SL |
| B | 214 | `:15014` | Anti-trend (`!IsADXPeakValid`) fractal + cloud distance |
| BR | 215 | `:15015` | Reverse hedge of B (orphan: only called from B exit) |
| BI | 214 *(shares B!)* | `:15015` LibOrder note | Pyramid child of B with `SL=0` |
| I | 216 | `:15016` | G-parasite Fibonacci-add-on |
| S | 217 | `:15017` | Wave-peak reversal after L/K close |
| P | 218 | `:15018` | Multi-stage pending state machine |
| T | 219 | `:15019` | Hull/SubDem-zone reversal |
| U | 220 | `:15020` | **DISABLED** in OnTick (`:291`, `:322`) |

> **AI Reconstruction Note (§1):** To rebuild this section, an AI must (a) parse `OnInit()` for all `iCustom`/`iIndicator` handle creations, (b) grep `Magic\w+\s*=` for slot magic numbers, (c) note the absence of `input` declarations, and (d) treat each top-level global as a parameter candidate when generating a refactored EA. Plan to introduce an `InputsContainer` struct that mirrors current globals 1:1 so the migration is mechanical.

---

## 🏗️ Section 2: Architecture Map

### 2.1 Event Handler Overview

| Handler | Trigger | Primary Role | Calls |
|---------|---------|--------------|-------|
| `OnInit()` `:77` | EA load | Open file DB, create indicator handles, detect digit multiplier, reset slot ratios, restore state via `LoadGlobal/LoadLibOrder/RegisterB`. Returns `INIT_SUCCEEDED` unconditionally. | `iCustom`, `iIchimoku`, `iMACD`, `iStochastic`, `iWPR`, `iForce`, `iFractals`, `iADX`, `iADXWilder`, `iDeMarker`, `iBands`, `iRSI`, `LoadGlobal`, `LoadLibOrder`, `RegisterB` |
| `OnDeinit()` `:193` | EA unload | Print worst drawdown; kill timer | `EventKillTimer` |
| `OnTick()` `:202` | Every tick | The entire trading pipeline (see §2.2) | ~80 functions |
| `OnTimer()` | — | **Not implemented** (no `SetTimer` call) | — |
| `OnTrade()` | — | **Not implemented** | — |

### 2.2 OnTick() Execution Order (canonical)

```
OnTick()
├── TickLoadBuffer()                  // refresh ALL indicator buffers
├── LoadCommonData()                  // cache ICHI_CLOUD_HIGH/LOW_0, OHLC H4[0]
├── CircuitBreakerOrder()             // halt EA on micro-flip-flop
├── (per-bar block keyed off PERIOD_M5 in tester / PERIOD_H1 live)
│   ├── ExtractZoneAction(H4)         // refresh SubDemCalcModelH4Resist/Support
│   ├── ExtractZoneAction(D1)         // refresh D1 zones
│   └── DrawProfitTags(...)           // visual mode only
├── (force-pending order timeout @ 9 H4 bars) clear IsForcePendingActionXxxOrder
├── (spread guard) return if SPREAD > 10 pip & IsMondayMorningWakeup()
├── ReadTradeDataCD()                 // tally CD orders
├── ReadTradeData()                   // tally all other slots
├── RunCheckWPRWaveWithIchimoku2()    // set WPRWaveWithIchimokuSingal2 + DontWPR* globals
├── (return early if IsMorningWakeup())
├── ExtraTakeProfit_CD/J/H/K/G/GO/I/M/L/Q/R/B/BR/S/T/P/ShortStrategy
│                                      // EXIT pass — runs BEFORE entry pass
├── ForceCutloss()                    // CD safety
├── ExtraCheckFunction2()             // demote ExtraForceModeReason if CD count==1
├── OrderGroupStartWorkflow()         // "Safe port" close-all-with-profit if avg badPIP > 55 pips
├── OrderGroupStartWorkflow2()        // close on Ichimoku double-bounce if weakOrderCount>2
├── (return if IsNewYearSeason2() && CD==0)
├── LotInitial2()                     // recalc cascade lot
├── FindCP()                          // refresh hasCPendingOrder, CPBarOffset
├── CheckADXWithForcePeakValid2()     // set IsADXPeakValid + StartAwayFromIchiIndex
├── BusinessLogic_C / D / J / H / K / G / G2 / I / M / L / LX / Q / R / B / BI
│                                      // ENTRY pass
├── BusinessLogic_S / T / P / P_Pending / P_Extra
├── // BusinessLogic_U()              // commented out / DISABLED
├── WatchProfits(EAName)              // drawdown bookkeeping
└── SaveFileDatabase()                // persist key/value DB
```

### 2.3 Function Call Graph (high level)

```
TickLoadBuffer ──> CopyBuffer × ~30 indicators

OnTick ─┬── exit pass → ExtraTakeProfit_X(magic) → CloseAllPositions(type, magic)
        │                                       └─> TradeClosePosition(ticket)
        │
        ├── entry pass → BusinessLogic_X
        │                  ├── (state read) BuyOrders__X / SellOrders__X / *Lots / *Profit
        │                  ├── (signal helper) IChiThisWaveStartBars / IChiLastWaveMaxBars
        │                  │                  / CheckForce / CheckGapFromIchi
        │                  │                  / CheckForceWaveMaxValue / CheckForceAlreadyCompleteAtStartWave
        │                  │                  / FindCP / CheckADXWithForcePeakValid2
        │                  │                  / RunCheckWPRWaveWithIchimoku2
        │                  │                  / FindZigZag / FractalPredicate
        │                  │                  / ConflidentialTradeOnG (G/I)
        │                  │                  / RatioPriceSubDem(D)
        │                  ├── (lot calc)    CalculateLotSize / GetSizeLot2
        │                  │                  / GetDLot / HGetLotSize / CalculateRuntimeLots2
        │                  └── (open helper) OpenOrderCD / OpenOrderH / OpenOrderJ / OpenOrderG /
        │                                    OpenOrderGO / OpenOrderL / OpenOrderM / OpenOrderQ /
        │                                    OpenOrder (generic)
        │                                       └─> useServerFill → CTrade.OrderSend
        │
        └── housekeeping → WatchProfits → MyGlobalVariableSet
                         → SaveFileDatabase → file write
```

### 2.4 Data Flow Diagram

```
[Market data] → TickLoadBuffer → indicator buffer globals (Ichi/Force/WPR/ADX/...)
                                          ↓
                              LoadCommonData (cache OHLC + cloud)
                                          ↓
[Account state] → ReadTradeData → BuyOrders__X / SellOrders__X / *Profit / *Lots / *Date globals
                                          ↓
[GlobalVariable + DB.txt] → LoadGlobal → state machine globals (Pending*, Ban*, ForceTimeStamp)
                                          ↓
                            ┌─────────────┴─────────────┐
                            ▼                            ▼
            ExtraTakeProfit_X (exits)        BusinessLogic_X (entries)
                            │                            │
                            ▼                            ▼
                    CloseAllPositions             OpenOrder*  → CTrade
                                          ↓
                              WatchProfits → drawdown
                                          ↓
                              SaveFileDatabase → DB.txt
```

### 2.5 State Machines (per-slot pending workflows)

The EA runs **multiple parallel pending state machines**, each persisted to GlobalVariable + DB.txt:

```
C-Pending state:
  IDLE --(BusinessLogic_C trigger)--> CPENDING (CPendingComment="C,...")
        --(price reaches trigger within 8 H4 bars)--> EXECUTED → IDLE
        --(8 bars timeout)--> IDLE
C-Pending-ADX state: same shape, 30-bar timeout, comment ends ",A"

R-Pending state:
  IDLE --(R buy condition met)--> R_BUY_PENDING (RBuyOrderPendingDate set)
        --(40 bars OR price returns to cloud)--> IDLE
        --(price > _pendingPrice)--> EXECUTED → IDLE
  (mirror for SELL: RSellOrderPendingDate)

P-Pending state (most complex):
  IDLE --(BusinessLogic_P sees big SL or extreme bands)-->
        PENDING (PPendingCommand = "ts,dir,diffSL,bandRatio")
        --(BusinessLogic_P_Pending evaluates each tick)-->
              ├── PX mode (Force trigger or _diffSL≥200)
              ├── PH mode (default)
              └── EXECUTED with sub-variant (E/N) → IDLE
        --(70-bar timeout OR Bollinger violation)--> IDLE

M-Pending state:
  IDLE --(BusinessLogic_M store snapshot)-->
        MPENDING (MPendingAtPrice, MPendingAtRefPrice, MPendingLot)
        --(price moves > thresholds)--> EXECUTED with +25% lot bonus → IDLE

T-Pending state:
  IDLE --(BusinessLogic_T)--> TPENDING (TBuyOrderPendingDate or TSellOrderPendingDate)
        --(BusinessLogic_PendingT confirms)--> EXECUTED → IDLE

Q-Pending state:
  QPendingCode in {0,1,2,3} → see §3 Slot Q

Force-Pending state (cross-slot):
  IDLE --(ForceDivergentWorking sets flag)-->
        IsForcePendingActionBuyOrder|SellOrder = true
        --(>9 H4 bars elapsed without trigger)--> IDLE  (cleared in OnTick :249)
        --(ForcePendingActionOrder fires)--> EXECUTED → IDLE
```

> **AI Reconstruction Note (§2):** This is a **single-threaded, tick-driven, megaswitch** architecture. To rebuild, do **not** try to merge slots into one polymorphic strategy class — that hides the per-slot quirks. Instead, define a `Slot` interface (`shouldEnter()`, `manageExits()`, `magic()`, `name()`, `pendingState()`), one concrete class per letter, and a `SlotOrchestrator` that calls them in the same fixed order as `OnTick()`. The exit pass MUST run before the entry pass each tick. Persist pending state to one structured file (JSON or sqlite) instead of the current key=value flat file. The order of indicator buffer creation in `OnInit` is important because `TickLoadBuffer` expects all handles populated.

---

## ⚡ Section 3: Signal Logic (Core)

The EA has 17 active strategy slots. Below, each slot is documented with: **trigger / direction / order properties / exit logic / magic numbers / review flags**. All "pip" distances are post-`DigitMultipier` (i.e. real pips, not points).

---

### 3.1 Slot C — Primary cloud-break with Force triple-peak

**Source:** `BusinessLogic_C @ :753`, `PendingC @ :1747`, `PendingC_ADX @ :2144`, `ExtraTakeProfit_CD @ :9517`. **Magic: 200.**

**Entry conditions (all AND):**
1. `WPRWaveWithIchimokuSingal2 != "No"` (set by `RunCheckWPRWaveWithIchimoku2`).
2. If `CPendingComment != ""` → delegate to `PendingC()` and return; if `CPendingCommentADX != ""` → delegate to `PendingC_ADX`.
3. Price strictly outside Ichimoku H4 cloud — `bid<lowMain` ⇒ BUY, `bid>highMain` ⇒ SELL.
4. `CheckIchiBarForC(type)` passes.
5. Bars 1..4 H4 must NOT poke into the opposite cloud edge — OR price must already be ≥`NormalTakeProfitPIP` (=48) away from cloud.
6. `IChiLastWaveMaxBars(type) != -1`.
7. Cooldown: `OrderForceTimeStamp + hour13 (=46800s) < TimeCurrent()`.
8. If <100 pips from cloud, must exceed 75% of last wave max distance.
9. Wave-start bar count ≥ 10 AND wave length ≥ `0.27 * iChiLastWaveMaxBars` (`:892`).
10. `CheckForceAlreadyCompleteAtStartWave` returns false.
11. `CheckGapFromIchi` and `CheckForceWaveMaxValue` both true.
12. If `BanCStartDate` set, ≥24 H1 bars must have passed (`:914`).
13. `CheckForce(type, fValue=11)` true (`:924`) `[MAGIC NUMBER]`.
14. Force peak triple `_idx1`,`_idx2`,`_idx3` (1st, 2nd, 3rd most-recent peaks of opposite-sign Force) determines a `lotSizeMultiply` between 1.0 and 2.5 based on whether the triple is ascending or descending (`:1041..:1078`).

**Direction:** purely from price vs. Ichimoku H4 cloud edge.

**Order:**
- Lot: `CalculateLotSize(15, 90) * lotSizeMultiply`
- Comment: `"C," + idx3 + "-" + idx2 + "-" + idx1 + "," + fVal3 + "-" + fVal2 + "-" + fVal1`
- Magic: 200 (`MagicCD`)
- Helper: `OpenOrderCD()`

**Pending pipelines:**
- **PendingC** — captures the lot/comment/type for up to 8 H4 bars (`:1815`); on trigger, applies an extra Bollinger/Force multiplier (constants `0.618`, `3.0`, `51.82` `[MAGIC NUMBER]` `:1911,:1918,:1935`); ADX-W cross validation at `:1840`.
- **PendingC_ADX** — separate 30-bar timeout, comment suffix `,A`, halves lot if a regular C order is already open (`:2207`).

**Exit (`ExtraTakeProfit_CD`):**
- Only active if `ExtraForceTakeProfitMode == true` (`:9520`).
- Closes on Force-momentum 3-wave decay + price-action confirmation (`:9574..:9603`).
- Closes on Ichimoku cloud double-bounce (`:9785..:9878`, up to 2 orders/tick).
- Hard exits for timeouts and reverse trend.

**Magic numbers / REVIEW:** `fValue=11`, `100 pip` cloud-distance gate (`:849`), `0.75` ratio (`:863`), `0.27` heuristic (`:892`), `8`/`30`-bar pending timeouts. The whole Force-peak ranking block (`:933..:1025`) is opaque and undocumented. PendingC's `0.618`/`3.0`/`51.82` constants have no calibration commentary. WPR routing flags `WPRWaveWithIchimokuSingal2` are global strings; whole signal routing depends on them.

---

### 3.2 Slot D — Wrapper for force-pending workflow

**Source:** `BusinessLogic_D @ :2368`. **Magic: shares 200 with C; comment prefix "D".**

`BusinessLogic_D()` is a 4-line wrapper that calls `ForcePendingActionOrder()` (`:7692`) and `ForceDivergentWorking()` (`:8009`). It is essentially a delegate; D orders share `MagicCD` but are tagged with `D,` in their comment so `GetOrderTrendType` can split them out.

**Trigger / direction:** delegated to the helpers — `ForcePendingActionOrder` requires ADX-W dominance, ≥3 Force peaks <-9 (BUY) or 3+ peaks (SELL), WPR>85, Hull above bar 1, then opens with `2 * gLot * 0.7`. `ForceDivergentWorking` updates `IsForcePendingActionBuyOrder/SellOrder` flags based on Force divergence patterns.

**Exit:** no `ExtraTakeProfit_D`; D orders are closed via `ExtraTakeProfit_CD` (since they share magic).

**REVIEW:** D is an "invisible" strategy — its logic is buried in helpers, no separate magic. Likely a legacy split that was never cleaned up.

---

### 3.3 Slot J — Follower trade after C/D fractal

**Source:** `BusinessLogic_J @ :2374`, `ExtraTakeProfit_J @ :10882`. **Magic: 206.**

**Entry conditions (all AND):**
1. `BuyOrders__CD + SellOrders__CD ∈ [1,2]` — J only follows C/D.
2. `BuyOrders__J + SellOrders__J < 3`.
3. Fractal `[3]` exists matching direction (`FractalLowBuffer[3]` for BUY, `FractalUpBuffer[3]` for SELL).
4. ≥8 H4 bars since last C/D entry, AND ≥4 H4 bars since last J entry on same side.
5. Pip distance from C/D entry exceeds `JPip1StBetweenC=-10` or `JPip1StBetweenD=-13` thresholds (scaled `*2` if existing J).
6. If not following D, run a Force-divergence peak finder; if ≥3 peaks with `|F|≥8`, mark variant `DD`/`DA` for premium lot.

**Direction:** mirrors C/D (BUY follows BUY, SELL follows SELL).

**Order:**
- Base lot: `LastBuyLots2 * (JRatioDecrease/10) = LastBuyLots2 * 0.23`.
- Multipliers: `DD` 3.95×, `DA` 2×, `DNerve` 2.5× when LastOrderType2=="D" and pip diff>50.
- Penalty: `0.5×` if very close to C/D and no divergence.
- Order-count penalty: `(10-count)/10` if count>1.
- Comment: `"J," + LastOrderType2 + "," + variant("N"|"DD"|"DA")`
- Helper: `OpenOrderJ()`

**Exit (`ExtraTakeProfit_J`):**
> ⚠ **CRITICAL BUG `[REVIEW]`** — `:10882..:10897` iterates `MagicF` (=201) instead of `MagicJ`. So `ExtraTakeProfit_J` does **not** actually close J orders. They are likely closed by overall portfolio "safe-port" logic in `OrderGroupStartWorkflow`. If the function were corrected to `MagicJ`, the visible logic closes when D1 cloud edge is touched and `_accountProfit > 0`, plus a 10-day-old + WPR100 extreme exit.

---

### 3.4 Slot H — Fractal + Ichimoku-distance + ADX cross

**Source:** `BusinessLogic_H @ :2659`, `HGetLotSize @ :3466`, `HCheckFractalForce @ :3543`, `CheckValidDEM @ :3432`, `CheckValidPeakADXW @ :3454`, `ExtraTakeProfit_H @ :10961`. **Magic: 205.**

**Entry conditions (all AND):**
1. Max 2 H orders.
2. If a C pending exists, require `CountCOOrder < 2` (anti-cannibalism).
3. Same H4 bar cooldown.
4. If `≥3 C/D` orders open, require ≥20 pip distance from last C/D entry (`:2684`).
5. If H exists, ≥8 bars since last H.
6. `FractalPredicate(BUY)` or `FractalPredicate(SELL)` returns ≥0 (strong fractal bar 2 or 3).
7. D1 Ichimoku validation: bars 0..4 against cloud + MACD D1 trend; reject if (inside AND outside AND MACD flipped).
8. H4 Ichimoku distance ≤ 35 pips (`:2776`) AND fractal aligns vs. cloud edge.
9. WPR constraint: if both routing flags say "No", require `|WPR[1]| ∉ [80,20]`.
10. Nerve-lot trim: if C/D BUY active and H empty AND <20 pips AND ≤18 bars → `lot * 0.6`.
11. ADX cross validation (300-bar lookback) — reject if price has already broken past prior crossover.
12. Bollinger validation — count of bars where `BBTop < IchiMax`, require ≥1.

**Direction:** from `FractalPredicate` result (low fractal ⇒ BUY, high fractal ⇒ SELL).

**Order:**
- Lot via `HGetLotSize(hCheckFractalForce)`:
  - Base `CalculateLotSize(15, 90)` then scaled `0.1×..2.55×` based on `WPRWaveWithIchimokuSingal2`/`DontWPRWaveWithIchimokuSameside2` permutations.
  - Ban penalty: `BanCStartDate < 168` H1 bars ⇒ `0.4..0.5×`.
- Comment: `"H," + WPRWaveFlag[0] + "," + DontWPRFlag[0] + "," + WPR[1] + "," + hCheckFractalForce + ",2"`
- Helper: `OpenOrderH()`

**Exit (`ExtraTakeProfit_H`):** Profit gating + Ichimoku touch + WPR extremes (BUY: WPR[1]<10 OR WPR[0]<2 with WPR100[0]<76; SELL: mirror with 90/98/24). 50-pip drawdown guard if C-anchored.

**REVIEW:** hidden lot multiplier ladder with no comments; ADX 300-bar scan re-runs every tick; `hasCPendingOrder` global state has no visible setter near the read site; drawdown loop iterates from orderIndex back to 0 (slow).

---

### 3.5 Slot K — Force crossover with Ichimoku layer

**Source:** `BusinessLogic_K @ :3614`, `ExtraTakeProfit_K @ :11453`, `KExtra @ :7858`. **Magic: 207.**

**Entry conditions (all AND):**
1. If existing K order → delegate to `KExtra()`.
2. `iTime(D1, 0) > KLastOrderDate` (one K per day).
3. Force pattern: `isFICrossUp` = `(F[1]>0.5 ∧ F[2]>0 ∧ F[3]<-0.2)` OR `(F[1]>1 ∧ F[2]<-0.2)`. `isFICrossDw` = mirror.
4. Price outside cloud matches direction.
5. C-pending cooldown: 2-hour wait past H4 bar start if C-pending offset ∈ (0,44).
6. Ask within −10 pip tolerance of recent high (BUY) / low (SELL).
7. Force wave extent ≤3 bars AND >37 bars from start ⇒ `isFoceOverIchi` premium.
8. Tenkan/Kijun layer overlap analysis (`:3750..:3844`).

**Order:**
- Lot via `CalculateLotSize` (specific args not visible in excerpt).
- Comment: layered encode with Tenkan/Kijun layer ("R"/"M"/"B") + validation bools + composite metrics.
- Helper: `OpenOrderK()`

**Exit (`ExtraTakeProfit_K`):** Profit gate + cascading rules — fractal proximity, ≥20 pip profit + cloud touch, ≥4 bar age + ≥5 small-touch bars + cloud max, fractal-at-entry + half-SL DD limit.

**REVIEW:** Force thresholds `0.5/1.0/-0.2` are uncalibrated. K is single-order-per-direction by design — pyramiding handled in `KExtra`.

---

### 3.6 Slot G — Force crossover + ADX + Ichimoku wave

**Source:** `BusinessLogic_G @ :4978`, `ExtraTakeProfit_G @ :11844`, `ConflidentialTradeOnG @ :15116`. **Magic: 208.**

**Entry conditions (all AND):**
1. No active G orders.
2. Not in `GPauseDate` window (>31 H1 bars elapsed).
3. Not in NewYear blackout.
4. Force crossover: BUY = `(F[1]>0 ∧ F[2]>0 ∧ F[3]<-0.2)` OR `(F[1]>1 ∧ F[2]∈[-0.2,-3))`. SELL mirror.
5. Price outside Ichimoku cloud.
6. ADX H4 + Weekly: `IDXWMain > +DI ∧ IDXWMain > −DI`; no opposite cross within 300-bar lookback.
7. Stochastic M10[0] or [1] <25 (BUY) / >75 (SELL).
8. Ichimoku Senkou-26 valid (no premature span breach).
9. Force peaks not exhausted (≤3 prior >11 peaks within wave; extremum <±25).
10. WPR sanity: BUY rejects if `|WPR[1]|≤5 ∧ |WPR100[1]|≤10`. SELL mirror.
11. Bollinger band validation (15-bar scan for `BBTop<IchiMax`).
12. DeMarker thresholds: BUY pending if total ratio ≥175; SELL ≤25.
13. Force wave spans ≥3 bars with dominant opposite-polarity bars.

**Order:**
- Lot: `CalculateLotSize(30, slPipsAbsolute)`, `*0.7` if pending.
- Comment: `"G," + diff + "," + mode + "," + isIchi26Valid + "," + pendingFlag + "," + slPrice`.
- Helper: `OpenOrderG()` with internal `*0.6` extra reduction (`:16850`).
- SL: max(cloud edge, fractal level, 61.8 pip floor).

**Exit (`ExtraTakeProfit_G`):**
- Only on profitable positions.
- D-order detection (`isDOpenInside`) + ADX-weighted differential ≥7 + profit > 200 pips ⇒ close with reason "Close on D".
- Trail tracking via `maxProfitPIP`; close if current > max ∧ >50 pip ∧ Bollinger-band touch to cloud edge.
- Calls `ConflidentialTradeOnG` to read history of H/M/L closures and suppress GO if certain context exists.
- **Triggers GOverload (slot GO) on peak**: `IsClosePeakBuy` + `(Force>15 OR ADX>49)` + `maxOffset≥20` + `dontTradeGO==1` ⇒ `GOverload(SELL)`. Mirror for `IsClosePeakSell`.

---

### 3.7 Slot G2 — Smooth-trend gap-filler for G

**Source:** `BusinessLogic_G2 @ :5532`. **Magic: REUSES `MagicG=208` `[REVIEW]`.**

**Entry conditions (all AND):**
1. No active G or G2 orders.
2. Not NewYear.
3. Price outside cloud.
4. `Force[1] ∈ (0.2, 7)` — narrow positive momentum band (G's gap).
5. ADX-W not trapped between ±DI for bars 1..3.
6. ≥5 of last 8 bars have `Force>0.2`.
7. ≥5 of last 8 bars have low > cloud high (SELL bias).
8. No bar in last 10 with `open<lowMain`.
9. ≥1 bar in lookback 22 with both open AND close outside cloud (same side).
10. ≥1 bar in `[2,5)` with `Force ≤ -0.2` (reversal trough).
11. Latest `FractalUp > current bid` (resistance present).
12. Senkou-26 valid.
13. SL ≥ 61.8 pips to cloud edge.

**Order:** `CalculateLotSize(15, slPipsAbs) * 0.7`. Magic = `MagicG`. Comment `"G2," + diff + "," + (P|N)`.

**Exit:** inherits `ExtraTakeProfit_G` since magic is shared.

**REVIEW:** G2 is **NOT mutually exclusive from G** at the magic level — both can fire same bar. This is a code smell.

---

### 3.8 Slot GO — G-Overload reverse hedge

**Source:** `GOverload @ :9493`, `OpenOrderGO @ :16790`, `ExtraTakeProfit_GO @ :11186`. **Magic: 209.**

**Entry:** Triggered ONLY by `ExtraTakeProfit_G` peak detection (lines `:12714..:12741`), NOT independently. Inverse direction of the closing G order. Lot = `closeLotsize * (GORatioDecrease/10) = closeLotsize * 1.0` then `*0.9` in `OpenOrderGO`. Comment fixed `"G,O"`.

**Exit:** profitable orders only. SELL closes if `iLow[0]>highMain` reversion + max-profit trail (>50 pip + within 10 pip of cloud). BUY mirror. Filters on comment-type "G".

**REVIEW:** GO is hard-coupled to G — there is no independent "GO" signal. No cooldown timer; rapid G reversals can suppress GO.

---

### 3.9 Slot M — ADX-Wilder valley + WPR-Ichimoku alignment

**Source:** `BusinessLogic_M @ :5973`, `PendingM @ :6441`, `ExtraTakeProfit_M @ :12784`, `OpenOrderM @ :16738`. **Magic: 210.**

**Entry conditions (all AND):**
1. PendingM() runs first.
2. No active M orders.
3. `hasCPendingOrder` not blocking (`CountCOOrder<2`).
4. Not in M-ban (BanMStartDate < 36 H1 bars).
5. Price outside cloud.
6. Prior bar high-low spread <52 pips (volatility filter).
7. C-pending nerve trim if applicable (lot ×0.8).
8. Sustained alignment: ≥X of last 10 bars with `Force>0.2 ∧ low>highMain` (BUY mirror).
9. ALL of bars [0..6) with `IDXWMain > ±DI`.
10. ADX-W valley: `IDXW[0] < IDXW[1] ∧ IDXW[2] < IDXW[1]`.
11. No bar [1..4) with `|Force|>6` or `|WPR|>85 ∧ |WPR100|>85` (or both <15).
12. BUY also requires `Force[1]>0` micro-trend.

**Order:** `CalculateLotSize(percentTage, absSL)`, `*0.8` in OpenOrderM. Comment: `"M," + diff + "," + countBars + "," + countValid + "," + orderAction + "," + hullText`.

**PendingM:** Stores `MPendingAtPrice/RefPrice/Lot`; force-execute when (BUY) `(hullText=="H" ∧ WPR100>80 ∧ WPR<90 ∧ diffFromPending>60)` or `(hullText!="H" ∧ diffFromRef>70 ∧ diffFromPending>30)`. Adds 25% lot bonus on execute in "E" mode. Cleared when no M orders.

**Exit (`ExtraTakeProfit_M`):**
- "E" pending mode: close on >50 pip profit + WPR extreme.
- "CP" flag → cut whole M batch.
- Cloud touch (bar0 crossing).
- Trailing in "NN" state (≥6 bar age) — close if profit > 20% of entry-bar profit AND >40 pips.

---

### 3.10 Slot L — ADX-cross + cloud break (with LX add-on)

**Source:** `BusinessLogic_L @ :4060`, `BusinessLogic_LX @ :4824`, `ExtraTakeProfit_L @ :11284`. **Magic: 211.**

**Entry conditions (all AND):**
1. No active L orders.
2. No active orders in B/R/G slots (mutual exclusion).
3. L-ban check: `BanLStartDate` <48 H1 bars ⇒ block.
4. Bid outside cloud → BUY/SELL.
5. C-pending gate: if `hasCPendingOrder ∧ CPBarOffset<44` then require ask>recentHigh by ≥10..27 pips (deeper if high>9 bars away).
6. `IDXW[0/1] ≥ LADXMLevelMin (22)` AND `IDX[0/1] ≥ 22`.
7. If ADX ≤ `LADXMLevel (30)`, require opposite-slot orders (C/D/H/J/K) on same side.
8. `IDXW[0] > +DI ∧ IDXW[0] > −DI`.
9. ADX cross validation 300-bar lookback for both `IDX` and `IDXW`: reject if any cross occurs with bar high>highMain (BUY) / low<lowMain (SELL).

**Order:** Comment `"L,..."`, `CalculateLotSize(~20, slPips)`. Magic 211.

**LX add-on (`BusinessLogic_LX`)** — pyramids onto an L position once it has 25+ pip unrealized profit, gated by DeMarker: BUY needs `DEM[0]<0.59`, SELL needs `>0.41`. Comment `"LX," + percentTage`. Lot `CalculateLotSize(percentTage, slPips) * 0.7` capped at 12% remainder.

**Exit (`ExtraTakeProfit_L`):**
- Fractal-mid exit, WPR>93 + short-flag close, cloud-proximity (>50 pip + <4 pip to cloud), cloud touch (bar 1 LOW > highMain), trailing after 8 bars.

**REVIEW:** dual ADX-cross 300-bar scan is expensive and recomputed every tick (no caching). DeMarker thresholds 0.59/0.41 are uncalibrated. ADX-level conditional creates a fragile inter-slot dependency.

---

### 3.11 Slot Q — WPR-extreme pyramid via pending state

**Source:** `BusinessLogic_Q @ :6680`, `ExtraTakeProfit_Q @ :13075`, `OpenOrderQ @ :16688`. **Magic: 212.**

**Entry conditions:**
1. `QPendingCode > 0` (1, 2, or 3) — externally set state; cancels if price re-enters cloud.
2. WPR extremes: BUY needs `|WPR[1]|>95 ∧ |WPR100[1]|>95`. SELL needs both `<5`.
3. ADX-Wilder peak: `IDXW[1] > +DI ∧ IDXW[1] > −DI` AND `IDXW[2] − IDXW[4] ≥ 2` AND `IDXW[2] > 40`.
4. Pip distance from prior Q/D entry > 20 (or first order).
5. Cooldown: `pendingIndex ≥ 2` bars since last pending signal.

**Order:** Lot `QPendingLot + (QPendingLot/2)*existingOrders` (pyramid), `*0.8` in OpenOrderQ. Comment `"Q," + QPendingCode[,W]`.

**Exit:** Cloud-touch only. Profit gate. WPR neutral-zone exclusion (BUY: WPR[0/1] not in [0,10]; SELL: not in [80,90]).

**REVIEW:** QPendingCode==1 vs ==2 contain near-identical duplicated logic.

---

### 3.12 Slot R — Pending Bollinger-SL trade

**Source:** `BusinessLogic_R @ :7053`, `ExtraTakeProfit_R @ :13157`. **Magic: 213.**

**Entry (BUY pending — mirror for SELL):**
1. `RBuyOrderPendingDate > 0`.
2. Cancel if `bid<lowMain` or `pendingIndex>40`.
3. Either fractal-high in `[pendingIndex+1..pendingIndex+10)` OR Force peak (`F[i+1]<F[i] ∧ F[i-1]<F[i]`).
4. Any bar in `[pendingIndex..1]` with `|WPR|>70`.
5. All of last 26 bars below cloud + `SenkouSpanC[26]<highMain`.
6. Last 30 bars: low<BBBot OR open/close<IchiKijun (downtrend pressure).
7. `bid > _pendingPrice` OR `bid > realPendingPrice` AND `isIchi26Valid`.
8. SL = lowest BBBot in [1..bandIndex], min 50 pips, +10 pip buffer.

**Order:** `CalculateLotSize(20, slDiff)`. Comment encodes `"R," + diff + "," + isIchi26Valid + "," + diffSL + "," + isDemPeak2 + "," + slPrice`.

**Exit (`ExtraTakeProfit_R`):** Multi-condition with order-age tiers:
- D-zone exit (>200 pip).
- orderIndex>11 + cloud breach + low<BBBot.
- orderIndex>19 + Force<−12 + WPR>85 + ADX-W peak + sets `dontTradeGO`.
- G-order block (orderIndex 15..55 + SellOrders__G>0) → skip exit.
- Continuous cloud overlap exit.
- 45-bar timeout.

**REVIEW:** Comment-format bloat; 6 fields parsed by string position. `dontTradeGO` flag set but never consumed inside R itself — leaks to external logic. 298-bar Senkou loop is inefficient.

---

### 3.13 Slot I — G-parasite Fibonacci pyramid

**Source:** `BusinessLogic_I @ :7354`, `ExtraTakeProfit_I @ :12752`, `FractalPredicate @ :7407`. **Magic: 216.**

**Entry conditions:**
1. `(BuyOrders__G + SellOrders__G) > 0` (G must be open).
2. `(BuyOrders__I + SellOrders__I) == 0`.
3. G order tagged "P" (pending mode) per `GetOrderTrendType(OrderComment__G, 4)`.
4. ≥2 bars since G entry.

**Direction:** mirrors G order.

**Order:** Fibonacci ratio add: `LastGLots + LastGLots * (rangeOfSLPercentage * 0.618)`. Comment `"I,"`. SL=0.

**Exit:** `ExtraTakeProfit_I` closes I orders the moment G hits zero — no independent exit.

**REVIEW:** `FractalPredicate` is defined but never used by I (only by H). I has SL=0 → relies entirely on G's lifecycle. `0.618` is hardcoded.

---

### 3.14 Slot P — Multi-stage pending state machine

**Source:** `BusinessLogic_P @ :16992`, `BusinessLogic_P_Pending @ :17267`, `BusinessLogic_P_Extra @ :17778`, `ExtraTakeProfit_P @ :17971`. **Magic: 218.**

**Initial entry (BUY mirror for SELL):**
1. No active P, no pending P command.
2. `Force[1]>0.1`.
3. `IChiThisWaveStartBars(SELL) ∈ [18,99]` (recent counter-trend wave).
4. `GetCountPeakForce(start, 12, true) ≥ 3`.
5. `GetCountPeakWPR(start, 90, true) ≥ 2`.
6. Last upward fractal within 7 pips of bid.
7. No reverse closures with no opens in same period.
8. Hull[3..45]<cloud OR DEM[0..20]<0.5 (oversold structure).
9. SL = lowest_close(20) clamped by BBBot and lowMain.
10. `CalculateBollingerRatio(bid, top, bot)` >75 OR `_diffRealSL ≥ 150` ⇒ defer to pending.

**Pending evaluation (`BusinessLogic_P_Pending`):**
- 70-bar deadline.
- Variants:
  - **PX** = Force trigger within 8 bars OR `_diffSL≥200` OR `_diffSL≥250` with band gating.
  - **PH** = default if `_diffSL<200`.
  - Sub-variants set TP ratio 7 vs 15.
- Exit-pending if Bollinger zone violated.

**P_Extra (second-order pyramid):** `CalculateLotSize(8, slDiff)` (vs 15 for first), comment `"PI,..."`, "L"/"S" Hull-penetration tag.

**Exit:** B/G profit-conflict skip; PI orders close after 20 bars; PH closes after 20 bars on highest-ever threshold; PX closes on technical reversal.

**REVIEW:** State spread across 4 functions with no orchestrator. PPendingCommand string-comma format is brittle. Helper functions (`GetCountPeakForce`/`GetCountPeakWPR`/`CalculateBollingerRatio`) are not visible at top level.

---

### 3.15 Slot T — Hull/SubDem reversal with pending

**Source:** `BusinessLogic_T @ :18414`, `BusinessLogic_PendingT @ :18842`, `ExtraTakeProfit_T @ :19192`. **Magic: 219.**

**Entry (BUY support-zone path):**
1. No active T, no T pending (or delegate to PendingT).
2. Price within `SubDemCalcModelH4Support` zone AND `BollBand% < 5%` of range.
3. No active G/B/R sells.
4. Price > Hull MA.
5. ≥7 of last 10 bars with `BBTop < IchiMax`.
6. ADXW dominance check sets `adxwValidText="A"` or `"B"`.
7. DEM threshold 0.45 for "D" (day) pattern.
8. `SubDemStrength = ZONE_PROVEN` OR `zone_hit ≥ 2`.
9. SL = max(Hull migration, BBWidth, 90 pip floor).

SELL path mirror (resistance zone, BBBand >95%).

**Order:** `OpenOrder(type, "T", lot, 0, sl, comment)`. Lot 15% base, can drop to 0.5–10% under specific permutations. Comment encodes DEM, IsBUseNearCrossIchi, ZoneStrength, zone_hit, diffSL.

**Exit:** Closes profitable positions on cascade of Bollinger touches, ADX-W weakness, DEM cooling, pricePercentRange thresholds (10/15/20), pending-mode threshold checks.

**REVIEW:** Dead code blocks `:18570..:18578`, `:18765..:18773`. Lot sizing branches are sprawling.

---

### 3.16 Slot S — Wave-peak reversal after L/K close

**Source:** `BusinessLogic_S @ :19359`, `ExtraTakeProfit_S @ :19626`, `ExtraTakeProfit_ShortStrategy @ :11065`. **Magic: 217.**

**Entry conditions:**
1. No active S.
2. Lookback 70 bars; require prior L/K closure ≥33 bars ago.
3. **SELL** path (after a closed BUY from L/K):
   - `Low[1] > IchiMax ∧ Low[2] > IchiMax`
   - `bid < Ichi[20]`
   - ≥4 BBTop peak bounces in prior range
   - `bid > BBTop ∧ |WPR[1]|<10`
   - `DEM ≥ 0.7` OR `Force ≥ 12` in last 6/20 bars
   - Sets `percentTP` ∈ {5,10,15} based on which conditions hit.
4. BUY mirror.

**Order:** `CalculateLotSize(percentTP, diffBand)`, SL ≥90 pip. Comment `"S," + IsBUseNearCrossIchi + percentTP + diffTp`.

**Exit:** Profit gate, conflict-skip if B/G open, ≥80 pip on early bars, ≥20 bar age + BBBot break + cloud breach, G/B closed signal, profit-target match, trail after 20 bars + ever-best>100 pip.

---

### 3.17 Slot B — Anti-trend fractal + cloud distance

**Source:** `BusinessLogic_B @ :19844`, `RegisterB @ :19839`, `ExtraTakeProfit_B @ :20363` (~370 LOC, the largest exit). **Magic: 214.**

**Entry conditions (BUY when bid<lowMain):**
1. No active B.
2. **`!IsADXPeakValid`** — anti-trend (set by `CheckADXWithForcePeakValid2 :2291`).
3. ≤1 G/I sell.
4. Price-distance from cloud <180 pips.
5. Valid `FractalUp` in `[4..StartAwayFromIchiIndex)` matching bid/open conditions.
6. Fractal count <3.
7. ADXMain dominance <3 bars.
8. Ichimoku wave-start bar count valid.
9. ADX cross count <3.
10. SL = min(lowest bar in wave, BBBot, lowMain).
11. TP percentage = `20 + tpplus` where tpplus depends on SL-vs-cloud distance.

SELL mirror with FractalLow.

**Order:** Comment `"B," + diffRealSL + maxForce + IsBUseNearCrossIchi + StartAwayFromIchiIndex + fractalCount + countCrossADX + diffFractal`.

**Exit:** A nested cascade with ≥8 branches differentiated by `orderIndex` age, `diffMaxSL`, `diffFromSource`, ADX-W cross patterns, fractal proximity, and DEM/WPR M15 validation. Calls `BusinessLogic_BR` from inside an exit branch (`:20701..:20704`).

---

### 3.18 Slot BR — B-Reverse hedge (orphan)

**Source:** `BusinessLogic_BR @ :20105`, `ExtraTakeProfit_BR @ :21620`. **Magic: 215.**

> ⚠ `[REVIEW]` — `BusinessLogic_BR` is **not called from `OnTick()`**. It is invoked only from inside `ExtraTakeProfit_B` when a B order closes. This makes it a sub-strategy of B, not an independent slot.

**Entry:** Parameterised by caller — `br_mode ∈ {S,W,G,N}`, `type`, `bOrderIndex`, `BReverseOrderProfitB`. Each mode has its own SL formula and target percent (5..30%).

**Order:** Comment `"BR," + br_mode + slPoint + targetPercent`.

**Exit (`ExtraTakeProfit_BR`):** Minimal — `|WPR[1]|<5` close, cloud touch close. ~90 LOC.

---

### 3.19 Slot BI — B-Inner pyramid child

**Source:** `BusinessLogic_BI @ :20291`. **Magic: 214 (shares B).**

**Entry:**
1. Exactly 1 B position.
2. Drawdown >45 pips from first B price.
3. `LOW < IchiKijun ∧ LOW < BBMid`.
4. `BBBot > lowMain` OR `LOW < highMain`.
SELL mirror.

**Order:** Lot = **23.6% of parent B lot** (`0.236` is unexplained, possibly a Fibonacci-derived constant). Comment fixed `"B,I,"`. **`SL = 0`** `[REVIEW: CRITICAL — naked position]`.

**Exit:** Handled inside `ExtraTakeProfit_B` (force-close if `comment == "B,I,"` and parent B gone).

---

### 3.20 Slot U — DISABLED

**Source:** `BusinessLogic_U @ :21715`, `ExtraTakeProfit_U @ :21841`. **Magic: 220.**

> ⚠ Both calls are commented out in `OnTick()` at lines `:291` and `:322`. The implementation exists in full and would fire on `IsADXPeakValid==true ∧ StartAwayFromIchiIndex∈[9,99] ∧ ADX/RSI/DEM extreme combo`. Implication: dead code with full function bodies still being compiled.

---

### 3.21 ShortStrategy exit

`ExtraTakeProfit_ShortStrategy @ :11065` is a portfolio-level cleanup pass invoked from `OnTick()` exit phase. It is not tied to one slot and operates over multiple magic numbers.

> **AI Reconstruction Note (§3):** Each slot is essentially a decision tree over indicator-buffer values + a guard table over portfolio state (`BuyOrders__X`/`SellOrders__X`/`hasCPendingOrder`/`Ban*StartDate`/`IsADXPeakValid`/`WPRWaveWithIchimokuSingal2`). The cleanest way to rebuild is to (a) freeze the indicator vocabulary into a `MarketContext` snapshot at the top of each tick, (b) freeze portfolio state into a `PortfolioState` struct, then (c) implement each slot as a pure function `(MarketContext, PortfolioState) → Optional<EntryOrder>`. Exits should similarly be `(MarketContext, PortfolioState, ExistingOrder) → CloseAction`. The cross-slot dependencies (G→GO, G→I, B→BR, B→BI, J→C/D, S→L/K, T→pending, P→pending) should be modeled as explicit edges in a slot dependency graph.

---

## 💰 Section 4: Position & Risk Management

### 4.1 Position Sizing Logic

```
function CalculateLotSize(riskPercent, slPips):
    // Defined in LibCommon (not shown directly), conceptually:
    riskMoney = AccountBalance * (riskPercent / 100)
    pipValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * DigitMultipier
    lots      = riskMoney / (slPips * pipValue)
    return Clamp(lots, MinLot, MaxLot * LimitMaxLotSizeRatio)

function GetSizeLot2():
    base = AccountBalance / (MainRiskRatio * 10000)   // [MAGIC NUMBER 10000]
    return Clamp(base, SymbolInfoDouble(SYMBOL_VOLUME_MIN), SymbolInfoDouble(SYMBOL_VOLUME_MAX))

function CalculateRuntimeLots2(type):
    base = GetSizeLot2() + IncreasePoint2
    if CD_open(type):
        base += scaledExistingLots * 0.3
    return max(base, SymbolInfoDouble(SYMBOL_VOLUME_MIN))

function GetDLot(type, lotSize, &nerveType, &lotSizeContinue, &isSpecialNerve, diffGPIP):
    // Scans 300 bars for cloud cross
    // Counts |Force|>0.2 bars from cross
    // If ADXWilder fails but Force>4, applies 3x or 2x by WPR>99/95 at bars 1/2
    // Returns dynamically scaled D lot

function HGetLotSize(checkFractalForce):
    base = CalculateLotSize(15, 90)
    multiplier = lookup(WPRWaveWithIchimokuSingal2, DontWPRWaveWithIchimokuSameside2,
                        |WPR[1]|>=80 ?, checkFractalForce, TradeOnHNN)
    if BanCStartDate set AND <168 H1 bars: multiplier *= 0.4..0.5
    return max(base * multiplier, SymbolInfoDouble(SYMBOL_VOLUME_MIN))
```

Per-slot lot multipliers (effective base risk after `*0.6/*0.7/*0.8/*0.9` reductions in OpenOrder helpers):

| Slot | CalculateLotSize % | Helper trim | Effective % |
|---|---|---|---|
| C | 15% | (none) | ~15% × 1..2.5 (peak multiplier) |
| H | 15% (× 0.1..2.55) | OpenOrderH (none specified) | 1.5..38% |
| J | based on `LastBuyLots2 * 0.23` | OpenOrderJ | × 1..3.95 |
| K | base | OpenOrderK | base |
| G | 30% | OpenOrderG ×0.6 | 18% |
| G2 | 15% | ×0.7 | 10.5% |
| GO | closeLotsize ×1.0 | OpenOrderGO ×0.9 | 0.9× closing G size |
| L | ~20% | ×0.7 (LX) | 14% |
| LX | ≤12% | ×0.7 | ≤8.4% |
| M | computed | OpenOrderM ×0.8 | varies |
| Q | pyramided | OpenOrderQ ×0.8 | 80% of pyramid |
| R | 20% | OpenOrder ×0.7 (R flag) | 14% |
| B | 20+tpplus% | OpenOrder ×0.9 (B flag) | ~18% + tpplus |
| BR | 5..30% | OpenOrder ×0.8 (BR flag) | varies |
| BI | 23.6% of parent B | (none — direct OpenOrder) | 23.6% of B |
| I | LastGLots × (1+0.618×rangePct) | (direct OpenOrder) | varies |
| P | 15% (8% for P_Extra) | (direct OpenOrder) | 15% / 8% |
| T | 15% (drops to 0.5..10%) | (direct OpenOrder) | varies |
| S | percentTP ∈ {5,10,15} | (direct OpenOrder) | 5/10/15% |
| U | 15% | (direct OpenOrder) | inert |

### 4.2 Stop-Loss / Take-Profit Logic

| Slot | SL Method | TP Method |
|---|---|---|
| C/D | Implicit (managed by ExtraTakeProfit_CD) | Implicit (cloud-touch / Force decay / timeout) |
| J | Implicit (relies on CD pool exit) | Implicit |
| H | Implicit | WPR extremes + Ichimoku touch |
| K | Implicit | Profit + cloud-mid + fractal |
| G | Cloud edge / fractal / 61.8 pip floor | Trailing via maxProfitPIP + cloud touch |
| GO | Inherited from G | Trailing + cloud touch |
| L | Implicit (managed) | Multi-rule cascade |
| M | Implicit | Cloud touch + trailing in NN mode |
| Q | None (cloud-touch only) | Cloud touch in profit |
| R | BBBot/BBTop ± 10 pip (computed at entry) | Multi-tiered by orderIndex |
| B | min(wave low, BBBot, lowMain) | 20+tpplus% pseudo-TP, complex exit |
| BR | Mode-dependent (5..120 pip) | Mode-dependent |
| BI | **0 (NONE)** ⚠ | Auto-cut when parent B closes |
| I | **0** | Auto-cut when G closes |
| P | Lowest_close(20) ∩ BBBot ∩ lowMain | 300 pip base, scaled by Hull |
| T | max(Hull, BBWidth, 90 pip floor) | Implicit |
| S | ≥90 pip from BBand | Implicit |
| U | ±70 pip from cloud | Implicit (inert) |

| Trailing/BE | Pattern |
|---|---|
| Trailing | Ad-hoc per slot via "max profit reached + cloud touch" pattern (G, GO, M, S) |
| Breakeven | None implemented as a discrete state — implicit in profit gates |

### 4.3 Trade Filter Rules

```
TRADE_BLOCKED = TRUE if any:
  - SYMBOL_SPREAD > (10 * DigitMultipier) AND IsMondayMorningWakeup()       // OnTick :261
  - IsMorningWakeup() (00:00–00:05 UTC)                                     // :270
  - IsNewYearSeason2() AND CD == 0 (Dec 21 .. Jan 3)                        // :297
  - Slot-specific bans: BanCStartDate < 24 H1 bars (C)
                        BanLStartDate < 48 H1 bars (L)
                        BanMStartDate < 36 H1 bars (M)
                        KLastOrderDate same D1 bar (K)
                        GPauseDate < 31 H1 bars (G)
  - Force-pending older than 9 H4 bars                                      // :251
  - CircuitBreakerOrder triggered (micro-flip-flop same position <3000ms)   // :15796 → ExpertRemove

OrderGroupStartWorkflow "safe port" close-all triggers if:
  - weakOrderCount > 1
  - average bad-PIP > 55
  - currentProfit > 0
```

> **AI Reconstruction Note (§4):** The risk module is conceptually simple (`risk% × balance ÷ pipValue ÷ slPips`) but is **smeared across ~20 helper functions and 18 different `*Lots*` globals**. To rebuild cleanly, build a single `RiskManager` class that takes `(balance, equity, symbol, slPips, riskPct, lotMultipliers...)` and returns a final lot. All slot-specific multipliers should be tabulated in a config struct, NOT scattered across `OpenOrderX` helpers. Replace the 18 per-slot `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` global families with a single `Map<MagicId, SlotState>` updated once per tick by `ReadTradeData`.

---

## 🔧 Section 5: Function Reference (selected)

### 5.1 Lifecycle

#### `OnInit()` — `:77`
| Field | Detail |
|---|---|
| Purpose | Create indicator handles, init DB file, restore state |
| Side effects | All `*Handle` globals; `DigitMultipier`; per-slot ratios reset; `LoadGlobal` invoked |
| Notes | No validation of `iCustom` handle return values `[REVIEW]` — failure leaves `INVALID_HANDLE` and `CopyBuffer` will silently fail in `TickLoadBuffer`. |

#### `OnTick()` — `:202`
| Field | Detail |
|---|---|
| Purpose | The entire trading pipeline (see §2.2) |
| Notes | No re-entrancy guard; assumes broker honors single-thread tick delivery. |

#### `OnDeinit(reason)` — `:193`
| Field | Detail |
|---|---|
| Purpose | Print worst DD, kill timer (timer never set) |
| Notes | Does NOT persist final state — relies on `SaveFileDatabase` from last tick. Edge case: crash mid-tick = silent state loss. |

### 5.2 Signal helpers

#### `CheckForce(type, fValue)` — `:8729`
Returns `true` if Force[0] is opposite-sign to type AND `|Force[0]| ≤ |Force[1]|` AND `|Force[1]| > fValue`. Has a per-H1 bar gate (`BarH1CheckForce`).

#### `IChiThisWaveStartBars(type)` — `LibCommon:119`
Scans up to 300 H4 bars; returns first bar index where price has crossed back through the Ichimoku cloud edge in `type`'s direction.

#### `IChiLastWaveMaxBars(type)` — `:8821`
Identifies the previous wave extremum by tracking `_isDown` toggles; returns max wave length.

#### `CheckGapFromIchi(type, startBars)` — `:8755`
Confirms the price has departed from the cloud at some bar between 0..startBars; returns true if gap exists.

#### `CheckForceWaveMaxValue(startBars)` — `:8795`
Validates that the Force amplitude inside the start..backLimit window is bounded.

#### `CheckForceAlreadyCompleteAtStartWave(type, startIndex, limit)` — `:8677`
Returns true if Force has already hit ±12 within the start..limit window (signal already used).

#### `RunCheckWPRWaveWithIchimoku2()` — `:14252`
Sets the global strings `WPRWaveWithIchimokuSingal2` and `DontWPRWaveWithIchimokuSameside2` to "Yes"/"No" based on the prior 300-bar history of WPR vs Ichimoku.

#### `CheckIchimokuWaveWithPrice(type, &pLowPIP, &pHighPIP, &currDiffPIP, &bars)` — `:14351`
Outputs cumulative PIP ranges and applies multiplier scaling (e.g. `0.3×` or `forceNerveLot`) to entry lot.

#### `RatioPriceSubDem(type)` / `RatioPriceSubDemD(type)` — `:21977 / :21998`
Map current bid/ask to a 0..100% percentage between `SubDemCalcModelH4Resist/Support` (or D1) hi/lo bounds. Used by T and B slots.

#### `FindCP()` — `:1660`
Locates the most-recent C/D pending anchor; sets `CPBarOffset`, `CPOrderOffset`, `CountCOOrder`, `hasCPendingOrder`.

#### `CheckADXWithForcePeakValid2()` — `:2291`
Sets the cross-slot flag `IsADXPeakValid` and `StartAwayFromIchiIndex`. Used by B (anti-trend) and U (with-trend).

### 5.3 Order helpers

#### `OpenOrder(type, flag, lot, tp, sl, comment)` — `:15620`
Generic dispatcher. The `flag` parameter ("B", "BR", "R", "S", "T", "P", "BI", ...) selects per-slot lot reduction (`×0.9`/`×0.8`/`×0.7`), magic number, and TP/SL handling. Eventually calls `useServerFill` then `CTrade.OrderSend`.

#### `OpenOrderCD(type, lotSize, comment, isFOff=false)` — `:14185`
Specialized CD opener; clears force-pending flags; chains `BusinessLogic_F` if `isFOff==false`.

#### `useServerFill(server_fill_type, preferred)` — `:15610`
Reads `SYMBOL_FILLING_MODE` and returns the most permissive fill enum the broker supports (FOK > IOC > preferred).

#### `CloseAllPositions(type, magic, reason, exceptComment="")` — `:15412`
Loops `PositionsTotal()`, closes all matching `(magic, type)` via `TradeClosePosition`. Optional comment exclusion filter.

#### `TradeClosePosition(ticket)` — `:15364`
Atomic `CTrade.PositionClose(ticket)`, returns success bool.

### 5.4 State / persistence

#### `LoadGlobal()` — `:132`
Reads dozens of GlobalVariable + DB.txt key/values into in-memory state. Skips network calls in tester mode.

#### `LoadLibOrder(name)` — `:15107`
Restores `KLastOrderDate`, `BanCStartDate`, `BanLStartDate`, `BanMStartDate` from GlobalVariable.

#### `MyGlobalVariableSet(key, value)` — `LibDatabase`
Wrapper around `GlobalVariableSet`; no-op in tester/visual mode.

#### `ReadFileDatabase()` / `SaveFileDatabase()` — `LibDatabase`
Read/write `<login>_DB.txt` (key=value, one per line).

#### `WatchProfits(EAName)` — `LibMonitor :22`
Computes `current_profit_percentage = (equity/StartupEquity − 1) × 100`. Logs when DD ≤ −20%. Updates `worst_drawdown_percentage`.

### 5.5 Cross-slot housekeeping

#### `OrderGroupStartWorkflow()` — `:328`
The "Safe port" cleanup. If 2+ "weak" orders open AND average bad-PIP excursion of weak orders >55 pips AND combined profit >0, closes ALL weak slots (CD, J, H, K, L, M, Q, GO, T, S). `[REVIEW]` Bulk action with no per-slot opt-out.

#### `OrderGroupStartWorkflow2()` — `:512`
Similar but uses an Ichimoku double-bounce + Force confirmation pattern.

#### `CircuitBreakerOrder()` — `:15796`
Detects ping-pong (same position re-opens within 3000ms) → `ExpertRemove()`.

#### `ForceCutloss()` — `:9009`
CD-only loss-cap; uses Stochastic M10 and MACD D1 to decide when to force-cut.

#### `EOverload(type, index, lotSize)` — `:9395`
Adds an extra CD order on a peak-reversion (WPR>90 OR Force<−11/−12 + ≥33 pip last gap), reduced by `InteruptRatioDecrease`.

#### `COverload(type, index, lotSize)` — `:9277`
Cuts CD size on repeated MACD same-sign losses (≥7 bars) under weak ADXW.

#### `GOverload(type, lotSize)` — `:9493`
Opens a GO order on the inverse direction of a closing G order (called from `ExtraTakeProfit_G`).

---

## 🔍 Section 6: Known Issues & Review Points

### 6.1 Magic Numbers (must be parameterized)

| Location | Value | Purpose | Action |
|---|---|---|---|
| `:14 NormalTakeProfitPIP` | 48 | C/D base TP distance | → `input int InpNormalTpPip = 48;` |
| `:15 hour13` (LibCommon) | 46800 | C cooldown | → constant |
| `:23 InteruptRatioDecrease` | 8 | EOverload divisor | → input |
| `:24 MainOverloadRatioDecrease` | 4 | overload divisor | → input |
| `:28 FIDValue` | 21 | Force Index period | → input |
| `:31 LADXMLevel/Min` | 30/22 | L slot ADX gate | → input |
| `:33-34 JPip1StBetweenC/D` | -10/-13 | J pip gap | → input |
| `:35-39 *RatioDecrease` | 1/2.3/10/10/10 | per-slot lot ratios | → struct of inputs |
| `:40 GRisk` | 15 | G risk % | → input |
| `:849 :871 100` | 100 | "below cloud by 100 pip" check in C | → `input int InpCNearCloudPip = 100;` |
| `:863 :884 0.75` | 0.75 | wave-history threshold | → input |
| `:892 0.27` | 0.27 | wave length heuristic | → input |
| `:924 fValue=11` | 11 | C Force threshold | → input |
| `:1050-1078 1.24..2.5` | 1.24..2.5 | C peak multipliers | → table input |
| `:1815 8` | 8 bars | PendingC timeout | → input |
| `:2182 30` | 30 bars | PendingC_ADX timeout | → input |
| `:1911 0.618` | Fibonacci | PendingC mult | → input |
| `:1918 3.0` | unknown | PendingC mult | → input |
| `:1935 51.82` | unknown | PendingC divisor | → input |
| `:2776 35` | 35 pip | H Ichimoku distance | → input |
| `:3627-3635 0.5/1/-0.2/0.2` | Force thresholds | K signal | → input table |
| `:3653 hour2` | 2h | K post-C cooldown | → input |
| `:4078 48` | 48 H1 bars | L ban duration | → input |
| `:4129 LADXMLevelMin` | 22 | L ADX floor | (already a global) |
| `:5000 et seq Force triggers` | 0/1/-0.2 | G triggers | → input |
| `:5995-6024 52` | 52 pip | M volatility filter | → input |
| `:6680ff QPendingCode` | manual codes | Q state | → enum input |
| `:7099 7 pip` | 7 | P fractal proximity | → input |
| `:7128 75/150` | thresholds | P pending defer | → input |
| `:7407 0.618` | Fibonacci | I Fibonacci | → input |
| `:11003 :11034 50` | 50 pip | H DD guard | → input |
| `:18414ff DEM 0.45/0.59/0.7` | thresholds | T DEM gates | → input |
| `:20305 45 pip` | 45 | BI drawdown trigger | → input |
| `:20324 0.236` | Fibonacci | BI lot ratio | → input |
| `:21777 60` | adxFml threshold | U ADX gate | → input |
| `OpenOrder lot trims 0.6/0.7/0.8/0.9` | per-slot | per-slot risk multiplier | → input table |

### 6.2 Logic Issues / Anti-patterns

| Issue | Location | Risk | Description |
|---|---|---|---|
| `[REVIEW]` ExtraTakeProfit_J iterates wrong magic | `:10897` | **HIGH** | Function processes `MagicF` (=201) instead of `MagicJ` (=206). J orders never get exit-managed by their own function. Likely a copy-paste bug. |
| `[REVIEW]` BI orders open with `SL=0` | `:20326 :20357` | **CRITICAL** | Pyramid-child of B has no stop-loss. Naked exposure. |
| `[REVIEW]` G2 shares `MagicG` with G | `:5692` | High | Two slots can fire same bar with no mutual exclusion. |
| `[REVIEW]` BI shares `MagicB` with B | `:20326` | Medium | Comment-string parsing is the only differentiator → fragile. |
| `[REVIEW]` Slot U is dead code | `:291 :322` | Medium | Full implementation present but commented out at call sites. |
| `[REVIEW]` Slot D is invisible | `:2368` | Medium | 4-line wrapper around helpers; no separate magic. Hard to audit. |
| `[REVIEW]` BR orphan function | `:20105` | Medium | Never called from `OnTick`; only invoked from `ExtraTakeProfit_B` exit branch. Hidden dependency. |
| `[REVIEW]` No `input` parameters anywhere | EA-wide | **HIGH** | User cannot tune the EA without recompiling. |
| `[REVIEW]` Comment string is the only state schema | EA-wide | High | Slot variants encoded as comma-separated fields parsed by `GetOrderTrendType(comment, n)`. Brittle to format drift. |
| `[REVIEW]` 300-bar scans every tick | `:4164 :7115 :13157` | Medium | Several functions re-scan 298–300 bars on every tick with no caching. |
| `[REVIEW]` Pending state in flat key=value file | DB.txt | Medium | All pending state machines persist to one text file with no schema/atomicity. |
| `[REVIEW]` `hasCPendingOrder` global lacks visible setter | `:2664` | Medium | Read by H but no clear write site nearby. |
| `[REVIEW]` `CircuitBreakerOrder` calls `ExpertRemove()` | `:15796` | Medium | Hard kill of the EA with no operator notification. |
| `[REVIEW]` `OrderGroupStartWorkflow` bulk-closes 10 slots | `:328` | Medium | A single `avg badPIP > 55` triggers a "safe port" close-all of weak slots. No per-slot opt-out. |
| `[REVIEW]` Indicator handles never validated | `:86..:113` | Medium | If `iCustom` returns `INVALID_HANDLE`, `CopyBuffer` silently fails and signal logic uses stale buffer arrays. |
| `[REVIEW]` Drawdown-from-orderIndex loops | `:10998` | Low | Inner loops iterate from order's open bar to bar 0 — slow as orders age. |

### 6.3 Missing Features / Gaps

| Gap | Impact | Notes |
|---|---|---|
| No slippage control | Medium | `CTrade` is used at default slippage. Live performance can drift from backtest. |
| No news filter | Medium | High-impact news isn't filtered. |
| No symbol whitelist | High | The EA is hardcoded to operate on `_Symbol` of the chart only — multi-symbol portfolio impossible. |
| No structured logging | Medium | All diagnostics are bare `Print()` calls. |
| No unit tests | Medium | The mq5 ecosystem makes them hard, but the slot logic is pure-functional and could be testable. |
| No partial-close | Low | Can't book partial profit. |
| No re-entrancy / mutex protection | Low | Relies on single-threaded broker tick delivery. |
| No equity/balance protection switch | Medium | Drawdown is observed but not enforced (no kill at −X%). |

---

## 🚀 Section 7: Improvement Roadmap

### 7.1 Quick Wins

- [ ] Convert all globals in §1.3 + §6.1 into `input` parameters (single biggest leverage point).
- [ ] Fix `ExtraTakeProfit_J` bug — change `MagicF` → `MagicJ` (`:10897`).
- [ ] Add explicit SL to BI orders (`:20326`, `:20357`).
- [ ] Validate all `iCustom` handle returns in `OnInit`.
- [ ] Add equity-floor circuit breaker (close all + halt at user-defined `MaxDrawdownPct`).
- [ ] Cache 300-bar scan results in `OnTick` until next H4 bar close.
- [ ] Add `SymbolWhitelist[]` input check in `OnInit`.
- [ ] Replace `Print()` with a tagged logger that prepends `[slot=X][ev=...]`.
- [ ] Delete or revive Slot U — don't ship dead code.

### 7.2 Architecture Improvements

- [ ] **Slot interface**: introduce a `Slot` abstract class with `magic()`, `name()`, `evaluate(MarketContext, PortfolioState)`, `manageExits(...)`. Replace each pair of `BusinessLogic_X` + `ExtraTakeProfit_X` with one concrete subclass.
- [ ] **MarketContext snapshot**: at the top of each tick, build one struct that holds all relevant indicator values. Stops the ad-hoc reads from giant arrays.
- [ ] **PortfolioState**: replace the `BuyOrders__X / SellOrders__X / *Lots / *Profit / *Date` global swarm with `Map<int magic, SlotState>` populated once per tick by `ReadTradeData`.
- [ ] **PendingState manager**: collapse all per-slot pending state into one `Map<SlotId, PendingTicket>` persisted as JSON.
- [ ] **RiskManager class**: centralize lot calculation; tabulate per-slot multipliers in a config struct.
- [ ] **Decouple G→GO, B→BR/BI, J→C/D, S→L/K**: model these as explicit `Slot::dependsOn(otherSlot)` edges; the orchestrator runs them in topo order.
- [ ] **Split the file**: 22k LOC in one .mq5 is unmaintainable. Split into one include per slot.
- [ ] **Backtest harness**: add a parameter optimization sweep config for the ~80 magic numbers that should become inputs.

### 7.3 Feature Extensions

- [ ] Multi-symbol portfolio (one EA instance manages multiple symbols).
- [ ] Walk-forward optimization interface.
- [ ] Real-time dashboard panel showing per-slot exposure, profit, pending state.
- [ ] Web-hook notifications on slot entries/exits.
- [ ] News-filter integration (e.g. ForexFactory).
- [ ] Replace text-file persistence with sqlite.
- [ ] Telemetry/OTel-style structured logging to a sidecar.

### 7.4 AI Continuation Prompt

```
Read the Phoenicis-n Code Wiki at MQL5/Experts/PhoenicisN2.10_CodeWiki.md
and implement <feature X> by:
  1. Following the slot architecture in §2 (do not introduce new event handlers)
  2. Honoring the entry-vs-exit pass ordering
  3. Reusing the indicator buffers listed in §1.4
  4. If touching a slot, preserving its Magic number from §1.5
  5. NOT changing any of the cross-slot dependencies in §3 (G→GO, B→BR/BI, J→C/D, etc)
  6. Adding any new magic constants as input parameters per §6.1 conventions
```

---

## ✅ Section 8: Reconstruction Checklist

**Core Logic**
- [ ] Slot C entry: Ichimoku cloud break + Force triple-peak + 9 chained gates
- [ ] Slot D entry: ForcePendingActionOrder + ForceDivergentWorking helpers
- [ ] Slot J entry: follow C/D within [1,2] orders + fractal[3] + pip gap + DD/DA divergence variants
- [ ] Slot H entry: fractal + ≤35 pip cloud distance + ADX cross + WPR band + lot multiplier ladder
- [ ] Slot K entry: Force crossover (0.5/1/-0.2) + Ichimoku layer overlap
- [ ] Slot G entry: Force crossover + ADX-W dominance + Stochastic M10 + Senkou-26
- [ ] Slot G2 entry: smooth Force band (0.2..7) + bar-distribution check
- [ ] Slot GO entry: triggered from G exit only, inverse direction
- [ ] Slot M entry: ADX-W valley + WPR-Ichimoku alignment + volatility filter
- [ ] Slot L entry: ADX cross + cloud break + C-pending gate + slot exclusion
- [ ] Slot LX entry: pyramid on profitable L + DEM gate
- [ ] Slot Q entry: QPendingCode state + WPR extremes + ADX-W peak
- [ ] Slot R entry: pending Bollinger SL + 26-bar Senkou validity
- [ ] Slot I entry: G-parasite Fibonacci ratio
- [ ] Slot P entry: 18-99 bar Ichi wave + Force/WPR peaks + Hull/DEM
- [ ] Slot T entry: SubDem zone + Hull + Bollinger band-percent
- [ ] Slot S entry: post-L/K-close wave-peak reversal
- [ ] Slot B entry: anti-trend (`!IsADXPeakValid`) fractal
- [ ] Slot BI entry: pyramid B at 23.6% lot, no SL
- [ ] Slot BR entry: parameterized hedge from B exit
- [ ] Slot U: DISABLED (preserve commented-out call sites)

**Exits**
- [ ] Each slot has either its own ExtraTakeProfit_X function OR shares one with another slot (CD ←→ D, B ← BI/BR, G ← GO?)
- [ ] Fix MagicF/MagicJ bug in ExtraTakeProfit_J before reconstruction
- [ ] Cross-slot bulk exits: OrderGroupStartWorkflow + OrderGroupStartWorkflow2 + ForceCutloss + ExtraTakeProfit_ShortStrategy

**Risk Management**
- [ ] CalculateLotSize / GetSizeLot2 / GetDLot / HGetLotSize implemented
- [ ] Per-slot lot multipliers in §4.1 honored
- [ ] LimitMaxLotSizeRatio cap enforced
- [ ] Time filters: IsMorningWakeup, IsMondayMorningWakeup, IsNewYearSeason2
- [ ] Spread guard at OnTick start
- [ ] CircuitBreakerOrder ping-pong protection
- [ ] WatchProfits drawdown bookkeeping

**Operational**
- [ ] OnInit creates ALL ~30 indicator handles AND validates them
- [ ] LoadGlobal restores ~30 state vars from GlobalVariable + DB.txt
- [ ] SaveFileDatabase runs at end of every tick
- [ ] PortfolioState (BuyOrders__X et al) refreshed at start of every tick
- [ ] Indicator buffers refreshed at start of every tick (TickLoadBuffer)
- [ ] Exit pass runs BEFORE entry pass
- [ ] Logging via `Print()` (or improved logger)

**Parameters**
- [ ] ALL ~80 magic numbers in §6.1 converted to inputs
- [ ] Default values match the current globals 1:1 for backtest reproducibility
- [ ] OnInit validates `MainRiskRatio > 0`, `LimitMaxLotSizeRatio > 0`, etc.
- [ ] Symbol whitelist input added

---

> **End of Wiki — for delta updates, bump Wiki Version and document the change in a Section 9 changelog when modifying.**
