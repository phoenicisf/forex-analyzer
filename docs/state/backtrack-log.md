# Backtrack Log

บันทึกการย้อน phase — append-only, ห้ามลบ entries เก่า

---

## BT-001 — NFR-1.1 Bucket A re-baseline (eliminate DISABLE_G4_FIXES confound)

- **Date:** 2026-05-12
- **Triggered by:** Phase 3 IMPLEMENT (operator `/impl-task IMPL-FIX-003 Phase 1B` → Bucket A 5-yr Run #2 verify-only execution)
- **Source:**
  - `docs/state/regression-bucket-a.md § 4a Run #2 root-cause analysis`
  - `docs/state/_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.txt` (Tester log; 16,734 lines)
  - `docs/state/_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.jsonl` (journal; 72 records)
  - Commit `e75dc2c` — Bucket A 5-yr Run #2 closure
- **Backtrack from:** Phase 3 IMPLEMENT → Phase 1A BA Requirements
- **Reason:** IMPL-062 Bucket A 5-yr Run #2 (2026-05-12) FAILED catastrophically (drift ≈ 99.998%) under `#define DISABLE_G4_FIXES` build. Root-cause analysis confirmed NOT a Phase 1B regression — Phase 1B wiring fired correctly (40 entries + 30 exits with 0 `order_failed`; BR-trigger gate flip transitively activated Slot_BR per design; CircuitBreaker BR-3.6 + HALTED state machine ADR-010 working as designed). The catastrophic drift is a structural artifact of the Bucket A measurement contract: with `DISABLE_G4_FIXES`, the pre-G4 path (Slot_J wrong-magic + Slot_BI naked SL) combined with the **rewrite's 16-active-slot concurrency** triggers `CircuitBreaker.ping_pong` BR-3.6, halting the EA at sim 2021-01-14. The 16-slot concurrency is intrinsic to the rewrite architecture (cannot be reverted via a compile flag), so comparing "rewrite-G4-OFF" vs legacy baseline ($24.27M, with different slot concurrency profile) is apples-to-oranges. The NFR-1.1 ≤ 25% Bucket A contract is structurally unmeetable as currently authored.
- **Proposed change (BA):**
  - **NFR-1.1** redefine "Bucket A" from "rewrite-G4-OFF vs baseline" → "rewrite-G4-ON vs baseline" (i.e., measure the default-build rewrite against legacy baseline)
  - **NFR-1.8** redefine "Bucket B" from "rewrite-G4-ON vs rewrite-G4-OFF" → informational delta: `rewrite-G4-ON − rewrite-G4-OFF` showing intentional fix contribution, no longer drives primary acceptance gate
  - Add empirical citation paragraph referencing 2026-05-12 Run #2 finding
- **Impacted phases:**
  - **BA** — `docs/ba/03-non-functional-requirements.md § NFR-1.1` + `§ NFR-1.8` (target rework); `docs/ba/04-business-rules.md` (re-validate cross-refs)
  - **SD** — `docs/design-docs/02-high-level-architecture.md` (lines 71/137/441/442/469); `docs/design-docs/03-deep-dive.md` (lines 11/19/57/59/308); `docs/design-docs/08-product-breakdown.md` IMPL-062/063 task descriptions (re-validate; no architectural change expected)
  - **TD** — none observed (grep clean; no direct Bucket A reference)
  - **Impl Plan** — `docs/state/impl-plan.md` IMPL-062 + IMPL-063 task entries (re-validate via `/impl-plan-review all`)
  - **Impl Code** — `slots/Slot_J.mqh` + `slots/Slot_BI.mqh` `#ifdef DISABLE_G4_FIXES` guards (decide: keep as forensic toggle OR remove if Bucket B drops from Must-priority); `simulation/headless-tests/regression_5yr_no_g4.ini` (decide: deprecate or keep as informational); `docs/state/regression-bucket-a.md` (re-author target semantic)
  - **Code Review** — `docs/code-review/*` mentions are historical/audit; no rewrite needed
- **Status:** ✅ Resolved 2026-05-13
- **Approved by:** Operator (Kritsana) 2026-05-12
- **Resolution:** BT-001 cascade closed in 5 steps (per `current_handoff.md § BT-001 cascade chain status`): (1) **BA cascade** — Rebuttal Round 04 + Round 05 verify-only ✅ 2026-05-12 (0 finding, `ba/claim-review-and-rebuttal/{rebuttal-round-04,claim-review-05}.md`); (2) **SD cascade** — Rebuttal Round 04 + Round 06 verify-only ✅ 2026-05-13 (0 finding, `design-docs/claim-review-and-rebuttal/{rebuttal-round-04,claim-review-06}.md`); (3) **Impl Plan re-validate** — Review Round 11 + Rebuttal 11 ✅ 2026-05-13 (7/7 Accept; BT-001 cascade drained across ~19 surfaces of `impl-plan.md`) + Review Round 12 + Rebuttal 12 ✅ 2026-05-13 (6/6 Accept; backtrack-log↔impl-plan SoT reconciliation completed; this entry flipped via R12 §12.1 Cascaded Changes Path A); (4) **TD verify** — deferred / not required (SD Round 06 verify-only confirmed `TD-02 § 13` Strategy Tester audit contract was already single-pass G4-ON per grep clean; no TD-side stale framing surfaced); (5) **Close BT-001** — executed in R12 §12.1 Cascaded Changes (Status flipped to ✅ Resolved + Resolution populated + `overview.md` BT-001 markers trimmed per Check 0.7 Direction A + `current_handoff.md § BT-001 cascade chain status` Step 3 + Step 5 flipped to ✅ Closed). **Resolution direction:** NFR-1.1 = `rewrite-G4-ON vs baseline single-pass` (BA `03 § NFR-1.1 Verification` line 32 + SD `08 § 1.10` line 129); NFR-1.8 demoted Must → Should informational delta `rewrite-G4-ON − rewrite-G4-OFF` (no acceptance gate). **Forensic toggle decision:** `slots/Slot_J.mqh:180` + `slots/Slot_BI.mqh:212` `#ifdef DISABLE_G4_FIXES` guards retained as forensic toggle per IMPL-062 task block S-AC #1 (decide at IMPL-FIX-NNN follow-up; not required for BT-001 measurement path). **Empirical citation preserved:** IMPL-062 Run #1 (2026-05-10 day-1 stop-out) + Run #2 (2026-05-12 Phase 1B build, drift ≈ 99.998%, CircuitBreaker BR-3.6 HALTED) attest measurement-contract incompatibility of pre-BT-001 `DISABLE_G4_FIXES` Bucket A framing.

---
