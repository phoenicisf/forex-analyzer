# IMPL-FIX-011 Step 4 (iter 1) — Q1 2021 Post-patch Paired Journal Diff

**Generated:** 2026-05-10T14:46:35+00:00
**Script:** `simulation/scripts/journal_diff.py` (Python stdlib; reproducible)
**Iteration:** 1 of cap-3 per Step 3-4 decision gate
**Inputs:**
- Rewrite (post-patch): `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605102145.jsonl` (12 events / 8 entry / 4 exit)
- Legacy  (Step 1 unchanged): `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events / 13 entry / 11 exit)

**Run config:** `simulation/headless-tests/q1_2021_paired_rewrite.ini` (Q1 2021.01.01–2021.03.31, Model=4, $1000/1:500). Wall-clock 0:03:02.519 (Step 1 baseline 0:03:51.984; -21%). Final balance **$2,188.09** (Step 1 baseline $1,774.64; +23.3% — moves toward legacy $2,071.17 baseline, now within +5.6%).

---

## 0. Step 4 verdict — empirical validation of (e) Slot_S gate

### 0.1 Headline

The Step 3 Session A (e) Slot_S parent-close gate per CodeWiki §3.16 is **empirically validated**:

| Slot | Step 2 baseline | Step 4 iter-1 post-patch | Reduction |
|---|---|---|---|
| **S/entry** (was top-1) | rewrite=6, legacy=0, \|Δ\|=6 | rewrite=**0**, legacy=0, \|Δ\|=**0** | **100%** ✅ |
| **All other top-10** | unchanged | unchanged | 0% |

The gate suppresses Slot_S entirely when L/K never close in the 70-bar lookback window — exactly what CodeWiki §3.16 prescribes ("Lookback 70 bars; require prior L/K closure ≥33 bars ago"). Q1 2021 has L=0/K=0 throughout in rewrite, so `m_last_lk_close_bar==0` → S suppressed → matches legacy Q1 S=0 convention.

### 0.2 Sum-of-|Δ| comparison (top-10 entries + exits)

| | Step 2 baseline | Step 4 iter-1 |
|---|---|---|
| Top-10 sum of \|Δ\| | 20 (S6+T3+G2+G2+T2+B1+B1+BR1+BR1+D1) | 15 (T3+G2+G2+T2+B1+B1+BR1+BR1+D1+D1) |
| Reduction | — | **−25%** |

### 0.3 S-AC #4 status: NOT YET MET (cap-3 iteration headroom)

S-AC #4 text: *"Step 4 re-canary post-patch divergence reduction ≥ 75% per-slot vs Step 2 baseline (Q1 trajectory matches legacy within ~10% on top-5 slots)."*

| Top-5 slot/event | Step 2 \|Δ\| | Step 4 iter-1 \|Δ\| | Per-slot reduction |
|---|---|---|---|
| S/entry | 6 | 0 | **100%** ✅ |
| T/entry | 3 | 3 | 0% |
| G/entry | 2 | 2 | 0% |
| G2/entry | 2 | 2 | 0% |
| T/exit | 2 | 2 | 0% |

**Average top-5 reduction: 20%** (1/5 met the ≥75% bar). S-AC #4 stays `[ ]` until Sessions B/C close G/G2/T eligibility predicates.

### 0.4 Final-balance trajectory (Net Profit per task-block decision gate)

Task-block § Step 4 decision gate: *"if Q1 trajectory matches legacy within ~10% per-slot count + ~10% Net Profit → proceed to Step 5; else iterate Steps 2-4."*

| Metric | Rewrite Step 1 | Rewrite Step 4 iter-1 | Legacy Step 1 | Step-4 vs legacy |
|---|---|---|---|---|
| Final balance | $1,774.64 | **$2,188.09** | $2,071.17 | **+5.6%** ✅ within ~10% |
| Entry count | 14 | 8 | 13 | -38% — NOT within ~10% |
| Wall-clock | 0:03:51 | 0:03:02 | 0:02:04 | rewrite still 1.46× legacy (less spam → faster) |

**Net Profit gate ✅ MET** (within ~10%); per-slot count gate ❌ NOT MET (need G/G2/T fixes). **Iterate Sessions B/C before Step 5 5-yr Bucket A retry.**

### 0.5 New top-1 divergence row (post-patch)

Slot_T/entry now top-1 at \|Δ\|=3 (rewrite=1 vs legacy=4). Rewrite hits only 1 of 4 legacy trigger varieties (T,MA,N,1,SL); legacy fires PF buy/sell + H buy/sell. Confirms Slot_T deferral to dedicated session (CodeWiki §3.15 Hull MA + Bollinger Band + SubDem zone + ADX-W dominance — ~400 LOC redesign + new MarketContext fields).

### 0.6 Recommended next session path

**Session B = G/G2/D eligibility patches** (artifact § 0.5 sequencing):
- G/entry +2 (rewrite-only) — `slots/Slot_G.mqh::Evaluate` F1-trigger predicate audit vs CodeWiki §3.G; banner cite IMPL-FIX-011 (e) hypothesis class
- G2/entry +2 (rewrite-only) — `slots/Slot_G2.mqh::Evaluate` should be silent when G silent (legacy convention); audit predicate gating
- D/entry -1 (legacy-only) — `slots/Slot_D.mqh::Evaluate` C-D force-pending wrapper not firing; audit `ForcePendingActionOrder` invocation chain

**Session B closes 6 of remaining top-10 |Δ|** (G/entry, G2/entry, D/entry, D/exit; possibly D effects on B/BR/H/K/M/P long-tail). After Session B, re-run Step 4 iter-2; if ≥75% sum-reduction across top-5 → close S-AC #4 and proceed to Step 5 5-yr Bucket A (operator-paired).

**Session C (dedicated, 4-8 hr) = Slot_T 4-sub-path redesign** (CodeWiki §3.15) — needs MarketContext extension first.

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
| 2021-01-08 20:00Z | 1 | 0 | +1 |

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

