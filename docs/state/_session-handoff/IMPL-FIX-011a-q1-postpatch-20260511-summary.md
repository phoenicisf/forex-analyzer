# IMPL-FIX-011a Step 4 iter-4 — Q1 paired re-canary EMPIRICAL VERDICT

**Date:** 2026-05-11
**Run wall-clock:** 3:23.739 (3.4 min)
**Ticks/bars:** 5,500,180 / 372 H4
**Build:** PhoenicisNex.ex5 post-Fix-A+B+C+D+E+F (commit `4bbe13d` HEAD)
**Inputs:**
- Rewrite journal: `docs/state/_session-handoff/IMPL-FIX-011a-q1_rewrite_postpatch_202605111128.jsonl` (9 events)
- Legacy baseline: `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events)
- journal_diff report: `docs/state/_session-handoff/IMPL-FIX-011a-q1-postpatch-20260511.md`

## § 0 Verdict — S-AC #3 NOT MET

| Metric | Result | S-AC #3 gate | Verdict |
|---|---|---|---|
| Slot_T entry |Δ| (per-bucket sum) | 4 (rewrite 0; legacy 4 at 4 buckets) | ≤ 1 | ❌ FAIL |
| Slot_T exit |Δ| | 3 | (paired with entry) | ❌ FAIL |
| Spurious 2021-03-11 BUY suppression | ✅ rewrite silent | required | ✅ Fix A worked |
| All 4 legacy buckets fire on rewrite | ❌ 0/4 fired | required | ❌ FAIL |
| Final balance vs legacy | $1,250.24 vs $2,071.17 = **-39.6%** | within ±10% Net Profit | ❌ FAIL |

## § 1 Per-bucket result vs § 4.1 prediction

| Bucket | Legacy | Diagnostic § 4.1 prediction | iter-4 actual |
|---|---|---|---|
| 2021-01-06 02:50 SELL `T,H,B` direct-main | ✅ | ❓ uncertain | ❌ silent |
| 2021-01-19 01:02 SELL `T,PF` THAF | ✅ | ❌ (THAF blocked on Fractal+zone) | ❌ silent (matches prediction) |
| 2021-02-26 04:00 SELL `T,PF` THAF | ✅ | ❌ (THAF blocked on Fractal+zone) | ❌ silent (matches prediction) |
| 2021-03-11 08:00 BUY rewrite-only spurious | ❌ | ✅ suppress via Fix A | ✅ suppressed (Fix A worked) |
| 2021-03-30 10:46 BUY `T,H,A` direct-main | ✅ | ❓ uncertain | ❌ silent |

## § 2 Root-cause analysis — base signal blocks at all legacy buckets

Rewrite Slot_T fires **0 entries** across all 4 legacy buckets. The new 5-state sub-path classifier (Fix C) is never invoked because **base signal `_IsTBuyBaseSignal`/`_IsTSellBaseSignal` returns false** at every legacy bar. Sub-path data (Fix D Fractal, Fix E zone metadata, Fix F wave-anchor) is moot when the base gate denies entry to Phase A.

### Predicates in current base signal (Slot_T.mqh `_IsTBuyBaseSignal`)

1. **`_IsTBuySupportZone`** — `has_support && bb_pct < 5`
2. **`_IsPriceAboveHull`** — `bid <= ctx.hull_h4.hull` (post-Fix-A mean-reversion semantics)
3. **`_BBTopBelowIchiMaxCount >= InpTBBHistMinAboveCount(=7)`** — Fix B per-bar `bb_top[i] < cloud_low[i]`
4. **`_IsAdxDominant`** — `adx > InpTAdxMin (=25)`

### Hypothesis: Fix A semantic interpretation needs review

Diagnostic § 1.1 shows legacy BUY outer gate uses TWO conditions:
- `Hull[0] < H4Support.hi` (Hull MA below SUPPORT-zone resistance level)
- `pricePercentRange < 5` (BB% — zone-band)

Diagnostic § 3 row A claimed legacy uses `bid <= Hull` — but legacy code actually compares **Hull vs Support.hi**, NOT bid vs Hull. The pre-Fix-A rewrite `bid > Hull` was wrong (trend-following); Fix A flipped to `bid <= Hull` (mean-reversion) — but neither matches the legacy `Hull < Support.hi` predicate. This is a **diagnostic-vs-legacy-source inconsistency** that was not surfaced at Fix A authoring time.

Likely fix: replace `_IsPriceAboveHull` with `Hull < H4Support.hi` (Hull below resistance level) — requires reading `subdem_h4.support_zone` or equivalent. This is a Fix A revisit, not a new fix.

### Other candidate blockers

- **Fix B `BBTopBelowIchiMaxCount >= 7`** may be too strict for 2021-03-30 (winter-spring volatility regime)
- **`_IsTBuySupportZone` `bb_pct < 5`** may be too tight; legacy `pricePercentRange` formula could differ
- **ADX `> InpTAdxMin (=25)`** may exclude low-ADX bars where legacy fires

## § 3 Multi-slot observations (out of IMPL-FIX-011a scope — flagged for 011b/c/d)

| Slot | Rewrite | Legacy | |Δ| | Routing |
|---|---:|---:|---:|---|
| G2 entry | 2 | 0 | 2 | IMPL-FIX-011b sub-ticket |
| G entry | 1 | 0 | 1 | IMPL-FIX-011c sub-ticket |
| Q entry | 1 | 0 | 1 | (not yet ticketed; long-tail per IMPL-FIX-011d) |
| B entry+exit | 0+0 | 1+1 | 2 | IMPL-FIX-011d |
| BR entry+exit | 0+0 | 1+1 | 2 | IMPL-FIX-011d |
| D entry | 0 | 1 | 1 | IMPL-FIX-011d |
| H, K, M, P entry | drift | drift | 1 each | IMPL-FIX-011d long-tail |

G2 buckets shifted from iter-3 (was 2021-01-08+01-12 → now 2021-01-04+01-15) — Session C §3.7:5/6/9 predicates still bucket-shifting, not suppressing.

## § 4 Recommended next session — Fix A calibration revisit + per-bucket Logger.Debug

**Engineer-side IMPL-FIX-011a architectural work IS complete** (S-AC #1 + #2 ✅ MET; all 6 fix clusters G1-clean; 13 commits / 1 day / single engineer). What remains is **predicate calibration** at the 4 legacy buckets, specifically:

1. **Add Logger.Debug instrumentation** in `_IsTBuyBaseSignal`/`_IsTSellBaseSignal` per predicate (emit when condition fails + emit current value vs threshold) gated to fire only at the 4 legacy bar timestamps (`is_target_bar` filter via `tick_time` match)
2. **Re-run Q1 canary iter-5** — collect Debug emit at the 4 buckets
3. **Identify the blocking predicate** at each bucket (e.g., "2021-01-06: cloud-scan count=3 < 7" or "2021-03-30: adx=18 < 25")
4. **Calibrate threshold OR revisit Fix A semantic interpretation** (replace `bid <= Hull` with `Hull < Support.hi` if subdem_h4.support_zone exposes the right value)

Per cap-3 iteration rule on parent IMPL-FIX-011 task block § Step 4: this is **iter-4 (cap-3 already exceeded)**; further iteration would require:
- (A) Operator approval to extend cap, OR
- (B) Scope to NEXT sub-ticket (IMPL-FIX-011b Slot_G2 or 011c Slot_G — different cap counter), OR
- (C) Escalate to `/backtrack sd` if Fix A diagnostic-vs-legacy inconsistency is structural

## § 5 S-AC status

- **S-AC #1** ✅ MET (6/6 fix clusters G1-clean — `0err/0warn`)
- **S-AC #2** ✅ MET (ADR-004 const& preserved; schema additive; PMR contract additive read-only)
- **S-AC #3** ❌ NOT MET (Slot_T |Δ|=7 entry+exit combined; required ≤ 1)
- **S-AC #4** ⏸️ NOT RUN this session (G2 smoke 3-day separate ini)

## § 6 Phase 5 mechanical gates

- Gate 1 forbidden-pattern grep: 0 hits — no `deferred per .* precedent` / `live verification deferred`
- Gate 6 file integrity: 1× `## End of Plan`
- Gate 11 working-tree clean (post this artifact commit)

## § 7 Artifacts

- This summary: `docs/state/_session-handoff/IMPL-FIX-011a-q1-postpatch-20260511-summary.md`
- journal_diff full report: `docs/state/_session-handoff/IMPL-FIX-011a-q1-postpatch-20260511.md`
- journal_diff JSON sidecar: `docs/state/_session-handoff/IMPL-FIX-011a-q1-postpatch-20260511.json`
- Rewrite journal: `docs/state/_session-handoff/IMPL-FIX-011a-q1_rewrite_postpatch_202605111128.jsonl`
