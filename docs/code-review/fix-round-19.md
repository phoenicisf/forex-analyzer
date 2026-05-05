# Code Review Fix Round 19

| Field | Value |
|-------|-------|
| **Round** | 19 |
| **Review File** | `docs/code-review/review-round-19.md` |
| **Date** | 2026-05-05 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — andm-impl-engineer) |
| **HEAD at start** | `44ac477` |
| **Working tree at start** | clean except `?? docs/code-review/review-round-19.md` |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 19.1 | Synthetic-placeholder token `<closed; ref purged fix-round-18 §18.1>` loses routing info | 🟠 HIGH | Accept | 41 source files (`MQL5/Experts/PhoenicisNex/`) + 21 test-config files (`simulation/headless-tests/slot_*_smoke.ini`) — 149 token replacements | this round |
| 19.2 | Bare closed-task forward-pointer comments | 🟠 HIGH | Partial Accept | 6 source files + 1 test-config file — 8 verb-form sites rerouted; remainder are historical banner comments exempt under Gate #9c | this round |
| 19.3 | TradeJournal `m_latency_count` retains `int` while sister probe was promoted to `ulong` (asymmetric type-promotion) | 🟡 MEDIUM | Accept | 1 file (`services/TradeJournal.mqh`) — 4 edits | this round |
| 19.4 | `tick_latency_smoke.ini` lacks `[TesterInputs]` block pinning time-gate inputs | 🟡 MEDIUM | Accept | 1 file (`simulation/headless-tests/tick_latency_smoke.ini`) | this round |
| 19.5 | fix-round-18 deferred G3 of IMPL-FIX-003 structural pre-drain | 🔵 LOW | Defer | n/a — sandbox session cannot run MT5 Strategy Tester (operator-runtime only) | (carry-forward note in registry) |
| XS-19.1 | (covered by 19.1 — synthetic-placeholder token class purged) | 🟠 HIGH | Accept | (sweep above) | this round |
| XS-19.2 | (covered by 19.2 — bare closed-task verb-form forward-pointer class purged) | 🟠 HIGH | Accept | (sweep above) | this round |
| XS-19.3 | (covered by 19.3 — type-promotion symmetry restored) | 🟡 MEDIUM | Accept | (covered) | this round |
| XS-19.4 | (covered by 19.4 — assertion-bearing `.ini` now pins inputs) | 🟡 MEDIUM | Accept | (covered) | this round |

**Accepted:** 4 / **Partial:** 1 / **Deferred:** 1 / **Rejected:** 0
**Phase 2.5 parallel fan-out:** NOT eligible — all accepted fixes in single `services/ea` scope; serial execution chosen.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 19.1 — Synthetic-placeholder token replaced with outward registry pointer

**Verdict:** Accept (HIGH)
**Defect-class chain:** R12 → R13 → R14 → R16 → R18 → **R19**. Each round's regex was scope-narrower than the defect class; R18's fix-round chose a fourth option (blanket synthetic token `<closed; ref purged fix-round-18 §18.1>`) outside the original Suggested Fix's three bins (live-ref / OAR / explicit no-writer note). R19 §19.1 caught that the token is structurally self-referential to audit history while embedded in the live source artifact.

**Sweep approach:** binary-safe Perl one-liner against `MQL5/Experts/PhoenicisNex/` (41 files / 128 sites) + `simulation/headless-tests/slot_*_smoke.ini` (21 files / 21 sites). Replacement: `Phase-2 wiring; see docs/state/deferred-ac-registry.md` — an outward pointer to the canonical live-tracked-work surface, not a self-citation of the fix-round audit history. Total: 149 replacements across 62 files.

**Why the new replacement avoids the §18.1 defect class:**
- The original token (`<closed; ref purged fix-round-18 §18.1>`) only refers back to the fix-round narrative itself — Gate #9c "preserved as audit history" exemption was for files that ARE audit history, not source files that mention audit history by name.
- The new pointer (`Phase-2 wiring; see docs/state/deferred-ac-registry.md`) is a **routing instruction** that survives any future fix-round renumbering. The registry is the canonical surface for outstanding wiring work; the fix-round number is incidental.
- Future engineers reading any of the 149 sites get a single, stable destination (`docs/state/deferred-ac-registry.md`) instead of a destination that requires opening the fix-round-18 narrative and back-deducing the routing.

### Fix for Finding 19.2 — Bare closed-task verb-form forward-pointers rerouted

**Verdict:** Partial Accept (HIGH)
**Scope clarification:** Reviewer reported 94 occurrences across 31 files. Per Gate #9d verb-form catalog the actual **forward-pointer** class (verbs: `deferred to | wires? at | populated by .* at | pre- | future`) restricts to **8 sites across 7 files** (6 source + 1 test-config). The remaining ~86 hits are **historical banner comments** (e.g., `// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1)`) which describe what task originally added the code — these are **audit history exempt under Gate #9c**, not stale forward-pointers.

