# Code Review Fix Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Review File** | `docs/code-review/review-round-01.md` |
| **Date** | 2026-05-02 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |
| **Scope** | 4 source files in `MQL5/Experts/PhoenicisNex/` (IndicatorService, PortfolioState, JsonWriter, CommentParser, BootstrapValidator) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit Group |
|---|---------|----------|---------|----------------|--------------|
| 01.1 | CreateHandles partial-failure handle leak | 🔴 CRITICAL | Accept | 0 | G1 |
| 01.2 | `iCustom("ZigZag")` path ผิด | 🔴 CRITICAL | Accept | 0 | G1 |
| 01.3 | CommentParser doc magic drift | 🟠 HIGH | Accept | 0 | G4 |
| 01.4 | IndicatorService Logger.Error vs ErrorBypassThrottle | 🟠 HIGH | Accept | 0 (BootstrapValidator already correct) | G1 |
| 01.5 | PortfolioState double-init SlotState* leak | 🟠 HIGH | Accept | 0 | G2 |
| 01.6 | CachedScan FIFO ≠ documented LRU | 🟡 MEDIUM | Accept (option B — doc fix) | 0 | G1 |
| 01.7 | CachedScan stub silent wrong-result | 🟡 MEDIUM | Accept | 0 | G1 |
| 01.8 | BootstrapValidator header guard count 43 ≠ body 39 | 🟡 MEDIUM | Accept | 0 | G4 |
| 01.9 | EscapeString ขาด control-char coverage | 🟡 MEDIUM | Accept | 0 | G3 |
| 01.10 | WriteString ไม่ escape JSON key | 🔵 LOW | Accept | 0 (6 WriteX sites in 1 file) | G3 |
| 01.11 | WriteDateTime epoch fallback emits bare int | 🔵 LOW | Accept | 0 | G3 |

**Accepted:** 11 / 11 — **Rejected:** 0 — **Partial:** 0
**Pattern detection:** ทุก finding scope-bounded ใน 1 ไฟล์เดิม. 01.4 (halt-path bypass) cross-checked across services — only IndicatorService offended; BootstrapValidator pattern แล้ว correct.

---

## Accepted Findings — Fixes Applied

### Fix for 01.1 — `CIndicatorService::CreateHandles` cleanup-on-fail
**File:** `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh` (CreateHandles validation loop)
**Change:** เพิ่ม cleanup loop ก่อน `return false` — เรียก `IndicatorRelease` ทุก handle ที่ valid (j != i + != INVALID_HANDLE) → reset เป็น INVALID_HANDLE. ป้องกัน 23-handle leak ตอน partial failure (m_handle_count ยัง 0 → orchestrator ReleaseHandles loop 0..0 = leak).

### Fix for 01.2 — ZigZag path
**File:** `services/IndicatorService.mqh` lines 232-235
**Change:** `"ZigZag"` → `"Examples\\ZigZag"` ทั้ง H4 + M5. Bundled MT5 ZigZag อยู่ที่ `MQL5/Indicators/Examples/ZigZag.ex5`. Unblocks G2/G3 gate ทั้งหมดเมื่อ entry .mq5 landed.

### Fix for 01.3 — CommentParser magic doc
**File:** `helpers/CommentParser.mqh` lines 19-29
**Change:** Doc magic 202/216/213 → 208/214/211 (ตรง EnumTypes canonical: MAGIC_G/B/L). เพิ่ม note "Canonical magic source: EnumTypes.mqh — do NOT restate".

### Fix for 01.4 — IndicatorService halt-path bypass
**File:** `services/IndicatorService.mqh` CreateHandles validation loop
**Change:** `m_logger.Error(...)` → `m_logger.ErrorBypassThrottle(...)`. ตรง pattern เดียวกับ BootstrapValidator (39 guards ใช้ ErrorBypassThrottle ทั้งหมด). Boot-time alert ต้องไม่ throttle (ADR-011 + NFR-5.1).

### Fix for 01.5 — PortfolioState double-init guard
**File:** `services/PortfolioState.mqh` `Init()`
**Change:** เพิ่ม defensive guard `if(m_magic_count > 0) ReleaseAll();` ก่อน reset. ป้องกัน 17-SlotState* leak ใน MT5 re-init scenario (input parameter change / CleanupPartialInit re-attempt).

