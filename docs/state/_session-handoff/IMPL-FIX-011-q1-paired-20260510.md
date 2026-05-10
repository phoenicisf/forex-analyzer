# IMPL-FIX-011 Step 1 — Q1 2021 Paired Canary Artifact

**Date:** 2026-05-10
**Task:** IMPL-FIX-011 Step 1 (paired Q1 canary harness)
**Evidence kinds:** `[log-assertion]` + `[file-blob-check]`
**Status:** ✅ Step 1 S-AC #1 satisfied

---

## 1. Purpose

Produce paired baseline (rewrite vs legacy `PhoenicisN2.10_stable`) over Q1 2021
on identical data + Model + Deposit/Leverage so Step 2 journal-diff
(`simulation/scripts/journal_diff.py`) can identify divergence sources without
window/parameter confounders.

---

## 2. Harness

| File | Role | Window | Model | Deposit | Leverage |
|------|------|--------|-------|---------|----------|
| `simulation/headless-tests/q1_2021_paired_rewrite.ini` | Rewrite leg | 2021.01.01 → 2021.03.31 | 4 (real ticks) | $1000 | 1:500 |
| `simulation/headless-tests/q1_2021_paired_legacy.ini`  | Legacy leg  | 2021.01.01 → 2021.03.31 | 4 (real ticks) | $1000 | 1:500 |

Same broker history (FBS-Real Build 5833 EURUSD H4 ticks) — 5,500,180 ticks /
372 bars per leg (Tester reports identical tick count → strict comparability).

Existing `simulation/headless-tests/q1_2021_canary.ini` (IMPL-FIX-009 perf-profile
canary, Jan-only Model=0) preserved unchanged for FIX-009 reproducibility per
TD-02 §13.6.

---

## 3. Per-leg telemetry

| Metric | Rewrite | Legacy | Delta |
|---|---|---|---|
| Final balance (USD) | **1,774.64** | **2,071.17** | **−14.3%** |
| Wall-clock | 0:03:51.984 | 0:02:04.622 | rewrite +1.86× slower |
| Tester log size | **1,475,352,982 B (1.41 GB)** | **27,600 B (27 KB)** | rewrite **53,455× larger** |
| MT5 deals (broker-side) | 29 (incl. Tester end-of-test forced closes) | 27 | rewrite +7% |
| Strategy-side journal records | 18 (TradeJournal JSONL) | n/a — Print stream + native deal history only | — |
| Strategy-side opens (intentional) | 14 (entry events) | 8 (`OrderOpen:` Print) | rewrite +75% |
| Strategy-side closes (intentional, excl. end-of-test) | 4 | 8+ (`Close by …` Print) | rewrite −50%+ |
| Worst DD reported | (not surfaced in run header) | -1.86% (2021-03-04 18:30:54) | — |
| Memory used | 205 MB | 256 MB | comparable |

> Tester end-of-test position-close cascades (e.g., `position closed due end of test`)
> account for some of the broker-side deal delta — 13/29 (rewrite) vs ~7/27 (legacy).
> Strategy-side opens/closes (the columns above) are the IMPL-FIX-011 signal of interest.

### Rewrite journal histogram (`docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl`, 18 lines)

```
event_type:
  14 entry
   4 exit

slot_id (entry only):
   6 S    (33% of entries)
   2 T
   2 Q
   2 M
   2 G2
   2 G
   2 C
   0 D F H J K L LX I P R B BI BR GO   (14 slots silent in Q1)
```

### Legacy slot activity (parsed from `OrderOpen:` / `Close by` Print prefixes — same comment grammar `CommentParser` consumes in rewrite)

```
opens (8 distinct comment shapes, 8 deals):
   1 T T,PF,B,0.54,0
   1 T T,PF,A,0.28,0
   1 T T,H,B,0.61,0,V,1,108
   1 T T,H,A,0.27,0,V,1,145
   1 P PX,7,1,101,118,18
   1 K K,34,61,15,B,0.56,37.59
   1 BR BR,N,75,7
   1 B B,131,9.5,1,5,3,2,73

closes (8 distinct exit signals):
   2 Close by ExtraTakeProfit M NN
   2 Close by ExtraForceTakeProfit
   1 Close by ExtraTakeProfit H Ichi
   1 Close by ExtraTakeProfit B Break Price Action
   1 Close by Close T Top Band
   1 Close by Close T Bot Band
   1 Close by Close T Band invalid at start
   1 Close by Close P touch Ichi
   1 Close by Close BR Touch Ichi
```

