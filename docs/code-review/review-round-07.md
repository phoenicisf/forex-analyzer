# Code Review Round 07

| Field | Value |
|-------|-------|
| **Round** | 07 |
| **Target** | `all` — adversarial sweep on the two slot files shipped post fix-round-06: `slots/Slot_BI.mqh` (IMPL-039 — G4 SL inheritance fix per ADR-009, Bucket B) + `slots/Slot_P.mqh` (IMPL-034 — P-Pending sub-modes per `04 § 4.4`, A7 risk surface) + their input headers (`Inputs_Slot_BI.mqh`, `Inputs_Slot_P.mqh`) + cross-cuts ที่ Round 06 ปิดไม่จับ (PMR canonical helper bypass, P-Pending payload schema drift, BR-6.4 legacy timeout reset semantics, dead `MqlTradeRequest` plumbing) |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~850 LOC: Slot_P (567 LOC) + Slot_BI (283 LOC) + 2 input headers (62 LOC). Cross-references read: `services/PendingMachineRegistry.mqh` § P-Pending API (lines 227-458, 436-458 EnterPPending helper), `docs/api-specs/state-persistence-schema.yaml` § PendingMachineState_PVariant (lines 215-237), `domain/CSlotBase.mqh` (Round-06 06.1 helpers), `services/PortfolioState.mqh::GetTicketsForSlot` (lines 356-366). Round 06 `_PipsToPrice/_NormalizeBrokerPrice` adoption verified across both new slots — drift surface stays at 1. |
| **Cumulative LOC reviewed (R01..R07)** | ~7,200 LOC across slot/services/core/helpers layers |
| **Plan Staleness Sentinel** | 3 closures since R06 (IMPL-039 + IMPL-034 + IMPL-013) — well below 10-closure threshold; Round 07 fired by adversarial sweep request, ไม่ใช่ sentinel |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **5** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No `WebRequest` / external `#import` / hardcoded creds in Slot_BI / Slot_P / inputs. Symbol whitelist still enforced upstream (OnInit, untouched by IMPL-034/039). |
| 2 | Business Logic Correctness | ⚠️ Finding | **Slot_P `EnterPending` injects `"dir"` field that is NOT defined in `PendingMachineState_PVariant` schema** — direction is not part of canonical persisted P-Pending payload (Finding 07.1 HIGH). Plus **legacy-timeout window resets on sub-mode lock** (Finding 07.3 MEDIUM) — BR-6.4 70-bar window can extend silently when N→PX/PH transition happens late. |
| 3 | Error Handling | ✅ Pass | NULL-guards consistent in both new slots (`m_risk`, `m_logger`, `m_pending`); fail-fast `return` paths behave per ADR-002 layer-2 contract. Slot_P `ManageExits` early-return on `_PipSize() <= 0.0` is silent — minor (rolled into Finding 07.5 LOW). |
| 4 | Performance | ✅ Pass | Slot_BI / Slot_P iterate O(tickets-per-magic) with bounded list; no N+1 over indicator handles; no allocations inside tick path (StringFormat is unavoidable per Logger contract). |
| 5 | Over-Engineering | ⚠️ Finding | **Slot_P fully populates `MqlTradeRequest req` + `MqlTradeResult res` (38 LOC across two sites — lines 338-349 + 456-467) but never calls `OrderSend` (commented as "Phase-1 stub")** (Finding 07.4 MEDIUM). Same Phase-1 stub semantic that Slot_BI / Slot_R / 19 sibling slots implemented as pure log-intent without unused trade-request scaffolding. Adds 38 LOC of dead struct-initialization that must compile + maintain forever for zero behavior delta. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **Slot_P bypasses `CPendingMachineRegistry::EnterPPending(mode, diff_sl, band_ratio, bar)` canonical helper at PMR.mqh:453-458** and hand-rolls JSON via raw `EnterPending(PM_P, payload, bar)` at Slot_P.mqh:389,420 (Finding 07.2 MEDIUM). Same drift class Round 06 06.1 collapsed for pip arithmetic (19 inline → 1 helper) — re-introduced one layer up. |
| 7 | Test Coverage Gaps | ✅ Pass | Spike_Slot_BI 6 SelfTest cases + Spike_Slot_P (per impl-plan TL;DR) ship G1 0err/0warn. PMR SelfTest Case 4 covers PSUB_PX/PH/E round-trip via `_BuildPPayloadStatic` — exactly the helper Slot_P bypasses; latent test gap surfaces under Finding 07.2 (drift not caught because canonical helper has tests, hand-rolled path doesn't). |
| 8 | Architecture Compliance | ✅ Pass | ADR-002 6-method contract honored on both slots (Magic/SlotId/Evaluate/ManageExits/DependsOn/PendingState). ADR-012 include discipline holds (no `slots/<other>` includes; both files include only `domain/`, `services/`, `inputs/`). ADR-005 shared-magic comment-prefix pattern correctly applied (BI prefix "BI," disambig from B "B,"; P prefix "P," vs PI "PI,"). |
| 9 | TD Compliance | ⚠️ Finding | **Slot_P P-Pending payload diverges from `state-persistence-schema.yaml § PendingMachineState_PVariant` lines 220-237** (Finding 07.1 HIGH) — schema defines exactly `{sub_mode, diff_sl, band_ratio}`; injected `"dir"` field has no schema definition + no PMR getter. State-persistence round-trip will silently lose direction on EA restart unless schema amended OR direction encoded inside an existing field (e.g., signed `diff_sl`). |
| 10 | Test Code Quality | ✅ Pass | No regex usage in slot bodies; Slot_BI/Slot_P loops are bounded by `n` from PortfolioState (currently stubbed to 0 — TODO IMPL-007 — but bounded by SlotState ticket array when implemented). No shared mutable state between instances. SelfTest harnesses (Spike_Slot_BI / Spike_Slot_P) live in `simulation/` not committed in this scope. |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `docs/state/impl-plan.md` returns **0 hits** for "deferred to operator-runtime" / "deferred to post-launch operator phase" / "deferred per .* precedent" / "structurally complete.*deferred" — Round 06 Claim 06.2 backfill remains intact post 3 closures (IMPL-039/034/013). 35 Active rows in `deferred-ac-registry.md` (24 P3 + 6 P1 + 5 P2) all have bounded expiry 2026-05-17/18 + risk-if-missed text. IMPL-039 evidence row references `g4-fix-attestation.md § Fix #2` — file exists at `docs/state/g4-fix-attestation.md` (live journal evidence still pending IMPL-053+; correctly modeled as Active row, not silent defer). |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface; both new slots are header-only `.mqh` files consumed by entry `.mq5` at IMPL-060. PhoenicisNex Tier 1.5 walk = headless backtest + Tester log + journal audit (per CLAUDE.md §1) — pending IMPL-053+ runnable surface, deferred-AC tracked. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret / API-key consumer (per CLAUDE.md §6 config-audit gate note). All 11 Slot_P inputs + 6 Slot_BI inputs are MT5 `input` declarations with `group="Slot P"` / `group="Slot BI"` annotations per NFR-6.3. Naming canonical (`InpEnableSlotP` / `InpEnableSlotBI` — Round 06 06.2 InpHEnabled→InpEnableSlotH precedent honored). |

---

## Findings

### Finding 07.1: 🟠 HIGH — Slot_P P-Pending payload injects non-schema `"dir"` field — direction silently lost on state.json round-trip

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 383-393 (IDLE→PENDING enter), 401 (PENDING re-read), 410-414 (sub-mode lock re-enter)
- File (cross-ref schema): `docs/api-specs/state-persistence-schema.yaml`, Lines: 215-237 (`PendingMachineState_PVariant`)
- File (cross-ref PMR): `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`, Lines: 227-239 (`_BuildPPayload`), 436-449 (`GetPSubMode/GetPDiffSL/GetPBandRatio` — **no `GetPDir` getter**)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:385-389  (IDLE → PENDING entry)
string payload = StringFormat(
   "{\"sub_mode\":\"%s\",\"diff_sl\":%.2f,\"band_ratio\":%.2f,\"dir\":\"%s\"}",
   mode_str, diff_sl_pip, band_ratio, dir);
m_pending.EnterPending(PM_P, payload, ctx.bar_index_h4);

// Slot_P.mqh:401  (PENDING re-read on next tick)
bool isBuy = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);
```

```yaml
# state-persistence-schema.yaml:215-237  (canonical PendingMachineState_PVariant)
PendingMachineState_PVariant:
  allOf:
    - $ref: "#/definitions/PendingMachineState_Bounded"
    - type: object
      properties:
        sub_mode:    { type: [string, "null"], enum: [PX, PH, E, N, null] }
        diff_sl:     { type: [number, "null"] }
        band_ratio:  { type: [number, "null"] }
