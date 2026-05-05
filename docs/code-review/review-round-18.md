# Code Review Round 18

| Field | Value |
|-------|-------|
| **Round** | 18 |
| **Target** | `all` — operator invoked `/impl-review all`. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` after fix-round-17 closure. HEAD = `44ae588`. Working tree at session start: clean (`git status --porcelain` = 0). |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) Post-fix-round-17 surface integrity on the 5 modified files (slots/Slot_J.mqh, slots/Slot_BI.mqh, core/Orchestrator.mqh, services/TradeJournal.mqh, services/TickLatencyProbe.mqh); (b) Repo-wide audit-trail sweep for next-coarser-granularity stale-forward-pointer pattern (R16 § 16.3/16.7 next-class recurrence check); (c) NFR-2.1 / NFR-2.2 instrument robustness re-verification after IMPL-065 / IMPL-066 closure; (d) Dim #11 Empirical AC Closure spot-check on fix-round-17 G2-G4 deferral rationale. |
| **Plan Staleness Sentinel** | 0 closures since R09 (R09 ran 2026-05-05; this is the immediate successor advisory after fix-round-17). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 3 |
| LOW      | 3 |
| **Total**| **7** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Symbol whitelist intact; no new `WebRequest` / DLL / `#import`; sidecar `latency-report-<ISO>.json` writes through `FileOpen` only into `MQL5/Files/PhoenicisNex/journal/<live\|tester>/`; `DISABLE_G4_FIXES` remains a build-flag (not reachable from `[TesterInputs]`). Logger.Warn on overflow does not leak credentials. |
| 2 | Business Logic Correctness | ✅ Pass | Slot_J post-fix branch selection (MAGIC_F under DISABLE_G4_FIXES, MAGIC_J otherwise) matches BR-7.2 baseline-vs-fix semantic; `magic_for_log` aligns with iterated tickets. Slot_BI post-fix attestation tag follows `#ifdef` correctly. `_PriceToPips` returns `MathAbs(price_diff)` so SL pip-distance computation handles BUY+SELL parents symmetrically (re-verified). |
| 3 | Error Handling | ⚠️ Finding | **18.4 LOW** — `EmitLatencyReport` sidecar `FileOpen` failure path emits `Logger.Warn("journal_latency_report_write_fail")` but does NOT bump the per-event-type bucket attribution; on transient FS failure the operator audit artifact is silently absent and the `m_latency_count` aggregate is identical between "sidecar landed" and "sidecar lost" — no journal record marks the gap. |
| 4 | Performance | ⚠️ Finding | **18.2 MEDIUM** — `CTickLatencyProbe::_EmitReport()` fires 1 + 8 = 9 `Logger.Info` calls (each a `Print()` + Logger file write) from inside `OnTickStart()` at every 1000th tick. Cumulative emit cost ≈ several hundred µs lands BEFORE STAGE_REFRESH starts, so it is invisible to the per-stage probe; but it inflates total OnTick wall-clock at periodic checkpoints — same measurement-pollutes-host pattern fix-round-17 § 17.4 just removed from TradeJournal. Cadence is hard-coded (literal `1000`). |
| 5 | Over-Engineering | ✅ Pass | Insertion-sort on 200-element ring acceptable; no premature abstraction in TickLatencyProbe header. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **18.3 MEDIUM** — TradeJournal header doc-block (line 8) + `m_evtype_keys[16]` field comment (line 83) still claim "max 16 buckets" / "(linear-probe, 16 buckets)" but fix-round-17 § 17.5 reduced *unique-event-type capacity* to 15 (bucket 15 reserved exclusively for `_overflow`). Header narrative drifts from runtime contract. |
| 7 | Test Coverage Gaps | ✅ Pass (advisory) | IMPL-FIX-003 (structural pre-drain of paired bundles) + IMPL-FIX-004 (DST PASS-criterion automation) carried forward from R17 deferral; not regressions, not re-raised here. |
| 8 | Architecture Compliance | ✅ Pass | TickLatencyProbe stays in `services/` per ADR-012; Orchestrator probe placement (inside entry-pass guard) preserves measurement scope. No new slot→slot includes; ADR-012 layering preserved. |
| 9 | Technical Design Compliance | ✅ Pass | TickLatencyProbe header now enumerates 8 timed + 6 omitted steps with per-step rationale (R17 § 17.6 closure). |
| 10 | Test Code Quality | ✅ Pass | No regex / loop pathology in fix-round-17 surfaces. |
| 11 | Empirical AC Closure | ⚠️ Finding | **18.5 MEDIUM** — fix-round-17 deferred G2-G4 with rationale "no production-runtime change to slot business logic (only attestation-tag branching + probe placement)". Probe-placement change in `core/Orchestrator.mqh:655-672` (TLPROBE_STAGE_ENTRY moved INSIDE entry-gate) IS a runtime control-flow change visible at compile-time only when `ENABLE_TICK_LATENCY` is defined — but the production-build behaviour is unaffected (matches deferral claim). However, no `[probe]` evidence artifact yet shows `#define ENABLE_TICK_LATENCY 1` + recompile + `[ev=tick_latency_report]` sample with `n` ≈ ran-entry-tick-count ≪ total-tick-count (the regression invariant being tested by Finding 17.2 fix). G3 deferral risks shipping a measurement instrument the project has never exercised post-fix. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface; Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1 callout. Walk batch-2 (2026-05-05) covered the bootstrap_smoke + atomic-write surfaces; the IMPL-062/065/066 instrumentation surfaces will land in walk batch-3. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer. Per `.claude/rules/testing.md § Per-Service-Kind Prove-It Evidence Table` `[config-audit]` row marked n/a. |

---

## Findings

