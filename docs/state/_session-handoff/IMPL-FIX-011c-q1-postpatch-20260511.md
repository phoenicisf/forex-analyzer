# IMPL-FIX-011 Step 2 — Q1 2021 Paired Journal Diff

**Generated:** 2026-05-11T08:01:08+00:00
**Script:** `simulation/scripts/journal_diff.py`
**Inputs:**
- Rewrite: `docs\state\_session-handoff\IMPL-FIX-011c-q1_rewrite_postpatch_202605111501.jsonl` (6 events)
- Legacy:  `docs\state\_session-handoff\IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events)

## 1. Per-leg telemetry

| Metric | Rewrite | Legacy |
|---|---|---|
| Total events | 6 | 24 |
| Entry events | 5 | 13 |
| Exit events | 1 | 11 |
| Unresolved slot_id | 0 | 0 |

### 1a. Entry slot mix (per leg)

| Slot | Rewrite entries | Legacy entries |
|---|---:|---:|
| `B` | 0 | 1 | 🟦 legacy-only |
| `BR` | 0 | 1 | 🟦 legacy-only |
| `C` | 1 | 1 | |
| `D` | 0 | 1 | 🟦 legacy-only |
| `G` | 1 | 0 | 🟥 rewrite-only |
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
| 2 | `T` | exit | 0 | 3 | -3 | 3 | 0 | 3 | 0 | 1 | **(e) eligibility** | legacy-only — fires 3 entries while rewrite is silent |
| 3 | `M` | exit | 0 | 2 | -2 | 2 | 0 | 2 | 0 | 1 | **(e) eligibility** | legacy-only — fires 2 entries while rewrite is silent |
| 4 | `B` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 5 | `B` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 6 | `BR` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 7 | `BR` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 8 | `D` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 9 | `D` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 10 | `G` | entry | 1 | 0 | +1 | 1 | 1 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 1 entries in 1 H4 buckets while legacy is silent |

## 3. H4-bucket drilldown — top-3 divergence slots (entries only)

### Slot `T` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-06 00:00Z | 1 | 1 | +0 |
| 2021-01-19 00:00Z | 0 | 1 | -1 |
| 2021-02-26 04:00Z | 0 | 1 | -1 |
| 2021-03-30 08:00Z | 0 | 1 | -1 |

### Slot `B` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-03-04 08:00Z | 0 | 1 | -1 |

### Slot `BR` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-03-10 08:00Z | 0 | 1 | -1 |

## 4. Hypothesis classification rollup (top-10 divergence)

| Hypothesis | Top-10 rows | Slots/events |
|---|---:|---|
| (e) eligibility | 10 | T/entry (|Δ|=3), T/exit (|Δ|=3), M/exit (|Δ|=2), B/entry (|Δ|=1), B/exit (|Δ|=1), BR/entry (|Δ|=1) |

## 5. IMPL-FIX-011 decision gate (per task-block Step 2 §)

Distinct entry slots with |Δ| ≥ 1: **10** — `B, BR, D, G, H, K, M, P, Q, T`

**Verdict — dispersed (escalate):** divergence spans 10+ slots → escalate scope estimate to upper bound per task-block (8 hr / 3 sessions). Step 3 patches must be batched + tested incrementally to avoid regressions.

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

