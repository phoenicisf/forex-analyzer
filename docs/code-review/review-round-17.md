# Code Review Round 17

| Field | Value |
|-------|-------|
| **Round** | 17 |
| **Target** | `all` — operator invoked `/impl-review all R09 mandatory`. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/` + `docs/state/` after fix-round-16 + 5 closures (IMPL-017, IMPL-066, IMPL-067, IMPL-062, IMPL-065). Working tree at session start: clean (`git status --porcelain` = 0). HEAD = `6239f3e`. |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) IMPL-062 `#ifdef DISABLE_G4_FIXES` toggle in `slots/Slot_J.mqh` + `slots/Slot_BI.mqh` correctness — Bucket A regression contract (NFR-1.1 / NFR-1.6); (b) IMPL-065 `services/TickLatencyProbe.mqh` + `core/Orchestrator.mqh` ENABLE_TICK_LATENCY instrumentation correctness (NFR-2.1); (c) IMPL-066 `services/TradeJournal.mqh` latency aggregates + sidecar JSON (NFR-2.2); (d) IMPL-067 10× DST .ini coverage + window symmetry (NFR-7.3); (e) IMPL-017 `optimize_sweep_FID.ini` schema (NFR-6.2); (f) Dim #11 Empirical AC Closure verification across 5 newly-closed tasks. Mandatory-R09 sweep also re-checked R16-fix surface for regression. |
| **Plan Staleness Sentinel** | 11 closures since R07 — TRIPPED (>10 threshold per `.claude/rules/workflow.md § Phase 5 Gate #4`); operator-invoked `/impl-review` honours the trigger. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **7** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Symbol whitelist intact; no new `WebRequest` / DLL / `#import`; sidecar `latency-report-<ISO>.json` writes via `FileOpen` only into MT5 sandbox `PhoenicisNex/journal/<live\|tester>/`; no credential exposure; `DISABLE_G4_FIXES` is build-flag only (cannot be reached via `[TesterInputs]` per regression_5yr_no_g4.ini operator runbook); no silent halt path introduced by tick latency probe (Logger.Info-only). |
| 2 | Business Logic Correctness | ⚠️ Findings | **17.1 HIGH** — Slot_J + Slot_BI Bucket A toggle leaks "G4 fix" log message text under `DISABLE_G4_FIXES`, which contaminates the journal/log-assertion contract used to verify which build produced a record. **17.2 HIGH** — Tick latency ENTRY stage probes `StageStart`/`StageEnd` unconditionally wrap the entry-pass `if(...)` guard, so when entry is gated (morning_block / HALTED / Monday-spread / holiday) the stage records ~near-zero µs samples and pollutes the avg / p95 / p99 used for NFR-2.1 acceptance. |
| 3 | Error Handling | ⚠️ Finding | **17.5 MEDIUM** — `CTradeJournal::EmitLatencyReport()` write-fail emits a `Warn` and continues, but the per-event-type linear-probe map silently relabels its 16th bucket to `"_overflow"` if events exceed the 16 distinct types — the 16th original event_type's prior counts are shadowed by the rename, and there is no warn / log entry surfacing the overflow. |
| 4 | Performance | ⚠️ Finding | **17.4 MEDIUM** — `CTradeJournal::EmitLatencyReport` runs `ArraySort` on a 200-element ring on every 1000th write (long Tester run = ~hundreds of times) PLUS writes a sidecar JSON file via FileOpen/FileWriteString/FileClose every emit. The sidecar I/O (uncached open + close) adds 1-3 ms per checkpoint at ~1 emit / 1000 writes — meaningful drag during dense entry-storm intervals; checkpoint cadence and sidecar redirection are not parameterised. |
| 5 | Over-Engineering | ✅ Pass | TickLatencyProbe is 8 stages × 200 samples + scalar aggregates (~13 KB resident); insertion-sort acceptable for 200 elements; per-event-type map intentionally bounded at 16 (matches the documented event_type set). No premature abstraction. |
| 6 | Cross-Service Consistency | ✅ Pass | Orchestrator wires probe AFTER `init_ok` (line 386) and routes `FinalEmit` BEFORE `_TeardownAll` destroys logger — order correct. TradeJournal final emit at `Close()` runs before `delete m_journal` — order correct. No new slot→slot inclusion; ADR-012 layering preserved. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **17.3 MEDIUM** — IMPL-067 DST 10× .ini set has no companion `<task>_smoke.ini` style PASS-criterion automation; `nfr-7.3-dst-regression.md` defines per-AC matrix but operator drains 10 runs by ad-hoc inspection. No grep recipe + jq filter committed for "datetime parse error" / "M2 lookup `ArraySetAsSeries` failure" / DST-relative `H4` boundary mis-bin invariants. |
| 8 | Architecture Compliance | ✅ Pass | TickLatencyProbe lives in `services/` per ADR-012 5-layer rule; `#include` chain through `Logger.mqh` only (no slot dep, no domain → service). DISABLE_G4_FIXES site choice (slots only) preserves the slot-as-strategy-logic abstraction; cross-slot coordinator + RiskManager untouched. |
| 9 | Technical Design Compliance | ⚠️ Finding | **17.6 LOW** — `services/TickLatencyProbe.mqh` defines stage names (`refresh, ctx_build, portfolio, pending, exit_pass, entry_pass, monitor, state_save`) outside the canonical 14-step OnTick taxonomy in TD-02 §7.2 (steps 3 logger boundary, 4 circuit breaker, 5 indicator runtime, 5b xslot SetHalted, 6 time gates, 10 holiday block, 13b journal sustained-fail, 14 HALTED transition are NOT timed) — silently excluded from "tick overhead" claim without TD-02 §7.2 citation. |
| 10 | Test Code Quality | ✅ Pass | All 10 DST .ini have explicit `Optimization=0`, `ShutdownTerminal=1`, `Visual=0`, `Model=4`. `regression_5yr_no_g4.ini` carries explicit operator runbook. `optimize_sweep_FID.ini` uses standard `||` 5-field sweep syntax. No regex/loop pathology. |
| 11 | Empirical AC Closure (R09 mandatory) | ⚠️ Finding | **17.7 LOW** — IMPL-062 + IMPL-065 + IMPL-066 + IMPL-067 paired E-AC bundles (4 paired bundles + 2 individual = 6 deferred-AC rows expiry 2026-05-19) all wait on the SAME operator session for resolution; no row has been pre-materialised with a structural-test artifact (e.g. probe-driven smoke .ini that compiles ENABLE_TICK_LATENCY + runs ≥1000 ticks + greps the report line) to drain even the *probe wiring contract* portion ahead of the operator window. Per Empirical Closure Discipline Glossary entry, structural tests can drain the *contract assertion* half of paired bundles. |