### Finding 18.1: 🟠 HIGH — Repo-wide stale forward-pointer comments referencing CLOSED tasks (IMPL-053+, IMPL-017, IMPL-062, IMPL-053..060) — 100 occurrences across 45 source files in `MQL5/Experts/PhoenicisNex/`. Same defect class as R16 § 16.3/16.7 ("deferred to IMPL-053+"); R16-fix sweep narrowed to the literal phrase pattern and missed the next-coarser variant ("wires at IMPL-NNN").

**Location:**
- 100 hits across 45 files; representative sites:
  - `slots/Slot_J.mqh:137,152,229` — `// CD-follower sub-call wires at IMPL-017 / IMPL-062`
  - `slots/Slot_BI.mqh:276` — `//--- Phase-1 stub: logger-only milestone; broker close wires at IMPL-017 / IMPL-062 per ea.md.`
  - `slots/Slot_F.mqh:128,136,152` + `slots/Slot_GO.mqh:111,119,132` + `slots/Slot_I.mqh:289,352` + `slots/Slot_LX.mqh:190,229` + `slots/Slot_BR.mqh:125,133,147` + `slots/Slot_G2.mqh:246,261` + `slots/Slot_B.mqh:209,267` + `slots/Slot_C.mqh:276` + `slots/Slot_G.mqh:88,293,297` + `slots/Slot_H.mqh:144,165,241` + `slots/Slot_K/L/P/Q/R/S/T/M.mqh` (residual)
  - `services/PortfolioState.mqh:176,278,315,380` — `// Finding 02.3 — populated by OnTradeTransaction at IMPL-053+`
  - `services/RiskManager.mqh:15,295,353` — `// OnTradeTransaction handler at IMPL-053+ wiring. Until then …`
  - `domain/SlotState.mqh:38` — `// Populated by PortfolioState OnTradeTransaction handler at IMPL-053+.`
- Service: ea (cross-cutting; 8 services + 14 slots + 2 domain types + spike tree)
- Reference: `.claude/rules/workflow.md § Phase 5 Closure mechanical gates Gate #9 clause (b)/(c)` (broader-class repo-wide intent grep — added by R14 + strengthened by R16); `docs/code-review/review-round-16.md § 16.3 / § 16.7`; impl-plan.md TL;DR confirming IMPL-053..060 + IMPL-017 + IMPL-062 ALL CLOSED 2026-05-04/2026-05-05

**Code:**
```mql5
// slots/Slot_J.mqh:135-137 — comment claims wiring lands in IMPL-017/IMPL-062
   //--- Phase-1 stub: no entry signal in main topo —
   //    CD-follower sub-call wires at IMPL-017 / IMPL-062
   //    (cross-slot coupling per ea.md) via CrossSlotCoordinator.

// slots/Slot_J.mqh:148-152
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator wires CD→J (IMPL-017 / IMPL-062) */)
     {
      //--- Stub: J activation from CD-entry event
      //    wires at IMPL-017 / IMPL-062 (cross-slot coupling per ea.md).
     }

// slots/Slot_BI.mqh:276
            //--- Phase-1 stub: logger-only milestone; broker close wires at IMPL-017 / IMPL-062 per ea.md.

// services/RiskManager.mqh:15
//|   OnTradeTransaction handler at IMPL-053+ wiring. Until then     |

// services/PortfolioState.mqh:176
      s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at IMPL-053+
```

**Problem:**
Per `docs/state/impl-plan.md` TL;DR (lines 5-9), **all of IMPL-053, IMPL-054, IMPL-055, IMPL-056, IMPL-057, IMPL-058, IMPL-059, IMPL-060, IMPL-017, and IMPL-062 are CLOSED** (commits `277cdb2`, `fd0c029`, `1bf81c1`, `1a6aed6`, `11bb2c7`, `1165137`, `41ffdd6`, `2b27a2e`, plus the 2026-05-04 cross-slot quartet). None of those closures landed the wirings the comments promise:

- "CD-follower sub-call wires at IMPL-017" → IMPL-017 was Strategy Tester optimization compat (`optimize_sweep_FID.ini` + 170-LOC report); did NOT touch CrossSlotCoordinator.
- "wires at IMPL-062" → IMPL-062 was Bucket A regression authoring (`#ifdef DISABLE_G4_FIXES` guards + `regression_5yr_no_g4.ini` + report skeleton); did NOT wire broker close from slots, did NOT add CD→J cross-slot coupling.
- "OnTradeTransaction handler at IMPL-053+" → IMPL-053..057 implemented `RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2` + overload helpers; none added an `OnTradeTransaction` handler in PortfolioState.
- "broker close wires at IMPL-017 / IMPL-062 per ea.md" — same: neither task wired `RiskManager::CloseOrder` from slot exit paths.

The comments are now strictly **misleading audit signals**: a future engineer (or `/impl-task` planner, or `/next` reader) following the breadcrumb to IMPL-017 / IMPL-062 / IMPL-053+ finds those tasks closed without the promised work, leaving the reader to spelunk the impl-plan to discover the wirings were either deferred forever or routed to a different task that the comment doesn't cite. `services/PortfolioState.mqh:176` `s.last_open_lot = 0.0` zero-initialises a field the comment says "populated by OnTradeTransaction at IMPL-053+" — but no `OnTradeTransaction` handler exists post-IMPL-060 (only `COrchestrator::OnTradeTransaction` per fix-round-10 § 10.3 cascade plan, NOT a `PortfolioState::OnTradeTransaction`). The pointer is structurally false.

