# Implementation Plan Claim Review Round 07

| Field | Value |
|-------|-------|
| **Round** | 07 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-04 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Trigger** | Plan Staleness Sentinel @ 10 closures since R06 — engineer self-flagged "TRIPS THRESHOLD" in TL;DR `Last updated` line + recommended `/impl-plan-review all` before IMPL-060 entry .mq5 |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL 1 / 🟠 HIGH 3 / 🟡 MEDIUM 1 / 🔵 LOW 1)

**Mechanical pre-scans:**
- Forbidden closure patterns: **2 hits** (line 1636 audit-log row × 2; **1 genuine R06 regression** + 1 greedy-regex false-positive `"deferred per XS scope" … "precedent"`)
- Forward reference (P_n → P_m, m > n): **0 edges** ✅ (walked all `**Deps**` fields; every P3/P4 forward link references prior phase or same-phase prereq)
- Silent Copy Detector: H=68, A=67, D=1 (IMPL-013), V=0, N=0 → **not triggered** (D ≠ 0; explicit divergence already documented)
- State reconciliation: impl-plan ↔ overview / registry / handoff — **4 divergences detected** (TL;DR P4 active-row count 1 vs registry 8; TL;DR total 36 vs actual 43; TL;DR P4 task count `7/11` vs Phase × Size matrix `17`; Plan Staleness Sentinel section "Closures since last review: 2" vs TL;DR self-claim "10")

### Top 3 to Fix First
1. **Claim 07.1** 🔴 — Forbidden closure pattern regression introduced post-R06 in Mid-Phase Audit Log row (2026-05-04) — `impl-plan.md` line 1636
2. **Claim 07.2** 🟠 — TL;DR Deferred-AC Active count drift: claims `1 P4 row = 36 total`, registry has `8 P4 rows = 43 total` (off by 7) — `impl-plan.md` line 8
3. **Claim 07.3** 🟠 — TL;DR + Phase Status row report `P4 7/11` but Phase × Size matrix locks P4=17 tasks (denominator wrong by 6) — `impl-plan.md` lines 5, 20

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — 1 CRITICAL (R06 closure-discipline regression) + 3 HIGH (state reconciliation drifts) → run `/impl-plan-rebuttal claim-review-07.md` before `/impl-task IMPL-060`
- [ ] ⛔ **Immediate Attention** — defects scoped to TL;DR/audit-log narrative; do not block engineer from understanding work; readable plan body unchanged

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Inherited from R02 lock; no Phase × Size matrix changes since approval |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | H=68 / A=67 / D=1 (IMPL-013) / V=0 / N=0 — Silent Copy Detector not triggered (D ≠ 0); audit-trail intact |
| 3 | Task Decomposition & Sizing | ✅ Pass | No new tasks since R06; existing decomposition stable |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 07.1 | 1 forbidden-closure-pattern regression in audit-log narrative (2026-05-04 row) + R06 had reworded all such variants — engineer-side `/impl-task` Phase 5 closure still lacks the recommended forbidden-pattern grep |
| 5 | Phase Gates — Testable Exit | ✅ Pass | All P2/P3/P4 Phase Gate rows testable + measurable; placeholder paths use `<TBD-...>` non-date markers per R06.6 fix |
| 6 | Deferred-AC Registry Init | ⚠️ Finding 07.2 | Registry initialized + schema-compliant; but TL;DR Active count is stale (claims 36, actual 43 with 8 P4 rows not 1) |
| 7 | Cross-Phase Dependency | ✅ Pass | Forward-reference scan = 0 edges; Mermaid graphs match Phase × Size matrix |
| 8 | State-File Consistency | ⚠️ Finding 07.3 + 07.4 | (a) TL;DR P4 task count `7/11` ≠ matrix `17`; (b) Plan Staleness Sentinel section internal contradiction (says 2 closures, TL;DR self-flags 10); (c) `overview.md § Impl Plan` Last Updated stuck at 2026-05-03 ขณะที่ plan body มี 8 closures dated 2026-05-04 |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | Grep clean for sprint/week/Q1-Q4/calendar-month leakage |
| 10 | Readability — Reader Empathy | ⚠️ Finding 07.5 + 07.6 | TL;DR `Last updated` line has grown to ~1,200 words single paragraph spanning 10 closures + skim test fails; Phasing Rationale sections still readable |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 07.1: 🔴 CRITICAL — Forbidden closure pattern regression in Mid-Phase Audit Log (2026-05-04 GREEN row)

