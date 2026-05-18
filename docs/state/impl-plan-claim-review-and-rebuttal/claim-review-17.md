# Implementation Plan Claim Review Round 17

| Field | Value |
|-------|-------|
| **Round** | 17 |
| **Target** | `docs/state/impl-plan.md` (+ state-reconciliation siblings: `overview.md`, `current_handoff.md`, `deferred-ac-registry.md`, `backtrack-log.md`) |
| **Date** | 2026-05-18 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R16 (2026-05-18) — 6/6 Accept; cascade-residue verify-pass round after R15 BT-002 cascade drain (3 HIGH intra-task-block + intra-Phase-Gate-block + 3-file-tier-3 asymmetries + 2 MEDIUM chronological reorder + 1 LOW line-anchor cite drift). Rebuttal-16 predicted "Routine verify-only R17 round predicted (mirror R13/R14 verify-pass chain after R11 BT-001 drain at BT-002 magnitude); R17 expected to surface 0-1 findings (defect-class progression now terminated at all known layers)." |
| **Trigger** | Operator invoked `/impl-plan-review all` immediately after R16 rebuttal narrative authoring + before R15/R16 commit landed (working-tree shows R15+R16 .md files untracked + impl-plan.md / current_handoff.md unstaged-modified). Scope: verify R16 cascade-residue drain landed cleanly across all 6 enumerated surfaces + sweep for residual cascade-completion gaps that R16 did not cover (mirror R12 verify-pass cycle after R11 BT-001 cascade drain at BT-002 magnitude). |

---

## 📊 At-a-Glance

