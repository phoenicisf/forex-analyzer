# Code Review Round 08

| Field | Value |
|-------|-------|
| **Round** | 08 |
| **Target** | `all` — adversarial sweep on the post-fix-round-07 surface: `slots/Slot_P.mqh` (refactored Phase A/B per 07.1/07.2/07.3) + `services/PendingMachineRegistry.mqh` (+`OverwritePPayload`) + `docs/api-specs/state-persistence-schema.yaml` (sign-convention amendment). Also re-checks Slot_BI for parity since both shipped together; Slot_BI cleared Round 07 with 0 findings — reviewed again here for regression. |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~120 LOC delta from fix-round-07 (Slot_P −36 LOC dead scaffold + ~25 LOC Phase A/B refactor + 16 LOC PMR `OverwritePPayload` + 6 LOC schema amendment). Cumulative reviewed surface: full Slot_P (542 LOC) + Slot_BI (283 LOC) + PMR P-Pending API region (PMR.mqh:227-474). Cross-references read: `domain/CSlotBase.mqh` § pip helpers (lines 145-184, Round 06 06.1 collapse), `helpers/PipMath.mqh` § PipToPrice (canonical 5/3-digit detection), `services/PortfolioState.mqh::GetTicketsForSlot` (still stubbed at line 356-366 — IMPL-007 deferred). |
| **Cumulative LOC reviewed (R01..R08)** | ~7,300 LOC across slot/services/core/helpers layers |
| **Plan Staleness Sentinel** | 0 closures since R07 (R08 fired by post-fix-round-07 adversarial re-sweep request — fix landed in commit `b02c5e6`; no IMPL-NNN closure events between R07 and R08) — well below 10-closure threshold |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **5** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No `WebRequest` / external `#import` / hardcoded creds in delta surface. Symbol whitelist still enforced upstream (OnInit untouched). Schema amendment is a description-only change (no structural / typing change). |
| 2 | Business Logic Correctness | ⚠️ Finding | Sign convention `(diff_sl >= 0.0)` cannot disambiguate `+0.0` from `-0.0` (Finding 08.4 LOW) — degenerate `bb_top - bb_bot == 0` case round-trips SELL as BUY. |
| 3 | Error Handling | ⚠️ Finding | `pip_size <= 0.0` guard asymmetry between `ManageExits` (loud failure per Round 07.5) and `Evaluate` Path A/B (no guard) — Finding 08.2 MEDIUM. NULL-guards on `m_risk` / `m_logger` / `m_pending` consistent across Phase A/B per ADR-002 layer-2 contract. |
| 4 | Performance | ✅ Pass | No new N+1 or unbounded patterns in the delta surface; `OverwritePPayload` rebuilds payload with the same `_BuildPPayload` allocation pattern as `EnterPending` — no regression. |
| 5 | Over-Engineering | ✅ Pass | Round 07.4 dead `MqlTradeRequest` scaffold removed cleanly; Slot_P entry stubs now mirror Slot_BI/Slot_R log-intent shape. No new abstractions introduced. |
| 6 | Cross-Service Consistency | ⚠️ Finding | `_PipSize() * sl_pips` raw arithmetic re-introduces Round 06 06.1 collapse-drift class — Slot_P lines 322-323 + 432-433 should use `_PipsToPrice(sl_pips)` like Slot_BI:210 (Finding 08.1 MEDIUM). |
| 7 | Test Coverage Gaps | ⚠️ Finding | PMR SelfTest Case 4 not extended for (a) negative `diff_sl` round-trip per new sign convention or (b) `pending_started_bar` invariance under `OverwritePPayload` — fix-round-07 explicitly acknowledged + deferred; both are the empirical proof of Round 07.1 + 07.3 fixes (Finding 08.3 MEDIUM). |
| 8 | Architecture Compliance | ✅ Pass | ADR-002 6-method contract intact on both slots. ADR-012 include discipline holds. ADR-008 force-clear logic untouched (PM_P uses legacy timeout per BR-6.4). The new `OverwritePPayload` correctly preserves `pending_started_bar` per Round 07.3 fix intent. |
| 9 | TD Compliance | ✅ Pass | `state-persistence-schema.yaml § PendingMachineState_PVariant.diff_sl` description amended in-place; `type: [number, "null"]` unchanged → round-trip safe. Slot_P `_BuildPPayload` invocation routes through canonical helper now (`grep -nE 'EnterPending\(PM_P,' slots/` = 0 hits ✅). |
| 10 | Test Code Quality | ⚠️ Finding | `_ParsePDouble` (PMR.mqh:257-282) accepts `-` / `+` / `e` / `E` at **any** position in numeric token — `--250` or `1-2-3` would parse silently. Not exploitable in current call paths but a loose parser (Finding 08.5 LOW). |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `docs/state/impl-plan.md` returns **0 hits** for "deferred to operator-runtime" / "deferred to post-launch operator phase" / "deferred per .* precedent" / "structurally complete.*deferred". Round 06 Claim 06.2 backfill remains intact. 35 Active rows in `deferred-ac-registry.md` all have bounded expiry + risk-if-missed. fix-round-07 did not introduce any new `[x]` AC closures (it touched code only — no impl-plan checkbox state changes), so no new closure-discipline regression surface. |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface. PhoenicisNex Tier 1.5 walk = headless backtest + Tester log + journal audit (per CLAUDE.md §1) — pending IMPL-053+ runnable surface, deferred-AC tracked. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret / API-key consumer in delta surface. Schema amendment is `.yaml` description text only — no `process.env.X` introduced. |

