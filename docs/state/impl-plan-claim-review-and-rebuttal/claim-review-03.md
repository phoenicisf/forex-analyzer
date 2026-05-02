# Implementation Plan Claim Review Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Target** | `docs/state/impl-plan.md` (post `rebuttal-round-02.md`; command argument: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-02.md`) |
| **Date** | 2026-05-02 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Plan version reviewed** | Round 02 patched per `rebuttal-round-02.md` (3 Accept / 0 Partial / 0 Reject) |

---

## 📊 At-a-Glance

**Total findings:** 3 (🔴 CRITICAL 0 / 🟠 HIGH 0 / 🟡 MEDIUM 2 / 🔵 LOW 1)

**Mechanical pre-scans:**
- Forbidden closure patterns (`deferred to operator-runtime|deferred to post-launch|deferred per .* precedent|structurally complete.*deferred|live verification deferred` on `impl-plan.md`): **0 hits** ✅
- Forward reference (P_n → P_m, m>n): **0 edges** across **68 tasks** ✅
- Silent Copy Detector: H = 68, A = 67, D = 1, V = 0, N = 0 → **not triggered** (D = 1, IMPL-013 documented divergence) ✅
- State reconciliation: **4 stale readiness markers** grouped into 3 findings (top `Action ถัดไป`, checked `Next Best Action`, `Plan Staleness Sentinel`, and round-02 closure propagation markers)

### Top 3 to Fix First

1. **Claim 03.1** 🟡 — Plan top section still instructs `/impl-plan-review all` after round-02 readiness approval — `impl-plan.md` lines 7 and 40-41
2. **Claim 03.2** 🟡 — `Plan Staleness Sentinel` still says review pending / none yet — `impl-plan.md` lines 1636-1642
3. **Claim 03.3** 🔵 — Round-02 closure not propagated to all derived readiness text — `impl-plan.md` line 9 + `overview.md` line 20

### Verdict

- [x] ✅ **Ready for Implementation Execution** — no CRITICAL/HIGH; direct `/impl-task IMPL-001` remains safe.
- [ ] ⚠️ **Needs Rebuttal Round** — N/A by severity policy, but a fast state-hygiene rebuttal is recommended before relying on `/next`.
- [ ] ⛔ **Immediate Attention** — N/A

> **Recommendation:** Proceeding directly to `/impl-task IMPL-001` is safe. However, `/next` or any status agent may still recommend another `/impl-plan-review all` because readiness metadata was not fully flipped after round 02. Run a small `/impl-plan-rebuttal claim-review-03.md` pass if the plan will be used as the source for automated next-action selection.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Four-phase MQL5 compile/dependency rationale remains intact; P2/P4 percentage deviations are explicitly justified. |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | 67 ✅ / 1 ⚠️ / 0 🔴 / 0 ◻️; Evolution E1/E1a/E1b/E1c/E2 all honored; Silent Copy Detector not triggered. |
| 3 | Task Decomposition & Sizing | ✅ Pass | Round-02 AC parity fix landed: bracket-condensed `S-AC` / `E-AC` grep = 0. IMPL-049 remains XL with explicit 4-pass decomposition hint. |
| 4 | AC — Dual-Track Compliance | ✅ Pass | Forbidden closure pattern grep = 0; E-AC evidence-kind taxonomy present; no config-blind Phase 1 task found. |
| 5 | Phase Gates — Testable Exit | ✅ Pass | P3 Tier 1.5 row now marks 5-yr aggregate as supplement-not-substitute; all phases retain 9 gate rows incl. rollback. |
| 6 | Deferred-AC + Operator Action Registry | ✅ Pass | Both registries initialized empty per Phase 1 baseline; no Active / Pending rows expected. |
| 7 | Cross-Phase Dependency | ✅ Pass | Parsed 68 task sections; no earlier-phase task depends on a later-phase task. |
| 8 | State-File Consistency | ⚠️ Findings 03.1, 03.2, 03.3 | `overview.md § Impl Plan` says Ready after rebuttal round 02, but `impl-plan.md` still has review-pending/staleness-pending markers. |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | Hits are legitimate metadata/test dates (`2026-05-02`, ISO timestamp example, DST/test wording), not SD schedule leakage. |
| 10 | Readability — Reader Empathy | ⚠️ Findings 03.1, 03.3 | Stakeholder skim path is internally contradictory: top action says review, last action says ready, overview says ready. |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

