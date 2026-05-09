# Code Review Fix Round 21

| Field | Value |
|-------|-------|
| **Round** | 21 |
| **Review File** | `docs/code-review/review-round-21.md` |
| **Date** | 2026-05-09 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 21.1 | Bulk-replacement token "Orchestrator wiring path (core/Orchestrator.mqh)" produces grammatical-doubling at 34 sites — `(wire[ds]?\|wire) at <token>` reads "wires at wiring path" | 🟠 HIGH | Accept (Option B regex pass) | 21 files (1 service + 13 slots + 7 spikes) | (forthcoming — see Commits section) |
| 21.2 | Bin-1 hand-fix cites `core/Orchestrator.mqh::WireSlots step 4` — method does NOT exist (only banner-comment hits) | 🟡 MEDIUM | Accept | `domain/CSlotBase.mqh` (2 sites @ :66, :147) | (forthcoming) |
| 21.3 | Comment-history-exemptions manifest is structurally seeded but functionally empty | 🟡 MEDIUM | Accept (Option B — track via IMPL-FIX-004) | `docs/state/comment-history-exemptions.md` + `docs/state/deferred-ac-registry.md` | (forthcoming) |
| 21.4 | IMPL-065 registry row collapses structural-half + numeric-half drains into one row, no partial-closure visibility | 🔵 LOW | Accept (Option B — inline drain checklist) | `docs/state/deferred-ac-registry.md` line 65 | (forthcoming) |

**Accepted:** 4 / 4 (100%) — 0 Reject, 0 Partial.

---

## Accepted Findings — Fixes Applied

### Fix for Finding 21.1: HIGH — bulk-token grammatical-doubling defect class

**Verdict:** Accept (Option B per review-round-21 §21.1 Suggested Fix).

**Approach:** Single sed-style regex substitution over the 21 affected files:

```bash
sed -i -E 's#(wire[ds]?) at Orchestrator wiring path \(core/Orchestrator\.mqh\)#\1 through core/Orchestrator.mqh#g' <FILE>
```

The regex captures the verb (`wire` / `wires` / `wired`) and rewrites the prepositional phrase from `at Orchestrator wiring path (core/Orchestrator.mqh)` (which doubles "wiring") to `through core/Orchestrator.mqh` (decoupled noun stem). Result: 34 sites collapsed; prose reads as `RiskManager::OpenOrder wired through core/Orchestrator.mqh.` — no doubling.

**Changes (21 files; comment-only — zero compile risk):**

- `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh` (1 site @ :278)
- `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh` (2 sites @ :209, :267)
- `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh` (2 sites @ :133, :147)
- `MQL5/Experts/PhoenicisNex/slots/Slot_F.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh` (1 site)
- `MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_I.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh` (3 sites @ :162, :212, :219)
- `MQL5/Experts/PhoenicisNex/slots/Slot_L.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_LX.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh` (2 sites)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5` (1 site @ :21)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BR.mq5` (1 site)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_G2.mq5` (1 site)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_GO.mq5` (1 site)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_I.mq5` (1 site)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_L.mq5` (1 site)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_LX.mq5` (1 site)

**Post-fix grep verification (Phase 5 Gate #9):**

| Clause | Command | Result |
|--------|---------|--------|
| 9a (originating literal grep) | `grep -rcnE "(wire[ds]?\|wire) at Orchestrator wiring path" MQL5/Experts/PhoenicisNex/` (sum > 0 lines) | **0** ✅ |
| 9b (broader-class doubling regex) | `grep -rcE "wire[ds]? at .* wiring" MQL5/Experts/PhoenicisNex/` | **0** ✅ |
| 9c (repo-wide intent grep) | Surviving "Orchestrator wiring path" hits all in non-`wire`-verb-prefix prose contexts (e.g., "completed at Orchestrator wiring path", "Real activation: Orchestrator wiring path", "Owner: Orchestrator wiring path") — no grammatical doubling | ✅ verified |
| Through-form count (sanity) | `grep -rcE "wire[ds]? through core/Orchestrator.mqh" MQL5/Experts/PhoenicisNex/` (file count) | **21** ✅ (matches affected-file count) |

### Fix for Finding 21.2: MEDIUM — `WireSlots step 4` dangling-method pointer

**Verdict:** Accept.

**Destination-existence verification (per new Gate #9 clause (f) added this round):**

```bash
grep -nE "WireSlots\\s*\\(|^bool COrchestrator::WireSlots" MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh
# → 0 hits (no callable method)

