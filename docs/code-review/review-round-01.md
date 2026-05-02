# Code Review Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Target** | `all` (P1 13/17 closures — `MQL5/Experts/PhoenicisNex/{core,domain,helpers,inputs,services}/*.mqh`) |
| **Date** | 2026-05-02 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | 15 source files (2,803 LOC); IMPL-001..005, 007..009, 011, 012, 014, 015, 042 |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH     | 3 |
| MEDIUM   | 4 |
| LOW      | 2 |
| **Total**| **11** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1  | Security (OWASP / MQL5 boundary) | ⚠️ Finding | NFR-5.1 halt-path divergence: `IndicatorService` ใช้ `Logger.Error` (throttled) แทน `ErrorBypassThrottle` ที่ `BootstrapValidator` ใช้ → Finding 01.4 |
| 2  | Business Logic Correctness | ⚠️ Finding | `iCustom("ZigZag")` path ผิด → INVALID_HANDLE 100% (Finding 01.2); BR-1.1 magic-table doc drift (Finding 01.3) |
| 3  | Error Handling | ⚠️ Finding | `CreateHandles` partial-failure leak (Finding 01.1); double-init leak ใน PortfolioState (Finding 01.5) |
| 4  | Performance | ✅ Pass | Hot-path code ยังไม่ landed (deferred to IMPL-006/053+); Refresh aggregate reset O(17) acceptable |
| 5  | Over-Engineering | ✅ Pass | header-only files ตรง TD-02 §5 skeleton; ไม่มี premature abstraction |
| 6  | Cross-Service Consistency | ⚠️ Finding | CommentParser doc magic 202/216/213 ขัดแย้งกับ EnumTypes 208/214/211 (Finding 01.3) |
| 7  | Test Coverage Gaps | ✅ Pass | SelfTest มีใน CCommentParser + CJsonWriter; G1-G4 N/A per impl-plan (header-only `.mqh`); E-ACs ทั้งหมด `[ ]` (ยังไม่ปิด) — ไม่มี Forbidden Closure Pattern violation |
| 8  | Architecture Compliance | ✅ Pass | 5-layer include direction respected (`services/Logger.mqh` includes `domain/EnumTypes.mqh` + `helpers/Timestamp.mqh`; no `slots/*` `#include "slots/<other>"`) |
| 9  | Technical Design Compliance | ⚠️ Finding | ZigZag path drift (Finding 01.2); CachedScan FIFO ≠ documented LRU (Finding 01.6); BootstrapValidator header guard-count drift (Finding 01.8) |
| 10 | Test Code Quality | ✅ Pass | SelfTest fixtures bounded (10 cases CCommentParser; 12 assertions JsonWriter); ไม่มี catastrophic regex / unbounded loop / shared mutable state |
| 11 | Empirical AC Closure | ✅ Pass | ทุก E-AC สำหรับ IMPL-005..042 ปล่อย `[ ]` พร้อม "deferred to IMPL-053+/IMPL-018+" (forward-task dependency, ไม่ใช่ in-place closure). ห้าม `[x]` + "deferred per <task> precedent" — grep `impl-plan.md` = 0 hits ✅ |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface (UX phase ⏭ N/A per overview.md); review touches header-only `.mqh` (no live runnable surface yet) |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; ไม่มี env var/secret/API key consumer (per CLAUDE.md §6 "config-audit gate triggers Phase 2") |

---

## Findings

### Finding 01.1: 🔴 CRITICAL — `CIndicatorService::CreateHandles` ปล่อย handle leak บน partial failure path

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh`, Lines: 170-272
- Service: `ea` / services / IndicatorService

**Code:**
```mql5
bool CIndicatorService::CreateHandles()
  {
   ArrayInitialize(m_handles, INVALID_HANDLE);
   m_handle_count = 0;                                       // ← stays 0 until success
   m_handles[IDX_ICHI_H4]  = iIchimoku(...);                 // ← if these succeed
   m_handles[IDX_ICHI_D1]  = iIchimoku(...);
   ...                                                        // 22 more iXxx() calls
   m_handles[IDX_MOMENTUM_H4] = iMomentum(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);

   int total = 24;
   for(int i = 0; i < total; i++)
     {
      if(m_handles[i] == INVALID_HANDLE)
        {
         m_logger.Error("indicators", "invalid_handle", i, ...);
         return false;        // ← BAIL OUT: handles 0..(i-1) leak; m_handle_count == 0
        }
     }
   m_handle_count = total;    // ← only reached on full success
   ...
  }
