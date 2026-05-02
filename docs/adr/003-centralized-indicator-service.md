# ADR-003 — Centralized IndicatorService (Handle Owner)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G1, G3, G4, FR-2.6, FR-7.6, FR-8.1, NFR-3.2 |

## Context

EA เดิมเรียก `iCustom`, `iIchimoku`, `iMACD`, ฯลฯ กระจายตลอด 22k LOC; ~30 indicator handles ถูกสร้างใน OnInit (CodeWiki §1.4) แต่ **ไม่มี validation** ของ INVALID_HANDLE → silent failure (CodeWiki §6.2 P1.8). FR-2.6 ต้องการ "indicator query เกิดครั้งเดียวต่อ tick + ทุก slot อ่านจาก snapshot เดียวกัน". FR-7.6 ต้องการ fail-fast ตอน OnInit ถ้ามี handle invalid. FR-8.1 ต้องการ cache 300-bar scan จนถึง bar close

ต้องตัดสินใจ: ใครเป็น **owner** ของ handle lifecycle + ใครเป็น **producer** ของ MarketContext snapshot

## Options Considered

### Option A — Centralized `CIndicatorService` (chosen)

Service เดียวเป็น owner ของทุก handle:
- `OnInit()` → `IndicatorService::CreateHandles()` สร้าง ~25 handles + validate ทุกตัว; reject load ถ้ามี INVALID_HANDLE (FR-7.6)
- `OnTick()` → `IndicatorService::Refresh()` เรียก `CopyBuffer` ของทุก handle ลง internal arrays
- `MarketContextBuilder::Build(ctx)` ดึงค่าจาก `IndicatorService` ใส่ struct `MarketContext` (immutable per-tick — ดู ADR-004)
- 300-bar scan helpers (`IChiThisWaveStartBars`, `CheckGapFromIchi`, `CheckForceWaveMaxValue`) cache ผ่าน `IndicatorService::CachedScan(key)` ที่ invalidate ตอน new H4 bar (FR-8.1)

### Option B — Per-slot indicator ownership

Slot สร้าง handle เอง + อ่านเอง

**Rejected:** Duplication (slot G + slot K ต่างเรียก `iIchimoku` พร้อม identical params = 2 handles); ไม่มี single point of fail-fast validation; ทำ FR-2.6 (snapshot consistency) ไม่ได้

### Option C — Distributed ownership: `IndicatorRegistry` static class

Static state, no instance — slot register ตอน startup

**Rejected:** Static state = global swarm pattern เหมือนเดิม; ขัด ADR-002 constructor injection discipline

## Decision

เลือก **Option A — `CIndicatorService` instance** ที่ orchestrator inject ลง slot ผ่าน constructor

**API ที่ commit:**
- `bool CreateHandles()` — call จาก OnInit; return false ถ้ามี INVALID_HANDLE → orchestrator return INIT_FAILED (FR-7.6 / NFR-3.2)
- `void Refresh()` — call ครั้งเดียวที่ OnTick start; populate internal cache + bump tick counter
- `MarketContext BuildSnapshot() const` — สร้าง immutable snapshot (ADR-004)
- `T CachedScan<T>(string key, T (*fn)(...))` — cache wrapper สำหรับ 300-bar scan (FR-8.1); invalidate ตอน `Refresh()` ถ้า new H4 bar
- `void ReleaseHandles()` — call จาก OnDeinit; เรียก `IndicatorRelease` ทุกตัว

**Concrete handle inventory** (ครอบคลุม CodeWiki §1.4):

| Indicator | Timeframes | Used by slots | Handle count |
|-----------|------------|---------------|---------------|
| Ichimoku | H4, D1 | C, D, F, J, H, K, G, GO, M, L, LX, Q, R, B, BR, BI, P, T, S | 2 |
| Force | H4 | C, J, G, GO, M, L, B, P | 1 |
| ADX | H4, D1 | C, K, G | 2 |
| WPR | H4, D1, M15 | C, H, L, S | 3 |
| Bollinger | H4 | R, B, BR, BI, P, T, S | 1 |
| DeMarker | H4, M15 | LX, M | 2 |
| Stochastic | M10, H4 | C (ForceCutloss), L | 2 |
| MACD | M10, D1 | C (ForceCutloss, COverload) | 2 |
| RSI | H4 | helpers | 1 |
| Hull MA | H4 | T, P | 1 |
| Fractals | H4 | G, K | 1 |
| ZigZag | M5 | wave detection | 1 |
| SubDem (custom) | H4, D1 | DrawProfitTags visual | 2 |
| **Total (estimate)** | | | **~25 handles** (sum ของ 13 entries = 21 handles ที่ unique-per-indicator-param; ~4 เพิ่มเติม coming from slots ที่ต้องการ different period/applied_price ของ indicator เดียวกัน) |

> **SD-locked estimate:** **~25 handles** (รวม base 21 จาก table + ~4 expected เพิ่มเติม per-slot params variant) — ทุก doc + log message + monitoring signal ใช้ตัวเลขนี้
> **TD spike trigger (Phase 1D):** ตอน implement IMPL-005 ต้องอ่าน CodeWiki §1.4 + per-slot signal logic แล้ว lock **exact count** (อาจอยู่ในช่วง 23-27); ถ้า exact count เกิน 30 → revisit ADR-003 + update ทุก doc ที่อ้าง "~25 handles"

## Consequences

**Positive**
- Single point of fail-fast — OnInit return INIT_FAILED ทันทีถ้ามี INVALID_HANDLE → ผ่าน NFR-3.2 (100% rejection)
- ทุก slot อ่าน MarketContext เดียวกันใน tick → ไม่มี race condition ของ indicator update ระหว่าง slot evaluate
- 300-bar scan cache ลด CPU ตาม FR-8.1; invalidation logic อยู่ที่ service เดียว → testable

**Negative / trade-off**
- Orchestrator ต้อง wire IndicatorService ก่อนสร้าง slot — order ของ OnInit สำคัญ (ดู F5)
- ถ้า indicator handle leak (forgot release) = MT5 memory growth — mitigated โดย `ReleaseHandles()` ใน OnDeinit + reviewer checklist
- Single-instance service = bottleneck ถ้า slot run parallel — N/A เพราะ MQL5 single-thread tick (BR-9.2)

## Revisit-when

- ถ้า Phase 2 introduce multi-timeframe slot (M5, M1) → revisit handle inventory + buffer size
- ถ้า measured handle creation time > 500 ms ใน OnInit (ผู้ใช้รู้สึกช้าตอน attach) → revisit lazy handle creation
- ถ้า TD spike Phase 1D (IMPL-005) measure exact count > 30 → revisit ADR-003 (เพิ่ม buffer/cache budget) + update "~25 handles" reference ทุก doc