# NO `dir` field defined.
```

**Problem:**
Slot_P encodes BUY/SELL direction as a **non-schema field** `"dir"` injected directly into the PendingMachineState_PVariant payload string. Three breakages:

1. **Schema-contract violation.** `docs/api-specs/state-persistence-schema.yaml § PendingMachineState_PVariant` defines exactly three keys (`sub_mode`, `diff_sl`, `band_ratio`). The schema is the **single source of truth** per CLAUDE.md §3 ("intra-process contracts via JSON Schema in `docs/api-specs/*.yaml`") and per TD-04 (StatePersistence schema validation drift = CRITICAL finding contract). Slot_P invents a fourth field with no schema entry — drift caught here is exactly the case that Round 06 Claim 06.1 collapse-pip-arithmetic-drift was meant to prevent at one architectural layer up.
2. **No PMR getter — `dir` only readable via raw StringFind.** PMR exposes `GetPSubMode() / GetPDiffSL() / GetPBandRatio()` for the three canonical fields. There is no `GetPDir()` — Slot_P at line 401 reads direction by literal substring search `StringFind(payload, "\"dir\":\"BUY\"")`. If the value were ever serialized differently (e.g., space after colon, or written as `BUY"` vs `\"BUY\"`), the substring match silently flips to FALSE → SELL on every PENDING tick. Brittle parser; PMR's `_ParsePDouble/_ParsePSubMode` handle whitespace tolerance — Slot_P's hand-rolled parser does not.
3. **State.json round-trip loses direction.** When `IMPL-047 StatePersistence::Save/Load` lands (P2, currently deferred), the saver will serialize `pending_payload` verbatim per schema. A schema-aware loader (or future amendment to drop unknown fields per JSON Schema `additionalProperties: false`) would reject or strip the `"dir"` key. Even if `additionalProperties: true` is permitted, downstream consumers (analytics, journal correlation) cannot rely on `dir` being present. After EA restart with persisted PENDING state, Slot_P would re-enter PENDING phase with `isBuy=false` (default branch of `StringFind == -1 → false`) → effectively forced SELL on every restored P-Pending state regardless of original direction.

**Why This Matters:**
Slot P is the largest slot (567 LOC, 11 inputs, 4 sub-modes) and one of two HIGH-RISK A7 surfaces (per impl-plan § Open Risks R-2/R-3). A direction-flip bug at restart is exactly the silent corruption class that Bucket A drift (NFR-1.1 ≤ 25% Net Profit deviation) cannot tolerate — half the trades would invert direction, doubling the drift instead of bounding it. The bug is dormant during Phase-1 because StatePersistence round-trip is deferred to IMPL-047, but ships as a time-bomb that lights up at the exact moment IMPL-047 lands. Since Round 06 spent effort hardening schema discipline, allowing schema drift in Round 07 regresses the architectural contract.

**Suggested Fix:**
Encode direction without inventing a non-schema field. Two clean options:

**Option A — Use signed `diff_sl` as direction indicator (schema-compatible):**
```mql5
// Slot_P.mqh:385-389  (sign convention: BUY=positive, SELL=negative)
double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
m_pending.EnterPPending(PSUB_N, signed_diff_sl, band_ratio, ctx.bar_index_h4);

// Slot_P.mqh:401
double signed_ds = m_pending.GetPDiffSL();
bool isBuy = (signed_ds >= 0.0);
double diff_sl_abs = MathAbs(signed_ds);
```
This uses the canonical `EnterPPending` builder (also fixes Finding 07.2) and stays inside schema bounds. Add a Schema-comment line in state-persistence-schema.yaml § diff_sl: `"sign carries direction: BUY ≥ 0, SELL < 0 (Slot_P only)"`.

**Option B — Amend schema to add `dir` field, then add PMR getter:**
1. Update `state-persistence-schema.yaml § PendingMachineState_PVariant` properties to include `dir: {type: [string, "null"], enum: [BUY, SELL, null]}`.
2. Add `_BuildPPayload` overload + `GetPDir()` accessor in PMR.
3. Update PMR SelfTest Case 4 to round-trip the new field.
4. Update `_BuildPPayload` in PMR (currently signature `(mode, diff_sl, band_ratio)`) to accept direction. Update one existing caller (`EnterPPending` helper).

Option A is cheaper (no schema amendment + no PMR API change). Option B is more explicit + extensible if future sub-modes need richer state. Either way, do NOT keep the hand-rolled `"dir"` injection.

**Level of Effort:** Low (Option A: ~10 LOC change in Slot_P + 1 schema-comment line) / Medium (Option B: schema amendment + PMR API extension + SelfTest update)

---

### Finding 07.2: 🟠 HIGH — Slot_P bypasses `CPendingMachineRegistry::EnterPPending` canonical helper; hand-rolls JSON instead

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 385-389 (IDLE→PENDING), 410-420 (sub-mode lock re-entry)
- Cross-ref helper available: `services/PendingMachineRegistry.mqh:453-458` (`EnterPPending(EPSubMode mode, double diff_sl, double band_ratio, int current_bar)`)
- Cross-ref canonical builder: `services/PendingMachineRegistry.mqh:227-239` (`_BuildPPayload`)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:383-389  (hand-rolled — bypass canonical helper)
string mode_str = "N";
string payload  = StringFormat(
   "{\"sub_mode\":\"%s\",\"diff_sl\":%.2f,\"band_ratio\":%.2f,\"dir\":\"%s\"}",
   mode_str, diff_sl_pip, band_ratio, dir);
m_pending.EnterPending(PM_P, payload, ctx.bar_index_h4);
```

```mql5
// services/PendingMachineRegistry.mqh:451-458  (canonical helper — unused by Slot_P)
//--- Helper for slots: build the canonical P-Pending payload + transition
//    PM_P to PENDING in one step.
void EnterPPending(EPSubMode mode, double diff_sl, double band_ratio,
                    int current_bar)
  {
   string payload = _BuildPPayload(mode, diff_sl, band_ratio);
   EnterPending(PM_P, payload, current_bar);
  }
```

**Problem:**
PMR ships an explicit "canonical-form" helper `EnterPPending` precisely so slots do not hand-roll P-Pending payload JSON — the helper guarantees schema conformance + DoubleToString precision (`.2`) + key order matching `_BuildPPayload` (consumed by `_ParsePSubMode` / `_ParsePDouble`). Slot_P is the **only** caller of `EnterPending(PM_P, ...)` outside of PMR itself; every other Slot that uses PMR (Slot_C/D/F/J/M/T/Q/R per impl-plan TL;DR) routes through the per-slot canonical helper or PMR's `EnterPending` with the simpler payload schemas (PendingMachineState_BoundedC/F/J/etc.).

The drift surface this introduces is identical to Round 06 06.1 (19 slots reimplementing pip arithmetic instead of using `helpers/PipMath.mqh`):

1. **Format drift.** PMR's `_BuildPPayload` uses `DoubleToString(value, 2)` — Slot_P's `StringFormat("%.2f", ...)` may differ on locale-sensitive builds (MQL5 standard says no but worth flagging for future Phase-2 multi-locale operators).
2. **Key-order coupling.** PMR's `_ParsePDouble` uses `StringFind(payload, "\"" + field + "\":")` so order doesn't matter for parse — but if any future consumer (e.g. logging tail compare in journal correlation) does substring match on the full payload, the order Slot_P writes (sub_mode, diff_sl, band_ratio, dir) vs PMR's (sub_mode, diff_sl, band_ratio) differs by exactly the trailing comma + extra field.
3. **Maintenance burden.** Schema changes (e.g., adding `triggered_at_bar` field per future P4 IMPL-062 advanced trigger lookback) now require touching TWO call sites — PMR's `_BuildPPayload` and Slot_P's hand-rolled `StringFormat`. Round 06 explicitly collapsed this drift class for pip math; Round 07 regression.

**Why This Matters:**
This is the second dimension of the same defect class as Finding 07.1. Even if 07.1's `"dir"` field is removed via Option A (signed `diff_sl`), Slot_P would still hand-roll `EnterPending` with manual JSON instead of invoking `EnterPPending`. Architectural contract: there's exactly one authoritative payload builder (`_BuildPPayload`), and slots call it via the public façade (`EnterPPending`). The hand-rolled site exists because of 07.1's `"dir"` field — fixing 07.1 mechanically removes 07.2 if Option A is chosen. Worth raising separately because the **smell** (slot reaches into raw PMR API instead of slot-friendly helper) needs explicit acknowledgement and is not auto-fixed if 07.1 is resolved via schema amendment (Option B keeps the hand-rolled call site even after schema fix unless `_BuildPPayload` signature is updated).

**Suggested Fix:**
Combined with Finding 07.1 Option A:
```mql5
// Slot_P.mqh:383-393  (replace 7 LOC with 4)
double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
m_pending.EnterPPending(PSUB_N, signed_diff_sl, band_ratio, ctx.bar_index_h4);
m_logger.Info("SlotP", "pending_entered", MAGIC_P,
              StringFormat("dir=%s sub_mode=N diff_sl_pip=%.1f band_ratio=%.1f bar=%d",
                           dir, diff_sl_pip, band_ratio, ctx.bar_index_h4));

// Slot_P.mqh:410-420  (sub-mode lock — same pattern)
double signed_ds_locked = isBuy ? diff_sl : -diff_sl;
m_pending.EnterPPending(resolved, signed_ds_locked, band_rat, ctx.bar_index_h4);
```
After this, the **only** caller of raw `EnterPending(PM_P, ...)` is PMR's own `EnterPPending` — assertion: forbidden-pattern grep `EnterPending(PM_P,` in `slots/` returns 0 hits.

**Level of Effort:** Low (rolled into 07.1 Option A fix; ~6 LOC delta net)

---

### Finding 07.3: 🟡 MEDIUM — Slot_P sub-mode-lock re-enters PENDING with current bar — silently extends BR-6.4 70-bar legacy timeout window

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 416-422 (sub-mode lock re-enter)
- File (cross-ref): `services/PendingMachineRegistry.mqh:400-409` (`EnterPending` resets `pending_started_bar`)
- File (cross-ref BR): `docs/ba/04-business-rules.md` § BR-6.4 (P legacy timeout 70 H4 bars)
- File (cross-ref data flow): `docs/design-docs/04-data-flow.md` § 4.4 (P sub-mode lock semantics)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:416-422
//--- Re-enter pending with locked sub-mode (preserves bar_index via
//    EnterPending overwrite — PMR resets pending_started_bar but
//    legacy timeout window is the slot's tolerance for retest, so
//    fresh timer on lock is acceptable per `04 § 4.4` lock semantics).
m_pending.EnterPending(PM_P, new_pl, ctx.bar_index_h4);
sub = resolved;
```

```mql5
// services/PendingMachineRegistry.mqh:400-409  (EnterPending unconditionally resets pending_started_bar)
void EnterPending(EPendingMachineId id, string payload, int current_bar)
  {
   if(id < 0 || id >= PM_COUNT) return;
   m_machines[id].state               = PENDING_STATE_PENDING;
   m_machines[id].pending_started_bar = current_bar;       // ← RESET
   m_machines[id].pending_payload     = payload;
   ...
  }
```

**Problem:**
The comment claims "fresh timer on lock is acceptable per `04 § 4.4` lock semantics" — but `04-data-flow.md § 4.4` does not contain language authorizing a timeout reset on N→{PX,PH} sub-mode lock. The timeout is BR-6.4 (70 H4 bar legacy timeout from `docs/ba/04-business-rules.md`); the sub-mode lock is an internal payload mutation, not a timeout-relevant transition. Two concrete problems:

1. **Silent timeout extension.** Worst case: Slot_P enters PENDING at bar 100 (sub_mode=N). At bar 169 (1 bar before timeout), the sub-mode resolution branch fires (PX or PH lock). `EnterPending` resets `pending_started_bar` to 169. The pending state now lives until bar 239 instead of bar 170 — a 70-bar extension on a 70-bar window, doubling the effective tolerance. PMR.TickAll's force-clear logic uses `current_bar - pending_started_bar` to detect timeout, so the reset directly defeats BR-6.4.
2. **Comment self-contradicts and is unsourced.** The inline justification ("per `04 § 4.4` lock semantics") is not citable — `04 § 4.4` discusses PX/PH/E semantic, not timer reset on lock. The comment also says "preserves bar_index via EnterPending overwrite" which is the opposite of what the code does (overwrite ≠ preserve).

**Why This Matters:**
Slot P is on the High-Risk-task list (impl-plan § Open Risks R-2/R-3) precisely because behavioral correctness drift is hard to detect from compile/log alone. Bucket A drift (NFR-1.1 ≤ 25% Net Profit deviation) is the regression contract; a stale-pending → late-execute sequence flips trade timing by exactly the 70-bar window every time the sub-mode lock fires after several bars of N — non-deterministic from input parameters, deterministic from market path. Empirical Tester run (IMPL-053+ runnable surface) will not surface this because PSUB_N typically resolves on the same bar (force_h4.f1 + bb width are both available at IDLE→PENDING). Bug only fires when N→PX/PH lock is delayed (e.g., when `_ResolvePSubMode` returns PSUB_PH because diff_sl was below threshold on the IDLE→PENDING bar but rises above on a later bar — exactly the band-widening scenario the lock semantic is designed for).

**Suggested Fix:**
Add a PMR helper that **mutates payload only** without touching `pending_started_bar`:
```mql5
// services/PendingMachineRegistry.mqh — new public method
void OverwritePayload(EPendingMachineId id, string payload)
  {
   if(id < 0 || id >= PM_COUNT) return;
   m_machines[id].pending_payload = payload;     // pending_started_bar unchanged
   if(m_logger != NULL)
      m_logger.Info("pending", "payload_overwrite", 0,
                    StringFormat("machine=%s", _IdToCode(id)));
  }

// Slot_P.mqh:416-422  (replace EnterPending with OverwritePayload)
double signed_ds_locked = isBuy ? diff_sl : -diff_sl;
string new_pl = ... /* canonical via EnterPPending builder if exposed */;
m_pending.OverwritePayload(PM_P, new_pl);
```
Cite BR-6.4 explicitly in the new comment ("BR-6.4 70-bar legacy timeout — payload mutation must not reset pending_started_bar"). Add PMR SelfTest case: enter PENDING at bar X → OverwritePayload at bar X+5 → verify `pending_started_bar` still == X.

**Level of Effort:** Low (1 new PMR method + 1 SelfTest case + Slot_P call site swap)

---

### Finding 07.4: 🟡 MEDIUM — Slot_P fully populates `MqlTradeRequest req` + `MqlTradeResult res` at two sites but never calls `OrderSend` — 38 LOC of dead struct-init

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 338-349 (pyramid path), 456-467 (primary path)
- Pattern reference (clean precedent): `slots/Slot_BI.mqh:208-229` (log-intent only — no `MqlTradeRequest` scaffolding)
- Pattern reference (clean precedent): `slots/Slot_R.mqh` (per impl-plan IMPL-033 closure note — log-intent stub)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:338-349 + comment 297-299
// NOTE: All OrderSend submissions are Phase-1 stubs — actual
//       broker call deferred to IMPL-053+ Orchestrator wiring per
//       slot precedent (Slot_R IMPL-033 + sibling slots).
...
MqlTradeRequest req = {};
MqlTradeResult  res = {};
req.action       = TRADE_ACTION_DEAL;
req.symbol       = _Symbol;
req.volume       = lot;
req.type         = ot;
req.price        = _NormalizeBrokerPrice(price);
req.sl           = sl_price;
req.tp           = 0.0;
req.comment      = comment;
req.magic        = MAGIC_P;
req.type_filling = ORDER_FILLING_FOK;
// ... no OrderSend(req, res) — just m_logger.Info and fall through
```