### Slot-set divergence (entry side, Q1 2021)

| Slot family | Rewrite entries | Legacy opens | Note |
|---|---|---|---|
| S      | 6 | 0 | rewrite-only — S is post-L/K helper; should chain off L/K close, not fire alone |
| C      | 2 | 0 | rewrite-only |
| Q      | 2 | 0 | rewrite-only |
| M      | 2 | 0 (only closes M) | rewrite-only entry; legacy used M for exit-side ExtraTakeProfit |
| G/G2   | 4 | 0 | rewrite-only — G2 was the run #3 day-1 cascade slot |
| T      | 2 | 4 | overlap — rewrite under-fires (½ count) |
| P      | 0 | 1 | legacy-only entry |
| K      | 0 | 1 | legacy-only entry |
| BR     | 0 | 1 | legacy-only entry |
| B      | 0 | 1 | legacy-only entry |
| H      | 0 | 0 entry / 1 close | both silent on entry side; legacy closes show H is active in chains |

**Headline:** the rewrite Q1 mix and the legacy Q1 mix are nearly disjoint — only `T` overlaps, and rewrite under-fires it. The rewrite is firing slots legacy doesn't (S, C, Q, G, G2) and not firing slots legacy does (P, K, BR, B). This is bigger than per-slot anti-pyramid count drift; the slot **eligibility predicates** themselves diverge.

---

## 4. Tester-log spam (rewrite leg)

**1.41 GB tester log over Q1 (~6 GB / yr → ~30 GB / 5-yr extrapolation).**

Event-type histogram sampled at 5 positions across the run delta (each window = 1 MB at offset N MB; values are *event-line counts within that 1 MB sample*):

| Sample offset | Top events |
|---|---|
| +5 MB   | 26 `entry_sell` |
| +50 MB  | 2,635 `entry_sell` |
| +200 MB | 2,188 `entry_buy` + 365 `entry_signal` + 1 `entry_sell` |
| +500 MB | 1,171 `entry_signal` + 1,170 `entry_sell` |
| +1000 MB | 2,106 `entry_signal` |
| +1300 MB | 2,106 `entry_signal` |

**Empirical confirmation of IMPL-FIX-011 hypothesis (d):** `entry_signal` /
`entry_buy` / `entry_sell` Print emits fire per-tick when conditions persist
(IMPL-FIX-008 R-10 stub-suppress targeted only `exit_profit_gate`; `entry_*`
emits left ungated). Density ~2,000/MB matches the R-13 narrative's
"12,631 events / 5MB sample" prediction.

**FIX-010 latch verified working:** tail of run shows `eoverload_triggered` emit
cadence ~3-12 events / sim-min (before FIX-010 it was per-tick ≈ ~50/sec). The
remaining cadence reflects WPR oscillation around the 90 threshold — predicate
true→false→true transitions correctly reset/re-fire latch (~18× spam reduction
vs pre-FIX-010, matches latch design).

---

## 5. Headline findings going into Step 2

1. **Rewrite under-trades vs legacy in Q1** — 14 strategy-side opens vs legacy's 8,
   but with a wildly different slot mix (S/C/Q/G/G2 instead of P/K/BR/B/T-rich).
   Final balance −14% suggests the rewrite *can* trade profitably on this window
   but is firing the **wrong** slots.
2. **Slot eligibility predicates appear miscalibrated, not just anti-pyramid gates** —
   only T overlaps between the two slot mixes; the rewrite fires entire slot
   families legacy ignores in this window (S, G/G2, C, Q) and is silent on
   legacy's actives (P, K, BR, B). Hypothesis (a) "missing anti-pyramid gates"
   alone cannot explain a disjoint slot set; per-slot eligibility predicate
   divergence is more likely the dominant class.
