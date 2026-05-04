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

.PARAMETER StateDir
    Path (relative to repo root) to the PhoenicisNex state directory.
    Default: 'MQL5/Files/PhoenicisNex/state'

.PARAMETER IniPath
    Path (relative to repo root) to the Strategy Tester .ini file used per trial.
    Default: 'simulation/headless-tests/atomic_write_kill.ini'

.PARAMETER OriginFile
    Path to origin.txt containing the MT5 install root (e.g. "C:\Program Files\FBS MetaTrader 5ph").
    Default: 'origin.txt'

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
    # Custom state dir + ini path
    pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 10 `
         -StateDir 'MQL5/Files/PhoenicisNex/state' `
         -IniPath 'simulation/headless-tests/atomic_write_kill.ini'

.NOTES
    NFR-3.1: AtomicFile.mqh write must survive simulated mid-write kill 100/100 trials.
    ADR-007: state.json uses write-temp + rename (NTFS atomic) per Option A primary.
    IMPL-064: task-ID; Tier 1.5 walk batch-2 fills numeric result table.
    Reference: docs/state/nfr-3.1-atomic-write-result.md
#>

[CmdletBinding()]
param(
    [int]    $Trials     = 100,
    [string] $StateDir   = 'MQL5/Files/PhoenicisNex/state',
    [string] $IniPath    = 'simulation/headless-tests/atomic_write_kill.ini',
    [string] $OriginFile = 'origin.txt',
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 0. Resolve paths
# ---------------------------------------------------------------------------
$RepoRoot     = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$AbsStateDir  = Join-Path $RepoRoot $StateDir
$AbsIniPath   = Join-Path $RepoRoot $IniPath
$AbsOrigin    = Join-Path $RepoRoot $OriginFile
$SidecarPath  = Join-Path $RepoRoot 'docs/state/nfr-3.1-atomic-write-result.json'

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
        verdict        = 'DRY_RUN'
        parse_pass                = 0
        parse_fail                = 0
        state_missing_tmp_present = 0
        state_missing_tmp_missing = 0
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

    # 5b. Random sleep 50-500ms (attack window inside write-tmp phase)
    $sleepMs = Get-Random -Minimum 50 -Maximum 501
    Start-Sleep -Milliseconds $sleepMs

    # 5c. Kill the process
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

    # 5d. Wait for full exit (max 10s)
    try {
        Wait-Process -Id $proc.Id -Timeout 10 -ErrorAction SilentlyContinue
    } catch {
        # process already gone - acceptable
    }

    # 5e. Inspect state dir
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

    # 5f. Clean .tmp orphan (ADR-007 (S)OnInit recovery contract - harness mimics OnInit behaviour)
    if ($tmpExists) {
        Remove-Item -Path $StateTmp -Force -ErrorAction SilentlyContinue
    }

    # 5g. Progress every 10 trials
    if ($i % 10 -eq 0) {
        Write-Host "[atomic-write-kill] Progress $i/$Trials - parse_pass=$parse_pass parse_fail=$parse_fail missing_tmp_present=$state_missing_tmp_present missing_clean=$state_missing_tmp_missing"
    }
}

# ---------------------------------------------------------------------------
# 6. Aggregate + verdict
# ---------------------------------------------------------------------------
$total   = $parse_pass + $parse_fail + $state_missing_tmp_present + $state_missing_tmp_missing
$isPass  = ($parse_fail -eq 0) -and ($total -eq $Trials)
$verdict = if ($isPass) { 'PASS' } else { 'FAIL' }

Write-Host ""
Write-Host "=========================================="
Write-Host "[atomic-write-kill] trials=$Trials parse_pass=$parse_pass parse_fail=$parse_fail missing_tmp_present=$state_missing_tmp_present missing_clean=$state_missing_tmp_missing verdict=$verdict"
Write-Host "=========================================="

if (-not $isPass) {
    if ($parse_fail -gt 0) {
        Write-Warning "[atomic-write-kill] FAIL: $parse_fail trial(s) produced a non-parseable state.json - NFR-3.1 violated."
    }
    if ($total -ne $Trials) {
        Write-Warning "[atomic-write-kill] FAIL: total outcomes ($total) != Trials ($Trials) - accounting error."
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
    verdict                   = $verdict
    parse_pass                = $parse_pass
    parse_fail                = $parse_fail
    state_missing_tmp_present = $state_missing_tmp_present
    state_missing_tmp_missing = $state_missing_tmp_missing
    nfr_ref                   = 'NFR-3.1'
    adr_ref                   = 'ADR-007'
    note                      = $sidecarNote
}

$sidecarJson = $sidecar | ConvertTo-Json -Depth 5
Set-Content -Path $SidecarPath -Value $sidecarJson -Encoding utf8
Write-Host "[atomic-write-kill] Sidecar written: $SidecarPath"
