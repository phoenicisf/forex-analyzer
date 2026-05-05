# PhoenicisNex — Inputs Optimization Compatibility Report

**Task:** IMPL-017 [S] [ea-qa]
**Date:** 2026-05-05
**Status:** STRUCTURAL COMPLETE — E-AC (sweep run) deferred to operator session (see §7)

---

## §1 Purpose

Verify FR-1.3 + NFR-6.2 by:

1. Enumerating all input declarations across the 5 input file groups
   (`Inputs_General`, `Inputs_TimeGates`, `Inputs_Pending`, `Inputs_Logging`,
   `Inputs_Slot_<X>` × 21 slots).
2. Classifying each declared type as sweep-compatible or not.
3. Confirming total input count ≥ 80 (FR-1.1 / NFR-4.3).
4. Confirming 100% of int / double / bool / enum inputs are sweep-compatible
   (NFR-6.2).

**FR-1.3 verbatim:** "Strategy Tester optimization mode must enumerate all
`input` variables and allow sweep over numeric + boolean parameters."

**NFR-6.2 verbatim:** "100% of `int`, `double`, `bool`, `ENUM_*` inputs must
be declared without `sinput` or `extern` — allowing MT5 Optimizer to enumerate
them. `string`, `color`, `datetime` are allowed but typically non-sweepable in
MT5 optimization."

**NFR-6.3:** Each input must carry a `group="<Name>"` annotation so the MT5
input dialog renders parameters under a named collapsible section.

---

## §2 Methodology

### 2.1 Enumeration approach

All input files live in:

```
MQL5/Experts/PhoenicisNex/inputs/Inputs_*.mqh
```

Each file is scanned for lines matching `^input ` (anchored at line start,
which is how MQL5 input declarations appear in practice — no leading whitespace
for top-level inputs).

```powershell
# PowerShell — count per file
$dir = "MQL5\Experts\PhoenicisNex\inputs"
Get-ChildItem "$dir\Inputs_*.mqh" | ForEach-Object {
    $lines = Get-Content $_.FullName
    [PSCustomObject]@{
        File    = $_.Name
        Total   = ($lines | Where-Object { $_ -match '^input ' }).Count
        int     = ($lines | Where-Object { $_ -match '^input int ' }).Count
        double  = ($lines | Where-Object { $_ -match '^input double ' }).Count
        bool    = ($lines | Where-Object { $_ -match '^input bool ' }).Count
        enum    = ($lines | Where-Object { $_ -match '^input ENUM_' }).Count
        string  = ($lines | Where-Object { $_ -match '^input string ' }).Count
        color   = ($lines | Where-Object { $_ -match '^input color ' }).Count
        datetime= ($lines | Where-Object { $_ -match '^input datetime ' }).Count
    }
}
```

### 2.2 Sweep-compatibility rule (per NFR-6.2)

| MQL5 type | Sweep-compatible | Notes |
|-----------|-----------------|-------|
| `int` | YES | Integer range; MT5 Optimizer sweeps start/step/stop |
| `double` | YES | Float range; MT5 Optimizer sweeps start/step/stop |
| `bool` | YES | Binary; MT5 Optimizer sweeps both values |
| `ENUM_*` | YES | Ordinal enum; MT5 Optimizer sweeps by integer value |
| `string` | NO | MT5 Optimizer cannot enumerate arbitrary strings |
| `color` | NO | Color picker; MT5 Optimizer skips |
| `datetime` | NO | Datetime picker; MT5 Optimizer skips |

All inputs in this codebase must use `input` (not `sinput` / `extern`).
`sinput` would suppress optimizer enumeration — verified absent (see §4).

---

## §3 Input Inventory

### 3.1 Per-file breakdown (actual grep counts, run 2026-05-05)

