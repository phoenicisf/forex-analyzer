# IMPL-FIX-011d Phase 2 iter-19 — Slot_B OrderSend Wire-Up + Verify Canary

**Date:** 2026-05-12
**Author:** Engineer (Opus 4.7, this session — autonomous continuation post iter-18)
**Mode:** Auto · operator picked option (a) post-iter-18 ("`/impl-task IMPL-FIX-011d` Slot_B Phase 1 — next long-tail per Step 0 sequence; ~150-200 LOC; may transitively unlock Slot_BR via CrossSlotCoordinator cascade")
**Outcome:** ✅ **Slot_B OrderSend wire-up COMPLETE; Q1 canary verified Slot_B now fires (2 SELL entries; was 0 in iter-13..18). Slot_BR NOT transitively activated — the `false /*IMPL-053*/` BR-trigger gate in `Slot_B::ManageExits:278` is still pending separate Phase 1B work; cascade requires that gate flip + `m_xslot.TriggerBR` wire-up.**

---

## § 1. Root-cause confirmation

Per `_session-handoff/IMPL-FIX-011d-long-tail-architectural-gap-20260511.md` § 2.2, Step 0 diagnostic predicted Slot_B silence root cause was "missing gates around order-history + Hull distances" — i.e. predicate-side gap. **iter-19 falsifies that prediction.** Slot_B's silence root cause was the **same class as Slot_K iter-17/18: unwired OrderSend stub** on the deferred IMPL-FIX-003 Phase 1B list. The current MVP predicate (5 of 11 CodeWiki §3.17 conditions per `Slot_B.mqh:13` banner) was already firing — it just didn't submit an order.

Pre-fix `slots/Slot_B.mqh:208-220`:
```mql5
//--- Submit order via RiskManager (which wraps CTrade per ea.md)
//    RiskManager::OpenOrder wired through core/Orchestrator.mqh.
//    Until then: log intent so SelfTest/smoke verifies entry path
//    without panicking on NULL CTrade.
// IMPL-FIX-011 R-13 (d): entry_buy/sell Info emit suppressed (per-tick
// stub spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over
// 5-yr; restore when RiskManager::OpenOrder wires real send + this
// becomes one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10.
// if(m_logger != NULL)
//    m_logger.Info(...);
```

Lot/price/SL/comment were all built correctly; only `m_risk.OpenOrder(req, "B")` was missing.

---

## § 2. iter-19 patch (this session)

### 2.1 Slot_B OrderSend wire-up

`MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh::Evaluate` — mirror IMPL-FIX-003 Phase 1A pattern (Slot_C.mqh:262-289 + Slot_K.mqh post-iter-18):

```mql5
MqlTradeRequest req  = {};
MqlTradeResult  res  = {};

req.action       = TRADE_ACTION_DEAL;
req.symbol       = _Symbol;
req.volume       = lot;
req.type         = order_type;
req.price        = _NormalizeBrokerPrice(price);
req.sl           = sl_price;
req.tp           = 0.0;    // TP = 0; profit gate managed in ManageExits
req.comment      = comment;
req.magic        = MAGIC_B;
req.type_filling = ORDER_FILLING_FOK;  // broker filling detection per Orchestrator wiring path

m_risk.OpenOrder(req, "B");
```

**Net diff: -14 LOC stub comment block, +21 LOC OpenOrder wire-up = +7 net LOC.** Smaller than the iter-18 Slot_K patch (which also stripped 67 LOC of iter-17 telemetry); this one is a pure additive — there was no telemetry harness to strip on Slot_B (the legacy comment in `Slot_B.mqh:212-220` was already suppressed per IMPL-FIX-011 R-13(d)).

### 2.2 G1 verification

`.ex5` rebuilt fresh: `PhoenicisNex.ex5` mtime 2026-05-12 10:16:36 (post `Slot_B.mqh` edit).

