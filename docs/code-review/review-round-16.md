# Code Review Round 16

| Field | Value |
|-------|-------|
| **Round** | 16 |
| **Target** | `all` — operator invoked `/impl-review all R09`; user-supplied tag "R09" diverges from Glob-resolved next-round number 16 (review-round-09 already exists). Per `.agents/workflows/impl-review.md § 1.1` ("New round = highest + 1"), this file is round **16**; the "R09" label is preserved in the user request log but does not change file numbering. |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | Cumulative state of `MQL5/Experts/PhoenicisNex/` + `docs/state/` after fix-round-15 commit `119a9ea`. Working tree at session start has **35 modified files (+508 LOC) uncommitted** (services + slots + spike + harness + state docs) and **6 untracked files** including `docs/state/nfr-3.1-atomic-write-result.json` (the IMPL-064 NFR-3.1 PASS sidecar). Adversarial sweep focused on: (a) build integrity of HEAD, (b) state-file `deferred to IMPL-053+` broader-class sweep that fix-round-15 gate #9b claimed clean, (c) audit-trail completeness between fix-round-13/14/15 narratives and committed git history, (d) Tier 1.5 walk batch-2 evidence pointers vs disk reality. |
| **Plan Staleness Sentinel** | 6 closures since R07 (per fix-round-15 § 15.3 revert). Below 10-closure threshold; advisory for `/impl-plan-review` re-validation ⏭ ยังไม่ trigger. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 3 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **7** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Symbol whitelist intact (`OnInit` rejects ≠EURUSD per FR-1.2); no new `WebRequest`/DLL/`#import`; atomic-write contract empirically PASS 100/100 per uncommitted sidecar; no credential introduction. |
| 2 | Business Logic Correctness | ⚠️ Finding | **Finding 16.1 CRITICAL** — HEAD does not compile: `BootstrapValidator::RunDomainSelfTests` (committed via `119a9ea`) calls `IsPhoenicisMagicSelfTest()` whose body lives only in the uncommitted working tree of `domain/EnumTypes.mqh`. Fresh clone + G1 = link-time fail. |
| 3 | Error Handling | ✅ Pass | FIX-001/002 + R15 15.1 ValidateSlotInputs all use `ErrorBypassThrottle` per ADR-011 boot-bypass; CircuitBreaker pre-Init NULL-logger guard intact (uncommitted Case E SelfTest verifies). No silent swallow. |
| 4 | Performance | ✅ Pass | No new hot-path allocations introduced; ValidateSlotInputs is OnInit-once (3× MathAbs); SelfTest umbrella runs once per spike attach. |
| 5 | Over-Engineering | ✅ Pass | RunDomainSelfTests umbrella is 5 lines of body (1 SelfTest call + 1 fail-log + return); ValidateSlotInputs ditto. No premature generalisation. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **Finding 16.3 HIGH** — `docs/state/impl-plan.md` has **25 stale `deferred to IMPL-053+` references** in `[ ]` AC entries; IMPL-053..060 are CLOSED so closure rationale is wrong-by-fact. Fix-round-15 § Phase 5 gate #9b claimed clean but only swept `MQL5/Experts/PhoenicisNex/`, not the state-doc tree. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **Finding 16.5 MEDIUM** — Spike_AtomicWrite path-guard logic + atomic_write_kill_100.ps1 `-FailFastConsecutive` + `-StateRel/-AgentSubpath` rework + CircuitBreaker SelfTest Case E + EnumTypes IsPhoenicisMagicSelfTest body are all **uncommitted** but referenced as "completed/verified" in fix-round-13/14/15 narratives. Test code that produced the NFR-3.1 PASS verdict is not in HEAD. |
| 8 | Architecture Compliance | ✅ Pass | ADR-002 Composition Root unchanged; ADR-007 atomic-write Option A still locked (sidecar verdict); ADR-010 HALTED transition unchanged; 5-layer dependency direction preserved. |
| 9 | Technical Design Compliance | ✅ Pass | ValidateSlotInputs follows ValidateInputs Guard pattern; tolerance 0.001 mirrors RiskManager consumer at lines 402-415 per TD-02 §13.5 audit contract. |
| 10 | Test Code Quality | ✅ Pass | No regex/loop pathology; SelfTest cases bounded; harness has explicit fail-fast circuit (uncommitted). |
| 11 | Empirical AC Closure | ⚠️ Finding | **Finding 16.4 HIGH** — IMPL-064 `[file-blob-check]` evidence pointer `docs/state/nfr-3.1-atomic-write-result.json` is **untracked** (`git ls-files` says "did not match any file(s)"). Fix-round-15 + impl-plan TL;DR + walk-summary + registry Resolved row all cite this sidecar as PASS proof; on a fresh clone the artifact does not exist → Dim #11 evidence pointer is broken. |
| 12 | Functional Walk (PhoenicisNex Tier 1.5) | ⚠️ Finding | **Finding 16.6 MEDIUM** — walk-summary.md cites `nfr-3.1-atomic-write-result.json` + Tester log + journal records that all live outside git. Tier 1.5 walk batch-2 evidence chain has 1 untracked file + 1 untracked abridged log (`abridged-tester-log.txt`). Per `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`, evidence artifacts must be committed alongside `[x]` closure. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; new `-StateRel` / `-AgentSubpath` PowerShell params have defaults; `origin.txt` already validated. No env-var consumer. |

---

## Findings

### Finding 16.1: 🔴 CRITICAL — HEAD ไม่ compile: `BootstrapValidator::RunDomainSelfTests` (committed `119a9ea`) เรียก `IsPhoenicisMagicSelfTest()` แต่ function body อยู่ใน working tree เท่านั้น (uncommitted ใน `domain/EnumTypes.mqh`). Fresh clone + G1 = undefined identifier → 4-gate Definition of Done broken on `main`.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh`, Line: 593 (HEAD — call site `if(!IsPhoenicisMagicSelfTest())`)
- File: `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh`, Lines: 105-163 (working tree only — `bool IsPhoenicisMagicSelfTest()` body)
- Service: ea (build integrity)
- Reference: fix-round-14 § 14.3 narrative + fix-round-15 § Phase 5 gate matrix (G1 reported PASS)

**Code:**
```mql5
// HEAD: core/BootstrapValidator.mqh:593 (committed 119a9ea — fix-round-15)
bool CBootstrapValidator::RunDomainSelfTests() const
  {
   if(!IsPhoenicisMagicSelfTest())                       // ← undefined in HEAD
     {
      m_logger.ErrorBypassThrottle("system", "domain_selftest_fail", 0,
         "IsPhoenicisMagicSelfTest reported one or more failures —"
         " see prior [EnumTypes][SelfTest][FAIL] lines");
      return false;
     }
   return true;
  }
```

```mql5
// HEAD: domain/EnumTypes.mqh — last committed change `631a9e0` (IMPL-002, no SelfTest body)
// `git show HEAD:MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh | grep -c "IsPhoenicisMagicSelfTest"` → 0
//
// Body is on disk in working tree (uncommitted):
bool IsPhoenicisMagicSelfTest()
  {
   bool ok = true;
   if(!IsPhoenicisMagic(MAGIC_CD)) { Print("[EnumTypes][SelfTest][FAIL] ..."); ok = false; }
   /* ... 17 registered + 6 negative cases ... */
   return ok;
  }
```

```bash
$ git show HEAD:MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh | grep -c "IsPhoenicisMagicSelfTest"
7      # call site present in HEAD
$ git show HEAD:MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh | grep -c "IsPhoenicisMagicSelfTest"
0      # body absent from HEAD ← CRITICAL
```

