# IMPL-062 Bucket A 5-yr Run #6 — Post-BT-002 no-detector default build

> **Date:** 2026-05-19  
> **Trigger:** Operator `/impl-task IMPL-062` invocation (`/next` Pre-check 0 Path B priority: expired Deferred-AC rows pending IMPL-062 5-yr regression on the post-BT-002 rewrite-no-detector default build)  
> **Operator session wall-clock:** ~10 min total (build pre-flight 5 min + Tester launch+blow-up 9m35s + operator kill on observed account-bankrupt zombie state)  
> **Verdict:** 🔴 **NFR-1.1 CATASTROPHIC FAIL — Bucket A drift = −100.0041% (final balance $0.84 vs baseline $24.27M Net Profit + $1k deposit).** Account-blowout via broker stop-out at sim 2021-08-04 16:06:00 (margin 17.72%); **0 EA-side halt events** ✅ (CircuitBreaker removed per BT-002 closure 2026-05-18 + impl-code cleanup commit `32f1209`); root cause = R-13 long-tail trading-logic translation gap, primarily **Slot_BI pyramid over-fire (101 entries vs baseline 0)** + **Slot_H over-fire (95 entries vs baseline 7 = 13.5×)**. BT-002 architectural decision empirically confirmed correct (no false-positive halt-class) but exposed the deeper trading-logic gap that the prior ping-pong detector had been masking by halting at sim 2021-01-14.

---

## §1 — Pre-flight state (post-BT-002, post-IMPL-FIX-013)

- BT-002 cascade ✅ Closed 2026-05-18 (`backtrack-log.md § BT-002 § Status`) — Option 1 legacy-parity remove BR-3.6 detector
- Impl-code cleanup ✅ landed via commits `32f1209` (DELETE `services/CircuitBreaker.mqh` + `spike/Spike_CircuitBreaker.mq5` + strip Orchestrator `OnTradeTransaction` ~100 LOC + strip `CheckPingPong` from `OnTick`) + `21161fc` (4-gate verification CLOSURE: G1 + G3 + G4 PASS on Jan 2021 1-month smoke window)
- Repository state at run launch: `services/CircuitBreaker.mqh` absent ✅; `core/Orchestrator.mqh` retains audit-history comments only (REMOVED markers) ✅; `domain/EnumTypes.mqh` has no `HALT_PINGPONG` constant ✅
- `.ex5` rebuilt fresh 2026-05-19 15:05:48 (size 353,754 bytes; G1 = `Result: 0 errors, 0 warnings, 30519 ms elapsed`)
- 5-yr `.ini`: `MQL5/Profiles/Tester/PhoenicisNex.EURUSD.H4.20210101_20251231.400.ini` (Visual=0 + ShutdownTerminal=1 + Deposit=1000 + Leverage=500 + Model=4 + 2021-01-01..2025-12-31). **Note:** the original `simulation/headless-tests/regression_5yr_g4.ini` was deleted by the path-modernization commit `47381a9`; this run uses the MT5-native local-only `.ini` per the IMPL-FIX-013 precedent (handoff `current_handoff.md` L14). A separate ticket to restore committed reproducibility .ini files into the repo tree is recommended.

## §2 — Run launch + zombie kill

| Field | Value |
|-------|-------|
| Launch wall | 2026-05-19 15:08:46 |
| EA init_ok wall | 15:08:59 |
| Operator-observed bankruptcy wall | ~15:17 (user signal "test is zombie now. it's bankrupt") |
| Operator kill wall | 2026-05-19 15:18:37 |
| MT5 Tester summary | `Test passed in 0:09:35.510` (Tester ran to internal stop-out termination — "passed" = run-to-end successfully, NOT strategy passed) |
| `final balance 0.84 USD` | per Tester log line `Tester	final balance 0.84 USD` at wall 15:18:34.154 |
| `OnTester result 0.84` | per EA `EOnTester()` return |
| `stop out occurred on 11% of testing interval` | Tester log; sim 2021-08-04 ≈ day 215 / 1825 = 11.78% |
| Tester log size | 58,531,564 bytes (58.5 MB UTF-16LE; 174,664 decoded lines) |
| Journal records | 578 (314 entry + 264 exit; **0 halt** ✅; **0 order_failed/skipped** ✅) |