This is the **next-coarser-granularity instance** of the recurrence chain `R12 (12.6/12.8) → R13 (13.2 HIGH) → R14 (14.b clause-broader) → R16 (16.3/16.7 repo-wide)`. R16 § 16.3 fix sweep used the literal pattern `"deferred to IMPL-053+"` (and variants); the next-coarser variant `"wires at IMPL-NNN"` / `"at IMPL-053+"` / `"populated by ... at IMPL-053+"` was not in the regex. Phase 5 Gate #9 clause (c) explicitly anticipates this class: "the originating grep is scope-narrower than the defect class" — and forces the engineer to verify against the **defect class**, not just the literal pattern from cited sites. R18 catches the missed variant.

**Why This Matters:**
The audit-trail integrity claim of `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` rests on engineers being able to trust that "deferred to <task>" / "wires at <task>" comments point to the task that actually carries the outstanding work. When the named task closes without delivering, the comment silently transitions from "TODO marker" to "lie". 100 instances across 45 files compound into systemic noise: any future review-round dimension #11 sweep that follows these breadcrumbs hits dead ends.

Critically, the same root cause already produced `R16 § 16.1 CRITICAL` (build-integrity HEAD vs working tree drift): when audit-trail comments diverge from runtime reality, the engineer eventually trusts the comment over the code. This is precisely the chain Gate #9 clause (c) was added to break.

**Suggested Fix:**
Mass-rewrite via two-step sweep:

```bash
# Step 1 — identify all stale references (broader-class regex per Gate #9c):
grep -rcnE "(wires? at IMPL-(017|053|062|053\+))|(at IMPL-053\+)|(populated by .* at IMPL-)" MQL5/Experts/PhoenicisNex/

# Step 2 — for each hit, route to the correct currently-pending task:
#   - "wires at IMPL-017 / IMPL-062" (cross-slot RiskManager::OpenOrder/CloseOrder) → "wires at IMPL-063 (Bucket B regression) OR deferred to operator-runtime per deferred-ac-registry.md row IMPL-063-broker-close"
#   - "OnTradeTransaction handler at IMPL-053+" → if handler now exists in COrchestrator, point to that file:line; if still TODO, register a Pending row in operator-action-registry.md and cite it
#   - "populated by ... at IMPL-053+" (PortfolioState last_open_lot) → grep for actual writer; if no writer exists, add "TODO: writer not yet implemented; tracked as IMPL-NEW-NNN" with concrete Pending row reference
```

After sweep, run repo-wide post-fix verification per Gate #9 clause (c):

```bash
# Must return 0 hits (all stale references rewritten or annotated as audit history):
grep -rcnE "wires? at IMPL-(017|053|062|053\+)|populated by .* at IMPL-053\+" .
```

Also extend `.claude/rules/workflow.md § Phase 5 Closure mechanical gates Gate #9` clause (c) regex catalog with the new variant patterns so future closures don't reintroduce them.

**Level of Effort:** Medium (mechanical sweep + per-site routing decision; ~2-3 hours wall-clock for 100 sites; no compile risk if comments-only).

---

### Finding 18.2: 🟡 MEDIUM — `CTickLatencyProbe::_EmitReport()` emits 9 `Logger.Info` calls from inside `OnTickStart()` at every 1000th tick — measurement-pollutes-host repeat of the exact pattern fix-round-17 § 17.4 (XS-17.1) just removed from TradeJournal sidecar I/O. Cadence is hard-coded.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TickLatencyProbe.mqh`, Lines: 116-121 (`OnTickStart` → `_EmitReport`); 177-207 (`_EmitReport` body emits 1 header + 8 stage Logger.Info calls)
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Line: 568 (`m_tick_probe.OnTickStart()` invoked at OnTick entry)
- Service: ea (instrumentation)
- Reference: NFR-2.1 (≤ 10% avg / ≤ 20% p95 / ≤ 30% p99 OnTick overhead); fix-round-17 § XS-17.1 cross-service rule "instrumentation NEVER invokes I/O on the hot-path; periodic = Logger only; sidecar = at Close/OnDeinit/FinalEmit only"

**Code:**
```mql5
// services/TickLatencyProbe.mqh:116-121 — OnTickStart calls _EmitReport every 1000 ticks
void CTickLatencyProbe::OnTickStart()
  {
   m_tick_count++;
   if(m_tick_count % 1000 == 0)
      _EmitReport("periodic_1000ticks");   // ← 9 Logger.Info calls inline
  }

// services/TickLatencyProbe.mqh:177-206 — _EmitReport body
void CTickLatencyProbe::_EmitReport(const string trigger)
  {
   if(m_logger == NULL) return;
   // Header line — 1 Logger.Info call
   m_logger.Info("system", "tick_latency_report", 0,
                 StringFormat("trigger=%s ticks=%d", trigger, m_tick_count));
   // Per-stage lines — 8 Logger.Info calls
   for(int s = 0; s < TLPROBE_STAGE_COUNT; s++)
     {
      // ... avg/p95/p99/max compute (insertion-sort 200 elements) ...
      m_logger.Info("system", "tick_latency_report", 0, StringFormat(...));
     }
  }
```

**Problem:**
fix-round-17 § XS-17.1 ruled "instrumentation NEVER invokes I/O on the hot-path; periodic = Logger only" and applied that rule to TradeJournal (gating sidecar to Close-only). The same rule applies here, but R17 only audited TradeJournal — TickLatencyProbe was missed because R17 § 17.2 looked at the per-stage probe wrapper, not the periodic emit cadence.