```

**Problem:**
ถ้า iXxx() บางตัว return INVALID_HANDLE (เช่น iCustom ZigZag — ดู Finding 01.2), function จะ `return false` ที่ line 263 โดยไม่เรียก `IndicatorRelease` สำหรับ handle ที่ valid อยู่แล้ว นอกจากนั้น `m_handle_count` ยังเป็น 0 ที่ point นั้น ทำให้ orchestrator's `CleanupPartialInit → ReleaseHandles()` (lines 380-389) loop `i < m_handle_count == 0` → release ไม่มีอะไรเลย handle ที่สร้างสำเร็จ (อาจ 23 ตัว) leak ตลอด session ของ MT5 จนกว่าจะปิด terminal

**Why This Matters:**
ขัด `.claude/rules/ea.md § MQL5/MT5-specific idioms` ("Indicator handles: create in IndicatorService::Init; release in ReleaseHandles() on OnDeinit") + TD-02 §7.4.1 CleanupPartialInit contract. ถ้า EA ถูก reattach หลัง INIT_FAILED 23 รอบ → MT5 limit (1024 handles per process per docs) → terminal-wide indicator exhaustion. Operator ต้องปิดทั้ง terminal เพื่อ recover.

**Suggested Fix:**
```mql5
bool CIndicatorService::CreateHandles()
  {
   ArrayInitialize(m_handles, INVALID_HANDLE);
   m_handle_count = 0;
   // ... all iXxx() calls ...

   int total = 24;
   for(int i = 0; i < total; i++)
     {
      if(m_handles[i] == INVALID_HANDLE)
        {
         m_logger.ErrorBypassThrottle("indicators", "invalid_handle", i, ...);
         // Release any handles that DID succeed before bailing
         for(int j = 0; j < total; j++)
            if(j != i && m_handles[j] != INVALID_HANDLE)
              { IndicatorRelease(m_handles[j]); m_handles[j] = INVALID_HANDLE; }
         return false;
        }
     }
   m_handle_count = total;
   ...
  }
```

**Level of Effort:** Low

---

### Finding 01.2: 🔴 CRITICAL — `iCustom("ZigZag", ...)` path ผิด → CreateHandles ล้มเหลว 100% บน MT5 stock install

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh`, Lines: 231-232
- Service: `ea` / services / IndicatorService

**Code:**
```mql5
//--- ZigZag (H4 + M5) — CodeWiki §1.4 ZigZag reference
//    TODO IMPL-005-tune: verify ZigZag ExtDepth/Deviation/Backstep params
m_handles[IDX_ZIGZAG_H4] = iCustom(_Symbol, PERIOD_H4, "ZigZag", 12, 5, 3);
m_handles[IDX_ZIGZAG_M5] = iCustom(_Symbol, PERIOD_M5,  "ZigZag", 12, 5, 3);
```

**Problem:**
`iCustom(symbol, period, "ZigZag", ...)` ค้นหา compiled indicator ที่ `MQL5/Indicators/ZigZag.ex5`. ใน MT5 stock install ไฟล์นี้ไม่มี — bundled ZigZag อยู่ที่ `MQL5/Indicators/Examples/ZigZag.ex5`. path ที่ถูกคือ `"Examples\\ZigZag"` (escape backslash). ผลลัพธ์: `iCustom` return `INVALID_HANDLE` → validation loop catch ที่ index 16 → `CreateHandles` return false → `INIT_FAILED` 100% ทุก boot จนกว่าจะแก้ path. EA ขึ้นไม่ติดตั้งแต่แรก = G2 Smoke gate ล้ม 100%.

**Why This Matters:**
ขัด NFR-3.2 (validate ทุก ~25 handles, fail-fast 100%) — fail-fast ทำงานถูก แต่ root cause = bug ที่ป้องกันไม่ให้ EA ขึ้นเลย. Operator-side recovery = paste `Examples\ZigZag.ex5` ลง `MQL5/Indicators/` หรือแก้โค้ด. CodeWiki §1.4 อ้าง bundled MT5 ZigZag → path ใน code วันนี้ขัดกับ source-of-truth.