**Problem:**
Slot_P populates `MqlTradeRequest req` + `MqlTradeResult res` (12 fields × 2 sites = 24 assignment lines + 2 declarations + 12 LOC of comment scaffolding ≈ 38 LOC total) but never calls `OrderSend(req, res)`. The variables fall out of scope at function end. The neighboring G4-fix slot (Slot_BI, IMPL-039 — also Phase-1 stub) ships the same intent in 9 LOC of `m_logger.Info(StringFormat(...))` without the trade-request scaffold. This is a dead-code anti-pattern that:

1. **Adds maintenance burden for zero behavior.** Every future MQL5 platform delta (e.g., `type_filling` field addition in MT5 build 4XXX, or `request_id` propagation from MT5 5.0) requires touching the dead `req = {}` initialization in two more places. Slot_BI/Slot_R style (log-intent only) is immune.
2. **Violates "don't add features beyond what task requires" CLAUDE.md §6 rule** ("Don't add features, refactor, or introduce abstractions beyond what the task requires"). The Phase-1 stub contract is "log entry intent" — populating MqlTradeRequest is a Phase-2 concern (IMPL-053+ Orchestrator wiring).
3. **Misleads readers.** A reviewer scanning `req.sl = sl_price` may reasonably infer that this slot DOES submit orders (most other code paths that build MqlTradeRequest end with `OrderSend`). Cognitive overhead = unnecessary.
4. **Creates code-review false-positive blocking pattern.** If IMPL-053+ Orchestrator engineer copies this scaffold into RiskManager wiring without realizing it's dead, they will write `OrderSend(req, res)` against the wrong target — leading to direct broker calls from slot layer in violation of ADR-002 (CTrade/RiskManager indirection).

