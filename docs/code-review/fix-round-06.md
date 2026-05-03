# Code Review Fix Round 06

| Field | Value |
|-------|-------|
| **Round** | 06 |
| **Review File** | `docs/code-review/review-round-06.md` |
| **Date** | 2026-05-03 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source code touched** | 23 files (1 helper + 1 domain base + 19 slots + 1 input + 1 core + 1 spike) |
| **G1 verification** | 20/20 affected spikes — 0 errors / 0 warnings (MetaEditor64 sequential compile) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 06.1 | 19 slots reimplement pip arithmetic; `helpers/PipMath.mqh` unused at slot layer | 🟠 HIGH | **Accept** | CSlotBase + 19 slots + PipMath latent fix | bundled with 06.2/06.3 |
| 06.2 | Slot_H input `InpHEnabled` vs canonical `InpEnableSlotH` | 🟡 MEDIUM | **Accept** | Inputs_Slot_H.mqh + Slot_H.mqh × 2 sites | bundled with 06.1/06.3 |
| 06.3 | `sl_price` not normalized for B/K/L/LX/S/H — broker-edge correctness drift | 🟡 MEDIUM | **Partial Accept** | B/K/L/H accepted (4 files); **LX/S Reject** (file inspection: both already `NormalizeDouble(..., digits)` at LX:181-182 + S:222-224) | bundled with 06.1/06.2 |
| 06.4 | `CSlotRegistry::SelfTest` Case 5 mislabeled "capacity overflow"; real branch uncovered | 🔵 LOW | **Accept** | core/SlotRegistry.mqh + Spike_CSlotBase.mq5 docblock | separate commit |

**Accepted:** 4/4 findings (06.3 partial — 4 of 6 cited slots fixed; LX/S evidenced as already-correct → Reject)
**Rejected (within Partial 06.3):** 2 sub-targets — Slot_LX, Slot_S
**Latent bug surfaced + fixed:** `helpers/PipMath.mqh:75-77` had C-style `(void)x;` casts which MQL5 rejects (`error 143: 'void' - illegal use of 'void' type`). Replaced with the `x = x;` self-assign idiom mirroring `core/SlotRegistry::RegisterAll` stub.

## Accepted Findings — Fixes Applied

### Fix for Finding 06.1: Wire `CPipMath` into `CSlotBase`; refactor 19 slots to use base-class helpers

**Verdict:** Accept
**Approach selected:** Setter-based injection (`SetPipMath()`) — does **NOT** change `CSlotBase::Init()` arity, so the 4 existing spike harnesses (Spike_CSlotBase / Spike_Slot_K / Spike_Slot_L / Spike_Slot_G / Spike_Slot_H) compile unchanged. Composition Root at IMPL-053+ will call `SetPipMath()` immediately after `Init()`. Slots fall back to a single canonical inline expression in CSlotBase when `m_pip` is NULL — drift surface collapsed from 19 sites to 1.
**Drift class collapsed:**

- `_PipSize()` (1-pip price delta), `_PipsToPrice(pips)` (signed price delta from pips), `_PriceToPips(diff)` (abs pip count from price diff), `_NormalizeBrokerPrice(price)` (broker-bound `NormalizeDouble`) all introduced as protected methods on CSlotBase.
- 19 slots now route through these — `_Digits == 5 || _Digits == 3 ? 10.0 : 1.0` and `(int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5` expressions removed from slot bodies. **Forbidden-pattern grep `_Digits == 5 \|\| _Digits == 3` / `digits == 3 \|\| digits == 5` / `SYMBOL_DIGITS) == 5` returns 0 hits in `slots/`** (validation: re-run `grep -rE` post-fix).
- Slot_J 3-digit drift (review noted `==5` only at line 182) auto-resolved by routing through canonical helper.
- `helpers/PipMath::InheritSlFromParent` (ADR-009 stub for IMPL-039) now compiles cleanly inside the new include path.

**Changes:**

