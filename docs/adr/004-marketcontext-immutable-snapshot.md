# ADR-004 — MarketContext as Immutable Per-Tick Snapshot

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G3, FR-2.6, AC-2.6.1, AC-2.6.2 |

## Context

FR-2.6 ระบุว่า indicator value ทั้งหมดต้อง build "ครั้งเดียวต่อ tick + ทุก slot อ่านจาก snapshot เดียวกัน". AC-2.6.2 บังคับว่า slot **ห้ามอ่านจาก global array โดยตรง** — ต้องอ่านจาก snapshot ที่ orchestrator pass มา. EA เดิมอ่าน `IchimokuBufferA[1]`, `ForceBuffer[2]` กระจาย → slot อาจอ่านค่าต่างกันใน tick เดียว ถ้า indicator update ระหว่าง slot evaluate (CodeWiki §7.2 mentions this risk)

คำถาม: snapshot มี shape อย่างไร + mutability semantic อย่างไร

## Options Considered

### Option A — `struct MarketContext` immutable per-tick (chosen)

```mql5
struct MarketContext {
   datetime tick_time;             // broker server time
   double   bid, ask, spread_pip;
   int      bar_index_h4;          // current H4 bar number

   // Ichimoku H4
   double ichi_h4_tenkan[3], ichi_h4_kijun[3];
   double ichi_h4_senkouA[3], ichi_h4_senkouB[3], ichi_h4_chikou[3];
   double ichi_h4_cloud_high, ichi_h4_cloud_low;

   // Ichimoku D1 (subset slots)
   double ichi_d1_tenkan, ichi_d1_kijun, ichi_d1_senkouA, ichi_d1_senkouB;

   // Force, ADX, WPR, Bollinger, DeMarker, Stochastic, MACD, Hull, Fractal, ZigZag, SubDem ...
   // (concrete field list = TD lock ใน Phase 1D — schema spec ใน docs/api-specs/marketcontext-snapshot-schema.yaml)

   // Derived signals (cached compute ที่ทุก slot ใช้)
   bool   wpr_wave_signal;         // RunCheckWPRWaveWithIchimoku2 result
   bool   adx_force_peak_valid;    // CheckADXWithForcePeakValid2 result
};
```

- Build ครั้งเดียวที่ OnTick start ผ่าน `MarketContextBuilder::Build(IndicatorService&)` 
- Pass ลง slot ผ่าน `Evaluate(const MarketContext &ctx, ...)` — `const` reference enforce read-only
- ตอน new tick → struct ถูก rebuild + ทับ; slot ที่อ่านระหว่าง tick เดียวเห็นค่าเดียวกันแน่นอน

### Option B — Mutable shared object ที่ slot อ่าน-เขียนได้

**Rejected:** Cross-slot interference; AC-2.6.2 บังคับ slot read-only ของ snapshot — mutable ก็จะมี bug ที่ slot ก่อนหน้า "พิษ" snapshot สำหรับ slot ถัดไป

### Option C — Lazy-evaluated wrapper (slot pull from service on-demand)

`MarketContext` เป็น proxy object; ทุกครั้งที่ slot อ่าน field → call IndicatorService

**Rejected:** ขัด AC-2.6.2 invariant (snapshot ใน tick เดียวต้องเหมือนกัน — lazy evaluate อาจคืน fresh value ถ้า indicator update ระหว่าง slot)

## Decision

เลือก **Option A — `struct MarketContext` ที่ build ครั้งเดียว + pass `const` reference ลง slot**

**Concrete contract:**
- Builder method: `MarketContext MarketContextBuilder::Build(const IndicatorService &svc)` — pure function ของ indicator buffers ปัจจุบัน
- Slot signature: `void CSlotBase::Evaluate(const MarketContext &ctx, PortfolioState &port)` — ctx = const ref; port = mutable ref (slot update PortfolioState หลัง OpenOrder ack)
- Field schema lock ที่ `docs/api-specs/marketcontext-snapshot-schema.yaml` — TD ห้ามเพิ่ม slot-specific field โดยไม่ update schema ก่อน

**Derived signal precompute:** Helper `RunCheckWPRWaveWithIchimoku2()` + `CheckADXWithForcePeakValid2()` ที่ EA เดิมเรียก global ตอน OnTick → ย้ายเข้า `MarketContextBuilder` คำนวณครั้งเดียว + เก็บใน snapshot field (`wpr_wave_signal`, `adx_force_peak_valid`); slot อ่านจาก field

## Consequences

**Positive**
- Slot consistency invariant guaranteed by `const` reference + struct value semantic (MQL5 struct = value type, copy on pass — tick-safe)
- Testability: stub `MarketContext` ใน QA scenario ได้
- Add field = touch 1 file (`MarketContext.mqh` + builder + schema YAML) — slot ที่ไม่ใช้ field ใหม่ไม่ต้อง recompile

**Negative / trade-off**
- Struct ใหญ่ (~30 indicator buffers × 3 bars × 8 bytes ≈ 720 bytes; +helper signals) → copy cost per slot evaluate ~720 bytes × 21 slots ≈ 15 KB/tick — well within MQL5 stack budget
- ถ้า slot ใหม่ต้องการ indicator field ที่ snapshot ไม่มี → **revisit** schema; ไม่ใช่ slot fix หลังบ้าน — discipline cost
- Schema versioning ตอน Phase 2 เพิ่ม field ใหม่ → backward compat ของ TradeJournal `indicator_snapshot` field; mitigated ผ่าน per-record schema version (TD decide)

## Revisit-when

- ถ้า MarketContext > 5 KB → revisit pass-by-pointer แทน value semantic
- ถ้า slot ต้องการ indicator ของ timeframe ที่ไม่ใช่ H4 (เช่น Phase 2 introduce M30 slot) → revisit schema expansion
- ถ้า measured copy overhead > 100 µs/tick → switch to pointer pass + immutability ผ่าน const interface
