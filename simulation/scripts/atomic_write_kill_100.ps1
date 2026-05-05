<#
.SYNOPSIS
    NFR-3.1 Atomic-Write Kill-100 Stress Harness for PhoenicisNex state.json.

.DESCRIPTION
    Launches terminal64.exe with atomic_write_kill.ini in background, sleeps a random
    50-500ms offset, then kills the process via Stop-Process -Force. Inspects
    state.json integrity post-kill across N trials.

    Pass criterion (NFR-3.1 + ADR-007): parse_fail == 0 AND Total == Trials.
    Acceptable outcomes per ADR-007 OnInit recovery contract:
      - state.json exists AND parses cleanly          => parse_pass
      - state.json missing AND state.json.tmp present  => state_missing_tmp_present
      - state.json missing AND state.json.tmp absent   => state_missing_tmp_missing (pre-first-write kill)

    After each trial, any state.json.tmp orphan is cleaned to avoid contaminating
    the next trial (ADR-007 (S)OnInit recovery contract).

    DryRun mode: validates params, checks terminal64.exe and .ini exist, writes a
    sidecar with verdict "DRY_RUN" - no process is spawned.

.PARAMETER Trials
    Number of kill trials to execute. Default: 100.

.PARAMETER StateRel
    Sandbox-relative path under MQL5/Files/ that the spike writes to.
    Default: 'PhoenicisNex/state' (matches atomic_write_kill.ini § [TesterInputs] InpStateFile prefix).
    fix-round-13 § 13.1 — under headless Strategy Tester run, the spike's relative
    FileOpen path resolves under the *Tester agent sandbox*, not the live-terminal
    sandbox. The harness now constructs $AbsStateDir under the Tester tree so its
    inspect path matches the spike's write path.

.PARAMETER AgentSubpath
    Strategy Tester agent subdirectory under <TesterDir>/<TerminalId>/.
    Default: 'Agent-127.0.0.1-3000' (single-agent local backtest convention).
    Override only if the local install uses a different agent (parallel optimisation
    setups may use Agent-127.0.0.1-3001+).

.PARAMETER IniPath
    Path (relative to repo root) to the Strategy Tester .ini file used per trial.
    Default: 'simulation/headless-tests/atomic_write_kill.ini'

.PARAMETER OriginFile
    Path to origin.txt containing the MT5 install root (e.g. "C:\Program Files\FBS MetaTrader 5ph").
    Default: 'origin.txt'

.PARAMETER FailFastConsecutive
    fix-round-13 § 13.4 — abort the trial loop with verdict=FAIL_FAST after this many
    consecutive startup_timeout trials. Healthy runs may see 1-2 transient timeouts
    (cold-bootstrap variance, history download); 3-in-a-row signals a path-binding
    misconfiguration (Finding 13.1 class). Default: 3. Set to 0 to disable.

.PARAMETER DryRun
    If specified, validate params + file existence + write test sidecar with verdict "DRY_RUN".
    No terminal64.exe process is spawned.

.EXAMPLE
    # Full 100-trial run (requires foreground MT5 closed beforehand)
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 100

.EXAMPLE
    # Dry-run validation (param parse + file-existence check only)
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -DryRun -Trials 5

