# ADR-008 Force-Clear Validation — Pending State Safety Threshold Analysis

**Task:** IMPL-068 — Force-clear validation per A6 (ADR-008 threshold tuning)
**Status:** Pipeline + template committed (structural close); numeric data deferred to IMPL-062/063 5-yr regression run
**Opened:** 2026-05-04
**Author:** IMPL-068 subagent (andm-impl-engineer)

**Cross-links:**
- ADR: `docs/adr/008-pending-state-safety-force-clear.md`
- A6 risk reference: `docs/ba/03-non-functional-requirements.md § A6`
- OQ-A1/A2/A3 anchor: `docs/ba/01-project-brief.md § 10.1`
- Journal schema: `docs/api-specs/trade-journal-schema.yaml § event_type`
- Impl plan: `docs/state/impl-plan.md § IMPL-061..063`

---

## 1. Validation Goal

Per ADR-008 §Validation strategy, the pending-state safety force-clear mechanism is a last-resort safety net: it transitions a stuck M/T/Q pending state to IDLE after exceeding a hard bar-count threshold, emitting a `pending_force_clear` journal event with `pending_age_bars` and `pending_payload` fields. The expected baseline behavior is **zero force-clear events** in a 5-yr regression run (2021–2025), because the force-clear threshold is set conservatively well above any valid pending-trigger window. If the 5-yr regression (produced by IMPL-062/063 Bucket A baseline run) reveals `force_clear_count > 0` per machine, each event must be inspected: does the force-clear cut a genuinely stuck pending (safety net working as designed), or does it cut a valid trigger window (= Bucket A drift requiring threshold amendment)? If `max(pending_age_bars)` per machine exceeds 70% of that machine's hard threshold, ADR-008 must be amended to tune the threshold up, preserving behavioral parity per NFR-1.1.

---

## 2. Threshold Reference Table

| Machine | Hard force-clear (bars) | Trading days (~) | Configurable input | Source |
|---|---|---|---|---|
| M-Pending (BR-6.5) | 150 | ~25 | `InpForceClearM_Bars` | ADR-008 §Decision |
| T-Pending (BR-6.6) | 80 | ~13 | `InpForceClearT_Bars` | ADR-008 §Decision |
| Q-Pending (BR-6.7) | 100 | ~17 | `InpForceClearQ_Bars` | ADR-008 §Decision |

**70% revisit trigger thresholds:**

| Machine | Threshold (bars) | 70% trigger level | Tune action if triggered |
|---|---|---|---|
| M | 150 | 105 | ADR-008 amendment: raise M threshold |
| T | 80 | 56 | ADR-008 amendment: raise T threshold |
| Q | 100 | 70 | ADR-008 amendment: raise Q threshold |

---

## 3. Data Source

**Primary journal:** `MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl` (JSON-Lines append-only)
**Produced by:** IMPL-062 (Bucket A 5-yr regression) + IMPL-063 (Bucket B regression) — both depend on IMPL-061 baseline parser output
**Schema reference:** `docs/api-specs/trade-journal-schema.yaml`

Relevant `event_type` enum value:
- `pending_force_clear` — "M/T/Q-Pending hard timeout fired (ADR-008)"

Key fields per `pending_force_clear` record:
- `slot_id` — machine identifier ("M", "T", or "Q")
- `magic` — magic number (M=207, T=213, Q=209 per BR-1.1)
- `timestamp` — ISO-8601 event time
- `pending_age_bars` — H4 bars elapsed since pending state was entered
- `pending_payload` — snapshot of pending state at fire time (for inspection)
- `signal_context` — original trigger context; for Q: `signal_context.q_pending_code` (0/1/2/3)

---

## 4. jq Pipeline — Per-Machine Count + Histogram

> Run from working directory containing `MQL5/Files/PhoenicisNex/journal/tester/`
> Requires `jq` (install via Chocolatey: `choco install jq`) and Git Bash or WSL.
> If `jq` absent, run PowerShell fallback (Section 4b).

### 4a. jq Pipeline (Git Bash / WSL)

**Step 1 — Force-clear event count per machine (M/T/Q):**

```bash
jq -r 'select(.event_type=="pending_force_clear") | .slot_id' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl \
  | sort | uniq -c
```

Expected baseline output: *(no output = 0 force-clear events = PASS)*

**Step 2 — Raw `pending_age_bars` per machine (M):**

```bash
jq -c 'select(.event_type=="pending_force_clear" and .slot_id=="M") | .pending_age_bars' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl
```

*(Repeat with `.slot_id=="T"` and `.slot_id=="Q"` for T and Q machines.)*

**Step 3 — Max `pending_age_bars` per machine (sanity check vs 70% threshold):**

```bash
# M machine (threshold 150 bars, 70% = 105)
jq -s '[.[] | select(.event_type=="pending_force_clear" and .slot_id=="M") | .pending_age_bars] | max' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl

# T machine (threshold 80 bars, 70% = 56)
jq -s '[.[] | select(.event_type=="pending_force_clear" and .slot_id=="T") | .pending_age_bars] | max' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl

# Q machine (threshold 100 bars, 70% = 70)
jq -s '[.[] | select(.event_type=="pending_force_clear" and .slot_id=="Q") | .pending_age_bars] | max' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl
```