---

## Findings

### Finding 08.1: 🟡 MEDIUM — Slot_P Evaluate raw `_PipSize() * sl_pips` arithmetic re-introduces Round 06 06.1 collapse-drift class

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 318-323 (Path A pyramid SL calc), 417-433 (Path B primary SL calc)
- Pattern reference (clean precedent): `slots/Slot_BI.mqh:210-213` (uses `_PipsToPrice(sl_distance_pip)` helper)
- Helper definition: `domain/CSlotBase.mqh:161-166` (`_PipsToPrice` — Round 06 06.1)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:318-323  (Path A pyramid)
double pip_size = _PipSize();
double sl_pips  = InpPSlPipsFloor;
double price    = parent_isBuy ? ctx.ask : ctx.bid;
double sl_price = parent_isBuy
                  ? _NormalizeBrokerPrice(price - sl_pips * pip_size)
                  : _NormalizeBrokerPrice(price + sl_pips * pip_size);

// Slot_P.mqh:417-433  (Path B primary — same pattern)
double pip_size = _PipSize();
double sl_pips  = (sub == PSUB_PX) ? diff_sl_abs : InpPSlPipsFloor;
...
double sl_price = isBuy
                  ? _NormalizeBrokerPrice(price - sl_pips * pip_size)
                  : _NormalizeBrokerPrice(price + sl_pips * pip_size);
```

```mql5
// slots/Slot_BI.mqh:210-213  (canonical pattern — Round 06 06.1 honored)
double sl_distance   = _PipsToPrice(sl_distance_pip);
                       ? _NormalizeBrokerPrice(bi_entry - sl_distance)
                       : _NormalizeBrokerPrice(bi_entry + sl_distance);

// domain/CSlotBase.mqh:161-166  (helper)
double _PipsToPrice(double pips) const
  {
   if(m_pip != NULL) return m_pip.PipToPrice(pips);
   return pips * _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
  }
```

**Problem:**
Round 06 06.1 explicitly collapsed 19 slots' inline pip-arithmetic (`pips * _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0)`) into a single canonical helper `_PipsToPrice` on `CSlotBase`. Slot_BI (the partner file in IMPL-039) honors this — line 210 reads `_PipsToPrice(sl_distance_pip)`. Slot_P, the partner file in IMPL-034, hand-rolls `sl_pips * pip_size` at TWO entry sites, raising `_PipSize()` directly into Slot_P scope when the helper layer is exactly designed to keep it private.

This is the same drift class Round 06 06.1 collapsed (raw pip math) and Round 07.2 collapsed (raw `EnterPending(PM_P, ...)`). Once a canonical helper exists on the base class, **every** new slot must route through it — otherwise the 5/3-digit detection rule becomes a maintenance hazard duplicated across slot files. Slot_P happens to compute `sl_pips * pip_size` identically to `_PipsToPrice(sl_pips)` today, but the moment `m_pip` (CPipMath) lands at IMPL-053+ Composition Root, only `_PipsToPrice` will use the wired CPipMath service; `_PipSize() * sl_pips` will silently bypass it (because `_PipSize()` returns `m_pip.PipToPrice(1.0)` when wired, and multiplication by a fractional `sl_pips` re-derives what `m_pip.PipToPrice(sl_pips)` would have returned directly with one less rounding step).

**Why This Matters:**
Round 06 fix-round-06 created the helpers specifically to localize pip arithmetic to one site. Slot_P's `pip_size * sl_pips` writeup is the second collapse-drift regression in two rounds (Round 07 fix-round-07 collapsed the `EnterPending(PM_P, ...)` call site at the architectural layer above). Letting it ship preserves the smell as a precedent — IMPL-053+ engineer wiring CPipMath into the Composition Root may then need to grep both `_PipsToPrice(...)` and `_PipSize() * ...` patterns across 21 slot files instead of one canonical site. Plus it makes Finding 08.2's `pip_size <= 0` guard asymmetry harder to fix because the guard would need duplication.

**Suggested Fix:**
```mql5
// Slot_P.mqh:318-323  (Path A pyramid — collapse to helper)
double sl_pips  = InpPSlPipsFloor;
double sl_dist  = _PipsToPrice(sl_pips);     // single canonical site
double price    = parent_isBuy ? ctx.ask : ctx.bid;
double sl_price = parent_isBuy
                  ? _NormalizeBrokerPrice(price - sl_dist)
                  : _NormalizeBrokerPrice(price + sl_dist);

