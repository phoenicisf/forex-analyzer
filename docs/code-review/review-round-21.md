# Code Review Round 21

| Field | Value |
|-------|-------|
| **Round** | 21 |
| **Target** | `all` — operator invoked `/impl-review` (no arg) in Auto mode after fix-round-20 closure (commit `d8691e4`). Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/` + `docs/state/*` + `.claude/rules/*`. Working tree at session start: clean. |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) fix-round-20 §20.1 Phase-2-token rewrite — does the new "Orchestrator wiring path (core/Orchestrator.mqh)" pointer + 7 hand-fixed cited sites actually break the R12→R20 chain at the destination-correctness level? (b) §20.2 dynamic Gate #9d clause (e) — does the closed-task list sweep return clean against the live 68-task list? (c) §20.3 comment-history-exemptions manifest — is it actually populated or seeded-with-empty-table? (d) §20.4 tick_latency_smoke.ini per-slot pin (Partial) — is the corrected rationale faithful to the probe topology in source? (e) §20.5 IMPL-065 Option B residue — is the registry row updated with the required schema fields? (f) Phase-5 11-gate compliance for fix-round-20 itself. |
| **Plan Staleness Sentinel** | 0 closures since R09 advisory (no IMPL-NNN closures since fix-round-20). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **4** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No new boundary surface. Symbol whitelist + atomic-write + no DLLs invariants intact. |
| 2 | Business Logic Correctness | ✅ Pass | Comment-only sweep; production runtime unchanged. G1 PASS (3845 ms production + 3960 ms wrapper) per fix-round-20 evidence table. |
| 3 | Error Handling | ✅ Pass | No regression vs fix-round-19 §19.3 + fix-round-18 §18.7. |
| 4 | Performance | ✅ Pass | XS-17.1 hot-path rule unchanged. |
| 5 | Over-Engineering | ✅ Pass | Manifest-as-SoT (Option B) follows existing PhoenicisNex registry-as-SoT pattern. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **21.1 HIGH** — fix-round-20 §20.1 bulk-replacement token "Orchestrator wiring path (core/Orchestrator.mqh)" landed mid-sentence in 34 sites across 21 files producing the **same grammatical-doubling defect** ("wires at Orchestrator wiring path", "wired at Orchestrator wiring path") that the fix narrative claimed it cleaned up via "31-file grammatical-doubling cleanup". Ninth iteration of R12→R20→**R21** chain — same structural failure mode, new token. |
| 7 | Test Coverage Gaps | ✅ Pass | tick_latency_smoke.ini `[TesterInputs]` block now pins per-slot enables + InpLogLevel; rationale block faithful to probe topology (verified `core/Orchestrator.mqh:665` wraps RunEntryPass from outside the slot iteration loop). |
| 8 | Architecture Compliance | ✅ Pass | No ADR drift. |
| 9 | Technical Design Compliance | ⚠️ Finding | **21.2 MEDIUM** — fix-round-20 §20.1 Pass-1 hand-fix table cites `core/Orchestrator.mqh::WireSlots step 4` as bin-1 routing destination at 2 sites (`domain/CSlotBase.mqh:66` + `:147`). **`WireSlots` is NOT a callable method** in `core/Orchestrator.mqh` — it appears only in two banner comments (`:131`, `:267`). The actual Phase A entry is `WireServices()` (line 280); `step 4` in Phase B is `m_state.Init(m_atomic, m_logger)` (line 291), not anything related to slot pip-math wiring. The hand-fix replaced a dangling-registry pointer with a dangling-method pointer. |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded-loop pathology. |
| 11 | Empirical AC Closure | ⚠️ Finding | **21.3 LOW** — fix-round-20 §20.5 Option B acceptance is the methodology-correct outcome, but the IMPL-065 registry row (line 65 of `deferred-ac-registry.md`) does NOT separately enumerate the **structural-half** as a discrete row vs the **numeric-half** — they share a single Active row, sharing one `Expires=2026-05-19` deadline. If the operator session at Tier 1.5 walk batch-3 runs only the numeric drain and skips the structural drain (or vice versa), the registry has no granularity to flag the partial closure. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface; Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1 callout. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer per CLAUDE.md §7b. |

---

## Findings

### Finding 21.1: 🟠 HIGH — fix-round-20 §20.1 bulk-replacement token "Orchestrator wiring path (core/Orchestrator.mqh)" produces the **same grammatical-doubling defect** at 34 sites across 21 files ("wires at Orchestrator wiring path", "wired at Orchestrator wiring path", "wire at Orchestrator wiring path") that the fix narrative explicitly claimed it cleaned up. Ninth iteration of the R12→R20 chain — same structural failure (mid-sentence string substitution into prose authored around the prior token), new placeholder string.

**Location:**
- 34 occurrences across 21 files of `(wires|wired|wire) at Orchestrator wiring path \(core/Orchestrator\.mqh\)`. Representative sites:
  - `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:209` — `RiskManager::OpenOrder wired at Orchestrator wiring path (core/Orchestrator.mqh).`
  - `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:267` — `m_risk.CloseOrder(ticket) wires at Orchestrator wiring path (core/Orchestrator.mqh)`
  - `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:133` — `TriggerBR sub-call wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).`
  - `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:147` — `wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).`
  - `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh:162,212,219` — three sites with same pattern
  - `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5:21` — `E-AC smoke + G4 attestation wire at Orchestrator wiring path (core/Orchestrator.mqh)`
  - Full distribution: 12 slot files (`Slot_B/BR/F/G2/GO/H/I/J/K/L/LX/P/S` etc.) + 7 spike files + `services/PortfolioState.mqh:278`
- Reference: fix-round-20 §20.1 narrative "Pass 2 (bulk replacement + grammatical-doubling cleanup) … 31-file grammatical-doubling cleanup pass collapsing variants like `Orchestrator wiring path (core/Orchestrator.mqh) (Orchestrator)` → `Orchestrator wiring path (core/Orchestrator.mqh)`"; Phase-5 Mechanical Gate #9 clause (a) post-fix grep claim "0 hits ✅"; review-round-20 §20.1 Suggested Fix bin-1 (file:line/`<class>::<method>` pointer)

**Code:**
```mql5
// slots/Slot_B.mqh:208-209
      // Phase-1 stub: m_risk.OpenOrder(...) call commented out per IMPL-018+ pattern;
      //    RiskManager::OpenOrder wired at Orchestrator wiring path (core/Orchestrator.mqh).

// slots/Slot_BR.mqh:131-148  (sentence runs across the substituted token)
   //--- Phase-1 stub: no entry signal in main topo — TriggerBR sub-call
   //    wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).
   ...
   if(m_xslot != NULL && false /* enable when TriggerBR wired per BR-2.2 (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: BR activation from B's ExtraTakeProfit_B
      //    wires at Orchestrator wiring path (core/Orchestrator.mqh) (cross-slot coupling per ea.md).
     }

// spike/Spike_Slot_BI.mq5:21  (banner — doubled "wire at … wiring path")
//| E-AC smoke + G4 attestation wire at Orchestrator wiring path (core/Orchestrator.mqh)           |
```

**Problem:**
fix-round-20 §20.1 Pass 2 was a binary string substitution (`Phase-2 wiring; see docs/state/deferred-ac-registry.md` → `Orchestrator wiring path (core/Orchestrator.mqh)`). The replacement string was chosen as a noun phrase — but the **prose surrounding the prior token** had been authored treating "Phase-2 wiring; see ..." as either (a) a noun phrase (e.g., `RiskManager::OpenOrder wired at <X>`) or (b) a parenthetical (e.g., `Composition Root (<X>) calls SetPipMath()`). The bulk swap preserved (a) sentences but produced **the very grammatical-doubling defect** that fix-round-20's claimed "31-file grammatical-doubling cleanup pass" was supposed to eliminate.

Re-reading the post-fix English at the 34 sites:
- `wires at Orchestrator wiring path (core/Orchestrator.mqh)` — literally "wires at wiring path" (verb-then-noun-with-doubled-verb-stem)
- `wired at Orchestrator wiring path (core/Orchestrator.mqh)` — "wired at wiring path"
- `wire at Orchestrator wiring path (core/Orchestrator.mqh)` — banner-style "wire at wiring path"

This is exactly the defect class fix-round-20 §20.1 line 67-69 advertised cleaning up:
> `Orchestrator wiring path (core/Orchestrator.mqh) (Orchestrator)` → `Orchestrator wiring path (core/Orchestrator.mqh)`
> `Orchestrator wiring path (core/Orchestrator.mqh) Orchestrator integration` → `Orchestrator wiring path (core/Orchestrator.mqh)`

The 31-file cleanup found the *suffix* doubling (`<token> Orchestrator <suffix>`) but missed the *prefix* doubling (`wires at <token>`, where `<token>` already contains "wiring"). The result is strictly worse audit signal than the synthetic-token fix-round-19 deleted: the prior wording was at least syntactically parseable; "wires at wiring path" reads as engineer carelessness on every commented surface.

**Why This Matters:**
This is the **ninth iteration** of the R12→R20 stale-forward-pointer recurrence chain. Each fix-round picks a placeholder string and applies it via bulk substitution, accumulating prose-context defects that the next reviewer surfaces. fix-round-20's claim "Chain broken at the **catalog-dynamism** level, not just the destination level" (Pass-2 closing line) is **half-true**: Gate #9d clause (e) is correctly broadening the closed-task sweep to dynamic regex (Finding 21 verifies 0 hits against the 68-task closed list). But the **destination-correctness** axis — the actual prose readability of the substituted sites — has regressed: the new token contains the noun "wiring" inside it, which makes every prose context that says "wires at <token>" or "wired at <token>" produce visible doubling.

Compounded by Finding 21.2 (`WireSlots step 4` dangling pointer at the hand-fixed cited sites), the destination-correctness axis remains the load-bearing failure of the chain.

**Suggested Fix:**
Pick a token that does **not** contain the substring "wiring" (or any word the prose would naturally repeat). Then re-run a context-sensitive sweep that expands the cleanup pattern catalog:

```bash
# Option A — token that decouples from the surrounding verb:
#   "see core/Orchestrator.mqh"  (informal pointer, no noun overlap)
#
#   E.g., slots/Slot_B.mqh:209 →
#     "RiskManager::OpenOrder wired at Orchestrator step 8 (m_risk.Init,
#      core/Orchestrator.mqh:297)."
#   slots/Slot_BR.mqh:147 →
#     "Stub: BR activation from B's ExtraTakeProfit_B routes through
#      services/CrossSlotCoordinator.mqh::TriggerBR (cross-slot coupling
#      per ea.md)."
#   spike/Spike_Slot_BI.mq5:21 →
#     "E-AC smoke + G4 attestation runs through services/RiskManager.mqh
#      ::OpenOrder + 60-day Tester per IMPL-039."

# Option B — leave the bulk-token but extend the cleanup catalog:
#   Append to the 31-file cleanup regex:
#     s/(wire[ds]?) at Orchestrator wiring path \(core\/Orchestrator\.mqh\)/$1 through core\/Orchestrator.mqh/g

# Then verify ZERO grammatical-doubling residue:
grep -rcnE "(wire[ds]?|routes?) at Orchestrator wiring path" \
     MQL5/Experts/PhoenicisNex/    # → 0
```

And add the meta-rule to `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)`:
> "Comment-routing tokens MUST NOT contain a noun-stem that can re-collide with the surrounding verb (e.g., a token containing 'wiring' creates 'wires at wiring path' on substitution). Tokens MUST be chosen by inspecting at least 5 representative call-sites for natural-prose collision before bulk substitution."

**Level of Effort:** Medium (~2-3 hours wall-clock for 34 sites; per-site bin-1 routing OR Option B regex pass + cleanup catalog rule update; no compile risk — comments only).

---

### Finding 21.2: 🟡 MEDIUM — fix-round-20 §20.1 Pass-1 hand-fix table cites `core/Orchestrator.mqh::WireSlots step 4` as the bin-1 routing destination at 2 sites (`domain/CSlotBase.mqh:66` + `:147`), but **`WireSlots` is NOT a callable method** in `core/Orchestrator.mqh` — it appears only in 2 banner comments (`:131`, `:267`). The hand-fix replaced a dangling-registry pointer with a dangling-method pointer; bin-1 routing failed at the destination-existence level.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, Line 66 — `Composition Root (core/Orchestrator.mqh::WireSlots step 4) calls SetPipMath();`
- File: `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, Line 147 — `When m_pip is wired (set by core/Orchestrator.mqh::WireSlots after CSlotBase::Init) the helpers route`
- Reference: fix-round-20 §20.1 Pass-1 table rows for `domain/CSlotBase.mqh:66` + `:146`; review-round-20 §20.1 Suggested Fix bin-1 ("specific file:line (or `<class>::<method>`) where the writer/wiring lives")

**Code:**
```mql5
// domain/CSlotBase.mqh:65-70
   //--- Round-06 06.1: pip-arithmetic helper (ea.md mandate). Composition
   //    Root (core/Orchestrator.mqh::WireSlots step 4) calls SetPipMath();
   //    when NULL the protected helpers fall back to inline 5/3-digit
   //    detection (single fallback site eliminates the 19-way drift
   //    Finding 06.1 reported).
   CPipMath                 *m_pip;

// domain/CSlotBase.mqh:146-151
   //--- Round-06 06.1 — pip helpers shared by 19 derived slots. When
   //    m_pip is wired (set by core/Orchestrator.mqh::WireSlots after
   //    CSlotBase::Init) the helpers route through CPipMath; otherwise
   //    a SINGLE fallback site implements
   //    the canonical 5/3-digit detection (matches CPipMath::Init at
   //    helpers/PipMath.mqh:31). Slots ห้าม re-derive this expression.
```

**Problem:**
A reader following the bin-1 pointer to `core/Orchestrator.mqh::WireSlots step 4` greps the file:

```bash
$ grep -n "WireSlots" MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh
131://| WireServices / WireSlots; reverse-order release in CleanupPartial|
267://|   Phase A: WireServices + WireSlots (heap construction only)     |
```

Two hits — both inside banner comment blocks. There is no `WireSlots()` method definition. The actual Phase A wiring path is:
- Line 280 — `if(!WireServices())` (single call; constructs all heap allocations including slots)
- Line 287-302 — Phase B `Init()` chain (step 1 logger, step 2 pip, step 4 state, step 5 portfolio, step 6 indicators, ..., step 11+ slots)

`SetPipMath()` is presumably called inside `WireServices()` body (or one of the Phase B slot-init steps), not by a method named `WireSlots`. The hand-fix author appears to have inferred a method name from the banner comment narrative rather than confirming via grep that the method exists.

This is the same defect class as the registry-pointer fix-round-19 introduced and fix-round-20 §20.1 set out to eliminate: a comment that promises a routing destination that the reader cannot resolve. Eight fix-rounds into the chain, the bin-1 routing discipline (review-round-19 §20.1 Suggested Fix) has now been applied — **and it failed at destination existence** for at least 2 of the 7 hand-fixed cited sites.

**Why This Matters:**
The bin-1 routing methodology was offered as the cure for the recurring chain. If hand-fixed cited sites can themselves carry dangling pointers (because the engineer skipped grep-verification of the destination), the chain's terminal state isn't "destination-correct" — it's "destination-syntactically-correct-but-unverified". The next reviewer following any of the 158-now-177 sites still hits a dead end; only the failure mode shifts from "registry-doesn't-have-this-entry" to "method-doesn't-exist".

A small subset of the Pass-1 table likely has the same defect — at minimum the `services/PortfolioState.mqh:176` row claims `OnTradeTransaction (line 791)` which DOES verify (✅ confirmed at line 791), and `slots/Slot_BI.mqh:276` cites `services/RiskManager.mqh (CTrade wrapper)` which is a real file. But the `WireSlots` cite was made twice, suggesting the author copy-pasted without verifying.

**Suggested Fix:**
Re-route the 2 sites to actual methods/lines. Inspect `WireServices()` body to find where `m_pip` allocation flows to slot wiring:

```bash
# Step 1: locate where SetPipMath is called
grep -n "SetPipMath" MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh
# ... use the actual line + method name in the comment

# Step 2: re-author the 2 sites with verified pointers, e.g.:
#
#   domain/CSlotBase.mqh:66 →
#     "Composition Root (core/Orchestrator.mqh::WireServices, Phase A
#      heap construction at line 280) calls SetPipMath() on each slot
#      after constructing m_pip"
#
#   domain/CSlotBase.mqh:147 →
#     "When m_pip is wired (set by core/Orchestrator.mqh::WireServices
#      via per-slot SetPipMath call) the helpers route through CPipMath"
```

And add to `.claude/rules/workflow.md § Phase 5 Gate #9` a clause **(f)** mandating destination-existence verification:
> "Bin-1 routing comments citing `<class>::<method>` MUST be grep-verified — the cited method MUST appear at least once outside banner-comment blocks (i.e., as a function definition or call). Engineers MUST attest the verification in the fix-round narrative."

**Level of Effort:** Low (~20 min — find SetPipMath call site + reword 2 comments + add Gate #9 clause (f)).

---

### Finding 21.3: 🟡 MEDIUM — fix-round-20 §20.3 comment-history-exemptions manifest is **structurally seeded but functionally empty** — the table has no rows, only a placeholder line `_(manifest seeded; first-pass enumeration deferred to next maintenance window)_`. The Gate #9d sweep falls back to the manual narrative-justification path that fix-round-19 §19.2 used (and that review-round-20 §20.3 raised as the originating defect). The MEDIUM finding is closure-deferred, not closure-resolved.

**Location:**
- File: `docs/state/comment-history-exemptions.md`, Lines 32-34 — single placeholder row in the Exemptions table
- Reference: fix-round-20 §20.3 narrative "Accept (Option B per review-round-20 §20.3 Suggested Fix) ... new file `docs/state/comment-history-exemptions.md` (seeded with frame; first-pass enumeration of the ~86 banner sites cited in fix-round-19 §19.2 deferred to next maintenance round)"

**Code:**
```markdown
| File | Line | Task ref | Justification |
|------|------|----------|---------------|
| _(manifest seeded; first-pass enumeration deferred to next maintenance window)_ | | | |
```

**Problem:**
review-round-20 §20.3 raised the finding because Gate #9c "audit history" exemption was self-claimed and ambiguous: ~86 sites flagged by fix-round-19 §19.2's verb-form catalog were waved through with the rationale "these are historical banners, not forward-pointers" — without any mechanism to disambiguate "banner" from "forward-pointer wearing banner syntax". Option B (manifest) was prescribed as the methodology fix.

fix-round-20 created the manifest **frame** + cross-references in `.claude/rules/workflow.md` + discipline rules (engineer attestation requirement, format spec, deletion rule on banner→forward-pointer conversion). What it did NOT do is enumerate the ~86 sites the originating Partial Accept exempted. The manifest's literal content is one placeholder row.

This is a defer-shaped accept: the methodology gap is **acknowledged** but the actual disambiguation work is pushed to "next maintenance window". Gate #9d sweeps in the interim continue to use the manual narrative path (fix-round-19 §19.2's "~86 banner-history sites preserved per Gate #9c") — exactly the practice review-round-20 §20.3 raised as ambiguous.

**Why This Matters:**
The Option B framework is now ratified in `.claude/rules/workflow.md`, which is methodology progress. But operationally, no Gate #9d sweep can run `grep -vFf <manifest>` against an empty manifest without false-positive every banner site. The empty-manifest state is **functionally indistinguishable** from no-manifest-at-all for the next Gate #9d sweep operator, who must either (a) re-justify each site narratively (fix-round-19's path), or (b) pre-populate the manifest before sweeping.

This is not a regression vs fix-round-20 (the methodology framework IS valuable) — it is an unfinished closure. LOW would be appropriate if the framework alone closed the originating defect; MEDIUM because the originating defect (operationalized exemption discipline) is not yet operational.

**Suggested Fix:**
Two options:

```bash
# Option A — populate the manifest now (~1-2 hours wall-clock):
PAT="$(grep -oE 'IMPL-0[0-9]{2}' docs/state/impl-plan.md | sort -u | tr '\n' '|' | sed 's/|$//')"
grep -rnE "(${PAT})" MQL5/Experts/PhoenicisNex/ \
  | grep -vE "(deferred to|wires? at|wired at|populated by .* at|gated on|tracked at|pre-|future ) ?\(?" \
  > /tmp/banner-candidates.txt
# Then human-classify each line: real banner OR forward-pointer disguised as banner
# Pre-populate the manifest table with the banner-classified sites + 1-line
# justification each. Engineer attests in the populating fix-round narrative.

# Option B — explicitly re-scope the finding as 2-stage (frame + populate):
#   Move the operational populate task to a tracked IMPL-FIX-* with owner +
#   expiry; close fix-round-20 §20.3 as "framework landed; population tracked
#   under IMPL-FIX-NNN". Avoids the silent deferral.
```

**Level of Effort:** Low-Medium (Option A: 1-2 hours one-shot enumeration; Option B: 5 min to file IMPL-FIX-NNN ticket).

---

### Finding 21.4: 🔵 LOW — IMPL-065 registry row (deferred-ac-registry.md line 65) bundles the **structural-half** assertion (`n[entry_pass] < n[refresh] AND n[entry_pass] > 0`) and the **numeric-half** assertion (avg overhead ≤ 10% NFR-2.1 + Tester wall-clock ≤ 1.5× NFR-2.3) into a single Active row sharing one `Expires=2026-05-19` deadline. If operator session at Tier 1.5 walk batch-3 runs only the numeric drain (`regression_5yr_no_g4.ini`) and skips the structural pre-drain (`tick_latency_smoke.ini`), the registry has no granularity to flag the partial closure.

**Location:**
- File: `docs/state/deferred-ac-registry.md`, Line 65 — IMPL-065 Active row
- Reference: fix-round-20 §20.5 Option B acceptance language ("structural-half assertion is now persistent E-AC residue — drains at the same Tier 1.5 walk batch-3 operator session as the numeric drain")

**Problem:**
The Option B acceptance pattern collapses two distinct deferred drains into one row:
- **Structural drain** — tick_latency_smoke.ini 3-day H4 (~10 min wall-clock); asserts probe topology correctness post-fix-round-17 §17.2
- **Numeric drain** — regression_5yr_no_g4.ini 5-year H4 (~30-60 min wall-clock); asserts NFR-2.1 + NFR-2.3 acceptance signal

These are different `.ini` files, different Tester windows, different acceptance metrics. fix-round-20 §20.5's narrative "drains at the same Tier 1.5 walk batch-3 operator session as the numeric drain" assumes the operator runs both. If the operator runs only the long one (more visible MVP-blocking acceptance signal) and skips the structural pre-drain, the row remains Active for the structural half — but the registry's binary `[x] / Active` state cannot represent partial closure.

**Why This Matters:**
LOW because (a) the closure-discipline outcome of breaking the operator-runtime defer cycle is the right move; (b) both drains share the same operator session boundary; (c) the row's "Risk if missed" column doesn't separately enumerate structural vs numeric risks. But the methodology cost is small: separate row enables cleaner closure tracking; combined row preserves the historical "single E-AC paired bundle" framing per the fix-round-18 narrative.

**Suggested Fix:**
Two options:

```markdown
# Option A — split into two Active rows:
| P4 | IMPL-065 | (numeric) avg overhead ≤ 10% NFR-2.1 + Tester wall-clock ≤ 1.5× NFR-2.3 [log-assertion] |
| P4 | IMPL-065 | (structural) n[entry_pass] < n[refresh] AND n[entry_pass] > 0 [log-assertion]            |

# Option B — keep one row but add explicit tick-boxes in the row's
#    "Deferred reason" column:
#    - [ ] structural drain (tick_latency_smoke.ini)
#    - [ ] numeric drain   (regression_5yr_no_g4.ini)
```

Either makes the partial-closure surface visible at next `/next` Check 5.5 sweep.

**Level of Effort:** Low (~5 min registry edit).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-21.1 | 🟠 HIGH | Bulk-substitution token chosen with internal noun overlap creates grammatical-doubling at every `wires at <token>` / `wired at <token>` / `wire at <token>` site | 21 source files, 34 sites | Ninth iteration of R12→R20 chain. Token must not contain noun-stem ("wiring") that collides with the surrounding verb ("wires/wired"). Cleanup catalog must inspect ≥5 representative call-sites for natural-prose collision before bulk substitution. |
| XS-21.2 | 🟡 MEDIUM | Bin-1 routing comments cite `<class>::<method>` without grep-verifying the destination exists outside banner blocks | `domain/CSlotBase.mqh:66,147` (cite `WireSlots` which has 0 method definitions) | Add Gate #9 clause (f) mandating destination-existence verification + engineer attestation. |
| XS-21.3 | 🟡 MEDIUM | Manifest framework landed without populating data — Gate #9d sweep practically falls back to manual narrative path | `docs/state/comment-history-exemptions.md` (1 placeholder row) | Either populate the ~86 banner sites or file IMPL-FIX-NNN ticket to track populate work as separate closure. |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 21.1 | Bulk-replacement token "Orchestrator wiring path (core/Orchestrator.mqh)" produces grammatical-doubling at 34 sites ("wires at wiring path") — same defect class fix-round-20 §20.1 claimed cleaning up | 🟠 HIGH | repo-wide; representative: `slots/Slot_B.mqh:209,267`, `slots/Slot_BR.mqh:133,147`, `slots/Slot_K.mqh:162,212,219`, `spike/Spike_Slot_BI.mq5:21`, `services/PortfolioState.mqh:278` | ea (cross-cutting) | M (~2-3h; Option A bin-1 reword OR Option B token-rechoose + extended cleanup catalog) |
| 21.2 | Bin-1 hand-fix cites `core/Orchestrator.mqh::WireSlots step 4` — method does NOT exist (only banner-comment hits) | 🟡 MEDIUM | `domain/CSlotBase.mqh:66,147` | ea | Low (~20 min — find SetPipMath actual call site + reword + Gate #9 clause (f)) |
| 21.3 | Comment-history-exemptions manifest is structurally seeded but functionally empty (1 placeholder row) | 🟡 MEDIUM | `docs/state/comment-history-exemptions.md:32-34` | ea-state | Low-Medium (Option A populate ~1-2h; Option B IMPL-FIX-NNN ticket ~5 min) |
| 21.4 | IMPL-065 registry row collapses structural-half + numeric-half drains into one row, no partial-closure visibility | 🔵 LOW | `docs/state/deferred-ac-registry.md:65` | ea-state | Low (~5 min; Option A two rows OR Option B inline tick-boxes) |
| **Cross-Service Total** | | | | | |
| XS-21.1 | Bulk-substitution token noun-overlap defect class | 🟠 HIGH | 21 files, 34 sites | ea | (covered by 21.1) |
| XS-21.2 | Bin-1 routing destination-existence unverified | 🟡 MEDIUM | 2 sites in CSlotBase.mqh | ea | (covered by 21.2) |
| XS-21.3 | Manifest framework landed, data unpopulated | 🟡 MEDIUM | comment-history-exemptions.md | ea-state | (covered by 21.3) |

---

## Phase-5 Mechanical Gate Compliance Check (fix-round-20 itself)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep | ✅ Pass | Re-ran against `docs/state/impl-plan.md` — 0 hits for `deferred to operator-runtime\|deferred per .* precedent\|structurally complete.*deferred\|live verification deferred`. |
| 9a | Originating literal grep | ✅ Pass | `Phase-2 wiring; see docs/state/deferred-ac-registry.md` literal — 0 hits in `MQL5/` + `simulation/` (was 177; surviving hits in `docs/code-review/*` audit history exempted). |
| 9b | Broader-class verb catalog | ⚠️ **NEW DEFECT (Finding 21.1)** | The intent grep `(wire[ds]?|wire) at Orchestrator wiring path` returns **34 hits** in 21 source files — same defect class (grammatical-doubling on bulk substitution) recurred under a new token. Gate #9 clause (a) cleared; clause-equivalent for cleanup-catalog regression NOT specified. |
| 9c | Repo-wide intent grep | ✅ Pass | Surviving Phase-2-wiring literal hits all in `docs/code-review/*` audit history. |
| 9d | Closed-task verb-form catalog (dynamic 68-task list) | ✅ Pass | Re-ran independently: built `IMPL-001|...|IMPL-068` pattern from impl-plan.md → swept `MQL5/` + `simulation/` → 0 hits. Gate #9d clause (e) verified working. |
| 10 | Stash-clean G1 | ✅ Pass | Per fix-round-20 evidence table: production 0/0/3845 ms + wrapper 0/0/3960 ms against committed surface only. |
| 11 | Working-tree clean post-closure | ✅ Pass | `git status --porcelain` returns empty after commit `d8691e4`. |

**Verdict on fix-round-20 mechanical gates:** Gates #1, #9a, #9c, #9d, #10, #11 pass. Gate #9b (broader-class intent grep) is the load-bearing failure mode — the cleanup-catalog approach in fix-round-20 §20.1 Pass 2 missed the prefix-doubling pattern (`wires at <token>`), surfacing as Finding 21.1.

---

## Recommendation

Ready for **fix-round-21**. Priority order:

1. **Finding 21.1 (HIGH)** — re-token OR re-route the 34 grammatical-doubling sites + extend Gate #9d cleanup catalog to require token-collision pre-check. **Block any IMPL-NNN closure until the source tree's prose is grep-clean of `wire[ds]? at .* wiring`.**
2. **Finding 21.2 (MEDIUM)** — reword the 2 `WireSlots step 4` cites with verified destinations + add Gate #9 clause (f) (destination-existence verification + engineer attestation).
3. **Finding 21.3 (MEDIUM)** — choose Option A (populate ~86 sites now) OR Option B (file IMPL-FIX-NNN ticket). Either is acceptable; Option B preferred if operator session bandwidth tight.
4. **Finding 21.4 (LOW)** — split IMPL-065 registry row OR add inline structural/numeric tick-boxes (5 min).

> **Reviewer note (R12→R21 recurrence chain — 9th iteration):**
> The chain has now been broken at one axis (catalog dynamism — Gate #9d clause (e) confirmed clean by independent dynamic sweep against the live 68-task list) and continues to break at another (destination correctness — bulk-substitution token noun-overlap, hand-fix dangling-method-pointer). The pattern across 9 rounds is consistent: each fix-round resolves the defect surface the prior reviewer cited and introduces a new surface manifestation of the same root cause (mechanical sweep that doesn't pre-validate against the prose context it lands in). The chain will iterate to R22+ until **both** axes are addressed:
> - **Catalog axis** — Gate #9d clause (e) (✅ landed in fix-round-20)
> - **Destination axis** — Gate #9 clause (f) (Finding 21.2 Suggested Fix) + cleanup-catalog token-collision pre-check (Finding 21.1 Suggested Fix)

> **Plan Staleness Sentinel post-R21:** unchanged from R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor to fix-round-20). Sentinel resets on next P4 closure (next-after-IMPL-068 work).

## End of Review Round 21
