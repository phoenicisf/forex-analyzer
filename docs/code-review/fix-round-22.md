# Code Review Fix Round 22

| Field | Value |
|-------|-------|
| **Round** | 22 |
| **Review File** | `docs/code-review/review-round-22.md` |
| **Date** | 2026-05-09 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commit |
|---|---------|----------|---------|----------------|--------|
| 22.1 | Bin-1 routing comments embed hardcoded line range (`line 365-369`) instead of grep-stable comment-marker anchor — brittle on future Orchestrator.mqh edits | 🔵 LOW | Accept | `domain/CSlotBase.mqh` (2 sites @ :68, :150) | (this round) |
| 22.2 | `Spike_Slot_BI.mq5:21` banner reads `attestation wire through ...` (bare-verb) — clipped vs sentence-prose `wired`/`wires` form | 🔵 LOW | Accept (Option A — `wiring` gerund) | `spike/Spike_Slot_BI.mq5` (:21) | (this round) |

**Accepted:** 2 / 2 (100%). 0 Reject / 0 Partial.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 22.1: LOW — line-anchor brittleness

**Verdict:** Accept (per review-round-22 §22.1 Suggested Fix).

**Approach:** Replace physical line range `(line 365-369: ...)` with grep-stable comment marker `"wire CPipMath into every slot post-RegisterAll"` — the same string that already appears at `core/Orchestrator.mqh:364` as the wiring-loop's banner. Future edits ahead of line 365 cannot desync the cite, because the marker travels with the loop.

**Changes:**

- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh:65-71` — comment block now reads:
  ```
  Composition Root calls SetPipMath() on every registered slot in
  core/Orchestrator.mqh::OnInit Phase B post-RegisterAll loop
  (grep marker: "wire CPipMath into every slot post-RegisterAll";
  body: `for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip)`).
  ```
- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh:148-153` — comment block now reads:
  ```
  When m_pip is wired (set by core/Orchestrator.mqh::OnInit Phase B
  post-RegisterAll loop — grep marker "wire CPipMath into every
  slot post-RegisterAll", via per-slot SetPipMath()) the helpers
  route through CPipMath ...
  ```

**Verification:**

```bash
grep -nE "line [0-9]+(-[0-9]+)?" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh
# → 0 hits (no line-number anchors remain)

grep -n "wire CPipMath into every slot post-RegisterAll" MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh
# → :364 ✅ (cited grep marker exists at the destination)
```

### Fix for Finding 22.2: LOW — banner bare-verb cosmetic

**Verdict:** Accept (Option A — `wiring` gerund).

**Approach:** Single banner-line edit. Option A preferred over B because gerund `wiring` reads cleanly in banner-fragment context, removing verb-vs-noun ambiguity. The substring `wiring` does NOT re-introduce the R21 doubling defect class because it appears in exactly one banner site (not 34 sentence-prose sites) and the surrounding prose `attestation wiring through` is a noun phrase + preposition, not verb + preposition.

**Changes:**

- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5:21` — banner now reads:
  ```
  //| E-AC smoke + G4 attestation wiring through core/Orchestrator.mqh         |
  ```

**Verification:**

```bash
grep -rcE "(wire[ds]?|wire) at .* wiring" MQL5/Experts/PhoenicisNex/
# → 0 hits (no R21 doubling regression)

