# Implementation Plan Claim Review Round 11

| Field | Value |
|-------|-------|
| **Round** | 11 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-13 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R10 (2026-05-13) — 5/6 Accept + 1 Partial; closed prose/state-reconciliation defects |
| **Trigger** | `current_handoff.md § Recommended next session step 1` — SD Round 06 closure (2026-05-13) explicit advisory: `impl-plan.md L1966/L1988 IMPL-062/063 task rows pre-BT-001 framing` → "Surfaced here so Step 3 ของ BT-001 chain catches it." BT-001 cascade chain has BA Round 05 ✅ + SD Round 06 ✅ closed; this round = **Step 3 Impl Plan re-validate** |

---

## 📊 At-a-Glance

**Total findings:** 7 (🔴 CRITICAL 2 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep** (regex set `deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`): **0 real hits** ✅. Note: literal `deferred per ... precedent` regex matches 1 line due to greedy `.*` spanning `deferred per registry row ... workflow.md Gate #4 + fix-round-10 precedent` (line 21) — false positive; "precedent" is the canonical Counter-Convention boilerplate, not a forbidden closure pattern. Verified by enumerating the 3 `deferred per` hits (lines 21/2138/2158): all forms = `deferred per registry`/`deferred per §11 limitation` (sanctioned). R10 rebuttal `replace_all` 51-instance Sentinel boilerplate fix holds.
- **Forward refs (P_n → P_m, m>n):** 0 edges ✅ — plan-format ใช้ `**Deps**:` line (ไม่ใช่ `**Dependencies**:` field-style); enumerated dependencies ทุก task ที่ตรวจ point ไป P-equal-or-earlier; no forward edges. R09 fix (parent IMPL-FIX-011 P4 ↔ sub-tickets 011a/b/c/d P3 with explicit parent drain ownership) ยัง holds.
- **Silent Copy Detector:** H=67, A=66, D=1 (IMPL-013 P4→P3 Service-coupling diverge), V=0, N=0. Detector **NOT triggered** ✅ (D ≥ 1 + confirmation note present).
- **State reconciliation (4-way):** 🔴 **2 BA-as-Master desync** (IMPL-062 task title + Description + S-AC `[x]` lock in DISABLE_G4_FIXES build path explicitly banned by BA `03 § NFR-1.1 Verification` post-BT-001 2026-05-12; IMPL-063 framing "vs baseline" obsolete vs BA `03 § NFR-1.8` informational delta `rewrite-G4-ON − rewrite-G4-OFF`) + 🟠 **3 self-introduced R10 narrative drift** (R-3 + Next Best Action + Phase Gate Empirical Demo BLOCKED annotation treat `/backtrack ba` as future-pending when BT-001 already executed 2026-05-12 with BA + SD cascade closed) + 🟠 **1 IMPL-FIX-003 task-block-vs-TL;DR drift** (line 1643 Phase 1B Closure paragraph misses registry-row pointer that R10 added to TL;DR + registry — exact same drift class R10 introduced gates #7/#8 to prevent, recurring at task-block layer) + 🟡 **1 current_handoff.md desync** (Last completed action is SD Round 06 closure, NOT R10 rebuttal closure — R10 Cascaded Changes claimed 3-file rule honored, but current_handoff was overwritten by sibling SD review immediately after; State Reconciliation 3-file rule appears violated for this round).

### Top 3 to Fix First

1. **Claim 11.1** 🔴 — IMPL-062 task title + Description + S-AC `[x]` lock in **DISABLE_G4_FIXES build path** which BA `03 § NFR-1.1 Verification` post-BT-001 **explicitly bans** ("ห้ามใช้ #define DISABLE_G4_FIXES build"); plan-as-Slave-to-BA contract violated — `impl-plan.md` L1970/L1974/L1977/L1978
2. **Claim 11.2** 🔴 — R10's BLOCKED annotation on **5 sites** (P4 Phase Gate Empirical Demo + NFR-1.1 check row + IMPL-062 Status + IMPL-FIX-011 parent 4× E-AC footnote + R-3 + Next Best Action) treats `/backtrack ba` as future-pending — but BT-001 BA Round 05 + SD Round 06 BOTH closed 2026-05-13; advisory in `current_handoff.md § Recommended next step 1` says THIS round drains the impl-plan cascade. R10 fix introduced a stale claim across 5 surfaces — `impl-plan.md` lines 122, 171, 1401, 1406, 1820/1821, 1986
3. **Claim 11.3** 🟠 — IMPL-062 task-block § Status (2026-05-12 R10 §10.4) says `do NOT rerun until contract resolves` — but post-BT-001 the rerun *is* the resolution (rewrite-G4-ON single-pass per BA `03 § NFR-1.1 Verification` + SD `08 § 1.10` line 129); engineer reading Status will halt; reviewer-as-orchestrator advisory wrong.

### Verdict

- [ ] ✅ **Ready for Implementation Execution**
- [x] ⚠️ **Needs Rebuttal Round** — 2 CRITICAL BA-as-Master cascade gap + 3 HIGH stale-`/backtrack ba` annotations block (a) IMPL-062/063 re-author per BT-001 single-pass measurement; (b) `/next` orchestrator + status agents reading Phase Gate row from issuing correct next-action. Run `/impl-plan-rebuttal claim-review-11.md`.
- [ ] ⛔ **Immediate Attention**

> Rebuttal scope: AC content change (IMPL-062 S-AC must un-`[x]` DISABLE_G4_FIXES locks + re-author per rewrite-G4-ON single-pass) + prose / state-reconciliation. **More material than R10** (which was prose-only); BT-001 cascade IS the impl-plan re-author event SD Round 06 advisory pointed to.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Unchanged since R01–R10; rationale + Phase % targets ครบ; no BT-001 phase-shape impact |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean; D=1 IMPL-013 documented; SD Round 06 confirmed `08-product-breakdown` Phase Hint P4 BT-001 cascade landed cleanly (line 245 single-pass measurement annotation) — impl-plan need NOT re-audit, only update IMPL-062/063 task content (Dim #3+#4) |
| 3 | Task Decomposition & Sizing | ⚠️ Finding 11.1 | IMPL-062 task content (title + Description + Input citation) frozen at pre-BT-001 framing |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 11.1 + 11.4 | IMPL-062 S-AC `[x]` locks in DISABLE_G4_FIXES build (banned post-BT-001); IMPL-FIX-003 Phase 1B closure paragraph still says "G2/G3/G4 deferred to operator session" without registry pointer (R10 fixed TL;DR + registry but missed task-block) |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 11.2 | P4 Empirical Demo + NFR-1.1 check rows blocked on a `/backtrack ba` that already executed |
| 6 | Deferred-AC Registry Init | ✅ Pass | Registry has IMPL-FIX-003 Phase 1B row (R10 §10.5) + IMPL-FIX-011 parent (R09 09.7); BT-001 does not require new registry rows (re-baseline = AC text rewrite, not deferred-AC) |
| 7 | Cross-Phase Dependency | ✅ Pass | No forward refs |
| 8 | State-File Consistency | ⚠️ Findings 11.2 + 11.3 + 11.5 + 11.6 + 11.7 | R-3 + Next Best Action + IMPL-062 Status + IMPL-FIX-011 footnote BLOCKED annotations stale; current_handoff Last-completed-action diverges from R10 closure claim; task-block-vs-TL;DR drift on IMPL-FIX-003 Phase 1B |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4 schedule leakage; "Q1 2021" + "2021-2025" = test data windows ไม่ใช่ delivery dates |
| 10 | Readability — Reader Empathy | ⚠️ Finding 11.7 | TL;DR top entry (2026-05-12 Run #2 catastrophic-fail narrative ~80 บรรทัด) repeats the **same pre-BT-001** root-cause framing in the body — reader landing on TL;DR top will not see that BT-001 already RESOLVED the contract structurally; same skim-fail class as R10 §10.6 with new BT-001 angle |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 11.1: 🔴 CRITICAL — IMPL-062 task title + Description + 3× S-AC `[x]` lock in `DISABLE_G4_FIXES` build path which BA `03 § NFR-1.1 Verification` (BT-001, 2026-05-12) **explicitly bans**; plan-as-Slave-to-BA contract violated; SD `08 § 1.10` line 129 has cascade landed cleanly but impl-plan IMPL-062 row didn't propagate

**Location:**
- `docs/state/impl-plan.md` L1970 (title): `"IMPL-062: [M] [ea-qa] — Run regression: rewrite (without G4 fixes) vs baseline → Bucket A drift"`
- L1974 (Description): `"🔴 HIGH RISK / NFR-1.1 acceptance signal — run rewrite EA วันที่ G4 fixes disabled (IMPL-022 + IMPL-039 reverted to original buggy behavior — use compile flag DISABLE_G4_FIXES) over 5-yr 2021-2025 backtest → compute Net Profit deviation vs baseline. Pass: Bucket A drift ≤ 25% per NFR-1.1"`
- L1977 (S-AC #1 `[x]`): `"Rewrite EA built with DISABLE_G4_FIXES compile flag — STRUCTURAL: slots/Slot_J.mqh:180 + slots/Slot_BI.mqh:212 wrapped in #ifdef DISABLE_G4_FIXES / #else / #endif guards ..."`
- L1978 (S-AC #2 `[x]`): `"5-yr backtest run committed via simulation/headless-tests/regression_5yr_no_g4.ini ..."`
- L1981 (E-AC #1): `"|Bucket A drift| ≤ 25% NFR-1.1 [db-inspect] + [file-blob-check] — deferred to operator session (build .ex5 with DISABLE_G4_FIXES + run 5-yr regression_5yr_no_g4.ini ...)"`
- L1986 (Status R10 §10.4 BLOCKED annotation): re-cites DISABLE_G4_FIXES build as the official measurement contract

**Problem:**
BT-001 (`docs/state/backtrack-log.md § BT-001` 2026-05-12; status 🔄 Open pending Step 3 = this impl-plan-review) closed Steps 1 (BA) + 2 (SD) on 2026-05-12/13 with cascade edits landed:

- `docs/ba/03-non-functional-requirements.md § NFR-1.1` line 21: `"NFR-1.1 — Total Net Profit deviation ≤ 25% (Bucket A — rewrite-G4-ON vs baseline, BT-001 re-baseline)"`
- Same file § NFR-1.1 Verification line 32: `"QA Phase: รัน Strategy Tester ... บน rewrite default build (G4 fixes ON) → คำนวณ deviation จาก headline result table; ห้ามใช้ #define DISABLE_G4_FIXES build (Bucket A semantic ไม่รองรับ pre-G4 measurement หลัง BT-001)"`
- `docs/design-docs/08-product-breakdown.md § 1.10` line 129: `"IMPL-062 — Run regression: rewrite default build (G4 fixes ON, single-pass) vs baseline → Bucket A drift gate (NFR-1.1 ≤ 25%, G4 fix contribution included per BT-001 re-baseline 2026-05-12). ห้ามใช้ #define DISABLE_G4_FIXES build ..."`

Yet `impl-plan.md` IMPL-062 task block ทั้ง title + Description + S-AC `[x]` lock + Input citation + E-AC text + R10 Status annotation **all** carry the **pre-BT-001 framing** ("without G4 fixes" / "DISABLE_G4_FIXES" / "vs baseline 5-yr"). Specifically, S-AC #1 `[x]` (line 1977) is closed-as-correct against a measurement contract that BA Verification now bans. R10 (rebuttal 2026-05-13) sat directly on this row to author the BLOCKED annotation and **did not catch** that BT-001 had already landed in BA + SD that same day (BA `03` Last updated `2026-05-12`; SD Round 06 closed `2026-05-13`).

**Why this matters:**
1. **Plan-as-Slave-to-BA-as-Master contract** (CLAUDE.md § Glossary `SD-as-Master` + Plan downstream): `impl-plan.md` consumes BA + SD; ห้าม carry vocabulary obsoleted upstream. Engineer dispatching `/impl-task IMPL-062` will (a) build with `DISABLE_G4_FIXES` per S-AC #1 `[x]` text, (b) read BA NFR-1.1 Verification banning that exact build, (c) raise CONFUSION block. Worst case: engineer follows impl-plan S-AC `[x]` (the trusted "closed and accepted" surface), produces another Run #2-class result, and impl-plan acquires Run #3 evidence at same root cause class.
2. **S-AC `[x]` semantic** = "closed against correct contract." S-AC #1 + #2 closed 2026-05-05 against pre-BT-001 contract are now **structurally invalid closures** — same forbidden-pattern *spirit* as `[x]` + "deferred to operator-runtime" but at the contract-validity layer (catalog → destination → anchor → exemption-regex → contract-vocabulary, 5th axis of the R20→R24 chain).
3. SD Round 06 explicit handoff: `current_handoff.md § Recommended next session step 1` = "`/impl-plan-review all` — re-validate IMPL-062/063 task rows + Phase Hint P4 propagation". R10 ran instead and authored a BLOCKED annotation on the wrong premise. This R11 is the explicit Step 3 destination.

**Minimum acceptable fix:**
1. **IMPL-062 title rewrite** (L1970): `"IMPL-062: [M] [ea-qa] — Run regression: rewrite default build (G4 fixes ON, single-pass per BT-001) vs baseline → Bucket A drift (NFR-1.1)"` (mirror SD `08 § 1.10` line 129 verbatim wording).
2. **IMPL-062 Description rewrite** (L1974): replace "G4 fixes disabled... use compile flag DISABLE_G4_FIXES" with "rewrite default build (G4 fixes ON; ห้ามใช้ `#define DISABLE_G4_FIXES` per BT-001 BA `03 § NFR-1.1 Verification` 2026-05-12)" + cite `regression-bucket-a.md § 4a Run #2 root-cause` + `backtrack-log.md § BT-001`.
3. **S-AC #1 `[x]` → un-`[x]`** with annotation `"~~`[x]` 2026-05-05 — invalidated by BT-001 2026-05-12: S-AC text described DISABLE_G4_FIXES compile-flag build path which BA `03 § NFR-1.1 Verification` (BT-001 re-baseline) bans. Re-author below.~~"` + new S-AC `[ ]` `"Rewrite EA committed default build (no #define DISABLE_G4_FIXES) — single-pass G4-ON; commit `277cdb2` slot guards retained as forensic toggle per BT-001 Resolution decision (decide: keep or remove at IMPL-FIX-NNN follow-up)"`. Same un-`[x]` + re-author treatment for S-AC #2 (`regression_5yr_no_g4.ini` → new single-pass `regression_5yr_g4_single_pass.ini` OR document that the existing `.ini` is repurposed for informational Bucket B per IMPL-063 BT-001 framing).
4. **E-AC #1 rewrite** (L1981): drop "build .ex5 with DISABLE_G4_FIXES" instruction; align with rewrite-G4-ON single-pass per BA NFR-1.1.
5. **IMPL-062 Status BLOCKED annotation (R10 §10.4) rewrite** (L1986): replace `"BLOCKED on /backtrack ba NFR-1.1 contract re-baseline; do NOT rerun until contract resolves"` → `"~~BLOCKED~~ ✅ RESOLVED 2026-05-12 via BT-001 (BA Round 05 + SD Round 06 closed); IMPL-062 ready to re-execute per rewrite-G4-ON single-pass methodology per BA 03 § NFR-1.1 Verification + SD 08 § 1.10 line 129. Run #1 (day-1 stop-out) + Run #2 (99.998% drift) evidence preserved as audit history per BT-001 § Empirical Citation."`
6. **IMPL-063 cascade** (L1989-2007): title + Description align with BA `03 § NFR-1.8 BT-001 redefined` informational delta `rewrite-G4-ON − rewrite-G4-OFF` (NOT "rewrite-with-G4 vs baseline" pre-BT-001 framing).

**Effort:** Medium (~50-80 LOC rewrite across 2 task blocks; S-AC un-`[x]` requires careful audit-trail preservation per State Reconciliation Discipline — strike old text + add new, don't silently rewrite).

---

#### Claim 11.2: 🔴 CRITICAL — R10's BLOCKED annotations on 5 sites treat `/backtrack ba` as future-pending operator action; BT-001 BA Round 05 ✅ + SD Round 06 ✅ both closed 2026-05-13 (today); annotation introduces stale framing on the highest-visibility surface (P4 Phase Gate + IMPL-062 Status + Next Best Action top item)

**Location:**
- `docs/state/impl-plan.md` L122 (Open Risks R-3 strike + R10 §10.2 pivot): `"⚠️ CONTRACT RE-BASELINE REQUIRED 2026-05-12 (R10 §10.2 update) ... Earliest mitigation: /backtrack ba to update NFR-1.1 threshold OR re-interpret Bucket A = 'rewrite-G4-ON vs baseline'"`
- L171 (Next Best Action new top-level): `"☐ Operator decision on /backtrack ba scope — IMPL-062 Run #2 ... Options: (i) /backtrack ba re-baseline NFR-1.1 threshold; (ii) /backtrack ba re-interpret Bucket A = 'rewrite-G4-ON vs baseline' (replace contract); (iii) accept N/A with stakeholder waiver per BA 01 § 6.2 Won't Permanent precedent"`
- L1401 (P4 Phase Gate § Empirical Demo): `"⚠️ BLOCKED 2026-05-12 (R10 §10.4) — pending /backtrack ba NFR-1.1 contract re-baseline ..."`
- L1406 (NFR-1.1 check row): `"BLOCKED 2026-05-12 (R10 §10.4) — pending /backtrack ba re-baseline ..."`
- L1818/1819/1820/1821 (IMPL-FIX-011 parent 4× E-AC footnote with R10 §10.4 BLOCKED): each cites `"BLOCKED on /backtrack ba contract re-baseline"`
- L1986 (IMPL-062 Status R10 §10.4): `"BLOCKED on /backtrack ba NFR-1.1 contract re-baseline"`

**Problem:**
R10 rebuttal (closed 2026-05-13 same day as this R11) authored a "BLOCKED — pending `/backtrack ba`" annotation in **5 distinct sites + 4 footnote bullets = 9 surface instances**. BT-001 was already in flight 2026-05-12 per `backtrack-log.md § BT-001` and the cascade edits landed in BA (`03 Last updated 2026-05-12`) and SD (`08 Last updated 2026-05-12`; SD Round 06 closure note `current_handoff.md § Last completed action 2026-05-13`). R10 reviewer (claim-review-10.md) wrote in Finding 10.4 Minimum-fix: `"⚠️ BLOCKED 2026-05-12 — pending /backtrack ba re-baseline"` — but did **not** check `backtrack-log.md` or `docs/ba/03 Last updated` before authoring; the BLOCKED text presumed `/backtrack ba` was future, when BT-001 chain was at Step 3 (this round). R10 fix-round inherited the reviewer's stale premise.

**Why this matters:**
1. **Highest-visibility surface contamination**: Phase Gate Empirical Demo bullet (L1401) + NFR check row (L1406) + Open Risks R-3 (L122) + Next Best Action top item (L171) are exactly the surfaces `/next` orchestrator + status agents + operator scan first. Reader landing on Next Best Action will see `"☐ Operator decision on /backtrack ba scope"` as the next-action — but `/backtrack ba` is DONE. Operator runs a redundant `/backtrack ba` (probably no-op since BT-001 already resolved both NFRs) OR sits paralyzed waiting for a decision that's already made.
2. **Same root cause as R10 §10.2 Open Risks staleness** (which R10 itself just fixed!) — R10 added Phase 5 Gate #7/#8 to prevent narrative-section drift, then introduced a new narrative-section drift in its own rebuttal text by not checking BT-001 status. Defect class recurrence at next-finer granularity (R10 caught stale-because-task-closed; R11 catches stale-because-upstream-backtrack-closed-during-same-rebuttal-window).
3. **State Reconciliation 3-file rule violation** at upstream layer: BA + SD are the upstream sources; R10 claimed "honored 3-file rule" but read only `impl-plan.md` + `overview.md` + `current_handoff.md` (intra-state) — did not read BA `03` + SD `08` Last updated stamps (which would have surfaced BT-001 vocabulary).

**Minimum acceptable fix:**
1. Bulk-replace 9 R10 §10.4 BLOCKED annotations with `"✅ RESOLVED 2026-05-12 via BT-001 (BA Round 05 + SD Round 06 closed) — measurement methodology redefined: NFR-1.1 = rewrite-G4-ON vs baseline single-pass (BA 03 § NFR-1.1 Verification); NFR-1.8 = informational delta (no acceptance gate). Run #1 + Run #2 evidence preserved as BT-001 § Empirical Citation."` Sites: L122 (R-3 pivot annotation); L171 (Next Best Action top item — strike Option (i)/(ii)/(iii) operator-decision block); L1401 (Phase Gate Empirical Demo); L1406 (NFR-1.1 check row); L1818-1821 (IMPL-FIX-011 parent 4× footnote); L1986 (IMPL-062 Status).
2. **Next Best Action new top-level** (post-strike): `"☐ /impl-task IMPL-062 — re-execute Bucket A 5-yr regression on rewrite default build (G4-ON, single-pass per BT-001) → produce Net Profit deviation vs baseline ($24.27M) per NFR-1.1 ≤ 25% gate. Paired with IMPL-063 informational Bucket B same operator session."`
3. Open Risks R-3 promote to **✅ RESOLVED 2026-05-12 via BT-001** (strike `⚠️ CONTRACT RE-BASELINE REQUIRED`); body preserved as audit history.
4. Add **mandatory pre-rebuttal step** to engineer-side rebuttal workflow checklist (`workflow.md § Phase 5 Closure mechanical gates`): new Gate #12 = **"Upstream BA/SD Last-updated check"** — before authoring any "BLOCKED on /backtrack X" annotation, engineer MUST grep `Last updated:` in `docs/ba/*.md` + `docs/design-docs/0*.md` + `docs/state/backtrack-log.md` § Status for any BT-NNN entry referencing the same scope; if BT-NNN status = Open with cascade landed → annotation must say "RESOLVED via BT-NNN" not "BLOCKED pending /backtrack". This is the meta-rule fix to prevent recurrence.

**Effort:** Low (9 site annotations rewrite + 1 new Gate #12 entry; ~30 LOC text replace + ~20 LOC new workflow.md gate).

---

### 🟠 HIGH

#### Claim 11.3: 🟠 HIGH — IMPL-062 task-block § Status (R10 §10.4) ends with `"do NOT rerun until contract resolves"` — actively wrong post-BT-001; engineer reading Status will refuse the very task the BT-001 chain Step 3+ unblocks

**Location:** `docs/state/impl-plan.md` L1986 (IMPL-062 Status R10 §10.4): `"... Re-baseline pending /backtrack ba; do NOT rerun until contract resolves."`

**Problem:**
The "do NOT rerun" instruction explicitly tells the engineer to halt IMPL-062 execution until `/backtrack ba` resolves. But BT-001 (the `/backtrack ba` event) resolved 2026-05-12; the resolution = "re-run IMPL-062 on rewrite-G4-ON build single-pass per redefined NFR-1.1." So the Status row's instruction is now the **opposite** of the BT-001 Resolution direction. Engineer who reads only this Status block (skipping TL;DR + Open Risks + Phase Gate) gets a wrong-direction next-step.

**Why this matters:**
Engineer-side `/impl-task IMPL-062` workflow reads the task block Status field directly (per `andm-impl-engineer/SKILL.md § Confusion Management`). Status overriding TL;DR + Phase Gate is the normal precedence (task-local > plan-global). R10 wrote a halt instruction; BT-001 wrote a resume instruction; the conflict resolves to halt by precedence. Plan acquires a permanent IMPL-062 deadlock until manually edited.

**Minimum acceptable fix:** L1986 Status full rewrite: `"**Status (R11 §11.3, 2026-05-13, post-BT-001):** ✅ READY TO RE-EXECUTE — Run #1 (2026-05-10 day-1 stop-out) + Run #2 (2026-05-12 99.998% drift) under DISABLE_G4_FIXES build attested measurement-contract incompatibility per BA `03 § NFR-1 Empirical Citation`; BT-001 BA Round 05 + SD Round 06 closed 2026-05-13 redefining NFR-1.1 = rewrite-G4-ON vs baseline single-pass. Next execution = default build (no DISABLE_G4_FIXES) over 5-yr 2021-2025 paired with IMPL-063 informational Bucket B. Prior Run #1/#2 evidence preserved at `_session-handoff/IMPL-062-bucket-a-5yr-partial-20260510.{md,txt}` + `IMPL-FIX-003-bucket-a-5yr-partial-20260512.{txt,jsonl}` + `regression-bucket-a.md § 4a/§ 5 § Empirical Citation`."`

**Effort:** Low (1 paragraph rewrite, ~10 LOC).

---

#### Claim 11.4: 🟠 HIGH — IMPL-FIX-003 task block § Phase 1B Closure paragraph (L1643) ยัง carry "G2/G3/G4 deferred to operator session" wording WITHOUT registry-row pointer that R10 §10.5 added to TL;DR + registry; task-block-vs-TL;DR drift exactly the class R10 introduced Gate #7/#8 to prevent

**Location:** `docs/state/impl-plan.md` L1643 (IMPL-FIX-003 Phase 1B Closure paragraph last sentence): `"G2/G3/G4 deferred to operator session (foreground MT5 lock during closure session; pattern byte-identical to known-clean Slot_K iter-18 + Slot_B iter-19 compiles per mt5-log-reader § Compile semantics)."` vs TL;DR L11 (R10 §10.5 fix): `"... ✅ tracked at deferred-ac-registry.md § Active row IMPL-FIX-003 Phase 1B (expiry 2026-05-26) per R10 §10.5 ..."`.

**Problem:**
R10 §10.5 closed Claim 10.5 by (a) adding new Active row in `deferred-ac-registry.md` (verified — line 71 of registry); (b) updating TL;DR L9 with registry pointer + R10 §10.5 cite. But the **canonical task block** at L1643 (where engineer running `/impl-task IMPL-FIX-003` Phase 1B verification will land) **still says "deferred to operator session"** with no registry pointer. R10 fix-round narrative claimed "State Reconciliation 3-file rule honored (impl-plan TL;DR + IMPL-FIX-003 Phase 1B inline closure note + Next Best Action strike + overview row + 1 evidence sidecar)" — but "IMPL-FIX-003 Phase 1B inline closure note" referenced the TL;DR-embedded sentence, NOT the task-block § Phase 1B Closure paragraph. Two surfaces; only one updated.

**Why this matters:**
Same drift class as R09 09.6 (TL;DR-vs-diagnostic drift) + R10 §10.3 (TL;DR-vs-parent-task-block drift) — recurring at next-finer granularity. Engineer reading task block doesn't know G2/G3/G4 is tracked at registry; treats "deferred to operator session" as forbidden-pattern proximity (per R10 §10.5 reasoning). Phase 5 mechanical Gate #7 (Phase Status Notes sweep) + Gate #8 (narrative-section freshness sweep) both apply to **task-block content**, not just intra-narrative; R10 fix-round failed Gates #7/#8 at the task-block layer for the IMPL-FIX-003 row.

**Minimum acceptable fix:** L1643 last sentence rewrite: `"G2/G3/G4 ✅ tracked at deferred-ac-registry.md § Active row IMPL-FIX-003 Phase 1B (expiry 2026-05-26, owner Kritsana, evidence-kinds probe + log-assertion + file-blob-check per R10 §10.5) — closure 2026-05-12 deferred operator session per foreground MT5 lock; pattern byte-identical to Slot_K iter-18 + Slot_B iter-19 (G1 PASS attests no syntax error); empirical attach/smoke/log verification deferred to Tier 1.5 walk batch-4 OR IMPL-062 Run #3 retry post-BT-001."`

**Effort:** Low (1 sentence rewrite + 1 registry citation; ~5 LOC).

---

#### Claim 11.5: 🟠 HIGH — current_handoff.md "Last completed action" = SD Round 06 closure, NOT R10 impl-plan rebuttal closure; R10 Cascaded Changes claim "honored State Reconciliation 3-file rule" → not durably true (handoff overwritten by sibling SD review immediately)

**Location:**
- `docs/state/current_handoff.md` Last completed action header (line 7): `"🟢 SD Review Round 06 ✅ CLOSED 2026-05-13 — BT-001 Bucket A/B cascade verify-only sweep returned 0 findings ..."`
- `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-10.md § Cascaded Changes` line 121: `"docs/state/overview.md § Phase Status § Impl Plan row — Status column updated with R10 rebuttal closure summary ... Honors State Reconciliation 3-file rule (CLAUDE.md §6)"`

**Problem:**
R10 rebuttal-round-10.md § Strength Assessment claimed `"State Reconciliation 3-file rule: honored"`. The rule per CLAUDE.md §6 = `impl-plan.md` (primary) + `overview.md` (derived) + `{module}/handoff.md` + `_session-handoff/*`. R10 updated overview.md (verified — overview line 19 has R10 closure note) but `current_handoff.md` "Last completed action" was either (a) never updated by R10, or (b) updated by R10 then immediately overwritten by the SD Round 06 closure happening the same day. Either way, **post-R10 state has no impl-plan-rebuttal-10 trace in current_handoff.md**. From a `/next` orchestrator perspective, only SD Round 06 visible — R10 rebuttal "didn't happen" from handoff-reader perspective.

**Why this matters:**
State Reconciliation 3-file rule is the CLAUDE.md §6 guardrail against `/next` rendering wrong recommendations. With `current_handoff.md` showing only SD Round 06, the `/next` orchestrator (which scans `Last completed action` first per its prompt design) will recommend the SD Round 06 follow-up sequence (which is correctly "`/impl-plan-review all`" = THIS round) — but the operator gets no signal that R10 just closed. If they invoke `/next` again after this R11 review writes, they will see THIS round's claim file as Last completed action, but R10's intermediate rebuttal close will remain invisible to the handoff timeline. Audit trail for the impl-plan-review/rebuttal cycle has a gap.

**Minimum acceptable fix:**
This is technically a current_handoff.md fix, not an impl-plan.md fix — but route through Cascaded Changes per State Reconciliation Discipline. R11 rebuttal should:
1. Append a **prior-action section** to current_handoff.md `Last completed action` block: `"**Prior action (2026-05-13 earlier):** 📝 /impl-plan-rebuttal claim-review-10.md ✅ CLOSED (6/6 — 5 Accept + 1 Partial). 51-instance Sentinel boilerplate fix + 6 narrative-parallel sections refreshed + IMPL-FIX-003 Phase 1B registry row added expiry 2026-05-26. No AC changes / no phase reassignments. See impl-plan-claim-review-and-rebuttal/rebuttal-round-10.md."`
2. Add to `workflow.md § Phase 5 Closure mechanical gates` new Gate #13 = **"Handoff Last-completed-action durability check"** — when multiple `/X-rebuttal` or `/X-review` actions close in same day, engineer MUST verify final state of `current_handoff.md` reflects MOST RECENT close OR carries both as primary + prior-action chain.

**Effort:** Low (current_handoff.md prior-action block + 1 new Gate entry; ~15 LOC).

---

### 🟡 MEDIUM

#### Claim 11.6: 🟡 MEDIUM — IMPL-063 task title + Description still cite "vs baseline" pre-BT-001 Bucket B framing instead of post-BT-001 informational delta `rewrite-G4-ON − rewrite-G4-OFF`; minor compared to IMPL-062 because IMPL-063 has no `[x]` lock to invalidate, but breaks single-voice contract with BA `03 § NFR-1.8`

**Location:**
- `docs/state/impl-plan.md` L1989 (title): `"IMPL-063: [M] [ea-qa] — Run regression: rewrite (with G4 fixes) vs baseline → Bucket B drift"`
- L1993 (Description): `"🔴 HIGH RISK / NFR-1.8 G4 acceptance signal — run rewrite EA with G4 fixes enabled (IMPL-022 + IMPL-039 baseline) over same 5-yr → compute additional drift attributable to G4 fixes. No hard cap (Bucket B = intentional change); user re-decide trigger if drift > 25%"`
- L1994 (Input): `"NFR-1.8 (Bucket B documented), ADR-009, BR-7.2, IMPL-062 (Bucket A baseline)"`
- L2004 (Risk): `"high (G4 acceptance; potential user re-decide)"`

**Problem:**
Per BA `03 § NFR-1.8 BT-001 redefined` (line 123): `"Bucket B = informational delta rewrite-G4-ON − rewrite-G4-OFF (sign + magnitude ของ intentional fix contribution); ไม่ใช่ primary acceptance gate (re-classified BT-001 2026-05-12 — เดิม Must, ตอนนี้ Should informational)"` + line 130 Metric: `"Informational delta: Net Profit (rewrite-G4-ON) − Net Profit (rewrite-G4-OFF) — sign + magnitude only; no pass/fail threshold"`. SD `08 § 1.10` line 130 + § 4 line 294 mirror this.

`impl-plan.md` IMPL-063 framing "rewrite-with-G4 vs baseline" is the pre-BT-001 contract; "user re-decide trigger if drift > 25%" is the pre-BT-001 escalation rule (BT-001 dropped this — NFR-1.8 is now Should/informational with no threshold). MoSCoW citation impact: BA `03` line 13 now says NFR-1.8 priority Must → Should — task Risk "high" should consequently downgrade.

**Why this matters:**
1. Same BA-as-Master desync class as Claim 11.1 but at a row where no `[x]` S-AC locks in a banned contract — so severity HIGH not CRITICAL.
2. Engineer running `/impl-task IMPL-063` will execute the wrong measurement (vs-baseline instead of pre-vs-post-G4 delta) and produce a result that doesn't satisfy the redefined NFR-1.8.

**Minimum acceptable fix:**
1. Title rewrite: `"IMPL-063: [M] [ea-qa] — Measure Bucket B informational delta rewrite-G4-ON − rewrite-G4-OFF (NFR-1.8 BT-001 informational; no acceptance gate)"`
2. Description rewrite: replace "vs baseline" framing with "informational delta `rewrite-G4-ON − rewrite-G4-OFF` per BA `03 § NFR-1.8 BT-001 redefined`; no pass/fail threshold; partial pre-CircuitBreaker window of G4-OFF build per BT-001 + IMPL-062 Run #2 empirical limitation"
3. S-AC #1 + #2 add follow-up annotation `"S-AC text describes G4-OFF build prerequisite for delta computation; BT-001 acknowledges G4-OFF window measurable only partially pre-CircuitBreaker BR-3.6 halt per IMPL-062 Run #2 finding."`
4. Risk: `"high"` → `"medium (BT-001 demoted NFR-1.8 Must → Should; no re-decide trigger; informational only)"`.

**Effort:** Low-Medium (~20-30 LOC across 1 task block).

---

#### Claim 11.7: 🟡 MEDIUM — TL;DR top entry (2026-05-12 IMPL-062 Run #2 catastrophic-fail; ~80 lines of inline narrative) embeds the same pre-BT-001 root-cause framing in its **recommended-next-steps body** that BT-001 then resolved structurally; reader landing on TL;DR will read 4-option `/backtrack ba` decision tree that's now historical

**Location:** `docs/state/impl-plan.md` L7 (TL;DR entry 2026-05-12 IMPL-062 Run #2; ~one paragraph spanning ~80 visual lines including the 4-option recommended-next-steps sub-list at the end: `"Recommended operator next steps: (1) Re-baseline NFR-1.1 contract — /backtrack ba to update threshold OR re-interpret 'Bucket A' to mean 'rewrite-G4-ON vs baseline' ... (2) Bucket B regression first ... (3) CircuitBreaker BR-3.6 threshold tuning ... (4) Slot_H ManageExits same-bar cooldown ..."`).

**Problem:**
The 4-option recommended-next-steps block is canonical pre-BT-001 framing — author's recommendation at the time of writing 2026-05-12 entry. BT-001 then ran option (1) variant ("re-interpret Bucket A as rewrite-G4-ON vs baseline") and resolved; BA + SD cascade landed; the other 3 options (Bucket B first / CircuitBreaker tuning / Slot_H cooldown) are now historical alternatives, not pending recommendations. Reader of TL;DR top entry sees an open-decision narrative.

**Why this matters:**
1. Per CLAUDE.md Readability "stakeholder skim test" — Tech Lead/PM reading TL;DR top should get current pending state, not historical decision-tree. With BT-001 already chosen and executed, the 4-option list misrepresents state.
2. Same skim-fail class as R10 §10.6 (Partial — physical reorg deferred). R10 added Reader empathy note + Closure Hygiene Status block but **did not annotate the TL;DR top entry post-mortem context** when BT-001 landed same day. This is a Phase 5 Gate #4 (Sentinel-update boilerplate) + Gate #8 (narrative-section freshness sweep) gap — R10's Sentinel `replace_all` updated the trailing boilerplate of each TL;DR entry but did not touch the **substantive recommended-next-steps body** of the top entry.

**Minimum acceptable fix:**
1. TL;DR L7 append (immediately before final boilerplate sentence): `"**Update 2026-05-13 (R11 §11.7, post-BT-001 closure):** Option (1) variant "re-interpret Bucket A = rewrite-G4-ON vs baseline" was selected → BT-001 BA Round 05 + SD Round 06 closed 2026-05-13 with cascade landed (BA 03 § NFR-1.1 Verification + SD 08 § 1.10 line 129). Options (2)/(3)/(4) preserved as historical alternatives but superseded. Next action = re-execute IMPL-062 per rewrite-G4-ON single-pass methodology per BT-001 Resolution direction."`

**Effort:** Low (single annotation, ~6 LOC).

---

## Cross-Document Issues

This round catches **2 BA↔impl-plan + 1 SD↔impl-plan** cross-document contradictions (the BT-001 cascade gap):

| Contradiction | Upstream source | impl-plan site |
|---------------|-----------------|----------------|
| BA `03 § NFR-1.1 Verification` (2026-05-12): "ห้ามใช้ `#define DISABLE_G4_FIXES` build" | `docs/ba/03-non-functional-requirements.md` L32 | impl-plan IMPL-062 S-AC #1 `[x]` at L1977 LOCKS IN `DISABLE_G4_FIXES` compile flag build path (Claim 11.1) |
| BA `03 § NFR-1.8 BT-001 redefined` (2026-05-12): "Bucket B = informational delta `rewrite-G4-ON − rewrite-G4-OFF`; no pass/fail threshold" | `docs/ba/03-non-functional-requirements.md` L123 + L130 | impl-plan IMPL-063 Description at L1993 cites "vs baseline" framing + "user re-decide if drift > 25%" pre-BT-001 escalation rule (Claim 11.6) |
| SD `08 § 1.10` line 129 (2026-05-12): "IMPL-062 — Run regression: rewrite default build (G4 fixes ON, single-pass)" | `docs/design-docs/08-product-breakdown.md` L129 | impl-plan IMPL-062 title at L1970 still says "rewrite (without G4 fixes)" (Claim 11.1) |

No new Evolution Sequence violation. No ADR backing gap.

---

## Recurring Weaknesses (rounds 06-10)

1. **Intra-plan parallel-narrative drift** caught at next-coarser granularity each round (R06/R07 TL;DR-vs-registry → R08 Phase Status Notes + Open Risks/Next Best Action → R09 TL;DR-vs-diagnostic → R10 TL;DR-vs-Sentinel + R-3/R-8/R-13 + Phase Status P4 + Next Best Action 6-section refresh). **R11 (this round)** catches the **upstream-vs-impl-plan drift** layer: BA `03` Last-updated 2026-05-12 + SD `08` Last-updated 2026-05-12 + SD Round 06 closure 2026-05-13 ALL landed BT-001 vocabulary; impl-plan task rows IMPL-062/063 + R10 BLOCKED annotations missed the propagation. Defect-class progression: **task-internal → intra-plan narrative → upstream-derived state** (4th layer; next-coarser granularity = whole-plan-vs-BA/SD).
2. **R10's own rebuttal introduced 3 new defects** (Claims 11.2 + 11.4 + 11.5): wrong-direction BLOCKED annotation in 9 sites; task-block-vs-TL;DR drift on IMPL-FIX-003 Phase 1B closure paragraph; current_handoff.md durability gap. Same shape as R08 finding "rebuttal itself introduces narrative defects" — R10 rebuttal triggered the very Gate #7/#8 R08 introduced (but at task-block layer not intra-narrative layer; same regression class as R12→R23 chain at meta-level).
3. **Cross-document discipline gap**: every prior round (R01-R10) operated within `docs/state/impl-plan.md` + sibling state files. R11 surfaces that impl-plan-review MUST also include upstream BA/SD/ADR `Last updated:` stamps in pre-scan; otherwise BT-NNN cascade-completion events between reviews silently desync the plan. Recommended methodology improvement: add Phase 0 onboarding step "grep `Last updated:` on `docs/ba/*.md` + `docs/design-docs/0*.md` + `docs/state/backtrack-log.md § Status` for any BT-NNN entry referencing impl-plan task scope" to `andm-impl-plan-reviewer/SKILL.md`.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 11.1 | 🔴 CRITICAL | IMPL-062 title + Description + S-AC `[x]` lock DISABLE_G4_FIXES build path banned by BA `03 § NFR-1.1 Verification` post-BT-001 | `impl-plan.md` L1970/1974/1977/1978/1981/1986 | Medium |
| 11.2 | 🔴 CRITICAL | R10's BLOCKED annotation on 9 sites treats `/backtrack ba` as future-pending; BT-001 already closed 2026-05-13 | `impl-plan.md` L122/171/1401/1406/1818-1821/1986 | Low |
| 11.3 | 🟠 HIGH | IMPL-062 Status R10 §10.4 says `"do NOT rerun"` — actively wrong post-BT-001; engineer halts on the task BT-001 unblocks | `impl-plan.md` L1986 | Low |
| 11.4 | 🟠 HIGH | IMPL-FIX-003 Phase 1B task-block closure paragraph drift (TL;DR has registry pointer; task block doesn't); R10 §10.5 missed task-block layer | `impl-plan.md` L1643 | Low |
| 11.5 | 🟠 HIGH | current_handoff.md "Last completed action" = SD Round 06 not R10 rebuttal; R10 "honored 3-file rule" claim not durable | `docs/state/current_handoff.md` (Cascaded; routes via rebuttal) | Low |
| 11.6 | 🟡 MEDIUM | IMPL-063 framing "vs baseline" obsolete vs BA NFR-1.8 BT-001 informational delta `G4-ON − G4-OFF` | `impl-plan.md` L1989-2007 | Low-Medium |
| 11.7 | 🟡 MEDIUM | TL;DR L7 top entry 4-option `/backtrack ba` recommended-next-steps body now historical post-BT-001 closure | `impl-plan.md` L7 | Low |

---

## End of Review
