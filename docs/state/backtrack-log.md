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
- **Status:** 🔄 Open
- **Approved by:** Operator (Kritsana) 2026-05-12
- **Resolution:** _(pending — operator runs new session for `/amend ba` or direct edits to NFR-1.1 + NFR-1.8; followed by `/sd-review all` + `/impl-plan-review all` to re-validate downstream)_

---
