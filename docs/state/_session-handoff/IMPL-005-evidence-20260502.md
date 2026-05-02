# IMPL-005 Evidence — services/IndicatorService.mqh
**Date:** 2026-05-02
**Task:** IMPL-005 — `services/IndicatorService.mqh` (handle owner + cache + fail-fast)
**Status:** S-ACs structurally covered; E-ACs deferred (runtime dependency)

---

## Files Created

| File | LOC | Layer | Guard |
|------|-----|-------|-------|
| `MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh` | 391 | services/ | `PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH` |

Within LOC budget (services: 200–800 per `.claude/rules/ea.md`).

---

## NFR-7.2 Audit — `#import` directives

```
IndicatorService.mqh: 0 #import directives
```

Pass: 0 `#import` directives — no external DLL usage (NFR-7.2 = 0 external DLLs).

---

## S-AC Coverage

### S-AC 1 — 8 public methods per TD-02 §8.1 / §5.1 class block
✅ Covered at lines 84–97 (class declaration) + 147–166 (method bodies).

Public API present:
1. `Init(CLogger *logger)` — Phase 1 init; stores logger; resets state (line 147–161)
2. `CreateHandles()` — populates ≥24 handles; fail-fast on first `INVALID_HANDLE` (line 172–248)
3. `Refresh()` — invalidates scan cache on new H4 bar (line 258–278)
4. `AnyHandleInvalid() const` — runtime fail-fast loop (line 284–293)
5. `CachedScan(string key, ScanFnType scan_fn)` — 10-entry LRU scan cache (line 305–354)
6. `ReleaseHandles()` — OnDeinit IndicatorRelease loop (line 362–374)
7. `GetHandle(int idx) const` — inline accessor for MarketContextBuilder (line 99)
8. `HandleCount() const` — inline accessor for Orchestrator init_ok log (line 102)

### S-AC 2 — `m_handle_count` literal matches `HandleCount()` return value
✅ Covered.
`m_handle_count = total;` at line 243, where `total = 24` (integer literal, lines 176–241 = 24 `iXxx()` calls, indices IDX 0..23). `HandleCount() const { return m_handle_count; }` inline at line 102. Both reference the same member — no divergence possible.

### S-AC 3 — `Init(CLogger*)` constructor injection; no `_Symbol` access in Init body
✅ Covered.
`Init()` body (lines 147–161): stores `m_logger = logger`; resets `m_handle_count`, `m_last_bar_index_h4`, `m_scan_count`; initializes arrays. No `_Symbol` reference anywhere in `Init()`.
`_Symbol` appears only inside `CreateHandles()` (lines 183–241) and `Refresh()` (line 263) — correct per ea.md Init body discipline.

### S-AC 4 — `AnyHandleInvalid()` returns true if any handle == INVALID_HANDLE
✅ Covered at lines 284–293.
Loop from `i = 0` to `m_handle_count - 1`; returns `true` on first `m_handles[i] == INVALID_HANDLE`; returns `false` if all valid. Satisfies FR-7.6 runtime check contract.

---

## Handle Inventory — ADR-003 compliance

