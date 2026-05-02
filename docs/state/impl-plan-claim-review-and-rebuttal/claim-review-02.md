# Implementation Plan Claim Review Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Target** | `docs/state/impl-plan.md` (post rebuttal-01) |
| **Date** | 2026-05-02 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Plan version reviewed** | Round 01 patched per `rebuttal-round-01.md` (7 Accept / 0 Partial / 0 Reject) |

---

## 📊 At-a-Glance

**Total findings:** 3 (🔴 CRITICAL 0 / 🟠 HIGH 0 / 🟡 MEDIUM 1 / 🔵 LOW 2)

**Mechanical pre-scans:**
- Forbidden closure patterns (`grep -nE 'deferred to operator-runtime|deferred to post-launch|deferred per .* precedent|structurally complete.*deferred|live verification deferred'` on `impl-plan.md`): **0 hits** ✅ (sustained across rounds 01→02)
- Forward reference (P_n → P_m, m>n): **0 edges** — rebuttal-01 fixes did not touch any `**Dependencies**:` field; round-01 walk result still valid ✅
- Silent Copy Detector: H = 68, A = 67, D = 1, V = 0, N = 0 → **trigger condition `D == 0` not met** (D = 1, IMPL-013 P4→P3 documented). Audit trail = genuine independent evaluation ✅
- State reconciliation across 4 files (impl-plan ↔ overview ↔ deferred-ac-registry ↔ operator-action-registry): **2 internal divergences inside impl-plan.md itself** (TL;DR `last action` stale + Mid-Phase Audit Log missing rebuttal-01 row — see Claim 02.1); registries still empty per Phase 1 baseline ✅; `overview.md § Impl Plan` row correctly appended with rebuttal-01 closure ✅

### Top 3 to Fix First

1. **Claim 02.1** 🟡 — State Reconciliation incomplete post-rebuttal-01 — TL;DR "last action" stale + Mid-Phase Audit Log missing rebuttal closure row → `impl-plan.md` lines 9 + 1509-1515
2. **Claim 02.2** 🔵 — P4 cross-slot + QA tasks (IMPL-053..058 + IMPL-066..068) still use bracket-condensed S-AC/E-AC; round-01 standardized only the 21 P3 slots → `impl-plan.md` § P4
3. **Claim 02.3** 🔵 — P3 Phase Gate Tier 1.5 row still carries "(×21 brief runs OR 1 full 5-yr run)" alternative after Claim 01.1 fix chose option (a); the OR-clause is now redundant + invites engineer to skip per-slot runs → `impl-plan.md` § P3 Phase Gate § Tier 1.5

### Verdict

- [x] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH; round-01 cleanup landed cleanly (7/7 polished); 1 MEDIUM ที่เหลือ = state-reconciliation hygiene gap inside the same artifact (impl-plan.md)
- [ ] ⚠️ **Needs Rebuttal Round** — N/A (none of the 3 findings block engineer; recommend optional 1-line rebuttal pass to close 02.1 before `/impl-task IMPL-001` so audit trail is consistent from day 1)
- [ ] ⛔ **Immediate Attention** — N/A