**Suggested Fix:**
```mql5
m_handles[IDX_ZIGZAG_H4] = iCustom(_Symbol, PERIOD_H4, "Examples\\ZigZag", 12, 5, 3);
m_handles[IDX_ZIGZAG_M5] = iCustom(_Symbol, PERIOD_M5,  "Examples\\ZigZag", 12, 5, 3);
```
ทดสอบใน Strategy Tester ก่อน commit — ถ้า G3 ล้ม → CodeWiki §1.4 อาจระบุ third-party ZigZag (ต้อง /amend td เพื่อ document dependency).

**Level of Effort:** Low

---

### Finding 01.3: 🟠 HIGH — `CCommentParser` header doc magic-number drift กับ `EnumTypes.mqh` canonical

**Location:**
- File: `MQL5/Experts/PhoenicisNex/helpers/CommentParser.mqh`, Lines: 20-23
- Service: `ea` / helpers / CommentParser

**Code:**
```cpp
//|  Shared-magic disambiguation pairs (4 pairs, 8 slots):
//|    C / D  (magic 200) — D is force-pending wrapper of C
//|    G / G2 (magic 202) — G2 prefix MUST be tested before G
//|    B / BI (magic 216) — BI prefix MUST be tested before B
//|    L / LX (magic 213) — LX prefix MUST be tested before L
```

vs `domain/EnumTypes.mqh`:
```cpp
static const int MAGIC_G  = 208;  // G, G2 shared
static const int MAGIC_L  = 211;  // L, LX shared
static const int MAGIC_B  = 214;  // B, BI shared
```

**Problem:**
CommentParser doc บอก G/G2 = 202, B/BI = 216, L/LX = 213 — ทั้งหมด **ขัดแย้งกับ EnumTypes canonical**: 208/214/211. Magic 202 ไม่มีใน registry (gap); 213 = MAGIC_R (R slot); 216 = MAGIC_I (I slot). ขัด BR-1.1 (17-magic invariant) + ADR-005 + cross-doc consistency. CommentParser code เอง correct (ใช้ slot_id strings, ไม่อ้าง magic) แต่ doc คือ source-of-confusion: engineer คนต่อไปอ่าน CommentParser แล้ว mis-derive magic → orphan trade ที่ broker / silent slot disambiguation bug.

**Why This Matters:**
Code Review Dimension #6 Cross-Service Consistency — entity name (magic) ต้องตรงทั่ว codebase. CLAUDE.md §1 + §3 ระบุ BR-1.1 17-magic invariant เป็น Phase Gate-blocking. Doc drift บนไฟล์ที่ "parse the slot prefix" = อันตรายโดยตรง: ถ้า engineer เปลี่ยน CommentParser ตามที่ doc บอก จะ desync กับ PortfolioState/EnumTypes ทันที.

**Suggested Fix:**
```cpp
//|  Shared-magic disambiguation pairs (4 pairs, 8 slots):
//|    C / D  (magic 200, MAGIC_CD) — D is force-pending wrapper of C
//|    G / G2 (magic 208, MAGIC_G ) — G2 prefix MUST be tested before G
//|    B / BI (magic 214, MAGIC_B ) — BI prefix MUST be tested before B
//|    L / LX (magic 211, MAGIC_L ) — LX prefix MUST be tested before L
//
//  Canonical source: domain/EnumTypes.mqh — do NOT restate; cross-link only.
```

**Level of Effort:** Low

---

### Finding 01.4: 🟠 HIGH — `IndicatorService::CreateHandles` ใช้ `Logger.Error` (throttled) แทน `ErrorBypassThrottle` บน boot-time fail-fast path

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh`, Line: 260
- Service: `ea` / services / IndicatorService

**Code:**
```mql5
if(m_handles[i] == INVALID_HANDLE)
  {
   m_logger.Error("indicators", "invalid_handle", i,
                  StringFormat("handle[%d] == INVALID_HANDLE after iXxx() call; "
                               "symbol=%s — returning false → INIT_FAILED", i, _Symbol));
   return false;
  }
