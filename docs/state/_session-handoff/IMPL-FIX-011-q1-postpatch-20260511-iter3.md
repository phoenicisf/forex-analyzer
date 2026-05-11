# IMPL-FIX-011 Step 4 iter-3 — Q1 2021 Paired Journal Diff (post-Session-C)

## § 0. Verdict synthesis (engineer-authored, prepended 2026-05-11)

**Outcome:** S-AC #4 (≥75% top-5 |Δ| reduction vs Step 2 baseline) **NOT MET.**

| Metric | Step 2 baseline | iter-1 (Session A) | iter-2 (Session B) | iter-3 (Session C) |
|---|---|---|---|---|
| Top-5 \|Δ\| sum | 15 | 15 (S→0, T=3, G=2, G2=2, T_exit=2) | 15 (no change — Session B falsified) | **10** (S=0 ✅, T=3, T_exit=3, G2=2, B=1, B_exit=1) |
| % reduction vs Step 2 | 0% | 33% | 33% | **33%** (still NOT MET ≥75% gate) |
| Final balance (USD) | n/a | $2,188.09 (+5.6% vs legacy) | $1,691.69 (-18.3%) | **$1,659.93 (-19.9% vs legacy $2,071.17)** |
| Net Profit ±10% gate | n/a | ✅ MET | ❌ FAIL | ❌ FAIL |
| Wall-clock | n/a | 0:03:02 | 0:03:51 | **0:02:20** (-39% vs iter-2; tester ticks 5.5M / 372 bars) |
| Entries (count) | n/a | 14 (S×6, G×2, G2×2, C×1, M×1, T×1, Q×1) | 12 (C×1, M×1, T×1, Q×1, G2×2, G×2) | **7** (C×1, M×1, T×1, Q×1, G2×2, G×1) |
| Distinct \|Δ\|≥1 slots | 12 | 12 | 12 | **11** (B/BR/D/G/G2/H/K/M/P/Q/T — S dropped ✅) |

**Session C predicate effectiveness (per slot, iter-3 vs Step 2 baseline):**

