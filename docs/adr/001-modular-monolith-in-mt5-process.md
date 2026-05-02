# ADR-001 — Modular Monolith Inside MT5 Process

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G1, G3, NFR-7.1, NFR-7.2, C-1, C-2, C-9, C-12 |

## Context

PhoenicisNex คือ EA สำหรับ MT5 — runtime คือ MT5 process เอง (ไม่มี server-side, ไม่มี VPS, ไม่มี installer ตาม MVP signal user 2026-05-01). User เป็น solo operator + ส่งมอบเป็น `.mq5/.ex5` วางมือใน `MQL5/Experts/`. NFR-7.2 บังคับ **0 external DLLs** เพื่อหลีก installer requirement (registry, Windows Defender exception).

คำถาม architectural: ใน MT5 process เดียว เราจัดโครงสร้าง 21 slots + cross-slot helpers + persistence + journal อย่างไรให้ G1 (file ≤ 5,000 LOC, ≥ 80 inputs, slot-by-slot maintainability) และ G3 (behavioral parity ≤ 25% Net Profit drift) ทำได้พร้อมกัน

## Options Considered

### Option A — Modular monolith intra-process (chosen)
EA ทั้งหมดอยู่ใน 1 MT5 process; โครงเป็น **layered modules** ผ่าน MQL5 native `#include` + classes:

- `core/` orchestrator + bootstrap
- `slots/Slot_<X>.mqh` (1 file per slot, 21 ไฟล์)
- `services/` MarketContext / IndicatorService / PortfolioState / RiskManager / TradeJournal / StatePersistence / Logger / CircuitBreaker / TimeGate
- `domain/` shared structs + enums + interfaces

### Option B — Multiple `.ex5` EAs on separate charts
Split slots ออกเป็น N EA แล้ว user attach หลาย chart

**Rejected:** 21 slots share state (PortfolioState, MarketContext) + ต้อง exit-before-entry pass ผ่าน orchestrator เดียว (FR-2.3) — split process = lose shared-memory invariant + cross-slot coordination (FR-7.1 OrderGroupStartWorkflow ปิด 10 slots พร้อมกัน) ทำไม่ได้

### Option C — External process via DLL/IPC (rejected)
ย้าย slot logic เข้า DLL (C++) + IPC ผ่าน named pipe

**Rejected:** ขัด NFR-7.2 (0 DLLs) + ขัด MVP signal "ไม่ต้องทำ Install หรือ Server" (C-12); Windows Defender + DLL signing = installer overhead

## Decision

เลือก **Option A — modular monolith intra-process** ใน MT5 sandbox. โครงสร้างเป็น layered modules ผ่าน MQL5 OO + `#include`

**Why:** เป็น **only viable option** เมื่อ NFR-7.2 + C-12 + FR-2.3 ผูกพร้อมกัน. Option B/C ทำให้ขัด constraint ที่ user lock ไปแล้ว — เลือก A และเน้น discipline ของ module boundaries เพื่อให้ G1 ผ่านได้

## Consequences

**Positive**
- 0 DLL dependency → ส่งมอบ = วางไฟล์ใน `MQL5/Experts/` ทันที
- Single-threaded tick (CodeWiki §6.3 P4.7) → ไม่มี race condition; preserve EA เดิม mental model
- Module boundaries ผ่าน MQL5 namespace + 1 file/slot (NFR-4.2) → AI agent + human reviewer ทำงานทีละ slot ได้

**Negative / trade-off**
- "Architecture" rigor มาจาก **discipline** ไม่ใช่ runtime enforcement — module ละเมิด boundary ได้ถ้า reviewer ไม่จับ → mitigated โดย code-review checklist (TD จะ enforce) + grep guard (`Slot_X.mqh` ห้าม `#include "Slot_Y.mqh"` ตรง)
- ทุก feature ต้อง compile เข้า EA เดียว → recompile time ขึ้นกับ total LOC; mitigated โดย `#ifdef` guard ของ feature flags (TD decide)
- Scaling out (multi-symbol / multi-account) จะต้องใช้ **multi-instance MT5 + separate EA copy** ไม่ใช่ multi-process scaling — acceptable เพราะ Won't (Permanent) ใน `01 § 6.2`

## Revisit-when

- ถ้า user ตัดสินใจ Phase 2 เพิ่ม cloud journal / Telegram alert / multi-symbol → revisit NFR-7.2 (อาจอนุญาต DLL หรือ HTTP via WinAPI native)
- ถ้า MT5 introduce real multi-thread tick (currently single-thread per chart) → revisit BR-9.2 single-thread invariant
- ถ้า total LOC > 25,000 ใน rewrite (rewrite ใหญ่กว่า monolith เดิม) → revisit module split (อาจต้อง 2 file/slot หรือ extract sub-libs)