```

**Problem:**
Boot-time fail-fast paths ต้องใช้ `ErrorBypassThrottle` per ADR-011 § "boot-time bypass" + `.claude/rules/security.md § Halt`. Reason: `Logger.Error` route ผ่าน `ShouldThrottleAlert` (Logger.mqh line 194) ซึ่ง suppress Alert ถ้า (slot,ev) ติด throttle window. แม้ว่า boot-time `m_tick_counter == 0` จะทำให้ตอน first call ไม่ติด throttle, **second invalid handle ใน same boot** หรือ **re-attach หลัง partial cleanup** จะเงียบ. `BootstrapValidator.mqh` (line 113) ใช้ `ErrorBypassThrottle` ถูกต้อง — IndicatorService ขัดแย้งกับ pattern เดียวกันใน codebase.

**Why This Matters:**
NFR-5.1 + security.md ระบุ "ห้าม silent halt path — ทุก halt path ต้อง Alert MT5 native + journal entry". ถ้า second iCustom fail (เช่น symbol-deps ล้มต่อเนื่อง) → operator ไม่เห็น Alert → ไม่รู้ว่า EA ตายเพราะ handle ตัวที่ 2. ADR-011 § Why บอกชัด: ครั้งนึงผิด → operator ต้องรู้.

**Suggested Fix:**
```mql5
if(m_handles[i] == INVALID_HANDLE)
  {
   m_logger.ErrorBypassThrottle("indicators", "invalid_handle", i,
                  StringFormat("handle[%d] == INVALID_HANDLE after iXxx() call; "
                               "symbol=%s — returning false → INIT_FAILED", i, _Symbol));
   return false;
  }
```
ใช้ pattern เดียวกับ `BootstrapValidator::ValidateInputs` (39 guards ทั้งหมดใช้ `ErrorBypassThrottle`).

**Level of Effort:** Low

---

### Finding 01.5: 🟠 HIGH — `CPortfolioState::Init` + `RegisterAll` ปล่อย `SlotState*` leak ถ้า called twice without `ReleaseAll`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh`, Lines: 97-105 + 122-266
- Service: `ea` / services / PortfolioState

**Code:**
```mql5
void CPortfolioState::Init(CLogger *logger)
  {
   m_logger      = logger;
   m_magic_count = 0;       // ← reset count
   m_map.Clear();           // ← drops 17 SlotState* references (heap leak)
   ArrayInitialize(m_magic_list, 0);
  }

void CPortfolioState::RegisterAll()
  {
   ...
   for(int i = 0; i < 17; i++)
     {
      ...
      SlotState *s = new SlotState;     // ← heap allocation
      ...
      m_map.Add(magic, s);
      m_magic_count++;
     }
  }
```

**Problem:**
`Init` เรียก `m_map.Clear()` โดยตรง (drops references) **ไม่ใช่** เรียก `ReleaseAll()` ที่ delete heap pointers ก่อน. ถ้า orchestrator restart sequence (เช่น INIT_FAILED → CleanupPartialInit → re-attempt; หรือ user-triggered re-init via input change) ทำให้ `Init` + `RegisterAll` รันรอบ 2 → 17 `SlotState*` จาก rounds แรก leak. MQL5 garbage-collection on `delete` only — `m_map.Clear()` ไม่ trigger destructor ของ pointed-to.

**Why This Matters:**
ADR-005 § "each SlotState* is new'd in RegisterAll → must delete" + ea.md § "ReleaseHandles() on OnDeinit; validate INVALID_HANDLE 100%" pattern. แม้ Phase 1 boot path เดียว (ดู `CleanupPartialInit` per TD-02 §7.4.1) แต่ orchestrator `re-init on input parameter change` (MT5 standard) จะ trigger. Long-running session = slowly creep memory. NFR-2.x silent breach.

**Suggested Fix:**
```mql5
void CPortfolioState::Init(CLogger *logger)
  {
   // Defensive: release prior allocations before re-init (ADR-005 lifecycle pairing)
   if(m_magic_count > 0)
      ReleaseAll();         // delete each SlotState* + Clear() map + reset count
   m_logger      = logger;
   ArrayInitialize(m_magic_list, 0);
   // m_map already cleared by ReleaseAll; m_magic_count == 0
  }
```
หรือ assert: `if(m_magic_count != 0) m_logger.ErrorBypassThrottle("portfolio","init_double_call",0,...);`.

**Level of Effort:** Low

---

### Finding 01.6: 🟡 MEDIUM — `CIndicatorService::CachedScan` ใช้ FIFO eviction แต่ header doc claim LRU

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh`, Lines: 65 (header doc) vs 351-369 (impl)
- Service: `ea` / services / IndicatorService

**Code:**
```mql5
// Header line 65:
//--- CachedScan storage (key→value, up to 10 entries — FR-8.1 300-bar scan cache)
// Line 15-16 doc:
//  • CachedScan() 10-entry LRU scan cache

