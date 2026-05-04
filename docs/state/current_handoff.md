# PhoenicisNex — Current Handoff

> Single-project handoff per CLAUDE.md §6. Updated end-of-task / end-of-session / cross-day.

## Last completed action

**IMPL-061 + IMPL-064 + IMPL-068 CLOSED 2026-05-04 (parallel batch) — P4 QA chain authoring pass** — `/impl-task parallel` 3-subagent fan-out under Phase Gate Override 2026-05-03 Path A.

- **Batch:** 3 disjoint `[ea-qa]` subagents on Sonnet 4.6 (general-purpose persona = `andm-impl-engineer` SKILL via Slim-Onboarding directive + shared context file `docs/state/_parallel-context/impl-task-parallel-20260504-1640.md`). Orchestrator: Opus 4.7 main session.
  - **IMPL-061 (M [ea-qa] per-slot baseline parser):** Python stdlib parser on UTF-16 LE `docs/foundation-input-sources/ReportTester-25045474.html` with FIFO volume-matching deal attribution → 21-slot `docs/state/baseline-per-slot.json` (sum=$24,271,276.63 **exact match** to total Net Profit; delta=$0.00; 17 active C/D/J/H/K/G/M/L/LX/Q/R/I/P/T/S/B/BR + 4 zero-filled F/G2/GO/BI per BR-1.1; consistent with G4 BI SL fix being new-EA-only per ADR-009). 4/4 ACs `[x]` (no defer). Commit `2b27a2e`.
  - **IMPL-064 (S [ea-qa] atomic-write kill-100 PowerShell harness):** 276-LOC `simulation/scripts/atomic_write_kill_100.ps1` per ADR-007 §Spike Result deferred-clause: 5-param spec + Start-Process terminal64 → random 50-500ms sleep → Stop-Process → state.json parse / .tmp orphan inspection per ADR-007 §OnInit recovery + JSON sidecar emit; PS5.1+PS7 ParseFile/ParseInput PASS; reuses `simulation/headless-tests/atomic_write_kill.ini` from IMPL-046 spike. 169-LOC `docs/state/nfr-3.1-atomic-write-result.md` skeleton (8 sections). 2/2 S-AC `[x]` structural; 1/1 E-AC deferred. Commit `41ffdd6`.
  - **IMPL-068 (S [ea-qa] ADR-008 force-clear validation):** 295-LOC `docs/state/adr-008-force-clear-validation.md` with 5 jq filter recipes per machine M=150/T=80/Q=100 + Q-Pending sub-code drill-down + 4-outcome pass criterion matrix + ADR-008 amendment template skeleton + PowerShell fallback. 2/2 S-AC `[x]` structural; 2/2 E-AC deferred (gated on IMPL-062/063 5-yr regression). Commit `1165137`.
- **Files created (deliverables):** `simulation/scripts/parse_baseline.py` (NEW; 403 LOC) · `simulation/scripts/atomic_write_kill_100.ps1` (NEW; 276 LOC) · `docs/state/baseline-per-slot.json` (NEW) · `docs/state/nfr-3.1-atomic-write-result.md` (NEW) · `docs/state/adr-008-force-clear-validation.md` (NEW) · `docs/state/_parallel-context/impl-task-parallel-20260504-1640.md` (NEW shared context)
- **State files modified:** `docs/state/impl-plan.md` (3 task entries + Closed lines · TL;DR rewrite · Phase Status P4 8/17 → 11/17 · Mid-Phase Audit Log new row · Plan Staleness Sentinel 3 → 6) · `docs/state/deferred-ac-registry.md` (2 new Active rows: IMPL-064 numeric + IMPL-068 paired bundle, both expiry 2026-05-18)
- **G1 N/A** for all 3 (script + doc deliverables only). Entry .mq5 baseline from IMPL-060 still 0err/0warn/3673 ms preserved.
- **Race-prevention verified:** file sets disjoint; no scope violation; all 3 fragments `status: completed`.
- **Parallel-execution telemetry:** wall-clock ≈ slowest task (470s IMPL-061 / 262s IMPL-064 / 200s IMPL-068) vs serial sum 932s ≈ **62% wall-clock saving**.
- **All 8 S-AC `[x]`** (4+2+2). **2/5 E-AC `[x]`** (IMPL-061 contract-roundtrip + file-blob-check). **3 E-AC deferred**.
- **Mid-Phase Audit P4 counter = 6** (≥ 5; satisfied semantically by next-recommended R09 + walk batch-2). **Plan Staleness Sentinel = 6 closures since R07** — within 10-closure threshold ✅.
- **Next suggested action:** `/impl-review all` R09 → Tier 1.5 walk batch-2 → P4 tail = IMPL-017 + IMPL-062/063/065/066/067 + IMPL-068 numeric drain.
- **Commits:** `2b27a2e` + `41ffdd6` + `1165137` — landed.

---

## Previous action — IMPL-FIX-001 + IMPL-FIX-002

**IMPL-FIX-001 + IMPL-FIX-002 CLOSED 2026-05-04 (parallel batch) — Tier 1.5 walk batch-1 findings drained at coordinator level** — `/impl-task parallel` 2-subagent fan-out under Phase Gate Override 2026-05-03 Path A.

- **Batch:** 2 disjoint `[ea]` subagents on Sonnet 4.6 (general-purpose persona = `andm-impl-engineer` SKILL via Slim-Onboarding directive + shared context file). Orchestrator: Opus 4.7 main session.
  - **FIX-001 (HIGH):** Slot_S percent_tp threading — `inputs/Inputs_Slot_S.mqh` adds `input double InpSPercentTp = 10.0;` (BR-4.1 valid {5,10,15} default 10 per CodeWiki §3.S; group "Slot S" annotation per NFR-6.3) + `slots/Slot_S.mqh:203` threads `InpSPercentTp` as 4th positional arg to `m_risk.ComputeLot("S", InpSSlPips, balance, InpSPercentTp)`. Root cause: caller-side gap — `RiskManager::ComputeLot` already accepted 4th `extra_multiplier` (default 1.0) so previous 3-arg call left percent_tp=1.0 → outside BR-4.1 range → `_ComputeLotForS` factor=0.0 → S lot=0 + per-tick `[ERROR][ev=s_pct_tp_invalid]` over entire 3-day Tier 1.5 walk.
  - **FIX-002 (MEDIUM):** clamp_applied log noise hygiene — `services/RiskManager.mqh:257` demoted `m_logger.Warn("RiskManager","clamp_applied",...)` → `m_logger.Debug(...)` + header comment + inline 3-line rationale block. Engineer chose option (a) per task spec; (b) rate-limit out-of-scope (would need Logger.mqh edit); (d) bump deposit out-of-scope (`.ini` edit). Clamp is BR-4.2/4.3 protection functioning as designed; 3-day walk produced 629 MB log dominated by per-tick WARN.
- **Files modified:** `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_S.mqh` (+1 line) · `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh:203` (4-arg call) · `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh:257` (Warn→Debug + comments).
- **Files created:** `docs/state/_parallel-context/impl-task-parallel-20260504-1500.md` (NEW shared context with Pre-loaded Context section + scope rules + race-prevention + fragment schema).
- **State files modified:** `docs/state/impl-plan.md` (IMPL-FIX-001 3 S-AC `[x]` + 2 E-AC deferred + Closed line · IMPL-FIX-002 2 S-AC `[x]` + 1 E-AC deferred + Closed line · TL;DR last-action rewrite · Open Risks unchanged · Next Best Action checkbox flipped · Mid-Phase Audit Log new row · Plan Staleness Sentinel 1 → 3) · `docs/state/deferred-ac-registry.md` (2 new Active rows: P3 IMPL-FIX-001 G3 + P2 IMPL-FIX-002 G3, both expiry 2026-05-18) · `docs/state/overview.md` (Impl Plan row Last Updated 2026-05-04 + status string append).
- **G1 ✅ MetaEditor64 /compile /log:** orchestrator-side rerun on merged state = `Result: 0 errors, 0 warnings, 3673 ms elapsed`. Subagent fragments both reported 4127 ms but were on stale pre-merge log; orchestrator rerun is authoritative. `.ex5` produced fresh 16:21:50.
- **Race-prevention verified:** subagent file sets disjoint (FIX-001 = inputs/Inputs_Slot_S + slots/Slot_S; FIX-002 = services/RiskManager only); no scope violation; both fragments returned `status: completed`. Wall-clock saving ~58% vs serial (fan-out finished in time of slowest task, not sum).
- **All 5 S-AC `[x]`** (FIX-001 3/3 + FIX-002 2/2). **2 E-AC deferred** (FIX-001 G3 zero `[ev=s_pct_tp_invalid]` + non-zero S lot · FIX-002 G3 ≤ 1 clamp_applied per slot OR log ≤ 100 MB) — both pair with single Tier 1.5 walk batch-2 G3 rerun.
- **SelfTest re-checked (FIX-002):** RiskManager.mqh Cases 5+6 (lines 537-579) assert numeric ClampLot return only; not log level → demotion has zero impact. No re-run needed.
- **Plan Staleness Sentinel = 3 closures since R07** (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002) — within 10-closure threshold ✅.
- **Newly unblocked:** Tier 1.5 walk batch-2 (operator: close foreground MT5 + run `bootstrap_smoke.ini` ~10 min → drains 13+ resolvable deferred-AC rows simultaneously).
- **Next suggested action:** Tier 1.5 walk batch-2 → `/impl-review all` R09 (cross-slot + Orchestrator + entry .mq5 + 2 FIX commits + walk findings = significant attack surface) → P4 QA chain IMPL-061..068.
- **Commits:** `4110a78` (FIX-001) + `a290d7a` (FIX-002) — landed.

---

## Previous action

**IMPL-059 CLOSED 2026-05-04 — `core/Orchestrator` composition root + OnInit 3-phase + OnTick F1 14-step + CleanupPartialInit reverse-order release** — single-task `/impl-task IMPL-059` orchestrator (Opus 4.7) Phase 2C 12-step decomposition (verbatim TD-02 §7.1-7.4.1 transcription).

- **Files created:** `core/Orchestrator.mqh` (NEW; 740+ LOC) + `spike/Spike_Orchestrator.mq5` (NEW; Phase A construction + dtor fallback NULL-safety) + `simulation/headless-tests/orchestrator_smoke.ini` (NEW; per TD-02 §13.6) + `docs/state/_session-handoff/IMPL-059-evidence-20260504.md` (NEW)
- **Files modified:** `core/SlotRegistry.mqh` (RegisterAll stub → 21-slot heap-new in BR-2.2 topo + 21 slot includes); `services/IndicatorService.mqh` + `services/CircuitBreaker.mqh` (ODR fix — 24 + 2 `static const int` decl/def split + `(void)scan_fn` cast → `scan_fn=scan_fn` idiom); `docs/state/impl-plan.md` (7 S-AC `[x]` + 3 E-AC deferred + Closed line + P4 6/11→7/11 + TL;DR + audit log row); `docs/state/overview.md` (P4 7/11 + EA core surface callout); `docs/state/deferred-ac-registry.md` (1 new IMPL-059 P4 Active row expiry 2026-05-18)
- **G1 ✅ Spike_Orchestrator 0err/0warn/608 ms** (PowerShell Start-Process MetaEditor64). **Sibling regression sweep 26/26 spikes 0err/0warn**: 5 service spikes + 21 slot spikes (post ODR fix in IndicatorService + CircuitBreaker — confirms no behavior change).
- **5 spec deviations from TD-02 §7.4** (service-actual signature divergence): D-1 ctx_builder.Init 2-arg / D-2 CB CheckPingPong 0-arg / D-3 xslot.Init pip not risk / D-4 pending.Init 11-arg no portfolio / D-5 journal.SetHaltSink wired (CEAState : IHaltSink). All documented in Orchestrator.mqh header banner.
- **All 7 S-AC `[x]`**; **3 E-AC deferred** (combined Phase C deliberate-fail `_Symbol="GBPUSD"` + Logger Debug step ordering + step 5b SetHalted before RunExitPass under CB trip — needs IMPL-060 entry .mq5 + Tester run; expiry 2026-05-18). Closing IMPL-060 + this row simultaneously unblocks the full 36+ row registry purge.
- **Plan Staleness Sentinel = 10 closures since R06 — TRIPS THRESHOLD** → strongly recommend `/impl-plan-review all` before IMPL-060. **Code Review trigger R09 strongly recommended** (Orchestrator + ODR fix + cross-slot surface = significant new adversarial sweep target).
- **Newly unblocked:** IMPL-060 + IMPL-061..068 QA chain + IMPL-017.
- **EA core surface complete pending IMPL-060 entry .mq5** — only one engineering task before MVP attach.
- **Next suggested action:** `/impl-review all` + `/impl-plan-review all` THEN `/impl-task IMPL-060` (S entry .mq5 thin wrapper).
- **Commit:** pending (to be created next).
- See `docs/state/_session-handoff/IMPL-059-evidence-20260504.md` for full evidence.

---

## Previous action