**Step 4 — Histogram (binned 0-30 / 31-60 / 61-90 / 91-120 / 121-150) per machine:**

```bash
# M machine histogram
jq -r 'select(.event_type=="pending_force_clear" and .slot_id=="M") | .pending_age_bars' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl \
  | awk '
    {
      if ($1 <= 30)       bin["0-30"]++
      else if ($1 <= 60)  bin["31-60"]++
      else if ($1 <= 90)  bin["61-90"]++
      else if ($1 <= 120) bin["91-120"]++
      else                bin["121-150"]++
    }
    END {
      printf "M histogram:\n"
      printf "  0-30:    %d\n", bin["0-30"]+0
      printf "  31-60:   %d\n", bin["31-60"]+0
      printf "  61-90:   %d\n", bin["61-90"]+0
      printf "  91-120:  %d\n", bin["91-120"]+0
      printf "  121-150: %d\n", bin["121-150"]+0
    }'

# Repeat substituting slot_id=="T" (bins 0-20/21-40/41-60/61-80)
# Repeat substituting slot_id=="Q" (bins 0-25/26-50/51-75/76-100)
```

**Step 5 — Full force-clear record extract (for payload inspection):**

```bash
jq -c 'select(.event_type=="pending_force_clear") | {slot_id, magic, timestamp, pending_age_bars, signal_context}' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl
```

### 4b. PowerShell Fallback (no jq / Git Bash)

```powershell
# PowerShell fallback — parse JSON-Lines + filter + count
$journalDir = "MQL5\Files\PhoenicisNex\journal\tester"
$records = Get-ChildItem -Path $journalDir -Filter "run-*.jsonl" |
    ForEach-Object { Get-Content $_.FullName } |
    ForEach-Object { $_ | ConvertFrom-Json } |
    Where-Object { $_.event_type -eq "pending_force_clear" }

# Count per machine
$records | Group-Object slot_id | Select-Object Name, Count

# Max pending_age_bars per machine
$records | Group-Object slot_id | ForEach-Object {
    $maxBars = ($_.Group | Measure-Object pending_age_bars -Maximum).Maximum
    [PSCustomObject]@{ Machine=$_.Name; MaxBars=$maxBars }
}

# Histogram for M
$mRecords = $records | Where-Object { $_.slot_id -eq "M" }
$bins = @{ "0-30"=0; "31-60"=0; "61-90"=0; "91-120"=0; "121-150"=0 }
foreach ($rec in $mRecords) {
    $b = $rec.pending_age_bars
    if ($b -le 30)       { $bins["0-30"]++ }
    elseif ($b -le 60)   { $bins["31-60"]++ }
    elseif ($b -le 90)   { $bins["61-90"]++ }
    elseif ($b -le 120)  { $bins["91-120"]++ }
    else                 { $bins["121-150"]++ }
}
$bins
```

---

## 5. Q-Pending Sub-Code Analysis

Q machine has 4 sub-codes (`QPendingCode 0/1/2/3`) per CodeWiki §2.5. Expected resolve timing differs across sub-codes. If a single sub-code dominates the `pending_age_bars > 70`-bar tail, revisit per-code thresholds.

**Sub-code distribution filter:**

```bash
jq -r 'select(.event_type=="pending_force_clear" and .slot_id=="Q") | .signal_context.q_pending_code' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl \
  | sort | uniq -c
```

**PowerShell equivalent:**

```powershell
$records |
  Where-Object { $_.slot_id -eq "Q" } |
  Group-Object { $_.signal_context.q_pending_code } |
  Select-Object Name, Count
```

**Routing rule:** if sub-code analysis reveals a single code driving >70-bar tail → document in §6 Result table + route to ADR-008 amendment for per-code threshold refinement (out of scope for this task; amendment template in §9).

---

## 6. Result Placeholder Table

> Fill after IMPL-062 Bucket A regression run produces `run-*.jsonl` journal records.

| Machine | force_clear_count (5-yr) | max pending_age_bars | 70% threshold | Tune action |
|---|---|---|---|---|
| M | TBD | TBD | 105 (0.7 × 150) | TBD |
| T | TBD | TBD | 56 (0.7 × 80)   | TBD |
| Q | TBD | TBD | 70 (0.7 × 100)  | TBD |

**Q sub-code breakdown (fill post-regression):**

| Q sub-code | force_clear_count | max pending_age_bars | Notes |
|---|---|---|---|
| 0 | TBD | TBD | |
| 1 | TBD | TBD | |
| 2 | TBD | TBD | |
| 3 | TBD | TBD | |

---

## 7. Pass Criterion

Per ADR-008 §Validation strategy:

| Outcome | Condition | Verdict | Next action |
|---|---|---|---|
| **PASS — baseline parity** | `force_clear_count == 0` per machine in 5-yr run | Safety net not triggered | No amendment needed |
| **PASS — safety net working** | `force_clear_count > 0` AND `pending_payload` inspection confirms force-clear cut a genuinely stuck pending (no valid trigger window present) | Safety net fired correctly | Document in §6; no amendment needed |
| **FAIL — Bucket A drift** | `force_clear_count > 0` AND payload inspection shows force-clear cut a valid trigger window | Threshold too low | Author ADR-008 amendment (use §9 template) + escalate via `/backtrack sd` if behavioral parity breached |
| **WARN — threshold proximity** | `force_clear_count == 0` BUT `max(pending_age_bars) > 70% threshold` for any machine | Safety margin thin | Author ADR-008 amendment to raise threshold preventively |

**Inspection method (payload analysis):**

```bash
# Inspect signal_context of each force-clear event to determine valid vs stuck
jq 'select(.event_type=="pending_force_clear") | {slot_id, pending_age_bars, pending_payload, signal_context}' \
  MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl | head -40
```

Compare `pending_payload.entry_conditions_met` and `signal_context.trigger_bars_remaining` against slot business logic (CodeWiki §2 per slot) to classify each event.

---

## 8. ADR-008 Amendment Template

> Skeleton only — do NOT append to ADR-008 unless §6 data warrants (FAIL or WARN verdict above).
> When data is available, copy this template to `docs/adr/008-pending-state-safety-force-clear.md § Spike Result` and fill in.

```markdown
## Spike Result (IMPL-068, YYYY-MM-DD)

**Verdict:** <KEEP_BASELINE | TUNE_M=<N> | TUNE_T=<N> | TUNE_Q=<N>>

Empirical 5-yr results (IMPL-062 Bucket A regression, journal run-*.jsonl):
- M: force_clear_count=<n>, max pending_age_bars=<n> (threshold=150, 70%=105)
- T: force_clear_count=<n>, max pending_age_bars=<n> (threshold=80, 70%=56)
- Q: force_clear_count=<n>, max pending_age_bars=<n> (threshold=100, 70%=70)

Q sub-code breakdown:
- code 0: count=<n>, max_bars=<n>
- code 1: count=<n>, max_bars=<n>
- code 2: count=<n>, max_bars=<n>
- code 3: count=<n>, max_bars=<n>

Decision: <preserve baseline | tune threshold based on max-bars >0.7× threshold rule>

Amendment (if tuning warranted):
- Old: InpForceClearM_Bars=150, InpForceClearT_Bars=80, InpForceClearQ_Bars=100
- New: InpForceClearM_Bars=<N>, InpForceClearT_Bars=<N>, InpForceClearQ_Bars=<N>
- Rationale: max observed pending_age_bars + 50% headroom per ADR-008 §Decision Option C note

Evidence artifact: docs/state/_session-handoff/IMPL-068-evidence-YYYYMMDD.md
Journal records reviewed: <count> total force_clear events sampled + classified
```

---

## 9. Operator Runbook

**Dependency chain (sequential):** IMPL-061 must close first (baseline parser + `docs/state/baseline-per-slot.json`) → IMPL-062 Bucket A 5-yr headless backtest runs (`terminal64.exe /config:simulation/headless-tests/impl-062-bucket-a.ini`) → journal records produced at `MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl` → run jq pipeline in §4 above (or PowerShell fallback §4b) → fill Result table in §6 → apply verdict logic from §7 → if amendment warranted, fill §8 template and append to ADR-008 `## Spike Result` section → commit ADR-008 amendment with `[fix:ea] ADR-008 threshold tune — IMPL-068 spike result` + evidence artifact at `docs/state/_session-handoff/IMPL-068-evidence-<YYYYMMDD>.md`.

**Note on `jq` availability:** `jq` is not installed on this system (confirmed 2026-05-04). Install via `choco install jq` (Chocolatey) or use PowerShell fallback in §4b. All filter logic validated via Python 3.11 equivalent (5/5 PASS, 2026-05-04).

---

## 10. Validation Evidence (IMPL-068 closure)

- **jq filter logic validation:** 5/5 PASS via Python 3.11 equivalent (jq absent on system; installed via choco if needed for operator runbook step)
- **Cross-link existence:** `docs/adr/008-pending-state-safety-force-clear.md` OK, `docs/api-specs/trade-journal-schema.yaml` OK
- **Section count:** 10 sections (Title/meta, Goal, Threshold table, Data source, jq pipeline, Q sub-code, Results table, Pass criterion, Amendment template, Operator runbook)
- **S-AC #1:** Pipeline + filter recipe + placeholder table committed (structural close) — numeric data deferred to IMPL-062/063 5-yr regression run
- **S-AC #2:** Amendment template skeleton included in §8 — not committed to ADR-008 unconditionally; filled only when §6 data warrants FAIL or WARN verdict
- **E-AC #1:** Deferred — `force_clear_count` per M/T/Q reported after IMPL-062/063 regression run
- **E-AC #2:** Deferred — ADR-008 amendment commit pending numeric verdict

---

## End of Document
