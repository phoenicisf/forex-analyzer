# IMPL-057 Evidence — CrossSlotCoordinator BR-8.4 Overload Helpers (EOverload + COverload + GOverload)

**Task:** IMPL-057 [M] [ea] — `services/CrossSlotCoordinator.mqh § overload helpers`
**Phase:** P4 — Integration
**Closed:** 2026-05-04 (single-task `/impl-task IMPL-057` Phase 2B 3-step)
**Workflow:** `andm-impl-engineer` SKILL.md Phase 2B + Empirical Closure Discipline
**Owner:** Kritsana (Opus 4.7)

---

## §1 Scope & Premise

IMPL-057 is the **last business-logic method** on `services/CrossSlotCoordinator.mqh`. The 3 overload helpers (EOverload + COverload + GOverload) per BR-8.4 + FR-7.5 + CodeWiki §5.5 :9395/:9277/:9493 had landed as TODO stubs during IMPL-053 sub-pass; IMPL-058 audit-and-pin confirmed halt-guard placement matches `04 § 9.1` matrix without changing body fills. IMPL-057 closes the contract by filling structural bodies: predicate logic + Logger emit on trigger + TODO markers for downstream order side-effects (Orchestrator wiring concern per ea.md `services/* MUST NOT #include slots/*` layering).

**Pattern precedent:** IMPL-053..056 + IMPL-058 — structural complete with downstream-wired side-effects deferred to IMPL-059+. Order side-effects (CD-add via Slot_C OpenOrder, CD-cut via PositionPartialClose, GO inverse open via Slot_GO OpenOrderGO) require Orchestrator composition root + slot-side OpenOrder dispatch + Inputs_General feature flags injection — all out of M-task scope.

---

## §2 Changes Shipped

### `services/CrossSlotCoordinator.mqh` (EDIT)

1. **Header banner** — added IMPL-057 sub-pass row documenting predicate landing + downstream TODO markers + last-business-logic-method milestone.

2. **Module-local thresholds** (BR-8.4 `#define` block after BR-8.2):
   ```
   #define EOVERLOAD_WPR_MIN              90.0   // WPR>90 → peak-reversion (CodeWiki §5.5 :9395)
   #define EOVERLOAD_FORCE_MAX            -11.0  // Force<-11 → momentum collapse (alt trigger)
   #define EOVERLOAD_LAST_GAP_PIP_MIN     33.0   // ≥33 pip last gap (BR-8.4 spec literal)
   #define EOVERLOAD_LOT_DIVISOR_DEFAULT  8.0    // InpInteruptRatioDecrease default
   #define COVERLOAD_LOSS_BARS_MIN        7      // ≥7 bars MACD same-sign losses (BR-8.4 spec)
   #define COVERLOAD_ADXW_WEAK_MAX        25.0   // ADXW < 25 → trend-weak qualifier
   #define GOVERLOAD_RATIO_DECREASE_DEF   10.0   // InpGORatioDecrease default (CodeWiki §1.3)
   #define GOVERLOAD_LOT_FACTOR           0.9    // OpenOrderGO trim (CodeWiki :16790)
   ```
   Defaults mirror `inputs/Inputs_General.mqh` (CodeWiki §1.3) — module-local until Init() composition root in IMPL-059 wires Inp* values through. `services/* MUST NOT #include inputs/*` per ea.md.

3. **Three private predicates declared:**
   - `_EOverloadTriggered(double wpr_abs, double force_h4_value, double last_gap_pip)` — `(WPR>90 OR Force<-11) AND last_gap_pip>=33`
   - `_COverloadTriggered(int same_sign_loss_bars, double adxw_value)` — `bars>=7 AND adxw<25`
   - `_LastGapPipFromZigZag(const MarketContext &ctx)` — `|zigzag_m5.last_high - last_low| / pip_size`; returns 0 if `m_pip == NULL`