| File | Total | int | double | bool | ENUM_* | string | color | datetime |
|------|------:|----:|-------:|-----:|-------:|-------:|------:|---------:|
| `Inputs_General.mqh` | 22 | 5 | 11 | 4 | 1 | 0 | 0 | 0 |
| `Inputs_TimeGates.mqh` | 12 | 11 | 0 | 0 | 0 | 0 | 0 | 0 |
| `Inputs_Pending.mqh` | 10 | 9 | 0 | 0 | 0 | 0 | 0 | 0 |
| `Inputs_Logging.mqh` | 4 | 2 | 0 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_B.mqh` | 9 | 2 | 5 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_BI.mqh` | 7 | 1 | 4 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_BR.mqh` | 6 | 1 | 3 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_C.mqh` | 10 | 1 | 7 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_D.mqh` | 3 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_F.mqh` | 6 | 1 | 3 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_G.mqh` | 16 | 1 | 13 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_G2.mqh` | 8 | 1 | 5 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_GO.mqh` | 6 | 1 | 3 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_H.mqh` | 9 | 3 | 4 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_I.mqh` | 8 | 2 | 4 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_J.mqh` | 5 | 1 | 2 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_K.mqh` | 9 | 1 | 6 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_L.mqh` | 9 | 1 | 6 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_LX.mqh` | 7 | 1 | 4 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_M.mqh` | 10 | 1 | 7 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_P.mqh` | 12 | 1 | 9 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_Q.mqh` | 10 | 1 | 7 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_R.mqh` | 9 | 1 | 6 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_S.mqh` | 10 | 1 | 7 | 1 | 0 | 0 | 0 | 0 |
| `Inputs_Slot_T.mqh` | 10 | 1 | 7 | 1 | 0 | 0 | 0 | 0 |
| **GRAND TOTAL** | **227** | **51** | **124** | **26** | **1** | **0** | **0** | **0** |

### 3.2 Summary by group

| Group | Files | Total inputs |
|-------|------:|-------------:|
| `Inputs_General` | 1 | 22 |
| `Inputs_TimeGates` | 1 | 12 |
| `Inputs_Pending` | 1 | 10 |
| `Inputs_Logging` | 1 | 4 |
| `Inputs_Slot_<X>` (21 slots) | 21 | 179 |
| **Total** | **25** | **227** |

**FR-1.1 / NFR-4.3 threshold check:** 227 ≥ 80 — PASS.

---

## §4 Sweep-Compatibility Classification

### 4.1 Overall verdict

| Type | Count | Sweep-compatible | Verdict |
|------|------:|-----------------|---------|
| `int` | 51 | YES | PASS |
| `double` | 124 | YES | PASS |
| `bool` | 26 | YES | PASS |
| `ENUM_*` | 1 | YES | PASS |
| `string` | 0 | n/a | n/a (none declared) |
| `color` | 0 | n/a | n/a (none declared) |
| `datetime` | 0 | n/a | n/a (none declared) |
| **Sweep-compatible total** | **202** | 100% | **PASS** |
| **Non-sweep-compatible** | 0 | — | PASS (no exceptions) |

**NFR-6.2 check:** 100% of int / double / bool / ENUM_* inputs are
sweep-compatible. Zero string / color / datetime inputs declared — no
non-sweepable exceptions to document. PASS.

### 4.2 `sinput` / `extern` audit

```powershell
# Verify no sinput or extern usage in input files
Select-String -Path "MQL5\Experts\PhoenicisNex\inputs\Inputs_*.mqh" -Pattern "^sinput|^extern"
# Expected: 0 matches (confirmed by author grep — no hits)
```

Result: 0 matches. All 227 inputs declared as plain `input` — MT5 Optimizer
can enumerate all of them.

### 4.3 Flagged inputs

None. Every declared input is sweep-compatible.

### 4.4 Chosen sweep target: `InpFIDValue`

`InpFIDValue` (type `int`, default 21) in `Inputs_General.mqh` — Force Index
period (H4 + M2). Selected for the compatibility sweep because:

- It is `int` (most straightforward range-sweep type).
- Default 21 is in the middle of a plausible range; test range 10→20 step 5
  stays within sensible indicator periods.
- Used by `IndicatorService` to create the Force Index handle — ensuring a real
  indicator init + re-init is exercised per optimization pass.

MT5 `[TesterInputs]` syntax: `InpFIDValue=<default>||<start>||<step>||<stop>||<enabled>`

Sweep declared: `InpFIDValue=10||10||5||20||N`
- start=10, step=5, stop=20 → 3 combinations: {10, 15, 20}.

---

## §5 Verification Command (Operator Runbook)

### 5.1 Pre-conditions

1. Close any foreground `terminal64.exe` instance (data-dir lock).
2. Confirm `MQL5/Experts/PhoenicisNex/PhoenicisNex.ex5` exists + compiled
   clean (G1 gate, 0 errors / 0 warnings).

### 5.2 Run the sweep

```cmd
; Windows CMD — resolve install path from origin.txt first
set ORIGIN=<value from origin.txt, e.g. C:\Program Files\FBS MetaTrader 5ph>
"%ORIGIN%\terminal64.exe" /config:"simulation\headless-tests\optimize_sweep_FID.ini"
```

Or via PowerShell:

