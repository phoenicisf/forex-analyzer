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

## BT-002 — Remove BR-3.6 CircuitBreaker ping-pong detector (legacy-parity safety contract)

- **Date:** 2026-05-17
- **Triggered by:** Phase 3 IMPLEMENT (operator `/impl-task IMPL-FIX-012` iter-3 Run #5 → cap-3 budget exhausted → escalation gate fires per `impl-plan.md ~line 1978`)
- **Source:**
  - `docs/state/_session-handoff/IMPL-FIX-012-iter3-run5-20260517.md § 5` (escalation gate; engineer recommends Path B `/backtrack sd`)
  - `docs/state/_session-handoff/IMPL-FIX-012-iter3-run5-20260517.jsonl` (Run #5 journal; 19 records — 1 `halt` + 1 `halt_stable` event with `halt_reason=circuit_breaker_pingpong magic=214 dir=0 delta=0s pos_i=12 pos_j=14 evt_i=1 evt_j=0`)
  - `docs/state/_session-handoff/IMPL-FIX-012-iter3-run5-20260517-tester-abridged.txt` (Tester log; halt at sim 2021-01-06 02:50:48 — 8 sim days EARLIER than Jan-14 baseline class)
  - `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-blocked-20260517.md` (Run #4 falsification narrative — Jan-27 EA-driven mass-close class)
  - `docs/adr/014-circuitbreaker-pingpong-position-event-dedup.md § Falsification triggers` clause #1 ("iter-3 G3 5-yr Run #5 reveals a third false-positive halt class → revisit detector design") — fired
  - `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md § Alternatives § Option C` — rejected during iter-1, empirically falsified by Run #4
  - Commits: `6bff2d0` (iter-3 closure with cap-3 exhaustion narrative); `15ff985` (ADR-014 schema + producer wiring); `4f4d0b2` (Day 17 retrospective)
- **Backtrack from:** Phase 3 IMPLEMENT → Phase 1B System Design
- **Reason:** BR-3.6 ping-pong detector's matching key `(magic, direction, Δ≤3s)` is structurally incompatible with three legitimate trading patterns produced by the EA's 16-active-slot concurrency profile: **(class 1)** broker-driven same-tick SL hits (Jan-14 class, addressed by ADR-013 DEAL_REASON filter); **(class 2)** EA-driven mass-close via `OrderGroupStartWorkflow`/`SafePort` (Jan-27 class, addressed by ADR-014 same-event_type skip); **(class 3)** Slot_BI pyramiding close-old + open-new same-tick (Jan-06 class, surfaced AFTER ADR-014 wired `RecordOpen` for the first time — different positions, different event_types, but same magic+dir+Δ=0s → fires). Three cap-3 iterations (iter-1 ✅ surgical + iter-2 ❌ partial + iter-3 ❌ regression) consumed the engineer-side budget. ADR-014's rule (c) `pos_i==pos_j → skip` is the **structural inverse** of the canonical ping-pong concept (same logical position closed-then-re-opened) — it skips the very pattern the detector was authored to catch and fires on legitimate different-position close+open at the same tick. Legacy `PhoenicisN2.10_stable.mq5` achieves the $24.27 M / 5-yr baseline (NFR-1.1 reference) **without any ping-pong detector** — empirical proof the safety capability is not load-bearing for the EA's known trading pattern set.
- **Proposed change (SD — Option 1: remove detector, legacy-parity):**
  - **SD `02-high-level-architecture.md`:** drop Requirements Trace row for FR-6.6 (line ~54); remove or repurpose Services Catalog row #14 `CircuitBreaker` (line ~290)
  - **SD `03-deep-dive.md`:** drop perf-budget rows for `CircuitBreaker::CheckPingPong()` (lines ~98, ~113); re-author NFR-1 reference paragraph at lines ~43, ~57-59 (CircuitBreaker no longer the cited halt cause for Bucket A measurement path)
  - **SD `04-data-flow.md`:** remove `CB` participant + `ping-pong detected` alt-branch from mermaid (lines ~26, ~48); update "always evaluate halt trigger" cell (line ~551)
  - **SD `05-security.md`:** drop "Infinite re-entry loop (CircuitBreaker should catch)" threat-model row + Mitigation Map row (lines ~120, ~151) — or re-control under a different mitigation (e.g., legacy-parity = no automated mitigation)
  - **SD `08-product-breakdown.md`:** IMPL-051 task (`CheckPingPong` impl) → cancelled-by-BT-002 (lines ~103, ~286); update P3 dependency note (line ~226); update NFR-1 reference paragraph (line ~245)
  - **ADR-010 `halted-state-exit-only.md`:** amend "Trigger sources" (line ~19) — CircuitBreaker removed from halt-trigger list; HALTED state machine remains for handle-invalid + future Phase 2 triggers (equity-floor, journal-sustained-failure)
  - **ADR-013 + ADR-014:** status flipped Accepted → `Superseded by BT-002` — preserved as audit history (the iter-1/-2/-3 chain documents the falsification path)
  - **API spec `trade-journal-schema.yaml`:** drop `circuit_breaker_pingpong` from `halt_reason` enum (lines ~131, ~189); breaking change OK in Phase 1 (no external consumers per ADR-006)
  - **Chained `/backtrack ba`:** BR-3.6 itself is a BA business rule (`docs/ba/04 § BR-3.6` lines 192-199) and FR-6.6 is the corresponding functional requirement (`docs/ba/02 § FR-6.6` lines 579-590). SD cannot unilaterally remove a BA requirement — operator must explicitly authorize BR-3.6 + FR-6.6 demotion to `Won't` (or removal) at the BA layer before SD propagation locks. Engineer recommends BA demotion order: `/backtrack ba` chained AFTER SD lock so the BA rebuttal cycle has a concrete SD proposal to align against.
- **Impacted phases:**
  - **BA (chained backtrack)** — `docs/ba/04 § BR-3.6` demote/remove; `docs/ba/02 § FR-6.6` demote/remove; `docs/ba/03 § NFR-1.1 Empirical Citation` (lines 149-159) — narrative cites CircuitBreaker as Run #2 halt cause, needs re-author or footnote post-BT-002
  - **SD** — 5 design docs + 3 ADRs (010 amend; 013/014 supersede) + 1 API spec — see SD proposed-change list above
  - **TD** — `02-backend-design.md § 5.8` (lines 875-898) CCircuitBreaker class skeleton DELETE; cross-refs at lines 66, 854, 1418, 1456, 1506, 1599, 1763, 1828, 1898, 2099 — cascade cleanup; `04-database-design.md` re-validate (no CB state in `state-persistence-schema.yaml` per ADR-014 § Migration; expected grep clean)
  - **Project Bootstrap (Phase 2.5)** — TD changed → `.claude/stack.json` + `.claude/rules/*` stale → mandatory `/project-init --regen` per `backtrack-workflow.md § Project Bootstrap Invalidation` row "TD = Always invalidated"
  - **Impl Plan** — `docs/state/impl-plan.md` IMPL-051 (cancel), IMPL-FIX-012 task closure pivots from `[ ]` "iter-3 fails" → `[x]` "BT-002 supersedes — detector removed at SD/BA"; re-run `/impl-plan-review all` after SD lock; IMPL-062/063 paired-bundle stays gated on G3 5-yr re-run post-BT-002
  - **Impl Code** — DELETE `services/CircuitBreaker.mqh`; strip `Record{Open,Close}` dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from `core/Orchestrator.mqh::OnTradeTransaction`; remove `CheckPingPong` call from `OnTick`; DELETE `spike/Spike_CircuitBreaker.mq5`; verify `domain/EnumTypes.mqh` for `HALT_PINGPONG` constant removal; mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal)
  - **Code Review** — 51 `docs/code-review/*.md` files are historical audit artifacts (no rewrite); next review round (Round 27) will validate the BT-002 cleanup
  - **Red Team** — n/a (not started)
  - **UX** — n/a (skipped)
- **Status:** ✅ Closed (2026-05-18)
- **Approved by:** Operator (Kritsana) 2026-05-17 (selected Option 1 — remove detector, legacy-parity)
- **Resolution:** SD-side cascade CLOSED 2026-05-17 via 3-round chain — Round 07 (7 findings) → rebuttal-round-05 (7 accept commit `111f092`) → Round 08 (2 findings) → rebuttal-round-06 (2 accept commit `32c56c0`) → Round 09 final verify-only **0 findings** ✅ (commit `e385ad0`); SD package = 18 BT-002 propagation surfaces + 9 cascade-completion surfaces single-voice across 6 SD docs + 4 ADRs + 1 API spec. BA-side cascade CLOSED 2026-05-18 via 1-cycle chain — BA cascade applied (commit `863493e`) consuming concrete SD proposal → Round 06 BA review (1 LOW cosmetic cite-annotation gap) → rebuttal-round-05 (1 accept) → ready-for-handoff. BA package = 18 BT-002 propagation surfaces + Anti-Duplication clean vs prior Round 04/05. Pending downstream cascade: TD review (`02-backend-design.md § 5.8` CCircuitBreaker skeleton DELETE + 10 cross-refs per Impacted phases TD) — out of BT-002 BA-closure scope; tracked separately. Impl-plan IMPL-051 closure + IMPL-FIX-012 task closure pivot — out of BT-002 BA-closure scope; tracked via `/impl-plan-review` next cycle. Commit chain: `aebec01` (BT-002 open) → `0be2a51` (SD apply) → `111f092` (SD rebuttal-05) → `32c56c0` (SD rebuttal-06) → `e385ad0` (SD Round 09 final verify) → `863493e` (BA apply) → BA rebuttal-round-05 + BT-002 closure commit (this commit).

---