The 9 `Logger.Info` calls each route to `Print()` + Logger file write (per `services/Logger.mqh` write path). On Windows MT5, even a buffered `Print()` line is ~10-50 µs; 9 calls × ~30 µs ≈ 270 µs per emit. Critically, all 9 fire BEFORE `m_tick_probe.StageStart(TLPROBE_STAGE_REFRESH)` runs — so the per-stage probe scope misses them — but the OPERATOR's NFR-2.1 acceptance compares "instrumented build's total OnTick wall-clock" vs "default build's total OnTick wall-clock" (per `nfr-2.1-tick-latency.md § Verification Protocol` which times the whole tick). The periodic emit shows up as a 270-µs spike every 1000 ticks in the overhead-vs-default delta, which the per-stage breakdown doesn't explain. Operator drain artifact will see periodic micro-spikes that need narrative justification — the same defect class fix-round-17 § 17.4 just neutralised on TradeJournal.

Additionally:
- **Cadence is hard-coded** (literal `1000` at line 119) — cannot be tuned for short tester runs (≤ 1000 ticks emit nothing) or for production (where periodic emit at 1000-tick cadence might dominate Experts log volume on slow EURUSD H4 bars).
- **Insertion-sort runs 8× per emit** (one per stage), each over up to 200 elements. ~800 element comparisons × 8 stages = ~6.4k ops, ≈ 30-50 µs additional.
- **Final emit gates correctly** (line 209 `FinalEmit` called from `_TeardownAll` per Orchestrator.mqh:548-552), but periodic emit shares the heavy machinery.

**Why This Matters:**
The instrument that measures NFR-2.1 acceptance has a measurement artifact every 1000 ticks that pushes total OnTick wall-clock above the per-stage sum. Same class as Finding 17.2 (entry-pass dilution) + 17.4 (sidecar I/O on hot-path) the project just rejected. Three instances of the pattern in two services in two consecutive review rounds = systemic — warrants the project-wide rule documented in fix-round-17 § XS-17.1 to be **enforced via a mechanical gate** (e.g., grep for `Logger.Info` / `FileWrite` / `FileOpen` inside any `services/*Probe*.mqh` / `services/*Latency*.mqh` periodic emit path).

**Suggested Fix:**
Two minimal changes (parallel structure to fix-round-17 § 17.4):

```mql5
// services/TickLatencyProbe.mqh — split periodic vs final emit:

#define TLPROBE_PERIODIC_EVERY 1000   // tunable; was inline literal

void CTickLatencyProbe::OnTickStart()
  {
   m_tick_count++;
   // Periodic emit — defer to FinalEmit-style aggregate at OnDeinit
   // OR emit a 1-line summary (not 9) to honour XS-17.1 hot-path rule.
   if(m_tick_count % TLPROBE_PERIODIC_EVERY == 0 && m_logger != NULL)
      _EmitOneLineSummary("periodic_1000ticks");   // single Logger.Info — header only
  }

// New private method — single-line periodic emit (no per-stage detail loop)
void CTickLatencyProbe::_EmitOneLineSummary(const string trigger)
  {
   m_logger.Info("system", "tick_latency_periodic", 0,
                 StringFormat("trigger=%s ticks=%d (per-stage detail at OnDeinit)", trigger, m_tick_count));
  }

// FinalEmit unchanged — full per-stage report at session end only
```

Then update `nfr-2.1-tick-latency.md § Verification Protocol`:
- Operator captures total OnTick wall-clock from FinalEmit-only artifact (no periodic 1000-tick spikes to subtract).
- TLPROBE_PERIODIC_EVERY tunable for short tester runs (cf. `journal_latency_smoke.ini` precedent in IMPL-FIX-003).

**Level of Effort:** Low (≈ 30 LOC diff in TickLatencyProbe.mqh + 5-line note in nfr-2.1-tick-latency.md).

---

### Finding 18.3: 🟡 MEDIUM — `services/TradeJournal.mqh` header doc-block (line 8) + `m_evtype_keys[16]` field comment (line 83) advertise "max 16 buckets" / "(linear-probe, 16 buckets)" but fix-round-17 § 17.5 reduced unique-event-type tracking capacity to 15 (bucket 15 reserved for `_overflow`). Header narrative drifts from runtime contract — same audit-trail-integrity class as Finding 18.1.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
  - Line 7-8 (file-level header): `Adds ≥200-sample ring buffer, running aggregates, per-event-type | breakdown map (linear-probe, 16 buckets), EmitLatencyReport()`
  - Line 83 (field comment): `//--- IMPL-066: per-event-type breakdown (linear-probe map, max 16 buckets)`
  - Line 533 (TrackLatency comment): `//--- per-event-type linear-probe map (max 16 buckets; overflow → "_overflow")`
- Service: ea (journal)
- Reference: fix-round-17 § 17.5 fix narrative ("(a) reserves bucket 15 exclusively for `_overflow` (unique event_types fill 0..14 only — capacity reduced from 16 → 15 unique)"); CLAUDE.md §6 State Reconciliation Discipline

**Code:**
```mql5
// services/TradeJournal.mqh:6-11 — file header (UNCHANGED by fix-round-17)
//| IMPL-066 extension (NFR-2.2 journal write latency measurement)  |
//| Adds ≥200-sample ring buffer, running aggregates, per-event-type |
//| breakdown map (linear-probe, 16 buckets), EmitLatencyReport()   |
//| (periodic every 1000 writes + final at Close), and sidecar JSON |
//| report at PhoenicisNex/journal/<mode>/latency-report-<ISO>.json |

// services/TradeJournal.mqh:83 — field comment (UNCHANGED)
   //--- IMPL-066: per-event-type breakdown (linear-probe map, max 16 buckets)
   string                 m_evtype_keys[16];

// services/TradeJournal.mqh:533 — TrackLatency comment (UNCHANGED)
   //--- per-event-type linear-probe map (max 16 buckets; overflow → "_overflow")
```

