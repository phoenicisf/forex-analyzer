# Code Review Fix Round 15

| Field | Value |
|-------|-------|
| **Round** | 15 |
| **Review File** | `docs/code-review/review-round-15.md` |
| **Date** | 2026-05-05 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 15.1 | `InpSPercentTp` boot-time validation gap (operator can re-trigger FIX-001 defect class via MT5 input dialog) | 🟠 HIGH | Accept | 3 (`core/BootstrapValidator.mqh` + `core/Orchestrator.mqh` + `inputs/Inputs_Slot_S.mqh`) | TBD |
| 15.2 | Walk batch-2 partial-drain narrative not propagated to registry rows IMPL-007 + IMPL-049 (×2) + IMPL-052 | 🟡 MEDIUM | Accept | 1 (`docs/state/deferred-ac-registry.md` — 4 row annotations) | TBD |
| 15.3 | Plan Staleness Sentinel 7-vs-6 internal contradiction (walk drain ≠ task closure per workflow.md gate #4) | 🔵 LOW | Accept | 3 (`docs/state/impl-plan.md` line 9 + line 55 + `current_handoff.md` line 49 + `overview.md` line 20) | TBD |
| 15.4 | Walk-summary G3 wall-clock 33% variance lacks system-load context (NFR-2.x methodology gap) | 🔵 LOW | Accept | 1 (`docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md`) | TBD |
| XS-15.1 | Broader `inputs/` audit for discrete-set semantics | — | Defer to Phase-2 backlog | 0 (no current input matches; verified via grep) | — |
| XS-15.2 | Canonicalize Result-Table fill pattern in `.claude/rules/testing.md` / `andm-impl-engineer/SKILL.md` | — | Defer to Phase-2 backlog | 0 (trigger naturally at IMPL-065/066/067 result-table authoring) | — |

**Accepted:** 4 findings (1 source defense-in-depth + 3 state/doc edits)
**Rejected:** 0
**Partial:** 0
**Deferred:** 2 XS to Phase-2 backlog (no blocking impact on R15 closure)

---

## Accepted Findings — Fixes Applied

### Fix for Finding 15.1: BootstrapValidator::ValidateSlotInputs() umbrella + Orchestrator wire + Inputs_Slot_S comment refresh

**Verdict:** Accept

**Scope:** 3 files in core/ + inputs/ (defense-in-depth source change)

**Problem recap:** FIX-001 (commit `4110a78`) added `input double InpSPercentTp = 10.0;` to `Inputs_Slot_S.mqh` and threaded it as the 4th arg to `m_risk.ComputeLot` at `Slot_S.mqh:203`. Default value is one of {5, 10, 15} — happy path. But MT5 exposes every `input` declaration in the chart-attach input dialog and Strategy Tester optimization sweep, so an operator can set `InpSPercentTp = 8.0` (intuition "8% TP") or any sweep step value, none of which match BR-4.1. The consumer `RiskManager::_ComputeLotForS` then falls through to the `else` branch at lines 409-415 emitting `[ERROR][ev=s_pct_tp_invalid]` per tick + returning lot=0.0 — the exact regression the FIX retired on the happy path. Tier 1.5 walk batch-2 walked the happy path (default 10.0); off-default operator action was not exercised.

**Changes:**

- `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh` — added `#include "../inputs/Inputs_Slot_S.mqh"` (per-slot input visibility for the validator); added `bool ValidateSlotInputs() const;` declaration with header doc block citing R15 15.1 + BR-4.1 + Phase-2 extension hook for XS-15.1; added body after `RunDomainSelfTests` that checks `MathAbs(InpSPercentTp - {5,10,15}) >= 0.001` (tolerance mirrors `RiskManager::_ComputeLotForS` consumer at `services/RiskManager.mqh:402-415` — keep in sync) and emits `ErrorBypassThrottle("system","invalid_input",0,…)` on failure (consistent with `ValidateInputs` 39-Guard pattern + ADR-011 boot-time bypass per NFR-5.1).
- `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh` — Phase C inserts `if(!m_validator.ValidateSlotInputs()) { CleanupPartialInit("validate_slot_inputs"); return INIT_FAILED; }` between the existing `ValidateInputs` and `ValidateSymbol` guards (logical position: cross-slot inputs first, per-slot inputs second, symbol whitelist third).
- `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_S.mqh:33` — comment now reads `percent_tp MUST be one of {5, 10, 15} per BR-4.1 (BootstrapValidator::ValidateSlotInputs fails INIT_FAILED on violation — R15 Finding 15.1 defense vs FIX-001 defect class regression); default 10 per CodeWiki §3.S` so future readers see the discrete set + the validator citation without grep'ing.

**Verification:**

- **G1 compile gate (Phase 5 § 4-gate DoD):** `MetaEditor64.exe /compile:MQL5\Experts\PhoenicisNex\PhoenicisNex.mq5 /log` → `Result: 0 errors, 0 warnings, 3844 ms elapsed`. `.ex5` regenerated with the new validator umbrella + Phase C wire transitively pulled.
- **Reviewer's suggested fix Part 1 honored** verbatim (validator umbrella + Orchestrator wire); Part 2 honored verbatim (Inputs_Slot_S comment refresh); Part 3 (auto-snap to nearest valid value) explicitly rejected per reviewer's own footnote ("masking operator typo with silent snap makes debug harder than fail-fast") + ADR-011 fail-fast precedent.
- **Defense scope:** the validator runs in OnInit Phase C step 4 (after ValidateInputs Guards 1-39, before ValidateSymbol). MT5 input dialog operator action + Strategy Tester optimization sweep both hit OnInit on every parameter change → INIT_FAILED on invalid value → operator sees `[ERROR][ev=invalid_input][InpSPercentTp=…]` boot-time bypass log + Alert + return INIT_FAILED *before* OnTick ever runs the broken consumer path. IMPL-017 (P4 optimization sweep) is now safe against accidental sweep-step-1 ranges that include invalid values — invalid steps fail-fast with clean log instead of producing 11/11 contaminated runs.

**Commit:** `[fix:ea] R15 15.1 BootstrapValidator::ValidateSlotInputs umbrella + Orchestrator Phase C wire`

---

### Fix for Finding 15.2: Registry partial-drain narrative propagation (IMPL-007 + IMPL-049 ×2 + IMPL-052)

**Verdict:** Accept

**Scope:** 1 file (`docs/state/deferred-ac-registry.md` — 4 row annotations); state-only

**Problem recap:** Tier 1.5 walk batch-2 (2026-05-05) produced structured per-row evidence: 4 rows fully drained (IMPL-009 / IMPL-FIX-001 / IMPL-FIX-002 / IMPL-064) → strikethrough'd in Active + appended in Resolved ✅; 3 rows partially drained (IMPL-007 / IMPL-049 / IMPL-052) → walk-summary correctly identifies the log-assertion clause as captured + the second clause (`[db-inspect]`/`[boot-cold]`/`[contract-roundtrip]`) as still pending real broker fills via IMPL-062 chain. The partial-drain status was reflected in the walk-summary artifact, but the registry row narratives themselves still cited pre-walk preconditions — load-bearing pointers for `/impl-task` HALT logic + `/deliver` block + `/impl-review` Dim #11 inspection. Stale narrative = future status agent risk: row reads as "still blocked on prereqs done last week" while the walk artifact already shows partial progress.

**Changes (4 row annotations; mirrors IMPL-022 G4 attestation row precedent):**

- **IMPL-007** (P1 / line 15) — appended "Partially resolved 2026-05-05 via Tier 1.5 walk batch-2" annotation to "Deferred reason" column; cites Tester log line emitting `[Phoenicis][slot=portfolio][ev=portfolio_registered][magic=0] magics registered: 17` (line 252 abridged); notes IMPL-053..060 prereqs now closed + entry .mq5 runnable; remaining `[db-inspect]` half (`GetByMagic(MAGIC_X).total_profit` matches MT5 native broker reconcile against open positions) requires real position flow → still gated on IMPL-062 5-yr regression with `RiskManager::OpenOrder` wired. Row stays Active until db-inspect clause drained.
- **IMPL-049** boot-cold row (P2 / line 24) — appended "Partially resolved 2026-05-05" annotation; cites 5 enter_pending events fired for machines C/M/T/Q/P + 4 transition_executed events for C/M/T/Q + state.json `pending_machines` 8 keys schema-valid. Remaining `[boot-cold]` clause (kill+reload + force-clear at threshold) — 3-day window did not cross InpForceClearM_Bars=150 / T=80 / Q=100 H4 bars; gated on IMPL-062.
- **IMPL-049** file-blob-check row (P2 / line 25) — explicitly notes "**Not drained by Tier 1.5 walk batch-2 (2026-05-05)**" because 3-day window crossed no force-clear threshold → no journal force-clear record produced. Still gated on IMPL-062 / IMPL-068 paired bundle. Annotation prevents future status agent confusing this row with the boot-cold sibling that *did* have partial log evidence.
- **IMPL-052** (P2 / line 23) — replaced stale "Live `terminal64.exe` headless tester invocation could not attach in current environment" wording (factually wrong — the bootstrap_smoke.ini Tester DID attach successfully) with "Partially resolved 2026-05-05" — cites `[ev=state_corrupt_starting_fresh]` fired on first-run when state.json absent → in-RAM resolved to RUNNING (init_ok line confirms). Remaining HALTED-restart specific clause requires synthetic state.json fixture (state=HALTED + portfolio_count=0); gated on IMPL-062 / dedicated boot-cold spike. Row stays Active until HALTED-restart clause drained.

**Verification:**

- All 4 annotations follow IMPL-022 G4 attestation row precedent (line 40) which already uses this format.
- Row-stays-Active per Dim #11 partial-drain handling — registry contract preserved; only the narrative now reflects ground truth.
- No source code touched; G1 unaffected.

**Commit:** `[chore:state] R15 15.2 deferred-ac-registry partial-drain annotations IMPL-007 + IMPL-049 ×2 + IMPL-052`

---

### Fix for Finding 15.3: Plan Staleness Sentinel 7→6 revert across 3 files

**Verdict:** Accept

**Scope:** 3 state files (state-only)

**Problem recap:** Plan Staleness Sentinel proper (`impl-plan.md` line 1778) was correctly maintained at 6 closures since R07 (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068). But after the Tier 1.5 walk batch-2 closure, the parallel-narrative TL;DR at line 9 was inflated to "7 closures since R07 review (+1 walk drain)" — and the bump propagated to `current_handoff.md:49` + `overview.md:20` + `impl-plan.md:55` Next Best Action. Walk drains are E-AC residue cleanup of already-closed tasks, not new IMPL-NNN closures; per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4 ("After closing task, bump Sentinel by +1") + fix-round-10 § Plan Staleness precedent ("fix-rounds are review-loop artifacts, not task closures"), the Sentinel should remain at 6.

**Changes (3 files, 4 sites):**

- `docs/state/impl-plan.md:9` (TL;DR `Last updated:` block) — reverted "7 closures since R07 review (+1 walk drain) — within threshold" → "6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068; walk batch-2 drain ≠ task closure per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4 + fix-round-10 Plan Staleness precedent — fix-rounds + walk drains are review-loop / E-AC residue cleanup artifacts, not new IMPL-NNN closures) — within 10-closure threshold ✅".
- `docs/state/impl-plan.md:55` (Next Best Action) — "7 closures since R07 within threshold" → "6 closures since R07 within threshold (walk drain not counted per workflow.md gate #4)".
- `docs/state/current_handoff.md:49` — reverted "7 closures since R07 review (was 6 + 1 walk drain)" → "6 closures since R07 review unchanged (walk batch-2 drained 4 E-AC residues but zero new IMPL-NNN closures; per workflow.md gate #4 + fix-round-10 precedent fix-rounds + walks are not counted)".
- `docs/state/overview.md:20` — reverted "Plan Staleness Sentinel = 7 closures since R07" → "Plan Staleness Sentinel = 6 closures since R07 unchanged (walk batch-2 drained 4 E-AC residues but zero new IMPL-NNN closures per workflow.md gate #4 + fix-round-10 precedent)".

**Verification:**

- Sentinel section line 1778 was already correct at 6 — no edit needed there; only the parallel-narrative inflation was reverted.
- Originating R15 finding 15.3 pattern grep on `docs/state/`: `walk drain.{0,30}within threshold|7 closures.{0,30}walk drain` = 0 hits ✅.
- The two remaining "Plan Staleness Sentinel = 7 closures since R07" hits in `current_handoff.md` lines 74 + 98 sit inside historical "Prior completed action" narrative blocks describing what fix-round-14 + fix-round-13 claimed *at the time of those rounds* — those are audit history, not current state, and out of R15 scope.

**Commit:** `[chore:state] R15 15.3 Plan Staleness Sentinel revert 7→6 (walk drain ≠ task closure per workflow.md gate #4)`

---

### Fix for Finding 15.4: Walk-summary System Load Context subsection

**Verdict:** Accept

**Scope:** 1 file (`docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md`); doc-only

**Problem recap:** The Execution table claims "+2:15 (variance; same fixture)" for batch-2 vs batch-1 wall-clock, but Strategy Tester `Model=0` non-tick OHLC + fixed FromDate/ToDate + fixed Deposit/Leverage = fully deterministic at the data layer (304,418 ticks identical confirms). The 33% delta is therefore host-load variance, not test-methodology variance — but the artifact didn't capture that distinction, leaving future NFR-2.x reviewers (IMPL-065 tick latency / IMPL-066 journal latency) without a basis to interpret single-session timings.

**Changes:**

- `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` Execution table — relabeled the wall-clock row delta from "+2:15 (variance; same fixture)" to "+2:15 (host-load variance — see "System Load Context" below; deterministic Tester output unchanged)" to point readers at the new subsection.
- Same file — appended new "## System Load Context (informational — for wall-clock interpretation)" subsection before "## ✅ Empirical evidence captured (drains deferred-AC rows)". Captures: run start time + MT5 cache state (cold vs warm) + concurrent processes + free RAM + operator notes for batch-1 + batch-2; explicitly notes "not captured" for fields that weren't measured (honest about retrofit limit). Includes a "Methodology advisory for IMPL-065 + IMPL-066" subsection: (a) capture system-load snapshot at run start; (b) require ≥3 sessions per run + use median (not single value) for p99 attestation; (c) prefer EA-internal `GetMicrosecondCount()` instrumentation per tick over wall-clock outer loop. Becomes template for future Tier 1.5 walk artifacts (XS-15.2 — canonicalize in `.claude/rules/testing.md` when IMPL-065/066 land).

**Verification:**

- Subsection follows reviewer's suggested format verbatim (run-start time + cache state + concurrent processes + free RAM + notes columns).
- Template authoring pattern is now precedent for IMPL-065/066/067 result-table walk artifacts (XS-15.2 deferred but the template is in place).

**Commit:** `[docs:ea-qa] R15 15.4 walk-summary System Load Context subsection + IMPL-065/066 methodology advisory`

---

## Deferred (Phase-2 Backlog)

### XS-15.1 — Broader `inputs/` audit for discrete-set semantics

**Verdict:** Defer to Phase-2 backlog.

**Reasoning:** Reviewer cited `InpKMode` (Inputs_Slot_K.mqh) and `InpPSubMode` (Inputs_Slot_P.mqh) as candidate enum-as-int inputs — verified via grep that no input with these names exists. Inputs_Slot_K.mqh defines `InpEnableSlotK` (bool) + `InpKBaseLot/InpKSlPips/InpKTpProfitPips/InpKMaxOrders/InpKFICrossThreshHigh/InpKFICrossThreshLow/InpKFICrossAltHigh` (continuous numerics). Inputs_Slot_P.mqh defines `InpEnableSlotP/InpPMaxOrders/InpPBaseLot/InpPSlPipsFloor/InpPAdxMin/InpPForcePxGate/InpPDiffSlPxThreshold/InpPTpPipsPx/InpPTpPipsPh/InpPTpPipsE/InpPPyramidGatePips` — all continuous. `InpForceClearM/T/Q_Bars` + `InpMainRiskRatio` are already validated by Guards 1-39 in `ValidateInputs`. No other current input has discrete-set semantic.

**Future trigger:** if a Phase-2 IMPL-NNN ticket adds an enum-as-int input (e.g., a real `InpKMode` selector for AGGRESSIVE/DEFENSIVE/NONE), it lands in the new `ValidateSlotInputs()` umbrella — that's why the umbrella exists separately from `ValidateInputs`. The "Future per-slot discrete-set inputs land here" hook is documented inline.

### XS-15.2 — Canonicalize Result-Table fill pattern

**Verdict:** Defer to Phase-2 backlog.

**Reasoning:** R15 verified the `nfr-3.1-atomic-write-result.md § 5` ↔ sidecar JSON exact-match fill pattern works (8/8 fields). Canonicalizing it in `.claude/rules/testing.md` + `andm-impl-engineer/SKILL.md` is good methodology hygiene but not blocking — IMPL-065 (tick latency) / IMPL-066 (journal latency) / IMPL-067 (DST regression) are the natural triggers for the canonicalization (they will all need result-table-fill workflows). Fix-round-15 § 15.4 (System Load Context subsection in walk-summary) creates a precedent that the canonicalization can lift verbatim when the time comes.

**Future trigger:** open the canonicalization ticket alongside the first IMPL-065/066/067 task to author its result-table.

---

## Phase 5 Mechanical Gates Verified

> Per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` — fix-round closure inherits the same 9 gates as task closure for consistency.

| # | Gate | Result |
|---|------|--------|
| 1 | Forbidden-pattern grep on `docs/state/impl-plan.md` (`deferred per .* precedent\|deferred to operator-runtime\|structurally complete.*deferred\|live verification deferred`) | **0 hits ✅** |
| 4 | Sentinel counter increment | **N/A — fix-round (review-loop artifact, not task closure per fix-round-10 precedent + finding 15.3 itself)**; Sentinel section line 1778 unchanged at 6 |
| 5 | `overview.md` Last Updated date + status string append | **Updated:** Last Updated 2026-05-04 → 2026-05-05; status string appended fix-round-15 narrative |
| 9a | Originating finding 15.3 pattern grep on `docs/state/` (`walk drain.{0,30}within threshold\|7 closures.{0,30}walk drain`) | **0 hits ✅** |
| 9b | Broader-class grep `deferred to IMPL-053(\+\| \|\.\|$)` on `MQL5/Experts/PhoenicisNex` (R14 strengthened gate, holding) | **0 hits ✅** |

Gates 2 (TL;DR ↔ registry recount), 3 (TL;DR ↔ matrix denominator), 6-8 (file integrity / Phase Status Notes / narrative-section freshness) were re-checked manually as part of the impl-plan.md / current_handoff.md / overview.md edits. No drift detected (TL;DR Active counts unchanged at 47→43 + matrix denominators preserved + Phase Status Notes still reflect post-walk-batch-2 reality + Open Risks R-6 partial-mitigation note still accurate + Next Best Action top unchecked item = `/impl-review all` R09 unchanged).

---

## State Reconciliation 3-File Propagation

| Layer | File | Update |
|-------|------|--------|
| 1 (Primary SoT) | `docs/state/impl-plan.md` | TL;DR Sentinel 7→6 + citation; Next Best Action 7→6; Mid-Phase Audit Log new fix-round-15 row appended |
| 1 (Primary SoT) | `docs/state/deferred-ac-registry.md` | 4 partial-drain row annotations (IMPL-007 / IMPL-049 ×2 / IMPL-052) — registry remains authoritative for E-AC closure verification |
| 2 (Derived View) | `docs/state/overview.md` | Last Updated 2026-05-04 → 2026-05-05; Sentinel revert; status string appended fix-round-15 narrative |
| 3 (Transient Pointer) | `docs/state/current_handoff.md` | New "Last completed action" section prepended for fix-round-15; Sentinel revert at line 49 in the now-"Prior completed action" section |
| (Walk artifact) | `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` | System Load Context subsection appended + Execution table delta cell relabeled |

✅ All 3 layers updated atomically with this fix-round closure. No drift between layers.

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 4 + 2 XS |
| Accepted | 4 |
| Rejected | 0 |
| Partial | 0 |
| Deferred (Phase-2 backlog) | 2 XS |
| Source Files Modified | 3 (`core/BootstrapValidator.mqh` + `core/Orchestrator.mqh` + `inputs/Inputs_Slot_S.mqh`) |
| State/Doc Files Modified | 4 (`deferred-ac-registry.md` + `impl-plan.md` + `overview.md` + `walk-summary.md`) |
| Tests Added/Updated | 0 (defense-in-depth validator covered by existing 4-gate DoD; test-add deferred to walk batch-3 invalid-input fixture if needed) |
| G1 Compile | PASS — 0 errors, 0 warnings, 3844 ms |
| Plan Staleness Sentinel | 6 closures since R07 unchanged (review-round + fix-round = review-loop artifacts; not counted) |
| Commits | 4 (one per finding) |

**Recommendation:** Ready for next review round (R16 trigger after IMPL-062 lands and produces 5-yr journal records — that's when the IMPL-062-gated deferred-AC rows can drain) **OR** ready for Red Team / `/impl-review all` R09 (cumulative attack surface across cross-slot + Orchestrator + entry .mq5 + 2 FIX commits + 3 QA pipeline + walk batch-2 evidence + R15 defense-in-depth still motivates the cumulative sweep).

**Next sequence:**
1. `/impl-review all` R09 (recommended pre-batch defect catch).
2. Start IMPL-062 (Bucket A regression — IMPL-061 baseline ✅ unblocked) to begin draining the IMPL-068 5-yr regression bundle + 24 P3 slot 60-day deferrals + the 3 partial-drain registry rows annotated by R15 § 15.2 before the 2026-05-17/18 expiry cycle.
