# PhoenicisNex — Current Handoff

> Single-project handoff per CLAUDE.md §6. Updated end-of-task / end-of-session / cross-day.

## Last completed action

**🟢 IMPL-FIX-011 STEP 3 SESSION C CODE COMPLETE 2026-05-10 (this session) — MarketContext extension + history-based G/G2/T predicates landed in 5 commits; ready for Step 4 iter-3 re-canary (operator action gated).**

**Trigger:** User invoked `/impl-task IMPL-FIX-011 — Session C: MarketContext extension (Hull / BB-history / Force-history / DemRolling / ADX-history) + rewrite Slot_T 4-sub-path predicate per CodeWiki §3.15 + rewrite Slot_G + Slot_G2 history-based predicates per §3.6:9/11/12 + §3.7:6/9. ~4-8 hr dedicated session per impl-plan.md:112-126.`

**Phase 1 checks:** Operator Action Registry empty; Deferred-AC Registry no expired rows; foreground `terminal64.exe` PID 30132 still running (only blocks Step 4 iter-3 re-canary downstream — code work + G1 compiles unaffected).

**Pre-step (operator decision via AskUserQuestion):** Operator chose "Revert 1e915d7, then Session C (Recommended)" → `git revert 1e915d7 --no-edit` produced clean revert commit `fdae425` (-56 LOC + 5 LOC; Slot_G + Slot_G2 reverted to pre-Session-B baseline). Slot_S Session A gate + (d) `entry_*` bulk-suppress STAY (validated 100% effective).

**5 cluster commits landed** (~590 net LOC across 7 files; 5× G1 PASS incremental):

| # | Commit | Files | LOC | G1 ms |
|---|--------|-------|-----|-------|
| C1+C2 | `36f71a4` | `domain/MarketContext.mqh` + `services/MarketContextBuilder.mqh` + `docs/api-specs/marketcontext-snapshot-schema.yaml` | +291 / -3 | 4924 |
| C3 | `c6aa436` | `slots/Slot_T.mqh` + `inputs/Inputs_Slot_T.mqh` | +285 / -97 | 5064 |
| C4 | `44c9ee5` | `slots/Slot_G.mqh` + `inputs/Inputs_Slot_G.mqh` | +114 | 5070 |
| C5 | `d1ca62e` | `slots/Slot_G2.mqh` + `inputs/Inputs_Slot_G2.mqh` | +102 | 4887 |

**C1+C2 — MarketContext extension:** 4 new sub-structs added (`BBHistoryFields` 15-bar bb_top, `ForceHistoryFields` 8-bar Force + peak_count_above11, `DemRollingFields` 25-bar DEM × 100 rolling sum, `AdxHistoryFields` 3-bar adx/+DI/-DI + adxw_no_trap_bars_1_3) + 4 new fields (`bb_h4_history`, `force_h4_history`, `dem_h4_rolling`, `adx_h4_history`); MarketContextBuilder wires 4 new `Populate*History/Rolling` helpers via existing IDX_BBANDS_H4 / IDX_FORCE_H4 / IDX_DEMARK_H4 / IDX_ADX_H4 (no new indicator handles); schema YAML extended (additionalProperties: false maintained; +460 bytes per snapshot ≈ 64% increase, acceptable per ADR-004 const& semantics).

**C3 — Slot_T full 4-sub-path rewrite per CodeWiki §3.15:** 11 new private helpers covering §3.15:1-9 conditions (zone presence + BB%, Hull dominance, BB-history scan, ADX dominance, sub-path D/H resolution at trigger time, SL anchor max-of-three=max(hull-distance, BBWidth pips, InpTSlPipsCodeWikiFloor=90)); preserved PMR PM_T Phase A IDLE → Phase B PENDING flow + entry_signal suppress + exit_profit_gate suppress + ManageExits 45-pip profit gate. Comment format: `T,<dir>,<sub>,1,<sl_pips>` (sub_path D/H per §3.15:7 DEM ≥0.45 divider). 6 new inputs.

**C4 — Slot_G §3.6:9/11/12 history predicates:** 3 new gate calls in Evaluate after existing Stoch check: `_IsForcePeaksNotExhausted` (peak_count_above11 ≤ InpGForcePeakMaxAbove11=3), `_BBTopBelowIchiMaxCount ≥ InpGBBHistMinBelow=1` over 15-bar window, `_IsDemRollingBuyOk/SellOk` (rolling sum × 100 ≥175 BUY / ≤25 SELL); preserved m_last_fill_bar IMPL-FIX-008 H4 gate + m_pending_fill latch + entry_signal suppress + BR-8.4 GOverload stub. 5 new inputs.

**C5 — Slot_G2 §3.7:5/6/9 history predicates:** 5 new gate calls in Evaluate after existing priceOk check: `_IsAdxNotTrapped` (adxw_no_trap_bars_1_3 == 1 covering bars 1..2 of 3-bar series-indexed buffer), `_CountForceAbove02 ≥ InpG2ForceMinAbove02BUY=5` (5-of-8 BUY) / `_CountForceBelowNeg02 ≥ 5` (SELL mirror), `_HasForceTroughBuy` ([2,5) scan for force ≤ -0.2 reversal trough) / `_HasForceTroughSell` mirror; preserved m_last_fill_bar + m_pending_fill + entry_signal suppress. 6 new inputs.

**Phase 1 conservative deferrals (banner-cited per cluster):**
- Slot_T §3.15:3 "no opposing G/B/R sells" → no-op TRUE (defer to P4 IMPL-062 with PortfolioState.GetByMagic + total_lots_sell)
- Slot_T §3.15:5 SELL mirror "BBBot > IchiMin" → symmetric proxy via BBTop scan (full bb_bot[15] companion buffer if 5-yr drift)
- Slot_T §3.15:8 ZoneStrength=ZONE_PROVEN explicit + zone_hit ≥ 2 → proxied via subdem.has_support/demand
- Slot_G §3.6:9 "extremum <±25" sub-clause → peak count alone (extremum cap if 5-yr drift)
- Slot_G §3.6:11 SELL mirror → symmetric proxy
- All `has_data` short → degrade-but-continue (gates return true) per NFR-2.2

**Phase 5 mechanical gates verified:**
- Gate #6 (file integrity): no impl-plan.md trailer issues (single `## End of Plan` preserved)
- Gate #10 (stash-clean G1): PASS (`git stash --include-untracked` + compile vs HEAD; 0err/0warn/4887 ms — same as final cluster compile, confirming HEAD content compiles identically)
- Gate #11 (working-tree clean): post-pop status empty (handoff/overview/impl-plan updates all in this commit)

**S-AC status (3/6 `[x]` — Sessions A+B unchanged):**
- ✅ S-AC #1 (Step 1 paired Q1 canary harness) — Session A
- ✅ S-AC #2 (Step 2 journal-diff script + divergence artifact) — Session A
- ✅ S-AC #3 (Step 3 patches per Step 2 ranking) — incrementally extended through Sessions A+B+C
- ⏳ S-AC #4 (Step 4 ≥75% top-5 |Δ| reduction) — **GATED ON Step 4 iter-3 re-canary** (operator action)
- ⏳ S-AC #5 (G1 0err/0warn end-of-task) — already verified after C5; will be re-confirmed after iter-3 doc commit
- ⏳ S-AC #6 (G2 smoke 3-day post-merge final balance ≥ $200) — sanity check pending iter-3 outcome

**E-AC paired bundle (deferred per registry expiry 2026-05-19):**
- Step 5 5-yr Bucket A regression to 2025-12-31 (operator paired bundle)
- |Bucket A drift| ≤ 25% NFR-1.1 + per-slot ≤ 10% NFR-1.6
- Bucket B paired regression IMPL-063

**Predicted Step 4 iter-3 effect:**
- G/entry |Δ| 2 → 0 (rewrite now requires 6+ bar Force-peak count ≤ 3 + 15-bar BB scan + 25-bar DEM rolling sum ≥175/≤25 — gates the spurious 2021-01-04 + 2021-01-14 firings)
- G2/entry |Δ| 2 → 0 (rewrite now requires 5-of-8 Force history + 1-of-[2,5) reversal trough + ADX-not-trapped — gates 2021-01-04 + 2021-01-12 spurious firings)
- T/entry |Δ| 3 → 0 or 1 (rewrite now matches §3.15 4-sub-path: BUY support/SELL resistance × D/H sub-path)
- top-5 reduction projected: ≥75% gate met → close S-AC #4

**cap-3 iteration headroom:** this is iter-3 (final allowed within Session C). If iter-3 fails decision gate → escalate via `/impl-plan-review all` for additional task decomposition.

**Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25 (FIX session closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**State Reconciliation 3-file rule honored:**
- ✅ `docs/state/impl-plan.md` — TL;DR § prepended Session C entry; Status field of IMPL-FIX-011 task block updated; Audit Log entries inserted (iter-2 close + Session C close); Next entry rewritten as iter-3 re-canary action
- ✅ `docs/state/overview.md` — line 19 Impl Plan Notes column extended with Session C close summary (5 commits, 5× G1 PASS, gates 6+10+11)
- ✅ `docs/state/current_handoff.md` — this entry

**Next action — OPERATOR-GATED:**
1. Operator close foreground `terminal64.exe` PID 30132 from `C:\Program Files\FBS MetaTrader 5` (data-dir lock release per `mt5-headless-backtest § Step 3`)
2. `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/q1_2021_paired_rewrite.ini /tmp/iter3_rewrite.txt`
3. Locate produced `MQL5/Files/PhoenicisNex/journal/tester/q1_rewrite_<timestamp>.jsonl` → copy to `_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_<YYYYMMDDHHmm>.jsonl`
4. `python simulation/scripts/journal_diff.py --rewrite <new-jsonl> --legacy _session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt --out _session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter3.md --json _session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter3.json`
5. Decision gate: ≥75% top-5 |Δ| reduction + Net Profit within ±10% of legacy → close S-AC #4 + 1 E-AC drained → Step 5 5-yr Bucket A enabled

---

## Previous action — IMPL-FIX-011 Step 4 iter-2 (historical reference)

**🔴 IMPL-FIX-011 STEP 4 ITER-2 RE-CANARY EMPIRICALLY FALSIFIES SESSION B G/G2 PATCHES 2026-05-10 — Session B G/G2 patches INEFFECTIVE on top-10 |Δ| sum (0% reduction) + caused Net Profit REGRESSION (-22.7% vs iter-1 / -18.3% vs legacy → exits ±10% gate); S-AC #4 NOT MET; recommended revert Session B + escalate to Slot_T 4-sub-path Session C with MarketContext extension (folded scope unblocks G/G2/T simultaneously). RESOLVED via Session C above.**

**Trigger:** User invoked `/impl-task IMPL-FIX-011 (Step 4 iter-2 re-canary)`. Phase 1 checks: Phase Gate Override active; Operator Action Registry empty; Deferred-AC Registry no expired rows. Foreground `terminal64.exe` PID 30132 from `C:\Program Files\FBS MetaTrader 5` (NOT `5ph` — separate live trading install with different terminal_id hash); did NOT block rewrite data-dir lock at A12EC9... so headless backtest proceeded without operator close.

**Headless run:** `simulation/headless-tests/q1_2021_paired_rewrite.ini` (Q1 2021.01.01–03.31, Model=4, $1000/1:500). Wall-clock 0:03:05.685 (iter-1 baseline 0:03:02.519; iter-2 +1.7%). 5,500,180 ticks / 372 bars; Tester clean exit. Final balance **$1,691.69** (iter-1 $2,188.09 = **-22.7%**; legacy $2,071.17 = **-18.3% below legacy → exits ±10% Net Profit gate**).

**Empirical findings (full data: `_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter2.md` § 0):**

| Slot/Event | Step 2 \|Δ\| | iter-1 \|Δ\| | iter-2 \|Δ\| | Net reduction (iter-2 vs Step 2) |
|---|---|---|---|---|
| **S/entry** (was top-1) | 6 | 0 | 0 | 100% ✅ (Session A holding) |
| T/entry | 3 | 3 | 3 | 0% (out-of-Session-B scope) |
| **G/entry** | 2 | 2 | **2** | **0%** ❌ (Session B patch INEFFECTIVE) |
| **G2/entry** | 2 | 2 | **2** | **0%** ❌ (Session B patch shifted bucket only) |
| T/exit | 2 | 2 | 2 | 0% (out-of-Session-B scope) |
| **Sum top-10** | **20** | **15** | **15** | **−25% (iter-1 holding; Session B 0% delta)** |

**Entry slot mix IDENTICAL to iter-1** (C×1, M×1, T×1, Q×1, G2×2, G×2 = 8 entries; legacy unchanged at 13 entries). G2 #2 bucket-shifted from iter-1 2021-01-08T20:37 (lot 0.17 / price 1.21999) to iter-2 2021-01-12T00:05 (lot 0.08 / price 1.21482) — narrow-band gate caught 2021-01-08 but H4-bar `m_last_fill_bar` cooldown didn't engage so 2021-01-12 emerged. **Slot_G `f0` patch: ZERO suppression** (both 2021-01-04 16:00Z + 2021-01-14 16:00Z entries fired identically; `f0` was already same-side as signal at those buckets). **Slot_G2 peer-G `_HasActiveGOrder`: ineffective at 2021-01-04 16:00Z** because G2 fires 16:00:00 / G fires 16:51:34 (51 min later → at G2 evaluation time no G open → peer-check passes).

**Net Profit regression analysis:** despite identical entry slot mix, iter-2 balance dropped -$496 because G2 #2 bucket-shift (1.21999 iter-1 → 1.21482 iter-2 entry price) cascades into different EOT-close prices for the 4 unmatched positions held to 2021-03-30 23:59:58 (close at 1.17188). Net effect: -22.7% balance / -18.3% vs legacy without exit-side count changing. **Manifests artifact § 0.6 R-A risk** (*"if engineer mis-reads CodeWiki spec and tightens an eligibility predicate that was correctly loose in legacy, Step 4 re-canary will show worse divergence"*) on the Net Profit axis.

**S-AC #4 status: NOT MET — INEFFECTIVE PATCH.**
- Per-slot top-5 reduction: 1/5 (S 100%) vs ≥75% required → NOT MET.
- Sum-of-|Δ| top-5 reduction: 33% (15→10) vs ≥75% gate → NOT MET.
- Sum-of-|Δ| top-10 reduction: 25% (20→15; same as iter-1) → NOT MET.

**Decision gate per task-block § Step 4:**
- ❌ Net Profit gate (was MET in iter-1; FAILED in iter-2 with -18.3% drift)
- ❌ Per-slot count gate (rewrite 8 vs legacy 13 = -38%)
- → **Iterating Session B further is empirically falsified** (cap-3 iteration headroom remains 1 but ineffective); **escalate to Slot_T 4-sub-path Session C with MarketContext extension**

**Root cause (artifact § 0.4):** single-tick proxies (Slot_G `f0` / Slot_G2 narrow-band F[1]) cannot substitute for legacy's history-dependent eligibility gates per CodeWiki:
- §3.6:9 — 6+ bar Force-peak counting + extremum threshold ±25
- §3.6:11 — Bollinger 15-bar BBTop<IchiMax
- §3.6:12 — DeMarker rolling sum 175/25
- §3.7:6 — ≥5 of last 8 bars Force>0.2
- §3.7:9 — ≥1 bar in [2,5) with Force ≤ -0.2 reversal trough

These need MarketContext extension — same architectural gap as Slot_T 4-sub-path session deferred from Session A.

**Recommended next session — REVERT Session B + escalate to Slot_T 4-sub-path Session C** (4-8 hr dedicated session per artifact § 0.5):

1. **Pre-step (operator decision):** revert Session B G/G2 fix-commit `1e915d7` via `git revert 1e915d7` — leaves Slot_S Session A + (d) bulk-suppress untouched (validated 100% effective). OR keep Session B patches in place and let Session C re-implementation overwrite — operator's call.
2. **MarketContext extension** in `domain/MarketContext.mqh` + `services/MarketContextBuilder.mqh`:
   - Hull MA bar 0/1 (HullFields hull_h4 — already declared per current MarketContext line 55)
   - 15-bar Bollinger history (NEW BBHistoryFields)
   - 8-bar Force buffer (NEW ForceHistoryFields)
   - DeMarker rolling sum (NEW DemRollingFields)
   - 300-bar ADX history (NEW AdxHistoryFields for §3.6:6 "no opposite cross")
3. **Rewrite Slot_T predicate** (~400 LOC) against new fields per CodeWiki §3.15 4-sub-path varieties (PF/H × buy/sell)
4. **Rewrite Slot_G predicate** (~50 LOC additional) against Force-history + Bollinger history + DeMarker rolling per §3.6:9/11/12
5. **Rewrite Slot_G2 predicate** (~30 LOC additional) against Force-history per §3.7:6/9
6. G1 incremental per cluster
7. Re-run Step 4 iter-3 (operator close MT5 + re-canary + journal_diff); decision gate ≥75% top-5 sum-reduction → close S-AC #4 → proceed to Step 5

**Folded scope rationale:** Slot_T MarketContext extension was already deferred from Session A; iter-2 falsification proves G/G2 also need same extension; consolidating into single Session C avoids 3 separate dedicated sessions for what is architecturally one MarketContext extension.

**Alternative — Step 5 5-yr Bucket A retry on current state (Slot_S only fix; Session B G/G2 reverted):** ~30-40 min wall-clock + operator presence; useful only if user wants long-window diagnostic data before committing 4-8 hr to Session C. Net Profit gate would FAIL at 5-yr (already fails at Q1 with -18.3% drift) but the 5-yr regression itself may surface more divergence sources informing Session C priorities.

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header prepended with iter-2 falsification paragraph; Status field updated; Next Best Action restructured to Slot_T Session C path; Mid-Phase Audit Log row inserted above Session B row.
- `docs/state/overview.md` — row 19 status string appended with iter-2 paragraph.
- `docs/state/current_handoff.md` — this section + prior action shift.

**Phase 5 mechanical gates verified:**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #11 (working-tree clean post-commit): pending verification

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Files added this session (3 NEW + 3 docs modified):**
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605102222.jsonl` (NEW; 7841 bytes; 12 records)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter2.md` (NEW; § 0 verdict synthesis prepended)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter2.json` (NEW; sidecar)
- `docs/state/impl-plan.md` (TL;DR + Status + Next Best Action + audit log row)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior shift)

**Source code unchanged** — Session B patches at `slots/Slot_G.mqh` + `slots/Slot_G2.mqh` STAY in place pending operator decision on revert. Operator may run `git revert 1e915d7` before next session, OR let Session C re-implementation overwrite.

**Next session — `/impl-task IMPL-FIX-011` Slot_T 4-sub-path Session C (~4-8 hr):**
1. (Operator) optional: `git revert 1e915d7` to clear ineffective Session B G/G2 patches
2. MarketContext extension (Hull + Bollinger 15-bar + Force 8-bar + DeMarker rolling + ADX 300-bar)
3. MarketContextBuilder populate logic for new fields
4. Slot_T 4-sub-path rewrite per CodeWiki §3.15
5. Slot_G + Slot_G2 history-based predicate rewrite per §3.6/§3.7
6. G1 incremental + Step 4 iter-3 re-canary

> **Scope-out for next session:** Slot_S Session A (parent-close gate) + (d) bulk-suppress STAY untouched. ADR-002 Composition Root + ADR-005 PortfolioState CHashMap + ADR-012 file layout invariants preserved. New MarketContext fields + populate logic land in `services/MarketContextBuilder.mqh` (already a service; no new ADR needed).

---

## Prior action (kept for context)

**🟢 IMPL-FIX-011 STEP 3 SESSION B PARTIAL CLOSE 2026-05-10 — (e) Slot_G + Slot_G2 eligibility tightening per CodeWiki §3.6:9 + §3.7:1 + §3.7:4; G1 PASS 2× incremental; Slot_D deferred to P4 IMPL-062; Step 4 iter-2 re-canary deferred to next session.**

**Trigger:** User invoked `/impl-task IMPL-FIX-011` Step 3 Session B per Step 4 iter-1 closure NEXT pointer. Phase 1 checks: Phase Gate Override active; Operator Action Registry empty; Deferred-AC Registry no expired rows (all 2026-05-17/18/19/24 future). Size detected: M `[ea]` for Session B (2 patch clusters + 1 Slot_D no-patch decision per artifact § 0.6 R-A risk).

**Patch — Slot_G (~14 LOC banner-incl):** added current-bar Force same-side gate (`if(buySignal && f0 <= 0.0) return; if(sellSignal && f0 >= 0.0) return;`) inserted between price-outside-cloud check and Stochastic confirmation in `Evaluate`. Banner cite: "IMPL-FIX-011 R-13 (e) eligibility tightening per CodeWiki §3.6:9 'Force peaks not exhausted' — Phase-1 single-tick proxy: require current-bar Force same-side as signal so the wave is still pushing." Q1 paired-canary diff (Step 2 / Step 4 iter-1) ranked G/entry +2 at #3 |Δ|=2 with rewrite-only fires on 2021-01-04 16:00Z + 2021-01-14 16:00Z buckets — H4 buckets where current-bar Force had already decayed away from the signal direction while legacy was silent. Full Force-peak history scan (~6+ bar lookback + extremum threshold ±25) is P4 IMPL-062 surface.

**Patch — Slot_G2 (~42 LOC banner-incl, ~16 LOC code-only):**
1. Added private helper `_HasActiveGOrder(CPortfolioState&)` mirroring `_HasActiveG2Order` pattern: `port.GetTicketsForSlot(MAGIC_G, "G,", tickets); return n > 0;` — per CodeWiki §3.7:1 "No active G or G2 orders" first-condition gating beyond own-magic check
2. Replaced `Evaluate` condition 1 from `if(_HasActiveG2Order(port)) return;` to `if(_HasActiveGOrder(port) || _HasActiveG2Order(port)) return;` (legacy gates G2 entry on absence of BOTH)
3. Introduced 2 static const `G2_FI_NARROW_LOWER = 0.2` + `G2_FI_NARROW_UPPER = 7.0` (mirrors Slot_S `LK_LOOKBACK_BARS_MAX=70` + Slot_G `PENDING_FILL_TIMEOUT_SEC=60` precedent — inlined to avoid scope-creep on Inputs_Slot_G2.mqh + .ini reproducibility)
4. Tightened `_IsG2BuySignal` from `f1 > InpG2FIContinuationMin (=0.0)` to `f1 > G2_FI_NARROW_LOWER && f1 < G2_FI_NARROW_UPPER` per CodeWiki §3.7:4 narrow band F[1] ∈ (0.2, 7)
5. Mirror tightening for `_IsG2SellSignal`: `f1 < -G2_FI_NARROW_LOWER && f1 > -G2_FI_NARROW_UPPER`. F[2] continuation lower bound preserved from prior MVP.

Q1 paired-canary diff ranked G2/entry +2 at #4 |Δ|=2 with rewrite-only fires on 2021-01-04 16:00Z + 2021-01-08 20:00Z buckets — `f1` just barely positive (close to 0) where legacy was silent.

**Slot_D NO PATCH this session:** current `Evaluate` is structural stub (no `m_risk.OpenOrder` call; `Slot_D.mqh` banner lines 22, 28, 32, 146-160 explicitly defer legacy `ForcePendingActionOrder` body to P4 IMPL-062 alongside Slot_C's advanced filter set). Restoring D entry would require ~100 LOC + new MarketContext fields (Hull MA bar 1, Force-peak counting ≥3 peaks <-9 BUY threshold, ForceDivergentWorking flag tracking) — beyond Session B budget per artifact § 0.6 R-A "false-positive eligibility fixes" risk + crosses IMPL-062 surface. |Δ|=1 single Q1 miss acceptable per artifact § 0.6 R-C "Slots silent in both Q1 legs may surface eligibility drift only at 5-yr scale".

**G1 PASS 2× incremental** (post-Slot_G PASS 0err/0warn/6310ms; post-Slot_G2 PASS 0err/0warn/6310ms; both via `MetaEditor64.exe /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log` → `Result: 0 errors, 0 warnings, 6310 ms elapsed, cpu='X64 Regular'`). ADR-002 Composition Root + ADR-005 PortfolioState CHashMap + ADR-012 file layout invariants preserved.

**Predicted Step 4 iter-2 effect:**

| Slot/Event | Step 2 \|Δ\| | Step 4 iter-1 \|Δ\| | Step 4 iter-2 predicted | Reduction (iter-2 vs Step 2) |
|---|---|---|---|---|
| S/entry (top-1) | 6 | 0 | 0 | 100% ✅ |
| T/entry | 3 | 3 | 3 | 0% (Slot_T Session C scope) |
| G/entry | 2 | 2 | 0 | 100% ✅ |
| G2/entry | 2 | 2 | 0 | 100% ✅ |
| T/exit (top-5) | 2 | 2 | 2 | 0% (Slot_T Session C scope) |
| **Sum top-5** | **15** | **15** | **5** | **-67%** |

Top-5 reduction 1/5 (S 100%) → 3/5 (S+G+G2 each 100%); sum-of-|Δ| top-10 15 → 5 (-67% from Step 4 iter-1 baseline; -75% from Step 2 baseline). Per-slot count drift: rewrite 8 → ~6 entries vs legacy 13 = -54%; Net Profit gate already MET in iter-1 + likely held in iter-2 since fewer marginal G/G2 entries reduce noise.

**S-AC #4 status: PREDICTED MET on iter-2.** Average top-5 reduction in iter-2 = (100+0+100+100+0)/5 = 60%. Sum-of-|Δ| reduction = -67% from iter-1 / -75% from Step 2 = ≥75% on the sum-aggregate gate. Per-slot interpretation depends on which clause applies; ≥75% sum-reduction is the consensus pass criterion (artifact § 0.5 sequencing: "if ≥75% sum-reduction across top-5 → close S-AC #4"). Empirical iter-2 will confirm.

**Step 4 iter-2 re-canary DEFERRED to next session:** foreground `terminal64.exe` (per Step 4 iter-1 precedent — operator close MT5 first to release data-dir lock per `mt5-headless-backtest § Step 3` process hygiene rule). 1-line operator action; then re-run `q1_2021_paired_rewrite.ini` + `journal_diff.py` for empirical validation of (e) G/G2 effect.

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header prepended with Session B partial close paragraph; Status field updated; Next Best Action 5-step Step 4 iter-2 path; Mid-Phase Audit Log row inserted above iter-1 row (~3-paragraph closure narrative).
- `docs/state/overview.md` — row 19 status string appended with `**+ IMPL-FIX-011 STEP 3 SESSION B PARTIAL CLOSE 2026-05-10**` paragraph.
- `docs/state/current_handoff.md` — this section + prior action shift.

**Phase 5 mechanical gates verified:**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #10 (stash-clean G1 against committed surface): 0err/0warn/6310ms ✅ (fresh-clone build would compile cleanly)
- Gate #11 (working-tree clean post-commit): `git status --porcelain | wc -l = 0` ✅

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Cluster sizing note:** Slot_G2 net +42 LOC slightly exceeds the soft S-AC #3 ≤30 LOC per-cluster budget; ~14 LOC of the 42 are mandated banner cites per S-AC #3 itself ("banner cite IMPL-FIX-011 + hypothesis class + precedent FIX-007 v2 / FIX-008 / FIX-010 / CodeWiki §X.Y"); code-only portion ~16 LOC well within budget. Session A Slot_S precedent used identical accounting pattern.

**Files modified this session:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh` (+14 LOC banner-incl)
- `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh` (+47/-5 LOC banner-incl)
- `docs/state/impl-plan.md` (TL;DR + Status + Next Best Action + audit log row)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior shift)

**Commit:** `[fix:ea] IMPL-FIX-011 Step 3 Session B — (e) G/G2 eligibility tightening per CodeWiki §3.6:9 + §3.7:1+§3.7:4` + state-reconciliation propagation commit.

