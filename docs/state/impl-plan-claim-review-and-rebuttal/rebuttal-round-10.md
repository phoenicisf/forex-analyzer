# Implementation Plan Rebuttal Round 10

| Field | Value |
|-------|-------|
| **Round** | 10 |
| **Claim Review** | `claim-review-10.md` |
| **Date** | 2026-05-13 |
| **SKILLs** | andm-impl-plan-defender, code-review |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 5 |
| Partial | 1 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` — (a) `## Plan Staleness Sentinel` block rewritten (R09 chain, FIX-ticket counter rule); (b) `replace_all` 51 instances of contradictory Sentinel boilerplate ("0 IMPL-NNN closures since R25" → "0 IMPL-NNN closures since R09 (impl-plan-review chain; FIX-ticket closures ไม่ increment counter)"); (c) `## Phase Status Snapshot` P4 row Notes column appended R10 pivot; (d) `## Open Risks` R-3 strikethrough + R-3 contract re-baseline pivot; (e) R-8 strikethrough + Resolved note; (f) R-13 mitigation rewrite (sub-tickets a/b/c/d + Phase 1B closure narrative); (g) `## Next Best Action` Option A/B/C strikethrough + new top-level `/backtrack ba` decision; (h) `### Phase Gate § Empirical Demo` BLOCKED annotation; (i) NFR-1.1 check row BLOCKED annotation; (j) `### IMPL-FIX-011` parent block 4× E-AC footnote SUPERSEDED annotation; (k) `### IMPL-062` task block new Status entry BLOCKED 2026-05-12; (l) TL;DR top reader-empathy note (R10 §10.6 Partial); (m) new `## Closure Hygiene Status` 3-line block; (n) TL;DR "Last updated" → 2026-05-13; (o) TL;DR line 9 IMPL-FIX-003 Phase 1B closure annotated with registry pointer.
- `docs/state/deferred-ac-registry.md` — new Active row **IMPL-FIX-003 Phase 1B** (P4, expiry 2026-05-26, owner Kritsana, evidence-kinds probe + log-assertion + file-blob-check).
- `docs/state/overview.md` — `Impl Plan` row Status column updated with R10 closure summary.

**Tasks split:** none (rebuttal scope: prose / state-reconciliation only — no AC content / phase reassignment / Evolution Sequence touch).
**Phase reassignments:** none.
**Registry rows added/closed:** 1 added (IMPL-FIX-003 Phase 1B Active, P4, expiry 2026-05-26); 0 moved to Resolved.
**Escalations filed:** none (no Evolution Sequence violation requested; no upstream artifact conflict).

---

## Claim Responses

### Claim 10.1: 🔴 CRITICAL — Plan Staleness Sentinel direct contradiction (TL;DR "0 closures since R25" vs § Sentinel "11 THRESHOLD CROSSED"); ผสม impl-review/impl-plan-review chain
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md § Plan Staleness Sentinel` (~line 2258) — block rewritten:
  - Added "Counter convention" note at top: Sentinel ติดตามเฉพาะ **IMPL-NNN main task closures**; **IMPL-FIX-NNN ticket closures ไม่ increment counter** per `workflow.md` Gate #4 + fix-round-10 precedent.
  - **Last review on:** flipped from `2026-05-04 (R07)` → `2026-05-11 (R09 7/7 Accept; IMPL-FIX-011 re-decomposition into 011a/b/c/d)` with R10 verify-pass + chain back to R07/R06.
  - **Closures since R09 (impl-plan-review chain):** `0 IMPL-NNN main task closures` — within ≤10-closure threshold ✅. Activity 2026-05-11/12 (FIX-011 sub-tickets a/b/c/d + iter-17/18/19 + IMPL-FIX-003 Phase 1B + IMPL-062 Run #2) เป็น engineer-side rework + verification, ไม่ใช่ main task closures — ไม่ trigger Sentinel.
  - Deleted contradictory "9 closures since R07 ... THRESHOLD CROSSED 11" paragraph; replaced with within-threshold ✅ status and reference to next IMPL-NNN main task closure (IMPL-063 post `/backtrack ba`).
  - Added R10 lesson: Gates #7/#8 ไม่ถูก invoke ใน 2026-05-11/12 closure burst → re-emphasized in `workflow.md`.
- File: `docs/state/impl-plan.md` TL;DR + body — `replace_all` of 51 instances of `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25"` → `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R09 (impl-plan-review chain; FIX-ticket closures ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent)"`. (Review report cited 10× literally but actual count was 51 — undercount caught during the replace_all execution; all 51 fixed in one pass.)
- Evidence (new Sentinel text):
  > **Closures since R09 (impl-plan-review chain):** **0 IMPL-NNN main task closures** — within ≤10-closure threshold ✅. Activity 2026-05-11/12 (FIX-011 sub-tickets a/b/c/d closures + iter-17/18/19 wiring + IMPL-FIX-003 Phase 1B closure + IMPL-062 Run #2 empirical execution) เป็น engineer-side rework + verification, ไม่ใช่ main task closures — ไม่ trigger Sentinel.
- **Cascaded:** none — Sentinel block change is self-contained; `/next` Check 5.8 readers will now read consistent value (0 < 10 → no MANDATORY review). overview.md `Impl Plan` row updated separately (Cascaded Changes below).

### Claim 10.2: 🟠 HIGH — Open Risks R-3/R-8/R-13 + Phase Status P4 Notes + Next Best Action ทั้งหมด stale หลัง 6 TL;DR closure entries ใน 2 วัน; Phase 5 mechanical Gate #7+#8 ไม่ถูก invoke
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md § Open Risks`:
  - **R-3** prefix strikethrough + `⚠️ CONTRACT RE-BASELINE REQUIRED 2026-05-12 (R10 §10.2 update)` — cites Run #2 catastrophic 99.998% drift; root cause = measurement contract structurally incompatible; earliest mitigation = `/backtrack ba` per TL;DR 2026-05-12 + `regression-bucket-a.md § 5`. (Body text preserved as audit history.)
  - **R-8** prefix strikethrough + `✅ RESOLVED 2026-05-10 via IMPL-FIX-006/007/008/009/010 chain` + `Superseded by R-3 (R10 §10.2)` — historical body preserved for audit.
  - **R-13** Mitigation paragraph rewritten (`Mitigation (UPDATED 2026-05-12 R10 §10.2):` lead) — sub-ticket chain CLOSED (IMPL-FIX-011a/b/c/d + IMPL-FIX-003 Phase 1B), parent paired-bundle drain now blocked transitively on R-3 contract re-baseline. Hypothesis (a) anti-pyramid scope-reduced wording preserved; Blocks section updated to cite R-3 transitive dependency.