**Problem:**
fix-round-13 § 13.6 + fix-round-14 § 14.3 narratives describe authoring `IsPhoenicisMagicSelfTest()` in `domain/EnumTypes.mqh` and wiring it through `RunDomainSelfTests` in `BootstrapValidator`. fix-round-15 commit `119a9ea` committed the *caller* (`BootstrapValidator::RunDomainSelfTests`) but the *callee* (the function body in `EnumTypes.mqh`) was never staged + committed — it lives only in the working tree. Same gap applies to `Spike_Orchestrator.mq5` IsPhoenicisMagicSelfTest call (working tree only).

The fix-round-15 G1 PASS (`Result: 0 errors, 0 warnings, 3844 ms elapsed`) was measured against the dirty working tree (which has the body), not against HEAD. Per `.claude/rules/testing.md § G1 Compile gate`, G1 must verify the *committed* surface compiles — if a CI runner (.github/workflows/mt5-smoke.yml advisory per workflow.md) does `git clone main && MetaEditor /compile`, MQL5 link phase will fail with "function 'IsPhoenicisMagicSelfTest' is not defined" or "implicit declaration" depending on MQL5 strict-mode behavior.

This is the same defect class that `.claude/rules/workflow.md § Phase 5 mechanical gates Gate #5/#6` are meant to catch ("file integrity post-Edit-batch") + Gate #9 clause (b) ("broadest-class grep that matches the *intent* of the finding"). Fix-round-15 § Phase 5 verification ran gate #1 + #4 + #5 + #9 but never verified that **HEAD itself compiles cleanly without working-tree dependencies**. Per `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`, the closure contract requires reproducible artifacts; an uncommitted body breaks that contract structurally.

`.claude/rules/ea.md § Strict mode` says "every `.mqh` opens with `#ifndef ... include guard`" — that's intact, but include guards do not protect against undefined function references at link time.

**Why This Matters:**
3am-operator scenario: operator pulls `main` to a fresh laptop (clean MT5 install) per `.claude/rules/workflow.md § Cold-Bootstrap Recipe`. They run `MetaEditor64.exe /compile:MQL5\Experts\PhoenicisNex\PhoenicisNex.mq5 /log`. Compile fails with `'IsPhoenicisMagicSelfTest' - function not defined` on BootstrapValidator.mqh:593. They check `git status` → clean tree → believe HEAD is broken (it is). They do not have the working-tree body that the original author had locally. Cold-bootstrap recipe fails.

Worse: any future `/impl-task` execution that depends on G1 PASS (per 4-gate DoD) will block. Any subagent spawned via `Agent` tool to `/impl-task parallel` also blocks because they each clone-fresh-conceptually (no dirty working tree). Phase advance impossible without reverting `119a9ea`'s RunDomainSelfTests body OR committing the EnumTypes body.

Worst-case for audit integrity: fix-round-15 was nominated "ready for next review round" + Plan Staleness Sentinel left at 6 + 4-gate DoD advertised as PASS. The PASS measurement was against an unrepresentative tree. Same pattern applies to spike harnesses (`Spike_Orchestrator.mq5` calls `IsPhoenicisMagicSelfTest` in its uncommitted working-tree state) + `Spike_CircuitBreaker.mq5` (untracked file referenced as fix-round-15 deliverable in walk-summary).