- `domain/CSlotBase.mqh` — added `#include "../helpers/PipMath.mqh"` + `CPipMath *m_pip` field (NULL-init in ctor) + `SetPipMath()` setter + 4 protected helpers (`_PipSize`, `_PipsToPrice`, `_PriceToPips`, `_NormalizeBrokerPrice`).
- `helpers/PipMath.mqh` — replaced `(void)x;` (illegal MQL5) with `x = x;` self-assign idiom (latent fix; same pattern as SlotRegistry.mqh:152).
- `slots/Slot_C.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_D.mqh` — 1 inline pip block → `_PipSize()`.
- `slots/Slot_F.mqh` — 1 inline pip block → `_PipSize()`.
- `slots/Slot_G.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_G2.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_GO.mqh` — 1 inline pip block → `_PipSize()`.
- `slots/Slot_I.mqh` — 3 inline pip blocks (incl. range-threshold call site) → `_PipSize()` / `_PipsToPrice(10.0)`; sl_price → `_NormalizeBrokerPrice`.
- `slots/Slot_J.mqh` — 1 inline pip block → `_PipSize()`. Comment notes the auto-fix of the 3-digit branch.
- `slots/Slot_M.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_Q.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_R.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_T.mqh` — 2 inline pip blocks → `_PipSize()`; sl_price + req.price → `_NormalizeBrokerPrice`.
- `slots/Slot_S.mqh` — 1 inline pip block → `_PipSize()`; local `_PipsToPrice` helper deleted (inherits base).
- `slots/Slot_B.mqh` — local `_PipsToPrice` deleted (inherits base); `_PriceDiffToPips` rewritten to `price_diff / _PipSize()`.
- `slots/Slot_BR.mqh` — local `_PipsToPrice` deleted (inherits base); `_PriceDiffToPips` rewritten to `price_diff / _PipSize()`.
- `slots/Slot_K.mqh` — local `_PipsToPrice` deleted (inherits base); `_PipSize()` from base; `profit_pips` simplified to `price_diff / _PipSize()`.
- `slots/Slot_L.mqh` — local `_PipsToPrice` deleted (inherits base); `_PipSize()` from base; `profit_pips` simplified to `price_diff / _PipSize()`.
- `slots/Slot_LX.mqh` — local `_PipsToPrice` + `_PipSize` deleted (inherits base).
- `slots/Slot_H.mqh` — 3 inline `_Point * (_Digits == 5 || _Digits == 3 ? 10:1)` → `_PipSize()`; sl_price wrapped with `_NormalizeBrokerPrice` (06.3); `InpHEnabled` → `InpEnableSlotH` × 2 sites (06.2).
- `inputs/Inputs_Slot_H.mqh` — `InpHEnabled` → `InpEnableSlotH` (06.2).

**G1 verification:** 20/20 affected spikes (Spike_CSlotBase + Spike_Slot_C/D/F/GO/J/K/L/LX/M/Q/R/S/T/I/G/G2/H/B/BR) compile **0 errors / 0 warnings** under MetaEditor64 sequential invocation. ex5 timestamps confirm fresh artifacts post-edit.
**Commit:** to be filled

### Fix for Finding 06.2: Rename `InpHEnabled` → `InpEnableSlotH`

**Verdict:** Accept (bundled with 06.1 commit since edits intersect Slot_H.mqh).
**Changes:**

- `inputs/Inputs_Slot_H.mqh:11` — declaration renamed; comment updated to canonical sibling style ("Enable Slot H (Fractal + Ichimoku Distance)").
- `slots/Slot_H.mqh:178, 204` — both `if(!InpHEnabled) return;` call sites updated.
- Forbidden-pattern grep `InpHEnabled` returns **0 hits** repo-wide post-fix.
- Sibling convention now uniform across all 19 slots: `InpEnableSlot{C,D,F,G,G2,GO,H,I,J,K,L,LX,M,Q,R,S,T,B,BR}`.

### Fix for Finding 06.3: NormalizeDouble on sl_price for B/K/L/H — Partial

**Verdict:** Partial Accept (4 of 6 cited slots accepted; LX/S rejected with file-content evidence).

**Accepted (4 slots) — sl_price wrapped with base-class `_NormalizeBrokerPrice`:**

- `slots/Slot_B.mqh:211` — wrapped via `_NormalizeBrokerPrice(price ± sl_dist)`.
- `slots/Slot_K.mqh:161` — wrapped (was previously naked `(price - sl_dist)`).
- `slots/Slot_L.mqh:156` — wrapped (was previously naked `(price - sl_dist)`).
- `slots/Slot_H.mqh:248-249` — wrapped (combined with 06.1 + 06.2 edits in same hunk).

**Rejected (2 slots) — LX/S already normalize per file inspection:**

- `slots/Slot_LX.mqh:181-182` reads (current file content):
  ```mql5
  double sl_price = buy_signal
                    ? NormalizeDouble(price - sl_dist, digits)
                    : NormalizeDouble(price + sl_dist, digits);
  ```
  Both branches `NormalizeDouble`-wrap. Review's "no NormalizeDouble" claim factually incorrect for LX. **No change required.**
- `slots/Slot_S.mqh:222-224` reads (current file content):
  ```mql5
  double sl_price = buy_signal
                    ? NormalizeDouble(ctx.ask - sl_dist, digits)
                    : NormalizeDouble(ctx.bid + sl_dist, digits);
  ```
  Same — already normalizes. Review claim factually incorrect for S. **No change required.**

