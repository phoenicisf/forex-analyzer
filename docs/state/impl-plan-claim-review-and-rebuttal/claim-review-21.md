# Implementation Plan Claim Review Round 21

| Field | Value |
|-------|-------|
| **Round** | 21 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-18 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Trigger** | Operator invoked `/impl-plan-review all` post-R20 verify-pass cycle continuation **WITHOUT** R18 + R19 + R20 bundled rebuttal commits having landed (3-round-bundle-pending working-tree state confirmed via `git status --porcelain` = 10 entries: 3 M + 7 ??; HEAD = `69be41c [BT-002 cascade] R15 + R16 + R17 impl-plan-rebuttal cascade-drain CLOSED 2026-05-18`). Cascade-drain verify-pass cycle continues per defect-class progression chain pattern (R15→R20 BT-002 cascade closure chain). R21 reviewer surfaces 6 findings at 14th-meta-axis next-finer-granularity layer per R20 §Claim 20.2 conditional reframing prediction ("R21 verify-pass conditional clean WITHIN known axes 1-13"); R20 self-stated it "cannot rule out next-finer-granularity 14th-meta-axis surfacing" — empirically validated by R21 surfacing 6 NEW findings at script-cite-enumeration + Gate-#11-prediction-enumeration + R20-closure-row-self-budget-violation + audit-log-sibling-row-trim-scope + overview.md-within-file-cross-agent-trim-scope + chain-termination-criterion-absence layers. |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL 0 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 1)

**Mechanical pre-scans:**
- Forbidden closure patterns: 1 hit (L27 — sanctioned false positive; greedy-regex `deferred per .* precedent` collapses legal "deferred per registry row" + "fix-round-10 precedent" phrases on same line; CRITICAL count: 0) — unchanged from R20 baseline ✅
- Forward reference (P_n → P_m, m>n): 0 edges (spot-check on Deps lines L414-981; no P_n task depends on P_m where m>n) ✅
- Silent Copy Detector: H=68, A=67, D=1, V=0, N=0 → NOT triggered (D > 0); confirmation note "Audit trail self-validates as genuine independent evaluation, not silent copy" present at L2349 ✅ unchanged
- State reconciliation: impl-plan.md TL;DR L101 / Plan Staleness Sentinel L2357 / Closure Hygiene Status L2368-2370 / overview.md row 19 — **all cite R20 6/6 Accept** ✅ consistent; **Gate #11 working-tree clean post-closure VIOLATED** (10 dirty entries; off-by-one from R20's predicted 9 per Finding 21.2)
- Working-tree state: `git status --porcelain | wc -l` = 10 (3 M `current_handoff.md` + `impl-plan.md` + `overview.md`; 7 ?? `claim-review-{18,19,20}.md` + `rebuttal-round-{18,19,20}.md` + `scripts/`) — R20's enumeration scope omitted `scripts/` as 7th untracked entry

### Top 3 to Fix First
1. **Claim 21.1** 🟠 HIGH — Load-bearing script `scripts/rebuttal_20_clean_anchors.py` exists untracked but NOT cited in `rebuttal-round-20.md` narrative (script-cite enumeration completeness gap at 14th-meta-axis) — `scripts/` + `rebuttal-round-20.md § Files modified`
2. **Claim 21.2** 🟠 HIGH — Gate #11 working-tree count 10 entries at R21 review time exceeds R20 §Claim 20.2's predicted 9 files (off-by-one: `scripts/` directory) — `rebuttal-round-20.md § Claim 20.2`
3. **Claim 21.3** 🟠 HIGH — R20 closure row at `impl-plan.md` L2267 = 6,475 chars violates Claim 20.1's own multi-line block aggregate-volume budget ≤5,000 chars — `impl-plan.md` § Mid-Phase Audit Log R20 closure row

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — 3 HIGH findings → run `/impl-plan-rebuttal claim-review-21.md`
- [ ] ⛔ **Immediate Attention** — fundamental phasing/AC flaw ที่ block engineer execution

