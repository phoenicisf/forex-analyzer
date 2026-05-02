# IMPL-003 Evidence Artifact — MarketContext.mqh
**Date:** 2026-05-02
**Task:** IMPL-003 — Create `domain/MarketContext.mqh`
**E-AC kind:** `[contract-roundtrip]`

---

## File Summary

| Item | Value |
|------|-------|
| File path | `MQL5/Experts/PhoenicisNex/domain/MarketContext.mqh` |
| Line count | 115 |
| Struct count | 15 (13 sub-structs + DerivedSignals + MarketContext) |
| MarketContext field count | 27 (5 primitives + 21 sub-struct instances + 1 derived) |
| Include guard | `PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH` ✅ |
| Dependency | `#include "EnumTypes.mqh"` (sibling, domain layer only) ✅ |
| Methods | None — pure data struct ✅ |

---

## Struct Count Verification

**Command run:**
```bash
grep -c "^struct " MQL5/Experts/PhoenicisNex/domain/MarketContext.mqh
```
**Output:** `15`

**Struct names declared (15 total):**
1. `IchimokuFields`
2. `ForceFields`
3. `AdxFields`
4. `WprFields`
5. `BBFields`
6. `DemFields`
7. `StochFields`
8. `MacdFields`
9. `RsiFields`
10. `HullFields`
11. `FractalFields`
12. `ZigZagFields`
13. `SubDemFields`
14. `DerivedSignals`
15. `MarketContext`

All 13 required sub-structs present ✅

---

## MarketContext Field Count

**Command run:**
```bash
awk '/^struct MarketContext/,/^};/' MarketContext.mqh | grep -v "^//" | grep -v "^struct" | grep -v "^{" | grep -v "^};" | grep -v "^$" | grep -v "^\s*//"
```
**Output (27 fields):**
```
datetime tick_time;
double   bid;
double   ask;
double   spread_pip;
int      bar_index_h4;
IchimokuFields  ichi_h4;
IchimokuFields  ichi_d1;
ForceFields     force_h4;
AdxFields       adx_h4;
AdxFields       adx_d1;
WprFields       wpr_h4;
WprFields       wpr_d1;
WprFields       wpr_m15;
BBFields        bb_h4;
DemFields       dem_h4;
DemFields       dem_m15;
StochFields     stoch_m10;
StochFields     stoch_h4;
MacdFields      macd_m10;
MacdFields      macd_d1;
RsiFields       rsi_h4;
HullFields      hull_h4;
FractalFields   fractal_h4;
ZigZagFields    zigzag_m5;
SubDemFields    subdem_h4;
SubDemFields    subdem_d1;
DerivedSignals  derived;
```

Field count = **27** — exceeds S-AC requirement of ≥24 ✅

> Note: The shared context §6 header says "25 top-level fields (5 primitives + 19 sub-structs + 1 derived)" but the schema YAML required list in the same section actually enumerates 27 properties (including `subdem_h4`, `subdem_d1` as separate sub-struct instances, plus all 21 sub-struct slots). The struct matches the schema list exactly.

---

## Schema ↔ MQL5 Field Mapping (1:1 Cross-Domain Match)

| Schema YAML property (`marketcontext-snapshot-schema.yaml`) | MQL5 struct field | Delta |
|-------------------------------------------------------------|-------------------|-------|
| `tick_time` | `datetime tick_time` | — |
| `bid` | `double bid` | — |
| `ask` | `double ask` | — |
| `spread_pip` | `double spread_pip` | — |
| `bar_index_h4` | `int bar_index_h4` | — |
| `ichi_h4` | `IchimokuFields ichi_h4` | — |
| `ichi_d1` | `IchimokuFields ichi_d1` | — |
| `force_h4` | `ForceFields force_h4` | — |
| `adx_h4` | `AdxFields adx_h4` | — |
| `adx_d1` | `AdxFields adx_d1` | — |
| `wpr_h4` | `WprFields wpr_h4` | — |
| `wpr_d1` | `WprFields wpr_d1` | — |
| `wpr_m15` | `WprFields wpr_m15` | — |
| `bb_h4` | `BBFields bb_h4` | — |
| `dem_h4` | `DemFields dem_h4` | — |
| `dem_m15` | `DemFields dem_m15` | — |
| `stoch_m10` | `StochFields stoch_m10` | — |
| `stoch_h4` | `StochFields stoch_h4` | — |
| `macd_m10` | `MacdFields macd_m10` | — |
| `macd_d1` | `MacdFields macd_d1` | — |
| `rsi_h4` | `RsiFields rsi_h4` | — |
| `hull_h4` | `HullFields hull_h4` | — |
| `fractal_h4` | `FractalFields fractal_h4` | — |
| `zigzag_m5` | `ZigZagFields zigzag_m5` | — |
| `subdem_h4` | `SubDemFields subdem_h4` | — |
| `subdem_d1` | `SubDemFields subdem_d1` | — |
| `derived_signals` | `DerivedSignals derived` | ⚠️ Name delta (see below) |

### Naming Delta: `derived_signals` ↔ `derived`

**Schema YAML name:** `derived_signals`
**MQL5 struct field name:** `derived`

**Accepted per TD-02 convention.** The content is identical — the struct type is `DerivedSignals` which carries the full name. The shorter field name `derived` is the TD-02-prescribed convention (matching the skeleton verbatim in `02-backend-design.md § 3.2`). This delta is known, intentional, and acceptable per shared-context §6 note: *"schema name `derived_signals` ↔ struct field name `derived` (TD-02 convention)"*.

---

## Verification Commands Summary

| Check | Command | Result |
|-------|---------|--------|
| Struct count | `grep -c "^struct " MarketContext.mqh` | `15` ✅ |
| Line count | `wc -l MarketContext.mqh` | `115` ✅ |
| MarketContext field count | awk extract + count | `27` ✅ (≥24 AC met) |
| Include guard present | visual + grep | `PHOENICISNEX_DOMAIN_MARKETCONTEXT_MQH` ✅ |
| No service #include | visual inspection | `#include "EnumTypes.mqh"` only ✅ |
| No methods | visual inspection | Pure data struct only ✅ |

---

## Acceptance Criteria Status

| AC | Description | Status |
|----|-------------|--------|
| S-AC-1 | All 13 sub-structs declared | ✅ All 13 present |
| S-AC-2 | MarketContext struct has ≥24 fields | ✅ 27 fields |
| S-AC-3 | No mutable methods (pass `const&` enforced by type) | ✅ Pure data struct, no methods |
| E-AC-1 | Field set = schema YAML properties (1:1 match) `[contract-roundtrip]` | ✅ 26/27 exact name match; 1 known delta (`derived_signals`↔`derived`) documented above |