> **Recommendation:** Proceed to `/impl-task IMPL-001` is safe. Optional fast `/impl-plan-rebuttal claim-review-02.md` pass (~5-10 min) closes Claim 02.1 (state reconciliation hygiene) + Claim 02.3 (Phase Gate clarity) before P3 surfaces. Claim 02.2 (P4 AC verbosity parity) lower priority — defer to mid-phase audit log if desired.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Round-01 Claim 01.2 fix landed: % targets table + interpretation paragraph at lines 64-73 quantify P2 −24/−34% + P4 +15/+25% deviation with MQL5 OO compile-direction rationale; semantic + numeric departures both surfaced |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | 67 ✅ + 1 ⚠️ + 0 🔴 + 0 ◻️ tally unchanged; Silent Copy Detector still untriggered (D=1 > 0); IMPL-013 divergence justification (Service-coupling rule) intact |
| 3 | Task Decomposition & Sizing | ⚠️ Finding 02.2 | Round-01 Claim 01.5 fix landed cleanly for 21 P3 slots IMPL-019..039 (full bullet style with slot-unique semantics preserved + smoke ini PR-contract bullet) + Claim 01.6 fix landed for IMPL-049 (4 sub-pass decomposition hint w/ engineer HALT latitude); **but** P4 cross-slot IMPL-053..058 + 3 P4 QA tasks IMPL-066/067/068 still use bracket-condensed AC syntax — round-01 deferred this scope by design (claim 01.5 was P3-only) |
| 4 | AC — Dual-Track Compliance | ✅ Pass | Forbidden closure pattern grep = 0 hits sustained; mandatory E-AC trigger surfaces all carry ≥1 E-AC with `[evidence-kind]` taxonomy; no pre-authored closure violations introduced by rebuttal-01 |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 02.3 | Round-01 Claim 01.4 fix landed correctly: P4 Phase Gate Live-stack health row now generic boot/pipeline check; NFR check row absorbs 10 NFR sub-bullets — SKILL template role split restored. **But** P3 Tier 1.5 row "(×21 brief runs OR 1 full 5-yr run)" alternative still present after Claim 01.1 fix chose option (a) — the OR-clause is now redundant (since 21 ini files will exist per per-slot S-AC bullet) and invites partial compliance |
| 6 | Deferred-AC + Operator Action Registry | ✅ Pass | Both registries still empty per Phase 1 baseline; no new defer raised; rebuttal-01 did not touch registries |
| 7 | Cross-Phase Dependency | ✅ Pass | No `**Dependencies**:` field touched by rebuttal-01; round-01 forward-reference walk result (0 edges) still valid; Mermaid graphs unchanged |
| 8 | State-File Consistency | ⚠️ Finding 02.1 | **`overview.md § Impl Plan` row** correctly appended with rebuttal-01 closure (✅ external propagation done); **but** `impl-plan.md` itself has 2 internal staleness gaps: (1) line 9 TL;DR "last action: plan generated by `/impl-plan` (commit pending)" — should reflect rebuttal-01 closure; (2) Mid-Phase Audit Log (lines 1509-1515) only has the first-cut 2026-05-02 row — missing rebuttal-01 closure entry per CLAUDE.md §6 State Reconciliation Discipline ("ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**") |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | Grep `sprint\s+\d|Q[1-4]|week\s+\d` returns 1 legitimate hit (title "Sprint 1") + DST test dates `2026-Mar-28` / `2026-Oct-25` are test-data boundaries, not delivery schedule. No new leakage introduced by rebuttal-01 |
| 10 | Readability — Reader Empathy | ✅ Pass | Round-01 Claim 01.7 fix landed: TL;DR label rename `📋 **TL;DR / At-a-Glance**` makes header findable for stakeholder skim; Phasing Rationale % targets table + Scope Tags Glossary footer (Claim 01.3) further improve reader reproducibility; 60-sec stakeholder skim test still passes |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

_ไม่มี — rebuttal-01 fixes landed without introducing forbidden closure patterns, forward references, or Evolution Sequence violations. Plan retains executability._

### 🟠 HIGH

_ไม่มี — no sizing miscall, no Phase Gate generic-text drift, no missing E-AC trigger, no broken state reconciliation across the 4 primary files (overview ↔ registries ↔ plan core)._

### 🟡 MEDIUM

---

#### Claim 02.1: 🟡 MEDIUM — State Reconciliation incomplete post-rebuttal-01: TL;DR "last action" stale + Mid-Phase Audit Log missing rebuttal closure row

**Location:** `docs/state/impl-plan.md` line 9 (TL;DR callout) + lines 1509-1515 (Mid-Phase Audit Log table)