**Location:** `docs/state/impl-plan.md` line 1636 (Mid-Phase Audit Log row "Mid-Phase Audit GREEN — Phase 4 unblocked for next task")

**Problem:**
ในขณะที่ R06 (Claim 06.1) เพิ่ง rework 20 hits ของ forbidden closure pattern (`"deferred per .* precedent"` + `"structurally complete.*deferred"`) ให้เหลือ 0 hits — audit-log row ที่เพิ่มเข้ามาวันที่ 2026-05-04 ใส่ pattern เดิมกลับเข้ามา quote ตรง:

> *"P4 evidence files IMPL-{053,054,055,056,058}-evidence-20260504.md all present, dated 2026-05-04, sections 9-13 each (**structurally complete per IMPL-018+ header-only precedent**) ✅"*

ตัว row เองพยายามแก้ตัวว่า:

> *"(5) Forbidden-closure pattern strict grep on `[x]` AC lines: 0 hits ✅ (one false-positive on greedy `.*` regex spanning audit-log narrative — `"deferred per XS scope"` + `"precedent"` in same cell — confirmed not a Dimension #11 violation)"*

แต่ pattern `"structurally complete per IMPL-018+ header-only precedent"` ใช้ทั้ง keyword `"structurally complete"` + `"precedent"` ซึ่งเป็น Type 2 forbidden pattern verbatim ที่ R06 ระบุห้าม — ไม่ใช่ regex false-positive

**Why this matters:**
R06 Recommendation explicitly noted ว่าควรเพิ่ม `grep -cE "deferred per .* precedent|deferred to operator-runtime|structurally complete.*deferred|live verification deferred"` เป็น mechanical gate ใน `/impl-task` Phase 5 Closure เพื่อจับ regression ที่ task-3 ไม่ใช่ task-33 — engineer-side workflow change ที่ R06 flag ไว้ "out-of-scope for that rebuttal" ยังไม่ได้ implement → ส่งผลให้เกิด R06 regression ทันทีในรอบ 2 เดือนหน้าวัน. ถ้าไม่จับตอนนี้ จะ propagate ทุก Mid-Phase Audit narrative ในอนาคต และ erode discipline กลับสู่ pre-R06 baseline.

**Minimum acceptable fix:**
1. Reword line 1636 audit-log row part `"(structurally complete per IMPL-018+ header-only precedent)"` → `"(structurally complete per § IMPL-018+ scope contract — same evidence-file template tracked in deferred-ac-registry rows)"` หรือคล้ายกัน — strip `"precedent"` keyword
2. Address greedy-regex false-positive ใน 1639 (`"deferred per XS scope. … precedent"`) ด้วย rewording `"deferred per XS scope"` → `"deferred under XS scope contract"` เพื่อไม่ให้ greedy `.*` ลากผ่าน 2 phrases ที่ unrelated มาชนกัน — แม้ว่า reviewer ยอมรับว่าเป็น false-positive แต่ post-fix grep ที่ R06 commit ว่า "0 hits ✅" ต้องคืนเป็น 0 hits จริง ๆ (cleaner audit signal)
3. **Implement** R06 recommendation จริง ๆ — เพิ่ม forbidden-pattern grep step ใน `/impl-task` Phase 5 Closure (engineer-side workflow change per Defender 10-marker sweep extension); ไม่ใช่ flag-only

**Effort:** Low (text reword) + Medium (workflow change one-liner ใน andm-impl-engineer SKILL — หรืออย่างน้อย document ใน CLAUDE.md §6 + `.claude/rules/workflow.md`)

---

### 🟠 HIGH

#### Claim 07.2: 🟠 HIGH — TL;DR Deferred-AC Active count drift: 36 claimed, 43 actual (P4 row count off by 7)

**Location:** `docs/state/impl-plan.md` line 8 (TL;DR `Deferred-AC Active:` row)

**Problem:**
TL;DR ปัจจุบัน:

> *"Deferred-AC Active: 6 P1 rows … + 5 P2 rows + 24 P3 E-AC deferrals (…) + **1 P4 row (IMPL-053 smoke 10-position fixture E-AC; expiry 2026-05-18; block on IMPL-059+ Orchestrator + entry .mq5)** = **36 Active rows total**"*

Mechanical recount of `deferred-ac-registry.md § Active` (awk filter on phase column):

```
P1: 6 rows  ✅
P2: 5 rows  ✅
P3: 24 rows ✅
P4: 8 rows  ❌  (claimed 1)
TOTAL: 43 rows  ❌ (claimed 36, off by 7)
```

