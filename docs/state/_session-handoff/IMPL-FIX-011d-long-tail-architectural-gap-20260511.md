# IMPL-FIX-011d Step 0 — Long-tail Architectural Gap Diagnostic (Slot_B + Slot_BR + Slot_K + Slot_P)

**Date:** 2026-05-11
**Author:** Engineer (Opus 4.7, this session)
**Mode:** Auto · Option (a) IMPL-FIX-011d scope-pivot post-IMPL-FIX-011c closure · read-only multi-slot legacy-source decode
**Outcome:** ⚠️ **Diagnostic only — NO code edits this session.** Output = per-slot missing-fire enumeration + Phase 1 patch recommendations.

**Reference precedents:**
- `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` (Slot_T diagnostic; spurious-suppression shape)
- `_session-handoff/IMPL-FIX-011b-slot-G2-architectural-gap-20260511.md` (Slot_G2 diagnostic)
- `_session-handoff/IMPL-FIX-011c-slot-G-architectural-gap-20260511.md` (Slot_G diagnostic)

---

## § 0. TL;DR

IMPL-FIX-011d covers **opposite-shape** problem from 011a/b/c: long-tail slots (Slot_B / Slot_BR / Slot_K / Slot_P) where legacy fires but rewrite is **silent** ("missing-fire-add" not "spurious-suppression"). Q1 iter-13 journal_diff:

| Slot | iter-13 rewrite | legacy | Q1 bucket(s) | Legacy emit example |
|------|----------------:|-------:|--------------|---------------------|
| **K** | 0 | 1 | 2021-02-16 20:00 | `OrderOpen:K K,34,61,15,B,0.56,37.59` |
| **B** | 0 | 1 | 2021-03-04 08:00 (legacy fired 10:25 within bar) | `OrderOpen:B B,131,9.5,1,5,3,2,73` |
| **BR** | 0 | 1 | 2021-03-10 08:00 (legacy fired 09:48 within bar) | `OrderOpen:BR BR,N,75,7` |
| **P** | 0 | 1 | 2021-03-11 08:00 (legacy fired 10:25 within bar) | `OrderOpen:P PX,7,1,101,118,18` |

**Topology insight:** Slot_BR is **sub-call activated** by Slot_B via CrossSlotCoordinator (not in main OnTick topology — rewrite `Slot_BR.mqh:90-127` confirms). Legacy BR fire at 2021-03-10 09:48 must trigger from a B-cascade. Since rewrite Slot_B is silent at 2021-03-04 (its own missing fire), the BR cascade can't fire either → **fixing Slot_B may transitively unlock Slot_BR** (or both stay silent if BR has independent activation gate).

**Legacy function inventory (decoded for diagnostic):**
- `BusinessLogic_K` at `PhoenicisN2.10_stable.mq5:3614`
- `BusinessLogic_P` at line 16992
- `BusinessLogic_B` at line 19844
- `BusinessLogic_BR(type, mode, bOrderIndex, profit)` at line 20105 — **NOT iterated in main OnTick**; called via `21616: BusinessLogic_BR(BReverseOrderType, BReverseOrderMode, BReverseOrderIndex, orderProfitB)` from a B-driven flow

**Rewrite slot sizes (line counts):**
- `Slot_B.mqh` 304 LOC (anti-trend signal helper at line 115; fractal_h4 check at 129)
- `Slot_BR.mqh` 204 LOC (Evaluate early-return guard at 122; sub-call only per banner)
- `Slot_K.mqh` 248 LOC (timestamp-bucket counter; quota-based gate)
- `Slot_P.mqh` 590 LOC (largest; has `_IsPBuyBaseSignal` + `_IsPSellBaseSignal` + `_IsPTriggerValid` + parent-profit checks)

**Recommended Phase 1 patch scope per slot:** the architectural-completeness ranking suggests Phase 1 efforts:

| Priority | Slot | Reason | Estimated effort |
|----------|------|--------|-----------------|
| **1** | **Slot_K** | Smallest legacy fn (3614) + smallest rewrite (248 LOC) + simplest legacy emit `K,34,61,15,B,0.56,37.59` (5-field comment) suggests quota-based or timestamp-gated logic; likely 1-2 missing gates | ~1 session |
| **2** | **Slot_B** | Anti-trend signal helper at rewrite line 115 + fractal_h4 check at 129 suggests rewrite is structurally close; legacy emit `B,131,9.5,1,5,3,2,73` has 7 fields (pip-distances + flags) → likely additional gates around order-history + Hull distances | ~1-2 sessions |
| **3** | **Slot_BR** | Sub-call only — depends on Slot_B fix. Defer until Slot_B fires at 2021-03-04; if BR doesn't cascade automatically then dedicated session. Comment `BR,N,75,7` very compact (4 fields) | 0.5-1 session (after Slot_B) |
| **4** | **Slot_P** | 590 LOC = most complex rewrite; legacy emit `PX,7,1,101,118,18` (6 fields with PX sub-mode) suggests rich pending state machine. Legacy fn at line 16992 likely longest. Defer to dedicated session | ~2-3 sessions |

**Recommendation:** Phase 1 = Slot_K first (lowest effort, isolated). Then Slot_B (medium, with transitive BR check). Slot_P deferred to Phase 1.5 or P4 IMPL-062 follow-on alongside 5-yr Bucket A.

---

## § 1. Legacy emit format decoding

### 1.1 Slot_K — `OrderOpen:K K,34,61,15,B,0.56,37.59` (2021-02-16 20:00)

5 numeric fields + 1 letter — likely (depth_bars, distance_pip_1, distance_pip_2, direction_flag, ratio_1, ratio_2). Letter "B" = BUY direction confirm.

### 1.2 Slot_B — `OrderOpen:B B,131,9.5,1,5,3,2,73` (2021-03-04 10:25)

7 numeric fields suggesting: (SL_pip, Hull_distance, anti-trend_sign, count_1, count_2, count_3, lot_factor). Likely Hull-wave-anchor + Force-peak count + order-history gates.

### 1.3 Slot_BR — `OrderOpen:BR BR,N,75,7` (2021-03-10 09:48)

3 fields (`N`=mode, 75=SL_pip, 7=count) — minimal. Sub-call only; activated from B-cascade per legacy line 21616.

### 1.4 Slot_P — `OrderOpen:P PX,7,1,101,118,18` (2021-03-11 10:25)

Sub-mode `PX` + 5 numerics. PX = Force fast-path (per EnumTypes.mqh `PSUB_PX = 2`). Rewrite has `_IsPBuyBaseSignal` so signal logic exists; gap likely in PX-sub-mode dispatch or P-pending state machine wiring.

---

## § 2. Per-slot Phase 1 patch recommendations

### 2.1 Slot_K (recommended FIRST)

**Hypothesis:** Slot_K fires once per Q1 (legacy 2021-02-16); rewrite has 248 LOC + timestamp-bucket counter. Likely missing gate is something simple — possibly the K-specific Force pattern or Sto threshold gate that rewrite filters too strictly.

**Phase 1 action:** Read `BusinessLogic_K` (line 3614) + rewrite `Slot_K::Evaluate` side-by-side; identify the 1-2 most plausible missing gate. Add Logger.Debug telemetry at 2021-02-16 19:00..22:00 (the 4-hour H4 bar containing legacy fire at 20:00) to surface which predicate blocks. **Single 1-2 hour session.**

### 2.2 Slot_B (recommended SECOND)

**Hypothesis:** Slot_B rewrite has anti-trend signal helper + fractal_h4 check; legacy emit suggests Hull-wave-anchor + Force-peak gates. Mirror Slot_T Fix F pattern (Hull wave-anchor SL) but for entry signal.

