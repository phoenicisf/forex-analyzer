# Implementation Plan Claim Review Round 15

| Field | Value |
|-------|-------|
| **Round** | 15 |
| **Target** | `docs/state/impl-plan.md` (+ state-reconciliation siblings) |
| **Date** | 2026-05-18 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R14 (2026-05-13) — 6/6 Accept; TL;DR L94 per-phase tally drift + L95 Last-updated 3 rebuttal rounds behind + L191/192/193 stale dependency-arrow + L110/L111 P2/P3 Notes pre-BT-001 framing + R-7/R-13 `/backtrack ba` residue + L93 `Action ถัดไป` audit-history. All R14 surfaces reconciled at rebuttal commit. |
| **Trigger** | Operator invoked `/impl-plan-review all` per `docs/state/overview.md` row 19 (`Impl Plan` status = `❌ Invalidated (BT-002 — re-run /impl-plan-review all post-SD lock)`) + `docs/state/backtrack-log.md § BT-002 § Impacted phases — Impl Plan` line 64 (`re-run /impl-plan-review all after SD lock`). SD-side BT-002 cascade CLOSED 2026-05-17 via Round 09 verify-only **0 findings**; BA-side BT-002 cascade CLOSED 2026-05-18 via Round 06 + rebuttal-05 (1 LOW Accept). Impl-plan-side is the next downstream cascade — R15 is the **first** impl-plan review after BT-002 fired (analogous to R11 first review after BT-001 fired). Scope: full BT-002 propagation drain across all 19+ impl-plan surfaces (mirror R11 §11.1 BT-001 cascade pattern). |

---

## 📊 At-a-Glance

