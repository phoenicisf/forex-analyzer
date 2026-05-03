# Code Review Fix Round 05

| Field | Value |
|-------|-------|
| **Round** | 05 |
| **Review File** | `docs/code-review/review-round-05.md` |
| **Date** | 2026-05-03 |
| **Fixer Persona** | Impl Engineer (andm-impl-engineer) |
| **Scope** | Round-05 adversarial sweep on Round-04 fix delta + post-Round-04 P3 slot batch (IMPL-018 SlotRegistry + 21 slot files; ~6,300 LOC delta). 10 findings: CRITICAL 2 / HIGH 3 / MEDIUM 3 / LOW 2. |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 05.1 | Slot_H direct `CTrade m_trade_exec` + naked SL=0 | 🔴 CRITICAL | Accept | Slot_H only (architecture-rot precedent) | `01f3396` |
| 05.2 | Slot_B / K / L `ManageExits` walk Order* (pending) APIs | 🔴 CRITICAL | Accept | 3 files | `b102a0c` |
| 05.3 | Slot_BR `_HasActiveBROrder` ignores `InpBRMaxOrders` | 🟠 HIGH | Accept | Slot_BR only | `8a44ca2` |
| 05.4 | Slot_H bypasses PortfolioState via raw `PositionsTotal()` | 🟠 HIGH | Accept | bundled w/ 05.1 | `01f3396` |
| 05.5 | Slot_J `ManageExits` missing `InpEnableSlotJ` gate | 🟡 MEDIUM | Accept | Slot_J only | `7e62dbe` |
| 05.6 | Slot_J dead `j_state` read masquerading as G4 marker | 🟡 MEDIUM | Accept | Slot_J only | `7e62dbe` |
| 05.7 | IMPL-023 / 024 / 025 deferred E-AC missing from registry | 🟠 HIGH | Accept | `deferred-ac-registry.md` | `dca5e98` |
| 05.8 | Slot_B BR-trigger comment "pre-close" but fires every-tick + Order* refs | 🟡 MEDIUM | Accept | bundled w/ 05.2 | `b102a0c` |
| 05.9 | Slot_H comment quotes rule while violating | 🔵 LOW | Accept | bundled w/ 05.1 | `01f3396` |
| 05.10 | `CSlotRegistry::Init` heap leak on re-init | 🔵 LOW | Accept | core/SlotRegistry.mqh | `3266fd7` |

**Accepted:** 10 / 10 · **Rejected:** 0 · **Partial:** 0

---

## Accepted Findings — Fixes Applied

### Fix 05.1 (CRITICAL) — Strip CTrade member from Slot_H + route through PortfolioState

**Verdict:** Accept
**Scope:** Slot_H only (no other slot instantiates CTrade — fix-round-05 prevents the architecture-rot precedent)

**Problem:** Slot_H was the only slot in 21 instantiating a CTrade member (`m_trade_exec`) and dispatching `Buy` / `Sell` / `PositionClose` directly, sidestepping the `RiskManager` choke point that owns retry policy, retcode handling, comment normalization, fill-policy detection (`SymbolInfoInteger(SYMBOL_FILLING_MODE)`), and journal hooks. Additionally `Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment)` opened with SL=0 — the only slot opening positions without a stop loss, exposing unbounded drawdown on adverse moves.

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh` — drop `#include <Trade\Trade.mqh>`; drop `CTrade m_trade_exec` member; refactor `_TryExit` to take `ENUM_POSITION_TYPE` + log-intent only (no broker call); refactor `Evaluate` to compute `sl_price = price ± InpHSlPips * pip_size` then log entry intent (mirrors 17 sibling slots — e.g. `Slot_B.mqh:202-221`); move `m_last_bar_entered = ctx.bar_index_h4` post-log so cooldown holds even when wiring lands and broker call may fail.

**Commit:** `01f3396` `[fix:ea] Slot_H — strip CTrade member; route through PortfolioState (Round 05.1/05.4/05.9)`

### Fix 05.2 (CRITICAL) — Slot_B / K / L exit loops switched Order* → Position* APIs

**Verdict:** Accept
**Scope:** 3 files (Slot_B, Slot_K, Slot_L) — Slot_H was already on Position* APIs (separate Finding 05.4 collapse to canonical PortfolioState dialect)