**Problem:**
Rebuttal-01 modified 7 edit clusters in `impl-plan.md` + appended closure note ใน `overview.md § Impl Plan` row, but **left 2 internal state markers inside `impl-plan.md` stale**:

1. **TL;DR / At-a-Glance callout (line 9):**
   ```
   > **Last updated:** 2026-05-02 · last action: plan generated by `/impl-plan` (commit pending)
   ```
   The callout's own meta-comment ระบุ: *"(อัปเดตทุกครั้งที่ปิด task / เกิด finding ใหม่)"*. Rebuttal-01 closed 7 findings (= "เกิด finding ใหม่ + ปิดไป") — qualifies for update. "last action" still says "plan generated by `/impl-plan` (commit pending)" ทั้งที่ commit pending state ไม่ตรงอีกต่อไป (rebuttal-01 closure happened post-commit).

2. **Mid-Phase Audit Log (lines 1509-1515):**
   ```
   > Engineer logs mid-phase findings, fix-rounds, and impl-plan rebuttals here — primary audit trail per CLAUDE.md §6 State SoT
   
   | Date       | Phase | Action                                  | ... |
   |------------|-------|-----------------------------------------|-----|
   | 2026-05-02 | —     | Plan generated by `/impl-plan` (first cut) | ... |
   ```
   Header explicitly states scope = "**impl-plan rebuttals**". Round-01 rebuttal = an impl-plan rebuttal. Should appear as a 2nd row but is absent. The defender's `rebuttal-round-01.md § Cascaded Changes #8` consciously chose to skip ("audit log = engineer-owned; defender does not write to it") — but the audit log header itself extends scope to fix-rounds + rebuttals, which contradicts the defender's reading. Ambiguity = the row is missing.

**Why this matters:**
1. **Status agent / `/next` accuracy:** A status-reading agent (e.g. `/next` Check 5.5 + Check 6) reads Mid-Phase Audit Log first to determine "what happened most recently" before scanning task closures. Without the rebuttal-01 row, the audit log says "last action = plan first-cut on 2026-05-02" — a future agent reading only the audit log would conclude "plan never went through review/rebuttal" → may recommend re-running review. Same defect class as Phase Gate Hallucination (CLAUDE.md §1) but in a different table.
2. **TL;DR skim test fail:** Stakeholder reading top of plan sees "last action: plan generated by `/impl-plan` (commit pending)" — concludes plan is in pre-review state. Misleading by ~1 review-rebuttal cycle. Plan readiness signal divergent from `overview.md § Impl Plan` row (which says "✅ Complete + Rebuttal Round 01").
3. **State Reconciliation Discipline (CLAUDE.md §6):** mandates "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**: (1) `impl-plan.md` (primary SoT — `[x]` AC, Phase Gate, **audit log**), (2) `overview.md` ..." — primary SoT layer #1 is incomplete; only #2 was updated. ห้าม update เพียงไฟล์เดียว.
4. **Forward-reference setup for IMPL-049:** rebuttal-01 added IMPL-049 description hint that says "document split decision in Mid-Phase Audit Log". Engineer-side downstream usage assumes audit log is being maintained as new actions occur — current empty-after-first-cut state degrades the contract.

**Minimum acceptable fix:**
Two edits inside `impl-plan.md`:

(a) **Update TL;DR callout last action** (line 9):
```diff
-> **Last updated:** 2026-05-02 · last action: plan generated by `/impl-plan` (commit pending)
+> **Last updated:** 2026-05-02 · last action: rebuttal-round-01 closed (7 Accept / 0 Partial / 0 Reject); plan ready for `/impl-task IMPL-001`
```

(b) **Append Mid-Phase Audit Log row** (after line 1515):
```markdown
| 2026-05-02 | — | Rebuttal round 01 closed | impl-plan.md, overview.md | 7/7 Accept; touched 7 edit clusters (TL;DR rename / Phasing % targets / IMPL-049 decomposition hint / 21 P3 slot ACs standardized + smoke ini PR contract / P4 Phase Gate Live-stack ↔ NFR row split / scope-tag glossary footer); 0 forbidden patterns; 0 forward refs; registries unchanged. See `impl-plan-claim-review-and-rebuttal/rebuttal-round-01.md` |
```

