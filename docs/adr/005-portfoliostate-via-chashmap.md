# ADR-005 — PortfolioState via CHashMap Keyed by Magic

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G1, G3, FR-2.7, AC-2.7.1, AC-2.7.2, BR-1.1 |

## Context

EA เดิมเก็บ per-slot state ใน **global variable swarm** (`BuyOrders__C`, `SellOrders__C`, `LotsC`, `ProfitC`, `LastOpenDateC`, ฯลฯ — กระจาย 18 families ตาม CodeWiki §2.4) ที่ refresh โดย `ReadTradeData` ทุก tick. FR-2.7 + AC-2.7.2 บังคับ O(1) lookup โดย magic + ห้าม iterate slot เดียวต้องผ่าน global swarm ทั้งหมด

MQL5 standard library มี `CHashMap<TKey, TValue>` ใน `<Generic\HashMap.mqh>` — generic associative container ที่รองรับ int key. คำถาม: data structure + refresh strategy

## Options Considered

### Option A — `CHashMap<int, SlotState*>` keyed by magic (chosen)

```mql5
struct SlotState {
   int      magic;
   string   slot_id;        // "C", "G", "BI", ...
   int      buy_count;
   int      sell_count;
   double   total_lots;
   double   total_profit;
   datetime last_open_date;
   EPendingState pending_state;
   string   pending_payload; // CPendingComment, MPendingAtPrice serialized, etc.
   int      ticket_ids[];   // active position tickets ของ slot
};

CHashMap<int, SlotState*> g_portfolio;
```

`PortfolioRefresher::Refresh()` (replacement สำหรับ `ReadTradeData`) ทำงาน 1 ครั้งต่อ tick:
1. Reset all `SlotState.buy_count/sell_count/total_lots/total_profit/ticket_ids[]` ของทุก entry
2. Loop `PositionsTotal()` ครั้งเดียว → for each position: lookup `g_portfolio[position.Magic()]`; ถ้าเจอ → update fields; ถ้าไม่เจอ → log warning (magic ที่ EA ไม่รู้จัก)
3. `last_open_date` + `pending_state` + `pending_payload` ไม่ reset (per-slot state machine maintain เอง ผ่าน `slot.UpdatePersistentState()`)

Slot อ่าน: `SlotState *me = port.GetByMagic(MagicC);  // O(1)`

### Option B — Sparse array indexed by `magic - 200` (range 200..220)

**Rejected:** Magic range tightly coupled — Phase 2 ถ้า extend range > 220 ต้อง resize; ทำ shared-magic disambiguation (G/G2, B/BI ใช้ magic เดียวกัน) ลำบาก (ต้อง fold สอง slot เข้า entry เดียว → ขัด FR-2.7 1 slot 1 entry)

### Option C — Per-slot field stored inside slot instance

```mql5
class CSlotBase { ...; SlotState m_state; };
```

**Rejected:** Cross-slot read (เช่น Slot J ต้องอ่าน CD's `total_lots` per BR-2.1) ลำบาก — ต้องผ่าน `slotRegistry.Get("CD").GetState()` overhead ของ string lookup; ขัด AC-2.7.2 O(1) target

## Decision

เลือก **Option A — `CHashMap<int, SlotState*>` keyed by magic**, owned by `PortfolioState` service

**Refresh contract:**
- `void PortfolioState::Refresh()` ที่ OnTick step `H` (ดู F1) — replaces EA เดิม `ReadTradeData`
- Single `PositionsTotal()` loop — O(N) where N = open position count (ปกติ ≤ 50)
- Lookup ผ่าน `SlotState *PortfolioState::GetByMagic(int magic)` = O(1) average

**Shared-magic handling (BR-1.1):**
- G/G2 share `MagicG` (=208), B/BI share `MagicB` (=214), C/D share `MagicCD` (=200), L/LX share `MagicL` (=211)
- `g_portfolio` มี 1 entry ต่อ magic (= **17 entries** รวม, ไม่ใช่ 21) — ทุก position ของ shared magic นับรวมใน entry เดียว. Pool: 200, 201, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219 (= 21 slots − 4 shared groups (C/D + G/G2 + B/BI + L/LX))
- Slot ที่ต้องแยก position ของตัวเองออกจาก sibling (G2 vs G, BI vs B) อ่าน `SlotState.ticket_ids[]` แล้ว filter ผ่าน position comment prefix (BR-1.2 "G,..." vs "G2,...") — ใช้ helper `PortfolioState::GetTicketsForSlot(int magic, string slot_prefix)`
- Trade journal record (FR-4.1) ใช้ `slot_id` field (ของ caller slot) แยก disambiguation ที่ record level ไม่ใช่ portfolio level

## Consequences

**Positive**
- O(1) lookup (AC-2.7.2)
- Single refresh point — ไม่มี state staleness ใน tick เดียว
- Shared-magic preserve 1:1 (BR-1.1) ขณะ slot ยัง observe own positions ผ่าน comment prefix
- Adding slot Phase 2 = new entry ใน `CHashMap` + new comment prefix discipline — no schema migration

**Negative / trade-off**
- `CHashMap` allocate `SlotState*` on heap → memory fragmentation possible สำหรับ long-running EA (months) — mitigated ด้วย entry count ที่ fixed ตอน OnInit (ไม่มี dynamic add/remove) + `ReleaseAll()` ใน OnDeinit
- Comment prefix parsing สำหรับ shared-magic = brittle (BR-1.2) — mitigated โดย centralized `CommentParser` helper ที่ทุก slot ที่ shared magic ใช้ (TD enforce)
- ลำดับ `Refresh()` ก่อน slot evaluate ต้องตรงตาม F1 step `H` — ถ้า slot อ่าน PortfolioState ก่อน Refresh = stale; mitigated ผ่าน orchestrator pipeline order (BR-2.2)

## Revisit-when

- ถ้า measured `Refresh()` ที่ N=200 positions > 1 ms → revisit batched diff (incremental update แทน reset+loop)
- ถ้า Phase 2 resolve shared-magic conflict (assign G2 own magic) → revisit comment-parser dependency; ลด complexity
- ถ้า MQL5 introduce concurrent OnTick (ไม่น่ามี) → revisit thread-safety ของ CHashMap