---

## Findings

### Finding 17.1: 🟠 HIGH — `DISABLE_G4_FIXES` Bucket A regression toggle leaks "G4 fix" wording into Slot_J + Slot_BI log messages even when the buggy pre-G4 path is selected — Bucket A journal records carry false attestation text contradicting the actual code path executed.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh`, Lines: 213-216 + 220
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh`, Lines: 226-235 (uses literal `"(G4 fix ADR-009)"` in `StringFormat` body)
- Service: ea
- Reference: IMPL-062 commit `277cdb2`; `docs/state/regression-bucket-a.md § 2 Verification Protocol`; `docs/api-specs/trade-journal-schema.yaml` event_type taxonomy

**Code:**
```mql5
// slots/Slot_J.mqh — DISABLE_G4_FIXES branch (line 180-184)
#ifdef DISABLE_G4_FIXES
   int n = port.GetTicketsForSlot(MAGIC_F, "J,", tickets);   // pre-G4 buggy behavior
#else
   int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);   // G4 fix BR-7.2
#endif

// ...later, line 213-216 (UNCONDITIONAL — runs in BOTH branches):
m_logger.Info("SlotJ", "exit_profit_gate", MAGIC_J,
              StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close (G4 fix BR-7.2)",
                           ticket, profit_pips, InpJTpProfitPips));
//                                                                       ^^^^^^^^^^^^^^^^^^^^^
//   "(G4 fix BR-7.2)" still emitted even when DISABLE_G4_FIXES is the active build.
//   Also: magic field hardcoded to MAGIC_J (=206) but tickets came from MAGIC_F (=201)
//         iteration in the buggy branch — log magic ≠ actual broker magic.
```

```mql5
// slots/Slot_BI.mqh — line 211-217 + 226-235
#ifdef DISABLE_G4_FIXES
      double sl_price      = 0.0;   // pre-G4 naked SL (Bucket A baseline)
#else
      double sl_price      = buy_signal ? _NormalizeBrokerPrice(...) : ...;
#endif
      // ...
      m_logger.Info("Slot_BI", buy_signal ? "entry_pyramid_buy" : "entry_pyramid_sell",
                    MAGIC_B,
                    StringFormat("parent_ticket=%I64u parent_profit_pips=%.1f "
                                 "dir=%s lot=%.2f bi_entry=%.5f sl=%.5f "
                                 "sl_distance_pip=%.1f %s comment=%s "
                                 "(G4 fix ADR-009)",   // ← unconditional even in pre-G4 build
                                 parent_ticket, profit_pips, ..., sl_price,
                                 sl_distance_pip, sl_inherit_tag, comment));
```

**Problem:**
The Bucket A regression contract (NFR-1.1) requires comparing `regression_5yr_no_g4.ini` output (DISABLE_G4_FIXES build) against the unmodified `PhoenicisN2.10` baseline; `IMPL-068` ADR-008 force-clear validation specifically grep-greps the `signal_context` / `comment` / Logger Info text via committed jq filters. Both Slot_J and Slot_BI emit a Logger Info milestone whose message body is hard-coded to claim "(G4 fix BR-7.2)" / "(G4 fix ADR-009)" — these strings remain even when the `#ifdef DISABLE_G4_FIXES` branch is active. Result: a Bucket A regression run produces journal lines + Tester log lines that **claim** G4 fixes were applied while actually executing the pre-G4 buggy path.

