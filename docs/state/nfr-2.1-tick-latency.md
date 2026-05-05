# NFR-2.1 Tick Latency Measurement Report

> Owner: IMPL-065
> Status: SKELETON — structural authoring complete; numeric fill pending operator session
> Last updated: 2026-05-05

---

## §1 NFR Verbatim

### NFR-2.1 — Tick latency overhead ≤ 10% vs original

| Field | Value |
|-------|-------|
| **Metric** | (Rewrite avg tick latency − Original avg tick latency) / Original avg tick latency |
| **Target** | ≤ **10%** average + ≤ **20%** at p95 + ≤ **30%** at p99 |
| **Priority** | Must |
| **Goal trace** | G1 (perf), G3 |
| **Why** | Slot abstraction + indicator snapshot + per-slot state lookup (FR-2.5/2.6/2.7) ใส่ indirection layer → เสี่ยง overhead; ขีดจำกัด 10% avg เพื่อให้ live tick ทันต่อ broker fill ใน volatile market (Hypothesis H2 ใน ideation-brief); p95/p99 ขีดจำกัดเพิ่มเพื่อกัน outlier hide ใน average |
| **Measurement protocol** | (a) Instrumentation: QA insert timestamp capture ที่ OnTick start + end ของทั้ง original EA และ rewrite. (b) Sample size: ≥ 5,000 ticks ต่อ run ของ regression period (2021-2025 EURUSD H4, 1-min OHLC tick model). (c) Aggregation: report avg + p95 + p99 ของ tick latency distribution ทั้งคู่. (d) Environment parity: วัดทั้งคู่บนเครื่องเดียวกัน (user's Windows machine), MT5 build เดียวกัน, no other CPU-heavy process. |
| **Verification** | QA Phase: ทำตาม Measurement protocol → คำนวณ deviation จาก aggregation → pass/fail ตาม Target |
| **Source** | ideation-brief Hypothesis H2; CodeWiki §7.2 |

### NFR-2.3 — Strategy Tester 5-yr run time

| Field | Value |
|-------|-------|
| **Metric** | Run time ของ 5-yr regression run (2021-2025 EURUSD H4) บนเครื่อง user (Windows) |
| **Target** | Run time ของ rewrite ≤ **1.5×** original (ภายใต้ default tester settings + 1-min OHLC tick model) |
| **Priority** | Should |
| **Goal trace** | G1 |
| **Why** | Slow backtest = user run sweep ไม่ไหว; cap เป็น Should (ไม่ใช่ Must) เพราะ FR-8.1 (300-bar cache) จะช่วย |
| **Verification** | QA Phase: เปรียบเทียบ Strategy Tester run time |
| **Source** | improvement-targets P2.1 |

---

## §2 Instrumentation Summary

### Implementation (`IMPL-065`)

The rewrite EA ships per-stage `GetMicrosecondCount()` instrumentation behind a compile-time opt-in flag:

```mql5
// PhoenicisNex.mq5 (measurement run only — remove before production commit)
#define ENABLE_TICK_LATENCY
#include "core/Orchestrator.mqh"
```

When `ENABLE_TICK_LATENCY` is defined:

1. `services/TickLatencyProbe.mqh` is compiled (new file, IMPL-065).
2. `COrchestrator` holds a value-typed `CTickLatencyProbe m_tick_probe` member (no heap allocation).
3. `m_tick_probe.Init(m_logger)` is called at OnInit INIT_SUCCEEDED time.
4. Each of the 8 timed stages in `OnTick` is bracketed by `StageStart(TLPROBE_STAGE_X)` / `StageEnd(TLPROBE_STAGE_X)` calls.
5. `CTickLatencyProbe::OnTickStart()` is called at the top of OnTick and emits `[ev=tick_latency_report]` every 1000 ticks.
6. `m_tick_probe.FinalEmit()` is called at `OnDeinit` before `_TeardownAll()`.

When `ENABLE_TICK_LATENCY` is NOT defined (default production build):

- The include directive is skipped.
- The member declaration is absent.
- Zero code is generated for any probe path. Overhead = zero.

### 8 Timed Stages

| Stage index | Stage name | OnTick step | Target µs |
|-------------|------------|-------------|-----------|
| 0 | `refresh` | Step 1 — `m_indicators.Refresh()` | ~200 µs |
| 1 | `ctx_build` | Step 2 — `m_ctx_builder.Build()` | ~50 µs |
| 2 | `portfolio` | Step 7 — `m_portfolio.Refresh()` | ~100 µs |
| 3 | `pending` | Step 8 — `m_pending.TickAll(ctx)` | — |
| 4 | `exit_pass` | Step 9 — `RunExitPass` + `RunForceCutloss` + `ExtraCheckFunction2` + `RunSafePort` + `RunOrderGroup2` + `RunCOverload` | — |
| 5 | `entry_pass` | Step 11 — `RunEntryPass` + `RunEOverload` (gated; timed even when skipped) | — |
| 6 | `monitor` | Step 12 — `m_monitor.Update()` | ~30 µs |
| 7 | `state_save` | Step 13 — `m_state.Save()` | ~800 µs |

### Ring Buffer Design (mirrors IMPL-066 idiom from `TradeJournal.mqh`)

- Per stage: `ulong m_samples[8][200]` ring + `m_total_us[8]` + `m_max_us[8]` + `m_count[8]` + `m_idx[8]`
- p95 / p99: insertion-sort on a local copy of the ring (≤ 200 elements; acceptable cost at emit time, NOT per tick)
- Emit format per stage line:
  ```
  stage=<name>     n=<count> avg=<N>us p95=<N>us p99=<N>us max=<N>us
  ```

---

## §3 Verification Protocol (4-Step)

### Step 1 — Build with flag

```bash
# Add to top of PhoenicisNex.mq5 (measurement run only — REMOVE before committing):
#define ENABLE_TICK_LATENCY
```

Then compile:
```bash
ORIGIN=$(cat origin.txt | tr -d '\r')
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
sleep 2
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" 2>/dev/null \
  | grep -E "Result:|error|warning" | tail -10
# Expect: Result: 0 errors, 0 warnings
```

### Step 2 — Run ≥5,000-tick window

Use the committed `bootstrap_smoke.ini` (or a dedicated 5-yr run ini) to collect ≥5,000 H4 ticks:

```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/bootstrap_smoke.ini /tmp/impl065_run.txt
```

The `bootstrap_smoke.ini` `[Tester]` block should cover a date range that yields ≥ 5,000 H4 ticks (≈ 5 years × 252 trading days × 6 H4 bars/day ≈ 7,560 ticks; 2021-2025 range sufficient).

### Step 3 — Parse `[ev=tick_latency_report]` lines

```bash
TODAY=$(date +"%Y%m%d")
TESTER_LOG="$HOME/AppData/Roaming/MetaQuotes/Tester/<TERMINAL_ID>/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep "tick_latency_report" | tail -30
```

Expected output pattern:
```
[Phoenicis][slot=system][ev=tick_latency_report] trigger=periodic_1000ticks ticks=1000
[Phoenicis][slot=system][ev=tick_latency_report]   stage=refresh       n=1000 avg=Nus p95=Nus p99=Nus max=Nus
...
[Phoenicis][slot=system][ev=tick_latency_report]   stage=state_save    n=1000 avg=Nus p95=Nus p99=Nus max=Nus
[Phoenicis][slot=system][ev=tick_latency_report] trigger=final_deinit ticks=NNNN
```

### Step 4 — Compute deviation + fill §5 table

1. Sum all 8 stage averages → **total avg tick latency (rewrite w/ probe OFF)**.
2. Run baseline original EA (`PhoenicisN2.10_stable.mq5`) with a `GetMicrosecondCount()` wrap for comparison (QA work; ≥5,000 ticks, same environment).
3. Compute: `overhead% = (rewrite_avg - original_avg) / original_avg × 100`.
4. Compare Strategy Tester wall-clock times (displayed in MT5 Tester window or Tester log `elapsed` line).
5. Fill §5 result table + §6 pass/fail matrix.

---

## §4 Pass Criterion Matrix

| Criterion | Threshold | Pass condition |
|-----------|-----------|----------------|
| NFR-2.1 avg overhead | ≤ 10% | `(rewrite_avg - original_avg) / original_avg ≤ 0.10` |
| NFR-2.1 p95 overhead | ≤ 20% | `(rewrite_p95 - original_p95) / original_p95 ≤ 0.20` |
| NFR-2.1 p99 overhead | ≤ 30% | `(rewrite_p99 - original_p99) / original_p99 ≤ 0.30` |
| NFR-2.3 Tester wall-clock | ≤ 1.5× original | `rewrite_run_seconds / original_run_seconds ≤ 1.50` |
| All stages sampled | ≥ 5,000 ticks | `n_total ≥ 5000` per tick_latency_report final_deinit |

Partial-pass rule: if avg passes but p95/p99 fails → **flag for investigation** (infrequent spike; does not auto-block delivery but MUST be noted in §8 closure note + Open Risks table).

---

## §5 Result Table — `<TBD post-execution>`

### Per-Stage Breakdown (fill after operator session)

| Stage | avg (µs) | p95 (µs) | p99 (µs) | max (µs) | n |
|-------|----------|----------|----------|----------|---|
| refresh | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| ctx_build | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| portfolio | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| pending | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| exit_pass | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| entry_pass | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| monitor | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| state_save | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> | \<TBD\> |
| **TOTAL** | \<TBD\> | — | — | — | \<TBD\> |

### Comparative Summary

| Metric | Original EA (µs) | Rewrite EA (µs) | Deviation | Pass? |
|--------|-----------------|-----------------|-----------|-------|
| avg tick latency | \<TBD\> | \<TBD\> | \<TBD\>% | \<TBD\> |
| p95 tick latency | \<TBD\> | \<TBD\> | \<TBD\>% | \<TBD\> |
| p99 tick latency | \<TBD\> | \<TBD\> | \<TBD\>% | \<TBD\> |
| Tester wall-clock (s) | \<TBD\> | \<TBD\> | \<TBD\>× | \<TBD\> |

---

## §6 Cross-References

- `docs/ba/03-non-functional-requirements.md` — NFR-2.1 (§ "Performance" group) + NFR-2.3
- `docs/state/impl-plan.md` — IMPL-065 task entry (P4 Verification)
- `MQL5/Experts/PhoenicisNex/services/TickLatencyProbe.mqh` — probe implementation
- `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh` — `#ifdef ENABLE_TICK_LATENCY` instrumentation blocks in OnTick + OnDeinit
- `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh` — IMPL-066 ring-buffer idiom (pattern source)
- `simulation/headless-tests/bootstrap_smoke.ini` — reference test ini for G3 run

---

## §7 Operator Runbook (~10–30 min)

> Pre-condition: MT5 installed, `origin.txt` correct, foreground terminal64.exe CLOSED.

1. **Add flag** — open `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` in MetaEditor; add `#define ENABLE_TICK_LATENCY` as the FIRST line before all `#include` directives.

2. **Compile (toggle build):**
   ```bash
   ORIGIN=$(cat origin.txt | tr -d '\r')
   METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
   "$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
   sleep 2
   iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" 2>/dev/null \
     | grep -E "Result:|error|warning" | tail -5
   ```
   Expect: `Result: 0 errors, 0 warnings`.

3. **Run headless backtest** (≥5,000 ticks):
   ```bash
   bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
        simulation/headless-tests/bootstrap_smoke.ini /tmp/impl065_run.txt
   ```
   Note the wall-clock start/end times for NFR-2.3 Tester ratio.

4. **Extract latency report:**
   ```bash
   iconv -f UTF-16LE -t UTF-8 "<TESTER_LOG_PATH>/$TODAY.log" \
     | grep "tick_latency_report" | tail -40
   ```

5. **Record original EA baseline** — run `PhoenicisN2.10_stable.mq5` with a temporary `GetMicrosecondCount()` wrap at OnTick start/end over same date range; record avg/p95/p99. Remove instrumentation after measurement (do NOT commit).

6. **Compute deviations** using §4 formulas; fill §5 result table.

7. **Remove flag** — delete `#define ENABLE_TICK_LATENCY` from `PhoenicisNex.mq5`; recompile (default build); verify `Result: 0 errors, 0 warnings`.

8. **Update §5 + §8** of this document with measured values; close E-ACs in `impl-plan.md` via orchestrator `/next` session.

---

## §8 Closure Note — `<TBD post-execution>`

> Fill after operator measurement session.

- Date of measurement: \<TBD\>
- MT5 build: \<TBD\>
- Sample count: \<TBD\> ticks
- NFR-2.1 verdict: \<PASS / FAIL / PARTIAL-PASS\>
- NFR-2.3 verdict: \<PASS / FAIL\>
- Anomalies / outliers: \<TBD\>
- Linked deferred-AC registry row: IMPL-065 row (expiry 2026-05-19)