**Problem:**
fix-round-17 § 17.5 reduced unique-event-type capacity from 16 to 15 (bucket 15 reserved for `_overflow`) but updated only the runtime logic (lines 544-572) — the three doc-block sites still claim 16. A future engineer adding a new `event_type` and reading the header expects 16 distinct types to track separately; in fact only 15 do, and the 15th-onward all collapse into `_overflow` with a Warn. Same audit-trail-integrity class as Finding 18.1: header contract drifts from runtime reality.

This is also a Phase 5 Gate #6 / Gate #9 micro-instance: the fix-round-17 narrative § 17.5 advertised "capacity reduced from 16 → 15 unique" but did not sweep the in-file documentation for the literal "16". Gate #9 clause (b) post-fix grep: `grep -nE "16 buckets" services/TradeJournal.mqh` returns 3 hits — none of which were rewritten.

**Why This Matters:**
LOW-bordering-MEDIUM because no runtime defect, but the documentation drift sets up the next reviewer / engineer to mis-reason about overflow behaviour. The bumped-buffer suggestion in R17 § 17.5 ("Bumping the buffer to 24 is also reasonable (4 + 16 KB extra resident)") is also blocked by the stale "16" references — anyone implementing that bump must hunt down 3 doc sites + the 4 array declarations + the 7 code-site `15` literals. Capacity contract in 5+ places is a refactor hazard.

**Suggested Fix:**

```mql5
// services/TradeJournal.mqh:6-11 — rewrite header
//| IMPL-066 extension (NFR-2.2 journal write latency measurement)  |
//| Adds ≥200-sample ring buffer, running aggregates, per-event-type |
//| breakdown map (linear-probe, 15 unique buckets + 1 reserved for  |
//| "_overflow" per fix-round-17 § 17.5), EmitLatencyReport()        |
//| (periodic every 1000 writes Logger-only + final at Close with    |
//| sidecar JSON), and sidecar at PhoenicisNex/journal/<mode>/...    |

// services/TradeJournal.mqh:83 — rewrite field comment
   //--- IMPL-066: per-event-type breakdown (linear-probe map, 15 unique +
   //    1 _overflow reserve per fix-round-17 § 17.5; bucket 15 = overflow)
   string                 m_evtype_keys[16];

// services/TradeJournal.mqh:533 — rewrite TrackLatency comment
   //--- per-event-type linear-probe map (15 unique buckets + bucket 15
   //    reserved for "_overflow"; one-time Warn on first overflow)
```

Optionally, replace the magic literal `15` at lines 550, 558, 565-569 with `#define JOURNAL_EVTYPE_UNIQUE_CAP 15` + `#define JOURNAL_EVTYPE_OVERFLOW_BUCKET 15` to make the next bump (R17 § 17.5 suggested 24) a one-line edit.

**Level of Effort:** Low (3 comment rewrites + optional 2-line `#define`).

---

### Finding 18.4: 🔵 LOW — `EmitLatencyReport` sidecar `FileOpen` failure path emits a `Logger.Warn` but does not differentiate "sidecar successfully landed" from "sidecar lost to FS error" in the `m_latency_count` aggregate or any per-event-type bucket. Operator audit artifact silently absent on transient FS failure.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`, Lines: 666-676
- Service: ea (journal)
- Reference: NFR-2.2 (write latency p95 ≤ 5 ms cap + zero halt-events from operator Tester run); fix-round-17 § 17.4 sidecar-at-Close-only gating

**Code:**
```mql5
// services/TradeJournal.mqh:666-676 — sidecar write failure handling
      int fh = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(fh != INVALID_HANDLE)
        {
         FileWriteString(fh, w.ToString());
         FileClose(fh);
        }
      else if(m_logger != NULL)
        {
         m_logger.Warn("system", "journal_latency_report_write_fail", 0,
                       StringFormat("path=%s err=%d", path, GetLastError()));
        }
```

**Problem:**
The sidecar JSON is the operator's primary audit artifact for NFR-2.2 paired-bundle drain. If `FileOpen` returns `INVALID_HANDLE` (disk full, sandbox path collision, antivirus lock, or a transient Windows FS error) the Logger.Warn is the ONLY record that the artifact never landed. Three downstream issues:

1. The operator running `jq -e .writes < latency-report-*.json` for the deferred-AC drain finds zero matching files and has no in-band signal explaining why — must cross-reference the Experts log to discover the `journal_latency_report_write_fail` Warn.
2. The `m_latency_count` aggregate, the per-event-type counts, and the in-Logger summary line ALL still emit; only the sidecar is missing. The operator's audit pipeline cannot tell from the Logger output whether sidecar landed.
3. `FILE_WRITE | FILE_TXT | FILE_ANSI` is silently lossy for non-ASCII `event_type` strings (currently all canonical event_types are ASCII per `trade-journal-schema.yaml`, but slot-specific event types could land non-ASCII text in future). FILE_ANSI loses the data without warning.

This is LOW because (a) FS failures are rare on local sandbox writes, (b) operator can recover by re-running, and (c) the underlying `m_latency_count` integrity is preserved. But the audit-trail story is thin.

**Why This Matters:**
The IMPL-066 deferred-AC paired bundle (NFR-2.2) drains by parsing `latency-report-<ISO>.json` — if it's missing, the operator must hand-parse Experts log to extract the same data. The Logger.Warn does not include the actual `writes/avg_us/p95_us/max_us` payload (it only names the failed path), so the operator gets neither the artifact nor a fallback in-log copy.

**Suggested Fix:**

