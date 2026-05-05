# Code Review Round 13

| Field | Value |
|-------|-------|
| **Round** | 13 |
| **Target** | `all` — focused on (a) post-fix-round-12 deltas: `simulation/headless-tests/atomic_write_kill.ini` ([TesterInputs] block + 4 overrides), `simulation/scripts/atomic_write_kill_100.ps1` (poll-then-attack + `startup_timeout_count` counter + verdict gate), `domain/EnumTypes.mqh` (`IsPhoenicisMagic` set-membership rewrite), `services/CircuitBreaker.mqh` (RecordOpen/RecordClose pre-Init NULL-logger guard + Print fallback), `simulation/scripts/parse_baseline.py` (`_parse_deals` tuple return + `parse_anomaly_count` counter + stderr WARN), 11 slot files (entry-side stub-comment update from "OrderSend deferred to IMPL-053+" → "OrderSend wiring lives in RiskManager::OpenOrder per ea.md"), `docs/state/baseline-per-slot.json` (`parse_anomaly_count: 0`), `docs/state/nfr-3.1-atomic-write-result.md § 2.3` (override-table rewrite), `docs/state/deferred-ac-registry.md` IMPL-068 row (`**Blocks: IMPL-062**`), `docs/state/impl-plan.md` (Open Risks R-7 added). Cumulative reviewed surface: ~9,420 LOC (R01..R12). |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~25 LOC delta `.ini` + ~50 LOC delta `.ps1` + ~35 LOC delta `.py` + ~30 LOC delta CircuitBreaker.mqh + ~25 LOC delta EnumTypes.mqh + ~5 LOC × 11 slot files + ~10 LOC state docs. Cumulative reviewed surface: ~9,420 LOC (R01..R12). |
| **Plan Staleness Sentinel** | 7 closures since R07 (R12 fix-round counted as +1); below 10-closure threshold ✅. Last `/impl-plan-review` was R07 (2026-05-04). Counter-trigger advisory still active per impl-plan TL;DR (Mid-Phase Audit P4 counter at 6 ≥ 5). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 1 |
| MEDIUM   | 2 |
| LOW      | 2 |
| **Total**| **6** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | `IsPhoenicisMagic` set-membership ladder closes the foreign-EA gap noted in 12.2; OnTradeTransaction → CircuitBreaker chain still gated 5 layers; PowerShell harness uses `Set-StrictMode -Version Latest` + `$ErrorActionPreference='Stop'`. No new `#import`/`WebRequest`/credential leaks. |
| 2 | Business Logic Correctness | ⚠️ Finding | (a) **Finding 13.1 CRITICAL** — `atomic_write_kill_100.ps1` inspects `<RepoRoot>/MQL5/Files/PhoenicisNex/state/state.json` but the spike running headless via Strategy Tester writes to `<TerminalDataDir>/Tester/<terminal-id>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state/state.json` — a structurally separate sandbox per `mt5-headless-backtest § references/log-paths.md`. R12's `[TesterInputs]` redirect changes the *relative path* but not the *sandbox tree*. (b) `Spike_AtomicWrite::OnInit` line 104-105 unconditionally `FileDelete(InpStateFile)` at start; the .ini override now points that delete at `PhoenicisNex/state/state.json` (= production path). Currently isolated by sandbox separation in 13.1; if 13.1 ever resolved by FILE_COMMON or Tester-path inspection, the delete becomes destructive (Finding 13.3 MEDIUM). |
| 3 | Error Handling | ✅ Pass | `parse_baseline.py` now surfaces parse anomalies via stderr WARN + counter + summary. CircuitBreaker pre-Init guard adds Print fallback before silent buffer-write. PowerShell harness verdict gate now fail-closes when `startup_timeout_count > 0`. |
| 4 | Performance | ⚠️ Finding | (a) Harness lacks early-bail when consecutive trials fail with `startup_timeout` — under Finding 13.1's path mismatch, every trial waits the full 60s poll deadline → 100 trials × 60s = **100 minutes** of wall-clock burn before the operator sees `verdict=FAIL` (Finding 13.4 MEDIUM). |
| 5 | Over-Engineering | ✅ Pass | 1-line NULL-logger early-return is the minimum-viable defense-in-depth posture; switch from range-check to `||` chain is constrained by MQL5's `error 188` on `static const` switch labels (documented inline). |
| 6 | Cross-Service Consistency | ⚠️ Finding | `IsPhoenicisMagic` and `PortfolioState::IsKnownMagic` now agree on the 17-magic set ✅ (XS-12.1 closed). BUT — fix-round-12 §12.8 / XS-12.3 advertised "all 11 slot files" (and review §12.8 expected propagation across all 21 slots) updated to drop the stale "deferred to IMPL-053+" framing — actual grep shows the entry-side comment got the new wording in some files but **18+ exit-side and pending-payload sites in 17 slot files still carry the stale "OrderSend/OrderClose deferred to IMPL-053+" or "schema lock deferred to IMPL-053+" or "OrderClose deferred to Orchestrator wiring" framing** (Finding 13.2 HIGH — partial fix-round regression). |
| 7 | Test Coverage Gaps | ⚠️ Finding | (a) `CCircuitBreaker::SelfTest` cases A-D do not exercise the new pre-Init path; Recommendation 12.6 explicitly proposed a SelfTest case ("pre-Init RecordOpen call → assert ring buffer NOT mutated + Print fallback emitted") not added (Finding 13.5 LOW). (b) `IsPhoenicisMagic` has no SelfTest exercising registered/unregistered/boundary magics; Recommendation 12.2 proposed one not added (Finding 13.6 LOW). (c) `nfr-3.1-atomic-write-result.md § 2.3` says the harness now exercises live taskkill against the production state path — but Finding 13.1 says it cannot, because the Tester sandbox isolates the spike's writes. The doc-↔-artifact divergence first noted in R12 § XS-12.2 persists in subtler form. |
| 8 | Architecture Compliance | ✅ Pass | EnumTypes.mqh fix preserves `PHOENICISNEX_MAGIC_COUNT=17` invariant + cross-references CrossSlotCoordinator predicate (XS-12.1). CircuitBreaker dual-gate (Option A orchestrator + Option B in-class NULL-logger) preserves ADR-002 composition root. Slot stubs still emit `entry_signal` Logger.Info per ADR-002 / TD-02 §5.8 contract — OrderSend wiring still architecturally deferred to IMPL-017 / IMPL-062. |
| 9 | Technical Design Compliance | ⚠️ Finding | `nfr-3.1-atomic-write-result.md § 2.3` documents `[TesterInputs]` overrides matching the .ini ✅. But `parse_baseline.py` schema now exposes `parse_anomaly_count` field at top-level + `baseline-per-slot.json` regenerated to include it — the schema is **still NOT defined in `docs/api-specs/*.yaml`**, same gap as R12 §12.6 narrative. Adding a field tightens the JSON shape without a written contract. LOW-grade tracked under R13 cross-service note. |
| 10 | Test Code Quality | ✅ Pass | PowerShell harness retains `Set-StrictMode -Version Latest` + try/catch around `Start-Process` + `Wait-Process -Timeout 10`. Python parser uses `html.parser` stdlib — no regex backtracking risk. SelfTest macros restored buffer post-run. |
| 11 | Empirical AC Closure | ⚠️ Finding | Forbidden-pattern grep on `docs/state/impl-plan.md` for "deferred to operator-runtime" / "deferred per .* precedent" / "structurally complete.*deferred" / "live verification deferred" → **0 hits** ✅. BUT — IMPL-064's `[boot-cold]` + `[file-blob-check]` E-AC was the heaviest-weight contract of R12, and it still cannot be satisfied by the current harness because of the Tester-sandbox path mismatch (Finding 13.1 CRITICAL). The verdict gate now fail-closes (`startup_timeout_count > 0` ⇒ FAIL), so this is **not** a false-PASS regression — but the harness will produce a 60-min FAIL on every invocation until the path is resolved. IMPL-068 paired bundle (M+T+Q `force_clear_count` AND ADR-008 amendment) — both rows expire 2026-05-18; still depends on IMPL-062 (R-7 annotation now visible ✅). |
| 12 | Functional Walk (PhoenicisNex Tier 1.5) | ⏭ Skip — not yet executed | `bootstrap_smoke.ini` walk batch-2 still has not run since FIX-001/002 + IMPL-061/064/068 + R12 fix-round closures. Tier 1.5 walk batch-2 is what would reveal Finding 13.1 empirically; recommend the walk runs an `atomic_write_kill_100.ps1 -Trials 5 -Verbose` against the corrected `.ini`+harness pair as part of the same operator session, NOT a full 100-trial run, until the sandbox path is verified. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; PowerShell harness reads `origin.txt` (already validated by IMPL-001 + IMPL-046) + `.ini` paths (committed); no new env-var / secret consumer. `[config-audit]` not triggered. |

