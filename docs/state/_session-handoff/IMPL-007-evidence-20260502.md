# IMPL-007 Evidence — services/PortfolioState.mqh
**Date:** 2026-05-02
**Task:** IMPL-007 — `services/PortfolioState.mqh` (CHashMap + Refresh + GetByMagic)
**Status:** S-ACs structurally covered; E-ACs deferred (runtime dependency)

---

## Files Created

| File | LOC | Layer | Guard |
|------|-----|-------|-------|
| `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh` | 421 | services/ | `PHOENICISNEX_SERVICES_PORTFOLIOSTATE_MQH` |

Within LOC budget: services 200-800 per `.claude/rules/ea.md`. 421 LOC ✅.

---

## NFR-7.2 Audit — `#import` count

```
PortfolioState.mqh: 0
```

Pass: 0 `#import` directives. Only `#include <Generic\HashMap.mqh>` (MQL5 standard library — permitted per NFR-7.2).

---

## `[Phoenicis]` Prefix Audit

PortfolioState itself does not call `Print()` directly — all log output goes through `m_logger.*()` which routes through `CLogger::FormatLine` (which prepends `[Phoenicis]`). The `portfolio_registered` Info log at RegisterAll() end is the primary audit-visible emission.

Grep pattern for E-AC verification (deferred to IMPL-053+):
```bash
iconv -f UTF-16LE -t UTF-8 <tester-log> | grep -E '\[Phoenicis\].*\[ev=portfolio_registered\]'
```
Expected match: `[Phoenicis][...][INFO][slot=portfolio][ev=portfolio_registered][magic=0] magics registered: 17`

---

## S-AC Coverage

### S-AC 1 — `m_map = CHashMap<int, SlotState*>` stack member; init in Init()
✅ Covered.
- Declaration: `CPortfolioState.mqh` line 50: `CHashMap<int, SlotState *> m_map;` — stack member.
- Init body: line 95: `m_map.Clear();` — clears map on Init, default ctor leaves it clean.
- CHashMap default ctor per ADR-005 directive: stack instance, no `new` needed.

### S-AC 2 — `RegisterAll()` populates 17 entries; explicit list of 17 magics using `MAGIC_*` constants
✅ Covered.
- RegisterAll() body: lines 125-225.
- Magic list literal (lines 133-150): `{MAGIC_CD, MAGIC_F, MAGIC_H, MAGIC_J, MAGIC_K, MAGIC_G, MAGIC_GO, MAGIC_M, MAGIC_L, MAGIC_Q, MAGIC_R, MAGIC_B, MAGIC_BR, MAGIC_I, MAGIC_S, MAGIC_P, MAGIC_T}`.
- Loop `for(int i = 0; i < 17; i++)` heap-allocates SlotState*, populates magic + slot_ids[] + zero-inits aggregates, calls `m_map.Add(magic, s)` + `m_magic_count++`.
- `MagicCount()` at line 71 returns `m_magic_count` — asserted == 17 by BootstrapValidator (IMPL-016+).

### S-AC 3 — `GetByMagic(int)` returns NULL for non-registered + Logger Warn
✅ Covered.
- GetByMagic() body: lines 245-260.
- `m_map.TryGetValue(magic, s)` returns false for unregistered magic.
- On false: `m_logger.Warn("portfolio", "magic_not_registered", magic, "")` + return NULL.
- Exact warn signature matches impl-plan.md S-AC: `m_logger.Warn("portfolio","magic_not_registered",magic,"")`.

### S-AC 4 — `Refresh()` body: skeleton + TODO stub
✅ Covered (stub accepted per shared-context §6.B directive).
- Refresh() body: lines 270-320.
- Step 1 reset loop (buy_count, sell_count, total_lots, total_profit, ticket_ids[], ticket_max_profit_pip[]) present and functional.
- Step 2 deferred: `// TODO IMPL-007-refresh` comment with full implementation sketch.

---

## Magic Count Audit — 17 Magics vs EnumTypes.mqh Constants

| # | MAGIC_* constant | Value | slot_ids[] | Type |
|---|-----------------|-------|------------|------|
| 1 | MAGIC_CD | 200 | ["C","D"] | shared (C/D pool) |
| 2 | MAGIC_F | 201 | ["F"] | unique |
| 3 | MAGIC_H | 205 | ["H"] | unique |
| 4 | MAGIC_J | 206 | ["J"] | unique (⚠️ BR-7.2) |
| 5 | MAGIC_K | 207 | ["K"] | unique |
| 6 | MAGIC_G | 208 | ["G","G2"] | shared (G/G2) |
| 7 | MAGIC_GO | 209 | ["GO"] | unique |
| 8 | MAGIC_M | 210 | ["M"] | unique |
| 9 | MAGIC_L | 211 | ["L","LX"] | shared (L/LX) |
| 10 | MAGIC_Q | 212 | ["Q"] | unique |
| 11 | MAGIC_R | 213 | ["R"] | unique |
| 12 | MAGIC_B | 214 | ["B","BI"] | shared (B/BI) |
| 13 | MAGIC_BR | 215 | ["BR"] | unique |
| 14 | MAGIC_I | 216 | ["I"] | unique |
| 15 | MAGIC_S | 217 | ["S"] | unique |
| 16 | MAGIC_P | 218 | ["P"] | unique |
| 17 | MAGIC_T | 219 | ["T"] | unique |

Total: **17 distinct magics** ✅ — matches BR-1.1 (21 slots − 4 shared pairs = 17).

Slot U (magic 220) confirmed absent per OQ-8 (deleted 2026-05-01). ✅