_ไม่มี — no forbidden closure pre-authoring, no Evolution Sequence violation, no forward phase dependency._

### 🟠 HIGH

_ไม่มี — the implementation plan remains executable. Remaining defects affect status automation/readiness clarity, not task executability._

### 🟡 MEDIUM

#### Claim 03.1: 🟡 MEDIUM — Top-level next action still sends the operator back into `/impl-plan-review all` after round-02 Ready verdict

**Location:** `docs/state/impl-plan.md` lines 7 and 40-41

**Problem:**
Round 02 rebuttal states the plan is ready:

```markdown
- [x] ✅ **Ready for Implementation Execution** — all 3 round-02 findings resolved...
```

`overview.md § Impl Plan` also says **"✅ Complete + Rebuttal Round 02"** and **"Next action: `/impl-task IMPL-001`"**. But the primary plan still tells the reader:

```markdown
> **Action ถัดไป:** `/impl-plan-review all` (mandatory plan QA cycle ก่อน start P1) → จากนั้น `/impl-task IMPL-001`
...
- ☑ **Plan QA loop — `/impl-plan-review all`** (mandatory per CLAUDE.md §6 — plan ต้องผ่าน review ก่อน start `/impl-task`; mirrors BA/SD/UX/TD review pattern)
- ☐ Continue Track A — recommended task: **IMPL-001** ... once review verdict ✅
```

The review verdict already exists. The checked checkbox is now pointing to completed workflow, while the unchecked row points to the actual next task.

**Why this matters:**
`/next` and a human skim both rely on the top narrative before reading the 1,600-line task body. With the wrong row checked, the project can loop through review forever even though the approved next action is `/impl-task IMPL-001`. This is not a task-blocking defect, but it is a state-navigation defect in the primary SoT.

**Minimum acceptable fix:**
Update the top callout and `Next Best Action` section:

```markdown
> **Action ถัดไป:** `/impl-task IMPL-001` (XS `[ea]` — folder structure + `bootstrap_smoke.ini` scaffold); IMPL-046 parallelizable after IMPL-001+IMPL-010 land
...
- ☑ Continue Track A — recommended task: **IMPL-001** (XS `[ea]` — folder structure + `bootstrap_smoke.ini` scaffold); IMPL-046 parallelizable ASAP after IMPL-001+IMPL-010 land
- ☐ Plan QA loop — complete through Rebuttal Round 02; re-run only if plan changes materially or staleness sentinel triggers
```

**Effort:** Low

---

#### Claim 03.2: 🟡 MEDIUM — `Plan Staleness Sentinel` still records "review pending" after two completed review rounds

**Location:** `docs/state/impl-plan.md` lines 1636-1642

**Problem:**
The sentinel currently says:

```markdown
**Plan approved on:** _pending — awaiting `/impl-plan-review all` approval_
**Last review on:** _none yet_
**Closures since last review:** 0

> ... Currently: review pending; staleness check inactive until first review.
```

That conflicts with:
- `claim-review-02.md` verdict: **Ready for Implementation Execution** with no CRITICAL/HIGH.
- `rebuttal-round-02.md` recommendation: **Ready for Implementation Execution** after 3/3 Accept.
- `overview.md § Impl Plan`: **✅ Complete + Rebuttal Round 02**.

**Why this matters:**
The staleness sentinel is specifically read by `/next` Check 5.8. If it says "no review yet", a future status pass can incorrectly recommend another plan review immediately after a completed review/rebuttal loop. Worse, once IMPL tasks start closing, `Closures since last review` has no reliable baseline because the sentinel never recorded the approval event.

**Minimum acceptable fix:**
Set the sentinel to the latest accepted review/rebuttal state. Example:

```markdown
**Plan approved on:** 2026-05-02 — after `claim-review-02.md` + `rebuttal-round-02.md`
**Last review on:** 2026-05-02 — `claim-review-03.md` (state-hygiene sweep) OR `claim-review-02.md` if no round-03 rebuttal is run
**Closures since last review:** 0

> Per `/next` Check 5.8: plan staleness recommendation triggers when approved >30d ago AND (>10 task closures since last review or material plan changes). Currently: approved; staleness check inactive until task closures accumulate.
```