## §3 — Halt class + drift

**0 EA-side halt events** — `event_type=halt` grep returns 0. CircuitBreaker is deleted; no `circuit_breaker_pingpong` halt-class can exist by construction. The bankrupt was an MT5 **broker stop-out**, not an EA-managed halt. Broker stop-out is the operating-environment safety net (margin level threshold), not a behavioral signal from the EA.

| Halt-class axis | Run #2 (2026-05-12) | Run #3 (2026-05-14) | Run #4/5 (IMPL-FIX-012 iter-2/3) | **Run #6 (this run)** |
|------------------|---------------------|---------------------|-----------------------------------|------------------------|
| Halt trigger | `circuit_breaker_pingpong` Slot_H broker SL Δ=0s | identical to Run #2 | iter-2: ping_pong Slot_H `OrderGroupStartWorkflow` Jan-27 mass-close; iter-3: ping_pong Slot_BI Jan-06 pyramiding close-then-open same-tick | **broker stop-out at margin 17.72%** (NOT EA-side) |
| Halt sim time | 2021-01-14 14:59:21 | 2021-01-14 14:59:21 | iter-2: 2021-01-27 15:45:07; iter-3: 2021-01-06 02:50:48 | **2021-08-04 16:06:00** |
| Final balance / equity | $470.83 | $470.83 | iter-2: $593.05; iter-3: $928.35 | **$0.84** |
| Drift vs baseline | −99.998% | −100.0022% | iter-2: ~−100%; iter-3: −100.0003% | **−100.0041%** |
| Sim depth covered | 14 sim days | 14 sim days | iter-2: 27 sim days; iter-3: 6 sim days | **216 sim days (7 sim months)** |