Whichever party owns the propagation (defender as plan-fix author OR engineer as state-keeper before `/impl-task`) should land both edits in 1 small commit before any IMPL-XXX work begins. **Recommended convention:** defender writes the row (since they hold the cleanest summary of what changed in the rebuttal); engineer ratifies on commit.

**Effort:** Low (~30 sec — 1 line replace + 1 row append)

---

### 🔵 LOW

---

#### Claim 02.2: 🔵 LOW — P4 cross-slot + QA tasks (IMPL-053..058 + IMPL-066..068) still use bracket-condensed S-AC / E-AC; round-01 standardized only the 21 P3 slots

**Location:** `docs/state/impl-plan.md` § P4 — IMPL-053 through IMPL-058 (6 cross-slot coordinator tasks) + IMPL-066, IMPL-067, IMPL-068 (3 QA verification tasks) — **9 of 17 P4 tasks (53%)**

**Problem:**
Round-01 Claim 01.5 standardized 21 P3 slot tasks (IMPL-019..039) จาก mixed bracket-condensed shorthand → uniform full-bullet style with 4 explicit S-AC bullets + 1 E-AC bullet preserving slot-unique semantics. Rebuttal-01 explicitly noted ("Note on scope" in Claim 01.5 response): *"P4 cross-slot tasks (IMPL-053..058) + 3 P4 QA tasks (IMPL-066/067/068) still use bracket-condensed S-AC syntax. Reviewer's Claim 01.5 was explicitly scoped to P3 IMPL-019..039 ('21 slot tasks'). P4 condensed-AC normalization is **out of this rebuttal's scope** — defer to next plan-review round if reviewer flags broader pattern."*

This review (round 02) is the next plan-review round, and the broader pattern is now being flagged. Examples from current state:

- **IMPL-053** (M, CrossSlotCoordinator::RunSafePort, BR-8.1, line 1255-1265):
  ```
  - **S-AC**: [method implemented; threshold 55 badPIP + profit gate]
  - **E-AC**: [Smoke: simulate 10 slots avg badPIP=60 + profit>0 → SafePort closes them en masse `[log-assertion]` + `[db-inspect]`]
  ```
- **IMPL-054** (M, RunOrderGroup2): `**S-AC**: [method implemented]` / `**E-AC**: [Smoke trigger Ichimoku double-bounce → close-all `[log-assertion]`]`
- **IMPL-055** (S, RunForceCutloss): same pattern
- **IMPL-056** (XS, ExtraCheckFunction2): same pattern  
- **IMPL-057** (M, overload helpers): same pattern (with HALTED enable matrix nuance)
- **IMPL-058** (S, HALTED-aware enable matrix wiring): same pattern
- **IMPL-066** (S, Journal write latency): `**S-AC**: [200 events sampled; report committed]`
- **IMPL-067** (M, DST regression): `**S-AC**: [10 transitions tested; report committed]`
- **IMPL-068** (S, Force-clear validation): `**S-AC**: [report committed; ADR-008 amended if threshold tuned]`