```mql5
// services/TradeJournal.mqh:666-680 — fail-soft fallback to Logger
      int fh = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(fh != INVALID_HANDLE)
        {
         FileWriteString(fh, w.ToString());
         FileClose(fh);
        }
      else if(m_logger != NULL)
        {
         // Sidecar write failed — emit full JSON inline as operator-
         // recoverable fallback (NFR-2.2 audit artifact must land
         // somewhere). One Warn naming the path + one Info carrying
         // the JSON body so jq -R 'fromjson?' can recover from log.
         m_logger.Warn("system", "journal_latency_report_write_fail", 0,
                       StringFormat("path=%s err=%d → fallback to Logger inline", path, GetLastError()));
         m_logger.Info("system", "journal_latency_report_inline", 0,
                       w.ToString());
        }
```

Also consider `FILE_WRITE | FILE_TXT | FILE_UNICODE` (or FILE_BIN write of UTF-8 bytes) to avoid ANSI lossy-conversion on non-ASCII event_types.

**Level of Effort:** Low (~5 lines).

---

### Finding 18.5: 🟡 MEDIUM — fix-round-17 G2-G4 deferral rationale ("no production-runtime change to slot business logic; combined drain in upcoming operator session") accurate for default build, but defers ALL post-fix verification of the `ENABLE_TICK_LATENCY` build to the same operator-session bottleneck — no `[probe]` evidence artifact yet shows the post-fix-17.2 instrumented-build invariant `n_entry_stage ≪ n_other_stages` actually materialises under headless tick load.

**Location:**
- File: `docs/code-review/fix-round-17.md`, Lines: 124-133 (G1-G4 verification table + G2-G4 deferral rationale)
- File: `core/Orchestrator.mqh:655-672` — fix that moved STAGE_ENTRY probe inside entry-gate
- File: `docs/state/deferred-ac-registry.md` (P4 IMPL-065 paired bundle row, expiry 2026-05-19)
- Reference: CLAUDE.md §1 Three-Tier Closure Convention; `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` ("task ที่มี E-AC ปิดด้วย structural test pass อย่างเดียวไม่ได้ — ต้องมี evidence artifact"); review-round-17 § 17.7 (the converse — "structural tests can drain the *contract assertion* half of paired bundles")

**Problem:**
Fix-round-17 § 17.2 changed the control flow inside `core/Orchestrator.mqh:655-672` (TLPROBE_STAGE_ENTRY now nested inside `if(!morning_block && !ShouldSkipEntryPass(...))`). The fix is correct in source-review terms — but the *contract assertion* of the fix is empirically testable: `m_count[TLPROBE_STAGE_ENTRY] < m_count[TLPROBE_STAGE_REFRESH]` after a tester run that includes morning-window or holiday gating.

The fix-round-17 G3 deferral table claims "operator-drain combined with IMPL-062 / IMPL-065 paired bundles will exercise" — but per review-round-17 § 17.7 (which fix-round-17 deferred as IMPL-FIX-003), the paired bundle includes a structural pre-drain opportunity that the operator can validate in 10 min today via a smoke `.ini` (e.g., `tick_latency_smoke.ini` with `ENABLE_TICK_LATENCY` + 3-day window + grep `[ev=tick_latency_report]` + jq the n-per-stage table). Without that pre-drain, the operator who eventually runs the full 5-yr regression has zero prior signal that the post-fix-17.2 instrumentation even compiles + emits + counts correctly under non-zero tick load — a measurement-instrument regression discovered in operator session is **maximum cost** because the 5-yr backtest itself takes hours and re-running with a re-fixed probe doubles the cycle.

This is the same defect class as `andm-impl-engineer/SKILL.md § Forbidden Closure Patterns` "deferred to operator-runtime" — except here it's "deferred to operator-runtime *that we already have a structural pre-drain plan for* (R17 § 17.7) but didn't execute".

**Why This Matters:**
fix-round-17 closed 5 findings without G2-G4 evidence; one of those findings (17.2) is itself an instrument-correctness fix to an instrument that has never been exercised post-fix. If the post-fix probe placement has a typo or off-by-one, the operator session burns ~3 hours of 5-yr backtest to discover it. The R17 § 17.7 IMPL-FIX-003 ticket exists precisely to neutralise this risk; deferring it post-fix-17 leaves the risk live.

**Suggested Fix:**
Open `IMPL-FIX-003` immediately after this review (per R17 § 17.7 + R18 reaffirmation) and execute the structural pre-drain:

1. Author `simulation/headless-tests/tick_latency_smoke.ini` (3-day window, `Period=H4`, `Model=4`, `ShutdownTerminal=1`, `Visual=0`) with EA-side `#define ENABLE_TICK_LATENCY 1` injected via a wrapper `.mq5` that includes `PhoenicisNex.mq5` after the define (or via `MetaEditor64.exe /compile` `/inc` flag if supported in your build).
2. Run G3 + grep `[ev=tick_latency_report]` ≥ 1 line.
3. Parse the per-stage table:
   ```bash
   grep "tick_latency_report" tester.log \
     | grep -oE "stage=[a-z_]+ n=[0-9]+" \
     | sort -u
   ```
4. Assert: `n` for `entry_pass` < `n` for `refresh` (proves R17 § 17.2 fix is empirically active — entry stage skipped by morning_block at least once in the 3-day window).
5. Mark structural half of IMPL-065 E-AC `[x]` + update `deferred-ac-registry.md` Active row with "structurally pre-drained YYYY-MM-DD; empirical p95/avg drain pending operator session".

**Level of Effort:** Low (`ini` authoring + 1 G3 + 1 jq + registry update; ~30 min wall-clock).

---

### Finding 18.6: 🔵 LOW — `CTickLatencyProbe::m_count[TLPROBE_STAGE_COUNT]` typed as `int` (signed 32-bit). Long-running every-tick model-4 backtest can approach but stays below `INT_MAX` (~2.1B). Safer to align with `m_total_us` (`ulong`) to remove the theoretical overflow surface and match the `m_idx` rolling counter type.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TickLatencyProbe.mqh`, Lines: 70-72
- Service: ea (instrumentation)

