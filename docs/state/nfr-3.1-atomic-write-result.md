# NFR-3.1 Atomic-Write Kill-100 Stress Test Result

| Field | Value |
|---|---|
| NFR reference | NFR-3.1 — AtomicFile.mqh write must survive mid-write kill 100/100 trials |
| ADR reference | `docs/adr/007-state-persistence-atomic-temp-rename.md` (Option A primary) |
| Task ID | IMPL-064 |
| Phase | P4 — Verification |
| Opened | 2026-05-04 |
| Status | **PENDING NUMERIC RUN** (script committed; execution deferred to Tier 1.5 walk batch-2) |
| Expiry (deferred-ac-registry) | 2026-05-18 |

---

## 1. Background

NFR-3.1 requires that `state.json` atomic writes never produce a half-written (non-parseable) file, even when the process is killed mid-write. ADR-007 achieves this via **Option A: write-temp + NTFS rename**:

1. Write complete JSON to `state.json.tmp`
2. `FileMove("state.json.tmp", "state.json")` — NTFS atomic by Win32 contract
3. On OnInit startup: if `state.json.tmp` orphan found → log warning + delete → load valid `state.json`

IMPL-046 (2026-05-02) spike validated Phase 1 (1000/1000 sequential writes) and Phase 2 (100/100 software-simulated mid-write crashes via `.tmp` truncation). Verdict: `OPTION_A_LOCKED`.

IMPL-064 is the **complementary live `taskkill` validation** — real PowerShell `Stop-Process -Force` during live `terminal64.exe` write loop — explicitly deferred by the spike's §Spike Result note: "Final 100/100 validation (real PowerShell `taskkill`) deferred to IMPL-064."

---

## 2. Protocol

### 2.1 Crash Windows (per ADR-007 §Atomicity Proof)

| Kill timing | Observable state | Integrity verdict |
|---|---|---|
| Before write starts (pre-tmp create) | `state.json` untouched, no `.tmp` | Acceptable — prior valid `state.json` intact |
| During write to `.tmp` | `.tmp` partial/missing, `state.json` intact | Acceptable — rename not reached |
| At `FileMove` rename (NTFS atomic) | Either old or new `state.json` — both valid JSON | Acceptable — NTFS atomicity guarantee |
| After rename completes | New `state.json` present, no `.tmp` | Pass — clean state |

### 2.2 Harness Algorithm

Script: `simulation/scripts/atomic_write_kill_100.ps1`

Parameters:
- `-Trials [int]=100` — number of kill cycles
- `-StateDir [string]='MQL5/Files/PhoenicisNex/state'` — path to state directory
- `-IniPath [string]='simulation/headless-tests/atomic_write_kill.ini'` — .ini for Strategy Tester
- `-OriginFile [string]='origin.txt'` — MT5 install root source
- `-DryRun [switch]` — parse + validate only, no process spawn

Per-trial sequence:
1. `Start-Process terminal64.exe /config:<ini> -PassThru` (background)
2. `Start-Sleep -Milliseconds (Get-Random -Min 50 -Max 501)` — random offset into write window
3. `Stop-Process -Force -Id $proc.Id` — simulate OS kill
4. `Wait-Process` (max 10s timeout)
5. Inspect `$StateDir`:
   - `state.json` exists → `ConvertFrom-Json` — pass = `parse_pass++`; throw = `parse_fail++`
   - `state.json` missing + `state.json.tmp` present → `state_missing_tmp_present++` (acceptable)
   - Both missing → `state_missing_tmp_missing++` (acceptable — pre-write kill)
6. `Remove-Item state.json.tmp -Force` — clean orphan (mirrors ADR-007 OnInit recovery)

Aggregate verdict: `PASS` iff `parse_fail == 0` AND `Total == Trials`.

### 2.3 .ini Reuse — UPDATED 2026-05-04 (fix-round-12 §12.1 + §12.3 + §12.4)

`simulation/headless-tests/atomic_write_kill.ini` was committed during IMPL-046 spike (TD-02 §13.6 PR contract) and is reused for IMPL-064 with a `[TesterInputs]` override block added in fix-round-12 to repair the harness/spike contract:

| Override | Purpose | Fix-round-12 finding |
|---|---|---|
| `InpStateFile=PhoenicisNex/state/state.json` | Redirects spike from sandbox path (`spike/state.json`) to the production path so the harness inspect path matches the spike write path | §12.1 CRITICAL |
| `InpTmpFile=PhoenicisNex/state/state.json.tmp` | Same — `.tmp` orphan visibility for `state_missing_tmp_present` accounting | §12.1 |
| `InpTotalWrites=100000` | Large enough that the random 50-500ms harness attack window always lands inside an active write iteration | §12.3 HIGH |
| `InpKillTrials=0` | Disables the spike's internal Phase 2 (software-simulated crashes); the external PowerShell `Stop-Process` alone owns kill semantics | §12.4 MEDIUM |

