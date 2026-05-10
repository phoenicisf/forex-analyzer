# IMPL-FIX-011 Step 2 — Q1 2021 Paired Journal Diff

**Generated:** 2026-05-10T14:00:11+00:00
**Script:** `simulation/scripts/journal_diff.py` (Python stdlib only; reproducible)
**Inputs:**
- Rewrite: `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl` (18 events / 14 entry / 4 exit)
- Legacy:  `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` (24 events / 13 entry / 11 exit)

**Step 1 entry conditions:** ✅ all met — see `_session-handoff/IMPL-FIX-011-q1-paired-20260510.md` § 6.
**S-AC closed by this artifact:** Step 2 journal-diff script + divergence ranking + hypothesis classification per IMPL-FIX-011 task block (line 1728 `[contract-roundtrip]` evidence kind).

---

## 0. Engineer synthesis & Step 3 sequencing (read first)

### 0.1 Headline (corroborates Step 1 § 6)

The Q1 2021 paired canary diff confirms **hypothesis (e) per-slot eligibility-predicate
divergence is the dominant axis** — 10/10 of the top-10 ranked divergence rows classify
as (e), zero classify as (a) anti-pyramid. **No slot has `max_intra_bucket_rewrite ≥ 2`
(see § 2 columns)** — meaning no slot multi-fills inside a single H4 bar in the rewrite
output. The Step 1 R-13 narrative's hypothesis (a) (anti-pyramid latches missing) is
EMPIRICALLY FALSIFIED for Q1 2021 — the rewrite trades infrequently within bars but
fires the wrong slots vs legacy.

### 0.2 Top-5 ranked divergence sources (S-AC requirement)

| Rank | Slot | Event | Δ (rw−lg) | Class | Step 3 action |
|---:|---|---|---:|---|---|
| 1 | `S` | entry | +6 | **(e) rewrite-only** | Inspect `slots/Slot_S.mqh::Evaluate` — S is a post-L/K helper per CodeWiki §3 + Step 1 § 3 note; should chain off L/K close events. Q1 has 0 L/K closes in rewrite (L/K never enter), so S firing alone is the bug — likely the S eligibility predicate doesn't gate on parent state. |
| 2 | `T` | entry | −3 | **(e) rewrite under-fires** | Both legs active but rewrite fires 1 vs legacy 4. Inspect `slots/Slot_T.mqh::Evaluate` — likely a predicate threshold/comparison miscompiled (e.g., RSI/MACD direction, top-band condition); legacy comment shapes show 4 distinct trigger varieties (`T,PF,B,...` `T,PF,A,...` `T,H,B,...` `T,H,A,...`) — rewrite hits only 1 ("T,MA,N,1,SL"). |
| 3 | `G` | entry | +2 | **(e) rewrite-only** | `slots/Slot_G.mqh::Evaluate` — G is the run #3 day-1 cascade slot. Q1 fires 2 G entries that legacy doesn't. Likely the G F1-trigger predicate is too permissive vs legacy's CodeWiki §3.x F1 conditions. |
| 4 | `G2` | entry | +2 | **(e) rewrite-only** | `slots/Slot_G2.mqh::Evaluate` — G2 was IMPL-FIX-007 v2's anti-pyramid scope, but that fix added the pyramid latch only — it did not adjust the **eligibility** predicate. G2 should not fire when G is silent (legacy convention). Predicate likely too loose. |
| 5 | `T` | exit | −2 | **(e) rewrite under-exits** | Companion to row 2 — fewer T entries → fewer T exits. Likely root-causes resolve together with row 2's predicate fix. |

> Top-10 + per-H4-bucket drilldown for top-3 entry slots: see § 2 + § 3 (auto-generated).

### 0.3 Decision gate (per IMPL-FIX-011 task-block Step 2)

**12 distinct entry slots show |Δ| ≥ 1** (B, BR, D, G, G2, H, K, M, P, Q, S, T). Per
the task-block decision gate: *"if dispersed across 8+ slots → escalate scope estimate
to upper bound (8 hr, 3 sessions)."* — **VERDICT: dispersed (escalate)**.

> 9 of 21 active slots are silent on BOTH legs in Q1 2021 (F, J, GO, L, LX, R, I, BI, plus
> the never-active in Q1 ones) — those don't contribute to scope. The 12 diverging slots
> are the actual Step 3 patching surface.

### 0.4 Hypothesis classification breakdown (IMPL-FIX-011 task-block axes)