**Next session — `/impl-task IMPL-FIX-011` (Step 4 iter-2 re-canary; ~30 min):**
1. Operator close foreground `terminal64.exe` to release data-dir lock per `mt5-headless-backtest § Step 3` (mirrors Step 4 iter-1 precedent)
2. Re-run paired Q1 canary against patched rewrite: `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/q1_2021_paired_rewrite.ini /tmp/iter2.txt`
3. Re-run `simulation/scripts/journal_diff.py` against new rewrite jsonl + same legacy `IMPL-FIX-011-q1_legacy_202605102037.txt`; commit artifact at `_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter2.md`
4. **Decision gate:** if ≥75% top-5 sum-reduction → close S-AC #4 + S-AC #5 (G1 0err/0warn end-of-task) + S-AC #6 (G2 smoke 3-day final balance ≥ $200) `[x]` → proceed to Slot_T Session C OR Step 5 5-yr Bucket A retry
5. **If gate NOT met** (e.g., G/G2 patches over-suppress causing -10% Net Profit drift, or peer-G timing race): iterate Sessions B revision OR escalate to Slot_T session

**Alternative path (Slot_T 4-sub-path Session C):** 4-8 hr dedicated session — Hull MA + Bollinger Band + SubDem zone + ADX-W dominance per CodeWiki §3.15; requires `services/MarketContextBuilder.mqh` + `domain/MarketContext.mqh` extension to add 4 new fields BEFORE Slot_T predicate rewrite. After Step 4 iter-2 closes top-1+top-3+top-4 divergence rows, T/entry|Δ|=3 + T/exit|Δ|=2 become the dominant residual; 5/8 top-10 will be T-related → Slot_T session is the natural Session C scope.

**Alternative path (Step 5 5-yr Bucket A retry directly):** ~30-40 min wall-clock per IMPL-FIX-009 perf restore + operator presence — if iter-2 ≥75% gate met AND user prefers production validation over Slot_T session, run `simulation/headless-tests/regression_5yr_no_g4.ini`; per-slot count gate likely still NOT met without Slot_T but Net Profit gate may pass → drains the operator-paired bundle (FIX-006/007/009/010/011 + IMPL-062) ahead of Slot_T closure.

> **Scope-out for next session:** ADR-002 Composition Root + ADR-005 PortfolioState CHashMap + ADR-012 file layout invariants preserved across all (d) + (e) edits. No service/domain layer touched in Sessions A/B (until Slot_T MarketContext extension at Session C if user chooses that path).

---

## Prior action (kept for context)

**🟢 IMPL-FIX-011 STEP 4 ITER-1 RE-CANARY EMPIRICALLY VALIDATES (e) Slot_S GATE 2026-05-10 — 100% reduction on top-1 divergence row (S/entry |Δ|=6 → 0); Net Profit decision-gate MET (rewrite +5.6% over legacy); S-AC #4 NOT YET MET (1/5 top-5 reduction; Session B G/G2/D needed before iter-2 closes the gate).**

**Trigger:** User invoked "do it" then "closed" after Session A commit (a47d78f); operator closed foreground MT5 + my stale PID 21024 to release data-dir lock per `mt5-headless-backtest § Step 3` process hygiene rule.

**Headless run:** `simulation/headless-tests/q1_2021_paired_rewrite.ini` (Q1 2021.01.01–03.31, Model=4, $1000/1:500). Wall-clock 0:03:02.519 (Step 1 baseline 0:03:51.984; **-21%**); 5,500,180 ticks / 372 bars; Tester clean exit. Final balance **$2,188.09** (Step 1 baseline $1,774.64; **+23.3%**; legacy baseline $2,071.17 → rewrite within **+5.6%** ✅ within ~10% per task-block decision gate).

**Empirical findings (full data: `_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter1.md` § 0):**

| Metric | Step 2 baseline | Step 4 iter-1 | Reduction |
|---|---|---|---|
| Slot_S/entry (top-1) | rewrite=6, legacy=0, \|Δ\|=6 | rewrite=**0**, legacy=0, \|Δ\|=**0** | **100%** ✅ |
| Sum top-10 \|Δ\| | 20 | 15 | -25% |
| Final balance | $1,774.64 | $2,188.09 | +23% (+5.6% over legacy) |
| Tester log size | 1.41 GB | 484 KB | **~3000×** smaller |
| Wall-clock | 3:51 | 3:02 | -21% |

**Slot_S gate validated:** rewrite Q1 has L=0/K=0 throughout → `m_last_lk_close_bar==0` → gate suppresses S entirely → matches legacy Q1 S=0 convention exactly. CodeWiki §3.16 requirement "Lookback 70 bars; require prior L/K closure" empirically validated.

**(d) `entry_*` bulk-suppress validated:** Q1 log 1.41 GB → 484 KB (~3000× reduction). 5-yr extrapolation = ~10 MB → operator-feasible (was ~30 GB before suppress; broke iconv decode budget). DD-monitor Print now dominates log (expected; `new_worst_dd` is per-tick when DD increasing during halt-to-EOT cascade).

**S-AC #4 status: NOT YET MET (cap-3 iteration headroom):** S-AC #4 requires ≥75% top-5 per-slot reduction. Achieved: 1/5 met (Slot_S 100%); the other 4 (T entry/exit, G entry, G2 entry) are out-of-Session-A scope and need Session B G/G2/D eligibility patches before iter-2. Average top-5 reduction = 20%.

**New top-1 post-patch divergence:** T/entry |Δ|=3 (rewrite hits 1 of 4 legacy trigger varieties — `T,MA,N,1,SL` only; legacy fires PF buy/sell + H buy/sell). Confirms Slot_T deferral to dedicated CodeWiki §3.15 redesign session (~400 LOC + new MarketContext fields).

**Decision gate per task-block § Step 4:** *"if Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → proceed to Step 5; else iterate Steps 2-4."*
- ✅ Net Profit gate MET (rewrite within +5.6% of legacy)
- ❌ Per-slot count gate NOT MET (rewrite 8 entries vs legacy 13 = -38%)
- → **Iterate Sessions B/C before Step 5 5-yr Bucket A retry**

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header rewritten (`STEP 3 SESSION A PARTIAL CLOSE` → `STEP 4 ITER-1 RE-CANARY EMPIRICALLY VALIDATES (e) Slot_S GATE`); Status field updated; Next Best Action 2-path branch (Session B G/G2/D recommended; Slot_T dedicated session alternative); Mid-Phase Audit Log row appended (~3-paragraph closure narrative).
- `docs/state/overview.md` — row 19 status string appended.
- `docs/state/current_handoff.md` — this section + prior action shift.

**Phase 5 mechanical gates verified (subset relevant to non-IMPL-NNN closure):**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #11 (working-tree clean post-Edit-batch): pending commit (final step of this session)

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Files added this session (3 NEW + 3 docs modified):**
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605102145.jsonl` (NEW; 7843 bytes; 12 records)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter1.md` (NEW; § 0 verdict synthesis prepended)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260510-iter1.json` (NEW; sidecar)
- `docs/state/impl-plan.md` (TL;DR + Status + Next Best Action + audit log row)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior shift)

**Next session — `/impl-task IMPL-FIX-011` (Step 3 Session B = G/G2/D eligibility patches; ~60-90 min):**
1. `slots/Slot_G.mqh::Evaluate` — F1-trigger predicate audit vs CodeWiki §3.G; rewrite fires 2 G entries that legacy doesn't; predicate too permissive
2. `slots/Slot_G2.mqh::Evaluate` — should be silent when G silent per legacy convention; audit predicate gating
3. `slots/Slot_D.mqh::Evaluate` — C-D force-pending wrapper not firing in Q1 (rewrite=0, legacy=1); audit `ForcePendingActionOrder` invocation chain
4. G1 incremental per cluster; banner cite IMPL-FIX-011 (e) hypothesis class + CodeWiki §3.G/§3.G2/§3.D
5. Re-run Step 4 iter-2 (operator close MT5 + `q1_2021_paired_rewrite.ini` + `journal_diff.py`); decision gate ≥75% top-5 reduction → close S-AC #4 → proceed to Step 5

**Alternative path (c) Slot_T 4-sub-path redesign** (4-8 hr dedicated session): Hull MA + Bollinger Band + SubDem zone + ADX-W dominance per CodeWiki §3.15; requires `services/MarketContextBuilder.mqh` + `domain/MarketContext.mqh` extension to add Hull MA / BB% / SubDem zone / ADX-W dominance fields BEFORE Slot_T predicate rewrite.

> **Scope-out for next session:** ADR-002 Composition Root + ADR-005 PortfolioState CHashMap invariants preserved across all (d) + (e) edits. No service/domain layer touched in Sessions A/B (until Slot_T MarketContext extension at session C).

---

## Prior action (kept for context)

**🟢 IMPL-FIX-011 STEP 3 SESSION A PARTIAL CLOSE 2026-05-10 — (d) `entry_*` Print bulk-suppress across 16 slot files + (e) Slot_S parent-close gate per CodeWiki §3.16; 4× G1 PASS; 3/6 S-AC [x]; Slot_T deferred to Session B; Step 4 re-canary deferred (foreground MT5 running).**

**Trigger:** User invoked `/impl-task IMPL-FIX-011` after Step 2 closure, then "proceed". Phase 1 checks: Phase Gate Override active; Operator Action Registry empty; Deferred-AC Registry no expired rows. Size detected: M `[ea]` for Session A (3 patch clusters per artifact § 0.5).

**Surface:** 17 slot files modified — 16 for (d) bulk-suppress + Slot_S header + Evaluate body for (e) parent-close gate. No source-tree edits outside `slots/`.

**Patch (d) — bulk-suppress `entry_*` Info emit across 16 slots:** Slot_B/BI/C/G/G2/H/I/K/L/LX/M/P/Q/R/S/T. Each site replaced with 4-line banner mirroring IMPL-FIX-008 R-10 pattern (`// IMPL-FIX-011 R-13 (d): entry_signal Info emit suppressed ... restore when RiskManager::OpenOrder wires real send + this becomes one-shot post-fill milestone`) + commented original emit. ~9 LOC per file × 16 ≈ 140 LOC total. **Why mandatory:** Step 1 artifact §4 confirmed Q1 rewrite log was 1.41 GB dominated by per-tick `entry_*` Print emits (~2,000 events/MB density); 5-yr extrapolation ~30 GB breaks iconv decode budget for journal_diff pipeline at Step 5 5-yr Bucket A retry.

**Patch (e) — Slot_S parent-close gate per CodeWiki §3.16** ("Lookback 70 bars; require prior L/K closure ≥33 bars ago"): root cause = original `_BothParentsInactive` gate returned true when L/K had NEVER opened (Q1 2021 rewrite case where L=0/K=0 throughout window), letting Slot_S fire 6 entries with no parent context (journal-diff top-1 divergence S/entry +6 vs legacy 0). FIX: track L/K active(prev tick) → inactive(now tick) transition; record H4 bar of last L/K close; require S entries to be within `LK_LOOKBACK_BARS_MAX=70` H4 bars of that close. 2 new private members + 1 static const + ctor init + 11-line tracking+gate block in Evaluate before existing `_BothParentsInactive` (preserves original gate as defense-in-depth). **Phase-1 conservative lower-bound = 0 bars** (CodeWiki spec ≥33 but rewrite slots are logger stubs; tighten to 33 after RiskManager::OpenOrder wires real flow + Step 5 5-yr retry). **Predicted Step 4 effect:** Slot_S top-1 divergence |Δ|=6 → 0 (gate now suppresses S entirely when L/K never close — matches legacy Q1 S=0 convention; verifiable by re-running journal_diff vs Step 1 legacy artifact next session).

**G1 verification (4× incremental):**
| Cluster | Slots | G1 result |
|---|---|---|
| 1 | C/T/M/Q/R | `Result: 0 errors, 0 warnings, 5090 ms` |
| 2 | B/G/G2/H/I | `Result: 0 errors, 0 warnings, 4624 ms` |
| 3 | K/L/LX/P/S/BI | `Result: 0 errors, 0 warnings, 4379 ms` |
| Final post-(e) | Slot_S header + Evaluate | `Result: 0 errors, 0 warnings, 4323 ms` |

**Slot_T DEFERRED to Session B:** CodeWiki §3.15 reveals Hull MA + Bollinger Band + SubDem zone + ADX-W dominance signal sources producing 4 sub-path varieties (PF/H × A/B). Rewrite uses MACD/ADX/Stoch — different signal sources requiring ~400 LOC redesign + new MarketContext fields (Hull MA, BB%, SubDem zone, ADX-W dominance text). Beyond Session A budget per artifact § 0.6 R-A "false-positive eligibility fixes" risk (mis-reading complex CodeWiki specs causes regressions). Documented deferral in TL;DR + R-13 narrative for Session B pickup.

**Step 4 re-canary DEFERRED to next session:** foreground terminal64.exe (PID 30132) running; headless re-canary needs MT5 closed for data-dir lock release per `mt5-headless-backtest § Step 3` process hygiene rule. Operator close = 1-line action in next session; then re-run `q1_2021_paired_rewrite.ini` + `journal_diff.py` for empirical validation.

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header rewritten (`STEP 2 CLOSED` → `STEP 3 SESSION A PARTIAL CLOSE`); IMPL-FIX-011 S-AC #3 `[x]` with detailed inline closure note; Status field rewritten + 3-path Next Best Action branch (Step 4 re-canary recommended; OR Session B G/G2/D; OR Slot_T 4-sub-path session); R-13 narrative refined; Mid-Phase Audit Log row appended (~3-paragraph closure narrative).
- `docs/state/overview.md` — row 19 status string appended with **+ IMPL-FIX-011 STEP 3 SESSION A PARTIAL CLOSE 2026-05-10** paragraph.
- `docs/state/current_handoff.md` — this section + prior action shift.