### Fix for 01.6 — CachedScan eviction policy doc
**File:** `services/IndicatorService.mqh` header doc + storage comment
**Change:** "10-entry LRU scan cache" → "10-entry FIFO scan cache (insertion-order evict)". เพิ่ม note อธิบาย FIFO trade-off + reference IMPL-006-cachedscan สำหรับ LRU upgrade. Option B (doc fix) chosen เพราะ scope-tight; full LRU upgrade ติดตามที่ impl-plan task IMPL-006.

### Fix for 01.7 — CachedScan fail-loud
**File:** `services/IndicatorService.mqh` `CachedScan()` cache miss path
**Change:** ลบ stub `scan_fn(m_handles[0], 300)` (silent wrong-result). Cache miss → log Warn `cached_scan_unwired` + return 0.0 + ไม่ insert. Caller ใน IMPL-006 จะเห็น Warn ทันทีถ้า key→IDX mapping ยังไม่ wired.

### Fix for 01.8 — BootstrapValidator guard count
**File:** `core/BootstrapValidator.mqh` ValidateInputs header doc
**Change:** "43 individual if-blocks" → "39 individual if-blocks (matches body Guards 1..39)" + breakdown 17+11+8+3=39 (Inputs_General 17 from 21 inputs/16 validatable + 1 relational LADX guard).

### Fix for 01.9 — EscapeString control-char coverage
**File:** `helpers/JsonWriter.mqh` `EscapeString()`
**Change:** เพิ่ม char-loop ตามหลัง 5-char StringReplace — escape `0x00..0x1F` (ยกเว้น 0x09/0x0A/0x0D ที่ handle แล้ว) เป็น `\uXXXX`. RFC 8259 §7 compliance.

### Fix for 01.10 — Escape JSON keys
**File:** `helpers/JsonWriter.mqh` 6 WriteX methods (WriteString, WriteInt, WriteDouble, WriteBool, WriteNull, WriteRaw)
**Change:** Apply `EscapeString(key)` ทุก site. Defensive boundary — ปัจจุบัน Phase 1 ใช้ literal field names เท่านั้น แต่ Phase 2 dynamic keys จะ break ถ้าไม่แก้.

### Fix for 01.11 — WriteDateTime ISO synthesis
**File:** `helpers/JsonWriter.mqh` `WriteDateTime()`
**Change:** Epoch fallback path เปลี่ยนจาก `WriteInt((long)epoch_fallback)` → synthesize `YYYY-MM-DDTHH:MM:SSZ` ผ่าน `TimeToStruct` + StringFormat → `WriteString`. Schema-compliant. SelfTest case 11 updated.

### SelfTest updates (Tests Added)
**File:** `helpers/JsonWriter.mqh` `CJsonWriter::SelfTest()`
- **Case 11** rewritten: stale_fallback assertion now checks synthesized ISO string (recomputes expected from same epoch via TimeToStruct).
- **Case 13 added:** control-char escape — input `"x" + 0x01 + "y"` expected `"xy"`.
- **Case 14 added:** key escape — key `a"b\c` expected `a\"b\\c`.

---

## Rejected Findings — Evidence

ไม่มี — 11/11 accepted.

---

## G1-G4 Status

| Gate | Status | Reason |
|------|--------|--------|
| G1 Compile | ⏭ Skip | Entry `.mq5` (`PhoenicisNex.mq5`) ยัง not landed (IMPL-018+) — header-only `.mqh` files defer G1 per IMPL-001..042 precedent (see `impl-plan.md` audit log). G1 จะรันรวมตอน orchestrator/entry land. |
| G2 Smoke | ⏭ Skip | Same precedent (header-only). |
| G3 Headless | ⏭ Skip | Same precedent. |
| G4 Log review | ⏭ Skip | Same precedent. |

**Verification surface ของ round นี้:** Static review (Edit + Read) + JsonWriter SelfTest case expansion (11 → 14 assertions, runs at IMPL-018+ wire-up). All fixes structurally sound; runtime verification gated by entry `.mq5` (per existing impl-plan precedent — ไม่ใช่ regression ของ round นี้).

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 11 |
| Accepted | 11 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 4 (IndicatorService.mqh, PortfolioState.mqh, JsonWriter.mqh, CommentParser.mqh, BootstrapValidator.mqh) |
| Tests Added/Updated | 3 SelfTest assertions (case 11 rewrite + 13 + 14) |
| Commits | TBD (4 commit groups planned: G1 IndicatorService, G2 PortfolioState, G3 JsonWriter, G4 doc fixes) |

**Recommendation:** Ready for next code review round หรือ proceed กับ IMPL-018+ (entry .mq5) ที่จะ unblock G1-G4 empirical verification ของ Round 01 fixes.
