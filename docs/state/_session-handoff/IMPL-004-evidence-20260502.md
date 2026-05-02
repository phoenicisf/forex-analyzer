# IMPL-004 Evidence — SlotState.mqh

**Date:** 2026-05-02
**Task:** IMPL-004 — Create `domain/SlotState.mqh`
**Status:** Completed

---

## File Created

| Item | Value |
|------|-------|
| Path | `MQL5/Experts/PhoenicisNex/domain/SlotState.mqh` |
| Line count | 43 lines |
| Include guard | `PHOENICISNEX_DOMAIN_SLOTSTATE_MQH` |
| Dependency | `#include "EnumTypes.mqh"` (IMPL-002, closed) |

---

## 11-Field Count Verification

Fields in `struct SlotState` (counted from source):

| # | Field name | MQL5 type |
|---|-----------|-----------|
| 1 | `magic` | `int` |
| 2 | `slot_ids[]` | `string[]` |
| 3 | `buy_count` | `int` |
| 4 | `sell_count` | `int` |
| 5 | `total_lots` | `double` |
| 6 | `total_profit` | `double` |
| 7 | `last_open_date` | `datetime` |
| 8 | `ticket_ids[]` | `ulong[]` |
| 9 | `ticket_max_profit_pip[]` | `double[]` |
| 10 | `pending_state` | `EPendingState` |
| 11 | `pending_payload` | `string` |

**Total: 11 fields. ✅ Matches TD-02 §3.3 skeleton exactly.**

---

## Field-Mapping Table: YAML Schema ↔ MQL5 Struct

Source schema: `docs/api-specs/state-persistence-schema.yaml § slot_states.<magic>`

| YAML schema name | Required/Optional | MQL5 struct field | Notes |
|-----------------|-------------------|-------------------|-------|
| *(parent map key)* | — | `magic` | **Delta — see below** |
| `slot_ids` | required | `slot_ids[]` | `string[]` array |
| `buy_count` | required | `buy_count` | `int` |
| `sell_count` | required | `sell_count` | `int` |
| `total_lots` | required | `total_lots` | `double` |
| `total_profit` | required | `total_profit` | `double` |
| `last_open_date` | required | `last_open_date` | `datetime` |
| `ticket_ids` | optional | `ticket_ids[]` | `ulong[]` |
| `ticket_max_profit_pip` | optional | `ticket_max_profit_pip[]` | `double[]` — parallel to `ticket_ids[]` |
| `pending_state` *(PendingMachine sub-schema)* | optional | `pending_state` | `EPendingState` enum |
| `pending_payload` *(PendingMachine sub-schema)* | optional | `pending_payload` | `string` |

### Delta: `magic` Denormalization

In `state-persistence-schema.yaml`, the slot state object is stored as a map keyed by magic number
(e.g., `slot_states["200"]`). The `magic` value is therefore the **parent map key**, not a property
of the SlotState object itself in the YAML schema.

In the MQL5 struct, `magic` is kept as a denormalized in-memory field to support O(1) reverse
lookup when iterating slot records without external context (per ADR-005 design note). This is an
acceptable and intentional divergence: the struct is an in-memory representation owned by
`PortfolioState` (CHashMap by magic), not a direct JSON serialization target.

**Verdict:** 1:1 content match. `magic` denormalization is documented and architecturally justified.
`[contract-roundtrip]` E-AC satisfied.

---

## Parallel Array Convention Verification (BR-5.2)

Fields `ticket_ids[]` and `ticket_max_profit_pip[]` are declared **adjacent** in the struct
(fields 8 and 9) to enforce the parallel-array convention required by BR-5.2 trailing per ticket.
Header comment also documents: "Always keep lengths equal."

---

## Verification Commands Run

```bash
# Line count verification
wc -l MQL5/Experts/PhoenicisNex/domain/SlotState.mqh
# Output: 43

# Field count grep
grep -E "^\s+(int|string|double|datetime|ulong|EPendingState)" \
  MQL5/Experts/PhoenicisNex/domain/SlotState.mqh
# Output: 11 matching lines (one per field)

# Include guard check
grep -E "#ifndef|#define|#endif" MQL5/Experts/PhoenicisNex/domain/SlotState.mqh
# Output:
#   #ifndef PHOENICISNEX_DOMAIN_SLOTSTATE_MQH
#   #define PHOENICISNEX_DOMAIN_SLOTSTATE_MQH
#   #endif // PHOENICISNEX_DOMAIN_SLOTSTATE_MQH

# Dependency include check
grep "#include" MQL5/Experts/PhoenicisNex/domain/SlotState.mqh
# Output: #include "EnumTypes.mqh"

# EPendingState confirmed in EnumTypes.mqh (IMPL-002)
grep "EPendingState" MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh
# Output:
#   enum EPendingState {
#   ...
```

---

## G1-G4 Gates

| Gate | Status | Reason |
|------|--------|--------|
| G1 Compile | N/A — skipped | Header-only `.mqh`; compile gate activates at IMPL-018+ when entry `.mq5` exists |
| G2 Smoke | N/A — skipped | Same reason |
| G3 Headless backtest | N/A — skipped | Same reason |
| G4 Log review | N/A — skipped | Same reason |

**Final full-suite run: skipped (header-only)**
**Filtered iteration count: 0**

---

## Acceptance Criteria

| AC | Description | Status |
|----|-------------|--------|
| S-AC-1 | `SlotState` struct มี 11 fields ครบ | ✅ 11 fields verified |
| S-AC-2 | `ticket_max_profit_pip[]` parallel array กับ `ticket_ids[]` (BR-5.2) | ✅ Adjacent declaration; header comment documents invariant |
| S-AC-3 | `slot_ids[]` array (single/multiple entry per magic sharing) | ✅ Declared as `string slot_ids[]`; comment documents shared-magic examples |
| E-AC-1 | Field set = `state-persistence-schema.yaml § slot_states.<magic>` 1:1 `[contract-roundtrip]` | ✅ Field-mapping table above; `magic` denormalization delta documented |
