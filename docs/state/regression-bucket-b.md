# Bucket B Regression Report — IMPL-063

> **Status:** STRUCTURAL SKELETON — numeric tables pending operator 5-yr Tester run (E-AC #1/#2/#3 deferred; see §8).
> Authored: 2026-05-10 | Task: IMPL-063 | Phase: P4 Verification

---

## §1 — NFR-1.8 + G4 Verification Acceptance Criteria (verbatim)

**NFR-1.8 — Bucket B drift documented (no hard cap; user re-decide if > 25%)**

| Field | Value |
|-------|-------|
| **Metric** | ΔTotal Net Profit Bucket B = NetProfit(G4-ON) − NetProfit(G4-OFF) |
| **Reference** | IMPL-062 Bucket A run (G4-OFF; `regression_5yr_no_g4.ini`) |
| **Hard cap** | None — Bucket B captures *intentional* behavioral change from G4 fixes |
| **Soft trigger** | If \|ΔBucket B\| > 25% relative to Bucket A → user re-decide whether intentional drift is acceptable |
| **Bucket** | B — intentional behavioral change (G4 fixes IMPL-022 J-Magic + IMPL-039 BI-SL) |
| **Priority** | Must (NFR-1.8); informational fail criterion |
| **Goal trace** | G3 |
| **Why** | G4 fixes IMPL-022 + IMPL-039 are intentional bug fixes per BR-7.2 + ADR-009; baseline divergence expected; quantifying it gates user acceptance per CodeWiki §6.2 P2.x classification |

**G4 Fix #1 verification (BR-7.2 — Slot_J MAGIC_J fix)**

| Field | Value |
|-------|-------|
| **Metric** | Journal exit events with `slot_id=J AND magic=206` count |
| **Pre-fix behavior** | `ExtraTakeProfit_J` iterates `MagicF=201` (sibling MAGIC_F instead of own MAGIC_J=206) — `J` exit events misattributed |
| **Post-fix behavior** | `ExtraTakeProfit_J` iterates `MagicJ=206` — exit events correctly attributed |
| **Pass threshold** | journal `event_type=exit, slot_id=J, magic=206` count > 0 over 5-yr window |
| **Goal trace** | G3 + ADR-009 audit trail |

**G4 Fix #2 verification (ADR-009 — Slot_BI parent-anchored SL)**

| Field | Value |
|-------|-------|
| **Metric** | Journal entry events with `slot_id=BI AND sl != 0.0` count |
| **Pre-fix behavior** | BI orders open with `sl=0.0` (naked SL — broker default; no protection on pyramid child) |
| **Post-fix behavior** | BI orders open with parent-B-anchored SL distance (per ADR-009 Option A pip arithmetic via `CPipMath.InheritSlFromParent`) |
| **Pass threshold** | journal `event_type=entry, slot_id=BI, sl != 0.0` count > 0 over 5-yr window |
| **Goal trace** | G3 + ADR-009 audit trail |

---

## §2 — Verification Protocol

This regression measures **Bucket B drift** — *intentional* behavioral change between the
PhoenicisNex rewrite (G4 fixes ENABLED, default build) and the same rewrite with
G4 fixes DISABLED (IMPL-062 Bucket A baseline). Bucket B drift is the additional drift
attributable to the G4 fixes (IMPL-022 J-Magic + IMPL-039 BI-SL); Bucket A drift was the
unintentional rewrite-logic translation drift measured separately in IMPL-062.

By isolating Bucket A and Bucket B, the user can attribute deviation to its source:
- Bucket A > 25% → rewrite logic regression (must fix)
- Bucket B > 25% → G4 fix re-evaluation (user re-decide; Won't-fix or fold into spec)

**4-step protocol:**

1. **Build (default)** — verify `PhoenicisNex.mq5` has NO `#define DISABLE_G4_FIXES`
   (committed default = G4 fixes ON). Compile via MetaEditor → verify
   `Result: 0 errors, 0 warnings`. The default .ex5 IS the Bucket B build.

2. **Run** — execute `simulation/headless-tests/regression_5yr_g4.ini` via headless Strategy
   Tester (5-yr window 2021.01.01 – 2025.12.31, `Model=4`, `ShutdownTerminal=1`, `Visual=0`).
   Estimated wall-clock: 30–60 min (full tick model 5-yr EURUSD H4).

3. **Parse** — extract results from Strategy Tester HTML report (or Tester log) using
   `mt5-log-reader` SKILL:
   - Total Net Profit (portfolio level)
   - Profit Factor (PF)
   - Sharpe Ratio
   - Per-slot trade counts (from journal `journal/tester/run-*.jsonl` via jq)
   - **G4 Fix #1 evidence:** `event_type=exit, slot_id=J, magic=206` count
   - **G4 Fix #2 evidence:** `event_type=entry, slot_id=BI, sl != 0.0` count

4. **Compute** — calculate Bucket B drift as
   `(NetProfit_G4ON − NetProfit_G4OFF) / NetProfit_G4OFF * 100` and populate result tables
   in §4. Evaluate per §5; user re-decide if soft trigger fired.

---

## §3 — Reference Runs

| Run | Build | .ini | Source |
|-----|-------|------|--------|
| Bucket A (G4-OFF) | `#define DISABLE_G4_FIXES` build | `simulation/headless-tests/regression_5yr_no_g4.ini` | IMPL-062 (closed structural 2026-05-05; numeric drain pending operator session) |
| Bucket B (G4-ON, this run) | default build (no flag) | `simulation/headless-tests/regression_5yr_g4.ini` | IMPL-063 (this report) |
| Baseline | PhoenicisN2.10 stable | N/A — `ReportTester-25045474.html` | IMPL-061 extraction → `docs/state/baseline-per-slot.json` total=$24,271,276.63 |

**Paired-bundle execution:** the operator runs both `regression_5yr_no_g4.ini` and
`regression_5yr_g4.ini` in the same session (~60-120 min total wall-clock). The Bucket A
result feeds Bucket B as denominator. Both .ini files share the same window/model/deposit
parameters — the only difference is the compile-flag state of the .ex5 they consume.

---

## §4 — Result Tables (TBD post-execution)

> **All numeric cells below are `<TBD post-execution>`.** Operator fills after running
> `regression_5yr_g4.ini` (paired with IMPL-062 `regression_5yr_no_g4.ini` for delta).

### 4a — Portfolio-level Bucket B drift

| Metric | Bucket A (G4-OFF, IMPL-062) | Bucket B (G4-ON, this run) | Absolute Δ | Relative Δ% (Bucket B drift) |
|--------|------------------------------|-----------------------------|------------|-------------------------------|
| Total Net Profit ($) | `<TBD from IMPL-062>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Profit Factor | `<TBD from IMPL-062>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Sharpe Ratio | `<TBD from IMPL-062>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Total Trades | `<TBD from IMPL-062>` | `<TBD>` | `<TBD>` | `<TBD>` |
| Max Drawdown % | `<TBD from IMPL-062>` | `<TBD>` | `<TBD>` | `<TBD>` |

### 4b — Per-slot impact of G4 fixes (NFR-1.8 attribution)

Slots NOT touched by G4 fixes (19 of 21 slots) should show ~0 Bucket B drift in trade count.
Slots J + BI (2 of 21) carry the entire Bucket B signal.

| Slot | Bucket A Trades | Bucket B Trades | Δ Trades | Δ% | Note |
|------|-----------------|-----------------|----------|-----|------|
| C    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| D    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| F    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| **J** | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | **G4 Fix #1 — MAGIC_J=206 routing** |
| H    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| K    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| G    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| G2   | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| GO   | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| M    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| L    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| LX   | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| Q    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| R    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| I    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| P    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| T    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| S    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| B    | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | parent of BI; secondary signal |
| BR   | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | not touched by G4 |
| **BI** | `<TBD>` | `<TBD>` | `<TBD>` | `<TBD>` | **G4 Fix #2 — parent-anchored SL** |

### 4c — G4 Fix verification (E-AC #2 + #3)

| Fix | Verification jq filter | Expected | Actual | Pass? |
|-----|------------------------|----------|--------|-------|
| G4 Fix #1 (J-Magic, BR-7.2) | `jq 'select(.event_type=="exit" and .slot_id=="J" and .magic==206)' run-*.jsonl \| wc -l` | > 0 | `<TBD>` | `<TBD>` |
| G4 Fix #2 (BI-SL, ADR-009) | `jq 'select(.event_type=="entry" and .slot_id=="BI" and (.sl != 0.0))' run-*.jsonl \| wc -l` | > 0 | `<TBD>` | `<TBD>` |

---

## §5 — Pass Criterion Matrix

| # | Criterion | Source | Pass Threshold | Status |
|---|-----------|--------|----------------|--------|
| 1 | Bucket B drift documented | NFR-1.8 | Report §4a populated; no hard cap | `<TBD>` |
| 2 | Soft trigger: \|Bucket B drift\| ≤ 25% | NFR-1.8 informational | If exceeded → user re-decide whether intentional drift is acceptable | `<TBD>` |
| 3 | G4 Fix #1 verified — `slot_id=J magic=206` exit count > 0 | BR-7.2 + ADR-009 audit trail | journal evidence present | `<TBD>` |
| 4 | G4 Fix #2 verified — `slot_id=BI sl != 0.0` entry count > 0 | ADR-009 audit trail | journal evidence present | `<TBD>` |

**Overall IMPL-063 verdict:** `<TBD post-execution>` — PASS requires criteria #1 (drift documented), #3 (J-Magic), and #4 (BI-SL) all met. Criterion #2 is informational; failure triggers user re-decide flow but does not auto-fail the task.

---

## §6 — Cross-links

| Reference | Purpose |
|-----------|---------|
| NFR-1.8 (BA `03-non-functional-requirements.md` §NFR-1.8) | Bucket B drift documentation requirement |
| ADR-009 (`docs/adr/009-bi-sl-inheritance-pip-arithmetic.md`) | BI parent-anchored SL design — Fix #2 source |
| BR-7.2 (BA `04-business-rules.md` §BR-7.2) | Slot J MAGIC_J=206 routing — Fix #1 source |
| IMPL-022 (Slot_J G4 fix) | Source commit `d386ea6` — Fix #1 implementation |
| IMPL-039 (Slot_BI G4 fix) | Source commit (g4-fix-attestation.md row 2) — Fix #2 implementation |
| IMPL-062 (Bucket A regression) | Reference run providing Bucket A baseline (G4-OFF) |
| IMPL-061 baseline extraction | `docs/state/baseline-per-slot.json` — 21-slot ground truth |
| `simulation/headless-tests/regression_5yr_no_g4.ini` | Bucket A .ini (paired bundle) |
| `simulation/headless-tests/regression_5yr_g4.ini` | Bucket B .ini (this report consumes) |
| `docs/state/g4-fix-attestation.md` | G4 fix audit trail (IMPL-022 + IMPL-039 commit hashes) |

---

## §7 — Operator Runbook (~30–60 min, paired with IMPL-062)

> Prerequisite: MT5 terminal closed (data-dir lock); `origin.txt` present; Git Bash + jq available.
> **Recommended:** run paired with IMPL-062 in the same operator session — Bucket A run first
> (`regression_5yr_no_g4.ini`), then Bucket B run (`regression_5yr_g4.ini`), so the two .ex5
> builds are isolated by compile-flag toggle and Bucket B drift can be computed inline.

### Step 1 — Verify default build (no DISABLE_G4_FIXES flag)

```bash
grep -c "^[[:space:]]*#define[[:space:]]\+DISABLE_G4_FIXES" \
     MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5
# Expected: 0 (default committed state — G4 fixes ON)
```

If the IMPL-062 paired run inserted the flag, Step 8 of `regression-bucket-a.md` should
have removed it. If still present, remove it manually before proceeding.

### Step 2 — Compile default build

```bash
ORIGIN=$(cat origin.txt | tr -d '\r')
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
sleep 2
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.log" \
  | grep -E "Result:|error|warning" | tail -5
# Expected: Result: 0 errors, 0 warnings, NNNN ms elapsed
```

### Step 3 — Verify MT5 terminal is closed

```powershell
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle
# Must return empty — close any open terminal64.exe before proceeding
```

### Step 4 — Run headless 5-yr backtest (Bucket B)

```bash
TERMINAL=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/terminal64.exe
"$TERMINAL" /config:"$(pwd)/simulation/headless-tests/regression_5yr_g4.ini"
# Wall-clock: 30–60 min for 5-yr EURUSD H4 every-real-tick model
# Terminal auto-exits (ShutdownTerminal=1)
```

### Step 5 — Parse Tester log

```bash
TERMINAL_ID=$(basename "$(pwd)")
TODAY=$(date +"%Y%m%d")
TESTER_LOG="$HOME/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -nE "\[Phoenicis\]|\[ERROR\]|\[WARN\]|init_ok|halt|Net Profit|Profit Factor|Sharpe" \
  | tail -30
```

### Step 6 — Parse journal for per-slot trade counts + G4 verification

```bash
JOURNAL_DIR="MQL5/Files/PhoenicisNex/journal/tester"

# Per-slot entry count:
echo "=== Per-slot entry count ==="
jq -r 'select(.event_type=="entry") | .slot_id' "$JOURNAL_DIR"/run-*.jsonl \
  | sort | uniq -c | sort -rn

# G4 Fix #1 (BR-7.2 — J-Magic):
echo "=== G4 Fix #1: J exits with magic=206 ==="
jq 'select(.event_type=="exit" and .slot_id=="J" and .magic==206)' \
  "$JOURNAL_DIR"/run-*.jsonl | jq -s 'length'

# G4 Fix #2 (ADR-009 — BI parent-anchored SL):
echo "=== G4 Fix #2: BI entries with non-zero SL ==="
jq 'select(.event_type=="entry" and .slot_id=="BI" and (.sl != 0.0))' \
  "$JOURNAL_DIR"/run-*.jsonl | jq -s 'length'

# Sample BI entry to inspect SL value vs parent B (sanity):
echo "=== Sample BI entries (first 3) ==="
jq -c 'select(.event_type=="entry" and .slot_id=="BI") | {ticket_id, sl, signal_context, parent_ticket_id}' \
  "$JOURNAL_DIR"/run-*.jsonl | head -3
```

### Step 7 — Compute Bucket B drift + fill §4 tables

For Bucket B drift (relative to Bucket A IMPL-062 result):
```
Bucket_B_drift_pct = (NetProfit_G4ON - NetProfit_G4OFF) / NetProfit_G4OFF * 100
Documented (no hard cap): always; user re-decide if |Bucket_B_drift_pct| > 25%
```

For per-slot delta (4b):
```
Δ_count = Bucket_B_count - Bucket_A_count   (per slot)
Δ%      = Δ_count / Bucket_A_count * 100    (when Bucket_A_count >= 5)
Expected: ~0 for 19 of 21 slots; non-zero on J + BI (G4 fix scope)
```

### Step 8 — Document verdict + commit report

Update §4a/4b/4c numeric cells, §5 status column, §8 closure note. Commit:
```bash
git add docs/state/regression-bucket-b.md
git commit -m "[docs:ea-qa] IMPL-063 Bucket B drift drained — Net Profit \$<N> (Δ=<X>% vs Bucket A); G4 Fix #1 verified <Y> J exits, Fix #2 verified <Z> BI entries"
```

---

## §8 — Closure Note (Deferred E-ACs)

**Structural S-ACs closed (2026-05-10):**
- [x] S-AC #1: Default build has G4 fixes ON (committed `PhoenicisNex.mq5` contains no `#define DISABLE_G4_FIXES`; verified by grep). G4 fixes IMPL-022 (J MAGIC_J) + IMPL-039 (BI parent-SL via ADR-009) shipped in mainline.
- [x] S-AC #2: `simulation/headless-tests/regression_5yr_g4.ini` committed with standard `[Tester]` block (Model=4, 5-yr window 2021.01.01–2025.12.31, ShutdownTerminal=1, Visual=0) + operator runbook noting paired-bundle execution with IMPL-062.
- [x] S-AC #3: This report skeleton authored with 8 sections — Bucket B drift formula `(G4-ON − G4-OFF) / G4-OFF * 100` referencing IMPL-062 baseline; per-slot impact table flagging J + BI as G4-bearing slots; G4 Fix #1/#2 verification jq filters for E-AC drain.

**Deferred E-ACs (registered in `docs/state/deferred-ac-registry.md` by orchestrator):**
- [ ] E-AC #1: Bucket B drift documented (no hard cap); user re-decide if > 25% `[db-inspect]` — requires operator paired-bundle 5-yr Tester run.
- [ ] E-AC #2: G4 Fix #1 verified — journal `event_type=exit, slot_id=J, magic=206` count > 0 `[db-inspect]` — requires operator journal parse (jq filter §6).
- [ ] E-AC #3: G4 Fix #2 verified — journal `event_type=entry, slot_id=BI, sl != 0.0` count > 0 `[db-inspect]` — requires operator journal parse (jq filter §6).

**Risk-if-missed:** NFR-1.8 G4 acceptance signal not measured; cannot certify intentional G4 behavioral change is bounded; J-Magic + BI-SL fixes shipped without empirical journal-trace audit (defeats the purpose of g4-fix-attestation.md).
**Expiry:** 2026-05-24 (14d from 2026-05-10).