3. **Hypothesis (d) per-tick `entry_*` Print spam confirmed** — 1.41 GB log /
   Q1 = ~30 GB / 5-yr. Operator-feasibility for Step 5 5-yr Bucket A retry is
   gated on suppressing this — at 30 GB the disk + iconv decode budget breaks
   the journal-diff pipeline. Bulk-suppress sweep mirroring IMPL-FIX-008 R-10
   pattern is now mandatory before Step 5 (escalates Step 3 scope by ~21 slot
   files: each emits `entry_buy`/`entry_sell` per their own Evaluate-time gate).
4. **Hypothesis (b) xslot helpers (RunSafePort/RunOrderGroup2/RunForceCutloss/ExtraCheckFunction2)** —
   Q1 sample didn't surface per-tick spam from those four helpers (R-12 closure
   "deferred until proven needed" still holds for Q1 evidence; defer until 5-yr
   evidence proves otherwise).
5. **Hypothesis (c) CD-pool demote** — `cd_demote_triggered` not visible in
   sampled MB windows (entry-* events drowned all xslot signals); will surface
   in journal-diff once entry-* spam is suppressed (Step 3 hypothesis (d) work
   must precede CD-pool analysis).
6. **Worst DD legacy = -1.86% on 2021-03-04** — small DD; legacy strategy stable
   through Q1. Rewrite Worst DD not surfaced in tail (would need full log scan;
   inferred small from $1,774 final balance with no halt event).

---

## 6. Step 2 entry conditions

✅ Both Q1 journal/log artifacts captured + comparable.
✅ Rewrite slot mix + entry count documented.
✅ Legacy slot mix + entry count documented.
✅ Top divergence axis identified (slot-set disjoint, not pyramid count).
✅ Spam class (d) `entry_*` Print emit) empirically confirmed.

**Next session ready for Step 2:** author `simulation/scripts/journal_diff.py`
(Python stdlib jsonl reader + Tester-log Print parser); group rewrite JSONL by
`(slot_id, event_type, h4_bucket)` AND legacy Print stream by same key (use
existing rewrite `helpers/CommentParser.mqh` grammar — slot-id is the comment
prefix before the first comma). Output divergence ranking + hypothesis (a/b/c/d)
classification per top-5 source.

---

## 7. Artifacts

| Path | Size | Note |
|---|---|---|
| `simulation/headless-tests/q1_2021_paired_rewrite.ini` | 0.9 KB | committed harness |
| `simulation/headless-tests/q1_2021_paired_legacy.ini` | 1.0 KB | committed harness |
| `docs/state/_session-handoff/IMPL-FIX-011-q1_rewrite_202605102037.jsonl` | 11.7 KB | 18 strategy-side records (TradeJournal) |
| `docs/state/_session-handoff/IMPL-FIX-011-q1_legacy_202605102037.txt` | 27 KB | decoded UTF-8 tester log |
| (live) Tester Agent's `MQL5/Files/PhoenicisNex/journal/tester/run-20210101-000000-081.jsonl` | 11.7 KB | original rewrite journal pre-rename |
| (rotated) Tester log delta for rewrite leg | 1.41 GB | NOT preserved — Tester rotated 20260510.log when legacy run launched (truncate-on-open behavior); rewrite tail+spam summaries already extracted into this artifact in §3-§4 |

---

## 8. Step 1 closure

- ✅ S-AC #1 satisfied: `_session-handoff/IMPL-FIX-011-q1-paired-20260510.md`
  with both rewrite + legacy journal/log paths + per-file
  `(record_count, final_balance, sim_window, wall_clock)` table
  `[log-assertion]` + `[file-blob-check]`.
- ⏸ S-AC #2-#6 + E-ACs remain `[ ]` pending Steps 2-5 execution (separate
  sessions).
- 🔍 **Scope-revision flag for Step 2:** the disjoint slot-set finding may
  require a 5th hypothesis class (e) "per-slot eligibility-predicate divergence"
  beyond the (a)/(b)/(c)/(d) ranking from the impl-plan task block. Step 2
  journal-diff should explicitly surface eligibility-predicate hits per slot
  per H4 bar so the misclassification doesn't propagate into Step 3 patches.