In Slot_J specifically, the message also passes `MAGIC_J` (=206) into the Logger `magic` field, but in the DISABLE_G4_FIXES branch the iterated tickets came from `MAGIC_F` (=201) — so the per-ticket loop body emits `[magic=206]` for tickets that actually live under `MAGIC_F`, scrambling the per-magic per-slot count audit that IMPL-061's `baseline-per-slot.json` parser uses for cross-validation against IMPL-062 output.

The `regression-bucket-a.md § 2 Verification Protocol` step 3 says "parse via mt5-log-reader SKILL → populate `docs/state/regression-bucket-a.md`" — that parse step grep / jq selects on event_type + slot_id; if downstream analysis ever uses message body text (e.g. `grep -c "G4 fix BR-7.2"` to audit "ran with fix on" vs "ran with fix off" automatically), the result will be uniformly non-zero and useless. The defect is silent because tests never run the DISABLE_G4_FIXES build automatically — only operator session does.

**Why This Matters:**
This is the kind of defect-class that scripted Phase Gates miss (CLAUDE.md §1 Tier 1.5 callout). The Bucket A regression IS the NFR-1.1 acceptance signal — false log attestation in the regression run undermines the audit trail that `g4-fix-attestation.md` + IMPL-068 force-clear validation rely on. R16 § 16.3 already showed the project's vulnerability to "wording state drift across compile-flag toggles" — this is a runtime-emitted instance of the same class.

**Suggested Fix:**
Two orthogonal fixes; both small:

```mql5
// slots/Slot_J.mqh — replace lines 213-216:
#ifdef DISABLE_G4_FIXES
   int magic_for_log = MAGIC_F;
   string g4_tag     = "(Bucket A — pre-G4 BR-7.2 path)";
#else
   int magic_for_log = MAGIC_J;
   string g4_tag     = "(G4 fix BR-7.2)";
#endif
   m_logger.Info("SlotJ", "exit_profit_gate", magic_for_log,
                 StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close %s",
                              ticket, profit_pips, InpJTpProfitPips, g4_tag));
```

```mql5
// slots/Slot_BI.mqh — replace literal "(G4 fix ADR-009)" in StringFormat at line 234:
#ifdef DISABLE_G4_FIXES
   string g4_tag = "(Bucket A — pre-G4 ADR-009 naked SL path)";
#else
   string g4_tag = "(G4 fix ADR-009)";
#endif
   m_logger.Info("Slot_BI", ..., StringFormat(... + " %s", ..., g4_tag));
```