| Hypothesis | Signal in Q1 diff | Step 3 disposition |
|---|---|---|
| **(a) per-slot anti-pyramid H4-bar gate** | **FALSIFIED for Q1** — `max_intra_bucket_rewrite` ≤ 1 for every slot/event in top-10 (no multi-fill inside any H4 bar). Legacy bursts (e.g., 0.06 + 0.06 EURUSD on 2021.01.18-19 in same direction = legacy ALSO multi-fills across H4 bars — that's not anti-pyramid drift). | **Defer** — keep IMPL-FIX-007 v2 / IMPL-FIX-008 latches as-is for G/G2/S; do NOT bulk-add latches to remaining 18 slots based on Q1 evidence (would suppress legitimate trades). Re-evaluate at Step 5 5-yr Bucket A if a slot shows max-intra-bucket > 2. |
| **(b) xslot helper one-shot trigger latches** | **Not detectable in this diff** — RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2 emit Logger.Info, not TradeJournal records. Q1 1.41 GB log was not grep-sampled for these helpers. | **Defer** to Step 5 5-yr Bucket A as task-block already specifies ("apply only if surfaces"). Step 1 § 5 note: did NOT surface in Bucket A run #3 5-MB head sample. |
| **(c) CD-pool demote miscalibrated** | **Not detectable** — `cd_demote_triggered` is Logger.Info Print, not journal record. Note: Slot D has 1 legacy entry / 0 rewrite entry (row 10) — the *demote* path is the WRITE-side effect of the CD-pool predicate, but the entry-side D fire is what we observe here. The D miss is more likely a generic eligibility-predicate divergence (class (e)), not a demote-cadence miscalibration (class (c)). | **Defer** — folded into (e) class if Step 3 D predicate fix doesn't restore parity, then revisit (c) at iteration 2. |
| **(d) `entry_*` per-tick Print spam** | **Confirmed empirically** at Step 1 § 4 (1.41 GB / Q1). Orthogonal to journal records — not visible in this diff. | **Mandatory in Step 3** — bulk-suppress sweep BEFORE Step 5 (5-yr would emit ~30 GB log; iconv decode would break). Mirror IMPL-FIX-008 R-10 stub-suppress pattern. |
| **(e) per-slot eligibility-predicate divergence** | **CONFIRMED — 10/10 top-10 rows classify as (e)**. Dominant axis. | **Primary Step 3 surface** — see § 0.5 sequencing. |

### 0.5 Step 3 patch sequencing (proposed)

> Multi-session work; ranking by leverage (slots with biggest |Δ| × clearest CodeWiki spec
> reference go first to validate the methodology before patching the long tail).

**Session A (~60-90 min) — high-leverage patches + (d) spam suppression**

1. **(d) bulk-suppress `entry_*` Prints** across all 21 slots (mirror IMPL-FIX-008 R-10 pattern: 4-line banner cite + `// IMPL-FIX-011 (d) — emit cadence align legacy per-bar-per-direction`). REQUIRED before any Step 4 re-canary because the rewrite log otherwise breaks the diff pipeline at 5-yr scale. ~21 file edits, each ≤ 4 LOC. G1 incremental per cluster of 5 slots.
2. **(e) Slot S eligibility** (rank 1, |Δ|=6) — `slots/Slot_S.mqh::Evaluate` — gate on parent L/K close event presence (legacy convention; verify against CodeWiki §3.S spec). Banner: `// IMPL-FIX-011 R-13 hypothesis (e) — Slot S parent-close gate per CodeWiki §3.S`.
3. **(e) Slot T eligibility** (rank 2, |Δ|=3) — `slots/Slot_T.mqh::Evaluate` — diff legacy comment varieties (`T,PF,B`, `T,PF,A`, `T,H,B`, `T,H,A`) vs rewrite (`T,MA,N,1,SL`); rewrite is missing PF (PriceFractal) + H (Hull) sub-paths. Spec source: `PhoenicisN2.10_stable.mq5` `BusinessLogic_T` body.

**Session B (~60-90 min) — G/G2 + Slot D**

4. **(e) Slot G eligibility** (rank 3, |Δ|=2) — `slots/Slot_G.mqh::Evaluate` — F1-trigger predicate audit vs CodeWiki §3.G.
5. **(e) Slot G2 eligibility** (rank 4, |Δ|=2) — `slots/Slot_G2.mqh::Evaluate` — G2 should be silent when G silent (per legacy convention); audit predicate gating.
6. **(e) Slot D eligibility** (rank 10, |Δ|=1) — `slots/Slot_D.mqh::Evaluate` — D is force-pending wrapper of C; legacy fires 1 D entry when rewrite is silent. Audit `ForcePendingActionOrder` invocation chain.

**Session C (~60-90 min) — long-tail eligibility + Step 4 re-canary**

7. **(e) Slots B/BR/H/K/M/P + others as needed** — apply same predicate-audit pattern; lower-priority because |Δ|=1 each. Some may auto-resolve once C/D chain (item 6) restores CD-pool flow.
8. **Step 4 — re-canary Q1 paired diff** (~30 min) — re-run journal_diff against the patched rewrite vs the same legacy artifact (legacy doesn't change). Decision gate: divergence reduction ≥ 75% per-slot to proceed to Step 5; else iterate.

### 0.6 Risk callouts for Step 3

- **R-A: false-positive eligibility fixes** — if engineer mis-reads a CodeWiki spec and tightens an eligibility predicate that was correctly loose in legacy, Step 4 re-canary will show worse divergence (rewrite goes silent on a slot legacy fires). Mitigation: Step 3 ALWAYS cite CodeWiki §X.Y in banner; Step 4 re-canary BEFORE the next session ends so misclassifications surface fast.
- **R-B: scope creep** — 12 diverging slots × ~30 LOC each ≈ 360 LOC of edits across slots/. ADR-002 (Composition Root) + ADR-005 (PortfolioState CHashMap) MUST stay invariant. Per-slot edit cluster ≤ 30 LOC absent justification (per S-AC #3).
- **R-C: under-coverage at Step 5 5-yr Bucket A** — Q1 2021 only sampled 7 of 21 slots in rewrite (S/C/Q/G/G2/M/T) + 9 of 21 in legacy (T/D/M/K/C/H/B/BR/P). Slots silent in both Q1 legs (F/J/GO/L/LX/R/I/BI) may surface eligibility drift only at 5-yr scale; Step 5 may discover NEW divergence sources requiring Step 3 iteration 2. Budget the +1 session contingency.

---

## 1. Per-leg telemetry

| Metric | Rewrite | Legacy |
|---|---|---|
| Total events | 18 | 24 |
| Entry events | 14 | 13 |
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
| `S` | 6 | 0 | 🟥 rewrite-only |
| `T` | 1 | 4 | ⚠️ count drift |

## 2. Per-(slot, event) divergence ranking — top 10

| Rank | Slot | Event | Rewrite | Legacy | Δ | \|Δ\| | RW buckets | LG buckets | Max RW/H4 | Max LG/H4 | Hypothesis | Rationale |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `S` | entry | 6 | 0 | +6 | 6 | 6 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 6 entries in 6 H4 buckets while legacy is silent |
| 2 | `T` | entry | 1 | 4 | -3 | 3 | 1 | 4 | 1 | 1 | **(e) eligibility** | both legs active but count drift |delta|=3 (rewrite=1 vs legacy=4) |
| 3 | `G` | entry | 2 | 0 | +2 | 2 | 2 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 2 entries in 2 H4 buckets while legacy is silent |
| 4 | `G2` | entry | 2 | 0 | +2 | 2 | 2 | 0 | 1 | 0 | **(e) eligibility** | rewrite-only — fires 2 entries in 2 H4 buckets while legacy is silent |
| 5 | `T` | exit | 1 | 3 | -2 | 2 | 1 | 3 | 1 | 1 | **(e) eligibility** | both legs active but count drift |delta|=2 (rewrite=1 vs legacy=3) |
| 6 | `B` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 7 | `B` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 8 | `BR` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 9 | `BR` | exit | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |
| 10 | `D` | entry | 0 | 1 | -1 | 1 | 0 | 1 | 0 | 1 | **(e) eligibility** | legacy-only — fires 1 entries while rewrite is silent |

## 3. H4-bucket drilldown — top-3 divergence slots (entries only)

### Slot `S` — entry events per H4 bucket

| H4 bucket (UTC) | Rewrite count | Legacy count | Δ |
|---|---:|---:|---:|
| 2021-01-07 08:00Z | 1 | 0 | +1 |
| 2021-01-08 08:00Z | 1 | 0 | +1 |
| 2021-01-11 12:00Z | 1 | 0 | +1 |
| 2021-01-15 16:00Z | 1 | 0 | +1 |
| 2021-03-10 12:00Z | 1 | 0 | +1 |
| 2021-03-11 08:00Z | 1 | 0 | +1 |

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

## 4. Hypothesis classification rollup (top-10 divergence)

| Hypothesis | Top-10 rows | Slots/events |
|---|---:|---|
| (e) eligibility | 10 | S/entry (|Δ|=6), T/entry (|Δ|=3), G/entry (|Δ|=2), G2/entry (|Δ|=2), T/exit (|Δ|=2), B/entry (|Δ|=1) |

## 5. IMPL-FIX-011 decision gate (per task-block Step 2 §)

Distinct entry slots with |Δ| ≥ 1: **12** — `B, BR, D, G, G2, H, K, M, P, Q, S, T`

**Verdict — dispersed (escalate):** divergence spans 12+ slots → escalate scope estimate to upper bound per task-block (8 hr / 3 sessions). Step 3 patches must be batched + tested incrementally to avoid regressions.

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

