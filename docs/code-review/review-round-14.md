# Code Review Round 14

| Field | Value |
|-------|-------|
| **Round** | 14 |
| **Target** | `all` — focused on fix-round-13 deltas: `simulation/scripts/atomic_write_kill_100.ps1` (`$AgentSubpath` + `$TesterRoot` resolution + `-FailFastConsecutive` circuit), `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5` (path-prefix cleanup guard at OnInit start + end), `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh` (SelfTest Case E pre-Init NULL-logger guard), `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh` (`IsPhoenicisMagicSelfTest`), `MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5` (SelfTest wiring), 17 slot files / 23 sites comment sweep, `docs/state/nfr-3.1-atomic-write-result.md § 2.3.1/.2/.3`, `.claude/rules/workflow.md § Phase 5 mechanical gate #9`. Cumulative reviewed surface: ~9,520 LOC (R01..R13). |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~50 LOC delta `.ps1` + ~30 LOC delta Spike_AtomicWrite.mq5 + ~25 LOC delta CircuitBreaker.mqh + ~50 LOC delta EnumTypes.mqh + ~10 LOC delta Spike_Orchestrator.mq5 + ~5 LOC × 17 slot files + ~25 LOC delta nfr-3.1 doc + 1 row workflow.md. Cumulative reviewed surface: ~9,520 LOC (R01..R13). |
| **Plan Staleness Sentinel** | 7 closures since R07 (R13 fix-round counted as +1); below 10-closure threshold ✅. Last `/impl-plan-review` was R07 (2026-05-04). Mid-Phase Audit P4 counter advisory still active. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **4** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | `Spike_AtomicWrite::OnInit` path-prefix guard now classifies `InpStateFile` (`sandbox`/`production`/`unknown`) and skips destructive `FileDelete` outside the spike sandbox; same guard symmetric at OnDeinit-equivalent block (lines 224-230). PowerShell harness retains `Set-StrictMode -Version Latest`. No new `#import`/`WebRequest`/credential leaks. |
| 2 | Business Logic Correctness | ✅ Pass | `atomic_write_kill_100.ps1` Tester-tree resolution (`$MetaQuotesRoot/Tester/$TerminalId/$AgentSubpath/MQL5/Files/$StateRel`) is structurally correct: `$RepoRoot` (= terminal-data-dir) → up-2 → `$MetaQuotesRoot` → `Tester` sibling → `$TerminalId` → `$AgentSubpath`. Verdict logic distinguishes `PASS` / `FAIL_FAST` / `FAIL` correctly: `$isPass = (-not $failed_fast) -and ($parse_fail -eq 0) -and ($total -eq $Trials) -and ($startup_timeout_count -eq 0)` fail-closes when fail-fast trips (because `$failed_fast=$true`) AND when `$total != $Trials` (early break). |
| 3 | Error Handling | ✅ Pass | Spike's path-class `[ev=path_guard]` Print fires unconditionally at OnInit start regardless of whether cleanup runs — operator can `grep -E "\[ev=path_guard\]"` for safety audit. Harness FAIL_FAST emits 5-line operator-audit hint (state dir / .ini override / Tester-sandbox path expectation / log-paths.md reference). |
| 4 | Performance | ✅ Pass | Fail-fast circuit converts the 100-trial × 60s = 100-min config-error discovery into a 3-trial × 60s = 3-min discovery. Compatible with Tier 1.5 walk 30-min budget per CLAUDE.md §1. |
| 5 | Over-Engineering | ✅ Pass | Path-class string ladder (`StringFind` × 2 + nested ternary) is the minimum-viable 3-class classifier; SelfTest Case E is 17 LOC including the m_logger save/restore dance. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **Finding 14.1 HIGH** — fix-round-13 § 13.2 narrative announced "0 hits (down from 23)" via grep `IMPL-053\+\|deferred to Orchestrator wiring\|deferred to orchestrator wiring\|schema lock deferred to IMPL-053` scoped to `slots/`. Repo-wide grep on `deferred to IMPL-053` (no escape, no `+` requirement) returns **23 sites still extant** (10 in `slots/` without `+`, 13 in `services/`/`core/`/`spike/` with `+`). Same defect class — fix-round verification grep was scope-narrower than the actual stale-comment problem class. The cross-cutting workflow gate #9 added in fix-round-13 § XS-13.2 enforces "re-run the originating R-finding's pattern grep" — but if the originating grep is itself scope-narrower, the gate verifies the narrow class and misses the broader class (gate #9 is shape-correct but as effective as its grep set). |
| 7 | Test Coverage Gaps | ⚠️ Finding | **Finding 14.2 MEDIUM** — `CCircuitBreaker::SelfTest()` (Cases A–E including the new fix-round-13 § 13.5 Case E) is never called from any production path or any spike. There is no `Spike_CircuitBreaker.mq5` (compare with sibling services that DO have spikes: `Spike_CrossSlotCoordinator`, `Spike_EAState`, `Spike_PendingMachineRegistry`). Production `core/Orchestrator::OnInit` doesn't invoke `m_breaker.SelfTest()` either. The fix-round-13 § 13.5 narrative says Case E "will run under the Phase 2 spike harness when CCircuitBreaker::SelfTest() is invoked" — but no such harness exists yet, and no IMPL ticket is scheduled to add one, so Case E (and Cases A–D) provide zero runtime regression detection until that Phase 2 wiring lands. **Finding 14.3 MEDIUM** — `IsPhoenicisMagicSelfTest()` is wired ONLY in `spike/Spike_Orchestrator.mq5:44`. Production `core/Orchestrator::OnInit` and `core/BootstrapValidator::ValidateAll()` (the documented intended consumer per `EnumTypes.mqh:112-113`) do NOT call it — so a live-chart production attach never exercises the magic-set membership SelfTest, which is exactly the runtime gate the R13 § 13.6 motivation asked for. |
| 8 | Architecture Compliance | ✅ Pass | Sandbox-tree binding doc (`§ 2.3.1`) preserves the per-mode MQL5 file-I/O sandbox separation (per `mt5-headless-backtest § references/log-paths.md`). Spike cleanup guard (`§ 2.3.2`) preserves IMPL-046's original sandbox semantics for direct-attach use. Harness fail-fast (`§ 2.3.3`) preserves the fail-closed verdict gate from fix-round-12 § 12.3 (verdict gate still requires `parse_fail == 0 AND total == Trials AND startup_timeout_count == 0 AND -not failed_fast`). |
| 9 | Technical Design Compliance | ✅ Pass | `nfr-3.1-atomic-write-result.md § 2.3.1/.2/.3` documents the 3-row component-path table + spike cleanup guard + harness fail-fast. `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` table now has 9 rows; failure-escalation note bumped from "8 gates" → "9 gates"; "Why this is here" paragraph cites R13 with the "all 11 slot files" narrative-vs-actual scope drift root-cause. Schema-yaml gap from R13 § XS-13.3 (`parse_anomaly_count` not in `api-specs/`) deferred to IMPL-062 explicitly — tracked, not blocking R14. |
| 10 | Test Code Quality | ⚠️ Finding | **Finding 14.4 LOW** — `atomic_write_kill_100.ps1` documentation drift introduced by fix-round-13 § 13.4 edit: (a) lines 25-26 contain a duplicate `.PARAMETER Trials` block (`(defined above) — see also -FailFastConsecutive`) which appears to be an editor-introduced stub instead of a `.PARAMETER FailFastConsecutive` block (the actual `.PARAMETER FailFastConsecutive` block correctly exists at lines 50-54 — the duplicate is dead doc content); (b) lines 70-72 example block still references `-StateDir 'MQL5/Files/PhoenicisNex/state'` but that param was renamed to `-StateRel 'PhoenicisNex/state'` in the fix-round-13 cmdlet binding refactor — operator copy-pasting the example will get a parameter-binding error. PowerShell harness logic itself is sound; doc/code synchronization is the gap. |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `docs/state/impl-plan.md` for "deferred to operator-runtime" / "deferred per .* precedent" / "structurally complete.*deferred" / "live verification deferred" → **0 hits** ✅. IMPL-064 deferred-AC E-AC#1 (`[boot-cold]` + `[file-blob-check]`) remains Active in `deferred-ac-registry.md` (expiry 2026-05-18); fix-round-13 narrative correctly notes this is now operationally exercisable empirically once the operator session runs `-Trials 5 -Verbose` against the corrected harness. IMPL-068 paired bundle row also still Active (expiry 2026-05-18). No new closures land in fix-round-13. |
| 12 | Functional Walk (PhoenicisNex Tier 1.5) | ⏭ Skip — not yet executed | `bootstrap_smoke.ini` walk batch-2 still has not run since fix-round-13. The R14 surface is structural-only (compile gates passed; DryRun smoke verified the path-resolution string but not the empirical Tester-tree binding). Recommend the walk runs `atomic_write_kill_100.ps1 -DryRun -Trials 5 -Verbose` first to confirm the Tester sandbox tree resolves correctly on this install (especially the `Agent-127.0.0.1-3000` constant), THEN escalate to a real `-Trials 5` (not 100) before committing to a full 100-trial run. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; PowerShell harness reads `origin.txt` (already validated by IMPL-001 + IMPL-046) + `.ini` paths (committed); no new env-var / secret consumer added by fix-round-13. `[config-audit]` not triggered. |

