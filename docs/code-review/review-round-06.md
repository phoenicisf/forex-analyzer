# Code Review Round 06

| Field | Value |
|-------|-------|
| **Round** | 06 |
| **Target** | `all` — adversarial sweep over post-fix-round-05 P3 slot batch (19 slots in `MQL5/Experts/PhoenicisNex/slots/` + `core/SlotRegistry.mqh` + `domain/CSlotBase.mqh` + 19 input files) — same scope window as Round 05 but examined for issues that the previous round's diff-driven sweep did not surface (cross-cutting drift, helper-layer non-use, broker-edge correctness) |
| **Date** | 2026-05-03 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~5,891 LOC across 19 slot files + 132 LOC CSlotBase + 334 LOC SlotRegistry. Cross-cuts examined: (a) `.claude/rules/ea.md` "MQL5/MT5-specific idioms" — pip arithmetic helper usage; (b) NFR-6.3 input naming convention; (c) NormalizeDouble discipline on broker-bound prices; (d) SelfTest coverage claims vs actual branch coverage. Round 05 diff-driven sweep caught 10 findings on the 21-task batch; Round 06 examines the same surface with a **layer-discipline lens** (helpers/ vs slots/) + **broker-edge lens** (price rounding, naming) + **test-claim lens** (do SelfTest comments match what the code exercises?). |
| **Cumulative LOC reviewed (Round 06)** | ~6,357 LOC (slot layer + core/SlotRegistry + helpers/PipMath cross-check) |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **4** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No `WebRequest` / external `#import` / hardcoded creds in slot or registry layer; symbol whitelist enforced upstream (OnInit). |
| 2 | Business Logic Correctness | ✅ Pass | Round 05 caught the 3 critical exit-API mismatches (Slot_B/K/L Order* → Position*) + Slot_H direct-CTrade. Post-fix-05 grep across slots/ shows 0 hits of `OrdersTotal()` / `OrderGetTicket` / `#include <Trade\Trade.mqh>` — fixes preserved. G4 BR-7.2 attestation surface in Slot_J (`MAGIC_J` iteration + log marker + comment) intact. |
| 3 | Error Handling | ✅ Pass | NULL-guard pattern consistent across 19 slots (`if(m_logger != NULL)`, `if(m_risk != NULL)`); fail-fast paths log + early-return per ADR-002. |
| 4 | Performance | ✅ Pass | Slot iteration O(n) where n ≤ tickets-per-symbol; comment-prefix StringFind O(prefix_len); no N+1 patterns observed. |
| 5 | Over-Engineering | ⚠️ Finding | **19 slots reimplement the same `_Digits == 5 \|\| _Digits == 3 ? 10.0 : 1.0` pip-multiplier expression inline + skip the dedicated `helpers/PipMath.mqh` helper that already encapsulates this** (Finding 06.1 HIGH). Architecturally this is duplication, but it also opens behavioral drift if PipMath::Init() ever changes the rule (e.g., 3-digit JPY pair classification). |
| 6 | Cross-Service Consistency | ⚠️ Finding | **`Slot_H.mqh` uses `InpHEnabled`** while 18 sibling slots use the `InpEnableSlot<X>` canonical form (Finding 06.2 MEDIUM). Single-slot drift on the same NFR-6.3 group-annotation contract that Round 05 just hardened on Slot_J `InpEnableSlotJ`. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **`CSlotRegistry::SelfTest` Case 5 comment claims "capacity overflow surface" but exercises `Add(NULL)` instead** — the real overflow branch (`m_count >= PHOENICISNEX_SLOT_CAPACITY` in `Add()` at `core/SlotRegistry.mqh:128`) is never exercised by any SelfTest case (Finding 06.4 LOW). False-coverage claim in test comment + an uncovered Add() branch in the IMPL-018 ADR-002 layer-1 sentinel sweep. |
| 8 | Architecture Compliance | ⚠️ Finding | Layer discipline holds (`slots/*` ห้าม `#include "slots/*"` — grep clean; no `services/*` → `slots/*`). However Finding 06.1 (HIGH) materializes as ea.md "Pip arithmetic: use helpers/PipMath.mqh::ToPoints(pips)" violation — slots bypass the helpers layer that exists explicitly to serve this need. |
| 9 | TD Compliance | ✅ Pass | CSlotBase 6-method contract honored (19/19 slots override all 6); ADR-002 Composition Root respected post-Slot_H fix; ADR-005 PortfolioState.GetTicketsForSlot canonical pattern used by 19/19 slots post-fix-05. |
| 10 | Test Quality | ⚠️ Finding | Slot_B/K/L/LX/S/H compute `sl_price = price ± sl_pips * pip_size` **without `NormalizeDouble(..., _Digits)`** (Finding 06.3 MEDIUM). Slot_C/G/G2/I/M/Q/R/T (8 slots) DO wrap with NormalizeDouble. Pattern drift on broker-edge correctness: when IMPL-053 wires OrderSend, unrounded SL prices may be rejected by broker `INVALID_STOPS` (10016) on certain pip-size × tick-size combos. |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `docs/state/impl-plan.md` returns **0 hits** for "deferred to operator-runtime" / "deferred to post-launch operator phase" / "deferred per .* precedent" / "structurally complete.*deferred" (R06 plan rebuttal Claim 06.1 cleared all forbidden-closure occurrences, backfilling 6 P1 rows to registry). 31 Active rows in `deferred-ac-registry.md` all have bounded expiry 2026-05-17 + risk-if-missed text. G4 attestation file `docs/state/g4-fix-attestation.md` correctly tracked as Active row (will be authored at IMPL-039 paired closure). |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface; all slot files are header-only `.mqh` consumed by entry `.mq5` at IMPL-018+ (Composition Root pending IMPL-053). |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret / API-key consumer (per CLAUDE.md §6 config-audit gate note). All inputs are MT5 `input` declarations + Strategy-Tester sweep-compatible per FR-1.3. |