// Slot_P.mqh:417-433  (Path B primary — same pattern)
double sl_pips  = (sub == PSUB_PX) ? diff_sl_abs : InpPSlPipsFloor;
if(sl_pips < InpPSlPipsFloor) sl_pips = InpPSlPipsFloor;
double sl_dist  = _PipsToPrice(sl_pips);
double price    = isBuy ? ctx.ask : ctx.bid;
double sl_price = isBuy
                  ? _NormalizeBrokerPrice(price - sl_dist)
                  : _NormalizeBrokerPrice(price + sl_dist);
```

Net delta: −2 LOC (drop two `double pip_size = _PipSize();` declarations now unused). Anti-regression assertion post-fix: `grep -nE '_PipSize\(\) ?\*' MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` returns **0 hits** (currently 2 hits at lines 322-323 and 432-433 via the indirect multiplication form). The remaining `_PipSize()` calls in Slot_P are at lines 206 (`_ComputeDiffSlPip`) — used as **divisor** (`width / pip_size` for pip-conversion), and line 254 (`_ParentProfitPipsAtLeast`) — same divisor pattern. Those are not collapsible into `_PipsToPrice` (which only handles pips→price direction); the proper helper for them is `_PriceToPips(price_diff)` per `CSlotBase.mqh:170-175`. Optional follow-up.

**Level of Effort:** Low (~6 LOC delta net across both call sites)

---

### Finding 08.2: 🟡 MEDIUM — `pip_size <= 0.0` guard asymmetry: `ManageExits` enforces NFR-5.1 loud failure but `Evaluate` Path A/B silent on degenerate symbol metric

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 318 (Path A pyramid — no guard), 417 (Path B primary — no guard), 476-484 (ManageExits — guard present per Round 07.5)
- Reference (Round 07.5 precedent): `slots/Slot_P.mqh::ManageExits:476-484` — loud `Logger.Error` + `Alert` + return
- Reference (NFR): `.claude/rules/security.md § Halt + Failure Surfacing` (NFR-5.1 + CodeWiki §6.2 P2.3)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:318  (Path A pyramid — silent path)
double pip_size = _PipSize();
double sl_pips  = InpPSlPipsFloor;
// ... no `if(pip_size <= 0.0)` guard — proceeds to:
double sl_price = parent_isBuy
                  ? _NormalizeBrokerPrice(price - sl_pips * pip_size)  // pip_size==0 → sl_price == price
                  : _NormalizeBrokerPrice(price + sl_pips * pip_size);

// Slot_P.mqh:417  (Path B primary — silent path)
double pip_size = _PipSize();
double sl_pips  = (sub == PSUB_PX) ? diff_sl_abs : InpPSlPipsFloor;
// ... no guard — same `sl_price == price` corruption when pip_size <= 0

// Slot_P.mqh:476-484  (ManageExits — loud guard per Round 07.5)
double pip_size = _PipSize();
if(pip_size <= 0.0)
  {
   m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                  StringFormat("_PipSize() returned %.10f — exit pass aborted; "
                               "symbol metric corrupt (NFR-5.1 surfacing)", pip_size));
   Alert("[PhoenicisNex] Slot_P degenerate _PipSize() — exit pass aborted");
   return;
  }
```

**Problem:**
fix-round-07 Finding 07.5 explicitly added the loud-failure guard on `ManageExits` because "exit pass aborted while open positions remain unmanaged is a halt-class condition per NFR-5.1." The same reasoning applies — symmetrically — to `Evaluate`: an entry with `sl_price == price` (which is what `price - sl_pips * 0.0 == price` evaluates to when `pip_size == 0`) is a broker-rejection-or-immediate-stopout guarantee (TRADE_RETCODE_INVALID_STOPS = 10016). The Phase-1 stub currently masks the bug because no `OrderSend` runs, but the moment IMPL-053+ Orchestrator wires `OrderSend` to RiskManager, the entry path will silently submit an order with SL = entry, which is exactly the surfacing-required condition NFR-5.1 protects against.

Round 07.5 acknowledged this defensively: *"`_PipSize() <= 0.0` is essentially impossible on EURUSD"* — yet still added the guard to `ManageExits`. The asymmetric treatment between `Evaluate` and `ManageExits` is the tell — either both need the guard (consistent with NFR-5.1) or neither does (which contradicts the Round 07.5 fix). Slot_BI sidesteps the question entirely by routing through `_PipsToPrice` (Finding 08.1 fix); if Slot_P adopts the same pattern, the guard collapses naturally because `_PipsToPrice(sl_pips)` returns 0 → `sl_distance == 0` → `sl_price == price` is still a problem, but is now centralized to one site.