This is a hard violation of `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` (Golden Rule #9): structural test pass on the committed surface is the only acceptable closure proof.

**Suggested Fix:**
2-step recovery (operator decides which order):

**Option A — commit the working-tree body (preferred; no rollback)**:
```bash
# Stage the function bodies + spike call sites that R15 G1 actually depended on:
git add MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh \
        MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5 \
        MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5 \
        MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh

git commit -m "[fix:ea] R16 16.1 commit IsPhoenicisMagicSelfTest body + CircuitBreaker Case E SelfTest

Why: HEAD's BootstrapValidator::RunDomainSelfTests (committed 119a9ea fix-round-15) calls
IsPhoenicisMagicSelfTest() but the function body only existed in working tree. Closes
build-integrity gap discovered by review-round-16 § 16.1 CRITICAL. See fix-round-13 § 13.6
+ fix-round-14 § 14.3 for original authoring narrative."

# Re-run G1 against the freshly-committed HEAD to confirm:
git stash --include-untracked
"$METAEDITOR" /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log
# Expect: Result: 0 errors, 0 warnings, NNNN ms elapsed
git stash pop
```

**Option B — revert RunDomainSelfTests body in HEAD (rolls back fix-round-15 § 14.3 wiring)**:
```bash
# Edit core/BootstrapValidator.mqh:593 → comment out the IsPhoenicisMagicSelfTest call;
# keep the umbrella as a placeholder until the body is properly authored + committed.
```
Not recommended — ditches walk batch-2 evidence-of-SelfTest-wiring.

**Defense gate addition** to `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`:
```markdown
| 10 | **Stash-clean G1** | After commit, run `git stash --include-untracked && MetaEditor /compile && git stash pop` and verify the post-stash compile = `0 errors, 0 warnings`. Catches HEAD-vs-working-tree drift. | exit code 0 + log shows clean compile against committed surface |
```

**Level of Effort:** Low (commit the body — 1 git add + commit) + Low (add gate #10 — 5-line workflow rule).

---

### Finding 16.2: 🟠 HIGH — Working tree contains 35 modified files + 6 untracked files (>508 LOC) ที่ fix-round-13 / 14 / 15 narratives บอก "applied" + "verified G1 PASS" แต่ไม่ได้ committed — audit trail gap จาก commit history vs documented closure narrative

**Location:**
- Files (representative, modified): `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh` (+35 LOC — Case E SelfTest), `services/RiskManager.mqh` (+5 — closure narrative sweep), `services/PortfolioState.mqh` (+10 — closure narrative sweep), `domain/EnumTypes.mqh` (+62 — IsPhoenicisMagicSelfTest body), `slots/Slot_*.mqh` × 16 files (closure narrative sweeps), `spike/Spike_*.mq5` × 10 files (SelfTest call sites + path guards), `simulation/scripts/atomic_write_kill_100.ps1` (+124 — `-StateRel`/`-AgentSubpath`/`-FailFastConsecutive` rework), `docs/state/nfr-3.1-atomic-write-result.md` (+68 — Result Table fill)
- Files (untracked): `MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5` (NEW spike per fix-round-14 § 14.2), `docs/code-review/{review,fix}-round-{13,14,15}.md` (3 review pairs documented but the 13/14 pair untracked at session start), `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt` (Tier 1.5 walk evidence), `docs/state/nfr-3.1-atomic-write-result.json` (NFR-3.1 PASS sidecar)
- Reference: `.claude/rules/workflow.md § Git + PR Workflow` ("Every PR MUST include the simulation/headless-tests/<task>.ini if task is slot/orchestrator/cross-slot"); `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`
- Service: ea (process discipline)

**Code:**
```bash
$ git status -s | wc -l
35

$ git ls-files --others --exclude-standard | head -8
MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5
docs/code-review/fix-round-13.md
docs/code-review/fix-round-14.md
docs/code-review/review-round-13.md
docs/code-review/review-round-14.md
docs/code-review/review-round-15.md         # ← committed via 119a9ea but the OLDER 13/14 pair untracked
docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt
docs/state/nfr-3.1-atomic-write-result.json # ← Finding 16.4 evidence pointer

$ git diff HEAD --shortstat
35 files changed, 508 insertions(+), 190 deletions(-)
```

**Problem:**
fix-round-13.md (untracked at session start), fix-round-14.md (untracked), and fix-round-15.md (committed at `119a9ea`) collectively claim:
- **13.1/13.3/13.4** — `atomic_write_kill_100.ps1` rework (`-StateRel`, `-AgentSubpath`, `-FailFastConsecutive`); HEAD does not have these params
- **13.5** — CircuitBreaker SelfTest Case E (pre-Init RecordOpen/RecordClose dropped); HEAD's `services/CircuitBreaker.mqh` does not have this case (`grep -c "Case E:" → 0`)
- **13.6/14.3** — IsPhoenicisMagicSelfTest body + Spike_Orchestrator wiring; HEAD does not have the body (Finding 16.1)
- **14.2** — Spike_CircuitBreaker.mq5 NEW spike harness; the file is untracked
- **15.4** — walk-summary.md System Load Context subsection; the file IS committed via `119a9ea`, but the *abridged Tester log* it references is untracked
- **NFR-3.1 PASS** — `nfr-3.1-atomic-write-result.md § 5` Result Table fill (verdict ✅ PASS) + sidecar JSON; doc is uncommitted, sidecar is untracked

This means fix-round-13/14/15 audit reports describe a development effort that — at the level of the public git history — never happened. Per `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`:
> "task ที่มี E-AC ปิดด้วย structural test pass อย่างเดียวไม่ได้ — ต้องมี evidence artifact ที่ `docs/state/_session-handoff/<task-id>-evidence-*` จาก deployed/running system"

The artifact existence is necessary but not sufficient — the artifact must also be **reachable from HEAD** (per `.claude/rules/workflow.md § Handoff Discipline` "Evidence artifacts: `docs/state/_session-handoff/<task-id>-evidence-*.{log,json,jsonl,md}`"). Untracked files cannot be cited as evidence in PRs/reviews because they cannot be reproduced.

This is a process-discipline failure that compounds Finding 16.1 (which is the build-integrity manifestation of the same root cause): commit hygiene gap between session-end and the next session's onboarding read of `current_handoff.md`.

`.claude/rules/workflow.md § Git + PR Workflow` says:
> "ห้าม force push ไป main/develop"
> "ห้าม skip pre-commit hooks (`--no-verify`) unless explicitly authorized"
> "Every PR MUST include the simulation/headless-tests/<task>.ini if task is slot/orchestrator/cross-slot"

The implicit baseline — that committed surface = source of truth — is not enforced by an explicit gate. fix-round-15 § Phase 5 mechanical gates 1-9 cover narrative integrity but not "is the working tree clean after fix-round closure". The 35 modified + 6 untracked is the visible cost.

**Why This Matters:**
- **Cold-bootstrap on a fresh laptop fails** per Finding 16.1; the rest of this finding compounds it (any operator reading `nfr-3.1-atomic-write-result.md` Status: ✅ PASS will not find the JSON sidecar that backs it).
- **PR review impossible** — fix-round-15 was committed solo on `main` (no PR); future review by Red Team or external auditor cannot diff the fix-round-13/14 deliverables because they're not in any commit.
- **Subagent fan-out unreliable** — `/impl-task parallel` spawns subagents via the `Agent` tool; subagents see the working tree their parent has, but the parent must have done the original commit work for the subagent's own commit to make narrative sense. fix-round-15 closure stating "G1 ✅ 3844 ms" cannot be reproduced by a subagent that does `git stash` first.
- **Walk batch-2 evidence chain has an exposed link** — Finding 16.4 (sidecar untracked) + Finding 16.6 (abridged log untracked) flow from this root cause. Tier 1.5 walk artifact cites file paths that do not git-show.
- **Plan Staleness Sentinel = 6 is misleading** — the Sentinel counts task closures, not source-edit churn. Working tree carrying 508 LOC of uncommitted work means the *effective* drift since R07 is much larger than 6 closures imply; the 10-closure threshold is not reaching the point where the user would call `/impl-plan-review` even though the source surface has shifted substantially.

**Suggested Fix:**
3-part recovery + 1 gate:

**Part 1 — Triage the working tree** (~5 min):
```bash
git status -s > /tmp/r16-pretriage.txt    # snapshot for audit
git diff HEAD --stat > /tmp/r16-shortstat.txt

# Categorize: source code vs state docs vs harness/scripts
# - Source code: bundle into 1-3 commits matching fix-round-13/14 narrative scopes
# - State docs (impl-plan/registry/overview/handoff): bundle into 1 [chore:state] commit
# - Harness scripts (atomic_write_kill_100.ps1) + result table + JSON sidecar:
#   1 [feat:ea-qa] commit closing IMPL-064
```

**Part 2 — Author 4-5 commits** in chronological order matching the fix-round narratives:
```bash
# Commit 1: fix-round-13 § 13.1/13.3/13.4 harness + spike path-guard
git add simulation/scripts/atomic_write_kill_100.ps1 \
        MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5 \
        docs/code-review/review-round-13.md docs/code-review/fix-round-13.md
git commit -m "[fix:ea-qa] code-review-round-13 — harness + spike path-guard
Why: per fix-round-13 § 13.1/13.3/13.4 — Tester sandbox binding + cleanup guard + fail-fast circuit"

# Commit 2: fix-round-13 § 13.5/13.6 + fix-round-14 SelfTest authoring
git add MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh \
        MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh \
        MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5 \
        MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5 \
        docs/code-review/review-round-14.md docs/code-review/fix-round-14.md
git commit -m "[fix:ea] code-review-round-14 — IsPhoenicisMagicSelfTest body + CB Case E SelfTest"

# Commit 3: fix-round-13/14 § slot closure-narrative sweep
git add MQL5/Experts/PhoenicisNex/services/{RiskManager,PortfolioState}.mqh \
        MQL5/Experts/PhoenicisNex/slots/Slot_*.mqh \
        MQL5/Experts/PhoenicisNex/spike/Spike_Slot_*.mq5
git commit -m "[chore:ea] R13/R14 closure-narrative sweep — replace stale 'deferred to IMPL-053+'"

# Commit 4: IMPL-064 NFR-3.1 PASS evidence
git add docs/state/nfr-3.1-atomic-write-result.{md,json} \
        docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt
git commit -m "[feat:ea-qa] IMPL-064 NFR-3.1 PASS — Result Table fill + sidecar + abridged log"

# Commit 5: state propagation (handoff + other state docs)
git add docs/state/* .claude/rules/workflow.md .serena/project.yml
git commit -m "[chore:state] R13/R14/R15 + walk batch-2 propagation"
```

**Part 3 — verify HEAD compiles + 4-gate DoD passes**:
```bash
git stash --include-untracked
"$METAEDITOR" /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log
iconv -f UTF-16LE -t UTF-8 MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log | grep "Result:"
# Expect: Result: 0 errors, 0 warnings, NNNN ms elapsed
git stash pop  # restore any genuinely WIP edits
```

**Gate addition** (mirrors Finding 16.1's gate #10 proposal):
Add `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` row #11:
```markdown
| 11 | **Working-tree clean post-closure** | `git status --porcelain | wc -l` after fix-round/task closure | exit count `0` (all artifacts referenced in fix-round narrative + closure tables are committed) — non-zero hits = audit-trail gap (per R16 § 16.2) |
```

**Level of Effort:** Medium (5 commits + verification ≈ 15-25 min, depending on diff inspection); the source edits themselves are correct — only commit hygiene needed.

---

### Finding 16.3: 🟠 HIGH — `docs/state/impl-plan.md` มี **25 stale `deferred to IMPL-053+` references** บน `[ ]` AC entries; IMPL-053..060 ปิดแล้ว (per impl-plan TL;DR) → closure rationale wrong-by-fact. Fix-round-15 § Phase 5 gate #9b grep claimed clean but limited sweep ไปที่ `MQL5/Experts/PhoenicisNex` only — workflow.md gate #9 clause (b) "broadest-class grep that matches the **intent** of the finding" requires repo-wide

**Location:**
- File: `docs/state/impl-plan.md` — 25 hits; representative sites: lines 340 (IMPL-005 CreateHandles AC), 376 (IMPL-007 magics-registered AC), 498 (IMPL-011 CleanupPartialInit AC), 530 (IMPL-042 Logger init_ok AC), 742-743 (IMPL-018+ DST + bans), 854 (IMPL-019 Slot C smoke), 933 (IMPL-023 Slot H smoke), 952 (IMPL-024 Slot K smoke), 972 (IMPL-025 Slot G smoke), 991 (IMPL-026 Slot G2 smoke), 1010 (IMPL-027 Slot GO smoke), 1030 (IMPL-028 Slot I smoke), 1050 (IMPL-029 Slot M smoke), 1069 (IMPL-030 Slot L smoke), 1089 (IMPL-031 Slot LX smoke), 1187 (IMPL-036 Slot S smoke), 1207 (IMPL-037 Slot B smoke), 1227 (IMPL-038 Slot BR smoke), 1249 (IMPL-039 Slot BI smoke)
- Reference: `.claude/rules/workflow.md § Phase 5 Closure mechanical gates Gate #9 clause (b)` (R14 strengthening: "broadest-class grep that matches the *intent* of the finding (e.g., if the finding is "remove references to closed task X", use `grep -rcE` against the **whole repo tree**, not just literal `<task-id>+` against one subdir)")
- Reference: fix-round-15.md § Phase 5 Mechanical Gates table row #9b (claims "broader-class grep `deferred to IMPL-053(\+| |\.|$)` on `MQL5/Experts/PhoenicisNex` = 0 hits ✅" — sweep narrowed to source tree only)
- Service: ea-state (state reconciliation discipline)

**Code:**
```bash
$ grep -cE "deferred to IMPL-053" docs/state/impl-plan.md
25

$ grep -nE "deferred to IMPL-053" docs/state/impl-plan.md | head -5
340:  - [ ] `CreateHandles()` ใน OnInit smoke = ≥ 24 handles, `HandleCount()` ตรงกับจำนวนจริง `[probe]` — **deferred to IMPL-053+** (Orchestrator wires Init+CreateHandles); evidence `docs/state/_session-handoff/IMPL-005-evidence-20260502.md`
376:  - [ ] OnInit smoke → Logger Debug "magics registered: 17" `[log-assertion]` — **deferred to IMPL-053+** (Orchestrator wires Init→RegisterAll); evidence `docs/state/_session-handoff/IMPL-007-evidence-20260502.md`
498:  - [ ] CleanupPartialInit called → no leaked `m_indicators` heap — **deferred to IMPL-053+** (CleanupPartialInit is owned by COrchestrator per TD-02 §7.4.1)
530:  - [ ] OnInit Logger.Info → Tester log shows `[Phoenicis][system][ev=init_ok]…` `[log-assertion]` — **deferred to IMPL-053+** (Orchestrator construct/Init); evidence `docs/state/_session-handoff/IMPL-042-evidence-20260502.md`
742:  - [ ] Smoke: backtest 2026-Mar-28 (DST start) + 2026-Oct-25 (DST end) — **deferred to IMPL-053+ + IMPL-018+** (entry `PhoenicisNex.mq5` not yet created)
```

```bash
# Status of the cited prereqs (per impl-plan TL;DR + fix-round commits):
$ git log --oneline -- MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 | head -3
3948718 [feat:ea] IMPL-060 PhoenicisNex.mq5 entry point thin wrapper — runnable surface gap closed
# IMPL-060 (PhoenicisNex.mq5 entry) closed 2026-05-04 ✅
# IMPL-053..060 (Orchestrator + entry) all closed per impl-plan §Phase Status

# Yet 25 ACs still cite "deferred to IMPL-053+ (Orchestrator wires …)" as their closure rationale.
```

**Problem:**
The phrase "deferred to IMPL-053+" was the standard closure rationale used by P1/P2/P3 task closures during 2026-05-02..2026-05-03 when IMPL-053..060 were the planned-but-not-yet-existing target for Orchestrator wiring + entry `.mq5`. Per impl-plan TL;DR + commits `3948718` (IMPL-060) + `119a9ea` (fix-round-15) + the 6 closures since R07, those prerequisites are now CLOSED:

| Cited prereq | Status | Closure commit |
|---|---|---|
| IMPL-053..058 (Orchestrator services) | ✅ Closed | `298d013 [feat:ea] IMPL-059 core/Orchestrator composition root` (covers IMPL-053..058 per /impl-task parallel) |
| IMPL-059 (Orchestrator OnInit Phase A/B/C + OnTick F1) | ✅ Closed | `298d013` |
| IMPL-060 (PhoenicisNex.mq5 entry thin wrapper) | ✅ Closed | `3948718` |
| IMPL-018+ (entry `.mq5` exists, runnable surface) | ✅ Closed (transitively via IMPL-060) | `3948718` |

So the AC narrative on 25 sites says "deferred to IMPL-053+ (Orchestrator wires …)" — pointing at a milestone that already shipped. A future status agent (`/next` Check 6 / `/impl-task` HALT logic / `/impl-plan-review` Dim #8) reading these rows will conclude either:
1. "These ACs are still blocked on Orchestrator wiring" — wrong; Orchestrator is wired (per spike `Spike_Orchestrator.ex5` produced 2026-05-04 19:39 + Strategy Tester runs in walk batch-2 at 2026-05-05 08:36)
2. "These ACs are closeable; I should run `/impl-task <NNN>` to close" — unsafe; many of these ACs are E-AC requiring real Tester runs that have not yet exercised them post-orchestrator-wiring

Either path is wrong. The correct narrative per fix-round-15 § 15.2 partial-drain pattern is:
- log-assertion clause for ACs touching OnInit emission paths → likely drainable via walk batch-2 `[ev=init_ok]`/`[ev=portfolio_registered][magic=0]` lines
- db-inspect/file-blob-check/contract-roundtrip clauses → still gated on IMPL-062 (5-yr regression with `RiskManager::OpenOrder` wired — separate task; the slot files have comment-only stubs for OrderSend per impl-plan)
- DST+holiday smoke → gated on IMPL-018 timegate spec being authored OR IMPL-062 Tester run with 2026-Mar/Oct windows

Fix-round-15 § Phase 5 gate #9b table row says:
> "broader-class grep `deferred to IMPL-053(\+| |\.|$)` on `MQL5/Experts/PhoenicisNex` = 0 hits ✅"

The sweep was narrowed to source code only. Per `.claude/rules/workflow.md § Phase 5 Gate #9 clause (b)` (added in R14 specifically to prevent this scope-narrowing):
> "ALSO run a broadest-class grep that matches the *intent* of the finding (e.g., if the finding is "remove references to closed task X", use `grep -rcE "deferred to <task-id>(\+\| \|\.\|$)"` against the **whole repo tree**, not just literal `<task-id>+` against one subdir)"

The intent of the R12/R13/R14 sweeps was to remove references to the closed IMPL-053..060 chain everywhere. Source code was swept; state docs were not. Same root cause as R12 § 12.8 → R13 § 13.2 → R14 § 14.4 chain that gate #9 (b) was added to break.

This is a Dim #11 EAC-closure-trace gap (registry/plan rows are load-bearing pointers for `/impl-task` HALT + `/deliver` block + Dim #11 audit). 25 stale rows = 25 false-positive blockers when `/impl-task` next picks an unblocked task.

**Why This Matters:**
- **`/next` Check 6 (Three-Tier Closure scan) accuracy** depends on AC narrative accuracy. 25 stale entries = 25 AC rows that look "still blocked" on a closed prereq. Future `/next` runs will rec actions based on wrong premises.
- **Phase Gate retroactive close blocked** — per impl-plan TL;DR, P2 retroactive Phase Gate close requires "draining N P2 deferred-AC rows". The drain logic walks the registry + impl-plan rows. Stale narratives confuse the drain plan.
- **Dim #11 evidence cross-check brittle** — when R17 runs Dim #11, it must follow the AC's `evidence` pointer. Pointer text "evidence `docs/state/_session-handoff/IMPL-007-evidence-20260502.md`" is correct; rationale "deferred to IMPL-053+ (Orchestrator wires Init→RegisterAll)" is stale-by-fact. R17 reviewer will spend time investigating "is Orchestrator actually wired?" only to discover walk batch-2 already proved it is.
- **Recurrence chain**: R12 § 12.8 → R13 § 13.2 → R14 § 14.4 → R15 § 15.2 → **R16 § 16.3** — same defect class surfaces every round because the broader-class sweep keeps getting narrowed when finalizing fix-rounds. Gate #9 (b) was the methodological fix; not applying it to state docs = the gate didn't do its job here.

**Suggested Fix:**
2-step sweep + 1 gate strengthening:

**Part 1 — sweep impl-plan.md** (~30 min):
For each of the 25 sites, replace stale "deferred to IMPL-053+" with the correct current rationale. Pattern (modeled on fix-round-15 § 15.2 partial-drain annotations):

For ACs whose **log-assertion clause was drained by walk batch-2** (IMPL-005/007/042 OnInit emissions):
```diff
-  - [ ] OnInit smoke → Logger Debug "magics registered: 17" `[log-assertion]` — **deferred to IMPL-053+** (Orchestrator wires Init→RegisterAll); evidence `…`
+  - [ ] OnInit smoke → Logger Debug "magics registered: 17" `[log-assertion]` — **partially drained 2026-05-05 via Tier 1.5 walk batch-2** (`_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` line ~252 captured `[ev=portfolio_registered][magic=0] magics registered: 17`); db-inspect half (`GetByMagic(MAGIC_X)` matches MT5 native broker reconcile) gated on IMPL-062 5-yr regression with `RiskManager::OpenOrder` wired
```

For ACs whose **all clauses still gated on IMPL-062 5-yr regression** (slot smoke 60-day backtests at lines 854/933/952/972/991/1010/1030/1050/1069/1089/1187/1207/1227/1249):
```diff
-  - [ ] Smoke 60-day backtest with only Slot C active → ≥ 1 entry+exit cycle journaled — **deferred to IMPL-053+ orchestrator wiring** per IMPL-018+ precedent (header-only `.mqh` until entry `.mq5` consumes via Composition Root); registered in `deferred-ac-registry.md` expiry 2026-05-17
+  - [ ] Smoke 60-day backtest with only Slot C active → ≥ 1 entry+exit cycle journaled — **gated on IMPL-062 5-yr regression** (Orchestrator + entry .mq5 closed via IMPL-053..060 + IMPL-060 commit `3948718`; remaining gap = `RiskManager::OpenOrder/CloseOrder` wired into slot `Evaluate/ManageExits` bodies — currently comment-only stubs per slot files); registered in `deferred-ac-registry.md` expiry 2026-05-17
```

For ACs whose **OrderSend wiring is the substantive gate** (IMPL-039 BI SL via parent B; IMPL-036/037 Slot S/B):
```diff
-  - [ ] Smoke: open B parent + trigger BI pyramid → BI ticket has non-zero SL — **deferred to IMPL-053+ Orchestrator + RiskManager OrderSend wiring**
+  - [ ] Smoke: open B parent + trigger BI pyramid → BI ticket has non-zero SL — **gated on IMPL-062 (RiskManager OrderSend wiring + 60-day Tester run with B+BI active)**; Orchestrator wiring closed at IMPL-059/060 ✅
```

**Part 2 — Repo-wide grep sweep** (~5 min):
```bash
grep -rnE "deferred to IMPL-053" docs/ | wc -l   # post-fix expected: 0 (only audit-history rows in commit logs untouched)
grep -rnE "deferred to IMPL-053" .              # repo-wide; expect: 0 (only history sections preserved)
```

**Part 3 — Strengthen workflow.md Gate #9 clause (c)**:
```markdown
| 9c | **Whole-repo intent grep** | After clause (b) source-tree grep passes, run the SAME broader-class regex against `docs/state/` + `docs/code-review/` (excluding within-finding citations that quote the literal pattern). Goal: state-doc + audit-doc surface tracks the source-tree narrative. | 0 hits OR each surviving hit annotated "preserved as audit history (commit log of round NN closure)" |
```

**Level of Effort:** Medium (~30-45 min for 25-row narrative sweep; ~10 min gate authoring + commit).

---

### Finding 16.4: 🟠 HIGH — IMPL-064 NFR-3.1 PASS verdict ✅ ที่ fix-round-15 + impl-plan TL;DR + walk-summary + registry Resolved row ทุกที่ cite เป็น evidence — pointer ที่ `docs/state/nfr-3.1-atomic-write-result.json` แต่ file นี้ **untracked** (ไม่ใน git index); fresh clone = sidecar absent → Dim #11 evidence pointer broken; AC `[x]` closure ไม่ reproducible

**Location:**
- File: `docs/state/nfr-3.1-atomic-write-result.json` (untracked — `git ls-files --error-unmatch` returns "did not match any file(s)")
- File: `docs/state/nfr-3.1-atomic-write-result.md`, Lines: 80-85 (Result Table cites the JSON sidecar) — itself uncommitted in working tree
- File: `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` (committed at `119a9ea`, but its evidence-pointer table cites the untracked JSON)
- File: `docs/state/deferred-ac-registry.md` Resolved row for IMPL-064 (committed; cites `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/` + JSON sidecar paths)
- File: `docs/state/impl-plan.md` line ~1689 (audit log row for fix-round-15 — cites JSON sidecar in evidence chain)
- Reference: `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`; `.claude/rules/security.md § State + Journal Integrity` (NFR-3.1 = `parse_fail == 0`)
- Service: ea-qa (NFR-3.1 closure evidence)

**Code:**
```bash
$ ls -la docs/state/nfr-3.1-atomic-write-result.json
-rw-r--r-- 1 kritsana.ye 1049089 1030 May  5 08:52 docs/state/nfr-3.1-atomic-write-result.json

$ git ls-files --error-unmatch docs/state/nfr-3.1-atomic-write-result.json
error: pathspec 'docs/state/nfr-3.1-atomic-write-result.json' did not match any file(s) known to git
```

```markdown
# walk-summary.md (committed) — references the untracked sidecar:
## ✅ Empirical evidence captured (drains deferred-AC rows)
| AC kind | Evidence | Sidecar |
|---|---|---|
| `[file-blob-check]` | atomic_write_kill_100.ps1 -Trials 100 PASS verdict | `docs/state/nfr-3.1-atomic-write-result.json` ← untracked
```

```markdown
# nfr-3.1-atomic-write-result.md § 5 (uncommitted) — Status: ✅ PASS:
| Trial Outcome | Count | Pass criterion |
|---|---|---|
| `parse_pass` | **100** | sum of all outcomes == 100 ✅ |
| `parse_fail` | **0** | **== 0** (NFR-3.1 hard requirement) ✅ |
| **Verdict** | **PASS** | PASS / FAIL ✅ |

Machine-readable sidecar: `docs/state/nfr-3.1-atomic-write-result.json` ← untracked, 1030 bytes
```

**Problem:**
NFR-3.1 (`state.json` survives kill mid-write 100/100) is the hardest of the 9 NFR safety contracts in the project. IMPL-064 closure attestation chain has 5 layers:
1. **`atomic_write_kill_100.ps1`** harness — produces sidecar JSON
2. **`docs/state/nfr-3.1-atomic-write-result.json`** sidecar — machine-readable verdict
3. **`docs/state/nfr-3.1-atomic-write-result.md`** § 5 — Result Table fill
4. **walk-summary.md** — narrative attestation
5. **registry Resolved row** + **impl-plan TL;DR** — gates Phase Gate close

Layer 2 is **untracked**. Layer 3 is **uncommitted in working tree**. Layers 4-5 are committed but cite layers 2-3 as evidence pointers.

Per `.agents/skills/andm-code-reviewer/SKILL.md § Phase 1 Dimension #11`:
> "Verify it exists — missing artifact while AC `[x]` → CRITICAL finding 'E-AC closed without evidence artifact'"

The artifact "exists" on the engineer's local disk (1030 bytes, mtime 2026-05-05 08:52), but NOT in any commit + NOT pushable to a hypothetical CI/external auditor. On a fresh clone:
```bash
git clone <repo> && cd <repo>
ls docs/state/nfr-3.1-atomic-write-result.json   # not found
cat docs/state/nfr-3.1-atomic-write-result.md    # not found
# → IMPL-064 evidence chain unverifiable
```

**Why This Matters:**
- **NFR-3.1 is a hard contract** per `.claude/rules/security.md § State + Journal Integrity`: "State write MUST survive simulated mid-write kill 100/100 trials (NFR-3.1 verification)". The PASS evidence is the only artifact that backs the registry Resolved row claim "100/100 PASS via Stop-Process kill".
- **Phase Gate retroactive close depends on this evidence** — per impl-plan TL;DR, P2 retroactive Phase Gate close requires draining IMPL-064 from Active. Currently in Resolved per fix-round-15. If Resolved row evidence is unreachable → drain is structurally invalid → Phase Gate cannot close.
- **/deliver block** — `.agents/skills/andm-impl-engineer/SKILL.md § Deferred-AC Registry`: "Block /deliver if Active table not empty". Currently empty for IMPL-064 (it's Resolved). But /deliver also walks Resolved evidence pointers; broken pointer = audit fail at deliver time.
- **Subagent reproducibility broken** — any future `/impl-task` agent picking up IMPL-062 (5-yr regression) will read fix-round-15 + walk-summary + registry, see "IMPL-064 ✅ NFR-3.1 PASS", try to verify, find the sidecar missing, escalate to operator. ~10-30 min wasted per recurrence.

This is one of the most load-bearing evidence pointers in the project — NFR-3.1 PASS attests to ADR-007 atomic-write contract. Untracked status = critical audit gap.

**Suggested Fix:**
**Part 1 — Commit the sidecar + result doc together** (~2 min):
```bash
git add docs/state/nfr-3.1-atomic-write-result.json \
        docs/state/nfr-3.1-atomic-write-result.md

git commit -m "[feat:ea-qa] IMPL-064 NFR-3.1 PASS evidence — sidecar + Result Table fill

Why: R16 § 16.4 found nfr-3.1-atomic-write-result.json untracked while fix-round-15
+ impl-plan + walk-summary + registry Resolved row all cited it as PASS evidence.
Closes evidence-pointer integrity gap for the only NFR-3.1 attestation in the project.

Sidecar: schema_version=1, parse_pass=100, parse_fail=0, total=100, verdict=PASS.
Walk-clock 34.3s/100 trials. ADR-007 Option A (write-temp + NTFS rename) holds
under live Stop-Process -Force mid-write kill (complements IMPL-046 software-
simulated 100/100 result)."
```

**Part 2 — Verify Dim #11 evidence chain end-to-end** (~3 min):
```bash
# Re-walk the evidence chain on a clean clone simulation:
git stash --include-untracked
test -f docs/state/nfr-3.1-atomic-write-result.json && echo "JSON sidecar tracked ✅" || echo "❌"
test -f docs/state/nfr-3.1-atomic-write-result.md  && echo "Result doc tracked ✅"  || echo "❌"
jq -e '.verdict == "PASS" and .parse_fail == 0' docs/state/nfr-3.1-atomic-write-result.json && echo "JSON schema valid ✅"
git stash pop
```

**Part 3 — Add `[file-blob-check]` evidence-tracking gate** to `.agents/skills/andm-impl-engineer/SKILL.md § Forbidden Closure Patterns`:
```markdown
| Pattern | Reason | Detect with |
|---------|--------|-------------|
| `[x]` AC cites untracked sidecar/JSON | Evidence pointer broken on fresh clone — Dim #11 chain non-reproducible | `git ls-files --error-unmatch <cited-path>` returns nonzero |
```

**Level of Effort:** Low (1 commit + 3 verification commands).

---

### Finding 16.5: 🟡 MEDIUM — Tier 1.5 walk batch-2 evidence chain มีไฟล์ untracked หลายไฟล์ (`abridged-tester-log.txt` + `nfr-3.1-atomic-write-result.json`) ที่ walk-summary cite เป็น evidence — ขัด `.claude/rules/workflow.md § Handoff Discipline` ที่บอก "Evidence artifacts: `docs/state/_session-handoff/<task-id>-evidence-*.{log,json,jsonl,md}`" implies committed; same root cause as 16.2 + 16.4 but specific to walk-batch-2

**Location:**
- File: `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt` (untracked)
- File: `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` (committed) — cites the abridged log + JSON sidecar
- Reference: `.claude/rules/workflow.md § Handoff Discipline`; `CLAUDE.md § 7 Glossary § Exploratory Walk (Tier 1.5)` ("Phase Gate ปิดไม่ได้จนกว่า walk artifact exists + ≤14d + CRITICAL findings resolved")
- Service: ea-qa (Tier 1.5 evidence)

**Code:**
```bash
$ git ls-files --others --exclude-standard docs/state/_session-handoff/tier-1.5-walk-2026-05-05/
docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt

$ git ls-files docs/state/_session-handoff/tier-1.5-walk-2026-05-05/
docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md
```

**Problem:**
walk-summary.md (committed) is the narrative + evidence index for Tier 1.5 walk batch-2. It cites:
- `abridged-tester-log.txt` (~6.5 KB excerpt of Tester log highlighting evidence lines for IMPL-007/049/052/064/FIX-001/FIX-002 drain)
- `nfr-3.1-atomic-write-result.json` (1030 byte JSON sidecar)
- Raw Tester log in `<TesterAgent>/logs/<DATE>.log` (live MT5 path; never committable per ADR-006 — fine)

Raw Tester logs are appropriately not committed (live machine paths, UTF-16LE, gigabytes — `.claude/rules/security.md` says local-only). But the *abridged* log is the operator-curated evidence excerpt — that's exactly the artifact the walk-summary needs to be reproducible. Untracked = future `/impl-review` rounds cannot verify the walk batch-2 evidence.

Per `CLAUDE.md § 1 Three-Tier Closure`:
> "Tier 1.5 walk artifact = `docs/state/_session-handoff/<date>-phase<N>-exploratory-walk.md` artifact + IMPL-FIX-* tickets resolved"
> "Phase Gate ปิดไม่ได้จนกว่า walk artifact exists + ≤14d + CRITICAL findings resolved"

walk-summary.md exists ✅, but its supporting abridged log doesn't. Per workflow.md:
> "Evidence artifacts: `docs/state/_session-handoff/<task-id>-evidence-*.{log,json,jsonl,md}`"

The path convention implies trackable artifacts. walk batch-2 directory has 1 tracked + 1 untracked file.

This is a subset of Finding 16.2 (uncommitted surface) but specifically scoped to Tier 1.5 walk evidence — load-bearing for Phase Gate close.

**Why This Matters:**
- Phase Gate scan (per `/next` Check 6) will find walk-summary.md present + ≤14d → claim Phase Gate ready. But walk-summary's evidence chain has a broken link.
- Future operator rerunning the walk to re-attest evidence cannot diff against batch-2's abridged log because it's not in git.
- Same recurrence chain risk as Finding 16.2: closure-narrative claims "evidence at <path>" + path resolves on engineer's local disk only.

**Suggested Fix:**
**Part 1 — Commit walk batch-2 evidence excerpt** (~1 min):
```bash
git add docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt
git commit -m "[chore:state] Tier 1.5 walk batch-2 — abridged Tester log evidence

Why: R16 § 16.5 found walk-summary cites this abridged log but file was untracked.
Closes Tier 1.5 evidence chain integrity gap."
```

**Part 2 — Add walk-artifact tracking gate** to `CLAUDE.md § 1 Three-Tier Closure` (~5 min):
```markdown
> **Tier 1.5 evidence integrity rule:** every file path cited in `walk-summary.md` § Evidence section must be `git ls-files`-trackable (or explicitly noted as "raw live-system path — not committable" per ADR-006). Walk Phase Gate close requires `git ls-files --error-unmatch <cited-path>` exit 0 for all curated evidence excerpts.
```

**Level of Effort:** Low (1 commit + 1 rule line).

---

### Finding 16.6: 🟡 MEDIUM — `Spike_AtomicWrite::OnInit` path-guard logic (uncommitted) ใช้ `StringFind(InpStateFile, "PhoenicisNex/spike/") == 0` for sandbox classification — เป็น **prefix match** ที่จะ pass false-positive ถ้ามี future path เช่น `PhoenicisNex/spike-archive/` หรือ `PhoenicisNex/spike2/`; ควรใช้ trailing-`/` exact prefix หรือ explicit equality with `/state.json` filename component

**Location:**
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5`, Lines: 117-127 (uncommitted)
- Reference: fix-round-13 § 13.3 cleanup-guard authoring narrative
- Service: ea (spike-only — bounded blast radius)

**Code:**
```mql5
// Spike_AtomicWrite.mq5:117 (working tree)
string path_class = (StringFind(InpStateFile, "PhoenicisNex/spike/") == 0)
                      ? "sandbox"
                      : (StringFind(InpStateFile, "PhoenicisNex/state/") == 0)
                           ? "production"
                           : "unknown";
```

**Problem:**
`StringFind(s, "PhoenicisNex/spike/") == 0` returns true for any string starting with that prefix — including future paths like `PhoenicisNex/spike-archive/old-state.json` or `PhoenicisNex/spike2/state.json`. The current usage scope is bounded (only IMPL-046 + IMPL-064 ever set `InpStateFile`), so blast radius is contained. But:
1. Naming `spike-archive/` is plausible if the engineer ever renames during refactor; at that point `FileDelete` would fire on archive contents.
2. Same applies to "production" branch — `PhoenicisNex/state-backup/` would be classified as production but also matches the cleanup branch via the `==0` prefix check.

This is a minor robustness issue — defense-in-depth for the dual-gate added in fix-round-12 § 12.6 + fix-round-13 § 13.3. The fix is trivial.

**Why This Matters:**
- Future refactor risk only; current usage is safe (R15 NFR-3.1 PASS verdict ✅ confirms harness ran clean).
- Pattern reuse: same `StringFind(.., prefix) == 0` idiom appears in multiple spike harnesses; if one sets a wider blast radius (e.g., production state path), false-positive prefix match could destroy data.

**Suggested Fix:**
Use a unique trailing component or exact filename match:
```mql5
// Strict — match prefix at directory boundary:
bool is_sandbox = (StringFind(InpStateFile, "PhoenicisNex/spike/") == 0);
bool is_production = (StringFind(InpStateFile, "PhoenicisNex/state/") == 0
                      && StringFind(InpStateFile, "PhoenicisNex/state-") < 0);  // exclude state-backup/

// Or stricter — require known filename component:
bool is_sandbox = (StringFind(InpStateFile, "PhoenicisNex/spike/state.json") >= 0);
```

LoE: Low (~3 LOC; bounded scope).

**Level of Effort:** Low

---

### Finding 16.7: 🔵 LOW — fix-round-15 § Phase 5 Mechanical Gates table row #9b ระบุ "broader-class grep `deferred to IMPL-053(\+| |\.|$)` on `MQL5/Experts/PhoenicisNex` = 0 hits ✅" — semantically correct (สำหรับ source tree) แต่ scope-narrow; per workflow.md gate #9 clause (b) R14 strengthening "broadest-class grep that matches the **intent** of the finding" the sweep needed to be repo-wide; this contributes the Finding 16.3 root cause

**Location:**
- File: `docs/code-review/fix-round-15.md`, Lines 152-158 (Phase 5 Mechanical Gates Verified table)
- File: `.claude/rules/workflow.md`, Lines covering "Phase 5 Closure mechanical gates Gate #9" + R14 strengthening clause
- Service: ea-process

**Code:**
```markdown
# fix-round-15.md § Phase 5 table row #9b:
| 9b | Broader-class grep `deferred to IMPL-053(\+| |\.|$)` on `MQL5/Experts/PhoenicisNex` (R14 strengthened gate, holding) | **0 hits ✅** |
```

```bash
# Reality check (R16):
$ grep -rcE "deferred to IMPL-053" MQL5/Experts/PhoenicisNex
0          # source tree clean ✅
$ grep -rcE "deferred to IMPL-053" docs/state/
26         # state docs not swept ❌ (impl-plan.md alone has 25)
```

**Problem:**
Gate #9 clause (b) per workflow.md (R14 strengthening text):
> "broadest-class grep that matches the *intent* of the finding (e.g., if the finding is "remove references to closed task X", use `grep -rcE "deferred to <task-id>(\+\| \|\.\|$)"` against the **whole repo tree**, not just literal `<task-id>+` against one subdir)"

fix-round-15 narrowed the sweep target to source tree (`MQL5/Experts/PhoenicisNex`). The gate row honestly states the sweep target — but the target was narrower than what gate #9b mandates. Future readers see "✅" + assume repo-wide clean, which is not the case.

This is a documentation/discipline LOW finding — it does not change the fact that fix-round-15 source code surface is correct. It does flag that the gate #9b enforcement mechanism was procedurally weaker than the workflow.md text demands. R14 added clause (b) precisely to break the "next-coarser-granularity recurrence chain"; R15 narrowed it back to subdir scope.

**Why This Matters:**
- Process discipline regression — R14 strengthened the gate; R15 partially honored it. Without R16 surfacing this, R17 might further narrow.
- Operator misreading risk: anyone reading fix-round-15 § Phase 5 table sees "9b ✅" + assumes intent-grep was satisfied. That's the false signal that propagated to Finding 16.3.

**Suggested Fix:**
Update fix-round-15.md Phase 5 table row #9b retrospectively (audit history): add an annotation that the sweep was narrowed; cite R16 § 16.7 finding. OR (preferred) treat as audit-history immutable + ensure R17+ fix-rounds run gate #9b against `*` (whole repo) explicitly:

```markdown
| 9b | Broader-class grep `deferred to IMPL-053(\+| |\.|$)` repo-wide (R14 + R16 strengthened) | **post-fix-round-NN expect 0 hits** ✅ |
```

Add a note to `.claude/rules/workflow.md § Phase 5 Gate #9 clause (b)`:
```markdown
> **R16 strengthening:** "whole repo tree" means literal `grep -rcE <pattern> .` (or equivalent `grep -rcE <pattern> docs/ MQL5/ .claude/ scripts/`) — NOT a chosen subdir. Narrowing the sweep to `MQL5/...` alone is the same regression class fix-round-15 § 9b accidentally introduced (caught by R16 § 16.3 + 16.7).
```

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-16.1 — Pattern: Audit-trail completeness across multi-round fix work

Findings 16.1 + 16.2 + 16.4 + 16.5 share a single root cause: **commit hygiene gap when fix-rounds span multiple sessions or chain through walk artifacts**. The defect class signature is "narrative claims X is shipped + verified, git history disagrees".

This recurs because:
1. Working-tree edits accumulate during long sessions (R13 → R14 → R15 chain) without intermediate commits.
2. `git stash --include-untracked + MetaEditor /compile + git stash pop` is not in the standard 4-gate DoD.
3. Phase 5 mechanical gates 1-9 cover narrative integrity but not commit-tree integrity.

Recommend single methodology gate (proposed in Finding 16.1 + 16.2): **Gate #10 Stash-clean G1** + **Gate #11 Working-tree clean post-closure**. Together they enforce that HEAD is buildable AND the working tree is empty after fix-round closure.

LoE: Low (~10 LOC of workflow.md gate text + 5 LOC of `andm-impl-engineer/SKILL.md` cross-reference).

### XS-16.2 — Pattern: Gate #9 clause (b) recurrence chain (R12 → R13 → R14 → R15 → R16)

Finding 16.3 + 16.7 = same defect class continued from R12 § 12.8. Each round adds a strengthening clause to gate #9 to break the recurrence; each next round finds a narrower scope where the gate was applied. The pattern is:
- R12: gate #9 introduced (originating regex against literal cite sites)
- R13: gate #9 fixed scope-narrow (broader-class regex)
- R14: gate #9 clause (b) added (R14 strengthening: "broadest-class grep against repo")
- R15: clause (b) narrowed to source tree only
- R16 (this round): identifies state docs not swept; proposes clause (c) "whole-repo intent grep, document scope explicitly"

The fix per R16 § 16.7 + Finding 16.3 fix Part 3 = explicit clause (c) with literal `.` repo-root in the example. If the clause text says "use `.`" instead of leaving the directory open-ended, R17 can't accidentally narrow it.

LoE: Low (5-10 LOC clause-(c) authoring in workflow.md).

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 16.1 | 🔴 CRITICAL | Build Integrity / Empirical AC Closure | HEAD compile fail: `BootstrapValidator::RunDomainSelfTests` calls undefined `IsPhoenicisMagicSelfTest()` (body in working tree only); fresh clone G1 fails; Cold-Bootstrap recipe broken | `core/BootstrapValidator.mqh:593` (HEAD) + `domain/EnumTypes.mqh:105-163` (working tree only) | Low |
| 16.2 | 🟠 HIGH | Process Discipline / Cross-Service Consistency | 35 modified + 6 untracked files (>508 LOC) ที่ fix-round-13/14/15 narratives บอก "applied + G1 PASS" แต่ไม่ committed; commit history vs documented closure narrative ไม่ตรง | working tree at session start + `git status -s` snapshot | Medium |
| 16.3 | 🟠 HIGH | State Reconciliation / Cross-Service Consistency | 25 stale `deferred to IMPL-053+` references in `[ ]` AC entries ของ `impl-plan.md`; IMPL-053..060 closed → closure rationale wrong-by-fact; fix-round-15 gate #9b narrowed sweep to source tree only | `docs/state/impl-plan.md` × 25 sites (lines 340..1249) | Medium |
| 16.4 | 🟠 HIGH | Empirical AC Closure / Test Code Quality | IMPL-064 NFR-3.1 PASS sidecar `nfr-3.1-atomic-write-result.json` untracked while fix-round-15 + impl-plan + walk-summary + registry Resolved row ทุกที่ cite as evidence; fresh clone Dim #11 chain broken | `docs/state/nfr-3.1-atomic-write-result.json` (untracked) + `nfr-3.1-atomic-write-result.md` (uncommitted) | Low |
| 16.5 | 🟡 MEDIUM | Functional Walk (Tier 1.5) / Empirical AC Closure | Tier 1.5 walk batch-2 abridged-tester-log.txt untracked while walk-summary cites it as evidence-pointer; subset of 16.2 specific to Tier 1.5 chain | `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt` | Low |
| 16.6 | 🟡 MEDIUM | Test Code Quality / Defensive Patterns | Spike_AtomicWrite path-guard `StringFind(InpStateFile, "PhoenicisNex/spike/") == 0` is prefix-match; future `spike-archive/` refactor false-positive | `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5:117` (working tree) | Low |
| 16.7 | 🔵 LOW | Process Discipline | fix-round-15 § Phase 5 gate #9b sweep narrowed to source tree (R14 strengthening text required repo-wide); contributing root cause for 16.3 | `docs/code-review/fix-round-15.md:152-158` + `.claude/rules/workflow.md § Gate #9 (b)` | Low |

---

## Recommendation

**Status: NOT READY for fix-round-16 OR new task work — block on Finding 16.1 (CRITICAL build integrity).**

R16 surfaces a CRITICAL build-integrity defect (Finding 16.1) that breaks `main` for any fresh clone or stash-clean compile. Cold-Bootstrap Recipe per `.claude/rules/workflow.md` does not pass. **All other findings are downstream of the same root cause class: commit hygiene gap (Findings 16.2/16.4/16.5/16.7).**

**Recommended sequence:**

1. **Fix Finding 16.1 first** (~5 min): commit `domain/EnumTypes.mqh` + `services/CircuitBreaker.mqh` + `spike/Spike_Orchestrator.mq5` + new `spike/Spike_CircuitBreaker.mq5` so HEAD has the body + spike call sites. Verify with `git stash --include-untracked && MetaEditor /compile && git stash pop`.

2. **Sweep working tree** (Finding 16.2 fix; ~15-25 min): 4-5 commits packaged by fix-round narrative scope. Each commit followed by stash-clean G1 (proposed Gate #10).

3. **Commit IMPL-064 evidence** (Finding 16.4 fix; ~2 min): `nfr-3.1-atomic-write-result.{md,json}` + walk batch-2 abridged log (Finding 16.5 fix). Ensure all walk batch-2 evidence pointers `git ls-files`-trackable.

4. **Sweep impl-plan.md stale narratives** (Finding 16.3 fix; ~30-45 min): 25 row narrative refresh; partition by drain status (drained / partial / gated-on-IMPL-062). Update gate #9 clause (c) for whole-repo sweep enforcement.

5. **Strengthen workflow.md gates** (Findings 16.1/16.2/16.7 fix; ~10-15 min): add Gate #10 stash-clean G1, Gate #11 working-tree-clean post-closure, Gate #9 clause (c) repo-wide intent grep.

6. **Re-verify with R17 review** OR proceed directly to **IMPL-062** (Bucket A regression) per fix-round-15 next-sequence — but only AFTER 16.1 closes (build-integrity blocker for all subsequent work).

**Cross-cutting observation — XS-16.1 + XS-16.2:**
Two recurrence chains visible:
- (a) commit-hygiene gap (16.1+16.2+16.4+16.5) → R12 § 12.4/12.5 had no commit gate; R13/R14/R15 inherited the gap.
- (b) gate #9 sweep-scope narrowing (16.3+16.7) → R12→R13→R14 added clauses; R15 narrowed; R16 catches.
Both chains close with workflow.md gate additions (#10/#11/#9c). After R17, should be a one-shot fix; if R18 finds these patterns again, methodology is failing.

**Plan Staleness Sentinel** unchanged at 6 (review rounds don't increment).

**Cumulative reviewed surface:** ~9,570 LOC source + ~25 state-doc files + 2 walk artifacts + 1 NFR PASS attestation chain.

**Verification commands run during this review:**
```bash
git show HEAD:MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh | grep -c "IsPhoenicisMagicSelfTest"   # → 7 (call sites)
git show HEAD:MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh | grep -c "IsPhoenicisMagicSelfTest"          # → 0 (body MISSING)
git show HEAD:MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh | grep -c "Case E:"                    # → 0
git show HEAD:simulation/scripts/atomic_write_kill_100.ps1 | grep -c "FailFastConsecutive"                 # → 0
git ls-files --error-unmatch docs/state/nfr-3.1-atomic-write-result.json                                   # → "did not match"
grep -cE "deferred to IMPL-053" docs/state/impl-plan.md                                                    # → 25
git diff HEAD --shortstat                                                                                  # → 35 files changed, 508 insertions(+), 190 deletions(-)
```

---

## End of Review