After fix, re-grep `slots/Slot_J.mqh` + `slots/Slot_BI.mqh` for any remaining unconditional `"G4 fix"` literal inside an `m_logger.*` call site (Phase 5 Gate #9 broader-class regex per R14 strengthening).

---

### Finding 17.2: 🟠 HIGH — Tick latency `TLPROBE_STAGE_ENTRY` is timed unconditionally even when entry pass is gated by `morning_block` / `ShouldSkipEntryPass`, polluting the NFR-2.1 avg/p95/p99 with near-zero "skipped guard check" samples.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 656-666
- Service: ea (instrumentation)
- Reference: IMPL-065 commit `fd0c029`; NFR-2.1 (≤ 10% avg / ≤ 20% p95 / ≤ 30% p99 overhead); TD-02 §7.2 step 11 entry-pass gate

**Code:**
```mql5
// core/Orchestrator.mqh:655-666 — OnTick entry-pass stage
   // 11. ENTRY PASS (skip in HALTED, morning-window, or any time-block).
#ifdef ENABLE_TICK_LATENCY
   m_tick_probe.StageStart(TLPROBE_STAGE_ENTRY);          // ← starts ALWAYS
#endif
   if(!morning_block && !ShouldSkipEntryPass(ctx, monday_block, holiday_block))
     {
      RunEntryPass(ctx);
      m_xslot.RunEOverload(ctx);
     }
#ifdef ENABLE_TICK_LATENCY
   m_tick_probe.StageEnd(TLPROBE_STAGE_ENTRY);            // ← ends ALWAYS
#endif
```

```mql5
// services/TickLatencyProbe.mqh:119-132 — StageEnd accumulates UNCONDITIONALLY
void CTickLatencyProbe::StageEnd(const int stage)
  {
   if(stage < 0 || stage >= TLPROBE_STAGE_COUNT) return;
   if(m_t0[stage] == 0) return; // StageStart not called — skip
   ulong dt = GetMicrosecondCount() - m_t0[stage];
   m_t0[stage] = 0;
   m_total_us[stage] += dt;
   if(dt > m_max_us[stage]) m_max_us[stage] = dt;
   m_samples[stage][m_idx[stage] % TLPROBE_RING_SIZE] = dt;
   m_idx[stage]++;
   m_count[stage]++;
  }
```

**Problem:**
On EURUSD H4 over a 5-yr regression run, the morning_block + Monday spread + holiday gates skip the entry pass on a non-trivial fraction of ticks (operator's bootstrap_smoke walk-batch-2 captured ~64% log volume reduction because the entry pass is the dominant emitter). When entry is skipped, the stage timing window measures only the cost of the `if(!morning_block && !ShouldSkipEntryPass(...))` predicate — single-digit microseconds — and that sample lands in `m_samples[TLPROBE_STAGE_ENTRY]` alongside real "ran 21 slots × Evaluate" samples (~hundreds of µs).

The `EmitLatencyReport` then computes avg / p95 / p99 over a bimodal distribution: dirty-cheap "skipped" ticks at the bottom + real "ran entry" ticks at the top. NFR-2.1 acceptance criteria targets the OVERHEAD of running the entry pass, so the relevant sample population is "ticks where entry actually ran". Mixed samples will artificially deflate `avg_us` and `p95_us`, allowing an actually-overheaded entry pass to PASS the NFR-2.1 ≤ 10% avg threshold by virtue of the morning-block dilution. False-pass = dangerous.

Same issue applies in lesser degree to STAGE_EXIT (always runs per ADR-010 — OK), STAGE_SAVE (always runs — OK), STAGE_PORTFOLIO (always — OK). STAGE_ENTRY is the only one with a guard, but it's also the most expensive stage in the pipeline.

**Why This Matters:**
The whole point of IMPL-065 is to provide the empirical evidence for NFR-2.1 acceptance. A measurement instrument that conflates "stage ran" with "stage skipped" gives the wrong answer. The deferred-AC bundle (paired NFR-2.1 + NFR-2.3, expiry 2026-05-19) will drain on a flawed sample set; the operator drain artifact will be a false-pass.

**Suggested Fix:**
Either (a) gate the StageStart/StageEnd inside the entry-pass guard so only ran-entry samples accumulate, or (b) split into two stages `entry_pass_eval` (the if-block body) + `entry_pass_skip_check` (always); (a) is simpler:

```mql5
// core/Orchestrator.mqh:655-666 — fix:
   // 11. ENTRY PASS (skip in HALTED, morning-window, or any time-block).
   if(!morning_block && !ShouldSkipEntryPass(ctx, monday_block, holiday_block))
     {
#ifdef ENABLE_TICK_LATENCY
      m_tick_probe.StageStart(TLPROBE_STAGE_ENTRY);
#endif
      RunEntryPass(ctx);
      m_xslot.RunEOverload(ctx);
#ifdef ENABLE_TICK_LATENCY
      m_tick_probe.StageEnd(TLPROBE_STAGE_ENTRY);
#endif
     }
```

After fix, also amend `docs/state/nfr-2.1-tick-latency.md § 4 Verification protocol` with a note that "STAGE_ENTRY n may be < total tick count when morning-block / Monday-spread / holiday gates active — denominator for overhead-% is `m_count[TLPROBE_STAGE_ENTRY]`, not total OnTick invocations".

---

### Finding 17.3: 🟡 MEDIUM — IMPL-067 DST regression has 10 .ini files with no committed PASS-criterion grep / jq automation — operator drains by manual inspection of 10 separate Tester logs; reproducible E-AC verdict gate absent.

**Location:**
- Files: `simulation/headless-tests/dst_2021_mar.ini` through `dst_2025_oct.ini` (10 files)
- File: `docs/state/nfr-7.3-dst-regression.md` (commit `1a6aed6`)
- Reference: IMPL-067 deferred-AC row (1 E-AC); `.claude/rules/testing.md § G4 Log review`; ADR pattern from IMPL-064 atomic-write `parse_pass=N/parse_fail=N` JSON sidecar

**Code:**
```ini
; All 10 dst_*.ini files share the same body shape (verified):
[Tester]
Expert=PhoenicisNex\PhoenicisNex
Symbol=EURUSD
Period=H4
Model=4
FromDate=2021.03.25
ToDate=2021.03.31
Optimization=0
Deposit=1000
Leverage=500
ShutdownTerminal=1
Visual=0
```

**Problem:**
`nfr-7.3-dst-regression.md` defines a 10-row coverage matrix + per-AC expected behavior + PASS/FAIL matrix, but the operator drain workflow is "run each .ini, inspect each Tester log by eye, transcribe verdict into the markdown". Compare to IMPL-064 (atomic-write kill harness), which produces a machine-checkable `nfr-3.1-atomic-write-result.json` sidecar with `verdict=PASS|FAIL` driven by `parse_pass==N` arithmetic — that pattern is reproducible and CI-amenable.

For DST runs, the relevant invariants are testable:
- (a) Each Tester run completes (no `[ERROR]` outside expected fail-fast set)
- (b) journal record `timestamp_seconds` ↔ EET hour mapping crosses the DST boundary cleanly (no 03:00 EET line followed by another 03:00 EET line in spring; no missing 02:00 EET line in fall)
- (c) `m_time.IsMorningWakeup` activations align to broker-server EET 03:00, not GMT 00:00, on both sides of boundary

A single PowerShell or jq script taking the 10 Tester logs + 10 journal files + emitting `dst-regression-result.json` `{transition: "2021-03-28-mar", verdict: "PASS|FAIL", anomalies: [...]}` would close the operator-drain loop in ~5 min vs 30-60 min, and would land the Phase 5 Gate #9 post-fix grep concept on the DST drain workflow.

**Why This Matters:**
With the operator-session backlog already at 6 P4 deferred-AC rows expiring 2026-05-19, adding 10 manual-inspection runs to the queue increases the risk that the operator session runs out of time and the DST E-AC defaults to a hand-wave verdict rather than an audited one. The IMPL-064 atomic-write JSON sidecar precedent shows the project understands this pattern; IMPL-067 just didn't apply it.

**Suggested Fix:**
Add `simulation/scripts/dst_regression_drain.ps1` (parallel to `atomic_write_kill_100.ps1`) that:
1. Iterates `simulation/headless-tests/dst_*.ini`
2. For each: spawns terminal64.exe → waits for ShutdownTerminal exit → parses corresponding Tester log + journal record set → asserts (a)/(b)/(c) above → records per-transition verdict
3. Aggregates 10 verdicts into `docs/state/nfr-7.3-dst-regression-result.json` with overall PASS/FAIL boolean + anomaly list

Alternatively (lighter weight), commit a `jq`-only recipe `simulation/scripts/dst_check.jq` + a one-line bash invocation in `nfr-7.3-dst-regression.md § Verification Protocol`.

---

### Finding 17.4: 🟡 MEDIUM — `CTradeJournal::EmitLatencyReport` writes a sidecar JSON file via FileOpen/FileWriteString/FileClose every 1000 writes — adds 1-3 ms of disk-uncached I/O per checkpoint, drag is non-trivial during dense entry-storm intervals; cadence and emit destination not parameterised.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`, Lines: 562-563 (1000-write trigger), 613-662 (sidecar write block)
- Service: ea (journal)
- Reference: IMPL-066 commit `11bb2c7`; NFR-2.2 (write latency p95 ≤ 5 ms cap)

**Code:**
```mql5
// services/TradeJournal.mqh:561-563 — periodic checkpoint trigger
   //--- IMPL-066: periodic checkpoint every 1000 writes (trigger 1 of 2)
   if(m_latency_count % 1000 == 0)
      EmitLatencyReport();
```

```mql5
// services/TradeJournal.mqh:613-655 — sidecar JSON write
   //--- sidecar JSON report
   if(EnsureDirectories())
     {
      // ... build iso_tag, dir, path ...
      string path = dir + "/latency-report-" + iso_tag + ".json";
      // ... build JSON body ...
      int fh = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(fh != INVALID_HANDLE)
        {
         FileWriteString(fh, w.ToString());
         FileClose(fh);
        }
      ...
     }
```

**Problem:**
Three issues conflated:

1. **Self-defeating measurement:** `EmitLatencyReport` is called from inside `TrackLatency`, which itself runs inside `WriteEvent` (right after the just-measured `FileFlush`). A new `FileOpen` + `FileWriteString` + `FileClose` on a fresh path takes ~1-3 ms on Windows NTFS uncached. That cost is observed by the NEXT WriteEvent's elapsed_us measurement (because the journal handle is still held open and the new sidecar fh is opened in the same MT5 sandbox volume → potential cache flush). So the NFR-2.2 p95 measurement contaminates itself every 1000 writes.

2. **No cadence parameterisation:** `1000` is a literal; long Tester runs hit it ~hundreds of times. A 5-yr regression run with ~216k entry_signal events (per walk batch-2) would emit ~216 sidecar JSONs, all with timestamped filenames, accumulating in `journal/tester/`. No GC, no `_overflow` rollup; disk fills with checkpoint snapshots.

3. **`EnsureDirectories()` re-runs FolderCreate × 3 every emit:** `EnsureDirectories` loops `FolderCreate` on three paths; that's 3 syscalls per emit. NTFS short-circuits already-existing folders, but the syscall round-trip is non-zero (~50 µs each).

NFR-2.2 target is p95 ≤ 5 ms. Sidecar I/O at ~1-3 ms means the periodic checkpoint can self-promote a ~3.5 ms write into a ~6 ms latency violation roughly every 1000 events.

**Why This Matters:**
The instrument that measures NFR-2.2 acceptance has a measurement artifact roughly once per 1000 writes that pushes the measured-write into the warn / halt threshold zone. This is the same measurement-pollutes-measurement defect class as Finding 17.2 in tick latency. Operator drain will see periodic spikes that need narrative explanation.

**Suggested Fix:**
Three minimal changes:

```mql5
// services/TradeJournal.mqh — make cadence configurable + emit Logger only on periodic, sidecar only on Close:
#define JOURNAL_LATENCY_PERIODIC_LOGGER_EVERY 1000
#define JOURNAL_LATENCY_SIDECAR_ON_FINAL_ONLY  true  // periodic → Logger only

void CTradeJournal::TrackLatency(ulong elapsed_us, const string &event_type)
  {
   // ... aggregates ...
   if(m_latency_count % JOURNAL_LATENCY_PERIODIC_LOGGER_EVERY == 0)
      EmitLatencyReportLoggerOnly();   // new variant — no sidecar I/O
  }

void CTradeJournal::Close()
  {
   if(m_latency_count > 0)
      EmitLatencyReport();   // full emit (Logger + sidecar) at session end only
   ...
  }
```

Then `nfr-2.2-journal-latency.md § Verification Protocol` documents that p95 measurement is taken from the sidecar at Close (single emit, single artifact, no in-band I/O drag).

---

### Finding 17.5: 🟡 MEDIUM — `CTradeJournal` per-event-type linear-probe map silently relabels its 16th bucket to `"_overflow"` once 16 distinct event types appear — the 16th original event_type's accumulated counts get hidden behind the rename, and no Logger.Warn surfaces the overflow event to the operator.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`, Lines: 543-557
- Reference: IMPL-066 commit `11bb2c7`; `docs/api-specs/trade-journal-schema.yaml § event_type enum`

**Code:**
```mql5
// services/TradeJournal.mqh:543-557 — overflow handling in TrackLatency
   if(bucket < 0)
     {
      if(m_evtype_used < 16)
        {
         bucket = m_evtype_used;
         m_evtype_keys[bucket] = key;
         m_evtype_used++;
        }
      else
        {
         // overflow bucket: lump into "_overflow" (always at index 15 when full)
         bucket = 15;
         m_evtype_keys[15] = "_overflow";   // ← OVERWRITES whatever was at index 15
        }
     }
   m_evtype_counts[bucket]++;
   m_evtype_total_us[bucket] += elapsed_us;
```

**Problem:**
When the 17th distinct event_type appears, `m_evtype_keys[15]` is unconditionally rewritten to `"_overflow"` — but **the counts and totals previously accumulated under the 16th original event_type at index 15 are NOT reset**. They silently bleed into the `_overflow` bucket's accumulator, attributing one event_type's latency profile to a synthetic label.

Worse: there's no `m_logger.Warn("system", "journal_evtype_overflow", ...)` emit when this happens. Operator reads the per-event-type table in `latency-report-<ISO>.json` and sees an `_overflow` row with mixed-attribution counts but cannot tell which original event_type was eaten.

`trade-journal-schema.yaml` defines roughly 12 event_types in the canonical taxonomy (entry_signal, exit_profit_gate, entry_pyramid_buy, entry_pyramid_sell, halt, init_ok, force_clear_*, etc.). The bound of 16 is a buffer of 4 — easily exceedable when slot-specific event_types like `s_pct_tp_invalid` (Slot S R15-fixed), `journal_latency_report` (this very service), `tick_latency_report` (IMPL-065), `cd_demote_triggered`, `eoverload_triggered`, `coverload_triggered`, `goverload_triggered`, `safe_port_close`, `force_cutloss`, `order_group_2_close`, `extra_check_2_demote`, `pending_state_*`, etc. all hit production. 16 is tight.

**Why This Matters:**
Silent-bucket-rewrite + no Warn = quiet measurement loss. Phase 5 Gate enforcement (NFR-2.2) would observe correct totals (`writes` + `avg_us` + `p95_us`) but a misleading per-type breakdown. Operator drain artifact would land on the deferred-AC registry without anybody noticing the per-event-type attribution drifted.

**Suggested Fix:**
On overflow, (a) freeze the 16th bucket's slot rather than rename; (b) emit a one-time Warn:

```mql5
if(bucket < 0)
  {
   if(m_evtype_used < 15)   // ← reserve slot 15 for overflow, use 0..14 for unique
     {
      bucket = m_evtype_used;
      m_evtype_keys[bucket] = key;
      m_evtype_used++;
     }
   else
     {
      if(m_evtype_keys[15] != "_overflow" && m_logger != NULL)
        {
         m_logger.Warn("system", "journal_evtype_overflow", 0,
                       StringFormat("event_type=%s does not fit; using _overflow bucket. "
                                    "Bump JOURNAL_EVTYPE_BUCKETS or audit event_type taxonomy.",
                                    key));
         m_evtype_keys[15]      = "_overflow";
         m_evtype_counts[15]    = 0;   // reset — _overflow is its own bucket
         m_evtype_total_us[15]  = 0;
        }
      bucket = 15;
     }
  }
```

Bumping the buffer to 24 is also reasonable (4 + 16 KB extra resident).

---

### Finding 17.6: 🔵 LOW — `services/TickLatencyProbe.mqh` only times 8 of the 14 OnTick steps from TD-02 §7.2 — silently excludes step 3 (Logger.OnTickBoundary), step 4 (CircuitBreaker.CheckPingPong), step 5 (indicator runtime), step 5b (xslot.SetHalted), step 6 (TimeGate evaluations), step 10 (HolidayBlock), step 13b (journal sustained-fail), step 14 (HALTED transition) — without a TD-02 §7.2 citation justifying the exclusion.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TickLatencyProbe.mqh`, Lines: 30-46 (stage taxonomy)
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Lines: 564-708 (OnTick instrumented sites)
- Reference: TD-02 §7.2 lines 1493-1576 (14-step pipeline definition); NFR-2.1 (≤ 10% avg overhead — overhead of WHAT subset?)

**Code:**
```mql5
// services/TickLatencyProbe.mqh:30-39 — 8 stages
#define TLPROBE_STAGE_REFRESH   0   // step 1
#define TLPROBE_STAGE_CTX       1   // step 2
#define TLPROBE_STAGE_PORTFOLIO 2   // step 7
#define TLPROBE_STAGE_PENDING   3   // step 8
#define TLPROBE_STAGE_EXIT      4   // step 9
#define TLPROBE_STAGE_ENTRY     5   // step 11
#define TLPROBE_STAGE_MONITOR   6   // step 12
#define TLPROBE_STAGE_SAVE      7   // step 13
//                              steps 3, 4, 5, 5b, 6, 10, 13b, 14 = NOT timed
```

**Problem:**
NFR-2.1 talks about tick-overhead percentiles — but "tick overhead" needs a denominator (sum of all measured stages). The current 8-stage subset omits 6+ steps that have non-trivial cost: indicator runtime guard (step 5: `m_indicators.AnyHandleInvalid()` iterates 25+ handles), TimeGate evaluations (step 6: two boolean computations against tick_time + spread + day-of-week math), HolidayBlock (step 10: PortfolioState scan for active positions on-holiday), and the HALTED transition check (step 14: ea_state machine + Alert build).

The doc skeleton `nfr-2.1-tick-latency.md § 4 Verification Protocol` interpretation of "≤ 10% avg overhead" therefore measures only ~8/14 steps' overhead. Either:
(a) the omitted steps are truly negligible (assert it via stub stages that confirm < 10 µs each), or
(b) the NFR-2.1 verdict will be optimistic.

The stage taxonomy comment at lines 30-39 lists step numbers but doesn't justify the exclusions, and `nfr-2.1-tick-latency.md` doesn't reference TD-02 §7.2 to scope the measurement intent.

**Why This Matters:**
Same defect-class as 17.2 + 17.4 — measurement instrument scope quietly disagrees with the contract being measured. Lower severity because (a) the excluded steps are individually expected to be cheap, (b) the SAVE stage already dominates the overhead budget, (c) operator can split-bucket ad-hoc if needed. But the audit trail is thin.

**Suggested Fix:**
Either add 4 more stages (3=logger, 4=breaker, 5=handle, 6=time, 10=holiday, 13b=journal, 14=halt = 7 stages), OR add a citation block to `services/TickLatencyProbe.mqh` § header stating "Steps 3/4/5/5b/6/10/13b/14 omitted because individual cost < 10 µs per TD-02 §7.2 line 1500-1530 — see nfr-2.1-tick-latency.md § Scope". The latter is fine; the former is overkill.

---

### Finding 17.7: 🔵 LOW — IMPL-062 + IMPL-065 + IMPL-066 + IMPL-067 paired E-AC bundles all defer to the SAME 1 operator session without any structural-test artifact (e.g. probe-driven smoke .ini that compiles ENABLE_TICK_LATENCY + runs ≥1000 ticks + greps the report line) draining even the *probe wiring contract* portion ahead of operator time.

**Location:**
- Files: `docs/state/deferred-ac-registry.md` (Active table, P4 rows for IMPL-062/065/066/067)
- Reference: CLAUDE.md §7 Glossary "Empirical Closure Discipline" — "task ที่มี E-AC ปิดด้วย structural test pass อย่างเดียวไม่ได้ — ต้องมี evidence artifact"; but the converse applies — paired bundles can drain the *contract assertion* half via structural test now, leaving only the *acceptance metric* half for operator session

**Problem:**
Each of the 4 P4 closures landed identical "drain in operator session" deferred-AC rows. Some examples are perfectly correct (NFR-1.1 25% deviation requires real 5-yr Tester run; no shortcut). But others have a mechanical-contract half:

- **IMPL-065:** the contract that ENABLE_TICK_LATENCY *compiles* + emits 1+ `[ev=tick_latency_report]` line + the per-stage table parses as expected → that's verifiable via a `simulation/headless-tests/tick_latency_smoke.ini` with `Period=H4 Model=4 FromDate=...ToDate=2024.01.05 ShutdownTerminal=1` that just runs ~1000 ticks + grep `[Phoenicis][slot=system][ev=tick_latency_report]` ≥ 1 line. Author can drain it in 10 min today; only "actually meets ≤10% overhead vs default build" needs operator.

- **IMPL-066:** same idea — `journal_latency_smoke.ini` runs the journal write path ≥ 200 times → grep `[ev=journal_latency_report]` and parse the JSON sidecar. The "writes ≥ 200 → schema present" half is structural; the "p95 ≤ 5 ms" half is empirical.

- **IMPL-067:** structural half = "all 10 ini files produce a Tester log without `[ERROR]`" — runable headlessly for first 1-2 inis right now to validate the .ini schema. Empirical half = "DST boundary handling correct" needs a multi-hour walk.

- **IMPL-062:** structural half = "DISABLE_G4_FIXES build compiles" — already verified by G1; "produces a regression journal" half can be smoke-run on a 3-day window today (operator only needs the 5-yr window).

Compressing the operator drain backlog by half via structural drains today is cheap ROI.

**Why This Matters:**
6 P4 deferred-AC rows expiring 2026-05-19 share one operator-session bottleneck. If that session slips, all 6 hit final renewal expiry simultaneously. Pre-draining the structural halves leaves only the irreducible empirical halves — reducing the surface area at risk and giving the operator session a faster pass.

**Suggested Fix:**
Open `IMPL-FIX-003` "structural pre-drain of P4 paired bundles" and:
1. Author `simulation/headless-tests/tick_latency_smoke.ini` (3-day window, ENABLE_TICK_LATENCY) + commit; run G3 + grep `tick_latency_report` ≥ 1 line; mark structural half of IMPL-065 E-AC `[x]`.
2. Author `simulation/headless-tests/journal_latency_smoke.ini` (3-day window) + commit; run G3 + parse sidecar `latency-report-*.json`; mark structural half of IMPL-066 E-AC `[x]`.
3. For IMPL-067, run `dst_2024_mar.ini` headlessly today as a smoke test (operator can re-attest the other 9 in batch); mark "schema validated" half of IMPL-067 E-AC `[x]`.
4. Update `deferred-ac-registry.md` Active rows with "structurally pre-drained YYYY-MM-DD; empirical drain pending operator session".

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-17.1 | 🟡 MEDIUM | Measurement-pollutes-measurement: instrumentation that participates in the contract being measured | `services/TickLatencyProbe.mqh` (17.2 entry-pass dilution) + `services/TradeJournal.mqh::EmitLatencyReport` (17.4 sidecar I/O during write path) | Both new IMPL-065 + IMPL-066 instruments have a self-pollution path. Suggest a project-wide pattern: instrumentation *NEVER* invokes I/O on the hot-path; periodic = Logger only; sidecar = at Close/OnDeinit/FinalEmit only. |
| XS-17.2 | 🔵 LOW | Bucket A regression (DISABLE_G4_FIXES) message strings asymmetric — slot file ifdef toggles iteration semantic but not the human-readable attestation tag | `slots/Slot_J.mqh` + `slots/Slot_BI.mqh` (17.1) | Symptom of "compile-flag toggle changes only the minimum surface needed". Add a `.claude/rules/ea.md` §Compile-flag toggles best practice: "When `#ifdef X` toggles a code path, all log/journal text generated by that path SHOULD also branch on `#ifdef X`". |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 17.1 | DISABLE_G4_FIXES log text leak | 🟠 HIGH | `slots/Slot_J.mqh:213-216`, `slots/Slot_BI.mqh:226-235` | ea | XS (3 lines × 2 files) |
| 17.2 | TLPROBE_STAGE_ENTRY timed unconditionally | 🟠 HIGH | `core/Orchestrator.mqh:656-666` | ea | XS (move 4 #ifdef blocks inside if-block) |
| 17.3 | DST 10× .ini lacks committed PASS-criterion automation | 🟡 MEDIUM | `simulation/headless-tests/dst_*.ini` + `docs/state/nfr-7.3-dst-regression.md` | ea-qa | M (new ~150-LOC PowerShell drain script + JSON sidecar schema) |
| 17.4 | TradeJournal sidecar I/O on hot-path | 🟡 MEDIUM | `services/TradeJournal.mqh:561-563, 613-662` | ea | S (split EmitLatencyReportLoggerOnly + sidecar-at-Close) |
| 17.5 | TradeJournal evtype overflow silently rewrites bucket 15 | 🟡 MEDIUM | `services/TradeJournal.mqh:543-557` | ea | XS (reserve bucket 15 + emit one-time Warn) |
| 17.6 | TickLatencyProbe taxonomy excludes 6+ OnTick steps without TD-02 citation | 🔵 LOW | `services/TickLatencyProbe.mqh:30-46` + `core/Orchestrator.mqh` | ea | XS (header citation block OR add 4 more stages) |
| 17.7 | P4 paired E-AC bundles share single operator-session bottleneck without pre-drained structural half | 🔵 LOW | `docs/state/deferred-ac-registry.md` Active P4 rows | ea-qa | M (3 new .ini files + structural drain commits) |
| **Cross-Service Total** | | | | | |
| XS-17.1 | Measurement-pollutes-measurement instrumentation pattern | 🟡 MEDIUM | services/TickLatencyProbe.mqh + services/TradeJournal.mqh | ea | (covered by 17.2 + 17.4) |
| XS-17.2 | Compile-flag toggle log-text symmetry rule | 🔵 LOW | slots/Slot_J.mqh + slots/Slot_BI.mqh | ea | (covered by 17.1) |

**Recommendation:** Ready for **fix-round-17** — proceed with Findings 17.1 + 17.2 first (HIGH severity; both XS fixes; both block the IMPL-062 / IMPL-065 paired bundle drain integrity). Then 17.4 + 17.5 (MEDIUM, both small) to clean the journal latency instrument. 17.3 + 17.7 are deliverable improvements that reduce operator-session risk; treat as nice-to-have if fix-round capacity allows. 17.6 is documentation-only.

> **Reviewer note (Dim #11 R09 mandatory verdict):** The 5 most recent closures (IMPL-017, IMPL-066, IMPL-067, IMPL-062, IMPL-065) all completed structural ACs (`[x]`) with paired-bundle E-AC deferrals registered correctly in `deferred-ac-registry.md`. Forbidden patterns = 0 hits in `impl-plan.md`. Phase 5 Gate #1 holds. The repo-wide `deferred to IMPL-053+` intent grep finds hits ONLY in audit-history surfaces (review/fix-round narratives + registry rationale rows + handoff history) — these are all compliant with R16 § 9c "audit history preserved" exemption. Build integrity verified at HEAD = `6239f3e` per fix-round-16 closure. **No critical empirical-closure violations; the findings above are quality issues with the new instrumentation surfaces, not closure violations.**

## End of Review Round 17