**Why This Matters:**
Slot_P is the second-largest slot file in the project (567 LOC) and the deferred-AC count for IMPL-034 is 2 rows (smoke 60-day backtest + log-assertion of sub-mode lifecycle). When IMPL-053+ engineer reads Slot_P to wire RiskManager, they must distinguish "intentional log-intent stub" (Slot_R precedent) from "trade-request scaffold awaiting OrderSend" (Slot_P current shape). The two patterns are intermixed in P3 — LX/S/H/B/BR/J/C/D/F/M/T/Q/R/G/G2/I/GO/K/L/BI follow log-intent; Slot_P alone follows scaffold. This is the exact category of inconsistency Round 06 06.1/06.2 collapsed for pip arithmetic and input naming.

**Suggested Fix:**
Strip MqlTradeRequest/MqlTradeResult scaffold; collapse to log-intent only — match Slot_BI/Slot_R precedent:
```mql5
// Slot_P.mqh — replace lines 338-355 (pyramid path) with:
m_logger.Info("SlotP", "entry_signal_pyramid", MAGIC_P,
              StringFormat("sub_mode=E dir=%s lot=%.2f sl_pips=%.1f "
                           "price=%.5f sl=%.5f comment=%s parent_open=%.5f "
                           "(Phase-1 stub: OrderSend deferred to IMPL-053+)",
                           dir_str, lot, sl_pips, price, sl_price,
                           comment, parent_open));

// Slot_P.mqh — replace lines 456-475 (primary path) with:
m_logger.Info("SlotP", "entry_signal", MAGIC_P,
              StringFormat("sub_mode=%s dir=%s lot=%.2f sl_pips=%.1f "
                           "price=%.5f sl=%.5f comment=%s "
                           "(Phase-1 stub: OrderSend deferred to IMPL-053+)",
                           sub_str, (isBuy ? "BUY" : "SELL"), lot, sl_pips,
                           price, sl_price, comment));
m_pending.TransitionExecuted(PM_P);
```
Net delta: −36 LOC. G1 still passes (no untouched compile dependency). G4 log-assertion E-AC still verifiable (the same Info line is the journal observable).