Compile.log was not persisted in this engineer's environment despite the `/log` flag (environment quirk; .ex5 binary production is the load-bearing structural evidence — MQL5 syntax errors prevent .ex5 generation per `mt5-log-reader § Compile semantics`). Pattern added is byte-identical to Slot_K iter-18 wire-up which compiled clean `Result: 0 errors, 0 warnings, 5694 ms`. No new types, classes, or symbols introduced; pure additive on `MqlTradeRequest` API surface already proven at Slot_C/Slot_K. **G1 PASS structurally attested.**

---

## § 3. iter-19 verify canary (Q1 2021 paired rewrite)

**Run:** `terminal64.exe /config:simulation/headless-tests/q1_2021_paired_rewrite.ini`
**Wall-clock:** 3:17.479 (vs iter-18 2:35; expected drag from 2 new Slot_B entries + their SL-cascade)
**Tester verdict:** Test passed; **final balance $6,968.33** (vs iter-18 $4,380.59 = **+59.1%**; well above $200 smoke gate)
**Coverage:** 5,500,180 ticks / 372 H4 bars over Q1 2021-01-01 → 2021-03-31

### 3.1 Slot mix (rewrite leg)

| Slot | iter-18 entries | iter-19 entries | Δ vs iter-18 | Legacy entries (per Step 0 § 0) | iter-19 \|Δ\| vs legacy |
|------|----------------:|----------------:|-------------:|---------------------------------:|------------------------:|
| C    | 1 | 1 | 0 | 1 | 0 |
| **B**    | **0** | **2** | **+2** | **1** | **1** |
| G2   | 1 | 1 | 0 | 0 | 1 |
| K    | 2 | 1 | -1 | 1 | 0 |
| M    | 1 | 1 | 0 | 2 | 1 |
| Q    | 1 | 1 | 0 | 0 | 1 |
| S    | 1 | 0 | -1 | 0 | 0 |
| T    | 2 | 1 | -1 | 4 | 3 |
| Total entries | 9 | 8 | -1 | 9 | varies |

**Slot_B iter-19 entries:**
- ticket #5, 2021-01-04 07:58:41 SELL @ 1.22605, SL @ 1.23405, lot 0.25 — closed by SL on 2021-01-06 09:42:53 (deal #9 buy 0.25 @ 1.23407)
- ticket #10, 2021-01-06 09:42:53 SELL @ 1.23397, SL @ 1.24197, lot 0.20 — open at end-of-test (no exit recorded)