**Problem:** `OrdersTotal() / OrderGetTicket(i) / OrderGetInteger(ORDER_MAGIC)` walk the MT5 _pending order_ list (limits/stops). Open market positions live on a separate list accessed via `PositionsTotal() / PositionGet*`. The exit gate body never executed against the right list; once IMPL-053 wires `CloseOrder`, the loop would still walk the wrong list and the slot's exit pass would become non-functional under real flow:
- Slot_B is parent of BR/BI cascade — broken B exit cascades to whole chain
- Slot_K is upstream dep of Slot_S post-close trigger
- Slot_L is upstream dep of Slot_LX pyramid + Slot_S post-close
- Bucket A regression risk (NFR-1.1 ≤25% Net Profit deviation)

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:225-282` — replace `OrdersTotal/OrderGet*` loop with `port.GetTicketsForSlot(MAGIC_B, "B,", tickets)` + `PositionSelectByTicket(ticket)` + `PositionGetInteger(POSITION_TYPE)` + `PositionGetDouble(POSITION_PRICE_OPEN)`. The shared-magic disambig retained — `GetTicketsForSlot` already filters by "B," prefix (StringFind("BI,...", "B,") returns -1).
- `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh:178-228` — same template; comment-prefix "K,".
- `MQL5/Experts/PhoenicisNex/slots/Slot_L.mqh:170-219` — same template; comment-prefix "L," (excludes "LX," from IMPL-031).

Also resolves Finding 05.8 (bundled below).

**Commit:** `b102a0c` `[fix:ea] Slot_B/K/L ManageExits — Order* → Position* APIs (Round 05.2/05.8)`

### Fix 05.3 (HIGH) — Slot_BR honours `InpBRMaxOrders`

**Verdict:** Accept
**Scope:** Slot_BR only

**Problem:** `_HasActiveBROrder` collapsed `GetTicketsForSlot` count → bool via `n > 0`, ignoring the operator-tunable input `InpBRMaxOrders`. Comment claimed "max InpBRMaxOrders BR orders simultaneously" but the gate hard-capped at 1. Strategy-Tester sweep on InpBRMaxOrders (FR-1.3 sweep compatibility) would produce identical results regardless of swept value, masking optimization signal. Pattern-drift inside the same B/BR/BI chain (Slot_B has `_CountBOrders` returning int).

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:74-80` — rename `_HasActiveBROrder` → `_CountBROrders` (returns int).
- `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:137` — own-active guard now `if(_CountBROrders(port) >= InpBRMaxOrders) return;`.

**Commit:** `8a44ca2` `[fix:ea] Slot_BR — _CountBROrders honours InpBRMaxOrders (Round 05.3)`

### Fix 05.4 (HIGH) — Slot_H routes through PortfolioState.GetTicketsForSlot (canonical)

**Verdict:** Accept
**Scope:** Slot_H — bundled with 05.1 commit (single architectural rewrite)

**Problem:** `_CountHOrders` and `ManageExits` walked the global `PositionsTotal()` list directly, bypassing `PortfolioState.GetTicketsForSlot()` which ADR-005 + ADR-012 mandate as the central choke point for ticket retrieval. Three dialects existed across 21 slots: (a) canonical `port.GetTicketsForSlot` (17 slots), (b) raw `PositionsTotal` (Slot_H — partial bypass), (c) raw `OrdersTotal` (Slot_B/K/L — wrong API, Finding 05.2). Round 05 collapses all three to (a).

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh:130-134` — `_CountHOrders` now takes `CPortfolioState &port` and returns `port.GetTicketsForSlot(MAGIC_H, "H,", tickets)`.
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh:176-196` — `ManageExits` uses `port.GetTicketsForSlot` + `PositionSelectByTicket`; added `if(!InpHEnabled) return;` guard (was missing — accidental).
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh:207` — Evaluate `_CountHOrders(port)` call site updated.

**Commit:** `01f3396` (bundled with 05.1)

### Fix 05.5 (MEDIUM) — Slot_J ManageExits +`InpEnableSlotJ` gate

**Verdict:** Accept
**Scope:** Slot_J only — G4 fix BR-7.2 attestation surface tightened

**Problem:** 17 sibling slots gate `ManageExits` on `InpEnableSlot<X>`; Slot_J did not. Disabling Slot_J via `InpEnableSlotJ=false` stopped Evaluate but ManageExits still iterated J tickets every tick. Pattern drift on the highest-risk slot (Bucket B / NFR-1.8 attribution) made the contract ambiguous.

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh:170` — added `if(!InpEnableSlotJ) return;` as the first line of `ManageExits` (canonical sibling guard).

**Commit:** `7e62dbe`

### Fix 05.6 (MEDIUM) — Remove dead `j_state` read in Slot_J ManageExits

**Verdict:** Accept (Option A — recommended for Phase-1 MVP)
**Scope:** Slot_J only

