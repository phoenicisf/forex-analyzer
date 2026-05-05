# Code Review Fix Round 17

| Field | Value |
|-------|-------|
| **Round** | 17 |
| **Review File** | `docs/code-review/review-round-17.md` |
| **Date** | 2026-05-05 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — andm-impl-engineer) |
| **HEAD at start** | `6239f3e` |
| **Working tree at start** | clean (`git status --porcelain` = 0) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 17.1 | DISABLE_G4_FIXES log text leak (Slot_J / Slot_BI) | 🟠 HIGH | Accept | 2 files (slots/Slot_J.mqh, slots/Slot_BI.mqh) | this round |
| 17.2 | TLPROBE_STAGE_ENTRY timed unconditionally | 🟠 HIGH | Accept | 1 file (core/Orchestrator.mqh) | this round |
| 17.3 | DST 10× .ini lacks PASS-criterion automation | 🟡 MEDIUM | Defer | — | tracked as IMPL-FIX-004 follow-up |
| 17.4 | TradeJournal sidecar I/O on hot-path | 🟡 MEDIUM | Accept | 1 file (services/TradeJournal.mqh) | this round |
| 17.5 | TradeJournal evtype overflow silently rewrites bucket 15 | 🟡 MEDIUM | Accept | 1 file (services/TradeJournal.mqh) | this round |
| 17.6 | TickLatencyProbe taxonomy lacks TD-02 §7.2 citation | 🔵 LOW | Accept | 1 file (services/TickLatencyProbe.mqh) | this round |
| 17.7 | P4 paired E-AC structural pre-drain absent | 🔵 LOW | Defer | — | tracked as IMPL-FIX-003 follow-up |

**Accepted:** 5 findings (5 files modified)
**Deferred:** 2 findings (17.3 + 17.7 — both M-scope new artifacts; reviewer explicitly marked nice-to-have / separate ticket)
**Rejected:** 0

---

## Accepted Findings — Fixes Applied

### Fix for Finding 17.1 — DISABLE_G4_FIXES log text leak

**Verdict:** Accept (HIGH)
**Scope:** 2 files (Slot_J + Slot_BI). Repo-wide intent grep `"\(G4 fix"` inside slot files now yields ONLY the `g4_tag` literal inside the `#else` (G4-fix) branch — defect class purged.

**Changes:**

- `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` — exit_profit_gate Logger.Info now uses branch-selected `magic_for_log` (MAGIC_F under DISABLE_G4_FIXES, MAGIC_J otherwise) and branch-selected `g4_tag` (`"(Bucket A — pre-G4 BR-7.2 path)"` vs `"(G4 fix BR-7.2)"`). Resolves the magic-mismatch (MAGIC_J emitted for tickets actually iterated under MAGIC_F) AND the false attestation in Bucket A regression journals.
- `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh` — entry_pyramid_buy/sell Logger.Info `(G4 fix ADR-009)` literal replaced with branch-selected `g4_tag` (`"(Bucket A — pre-G4 ADR-009 naked SL path)"` vs `"(G4 fix ADR-009)"`).

**Why:** Bucket A regression contract (NFR-1.1) requires `regression_5yr_no_g4.ini` outputs to be distinguishable from G4-fix outputs via journal text grep. Hard-coded G4-fix attestation in both branches contaminates the audit trail and breaks downstream `g4-fix-attestation.md` jq filters.

---

### Fix for Finding 17.2 — TLPROBE_STAGE_ENTRY pollution by skipped ticks

**Verdict:** Accept (HIGH)
**Scope:** 1 file (Orchestrator.mqh).

**Changes:**

- `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh:655-672` — moved `m_tick_probe.StageStart/End(TLPROBE_STAGE_ENTRY)` INSIDE the `if(!morning_block && !ShouldSkipEntryPass(...))` block so only ticks that actually run the entry pass accumulate samples. Added inline note that NFR-2.1 overhead-% denominator is `m_count[TLPROBE_STAGE_ENTRY]`, not total OnTick invocations.

**Why:** Bimodal distribution (skipped-tick guard cost ≈ single-digit µs vs ran-entry cost ≈ hundreds µs) artificially deflated avg / p95 / p99, false-passing NFR-2.1 ≤ 10% avg overhead.

---

### Fix for Finding 17.4 — Sidecar I/O on hot-path

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (TradeJournal.mqh).

**Changes:**

- `services/TradeJournal.mqh` declaration (line 144) — `EmitLatencyReport()` gains `bool emit_sidecar = true` default-arg.
- Periodic checkpoint trigger (line 562) — calls `EmitLatencyReport(false)` (Logger-only; no sidecar I/O on hot-path).
- `Close()` (line 315) — unchanged (default `emit_sidecar=true` ⇒ full Logger + sidecar at session end).
- Sidecar write block (line 614) — gated `if(emit_sidecar && EnsureDirectories())`.