| IDX constant | Indicator | Timeframe | Slots / usage | Handle IDX |
|---|---|---|---|---|
| `IDX_ICHI_H4` | iIchimoku | H4 | many | 0 |
| `IDX_ICHI_D1` | iIchimoku | D1 | many | 1 |
| `IDX_FORCE_H4` | iForce | H4 | C,J,G,GO,M,L,B,P | 2 |
| `IDX_ADX_H4` | iADX | H4 | C,K,G | 3 |
| `IDX_ADX_D1` | iADX | D1 | C,K,G | 4 |
| `IDX_WPR_H4` | iWPR | H4 | C,H,L,S | 5 |
| `IDX_WPR_D1` | iWPR | D1 | C,H,L,S | 6 |
| `IDX_WPR_M15` | iWPR | M15 | C,H,L,S | 7 |
| `IDX_BBANDS_H4` | iBands | H4 | R,B,BR,BI,P,T,S | 8 |
| `IDX_DEMARK_H4` | iDeMarker | H4 | LX,M | 9 |
| `IDX_DEMARK_M15` | iDeMarker | M15 | LX,M | 10 |
| `IDX_STOCH_M10` | iStochastic | M10 | C (ForceCutloss) | 11 |
| `IDX_STOCH_H4` | iStochastic | H4 | L | 12 |
| `IDX_STOCH_M15` | iStochastic | M15 | variant CodeWiki §1.4 | 13 |
| `IDX_MACD_M10` | iMACD | M10 | C (ForceCutloss, COverload) | 14 |
| `IDX_MACD_D1` | iMACD | D1 | C (COverload) | 15 |
| `IDX_ZIGZAG_H4` | iCustom ZigZag | H4 | CodeWiki §1.4 | 16 |
| `IDX_ZIGZAG_M5` | iCustom ZigZag | M5 | CodeWiki §1.4 | 17 |
| `IDX_MA_FAST_H4` | iMA (SMA 50) | H4 | trend filter | 18 |
| `IDX_MA_SLOW_H4` | iMA (SMA 200) | H4 | trend filter | 19 |
| `IDX_RSI_H4` | iRSI | H4 | filter | 20 |
| `IDX_RSI_D1` | iRSI | D1 | filter | 21 |
| `IDX_ATR_H4` | iATR | H4 | pip-distance reference | 22 |
| `IDX_MOMENTUM_H4` | iMomentum | H4 | CodeWiki §1.4 | 23 |

**Total: 24 handles** (S-AC: `m_handle_count = 24` literal). ADR-003 inventory base = 15; additional 9 from CodeWiki §1.4 to reach ≥24 target. All parameter tuples marked `// TODO IMPL-005-tune (verify CodeWiki §1.4 row N)` for lock-down at tuning pass.

---

## E-AC Deferral Notes

### E-AC 1 — `[probe]` smoke: ≥24 handles + `HandleCount()` returns 24
**Deferred to IMPL-053+** (Orchestrator OnInit wiring).
Evidence once available:
```bash
iconv -f UTF-16LE -t UTF-8 <tester-log> | grep -E '\[Phoenicis\].*\[ev=handles_created\]'
# Expect: "All 24 indicator handles valid (ADR-003 inventory)"
```
Structural coverage: `CreateHandles()` emits `Logger.Info("indicators","handles_created",0,"All 24...")` after all 24 pass INVALID_HANDLE check, then sets `m_handle_count = 24`. Orchestrator reads `HandleCount()` for init_ok log (Claim 02.5).

### E-AC 2 — `[log-assertion]` stub Symbol="INVALID" → `Init` returns false + Logger Error
**Deferred to IMPL-018+** (entry `.mq5` exists for G1 compile + G2 smoke test).
Structural coverage: `CreateHandles()` validates all 24 handles and calls `m_logger.Error("indicators","invalid_handle",i,...)` + `return false` on first invalid. Orchestrator → `CleanupPartialInit` → `INIT_FAILED` per TD-02 §7.4.1.
Grep command for future verification:
```bash
iconv -f UTF-16LE -t UTF-8 <tester-log> | grep -E '\[Phoenicis\].*\[ev=invalid_handle\]'
```

---

## Design Decisions

### `typedef double (*ScanFnType)(int handle, int depth)` at header level
Placed before class body (after include guard, before `class CIndicatorService`) per MQL5 `typedef` scoping rules. Required for `CachedScan` signature to compile without forward declaration of the function pointer type inside the class. Matches implementation directive in shared-context §6.A.

### `CachedScan` eviction strategy: rotate-left (FIFO/oldest-first) vs LRU
Chose rotate-left (shift all entries left, insert new at tail) when `m_scan_count == 10`. This is FIFO eviction — simpler than LRU in fixed-array context. For a 10-entry cache used per-bar (invalidated each H4 bar), FIFO is sufficient. Shared-context said "evict oldest" which rotate-left satisfies for insertion-order tracking.

### `CachedScan` scan_fn invocation stub
Full invocation deferred with `// TODO IMPL-005-cachedscan` comment. Currently passes `m_handles[0]` as placeholder. The actual IDX↔key mapping is a MarketContextBuilder concern (IMPL-006) — MCB will either: (a) pass the handle directly as a closure, or (b) use a naming convention in `key` to resolve IDX. Deferred cleanly without blocking callers from wiring the interface.