**Problem:** `SlotState *j_state = port.GetByMagic(MAGIC_J);` was assigned, NULL-checked, then never used. The empty `if(NULL)` body had no fall-through behavior — execution proceeded identically. The comment claimed this was a "G4 fix BR-7.2" anchor but the actual G4 fix is the `GetTicketsForSlot(MAGIC_J, "J,", ...)` line below. The dead read inflated the audit surface and was a future bug-vector when SlotState really is unregistered post-MVP.

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh:173-181` — removed `j_state` declaration + NULL-check block; G4 attestation surface tightened to 2 explicit `// G4 fix BR-7.2 — was MAGIC_F` markers (at GetTicketsForSlot site + log message site, down from 3).
- Updated docblock above `ManageExits` to reflect single-step iteration (was 2-step Read-state → iterate).

**Commit:** `7e62dbe` `[fix:ea] Slot_J — InpEnableSlotJ gate + remove dead j_state (Round 05.5/05.6)`

### Fix 05.7 (HIGH) — Add IMPL-023 / 024 / 025 to deferred-ac-registry

**Verdict:** Accept
**Scope:** `docs/state/deferred-ac-registry.md`

**Problem:** Dimension #11 closure-discipline violation. IMPL-023 / 024 / 025 closed with `[ ]` E-AC + "deferred to IMPL-053+ orchestrator wiring" note but no Active row in `deferred-ac-registry.md`. 18 sibling slot tasks were properly registered with bounded expiry + risk-if-missed; 3 outliers were a discipline gap that left the deferred set silently incomplete — at expiry 2026-05-17, `/impl-task` would HALT on the 18 registered rows but never surface IMPL-023/024/025.

**Changes:**
- `docs/state/deferred-ac-registry.md` Active table — added 3 rows:
  - `P3 | IMPL-023 | Smoke 60-day backtest with only Slot H active → ≥1 entry+exit cycle journaled | log-assertion | ... | Kritsana | 2026-05-03 | 2026-05-17 | Slot H independent-baseline production behavior untested ...`
  - `P3 | IMPL-024 | Smoke 60-day backtest with only Slot K active → ≥1 entry+exit cycle journaled | log-assertion | ... | 2026-05-17 | Slot K production untested; downstream IMPL-036 S post-close depends on K close events ...`
  - `P3 | IMPL-025 | Smoke 60-day backtest with only Slot G active → ≥1 G entry triggers GOverride | log-assertion | ... | 2026-05-17 | Slot G production untested; G2/I/GO multi-slot fanout root ...`

**Commit:** `dca5e98` `[state] register IMPL-023/024/025 deferred E-AC (Round 05.7)`

### Fix 05.8 (MEDIUM) — Slot_B BR-trigger hook relocated post-profit-gate; Position* APIs in commented body

**Verdict:** Accept
**Scope:** Slot_B — bundled with 05.2 (single ManageExits rewrite)

**Problem:** Comment said "pre-close trigger: emit hook before OrderClose returns" but the loop never called OrderClose (Phase-1 stub log-only) and the hook was placed BEFORE the profit-gate check at line 283 — firing every tick that a B position was open (regardless of whether close fires). That's neither "pre-close" nor "post-close"; it's "every-tick-while-open". CodeWiki §3.18 contract requires post-close semantics. The commented body referenced `OrderGetDouble(ORDER_VOLUME_CURRENT)` — same Order* family as Finding 05.2.

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:259-275` — relocated BR-trigger hook AFTER the profit-gate close stub so it fires post-close per CodeWiki §3.18; switched commented body to `PositionGetDouble(POSITION_VOLUME)`; comment annotates "fires AFTER close".

**Commit:** `b102a0c` (bundled with 05.2)

### Fix 05.9 (LOW) — Resolved by 05.1 strip

**Verdict:** Accept
**Scope:** Slot_H — comment removed when CTrade member stripped

**Problem:** `Slot_H.mqh:249` comment "ห้าม instantiate CTrade ตรง" quoted the project rule in the same line as the code that violated it. False-documentation pattern that slowed code review.

**Changes:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh` — comment block at the OrderSend site rewritten to "Submit order via RiskManager wrapper (ea.md: ALL CTrade calls through RiskManager — slots ห้าม instantiate CTrade ตรง). Phase-1 stub: log intent only; m_risk.OpenOrderH(...) wires at IMPL-053+." — comment now correctly describes intended behavior, not violated behavior.

**Commit:** `01f3396` (bundled with 05.1)

### Fix 05.10 (LOW) — `CSlotRegistry::Init` routed through ReleaseAll

