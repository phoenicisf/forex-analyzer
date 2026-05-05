# Code Review Fix Round 13

| Field | Value |
|-------|-------|
| **Round** | 13 |
| **Review File** | `docs/code-review/review-round-13.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit (planned) |
|---|---------|----------|---------|----------------|------------------|
| 13.1 | Harness inspects Terminal sandbox; Tester writes Tester sandbox | 🔴 CRITICAL | Accept | 1 (`atomic_write_kill_100.ps1`) | TBD |
| 13.2 | 21+ stale "deferred to IMPL-053+" / "Orchestrator wiring" comments | 🟠 HIGH | Accept | 17 slot files / 23 sites | TBD |
| 13.3 | Spike unconditional `FileDelete` cleanup | 🟡 MEDIUM | Accept | 1 (`Spike_AtomicWrite.mq5`) | TBD |
| 13.4 | Harness lacks consecutive-timeout fail-fast | 🟡 MEDIUM | Accept | 1 (`atomic_write_kill_100.ps1`) | TBD (bundled with 13.1) |
| 13.5 | CircuitBreaker SelfTest no Case E (pre-Init guard) | 🔵 LOW | Accept | 1 (`CircuitBreaker.mqh`) | TBD |
| 13.6 | `IsPhoenicisMagic` no SelfTest pinning helper to MAGIC_* | 🔵 LOW | Accept | 2 (`EnumTypes.mqh` + `Spike_Orchestrator.mq5`) | TBD |
| XS-13.1 | Doc-↔-artifact divergence | — | Resolved by 13.1 | 1 (`nfr-3.1-atomic-write-result.md`) | TBD (bundled with 13.1) |
| XS-13.2 | Phase 5 gate missing post-fix grep verification | — | Accept | 1 (`.claude/rules/workflow.md`) | TBD |
| XS-13.3 | `parse_anomaly_count` schema not in api-specs | — | Defer to IMPL-062 | — | (deferred — not blocking R13) |

**Accepted:** 6 findings + 2 XS (XS-13.3 deferred to IMPL-062)
**Rejected:** 0
**Partial:** 0

---

## Accepted Findings — Fixes Applied

### Fix for Finding 13.1: Harness inspects Tester agent sandbox (Approach A)

**Verdict:** Accept
**Scope:** 1 file (harness)
**Changes:**
- `simulation/scripts/atomic_write_kill_100.ps1` — replaced `$StateDir` (live-Terminal-sandbox-relative) with `$StateRel` + `$AgentSubpath` (Tester-tree-aware). New path resolution: `$MetaQuotesRoot = Split-Path (Split-Path $RepoRoot -Parent) -Parent` → `$TesterRoot = Join-Path $MetaQuotesRoot 'Tester'` → `$AgentRoot = $TesterRoot/$TerminalId/$AgentSubpath` → `$AbsStateDir = $AgentRoot/MQL5/Files/$StateRel`. Pre-flight `Test-Path` warns if Tester tree absent (first headless run creates it). Sidecar JSON adds `agent_subpath` + `state_rel` fields for forensic audit.
- `docs/state/nfr-3.1-atomic-write-result.md § 2.3.1` — new sub-section documenting MQL5 per-mode sandbox separation (live vs Tester) + the 3-row component-path table.

**Verification (G1 + DryRun smoke):**
- `MetaEditor64.exe /compile:PhoenicisNex.mq5 /log` → `Result: 0 errors, 0 warnings, 3731 ms elapsed`
- `Spike_AtomicWrite.mq5` compile → `Result: 0 errors, 0 warnings, 432 ms`
- `powershell.exe -File atomic_write_kill_100.ps1 -DryRun -Trials 5` → resolved `StateDir = <MetaQuotesRoot>/Tester/<TerminalId>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state` ✅ (matches the spike's runtime sandbox under headless Tester)

### Fix for Finding 13.2: Slot comment sweep (broader grep set)

**Verdict:** Accept
**Scope:** 17 slot files / 23 sites
**Changes (canonical Phase-1 wording):**
- `slots/Slot_F.mqh:200` — exit-side OrderClose stub
- `slots/Slot_BI.mqh:264` — exit-side OrderSend close stub
- `slots/Slot_D.mqh:209` — exit-side OrderClose stub
- `slots/Slot_GO.mqh:180` — exit-side OrderSend close stub
- `slots/Slot_C.mqh:208 + 340` — pending-payload schema-lock + exit OrderClose
- `slots/Slot_BR.mqh:192` — exit-side OrderSend close stub
- `slots/Slot_G2.mqh:310` — exit-side OrderSend close stub
- `slots/Slot_J.mqh:212` — exit-side OrderClose stub (G4 BR-7.2 attestation preserved)
- `slots/Slot_I.mqh:342` — exit-side OrderSend close stub
- `slots/Slot_K.mqh:212` — Ichimoku cloud-touch deferral note
- `slots/Slot_LX.mqh:228` — exit-side OrderSend close stub
- `slots/Slot_M.mqh:187 + 317` — pending-payload + exit OrderClose
- `slots/Slot_Q.mqh:186 + 316` — pending-payload + exit OrderClose
- `slots/Slot_R.mqh:195 + 325` — pending-payload + exit OrderClose
- `slots/Slot_T.mqh:186 + 316` — pending-payload + exit OrderClose
- `slots/Slot_S.mqh:305` — exit-side OrderSend close stub
- `slots/Slot_P.mqh:298 (banner) + 550 + 576` — file-header banner replaced with single-line pointer; both exit-paths use canonical wording

**Canonical replacement wording:**
```mql5
//--- Phase-1 stub: logger-only milestone; broker close wires at
//    IMPL-017 / IMPL-062 (RiskManager::OpenOrder) per ea.md.
```
Pending-payload schema-lock comments replaced with: `(minimal JSON — full schema in state-persistence-schema.yaml § PendingMachine)`.

**Post-fix grep verification (Phase 5 gate #9):**
```
$ grep -rE "deferred to IMPL-053\+|deferred to Orchestrator wiring|deferred to orchestrator wiring|schema lock deferred to IMPL-053" MQL5/Experts/PhoenicisNex/slots
0 hits  (down from 23)
```

### Fix for Finding 13.3: Spike `FileDelete` path-prefix guard

**Verdict:** Accept
**Scope:** 1 file (`Spike_AtomicWrite.mq5`)
**Changes:**
- `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5:103-130` — replaced unconditional `FileDelete(InpStateFile)` + `FileDelete(InpTmpFile)` with a `StringFind` prefix check. Path classified as `sandbox` / `production` / `unknown` and logged via `[spike][ev=path_guard][class=...]` for operator audit. Cleanup runs only when `class == "sandbox"`. End-of-run cleanup (formerly lines 192-194) gated symmetrically. Inspect-path cleanup ownership migrates to the harness (`atomic_write_kill_100.ps1` already does `Remove-Item $StateTmp` per trial).

**Verification:** `Spike_AtomicWrite.mq5` compile → `Result: 0 errors, 0 warnings, 432 ms`. The `[ev=path_guard]` Print fires unconditionally so a Tier 1.5 walk operator can `grep -E "\[ev=path_guard\]" tester_log.txt` and confirm the safety property at run time.

### Fix for Finding 13.4: Harness fail-fast circuit (bundled with 13.1)

**Verdict:** Accept
**Scope:** 1 file (`atomic_write_kill_100.ps1`)
**Changes:**
- New `-FailFastConsecutive` parameter (default `3`; set to `0` to disable). Trial loop tracks `$consecutive_timeouts`; on every successful poll the counter resets, on every startup-timeout it increments. When `$consecutive_timeouts -ge $FailFastConsecutive`, loop aborts with verdict `FAIL_FAST` and prints an operator-audit hint listing `$AbsStateDir`, the `.ini` override, and the Tester-sandbox path expectation.
- Sidecar JSON adds `failed_fast` (bool) + `fail_fast_consecutive` (int).
- Verdict logic now distinguishes `PASS` / `FAIL_FAST` / `FAIL`.

**Verification:** DryRun smoke prints `verdict=DRY_RUN` and writes sidecar with `failed_fast: false`, `fail_fast_consecutive: 3` ✅.

**Operator-experience win:** under Finding 13.1's pre-fix path mismatch, a 100-trial run would have wall-clocked at 100 × 60s = 100 min before reporting FAIL. With FailFastConsecutive=3, the same misconfiguration aborts in ~3 min — compatible with the Tier 1.5 walk 30-min session budget.

### Fix for Finding 13.5: CircuitBreaker SelfTest Case E

**Verdict:** Accept
**Scope:** 1 file (`CircuitBreaker.mqh`)
**Changes:**
- `services/CircuitBreaker.mqh § SelfTest` — added Case E exercising the dual-gate added in fix-round-12 § 12.6. Saves `m_logger`, sets to NULL, calls `RecordOpen(200, 0, t0)` + `RecordClose(200, 0, t0)`, asserts `m_count == 0` (buffer not mutated), restores `m_logger`. Header comment block updated to list Cases A–E and cite R12 § 12.6 + R13 § 13.5.

**Verification:** `Spike_Orchestrator.mq5` compile (transitively pulls CircuitBreaker) → `Result: 0 errors, 0 warnings, 621 ms`. Case E will run under the Phase 2 spike harness when `CCircuitBreaker::SelfTest()` is invoked.

### Fix for Finding 13.6: `IsPhoenicisMagic` SelfTest

**Verdict:** Accept
**Scope:** 2 files (`EnumTypes.mqh` + `Spike_Orchestrator.mq5`)
**Changes:**
- `domain/EnumTypes.mqh` — added free function `bool IsPhoenicisMagicSelfTest()` below `IsPhoenicisMagic`. Tests all 17 registered magics (CD/F/H/J/K/G/GO/M/L/Q/R/B/BR/I/S/P/T) for `true`, plus the BR-3.6 foreign-EA gap (202/203/204) and boundaries (199, 220 = deleted Slot U, 0, -1) for `false`. Per-failure `Print` shows the exact magic + expected/actual; PASS line summarizes `17 registered + 6 negative cases PASSED`.
- `spike/Spike_Orchestrator.mq5 § OnInit` — wired `IsPhoenicisMagicSelfTest()` call after the entry banner. SelfTest failure returns `INIT_FAILED`, blocking spike progression.

**Verification:** `Spike_Orchestrator.mq5` compile (transitively pulls EnumTypes) → `Result: 0 errors, 0 warnings, 621 ms` ✅.

### Resolution for XS-13.1: Doc re-amend (bundled with 13.1)

**Verdict:** Accept (closed by 13.1 implementation)
**Scope:** 1 file (`docs/state/nfr-3.1-atomic-write-result.md`)
**Changes:**
- `§ 2.3` updated header to cite both R12 + R13 finding sets and added the cross-finding column to the override table.
- New `§ 2.3.1` documents MQL5 per-mode sandbox separation + the spike-write-target / harness-inspect / live-mode-StatePersistence path triplet.
- New `§ 2.3.2` documents the spike cleanup guard (Finding 13.3).
- New `§ 2.3.3` documents the harness fail-fast circuit (Finding 13.4).

### Resolution for XS-13.2: Phase 5 mechanical gate #9

**Verdict:** Accept
**Scope:** 1 file (`.claude/rules/workflow.md`)
**Changes:**
- `## Phase 5 Closure mechanical gates` — added gate #9 "Post-fix grep verification (impl-review-fix only)": after a fix-round commits land, re-run the originating R-finding's pattern grep with `--count`; record the post-condition. Pass criterion: zero matches. Updated the "Why this is here" paragraph to cite R13 (Finding 13.2 / 13.5 / 13.6 — fix-round-12 narratives advertised wider sweeps than the engineer's grep set or scope captured). Failure-escalation row bumped from "8 gates" → "9 gates".