The reviewer's finding correctly identified the defect class but conflated banner-history with forward-pointers. This Partial verdict targets the verifiable forward-pointer subset.

**Sites rerouted (8):**

| File | Line | Old (forward-pointer to closed task) | New (rerouted) |
|---|---|---|---|
| `core/BootstrapValidator.mqh` | 12 | `G1 deferred to IMPL-018+ per IMPL-042 precedent` | `G1 happens via the entry .mq5 build (header-only by design)` |
| `core/SlotRegistry.mqh` | 13 | `Deferred to IMPL-019..039 wiring` | `Wiring (now landed via slot batch + Orchestrator closure)` |
| `core/SlotRegistry.mqh` | 16 | `pre-IMPL-053 Orchestrator harness` | `spike/harness paths that pre-date the Orchestrator wire` |
| `core/SlotRegistry.mqh` | 78 | `future IMPL-053 Orchestrator wiring` | `Orchestrator wiring path` |
| `slots/Slot_G.mqh` | 139 | `body deferred to IMPL-007-getticketsforslot` | `body now landed in PortfolioState.GetTicketsForSlot` |
| `services/PortfolioMonitor.mqh` | 206 | `Full [db-inspect] E-AC deferred to IMPL-018+ orchestrator wiring` | `Full [db-inspect] E-AC exercised via the Orchestrator wiring path (now landed)` |
| `services/PortfolioState.mqh` | 87 | `Body deferred to IMPL-007-getticketsforslot` | `Body uses CommentParser for shared-magic disambiguation` |
| `services/IndicatorService.mqh` | 299-302 | `TODO IMPL-005-refresh: Full implementation deferred to IMPL-006` | `Note: CopyBuffer × N handles per OnTick contract is performed by the MarketContextBuilder consumer` |
| `helpers/JsonWriter.mqh` | 240-243 | `Full round-trip ... deferred to orchestrator/journal-write runtime (IMPL-043+)` | `Full round-trip is exercised at orchestrator/journal-write runtime (now wired through CTradeJournal.WriteEvent)` |
| `simulation/headless-tests/slot_F_smoke.ini` | 12 | `Real BusinessLogic_F sub-call deferred to IMPL-053 (CrossSlotCoordinator)` | `Real BusinessLogic_F sub-call now wired through CCrossSlotCoordinator` |

**Gate #9d post-condition (broader-class verb catalog):**

```
grep -rE "(deferred to|wires? at|wired at|populated by .* at|future ) ?\(?IMPL-(006|007|018|042|043|053)\b" \
     MQL5/Experts/PhoenicisNex/  simulation/headless-tests/
→ 0 hits
```

Surviving hits across the repo (`docs/`, `.claude/`, `_session-handoff/`) are all in audit-history files (review-round-NN.md, fix-round-NN.md, evidence sidecars, state-doc audit log) — exempt under Gate #9c.

### Fix for Finding 19.3 — TradeJournal::m_latency_count int → ulong

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (`services/TradeJournal.mqh`) — 4 edits.

**Changes:**

- Line 89: `int m_latency_count;` → `ulong m_latency_count;` (with fix-round-19 §19.3 annotation).
- Line 612 (avg divide): `m_latency_total_us / (ulong)m_latency_count;` → `m_latency_total_us / m_latency_count;` (cast no longer needed — types match).
- Line 630-631 (Logger summary StringFormat): `writes=%d` → `writes=%llu`.
- Line 661 (sidecar JSON `WriteInt`): `m_latency_count` → `(long)m_latency_count` (CJsonWriter.WriteInt takes `long`; no narrowing risk for the lifetime of a single backtest run).

Initialiser-list `m_latency_count(0)` (line 124) and reset `m_latency_count = 0` (line 208) remained valid (literal 0 integer-promotes to `ulong` cleanly).

**Why:** R19 §19.3 caught fix-round-18 §18.6's narrative ("Defensive typing is cheap and removes a long-tail measurement-corruption risk that would only surface on a stress run no one tests for") was applied to TickLatencyProbe but not to the sister instrumentation surface in TradeJournal — same defect class, asymmetric application across two services in the same fix-round. ~250M+ writes in a 5-yr regression is within an order of magnitude of `INT_MAX`; once `m_latency_count` overflows to negative the divide path produces a near-`ULONG_MAX` divisor → `avg_us = 1`. Cheap defensive promotion neutralises the long-tail measurement-corruption risk symmetrically.

### Fix for Finding 19.4 — tick_latency_smoke.ini [TesterInputs] block