Drift count post-fix: **0** entry-slots compute `sl_price` without normalization (vs. review's claim of 6 drifted; actual was 4).

### Fix for Finding 06.4: Split `CSlotRegistry::SelfTest` Case 5 into 5a (NULL-guard) + 5b (capacity overflow)

**Verdict:** Accept
**Changes:**

- `core/SlotRegistry.mqh:310-319` — old single-case body split into two cases:
  - **Case 5a** — `Add(NULL)` returns false (existing behavior; preserves NULL-guard coverage at `Add():122-127`).
  - **Case 5b** — fills registry to `PHOENICISNEX_SLOT_CAPACITY` (21) using same caller-owned `good_slot_a` stub via tight loop, then asserts the 22nd `Add()` rejects (`m_count >= PHOENICISNEX_SLOT_CAPACITY` branch at `Add():128-134`).
- `core/SlotRegistry.mqh:234` — class docblock updated: 5 → 5a/5b plus renumbered footer; PASS message changed from `"6 cases"` to `"7 cases — sentinel + slot-id + null-guard + capacity + pending default"`.
- `spike/Spike_CSlotBase.mq5:12-14` — coverage docblock updated: `6 SelfTest cases` → `7 SelfTest cases (..., null-guard, capacity-overflow, ...)`.

**G1 verification:** Spike_CSlotBase compiles **0 errors / 0 warnings** post-fix; SelfTest at runtime now exercises both branches via the new 5a + 5b cases (executed when Spike_CSlotBase attaches in MT5; runtime evidence deferred to next attach session per existing pattern — header-only `.mqh` precedent).
**Commit:** to be filled

## Rejected Findings — Evidence

### Rejection of Finding 06.3 sub-targets: Slot_LX + Slot_S

**Verdict:** Reject (within Partial accept of 06.3)
**Evidence:** Direct file inspection — both files contain `NormalizeDouble(..., digits)` wrappers around `sl_price` at the cited line ranges. Reproduction:

```bash
sed -n '180,184p' MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh
# → double sl_price = buy_signal
#                    ? NormalizeDouble(price - sl_dist, digits)
#                    : NormalizeDouble(price + sl_dist, digits);

sed -n '221,225p' MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh
# → double sl_price = buy_signal
#                    ? NormalizeDouble(ctx.ask - sl_dist, digits)
#                    : NormalizeDouble(ctx.bid + sl_dist, digits);
```

Review's drift list (6 slots) was correct on B/K/L/H but factually incorrect on LX/S — likely a snapshot/diff misread. The repo Round-05 fix did not retroactively normalize LX/S; the canonical pattern was authored that way originally per IMPL-031 + IMPL-036 closure.

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 4 |
| Accepted (full)   | 3 (06.1 / 06.2 / 06.4) |
| Accepted (partial)| 1 (06.3 — B/K/L/H accepted; LX/S rejected with evidence) |
| Rejected (full)   | 0 |
| Files Modified | 23 (1 helper + 1 domain + 19 slots + 1 input + 1 core + 1 spike comment) |
| Latent bugs surfaced + fixed | 1 (PipMath `(void)x;` MQL5 illegal cast) |
| Spikes Re-verified G1 | 20/20 (0 errors / 0 warnings) |
| Commits | 2 ea code commits + 1 state-reconcile commit (per workflow §3.2 rolled into bundles where edits overlap) |

## State Reconciliation (3-File Propagation)

Per CLAUDE.md §6 + workflow §4.2 — code review fixes are **NOT** task closure but DO change file state. Propagation (this fix-round closes Round 06):

- **Layer 1 (`docs/state/impl-plan.md`):** TL;DR last-action line updated to "Round 06 review + fix-round-06 closed"; Plan Staleness Sentinel reset to 0 (post-review). No task `[x]` retick — Round-06 fixes did not unblock previously-deferred E-AC closure.
- **Layer 2 (`docs/state/overview.md`):** "last code-review round" pointer bumped to `06`; phase status unchanged (P3 still 20/23 pending IMPL-013/034/039).
- **Layer 3 (`docs/state/_session-handoff/`):** Evidence index — refer to this fix-round file + the 20/20 G1 compile artifacts under `MQL5/Experts/PhoenicisNex/spike/Spike_*.compile.log` (timestamp ≥ 2026-05-03 23:18).

**Recommendation:** Ready for Code Review Round 07 OR proceed to **IMPL-039** (Slot_BI G4 SL fix per ADR-009) — the latter benefits from this round since `helpers/PipMath::InheritSlFromParent` is now reachable from CSlotBase via the wired `m_pip` (IMPL-039 will adopt one-line `m_pip.InheritSlFromParent(...)` instead of the duplicate-pattern path the reviewer warned about). Bucket B drift attribution at IMPL-063 is now cleaner: the slot layer is uniformly routed through CPipMath, so any deviation can be isolated to the G4 fix surfaces (IMPL-022 J ManageExits magic + IMPL-039 BI SL inheritance) rather than confused with sibling pip-arithmetic drift.