8 P4 rows = IMPL-053 + IMPL-054 + IMPL-055 + IMPL-056 + IMPL-057 + IMPL-058 + IMPL-059 + IMPL-053..056 (compound close-path empirical row from fix-round-09 Finding 09.5).

**Why this matters:**
Identical defect class to **R06 Claim 06.4** (TL;DR Active count off-by-one). R06 fix updated count from `5 P2 + 21 P3 = 26` → `6 P1 + 5 P2 + 20 P3 = 31` correctly — but TL;DR was not re-incremented as P4 closures landed (IMPL-054 → IMPL-059 each added a row). This is **the same off-by-N drift defender SKILL § 10-marker sweep marker #8 was designed to catch** ("TL;DR Active count vs `wc -l docs/state/deferred-ac-registry.md § Active`"). Either the marker was never implemented past the recommendation in rebuttal-round-06.md, or it was skipped during the 6 P4 closures since IMPL-053. `/deliver` block + `/impl-task` HALT trigger rely on accurate count; status agents reading TL;DR will under-report registry pressure heading into 2026-05-17 expiry hard-stop.

**Minimum acceptable fix:**
1. Update TL;DR line 8 to: *"Deferred-AC Active: 6 P1 + 5 P2 + 24 P3 + **8 P4** = **43 Active rows total** · expiry 2026-05-17 (P1/P2/most P3) and 2026-05-18 (IMPL-013 + IMPL-034 + IMPL-039 + all 8 P4 rows) · all blocked on IMPL-060 entry .mq5"*
2. Enumerate the 8 P4 rows briefly (IMPL-053/054/055/056/057/058/059 individual rows + IMPL-053..056 compound close-path row) เพื่อ skim-readers รู้ว่าไม่ใช่แค่ IMPL-053
3. Implement R06 marker #8 (TL;DR vs registry awk recount) เป็น mandatory step ใน `/impl-task` Phase 5 Closure ก่อน TL;DR rewrite — ไม่ใช่ at-review-time only

**Effort:** Low

---

#### Claim 07.3: 🟠 HIGH — TL;DR + Phase Status report `P4 7/11` but Phase × Size matrix locks P4=17 tasks

**Location:** `docs/state/impl-plan.md` line 5 (TL;DR `ตอนนี้:` row) + line 20 (Phase Status Snapshot row P4) + line 116 (Phase × Size matrix)

**Problem:**
Phase × Size matrix (line 116) ล็อก:

> *"P4: Cross-slot + Orchestrator + Verification | XS=1 | S=7 | M=8 | L=1 | XL=0 | **Total=17**"*

Risk distribution paragraph (line 119) ก็ระบุ "5 high-risk tasks total — IMPL-046 (P1), IMPL-022 + IMPL-039 (P3), **IMPL-062 + IMPL-063 (P4)**" → 17 P4 tasks ตรงกับ task list `IMPL-053..058 (6) + IMPL-059 + IMPL-060 + IMPL-017 + IMPL-061..068 (8) = 17` ตามที่ task body ของ P4 section นับด้วย.

แต่ TL;DR (line 5) บอก:

> *"P4 7/11 — bulk-close quartet + … — EA core surface complete pending IMPL-060 entry .mq5; remaining: IMPL-060 entry .mq5 + IMPL-017/061..068 QA"*

Phase Status row P4 (line 20): *"🔄 7/11 [x]"*.

`7/11` denominator drift: 7 closed (IMPL-053..059) + 10 remaining (IMPL-060, IMPL-017, IMPL-061..068) = **17**, ไม่ใช่ 11. TL;DR enumerates the remaining list correctly (IMPL-060 + IMPL-017/061..068 = 10 items) — แต่ตัวเลข `7/11` is wrong by 6.

**Why this matters:**
Three sections of the same plan now disagree on Phase 4 task count (matrix=17, narrative-list=17, headline=11). Status agents ใช้ TL;DR ก่อน → จะรายงาน "P4 64% complete" แทนที่จะเป็น "P4 41% complete" — **misleads MoSCoW + Phase Gate readiness assessment**. Same reconciliation defect class as Claim 06.4 R06 (off-by-one Active count) แต่ครั้งนี้ off-by-six บน Phase task count. ถ้า `/next` agent ใช้ TL;DR self-flag → จะ recommend P4 Gate sooner than ready.

**Minimum acceptable fix:**
1. Update TL;DR line 5: `P4 7/11` → `P4 7/17`
2. Update Phase Status row P4 (line 20) + entire `[x] N/M` references throughout plan: `7/11` → `7/17` (grep + replace)
3. Add `/impl-task` Phase 5 Closure check #11 to defender 10-marker sweep: **TL;DR Phase counts vs Phase × Size matrix totals**