**Code:**
```mql5
// services/TickLatencyProbe.mqh:67-74
   ulong   m_samples[TLPROBE_STAGE_COUNT][TLPROBE_RING_SIZE]; // [stage][slot]
   int     m_idx[TLPROBE_STAGE_COUNT];          // next write index (mod TLPROBE_RING_SIZE)
   ulong   m_total_us[TLPROBE_STAGE_COUNT];     // running sum
   ulong   m_max_us[TLPROBE_STAGE_COUNT];       // running max
   int     m_count[TLPROBE_STAGE_COUNT];         // total samples recorded
```

**Problem:**
A 5-yr EURUSD backtest with `Model=4` "every tick based on real ticks" generates on the order of 100-300M ticks (per FBS Standard tick density). 8 stages × ~200M ticks ≈ 1.6B per stage — still under INT_MAX but within an order of magnitude. Stress runs (e.g. 10-yr, multi-symbol smoke, high-frequency tick injection for stress profiling) cross the boundary. Once `m_count[s]` overflows to negative, the divide `m_total_us[s] / (ulong)m_count[s]` casts negative to a near-`ULONG_MAX` value, producing nonsense `avg_us = 1` (huge denominator).

`m_idx[stage]` has the same issue but is taken `mod TLPROBE_RING_SIZE = 200` immediately, so overflow only mis-orders the ring temporarily — not a correctness issue.

**Why This Matters:**
Defensive typing is cheap and removes a long-tail measurement-corruption risk that would only surface on a stress run no one tests for. Same class as the `m_tick_count` int in `OnTickStart` (line 77) — also `int`, also incrementable to overflow on multi-day stress runs.

**Suggested Fix:**

```mql5
// services/TickLatencyProbe.mqh:70-74 — align types
   ulong   m_idx[TLPROBE_STAGE_COUNT];          // next write index (mod TLPROBE_RING_SIZE)
   ulong   m_total_us[TLPROBE_STAGE_COUNT];
   ulong   m_max_us[TLPROBE_STAGE_COUNT];
   ulong   m_count[TLPROBE_STAGE_COUNT];        // ulong to match m_total_us; no overflow on 5-yr+ stress runs

// services/TickLatencyProbe.mqh:77 — same for m_tick_count
   ulong   m_tick_count;

// _Quantile cast line 149 also adjusts:
   int n = (int)MathMin((ulong)m_count[stage], (ulong)TLPROBE_RING_SIZE);
```

Plus update `Init` / constructor / printf format strings (`%llu` for ulong) accordingly.

**Level of Effort:** Low (≈10 type changes + format-string fixes; G1 catches missed sites).

---

### Finding 18.7: 🔵 LOW — `EmitLatencyReport` sidecar JSON write uses `FILE_WRITE | FILE_TXT | FILE_ANSI` — silently lossy for non-ASCII characters in `event_type` keys. Currently all canonical event_types are ASCII, but slot-specific tags or future i18n breaks the audit artifact silently.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`, Line: 666
- Service: ea (journal)

**Code:**
```mql5
// services/TradeJournal.mqh:666
      int fh = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
```

**Problem:**
`FILE_ANSI` writes 1 byte per character via the system code page — non-ASCII strings get lossy-converted (typically to `?`) without any error. JSON specification mandates UTF-8 (or UTF-16/32 with BOM). MT5 native string handling is UTF-16; encoding to ANSI on disk is a downgrade.

If a future engineer adds an `event_type` that includes a non-ASCII character (e.g. Thai-language event labels per the `feedback_thai_clusters.md` user-profile note, or unicode arrows in tag literals), the sidecar JSON contains `?` glyphs, breaking `jq -R 'fromjson?'` parsing on the operator-drain pipeline. Probability is low (current taxonomy is ASCII-only) but cost is silent corruption.

**Why This Matters:**
ADR-006 § Trade Journal Format mandates JSON-Lines + UTF-8 per `docs/api-specs/trade-journal-schema.yaml`. The sidecar is an extension of that contract surface; ANSI writes silently violate the encoding invariant.

**Suggested Fix:**

```mql5
// services/TradeJournal.mqh:666 — switch to UTF-8 binary write
      int fh = FileOpen(path, FILE_WRITE | FILE_BIN);   // write raw UTF-8 bytes
      if(fh != INVALID_HANDLE)
        {
         string body = w.ToString();
         uchar utf8[];
         StringToCharArray(body, utf8, 0, -1, CP_UTF8);
         // Drop trailing NUL byte that StringToCharArray appends
         int nbytes = ArraySize(utf8) - 1;
         if(nbytes > 0)
            FileWriteArray(fh, utf8, 0, nbytes);
         FileClose(fh);
        }
```

Or alternatively, stay with `FILE_TXT` but use `FILE_UNICODE` (UTF-16 LE with BOM, MT5 native) and document the encoding in the file header.