.EXAMPLE
    # Custom state-relative path + agent subpath (parallel-optimisation install)
    # fix-round-13 § 13.1 renamed -StateDir → -StateRel; semantic also changed:
    #   value is now sandbox-RELATIVE (under <TesterAgent>/MQL5/Files/), not
    #   repo-relative under <RepoRoot>/. Default 'PhoenicisNex/state' is correct;
    #   override only if .ini also points elsewhere.
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 10 `
         -StateRel 'PhoenicisNex/state' `
         -AgentSubpath 'Agent-127.0.0.1-3001' `
         -IniPath 'simulation/headless-tests/atomic_write_kill.ini'

.NOTES
    NFR-3.1: AtomicFile.mqh write must survive simulated mid-write kill 100/100 trials.
    ADR-007: state.json uses write-temp + rename (NTFS atomic) per Option A primary.
    IMPL-064: task-ID; Tier 1.5 walk batch-2 fills numeric result table.
    Reference: docs/state/nfr-3.1-atomic-write-result.md
#>

[CmdletBinding()]
param(
    [int]    $Trials                = 100,
    [string] $StateRel              = 'PhoenicisNex/state',
    [string] $AgentSubpath          = 'Agent-127.0.0.1-3000',
    [string] $IniPath               = 'simulation/headless-tests/atomic_write_kill.ini',
    [string] $OriginFile            = 'origin.txt',
    [int]    $FailFastConsecutive   = 3,
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 0. Resolve paths
# ---------------------------------------------------------------------------
# $RepoRoot resolves to the MetaTrader 5 *terminal data directory* (the project
# root sits inside <AppData>/Roaming/MetaQuotes/Terminal/<TerminalId>/), which
# is also the live-chart sandbox parent.
$RepoRoot     = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$AbsIniPath   = Join-Path $RepoRoot $IniPath
$AbsOrigin    = Join-Path $RepoRoot $OriginFile
$SidecarPath  = Join-Path $RepoRoot 'docs/state/nfr-3.1-atomic-write-result.json'

# fix-round-13 § 13.1 CRITICAL — Strategy Tester writes to a structurally
# separate sandbox tree from the live terminal. Reference:
# .agents/skills/mt5-headless-backtest/references/log-paths.md.
#   Live terminal sandbox: <TerminalDataDir>/MQL5/Files/<rel>
#   Tester agent sandbox:  <MetaQuotesRoot>/Tester/<TerminalId>/<AgentSubpath>/MQL5/Files/<rel>
# The spike's FileOpen calls in Spike_AtomicWrite.mq5 carry no FILE_COMMON
# flag, so they resolve under whichever sandbox the EA runs in. atomic_write_kill.ini
# launches the spike via Strategy Tester, so writes land in the Tester agent
# sandbox; the harness must inspect that same tree.
$TerminalId      = Split-Path $RepoRoot -Leaf
# <RepoRoot> = <MetaQuotesRoot>/Terminal/<TerminalId> — go up two levels to reach
# <MetaQuotesRoot>, where the 'Tester' tree sits as a sibling of 'Terminal'.
$MetaQuotesRoot  = Split-Path (Split-Path $RepoRoot -Parent) -Parent
$TesterRoot      = Join-Path $MetaQuotesRoot 'Tester'
$AgentRoot       = Join-Path (Join-Path $TesterRoot $TerminalId) $AgentSubpath
$AbsStateDir     = Join-Path (Join-Path $AgentRoot 'MQL5/Files') $StateRel

Write-Host "[atomic-write-kill] Resolving terminal64.exe from: $AbsOrigin"

# ---------------------------------------------------------------------------
# 1. Validate origin.txt + terminal64.exe
# ---------------------------------------------------------------------------
if (-not (Test-Path $AbsOrigin)) {
    Write-Error "origin.txt not found at '$AbsOrigin'. Ensure you run from repo root or pass -OriginFile."
}

$MT5Root      = (Get-Content $AbsOrigin -Raw).Trim()
$Terminal64   = Join-Path $MT5Root 'terminal64.exe'

Write-Host "[atomic-write-kill] terminal64.exe: $Terminal64"
Write-Host "[atomic-write-kill] StateDir:        $AbsStateDir"
Write-Host "[atomic-write-kill] IniPath:         $AbsIniPath"
Write-Host "[atomic-write-kill] Trials:          $Trials"
Write-Host "[atomic-write-kill] DryRun:          $DryRun"

# ---------------------------------------------------------------------------
# 2. Validate inputs (always - DryRun or not)
# ---------------------------------------------------------------------------
if ($Trials -lt 1) {
    Write-Error "-Trials must be >= 1 (got $Trials)."
}

if (-not (Test-Path $Terminal64)) {
    Write-Error "terminal64.exe not found at '$Terminal64'. Check origin.txt MT5 install path."
}

if (-not (Test-Path $AbsIniPath)) {
    Write-Error ".ini file not found at '$AbsIniPath'. Commit simulation/headless-tests/atomic_write_kill.ini first."
}

# fix-round-13 § 13.1 — pre-flight check: warn if the Tester agent sandbox tree
# does not yet exist on this install. MT5 lays down the tree on first headless
# run, so the first 1-2 trials may startup-timeout before the directory appears
# (subsequent trials work normally). If timeouts persist, the AgentSubpath
# constant likely does not match this install (parallel-optimisation setups use
# Agent-127.0.0.1-3001+).
$AgentParent = Split-Path $AbsStateDir -Parent
if (-not (Test-Path $AgentParent)) {
    Write-Warning "[atomic-write-kill] Tester agent dir not found at '$AgentParent'."
    Write-Warning "  MT5 creates this tree on first headless run; first trial may startup-timeout."
    Write-Warning "  If timeouts persist, verify -AgentSubpath matches your install (default: Agent-127.0.0.1-3000)."
}

# ---------------------------------------------------------------------------
# 3. DryRun - write sidecar + exit
# ---------------------------------------------------------------------------
if ($DryRun) {
    Write-Host "[atomic-write-kill] DRY_RUN mode - no process spawned."

    $sidecar = [ordered]@{
        schema_version = 1
        task_id        = 'IMPL-064'
        run_at         = (Get-Date -Format 'o')
        trials         = $Trials
        dry_run        = $true
        terminal64     = $Terminal64
        ini_path       = $AbsIniPath
        state_dir      = $AbsStateDir
        agent_subpath  = $AgentSubpath
        state_rel      = $StateRel
        verdict        = 'DRY_RUN'
        parse_pass                = 0
        parse_fail                = 0
        state_missing_tmp_present = 0
        state_missing_tmp_missing = 0
        startup_timeout_count     = 0
        failed_fast               = $false
        fail_fast_consecutive     = $FailFastConsecutive
        note           = 'Dry-run only - param validation + file-existence check passed. Numeric run deferred to Tier 1.5 walk batch-2.'
    }

    $sidecarJson = $sidecar | ConvertTo-Json -Depth 5
    Set-Content -Path $SidecarPath -Value $sidecarJson -Encoding utf8
    Write-Host "[atomic-write-kill] Sidecar written: $SidecarPath"
    Write-Host "[atomic-write-kill] verdict=DRY_RUN - param parse OK, terminal64.exe found, .ini found."
    return
}

# ---------------------------------------------------------------------------
# 4. Counters
# ---------------------------------------------------------------------------
$parse_pass                = 0
$parse_fail                = 0
$state_missing_tmp_present = 0
$state_missing_tmp_missing = 0
# fix-round-12 §12.3 — track trials where MT5 startup never produced a write
#   target before the bounded poll deadline expired. A healthy run should
#   show startup_timeout_count == 0; non-zero means the spike's write loop
#   never started within 60s, so the kill window did not race a real write.
$startup_timeout_count     = 0

# fix-round-13 § 13.4 — track consecutive startup timeouts so the harness can
#   fail-fast on systemic path-binding misconfiguration (Finding 13.1 class)
#   instead of burning Trials × 60s of wall clock before the verdict prints.
$consecutive_timeouts      = 0
$failed_fast               = $false

$StateJson    = Join-Path $AbsStateDir 'state.json'
$StateTmp     = Join-Path $AbsStateDir 'state.json.tmp'

Write-Host "[atomic-write-kill] Starting $Trials kill trials..."
Write-Host "[atomic-write-kill] WARNING: Ensure foreground MT5 (terminal64.exe) is closed before running."

# ---------------------------------------------------------------------------
# 5. Trial loop
# ---------------------------------------------------------------------------
for ($i = 1; $i -le $Trials; $i++) {

    # 5a. Launch terminal64.exe in background
    $proc = $null
    try {
        $proc = Start-Process -FilePath $Terminal64 `
                              -ArgumentList "/config:`"$AbsIniPath`"" `
                              -PassThru
    } catch {
        Write-Warning "[atomic-write-kill] Trial $i - failed to start terminal64.exe: $_"
        $parse_fail++
        continue
    }

    # 5b. fix-round-12 §12.3 — poll-then-attack: wait for the spike to start
    #     writing (state.json or state.json.tmp appears) before applying the
    #     50-500ms random offset. Without this, a fixed 50-500ms sleep
    #     pre-empts terminal64.exe cold-bootstrap (typically 3-15s) so the
    #     kill arrives before any write target exists, leaving every trial
    #     in `state_missing_tmp_missing` with `verdict=PASS` despite zero
    #     atomic writes ever being raced (false-positive NFR-3.1 closure).
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
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        try { Wait-Process -Id $proc.Id -Timeout 10 -ErrorAction SilentlyContinue } catch { }
        # Clean any partial .tmp orphan before next trial
        if (Test-Path $StateTmp) {
            Remove-Item -Path $StateTmp -Force -ErrorAction SilentlyContinue
        }
        $startup_timeout_count++
        $consecutive_timeouts++

        # fix-round-13 § 13.4 — fail-fast on N consecutive startup_timeouts.
        # 1-2 timeouts can be transient (cold boot, history download); 3-in-a-row
        # signals systemic path-binding misconfiguration (Finding 13.1 class).
        # Convert a 100-min FAIL discovery into a ~3-min discovery, same fail-closed.
        if ($FailFastConsecutive -gt 0 -and $consecutive_timeouts -ge $FailFastConsecutive) {
            Write-Warning "[atomic-write-kill] FAIL_FAST: $consecutive_timeouts consecutive startup timeouts at trial $i/$Trials. Aborting trial loop."
            Write-Warning "  Likely cause: path-binding mismatch between harness inspect path and spike write path."
            Write-Warning "  Audit: state dir inspected by harness = $AbsStateDir"
            Write-Warning "  Audit: ini override path             = PhoenicisNex/state/state.json (relative under spike's runtime sandbox)"
            Write-Warning "  Audit: spike runtime sandbox under headless Tester = <Tester>/<TerminalId>/$AgentSubpath/MQL5/Files/..."
            Write-Warning "  Reference: .agents/skills/mt5-headless-backtest/references/log-paths.md (sandbox tree separation)."
            $failed_fast = $true
            break
        }
        continue
    }

    # fix-round-13 § 13.4 — successful poll resets the consecutive counter.
    #   1-2 transient timeouts inside a healthy run are fine; only an unbroken
    #   chain trips fail-fast.
    $consecutive_timeouts = 0

    # 5c. Random sleep 50-500ms — now the window genuinely lands inside an
    #     active write iteration (paired with InpTotalWrites=100000 in the
    #     .ini override per fix-round-12 §12.3).
    $sleepMs = Get-Random -Minimum 50 -Maximum 501
    Start-Sleep -Milliseconds $sleepMs

    # 5d. Kill the process
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

    # 5e. Wait for full exit (max 10s)
    try {
        Wait-Process -Id $proc.Id -Timeout 10 -ErrorAction SilentlyContinue
    } catch {
        # process already gone - acceptable
    }

    # 5f. Inspect state dir
    $jsonExists = Test-Path $StateJson
    $tmpExists  = Test-Path $StateTmp

    if ($jsonExists) {
        # Try parse
        try {
            $raw = Get-Content $StateJson -Raw -ErrorAction Stop
            $null = $raw | ConvertFrom-Json -ErrorAction Stop
            $parse_pass++
            Write-Verbose "[atomic-write-kill] Trial $i/${Trials}: parse_pass (sleep=${sleepMs}ms)"
        } catch {
            $parse_fail++
            Write-Warning "[atomic-write-kill] Trial $i/${Trials}: PARSE_FAIL - state.json not valid JSON! (sleep=${sleepMs}ms) Error: $_"
        }
    } elseif ($tmpExists) {
        $state_missing_tmp_present++
        Write-Verbose "[atomic-write-kill] Trial $i/${Trials}: state_missing_tmp_present (pre-rename kill, acceptable per ADR-007)"
    } else {
        $state_missing_tmp_missing++
        Write-Verbose "[atomic-write-kill] Trial $i/${Trials}: state_missing_tmp_missing (pre-first-write kill, acceptable)"
    }

    # 5g. Clean .tmp orphan (ADR-007 (S)OnInit recovery contract - harness mimics OnInit behaviour)
    if ($tmpExists) {
        Remove-Item -Path $StateTmp -Force -ErrorAction SilentlyContinue
    }

    # 5h. Progress every 10 trials
    if ($i % 10 -eq 0) {
        Write-Host "[atomic-write-kill] Progress $i/$Trials - parse_pass=$parse_pass parse_fail=$parse_fail missing_tmp_present=$state_missing_tmp_present missing_clean=$state_missing_tmp_missing startup_timeout=$startup_timeout_count"
    }
}