// Impl lines 358-368 (eviction):
else
  {
   // Cache full — evict oldest (index 0) by rotating left
   for(int i = 0; i < 9; i++)
     {
      m_scan_keys[i]   = m_scan_keys[i + 1];
      m_scan_values[i] = m_scan_values[i + 1];
     }
   m_scan_keys[9]   = key;
   m_scan_values[9] = computed;
  }
```

**Problem:**
Doc claim "LRU cache" (Logger.mqh เป็น LRU จริง — ดู `FindOrEvictKey`). แต่ `CachedScan` evict by **insertion order** (rotate-left index 0 = oldest insert) — **FIFO**, not LRU. Cache hit ที่ line 339 return cached value โดย**ไม่อัพเดต access timestamp** → frequently-used key ยัง evict ก่อน rare-but-recent key.

**Why This Matters:**
FR-8.1 บอก "300-bar scan cache" — ถ้าเป็น FIFO, scan ที่อ่านบ่อยจะถูก evict โดย scan one-shot ที่เพิ่งเข้า → cache hit rate ต่ำลง → recompute 300-bar scan = expensive (NFR-2.x tick latency). อาจไม่ block correctness แต่ defeats caching purpose. Documentation drift = engineer ในอนาคตคิดว่า hot key safe → tunes cache size from "real LRU" baseline.

**Suggested Fix:**
ทางเลือก (A) implement true LRU: เพิ่ม `int m_scan_access_tick[10]` + อัพเดตบน hit + evict by oldest access tick (parallel ของ Logger.FindOrEvictKey). ทางเลือก (B) แก้ doc ให้ตรงกับ impl — เปลี่ยน "LRU" → "FIFO" ในไฟล์ + TD-02 §5.1. แนะนำ (A) per FR-8.1 spirit; ถ้า scope-tight ก็ (B) + add ADR-013 acknowledging trade-off.

**Level of Effort:** Low (B) / Medium (A)

---

### Finding 01.7: 🟡 MEDIUM — `CIndicatorService::CachedScan` stub computes wrong handle on cache miss (silent wrong-result)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh`, Lines: 343-348
- Service: `ea` / services / IndicatorService

**Code:**
```mql5
double computed = 0.0;
if(scan_fn != NULL && m_handle_count > 0)
   computed = scan_fn(m_handles[0], 300);  // TODO IMPL-005-cachedscan: resolve idx from key
```

**Problem:**
Cache miss path เรียก `scan_fn(m_handles[0], 300)` — `m_handles[0]` คือ `IDX_ICHI_H4` (Ichimoku H4) เสมอ ไม่ว่า key ที่ caller ส่งจะระบุ scan ของ indicator ตัวไหน. ถ้า MarketContextBuilder ใน IMPL-006 เรียก `CachedScan("force_peak_300", scan_fn)` คาดหวัง Force-Index handle → ได้ Ichimoku H4 instead → ผลลัพธ์ = numeric garbage (Ichimoku Tenkan ค่า ≠ Force peak detector). Caller ไม่ทราบว่าได้ result ผิด (function ไม่ Warn).

**Why This Matters:**
TODO comment บ่งบอกว่ารู้ปัญหา แต่ stub current = silent wrong-result, **ไม่ใช่** controlled fail. ถ้า IMPL-006 wire เข้า production paths ก่อน IMPL-005-cachedscan ปิด → trade decision ใช้ wrong indicator value → wrong P&L. Code Review Dimension #2 Business Logic Correctness — partial implementation ที่ produce wrong-but-plausible result คือ defect class ที่อันตรากว่า not-implemented.

**Suggested Fix:**
```mql5
double computed = 0.0;
if(scan_fn != NULL && m_handle_count > 0)
  {
   // TODO IMPL-005-cachedscan: resolve idx from key
   // Until then, refuse to compute — fail-loud, not silent-wrong-result
   m_logger.Warn("indicators", "cached_scan_unwired", 0,
                 "CachedScan called before IDX-mapping wired; key=" + key + " — returning 0.0");
   return 0.0;
  }
```
หรือทำให้ key encode IDX ตรงๆ (`"IDX_5:force_peak_300"`) + parse แล้ว lookup `m_handles[idx]`.

