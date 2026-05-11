# Implementation Plan Claim Review Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Target** | `docs/state/impl-plan.md` § IMPL-FIX-011 (R-13 trading-logic translation gap) |
| **Date** | 2026-05-11 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Trigger** | Operator request "all to re-decompose IMPL-FIX-011" following 3 consecutive Step 4 re-canary falsifications (iter-1/2/3 all at 33% top-5 reduction vs ≥75% gate) + engineer-authored Slot_T architectural-gap diagnostic recommending Option B escalation |

---

## 📊 At-a-Glance

**Total findings:** 7 (🔴 CRITICAL 2 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- Forbidden closure patterns (impl-plan.md § IMPL-FIX-011): **0 hits** ✅ (forbidden-grep clean inside the task block; "deferred" appears only in E-AC paired-bundle pointer text + `**deferred** to operator paired-bundle session` which routes to `deferred-ac-registry.md`, not inline `[x]` closure)
- Forward reference (P_n → P_m, m>n): IMPL-FIX-011 declares `**Phase**: spans P3 + P4 + possibly P3` (multi-phase declaration — see Finding 09.5) — **anomaly** not technically a forward-reference edge but breaks Phase Gate Blocking
- Silent Copy Detector: not re-run for this round (scope = single task; SD Hint Alignment table unchanged since R08 — H=68/A=67/D=1)
- State reconciliation: **1 divergence flagged** — engineer's Slot_T architectural-gap diagnostic § 5.1 explicitly recommends re-decomposition + threshold revision; plan AC #4 still asserts ≥75% as live gate (TL;DR `Next:` does NOT yet reflect Option B as accepted decision)
- Empirical falsification evidence: **3 consecutive iter falsifications** (iter-1/2/3 at 33% top-5 reduction; iter-2 also caused Net Profit -18.3% regression vs legacy = outside ±10% gate); decision-gate `cap at 3 iterations per session` HIT — plan provides no closure path other than session-level defer

### Top 3 to Fix First

1. **Claim 09.1** 🔴 — IMPL-FIX-011 เป็น L-XL multi-slot mega-task ที่ engineer Phase 2C จะ STOP — empirically falsified 3 ครั้ง; ต้อง decompose เป็น `IMPL-FIX-011a` Slot_T / `IMPL-FIX-011b` Slot_G2 / `IMPL-FIX-011c` Slot_G / `IMPL-FIX-011d` long-tail per engineer diagnostic — `impl-plan.md § IMPL-FIX-011`
2. **Claim 09.2** 🔴 — S-AC #4 "≥75% top-5 per-slot |Δ| reduction" gate authored before architectural depth was known; engineer diagnostic § 4.2 proves Slot_T alone needs ~400 LOC + Fractal indicator + 3 new MarketContext fields → single-session AC mathematically unreachable — `impl-plan.md § IMPL-FIX-011 S-AC #4`
3. **Claim 09.3** 🟠 — Hypothesis space (a)/(b)/(c)/(d)/(e) is non-MECE; (e) "eligibility-predicate divergence" subsumes ≥6 architectural sub-classes per Slot_T diagnostic § 3 — predicate-translation framing is wrong taxonomy — `impl-plan.md § IMPL-FIX-011 Description`

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL/HIGH → run `/impl-plan-rebuttal claim-review-09.md`
- [ ] ⛔ **Immediate Attention** — fundamental phasing/AC flaw ที่ block engineer execution

> **Why CRITICAL on re-decomposition:** Engineer ran the plan as authored 3 iterations + produced empirical falsification artifact + diagnostic doc. Plan AC #4 is now demonstrably unachievable via the prescribed `Step 2 → Step 3 → Step 4` loop. Continuing to dispatch `/impl-task IMPL-FIX-011` against this AC will burn another 3-6 sessions on Slot_G2 + Slot_G architectural-depth discovery (same shape as Slot_T per diagnostic § 4.3) before re-arriving at the same Option B recommendation. Re-decomposition NOW saves 9-12 sessions of repeated falsification work.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass (plan-level) / ⚠️ Finding 09.5 (FIX-011 multi-phase declaration) | Plan shape unchanged since R03; FIX-011 task block declares `spans P3 + P4 + possibly P3` (anomalous) |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Table unchanged since R08; IMPL-FIX-011 is post-plan FIX ticket so falls outside SD Hint Alignment scope (FIX tasks don't increment audit per workflow.md) |
| 3 | Task Decomposition & Sizing | ⚠️ Finding 09.1 (CRITICAL) | FIX-011 sized `[L-XL]` cross-layer cross-slot; engineer diagnostic proves per-slot sub-decomposition needed |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 09.2 (CRITICAL) + 09.3 (HIGH) + 09.4 (HIGH) | AC #4 threshold unreachable; hypothesis taxonomy non-MECE; per-slot empirical gates absent |
| 5 | Phase Gates — Testable Exit | ✅ Pass (plan-level) | Phase Gate rows themselves unchanged; FIX-011 is post-gate recovery work |
| 6 | Deferred-AC Registry Init | ⚠️ Finding 09.7 (MEDIUM) | Plan references "paired bundle with IMPL-062 + extend FIX-006/007/009 expiry to absorb IMPL-FIX-011 closure window" — registry expiry alignment needs explicit row update on re-decomposition |
| 7 | Cross-Phase Dependency | ⚠️ Finding 09.5 (MEDIUM) | FIX-011 multi-phase declaration breaks Phase Gate Blocking semantics |
| 8 | State-File Consistency | ✅ Pass (advisory) | TL;DR ↔ overview ↔ registry checked at last R8 close; this round did not re-run full state reconciliation (scope = single task) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No new SD-hint copies introduced this session |
| 10 | Readability — Reader Empathy | ⚠️ Finding 09.6 (HIGH) | TL;DR `Next:` line points to engineer recommending Option A continuation while diagnostic § 5.1 recommends Option B — stakeholder reading TL;DR alone gets opposite signal from reading diagnostic |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

### Claim 09.1: 🔴 CRITICAL — IMPL-FIX-011 เป็น L-XL multi-slot mega-task ที่ violate decomposition rule + empirically falsified 3 รอบ

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 (line 1727 header)

**Problem:**

Task header ระบุ `[L-XL] [ea] — Rewrite vs legacy trading-logic translation gap (R-13; multi-slot Evaluate + xslot helper divergence)` — single task ครอบคลุม:
- 18 of 21 slot files (`C/D/F/M/T/Q/H/K/L/LX/I/P/R/B/BI/BR/J/GO` per Description block)
- `services/CrossSlotCoordinator.mqh` xslot helpers (4 additional helpers per "(b) hypothesis")
- CD-pool demote recalibration (per (c))
- Per-tick Print emit suppression (per (d))

Engineer-authored diagnostic `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md § 4.2` quantifies Slot_T alone:

> "Total estimate: ~400 LOC across 5+ files + 3 new MarketContext fields + 1 new indicator handle. Per workflow.md size detection: this is **L-XL scope per slot** — should not arrive at engineer as a single ticket per CLAUDE.md §6 / impl-plan size rules."

Diagnostic § 4.3 extrapolates total cost for {T, G2, G} = **~1,200 LOC × 12-15 sessions** (originally estimated 3-6). Slot_B + long-tail not yet estimated.

Empirical history this session:
- Step 3 Session A → Step 4 iter-1 = 33% top-5 reduction (S/entry 100% but T/G/G2 untouched)
- Session B → iter-2 = 33% (G/G2 single-tick proxies falsified + Net Profit -18.3% regression)
- Session C → iter-3 = 33% (history-based predicates per CodeWiki §3.6/§3.7/§3.15 also falsified — Hull-direction inversion + Fractal-missing surface as architectural gaps in diagnostic § 3)
- `cap at 3 iterations per session` decision-gate HIT (per task-block Step 4 text)

**Why this matters:**

Per `andm-impl-planner` SKILL Phase 2C size detection: L/XL cross-layer task without per-slice decomposition → engineer **STOPS** and routes back to planner. Plan currently asks engineer to "iterate Steps 2-4 (cap 3/session; defer continuation to next session if cap hit)" — this is an open-ended defer-loop, NOT a decomposition + scoped closure path. `/impl-task IMPL-FIX-011` will keep dispatching against the same `[ ]` AC #4 every session, accumulating falsification artifacts without ever hitting a closure boundary the workflow can detect.

Engineer has already produced the diagnostic + Option B recommendation. Continuing as-authored re-litigates the same conclusion at the cost of 9-12 sessions (Slot_G2 + Slot_G architectural-depth discovery — diagnostic § 4.3 predicts same shape as Slot_T).

**Minimum acceptable fix:**

Re-author IMPL-FIX-011 as parent ticket + 4 sub-tickets per engineer diagnostic § 5.1.1:

```
IMPL-FIX-011 (parent — keeps R-13 ownership + paired-bundle deferred E-ACs)
├── IMPL-FIX-011a [L] [ea] Slot_T architectural alignment
│       Scope: 6 gaps in diagnostic § 3 (Hull direction / Ichi cloud-edge field / 5-state pending sub-path /
│       Fractal indicator / zone strength+hit metadata / Hull wave-anchor SL)
│       Est: ~400 LOC, 5-7 sessions, 3 new MarketContext fields + 1 new IDX_FRACTAL_H4 handle
├── IMPL-FIX-011b [L] [ea] Slot_G2 architectural alignment
│       Scope: CodeWiki §3.7 history-based predicates (multi-bar Force buffer / ADX history / pending state)
│       Est: ~300-400 LOC, 4-6 sessions per diagnostic § 4.3 extrapolation
├── IMPL-FIX-011c [L] [ea] Slot_G architectural alignment
│       Scope: CodeWiki §3.6 history-based predicates (DEM rolling / BBHist / Force-peak)
│       Est: ~300-400 LOC, 4-6 sessions
└── IMPL-FIX-011d [M] [ea] Long-tail slot alignment (Slot_B + others surfaced at 5-yr regression)
        Scope: legacy fires + rewrite silent classes not in T/G2/G (e.g. 2021-03-04 B/entry+exit |Δ|=1)
        Est: ~150-200 LOC, 2-3 sessions
```

Parent IMPL-FIX-011 retains the 4 paired-bundle E-ACs (Step 5 5-yr Bucket A drift NFR-1.1 / per-slot NFR-1.6 / Bucket B IMPL-063 chain) — these are run-once empirical drains, not per-slot work.

Each sub-ticket gets its own S-AC + E-AC with per-slot pass criteria (see Finding 09.4).

**Effort:** Medium (plan edit: ~80-120 LOC inside `impl-plan.md` for 4 new task blocks + update Phase Status Snapshot + update overview.md + deferred-ac-registry row alignment per Finding 09.7)

---

### Claim 09.2: 🔴 CRITICAL — S-AC #4 "≥75% top-5 per-slot |Δ| reduction" gate authored before architectural depth was known; now empirically unreachable

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 S-AC #4 (line 1758)

**Problem:**

AC #4 quoted text:

> "[ ] Step 4 re-canary post-patch divergence reduction ≥ 75% per-slot vs Step 2 baseline (Q1 trajectory matches legacy within ~10% on top-5 slots); artifact `_session-handoff/IMPL-FIX-011-q1-postpatch-<YYYYMMDD>-iter<N>.md` per iteration `[log-assertion]`"

Step 4 decision-gate text (line 1751):

> "if Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → proceed to Step 5; else iterate Steps 2-4 (cap at 3 iterations per session; defer continuation to next session if cap hit)"

Empirical evidence this session — 3 consecutive iter falsifications **all at 33%** (1 of 5 top-5 slots hit reduction; the other 4 stayed at |Δ| ≥ 1):

| iter | Patches applied | Top-5 |Δ| sum reduction | Net Profit Q1 vs legacy | Verdict |
|---|---|---|---|---|
| 1 | Session A: Slot_S §3.16 + (d) Print bulk-suppress | **33%** (S 100%; T/G/G2 untouched) | +5.6% (✅ within ±10%) | S-AC #4 NOT MET |
| 2 | + Session B: Slot_G2 §3.7:1/4 + Slot_G §3.6:9 single-tick proxies | **33%** (top-5 sum 15 → 15; 0% extra reduction) | -18.3% (❌ outside ±10%) | S-AC #4 NOT MET + NP regression |
| 3 | + Session C: MarketContext extension + Slot_T 4-sub-path + §3.7/§3.6 history predicates | **33%** (top-5 sum 15 → 10; net 1/5 hit) | -19.9% (❌ outside ±10%) | S-AC #4 NOT MET + NP regression |

Engineer diagnostic § 4.1 quantifies why Fix A alone (Hull direction inversion — the lightest of 6 Slot_T gaps) cannot move the needle:

> "Best-case Fix A only: rewrite goes from 1 (wrong bucket) to maybe 1-2 (right buckets) → T/entry |Δ| stays at 3 OR drops to 2-1. Worst-case: rewrite goes from 1 → 0 → T/entry |Δ| INCREASES to 4. **Either way, the 75% gate cannot be met by Fix A alone.**"

§ 4.2 lists 6 architectural fixes required to hit ≥75% on Slot_T alone:
- Fix A Hull direction (2-line)
- Fix B Ichi cloud-edge (~50 LOC + MarketContext extension)
- Fix C 5-state pending sub-path (~150 LOC + PMR payload schema change)
- Fix D Fractal indicator wiring (~80 LOC + IndicatorService + MarketContext)
- Fix E zone strength + zone_hit metadata (~50 LOC + MarketContext)
- Fix F Hull wave-anchor SL (~60 LOC + helper)

→ ~400 LOC + 3 new MarketContext fields + 1 new indicator handle for Slot_T alone.

**Why this matters:**

AC #4 conflates **per-slot signal correctness** (architectural alignment) with **aggregate per-pass reduction percentage** (mechanical-gate semantics). Engineer cannot mark `[x]` AC #4 honestly until 4 separate slot rewrites land — but the gate is authored as a single binary check per iteration. Result: engineer either (a) lies and ticks `[x]` after partial work, violating Empirical Closure Discipline (forbidden-pattern grep would catch); (b) defers indefinitely; (c) escalates to Option B (current state).

Same defect class as **Shark CMS 2026-04** retrospective in CLAUDE.md § 1 — a multi-tier closure conflation that hides scope and produces phase-gate hallucination if engineer rationalizes the gate down.

**Minimum acceptable fix:**

When IMPL-FIX-011 is decomposed (Finding 09.1), replace the single ≥75% gate with **per-slot AC** in each sub-ticket:

```
IMPL-FIX-011a Slot_T S-AC #4:
[ ] Q1 paired re-canary post-Slot_T patches: rewrite fires at all 4 legacy buckets
    (2021-01-06 02:50 SELL direct-main / 2021-01-19 01:02 SELL THAF / 2021-02-26 04:00 SELL THAF /
    2021-03-30 10:46 BUY direct-main) AND rewrite-only-fire count = 0
    (suppress 2021-03-11 08:00 spurious) → Slot_T |Δ| ≤ 1 across entry+exit `[log-assertion]`
```

Parent IMPL-FIX-011 retains a softer aggregate AC tied to NFR-1.1 (the actual delivery contract):

```
IMPL-FIX-011 parent S-AC #4 (replaces current):
[ ] 5-yr Bucket A regression Net Profit drift ≤ 25% NFR-1.1
    AND per-slot deviation ≤ 10% NFR-1.6 across 17 active slots `[db-inspect]`
    (deferred paired-bundle with IMPL-062 — same content as current parent E-AC; no change there)
```

This makes the gate enforceable per slot + matches NFR contract at parent level. Drop the ≥75% Q1-aggregate gate — Q1 is a 3-month sample of a 5-yr contract; tying delivery to Q1 was a Step 2 sampling-bias artifact.

**Effort:** Low (gate text rewrite per sub-ticket; ~10 LOC each)

---

### 🟠 HIGH

### Claim 09.3: 🟠 HIGH — Hypothesis space (a)/(b)/(c)/(d)/(e) is non-MECE; (e) "eligibility-predicate divergence" subsumes ≥6 architectural sub-classes

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 Description "Hypothesis space" block (lines ~1738-1745) + Step 3 dispatch table (lines 1747-1750)

**Problem:**

Plan authors 4 hypotheses (a)/(b)/(c)/(d) at task creation; Step 2 journal-diff surfaces NEW (e) "per-slot eligibility-predicate divergence" as dominant axis (10/10 top-10 rows classify as (e)). Step 3 dispatch table maps:
- (a) → "IMPL-FIX-007 v2 pattern to slot file"
- (b) → "IMPL-FIX-010 latch pattern to xslot helper"
- (c) → "recalibrate predicate against CodeWiki §3-§5 spec"
- (d) → "bulk-suppress per-tick Print emit"
- (e) → **no dispatch entry** (added post-hoc at Step 2 close)

Engineer diagnostic § 3 enumerates **6 distinct architectural sub-classes** inside the (e) bucket for Slot_T alone:

| Sub-class | Type | Fix shape |
|---|---|---|
| Hull direction inversion | signal inversion bug | 2-line surgical |
| Ichi cloud-edge wrong field + wrong scan | semantic mismatch | new MarketContext field + history scan |
| Pending sub-path resolution missing | 5-state state machine absent | PMR payload schema change |
| Fractal indicator missing | dependency gap | new IDX handle + builder field |
| Zone strength + zone_hit metadata | data-model gap | MarketContext extension |
| SL anchor wrong distance | algorithm divergence | new helper + history scan |

Per Slot_T diagnostic; § 4.3 predicts similar diversity inside G2 + G eligibility.

**Why this matters:**

Hypothesis taxonomy drives Step 3 dispatch table → engineer picks "the matching fix shape" mechanically. But (e) collapses 6+ different fix shapes into one bucket → engineer dispatches the same recipe (single-tick predicate calibration per CodeWiki) and gets falsified each iteration because the actual gap is heterogeneous. iter-2 + iter-3 are exactly this failure mode — applying CodeWiki §3.6/§3.7 predicate translations as if (e) were uniform predicate-threshold tuning.

Same defect class as **Phase Gate Hallucination** (CLAUDE.md § Glossary) at the AC-taxonomy layer: a category that looks like a leaf is actually a parent containing heterogeneous children.

**Minimum acceptable fix:**

In each per-slot sub-ticket (per Finding 09.1), enumerate the slot-specific sub-classes BEFORE Step 3 dispatch. For Slot_T this is the 6-row table in diagnostic § 3. For G2/G, run the same architectural diff as a Step 0 prerequisite (diagnostic-only session producing artifact at `_session-handoff/IMPL-FIX-011{b,c}-architectural-gap-<date>.md`) before engineer commits to predicate edits.

Drop the (a)/(b)/(c)/(d)/(e) parent-level taxonomy from IMPL-FIX-011 task block (it served Step 2 but is now misleading scaffold).

**Effort:** Medium (diagnostic-first Step 0 in each of 011a/b/c; ~1-2 sessions of read-only Slot_G2 + Slot_G legacy-source decoding before fix commits)

---

### Claim 09.4: 🟠 HIGH — Per-slot empirical gates absent; AC text uses aggregate "within ~10% on top-5 slots" framing that single-tick proxies cannot satisfy

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 S-AC #4 + Step 4 decision-gate text (lines 1751, 1758)

**Problem:**

Decision-gate text:

> "if Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → proceed to Step 5"

This aggregates 12 of 21 active slots (B/BR/D/G/G2/H/K/M/P/Q/S/T from Step 2 finding) into one threshold. iter-2 explicitly failed because the gate is non-decomposed:
- Slot_G2 patch suppressed 2021-01-08 entry → 2021-01-12 entry **emerged** (bucket-shift, not suppression) — aggregate count unchanged
- Slot_G `f0` patch had ZERO effect (both 2021-01-04 + 2021-01-14 fires identical pre/post-patch)
- Aggregate metric hid both per-slot failures

iter-3 likewise: G/entry 2 → 1 (PARTIAL — suppressed 2021-01-14 but new 2021-03-30 emerged); G2/entry 2 → 2 (bucket-shifted not reduced); T/entry 3 → 3 (different miss pattern). All three are aggregate-invariant **bucket-shift defects** that the AC text does not catch.

**Why this matters:**

Without per-slot pass criteria, engineer cannot empirically distinguish "predicate change suppressed wrong slot AND created new wrong fire" from "predicate change correctly aligned slot". Per `mt5-log-reader § Empirical Closure Discipline` + Code Review Dimension #11 — aggregate gates over heterogeneous per-slot signals are the classic false-positive vector.

**Minimum acceptable fix:**

In each per-slot sub-ticket (per Finding 09.1), AC #4 enumerates the legacy Q1 trigger buckets explicitly. Example for Slot_T (from diagnostic § 1.2):

```
IMPL-FIX-011a Slot_T S-AC #4 (replaces aggregate gate):
[ ] Q1 paired re-canary: rewrite fires exactly at all 4 legacy buckets with matching path:
    - 2021-01-06 02:50 SELL via direct main-path (sub-path: TB or fall-through; comment T,H/D,...)
    - 2021-01-19 01:02 SELL via PendingT THAF (comment T,PF,...)
    - 2021-02-26 04:00 SELL via PendingT THAF (comment T,PF,...)
    - 2021-03-30 10:46 BUY via direct main-path (sub-path: TB or fall-through; comment T,H/D,...)
    AND rewrite-only-fire count = 0 (the 2021-03-11 08:00 spurious BUY must NOT re-fire)
    Evidence: journal_diff.py output showing Slot_T |Δ| ≤ 1 entry+exit combined `[log-assertion]`
```

Bucket-level enumeration eliminates aggregate-hiding bugs.

**Effort:** Medium (one enumerated bucket table per sub-ticket using existing diagnostic data — Slot_T already done in diagnostic § 1.2; G2/G need same enumeration as Step 0 prerequisite per Finding 09.3)

---

### Claim 09.6: 🟠 HIGH — TL;DR `Next:` line points to "Option A continuation" while engineer diagnostic explicitly recommends Option B — stakeholder reading TL;DR alone gets opposite signal from reading diagnostic

**Location:** `docs/state/impl-plan.md` line 5 TL;DR final sentence + line 7 STEP 3 SESSION C final `Next:` clause

**Problem:**

TL;DR line 5 ends with:

> "**Next:** operator review of iter-3 verdict + Option A/B/C decision; engineer proposes Option A (targeted predicate calibration next session) but defers final pivot to operator."

But diagnostic § 5.1 (committed same date) reads:

> "Engineer recommends **escalating to Option B `/impl-plan-review all`** — re-validate IMPL-FIX-011 task decomposition + AC dual-track. The ≥75% gate is unrealistic given the architectural depth required."

Operator following stakeholder skim test (CLAUDE.md § Glossary Readability) reads TL;DR → sees "engineer proposes Option A" → invokes `/impl-task IMPL-FIX-011` → engineer Option A Session 2 starts → re-discovers Option B from another angle (now Slot_G2 architectural-gap diagnostic). Wasted 1-2 sessions before re-arriving at the same recommendation.

The TL;DR was authored at iter-3 close BEFORE the architectural-gap diagnostic was produced. Diagnostic is `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` committed 0e2f526 — most recent commit per `git log`. TL;DR drift = ~1 commit cycle.

**Why this matters:**

TL;DR is the canonical stakeholder-skim surface per CLAUDE.md Readability Dimension #10. When it points one way and diagnostic § 5.1 (downstream artifact) points the opposite way, the State Single Source of Truth contract (CLAUDE.md § Glossary) is broken — derived view contradicts primary SoT. `/next` orchestrator would prefer TL;DR reading and dispatch Option A; engineer reading diagnostic would refuse and bounce to Option B. Race condition between two readers.

**Minimum acceptable fix:**

Append a new TL;DR entry dated 2026-05-11 documenting the diagnostic + revised recommendation:

```
> 📝 **2026-05-11 IMPL-FIX-011 OPTION A SESSION 1 — SLOT_T ARCHITECTURAL-GAP DIAGNOSTIC produced; engineer
> recommendation FLIPPED to Option B `/impl-plan-review all`.** Diagnostic at
> `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` enumerates 6 architectural gaps in
> Slot_T (Hull direction inversion / Ichi cloud-edge field + history / 5-state pending sub-path /
> Fractal indicator missing / zone strength+hit metadata / Hull wave-anchor SL) — ~400 LOC + 3 new
> MarketContext fields + 1 new indicator handle for Slot_T alone. § 4.3 extrapolates {T, G2, G} =
> ~1,200 LOC × 12-15 sessions (vs 3-6 originally estimated). § 5.1 recommends decomposition into
> IMPL-FIX-011a/b/c/d per-slot sub-tickets + AC #4 threshold revision.
> **Next:** operator decision; engineer NOW recommends Option B (escalate to `/impl-plan-review all`).
```

Once Option B closes via rebuttal cycle, the next TL;DR entry should record the re-decomposition + Phase Status Snapshot update.

**Effort:** Low (single TL;DR entry insert at line 4)

---

### 🟡 MEDIUM

### Claim 09.5: 🟡 MEDIUM — IMPL-FIX-011 declares multi-phase `**Phase**: spans P3 + P4 + possibly P3` — breaks Phase Gate Blocking semantics

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 Phase field (line 1728)

**Problem:**

Phase field text:

> "**Phase**: spans P3 (per-slot `Evaluate` predicates: anti-pyramid latches + entry/exit signal alignment across 18 slots …) + P4 (xslot helper one-shot latches: `RunSafePort`/`RunOrderGroup2`/… in `services/CrossSlotCoordinator.mqh` — same defect class as IMPL-FIX-010 R-12 latches …) + possibly P3 (CD-pool demote + per-slot exit predicate calibration if hypotheses (c)/(d) confirm)."

Per CLAUDE.md § Glossary "Phase Gate Blocking" — `/impl-task` Phase 1.3 HALTs when task's phase > current open phase. With multi-phase declaration `/impl-task IMPL-FIX-011` cannot resolve a single phase → either pre-check accepts whichever phase grep matches first, or halts ambiguously. Plan Staleness Sentinel + Phase Status Snapshot also cannot count this task into a single phase.

**Why this matters:**

P3 Phase Gate cannot close while FIX-011 has open P3 component; P4 Phase Gate cannot close while FIX-011 has open P4 component. Currently both gates list FIX-011 as a blocker — true but inelegant; on decomposition the sub-tickets land cleanly into single phases.

**Minimum acceptable fix:**

Per-slot decomposition (Finding 09.1) makes this self-correcting:
- IMPL-FIX-011a/b/c/d Slot_* alignment → **P3** (per-slot Evaluate predicates per existing P3 Per-Slot Implementation scope)
- xslot-helper latches (if (b) hypothesis surfaces at 5-yr scale) → break out as **IMPL-FIX-011e [S] [ea] xslot latches** if/when empirically needed; defer authoring until 5-yr Bucket A retry surfaces the per-tick emit (parity with IMPL-FIX-010's authoring trigger).
- Parent IMPL-FIX-011 retains paired-bundle E-ACs → P4 phase (matches IMPL-062/063 paired bundle).

This separates per-slot P3 work from P4 numeric-drain bundle cleanly.

**Effort:** Low (folds into Finding 09.1 plan edit)

---

### Claim 09.7: 🟡 MEDIUM — Deferred-AC registry expiry alignment + paired-bundle pointer needs update on re-decomposition

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 E-AC paired-bundle pointers (line 1762: "extend FIX-006/007/009 expiry to absorb IMPL-FIX-011 closure window") + `docs/state/deferred-ac-registry.md` (not re-read this round — flagged for reconciliation)

**Problem:**

Parent IMPL-FIX-011 ties 4 E-ACs to paired-bundle drain with IMPL-062/063 + extends expiry of FIX-006/007/009. On decomposition into 011a/b/c/d:
- Sub-tickets need separate registry rows (or shared single parent row).
- Expiry window currently sized for "IMPL-FIX-011 closure window" — engineer diagnostic § 4.3 predicts 12-15 sessions just for {T,G2,G}; original expiry assumed 1-2 sessions per closure.
- Without re-aligning the registry, `/deliver` Block check (CLAUDE.md § Glossary "Deferred-AC Registry") fires on stale expiry dates.

**Why this matters:**

Registry serves as canonical Active-row destination for E-AC defers. If sub-ticket E-ACs go uncatalogued, engineer falls back to forbidden `[x] + "deferred"` pattern (forbidden-grep CRITICAL). If parent row holds all sub-ticket E-ACs, the row's expiry must reflect realistic multi-sub-ticket close window (4-8 weeks not 2 weeks).

**Minimum acceptable fix:**

Within the same plan rebuttal cycle that lands per-slot decomposition (Finding 09.1):
1. Update `deferred-ac-registry.md` IMPL-FIX-011 row owner from "engineer" to "parent of 011a/b/c/d" with link to all 4 sub-tickets.
2. Set new expiry to realistic close horizon (e.g., 2026-06-30 = ~7 weeks; revisit if sub-ticket cadence faster).
3. Each sub-ticket carries `[log-assertion]` per-slot S-ACs (Finding 09.4) directly — these are session-close S-ACs, not deferred E-ACs.
4. Only the 5-yr Bucket A NFR-1.1 + NFR-1.6 + Bucket B + IMPL-063 chain stays as parent-E-AC paired bundle.

**Effort:** Low (1 registry row edit + 1 expiry recalc; folds into same rebuttal commit as Finding 09.1)

---

## Cross-Document Issues

| # | Issue | Evidence |
|---|-------|----------|
| 1 | TL;DR line 5 says "engineer proposes Option A" vs diagnostic § 5.1 says "Engineer recommends escalating to Option B" — primary SoT contradicts derived artifact | Finding 09.6 |
| 2 | IMPL-FIX-011 task `**Phase**:` field declares `spans P3 + P4` — Phase Status Snapshot tables (line 24-ish region per R08 history) count tasks per-phase and this task is uncountable | Finding 09.5 |
| 3 | `_session-handoff/IMPL-FIX-011-slot-T-architectural-gap-20260511.md` § 5.1.3 raises **NEW QUESTION**: "if these architectural fixes are P4 scope, they should be planned tasks not FIX tickets. Consider promoting to `IMPL-069/070/071` if SD doesn't already cover." — review did NOT raise as a finding because re-routing to `/backtrack sd` is outside `/impl-plan-review` scope, but Rebuttal should consider whether the per-slot sub-tickets are FIX class (recovery) or IMPL class (deferred architectural completion) | Diagnostic § 5.1.3 flagged; future-state question |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 09.1 | 🔴 CRITICAL | IMPL-FIX-011 L-XL mega-task → decompose to 011a/b/c/d per engineer diagnostic | `impl-plan.md § IMPL-FIX-011` header | Medium |
| 09.2 | 🔴 CRITICAL | S-AC #4 ≥75% gate empirically unreachable; replace with per-slot AC + NFR-1.1 parent gate | `impl-plan.md § IMPL-FIX-011 S-AC #4` | Low |
| 09.3 | 🟠 HIGH | Hypothesis (e) non-MECE — 6 architectural sub-classes in one bucket | `impl-plan.md § IMPL-FIX-011 Description / Step 3 dispatch` | Medium |
| 09.4 | 🟠 HIGH | Aggregate "within ~10% on top-5" gate hides per-slot bucket-shift defects | `impl-plan.md § IMPL-FIX-011 Step 4 decision-gate` | Medium |
| 09.6 | 🟠 HIGH | TL;DR `Next:` opposite signal vs diagnostic § 5.1 recommendation | `impl-plan.md` line 5 TL;DR | Low |
| 09.5 | 🟡 MEDIUM | Multi-phase Phase field breaks Phase Gate Blocking | `impl-plan.md § IMPL-FIX-011 Phase field` | Low |
| 09.7 | 🟡 MEDIUM | Deferred-AC registry row needs re-alignment on decomposition | `impl-plan.md § IMPL-FIX-011 E-AC` + `deferred-ac-registry.md` | Low |

---

## End of Review Round 09
