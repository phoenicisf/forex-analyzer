# NFR-2.2 Journal Write Latency — Measurement Report

> Owner: IMPL-066 · ADR-006 · Phase: P4 Verification
> Status: **Structural complete — E-ACs deferred to operator Tester run** (expiry 2026-05-19)
> Last updated: 2026-05-05

---

## §1 Purpose

Verify that `CTradeJournal::WriteEvent()` meets the NFR-2.2 latency budget:
- **avg ≤ 5 ms** per journal write event
- **p95 ≤ 5 ms** per journal write event
- Sample size **≥ 200 events** from a regression run

If any p95 overshoot occurs without avg breach → ADR-006 degrade-warn policy applies
(emit `journal_write_slow` Warn, continue trade flow, do NOT block OnTick).

---

## §2 Source Contract

Verbatim from `docs/ba/03-non-functional-requirements.md § NFR-2.2` (lines 156-167):

> | **Target** | ≤ **5 ms/tick** average + ≤ **10 ms/tick** at p95 |
> | **Measurement protocol** | (a) Instrumentation: timestamp รอบ journal write block. (b) Sample size: ≥ 200 events จาก regression run. (c) Aggregation: avg + p95. (d) Overshoot behavior: ถ้า journal write > 5ms ติดต่อกัน N ครั้งใน window M ticks → emit tagged warning ผ่าน FR-4.2 logger + continue trade flow (degrade-but-continue). |

Note: shared context §6.3 quotes the same passage. The target is `avg ≤ 5 ms` and `p95 ≤ 10 ms`
(NFR-2.2 literal). This report uses the stricter `avg + p95 ≤ 5 ms` pass criterion from
the IMPL-066 task ACs; the NFR-2.2 literal p95 budget of 10 ms is the absolute ceiling.

---

## §3 Instrumentation Summary

Added by IMPL-066 to `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`:

### 3.1 New private members

| Member | Type | Purpose |
|--------|------|---------|
| `m_latency_total_us` | `ulong` | Running sum of all elapsed_us values |
| `m_latency_max_us` | `ulong` | Running maximum elapsed_us |
| `m_latency_count` | `int` | Total write events sampled |
| `m_latency_samples[200]` | `ulong[]` | Ring buffer of last 200 elapsed_us (for p95) |
| `m_latency_samples_idx` | `int` | Next write position in ring |
| `m_latency_samples_filled` | `int` | Clamped to ≤ 200; denominator for p95 |
| `m_evtype_keys[16]` | `string[]` | Per-event-type linear-probe map keys |
| `m_evtype_counts[16]` | `int[]` | Per-event-type write count |
| `m_evtype_total_us[16]` | `ulong[]` | Per-event-type running sum us |
| `m_evtype_used` | `int` | Populated bucket count (≤ 16; bucket 15 = `_overflow`) |

### 3.2 Extended `TrackLatency(ulong elapsed_us, const string &event_type)`

Called from `WriteEvent()` immediately after `FileFlush()` (existing `GetMicrosecondCount()` measurement block retained verbatim). Additions:
- Increments `m_latency_count`, accumulates `m_latency_total_us`, updates `m_latency_max_us`.
- Appends to `m_latency_samples` ring (O(1) append).
- Updates per-event-type bucket via linear probe (O(16) worst-case; overflow → `_overflow`).
- Emits periodic `EmitLatencyReport()` call at every 1000th write.
- Preserves existing 10-event overshoot ring + `journal_write_slow` Warn logic (Finding 03.10).

### 3.3 `EmitLatencyReport()` — public method

**Trigger 1:** `m_latency_count % 1000 == 0` inside `TrackLatency()` (periodic checkpoint during long Tester runs).  
**Trigger 2:** `Close()` — called at OnDeinit; emits final session aggregate unconditionally if `m_latency_count > 0`.

**Logger output (per call):**
```
[system][ev=journal_latency_report] writes=N avg_us=A p95_us=P max_us=M
[system][ev=journal_latency_by_type] ev=<type> writes=N avg_us=A    (× m_evtype_used lines)
```

**Sidecar JSON path:**
```
MQL5/Files/PhoenicisNex/journal/<live|tester>/latency-report-YYYYMMDD-HHMMSS.json
```

**Sidecar JSON schema:**
```json
{
  "writes": <int>,
  "avg_us": <int>,
  "p95_us": <int>,
  "max_us": <int>,
  "sample_n": <int>,
  "by_event_type": [
    {"event_type": "<string>", "writes": <int>, "avg_us": <int>},
    ...
  ]
}
```

---

## §4 Verification Protocol

### Step 1 — Run a Tester session producing ≥ 200 journal events

Use any committed ini that generates ample write volume. `bootstrap_smoke.ini` (a few-hour
window on EURUSD H4 with all 21 slots active) routinely produces tens of thousands of events
per the Phase 4 Tier 1.5 walk-batch-2 evidence (overview TL;DR: 216,671 SlotS entry_signal
events alone). A 3-day window is sufficient.

Ensure foreground `terminal64.exe` is closed first (data-dir lock):

```powershell
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Stop-Process -Force
```

Then run:

```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/bootstrap_smoke.ini /tmp/nfr22_run.txt
```

### Step 2 — Parse Tester log for latency report lines

```bash
TODAY=$(date +"%Y%m%d")
TERMINAL_ID="A12EC900AF5AF5023ECB36F7FB72E396"
TESTER_LOG="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"

iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -E "journal_latency_report|journal_latency_by_type"
```