**Why This Matters:**
Slot P is on the High-Risk-task list (impl-plan § Open Risks R-2/R-3). The Phase-1 stub status hides the defect today; it will fire the moment OrderSend lands at IMPL-053+. The whole point of the Round 07.5 ManageExits guard was to make the pre-OrderSend log path noisy enough that the IMPL-053+ engineer cannot miss the symbol-metric corruption. Leaving Evaluate silent breaks the auditing intent: a tester running headless backtests would see `[ERROR] degenerate_pip_size` from ManageExits but a clean Info from Evaluate's `entry_signal` log line containing `sl=$price` (= entry price), making the issue look like an exit-side problem when it's really a symbol-metric corruption affecting both passes.

**Suggested Fix:**
Pair the Evaluate guards with the existing ManageExits guard. Two clean implementations:

**Option A (preferred — combine with Finding 08.1):** Adopt `_PipsToPrice(sl_pips)` then add a single guard on the helper return:
```mql5
// Slot_P.mqh:316-325  (Path A pyramid)
double sl_pips = InpPSlPipsFloor;
double sl_dist = _PipsToPrice(sl_pips);
if(sl_dist <= 0.0)
  {
   m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                  "Path A pyramid aborted — _PipsToPrice returned ≤ 0 (NFR-5.1 surfacing)");
   return;        // Don't fall through to Path B; symbol metric corrupt this tick.
  }
// ... use sl_dist directly in _NormalizeBrokerPrice(price ± sl_dist)
```

```mql5
// Slot_P.mqh:415-422  (Path B primary)
double sl_pips = (sub == PSUB_PX) ? diff_sl_abs : InpPSlPipsFloor;
if(sl_pips < InpPSlPipsFloor) sl_pips = InpPSlPipsFloor;
double sl_dist = _PipsToPrice(sl_pips);
if(sl_dist <= 0.0)
  {
   m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                  "Path B primary aborted — _PipsToPrice returned ≤ 0 (NFR-5.1 surfacing)");
   Alert("[PhoenicisNex] Slot_P degenerate _PipSize() — primary entry aborted");
   return;
  }
```

**Option B (minimal — keep raw `_PipSize()`):** Just add a guard parallel to Round 07.5:
```mql5
double pip_size = _PipSize();
if(pip_size <= 0.0)
  {
   m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                  "Path A/B pyramid/primary aborted — _PipSize() ≤ 0 (NFR-5.1 surfacing)");
   return;
  }
```

Option A is preferred because it auto-resolves Finding 08.1 too. Either fix should also update fix-round-07.md note — currently it claims Finding 07.5 covers degenerate-symbol case, but the asymmetry was missed.

**Level of Effort:** Low (rolled into 08.1 Option A: ~10 LOC across both Evaluate paths)

---

### Finding 08.3: 🟡 MEDIUM — PMR SelfTest Case 4 not extended for negative `diff_sl` round-trip OR `pending_started_bar` invariance under `OverwritePPayload` — empirical proof of Round 07.1 + 07.3 fixes deferred without registry entry

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`, Lines: 466-474 (`OverwritePPayload` — new method, no SelfTest)
- File (cross-ref schema): `docs/api-specs/state-persistence-schema.yaml`, Lines: 232-238 (sign-convention amendment — no test exercises it)
- File (cross-ref fix-round): `docs/code-review/fix-round-07.md` § Summary table line 126: *"Tests Added/Updated: 0 ... SelfTest extension for `pending_started_bar` invariance under `OverwritePPayload` is reasonable follow-up but out of scope for this round per reviewer-noted Low effort."*
- Service: `[ea]` services layer

**Code:**
```mql5
// PendingMachineRegistry.mqh:466-474  (new method, untested)
void              OverwritePPayload(EPSubMode mode, double diff_sl, double band_ratio)
  {
   string payload = _BuildPPayload(mode, diff_sl, band_ratio);
   m_machines[PM_P].pending_payload = payload;     // pending_started_bar unchanged
   if(m_logger != NULL)
      m_logger.Info("pending", "payload_overwrite", 0,
                    StringFormat("machine=P sub_mode=%s",
                                 _PSubModeToStr(mode)));
  }