**Level of Effort:** Low

---

### Finding 01.8: 🟡 MEDIUM — `CBootstrapValidator` header doc claim "43 individual if-blocks" แต่ code มี 39 guards

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh`, Lines: 88-101 (header) vs 102-477 (body)
- Service: `ea` / core / BootstrapValidator

**Code:**
```cpp
// Header line 89:
//| Guard count: 43 individual if-blocks (audit in evidence file).

// Header line 92-98 itemizes:
//|  Inputs_General.mqh  — ... yields 21 if-blocks
//|  Inputs_TimeGates.mqh— 11 inputs; all int, yields 11 if-blocks
//|  Inputs_Pending.mqh  — 8  inputs; all int, yields 8 if-blocks
//|  Inputs_Logging.mqh  — 3 if-blocks
// Total claimed:                                  21 + 11 + 8 + 3 = 43

// Body actually enumerates "Guard 1" through "Guard 39" (lines 109-472)
```

**Problem:**
Header math (21 + 11 + 8 + 3 = 43) ขัดกับ body enumeration (Guards 1..39). impl-plan.md `IMPL-015` audit log (line 1558) เขียนว่า "**39 fail-fast guards**" — ตรงกับ body ไม่ตรงกับ header. Discrepancy = audit-traceability defect: TD-02 §13.5 audit contract บอก "ห้าม silent skip gate (แก้ message ให้ ผ่าน)" — header doc ยังโชว์ตัวเลขเก่า.

**Why This Matters:**
Code Review Dimension #9 Technical Design Compliance + audit contract. Reviewer ในอนาคตอ่าน header → expect 43 guards → grep ได้ 39 → file fixing ticket. หรือ engineer คิดว่า "doc ถูกแล้ว — ลืมเพิ่ม 4 guard" → เพิ่ม guard ที่ไม่ควรเพิ่ม. Both vectors waste cycles.

**Suggested Fix:**
แก้ header:
```cpp
//| Guard count: 39 individual if-blocks (audit in evidence file).
//|
//|  Inputs_General.mqh  — 21 inputs; 16 validatable (5 bool/enum
//|                         skipped); yields 17 if-blocks (incl. Guard 6
//|                         relational LADX floor < threshold)
//|  Inputs_TimeGates.mqh— 11 inputs; yields 11 if-blocks
//|  Inputs_Pending.mqh  —  8 inputs; yields  8 if-blocks
//|  Inputs_Logging.mqh  —  3 if-blocks (LogLevel low, LogLevel high,
//|                         EscalationN)
//|                         Total: 17 + 11 + 8 + 3 = 39
```
หรือ — ถ้าตั้งใจเพิ่ม 4 guards เพิ่ม → ระบุชัดว่า guard ไหนหายไป + เพิ่มลง code.

**Level of Effort:** Low

---

### Finding 01.9: 🟡 MEDIUM — `CJsonWriter::EscapeString` ขาด control-character coverage (JSON spec violation)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh`, Lines: 63-76
- Service: `ea` / helpers / JsonWriter

**Code:**
```mql5
string EscapeString(string raw) const
  {
   StringReplace(raw, "\\", "\\\\");   // 1. Backslash
   StringReplace(raw, "\"", "\\\"");   // 2. Double quote
   StringReplace(raw, "\n", "\\n");    // 3. Newline
   StringReplace(raw, "\r", "\\r");    // 4. Carriage return
   StringReplace(raw, "\t", "\\t");    // 5. Tab
   return raw;
  }
```

**Problem:**
JSON RFC 8259 §7 บังคับว่า control characters U+0000..U+001F **ทุกตัว**ต้อง escape (เช่น ``, ``, ``). EscapeString covers แค่ 3 ตัวที่ printable-relevant (\n=0x0A, \r=0x0D, \t=0x09). หาก slot's `signal_context` หรือ MT5 `POSITION_COMMENT` มี byte 0x01..0x08 / 0x0B..0x0C / 0x0E..0x1F (เช่น user copy-paste จาก binary log) → output `.jsonl` ไม่ใช่ valid JSON → `jq .` parse fail → G4 gate ล้ม → `trade-journal-schema.yaml` validation block.