If a rebuttal is run for this file, use `claim-review-03.md` / `rebuttal-round-03.md` as the last review marker.

**Effort:** Low

### 🔵 LOW

#### Claim 03.3: 🔵 LOW — Round-02 closure text is not propagated to every readiness marker

**Location:** `docs/state/impl-plan.md` line 9 + `docs/state/overview.md` line 20

**Problem:**
Round 02 did add the audit row:

```markdown
| 2026-05-02 | — | Rebuttal round 02 closed | impl-plan.md, overview.md | 3/3 Accept ... |
```

But the top `Last updated` marker still says:

```markdown
> **Last updated:** 2026-05-02 · last action: rebuttal-round-01 closed (7 Accept / 0 Partial / 0 Reject); plan ready for `/impl-task IMPL-001`
```

And `overview.md § Impl Tasks` says:

```markdown
Plan QA cycle complete (round 01 = ✅ Ready for Implementation Execution).
```

That is stale after `rebuttal-round-02.md`, which explicitly says the status field was updated to **Rebuttal Round 02** and that the plan is ready after 3/3 Accept.

**Why this matters:**
This is lower severity than Claim 03.1 because both stale markers still point to `/impl-task IMPL-001`. But it weakens State Reconciliation Discipline: one row says round 02 is the latest closure, two other readiness markers still say round 01. A future reviewer may waste time checking whether round 02 actually landed.

**Minimum acceptable fix:**
Update both markers:

```markdown
> **Last updated:** 2026-05-02 · last action: rebuttal-round-02 closed (3 Accept / 0 Partial / 0 Reject); plan ready for `/impl-task IMPL-001`
```

And in `overview.md § Impl Tasks`:

```markdown
Plan QA cycle complete (round 02 = ✅ Ready for Implementation Execution). First task: **IMPL-001** ...
```

**Effort:** Low

---

## Cross-Document Issues

No SD/TD/ADR/API contradictions were found in this sweep:

- Evolution Sequence source in `07-future-evolution.md § 6` still matches plan assignment: E1 → IMPL-046 P1; E1a/E1b/E1c → IMPL-047/048/049 P2; E2 → IMPL-018 P3.
- Phase Hints source in `08-product-breakdown.md § 3` still matches the plan tally: 67 Align, 1 Diverge (IMPL-013 P4→P3).
- `deferred-ac-registry.md` and `operator-action-registry.md` remain initialized empty, matching the Phase 1 local-only baseline.
- Round-02 substantive fixes verified: bracket-condensed AC grep = 0; `×21 brief runs OR 1 full 5-yr` grep = 0; P3 Tier 1.5 includes supplement-not-substitute wording.

The only cross-document drift is state/readiness metadata between `impl-plan.md`, `overview.md`, and the round-02 rebuttal record.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 03.1 | 🟡 MEDIUM | Top-level next action still sends operator back into `/impl-plan-review all` after Ready verdict | `impl-plan.md` lines 7, 40-41 | Low |
| 03.2 | 🟡 MEDIUM | `Plan Staleness Sentinel` still records "review pending" after two completed review rounds | `impl-plan.md` lines 1636-1642 | Low |
| 03.3 | 🔵 LOW | Round-02 closure text is not propagated to every readiness marker | `impl-plan.md` line 9 + `overview.md` line 20 | Low |

---

## Reviewer's Closing Note

Round 02 fixed the actual plan-quality defects: no forbidden closure patterns, no forward references, no bracket-condensed ACs, no P3 Tier 1.5 OR-clause ambiguity. The plan is executable.

Round 03 is therefore a state-hygiene review, not a planning rework review. The remaining problem is that readiness markers were updated unevenly: deep audit rows and `overview.md § Impl Plan` say "Ready after round 02", while the top `Next Best Action` and `Plan Staleness Sentinel` still say "review pending". That can mislead `/next` and status readers even though `/impl-task IMPL-001` is safe.

**Engineer next action remains:** `/impl-task IMPL-001` after a small rebuttal patch, or immediately if the operator invokes it directly and ignores the stale top-section review prompt.

— Implementation Plan Reviewer (Adversarial Tech Lead)
2026-05-02
