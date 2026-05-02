# ADR-002 — Slot Abstraction via OO Inheritance (CSlotBase)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G1, G3, FR-2.5, FR-2.4, NFR-4.2 |

## Context

EA เดิมใช้ **free-function pair** `BusinessLogic_<X>()` + `ExtraTakeProfit_<X>()` กระจายใน 22k LOC monolith — ทุก function อ่าน/เขียน global variable swarm; orchestrator เรียก function ตามชื่อ (no abstraction). FR-2.5 ต้องการ slot abstraction ที่ orchestrator interact ผ่าน behavior contract ชุดเดียวกัน + FR-2.4 ต้องการ explicit `dependsOn()` edges. NFR-4.2 = 1 file/slot (21 ไฟล์ slot ใน rewrite)

MQL5 รองรับ OO (class, inheritance, virtual, abstract via `=0` is **not** supported — แทนด้วย empty default + override discipline). คำถาม: behavior contract ระหว่าง orchestrator ↔ slot ใช้ pattern ไหน

## Options Considered

### Option A — OO inheritance: `CSlotBase` abstract + 21 derived classes (chosen)

```mql5
class CSlotBase {
public:
   virtual int    Magic() const = 0;          // pure-equivalent (override discipline)
   virtual string SlotId() const = 0;
   virtual void   Evaluate(const MarketContext &ctx, PortfolioState &port) = 0;
   virtual void   ManageExits(PortfolioState &port) = 0;
   virtual int    DependsOn(int &out_magics[]) = 0;
   virtual EPendingState PendingState() const = 0;
};

class CSlot_C : public CSlotBase { /* C-specific implementation */ };
class CSlot_J : public CSlotBase { /* J-specific implementation */ };
// ... 21 derived classes total
```

Orchestrator ถือ `CSlotBase *slots[]` array; iterate ผ่าน virtual call

### Option B — Function-pointer table + per-slot static struct

```mql5
struct SlotVTable {
   int magic;
   void (*evaluate)(const MarketContext&, PortfolioState&);
   void (*manage_exits)(PortfolioState&);
   ...
};
SlotVTable g_slots[] = { ... };
```

**Rejected:** MQL5 ไม่ support function pointer to free functions (รองรับเฉพาะ method pointer ของ class) — pattern นี้ทำใน MQL5 ไม่ได้แบบ native

### Option C — Template-based "concept" (compile-time polymorphism)

**Rejected:** MQL5 templates รองรับ generic container (CHashMap<K,V>) แต่ไม่รองรับ duck-typed concept; ทำ slot orchestration ผ่าน template ไม่ได้แบบที่ C++ ทำได้

## Decision

เลือก **Option A — `CSlotBase` abstract + 21 derived classes**, 1 file ต่อ class (`Slot_C.mqh` ... `Slot_BI.mqh`)

**Why:** Native MQL5 idiom + รองรับ FR-2.5 (uniform contract) + FR-2.4 (explicit dependsOn) + NFR-4.2 (1 file/slot) ตรงๆ; orchestrator ไม่ต้องรู้ slot-specific logic ใดๆ

**Decision detail:**
- Method `Evaluate()` runs entry pass (FR-2.3 entry pipeline)
- Method `ManageExits()` runs exit pass (FR-2.3 exit pipeline)
- Method `DependsOn(int &out[])` populate array of magic numbers ที่ slot นี้ depend on (BR-2.1 dependency table); orchestrator ใช้ตอน topo-sort validate
- Method `PendingState()` คืน enum {IDLE, PENDING, EXECUTED} — ใช้ตอน slot.Evaluate() เพื่อ branch ไป pending sub-flow (F4)
- Constructor injection: `CSlotBase` รับ `IndicatorService*`, `RiskManager*`, `TradeJournal*`, `Logger*`, `StatePersistence*` ผ่าน constructor — ห้ามใช้ global singleton

**Pure-virtual override enforcement (concrete mechanism — replaces "discipline only"):**

MQL5 ไม่รองรับ `=0` pure virtual = compile-time enforcement ทำไม่ได้. แต่ "missing override" ห้ามเป็น silent no-op (เพราะ `Slot_<X>::Evaluate()` ที่ derived ไม่ override → base no-op = signal evaluation skip = orphan positions). ใช้ **2-layer enforcement** เพื่อให้ failure loud + early:

| Layer | Mechanism | Detection point | Behavior on miss |
|-------|-----------|-----------------|-------------------|
| **Boot-time (primary)** | `SlotRegistry::ValidateTopo()` หลัง `RegisterAll()` — call `slot.Magic()` + `slot.SlotId()` ของทุก entry | OnInit | If returns sentinel value (Magic == `-1`, SlotId == `""`) → `INIT_FAILED` (NFR-3.2 fail-fast); EA ไม่ load — user เห็น dialog error ทันที |
| **Runtime (secondary)** | Base `CSlotBase::Evaluate / ManageExits / DependsOn / PendingState` body = `Logger::Error("CSlotBase","missing_override",magic,method_name) + ExpertRemove()` | First tick after attach | EA terminate + Alert popup; user เห็นผ่าน MT5 Experts log ทันที — **ไม่มี silent path** |

**Concrete base class default (TD lock ใน IMPL-018):**
```mql5
class CSlotBase {
public:
   virtual int    Magic()  const { return -1; }      // sentinel — boot-time check catches
   virtual string SlotId() const { return "";   }    // sentinel — boot-time check catches
   virtual void Evaluate(const MarketContext &ctx, PortfolioState &port) {
      m_logger.Error("CSlotBase","missing_override", Magic(), "Evaluate");
      ExpertRemove();   // runtime guarantee — never silent
   }
   virtual void ManageExits(PortfolioState &port) {
      m_logger.Error("CSlotBase","missing_override", Magic(), "ManageExits");
      ExpertRemove();
   }
   virtual int    DependsOn(int &out[]) {
      m_logger.Error("CSlotBase","missing_override", Magic(), "DependsOn");
      ExpertRemove();
      return 0;
   }
   virtual EPendingState PendingState() const { return IDLE; }   // safe default
};
```

**SlotRegistry boot-time check:**
```mql5
bool SlotRegistry::ValidateTopo() {
   for (int i=0; i<ArraySize(m_slots); i++) {
      if (m_slots[i].Magic() == -1 || m_slots[i].SlotId() == "") {
         m_logger.Error("SlotRegistry","slot_missing_override", i, "derived class did not override Magic/SlotId");
         return false;   // → orchestrator returns INIT_FAILED
      }
   }
   // ... existing topo-sort dependency validation
   return true;
}
```

**ทำไมไม่ใช้ static_assert / compile-time:** MQL5 รองรับ `static_assert` จำกัด (only on integer constants); ไม่สามารถ enforce method-override ผ่าน compile-time ได้

## Consequences

**Positive**
- 1 file/slot — refactor 1 slot ไม่ touch slot อื่น (G1 ตรงๆ)
- AI agent + reviewer อ่าน `Slot_C.mqh` แค่ไฟล์เดียวเข้าใจ slot C ครบ
- Adding new slot (Phase 2) = สร้าง class ใหม่ + register ใน `SlotRegistry::RegisterAll()` — ไม่ต้องแก้ orchestrator (AC-2.5.3)
- Mockable สำหรับ test (แต่ MQL5 unit testing limited — QA ใช้ Strategy Tester, ดู P4.8)

**Negative / trade-off**
- Virtual call overhead ~20-50 ns per call (negligible ที่ tick-rate); 21 slots × 2 methods/tick × 50 ns = ~2 µs total → << 10% NFR-2.1 budget
- MQL5 ไม่มี `=0` pure virtual = compile-time enforcement ทำไม่ได้ — mitigated ผ่าน 2-layer enforcement (boot-time SlotRegistry::ValidateTopo + runtime base-method ExpertRemove; ดู § Decision detail). Reviewer checklist ลง backup
- Constructor injection ต้องการ orchestrator เป็น composition root — มี boilerplate ตอน OnInit; acceptable

## Revisit-when

- ถ้าวัด virtual call overhead จริงแล้ว > 5% tick latency → revisit ใช้ static dispatch (template specialization)
- ถ้าจำนวน slot > 30 (Phase 2 expansion) → revisit slot loading model (ก่อน load ทั้ง 30 instance ตอน OnInit อาจช้า) — แก้ด้วย lazy init