**Level of Effort:** Low (~36 LOC removal, no new logic, no test impact)

---

### Finding 07.5: 🔵 LOW — Slot_P ManageExits self-contradicting comment block + silent early-return on `_PipSize() <= 0.0`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 494-505
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:494-505
//--- Iterate union of "P," + "PI," tickets via two GetTicketsForSlot calls.
//    "P," call returns both (StringFind precedent — "PI," startsWith "P,"
//    only at offset 0 char ',' vs 'I' so "P," prefix-match excludes "PI,"
//    actually NO — startsWith "P," means comment[0..2]=="P,"; "PI,..." has
//    comment[1]='I' ≠ ',' so it does NOT match. We use both calls below.)
ulong tickets_p[];
int n_p = port.GetTicketsForSlot(MAGIC_P, "P,", tickets_p);
ulong tickets_pi[];
int n_pi = port.GetTicketsForSlot(MAGIC_P, "PI,", tickets_pi);

double pip_size = _PipSize();
if(pip_size <= 0.0) return;   // silent early-return — no warn log
```

**Problem:**
Two LOW-severity smells in the same block:

1. **Self-contradicting comment.** Lines 495-498 claim `"P," call returns both` then immediately reverse with `actually NO`. The author talked themselves out of an incorrect mental model in-place; the residue is a 5-line comment that confuses future readers. The correct statement is one sentence: `"PortfolioState.GetTicketsForSlot uses startsWith semantic — "P," matches "P,..." only; "PI,..." has comment[1]='I' ≠ ',' so PI tickets need a second call."`
2. **Silent early-return on degenerate `_PipSize()`.** Line 505 returns from ManageExits with no log when `_PipSize() <= 0.0`. This is the same fail-safe that other slots use (Slot_H:114-115 etc.) but in those slots the early-return is at Evaluate (entry) not ManageExits (exit) — early-return on exit means open positions are not exit-checked, which is an exit-loss-of-control rather than an entry-skip. NFR-5.1 requires loud failure on halt-class events; degenerate pip_size during exit pass is exactly that class. Should `m_logger.Error(...)` + `Alert(...)` per NFR-5.1 (CodeWiki §6.2 P2.3) — silent return masks the condition.

**Why This Matters:**
LOW because (a) `_PipSize() <= 0.0` is essentially impossible on EURUSD (`_Point > 0` always true on a connected symbol; `_Digits == 5 || _Digits == 3 ? 10 : 1` is always positive), and (b) the comment confusion is cosmetic. But: PhoenicisNex Phase 2 trigger (per BA `03 § 5 Note`) opens the door to multi-symbol — if pip_size detection becomes runtime-dependent, the silent-return path will fire and Slot_P will quietly stop managing exits while the EA appears healthy. NFR-5.1 + ADR-010 HALT semantic argue against any silent return on a degenerate symbol metric in the exit path.

**Suggested Fix:**
```mql5
// Slot_P.mqh:494-498  (replace 5-line comment with 1-line)
//--- "P," and "PI," need separate GetTicketsForSlot calls — startsWith
//    semantic excludes "PI," from "P," prefix-match (comment[1]='I'≠',').
ulong tickets_p[]; int n_p = port.GetTicketsForSlot(MAGIC_P, "P,", tickets_p);
ulong tickets_pi[]; int n_pi = port.GetTicketsForSlot(MAGIC_P, "PI,", tickets_pi);