```

**Problem:**
Two structural test gaps tied directly to the correctness of Round 07 fixes:

1. **Negative `diff_sl` round-trip not exercised.** The schema amendment at `state-persistence-schema.yaml § PendingMachineState_PVariant.diff_sl` (lines 232-238) introduces a sign convention (BUY ≥ 0, SELL < 0). The empirical proof that `_BuildPPayload` → `_ParsePDouble` round-trips a negative double correctly is an unwritten test. fix-round-07 line 126 claims *"`OverwritePPayload` re-uses tested `_BuildPPayload`; round-trip already covered by SelfTest Case 4"* — but Case 4 (per Round 07 review, not re-read here) covers PSUB_PX/PH/E sub_mode round-trip, not negative `diff_sl` values. `_BuildPPayload` writes `DoubleToString(diff_sl, 2)` which produces `"-250.43"` for negative inputs; `_ParsePDouble` (PMR.mqh:257-282) accepts `-` in its allow-set (line 274) and `StringToDouble` parses it correctly — but this is **assumed** not **verified**. Round 07 Finding 07.1 was specifically about silent direction-loss on round-trip; closing it without a round-trip test that exercises the new sign convention is exactly the empirical-closure-discipline concern Dimension #11 raises.

2. **`pending_started_bar` invariance under `OverwritePPayload` not exercised.** Round 07.3's whole purpose was *"`OverwritePPayload` does not touch `pending_started_bar` (vs `EnterPending` which resets it)"*. The structural assertion is one line in code (line 469 just doesn't write to that field). The empirical assertion is: enter PENDING at bar X → `OverwritePPayload(...)` at bar X+5 → assert `pending_started_bar == X` (not X+5). fix-round-07 explicitly defers this to "reasonable follow-up but out of scope" — but the BR-6.4 70-bar legacy timeout is precisely the regression that would silently extend on a future code change to `OverwritePPayload` (e.g., a contributor adds `m_machines[PM_P].pending_started_bar = current_bar;` thinking it's needed for telemetry). A SelfTest case is the cheap insurance.

The defer-to-follow-up framing is also missing the `Deferred-AC Registry` discipline: per CLAUDE.md §7 Glossary, follow-up E-AC closure tied to "vendor wait / hardware not arrived" goes to `docs/state/deferred-ac-registry.md` with bounded expiry + risk-if-missed text. Round 07's deferral has neither — it's an in-line text note in fix-round-07.md without a registry entry.

**Why This Matters:**
Round 07 spent effort hardening the schema + PMR API. The Round 07 fix recommendation was correct (Option A signed `diff_sl`); the implementation looks right; but the empirical proof is missing. Code review's role at Dimension #11 is to ensure non-trivial behavior changes get their tests, not just to verify the structural change compiles. PMR is a 919 LOC service with 8 pending machines — any silent regression on PM_P sub-mode round-trip would be invisible until IMPL-053+ Orchestrator wiring exercises end-to-end state.json round-trip. By that time, root-causing regression would require bisecting through 50+ commits.

The asymmetry is sharp: Round 07 fixes touched 3 files for ~50 LOC of production code with 0 LOC of corresponding test code. Round 06 fix-round-06 by contrast added SelfTest cases when introducing pip helpers (per impl-plan TL;DR). Same engineer, same review cycle, divergent test discipline.

**Suggested Fix:**
Add 2 SelfTest cases to PMR (assuming `Spike_PendingMachineRegistry.mq5` self-test pattern from the existing 5 cases):

```mql5
//--- SelfTest Case 6 — negative diff_sl round-trip (Round 08.3 closure of Round 07.1 fix)
void TestNegativeDiffSlRoundTrip()
  {
   CPendingMachineRegistry pmr; CLogger logger; pmr.Init(.., NULL, NULL, &logger);
   pmr.EnterPPending(PSUB_N, -250.43, 75.5, 100);
   double round_trip = pmr.GetPDiffSL();
   _Assert(MathAbs(round_trip - (-250.43)) < 0.01,
           "PSUB_N negative diff_sl round-trip lost sign or precision");
   _Assert(round_trip < 0.0, "Sign convention: SELL marker (diff_sl < 0) lost");
  }

//--- SelfTest Case 7 — pending_started_bar invariance under OverwritePPayload
void TestOverwritePPayloadPreservesStartedBar()
  {
   CPendingMachineRegistry pmr; CLogger logger; pmr.Init(.., NULL, NULL, &logger);
   pmr.EnterPPending(PSUB_N, 200.0, 50.0, 100);                        // bar 100
   pmr.OverwritePPayload(PSUB_PX, 200.0, 50.0);                        // simulate lock
   // Use a state-introspection accessor — add one if needed for test only.
   _Assert(pmr._GetStartedBar(PM_P) == 100,
           "BR-6.4 70-bar legacy timeout window reset by OverwritePPayload");
  }
```

If exposing `_GetStartedBar(EPendingMachineId)` is undesirable for production API, add a `friend`-equivalent test-only accessor or move the test inside PMR via a `#ifdef SELFTEST` block.