### Deferral for XS-13.3: `parse_anomaly_count` schema in api-specs

**Verdict:** Defer to IMPL-062
**Rationale:** XS-13.3 calls for `docs/api-specs/baseline-per-slot-schema.yaml` companion file (≤80 LOC). The schema's intended consumer is IMPL-062 5-yr regression Bucket A drift comparison; landing the schema before IMPL-062 starts risks doc drift if the regression code shapes the consumer interface differently. Tracking under IMPL-062 task scope; not blocking R13 closure.

---

## Rejected Findings — Evidence

None — all findings accepted (1 deferred).

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 6 + 3 XS = 9 |
| Accepted | 8 (6 findings + 2 XS) |
| Rejected | 0 |
| Partial | 0 |
| Deferred | 1 (XS-13.3 → IMPL-062) |
| Files Modified | 23 (17 slots + 4 services/spike + 2 doc/rule) |
| New Tests Added | 2 (CircuitBreaker Case E + IsPhoenicisMagicSelfTest) |
| G1 Compile Gates | 3/3 PASS (PhoenicisNex.mq5, Spike_AtomicWrite.mq5, Spike_Orchestrator.mq5) — all `0 errors, 0 warnings` |
| G2 Smoke | n/a (live-chart attach not part of fix scope) |
| G3 Headless backtest | n/a (deferred to Tier 1.5 walk batch-2) |
| G4 Log review | partial — DryRun sidecar verified |
| Post-fix grep (gate #9) | `grep -rE "deferred to IMPL-053\+\|deferred to Orchestrator wiring\|deferred to orchestrator wiring\|schema lock deferred to IMPL-053" slots/` → 0 hits ✅ |
| Commits | TBD (single fix-round-13 commit per micro-commit pattern) |

## Cross-cutting Notes

**Fix-round-13 closes 3 R12-era under-delivered scope sites (Findings 13.2 / 13.5 / 13.6 cluster) plus 1 next-coarser-granularity recurrence (Finding 13.1 — sandbox-tree level vs R12's relative-path level).** The Phase 5 gate #9 added by XS-13.2 is the cross-cutting prevention for the closure narrative ↔ executed sweep mismatch — applying it retroactively to fix-round-12 would have surfaced all 4 of these findings at the R12 commit boundary.

**IMPL-064 deferred-AC E-AC#1 (`[boot-cold]` + `[file-blob-check]`) remains Active in `deferred-ac-registry.md` (expiry 2026-05-18).** With the R13 path-binding fix in place, the next operator session that runs `atomic_write_kill_100.ps1 -Trials 100` will exercise the production NFR-3.1 contract empirically. Recommend running `-Trials 5 -Verbose` first to confirm the Tester sandbox tree is being correctly inspected, then escalate to full 100-trial run.

**Recommendation:** Ready for next review round (R14) OR ready for Tier 1.5 walk batch-2 — operator's choice. Substantive fix surface is structurally clean; remaining gaps (XS-13.3 schema yaml + the actual numeric NFR-3.1 100/100 result) are operator-runtime concerns scheduled for Phase 2 / Tier 1.5 walk respectively.