// Slot_P.mqh:504-505  (replace silent return with loud error)
double pip_size = _PipSize();
if(pip_size <= 0.0)
  {
   m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                  StringFormat("_PipSize() returned %.10f — exit pass aborted; "
                               "symbol metric corrupt (NFR-5.1 surfacing)", pip_size));
   return;
  }
```

Drop the defensive `if(StringFind(c, "PI,") == 0) continue;` at Slot_P.mqh:517 too — once the comment correctly explains the startsWith semantic, the second-line filter is dead code (PortfolioState filter has already excluded PI from the P-loop output).

**Level of Effort:** Low (~10 LOC change)

---

## Cross-Service Issues

| # | Issue | Severity | Location |
|---|-------|----------|----------|
| C1 | `state-persistence-schema.yaml § PendingMachineState_PVariant` ↔ `slots/Slot_P.mqh` payload mismatch | HIGH | rolled into Finding 07.1 |
| C2 | `services/PendingMachineRegistry.mqh::EnterPPending` canonical helper ↔ `slots/Slot_P.mqh` raw `EnterPending` bypass | HIGH | rolled into Finding 07.2 |

**No new cross-service contradictions** beyond those rolled into the per-finding sections. Slot_BI shared-magic disambig (`MAGIC_B=214` shared with B per ADR-005) verified against `services/PortfolioState.mqh::GetTicketsForSlot` semantic + `helpers/CommentParser.mqh` longest-prefix-match contract. ADR-009 G4 SL inheritance fix (parent_sl pip distance applied at BI entry, fallback `InpBISlFallbackPips=80` when parent_sl=0) tracks the architectural primary `g4-fix-attestation.md § Fix #2` documentation correctly.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 07.1 | 🟠 HIGH | TD Compliance / Business Logic | Slot_P payload injects non-schema `"dir"` field; round-trip loses direction | `slots/Slot_P.mqh:383-401, 410-414` + `state-persistence-schema.yaml:215-237` | Low/Medium |
| 07.2 | 🟠 HIGH | Cross-Service Consistency | Slot_P bypasses `CPendingMachineRegistry::EnterPPending` canonical helper; hand-rolls JSON | `slots/Slot_P.mqh:383-389, 410-420` | Low |
| 07.3 | 🟡 MEDIUM | Business Logic / BR Compliance | Sub-mode lock re-enters PENDING with current bar; resets BR-6.4 70-bar legacy timeout | `slots/Slot_P.mqh:416-422` + `services/PendingMachineRegistry.mqh:400-409` | Low |
| 07.4 | 🟡 MEDIUM | Over-Engineering | Slot_P populates `MqlTradeRequest req` × 2 sites without `OrderSend` — 38 LOC dead scaffold | `slots/Slot_P.mqh:338-349, 456-467` | Low |
| 07.5 | 🔵 LOW | Code Quality / NFR-5.1 | Self-contradicting comment + silent early-return on degenerate `_PipSize()` in exit path | `slots/Slot_P.mqh:494-505` | Low |