**Total findings:** 7 (🔴 CRITICAL 1 / 🟠 HIGH 4 / 🟡 MEDIUM 1 / 🔵 LOW 1)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (`deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **1 sanctioned false-positive** ✅ — single hit at L27 IMPL-FIX-011d Phase 1 audit-log row (regex `.*` greediness matching `"deferred per registry row"` + later `"fix-round-10 precedent"` in same narrative). Identical to R16 baseline; **0 real hits** on `[x]` AC closure lines. R16 §15.11 closure-hygiene refactor + fix-round-26 §Finding 26.6 self-reference avoidance discipline preserved.
- **Forward refs (P_n → P_m, m>n):** **0 edges** ✅. Sub-ticket↔parent convention (R09 §09.5 + R11 §11.1) preserved across R16 6-surface drain (IMPL-051 E-AC supersession + IMPL-FIX-012 Status reorder + Mid-Phase Audit row move + 2 cite re-anchors + Phase Gate row rewrite do not introduce forward refs).
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013 P4→P3 Service-coupling diverge), V=0, N=0 — **Not triggered** ✅ (D ≥ 1; SD Hint Alignment scratch table L2266 onwards preserved post-R16; BT-002 cascade did not introduce new task or reclassify any task's hint alignment).
- **State reconciliation (4-way):** ✅ **R15 §15.1 primary inversion gap stays CLOSED** — `grep -c '\bBT-002\b'` on `impl-plan.md` = **33 hits** (+5 vs R16 baseline 28; new hits from R16 §16.1 IMPL-051 L903/L905/L906 BT-002 annotations + R16 §16.2 P4 Phase Gate L1412 walk-row rewrite). Vs `overview.md` = 10 + `current_handoff.md` = 22 (+22 from R16 §16.3 Last-completed-action lead-block rewrite) + `backtrack-log.md` = 7 + `CLAUDE.md` = 8. Registry recount per Gate #2: 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = **55 Active rows** + **8 Resolved rows** ✅ matches TL;DR L100 claim exactly. **3 NEW state-reconciliation gaps surface at next-finer-granularity layers post-R16 commit-narrative-propagation axis (10th meta-axis per Recurring Weaknesses chain)**: (a) TL;DR L101 `Last updated:` + Plan Staleness Sentinel L2349 `Last review on:` + Closure Hygiene Status L2363-2365 all cite "R15" only — no R16 mention despite R16 closure 2026-05-18 (Claim 17.2 + 17.3); (b) Mid-Phase Audit Log has 0 row for R16 rebuttal closure 2026-05-18 (Claim 17.4); (c) `overview.md` row 19 Impl Plan status asymmetric vs row 9 Design (BA) + row 10 Design (SD) which both flipped to "✅ Complete + BT-002 cascade CLOSED 2026-05-18" post-cascade-closure (Claim 17.5). PLUS 1 CRITICAL Gate #11 working-tree violation: 2 M files (impl-plan.md + current_handoff.md) + 4 untracked review/rebuttal .md files (claim-review-15/16 + rebuttal-round-15/16) + 18 .bak files from `/project-init --regen` — all uncommitted (Claim 17.1).

### Top 3 to Fix First

1. **Claim 17.1** 🔴 — **Gate #11 working-tree NOT clean — R15 + R16 rebuttal narratives both claim closure but commits never landed.** `git status --short` returns: `M docs/state/impl-plan.md` + `M docs/state/current_handoff.md` + `?? docs/state/impl-plan-claim-review-and-rebuttal/{claim-review-15,claim-review-16,rebuttal-round-15,rebuttal-round-16}.md` + 18 untracked `.bak` files from `/project-init --regen` 2026-05-18. Same defect class as R16 §15.13 + R16 §11 `Closure Hygiene Status footer Gate #11 working-tree clean post-commit pending final verification` advertised-as-pending residue — but R16 closure narrative was authored without actually exercising the commit. The R16 §11 narrative wrote "working-tree pending final commit" but operator launched `/impl-plan-review all` (this round) before that commit landed → Gate #11 violation at R17 entry. Originating fix-round-15 §16.2 / R16 §16.2 audit-trail gap defect class — "applied + verified" advertised but actual artefacts uncommitted (R16 narrative ~500 LOC of edits + 4 review docs uncommitted).

2. **Claim 17.2** 🟠 — **TL;DR L101 `Last updated:` lead clause cites "R15 12/12 Accept" as last action; doesn't mention R16 closure 2026-05-18.** Per workflow.md Gate #4 (atomic Sentinel + TL;DR `Last updated:` rewrite) + Gate #8 (narrative-section freshness sweep — TL;DR is canonical first-impression skim block; primary engineer-side reader surface) + CLAUDE.md §6 State Reconciliation Discipline ("ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update ทั้ง 3 ชั้น"), R16 rebuttal closure should have refreshed TL;DR Last-updated lead clause to cite R16 6/6 Accept verify-pass + preserve R15 narrative as prior-action subordinate clause (mirror R14 §14.6 + R15 §15.1 lead-clause refresh discipline). Same defect class as R15 §15.1 originating gap surfacing at within-rebuttal-commit-narrative-propagation layer (10th meta-axis per Recurring Weaknesses chain).

3. **Claim 17.5** 🟠 — **`overview.md` row 19 "Impl Plan" status reads pre-R15/R16-closure framing `"❌ Invalidated (BT-002 — ... re-run /impl-plan-review all post-SD lock)"` while row 9 "Design (BA)" + row 10 "Design (SD)" both flipped to `"✅ Complete + BT-002 cascade CLOSED 2026-05-18"` post-cascade-closure** — asymmetric narrative pattern at secondary-SoT layer. The "re-run `/impl-plan-review all` post-SD lock" recommendation already EXECUTED twice (R15 + R16 both ran post-SD-Round-09 closure) but Impl Plan row treats this recommendation as still-pending. Rebuttal-16 §11 + Cross-Document Issues table explicitly declined to update overview.md citing "substantive downstream work pending (TD review + impl-code cleanup + IMPL-062 re-execute)" but conflates two distinct layers: (a) **impl-plan layer cascade** = ✅ CLOSED 2026-05-18 via R15 + R16 (analogous to BA closure via Round 06 + rebuttal-05; SD closure via Round 09); (b) **downstream cascade** = pending (TD + impl-code + IMPL-062). The Impl Plan row should distinguish (a) from (b) — mirror BA + SD rows' "✅ Complete + BT-002 cascade CLOSED at this layer 2026-05-18 + downstream pending" framing.

### Verdict

- [ ] ✅ **Ready for Implementation Execution** — 1 CRITICAL working-tree violation + 4 HIGH narrative-propagation/state-reconciliation gaps surface at next-finer-granularity layers (within-rebuttal-commit-narrative-propagation axis; secondary-SoT asymmetric-row layer); requires rebuttal-pass for canonical closure
- [x] ⚠️ **Needs Rebuttal Round** — 1 CRITICAL (Gate #11 working-tree) + 4 HIGH (TL;DR Last-updated stale + Sentinel/Closure Hygiene narrative-propagation gap + Mid-Phase Audit Log missing R16 row + overview.md row 19 asymmetric pre-cascade-closure framing) + 1 MEDIUM (Mid-Phase Audit Log L2237 pre-existing chronological mismatch per R16 §16.5 explicit scope-out) + 1 LOW (18 .bak files untracked from `/project-init --regen`). Run `/impl-plan-rebuttal claim-review-17.md`. Mirror R12/R13 verify-pass cycle after R11 BT-001 cascade drain at BT-002 magnitude — same "rebuttal commit narrative didn't propagate its own closure to canonical first-impression surfaces" defect class observed across cascade-drain cycles. Expected ~10-15 in-place edits (~80-120 LOC narrative) + 1 commit-execution step + 4 untracked review-doc git-add + decision on .bak file disposition.
- [ ] ⛔ **Immediate Attention** — no fundamental scope flaw; all R17 findings are cascade-completion residue at sub-section / commit-discipline / asymmetric-narrative layers

> **Rebuttal scope guidance:** (1) Execute the R15 + R16 rebuttal commits per Gate #11 discipline — `git add` the 4 untracked review/rebuttal .md files + 2 M files + decide .bak disposition (commit as audit ledger / .gitignore / delete) + commit with `[BT-002 cascade]` style message citing R15+R16 closure (Claim 17.1). (2) Update TL;DR L101 `Last updated:` lead clause to cite R16 6/6 Accept verify-pass closure 2026-05-18 + preserve R15 12/12 Accept as prior-action subordinate clause per R14 §14.6 lead-clause discipline (Claim 17.2). (3) Update Plan Staleness Sentinel L2349 `Last review on:` to list R16 + append R16 6/6 Accept narrative; update Closure Hygiene Status L2363-2365 three lines to cite R15 + R16 (Plan Staleness Sentinel + Phase 5 mechanical gates sweep refreshed post-R16; State Reconciliation 3-file rule honored post-R15+R16 with R16 closing Tier 3 handoff layer per §16.3 fix) (Claim 17.3). (4) Add Mid-Phase Audit Log row for R16 rebuttal closure 2026-05-18 (`R16 6/6 Accept — BT-002 cascade-residue drain across IMPL-051 task block + P4 Phase Gate L1412 walk row + current_handoff.md Tier 3 + IMPL-FIX-012 Status chronological reorder + Mid-Phase Audit Log row reposition + L2254/L2255 line-anchor brittleness re-anchor`) (Claim 17.4). (5) Update overview.md row 19 Impl Plan to cite "✅ R15+R16 BT-002 impl-plan-layer cascade CLOSED 2026-05-18 — 12/12 + 6/6 Accept; downstream cascade pending: TD review + impl-code cleanup + IMPL-062 re-execute" mirror BA/SD row pattern (Claim 17.5). (6) Optionally reposition Mid-Phase Audit Log L2237 IMPL-061+064+068 row per R16 §16.5 explicit-scope-out residue (Claim 17.6). (7) Decide .bak file disposition + commit/gitignore (Claim 17.7). Likely 7/7 Accept verify-pass pattern (no rejected claims expected; all are commit-discipline / narrative-propagation closures).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Phase shape unchanged since R01–R16; rationale + Phase % targets ครบ; BT-002 cascade did not affect Phase Shape Choice |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean (H=68, A=67, D=1, V=0, N=0); confirmation note + scratch table L2266+ preserved post-R16 |
| 3 | Task Decomposition & Sizing | ✅ Pass | No changes from R16; IMPL-051 + IMPL-FIX-012 task-block annotations preserve Phase × Size matrix denominator per audit-history discipline |
| 4 | AC — Dual-Track Compliance | ✅ Pass | IMPL-051 E-AC L903 `[x] ~~original~~ — Superseded by BT-002` properly applied per R16 §16.1 fix; IMPL-FIX-012 E-AC #1/#2 superseded annotations preserved from R15 §15.8 |
| 5 | Phase Gates — Testable Exit | ✅ Pass | P4 Phase Gate L1411 Empirical Demo + L1412 Tier 1.5 Walk + L1416 NFR-1.1 sub-row all uniformly post-BT-002 framed via R15 §15.6 + R16 §16.2 joint drain |
| 6 | Deferred-AC Registry Init | ✅ Pass | Registry empirical recount (Gate #2): 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = **55 Active rows** ✅ matches TL;DR L100 + **8 Resolved rows** ✅ matches L100 claim |
| 7 | Cross-Phase Dependency | ✅ Pass | 0 forward refs; sub-ticket↔parent convention preserved; Mermaid Phase × Size matrix unchanged |
| 8 | State-File Consistency | ⚠️ Findings 17.1 + 17.2 + 17.3 + 17.4 + 17.5 | R15 §15.1 primary inversion gap stays CLOSED via R15 + R16 cascade drain. 5 NEW reconciliation gaps surface at within-rebuttal-commit-narrative-propagation axis: (a) Gate #11 working-tree NOT clean post-R16 narrative-authored-but-uncommitted (17.1); (b) TL;DR Last-updated lead clause cites R15 only post-R16 (17.2); (c) Plan Staleness Sentinel + Closure Hygiene Status three lines cite R15 only post-R16 (17.3); (d) Mid-Phase Audit Log missing R16 closure row (17.4); (e) `overview.md` row 19 Impl Plan asymmetric vs BA row 9 + SD row 10 post-R15/R16 (17.5) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4/month-year schedule leakage in SD-hint copies; absolute dates (2026-05-17/18) are working-paper-dates allowed per R10 disposition + BT-001/BT-002 cascade precedent |
| 10 | Readability — Reader Empathy | ⚠️ Finding 17.6 | Mid-Phase Audit Log L2237 (2026-05-04 IMPL-061+064+068 between 2026-05-05 IMPL-017+066+067 row L2236 + 2026-05-05 Code Review Round 15 row L2238) chronologically out-of-order; pre-existing per R16 §16.5 explicit scope-out — surfaces during R17 verify-pass sweep as audit-log-internal residue. (Dim #10 audit-trail readability) |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 17.1: 🔴 CRITICAL — Gate #11 working-tree NOT clean post-R15/R16 rebuttal narratives — R15 + R16 closure narratives both claim "applied + verified" but commits never executed; `git status --short` returns 2 M files (impl-plan.md + current_handoff.md) + 4 untracked review/rebuttal .md files (claim-review-15.md + claim-review-16.md + rebuttal-round-15.md + rebuttal-round-16.md) + 18 untracked .bak files from `/project-init --regen` 2026-05-18; R17 entry surfaces the violation that R16 §11 narrative explicitly advertised as "pending"

**Location:** Working-tree state (verified via `git status --short`):

```
 M docs/state/current_handoff.md
 M docs/state/impl-plan.md
?? .claude/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/security.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .claude/stack.json.bak-2026-05-18T02-26-01Z
?? .codex/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/security.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/security.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/security.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? AGENTS.md.bak-2026-05-18T02-26-01Z
?? CLAUDE.md.bak-2026-05-18T02-26-01Z
?? docs/state/impl-plan-claim-review-and-rebuttal/claim-review-15.md
?? docs/state/impl-plan-claim-review-and-rebuttal/claim-review-16.md
?? docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-15.md
?? docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-16.md
```

**Problem:**

Per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates § Gate #11`:

> "`git status --porcelain | wc -l` after fix-round / task closure → exit count `0` (all artefacts referenced in fix-round narrative + closure tables — code, evidence sidecars, walk-batch logs, review/fix-round docs — are committed). Untracked review-round / fix-round / evidence files explicitly disallowed (R16 § 16.2 audit-trail gap)"

Both R15 + R16 rebuttal narratives claim closure ("**Verdict:** Accept" across all 12 + 6 claims; "**Files modified:** `impl-plan.md` (...) + `current_handoff.md` (...)") but the commits never executed:

- **R15 rebuttal narrative** (`rebuttal-round-15.md`) advertises 11+ surface edits across impl-plan.md (TL;DR L97 + Phase Status L118 + Open Risks R-3/R-13 + Next Best Action L199-201 + Phase Gate P4 + IMPL-051 task block + IMPL-FIX-012 task block + Mid-Phase Audit Log 9 new rows + Closure Hygiene Status + Plan Staleness Sentinel) — all marked as "applied"
- **R16 rebuttal narrative** (`rebuttal-round-16.md`) advertises 6 surface edits across impl-plan.md (IMPL-051 L903/L905/L906 + P4 Phase Gate L1412 + IMPL-FIX-012 Status reorder + Mid-Phase Audit Log L2250 reposition + L2254/L2255 re-anchor) + 1 lead-block rewrite in current_handoff.md — all marked as "applied"
- **Working-tree empirical evidence**: 2 .md files modified-but-unstaged + 4 review/rebuttal docs untracked + 18 .bak files untracked

The R16 §11 Closure Hygiene Status `Phase 5 mechanical gates` line explicitly advertises: `**+ Gate #11** (working-tree clean post-commit pending final verification)` — acknowledging the gap was not closed at R16 narrative-authoring time but expected to close before R17. Operator instead launched `/impl-plan-review all` (this round) BEFORE the commit landed → Gate #11 violation surfaces at R17 entry boundary.

The 4 untracked review/rebuttal .md files are the EXACT defect class enumerated in `workflow.md § Phase 5 Gate #11` body: "Untracked review-round / fix-round / evidence files explicitly disallowed (R16 § 16.2 audit-trail gap)." R16 §16.2 + fix-round-15 §16.2 documented this defect class at the source-tree level for code reviews; same class now surfaces at the impl-plan-review-cycle layer.

The 18 .bak files from `/project-init --regen` are a secondary working-tree pollution class — methodology-infra timestamped backup artefacts left untracked after regen. Per Gate #11 audit contract, these need disposition: (a) commit as backup-artifact ledger (rare), (b) add to `.gitignore` as method ephemera (common), or (c) delete after regen verification.

**Why this matters:**

1. **R15 + R16 review/rebuttal closure narratives are reader-side stale** — engineer reading `git log` to verify R15+R16 closure sees commits `7ff6f43` (project-init regen) + `47381a9` (path modernization) + `538e990` (BT-002 closed) but NO R15 or R16 impl-plan-rebuttal commits. The 4 review/rebuttal .md docs cannot be referenced by SHA → defeats `claim-review-XX.md` audit-trail discipline. Same root cause as fix-round-15 §16.2 → R16 §16.2 chain at source-code Gate #11 layer

2. **`/impl-task` next invocation HALTS at R17 entry** — `/impl-task` Phase 1 reads `impl-plan.md` last-modified-time + cross-checks against committed SHA per workflow.md cold-bootstrap recipe. Working-tree shows impl-plan.md M (modified-but-unstaged) → `/impl-task` cannot proceed without operator commit-or-revert decision

3. **`/next` Check 5.5 (State SoT consistency)** dispatches handoff guidance based on impl-plan.md as primary SoT; current state = working-tree modified but uncommitted → reader-side state is ambiguous (HEAD = stale; working-tree = R15+R16 narrative-applied but unverified-by-commit-SHA)

4. **`/deliver` Phase 5 readiness check** blocks shipping when registry rows Active OR working-tree dirty per workflow.md Gate #11 audit contract — current state blocks `/deliver` regardless of R15+R16 cascade-drain claim narratives

5. **Forensic traceability of BT-002 closure chain** depends on R15 + R16 review/rebuttal docs being committed at canonical SHAs that backtrack-log.md can cite — current state leaves the impl-plan-side closure chain orphaned in working-tree only

**Minimum acceptable fix (R17 rebuttal sequence):**

```bash
# Step 1 — commit R15 + R16 review/rebuttal docs + state mods + .bak disposition decision
git add docs/state/impl-plan-claim-review-and-rebuttal/{claim-review-15,claim-review-16,rebuttal-round-15,rebuttal-round-16}.md
git add docs/state/impl-plan.md docs/state/current_handoff.md

# Step 2 — .bak file disposition (operator choice; reviewer recommends Option B):
#   Option A: commit as audit ledger
#     git add *.bak-* .claude/**/*.bak-* .codex/**/*.bak-* .trae/**/*.bak-* .windsurf/**/*.bak-*
#   Option B (RECOMMENDED): add to .gitignore as method ephemera
#     echo "*.bak-2026-*" >> .gitignore && git add .gitignore
#   Option C: delete after regen verification
#     rm -f *.bak-* .claude/**/*.bak-* .codex/**/*.bak-* .trae/**/*.bak-* .windsurf/**/*.bak-*

# Step 3 — commit R15+R16 cascade-drain closure (apply R17 rebuttal edits FIRST per Claims 17.2-17.5, then single commit)
git commit -m "[BT-002 cascade] R15 + R16 + R17 impl-plan-rebuttal cascade-drain CLOSED 2026-05-18

R15 12/12 Accept (4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 11+ surface drain).
R16 6/6 Accept (3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass).
R17 N/N Accept (1 CRITICAL Gate #11 commit + 4 HIGH narrative-propagation + 1 MEDIUM + 1 LOW).

Closes BT-002 cascade at impl-plan layer; downstream cascade pending per
backtrack-log.md § BT-002 § Resolution L71: TD review + impl-code cleanup + IMPL-062 re-execute."

# Step 4 — verify Gate #11 clean post-commit
git status --porcelain | wc -l  # MUST return 0
```

Optionally bundle R17 commit alongside R15+R16 if R17 rebuttal lands in same session (mirror BT-001 R12→R13 verify-pass chain where verify-only rounds were bundled with originating rebuttal commit). Engineer-dispositive on commit-granularity.

**Effort:** Low for commit execution itself (~2 min); Low for .gitignore disposition (~5 min). Total ~10 min including post-commit Gate #11 verification + git log inspection.

---

### 🟠 HIGH

#### Claim 17.2: 🟠 HIGH — `impl-plan.md` TL;DR L101 `Last updated:` lead clause cites "R15 12/12 Accept" as last action; doesn't mention R16 6/6 Accept verify-pass closure 2026-05-18; same defect class as R15 §15.1 originating gap (canonical first-impression skim block stale post-rebuttal-commit) but at within-rebuttal-commit-narrative-propagation layer (10th meta-axis per Recurring Weaknesses chain)

**Location:** `docs/state/impl-plan.md` L101 (TL;DR Last-updated lead block):

`"**Last updated:** 2026-05-18 · last action: **📝 `/impl-plan-rebuttal claim-review-15.md` ✅ CLOSED 2026-05-18 — R15 12/12 Accept (4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer).** Cascaded with **BT-002 ✅ CLOSED 2026-05-18** ..."`

R16 6/6 Accept closure (2026-05-18) is NOT mentioned in the lead clause; the entire prior-action enumeration cites "(fix-round-26 2026-05-17) → (IMPL-FIX-012 iter-3 2026-05-17) → (IMPL-FIX-012 iter-2 2026-05-17) → (IMPL-FIX-012 iter-1 2026-05-14) → (IMPL-062 Run #3) → ..." but omits the R16 verify-pass round entirely.

**Problem:**

Per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates § Gate #4 + Gate #8`:

> "**Gate #4 Sentinel counter increment**: After closing task, bump `Plan Staleness Sentinel § Closures since last review` by +1 atomically with TL;DR `Last updated:` rewrite | counter = (post-review closures); section + TL;DR self-flag agree"
>
> "**Gate #8 Narrative-section freshness sweep**: Re-read `## Open Risks` (each R-N row) + `## Next Best Action` checklist; rewrite or strikethrough rows whose claims are invalidated by this closure"

Per CLAUDE.md §6 State Reconciliation Discipline:

> "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal → propagate state 3 ชั้น: (1) `impl-plan.md` (primary), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*`. ห้าม update เพียงไฟล์เดียว"

R16 rebuttal closure → fired Gate #4 (Sentinel — counter UNCHANGED at 1 per workflow.md Gate #4 rebuttal-exception; correctly handled per rebuttal-16 §Cascaded #7) BUT ALSO required atomic `TL;DR Last updated:` rewrite per Gate #4 even when counter is unchanged. The Gate #4 audit contract says counter increment AND TL;DR rewrite are paired atomically; rebuttal-closures-don't-increment-counter exception applies to the COUNTER only, not to the `Last updated:` lead clause.

Per R14 §14.6 explicit precedent (lead-clause refresh discipline): R14 reviewer + defender established that R10 §10.6 lead-fields = canonical-current rule applies to TL;DR `Last updated:` lead clause: lead clause cites most-recent action canonically; prior-action enumeration follows as subordinate clauses. R16 rebuttal commit applied per-surface edits (IMPL-051 + P4 Phase Gate + IMPL-FIX-012 + audit-log moves + cite re-anchors) but did NOT update the TL;DR canonical-current pointer to reflect R16 itself as the latest action.

Same defect class as R15 §15.1 originating inversion gap (TL;DR canonical-current vs backtrack-log lifecycle SoT divergence) but at next-meta-axis layer (10th axis): **within-rebuttal-commit-narrative-propagation** — the R16 rebuttal commit propagated BT-002 cascade-residue closure to per-section edits but did NOT propagate the R16 closure itself to the TL;DR canonical-current pointer that names the latest action. Reader skimming TL;DR sees R15 as the most-recent action and infers no rebuttal has run since.

**Why this matters:**

1. **Canonical first-impression skim signal stale** (Dim #10 reader empathy) — engineer reading TL;DR L101 first per CLAUDE.md §6 Agent Workflow Rules sees R15 12/12 Accept as the last action; infers R16 has not run; status-agent dashboards rendering TL;DR `Last updated:` as canonical first-impression signal display R15 as latest; Tech Lead skim test fails

2. **`/next` Check 5.7 backlog reader** reads handoff + TL;DR Last-updated for current-state context; current state = TL;DR cites R15 only → `/next` recommends `/impl-plan-rebuttal claim-review-16.md` as next action OR mis-routes per stale anchor

3. **Same recurring weakness pattern as R14 §14.6 (TL;DR 3 rebuttal rounds behind) + R15 §15.1 (BT-002 canonical-block-vs-narrative-prose drift)** at next-meta-axis — defect-class progression chain now at **10th axis: within-rebuttal-commit-narrative-propagation**. Each round's narrower-than-defect-class fix surfaces next-finer surface at next review (mirror R20→R23 source-code Gate #9 chain at impl-plan meta-layer)

**Minimum acceptable fix:**

L101 lead-clause rewrite (mirror R14 §14.6 lead-clause refresh pattern at R16-as-latest layer; preserve R15 + prior-action enumeration verbatim as subordinate clauses):

```markdown
> **Last updated:** 2026-05-18 · last action: **📝 `/impl-plan-rebuttal claim-review-16.md` ✅ CLOSED 2026-05-18 — R16 6/6 Accept (3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass round after R15 BT-002 cascade drain — intra-task-block + intra-Phase-Gate-block + 3-file-tier-3 asymmetries surviving R15 narrow scope drained + IMPL-FIX-012 Status chronological reorder + Mid-Phase Audit Log row reposition + L2254/L2255 line-anchor brittleness re-anchor).** Cascaded with R17 verify-pass round predicted clean per cascade-completion termination at all known layers post-R16 §16.3 third-tier handoff fix. · prior action (2026-05-18 R15 cascade drain): **📝 `/impl-plan-rebuttal claim-review-15.md` ✅ CLOSED 2026-05-18 — R15 12/12 Accept (4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer).** Cascaded with **BT-002 ✅ CLOSED 2026-05-18** ... [preserve remaining lead-clause narrative verbatim from current L101] ...
```

**Effort:** Low (1 lead-clause refresh preserving all prior narrative + enumeration verbatim per R14 §14.6 lead-clause discipline; ~30-50 LOC narrative).

---

#### Claim 17.3: 🟠 HIGH — `impl-plan.md` Plan Staleness Sentinel L2349 `Last review on:` + Closure Hygiene Status L2363-2365 three lines all cite R15 only post-R16 closure; R16 rebuttal commit applied per-surface edits but did NOT propagate R16 closure to canonical Sentinel + Closure Hygiene narrative — same defect class as Claim 17.2 at canonical-hygiene-tracking layer

**Location:** `docs/state/impl-plan.md` L2349 (Plan Staleness Sentinel) + L2363-2365 (Closure Hygiene Status):

- L2349: `"**Last review on:** 2026-05-18 — `claim-review-15.md` + `rebuttal-round-15.md` (R15 12/12 Accept — 4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer; IMPL-FIX-012 → close-by-BT-002 supersession + IMPL-051 → cancel-by-BT-002 + ADR-013/014 Superseded annotations propagated). Prior 2026-05-13 ..."` — R16 NOT listed in latest-review enumeration
- L2363 (Closure Hygiene Plan Staleness Sentinel line): `"...**Last review 2026-05-18 = R15 BT-002 cascade drain** + prior R14 verify-pass 2026-05-13 + ..."` — R16 NOT listed
- L2364 (Closure Hygiene Phase 5 mechanical gates line): `"Gates #1-#11 — sweep refreshed 2026-05-18 post-R15 rebuttal commit (BT-002 cascade drain across 11+ surfaces). **R15 explicitly exercised Gate #1** ... + Gate #2 ... + Gate #5 ... + Gate #6 ... + Gate #7 ... + Gate #8 ... + Gate #9 clause (a)-(i) ... + Gate #10 ... + Gate #11 (working-tree clean post-commit pending final verification)..."` — R16 NOT listed; Gate #11 explicitly advertised as "pending final verification" (the originating defect class for Claim 17.1)
- L2365 (Closure Hygiene State Reconciliation 3-file rule line): `"impl-plan.md (primary SoT) ↔ overview.md (derived count + phase status) ↔ {module}/handoff.md + `_session-handoff/*` — **honored post-R15 rebuttal commit (BT-002 cascade drained at primary SoT — closes the inversion gap where overview.md was ahead of impl-plan.md per R15 §15.1)**. R14 §13.1+ §13.2 closures preserved..."` — R16 closing Tier 3 handoff layer per §16.3 NOT mentioned

**Problem:**

R16 rebuttal §Cascaded Changes #4 explicitly claimed: "**State Reconciliation 3-file rule (CLAUDE.md §6) fully restored across all 3 tiers** — Tier 1 (`impl-plan.md`) closed via R15 cascade drain at primary SoT layer; Tier 2 (`overview.md`) already canonical per BT-002 SD cascade row 19 narrative; Tier 3 (`current_handoff.md`) closed via R16 §16.3 Last completed action lead-block rewrite. Defect-class progression chain (R15 §15.1 originating inversion gap → R16 §16.3 third-tier residue) terminated at handoff layer."

But the Closure Hygiene Status L2365 line reads `"honored post-R15 rebuttal commit (BT-002 cascade drained at primary SoT — closes the inversion gap where overview.md was ahead of impl-plan.md per R15 §15.1)"` — citing only R15 + R15 §15.1; R16 §16.3 Tier 3 closure NOT mentioned. Reader inferring 3-file rule status from Closure Hygiene Status alone would conclude only Tier 1 was closed.

Same defect class as Claim 17.2 at next-finer hygiene-tracking layer:
- TL;DR `Last updated:` = canonical first-impression skim (Claim 17.2)
- Plan Staleness Sentinel `Last review on:` = canonical review-cycle tracker (this claim subset 1)
- Closure Hygiene Status 3 lines = canonical 3-line hygiene skim block per R10 §10.6 (this claim subsets 2/3/4)

R16 rebuttal commit applied per-surface edits but did NOT propagate the R16 closure narrative to canonical hygiene-tracking surfaces. Same root cause as Claim 17.2 (within-rebuttal-commit-narrative-propagation axis) at 4 additional surfaces.

**Why this matters:**

1. **Sentinel L2349 + Closure Hygiene L2363-2365 are canonical hygiene-tracking surfaces** — reviewer running `/impl-plan-review all` (mirror this round) reads Closure Hygiene Status to verify Gate #1-#11 sweep status; current state misleads reviewer into believing Gate #1-#11 was R15-applied not R16-applied (R16 explicitly exercised Gates #1-#8 again per rebuttal-16 §Strength Assessment — but L2364 only cites R15 sweep)

2. **`/next` Check 5.5 (State SoT consistency)** reads Plan Staleness Sentinel for review-cadence guidance; "Last review on: R15" framing implies R16 has not run + recommends R16 as next action OR mis-routes per stale anchor

3. **State Reconciliation 3-file rule documentation drift** — L2365 cites only R15 §15.1 closure; future R18 reader inferring 3-file rule status would not see R16 §16.3 Tier 3 fix. Per CLAUDE.md §6 + Glossary § State SoT discipline, the 3-file rule's audit trail MUST cite all reconciliation closures — R16 §16.3 is the canonical Tier-3-closure event that the L2365 line should anchor to

4. **Same recurring weakness pattern as R14 §14.2/§14.6 + R15 §15.11/§15.12 + R16 §15.13 (Closure Hygiene Status refresh discipline)** at next-meta-axis — each round, the Closure Hygiene Status block reads N-1 rounds behind because per-surface edits land but canonical-hygiene-tracking surfaces don't get the latest-round annotation

**Minimum acceptable fix:**

L2349 (Plan Staleness Sentinel `Last review on:`) prepend R16 entry:

```markdown
**Last review on:** 2026-05-18 — `claim-review-16.md` + `rebuttal-round-16.md` (R16 6/6 Accept — 3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass round after R15 BT-002 cascade drain — intra-task-block IMPL-051 supersession + intra-Phase-Gate-block P4 L1412 walk-row + 3-file rule Tier 3 handoff layer + IMPL-FIX-012 Status chronological reorder + Mid-Phase Audit Log row reposition + L2254/L2255 line-anchor brittleness re-anchor; cascade-completion termination predicted at all known layers post-R16 §16.3 third-tier handoff fix). Prior 2026-05-18 `claim-review-15.md` + `rebuttal-round-15.md` (R15 12/12 Accept — 4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer; IMPL-FIX-012 → close-by-BT-002 supersession + IMPL-051 → cancel-by-BT-002 + ADR-013/014 Superseded annotations propagated). Prior 2026-05-13 ... [preserve remaining enumeration verbatim] ...
```

L2363 (Closure Hygiene Plan Staleness Sentinel) — replace `"**Last review 2026-05-18 = R15 BT-002 cascade drain**"` with `"**Last review 2026-05-18 = R16 cascade-residue verify-pass (6/6 Accept) + R15 BT-002 cascade drain (12/12 Accept)**"`.

L2364 (Closure Hygiene Phase 5 mechanical gates) — replace `"sweep refreshed 2026-05-18 post-R15 rebuttal commit"` with `"sweep refreshed 2026-05-18 post-R16 rebuttal commit (cascade-residue 6 surface drain) + prior post-R15 rebuttal commit (BT-002 cascade drain across 11+ surfaces)"`; append `"**R16 explicitly exercised Gate #1** (forbidden-pattern grep — 1 sanctioned false-positive ✅ unchanged from R15 baseline) **+ Gate #2** (TL;DR ↔ registry recount — 55 Active rows unchanged from R15 baseline) **+ Gate #7** (Phase Status Snapshot Notes sweep — P4 Notes unchanged; cascade-residue handled at task-block + Phase Gate-row layers not Phase Status row layer) **+ Gate #8** (narrative-section freshness sweep — IMPL-051 L903/L905/L906 + P4 Phase Gate L1412 + current_handoff.md L7) **+ Gate #9 clause (h)** (line-anchor brittleness rule — L2254/L2255 symbolic-anchor re-anchor + Claim 16.6 Option A preemptive sibling)."`

L2365 (Closure Hygiene State Reconciliation 3-file rule) — replace `"honored post-R15 rebuttal commit (BT-002 cascade drained at primary SoT — closes the inversion gap where overview.md was ahead of impl-plan.md per R15 §15.1)"` with `"**fully restored across all 3 tiers post-R15+R16 rebuttal commits**: Tier 1 (impl-plan.md) closed via R15 cascade drain at primary SoT layer (R15 §15.1 originating inversion gap resolved); Tier 2 (overview.md) already canonical per BT-002 SD cascade row 19 narrative — explicit R16 reviewer scope-out at Cross-Document Issues table; Tier 3 (current_handoff.md L7 Last completed action lead-block) closed via R16 §16.3 rewrite. Defect-class progression chain terminated at handoff layer."`

**Effort:** Low (4 narrative-line refreshes preserving all prior content verbatim per R10 §10.6 strikethrough-append discipline; ~80-100 LOC narrative across 4 surfaces).

---

#### Claim 17.4: 🟠 HIGH — `impl-plan.md` Mid-Phase Audit Log missing row for R16 impl-plan-rebuttal closure 2026-05-18; per CLAUDE.md §6 + workflow.md Gate #4 ("ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal"), R16 rebuttal closure should have added new audit-log row; defect-class progression — R15 added 9 audit-log rows per §15.10 narrative but R16 added 0 rows for its own closure (only modified existing L2254/L2255 cite re-anchors via §16.6)

**Location:** `docs/state/impl-plan.md` Mid-Phase Audit Log table L2186 onwards. Grep verification:

```bash
grep -nE 'R16|claim-review-16|rebuttal-round-16' docs/state/impl-plan.md
# Returns only:
# L1412 (P4 Phase Gate Tier 1.5 walk row — Claim 16.2 fix; not audit-log row)
# L1988 (IMPL-FIX-012 chronological reorder invariant comment — Claim 16.4 fix; not audit-log row)
# L2184 (Audit-history preservation note — references workflow.md "R16 strengthening" for code-review round 16 / fix-round 16, NOT impl-plan claim-review round 16)
# L2239 (Mid-Phase Audit Log row for "Code Review Round 16 + Fix Round 16 closed" — code-review round counter, NOT impl-plan claim-review round)
# L2254 + L2255 (Mid-Phase Audit Log evidence-pointer re-anchor — Claim 16.6 fix; not new R16 closure row)
```

**Zero** Mid-Phase Audit Log rows exist for the R16 impl-plan-rebuttal closure 2026-05-18 itself.

**Problem:**

R15 rebuttal added 9 new Mid-Phase Audit Log rows per §15.10 narrative (visible at L2249-L2260: 4 BT-002 cascade events + commit-chain rows + R15 closure row). R16 rebuttal narrative (`rebuttal-round-16.md`) lists **Files modified:** `impl-plan.md` (6 surface edits)` enumeration including "Mid-Phase Audit Log L2250 reposition + L2254/L2255 evidence-pointer re-anchor" — both are EDITS to existing rows, NOT a new R16 closure row.

Per CLAUDE.md §6 Agent Workflow Rules + State Reconciliation 3-file rule:

> "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update ทั้ง 3 ชั้น: (1) `impl-plan.md` (primary SoT — `[x]` AC, Phase Gate, **audit log**, audit log), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*` (transient pointer + artifact)."

Per workflow.md `## Mid-Phase Audit Log` purpose statement:

> "Engineer logs mid-phase findings, fix-rounds, and impl-plan rebuttals here — primary audit trail per CLAUDE.md §6 State SoT"

R16 closure = impl-plan rebuttal closure → MUST log row in Mid-Phase Audit Log per CLAUDE.md §6 + Mid-Phase Audit Log purpose statement. R15 §15.10 narrative correctly added rows for R15 closure + cascade events. R16 narrative documented per-surface edits but missed the canonical R16-closure-itself audit-log row.

Same defect class as Claim 17.2/17.3 (within-rebuttal-commit-narrative-propagation axis) at canonical-audit-trail-row layer.

**Why this matters:**

1. **Audit-trail completeness gap** — `/impl-plan-review` next-round-reader (mirror R17 this round) reads Mid-Phase Audit Log to enumerate closure events since last review; current state shows 0 rows for R16 → reviewer infers R16 has not run + recommends R16 as next action OR mis-routes per stale anchor

2. **Forensic traceability** — auditor reconstructing BT-002 cascade-drain chain from impl-plan.md alone would see R15 closure row at L2260 but NO R16 closure row → infers R15 was the terminal cascade-drain event; misses R16's role in closing IMPL-051 sibling task supersession + Tier 3 handoff layer + IMPL-FIX-012 chronological reorder

3. **Same recurring weakness pattern as R14 §14.6 (TL;DR + Sentinel + Closure Hygiene Status not refreshed at canonical surfaces post-rebuttal commit)** at next-finer audit-trail-row layer — defect-class progression chain now extends to the 5th surface within Claim 17.2/17.3 cluster: TL;DR + Sentinel + Closure Hygiene 3 lines + Mid-Phase Audit Log row

**Minimum acceptable fix:**

Append new row to Mid-Phase Audit Log table (insertion point: after L2260 R15 closure row, mirror R15 §15.10 row format):

```markdown
| 2026-05-18 | — | **R16 `/impl-plan-rebuttal claim-review-16.md` ✅ CLOSED — 6/6 Accept (3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue verify-pass round after R15 BT-002 cascade drain)** | impl-plan.md (IMPL-051 task block L903 E-AC supersession + L905 Risk + L906 ADR annotations + P4 Phase Gate L1412 Tier 1.5 walk row instruction (3) rewrite + IMPL-FIX-012 Status chronological reorder L1986-L1996 + invariant comment L1988 + Mid-Phase Audit Log L2250→L2235 reposition + L2254/L2255 evidence-pointer symbolic-anchor re-anchor per Gate #9 clause (h)), current_handoff.md (L7 Last completed action lead-block rewrite + strikethrough-preserve prior 2026-05-17 framing per R10 §10.6) | Reviewer + Defender: Opus 4.7. 6 findings drained: 3 HIGH (16.1 IMPL-051 intra-block asymmetry post-BT-002 cascade + 16.2 P4 Phase Gate L1412 pre-BT-002 walk-row framing + 16.3 current_handoff.md L7 stale anchor / 3-file rule Tier 3) + 2 MEDIUM (16.4 IMPL-FIX-012 Status chronological reorder + 16.5 Mid-Phase Audit Log L2250 chronological reposition) + 1 LOW (16.6 L2253→L2255 line-anchor brittleness Option A re-anchor + preemptive L2254 sibling). State Reconciliation 3-file rule fully restored across all 3 tiers (R15 closed Tier 1; Tier 2 already canonical per BT-002 SD cascade; R16 §16.3 closed Tier 3 handoff layer). Symmetric post-BT-002 closure narrative across BT-002-impacted task pair (IMPL-051 sibling + IMPL-FIX-012 main both fully drained). Intra-Phase-Gate-block annotation symmetry restored at P4 Phase Gate (L1411 + L1412 + L1416 all post-BT-002 framed). Audit-trail chronological discipline restored at IMPL-FIX-012 task-block (5-row reorder + invariant comment) + Mid-Phase Audit Log internal (1-row move). Gate #9 clause (h) line-anchor brittleness rule extended to audit-log meta-document layer with future Gate #9 clause (j) candidate surfaced for `/update-config` ticket. Plan Staleness Sentinel UNCHANGED at 1 (R16 rebuttal closure is engineer-side rework cycle per workflow.md Gate #4 + fix-round-10 precedent — only IMPL-NNN main task closures increment counter). |
```

**Effort:** Low (1 new audit-log row append at L2261 mirror R15 §15.10 row format; ~30-50 LOC narrative).

---

#### Claim 17.5: 🟠 HIGH — `overview.md` row 19 "Impl Plan" status reads pre-R15/R16-closure framing `"❌ Invalidated (BT-002 — ... re-run /impl-plan-review all post-SD lock)"` while row 9 "Design (BA)" + row 10 "Design (SD)" both flipped to `"✅ Complete + BT-002 cascade CLOSED 2026-05-18"` post-cascade-closure; asymmetric narrative pattern at secondary-SoT layer; same defect class as R15 §15.1 originating gap (BA/SD canonical-current vs Impl Plan stale framing) but at row-level layer post-R15+R16 cascade drain

**Location:** `docs/state/overview.md` rows 9/10/19:

- **Row 9 (Design BA):** `"✅ **Complete + BT-002 cascade CLOSED 2026-05-18 (Round 06 first-sweep 1 LOW + rebuttal-round-05 1 accept = ready for Architecture Handoff)** · prior: ⚠️ Pending re-validation (BT-002 chained `/backtrack ba`) · pre-BT-002: ✅ Complete + Round 05 (post-BT-001 cascade clean) · pre-BT-001: ✅ Complete + Rebuttal Round 02"`
- **Row 10 (Design SD):** `"✅ **Complete + BT-002 cascade CLOSED 2026-05-18 — SD 3-round chain (R07→rebuttal-05→R08→rebuttal-06→R09 0 findings 2026-05-17) + BA 1-cycle chain (R06 1 LOW→rebuttal-05 closed 2026-05-18); BT-002 Status flipped 🔄 Open → ✅ Closed in backtrack-log.md (commit chain `aebec01`→`0be2a51`→`111f092`→`32c56c0`→`e385ad0`→`863493e`→BA rebuttal+closure)**. Prior ..."`
- **Row 19 (Impl Plan):** `"❌ **Invalidated (BT-002 — 2026-05-17 escalation gate executed; cap-3 budget exhausted at IMPL-FIX-012 iter-3 Run #5; IMPL-051 → cancel-by-BT-002, IMPL-FIX-012 → close-by-BT-002 supersession; re-run `/impl-plan-review all` post-SD lock)** · prior: 🔴 ..."`

**Problem:**

Row 19 Impl Plan status field tells the reader: "re-run `/impl-plan-review all` post-SD lock" — that recommendation has been EXECUTED twice: R15 (`claim-review-15.md` + `rebuttal-round-15.md` 12/12 Accept) + R16 (`claim-review-16.md` + `rebuttal-round-16.md` 6/6 Accept). Both rounds ran post-SD-Round-09 closure (commit `e385ad0` 2026-05-17). The "re-run" recommendation is canonically OBSOLETE.

Per the BA + SD row precedent (both flipped to `"✅ Complete + BT-002 cascade CLOSED 2026-05-18"`), the Impl Plan layer of the BT-002 cascade ALSO closed at the impl-plan layer:
- BA closed at Round 06 first-sweep 1 LOW + rebuttal-05 1 Accept
- SD closed at Round 09 verify-only 0 findings (after Round 07 + rebuttal-05 + Round 08 + rebuttal-06 chain)
- Impl Plan closed at R15 12/12 Accept + R16 6/6 Accept verify-pass

Yet the Impl Plan row reads pre-cascade-closure framing identical to its 2026-05-17 baseline. Rebuttal-16 §Cascaded Changes #11 explicitly declined to update overview.md citing "substantive downstream work pending (TD review + impl-code cleanup + IMPL-062 re-execute) per `backtrack-log.md § BT-002 § Resolution` L71 enumeration; status flip from ❌ → ✅ Re-validated occurs when all downstream BT-002 work completes, not at R16 rebuttal closure."

But this conflates two distinct cascade layers:
1. **Impl-plan-layer cascade** = ✅ CLOSED 2026-05-18 via R15 + R16 (analogous to BA closure via Round 06 + rebuttal-05; SD closure via Round 09)
2. **Downstream cascade** = pending (TD + impl-code cleanup + IMPL-062 re-execute)

The Impl Plan row should distinguish (1) from (2) — mirror BA + SD rows' "✅ Complete + BT-002 cascade CLOSED at this layer 2026-05-18 + downstream pending" framing. The status flip to ✅ at the impl-plan layer does NOT depend on downstream work completing (per BA + SD row precedent — both flipped to ✅ despite TD/Impl-Code/IMPL-062 still pending downstream).

Same defect class as R15 §15.1 originating gap at next-layer-down: previously the inversion was between `impl-plan.md` TL;DR (canonical-current 2026-05-18) vs `backtrack-log.md` lifecycle SoT (pre-cascade-closure framing); now the inversion is between `impl-plan.md` R15+R16 closure (canonical-current 2026-05-18) vs `overview.md` row 19 Impl Plan status field (pre-cascade-closure framing 2026-05-17).

**Why this matters:**

1. **Reader-side decision-tree** — Tech Lead reading overview.md row 19 first per CLAUDE.md §6 + workflow.md cold-bootstrap recipe sees "❌ Invalidated + re-run `/impl-plan-review all` post-SD lock" → infers Impl Plan layer cascade is still pending + recommends R17 as next action even after R15+R16 closure → wastes cycles re-running already-closed reviews. `/next` Check 5.5 dispatches workflow per stale priority

2. **Asymmetric narrative pattern across BT-002-impacted rows** — BA row + SD row both report cascade CLOSED at their respective layers (per Round-N closure + rebuttal); Impl Plan row reads "re-run pending" framing. Reader cross-referencing the three BT-002-impacted rows cannot reconcile: BA + SD say closed at their layer, Impl Plan says still-pending at its layer; either (a) BA/SD also still-pending (which the rows say they're not) OR (b) Impl Plan has special closure dependency on TD/Impl-Code/IMPL-062 (which the BA/SD row precedent contradicts — they flipped to ✅ at their layer without waiting on Impl Plan re-execution)

3. **Same recurring weakness pattern as R15 §15.1 originating inversion gap** at next-layer-down (10th-axis post-Recurring-Weaknesses chain) — defect-class progression chain: each cascade-drain round closes at primary-SoT layer but secondary-SoT row narrative reads N-1 closure-events behind. Now extending the chain from TL;DR + Sentinel + Closure Hygiene + Mid-Phase Audit Log narrative-propagation cluster (Claims 17.2/17.3/17.4) to overview.md row-level asymmetric narrative cluster (this Claim 17.5)

**Minimum acceptable fix:**

Row 19 status field rewrite (mirror BA row 9 + SD row 10 closure pattern at impl-plan layer):

```markdown
| Impl Plan | ✅ **Complete + BT-002 impl-plan-layer cascade CLOSED 2026-05-18 — R15 12/12 Accept (4 CRITICAL + 4 HIGH + 3 MEDIUM + 1 LOW; BT-002 cascade drain across 11+ impl-plan surfaces) + R16 6/6 Accept verify-pass (3 HIGH + 2 MEDIUM + 1 LOW; cascade-residue at intra-task-block + intra-Phase-Gate-block + 3-file-rule Tier-3 layers); IMPL-051 → cancel-by-BT-002 + E-AC supersession + Risk/ADR post-BT-002 annotations; IMPL-FIX-012 → close-by-BT-002 supersession + Status chronological reorder; current_handoff.md L7 Last completed action canonical-current. Downstream cascade pending (separate from impl-plan-layer closure): (a) TD review `/td-review all` — TD-02 §5.8 CCircuitBreaker skeleton DELETE + 10 cross-refs cleanup; (b) impl-code BT-002 cleanup ~1-2 hr single session per `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65; (c) IMPL-062 re-execute Bucket A 5-yr regression on rewrite-no-detector default build (NFR-1.1 acceptance signal).** · prior: ❌ **Invalidated (BT-002 — 2026-05-17 escalation gate executed; cap-3 budget exhausted at IMPL-FIX-012 iter-3 Run #5 ...)** [preserve remaining audit-history narrative verbatim per R10 §10.6 strikethrough-append discipline] ... | 2026-05-18 | Generated by `/impl-plan` (sprint 1, single-sprint MVP rewrite). Output: `docs/state/impl-plan.md` ... |
```

Update Last Updated column to `2026-05-18` (current date).

**Effort:** Low (1 row 19 status field rewrite preserving all prior audit-history narrative verbatim per R10 §10.6 strikethrough-append discipline + 1 Last Updated date refresh; ~80-120 LOC narrative for full row).

---

### 🟡 MEDIUM

#### Claim 17.6: 🟡 MEDIUM — `impl-plan.md` Mid-Phase Audit Log L2237 row dated 2026-05-04 (IMPL-061 + IMPL-064 + IMPL-068 parallel batch) is chronologically out-of-order — sandwiched between L2236 (2026-05-05 IMPL-017 + IMPL-066 + IMPL-067) and L2238 (2026-05-05 Code Review Round 15); pre-existing per R16 §16.5 explicit scope-out ("other pre-existing mismatches predate R15 and are out of R16 scope — would require dedicated audit-log-internal-chronological-cleanup task"); surfaces during R17 verify-pass sweep as audit-log-internal residue per next-finer-granularity sweep pattern

**Location:** `docs/state/impl-plan.md` Mid-Phase Audit Log L2235-L2240:

- L2235: `| 2026-05-04 | P3+P2 | **IMPL-FIX-001 + IMPL-FIX-002 closed (parallel batch) — Tier 1.5 walk batch-1 findings drained at coordinator level** ...` ✅ (R16 §16.5 reposition target)
- L2236: `| 2026-05-05 | P4 | **IMPL-017 + IMPL-066 + IMPL-067 closed (parallel batch — `/impl-task parallel` 3-subagent fan-out on Sonnet 4.6)** — P4 QA verification authoring pass ...`
- L2237: `| 2026-05-04 | P4 | **IMPL-061 + IMPL-064 + IMPL-068 closed (parallel batch — `/impl-task parallel` 3-subagent fan-out on Sonnet 4.6)** — P4 QA chain authoring pass ...` ❌ out-of-order (2026-05-04 between 2026-05-05 rows)
- L2238: `| 2026-05-05 | — | **Code Review Round 15 + Fix Round 15 closed (4/4 accepted + 2 XS deferred to Phase-2 backlog)** ...`

**Problem:**

Mid-Phase Audit Log is documented as "primary chronological audit trail" per `## Mid-Phase Audit Log` purpose statement L2181. L2237 dated 2026-05-04 sits between L2236 (2026-05-05) and L2238 (2026-05-05) — chronologically out-of-order. Pre-existing defect predates R15 + R16.

Rebuttal-16 §16.5 narrative explicitly noted: `"remaining pre-existing chronological mismatches at L2237 (2026-05-04 between 2026-05-05 rows) and L2241-2244 boundaries left in place per R16 reviewer's note that Claim 16.5 specifically targeted only the L2250 row (other pre-existing mismatches predate R15 and are out of R16 scope — would require dedicated audit-log-internal-chronological-cleanup task)"`. R16 reviewer + defender both acknowledged the residue + explicit-scope-out at R16 disposition.

R17 verify-pass sweep surfaces the residue as MEDIUM (same defect class as Claim 16.5 at audit-log-internal layer; pre-existing predates R15 + R16; explicit-scope-out at R16 → re-surfaces at R17 per next-finer-granularity sweep pattern).

**Why this matters:**

1. **Audit-trail readability** (Dim #10) — reader scrolling chronologically encounters 2026-05-05 → **2026-05-04** → 2026-05-05 → ... — visual time-travel breaks chronological discipline (analogous to Claim 16.5 L2250 case)

2. **MEDIUM not HIGH** because: (a) row content is correct (IMPL-061 + IMPL-064 + IMPL-068 closure narrative is accurate per 2026-05-04 parallel batch events); (b) the row IS in the audit-log (not missing); (c) chronological position is layout concern not content correctness; (d) pre-existing predates R15 + R16 — minor residue cleanup that R16 reviewer explicitly scope-out + R17 reviewer surfaces as carry-forward decision (operator-dispositive on whether to fix now or defer to dedicated audit-log-internal-chronological-cleanup task per R16 reviewer's note)

3. **Recurring Weakness signal** — same defect class as Claim 16.5 at audit-log-internal layer; both are Gate #7 Phase Status Notes-sweep analog finding at internal-chronological-discipline layer; R17 surfaces as carry-forward residue

**Minimum acceptable fix (engineer-choice — accepts either disposition):**

**Option A** — Move L2237 to chronologically-correct position (insert between earlier 2026-05-04 rows). Per surrounding context, expected insertion point = between L2234 (2026-05-04 IMPL-056 closure) and L2235 (2026-05-04 IMPL-FIX-001 + IMPL-FIX-002 closure per R16 §16.5 reposition target). Reorder = single row move; content unchanged.

**Option B** — Carry forward per R16 §16.5 explicit scope-out + document at R17 closure narrative as known-pre-existing residue. Engineer-dispositive on whether to address now or batch with dedicated audit-log-internal-chronological-cleanup task (which would also address L2241-2244 boundary residue per R16 reviewer's note).

Reviewer recommends **Option B** for R17 scope discipline (R17 is verify-pass round + pre-existing residue per R16 explicit scope-out; bundling with dedicated cleanup task is operationally cleaner than incremental per-round single-row moves). Engineer-dispositive.

**Effort:** Low (1-row move within audit log per Option A; ~3-5 LOC layout change; OR documented carry-forward per Option B; no narrative rewrite needed).

---

### 🔵 LOW

#### Claim 17.7: 🔵 LOW — 18 `.bak-2026-05-18T02-26-01Z` files untracked at repo root + `.claude/rules/` + `.codex/rules/` + `.trae/rules/` + `.windsurf/rules/` + 1 `.claude/stack.json.bak-*` from `/project-init --regen` 2026-05-18 (commit `7ff6f43`); Gate #11 working-tree pollution; disposition pending operator decision

**Location:** Working-tree (verified via `git status --short`):

```
?? .claude/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/security.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .claude/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .claude/stack.json.bak-2026-05-18T02-26-01Z
?? .codex/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/security.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .codex/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/security.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .trae/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/ea.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/security.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/testing.md.bak-2026-05-18T02-26-01Z
?? .windsurf/rules/workflow.md.bak-2026-05-18T02-26-01Z
?? AGENTS.md.bak-2026-05-18T02-26-01Z
?? CLAUDE.md.bak-2026-05-18T02-26-01Z
```

**Problem:**

`/project-init --regen` 2026-05-18 (commit `7ff6f43`) wrote pre-regen backups of CLAUDE.md + AGENTS.md + 4× rule files × 4× IDE mirrors (.claude / .codex / .trae / .windsurf) + 1× stack.json — totaling 20 .bak files (Note: count is 19 in actual git status output; 1 .codex stack.json variant may not exist). All have identical timestamp suffix `.bak-2026-05-18T02-26-01Z` indicating single-batch regen operation.

Per Gate #11 audit contract (`.claude/rules/workflow.md § Phase 5 Closure mechanical gates § Gate #11`):

> "Working-tree clean post-closure: `git status --porcelain | wc -l` after fix-round / task closure | exit count `0` (all artefacts referenced in fix-round narrative + closure tables — code, evidence sidecars, walk-batch logs, review/fix-round docs — are committed)."

The .bak files are methodology-infra timestamped backup artefacts generated by `/project-init --regen` — not referenced by any narrative + closure table + not part of the source-tree contract. They need disposition:
- **Option A** — commit as audit ledger (preserves backup-on-regen invariant; explicit audit-trail for methodology cascades like BT-002 TD/SD cascade)
- **Option B (recommended)** — add `*.bak-2026-*` glob to `.gitignore` (method ephemera; consistent with standard backup-file gitignore patterns)
- **Option C** — delete after regen verification (assumes verification complete; `7ff6f43` already merged so verification implicit)

Pre-existing pattern: prior `/project-init --regen` events (BT-001 2026-05-13 region) may have left similar artefacts — grep `find . -name "*.bak-*" -type f` would surface count. (Out-of-scope for R17 to enumerate prior pattern; engineer-dispositive whether to backfill at R17 or address as `/update-config` ticket.)

**Why this matters:**

1. **LOW not MEDIUM** because: (a) .bak files do not affect runtime / compile / source-tree (purely backup artifacts at .bak-* extension; tracked by git only for ?? untracked-marker visibility); (b) Gate #11 working-tree pollution is cosmetic at this layer (vs Claim 17.1 CRITICAL Gate #11 violation of 4 missing review/rebuttal commits + 2 M files); (c) operator-dispositive on disposition choice (any of A/B/C is acceptable per repo-discipline norms); (d) self-resolves with Option B .gitignore addition (one-time)

2. **Same Gate #11 working-tree-clean discipline as Claim 17.1** at next-finer layer — methodology-infra ephemera vs review/rebuttal artefacts; both surface in `git status --short`; both block clean-tree assertion but at different severity per content-criticality (review/rebuttal = CRITICAL audit-trail; .bak = LOW backup-pollution)

3. **Defect-class progression signal** — `/project-init --regen` is a routine methodology cycle (BT-001 + BT-002 cascade re-init events trigger regen per backtrack-workflow.md `§ Project Bootstrap Invalidation`); future regens will produce same .bak pollution unless `.gitignore` glob lands. Recommended preemptive fix per Option B + `/update-config` ticket for backtrack-workflow.md augmentation (`/project-init --regen` post-condition: ensure .gitignore covers .bak-* glob OR commit .bak files with regen commit). Out-of-scope for R17 rebuttal — methodology-evolution ticket per R14 §14.4 precedent

**Minimum acceptable fix (engineer-choice — accepts any disposition):**

**Option A (commit as audit ledger):**
```bash
git add CLAUDE.md.bak-* AGENTS.md.bak-* .claude/**/*.bak-* .codex/**/*.bak-* .trae/**/*.bak-* .windsurf/**/*.bak-*
# Bundle with R17 rebuttal commit per Claim 17.1 sequence
```

**Option B (RECOMMENDED — add to .gitignore):**
```bash
# Append to repo-root .gitignore
cat >> .gitignore <<'EOF'

# /project-init --regen pre-regen backups (methodology-infra ephemera; can be deleted post-verification)
*.bak-[0-9][0-9][0-9][0-9]-*
EOF
git add .gitignore
# Bundle with R17 rebuttal commit per Claim 17.1 sequence
# Optionally delete extant .bak files post-.gitignore:
rm -f CLAUDE.md.bak-* AGENTS.md.bak-* .claude/**/*.bak-* .codex/**/*.bak-* .trae/**/*.bak-* .windsurf/**/*.bak-*
```

**Option C (delete now; assumes regen verification complete):**
```bash
rm -f CLAUDE.md.bak-* AGENTS.md.bak-* .claude/**/*.bak-* .codex/**/*.bak-* .trae/**/*.bak-* .windsurf/**/*.bak-*
```

Reviewer recommends Option B for repeat-safety (future `/project-init --regen` cycles won't re-trigger this finding).

**Effort:** Low (any option ~2-5 min); preemptive Option B requires .gitignore append + optional delete; Option A bundles with Claim 17.1 commit; Option C is single rm command.

---

## Cross-Document Issues

R17 catches **3 cross-document state-reconciliation gaps** at next-finer-granularity layers (R16 §16.3 closed Tier 3 handoff layer but R16 narrative did NOT propagate its own closure to canonical hygiene-tracking surfaces in primary SoT):

| Contradiction | Primary SoT (correct) | Drifted surface |
|---------------|----------------------|------------------|
| TL;DR L101 `Last updated:` lead clause | R16 closure 2026-05-18 (per `rebuttal-round-16.md`) is the latest action | TL;DR L101 cites "R15 12/12 Accept" as last action (R16 not mentioned); Claim 17.2 |
| Mid-Phase Audit Log `[Date | Phase | Action]` table | R16 closure 2026-05-18 should have new row per CLAUDE.md §6 + workflow.md Gate #4 | 0 rows for R16 impl-plan-rebuttal closure; only L2239 Code Review Round 16 + L2184 R16 strengthening reference exist (different round counters); Claim 17.4 |
| `overview.md` row 19 Impl Plan status field | R15 12/12 + R16 6/6 Accept = impl-plan-layer BT-002 cascade CLOSED 2026-05-18 (mirror BA row 9 + SD row 10 closure pattern) | Row 19 cites "❌ Invalidated + re-run `/impl-plan-review all` post-SD lock" (pre-cascade-closure framing); Claim 17.5 |

Intra-document inconsistencies (4 surfaces — all same defect class: within-rebuttal-commit-narrative-propagation per 10th meta-axis):
- TL;DR L101 stale post-R16 (Claim 17.2)
- Plan Staleness Sentinel L2349 + Closure Hygiene Status L2363-2365 three lines stale post-R16 (Claim 17.3)
- Mid-Phase Audit Log missing R16 closure row (Claim 17.4)
- working-tree dirty post-R16 narrative-authoring (Claim 17.1 CRITICAL — Gate #11 violation; R15+R16 review/rebuttal .md docs + impl-plan.md + current_handoff.md uncommitted)

Audit-log-internal residue (1 surface — pre-existing per R16 §16.5 explicit scope-out):
- Mid-Phase Audit Log L2237 chronological out-of-order (Claim 17.6)

Methodology-infra pollution (1 surface — non-narrative artefact class):
- 18 `.bak-2026-05-18T02-26-01Z` files untracked from `/project-init --regen` (Claim 17.7)

No new Evolution Sequence violation. No ADR backing gap. Phase × Size matrix denominator preserved (IMPL-051 stays in matrix + IMPL-FIX-012 stays via close-by-supersession pivot per audit-history discipline). SD Hint Alignment audit trail unchanged (BT-002 did not introduce new task or change classifications post-R16).

---

## Recurring Weaknesses (rounds 06-16)

1. **State-reconciliation defect-class progression continues at next-finer granularity each round** (per R16 § Recurring Weaknesses #1 axis catalog — extended to 10 axes):
   - R06/R07: TL;DR↔registry drift (within `impl-plan.md`)
   - R08: Phase Status Notes + Open Risks + Next Best Action (intra-narrative-parallel sections)
   - R09: TL;DR↔diagnostic-artifact drift (one external artifact)
   - R10: TL;DR↔Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh
   - R11: upstream-vs-impl-plan (BA `03` + SD `08` Last-updated 2026-05-12 vs impl-plan pre-BT-001 framing) — BT-001 19-surface drain across impl-plan.md
   - R12: upstream-lifecycle-state-vs-derived-view (`backtrack-log.md § BT-001 Status` primary lifecycle SoT vs impl-plan ~19 surface annotations) — 5th meta-axis
   - R13: derived-view↔derived-derived-view (R12 reconciled backtrack-log↔impl-plan but overview.md unreconciled) — 6th axis depth-of-propagation
   - R14: intra-primary-SoT TL;DR canonical-block-vs-narrative-prose (7th axis at top reader-skim surface)
   - R15: next-cascade-event drain — BT-002 cascade across 11+ impl-plan surfaces (8th axis fresh-cascade-event boundary)
   - R16: cascade-residue at three sub-axes — intra-task-block annotation asymmetry (IMPL-051 sibling vs R15 §15.8 IMPL-FIX-012) + intra-Phase-Gate-block annotation asymmetry (R15 §15.6 L1411 vs L1412) + third-tier handoff layer (R15 §15.1 + claim CH-15 vs current_handoff.md L7) — 9th axis within-cascade-drain-rebuttal-scope-narrower-than-defect-class-footprint
   - **R17 (this round)** catches the **next-finer-granularity residue at four sub-axes within the new 10th axis layer**: (a) TL;DR + Sentinel + Closure Hygiene Status + Mid-Phase Audit Log narrative-propagation gap where R16 commit applied per-surface edits but didn't propagate R16 closure to canonical hygiene-tracking surfaces (Claims 17.2 + 17.3 + 17.4); (b) overview.md row 19 Impl Plan asymmetric vs row 9 BA + row 10 SD post-R15/R16 cascade closure (Claim 17.5); (c) Gate #11 working-tree NOT clean — R15/R16 rebuttal narratives both authored but commits never executed (Claim 17.1 CRITICAL); (d) methodology-infra .bak pollution from `/project-init --regen` (Claim 17.7 LOW). Defect-class progression now at **10th axis: within-rebuttal-commit-narrative-propagation + commit-execution-discipline**.

2. **Cascade-drain rebuttal verify-pass cycle continues** — BT-002 closure → R15 BT-002 11+ surface drain → R16 verify-pass + residue cleanup → R17 verify-pass surfaces narrative-propagation + commit-execution gaps (this round) → expected R18 verify-pass clean cycle after R17 closure addresses all 4 axis-10 sub-surfaces. Mirror BT-001 closure → R11 BT-001 drain → R12/R13/R14 verify-pass chain. R17 rebuttal predicted 7/7 Accept verify-pass pattern (no rejected claims expected; all are commit-discipline + narrative-propagation closures; reviewer-suggested Option B for both .bak disposition and L2237 carry-forward — both engineer-dispositive).

3. **Gate #2 mechanical sweep status** — per R14/R15/R16 § Recurring Weaknesses, Gate #2 (TL;DR ↔ registry recount) is documented since R07 but only explicitly invoked when narrative discipline cites it. **R17 verify-pass note**: Gate #2 ran clean this round (5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = 55 Active rows ✅ matches TL;DR L100 + 8 Resolved rows ✅ matches L100; R16 fix-round preservation held). **R14 informal recommendation** (Gate #2 mandatory-every-round codification) still outstanding as `/update-config` candidate.

4. **Gate #4 atomic TL;DR-rewrite-on-rebuttal-close discipline** — per workflow.md Gate #4 ("After closing task, bump `Plan Staleness Sentinel § Closures since last review` by +1 atomically with TL;DR `Last updated:` rewrite"); R16 rebuttal correctly handled the counter-unchanged exception per rebuttal-exception-fix-round-10-precedent but did NOT execute the paired atomic TL;DR rewrite (Claim 17.2 surface). The rebuttal-exception applies to the COUNTER only, not to the `Last updated:` lead clause atomic-pairing. Future Gate #4 codification candidate: explicitly distinguish counter-pairing from TL;DR-pairing in rule body. `/update-config` ticket per R14 §14.4 precedent — out-of-scope for R17 rebuttal.

5. **Gate #11 working-tree-clean discipline applies at impl-plan-rebuttal-closure layer** (Claim 17.1 newly-surfaced defect-class application) — Gate #11 was authored for code-review / fix-round closures (fix-round-15 §16.2 originating + fix-round-16 §16.2 hardening); R17 §17.1 surfaces the **same defect class at impl-plan-rebuttal-closure layer** — narrative authored + commits not executed = audit-trail integrity violation. Symmetric across closure-cycle types. Recommend `/update-config` ticket to extend Gate #11 explicit scope language to include impl-plan-rebuttal-cycle closures + fix-round closures + impl-plan-fix-round closures + impl-task closures uniformly. Out-of-scope for R17 rebuttal — engineer-side methodology-evolution ticket per R14 §14.4 precedent.

6. **Methodology-infra .bak ephemera Gate #11 corner case** (Claim 17.7 newly-surfaced) — `/project-init --regen` and analogous methodology-cascade events produce timestamped .bak files that pollute working tree at Gate #11 sweep time. Recommend `/update-config` ticket extending backtrack-workflow.md `§ Project Bootstrap Invalidation` post-condition: ensure repo .gitignore covers `*.bak-[0-9][0-9][0-9][0-9]-*` glob OR `/project-init --regen` commits .bak files alongside regen output. Out-of-scope for R17 rebuttal — methodology-evolution ticket per R14 §14.4 precedent.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 17.1 | 🔴 CRITICAL | Gate #11 working-tree NOT clean — R15 + R16 rebuttal narratives both claim closure but commits never landed; 2 M files + 4 untracked review/rebuttal .md files + 18 .bak files all uncommitted | Working-tree (verified via `git status --short`) | Low (~10 min — commit execution + .gitignore disposition + Gate #11 verification) |
| 17.2 | 🟠 HIGH | TL;DR L101 `Last updated:` lead clause cites "R15 12/12 Accept" only; R16 6/6 Accept closure 2026-05-18 not mentioned; same defect class as R15 §15.1 originating gap at within-rebuttal-commit-narrative-propagation layer (10th meta-axis) | `impl-plan.md` L101 (TL;DR Last-updated block) | Low (1 lead-clause refresh preserving prior narrative; ~30-50 LOC) |
| 17.3 | 🟠 HIGH | Plan Staleness Sentinel L2349 `Last review on:` + Closure Hygiene Status L2363-2365 three lines cite R15 only; R16 closure narrative not propagated to canonical hygiene-tracking surfaces; subset 4 of 5 within-commit-narrative-propagation axis | `impl-plan.md` L2349 (Plan Staleness Sentinel) + L2363/L2364/L2365 (Closure Hygiene Status) | Low (4 narrative-line refreshes preserving prior content; ~80-100 LOC) |
| 17.4 | 🟠 HIGH | Mid-Phase Audit Log missing row for R16 impl-plan-rebuttal closure 2026-05-18; per CLAUDE.md §6 + workflow.md Gate #4, rebuttal closures MUST log audit-row | `impl-plan.md` Mid-Phase Audit Log (insertion point: after L2260 R15 closure row) | Low (1 new audit-log row append; ~30-50 LOC) |
| 17.5 | 🟠 HIGH | `overview.md` row 19 "Impl Plan" status reads pre-R15/R16-closure framing while row 9 BA + row 10 SD both flipped to "✅ Complete + BT-002 cascade CLOSED 2026-05-18"; asymmetric narrative at secondary-SoT layer | `overview.md` row 19 (Impl Plan status field) | Low (1 row status field rewrite preserving prior audit-history; ~80-120 LOC) |
| 17.6 | 🟡 MEDIUM | Mid-Phase Audit Log L2237 row dated 2026-05-04 chronologically out-of-order (sandwiched between L2236 = 2026-05-05 + L2238 = 2026-05-05); pre-existing per R16 §16.5 explicit scope-out; carry-forward residue | `impl-plan.md` L2237 (Mid-Phase Audit Log table) | Low (1-row move per Option A; ~3-5 LOC layout change; OR carry-forward per Option B) |
| 17.7 | 🔵 LOW | 18 `.bak-2026-05-18T02-26-01Z` files untracked from `/project-init --regen` (commit `7ff6f43` 2026-05-18); Gate #11 working-tree pollution; disposition operator-choice (commit / .gitignore / delete) | Working-tree (`.bak-*` files at repo root + .claude/rules/ + .codex/rules/ + .trae/rules/ + .windsurf/rules/) | Low (~2-5 min — any of A/B/C disposition; reviewer recommends Option B .gitignore append) |

---

## End of Review