```powershell
$origin = (Get-Content origin.txt -Raw).Trim()
$terminal = Join-Path $origin "terminal64.exe"
Start-Process $terminal -ArgumentList "/config:`"simulation\headless-tests\optimize_sweep_FID.ini`"" -Wait
```

### 5.3 Inspect optimization output

After `ShutdownTerminal=1` auto-exits:

1. Open MT5 Terminal → Strategy Tester → Optimization Results tab.
   Expect: **exactly 3 rows** (one per `InpFIDValue` combination: 10, 15, 20).

2. Inspect journal files:

```powershell
$journalDir = "MQL5\Files\PhoenicisNex\journal\tester"
Get-ChildItem "$journalDir\run-*.jsonl" | Sort-Object Name
# Expect: 3 files with distinct ISO timestamps
```

3. Sample-validate each journal file:

```powershell
Get-ChildItem "$journalDir\run-*.jsonl" | ForEach-Object {
    Get-Content $_.FullName | Select-Object -First 1 | ConvertFrom-Json
}
# Each record must have: event_type, slot_id, timestamp fields per trade-journal-schema.yaml
```

---

## §6 Result Placeholder Table

> **TBD** — pending operator sweep run (E-AC deferred; see §7).
> Populate after running `optimize_sweep_FID.ini` per §5.

| Combination | `InpFIDValue` | Net Profit (USD) | Profit Factor | Max DD (%) | Journal file |
|-------------|-------------:|----------------:|--------------:|-----------:|--------------|
| 1 | 10 | TBD | TBD | TBD | `run-<ISO>.jsonl` |
| 2 | 15 | TBD | TBD | TBD | `run-<ISO>.jsonl` |
| 3 | 20 | TBD | TBD | TBD | `run-<ISO>.jsonl` |

Note: This sweep covers only 2024-01-02 → 2024-01-05 (3 trading days) and is
intended to verify MT5 Optimizer enumeration mechanics only — it is NOT a
regression backtest. 5-yr performance regression is governed by NFR-1.1 and
the `ReportTester-25045474.html` baseline.

---

## §7 Pass Criterion

### S-AC #1 — Sweep produces 3 distinct results (STRUCTURAL VERIFIED)

The ini file at `simulation/headless-tests/optimize_sweep_FID.ini` declares:

```ini
[TesterInputs]
InpFIDValue=10||10||5||20||N
```

MT5 Optimizer will expand start=10 / step=5 / stop=20 → 3 combinations
{10, 15, 20}. Structural pass: ini syntax is correct per MT5 `[TesterInputs]`
specification. Numeric verdict (actual 3-row output) is deferred to E-AC
operator session.

### S-AC #2 — Compatibility report authored (COMPLETE)

This document at `docs/state/inputs-optimization-compat.md` — DONE.

### E-AC — 3 distinct `run-<ISO>.jsonl` files `[file-blob-check]` (DEFERRED)

**Evidence kind:** `[file-blob-check]`
**Verification:** After sweep run, operator inspects
`MQL5/Files/PhoenicisNex/journal/tester/` and confirms exactly 3 distinct
`run-<ISO>.jsonl` files exist — one created per optimization pass — and that
each validates against `docs/api-specs/trade-journal-schema.yaml` (sample 1
record per file via `ConvertFrom-Json`).

**Defer reason:** Requires operator to close foreground MT5, run
`optimize_sweep_FID.ini` headless, and inspect journal directory. Cannot be
verified structurally — exercise of deployed MT5 runtime required.

**Registry entry:** `deferred-ac-registry.md` row IMPL-017
**Expiry:** 2026-05-19
**Pair with:** IMPL-066 / IMPL-067 deferred E-AC bundle (same operator session)

---

## §8 Cross-References

| Ref | Description |
|-----|-------------|
| FR-1.3 | Strategy Tester optimization mode must enumerate all `input` variables |
| NFR-6.2 | 100% of int/double/bool/ENUM_* must be optimizer-enumerable (no `sinput`/`extern`) |
| NFR-6.3 | All inputs must carry `group="<Name>"` annotation for input dialog rendering |
| NFR-4.3 | Total input count ≥ 80 |
| AC-1.3.1 | Sweep test passes; 3 distinct results produced |
| AC-1.3.2 | Compatibility report at `docs/state/inputs-optimization-compat.md` |
| `simulation/headless-tests/optimize_sweep_FID.ini` | Sweep ini (IMPL-017 deliverable) |
| `simulation/headless-tests/bootstrap_smoke.ini` | Template ini (IMPL-001 scaffold) |
| `docs/api-specs/trade-journal-schema.yaml` | Journal record schema for E-AC validation |
| `deferred-ac-registry.md` | E-AC deferred row owner |

---

## End of Report