**Why This Matters:**
ADR-006 + trade-journal-schema.yaml กำหนดว่า journal records ต้อง valid JSON-Lines. NFR-2.2 journal write 5 ms p99 — ถ้า jq fail บน control char → run ทั้ง batch ของ records ใน file นั้น = corrupt. Phase 1 risk ต่ำ (slot signals ไม่น่ามี control char) แต่ Phase 2 cloud sync จะ break.

**Suggested Fix:**
```mql5
string EscapeString(string raw) const
  {
   StringReplace(raw, "\\", "\\\\");
   StringReplace(raw, "\"", "\\\"");
   StringReplace(raw, "\n", "\\n");
   StringReplace(raw, "\r", "\\r");
   StringReplace(raw, "\t", "\\t");
   // Escape remaining control chars (0x00..0x08, 0x0B..0x0C, 0x0E..0x1F)
   string out = "";
   int n = StringLen(raw);
   for(int i = 0; i < n; i++)
     {
      ushort ch = StringGetCharacter(raw, i);
      if(ch < 0x20 && ch != 0x09 && ch != 0x0A && ch != 0x0D)
         out += StringFormat("\\u%04x", ch);
      else
         out += ShortToString(ch);
     }
   return out;
  }
```
(NFR-2.2 5 ms budget ยังพอ — typical journal record 200-500 bytes; loop overhead microseconds).

**Level of Effort:** Medium

---

### Finding 01.10: 🔵 LOW — `CJsonWriter::WriteString` ไม่ escape JSON key (caller-trust assumption)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh`, Lines: 104-108
- Service: `ea` / helpers / JsonWriter

**Code:**
```mql5
void WriteString(string key, string value)
  {
   AppendComma();
   m_buffer += "\"" + key + "\":\"" + EscapeString(value) + "\"";
   //          ^^^^^^^^^^^^^^^^^^^^^^^ key is NOT escape-protected
  }
```

**Problem:**
ถ้า caller ส่ง `key` ที่มี `"` หรือ `\` (ไม่ควรเกิดใน Phase 1 — keys = literal field names เช่น `"event_type"` แต่ defensive boundary). Output JSON malformed.

**Why This Matters:**
JSON spec consistency. Phase 1 risk = 0 (keys hardcoded ใน TradeJournal serializer ทั้ง 11 + 8 schema fields). Phase 2 ถ้า dynamic keys (เช่น metadata bag) → break.

**Suggested Fix:**
```mql5
void WriteString(string key, string value)
  {
   AppendComma();
   m_buffer += "\"" + EscapeString(key) + "\":\"" + EscapeString(value) + "\"";
  }
```
Apply same to WriteInt/WriteDouble/WriteBool/WriteNull/WriteRaw/WriteDateTime.

**Level of Effort:** Low

---

### Finding 01.11: 🔵 LOW — `CJsonWriter::WriteDateTime` epoch fallback emits unquoted integer for ISO-8601-typed schema field

**Location:**
- File: `MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh`, Lines: 176-188
- Service: `ea` / helpers / JsonWriter

**Code:**
```mql5
void WriteDateTime(string key, string iso_string, datetime epoch_fallback = 0)
  {
   if(StringLen(iso_string) > 0)
      WriteString(key, iso_string);    // schema-correct: quoted ISO-8601
   else
      WriteInt(key, (long)epoch_fallback);  // ← schema-WRONG: bare int where schema expects string
  }
```

**Problem:**
trade-journal-schema.yaml กำหนด `timestamp` (และ `entry_time`, etc.) เป็น ISO-8601 string. Fallback path emit `"timestamp":1746187425` — bare int — schema validator (jq + json-schema) reject. Even comment in body line 186 admits "marks missing formatter" — แต่ caller-side ไม่มี way to detect mode mismatch.

**Why This Matters:**
G4 log review gate (testing.md) sample 5 journal records validate vs schema. ถ้า fallback ถูก trigger (e.g., Timestamp.mqh formatter fail) → 5/5 records reject. Currently masked because no IMPL-043+ wiring ใช้ fallback — แต่ defensive correctness.

**Suggested Fix:**
ลบ fallback path (fail-fast แทน silently corrupt):
```mql5
void WriteDateTime(string key, string iso_string, datetime epoch_fallback = 0)
  {
   string s = iso_string;
   if(StringLen(s) == 0)
     {
      // Synthesize minimal ISO-8601 from epoch fallback (schema-compliant string)
      MqlDateTime dt; TimeToStruct(epoch_fallback, dt);
      s = StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                       dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
     }
   WriteString(key, s);
  }
