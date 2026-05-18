# ADR-012 — File Layout & Module Split Discipline

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G1, NFR-4.1 (≤5,000 LOC/file), NFR-4.2 (1:1 slot:file), NFR-4.3 (≥80 inputs), C-12 |

## Context

ADR-001 lock architecture style = modular monolith intra-process. ADR-002 lock slot abstraction = OO inheritance, 1 file per slot. แต่ "file layout" = layered concern ที่ต้องตัดสินใจรวมๆ:
- Folder structure
- `#include` graph + boundary rules
- Input parameter file ownership
- Library separation (re-use ของ EA เดิม `LibCommon1.1`, `LibIndicator1.1`, `LibSubDem1.6`, `LibDatabase1.1`, `LibMonitor1.1`)
- Compile output structure

## Options Considered

### Option A — Flat single-file (rejected)
ของเดิม monolith pattern. Reject — ขัด NFR-4.1/4.2

### Option B — Layered directory tree (chosen)
Mirror DDD-style layering inside `MQL5/Experts/PhoenicisNex/`

### Option C — Per-slot subfolder (each slot = own folder with helpers)
**Rejected:** Over-fragmentation; helpers ของ slot มักเล็ก (< 100 LOC) ไม่คุ้ม folder overhead

## Decision

เลือก **Option B — layered directory tree**

**Folder structure (commit):**

```
MQL5/Experts/PhoenicisNex/
├── PhoenicisNex.mq5                # entry point: OnInit, OnTick, OnDeinit, OnTester
│                                   # ≤ 500 LOC; calls into orchestrator
├── inputs/
│   ├── Inputs_General.mqh          # cross-slot inputs (FIDValue, MainRiskRatio, LimitMaxLotSizeRatio, ...)
│   ├── Inputs_TimeGates.mqh        # IsMorningWakeup window, holiday range, DST handling
│   ├── Inputs_Slot_<X>.mqh         # 21 input files (1 per slot) — group="Slot X" annotation
│   ├── Inputs_Logging.mqh          # InpLogLevel, InpAlertOnError, InpJournalRotation
│   └── Inputs_Pending.mqh          # InpForceClearM_Bars, InpForceClearT_Bars, InpForceClearQ_Bars
├── core/
│   ├── Orchestrator.mqh            # SlotOrchestrator class — runs OnTick pipeline (F1)
│   ├── BootstrapValidator.mqh      # OnInit: validate inputs, symbol whitelist, indicator handles
│   ├── SlotRegistry.mqh            # registers 21 CSlotBase* + topo-sort validation
│   └── EAState.mqh                 # RUNNING/HALTED/HALTED_STABLE state machine (ADR-010)
├── slots/
│   ├── Slot_C.mqh                  # 21 slot files; 1 file per slot (NFR-4.2)
│   ├── Slot_D.mqh
│   ├── Slot_F.mqh
│   ├── Slot_J.mqh
│   ├── Slot_H.mqh
│   ├── Slot_K.mqh
│   ├── Slot_G.mqh
│   ├── Slot_G2.mqh
│   ├── Slot_GO.mqh
│   ├── Slot_M.mqh
│   ├── Slot_L.mqh
│   ├── Slot_LX.mqh
│   ├── Slot_Q.mqh
│   ├── Slot_R.mqh
│   ├── Slot_I.mqh
│   ├── Slot_P.mqh
│   ├── Slot_T.mqh
│   ├── Slot_S.mqh
│   ├── Slot_B.mqh
│   ├── Slot_BR.mqh
│   └── Slot_BI.mqh
├── services/
│   ├── IndicatorService.mqh        # ADR-003 — ~25 handle owner + cache (TD spike Phase 1D locks exact count)
│   ├── MarketContextBuilder.mqh    # ADR-004 — build immutable snapshot
│   ├── PortfolioState.mqh          # ADR-005 — CHashMap-based state lookup
│   ├── RiskManager.mqh             # FR-3.1/3.6 — lot calc + clamp
│   ├── TradeJournal.mqh            # ADR-006 — JSON-Lines append-only
│   ├── StatePersistence.mqh        # ADR-007 — atomic temp + rename
│   ├── Logger.mqh                  # ADR-011 — tagged structured logger
│   # CircuitBreaker.mqh REMOVED per BT-002 2026-05-17 (legacy-parity; see ADR-010 § Revision history)
│   ├── TimeGate.mqh                # FR-6.1/6.2/6.3/6.5 — IsMorningWakeup, Monday spread, holiday, DST
│   ├── PendingMachineRegistry.mqh  # 7 pending state machines + ADR-008 force-clear
│   ├── CrossSlotCoordinator.mqh    # FR-7.1 ถึง FR-7.5 — Safe port, OrderGroup#2, ForceCutloss, ExtraCheckFunction2, Overload helpers
│   └── PortfolioMonitor.mqh        # FR-4.4 — WatchProfits replacement (worst DD bookkeeping)
├── domain/
│   ├── MarketContext.mqh           # struct definition (ADR-004 schema)
│   ├── SlotState.mqh               # struct definition (ADR-005 schema)
│   ├── EnumTypes.mqh               # EEAState, EPendingState, ESeverity, ESlotId, ...
│   └── CSlotBase.mqh               # abstract slot interface (ADR-002)
├── helpers/
│   ├── CommentParser.mqh           # shared-magic disambiguation (BR-1.2)
│   ├── PipMath.mqh                 # DigitMultipier-aware pip arithmetic (ADR-009)
│   ├── JsonWriter.mqh              # JSON-Lines serialization (ADR-006)
│   └── AtomicFile.mqh              # FileMove-based atomic write (ADR-007)
└── libs/
    └── (preserve EA เดิม libs that ยัง use ผ่าน MT5 #include path)
```