| Slot/event | Step 2 |Δ| | iter-3 |Δ| | Δ reduction | Session C predicate verdict |
|---|---|---|---|---|
| S/entry | 6 | **0** ✅ | 100% | Session A `_BothParentsInactive` gate per §3.16 **EMPIRICALLY VALIDATED** (still effective iter-3) |
| T/entry | 3 | 3 ❌ | 0% | Session C `Slot_T` 4-sub-path rewrite per §3.15 **FAILED to align with legacy 4 trigger varieties** — rewrite fires 1 at 2021-03-11 08:00Z (legacy silent), legacy fires 4 at 01-06/01-19/02-26/03-30 (rewrite silent). Predicate calibration miss: zone+BB%, Hull dominance, BBTop<IchiMax, ADX dominance, DEM-D/H sub-paths — at least one branch threshold misaligned vs legacy CodeWiki §3.15 spec |
| G/entry | 2 | 1 ⚠️ | 50% | Session C §3.6:9 _IsForcePeaksNotExhausted + §3.6:11 _BBTopBelowIchiMaxCount + §3.6:12 _IsDemRollingBuyOk/SellOk **PARTIAL** — suppressed 2021-01-14 16:00Z but new rewrite-only fire at 2021-03-30 08:00Z emerged (different bucket — predicate too permissive at month boundary OR DEM rolling threshold off) |
| G2/entry | 2 | 2 ❌ | 0% | Session C §3.7:5 _IsAdxNotTrapped + §3.7:6 5-of-8 + §3.7:9 1-of-[2,5) reversal trough **FAILED** — both 2021-01-04 16:00Z + new 2021-01-15 08:00Z (shifted from iter-2's 2021-01-12) fire while legacy silent. Either history-buffer windows wrong (8-bar Force, 25-bar DEM) OR threshold gates (peak_count_above11≤3, adxw_no_trap_bars_1_3==1) too lenient vs legacy CodeWiki §3.7 spec |
| T/exit | 2 | 3 ❌ | -50% (worse) | T/entry under-fire cascades to T/exit under-fire (no entries → no companion exits); legacy fires 3 exits at companion buckets, rewrite silent — same root cause as T/entry |

**cap-3 hit (per task-block Step 4 Decision gate):** "cap at 3 iterations per session; defer continuation to next session if cap hit." → **DEFER to next session.**

**Root cause analysis (iter-3 specific):**

1. **Slot_T 4-sub-path predicates DO NOT align with legacy CodeWiki §3.15:1-9 thresholds** — rewrite fires 1× at 2021-03-11 08:00Z which legacy doesn't; legacy fires 4× at distinct buckets (01-06/01-19/02-26/03-30) rewrite doesn't. Suggests:
   - (i) BollBandPct gates (Buy=5, Sell=95) may be too narrow OR direction-inverted vs legacy
   - (ii) DEM-D/H sub-path resolution at trigger time may be hitting different branch than legacy
   - (iii) BBHist `MinAboveCount=7` (of 10 bars) may be too strict — legacy may use simpler `MaxLookback` window
   - (iv) Hull dominance gate (`hull[1] > hull[2]` for BUY) may be backward
   - (v) PMR PM_T Phase A/B may have stale state at H4 bar boundary

2. **Slot_G2 history predicates DO NOT align with legacy §3.7:5/6/9** — both rewrite-only fires (2021-01-04 16:00Z + 2021-01-15 08:00Z) bucket-shifted vs iter-2 (was 2021-01-08+2021-01-12) confirming the new history buffer is shifting but not aligning with legacy gate. Suggests:
   - (i) Force 8-bar buffer `peak_count_above11` may use wrong index range (legacy may count peaks at [1..6] not [0..7])
   - (ii) `5-of-8` Force count window (§3.7:6) may be inverted — legacy may require ≤5 not ≥5 of Force above 0.2
   - (iii) `adxw_no_trap_bars_1_3==1` ADX-history exact-match may be too strict vs legacy's `>=1` count
   - (iv) `1-of-[2,5)` Force trough scan may use wrong direction sign (BUY vs SELL flipped)

3. **Slot_G partial improvement (2→1)** suggests at least one of §3.6:9/11/12 predicates is correctly aligned for January fires but DEM rolling sum or Force peak count is misaligned for March (different volatility regime exposes different threshold band).

4. **(d) entry_*` Print bulk-suppress (Session A) STILL EFFECTIVE** — tester log 237 KB vs iter-1 1.41 GB confirms log-volume defect remains closed.

5. **Net Profit deviation -19.9% vs legacy** — outside ±10% gate. Direction: rewrite under-fires (7 entries vs legacy 13 entries → under-exposure → under-profit). Trade quality similar (no day-1 cascade; reached end-of-Q1 cleanly; positions closed at end-of-test at modest losses).

**Recommended next session decomposition (next operator session):**

Option A — **Targeted predicate calibration** (~4-8 hr): single-slot deep dive on each of {T, G2, G} → instrument predicate evaluation with per-bar Logger.Debug emit → compare rewrite predicate value vs legacy `PhoenicisN2.10_stable.mq5` source-level decode at the SAME 5-10 H4 buckets where divergence occurs (e.g., 2021-01-04 16:00Z, 2021-01-06 00:00Z, 2021-01-15 08:00Z) → adjust thresholds/indices/sign to match legacy → iter-4 re-canary. **Risk:** session-scoped cap reset; may need 2-3 sessions per slot.

Option B — **Escalate via `/impl-plan-review all`** (Plan QA loop): re-validate whether IMPL-FIX-011 task decomposition + AC dual-track is still appropriate given 3 iterations of empirical falsification. May surface that the AC #4 75% gate is unrealistic for Phase 1 single-pass predicate translation; may suggest splitting IMPL-FIX-011 into per-slot fix tickets (IMPL-FIX-011a Slot_T / IMPL-FIX-011b Slot_G2 / IMPL-FIX-011c Slot_G) with separate iteration budgets.

Option C — **Escalate via `/backtrack sd`**: if root cause is architectural impedance (legacy global-state lookup pattern fundamentally differs from rewrite CHashMap dispatch → predicate semantics cannot translate 1:1), backtrack to add ADR-013 documenting the gap + revise CodeWiki §3 source-of-truth contract. **Risk callout from task-block § 1763 explicitly flags this as worst-case last-resort.**

**Engineer recommendation (this session, given cap-3 hit + auto mode):** Defer to next operator session with Option A as the leading hypothesis. Document iter-3 evidence + 5 specific 2021 H4 buckets where each predicate diverges + propose targeted Logger.Debug instrumentation strategy for next session. Do NOT escalate to /impl-plan-review or /backtrack without operator review of this verdict first — both have higher cost than a focused predicate-tuning session.

**S-AC #4 disposition:** remains `[ ]` (NOT MET); iter-3 evidence recorded per task-block 5-step Decision gate. Cap-3 per-session iteration budget exhausted this session.

**Artifacts:**
- `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_postpatch_202605110933.jsonl` (NEW; 6536 bytes; 10 records — 7 entry / 3 exit)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter3.md` (NEW; this file)
- `docs/state/_session-handoff/IMPL-FIX-011-q1-postpatch-20260511-iter3.json` (NEW; sidecar)
- `/tmp/iter3_rewrite.txt` (decoded tester log, 237 KB) — final balance line: `Tester	final balance 1659.93 USD`

---

# IMPL-FIX-011 Step 2 — Q1 2021 Paired Journal Diff (auto-generated below)

**Generated:** 2026-05-11T02:34:31+00:00
**Script:** `simulation/scripts/journal_diff.py`
**Inputs:**
- Rewrite: `docs\state\_session-handoff\IMPL-FIX-011-q1_rewrite_postpatch_202605110933.jsonl` (10 events)
- Legacy:  `docs\state\_session-handoff\IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events)

## 1. Per-leg telemetry

| Metric | Rewrite | Legacy |
|---|---|---|
| Total events | 10 | 24 |
| Entry events | 7 | 13 |
| Exit events | 3 | 11 |
| Unresolved slot_id | 0 | 0 |

### 1a. Entry slot mix (per leg)

| Slot | Rewrite entries | Legacy entries |
|---|---:|---:|
| `B` | 0 | 1 | 🟦 legacy-only |
| `BR` | 0 | 1 | 🟦 legacy-only |
| `C` | 1 | 1 | |
| `D` | 0 | 1 | 🟦 legacy-only |
| `G` | 1 | 0 | 🟥 rewrite-only |
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
| 2 | `T` | exit | 0 | 3 | -3 | 3 | 0 | 3 | 0 | 1 | **(e) eligibility** | legacy-only — fires 3 entries while rewrite is silent |
| 3 | `G2` | entry | 2 | 0 | +2 | 2 | 2 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 2 entries in 2 H4 buckets while legacy is silent |
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
| 2021-01-06 00:00Z | 0 | 1 | -1 |
| 2021-01-19 00:00Z | 0 | 1 | -1 |
| 2021-02-26 04:00Z | 0 | 1 | -1 |
| 2021-03-11 08:00Z | 1 | 0 | +1 |
| 2021-03-30 08:00Z | 0 | 1 | -1 |

### Slot `G2` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-04 16:00Z | 1 | 0 | +1 |
| 2021-01-15 08:00Z | 1 | 0 | +1 |

### Slot `B` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-03-04 08:00Z | 0 | 1 | -1 |

## 4. Hypothesis classification rollup (top-10 divergence)

| Hypothesis | Top-10 rows | Slots/events |
|---|---:|---|
| (e) eligibility | 10 | T/entry (|Δ|=3), T/exit (|Δ|=3), G2/entry (|Δ|=2), B/entry (|Δ|=1), B/exit (|Δ|=1), BR/entry (|Δ|=1) |

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

