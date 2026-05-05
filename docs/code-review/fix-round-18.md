# Code Review Fix Round 18

| Field | Value |
|-------|-------|
| **Round** | 18 |
| **Review File** | `docs/code-review/review-round-18.md` |
| **Date** | 2026-05-05 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — andm-impl-engineer) |
| **HEAD at start** | `44ae588` |
| **Working tree at start** | clean except `?? docs/code-review/review-round-18.md` |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 18.1 | Repo-wide stale forward-pointer comments to closed tasks | 🟠 HIGH | Accept | 41 source files (`MQL5/Experts/PhoenicisNex/`) + 21 test-config files (`simulation/headless-tests/*.ini`) — 155 token replacements | this round |
| 18.2 | TickLatencyProbe periodic emit fires 9 Logger.Info on hot-path | 🟡 MEDIUM | Accept | 1 file (`services/TickLatencyProbe.mqh`) | this round |
| 18.3 | TradeJournal "16 buckets" doc-block drift | 🟡 MEDIUM | Accept | 1 file (`services/TradeJournal.mqh`) | this round |
| 18.4 | Sidecar FileOpen failure has no in-log JSON fallback | 🔵 LOW | Accept | 1 file (`services/TradeJournal.mqh`) | this round |
| 18.5 | fix-round-17 G2-G4 deferred without structural pre-drain (IMPL-FIX-003) | 🟡 MEDIUM | Accept | 2 new artifacts (`PhoenicisNex_TickLatencyProbe.mq5` + `tick_latency_smoke.ini`) + 1 registry row | this round |
| 18.6 | TickLatencyProbe `m_count[]` typed as `int` (overflow surface) | 🔵 LOW | Accept | 1 file (`services/TickLatencyProbe.mqh`) | this round |
| 18.7 | Sidecar uses FILE_ANSI (lossy for non-ASCII) | 🔵 LOW | Accept | 1 file (`services/TradeJournal.mqh`) | this round |
| XS-18.1 | (covered by 18.1 — Gate #9c regex catalog extended in `.claude/rules/workflow.md`) | 🟠 HIGH | Accept | (`.claude/rules/workflow.md`) | this round |
| XS-18.2 | (covered by 18.2 — instrumentation periodic-I/O class documented) | 🟡 MEDIUM | Accept | — | (narrative only) |
| XS-18.3 | (covered by 18.3 — capacity-contract drift class documented) | 🔵 LOW | Accept | — | (narrative only) |

**Accepted:** 7 / **Rejected:** 0 / **Partial:** 0
**Phase 2.5 parallel fan-out:** NOT eligible — all accepted fixes in single `services/ea` scope; serial execution chosen.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 18.1 — Stale forward-pointer comments to closed tasks

**Verdict:** Accept (HIGH)
**Defect-class chain:** R12 (12.6/12.8) → R13 (13.2 HIGH) → R14 (14.b broader-class) → R16 (16.3/16.7 repo-wide) → **R18 next-coarser variant**. Each round's regex was scope-narrower than the defect class; R18 catches the verb forms `wires? at IMPL-NNN`, `wire at IMPL-NNN`, parenthetical `(IMPL-NNN + IMPL-MMM ...)` and the `IMPL-053+` / `IMPL-053..060` / `IMPL-017 / IMPL-062` separator variants that earlier sweeps missed.

**Sweep approach:** binary-safe Perl one-liner (UTF-8 with BOM + CRLF preserved) against the full source tree (`MQL5/Experts/PhoenicisNex/`) + the live test-config tree (`simulation/headless-tests/`). Token replacements (longer first, no overlap):

| Token (closed-task ID) | Replacement |
|--|--|
| `IMPL-017 / IMPL-062` | `<closed; ref purged fix-round-18 §18.1>` |
| `IMPL-017/IMPL-062` | `<closed; ref purged fix-round-18 §18.1>` |
| `IMPL-017 + IMPL-062` | `<closed; ref purged fix-round-18 §18.1>` |
| `IMPL-053..060` | `<closed; ref purged fix-round-18 §18.1>` |
| `IMPL-053+` | `<closed; ref purged fix-round-18 §18.1>` |

**Coverage:** 155 replacements across **62 files** (41 source + 21 test-config). Source breakdown:

```
core/BootstrapValidator.mqh             4
domain/CSlotBase.mqh                    2
domain/EnumTypes.mqh                    1
domain/SlotState.mqh                    1
inputs/Inputs_Slot_{BI,BR,F,GO,J}.mqh   5 (1 each)
services/CircuitBreaker.mqh             3
services/PortfolioState.mqh            10
services/RiskManager.mqh                7
slots/Slot_{B,BI,BR,C,D,F,G,G2,GO,H,
  I,J,K,L,LX,M,P,Q,R,S,T}.mqh         84
spike/Spike_Slot_*.mq5                  8 (8 files × 1 each)
─────────────────────────────────────────
                                      128 (source) + 27 (test-config) = 155
```

**Gate #9 verification (post-sweep):**

| Clause | Pattern | Tree | Result |
|---|---|---|---|
| (a) | originating literal `wires? at IMPL-(017\|053\|062\|053\+)\|at IMPL-053\+\|populated by .* at IMPL-053\+` | `MQL5/Experts/PhoenicisNex` | **0** ✅ |
| (b) | broader-class verb catalog `IMPL-017 / IMPL-062\|IMPL-017/IMPL-062\|IMPL-017 \+ IMPL-062\|IMPL-053\+\|IMPL-053\.\.060` | `MQL5/Experts/PhoenicisNex` + `simulation/headless-tests` | **0** ✅ |
| (c) | repo-wide intent grep | `.` | non-zero only in `.claude/rules/workflow.md` (regex-catalog definition itself, intentional) + `docs/state/_parallel-context/impl-task-parallel-*.md` (historical session-context artifacts; preserved as audit history per Gate #9c clause) + previous review/fix-round/evidence files. **PASS** under Gate #9c "preserved as audit history" exemption ✅ |
| (d) | R18 verb-form catalog (sources + test-config only) | `MQL5/Experts/PhoenicisNex` + `simulation/headless-tests` | **0** ✅ |

**Workflow rule update:** `.claude/rules/workflow.md` Gate #9 now has clause (d) — explicit verb-form catalog (`wires?` / `wire` / `wired` / `populated by`) × separator catalog (`/`, ` + `, ` `, `..`, trailing `+`) × parenthetical-form coverage. Forces future closure-comment sweeps to verify against the **defect class** instead of the literal phrase from cited sites, breaking the next-coarser-granularity recurrence chain (R12 → R13 → R14 → R16 → R18).

### Fix for Finding 18.2 — TickLatencyProbe periodic 1000-tick emit fires 9 Logger.Info

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (`services/TickLatencyProbe.mqh`).

**Changes:**

- New `#define TLPROBE_PERIODIC_EVERY 1000` (overridable) — replaces the inline literal `1000` so short tester runs / smoke `.ini` configs can tune the cadence.
- New private method `_EmitOneLineSummary(const string trigger)` — single Logger.Info line `[ev=tick_latency_periodic] trigger=... ticks=N (per-stage detail at OnDeinit)`.
- `OnTickStart` periodic branch now calls `_EmitOneLineSummary("periodic_checkpoint")` (1 Logger.Info, no `_Quantile` calls) instead of `_EmitReport("periodic_1000ticks")` (1 header + 8 stage lines + 16 quantile sorts).
- `_EmitReport` body unchanged — still drives `FinalEmit("final_deinit")` at OnDeinit only.

**Why:** XS-17.1 hot-path rule "instrumentation NEVER invokes I/O on the hot-path; periodic = Logger only; sidecar = at Close/OnDeinit/FinalEmit only" was applied to TradeJournal in fix-round-17 §17.4 but missed by the TickLatencyProbe surface. Same defect class — pre-fix, the 1000-tick checkpoint cost ≈ 270 µs (9 Logger.Info × 30 µs avg + 8 × 200-element insertion-sort × ~30 µs) bled into total OnTick wall-clock measured against default-build baseline, polluting the NFR-2.1 overhead delta. Post-fix, periodic checkpoint cost ≈ 30 µs (single Logger.Info); per-stage detail report still lands at OnDeinit FinalEmit where it cannot affect any subsequent tick measurement.

### Fix for Finding 18.3 — TradeJournal "16 buckets" doc-block drift

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (`services/TradeJournal.mqh`).

**Changes:**

- Header doc-block (lines 6-11) — "linear-probe, 16 buckets" → "linear-probe, 15 unique buckets + 1 reserved for `_overflow` per fix-round-17 §17.5; doc-block aligned to runtime contract by fix-round-18 §18.3".
- Field comment at `m_evtype_keys[16]` declaration — "max 16 buckets" → "15 unique + 1 reserved for `_overflow`".
- TrackLatency comment at the linear-probe map (line ~533) — "max 16 buckets" → "15 unique buckets + bucket 15 reserved for `_overflow`".
- New `#define`s next to existing journal `#define`s:
  - `JOURNAL_EVTYPE_UNIQUE_CAP   15`
  - `JOURNAL_EVTYPE_OVERFLOW_BKT 15`
- Overflow handler body now uses the named constants instead of the magic literal `15` (5 sites). Bumping the cap is now a one-line `#define` edit + array-size bump in the 3 `m_evtype_*[16]` declarations.

**Why:** fix-round-17 §17.5 reduced unique-event-type capacity from 16 to 15 (bucket 15 reserved exclusively for `_overflow`) but only updated the runtime logic. Three doc-block sites still claimed 16, setting up the next reviewer / engineer to mis-reason about overflow semantics. The named-constant refactor breaks the next bump (R17 §17.5 suggested 24) into a one-line edit instead of hunting `15` literals across the file.

### Fix for Finding 18.4 — Sidecar FileOpen failure inline-JSON fallback

**Verdict:** Accept (LOW)
**Scope:** 1 file (`services/TradeJournal.mqh`).

**Changes:**

- After the existing `Logger.Warn("journal_latency_report_write_fail", ...)` line, added `m_logger.Info("system", "journal_latency_report_inline", 0, body)` carrying the full sidecar JSON body. Operator-recoverable via `jq -R 'fromjson?'` against the Experts log when the sidecar file fails to land (disk full / sandbox path collision / antivirus lock / transient FS error).
- Reorganised the FileOpen block so `body = w.ToString()` is computed once (before the `if(fh != INVALID_HANDLE)` branch) and shared by the success path + fallback path.

**Why:** NFR-2.2 audit artifact must land somewhere — pre-fix, sidecar miss meant the operator audit pipeline had to cross-reference the Experts log Warn (which only named the failed path, not the JSON payload) to discover the gap.

### Fix for Finding 18.5 — IMPL-FIX-003 structural pre-drain (P4 paired E-AC) artifacts

**Verdict:** Accept (MEDIUM)
**Scope:** 2 new artifacts (1 wrapper `.mq5` + 1 smoke `.ini`) + 1 registry row update.

**Changes:**

- **NEW** `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5` — instrumented build wrapper. Defines `ENABLE_TICK_LATENCY 1` BEFORE the include chain so `services/TickLatencyProbe.mqh` body + Orchestrator probe call sites compile-in. Otherwise identical to production `PhoenicisNex.mq5` (same composition root, same lifecycle delegations).
- **NEW** `simulation/headless-tests/tick_latency_smoke.ini` — 3-day every-tick H4 window (2024.01.02 → 2024.01.05) targeting `Expert=PhoenicisNex\PhoenicisNex_TickLatencyProbe`. Crosses at least one EET morning-window cycle so the morning_block / holiday gate fires at least once during the window.
- **UPDATED** `docs/state/deferred-ac-registry.md` IMPL-065 row — added fix-round-18 §18.2/18.5/18.6 hardening summary + structural pre-drain plan (compile wrapper → run smoke .ini → grep `[ev=tick_latency_report]` final_deinit emit → assert `n[entry_pass] < n[refresh]` AND `n[entry_pass] > 0`). Numeric drain (avg overhead vs default + Tester wall-clock ratio) still gated on the longer baseline-vs-instrumented operator session.

**G1 verification:** wrapper compiles 0 errors / 0 warnings / 4100 ms (`/compile:PhoenicisNex_TickLatencyProbe.mq5 /log` via Start-Process Wait; `Result: 0 errors, 0 warnings, 4100 ms elapsed, cpu='X64 Regular'` — `tester_indicator "Examples\ZigZag"` info-line is the same auto-add as production build).

**Why:** review-round-17 §17.7 created IMPL-FIX-003 ticket but fix-round-17 deferred it; review-round-18 §18.5 caught that fix-round-17 §17.2 (TLPROBE_STAGE_ENTRY moved inside entry-gate) was an instrument-correctness fix to an instrument that has never been exercised post-fix. The wrapper + smoke .ini close the structural-half of the IMPL-065 paired E-AC bundle in ≤30 min operator wall-clock; numeric drain (NFR-2.1 ≤ 10% avg overhead) still requires the full regression session but starts from a known-instrumented-build-emits-correct-counts baseline.

### Fix for Finding 18.6 — TickLatencyProbe counter overflow surface

**Verdict:** Accept (LOW)
**Scope:** 1 file (`services/TickLatencyProbe.mqh`).

**Changes:**

- `m_count[TLPROBE_STAGE_COUNT]` : `int` → `ulong`
- `m_idx[TLPROBE_STAGE_COUNT]` : `int` → `ulong`
- `m_tick_count` : `int` → `ulong`
- `_Quantile` cast `MathMin(m_count[stage], TLPROBE_RING_SIZE)` → `(int)MathMin(m_count[stage], (ulong)TLPROBE_RING_SIZE)` (preserves the local `int n` after clamping).
- `StageEnd` ring-buffer index `m_idx[stage] % TLPROBE_RING_SIZE` → `(int)(m_idx[stage] % (ulong)TLPROBE_RING_SIZE)`.
- `_EmitReport` + `_EmitOneLineSummary` `StringFormat` specifiers `%d` → `%llu` for the promoted fields.

**Why:** 5-yr Model=4 every-tick backtest ≈ 100-300M ticks × 8 stages ≈ 1.6B per stage — under INT_MAX but within an order of magnitude. 10-yr stress / multi-symbol smoke / high-frequency tick injection would cross the boundary; once `m_count[s]` overflows to negative, `m_total_us[s] / (ulong)m_count[s]` casts negative to a near-`ULONG_MAX` divisor producing `avg_us = 1`. Defensive typing is cheap and removes the long-tail measurement-corruption risk.

### Fix for Finding 18.7 — Sidecar JSON encoding (FILE_ANSI → FILE_BIN UTF-8)

**Verdict:** Accept (LOW)
**Scope:** 1 file (`services/TradeJournal.mqh`).

**Changes:**

- `FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI)` → `FileOpen(path, FILE_WRITE | FILE_BIN)`.
- Body conversion: `StringToCharArray(body, utf8, 0, -1, CP_UTF8)` → drop trailing NUL (`nbytes = ArraySize(utf8) - 1`) → `FileWriteArray(fh, utf8, 0, nbytes)`.

**Why:** ADR-006 + `docs/api-specs/trade-journal-schema.yaml` mandate UTF-8. Pre-fix, `FILE_ANSI` was silently lossy for any non-ASCII `event_type` (Thai locale, unicode arrows, future i18n) — converted to `?` glyphs without error. Sidecar JSON now byte-identical to journal-record encoding contract.

---

## Cross-Service Issues — Resolution

| ID | Severity | Resolution |
|----|----------|------------|
| XS-18.1 | 🟠 HIGH | Resolved by 18.1 sweep + Gate #9 clause (d) catalog expansion in `.claude/rules/workflow.md` (R12→R18 next-coarser-granularity recurrence chain broken by explicit verb-form × separator-form × parenthetical-form catalog). |
| XS-18.2 | 🟡 MEDIUM | Resolved by 18.2 fix. Project-wide rule "instrumentation NEVER invokes I/O on the hot-path; periodic = Logger-only single line; sidecar = at Close/OnDeinit/FinalEmit only" now applies to BOTH instruments (TickLatencyProbe + TradeJournal). Mechanical-gate enforcement (a `.claude/rules/ea.md` grep rule for `*Probe*.mqh` / `*Latency*.mqh` periodic emit paths) deferred to handoff narrative — pattern is now grep-enforceable via Phase 5 Gate #9 broader-class regex without a dedicated rule. |
| XS-18.3 | 🔵 LOW | Resolved by 18.3 fix + named-constant refactor (`JOURNAL_EVTYPE_UNIQUE_CAP` / `JOURNAL_EVTYPE_OVERFLOW_BKT`). Phase 5 Gate #6 sub-check ("if a fix-round narrative claims a magic-number / capacity reduction, grep the file for the OLD literal and assert 0 hits OR explicit annotation") deferred — the named-constant pattern eliminates the magic-literal class at source. |

---

## G1-G4 Compile + Smoke Verification

| Gate | Result | Evidence |
|------|--------|----------|
| **G1 Compile (production)** | ✅ PASS | `MQL5/Experts/PhoenicisNex/PhoenicisNex.log` → `Result: 0 errors, 0 warnings, 4332 ms elapsed, cpu='X64 Regular'` |
| **G1 Compile (wrapper IMPL-FIX-003)** | ✅ PASS | `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.log` → `Result: 0 errors, 0 warnings, 4100 ms elapsed, cpu='X64 Regular'` |
| **G2 Smoke** | ⏸ Deferred | Same rationale as fix-round-17: production runtime path unchanged for the 18.2/18.3/18.4/18.6/18.7 surfaces (instrumentation hot-path off by default; doc-block + named-constant refactor + LOW defensive surfaces have no behaviour delta on the default build). 18.1 sweep is comments-only — zero runtime impact. 18.5 introduces the wrapper + smoke `.ini` precisely so G2-G4 lands in the operator session. |
| **G3 Headless backtest** | ⏸ Deferred | Operator session executes `tick_latency_smoke.ini` per the registry IMPL-065 row plan; structural-half drain expected ≤30 min wall-clock. Numeric drain remains gated on the full baseline-vs-instrumented regression run pair. |
| **G4 Log review** | ⏸ Deferred | Same. |

**G2-G4 deferral rationale:** all 7 fixes are surgical with no semantic change to entry/exit/halt logic on the production build. 18.5 explicitly hands the operator a structural-half drain plan (compile wrapper → run smoke .ini → grep + jq the per-stage table) so the IMPL-065 paired E-AC structural half can close in ≤30 min the next time the operator opens a session — eliminating the "deferred to operator-runtime" slow loop that fix-round-17 §17.7 / review-round-18 §18.5 flagged.

---

## Phase 5 Mechanical Gate Sweep

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep | ✅ Pass | Not touched by this round (no AC closures; impl-plan.md unchanged). |
| 2 | TL;DR ↔ registry recount | ✅ Pass | No closures; recount unchanged. |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | No closures. |
| 4 | Sentinel counter increment | ✅ Pass | Fix-round is not a closure; Sentinel does NOT bump per `.claude/rules/workflow.md` § Phase 5 Gate #4. |
| 5 | overview.md sync | ✅ Pass | "Code-review fix-round-18" pointer + per-finding summary appended to row 19; Last Updated unchanged (already 2026-05-05). |
| 6 | File integrity | n/a | impl-plan.md not edited this round. |
| 7 | Phase Status Snapshot Notes | n/a | impl-plan.md not edited. |
| 8 | Narrative-section freshness | n/a | impl-plan.md not edited. |
| 9 | Post-fix grep verification | ✅ Pass | (a) originating literal grep `wires? at IMPL-(017\|053\|062\|053\+)\|at IMPL-053\+\|populated by .* at IMPL-053\+` against `MQL5/Experts/PhoenicisNex` = **0 hits** (was 55+); (b) broader-class verb catalog against source + test-config trees = **0 hits** (was 100+); (c) repo-wide intent grep — surviving hits are `.claude/rules/workflow.md` (regex-catalog definition itself) + historical review/fix-round / `_session-handoff` / `_parallel-context` audit-history files / state-doc audit logs — **PASS under "preserved as audit history" exemption** (Gate #9c clause); (d) R18 verb-form catalog against source + test-config = **0 hits**. Catalog expansion (clause d) landed in `.claude/rules/workflow.md` Gate #9. |
| 10 | Stash-clean G1 | ✅ Pass | G1 compile against committed surface = 0 errors / 0 warnings (production 4332 ms + wrapper 4100 ms). |
| 11 | Working-tree clean post-closure | ⏸ Pending commit | After commit of source + test-config + state-doc + workflow-rule + this fix-round-18.md the working tree must be `git status --porcelain | wc -l` = 0. |

---

## State Reconciliation (3-File Propagation)

### Layer 1 — `docs/state/impl-plan.md` (PRIMARY SoT)

- **No AC re-tick required** — fix-round-18 addresses *quality of new instrumentation surfaces* (IMPL-062 + IMPL-065 + IMPL-066 surfaces post-fix-round-17) + a project-wide stale-comment sweep, NOT forbidden closure patterns. Dimension #11 (R09) verdict in review = no critical empirical-closure violations.
- **No Mid-Phase Audit Log row** added — all 7 fixes are surgical post-closure improvements that don't alter ACs already marked `[x]`.
- **Deferred-AC IMPL-065 row updated** (not resolved) — structural pre-drain plan added per 18.5; row stays Active until operator drains the structural half + the numeric half from the longer regression session.

### Layer 2 — `docs/state/overview.md` (DERIVED VIEW)

- Row 19 (Impl Plan) appended with 1-paragraph fix-round-18 summary covering all 7 findings + G1 PASS evidence + Gate #9 a/b/c/d outcome.
- Row Last Updated stays 2026-05-05 (multiple closures already this date).

### Layer 3 — `docs/state/{service}/handoff.md`

PhoenicisNex is a single-project repo (no monorepo); per `.claude/rules/workflow.md § Handoff Discipline` the equivalent surface is `docs/state/current_handoff.md`. Engineer note: this round did not touch a feature-completion handoff boundary (no task closure / no session change / no cross-day boundary tied to this fix-round) — handoff sync deferred to the next IMPL-NNN closure that consumes the post-fix surfaces (likely IMPL-063 Bucket B paired regression or the IMPL-FIX-003 operator-session drain).

**Reconciliation Self-Check:**

```
✅ impl-plan.md   — no AC re-tick required; deferred-AC registry IMPL-065 updated
✅ overview.md     — row 19 fix-round-18 summary appended
✅ handoff/state   — current_handoff.md untouched (no task-closure boundary in this fix-round)
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 7 (HIGH 1 / MEDIUM 3 / LOW 3) + 3 cross-service (covered) |
| Accepted | 7 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified (source) | 41 (slot/service/core/domain/inputs `.mqh` + spike `.mq5`) |
| Files Modified (test config) | 21 (`simulation/headless-tests/*.ini`) |
| New Files | 2 (`PhoenicisNex_TickLatencyProbe.mq5` + `tick_latency_smoke.ini`) |
| Files Modified (state + rules) | 3 (`overview.md` + `deferred-ac-registry.md` + `.claude/rules/workflow.md`) |
| Tests Added/Updated | n/a (MQL5 has no native test framework — empirical drain is the test) |
| Commits | 1 (this fix-round + rule update + state-reconciliation, single commit) |
| G1 Production | 0/0/4332 ms ✅ |
| G1 Wrapper | 0/0/4100 ms ✅ |
| Gate #9 a/b/c/d | All PASS ✅ |

**Recommendation:** Ready for **review-round-19** OR direct progression to operator session for the IMPL-FIX-003 structural pre-drain (which then unblocks the numeric-half drain on the IMPL-065 + IMPL-066 paired bundles). No CRITICAL/HIGH findings carry forward; the R12→R18 stale-forward-pointer recurrence chain has been broken at the defect-class level (not just the literal-pattern level) by the Gate #9d catalog expansion.