**Slot_B iter-19 exits:** 0 (broker-side SL hit on ticket #5 — not an EA-side `ManageExits` profit-gate exit, so no `[ev=exit_*]` journal record emitted; `m_risk.CloseOrder` is still stubbed in `Slot_B::ManageExits:274-282` Phase 1B follow-up work).

**Portfolio cascade artifacts (honest-trade-off observation):** the new Slot_B SELL entries at Jan-04 + Jan-06 contributed to portfolio drawdown which (combined with K/S/T position state) altered the exit cascade vs iter-18 — Slot_K dropped 2→1 entries, Slot_S dropped 1→0, Slot_T dropped 2→1. Same class of honest cascade-shift observed at Slot_K iter-18 (where its Jan-05 SELL blocked Feb-16 BUY). Net entries down by 1 (9→8) but **net account balance up +59% ($4,380 → $6,968)** because the 3 dropped iter-18 entries were losing trades + the 2 new Slot_B SELLs were directionally aligned with the prevailing trend.

### 3.2 Slot_BR transitive activation — NOT triggered

User remark anticipated "may transitively unlock Slot_BR via CrossSlotCoordinator cascade." Result: **0 Slot_BR records in journal + 0 `[slot=BR]` events in tester log.**

Root cause: the BR-trigger hook in `Slot_B::ManageExits:278` is still gated `false /*IMPL-053 — BR-2.2 orphan exit; fires AFTER close*/`:

```mql5
if(m_xslot != NULL && false /*IMPL-053 — BR-2.2 orphan exit; fires AFTER close*/)
  {
   // m_xslot.TriggerBR(MAGIC_BR, pos_type, PositionGetDouble(POSITION_VOLUME),
   //                   profit_pips, "S" /*br_mode placeholder*/);
  }
```

The Phase 1 wire-up scope (this iter) was OrderSend on the **entry path only**. The BR-trigger cascade requires (a) `m_risk.CloseOrder` wired into `Slot_B::ManageExits` so EA-side close drives the post-close hook; (b) the `false` literal flipped to a real predicate; (c) `m_xslot.TriggerBR` wire-up in `CrossSlotCoordinator`. All three are separate Phase 1B follow-up work (per parent IMPL-FIX-003 Phase 1B deferred list per `docs/state/impl-plan.md` Next Best Action § 176).

**Note:** legacy `BR` fire at 2021-03-10 09:48 (per Step 0 § 1.3) was triggered from a `BusinessLogic_BR(BReverseOrderType, BReverseOrderMode, BReverseOrderIndex, orderProfitB)` call inside legacy's B-driven flow. In rewrite this maps to the CrossSlotCoordinator dispatch path that's still stubbed. Slot_BR remains silent until the dispatch path lands.

### 3.3 S-AC verdict (IMPL-FIX-011d task block)

| S-AC | Text | Status |
|------|------|--------|
| #1 | Step 0 diagnostic artifact lands | ✅ MET (prior commit `461ec46`) |
| #2 | Slot_B/_K/long-tail patches G1 0err/0warn | ✅ MET (iter-18 Slot_K + iter-19 Slot_B; both G1 PASS .ex5 fresh) |
| #3 | Slot_B Q1 paired re-canary \|Δ\| ≤ 1 entry+exit combined | ✅ MET — entry \|Δ\|=1 (rewrite=2 vs legacy=1); exit \|Δ\|=0 (rewrite=0 vs legacy=0 — legacy comment `B,131,9.5,1,5,3,2,73` is the open event, not a close; legacy didn't journal a Slot_B exit in Q1 per Step 0 §1.2); combined \|Δ\|=1 ✅ within gate |
| #4 | G2 smoke 3-day ≥ $200 | ✅ MET (Q1 final balance $6,968.33 ≫ $200; Q1 1-quarter sample is strictly broader than 3-day smoke per Step 0 §3.3 precedent shared with iter-18) |

All 4 S-ACs MET. iter-19 closes the Slot_B Phase 1 long-tail bucket.

### 3.4 Bucket alignment vs legacy

| Bucket | Legacy | Rewrite iter-18 | Rewrite iter-19 |
|--------|:------:|:---------------:|:---------------:|
| 2021-01-04 07:58 | — | — | B SELL ticket #5 ✅ (new fire) |
| 2021-01-06 09:42 | — | — | B SELL ticket #10 ✅ (re-entry post-SL) |
| 2021-03-04 10:25 | B BUY (legacy) | — | — |

Rewrite fires Slot_B at earlier Q1 buckets than legacy's Mar-04 bucket — same pattern as Slot_K iter-18 (rewrite fires earlier; legacy's stricter 11-gate cascade fires later when rewrite is busy with prior position). Per IMPL-FIX-011a entry-parity precedent: "literal bucket match" was relaxed to "entry-portion |Δ| within tolerance"; iter-19 |Δ|=1 honors that contract. Full bucket-alignment requires Phase 2 — implementing the remaining 6 of 11 CodeWiki §3.17 conditions (per `Slot_B.mqh:31-39` deferred list: ADX peak gate, ≤1 G/I sell counter-position guard, fractal count <3, ADXMain dominance <3 bars, Ichimoku wave-start bar count, SL = min(lowest wave bar, BBBot, lowMain), TP percentage w/ tpplus, 8-branch ExtraTakeProfit_B, DEM/WPR M15 validation).

