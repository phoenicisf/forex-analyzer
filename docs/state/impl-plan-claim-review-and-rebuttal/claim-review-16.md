# Implementation Plan Claim Review Round 16

| Field | Value |
|-------|-------|
| **Round** | 16 |
| **Target** | `docs/state/impl-plan.md` (+ state-reconciliation siblings) |
| **Date** | 2026-05-18 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R15 (2026-05-18) — 12/12 Accept; BT-002 cascade drain across 11+ impl-plan surfaces (mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event boundary). IMPL-FIX-012 → close-by-BT-002 supersession + IMPL-051 → cancel-by-BT-002 + ADR-013/014 Superseded annotations propagated. Rebuttal-15 predicted "Routine verify-only R16 round" (mirror R12→R13→R14 verify-pass chain after R11 BT-001 drain). |
| **Trigger** | Operator invoked `/impl-plan-review all` immediately after R15 rebuttal commit. Scope: verify R15 BT-002 cascade drain landed cleanly across all 11+ enumerated surfaces + sweep for residual cascade-completion gaps that R15 did not cover (mirror R12 verify-pass cycle after R11 BT-001 cascade drain). |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL 0 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 1)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (`deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **1 sanctioned false-positive** ✅ — single hit at L27 (IMPL-FIX-011d Phase 1 audit-log row, regex `.*` greediness matching `"deferred per registry row"` + later `"fix-round-10 precedent"` in same narrative). Down from 2 in R15 — R15 §15.11 Closure Hygiene Status rewrite closed the second self-reference at L2349 per fix-round-26 §Finding 26.6 lesson. **0 real hits** on `[x]` AC closure lines.
- **Forward refs (P_n → P_m, m>n):** **0 edges** ✅. Sub-ticket↔parent convention (R09 §09.5 + R11 §11.1) preserved across BT-002 task closure pivots (IMPL-FIX-012 close-by-supersession + IMPL-051 cancel-by-BT-002 do not introduce forward refs).
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013 P4→P3 Service-coupling diverge), V=0, N=0 — **Not triggered** ✅ (D ≥ 1; SD Hint Alignment scratch table L2264-L2337 in place; BT-002 cascade did not introduce new task or reclassify any task's hint alignment).
- **State reconciliation (4-way):** ✅ **Primary inversion gap CLOSED** — `grep -c '\bBT-002\b'` on `impl-plan.md` = **28 hits** vs `overview.md` = 10 + `backtrack-log.md` = 7 + `CLAUDE.md` = 8 (R15 §15.1 originating defect class drained). Registry recount per Gate #2: 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = **55 Active rows** + **8 Resolved rows** ✅ matches TL;DR L100 claim exactly (R14 §14.1 + fix-round-26 +1 P5 row + R15 IMPL-FIX-013 sync preserved). **3 residual reconciliation gaps surface** at finer-granularity layers (next-finer-granularity sweep pattern per R20→R23 chain documented in workflow.md): (a) IMPL-051 task block E-AC L903 + Risk L905 + ADR L906 pre-BT-002 framing not symmetrically annotated alongside L897/L909 (Claim 16.1); (b) P4 Phase Gate Tier 1.5 Exploratory Walk row L1412 instruction (3) still cites "manually trigger CircuitBreaker via stub" (Claim 16.2); (c) `current_handoff.md` L7 `Last completed action` anchor stale at "2026-05-17 BT-002 SD rework APPLIED" pre-cascade-closure (Claim 16.3).

### Top 3 to Fix First

1. **Claim 16.1** 🟠 — **IMPL-051 task block intra-block asymmetry post-BT-002 cascade** — L897 Input field + L909 Cancelled-by-BT-002 row are properly drained per R15 §15.7 fix, but L903 E-AC stays `[ ]` deferred with stale annotation referencing CircuitBreaker live-wiring at IMPL-052/053+ + ADR-010 design (CircuitBreaker entry removed from halt-trigger list per backtrack-log L55). Symmetric to R15 §15.8 IMPL-FIX-012 E-AC supersession flip — same architectural decision (Option 1 legacy-parity; remove BR-3.6 detector) applies to both task siblings but R15 fix landed only at IMPL-FIX-012 layer. Also L905 Risk field `medium (G4 safety net)` reads canonical-current without post-BT-002 annotation that the "G4 safety net" capability is removed; L906 ADR field cites ADR-010 without amendment annotation.

2. **Claim 16.2** 🟠 — **P4 Phase Gate L1412 Tier 1.5 Exploratory Walk row instruction (3) `"halt paths trigger correctly (manually trigger CircuitBreaker via stub; manually trigger journal sustained-fail)"`** carries pre-BT-002 acceptance-path framing — operator following the walk script would attempt to manually trigger a removed mechanism (CircuitBreaker.mqh slated for deletion per backtrack-log L65 + cleanup commits pending). Phase Gate testable-exit text should reflect post-BT-002 acceptance path (CircuitBreaker reference removed; halt paths reduced to journal sustained-fail + handle-invalid + future Phase 2 triggers per ADR-010 amended).

3. **Claim 16.3** 🟠 — **`current_handoff.md` L7 `Last completed action` stale at "BT-002 SD rework APPLIED 2026-05-17"** — anchor predates SD Round 09 closure (2026-05-17), BA Round 06 + rebuttal-05 closure (2026-05-18), BT-002 ✅ CLOSED (2026-05-18), and R15 impl-plan rebuttal closure (2026-05-18). State Reconciliation 3-file rule analog at handoff layer — R15 §15.1 originating defect class drained at primary SoT but NOT propagated to third tier (per CLAUDE.md §6 "ทั้ง 3 ชั้น: (1) `impl-plan.md` (primary SoT), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*`"). Engineer reading handoff after R15 closure sees handoff frozen at pre-cascade-closure framing.

### Verdict

- [ ] ✅ **Ready for Implementation Execution** — 3 HIGH state-reconciliation gaps surface at next-finer-granularity layers requiring rebuttal-pass for canonical closure
- [x] ⚠️ **Needs Rebuttal Round** — 3 HIGH (cascade-completion residue at task-block + Phase Gate + handoff layers) + 2 MEDIUM (audit-trail readability) + 1 LOW (line-anchor cite drift). Run `/impl-plan-rebuttal claim-review-16.md`. Mirror R12 verify-pass after R11 BT-001 drain at BT-002 cascade boundary. Expected ~10-15 in-place edits (~50-100 LOC narrative); no AC content changes beyond IMPL-051 E-AC `[ ]` → `[x] Superseded by BT-002` flip; no task splits; one task-block status-row reorder (IMPL-FIX-012 chronological re-sort).
- [ ] ⛔ **Immediate Attention** — no fundamental scope flaw; all R16 findings are cascade-residue cleanup at sub-task / sub-section granularity

> **Rebuttal scope guidance:** Apply symmetric R15 §15.8 closure pattern to IMPL-051 sibling — flip E-AC L903 `[ ]` → `[x] Superseded by BT-002` with strikethrough preserving original assertion + supersession annotation citing ADR-010 amendment + impl-code cleanup pending (Claim 16.1). Rewrite P4 Phase Gate L1412 walk instruction (3) to remove "manually trigger CircuitBreaker via stub" + cite ADR-010 amended halt-trigger list (Claim 16.2). Update `current_handoff.md` L7 `Last completed action` to canonical-current anchor R15 rebuttal closure + BT-002 ✅ CLOSED + cascade chain summary (Claim 16.3). Reorder IMPL-FIX-012 Status entries L1988/L1990/L1992 chronologically (Claim 16.4). Annotate IMPL-051 Risk L905 + ADR L906 with post-BT-002 footnote mirror L898 Input pattern (Claim 16.5). Re-anchor Mid-Phase Audit Log L2253 cite from `Status L1986` (off-by-2 post-R15 LOC shift) to grep-stable symbolic anchor `Status (iter-3 — Run #5 EXECUTED 2026-05-17)` (Claim 16.6). Likely 6/6 Accept verify-pass pattern (no rejected claims expected; all are cascade-residue closures).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Phase shape unchanged since R01–R15; rationale + Phase % targets ครบ; BT-002 cascade did not affect Phase Shape Choice |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean (H=68, A=67, D=1, V=0, N=0); confirmation note + scratch table L2264-L2337 preserved; BT-002 cascade did not change Evolution Sequence or hint classifications |
| 3 | Task Decomposition & Sizing | ✅ Pass | No changes from R15; IMPL-051 + IMPL-FIX-012 task-block annotations preserve Phase × Size matrix denominator per audit-history discipline |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 16.1 | IMPL-051 E-AC L903 still `[ ]` deferred with stale annotation referencing CircuitBreaker live-wiring at IMPL-052/053+ + ADR-010 design that has been amended (CircuitBreaker removed from halt-trigger list); symmetric to R15 §15.8 IMPL-FIX-012 E-AC supersession flip but NOT applied to IMPL-051 sibling |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 16.2 | P4 Phase Gate L1412 Tier 1.5 Exploratory Walk row instruction (3) carries pre-BT-002 framing `"halt paths trigger correctly (manually trigger CircuitBreaker via stub; manually trigger journal sustained-fail)"`; operator following script attempts manual trigger of removed mechanism. R15 §15.6 fix landed at L1411 Empirical Demo + L1416 NFR-1.1 sub-row but did NOT reach L1412 Tier 1.5 Walk row |
| 6 | Deferred-AC Registry Init | ✅ Pass | Registry empirical recount (Gate #2): 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = **55 Active rows** ✅ matches TL;DR L100 + **8 Resolved rows** ✅ matches L100 claim; R14 fix held + fix-round-26 +1 P5 row + R15 IMPL-FIX-013 row appended in sync |
| 7 | Cross-Phase Dependency | ✅ Pass | 0 forward refs; sub-ticket↔parent convention preserved; Mermaid Phase × Size matrix unchanged; IMPL-051 cancel-by-BT-002 + IMPL-FIX-012 close-by-supersession do not remove from matrix denominator (audit-history discipline per R10 §10.6) |
| 8 | State-File Consistency | ⚠️ Findings 16.1 + 16.3 + 16.5 + 16.6 | Primary BT-002 cascade drain CLOSED at impl-plan.md vs overview.md/backtrack-log.md/CLAUDE.md inversion gap; 3 residual surface gaps: (a) IMPL-051 intra-block fields (16.1) — task-block reads canonical-current at Risk/ADR fields without post-BT-002 footnote; (b) current_handoff.md L7 anchor stale (16.3) — third tier of 3-file rule not propagated; (c) Mid-Phase Audit Log L2253 cite-by-line-number drift (16.6) — analogous to R22-R23 line-anchor brittleness defect class at audit-log-internal layer |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4/month-year schedule leakage in SD-hint copies; absolute dates (2026-05-17/18) are working-paper-dates allowed per R10 disposition + BT-001/BT-002 cascade precedent |
| 10 | Readability — Reader Empathy | ⚠️ Findings 16.2 + 16.4 | P4 Phase Gate L1412 walk instruction misleads operator on acceptance path (Dim #5 cross-layer); IMPL-FIX-012 Status entries L1988/L1990/L1992 chronologically out-of-order per R15 §15.8 problem #4 explicit-but-unfixed (Dim #10 audit-trail readability) |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🟠 HIGH

#### Claim 16.1: 🟠 HIGH — `impl-plan.md` IMPL-051 task block intra-block asymmetry post-BT-002 cascade — L903 E-AC stays `[ ]` deferred with stale annotation referencing CircuitBreaker live-wiring at IMPL-052/053+ + ADR-010 design (CircuitBreaker entry removed from halt-trigger list per backtrack-log L55); symmetric to R15 §15.8 IMPL-FIX-012 E-AC supersession flip but NOT applied to IMPL-051 sibling task; also L905 Risk + L906 ADR fields pre-BT-002 framing without post-BT-002 footnote (mirror L898 Input pattern)

**Location:** `docs/state/impl-plan.md` IMPL-051 task block L893-L909:
- L903 E-AC: `"- [ ] Smoke: stub portfolio with 3 close events 1500ms apart → CheckPingPong returns true → EAState transitions HALTED [log-assertion] — partial: SelfTest Case A structurally validates 1500s detection + ErrorBypassThrottle emission; EAState halt transition deferred to IMPL-052 (EAState class) + IMPL-053+ Orchestrator wiring per ADR-010 design (CircuitBreaker emits + returns true; Orchestrator owns SetHalted call)"`
- L905 Risk: `"- **Risk**: medium (G4 safety net)"`
- L906 ADR: `"- **ADR**: ADR-010"`
- L897 Input + L898 Input annotation + L909 Cancelled-by-BT-002 row ✅ properly drained per R15 §15.7

**Problem:**

R15 §15.7 fix landed the IMPL-051 cancel-by-BT-002 annotation at L897 Input + L909 Closed-line companion row. BUT the same architectural decision (BT-002 closure removed BR-3.6 detector entirely; ADR-010 amended; CircuitBreaker.mqh slated for deletion) also makes the L903 E-AC structurally invalid:

- E-AC assertion: `CheckPingPong returns true → EAState transitions HALTED [log-assertion]`
- Post-BT-002 reality: `CheckPingPong` method + `services/CircuitBreaker.mqh` slated for DELETE per backtrack-log L65; ADR-010 halt-trigger list amended (CircuitBreaker removed per backtrack-log L55); the verification path is structurally impossible
- E-AC deferral annotation: `"EAState halt transition deferred to IMPL-052 (EAState class) + IMPL-053+ Orchestrator wiring per ADR-010 design (CircuitBreaker emits + returns true; Orchestrator owns SetHalted call)"` — references **ADR-010 design** that has been amended (CircuitBreaker removed) + **IMPL-052/053+ Orchestrator wiring** that won't materialize for CircuitBreaker (no `CheckPingPong` call to wire post-cleanup)

Per R15 §15.8 fix at IMPL-FIX-012 sibling — same defect class — E-AC #1 + #2 flipped `[ ]` → `[x]` with strikethrough + `**Superseded by BT-002 2026-05-18** annotation` per R10 §10.6 + R11 §11.1 strikethrough-append precedent. The IMPL-051 E-AC at L903 needs the same flip. Cascade-completion asymmetry — R15 fix scope explicitly covered IMPL-FIX-012 but NOT IMPL-051 sibling.

Additionally:
- L905 Risk `medium (G4 safety net)` — pre-BT-002 framing; the "G4 safety net" capability is being removed (BT-002 = remove BR-3.6 detector); reader inferring canonical-current risk classification mis-infers the safety net is still operational
- L906 ADR `ADR-010` — cites ADR-010 without amendment annotation (per backtrack-log L55: `ADR-010 § Trigger sources (line ~19) — CircuitBreaker removed from halt-trigger list; HALTED state machine remains for handle-invalid + future Phase 2 triggers`); R15 §15.7 fix added L898 Input annotation referencing `ADR-010 amended (CircuitBreaker entry removed from halt-trigger list per L55)` — same annotation should mirror to L906 ADR field

**Why this matters:**

1. **Engineer running `/impl-task IMPL-051` or `/impl-review IMPL-051`** would see `[ ]` E-AC with deferral note pointing to IMPL-052/053+ wiring path that won't exist post-impl-code cleanup; could attempt to wire `CheckPingPong` → `EAState::SetHalted` at IMPL-053+ Orchestrator only to find `services/CircuitBreaker.mqh` already deleted; cascade-completion asymmetry between IMPL-FIX-012 (closed-by-supersession) and IMPL-051 (cancel-by-BT-002 annotated but E-AC still pending) is structurally inconsistent

2. **`/deliver` final readiness check** reads each task block's `[x]`/`[ ]` AC status as canonical structural-acceptance signal; IMPL-051 with `[ ]` E-AC + cancel-by-BT-002 annotation produces ambiguous Phase 5 readiness signal (is the task pending E-AC drain OR cancel-by-supersession?); R15 §15.8 closure pattern at IMPL-FIX-012 produces unambiguous `[x] Superseded` signal — same disambiguation needed at IMPL-051

3. **Reader-side decision-tree (Dim #4 + Dim #8 cross-layer)** — Tech Lead / PM reading IMPL-051 block sees `Closed: 2026-05-03` + `Cancelled-by-BT-002 2026-05-18` + `[ ] E-AC deferred to IMPL-052/053+` — the three states are internally contradictory (closed AND cancelled AND pending E-AC drain). Reader cannot resolve canonical status without cross-referencing backtrack-log § BT-002 § Impacted phases Impl Code L65 (impl-code cleanup checklist). The IMPL-FIX-012 task-block resolves all three states consistently: `Closed-by-supersession 2026-05-18 + [x] E-AC Superseded` (R15 §15.8 fix). IMPL-051 needs same resolution.

**Minimum acceptable fix:**

L903 E-AC checkbox flip + annotation append (mirror R15 §15.8 fix for IMPL-FIX-012 E-AC #1):

```markdown
- [x] ~~Smoke: stub portfolio with 3 close events 1500ms apart → `CheckPingPong` returns true → EAState transitions HALTED `[log-assertion]` — **partial: SelfTest Case A structurally validates 1500s detection + ErrorBypassThrottle emission**; EAState halt transition deferred to IMPL-052 (EAState class) + IMPL-053+ Orchestrator wiring per ADR-010 design (CircuitBreaker emits + returns true; Orchestrator owns SetHalted call)~~ **— Superseded by BT-002 2026-05-18:** per `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65 — `services/CircuitBreaker.mqh` DELETE pending impl-code cleanup; `CheckPingPong` method removed entirely; the E-AC verification path is structurally impossible by construction once cleanup commits land. ADR-010 halt-trigger list amended (CircuitBreaker removed; HALTED state machine remains for handle-invalid + Phase 2 future triggers per backtrack-log L55); `EAState::SetHalted` no longer wires CircuitBreaker as halt source. SelfTest Case A structural validation preserved as audit history (Case A demonstrated implementation correctness at 2026-05-03 closure — empirical attestation that IMPL-051 work was performed correctly; supersession reflects BT-002 architectural decision not defect in IMPL-051 work). Audit history preserved per R10 §10.6 + R11 §11.1 strikethrough-append precedent + R15 §15.8 IMPL-FIX-012 sibling-task closure pattern.
```

L905 Risk field append:

```markdown
- **Risk**: medium (G4 safety net) — **BT-002 status update 2026-05-18:** "G4 safety net" capability removed per Option 1 legacy-parity (remove BR-3.6 detector); empirical legacy proof per `backtrack-log.md § BT-002 § Reason` (PhoenicisN2.10_stable.mq5 achieves $24.27M baseline without ping-pong detector → safety capability not load-bearing for EA's known trading pattern set). Risk post-BT-002 = N/A (capability removed; HALTED state machine remains for handle-invalid + future Phase 2 triggers per ADR-010 amended)
```

L906 ADR field append (mirror L898 Input pattern):

```markdown
- **ADR**: ADR-010 — **BT-002 status update 2026-05-18:** ADR-010 amended per backtrack-log L55 (`§ Trigger sources line ~19 — CircuitBreaker removed from halt-trigger list; HALTED state machine remains for handle-invalid + future Phase 2 triggers`); audit history preserved (revision history entry added at ADR-010 per BT-002 SD cascade commit `0be2a51`)
```

**Effort:** Low (1 E-AC flip + 2 field annotation appends preserving all prior content; ~30-40 LOC narrative; mirror R15 §15.8 IMPL-FIX-012 closure pattern at sibling task layer).

---

#### Claim 16.2: 🟠 HIGH — `impl-plan.md` L1412 P4 Phase Gate Tier 1.5 Exploratory Walk row instruction (3) `"halt paths trigger correctly (manually trigger CircuitBreaker via stub; manually trigger journal sustained-fail)"` carries pre-BT-002 acceptance-path framing — operator following the walk script would attempt to manually trigger a removed mechanism (`services/CircuitBreaker.mqh` slated for DELETE per backtrack-log L65); Phase Gate testable-exit text must reflect post-BT-002 acceptance path; R15 §15.6 fix landed at L1411 Empirical Demo + L1416 NFR-1.1 sub-row but did NOT propagate to L1412 Tier 1.5 Walk row

**Location:** `docs/state/impl-plan.md` L1412 (P4 Phase Gate Tier 1.5 Exploratory Walk row):

`"- [ ] **Tier 1.5 Exploratory Walk:** 30-min walk on full 21-slot EA — multiple Strategy Tester runs (60-day, 1-yr, 5-yr) — verify (1) journal records validate against schema sample 5+, (2) state.json sanity (17 slot_states populated, 11 sub-objects per schema), (3) halt paths trigger correctly (manually trigger CircuitBreaker via stub; manually trigger journal sustained-fail), (4) force-clear paths trigger on stale Pending payloads, (5) DST transitions (Mar 28 + Oct 25 in test years) handled correctly per NFR-7.3, (6) atomic-write integrity under simulated kill 100x (NFR-3.1), (7) cold-bootstrap from empty state.json restores defaults per [ev=state_corrupt_starting_fresh]. Artifact: docs/state/_session-handoff/<TBD-phase4-exploratory-walk>.md..."`

**Problem:**

Phase Gate testable-exit row reads canonical-current at instruction (3): operator should `"manually trigger CircuitBreaker via stub"` as one of the halt-path verification steps. Post-BT-002 closure (2026-05-18):

- CircuitBreaker mechanism reverted entirely (Option 1 legacy-parity per `backtrack-log.md § BT-002 § Resolution` L71)
- `services/CircuitBreaker.mqh` slated for DELETE per `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65
- ADR-010 halt-trigger list amended — `"CircuitBreaker removed from halt-trigger list; HALTED state machine remains for handle-invalid + future Phase 2 triggers"` (per backtrack-log L55)
- Halt paths reduced to: (a) journal sustained-fail (BR-3.4) + (b) handle-invalid (NFR-3.2 fail-fast) + (c) future Phase 2 triggers (equity-floor, etc. — TBD)

Operator following the walk script at Phase Gate close would attempt to `"manually trigger CircuitBreaker via stub"` only to find `services/CircuitBreaker.mqh` deleted and no `CheckPingPong` method available — walk artifact would be incomplete OR operator would generate a false-positive walk PASS by skipping the now-impossible step without documenting why.

Per workflow.md § Phase 5 Closure mechanical gates + Phase Gate testable-exit discipline (Dim #5) + R15 §15.6 fix pattern at L1411 Empirical Demo (which already drained the pre-BT-002 "Run #4 retry" framing): the Tier 1.5 Walk row needs analogous refresh. R15 §15.6 fix scope explicitly covered L1411 + L1416 NFR-1.1 sub-row but did NOT propagate to L1412 Tier 1.5 Walk row. This is the **same defect class** at Phase Gate row layer — pre-BT-002 acceptance-path framing surviving R15 fix narrow scope.

**Why this matters:**

1. **Phase Gate testable-exit clarity (Dim #5)** — operator running Phase Gate close per L1412 reads instruction (3) as canonical-acceptance step → attempts manual CircuitBreaker trigger → finds method removed → either (a) skips silently (walk artifact incomplete; Phase Gate close blocked) OR (b) modifies walk script to "skip step 3 because CircuitBreaker removed" (walk artifact passes but is structurally inconsistent with the original acceptance criterion as written)

2. **Same defect class as R15 §15.6 fix at L1411 Empirical Demo** — pre-BT-002 framing surviving narrow rebuttal scope. R15 §15.6 fix landed Empirical Demo + NFR-1.1 sub-row appends but the Tier 1.5 Walk row at L1412 (next row down in the same Phase Gate block) was not in scope. Next-finer-granularity sweep pattern per R20→R23 chain — fix scope narrower than defect class footprint.

3. **Reader-side decision-tree (Dim #5 + Dim #10 cross-layer)** — Tech Lead reading P4 Phase Gate block sees L1411 Empirical Demo properly drained (post-BT-002 framing with Run #6 on no-detector build acceptance path), but L1412 still cites manually-triggered CircuitBreaker — internally inconsistent within the same Phase Gate block

**Minimum acceptable fix:**

L1412 instruction (3) rewrite — replace `"halt paths trigger correctly (manually trigger CircuitBreaker via stub; manually trigger journal sustained-fail)"` with:

```markdown
halt paths trigger correctly per **ADR-010 amended halt-trigger list (post-BT-002 cascade closure 2026-05-18)**: (a) manually trigger journal sustained-fail (BR-3.4; 10 consecutive `FileWriteString` failures → `Logger.Error [ev=journal_halt][reason=write_fail_sustained]` + `EAState::SetHalted`); (b) manually trigger indicator-handle-invalid (NFR-3.2; force one of ~25 handles to return `INVALID_HANDLE` in OnInit → fail-fast `EAState::SetHalted` + Alert popup); (c) ~~manually trigger CircuitBreaker via stub~~ **SUPERSEDED by BT-002 2026-05-18 — `services/CircuitBreaker.mqh` deleted per impl-code cleanup (`backtrack-log.md § BT-002 § Impacted phases Impl Code` L65); BR-3.6 demoted Won't at BA; FR-6.6 demoted; halt paths reduced to (a)+(b)+future Phase 2 triggers per ADR-010 § Trigger sources amended (per backtrack-log L55).** Empirical proof safety capability not load-bearing: legacy `PhoenicisN2.10_stable.mq5` achieves $24.27M baseline without ping-pong detector per BT-002 § Reason)
```

**Effort:** Low (1 in-place instruction-(3) rewrite; ~20-30 LOC narrative; preserves walk artifact filename placeholder + walk discipline; cleanly removes CircuitBreaker manual-trigger step).

---

#### Claim 16.3: 🟠 HIGH — `current_handoff.md` L7 `Last completed action` anchor stale at `"🟢 BT-002 SD rework APPLIED 2026-05-17"` — anchor predates SD Round 09 closure (2026-05-17), BA Round 06 + rebuttal-05 closure (2026-05-18), BT-002 ✅ CLOSED (2026-05-18), and R15 impl-plan rebuttal closure (2026-05-18); third tier of State Reconciliation 3-file rule (CLAUDE.md §6) not propagated post-R15 rebuttal commit — same defect class as R15 §15.1 originating inversion gap but at handoff layer

**Location:** `docs/state/current_handoff.md` L5-L7 (Last completed action block):

- L5: `"## Last completed action"`
- L7: `"**🟢 BT-002 SD rework APPLIED 2026-05-17 — Option 1 legacy-parity (remove BR-3.6 CircuitBreaker ping-pong detector) cascade across SD package, ADRs, and API spec. Status: ready for /sd-review all re-validation. Triggered by /next Navigation Decision Layer §1.9.1 priority #2 (Open backtrack BT-002) recommendation + operator "proceed recommended" approval.**"`

**Problem:**

Per CLAUDE.md §6 State Reconciliation Discipline (`State Reconciliation 3-file rule`):

> "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal → propagate state 3 ชั้น: (1) `impl-plan.md` (primary), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*`. ห้าม update เพียงไฟล์เดียว"

R15 rebuttal claimed "**State Reconciliation 3-file rule (CLAUDE.md §6) restored at primary SoT layer**" (per claim-review-15.md § At-a-Glance + Closure Hygiene Status L2363). The drain landed:
- Tier 1 (`impl-plan.md`): ✅ 28 BT-002 hits — fully propagated
- Tier 2 (`overview.md`): ✅ already canonical-current per BT-002 SD cascade (row 19 narrative)
- **Tier 3 (`current_handoff.md`): ❌ NOT propagated** — L7 anchor frozen at "2026-05-17 BT-002 SD rework APPLIED" which is the **pre-cascade-closure** state

Canonical post-2026-05-17 events that current_handoff.md L7 misses:
- 2026-05-17 SD Round 09 verify-only 0 findings ✅ (commit `e385ad0`)
- 2026-05-17 fix-round-26 ✅ CLOSED
- 2026-05-18 BA Round 06 + rebuttal-05 1 LOW closed (commit `863493e`)
- 2026-05-18 BT-002 ✅ CLOSED (Status flipped in backtrack-log L69 + Resolution populated L71)
- 2026-05-18 commit `7ff6f43` `/project-init --regen` (CLAUDE.md + 4× rules regenerated per BT-002 TD/SD cascade + user remark 2026-05-18)
- 2026-05-18 commit `47381a9` path modernization `.agents/` → `.andm/`
- 2026-05-18 R15 `/impl-plan-rebuttal claim-review-15.md` ✅ 12/12 Accept

R15 §15.1 Why-this-matters paragraph #3 enumerated reader-side impact classes — all apply to `current_handoff.md` reader as well:
- Engineer running `/impl-task` reads handoff first per CLAUDE.md §6 Agent Workflow Rules
- `/next` Check 5.7 reads handoff for backlog context
- Status agent rendering dashboard reads handoff "Last completed action" as canonical first-impression signal

The R15 fix for the originating defect class did not extend to handoff propagation — third tier of the 3-file rule. Same primary-SoT-inversion-gap pattern (R15 §15.1) recurring at next-finer derived-view layer (handoff is downstream-derived from impl-plan; per CLAUDE.md §6 State SoT discipline, handoff is "transient pointer + artifact" derived from primary SoT impl-plan.md).

**Why this matters:**

1. **State Reconciliation 3-file rule violation** (CLAUDE.md §6 explicit) — same defect class as R15 §15.1 originating gap but at next-tier-down layer; R15 closure narrative claimed 3-file rule restored but only addressed tiers 1+2

2. **Engineer reading handoff at session start** (per CLAUDE.md §6 Agent Workflow Rules: "เริ่มงาน: อ่าน CLAUDE.md → อ่าน handoff → ทำงาน") sees pre-BT-002-closure framing → infers BT-002 SD cascade is awaiting `/sd-review all` re-validation (per L7 `"Status: ready for /sd-review all re-validation"`) → wastes cycles re-running already-closed reviews OR dispatches workflow per stale priority

3. **Same recurring weakness pattern as R12 → R13 → R14 → R15 chain** at handoff-derived-view layer — each backtrack event needs cascade drain across **all 3 tiers** of state reconciliation; R15 closed tiers 1+2 but missed tier 3. R16 catches the residual

**Minimum acceptable fix:**

`current_handoff.md` L7 rewrite — replace lead clause with canonical-current anchor (preserve subsequent narrative + table verbatim per R10 §10.6 strikethrough-append discipline):

```markdown
**🟢 BT-002 ✅ CLOSED 2026-05-18 — Option 1 legacy-parity (remove BR-3.6 CircuitBreaker ping-pong detector) cascade FULLY DRAINED across BA + SD + impl-plan packages.** Resolution per `backtrack-log.md § BT-002 § Status` L69 + § Resolution L71: SD-side cascade CLOSED via 3-round chain — Round 07 (7 findings) → rebuttal-05 (7 accept commit `111f092`) → Round 08 (2 findings) → rebuttal-06 (2 accept commit `32c56c0`) → Round 09 verify-only 0 findings ✅ (commit `e385ad0`); BA-side cascade CLOSED via 1-cycle chain — BA cascade applied (commit `863493e`) → Round 06 (1 LOW cosmetic) → rebuttal-05 (1 accept). impl-plan-side cascade drain CLOSED via R15 12/12 Accept (commit pending — this rebuttal) — IMPL-FIX-012 → close-by-BT-002 supersession + IMPL-051 → cancel-by-BT-002 + 11+ surface BT-002 propagation. **Pending downstream cascade (out of impl-plan-rebuttal scope):** (a) TD review `/td-review all` — TD-02 §5.8 CCircuitBreaker class skeleton DELETE + 10 cross-refs cleanup; (b) impl-code BT-002 cleanup ~1-2 hr single session — DELETE `services/CircuitBreaker.mqh` + strip dispatch + remove HALT_PINGPONG + G1+G2+G3 re-run; (c) IMPL-062 re-execute Bucket A 5-yr regression on rewrite-no-detector default build (NFR-1.1 acceptance signal). Triggered by `/next` Navigation Decision Layer §1.9.1 priority #2 (Open backtrack BT-002) recommendation + operator "proceed recommended" approval 2026-05-17; chained R15 impl-plan-review trigger 2026-05-18.

**Prior completed action (preserved for audit per R10 §10.6):** ~~**🟢 BT-002 SD rework APPLIED 2026-05-17** — Option 1 legacy-parity (remove BR-3.6 CircuitBreaker ping-pong detector) cascade across SD package, ADRs, and API spec. Status: ready for /sd-review all re-validation. Triggered by /next Navigation Decision Layer §1.9.1 priority #2 (Open backtrack BT-002) recommendation + operator "proceed recommended" approval.~~ ✅ closed via SD Round 09 + BA Round 06 + rebuttal cascade chain enumerated above.
```

**Effort:** Low (1 lead-block rewrite preserving all prior narrative + table verbatim per strikethrough-append discipline; ~30-50 LOC narrative).

---

### 🟡 MEDIUM

#### Claim 16.4: 🟡 MEDIUM — `impl-plan.md` IMPL-FIX-012 task block L1986-L1994 Status entries chronologically out-of-order — correct chronological order: L1986 iter-1 (2026-05-14) → L1992 iter-2 (2026-05-17) → L1990 iter-3 PATCH (2026-05-17) → L1988 iter-3 close (2026-05-17) → L1994 close-by-BT-002 (2026-05-18); R15 §15.8 Problem #4 explicitly noted this out-of-order issue but rebuttal-15 §15.8 fix only added new L1994 Status row without reordering prior L1988/L1990/L1992; audit-trail readability + Gate #7 Phase Status Notes-sweep analog at task-block layer

**Location:** `docs/state/impl-plan.md` IMPL-FIX-012 Status entries L1986-L1994:
- L1986: `Status (iter-1 close, this commit 2026-05-14)` — chronological position 1 ✅
- L1988: `Status (iter-3 — Run #5 EXECUTED 2026-05-17, ADR-014 INSUFFICIENT...)` — chronological position 4 (should come after iter-3 PATCH)
- L1990: `Status (iter-3 PATCH — ADR-014 LANDED 2026-05-17, awaiting G3 5-yr Run #5)` — chronological position 3 (should come before iter-3 close)
- L1992: `Status (iter-2 — Run #4 EXECUTED 2026-05-17, E-AC #1 NOT MET)` — chronological position 2 (should come before iter-3 PATCH)
- L1994: `Status (close-by-BT-002 supersession 2026-05-18)` — chronological position 5 ✅

**Problem:**

Per claim-review-15.md § Claim 15.8 Problem #4 (verbatim):

> "**Status entries L1986 + L1988 + L1990 are out-of-chronological-order** (iter-3 closure listed before iter-3 PATCH and iter-2). Audit-trail readers expect chronological order. (Note: this is a separate Gate #7 Phase Status Snapshot Notes-sweep-class defect at task-block layer.)"

Reviewer R15 explicitly identified the chronological-order issue as a separate Gate #7 analog finding at task-block layer. The rebuttal-15 §15.8 fix sequence (per rebuttal narrative):

> "(a) E-AC #1 L1976 flipped... (b) E-AC #2 L1977 flipped... (c) ADR field L1981 appended... (d) **New Status row appended after iter-2 Status (L1992)** as `Status (close-by-BT-002 supersession 2026-05-18)`..."

The rebuttal added L1994 (close-by-BT-002 supersession) after L1992 (iter-2) — chronologically correct position for the NEW row — but did NOT reorder the prior L1988 + L1990 + L1992 entries. The pre-existing chronological mismatch (iter-3 close at L1988 before iter-3 PATCH at L1990 before iter-2 close at L1992) survives the R15 rebuttal commit.

Correct chronological order (post-R16 fix):
1. L1986: iter-1 close 2026-05-14
2. L1992 → new L1988: iter-2 close 2026-05-17 (Run #4 ❌)
3. L1990 → new L1990: iter-3 PATCH 2026-05-17 (ADR-014 LANDED awaiting Run #5)
4. L1988 → new L1992: iter-3 close 2026-05-17 (Run #5 ❌)
5. L1994: close-by-BT-002 2026-05-18

Reorder cost = swap 3 rows (L1988↔L1992 + verify L1990 stays middle); content unchanged.

**Why this matters:**

1. **Audit-trail readability** (Dim #10 reader empathy) — engineer reading IMPL-FIX-012 chronologically encounters iter-3 close BEFORE iter-3 PATCH BEFORE iter-2 close; inverts the actual cap-3 sequencing narrative (iter-1 → iter-2 → iter-3); confuses the iter-N → iter-N+1 dependency chain that the cap-3 budget protocol enforces

2. **MEDIUM not HIGH** because: (a) task-block IS canonical-closed via L1994 supersession row at correct position; (b) chronological-order is readability concern not content correctness; (c) all 4 Status entries are preserved verbatim per audit-trail discipline — reorder = layout change only; (d) Gate #7 Phase Status Notes-sweep analog → MEDIUM disposition per workflow.md Phase 5 Gate #7 severity rubric

3. **Recurring Weakness signal** — R15 §15.8 Problem #4 was explicit + reviewer-flagged but rebuttal-15 §15.8 did not address. Next-finer-granularity sweep pattern: R15 reviewer flagged it but R15 defender deferred. R16 catches the explicit-but-unfixed residue. Same pattern as workflow.md Gate #9 clauses (a)→(d) where each round's narrower-than-defect-class fix surfaces next-finer surface at next review.

**Minimum acceptable fix:**

Swap content of L1988 and L1992 (3-row reorder; preserves all Status entry text verbatim):

```
# BEFORE:
L1986 iter-1 close (2026-05-14)
L1988 iter-3 close (2026-05-17, Run #5)
L1990 iter-3 PATCH (2026-05-17, ADR-014)
L1992 iter-2 close (2026-05-17, Run #4)
L1994 close-by-BT-002 (2026-05-18)

# AFTER:
L1986 iter-1 close (2026-05-14)
L1988 iter-2 close (2026-05-17, Run #4)     ← was L1992
L1990 iter-3 PATCH (2026-05-17, ADR-014)
L1992 iter-3 close (2026-05-17, Run #5)     ← was L1988
L1994 close-by-BT-002 (2026-05-18)
```

Plus add narrative anchor sentence at L1986 trailer (or new comment before L1988): `"<!-- Status entries listed in chronological order per Gate #7 audit-trail discipline; reorder applied 2026-05-18 via R16 §16.4 -->"` — establishes invariant for future Status appends.

Cascaded change: Mid-Phase Audit Log L2253 cite `Status L1986` (per Claim 16.6 line-anchor drift) will need re-anchor to grep-stable symbolic anchor regardless of reorder; reorder doesn't introduce new cite drift.

**Effort:** Low (3-row swap preserving all content; ~5-10 LOC layout change; no narrative rewrite needed; mirror R20 §20.3 reorder-discipline pattern at task-block layer).

---

#### Claim 16.5: 🟡 MEDIUM — `impl-plan.md` Mid-Phase Audit Log L2250 row dated 2026-05-04 (IMPL-FIX-001 + IMPL-FIX-002 closed via parallel batch) is chronologically out-of-order — sandwiched between L2249 (2026-05-14) and L2251 (2026-05-17); pre-existing readability defect predates R15 but surfaces during R16 sweep as audit-log internal consistency gap; Gate #7 Phase Status Notes-sweep analog at audit-log-internal layer

**Location:** `docs/state/impl-plan.md` Mid-Phase Audit Log L2248-L2253:

- L2248: `| 2026-05-14 | P4 | **IMPL-FIX-012 iter-1 ✅ CLOSED — ADR-013 DEAL_REASON_EXPERT filter applied...** |`
- L2249: `| 2026-05-14 | P4 | **IMPL-062 Run #3 EXECUTED + IMPL-063 ✅ CLOSED via cascade + IMPL-FIX-012 AUTHORED...** |`
- L2250: `| 2026-05-04 | P3+P2 | **IMPL-FIX-001 + IMPL-FIX-002 closed (parallel batch) — Tier 1.5 walk batch-1 findings drained at coordinator level...** |` ❌ out-of-order
- L2251: `| 2026-05-17 | — | **fix-round-26 ✅ CLOSED — 6/6 findings Accept...** |`

**Problem:**

Mid-Phase Audit Log is documented as "primary chronological audit trail" per its purpose statement (L2176 region). L2250 dated 2026-05-04 sits between L2249 (2026-05-14) and L2251 (2026-05-17) — chronologically out-of-order. Pre-existing defect predates R15 (R15 appended 9 new rows at L2252-L2260 chronologically-ordered post-fix-round-26 anchor).

The L2250 row belongs in the earlier chronological band (between IMPL-060 closure 2026-05-03/04 entries and 2026-05-05 walk batch-2 entries — should be near top of Mid-Phase Audit Log table). It got misplaced during an earlier rebuttal append. R16 sweep surfaces the residue.

**Why this matters:**

1. **Audit-trail readability** (Dim #10) — reader scrolling chronologically encounters 2026-05-14 → 2026-05-14 → **2026-05-04** → 2026-05-17 → ... — visual time-travel breaks the chronological discipline; cognitive friction for status agents + Tech Lead chrono-audits

2. **MEDIUM not HIGH** because: (a) row content is correct (IMPL-FIX-001 + IMPL-FIX-002 closure narrative is accurate per 2026-05-04 walk batch-1 events); (b) the row IS in the audit-log (not missing); (c) chronological position is layout concern not content correctness; (d) pre-existing predates R15 — minor residue cleanup

3. **Recurring Weakness signal** — same defect class as Claim 16.4 at audit-log-internal layer (vs Claim 16.4 at task-block-internal layer); both are Gate #7 Phase Status Notes-sweep analog finding at internal-chronological-discipline layer

**Minimum acceptable fix:**

Move L2250 to chronologically-correct position (between earlier 2026-05-03 and later 2026-05-05 audit-log rows). Engineer locates the correct insertion point by grepping for adjacent dates:

```bash
awk -F'|' 'NR>=2178 && NR<=2260 {print NR": "$2}' docs/state/impl-plan.md | sort -t'|' -k2
```

Expected insertion point: between the IMPL-060 closure row (2026-05-04 dated rows already present in audit log) and the walk batch-2 closure row (2026-05-05 dated row). Reorder = single row move; content unchanged.

**Effort:** Low (1-row move within audit log; ~3-5 LOC layout change; no narrative rewrite needed).

---

### 🔵 LOW

#### Claim 16.6: 🔵 LOW — `impl-plan.md` L2253 Mid-Phase Audit Log row for IMPL-FIX-012 iter-3 Run #5 cites `"IMPL-FIX-012 Status L1986"` as evidence-pointer — but L1986 = iter-1 close Status (iter-3 close Status is at L1988 post-R15 rebuttal); cite-by-line-number drift caused by R15's own LOC additions; analogous to R22-R23 line-anchor brittleness defect class (workflow.md Gate #9 clause (h)) at audit-log-internal-cite layer; recommend re-anchor to grep-stable symbolic anchor

**Location:** `docs/state/impl-plan.md` L2253 (Mid-Phase Audit Log row):

`"| 2026-05-17 | P4 | **IMPL-FIX-012 iter-3 Run #5 EXECUTED ❌ — ADR-014 INSUFFICIENT; INTRODUCES 3rd false-positive class (BI pyramiding close-tk12+open-tk14 same tick) HALT 8 sim days EARLIER than baseline → cap-3 budget exhausted → escalation gate fires** | impl-plan.md (IMPL-FIX-012 Status L1986 + ...) | ..."`

**Problem:**

The evidence-pointer cell of L2253 row cites `"IMPL-FIX-012 Status L1986"` as the in-plan record of the iter-3 close event. Empirical line resolution:
- L1986 = `"Status (iter-1 close, this commit 2026-05-14)"` ❌ (iter-1 not iter-3)
- L1988 = `"Status (iter-3 — Run #5 EXECUTED 2026-05-17, ADR-014 INSUFFICIENT...)"` ✅ (correct iter-3 close)

The cite is off-by-2. Root cause: R15 §15.8 fix added the new L1994 `Status (close-by-BT-002 supersession 2026-05-18)` row, which shifted prior content downward by ~2 LOC. Pre-R15 line numbers had iter-3 close at "L1986" (per claim-review-15.md § Claim 15.8 Location). The R15 rebuttal § Claim 15.10 audit-log append cited the **pre-rebuttal** line number `L1986` for iter-3, but the rebuttal's own task-block edits shifted iter-3 close to L1988 by the time the rebuttal commit lands. Self-referential drift.

Same defect class as workflow.md Gate #9 clause (h) (R22 line-anchor brittleness rule):

> "bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor — drift on file edits silently desyncs the cite without compile-time signal."

The Gate #9 clause (h) was authored for source-code bin-1 routing comments. R16 §16.6 surfaces the **same defect class at impl-plan.md audit-log-internal cite layer** — Mid-Phase Audit Log evidence-pointers MUST use grep-stable symbolic anchors (`"Status (iter-3 — Run #5 EXECUTED 2026-05-17)"`) not physical line numbers, to survive future LOC shifts.

L2252 (Mid-Phase Audit Log row for iter-2) similarly cites `"IMPL-FIX-012 Status L1992"` — which is the post-rebuttal correct line for iter-2 (✅ no drift at L2252 because the new L1994 row was appended AFTER iter-2 row not before it). So only L2253 has the off-by-2 cite drift.

**Why this matters:**

1. **LOW not MEDIUM** because: (a) audit-log cite drift is internal to impl-plan.md (not cross-doc); (b) reader cross-referencing the wrong line learns about iter-1 instead of iter-3 — but the iter-3 narrative is identifiable from the surrounding context + the L2253 row's own narrative summary; (c) the cite is a navigation aid not load-bearing for closure correctness; (d) self-resolves OR becomes worse with each future LOC change to IMPL-FIX-012 task block — recommend re-anchor preemptively

2. **Defect-class progression signal** — Gate #9 clause (h) line-anchor brittleness rule is documented for source code (R22 §22.1 fix-round-22 §22.1 hand-fix applied to `domain/CSlotBase.mqh:68,150`). R16 §16.6 surfaces the **next-meta-layer**: the rule applies symmetrically to audit-trail meta-documents (`impl-plan.md` Mid-Phase Audit Log evidence-pointer cells). Future Gate #9 clause (j) candidate: "audit-log meta-document evidence-pointer cites must use grep-stable symbolic anchors not physical line numbers." Out-of-scope for R16 rebuttal — recommend `/update-config` ticket per R14 §14.4 precedent.

3. **Recurring Weakness signal** — same defect class as R22→R23 source-code line-anchor brittleness chain at audit-trail-meta-document layer; expected to recur with each future IMPL-FIX-012 task-block edit unless re-anchored

**Minimum acceptable fix (engineer-choice — accepts either disposition):**

**Option A (recommended)** — Re-anchor L2253 evidence-pointer cite to grep-stable symbolic anchor:

```markdown
| 2026-05-17 | P4 | **IMPL-FIX-012 iter-3 Run #5 EXECUTED ❌ ...** | impl-plan.md (IMPL-FIX-012 ~~Status L1986~~ Status `(iter-3 — Run #5 EXECUTED 2026-05-17, ADR-014 INSUFFICIENT — REGRESSED EARLIER; cap-3 budget exhausted → escalation gate fires)` — re-anchored to symbolic anchor per R16 §16.6 + Gate #9 clause (h) line-anchor brittleness rule; pre-R15 line was L1986; post-R15 rebuttal commit ~L1988; symbol cite survives future LOC shifts), + TL;DR L7) | ... |
```

Also apply preemptive symbolic-anchor refactor to L2252 IMPL-FIX-012 iter-2 cite (currently `"Status L1992"`) for consistency + future-proofing — replace with `"Status (iter-2 — Run #4 EXECUTED 2026-05-17, E-AC #1 NOT MET)"` symbolic anchor.

**Option B (retain verbatim per R10 §10.6 audit-trail discipline)** — accept current L2253 `Status L1986` cite as-is + log known follow-up in next R17 cycle; engineer dispositive on whether immediate re-anchor or deferred-to-next-LOC-drift; reviewer recommends Option A for consistency with R22-R23 source-code Gate #9 clause (h) discipline + preemptive future-proofing.

**Effort:** Low (1-cite re-anchor; ~5-10 LOC; optional preemptive Option A applied to L2252 sibling = +5 LOC).

---

## Cross-Document Issues

R16 catches **2 cross-document state-reconciliation gaps** at finer-granularity layers (R15 §15.1 originating defect class drained at primary-SoT layer; R16 catches residue at third-tier handoff layer + audit-log-meta-cite layer):

| Contradiction | Primary SoT (correct) | Drifted surface |
|---------------|----------------------|------------------|
| `current_handoff.md` Last completed action | `backtrack-log.md § BT-002 § Status` = `✅ Closed (2026-05-18)` + `overview.md` row 19 + `impl-plan.md` TL;DR L101 (R15 rebuttal 12/12 Accept) | `current_handoff.md` L7 = `🟢 BT-002 SD rework APPLIED 2026-05-17` (pre-cascade-closure framing); Claim 16.3 |
| Mid-Phase Audit Log evidence-pointer cite for IMPL-FIX-012 iter-3 | `impl-plan.md` L1988 `Status (iter-3 — Run #5 EXECUTED 2026-05-17, ADR-014 INSUFFICIENT...)` | `impl-plan.md` L2253 audit-log row cite = `Status L1986` (off-by-2 post-R15 rebuttal LOC shift; L1986 is iter-1 close); Claim 16.6 |

Intra-document inconsistencies (3 surfaces):
- IMPL-051 task block: E-AC L903 stays `[ ]` while L909 Cancelled-by-BT-002 + L898 Input post-BT-002 annotation declare task superseded; intra-block status contradiction (Claim 16.1)
- IMPL-051 task block: Risk L905 + ADR L906 read pre-BT-002 framing without post-BT-002 footnote (mirror L898 Input pattern); intra-block annotation asymmetry (Claim 16.1 corollary)
- P4 Phase Gate L1411 Empirical Demo properly drained (R15 §15.6) but L1412 Tier 1.5 Walk row instruction (3) still cites manually-triggered CircuitBreaker (Claim 16.2); intra-Phase-Gate-block annotation asymmetry

No new Evolution Sequence violation. No ADR backing gap. Phase × Size matrix denominator preserved (IMPL-051 stays in matrix per audit-history discipline; IMPL-FIX-012 stays via close-by-supersession pivot). SD Hint Alignment audit trail unchanged (BT-002 did not introduce new task or change classifications). Plan Staleness Sentinel + Closure Hygiene Status canonical-current per R15 §15.11 + §15.12 fixes.

---

## Recurring Weaknesses (rounds 06-15)

1. **State-reconciliation defect-class progression continues at next-finer granularity each round** (per R15 § Recurring Weaknesses #1 axis catalog):
   - R06/R07: TL;DR↔registry drift (within `impl-plan.md`)
   - R08: Phase Status Notes + Open Risks + Next Best Action (intra-narrative-parallel sections)
   - R09: TL;DR↔diagnostic-artifact drift (one external artifact)
   - R10: TL;DR↔Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh
   - R11: upstream-vs-impl-plan (BA `03` + SD `08` Last-updated 2026-05-12 vs impl-plan pre-BT-001 framing) — BT-001 19-surface drain across impl-plan.md
   - R12: upstream-lifecycle-state-vs-derived-view (`backtrack-log.md § BT-001 Status` primary lifecycle SoT vs impl-plan ~19 surface annotations) — 5th meta-axis
   - R13: derived-view↔derived-derived-view (R12 reconciled backtrack-log↔impl-plan but overview.md unreconciled) — 6th axis depth-of-propagation
   - R14: intra-primary-SoT TL;DR canonical-block-vs-narrative-prose (7th axis at top reader-skim surface)
   - R15: **next-cascade-event drain** — BT-002 cascade across 11+ impl-plan surfaces (8th axis fresh-cascade-event boundary)
   - **R16 (this round)** catches the **next-finer-granularity residue at three sub-axes**: (a) intra-task-block annotation asymmetry where R15 fixed one sibling task's E-AC supersession but not the other (Claim 16.1 IMPL-051 vs R15 §15.8 IMPL-FIX-012); (b) intra-Phase-Gate-block annotation asymmetry where R15 fixed Empirical Demo + NFR-1.1 sub-row but not the adjacent Tier 1.5 Walk row (Claim 16.2 L1412 vs R15 §15.6 L1411/L1416); (c) third-tier handoff layer where R15 closed tiers 1+2 of 3-file rule but not tier 3 (Claim 16.3 current_handoff.md vs R15 §15.1 + claim CHs). Defect-class progression now at **9th axis** — within-cascade-drain-rebuttal-scope-narrower-than-defect-class-footprint, the same pattern that R20→R23 fix-round chain documented at source-code Gate #9 clauses (a)→(d).

2. **Cascade-drain rebuttal verify-pass cycle continues** — BT-002 closure → R15 BT-002 11+ surface drain → R16 verify-pass + residue cleanup (this round) → expected R17 verify-pass clean cycle. Mirror BT-001 closure → R11 BT-001 drain → R12/R13/R14 verify-pass chain. R16 rebuttal predicted 5-6 Accept verify-pass (all are residue closures; no rejected claims expected).

3. **Gate #2 mechanical sweep status** — per R14/R15 § Recurring Weaknesses, Gate #2 (TL;DR ↔ registry recount) is documented since R07 but only explicitly invoked when narrative discipline cites it. **R16 verify-pass note**: Gate #2 ran clean this round (5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = 55 Active rows ✅ matches TL;DR L100 + 8 Resolved rows ✅ matches L100; R14 fix + fix-round-26 +1 P5 + R15 IMPL-FIX-013 sync all propagated correctly). **R14 informal recommendation** (Gate #2 mandatory-every-round codification) still outstanding as `/update-config` candidate.

4. **R10 §10.6 audit-history precedent boundary** — R14 §14.2 + §14.6 disposition (lead clauses = canonical-current; per-entry boilerplate triad = audit-history) extended to BT-002 cascade context in R15. R16 §16.1 + §16.2 follow lead-fields = canonical-current rule (Risk + ADR + E-AC are lead-fields per task-block schema; should mirror post-BT-002 footnote pattern of Input field). R16 §16.3 follows lead-paragraph = canonical-current rule at handoff layer (Last completed action lead paragraph). No new boundary surface this round.

5. **Gate #9 clause (h) line-anchor brittleness rule applies symmetrically to audit-log meta-document evidence-pointer cells** (R16 §16.6 newly-surfaced defect-class application) — recommend `/update-config` ticket extending Gate #9 clause (h) with explicit "audit-log meta-document evidence-pointer cites" coverage; out-of-scope for R16 rebuttal — engineer-side methodology-evolution ticket per R14 §14.4 precedent.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 16.1 | 🟠 HIGH | IMPL-051 task block intra-block asymmetry post-BT-002 — L903 E-AC stays `[ ]` deferred with stale CircuitBreaker live-wiring annotation while L909 Cancelled-by-BT-002 declares task superseded; symmetric to R15 §15.8 IMPL-FIX-012 E-AC flip but NOT applied to IMPL-051 sibling; also L905 Risk + L906 ADR fields pre-BT-002 framing | `impl-plan.md` L893-L909 (IMPL-051 task block — L903 E-AC + L905 Risk + L906 ADR) | Low (1 E-AC flip + 2 field annotation appends; ~30-40 LOC) |
| 16.2 | 🟠 HIGH | P4 Phase Gate L1412 Tier 1.5 Exploratory Walk row instruction (3) `"halt paths trigger correctly (manually trigger CircuitBreaker via stub; ...)"` carries pre-BT-002 framing; operator would attempt to trigger removed mechanism; R15 §15.6 fix landed at L1411 + L1416 but did NOT reach L1412 sibling row | `impl-plan.md` L1412 | Low (1 instruction-(3) rewrite; ~20-30 LOC) |
| 16.3 | 🟠 HIGH | `current_handoff.md` L7 `Last completed action` stale at `"🟢 BT-002 SD rework APPLIED 2026-05-17"` — predates SD Round 09 closure + BA Round 06 closure + BT-002 ✅ CLOSED + R15 closure (all 2026-05-17/18 events); third tier of State Reconciliation 3-file rule not propagated; same defect class as R15 §15.1 originating inversion gap but at handoff layer | `current_handoff.md` L7 | Low (1 lead-block rewrite; ~30-50 LOC) |
| 16.4 | 🟡 MEDIUM | IMPL-FIX-012 task block L1988/L1990/L1992 Status entries chronologically out-of-order — R15 §15.8 Problem #4 explicit-but-unfixed; correct order = iter-1 → iter-2 → iter-3 PATCH → iter-3 close → close-by-BT-002 | `impl-plan.md` L1986-L1994 (IMPL-FIX-012 Status entries) | Low (3-row reorder swap; ~5-10 LOC layout change; no narrative rewrite) |
| 16.5 | 🟡 MEDIUM | Mid-Phase Audit Log L2250 row dated 2026-05-04 chronologically out-of-order (sandwiched between L2249 = 2026-05-14 + L2251 = 2026-05-17); pre-existing predates R15 | `impl-plan.md` L2250 (Mid-Phase Audit Log table) | Low (1-row move within audit log; ~3-5 LOC layout change) |
| 16.6 | 🔵 LOW | Mid-Phase Audit Log L2253 evidence-pointer cite `Status L1986` for IMPL-FIX-012 iter-3 — but L1986 = iter-1 close (iter-3 close at L1988 post-R15 LOC shift); analogous to Gate #9 clause (h) line-anchor brittleness rule at audit-log-meta-document layer; recommend re-anchor to grep-stable symbolic anchor | `impl-plan.md` L2253 (Mid-Phase Audit Log evidence-pointer cell) | Low (1-cite re-anchor; ~5-10 LOC; optional Option A preemptive sibling = +5 LOC) |

---

## End of Review