Alternatively, if SelfTest extension is genuinely deferred to IMPL-053+ runtime exercise, register it in `docs/state/deferred-ac-registry.md` with: owner=Impl Engineer, expiry≤14d (so 2026-05-18), risk-if-missed="silent regression on BR-6.4 70-bar legacy timeout window if a future contributor adds `pending_started_bar = current_bar` to `OverwritePPayload`". Don't leave the deferral as a free-text note in fix-round-07.md.

**Level of Effort:** Low (~30 LOC of SelfTest code + 1 internal accessor) OR Low (1 deferred-AC registry row)

---

### Finding 08.4: 🔵 LOW — Sign convention `(diff_sl >= 0.0)` cannot disambiguate `+0.0` from `-0.0` → SELL with `diff_sl_pip == 0` reads back as BUY

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 373 (signed_diff_sl construction), 389 (PENDING re-read direction parse)
- File (cross-ref schema): `docs/api-specs/state-persistence-schema.yaml`, Lines: 232-238 (sign-convention amendment)
- File (cross-ref helper): `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh:204-211` (`_ComputeDiffSlPip` returns 0 when `pip_size <= 0` OR `width == 0`)
- Service: `[ea]` slots layer

**Code:**
```mql5
// Slot_P.mqh:373  (sign construction at IDLE→PENDING)
double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
m_pending.EnterPPending(PSUB_N, signed_diff_sl, band_ratio, ctx.bar_index_h4);

// Slot_P.mqh:387-389  (PENDING re-read)
double signed_ds   = m_pending.GetPDiffSL();
double diff_sl_abs = MathAbs(signed_ds);
bool   isBuy       = (signed_ds >= 0.0);

// Slot_P.mqh:204-211  (degenerate path)
double CSlotP::_ComputeDiffSlPip(const MarketContext &ctx) const
  {
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return 0.0;
   double width = ctx.bb_h4.bb_top - ctx.bb_h4.bb_bot;
   if(width < 0.0) width = 0.0;
   return width / pip_size;
  }
```

**Problem:**
The sign-convention amendment in `state-persistence-schema.yaml § PendingMachineState_PVariant.diff_sl` says *"BUY ≥ 0, SELL < 0"* — but IEEE 754 considers `-0.0 == +0.0` when compared with `>=`, so `-0.0 >= 0.0` is `true`. When `_ComputeDiffSlPip` returns 0 (degenerate path: `pip_size <= 0` OR `bb_top == bb_bot`), Slot_P writes `signed_diff_sl = -0.0` for SELL or `+0.0` for BUY; on PENDING re-read, both round-trip through `DoubleToString(0.0, 2)` → `"0.00"` → `StringToDouble` → `+0.0` (positive zero), and `(0.0 >= 0.0) == true` → reads as BUY regardless of original signal. The SELL signal is silently flipped to BUY across the IDLE→PENDING boundary.

In practice this is dormant for two reasons: (1) `_IsPSellBaseSignal` requires `bb_ratio >= 80.0`, which itself requires `bb_top - bb_bot > 0` (else `bb_ratio` is undefined), so `_ComputeDiffSlPip == 0` co-occurs with no SELL signal firing in the same tick; (2) `pip_size <= 0` is essentially impossible on a connected EURUSD symbol (per Round 07.5 reasoning). But the sign-convention doc explicitly says *"absolute value carries the pip distance, sign carries direction"* — this contract is broken at the boundary value 0 even if the boundary is unreachable in practice.

**Why This Matters:**
LOW because the path is dormant in current Phase-1 stub mode. But: (a) a future contributor changing `_ComputeDiffSlPip` to compute pip width via a different indicator (e.g., ATR instead of BB width) might allow 0 as a valid value; (b) `bb_ratio` being computed via a different formula in Phase 2 might allow degenerate band width with valid bb_ratio; (c) signed-zero is a class of bug that's nearly impossible to repro on demand and very expensive to root-cause when production behavior diverges. Schema doc + sign-convention semantics should be tight at the boundary, not loose.

**Suggested Fix:**
Two clean mitigations (pick one or both):

**Option A (cheapest — guard at source):** Reject `diff_sl_pip == 0` at IDLE→PENDING entry:
```mql5
// Slot_P.mqh:366-379
double diff_sl_pip = _ComputeDiffSlPip(ctx);
if(diff_sl_pip <= 0.0)
  {
   // Degenerate band width or symbol metric — skip pending entry this tick.
   // Direction would be ambiguous via signed-diff_sl encoding.
   m_logger.Warn("SlotP", "skip_idle_zero_diff_sl", MAGIC_P,
                 StringFormat("diff_sl_pip=%.4f bb_top=%.5f bb_bot=%.5f — pending skipped",
                              diff_sl_pip, ctx.bb_h4.bb_top, ctx.bb_h4.bb_bot));
   return;
  }
double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
```