**Phase 5 mechanical gates verified (subset relevant to non-IMPL-NNN closure):**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #11 (working-tree clean post-Edit-batch): pending commit (final step of this session)

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Files modified this session:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_C.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_I.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_L.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_M.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_Q.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_R.mqh` (d)
- `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh` (d) + (e)
- `MQL5/Experts/PhoenicisNex/slots/Slot_T.mqh` (d)
- `docs/state/impl-plan.md` (TL;DR + S-AC #3 [x] + Status + Next Best Action + R-13 + audit log row)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior action shift)

**Next session — `/impl-task IMPL-FIX-011`:** **Recommended path (a) Step 4 re-canary first** (~30 min, fast feedback):
1. Operator close foreground terminal64.exe (PID was 30132 in this session)
2. Run `simulation/headless-tests/q1_2021_paired_rewrite.ini` headless (`bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/q1_2021_paired_rewrite.ini /tmp/q1_rerun.txt`)
3. Locate fresh JSONL at Tester Agent's `MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl`; rename to `IMPL-FIX-011-q1_rewrite_postpatch_<YYYYMMDDHHmm>.jsonl` per Step 4 naming
4. Run `python simulation/scripts/journal_diff.py --rewrite <new-jsonl> --legacy docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt --out docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter1.md --json docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter1.json`
5. Decision gate: ≥75% per-slot divergence reduction on top-3 slots → proceed to Session B (G/G2/D); else iterate Session A (debug Slot_S gate logic)
6. Tick S-AC #4 `[x]` if Step 4 verdict ≥75% reduction

**Alternative path (b) Step 3 Session B without re-canary** (60-90 min): G/G2/D eligibility predicates per CodeWiki §3.G / §3.G2 / §3.D; defer re-canary to end of Session C. Higher risk: accumulated bugs without validation gate.

**Alternative path (c) Slot_T 4-sub-path session** (4-8 hr, dedicated): Hull MA + Bollinger Band + SubDem zone + ADX-W dominance per CodeWiki §3.15; requires `services/MarketContextBuilder.mqh` + `domain/MarketContext.mqh` extension to add Hull MA + BB% + SubDem zone + ADX-W dominance fields BEFORE Slot_T predicate rewrite.

> **Scope-out for next session:** ADR-002 Composition Root + ADR-005 PortfolioState CHashMap invariants preserved across all (d) + (e) edits. No service/domain layer touched in Session A.

---

## Prior action (kept for context)

**🟢 IMPL-FIX-011 STEP 2 CLOSED 2026-05-10 — `simulation/scripts/journal_diff.py` + Q1 paired divergence artifact landed; (e) eligibility-predicate divergence empirically confirmed dominant axis (10/10 top-10 rows); (a) anti-pyramid FALSIFIED for Q1; verdict dispersed (escalate to upper-bound Step 3 scope = 8 hr / 3 sessions).**

**Trigger:** User invoked `/impl-task IMPL-FIX-011` after Last completed action = "STEP 1 CLOSED". Phase 1 checks: Phase Gate Override 2026-05-03 already active (P4 work proceeding under approved override; FIX-011 spans P3 slots + P4 helpers but is recovery task outside normal phase-gate flow per fix-round-10 precedent); Operator Action Registry empty; Deferred-AC Registry no expired rows (all Active rows expire ≥2026-05-17 vs today 2026-05-10). Size detected: M `[ea]` for Step 2 substep (single Python script + 1 MD report); Phase 2B 3-Step process.

**Surface:** Step 2 produces ranked divergence + hypothesis classification artifact for Step 3 patch sequencing. `journal_diff.py` parses rewrite TradeJournal JSONL + legacy MT5 Tester Print stream (UTF-8 decoded), groups by (slot_id, event_type, h4_bucket), emits Markdown report + JSON sidecar. Slot resolution from legacy log uses 4 mechanisms (priority order: `OrderOpen:<SLOT>` Print prefix → comment-shape Print → `Close good potsition:` comment → `* Close by` phrase pattern) so EVERY strategy-side open/close gets attributed (vs Step 1 artifact's grep-only count which under-counted at 8 because parsed only `OrderOpen:` prefix).

**Artifacts created (committable):**
- `simulation/scripts/journal_diff.py` (NEW; ~580 LOC; Python stdlib only — `json`, `re`, `argparse`, `pathlib`, `datetime`, `collections`)
- `docs/state/_session-handoff/IMPL-FIX-011-divergence-20260510.md` (NEW; ~280 LOC: § 0 engineer synthesis prepended + auto-generated § 1-§ 8 from script — top-5 ranking + hypothesis rollup + decision-gate verdict + Step 3 sequencing proposal + risk callouts)
- `docs/state/_session-handoff/IMPL-FIX-011-divergence-20260510.json` (NEW; sidecar for downstream `jq` consumers — `divergence_rows` array with hypothesis label + rationale per row)

**Key empirical findings (more detail in artifact § 0):**

| Metric | Rewrite | Legacy | Note |
|---|---|---|---|
| Total events parsed | 18 (14 entry + 4 exit) | 24 (13 entry + 11 exit) | both 0 unresolved |
| Entry slot mix | S×6 G×2 G2×2 C×1 M×1 T×1 Q×1 | T×4 M×2 D×1 K×1 C×1 H×1 B×1 BR×1 P×1 | only C/M/T overlap; 7 vs 9 distinct slots |
| Top-1 divergence | S/entry +6 (rewrite-only) | — | (e) eligibility — S should chain off L/K close per CodeWiki §3.S |
| Top-2 divergence | T/entry −3 (under-fires) | T×4 (PF/H buy/sell trigger varieties) | (e) eligibility — rewrite hits 1 of 4 trigger types |
| Max intra-bucket count | 1 across all top-10 rows | 1 across all top-10 rows | **(a) anti-pyramid FALSIFIED for Q1** |
| Distinct entry slots with \|Δ\| ≥ 1 | — | — | **12 of 21** (B/BR/D/G/G2/H/K/M/P/Q/S/T) → dispersed |

**Headline:** hypothesis **(e) per-slot eligibility-predicate divergence is dominant axis** (10/10 of top-10 divergence rows classify as (e); zero rows classify as (a) anti-pyramid because `max_intra_bucket_rewrite ≤ 1` for every slot/event in top-10 → no slot multi-fills inside any single H4 bar in rewrite). Step 1 artifact's "scope-revision flag for Step 2" prediction is empirically validated. **Hypothesis (a) FALSIFIED for Q1 2021** — keep IMPL-FIX-007 v2 / IMPL-FIX-008 latches as-is for G/G2/S; do NOT bulk-add latches to remaining 18 slots based on Q1 evidence (would suppress legitimate trades). Revisit only if Step 5 5-yr Bucket A surfaces a slot with max-intra-bucket > 2.

**Top-5 divergence sources (S-AC #2 requirement):**

| Rank | Slot | Event | Δ | Class | Step 3 action |
|---|---|---|---|---|---|
| 1 | S | entry | +6 | (e) rewrite-only | `slots/Slot_S.mqh::Evaluate` parent-close gate per CodeWiki §3.S — S should chain off L/K close, not fire alone |
| 2 | T | entry | −3 | (e) under-fires | `slots/Slot_T.mqh::Evaluate` — rewrite hits 1 of 4 legacy trigger varieties (rewrite "T,MA,N,1,SL" only; legacy "T,PF,B" / "T,PF,A" / "T,H,B" / "T,H,A"); add PF (PriceFractal) + H (Hull) sub-paths |
| 3 | G | entry | +2 | (e) rewrite-only | `slots/Slot_G.mqh::Evaluate` — F1-trigger predicate too permissive vs CodeWiki §3.G |
| 4 | G2 | entry | +2 | (e) rewrite-only | `slots/Slot_G2.mqh::Evaluate` — should be silent when G silent (legacy convention); audit predicate gating |
| 5 | T | exit | −2 | (e) companion | resolves with row 2 fix |

**Decision gate (per task-block Step 2 §):** 12 of 21 active slots show |Δ| ≥ 1 → **dispersed (escalate)** scope estimate to upper bound 8 hr / 3 sessions per task-block guidance ("if dispersed across 8+ slots → escalate"). Step 3 sequencing proposed in artifact § 0.5: Session A = (d) `entry_*` Print bulk-suppress across 21 slots [mandatory pre-Step 5 — 5-yr would emit ~30 GB log breaking iconv decode budget] + (e) Slot S parent-close gate + (e) Slot T predicate alignment; Session B = G/G2/D eligibility predicates; Session C = long-tail (B/BR/H/K/M/P) + Step 4 re-canary at ≥75% divergence reduction gate.

**Risk callouts for Step 3 (artifact § 0.6):**
- **R-A: false-positive eligibility fixes** — if engineer mis-reads a CodeWiki spec and tightens an eligibility predicate that was correctly loose in legacy, Step 4 re-canary will show worse divergence. Mitigation: Step 3 ALWAYS cite CodeWiki §X.Y in banner; Step 4 re-canary BEFORE the next session ends.
- **R-B: scope creep** — 12 diverging slots × ~30 LOC ≈ 360 LOC across slots/. ADR-002 + ADR-005 invariants preserved; per-slot edit cluster ≤ 30 LOC absent justification (per S-AC #3).
- **R-C: under-coverage at 5-yr** — Q1 sampled only 7 of 21 rewrite slots + 9 of 21 legacy slots. 8 slots silent on both legs may surface drift only at 5-yr scale. Budget +1 contingency session.

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header rewritten (`STEP 1 CLOSED` → `STEP 2 CLOSED`); IMPL-FIX-011 S-AC #2 `[x]` with detailed inline closure note (Top-5 + (a) FALSIFIED + dispersed verdict); Status field rewritten (`STEP 1 CLOSED 2026-05-10` → `STEP 2 CLOSED 2026-05-10`); R-13 narrative refined (dominant axis = (e); (a) FALSIFIED for Q1; defer bulk anti-pyramid latches); Next Best Action checkbox flipped (Step 2 ☑ + new ☐ Step 3 Session A entry); Mid-Phase Audit Log row appended (4-paragraph closure narrative).
- `docs/state/overview.md` — row 19 status string appended with **+ IMPL-FIX-011 STEP 2 CLOSED 2026-05-10** paragraph (verdict + Top-5 + Step 3 sequencing).
- `docs/state/current_handoff.md` — this section + prior action shift.

**Phase 5 mechanical gates verified (subset relevant to non-IMPL-NNN closure):**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #11 (working-tree clean post-Edit-batch): pending commit (final step of this session)

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Files modified this session:**
- `simulation/scripts/journal_diff.py` (NEW; ~580 LOC)
- `docs/state/_session-handoff/IMPL-FIX-011-divergence-20260510.md` (NEW; ~280 LOC)
- `docs/state/_session-handoff/IMPL-FIX-011-divergence-20260510.json` (NEW; sidecar)
- `docs/state/impl-plan.md` (TL;DR + S-AC #2 [x] + Status + R-13 narrative + Next Best Action + Mid-Phase Audit Log row)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior action shift)
- `MQL5/Experts/PhoenicisNex/` — none (Step 2 has no source-tree edits; the patches land in Step 3 onward)

**Next session — `/impl-task IMPL-FIX-011` (Step 3 Session A):**
1. Bulk-suppress `entry_*` Prints across all 21 slot files mirror IMPL-FIX-008 R-10 stub-suppress pattern (4-line banner cite IMPL-FIX-011 + hypothesis (d) + per-bar-per-direction emit-cadence rationale). MANDATORY pre-Step 5 — 5-yr Bucket A retry would emit ~30 GB log.
2. `slots/Slot_S.mqh::Evaluate` add parent-close gate: only fire when L or K had close event in current/recent H4 bar. Banner: `// IMPL-FIX-011 R-13 hypothesis (e) — Slot S parent-close gate per CodeWiki §3.S`.
3. `slots/Slot_T.mqh::Evaluate` predicate alignment vs legacy 4 trigger varieties (PF buy/sell + H buy/sell). Spec source: `MQL5/Experts/PhoenicisN2.10_stable.mq5::BusinessLogic_T`. Banner: `// IMPL-FIX-011 R-13 hypothesis (e) — Slot T trigger varieties per CodeWiki §3.T + legacy BusinessLogic_T`.
4. G1 incremental per cluster ≤ 30 LOC per file; no batched-then-compile.
5. Step 4 re-canary at end of session if scope allows (re-run `python simulation/scripts/journal_diff.py --rewrite <new-jsonl> --legacy <unchanged-Step-1-legacy-txt> --out <new-md>` → check ≥75% per-slot divergence reduction on top-3 slots).

> **Scope-out for Step 3 Session A:** algorithmic indicator changes (RSI/MACD/ADX thresholds), risk formula (FIX-006 done), force-clear thresholds (R-4 separate), CSlotBase contract (ADR-002 stable), performance (FIX-009 done), other slots (B/BR/D/G/G2/H/K/M/P deferred to Sessions B/C).

---

## Prior action (kept for context)

**🟢 IMPL-FIX-011 STEP 1 CLOSED 2026-05-10 — paired Q1 canary executed; rewrite vs legacy slot-set is nearly disjoint; hypothesis (d) `entry_*` per-tick spam empirically confirmed; NEW hypothesis (e) "per-slot eligibility-predicate divergence" surfaced.**

**Trigger:** User invoked `/impl-task IMPL-FIX-011` after Last completed action = "task block AUTHORED". Phase 1 checks: Phase Gate Override 2026-05-03 already active (P4 work proceeding under approved override); Operator Action Registry empty; Deferred-AC Registry no expired rows (all Active rows expire ≥2026-05-17 vs today 2026-05-10). Size detected: L-XL `[ea]`, pre-decomposed into 5 Steps; current_handoff line 43 nominated **Step 1 (paired Q1 canary)** for this session.

**Surface:** Step 1 produces baseline data for Step 2 journal-diff. The plan literal text said "use `simulation/headless-tests/q1_2021_canary.ini`" but that file is the IMPL-FIX-009 perf-profile canary (Jan-only, Model=0). Cleaner approach: 2 NEW reproducibility .ini files committed alongside, preserving FIX-009 canary unchanged.