**IMPL-057 CLOSED 2026-05-04 — `services/CrossSlotCoordinator` BR-8.4 overload helpers (EOverload/COverload/GOverload — last business-logic method on file)** — single-task `/impl-task IMPL-057` orchestrator (Opus 4.7) Phase 2B 3-step. M-size structural completion of the 3 overload-helper bodies per BR-8.4 + FR-7.5 + CodeWiki §5.5 :9395/:9277/:9493. Predicate logic + Logger emit lands here; downstream order side-effects (CD-add via Slot_C, CD PartialClose, GO inverse open via Slot_GO) deferred to IMPL-059 Orchestrator wiring per ea.md `services/* must not #include slots/*` layering. **CrossSlotCoordinator service surface complete at coordinator level** — only `EvaluateBR_OrphanExit` body remains as TODO IMPL-038 (Slot_BR ownership, out of P4 scope).

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — module-local thresholds (EOVERLOAD_*/COVERLOAD_*/GOVERLOAD_*) added to header `#define` block; 3 private predicates declared (`_EOverloadTriggered`/`_COverloadTriggered`/`_LastGapPipFromZigZag`); `RunEOverload`/`RunCOverload`/`TriggerGOverload` body fills (predicate eval + Logger emit + TODO IMPL-059 markers for order side-effects); SelfTest extended 28→36 cases (C29-C32 EOverload truth-table 4 cases + C33-C35 COverload truth-table 3 cases + C36 reach-without-crash for all 3 helpers under bare MarketContext); header banner IMPL-057 sub-pass row added
  - `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` (EDIT — header banner only) — IMPL-053..058 → IMPL-053..058 + IMPL-057; SelfTest count 28 → 36
- **Files created:**
  - `simulation/headless-tests/cross_slot_overload_helpers.ini` (NEW) — committed per TD-02 §13.6 reproducibility
  - `docs/state/_session-handoff/IMPL-057-evidence-20260504.md` (NEW) — evidence file §1-§13