grep -n "SetPipMath" MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh
# → :368   (`if(s != NULL) s.SetPipMath(m_pip);`) inside Phase B post-RegisterAll loop @ :365-369
```

The actual SetPipMath wiring lives in `core/Orchestrator.mqh:365-369`:

```mql5
   // Round-06 06.1 — wire CPipMath into every slot post-RegisterAll
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.SetPipMath(m_pip);
     }
```

This is in `OnInit` Phase B (post-`RegisterAll`), NOT inside any method named `WireSlots`. The method is `OnInit` itself; `WireServices` is a Phase A heap-construction routine called from `OnInit:280`.

**Changes:**

- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh:65-70` — comment now reads:
  `Composition Root calls SetPipMath() on every registered slot in core/Orchestrator.mqh::OnInit Phase B post-RegisterAll loop (line 365-369: \`for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip)\`).`
- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh:146-151` — comment now reads:
  `When m_pip is wired (set by core/Orchestrator.mqh::OnInit Phase B post-RegisterAll loop at line 365-369, via per-slot SetPipMath()) the helpers route through CPipMath; ...`

**Post-fix verification:** `grep -n "WireSlots" MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh` → 0 hits ✅

### Fix for Finding 21.3: MEDIUM — comment-history-exemptions manifest empty

**Verdict:** Accept (Option B per review-round-21 §21.3 Suggested Fix — file IMPL-FIX-NNN ticket).

**Rationale for Option B over Option A:** Option A (one-shot enumeration of ~86 sites) is 1-2 hours of low-stakes classification work that is better tracked as a discrete deferred-AC closure than smuggled into a code-review fix-round. Option B converts the implicit deferral into an explicit, expirable commitment with owner + risk-if-missed.

**Changes:**

- `docs/state/deferred-ac-registry.md` — new Active row inserted before IMPL-067:
  - Phase: P5
  - Task: IMPL-FIX-004
  - E-AC: manifest populated with ~86 banner-style sites cited in fix-round-19 §19.2 + Gate #9d sweep verified clean via `grep -vFf` subtraction `[file-blob-check]`
  - Owner: Kritsana
  - Opened: 2026-05-05
  - Expires: 2026-05-19
  - Risk if missed: Gate #9d sweep falls back to manual narrative path; banner-vs-forward-pointer ambiguity remains unresolved at the disambiguation layer
- `docs/state/comment-history-exemptions.md` header narrative — placeholder line replaced with `_(populate work tracked under IMPL-FIX-004; deferred-ac-registry row Active until 2026-05-19)_` and the "First-pass population" note now states "Tracked under IMPL-FIX-004 ... fallback path is now an explicitly-tracked deferral, not a silent placeholder."

### Fix for Finding 21.4: LOW — IMPL-065 single Active row no partial-closure visibility

**Verdict:** Accept (Option B per review-round-21 §21.4 Suggested Fix — inline drain checklist).

**Rationale for Option B over Option A:** keeps the "single E-AC paired bundle" framing established by fix-round-18 §18.5 + ratified by fix-round-20 §20.5, while exposing per-drain progress to `/next` Check 5.5. Splitting into two rows would invalidate the "drains at the same operator session" framing which is part of the methodology.

**Changes:**

- `docs/state/deferred-ac-registry.md` line 65 — appended to the `Deferred reason` column:
  - `- [ ] structural drain (tick_latency_smoke.ini 3-day H4 — asserts n[entry_pass] < n[refresh] AND n[entry_pass] > 0 [log-assertion])`
  - `- [ ] numeric drain (regression_5yr_no_g4.ini 5-yr H4 — asserts avg overhead ≤ 10% NFR-2.1 + Tester wall-clock ≤ 1.5× NFR-2.3 [log-assertion])`
  - Closure rule: row moves to Resolved only when BOTH boxes ticked. `/next` Check 5.5 surfaces partial-closure (one box ticked, one Active) as a distinct sentinel state vs fully-Active.

---

## Workflow / Methodology Updates

### `.claude/rules/workflow.md` Gate #9 — clauses (f) + (g)

R21-derived strengthening of Gate #9 to break the destination-correctness axis of the R12→R21 chain:

- **(f) Destination-existence verification** — when a fix introduces a bin-1 routing comment that cites `<file>:<line>` or `<class>::<method>`, the engineer MUST grep-verify the destination is not a banner-comment-only hit. Engineer attests the verification in the fix-round narrative.
- **(g) Token-collision pre-check** — when choosing a bulk-substitution token, the engineer MUST inspect ≥5 representative call-sites and verify the token's internal nouns do NOT collide with the surrounding verb prose. Post-condition: `grep -rcE "<verb-class> at <token>"` → 0 grammatical-doubling hits.

R21 narrative entry appended to the "Why this is here" prose at the end of the Phase 5 mechanical-gate section, citing Findings 21.1 + 21.2 + 21.3 as motivating defects.

### IMPL-FIX-004 ticket (deferred-AC registry)

Tracks the comment-history-exemptions populate work (Finding 21.3 follow-up). Owner Kritsana, expires 2026-05-19.

---

## Mechanical Gates (Phase 5 Closure self-check)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | ✅ Pass | `grep -cnE "deferred per .* precedent\|deferred to operator-runtime\|structurally complete.*deferred\|live verification deferred" docs/state/impl-plan.md` → 0 |
| 2 | TL;DR ↔ registry recount | ✅ Pass | impl-plan.md line 8 updated 48→49 (added P5 IMPL-FIX-004 row) |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | no Phase × Size matrix change |
| 4 | Sentinel counter increment | n/a — fix-round, not IMPL-NNN closure | Plan Staleness Sentinel unchanged from R09 advisory (this is a code-review fix-round, not a task closure) |
| 5 | overview.md sync | ✅ Pass | Impl Plan row Last Updated 2026-05-05 → 2026-05-09 + R21 paragraph appended + status string registry-count append |
| 6 | File integrity (post-Edit-batch) | ✅ Pass | `grep -c "^## End of Plan" docs/state/impl-plan.md` → 1; tail clean |
| 7 | Phase Status Snapshot Notes sweep | n/a | no Phase Status row Notes invalidated by this round (fix-round, not task closure) |
| 8 | Narrative-section freshness sweep | n/a | no Open Risks / Next Best Action invalidated by this round |
| 9a | Originating literal grep | ✅ Pass | `(wire[ds]?\|wire) at Orchestrator wiring path` source tree → 0 hits |
| 9b | Broader-class intent grep | ✅ Pass | `wire[ds]? at .* wiring` source tree → 0 hits |
| 9c | Repo-wide intent grep | ✅ Pass | surviving "Orchestrator wiring path" hits all in non-doubling prose contexts |
| 9d | Closed-task verb-form catalog (dynamic 68-task list) | ✅ Pass (carried from fix-round-20 §20.2 verification — no closed-task list change this round) |
| 9e | Closed-task list dynamic derivation | ✅ Pass (mechanism unchanged — fix-round adds no IMPL-NNN closures) |
| 9f | **Destination-existence verification (NEW, R21)** | ✅ Pass | `WireSlots` removed from `domain/CSlotBase.mqh`; new pointer cites `OnInit Phase B post-RegisterAll loop line 365-369` — verified by `grep -n "SetPipMath" core/Orchestrator.mqh` returning :368 |
| 9g | **Token-collision pre-check (NEW, R21)** | ✅ Pass | new through-form `(wire[ds]?) through core/Orchestrator.mqh` inspected at 5 representative sites (Slot_B.mqh:209, Slot_BR.mqh:133/147, Spike_Slot_BI.mq5:21, services/PortfolioState.mqh:278) — no internal-noun collision with surrounding prose |
| 10 | Stash-clean G1 (R16) | ⏭ deferred to commit step (run after working-tree commit lands) |
| 11 | Working-tree clean post-closure | ⏭ deferred to commit step |

**Gate #9 verdict:** all sub-clauses pass; the R21-derived clauses (f) + (g) are themselves the verification mechanism that closed Findings 21.1 + 21.2.

### G1 compile gate

```
Result: 0 errors, 0 warnings, 4142 ms elapsed, cpu='X64 Regular'
```

PASS ✅ (post-edits, against committed-plus-working-tree surface; comment-only changes — no code path touched).

---

## State Reconciliation (3-File Propagation)

**Layer 1 — `docs/state/impl-plan.md`** (PRIMARY SoT)
- TL;DR Active count line 8: `48 Active rows total` → `49 Active rows total` + `+ 1 P5 row (IMPL-FIX-004 ...)` enumeration.

**Layer 2 — `docs/state/overview.md`** (DERIVED VIEW)
- Impl Plan row Last Updated `2026-05-05` → `2026-05-09`.
- Status string: appended fix-round-21 closure paragraph (4 findings, all accept; G1 PASS; Gate #9 a/b/c/d/e/f/g ALL PASS); registry-count append `48 Active rows = ... 14 P4 + 5 Resolved` → `49 Active rows = ... 14 P4 + 1 P5 IMPL-FIX-004 + 5 Resolved`.

**Layer 3 — `docs/state/current_handoff.md`**
- (handled inline — see "Files Modified" tally below.)

**Reconciliation Self-Check:**

```
✅ impl-plan.md     — TL;DR Active count 48→49 + P5 IMPL-FIX-004 enumeration
✅ overview.md      — Impl Plan Last Updated bumped + R21 status paragraph appended + registry-count append
✅ deferred-ac-registry.md — IMPL-065 row gains drain checklist + new IMPL-FIX-004 P5 row
✅ comment-history-exemptions.md — header narrative converted from silent placeholder to tracked-ticket pointer
✅ workflow.md      — Gate #9 cell extended with clauses (f) + (g) + R21 narrative entry
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 4 |
| Accepted | 4 (100%) |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 26 (21 source + 1 workflow rule + 2 state-doc + 1 manifest + 1 impl-plan) |
| Tests Added/Updated | 0 (comment-only sweep + state/registry hygiene; no behavior change) |
| Compile (G1) | ✅ 0 errors, 0 warnings, 4142 ms |
| New Gate #9 clauses | 2 (f destination-existence verification + g token-collision pre-check) |
| New deferred-AC rows | 1 (IMPL-FIX-004 P5; expires 2026-05-19) |