**Option B (defensive — split sign and magnitude in schema):** Reserve a small epsilon for direction encoding (e.g., BUY = +max(diff_sl_pip, 0.01); SELL = -max(diff_sl_pip, 0.01)). Document the epsilon in the schema comment.

Option A is preferred — it surfaces the degenerate condition with a Warn log instead of silently flipping direction. Option B muddles the schema semantics.

**Level of Effort:** Low (~6 LOC delta in Slot_P.mqh::Evaluate Phase A)

---

### Finding 08.5: 🔵 LOW — `_ParsePDouble` accepts `-` / `+` / `e` / `E` at any position in numeric token; loose parser silently accepts malformed payloads

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`, Lines: 257-282 (`_ParsePDouble`)
- Service: `[ea]` services layer

**Code:**
```mql5
// PendingMachineRegistry.mqh:257-282
static double     _ParsePDouble(string payload, string field)
  {
   if(StringLen(payload) == 0) return 0.0;
   string needle = "\"" + field + "\":";
   int p = StringFind(payload, needle);
   if(p < 0) return 0.0;
   p += StringLen(needle);
   // Skip whitespace
   while(p < StringLen(payload) &&
         (StringGetCharacter(payload, p) == ' ' ||
          StringGetCharacter(payload, p) == '\t'))
      p++;
   int q = p;
   ushort ch;
   while(q < StringLen(payload))
     {
      ch = StringGetCharacter(payload, q);
      if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == '+' ||
         ch == 'e' || ch == 'E')
         q++;
      else
         break;
     }
   if(q == p) return 0.0;
   return (double)StringToDouble(StringSubstr(payload, p, q - p));
  }
```

**Problem:**
The parser's numeric-token char class accepts `-`, `+`, `e`, `E`, `.`, and digits at **any** position within the token. Malformed payloads like `"diff_sl":--250` or `"diff_sl":1-2-3` or `"diff_sl":1.2.3` would extend the token through the entire malformed run, then hand the whole substring to `StringToDouble`, which silently truncates at the first invalid character (so `--250` → `0.0`, `1-2-3` → `1.0`). The schema-canonical writer (`_BuildPPayload` via `DoubleToString(value, 2)`) cannot produce these forms, so today the loose parser is a non-issue. But if a future state.json file is hand-edited (debugging scenario) or if Phase-2 cloud-journal sync introduces a malformed payload from a different writer, the loose parser silently returns wrong values rather than rejecting + logging.

The MQL5-canonical pattern (used by `_NormalizeBrokerPrice` etc.) is to validate strict token shape before passing to a converter. A correct parser tracks state: optional leading `-` or `+`, then digits, then optional `.` + digits, then optional `e/E` + optional sign + digits.

**Why This Matters:**
LOW because no current call path produces malformed payloads (the only writers are `_BuildPPayload` + `EnterPending` + `OverwritePPayload`, all of which use `DoubleToString`). But: (a) state.json round-trip in IMPL-047 will introduce a path where externally-edited or partially-corrupted JSON is read back; (b) the parser is shared between PM_P sub-mode field, PM_P diff_sl, PM_P band_ratio — three call sites silently masking corruption; (c) it's exactly the parsing surface that a strict-mode `#strict` audit would flag at TD-04 verification time.

**Suggested Fix:**
Replace the loose char class with a strict state machine:

```mql5
static double _ParsePDouble(string payload, string field)
  {
   if(StringLen(payload) == 0) return 0.0;
   string needle = "\"" + field + "\":";
   int p = StringFind(payload, needle);
   if(p < 0) return 0.0;
   p += StringLen(needle);
   while(p < StringLen(payload) &&
         (StringGetCharacter(payload, p) == ' ' ||
          StringGetCharacter(payload, p) == '\t')) p++;

   int q = p;
   int len = StringLen(payload);
   //--- Optional leading sign
   if(q < len && (StringGetCharacter(payload, q) == '-' ||
                  StringGetCharacter(payload, q) == '+')) q++;
   //--- Integer digits (≥1)
   int digit_start = q;
   while(q < len && StringGetCharacter(payload, q) >= '0' &&
                    StringGetCharacter(payload, q) <= '9') q++;
   if(q == digit_start) return 0.0;     // no digits — malformed
   //--- Optional fractional
   if(q < len && StringGetCharacter(payload, q) == '.')
     {
      q++;
      while(q < len && StringGetCharacter(payload, q) >= '0' &&
                       StringGetCharacter(payload, q) <= '9') q++;
     }
   //--- Optional exponent
   if(q < len && (StringGetCharacter(payload, q) == 'e' ||
                  StringGetCharacter(payload, q) == 'E'))
     {
      q++;
      if(q < len && (StringGetCharacter(payload, q) == '-' ||
                     StringGetCharacter(payload, q) == '+')) q++;
      int exp_start = q;
      while(q < len && StringGetCharacter(payload, q) >= '0' &&
                       StringGetCharacter(payload, q) <= '9') q++;
      if(q == exp_start) return 0.0;    // exponent introduced but no digits
     }
   return (double)StringToDouble(StringSubstr(payload, p, q - p));
  }
```