**Effort:** Low

---

#### Claim 07.4: 🟠 HIGH — Plan Staleness Sentinel section is itself stale (says "2 closures since last review", TL;DR self-flags "10")

**Location:** `docs/state/impl-plan.md` line 1726 (Plan Staleness Sentinel `Closures since last review:` line) vs line 9 (TL;DR `Last updated` self-flag)

**Problem:**
Plan Staleness Sentinel section:

> *"**Closures since last review:** 2 (R06 closed 2026-05-03; +IMPL-039 + IMPL-034)"*

TL;DR last-action row:

> *"**Plan Staleness Sentinel = 10 closures since R06 — TRIPS THRESHOLD** → strongly recommend `/impl-plan-review all` before IMPL-060."*

10 closures since R06 = IMPL-039 + IMPL-034 + IMPL-013 + IMPL-053 + IMPL-054 + IMPL-055 + IMPL-056 + IMPL-058 + IMPL-057 + IMPL-059 (correct per audit-log dates 2026-05-03..04). The Sentinel section was last edited at IMPL-039 closure; never re-incremented for IMPL-034 (which it does count) → IMPL-013 → IMPL-053 → IMPL-054..057 → IMPL-058 → IMPL-059 (which it does **not** count).

**Why this matters:**
The Sentinel section is the **policy artifact** that triggers `/impl-plan-review all` recommendation. Engineer correctly self-flagged via TL;DR (which is why this review exists) but the Sentinel itself is stale → next status agent reading Sentinel section directly will say "only 2 closures, no review needed" while TL;DR contradicts it. Same `/next` Check 5.8 advisory infrastructure that protects against "approved-once-drift-forever" must update the **counter** atomically with each closure — otherwise the threshold check is meaningless.

**Minimum acceptable fix:**
1. Update Plan Staleness Sentinel line: `Closures since last review: 2 (...)` → `Closures since last review: 10 (R06 closed 2026-05-03; +IMPL-039 + IMPL-034 + IMPL-013 + IMPL-053 + IMPL-054 + IMPL-055 + IMPL-056 + IMPL-058 + IMPL-057 + IMPL-059) — THRESHOLD CROSSED — running claim-review-07 (this round) resets to 0`
2. Add **explicit increment step** to `/impl-task` Phase 5 Closure: bump Sentinel counter by 1 alongside TL;DR `Last updated` rewrite — ไม่ใช่ "narrative says, sentinel doesn't" pattern
3. After R07 rebuttal closes, reset to `0`

**Effort:** Low

---

### 🟡 MEDIUM

#### Claim 07.5: 🟡 MEDIUM — `overview.md § Impl Plan` Last Updated stuck at 2026-05-03 + status string still cites only R06 — ขัด State Reconciliation 3-file rule

**Location:** `docs/state/overview.md` line 19 (Impl Plan row)

**Problem:**
Overview row 19:

> *"Impl Plan | ✅ Implementation Execution Certified + R06 closure-discipline rebuttal closed | **2026-05-03** | …"*

ขณะที่ `impl-plan.md` มี 8 closures dated 2026-05-04 (IMPL-013, IMPL-053..059) + Mid-Phase Audit GREEN row 2026-05-04. CLAUDE.md §6 State Reconciliation Discipline requires 3-file propagation: (1) `impl-plan.md` (primary), (2) `overview.md` (derived count + phase status), (3) `{module}/handoff.md` + `_session-handoff/`. Engineer updated (1) and (3) (evidence files exist) but **not (2)** since 2026-05-03 R06 close.

**Why this matters:**
Same defect class as Plan Staleness Sentinel staleness (Claim 07.4) — different file. Per CLAUDE.md "Status reports + `/next` ต้อง reconcile ทั้ง 3 tiers" — overview.md drift causes status agents to under-report progress (P4 7/17 closed reads as "still at R06 baseline" if only overview.md consulted).

**Minimum acceptable fix:**
1. Update `overview.md § Impl Plan` row Last Updated: `2026-05-03` → `2026-05-04`
2. Update Status string: append summary `+ 8 closures 2026-05-04 (P3 IMPL-013 + P4 IMPL-053..059); P4 7/17 with Mid-Phase Audit GREEN; Plan Staleness Sentinel TRIPPED → claim-review-07 in progress`
3. Same propagation step ใน `/impl-task` Phase 5 Closure (already documented in CLAUDE.md §6 — engineer needs to actually run the `overview.md` edit, not just `impl-plan.md`)