**Why this matters:**
1. **Inconsistency in same plan artifact:** P3 21 slots (round-01 standardized) + P4 8 verification cluster (IMPL-061..065 + IMPL-017 + IMPL-059 + IMPL-060) ทั้งหมด full-bullet style. Only P4 IMPL-053..058 + IMPL-066..068 = bracket-condensed. Engineer/reviewer reading P4 phase encounters mixed format → cognitive friction during PR review (especially when scoring AC coverage).
2. **Code Review Dimension #4 (AC parsing):** reviewer's structural-review checklist parses S-AC bullets line-by-line; bracket-condensed syntax requires expansion in head before scoring. Same defect class as round-01 Claim 01.5, lower volume (9 vs 21 tasks) and lower individual stakes (IMPL-053..058 = single-method services with simpler ACs than 21 slot business logic).
3. **`/impl-review` Dim #5 + Dim #11 scoring:** depends on counting structurally-distinct AC bullets — bracket shorthand collapses 1 logical AC into 1 line regardless of how many sub-conditions it asserts (e.g. IMPL-053 S-AC asserts 2 conditions: method implemented AND threshold gate; IMPL-057 asserts 2: 3 helpers AND HALTED-aware). Standardization would bump count + reveal hidden multi-assertion sub-clauses.
4. **Lower urgency than 01.5 was:** P4 cross-slot tasks ทำหลังจาก P3 done; engineer มี momentum + reviewer pattern จาก round-01 P3 slot reviews already in head when P4 lands. Cost of mismatch ≈ 1 PR-cycle clarification per task; total surface ~9 tasks. Manageable but un-elegant.

**Minimum acceptable fix:**

เลือกทางใดทางหนึ่ง:

(a) **Standardize 9 P4 tasks to full-bullet style** following the round-01 Claim 01.5 pattern. Recommended phrasing baseline:

For IMPL-053 (analog for 054/055/056/057/058):
```markdown
- **S-AC**:
  - [ ] Method `RunSafePort()` implemented per BR-8.1 / FR-7.1
  - [ ] Threshold gate: avg badPIP > 55 AND currentProfit > 0 (CodeWiki §5.5 baseline)
  - [ ] Compile clean
- **E-AC**:
  - [ ] Smoke: 10 slots fixture with avg badPIP=60 + profit > 0 → SafePort closes them en masse `[log-assertion]` + `[db-inspect]`
```

For IMPL-066 (analog for 067/068):
```markdown
- **S-AC**:
  - [ ] ≥ 200 journal events sampled with `GetMicrosecondCount()` instrumentation
  - [ ] Report at `docs/state/nfr-2.2-journal-latency.md` committed
- **E-AC**:
  - [ ] Journal write avg + p95 ≤ 5 ms `[log-assertion]`
  - [ ] No `[ev=journal_halt][reason=write_fail_sustained]` events `[db-inspect]`
```

(b) **Add 1-line legend at top of P4 section** disambiguating bracket-condensed shorthand: *"Bracket shorthand `[X; Y; Z]` = sequential conjunction asserts X AND Y AND Z; reviewer expand for scoring."* (lighter touch — preserves current text).

แนะนำ (a) เพราะ paritry กับ P3 round-01 fix + future-proofs `/impl-review` scoring. Round-02 may bundle this with Claim 02.1 fix in a single fast rebuttal pass.

**Effort:** Low (~10 min — 9 task AC blocks edit, ~1 min each)

---

#### Claim 02.3: 🔵 LOW — P3 Phase Gate Tier 1.5 row "(×21 brief runs OR 1 full 5-yr run)" alternative still present after Claim 01.1 fix chose option (a)

**Location:** `docs/state/impl-plan.md` § P3 — 21 Slots + CSlotBase + Inputs § Phase Gate § Tier 1.5 Exploratory Walk row (line 767)

**Problem:**
Round-01 Claim 01.1 surfaced ambiguity in P3 Tier 1.5 row:
> *"30-min headless walk via per-slot smoke ini files `simulation/headless-tests/slot_<X>_smoke.ini` (×21 brief runs OR 1 full 5-yr run with all slots active)"*

The reviewer offered 2 options to fix: **(a)** add S-AC bullet to all 21 slot tasks committing per-slot smoke ini files, OR **(b)** reword the row to drop the OR-alternative + reference a single 5-yr regression ini. Defender chose option **(a)** + explicitly noted: *"Phase Gate Tier 1.5 row text unchanged (now correctly references files that will exist by Phase Gate close time)."* (rebuttal-round-01.md Claim 01.1 § Cascaded).

