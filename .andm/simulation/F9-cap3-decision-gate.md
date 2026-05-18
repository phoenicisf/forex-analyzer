# F9 — Cap-3 Decision Gate + IMPL-FIX Sibling Ban + Sample-Walk

> **Scenario class:** Methodology evolution validation — exercises rules added 2026-05-17 from PhoenicisNex retro
> **Reference system:** TaskFlow (per simulation README) — financial reporting module with slow-runtime backtest stack
> **Commands demonstrated:** `/impl-task`, `/impl-plan-review`, `/backtrack`, `/next`
> **Glossary terms exercised:** `Cap-3 Decision Gate`, `IMPL-FIX Sibling Ban`, `METHODOLOGY-REDESIGN Ticket`, `Plan Staleness Sentinel` (dual counter), `Impl-Plan Compaction Threshold`, `Exploratory Walk (Tier 1.5)` — sample-walk variant, `Handoff Artifact Archive Policy`

---

## Setup

- TaskFlow's Reports module wraps an empirical 5-yr backtest engine (financial parity check, 30-60 min/run)
- Phase 3 P2 in progress — `docs/state/impl-plan.md` already 48k tokens, 7 IMPL-FIX-* tickets closed
- Engineer opens IMPL-FIX-007 (parity regression in `MonthlyAggregator`) — hypothesis: rolling-window math wrong

---

## Step 1 — Cap-3 budget exhausted on IMPL-FIX-007

| Iter | Hypothesis | Result |
|---|---|---|
| 1 | Fix window-offset by-one | re-canary `FALSIFIED` — -3.2% regression |
| 2 | Change accumulator initialization | re-canary `FALSIFIED` — same regression |
| 3 | Add anti-pyramid latch | re-canary `EMPIRICALLY FALSIFIED` — different defect surfaces |

Engineer prepares iter-4. Opens new branch + intends to commit as `IMPL-FIX-007a Step 4 iter-1 — bulk-suppress entry_*`.

**Engineer runs:** `/impl-task IMPL-FIX-007a`

---

## Step 2 — Cap-3 Decision Gate fires (impl-task.md Phase 1.3.3)

`/impl-task` Phase 1.3.3 Cap-3 Decision Gate runs:

1. **Sibling-naming check (HARD BLOCK):** ticket ID `IMPL-FIX-007a` matches forbidden pattern `IMPL-FIX-\d+[a-z]` → HALT with `IMPL-FIX SIBLING BAN` message
2. Engineer reads the halt — cannot proceed with `007a`. Options listed in Cap-3 Decision Gate prompt:
   - (a) `/backtrack` BA/SD/UX/TD
   - (b) Re-decompose → spawn fresh `IMPL-FIX-008` + close `IMPL-FIX-007` as `[scope-replaced → 008]`
   - (c) Defer with operator sign-off + `deferred-ac-registry.md` row

Engineer picks (b) — believes premise still valid; per-iter evidence shows scope was too wide (window math + accumulator + anti-pyramid = 3 independent root causes, not one)

3. Engineer runs `/impl-plan-review all` to re-decompose
   - Plan Reviewer spawns 3 fresh tickets: `IMPL-FIX-008` (window math), `IMPL-FIX-009` (accumulator init), `IMPL-FIX-010` (anti-pyramid)
   - `IMPL-FIX-007` closes as `[scope-replaced → 008, 009, 010]` — NOT `[x]`
   - Plan-Reviewer rebuttal round documents the Cap-3 Decision Gate trigger as audit-trail entry

---

## Step 3 — Sample-walk validates IMPL-FIX-008 before opening 009

`IMPL-FIX-008` closes (window math hypothesis verified — iter-1 PASS). Before opening `IMPL-FIX-009`, engineer wants to confirm no regression in adjacent slots.

Full Tier 1.5 walk on this stack = 30-60 min (full 5-yr backtest). Engineer chooses **sample-walk**:

1. Scope axis: **time-slice** — last 30 sim days only
2. Bootstrap cold from zero, run sample backtest (~7 min wall-clock)
3. Walk findings: 0 CRITICAL, 1 LOW (cosmetic — log line ordering)
4. Save artifact: `docs/state/_session-handoff/20260517-phase2-sample-walk.md` (note `sample-walk`, not `exploratory-walk`)
5. Artifact frontmatter declares: `Replaces full-walk? NO — full-walk still required before Phase Gate`

Engineer proceeds to `IMPL-FIX-009`. Sample-walk does not tick Phase Gate "Tier 1.5" row — full-walk still pending.

---

## Step 4 — `/next` Check 5.8 Plan Staleness Sentinel (dual counter)

After `IMPL-FIX-008` + `009` + `010` close, engineer runs `/next` for the next task.

Check 5.8 computes:
- `main_task_closures_since_review` = 4 (below threshold 10)
- `fix_iter_closures_since_review` = 22 (above threshold 20 — includes the 3 falsified iters on `007` + closure iters on `008`/`009`/`010` + 13 earlier fix-iter closures)