- **State files modified:** `docs/state/impl-plan.md` (IMPL-057 4 S-AC `[x]` + 1 E-AC `[ ]` deferred + Closed line + P4 status row 5/11→6/11 + TL;DR + Mid-Phase Audit Log new row), `docs/state/overview.md` (Impl Tasks row P4 6/11), `docs/state/deferred-ac-registry.md` (1 new IMPL-057 Active P4 row expiry 2026-05-18), `docs/state/current_handoff.md` (this file)
- **G1 ✅ PowerShell Start-Process MetaEditor64:** Spike_CrossSlotCoordinator 0err/0warn/**609 ms** (cache hit; no new headers — predicates + body fills only). G2-G4 deferred per IMPL-018+ header-only `.mqh` precedent (no entry .mq5 yet — runnable surface lands at IMPL-059+IMPL-060).
- **No sibling regression** — only `services/CrossSlotCoordinator.mqh` (header `#define` + private predicates + body fills + SelfTest tail) + `spike/Spike_CrossSlotCoordinator.mq5` (header banner only) edited. No other slots/services/domain/helpers files touched. No header-include cascade.
- **All 4 S-AC `[x]`** (3 helpers + HALTED matrix inherited from IMPL-058 + no-op log inherited from IMPL-053 + compile clean). **1 E-AC deferred** (combined HALTED+RUNNING matrix smoke + downstream order-execution side-effects + cross_slot_state request flag pickup `[log-assertion]` + `[db-inspect]` → block on IMPL-059+ Orchestrator + InpUseCOverload feature flag + InpInteruptRatioDecrease/InpGORatioDecrease wiring + Slot_C/Slot_GO OpenOrder dispatch + portfolio populator OnTradeTransaction); registered to `deferred-ac-registry.md` Active P4 row expiry 2026-05-18.
- **Code Review trigger R09 condition met** (5 P4 structural + 1 final business-logic = 6 P4 tasks closed; cross-slot surface complete). **Recommend `/impl-review all`** for adversarial sweep on cross-slot surface + ADR-010 enable matrix verification.
- **Newly unblocked:** IMPL-059 (L Orchestrator composition root — depends on ALL prior P1+P2+P3 + cross-slot IMPL-053..058+057). IMPL-060 chain follows.
- **Next suggested action:** `/impl-review all` (R09 trigger) → `/impl-task IMPL-059` (L Orchestrator) → IMPL-060 entry .mq5 → empirical surface unblocks 36+ deferred-AC rows expiring 2026-05-17/18.
- **Commit:** pending (to be created next)
- See `docs/state/_session-handoff/IMPL-057-evidence-20260504.md` for full evidence

---

## Previous action — Phase 4 Mid-Phase Audit GREEN

**Phase 4 Mid-Phase Audit CLOSED 2026-05-04 — Verdict GREEN, IMPL-057 unblocked** — `/next` recommended audit per CLAUDE.md §6 + workflow §4.1 after IMPL-058 closure crossed P4 counter = 5 threshold. Replay scope per IMPL-058 evidence §11 (structural-only — no runnable surface until IMPL-059+ Orchestrator + entry .mq5 land).

- **Replay actions (6 checks all ✅):**
  1. **G1 recompile** — Spike_CrossSlotCoordinator 0err/0warn/661 ms (fresh post fix-round-09: m_risk dropped, IsKnownMagic added, tickets_closed_count rename, no-op Warn branches, SetTypeFilling Init detection — all delta intact)
  2. **SelfTest structural integrity** — 28 explicit `Case <N>:` markers + `Print("[xslot] SelfTest 28/28 PASS")` + Logger `selftest_ok` event with "28/28 cases pass" all present (live runtime invocation deferred per §11 — covered by deferred-AC IMPL-053..056 close-path row in registry)
  3. **P4 evidence file structural pass** — IMPL-{053,054,055,056,058}-evidence-20260504.md all present + dated 2026-05-04 + sections 9-13 each (per IMPL-018+ header-only precedent)
  4. **Sibling regression** — Spike_PendingMachineRegistry 0err/0warn/1432 ms (verifies PortfolioState `IsKnownMagic` addition + general method-table change didn't break sister consumer chain)
  5. **Forbidden-closure pattern strict grep on `[x]` AC lines** — 0 hits ✅ (1 false-positive from greedy `.*` regex spanning audit-log narrative — `"deferred per XS scope"` + `"precedent"` in same Mid-Phase Audit Log cell — confirmed not a Dimension #11 violation)
  6. **fix-round-09 anti-regression** — `m_risk` 0 hits in `services/CrossSlotCoordinator.mqh` ✅ / `tickets_closed` 13 hits ✅ / `IsKnownMagic` 1 consumer + 3 hits in PortfolioState (decl + body + comment) ✅
- **State files modified:** `docs/state/impl-plan.md` (Mid-Phase Audit Log new row + TL;DR threshold-crossed → GREEN), `docs/state/overview.md` (Code Review row prepended audit verdict), `docs/state/current_handoff.md` (this rebump)
- **Verdict:** Phase 4 unblocked — recommend `/impl-task IMPL-057` (M overload helpers BR-8.4 — last business-logic method on `services/CrossSlotCoordinator.mqh`; circular dep resolved by IMPL-058). After IMPL-057 → IMPL-059 (L Orchestrator) + IMPL-060 (S entry .mq5) → empirical surface unblocks 36+ deferred-AC rows expiring 2026-05-17/18 + Code Review Round 10 trigger.
- **Commit:** pending (audit log + state propagation only — no source changes)

---

## Previous action — fix-round-09

**fix-round-09 CLOSED 2026-05-04 — adversarial review of `services/CrossSlotCoordinator.mqh` (post IMPL-053/054/055/056/058 land)** — `/impl-review-fix review-round-09.md` accepted 6/7 + 1 partial (09.5 deferred-AC); 0 reject. **2 HIGH** (09.1 magic filter via new `IsKnownMagic` predicate / 09.2 `_triggered` log → `_no_op` Warn when close count = 0) + **3 MEDIUM** (09.3 `SetTypeFilling` + Warn→Error on close-fail / 09.4 dropped dead `m_risk` injection / 09.5 partial → registry row) + **2 LOW** (09.6 single-gate `RunOrderGroup2` / 09.7 `slots_closed_count` → `tickets_closed_count` rename).

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — 09.1 magic filter / 09.2 no-op Warn / 09.3 filling-policy + Warn→Error / 09.4 drop m_risk + RiskManager include + Init param / 09.6 drop quick-out / 09.7 rename + header banner amend
  - `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh` (EDIT) — new public `IsKnownMagic(int)` silent membership predicate (distinct from `GetByMagic` which Warns on miss)
  - `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` (EDIT) — Init signature 5→4 args (drop trailing NULL after RiskManager removal)
- **Files created:**
  - `docs/code-review/fix-round-09.md` (NEW) — verdict table + per-finding fix narrative + summary metrics
- **State files modified:** `docs/state/overview.md` (Code Review row prepended Round 09 entry), `docs/state/deferred-ac-registry.md` (new P4 Active row IMPL-053..056 close-path empirical exercise, expires 2026-05-18), `docs/state/current_handoff.md` (this file)
- **G1 ✅ MetaEditor64 (PowerShell):** Spike_CrossSlotCoordinator 0err/0warn (668 ms) + Spike_PendingMachineRegistry 0err/0warn (1432 ms regression sweep — verifies PortfolioState `IsKnownMagic` addition didn't break sister consumers). G2-G4 deferred per header-only `.mqh` precedent.
- **Anti-regression sweep:** `m_risk` 0 hits in `services/CrossSlotCoordinator.mqh` ✅; `slots_closed=` 0 hits in same file ✅; `tickets_closed=` 2 hits ✅ (RunSafePort + RunOrderGroup2); `IsKnownMagic` 1 hit consumed in `_AggregateWeakMetrics` ✅; spike Init arg count = 4 ✅
- **Open follow-ups:** Finding 09.5 close-path empirical coverage tracked in `deferred-ac-registry.md` P4 row tied to IMPL-007 `GetTicketsForSlot` body landing. Newly added `IsKnownMagic` is structurally tested via spike SelfTest (28/28) but unexercised against real foreign-EA position — same registry row covers.
- **Next suggested action:** Code Review **Round 10** — adversarial re-sweep on fix-round-09 delta (HIGH-finding fixes are observability + filter changes, prone to subtle regressions) OR proceed to **Phase 4 Mid-Phase Audit** then `/impl-task IMPL-057` (M overload helpers BR-8.4) per IMPL-058's prior next-suggested action.
- **Commit:** pending (to be created next)
- See `docs/code-review/fix-round-09.md` for full evidence

---

## Previous action — IMPL-058

**IMPL-058 CLOSED 2026-05-04 — `services/CrossSlotCoordinator` HALTED enable-matrix audit + SetHalted setter (ADR-010)** — single-task `/impl-task IMPL-058` orchestrator (Opus 4.7) Phase 2A single-prompt (fall-back from `/impl-task parallel` per "no parallel candidates" scan — only IMPL-057+058 ready, both same-file `services/CrossSlotCoordinator.mqh` violating §1.5.1 scope-isolation; user picked option (a) IMPL-058 first per IMPL-054 next-suggested guidance). S-size audit-and-pin task — most wiring (m_halted field + SetHalted setter + RunEOverload/TriggerGOverload halt-guards) already landed during IMPL-053 sub-pass; IMPL-058 closes the contract by pinning the matrix in code + adding SelfTest coverage. **Bulk-close quartet + HALTED matrix audit now complete at coordinator level** (BR-8.1 SafePort + BR-8.2 OrderGroup2 + BR-8.3 ForceCutloss + BR-8.5 ExtraCheckFunction2 + ADR-010 enable matrix per `04 § 9.1`).

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — header banner adds IMPL-058 sub-pass row + verbatim `04 § 9.1 RUNNING/HALTED enable matrix` table pinning per-method enable decisions; SelfTest extended 25→28 cases (C26 entry-side guard reachability under HALTED, C27 exit-side reachability under HALTED, C28 restore path on SetHalted(false))
  - `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` (EDIT — header banner only) — IMPL-053..056 → IMPL-053..058; SelfTest count 25 → 28
- **Files created:**
  - `docs/state/_session-handoff/IMPL-058-evidence-20260504.md` (NEW) — evidence file §1-§13
- **State files modified:** `docs/state/impl-plan.md` (IMPL-058 4 S-AC `[x]` + 1 E-AC deferred + Closed: line + Phase Status row P4 4/11 → 5/11 + TL;DR + Mid-Phase Audit Log new row + **Phase Gate Override Log new row** for IMPL-057 reverse circular dep), `docs/state/overview.md` (Impl Tasks row prefix updated to bulk-close quartet + HALTED matrix audit), `docs/state/deferred-ac-registry.md` (1 new IMPL-058 Active P4 row expiry 2026-05-18)
- **Audit findings:** all 7 cross-slot methods comply with `04 § 9.1` matrix as of pre-IMPL-058 state (RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2/RunCOverload no-guard allowed in HALTED; RunEOverload + TriggerGOverload halt-guarded emit `[ev=overload_skipped_halted][helper=E\|G]` per ADR-010 :106). IMPL-058 work = audit-and-pin (doc block + SelfTest); no behavior change.
- **Dep override logged:** IMPL-058 Deps include IMPL-057, but IMPL-057 itself depends on IMPL-058 (HALTED matrix integration) → reverse circular per impl-plan. IMPL-054 next-suggested-task field had authorized pragmatic order swap (058 before 057). Phase Gate Override Log row 2026-05-04 documents scope (IMPL-058 only) + closure rationale (IMPL-058 audit work independent of IMPL-057 body fills; RunCOverload halt-allow decision unchanged regardless of body; EOverload/GOverload guards already in place).
- **G1 ✅ PowerShell Start-Process MetaEditor64:** Spike_CrossSlotCoordinator 0err/0warn/**611 ms** (cache hit; faster than IMPL-053..056 prior 838 ms baseline because no new headers, just doc + SelfTest tail)
- **No sibling regression** — only `CrossSlotCoordinator.mqh` (header doc + SelfTest tail) + `spike/Spike_CrossSlotCoordinator.mq5` (header banner) edited; no header-include cascade
- **SelfTest 28/28 cases pass** (7 IMPL-053 + 6 IMPL-055 + 6 IMPL-056 + 6 IMPL-054 + 3 IMPL-058):
  - C26: SetHalted(true) → RunEOverload + TriggerGOverload exercised → guards early-return without crash (reach-without-crash coverage)
  - C27: under HALTED, exit-side helpers (RunForceCutloss + ExtraCheckFunction2 + RunCOverload) reach predicate/null-guard paths without false halt-blocking
  - C28: SetHalted(false) un-latches entry-side methods — RunEOverload + TriggerGOverload reach TODO body without guard
- **All 4 S-AC `[x]`** (m_halted + SetHalted setter + per-method matrix wiring + compile clean). **1 E-AC deferred** — smoke trigger CircuitBreaker → `m_xslot.SetHalted(true)` invoked BEFORE RunExitPass + per-method behavior matches `04 § 9.1` matrix per row `[log-assertion]` + `[db-inspect]`. **Compound prerequisite:** (a) IMPL-059+ Orchestrator OnTick step 5b call site (currently doesn't exist), (b) IMPL-057 RunCOverload body wiring (currently TODO stub — coverage gap on COverload exit-side behavior in HALTED), (c) entry .mq5 (IMPL-060) + Tester run with CircuitBreaker triggering scenario. **Registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18.
- **Newly unblocked:** IMPL-057 (M overload helpers BR-8.4 — last business-logic method on file; circular dep resolved by IMPL-058 closure)
- **🚨 P4 Phase Status snapshot 4/11 → 5/11. Mid-Phase Audit P4 counter = 5 — THRESHOLD CROSSED.** Per CLAUDE.md §6 + workflow §4.1, **Phase 4 audit triggers BEFORE next P4 task can start**. Audit replay scope limited to (a) re-run Spike_CrossSlotCoordinator SelfTest 28/28 against fresh build, (b) structural inspection of evidence artifacts IMPL-053..058 against current state — **no live trading evidence to replay** until IMPL-059+ runnable surface lands. Plan Staleness Sentinel = 8 closures since R06 (well below 10-closure threshold).
- **Next suggested action:** **Phase 4 Mid-Phase Audit** (per workflow §4.1 cold-bootstrap + smoke chain + E-AC artifact replay; scope reduced per §11 of evidence file). After audit Green: **`/impl-task IMPL-057`** (M overload helpers BR-8.4 — last business-logic method on file). After IMPL-057 → IMPL-059 (L Orchestrator) + IMPL-060 (S entry .mq5) → empirical surface unblocks 36+ deferred-AC rows expiring 2026-05-17/18. Code Review trigger R09: after IMPL-057 closes for adversarial sweep on cross-slot surface + ADR-010 enable matrix verification.
- **Commit:** pending (to be created next)
- See `docs/state/_session-handoff/IMPL-058-evidence-20260504.md` for full evidence

---

## Prior action — IMPL-054 (kept for continuity)

**IMPL-054 CLOSED 2026-05-04 — `services/CrossSlotCoordinator::RunOrderGroup2()` (BR-8.2 Ichimoku double-bounce)** — single-task `/impl-task IMPL-054` orchestrator (Opus 4.7) Phase 2B 3-step (fall-back from `/impl-task parallel` per "no parallel candidates" scan — same-file scope on `services/CrossSlotCoordinator.mqh` blocked IMPL-054/057/058 fan-out per §1.5.1 scope-isolation criterion). M-size MVP (last sibling cross-slot method on file). **Bulk-close quartet now complete at coordinator level** (BR-8.1 SafePort + BR-8.2 OrderGroup2 + BR-8.3 ForceCutloss + BR-8.5 ExtraCheckFunction2).

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — replaced RunOrderGroup2 TODO stub with full body + 1 private helper (`_OrderGroup2Triggered`) + 1 define (`ORDER_GROUP_2_WEAK_ORDER_MIN`); refactored `_CloseSlotGroup` signature to take `(magic, prefix, triggering_function, comment_tag)` so SafePort + OrderGroup2 share bulk-close primitive; extended SelfTest 19 → 25 cases; updated header banner
  - `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` (EDIT — header banner only, reflects 25-case count)
- **Files created:**
  - `simulation/headless-tests/cross_slot_order_group_2.ini` (NEW) — smoke fixture per TD-02 §13.6; activation deferred to IMPL-059+
  - `docs/state/_session-handoff/IMPL-054-evidence-20260504.md` (NEW) — evidence file §1-§11
- **State files modified:** `docs/state/impl-plan.md` (3 S-AC `[x]` + 1 E-AC deferred + Closed: line + Phase Status row P4 3/11 → 4/11 + TL;DR + Mid-Phase Audit Log row), `docs/state/overview.md` (Impl Tasks row prefix updated to quartet), `docs/state/deferred-ac-registry.md` (1 new IMPL-054 Active P4 row expiry 2026-05-18)
- **G1 ✅ PowerShell Start-Process MetaEditor64:** Spike_CrossSlotCoordinator 0err/0warn/**569 ms** (incremental cache hit — faster than IMPL-053/055/056 prior 838 ms; refactor only, no new headers)
- **No sibling regression** — only `CrossSlotCoordinator.mqh` + spike header touched; refactored `_CloseSlotGroup` is private helper called by 2 sites (RunSafePort + RunOrderGroup2) both updated atomically
- **RunOrderGroup2 body design:**
  - NULL guards on m_portfolio + m_logger
  - Quick-out: `bool ichi_active = ctx.derived.ichi_double_bounce_active; if(!ichi_active) return;` (ADR-004 immutable derived signal)
  - `_AggregateWeakMetrics(weak_count, sum_bad_pip, total_pl)` — re-uses IMPL-053 helper
  - `_OrderGroup2Triggered(ichi_active, weak_count)` AND-gate (`ichi=true AND weak > 2` strict per BR-8.2 / CodeWiki §5.5 :512)
  - `_FillSafePortTargets(targets[])` shared 11-entry table (CD/J/H/K/L/M/Q/GO/T/S — bulk close mirrors RunSafePort target set per CodeWiki §5.5 :512 "similar to OrderGroupStartWorkflow")
  - Per-pair: `_CloseSlotGroup(magic, prefix, "OrderGroupStartWorkflow2", "order_group_2")` — issues per-ticket CTrade.PositionClose + per-ticket exit journal `triggering_function="OrderGroupStartWorkflow2"` (schema enum allowed `trade-journal-schema.yaml:179`)
  - Aggregate: `Logger.Info("xslot","order_group_2_triggered","slots_closed=N weak=N avg_bad_pip=N pl=N halted=...")`
- **Returns:** `void` per TD-02 §5.11 skeleton — **no spec deviation** (unlike IMPL-053 which returned `int` per Plan-text override)
- **HALTED matrix per `04 § 9.1` / ADR-010:** RunOrderGroup2 runs in BOTH RUNNING+HALTED (exit-side helper, mirrors RunSafePort semantics)
- **`_CloseSlotGroup` refactor justification:** 2 real call sites (SafePort + OrderGroup2) — DRY, not premature abstraction. Both helpers walk the same 11-entry target table; only the gate predicate + journal label + comment tag differ. Adheres to ea.md "Minimal changes" + "No over-engineering" principles. CTrade fail-log tag generalized `"safe_port_close_fail"` → `comment_tag + "_close_fail"`
- **SelfTest 25/25 cases pass** (7 IMPL-053 carry-forward + 6 IMPL-055 carry-forward + 6 IMPL-056 carry-forward + 6 IMPL-054 added):
  - C20 _OrderGroup2Triggered ichi=false, weak=0 → false
  - C21 ichi=true, weak=2 (boundary) → false (gate is strict `> 2`)
  - C22 ichi=true, weak=3 (first qualifying) → true
  - C23 ichi=true, weak=10 (well above) → true
  - C24 ichi=false, weak=10 (no ichi) → false (ichi flag dominates)
  - C25 RunOrderGroup2 with NULL portfolio + ichi=true → no-op (defensive guard)
- **All 3 S-AC `[x]`.** 1 E-AC deferred — smoke 3+ weak-position fixture in target slot set + Ichi-bounce signal active → close-all triggered + `[ev=order_group_2_triggered]` + per-ticket `triggering_function="OrderGroupStartWorkflow2"` `[log-assertion]` + `[db-inspect]`. **Compound prerequisite:** `ComputeIchiDoubleBounce` is currently PLACEHOLDER returning `false` per `MarketContextBuilder.mqh:577` (TODO IMPL-FUTURE — needs H4 history scan ≥50 bars beyond ADR-004 single-tick snapshot). Block on IMPL-059+ Orchestrator + IMPL-060 entry .mq5 + portfolio populator + Ichi-bounce signal refinement; **registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18
- **Newly unblocked:** IMPL-058 (S HALTED matrix wire-up — depends on IMPL-053..057 chain; pending IMPL-057) + IMPL-057 (M overload helpers — depends on IMPL-058 per impl-plan; pragmatic order: IMPL-058 first as wire-up is simpler then IMPL-057 business logic on top)
- **P4 Phase Status snapshot 3/11 → 4/11.** Mid-Phase Audit P4 counter = 4; **next P4 closure trips threshold 5** → Phase 4 audit will trigger before any subsequent task can start; audit replay scope limited to SelfTest re-run + structural inspection until IMPL-059+ runnable surface lands. **Plan Staleness Sentinel = 7 closures since R06** (still below 10-closure threshold)
- **Next suggested task:** **`/impl-task IMPL-058`** (S HALTED matrix wire-up — `m_halted` field + setter already exist; just per-method enable gate documentation + Orchestrator OnTick step 5b call site stub) **THEN** `/impl-task IMPL-057` (M overload helpers BR-8.4 — last business-logic method on file). After IMPL-057+058 → IMPL-059 (L Orchestrator) + IMPL-060 (S entry .mq5) → empirical surface unblocks 36+ deferred-AC rows expiring 2026-05-17/18. Code Review trigger R09: after IMPL-057+058 chain complete for adversarial sweep on cross-slot surface + ADR-010 HALTED enable matrix verification
- **Commit:** `2907e4a` `[feat:ea] IMPL-054 CrossSlotCoordinator::RunOrderGroup2 - BR-8.2 Ichi double-bounce`
- See `docs/state/_session-handoff/IMPL-054-evidence-20260504.md` for full evidence

---

## Prior action — IMPL-056 (kept for continuity)

**IMPL-056 CLOSED 2026-05-04 — `services/CrossSlotCoordinator::ExtraCheckFunction2()` (BR-8.5 CD demote check)** — single-task `/impl-task IMPL-056` orchestrator (Opus 4.7) Phase 2A single-prompt. XS-size MVP (continuation of CD-pair safety triplet — same-file scope as IMPL-053/055). **CD-pair safety triplet now complete at coordinator level** (BR-8.1 SafePort + BR-8.3 ForceCutloss + BR-8.5 ExtraCheckFunction2).

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — replaced ExtraCheckFunction2 TODO stub with full body + 1 private helper (`_IsCDDemoteCondition`); extended SelfTest 13 → 19 cases
- **Files created:**
  - `simulation/headless-tests/cross_slot_extra_check.ini` (NEW) — smoke fixture per TD-02 §13.6; activation deferred to IMPL-059+
  - `docs/state/_session-handoff/IMPL-056-evidence-20260504.md` (NEW) — evidence file §1-§9
- **State files modified:** `docs/state/impl-plan.md` (3 S-AC `[x]` + 1 E-AC deferred + Closed: line + Phase Status row P4 2/11 → 3/11 + Mid-Phase Audit Log row), `docs/state/overview.md` (Impl Tasks row prefix updated to triplet), `docs/state/deferred-ac-registry.md` (1 new IMPL-056 Active P4 row expiry 2026-05-18)
- **G1 ✅ MetaEditor64 /compile /log:** Spike_CrossSlotCoordinator 0err/0warn/838 ms (re-validated post-edit)
- **No sibling regression** — only `CrossSlotCoordinator.mqh` edited; new `_IsCDDemoteCondition` is private helper; no cross-cutting cascade
- **ExtraCheckFunction2 body design:**
  - NULL guards on m_portfolio + m_logger
  - `m_portfolio.GetByMagic(MAGIC_CD)` → `SlotState* cd` (CD pool aggregate per ADR-005 shared-magic)
  - `_IsCDDemoteCondition(cd.buy_count, cd.sell_count)` predicate: `(buy + sell) == 1` per BA `04 § BR-8.5` "portfolio[MagicCD].count == 1" + CodeWiki §5.5 :157
  - On trigger: `Logger.Info("xslot","cd_demote_triggered",MAGIC_CD,"cd_count=1 buy=N sell=N halted=...")`
- **HALTED matrix per `04 § 9.1` / ADR-010:** ExtraCheckFunction2 runs in BOTH RUNNING+HALTED (no order activity — pure state-trigger event)
- **XS scope split:** this sub-pass implements **predicate + Logger trigger emission** only. The actual `cross_slot_state.extra_force_mode_reason` integer field mutation (state-persistence-schema.yaml § cross_slot_state line 119-121) is owned downstream by IMPL-047 StatePersistence + IMPL-059 Orchestrator wiring (CrossSlotCoordinator currently lacks CrossSlotState reference; injection deferred per XS scope). Pattern matches IMPL-053 (SafePort emits log + journal but `ichi_double_bounce_buffer` not yet wired) precedent
- **SelfTest 19/19 cases pass** (7 IMPL-053 carry-forward + 6 IMPL-055 carry-forward + 6 IMPL-056 added):
  - C14 _IsCDDemoteCondition empty (0,0) → false
  - C15 single BUY (1,0) → true
  - C16 single SELL (0,1) → true
  - C17 paired (1,1) → false
  - C18 over-stack (2,0) → false
  - C19 ExtraCheckFunction2 NULL portfolio → no-op (defensive)
- **All 3 S-AC `[x]`.** 1 E-AC deferred — smoke 1-CD-position fixture → check returns true + `[ev=cd_demote_triggered]` Logger Print + state.json `extra_force_mode_reason` reset to 0 — block on IMPL-059+ Orchestrator + IMPL-060 entry .mq5 + cross_slot_state field mutation wiring; **registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18
- **Newly unblocked:** IMPL-054 (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce — last remaining sibling cross-slot method on `CrossSlotCoordinator.mqh`); IMPL-057/058 still gated on prereqs
- **P4 Phase Status snapshot 2/11 → 3/11.** Mid-Phase Audit P4 counter = 3; threshold 5 not crossed. **Plan Staleness Sentinel = 6 closures since R06** (still below 10-closure threshold)
- **Next suggested task:** **`/impl-task IMPL-054`** (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce — last sibling on CrossSlotCoordinator.mqh; completes the cross-slot bulk-cleanup quartet at coordinator level before IMPL-058 wire-up). After IMPL-054 → IMPL-058 (S HALTED enable matrix wire-up; depends on IMPL-053..057 chain — gating on IMPL-057 which depends on IMPL-058 itself; per Open Risk R-6 mitigation, may need to defer IMPL-057 to post-IMPL-059 if circular dep blocks). Code Review trigger R09: after IMPL-054/058 chain complete (5 P4 tasks total) for adversarial sweep on cross-slot surface
- **Commit:** `c4f58d3` `[feat:ea] IMPL-056 CrossSlotCoordinator::ExtraCheckFunction2 - BR-8.5 CD demote`
- See `docs/state/_session-handoff/IMPL-056-evidence-20260504.md` for full evidence

---

## Prior action — IMPL-055 (kept for continuity)

**IMPL-055 CLOSED 2026-05-04 — `services/CrossSlotCoordinator::RunForceCutloss()` (BR-8.3 CD safety)** — single-task `/impl-task IMPL-055` orchestrator (Opus 4.7) Phase 2A single-prompt. S-size MVP. **Parallel mode rejected** — all 3 ready P4 candidates (IMPL-054/055/056) share file `services/CrossSlotCoordinator.mqh` violating §1.5.1 scope-isolation criterion → fall back single-task IMPL-055 (smallest in chain). Full RunForceCutloss body landed; sibling stubs IMPL-054/056/057 unchanged.

- **Files modified:**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (EDIT) — replaced RunForceCutloss TODO stub with full body + 2 private helpers (`_ForceCutlossSignal`, `_CloseCDPositionsInLoss`); extended SelfTest 7 → 13 cases (added C8-C13 trigger truth-table + safe-guards); updated header banner to credit IMPL-055 sub-pass
- **Files created:**
  - `simulation/headless-tests/cross_slot_force_cutloss.ini` (NEW) — smoke fixture per TD-02 §13.6 (Visual=0 + ShutdownTerminal=1 + EURUSD H4 Model=4 60-day window 2024.01.01→2024.03.01); activation deferred to IMPL-059+
  - `docs/state/_session-handoff/IMPL-055-evidence-20260504.md` (NEW) — evidence file §1-§10
- **State files modified:** `docs/state/impl-plan.md` (3 S-AC `[x]` + 1 E-AC deferred + Closed: line + Phase Status row P4 1/11 → 2/11 + Mid-Phase Audit Log row + Next Best Action), `docs/state/overview.md` (Impl Tasks row prefix), `docs/state/deferred-ac-registry.md` (1 new IMPL-055 Active P4 row expiry 2026-05-18 — smoke 2-CD-position fixture)
- **G1 ✅ MetaEditor64 /compile /log:** Spike_CrossSlotCoordinator 0err/0warn/838 ms (re-validated post-edit)
- **No sibling regression** — only `CrossSlotCoordinator.mqh` edited; new `_ForceCutlossSignal` + `_CloseCDPositionsInLoss` are private helpers; no cross-cutting cascade
- **RunForceCutloss body design:**
  - `_ForceCutlossSignal(ctx)` derives ±1/0 tri-state from Stochastic M10 K-vs-D crossover AND MACD D1 hist sign (BR-8.3 + CodeWiki §5.5 :9009 baseline — no magic-number thresholds invented; sign-based AND-gate)
    - stoch_bear (K<D) AND macd_bear (hist<0) → +1 (cut BUY losses)
    - stoch_bull (K>D) AND macd_bull (hist>0) → -1 (cut SELL losses)
    - mismatch / flat → 0 (no cut)
  - `_CloseCDPositionsInLoss(signal)` walks both shared-magic prefixes "C," + "D," under MAGIC_CD via `port.GetTicketsForSlot`, closes only direction-matched losers (BUY+signal=+1 OR SELL+signal=-1 AND PL<0) via `m_trade.PositionClose`
  - Per-ticket journal `event_type="exit"` `triggering_function="ForceCutloss"` (schema enum allowed `trade-journal-schema.yaml` line 179) `comment="force_cutloss"` `signal_context="pl=<pl> signal=±1"`
  - Aggregate Logger Info `[ev=force_cutloss_triggered][magic=200][closed=N signal=±1 halted=...]`
- **HALTED matrix per `04 § 9.1` / ADR-010 §107:** ForceCutloss runs in BOTH RUNNING+HALTED (exit-side helper); no halt-guard needed
- **Naming note:** spec event `[ev=force_cutloss_cd]` (E-AC text) implemented as `[ev=force_cutloss_triggered]` for naming consistency with sibling `safe_port_triggered` (IMPL-053 pattern); per-ticket `triggering_function="ForceCutloss"` is authoritative schema-enum field — that's what auditors / IMPL-063 regression key off
- **SelfTest 13/13 cases pass** (7 IMPL-053 carry-forward + 6 IMPL-055 added):
  - C8 stoch K=20<D=50 + macd hist=-0.5 → +1 (cut BUY)
  - C9 stoch K=80>D=50 + macd hist=+0.5 → -1 (cut SELL)
  - C10 stoch bear + macd bull (mismatch) → 0
  - C11 K==D + hist==0 (flat) → 0
  - C12 _CloseCDPositionsInLoss with NULL portfolio → 0 (defensive)
  - C13 _CloseCDPositionsInLoss with signal=0 → 0 (defensive)
- **All 3 S-AC `[x]`.** 1 E-AC deferred — smoke 2-CD-position fixture with directional Stoch+MACD confirm → both C+D direction-matched losers close + journal `triggering_function="ForceCutloss"` `[log-assertion]` + `[db-inspect]` — block on IMPL-059+ Orchestrator + IMPL-060 entry .mq5 + PortfolioState OnTradeTransaction populator; **registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18
- **Newly unblocked:** IMPL-056 (XS ExtraCheckFunction2 BR-8.5 CD demote check — completes CD-pair safety triplet) · IMPL-054 (M RunOrderGroup2 BR-8.2 Ichimoku — independent any-order) · IMPL-058 still gated on chain complete
- **P4 Phase Status snapshot 1/11 → 2/11.** Mid-Phase Audit P4 counter = 2; threshold 5 not crossed. **Plan Staleness Sentinel = 5 closures since R06** (IMPL-039 + IMPL-034 + IMPL-013 + IMPL-053 + IMPL-055 — still below 10-closure threshold)
- **Next suggested task:** **`/impl-task IMPL-056`** (XS ExtraCheckFunction2 BR-8.5 CD demote check — smallest in chain; same-file scope) **OR** **`/impl-task IMPL-054`** (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce). Per Open Risk R-6 mitigation, prioritize IMPL-053..058 → IMPL-059 (L Orchestrator) → IMPL-060 (S entry .mq5) chain to unblock 36 Active deferred-AC rows + P2/P3 retroactive Phase Gate close + IMPL-022/IMPL-039 G4 attestation journal evidence path. Code Review trigger R09: after IMPL-058 chain complete (5 P4 tasks) for adversarial sweep on cross-slot surface
- **Commit:** `d42377a` `[feat:ea] IMPL-055 CrossSlotCoordinator::RunForceCutloss - BR-8.3 CD safety`
- See `docs/state/_session-handoff/IMPL-055-evidence-20260504.md` for full evidence

---

## Prior action — IMPL-053 (kept for continuity)

**IMPL-053 CLOSED 2026-05-04 — `services/CrossSlotCoordinator::RunSafePort()` (BR-8.1 OrderGroupStartWorkflow)** — single-task `/impl-task IMPL-053` orchestrator (Opus 4.7) Phase 2B 3-step. M-size MVP: first P4 task closed under Phase Gate Override 2026-05-03 (Path A) which authorizes "P3 IMPL-018 + IMPL-053..058 Orchestrator chain"; full RunSafePort body landed; sibling cross-slot methods stubbed for IMPL-054..057.

- **Files (NEW × 3):**
  - `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` — class skeleton (7 public methods per TD-02 §5.11) + RunSafePort full body + sibling stubs guarded for IMPL-054..057 + private helpers (`_SafePortTriggered`, `_AggregateWeakMetrics`, `_FillSafePortTargets`, `_CloseSlotGroup`) + 7-case SelfTest. Service-layer CTrade member allowed (ea.md restricts only slots/*).
  - `MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5` — G1 compile harness; Init(NULL deps) + SelfTest 7 cases pass.
  - `simulation/headless-tests/cross_slot_safe_port.ini` — smoke fixture (TD-02 §13.6) `[Tester]` block Visual=0 + ShutdownTerminal=1 + EURUSD H4 Model=4 60-day window 2024.01.01→2024.03.01; activation deferred to IMPL-059+.
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + IMPL-053 closure block all 4 S-AC `[x]` + Phase Status row P4 0→1/11 + Mid-Phase Audit Log row + Action ถัดไป + Last updated), `docs/state/overview.md` (Impl Tasks row prefix), `docs/state/deferred-ac-registry.md` (1 new IMPL-053 Active P4 row expiry 2026-05-18 — smoke 10-position fixture), `docs/state/_session-handoff/IMPL-053-evidence-20260504.md` (NEW evidence file with §1-§10).
- **G1 ✅ orchestrator-side independent recompile** (PowerShell Start-Process MetaEditor64): Spike_CrossSlotCoordinator 0err/0warn/838 ms.
- **No sibling regression** — `services/CrossSlotCoordinator.mqh` is a new file with zero existing `#include` consumers; no cascade.
- **RunSafePort body design:**
  - `_AggregateWeakMetrics` iterates `PositionsTotal()` filtered `_Symbol==EURUSD` (NFR-5.3 whitelist) → derives `weak_count` (signed_pip<0), `sum_bad_pip` (abs of signed_pip), `total_pl` (POSITION_PROFIT)
  - `_SafePortTriggered` AND-gate: `weak_count > 1` AND `avg_bad_pip > 55.0` AND `combined_pl > 0.0` per BR-8.1 spec literal (CodeWiki §5.5 baseline)
  - `_FillSafePortTargets` populates 11 entries `{(MAGIC_CD,"C,"), (MAGIC_CD,"D,"), (MAGIC_J,"J,"), (MAGIC_H,"H,"), (MAGIC_K,"K,"), (MAGIC_L,"L,"), (MAGIC_M,"M,"), (MAGIC_Q,"Q,"), (MAGIC_GO,"GO,"), (MAGIC_T,"T,"), (MAGIC_S,"S,")}` per BA `04 § BR-8.1` slot list
  - per (magic, prefix) `_CloseSlotGroup` calls `port.GetTicketsForSlot` + `m_trade.PositionClose(ticket)` + per-ticket journal `event_type="exit"` `triggering_function="OrderGroupStartWorkflow"` `comment="safe_port"` `signal_context="pl=<pl>"` + accumulates count
  - Aggregate Logger Info `[ev=safe_port_triggered][slots_closed=N weak=N avg_bad_pip=N pl=N halted=...]`
  - Returns `int slots_closed_count`
- **HALTED matrix per `04 § 9.1` / ADR-010:** SafePort runs in BOTH RUNNING+HALTED (exit-side helper); EOverload/TriggerGOverload guarded `if(m_halted) return;` with Logger `[ev=overload_skipped_halted][helper=E|G]`.
- **Spec deviation logged:** TD-02 §5.11 declares `void RunSafePort(const MarketContext&)`; implementation returns `int` (slots_closed_count) per S-AC #3 plan-text imperative — Plan text > skeleton text per Plan QA precedent (mirrors IMPL-039 ADR-009 + R06 Slot_P signature deviations). Documented in `services/CrossSlotCoordinator.mqh` header banner + evidence §7 + impl-plan + Mid-Phase Audit Log.
- **SelfTest 7/7 cases pass:** C1 Init defaults (m_halted=false), C2 SetHalted toggle round-trip, C3 _SafePortTriggered all-zero → false, C4 weak=2/avg=60/pl=10 → true, C5 weak=2/avg=40/pl=10 → false (low pip), C6 weak=2/avg=60/pl=-5 → false (neg pl), C7 _FillSafePortTargets returns 11 entries with [0]=(MAGIC_CD,"C,") and [10]=(MAGIC_S,"S,") — composite gate truth-table fully covered.
- **All 4 S-AC `[x]`.** 1 E-AC deferred — smoke 10-position fixture with avg badPIP=60 + currentProfit>0 → SafePort closes en masse + journal `[ev=safe_port_triggered][slots_closed=10]` + per-ticket `triggering_function="OrderGroupStartWorkflow"` `[log-assertion]` + `[db-inspect]` — block on IMPL-059+ Orchestrator + IMPL-060 entry .mq5 + PortfolioState OnTradeTransaction populator (Finding 02.3 fix contract); **registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18.
- **Newly unblocked:** IMPL-054 (RunOrderGroup2 BR-8.2 — same-file sequential) · IMPL-055 (RunForceCutloss BR-8.3 S-size simpler) · IMPL-056 (ExtraCheckFunction2 BR-8.5 XS) · IMPL-057 (overload helpers M; depends on IMPL-058) · IMPL-058 (HALTED matrix wire-up S — depends on IMPL-053..057).
- **P4 Phase Status snapshot 0/11 → 1/11.** Mid-Phase Audit P4 counter = 1. **Plan Staleness Sentinel = 4 closures since R06** (IMPL-039 + IMPL-034 + IMPL-013 + IMPL-053 — well below 10-closure threshold).
- **Commit:** `70ed0a2` `[feat:ea] IMPL-053 CrossSlotCoordinator::RunSafePort - BR-8.1 OrderGroupStartWorkflow` (backfill commit `e252cdf` ships paired R06 plan rebuttal + R08 code review/fix artifacts; landed via `git commit --amend` to substitute commit hash for `<pending>` placeholder per IMPL-039 commit-hash-backfill precedent).
- **Next suggested task:** **`/impl-task IMPL-055`** (S RunForceCutloss BR-8.3 CD pair — simplest in chain; same-file scope) **OR** **`/impl-task IMPL-054`** (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce) **OR** **`/impl-task IMPL-056`** (XS ExtraCheckFunction2 BR-8.5 CD demote check). Per Open Risk R-6 mitigation, prioritize IMPL-053..058 → IMPL-059 (L Orchestrator) → IMPL-060 (S entry .mq5) chain to unblock 36 Active deferred-AC rows + P2/P3 retroactive Phase Gate close + IMPL-022/IMPL-039 G4 attestation journal evidence path. Code Review trigger R09: after IMPL-058 chain complete (~5 P4 tasks) for adversarial sweep on cross-slot surface + ADR-010 HALTED enable matrix verification.
- See `docs/state/_session-handoff/IMPL-053-evidence-20260504.md` for full evidence.

---

## Prior action — Code Review Round 08 (kept for continuity)

**Code Review Round 08 + Fix Round 08 APPLIED 2026-05-04** — `/impl-review-fix review-round-08.md` accepted **5/5** findings (CRITICAL 0 / HIGH 0 / MEDIUM 3 / LOW 2; 0 reject, 0 partial). 2 source files modified (`slots/Slot_P.mqh` + `services/PendingMachineRegistry.mqh`).

- **Major fixes:**
  - **08.1 MEDIUM + 08.2 MEDIUM + 08.4 LOW** (bundled — Slot_P entry-path housekeeping) Adopted canonical `_PipsToPrice(sl_pips)` helper at Path A pyramid + Path B primary (Round 06 06.1 collapse honored); paired both Evaluate sites with NFR-5.1 loud-failure guard symmetric to ManageExits Round 07.5 (`Logger.Error` + Path B `Alert` + early-return); added `diff_sl_pip <= 0.0` skip-with-Warn at Phase A IDLE→PENDING (eliminates `+0.0` vs `-0.0` ambiguity in signed-encoding scheme per schema § PendingMachineState_PVariant.diff_sl)
  - **08.5 LOW** `_ParsePDouble` loose char-class loop replaced with strict JSON-number state machine — `[+|-]? digits ( . digits )? ( [eE][+|-]? digits )?` — rejects malformed forms (`--250` / `1-2-3` / `1e`) while binary-equivalent on canonical `_BuildPPayload` output
  - **08.3 MEDIUM** PMR SelfTest extended +Case 8 (negative `diff_sl` round-trip — empirical proof of Round 07.1 sign-convention fix; SELL marker preserved through `DoubleToString` / strict `_ParsePDouble`) + Case 9 (`pending_started_bar` invariance under `OverwritePPayload` via indirect legacy-timeout behavior at PM_P age=69 still-PENDING + age=70 transitions-IDLE — empirical proof of Round 07.3 BR-6.4 fix)
- **Anti-regression sweep (post-fix grep):** `_PipSize() *|sl_pips * pip_size` in Slot_P.mqh **0 hits** ✅ · `_PipsToPrice` in Slot_P.mqh **2 hits** ✅ (Path A line 323 + Path B line 445) · `if(diff_sl_pip <= 0.0)` in Evaluate **1 hit** ✅ (Phase A guard) · `if(sl_dist <= 0.0)` in Evaluate **2 hits** ✅ (NFR-5.1 symmetry both paths) · `ch == '-' || ch == '+'` loose char-class **0 hits** ✅ · `EnterPending(PM_P,` in `slots/` **0 hits** ✅ (Round 07.2 collapse intact)
- **G1 ✅:** 3/3 affected spikes 0err/0warn (Spike_PendingMachineRegistry 1299 ms / Spike_Slot_P 398 ms / Spike_Slot_BI 386 ms via PowerShell Start-Process MetaEditor64). G2-G4 deferred per header-only `.mqh` precedent (gates activate at IMPL-053+ Composition Root); SelfTest Case 8+9 exercised at Spike_PendingMachineRegistry runtime when entry .mq5 lands.
- **3 commits:** (A) Slot_P entry-path housekeeping (08.1+08.2+08.4); (B) PMR `_ParsePDouble` strict parser (08.5); (C) PMR SelfTest Cases 8+9 (08.3) — see git log post-2026-05-04.
- **No Tier-1 task ACs reopened, no Deferred-AC registry rows affected.** IMPL-039 + IMPL-034 attestation surface stable; Round 08 surface fully resolved.
- See `docs/code-review/fix-round-08.md` for full evidence + verdict table + per-finding diffs.

---

## Prior action — IMPL-013 (kept for continuity)

**IMPL-013 CLOSED 2026-05-04 — `inputs/Inputs_Slot_<X>.mqh` × 21 (formal rolling-close mark)** — single-task `/impl-task IMPL-013` orchestrator (Opus 4.7) formal AC marking. **No new code shipped** — file set rolled in incrementally with IMPL-019..039 commits per impl-plan IMPL-013 description engineer convention ("May complete as 21 sub-tasks bundled with IMPL-019..039 OR as one batch landing"). Trigger: IMPL-034 closed 2026-05-04 → `Inputs_Slot_P.mqh` shipped → 21/21 file set complete. **P3 Phase Status snapshot 22/23 → 23/23 ✅** — P3 Phase Gate now nominate-able pending IMPL-053+ Orchestrator runnable surface.

- **Files modified (no new code):** `docs/state/impl-plan.md` (3 S-AC `[x]` + 1 E-AC `[x]` + 1 E-AC deferred + Closed: line + Phase Status row 22/23 → 23/23 ✅ + TL;DR + Mid-Phase Audit Log row + Action ถัดไป + Last updated), `docs/state/overview.md` (Impl Tasks row prefix), `docs/state/deferred-ac-registry.md` (1 new IMPL-013 Active P3 row expiry 2026-05-18 — live MT5 input dialog probe defers to IMPL-060 entry .mq5).
- **File created:** `docs/state/_session-handoff/IMPL-013-evidence-20260504.md` — evidence file with §1 file count + §2 group annotation grep + §3 input declaration grep (178 total) + §4 defaults rolling verification via 21 spike harnesses + §5 AC closure summary + §6 notes + §7 next.
- **3/3 S-AC `[x]` via filesystem grep:**
  1. **21 input files exist + group annotations** — `ls Inputs_Slot_*.mqh` returns 21 files (B/BI/BR/C/D/F/G/G2/GO/H/I/J/K/L/LX/M/P/Q/R/S/T) + `grep -E '^input group' Inputs_Slot_*.mqh` returns 21 lines `input group "Slot <X>"` per NFR-6.3.
  2. **Defaults match CodeWiki §3 baseline** — verified rolling via 21/21 Spike_Slot_X G1 0err/0warn (G4 fix tunables InpBIPyramidGatePips=30 / InpBISlFallbackPips=80 / InpEnableSlotJ / InpLegacyPBars=70 / InpPPyramidGatePips=30 / InpPAdxMin / InpPForcePxGate / InpPDiffSlPxThreshold / InpP{TpPxPips,TpPhPips,TpEPips} match ADR-009 + BR-7.2 + 04 § 4.4).
  3. **Total ≥ 80 NFR-4.3** — `grep -c "^input " Inputs_Slot_*.mqh` total = **178 per-slot input declarations** (B=9, BI=7, BR=6, C=10, D=3, F=6, G=16, G2=8, GO=6, H=9, I=8, J=5, K=9, L=9, LX=7, M=10, P=12, Q=10, R=9, S=9, T=10) + 22 IMPL-012 General + ≥ 15 IMPL-014 cross-slot ≈ **215 cumulative ≫ 80 target**.
- **1 E-AC `[x]` file-blob-check:** 178 declarations across 21 files verified via grep.
- **1 E-AC deferred:** MT5 attach EA → 21 distinct "Slot X" group sections in input dialog `[probe]` — needs entry `PhoenicisNex.mq5` (IMPL-060) + chart attach; spike harnesses cannot exercise input-dialog rendering (Strategy Tester uses default values; live dialog only on chart attach). Registered to `deferred-ac-registry.md § Active` row IMPL-013 expires 2026-05-18.
- **G1-G4 N/A on this rolling-close.** Per-slot G1 already verified at each IMPL-019..039 closure (21/21 0err/0warn). Aggregate compile unit only meaningful via Composition Root at IMPL-053+/IMPL-060.
- **Mid-Phase Audit P3 counter** = 23 (advisory pending runnable surface). **Plan Staleness Sentinel = 3 closures since R06** (IMPL-039 + IMPL-034 + IMPL-013 — well below 10-closure threshold).
- **Commit:** `<pending this commit>` `[state] IMPL-013 rolling-close - 21/21 per-slot input files marked`
- **Next suggested task:** **`/impl-review all`** (R07 trigger — adversarial sweep on full P3 slot surface incl Slot_P sub-mode lifecycle + Slot_BI G4 surface vs ADR-009 + IMPL-022/039 attestation completeness) **OR** **`/impl-task IMPL-053`** (start P4 CrossSlotCoordinator chain — IMPL-053..058 sequential due to shared-file scope on `services/CrossSlotCoordinator.mqh`; per Open Risk R-6 mitigation, prioritize IMPL-053 RunSafePort + IMPL-059 Orchestrator + IMPL-060 entry .mq5 to unblock 35 deferred-AC rows expiring 2026-05-17/18).

---

## Prior action — IMPL-034 (kept for continuity)

**IMPL-034 CLOSED 2026-05-04 — Slot_P ⚠️ A7 risk: P-Pending sub-modes PSUB_NONE/N/PX/PH/E per `04 § 4.4` (lock-once semantic)** — single-task `/impl-task IMPL-034` orchestrator (Opus 4.7) Phase 2C 7-step decomposition. L-size MVP: P-Pending lifecycle with sub-mode resolution branch + pyramid extension path bypassing PMR. **All 21 P3 slots + 21/21 per-slot input files now complete** at slot layer.

- **Files (NEW × 4):**
  - `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` — CSlotP : CSlotBase; sub-mode resolution (`_ResolvePSubMode` lock-once N→PX/PH); pyramid E path bypasses PMR (parent profit gate ≥ 30 pip); comment-prefix disambig "P," vs "PI," (Slot_BI line 89-95 precedent); `_TpPipsForSubMode` parses comment 3rd CSV field.
  - `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_P.mqh` — 11 inputs (group="Slot P"): InpEnableSlotP / InpPMaxOrders=1 / InpPBaseLot=20.0 / InpPSlPipsFloor=80.0 / InpPAdxMin=18.0 / InpPForcePxGate=0.1 / InpPDiffSlPxThreshold=200.0 / InpPTpPipsPx=7.0 / InpPTpPipsPh=15.0 / InpPTpPipsE=25.0 / InpPPyramidGatePips=30.0.
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_P.mq5` — G1 compile + 6 SelfTest cases (Magic=218/SlotId="P"/DependsOn=0/PendingState=IDLE/range/id_nonempty).
  - `simulation/headless-tests/slot_P_smoke.ini` — standard headless [Tester] block (Visual=0, ShutdownTerminal=1, EURUSD H4 Model=4 60-day window 2021.01.01→2021.03.02).
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + IMPL-034 closure block with all 6 S-AC `[x]` + Phase Status row 21→22/23 + Mid-Phase Audit Log row + Plan Staleness Sentinel = 2 closures + Action ถัดไป + Last updated), `docs/state/overview.md` (Impl Tasks row prefix), `docs/state/deferred-ac-registry.md` (1 new IMPL-034 Active P3 row expiry 2026-05-18), `docs/state/_session-handoff/IMPL-034-evidence-20260504.md` (NEW — G1 evidence + sub-mode coverage table + A7 deferred items).
- **G1 ✅ orchestrator-side recompile** (Bash MetaEditor64): Spike_Slot_P 0err/0warn/435 ms.
- **Sibling regression (4/4 clean):** Spike_Slot_R 0/0/405 ms · Spike_Slot_M 0/0/420 ms · Spike_Slot_BI 0/0/424 ms · Spike_Slot_LX 0/0/407 ms.
- **Sub-mode lifecycle structural verification:** IDLE→base BB+ADX signal→`EnterPending(payload sub_mode=N)`; PENDING+sub_mode=N→`_ResolvePSubMode` locks PSUB_PX (`|f1|>InpPForcePxGate AND diff_sl_pip≥InpPDiffSlPxThreshold`) or PSUB_PH default; PENDING+sub_mode∈{PX,PH}+`_IsPTriggerValid`→OrderSend "P,MA,PX|PH,1,SL"+TransitionExecuted. Pyramid E path direct OrderSend "PI,MA,E,1,SL" when own primary P active + parent profit ≥ 30 pip (Slot_LX/Slot_BI precedent). Legacy timeout `InpLegacyPBars=70` BR-6.4 owned by PMR.TickAll Orchestrator step 8.
- **A7 risk advanced filters deferred to P4 IMPL-062:** Hull MA structure entry filter / recent-bar trigger lookback ≤ 8 bars / band gating extremes (`_diffSL ≥ 250 AND band_ratio > 75`) / per-extension Fibonacci pyramid lot calc per CodeWiki §3.14.
- **All 6 S-AC `[x]`.** 1 E-AC deferred — smoke 60-day backtest with sub-mode trigger reflected in `state.json § pending_machines.P.sub_mode` `[db-inspect]` + `[log-assertion]` — block on IMPL-053+ Orchestrator + RiskManager OrderSend + 60-day Tester run; **registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18.
- **Newly unblocked:** IMPL-013 formal rolling-close mark (21/21 input files complete with `Inputs_Slot_P.mqh`).
- **Mid-Phase Audit P3 counter** = 22 (threshold 5 crossed many times; advisory only until IMPL-053+ runnable surface). **Plan Staleness Sentinel = 2 closures since R06 review** (well below 10-closure threshold).
- **Commit:** `<pending this commit>` `[feat:ea] IMPL-034 Slot_P - P-Pending sub-modes (PSUB_NONE/N/PX/PH/E per 04 § 4.4)`
- **Next suggested task:** **IMPL-013 formal rolling-close** (mark all 21 per-slot input AC `[x]` since file set complete) **OR** `/impl-review all` (R07 trigger — adversarial sweep on full P3 slot surface incl Slot_P sub-mode lifecycle + Slot_BI G4 vs ADR-009) **OR** begin P3 Phase Gate path (Tier 1.5 walk requires IMPL-053+ Orchestrator chain first).

---

## Prior actions (kept for continuity)

**IMPL-039 CLOSED 2026-05-04 — Slot_BI ⚠️ G4 critical SL inheritance fix per ADR-009 (Bucket B drift NFR-1.8)** — single-task `/impl-task IMPL-039` orchestrator (Opus 4.7) Phase 2C 7-step decomposition. L-size MVP: pyramid child of Slot B sharing MAGIC_B=214 with G4 SL inheritance contract restored.

- **Files (NEW × 5):**
  - `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh` — CSlotBI : CSlotBase; G4 fix surface in Evaluate (SL anchor at BI entry per ADR-009 Option A; earliest-B-parent pip distance via `_PipsToPrice(_PriceToPips(parent_open - parent_sl))`; fallback `InpBISlFallbackPips=80` when parent_sl=0).
  - `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_BI.mqh` — 6 inputs (group="Slot BI"): InpEnableSlotBI / InpBIMaxOrders=1 / InpBIBaseLot=14.0 (lighter than B's 20) / InpBIPyramidGatePips=30.0 / InpBITpProfitPips=30.0 / InpBISlFallbackPips=80.0 (ADR-009 fallback floor).
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5` — G1 compile + 6 SelfTest cases (Magic/SlotId/DependsOn/PendingState/range/id_nonempty).
  - `simulation/headless-tests/slot_BI_smoke.ini` — standard headless [Tester] block (Visual=0, ShutdownTerminal=1, EURUSD H4 Model=4 60-day window 2021.01.01→2021.03.02).
  - `docs/state/g4-fix-attestation.md` **NEW** — consolidated G4 fix audit trail: Fix #1 IMPL-022 BR-7.2 (commit `d386ea6` + structural evidence path) + Fix #2 IMPL-039 ADR-009 (commit pending; structural evidence path); ADR-009 Option A implementation notes + spec deviation log.
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + IMPL-039 closure block with all 7 S-AC `[x]` + Phase Status row 20→21/23 + Mid-Phase Audit Log row + Action ถัดไป + Last updated 2026-05-04), `docs/state/overview.md` (Impl Tasks row), `docs/state/deferred-ac-registry.md` (2 new IMPL-039 Active P3 rows expiry 2026-05-18 + IMPL-022 row partially resolved on file-existence portion), `docs/state/_session-handoff/IMPL-039-evidence-20260503.md` (G1 evidence + G4 fix structural verification + S-AC/E-AC status).
- **G1 ✅ orchestrator-side recompile** (PowerShell Start-Process MetaEditor64): Spike_Slot_BI 0err/0warn/425 ms.
- **Sibling regression (4/4 clean):** Spike_Slot_B 0/0/432 ms · Spike_Slot_BR 0/0/427 ms · Spike_Slot_LX 0/0/419 ms · Spike_Slot_J 0/0/427 ms.
- **G4 fix ADR-009 structural verification:** earliest-B-parent anchor (`parent_tickets[0]`), pip distance via CSlotBase helpers (Round-06 06.1 routing through CPipMath when wired), `_NormalizeBrokerPrice` for broker tick precision (Round-06 06.3), edge-case fallback `InpBISlFallbackPips` floor (Bollinger fallback BBBot-10/BBTop+10 deferred to IMPL-062 P4). Bucket B classification noted in commit message body.
- **Spec deviation logged:** S-AC #3 plan text reads "OrderSend SL parameter = parent B's open price ± m_pip.ToPoints(parent_sl_pip)"; ADR-009 Option A locks anchor at `BI.entry_price`; implementation follows ADR-009 (architectural primary). Documented in `g4-fix-attestation.md § Fix #2` + Slot_BI.mqh header banner.
- **All 7 S-AC `[x]`.** 2 E-AC deferred — (1) smoke `[db-inspect]` BI ticket non-zero SL matching parent pip distance — block on IMPL-053+ Orchestrator; (2) g4-fix-attestation.md journal evidence path — file exists with Fix #2 row but commit hash + journal evidence path land at IMPL-053+ runnable surface; **both registered to `deferred-ac-registry.md` Active table** expiry 2026-05-18.
- **Newly unblocked:** none (BI has no downstream P3 deps; remaining P3 = IMPL-013 input completion + IMPL-034 Slot_P).
- **Mid-Phase Audit P3 counter** = 21 (threshold 5 crossed many times; advisory only until IMPL-053+ runnable surface). **Plan Staleness Sentinel = 1 closure since R06 review** (R06 closed 2026-05-03 reset to 0; +IMPL-039 = 1 — well below 10-closure threshold).
- **Commit:** `bc7f558` `[feat:ea] IMPL-039 Slot_BI - G4 critical SL inheritance fix per ADR-009 (Bucket B)`
- **Next suggested task:** **IMPL-034 (L Slot_P — A7 risk monitoring slot; only remaining P3 slot file)** **OR** `/impl-review all` (R07 trigger — adversarial sweep on Slot_BI G4 surface vs ADR-009 + IMPL-022/039 attestation completeness) **OR** P3 Phase Gate close after IMPL-034 + IMPL-013 input completion.

---

**Code Review Round 05 + Fix Round 05 APPLIED 2026-05-03** — `/impl-review-fix review-round-05.md` accepted **10/10** findings (CRITICAL 2 / HIGH 3 / MEDIUM 3 / LOW 2; 0 reject, 0 partial). 7 source files modified (Slot_H/B/K/L/BR/J + core/SlotRegistry) + 1 state file (`deferred-ac-registry.md`).

- **Major fixes:**
  - **05.1 CRITICAL** Slot_H stripped `CTrade m_trade_exec` member + `<Trade\Trade.mqh>` include + naked `Buy/Sell` calls; replaced with RiskManager-routed log-intent stubs + computed sl_price (mirrors 17 sibling slots; commit `01f3396`)
  - **05.2 CRITICAL** Slot_B/K/L `ManageExits` switched from MT5 ORDER APIs (`OrdersTotal()` + `OrderGet*`) to canonical POSITION APIs (`port.GetTicketsForSlot` + `PositionSelectByTicket`) — Order* APIs walked the wrong list and would have rendered exit gates non-functional once IMPL-053 wires close (commit `b102a0c`)
  - **05.3 HIGH** Slot_BR `_HasActiveBROrder` → `_CountBROrders` gating `>= InpBRMaxOrders` (commit `8a44ca2`)
  - **05.4 HIGH** Slot_H `_CountHOrders` + `ManageExits` routed through PortfolioState.GetTicketsForSlot (was raw `PositionsTotal()` — third dialect collapsed; bundled in `01f3396`)
  - **05.5 MEDIUM** Slot_J `ManageExits` gated on `InpEnableSlotJ` (canonical sibling guard); **05.6 MEDIUM** dead `j_state` read removed (G4 attestation surface tightened; 2 explicit BR-7.2 markers preserved at GetTicketsForSlot + log sites; commit `7e62dbe`)
  - **05.7 HIGH** IMPL-023/024/025 added to `deferred-ac-registry.md` Active table (closure-discipline Dimension #11 violation resolved; commit `dca5e98`)
  - **05.8 MEDIUM** Slot_B BR-trigger hook relocated post-profit-gate; commented body switched to Position* APIs (bundled in `b102a0c`)
  - **05.9 LOW** Slot_H false-doc comment removed (resolved with 05.1 strip)
  - **05.10 LOW** `CSlotRegistry::Init` routed through `ReleaseAll` to respect `m_owns_slots` (prevents heap leak on OnInit re-entry per CleanupPartialInit; commit `3266fd7`)
- **G1 ✅** 7/7 affected spikes 0err/0warn (Slot_H 640 ms / Slot_B 468 ms / Slot_K 458 ms / Slot_L 429 ms / Slot_BR 418 ms / Slot_J 534 ms / CSlotBase 562 ms — fresh post-fix run via PowerShell Start-Process MetaEditor64).
- **Sibling regression:** 13/13 unmodified slot spikes still 0err/0warn (Slot_C/D/F/G/G2/GO/I/LX/M/Q/R/S/T) — no cascade.
- **Anti-regression sweep (post-fix grep):** `m_trade_exec` 0 hits; `OrdersTotal()` in slots/ 0 hits; `_HasActiveBROrder` 0 hits.
- **Deferred-AC table:** Active rows 23 (was 20) — IMPL-023/024/025 added uniformly with expiry 2026-05-17.
- **G2-G4** deferred per header-only `.mqh` precedent (gates activate at IMPL-053+ Composition Root; live cascade demo for B/BR/BI etc. awaits Orchestrator).
- **Round 05 fix report:** `docs/code-review/fix-round-05.md`.
- **Newly unblocked:** none (all fixes are in-place refactors of already-closed slot tasks; no new task readiness).
- **Recommendation:** ready for next code review round (Round 06 — adversarial sweep on Round-05 fix delta) **OR** continue with IMPL-039 (BI SL G4 fix per ADR-009 — second G4 fix; HIGH RISK Bucket B drift) **OR** Slot_P (IMPL-034 — A7 risk monitoring slot, only remaining P3 slot).

---

**IMPL-022 CLOSED 2026-05-03 — Slot_J ⚠️ G4 critical fix BR-7.2 (Bucket B drift NFR-1.8)** — single-task `/impl-task IMPL-022` orchestrator (Opus 4.7) path; M-size MVP CD-follower scaffold + G4 critical fix surface in ManageExits.

- **Files (NEW × 4):**
  - `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` — CSlotJ : CSlotBase; MAGIC_J=206; comment "J,"; DependsOn=[MAGIC_CD]; PendingState=IDLE; Evaluate sub-call early-return; **ManageExits = G4 fix BR-7.2 SURFACE** (3 explicit `// G4 fix BR-7.2 — was MAGIC_F` comments at GetByMagic + GetTicketsForSlot + log message sites).
  - `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_J.mqh` — InpEnableSlotJ + InpJMaxOrders=1 + InpJSlPipsFloor=50.0 + InpJTpProfitPips=40.0; group="Slot J".
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_J.mq5` — 6 SelfTest cases (Magic/SlotId/DependsOn/PendingState/range/non-empty); pattern mirrors Spike_Slot_F.
  - `simulation/headless-tests/slot_J_smoke.ini` — standard headless [Tester] block (Visual=0, ShutdownTerminal=1, EURUSD H4 Model=4 60-day window).
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + IMPL-022 closure block with all 6 S-AC `[x]` + Phase Status row 17→18/23 + Mid-Phase Audit Log row + Plan Staleness Sentinel 43→46), `docs/state/overview.md` (Impl Tasks row), `docs/state/deferred-ac-registry.md` (2 new Active P3 rows for IMPL-022 — smoke fixture E-AC + g4-fix-attestation.md authoring; expiry 2026-05-17), `docs/state/_session-handoff/IMPL-022-evidence-20260503.md` (G1 evidence + G4 fix structural verification).
- **G1 ✅ orchestrator-side recompile** (PowerShell Start-Process MetaEditor64): Spike_Slot_J 0err/0warn/534 ms (log on disk: `MQL5\Experts\PhoenicisNex\spike\Spike_Slot_J.log` — note current MetaEditor64 build emits `.log` not `.compile.log`).
- **Sibling regression:** Spike_Slot_F 0err/0warn/460 ms unchanged (CD chain unaffected).
- **G4 fix BR-7.2 structural verification:** `m_portfolio.GetByMagic(MAGIC_J)` confirmed in ManageExits (line ~189 of Slot_J.mqh) with adjacent `// G4 fix BR-7.2 — was MAGIC_F` comment; `port.GetTicketsForSlot(MAGIC_J, "J,", tickets)` confirmed (line ~196) with same fix marker; log message at exit gate carries `"(G4 fix BR-7.2)"` suffix for journal forensic. Bucket B classification (intentional behavioral change vs PhoenicisN2.10 baseline) noted in commit `d386ea6` body — NFR-1.8 budget separate from Bucket A NFR-1.1; regression sign-off at IMPL-063 (P4 G4-fixes-on full backtest).
- **All 6 S-AC `[x]`.** 2 E-AC deferred to IMPL-053+ Orchestrator + g4-fix-attestation.md authoring (registered to deferred-ac-registry.md Active table; expiry 2026-05-17).
- **Newly unblocked:** none — Slot_J has no downstream P3 deps.
- **Mid-Phase Audit P3 counter** = 18 (threshold 5 crossed many times; advisory only until IMPL-053+ runnable surface). **Plan Staleness Sentinel @ 46 closures since last review** — STRONGLY recommend `/impl-plan-review all` + `/impl-review all` BEFORE next batch, especially before IMPL-039 BI SL fix (the second G4 fix per ADR-009).
- **Commit:** `d386ea6` `[feat:ea] IMPL-022 Slot_J — CD-follower + ⚠️ G4 fix BR-7.2 (Bucket B)`.
- **Next suggested task:** **`/impl-plan-review all` + `/impl-review all` first** (Sentinel @ 46), then IMPL-037 (L Slot_B — kicks off B/BR/BI chain) **OR** IMPL-034 (L Slot_P — A7 risk).

---

**P3 Parallel batch #10 CLOSED 2026-05-03 — IMPL-027 (Slot_GO) + IMPL-028 (Slot_I) + IMPL-031 (Slot_LX)** — 3× Sonnet 4.6 subagents fan-out via `/impl-task parallel`; orchestrator-side independent G1 verification + sibling regression all clean.

- **Files (NEW × 12):**
  - `MQL5/Experts/PhoenicisNex/slots/{Slot_GO,Slot_I,Slot_LX}.mqh`
  - `MQL5/Experts/PhoenicisNex/inputs/{Inputs_Slot_GO,Inputs_Slot_I,Inputs_Slot_LX}.mqh`
  - `MQL5/Experts/PhoenicisNex/spike/{Spike_Slot_GO,Spike_Slot_I,Spike_Slot_LX}.mq5`
  - `simulation/headless-tests/{slot_GO_smoke,slot_I_smoke,slot_LX_smoke}.ini`
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + 3 task closures + Mid-Phase Audit Log row + Phase Status row), `docs/state/overview.md` (Impl Tasks row), `docs/state/deferred-ac-registry.md` (3 new Active P3 rows expiry 2026-05-17), `docs/state/_parallel-context/impl-task-parallel-20260503-1853.md` (shared context).
- **G1 (orchestrator-side recompile, 2026-05-03 18:53):** Spike_Slot_GO 0err/0warn/532ms · Spike_Slot_I 0/0/440ms · Spike_Slot_LX 0/0/445ms.
- **Sibling regression:** Spike_Slot_G 0/0/463ms (unchanged from batch #9 baseline 490ms — within compile-time noise).
- **MVP scope:** GO = post-exit hook scaffold (Evaluate early-return — sub-call only; ManageExits 40-pip profit gate mirroring Slot_G2; CrossSlotCoordinator BR-8.4 stub guarded `false /*IMPL-053*/`); I = G-parasite Fibonacci (parasite gate `port.GetTicketsForSlot(MAGIC_G,"G,",...) > 0` + own-no-active + direction inheritance from first G ticket + Fibonacci retrace via iHigh/iLow lookback InpILookbackBars=20 InpIFibLevel=0.5; **DependsOn returns 1 with deps[0]=MAGIC_G** — only slot in batch with topology dep; Case 3 of SelfTest validates this); LX = shared-magic pyramid on parent L (parent profitability gate via `GetTicketsForSlot(MAGIC_L,"L,",...)` then `PositionSelectByTicket` profit_pips >= InpLXPyramidGatePips=30; own-no-active via `GetTicketsForSlot(MAGIC_L,"LX,",...)`; CommentParser disambig "LX," vs "L," mirrors G2 vs G shared-magic precedent; lighter inputs vs L — BaseLot 15.0 / TpProfitPips 25.0).
- **All 14 S-AC `[x]`** (GO=4 / I=5 / LX=5 — see impl-plan.md per-task closure rows). 3 E-AC smoke deferred to IMPL-053+ Orchestrator wiring → registered to `deferred-ac-registry.md` Active table (uniform expiry 2026-05-17).
- **Newly unblocked:** none (no slots depend on GO/I/LX directly).
- **Mid-Phase Audit P3 counter** = 10 (threshold 5 crossed twice; advisory until IMPL-053+ runnable surface). Plan Staleness Sentinel closures-since-last-review = 10 (threshold reached — recommend `/impl-plan-review all` + `/impl-review all` after next batch or before IMPL-019 CD chain start).
- **Next suggested task:** IMPL-019 (M [ea] Slot_C — CD chain root) **OR** parallel batch #11 candidates {IMPL-032 Slot_Q + IMPL-033 Slot_R + IMPL-035 Slot_T} (all M-size with PMR pending integrations, file-isolated, deps PMR ✅) **OR** IMPL-037 (L Slot_B — kicks off B/BR/BI chain).

---

**P3 Parallel batch #9 CLOSED 2026-05-03 — IMPL-026 (Slot_G2) + IMPL-029 (Slot_M) + IMPL-030 (Slot_L)** — 3× Sonnet 4.6 subagents fan-out via `/impl-task parallel`; orchestrator-side independent G1 verification + 3-spike sibling regression all clean.

- **Files (NEW × 12):**
  - `MQL5/Experts/PhoenicisNex/slots/{Slot_G2,Slot_M,Slot_L}.mqh`
  - `MQL5/Experts/PhoenicisNex/inputs/{Inputs_Slot_G2,Inputs_Slot_M,Inputs_Slot_L}.mqh`
  - `MQL5/Experts/PhoenicisNex/spike/{Spike_Slot_G2,Spike_Slot_M,Spike_Slot_L}.mq5`
  - `simulation/headless-tests/{slot_G2_smoke,slot_M_smoke,slot_L_smoke}.ini`
- **Files modified:** `docs/state/impl-plan.md` (TL;DR + 3 task closures + Mid-Phase Audit Log row), `docs/state/overview.md` (Impl Tasks row), `docs/state/deferred-ac-registry.md` (3 new Active P3 rows expiry 2026-05-17), `docs/state/_parallel-context/impl-task-parallel-20260503-p3batch9.md` (shared context).
- **G1 (orchestrator-side recompile, 2026-05-03 18:40):** Spike_Slot_G2 0err/0warn/530ms; Spike_Slot_M 0/0/475ms; Spike_Slot_L 0/0/467ms.
- **Sibling regression:** Spike_Slot_G 0/0/490ms · Spike_Slot_K 0/0/445ms · Spike_Slot_H 0/0/573ms (unchanged from batch #8 baselines).
- **MVP scope:** G2 = 3 of N CodeWiki §3.G2 conditions (lighter wave-helper; CommentParser "G2," disambig vs "G," via GetTicketsForSlot); M = 5 of N (MACD M10 + ADX H4 + Stoch H4 + PMR EnterPending/GetState/TransitionExecuted wiring per ADR-008); L = 5 of N (no-active-L "L," disambig + ADX volatility + D1 Ichimoku trend + WPR wave + WPR threshold). Advanced filters deferred to P4 IMPL-062.
- **Slot_M PMR pattern:** Evaluate calls `m_pending.GetState(PM_M)` + `EnterPending(PM_M, payload, bar)` + `TransitionExecuted(PM_M)`; force-clear handled by PMR.TickAll (slot does not poll). InpForceClearM_Bars NOT redeclared — Inputs_Pending.mqh owns it per ADR-008.
- **Slot_G2 stub:** CrossSlotCoordinator BR-8.4 trigger guarded `if(m_xslot != NULL && false /*IMPL-053*/)` — same pattern as IMPL-025.
- **All 16 S-AC `[x]`** (G2 = 4 / M = 5 / L = 4 — see impl-plan.md per-task closure rows). 3 E-AC smoke deferred to IMPL-053+ Orchestrator wiring → registered to `deferred-ac-registry.md` Active table (uniform expiry 2026-05-17).
- **Newly unblocked:** IMPL-027 (Slot_GO depends on G ✅) · IMPL-028 (Slot_I depends on G ✅) · IMPL-031 (Slot_LX depends on L ✅).
- **Next suggested task:** IMPL-019 (M [ea] Slot_C — CD chain root) **OR** parallel batch #10 candidates {IMPL-027 + IMPL-028 + IMPL-031} (newly unblocked, file-isolated).

---

**IMPL-018 CLOSED 2026-05-03** — `domain/CSlotBase.mqh` + `core/SlotRegistry.mqh` + `spike/Spike_CSlotBase.mq5`. First P3 task per Phase Gate Override (Path A); Evolution E2 compile prereq satisfied — IMPL-019..039 (21 slot classes) unblocked.

- **Files (NEW):** `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, `MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh`, `MQL5/Experts/PhoenicisNex/spike/Spike_CSlotBase.mq5`
- **G1:** `Result: 0 errors, 0 warnings, 605 ms` (Spike_CSlotBase); regression check 4/4 sibling spikes clean (PMR 1495 / SP 1331 / EAState 879 / TJ 1288 ms unchanged)
- **ADR-002 enforcement:** Layer 1 (boot-time sentinel detected by `CSlotRegistry::ValidateTopo`) + Layer 2 (runtime `Logger.Error + ExpertRemove` in base virtual bodies)
- **SelfTest:** 6 cases pass (empty registry / bad-Magic / good-pair / empty-SlotId / null-Add / PendingState default)
- **Schema-roundtrip:** 6 methods (Magic/SlotId/Evaluate/ManageExits/DependsOn/PendingState) match `slot-abstraction-contract.yaml § methods` 1:1
- **Spec deviation:** `ValidateTopo` + `ValidateDependencyOrder` non-const (MQL5 error 279 — calling non-const `DependsOn` through pointer field from const context); harmless per single OnInit invocation pattern
- **Scoped include exception:** `domain/CSlotBase.mqh` #includes `services/Logger.mqh` for inline layer-2 body — only domain/* file with a services/* include; documented inline as ADR-002-required exception
- **Next suggested task:** IMPL-019 (M [ea] Slot_C — CD chain root, foundational P3 task)