---

## Findings

### Finding 13.1: 🔴 CRITICAL — `atomic_write_kill_100.ps1` ตรวจสอบ `<TerminalDataDir>/MQL5/Files/...` แต่ Strategy Tester ของ MT5 เขียน `state.json` ลง `<TerminalDataDir>/Tester/<id>/Agent-127.0.0.1-3000/MQL5/Files/...` ซึ่งเป็น sandbox tree คนละต้น — R12 §12.1 fix แก้ relative path แต่ไม่แก้ sandbox tree

**Location:**
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 77-79 (`$RepoRoot = Split-Path -Parent` x2 → `<TerminalDataDir>` ; `$AbsStateDir = Join-Path $RepoRoot $StateDir`)
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 160-161 (`$StateJson = Join-Path $AbsStateDir 'state.json'`)
- File: `simulation/headless-tests/atomic_write_kill.ini`, Lines: 39-50 ([TesterInputs] block — `InpStateFile=PhoenicisNex/state/state.json` is a *relative MQL5 sandbox path*, not an absolute path)
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5`, Line: 32 (`FileOpen(tmppath, FILE_WRITE|FILE_TXT|FILE_ANSI)` — no `FILE_COMMON` flag, so the path resolves in the Tester agent's local sandbox when run headless)
- Reference: `.agents/skills/mt5-headless-backtest/references/log-paths.md` (Tester-path tree separation contract)
- Service: ea-qa (NFR-3.1 verification harness)

**Code:**
```powershell
# atomic_write_kill_100.ps1:77-79 + 160-161
$RepoRoot     = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent  # = <TerminalDataDir>
$AbsStateDir  = Join-Path $RepoRoot $StateDir                            # = <TerminalDataDir>/MQL5/Files/PhoenicisNex/state
...
$StateJson    = Join-Path $AbsStateDir 'state.json'                      # = <TerminalDataDir>/MQL5/Files/PhoenicisNex/state/state.json
```

```mql5
// Spike_AtomicWrite.mq5:30-46  (no FILE_COMMON ⇒ default sandbox)
bool WriteAtomic(string path, string tmppath, string content)
{
   int h = FileOpen(tmppath, FILE_WRITE|FILE_TXT|FILE_ANSI);   // no FILE_COMMON
   ...
   if(!FileMove(tmppath, 0, path, FILE_REWRITE))               // common-flag = 0 (local sandbox)
   ...
}
```

```ini
; atomic_write_kill.ini:39-50 (relative path under MQL5/Files/ in whichever sandbox the EA runs in)
[TesterInputs]
InpStateFile=PhoenicisNex/state/state.json
InpTmpFile=PhoenicisNex/state/state.json.tmp
```

**Problem:**
MQL5's file-I/O sandbox is **per-mode**: an EA running on a live chart resolves relative paths under `<TerminalDataDir>/MQL5/Files/...`, but the SAME EA running headless via Strategy Tester (`terminal64.exe /config:atomic_write_kill.ini`) resolves the SAME relative path under `<TerminalDataDir>/Tester/<terminal-id>/Agent-127.0.0.1-3000/MQL5/Files/...` — a structurally separate sandbox tree per project documentation `mt5-headless-backtest § references/log-paths.md`:

> Tester log lives in a different tree from runtime log. Runtime: `Terminal/{id}/MQL5/Logs/YYYYMMDD.log`. Tester: `Tester/{id}/Agent-127.0.0.1-3000/logs/YYYYMMDD.log`. Always use the Tester path for backtest runs.

This separation applies to **all** file I/O (logs, state files, journals), not just logs. The spike's `FileOpen(...)` calls (lines 32, 40, 57) carry no `FILE_COMMON` flag, so writes go to the per-agent local sandbox.

R12 § 12.1 closed the earlier `spike/state.json` vs `state/state.json` *relative-path* mismatch by adding `[TesterInputs]` overrides. But the *tree-level* mismatch persists: regardless of the relative path, the harness's `$AbsStateDir` resolves to the live-terminal sandbox (because `$PSScriptRoot` is the `simulation/scripts/` directory inside `<TerminalDataDir>`), while the spike — running in Strategy Tester — writes to the Tester agent sandbox.

Consequence per trial:
1. Harness launches `terminal64.exe /config:atomic_write_kill.ini` → spike runs in Strategy Tester sandbox.
2. Spike's `WriteAtomic` writes to `<TerminalDataDir>/Tester/<id>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state/state.json{,.tmp}` — invisible to the harness.
3. Harness polls `<TerminalDataDir>/MQL5/Files/PhoenicisNex/state/state.json` for 60 s — never appears.
4. `startup_timeout_count++` per the new fix-round-12 §12.3 logic; the trial is skipped.

After 100 trials × 60 s = **100 minutes**, the verdict gate `($startup_timeout_count -eq 0)` fails closed — `verdict=FAIL`, message "$startup_timeout_count trial(s) hit MT5 startup timeout (60s) without ever creating a write target". This is at least **fail-closed** — not a false PASS — but the harness still empirically tests **nothing** about NFR-3.1, and the operator who runs it pays a 100-minute price to discover the contract is broken.

The bundled R12 fix proved the path-binding correctness of one half of the chain (harness-side relative path matches the .ini override) without verifying the other half (Strategy Tester sandbox tree). Both halves must agree for the harness to observe the spike's writes.

**Why This Matters:**
This is the same defect class as R12 § Finding 12.1 — Dim #11 closure-rule trap — recurring at the next-coarser granularity. R12 caught the spike-writes-different-relative-path defect; R13 catches the spike-writes-different-sandbox-tree defect. The IMPL-064 deferred-AC row `[boot-cold]` + `[file-blob-check]` E-AC remains **empirically untestable** by the current harness. The Tier 1.5 walk batch-2 will hit this immediately when an operator runs the harness for real.

Worse: the doc claim in `nfr-3.1-atomic-write-result.md § 2.3` (R12 fix) assures the reader that the override redirects the spike to the production path the harness inspects — but the override only redirects within the Tester sandbox tree, which the harness does not inspect. The doc-↔-artifact divergence pattern flagged in R12 § XS-12.2 has migrated rather than resolved.

The R12 closure narrative on this finding cluster (12.1 + 12.3 + 12.4) called out parallel-batch closure as the root cause: "no single subagent had end-to-end ownership of 'harness writes to + harness inspects + .ini configures' the same path". The recommended consolidation step ("run the full chain headless even with -DryRun before commit") was not added; the fix-round-12 G1 verification ran DryRun, which short-circuits before launching `terminal64.exe`, so the sandbox-tree mismatch never surfaced empirically pre-commit.

**Suggested Fix:**
Two viable approaches; pick **one** consistently across .ini + .ps1 + spike:

**Approach A — Inspect the Tester agent sandbox (recommended, no spike changes)**
```powershell
# atomic_write_kill_100.ps1 — replace $StateDir resolution with Tester-tree path.
[CmdletBinding()]
param(
    [int]    $Trials       = 100,
    [string] $StateRel     = 'PhoenicisNex/state',
    [string] $AgentSubpath = 'Agent-127.0.0.1-3000',          # default agent under headless run
    ...
)
...
$TerminalId   = Split-Path $RepoRoot -Leaf                    # 32-char hex hash
$TesterRoot   = Join-Path (Split-Path $RepoRoot -Parent) 'Tester'   # ...AppData/Roaming/MetaQuotes/Tester
$AbsStateDir  = Join-Path (Join-Path (Join-Path $TesterRoot $TerminalId) $AgentSubpath) "MQL5/Files/$StateRel"
```
Plus a sanity-check pre-flight:
```powershell
if (-not (Test-Path (Split-Path $AbsStateDir -Parent))) {
    Write-Warning "[atomic-write-kill] Tester agent dir not found at '$AbsStateDir'. The Tester sandbox is created on first headless run — first trial may startup-timeout while MT5 lays down the tree. If timeouts persist, verify the agent subpath matches your install (some setups use Agent-127.0.0.1-3001+ for parallel agents)."
}
```
**Pros:** zero spike changes; spike keeps its IMPL-046 sandbox-path defaults; only the harness learns the Tester-tree convention.
**Cons:** harness now depends on the agent-subpath constant (`Agent-127.0.0.1-3000`) being stable; document this in the .ps1 header.

**Approach B — Use FILE_COMMON in the spike + redirect harness to `<TerminalDataDir>/MQL5/Files/Common/...`**
```mql5
// Spike_AtomicWrite.mq5 — switch the spike's file I/O to FILE_COMMON.
int h = FileOpen(tmppath, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
...
FileMove(tmppath, FILE_COMMON, path, FILE_REWRITE|FILE_COMMON);
```
Plus:
```ini
[TesterInputs]
InpStateFile=PhoenicisNex/state/state.json     ; resolved under MQL5/Files/Common/
InpTmpFile=PhoenicisNex/state/state.json.tmp
```
Plus:
```powershell
# atomic_write_kill_100.ps1 — point at the shared Common directory.
$AbsStateDir = Join-Path (Join-Path (Split-Path $RepoRoot -Parent) 'Common') 'Files/PhoenicisNex/state'
```
**Pros:** unified sandbox for live + tester runs; aligns with how a future "live-mode" production EA would also write state.
**Cons:** changes IMPL-046 spike's contract (the original Phase 1+2 sandbox in `<TerminalDataDir>/MQL5/Files/PhoenicisNex/spike/` is what the IMPL-046 §Spike Result locked); requires re-attest.

Either approach must add a **DryRun assertion** that exercises the resolved `$AbsStateDir` path one trial actually writes to, e.g. by parsing the spike's `Print` output (`[spike][ev=spike_complete]`) from the Tester log instead of (or in addition to) inspecting the file blob. That eliminates the recurrence: the harness validates its expected write path against an empirical signal from the spike, not a path-binding assertion against a static .ini.

After fixing 13.1, also re-verify Finding 13.4 — the early-bail proposal becomes more impactful when each timeout still costs 60 s.

**Level of Effort:** Medium

---

### Finding 13.2: 🟠 HIGH — fix-round-12 §12.8 / XS-12.3 advertised "all 11 slot files" updated to drop "deferred to IMPL-053+" framing — actual grep shows **18+ stale sites in 17 slot files** still carrying the old wording on exit-paths, pending-payload schema-lock comments, and Logger.Info format strings — partial regression of the announced fix

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh`, Line: 264 (exit `OrderSend close deferred to IMPL-053+`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_F.mqh`, Line: 200 (`OrderClose deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh`, Line: 180 (`OrderSend close deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh`, Line: 310 (`OrderSend close deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_C.mqh`, Lines: 208 (`schema lock deferred to IMPL-053+`), 340 (`OrderClose deferred to Orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_D.mqh`, Line: 209 (`OrderClose deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_T.mqh`, Lines: 186 (schema-lock), 316 (OrderClose)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh`, Line: 228 (`OrderSend close deferred to IMPL-053+`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh`, Line: 212 (`OrderClose deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh`, Line: 192 (`OrderSend close deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh`, Line: 305 (`OrderSend close deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh`, Line: 212 (`Full cloud-touch check deferred to IMPL-053+`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_I.mqh`, Line: 342 (`OrderSend close deferred to IMPL-053+ orchestrator wiring`)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh`, Lines: 298 (header banner — `broker call deferred to IMPL-053+ Orchestrator wiring per slot precedent`), 550, 576 (close paths)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_M.mqh`, Lines: 187 (schema-lock), 317 (OrderClose)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_R.mqh`, Lines: 195 (schema-lock), 325 (OrderClose)
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_Q.mqh`, Lines: 186 (schema-lock), 316 (OrderClose)
- Service: ea (slots/* — 17 slot files; 21 sites)

**Code:**
```mql5
// Slot_BI.mqh:263-265 (still stale)
                                       ticket, profit_pips, InpBITpProfitPips));
            //--- Phase-1 stub: OrderSend close deferred to IMPL-053+
           }

// Slot_C.mqh:340 (still stale)
         //--- Close via CTrade route (IMPL-053+ wiring)
         //    Phase-1 stub: log intent; OrderClose deferred to Orchestrator wiring.

// Slot_M.mqh:187 (still stale)
      //--- Build pending payload (minimal JSON — schema lock deferred to IMPL-053+)

// Slot_P.mqh:297-299 (still stale — header banner)
//| NOTE: All OrderSend submissions are Phase-1 stubs — actual        |
//|       broker call deferred to IMPL-053+ Orchestrator wiring per   |
//|       slot precedent (Slot_R IMPL-033 + sibling slots).           |
```

```bash
# Verification grep (Grep tool, project root):
#   pattern: "deferred to IMPL-053\+|deferred to Orchestrator wiring|deferred to orchestrator wiring"
#   path:    MQL5/Experts/PhoenicisNex/slots
# Output: 21 sites across 17 files (full enumeration above).
```

**Problem:**
fix-round-12 § 12.8 narrative says: "Grepped slots/ for 'OrderSend deferred to IMPL-053+' / 'OrderSend deferred to Orchestrator wiring (IMPL-053+)' / 'OrderSend deferred to orchestrator wiring' and updated all 11 files (Slot_S, Slot_BI, Slot_C, Slot_G, Slot_G2, Slot_I, Slot_LX, Slot_M, Slot_P [×2 occurrences], Slot_Q, Slot_R, Slot_T)". The grep evidently caught the ENTRY-side `OrderSend` stub comment (the "Build MqlTradeRequest stub" block) — that comment block was correctly updated (verified in `Slot_S.mqh:223-227`). But:

1. **Exit-side comment blocks** in the same files (where the slot logs Close-intent and notes broker wiring is deferred) were NOT updated. Slot_BI:264, Slot_F:200, Slot_GO:180, Slot_G2:310, Slot_LX:228, Slot_J:212, Slot_BR:192, Slot_S:305, Slot_I:342, Slot_C:340, Slot_D:209, Slot_T:316, Slot_M:317, Slot_R:325, Slot_Q:316 — 15 exit-side sites still say "OrderSend/OrderClose deferred to IMPL-053+ orchestrator wiring" or "deferred to Orchestrator wiring".
2. **Schema-lock comments** in pending-payload builder paths (Slot_C:208, Slot_T:186, Slot_M:187, Slot_R:195, Slot_Q:186) still say "schema lock deferred to IMPL-053+" — the schema *is* now defined per `state-persistence-schema.yaml`, so this comment is doubly stale (wrong task ref AND wrong contract claim).
3. **Slot_P file header banner** lines 297-299 still says "broker call deferred to IMPL-053+ Orchestrator wiring per slot precedent" — a 3-line block at file level.
4. **Slot_K:212** says "Full cloud-touch check deferred to IMPL-053+ when ctx is passed to ManageExits" — different semantic (deferred logic, not deferred OrderSend) but same stale task reference; would mislead a new reader the same way.

The R12 § 12.8 narrative explicitly worried this would propagate ("comment cleanup across all 21 slots") and proposed a fix scoped to "all 21 slots". The closure narrative said "11 slot files" got fixed; cross-service note XS-12.3 said the propagation surface is "all 20 other slot files" beyond Slot_S. Reality after the fix-round: the fix was scoped narrower than declared — only the entry-side stub comment was touched. Two additional comment-pattern variants (exit-side "OrderSend close deferred to IMPL-053+" and pending-payload "schema lock deferred to IMPL-053+") were not part of the grep set and survived the fix-round wholesale.

**Why This Matters:**
Same audit-clarity defect class as Finding 12.8. A new engineer reading Slot_F:200 ("OrderClose deferred to IMPL-053+ orchestrator wiring"), Slot_C:208 ("schema lock deferred to IMPL-053+"), or Slot_P:297-299 still sees the stale "IMPL-053+" reference even though IMPL-053..060 are all closed. The misleading pointer wastes onboarding cycles AND erodes trust in the just-applied fix-round narrative ("the comments were swept" — they were not).

More structurally: this is exactly the **declared-vs-actual cascade scope drift** Code Reviewer SKILL § Common Rationalizations row 7 is meant to catch — fix narrative claims comprehensive sweep, actual delta is partial, no post-fix grep was committed as evidence (the fix-round body has G1 + Python smoke + PowerShell smoke evidence rows, but no `grep -c "deferred to IMPL-053"` post-condition row). A 1-line `grep -rn` post-condition in fix-round-12 would have caught this before the commit landed.

This is also the second R12-era closure that under-delivered relative to its narrative (the first being § 12.1's path-binding scope underestimation ⇒ Finding 13.1 above). Same root cause: fix-round narratives describe broader sweeps than the engineer's grep set caught.

**Suggested Fix:**
Run the broader grep + sweep all sites in one batch:

```bash
# Single-shot sweep
cd MQL5/Experts/PhoenicisNex/slots

# 1. Replace "deferred to IMPL-053+ orchestrator wiring" with the canonical Phase-1 framing.
grep -rln "deferred to IMPL-053+\|deferred to Orchestrator wiring\|deferred to orchestrator wiring" .

# 2. For each match, replace with the consistent fix-round-12 §12.8 wording:
#    "logger-only milestone; broker call wires at IMPL-017 / IMPL-062 (RiskManager::OpenOrder)"
```

Then add a **post-fix verification row** to the fix-round template + `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`:

```
| 9 | **Post-fix grep verification** | `grep -rn "<old pattern>" <touched dir>` | exit code 1 (zero matches) — any non-zero hit means the sweep was scope-narrower than the fix-round narrative claims |
```

Also drop the file-header banner `Slot_P.mqh:295-299` ("NOTE: All OrderSend submissions are Phase-1 stubs ... deferred to IMPL-053+ Orchestrator wiring") in favor of a single-line pointer at the top of each file: `// Phase-1 stub: emits entry_signal Logger.Info; OrderSend wires at IMPL-017 / IMPL-062 per ea.md.`

LoE: Low (~30 LOC across 17 files, mechanical) + 1 workflow-rule row.

**Level of Effort:** Low

---

### Finding 13.3: 🟡 MEDIUM — `Spike_AtomicWrite::OnInit` line 104-105 unconditionally `FileDelete(InpStateFile)` and `FileDelete(InpTmpFile)` at start of run — under R12's `[TesterInputs]` redirect, this delete now points at `PhoenicisNex/state/state.json` (= production path) and silently destroys real operator state if the harness is ever re-pointed at the live-terminal sandbox

**Location:**
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5`, Lines: 103-105 (`// Cleanup any prior run artifacts` then `FileDelete(InpStateFile); FileDelete(InpTmpFile);`)
- File: `simulation/headless-tests/atomic_write_kill.ini`, Lines: 42-43 (`InpStateFile=PhoenicisNex/state/state.json`, `InpTmpFile=PhoenicisNex/state/state.json.tmp`)
- Service: ea (spike) + ea-qa (harness contract)

**Code:**
```mql5
// Spike_AtomicWrite.mq5:96-105
int OnInit()
{
   PrintFormat("[spike][ev=spike_start][total_writes=%d][kill_trials=%d]",
               InpTotalWrites, InpKillTrials);

   // Cleanup any prior run artifacts
   FileDelete(InpStateFile);     // <-- now resolves to PhoenicisNex/state/state.json (PRODUCTION PATH)
   FileDelete(InpTmpFile);
```

**Problem:**
The spike was authored for IMPL-046 sandbox usage where `InpStateFile` defaults to `PhoenicisNex/spike/state.json` — its own private sandbox subdirectory. Cleanup-at-start was safe because nothing else owned that path.

R12 § 12.1 fix added `[TesterInputs]` overrides redirecting `InpStateFile` to `PhoenicisNex/state/state.json` — the production state path owned by `services/StatePersistence.mqh::m_state_path`. The spike's start-of-run `FileDelete` now points at the production path.

Currently this is **isolated** by Finding 13.1 (Tester sandbox vs Terminal sandbox tree separation): in headless mode the `FileDelete` deletes `<TesterDir>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state/state.json`, which is ephemeral. The live terminal's `<TerminalDataDir>/MQL5/Files/PhoenicisNex/state/state.json` (the real production path) is untouched.

But that isolation is **incidental**, not designed. Two scenarios reactivate the destruction:

1. **Approach B fix to Finding 13.1 (FILE_COMMON):** if the spike's FileOpen flips to `|FILE_COMMON`, the `FileDelete(InpStateFile)` at line 104 also runs against the Common sandbox, deleting `<TerminalDataDir>/MQL5/Files/Common/PhoenicisNex/state/state.json` per harness trial. If a live-mode EA later writes its production state to that Common path, every harness trial wipes it before the spike's write loop starts.
2. **Operator who runs the spike directly** (without Strategy Tester) on a dev chart — the spike runs in the *terminal* sandbox, the FileDelete now wipes the live `state.json`. R12's `[TesterInputs]` only applies under Tester; default-input runs read the .mq5's hardcoded `"PhoenicisNex/spike/state.json"` which is safe — but if anyone hardcodes the production path for a quick test (operator session walks 2 different production-path test runs), data loss is silent.

This is the same defect class as the cascade in R10 (where path-binding was discovered to be bound to the WRONG side of the contract). It's *a destructive operation gated by an incidental safety property*; Code Reviewer Phase 0 mindset (`think like an operator — what happens at 3am`) makes this the kind of pattern to flag even under current isolation.

**Why This Matters:**
The R12 fix narrative § 12.1 explicitly wanted the harness contract to be "harness inspect path == spike write path == production state path". If that contract is genuinely achieved in a future fix to Finding 13.1, the spike's start-of-OnInit `FileDelete` becomes a per-trial production-state-wipe. At 100 trials, the operator's live `state.json` (which Phase 4 IMPL-062 5-yr regression Bucket A drift comparison depends on, and which the live-mode EA persists every tick) would be deleted 100 times in 100 minutes — silent data loss. The next live-mode OnInit would log `state_corrupt_starting_fresh` and reset all per-magic state.

This is also a **pre-condition** for safely closing Finding 13.1 — whichever approach (A or B) is chosen, this `FileDelete` must be removed or guarded before the production-path inspection actually happens. Better to flag now (when the contract is being designed) than after the path is fixed and the next harness run silently destroys live state.

**Suggested Fix:**
Replace the unconditional cleanup with a guarded version that asserts the path is a sandbox-owned spike path:

```mql5
// Spike_AtomicWrite.mq5 — guard cleanup against accidental production-path destruction.
int OnInit()
{
   PrintFormat("[spike][ev=spike_start][total_writes=%d][kill_trials=%d]",
               InpTotalWrites, InpKillTrials);

   //--- Cleanup is gated to known-sandbox prefixes — protects against
   //    a misconfigured InpStateFile pointing at a production path that
   //    other system components (StatePersistence.mqh) own.
   //    Operator who legitimately wants to redirect at the production
   //    path must explicitly accept the destructive semantics by setting
   //    InpAllowProductionPath=true.
   if (StringFind(InpStateFile, "PhoenicisNex/spike/") == 0)
     {
      FileDelete(InpStateFile);
      FileDelete(InpTmpFile);
     }
   else
     {
      PrintFormat("[spike][ev=cleanup_skipped][reason=non-spike-path][path=%s]",
                  InpStateFile);
     }
```

Or — preferred — drop the cleanup entirely and have the harness clean its own inspect path before each trial (the harness already does `Remove-Item $StateTmp` on line 205 + 252-254; extend it to also `Remove-Item $StateJson` if the trial is meant to start from a clean slate). That puts the destructive operation under the harness-side process owner, which is the correct boundary.

Add a SelfTest assertion to the spike: log `[spike][ev=path_guard]` at OnInit start showing the resolved path classification (`sandbox` / `production` / `unknown`) so an operator can audit the safety property in real time.

LoE: Low (~10 LOC + 1 doc note).

**Level of Effort:** Low

---

### Finding 13.4: 🟡 MEDIUM — `atomic_write_kill_100.ps1` lacks early-bail when consecutive trials hit `startup_timeout_count` — under Finding 13.1's path mismatch, the harness burns 100 minutes (100 × 60 s) before reporting FAIL; obvious config error silently consumes operator session

**Location:**
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 169-260 (per-trial loop has no consecutive-fail short-circuit)
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 190-210 (60 s poll deadline runs full duration on every miss)
- Service: ea-qa (NFR-3.1 verification harness)

**Code:**
```powershell
# atomic_write_kill_100.ps1:169-210 (per-trial, no early-bail)
for ($i = 1; $i -le $Trials; $i++) {
    ...
    $pollDeadline = (Get-Date).AddSeconds(60)
    $writeStarted = $false
    while ((Get-Date) -lt $pollDeadline) {
        if ((Test-Path $StateJson) -or (Test-Path $StateTmp)) {
            $writeStarted = $true
            break
        }
        Start-Sleep -Milliseconds 100
    }
    if (-not $writeStarted) {
        Write-Warning "[atomic-write-kill] Trial $i/${Trials}: spike never wrote within 60s — startup timeout. Killing terminal and skipping."
        ...
        $startup_timeout_count++
        continue                   # <-- proceeds to next trial regardless of how many consecutive timeouts
    }
    ...
}
```

**Problem:**
With Finding 13.1's path mismatch, EVERY trial will timeout (writes go to a sandbox the harness doesn't inspect). The current loop runs all 100 trials × 60 s = **100 minutes of wall clock** before the verdict gate finally reports FAIL with "100 trial(s) hit MT5 startup timeout". An operator who was expecting a 10-15 minute run (the original budget when 50-500ms sleep was the only delay) will sit through 6.7× the expected duration before seeing the actual failure mode. Worse, the operator likely watches the first 1-2 trials, walks away, comes back 30 minutes later, and has to wait another 70 minutes for the verdict to print.

The harness already tracks `startup_timeout_count`. A 1-page-of-PowerShell early-bail check (e.g., "if first 3 consecutive trials timeout, abort with verdict=FAIL_FAST and recommend the operator audit the path binding") would convert a 100-min config-error discovery into a 3-min discovery — same fail-closed semantics, 33× faster operator feedback.

This is independent of Finding 13.1 (the early-bail belongs in the harness regardless of whether 13.1 is fixed or not — even genuine startup failures (terminal64 license expired, broker history download in progress, etc.) deserve fast feedback). But the impact is dominant under 13.1.

**Why This Matters:**
Operator-experience defect that compounds with the Tier 1.5 walk batch-2 schedule. The walk session is meant to drain the IMPL-064 deferred-AC row in one operator session; if the harness needs 100 minutes to discover the config is wrong, then 100 minutes more for the fix + recompile + retest, the walk window expands from "single 30-min session" to "split 2-3 day cycle". The CLAUDE.md § 1 Tier 1.5 "30-min non-scripted operator walk" budget assumes individual probes are fast enough to support exploratory iteration; a 100-min FAIL probe is structurally incompatible with that.

Also a defensive-coding signal: the harness's verdict gate logic is now correct (fail-closed on any startup_timeout), but the surrounding telemetry is misaligned with operator workflow. Test infrastructure should fail FAST and LOUD on obvious misconfiguration — that's `.claude/rules/testing.md § Test Execution Safety` "Hang protection" applied to operator-session walks.

**Suggested Fix:**
Add a consecutive-timeout circuit-breaker:

```powershell
# atomic_write_kill_100.ps1 — fail-fast on early consecutive timeouts.

$consecutive_timeouts        = 0
$max_consecutive_timeouts    = 3            # configurable param; rationale below

for ($i = 1; $i -le $Trials; $i++) {
    ...
    if (-not $writeStarted) {
        Write-Warning "[atomic-write-kill] Trial $i/${Trials}: startup timeout."
        ...
        $startup_timeout_count++
        $consecutive_timeouts++

        if ($consecutive_timeouts -ge $max_consecutive_timeouts) {
            Write-Warning "[atomic-write-kill] FAIL_FAST: $consecutive_timeouts consecutive startup timeouts; aborting at trial $i/$Trials. Likely path-binding misconfiguration. Audit:"
            Write-Warning "  - State dir inspected by harness: $AbsStateDir"
            Write-Warning "  - .ini override path: PhoenicisNex/state/state.json (resolves under spike's runtime sandbox)"
            Write-Warning "  - If running headless via Tester, see mt5-headless-backtest § log-paths.md sandbox tree separation."
            $verdict = 'FAIL_FAST'
            break        # exit loop early; verdict + sidecar still emitted below
        }
        continue
    }

    # Reset consecutive counter on a successful poll.
    $consecutive_timeouts = 0
    ...
}
```

Param `-FailFastConsecutive` defaults to 3. Rationale: cold-bootstrap variance + occasional history download latency could cause 1-2 timeouts in a healthy run; 3 in a row signals systemic path-binding error rather than transient resource contention. Document this trade-off in the .ps1 header SYNOPSIS.

LoE: Low (~15 LOC harness + 1 sidecar field `failed_fast=$true|false` + 4 LOC doc).

**Level of Effort:** Low

---

### Finding 13.5: 🔵 LOW — `CCircuitBreaker::SelfTest` cases A-D do not exercise the new pre-Init NULL-logger guard added in fix-round-12 § 12.6 — Recommendation 12.6 explicitly proposed a SelfTest case ("pre-Init RecordOpen call → assert ring buffer NOT mutated + Print fallback emitted"); not added → silent regression risk for Phase 2 RiskManager wiring

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`, Lines: 281-382 (SelfTest body covers Cases A-D for CheckPingPong, none for pre-Init RecordOpen/Close)
- Reference: `docs/code-review/review-round-12.md` § Finding 12.6 Suggested Fix ("Add a SelfTest case: pre-Init RecordOpen call → assert ring buffer NOT mutated + Print fallback emitted")
- Service: ea (CircuitBreaker)

**Code:**
```mql5
// CircuitBreaker.mqh:281+ — SelfTest covers 4 CheckPingPong cases:
bool CCircuitBreaker::SelfTest()
{
   ...
   // Case A: 3 close events 1 s apart → expect halt
   // Case B: 2 events 4 s apart → near-miss warn, no halt
   // Case C: 2 events 6 s apart → no trigger
   // Case D: different magic → no trigger
   ...
   // (No Case E exercising RecordOpen/Close pre-Init NULL-logger guard.)
}
```

**Problem:**
fix-round-12 § 12.6 added the dual-gate (Option B) NULL-logger early-return at `RecordOpen` and `RecordClose`, motivated by Phase 2 IMPL-017 / IMPL-062 RiskManager wiring (per the inline comment at lines 137-147). The fix is correct. But:

1. The SelfTest does NOT exercise the new code path. A future regression (e.g., engineer removes the NULL check during a refactor, or accidentally swaps the early-return order) is silently accepted by the existing SelfTest because Cases A-D all run after `Init(logger)` is called inside `Spike_CircuitBreaker.mq5` or wherever SelfTest is wired.
2. Recommendation 12.6 explicitly proposed the SelfTest case as part of the Suggested Fix block. Fix-round-12 narrative says "Approach. Added Option B early-return guards..." but does not mention the SelfTest extension; it was scoped out of the fix.
3. Same defect class as Finding 12.8 (announced sweep wider than executed sweep): R12 finding includes a 2-part fix (production code + test); fix-round delivered 1 part.

This is LOW because: (a) the production-code change is correct AND verified by inspection; (b) the test gap is for a defensive layer, not a primary contract; (c) phase 2 callers are not yet wired so the pre-Init dispatch surface is not yet active.

**Why This Matters:**
When IMPL-017 / IMPL-062 lands (within 1-2 weeks per current plan), the Phase 2 caller surface activates. A pre-Init `RecordOpen` dispatch (e.g., broker-recovery `OnTradeTransaction` firing before `OnInit` completes per MT5 docs) hits the new guard. Without a SelfTest exercising that path, a reviewer in 2-3 sprints' time who refactors CircuitBreaker has no immediate signal that they broke the dual-gate — the existing SelfTest remains green.

This is the cheapest possible defense-in-depth gap to close (5 LOC) and the highest-leverage prevention against a Phase 2 regression that would re-introduce the exact bug R12 § 12.6 was raised to fix.

**Suggested Fix:**
Add Case E to `SelfTest`:

```mql5
   //--------------------------------------------------------------------
   // Case E: pre-Init RecordOpen + RecordClose drop events with no buffer
   //         mutation + Print fallback emit. (R12 § 12.6 dual-gate test.)
   //--------------------------------------------------------------------
   CB_SELFTEST_RESET();
   CLogger* saved_logger = m_logger;
   m_logger = NULL;                                  // simulate pre-Init

   RecordOpen(200, 0, t0);                            // expect: dropped, m_count=0
   RecordClose(200, 0, t0);                           // expect: dropped, m_count=0

   m_logger = saved_logger;                           // restore for subsequent cases

   if(m_count != 0)
     {
      Print("[CircuitBreaker][SelfTest][FAIL] Case E: pre-Init Record*"
            " mutated buffer (m_count=", m_count, "), expected 0");
      all_pass = false;
     }
   else
      Print("[CircuitBreaker][SelfTest][PASS] Case E: pre-Init Record* dropped as expected");
```

LoE: Low (~10 LOC + 1 line case-doc in the SelfTest banner).

**Level of Effort:** Low

---

### Finding 13.6: 🔵 LOW — `IsPhoenicisMagic` lacks SelfTest exercising registered/unregistered/boundary magics; Recommendation 12.2 proposed one ("Add a SelfTest case in `Spike_CircuitBreaker` ... `OnTradeTransaction` simulated event with magic=202 → assert ring buffer NOT mutated") not added → future MAGIC_* addition/removal cannot be statically verified to update the helper

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh`, Lines: 77-103 (`IsPhoenicisMagic` body — no co-located SelfTest)
- Reference: `docs/code-review/review-round-12.md` § Finding 12.2 Suggested Fix ("Add a SelfTest case ... magic=202 → assert ring buffer NOT mutated. LoE: Low (~17 LOC switch + 1 SelfTest case)")
- Service: ea (domain helper)

**Code:**
```mql5
// EnumTypes.mqh:77-103 — helper now correct, but unverified by automation
bool IsPhoenicisMagic(int magic)
  {
   //--- if/else over MAGIC_* ladder rather than `switch` because MQL5
   //    switch labels require literal constant expressions...
   //    PHOENICISNEX_MAGIC_COUNT (=17) and the MAGIC_* set above are the
   //    single source of truth — keep this list in sync with any future
   //    addition or removal.
   return magic == MAGIC_CD     // 200 (C, D shared)
       || magic == MAGIC_F      // 201
       ...
       || magic == MAGIC_T;     // 219
  }
// No co-located SelfTest; no test in Spike_CircuitBreaker that asserts
// IsPhoenicisMagic(202) == false / IsPhoenicisMagic(MAGIC_S) == true.
```

**Problem:**
fix-round-12 § 12.2 explicitly accepts that the `||` chain is **the single source of truth** for the registered-magic set, alongside `PHOENICISNEX_MAGIC_COUNT=17`. The contract is correct AS WRITTEN. But:

1. Adding a new slot magic (e.g., a re-enabled Slot U with magic 220 in a future ADR-013) requires the engineer to remember to (a) add the constant, (b) bump `PHOENICISNEX_MAGIC_COUNT`, (c) extend the `||` chain. There's no automated check that all three are in sync; each is a SoT. (a) is required by compile (referenced by slot files); (b) is mostly used by struct sizing and is verified in other SelfTests; (c) — the new helper — has no SelfTest pinning it to MAGIC_*.
2. Removing a slot (e.g., the 2026-05-01 OQ-8 deletion of Slot U) requires the inverse 3-step delete; (c) again is unverified.
3. fix-round-12 narrative ends "(also bump PHOENICISNEX_MAGIC_COUNT)" — the engineer is expected to remember this, but engineering rules § Glossary "State Single Source of Truth" prefers automation over discipline. A 5-LOC SelfTest closes the loop.

LOW because: the helper is correct today AND the comment block adequately documents the maintenance dance. But this is the same propagation defect class as 13.2 / 13.5 (R12 recommendation under-delivered), so worth tracking for fix-round-13 batch.

**Why This Matters:**
Slot V/U/etc. could be re-enabled at any time per BR-1.1 + ADR-005 evolution sequence (E2+ trigger conditions per `07-future-evolution.md`). The `||` chain has no compile-time linkage to `MAGIC_*` constants — adding `static const int MAGIC_V = 220;` and forgetting to extend the chain produces a silent drop of MAGIC_V close events (foreign-EA-equivalent treatment), which is a regression in the trade-transaction surface. SelfTest would catch this on first attach.

**Suggested Fix:**
Add a SelfTest helper either co-located in `EnumTypes.mqh` (a free function `bool IsPhoenicisMagicSelfTest()`) or in `Spike_CircuitBreaker` / a new dedicated `Spike_DomainTypes`:

```mql5
// EnumTypes.mqh — free function below IsPhoenicisMagic
bool IsPhoenicisMagicSelfTest()
  {
   bool ok = true;
   //--- All 17 registered magics must return true.
   if(!IsPhoenicisMagic(MAGIC_CD)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(CD=200)=false"); ok=false; }
   if(!IsPhoenicisMagic(MAGIC_F))  { Print("[SelfTest][FAIL] IsPhoenicisMagic(F=201)=false"); ok=false; }
   if(!IsPhoenicisMagic(MAGIC_H))  { Print("[SelfTest][FAIL] IsPhoenicisMagic(H=205)=false"); ok=false; }
   // ...repeat for all 17 magics...
   if(!IsPhoenicisMagic(MAGIC_T))  { Print("[SelfTest][FAIL] IsPhoenicisMagic(T=219)=false"); ok=false; }

   //--- Unregistered gap magics must return false (BR-3.6 foreign-EA filter).
   if(IsPhoenicisMagic(202)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(202)=true"); ok=false; }
   if(IsPhoenicisMagic(203)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(203)=true"); ok=false; }
   if(IsPhoenicisMagic(204)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(204)=true"); ok=false; }

   //--- Boundary checks.
   if(IsPhoenicisMagic(199)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(199)=true"); ok=false; }
   if(IsPhoenicisMagic(220)) { Print("[SelfTest][FAIL] IsPhoenicisMagic(220)=true"); ok=false; } // Slot U deleted
   if(IsPhoenicisMagic(0))   { Print("[SelfTest][FAIL] IsPhoenicisMagic(0)=true"); ok=false; }

   return ok;
  }
```

Wire into `BootstrapValidator::ValidateAll()` or `core/Orchestrator::OnInit` SelfTest pass alongside JsonWriter / IndicatorService SelfTests. LoE: Low (~25 LOC + 1 wire).

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-13.1 — Doc-↔-artifact divergence cascade: `nfr-3.1-atomic-write-result.md § 2.3` after R12 fix asserts the harness exercises live taskkill against the production state path; Finding 13.1 shows the spike still writes into the Tester sandbox tree, not the production tree the harness inspects
The R12 § XS-12.2 cross-service finding (doc claim vs harness behaviour) was scoped to "(a) `.ini` is reused as-is" + "(b) `parse_pass` 50-100 expected" + "(c) startup poll is not blocked". R12 fix-round addressed all 3 surface-level claims. But Finding 13.1 shows the deeper sandbox-tree mismatch — the doc still implies the harness validates production-path NFR-3.1 contract; reality is sandbox-tree mismatch makes that empirically impossible. Single fix to Finding 13.1 closes XS-13.1; doc must be re-amended at the same time.

### XS-13.2 — Fix-round narrative scope vs actual sweep coverage: § 12.8 (claim "all 11 slot files") + § 12.6 (no SelfTest case despite recommendation) + § 12.2 (no SelfTest case despite recommendation) — three sites where R12-era closure narratives advertised wider sweeps than the engineer's grep set or scope captured
This is the same root-cause as R12 § Recommendation cross-cutting note ("future parallel batches that touch a multi-file contract should include a final consolidation step"). The remediation proposed in R12 (artifact-contract roundtrip gate analogous to Phase 5 mechanical gate #6) was not added to `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`. Recommend adding gate #9 ("post-fix grep verification: re-run the originating fix's pattern grep with `--count`; non-zero hits ⇒ fix scope under-delivered") as the cross-cutting closure for both 12.8 (slot comments) and any future fix-round that claims "swept all N files".

### XS-13.3 — `parse_baseline.py` schema additions (`parse_anomaly_count` field) extend the JSON shape without an `api-specs/*.yaml` schema definition; downstream IMPL-062 regression logic now consumes a field that has no written contract
fix-round-12 § 12.5 added `parse_anomaly_count` to `baseline-per-slot.json` top-level; the JSON's intended consumer is IMPL-062 5-yr regression. The schema is not yet defined in `docs/api-specs/*.yaml`. R12 § Finding 12.6 narrative noted the same gap pattern ("`parse_baseline.py` schema is NOT yet defined in `docs/api-specs/*.yaml`") and tagged it LOW under TD JSON-schema gap. R13 reiterates: closing IMPL-062 task should include a `docs/api-specs/baseline-per-slot-schema.yaml` companion file (≤80 LOC) so the contract is enforceable rather than convention-only.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 13.1 | 🔴 CRITICAL | Test Coverage / E-AC Closure | Harness inspects `<Terminal>/MQL5/Files/...` while spike writes to `<Tester>/.../MQL5/Files/...` — sandbox-tree mismatch persists after R12 fix; verdict fail-closes (no false PASS) but burns 100 min before reporting FAIL; NFR-3.1 still empirically untested | `atomic_write_kill_100.ps1:77-79,160-161` + `Spike_AtomicWrite.mq5:32` + `atomic_write_kill.ini:39-50` | Medium |
| 13.2 | 🟠 HIGH | Cross-Service Consistency / Doc | fix-round-12 § 12.8 advertised "all 11 slot files" updated; actual grep shows 21 sites across 17 slot files still carry "deferred to IMPL-053+" / "schema lock deferred to IMPL-053+" / "OrderClose deferred to Orchestrator wiring" framing — exit-side + pending-payload comment patterns were outside the fix-round grep set | `slots/Slot_BI:264, Slot_F:200, Slot_GO:180, Slot_G2:310, Slot_C:208,340, Slot_D:209, Slot_T:186,316, Slot_LX:228, Slot_J:212, Slot_BR:192, Slot_S:305, Slot_K:212, Slot_I:342, Slot_P:298,550,576, Slot_M:187,317, Slot_R:195,325, Slot_Q:186,316` | Low |
| 13.3 | 🟡 MEDIUM | Architecture Compliance / Defense in Depth | `Spike_AtomicWrite::OnInit:104-105` unconditionally `FileDelete(InpStateFile)` at start; under R12's `[TesterInputs]` redirect, the path now resolves to the production state path; currently isolated by Tester sandbox separation (Finding 13.1) but becomes destructive if 13.1 is fixed via FILE_COMMON or if operator runs spike directly | `Spike_AtomicWrite.mq5:103-105` + `atomic_write_kill.ini:42-43` | Low |
| 13.4 | 🟡 MEDIUM | Performance / Operator UX | `atomic_write_kill_100.ps1` lacks consecutive-timeout fail-fast; under Finding 13.1's path mismatch, 100 trials × 60 s = 100 min of wall clock before verdict prints — incompatible with Tier 1.5 walk 30-min budget | `atomic_write_kill_100.ps1:169-260` | Low |
| 13.5 | 🔵 LOW | Test Coverage Gap | `CCircuitBreaker::SelfTest` cases A-D do not exercise the new pre-Init NULL-logger guard added in fix-round-12 § 12.6; Recommendation 12.6 explicitly proposed a SelfTest case not added | `CircuitBreaker.mqh:281-382` | Low |
| 13.6 | 🔵 LOW | Test Coverage Gap | `IsPhoenicisMagic` lacks SelfTest exercising registered/unregistered/boundary magics; Recommendation 12.2 proposed one not added; future MAGIC_* addition/removal has no automation pinning the `||` chain to constants | `EnumTypes.mqh:77-103` | Low |

---

## Recommendation

**Needs immediate attention before Tier 1.5 walk batch-2 runs.** Finding 13.1 + 13.4 form a usability trap: the operator who runs `atomic_write_kill_100.ps1` per fix-round-12's recommended walk session will sit through ~100 minutes of failed trials before learning that the path binding is still wrong (this time at the sandbox-tree level, not the relative-path level). The R12 fix surface verdict mechanism is correctly fail-closed (`startup_timeout_count > 0` ⇒ FAIL), so this is **not** a false-PASS regression — but it is also not an operationally-completable contract.

**Fix priority:**
1. **13.1 (CRITICAL)** — Approach A (harness inspects Tester agent sandbox) OR Approach B (spike + harness both use FILE_COMMON); pick one consistently across `.ini` + `.ps1` + `Spike_AtomicWrite.mq5`. Add DryRun assertion that exercises the resolved path against an empirical Tester-log signal, not a static path-binding check (~30 LOC). Re-amend `nfr-3.1-atomic-write-result.md § 2.3` to document the chosen sandbox.
2. **13.4 (MEDIUM)** — `atomic_write_kill_100.ps1` consecutive-timeout circuit-breaker (~15 LOC). Independent of 13.1 fix; both should land in the same fix-round-13 batch so the harness fail-fast path is exercised by the same Tier 1.5 walk that confirms 13.1's resolution.
3. **13.2 (HIGH)** — broader grep + sweep across 17 slot files (~30 LOC mechanical) + add `.claude/rules/workflow.md § Phase 5 Closure mechanical gate #9` (post-fix grep verification) so this defect class has a recurring guard.
4. **13.3 (MEDIUM)** — `Spike_AtomicWrite::OnInit` cleanup guard against non-spike paths (~10 LOC + 1 SelfTest assertion). Best landed alongside 13.1 since the destructive surface only opens when 13.1 is fixed via Approach B.
5. **13.5 (LOW)** — CircuitBreaker SelfTest Case E (pre-Init NULL-logger guard) (~10 LOC).
6. **13.6 (LOW)** — `IsPhoenicisMagicSelfTest` free function + wire into Orchestrator SelfTest pass (~25 LOC).

**Plan Staleness Sentinel:** 7 closures since R07 — within 10-closure threshold ✅; this review counts as 0 closures (review-round files don't increment Sentinel). Mid-Phase Audit P4 counter at 6 ≥ 5 trigger remains advisory; `/impl-plan-review all` can wait until after IMPL-062 closes (so the review captures the full P4 tail in one pass).

**Cross-cutting observation:** Findings 13.1 + 13.2 + 13.5 + 13.6 share a root cause — fix-round-12 narrative described wider sweeps than the engineer's grep set or scope actually executed. R12 § Recommendation cross-cutting note proposed an "artifact-contract roundtrip" gate analogous to Phase 5 mechanical gate #6 (file integrity); that gate was not added to `.claude/rules/workflow.md`. Recommend adding it as gate #9 in fix-round-13 alongside the substantive code fixes:

| 9 | **Post-fix grep verification** | Re-run the originating R-finding's pattern grep with `--count` after the fix-round commits land | exit code 1 (zero matches) — any non-zero hit means the announced sweep was scope-narrower than the fix-round narrative; raise as fix-round regression in the next R-cycle |

This same gate would have caught Finding 13.2 at the fix-round-12 commit boundary (a `grep -c "deferred to IMPL-053"` post-condition of the fix would have shown 21 remaining hits and forced the engineer to expand the grep set).

**On the structural quality of fix-round-12 closures:**
- IsPhoenicisMagic set-membership rewrite is correct AS WRITTEN ✅; only the SelfTest extension (13.6) was scoped out.
- CircuitBreaker dual-gate (Option B) is correct AS WRITTEN ✅; only the SelfTest case (13.5) was scoped out.
- parse_baseline.py parse-anomaly counter + stderr WARN + summary is well-shaped ✅; the schema-yaml gap (XS-13.3) is a downstream contract issue tracked under IMPL-062.
- atomic_write_kill_100.ps1 poll-then-attack + startup_timeout_count + verdict gate is correctly fail-closed ✅; only the path-binding (13.1) and operator-UX (13.4) were missed.
- 11-slot comment update correctly closes the entry-side stub-comment defect ✅; the exit-side + schema-lock + Slot_P header banner sites (13.2) were outside the grep set.

R12 fix surface is structurally sound; R13 surface is dominantly **scope** — every R13 finding except 13.3 is a fix-round-12 sweep that under-delivered relative to its narrative. R12's heaviest defect cluster (Findings 12.1 + 12.3 + 12.4 — IMPL-064 harness contract) recurs in the next-coarser form (Finding 13.1 — sandbox-tree level). The prevention pattern is the cross-cutting Phase 5 mechanical gate #9 above.