Trigger (c) fires. Sentinel advisory message displays both counts. Engineer picks Option (a): `/impl-plan-review all` to re-validate phasing + AC dual-track + IMPL-FIX scope drift before next task. Plan Reviewer finds 1 MEDIUM (Phase 2 Mid-Phase Audit Log not initialized for P3 prep) + 0 HIGH/CRITICAL.

---

## Step 5 — Check 5.9 Impl-Plan Compaction Threshold fires

Same `/next` invocation continues to Check 5.9. `impl-plan.md` is now 52k tokens (grew past 50k due to scope-replacement audit trail for `IMPL-FIX-007`).

Sentinel fires advisory message. Engineer picks Option (a) — runs compaction at this sprint boundary:
- Keep in primary: TL;DR top-3, Phase Gate rows, Open Risks, current P2 task table, Mid-Phase Audit Log, SD Hint Alignment
- Move to `docs/state/impl-plan-archive-2026-05.md`: closed `IMPL-001..IMPL-040` entries + closed `IMPL-FIX-001..007` chain (incl. `007` scope-replaced trail)
- Primary plan now 28k tokens — readable in 2 Read calls

---

## Step 6 — Handoff artifact archive (on IMPL-FIX-007 closure)

When `IMPL-FIX-007` closed as `[scope-replaced]` in Step 2, the Phase 3.2 handoff archive policy fired:
- 11 `IMPL-FIX-007-iter-*-evidence-*.md` files older than 14 days exist
- None referenced by `deferred-ac-registry.md` Active row
- Archive: `tar -czf docs/state/_session-handoff/archive/IMPL-FIX-007.tar.gz docs/state/_session-handoff/IMPL-FIX-007*`
- Originals removed; archive path noted in `docs/state/reports/handoff.md` for retrievability

`_session-handoff/` root drops from 142 files → 131 files. Future `/next` grep cost bounded.

---

## Step 7 — Methodology defect recurrence (counter-factual)

> **Counter-factual sub-scenario:** demonstrates METHODOLOGY-REDESIGN trigger when Cap-3 Gate itself is misclassified.

Imagine in Step 2 the reviewer added a Gate clause to catch sibling-naming via regex, then in subsequent rounds the same defect class kept slipping through different naming variants (e.g., `IMPL-FIX-007-PART2`, `IMPL-FIX-007-EXT-A`).

By review-round 3 of the same defect class, `/impl-review` Phase 2.5 Defect Class Recurrence Check fires:
- Defect class: "IMPL-FIX sibling-naming via creative suffix"
- Rounds affected: R<N-2>, R<N-1>, R<N>
- Clause growth: (a) → (b) → (c)
- HALT — reviewer cannot add clause (d)
- Spawn `docs/code-review/methodology-redesign/METHODOLOGY-REDESIGN-001.md`:
  - Mechanism (regex on ticket-ID) cannot cover human creativity
  - Propose alternative: structural tool — `git hook` rejecting commit messages with `IMPL-FIX-\d+\S+` pattern at PR boundary
  - Owner + close date + methodology-owner sign-off

This round closes WITHOUT clause (d). Other unrelated findings proceed normally.

---

## Expected outcomes

| Rule | Triggered | Outcome |
|---|---|---|
| Cap-3 Decision Gate (Phase 1.3.3) | ✅ Step 2 | HALT at sibling naming; engineer re-decomposes to 3 fresh tickets |
| IMPL-FIX Sibling Ban (Cap-3 step 1) | ✅ Step 2 | `IMPL-FIX-007a` rejected; spawn `008/009/010` instead |
| Sample-Walk Variant | ✅ Step 3 | 7-min sample-walk instead of 30-60 min full-walk; full-walk still pending at Phase Gate |
| Plan Staleness Sentinel — dual counter | ✅ Step 4 | Trigger (c) fires on fix-iter count > 20; plan review runs |
| Impl-Plan Compaction Threshold | ✅ Step 5 | Plan compacted from 52k → 28k tokens |
| Handoff Artifact Archive Policy | ✅ Step 6 | IMPL-FIX-007 artifacts archived; root drops 11 files |
| METHODOLOGY-REDESIGN Ticket (counter-factual) | ✅ Step 7 | Spawn redesign ticket instead of clause (d) |

## Pre-existing scenarios unaffected

S1, S2, S3, S5, S6 + F1-F8 don't exercise IMPL-FIX-NNN chains with ≥3 falsified iter or `_session-handoff/` >14d retention. New rules are **additive** — existing happy-path / failure-path flows remain valid.

---

**Source:** [`real-problems/methodology-retrospective-day17.md`](../../../real-problems/methodology-retrospective-day17.md) (PhoenicisNex Day 17 retro, 2026-05-17)
