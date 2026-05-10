# IMPL-FIX-011 Step 4 (iter 2) — Q1 2021 Post-patch Paired Journal Diff

**Generated:** 2026-05-10T22:30:00+07:00
**Script:** `simulation/scripts/journal_diff.py` (Python stdlib; reproducible)
**Iteration:** 2 of cap-3 per Step 3-4 decision gate
**Inputs:**
- Rewrite (post-Session-B): `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605102222.jsonl` (12 events / 8 entry / 4 exit)
- Legacy (Step 1 unchanged): `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events / 13 entry / 11 exit)

**Run config:** `simulation/headless-tests/q1_2021_paired_rewrite.ini` (Q1 2021.01.01–2021.03.31, Model=4, $1000/1:500). Wall-clock 0:03:05.685 (iter-1 baseline 0:03:02.519; iter-2 +0:00:03.166 / +1.7%). Final balance **$1,691.69** (iter-1 baseline $2,188.09; **-22.7%**; legacy baseline $2,071.17 → rewrite now **-18.3%** → exits ≤10% Net Profit gate).

> **See § 0 below for engineer synthesis + verdict + recommended revert path. Auto-generated § 1-§ 8 follow.**

---

## 0. Step 4 iter-2 verdict — Session B G/G2 patches EMPIRICALLY INEFFECTIVE; Net Profit regression

### 0.1 Headline

**Session B G/G2 eligibility-tightening patches (CodeWiki §3.6:9 + §3.7:1 + §3.7:4) had ZERO measurable effect on top-10 |Δ| sum and CAUSED a Net Profit regression of -22.7% vs iter-1 (within +5.6% of legacy → -18.3% below legacy → exits ±10% gate).**

| Slot/Event | Step 2 \|Δ\| | Step 4 iter-1 \|Δ\| | Step 4 iter-2 \|Δ\| | Net reduction (iter-2 vs Step 2) |
|---|---|---|---|---|
| **S/entry** (was top-1) | 6 | 0 | 0 | 100% ✅ (Session A holding) |
| T/entry | 3 | 3 | 3 | 0% (out-of-Session-B scope) |
| G/entry | 2 | 2 | **2** | **0%** ❌ (Session B patch ineffective) |
| G2/entry | 2 | 2 | **2** | **0%** ❌ (Session B patch shifted bucket only) |
| T/exit | 2 | 2 | 2 | 0% (out-of-Session-B scope) |
| **Sum top-5** | **15** | **10** | **10** | **−33% (iter-1 holding; Session B 0% delta)** |
| **Sum top-10** | **20** | **15** | **15** | **−25% (iter-1 holding; Session B 0% delta)** |

**Average top-5 reduction (iter-2 vs Step 2): (100+0+0+0+0)/5 = 20%** — same as iter-1, NO improvement from Session B.

### 0.2 S-AC #4 status: **NOT MET — INEFFECTIVE PATCH**

S-AC #4 text: *"Step 4 re-canary post-patch divergence reduction ≥ 75% per-slot vs Step 2 baseline (Q1 trajectory matches legacy within ~10% on top-5 slots)."*

- Per-slot top-5 reduction: 1/5 (S 100%) vs ≥75% required on each → NOT MET.
- Sum-of-|Δ| top-5 reduction: 33% (15→10) vs ≥75% interpretation gate → NOT MET.
- Sum-of-|Δ| top-10 reduction: 25% (20→15) → NOT MET.

**Verdict: cap-3 iteration headroom remains 1 (this was iter-2; iter-3 cap available); however, recommend NOT iterating Session B further and instead REVERT + escalate to Slot_T Session C MarketContext extension (which would also unblock proper G/G2 history-based predicates).**

### 0.3 Net Profit gate REGRESSION

Task-block § Step 4 decision gate: *"if Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → proceed to Step 5; else iterate Steps 2-4."*

| Metric | Step 1 baseline | iter-1 | iter-2 | iter-2 vs legacy | iter-2 vs iter-1 |
|---|---|---|---|---|---|
| Final balance | $1,774.64 | $2,188.09 | **$1,691.69** | **-18.3%** ❌ | **-22.7%** |
| Net Profit gate | -14% (legacy) ❌ | +5.6% (legacy) ✅ | -18.3% (legacy) ❌ | exits ±10% gate |
| Entry count | 14 | 8 | **8** | -38% (≤10% gate ❌) | unchanged |
| Wall-clock | 0:03:51 | 0:03:02 | 0:03:05 | +1.7% | +1.7% |

**Net Profit gate was MET in iter-1 + REGRESSED in iter-2 — Session B patches actively WORSENED the rewrite's behavioral parity vs legacy on the Net Profit axis.**

### 0.4 Root cause analysis — single-tick proxies insufficient for history-dependent legacy gates

**Slot_G (current-bar Force same-side `f0` gate):** ZERO suppression effect — both 2021-01-04 16:00Z and 2021-01-14 16:00Z entries fired identically to iter-1. Hypothesis: at those H4 buckets, `f0` was already same-side as the signal direction (Force still pushing); the single-tick proxy cannot substitute for legacy CodeWiki §3.6:9's 6+ bar Force-peak history scan with extremum threshold ±25.

**Slot_G2 (peer-G `_HasActiveGOrder` + Force narrow-band F[1] in (0.2, 7)):** patch DID suppress one entry but UNCOVERED another:
- iter-1 G2 fires: 2021-01-04 16:00:00.738Z + **2021-01-08 20:37:31.529Z**
- iter-2 G2 fires: 2021-01-04 16:00:00.986Z + **2021-01-12 00:05:00.864Z**
- The 2021-01-08 G2 entry was suppressed (likely the narrow-band gate caught it — F[1] was probably barely positive < 0.2)
- BUT a NEW G2 entry emerged at 2021-01-12 00:05Z because the H4-bar gate (`m_last_fill_bar` from IMPL-FIX-007 v2) was no longer locking out subsequent fires (since 2021-01-08 didn't fire, the bar-gate cooldown didn't trigger)
- Net effect: G2 |Δ|=2 unchanged (different bucket but same total count vs legacy=0)

**Slot_G2 peer-G check (`_HasActiveGOrder`):** ineffective at 2021-01-04 16:00Z because G fires AT 16:51:34 (51 min AFTER G2's 16:00:00 entry). At G2's evaluation time, no G is open → peer-check passes → G2 fires. The CodeWiki §3.7:1 "no active G or G2" wording is satisfied at G2's evaluation moment; the legacy convention "G2 should be silent when G silent" is NOT what the literal CodeWiki spec says.

**Slot_G2 narrow-band F[1] in (0.2, 7):** ineffective at 2021-01-04 16:00Z + 2021-01-12 00:05Z because rewrite Force values at those buckets ARE within (0.2, 7); the assumption "F[1] just barely positive" was wrong for those specific buckets.

### 0.5 Why Net Profit dropped despite same entry slot mix

Both iter-1 and iter-2 have IDENTICAL 8-entry slot mix (C×1, M×1, T×1, Q×1, G2×2, G×2). The only difference is G2 #2's bucket shift:

| Field | iter-1 G2 #2 | iter-2 G2 #2 |
|---|---|---|
| Timestamp | 2021-01-08T20:37:31 | 2021-01-12T00:05:00 |
| Lot | 0.17 | 0.08 |
| Open price | 1.21999 | 1.21482 |

End-of-test forced close at 2021-03-30 23:59:58 price 1.17188. Iter-2's smaller lot (0.08 vs 0.17) at lower entry price (1.21482 vs 1.21999) on a BUY position incurs less loss on the G2 trade itself but cascades into different state for OTHER positions held to EOT — likely affecting the 4 EOT-closed positions' prices via tick-by-tick equity drawdown sequence. Net effect: -22.7% balance (-$496) without exit-side count changing.

This is exactly the artifact § 0.6 R-A risk: *"if engineer mis-reads CodeWiki spec and tightens an eligibility predicate that was correctly loose in legacy, Step 4 re-canary will show worse divergence"* — manifested here on the Net Profit axis (rather than per-slot count axis).

### 0.6 Recommended next session — REVERT + escalate to Slot_T MarketContext extension

**Recommended revert:**
- `slots/Slot_G.mqh` — revert the current-bar Force `f0` gate (~14 LOC including banner)
- `slots/Slot_G2.mqh` — revert the peer-G helper + narrow-band tightening + 2 static const (~47 LOC including banner)
- Slot_S Session A patch + (d) bulk-suppress STAY (validated 100% effective on top-1 + log-volume reduction).

**Escalate to Slot_T 4-sub-path Session C** (4-8 hr dedicated session per artifact § 0.5 alternative):
- Hull MA + Bollinger Band + SubDem zone + ADX-W dominance per CodeWiki §3.15
- **NEW:** the same MarketContext extension would also unblock proper G/G2 history-based predicates per CodeWiki §3.6:9 (Force-peak history) + §3.6:11 (Bollinger 15-bar lookback) + §3.6:12 (DeMarker rolling sum) + §3.7:6 ("≥5 of last 8 bars Force>0.2") + §3.7:9 ("≥1 bar in [2,5) with Force ≤ -0.2")
- **Folded scope:** Slot_T + (proper) Slot_G + (proper) Slot_G2 all share the MarketContext extension dependency; one consolidated session adds Hull/BB%/SubDem/ADX-W + multi-bar Force buffer + Bollinger history buffer to MarketContextBuilder, then rewrites all three slot predicates against the new fields.

**Alternative — proceed to Step 5 5-yr Bucket A retry on current state (Slot_S only fix):**
- Net Profit gate would FAIL at 5-yr (already fails at Q1 with -18.3% drift)
- BUT the 5-yr regression itself may surface more divergence sources that drive the Slot_T MarketContext extension priority — running it produces useful diagnostic data even if S-AC closure deferred
- Operator-paired (~30-40 min wall-clock); only valuable if user wants to validate IMPL-FIX-009 perf restore + Slot_S gate at scale before the 4-8 hr Slot_T session

### 0.7 Decision-gate verdict (per IMPL-FIX-011 task-block § Step 2)

Distinct entry slots with |Δ| ≥ 1 in iter-2: **11** — `B, BR, D, G, G2, H, K, M, P, Q, T` (Slot_S now silent on both legs ✅). Same as iter-1.

**Verdict — STILL dispersed (escalate)** — original Step 2 task-block guidance ("if dispersed across 8+ slots → escalate scope estimate to upper bound 8 hr / 3 sessions") remains in effect. Sessions A+B (so far ~3 hr engineer time) covered Slot_S + (d) bulk-suppress + ineffective G/G2. Session C (4-8 hr Slot_T MarketContext extension + rewrite G/G2/T predicates against history buffer) is now the next mandatory session per the dispersed-escalate verdict.

### 0.8 Plan Staleness Sentinel + Phase 5 mechanical gates

Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25 (FIX tasks + Step closures don't increment per workflow.md Gate #4 + fix-round-10 precedent).

Phase 5 mechanical gates 1+6+10+11 verified (impl-plan.md no forbidden patterns; single End of Plan; stash-clean G1 PASS; working-tree clean expected post-commit).

---

## 1. Per-leg telemetry

| Metric | Rewrite | Legacy |
|---|---|---|
| Total events | 12 | 24 |
| Entry events | 8 | 13 |
| Exit events | 4 | 11 |
| Unresolved slot_id | 0 | 0 |

### 1a. Entry slot mix (per leg)

| Slot | Rewrite entries | Legacy entries |
|---|---:|---:|
| `B` | 0 | 1 | 🟦 legacy-only |
| `BR` | 0 | 1 | 🟦 legacy-only |
| `C` | 1 | 1 | |
| `D` | 0 | 1 | 🟦 legacy-only |
| `G` | 2 | 0 | 🟥 rewrite-only |
| `G2` | 2 | 0 | 🟥 rewrite-only |
| `H` | 0 | 1 | 🟦 legacy-only |
| `K` | 0 | 1 | 🟦 legacy-only |
| `M` | 1 | 2 | ⚠️ count drift |
| `P` | 0 | 1 | 🟦 legacy-only |
| `Q` | 1 | 0 | 🟥 rewrite-only |
| `T` | 1 | 4 | ⚠️ count drift |

## 2. Per-(slot, event) divergence ranking — top 10

| Rank | Slot | Event | Rewrite | Legacy | Δ | \|Δ\| | RW buckets | LG buckets | Max RW/H4 | Max LG/H4 | Hypothesis | Rationale |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `T` | entry | 1 | 4 | -3 | 3 | 1 | 4 | 1 | 1 | **(e) eligibility** | both legs active but count drift |delta|=3 (rewrite=1 vs legacy=4) |
| 2 | `G` | entry | 2 | 0 | +2 | 2 | 2 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 2 entries in 2 H4 buckets while legacy is silent |
| 3 | `G2` | entry | 2 | 0 | +2 | 2 | 2 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 2 entries in 2 H4 buckets while legacy is silent |
| 4 | `T` | exit | 1 | 3 | -2 | 2 | 1 | 3 | 1 | 1 | **(e) eligibility** | both legs active but count drift |delta|=2 (rewrite=1 vs legacy=3) |
| 5 | `B` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 6 | `B` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 7 | `BR` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 8 | `BR` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 9 | `D` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 10 | `D` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |

## 3. H4-bucket drilldown — top-3 divergence slots (entries only)

### Slot `T` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-04 00:00Z | 1 | 0 | +1 |
| 2021-01-06 00:00Z | 0 | 1 | -1 |
| 2021-01-19 00:00Z | 0 | 1 | -1 |
| 2021-02-26 04:00Z | 0 | 1 | -1 |
| 2021-03-30 08:00Z | 0 | 1 | -1 |

### Slot `G` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-04 16:00Z | 1 | 0 | +1 |
| 2021-01-14 16:00Z | 1 | 0 | +1 |

### Slot `G2` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-04 16:00Z | 1 | 0 | +1 |
| 2021-01-12 00:00Z | 1 | 0 | +1 |

## 4. Hypothesis classification rollup (top-10 divergence)

| Hypothesis | Top-10 rows | Slots/events |
|---|---:|---|
| (e) eligibility | 10 | T/entry (|Δ|=3), G/entry (|Δ|=2), G2/entry (|Δ|=2), T/exit (|Δ|=2), B/entry (|Δ|=1), B/exit (|Δ|=1) |

## 5. IMPL-FIX-011 decision gate (per task-block Step 2 §)

Distinct entry slots with |Δ| ≥ 1: **11** — `B, BR, D, G, G2, H, K, M, P, Q, T`

**Verdict — dispersed (escalate):** divergence spans 11+ slots → escalate scope estimate to upper bound per task-block (8 hr / 3 sessions). Step 3 patches must be batched + tested incrementally to avoid regressions.

## 6. Hypothesis (d) per-tick `entry_*` Print spam — out-of-band note

Hypothesis (d) is a logging-volume defect orthogonal to journal records:
the `entry_signal` / `entry_buy` / `entry_sell` Print emits fire per-tick
when conditions persist, but they do NOT show up in this diff because
`TradeJournal` (the JSONL stream) emits one record per actual `OrderSend`
not per Print. Step 1 artifact §4 already empirically confirmed this
hypothesis (1.41 GB tester log over Q1 ≈ 30 GB / 5-yr extrapolation).

Step 3 of IMPL-FIX-011 must therefore *also* sweep the per-tick `entry_*`
Prints (mirror the IMPL-FIX-008 R-10 stub-suppress pattern that targeted
`exit_profit_gate`) — this is gating on Step 5 5-yr Bucket A retry being
operator-feasible (~30 GB log breaks the iconv decode budget).

## 7. Hypothesis (b) xslot helpers + (c) CD-pool demote — status

- **(b)** `RunSafePort` / `RunOrderGroup2` / `RunForceCutloss` /
  `ExtraCheckFunction2` — these helpers do NOT emit slot-tagged
  journal records (they emit Logger.Info events with helper-level tags);
  this diff cannot detect their per-tick emit pattern. Q1 sample did NOT
  surface their spam in Step 1 5-MB tail; defer per task-block guidance
  ('apply only if Step 2 journal-diff shows per-tick emit on those
  helpers — defensive deferral'). Reconfirm at Step 5 5-yr Bucket A.
- **(c)** CD-pool demote — `cd_demote_triggered` Logger.Info emit is
  not a TradeJournal record (no `event_type=cd_demote_triggered` in the
  rewrite JSONL); detection requires Tester log grep. Defer until
  hypothesis (d) per-tick `entry_*` spam is suppressed in Step 3 (the
  spam currently drowns CD-demote Print signal in Step 1 1.41 GB log).

## 8. Data-quality caveats

- Legacy parser resolves slot_id via 4 mechanisms (priority order):
  `OrderOpen:<SLOT>` Print prefix → comment-shape Print → `Close good
  potsition:` comment → `* Close by` phrase pattern. Each event records
  which mechanism resolved it (see `_resolved_via` field in JSON
  sidecar).
- `<unresolved>` rows in section 1a are events where none of the 4
  mechanisms succeeded — typically Tester forced end-of-test closes
  (filtered) or unusual close paths. If unresolved count is non-zero,
  inspect raw log for missed cases before trusting top-10 ranking.
- H4 bucket boundaries are UTC-aligned (00/04/08/12/16/20). EURUSD H4
  broker bars align to UTC+0/+2/+3 EET; UTC bucketing keeps comparison
  stable across DST. Per-bar slot eligibility is approximated by H4
  bucket count (off-by-one possible at DST transitions; not an issue
  for Q1 2021 which has no DST switch in the EURUSD window).