# ---------------------------------------------------------------------------
# 6. Aggregate + verdict
# ---------------------------------------------------------------------------
$total   = $parse_pass + $parse_fail + $state_missing_tmp_present + $state_missing_tmp_missing + $startup_timeout_count
# fix-round-12 §12.3 — verdict requires every trial to have actually exercised
#   a write loop. startup_timeout_count > 0 means MT5 startup never produced
#   a write target before deadline; that trial did NOT race a real atomic
#   write and cannot count toward NFR-3.1 100/100.
# fix-round-13 §13.4 — fail-fast aborts the loop early; total < Trials in that
#   case, which the (-eq $Trials) clause already catches as FAIL. Verdict
#   string distinguishes FAIL_FAST from FAIL for operator visibility.
$isPass  = (-not $failed_fast) -and ($parse_fail -eq 0) -and ($total -eq $Trials) -and ($startup_timeout_count -eq 0)
$verdict = if ($isPass)        { 'PASS' }
           elseif ($failed_fast) { 'FAIL_FAST' }
           else                  { 'FAIL' }

Write-Host ""
Write-Host "=========================================="
Write-Host "[atomic-write-kill] trials=$Trials parse_pass=$parse_pass parse_fail=$parse_fail missing_tmp_present=$state_missing_tmp_present missing_clean=$state_missing_tmp_missing startup_timeout=$startup_timeout_count verdict=$verdict"
Write-Host "=========================================="