---

## Findings

### Finding 06.1: 🟠 HIGH — 19 slots reimplement pip arithmetic inline; `helpers/PipMath.mqh` lives unused in the helpers layer

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_C.mqh`, Slot_D, Slot_F, Slot_G, Slot_G2, Slot_GO, Slot_H, Slot_I, Slot_J, Slot_K, Slot_L, Slot_LX, Slot_M, Slot_Q, Slot_R, Slot_S, Slot_T, Slot_BR (and Slot_B's local `_PipsToPrice` helper) — **19 / 19 slot files**
- Service: `[ea]` slots layer
- Cross-ref rule: `.claude/rules/ea.md` § "MQL5/MT5-specific idioms" — "**Pip arithmetic: use `helpers/PipMath.mqh::ToPoints(pips)` — handles 4-digit vs 5-digit broker** per `mql-developer`"
- Cross-ref helper: `MQL5/Experts/PhoenicisNex/helpers/PipMath.mqh` (85 LOC) — owns `Init()` digit-multiplier detection (BR-9.3 + ADR-009), `PipToPrice()`, `PriceToPip()`, `ToPoints()`, `FromPoints()`, `InheritSlFromParent()` (ADR-009 stub for IMPL-039)
- Cross-ref consumer: only `services/TimeGate.mqh` injects `CPipMath* m_pip` via constructor — slot layer has zero consumers

**Code (representative — same pattern across 19 files):**
```mql5
// Slot_H.mqh:114-115
double pip_size = _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
if(pip_size <= 0.0) return false;

// Slot_J.mqh:181-183
double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
double pip_factor = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10.0 : 1.0;
double pip_size   = point * pip_factor;