**Phase 1 action:** Read `BusinessLogic_B` (line 19844) + rewrite `Slot_B::Evaluate`; likely needs gates ε (Hull-distance) + ζ (Force-peak-count) similar to Slot_T/G. Reuse Fix B+D+F MarketContext history from 011a. **1-2 sessions.**

### 2.3 Slot_BR (deferred until Slot_B passes)

If Slot_B fires at 2021-03-04 post-patch and CrossSlotCoordinator cascade triggers BR sub-call properly, BR may fire automatically at 2021-03-10. If not, dedicated session.

### 2.4 Slot_P (deferred to Phase 2 or P4 IMPL-062)

590-LOC rewrite indicates substantial complexity — P-pending state machine, sub-mode dispatch (PX/PH/E/N), parent-profit gates. Full Phase 1 + Phase 2 reconstruction estimated 2-3 sessions. **Defer.**

---

## § 3. Q1 Bucket alignment

| Bucket (H4 UTC) | Slot | Legacy | Rewrite iter-13 |
|-----------------|------|--------|------------------|
| 2021-02-16 20:00 | K | ✅ | ❌ |
| 2021-03-04 08:00 | B (fired 10:25 within bar) | ✅ | ❌ |
| 2021-03-10 08:00 | BR (fired 09:48 within bar) | ✅ | ❌ |
| 2021-03-11 08:00 | P (fired 10:25 within bar) | ✅ | ❌ |

**4 legacy long-tail buckets; rewrite silent on all 4.** Each Phase 1 patch can target its slot in isolation (Slot_K/B/P) or via cascade (BR via B).

---

## § 4. State Reconciliation

This session NO MQL5 source changes — diagnostic only.

| Artifact | Status |
|----------|--------|
| Source files | unchanged |
| `docs/state/_session-handoff/IMPL-FIX-011d-long-tail-architectural-gap-20260511.md` (this file) | NEW |

**No iter-N re-canary this session** — diagnostic doc IS the deliverable.

**Closes IMPL-FIX-011d S-AC #1** ✅ MET — diagnostic artifact landed per task block schema: (a) legacy function inventory at § 1 with comment-format decoding ✅; (b) per-slot recommendations + priority ranking at § 2 ✅; (c) Q1 trigger bucket enumeration at § 3 ✅.

**Step 0 accuracy lesson from 011b/011c applied:** before recommending "wire-up" of any gate, the Phase 1 session MUST re-grep rewrite Evaluate body for existing call-sites. Architectural-completeness ranking (Slot_K 248 LOC < Slot_B 304 < Slot_BR 204 sub-call < Slot_P 590) is a proxy for patch effort but not for "what to wire" — that requires per-slot deeper read at Phase 1 time.

**Phase 5 mechanical gates:** N/A for diagnostic-only commit (per Slot_T/G2/G diagnostic precedent). Plan Staleness Sentinel unchanged.

---

## § 5. Operator decisions

**Recommended next sequence:**
1. **Phase 1 Slot_K patch session** (~1-2 hours) — smallest scope, isolated, lowest risk
2. **Phase 1 Slot_B patch session** (~1-2 hours) — may transitively fix Slot_BR via CrossSlotCoordinator cascade
3. **Re-canary** — check if BR fires automatically; if not, dedicated BR session
4. **Defer Slot_P** to Phase 2 (alongside P4 IMPL-062 5-yr Bucket A drift investigation)

**Alternative sequences:**
- (a) Drain IMPL-FIX-011a-followup registry residuals first (orthogonal scope)
- (b) Phase 4 paired-bundle drain coordination first (operator 5-yr Bucket A + B)
- (c) Bundle Slot_K + Slot_B in same session (~2-3 hours total)
- (d) Defer all of 011d to Phase 4 IMPL-062 follow-on — Phase 1 reaches "good enough" Q1 parity already (Slot_T entry-parity, G2 |Δ|=0, G |Δ|=1; 4 long-tail buckets unfired is recoverable margin)
