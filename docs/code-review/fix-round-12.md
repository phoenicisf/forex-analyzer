# Code Review Fix Round 12

| Field | Value |
|-------|-------|
| **Round** | 12 |
| **Review File** | `docs/code-review/review-round-12.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source files touched** | 17 (1 .ini + 1 .ps1 + 1 .py + 1 .mqh domain + 1 .mqh services + 11 .mqh slots + 1 doc + 1 registry + 1 plan) |
| **G1 verification** | Entry `PhoenicisNex.mq5` 3752 ms + Spike_Orchestrator 723 ms + Spike_CrossSlotCoordinator 763 ms + Spike_EAState 1106 ms — all `Result: 0 errors, 0 warnings`. PowerShell harness ParseFile OK + DryRun PASS. parse_baseline.py round-trip on 5-yr fixture: sum = total_net_profit = $24,271,276.63 exact (delta=0.00) + parse_anomaly_count=0. |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 12.1 | Harness inspect path != spike write path | 🔴 CRITICAL | **Accept** | atomic_write_kill.ini + nfr-3.1-atomic-write-result.md § 2.3 | bundled |
| 12.2 | `IsPhoenicisMagic` range admits 202/203/204 | 🟠 HIGH | **Accept** | EnumTypes.mqh | bundled |
| 12.3 | 50-500ms kill window pre-empts MT5 startup | 🟠 HIGH | **Accept** | atomic_write_kill_100.ps1 (poll-then-attack + counter) | bundled |
| 12.4 | `.ini` lacks `[TesterInputs]` override | 🟡 MEDIUM | **Accept** (subsumed by 12.1 fix) | atomic_write_kill.ini | bundled |
| 12.5 | `parse_baseline.py` silent ValueError fallback | 🟡 MEDIUM | **Accept** | parse_baseline.py + baseline-per-slot.json regen | bundled |
| 12.6 | CircuitBreaker pre-Init guard missing | 🟡 MEDIUM | **Accept** | CircuitBreaker.mqh | bundled |
| 12.7 | IMPL-068 expiry blocked on unstarted IMPL-062 | 🔵 LOW | **Accept** | deferred-ac-registry.md (IMPL-068 row) + impl-plan.md (R-7) | bundled |
| 12.8 | `Slot_S:224` "deferred to IMPL-053+" stale | 🔵 LOW | **Accept** | 11 slot files | bundled |
| XS-12.1 | Two parallel is-our-magic predicates | — | **Accept** (subsumed by 12.2 fix) | — | bundled |
| XS-12.2 | Doc § 2.3 vs harness behaviour divergence | — | **Accept** (subsumed by 12.1 + 12.4 fix) | — | bundled |
| XS-12.3 | Slot_S stale comment propagates to all slots | — | **Accept** (subsumed by 12.8 fix) | — | bundled |

**Accepted:** 8/8 base findings (+ 3/3 cross-service, all subsumed).
**Rejected:** 0.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 12.1 (CRITICAL) + 12.4 (MEDIUM) — `[TesterInputs]` override + doc amendment

**Approach.** The `simulation/headless-tests/atomic_write_kill.ini` was authored for IMPL-046 sandbox spike (which writes to `PhoenicisNex/spike/state.json` deliberately). Reusing it for IMPL-064's external PowerShell-driven kill harness required the spike's input parameters to be redirected to the production state path that the harness inspects, otherwise every trial reports `state_missing_tmp_missing` (acceptable per ADR-007) and `verdict=PASS` despite zero atomic writes ever being raced.

Added a `[TesterInputs]` block to the `.ini` overriding four input parameters of `Spike_AtomicWrite`:

| Override | Purpose |
|---|---|
| `InpStateFile=PhoenicisNex/state/state.json` | Match harness inspect path |
| `InpTmpFile=PhoenicisNex/state/state.json.tmp` | `.tmp` orphan visibility |
| `InpTotalWrites=100000` | Window large enough that 50-500ms kill always lands inside an active write iteration (paired with Finding 12.3 fix) |
| `InpKillTrials=0` | Disable the spike's internal Phase 2; external PowerShell `Stop-Process` alone owns kill semantics |

Amended `docs/state/nfr-3.1-atomic-write-result.md § 2.3` from "no modification required" to a UPDATED 2026-05-04 section with a 4-row override table + cross-link to fix-round-12 §12.1+§12.3+§12.4. The IMPL-046 sandbox usage path (running `Spike_AtomicWrite.mq5` directly without the .ini) keeps the spike's input defaults authoritative, so this change is non-breaking for the original spike contract.

**Changes:**
- `simulation/headless-tests/atomic_write_kill.ini` — header banner expanded to document dual consumer (IMPL-046 sandbox vs IMPL-064 harness) + `[TesterInputs]` block added.
- `docs/state/nfr-3.1-atomic-write-result.md` — § 2.3 rewritten with override table + non-breaking guarantee for the original spike sandbox.

### Fix for Finding 12.2 (HIGH) — `IsPhoenicisMagic` set membership

**Approach.** Replaced the literal range check `magic >= 200 && magic <= 219` with an explicit ladder over the 17 registered `MAGIC_*` constants. The MQL5 compiler rejects `switch(magic) { case MAGIC_CD: ... }` because `static const int MAGIC_*` declarations are not constant expressions in MQL5 (`error 188`); used an `||` chain comparing against each named constant instead. Added a doc-comment explicitly noting that the chain is the single source of truth alongside `PHOENICISNEX_MAGIC_COUNT` and must mirror any future `MAGIC_*` addition or removal.

Magics 202, 203, 204 (gaps in the non-contiguous slot range) are now rejected at the OnTradeTransaction surface (`Orchestrator.mqh:739` caller already passes through this helper), preventing a foreign EA on EURUSD from feeding BR-3.6 and triggering false-positive ping-pong halts. This closes the partial regression of fix-round-11 § 11.2 noted in review-round-12 and aligns the trade-transaction surface with `services/CrossSlotCoordinator.mqh::_AggregateWeakMetrics`'s stricter set-membership check (XS-12.1).

**Changes:**
- `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh` — comment block reworded; helper body switched from range to `||` chain over MAGIC_* constants.

### Fix for Finding 12.3 (HIGH) — Poll-then-attack + startup-timeout counter

**Approach.** Added a bounded poll inside the per-trial loop that waits up to 60 seconds for `state.json` or `state.json.tmp` to appear before applying the random 50-500ms attack offset. If the deadline expires without a write target, the trial is marked `startup_timeout_count++`, the terminal is killed, the `.tmp` orphan cleaned, and the loop continues — but the verdict is gated on `startup_timeout_count == 0`, so any run with non-zero startup timeouts fails closed instead of false-PASS.

Bumped `InpTotalWrites` to `100000` via `[TesterInputs]` (Finding 12.1 fix) so the random 50-500ms attack window always lands inside an active iteration of the spike's Phase 1 write loop. Added the `startup_timeout_count` counter to:
- per-trial Verbose output
- 10-trial progress line
- final aggregate verdict line + warning emit
- JSON sidecar (`startup_timeout_count` field at top-level)
- DryRun sidecar shape (so the schema is consistent across modes)

Total accounting is updated to include the timeout bucket (`total = parse_pass + parse_fail + state_missing_tmp_present + state_missing_tmp_missing + startup_timeout_count`) so per-bucket counts always sum to `Trials`.

**Changes:**
- `simulation/scripts/atomic_write_kill_100.ps1` — counter declaration + poll loop + warn-on-timeout branch + aggregate gate + verdict warning + sidecar field (DryRun + production paths).

### Fix for Finding 12.5 (MEDIUM) — `parse_baseline.py` parse-anomaly counter + stderr warnings

**Approach.** `_parse_deals` now returns `(trades, parse_anomaly_count)` instead of bare `trades`. Each `ValueError` on swap or profit `float()` increments the counter and emits a stderr warning identifying the offending deal id and the unparseable cell content (≤30 chars). Final stderr summary line emits if any anomaly fired, telling IMPL-062 regression to treat the baseline as untrusted.

`_build_output` accepts `parse_anomaly_count` (default `0` for backward compat) and adds a top-level `parse_anomaly_count` field to the output JSON so downstream IMPL-062 logic can refuse to compute drift against a tainted baseline. Re-ran the parser against the 5-yr fixture (`docs/foundation-input-sources/ReportTester-25045474.html`) — sum of per-slot net_pnl = `$24,271,276.63` matches `total_net_profit` exactly (delta=0.00); `parse_anomaly_count=0` confirming no malformed cells in the current baseline. Regenerated `docs/state/baseline-per-slot.json` to include the new field.

**Changes:**
- `simulation/scripts/parse_baseline.py` — `_parse_deals` signature + counter + stderr emits + summary; `_build_output` signature + JSON field; `parse_baseline` orchestrator unpacks the tuple.
- `docs/state/baseline-per-slot.json` — regenerated with `parse_anomaly_count: 0` field.

### Fix for Finding 12.6 (MEDIUM) — CircuitBreaker pre-Init defense-in-depth

**Approach.** Added Option B early-return guards to `CCircuitBreaker::RecordOpen` and `CCircuitBreaker::RecordClose`: if `m_logger == NULL`, emit a stable Print fallback `[CircuitBreaker][WARN] Record{Open,Close} pre-Init dropped: magic=… dir=… t=…` and return BEFORE `_WriteEvent` writes into the ring buffer. This is the dual-gate posture review-round-11 § 11.3 originally recommended; fix-round-11 chose Option A (orchestrator-side `m_init_complete`) only and is preserved.

The guard is cheap (1 null-check on the hot path) and protects future Phase 2 RiskManager::OpenOrder wiring per TD-02 §5.8 from a pre-OnInit broker-recovery dispatch that could otherwise corrupt the ring buffer with garbage events. Inline comment cites both the fix-round-11 trade-off and the Phase 2 caller surface that motivates the dual gate.

**Changes:**
- `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh` — `RecordOpen` + `RecordClose` bodies guarded; banner comments updated.

### Fix for Finding 12.7 (LOW) — IMPL-068 + IMPL-062 dependency annotation

**Approach.** Chose option (a) from the review (explicit annotation) over (b) preemptive expiry extension, so the 14d guideline stays intact and the prereq is visible to operators reading the registry. Prepended `**Blocks: IMPL-062**` to the `Deferred reason` cell of the IMPL-068 row in `docs/state/deferred-ac-registry.md` plus a 1-line note pointing at impl-plan.md R-7 (single-renewal cycle to 2026-06-01 if IMPL-062 slips past 2026-05-11).

Added `R-7` row to `docs/state/impl-plan.md § Open Risks` with concrete dates: today 2026-05-04 → IMPL-068 expiry 2026-05-18 → realistic drain ≥ IMPL-062 close + 1 walk session ≈ 1 week → IMPL-062 must start within 2-3 days OR proactively extend. R-7 is positioned above R-6 in the list (newer Open Risks add to the top per CLAUDE.md convention).

**Changes:**
- `docs/state/deferred-ac-registry.md` — IMPL-068 row Deferred-reason cell prepended.
- `docs/state/impl-plan.md` — Open Risks R-7 added.

### Fix for Finding 12.8 (LOW) + XS-12.3 — Slot stub comments updated across 11 files

**Approach.** Grepped `slots/` for "OrderSend deferred to IMPL-053+" / "OrderSend deferred to Orchestrator wiring (IMPL-053+)" / "OrderSend deferred to orchestrator wiring" and updated all 11 files (Slot_S, Slot_BI, Slot_C, Slot_G, Slot_G2, Slot_I, Slot_LX, Slot_M, Slot_P [×2 occurrences], Slot_Q, Slot_R, Slot_T) with a consistent message:

> Phase 1 emits entry_signal Logger.Info as the observable milestone; actual OrderSend wiring lives in `RiskManager::OpenOrder` per `.claude/rules/ea.md` (IMPL-017 + IMPL-062 5-yr regression).

The stale framing — "deferred to IMPL-053+" — was misleading because IMPL-053..060 are closed but did not wire OrderSend; the actual wiring lands at IMPL-017 + IMPL-062 + IMPL-063 per the regression chain. Slot_P had two affected sites (PSUB_E pyramid path and PSUB_PX/PH default path); both updated. Logger.Info format strings that embedded the stale phrase ("(Phase-1 stub: OrderSend deferred to IMPL-053+)") were also updated to "(Phase 1 logger-only; OrderSend at IMPL-017/IMPL-062)" so journal records carry the correct reference for Tier 1.5 walk batch-2 evidence.

**Changes:**
- 11 slot files in `MQL5/Experts/PhoenicisNex/slots/` — comment blocks reworded; 2 Logger.Info format strings updated.

---

## Rejected Findings — Evidence

None — all 8 base findings + 3 cross-service findings accepted.

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 11 (8 base + 3 cross-service) |
| Accepted | 11 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 17 |
| G1 Compile Gate | ✅ Entry .mq5 + 3 spikes (Orchestrator/CrossSlotCoordinator/EAState) all 0 errors / 0 warnings |
| Python smoke | ✅ parse_baseline.py round-trip on 5-yr fixture: delta=0.00, parse_anomaly_count=0 |
| PowerShell smoke | ✅ ParseFile clean + DryRun verdict=DRY_RUN with `startup_timeout_count` field present in sidecar schema |

**Recommendation.** Ready for `/impl-review all` R13 OR Tier 1.5 walk batch-2 (operator session: close foreground MT5 → run `pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 100` against the corrected `.ini`+harness pair → drain IMPL-064 numeric verdict). Recommend the walk first since R12 explicitly flagged that the harness contract was the heaviest defect cluster of the round (12.1 CRITICAL + 12.3 HIGH + 12.4 MEDIUM), and the walk now gives the harness an empirical pass with the corrected contract — `/impl-review all` R13 then captures the walk artifact + remaining state.

Plan Staleness Sentinel: 6 closures since R07 — within 10-closure threshold ✅; this fix-round counts as 1 additional closure → 7 since R07. Mid-Phase Audit P4 counter at 6 ≥ 5 trigger remains advisory.

---

## State Reconciliation (CLAUDE.md § 6 — 3-File Propagation)

| Layer | File | Update |
|-------|------|--------|
| Layer 1 | `docs/state/impl-plan.md` | Open Risks R-7 added (IMPL-068 + IMPL-062 timing dependency) |
| Layer 1 | `docs/state/deferred-ac-registry.md` | IMPL-068 row deferred-reason cell annotated `**Blocks: IMPL-062**` |
| Layer 1 | `docs/state/baseline-per-slot.json` | regenerated with `parse_anomaly_count: 0` field |
| Layer 1 | `docs/state/nfr-3.1-atomic-write-result.md` | § 2.3 amended with [TesterInputs] override table |
| Layer 2 | `docs/state/overview.md` | last-code-review pointer → R12 ✅ fix-round-12 (handled by overview.md auto-sync per /next workflow; deferred to next /next run) |
| Layer 3 | `docs/state/_session-handoff/*` | n/a — fix-round is not a task closure (no `[x]` AC flips) |

Reconciliation Self-Check:
- ✅ impl-plan.md — R-7 row added (no AC flips; no Active deferred-AC entries resolved)
- ⏸ overview.md — defer to next `/next` run (not blocking commit per fix-round practice in R10/R11)
- ✅ deferred-ac-registry.md — IMPL-068 row annotated
- ✅ baseline-per-slot.json — schema field added with backward-compat default

No forbidden closure patterns introduced. Existing forbidden-pattern grep on `impl-plan.md` for `deferred to operator-runtime` / `deferred per .* precedent` / `structurally complete.*deferred` / `live verification deferred` remains 0 hits ✅.