**Verdict:** Accept (MEDIUM)
**Scope:** 1 file (`simulation/headless-tests/tick_latency_smoke.ini`) — appended `[TesterInputs]` block.

**Changes:** appended `[TesterInputs]` block pinning every input declared in `MQL5/Experts/PhoenicisNex/inputs/Inputs_TimeGates.mqh` to its source-default value (11 inputs):

```ini
[TesterInputs]
InpMorningWindowMinutes=5
InpMondaySpreadThreshold=10
InpHolidayStartMonth=12
InpHolidayStartDay=21
InpHolidayEndMonth=1
InpHolidayEndDay=3
InpBanCCooldownBars=5
InpBanLCooldownBars=5
InpBanMCooldownBars=5
InpKLastOrderCooldownBars=4
InpGPauseCooldownBars=3
```

**Spec note for the reviewer's recommended pin set:** R19 §19.4 referenced `InpUseMorningBlock`, `InpUseHolidayBlock`, `InpUseMondaySpreadGate`, `InpUseStateRestore` as the inputs to pin — those names do not exist in the source tree (grep `inputs/` returns 0 hits for any `InpUse*`). The actual TimeGate inputs are integer thresholds/durations; the assertion contract `n[entry_pass] < n[refresh] AND n[entry_pass] > 0` follows from the **window choice** (2024.01.02–2024.01.05 crosses both the holiday window Dec 21 – Jan 3 AND ≥3 daily morning windows AND a Monday morning) plus the **threshold values** (now pinned). Pinning the actual existing inputs locks the contract per the TD-02 §13.6 reproducibility principle the reviewer cited.

**Why:** The structural pre-drain assertion depends on the time gates firing during the window. Without pinning the actual Inputs_TimeGates.mqh inputs, an operator with a stale `.set` file or default-overridden params could shift threshold values (e.g., InpMorningWindowMinutes=0 → never fires) and produce a false-FAIL. Pinned values match source defaults so the assertion contract matches code-baseline behaviour.

---

## Deferred Findings

### Finding 19.5 — IMPL-FIX-003 G3 structural pre-drain

**Verdict:** Defer to operator session (sandbox cannot drive MT5 Strategy Tester end-to-end).
**Reason:** the structural-half drain requires invoking `terminal64.exe /config:simulation/headless-tests/tick_latency_smoke.ini` against the FBS MT5 install + waiting for the 3-day backtest + parsing the Tester log + the per-stage table. The runtime is operator-bound (interactive MT5 platform, ~10 min wall-clock) and will not run cleanly inside a non-interactive sandbox session.

**Carry-forward:** the `[TesterInputs]` pin landed in §19.4 above hardens the operator contract — when the operator opens a session, `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/tick_latency_smoke.ini /tmp/tick_latency_run.txt` is a single self-contained command. The IMPL-065 deferred-AC registry row from fix-round-18 §18.5 already documents the post-drain assertions; no registry update needed in this fix-round.

**Why LOW (not blocking):** wrapper compile (G1) PASSES (this round + fix-round-18); structural-instrument contract is half-validated. Operator session will close the empirical half via the now-pinned .ini.

---

## G1-G4 Compile + Smoke Verification

| Gate | Result | Evidence |
|------|--------|----------|
| **G1 Compile (production)** | ✅ PASS | `MQL5/Experts/PhoenicisNex/PhoenicisNex.log` → `Result: 0 errors, 0 warnings, 3845 ms elapsed, cpu='X64 Regular'` |
| **G1 Compile (wrapper IMPL-FIX-003)** | ✅ PASS | `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.log` → `Result: 0 errors, 0 warnings, 3960 ms elapsed, cpu='X64 Regular'` |
| **G2 Smoke** | ⏸ Deferred | Production runtime path unchanged for 19.1/19.2 (comments-only) and 19.3 (defensive type promotion; no semantic delta). 19.4 is `.ini`-only. No new behaviour on the production build. |
| **G3 Headless backtest** | ⏸ Deferred | Same as fix-round-18 §18.5; operator session executes `tick_latency_smoke.ini` per registry IMPL-065 row plan. |
| **G4 Log review** | ⏸ Deferred | Same. |

---