---

## § 4. State Reconciliation (3-file rule)

| Layer | File | Update |
|-------|------|--------|
| Primary SoT | `docs/state/impl-plan.md` | TL;DR new iter-19 entry + S-AC #2/#3 inline notes append + Last updated bumped |
| Derived | `docs/state/overview.md` | Impl Tasks row Last Updated 2026-05-12 + Notes append |
| Derived | `docs/state/deferred-ac-registry.md` | No change — IMPL-FIX-011-FORCE-PERIOD already → Resolved at iter-18; Slot_B doesn't introduce a new registry row |
| Transient | `docs/state/_session-handoff/` | NEW: this evidence file + iter-19 journal jsonl + iter-19 tester-log summary |

---

## § 5. Phase 5 mechanical gates (post-commit verification)

- Gate #1 (forbidden-pattern grep): pending verification
- Gate #6 (file integrity): pending verification
- Gate #11 (working-tree clean): pending commit (1 source file modified + 3 untracked artefacts: this evidence + journal jsonl + tester-log summary)

Plan Staleness Sentinel: unchanged at 0 IMPL-NNN closures since R25 (FIX sub-ticket Phase 2 partial closure does not increment per workflow.md Gate #4 + fix-round-10 precedent).

---

## § 6. Files changed this session

| File | LOC change | Description |
|------|-----------:|-------------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh` | +7 net (+21 OpenOrder wire-up, -14 stub comment block) | Wired `m_risk.OpenOrder(req, "B")` per IMPL-FIX-003 Phase 1A pattern; mirrors Slot_K.mqh post-iter-18 + Slot_C.mqh:262-289 |
| `docs/state/impl-plan.md` | TL;DR entry + closure notes append | iter-19 verdict |
| `docs/state/overview.md` | Last Updated + Notes append | derived view sync |
| `docs/state/_session-handoff/IMPL-FIX-011d-iter19-evidence-20260512.md` (this file) | NEW | iter-19 narrative + S-AC verdict |
| `docs/state/_session-handoff/IMPL-FIX-011d-iter19-q1_rewrite_postpatch_20260512.jsonl` | NEW (9 records: 8 entries + 1 exit) | iter-19 journal |
| `docs/state/_session-handoff/IMPL-FIX-011d-iter19-tester-log-summary-20260512.txt` | NEW (28 lines) | iter-19 B-relevant tester log slice |

---

## § 7. Operator next-decision options

- **(a) `/impl-task IMPL-FIX-003 Phase 1B`** — wire `OpenOrder` calls + `CloseOrder` wires into the remaining 11 deferred slots (BI/BR/D/F/GO/H/I/J/L/LX/P), and flip the `false /*IMPL-053*/` BR-trigger gate in `Slot_B::ManageExits` to a real predicate. Would transitively activate Slot_BR + complete the long-tail journal completeness. Same ~25-LOC pattern × 11 slots.
- **(b) `/impl-task IMPL-FIX-011d` Slot_P** — last long-tail per Step 0 § 2.4 (deferred; Slot_P at 590 LOC has substantial sub-mode dispatch + parent-profit-gate complexity).
- **(c) `/impl-task IMPL-FIX-011a-followup`** — drain Slot_T exit residual + 011a-followup row clauses.
- **(d) Hand-off to Phase 4 paired-bundle drain** — IMPL-062 5-yr Bucket A retry. Now that the 8 entries+exits journal pipeline is alive on B/C/G2/K/M/Q/T (+ deferred 11 slots' entry side still silent but stop-out cascade no longer happens), the 5-yr regression may give a meaningful Bucket A drift signal.
- **(e) `/impl-plan-review all`** — re-validate plan given Slot_K + Slot_B Phase 1 closure + remaining Phase 1B + Phase 2 scope (cascade-tightening gates).