grep -rcE "wire through " MQL5/Experts/PhoenicisNex/
# → 0 hits (bare-verb form eliminated)
```

---

## Workflow / Methodology Updates

### `.claude/rules/workflow.md` Gate #9 — clause (h)

R22-derived strengthening for the next-finer-granularity destination-correctness surface:

- **(h) Line-anchor brittleness rule** — bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor — drift on file edits silently desyncs the cite without compile-time signal.
- **Verification post-condition:** `grep -nE "line [0-9]+(-[0-9]+)?" <comment-block>` MUST return 0 hits OR each surviving line-number annotation MUST be paired with a grep-stable symbolic anchor in the same comment block.

R22 narrative entry appended to the "Why this is here" prose at the end of the Phase 5 mechanical-gate section, citing Finding 22.1 as the motivating defect AND noting R12→R21 chain termination confirmed by R22 verify-only sweep.

---

## Mechanical Gates (Phase 5 Closure self-check)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | ✅ Pass | 0 hits |
| 2 | TL;DR ↔ registry recount | ✅ Pass | unchanged from fix-round-21 (49 Active rows) |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | no Phase × Size matrix change |
| 4 | Sentinel counter increment | n/a — fix-round, not IMPL-NNN closure |
| 5 | overview.md sync | ✅ Pass | Impl Plan row status string appended fix-round-22 paragraph |
| 6 | File integrity (post-Edit-batch) | ✅ Pass |
| 7 | Phase Status Snapshot Notes sweep | n/a |
| 8 | Narrative-section freshness sweep | n/a |
| 9a | Originating literal grep | ✅ Pass | `(wire[ds]?\|wire) at Orchestrator wiring path` source tree → 0 hits (carried from R21) |
| 9b | Broader-class doubling regex | ✅ Pass | `wire[ds]? at .* wiring` source tree → 0 hits |
| 9c | Repo-wide intent grep | ✅ Pass | unchanged from R21 |
| 9d | Closed-task verb-form catalog (dynamic 68-task list) | ✅ Pass (unchanged from fix-round-20) |
| 9e | Closed-task list dynamic derivation | ✅ Pass (unchanged) |
| 9f | Destination-existence verification (R21) | ✅ Pass |
| 9g | Token-collision pre-check (R21) | ✅ Pass |
| 9h | **Line-anchor brittleness rule (NEW, R22)** | ✅ Pass | `grep -nE "line [0-9]+(-[0-9]+)?" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh` → 0 hits |
| 10 | Stash-clean G1 (R16) | ✅ Pass (post-commit, equivalent to working-tree-clean) |
| 11 | Working-tree clean post-closure | ✅ Pass (post-commit) |

### G1 compile gate

```
Result: 0 errors, 0 warnings, 4534 ms elapsed, cpu='X64 Regular'
```

PASS ✅ (comment-only changes; no code path touched).

---

## State Reconciliation (3-File Propagation)

**Layer 1 — `docs/state/impl-plan.md`** (PRIMARY SoT)
- No change (no IMPL-NNN closure; no Active count delta).

**Layer 2 — `docs/state/overview.md`** (DERIVED VIEW)
- Impl Plan row status string: appended fix-round-22 closure paragraph.

**Layer 3 — `.claude/rules/workflow.md`**
- Gate #9 cell extended with clause (h); narrative footer extended with R22 entry.

**Reconciliation Self-Check:**

```
✅ impl-plan.md     — no change required (no closure)
✅ overview.md      — fix-round-22 status paragraph appended
✅ workflow.md      — Gate #9 clause (h) + R22 narrative
✅ CSlotBase.mqh    — 2 comment blocks re-anchored
✅ Spike_Slot_BI.mq5 — banner reworded
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 2 |
| Accepted | 2 (100%) |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 5 (2 source + workflow.md + overview.md + this report) |
| Tests Added/Updated | 0 (comment-only; no behavior change) |
| Compile (G1) | ✅ 0 errors, 0 warnings, 4534 ms |
| New Gate #9 clauses | 1 (h line-anchor brittleness rule) |
| New deferred-AC rows | 0 |

---

## Recommendation

Ready for **review-round-23** OR **chain-termination acceptance**.

**R12→R22 chain status:** TERMINATED at both axes.

- **Catalog axis** — Gate #9d clause (e) ✅
- **Destination axis** — Gate #9 clauses (f) + (g) + (h) ✅

R22's verify-only sweep was the first round in 10 iterations to find 0 hits on the broader-class intent grep with no new defect class manifesting. Findings 22.1 + 22.2 were next-finer-granularity surfaces (line-anchor drift, banner-prose cosmetic) — not chain recurrences. The structural failure mode (mechanical sweep without prose-context validation) is no longer surfacing.

**Forward-looking recommendation:** R23 verify-only sweep recommended after one more `/impl-task` closure batch to confirm Sentinel-trigger threshold doesn't surface a new chain. If R23 finds 0 hits, declare R12→R22 chain methodology-closed and remove the Sentinel-pre-trigger advisory from the next IMPL-NNN closure path.

## End of Fix Round 22