**Total file count estimate:** 21 slot + 5 inputs + 4 core + 11 services + 4 domain + 5 helpers + entry = **~50 files** <!-- TD Round 09 Finding 09.1/09.2 cascade-completion 2026-05-18: services 13→11 (pre-BT-002 narrative was off-by-one vs file tree; post-BT-002 empirical = 11 per TD-02 § 2 L58-69 + § 5.1-5.12 minus struck 5.8) + helpers 4→5 (Timestamp.mqh ADR-006/011 ms-precision wiring per IMPL-FIX-009 not previously counted in ADR enumeration); total ~52→~50 -->

**LOC budget per file (NFR-4.1 ≤ 5,000 LOC):**
- `Slot_<X>.mqh`: avg 800-2,000 LOC; max 5,000 (some complex slots like P, B, M); split sub-helpers ออกถ้า > 5,000
- `services/`: avg 200-800 LOC per file
- `core/`, `domain/`, `helpers/`: ≤ 500 LOC per file
- `Inputs_*.mqh`: ≤ 200 LOC per file (declarations only)
- `PhoenicisNex.mq5`: ≤ 500 LOC (entry-point thin wrapper)

**Total project LOC estimate:** ~25,000-30,000 (slightly larger than EA เดิม 22,016 LOC due to abstraction overhead — acceptable per G1 trade-off)

**`#include` graph rules:**
- `slots/*.mqh` ห้าม `#include "slots/<other>"` — slot-to-slot reference ผ่าน `SlotRegistry.GetByMagic()` หรือ `PortfolioState.GetByMagic()` only
- `slots/*.mqh` may `#include "services/*"`, `domain/*`, `helpers/*`
- `services/*.mqh` ห้าม `#include "slots/*"` — service-to-slot dependency = wrong direction
- `domain/*.mqh` ห้าม `#include "services/*"` หรือ `slots/*` — domain = pure types
- `helpers/*.mqh` ห้าม `#include "services/*"` หรือ `slots/*` — helpers = pure utility
- `core/Orchestrator.mqh` คือ composition root — `#include` ทุก service + slot

**Enforcement (TD checklist):**
- Pre-commit grep guard: ตรวจ `slots/Slot_X.mqh` ห้ามมี `#include` matching `"slots/Slot_(?!X)"` pattern
- Reviewer check: layered direction (slots → services → domain/helpers)

## Consequences

**Positive**
- AI agent + human reviewer ทำงานทีละ slot ได้ — open `Slot_C.mqh` + `Inputs_Slot_C.mqh` ก็พอ
- Inputs grouped per slot (NFR-6.3) → MT5 input dialog auto-group ผ่าน `group="..."` annotation
- Layering enforce service contracts; refactor service ไม่ touch slot
- ≥ 80 inputs spread across 5 input files (NFR-4.3 + manageable per file)

**Negative / trade-off**
- 52 files = `#include` boilerplate + recompile time longer; estimated 3-8s vs EA เดิม ~1s — acceptable for live; affects backtest sweep iterations
- Discipline burden — reviewer ต้อง enforce `#include` direction
- Total LOC slightly > EA เดิม (acceptable per G1)

## Revisit-when

- ถ้า slot file > 5,000 LOC → split สู่ `Slot_X_Entry.mqh` + `Slot_X_Exit.mqh`
- ถ้า input count > 150 → revisit input file split granularity
- ถ้า recompile time > 30s → introduce precompiled headers / partial recompile (MQL5 limited support)
