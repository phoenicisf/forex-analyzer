# Implementation Plan Claim Review Round 12

| Field | Value |
|-------|-------|
| **Round** | 12 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-13 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R11 (2026-05-13 earlier today) — 7/7 Accept; BT-001 Step 3 impl-plan cascade drain |
| **Trigger** | Mid-cascade audit pair to R11 within same calendar day — `/impl-plan-review all` invoked after R11 rebuttal commit to surface defects introduced by R11's own ~19-surface bulk re-annotation pass |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL 2 / 🟠 HIGH 2 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (regex `deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **0 real hits** ✅. Note: literal `deferred per .* precedent` regex matches **1 line** (line 21 in 11 `## Plan Staleness Sentinel` Counter-Convention boilerplate occurrences — `... ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent`); identified as same false-positive class noted by R11 pre-scan (sanctioned boilerplate, greedy `.*` spans innocuous "per workflow.md Gate #4 + fix-round-10 precedent"). R11 rebuttal-round-11 wording carries forward unchanged.
- **Forward refs (P_n → P_m, m>n):** 0 edges ✅. Dependency edges sampled (IMPL-FIX-011a P3 deps on parent IMPL-FIX-011 P4: per R09 §09.5 rule = parent-tracks-paired-bundle-only, sub-tickets independent → not a forward ref); IMPL-062/063 P4 deps on IMPL-060/061 ✅ P4-P4 backward; IMPL-FIX-003 Phase 1B P4 deps closed.
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013 P4→P3 documented diverge), V=0, N=0. Detector **NOT triggered** ✅ (D ≥ 1 + line 2260 explicit confirmation note `"Audit trail self-validates as genuine independent evaluation, not silent copy"`).
- **State reconciliation (4-way):** 🔴 **1 fundamental upstream-vs-plan desync** (BT-001 in `backtrack-log.md § BT-001` STILL `Status: 🔄 Open` + `Resolution: _(pending — operator runs new session for /amend ba or direct edits to NFR-1.1 + NFR-1.8; followed by /sd-review all + /impl-plan-review all to re-validate downstream)_` as of last commit — yet R11 authored ~19 surface annotations across impl-plan claiming `✅ RESOLVED 2026-05-12 via BT-001`; per CLAUDE.md State SoT contract, `backtrack-log.md` is the **primary SoT for backtrack lifecycle**; impl-plan annotations contradict it) + 🟠 **1 task-block S-AC structural inconsistency** (IMPL-062 S-AC #1 + #2 un-`[x]` by R11; IMPL-063 S-AC #1 + #2 + #3 **still `[x]`** despite BT-001 demoting IMPL-063 to informational delta with completely different measurement contract — same vocabulary-invalidation logic R11 §11.1 applied to IMPL-062 was NOT propagated symmetrically) + 🟠 **1 P4 Phase Status row Notes column drift** (line 112 P4 row Notes paragraph still narrates the PRE-BT-001 "PIVOT to contract re-baseline" + "Numeric-drain residue ... all downstream of contract re-baseline outcome" framing that R11 just resolved on every other surface — Phase 5 mechanical Gate #7 missed at task-block-adjacent layer) + 🟡 **2 ancillary** (deferred-ac-registry IMPL-062 row expiry 2026-05-19 unchanged + IMPL-062 task block § Closed line 1988 still says `2/2 E-AC deferred paired bundle gated on operator 5-yr run` while E-AC #1 wording rewritten / paired bundle now expiry-uncertain post-BT-001).

### Top 3 to Fix First

1. **Claim 12.1** 🔴 — BT-001 `backtrack-log.md § BT-001` Status STILL `🔄 Open` + Resolution `(pending)`; R11 authored 19 "✅ RESOLVED 2026-05-12 via BT-001" annotations on impl-plan presuming closure that never happened in the primary SoT — `docs/state/backtrack-log.md` L29-31 vs `impl-plan.md` ~19 surface sites (line 122, 171, 1401, 1406, 1643, 1818, 1819, 1820, 1821, 1970, 1974, 1975, 1977, 1978, 1979, 1981, 1986, 2007? IMPL-063 ROW STILL `[x]`)
2. **Claim 12.2** 🔴 — IMPL-063 task block S-AC #1 + #2 + #3 ALL still `[x]` 2026-05-10 closure under pre-BT-001 framing; R11 §11.6 only changed title + Description + Risk + Input citation, but the **3 closed `[x]` S-ACs** remain — exact same `[x]`-locks-banned-contract defect class as R11 §11.1 caught on IMPL-062, missed symmetrically here — `impl-plan.md` L1997/1998/1999
3. **Claim 12.3** 🟠 — Phase Status Snapshot P4 row Notes column (L112) still narrates `"2026-05-12 PIVOT (R10 §10.2): ... contract re-baseline via /backtrack ba ... all downstream of contract re-baseline outcome"`; R11 explicitly resolved this framing on Open Risks R-3 + Next Best Action + Phase Gate Empirical Demo + NFR-1.1 check + IMPL-FIX-011 footnote + IMPL-062 Status but missed the Phase Status row Notes — Phase 5 Gate #7 (Phase Status Notes sweep) gap at intra-rebuttal layer

### Verdict

- [ ] ✅ **Ready for Implementation Execution**
- [x] ⚠️ **Needs Rebuttal Round** — 2 CRITICAL block (a) backtrack-log SoT vs impl-plan annotation contradiction (must either close BT-001 in primary SoT OR revert R11 annotations to a non-presumptive form e.g., "cascade landed in BA+SD, pending BT-001 closure step 5"); (b) IMPL-063 S-AC `[x]` symmetry gap. Run `/impl-plan-rebuttal claim-review-12.md`.
- [ ] ⛔ **Immediate Attention**

> Rebuttal scope: **mixed AC content + upstream-state-reconciliation** — IMPL-063 S-AC un-`[x]` + symmetric audit-trail annotation (mirror R11 §11.1 surgery); cross-state reconciliation between `backtrack-log.md` Status and impl-plan annotations (either rebuttal triggers BT-001 close in backtrack-log via Cascaded Changes, OR softens annotation language). Higher cost than R10 (prose-only) and similar to R11 (BA-as-Master cascade), but at the **backtrack-lifecycle layer** (5th regression-class axis: defect → fix scope → rule application → rule mechanism → upstream-lifecycle-state).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Unchanged since R01–R11; rationale + Phase % targets ครบ; no BT-001 phase-shape impact |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean (H=68, A=67, D=1, line 2260 explicit confirmation note); SD Round 06 verify-only confirmed `08 § 1.10` line 129 single-pass methodology landed |
| 3 | Task Decomposition & Sizing | ⚠️ Finding 12.4 | IMPL-062 task-block § Closed paragraph L1988 still narrates `2/2 E-AC deferred paired bundle gated on operator 5-yr run` while E-AC #1 wording was rewritten + paired-bundle expiry uncertain post-BT-001 |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 12.2 | IMPL-063 3× S-AC `[x]` lock in pre-BT-001 contract; symmetric to R11 §11.1 IMPL-062 fix not propagated |
| 5 | Phase Gates — Testable Exit | ✅ Pass | P4 Phase Gate rows correctly updated by R11 §11.2 (Empirical Demo + NFR-1.1 check); Tier 1.5 Exploratory Walk row + Rollback Plan row preserved |
| 6 | Deferred-AC Registry Init | ⚠️ Finding 12.5 | Registry IMPL-062 row P4 expiry 2026-05-19 (line ~71) unchanged post-BT-001; expiry inherited from pre-BT-001 `regression_5yr_no_g4.ini` paired-bundle assumption; should at minimum acknowledge BT-001 measurement-contract change in registry row deferred-reason text |
| 7 | Cross-Phase Dependency | ✅ Pass | No forward refs; sub-ticket↔parent dependency convention (per R09) preserved |
| 8 | State-File Consistency | ⚠️ Findings 12.1 + 12.3 + 12.6 | backtrack-log Status vs 19-surface annotation contradiction (CRITICAL 12.1); P4 row Notes column stale (HIGH 12.3); current_handoff.md cascade-chain Step 5 still ⏳ Pending in conflict with R11 annotation premise (MEDIUM 12.6) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4 schedule leakage; "Q1 2021" + "2021-2025" = test data windows; "2026-05-12/13" + registry expiries = working-paper dates (allowed) |
| 10 | Readability — Reader Empathy | ✅ Pass | TL;DR top R11 §11.7 BT-001 update annotation correctly resolves reader-skim concern; Closure Hygiene Status block (R10 §10.6) absorbs Sentinel boilerplate; no new readability finding this round |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 12.1: 🔴 CRITICAL — BT-001 `backtrack-log.md § BT-001` Status STILL `🔄 Open` + Resolution `(pending)` as of 2026-05-13; R11 authored ~19 "✅ RESOLVED 2026-05-12 via BT-001" annotations on impl-plan that contradict the primary backtrack-lifecycle SoT

**Location:**
- `docs/state/backtrack-log.md` § BT-001 L29: `"**Status:** 🔄 Open"` + L31: `"**Resolution:** _(pending — operator runs new session for /amend ba or direct edits to NFR-1.1 + NFR-1.8; followed by /sd-review all + /impl-plan-review all to re-validate downstream)_"`
- `docs/state/current_handoff.md` § BT-001 cascade chain status table L42: `"5. Close BT-001 (populate Resolution + flip Status; trim overview BT-001 markers per Check 0.7 Direction A) | ⏳ Pending Steps 3+4"`
- vs `docs/state/impl-plan.md` ~19 surface sites carrying R11 annotation `"✅ RESOLVED 2026-05-12 via BT-001 (R11 §11.2)"` or equivalent: L7 TL;DR (R11 §11.7 update); L122 Open Risks R-3 strike + pivot; L171 Next Best Action top item; L1401 P4 Phase Gate Empirical Demo; L1406 NFR-1.1 check; L1643 IMPL-FIX-003 Phase 1B Closure paragraph; L1818/1819/1820/1821 IMPL-FIX-011 parent 4× E-AC footnote; L1970/1974/1975/1977/1978/1979/1981/1986 IMPL-062 task block (title + Description + Input + un-`[x]` strikethroughs + new `[ ]` re-author + E-AC rewrite + Status); L1990/1993/1994/1995 IMPL-063 task block (title + Description + Input + Risk).

**Problem:**
Per CLAUDE.md § Glossary `State Single Source of Truth (State SoT)`: `impl-plan.md` is SoT for **task list / phase / Phase Gate / SD Hint Alignment / Mid-Phase Audit Log**; `deferred-ac-registry.md` is SoT for **deferred E-AC**. By identical logic + workflow contract (per backtrack methodology `backtrack-log.md` header `"บันทึกการย้อน phase — append-only"`), `backtrack-log.md` is the **primary SoT for backtrack lifecycle status** (Open / Resolved). `impl-plan.md` annotations referencing BT-NNN are **derived views**.

R11 rebuttal-round-11 authored 19 surface annotations claiming `✅ RESOLVED 2026-05-12 via BT-001 (BA Round 05 + SD Round 06 closed 2026-05-13)`. But:

1. **BT-001 Status field literal value: `🔄 Open`** (last edit unchanged from 2026-05-12 initial entry).
2. **BT-001 Resolution field literal value: `_(pending — ... /sd-review all + /impl-plan-review all to re-validate downstream)_`** — i.e., per backtrack-log's own narrative, the closure-trigger sequence requires (a) operator `/amend ba`, (b) `/sd-review all`, (c) `/impl-plan-review all` to all complete + Step 5 ("Close BT-001 + trim overview markers") executed.
3. **`current_handoff.md` § BT-001 cascade chain status table L42 explicitly tracks Step 5 = ⏳ Pending Steps 3+4** — Step 3 = THIS impl-plan-review chain (in flight; R11 closed + R12 now opening); Step 4 = optional parallel `/td-review all`; Step 5 = BT-001 close + overview marker trim, executed AFTER Steps 3+4 pass clean.

So R11's annotation premise that "BT-001 ✅ RESOLVED" is **structurally wrong** by current_handoff.md's own cascade-chain narrative: Steps 1+2 (BA + SD) closed, but Step 5 (the actual BT-001 closure operation) explicitly hasn't run. The BA + SD cascade-edit landing ≠ BT-001 closure event; those are 2 distinct lifecycle moments. R11 conflated them by reading `current_handoff.md § Last completed action` which said "SD Round 06 closed 2026-05-13" + assuming the BT-001 closure had landed too — but `current_handoff.md` L42 table directly contradicts that read.

**Why this matters:**

1. **Backtrack lifecycle audit trail** (per CLAUDE.md §6 + State Reconciliation Discipline): `backtrack-log.md` is the canonical audit destination for `/backtrack` events. An impl-plan that says `"✅ RESOLVED 2026-05-12 via BT-001"` in 19 places while the backtrack-log says `🔄 Open + Resolution pending` is **the inverse of state-reconciliation** — a downstream derived view asserting a closure that the primary SoT doesn't carry. Status agents + `/next` orchestrators reading the backtrack-log will see Open; reading impl-plan will see Resolved. Race condition between two SoT-claimants at the lifecycle-event layer.

2. **R10 → R11 → R12 recurrence chain**: R10 wrote "BLOCKED on `/backtrack ba` pending" on 5 sites (R10 §10.4); R11 caught R10's stale framing because BT-001 had been **opened** + cascade started but R10 read "Phase Status snapshot" not "backtrack-log" (R11 §11.2 narrative explicitly says R10 missed checking `backtrack-log.md § BT-001` + `BA Last updated` stamps). R11 fixed the staleness by re-annotating to "✅ RESOLVED via BT-001" — but **R11 made the symmetric inverse error**: R11 read `current_handoff.md § Last completed action` (which said SD Round 06 closed) + assumed BT-001 closure event had also occurred, but didn't grep `backtrack-log.md § BT-001 Status` field literal value. The mechanism-improvement Gate #12 R11 §11.2 recommended ("Upstream BA/SD Last-updated check before authoring BLOCKED annotation") is necessary but insufficient — engineer must ALSO check the `backtrack-log.md` Status field, not just upstream artifact Last-updated.

3. **Downstream consumer harm**: Engineer dispatching `/impl-task IMPL-062` reads task-block Status `"✅ READY TO RE-EXECUTE"` + Description `"BT-001 re-baseline 2026-05-12"` + Input `"BT-001 re-baseline — rewrite-G4-ON vs baseline"` and proceeds. But the BT-001 Resolution narrative in primary SoT is **explicitly pending** — the closure operation has not happened. If operator runs `/next` later, `/next` reads backtrack-log → sees BT-001 Open → recommends "close BT-001 via Step 5" — but impl-plan annotations claim it's already closed. Operator gets contradictory instructions from two state docs.

**Minimum acceptable fix:**
Two acceptable resolution paths — operator-side decision (not engineer-side):

**Path A — close BT-001 in primary SoT (recommended, since R11+R12 ARE the Step 3 cascade-validation events the backtrack-log Resolution narrative awaits):**
1. R12 rebuttal Cascaded Changes: edit `docs/state/backtrack-log.md § BT-001`:
   - Flip Status `🔄 Open` → `✅ Resolved 2026-05-13`
   - Populate Resolution: `"BT-001 cascade closed in 5 steps: (1) BA Rebuttal Round 04 + Round 05 verify-only ✅ 2026-05-12 (0 finding); (2) SD Rebuttal Round 04 + Round 06 verify-only ✅ 2026-05-13 (0 finding); (3) Impl Plan Review Round 11 + Rebuttal 11 ✅ 2026-05-13 (7/7 Accept, BT-001 cascade drained across 19 surfaces of impl-plan.md); (4) TD verify (deferred — TD `02 § 13` Strategy Tester audit contract was already single-pass G4-ON per grep clean SD Round 06 finding); (5) Closure operation ran in R12 Cascaded Changes. Forensic toggle decision: keep DISABLE_G4_FIXES slot guards as forensic toggle per task-block IMPL-062 S-AC #1 (decide at IMPL-FIX-NNN follow-up). Resolution direction = rewrite-G4-ON vs baseline single-pass for NFR-1.1; informational delta for NFR-1.8 (Must→Should demotion)."`
2. Trim overview BT-001 markers per Check 0.7 Direction A (overview.md row update).
3. update current_handoff.md § BT-001 cascade chain Steps 3+5 → ✅ Closed.

**Path B — soften impl-plan annotations to "cascade landed, BT-001 closure pending Step 5":**
1. R12 rebuttal: bulk find-replace `"✅ RESOLVED 2026-05-12 via BT-001"` → `"📝 BT-001 cascade landed 2026-05-12 (BA Round 05 + SD Round 06 closed); BT-001 lifecycle Status pending Step 5 closure per backtrack-log.md § BT-001"` across all 19 sites.
2. No change to backtrack-log.md.

Either path closes the contradiction. Path A is preferred because R11+R12 ARE the Step 3 cascade-validation events; staying in Path B leaves the closure operation orphaned forever (no later trigger to revive it). R12 reviewer recommends Path A.

**Effort:** Low (Path A = 1 backtrack-log edit + 1 overview edit + 1 handoff edit; Path B = 19 find-replace across impl-plan + no upstream edits). Either ≤ 20 LOC across 1-3 files.

---

#### Claim 12.2: 🔴 CRITICAL — IMPL-063 task block S-AC #1 + #2 + #3 ALL still `[x]` closed 2026-05-10 under pre-BT-001 framing; R11 §11.6 only changed title + Description + Risk + Input citation, leaving the 3 closed S-ACs untouched; same `[x]`-locks-banned-contract defect class as R11 §11.1 caught on IMPL-062 — applied asymmetrically

**Location:**
- `docs/state/impl-plan.md` IMPL-063 task block § S-AC L1997-1999:
  - L1997: `"- [x] Rewrite EA built with DISABLE_G4_FIXES flag OFF (default) — STRUCTURAL: grep -c '...' returns 0 (committed default = G4 fixes ON; mainline includes IMPL-022 J-Magic + IMPL-039 BI-SL fixes verbatim). G1 PASS Result: 0 errors, 0 warnings, 4199 ms elapsed."`
  - L1998: `"- [x] 5-yr backtest via simulation/headless-tests/regression_5yr_g4.ini — STRUCTURAL: standard [Tester] block per TD-02 §13.3 (...) + operator runbook documenting paired-bundle execution with IMPL-062 (regression_5yr_no_g4.ini)."`
  - L1999: `"- [x] regression-bucket-b.md reports: Bucket B drift = (with-G4 result) − (without-G4 result IMPL-062); per-slot impact of J + BI fixes — STRUCTURAL: 8-section report skeleton (...)"`

**Problem:**
R11 §11.6 (rebuttal verdict Accept) renamed IMPL-063 to `"Measure Bucket B informational delta rewrite-G4-ON − rewrite-G4-OFF (NFR-1.8 BT-001 informational; no acceptance gate)"` + downgraded Risk Must→Should + updated Input citation. But the **3 closed-`[x]` S-AC bodies still describe the PRE-BT-001 contract**:

- **L1998 S-AC #2 `[x]`** declares Bucket B 5-yr backtest committed at `regression_5yr_g4.ini` paired-bundle with `regression_5yr_no_g4.ini` (IMPL-062). But per BT-001 + R11 §11.1 fix, IMPL-062's `regression_5yr_no_g4.ini` was **repurposed as the informational Bucket B `rewrite-G4-OFF` leg of THIS task (IMPL-063)** — i.e., IMPL-063's S-AC #2 should now reference both `regression_5yr_g4.ini` (G4-ON leg) AND `regression_5yr_no_g4.ini` (G4-OFF leg, taking over IMPL-062's old role). Current S-AC #2 narrates a paired bundle WITH IMPL-062 — but post-BT-001 IMPL-062 is no longer a Bucket B leg (it's the rewrite-G4-ON Bucket A single-pass). The S-AC text describes a measurement topology that doesn't exist post-BT-001.

- **L1999 S-AC #3 `[x]`** narrates `regression-bucket-b.md reports: Bucket B drift = (with-G4 result) − (without-G4 result IMPL-062)` — i.e., the **pre-BT-001 binary-acceptance-gate framing** that BA `03 § NFR-1.8` redefined as `Net Profit (rewrite-G4-ON) − Net Profit (rewrite-G4-OFF) sign + magnitude only; no pass/fail threshold`. The S-AC computation formula in plan text describes the obsolete contract.

- **L1997 S-AC #1 `[x]`** is structurally compatible with post-BT-001 framing (default build = G4-ON) but R11 §11.6 Changes note explicitly says `"S-AC text left unchanged (still describes G4-OFF build prerequisite for delta computation; BT-001 acknowledges partial measurement window per IMPL-062 Run #2 finding — annotation embedded in Description)"` — i.e., R11 chose to leave the `[x]` AC text + put the BT-001 caveat in Description. Same forbidden-pattern *spirit* as R11 §11.1 (`[x]` semantic = "closed against correct contract"; closed-`[x]` AC describing G4-OFF prerequisite under a Description that says "BT-001 makes this only partially measurable" is the same banned-contract structural-invalid-closure class).

**Same defect class as R11 §11.1** (S-AC `[x]` locks in measurement contract banned by BA post-BT-001): R11 surgically un-`[x]`'d IMPL-062 S-AC #1 + #2 with `~~strikethrough~~` audit-trail + new `[ ]` re-author + un-strikethrough new `[ ]` re-author. The **symmetric treatment** of IMPL-063 was NOT applied. R11 §11.6 Changes paragraph explicitly cited S-AC text being left unchanged as a deliberate choice — but that choice replicates the exact forbidden-pattern class R11 §11.1 fix went out of its way to repair on IMPL-062.

**Why this matters:**

1. **Engineer dispatching `/impl-task IMPL-063` reads task block top-down**: sees title (post-BT-001 informational delta) + Description (BT-001 redefined) + S-AC L1998 `[x]` (paired bundle with IMPL-062 — IMPL-062 description says default-build single-pass). CONFLICT: IMPL-063's S-AC #2 says "paired with IMPL-062 `regression_5yr_no_g4.ini`", but IMPL-062 (R11 §11.1) explicitly says `regression_5yr_no_g4.ini` is now repurposed as the IMPL-063 G4-OFF leg. The two task blocks point at each other circularly with no canonical authority.

2. **S-AC `[x]` semantic class** identical to R11 §11.1 finding (CLAUDE.md § Glossary "Empirical Closure Discipline" + Code Review Dim #11): closed-`[x]` AC must reflect "closed against correct contract." All 3 IMPL-063 S-ACs were closed 2026-05-10 against the pre-BT-001 Bucket B = "rewrite-G4-ON vs baseline" contract; BT-001 redefined Bucket B = informational delta `rewrite-G4-ON − rewrite-G4-OFF`. All 3 `[x]`s describe artifacts produced under the obsolete contract.

3. **Asymmetric application of R11 §11.1 logic**: R11 reviewer + defender both applied the un-`[x]` + audit-trail surgery to IMPL-062 (where 2 of 3 S-ACs were affected), but missed IMPL-063 (where 3 of 3 are affected). Same defect axis — the fix-scope's "intent" was wider than the "literal target" — exactly the recurrence pattern Gate #9 clauses (a)/(b)/(c) in `.claude/rules/workflow.md` were authored to prevent at the source-code layer. R11 rebuttal happened at the impl-plan-state layer; the same intent-vs-target trap applied.

**Minimum acceptable fix:**
Mirror R11 §11.1 surgery on IMPL-063 S-AC block:

1. **L1997 S-AC #1**: `[x]` retained, but append annotation `"(2026-05-13 R12 §12.2 post-BT-001 update: G4-OFF clause now describes informational Bucket B leg per BT-001 NFR-1.8 redefinition; partial-window per IMPL-062 Run #2 finding — leg measurable only pre-CircuitBreaker BR-3.6 halt)"`.

2. **L1998 S-AC #2**: un-`[x]` with strikethrough + new `[ ]`:
   - `"- [ ] ~~`[x]` 2026-05-10 (commit `<TBD-batch>`) — invalidated by BT-001 2026-05-12: S-AC text described 5-yr backtest paired-bundle with IMPL-062 `regression_5yr_no_g4.ini` (when IMPL-062 was the Bucket A acceptance gate). Post-BT-001 IMPL-062 is the rewrite-G4-ON Bucket A single-pass; IMPL-063 absorbs `regression_5yr_no_g4.ini` as the G4-OFF informational leg of Bucket B delta. Re-authored below.~~"`
   - `"- [ ] 5-yr backtest via paired-bundle `simulation/headless-tests/regression_5yr_g4.ini` (G4-ON leg) + repurposed `regression_5yr_no_g4.ini` (G4-OFF leg per BT-001 take-over from IMPL-062) — STRUCTURAL: both .ini files standard [Tester] block per TD-02 §13.3 (Symbol=EURUSD, Period=H4, Model=4, Optimization=0, Deposit=1000, Leverage=500, ShutdownTerminal=1, Visual=0, FromDate=2021.01.01, ToDate=2025.12.31); operator runbook documents informational delta computation post-run, no pass/fail threshold per BA 03 § NFR-1.8 BT-001 redefined."`

3. **L1999 S-AC #3**: un-`[x]` with strikethrough + new `[ ]`:
   - `"- [ ] ~~`[x]` 2026-05-10 — `regression-bucket-b.md` reports: Bucket B drift = (with-G4) − (without-G4 IMPL-062) — invalidated by BT-001: computation formula references the pre-BT-001 binary acceptance gate; informational delta has different formula + no threshold.~~"`
   - `"- [ ] `regression-bucket-b.md` reports: **informational delta `Net Profit (rewrite-G4-ON) − Net Profit (rewrite-G4-OFF)`** + sign + magnitude + per-slot impact of J + BI fixes — STRUCTURAL: 8-section report skeleton updated post-BT-001 to drop §5 binary pass criterion (replaced with informational-summary table) + §1/§2/§4 reframed per NFR-1.8 BT-001 redefined; no acceptance gate verbiage."`

4. **L2008 `**Closed**:` field append**: `"R12 §12.2 (2026-05-13): S-AC #2 + #3 un-`[x]`'d per BT-001 symmetry with IMPL-062 (R11 §11.1); 1/3 S-AC `[x]` (decorative L1997 default-build annotation); 3/3 E-AC remain deferred paired bundle gated on operator informational-delta run."`

5. **L1995 Input citation** already cites `"IMPL-062 (Bucket A baseline = rewrite-G4-ON single-pass)"` post-R11; this is correct + needs no change.

**Effort:** Medium (2 S-AC un-`[x]` + strikethrough + re-author + Closed field annotation + audit-trail preservation per State Reconciliation Discipline; ~30-40 LOC); same surgical pattern as R11 §11.1 applied byte-similarly.

---

### 🟠 HIGH

#### Claim 12.3: 🟠 HIGH — Phase Status Snapshot P4 row Notes column (L112) still narrates pre-BT-001 PIVOT framing `"contract re-baseline via /backtrack ba"` + `"all downstream of contract re-baseline outcome"`; R11 fixed 6+ surfaces but missed Phase Status Notes; Phase 5 mechanical Gate #7 gap at intra-rebuttal layer

**Location:** `docs/state/impl-plan.md` § Phase Status Snapshot table L112 (P4 row Notes column, end of paragraph): `"~~Remaining work = operator paired-bundle 5-yr drain~~ **2026-05-12 PIVOT (R10 §10.2):** IMPL-062 Run #1 (2026-05-10 day-1 stop-out) + Run #2 (2026-05-12 Phase 1B build, drift ≈ 99.998%, CircuitBreaker BR-3.6 HALTED) both empirically FAILED; remaining work pivots from **numeric drain** to **contract re-baseline** via /backtrack ba (NFR-1.1 measurement methodology — DISABLE_G4_FIXES contract structurally incompatible with 16-active-slot rewrite under $1k deposit per regression-bucket-a.md § 5). IMPL-062 task block annotated BLOCKED 2026-05-12. Numeric-drain residue (IMPL-063 Bucket B + IMPL-FIX-006/007/008/009 E-AC + IMPL-066 journal latency long-sample + IMPL-068 force-clear validation) all downstream of contract re-baseline outcome"`

**Problem:**
The P4 Notes column paragraph (added by R10 §10.2) carries the pre-BT-001 PIVOT framing word-for-word:
- `"contract re-baseline via /backtrack ba"` — the `/backtrack ba` is now done (BA Round 05 closed 2026-05-12)
- `"IMPL-062 task block annotated BLOCKED 2026-05-12"` — R11 §11.3 explicitly replaced the BLOCKED annotation with `✅ READY TO RE-EXECUTE`
- `"Numeric-drain residue ... all downstream of contract re-baseline outcome"` — outcome is now known (rewrite-G4-ON single-pass methodology); not "downstream of" anymore

R11 §11.2 explicitly listed sites updated with `"✅ RESOLVED via BT-001"`: Open Risks R-3 L122, Next Best Action L171, P4 Phase Gate Empirical Demo L1401, NFR-1.1 check L1406, IMPL-FIX-011 parent 4× footnote L1818-1821, IMPL-062 Status L1986. The **Phase Status Snapshot table** P4 row Notes column L112 was NOT in R11's update list — the same Notes column that Phase 5 mechanical Gate #7 (Phase Status Notes sweep) was added to `workflow.md` specifically to keep current. R10 §10.2 originally drafted this exact paragraph; R11 missed it.

**Why this matters:**

1. **Phase Status Snapshot is the canonical state-of-the-phase reader surface** (per `andm-impl-plan-reviewer/SKILL.md` Phase 1 Dim #10 + `/next` Check 5.6+5.7): operator or status-agent reads this table FIRST to understand each phase's posture. P4 Notes paragraph asserting "contract re-baseline via /backtrack ba" + "BLOCKED 2026-05-12" reads as "/backtrack ba is the next action" — contradicts every other surface R11 already updated.

2. **Same recurrence pattern Gate #7/#8 were authored to prevent** — R08 added Gate #7 (Phase Status Notes sweep) after R08 caught Phase Status frozen at pre-IMPL-057 state. R10 §10.2 then drafted a new Notes paragraph reflecting the 2026-05-12 PIVOT. R11 closed BT-001 cascade across 9 surfaces, but the Phase Status Notes (the very surface Gate #7 enforces) was not in R11's update list — Gate #7 missed at intra-rebuttal-cycle layer. Defect-class recurrence: rule authored → rule applied selectively → next round catches the gap. Identical shape to R11 §11.4 (TL;DR-vs-task-block IMPL-FIX-003 Phase 1B drift caught at next-finer granularity than R10 §10.5 fix).

3. **Reader-skim impact**: Tech Lead / PM scanning Phase Status table sees P4 status `✅ 17/17 [x] structural` + Notes paragraph saying `"BLOCKED ... pivots to contract re-baseline via /backtrack ba"`. Then scrolls to TL;DR which says `"BT-001 closed 2026-05-13 ... Next action = re-execute IMPL-062"`. Two reader paths, two different conclusions. Per CLAUDE.md Readability "stakeholder skim test", this is a fail at the canonical Phase Status surface.

**Minimum acceptable fix:**
L112 P4 Notes column rewrite (append immediately after existing paragraph, OR replace the PIVOT section):

`"~~2026-05-12 PIVOT (R10 §10.2)~~ ✅ **2026-05-13 (R12 §12.3, post-BT-001):** ~~contract re-baseline via /backtrack ba~~ → BT-001 cascade ✅ closed 2026-05-13 (BA Round 05 + SD Round 06 + Impl Plan Rebuttal Round 11 all 0 finding / 7-of-7 Accept; backtrack-log § BT-001 lifecycle Status to be flipped via R12 Cascaded Changes per Claim 12.1). NFR-1.1 redefined = rewrite-G4-ON vs baseline single-pass; NFR-1.8 demoted Must→Should informational delta. **Remaining work (post-BT-001):** operator paired-bundle 5-yr drain on rewrite default build (G4-ON, single-pass) = IMPL-062 Bucket A single-pass + IMPL-063 informational Bucket B (paired G4-ON + G4-OFF) — both unblocked. Numeric-drain residue (IMPL-FIX-006/007/008/009 E-AC + IMPL-066 + IMPL-068) now drains alongside IMPL-062/063 single-pass run, NOT downstream of further `/backtrack` event."`

**Effort:** Low (1 paragraph rewrite, ~10-15 LOC).

---

#### Claim 12.4: 🟠 HIGH — IMPL-062 task block § Closed paragraph (L1988) still narrates pre-BT-001 closure statistics `"3/3 S-AC [x] structural; 2/2 E-AC deferred paired bundle gated on operator 5-yr run"`; R11 un-`[x]`'d 2 of 3 S-AC + rewrote E-AC #1 wording, but Closed-statistics narrative not updated to match

**Location:** `docs/state/impl-plan.md` § IMPL-062 task block L1988: `"**Closed**: 2026-05-05 (commit `277cdb2`, parallel batch via /impl-task parallel Sonnet 4.6 fan-out with IMPL-065) — slots/Slot_J.mqh + slots/Slot_BI.mqh (#ifdef guards) + simulation/headless-tests/regression_5yr_no_g4.ini (NEW; ~50 LOC) + docs/state/regression-bucket-a.md (NEW; ~280 LOC). 3/3 S-AC `[x]` structural; 2/2 E-AC deferred paired bundle gated on operator 5-yr run. P4 Phase Status snapshot 14/17 → 15/17. Cascade: numeric drain unblocks IMPL-068 force-clear validation pipeline + completes NFR-1.1 acceptance signal for MVP delivery."`

**Problem:**
The IMPL-062 task block has 3 S-ACs (L1977/1978/1980) + 2 E-ACs (L1982/1983). After R11 §11.1 surgery:
- L1977 S-AC #1: now `[ ]` un-strikethrough new + `~~[x]~~` strikethrough old
- L1978 S-AC #2: new `[ ]` re-author for default build (no `[x]` mark)
- L1979 S-AC #3 (originally `[x]` for `.ini` committed): now `[ ]` un-strikethrough new + `~~[x]~~` strikethrough old
- L1980 S-AC #4 (originally `[x]` for `regression-bucket-a.md` 8-section report): retained `[x]` (structural skeleton unchanged)

Wait — looking more carefully at the file content (L1977-1980), R11 applied the un-`[x]` to 2 of the 3 originally-`[x]`'d S-ACs (the DISABLE_G4_FIXES build + the `regression_5yr_no_g4.ini` commitment). The 3rd S-AC (regression-bucket-a.md 8-section skeleton at L1980) retained `[x]` correctly (skeleton is contract-agnostic).

But the **Closed paragraph at L1988** still asserts `"3/3 S-AC [x] structural"` — which was true at 2026-05-05 closure but is now false post-R11 (S-AC count is 1 `[x]` + 2 new `[ ]` un-strikethrough + 2 `~~[x]~~` strikethrough audit-trail). Same for `"2/2 E-AC deferred paired bundle"` — E-AC #1 (L1982) was rewritten to add the BT-001 single-pass methodology + Prior Run #1/#2 audit citation; "deferred paired bundle" is technically still accurate but the "paired bundle" semantic differs post-BT-001 (paired with IMPL-063 informational delta, not paired Bucket A vs Bucket B).

Cascade narrative also wrong: `"Cascade: numeric drain unblocks IMPL-068 force-clear validation pipeline + completes NFR-1.1 acceptance signal for MVP delivery"` — describes the pre-BT-001 cascade; post-BT-001 numeric drain produces NFR-1.1 single-pass measurement + IMPL-063 G4-OFF leg simultaneously (different cascade topology).

**Why this matters:**

1. **Engineer reading IMPL-062 § Closed paragraph reads a closure-statistics narrative that doesn't match the current AC checkboxes** — counts `[x]` (gets 1 of 3, not 3 of 3) + reads Closed says "3/3 S-AC `[x]`" → CONFUSION block. Same pattern as R11 §11.4 (IMPL-FIX-003 Phase 1B Closure paragraph TL;DR-drift) at next-finer granularity.

2. **Closed paragraph asserts the task is DONE** but R11 surgery left 2 S-AC at `[ ]` un-strikethrough new = NOT YET CLOSED. Definition of `**Closed**:` field semantic = "task completed at this date with these stats" — post-R11 the task is partially un-closed by the un-`[x]` surgery. Either the Closed field gets a R12 §12.4 annotation indicating partial-re-opening per BT-001, OR the Closed field gets re-dated to track the re-validation event.

3. **State Reconciliation discipline at task-block-internal layer**: `## Phase Status Snapshot` P4 row says `✅ 17/17 [x] structural` (Claim 12.3 fixes the Notes column; the 17/17 count itself includes IMPL-062 as `[x]` structurally closed). With R11 un-`[x]` of 2 S-ACs, IMPL-062 is now `[partial]` structurally — the 17/17 count is arguably incorrect (could be 16.6/17 or "structurally complete with BT-001 re-validation pending"). Phase × Size matrix denominator implications + Mid-Phase Audit Log counter implications need reconciliation. R11 §11.1 Cascaded-changes note says `"no Phase × Size matrix update — no task split / no phase reassignment"` — but un-`[x]` is structurally a "task partially re-opened" event that arguably warrants Phase × Size update (not a phase MOVE, a phase COUNT delta).

**Minimum acceptable fix:**

Append to L1988 immediately after existing Closed paragraph: `"**Re-opened structurally 2026-05-13 (R12 §12.4, post-BT-001):** S-AC #1 + S-AC #2 un-`[x]`'d by R11 §11.1 per BT-001 measurement-contract redefinition; 1/3 S-AC `[x]` remaining (L1980 regression-bucket-a.md 8-section skeleton — contract-agnostic structural report shell); 2/3 S-AC `[ ]` un-strikethrough new (L1977 default-build + L1979 .ini repurpose); 2/2 E-AC remain deferred (L1982 single-pass methodology re-authored; L1983 per-slot deviation paired bundle topology re-framed). Post-BT-001 cascade: numeric drain on default build (G4-ON, single-pass) produces both NFR-1.1 Bucket A measurement + IMPL-063 G4-ON leg of informational Bucket B in one operator session (paired-bundle topology different from pre-BT-001 IMPL-062-vs-IMPL-063-as-separate-buckets framing)."`

OR (alternative — task re-open via re-dating):

`"**Status 2026-05-13 (R12 §12.4):** Original 2026-05-05 closure superseded by R11 §11.1 un-`[x]` surgery per BT-001; task now `[partial]` pending operator default-build single-pass run. Original Closed paragraph preserved as audit history below; new effective Closure date will be set when remaining 2 S-AC + 2 E-AC drain post-operator-run."`

Recommend the append form (less invasive; preserves Closed field semantic; explicit audit trail).

**Effort:** Low (1 paragraph append, ~10 LOC).

---

### 🟡 MEDIUM

#### Claim 12.5: 🟡 MEDIUM — `deferred-ac-registry.md § Active` IMPL-062 row (P4, expiry 2026-05-19) deferred-reason text still narrates `DISABLE_G4_FIXES` build instructions; R11 §11.1 changed the measurement-contract but the registry row deferred-reason text wasn't propagated; same defect class as Claim 12.4 at registry-row layer

**Location:** `docs/state/deferred-ac-registry.md § Active` IMPL-062 row (~line 71 per R10 verify search — present in lines 50+ of registry; reviewer infers from R10 fix narrative + impl-plan E-AC L1982 wording `"registered in deferred-ac-registry.md expiry 2026-05-19 paired bundle"`).

**Problem:**
R11 §11.1 Cascaded-changes note explicitly says `"No deferred-ac-registry.md change — BT-001 = measurement-methodology rewrite + AC text fix, not new deferred E-AC. Existing IMPL-FIX-003 Phase 1B row (R10 §10.5) + IMPL-FIX-011 parent row (R09 §09.7) unaffected."` — and IMPL-062 row was not in R11's update list. But the IMPL-062 row in registry (per R10's narrative + impl-plan E-AC L1982 reference to it) describes deferred-reason ≈ `"build .ex5 with DISABLE_G4_FIXES + run 5-yr regression_5yr_no_g4.ini"` (the pre-BT-001 measurement contract). Post-BT-001 the operator-action is `"build default .ex5 (G4-ON; no DISABLE_G4_FIXES) + run 5-yr regression_5yr_g4.ini single-pass + parse Net Profit vs baseline"`. Registry row deferred-reason text now describes operator action that BA `03 § NFR-1.1 Verification` explicitly bans.

**Why this matters:**

1. **Registry is consumed by `/impl-task IMPL-062` (HALTs on expired entries) + `/deliver` (blocks shipping if non-empty) per CLAUDE.md § Glossary `Deferred-AC Registry`**: engineer at expiry-trigger reads deferred-reason → tries DISABLE_G4_FIXES path → hits BA-side ban (same failure mode as Claim 11.1 source-code-layer defect, recurring at registry-row layer).

2. **Same defect class as Claim 12.4** (task-block Closed paragraph) + Claim 11.1 (task-block S-AC); recurrence at next-finer granularity (registry-row deferred-reason).

3. **MEDIUM not HIGH** because: (a) engineer running `/impl-task IMPL-062` reads task block FIRST (post-R11 task block correctly says rewrite-G4-ON single-pass) + registry row is consulted as deferred-context not as primary instruction; (b) registry row is read mostly by `/deliver` Block check + `/next` Check 5.x — neither has high-urgency consequence vs Claim 12.1/12.2 CRITICAL.

**Minimum acceptable fix:**
Append to deferred-reason text of IMPL-062 registry row: `"**2026-05-13 (R12 §12.5, post-BT-001):** deferred-reason text describes pre-BT-001 DISABLE_G4_FIXES build path which BA 03 § NFR-1.1 Verification now bans. Post-BT-001 operator action = build default .ex5 (G4-ON; no DISABLE_G4_FIXES) + run 5-yr regression_5yr_g4.ini (or new single-pass .ini) + parse Net Profit vs baseline $24.27M. Original deferred-reason preserved for audit history per State Reconciliation Discipline."`

Optionally also reconsider expiry: 2026-05-19 was set when DISABLE_G4_FIXES path was the contract; with BT-001 closure + R11 surgery making the row partially re-opened (Claim 12.4), an expiry extension to 2026-05-26 (paired with IMPL-FIX-003 Phase 1B row R10 §10.5) might better track the new operator-action timeline. Engineer-side decision.

**Effort:** Low (1 registry row deferred-reason append + optional 1 expiry-date edit; ~5-8 LOC).

---

#### Claim 12.6: 🟡 MEDIUM — `current_handoff.md § BT-001 cascade chain status` table Step 3 STILL `⏳ Pending` despite R11 (the Step 3 actual content) having closed; R11 Cascaded-changes claim "Prior action chain to SD Round 06" set Last-completed-action but did NOT flip the cascade-chain Step 3 row from ⏳ to ✅

**Location:** `docs/state/current_handoff.md` § BT-001 cascade chain status table L40-43:
```
| 3. Impl Plan re-validate (`/impl-plan-review all`) | ⏳ Pending — sweeps `impl-plan.md` L1966/L1988 IMPL-062/063 + Phase Hint P4 propagation | — |
| 4. TD verify (`/td-review all`, optional parallel) | ⏳ Pending — verify TD `02 § 13` Strategy Tester audit contract = single-pass G4-ON | — |
| 5. Close BT-001 (populate Resolution + flip Status; trim overview BT-001 markers per Check 0.7 Direction A) | ⏳ Pending Steps 3+4 | `backtrack-log.md` § BT-001 |
```

**Problem:**
R11 rebuttal-round-11.md § Cascaded Changes claims `"docs/state/current_handoff.md — 1 edit block (Last completed action set to R11 + Prior action chain to SD Round 06)"`. Inspecting current_handoff.md: ✅ Last completed action IS set to R11 (L5-7). But the **BT-001 cascade chain status table** (L36-42; a separate section listing the 5 cascade steps with status icons) was NOT updated. Step 3 row still says `⏳ Pending`. Same drift class as R10 §10.5 (TL;DR fix without task-block fix) → R11 §11.4 (task-block fix without registry-row fix) — recurring at next-finer granularity: handoff Last-completed-action updated, but handoff BT-001-cascade-chain-table not updated.

**Why this matters:**

1. **`/next` orchestrator reads cascade-chain table** to determine BT-001 lifecycle position. Table says Step 3 ⏳ Pending → `/next` recommends "run `/impl-plan-review all`" (but R11 just did Step 3 + just closed). Operator gets redundant-action recommendation OR confusion.

2. **Same regression class as Claim 12.1** at the cascade-chain-row layer (12.1 = backtrack-log primary SoT not updated; 12.6 = handoff cascade-chain table at derived-view layer not updated). R12 rebuttal Cascaded Changes will need to fix both surfaces atomically per State Reconciliation Discipline.

3. **MEDIUM not HIGH** because: (a) the contradiction is intra-handoff (handoff Last-completed-action says R11 closed; handoff cascade-chain table says Step 3 pending — same file, easily reconcilable); (b) no impl-plan content depends on this row directly; (c) routes via Cascaded Changes from rebuttal Claim 12.1 fix.

**Minimum acceptable fix:**
R12 rebuttal Cascaded Changes: update current_handoff.md L40-42 cascade-chain table:
- Step 3 status `⏳ Pending` → `✅ Closed 2026-05-13` + artifact column `"impl-plan-claim-review-and-rebuttal/rebuttal-round-11.md (7/7 Accept) + claim-review-12.md / rebuttal-round-12.md verify-only sweep"`.
- Step 4 status: leave `⏳ Pending` UNLESS R12 rebuttal also runs `/td-review all` (out-of-scope for R12 normally, but per BT-001 Resolution narrative Step 4 = optional parallel). Engineer-side decision.
- Step 5 status: if R12 rebuttal Cascaded Changes flips backtrack-log Status (Claim 12.1 Path A) → `✅ Closed 2026-05-13` + artifact column `"backtrack-log.md § BT-001 Resolution populated; overview.md BT-001 markers trimmed"`.

**Effort:** Low (1-2 row edits in current_handoff.md table; ~5 LOC).

---

## Cross-Document Issues

This round catches **1 backtrack-log↔impl-plan + 1 backtrack-log↔current_handoff cross-document contradictions** (the BT-001 closure-event-vs-cascade-landed gap):

| Contradiction | Primary SoT | Derived view (impl-plan / handoff) |
|---------------|-------------|-----|
| BT-001 Status `🔄 Open` + Resolution `(pending)` | `docs/state/backtrack-log.md § BT-001` L29/31 | impl-plan ~19 surface annotations claim `"✅ RESOLVED 2026-05-12 via BT-001"` (Claim 12.1) |
| BT-001 cascade chain Step 3 ⏳ Pending | `docs/state/current_handoff.md § BT-001 cascade chain status` L40 | current_handoff.md L5-7 Last completed action says R11 (which IS Step 3 content) closed (Claim 12.6) |

No new Evolution Sequence violation. No ADR backing gap. No BA↔plan or SD↔plan vocabulary desync surfaced — R11 §11.1/11.6 already drained those at task-block level.

---

## Recurring Weaknesses (rounds 06-11)

1. **State-reconciliation defect-class progression** continues at next-coarser granularity each round:
   - R06/R07: TL;DR↔registry drift (within `impl-plan.md`).
   - R08: Phase Status Notes + Open Risks + Next Best Action (intra-narrative-parallel sections).
   - R09: TL;DR↔diagnostic-artifact drift (one external artifact).
   - R10: TL;DR↔Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh (intra-narrative-parallel batch).
   - R11: upstream-vs-impl-plan (BA `03` + SD `08` Last-updated 2026-05-12 vs impl-plan IMPL-062/063 pre-BT-001 framing) — caught BA-as-Master cascade gap.
   - **R12 (this round)** catches the **upstream-lifecycle-state-vs-derived-view** layer: `backtrack-log.md § BT-001 Status` (primary lifecycle SoT) vs impl-plan 19-surface annotation (derived view). Defect-class progression now at **5th axis** (lifecycle-state-of-an-upstream-event, not just upstream-artifact-content). Same 4-axis structure R20→R23 chain accumulated for source-code-layer (catalog/destination/anchor/exemption-regex); R12 is the equivalent meta-axis at state-doc layer.

2. **R11's own rebuttal introduced 3+ new defects** (Claims 12.1 + 12.3 + 12.4 + 12.6): broke the backtrack-log↔impl-plan SoT contract by asserting closure-events the primary SoT didn't carry; missed Phase Status P4 Notes column in its 6-surface BLOCKED-resolution sweep; left IMPL-062 Closed-paragraph statistics narrative inconsistent with its own un-`[x]` surgery; didn't propagate Last-completed-action update to the BT-001 cascade-chain table in same file. Same shape as R10 introducing R11-class defects (which R11 then caught); R11 introduced R12-class defects (which R12 now catches). Predictable cycle.

3. **Methodology-improvement deferral gap**: R11 §11.2 recommended new `workflow.md` Gate #12 ("Upstream BA/SD Last-updated check before authoring BLOCKED annotation") + R11 §11.5 recommended Gate #13 ("Handoff Last-completed-action durability check"). R11 rebuttal narrative explicitly deferred both to "follow-up workflow.md edit — outside impl-plan-rebuttal scope per andm-impl-plan-defender/SKILL.md". Reviewer-side R12 sweep confirms NEITHER landed in `.claude/rules/workflow.md` (grep `Gate #12|Gate #13|Upstream BA/SD Last-updated|Handoff Last-completed-action durability` returns 0 matches). Result: Gate #12 (which would have prevented R11's own Claim 12.1 BT-001-Status defect) was recommended but never implemented; defect-class recurrence at R12 was structurally inevitable. **Recommended methodology improvement (R12 §12.7 informal, no separate claim):** add Gate #12 + Gate #13 atomically with R12 rebuttal closure, OR file as separate `/update-config` ticket WITH expiry ≤14d to prevent indefinite deferral (deferred-improvements-without-expiry is itself a recurring weakness — per fix-round/methodology-improvement-debt class).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 12.1 | 🔴 CRITICAL | BT-001 backtrack-log Status `🔄 Open` + Resolution `(pending)` vs impl-plan ~19 surface annotations claiming `✅ RESOLVED 2026-05-12 via BT-001` | `backtrack-log.md` L29/31 vs `impl-plan.md` 19 sites (L122/171/1401/1406/1643/1818-1821/1970/1974/1975/1977/1978/1979/1981/1986/1990/1993/1994/1995) | Low (Path A) |
| 12.2 | 🔴 CRITICAL | IMPL-063 S-AC #1+#2+#3 still `[x]` under pre-BT-001 framing; symmetric to R11 §11.1 IMPL-062 fix not propagated | `impl-plan.md` L1997/1998/1999 + L2008 Closed field | Medium |
| 12.3 | 🟠 HIGH | Phase Status Snapshot P4 row Notes column still narrates `"contract re-baseline via /backtrack ba"` PIVOT framing; Gate #7 missed at intra-rebuttal layer | `impl-plan.md` L112 | Low |
| 12.4 | 🟠 HIGH | IMPL-062 § Closed paragraph statistics narrative `"3/3 S-AC [x]"` inconsistent with R11 un-`[x]` surgery; task block partial-re-open not annotated | `impl-plan.md` L1988 | Low |
| 12.5 | 🟡 MEDIUM | deferred-ac-registry IMPL-062 row deferred-reason text still describes DISABLE_G4_FIXES operator action banned by BA post-BT-001 | `deferred-ac-registry.md § Active` IMPL-062 row | Low |
| 12.6 | 🟡 MEDIUM | current_handoff.md § BT-001 cascade chain table Step 3 still `⏳ Pending` despite R11 closure of Step 3 content | `current_handoff.md` L40 cascade-chain table | Low |

---

## End of Review