---

## Aggregate Convergence Note

| Round | Findings | CRITICAL | HIGH | MEDIUM | LOW |
|-------|----------|----------|------|--------|-----|
| R01 | 1 | 0 | 1 | 0 | 0 |
| R02 | 5 | 1 | 2 | 2 | 0 |
| R03 | 7 | 0 | 4 | 2 | 1 |
| R04 | 0 | 0 | 0 | 0 | 0 |
| R05 | 10 | 0 | 5 | 4 | 1 |
| R06 | 4 | 0 | 1 | 2 | 1 |
| R07 | **5** | **0** | **2** | **2** | **1** |

**Trajectory observation:** Round 07 mirrors Round 06 shape (0/2/2/1 vs 0/1/2/1) — consistent low-defect-density floor on stabilized P3 slot surface. The HIGH findings are concentrated in **the single new file** (Slot_P, the larger of the two post-R06 commits) and form a **single architectural drift class**: P-Pending payload contract bypass (07.1 schema drift, 07.2 helper bypass, 07.3 timeout reset semantics — all symptoms of "Slot_P uses raw `EnterPending` instead of `EnterPPending`"). One root-cause fix (07.1 Option A + collapse to `EnterPPending` per 07.2) auto-resolves 07.3's surface as well if `OverwritePayload` is added.

**Reviewer recommendation:** Ready for `/impl-review-fix` — all 5 findings have concrete, low-effort fixes with clear scope. Slot_BI (IMPL-039 G4 fix) cleared the review with no findings, which is the desired outcome for a critical Bucket B drift attestation point. The Round 07 surface localizes to Slot_P's P-Pending payload handling. Recommend bundling 07.1+07.2+07.3 into a single fix-round commit (combined ~50 LOC) and 07.4+07.5 as separate housekeeping commit. Post-fix, IMPL-039+IMPL-034 attestation surface stable for IMPL-053+ Orchestrator wiring.