This is ~25 LOC vs the original ~25 LOC — net 0 LOC delta but rejects malformed forms. Optionally pair with an existing or new SelfTest case that feeds malformed payloads.

**Level of Effort:** Low (~25 LOC swap; existing PMR SelfTest Case 4 still passes verbatim — strict parser accepts everything `_BuildPPayload` produces)

---

## Cross-Service Issues

| # | Issue | Severity | Location |
|---|-------|----------|----------|
| C1 | `slots/Slot_BI.mqh` uses `_PipsToPrice` helper but `slots/Slot_P.mqh` Evaluate paths use raw `_PipSize() * sl_pips` arithmetic | MEDIUM | rolled into Finding 08.1 |
| C2 | `slots/Slot_P.mqh::ManageExits` enforces NFR-5.1 loud-failure on degenerate `_PipSize()` but `Evaluate` Path A/B silent | MEDIUM | rolled into Finding 08.2 |

**No new cross-service contradictions** beyond those rolled into the per-finding sections. The Round 07 fix-round-07 anti-regression sweep results (`grep -nE 'EnterPending\(PM_P,' slots/` = 0 hits, `grep -n '\\"dir\\":' slots/Slot_P.mqh` = 0 hits, `grep -n 'MqlTradeRequest req' slots/Slot_P.mqh` = 0 hits) re-verified at this round — all pass ✅.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 08.1 | 🟡 MEDIUM | Cross-Service Consistency | Slot_P Evaluate uses raw `_PipSize() * sl_pips`; should route through `_PipsToPrice` helper per Round 06 06.1 collapse | `slots/Slot_P.mqh:318-323, 417-433` | Low |
| 08.2 | 🟡 MEDIUM | Error Handling / NFR-5.1 | `pip_size <= 0` guard asymmetry between Evaluate (silent) and ManageExits (loud per Round 07.5) | `slots/Slot_P.mqh:318, 417` vs `:476-484` | Low |
| 08.3 | 🟡 MEDIUM | Test Coverage Gaps | PMR SelfTest not extended for negative `diff_sl` round-trip OR `pending_started_bar` invariance under `OverwritePPayload`; deferral lacks registry entry | `services/PendingMachineRegistry.mqh:466-474` + `docs/code-review/fix-round-07.md:126` | Low |
| 08.4 | 🔵 LOW | Business Logic / Schema | Sign convention `(diff_sl >= 0.0)` cannot disambiguate `+0.0` vs `-0.0` → SELL with `diff_sl_pip == 0` reads as BUY | `slots/Slot_P.mqh:373, 389` + `state-persistence-schema.yaml:232-238` | Low |
| 08.5 | 🔵 LOW | Test Code Quality / Defensive Patterns | `_ParsePDouble` loose char class accepts malformed numeric tokens silently | `services/PendingMachineRegistry.mqh:257-282` | Low |

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
| R07 | 5 | 0 | 2 | 2 | 1 |
| R08 | **5** | **0** | **0** | **3** | **2** |

**Trajectory observation:** Round 08 mirrors the Round 07 shape but with HIGH count dropping to 0 — fix-round-07's three-fix architectural collapse (07.1 schema drift + 07.2 helper bypass + 07.3 timeout-reset) eliminated the entire HIGH-class drift surface. The Round 08 MEDIUM cluster is **a single second-order drift class**: Slot_P entry-path pip-arithmetic + degenerate-symbol guards + SelfTest empirical proof — symptoms of "the Round 07 fix landed correctly at the architectural seam (PMR↔schema) but did not propagate the equivalent discipline back into Slot_P's pre-existing entry-path scaffold." 08.1 + 08.2 are mechanically resolvable in one combined refactor (Option A in 08.2: adopt `_PipsToPrice` and guard the helper return), and 08.3 is either a 30-LOC SelfTest extension or a 1-row registry entry.

**Reviewer recommendation:** Ready for `/impl-review-fix` — all 5 findings have concrete, low-effort fixes with clear scope. The R08 surface is concentrated entirely on Slot_P entry-path housekeeping; PMR/schema architectural seam is stable. Recommend bundling 08.1+08.2+08.4 into a single fix-round commit (single refactor pass through Slot_P Evaluate Path A + Path B, ~20 LOC delta net) and 08.3+08.5 as separate housekeeping commits (or 08.3 as a deferred-AC registry row if SelfTest extension is genuinely deferred to IMPL-053+ runtime exercise). Post-fix, IMPL-039 + IMPL-034 attestation surface ready for IMPL-053+ Orchestrator wiring with no outstanding architectural drift.