The fix is technically sound (21 ini files will exist post-21 slot tasks), **but** the row text retains the OR-alternative — making it now read as "engineer can still skip the per-slot runs and substitute 1 full 5-yr run" which silently weakens the per-slot S-AC bullet's intent (which said "commit ... per TD-02 §13.6 PR contract"). Per-slot ini files have stronger per-slot debug-replay value (regression isolation per slot) than 1 full 5-yr run; partial-compliance reading invites engineer to skip the per-slot walk and only run the bundled 5-yr.

**Why this matters:**
1. **Tier 1.5 walk artifact quality** depends on operator (engineer/agent) actually exercising the per-slot path. The OR-clause says they don't have to — just one 5-yr full run suffices. This degrades the regression-debug-isolation value the per-slot ini files are meant to provide.
2. **Engineer reading Phase Gate row alone** (without cross-referencing the 21 slot S-AC bullets at IMPL-019..039) sees the OR + concludes 1 full 5-yr run is enough → Tier 1.5 walk artifact has reduced fidelity (no per-slot trade-distribution verification per slot before bundling).
3. **`/impl-review` Dim #5 scoring** parses Phase Gate row text directly; OR-alternative makes the row's exit criterion ambiguous (is 1 full 5-yr enough? Or must each per-slot run be exercised?).
4. **Self-contradiction within fix:** rebuttal-01 added 21 S-AC bullets forcing per-slot ini commit — the Phase Gate row OR-alternative undermines that commitment.

**Minimum acceptable fix:**

Replace line 767 from:
```markdown
- [ ] **Tier 1.5 Exploratory Walk:** 30-min headless walk via per-slot smoke ini files `simulation/headless-tests/slot_<X>_smoke.ini` (×21 brief runs OR 1 full 5-yr run with all slots active) — verify (1) per-slot trade count distribution roughly aligns with baseline ...
```

To:
```markdown
- [ ] **Tier 1.5 Exploratory Walk:** 30-min headless walk via per-slot smoke ini files `simulation/headless-tests/slot_<X>_smoke.ini` (×21 brief runs — committed per IMPL-019..039 S-AC) — verify (1) per-slot trade count distribution roughly aligns with baseline ...
```

OR (if the defender wants to retain optionality):

```markdown
- [ ] **Tier 1.5 Exploratory Walk:** 30-min headless walk via per-slot smoke ini files `simulation/headless-tests/slot_<X>_smoke.ini` (×21 brief runs — committed per IMPL-019..039 S-AC; **a single 5-yr aggregate run is acceptable supplement but not substitute** for per-slot runs) — verify (1) ...
```

แนะนำ first form (drop OR cleanly) — preserves single Phase Gate exit criterion + locks the per-slot debug-replay tool's role.

**Effort:** Low (1-line edit)

---

## Cross-Document Issues

ไม่พบ contradictions:

- All 7 round-01 claim fixes verified landed (TL;DR rename ✅; Phasing Rationale % targets table ✅; IMPL-049 decomposition hint ✅; 21 P3 slots full-bullet style + smoke ini PR contract bullet ×21 = grep `commit \`simulation/headless-tests/slot_` returns **21 hits** ✅; P4 Phase Gate Live-stack health generic + NFR check 10 sub-bullets split ✅; Scope Tags Glossary footer at lines 1610-1623 ✅).
- `overview.md § Impl Plan` row appended with rebuttal-01 closure note: tally "67/68 ✅ + 1/68 ⚠️" preserved; verdict "✅ Ready for Implementation Execution"; first-cut + rebuttal both narrated.
- `deferred-ac-registry.md` + `operator-action-registry.md` both still empty per Phase 1 baseline (no cascaded effect from rebuttal-01).
- Task IDs IMPL-001..IMPL-068 ✅ stable; ADR citations ADR-002/003/004/005/006/007/008/009/010/011/012 stable; 4 api-spec references stable; 4 `.claude/rules/*.md` references stable; SD-07/08 references stable.
- The "out-of-rebuttal-scope follow-up" flagged in rebuttal-01 Claim 01.3 (propagate scope-tag glossary to `CLAUDE.md §3` + `.claude/rules/ea.md` + `.claude/stack.json` via `/amend td`) is **not** re-raised here — it's already documented as recommended hardening in the plan's Scope Tags Glossary section (line 1612: *"Recommended hardening: propagate to CLAUDE.md §3 + ..."*). Surfacing again would double-cite a known follow-up.