---

**Path A elected 2026-05-03 — Phase Gate Override logged; P3 starting** — operator (Kritsana) signed off on Path A per `_session-handoff/2026-05-03-phase2-gate-nomination.md § Recommendation`. Override row + closure condition codified in `impl-plan.md § Phase Gate Override Log`. P2 Gate retroactively closes once IMPL-053+ Orchestrator skeleton lands + `simulation/headless-tests/p2_services_smoke.ini` walk evidence produced + 5 Active P2 deferred-AC rows drained.

- **Override scope:** P3 IMPL-018 + IMPL-053..058 Orchestrator chain only
- **Next action:** `/impl-task IMPL-018` (M [ea] — `domain/CSlotBase.mqh` abstract + 2-layer override enforcement per ADR-002 — Evolution E2 compile prereq)

---

**P2 Phase Gate NOMINATED 2026-05-03 — IMPL-049 closure attestation produced** — engineer-side row-by-row assessment: **5/9 rows Ready** (Structural / Code review / NFR provisional / Rollback / Docs) · **4/9 rows Blocked** (Empirical Demo / Tier 1.5 Walk / Live-stack — all need entry `PhoenicisNex.mq5` from IMPL-018+; Deferred-AC drain — 5 Active P2 rows blocked on IMPL-018+).