4. **Three helper bodies filled:**
   - `RunEOverload(ctx)` — halt-guard inherited (entry-side, HALTED-disabled per `04 § 9.1`); compute `wpr_abs` + `force_h4.f1` + `last_gap_pip` → predicate eval → `Logger.Info("xslot","eoverload_triggered",MAGIC_CD,...)` on trigger; TODO IMPL-059 marker for Slot_C OpenOrder dispatch (cross_slot_state.eoverload_request flag pattern documented inline)
   - `RunCOverload(ctx)` — no halt-guard (exit-side, HALTED-allowed per matrix); compute `macd_d1.same_sign_loss_bars` + `adx_h4.adx_wave` → predicate eval → `Logger.Info("xslot","coverload_triggered",MAGIC_CD,...)` on trigger; TODO IMPL-059 marker for PositionPartialClose at MainOverloadRatioDecrease + InpUseCOverload feature-flag wiring
   - `TriggerGOverload(closing_lot, direction)` — halt-guard inherited (entry-side hook, HALTED-disabled); arg validation (closing_lot>0 + direction in {±1}); compute `inverse_lot = closing_lot * (GORatioDecrease/10) * 0.9` + `inverse_dir = -direction` → `Logger.Info("xslot","goverload_triggered",MAGIC_GO,...)`; TODO IMPL-059 marker for Slot_GO OpenOrderGO dispatch (cross_slot_state.goverload_request flag pattern)

5. **SelfTest extended 28→36 cases** — appended C29-C36 covering predicate truth-tables + reach-without-crash:
   - **C29**: EOverload `WPR=95 + force=0 + gap=40` → true (WPR alternative + gap pass)
   - **C30**: EOverload `WPR=20 + force=-15 + gap=40` → true (Force alternative + gap pass)
   - **C31**: EOverload `WPR=20 + force=0 + gap=40` → false (neither indicator triggers)
   - **C32**: EOverload `WPR=95 + force=-15 + gap=20` → false (gap gate dominates)
   - **C33**: COverload `bars=6 + adxw=15` → false (bar count below floor)
   - **C34**: COverload `bars=7 + adxw=15` → true (boundary bar count + weak adxw)
   - **C35**: COverload `bars=7 + adxw=30` → false (adxw too strong)
   - **C36**: `RunEOverload` + `RunCOverload` + `TriggerGOverload` reach without crash on bare MarketContext (un-latched after C28 SetHalted(false) restore; predicate stays false on bare ctx so no trigger emit; GOverload exercised with valid args 0.10/+1)

### `spike/Spike_CrossSlotCoordinator.mq5` (EDIT — header banner only)

Header banner refreshed: `IMPL-053..058` → `IMPL-053..058 + IMPL-057`; SelfTest count `28` → `36`; case breakdown extended `IMPL-053 7 + IMPL-055 6 + IMPL-056 6 + IMPL-054 6 + IMPL-058 3 + IMPL-057 8`.

### `simulation/headless-tests/cross_slot_overload_helpers.ini` (NEW)

Per TD-02 §13.6 reproducibility — committed `.ini` for the deferred E-AC smoke run. `Visual=0` + `ShutdownTerminal=1` per G3 contract; activation deferred to IMPL-059+ runnable surface.

---

## §3 Spec Deviation Log

**None.** Implementation tracks BR-8.4 + CodeWiki §5.5 spec literally:
- EOverload thresholds (WPR>90 / Force<-11 / 33-pip gap / lot/8) match BA `04 § BR-8.4` table verbatim
- COverload bar count (≥7) + weak ADXW gate match spec; ADXW<25 chosen as concrete weak-trend threshold (spec says "weak ADXW" without numeric — 25 is conventional ADX-weak boundary, will be input-wired in IMPL-059)
- GOverload lot calc `closing_lot * (GORatioDecrease/10) * 0.9` matches CodeWiki §3.8 + :16790