Shared-magic pairs in RegisterAll() slot_ids assignments:
- 200 → ["C","D"]   (ADR-005 § Decision row 1) ✅
- 208 → ["G","G2"]  (ADR-005 § Decision row 2) ✅
- 211 → ["L","LX"]  (ADR-005 § Decision row 3) ✅
- 214 → ["B","BI"]  (ADR-005 § Decision row 4) ✅

---

## E-AC Deferral Notes (mirror IMPL-042 pattern)

### E-AC 1 — `[log-assertion]` "magics registered: 17"
**Deferred** until Orchestrator (IMPL-053+) exists and wires `Init()` → `RegisterAll()`.
PortfolioState.RegisterAll() emits:
```
m_logger.Info("portfolio","portfolio_registered",0,"magics registered: 17")
```
which CLogger.FormatLine() renders as:
```
[Phoenicis][YYYY-MM-DD HH:MM:SS.mmm][INFO][slot=portfolio][ev=portfolio_registered][magic=0] magics registered: 17
```
Verification command (post-IMPL-053+):
```bash
iconv -f UTF-16LE -t UTF-8 <tester-log> \
  | grep -E '\[Phoenicis\].*\[ev=portfolio_registered\].*magics registered: 17'
```

### E-AC 2 — `[db-inspect]` mock-position Refresh check
**Deferred** until entry `.mq5` (IMPL-018+) + Strategy Tester run (IMPL-053+).
Refresh() step 1 (aggregate reset) is structurally complete. Step 2 (PositionsTotal() broker loop) is documented as `// TODO IMPL-007-refresh` with full implementation sketch. The headless backtest run will populate ticket_ids[] via the step-2 loop and the db-inspect E-AC can verify:
```bash
jq 'select(.event_type=="entry") | {slot_id, magic, ticket_id}' journal/tester/run-*.jsonl
```

---

## Self-Review Checklist (shared-context §6.G)

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Security: no hardcoded secrets; `_Symbol` only in Refresh/CreateHandles not header | ✅ | No `_Symbol`, no secrets. `PositionSelectByTicket` in TODO sketch only. |
| 2 | Business logic: matches all S-AC checkboxes | ✅ | All 4 S-ACs covered above |
| 3 | Error handling: fail-fast booleans; no silent swallow | ✅ | GetByMagic returns NULL + Warn; RegisterAll default-case Warns for unknown magic |
| 4 | Performance: no allocation inside Refresh() hot path | ✅ | ArrayResize() in Refresh step 1 resets to size 0 (shrink, O(1)); step-2 alloc in TODO only |
| 5 | Over-engineering: header-only; no extra utility classes | ✅ | Single class, no extra helpers |
| 6 | Tests: G1-G4 deferred; SelfTest N/A (data-dependent) | ✅ | Per IMPL-042 precedent; G1-G4 deferred to IMPL-018+ |
| 7 | Naming: `m_*` members; PascalCase public; include-guard correct | ✅ | `m_map`, `m_magic_list`, `m_magic_count`, `m_logger`; all public methods PascalCase |

---

## Architecture Compliance

| Rule | Status |
|------|--------|
| 5-layer `#include` direction: `services/` → `domain/` + `helpers/` only | ✅ Includes: `<Generic\HashMap.mqh>`, `../domain/EnumTypes.mqh`, `../domain/SlotState.mqh`, `services/Logger.mqh` |
| `slots/*` NOT included (ADR-012) | ✅ No slot includes |
| Include guard `PHOENICISNEX_SERVICES_PORTFOLIOSTATE_MQH` | ✅ |
| Member naming `m_*` | ✅ All 4 private members use `m_` prefix |
| Methods PascalCase public | ✅ |
| No `#import` (NFR-7.2) | ✅ 0 `#import` directives |
| LOC budget 200-800 for services | ✅ 421 LOC |
| CommentParser not included (stub body) | ✅ `GetTicketsForSlot` body stubbed with `// TODO IMPL-007-getticketsforslot` |
| No `new CHashMap()` — stack instance | ✅ `CHashMap<int, SlotState *> m_map;` stack member |

---

## Design Decisions

### Default constructor approach
MQL5 CHashMap has a default constructor; `m_map` declared as stack member — no `new CHashMap()` needed (per ADR-005 directive). `Init()` calls `m_map.Clear()` to ensure clean state on re-init.

### Refresh() step 1 uses ArrayResize to 0
`ArrayResize(s.ticket_ids, 0)` and `ArrayResize(s.ticket_max_profit_pip, 0)` shrink arrays to empty without deallocation overhead. This is the correct MQL5 pattern for resetting dynamic arrays in a hot path.

### GetTicketsForSlot const correctness
Method declared `const` per TD-02 §5.3 skeleton. `m_logger` pointer is mutable through indirection so const method can call `m_logger.Warn()` correctly — const applies to `this` pointer, not the pointed-to logger object.

### TotalActivePositions and TotalFloatingPL iterate m_magic_list
Both use `m_map.TryGetValue(m_magic_list[i], s)` iteration pattern (same as Refresh step 1) for consistency and to avoid m_map key enumeration which CHashMap may not support directly.

---

## Next Steps

- **IMPL-053** (Orchestrator): wire `m_portfolio.Init(m_logger)` + `m_portfolio.RegisterAll()` → closes E-AC 1 (`[log-assertion]` magics registered: 17).
- **IMPL-018+** (entry `.mq5`): enables G1-G4 gate execution → closes E-AC 2 via headless backtest.
- **IMPL-016** (BootstrapValidator::ValidateSymbol): `ValidateSlotRegistry(m_portfolio.MagicCount(), 17)` asserts invariant.
- **IMPL-007-refresh** TODO: implement `PositionsTotal()` loop at IMPL-053+ orchestrator wire-up.
- **IMPL-007-getticketsforslot** TODO: implement via `CCommentParser::FilterTicketsByPrefix` at IMPL-053+.