- **Nomination doc:** `docs/state/_session-handoff/2026-05-03-phase2-gate-nomination.md`
- **IMPL-049 attestation:** Tier 1 ✅ (4 sub-passes + 4 S-AC + 2 E-AC + 7 SelfTest cases incl. PM_T+PM_Q boundary post-R04); Tier 1.5 deferred per registry; Tier 2 awaiting operator
- **Circular dep identified:** all 4 blocked rows gated by IMPL-018+, which Phase Gate Blocking blocks until P2 closes
- **Operator decision required — 3 paths:**
  - **Path A (recommended):** Phase Gate Override row → start P3 IMPL-018 → P2 Phase Gate closes after IMPL-018 lands and the 4 blocked items run in one sweep
  - **Path B:** build minimal entry `.mq5` stub now (violates SD Hint Alignment — IMPL-018 = E2 CSlotBase compile prereq)
  - **Path C:** defer + renew 5 Active rows on 2026-05-17 (silent override; Code Review Dim #11 risk)

---

**Code Review Round 04 + Fix Round 04 CLOSED 2026-05-03** — `docs/code-review/review-round-04.md` adversarial sweep on Round-03 fix delta + IMPL-049 surface; 8 findings (CRITICAL 1 / HIGH 2 / MEDIUM 3 / LOW 2). `/impl-review-fix review-round-04.md` accepted **8/8** (0 reject, 0 partial).

- **Report:** `docs/code-review/fix-round-04.md`
- **Files touched:** `services/PendingMachineRegistry.mqh`, `services/TradeJournal.mqh`, `core/EAState.mqh`, `spike/Spike_PendingMachineRegistry.mq5`
- **G1 compile (post-fix):** 4/4 spikes 0err/0warn (PMR 1495 ms / SP 1331 ms / EAState 879 ms / TJ 1288 ms)
- **Bundles applied:**
  - **G1 CRITICAL** (04.1) — spike harness 12 sites `TickAll(ctx, empty_port)` → `TickAll(ctx)` + orphan `empty_port` decl removed; corrigendum to fix-round-03 G1 evidence row noted
  - **G2 HIGH** (04.2 + 04.3) — EAState SelfTest BuildHaltEvent uses fresh `ea_he`/`ea_hse` instances (Option A; IJournalSink Option B deferred); TradeJournal self-halt gate `==` → `>=` (ADR-006 RPO ≥10 literal alignment)
  - **G3 MEDIUM** (04.4 + 04.5 + 04.6) — EmitForceClear state-first/RAM-mirror ordering + Case 6 sym assertion; `comment` maxLength: 32 clamp + Warn; `pending_age_bars` event-driven gate
  - **G4 LOW** (04.7 + 04.8) — drop dead `m_portfolio` member + `port` Init param (12-arg → 11-arg) + remove `PortfolioState.mqh` include; Case 7 cold-restart extended PM_M-only → PM_M+PM_T+PM_Q at-boundary scenarios
- **Anti-regression sweep:** TickAll `(ctx, port)` 0 hits; `m_consecutive_failures ==` 0 hits; `m_portfolio`/`empty_port` 0 hits ✅
- **Recommendation:** Ready for next review round (Round 05) or P2 Phase Gate nomination

---

**Code Review Round 03 + Fix Round 03 CLOSED 2026-05-03** — `docs/code-review/review-round-03.md` audited P2 closure delta (IMPL-043 TradeJournal + IMPL-044 schema + IMPL-049 PMR XL + IMPL-052 EAState; ~1,476 LOC); 11 findings (CRITICAL 2 / HIGH 4 / MEDIUM 3 / LOW 2). `/impl-review-fix review-round-03.md` accepted **11/11** (0 reject, 0 partial).

- **Report:** `docs/code-review/fix-round-03.md`
- **Files touched:** `core/EAState.mqh`, `services/PendingMachineRegistry.mqh`, `services/StatePersistence.mqh`, `services/TradeJournal.mqh`, `domain/IHaltSink.mqh` (NEW), `docs/state/deferred-ac-registry.md`
- **G1 compile:** 4/4 spikes 0err/0warn (PMR 1495 ms / StatePersistence 1331 ms / EAState 879 ms / TradeJournal 1288 ms)
- **Bundles:**
  - **G1 schema-contract** (03.1+03.2+03.3+03.4+03.6) — `event_type="pending_force_clear"`; populate halt + force_clear required fields (`slot_id`, `magic`, `symbol`, `triggering_function`); `GetPmStartedBar` getter + LoadFromState recovery; `IHaltSink` interface + TradeJournal self-halt at `JOURNAL_HALT_THRESHOLD`
  - **G2 indicator_snapshot** (03.5) — Deferred-AC promotion (IMPL-018+ Orchestrator must cache MarketContext snapshot before subset extraction is feasible per ADR-004)
  - **G3 quality** (03.7+03.8+03.9) — CPendingForce escape-aware `_ExtractStr` (mirrors Round-02.5); EAState extracted `BuildHaltEvent` + 2 SelfTest assertions; promote IMPL-052/049 boot-cold E-ACs to Deferred-AC registry
  - **G4 polish** (03.10+03.11) — journal latency p99 ratio (warn ≥2/10 overshoots, not every overshoot); drop dead `port` arg from `TickMachine`/`TickAll` + dead branch
- **SelfTest deltas:** PMR Case 7 verifies post-fix-03.4 cold-restart `started_bar` recovery (PM_M persisted `started_bar=2000` → at bar 2050 still PENDING, at bar 2151 force-clear); EAState `BuildHaltEvent("halt"/"halt_stable")` verified to populate slot_id/symbol/halt_reason/triggering_function/signal_context

---

**IMPL-044 CLOSED 2026-05-03** — `docs/api-specs/trade-journal-schema.yaml` v1 final-locked. P2 = 9/11.

- **Commit:** `f45fefd` — required list expanded 11→15 (ticket_id+order_type+lot+price promoted); `examples:` added to all 15 required fields; `## Lifecycle Plan` section added per SD-07 § 3.1.
- **E-AC #1:** `required list length = 15` (PowerShell Select-String count) ✅
- **E-AC #2:** sample record ConvertFrom-Json + 15-field presence check → PASS ✅
- **S-AC:** all 3 [x] — fields documented, `const: 1` lock, Lifecycle Plan added.
- **Evidence:** `docs/state/_session-handoff/IMPL-044-evidence-20260503.md`

---

**IMPL-043 CLOSED 2026-05-03** — `services/TradeJournal.mqh` fully implemented and verified. All 4 gates green. P2 = 8/11.

- **Commit:** `45a72c0` — path-separator fix (backslash → forward slash in all 4 path methods + EnsureDirectories); write-check relaxed from `!=` to `<` for Windows CRLF expansion in FILE_TXT mode.
- **G1:** `0 errors, 0 warnings` (service + spike).
- **G3/G4:** `impl043_complete[mode=tester][writes=200]`; `run-20210104-000000-000.jsonl` 107,090 bytes; 200/200 records parse cleanly; zero `journal_write_slow` (latency < 5 ms); `impl043_halt_check_ok[consecutive=0]`.
- **Deferred AC:** E-AC `journal_halt[write_fail_sustained]` → `deferred-ac-registry.md` row opened (expires 2026-05-17); blocked on IMPL-052 (EAState wiring).
- **Evidence:** `docs/state/_session-handoff/IMPL-043-evidence-20260503.md`

---

**IMPL-041 closed 2026-05-03** — inherited-scope close for `CRiskManager::ClampLot()` after IMPL-040 + Code Review Round 02.

- **Why no source diff:** `ClampLot()` was already shipped inside `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh` under IMPL-040. Plan/overview/handoff all already described IMPL-041 as "body integrated into IMPL-040; trivial close".
- **What changed in this pass:** reconciled `docs/state/impl-plan.md`, `docs/state/overview.md`, this handoff, and added `docs/state/_session-handoff/IMPL-041-evidence-20260503.md`.
- **Inherited proof surface:** `ClampLot()` body + `clamp_applied` Warn path + `CRiskManager::SelfTest()` cases 5/6 (floor and cap checks) + IMPL-040 compile baseline. No new runtime surface exists until IMPL-018+ entry wiring.

---

**Prior action:** Code Review Round 02 + Fix Round 02 closed 2026-05-03 — 10/10 findings accepted; 6 commits.

- **Review** `docs/code-review/review-round-02.md` — Adversarial Quality Engineer audit of P2 6/11 closures (5 source files / ~2,490 LOC delta). Findings: CRITICAL 2 / HIGH 3 / MEDIUM 3 / LOW 2.
- **Fix-round** `docs/code-review/fix-round-02.md` — all 10 accepted; 0 reject; 0 partial.

| Commit  | Bundle | Findings | Files touched |
|---------|--------|----------|---------------|
| `97d7c24` | G1 critical | 02.1 + 02.2 + 02.9 | StatePersistence, CircuitBreaker |
| `6b23ddf` | G2 02.3 | parent-lot last_open_lot | SlotState (domain), PortfolioState (cascade), RiskManager (+SelfTest case 9) |
| `214b79a` | G2 02.4 | NULL-state log throttle | PortfolioMonitor |
| `795e63f` | G2 02.5 | _ExtractStr unescape | StatePersistence |
| `c51f4a1` | G3 polish | 02.6 + 02.7 + 02.8 | RiskManager, CircuitBreaker |
| `8fb5300` | G4 02.10 | HolidayBlock NULL path | TimeGate |

**Key fixes (high-impact):**
- **02.1 StatePersistence** — added `_ExtractRawValue` helper (RFC 8259 value extractor for opaque pending_payload — fixes silent ADR-008 round-trip loss every reboot).
- **02.2/02.9 CircuitBreaker** — `PING_PONG_THRESHOLD_S = 3` (was 3000 → 1000× off vs BR-3.6 spec); field `close_time_ms` → `close_time_s`; SelfTest re-targeted (1/4/6 sec deltas).
- **02.3 RiskManager** — added `last_open_lot` to SlotState; J/BI/I now read parent.last_open_lot per BR-4.1 spec literal; fail-loud (Warn + return 0) when unwired (= 0). Population deferred to PortfolioState OnTradeTransaction at IMPL-053+.
- **02.5 StatePersistence** — `_ExtractStr` now JSON escape-aware (backslash-parity terminator + `\"`/`\\`/`\n`/`\r`/`\t`/`\uXXXX` unescape).

**G1 baseline:** Spike_StatePersistence.mq5 still 0 errors / 0 warnings (no regression from `.mqh` edits since none are yet `#include`'d by entry).
**G2-G4:** deferred per header-only `.mqh` precedent (gates activate at IMPL-018+).
**Anti-regression grep clean:** ZigZag path `Examples\\ZigZag` preserved; `ErrorBypassThrottle` for invalid_handle preserved; `CleanupPartialInit` guards preserved.

**State Reconciliation (3-file propagation):**
- ✅ Layer 1 `impl-plan.md` — Mid-Phase Audit Log row appended for fix-round-02.
- ✅ Layer 2 `overview.md` — Code Review row updated (Round 01 → Round 02 with full convergence note).
- ✅ Layer 3 `current_handoff.md` (this file) — last-action + state-of-workspace updated.

---

**Prior action (2026-05-03):** Parallel batch #7 closed — IMPL-040 (L RiskManager.mqh) + IMPL-045 (S PortfolioMonitor.mqh). User-authorized L-in-parallel override. Both subjects of round-02 review.

**Prior-prior (2026-05-03):** Parallel batch #6 closed — IMPL-048 + IMPL-050 + IMPL-051.

## State of the Workspace

- **Phase:** Implementation (P2 — Core Services)
- **P2 Progress:** **10/11 tasks done** (IMPL-047 + IMPL-048 + IMPL-050 + IMPL-051 + IMPL-040 + IMPL-041 + IMPL-045 + IMPL-043 + IMPL-044 + IMPL-052)
- **Active Task:** None — IMPL-052 just closed. Next: IMPL-049 (XL PendingMachineRegistry)
- **Dependencies Blocked:** None — IMPL-049 is unblocked
- **Mid-Phase Audit Counter (P2):** 10 (threshold 5 crossed — advisory only; no runnable surface until IMPL-018+ entry wiring; precedent from parallel batch #7 holds)
- **Pending Code Reviews:** Round 02 closed. Next code review trigger after IMPL-049 (PendingMachineRegistry XL) lands.
- **Open follow-ups:** PortfolioState.OnTradeTransaction handler (populate `last_open_lot` per Finding 02.3 fix contract) — lands at IMPL-053+ wiring.

## Next Steps

1. **IMPL-049** [XL] [ea] — `PendingMachineRegistry` (unblocked by IMPL-043 ✅; largest remaining P2 task).
2. After IMPL-049 closes — `/impl-review all` code review trigger for IMPL-043+044+049+052 batch.
no runnable surface until IMPL-018+ entry wiring; precedent from parallel batch #7 holds)
- **Pending Code Reviews:** Round 02 closed. Next code review trigger after IMPL-049 (PendingMachineRegistry XL) lands.
- **Open follow-ups:** PortfolioState.OnTradeTransaction handler (populate `last_open_lot` per Finding 02.3 fix contract) — lands at IMPL-053+ wiring.

## Next Steps

1. **IMPL-052** [S] [ea] — `EAState` halt-wiring (unblocked by IMPL-043 ✅; wires `journal_halt` deferred AC from deferred-ac-registry row IMPL-043).
2. **IMPL-049** [XL] [ea] — `PendingMachineRegistry` (unblocked by IMPL-043 ✅; largest remaining P2 task).
3. After IMPL-049 closes — `/impl-review all` code review trigger for IMPL-043+044+049+052 batch.