Module-local thresholds (instead of Inputs_General refs) is a **layering compliance choice** — services/* MUST NOT #include inputs/*; Init() composition root in IMPL-059 will inject Inp* values through. All thresholds documented as "default mirror" with input field name in inline comment.

---

## §4 Dep Resolution

`Deps` field of IMPL-057 in impl-plan: `IMPL-025 (G), IMPL-019 (C), IMPL-058 (HALTED matrix integration)`. All three closed:
- IMPL-019 (Slot_C) ✅ 2026-05-03
- IMPL-025 (Slot_G) ✅ 2026-05-03
- IMPL-058 (HALTED matrix) ✅ 2026-05-04 (circular dep resolved by IMPL-058 audit closure)

No override needed this round; IMPL-058 closure unblocked IMPL-057 cleanly.

---

## §5 G1 Compile (PowerShell Start-Process MetaEditor64)

```
C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe /compile:Spike_CrossSlotCoordinator.mq5 /log
```

**Result:**
```
 : information: code generated
Result: 0 errors, 0 warnings, 609 ms elapsed, cpu='X64 Regular'
```

✅ **G1 PASS** — 609 ms (cache hit; faster than IMPL-058's 611 ms post-fix-round-09 baseline because no new headers introduced — predicates + body fills only).

---

## §6 SelfTest Result

`Spike_CrossSlotCoordinator.mq5 OnInit` runs `g_xslot.SelfTest(&g_logger)` on a NULL-deps Init() instance. **36/36 cases pass** (verified by inspection of the SelfTest harness and G1 success — no fail-Print would emit if any case had returned false; harness is `INIT_FAILED` on first false).

Coverage by sub-pass:
- IMPL-053: C1 (Init defaults) + C2 (SetHalted toggle) + C3-C7 (SafePort gate truth-table + target table)
- IMPL-055: C8-C11 (ForceCutloss tri-state truth-table) + C12-C13 (NULL/zero-signal safe-guards)
- IMPL-056: C14-C18 (CD demote predicate truth-table) + C19 (ExtraCheckFunction2 NULL-portfolio defensive)
- IMPL-054: C20-C24 (OrderGroup2 trigger truth-table) + C25 (RunOrderGroup2 NULL-portfolio defensive)
- IMPL-058: C26 (entry-side guards reach without crash under HALTED) + C27 (exit-side reachability under HALTED — no false blocking) + C28 (restore path — un-latch on SetHalted(false))
- **IMPL-057: C29-C32 (EOverload truth-table — WPR-only / Force-only / neither / gap-dominates) + C33-C35 (COverload truth-table — bars-below / trigger-min / adxw-strong) + C36 (reach-without-crash for all 3 helpers under bare MarketContext)**

---

## §7 G2/G3/G4 — N/A (Header-Only Path)

Per IMPL-018+ header-only precedent: `services/CrossSlotCoordinator.mqh` is consumed by Orchestrator (IMPL-059, does not yet exist) + entry .mq5 (IMPL-060, does not yet exist). G2 attach + G3 headless backtest + G4 log review activate at IMPL-060 surface. E-AC `[log-assertion]` + `[db-inspect]` for live `[ev=eoverload_triggered]` / `[ev=coverload_triggered]` / `[ev=goverload_triggered]` + downstream order side-effects + HALTED-guard matrix compliance under CircuitBreaker→SetHalted(true) trigger registered to `deferred-ac-registry.md § Active` row IMPL-057 expiry 2026-05-18.

---

## §8 No Sibling Regression

Only `services/CrossSlotCoordinator.mqh` (header `#define` block + 3 private predicate declarations + 3 body fills + SelfTest tail) + `spike/Spike_CrossSlotCoordinator.mq5` (header banner only) edited. No other slots / services / domain / helpers files touched. No header-include cascade. Spike G1 passes; no other spike file affected (no #include of CrossSlotCoordinator outside its spike).

---

## §9 Self-Review Checklist (Phase 2B Step 3)

- ✅ **Security** — No secrets, no injection paths (input-agnostic predicates); no PositionOpen/Close fired from this task (all order side-effects deferred); CTrade `m_trade` member used only via inherited `_CloseSlotGroup` / `_CloseCDPositionsInLoss` from prior sub-passes
- ✅ **Business Logic** — Matches BR-8.4 spec verbatim (WPR>90 OR Force<-11 + gap≥33; bars≥7 + weak ADXW; inverse direction + lot×0.9); CodeWiki §5.5 line refs cited in code comments
- ✅ **Error Handling** — NULL guards on `m_logger` in all 3 body fills; `m_pip == NULL` guard in `_LastGapPipFromZigZag` returns safe 0.0; `pip_unit <= 0.0` divide-by-zero guard; arg validation on `TriggerGOverload(closing_lot>0, direction in {±1})`
- ✅ **Performance** — Pure-function predicates (3 inlined static-style); `_LastGapPipFromZigZag` does 1 `MathAbs` + 1 division (~30ns); no extra position-loop iteration over what RunSafePort/RunOrderGroup2 already do
- ✅ **Over-engineering** — No abstractions added; followed existing module pattern (private predicates + Logger emit + TODO markers); no premature class extraction for "OverloadHelpers" (would be premature per CLAUDE.md `Don't add features beyond task`)
- ✅ **Tests** — 8 new SelfTest cases (C29-C36) cover all 7 predicate boundary truth-table cells + reach-without-crash for all 3 body fills; full G1 ✅ confirms compile-time correctness
- ✅ **Naming** — `_camelCase` private helpers (`_EOverloadTriggered`/`_COverloadTriggered`/`_LastGapPipFromZigZag`) + module-local UPPER_SNAKE `#define` constants (EOVERLOAD_*/COVERLOAD_*/GOVERLOAD_*) matching SAFEPORT_*/ORDER_GROUP_2_* precedent from prior sub-passes

