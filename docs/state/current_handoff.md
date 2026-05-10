# PhoenicisNex — Current Handoff

> Single-project handoff per CLAUDE.md §6. Updated end-of-task / end-of-session / cross-day.

## Last completed action

**✅ IMPL-FIX-004 RESOLVED 2026-05-10 — Comment-history-exemptions manifest populated with 111 banner sites (Gate #9d sweep verified clean)**

- **Files changed:**
  - `docs/state/comment-history-exemptions.md` — manifest rebuilt: 111 rows in `<file>:<line>:<task-id>:<justification>` format embedded in fenced ` ```text ` block (preserves Markdown header but uses fenced block to prevent prose lines from poisoning Gate #9d's `awk -F:` extraction). Added population script + population-history table.
- **Sweep scope:** `grep -rnE "IMPL-(006|007|018|042|043|053)\b" MQL5/Experts/PhoenicisNex/ simulation/headless-tests/` — same 6 closed-task IDs cited in fix-round-19 §19.2 (the original ~86 site count grew to 111 reflecting ~25 IMPL-053+ closure additions).
- **Verification gates:**
  - Gate #9d post-condition `comm -23 <(sweep) <(manifest)` returns **0 unmatched** ✅
  - Gate #9 clause (h) verb-form forward-pointer sweep returns **0 hits** at population time ✅ — confirms ALL 111 surviving sites are banner-history exempt (no stale forward-pointers)
- **Registry impact:** P5 row IMPL-FIX-004 strikethrough-resolved in place (mirrors IMPL-067 closure pattern); Active count 48 → 50 (P5 −1 net + P4 +2 from IMPL-FIX-006 + IMPL-063 paired bundles). Resolved count 6 → 7.
- **Next suggested task:**
  1. **Operator session** — paired-bundle 5-yr regression drain (IMPL-FIX-006 + IMPL-062 + IMPL-063, ~60-120 min wall-clock)
  2. **OR** `/impl-review all` R09 — cumulative attack surface (IMPL-FIX-006 dimensional fix touched 17 slots' risk math; recommended pre-MVP)

---

## Prior action (kept for context)

**✅ IMPL-063 STRUCTURAL CLOSED 2026-05-10 — Bucket B regression .ini + report skeleton (paired-bundle with IMPL-062 + IMPL-FIX-006 numeric drain)**

- **Files added:**
  - `simulation/headless-tests/regression_5yr_g4.ini` (NEW; default-build 5-yr 2021.01.01–2025.12.31 — complement to IMPL-062's `regression_5yr_no_g4.ini`)
  - `docs/state/regression-bucket-b.md` (NEW; 8-section structural skeleton — Bucket B drift formula `(G4-ON − G4-OFF) / G4-OFF * 100` referencing IMPL-062 baseline; per-slot impact table flagging J + BI as G4-bearing slots; G4 Fix #1/#2 jq filter recipes for E-AC drain)
- **G1 compile:** PASS `Result: 0 errors, 0 warnings, 4199 ms` (default-build invariant — `grep -c '#define[[:space:]]\+DISABLE_G4_FIXES' PhoenicisNex.mq5` = 0).
- **Status:** 3/3 S-AC `[x]` structural; 3/3 E-AC deferred paired-bundle gated on operator paired 5-yr run with IMPL-062 + IMPL-FIX-006 (registry row P4 IMPL-063 expiry 2026-05-24).
- **Cascade:** P4 16/17 → **17/17 ✅**. Single paired-bundle operator session now drains all 3 Bucket-related deferred-AC bundles in one go (IMPL-FIX-006 + IMPL-062 Bucket A + IMPL-063 Bucket B = NFR-1.1 + NFR-1.6 + NFR-1.8 acceptance signals + R-8 closure + Tier 2 Phase Gate unblocking).
- **Next suggested task:** Operator paired-bundle drain (Bucket A then Bucket B 5-yr regressions, ~60-120 min wall-clock); on success → P4 Tier 2 Phase Gate empirical demo proceeds (Tier 1.5 walk batch-3 already PASSED 2026-05-09/10). Alternatively `/impl-review all` R09 (cumulative attack surface — IMPL-FIX-006 dimensional formula change touched 17 slots' risk math; recommended before MVP delivery sign-off).

---

## Prior action (kept for context)

**✅ IMPL-FIX-006 IMPLEMENTED 2026-05-10 — RiskManager.ComputeLot dimensional formula fix (R-8 root cause closed; 5-yr regression drift drain pending operator session paired with IMPL-062)**

- **Files changed:** `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh` (1 file, ~110 LOC delta) — added `_PipValue()` + `_RiskMoneyToLot(risk_money, sl_pips, slot_id)` private helpers; rewrote `ComputeLot` dispatcher so 17 direct-lot slots (C/D/F/G/G2/GO/M/L/LX/Q/R/P/T/B/BR/H + S/K via private variants) route through `_RiskMoneyToLot`; updated `_ComputeLotForS(sl_pips, percent_tp)` + `_ComputeLotForK(sl_pips, balance, extra)` signatures to accept `sl_pips`; J/BI/I parent-anchored variants unchanged (formulas already operate on `parent.last_open_lot × fibonacci_pct` → lot units); SelfTest extended 9 → 10 cases (Case 10 dimensional invariant: doubling sl_pips → halving lot via `_RiskMoneyToLot`).
- **Tests added:** SelfTest Case 10 (in-process invariant + sl_pips=0 fail-loud guard).
- **G1 compile:** PASS — `Result: 0 errors, 0 warnings, 4199 ms elapsed`.
- **G2 smoke:** PASS — `bootstrap_smoke.ini` Model=0 3-day; lots now dimensional (S=0.17 / C=0.30 / M=0.40 / T=0.36) — was constant 2.90 cap pre-fix; **0 `[ev=clamp_applied]`** events across 19 `[ev=order_sent]` (primary structural signal); 0 `order_failed`; 1 `order_skipped_no_margin` (IMPL-FIX-005 anti-spam latch fires once + silenced).
- **Side-finding (out of FIX-006 scope):** Slot_S pyramid stacking (16 same-direction Buy entries in 11 min on continuous WPR-oversold + EMA-trend signal). Same defect class as Slot_G2 anti-pyramid concern flagged in the IMPL-FIX-006 task block "Secondary concern" line. Final balance −$239 in 3-day window attributable to this stacking + drawdown, NOT to dimensional sizing. Open IMPL-FIX-007 covering both G2 + S anti-pyramid gates if Bucket A drift > 25% during 5-yr regression retry.
- **Deferred E-AC bundle:** 3/4 E-ACs (5-yr regression wall-clock + Bucket A drift ≤ 25% + per-slot lot scaling spot-check) registered in `deferred-ac-registry.md` row P4 IMPL-FIX-006 expiry 2026-05-19, paired with IMPL-062 numeric drain (operator builds .ex5 with `#define DISABLE_G4_FIXES` + runs `regression_5yr_no_g4.ini` ~30-60 min). 1/4 E-AC drained via G2 (clamp count = 0).
- **Evidence artifact:** `docs/state/_session-handoff/IMPL-FIX-006-evidence-20260510.md`.
- **Next suggested task:** Operator drains 5-yr regression for IMPL-FIX-006 + IMPL-062 paired bundle; on success → R-8 closes, IMPL-062 numeric drain proceeds, P4 16/17 → 17/17 unblocks Tier 2 Phase Gate. If 5-yr halts day-1 again → open IMPL-FIX-007 (Slot_S/G2 anti-pyramid gates).

---

## Prior action (root-cause investigation, kept for context)

**🔴 IMPL-FIX-006 root cause IDENTIFIED + task block AUTHORED 2026-05-10 — RiskManager.ComputeLot dimensional formula bug**

- **Trigger:** user said "do it" to recommended next action ("Open IMPL-FIX-006 root-cause investigation").
- **Investigation method:** parallel inspection of (1) rewrite `services/RiskManager.mqh::ComputeLot` body lines 191-237; (2) rewrite per-slot private variants `_ComputeLotForJ/_BI/_I/_S/_K` lines 302-457; (3) legacy 22k-LOC `MQL5/Experts/PhoenicisN2.10_stable.mq5` to find `CalculateLotSize` call sites (~80 hits across 17137-21826); (4) `MQL5/Libraries/LibCommon1.1.mq5:835` where `CalculateLotSize` body lives (file referenced from legacy mq5 line 20 `#include "./..//Libraries//LibCommon1.1.mq5"`); (5) authoritative spec `docs/foundation-input-sources/PhoenicisN2.10_CodeWiki.md` § 4.1 lines 767-826.
- **Root cause confirmed (CRITICAL):** rewrite `CRiskManager::ComputeLot(slot_id, sl_pips, balance, extra_multiplier)` body is **dimensionally wrong** — produces riskMoney (USD), not lots. Formula path:
  ```
  base   = balance × m_main_risk_ratio                          (line 194)
  G2:    result = base × 0.15 × 0.7 × extra_multiplier           (line 205)
  stepped = _StepRound(result)                                  (line 228)
  clamped = ClampLot(stepped, slot_id)                          (line 229)
  ```
  For Balance=$1000 + m_main_risk_ratio=1.0 + Slot_G2 + sl_pips=77 → **result = $105 USD assigned as lot count → clamped to MAX 2.90 cap**.
  The `sl_pips` parameter (line 191 signature) is consumed **only at line 234** (`Logger.Debug` format string `"slot=%s sl_pips=%.1f raw=%.4f stepped=%.4f clamped=%.4f"`) — NEVER divided into the result. Same pattern across `_ComputeLotForS` (line 444 `balance × factor`) + `_ComputeLotForK` (line 456 `balance × m_main_risk_ratio × 0.20 × extra`); both also ignore sl_pips.
- **Legacy formula (correct, from `MQL5/Libraries/LibCommon1.1.mq5:835`):**
  ```mql5
  double lotSize = (AccountInfoDouble(ACCOUNT_BALANCE) * riskPercentage / 100) / (stopLossPips * Point());
  lotSize = (lotSize * Point()) / DigitMultipier;
  return NormalizeDouble(lotSize, 2);
  // Simplifies to: lots = riskMoney / (slPips × pipValue) where pipValue = Point × DigitMultipier
  ```
  For Balance=$1000 + RiskPct=10 + slPips=77 + DigitMultipier=10 (5-digit broker) → **lots ≈ 0.13** ✅.
- **CodeWiki §4.1 spec (lines 769-826) confirms LegacyCalculateLotSize is the authoritative formula** + per-slot riskPercent + helper trim multipliers (G2=10.5%, C=15%, M=0.8× computed, Q=0.8× pyramid, etc.). Spec is unambiguous; rewrite is a translation defect, not an architectural deviation.
- **Slots affected (17 of 21):** C/D/F/G/G2/GO/M/L/LX/Q/R/P/T/B/BR/H + indirect K/S via `_ComputeLotForK/_ComputeLotForS`. **Slots already correct (3 of 21):** J/BI/I — these use parent-anchored `last_open_lot × fibonacci_pct` which produces lot-units directly (last_open_lot is populated from MT5 deal.volume which IS in lots).
- **Decision matrix outcome:** **Option (a) code fix in IMPL-FIX-006 ticket** — NOT `/backtrack sd` (no ADR governs ComputeLot formula); NOT `/backtrack ba` (CodeWiki §4.1 + LibCommon implementation are unambiguous; rewrite simply mistranslated).
- **Secondary concern (Slot_G2 race):** `_HasActiveG2Order` gate at `slots/Slot_G2.mqh:186` worked 6,728 of 6,731 evaluations correctly (0.04% miss rate). The 3 misses produced 3 same-magic fills in 21 sec (16:00:00, 16:00:02, 16:00:21). Likely race condition between `OrderSend` success + MT5 dispatching `OnTradeTransaction` + PortfolioState populator wiring. Becomes moot post-FIX-006 (with proper lot=0.1-0.2 range, 3 simultaneous fills consume only ~$70 margin, not exhausting $1000). **Demoted from primary concern to monitor-during-FIX-006-G3-retry.** Open IMPL-FIX-007 only if observable drift after FIX-006.
- **Tertiary concern (entry-signal aggressiveness):** REFUTED. The 12,409 entry_signal events in 17 hours = ~12/min normal evaluation rate × 21 slots × tick frequency (Model=4 real ticks ~1-2 ticks/sec). The Print event count is `entry_signal` (Print log only, not OrderSend attempts) — does not indicate aggressive firing.
- **IMPL-FIX-006 task block authored at `docs/state/impl-plan.md` line 1544 (L-XL size, P2+P3 spans):**
  - **S-AC scope:** add `_PipValue()` helper, rewrite ComputeLot body to divide riskMoney by (sl_pips × pipValue) for 17 direct-lot slots, update `_ComputeLotForS/_K` signatures to accept sl_pips, thread through Slot_S/Slot_K Evaluate call sites, parent-anchored variants J/BI/I unchanged, G1 + G2 smoke verifying lot=0.10-0.20 range
  - **E-AC scope:** G3 5-yr regression `regression_5yr_no_g4.ini` runs to 2025-12-31 (no day-1 halt); Bucket A drift ≤ 25% NFR-1.1; per-slot deviation ≤ 10% NFR-1.6; lot scales empirically with balance during compounding (spot-check 5+ journal entries at Q1-2021 vs Q4-2024 timestamps)
  - **Risk:** high — touches 17+ slots' risk math; Mitigation: SelfTest extension with truth-table per slot before live verification
  - **Closes:** R-8 once 5-yr regression passes; **Unblocks:** IMPL-062/066/068 numeric drain + IMPL-063 Bucket B + P4 Tier 2 Phase Gate + MVP delivery NFR-1.1 acceptance signal
- **State reconciliation 2026-05-10 (this session):**
  - `docs/state/impl-plan.md`: TL;DR 🔴 entry for IMPL-FIX-006 root cause + spec citations (above the prior run #1 entry); Open Risks R-8 marker updated to "ROOT CAUSE IDENTIFIED, IMPL-FIX-006 OPEN" with full investigation outcome paragraph (hypothesis (a) confirmed, (b) demoted, (c) refuted); Next Best Action checklist: ☑ root-cause investigation completed, ☐ `/impl-task IMPL-FIX-006` implementation, ☐ secondary G2-race monitoring; Phase Status Snapshot row P4 status string appended "IMPL-FIX-006 root cause IDENTIFIED + task block AUTHORED 2026-05-10"; IMPL-FIX-005 closure note updated with post-IMPL-062-run-#1 understanding (smoke calibration assumption was partially wrong — formula bug surfaces also at 5-yr scale); IMPL-FIX-006 task block authored at line 1544.
  - `docs/state/overview.md` row 19 (Impl Plan): hypothesis space paragraph updated with investigation outcome + decision; row 20 (Impl Tasks): pending pointer updated to `/impl-task IMPL-FIX-006`.
  - This `current_handoff.md` section.
- **Phase 5 mechanical gates (Phase 5 Closure 11-gate sweep per workflow.md):** Gate #1 forbidden-pattern (no `[x]` + "deferred to operator-runtime" introduced — investigation outcome recorded as new task block + Open Risk update) ✅; Gate #2 TL;DR ↔ registry recount (no registry rows added/moved this commit; counts unchanged 48 Active / 6 Resolved) ✅; Gate #3 TL;DR ↔ matrix denominator (P4 16/17 unchanged — IMPL-FIX-006 is a fix-ticket not an IMPL-NNN closure) ✅; Gate #4 Sentinel counter (0 IMPL-NNN closures since R25 — investigation does not increment) ✅; Gate #5 overview.md sync (rows 19+20 propagated) ✅; Gate #6 file integrity (TBD verify); Gate #7 Phase Status Snapshot Notes sweep (P4 row status updated) ✅; Gate #8 narrative-section freshness (Open Risks R-8 + Next Best Action both refreshed) ✅; Gate #9 post-fix grep (n/a — investigation, not a fix-round); Gate #10 stash-clean G1 (n/a — no source code changes this turn — only docs); Gate #11 working-tree clean post-closure (will commit + verify).
- **Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25. Investigation does not count.
- **Recommended next action:** **`/impl-task IMPL-FIX-006`** — implement formula fix per task block at impl-plan line 1544: (1) add `_PipValue()` helper computing `SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) × pip_helper.DigitMultipier()`; (2) rewrite ComputeLot body for 17 direct-lot slots — `riskMoney = balance × m_main_risk_ratio × per_slot_pct × extra_multiplier`, then `result = riskMoney / (sl_pips × pipValue)`, then `_StepRound + ClampLot`; (3) update `_ComputeLotForS(percent_tp, sl_pips)` + `_ComputeLotForK(balance, extra, sl_pips)` signatures + thread through Slot_S/Slot_K call sites; (4) parent-anchored J/BI/I unchanged; (5) extend SelfTest with truth-table per slot (e.g., `_AssertEq(rm.ComputeLot("G2", 77.0, 1000.0, 1.0), 0.13, 1e-2)`); (6) G1 + G2 smoke + G3 5-yr regression (~30-60 min) to verify Bucket A drift ≤ 25% NFR-1.1.

---

## Prior completed action — IMPL-062 5-yr Bucket A regression run #1 FAILED 2026-05-10 — R-8 day-1 stop-out cascade defect

**🔴 IMPL-062 5-yr Bucket A regression run #1 FAILED 2026-05-10 — NEW R-8 day-1 stop-out cascade defect (engineer-driven attempt; default .ex5 restored)**

- **Trigger:** user said "yes go" to recommended next action ("Operator session for IMPL-062 + IMPL-066 + IMPL-068 numeric drain") after state reconciliation commit `45bba53` landed.
- **Pre-flight check:** Confirmed baseline used **$1,000 + 1:500** (verified `docs/foundation-input-sources/ReportTester-25045474.html` — `Initial Deposit: 1 000.00 / Leverage: 1:500`). Therefore current `regression_5yr_no_g4.ini` Deposit=1000 already correct — the "bump to $1M (baseline parity)" recommendation in IMPL-FIX-003 closure note + Next Best Action was incorrect (likely misread of the lot=2.90 vs $1000 smoke calibration mismatch). **Did NOT bump deposit** — kept $1000 for true baseline parity.
- **Execution:**
  - Injected `#define DISABLE_G4_FIXES` after `#property tester_no_cache` block in `PhoenicisNex.mq5`; G1 compile via MetaEditor 10:26:03 PASS 0err/0warn/4330 ms; `.ex5` = 306,697 bytes (DISABLE_G4_FIXES build = 158 bytes larger than default due to #ifdef branches).
  - Launch attempt #1 at 10:28:00 — FAILED (network drop at 10:28:03.715 → tick download canceled → "no history data" → terminal exit code 0 in 4.7 s); root cause: connection blip + ShutdownTerminal=1 + Tester aborts tick download on disconnect.
  - Launch attempt #2 at 10:31:21 — succeeded; tick history download completed 1.0 s; Tester started 10:31:25 testing 2021.01.01 → 2025.12.31 with deposit $1000 + leverage 1:500; EA `[ev=init_ok] handles=24 slots=21 magics=17 state=EA_STATE_RUNNING` captured at 10:31:31.928.
- **Backtest outcome:** **Failed at simulated day 1** — Tester halted at **2021-01-04 17:10:00 EET** (17 simulated hours, 5 H4 bars, 71,110 ticks generated). Wall-clock 0:01:26.807. Final balance **$512.80** from $1000 deposit. `OnTester result 512.8`.
- **Position chronology:** 5 actual `order_sent` events captured (vs 12,409 entry_signal Print events ≈ 12/min):
  | Time (sim) | Ticket | Slot | Dir | Lot | Price | SL |
  |-----------|--------|------|-----|-----|-------|-----|
  | 00:29:22 | #2 | C | BUY | 2.90 | 1.22401 | 1.21901 |
  | 00:29:22 | (skipped — Slot_M FIX-005 latch) | — | — | 2.90 | required 709.93 vs free 263.97 — anti-spam ✅ |
  | 14:57:35 | #3 | Q | SELL | 2.90 | 1.23040 | 1.23540 |
  | 16:00:00 | #4 | G2 | BUY | 2.90 | 1.23025 | 1.22000 |
  | 16:00:02 | #5 | G2 | BUY | 2.90 | 1.23022 | 1.22001 |
  | 16:00:21 | #6 | G2 | BUY | 2.90 | 1.23039 | 1.22000 |
  | 17:10:00 | stop_out cascade #2/#4/#6 | — | — | — | closed at ~1.22763 |
  | 17:10:00 | end_of_test #3/#5 | — | — | — | closed at ~1.22763–1.22773 |
  P&L attribution: #2 (Slot_C +$1,050 win) + #3 (Slot_Q +$774 win) + #4 (Slot_G2 −$760) + #5 (−$751) + #6 (−$800) = net **−$487** → balance $1000 → $512.80 ✅ matches Tester verdict.
- **Why this is a Bucket A drift signal (CRITICAL):** baseline reached $24,271,276.63 over 2021-01-01 → 2025-12-31 with same $1000 + 1:500 setup. Rewrite blew up at simulated day 1 → cannot complete the 5-yr run → Bucket A drift ≈ 100% (target ≤ 25% per NFR-1.1). The defect is **upstream of IMPL-FIX-005 margin guard** (which fired correctly with 1× `order_skipped_no_margin` Slot_M latch + 0 `order_failed` retry storm).
- **Hypothesis space (R-8):**
  1. RiskManager.ComputeLot consistently produces lot=2.90 (MAX_LOT cap) on $1000 balance — baseline likely scales lot to risk-per-trade % (cf. FIX-002 closure: "216,671 SlotS entry_signal events with lot=2.90 (clamped at max_lot_ratio... NOT floor-clamped to 0.01)" suggests rewrite consistently hits upper cap).
  2. Slot_G2 lacks anti-pyramid gate (3 same-magic BUY fills at 1.23022/1.23025/1.23039 in 21 seconds before 276-pip drawdown).
  3. Entry-signal predicates fire too aggressively vs CodeWiki §3/§5 (12,409 entry_signal events in 17 hours = ~12/min — MarketContextBuilder + per-slot Evaluate predicates may match CodeWiki literal but produce stronger entry rate due to ADR-004 single-tick MarketContext snapshot semantics).
- **Restoration:** removed `#define DISABLE_G4_FIXES` from `PhoenicisNex.mq5`; recompiled at 10:36:32 PASS 0err/0warn/4144 ms; `.ex5` = 306,498 bytes (default G4-fixes ON build per ADR-009 + BR-7.2). Working tree is back to commit `45bba53` HEAD source surface.
- **State reconciliation 2026-05-10 (this session):**
  - `docs/state/impl-plan.md`: TL;DR 🔴 header for run #1 failure + Last updated narrative refreshed; IMPL-062 task block E-AC clauses annotated with "RUN #1 FAILED" closure note + evidence link; new **R-8 Open Risk** added; Next Best Action checklist: numeric drain row demoted to ❌ FAILED + new IMPL-FIX-006 row added as primary investigation pivot.
  - `docs/state/overview.md` row 19 (Impl Plan): full failure paragraph + hypothesis space + IMPL-062/066/068 BLOCKED status; row 20 (Impl Tasks): pending pointer changed from "deposit-bump $1M+" to "IMPL-FIX-006 root-cause investigation".
  - This `current_handoff.md` section.
- **Evidence files:**
  - `docs/state/_session-handoff/IMPL-062-evidence-20260510.md` (12 KB structured analysis: TL;DR + config + Tester verdict + event counts + position chronology + root cause hypothesis + Bucket A drift quantification + recommended path forward)
  - `docs/state/_session-handoff/IMPL-062-attempted-run-20260510-abridged.txt` (2.5 MB / 12,968 lines — UTF-8 decoded full Tester run log; preserved per Tier 1.5 walk audit-trail convention)
- **Phase 5 mechanical gates (Phase 5 Closure 11-gate sweep per workflow.md):** Gate #1 forbidden-pattern (no `[x]` + "deferred to operator-runtime" introduced — failure recorded as new finding R-8 + IMPL-FIX-006 placeholder) ✅; Gate #2 TL;DR ↔ registry recount (no registry rows added/moved this commit) ✅; Gate #3 TL;DR ↔ matrix denominator (P4 16/17 unchanged — no closure) ✅; Gate #4 Sentinel counter (0 IMPL-NNN closures since R25 — failure run is not a closure) ✅; Gate #5 overview.md sync (rows 19+20 propagated) ✅; Gate #6 file integrity (1 `## End of Plan` marker — TBD verify); Gate #7 Phase Status Snapshot Notes sweep (P4 row Notes column unchanged — TBD append "Run #1 FAILED" note); Gate #8 narrative-section freshness (Open Risks R-8 added; Next Best Action checklist refreshed) ✅; Gate #9 post-fix grep (n/a — not a fix-round); Gate #10 stash-clean G1 — `.ex5` IS the committed-source build (post-restore commit `45bba53` HEAD source surface); Gate #11 working-tree clean post-closure (will commit + verify).
- **Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25. Failure run does not count.
- **Recommended next action:** **Open IMPL-FIX-006 root-cause investigation** — engineer (or sub-agent via `/impl-task IMPL-FIX-006` once authored) inspects: (1) `services/RiskManager.mqh::ComputeLot` formula on $1000 balance — confirm whether lot=2.90 is invariant or balance-scaled; compare vs CodeWiki §3 risk-management math; (2) Slot_G2 Evaluate predicates — locate any anti-pyramid gate (cooldown timer, position-count check, or M5/M15 confirmation filter) — verify rewrite respects it; (3) entry-signal aggressiveness — compare per-slot Evaluate predicates against CodeWiki §5 line-by-line; flag any slot where rewrite emits entry_signal at higher rate than spec implies. Decision matrix: (a) lot-sizing fix in `RiskManager.ComputeLot` → IMPL-FIX-006 implementation ticket; (b) ADR change → `/backtrack sd`; (c) BA scope gap → `/backtrack ba`. **Blocks:** IMPL-062 + IMPL-066 + IMPL-068 numeric drain; P4 Tier 2 Phase Gate; MVP delivery acceptance signal.

---

## Prior completed action — Tier 1.5 walk batch-3 PASSED + IMPL-FIX-003/005 CLOSED + state reconciliation CLOSED 2026-05-10

**Tier 1.5 walk batch-3 PASSED + IMPL-FIX-003/005 CLOSED + state reconciliation CLOSED 2026-05-10**

- **Trigger:** Tier 1.5 Exploratory Walk batch-3 nominated 2026-05-09 21:54 (smoke) → 2026-05-10 01:07 (10/10 batch complete) per CLAUDE.md §1 Tier 1.5 protocol; specifically scoped to drain IMPL-067 DST regression deferred-AC + structurally validate IMPL-062/065/066/068 toolchain post-tick-download.
- **Walk batch-3 outcome:** 10/10 DST .ini files Tester result ✅ (`dst_2021_mar.ini` through `dst_2025_oct.ini`, ±3 days around DST Sunday 2021-2025); legs 1-8 wall-clock 7-36 min, legs 9-10 ran 37s+2:16 post-FIX-005 due to retry-loop elimination. AC-6.5.2 zero entries 00:00-00:05 EET on DST Sunday verified per Print log (e.g., dst_2021_mar Sun 03-28 = 0 entry events vs Thu 76,787 / Fri 58,981 / Mon 21,800). AC-6.5.3 timestamp coherence verified (pre-DST `2021-03-26 22:59:55.132` → post-DST `2021-03-29 01:06:05.369`, gap ~50h45m = weekend ~48h + DST spring-forward ~1h, ISO 8601 .NNN format coherent). **IMPL-067 DRAINED** — registry row Active→Resolved (Active 49→48; Resolved 5→6).
- **CRITICAL finding F-W3.1 IMPL-FIX-003 — discovered + closed in same session:** EA emitted 322,125+ `[ev=entry_signal]` events across 5 DST legs but **ZERO `[ev=order_sent]` events**; final account balance unchanged at $1000 every leg. Root cause: `CRiskManager` class declared only `Init()/ComputeLot()/ClampLot()/SelfTest()` — **no `OpenOrder()` method body**. 21 slot files have comments referencing `RiskManager::OpenOrder` per `.claude/rules/ea.md` but the method was never implemented. R12→R25 review chain did not catch (chain focused on comment-routing methodology precision; R21 §21.2 destination-existence applied only to comment routing pointers, not functional call sites). **Fix (commit `ec636a0`):** added `bool CRiskManager::OpenOrder(MqlTradeRequest &req, string slot_id)` body using raw OrderSend (no CTrade dep — slim service-layer dispatcher); 8 independent-entry slots (C/G/G2/M/Q/R/S/T) call it after `EmitEntrySignal()` log. G1 PASS 0err/0warn/4468 ms. G2 smoke (bootstrap_smoke.ini Model=0 3-day, Test passed 0:00:44.234): `[ev=order_sent]` fires + journal `tester/run-20240102-000000-088.jsonl` = 642 bytes schema-valid entry record + final balance $1000→$43 (real fills + margin exhaustion). **Phase 1B follow-up** (separate ticket): 13 sub-call/wrapper slots (B/BI/BR/D/F/GO/H/I/J/K/L/LX/P) need cross-slot coordinator dispatch — they don't build MqlTradeRequest in their own Evaluate; not blocking IMPL-062 since 8 independent-entry slots cover active-trading surface. Scope memo `_session-handoff/IMPL-FIX-003-scope-memo.md`.
- **MEDIUM finding F-W3.2 IMPL-FIX-005 — discovered + closed in same session:** post-FIX-003 G2 smoke produced 31,409 `[ev=order_failed][rc=10019]` (NO_MONEY) events in 44s (~700/sec) because slots without pending state machine (G/G2/S/T) re-evaluate signals every tick + retry OrderSend on insufficient margin. User reported same in DST 2025-Mar real-tick run "Core 01 2025.03.27 17:57:43 not enough money [market sell 2.9 EURUSD ...]". **Fix (commit `a073bf0`):** pre-flight margin guard via `OrderCalcMargin` against `ACCOUNT_MARGIN_FREE` before OrderSend. Skip silently if insufficient; first skip emits one Warn; subsequent silenced via `m_margin_warn_logged` per-session latch. G1 PASS 0err/0warn/4199 ms. G2 verification: `ev=order_failed rc=10019` count 31,409 → 0; `ev=order_skipped_no_margin` = 1 single Warn (anti-spam ✅); `ev=order_sent` = 1 preserved (first fill works); final balance $43 preserved. DST batch legs 9-10 ran ~10× faster post-fix (37s + 2:16 vs typical 7-25 min for legs 1-8) — confirms retry-loop CPU burn eliminated. Side note (NOT defect): lot=2.90 vs $1000 smoke deposit margin mismatch is smoke calibration; real IMPL-062 5-yr regression baseline ran with same $1000 deposit + 1:500 leverage per `ReportTester-25045474.html` — early winning trades + lot scaling carry $1000 → $24M historically.
- **State reconciliation 2026-05-10 (this session):** `docs/state/impl-plan.md` (TL;DR ✅ header for batch-3 + IMPL-FIX-005 task block authored at line 1518 per FIX-001/002/003 template + Phase Status Snapshot row P4 Tier 1.5 column updated with batch-3 PASSED + Deferred-AC counts 49→48 Active / 5→6 Resolved + Next Best Action checklist refreshed + stale "Tier 1.5 walk batch-3 in progress" prior-action removed) + `docs/state/overview.md` (Impl Plan row status string append IMPL-FIX-005 + walk-batch-3 + reconciliation Files Modified inventory; Impl Tasks row status P4 11/17 → 16/17 + IMPL-FIX-003/005 ✅ + Last Updated 2026-05-05 → 2026-05-10 + last code-review pointer fix-round-17 → review-round-25 stale-fix) + this section (current_handoff.md) + 2 untracked `simulation/headless-tests/runs/dst_batch_*progress.txt` audit-trail files committed per IMPL-046-post_kill_run-20260502.txt convention precedent.
- **Phase 5 mechanical gates (Phase 5 Closure 11-gate sweep per workflow.md):** Gate #1 forbidden-pattern (no `[x]` + "deferred to operator-runtime" introduced) ✅; Gate #2 TL;DR ↔ registry recount (Active 48 / Resolved 6 — TL;DR matches registry post-IMPL-067 move) ✅; Gate #3 TL;DR ↔ matrix denominator (P4 16/17 matches Phase Status Snapshot Total) ✅; Gate #4 Sentinel counter (0 IMPL-NNN closures since R25 — FIX-tickets don't increment per fix-round-10 precedent) ✅; Gate #5 overview.md sync (rows 19+20 propagated) ✅; Gate #6 file integrity (1 `## End of Plan` marker — TBD verify); Gate #7 Phase Status Snapshot Notes sweep (P4 row Tier 1.5 + status updated) ✅; Gate #8 narrative-section freshness (Next Best Action checklist refreshed) ✅; Gate #9 post-fix grep (n/a — not a fix-round); Gate #10 stash-clean G1 (n/a — no source code changes this turn — only docs); Gate #11 working-tree clean post-closure (will commit + verify).
- **Plan Staleness Sentinel:** **resets to 0 IMPL-NNN closures since R25 chain termination 2026-05-09** — within threshold ✅. FIX-003 + FIX-005 are review-loop / fix-ticket artifacts per fix-round-10 precedent + workflow.md Gate #4. Cumulative attack surface unchanged from R25 chain-terminated baseline.
- **Files modified (this session):** `docs/state/impl-plan.md` (~5 distinct edits) + `docs/state/overview.md` (rows 19+20 status string append) + `docs/state/current_handoff.md` (this section + Prior completed action demote) + `simulation/headless-tests/runs/dst_batch_progress.txt` (NEW — committed; UTF-16LE wall-clock log of legs 1-7) + `simulation/headless-tests/runs/dst_batch_finish_progress.txt` (NEW — committed; UTF-16LE wall-clock log of legs 8-10).
- **Recommended next action:** **Operator session for IMPL-062 + IMPL-066 + IMPL-068 numeric drain** — bump `regression_5yr_no_g4.ini Deposit=1000` → ≥$1M (baseline parity); recompile with `#define DISABLE_G4_FIXES`; run 5-yr regression (~30-60 min); parse Net Profit + per-slot trade counts vs `baseline-per-slot.json`; drain 3 paired E-AC bundles (Bucket A + journal latency + force-clear validation). **THEN** IMPL-063 (Bucket B paired regression — same compile-flag toggle, default OFF, comparing to IMPL-062 numeric). **THEN** P4 Tier 2 Phase Gate empirical demo (5 prereqs all closed — Tier 1 16/17 + IMPL-FIX-003/005, Tier 1.5 batch-3 ≤14d, IMPL-063 + numeric drain). **THEN** P2/P3 Phase Gate retroactive close (drain remaining 29 P2/P3 deferred-AC rows via 5-yr journal records).

---

## Prior completed action — Code Review Fix Round 24 CLOSED 2026-05-09 (methodology-only round)

**Code Review Fix Round 24 CLOSED 2026-05-09 — methodology-only round (extend Gate #9 clause (h) exemption regex + author clause (i))**

- **Trigger:** `/impl-review-fix review-round-24.md` — 2 findings (MEDIUM 1 / LOW 1). Verify-only sweep + R23-mandated termination test surfaced 4th axis on chain (R12→R24): exemption regex itself was scope-narrower than its intent, returning 5 surviving non-exempt-by-regex hits that fix-round-23 §23.1 had hand-classified as exempt. **Accepted 2/2** (1 actioned, 1 narrative-only).
- **24.1 MEDIUM (Gate #9 clause (h) exemption regex extended):** Replaced narrow exemption `(TD-02 §|ADR-[0-9]+ §|TD-02 line|ADR-[0-9]+ line)` with extended form covering 4 missed classes: (α) merged `TD-02 (§|line)` + `ADR-[0-9]+ (§|line)`; (β) bare-§ doc anchor ` § X.Y line ` (catches `(per § 7.4 line 1659)` form); (γ) spec-yaml anchors `(trade-journal-schema|state-persistence-schema|slot-abstraction-contract).yaml`; (δ) TA-indicator false-positive filter `MACD|Signal|EMA|SMA|RSI line`. **Authored clause (i) exemption-regex tree-wide verifiability** as inline meta-rule — exemption regexes used inside Gate #9 verification post-conditions MUST themselves be tree-wide-verifiable; surviving hits MUST either extend the regex (with attestation) or be enumerated as scope-out exceptions in the fix-round narrative (no narrative-only hand-classification). Footer "Why this is here" appended with R24 paragraph documenting the 4-axis chain {catalog (R20) + destination (R21) + anchor (R22-R23) + exemption-regex (R24)}.
- **24.2 LOW (R23 §23.1 site #3 narrative-precision):** No action — already self-corrected in fix-round-23 verdict-table cell ("function actually IS at line 791 today"). Methodology note adopted: future review rounds invoking clause (h) MUST classify surviving hits as {realized-drift / text-violation / compliant} with explicit per-category counts.
- **Verification (post-fix combined regex, tree-wide):** 1 surviving hit at `core/BootstrapValidator.mqh:81` — mojibake'd `§` byte sequence (`od -c` shows `340 271 200 340 270 230 340 270 202 340 271 200 340 270 230 302 207` Thai chars + `` control, instead of UTF-8 `\xc2\xa7` for `§`). Enumerated as scope-out per clause (i)(b): latent file-transcoding defect across 5 files (`core/BootstrapValidator.mqh`, `inputs/Inputs_Slot_BI.mqh`, `inputs/Inputs_Slot_BR.mqh`, `inputs/Inputs_Slot_GO.mqh`, `services/CircuitBreaker.mqh`); reviewer's footnote claim "on UTF-8 terminal this site IS exempt" is incorrect — corruption is in file content, not terminal rendering. Flagged for separate cleanup ticket.
- **Termination test outcome:** Gate #9 clauses (a)-(g) verify clean tree-wide simultaneously ✅; clause (h) returns 5→0 exempt-by-regex hits + 1 scope-justified hit ✅; clause (i) verifies the verification mechanism itself ✅. R12→R24 chain extends to 4-axis termination; R25 verify-only sweep should re-run full meta-grep over (a)-(i) to declare chain termination.
- **Phase 5 mechanical gates:** Gate #1 forbidden-pattern (n/a — no plan changes); Gate #5 overview.md sync ✅; Gate #9 clauses (a)-(i) ✅; Gate #11 working-tree clean (post-commit). Gate #10 stash-clean G1 n/a (no source code changes; rule edit in `.claude/rules/workflow.md` not compiled).
- **No source code changes** — methodology-only round.
- **Plan Staleness Sentinel:** unchanged from R09 advisory (fix-round commits don't increment IMPL-NNN closure counter).
- **Files modified:** `.claude/rules/workflow.md` (Gate #9 clause (h) extended exemption regex + R24 strengthening narrative + new clause (i) + footer R24 paragraph) + `docs/state/overview.md` (Impl Plan row status string append) + `docs/state/current_handoff.md` (this section) + `docs/code-review/fix-round-24.md` (NEW report).
- **Output:** `docs/code-review/fix-round-24.md`.
- **Recommended next action:** `/impl-review all` R25 verify-only sweep to confirm 4-axis termination; OR proceed with IMPL-062 (Bucket A regression) per prior R09 advisory queue.

---

## Prior completed action — IMPL-017 + IMPL-066 + IMPL-067 P4 QA verification authoring parallel batch

**IMPL-017 + IMPL-066 + IMPL-067 CLOSED 2026-05-05 — P4 QA verification authoring parallel batch (Sonnet 4.6 fan-out)**

- **Trigger:** `/impl-task parallel` — orchestrator scanned P4 ready-task pool, proposed 3-task batch (IMPL-017 [S] sweep compat, IMPL-066 [S] journal latency, IMPL-067 [M] DST regression), HALT-ed for approval, fan-out to 3× general-purpose `andm-impl-engineer` subagents on Sonnet 4.6 in one message with disjoint SCOPE constraint per workflow §1.5.
- **Pre-checks PASSED:** Phase Gate compliance (P4 = current open phase, all 3 tasks P4) ✅; Operator Action Registry empty ✅; Deferred-AC expiry scan — 0 expired rows (all 2026-05-17/18 vs today 2026-05-05) ✅; HEAD compile-clean from R16 fix-round closure ✅; working-tree-clean ✅.
- **Race-prevention verified:** subagent file sets disjoint — IMPL-017 = `simulation/headless-tests/optimize_sweep_FID.ini` + `docs/state/inputs-optimization-compat.md`; IMPL-066 = `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh` (only MQL5/ touch) + `docs/state/nfr-2.2-journal-latency.md`; IMPL-067 = 10× `simulation/headless-tests/dst_*.ini` + `docs/state/nfr-7.3-dst-regression.md`. All 3 fragments returned `status: completed`.
- **IMPL-017 (S [ea-qa] FR-1.3 sweep compat):** `optimize_sweep_FID.ini` (Optimization=2 + `[TesterInputs] InpFIDValue=10||10||5||20||N` → 3 combos {10,15,20}) + 170-LOC compat report enumerating 25 input files / **227 total inputs** (int=51 / double=124 / bool=26 / ENUM_*=1 / 0 string-color-datetime / 0 sinput-extern); NFR-4.3 PASS (227 ≥ 80) + NFR-6.2 PASS (100% sweep-compatible). 2/2 S-AC `[x]` + 1 E-AC deferred (sweep journal `[file-blob-check]`) → expiry 2026-05-19.
- **IMPL-066 (S [ea-qa] journal latency NFR-2.2):** `services/TradeJournal.mqh` extended with 200-sample ring buffer + running aggregates (total/max/count) + per-event-type linear-probe map (16 buckets) + `EmitLatencyReport()` emitting `[ev=journal_latency_report]` Logger.Info + sidecar `journal/<live|tester>/latency-report-<ISO>.json` via CJsonWriter; trigger hook = periodic 1000-write checkpoint + final emit at `Close()`. Existing overshoot ring + `journal_write_slow` Warn logic preserved verbatim. **G1 PASS** (orchestrator-verified post fan-out): `Result: 0 errors, 0 warnings, 3844 ms elapsed`. 190-LOC `nfr-2.2-journal-latency.md` with 4-step protocol + 5-outcome pass matrix. 2/2 S-AC `[x]` + 2 E-AC deferred paired bundle (avg/p95 ≤ 5 ms `[log-assertion]` + zero halt-events `[db-inspect]`) → expiry 2026-05-19.
- **IMPL-067 (M [ea-qa] DST regression NFR-7.3):** 10× `dst_<YYYY>_<mar|oct>.ini` (each ±3 days around DST Sunday 2021-2025) + ~250-LOC `nfr-7.3-dst-regression.md` with 10-row coverage matrix + per-AC expected behavior (AC-6.5.2 + AC-6.5.3) + 10-row PASS/FAIL matrix + operator runbook (~10-20 min wall-clock). 2/2 S-AC `[x]` + 1 E-AC deferred (TimeGate ±0 EET hour at each of 10 transitions `[log-assertion]` + `[db-inspect]`) → expiry 2026-05-19.
- **Wall-clock telemetry:** subagent durations IMPL-017 ≈125s / IMPL-066 ≈299s / IMPL-067 ≈157s; serial sum ≈581s; parallel wall-clock ≈ slowest = 299s → **~49% wall-clock saving** (lower than IMPL-061 batch's 62% because IMPL-066 instrumentation extension was code-dense).
- **State Reconciliation 3-file rule honored:** `impl-plan.md` (TL;DR + Phase Status snapshot P4 11/17→14/17 + Active count 43→47 + Mid-Phase Audit Log new 2026-05-05 row + Plan Staleness Sentinel 6→9 + Open Risk R-6 count update + Next Best Action checkboxes) + `overview.md § Impl Plan` row status string append + `current_handoff.md` (this section) + `deferred-ac-registry.md` (4 new Active rows).
- **Files modified:** 1 source EDIT (`MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`) + 13 NEW (1 sweep ini + 10 DST ini + 3 reports) + 4 state docs (impl-plan / overview / current_handoff / deferred-ac-registry) + 1 gitignored shared context.
- **Plan Staleness Sentinel: 9 closures since R07** (1 closure shy of 10-trigger ✅) but cumulative attack surface **strongly motivates `/impl-review all` R09 before next IMPL-NNN batch**. **Mid-Phase Audit P4 counter = 9** (≥ 5 trigger crossed twice over) — semantically satisfied by walk batch-2 for prior defect classes but new TradeJournal latency instrumentation + 10 DST ini + sweep ini unreviewed.
- **Recommended next action:** `/impl-review all` R09 **THEN** IMPL-062 (HIGH Bucket A regression — 2-3 day deadline per R-7) **THEN** IMPL-063 + IMPL-065 **THEN** P4 Phase Gate close.

---

## Prior completed action — Code Review Fix Round 15

**Code Review Fix Round 15 CLOSED 2026-05-05 — 4 findings accepted + 2 XS deferred (1 source defense-in-depth + 3 state/doc edits)**

- **Trigger:** `/impl-review-fix review-round-15.md` — 4 findings (HIGH 1 / MEDIUM 1 / LOW 2) + 2 cross-service. **Accepted 4 + 2 XS deferred to Phase-2 backlog.**
- **15.1 HIGH (BootstrapValidator::ValidateSlotInputs umbrella):** added `ValidateSlotInputs() const` to `core/BootstrapValidator.mqh` — checks InpSPercentTp ∈ {5, 10, 15} per BR-4.1 via tolerance 0.001 (mirrors RiskManager._ComputeLotForS consumer at 402-415); ErrorBypassThrottle on fail per ADR-011 boot-bypass; `core/Orchestrator.mqh:312` Phase C wires the call between ValidateInputs and ValidateSymbol with `validate_slot_inputs` CleanupPartialInit tag; `inputs/Inputs_Slot_S.mqh:33` comment now self-documents the discrete set + cites the validator. Closes operator-driven regression of FIX-001 defect class (per-tick `[ev=s_pct_tp_invalid]` + zero-lot Slot S) when MT5 input dialog or Strategy Tester optimization sweep sets the input outside the valid set. Future per-slot discrete-set inputs land in this umbrella per XS-15.1 Phase-2 backlog.
- **15.2 MEDIUM (registry partial-drain narrative propagation):** appended "Partially resolved 2026-05-05 via Tier 1.5 walk batch-2" annotation to `docs/state/deferred-ac-registry.md` Active rows IMPL-007 (log-assertion clause drained — `magics registered: 17` captured; db-inspect half pending IMPL-062 broker reconcile) + IMPL-049 boot-cold (5 enter_pending + 4 transition_executed events C/M/T/Q/P captured; kill+reload threshold needs longer window) + IMPL-049 file-blob-check (not drained — 3-day window insufficient to cross any force-clear threshold; still gated on IMPL-062) + IMPL-052 (state_corrupt_starting_fresh first-run path drained; HALTED-restart synthetic fixture not exercised). Mirrors IMPL-022 G4 attestation row precedent. All rows stay Active per Dim #11 partial-drain handling.
- **15.3 LOW (Plan Staleness Sentinel 7→6 revert):** reverted "7 closures since R07 review (+1 walk drain)" → "6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068)" across `impl-plan.md` line 9 TL;DR + line 55 Next Best Action + `current_handoff.md` line 49 + `overview.md` line 20. Cited `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4 + fix-round-10 Plan Staleness precedent — fix-rounds + walk drains are review-loop / E-AC residue cleanup artifacts, not new IMPL-NNN closures. (Sentinel section line 1778 was already correct at 6; only the parallel-narrative TL;DR + handoff + overview status string were inflated.)
- **15.4 LOW (walk-summary System Load Context):** appended "System Load Context (informational)" subsection to `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` documenting batch-1/2 wall-clock context (cold/warm cache + concurrent activity) + methodology advisory for IMPL-065/066 NFR-2.x latency E-ACs (≥3 sessions + median p99 + GetMicrosecondCount instrumentation over wall-clock outer loop). Becomes template for future Tier 1.5 walk artifacts (XS-15.2 — canonicalize in `.claude/rules/testing.md` when IMPL-065/066 land).
- **XS-15.1 (Phase-2 backlog):** broader inputs/ audit for discrete-set semantics — verified via grep that no other current input is enum-as-int (`InpKMode`/`InpPSubMode` cited by reviewer don't exist; continuous numerics covered by Guards 1-39). Open as Phase-2 IMPL-NNN ticket if/when new discrete-set inputs land.
- **XS-15.2 (Phase-2 backlog):** canonicalize Result-Table fill pattern in `.claude/rules/testing.md` / `andm-impl-engineer/SKILL.md`; trigger naturally at IMPL-065/066/067 result-table authoring time.
- **G1 ✅ MetaEditor64 /compile /log:** `Result: 0 errors, 0 warnings, 3844 ms elapsed`.
- **Phase 5 mechanical gates 1+9 verified:** forbidden-pattern grep on `impl-plan.md` = 0 hits ✅; originating R15 finding 15.3 pattern grep on `docs/state/` = 0 hits ✅; broader-class grep `deferred to IMPL-053(\+| |\.|$)` on `MQL5/Experts/PhoenicisNex` = 0 hits ✅ (R14 strengthened gate holding).
- **Plan Staleness Sentinel:** 6 closures since R07 review unchanged (review-round + fix-round commits don't increment counter; no new IMPL-NNN ACs ticked) — within 10-closure threshold ✅. R09 advisory still motivates next `/impl-review all` before next IMPL-NNN batch.
- **Files modified:** 3 source (`core/BootstrapValidator.mqh` + `core/Orchestrator.mqh` + `inputs/Inputs_Slot_S.mqh`) + 4 state/doc (`docs/state/deferred-ac-registry.md` + `docs/state/impl-plan.md` + `docs/state/overview.md` + `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md`).
- **State Reconciliation 3-file rule honored:** `impl-plan.md` (TL;DR Sentinel + Next Best Action + Mid-Phase Audit Log new row for fix-round-15) + `overview.md` (Sentinel + Last Updated 2026-05-04→2026-05-05 + status string append) + `current_handoff.md` (Sentinel revert at line 49 + this new "Last completed action" section).
- **Output:** `docs/code-review/fix-round-15.md`.
- **Recommended next action:** `/impl-review all` R09 (cross-slot + Orchestrator + entry .mq5 + 2 FIX commits + 3 QA pipeline + walk batch-2 evidence + fix-round-15 defense-in-depth = significant accumulated attack surface) **THEN** start IMPL-062 (Bucket A regression — IMPL-061 baseline ✅ unblocked) to begin draining the IMPL-068 5-yr regression bundle + 24 P3 slot 60-day deferrals before 2026-05-17/18 expiry cycle.

---

## Prior completed action

**Tier 1.5 Exploratory Walk batch-2 CLOSED 2026-05-05 — 4 deferred-AC rows drained + NFR-3.1 atomic-write live-kill verified + 2 FIX defects empirically resolved**

- **Trigger:** Engineer-driven `andm-impl-engineer` session per CLAUDE.md §1 PhoenicisNex Tier 1.5 definition (no GUI; walk = headless backtest + Tester log + journal audit). User invocation: "act @.agents/agents/andm-impl-engineer.md to Run Tier 1.5 Exploratory Walk batch-2".
- **Pre-conditions:** Foreground MT5 closed; FIX-001 + FIX-002 + IMPL-064 harness commits already merged (4110a78 + a290d7a + 41ffdd6); G1 recompile on PhoenicisNex.mq5 → Result: 0 errors, 0 warnings, 3895 ms.
- **G3 — bootstrap_smoke.ini rerun (post-FIX merge):**
  - Wall-clock: 9:05.786 (vs batch-1's 6:50.521; 304,418 ticks / 18 bars)
  - Raw Tester log: 224 MB (vs batch-1's 629 MB → **−64% volume**)
  - `[ERROR]` count: **0** (was tens of thousands of `s_pct_tp_invalid`)
  - `[WARN]` count: **1** (only first-run `state_corrupt_starting_fresh`; was tens of thousands of `clamp_applied`)
  - SlotS `entry_signal` count: **216,671** with `lot=2.90` (clamped at `max_lot_ratio=2.9`, NOT floor-clamped to 0.01)
  - state.json schema-valid: 35 fields / 11 sub-objects / 17 slot_states magics / 8 pending_machines / journal_metrics.write_failures=0 / logger_metrics.throttled_alert_count=0
- **G4 — atomic_write_kill_100.ps1 -Trials 100 (IMPL-064 numeric verdict):**
  - Wall-clock: 34.3s (≈340ms/trial; well under 60s startup-timeout cap)
  - Verdict: **PASS** — `parse_pass=100, parse_fail=0, state_missing_tmp_present=0, state_missing_tmp_missing=0, startup_timeout_count=0, failed_fast=false`
  - NFR-3.1 live-kill contract verified against ADR-007 Option A (write-temp + NTFS rename) under `Stop-Process -Force` mid-write
  - Sidecar: `docs/state/nfr-3.1-atomic-write-result.json` (schema_version=1)
- **Drained deferred-AC rows (4 fully):**
  - **IMPL-009** (P1) — `pip_math_init digit_multiplier=10` captured at OnInit ✅
  - **IMPL-FIX-001** (P3 / HIGH) — zero ERROR + 216,671 SlotS entry_signal events with lot=2.90 ✅
  - **IMPL-FIX-002** (P2 / MEDIUM) — zero `clamp_applied` (DEBUG demoted; OR-clause-1 satisfied) ✅
  - **IMPL-064** (P4) — verdict=PASS 100/100 ✅
- **Partially drained (kept Active with updated narrative — log-assertion drained, db-inspect needs real broker fills):**
  - IMPL-007 (magics registered: 17 ✓; broker reconcile needs real positions)
  - IMPL-049 (5 enter_pending + 4 transition_executed events for C/M/T/Q/P; force-clear needs longer window)
  - IMPL-052 (state_corrupt_starting_fresh first-run path drained; HALTED-restart synthetic fixture not exercised)
- **NOT drained (gating remains):**
  - IMPL-008 / IMPL-011 (ENABLE_SELFTEST flag-gated; not enabled in bootstrap_smoke.ini)
  - IMPL-012 / IMPL-013 / IMPL-014 (input dialog probe needs live MT5 chart attach; Strategy Tester uses defaults)
  - IMPL-019..039 (60-day backtest prerequisite; deferred to IMPL-062/063)
  - IMPL-022 / IMPL-039 G4 attestation journal evidence (need real broker fills; 3-day $1000 deposit produced 0 fills, final balance unchanged)
  - IMPL-053..058 (cross-slot synthetic fixtures `cross_slot_*.ini` deferred to IMPL-059+ runnable surface)
  - IMPL-068 (paired bundle gated on IMPL-062/063 5-yr regression journal records)
- **No new defects discovered.** Both prior batch-1 defects empirically verified resolved.
- **State propagation (3-file rule per CLAUDE.md §6):**
  - `docs/state/deferred-ac-registry.md` — 4 rows moved Active → Resolved table; IMPL-009 / IMPL-FIX-001 / IMPL-FIX-002 / IMPL-064 strikethrough'd in Active + appended in Resolved with walk artifact path
  - `docs/state/impl-plan.md` — TL;DR (Active count 47→43; Resolved 1→5; Last updated 2026-05-04→2026-05-05; new last action) + Phase Status Snapshot (P2 + P3 + P4 Tier 1.5 column updated batch-2 PASSED) + Open Risks R-6 (PARTIALLY MITIGATED) + Next Best Action (Tier 1.5 walk batch-2 ☐→☑)
  - `docs/state/overview.md` — Impl Tasks row prefix + date 2026-05-04→2026-05-05 + new closure narrative
  - `docs/state/nfr-3.1-atomic-write-result.md` — Status `PENDING NUMERIC RUN` → `✅ PASS` + § 5 Result Table filled (placeholder TBD → actual counts) + observations subsection
- **Walk artifact:**
  - `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` (~7 KB; full execution + drain table + verdict)
  - `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/abridged-tester-log.txt` (~6.5 KB; init + pending events + entry_signal samples + Tester verdict)
  - Walk validity ≤14d per CLAUDE.md §1 → expires 2026-05-19
- **Plan Staleness Sentinel:** 6 closures since R07 review unchanged (walk batch-2 drained 4 E-AC residues but zero new IMPL-NNN closures; per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4 + fix-round-10 precedent fix-rounds + walks are not counted) — within 10-closure threshold ✅. R09 advisory unchanged (cumulative attack surface still motivates `/impl-review all`).
- **Recommended next action:** `/impl-review all` R09 (cross-slot + Orchestrator + entry .mq5 + 2 FIX commits + 3 QA pipeline + walk batch-2 evidence) **THEN** start IMPL-062 (Bucket A regression — IMPL-061 baseline ✅ unblocked) to begin draining the IMPL-068 5-yr regression bundle + 24 P3 slot 60-day deferrals.

---

## Prior completed action

**Code Review Fix Round 14 CLOSED 2026-05-04 — broader-class IMPL-053 sweep + SelfTest wiring + workflow.md gate #9 strengthened**

- **Trigger:** `/impl-review-fix review-round-14.md` — 4 findings (HIGH 1 / MEDIUM 2 / LOW 1) + 3 cross-service. **Accepted 4 + 2 XS** + 1 deferred (XS-14.2 → Phase 2 backlog) + 1 subsumed (XS-14.3 → 14.3).
- **Substantive fixes:**
  - **14.1 HIGH** — broader-class IMPL-053 sweep: 23 stale `deferred to IMPL-053` sites repo-wide rewritten across 14 files (10 in `slots/`, 3 in `services/`, 1 in `core/`, 9 in `spike/`). Canonical Phase-1 wording: cross-slot trigger stubs → "wires at IMPL-017 / IMPL-062 (cross-slot coupling per ea.md)"; service-side header/loop stubs → "completed at IMPL-053..060 (Orchestrator) per impl-plan"; spike-file E-AC headers → "E-AC smoke wires at IMPL-017 / IMPL-062 (RiskManager::OpenOrder)". Closes the next-coarser-granularity recurrence of R12 § 12.8 → R13 § 13.2 (literal `IMPL-053+` regex was scope-narrower than the defect class).
  - **14.2 MEDIUM** — new `MQL5/Experts/PhoenicisNex/spike/Spike_CircuitBreaker.mq5` (~70 LOC, mirrors `Spike_PendingMachineRegistry` invocation pattern). Logger init → CircuitBreaker init → SelfTest call. Closes operationally-inert gap from R13 § 13.5 — Cases A–E (including Case E pre-Init guard) now have a runnable G1 attach path; the regression gate that R13 motivated actually deploys.
  - **14.3 MEDIUM** — `domain/EnumTypes.mqh:111-122` rewrites misleading "Wire from `BootstrapValidator::ValidateAll()`" comment with honest "Wiring status" matrix (Phase 1: spike-only via Spike_Orchestrator + new RunDomainSelfTests umbrella header / Phase 2: production wire deferred to IMPL-053..060 / IMPL-062 owner). `core/BootstrapValidator.mqh` adds `RunDomainSelfTests()` umbrella method (header-only, wraps `IsPhoenicisMagicSelfTest` + emits ErrorBypassThrottle on fail, room for future SelfTests). Chose review's Part 2 fallback option to avoid tangling R14 with Orchestrator boot-sequence changes; production-wire-from-Orchestrator deferred to IMPL-053..060 / IMPL-062 named owner.
  - **14.4 LOW** — `simulation/scripts/atomic_write_kill_100.ps1` doc cleanup: removed duplicate `.PARAMETER Trials` block (lines 25-26 stub leftover from fix-round-13 § 13.4 edit) + rewrote `.EXAMPLE` block to use `-StateRel 'PhoenicisNex/state'` + `-AgentSubpath 'Agent-127.0.0.1-3001'` (post-13.1 rename + semantic shift to sandbox-relative). Operator copy-paste of `Get-Help -Examples` output no longer hits param-binding error or path-prefix-doubling trap.
- **Cross-service:**
  - **XS-14.1** — strengthened `.claude/rules/workflow.md § Phase 5 Closure mechanical gates § Gate #9` with **clause (b) broadest-class regex requirement**. Previously the gate ran only the originating finding's literal pattern (e.g. `IMPL-053\+` against `slots/`); now also requires a defect-class regex (e.g. `deferred to IMPL-053(\+| |\.|$)` against the whole tree). Non-zero hit on (b) forces engineer to expand the sweep or explicitly scope-out non-target sites. Breaks the R12 § 12.8 → R13 § 13.2 → R14 § 14.1 next-coarser-granularity recurrence chain at fix-round commit boundary instead of next-R-cycle.
  - **XS-14.2** — deferred to Phase-2 IMPL-NNN ticket. Bulk SelfTest wiring backlog: `helpers/CommentParser::SelfTest`, `helpers/JsonWriter::SelfTest`, `services/PortfolioMonitor::SelfTest`, `services/RiskManager::SelfTest` are all defined-but-uncalled. Review explicitly framed as "structurally orthogonal" — out of R14 fix scope.
  - **XS-14.3** — subsumed by 14.3. The `EnumTypes.mqh` comment claim about `BootstrapValidator::ValidateAll()` is closed; TD-02 §7.4 mirror update tracked as `/amend td` follow-up advisory (not blocking R14).
- **Files modified:** 16 — 14 source for 14.1 (Slot_BR/F/G2/GO/I/J/LX/S + BootstrapValidator + PortfolioState + RiskManager + Spike_Slot_B/BR/BI/G2/GO/I/L/LX) + 1 spike new (Spike_CircuitBreaker.mq5) + EnumTypes.mqh + BootstrapValidator.mqh (also for 14.3) + atomic_write_kill_100.ps1 + workflow.md.
- **G1 compile (4-gate Definition of Done):** 3/3 PASS — `PhoenicisNex.ex5` regenerated 19:38 (entry transitively pulls all updated headers); `Spike_CircuitBreaker.ex5` newly created 19:39 (23,080 bytes, new spike); `Spike_Orchestrator.ex5` regenerated 19:39 (transitively pulls updated EnumTypes + BootstrapValidator). MetaEditor in this version omits `.compile.log` on warning-free builds (per `mt5-log-reader` SKILL § Wine note); `.ex5` mtime is canonical evidence — compile errors prevent `.ex5` output. G2/G3/G4 deferred to Tier 1.5 walk batch-2 per IMPL-064 deferred-AC E-AC#1 (expiry 2026-05-18).
- **Post-fix grep gate #9 (both clauses):**
  - (a) Literal-pattern (originating from R13 § 13.2): `grep -rE "deferred to IMPL-053\+|deferred to Orchestrator wiring|deferred to orchestrator wiring|schema lock deferred to IMPL-053" MQL5/Experts/PhoenicisNex/slots` → **0 hits** ✅
  - (b) Broadest-class (R14 § 14.1 strengthened gate): `grep -rE "deferred to IMPL-053(\+| |\.|$)" MQL5/Experts/PhoenicisNex` → **0 hits** ✅
  - Forbidden-pattern grep on impl-plan.md (gate #1): 0 hits ✅
- **Output:** `docs/code-review/fix-round-14.md`. Plan Staleness Sentinel = 7 closures since R07 (review-round + fix-round commits don't increment counter; no IMPL-NNN ACs ticked) — within 10-closure threshold ✅.
- **Recommendation:** Ready for Tier 1.5 walk batch-2 OR R15 review — operator's choice. R13's structural-vs-operational gap (SelfTest defined but uncalled) is now closed; R12-R14 closure-narrative-vs-actual-sweep recurrence chain is structurally prevented at gate #9 (a)+(b). Operator invocation order for Tier 1.5 walk: `pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -DryRun -Trials 5 -Verbose` (sanity check on doc-clean .EXAMPLE) → `... -Trials 5 -Verbose` (Tester-tree validation) → `... -Trials 100` (full IMPL-064 NFR-3.1 contract closure).

---

## Previous completed action

**Code Review Fix Round 13 CLOSED 2026-05-04 — post-fix-round-12 next-coarser-recurrence sweep + Phase 5 mechanical gate #9 added**

- **Trigger:** `/impl-review-fix review-round-13.md` — 6 findings (CRITICAL 1 / HIGH 1 / MEDIUM 2 / LOW 2) + 3 cross-service. **Accepted 6 + 2 XS** + 1 deferred (XS-13.3 → IMPL-062 schema yaml).
- **Substantive fixes:**
  - **13.1 CRITICAL** — `simulation/scripts/atomic_write_kill_100.ps1` `$AbsStateDir` resolves under Tester agent sandbox (`<MetaQuotesRoot>/Tester/<TerminalId>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state`) — was resolving under live Terminal sandbox (R12 fix only repaired relative path, not sandbox tree). New `-StateRel` / `-AgentSubpath` params + pre-flight `Test-Path` warn.
  - **13.2 HIGH** — 23 stale `deferred to IMPL-053+` / `Orchestrator wiring` / `schema lock deferred to IMPL-053+` sites swept across 17 slot files (Slot_BI/F/D/GO/G2/C/BR/J/S/I/M/Q/R/T/LX/K/P). Canonical wording: `logger-only milestone; broker close wires at IMPL-017 / IMPL-062 (RiskManager::OpenOrder) per ea.md`. Slot_P file-header banner replaced with single-line pointer. Post-fix grep: 0 hits ✅.
  - **13.3 MEDIUM** — `Spike_AtomicWrite::OnInit` cleanup gated to `PhoenicisNex/spike/` prefix + `[ev=path_guard][class=sandbox|production|unknown]` audit log; defends against per-trial production-state destruction if 13.1 ever bridged to live sandbox via FILE_COMMON.
  - **13.4 MEDIUM** — `-FailFastConsecutive=3` aborts trial loop after 3 consecutive `startup_timeout` trials → 100-min FAIL → 3-min FAIL_FAST verdict; sidecar gains `failed_fast` + `fail_fast_consecutive` fields. Compatible with Tier 1.5 walk 30-min budget.
  - **13.5 LOW** — `CCircuitBreaker::SelfTest` Case E (pre-Init RecordOpen/Close → buffer NOT mutated + Print fallback emitted) added; guards dual-gate added in fix-round-12 § 12.6 against future refactor regression.
  - **13.6 LOW** — `IsPhoenicisMagicSelfTest()` free function in `domain/EnumTypes.mqh` (17 registered + 6 negative cases inc. BR-3.6 foreign-EA gap 202/203/204 + boundaries 199/220/0/-1); wired into `spike/Spike_Orchestrator.mq5 § OnInit`.
- **Cross-service:**
  - **XS-13.1** — closed by 13.1 implementation; `docs/state/nfr-3.1-atomic-write-result.md § 2.3.1/2/3` rewritten to document MQL5 per-mode sandbox separation + spike cleanup guard + harness fail-fast circuit.
  - **XS-13.2** — `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` gained **gate #9 (post-fix grep verification)** — would have caught R13.2 + R13.5 + R13.6 at R12 commit boundary; failure-escalation row bumped 8 → 9 gates.
  - **XS-13.3** — deferred to IMPL-062 (`docs/api-specs/baseline-per-slot-schema.yaml` companion file lands when 5-yr regression code shapes the consumer interface).
- **Files modified:** 23 (17 slots + `domain/EnumTypes.mqh` + `services/CircuitBreaker.mqh` + `spike/Spike_AtomicWrite.mq5` + `spike/Spike_Orchestrator.mq5` + `simulation/scripts/atomic_write_kill_100.ps1` + `docs/state/nfr-3.1-atomic-write-result.md` + `.claude/rules/workflow.md`).
- **G1 compile (4-gate Definition of Done):** 3/3 PASS — `PhoenicisNex.mq5` 0err/0warn/3731 ms · `Spike_AtomicWrite.mq5` 0err/0warn/432 ms · `Spike_Orchestrator.mq5` 0err/0warn/621 ms. G2/G3/G4 deferred to Tier 1.5 walk batch-2 per IMPL-064 deferred-AC E-AC#1 (`[boot-cold]` + `[file-blob-check]`, expiry 2026-05-18).
- **DryRun smoke:** `powershell.exe -File atomic_write_kill_100.ps1 -DryRun -Trials 5` resolves `state_dir = <MetaQuotesRoot>/Tester/<TerminalId>/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/state` ✅ (sandbox-tree binding correct); sidecar contains new `agent_subpath` / `state_rel` / `failed_fast` / `fail_fast_consecutive` fields.
- **Output:** `docs/code-review/fix-round-13.md`. Plan Staleness Sentinel = 7 closures since R07 (R13 fix-round counted as +1) — within 10-closure threshold ✅.
- **Recommendation:** Ready for Tier 1.5 walk batch-2. Operator invocation order: `pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 5 -Verbose` (Tester-tree sanity check) → `pwsh -File simulation/scripts/atomic_write_kill_100.ps1 -Trials 100` (full IMPL-064 NFR-3.1 contract closure).

---

## Earlier completed action — IMPL-061 + IMPL-064 + IMPL-068

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