**One internal divergence inside `impl-plan.md`** (raised as Claim 02.1): TL;DR `last action` + Mid-Phase Audit Log not updated to reflect rebuttal-01 closure, while the same artifact's `overview.md` row WAS updated. The discrepancy is between primary-SoT layer (impl-plan.md) and derived-view layer (overview.md) — primary-SoT is incomplete, which inverts the State Reconciliation Discipline order.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 02.1 | 🟡 MEDIUM | State Reconciliation incomplete post-rebuttal-01 (TL;DR `last action` stale + Mid-Phase Audit Log missing rebuttal closure row) | `impl-plan.md` line 9 + lines 1509-1515 | Low |
| 02.2 | 🔵 LOW | P4 cross-slot + QA tasks (IMPL-053..058 + IMPL-066..068) still use bracket-condensed S-AC/E-AC; round-01 standardized only 21 P3 slots — broader pattern flagged | `impl-plan.md` § P4 (9 of 17 tasks) | Low |
| 02.3 | 🔵 LOW | P3 Phase Gate Tier 1.5 row "(×21 brief runs OR 1 full 5-yr run)" alternative still present after Claim 01.1 fix chose option (a) | `impl-plan.md` § P3 Phase Gate § Tier 1.5 (line 767) | Low |

---

## Reviewer's Closing Note

Round-01 cleanup landed cleanly — **7/7 Accept** ของ defender ทำงานตรง ack: forbidden closure pattern grep ยัง 0 hits, forward-reference walk ยัง 0 edges, Silent Copy still untriggered, registries still empty, 4-file state reconciliation **almost** clean. ที่ "almost" — defender propagated rebuttal closure ลง `overview.md § Impl Plan` row ครบ แต่ **forgot to propagate inside `impl-plan.md` itself** ที่ TL;DR `last action` + Mid-Phase Audit Log. นี่คือ State Reconciliation Discipline gap ระดับ MEDIUM ที่ inverts the propagation order (derived view updated; primary SoT incomplete).

3 findings สำหรับ round 02:

- ✅ **Claim 02.1 🟡 MEDIUM** — fix internal staleness ใน `impl-plan.md` (line 9 TL;DR + Mid-Phase Audit Log) ก่อน `/impl-task IMPL-001` start. ~30 sec.
- ✅ **Claim 02.2 🔵 LOW** — broaden round-01 Claim 01.5 pattern to P4 IMPL-053..058 + IMPL-066..068 (9 tasks bracket-condensed AC). Defer-able แต่ ~10 min effort closes the parity gap.
- ✅ **Claim 02.3 🔵 LOW** — close OR-clause loose-end ใน P3 Phase Gate Tier 1.5 row that round-01 Claim 01.1 fix didn't touch (defender chose option (a) without rewording the row text). ~1 min.

**Verdict: ✅ Ready for Implementation Execution** — none of the 3 block engineer; recommend optional 5-10 min `/impl-plan-rebuttal claim-review-02.md` to land 02.1 (state hygiene critical for `/next` accuracy from day 1) + 02.3 (low effort + closes round-01 loose-end). 02.2 lower priority — engineer can apply mid-phase audit log entry when P4 starts if desired.

**Engineer next action (after optional rebuttal pass):** `/impl-task IMPL-001` (XS [ea] — folder structure scaffold + `bootstrap_smoke.ini` stub).

— Implementation Plan Reviewer (Adversarial Tech Lead)
2026-05-02