> **Why HIGH not CRITICAL:** ทุก finding เป็น cascade-residue ที่ surface ที่ next-finer-granularity layer per R20 §Recurring Weakness #3 reframing pattern. ไม่มี finding ที่ block engineer execution; ทุก finding sanctioned as verify-pass-cycle residue per R19/R18/R17/R16/R15/R14/R13/R12 precedent chain. Defect class = audit-trail-completeness + convention-vs-instance self-consistency at meta-layer; not architectural disagreement.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | 4-phase P1-P4 + 1-paragraph rationale ที่ § Phasing Rationale (L217+); MoSCoW + risk + dep drivers cited; % targets unchanged from approved baseline (no Finding) |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | H=68, A=67, D=1 (IMPL-013 ⚠️ Diverge with Service-coupling rationale), V=0, N=0; Silent Copy Detector NOT triggered (D>0); confirmation note present (no Finding) |
| 3 | Task Decomposition & Sizing | ✅ Pass | 68 tasks ทุก task มี Phase + scope tag + size; no L/XL cross-layer task without decomposition; verified via spot-check P1 IMPL-005 + P2 IMPL-043 + P3 IMPL-019 + P4 IMPL-059 (no Finding) |
| 4 | AC — Dual-Track Compliance | ✅ Pass | Spot-check on IMPL-005 + IMPL-046 + IMPL-039 + IMPL-062 E-AC present + `[evidence-kind]` taxonomy cited; no forbidden pre-authoring at task-AC level (greedy-regex false-positive at L27 sanctioned per R20 §Closure Hygiene Status Gate #1 baseline) (no Finding) |
| 5 | Phase Gates — Testable Exit | ✅ Pass | All 4 phases มี Phase Gate section (L387 P1 + L707 P2 + L935 P3 + L1408 P4); 9-row schema (Structural / Empirical Demo / Tier 1.5 Walk / Live-stack health / Code review / NFR / Deferred drain / Rollback / Docs) ครบ; P1 Phase Gate `[x]` 9/9 closed 2026-05-02; P2/P3/P4 row contents testable (concrete text, no generic "all tests pass") (no Finding) |
| 6 | Deferred-AC Registry Init | ✅ Pass | `docs/state/deferred-ac-registry.md` initialized 2026-05-02 per `/impl-plan` Phase 2.5.5; schema ครบ (Active table + Resolved table + Rules); 55 Active rows + 8 Resolved rows; ทุก Active row มี owner + expiry ≤14d + risk-if-missed; TL;DR ↔ registry recount consistent (5 P1 + 5 P2 + 25 P3 + 19 P4 + 1 P5 = 55 ✅); no `[x]` AC with "deferred" closure note at task level (no Finding) |
| 7 | Cross-Phase Dependency | ✅ Pass | Spot-check on Deps lines L414-981: IMPL-001 (P1) deps none; IMPL-040 (P2) deps IMPL-007+009+042+012 (all P1); IMPL-043 (P2) deps IMPL-006+007+011+042 (P1) + IMPL-047 (P2); IMPL-018 (P3) deps IMPL-002+003+004 (P1); IMPL-053 (P4) deps unrelated to forward — no P_n → P_m where m>n detected in scanned sample (no Finding) |
| 8 | State-File Consistency | ⚠️ Finding 21.1 + 21.2 | impl-plan.md ↔ overview.md row 19 ↔ Plan Staleness Sentinel ↔ Closure Hygiene Status — all cite R20 6/6 Accept consistently ✅; **but Gate #11 working-tree clean post-closure VIOLATED** at 10 dirty entries (R18+R19+R20 commits pending; R20 predicted 9 — see Finding 21.2); `scripts/rebuttal_20_clean_anchors.py` untracked + uncited in rebuttal-round-20.md narrative (see Finding 21.1) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | Re-scan SD Hint Alignment section (L2271-2349) + Phasing Rationale (L217+): no sprint numbers / Q1-Q4 / month-year / team capacity leaked from SD-hint sections; planner's own schedule content concrete (e.g., "Plan approved 2026-05-02"; expiry dates concrete "2026-05-17/18", "2026-05-28") (no Finding) |
| 10 | Readability — Reader Empathy | ⚠️ Finding 21.3 + 21.4 | Narrative top section present (Phase Status Snapshot L111 + Open Risks L122 + Next Best Action L141 + Phasing Rationale L217 + TL;DR/Last updated L101); narrative-prose ภาษาไทย; Mermaid graphs at L278+L296 with narrative context; **but R20 closure row L2267 self-violates Claim 20.1 budget ≤5K chars at 6,475 chars** (see Finding 21.3); **adjacent Mid-Phase Audit Log rows R12-R18 era 5-7K chars each — sibling-row trim scope incompleteness** (see Finding 21.4) |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🟠 HIGH

#### Claim 21.1: 🟠 HIGH — Load-bearing script `scripts/rebuttal_20_clean_anchors.py` exists untracked but NOT cited in `rebuttal-round-20.md` narrative — script-cite enumeration completeness gap at 14th-meta-axis

**Location:**
- File: `scripts/rebuttal_20_clean_anchors.py` (untracked; 3,179 bytes; modified 2026-05-18 15:37)
- File: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Summary "Files modified" enumeration + § Claim 20.5 "Changes Made" narrative

**Problem:**

`scripts/` directory ที่ R20 introduced contains **4 Python files**, not 3:

| Script | Cited in rebuttal-round-20.md? | Purpose (per docstring) |
|--------|-------------------------------|--------------------------|
| `rebuttal_20_edit_impl_plan.py` (24,285 bytes) | ✅ cited L57 Claim 20.1 § Changes Made | "5 distinct surface trims executed" |
| `rebuttal_20_edit_overview.py` (5,950 bytes) | ✅ cited L66 Claim 20.1 § Changes Made | "overview.md row 19 trim" |
| `rebuttal_20_edit_handoff.py` (4,664 bytes) | ✅ cited L68 Claim 20.1 § Changes Made | "current_handoff.md L7 lead-block trim" |
| `rebuttal_20_clean_anchors.py` (3,179 bytes) | ❌ **NOT cited anywhere in rebuttal-round-20.md** | "R20 §20.5 + §20.6 forward-protection — strip physical-line cites from R20-authored narrative" |

The fourth script `rebuttal_20_clean_anchors.py` docstring (L1-7) explicitly attests itself as the **implementation mechanism for Claim 20.5's line-anchor symbolic-marker re-anchor work**:

> "R20 §20.5 + §20.6 forward-protection — strip physical-line cites from R20-authored narrative. Surgical replacements only on the NEW narrative lines (R20 closure row at L2267 + State Reconciliation 3-file rule line at L2370 which R20 §20.1 trim rewrote). Pre-existing R18/R19/R16 audit-history lines preserved verbatim per R10 §10.6 captured-snapshot prose discipline + R20 §20.4 Methodology Discipline Carve-out (captured-snapshot prose with no canonical-pointer status → DO NOT retroactively modify)."

Per Claim 20.4's load-bearing-pointer carve-out, this script **IS** canonical-pointer-status load-bearing — it's the executable that performs Claim 20.5 + 20.6's stated forward-protection work. Yet rebuttal-round-20.md § Claim 20.5 § "Changes Made" narrates the 4-substring replacement table inline as if applied manually:

> "**File:** `docs/state/impl-plan.md` L2266 R19 closure row — rewritten with grep-stable symbolic markers per R18 §18.4 forward-protection convention (atomic with Claim 20.1 trim ~7.2K→~3.9K) ... [4-row substitution table]"

The narrative gives the impression edits were applied via the cited 3 `rebuttal_20_edit_*.py` scripts; in reality, the L2266 + L2267 + L2370 line-anchor work was implemented by an uncited 4th script `rebuttal_20_clean_anchors.py`.

**Why This Matters:**

Engineer running stash-clean G1 audit (workflow.md Gate #10 post-R20 commit) cannot replay R20's line-anchor symbolic-marker work — the script that performed it is unannotated and would either need to be re-discovered by `ls scripts/` or treated as orphan. Same defect class as Claim 19.3 (file-bundle enumeration completeness) but at the script-level granularity within R20: enumeration scope for "Files modified" should include ALL load-bearing artifacts authored during the rebuttal cycle, not just the markdown deliverables.

Per Gate #9 clauses (h)/(i)/(j) discipline — rules that govern source-code cite discipline also apply to narrative-prose hygiene at the methodology-evolution meta-layer — the cite-incompleteness pattern self-replicates one level above the source-tree cite discipline R20 §20.5 closed. **14th-meta-axis script-cite enumeration completeness gap.**

`/next` orchestrator + engineer + future reviewer reading rebuttal-round-20.md to understand "what did R20 ship" gets an incomplete asset manifest: 3 of 4 scripts cited; the 4th orphaned. Audit-trail-completeness layer breached.

**Minimum Acceptable Fix:**

Per R20 §20.4 Methodology Discipline Carve-out distinction:
- The narrative-prose retroactive-modification carve-out (§20.4 case (b) "load-bearing canonical pointer to future commit/event MAY retroactively modify") applies — `rebuttal-round-20.md § Summary "Files modified" + § Claim 20.5 § Changes Made` MAY be retroactively amended to add the 4th script cite, marked as "(post-R21 §21.1 corrigendum)"
- Append to rebuttal-round-20.md § Summary "Files modified" enumeration: `scripts/rebuttal_20_edit_impl_plan.py + rebuttal_20_edit_overview.py + rebuttal_20_edit_handoff.py + **rebuttal_20_clean_anchors.py** (NEW per R21 §21.1 script-cite enumeration completeness)`
- Append to rebuttal-round-20.md § Claim 20.5 § Changes Made narrative: explicit cite that the L2266 + L2267 + L2370 line-anchor symbolic-marker re-anchor was executed via `scripts/rebuttal_20_clean_anchors.py` (substring-substitution script per docstring L1-7)
- Flag NEW Recurring Weakness #16 candidate for `/update-config` ticket: extend Recurring Weakness #14 (multi-surface narrative-volume trim convention) + Claim 19.3 file-bundle enumeration completeness rule to include "all load-bearing scripts authored during rebuttal cycle MUST be cited in rebuttal narrative § Files modified + cited at the §Claim § Changes Made where they implement the fix work"

**Level of Effort:** Low (narrative annotation; 2 cite additions in existing rebuttal-round-20.md surface)

---

#### Claim 21.2: 🟠 HIGH — Gate #11 working-tree count 10 entries at R21 review time exceeds R20 §Claim 20.2's predicted 9 files; off-by-one from `scripts/` directory enumeration omission

**Location:**
- File: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Claim 20.2 § Rationale "predict 9 files (R18 + R19 + R20 work uncommitted)" + § Strength Assessment "R21 Prediction"
- Empirical state: `git status --porcelain | wc -l` = 10 at R21 review time (timestamped 2026-05-18 R21 pre-scan)

**Problem:**

R20 §Claim 20.2 § Rationale (rebuttal-round-20.md L83) authored an explicit forward-prediction:

> "Empirical state at R20 pre-scan time: `git status --porcelain | wc -l` = 7 (3 M `current_handoff.md` + `impl-plan.md` + `overview.md`; 4 ?? `claim-review-18.md` + `claim-review-19.md` + `rebuttal-round-18.md` + `rebuttal-round-19.md`). ... If R21 review runs next without R18+R19 commit = predict 9 files (R18 + R19 + R20 work uncommitted)."

Actual `git status --porcelain` at R21 review time (2026-05-18):

```
 M docs/state/current_handoff.md
 M docs/state/impl-plan.md
 M docs/state/overview.md
?? docs/state/impl-plan-claim-review-and-rebuttal/claim-review-18.md
?? docs/state/impl-plan-claim-review-and-rebuttal/claim-review-19.md
?? docs/state/impl-plan-claim-review-and-rebuttal/claim-review-20.md
?? docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-18.md
?? docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-19.md
?? docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md
?? scripts/
```

Count = **10 entries** (3 M + 7 ??). R20 predicted **9** = 3 M + 6 ?? (counting only the 6 canonical review/rebuttal markdown files for R18/R19/R20). The off-by-one is the `scripts/` directory — R20-authored Python helpers at `scripts/rebuttal_20_edit_*.py` (3 files cited per Claim 20.1) + `scripts/rebuttal_20_clean_anchors.py` (1 file uncited per Finding 21.1) that R20's enumeration scope (canonical state/review-surface markdown only) did NOT count as a separate working-tree dirty entry.

**Why This Matters:**

Methodology-evolution candidate Recurring Weakness #12 (Gate #11 verify-pass-bundle carve-out codification) currently flagged for `/update-config` ticket is now empirically validated as needing **TWO codifications**, not one:
- **(a)** the carve-out for rebuttal-bundle commits — R20's original framing (rebuttals may bundle into operator-driven commit at end of multi-round cascade)
- **(b)** enumeration scope completeness — Gate #11 file-count enumeration MUST include ALL new asset classes introduced by the rebuttal (scripts, simulations, audit artifacts, sidecars), not just canonical markdown surfaces

R20 §Claim 20.2 monotonic growth claim (R17=18+ → R19=5 → R20=7 → predicted R21=9) was off-by-one because the asset-class enumeration was incomplete. The narrative pattern "+2 per round" applies to canonical review/rebuttal markdown only; total working-tree growth is `+2 + N(new_asset_classes)` where N = scripts/simulations/audit-sidecars introduced by the round.

**14th-meta-axis layer**: prediction-enumeration completeness ≠ surface enumeration completeness. R20 §Claim 20.2 fix narrative-acknowledged the monotonic-growth pattern but didn't author the enumeration mechanism for all asset classes — a one-axis-finer-granularity gap.

**Minimum Acceptable Fix:**

Two-path Option A (recommended) or Option B:

- **Option A (recommended) — Drain Gate #11 at R21 closure by committing R18 + R19 + R20 + R21 bundled rebuttal commits** per R20 §Recommendation Approach A or Approach B. After commit, working-tree count drops to 0 (Gate #11 closed atomically). Reset Recurring Weakness #12 codification scope to **both** (a) verify-pass-bundle carve-out + (b) all-asset-class enumeration.
- **Option B — Acknowledge off-by-one + extend Recurring Weakness #12 scope inline**: amend rebuttal-round-20.md § Claim 20.2 § Rationale to acknowledge "predicted 9; actual 10 at R21 review time due to `scripts/` directory omission from enumeration scope" via post-R21 §21.2 corrigendum annotation (same R20 §20.4 carve-out distinction applies). Codify the asset-class enumeration completeness expansion as part of Recurring Weakness #12 codification target.

Either path closes Finding 21.2 atomically.

**Level of Effort:** Low (Option A = ~5 min commit cycle; Option B = ~10 min narrative annotation)

---

#### Claim 21.3: 🟠 HIGH — R20 closure row at `impl-plan.md` L2267 = 6,475 chars violates Claim 20.1's own multi-line block aggregate-volume budget ≤5,000 chars at the surface the convention was authored on

**Location:**
- File: `docs/state/impl-plan.md` L2267 (R20 closure row in Mid-Phase Audit Log)
- Cross-reference: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Claim 20.1 § Forward-protection (cites aggregate-volume budget) + § Cascaded Changes #3 (Recurring Weakness #14 candidate flag)

**Problem:**

R20 §Claim 20.1 § Forward-protection (rebuttal-round-20.md L77) establishes the multi-surface trim convention with explicit aggregate-volume budget:

> "Future R-N verify-pass rounds should follow the same multi-surface trim convention — most-recent 3 rounds inline explicit-exercise narrative + prior rounds via row-pointer references; **aggregate-volume budget per surface (e.g., ≤2,500 chars per single-line skim surface; ≤5,000 chars per multi-line block surface).**"

Empirical char count via `awk '{print NR": "length($0)" chars"}' docs/state/impl-plan.md | sort -t: -k2 -n -r | head -20`:

```
103: 17932 chars
1840: 13556 chars
97: 8520 chars
118: 8091 chars
2251: 7503 chars  ← Mid-Phase Audit Log row (R-N era)
2246: 6927 chars  ← Mid-Phase Audit Log row (R-N era)
2240: 6722 chars  ← Mid-Phase Audit Log row (R-N era)
2267: 6475 chars  ← R20 closure row (NEW per R20 §20.1)
2245: 6406 chars
2252: 6094 chars
2265: 6074 chars  ← R18 closure row
2249: 6047 chars
2232: 5859 chars
2237: 5757 chars
1994: 5437 chars
2248: 5353 chars
2244: 5097 chars
2253: 5044 chars
128:  4972 chars
2250: 4946 chars
```

L2267 R20 closure row = **6,475 chars** — exceeds the multi-line block budget ≤5,000 chars by ~30% (1,475 chars over).

The very surface where Claim 20.1's convention was authored (Mid-Phase Audit Log row, per § Claim 20.1 § Changes Made surface table) violates the convention at the convention's authoring instance. Self-contradicting: R20 establishes ≤5K budget but writes a 6.5K row at the same audit-log surface the convention was authored to govern.

Per R20 §Claim 20.4 Methodology Discipline Carve-out — this is **methodology-discipline self-contradiction at convention-vs-instance layer**, structurally identical to R18 §18.4 "would set a problematic precedent" blanket rule vs R19 §19.4 retroactive-modification action carve-out distinction, but now manifested at narrative-volume budget layer.

**Why This Matters:**

Future audit-log rows (R21, R22, ..., R-N) will reasonably mirror R20's instance as precedent — perpetuating budget violation across all subsequent rounds. The convention-vs-instance gap forks a methodology-evolution debate:

- **Interpretation A — convention is normative**: R20 closure row must be trimmed to ≤5K to match budget; future R-N rows follow.
- **Interpretation B — convention has implicit carve-out for "convention-authoring" rows**: closure rows that introduce NEW axes/conventions may temporarily exceed budget; future audit rows enforce strictly. (Same shape as R20 §20.4 captured-snapshot prose carve-out at a different layer.)

Without explicit annotation choosing A or B, every future R-N audit-log row sets its own precedent. **14th-meta-axis layer: convention-vs-instance self-consistency at narrative-volume budget**, structurally one-axis-finer-granularity beyond R20 §20.4's captured-snapshot-vs-load-bearing distinction at retroactive-modification layer.

`/next` orchestrator + status agents reading audit-log rows to summarize plan state inherit the inconsistent budget enforcement: skim cost grows monotonically as each round exceeds budget by N% accumulating across rounds.

**Minimum Acceptable Fix:**

- **Option A — Trim R20 closure row L2267 to ≤5K chars** via Mid-Phase Audit Log row-pointer references for the verbose §Claim 20.1-20.6 narrative chain (same pattern as R20 §20.1 R19 closure row trim ~7.2K→~3.9K via Mid-Phase Audit Log row references). Target: L2267 from 6,475 → ≤5,000 chars (~23% reduction).
- **Option B — Document an explicit carve-out in Claim 20.1 § Forward-protection** for "convention-authoring closure rows" (rows that introduce NEW axes/conventions may temporarily exceed budget; future audit rows enforce strictly). Annotate L2267 as scope-out exception with "(convention-authoring row per R21 §21.3 carve-out)".

Either Option closes Finding 21.3.

Recurring Weakness #17 candidate flag (codification): extend Recurring Weakness #14 (multi-surface narrative-volume trim convention) at `/update-config` ticket to explicitly address convention-vs-instance self-consistency at the surface the convention is authored on — i.e., the convention-authoring round MUST verify-itself at its own surface before forward-protection clause activates for subsequent rounds.

**Level of Effort:** Low (Option A = ~15 min trim cycle via Edit tool; Option B = ~5 min narrative annotation)

### 🟡 MEDIUM

#### Claim 21.4: 🟡 MEDIUM — Mid-Phase Audit Log adjacent rows R12-R18 era (L2232-L2253 + L2265) remain 5-7K chars each — Claim 20.1 multi-surface trim convention sibling-row scope incompleteness

**Location:**
- File: `docs/state/impl-plan.md` Mid-Phase Audit Log adjacent rows L2232..L2253 (R12-R17 era + R18 row L2265)
- Cross-reference: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Claim 20.1 § Changes Made surface table (enumerates 6 surfaces; sibling audit-log rows NOT in scope)

**Problem:**

Claim 20.1 § Changes Made enumerated "**all 6 canonical-current narrative-propagation surfaces**":
1. impl-plan.md L101 TL;DR `Last updated:` lead clause
2. impl-plan.md L2266 R19 closure row (Mid-Phase Audit Log)
3. impl-plan.md L2357 Plan Staleness Sentinel `Last review on:`
4. impl-plan.md L2369 Closure Hygiene Status `Phase 5 mechanical gates:`
5. impl-plan.md L2370 Closure Hygiene Status `State Reconciliation 3-file rule:`
6. overview.md row 19 + current_handoff.md L7 (combined as Tier 2 + Tier 3)

The Mid-Phase Audit Log contains additional rows beyond the R19 closure row (#2 above):

| Audit Log Row (approx era) | Line | Chars | Status |
|---------------------------|------|-------|--------|
| R12 closure (2026-05-13) | L2232 | 5,859 | NOT in Claim 20.1 scope |
| R13 closure (2026-05-13) | L2237 | 5,757 | NOT in Claim 20.1 scope |
| R14 closure (2026-05-13) | L2240 | 6,722 | NOT in Claim 20.1 scope |
| R15 closure (2026-05-18) | L2244 | 5,097 | NOT in Claim 20.1 scope |
| R16 closure (2026-05-18) | L2245 | 6,406 | NOT in Claim 20.1 scope |
| R17 closure (2026-05-18) | L2246 + L2249 | 6,927 + 6,047 | NOT in Claim 20.1 scope |
| R18 closure (2026-05-18) | L2248 + L2265 | 5,353 + 6,074 | NOT in Claim 20.1 scope |
| Other R-N era rows | L2250-L2253 + L2237 etc | 4,946 - 7,503 | NOT in Claim 20.1 scope |

Collectively ~73K chars of narrative-volume across ~12-13 sibling audit-log rows — all exceeding the ≤5K multi-line block budget Claim 20.1 § Forward-protection cites. Only R19 closure row L2266 was trimmed (~7.2K → ~3.9K per Claim 20.1 § Changes Made) + R20 closure row L2267 introduced (but at 6.5K — see Finding 21.3).

**Why This Matters:**

R20 §Claim 20.4 Methodology Discipline Carve-out distinction provides a plausible exemption mechanism:

- **Captured-snapshot prose with no canonical-pointer status** (audit-history rows preserved per R10 §10.6 strikethrough-append discipline) → DO NOT retroactively modify
- **Load-bearing canonical pointer to future commit/event** (current-active narrative-propagation surfaces) → MAY retroactively modify per Gate #9 clause (h) extension

Under this distinction, R12-R18 sibling audit-log rows are arguably **captured-snapshot prose** (audit-history, not current-active narrative) — exempt from the trim convention by the same carve-out logic.

**But Claim 20.1 § Forward-protection didn't explicitly invoke the §20.4 carve-out for R12-R18 sibling rows** — the omission is unannotated. Reader reasonably interprets the convention as universally applicable to "multi-line block surfaces" within the Mid-Phase Audit Log table; the implicit exemption is invisible.

**15th-meta-axis layer**: trim convention scope = "current-active surfaces" not "all instances of same surface type", but the boundary is implicit, not stated. Same shape as R26 §Finding 26.1 falsification of R25's documented mechanism (mechanism-vs-hand-classification gap surfaced at exemption-regex axis per workflow.md Gate #9 clause (i)) but at narrative-volume trim convention layer.

**Minimum Acceptable Fix:**

- **Option A (recommended) — Document the §20.4 carve-out exemption explicitly** in Claim 20.1 § Forward-protection: append clause "Audit-history rows (R-N closure rows authored at prior rebuttal closure time; no current-active narrative-propagation status; preserved per R10 §10.6 strikethrough-append discipline) are exempt from the multi-line block ≤5K budget per R20 §20.4 captured-snapshot prose carve-out. Only current-active narrative-propagation surfaces enforce the budget."
- **Option B — Trim R12-R18 sibling rows per Claim 20.1 convention** uniformly across all audit-log rows. Higher effort + violates R10 §10.6 captured-snapshot prose discipline per R20 §20.4.
- **Option C — Defer to `/update-config` ticket consolidation** per Recurring Weakness #14 codification scope extension; flag NEW Recurring Weakness #18 candidate.

Option A recommended; Option C parallel.

**Level of Effort:** Low (Option A = ~5 min narrative annotation; Option C = `/update-config` ticket flag)

---

#### Claim 21.5: 🟡 MEDIUM — `overview.md` sibling rows 20 (Impl Tasks 40,250 chars) + 21 (Code Review 36,605 chars) untrimmed despite same-file scope; cross-agent within-file consistency gap

**Location:**
- File: `docs/state/overview.md` row 20 (Impl Tasks status field; line index 20) + row 21 (Code Review status field; line index 21)
- Cross-reference: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Claim 20.1 § Changes Made (overview.md row 19 trim ~104K → ~4,528 chars [~96% reduction])

**Problem:**

`docs/state/overview.md` is a 25-line file containing the Phase Status table. Per-row char count via `awk '{print NR": ["length($0)" chars]"}' docs/state/overview.md`:

```
Row 10 Design (BA): 2,251 chars
Row 11 Design (SD): 11,239 chars  ⚠️
Row 12 Design (UX): 513 chars (N/A)
Row 13 Design (TD): 2,571 chars
Row 14 Design QA (BA): 407 chars
Row 15 Design QA (SD): 527 chars
Row 16 Design QA (UX): 113 chars
Row 17 Design QA (TD): 11,536 chars  ⚠️
Row 18 Project Bootstrap: 1,731 chars
Row 19 Impl Plan: 4,528 chars  ✅ (trimmed per Claim 20.1)
Row 20 Impl Tasks: 40,250 chars  🔴
Row 21 Code Review: 36,605 chars  🔴
Row 22 Red Team: 36 chars (Not started)
```

Claim 20.1 trimmed row 19 (Impl Plan, impl-plan-rebuttal's write-surface) from ~104K → ~4,528 chars (~96% reduction). But sibling rows in the same overview.md table file:

- **Row 20 Impl Tasks** = 40,250 chars (Impl Engineer's territory; updated when IMPL-NNN tasks close)
- **Row 21 Code Review** = 36,605 chars (Code Reviewer's territory; updated when /impl-review fix rounds close)

Combined: 76,855 chars in the same overview.md file remain unfiltered. Same-file scope: trim convention applied to impl-plan-rebuttal's row only; sibling rows updated by other agents (Impl Engineer, Code Reviewer) carry the same narrative-volume bloat pattern.

**Why This Matters:**

Reader experience within `overview.md`:
- Row 19 (Impl Plan, 4.5K chars) skims quickly via row-pointer references to Mid-Phase Audit Log
- Rows 20+21 (76K chars total) don't — they replicate the pre-trim narrative-bloat pattern Claim 20.1 set out to address

Cross-agent territory boundary: Recurring Weakness #14 currently scoped to "impl-plan-rebuttal's write-surfaces" per R20 §20.1 implicit scoping. But within-file consistency suggests the trim convention SHOULD apply uniformly to all rows in the same state file regardless of authoring agent — otherwise reader's skim cost is dominated by the most-bloated row in the file.

**16th-meta-axis layer**: within-file cross-agent trim convention scope. Per-agent territory ≠ same-file. Methodology-evolution candidate.

**Minimum Acceptable Fix:**

- **Out-of-scope for R21 rebuttal** per R-N rebuttal scope discipline (cross-agent territory; rows 20-21 are Impl Engineer + Code Reviewer write-surfaces, not impl-plan-rebuttal's direct fix scope).
- **Flag NEW Recurring Weakness #19 candidate for `/update-config` ticket**: extend Recurring Weakness #14 (multi-surface narrative-volume trim convention) cross-agent — trim convention applies uniformly to all rows in the same state file regardless of authoring agent.
- **Document the cross-agent-territory boundary explicitly** in Claim 20.1 § Forward-protection (current scope = "impl-plan-rebuttal's write-surfaces"; cross-agent extension pending `/update-config`).

**Level of Effort:** Low (methodology evolution flag; no immediate file edit required for cross-agent surfaces)

### 🔵 LOW

#### Claim 21.6: 🔵 LOW — R20 §Claim 20.2 + §R21 Prediction "conditional clean WITHIN known axes 1-N" reframing pattern lacks positive termination criterion for verify-pass-cycle chain

**Location:**
- File: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-20.md` § Strength Assessment "R21 Prediction" row + § Cascaded Changes #9 (12 open methodology-evolution candidates accumulation)
- Cross-reference: `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-19.md` § Claim 19.x → Recurring Weakness #3 reframing lesson

**Problem:**

R20 § Strength Assessment "R21 Prediction" row:
> "Conditional clean 'WITHIN known axes 1-13' — R20 cannot rule out next-finer-granularity 14th-meta-axis surfacing at next round per defect-class progression chain pattern"

Per R18 §Recurring Weakness #3 reframing lesson, R-N predictions are now conditional ("WITHIN known axes 1-N", not absolute "no findings expected") to avoid R-N+1 falsification of R-N's prediction. R20 explicitly states it "cannot rule out next-finer-granularity 14th-meta-axis surfacing" — which the R21 empirical surface (6 findings at NEW layers per R20 §20.2 + 20.5 next-finer-granularity layers) has now validated.

But the chain pattern is **open-ended**: there is no positive termination criterion. R20 § Cascaded Changes #9 enumerates 12 open methodology-evolution candidates (Recurring Weaknesses #4-#15) as `/update-config` ticket candidates. The chain currently has:

- R12-R14 BT-001 cycle (3 rounds)
- R15-R20 BT-002 cycle (6 rounds; verify-pass continuation)
- R21+ projected continuation (per R20's prediction; this round validates)

Each round surfaces ≤6 findings at NEW meta-axis layers. R26 §Finding 26.1 falsified R25 §Termination Test claim (per workflow.md Gate #9 clause (h)/(i) chain discussion) — empirical pattern is "chain termination claims are empirically falsifiable until codification mechanism enforces strict-reading verification".

**Why This Matters:**

Engineer / reviewer / operator have no decision rule for when verify-pass cycle ENDS:
- Could perpetuate indefinitely (R21 → 14th axis → R22 → 15th axis → ...)
- Each round wastes engineer + reviewer + operator session-time on cascade-residue narrative annotation
- 12 open methodology-evolution candidates have not been consolidated into a single `/update-config` ticket; backlog grows monotonically

R20's reframing pattern protects R-N's reputation (avoids R-N+1 falsification) but does NOT close the chain. The 12 open candidates suggest the methodology has reached a complexity threshold where consolidation is required.

**Methodology-evolution layer concern**: the verify-pass-cycle chain pattern is itself a methodology defect at the meta-meta-layer — finding bugs in the bug-finding mechanism.

**Minimum Acceptable Fix:**

- **Document explicit termination criterion** in `workflow.md` or a methodology-evolution document. Candidate criteria:
  - "Verify-pass cycle terminates when 3 consecutive rounds (R-N, R-N+1, R-N+2) surface 0 findings at any meta-axis"
  - "Verify-pass cycle terminates when 1 round (R-N) surfaces only LOW-severity findings"
  - "Verify-pass cycle terminates when `/update-config` ticket consolidating all open Recurring Weaknesses lands"
- **Per R26 §Finding 26.1 lesson**: termination claims MUST be empirically verified by running the documented mechanism (not hand-classification). Future R-N rounds asserting "chain terminated" MUST cite the verification mechanism + empirical run output.
- **Flag NEW Recurring Weakness #20 candidate**: verify-pass-cycle chain termination criterion codification (highest-priority `/update-config` ticket; consolidates Recurring Weaknesses #4-#15+).

**Level of Effort:** Medium (methodology evolution; requires consensus on termination criterion; out-of-scope for R21 immediate fix)

---

## Cross-Document Issues

ไม่พบ cross-document contradictions ที่ raise นอกเหนือจาก 6 findings above:

- **Task ID consistency** ✅ — IMPL-001..IMPL-068 ⊥ IMPL-FIX-001..013 ⊥ IMPL-PERF-001 (alias IMPL-FIX-009) consistent across impl-plan.md + overview.md + current_handoff.md + handoff sidecars
- **Evolution step references** ✅ — E1/E1a/E1b/E1c/E2 cited in Phasing Rationale L217+ all map to `docs/design-docs/07-future-evolution.md § 6`; ADR backing (ADR-007 for E1; ADR-002 for E2) verified
- **Phase Hint references** ✅ — All 68 IMPL tasks have SD Hint row in machine-readable scratch table L2271+; classifications (67 ✅ Align + 1 ⚠️ Diverge) auditable
- **Task scope grounding** ✅ — Spot-check on IMPL-005 (TD-02 §5), IMPL-046 (ADR-007 + spike harness), IMPL-039 (ADR-009 BI SL fix), IMPL-059 (TD-02 §7.4 Phase B Init order) — all cite valid TD/ADR sections that exist
- **ADR backing** ✅ — All 12 locked ADRs (ADR-001..012) cited in Phasing Rationale + per-task ADR fields exist; ADR-013 + ADR-014 Superseded by BT-002 (audit history preserved per CLAUDE.md §6 ADR Discipline)

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 21.1 | 🟠 HIGH | Load-bearing script `scripts/rebuttal_20_clean_anchors.py` uncited in `rebuttal-round-20.md` narrative — script-cite enumeration completeness gap at 14th-meta-axis | `scripts/` + `rebuttal-round-20.md § Files modified + § Claim 20.5 § Changes Made` | Low |
| 21.2 | 🟠 HIGH | Gate #11 working-tree count 10 entries exceeds R20 §Claim 20.2's predicted 9; off-by-one from `scripts/` enumeration omission | `rebuttal-round-20.md § Claim 20.2 § Rationale` | Low |
| 21.3 | 🟠 HIGH | R20 closure row `impl-plan.md` L2267 = 6,475 chars violates Claim 20.1's own ≤5K multi-line block budget; convention-vs-instance self-contradiction at authoring surface | `impl-plan.md` § Mid-Phase Audit Log R20 closure row L2267 | Low |
| 21.4 | 🟡 MEDIUM | Mid-Phase Audit Log adjacent rows R12-R18 era (L2232-L2253 + L2265) 5-7K chars each — Claim 20.1 trim convention sibling-row scope incompleteness (implicit §20.4 carve-out unannotated) | `impl-plan.md` § Mid-Phase Audit Log L2232-L2265 | Low |
| 21.5 | 🟡 MEDIUM | `overview.md` rows 20 (Impl Tasks 40K) + 21 (Code Review 36K) untrimmed despite same-file scope; cross-agent within-file consistency gap | `overview.md` rows 20-21 | Low (methodology flag; out-of-scope immediate fix) |
| 21.6 | 🔵 LOW | R20 conditional "WITHIN known axes 1-N" reframing pattern lacks positive termination criterion for verify-pass-cycle chain; 12 open methodology-evolution candidates accumulating | `rebuttal-round-20.md § Strength Assessment "R21 Prediction"` + workflow.md Gate #9 clause chain | Medium (methodology evolution) |

---

**R21 Recurring Weakness candidates (4 NEW, extending R18 #4-#7 + R19 #8-#11 + R20 #12-#15 → 16 total open):**
- **#16** Script-cite enumeration completeness rule per Claim 21.1 (extend Claim 19.3 file-bundle enumeration + R16 §16.2 commit-hygiene to load-bearing scripts authored during rebuttal cycle)
- **#17** Convention-vs-instance self-consistency at authoring surface rule per Claim 21.3 (convention-authoring round MUST verify-itself at its own surface before forward-protection clause activates for subsequent rounds)
- **#18** Multi-surface trim convention §20.4 carve-out explicit annotation rule per Claim 21.4 (audit-history rows exempt; only current-active narrative-propagation surfaces enforce budget — codify the exemption mechanism)
- **#19** Cross-agent within-file trim convention scope extension rule per Claim 21.5 (Recurring Weakness #14 codification extend to all rows in same state file regardless of authoring agent)
- **#20** Verify-pass-cycle chain termination criterion codification rule per Claim 21.6 (highest-priority `/update-config` ticket; consolidates #4-#15+ open candidates)

Total open methodology-evolution candidates: **20** (R18 #4-#7 + R19 #8-#11 + R20 #12-#15 + R21 #16-#20). Recurring Weakness #20 (chain termination criterion) is recommended highest-priority consolidation target.

---

## End of Review