### Files Modified

- `MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh`
- `MQL5/Experts/PhoenicisNex/slots/Slot_{B,BR,F,G2,GO,H,I,J,K,L,LX,P,S}.mqh` (13)
- `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_{BI,BR,G2,GO,I,L,LX}.mq5` (7)
- `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`
- `.claude/rules/workflow.md`
- `docs/state/deferred-ac-registry.md`
- `docs/state/comment-history-exemptions.md`
- `docs/state/impl-plan.md`
- `docs/state/overview.md`
- `docs/code-review/fix-round-21.md` (this file)

---

## Recommendation

Ready for **review-round-22** (verify-only sweep recommended given comment-only scope + no IMPL-NNN closure since R09).

**R12→R21 chain status — both axes now addressed:**

- **Catalog axis** — Gate #9d clause (e) (✅ landed in fix-round-20; verified clean against 68-task dynamic list this round)
- **Destination axis** — Gate #9 clauses (f) + (g) (✅ landed in fix-round-21 — destination-existence verification + token-collision pre-check)

Whether the chain truly terminates at R21 will be revealed by R22's broader-class sweep against the new `through core/Orchestrator.mqh` substring (no internal-noun collision risk identified in pre-check, but R12→R21 history suggests verification at the next reviewer surface is the load-bearing test).

## End of Fix Round 21