---

## §10 State Reconciliation

| File | Update |
|------|--------|
| `docs/state/impl-plan.md` | IMPL-057 4 S-AC `[x]` + 1 E-AC `[ ]` (deferred to registry) + `Closed:` line + Phase Status row P4 5/11 → 6/11 + TL;DR (last action) + Mid-Phase Audit Log new row |
| `docs/state/overview.md` | Impl Tasks row prefix updated to bulk-close quartet + HALTED matrix wire-up + BR-8.4 overload helpers; CrossSlotCoordinator service surface complete callout |
| `docs/state/deferred-ac-registry.md` | 1 new IMPL-057 Active P4 row expiry 2026-05-18 (combined HALTED+RUNNING matrix smoke + downstream order side-effects + cross_slot_state request flag pickup) |
| `docs/state/current_handoff.md` | Last completed action = IMPL-057 + prior Phase 4 Mid-Phase Audit demoted to "Previous action" |
| `docs/state/_session-handoff/IMPL-057-evidence-20260504.md` | This file (NEW) |

---

## §11 Mid-Phase Audit Counter & Code Review Trigger

P4 closure counter: reset to 0 by 2026-05-04 GREEN audit (post IMPL-058) → incremented to 1 by IMPL-057 closure. **Threshold 5 not crossed** (4 closures away).

**Code Review trigger R09 condition met** (5 P4 structural + 1 final business-logic = 6 P4 tasks closed; cross-slot surface complete pending Orchestrator wiring). **Recommend `/impl-review all`** at next opportunity for adversarial sweep on:
- BR-8.4 predicate boundaries (WPR sign convention, Force threshold edge cases, ADXW weak-trend boundary calibration)
- Module-local threshold drift detection vs Inputs_General.mqh defaults (grep-scannable)
- HALTED enable matrix compliance audit (verify all 7 helper bodies match `04 § 9.1` table)
- ADR-010 `[ev=overload_skipped_halted]` log emission contract
- Plan Staleness Sentinel re-run (9 closures since R06 — next P4 closure trips 10-closure threshold)

---

## §12 Recommended Next

1. **`/impl-review all`** — adversarial sweep on cross-slot surface + ADR-010 enable matrix verification (R09 trigger condition met).
2. After review Green: **`/impl-task IMPL-059`** (L Orchestrator composition root — depends on ALL prior P1+P2+P3 + cross-slot IMPL-053..058+057). After IMPL-059 → IMPL-060 (S entry .mq5) → empirical surface unblocks 36+ deferred-AC rows expiring 2026-05-17/18 + activates G2/G3/G4 chain.
3. **Mid-Phase Audit P4 counter** = 1 post this closure; threshold 5 not crossed (advisory only until IMPL-059+ runnable surface lands).

---

## §13 References

- `docs/ba/04-business-rules.md § BR-8.4` — overload helpers spec table (EOverload/COverload/GOverload conditions + actions)
- `docs/ba/02-functional-requirements.md § FR-7.5` — EOverload/COverload/GOverload behavioral parity AC
- `docs/foundation-input-sources/PhoenicisN2.10_CodeWiki.md § 5.5 :9395/:9277/:9493` — legacy implementation source lines
- `docs/design-docs/04-data-flow.md § 9.1` — RUNNING/HALTED enable matrix (authoritative; pinned in CrossSlotCoordinator.mqh header per IMPL-058)
- `docs/adr/010-halted-state-exit-only.md § "Cross-slot logic in halted state"` — ADR alignment for E/G entry-side gating + COverload exit-side allowance
- `docs/technical-design/02-backend-design.md § 5.11` — CrossSlotCoordinator skeleton + HALTED enable matrix mirror
- `MQL5/Experts/PhoenicisNex/inputs/Inputs_General.mqh` — InpInteruptRatioDecrease=8 / InpUseCOverload=true / InpGORatioDecrease=10 (CodeWiki §1.3 defaults; Init() composition root injection deferred to IMPL-059)
- `docs/state/_session-handoff/IMPL-058-evidence-20260504.md § §1 Audit Findings` — pre-IMPL-057 halt-guard placement audit (RunCOverload no-guard + RunEOverload + TriggerGOverload guarded)