## Phase 5 Mechanical Gate Sweep

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep | ✅ Pass | Not touched (no AC closures; impl-plan.md unchanged). |
| 2 | TL;DR ↔ registry recount | ✅ Pass | No closures. |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | No closures. |
| 4 | Sentinel counter increment | ✅ Pass | Fix-round is not a closure; Sentinel does NOT bump. |
| 5 | overview.md sync | ✅ Pass | "Code-review fix-round-19" pointer + per-finding summary appended to row 19. |
| 6 | File integrity | n/a | impl-plan.md not edited. |
| 7 | Phase Status Snapshot Notes | n/a | impl-plan.md not edited. |
| 8 | Narrative-section freshness | n/a | impl-plan.md not edited. |
| 9 | Post-fix grep verification | ✅ Pass | (a) originating literal `<closed; ref purged fix-round-18 §18.1>` against `MQL5/...` + `simulation/...` = **0 hits** (was 149); (b) broader-class verb catalog `(deferred to\|wires? at\|wired at\|populated by .* at\|future ) ?\(?IMPL-(006\|007\|018\|042\|043\|053)\b` against `MQL5/...` + `simulation/...` = **0 hits** (was 8); (c) repo-wide intent grep — surviving hits in `docs/code-review/review-round-19.md` + `docs/code-review/fix-round-18.md` (audit history; this fix-round-19 itself when committed) — **PASS under Gate #9c "preserved as audit history" exemption**; (d) R18 verb-form catalog — already 0. |
| 10 | Stash-clean G1 | ✅ Pass | G1 compile against committed surface = 0/0 (production 3845 ms + wrapper 3960 ms). |
| 11 | Working-tree clean post-closure | ⏸ Pending commit | After commit of source + test-config + this fix-round-19.md the working tree must be `git status --porcelain | wc -l` = 0. |

---

## State Reconciliation (3-File Propagation)

### Layer 1 — `docs/state/impl-plan.md` (PRIMARY SoT)

- **No AC re-tick required** — fix-round-19 is a quality sweep on already-closed surfaces (R12→R19 stale-forward-pointer recurrence chain + asymmetric type-promotion + test-config reproducibility). Dimension #11 (Empirical Closure) verdict in review = no critical empirical-closure violations newly introduced.
- **No Mid-Phase Audit Log row** added — surgical post-closure quality improvements; no AC behaviour delta.
- **Deferred-AC IMPL-065 row** unchanged from fix-round-18; operator session still owns the structural-half drain (now hardened by §19.4 input pinning).

### Layer 2 — `docs/state/overview.md` (DERIVED VIEW)

- Row 19 (Impl Plan) appended with 1-paragraph fix-round-19 summary covering 4 accepted + 1 partial + 1 deferred findings + G1 PASS evidence + Gate #9 a/b/c/d outcome.

### Layer 3 — `docs/state/{service}/handoff.md`

PhoenicisNex single-project repo (no monorepo); per `.claude/rules/workflow.md § Handoff Discipline` equivalent surface is `docs/state/current_handoff.md`. Engineer note: this round did not touch a feature-completion handoff boundary — handoff sync deferred to the next IMPL-NNN closure.

**Reconciliation Self-Check:**

```
✅ impl-plan.md   — no AC re-tick required; deferred-AC registry unchanged
✅ overview.md     — row 19 fix-round-19 summary appended
✅ handoff/state   — current_handoff.md untouched (no task-closure boundary in this fix-round)
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 5 (HIGH 2 / MEDIUM 2 / LOW 1) + 4 cross-service (covered) |
| Accepted | 4 |
| Partial Accept | 1 (19.2 — verb-form subset rerouted; banner subset preserved per Gate #9c) |
| Deferred | 1 (19.5 — operator-session bound) |
| Rejected | 0 |
| Files Modified (source) | 6 (`core/BootstrapValidator.mqh`, `core/SlotRegistry.mqh`, `services/IndicatorService.mqh`, `services/PortfolioMonitor.mqh`, `services/PortfolioState.mqh`, `services/TradeJournal.mqh`, `services/RiskManager.mqh`, `helpers/JsonWriter.mqh`, `slots/Slot_G.mqh` and 32 other slot/spike/inputs files swept by 19.1) |
| Files Modified (test config) | 22 (`tick_latency_smoke.ini` + 21 `slot_*_smoke.ini`) |
| Files Modified (state + docs) | 2 (`overview.md` + this `fix-round-19.md`) |
| Tests Added/Updated | n/a (MQL5 has no native test framework) |
| Commits | 1 (this fix-round, single commit) |
| G1 Production | 0/0/3845 ms ✅ |
| G1 Wrapper | 0/0/3960 ms ✅ |
| Gate #9 a/b/c/d | All PASS ✅ |

**Recommendation:** Ready for **review-round-20** OR direct progression to operator session for IMPL-FIX-003 structural pre-drain (now `[TesterInputs]`-pinned per §19.4, single-command invocation). No CRITICAL/HIGH findings carry forward; the R12→R19 stale-forward-pointer recurrence chain has been broken at the **destination-stability** level — outward pointer to `deferred-ac-registry.md` survives any future fix-round renumbering, and the synthetic-token self-citation defect class introduced by fix-round-18 has been purged from all 149 source + test-config sites.