- File: `docs/state/impl-plan.md § Phase Status Snapshot` P4 row Notes column — "Remaining work = operator paired-bundle 5-yr drain" sentence struck through + 2026-05-12 PIVOT annotation: numeric-drain → contract re-baseline via `/backtrack ba` (NFR-1.1 methodology); numeric-drain residue (IMPL-063 Bucket B + IMPL-FIX-006/007/008/009 E-AC + IMPL-066 + IMPL-068) all downstream of contract re-baseline outcome.
- File: `docs/state/impl-plan.md § Next Best Action`:
  - "NEXT — operator decision on Option A / B / C" line prefix `☑ ~~...~~ ✅ RESOLVED at R09 (2026-05-11)` — Option B accepted; sub-tickets 011a/b/c/d + IMPL-FIX-003 Phase 1B all CLOSED 2026-05-11/12.
  - New top-level NEXT (R10 §10.2): `☐ Operator decision on /backtrack ba scope` — Options (i) re-baseline NFR-1.1 threshold; (ii) re-interpret Bucket A = "rewrite-G4-ON vs baseline"; (iii) stakeholder waiver per BA `01 § 6.2 Won't Permanent` precedent.
  - Historical Option A/B/C block preserved as nested sub-bullets for audit per State Reconciliation Discipline (don't silently rewrite history).
- **Cascaded:** P4 Phase Status row Notes column also gains a 2026-05-12 PIVOT note (linked to R-3 + IMPL-062 BLOCKED).

### Claim 10.3: 🟠 HIGH — IMPL-FIX-011 parent task block E-AC footnote ยัง cite "extend FIX-006/007/009 expiry to absorb IMPL-FIX-011 closure window"; R09 09.7 superseded
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md § IMPL-FIX-011` parent block — all 4 E-AC footnote bullets annotated:
  - E-AC #1 (5-yr Bucket A regression `regression_5yr_no_g4.ini`): footnote text rewritten to cite `deferred-ac-registry.md § Active` **IMPL-FIX-011 parent row, expiry 2026-06-30** per R09 Finding 09.7; `[SUPERSEDED post-R09]` marker added on prior absorb-window wording. Additional R10 §10.4 BLOCKED-on-`/backtrack-ba` annotation added.
  - E-AC #2 (|Bucket A drift| ≤ 25% NFR-1.1): same SUPERSEDED + R10 §10.4 BLOCKED annotations.
  - E-AC #3 (Per-slot deviation ≤ 10% NFR-1.6): same.
  - E-AC #4 (Bucket B paired regression IMPL-063): same; "Requires valid Bucket A baseline" → blocked transitively on `/backtrack ba`.
- **Cascaded:** none — registry rows for FIX-006/007/009 already had R09 audit-trail wording per R09 rebuttal decision; this rebuttal only fixes the parent task-block footnotes to match.

### Claim 10.4: 🟠 HIGH — P4 Phase Gate "Empirical Demo" + NFR-1.1 check rows ไม่สะท้อน Run #1/Run #2 empirical falsification
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md § P4 Phase Gate § Empirical Demo` bullet — prefix annotation:
  > ⚠️ **BLOCKED 2026-05-12 (R10 §10.4) — pending `/backtrack ba` NFR-1.1 contract re-baseline.** IMPL-062 Run #1 (2026-05-10 day-1 stop-out) + Run #2 (2026-05-12 Phase 1B build, drift ≈ 99.998%, HALTED via CircuitBreaker BR-3.6) both empirically demonstrated that the current Bucket A measurement contract (DISABLE_G4_FIXES) is structurally incompatible with the 16-active-slot rewrite under $1k deposit (root cause = measurement methodology, not Phase 1B regression — Phase 1B wiring fired correctly with 72 schema-valid journal records). See TL;DR 2026-05-12 + `regression-bucket-a.md § 5`. **Original gate text (preserved for audit):** ...
- File: `docs/state/impl-plan.md § P4 Phase Gate § NFR check § NFR-1.1`: same BLOCKED 2026-05-12 (R10 §10.4) annotation appended.
- File: `docs/state/impl-plan.md § IMPL-062` task block — new `**Status (R10 §10.4, 2026-05-12):**` paragraph between `Rules:` and `Closed:` sections — documents Run #1 + Run #2 outcomes with evidence paths + root cause + "do NOT rerun until contract resolves" instruction.
- **Cascaded:** Phase Gate Hallucination class prevented — `/next` orchestrator + status agents reading Phase Gate row will now see BLOCKED status and stop recommending "run IMPL-062 again, close P4 Gate".

### Claim 10.5: 🟡 MEDIUM — IMPL-FIX-003 Phase 1B closure G2/G3/G4 deferred โดยไม่มี Active row ใน deferred-ac-registry; ใกล้เคียง forbidden pattern
**Verdict:** Accept
**Changes:**
- File: `docs/state/deferred-ac-registry.md § Active` — new row inserted before `IMPL-FIX-011a-followup`:
  - Phase: P4
  - Task: IMPL-FIX-003 Phase 1B
  - E-AC text: G2 smoke EA attach 5-tick `[ev=init_ok]` `[probe]` + G3 headless `bootstrap_smoke.ini` 3-day run `[log-assertion]` + G4 journal-record schema validate sample 5 `[file-blob-check]`
  - Evidence-kind: probe + log-assertion + file-blob-check
  - Deferred reason: closure 2026-05-12 foreground MT5 lock; pattern byte-identical to known-clean Slot_K iter-18 + Slot_B iter-19 (G1 PASS attests no syntax error). Run #2 Phase 1B build (2026-05-12) provides strong indirect attestation (40 entries + 30 exits + 72 schema-valid journal records). Explicit gates deferred to Tier 1.5 walk batch-4 OR next Run #3 retry. Registered per R10 §10.5.
  - Owner: Kritsana
  - Opened: 2026-05-12
  - Expires: 2026-05-26 (≤14d ✅)
  - Risk if missed: runtime defect not caught by G1 (null-deref / latch race / CloseOrder edge case) → next Bucket A run day-1 cascade. Mitigation: strong indirect attestation from Run #2.
- File: `docs/state/impl-plan.md` TL;DR line 9 (IMPL-FIX-003 Phase 1B closure entry) — `G2/G3/G4 deferred to operator session` annotated `✅ tracked at deferred-ac-registry.md § Active row IMPL-FIX-003 Phase 1B (expiry 2026-05-26) per R10 §10.5`.
- **Cascaded:** `/deliver` Block check now correctly fires on this row (Active table non-empty for IMPL-FIX-003 Phase 1B until 2026-05-26 walk-batch-4 OR Run #3 drain). Empirical Closure Discipline gate sealed; forbidden-pattern proximity eliminated.

### Claim 10.6: 🟡 MEDIUM — TL;DR section 10 stacked entries deep + ~60 lines repeating boilerplate; skim test fail + amplifies Finding 10.1 contradiction
**Verdict:** Partial
**Accepted part:**
- Added canonical `## Closure Hygiene Status` 3-line block under `## Plan Staleness Sentinel` consolidating Sentinel counter / Phase 5 mechanical-gate status / State Reconciliation 3-file rule status — replaces the per-TL;DR-entry boilerplate triad for skim-first readers.
- Added TL;DR top "Reader empathy (R10 §10.6, 2026-05-13)" note pointing readers to **top 3 most-material entries** + Closure Hygiene Status block + audit-trail discipline rationale (older entries retained inline; Ctrl-F by date / IMPL-NNN tag).
- Bulk-replaced 51 instances of contradictory `"unchanged at 0 IMPL-NNN closures since R25"` boilerplate with the corrected `R09 (impl-plan-review chain; FIX-ticket closures ไม่ increment counter)` string (subsumes the "contradiction-amplified-10×" reader concern in Finding 10.6).

**Rejected (deferred) part:**
- **Physical reorg of 76 TL;DR audit-trail entries into a new `## TL;DR Audit Trail` section** is NOT applied this round. Rationale:
  1. **Edit risk** — moving ~76 contiguous blockquote lines using the Edit tool (anchor-match-replace) has high probability of introducing trailer-corruption or orphan-fragment defects (R08 § 6 + R16 § 16.1 precedent — file integrity gates exist precisely because large block moves silently desync).
  2. **Information gain vs cost** — the canonical Closure Hygiene Status block + reader-empathy note already absorb the skim-test concern; the audit-trail entries remain in-place + searchable; Ctrl-F by date or task-id is the actual reader path for historical lookup.
  3. **State Reconciliation Discipline** — silently rewriting 76 entries (even with audit-trail destination) risks the same "silent history rewrite" class that the rebuttal pattern guards against in other dimensions.
  4. **Scope-out path** — physical reorg is properly a `/deliver` Phase 5 cleanup task (alongside trailer hygiene + commit hygiene + final docs polish), not a mid-implementation rebuttal action.

**Recommended follow-up:** track physical TL;DR reorg as a `/deliver` Phase 5 grooming task (NO deferred-AC row required — this is documentation hygiene, not E-AC).

---

## Cascaded Changes

Changes ใน plan / sibling state files ที่ **ไม่ได้** cite ใน claims โดยตรง:

1. **`docs/state/impl-plan.md` TL;DR "Last updated:" line** — flipped from `2026-05-12 · last action: 🔴 IMPL-062 Bucket A 5-yr Run #2 ...` to `2026-05-13 · last action: 📝 /impl-plan-rebuttal claim-review-10.md ✅ CLOSED` with R10 closure summary + `prior action:` re-pointing to the IMPL-062 Run #2 entry. Maintains chronological narrative.
2. **`docs/state/overview.md § Phase Status § Impl Plan` row** — Status column updated with R10 rebuttal closure summary + `No AC changes / no phase reassignments / no Evolution Sequence touch` reassurance. Honors State Reconciliation 3-file rule (CLAUDE.md §6).
3. **51-instance Sentinel boilerplate replace_all (10.1)** also incidentally cleans every TL;DR entry's duplicated Sentinel sentence — partially honoring Finding 10.6's "remove duplicate boilerplate" intent without the physical reorg.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 83% (5/6) + 17% Partial (1/6) | ทุก finding rebuttal-fixable; ไม่มี Reject / Escalate (intra-plan parallel-narrative class — R10 ตรงกับ R06→R09 recurring weakness pattern) |
| Critical Fixes | 1 (10.1 Sentinel contradiction) | สำคัญที่สุด — `/next` Check 5.8 + status agents จะอ่าน consistent value แล้ว; Phase Gate Hallucination class prevented |
| Tasks Split | 0 | Rebuttal scope: prose / state-reconciliation only — no AC content change |
| Phase Reassignments | 0 | No phase movement; no forward-reference creation |
| Net Improvement | High — TL;DR + Sentinel + Open Risks + Phase Status + Next Best Action + Phase Gate + IMPL-062 + IMPL-FIX-011 parent + registry ทั้งหมด reconciled; `/backtrack ba` decision now surfaces clearly to operator at the canonical "Next Best Action" surface | |
| Escalations | 0 | No Evolution Sequence violation; no upstream BA/SD/TD/ADR conflict |
| Remaining Gaps | 1 — TL;DR physical reorg (10.6 Partial) | Deferred to Phase 5 `/deliver` cleanup; rationale: edit risk > information gain at mid-implementation stage |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all CRITICAL + HIGH claims fully resolved; one MEDIUM Partial (10.6 physical reorg) with documented `/deliver` follow-up path. No blocking finding remains.
- [ ] 🔁 Request Re-Review — not needed (single-cycle close as predicted by reviewer scope note)
- [ ] ⛔ Needs Stakeholder Input — separate operator decision on `/backtrack ba` scope (now surfaced in `## Next Best Action` per Claim 10.2 fix); not a rebuttal blocker

## End of Rebuttal