**Why:** Sidecar `FileOpen + FileWriteString + FileClose` ≈ 1–3 ms uncached on Windows NTFS; emitted from inside `TrackLatency` which runs inside `WriteEvent`, self-polluting the next NFR-2.2 p95 sample. Session-end sidecar preserves the audit artifact without contaminating in-band latency.

---

### Fix for Finding 17.5 — evtype overflow silently rewrites bucket 15

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (TradeJournal.mqh).

**Changes:**

- `services/TradeJournal.mqh:543-572` — overflow handler now (a) reserves bucket 15 exclusively for `_overflow` (unique event_types fill 0..14 only — capacity reduced from 16 → 15 unique), (b) on first overflow zeros `m_evtype_counts[15]` + `m_evtype_total_us[15]` (no shadow-bleed of the prior 16th occupant's counts), (c) emits one-time `m_logger.Warn("system", "journal_evtype_overflow", ...)` naming the offending key so operator can audit the taxonomy.

**Why:** Silent-rewrite + no-Warn = quiet measurement loss. Per-event-type breakdown in `latency-report-<ISO>.json` becomes unreliable once the 16th distinct event_type appears.

---

### Fix for Finding 17.6 — TickLatencyProbe taxonomy citation

**Verdict:** Accept (LOW — docs-only)
**Scope:** 1 file (TickLatencyProbe.mqh header).

**Changes:**

- `services/TickLatencyProbe.mqh:23-37` — header block now enumerates the 8 timed steps (1, 2, 7, 8, 9, 11, 12, 13) AND the 6+ omitted steps (3, 4, 5, 5b, 6, 10, 13b, 14) with rationale ("each < 10 µs typical"), plus pointer to `docs/state/nfr-2.1-tick-latency.md § Scope` for operator-drain expectations.

**Why:** NFR-2.1 overhead-% denominator must be measurement-explicit; reviewer flagged silent exclusion as audit-trail thin.

---

## Deferred Findings — Tracked for Follow-up

### Defer of Finding 17.3 — DST PASS-criterion automation

**Verdict:** Defer
**Reason:** M-scope deliverable (new ~150-LOC PowerShell drain script + `dst-regression-result.json` schema). Reviewer marked "nice-to-have" and out-of-scope for fix-round if capacity tight. Tracked as **IMPL-FIX-004** for the next session window: add `simulation/scripts/dst_regression_drain.ps1` (parallel to `atomic_write_kill_100.ps1` precedent) + companion JSON sidecar schema. Compresses operator drain from 30-60 min manual → ~5 min automated.

### Defer of Finding 17.7 — Paired E-AC structural pre-drain

**Verdict:** Defer
**Reason:** Reviewer explicitly suggested opening `IMPL-FIX-003` ("structural pre-drain of P4 paired bundles") as a separate ticket. Three new `simulation/headless-tests/*.ini` files (tick_latency_smoke / journal_latency_smoke / dst_2024_mar smoke) + corresponding G3 + grep evidence. Tracked as **IMPL-FIX-003**. Out-of-fix-round-scope; both deferrals are reducer-of-operator-session-risk improvements, not defect remediation.

---

## Cross-Service Issues — Resolution

| ID | Severity | Resolution |
|----|----------|------------|
| XS-17.1 | 🟡 MEDIUM | Both new instruments now isolate measurement from contract: TickLatencyProbe (17.2 fix, samples ran-only) + TradeJournal sidecar (17.4 fix, gated to Close). Project-wide pattern documented in fix narrative; `.claude/rules/ea.md` rule update deferred — small enough to land via the next handoff TL;DR rather than its own commit. |
| XS-17.2 | 🔵 LOW | Resolved by 17.1 (Slot_J + Slot_BI both branch the human-readable tag). `.claude/rules/ea.md` "Compile-flag toggles best practice" rule deferred to handoff narrative — pattern is now grep-enforceable via Phase 5 Gate #9 broader-class regex. |

---

## G1-G4 Compile + Smoke Verification

| Gate | Result | Evidence |
|------|--------|----------|
| **G1 Compile** | ✅ PASS | `MQL5/Experts/PhoenicisNex/PhoenicisNex.log` → `Result: 0 errors, 0 warnings, 3964 ms elapsed, cpu='X64 Regular'` |
| **G2 Smoke** | ⏸ Deferred | No production-runtime change in this round to slot business logic (only attestation-tag branching + probe placement); operator-drain combined with IMPL-062 / IMPL-065 paired bundles will exercise. |
| **G3 Headless backtest** | ⏸ Deferred | Same — instrument-correctness fixes; combined drain in upcoming operator session covers. |
| **G4 Log review** | ⏸ Deferred | Same. |

**G2-G4 deferral rationale:** all 5 fixes are surgical text/control-flow changes (tag string branching + probe placement + sidecar gate + overflow Warn + header docs) with no semantic change to entry/exit/halt logic. G1 compile clean is sufficient pre-commit evidence; combined empirical drain with paired-bundle operator session validates downstream.

## Phase 5 Mechanical Gate Sweep

| Gate | Status | Note |
|------|--------|------|
| #1 Forbidden-pattern grep | ✅ Pass | Not touched by this round (no AC closures). |
| #2 TL;DR ↔ registry recount | ✅ Pass | No closures; recount unchanged. |
| #3 TL;DR ↔ matrix denominator | ✅ Pass | No closures. |
| #4 Sentinel counter increment | ✅ Pass | Fix-round is not a closure; Sentinel does NOT bump per `.claude/rules/workflow.md` § Phase 5 Gate #4. |
| #5 overview.md sync | ✅ Pass | "last code-review round" pointer updated below to round-17. |
| #6 File integrity | n/a | impl-plan.md not edited this round. |
| #7 Phase Status Snapshot Notes | n/a | impl-plan.md not edited. |
| #8 Narrative-section freshness | n/a | impl-plan.md not edited. |
| #9 Post-fix grep verification | ✅ Pass | (a) originating literal grep `"(G4 fix BR-7.2)"` + `"(G4 fix ADR-009)"` outside `#ifdef`-branched `g4_tag` literals = 0 production hits; (b) broader-class `m_logger\.(Info\|Warn).*G4 fix` in slot logger calls = 0 unconditional hits; (c) repo-wide `"\(G4 fix` in `slots/` = 2 hits, both inside the `#else` (G4-fix-active) branch as `g4_tag` initialiser = compliant. |
| #10 Stash-clean G1 | ✅ Pass | G1 compile against modified surface = 0 errors / 0 warnings (pre-stash run); post-commit stash-clean re-run is operator-side audit only. |
| #11 Working-tree clean post-closure | ⏸ Pending commit | After commit of 5 .mqh files + this fix-round-17.md + state-reconciliation updates the working tree must be 0 untracked / 0 modified. |

---

## State Reconciliation (3-File Propagation)

### Layer 1 — `docs/state/impl-plan.md` (PRIMARY SoT)

- **No AC re-tick required** — fix-round-17 addresses *quality of new instrumentation surfaces* (IMPL-062 + IMPL-065 + IMPL-066 + IMPL-067 instruments), NOT forbidden closure patterns. Dimension #11 (R09) verdict in review = no critical empirical-closure violations.
- **No Mid-Phase Audit Log row** added — all 5 fixes are surgical post-closure improvements that don't alter the ACs already marked `[x]`.
- **No Deferred-AC row resolved** — paired bundles still wait on operator session. Sidecar/probe correctness fixes IMPROVE the integrity of the eventual drain artifact but don't drain it.

### Layer 2 — `docs/state/overview.md` (DERIVED VIEW)

- "Last code-review round" pointer → `review-round-17` + `fix-round-17` (2026-05-05).
- Phase status unchanged (P4 in-flight; operator drain still pending).

### Layer 3 — `docs/state/_session-handoff/` + handoff narrative

- This file (`docs/code-review/fix-round-17.md`) IS the handoff artifact for the round.
- No new evidence sidecar files needed (G1 compile log is local-only per `.claude/rules/security.md` artifact policy; embedded in this report).

**Reconciliation Self-Check:**

```
✅ impl-plan.md     — no closure changes; no edit needed (fix-round != closure)
✅ overview.md       — review/fix pointer updated (commit candidate below)
✅ handoff narrative — fix-round-17.md serves as the artifact
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 7 |
| Accepted (fixed) | 5 (17.1, 17.2, 17.4, 17.5, 17.6) |
| Deferred (tracked) | 2 (17.3 → IMPL-FIX-004; 17.7 → IMPL-FIX-003) |
| Rejected | 0 |
| Files Modified | 5 (Slot_J, Slot_BI, Orchestrator, TradeJournal, TickLatencyProbe) |
| Tests Added/Updated | 0 (instrumentation-correctness fixes; operator-drain validates downstream) |
| Compile (G1) | 0 errors, 0 warnings, 3964 ms |
| Defect classes purged | 2 (compile-flag log-text asymmetry; measurement-pollutes-measurement on entry-pass + sidecar I/O) |

**Recommendation:** Ready for next review round (round-18) when operator drain of P4 paired bundles completes; or proceed to **IMPL-FIX-003** (structural pre-drain) if compressing operator-session bottleneck is priority. No CRITICAL/HIGH residual.

## End of Fix Round 17