// Slot_C.mqh, Slot_G.mqh, Slot_M.mqh, Slot_Q.mqh, Slot_R.mqh, Slot_T.mqh, Slot_I.mqh, Slot_G2.mqh:
// near-identical inline blocks, each computing the same multiplier
```

**Problem:**
`.claude/rules/ea.md` explicitly mandates `helpers/PipMath.mqh::ToPoints(pips)` as the **single choke point** for digit-multiplier arithmetic — exactly to prevent the pattern observed here, where 19 slot files each re-derive `_Digits == 5 || _Digits == 3 ? 10.0 : 1.0`. Three concrete drift surfaces:

1. **Behavioral divergence risk.** `CPipMath::Init()` at `helpers/PipMath.mqh:31` sets the project-wide multiplier rule. If that rule ever changes (e.g., supporting 6-digit gold quotes, or fixing a 3-digit JPY pair classification), the 19 slots will silently keep the old logic until each is hand-edited — Bucket A regression (NFR-1.1 ≤ 25% Net Profit deviation) waiting to happen.
2. **`Slot_J` already wrong on the 3-digit branch.** `Slot_J.mqh:182` checks `(int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5` — **drops the 3-digit JPY case** that PipMath includes. Other slots (C, G, H, etc.) include `_Digits == 5 || _Digits == 3`. PhoenicisNex is EURUSD-only per NFR-5.3 so the bug is dormant, but the inconsistency is exactly the drift class the helper exists to prevent.
3. **`InheritSlFromParent` orphaned.** `helpers/PipMath.mqh:69-81` ships an ADR-009 stub for IMPL-039 BI SL fix. With slots ignoring the helper, IMPL-039 will need to either (a) finally adopt the helper across all 19 slots (large refactor) or (b) duplicate ADR-009 logic into Slot_BI inline — both bad outcomes that surface only at IMPL-039 time, deep into Phase 3.

**Why This Matters:**
ea.md non-compliance is not aesthetics — it's the contract that turns `helpers/PipMath.mqh` from "dead code" to "shared infrastructure". Right now PhoenicisNex has the worst of both: helper exists (cost-paid in IMPL-009 + the tests/SelfTest at IMPL-009), but only 1 of 14 services consumes it (TimeGate). Round 05 tightened slot layer convergence on PortfolioState.GetTicketsForSlot (3 dialects → 1) and CTrade routing (Slot_H direct → RiskManager) — Round 06 raises the same architectural concern one layer up: slots → helpers/PipMath. Same drift class.

Without action, IMPL-039 (Slot_BI G4 SL fix per ADR-009 — Bucket B drift NFR-1.8 attestation point) will land into a slot layer that is already 19-way inconsistent with the helper — making Bucket B drift attribution muddier than necessary, since the comparison baseline is fragmented.

**Suggested Fix:**

**Phase A (this fix):** wire `CPipMath* m_pip` into `CSlotBase` Init (mirror TimeGate), update Composition Root to inject the shared `CPipMath` instance, replace inline `_Digits` checks with `m_pip.ToPoints(pips)` / `m_pip.PipToPrice(pips)` across all 19 slots. Estimated: ~38 line edits (~2 lines per slot — declare + use), 1 file edit per slot, mechanical.

```mql5
// CSlotBase.mqh — add
protected:
   CPipMath *m_pip;   // injected at Init; ea.md mandate

// Slot_X.mqh — replace
//   double pip_size = _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
// with
//   double pip_size = m_pip.PipToPrice(1.0);   // 1-pip price delta
// or for SL distance:
//   double sl_dist = m_pip.PipToPrice(InpXSlPips);
```

**Phase B (deferred to IMPL-039):** consume `m_pip.InheritSlFromParent(...)` in Slot_BI per ADR-009 — this finding makes that path one-line at IMPL-039 instead of a refactor.

**Level of Effort:** Medium

---

### Finding 06.2: 🟡 MEDIUM — `Slot_H` input declared as `InpHEnabled` instead of canonical `InpEnableSlotH` — single-slot NFR-6.3 naming drift

**Location:**
- File: `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_H.mqh`, Line: 11
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh`, Lines: 178, 204
- Service: `[ea]` slots + inputs
- Cross-ref BA spec: `docs/ba/03-non-functional-requirements.md` NFR-6.3 group annotation contract (per CLAUDE.md §3 + `.claude/rules/ea.md` Naming Conventions: "Inputs: `Inp<SlotId><Param>` with `group=\"Slot <X>\"` annotation")
- Cross-ref siblings (canonical):
  - `Inputs_Slot_B.mqh:29` → `InpEnableSlotB`
  - `Inputs_Slot_BR.mqh:21` → `InpEnableSlotBR`
  - `Inputs_Slot_C.mqh:20` → `InpEnableSlotC`
  - `Inputs_Slot_D.mqh:26` → `InpEnableSlotD`
  - `Inputs_Slot_G.mqh:22` → `InpEnableSlotG`
  - `Inputs_Slot_G2.mqh:24` → `InpEnableSlotG2`
  - `Inputs_Slot_GO.mqh:20` → `InpEnableSlotGO`
  - `Inputs_Slot_I.mqh:24` → `InpEnableSlotI`
  - `Inputs_Slot_LX.mqh:22` → `InpEnableSlotLX`
  - `Inputs_Slot_T.mqh:17` → `InpEnableSlotT`
  - (+ J/K/L/M/Q/R/S/F/D — 18 sibling files)
- Cross-ref Round 05 fix: Fix 05.5 added `InpEnableSlotJ` gate to Slot_J — same naming convention used as the canonical anchor

**Code:**
```mql5
// inputs/Inputs_Slot_H.mqh:10-11  (the only outlier)
input group "Slot H"
input bool   InpHEnabled            = true;   // Enable/disable Slot H

// slots/Slot_H.mqh:178
void CSlotH::ManageExits(CPortfolioState &port)
  {
   if(!InpHEnabled) return;       // ← canonical sibling form would be InpEnableSlotH

// slots/Slot_H.mqh:204
void CSlotH::Evaluate(...)
  {
   if(!InpHEnabled) return;       // ← canonical sibling form would be InpEnableSlotH
```

**Problem:**
`Slot_H` is the only slot in 19 that does not follow the `InpEnableSlot<X>` naming convention adopted everywhere else in the inputs/ layer. The convention surface is operator-facing — MT5 input dialog (NFR-6.3 group annotation) groups all `InpEnableSlot*` inputs visually so the operator sees a uniform "Slot enable" column when scrolling through the 21-slot configuration. `InpHEnabled` will sort separately, and Strategy-Tester sweep templates that iterate slots via the canonical prefix (e.g., for FR-1.3 batch enable/disable sweeps) will silently skip Slot_H.

This was not in Round 05 because Round 05's diff-driven sweep on Slot_H focused on the architecture-rot issue (CTrade member + naked SL=0 = the CRITICAL); the input naming never surfaced as a delta against the previous slot batch.

**Why This Matters:**
1. **Operator UX — silent gap.** Operator opens MT5 input dialog at IMPL-060 (entry `PhoenicisNex.mq5` attach), expects the "Slot H" group to have an `InpEnableSlotH` toggle matching every other slot — finds `InpHEnabled`. Confusion + manual lookup; not a crash but a paper-cut on first attach.
2. **Sweep template drift.** FR-1.3 demands Strategy-Tester sweep compatibility. A YAML or `.set` template generated by walking sibling slots with prefix `InpEnableSlot*` will produce a sweep that disables 18 slots and silently leaves Slot_H enabled — inverted-baseline regression risk during Bucket A drift testing (NFR-1.1).
3. **Signal — Round 05 fix-precedent.** Fix 05.5 explicitly adopted `InpEnableSlotJ` for Slot_J — that fix is stronger if the convention is uniform across 19 slots. Round 06 closes the last outlier.

**Suggested Fix:**

```mql5
// inputs/Inputs_Slot_H.mqh:11 — rename
input bool   InpEnableSlotH         = true;   // Enable Slot H (Fractal + Ichimoku Distance)

// slots/Slot_H.mqh:178, 204 — update both call sites
   if(!InpEnableSlotH) return;
```

Two file edits (1 input file + 1 slot file × 2 sites = 3 line edits). G1 spike compile must be re-run for IMPL-023 to confirm 0 errors / 0 warnings.

**Level of Effort:** Low

---

### Finding 06.3: 🟡 MEDIUM — Slot_B / K / L / LX / S / H compute `sl_price` without `NormalizeDouble(..., _Digits)` — broker-edge correctness drift

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh`, Line: 211
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh`, Line: 161
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_L.mqh`, Line: 156
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh`, Lines: 181-182
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh`, Lines: 222-224
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh`, Lines: 248-249
- Service: `[ea]` slots layer (entry path)
- Cross-ref rule: `.claude/rules/ea.md` § "MQL5/MT5-specific idioms" — "**Double comparison: never `==` with doubles — use `NormalizeDouble(x, _Digits)` or tolerance**" (broker-bound prices need same discipline — broker `INVALID_STOPS` (10016) on certain tick-size × pip-size combos when SL is sub-tick)
- Cross-ref siblings (canonical — DO normalize):
  - `Slot_C.mqh:252-256` → `NormalizeDouble(ctx.ask - sl_pips * pip_size, _Digits)`
  - `Slot_G.mqh:275, 279` → `NormalizeDouble(..., (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS))`
  - `Slot_G2.mqh:229, 231` → `NormalizeDouble(..., digits)`
  - `Slot_I.mqh:275, 277` → `NormalizeDouble(..., digits)`
  - `Slot_M.mqh:231, 234` → `NormalizeDouble(..., digits)`
  - `Slot_Q.mqh:230, 233` → `NormalizeDouble(..., digits)`
  - `Slot_R.mqh:239, 242` → `NormalizeDouble(..., digits)`
  - `Slot_T.mqh:230, 233` → `NormalizeDouble(..., digits)`
  - (8 of 14 entry-slots normalize; 6 do not)

**Code:**
```mql5
// Slot_B.mqh:209-211 (representative — no NormalizeDouble)
double           price      = buy_signal ? ctx.ask : ctx.bid;
double           sl_dist    = _PipsToPrice(InpBSlPips);
double           sl_price   = buy_signal ? (price - sl_dist) : (price + sl_dist);

// Slot_H.mqh:246-249 (no NormalizeDouble)
double price    = is_buy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                         : SymbolInfoDouble(_Symbol, SYMBOL_BID);
double sl_price = is_buy ? (price - InpHSlPips * pip_size)
                         : (price + InpHSlPips * pip_size);

// Slot_LX.mqh:181-182 (no NormalizeDouble)
double           sl_price = buy_signal
                            ? (price - sl_dist) : (price + sl_dist);

// Canonical pattern (Slot_C.mqh:250-256)
double sl_price = 0.0;
if(is_buy)
   sl_price = NormalizeDouble(ctx.ask - sl_pips * pip_size,
                              (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
else
   sl_price = NormalizeDouble(ctx.bid + sl_pips * pip_size,
                              (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
```

**Problem:**
At Phase-1 stub stage `sl_price` is only logged (intent-only) so an unrounded value is **harmless today**. At IMPL-053 wiring time the same value flows into `RiskManager::OpenOrder<X>(...)` → `CTrade::PositionOpen(... sl ...)` → broker. MT5 brokers reject orders with SL at sub-tick precision (`TRADE_RETCODE_INVALID_STOPS` = 10016); `_Point * pip_factor * pips_double` can produce a price with more digits than `_Digits` due to floating-point arithmetic, especially when `sl_pips` is fractional or `pip_factor=10.0` * point compounds.

The drift is exactly the kind ea.md warns about. 8 sibling slots (C/G/G2/I/M/Q/R/T) already do the right thing; 6 slots (B/K/L/LX/S/H) drift. The split is non-random — it correlates with the slot's MVP-vs-CD-chain authoring batch (B/K/L came as their own batch with shared pattern; H came earlier; C/G/etc. came in the parallel-batch wave that adopted the canonical NormalizeDouble form).

**Why This Matters:**
1. **IMPL-053 ticking time bomb.** When Orchestrator wires OrderSend, the 6 drifted slots will start producing real orders. Bucket A regression risk (NFR-1.1) — real OrderSend rejected at broker = trade signal lost = baseline parity diverges.
2. **Bucket B muddied at IMPL-039.** IMPL-039 (Slot_BI G4 SL fix per ADR-009) is the second G4 fix and the Bucket B (NFR-1.8) attestation point. If 6 of 14 sibling entry-slots drift on price normalization, the Bucket B attestation becomes harder to isolate — was the deviation from the G4 fix or from sibling drift?
3. **Pattern entrenchment cost.** Each round that ships drift at this layer doubles the future fix cost. Round 06 has 6 files; if IMPL-039 + IMPL-034 ship the same drift pattern the count goes to 8.

**Suggested Fix:**

```mql5
// Slot_B.mqh:211 — wrap with NormalizeDouble
double sl_price   = buy_signal
                    ? NormalizeDouble(price - sl_dist, _Digits)
                    : NormalizeDouble(price + sl_dist, _Digits);

// Slot_H.mqh:248-249, Slot_K.mqh:161, Slot_L.mqh:156, Slot_LX.mqh:181-182,
// Slot_S.mqh:222-224 — same wrap (or _Digits in scope, or
// (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) per Slot_C precedent)
```

If Finding 06.1 (PipMath wiring) lands first, the same call site becomes:
```mql5
double sl_price = m_pip.NormalizeForBroker(price ± m_pip.PipToPrice(InpBSlPips));
```
(introduces a new `CPipMath::NormalizeForBroker` accessor that wraps NormalizeDouble + `_Digits` lookup).

**Level of Effort:** Low (6 file edits, ~12 line wraps). Medium if bundled with Finding 06.1.

---

### Finding 06.4: 🔵 LOW — `CSlotRegistry::SelfTest` Case 5 mislabeled "capacity overflow"; the real overflow branch is uncovered

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh`, Lines: 310-319 (Case 5 body) + 128-134 (uncovered branch in `Add()`)
- Service: `[ea]` core/SelfTest harness

**Code:**
```mql5
// core/SlotRegistry.mqh:310-319 — Case 5 in SelfTest
// --- Case 5 — capacity overflow surface (Add NULL returns false)   ← misleading comment
CSlotRegistry r5;
r5.Init(logger);
r5.SetOwnsSlots(false);
if(r5.Add(NULL))                        // ← actually tests NULL guard, not overflow
  {
   logger.Error("system", "SelfTest_SlotRegistry", 0,
                "Case 5 fail: Add(NULL) should return false");
   return false;
  }

// core/SlotRegistry.mqh:128-134 — the actual overflow branch (UNCOVERED)
if(m_count >= PHOENICISNEX_SLOT_CAPACITY)   // ← never exercised by SelfTest
  {
   if(m_logger != NULL)
      m_logger.Error("SlotRegistry", "capacity_exceeded",
                     0, StringFormat("limit=%d", PHOENICISNEX_SLOT_CAPACITY));
   return false;
  }
```

Also class doc at line 234:
```
//|   5. Capacity overflow → Add returns false                        ← false claim
//|   6. PendingState() default = PENDING_STATE_IDLE                  |
```

**Problem:**
Case 5 comment + class docblock both claim Case 5 exercises "capacity overflow", but the body calls `Add(NULL)` once. That tests the **NULL-guard branch** of `Add()` (`if(slot == NULL)` at SlotRegistry.mqh:122-127), not the **capacity branch** (`if(m_count >= PHOENICISNEX_SLOT_CAPACITY)` at lines 128-134). The capacity branch ships in Phase 1 untouched by any test — for IMPL-018 the registry is `PHOENICISNEX_SLOT_CAPACITY=21` and the only call site that could hit it is `RegisterAll()` which is currently a stub returning `false`. Once IMPL-053 wires real RegisterAll + a 22nd slot accidentally gets added (refactor regression), the capacity guard fires for the first time in production with no SelfTest precedent.

The drift is documentation-vs-reality. Round 05 Fix 05.10 hardened the `Init()` re-init path → `ReleaseAll()` (good, prevents heap leak), but did not extend SelfTest cases to cover the overflow branch.

**Why This Matters:**
1. **False coverage signal.** Engineer reading SelfTest output sees "6 cases — sentinel + slot-id + capacity + pending default" and trusts capacity is exercised. Audit failure under Code Review Dimension #7 (Test Coverage Gaps).
2. **IMPL-053 regression seam.** `RegisterAll()` body lands at IMPL-053+ — at that point a typo or copy-paste bug could enqueue 22 slots instead of 21. Without a SelfTest case that adds 22 stubs in a loop, the regression slips past G1 compile + G2 smoke → first reproduces at G3 backtest with cryptic broker-side symptoms.

**Suggested Fix:**

```mql5
// core/SlotRegistry.mqh:310-319 — split Case 5 into two cases
// --- Case 5a — NULL-guard surface (Add(NULL) returns false)
CSlotRegistry r5a;
r5a.Init(logger);
r5a.SetOwnsSlots(false);
if(r5a.Add(NULL))
  {
   logger.Error("system","SelfTest_SlotRegistry",0,
                "Case 5a fail: Add(NULL) should return false");
   return false;
  }

// --- Case 5b — capacity overflow surface (22nd Add returns false)
CSlotRegistry r5b;
r5b.Init(logger);
r5b.SetOwnsSlots(false);
for(int k = 0; k < PHOENICISNEX_SLOT_CAPACITY; k++)
  {
   if(!r5b.Add(good_slot_a))   // re-add same stub; topo check skipped (count == 1 path covered already)
     { logger.Error("system","SelfTest_SlotRegistry",0,
                    StringFormat("Case 5b fail: Add #%d unexpected reject", k));
       return false; }
  }
if(r5b.Add(good_slot_a))   // 22nd add — must reject
  {
   logger.Error("system","SelfTest_SlotRegistry",0,
                "Case 5b fail: 22nd Add() should reject (capacity)");
   return false;
  }
```

Update class docblock:
```
//|   5a. NULL-guard surface → Add(NULL) returns false               |
//|   5b. Capacity overflow surface → 22nd Add returns false         |
//|   6.  PendingState() default = PENDING_STATE_IDLE                 |
```

**Level of Effort:** Low (~15 LOC added in SelfTest body + docblock update + Spike_CSlotBase.mq5 invocation unchanged).

---

## Cross-Service Issues

| # | Issue | Drift between | Severity | Resolution path |
|---|-------|---------------|----------|-----------------|
| 1 | Pip arithmetic — 19 slots inline + ignore `helpers/PipMath` | slots/* (19) ↔ helpers/PipMath.mqh ↔ services/TimeGate.mqh (1 consumer) | HIGH (Finding 06.1) | Wire CPipMath into CSlotBase composition root |
| 2 | Input enable-toggle naming — Slot_H is `InpHEnabled`, 18 siblings `InpEnableSlot<X>` | inputs/Inputs_Slot_H.mqh ↔ 18 sibling input files | MEDIUM (Finding 06.2) | Rename 1 input + 2 call sites |
| 3 | NormalizeDouble discipline on broker-bound SL — 6/14 entry-slots drift | slots/Slot_B,K,L,LX,S,H ↔ slots/Slot_C,G,G2,I,M,Q,R,T (canonical) | MEDIUM (Finding 06.3) | Wrap 6 sl_price expressions with NormalizeDouble |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 06.1 | 🟠 HIGH | Architecture (ea.md) + Over-Engineering | 19 slots reimplement pip arithmetic; `helpers/PipMath.mqh` unused at slot layer | 19 slot files + helpers/PipMath.mqh + CSlotBase Composition Root | Medium |
| 06.2 | 🟡 MEDIUM | Cross-Service Consistency (NFR-6.3) | Slot_H input `InpHEnabled` vs canonical `InpEnableSlotH` | inputs/Inputs_Slot_H.mqh:11 + slots/Slot_H.mqh:178,204 | Low |
| 06.3 | 🟡 MEDIUM | Test Quality / Broker-edge correctness (ea.md) | 6 slots compute `sl_price` without `NormalizeDouble(..., _Digits)` | slots/Slot_B,K,L,LX,S,H | Low |
| 06.4 | 🔵 LOW | Test Coverage Gap | `CSlotRegistry::SelfTest` Case 5 mislabeled "capacity overflow"; real branch uncovered | core/SlotRegistry.mqh:310-319 + 128-134 + 234 docblock | Low |

---

## Recommendation

**Ready for fix round.** No CRITICAL or systemic-defect findings; Round 05 already collapsed the worst slot-layer drift (CTrade member + Order/Position-API + missing registry rows). Round 06 surfaces the layer-discipline gap (slots → helpers/PipMath) + 2 broker-edge correctness drifts that would otherwise materialize as IMPL-053 regressions.

**Strongly recommend bundling 06.1 + 06.3 in one commit** — both are pip-arithmetic-adjacent; fixing 06.1 (PipMath wiring) gives a natural NormalizeForBroker hook that resolves 06.3. Independent: 06.2 (Slot_H rename) + 06.4 (SelfTest split).

**Sequencing:** Apply Round-06 fixes BEFORE IMPL-039 (Slot_BI G4 SL fix per ADR-009 — Bucket B attestation point). Landing IMPL-039 on top of an already-drifted slot layer makes Bucket B isolation harder and entrenches the pattern. Same logic that motivated `/impl-review all` on the Round-05 → Round-06 boundary applies here.

**Next:** `/impl-review-fix docs/code-review/review-round-06.md` → expect ≤ 1 file edit per slot for 06.1 (~19 files) + 1 edit for 06.2 + 6 edits for 06.3 + 1 edit for 06.4. G1 spike compile must re-run for all touched slots; G2/G3/G4 deferred per header-only `.mqh` precedent (gates activate at IMPL-053+).