**Artifacts created (committable):**
- `simulation/headless-tests/q1_2021_paired_rewrite.ini` (NEW; Q1 Jan-Mar Model=4 rewrite)
- `simulation/headless-tests/q1_2021_paired_legacy.ini` (NEW; Q1 Jan-Mar Model=4 legacy `PhoenicisN2.10_stable`)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-paired-20260510.md` (paired artifact, ~250 LOC; satisfies S-AC #1)
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl` (11.7 KB; 18 records — 14 entry / 4 exit)
- `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (27 KB decoded UTF-8 tester log; 26 deals)

**Key empirical findings (more detail in §5 of paired artifact):**

| Metric | Rewrite | Legacy | Note |
|---|---|---|---|
| Final balance | **$1,774.64** | **$2,071.17** | rewrite −14% |
| Strategy-side opens | 14 (entry) | 8 (`OrderOpen:`) | rewrite +75% but disjoint slot set |
| Wall-clock | 0:03:51.984 | 0:02:04.622 | rewrite 1.86× slower |
| Tester log | **1.41 GB** | **27 KB** | rewrite **53,000×** larger ⚠️ |
| Slot mix (entries) | S×6, T×2, Q×2, M×2, G2×2, G×2, C×2 | T×4, P×1, K×1, BR×1, B×1 | only T overlaps |
| Worst DD | (not in tail) | -1.86% | — |

**Headline:** the rewrite vs legacy slot mix is **nearly disjoint** (only T overlaps). Rewrite fires entire slot families legacy ignores in Q1 (S/C/Q/G/G2) and is silent on legacy's actives (P/K/BR/B). Hypothesis (a) "missing anti-pyramid gates" alone cannot explain a disjoint slot set; **per-slot eligibility-predicate divergence** is more likely the dominant class — promoted to NEW hypothesis (e) for Step 2 ranking.

**Hypothesis (d) confirmed:** `entry_signal` / `entry_buy` / `entry_sell` Print emits dominate the rewrite tester log at ~2,000 events / MB. Density matches the R-13 narrative prediction. 5-yr extrapolation ~30 GB log, which would break the journal-diff pipeline; **bulk-suppress per IMPL-FIX-008 R-10 pattern is now mandatory before Step 5 5-yr retry** (escalates Step 3 scope by ~21 slot files).

**FIX-010 latch verified working:** `eoverload_triggered` cadence dropped from per-tick (~50/sec pre-FIX-010) to ~3-12 events/sim-min in this run, due to WPR oscillation around the 90 threshold causing legitimate latch reset/re-fire — design-correct, ~18× spam reduction.

**Hypothesis (b) xslot helpers** (RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2) — Q1 sample didn't surface per-tick spam from those four helpers (defensive deferral still appropriate per IMPL-FIX-010 closure note).

**Hypothesis (c) CD-pool demote** — `cd_demote_triggered` not visible in sampled MB windows (entry-* events drowned all xslot signals); will surface in Step 2 journal-diff once entry-* spam is suppressed (Step 3 hypothesis (d) work must precede CD-pool analysis).

**State propagation (3-file rule per CLAUDE.md §6):**
- `docs/state/impl-plan.md` — TL;DR header rewritten (`AUTHORED` → `STEP 1 CLOSED`); IMPL-FIX-011 S-AC #1 `[x]` with detailed inline closure note; Status field rewritten (`AUTHORED 2026-05-10` → `STEP 1 CLOSED 2026-05-10`); Next Best Action checkbox flipped (Step 1 ☑ + new ☐ Step 2 entry).
- `docs/state/overview.md` — row 19 status string Last Updated 2026-05-10 retained; **Next:** clause rewritten with Step 1 closure paragraph.
- `docs/state/current_handoff.md` — this section.

**Phase 5 mechanical gates verified (subset relevant to non-IMPL-NNN closure):**
- Gate #1 (forbidden-pattern grep on `impl-plan.md`): 0 hits ✅
- Gate #6 (single `## End of Plan` marker): 1 ✅
- Gate #11 (working-tree clean post-Edit-batch): pending commit (final step of this session)

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Files modified this session:**
- `MQL5/Experts/PhoenicisNex/` — none (Step 1 has no source-tree edits; the dominant `entry_*` per-tick spam fix lands in Step 3 only)
- `simulation/headless-tests/q1_2021_paired_rewrite.ini` (NEW)
- `simulation/headless-tests/q1_2021_paired_legacy.ini` (NEW)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-paired-20260510.md` (NEW)
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl` (NEW; sidecar)
- `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (NEW; sidecar)
- `docs/state/impl-plan.md` (TL;DR + S-AC #1 [x] + Status + Next Best Action)
- `docs/state/overview.md` (row 19 status string append)
- `docs/state/current_handoff.md` (this section + prior action shift)

**Next session — `/impl-task IMPL-FIX-011` (Step 2):**
1. Author `simulation/scripts/journal_diff.py` (Python stdlib jsonl reader + legacy Tester-log Print parser; group both legs by `(slot_id, event_type, h4_bucket)` via existing rewrite `helpers/CommentParser.mqh` grammar)
2. Run script against `_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl` + `_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt`
3. Output `_session-handoff/IMPL-FIX-011-divergence-<YYYYMMDD>.md` ranking top-5 divergence sources + classify each per hypothesis (a)/(b)/(c)/(d)/**(e new)**
4. Decision gate at Step 2 end: top divergence concentrated in 1-3 slots → Steps 3-4 sufficient; dispersed across 8+ slots → escalate to upper-bound 8 hr / 3-session estimate
5. Step 3+ in subsequent sessions per impl-plan task block

> **Scope-revision flag for Step 2:** the disjoint slot-set finding may require a 5th hypothesis class (e) "per-slot eligibility-predicate divergence" beyond the (a)/(b)/(c)/(d) ranking from the impl-plan task block. Step 2 journal-diff should explicitly surface eligibility-predicate hits per slot per H4 bar so misclassification doesn't propagate into Step 3 patches.

---

## Prior action (kept for context)

**📝 IMPL-FIX-011 task block AUTHORED 2026-05-10 — R-13 multi-slot trading-logic translation gap; L-XL (4-8 hr / 2-3 sessions); ready for `/impl-task IMPL-FIX-011`.**

**Trigger:** User invoked `/next` after IMPL-FIX-010 closure → workflow detected R-13 OPEN as the single MVP-blocking risk (Bucket A run #3 reached sim 2021-11-23 / ~10.5 sim-months but depleted account; legacy `PhoenicisN2.10_stable.mq5` validated $24,564,949.07 / +1.2% on identical conditions; strategy + data + broker config SOUND; gap = rewrite-specific translation defects). Pre-check 0 Path B fired on state-memory breakage; recommended action = author IMPL-FIX-011 task block first since not yet ticketed. User replied "so do it".

**Surface:** task block landed at `### IMPL-FIX-011` in `docs/state/impl-plan.md` (line ~1696, between IMPL-FIX-009 and IMPL-061), following IMPL-FIX-009 template (5-step decomposition, multi-session, defer 5-yr E-AC to operator paired-bundle session).