Expected output lines (example):
```
[system][ev=journal_latency_report] writes=1000 avg_us=320 p95_us=1800 max_us=9200
[system][ev=journal_latency_by_type] ev=entry writes=412 avg_us=290
[system][ev=journal_latency_by_type] ev=exit writes=388 avg_us=310
...
[system][ev=journal_latency_report] writes=2000 avg_us=318 p95_us=1750 max_us=9200
...
[system][ev=journal_latency_report] writes=N avg_us=A p95_us=P max_us=M  ← final at Close()
```

### Step 3 — Parse sidecar JSON

```bash
# Git Bash + jq
cat MQL5/Files/PhoenicisNex/journal/tester/latency-report-*.json | jq .

# PowerShell fallback (no jq)
Get-Content "MQL5\Files\PhoenicisNex\journal\tester\latency-report-*.json" | ConvertFrom-Json | Format-List
```

### Step 4 — Assert pass criteria

```bash
# From the final journal_latency_report log line or the last sidecar JSON:
AVG_US=<value from log/JSON>
P95_US=<value from log/JSON>

# Pass: both ≤ 5000 us (= 5 ms)
python3 -c "avg=$AVG_US; p95=$P95_US; print('PASS' if avg<=5000 and p95<=5000 else 'FAIL: avg='+str(avg/1000)+'ms p95='+str(p95/1000)+'ms')"
```

Also check for journal halt events (E-AC #2):

```bash
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -E "journal_halt|journal_write_fail_sustained"
# Pass: 0 lines (no sustained write failures)
```

---

## §5 Pass Criterion Matrix

| Outcome | Condition | Action |
|---------|-----------|--------|
| **PASS-baseline** | `avg_us ≤ 5000` AND `p95_us ≤ 5000` AND 0 `journal_halt` events | Close E-AC #1 + E-AC #2; mark IMPL-066 complete |
| **PASS-nfr-literal** | `avg_us ≤ 5000` AND `p95_us ≤ 10000` AND 0 `journal_halt` events | Meets NFR-2.2 literal budget; close E-ACs with WARN note in §6 Result table |
| **WARN-overshoot** | `avg_us ≤ 5000` AND `p95_us > 5000` (but ≤ 10000) | ADR-006 degrade-warn applies; emit `journal_write_slow`; do NOT block; document in §6 |
| **FAIL-avg** | `avg_us > 5000` | Escalate; review ADR-006 §performance-budget; consider async flush strategy |
| **FAIL-halt** | Any `[ev=journal_halt][reason=write_fail_sustained]` in log | CRITICAL — halt path triggered; investigate disk I/O / file handle exhaustion |

---

## §6 Result Table

> TBD — populated after operator Tester run (deferred E-AC expiry: 2026-05-19).

| Run date | ini file | writes | avg_us | p95_us | max_us | halt_events | Outcome |
|----------|----------|--------|--------|--------|--------|-------------|---------|
| _pending_ | — | — | — | — | — | — | — |

---

## §7 Cross-References

| Reference | Role |
|-----------|------|
| **NFR-2.2** | `docs/ba/03-non-functional-requirements.md § NFR-2.2` — source metric + target |
| **ADR-006** | `docs/adr/006-*.md` — journal append contract + degrade-warn policy + RPO escalation |
| **FR-4.1** | Journal write per trade event |
| **FR-4.3** | Journal write latency non-blocking contract |
| **IMPL-043** | TradeJournal service owner (BuildRecord, WriteEvent) |
| **IMPL-064** | `docs/state/nfr-3.1-atomic-write-result.md` — precedent report skeleton (deferred-numeric-run pattern) |
| **IMPL-068** | `docs/state/adr-008-force-clear-validation.md` — precedent for deferred E-AC pattern in P4 |
| **IMPL-066** | This task — instrumentation extension + report skeleton |

---

## §8 Operator Runbook (drain deferred E-ACs)

Three commands to close E-AC #1 (`[log-assertion]`) and E-AC #2 (`[db-inspect]`):

**Command 1 — Close foreground MT5 (data-dir lock prevention):**
```powershell
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Stop-Process -Force
```

**Command 2 — Run Tester ini producing ≥ 200 journal events:**
```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/bootstrap_smoke.ini /tmp/nfr22_run.txt
# Wait for ShutdownTerminal=1 auto-exit; then:
TODAY=$(date +"%Y%m%d")
TERMINAL_ID="A12EC900AF5AF5023ECB36F7FB72E396"
TESTER_LOG="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" | grep -E "journal_latency_report|journal_latency_by_type|journal_halt"
```

**Command 3 — Parse sidecar JSON and assert pass criteria:**
```bash
# Locate the latest sidecar
SIDECAR=$(ls -t MQL5/Files/PhoenicisNex/journal/tester/latency-report-*.json 2>/dev/null | head -1)
echo "Sidecar: $SIDECAR"

# jq assertion (pass = both avg_us and p95_us ≤ 5000)
cat "$SIDECAR" | jq '{avg_us, p95_us, writes, sample_n, pass_avg: (.avg_us <= 5000), pass_p95: (.p95_us <= 5000)}'

# PowerShell fallback:
# $r = Get-Content "MQL5\Files\PhoenicisNex\journal\tester\latency-report-*.json" | ConvertFrom-Json
# [PSCustomObject]@{avg_ms=$r.avg_us/1000; p95_ms=$r.p95_us/1000; pass=($r.avg_us -le 5000 -and $r.p95_us -le 5000)}
```

Record results in §6 Result table above; update `deferred-ac-registry.md` rows to Done; mark
`[x]` E-AC #1 + E-AC #2 in `docs/state/impl-plan.md` IMPL-066 entry.