**Total findings:** 12 (🔴 CRITICAL 4 / 🟠 HIGH 4 / 🟡 MEDIUM 3 / 🔵 LOW 1)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (`deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **2 sanctioned false-positives** ✅ — hit-1 at L27 (IMPL-FIX-011d Phase 1 audit-log row, regex `.*` greediness on `"deferred per registry row"` + later `"fix-round-10 precedent"`) + hit-2 at L2349 (Closure Hygiene Status self-reference); both sanctioned per `claim-review-14.md § At-a-Glance` + fix-round-26 §Finding 26.6 precedent. **0 real hits** on `[x]` AC closure lines.
- **Forward refs (P_n → P_m, m>n):** **0 edges** ✅. Walked all 82 `- **Deps**:` declarations cross-referenced to task→phase map; sub-ticket↔parent convention (R09 §09.5 + R11 §11.1) preserved.
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013 P4→P3 Service-coupling diverge), V=0, N=0 — **Not triggered** ✅ (D ≥ 1; SD Hint Alignment scratch table line 2262 + tally line 2326 in place).
- **State reconciliation (4-way):** 🔴 **`\bBT-002\b` grep on `impl-plan.md` returns 0 hits**, vs `overview.md` = 10 hits + `backtrack-log.md` = 7 hits + `CLAUDE.md` Status snapshot row P4 + Glossary §CircuitBreaker + §6 ADR bullet + §1 BT-002 status note. **Impl-plan-side BT-002 cascade not drained at any surface** — same defect class as R11 §11.1 BT-001 propagation (19-surface drain) at fresh-cascade trigger layer (Claim 15.1). 🔴 **TL;DR L101 `Last updated: 2026-05-14`** = 4 days behind canonical; canonical last action per overview row 19 + backtrack-log § BT-002 § Status flipped 2026-05-18 = **BT-002 cascade closure** (2026-05-17/18) preceded by **IMPL-FIX-012 iter-2 Run #4 ❌ (2026-05-17)** + **iter-3 Run #5 ❌ (2026-05-17)** + **cap-3 budget exhausted** + **fix-round-26 closure (2026-05-17)** + **BT-002 cascade open/close (2026-05-17/18)** + **`/project-init --regen` propagation (commit `7ff6f43` 2026-05-18)**. 5 canonical events behind (Claim 15.2). 🔴 **TL;DR L97 `ตอนนี้:` block** says `P4 16/17 — ... remaining: IMPL-063 (paired Bucket B; depends on IMPL-062 numeric drain)` but IMPL-063 ✅ CLOSED 2026-05-14 via Run #3 cascade (per L2073 task-block + L100 registry Resolved row) making P4 = 17/17 ✅ structural; also **zero BT-002 invalidation marker** on the canonical reader-skim line (Claim 15.3). 🔴 **Next Best Action L199-201 stale**: L199 `☐ NEXT — operator session: /impl-task IMPL-FIX-012 Step 3 G3 5-yr Bucket A retry (Run #4)` is **3 events stale** — Run #4 = iter-2 (2026-05-17 ❌); Run #5 = iter-3 (2026-05-17 ❌); cap-3 exhausted; BT-002 fired; IMPL-FIX-012 → `close-by-BT-002 supersession` per overview row 19 (Claim 15.4).

### Top 3 to Fix First

1. **Claim 15.1** 🔴 — **impl-plan.md zero BT-002 cascade propagation across 11+ canonical surfaces** (TL;DR audit-history block L7-L101 + ตอนนี้ L97 + Phase Status Snapshot P4 Notes L118 + Open Risks R-3/R-13 L128/L133 + Next Best Action L199-201 + Phase Gate P4 Empirical Demo L1409 + NFR-1.1 subrow L1414 + IMPL-051 task block L892-907 + IMPL-FIX-012 task block L1961-1990 + Mid-Phase Audit Log L2247 trailer + Closure Hygiene Status L2348-2350 + Plan Staleness Sentinel L2337-2338). Empirical: `grep -c '\bBT-002\b' docs/state/impl-plan.md` = **0**; same grep on overview.md = 10, backtrack-log.md = 7, CLAUDE.md ≥ 6. The primary State SoT (impl-plan.md per CLAUDE.md §6 State SoT) does not acknowledge BT-002 fired — engineer/status agent reading impl-plan alone has no signal that the CircuitBreaker mechanism was reverted, ADR-013/014 superseded, IMPL-051 cancelled, IMPL-FIX-012 closed-by-supersession, and impl-code cleanup pending. Originating defect class; cascades to Claims 15.2..15.10.

2. **Claim 15.2** 🔴 — **TL;DR L101 `Last updated: 2026-05-14` + lead clause `last action: 🟢 /impl-task IMPL-FIX-012 iter-1 ✅ CLOSED`** stale 4 days + 5 canonical closure events behind. Canonical post-2026-05-14 events visible in overview.md row 19 narrative chain: (a) **2026-05-17 IMPL-FIX-012 iter-2 Run #4 ❌** (ADR-014 partial; mass-close class); (b) **2026-05-17 IMPL-FIX-012 iter-3 Run #5 ❌** (ADR-014 INSUFFICIENT; 3rd false-positive class; cap-3 budget exhausted); (c) **2026-05-17 fix-round-26 ✅ closed** (IMPL-FIX-013 P5 row added + Gate #9 clause (h) extended); (d) **2026-05-17 BT-002 OPENED** (`/backtrack sd` after cap-3 exhaustion); (e) **2026-05-18 BT-002 SD-side CLOSED** (Round 09 verify-only 0 findings; commit `e385ad0`) + **BA-side CLOSED** (Round 06 + rebuttal-05; commit `863493e`). Same defect class as Claim 14.2 (3 rebuttal rounds behind) — now at 5 closure events behind at higher-magnitude post-BT-002 cascade.

3. **Claim 15.4** 🔴 — **Next Best Action L199-201 stale dependency-arrow on IMPL-FIX-012 Step 3 Run #4**: L199 `☐ NEXT — operator session: /impl-task IMPL-FIX-012 Step 3 G3 5-yr Bucket A retry (Run #4)` claims Run #4 is the next operator action — but Run #4 happened 2026-05-17 as iter-2 (Jan-27 mass-close class ❌); Run #5 happened 2026-05-17 as iter-3 (Jan-06 BI pyramiding class ❌); cap-3 budget exhausted; BT-002 fired and **closed 2026-05-18** per backtrack-log L69 Status. L200 + L201 `still blocked on IMPL-FIX-012 Step 3 Run #4` carry the same stale dependency. Per overview row 19 + backtrack-log § BT-002 § Impacted phases Impl Code (line 65: `DELETE services/CircuitBreaker.mqh; strip Record{Open,Close} dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from core/Orchestrator.mqh::OnTradeTransaction; remove CheckPingPong call from OnTick; DELETE spike/Spike_CircuitBreaker.mq5; verify domain/EnumTypes.mqh for HALT_PINGPONG constant removal; mandatory G1+G2+G3 re-run`), the actual next action is **impl-code BT-002 cleanup** (single-session ~1-2 hr) + then `/impl-task IMPL-062` re-execute (rewrite-no-ping-pong-detector single-pass). Same defect class as R14 §14.3 (intra-section dependency contradiction) at post-BT-002 magnitude.

### Verdict
- [ ] ✅ **Ready for Implementation Execution**
- [x] ⚠️ **Needs Rebuttal Round** — 4 CRITICAL BT-002 cascade-drain gaps + 4 HIGH state-reconciliation drifts + 3 MEDIUM narrative residues + 1 LOW Sentinel/Closure Hygiene refresh. Run `/impl-plan-rebuttal claim-review-15.md`. Mirror R11 §11.1 (BT-001 19-surface drain) at BT-002 magnitude — expect ~20-30 in-place surface edits (~100-150 LOC narrative); no AC content changes; no task splits; one task status flip (IMPL-051 → cancel-by-BT-002) + one task closure pivot (IMPL-FIX-012 → close-by-BT-002 supersession with audit history preserved).
- [ ] ⛔ **Immediate Attention** — fundamental scope flaw

> **Rebuttal scope guidance:** Drain BT-002 cascade across the 11+ surfaces enumerated in Claim 15.1 § Location. Preserve **all** existing audit history per R10 §10.6 + R11 §11.1 precedent (strikethrough-then-append pattern). IMPL-FIX-012 task block keeps full iter-1/2/3 audit narrative + ADR-013/014 author-history; adds a final `Status (BT-002 supersession 2026-05-18)` row marking ❌ → `[x]` closure via BT-002 with reasoning. IMPL-051 task block keeps `Closed: 2026-05-03` audit + ADR-010 reasoning; adds annotation `**Cancelled-by-BT-002 2026-05-18:** detector removed at SD lock; CircuitBreaker.mqh deletion pending impl-code cleanup`. R-3 + R-13 Open Risks rows append post-BT-002 closure resolution paragraph. P4 Phase Gate Empirical Demo + NFR-1.1 subrow append post-BT-002 framing (Run #3/#4/#5 became audit-only; new acceptance path = impl-code BT-002 cleanup + clean 5-yr regression on no-detector build). Plan Staleness Sentinel L2337 updates to 2026-05-18 with R15 anchor; L2338 Closures-since-R09 **unchanged at 1** (rebuttal cycle ≠ main task closure per workflow.md Gate #4 + fix-round-10 precedent — same convention as R11/R12/R13/R14 closure pattern). Likely 11-12 Accept verify-pass pattern (substantive cascade drain + 1 LOW disposition flexibility).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Phase shape unchanged since R01–R14; rationale + Phase % targets ครบ; BT-002 cascade does not affect Phase Shape Choice (does affect work content within Phase 4 verification, addressed via Claim 15.6 Phase Gate row drain) |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean (H=68, A=67, D=1, line 2262 confirmation note); BT-002 cascade did not change Evolution Sequence (no E1..EN reassignment per backtrack-log § BT-002); E2 CircuitBreaker spike (IMPL-046) was P1 and remains ✅ Honored; no new SD Hint classification changes |
| 3 | Task Decomposition & Sizing | ⚠️ Finding 15.7 + 15.8 | IMPL-051 task block needs `cancel-by-BT-002` annotation (CircuitBreaker.mqh impl deletion pending impl-code cleanup per overview L19 + backtrack-log L65); IMPL-FIX-012 task block needs `close-by-BT-002 supersession` final Status row (audit history preserved per R10 §10.6 + R11 §11.1 strikethrough-append precedent) |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 15.8 | IMPL-FIX-012 E-AC L1976 + L1977 reference Run #4 / Run #5 as future-pending — Run #4 + Run #5 happened 2026-05-17 ❌; need annotation `Superseded by BT-002 2026-05-18 — detector removal supersedes ping_pong halt verification path`. Otherwise dual-track compliance preserved (no new task introduces forbidden pattern; IMPL-FIX-013 E-AC properly `[ ]` deferred via P5 registry row not inline `[x]+deferred`) |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 15.6 | P4 Phase Gate L1409 "Empirical Demo" + L1414 NFR-1.1 sub-row carry pre-Run #3 BT-001-resolved framing — Run #3 fail + iter-1/2/3 + BT-002 cascade not reflected; needs append (mirror R14 §14.4 reword pattern at Phase Gate testable-exit layer) |
| 6 | Deferred-AC Registry Init | ✅ Pass | Registry empirical recount (Gate #2): 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = **55 Active rows** ✅ matches TL;DR L100 claim exactly (Gate #2 ✅ verified clean — R14 §14.1 fix held + fix-round-26 +1 P5 row + IMPL-FIX-013 row appended in sync). Resolved table = 8 rows ✅ matches L100 claim. Schema + Rules sections clean |
| 7 | Cross-Phase Dependency | ✅ Pass | 0 forward refs detected; sub-ticket↔parent convention (R09 §09.5) preserved; Mermaid Phase × Size matrix unchanged (Claim 15.7 IMPL-051 cancel-by-BT-002 does NOT remove from matrix denominator per R10 §10.6 audit-trail discipline — task block stays with audit annotation, not deleted) |
| 8 | State-File Consistency | ⚠️ Findings 15.1 + 15.2 + 15.3 + 15.4 + 15.5 + 15.9 + 15.10 + 15.11 | Massive BT-002 cascade drain pending (Claim 15.1 covers cross-surface gap); TL;DR L97/L100/L101 + Phase Status P4 Notes + Open Risks R-3/R-13 + Next Best Action + Phase Gate rows + Mid-Phase Audit Log + Closure Hygiene Status all drift versus overview.md L19/L20 + backtrack-log.md § BT-002 + CLAUDE.md Status snapshot post-BT-002 framing |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4/month-year schedule leakage; absolute dates (2026-05-17/18) are working-paper-dates allowed per R10 disposition + BT-001 cascade precedent |
| 10 | Readability — Reader Empathy | ⚠️ Findings 15.3 + 15.4 + 15.9 | TL;DR `ตอนนี้:` lead block + Next Best Action checklist + Open Risks narratives are the canonical Tech Lead / PM reader-skim surface per Dim #10; all three drift on the most-material cascade event (BT-002) — primary reader-empathy failure |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 15.1: 🔴 CRITICAL — `impl-plan.md` zero BT-002 cascade propagation across 11+ canonical surfaces; primary State SoT does not acknowledge that BT-002 fired + closed; engineer/status agent reading impl-plan alone has no signal of CircuitBreaker mechanism revert + ADR-013/014 supersession + IMPL-051 cancellation + IMPL-FIX-012 close-by-supersession + impl-code cleanup pending; originating defect class for the R15 cascade drain

**Location:** Empirical evidence — `grep -c '\bBT-002\b' docs/state/impl-plan.md` = **0**; same grep on `docs/state/overview.md` = **10**; `docs/state/backtrack-log.md` = **7**; `CLAUDE.md` ≥ 6 (Status snapshot P4 row + Glossary § CircuitBreaker + §6 ADR bullet + Section 1 BT-002 status note + Section 7b § CircuitBreaker entry). **11+ canonical surfaces in `impl-plan.md` that require BT-002 annotation** (mirror R11 §11.1 BT-001 19-surface drain pattern):

| # | Surface | Line(s) | Drift type |
|---|---------|---------|------------|
| 1 | TL;DR audit-history top entries | L7 (IMPL-FIX-012 iter-3 Run #5 ❌) | Latest entry references cap-3 exhaustion + `Engineer recommends /backtrack sd` but no closure annotation that `/backtrack sd` was executed + closed |
| 2 | TL;DR `ตอนนี้:` reader-skim block | L97 | P4 16/17 (stale; IMPL-063 closed 2026-05-14 → 17/17) + no BT-002 invalidation marker |
| 3 | TL;DR `Last updated: 2026-05-14` lead clause | L101 | 4 days behind canonical (Claim 15.2) |
| 4 | Phase Status Snapshot P4 row Notes | L118 | References ADR-013 as live; ADR-013/014 Superseded per backtrack-log L56 |
| 5 | Open Risks R-3 | L128 | "Mitigation iter-1 ✅ APPLIED 2026-05-14 via IMPL-FIX-012 + ADR-013" — no iter-2/iter-3 fail or BT-002 closure |
| 6 | Open Risks R-13 | L133 | "Post-Run #3 ... triggers next IMPL-FIX-NNN long-tail iteration" — Run #4/5 happened + cap-3 exhausted + BT-002 fired |
| 7 | Next Best Action checklist | L199-201 | Claim 15.4 |
| 8 | P4 Phase Gate Empirical Demo + NFR-1.1 subrow | L1409 + L1414 | Pre-Run #3 BT-001-resolved framing; cascades to Claim 15.6 |
| 9 | IMPL-051 task block | L892-907 | Closed 2026-05-03; cancel-by-BT-002 annotation pending (Claim 15.7) |
| 10 | IMPL-FIX-012 task block | L1961-1990 | iter-1 + iter-2 + iter-3 Status entries; no close-by-BT-002 supersession final row + ADR field stale (Claim 15.8) |
| 11 | Mid-Phase Audit Log trailer | L2247 (post-fix-round-26) + L2248-2250 | Missing 2026-05-17 IMPL-FIX-012 iter-2/iter-3 closures + 2026-05-17/18 BT-002 cascade open/close + 2026-05-18 BA Round 06/SD Round 09 closures + commit `7ff6f43` `/project-init --regen` (Claim 15.10) |

**Problem:**

Per CLAUDE.md §6 State SoT discipline (`State Single Source of Truth (State SoT)`) + `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #5 (overview.md sync) + R11 §11.1 precedent (BT-001 cascade drain across 19 impl-plan surfaces post-BA-Round-04 + SD-Round-04 closure 2026-05-12):

> "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**: (1) `impl-plan.md` (primary SoT — `[x]` AC, Phase Gate, audit log), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*`"

The current state inverts the contract: BT-002 cascade is fully drained at `overview.md` (10 mentions across rows 10, 11, 13, 14, 15, 17, 18, 19, 20, 21) + `backtrack-log.md` (full BT-002 entry lines 35-71 with Status `✅ Closed 2026-05-18`) + `CLAUDE.md` (regenerated 2026-05-18 via `/project-init --regen` commit `7ff6f43` per CLAUDE.md L1 frontmatter) — but the **primary SoT** (`impl-plan.md` per `## State Single Source of Truth` Glossary entry) is silent on BT-002. The derived views are ahead of the primary; this is the **exact inverse** of the 3-file rule.

BT-002 chain timeline (per backtrack-log.md § BT-002):
- 2026-05-17 OPEN — operator selected Option 1 (remove detector, legacy-parity)
- 2026-05-17 SD-side cascade open: Round 07 (7 findings) → rebuttal-05 (7 accept commit `111f092`) → Round 08 (2 findings) → rebuttal-06 (2 accept commit `32c56c0`) → Round 09 verify-only **0 findings** ✅ (commit `e385ad0`); SD package = 18 BT-002 propagation surfaces + 9 cascade-completion surfaces
- 2026-05-18 BA-side cascade: Round 06 (1 LOW) → rebuttal-05 (1 accept commit `863493e`); BA package = 18 BT-002 propagation surfaces + Anti-Duplication clean vs prior Round 04/05
- 2026-05-18 BT-002 ✅ Closed (Status flipped; this commit is the BT-002 closure commit per backtrack-log L71)
- **Pending downstream cascade** (per backtrack-log § BT-002 § Status line 69 + § Resolution line 71): (a) **TD review** — out of BT-002 BA-closure scope; tracked separately as TD `02-backend-design.md § 5.8` CCircuitBreaker class skeleton DELETE + 10 cross-refs cascade cleanup; (b) **Impl-plan IMPL-051 closure + IMPL-FIX-012 task closure pivot** — out of BT-002 BA-closure scope; **tracked via `/impl-plan-review` next cycle** (this is the R15 trigger per overview row 19); (c) **Impl-code cleanup** — DELETE `services/CircuitBreaker.mqh` + strip `Record{Open,Close}` dispatch from `core/Orchestrator.mqh::OnTradeTransaction` + remove `CheckPingPong` call from `OnTick` + DELETE `spike/Spike_CircuitBreaker.mq5` + verify `domain/EnumTypes.mqh` `HALT_PINGPONG` removal + mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal).

The R15 rebuttal IS the trigger that drains BT-002 across impl-plan.md — same shape as R11 §11.1 which drained BT-001 across 19 impl-plan surfaces.

**Why this matters:**

1. **State SoT inversion is the primary failure mode the 3-file rule was authored to prevent.** Derived views ahead of primary SoT = engineer reading `impl-plan.md` and dispatching via `/impl-task` (which reads `impl-plan.md` per CLAUDE.md §6 Glossary `State Single Source of Truth`) would attempt the **canonical Next Best Action** at L199 — `/impl-task IMPL-FIX-012 Step 3 G3 5-yr Bucket A retry (Run #4)` — which is **already-executed-and-failed** + **closed-by-BT-002 supersession**. `/impl-task` would HALT immediately at Task ID resolution since IMPL-FIX-012 has [x] AC closure (after R15 rebuttal applies the cancel-by-BT-002 pivot per Claim 15.8 fix). Until R15 rebuttal lands, dispatch path is **structurally broken** by the cascade gap.

2. **Same defect class as R11 §11.1 BT-001 19-surface drain** at next-cascade-event layer: R11 closed 2026-05-13 via 7/7 Accept after `/backtrack ba` ran 2026-05-12; R12 §12.1 + R13 §13.1 drained the backtrack-log↔overview.md residue (next-finer derived-view layers). R14 caught TL;DR-Last-updated-narrative drift (canonical-block-vs-narrative-prose at TL;DR layer). R15 catches the **next-cascade-event** (BT-002) — primary SoT layer not yet drained on the new event. Defect-class progression: each backtrack event needs its own impl-plan cascade drain rebuttal pair, with R-N(M-1) drained N-1 cascade-by-cascade. R15 = first BT-002 cascade drain. R16+ likely needed for cascade residue cleanup (mirror R11→R12→R13→R14 chain).

3. **Reader-side decision-tree impact (CRITICAL across all reader classes)**:
   - **Engineer running `/impl-task`**: would dispatch IMPL-FIX-012 Step 3 Run #4 (broken; halted via supersession after R15)
   - **Tech Lead reading TL;DR `ตอนนี้:` line**: sees P4 16/17 + no BT-002 marker → infers Run #4 retry is still primary blocker; doesn't know detector was reverted
   - **Status agent rendering dashboard**: reports `Last updated: 2026-05-14` + Run #4 next action; **misses** entire IMPL-FIX-012 iter-2/3 + cap-3 exhaustion + BT-002 cascade lifecycle (the 4 most-material events on the project right now)
   - **PM running `/next` Check 5.7**: reads Next Best Action checklist (L199-201) sees Run #4 still next; mis-estimates remaining work timeline (Run #4 was actually never the next action post-2026-05-17; impl-code BT-002 cleanup + re-execute IMPL-062 on no-detector build is the next action)
   - **`/deliver` block check**: reads registry (clean — 55 Active rows reconcile) but doesn't gate on BT-002 invalidation marker; would attempt to ship a build that still has CircuitBreaker.mqh + dispatch wires + ADR-013/014 producer filters (BT-002 cleanup pending)

**Minimum acceptable fix:**

R15 rebuttal commits BT-002 cascade drain across the 11 surfaces enumerated above. Each surface gets a strikethrough-then-append pattern preserving all prior audit history (per R10 §10.6 + R11 §11.1 precedent). Indicative per-surface drain text:

```
# Surface 1 (TL;DR audit-history top L7): append after current entry trailer
> 📝 **2026-05-18 BT-002 ✅ CLOSED — SD Round 09 verify-only 0 findings (commit e385ad0) + BA Round 06 1 LOW closed via rebuttal-05 (commit 863493e); CircuitBreaker BR-3.6 ping-pong detector revert authorized per Option 1 (legacy-parity).**
> Per `backtrack-log.md § BT-002`: ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA layer; SD Services Catalog `CircuitBreaker` row repurposed/removed across 5 design docs; halt-trigger list at ADR-010 amended (CircuitBreaker removed; HALTED state machine remains for handle-invalid + Phase 2 future triggers). Pending impl-code cleanup: DELETE `services/CircuitBreaker.mqh` + strip `Record{Open,Close}` dispatch + ADR-013/014 producer filter from `core/Orchestrator.mqh::OnTradeTransaction` + remove `CheckPingPong` from `OnTick` + DELETE `spike/Spike_CircuitBreaker.mq5` + verify `domain/EnumTypes.mqh` `HALT_PINGPONG` removal + mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal). Next operator action = impl-code cleanup ~1-2 hr (single session; G1+G2+G3 within session); then `/impl-task IMPL-062` re-execute on no-detector default build (NFR-1.1 acceptance signal — rewrite-no-detector vs baseline single-pass per BT-001 R12 §12.1 methodology, now with no CircuitBreaker halt-class risk per BT-002 closure).

# Surface 2 (TL;DR `ตอนนี้` L97): bump 16/17 → 17/17; append BT-002 marker
"P4 ✅ 17/17 (IMPL-063 closed 2026-05-14 via Run #3 cascade; bumped 16→17 per R15 §15.3) + IMPL-FIX-003/005/006/007/008/009/010 ✅ closed 2026-05-10. **❌ BT-002 INVALIDATED 2026-05-17/18** — IMPL-FIX-012 iter-3 Run #5 (2026-05-17) cap-3 exhausted → /backtrack sd → SD Round 09 + BA Round 06 0 findings 2026-05-17/18 → CircuitBreaker mechanism reverted (ADR-013/014 Superseded; BR-3.6 demoted; FR-6.6 demoted). Pending impl-code cleanup: DELETE services/CircuitBreaker.mqh + strip Orchestrator dispatch + remove HALT_PINGPONG constant; mandatory G1+G2+G3 re-run. Then IMPL-062 re-execute on no-detector default build."

# Surfaces 3-11: analogous strikethrough-then-append pattern per surface
```

Plus the substantive task-block surgery (Claims 15.7 + 15.8) covered separately. **Effort:** Medium (~20-30 in-place surface edits + 2 task-block status pivots; ~100-150 LOC narrative; mirror R11 §11.1 BT-001 19-surface drain scope).

---

#### Claim 15.2: 🔴 CRITICAL — `impl-plan.md` L101 TL;DR `Last updated: 2026-05-14 · last action: 🟢 /impl-task IMPL-FIX-012 iter-1 ✅ CLOSED` is 4 calendar days + 5 canonical closure events behind; same defect class as Claim 14.2 (3 rebuttal rounds behind) at 5-events behind post-BT-002 magnitude; the primary canonical reader-skim signal for "what just happened" is severely stale

**Location:** `docs/state/impl-plan.md` L101 — `"> **Last updated:** 2026-05-14 · last action: **🟢 \`/impl-task IMPL-FIX-012\` iter-1 ✅ CLOSED — ADR-013 DEAL_REASON_EXPERT filter applied + Step 0 diagnostic falsified ManageExits cooldown hypothesis + Step 1 patch (3 LOC in core/Orchestrator.mqh + ADR-013 ~210 LOC NEW) + Step 2 G1 PASS (0err/0warn/4705 ms) + G2 bootstrap_smoke 3-day PASS ..."` (~3500 char block).

**Problem:**

Per workflow.md Gate #8 (narrative-section freshness sweep) + R14 §14.2 disposition (Accept; rewrote L95 lead clause to current-round R14 narrative + chained backward through R13/R12/R11/R10 audit history per R10 §10.6 preservation rule), the **TL;DR Last-updated lead clause** is the canonical "what just happened" reader-skim signal. Current state lags canonical by:

| Date | Canonical event (per overview row 19 + backtrack-log) | TL;DR L101 status |
|------|------------------------------------------------------|--------------------|
| 2026-05-14 | IMPL-FIX-012 iter-1 ✅ CLOSED | ✅ current (this is what L101 says) |
| 2026-05-17 | IMPL-FIX-012 iter-2 Run #4 ❌ (ADR-014 partial; Jan-27 mass-close class) | ❌ missing |
| 2026-05-17 | IMPL-FIX-012 iter-3 Run #5 ❌ (ADR-014 INSUFFICIENT; Jan-06 BI pyramiding 3rd class; cap-3 exhausted) | ❌ missing |
| 2026-05-17 | fix-round-26 ✅ CLOSED (6/6 Accept; IMPL-FIX-013 P5 row added; Gate #9 clause (h) extended) | ❌ missing |
| 2026-05-17 | BT-002 OPEN (Operator selected Option 1 legacy-parity) | ❌ missing |
| 2026-05-17 | BT-002 SD-side cascade: Round 07 → rebuttal-05 → Round 08 → rebuttal-06 → Round 09 verify-only 0 findings ✅ | ❌ missing |
| 2026-05-18 | BT-002 BA-side cascade: Round 06 → rebuttal-05 ✅ + BT-002 ✅ CLOSED + `/project-init --regen` commit `7ff6f43` | ❌ missing |

**5 canonical closure events** spanning **4 calendar days** between current L101 anchor (2026-05-14) and review date (2026-05-18). Compare with R14 §14.2 which caught L95 at **3 rebuttal rounds behind same calendar day (2026-05-13)** — this round catches L101 at **2× magnitude** at next-cascade-event boundary.

L101 reads `Last updated: 2026-05-14` but the TL;DR audit-history at L7 (top entry, post-R10 §10.6 reader-empathy reorg) DOES include the 2026-05-17 IMPL-FIX-012 iter-3 Run #5 ❌ narrative. This is the same shape R14 caught at L93/L94/L95 vs L7+ audit-history: **audit-history block updated incrementally but canonical Last-updated lead clause not bumped**. Recurring weakness at primary-SoT-internal TL;DR layer.

**Why this matters:**

1. **Same defect class progression as R12 → R13 → R14 chain** at next-meta-axis: R12 caught backtrack-log↔impl-plan; R13 caught impl-plan↔overview.md; R14 caught TL;DR-narrative↔Plan-Staleness-Sentinel-canonical (intra-primary-SoT). R15 catches **TL;DR-Last-updated↔TL;DR-audit-history-top-entries** drift (intra-TL;DR-block axis) AT post-BT-002 cascade magnitude. The TL;DR audit-history block (L7-L96) accumulates incrementally per closure event; the L101 Last-updated lead clause requires explicit "current canonical event" rewrite per R10 §10.6 boundary clarification (lead clauses = canonical-current; per-entry boilerplate triad = audit-history retained verbatim). L101 falls into the canonical-current category and got missed in the 2026-05-17 closure burst (IMPL-FIX-012 iter-2/3 + fix-round-26 + BT-002 OPEN) and the 2026-05-18 BT-002 CLOSE.

2. **Reader-side first-impression impact (CRITICAL)**: per `andm-impl-plan-reviewer/SKILL.md` Dim #10 reader-skim discipline + R14 §14.2 reader-side analysis. Tech Lead / PM running `/next` reads TL;DR L101 as canonical "what just happened" signal. Current L101 says "IMPL-FIX-012 iter-1 ✅ CLOSED" — they would correctly infer Last-updated: 2026-05-14 but mis-infer that iter-1 was the latest event. The Plan Staleness Sentinel block (L2337) is **23 sections + ~2240 lines below** L101 in the file — outside any reasonable reader-skim window. Backtrack-log.md § BT-002 (the actual canonical lifecycle SoT for the BT-002 event) is in a **different file** entirely. **Reader has no signal that BT-002 even happened from impl-plan.md alone.** This compounds with Claim 15.1 (zero `\bBT-002\b` hits anywhere in impl-plan.md).

3. **Status agent + dashboard rendering**: a status agent reading L101 reports `"📝 /impl-task IMPL-FIX-012 iter-1 ✅ CLOSED — ADR-013 DEAL_REASON_EXPERT filter applied"` as the latest closure event, **missing**: (a) iter-2 fail; (b) iter-3 fail; (c) cap-3 exhaustion + escalation gate; (d) `/backtrack sd` execution; (e) BT-002 SD-side 3-round chain closure; (f) BT-002 BA-side 1-cycle closure; (g) BT-002 lifecycle ✅ Closed Status flip; (h) `/project-init --regen` propagation. The R10 §10.4 P4 Phase Gate BLOCKED framing is again echoed forward (Claim 15.6 surfaces this at Phase Gate row layer).

**Minimum acceptable fix:**

L101 lead clause rewrite — replace
```
> **Last updated:** 2026-05-14 · last action: **🟢 `/impl-task IMPL-FIX-012` iter-1 ✅ CLOSED — ADR-013 DEAL_REASON_EXPERT filter applied + Step 0 diagnostic falsified ManageExits cooldown hypothesis + Step 1 patch (3 LOC in core/Orchestrator.mqh + ADR-013 ~210 LOC NEW) + Step 2 G1 PASS (0err/0warn/4705 ms) + G2 bootstrap_smoke 3-day PASS (0 halt + 0 ERROR; behavioral parity vs pre-patch 502.66 USD final balance). ...** · prior action (IMPL-062 Run #3): **🔴 ...** · prior action (R14): **📝 ...**
```
with
```
> **Last updated:** 2026-05-18 · last action: **📝 `/impl-plan-rebuttal claim-review-15.md` ✅ CLOSED 2026-05-18 — R15 N/N Accept (BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer). Cascaded with BT-002 ✅ Closed 2026-05-18 (backtrack-log.md § BT-002 Status flipped via SD Round 09 verify-only 0 findings 2026-05-17 commit e385ad0 + BA Round 06 1 LOW closed via rebuttal-05 2026-05-18 commit 863493e). BT-002 Resolution: Option 1 (remove BR-3.6 detector, legacy-parity); ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA; SD Services Catalog CircuitBreaker repurposed/removed across 5 docs; ADR-010 halt-trigger list amended (CircuitBreaker removed; HALTED state machine remains for handle-invalid + Phase 2 future triggers). Cascaded with IMPL-FIX-012 → close-by-BT-002 supersession (R15 §15.8) + IMPL-051 → cancel-by-BT-002 (R15 §15.7) + R15 surface drain across TL;DR + Phase Status P4 Notes + Open Risks R-3/R-13 + Next Best Action + Phase Gate P4 Empirical Demo + NFR-1.1 + Mid-Phase Audit Log + Closure Hygiene Status. Plan Staleness Sentinel updated to 2026-05-18 with R15 anchor (Closures-since-R09 unchanged at 1 per workflow.md Gate #4 — rebuttal cycle ≠ main task closure).** · prior action (fix-round-26 2026-05-17): **🟢 fix-round-26 ✅ CLOSED — 6/6 findings Accept (2 HIGH / 2 MEDIUM / 2 LOW); IMPL-FIX-013 P5 row added; Gate #9 clause (h) extended with class (ε) frozen legacy-file cites + 10 remaining survivors enumerated as scope-out per clause (i)(b)** · prior action (IMPL-FIX-012 iter-3 2026-05-17): **🔴 iter-3 Run #5 ❌ — ADR-014 INSUFFICIENT; 3rd false-positive class (BI pyramiding close-tk12+open-tk14 same tick); cap-3 budget exhausted → escalation gate fires → /backtrack sd (BT-002 NEW)** · prior action (IMPL-FIX-012 iter-2 2026-05-17): **🔴 iter-2 Run #4 ❌ — ADR-014 partial fix; new false-positive class via OrderGroupStartWorkflow Jan-27 mass-close** · prior action (IMPL-FIX-012 iter-1 2026-05-14): **🟢 iter-1 ✅ CLOSED — ADR-013 DEAL_REASON_EXPERT filter applied (3 LOC in core/Orchestrator.mqh + ADR-013 ~210 LOC NEW); G1 PASS + G2 bootstrap_smoke 3-day PASS (behavioral parity)** · prior prior action: (preserve existing R10/R14/IMPL-062-Run-#3/Phase-1B narrative blocks verbatim per R10 §10.6 audit-trail discipline).
```

(Preserve existing IMPL-FIX-012 iter-1 + IMPL-062 Run #3 + R14 + earlier narrative blocks verbatim — strikethrough-and-append pattern per R10 §10.6 + R11 §11.1 precedent.)

**Effort:** Low-Medium (1 lead-clause prepend with 5 new chained `prior action` markers; ~40-50 LOC narrative; preserves all prior history unchanged).

---

#### Claim 15.3: 🔴 CRITICAL — `impl-plan.md` L97 TL;DR `ตอนนี้:` reader-skim block reports `P4 16/17 — ... remaining: IMPL-063` but IMPL-063 ✅ CLOSED 2026-05-14 (per L2073 + L100 Resolved table); P4 = 17/17 ✅ structural; additionally zero BT-002 invalidation marker on the canonical reader-skim line (Claim 15.1 corollary)

**Location:** `docs/state/impl-plan.md` L97 — `"> **ตอนนี้:** P1 ✅ 17/17 + Phase Gate closed · P2 11/11 tasks \`[x]\` + Phase Gate Override 2026-05-03 (Path A) · P3 23/23 ✅ all slots + IMPL-013 · **P4 16/17 — IMPL-053..059 cross-slot quartet + HALTED matrix + Orchestrator + IMPL-060 entry .mq5 + IMPL-061/064/068 QA chain authoring + IMPL-017 (sweep compat) + IMPL-066 (journal-latency instrumentation) + IMPL-067 (10× DST regression ini + report) + IMPL-062 (Bucket A regression authoring + DISABLE_G4_FIXES guards) + IMPL-065 (tick latency NFR-2.1 instrumentation behind ENABLE_TICK_LATENCY) — EA core + full QA pipeline authoring surface complete**; remaining: **IMPL-063 (paired Bucket B; depends on IMPL-062 numeric drain)** + Tier 1.5 walk batch-3 to drain registry ... ✅ Mid-Phase Audit P4 GREEN (2026-05-04) — IMPL-057 unblocked. ..."` (~2500 char block).

**Problem:**

L97 is the canonical `**ตอนนี้:**` (what's the current state) lead block — first content line a reader hits per CLAUDE.md §6 + workflow.md Gate #8 reader-skim discipline. Current state reports P4 at 16/17. Empirical verification:

- L2073 IMPL-063 task block: `"- **Closed**: 2026-05-10 structural; **fully drained 2026-05-14 via Run #3 cascade closure** (paired-bundle G4-ON Run #3 + G4-OFF Run #2; informational delta = $0 documented; G4 BI SL fix verified empirically 11/11; ..."`
- L2066-2068 IMPL-063 E-AC: all 3 `[x]` closed (E-AC #1 informational delta documented; E-AC #2 J-Magic; E-AC #3 BI SL)
- L100 Deferred-AC Active: `"+ IMPL-063 Bucket B informational delta — 2026-05-14 Run #3 cascade"` in Resolved table

Therefore: **P4 = 17/17 ✅ structural** (was 16/17 pre-IMPL-063 closure; bumped 16→17 on 2026-05-14 but L97 TL;DR not bumped per R14 §14.4 same defect class).

Plus: L97 does NOT carry any BT-002 invalidation marker. Per overview.md L19 the canonical Impl Plan row status is `❌ Invalidated (BT-002 — 2026-05-17 escalation gate executed; cap-3 budget exhausted at IMPL-FIX-012 iter-3 Run #5; IMPL-051 → cancel-by-BT-002, IMPL-FIX-012 → close-by-BT-002 supersession; re-run /impl-plan-review all post-SD lock)`. The impl-plan.md `ตอนนี้:` line should mirror this canonical primary-derived view sync.

L97 also continues with: `+ Tier 1.5 walk batch-3 to drain registry (4 prior + 2 new = 6 P4 deferred-AC rows from IMPL-017/062/065/066/067 + IMPL-068 paired bundle)` — this enumeration is pre-IMPL-FIX-* burst-era (2026-05-04/05) and stale vs current 19 P4 + 1 P5 = 20 deferred-AC rows.

**Why this matters:**

1. **Reader-skim test fail at the canonical `ตอนนี้:` block** (Dim #10) — first content reader hits. Same defect class as R14 §14.4 L11 P2 row Notes column pre-BT-001 framing, now at higher-visibility surface (TL;DR `ตอนนี้` lead block vs Phase Status Snapshot row).

2. **Structural P4 16/17 claim cascades into Phase Gate Structural Acceptance check** (L1408 `all 17 P4 tasks ปิด [x] ครบ`). L1408 would pass empirically at 17/17 (IMPL-063 closed) but L97 reader inferring 16/17 mis-counts the Phase Gate Structural readiness. R10 §10.4 caught the prior version of this drift at Phase Gate row layer; R15 catches it at TL;DR layer.

3. **Zero BT-002 marker on canonical state-summary line**: same defect class root cause as Claim 15.1 surfaced at the most-skim-visible surface; reader infers project is in normal post-Mid-Phase-Audit-Green state, not in post-BT-002-cascade-cleanup state.

**Minimum acceptable fix:**

L97 ตอนนี้ block rewrite — replace
```
> **ตอนนี้:** P1 ✅ 17/17 + Phase Gate closed · P2 11/11 tasks `[x]` + Phase Gate Override 2026-05-03 (Path A) · P3 23/23 ✅ all slots + IMPL-013 · **P4 16/17 — IMPL-053..059 cross-slot quartet + HALTED matrix + Orchestrator + IMPL-060 entry .mq5 + IMPL-061/064/068 QA chain authoring + IMPL-017 (sweep compat) + IMPL-066 (journal-latency instrumentation) + IMPL-067 (10× DST regression ini + report) + IMPL-062 (Bucket A regression authoring + DISABLE_G4_FIXES guards) + IMPL-065 (tick latency NFR-2.1 instrumentation behind ENABLE_TICK_LATENCY) — EA core + full QA pipeline authoring surface complete**; remaining: **IMPL-063 (paired Bucket B; depends on IMPL-062 numeric drain)** + Tier 1.5 walk batch-3 ...
```
with
```
> **ตอนนี้:** P1 ✅ 17/17 + Phase Gate closed · P2 11/11 tasks `[x]` + Phase Gate Override 2026-05-03 (Path A; **IMPL-051 → cancel-by-BT-002 2026-05-18 — CircuitBreaker.mqh deletion pending impl-code cleanup per overview row 19 + backtrack-log § BT-002 § Impacted phases Impl Code; task block + audit history preserved per R10 §10.6 + R11 §11.1 strikethrough-append precedent**) · P3 23/23 ✅ all slots + IMPL-013 · **P4 ✅ 17/17 (was 16/17; bumped 2026-05-14 post-IMPL-063 closure via Run #3 cascade — informational delta = $0 documented; G4 BI SL fix verified empirically 11/11; G4 J magic-J fix verified structurally; criterion #2 dropped per BT-001 R12 §12.1) + IMPL-FIX-003/005/006/007/008/009/010 ✅ closed 2026-05-10**. **❌ BT-002 INVALIDATED 2026-05-17/18 — IMPL-FIX-012 iter-3 Run #5 (2026-05-17) cap-3 exhausted → /backtrack sd → SD Round 09 (commit e385ad0) + BA Round 06 (commit 863493e) 0 findings 2026-05-17/18 → CircuitBreaker BR-3.6 ping-pong detector revert authorized per Option 1 (legacy-parity). ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA layer. Pending impl-code cleanup: DELETE services/CircuitBreaker.mqh + strip Record{Open,Close} dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from core/Orchestrator.mqh::OnTradeTransaction + remove CheckPingPong from OnTick + DELETE spike/Spike_CircuitBreaker.mq5 + verify domain/EnumTypes.mqh HALT_PINGPONG removal + mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal on no-detector default build).** Remaining work post-BT-002: impl-code cleanup ~1-2 hr (single session; G1+G2+G3 within session) → IMPL-062 re-execute on no-detector default build (NFR-1.1 acceptance per rewrite-no-detector vs baseline single-pass methodology per BT-001 R12 §12.1 + BT-002 closure). Tier 1.5 walk batch-3 drained 2026-05-09/10 ✅; batch-4 alongside post-BT-002 IMPL-062 single-session. **Mid-Phase Audit P4 GREEN (2026-05-04) — IMPL-057 unblocked; mid-phase audit state preserved across BT-002 cascade.**
```

**Effort:** Low (1 lead-block rewrite preserving structure; ~30-40 LOC narrative).

---

#### Claim 15.4: 🔴 CRITICAL — `impl-plan.md` L199 + L200 + L201 Next Best Action checklist still claims `/impl-task IMPL-FIX-012 Step 3 G3 5-yr Bucket A retry (Run #4)` is next operator action + `P2 + P3 + P4 Phase Gate close` blocked on Run #4; Run #4 = iter-2 (2026-05-17 ❌); Run #5 = iter-3 (2026-05-17 ❌); cap-3 exhausted; BT-002 cascade fired + closed 2026-05-18; IMPL-FIX-012 → close-by-BT-002 supersession; impl-code cleanup pending; intra-section dependency-arrow stale; cascades into `/next` Check 5.7 backlog mis-render

**Location:** `docs/state/impl-plan.md` L199 + L200 + L201 (Next Best Action checklist):
- L198: `"☑ ~~NEXT — /impl-task IMPL-FIX-012 (NEW 2026-05-14, M [ea] HIGH severity)~~ ✅ iter-1 CLOSED 2026-05-14"` — historical correct
- L199: `"☐ NEXT — operator session: /impl-task IMPL-FIX-012 Step 3 G3 5-yr Bucket A retry (Run #4) — launch terminal64.exe /config:simulation/headless-tests/regression_5yr_g4.ini (~30-60 min wall-clock per IMPL-FIX-009 perf restoration). Verify: (a) simulation reaches ≥ 3 sim months past Slot_H Jan-14 storm point without circuit_breaker_pingpong halt → ADR-013 confirmed effective; (b) if reaches 5-yr completion AND drift ≤ 25% → IMPL-062 E-AC #1+#2 close + cascade IMPL-068 force-clear validation + IMPL-066 journal latency long-sample → P2/P3/P4 Tier 2 Phase Gate close path opens; ... Cap-3 sequencing: iter-1 ✅ (this session); iter-2 conditional pending Run #4; iter-3 escalation gate."`
- L200: `"☐ P2 + P3 Phase Gate retroactive close — still blocked on IMPL-FIX-012 Step 3 Run #4 → 29 P2/P3 deferred-AC rows drainage"`
- L201: `"☐ P4 Phase Gate close — still blocked on IMPL-FIX-012 Step 3 Run #4 → 17 P4 deferred-AC rows drainage + Tier 1.5 walk batch-4"`

**Problem:**

L199 states cap-3 sequencing in its own body: `"iter-1 ✅ (this session); iter-2 conditional pending Run #4; iter-3 escalation gate"`. Per IMPL-FIX-012 task-block Status entries L1986-1990 + TL;DR L7 + overview.md L19 + backtrack-log § BT-002 L38-44, the cap-3 budget was fully consumed 2026-05-17:

- iter-1 ✅ 2026-05-14 (ADR-013 DEAL_REASON filter; G1+G2 PASS)
- iter-2 ❌ 2026-05-17 Run #4 (ADR-014 partial; OrderGroupStartWorkflow Jan-27 mass-close false-positive class)
- iter-3 ❌ 2026-05-17 Run #5 (ADR-014 INSUFFICIENT; 3rd false-positive class — BI pyramiding close-tk12+open-tk14 same tick; halt 8 sim days EARLIER than baseline at sim 2021-01-06 02:50:48)
- Cap-3 exhausted → escalation gate fires → `/backtrack sd` (BT-002 OPENED)
- BT-002 ✅ Closed 2026-05-18 → IMPL-FIX-012 → close-by-BT-002 supersession (per overview L19 + backtrack-log § BT-002 § Impacted phases Impl Plan L64)

The L199 checklist line is **literally referring to a budgeted future event that has already played out + failed + escalated + resolved**. The own L199 body cap-3 reference (`iter-3 escalation gate`) is the **next-tick consequence** of what actually happened — iter-3 = escalation gate fires = `/backtrack sd` = BT-002. The checklist row was never updated post-2026-05-14.

L200 + L201 carry the same stale dependency-arrow at downstream Phase Gate close rows. Per `backtrack-log.md § BT-002 § Impacted phases Impl Code` (line 65), the actual next operator action is:

> `DELETE services/CircuitBreaker.mqh; strip Record{Open,Close} dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from core/Orchestrator.mqh::OnTradeTransaction; remove CheckPingPong call from OnTick; DELETE spike/Spike_CircuitBreaker.mq5; verify domain/EnumTypes.mqh for HALT_PINGPONG constant removal; mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal)`

— single-session impl-code cleanup (~1-2 hr) + then `/impl-task IMPL-062` re-execute (NFR-1.1 acceptance gate via rewrite-no-detector vs baseline single-pass).

**Why this matters:**

1. **`/next` Check 5.7 propagation**: `/next` reads `## Next Best Action` to surface backlog. Stale L199 → backlog reports `Run #4 retry` as primary unchecked action → operator runs `/impl-task IMPL-FIX-012`, which would HALT (after R15 §15.8 fix applies the cancel-by-BT-002 pivot) or RUN (without the fix) and re-execute a doomed iter-4 (cap-3 exhausted means iter-4 is structurally forbidden per IMPL-FIX-012 task-block § Description Step 5 + cap-3 sequencing).

2. **Reader-skim test fail at the canonical decision-tree section** (Dim #10): R14 §14.3 caught L191/L192/L193 IMPL-FIX-003 stale-dependency-arrow at intra-section contradiction layer. R15 §15.4 catches L199/L200/L201 IMPL-FIX-012 stale-dependency-arrow at next-event-after-R14 layer. Same shape (stale dependency-arrow); larger scope (3 events stale not 1 closure).

3. **Intra-section consistency** (Gate #6 file-integrity analog + Gate #8 narrative-section freshness sweep): L198 strikethrough-anchor `~~NEXT — /impl-task IMPL-FIX-012~~ ✅ iter-1 CLOSED 2026-05-14` is correct as historical event. L199 should immediately follow with `~~NEXT — Run #4 retry~~` ✅ → ❌ historical, and a new `☐ NEXT — operator session: impl-code BT-002 cleanup` ☐ row should be added. L200 + L201 similarly need stale-dependency replacement.

**Minimum acceptable fix:**

L199 replace:
```
☐ **NEXT — operator session: `/impl-task IMPL-FIX-012` Step 3 G3 5-yr Bucket A retry (Run #4)** — launch ... Cap-3 sequencing: iter-1 ✅ (this session); iter-2 conditional pending Run #4; iter-3 escalation gate.
```
with
```
☑ ~~**NEXT — operator session: `/impl-task IMPL-FIX-012` Step 3 G3 5-yr Bucket A retry (Run #4)**~~ ❌ **iter-2 Run #4 ❌ 2026-05-17 (ADR-014 partial; Jan-27 OrderGroupStartWorkflow mass-close false-positive class) → iter-3 Run #5 ❌ 2026-05-17 (ADR-014 INSUFFICIENT; Jan-06 BI pyramiding 3rd false-positive class; halt 8 sim days EARLIER than baseline; cap-3 budget exhausted) → escalation gate fires → `/backtrack sd` → BT-002 OPENED 2026-05-17 + ✅ CLOSED 2026-05-18 (SD Round 09 verify-only 0 findings commit `e385ad0` + BA Round 06 1 LOW closed via rebuttal-05 commit `863493e`; CircuitBreaker BR-3.6 ping-pong detector revert authorized per Option 1 legacy-parity). IMPL-FIX-012 → close-by-BT-002 supersession (R15 §15.8); IMPL-051 → cancel-by-BT-002 (R15 §15.7).**

- ☐ **NEXT (post-BT-002 closure 2026-05-18) — operator session: impl-code BT-002 cleanup (~1-2 hr single session)** — per `backtrack-log.md § BT-002 § Impacted phases Impl Code` (line 65): (a) DELETE `services/CircuitBreaker.mqh`; (b) strip `Record{Open,Close}` dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from `core/Orchestrator.mqh::OnTradeTransaction`; (c) remove `CheckPingPong` call from `OnTick`; (d) DELETE `spike/Spike_CircuitBreaker.mq5`; (e) verify `domain/EnumTypes.mqh` `HALT_PINGPONG` constant removal; (f) mandatory G1+G2+G3 re-run within same session (NFR-1.1 acceptance signal on no-detector default build); (g) commit + push. Then `/impl-task IMPL-062` re-execute Bucket A 5-yr regression on rewrite no-detector default build per BT-001 R12 §12.1 single-pass methodology + BT-002 no-CircuitBreaker-class methodology — produce Net Profit deviation vs baseline ($24.27M) per NFR-1.1 ≤ 25%.
```

L200 replace `"still blocked on IMPL-FIX-012 Step 3 Run #4 → 29 P2/P3 deferred-AC rows drainage"` → `"~~still blocked on IMPL-FIX-012 Step 3 Run #4~~ (IMPL-FIX-012 closed-by-BT-002 supersession 2026-05-18) — now blocked on impl-code BT-002 cleanup + post-BT-002 IMPL-062 re-execute paired-bundle operator session → 30 P2/P3 deferred-AC rows drainage (5 P2 + 25 P3)"`

L201 replace `"still blocked on IMPL-FIX-012 Step 3 Run #4 → 17 P4 deferred-AC rows drainage + Tier 1.5 walk batch-4"` → `"~~still blocked on IMPL-FIX-012 Step 3 Run #4~~ (closed-by-BT-002 supersession 2026-05-18) — now blocked on impl-code BT-002 cleanup + post-BT-002 IMPL-062 re-execute paired-bundle session → 19 P4 deferred-AC rows drainage + Tier 1.5 walk batch-4 (drains alongside IMPL-062 single-session per workflow.md Cold-Bootstrap Recipe)"`

**Effort:** Low (3 in-place phrase replaces + 1 new checklist row added; ~20-30 LOC).

---

### 🟠 HIGH

#### Claim 15.5: 🟠 HIGH — `impl-plan.md` L118 Phase Status Snapshot P4 row Notes column carries pre-2026-05-17 framing referencing IMPL-FIX-012 iter-1 + ADR-013 as live; iter-2/iter-3 cap-3 exhaustion + ADR-013/014 supersession + BT-002 cascade not reflected; symmetric to Claim 14.4 (P2/P3 Notes pre-BT-001 framing) at P4 Notes post-BT-002 layer

**Location:** `docs/state/impl-plan.md` L118 (Phase Status Snapshot P4 row Notes column tail):
- `"... ✅ Mid-Phase Audit P4 GREEN 2026-05-04 ... **Remaining work (post-BT-001):** operator paired-bundle 5-yr drain on rewrite default build (G4-ON, single-pass) = IMPL-062 Bucket A single-pass + IMPL-063 informational Bucket B (paired G4-ON + G4-OFF within same task per R12 §12.2 S-AC repurpose) — both unblocked. Numeric-drain residue ... now drains alongside IMPL-062/063 single-pass run, NOT downstream of any further /backtrack event ..."`

Note: this column extends ~6000 chars and references IMPL-FIX-012 iter-1 + ADR-013 at multiple points; the canonical-current "remaining work" claim states "both unblocked" + "NOT downstream of any further /backtrack event" — both invalidated by post-2026-05-14 events.

**Problem:**

The P4 Notes column "Remaining work (post-BT-001)" closing paragraph (added via R12 §12.3 fix) was authored 2026-05-13 as part of BT-001 closure cascade. Subsequent events:

- 2026-05-14 IMPL-062 Run #3 ❌ (drift = 100.0022%; same halt class as Run #2 — Slot_H ping-pong @ Jan-14)
- 2026-05-14 IMPL-FIX-012 NEW authored (Slot_H pyramid same-bar cooldown)
- 2026-05-14 IMPL-FIX-012 iter-1 ✅ (ADR-013 DEAL_REASON filter pivot)
- 2026-05-17 IMPL-FIX-012 iter-2 ❌ (ADR-014 partial; Jan-27 mass-close class)
- 2026-05-17 IMPL-FIX-012 iter-3 ❌ (ADR-014 INSUFFICIENT; cap-3 exhausted)
- 2026-05-17/18 BT-002 OPEN → CLOSE

The "Remaining work" claim `"both unblocked"` + `"NOT downstream of any further /backtrack event"` is structurally invalidated by BT-002 cascade. R-3 + R-13 Open Risks rows (Claim 15.9) carry the same defect at narrative layer — Phase Status Snapshot has it at canonical-tabular layer.

**Why this matters:**

1. **Reader-skim impact at Phase Status Snapshot** (Dim #10): per overview.md schema + R10 §10.2 § Phase Status Snapshot reader-skim discipline, this is the canonical 4-row table for phase progress. Tech Lead reading P4 row sees "both unblocked" → infers IMPL-062 + IMPL-063 numeric drain is operator-session-feasible — true at 2026-05-13 framing, **invalidated by 2026-05-14 Run #3 fail and BT-002 cascade since**.

2. **Same defect class as R14 §14.4** (overview.md L11 P2 row Notes column tail post-BT-001 framing surfacing as L110/L111 in impl-plan per rebuttal-14 §14.4 location correction). R14 caught P2/P3 pre-BT-001 tail; R15 catches P4 post-BT-001-pre-BT-002 tail at next-cascade-event boundary.

**Minimum acceptable fix:**

Append at the end of L118 P4 row Notes column tail (preserve all prior R10 §10.2 + R12 §12.3 narrative verbatim per R10 §10.6 audit discipline):

```
**Post-2026-05-14 update:** Run #3 (2026-05-14) executed on rewrite-G4-ON default build (BT-001 single-pass methodology) → NFR-1.1 FAIL drift = 100.0022%; same halt class as Run #2 (`circuit_breaker_pingpong` Slot_H magic=205 @ sim 2021-01-14 14:59:21); G4 fix portfolio impact = $0; reveals R-13 long-tail Slot_H clustering as proximate ping_pong trigger. IMPL-063 ✅ CLOSED via Run #3 cascade (informational delta = $0); IMPL-062 E-AC #1+#2 stay deferred (registry expiry renewed 2026-05-28 renewal #1 of max 2); IMPL-FIX-012 authored as Slot_H sub-ticket. **Post-2026-05-17 update (BT-002 cascade):** IMPL-FIX-012 cap-3 budget consumed (iter-1 ✅ ADR-013 + iter-2 ❌ ADR-014 partial Jan-27 mass-close class + iter-3 ❌ ADR-014 INSUFFICIENT Jan-06 BI pyramiding 3rd class) → escalation gate → `/backtrack sd` (BT-002 OPEN 2026-05-17) → SD Round 09 verify-only 0 findings (commit e385ad0) + BA Round 06 1 LOW closed via rebuttal-05 (commit 863493e) → BT-002 ✅ CLOSED 2026-05-18 (Option 1 legacy-parity; remove BR-3.6 detector). ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA layer. **New remaining work (post-BT-002 closure 2026-05-18):** (a) impl-code BT-002 cleanup ~1-2 hr single session — DELETE services/CircuitBreaker.mqh + strip dispatch + remove HALT_PINGPONG + mandatory G1+G2+G3 re-run; (b) IMPL-062 re-execute Bucket A 5-yr regression on rewrite no-detector default build (NFR-1.1 acceptance signal); (c) IMPL-068 + IMPL-066 numeric drain alongside IMPL-062 single-session; (d) Tier 1.5 walk batch-4 alongside. IMPL-FIX-012 → close-by-BT-002 supersession (R15 §15.8); IMPL-051 → cancel-by-BT-002 (R15 §15.7); Phase Gate Override Log + Mid-Phase Audit Log preserved across BT-002 cascade. Cascaded with Claim 15.6 P4 Phase Gate Empirical Demo + NFR-1.1 subrow refresh.
```

**Effort:** Low-Medium (1 in-place tail append; ~30-40 LOC narrative).

---

#### Claim 15.6: 🟠 HIGH — `impl-plan.md` L1409 P4 Phase Gate `Empirical Demo` row + L1414 `NFR-1.1` sub-row carry "✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2)" framing without Run #3 fail (2026-05-14) + Run #4/5 fail (2026-05-17) + BT-002 cascade closure (2026-05-18); Phase Gate testable-exit text now misleads engineer/operator on acceptance path

**Location:**
- L1409: `"- [ ] **Empirical Demo:** ✅ **RESOLVED 2026-05-12 via BT-001 (R11 §11.2)** — BA Round 05 + SD Round 06 closed 2026-05-13 redefining measurement methodology: NFR-1.1 = **rewrite-G4-ON vs baseline single-pass** (BA \`03 § NFR-1.1 Verification\`); NFR-1.8 = informational delta \`rewrite-G4-ON − rewrite-G4-OFF\` (no acceptance gate). Prior R10 §10.4 BLOCKED annotation premise was that /backtrack ba is future-pending but BT-001 chain landed earlier same day. ... **Original gate text (preserved for audit):** full 5-yr Strategy Tester regression 2021-Jan-01 → 2025-Dec-31 on EURUSD H4 with $1000 deposit + leverage 500 → produces \`ReportTester-<run-id>.html\` + \`journal/tester/run-<ISO>.jsonl\`. **Bucket A drift ≤ 25% Net Profit deviation per NFR-1.1** ..."`
- L1414: `"- [ ] NFR-1.1 Bucket A Net Profit deviation ≤ 25% (IMPL-062) — ✅ **CONTRACT RESOLVED 2026-05-12 via BT-001 (R11 §11.2)**: methodology redefined rewrite-G4-ON vs baseline single-pass; Run #1 + Run #2 ..."`

**Problem:**

The P4 Phase Gate "Empirical Demo" row + "NFR-1.1" sub-row claim `✅ RESOLVED via BT-001` — true at the **methodology contract layer** (NFR-1.1 redefined; no further `/backtrack ba` needed for measurement framing). But the **empirical-acceptance-on-the-redefined-contract** is **not resolved**:

- Run #3 (2026-05-14 on rewrite-G4-ON single-pass per BT-001 R12 §12.1 methodology) → NFR-1.1 FAIL drift = 100.0022% (catastrophic; same halt class as Run #2). The BT-001 closure was necessary but not sufficient.
- IMPL-FIX-012 chain (iter-1/2/3) attempted producer-side patch + dedup refinement → cap-3 exhausted 2026-05-17.
- BT-002 ✅ Closed 2026-05-18 with Resolution = remove BR-3.6 detector entirely (legacy-parity safety contract).
- **New empirical acceptance path** (per BT-002 closure): rewrite-no-detector default build vs baseline single-pass → no CircuitBreaker halt-class risk; Run #6 on no-detector build = canonical NFR-1.1 acceptance trial.

Per workflow.md § Phase 5 Closure mechanical gates + Phase Gate testable-exit discipline, the Phase Gate text should describe the **current** acceptance path, not the **pre-cascade** acceptance path. R10 §10.4 caught the pre-BT-001 BLOCKED framing and R11 §11.2 fixed it post-BT-001; R15 §15.6 catches the pre-BT-002 post-BT-001 framing and the rebuttal needs to refresh it post-BT-002.

**Why this matters:**

1. **Phase Gate testable-exit clarity**: an engineer attempting Phase Gate close per L1409 reading `"✅ RESOLVED 2026-05-12 via BT-001"` infers the empirical demo is closed — false. Reader needs the post-BT-002 framing to understand `(a) contract was resolved BT-001; (b) empirical attempt Run #3 failed BT-001-correct but unresolved BR-3.6 detector; (c) BT-002 resolves detector; (d) Run #6 on no-detector build pending — that is the empirical demo`.

2. **Same defect class as Claim 14.4** (P2/P3 Notes pre-BT-001 framing) at Phase Gate row layer, post-BT-002.

3. **L1414 NFR-1.1 sub-row** carries identical structural drift at NFR-checklist sub-layer; engineer reading the NFR checklist as canonical acceptance-criterion source mis-infers NFR-1.1 resolved.

**Minimum acceptable fix:**

L1409 Empirical Demo row append after `"✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2)"` and before the `"Original gate text"` block:

```
**Post-2026-05-14 update (BT-002 cascade):** BT-001 closure resolved the **measurement methodology** but the empirical acceptance trial on the BT-001-redefined contract surfaced a structural detector-layer defect. Run #3 (2026-05-14 on rewrite-G4-ON single-pass per BT-001 methodology) → NFR-1.1 FAIL drift = 100.0022%; halt via `circuit_breaker_pingpong` Slot_H @ sim 2021-01-14. IMPL-FIX-012 cap-3 chain (iter-1 ADR-013 + iter-2 ADR-014 + iter-3 ADR-014 INSUFFICIENT) consumed; escalation gate fired → `/backtrack sd` (BT-002 OPEN 2026-05-17). **BT-002 ✅ CLOSED 2026-05-18** (Option 1 legacy-parity; remove BR-3.6 detector; ADR-013/014 Superseded; BR-3.6 + FR-6.6 demoted at BA; SD Services Catalog CircuitBreaker repurposed/removed across 5 docs; ADR-010 halt-trigger list amended — CircuitBreaker removed; HALTED state machine remains for handle-invalid + Phase 2 future triggers). **New canonical empirical demo (post-BT-002):** Run #6 on rewrite-no-detector default build vs baseline single-pass — no CircuitBreaker halt-class risk per BT-002 closure; legacy baseline $24.27M achieved without ping-pong detector per backtrack-log § BT-002 § Reason (empirical proof safety capability not load-bearing for EA's known trading pattern set). Acceptance: |drift| ≤ 25% Net Profit deviation per NFR-1.1 + per-slot trade count ratio ≥ 90% per NFR-1.6. Pre-condition: impl-code BT-002 cleanup committed (DELETE services/CircuitBreaker.mqh + strip Orchestrator dispatch + remove HALT_PINGPONG + G1+G2+G3 re-run). Estimated operator wall-clock: impl-code cleanup ~1-2 hr + Run #6 ~30-60 min + journal/log parse ~10 min = single ~3 hr session covers Phase Gate Empirical Demo. See `backtrack-log.md § BT-002 § Resolution` + `docs/state/backtrack-log.md § BT-002 § Impacted phases Impl Code` (line 65 cleanup checklist).
```

L1414 NFR-1.1 sub-row append after `"✅ CONTRACT RESOLVED 2026-05-12 via BT-001 (R11 §11.2)"`:

```
**Post-BT-002 update (2026-05-18):** Run #3 (2026-05-14 on BT-001-redefined contract) FAIL drift = 100.0022%; IMPL-FIX-012 cap-3 chain consumed; BT-002 closed 2026-05-18 (remove detector; legacy-parity). New acceptance trial = Run #6 on rewrite-no-detector default build per BT-002 closure methodology; pending impl-code BT-002 cleanup + paired-bundle IMPL-062 re-execute.
```

**Effort:** Low-Medium (2 in-place appends; ~25-35 LOC).

---

#### Claim 15.7: 🟠 HIGH — `impl-plan.md` L892-907 IMPL-051 task block still marked `Closed: 2026-05-03 (commit de087fe)` without `cancel-by-BT-002 2026-05-18` annotation; per overview.md L19 + backtrack-log § BT-002 § Impacted phases Impl Plan L64 the task block requires explicit cancellation marker; CircuitBreaker.mqh impl deletion pending impl-code cleanup separately

**Location:** `docs/state/impl-plan.md` L892-907 (IMPL-051 task block):
- L892: `"#### IMPL-051: [S] [ea] — services/CircuitBreaker::CheckPingPong() (BR-3.6 3000ms threshold)"`
- L897: `"- **Input**: TD-02 §5.8, BR-3.6, FR-6.6, ADR-010"`
- L901-902: 2 E-AC rows
- L907: `"- **Closed**: 2026-05-03 (commit de087fe); G1 = 0 errors / 0 warnings on Spike_StatePersistence baseline (no regression); inline SelfTest() validates 4 cases (1500s detect / 4000s near-miss / 6000s no-trigger / different-magics no-trigger); G2-G4 = header-only .mqh task — Orchestrator wiring at IMPL-053+ activates G2-G4 gates; evidence _session-handoff/IMPL-051-evidence-20260503.md"`

**Problem:**

Per `backtrack-log.md § BT-002 § Impacted phases Impl Plan` line 64:

> `docs/state/impl-plan.md` IMPL-051 (cancel), IMPL-FIX-012 task closure pivots from `[ ]` "iter-3 fails" → `[x]` "BT-002 supersedes — detector removed at SD/BA"; re-run `/impl-plan-review all` after SD lock; IMPL-062/063 paired-bundle stays gated on G3 5-yr re-run post-BT-002

The IMPL-051 task block requires a `cancel-by-BT-002` annotation. Per overview.md L19 (`Impl Plan` status string): `"IMPL-051 → cancel-by-BT-002, IMPL-FIX-012 → close-by-BT-002 supersession; re-run /impl-plan-review all post-SD lock"`. The task block at L892-907 has zero BT-002 mention.

Note: per `backtrack-log.md § BT-002 § Impacted phases Impl Code` (line 65), the IMPL-051 produced artifact (`services/CircuitBreaker.mqh`) is scheduled for deletion as part of impl-code cleanup. The task block annotation should reflect:

1. Task remains `Closed: 2026-05-03` for audit history (work was performed; the impl is real; SelfTest passed)
2. Task is **superseded** by BT-002 cascade decision to remove BR-3.6 detector entirely
3. Produced artifact pending deletion in separate impl-code cleanup session
4. Input field references (TD-02 §5.8, BR-3.6, FR-6.6, ADR-010) need annotation: TD-02 §5.8 CCircuitBreaker class skeleton DELETE pending per backtrack-log § BT-002 § Impacted phases TD (line 62); BR-3.6 + FR-6.6 demoted at BA per backtrack-log § BT-002 § Proposed change (BA) lines 58; ADR-010 amended (CircuitBreaker removed from halt-trigger list) per backtrack-log § BT-002 § Proposed change line 55.

**Why this matters:**

1. **Task-block-as-canonical-record** (CLAUDE.md §6 State SoT): per `/impl-task` dispatch logic + Phase Gate structural acceptance check + `/deliver` final readiness gate, each task block is the canonical record of work + ADR backing + AC status. A task with stale Input field references pointing to deleted/superseded artifacts is a structural inconsistency that propagates to downstream consumers.

2. **Reader-side**: engineer reading IMPL-051 task block sees Status `Closed: 2026-05-03` + Input `BR-3.6, FR-6.6, ADR-010` → infers task is canonical-closed and produced artifact is canonical-current. False post-BT-002: artifact pending deletion; input references demoted/amended.

3. **Phase Gate Structural Acceptance** (L1408 `"all 17 P4 tasks ปิด [x] ครบ"`) — IMPL-051 is P2 not P4 so doesn't affect P4 count, but Phase Gate Override Log + P2 Notes column reference IMPL-051 closure as part of P2 11/11; the cancel-by-BT-002 annotation needs to land in audit trail.

**Minimum acceptable fix:**

L907 Closed line append (after existing closure text, preserve verbatim):

```
**Cancelled-by-BT-002 2026-05-18:** per `backtrack-log.md § BT-002 § Impacted phases Impl Plan` L64 (`IMPL-051 (cancel)`) + § Impacted phases Impl Code L65 (`DELETE services/CircuitBreaker.mqh`). BT-002 resolution removed BR-3.6 detector entirely per Option 1 (legacy-parity); CircuitBreaker mechanism reverted; ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA layer; SD Services Catalog `CircuitBreaker` row repurposed/removed across 5 design docs; ADR-010 halt-trigger list amended (CircuitBreaker removed; HALTED state machine remains for handle-invalid + Phase 2 future triggers). **Implementation-side cleanup pending** (separate session ~1-2 hr): DELETE `services/CircuitBreaker.mqh` + DELETE `spike/Spike_CircuitBreaker.mq5` + strip `Record{Open,Close}` dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from `core/Orchestrator.mqh::OnTradeTransaction` + remove `CheckPingPong` call from `OnTick` + verify `domain/EnumTypes.mqh` `HALT_PINGPONG` constant removal + mandatory G1+G2+G3 re-run (NFR-1.1 acceptance signal). **Audit history preserved per R10 §10.6 + R11 §11.1 strikethrough-append precedent** — IMPL-051 task remains canonical-closed at audit-trail level (commit `de087fe` SelfTest 4 cases attests implementation correctness); the cancellation reflects BT-002 architectural decision to remove the safety capability, not a defect in IMPL-051 work itself. **Input field annotation:** TD-02 §5.8 CCircuitBreaker class skeleton DELETE pending TD cascade (per `backtrack-log.md § BT-002 § Impacted phases TD` L62); BR-3.6 demoted Must → Won't at BA (per BT-002 BA cascade L60); FR-6.6 demoted similarly; ADR-010 amended (CircuitBreaker entry removed from halt-trigger list).
```

Also append to L897 Input field tail (after `"ADR-010"`):

```
 — **BT-002 status update 2026-05-18:** TD-02 §5.8 DELETE pending per BT-002 TD cascade; BR-3.6 demoted Must → Won't at BA; FR-6.6 demoted; ADR-010 amended (CircuitBreaker removed from halt-trigger list)
```

**Effort:** Low (2 in-place appends preserving all prior content; ~25-35 LOC).

---

#### Claim 15.8: 🟠 HIGH — `impl-plan.md` L1961-1990 IMPL-FIX-012 task block has 3 Status entries (iter-1 close, iter-3 fail, iter-3 patch, iter-2 fail — out-of-order) but no final `close-by-BT-002 supersession` Status row; E-AC L1976/L1977 reference Run #4 + Run #5 as future-pending but those Runs ran ❌ and the entire detector mechanism is now reverted; ADR field L1981 cites ADR-013 as live but ADR-013 + ADR-014 Superseded per backtrack-log L56

**Location:** `docs/state/impl-plan.md` L1961-1990 (IMPL-FIX-012 task block):
- L1961: `"#### IMPL-FIX-012: [M] [ea] — Slot_H pyramid same-bar cooldown (R-13 sub-ticket; ...)"`
- L1973: S-AC #2 closes via ADR-013 application (text references ADR-013 as Active)
- L1976: `"- [ ] G3 5-yr Bucket A retry (Run #4) reaches ≥ 3 sim months past Slot_H Jan-14 storm point without circuit_breaker_pingpong halt [log-assertion] + [db-inspect] — deferred to next operator session paired with IMPL-062 E-AC #1 retry (~30-60 min)"`
- L1977: `"- [ ] If Run #4 reaches sim 2025-12-31: IMPL-062 E-AC #1 |drift| ≤ 25% NFR-1.1 retry [db-inspect] — deferred as paired bundle ..."`
- L1981: `"- **ADR**: ADR-013 (NEW 2026-05-14) — CircuitBreaker BR-3.6 ping-pong scope refinement: DEAL_REASON_EXPERT filter"`
- L1984: Status (iter-1 close, this commit 2026-05-14)
- L1986: Status (iter-3 — Run #5 EXECUTED 2026-05-17, ADR-014 INSUFFICIENT — REGRESSED EARLIER; cap-3 budget exhausted → escalation gate fires)
- L1988: Status (iter-3 PATCH — ADR-014 LANDED 2026-05-17, awaiting G3 5-yr Run #5)
- L1990: Status (iter-2 — Run #4 EXECUTED 2026-05-17, E-AC #1 NOT MET)

**Problem:**

The IMPL-FIX-012 task block has 4 Status entries documenting the iter-1/2/3 chain through 2026-05-17 cap-3 exhaustion. But:

1. **No final Status row marking BT-002 closure**: per overview.md L19 (`IMPL-FIX-012 → close-by-BT-002 supersession`) + backtrack-log L64 (`IMPL-FIX-012 task closure pivots from [ ] "iter-3 fails" → [x] "BT-002 supersedes — detector removed at SD/BA"`). The task is structurally `close-by-supersession` but the block has no canonical pivot annotation.

2. **E-AC L1976 + L1977 still `[ ]` deferred to Run #4** — Run #4 + Run #5 ran ❌; per BT-002 closure (remove detector) these E-ACs are **structurally invalid** (the detector being verified is being removed; the halt-class being tested no longer exists post-cleanup). Need `[x] Superseded by BT-002 2026-05-18` closure annotation.

3. **ADR field L1981 cites ADR-013 as canonical-Active** — per backtrack-log § BT-002 § Proposed change L56: `ADR-013 + ADR-014: status flipped Accepted → Superseded by BT-002 — preserved as audit history (the iter-1/-2/-3 chain documents the falsification path)`. Field needs amendment.

4. **Status entries L1986 + L1988 + L1990 are out-of-chronological-order** (iter-3 closure listed before iter-3 PATCH and iter-2). Audit-trail readers expect chronological order. (Note: this is a separate Gate #7 Phase Status Snapshot Notes-sweep-class defect at task-block layer.)

**Why this matters:**

1. **Task-block-as-canonical-record** (Claim 15.7 corollary): engineer reading IMPL-FIX-012 task block sees E-AC #1 + #2 still `[ ]` deferred → infers Run #4 retry is pending operator session. False post-BT-002.

2. **`/impl-task IMPL-FIX-012`** would dispatch and attempt iter-4 (cap-3 exhausted means iter-4 is forbidden per IMPL-FIX-012 task-block § Description Step 5 + cap-3 sequencing — but without the cancellation pivot, dispatch enters undefined-behavior state).

3. **ADR cite drift** — ADR-013 status flip (Accepted → Superseded by BT-002) is documented in `docs/adr/013-*.md` per backtrack-log L56 but the task block ADR field doesn't reflect it; ADR cross-ref consistency violated.

**Minimum acceptable fix:**

Append a new Status row after L1990 (preserve all prior iter-1/2/3 entries verbatim per R10 §10.6 audit-trail discipline):

```
- **Status (close-by-BT-002 supersession 2026-05-18):** ✅ **CLOSED-by-supersession via BT-002 2026-05-18 — IMPL-FIX-012 cap-3 budget consumed (iter-1 ✅ + iter-2 ❌ + iter-3 ❌; escalation gate fires per task-block § Description Step 5); operator selected Option 1 (remove BR-3.6 detector, legacy-parity) per `backtrack-log.md § BT-002 § Approved by` L70. BT-002 cascade closed: SD Round 09 verify-only 0 findings 2026-05-17 (commit `e385ad0`) + BA Round 06 1 LOW closed via rebuttal-05 2026-05-18 (commit `863493e`). ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved per backtrack-log L56). BR-3.6 + FR-6.6 demoted at BA layer; SD Services Catalog `CircuitBreaker` row repurposed/removed across 5 design docs; ADR-010 halt-trigger list amended (CircuitBreaker removed). E-AC #1 + #2 (Run #4 + 5-yr completion + drift ≤ 25% gates) **superseded** — the detector being verified is removed; the halt-class being eliminated no longer exists post-impl-code cleanup. New canonical NFR-1.1 acceptance path = IMPL-062 re-execute on rewrite-no-detector default build (per BT-002 § Resolution); pending impl-code cleanup (single session ~1-2 hr per backtrack-log § Impacted phases Impl Code L65). **Task-block preserved as canonical iter-1/2/3 falsification audit** per R10 §10.6 audit-trail discipline + workflow.md Phase 5 Gate #6 file-integrity precedent.** Plan Staleness Sentinel unchanged at 1 IMPL-NNN main task closure since R09 (FIX-ticket close-by-supersession ≠ main task closure per workflow.md Gate #4 + fix-round-10 precedent).
```

Update L1976 + L1977 E-AC checkboxes:
- L1976 `[ ]` → `[x]` with append: `**— Superseded by BT-002 2026-05-18:** detector being verified removed per BT-002 closure (Option 1 legacy-parity); E-AC obsolete by construction; preserved for audit history per R10 §10.6 + R11 §11.1 strikethrough-append precedent.`
- L1977 `[ ]` → `[x]` with append: `**— Superseded by BT-002 2026-05-18:** Run #4 was iter-2 (2026-05-17 ❌) and Run #5 was iter-3 (2026-05-17 ❌); cap-3 exhausted; BT-002 cascade ✅ Closed 2026-05-18 with detector removal. New NFR-1.1 acceptance path = IMPL-062 re-execute on rewrite-no-detector default build (post-impl-code BT-002 cleanup).`

Update L1981 ADR field — append:
```
 — **Status (2026-05-18):** ADR-013 + ADR-014 flipped Accepted → Superseded by BT-002 per `backtrack-log.md § BT-002 § Proposed change` L56 (audit history preserved; iter-1/2/3 chain documents falsification path).
```

**Effort:** Medium (1 new Status row + 2 E-AC `[x]` flips + 1 ADR field append; ~50-70 LOC narrative; preserves all iter-1/2/3 audit history verbatim).

---

### 🟡 MEDIUM

#### Claim 15.9: 🟡 MEDIUM — `impl-plan.md` L128 Open Risks R-3 + L133 R-13 narratives carry post-Run #3 + post-IMPL-FIX-012 iter-1 framing without iter-2/iter-3 + BT-002 cascade closure annotations; same defect class as R14 §14.5 (R-7 + R-13 `/backtrack ba` future-pending residue) at post-BT-002 cascade boundary

**Location:**
- L128 R-3 Bucket A drift exceeds NFR-1.1 (`🔴 RE-OPENED 2026-05-14 via Run #3 empirical execution`): full narrative ~2957 chars; closing paragraphs reference `"Mitigation iter-1 ✅ APPLIED 2026-05-14 via IMPL-FIX-012 + ADR-013"` + `"Post-IMPL-FIX-012 → Run #4 retry expected to either (a) PASS ... or (b) FAIL with different halt class → triggers next IMPL-FIX-NNN long-tail iteration"` — the conditional has played out as **(c) cap-3 exhausted → BT-002 → detector removed entirely**, which falls outside the (a)/(b) framing
- L133 R-13 (Rewrite trading-logic translation gap): full narrative ~3032 chars; references `"New IMPL-FIX-012 follow-up authored 2026-05-14 ... cap-3 iteration; fallback ADR-013 CircuitBreaker threshold tune"` + `"Hypothesis (a) anti-pyramid latches scope reduced — keep IMPL-FIX-007 v2 / IMPL-FIX-008 latches as-is; revisit only if Run #3 (post-BT-001 R12 §12.1 2026-05-13) surfaces max-intra-bucket > 2 on a slot"` — the conditional has happened (Run #3 + 4 + 5 happened); the followup hasn't materialized

**Problem:**

Same defect class as R14 §14.5 (R-7 + R-13 `/backtrack ba` future-pending residue post-BT-001 closure) at post-BT-002 cascade boundary. R-3 narrative carries 2026-05-14 iter-1-close framing; R-13 carries 2026-05-10 framing with 2026-05-14 update annotation. Both rows missed the 2026-05-17 cap-3 exhaustion + BT-002 cascade events.

R-3 closing paragraph `"Post-IMPL-FIX-012 → Run #4 retry expected to either (a) PASS ... or (b) FAIL with different halt class"` is invalidated by what actually happened: (c) Run #4 = iter-2 ❌ (different halt class = OrderGroupStartWorkflow Jan-27 mass-close) → (d) Run #5 = iter-3 ❌ (3rd different halt class = BI pyramiding Jan-06) → (e) cap-3 exhausted → (f) BT-002 → (g) detector removed entirely. The (b) branch fired twice then escalated to BT-002. The narrative needs the (c)→(g) chain reflected.

R-13 Mitigation paragraph end `"Hypothesis (a) anti-pyramid latches ... revisit only if Run #3 ... surfaces max-intra-bucket > 2"` — the post-Run #3 narrative ran a different intervention path (CircuitBreaker DEAL_REASON / DEAL_ENTRY refinement, not anti-pyramid latch tuning) and reached BT-002. The "revisit only if" conditional is now moot.

**Why this matters:**

1. **Reader-side decision-tree confusion** (MEDIUM): engineer reading R-3 sees `"iter-1 ✅ APPLIED ... Run #4 retry expected to either (a) PASS or (b) FAIL"` → infers Run #4 is the next pending decision point. False; Run #4 + Run #5 happened, both failed, cap-3 exhausted, BT-002 cascade fired + closed.

2. **MEDIUM not HIGH** because: (a) Open Risks rows are advisory/historical, not load-bearing for engineer dispatch (Next Best Action L199-201 is the canonical dispatch surface, covered separately by Claim 15.4); (b) R-3 + R-13 rows can carry strikethrough-append patches without affecting `/impl-task` flow; (c) cascades cleanly via the same R15 rebuttal commit alongside other surfaces.

3. **Same defect class as R14 §14.5** at post-BT-002 cascade event boundary — Open Risks narrative residue is now a recurring drift class at each new backtrack event.

**Minimum acceptable fix:**

L128 R-3 tail append (after current `"Audit history preserved: pre-2026-05-14 disposition was ✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2) ..."`):

```
**Post-2026-05-14 update (BT-002 cascade closure 2026-05-18):** Run #4 retry hypothesis (a)/(b) per R-3 narrative tail invalidated by empirical execution: Run #4 = iter-2 (2026-05-17) ❌ ADR-014 partial; new false-positive class via OrderGroupStartWorkflow Jan-27 mass-close (different halt class — matches (b) sub-branch but different from Slot_H clustering hypothesis); Run #5 = iter-3 (2026-05-17) ❌ ADR-014 INSUFFICIENT; 3rd false-positive class — BI pyramiding close-tk12 + open-tk14 same tick (halt 8 sim days EARLIER than baseline); cap-3 budget exhausted → escalation gate fires → `/backtrack sd` (BT-002 OPEN 2026-05-17). **BT-002 ✅ CLOSED 2026-05-18** (Option 1 legacy-parity per `backtrack-log.md § BT-002 § Resolution` L71). The BR-3.6 detector's matching key `(magic, dir, Δ≤3s)` proved structurally incompatible with three legitimate trading patterns produced by the EA's 16-active-slot concurrency profile; iter-1→2→3 chain accumulated 3 false-positive classes each "fix" surfacing the next. Legacy `PhoenicisN2.10_stable.mq5` achieves the $24.27M baseline without any ping-pong detector → empirical proof safety capability not load-bearing for EA's known trading pattern set. ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); BR-3.6 + FR-6.6 demoted at BA. **R-3 mitigation path (post-BT-002):** impl-code BT-002 cleanup (DELETE services/CircuitBreaker.mqh + strip Orchestrator dispatch + remove HALT_PINGPONG + G1+G2+G3 re-run; ~1-2 hr) + IMPL-062 re-execute Bucket A 5-yr regression on rewrite-no-detector default build (NFR-1.1 acceptance signal — single operator session ~30-60 min wall-clock). **Blocks (updated):** NFR-1.1 acceptance signal + IMPL-062 E-AC #1 + #2 retry (paired bundle alongside post-cleanup re-execute) + IMPL-068 force-clear validation + IMPL-066 journal latency long-sample + P2 + P3 + P4 Tier 2 Phase Gate close + MVP delivery — all transitively unblocked by impl-code BT-002 cleanup + post-cleanup IMPL-062 single-session.
```

L133 R-13 Mitigation tail append (after current `"...Hypothesis (a) anti-pyramid latches scope reduced — keep IMPL-FIX-007 v2 / IMPL-FIX-008 latches as-is; revisit only if Run #3 (post-BT-001 R12 §12.1 2026-05-13) surfaces max-intra-bucket > 2 on a slot"`):

```
**Post-2026-05-17 update (BT-002 cascade):** the post-Run #3 intervention path pivoted to CircuitBreaker DEAL_REASON / DEAL_ENTRY refinement (ADR-013 iter-1 + ADR-014 iter-2/3) rather than anti-pyramid latch revisit (max-intra-bucket condition not surfaced; Slot_H clustering hypothesis falsified by Step 0 diagnostic 2026-05-14 — real cause = broker-driven concurrent SL fills @ Jan-14 + EA-driven mass-close @ Jan-27 + BI pyramid same-tick @ Jan-06). IMPL-FIX-012 cap-3 chain consumed (iter-1 ADR-013 ✅ + iter-2 ADR-014 ❌ + iter-3 ADR-014 INSUFFICIENT ❌); BT-002 ✅ CLOSED 2026-05-18 (remove detector). **R-13 mitigation path (post-BT-002):** detector class of mitigation is removed; trading-logic translation gap residue now drains via empirical Run #6 on rewrite-no-detector default build (NFR-1.1 + NFR-1.6 acceptance signals); IMPL-FIX-011 parent paired-bundle drain alongside post-cleanup IMPL-062 single-session per backtrack-log § BT-002 § Resolution. Hypothesis (a) anti-pyramid latches remain unchanged (IMPL-FIX-007 v2 + IMPL-FIX-008 latches preserved as defense-in-depth; max-intra-bucket condition still not surfaced empirically across 3 5-yr regression attempts).
```

**Effort:** Low (2 in-place tail appends; ~40-50 LOC narrative).

---

#### Claim 15.10: 🟡 MEDIUM — `impl-plan.md` L2247 Mid-Phase Audit Log trailer is at fix-round-26 ✅ closed (2026-05-17); missing 2026-05-17 IMPL-FIX-012 iter-2/iter-3 closures + 2026-05-17/18 BT-002 cascade open/close + 2026-05-18 BA Round 06/SD Round 09 verify closures + 2026-05-18 `/project-init --regen` commit `7ff6f43`; primary audit trail violation per CLAUDE.md §6 State SoT discipline

**Location:** `docs/state/impl-plan.md` L2174-2247 Mid-Phase Audit Log; final entry at L2247 `"| 2026-05-17 | — | fix-round-26 ✅ CLOSED — 6/6 findings Accept (2 HIGH / 2 MEDIUM / 2 LOW) processed in 3 commits; IMPL-FIX-013 NEW Active row (P5; orphan-recommendation propagation per Finding 26.4); Gate #9 clause (h) extended with class (ε) frozen legacy-file cites + 10 remaining survivors enumerated as scope-out per clause (i)(b)"`.

**Problem:**

Per Mid-Phase Audit Log purpose statement at L2176: `"Engineer logs mid-phase findings, fix-rounds, and impl-plan rebuttals here — primary audit trail per CLAUDE.md §6 State SoT"`. Missing audit-trail entries since 2026-05-17 fix-round-26 closure:

| Date | Event | Missing from Mid-Phase Audit Log |
|------|-------|----------------------------------|
| 2026-05-17 | IMPL-FIX-012 iter-2 Run #4 ❌ executed | ❌ |
| 2026-05-17 | IMPL-FIX-012 iter-3 Run #5 ❌ executed | ❌ |
| 2026-05-17 | IMPL-FIX-012 cap-3 budget exhausted | ❌ |
| 2026-05-17 | BT-002 OPENED (`/backtrack sd` from impl-plan) | ❌ |
| 2026-05-17 | BT-002 SD-side cascade: Round 07/rebuttal-05/Round 08/rebuttal-06/Round 09 verify 0 findings | ❌ |
| 2026-05-18 | BT-002 BA-side cascade: Round 06/rebuttal-05 | ❌ |
| 2026-05-18 | BT-002 ✅ CLOSED (Status flipped via SD Round 09 + BA closure) | ❌ |
| 2026-05-18 | commit `7ff6f43` `/project-init --regen` (CLAUDE.md + .claude/rules/* regenerated per BT-002 cascade + user remark 2026-05-18) | ❌ |
| 2026-05-18 | commit `47381a9` path modernization `.agents/development-guide/` → `.andm/` (methodology infra) | ❌ |

While engineer-side conventions hold that some events (rebuttal closures, fix-round closures) don't increment Sentinel counter per workflow.md Gate #4 + fix-round-10 precedent, they DO belong in the Mid-Phase Audit Log primary audit-trail per its stated purpose. Specifically: BT-002 OPEN + CLOSE events are **lifecycle-scope** events that must be in the audit log (analogous to BT-001 OPEN/CLOSE which appears in audit log at L2235 and earlier entries).

**Why this matters:**

1. **Audit-trail completeness** (CLAUDE.md §6): impl-plan.md = primary SoT for task list + Phase Gate + audit log + SD Hint Alignment. Mid-Phase Audit Log is the primary chronological audit trail. Missing 8+ entries spanning 2 days = audit gap that compounds with each subsequent close that references back to one of those missing events.

2. **MEDIUM not HIGH** because: (a) backtrack-log.md § BT-002 has the full canonical lifecycle record (lines 35-71); (b) overview.md row 19 narrative has the closure-event summary; (c) commit history (git log) has the source-of-truth for commit-level events. Mid-Phase Audit Log is "primary audit trail" but **derived from** the upstream canonical lifecycle SoTs.

3. **Same defect class as workflow.md § Phase 5 Gate #7 Phase Status Snapshot Notes sweep** at next-cascade-event boundary — the Mid-Phase Audit Log requires the same per-closure update discipline.

**Minimum acceptable fix:**

Append 8 new rows after L2247 (chronological order; preserve existing entries verbatim):

```markdown
| 2026-05-17 | P4 | **IMPL-FIX-012 iter-2 Run #4 EXECUTED ❌ — ADR-014 partial fix; new false-positive class via OrderGroupStartWorkflow Jan-27 mass-close** | impl-plan.md (IMPL-FIX-012 Status L1990 + R-3/R-13 narrative pending R15 cascade), `_session-handoff/IMPL-FIX-012-iter2-run4-blocked-20260517.md` | Engineer: Opus 4.7. Run #4 launched `regression_5yr_g4.ini`; halt class shifted from broker-SL Jan-14 → EA-driven mass-close Jan-27 (`OrderGroupStartWorkflow` 11-target safe-port batch-close); ADR-013 DEAL_REASON_EXPERT filter correctly excluded broker-SL but ADR-014 dedup rules needed for same-event_type bulk-close pattern. iter-3 PATCH authored = ADR-014 (position_id + event_type fields in TradeEvent struct + RecordOpen wired). |
| 2026-05-17 | P4 | **IMPL-FIX-012 iter-3 Run #5 EXECUTED ❌ — ADR-014 INSUFFICIENT; INTRODUCES 3rd false-positive class (BI pyramiding close-tk12+open-tk14 same tick) HALT 8 sim days EARLIER than baseline → cap-3 budget exhausted → escalation gate fires** | impl-plan.md (IMPL-FIX-012 Status L1986 + TL;DR L7), `_session-handoff/IMPL-FIX-012-iter3-run5-20260517.{md,jsonl,-tester-abridged.txt}` (NEW 3-artifact bundle ~30 KB) | Engineer: Opus 4.7. Run #5 halted at sim 2021-01-06 02:50:48 via `circuit_breaker_pingpong magic=214 (Slot_BI) dir=0 pos_i=12 pos_j=14 evt_i=1 evt_j=0`; final balance $928.35 (drift = −100.0003%); ADR-014 rule (c) `pos_i==pos_j → skip` is structural INVERSE of canonical ping-pong concept (same position closed-then-re-opened); fires on legitimate different-position close+open at same tick. Engineer recommends `/backtrack sd` per task-block cap-3 sequencing § Description Step 5. |
| 2026-05-17 | — | **BT-002 OPENED (`/backtrack sd` from impl-plan) — Remove BR-3.6 CircuitBreaker ping-pong detector (legacy-parity safety contract)** | docs/state/backtrack-log.md (NEW § BT-002 entry lines 35-71), docs/state/overview.md (status flips to ❌ Invalidated across rows 11/13/17/18/19/20/21), docs/state/current_handoff.md (BT-002 cascade chain status added) | Operator (Kritsana) approved Option 1 (remove detector, legacy-parity). Triggered by IMPL-FIX-012 iter-3 cap-3 exhaustion; SD/BA cascade authorized to demote BR-3.6 + FR-6.6 + ADR-013/014 supersession. Engineer recommends BA demotion order: `/backtrack ba` chained AFTER SD lock for BA rebuttal cycle to align against concrete SD proposal. Commit `aebec01` (BT-002 open). |
| 2026-05-17 | — | **BT-002 SD-side cascade CLOSED via 3-round chain — Round 07 (7 findings) → rebuttal-05 (7 accept commit 111f092) → Round 08 (2 findings) → rebuttal-06 (2 accept commit 32c56c0) → Round 09 verify-only 0 findings ✅ (commit e385ad0)** | docs/design-docs/{02..08} + docs/adr/{010,013,014} + docs/api-specs/trade-journal-schema.yaml (BT-002 cascade across 6 SD docs + 4 ADRs + 1 API spec), docs/design-docs/claim-review-and-rebuttal/{claim-review-{07,08,09},rebuttal-round-{05,06}}.md | SD package = 18 BT-002 propagation surfaces + 9 cascade-completion surfaces single-voice across SD/ADR/API. ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (audit history preserved); ADR-010 amended (CircuitBreaker removed from halt-trigger list); BR-3.6 + FR-6.6 demoted across SD. |
| 2026-05-18 | — | **BT-002 BA-side cascade CLOSED via 1-cycle chain — BA cascade applied (commit 863493e) consuming concrete SD proposal → Round 06 (1 LOW cosmetic cite-annotation gap) → rebuttal-05 (1 accept) → ready-for-handoff** | docs/ba/{01..05} + docs/ba/claim-review-and-rebuttal/{claim-review-06,rebuttal-round-05}.md | BA package = 18 BT-002 propagation surfaces + Anti-Duplication clean vs prior Round 04/05. BR-3.6 + FR-6.6 demoted Must → Won't; NFR-1.1 Empirical Citation paragraph re-authored (footnote post-BT-002). |
| 2026-05-18 | — | **BT-002 ✅ CLOSED (Status flipped + Resolution populated in backtrack-log.md § BT-002 § Status line 69 + § Resolution line 71)** | docs/state/backtrack-log.md (Status field flipped 🔄 Open → ✅ Closed 2026-05-18) | Pending downstream cascade: (a) TD review `/td-review all` after TD-02 § 5.8 CCircuitBreaker class skeleton DELETE + 10 cross-refs cascade cleanup (tracked separately); (b) Impl-plan IMPL-051 closure + IMPL-FIX-012 task closure pivot — tracked via `/impl-plan-review` next cycle (this triggers R15 = current claim review); (c) Impl-code BT-002 cleanup — DELETE services/CircuitBreaker.mqh + strip dispatch + remove HALT_PINGPONG + G1+G2+G3 re-run. |
| 2026-05-18 | — | **commit `7ff6f43` `/project-init --regen` — CLAUDE.md + .claude/rules/{ea,security,testing,workflow}.md + .claude/stack.json + AGENTS.md + .windsurf/rules/* + .trae/rules/* + .codex/rules/* regenerated per BT-002 TD/SD cascade + user remark 2026-05-18** | CLAUDE.md + 4× .claude/rules/*.md + .claude/stack.json + 4× .windsurf/rules/*.md + 4× .trae/rules/*.md + 4× .codex/rules/*.md + AGENTS.md + 18× `.bak-2026-05-18T02-26-01Z` backup files (preserved per `backtrack-workflow.md § Project Bootstrap Invalidation`) | Methodology infra refresh; CLAUDE.md TL;DR Three-Tier Closure Status snapshot updated to 2026-05-18 with BT-002 cascade reflected; `.claude/rules/*` regenerated with `🔴 Recompile-after-edit` + `🔴 Headless MT5 testing focus` + `🔴 MQL5 SKILL invocation + canonical MT5 path` per user remark. |
| 2026-05-18 | — | **commit `47381a9` path modernization `.agents/development-guide/` → `.andm/` + `.agents/prompt-templates/` → `.andm/prompt-templates/` across 6 agent personas + 1 guide deletion** | 6× agent persona file path updates + 1 guide deletion | Methodology-infra cleanup (path normalization); cascaded from `/project-init --regen` post-BT-002 propagation. |
| 2026-05-18 | — | **`/impl-plan-review all` invoked → R15 claim review NEW (this entry will update post-R15 rebuttal closure)** | docs/state/impl-plan-claim-review-and-rebuttal/claim-review-15.md (NEW; ~N findings; BT-002 cascade drain pending) | Reviewer: Opus 4.7. Trigger: overview.md row 19 + backtrack-log § BT-002 § Impacted phases Impl Plan L64 (`re-run /impl-plan-review all post-SD lock`). Scope: full BT-002 propagation drain across 11+ impl-plan surfaces (mirror R11 §11.1 BT-001 19-surface drain at fresh-cascade-event layer). |
```

**Effort:** Medium (9 new audit-log rows; ~40-60 LOC narrative; preserves all prior entries verbatim).

---

#### Claim 15.11: 🟡 MEDIUM — `impl-plan.md` L2348-2350 Closure Hygiene Status block references "post-IMPL-FIX-012 iter-1 closure commit 2026-05-14" + R14 Gate exercise narrative; missing 2026-05-17 fix-round-26 closure context + 2026-05-17/18 BT-002 cascade closure context; canonical 3-line skim block out of date with primary SoT

**Location:** `docs/state/impl-plan.md` L2348-2350 (Closure Hygiene Status block 3 bullets):
- L2348: `"- **Plan Staleness Sentinel:** 1 IMPL-NNN main task closure since R09 (impl-plan-review chain; IMPL-063 fully closed 2026-05-14 via Run #3 cascade — informational delta = $0 + G4 verification empirical/structural; counter +1). Last review 2026-05-13 = R14 verify-pass + R13 verify-pass + R12 verify-pass + R11 BT-001 cascade drain. FIX-ticket closures (IMPL-FIX-012 authored 2026-05-14) ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent. Within ≤10-closure threshold ✅."`
- L2349: `"- **Phase 5 mechanical gates (.claude/rules/workflow.md):** Gates #1-#11 — sweep refreshed 2026-05-14 post-IMPL-FIX-012 iter-1 closure commit; ... R14 explicitly exercised Gate #2 ..."`
- L2350: `"- **State Reconciliation 3-file rule (CLAUDE.md §6):** impl-plan.md (primary SoT) ↔ overview.md (derived count + phase status) ↔ {module}/handoff.md + _session-handoff/* — honored post-R13 rebuttal commit ..."`

**Problem:**

Per R10 §10.6 precedent + workflow.md Phase 5 Closure mechanical gates, the Closure Hygiene Status block is the canonical 3-line skim block updated at every task closure / fix-round / rebuttal close (per Phase 5 mechanical Gate #4 + #5 + R10 §10.6 reader-empathy discipline). Current state references:
- L2348 last anchor = R14 (2026-05-13); missing: R15 (this round when rebuttal closes), fix-round-26 (2026-05-17 closure event), BT-002 OPEN/CLOSE (2026-05-17/18)
- L2349 last sweep = 2026-05-14 post-IMPL-FIX-012 iter-1; missing: fix-round-26 sweep results (which actually did exercise Gate #1 + #9h + #9i per L2349 fix-round-26 references already inline), BT-002 cascade-event sweep
- L2350 anchor = post-R13; missing: post-R14 cascade-drain (R14 6/6 Accept landed); post-BT-002 cascade-drain (pending R15 rebuttal)

L2349 has been partially refreshed for fix-round-26 (inline reference at `2 sanctioned false-positives per review-round-26 §Finding 26.6 / fix-round-26`). But the overall block doesn't reflect that the canonical anchor has moved from R14 (2026-05-13) to R15 (this round will close it; mention pending until rebuttal commit).

**Why this matters:**

1. **MEDIUM not HIGH** because: (a) Closure Hygiene Status is 3-line summary, not primary canonical record; (b) Plan Staleness Sentinel L2337 + Mid-Phase Audit Log L2174+ are primary audit trail; (c) Block refreshes at every rebuttal close per R10 §10.6 + workflow.md Gate #4 — R15 rebuttal will inherently refresh it.

2. **Same defect class as workflow.md Gate #4 (Sentinel counter increment) + Gate #5 (overview.md sync)** at Closure Hygiene Status canonical-summary layer — block needs to be refreshed when any of the 11 mechanical gates are exercised (R15 will exercise Gate #1 + #2 + #5 + #6 + #7 + #8 + #11 across the BT-002 cascade drain commit).

**Minimum acceptable fix:**

L2348-2350 refresh at R15 rebuttal commit (preserve all prior R14 narrative verbatim; append R15 anchor):

```markdown
- **Plan Staleness Sentinel:** **1 IMPL-NNN main task closure** since R09 (impl-plan-review chain; IMPL-063 fully closed 2026-05-14 via Run #3 cascade — informational delta = $0 + G4 verification empirical/structural; counter +1). **Last review 2026-05-18 = R15 BT-002 cascade drain** + prior R14 verify-pass 2026-05-13 + R13 verify-pass 2026-05-13 + R12 verify-pass 2026-05-13 + R11 BT-001 cascade drain 2026-05-13. FIX-ticket closures (IMPL-FIX-012 iter-2/3 + IMPL-FIX-013 P5 author 2026-05-17) + fix-round-26 closure (2026-05-17) + BT-002 OPEN/CLOSE (2026-05-17/18) ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent. Within ≤10-closure threshold ✅.

- **Phase 5 mechanical gates (.claude/rules/workflow.md):** Gates #1-#11 — sweep refreshed 2026-05-18 post-R15 rebuttal commit (BT-002 cascade drain across 11+ surfaces). **R15 explicitly exercised Gate #1 (forbidden-pattern grep on impl-plan.md — 2 sanctioned false-positives ✅ per claim-review-15 §At-a-Glance + fix-round-26 §Finding 26.6 precedent)** + Gate #2 (TL;DR ↔ registry recount — empirical sweep 5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = 55 Active rows ✅ matches L100 claim post-fix-round-26 +1 P5 row) + Gate #5 (overview.md sync — handled by overview.md row 19 narrative already drained for BT-002) + Gate #6 (file-integrity post-R15 cascade-drain commit — single `## End of Plan` marker + clean trailer verified) + Gate #7 (Phase Status Snapshot Notes sweep — L118 P4 row Notes tail BT-002 cascade drained per Claim 15.5) + Gate #8 (narrative-section freshness sweep — TL;DR L7/L97/L100/L101 + Open Risks R-3/R-13 + Next Best Action L199-201 + Phase Gate P4 Empirical Demo L1409 + NFR-1.1 sub-row L1414 + Mid-Phase Audit Log 9 new rows per Claim 15.10 all post-BT-002 drained) + Gate #9 (post-fix grep verification — 0 stale `IMPL-FIX-012 Step 3 Run #4` references post-fix per Claim 15.4) + Gate #10 (stash-clean G1 — pending; rebuttal commit applies prose-only changes; G1 status unchanged) + Gate #11 (working-tree clean post-commit — pending final verification). Prior R14 sweep 2026-05-13 post-rebuttal commit Gate #2 + #7 + #8 exercise preserved.

- **State Reconciliation 3-file rule (CLAUDE.md §6):** impl-plan.md (primary SoT) ↔ overview.md (derived count + phase status) ↔ {module}/handoff.md + _session-handoff/* — **honored post-R15 rebuttal commit (BT-002 cascade drained at primary SoT — closes the inversion gap where overview.md was ahead of impl-plan.md per Claim 15.1)**. R14 §13.1+ §13.2 closures preserved + R12 §12.1 Path A backtrack-log.md ↔ impl-plan.md reconciliation preserved across BT-002 cascade. backtrack-log.md § BT-002 (lifecycle SoT) ↔ impl-plan.md primary SoT now fully reconciled at all 11+ surfaces enumerated in Claim 15.1 Location table.
```

**Effort:** Low (1 in-place 3-bullet block rewrite preserving all prior narrative; ~30-40 LOC).

---

### 🔵 LOW

#### Claim 15.12: 🔵 LOW — `impl-plan.md` L2337 Plan Staleness Sentinel `Last review on: 2026-05-13` is the last canonical review-cycle anchor; R15 rebuttal commit will move it to 2026-05-18; ahead-of-itself reading by a status agent reading L2337 alone may infer R14 is the latest review when R15 is actively in progress; sentinel will inherently refresh on rebuttal close

**Location:** `docs/state/impl-plan.md` L2337 — `"**Last review on:** 2026-05-13 — claim-review-13.md + rebuttal-round-13.md (R13 3/4 Accept + 1 partial/advisory; ...). Prior 2026-05-13 claim-review-12.md + rebuttal-round-12.md (R12 6/6 Accept; ...). Prior reviews: 2026-05-13 claim-review-11.md + rebuttal-round-11.md (R11 7/7 Accept; ...); 2026-05-13 claim-review-10.md + rebuttal-round-10.md (R10 6/6 Accept ...); 2026-05-11 claim-review-09.md + rebuttal-round-09.md (R09 7/7 Accept; ...); ..."`

**Problem:**

The Plan Staleness Sentinel `Last review on:` field is the canonical anchor for `/next` Check 5.8 advisory (`plan staleness recommendation triggers when (approved > 30d ago) AND (no review OR > 10 closures since review)`). Currently anchored at R13 (2026-05-13). R14 rebuttal closed 2026-05-13 — should the field have been bumped to R14 anchor? Per workflow.md Gate #4 + R14 §14.2 fix narrative, R14 was a verify-pass round (6/6 Accept) so the Sentinel L2337 was technically refreshed at R14 close. But the current L2337 still says R13. **This is a minor R14 §14.2 follow-up that was not in R14 explicit scope** — and now compounded by R15 about to fire.

The R15 rebuttal commit will bump L2337 to `Last review on: 2026-05-18 — claim-review-15.md + rebuttal-round-15.md (...)`. So this is self-resolving at R15 rebuttal close.

**Why this matters:**

1. **LOW not MEDIUM** because: (a) self-resolves at R15 rebuttal commit; (b) `/next` Check 5.8 reads Sentinel `Last review on:` for staleness advisory — at R13 anchor 2026-05-13 = 5 days ago, well within 30d threshold so no false-positive advisory; (c) closures-since-R09 counter at 1 = far below 10-closure threshold; advisory wouldn't fire regardless.

2. **Minor R14 §14.2 follow-up surface**: R14 caught TL;DR L95 Last-updated lead clause stale; the Sentinel L2337 `Last review on:` field is the analogous canonical anchor at primary-SoT layer and arguably should have been bumped at R14 close. R14 §14.2 fix scope was explicitly TL;DR L95 only — Sentinel anchor not in scope. R15 picks it up as `prior round known-follow-up` surface.

3. **Reader-side**: a status agent reading Sentinel L2337 alone would correctly report `Last review: 2026-05-13` but reader infers no review has happened since R13 — actually R14 closed same day 2026-05-13 and R15 is in progress 2026-05-18. Minor friction.

**Minimum acceptable fix (engineer-choice — accepts either disposition):**

**Option A (recommended)** — R15 rebuttal explicit refresh of L2337 to current canonical:
```
**Last review on:** 2026-05-18 — `claim-review-15.md` + `rebuttal-round-15.md` (R15 N/N Accept; BT-002 cascade drain across 11+ impl-plan surfaces mirror R11 §11.1 BT-001 19-surface drain pattern at fresh-cascade-event layer). Prior 2026-05-13 `claim-review-14.md` + `rebuttal-round-14.md` (R14 6/6 Accept; TL;DR per-phase tally + Last-updated 3 rounds behind + Next Best Action stale dep + Phase Status P2/P3 tail + Open Risks R-7/R-13 + TL;DR Action ถัดไป). Prior 2026-05-13 ... (preserve existing R13/R12/R11/R10/R09/R07/R06 chain verbatim).
```

**Option B (retain verbatim per R10 §10.6 audit-trail discipline)** — accept that Sentinel "Last review on:" is canonical-current-snapshot field that may lag actual rebuttal closures by one round; relax expectation that R14 anchor existed (it should have but didn't). Engineer chooses based on consistency-with-R14-§14.2-pattern (Option A bumps both lead clauses — TL;DR L95 + Sentinel L2337 — per closure event) vs simplification (Option B keeps Sentinel as single most-recent canonical-review snapshot, updated only when state reconciliation drift becomes material).

Reviewer recommends **Option A** for consistency with R14 §14.2 narrative-freshness discipline (lead clauses are canonical-current; per-entry boilerplate triad is audit-history retained verbatim — Sentinel `Last review on:` field is canonical-current marker not audit-history).

**Effort:** Low (1 in-place anchor refresh; ~5-10 LOC).

---

## Cross-Document Issues

R15 catches **11+ cross-document state-reconciliation gaps** at primary-SoT-vs-derived-views layer (Claim 15.1 covers the meta-axis; Claims 15.2..15.11 cover individual surface drifts):

| Contradiction | Primary SoT (correct) | Drifted surface |
|---------------|----------------------|------------------|
| BT-002 lifecycle status | `backtrack-log.md § BT-002 § Status` = `✅ Closed (2026-05-18)` | `impl-plan.md` = **0 BT-002 references anywhere** (`grep -c '\bBT-002\b' docs/state/impl-plan.md` = 0; same grep overview.md = 10, backtrack-log.md = 7, CLAUDE.md ≥ 6); Claim 15.1 |
| Last action canonical event | `overview.md` row 19 + `backtrack-log.md § BT-002 § Status flipped 2026-05-18` + `CLAUDE.md` Status snapshot row P4 | `impl-plan.md` L101 TL;DR `Last updated: 2026-05-14` (4 days + 5 closure events behind); Claim 15.2 |
| P4 task completion count | `impl-plan.md` L2073 IMPL-063 Closed 2026-05-14 + L100 Resolved table | `impl-plan.md` L97 TL;DR `ตอนนี้: P4 16/17` (was 16/17 pre-IMPL-063 closure; should be 17/17); Claim 15.3 |
| Next operator action | `backtrack-log.md § BT-002 § Impacted phases Impl Code` L65 (impl-code BT-002 cleanup) | `impl-plan.md` L199-201 Next Best Action = `IMPL-FIX-012 Step 3 Run #4 retry` (Run #4/5 already happened ❌; cap-3 exhausted; BT-002 fired+closed); Claim 15.4 |
| P4 Phase Status remaining work | `overview.md` row 19 narrative + `backtrack-log.md § BT-002 § Resolution` | `impl-plan.md` L118 P4 row Notes column tail (`both unblocked` + `NOT downstream of any further /backtrack event`); Claim 15.5 |
| P4 Phase Gate Empirical Demo acceptance path | `backtrack-log.md § BT-002 § Resolution` (impl-code cleanup + Run #6 on no-detector build) | `impl-plan.md` L1409 Empirical Demo + L1414 NFR-1.1 sub-row (`✅ RESOLVED 2026-05-12 via BT-001`); Claim 15.6 |
| IMPL-051 task disposition | `overview.md` row 19 + `backtrack-log.md § BT-002 § Impacted phases Impl Plan` L64 (`IMPL-051 (cancel)`) | `impl-plan.md` L907 IMPL-051 task block `Closed: 2026-05-03` without cancel-by-BT-002 annotation; Claim 15.7 |
| IMPL-FIX-012 task closure pivot | `overview.md` row 19 + `backtrack-log.md § BT-002 § Impacted phases Impl Plan` L64 (`IMPL-FIX-012 task closure pivots ... [x] BT-002 supersedes`) | `impl-plan.md` L1976/L1977 E-AC still `[ ]` deferred to Run #4 + L1981 ADR field cites ADR-013 as live (Superseded per backtrack-log L56); Claim 15.8 |
| Open Risks R-3/R-13 cascade context | `backtrack-log.md § BT-002 § Reason` + § Resolution | `impl-plan.md` L128 R-3 + L133 R-13 narratives reference iter-1 ✅ APPLIED + post-Run #3 framing; Claim 15.9 |
| Mid-Phase Audit Log completeness | `git log` + `overview.md` row 19 + `backtrack-log.md § BT-002` + `CLAUDE.md` § frontmatter (regen 2026-05-18) | `impl-plan.md` L2247 trailer at fix-round-26 (2026-05-17); missing 8+ entries spanning 2026-05-17 IMPL-FIX-012 iter-2/3 + BT-002 cascade open/close + 2026-05-18 BA/SD closures + `/project-init --regen` commit; Claim 15.10 |
| Closure Hygiene Status 3-line skim block | (canonical-current snapshot — should reflect R15 + fix-round-26 + BT-002 closures) | `impl-plan.md` L2348-2350 references "post-IMPL-FIX-012 iter-1 closure commit 2026-05-14" + R14 anchor; Claim 15.11 |
| Plan Staleness Sentinel `Last review on:` field | (canonical-current snapshot) | `impl-plan.md` L2337 = R13 anchor (2026-05-13); R14 + R15 closures not reflected; Claim 15.12 |

No new Evolution Sequence violation. No ADR backing gap. Phase × Size matrix denominator preserved (IMPL-051 stays in matrix per audit-history discipline; IMPL-FIX-012 stays via close-by-supersession pivot). SD Hint Alignment audit trail unchanged (BT-002 did not introduce new task or change classifications).

---

## Recurring Weaknesses (rounds 06-14)

1. **State-reconciliation defect-class progression continues at next-finer granularity each round** (per R14 § Recurring Weaknesses #1 + R13 §1 axis catalog):
   - R06/R07: TL;DR↔registry drift (within `impl-plan.md`)
   - R08: Phase Status Notes + Open Risks + Next Best Action (intra-narrative-parallel sections)
   - R09: TL;DR↔diagnostic-artifact drift (one external artifact)
   - R10: TL;DR↔Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh (intra-narrative-parallel batch)
   - R11: upstream-vs-impl-plan (BA `03` + SD `08` Last-updated 2026-05-12 vs impl-plan IMPL-062/063 pre-BT-001 framing) — BA-as-Master cascade gap; **BT-001 19-surface drain across impl-plan.md**
   - R12: upstream-lifecycle-state-vs-derived-view (`backtrack-log.md § BT-001 Status` primary lifecycle SoT vs impl-plan ~19 surface annotations) — 5th meta-axis
   - R13: derived-view↔derived-derived-view (R12 reconciled backtrack-log↔impl-plan but overview.md unreconciled) — 6th axis depth-of-propagation
   - R14: intra-primary-SoT TL;DR canonical-block-vs-narrative-prose at TL;DR layer itself (7th axis at top reader-skim surface) — TL;DR L94 per-phase tally drift + L95 Last-updated 3 rebuttal rounds behind + L191/192/193 stale dependency-arrow
   - **R15 (this round)** catches the **next-cascade-event drain**: **BT-002 cascade across all 11+ impl-plan surfaces** (TL;DR + Phase Status + Open Risks + Next Best Action + Phase Gate + task blocks IMPL-051 + IMPL-FIX-012 + Mid-Phase Audit Log + Closure Hygiene Status + Plan Staleness Sentinel). Defect-class progression now at **8th axis** — fresh-cascade-event-vs-impl-plan-derived-from-canonical-lifecycle-SoT. R15 mirrors R11 §11.1 BT-001 19-surface drain at next-cascade-event-boundary; expected to be followed by R16+ verify-pass + cascade-residue cleanup rounds (mirror R12/R13/R14 verify-pass chain after R11 BT-001 drain).

2. **Cascade-drain rebuttal pattern surfaces every backtrack event**: BT-001 closure → R11 BT-001 19-surface drain → R12/R13/R14 verify-pass + residue cleanup chain. BT-002 closure → R15 BT-002 11+ surface drain → expected R16/R17/R18 verify-pass + residue cleanup chain. **R15 reviewer recommendation (informal, no separate Claim)**: when `/backtrack <phase>` fires + upstream cascade closes, automatically queue an `/impl-plan-review` invocation in `current_handoff.md § Next Best Action` to drain the impl-plan side without waiting for operator manual trigger. Codification path: extend `backtrack-workflow.md § Project Bootstrap Invalidation` row schema with a column `Impl-Plan re-review required: yes/no` defaulting to `yes` for any BA/SD-layer change. Engineer-side decision on whether to land in R15 rebuttal Closure Discipline Note OR as separate `/update-config` ticket on `backtrack-workflow.md`.

3. **Gate #2 mechanical sweep underutilized**: per R14 § Recurring Weaknesses #2 — workflow.md Gate #2 (TL;DR ↔ registry recount) is documented since R07 but only explicitly invoked when narrative discipline cites it. **R15 verify-pass note**: Gate #2 ran clean this round (5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = 55 Active rows ✅ matches L100 claim post-fix-round-26 +1 P5 row) — R14 fix held + fix-round-26 +1 P5 propagated correctly through TL;DR L100 + registry Active table sync. **R14 informal recommendation** (Gate #2 mandatory-every-round codification) still outstanding as `/update-config` candidate.

4. **R10 §10.6 audit-history precedent boundary** — R14 §14.2 + §14.6 disposition (lead clauses = canonical-current; per-entry boilerplate triad = audit-history) extended cleanly to BT-002 cascade context. R15 §15.2 (TL;DR L101) + §15.3 (TL;DR L97) + §15.12 (Sentinel L2337) all follow lead-clause = canonical-current rule. No new boundary surface this round.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 15.1 | 🔴 CRITICAL | impl-plan.md zero `\bBT-002\b` propagation across 11+ canonical surfaces; primary State SoT does not acknowledge BT-002 fired + closed; originating defect class for R15 cascade drain | `impl-plan.md` (entire file — 11+ surfaces enumerated in Location table) | Medium (~20-30 in-place surface edits; ~100-150 LOC narrative; mirror R11 §11.1 BT-001 19-surface drain scope) |
| 15.2 | 🔴 CRITICAL | TL;DR L101 `Last updated: 2026-05-14 · last action: iter-1 ✅` 4 days + 5 closure events behind (IMPL-FIX-012 iter-2/3 + fix-round-26 + BT-002 open/close + `/project-init --regen`) | `impl-plan.md` L101 | Low-Medium (1 lead-clause prepend + 5 new chained `prior action` markers; ~40-50 LOC) |
| 15.3 | 🔴 CRITICAL | TL;DR L97 `ตอนนี้:` block reports P4 16/17 (stale; IMPL-063 closed → 17/17) + zero BT-002 invalidation marker on canonical reader-skim line | `impl-plan.md` L97 | Low (1 lead-block rewrite; ~30-40 LOC) |
| 15.4 | 🔴 CRITICAL | Next Best Action L199-201 stale dependency-arrow on IMPL-FIX-012 Step 3 Run #4 (Run #4/5 happened ❌; cap-3 exhausted; BT-002 fired+closed; close-by-supersession pending) | `impl-plan.md` L199 + L200 + L201 | Low (3 in-place phrase replaces + 1 new checklist row; ~20-30 LOC) |
| 15.5 | 🟠 HIGH | Phase Status Snapshot P4 row Notes L118 carries pre-2026-05-17 IMPL-FIX-012 iter-1 + ADR-013 framing; iter-2/3 + ADR-013/014 supersession + BT-002 cascade not reflected | `impl-plan.md` L118 | Low-Medium (1 in-place tail append; ~30-40 LOC) |
| 15.6 | 🟠 HIGH | P4 Phase Gate L1409 Empirical Demo + L1414 NFR-1.1 sub-row carry "✅ RESOLVED via BT-001" framing; Run #3 fail + iter-1/2/3 + BT-002 cascade closure not reflected; misleads engineer on acceptance path | `impl-plan.md` L1409 + L1414 | Low-Medium (2 in-place appends; ~25-35 LOC) |
| 15.7 | 🟠 HIGH | IMPL-051 task block L907 still `Closed: 2026-05-03` without cancel-by-BT-002 annotation; per overview L19 + backtrack-log § BT-002 § Impacted phases Impl Plan L64 | `impl-plan.md` L892-907 | Low (2 in-place appends; ~25-35 LOC) |
| 15.8 | 🟠 HIGH | IMPL-FIX-012 task block L1961-1990 lacks final `close-by-BT-002 supersession` Status row + E-AC L1976/L1977 still `[ ]` deferred to superseded Run #4/#5 + ADR field L1981 cites ADR-013 as live | `impl-plan.md` L1961-1990 | Medium (1 new Status row + 2 E-AC `[x]` flips + 1 ADR field append; ~50-70 LOC) |
| 15.9 | 🟡 MEDIUM | Open Risks R-3 (L128) + R-13 (L133) narratives carry post-Run #3 + iter-1 framing; iter-2/3 cap-3 exhaustion + BT-002 closure not reflected | `impl-plan.md` L128 + L133 | Low (2 in-place tail appends; ~40-50 LOC) |
| 15.10 | 🟡 MEDIUM | Mid-Phase Audit Log L2247 trailer at fix-round-26 (2026-05-17); missing 8+ entries spanning IMPL-FIX-012 iter-2/3 + BT-002 cascade open/close + BA Round 06/SD Round 09 + `/project-init --regen` commits | `impl-plan.md` L2247-2250 (append 9 new rows) | Medium (9 new audit-log rows; ~40-60 LOC) |
| 15.11 | 🟡 MEDIUM | Closure Hygiene Status L2348-2350 references R14 anchor + post-IMPL-FIX-012 iter-1 sweep; missing fix-round-26 + BT-002 + R15 anchor | `impl-plan.md` L2348-2350 | Low (1 in-place 3-bullet block rewrite; ~30-40 LOC) |
| 15.12 | 🔵 LOW | Plan Staleness Sentinel L2337 `Last review on: 2026-05-13` is R13 anchor; R14 + R15 closures not reflected; self-resolves at R15 rebuttal commit | `impl-plan.md` L2337 | Low (1 anchor refresh; ~5-10 LOC; engineer may opt Option B retain) |

---

## End of Review