```

**Level of Effort:** Low

---

## Cross-Service Issues

| Issue | Files | Finding |
|-------|-------|---------|
| Magic-number canon vs CommentParser doc | `domain/EnumTypes.mqh` ↔ `helpers/CommentParser.mqh` | 01.3 |
| Halt-path Logger pattern: `ErrorBypassThrottle` vs `Error` | `core/BootstrapValidator.mqh` (uses correct) ↔ `services/IndicatorService.mqh` (uses throttled) | 01.4 |
| Cache eviction policy doc/impl | `services/IndicatorService.mqh` line 65 doc ↔ line 351-368 impl | 01.6 |
| Guard-count claim vs body | `core/BootstrapValidator.mqh` line 89 doc ↔ enumerated 1..39 in body | 01.8 |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 01.1 | 🔴 CRITICAL | 3 Error Handling | CreateHandles partial-failure handle leak | IndicatorService.mqh:170-272 | Low |
| 01.2 | 🔴 CRITICAL | 2 Business Logic | iCustom("ZigZag") path ผิด → INIT_FAILED 100% | IndicatorService.mqh:231-232 | Low |
| 01.3 | 🟠 HIGH | 6 Cross-Service Consistency | CommentParser magic-number doc drift vs EnumTypes | CommentParser.mqh:20-23 | Low |
| 01.4 | 🟠 HIGH | 1 Security / Halt-path | IndicatorService Logger.Error แทน ErrorBypassThrottle | IndicatorService.mqh:260 | Low |
| 01.5 | 🟠 HIGH | 3 Error Handling | PortfolioState double-init SlotState* leak | PortfolioState.mqh:97-105 | Low |
| 01.6 | 🟡 MEDIUM | 9 TD Compliance | CachedScan FIFO ≠ documented LRU | IndicatorService.mqh:65 vs 351-368 | Low/Medium |
| 01.7 | 🟡 MEDIUM | 2 Business Logic | CachedScan stub silent wrong-result on cache miss | IndicatorService.mqh:343-348 | Low |
| 01.8 | 🟡 MEDIUM | 9 TD Compliance / audit | BootstrapValidator header guard count 43 ≠ body 39 | BootstrapValidator.mqh:89 | Low |
| 01.9 | 🟡 MEDIUM | 1 Security / spec | JsonWriter EscapeString ขาด control-char coverage | JsonWriter.mqh:63-76 | Medium |
| 01.10 | 🔵 LOW | 9 TD Compliance | JsonWriter ไม่ escape key | JsonWriter.mqh:104-108 | Low |
| 01.11 | 🔵 LOW | 9 TD Compliance | WriteDateTime epoch fallback = bare int (schema mismatch) | JsonWriter.mqh:176-188 | Low |

---

## Recommendation

**Verdict:** ❌ **Not Ready for P1 Phase Gate** — 2 CRITICAL findings (01.1 + 01.2) จะทำให้ G2 Smoke + G3 Headless gate ล้ม 100% ทันทีที่ entry `.mq5` (IMPL-018+) ขึ้น. 3 HIGH findings เป็น code-correctness + cross-doc consistency ที่ engineer ที่อ่าน CommentParser doc อาจ propagate magic ผิดเข้า PortfolioState เวอร์ชันต่อไป.

**Next action:** `/impl-review-fix review-round-01.md` — แนะนำ fix 01.1/01.2/01.4 (CRITICAL + halt-path consistency) ก่อน serial; 01.3 + 01.5 จัด bundle เดียวกัน. 01.6/01.7/01.8/01.9 รวบ MEDIUM cluster. 01.10/01.11 polish ที่อาจ defer ได้ถึง IMPL-043+ (TradeJournal landing).

**Top 3 priority fixes:**
1. **01.2** (5 นาที): แก้ iCustom path "ZigZag" → "Examples\\ZigZag" — unblocks all G2/G3 gates downstream
2. **01.1** (15 นาที): เพิ่ม cleanup loop ใน CreateHandles fail path — prevents handle exhaustion ในระหว่าง dev iteration
3. **01.3** (5 นาที): แก้ doc magic 202/216/213 → 208/214/211 + cross-link to EnumTypes — prevents cross-doc derivation drift