**Drift computation (Run #6):**

- Baseline Net Profit (5-yr): $24,271,276.63 per `ReportTester-25045474.html` (IMPL-061 extraction)
- Run #6 Net Profit: $0.84 − $1,000 deposit = **−$999.16**
- Absolute Δ: $24,271,276.63 − (−$999.16) = $24,272,275.79
- Relative drift: 24,272,275.79 / 24,271,276.63 × 100 = **−100.0041%** (CATASTROPHIC FAIL vs ≤ 25% target)

## §4 — Per-slot entry distribution (Run #6 pre-bankrupt window = 7 sim months)

> All counts are entries before broker stop-out at sim 2021-08-04 16:06:00. Baseline counts are 5-yr totals; Run #6 covers ~12% of the 5-yr window, but trade-count comparison is still informative for diagnosing over-fire patterns.

| Slot | Baseline (5-yr) | Run #6 (~7 sim mo) | Over/Under | Note |
|------|----------------:|-------------------:|-----------:|------|
| **BI** | **0**  | **101** | **MASSIVE OVER-FIRE** | Baseline = 0 entries (BR-1.1 zero-filled slot). Rewrite fires 101 BI pyramid entries → primary blow-up vector. G4 BI SL fix verified working (parent-pip-anchored SL per ADR-009), but pyramiding gate predicate over-permissive |
| **H**  | **7**  | **95**  | **13.5× OVER**   | Slot_H pyramid clustering is the proximate trigger that BR-3.6 ping_pong WAS halting at Jan-14 in Runs #2/#3 — confirmed by Run #6 reaching Jan-14 freely (no detector) then continuing to over-fire for 6 more sim months until balance drained |
| **LX** | **1**  | **15**  | **15× OVER**     | Pyramid wired (Phase 1B) — over-fire confirms LX pyramid gate predicate over-permissive |
| **B**  | 18 | 42 | 2.3× over | B parent of BR/BI chain; over-fire cascades into BI |
| **L**  | 7  | 16 | 2.3× over | |
| **T**  | 24 | 15 | 0.6× under | (truncated window expected) |
| **BR** | 7  | 9  | 1.3× over | within tolerance |
| **S**  | 13 | 8  | 0.6× under | (truncated window expected) |
| **K**  | 32 | 6  | 0.2× under | severe under-fire |
| C/D/F/G/G2/GO/I/J/M/P/Q/R | (mixed) | ≤1 each | severely under | CD chain barely firing; G/G2 family silent; P sub-modes silent |
| **Totals** | 231 | 314 | +36% | Volume excess driven entirely by BI/H/LX/B over-fire |

## §5 — Root-cause analysis

**The post-BT-002 build has eliminated the false-positive halt-class** (no CircuitBreaker, no `circuit_breaker_pingpong` records, 0 halt events in 578-record journal). This was the explicit BT-002 design intent and is empirically confirmed ✅.

**However, removing the detector exposed a deeper trading-logic translation gap (R-13 long-tail):**

1. **Slot_BI pyramid over-fire (101 entries vs 0 baseline)** — `InpBIPyramidGatePips=30` and the pyramid-eligibility predicate let BI fire pyramid orders far more aggressively than the legacy EA. Legacy `PhoenicisN2.10_stable.mq5` produces zero BI entries in the 5-yr 2021-2025 window per `baseline-per-slot.json`. Rewrite produces 101 in 7 sim months. The pyramid gate predicate is structurally too permissive.

2. **Slot_H pyramid clustering (95 entries vs 7 baseline = 13.5× over-fire)** — Slot_H's entry conditions (Fractal + Ichimoku gate per CodeWiki §3.4) fire much more frequently in the rewrite. The same Jan-14 clustering pattern that prior runs halted on via BR-3.6 ping_pong is now allowed to continue — and continues over-firing through August.

3. **Slot_LX pyramid over-fire (15 vs 1 = 15×)** — same pattern as BI; pyramid gate predicate over-permissive.

4. **B/BR/BI chain amplification** — Slot_B over-fires 2.3× (42 vs 18), each B parent spawns BR + BI children, compounding the pyramid blowup downstream.

5. **CD chain + G/G2/GO family near-silent** — Slots C/D/F/G/G2/GO/J/M/P/Q/R/T fire under-baseline; the rewrite has the inverse of the desired distribution (too much B/BI/H/LX pyramiding, too little disciplined CD/G/T entries).

The legacy EA achieves $24.27M Net Profit over 5 years not by avoiding pyramid blowups via a safety detector (BT-002 § Reason proves this: legacy lacks the ping-pong detector entirely) but by **never producing the BI/H/LX over-fire pattern in the first place**. The slot eligibility predicates in the rewrite are systematically too permissive on the pyramid slots and too restrictive on the disciplined-trend slots.

**This is the SAME class of defect as R-13 long-tail trading-logic translation gap** (impl-plan.md Open Risks R-13) — Q1 paired canary diff (IMPL-FIX-011 chain 2026-05-10/11) ranked T/G/G2/B/K as the top-5 divergent slots; Slot_BI/H/LX did not surface in Q1 because their over-fire pattern materializes only over multi-month windows when pyramid-eligibility predicates accumulate enough triggering conditions to fire repeatedly.

## §6 — Comparison vs prior IMPL-062 runs

| Axis | Run #1 (G4-OFF day-1 stop-out 2026-05-10) | Run #2 (G4-OFF Phase 1B 2026-05-12) | Run #3 (G4-ON BT-001 2026-05-14) | Run #4/5 (IMPL-FIX-012 iter-2/3 2026-05-17) | **Run #6 (post-BT-002 no-detector 2026-05-19)** |
|------|----------------------------------------------|--------------------------------------|------------------------------------|----------------------------------------------|---------------------------------------------------|
| Build | pre-Phase-1B (8 slots wired) | Phase 1B (14 slots, `DISABLE_G4_FIXES`) | Phase 1B (16 slots G4-ON default) | + ADR-013/ADR-014 producer-side filters | **post-BT-002: no CircuitBreaker, no ADR-013/014, no HALT_PINGPONG** |
| Halt source | broker stop-out (margin) | CircuitBreaker BR-3.6 ping_pong | CircuitBreaker BR-3.6 ping_pong | CircuitBreaker BR-3.6 ping_pong (still firing) | **broker stop-out (margin)** |
| Sim depth | day-1 (17 hr) | 14 sim days | 14 sim days | iter-2: 27 days; iter-3: 6 days | **216 sim days (~7 months)** |
| Final balance | $512.80 | $470.83 | $470.83 | iter-2: $593.05; iter-3: $928.35 | **$0.84** |
| Drift | −100% | −99.998% | −100.0022% | iter-2: ~−100%; iter-3: −100.0003% | **−100.0041%** |
| Best outcome on axis | — | — | — | iter-3 had highest residual balance ($928) | **deepest sim coverage (7 mo)** but lowest balance |
| Detector influence | n/a (pre-Phase-1B) | masking R-13 long-tail at day 14 | masking R-13 long-tail at day 14 | three false-positive classes accumulated | **detector absent — R-13 long-tail fully exposed** |

**Pattern across all 6 runs:** Bucket A drift ~−100% regardless of (a) G4-on-vs-off, (b) detector-on-vs-off, (c) ADR-013/014 filter present-vs-absent. The rewrite cannot achieve parity with legacy baseline at the current slot trading-logic translation fidelity. **Each "fix" applied to the detector layer (ADR-013, ADR-014) only changed WHERE the halt fires (Jan-14 → Jan-27 → Jan-06), not WHETHER the rewrite is competitive with the baseline.** BT-002 (remove the detector entirely) gave the rewrite the longest runway (7 sim months vs 14 sim days) but the bleed continues.

## §7 — Escalation options

This is the **6th IMPL-062 run, all FAIL** with drift ≈ −100%. The cap-3 iteration discipline applies to IMPL-FIX-* tickets, not IMPL-062 main task. The empirical signal is unambiguous: **slot trading-logic translation at multiple slots (BI / H / LX / B) is the actual NFR-1.1 blocker**; the detector layer was a downstream symptom-masker.

**Recommended paths (operator decision):**

1. **`/backtrack sd`** — re-examine slot trading-logic translation contract at the SD layer (CodeWiki §3.X mirroring vs slot eligibility predicates). Likely cascade: SD § 1.1 FR-2/3 trace updates + ADR-NNN authored for pyramid-gate predicate calibration policy + `08-product-breakdown.md` IMPL-019..039 task descriptions re-audited. Higher cost than IMPL-FIX-* but addresses the structural cause.

2. **`/impl-plan-review all`** — re-decompose IMPL-062 acceptance criteria. Options: (a) substitute softer NFR-1.1 acceptance (e.g., advisory-only — drift ≤ 50% truncated 6-month window); (b) open new `IMPL-FIX-014` (Slot_BI pyramid gate calibration) + `IMPL-FIX-015` (Slot_H over-fire calibration) + `IMPL-FIX-016` (Slot_LX pyramid gate) as targeted slot-level fixes; (c) demote IMPL-062 priority and revisit after the IMPL-FIX-014..016 chain closes.

3. **`/backtrack ba`** — re-baseline NFR-1.1 contract. Acknowledge that exact $24.27M parity is unachievable at MVP scope; redefine NFR-1.1 acceptance as "rewrite achieves positive Net Profit over 5-yr window AND maintains Account Equity > $1 (i.e., does not blow up the account)" — a much weaker contract but achievable. Cascades: BA `03 § NFR-1.1` rewording + SD trace + TD + project bootstrap regen.

4. **Hold and re-survey** — preserve Run #6 as audit evidence, leave IMPL-062 E-AC `[ ]`, schedule a 1–2 hr design-review session to enumerate slot-level over-fire patterns from `_session-handoff/IMPL-062-bucket-a-5yr-run6-20260519.jsonl` (the journal has all 314 entry records timestamped with `signal_context` and `comment` fields enabling pattern attribution per slot). Lowest cost; defers decision.

Engineer recommendation: **path (2) `/impl-plan-review all`** — the BI/H/LX over-fire pattern is precisely the kind of defect a Plan QA re-decomposition can address by introducing targeted IMPL-FIX tickets, and the journal evidence is rich enough to formulate concrete acceptance criteria for each fix. `/backtrack sd` (path 1) is overkill if the issue is predicate calibration, not architectural; `/backtrack ba` (path 3) is premature without first attempting predicate-level fixes.

## §8 — Closure status (this session)

**IMPL-062 task block:**
- S-AC: 3/3 stay `[x]` (no S-AC changes — the structural build + `.ini` + report skeleton existed pre-Run-#6; Run #6 only exercises the empirical AC)
- E-AC #1 (|drift| ≤ 25% NFR-1.1): stays `[ ]` — **🔴 EXERCISED via Run #6 → drift = −100.0041% FAIL**. Registry row stays Active; expiry was 2026-05-28 (renewal #1 of max 2 already consumed); **next renewal will be the 2nd-of-2 — last renewal allowed before forced escalation per Phase 1.3.2 cap policy**
- E-AC #2 (all 21 per-slot deviations ≤ 10% NFR-1.6): stays `[ ]` — N/A (truncated 7-month window vs 5-yr baseline; halt prevents 5-yr completion); same blocker as E-AC #1
- Status block update: append new Run #6 narrative (this evidence file is the primary artifact)

**Empirical Closure Discipline (Golden Rule #9):** Run #6 is recorded as `[ ]` `EXERCISED → FAIL` not `[x]` close. The forbidden pattern `[x] deferred per <task> precedent` does NOT apply; the row stays unchecked because the acceptance threshold is not met empirically. Evidence path: `_session-handoff/IMPL-062-bucket-a-5yr-run6-20260519.{md,jsonl,-tester-abridged.txt}` (3-artifact bundle).

**State Reconciliation 3-file rule:**
- Layer 1 primary `impl-plan.md`: TL;DR top entry + IMPL-062 Status block (this commit)
- Layer 2 `overview.md`: row 19 (Impl Plan) + row 20 (Impl Tasks) status text refresh
- Layer 3 `current_handoff.md`: new Last completed action section (this commit) + 3 evidence sidecars at `_session-handoff/`

**Plan Staleness Sentinel:** unchanged at 1 IMPL-NNN main task closure since R09 (IMPL-062 Run #6 is empirical verification of an existing task whose structural closure landed 2026-05-05; the task itself is not "newly closed" so the sentinel counter does not increment per `workflow.md` Gate #4 + fix-round-10 precedent).

**Recommended next action:** `/impl-plan-review all` per §7 path (2) — re-decompose IMPL-062 acceptance + author IMPL-FIX-014/015/016 slot-level predicate-calibration tickets with concrete acceptance criteria derived from the 314-record journal entry pattern attribution.

---

**Evidence artifacts (this run):**
- `_session-handoff/IMPL-062-bucket-a-5yr-run6-20260519.md` (this file; ~9 KB §1-§8 narrative)
- `_session-handoff/IMPL-062-bucket-a-5yr-run6-20260519.jsonl` (578-record journal; 374 KB schema-valid)
- `_session-handoff/IMPL-062-bucket-a-5yr-run6-20260519-tester-abridged.txt` (265-line decoded Tester log abridge; 35 KB; raw 174,664-line + 58 MB UTF-16LE not committed per binary-noise rule)

**Pre-bankrupt sim depth:** 2021-01-01 → 2021-08-04 (216 sim days; ~12% of 5-yr window covered before broker stop-out)  
**Wall-clock total:** 9m35s Tester + ~30s operator kill latency (operator observed zombie state at ~+8 min and signaled "test is zombie now. it's bankrupt")