**Effort:** Low

---

### 🔵 LOW

#### Claim 07.6: 🔵 LOW — TL;DR `Last updated` line has grown to ~1,200 words single paragraph spanning 10 closures — skim test fails

**Location:** `docs/state/impl-plan.md` line 9 (TL;DR `Last updated:`)

**Problem:**
หลัง 10 closures the `Last updated` row คือ paragraph เดียวที่กระจาย "last action / prior action / prior action / prior … / prior" ทุก task ตั้งแต่ IMPL-039 → IMPL-059. Stakeholder skim test (planner SKILL Phase 0 Empathy check) — reader อ่าน ≤30 seconds ไม่ทันได้ส่วน "what's next" ที่จริงสำคัญ (IMPL-060 entry .mq5 + 36+ deferred-AC unlock).

**Why this matters:**
TL;DR is the most-read section of the plan; growth pattern per-closure = unbounded. This is a soft readability issue (not load-bearing for engineer execution) but per planner SKILL §Readability — Reader Empathy guidance "TL;DR 3-5 บรรทัด".

**Minimum acceptable fix:**
1. After R07 rebuttal close, **trim** TL;DR `Last updated` to **only the most recent closure** (IMPL-059) + 1-line "since R06 (2026-05-03): closed P3 IMPL-013/034/039 + P4 IMPL-053..059 (10 closures total)"
2. Move detailed prior-action narratives → Mid-Phase Audit Log (which already has them duplicated; remove duplication when trimming)
3. Defender SKILL convention extension: **TL;DR last-action max 200 words; longer history → Audit Log only**

**Effort:** Medium (text consolidation; needs care not to lose unique facts that aren't in audit log)

---

## Cross-Document Issues

ไม่พบ contradictions ข้าม `docs/design-docs/` หรือ `docs/technical-design/` — ทุก finding scoped within `docs/state/` triplet (impl-plan.md, overview.md, deferred-ac-registry.md).

Two **registry hygiene observations** (not raised as findings — within tolerance):
- 6 P1 rows + 4 P2 rows + 19 P3 rows expire 2026-05-17 (10 days from now); 8 P4 rows + 3 P3 rows expire 2026-05-18. Open Risk R-6 already tracks; no new finding.
- IMPL-039 deferred-AC row text mentions "IMPL-039 commit hash to be substituted on commit landing" — engineer should run `git log --grep IMPL-039` after PR lands (defender marker #10 already covers).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 07.1 | 🔴 CRITICAL | Forbidden closure pattern regression in 2026-05-04 audit-log row | `impl-plan.md` line 1636 | Low + Medium (workflow change) |
| 07.2 | 🟠 HIGH | TL;DR Deferred-AC Active count off by 7 (36 vs 43) | `impl-plan.md` line 8 | Low |
| 07.3 | 🟠 HIGH | TL;DR + Phase Status `P4 7/11` denominator wrong (should be 7/17) | `impl-plan.md` lines 5, 20 | Low |
| 07.4 | 🟠 HIGH | Plan Staleness Sentinel section stale (says 2, actual 10) | `impl-plan.md` line 1726 | Low |
| 07.5 | 🟡 MEDIUM | `overview.md § Impl Plan` Last Updated stuck at 2026-05-03 | `overview.md` line 19 | Low |
| 07.6 | 🔵 LOW | TL;DR `Last updated` paragraph ~1,200 words — skim test fails | `impl-plan.md` line 9 | Medium |

---

## Recommendation

Run `/impl-plan-rebuttal claim-review-07.md` to resolve all 6 findings before `/impl-task IMPL-060`. Most fixes are mechanical text edits (07.2/07.3/07.4/07.5/07.6); 07.1 needs both text reword **and** engineer-side workflow change (R06 recommendation #1 — finally implement the forbidden-pattern grep gate ใน `/impl-task` Phase 5).

**Convergence trajectory observation:** R01=7 → R02=3 → R03=3 → R04=0 → R05 skipped → R06=7 (regression) → R07=6 (still elevated). Pattern suggests rebuttal-only workflow ไม่พอ — need engineer-side mechanical gates ใน `/impl-task` Phase 5 Closure (forbidden-pattern grep + TL;DR ↔ registry recount + TL;DR ↔ matrix denominator + Sentinel counter increment + overview.md sync). Otherwise R08+ will keep surfacing the same defect classes per-closure-burst.

— Implementation Plan Reviewer (Adversarial Tech Lead)
2026-05-04