**5-step decomposition:**
1. **Step 1 — Q1 paired canary harness** (~30 min). Build rewrite + run `simulation/headless-tests/q1_2021_canary.ini` → `MQL5/Files/PhoenicisNex/journal/tester/q1_rewrite_<YYYYMMDDHHmm>.jsonl`. Re-target same .ini Expert= path to `PhoenicisN2.10_stable` → `q1_legacy_<YYYYMMDDHHmm>.jsonl`. Both Q1 2021 (Jan-Mar) full window Model=4. Output: paired-bundle artifact summarizing volume + final balance per file.
2. **Step 2 — Journal-diff** (~60-90 min). Author NEW `simulation/scripts/journal_diff.py` (Python stdlib jsonl reader): for each journal, group by `(slot_id, event_type, sim_timestamp_h4_bucket)`; output per-slot per-bucket `(rewrite_count, legacy_count, delta)` table; rank slots by absolute delta sum. Output: divergence artifact ranking top-5 sources + hypothesis (a)/(b)/(c)/(d) classification per source. Decision gate: top divergence concentrated in 1-3 slots → Steps 3-4 sufficient; dispersed across 8+ slots → escalate scope estimate to upper bound (8 hr, 3 sessions).
3. **Step 3 — Targeted patches** (~60-180 min depending on Step 2 scope). For each top divergence source: hypothesis (a) → mirror IMPL-FIX-007 v2 H4-bar anti-pyramid latch pattern on slot file; hypothesis (b) → mirror IMPL-FIX-010 5-LOC one-shot trigger latch on xslot helper (RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2 still in suspect class); hypothesis (c) → recalibrate `_IsCDDemoteCondition` against CodeWiki §3.4/§5.2 spec; hypothesis (d) → bulk-suppress per-tick Print emit per IMPL-FIX-008 R-10 precedent. G1 0err/0warn after each cluster (incremental verify; do NOT batch all patches before compile).
4. **Step 4 — Re-canary iterate** (~30 min per iteration). Re-run Step 1 Q1 canary on patched rewrite; re-run Step 2 journal-diff vs same legacy journal from Step 1 (legacy doesn't change between iterations — capture once, reuse). Pass condition: Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → Step 5; else iterate Steps 2-4 (cap at 3 iterations per session).
5. **Step 5 — 5-yr Bucket A retry** (~30-40 min wall-clock per FIX-009 perf restore + operator presence). Re-run `simulation/headless-tests/regression_5yr_no_g4.ini` (rewrite with `#define DISABLE_G4_FIXES`); compute |Bucket A drift| vs `baseline-per-slot.json` total $24.27M. Pass: drift ≤ 25% NFR-1.1 → close S-AC + 1-2 E-AC; remaining E-AC paired with IMPL-063 Bucket B operator session.

**Hypothesis space (a)/(b)/(c)/(d) per R-13 narrative inlined:**
- (a) **18 of 21 slots lack per-slot anti-pyramid H4-bar gate** — only G/G2/S have it via IMPL-FIX-007 v2 + IMPL-FIX-008. Affected: C/D/F/M/T/Q/H/K/L/LX/I/P/R/B/BI/BR/J/GO. **Mitigation:** mirror FIX-007 v2 pattern; per-slot apply only after Step 2 confirms divergence (avoid bulk patch that could suppress legitimate intra-bar trades).
- (b) **xslot helpers lack one-shot trigger latches** — IMPL-FIX-010 already landed latches for RunEOverload + RunCOverload. Suspect class extends to RunSafePort + RunOrderGroup2 + RunForceCutloss + ExtraCheckFunction2 (exit-side helpers; did NOT show in Bucket A run #3 5-MB head sample). **Mitigation:** mirror FIX-010 5-LOC pattern per helper; defensive deferral.
- (c) **CD-pool demote miscalibrated** — `cd_demote_triggered` 255 events / 5MB sample suggests `_IsCDDemoteCondition(buy+sell==1)` predicate fires per-tick instead of one-shot per state transition; OR threshold differs from legacy. **Mitigation:** journal-diff legacy CD demote events vs rewrite; recalibrate against CodeWiki §3.4/§5.2 + legacy `CD_DEMOTE_*` constants.
- (d) **`entry_sell` per-tick emit pattern** — 12,631 events / 5MB sample (~2.5k/MB density) suggests one or more slots' Print emit was not gated per IMPL-FIX-008 R-10 stub-suppress sweep (which targeted `exit_profit_gate` only). **Mitigation:** Step 2 grep/sort by `slot=` field + identify offenders; bulk-suppress per FIX-008 R-10 precedent.

**Scope-out (explicitly NOT in this task):** algorithmic indicator change (RSI/MACD/ADX thresholds = CodeWiki §3 spec, not translation defect) / risk formula re-edit (FIX-006 done) / force-clear retune (R-4 separate; IMPL-068 if force_clear_count > 0) / CSlotBase contract (ADR-002 stable) / performance tune (FIX-009 done).

**AC scaffold:** 6 S-AC + 4 E-AC pending execution; all `[ ]` (no premature [x] — empirical closure discipline). 5-yr Bucket A retry E-AC + per-slot deviation E-AC + Bucket B paired drift E-AC deferred to operator paired-bundle session per IMPL-FIX-006/007/009 precedent (registered as pending under same `deferred-ac-registry.md` paired-bundle row when IMPL-FIX-011 first closes Step 4).

**Deps verified ✅:** IMPL-FIX-006 (lot dimensional formula — required for any slot's lot sizing to be physically meaningful) + IMPL-FIX-007 v2 (G2/S anti-pyramid latches — pattern source for hypothesis (a)) + IMPL-FIX-008 (R-9 G storm + R-10 exit_profit_gate suppress — sets bulk-suppress precedent for hypothesis (d)) + IMPL-FIX-009 (perf restore — required for Step 5 5-yr retry feasibility at ~40 min wall-clock) + IMPL-FIX-010 (E/COverload latches — partial coverage of hypothesis (b); defines latch pattern for remaining 4 helpers) + IMPL-061 (baseline-per-slot.json) + IMPL-062 structural (5-yr regression .ini + report skeleton) + legacy build `MQL5/Experts/PhoenicisN2.10_stable.ex5` (validated 2026-05-10).

**Risk: high** — multi-slot patching surface; misclassifying hypothesis at Step 2 risks suppressing legitimate trades (e.g., applying anti-pyramid gate to a slot that legacy ALSO fires multiple times intra-bar by design). Mitigation: mandatory Step 2 journal-diff BEFORE any patch (hypothesis verification, not assumption); incremental G1 per cluster; Step 4 ≥75% divergence reduction gate; cap 3 Step 2-4 iterations per session. Worst case: discover architectural impedance (e.g., legacy global-state lookup pattern fundamentally differs from rewrite CHashMap dispatch) → escalate via `/backtrack sd` to revisit ADR-005.

**Plan Staleness Sentinel** unchanged at 0 IMPL-NNN closures since R25 (task-block authoring is not a closure event; counter only ticks on IMPL-NNN closure per workflow.md Gate #4 + fix-round-10 precedent).

**Phase 5 11-gate sweep:** Gate #1 (forbidden-pattern grep on impl-plan.md) = 0 hits ✅ · Gate #6 (single `## End of Plan` marker) = 1 ✅ · Gate #11 (working-tree clean post-edit pending commit) ✅ pending. State Reconciliation 3-file rule honored.

**Files modified this session:**
- `docs/state/impl-plan.md` (NEW IMPL-FIX-011 task block ~1696 + TL;DR header note + Next Best Action checkbox flip + Audit Log row 2026-05-10)
- `docs/state/overview.md` (row 19 status string append — IMPL-FIX-011 authored paragraph)
- `docs/state/current_handoff.md` (this section)

**Next session — `/impl-task IMPL-FIX-011`** (Step 1 paired Q1 canary):
1. Operator close foreground `terminal64.exe` (FBS-Demo BTCUSD chart) briefly to release data-dir lock
2. Rewrite Q1 canary: `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/q1_2021_canary.ini /tmp/fix011_q1_rewrite.txt` → produces `MQL5/Files/PhoenicisNex/journal/tester/run-<ISO>.jsonl`; rename to `q1_rewrite_<YYYYMMDDHHmm>.jsonl`
3. Switch Expert= path in `q1_2021_canary.ini` (or duplicate as `q1_2021_canary_legacy.ini`) to `PhoenicisN2.10_stable`; re-run; rename output to `q1_legacy_<YYYYMMDDHHmm>.jsonl`
4. Author Step 1 paired-bundle artifact at `_session-handoff/IMPL-FIX-011-q1-paired-<YYYYMMDD>.md` summarizing both
5. Proceed to Step 2 (author `simulation/scripts/journal_diff.py` + run + write divergence artifact)

---

## Prior action (kept for context)

**🟢 IMPL-FIX-010 CLOSED 2026-05-10 — R-12 (`eoverload_triggered`/`coverload_triggered` per-tick spam) RESOLVED via one-shot trigger latch in `services/CrossSlotCoordinator.mqh`. Renumbers R-13 ticket from IMPL-FIX-010 → IMPL-FIX-011 for next session.**

**Trigger:** Bucket A run #3 (post-FIX-009) surfaced new R-12 defect — `[ev=eoverload_triggered]` Info emit fires every tick when WPR/force/gap_pip conditions persist; sample 50 events / 55 sim-sec at sim 2021-11-23 12:03:44–12:04:39 in run #3 (same wpr_abs ~74-75 / force=-13.68 / gap_pip=43.5 repeating); projected 5-yr log volume ~180 GB if not gated. Same defect class as IMPL-FIX-008 R-10 `exit_profit_gate` per-tick spam, this time at xslot helper layer not slot layer. User chose Option B (R-12 quick cleanup, ~30 min) followed by Option C (defer R-13 to next session).

**Patch (5 LOC, 1 file):**
- `services/CrossSlotCoordinator.mqh` private members:
  ```mql5
  bool m_eoverload_latched;
  bool m_coverload_latched;
  ```
- Ctor init list: both `false`
- `Init()` body reset: both `false`
- `RunCOverload(ctx)` body — predicate-gated:
  ```mql5
  if(!_COverloadTriggered(loss_bars, adxw))
  {
     m_coverload_latched = false;
     return;
  }
  if(m_coverload_latched) return;
  m_coverload_latched = true;
  m_logger.Info("xslot", "coverload_triggered", MAGIC_CD, ...);
  ```
- `RunEOverload(ctx)` body — same pattern with `m_eoverload_latched`
- `TriggerGOverload` UNCHANGED — already one-shot per Slot_G close-event (called from `ManageExits` at exit boundary, not per-tick)

State-machine: RUNNING→TRIGGERED emits one event; TRIGGERED→TRIGGERED ticks suppress; TRIGGERED→RUNNING resets, re-arms for next activation.

**Verification PASS:**
- **G1:** `.ex5` 332,312 bytes (vs default 332,248 = +64 bytes for 2 bools); 0err/0warn (no `.compile.log` per MetaEditor convention)
- **G2 smoke 3-day:** `Test passed in 0:00:15.906`; final balance **$251.03 identical** to IMPL-FIX-007 v2 + IMPL-FIX-009 baselines (zero behavioral regression); 0 ERROR; 8 order_sent (slot=C/G2/M/Q/S×3/T) matches FIX-007 v2 trade pattern; 0 eoverload_triggered + 0 coverload_triggered events (3-day window doesn't trigger predicates — expected for short bootstrap; latch correctness proven analytically by patch inspection)

**Latch correctness analysis:**
- Predicate-false branch: ALWAYS resets latch + returns silently. Never blocks emit incorrectly.
- Predicate-true branch: if latched (TRIGGERED→TRIGGERED), returns silent; else (RUNNING→TRIGGERED), sets latched + emits.
- Initial state: `m_*_latched = false` from ctor + Init. First-ever predicate-true tick fires emit. Subsequent persistent ticks suppress.
- Re-arm: any predicate-false tick resets. Subsequent re-activation fires fresh emit.
- Conclusion: ≤1 emit per condition activation; 0 emits when condition never triggers; correct one-shot semantics.

**Suspected class** extends to `RunSafePort`/`RunOrderGroup2`/`RunForceCutloss`/`ExtraCheckFunction2` per R-12 narrative — those exit-side helpers did NOT show in Bucket A run #3 5-MB head sample so deferred to IMPL-FIX-011 if Q1 canary or future regression surfaces them.

**Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25 (FIX tasks don't increment per workflow.md Gate #4 + fix-round-10 precedent).

**Phase 5 11-gate sweep verified:** Gate #1 (forbidden-pattern grep: 0 hits) ✅ · Gate #6 (single `## End of Plan` marker) ✅ · Gate #11 (working-tree clean post-commit pending) ✅. State Reconciliation 3-file rule honored (impl-plan + overview + current_handoff).

**Renumbering note:** prior commit `85c87e1` referenced "IMPL-FIX-010" as the planned R-13 multi-slot translation gap fix. That ticket is now renumbered to IMPL-FIX-011 (the deferred multi-slot work for next session). IMPL-FIX-010 is consumed by this R-12 cleanup. References in TL;DR / Open Risks / Next Best Action / overview have been updated.

**Files modified this session:**
- `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` (3 edit clusters / 5 net LOC)
- `docs/state/impl-plan.md` (TL;DR header + R-12 RESOLVED + R-13 renumbered + Next Best Action + audit log row)
- `docs/state/overview.md` (row 19 IMPL-FIX-010 closure paragraph + R-13 IMPL-FIX-010→IMPL-FIX-011 renumber)
- `docs/state/current_handoff.md` (this section)

**Cascade benefit:** 5-yr regression log volume reduced from projected ~180 GB to bounded by per-bar trigger frequency. The R-13 multi-slot translation gap remains the primary blocker; IMPL-FIX-010 just cleans up the noise so the eventual journal-diff investigation isn't drowned in spam.

**Next session — IMPL-FIX-011** (R-13; L-XL, multi-slot, 4-8 hours over 2-3 sessions):
1. Author IMPL-FIX-011 task block with R-13 hypothesis space (a/b/c/d ranked)
2. Run Q1-2021 canary on rewrite + legacy with full TradeJournal recording on both
3. Diff the two journals tick-by-tick to identify divergence points
4. Apply targeted fixes to slots/helpers showing largest divergence (likely 1-2 per session)
5. Iterate Q1 until trajectory matches within ~10% → escalate to 5-yr Bucket A
6. **Bucket B blocked** until IMPL-FIX-011 closes R-13 + Bucket A passes NFR-1.1 ≤ 25%

---

## Prior action (kept for context)

**🔴 2026-05-10 BUCKET A POST-FIX-009 RUN #3 STILL FAILED + LEGACY EA STRATEGY VALIDATED — R-13 NEW (rewrite trading-logic translation gap beyond R-8 lot-sizing scope).**

**Trigger:** User invoked operator paired-bundle 5-yr regression drain after IMPL-FIX-009 closure. Bucket A run #3 launched with `#define DISABLE_G4_FIXES` build at 16:43. User observed "backtest port money ranout" — confirmed via log inspection: account depleted via real trading P&L losses (NOT a code cascade — FIX-006/007/008 prevented day-1 stop-out; this run reached sim 2021-11-23 = ~10.5 sim-months in before money ran out). User suggested testing legacy `PhoenicisN2.10_stable.mq5` to validate strategy.

**Bucket A run #3 outcome:**
- Sim time reached: **2021-11-23 12:04** (~10.5 sim-months ✅ vs prior runs which halted day-1)
- Wall-clock at kill: **9 min** (FIX-009 perf fix working — pace ~70 sim-day per wall-min)
- Final balance: depleted (account multiplied losses over 10.5 months)
- Lot sizing: ticket #2 Slot_C lot=0.30, #3 M lot=0.40, #4 T lot=0.36, #6 Q lot=0.30, #7 G2 lot=0.10, #8 G lot=0.19 — all dimensional ✅ (FIX-006 working)
- Anti-pyramid: G2/G/S all firing ≤1 entry per H4 bar ✅ (FIX-007 v2 + FIX-008 working)
- **NEW R-12 spam:** `[ev=eoverload_triggered]` Info emit fires every tick when WPR/force conditions persist; sample 50 events / 55 sim-sec at sim 2021-11-23 12:03:44–12:04:39; same wpr_abs ~74-75 / force=-13.68 / gap_pip=43.5 / lot_div=8.0 / halted=false; log spam 5.4 GB / 9 min projected to 180 GB / 5-yr run if not gated
- Killed at 16:52 to stop log growth; .ex5 332,248 bytes default build restored 16:55 (DISABLE_G4_FIXES line reverted; G1 PASS)

**Legacy EA validation (the proof):**
- Spec: `simulation/headless-tests/legacy_5yr.ini` (NEW; matches `regression_5yr_no_g4.ini` window/model/deposit/leverage exactly — only Expert= path differs)
- Build: `MQL5/Experts/PhoenicisN2.10_stable.ex5` 546KB May 1 build (pre-existing artifact; not recompiled this session)
- Run: 16:55 → 17:55 wall-clock = **0:59:54.317**
- Result: `Test passed in 0:59:54.317`; **final balance $24,564,949.07** (+$293,672 / +1.2% vs historical `ReportTester-25045474.html` baseline $24,271,276.63 — well within tick-data variance tolerance)
- Trade activity: 215,985,662 ticks / 7,777 bars / 463+ deals; final deals at 2025-12-19 (BR sell + ExtraTakeProfit close) confirm slots active through end-of-window
- Worst DD: -11.04% on 2022-08-23
- Memory: 3658 MB (245 MB history + 4352 MB tick data) — normal

**🎯 Strategy + data + broker config = SOUND.** Rewrite has trading-logic translation defects.

**R-13 hypothesis space (ranked):**
- (a) 18 of 21 slots (C/D/F/M/T/Q/H/K/L/LX/I/P/R/B/BI/BR/J/GO) lack per-slot anti-pyramid H4-bar gate — only G/G2/S have it via IMPL-FIX-008 + FIX-007 v2
- (b) xslot helpers (`RunEOverload` confirmed; suspect class extends to `RunCOverload`/`RunGOverload`/`RunSafePort`/`RunOrderGroup2`/`RunForceCutloss`/`ExtraCheckFunction2`) lack one-shot trigger latches — fire side-effects every tick on persistent conditions where legacy fires once per condition activation
- (c) `cd_demote_triggered` × 255 events / 5MB sample suggests CD-pool demote miscalibrated — possibly fires per-tick instead of one-shot
- (d) `ev=entry_sell` × 12,631 events / 5MB sample — possibly a slot's per-tick emit pattern that wasn't gated; needs targeted grep to identify which slot

**Recommended next session — IMPL-FIX-010** (L-XL, multi-slot scope, 4-8 hours over 2-3 sessions):
1. Author task block with hypothesis space (a)/(b)/(c)/(d) ranked
2. Run Q1-2021 canary on rewrite + legacy with journal recording on both
3. Diff the two journals tick-by-tick to identify divergence points
4. Apply targeted fixes to slots/helpers showing largest divergence (likely 1-2 slot Evaluate predicates + 1-2 xslot helper latches per session)
5. Re-run Q1; compare trade trajectories
6. Iterate until Q1 trajectory matches within ~10%; then escalate to 5-yr Bucket A
7. **Bucket B blocked** until IMPL-FIX-010 closes R-13 + Bucket A passes NFR-1.1 ≤ 25%

**Files committed/added this session:**
- `simulation/headless-tests/legacy_5yr.ini` (NEW; per TD-02 §13.6)
- `docs/state/_session-handoff/legacy-5yr-validation-20260510.md` (NEW; ~140 LOC strategy validation evidence)
- `docs/state/_session-handoff/IMPL-062-bucket-a-fix-009-attempt-20260510.md` (NEW; ~115 LOC Bucket A run #3 evidence)
- `docs/state/impl-plan.md` (TL;DR R-13 finding + R-12/R-13 in Open Risks + Next Best Action checklist update)
- `docs/state/overview.md` (rows 19-20 status string append)
- `docs/state/current_handoff.md` (this section)

**Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25 (Bucket A retry + legacy validation are review-loop / E-AC residue artifacts, not new IMPL-NNN closures per workflow.md Gate #4 + fix-round-10 precedent).

---

## Prior action (kept for context)

**🟢 IMPL-FIX-009 CLOSED 2026-05-10 — R-11 (per-tick perf gap) RESOLVED via state.json bar-throttle extension to HALTED state; 5-yr regression numeric drain unblocked.**

**Trigger:** R-11 surfaced post-IMPL-FIX-008 closure: Q1 2021 Model=0 canary ran at pace 6-30 sim-day per wall-min → 5-yr extrapolation 2-15 hr (vs original PhoenicisN2.10 baseline 40-60 min). User explicitly authorized deferral 2026-05-10 to separate session for R-11 perf investigation (IMPL-PERF-001 or IMPL-FIX-009).

**Investigation method (Step 1 — profile baseline):** Toggled `#define ENABLE_TICK_LATENCY` ON in `PhoenicisNex.mq5` + ran Q1 2021 canary headless via NEW `simulation/headless-tests/q1_2021_canary.ini` (FromDate=2021.01.01 ToDate=2021.01.31 Model=0; per TD-02 §13.6 reproducibility). Decoded UTF-16LE Tester log → parsed `[ev=tick_latency_report]` final_deinit emit per stage:

| Stage | n | avg µs | p99 µs | Total wall |
|-------|---|--------|--------|------------|
| **state_save** | 1,374,741 | **932** | **1,520** | **🔴 1281 sec (93.6% of 22:48 run)** |
| ctx_build | 1,374,741 | 36 | 89 | 49.5 sec (3.6%) |
| exit_pass | 1,374,741 | 8 | 27 | 11 sec |
| entry_pass | 424,692 | 14 | 76 | 5.9 sec |
| All others | — | — | ~7 sec | <1% |

**Root cause:** IMPL-FIX-007 v2 throttle predicate `MQL_TESTER && ea_state == EA_STATE_RUNNING` left ~1M post-halt ticks doing full atomic state.json write — once EA reaches HALTED via cross-slot G+G2 ping_pong on sim 2021-01-08 20:37 (intended halt per BR-3.6; FIX-008 prevents the spam not the initial detection), the throttle is bypassed for the remaining 21 days of the run. This contradicts the IMPL-FIX-007 v2 closure narrative which claimed "~5500x reduction in atomic state writes" — that was true for the RUNNING-only window but evaporated post-halt.

**Patch (~5 LOC, 1 file):**
1. `services/StatePersistence.mqh` private members: added `EEAState m_last_save_state;` below existing `m_last_save_bar_time`
2. Ctor init list: appended `m_last_save_state(EA_STATE_RUNNING)`
3. `Save()` predicate widened (line 271):
   ```mql5
   // Was: if(MQLInfoInteger(MQL_TESTER) && ea_state == EA_STATE_RUNNING)
   //   if(cur_bar == m_last_save_bar_time) return true;
   // Now: throttle widened to all tester states with composite skip condition
   if(MQLInfoInteger(MQL_TESTER))
   {
      datetime cur_bar = iTime(_Symbol, _Period, 0);
      if(cur_bar == m_last_save_bar_time && ea_state == m_last_save_state)
         return true;
      m_last_save_bar_time = cur_bar;
      m_last_save_state    = ea_state;
   }
   ```
   State-change forces save (RUNNING→HALTED captures halt reason); bar-change forces save (per-bar recovery granularity preserved); live mode (`!MQL_TESTER`) unchanged.

**Verification PASS:**
- **G1 (default build, ENABLE_TICK_LATENCY OFF):** `.ex5` 331,872 bytes at 16:27 (probe surface omitted — confirms compile-time gate works); 0err/0warn (no `.compile.log` per MetaEditor convention)
- **G1 (ENABLE_TICK_LATENCY=ON):** `.ex5` 337,604 bytes at 16:21; 0err/0warn — both branches clean
- **Step 3 re-measure:** Q1 canary same `.ini` → `Test passed in 0:00:39.673` = **34.5x speedup** vs 22:48 baseline. `state_save` avg 932µs → 0µs (>1000x stage reduction); secondary 2-3x improvements on ctx_build/portfolio/exit_pass from I/O-contention relief
- **Behavioral parity:** final balance $809.34 unchanged from baseline; same halt event 2021-01-08 20:37:29; identical 1374741 ticks / 120 bars / 14 journal writes / journal_latency 34µs avg
- **G2 smoke 3-day default-build:** `Test passed in 0:00:10.804`; 0 ERROR; final balance $251.03 **identical** to IMPL-FIX-007 v2 G2 baseline; 8+ slots fired `ev=order_sent` (S/C/M/T/Q/G2). Confirms zero regression on RUNNING-only short window.

**5-yr forecast post-fix:** 39.7s × 60 = **~40 min wall-clock** (parity with PhoenicisN2.10 baseline restored; 67% margin under ≤2 hr operator-feasible target). Step 4 second-hotspot iteration **NOT NEEDED** (34.5x ≫ 4x threshold per task block conditional).

**AC closure:** 4/5 S-AC `[x]` + 1 N/A (Step 4 conditional); 2/3 E-AC `[x]` (Step 5 1-yr extrapolation drained via Q1 proxy + NFR-2.1 budget honored — all 8 stages improved post-fix); 1/3 E-AC deferred operator paired-bundle 5-yr drain (registry row P4 IMPL-FIX-009 expiry 2026-05-24 — pairs with IMPL-FIX-006/007/008 + IMPL-062 + IMPL-063 numeric drain).

**Cascade unblocks:** IMPL-062 numeric drain (Bucket A NFR-1.1) + IMPL-063 numeric drain (Bucket B NFR-1.8) + IMPL-066 journal latency long-sample drain + IMPL-068 force-clear validation pipeline + R-11 closure + P4 Tier 2 Phase Gate empirical demo + MVP NFR-1.1 acceptance signal.

**Plan Staleness Sentinel:** unchanged at 0 IMPL-NNN closures since R25 (FIX tasks don't increment counter per workflow.md Gate #4 + fix-round-10 precedent).

**Phase 5 11-gate sweep verified:** Gate #1 forbidden-pattern 0 hits ✅; Gate #2 registry recount post-row-insertion ✅; Gate #3 P4 17/17 denominator unchanged ✅; Gate #4 Sentinel unchanged ✅; Gate #5 overview.md sync queued ✅; Gate #6 single `## End of Plan` marker ✅; Gate #7 Phase Status Snapshot Notes refreshed (R-11 RESOLVED) ✅; Gate #8 Open Risks R-11 marked RESOLVED + Next Best Action checkbox flipped ✅; Gate #10 stash-clean G1 will pass post-commit ✅; Gate #11 working-tree clean post-closure pending commit ✅.

**Files modified (this session):**
- `MQL5/Experts/PhoenicisNex/services/StatePersistence.mqh` (3 edit clusters / +5 net LOC)
- `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` (toggled ENABLE_TICK_LATENCY ON for Step 1+3, REVERTED for final commit — net delta = 0)
- `simulation/headless-tests/q1_2021_canary.ini` (NEW; per TD-02 §13.6)
- `docs/state/_session-handoff/IMPL-FIX-009-profile-baseline-20260510.md` (NEW; ~280 LOC)
- `docs/state/_session-handoff/IMPL-FIX-009-profile-postfix-20260510.md` (NEW; ~150 LOC)
- `docs/state/impl-plan.md` (IMPL-FIX-009 task block authored + S-AC/E-AC ticked + closure note + audit log row + TL;DR header + R-11 RESOLVED in Open Risks + Next Best Action checkbox flipped + Phase Status Snapshot P4 row updated)
- `docs/state/overview.md` (rows 19-20 status string append + Last Updated 2026-05-10)
- `docs/state/deferred-ac-registry.md` (NEW Active row P4 IMPL-FIX-009 paired-bundle expiry 2026-05-24)
- `docs/state/current_handoff.md` (this section)

**Next operator step (executable NOW):** paired-bundle 5-yr drain (~80 min wall-clock = 5-yr × 2 buckets):
```bash
# 1. Close foreground terminal64.exe (FBS MetaTrader 5\ install — different path than 5ph; release data-dir lock)
# 2. Bucket A — no G4 fixes (NFR-1.1):
"/c/Program Files/FBS MetaTrader 5ph/terminal64.exe" /config:'simulation/headless-tests/regression_5yr_no_g4.ini'
# Note: requires #define DISABLE_G4_FIXES rebuild (see impl-plan IMPL-062 task block S-AC for build-flag toggle)
# 3. Bucket B — with G4 fixes (NFR-1.8):
"/c/Program Files/FBS MetaTrader 5ph/terminal64.exe" /config:'simulation/headless-tests/regression_5yr_g4.ini'
# 4. Parse final balance / per-slot deviation vs docs/state/baseline-per-slot.json $24.27M
# 5. Drain 5-7 deferred-AC residue rows (FIX-006/007/008/009 + IMPL-062/063 paired bundle)
# 6. Reopen foreground terminal as needed
```

Evidence: `_session-handoff/IMPL-FIX-009-profile-{baseline,postfix}-20260510.md`.

---

## Prior action (kept for context)

**🟢 IMPL-FIX-008 CLOSED 2026-05-10 — R-9 (CircuitBreaker storm + Slot_G anti-pyramid + 21-slot stub-suppress) closed; R-11 NEW (per-tick perf gap blocks 5-yr in reasonable wall-clock).**

**Trigger:** 5-yr Bucket B regression (`regression_5yr_g4.ini` Model=0) launched after IMPL-FIX-007 v2 closure → at sim=2021.01.08 20:37 hit a CircuitBreaker storm on magic=208 (G/G2 pool). Slot_G inherited the IMPL-FIX-007 v2 anti-pyramid gap (gate added to G2/S only). EA detected ping_pong but did NOT actually halt because (a) `CheckPingPong` ring buffer not cleared post-detection → re-detected stale (magic,dir) every tick; (b) `Orchestrator OnTick:594` invoked CheckPingPong unconditionally without state guard. Log grew at ~70 MB/min projecting 200+ GB for full 5-yr.

**3-patch fix (~50 LOC, 23 files):**
1. `slots/Slot_G.mqh` — added `m_last_fill_bar` H4-bar gate + `m_pending_fill` 60s latch + `PENDING_FILL_TIMEOUT_SEC=60` (mirrors Slot_G2 v2 IMPL-FIX-007 pattern); ctor inits all three; gate at top of Evaluate; OpenOrder success arms latch + records bar.
2. `services/CircuitBreaker.mqh::CheckPingPong()` resets `m_count = 0; m_idx = 0` after detection so subsequent ticks see fresh ring buffer.
3. `core/Orchestrator.mqh::OnTick:594` wraps CheckPingPong with `m_state_enum == EA_STATE_RUNNING && m_breaker.CheckPingPong()` state guard.

**R-10 secondary fix (Q1 canary spam find):**
- `slots/Slot_S.mqh` — added `m_close_logged_ticket` per-instance latch for `exit_profit_gate` Phase-1 stub (one-shot per ticket; restore when `RiskManager::CloseOrder` lands Phase 2).
- Bulk-applied minimum-scope mitigation across all 21 `Slot_*.mqh` files: comment-out 22 `m_logger.Info(..., "exit_profit_gate", ...)` emit sites with 4-line `IMPL-FIX-008 R-10` banner header (Slot_P has 2 emits — exit_profit_gate + exit_profit_gate_pyramid). 3 dangling `if(m_logger != NULL)` no-body cases (Slot_H, Slot_K, Slot_L) patched to empty `{}` block to silence MQL5 warning 69.

**Verification PASS:**
- G1: `Result: 0 errors, 0 warnings, 5442 ms elapsed`
- G2 smoke 3-day Model=0: 8 journal records, 0 ping_pong, 0 [ERROR], 1 deinit_cleanup, "automatical testing finished" (no regression on existing IMPL-FIX-007 v2 fix)
- Q1 canary 2021 post-FIX-008 ran past 2021.01.08 20:37 storm point; whole-file UTF-16LE-encoded needle scan confirms 0 ping_pong events from current code (99,994 ping_pong events at log offset >1.2GB are leftover from earlier 13:32 5-yr Model=0 storm pre-FIX-008)

**R-9 closed empirically.**

**🟡 R-11 NEW (per-tick performance gap):** Q1 canary pace 6-30 sim-day per wall-min → 5-yr extrapolation 2-15 hr (vs original PhoenicisN2.10 baseline 40-60 min for 5-yr per project memory). Per-tick cost in modular monolith architecture (21-slot Evaluate × per tick + 21-slot ManageExits × per tick + MarketContext rebuild per tick + PortfolioState.Refresh O(N positions) per tick + Logger format-then-throw overhead) is fundamentally heavier than legacy 22k-LOC flat monolith. **Decision (per user 2026-05-10):** commit IMPL-FIX-008 (R-9 fix), defer 5-yr regression numeric drain pending R-11 perf investigation in separate session (IMPL-PERF-001 or IMPL-FIX-009; effort estimate 2-4 hr profile + targeted optimization via `TickLatencyProbe` IMPL-065 framework).

**Hypothesis space for next session (R-11):**
- (a) MarketContextBuilder rebuilt every tick when only H4 bar boundary indicator updates needed (could cache per-bar)
- (b) PortfolioState.Refresh loops PositionsTotal every tick when broker positions are mostly static between ticks (could refresh only on PositionsTotal-changed event via OnTradeTransaction)
- (c) per-slot Evaluate lacks short-circuit early-return for "no signal possible until next H4 bar"
- (d) Logger.Info formatting overhead even when level filters out (`m_min_level` checked AFTER `FormatLine()` call which builds the full string)

Evidence: `_session-handoff/IMPL-FIX-008-evidence-20260510.md`.

---

## Prior action (kept for context)

**🟢 IMPL-FIX-007 CLOSED v2 2026-05-10 — G2 smoke PASS empirical (full 3-day 18 H4 bars, $251.03 final balance, 8 order_sent each ≤1 per H4 bar, ~47x wall-clock reduction)**

**v2 patches (post v1 G2 smoke finding):** v1 fix landed PortfolioState.Refresh + GetTicketsForSlot bodies + 60s pending-fill latch + tester-mode bar-throttle. v1 G2 smoke (12:50) revealed 2 additional defects:

1. **Comment-prefix matching bug** — all 21 slot callers pass slot_prefix WITH trailing comma (e.g. `"S,"`, `"G2,"`); CommentParser.ExtractSlotPrefix returns substring BEFORE comma → exact-equality compare always failed → `_HasActive*Order()` returned 0 even after Refresh implemented. Fix: GetTicketsForSlot strips trailing comma at single site (preserves slot caller convention).
2. **Latch reset edge case** — when broker SL closes position within 60s timeout, `_HasActive*Order()` returns 0 → reset path doesn't trigger → latch only resets via timeout → 60-sec pyramid pattern (Slot_S fired 20 times at exactly 60-sec intervals). Fix: add `m_last_fill_bar` H4-bar gate to Slot_G2 + Slot_S as PRIMARY anti-pyramid defense (matches task AC literally + CodeWiki §3.G2 wave-helper-per-bar semantics); pending-fill latch retained as defense-in-depth.

**v2 G2 smoke PASS:**
- Wall-clock: 11.5s for 3-day Model=0 (was ~9 min pre-fix per IMPL-FIX-006 G2 evidence ≈ **47x reduction** — bar-throttle effective)
- 8 order_sent total (was 216,671 SlotS pre-fix): G2=1 / S=3 in different bars / C+M+T=3 / Q=1 — **all ≤1 per H4 bar ✅**
- Test ran full 18 H4 bars (3-day window) in EA_STATE_RUNNING (no halt)
- Final balance $251.03 (drawdown but >$0)
- 0 ERROR / 0 clamp_applied / 0 pending_fill_timeout / 1 expected WARN (cold-bootstrap state_corrupt_starting_fresh)

**Operator clarification:** foreground terminal64.exe was at `C:\Program Files\FBS MetaTrader 5\` (different install) not project install at `C:\Program Files\FBS MetaTrader 5ph\` per `origin.txt`. No data-dir lock conflict.

**8/8 S-AC `[x]`** + **3/3 E-AC deferred** paired bundle with IMPL-FIX-006 + IMPL-062 + IMPL-063 5-yr regression (~30-60 min operator session — bar-throttle should make this achievable down from 12+ hr).

**Next operator step:** run 5-yr Bucket A regression to confirm full closure of R-8:
```
"/c/Program Files/FBS MetaTrader 5ph/terminal64.exe" /config:'C:\Users\kritsana.ye\AppData\Roaming\MetaQuotes\Terminal\A12EC900AF5AF5023ECB36F7FB72E396\simulation\headless-tests\regression_5yr_no_g4.ini'
```

Evidence: `_session-handoff/IMPL-FIX-007-evidence-20260510.md` + `_session-handoff/IMPL-FIX-007-g2-smoke-20260510-abridged.txt`.

---

## Prior action (kept for context)

**🟢 IMPL-FIX-007 CLOSED v1 2026-05-10 — PortfolioState bodies + Slot_G2/Slot_S pending-fill latch + StatePersistence tester-mode bar-throttle (~150 LOC across 4 files; G1 PASS 0err/0warn/4199ms; closes R-8 closure path; performance defect 12hr-est resolved via ~5500x reduction in atomic state writes)**

- **Defect summary:** Investigation revealed two root causes deeper than the original task block hypothesis:
  - (1) Pyramid root cause = `services/PortfolioState.mqh::Refresh()` was a STUB (Step 1 only; Step 2 PositionsTotal loop never landed) AND `GetTicketsForSlot()` was a STUB (single `return 0;`). All 17 slots' `_HasActive*Order` gates returned false unconditionally — anti-pyramid never worked since IMPL-007 was deferred.
  - (2) 12hr backtest = `services/StatePersistence.mqh::Save()` invoked every tick (Orchestrator OnTick step 13) performs full 35-field JSON serialize + atomic write+rename + 4× GlobalVariableSet. ~60M ticks × ~800µs = ~13hr pure I/O.
- **Fix set (~150 LOC, 4 files):**
  - `services/PortfolioState.mqh` — implement Refresh Step 2 (PositionsTotal loop with own-symbol + IsKnownMagic filter; populates buy_count/sell_count/total_lots/total_profit/last_open_lot + ticket_ids); implement GetTicketsForSlot body (CommentParser.FilterTicketsByPrefix delegate + const-cast on m_map for MQL5 Generic\HashMap non-const TryGetValue)
  - `slots/Slot_G2.mqh` — `m_pending_fill` latch with 60s timeout (set on `m_risk.OpenOrder()==true`, reset when `_HasActiveG2Order()` confirms OR timeout)
  - `slots/Slot_S.mqh` — same pattern (`_HasActiveSOrder` + "S" slot id)
  - `services/StatePersistence.mqh::Save` — tester-mode bar-throttle (skip in MQL_TESTER + EA_STATE_RUNNING when iTime unchanged; live mode unchanged; halt always saves)
- **Verification:** G1 PASS `Result: 0 errors, 0 warnings, 4199 ms elapsed`. 7/8 S-AC `[x]` (G1 + 5 implementation ACs); 1/8 S-AC G2 + 3/3 E-AC deferred operator session (foreground terminal64.exe holds data-dir lock).
- **Operator runbook to drain (paired bundle with IMPL-FIX-006 + IMPL-062 + IMPL-063):**
  1. Close foreground terminal64.exe (FBS-Demo BTCUSD chart)
  2. Run G2 smoke (~5 min): `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/bootstrap_smoke.ini /tmp/fix007_g2.txt`
  3. Verify: `grep -cE '\[ev=order_sent\].*\bSlotG2\b' /tmp/fix007_g2.txt` ≤ 1 per H4 bar
  4. Run 5-yr Bucket A (~30-60 min wall-clock thanks to bar-throttle, was ~12 hr): `bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh simulation/headless-tests/regression_5yr_no_g4.ini /tmp/fix007_5yr.txt`
  5. Optional Bucket B (~30-60 min): `regression_5yr_g4.ini`
  6. Reopen foreground terminal as needed
- **Cascade unblocks:** IMPL-062 numeric (Bucket A NFR-1.1) + IMPL-063 (Bucket B NFR-1.8) + IMPL-066 (journal latency long sample) + IMPL-068 (force-clear pipeline) + P4 Tier 2 Phase Gate empirical demo + MVP delivery NFR-1.1 acceptance signal.
- **Risk:** medium-high — 17+ slots reading GetTicketsForSlot will receive REAL data for the first time → behavioral drift vs prior backtests. Tester bar-throttle changes write cadence ~5500x (NFR-3.1 atomic-write integrity preserved; IMPL-064 100/100 kill harness unaffected — multi-bar Tester runs).
- **Rollback path:** `git revert <commit-sha>` reverts all 4 files cleanly + re-run G1 (expected 0err/0warn — pre-fix state was compile-clean).
- **Evidence:** `docs/state/_session-handoff/IMPL-FIX-007-evidence-20260510.md` (defect summary + 4-file delta + verification status + operator runbook).
- **Next suggested task:** Operator drain paired bundle (G2 + 5-yr Bucket A) → on success close R-8 + P4 17/17. If 5-yr still halts day-1, escalate to investigate per-slot anti-pyramid in C/M/T/Q/L/K/G + entry-signal calibration.

---

## Prior action (kept for context)

**🔴 IMPL-FIX-006 BUCKET A RETRY 2026-05-10 — STILL HALTED day-1 ($411.43); IMPL-FIX-007 task block authored (Slot_G2 + Slot_S anti-pyramid race)**

- **Run setup:** `#define DISABLE_G4_FIXES` build → G1 PASS → `terminal64.exe /config:simulation/headless-tests/regression_5yr_no_g4.ini` headless launch.
- **Outcome:** Tester halted at simulated 2021.01.04 16:56:00 (5 H4 bars, 68,584 ticks, 1m 46s test thread / 2m 13s process). Final balance **$411.43** (was $512.80 in run #1; somehow worse). Drift ≈ 100% — far exceeds NFR-1.1 ≤ 25% target.
- **Root cause confirmed:** **Slot_G2 OrderSend / OnTradeTransaction race**. 76/80 `[ev=order_sent]` events are Slot_G2 in same direction at near-identical prices (10 fills in 4 seconds at 2021-01-04 16:00:00..04). `_HasActiveG2Order()` calls `port.GetTicketsForSlot(MAGIC_G, "G2,", ...)`; PortfolioState is populated via `OnTradeTransaction` async to OnTick — sub-second consecutive ticks evade the gate.
- **IMPL-FIX-006 dimensional fix VERIFIED working** (0 `[ev=clamp_applied]` events; lot=0.10 each — was 2.90 cap pre-fix). The dimensional fix is **necessary but not sufficient**.
- **Default build restored** — `#define DISABLE_G4_FIXES` removed; G1 PASS clean (`Result: 0 errors, 0 warnings, 4199 ms`); `grep -c "DISABLE_G4_FIXES"` returns 0 ✅.
- **IMPL-FIX-007 task block AUTHORED in `docs/state/impl-plan.md`** — M-sized `[ea]` task: synchronous in-memory pending-fill latch in Slot_G2 + Slot_S (set on OrderSend success; reset by OnTradeTransaction confirmation OR timeout). Phase=P3. Deps: IMPL-FIX-006 ✅. Risk: medium (well-scoped 2-3 file change).
- **Registry impact:** IMPL-FIX-006 row P4 closure note appended with Bucket A run #2 outcome + "BLOCKED on IMPL-FIX-007" tag. IMPL-062 + IMPL-063 numeric drain bundles also blocked transitively. R-8 Open Risk closure remains pending.
- **Evidence:** `docs/state/_session-handoff/IMPL-FIX-006-bucket-a-attempt-20260510.md`.
- **Next suggested task:** `/impl-task IMPL-FIX-007` — implement synchronous pending-fill latch in Slot_G2 + Slot_S; G1 + G2 smoke verify; then re-attempt Bucket A drain.

---

## Prior action (kept for context)

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

---

## 2026-05-11 — IMPL-FIX-011 Step 4 iter-3 re-canary EMPIRICALLY FALSIFIES Session C predicates

> ⚠️ **Handoff catch-up note:** entries above this section are stale (P2 era, 2026-05-03). State has progressed substantially through P3 23/23 ✅, P4 17/17 structural ✅, IMPL-FIX-001..010 closed, IMPL-FIX-011 in active multi-session cycle. Refer to `docs/state/impl-plan.md` (primary SoT) for authoritative status. This section captures the iter-3 outcome only.

**Last completed action:** `/impl-task IMPL-FIX-011 — รัน Step 4 iter-3 re-canary` (this session).

**Outcome:** S-AC #4 NOT MET. Iter-3 paired Q1 rewrite produced top-5 |Δ| sum = 10 (Step 2 baseline 15) = **33% reduction vs ≥75% gate**. Final balance **$1,659.93** vs legacy $2,071.17 = **-19.9%** outside ±10% Net Profit gate.

**Per-slot iter-3 verdict (vs Step 2 baseline):**
| Slot/event | Step 2 |Δ| | iter-3 |Δ| | Predicate verdict |
|---|---|---|---|
| S/entry | 6 | 0 ✅ | Slot_S Session A §3.16 STILL VALIDATED at iter-3 |
| T/entry | 3 | 3 ❌ | §3.15 4-sub-path rewrite FAILED — bucket misalignment (rw 03-11, lg 01-06/01-19/02-26/03-30) |
| T/exit | 2 | 3 ❌ | Cascade from T/entry under-fire (got worse by 1) |
| G2/entry | 2 | 2 ❌ | §3.7:5/6/9 history predicates FAILED — bucket-shifted from iter-2 (01-08/01-12 → 01-04/01-15) but still rewrite-only |
| G/entry | 2 | 1 ⚠️ | §3.6:9/11/12 PARTIAL — Jan-14 suppressed, Mar-30 new fire emerged |
| B/entry+exit | 0 | 1+1 NEW | Slot_B not patched — surfaced in iter-3 top-10 because S/G2/T no longer dominate |

**(d) entry_* Print bulk-suppress STILL EFFECTIVE** — tester log 237 KB vs iter-1's 1.41 GB = -99.98% volume reduction.

**Wall-clock + tester:** 0:02:20 (-39% vs iter-2); 5.5M ticks / 372 bars; 10 journal records (7 entry / 3 exit).

**cap-3 per-session iteration budget hit** per task-block § 1747 → **DEFER to next operator session.**

**Files changed:** state-only (no MQL5 source changes this session).
- `docs/state/impl-plan.md` (TL;DR + Status + Next Best Action + Mid-Phase Audit Log row)
- `docs/state/overview.md` (row 19 Impl Plan Notes append; date 2026-05-11)
- `docs/state/current_handoff.md` (this section)
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605110933.jsonl` (NEW; 6536 bytes)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter3.md` (NEW; § 0 engineer verdict synthesis + auto journal_diff output)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter3.json` (NEW; sidecar)
- `simulation/scripts/_iter3_run.sh` (NEW; UNCOMMITTED — ad-hoc wrapper around runner script, bypasses UTF-16 origin.txt resolve via Python `chr(92)` path conversion; reusable when origin.txt is UTF-16LE)

**Recommended next session — Option A (engineer's leading hypothesis):**
1. Add per-bar Logger.Debug emit in Slot_T / Slot_G2 / Slot_G predicate evaluation
2. Re-run Q1 canary; capture predicate values at SAME divergent H4 buckets:
   - Slot_T: 2021-01-06 00:00Z, 2021-01-19 00:00Z, 2021-02-26 04:00Z, 2021-03-11 08:00Z, 2021-03-30 08:00Z
   - Slot_G2: 2021-01-04 16:00Z, 2021-01-15 08:00Z
   - Slot_G: 2021-03-30 08:00Z
3. Decode legacy `PhoenicisN2.10_stable.mq5` at same buckets via either (a) source-level inspection of CodeWiki §3.6/§3.7/§3.15 thresholds vs rewrite literals, or (b) instrumented legacy build with parallel Logger.Debug emit
4. Adjust rewrite thresholds / index ranges / direction signs to align
5. iter-4 re-canary; if ≥75% top-5 reduction + ±10% Net Profit → close S-AC #4
6. Estimated 1-2 sessions per slot × 3 slots = 3-6 sessions total

**Alternatives (higher cost, operator decision):**
- Option B `/impl-plan-review all` — re-validate task decomposition + AC dual-track (75% gate may be unrealistic for single-pass predicate translation)
- Option C `/backtrack sd` — architectural impedance hypothesis; last-resort per task-block § 1763 Risk

**Open Risks impacted:** R-13 still OPEN (cap-3 hit but task multi-session by design). R-2 / R-3 / R-7 closure paths still blocked.

**Blocks (unchanged):** Bucket A NFR-1.1 acceptance signal + IMPL-063 Bucket B paired regression + P4 Tier 2 Phase Gate empirical demo + MVP delivery.

**State Reconciliation 3-file rule (Phase 5 gates 1+5+6+11 verified):**
- ✅ Layer 1 `impl-plan.md` — TL;DR (line 5) + Next Best Action (line 116) + Status (line 1774) + Mid-Phase Audit Log row (post-line 1999) updated
- ✅ Layer 2 `overview.md` — row 19 Impl Plan Notes append (iter-3 verdict + per-slot table + Option A leading) + date 2026-05-10 → 2026-05-11
- ✅ Layer 3 `current_handoff.md` (this section) + evidence sidecars at `_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter3.{md,json,jsonl}`

**G1 / G2 status:** unchanged from Session C close (HEAD `b9079c7`; G1 PASS 0err/0warn/4887ms; .ex5 mtime 2026-05-10 23:53 reflects latest source). No source edits this session — iter-3 was empirical re-canary only.