if (-not $isPass) {
    if ($parse_fail -gt 0) {
        Write-Warning "[atomic-write-kill] FAIL: $parse_fail trial(s) produced a non-parseable state.json - NFR-3.1 violated."
    }
    if (-not $failed_fast -and $total -ne $Trials) {
        Write-Warning "[atomic-write-kill] FAIL: total outcomes ($total) != Trials ($Trials) - accounting error."
    }
    if ($startup_timeout_count -gt 0) {
        Write-Warning "[atomic-write-kill] FAIL: $startup_timeout_count trial(s) hit MT5 startup timeout (60s) without ever creating a write target - kill never raced an atomic write. Investigate terminal64.exe boot time or .ini path."
    }
    if ($failed_fast) {
        Write-Warning "[atomic-write-kill] FAIL_FAST: aborted at $total/$Trials trial(s) after $FailFastConsecutive consecutive startup timeouts. Re-run with -FailFastConsecutive 0 to disable, or audit AgentSubpath / sandbox-tree binding (Finding 13.1)."
    }
}

# ---------------------------------------------------------------------------
# 7. Write JSON sidecar (machine-readable; orchestrator-readable)
# ---------------------------------------------------------------------------
$sidecarNote = if ($isPass) {
    'All trials passed NFR-3.1 integrity check.'
} else {
    "FAIL: parse_fail=$parse_fail. Investigate state.json content in $AbsStateDir."
}

$sidecar = [ordered]@{
    schema_version            = 1
    task_id                   = 'IMPL-064'
    run_at                    = (Get-Date -Format 'o')
    trials                    = $Trials
    dry_run                   = $false
    terminal64                = $Terminal64
    ini_path                  = $AbsIniPath
    state_dir                 = $AbsStateDir
    agent_subpath             = $AgentSubpath
    state_rel                 = $StateRel
    verdict                   = $verdict
    parse_pass                = $parse_pass
    parse_fail                = $parse_fail
    state_missing_tmp_present = $state_missing_tmp_present
    state_missing_tmp_missing = $state_missing_tmp_missing
    startup_timeout_count     = $startup_timeout_count
    failed_fast               = $failed_fast
    fail_fast_consecutive     = $FailFastConsecutive
    nfr_ref                   = 'NFR-3.1'
    adr_ref                   = 'ADR-007'
    note                      = $sidecarNote
}

$sidecarJson = $sidecar | ConvertTo-Json -Depth 5
Set-Content -Path $SidecarPath -Value $sidecarJson -Encoding utf8
Write-Host "[atomic-write-kill] Sidecar written: $SidecarPath"