**Verdict:** Accept
**Scope:** `core/SlotRegistry.mqh`

**Problem:** `Init()` cleared `m_slots[]` and reset `m_count = 0` without checking whether the registry was already populated. If a caller invoked `RegisterAll() → Init()` (e.g., re-init on OnInit re-entry per `CleanupPartialInit` per TD-02 §7.4.1), the first `Init()` zeroed pointers without `delete` — heap leak when `m_owns_slots == true` (production wiring at IMPL-053+ allocates derivatives on heap). Today's SelfTests use `SetOwnsSlots(false)` so the leak was masked structurally, but the latent bug surfaces when RegisterAll allocates derivatives.

**Changes:**
- `MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh:104-112` — `Init()` now calls `ReleaseAll()` at start; `ReleaseAll` respects `m_owns_slots` (deletes when true, just clears pointers when false). Removed redundant `m_count=0` + manual array zeroing (ReleaseAll does both).

**Commit:** `3266fd7` `[fix:ea] CSlotRegistry::Init — route through ReleaseAll (Round 05.10)`

---

## Rejected Findings — Evidence

_None — all 10 findings accepted._

---

## Compile Evidence (G1)

| Spike | Result | Time |
|-------|--------|------|
| Spike_Slot_H | 0 errors, 0 warnings | 640 ms |
| Spike_Slot_B | 0 errors, 0 warnings | 468 ms |
| Spike_Slot_K | 0 errors, 0 warnings | 458 ms |
| Spike_Slot_L | 0 errors, 0 warnings | 429 ms |
| Spike_Slot_BR | 0 errors, 0 warnings | 418 ms |
| Spike_Slot_J | 0 errors, 0 warnings | 534 ms |
| Spike_CSlotBase | 0 errors, 0 warnings | 562 ms |

**Sibling regression** — 13/13 unmodified slot spikes still 0err/0warn:

| Spike | Result | Time |
|-------|--------|------|
| Spike_Slot_C | 0/0 | 513 ms |
| Spike_Slot_D | 0/0 | 472 ms |
| Spike_Slot_F | 0/0 | 455 ms |
| Spike_Slot_G | 0/0 | 435 ms |
| Spike_Slot_G2 | 0/0 | 450 ms |
| Spike_Slot_GO | 0/0 | 447 ms |
| Spike_Slot_I | 0/0 | 487 ms |
| Spike_Slot_LX | 0/0 | 469 ms |
| Spike_Slot_M | 0/0 | 453 ms |
| Spike_Slot_Q | 0/0 | 460 ms |
| Spike_Slot_R | 0/0 | 458 ms |
| Spike_Slot_S | 0/0 | 470 ms |
| Spike_Slot_T | 0/0 | 448 ms |

G2-G4 deferred per header-only `.mqh` precedent (gates activate at IMPL-053+ Composition Root).

---

## Anti-Regression Sweep

Post-fix grep validation (zero hits = clean):

| Pattern | Hits | Notes |
|---------|------|-------|
| `m_trade_exec` (slots/) | 0 | CTrade members stripped |
| `OrdersTotal()` (slots/) | 0 | All exit loops switched to Position* / PortfolioState |
| `_HasActiveBROrder` | 0 | Renamed to `_CountBROrders` |
| `<Trade\\Trade.mqh>` (slots/) | 0 | No slot includes CTrade directly |
| `OrderGetInteger(ORDER_MAGIC)` (slots/) | 0 | Replaced by canonical pattern |

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 10 |
| Accepted | 10 |
| Rejected | 0 |
| Partial | 0 |
| Source files modified | 7 (Slot_H, Slot_B, Slot_K, Slot_L, Slot_BR, Slot_J, core/SlotRegistry) |
| State files modified | 1 (deferred-ac-registry.md +3 rows) |
| Tests Added/Updated | 0 (refactors of header-only `.mqh` — Spike SelfTests still pass structurally; live-flow E-ACs remain deferred to IMPL-053+) |
| Commits | 6 (`01f3396`, `b102a0c`, `8a44ca2`, `7e62dbe`, `3266fd7`, `dca5e98`) |
| Deferred-AC Active table | 20 → 23 rows (5 P2 + 18 P3 → 5 P2 + 21 P3 after IMPL-023/024/025 added) |

**Recommendation:** ready for next code review round (Round 06 — adversarial sweep on Round-05 fix delta) **OR** continue with IMPL-039 (BI SL G4 fix per ADR-009 — second G4 fix; HIGH RISK Bucket B drift) after `/impl-plan-review all` (Plan Staleness Sentinel @ 48 closures since last review).