---

## Findings

### Finding 14.1: 🟠 HIGH — fix-round-13 § 13.2 verification grep "0 hits (down from 23)" was scope-narrower than the actual stale-comment problem class — repo-wide `grep -rn "deferred to IMPL-053"` shows **23 stale sites still extant** (10 in `slots/` without literal `+`, 13 in `services/`/`core/`/`spike/` with `+`); the fix-round narrative declared comprehensive sweep but only the entry/exit-side `IMPL-053+` patterns inside `slots/` were addressed — exact recurrence of the R13 § 13.2 / § XS-13.2 declared-vs-actual scope drift defect class

**Location:**
- Files (10 sites in `slots/`, all "deferred to IMPL-053" without `+`):
  - `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:145` (`BR activation from B's ExtraTakeProfit_B deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_F.mqh:150` (`F activation from CD's OpenOrderCD deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:260` (`coupling to G-overload signal deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:130` (`GO activation from G's TriggerGOverload deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_I.mqh:288, 350` (`Fibonacci parasite coupling deferred to IMPL-053` + `orphan-guard coupling (close I when parent G closes) deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh:150` (`J activation from CD-entry event deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh:189` (`LX pyramid coupling deferred to IMPL-053`)
  - `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh:251, 313` (`S post-close coupling deferred to IMPL-053` + `orphan-guard coupling deferred to IMPL-053`)
- Files (13 sites OUTSIDE `slots/`, with literal `IMPL-053+`):
  - `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:73` (`CleanupPartialInit deferred to IMPL-053+ (orchestrator owner)`)
  - `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh:439` (`deferred to IMPL-053+ orchestrator wiring per header-only`)
  - `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:71, 276, 289` (3 hits — broker query / log-assertion E-AC / `PositionsTotal()` loop deferred to IMPL-053+)
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_G2.mq5:18`, `Spike_Slot_I.mq5:19`, `Spike_Slot_GO.mq5:19`, `Spike_Slot_LX.mq5:19` (4 hits — `G2-G4 full entry+exit E-ACs deferred to IMPL-053+`)
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5:21` (`E-AC smoke + G4 attestation deferred to IMPL-053+ Orchestrator`)
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_B.mq5:17`, `Spike_Slot_BR.mq5:17`, `Spike_Slot_L.mq5:17` (3 hits — `E-AC smoke deferred to IMPL-053+ ... wiring`)
- Reference: `docs/code-review/fix-round-13.md` § Finding 13.2 verification grep claim ("0 hits (down from 23)") + `docs/code-review/review-round-13.md` § XS-13.2 ("declared-vs-actual cascade scope drift") + `.claude/rules/workflow.md § Phase 5 mechanical gate #9` (added by fix-round-13 § XS-13.2)
- Service: ea (slots/ + services/ + core/ + spike/ — repo-wide audit-clarity surface)

**Code:**
```mql5
// slots/Slot_S.mqh:249-253  (still stale — fix-round-13 grep set missed "deferred to IMPL-053" without `+`)
   if(close_event_for_S)
     {
      m_logger.Info("SlotS", "exit_post_close_signal", MAGIC_S, "S close event detected");
      //--- Stub: S post-close coupling deferred to IMPL-053
     }

// slots/Slot_GO.mqh:128-132 (still stale)
   if(parent_G_overload)
     {
      m_logger.Info("SlotGO", "entry_signal", MAGIC_GO, "G overload trigger detected");
      //--- Stub: GO activation from G's TriggerGOverload deferred to IMPL-053
     }

// services/PortfolioState.mqh:69-73 (still stale, with `+` — outside fix-round-13 grep scope)
//|   Phase 1: registers 17 magics (CD/F/H/J/K/G/G2/GO/M/L/LX/Q/R/B/BR/I/S/P/T)|
//|   Phase 2: PositionsTotal() loop populates per-slot SlotState fields. |
//|   Per ADR-005 § Refresh contract; broker query deferred to IMPL-053+ |

// core/BootstrapValidator.mqh:71-73 (still stale, with `+`)
//   Called from Orchestrator::Init Phase C (TD-02 §7.4 line 1654):
//     if (!m_validator.ValidateInputs()) return INIT_FAILED;
//   CleanupPartialInit deferred to IMPL-053+ (orchestrator owner).
```

```bash
# Verification grep (Grep tool, project root, MQL5/Experts/PhoenicisNex/, repo-wide):
#   pattern: "deferred to IMPL-053"
# Output: 23 hits (10 in slots/ without `+`, 13 in services/+core/+spike/ with `+`)
#
# fix-round-13 § 13.2 narrative said:
#   "$ grep -rE \"deferred to IMPL-053\\+|deferred to Orchestrator wiring|deferred to orchestrator wiring|schema lock deferred to IMPL-053\" MQL5/Experts/PhoenicisNex/slots
#    0 hits  (down from 23)"
# That grep WAS satisfied (slots/ does have 0 matches for that exact pattern set);
# but the broader defect class (stale 'deferred to IMPL-053' pointer) survives.
```

**Problem:**
fix-round-13 § Finding 13.2 declared a comprehensive slot-comment sweep ("17 slot files / 23 sites" in the verdict summary table). The post-fix grep used `IMPL-053\+` (literal `+` required) and was scoped to `MQL5/Experts/PhoenicisNex/slots` only. The originating R13 § 13.2 finding listed exactly those 23 sites and they were correctly addressed. But:

1. **Inside `slots/`**: 10 additional sites carry the stale "deferred to IMPL-053" wording WITHOUT the trailing `+`. These are slot-coupling-stubs (different semantic from R13's exit-side stubs — they refer to cross-slot trigger wiring like `BR activation from B's ExtraTakeProfit_B`, `GO activation from G's TriggerGOverload`, etc.) but in the same files and present the same audit-clarity defect: a new engineer reading `Slot_S.mqh:251` ("S post-close coupling deferred to IMPL-053") still sees a stale pointer to a long-closed task.
2. **Outside `slots/`**: 13 sites in `services/`, `core/`, and `spike/` carry the literal `IMPL-053+` framing — outside the fix-round-13 grep scope entirely. Including the `PortfolioState.mqh` PositionsTotal-loop deferral comment, the BootstrapValidator CleanupPartialInit comment, the RiskManager header-only deferral comment, and 7 spike-file headers that say `E-AC smoke deferred to IMPL-053+`.

This is the **exact defect class** R13 § XS-13.2 named ("declared-vs-actual cascade scope drift") and the workflow.md gate #9 was added specifically to prevent. The gate's wording ("re-run the originating R-finding's pattern grep") only catches what the originating finding's grep was told to catch. When the originating grep's regex is scope-narrower than the actual defect class — as here — the gate verifies a narrow superset is gone but the broader class survives.

The recurrence pattern holds: R12 § 12.8 closure narrative said "all 11 slot files" → R13 found 21 stale sites in 17 slot files; R13 § 13.2 closure narrative said "17 slot files / 23 sites" + grep "0 hits down from 23" → R14 finds 23 more stale sites repo-wide. The defect class compounds each round at the next-coarser granularity (entry-side stubs → exit-side stubs → cross-slot coupling stubs + non-slot service stubs).

**Why This Matters:**
Same audit-clarity erosion as R13 § 13.2 + R12 § 12.8. A new engineer reading `Slot_F.mqh:150` ("F activation from CD's OpenOrderCD deferred to IMPL-053") will still chase a closed task ID; an engineer reading `services/PortfolioState.mqh:289` ("Step 2: PositionsTotal() loop — deferred to IMPL-053+") will still believe IMPL-053 is the wiring task even though IMPL-053..060 all closed. **Trust erosion** is the structural cost: fix-round-13 § 13.2 explicitly committed to "0 hits (down from 23)" but the broader sweep audit shows the same number 23 — operator who runs the broader grep loses confidence that the closure narrative matched reality.

This also stress-tests the gate #9 design. Gate #9 is shape-correct (re-run the originating grep, expect zero matches) but as effective as the originating grep's pattern set. To prevent the next R-cycle recurrence, gate #9 needs an additional clause: **"if the finding's intent is to remove a class of stale references (e.g., 'all references to closed task X'), the post-fix grep must use the BROADEST possible regex that captures the class, not the narrowest pattern from the finding's specific cited sites."**

The single 13.2 closure-line that would have caught this at fix-round-13 commit boundary:
```
$ grep -rcE "deferred to IMPL-053(\+| |\.|$)" MQL5/Experts/PhoenicisNex
```
would have shown 23 hits; the engineer would have been forced to broaden the sweep to either (a) replace the broader class or (b) explicitly scope-out the non-slot files in the fix-round narrative.

**Suggested Fix:**
Two-part fix:

**Part 1 — sweep the broader class** (mechanical, ~30 LOC across 23 sites):

```bash
# Replace stale "deferred to IMPL-053" / "IMPL-053+" pointers with canonical Phase-1 framing per fix-round-12 §12.8.
cd MQL5/Experts/PhoenicisNex
grep -rln "deferred to IMPL-053" .
# For slot-coupling stubs: keep the cross-slot trigger semantic but drop the stale task ID:
#   "deferred to IMPL-053" → "wires at IMPL-017 / IMPL-062 (cross-slot coupling per ea.md)"
# For service-side stubs (PortfolioState/BootstrapValidator/RiskManager headers):
#   "deferred to IMPL-053+ (orchestrator owner)" → "completed at IMPL-053..060 (Orchestrator) per impl-plan"
# For spike-file headers (E-AC smoke):
#   "E-AC smoke deferred to IMPL-053+ orchestrator wiring" → "E-AC smoke wires at IMPL-017 / IMPL-062 entry+exit when RiskManager::OpenOrder lands"
```

**Part 2 — strengthen workflow.md gate #9** (process, 1 row + 1 paragraph):

```
| 9 | **Post-fix grep verification (impl-review-fix only)** | After a fix-round commits land:
   (a) re-run the originating R-finding's pattern grep with `--count`;
   (b) ALSO run a broadest-class grep that matches the *intent* of the finding
       (e.g., if the finding is "remove references to closed task X", use
       `grep -rcE "deferred to <task-id>(\+| |\.|$)"` not just literal `<task-id>+`);
   record both post-conditions in the fix-round report.
| (a) exit code 1 (zero matches) of the originating grep AND (b) zero matches of the broadest-class grep — any non-zero hit on (b) means the finding's intent was wider than the executed sweep; force the engineer to either expand or explicitly scope-out the non-target sites |
```

Add a paragraph to "Why this is here":
> **R14 recurrence (2026-05-04):** fix-round-13 § 13.2 closed "17 slot files / 23 sites" with grep "0 hits down from 23" using `IMPL-053\+` pattern; broader grep `deferred to IMPL-053` shows 23 OTHER stale sites still extant (10 in slots/ without `+`, 13 in services/+core/+spike/ with `+`). Same root cause as R12 § 12.8 → R13 § 13.2 (the originating grep is scope-narrower than the defect class).

LoE: Low (~30 LOC mechanical comment sweep + 1 workflow.md row + 1 paragraph).

**Level of Effort:** Low

---

### Finding 14.2: 🟡 MEDIUM — `CCircuitBreaker::SelfTest()` (Cases A–E including the new fix-round-13 § 13.5 Case E) is dead code — never called from any production path or any spike harness; no `Spike_CircuitBreaker.mq5` exists; production `core/Orchestrator::OnInit` doesn't call `m_breaker.SelfTest()`. The fix-round added Case E for runtime regression detection of the dual-gate, but the SelfTest method has zero callers, so neither Case E nor Cases A–D detect anything at runtime

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`, Lines: 285-417 (SelfTest method body — Cases A–E)
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 289 (`m_breaker.Init(m_logger)` is called) — but no subsequent `m_breaker.SelfTest()` call anywhere in the file
- Files: `MQL5/Experts/PhoenicisNex/spike/Spike_*.mq5` — 29 files exist; **no `Spike_CircuitBreaker.mq5`** (compare: `Spike_CrossSlotCoordinator.mq5`, `Spike_EAState.mq5`, `Spike_PendingMachineRegistry.mq5`, `Spike_CSlotBase.mq5` all exist and DO call their respective `SelfTest(&g_logger)` methods)
- Reference: `docs/code-review/fix-round-13.md` § Finding 13.5 ("Case E will run under the Phase 2 spike harness when CCircuitBreaker::SelfTest() is invoked") + `docs/code-review/review-round-13.md` § Finding 13.5 motivation ("a future regression … is silently accepted by the existing SelfTest because Cases A-D all run after `Init(logger)` is called inside `Spike_CircuitBreaker.mq5` or wherever SelfTest is wired")
- Service: ea (services/ + core/)

**Code:**
```mql5
// CircuitBreaker.mqh:285-417 — SelfTest defined with 5 cases (A-E), but...
bool CCircuitBreaker::SelfTest()
  {
   bool all_pass = true;
   ...
   //--------------------------------------------------------------------
   // Case E: pre-Init RecordOpen + RecordClose dropped — buffer NOT
   //         mutated + Print fallback emitted (fix-round-13 § 13.5;
   //         guards dual-gate added in fix-round-12 § 12.6).
   //--------------------------------------------------------------------
   ...
}
```

```bash
# Verification — all callers of CCircuitBreaker::SelfTest()
$ grep -rE "\.SelfTest\(|::SelfTest\(|->SelfTest\(" MQL5/Experts/PhoenicisNex
spike/Spike_CrossSlotCoordinator.mq5:35:   if(!g_xslot.SelfTest(&g_logger))
spike/Spike_EAState.mq5:24:                if (!ea.SelfTest(&g_logger))
spike/Spike_CSlotBase.mq5:145:             if(!CSlotRegistry::SelfTest(&g_logger, ...))
spike/Spike_PendingMachineRegistry.mq5:25: if(!g_pmr.SelfTest(&g_logger))
# 4 callers, none of them target CCircuitBreaker. No Spike_CircuitBreaker.mq5.

$ ls MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5
ls: cannot access 'Spike_CircuitBreaker.mq5': No such file or directory
```

**Problem:**
fix-round-13 § Finding 13.5 added Case E to `CCircuitBreaker::SelfTest()` to address R13 § 13.5 motivation: "a future regression (e.g., engineer removes the NULL check during a refactor, or accidentally swaps the early-return order) is silently accepted by the existing SelfTest because Cases A-D all run after `Init(logger)` is called inside `Spike_CircuitBreaker.mq5` or wherever SelfTest is wired." The Case E body itself is correct (saves m_logger, sets to NULL, calls RecordOpen + RecordClose, asserts m_count == 0, restores m_logger).

But the SelfTest method has **no caller anywhere in the codebase**:
- `core/Orchestrator::OnInit` (production path) only calls `m_breaker.Init(m_logger)` — never `SelfTest()` (checked at line 289 + global grep on `\.SelfTest\(` returned 4 spike files, none for CircuitBreaker).
- No `spike/Spike_CircuitBreaker.mq5` exists. The spike directory has 29 files for other components (Spike_CrossSlotCoordinator, Spike_EAState, Spike_CSlotBase, Spike_PendingMachineRegistry are wired and call their respective SelfTests; Spike_AtomicWrite, Spike_StatePersistence, Spike_TradeJournal, 21 Spike_Slot_*.mq5 files exist for other purposes; **no Spike_CircuitBreaker**).
- No IMPL ticket in the impl-plan is scheduled to add the spike or to wire `SelfTest()` into production OnInit.

So Case A through E provide **zero runtime regression detection** until either (a) a Spike_CircuitBreaker.mq5 spike is added, OR (b) Orchestrator::OnInit invokes SelfTest after WireServices, OR (c) BootstrapValidator::ValidateAll picks it up. The fix-round-13 § 13.5 fix is **structurally correct but operationally inert** — the regression detection mechanism exists in source but never executes.

This is the same defect class as Finding 14.3 below (IsPhoenicisMagicSelfTest) — a SelfTest is added but its runtime invocation gap is not addressed in the same fix-round. Compare with the wired-and-fired SelfTests in PhoenicisNex (`Spike_CrossSlotCoordinator` calls `g_xslot.SelfTest(&g_logger)` line 35 + returns INIT_FAILED on FAIL); those follow the correct pattern.

**Why This Matters:**
The R13 § 13.5 motivation explicitly frames the SelfTest as a defense against a Phase-2-era refactor regression: "When IMPL-017 / IMPL-062 lands (within 1-2 weeks per current plan), the Phase 2 caller surface activates. A pre-Init RecordOpen dispatch ... hits the new guard. Without a SelfTest exercising that path, a reviewer in 2-3 sprints' time who refactors CircuitBreaker has no immediate signal that they broke the dual-gate — the existing SelfTest remains green." This argument requires the SelfTest to **actually run** at attach time (live or spike). It does not run anywhere — so the defense never deploys.

A simpler way to phrase the impact: fix-round-13 § 13.5 effectively claims to have closed R13 § 13.5 by adding 17 LOC of test code. But "closed" assumes the test runs. Since it doesn't, the closure is structural, not empirical — same Empirical Closure Discipline trap that Code Review Dim #11 + the andm-impl-engineer SKILL § Forbidden Closure Patterns guard against (the SelfTest is added; running-the-SelfTest is "deferred to operator-runtime" by absence). Phase 2 regression risk identified by R13 § 13.5 still latent.

This is also the existing state of `helpers/CommentParser::SelfTest`, `helpers/JsonWriter::SelfTest`, `services/PortfolioMonitor::SelfTest`, and `services/RiskManager::SelfTest` — multiple defined-but-never-called SelfTests pre-existed fix-round-13 (broader project-wide pattern). But fix-round-13 § 13.5 is the specific case where the R13 narrative explicitly motivated the SelfTest as a runtime regression gate; the wiring gap is most visible there.

**Suggested Fix:**
Add `MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5` mirroring the existing `Spike_PendingMachineRegistry.mq5` shape (~25 LOC):

```mql5
//+------------------------------------------------------------------+
//| Spike_CircuitBreaker.mq5 — exercises CCircuitBreaker::SelfTest   |
//| Cases A–E in headless tester / on-chart attach.                  |
//+------------------------------------------------------------------+
#property strict
#include "../services/Logger.mqh"
#include "../services/CircuitBreaker.mqh"

CLogger          g_logger;
CCircuitBreaker  g_breaker;

int OnInit()
  {
   Print("[Phoenicis] Spike_CircuitBreaker: SelfTest exercise start");
   g_logger.Init(/* params */);
   g_breaker.Init(&g_logger);

   if(!g_breaker.SelfTest())
     {
      Print("[Phoenicis] Spike_CircuitBreaker: SelfTest FAILED");
      return INIT_FAILED;
     }

   Print("[Phoenicis] Spike_CircuitBreaker: SelfTest PASS (5 cases A–E)");
   return INIT_SUCCEEDED;
  }
void OnTick() { }
void OnDeinit(const int reason) { }
double OnTester() { return(0.0); }
```

OR — preferred per `core/Orchestrator::OnInit` integration — call `m_breaker.SelfTest()` at the end of WireServices (after `m_breaker.Init(m_logger)` at line 289), behind a debug-only flag (e.g., `#ifdef PHOENICISNEX_SELFTEST`). That puts the regression gate on the production attach path without bloating production tick budget.

Either approach also applies to the project-wide pattern: `Spike_PortfolioMonitor`, `Spike_RiskManager`, `Spike_JsonWriter`, `Spike_CommentParser` are missing — recommend a separate IMPL-NNN to bulk-add SelfTest spikes for all defined-but-uncalled SelfTest methods.

LoE: Low (~25 LOC × 1 spike = trivial).

**Level of Effort:** Low

---

### Finding 14.3: 🟡 MEDIUM — `IsPhoenicisMagicSelfTest()` is wired ONLY in `spike/Spike_Orchestrator.mq5:44`, NOT in production `core/Orchestrator::OnInit` or `core/BootstrapValidator::ValidateAll()`; the function header comment at `EnumTypes.mqh:112-113` claims production wiring intent ("Wire from BootstrapValidator::ValidateAll() at OnInit step 1 (per TD-02 §7.4)") that was not delivered. So a live-chart production attach NEVER exercises the magic-set-membership regression gate that R13 § 13.6 motivated; only the headless spike does

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh`, Lines: 112-113 (comment header — "Wire from BootstrapValidator::ValidateAll() at OnInit step 1 (per TD-02 §7.4) alongside JsonWriter / IndicatorService SelfTests")
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5`, Lines: 44-48 (only wiring site)
- File: `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh`, Lines: 1-540 (does NOT call IsPhoenicisMagicSelfTest — `ValidateInputs`, `ValidateSymbol`, `DetectDigitMultiplier`, `ValidateSlotRegistry` are the 4 public methods; no fifth call site added by fix-round-13)
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 1-1000+ (no `IsPhoenicisMagicSelfTest` call; verified by repo-wide grep — only Spike_Orchestrator.mq5 calls it)
- Reference: `docs/code-review/fix-round-13.md` § Finding 13.6 ("`spike/Spike_Orchestrator.mq5 § OnInit` — wired `IsPhoenicisMagicSelfTest()` call after the entry banner. SelfTest failure returns `INIT_FAILED`, blocking spike progression.") — fix narrative is honest about spike-only wiring, but the function's own header comment in EnumTypes.mqh:112-113 still claims BootstrapValidator wiring intent that was not fulfilled
- Service: ea (domain/ + core/ + spike/)

**Code:**
```mql5
// domain/EnumTypes.mqh:105-114 — header comment claims production wiring intent
//--- fix-round-13 § 13.6 — SelfTest pinning IsPhoenicisMagic to MAGIC_*
//    constants and the foreign-EA gap (202/203/204) + boundary cases.
//    Future MAGIC_* addition or removal that forgets to update the `||`
//    chain above is caught here; a green SelfTest is the contract that
//    PHOENICISNEX_MAGIC_COUNT, the MAGIC_* set, and IsPhoenicisMagic
//    remain synchronized (see comment on IsPhoenicisMagic).
//
//    Wire from BootstrapValidator::ValidateAll() at OnInit step 1 (per
//    TD-02 §7.4) alongside JsonWriter / IndicatorService SelfTests.   <-- claims wiring
bool IsPhoenicisMagicSelfTest()
  { ... }

// spike/Spike_Orchestrator.mq5:36-48 — actual wiring (spike-only)
int OnInit()
  {
   Print("[Phoenicis] Spike_Orchestrator: G1 compile gate + structural check");

   //--- fix-round-13 § 13.6 — IsPhoenicisMagic SelfTest pinning the `||`
   //    chain to MAGIC_* constants + the BR-3.6 foreign-EA gap (202/203/204).
   //    Wired here because Orchestrator::OnTradeTransaction is the consumer
   //    and EnumTypes.mqh is transitively included via slot includes.
   if(!IsPhoenicisMagicSelfTest())
     {
      Print("[Phoenicis] Spike_Orchestrator: IsPhoenicisMagicSelfTest FAILED");
      return INIT_FAILED;
     }
```

```bash
# Verification — all callers of IsPhoenicisMagicSelfTest()
$ grep -rn "IsPhoenicisMagicSelfTest" MQL5/Experts/PhoenicisNex
domain/EnumTypes.mqh:114:bool IsPhoenicisMagicSelfTest()
spike/Spike_Orchestrator.mq5:44:   if(!IsPhoenicisMagicSelfTest())
spike/Spike_Orchestrator.mq5:46:      Print("[Phoenicis] Spike_Orchestrator: IsPhoenicisMagicSelfTest FAILED");
# 1 declaration + 1 caller, both in the spike. core/Orchestrator.mqh + core/BootstrapValidator.mqh do NOT call it.
```

**Problem:**
fix-round-13 § Finding 13.6 added `IsPhoenicisMagicSelfTest()` (50 LOC: 17 registered-magic checks + 6 negative-case boundary checks) targeting R13 § 13.6 motivation: "Slot V/U/etc. could be re-enabled at any time per BR-1.1 + ADR-005 evolution sequence ... adding `static const int MAGIC_V = 220;` and forgetting to extend the chain produces a silent drop of MAGIC_V close events (foreign-EA-equivalent treatment), which is a regression in the trade-transaction surface. **SelfTest would catch this on first attach.**"

The motivation pivots on **"first attach"** = production OnInit on a live EURUSD chart. But the actual wiring delivered:

1. **Spike_Orchestrator.mq5:44** — runs only when the operator manually attaches `Spike_Orchestrator.ex5` to a chart for structural verification (G1 compile gate per IMPL-059 spike per the file's own header). This is NOT the production attach path.
2. **EnumTypes.mqh:112-113 comment** — claims "Wire from BootstrapValidator::ValidateAll() at OnInit step 1 (per TD-02 §7.4) alongside JsonWriter / IndicatorService SelfTests". This wiring was NOT delivered: BootstrapValidator (`core/BootstrapValidator.mqh:51-84` class definition) has only 4 public methods (`ValidateInputs`, `ValidateSymbol`, `DetectDigitMultiplier`, `ValidateSlotRegistry`) — no 5th method that calls IsPhoenicisMagicSelfTest, no `ValidateAll()` umbrella method, no call insertion in `ValidateInputs::Section 1` either.

So the production EA OnInit path on a live EURUSD H4 chart never runs `IsPhoenicisMagicSelfTest`. An engineer who adds `MAGIC_V=220` and forgets the `||` chain extension would compile and attach successfully on a live chart — the regression gate the R13 § 13.6 fix promised is operationally absent on production attach. This is a partial-fix-as-Finding-13.2-recurrence: structural correctness in source + silent absence of runtime invocation.

The fix-round-13 § Finding 13.6 narrative ("wired IsPhoenicisMagicSelfTest() call after the entry banner. SelfTest failure returns INIT_FAILED, blocking spike progression") is honest about **spike** wiring — the gap is the EnumTypes.mqh:112-113 comment that promises BootstrapValidator wiring without delivering it. Either:
- (a) the comment lies — a future engineer reading EnumTypes.mqh will believe the production wiring is done and not look for the gap; OR
- (b) the comment is forward-looking — but the comment doesn't mark itself as such (no "TODO" / "Phase 2" prefix), so it reads as factual.

**Why This Matters:**
Same Empirical Closure Discipline trap as Finding 14.2. The fix-round closes a finding with structural-only correctness; the runtime-invocation gap is implicitly deferred. R13 § 13.6 explicitly framed the value as "catch this on first attach" — without production OnInit wiring, that value is unrealized.

Operator scenario at 3am (Code Reviewer SKILL Phase 0 mindset): an engineer working on Phase-2 ADR-013 to re-enable Slot V/U adds `static const int MAGIC_V = 220;` to EnumTypes.mqh, bumps PHOENICISNEX_MAGIC_COUNT to 18, and forgets the `||` chain. Compile passes (no static check links the chain to MAGIC_*); production attach on EURUSD H4 passes (no SelfTest runs); first MAGIC_V close event arrives at OnTradeTransaction → `IsPhoenicisMagic(220)` returns false → CircuitBreaker BR-3.6 ring buffer never sees the event → ping-pong detection silently fails for Slot V → operator only learns at the FIRST near-miss-window scenario that the regression is live. Days or weeks of latent silent regression.

Spike-only wiring gives engineers a "you can run this manually if you want" mechanism, but production safety nets must be on the production attach path, not in spike harnesses that only run when explicitly invoked.

**Suggested Fix:**
Two-part fix:

**Part 1 — wire `IsPhoenicisMagicSelfTest` into BootstrapValidator** (delivers the comment-promised wiring, ~10 LOC):

```mql5
// core/BootstrapValidator.mqh — add a 5th method that umbrellas all SelfTests called at OnInit step 1.
// Called from Orchestrator::OnInit BEFORE Phase B (ValidateSymbol) — purely structural check.
bool RunDomainSelfTests() const
  {
   if(!IsPhoenicisMagicSelfTest())
     {
      m_logger.ErrorBypassThrottle("system", "domain_selftest_fail", 0,
         "IsPhoenicisMagicSelfTest reported one or more failures — see prior [SelfTest][FAIL] lines");
      return false;
     }
   //--- room for future SelfTests (CommentParser, JsonWriter, etc.)
   return true;
  }
```

Wire from `core/Orchestrator::OnInit` Phase B step 1:
```mql5
   if(!m_validator.RunDomainSelfTests()) return INIT_FAILED;
```

**Part 2 — drop the misleading comment in EnumTypes.mqh:112-113** until the wiring is actually delivered. Replace with:

```mql5
//    Currently wired in: spike/Spike_Orchestrator.mq5 § OnInit (G1 compile gate).
//    TODO IMPL-NNN: also wire in core/BootstrapValidator::RunDomainSelfTests so production
//    OnInit on a live EURUSD chart runs the regression gate at first attach — without it,
//    the `||` chain ↔ MAGIC_* synchronization is verified only when the spike is run.
```

If the team chooses NOT to wire production (e.g., to keep OnInit minimal for Phase 1), then the comment must explicitly say "Phase 1 = spike-only wiring; production wiring deferred to Phase 2 IMPL-NNN" rather than implying production wiring is done.

LoE: Low (~10 LOC + 1 doc note).

**Level of Effort:** Low

---

### Finding 14.4: 🔵 LOW — `atomic_write_kill_100.ps1` documentation drift introduced by fix-round-13 § 13.4 edit: (a) lines 25-26 contain a duplicate `.PARAMETER Trials` block that appears to be an editor stub left in place of the intended `.PARAMETER FailFastConsecutive` header (the actual `.PARAMETER FailFastConsecutive` block IS correctly present at lines 50-54); (b) lines 70-72 example block references `-StateDir 'MQL5/Files/PhoenicisNex/state'` which is a stale parameter name (param renamed `-StateDir` → `-StateRel` in fix-round-13 § 13.1 cmdlet binding refactor) — operator copy-pasting the example will get a parameter-binding error

**Location:**
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 22-26 (duplicate `.PARAMETER Trials` block)
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 68-72 (example block with stale `-StateDir` param)
- Service: ea-qa (NFR-3.1 verification harness)

**Code:**
```powershell
# atomic_write_kill_100.ps1:22-26 — duplicate .PARAMETER Trials (lines 25-26 should be FailFastConsecutive header)
.PARAMETER Trials
    Number of kill trials to execute. Default: 100.

.PARAMETER Trials                                                                # <-- duplicate
    (defined above) — see also -FailFastConsecutive.                             # <-- stub doc

.PARAMETER StateRel
    Sandbox-relative path under MQL5/Files/ that the spike writes to.
    ...

# atomic_write_kill_100.ps1:68-72 — stale -StateDir example
.EXAMPLE
    # Custom state dir + ini path
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 10 `
         -StateDir 'MQL5/Files/PhoenicisNex/state' `                             # <-- -StateDir no longer exists
         -IniPath 'simulation/headless-tests/atomic_write_kill.ini'
```

```powershell
# Param block at lines 81-90 confirms the actual cmdlet binding:
[CmdletBinding()]
param(
    [int]    $Trials                = 100,
    [string] $StateRel              = 'PhoenicisNex/state',                       # <-- $StateRel (renamed from $StateDir)
    [string] $AgentSubpath          = 'Agent-127.0.0.1-3000',
    [string] $IniPath               = 'simulation/headless-tests/atomic_write_kill.ini',
    [string] $OriginFile            = 'origin.txt',
    [int]    $FailFastConsecutive   = 3,
    [switch] $DryRun
)
```

**Problem:**
Two distinct documentation drifts introduced by the fix-round-13 § 13.4 edit (which added `-FailFastConsecutive`) + § 13.1 edit (which renamed `-StateDir` to `-StateRel`):

1. **Lines 25-26 duplicate `.PARAMETER Trials`**: an editor pattern likely intended to add a `.PARAMETER FailFastConsecutive` block at this position (between Trials and StateRel) but the heading copied from above was never updated. The actual `.PARAMETER FailFastConsecutive` block is correctly written at lines 50-54 — so lines 25-26 are dead doc content. PowerShell's `Get-Help` on the script will render two redundant Trials sections + a stub note.

2. **Lines 70-72 example uses `-StateDir`**: the cmdlet binding param was renamed `-StateDir` → `-StateRel` in fix-round-13 § 13.1 (see actual param block at line 84). The `.EXAMPLE` block was not updated. Operator who copy-pastes:
   ```
   pwsh -File ... -StateDir 'MQL5/Files/PhoenicisNex/state' ...
   ```
   will get `Get-Help`-style parameter binding error: "A parameter cannot be found that matches parameter name 'StateDir'". On strict-mode PowerShell (`Set-StrictMode -Version Latest` IS set at line 92), this is a hard exception; the operator loses 30s figuring out the rename before retrying.

   Also, the relative-path semantic changed: old `-StateDir 'MQL5/Files/PhoenicisNex/state'` was a path under `$RepoRoot`; new `-StateRel 'PhoenicisNex/state'` is the sandbox-relative segment that gets composed under `<TesterAgentRoot>/MQL5/Files/`. So even if the operator manually fixed the param name, the value semantic is different (`MQL5/Files/PhoenicisNex/state` would resolve to `<TesterAgentRoot>/MQL5/Files/MQL5/Files/PhoenicisNex/state` — wrong by 1 prefix-doubling).

This is a minor docs-tested-with-the-PR-narrative-not-the-code-state defect class. Both issues are LOW because the harness logic itself is correct AND the actual `param()` block authoritatively binds the names — but the `Get-Help` surface (lines 22-79) is what an operator running `Get-Help atomic_write_kill_100.ps1 -Examples` will see, and that surface is currently inconsistent with reality.

**Why This Matters:**
The Tier 1.5 walk batch-2 operator session is the next consumer of this script. The walk's session budget is 30 minutes; an operator trying out the documented `.EXAMPLE` block first (per standard PowerShell discoverability) will hit the param-binding error and lose ~5 minutes troubleshooting before checking the source `param()` block. Compounded with the fail-fast circuit's 3-min discovery time, the operator ends up at ~8 min sunk before any Tester-tree empirical run — eats 27% of the walk session budget on doc drift recovery alone.

This is also a regression-class concern for `mt5-headless-backtest § Step 0 § Permission Capture` workflow which standardizes operator interaction with run scripts via `Get-Help` first.

**Suggested Fix:**
```powershell
# atomic_write_kill_100.ps1:22-31 — replace duplicate Trials block with the missing FailFastConsecutive header.
.PARAMETER Trials
    Number of kill trials to execute. Default: 100.

.PARAMETER FailFastConsecutive
    fix-round-13 § 13.4 — abort the trial loop with verdict=FAIL_FAST after this many
    consecutive startup_timeout trials. Healthy runs may see 1-2 transient timeouts
    (cold-bootstrap variance, history download); 3-in-a-row signals a path-binding
    misconfiguration (Finding 13.1 class). Default: 3. Set to 0 to disable.

.PARAMETER StateRel
    ...
```
(Effectively merges lines 50-54 contents into the empty slot at 25-26 and removes the duplicate; no net LOC change.)

```powershell
# atomic_write_kill_100.ps1:68-72 — fix the .EXAMPLE param name and value.
.EXAMPLE
    # Custom state-relative path + agent subpath (parallel-optimisation install)
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 10 `
         -StateRel 'PhoenicisNex/state' `
         -AgentSubpath 'Agent-127.0.0.1-3001' `
         -IniPath 'simulation/headless-tests/atomic_write_kill.ini'
```

(Adds `-AgentSubpath` to showcase the new param while we're touching the example block.)

LoE: Low (~10 LOC reorganization + 1 example value rewrite).

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-14.1 — fix-round-13 § XS-13.2 / Phase 5 mechanical gate #9 added correctly in shape but is **as effective as the originating finding's grep set** — when the originating grep is scope-narrower than the actual defect class (as in fix-round-13 § 13.2 where the grep used `IMPL-053\+` instead of the broader `IMPL-053(\+| |\.|$)` class regex), the gate verifies the narrow class is gone but the broader class persists; same root-cause defect class continues to recur (R12 § 12.8 → R13 § 13.2 → R14 § 14.1)

The gate's mandate "re-run the originating R-finding's pattern grep" presumes the originating grep was well-scoped. The R12 → R13 → R14 chain shows this is structurally fragile: each round's originating grep tends to use the LITERAL pattern from the cited sites, not the BROADEST regex that captures the defect class. Recommend adding clause (b) to gate #9 per Finding 14.1 Suggested Fix Part 2 — both grep variants required, and any non-zero hit on the broader-class grep forces the engineer to either expand the sweep or explicitly scope-out non-target sites. This pushes the post-fix verification to **defect-class-completeness**, not just **literal-pattern-completeness**.

### XS-14.2 — Defined-but-never-called SelfTest pattern is broader than fix-round-13 surface — `helpers/CommentParser::SelfTest`, `helpers/JsonWriter::SelfTest`, `services/PortfolioMonitor::SelfTest`, `services/RiskManager::SelfTest` AND `services/CircuitBreaker::SelfTest` are all defined but have no caller in production OnInit OR any spike harness; fix-round-13 § 13.5 added Case E to one of these (CircuitBreaker) without addressing the broader wiring gap

The 5 dead SelfTests (4 pre-existing + the just-extended CircuitBreaker) collectively embody ~30-50 LOC of defensive test code each that detects nothing at runtime. They're structurally orthogonal to Findings 14.2 + 14.3 (which are specific to the fix-round-13 deliverable scope), but they suggest a project-wide refactor opportunity: a `core/SelfTestSuite::RunAll()` umbrella method that BootstrapValidator invokes at OnInit step 1 (alongside ValidateInputs), running all defined SelfTests in dependency order. Recommend a Phase-2 IMPL-NNN ticket to bulk-wire all 5 (+ IsPhoenicisMagicSelfTest from Finding 14.3) into BootstrapValidator. LoE: Low (~30 LOC umbrella method + 1 wire in Orchestrator::OnInit).

### XS-14.3 — `EnumTypes.mqh:112-113` comment claim ("Wire from BootstrapValidator::ValidateAll() at OnInit step 1 (per TD-02 §7.4)") is forward-looking documentation written as if past-tense — same defect class as TD-02 §7.4's documented intent vs `core/BootstrapValidator.mqh`'s actual `ValidateAll` method (which doesn't exist; only `ValidateInputs/ValidateSymbol/DetectDigitMultiplier/ValidateSlotRegistry` are public)

`TD-02 §7.4` references "BootstrapValidator::ValidateAll()" as the umbrella; the actual class never had a `ValidateAll` method. The Orchestrator calls `m_validator.ValidateInputs()` then `m_validator.ValidateSymbol()` separately (per TD-02 §7.4 line 1654). So either:
- (a) `ValidateAll()` is a documentation alias for the sequential calls — in which case `EnumTypes.mqh:112-113` should reference the actual method names; OR
- (b) `ValidateAll()` was intended as a future umbrella method — in which case TD-02 §7.4 + `EnumTypes.mqh:112-113` should mark it as such with a TODO IMPL-NNN ticket reference.

This is a TD-vs-impl drift that R14 surfaces incidentally; not a fix-round-13 regression but worth flagging as backlog. Tracked under XS-14.3 advisory; not blocking R14 closure.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 14.1 | 🟠 HIGH | Cross-Service Consistency / Doc | fix-round-13 § 13.2 verification grep was scope-narrower than the defect class — 23 stale "deferred to IMPL-053" sites still extant repo-wide (10 in `slots/` without `+`, 13 in `services/`/`core/`/`spike/` with `+`); same root-cause defect class as R12 § 12.8 → R13 § 13.2 recurrence at next-coarser granularity; gate #9 shape-correct but as effective as its grep set | `slots/Slot_BR.mqh:145, Slot_F.mqh:150, Slot_G2.mqh:260, Slot_GO.mqh:130, Slot_I.mqh:288,350, Slot_J.mqh:150, Slot_LX.mqh:189, Slot_S.mqh:251,313` (10 sites) + `services/RiskManager.mqh:439, PortfolioState.mqh:71,276,289, core/BootstrapValidator.mqh:73, spike/Spike_Slot_*.mq5 (8 sites)` | Low |
| 14.2 | 🟡 MEDIUM | Test Coverage Gap | `CCircuitBreaker::SelfTest()` (Cases A–E including new fix-round-13 § 13.5 Case E) has zero callers — no `Spike_CircuitBreaker.mq5` exists; production `core/Orchestrator::OnInit` doesn't invoke it; Case E is structurally correct but operationally inert until a spike or production wiring is added | `services/CircuitBreaker.mqh:285-417` + `core/Orchestrator.mqh:289` (Init only, no SelfTest call) + missing `spike/Spike_CircuitBreaker.mq5` | Low |
| 14.3 | 🟡 MEDIUM | Test Coverage Gap | `IsPhoenicisMagicSelfTest()` is wired only in `spike/Spike_Orchestrator.mq5:44` — `core/BootstrapValidator.mqh` doesn't call it (no `ValidateAll` umbrella, no 5th method); `EnumTypes.mqh:112-113` header comment claims production wiring intent that was not delivered; production EA on live EURUSD H4 attach never runs the magic-set regression gate that R13 § 13.6 motivated | `domain/EnumTypes.mqh:112-114` + `core/BootstrapValidator.mqh:51-84` (no IsPhoenicisMagicSelfTest call) + only `spike/Spike_Orchestrator.mq5:44` calls it | Low |
| 14.4 | 🔵 LOW | Test Code Quality / Docs | `atomic_write_kill_100.ps1` doc drift introduced by fix-round-13: (a) duplicate `.PARAMETER Trials` block at lines 25-26 (stub leftover from § 13.4 edit); (b) `.EXAMPLE` at lines 70-72 references stale `-StateDir 'MQL5/Files/PhoenicisNex/state'` parameter (renamed to `-StateRel 'PhoenicisNex/state'` in § 13.1 refactor; semantic also changed) — operator copy-pasting the example hits param-binding error + path semantic drift | `simulation/scripts/atomic_write_kill_100.ps1:22-26, 68-72` | Low |

---

## Recommendation

**Ready for fix-round-14 with no blockers.** Fix-round-13 surface is structurally clean for the substantive R13 deltas (path-binding correction + spike cleanup guard + harness fail-fast + SelfTest Case E + `IsPhoenicisMagicSelfTest` body). All 6 R13 findings + 2 XS items materially addressed. R14 surface is dominantly **scope-completeness** — the same defect class (declared-vs-actual narrative scope drift) raised in R13 § XS-13.2 recurs at the next-coarser granularity in fix-round-13 § 13.2 grep set + § 13.5 / § 13.6 SelfTest wiring gaps.

**Fix priority:**
1. **14.1 (HIGH)** — broader-class grep + sweep across 23 sites repo-wide (~30 LOC mechanical) + strengthen workflow.md gate #9 with broadest-class grep clause (~5 LOC + 1 paragraph).
2. **14.2 (MEDIUM)** — add `spike/Spike_CircuitBreaker.mq5` (~25 LOC) OR call `m_breaker.SelfTest()` from `Orchestrator::OnInit` after WireServices behind a `#ifdef PHOENICISNEX_SELFTEST` flag — pick one. Best landed alongside 14.3 since both have the same wiring-gap defect class.
3. **14.3 (MEDIUM)** — add `BootstrapValidator::RunDomainSelfTests` (~10 LOC) + wire from `Orchestrator::OnInit` Phase B step 1 + drop the misleading `EnumTypes.mqh:112-113` BootstrapValidator-wiring claim until delivered.
4. **14.4 (LOW)** — `atomic_write_kill_100.ps1` doc fixes (~10 LOC reorganization). Trivial.

**Plan Staleness Sentinel:** 7 closures since R07 — within 10-closure threshold ✅; this review counts as 0 closures (review-round files don't increment Sentinel). Mid-Phase Audit P4 counter at 6 ≥ 5 trigger remains advisory; `/impl-plan-review all` can wait until after IMPL-062 closes (so the review captures the full P4 tail in one pass).

**Cross-cutting observation:**
The R12 → R13 → R14 chain shows a recurring "fix-round narrative scope > executed sweep scope" defect class. R12 § XS-12.3 + R13 § XS-13.2 added Phase 5 gates (#6 trailer integrity → #7 Phase Status sweep → #8 narrative-section freshness → #9 post-fix grep). Each gate addresses the previous round's specific defect, but the meta-pattern (engineer's grep pattern is narrower than the defect class because it's sourced from the originating finding's literal cite rather than the class regex) persists.

R14 § XS-14.1 proposes the structural fix: gate #9 needs (a) literal-pattern verification AND (b) broadest-class verification, with non-zero hits on (b) forcing the engineer to either expand or explicitly scope-out. Without this addition, expect R15 to surface the next-coarser recurrence (e.g., a fix-round closing the broad `deferred to IMPL-053` class but missing `deferred to IMPL-052` or `deferred to IMPL-060` as siblings of the same task-deferral semantic).

**On the structural quality of fix-round-13 closures:**
- Tester-sandbox-tree resolution in `atomic_write_kill_100.ps1` is correct AS WRITTEN ✅; only the doc drift (14.4) needs cleanup.
- Spike cleanup guard (`Spike_AtomicWrite.mq5` path-prefix classification + symmetric end-of-OnInit guard) is correct AS WRITTEN ✅.
- Harness fail-fast circuit (`-FailFastConsecutive` + verdict logic) is correct AS WRITTEN ✅.
- CircuitBreaker SelfTest Case E is correct AS WRITTEN ✅; only the runtime invocation gap (14.2) was missed.
- `IsPhoenicisMagicSelfTest` body is correct AS WRITTEN ✅; only the BootstrapValidator wiring + comment drift (14.3) were missed.
- Slot-comment sweep narrative is correct ABOUT THE 23 SLOT-FILE SITES it claimed to cover ✅; the broader 23 stale repo-wide sites (14.1) were outside the originating grep set.
- Workflow.md gate #9 is correct AS WRITTEN ✅; the meta-gap (14.1's gate-effectiveness clause) needs strengthening.
- nfr-3.1-atomic-write-result.md § 2.3.1/.2/.3 documentation updates are well-shaped ✅; no R14 finding.

R13 fix surface is structurally sound. R14 surface is dominantly **scope completeness** + **wiring-vs-declaration gaps** — every R14 finding except 14.4 is a fix-round-13 deliverable that under-delivered relative to its narrative scope (in 2 cases: the SelfTest body + the runtime invocation gap; in 1 case: the slot comment sweep + the broader-class repo audit). R12's heaviest defect cluster (Findings 12.1 + 12.3 + 12.4 — IMPL-064 harness contract) is now fully closed; R13's heaviest defect cluster (Findings 13.5 + 13.6 — SelfTest extension) is half-closed (body added; runtime invocation gap surfaced as Findings 14.2 + 14.3). The next prevention pattern is XS-14.1 — gate #9 broadest-class verification.