The .ini targets `PhoenicisNex\spike\Spike_AtomicWrite` EA which continuously exercises the `AtomicFile.mqh` write path in a short 1-day date window (2021-01-04 to 2021-01-05, `Model=2`, `ShutdownTerminal=1`, `Visual=0`).

> **IMPL-046 sandbox usage** still runs `Spike_AtomicWrite.mq5` directly without this `.ini`, so the spike's input defaults (`PhoenicisNex/spike/state.json`, 1000 writes, 100 kills) remain authoritative for the original spike contract — only the IMPL-064 harness path inherits the overrides.

---

## 3. Prior Evidence (IMPL-046 Spike)

Cross-link: `docs/adr/007-state-persistence-atomic-temp-rename.md § Spike Result`

IMPL-046 result:
- Phase 1: 1000/1000 sequential atomic writes — all `state.json` parse clean
- Phase 2: 100/100 software-simulated mid-write crashes (`.tmp` truncation) — all produced either valid `state.json` OR missing-with-orphan-tmp pattern; zero parse failures
- Verdict committed: `OPTION_A_LOCKED`

IMPL-064 extends this with real OS-level process kill (`Stop-Process -Force`) to validate the full crash-window matrix under NTFS semantics.

---

## 4. Expected Counters

Based on ADR-007 §Spike Result + NTFS win32 rename atomicity:

| Counter | Expected | Rationale |
|---|---|---|
| `parse_pass` | 50-100 | Kill arrives after rename completes → valid `state.json` present |
| `parse_fail` | **0** (NFR-3.1 hard requirement) | Partial JSON = ADR-007 violated |
| `state_missing_tmp_present` | 0-50 | Kill arrives during `.tmp` write phase → rename not reached |
| `state_missing_tmp_missing` | ~0 | Kill before any write starts (rare at 50-500ms sleep) |

NFR-3.1 pass criterion: `parse_fail == 0` over 100 trials.

---

## 5. Result Table (PLACEHOLDER — fill post-execution)

Run date: **TBD** (Tier 1.5 walk batch-2)
Operator: **TBD**
Trials: 100

| Trial Outcome | Count | Pass criterion |
|---|---|---|
| `parse_pass` | TBD | sum of all outcomes == 100 |
| `parse_fail` | TBD | **== 0** (NFR-3.1 hard requirement) |
| `state_missing_tmp_present` | TBD | any value acceptable (ADR-007 §OnInit recovery) |
| `state_missing_tmp_missing` | TBD | any value acceptable |
| **Total** | TBD | **== 100** |
| **Verdict** | TBD | PASS / FAIL |

Machine-readable sidecar: `docs/state/nfr-3.1-atomic-write-result.json` (written by harness)

---

## 6. Pass/Fail Criterion

**NFR-3.1 PASS:** `parse_fail == 0` AND `Total == 100`

If `parse_fail > 0`:
- Capture the failing `state.json` content (≤30 lines) in this document
- Escalate via `/backtrack sd` to review ADR-007 Option A implementation in `helpers/AtomicFile.mqh`
- Do NOT mark IMPL-064 E-AC `[x]` until `parse_fail == 0` achieved

---

## 7. Operator Runbook

**Pre-conditions (must be satisfied before running):**
1. Close all foreground MetaTrader 5 instances (`terminal64.exe`) — data-dir lock prevents headless launch
2. Verify `state.json` exists from a prior run (so parse_pass outcomes are possible): check `MQL5/Files/PhoenicisNex/state/state.json`
3. Confirm PowerShell 7+ available (`pwsh --version`) or use Windows PowerShell 5.1 (`powershell.exe`)

**Execution:**
```powershell
# From repo root
pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 100
```

Or with verbose per-trial output:
```powershell
pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 100 -Verbose
```

**Dry-run validation (no process spawn):**
```powershell
pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -DryRun -Trials 5
```

**Post-run:**
1. Check console output for `verdict=PASS` or `verdict=FAIL`
2. Read machine-readable sidecar: `docs/state/nfr-3.1-atomic-write-result.json`
3. Fill §5 Result Table above with actual counts
4. If PASS: update `deferred-ac-registry.md` E-AC#1 IMPL-064 row → Done
5. If FAIL: capture failing `state.json` content + open defect ticket

---

## 8. Deferred-AC Registry Entry (orchestrator to fill)

E-AC#1 for IMPL-064: "100/100 trials = state.json parses cleanly OR doesn't exist (no half-write) `[boot-cold]` + `[file-blob-check]`"

- Status: **Active (deferred)**
- Owner: Tier 1.5 walk batch-2 operator session
- Expiry: 2026-05-18
- Registry row: `docs/state/deferred-ac-registry.md` Active table