### ZigZag via `iCustom`
ZigZag is not a native MQL5 indicator — uses `iCustom(_Symbol, PERIOD_H4, "ZigZag", 12, 5, 3)`. Parameters (ExtDepth=12, ExtDeviation=5, ExtBackstep=3) are MQL5 standard ZigZag defaults. Marked `// TODO IMPL-005-tune` per directive.

---

## Self-Review Checklist (shared-context §6.G)

| # | Check | Result |
|---|-------|--------|
| 1 | Security: no hardcoded secrets; no string concat for paths; `_Symbol` only in `CreateHandles`/`Refresh` | ✅ Pass — `_Symbol` used only at lines 184–241 (CreateHandles) and line 263 (Refresh); no secrets |
| 2 | Business logic: all S-AC checkboxes covered | ✅ Pass — 4/4 S-ACs satisfied (see above) |
| 3 | Error handling: fail-fast booleans; no silent swallow | ✅ Pass — `CreateHandles()` returns `false` + `Logger.Error(...)` on first invalid handle; `ReleaseHandles()` checks `!= INVALID_HANDLE` before release |
| 4 | Performance: no allocation inside `Refresh()` hot path | ✅ Pass — `Refresh()` uses only stack-local `int bars_h4`; array reset via loop (fixed-size); no `new` or dynamic allocation |
| 5 | Over-engineering: header-only, no extra utility classes | ✅ Pass — single class `CIndicatorService`; `ScanFnType` typedef is required (not extra) |
| 6 | Tests: N/A this round (G1-G4 deferred per IMPL-002/004/008/009/011/012/014/042 precedent) | ✅ Skipped — documented in fragment |
| 7 | Naming: `m_*` member, PascalCase public, include-guard correct | ✅ Pass — all private members use `m_` prefix; public methods PascalCase; guard = `PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH` |

---

## Architecture Compliance

| Rule | Status |
|------|--------|
| 5-layer `#include` direction | ✅ `services/IndicatorService.mqh` includes `services/Logger.mqh` only (same layer — include guard safe); no slot/core/inputs includes |
| No `services/*` in `domain/` or `helpers/` | ✅ Not applicable — this is a services/ file |
| Include guard `#ifndef PHOENICISNEX_<LAYER>_<NAME>_MQH` | ✅ `PHOENICISNEX_SERVICES_INDICATORSERVICE_MQH` |
| Member naming `m_*` | ✅ All private members: `m_handles`, `m_handle_count`, `m_last_bar_index_h4`, `m_scan_keys`, `m_scan_values`, `m_scan_count`, `m_logger` |
| Methods PascalCase public | ✅ Init, CreateHandles, Refresh, AnyHandleInvalid, CachedScan, ReleaseHandles, GetHandle, HandleCount |
| No `#import` (NFR-7.2) | ✅ 0 `#import` directives |
| LOC budget (services: 200–800) | ✅ 391 LOC |
| `_Symbol` only inside CreateHandles/Refresh | ✅ Confirmed — Init body has no `_Symbol` |
| No slot-to-slot cross-include | ✅ Not applicable (services layer) |
| Constructor injection (ADR-002 + ea.md DI rule) | ✅ `Init(CLogger *logger)` — pointer stored; no global access |

---

## Open TODOs (for future tasks)

- `// TODO IMPL-005-tune` — 24 parameter tuples to lock-down per CodeWiki §1.4 (assign to IMPL-006 or dedicated tune pass)
- `// TODO IMPL-005-refresh` — CopyBuffer × 24 handles per-tick (deferred to IMPL-006 MarketContextBuilder, which owns per-buffer extraction)
- `// TODO IMPL-005-cachedscan` — full scan_fn invocation with correct IDX resolution (deferred to IMPL-006)

## Next Steps

- IMPL-006 (`MarketContextBuilder`): reads handles via `GetHandle(IDX_*)`, calls `CopyBuffer` to populate MarketContext snapshot; resolves scan_fn↔IDX mapping for CachedScan full invocation
- IMPL-053 (Orchestrator): wires `IndicatorService.Init(logger)` → `CreateHandles()` → `HandleCount()` in OnInit Phase C step 6; closes E-AC 1
- IMPL-018+ (entry `.mq5`): enables G1-G4 gate execution; closes E-AC 2