**Level of Effort:** Low (≈10 lines).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-18.1 | 🟠 HIGH | Stale forward-pointer comments referring to closed tasks (next-coarser variant of R16 § 16.3 / 16.7 sweep miss) | 100 occurrences across 45 files in `MQL5/Experts/PhoenicisNex/`; representative: `slots/Slot_J.mqh`, `slots/Slot_BI.mqh`, `services/PortfolioState.mqh`, `services/RiskManager.mqh`, `domain/SlotState.mqh`, all 14 slot files | Defect-class continuation R12 → R13 → R14 → R16 → R18. Each round caught a strictly broader-class regex than the previous; R18 catches the variant `"wires at IMPL-NNN"` / `"populated by … at IMPL-053+"` that R16 § 16.3 sweep missed. Phase 5 Gate #9 clause (c) catalog needs to expand. |
| XS-18.2 | 🟡 MEDIUM | Hot-path I/O in instrumentation periodic emit (defect class fix-round-17 § XS-17.1 already documented but not enforced via gate) | `services/TickLatencyProbe.mqh:116-121` (Finding 18.2) — same pattern fix-round-17 § 17.4 fixed in `services/TradeJournal.mqh` | Add a Phase 5 mechanical gate or `.claude/rules/ea.md` rule: "any class named `*Probe*.mqh` or `*Latency*.mqh` whose periodic emit method invokes `Logger.Info` more than 1× per cadence MUST gate that emit to FinalEmit / OnDeinit only". Grep-enforceable. |
| XS-18.3 | 🔵 LOW | Documentation-vs-runtime drift inside a single file (capacity contract) | `services/TradeJournal.mqh` (Finding 18.3) — header / field / TrackLatency comments all still say "16 buckets" after fix-round-17 § 17.5 reduced unique cap to 15 | Phase 5 Gate #6 (file integrity post-Edit-batch) should add a sub-check: "if a fix-round narrative claims a magic-number / capacity reduction, grep the file for the OLD literal and assert 0 hits OR explicit annotation". |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 18.1 | Stale "wires at IMPL-NNN" forward-pointer comments referring to closed tasks (100 occurrences across 45 files) | 🟠 HIGH | repo-wide; representative: `slots/Slot_J.mqh:137,152,229`, `slots/Slot_BI.mqh:276`, `services/PortfolioState.mqh:176,278,315,380`, `services/RiskManager.mqh:15,295,353`, `domain/SlotState.mqh:38` | ea (cross-cutting) | M (mechanical sweep + per-site routing decision; ~2-3h) |
| 18.2 | TickLatencyProbe periodic 1000-tick emit fires 9 Logger.Info on hot-path | 🟡 MEDIUM | `services/TickLatencyProbe.mqh:116-121, 177-207` | ea | Low (~30 LOC; 1-line periodic + full FinalEmit) |
| 18.3 | TradeJournal header + field + TrackLatency comments still say "16 buckets" after R17 § 17.5 reduced unique cap to 15 | 🟡 MEDIUM | `services/TradeJournal.mqh:7-11, 83, 533` | ea | Low (3 comment rewrites) |
| 18.4 | EmitLatencyReport sidecar FileOpen failure has no in-log JSON fallback | 🔵 LOW | `services/TradeJournal.mqh:666-676` | ea | Low (~5 lines) |
| 18.5 | fix-round-17 deferred all post-fix verification of ENABLE_TICK_LATENCY build to operator-session bottleneck — no structural pre-drain executed despite R17 § 17.7 plan | 🟡 MEDIUM | `docs/code-review/fix-round-17.md:124-133` + `core/Orchestrator.mqh:655-672` | ea-qa | Low (1 .ini + 1 G3 + 1 jq; ~30min) |
| 18.6 | TickLatencyProbe `m_count[s]` typed as `int` — theoretical overflow on multi-yr stress runs | 🔵 LOW | `services/TickLatencyProbe.mqh:70-74, 77` | ea | Low (~10 type changes) |
| 18.7 | EmitLatencyReport sidecar uses FILE_ANSI — silently lossy for non-ASCII event_types | 🔵 LOW | `services/TradeJournal.mqh:666` | ea | Low (~10 lines) |
| **Cross-Service Total** | | | | | |
| XS-18.1 | Stale forward-pointer next-coarser-variant defect class (R12 → R18 chain) | 🟠 HIGH | repo-wide | ea | (covered by 18.1) |
| XS-18.2 | Hot-path I/O in instrumentation periodic emit — Phase 5 gate enforcement gap | 🟡 MEDIUM | `services/TickLatencyProbe.mqh` | ea | (covered by 18.2) |
| XS-18.3 | Documentation-vs-runtime capacity drift — Phase 5 Gate #6 enforcement gap | 🔵 LOW | `services/TradeJournal.mqh` | ea | (covered by 18.3) |

**Recommendation:** Ready for **fix-round-18**. Priority order:

1. **Finding 18.1 (HIGH)** — repo-wide stale forward-pointer sweep; defect class R12-R16 chain continuation; same closure-discipline rationale that produced R16 § 16.3/16.7 fix. Block IMPL-063 closure until clean (any new comments referencing closed tasks regress the chain).
2. **Finding 18.2 (MEDIUM)** + **Finding 18.3 (MEDIUM)** + **Finding 18.5 (MEDIUM)** — surgical post-R17 hardening of the new instrumentation surfaces; all small; all reduce operator-drain risk for the IMPL-065 / IMPL-066 paired bundles.
3. **Findings 18.4 / 18.6 / 18.7 (LOW)** — defensive hardening; can land in same fix-round if capacity allows, otherwise tracked as IMPL-FIX-005.

> **Reviewer note (Dim #11 Empirical AC Closure spot-check):** No new forbidden closure patterns introduced by fix-round-17. The "G2-G4 deferred" pattern in `fix-round-17.md` is closer to the operator-runtime defer that Glossary § Empirical Closure Discipline rejects, but is excused for this round because (a) production runtime path is unchanged for the slot/Orchestrator changes, (b) the deferred verification has a structural pre-drain plan in R17 § 17.7. Finding 18.5 raises the bar — the structural pre-drain SHOULD execute pre-operator-session, not be itself deferred.

> **Plan Staleness Sentinel post-R18:** unchanged from R09 (this is the immediate successor advisory). Sentinel resets on next P4 closure (IMPL-063).

## End of Review Round 18
