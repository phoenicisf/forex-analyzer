# Code Review Round 22

| Field | Value |
|-------|-------|
| **Round** | 22 |
| **Target** | `all` — operator invoked `/impl-review review-round-22` after fix-round-21 closure (commit `54fd9a3`). Verify-only sweep per fix-round-21 Recommendation. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/` + `docs/state/*` + `.claude/rules/*`. Working tree at session start: clean. |
| **Date** | 2026-05-09 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) fix-round-21 §21.1 Option B regex pass — does `(wire[ds]?) through core/Orchestrator.mqh` close the grammatical-doubling defect class without introducing a new prose-collision pattern? (b) §21.2 destination-existence verification — are the 2 CSlotBase.mqh hand-fix sites grep-clean against the cited `OnInit Phase B post-RegisterAll loop line 365-369`? (c) §21.3 Option B — is IMPL-FIX-004 row schema-conformant + manifest header narrative re-pointed to the tracked ticket? (d) §21.4 IMPL-065 inline drain checklist — does the registry row now expose partial-closure surface? (e) Phase 5 mechanical-gate compliance for fix-round-21 itself (#1, #5, #6, #9 a-g, #10, #11). (f) **R12→R21 chain termination test** — does R22's broader-class sweep find a 10th-iteration recurrence on the new `through core/Orchestrator.mqh` token? |
| **Plan Staleness Sentinel** | 0 closures since R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor to fix-round-21). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 2 |
| **Total**| **2** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No new boundary surface. Symbol whitelist + atomic-write + no DLLs invariants intact. |
| 2 | Business Logic Correctness | ✅ Pass | Comment-only sweep + state/registry hygiene; production runtime unchanged. fix-round-21 G1 PASS (4142 ms) per closure narrative. |
| 3 | Error Handling | ✅ Pass | No regression. |
| 4 | Performance | ✅ Pass | XS-17.1 hot-path rule unchanged. |
| 5 | Over-Engineering | ✅ Pass | Option B (registry-tracked exemption populate via IMPL-FIX-004) follows existing PhoenicisNex registry-as-SoT pattern; no premature abstraction. |
| 6 | Cross-Service Consistency | ✅ Pass | **R12→R21 chain terminated at the catalog axis (R20 §20.2) AND destination axis (R21 §21.1 + §21.2).** Independent verification this round: `grep -rcnE "(wire[ds]?\|wire) at Orchestrator wiring path" MQL5/Experts/PhoenicisNex/` → **0 hits** ✅; `grep -rcnE "wire[ds]? at .* wiring" MQL5/Experts/PhoenicisNex/` → **0 hits** ✅; `grep -rlE "wire[ds]? through core/Orchestrator" MQL5/Experts/PhoenicisNex/` → **21 files / 34 sites** ✅ (matches fix-round-21 §21.1 sweep claim). Sampled 5 representative through-form sites (Slot_B.mqh:209,267, Slot_BR.mqh:133,147, Spike_Slot_BI.mq5:21) — natural-prose flow clean; no internal-noun collision detected (`through` is a preposition that does not double with any verb in the surrounding catalog). |
| 7 | Test Coverage Gaps | ✅ Pass | tick_latency_smoke.ini per-slot pin unchanged; IMPL-065 inline drain checklist visible to `/next` Check 5.5. |
| 8 | Architecture Compliance | ✅ Pass | No ADR drift. CSlotBase.mqh:65-68 + :148-151 comment now points at concrete OnInit Phase B post-RegisterAll loop verified at `core/Orchestrator.mqh:364-369` (independent grep this round confirms `for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip);` at line 365-368 — citation accurate). |
| 9 | Technical Design Compliance | ✅ Pass | No api-spec / TD-02..04 drift. |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded-loop pathology. |
| 11 | Empirical AC Closure | ✅ Pass | IMPL-065 row now exposes structural/numeric drain checklist; IMPL-FIX-004 row schema-conformant (Owner=Kritsana, Opened=2026-05-05, Expires=2026-05-19, Risk=manual-narrative-fallback ambiguity). No `[x]`+"deferred to operator-runtime" pattern reintroduced. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface; Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1 callout. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer per CLAUDE.md §7b. |

---

## Findings

### Finding 22.1: 🔵 LOW — bin-1 routing comments in `domain/CSlotBase.mqh` embed hardcoded source-line numbers (`line 365-369`) that become brittle on any future edit to `core/Orchestrator.mqh` ahead of the cited loop. The two new comment blocks (`:68` and `:150`) cite the SetPipMath wiring loop by physical line range rather than by a grep-stable symbolic anchor. The destination-existence verification (R21 Gate #9 clause (f)) is correct *today*, but inserting/deleting lines anywhere in `OnInit` Phase A or pre-loop Phase B will silently desync the cite without any compile-time signal.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, Line 68 — `(line 365-369: \`for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip)\`).`
- File: `MQL5/Experts/PhoenicisNex/domain/CSlotBase.mqh`, Line 150 — `post-RegisterAll loop at line 365-369, via per-slot SetPipMath())`
- Reference: fix-round-21 §21.2 destination-existence-verification narrative; cited live at `core/Orchestrator.mqh:364-369` (verified accurate this round)

**Code:**
```mql5
// domain/CSlotBase.mqh:65-71
   //--- Round-06 06.1: pip-arithmetic helper (ea.md mandate). Composition
   //    Root calls SetPipMath() on every registered slot in
   //    core/Orchestrator.mqh::OnInit Phase B post-RegisterAll loop
   //    (line 365-369: `for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip)`).
   //    When NULL the protected helpers fall back to inline 5/3-digit
   //    detection (single fallback site eliminates the 19-way drift
   //    Finding 06.1 reported).

// core/Orchestrator.mqh:364-369  (cited destination)
   // Round-06 06.1 — wire CPipMath into every slot post-RegisterAll
   for(int i = 0; i < m_registry.Count(); i++)
     {
      CSlotBase *s = m_registry.Get(i);
      if(s != NULL) s.SetPipMath(m_pip);
     }
```

**Problem:**
The R12→R21 chain's destination-correctness axis was closed by mandating that bin-1 routing comments cite verifiable destinations. Gate #9 clause (f) requires `grep -nE '<method>\\s*\\(' <file>` returning ≥1 non-banner site — which is satisfied today by the `SetPipMath` cite. But the comment also embeds a physical line range (`365-369`), which is **NOT grep-stable** — it's an integer anchor that the engineer must hand-update on every edit to `Orchestrator.mqh` that touches the file ahead of line 365. Gate #9 (f) does not explicitly require that anchor to be grep-stable; it only requires the cited symbol to exist outside banner blocks.

A future edit (e.g., adding a service initialization step at Phase A:285 or extending Phase B Step 6 indicator validation) shifts the loop to `367-371`, rendering the comment silently incorrect. The next reviewer following the cite will find the loop, recognize the line-number drift, and route this back through review→fix cycles for re-anchoring. This is the **next-finer-granularity** of the destination-correctness defect class: the destination's *identity* is correct, but the destination's *coordinates* are brittle.

**Why This Matters:**
LOW (not MEDIUM) because (a) the cited symbol `SetPipMath` is itself grep-stable and recoverable from the surrounding prose even when the line range desyncs; (b) the closure-discipline outcome (destination existence verified) is preserved; (c) the brittleness only manifests on future Orchestrator.mqh edits, not on current state. But the methodology cost is small: substituting `(line 365-369: ...)` with `(loop body shown at the "wire CPipMath into every slot post-RegisterAll" comment marker)` makes the cite grep-stable AND human-readable AND drift-immune.

This is the same anti-pattern as embedding `IMPL-053+` literals in slot comments (R12→R20 chain): the literal is correct at edit time but doesn't survive context drift. The destination-axis cure is "cite the symbol", not "cite the line range".

**Suggested Fix:**
Re-author the 2 comment blocks to cite the grep-stable comment marker instead of the integer range:

```mql5
// domain/CSlotBase.mqh:65-71  (revised)
   //--- Round-06 06.1: pip-arithmetic helper (ea.md mandate). Composition
   //    Root calls SetPipMath() on every registered slot in
   //    core/Orchestrator.mqh::OnInit Phase B post-RegisterAll loop
   //    (grep marker: "wire CPipMath into every slot post-RegisterAll";
   //    body: `for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip)`).

// domain/CSlotBase.mqh:148-154  (revised)
   //--- Round-06 06.1 — pip helpers shared by 19 derived slots. When
   //    m_pip is wired (set by core/Orchestrator.mqh::OnInit Phase B
   //    post-RegisterAll loop — grep marker "wire CPipMath into every
   //    slot post-RegisterAll", via per-slot SetPipMath()) the helpers
   //    route through CPipMath ...
```

And add to `.claude/rules/workflow.md § Phase 5 Gate #9` a clause **(h)**:
> "Bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor — drift on file edits silently desyncs the cite without compile-time signal."

**Level of Effort:** Low (~10 min — reword 2 comment blocks + add Gate #9 clause (h)).

---

### Finding 22.2: 🔵 LOW — `spike/Spike_Slot_BI.mq5:21` banner-comment now reads `E-AC smoke + G4 attestation wire through core/Orchestrator.mqh` — the bare-verb `wire` (vs the body-code `wired`/`wires`) parses as a clipped noun-phrase fragment in the banner context. Grammatical, but stylistically inconsistent with the 33 other through-form sites that use `wired`/`wires`. Cosmetic; the post-fix prose flows differently in banner-fragment context vs sentence-prose context.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5`, Line 21
- Reference: fix-round-21 §21.1 sweep — bare-verb `wire` form was matched by `wire[ds]?` regex (the `[ds]?` makes the suffix optional, so `wire` itself qualifies)

**Code:**
```mql5
// spike/Spike_Slot_BI.mq5:19-22
//| harness. IMPL-018 precedent: G2-G4 deferred; G1 + SelfTest = bar. |
//| E-AC smoke + G4 attestation wire through core/Orchestrator.mqh           |
//|   (RiskManager::OpenOrder) + 60-day Tester run with B+BI active   |
```

**Problem:**
fix-round-21 §21.1 Option B regex `(wire[ds]?) through core/Orchestrator.mqh` correctly captures `wire`/`wired`/`wires`. The 33 sentence-prose sites read cleanly because the surrounding prose is a clause (e.g., `RiskManager::OpenOrder wired through core/Orchestrator.mqh.`). The single banner site (Spike_Slot_BI.mq5:21) is a banner-comment fragment — `E-AC smoke + G4 attestation wire through core/Orchestrator.mqh` parses as either (a) noun phrase "[the] G4 attestation wire" (grammatically valid but semantically odd — a "wire" is a thing, but the surrounding bullets suggest a verb), or (b) elliptical verb "wire" (imperative or infinitive: "[is to] wire through core/Orchestrator.mqh"). The original pre-fix-round-19 wording cycle used `wire at Orchestrator wiring path (...)` which had the doubling defect; the new wording trades doubling for ambiguity.

This is purely cosmetic — banner comments are pipe-bracketed fragments by convention, and the reader can decode either interpretation as "the smoke + attestation paths route through Orchestrator's RiskManager wiring". Prose readability LOW because banner conventions allow fragments.

**Why This Matters:**
LOW because banner comments are by convention sentence-fragmented (the 80-char `|`-bracket format precludes full sentences). The cosmetic inconsistency surfaces only when reading all 34 through-form sites in sequence; it doesn't break audit signal. Including this finding because Gate #9 clause (g) (token-collision pre-check) explicitly mentions inspecting "≥5 representative call-sites" — the banner-fragment context is a 6th category not represented in the sentence-prose sample, and would benefit from explicit token-class differentiation in the methodology.

**Suggested Fix:**
Two options (both Low effort):

```mql5
// Option A — reword the banner to use a clean noun phrase:
//| E-AC smoke + G4 attestation wiring through core/Orchestrator.mqh           |

// Option B — pluralize the verb to match body-code convention:
//| E-AC smoke + G4 attestation wires through core/Orchestrator.mqh           |
```

Option A is preferred: `wiring` reads as a gerund/noun phrase in banner context, removing verb-vs-noun ambiguity. Note this re-introduces the `wiring` substring that fix-round-21 §21.1 Option B regex was chosen to avoid — but only in *one* banner site, not in 34 sentence-prose sites, so the doubling-defect class doesn't recur (the surrounding prose `attestation wiring through` is a noun phrase + preposition, not verb + preposition).

**Level of Effort:** Low (~2 min — single banner edit; Option A or B per stylistic preference).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| (none) | — | — | — | R12→R21 chain status: **terminated at both axes** (catalog via Gate #9d clause (e); destination via Gate #9 clauses (f) + (g)). R22 verify-only sweep finds no new structural defect class. Findings 22.1 + 22.2 are next-finer-granularity surface details, not chain recurrences. |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 22.1 | Bin-1 routing comments embed hardcoded line range (`line 365-369`) instead of grep-stable comment-marker anchor — brittle on future Orchestrator.mqh edits | 🔵 LOW | `domain/CSlotBase.mqh:68,150` | ea | Low (~10 min — reword 2 comment blocks + Gate #9 clause (h)) |
| 22.2 | Spike_Slot_BI.mq5:21 banner reads `attestation wire through ...` (bare-verb) — grammatically clipped vs the 33 sentence-prose sites that use `wired`/`wires` | 🔵 LOW | `spike/Spike_Slot_BI.mq5:21` | ea-spike | Low (~2 min — single banner edit) |

---

## Phase-5 Mechanical Gate Compliance Check (fix-round-21 itself)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | ✅ Pass | Re-ran independently — `grep -cnE "deferred per .* precedent\|deferred to operator-runtime\|structurally complete.*deferred\|live verification deferred" docs/state/impl-plan.md` → 0 hits. |
| 2 | TL;DR ↔ registry recount | ✅ Pass | impl-plan.md line 8 reads `49 Active rows total` + `1 P5 row (IMPL-FIX-004)` enumeration. Registry P-row count: 54 (49 Active + 5 Resolved breakdown matches narrative). |
| 3 | TL;DR ↔ matrix denominator | ✅ Pass | No Phase × Size matrix change this round (no IMPL-NNN closure). |
| 4 | Sentinel counter increment | n/a | No IMPL-NNN closure since R09 advisory; sentinel unchanged (correctly). |
| 5 | overview.md sync | ✅ Pass | Impl Plan row Last Updated 2026-05-05 → 2026-05-09 + R21 status paragraph append + 48→49 registry-count append visible. |
| 6 | File integrity (post-Edit-batch) | ✅ Pass | `grep -c "^## End of Plan" docs/state/impl-plan.md` → 1; tail clean. |
| 7 | Phase Status Snapshot Notes sweep | n/a | No Phase Status row Notes invalidated by this round. |
| 8 | Narrative-section freshness sweep | n/a | No Open Risks / Next Best Action invalidated by this round. |
| 9a | Originating literal grep | ✅ Pass | `(wire[ds]?\|wire) at Orchestrator wiring path` source tree → **0 hits**. |
| 9b | Broader-class doubling regex | ✅ Pass | `wire[ds]? at .* wiring` source tree → **0 hits**. |
| 9c | Repo-wide intent grep | ✅ Pass | Surviving "Orchestrator wiring path" hits all in `docs/code-review/*` audit history (preserved per Gate #9c convention). |
| 9d | Closed-task verb-form catalog (dynamic 68-task list) | ✅ Pass | Carried from fix-round-20 §20.2 + verified clean against the 68-task list (no closures since). |
| 9e | Closed-task list dynamic derivation | ✅ Pass (mechanism unchanged) |
| 9f | Destination-existence verification (NEW R21) | ✅ Pass | `WireSlots` removed from `domain/CSlotBase.mqh`; new pointer cites `OnInit Phase B post-RegisterAll loop` — verified independently this round at `core/Orchestrator.mqh:364-369` (`for(i=0; i<m_registry.Count(); i++) s.SetPipMath(m_pip);`). |
| 9g | Token-collision pre-check (NEW R21) | ✅ Pass | New through-form `(wire[ds]?) through core/Orchestrator.mqh` inspected at 5 representative sites — no internal-noun collision in sentence-prose sites; bare-verb banner site (Spike_Slot_BI.mq5:21) raises Finding 22.2 (cosmetic, LOW). |
| 10 | Stash-clean G1 (R16) | ✅ Pass | Working tree clean (`git status --porcelain` = 0 lines) means committed surface == working surface — implicit stash-clean equivalence. |
| 11 | Working-tree clean post-closure | ✅ Pass | `git status --porcelain \| wc -l` → **0** ✅. fix-round-21 commit `54fd9a3` lands all 26 files cleanly. |

**Verdict on fix-round-21 mechanical gates:** ALL gates (#1, #2, #3, #5, #6, #9 a-g, #10, #11) pass. Gates #4, #7, #8 correctly n/a (fix-round, not IMPL-NNN closure). The R21-derived clauses (f) + (g) themselves verified working as termination mechanism for the R12→R21 chain.

---

## Recommendation

Ready for **fix-round-22** OR **chain-termination acceptance**. Priority order:

1. **Finding 22.1 (LOW)** — re-anchor 2 CSlotBase.mqh comment blocks from physical line range to grep-stable comment marker; add Gate #9 clause (h) (line-anchor brittleness rule). Methodology gain: closes the next-finer-granularity destination-correctness surface (line drift) before any future Orchestrator.mqh edit triggers it.
2. **Finding 22.2 (LOW)** — single banner edit at Spike_Slot_BI.mq5:21; cosmetic stylistic alignment with 33 other through-form sites.

Both findings are LOW; operator may **accept** as residual cosmetic surface and close the R12→R22 chain at this round, OR **fix-round-22** to land the methodology strengthening (Gate #9 clause (h)) for forward-looking drift immunity. Recommendation: fix-round-22 to land the Gate #9 clause (h) — the cost is ~12 min wall-clock and the methodology gain (line-anchor brittleness rule) prevents the next chain iteration from manifesting on Orchestrator.mqh edits.

> **Reviewer note (R12→R22 recurrence chain — verify-only outcome):**
> R22 is the first round in the chain since R12 (10 rounds) where the broader-class intent grep returns **0 hits on the source tree** AND no new defect class manifests on the substituted token. The chain has now been verifiably terminated at:
> - **Catalog axis** — Gate #9d clause (e) (closed-task list dynamic derivation; ✅ landed in fix-round-20)
> - **Destination axis** — Gate #9 clauses (f) destination-existence + (g) token-collision pre-check (✅ landed in fix-round-21)
>
> Findings 22.1 + 22.2 are **NOT** chain recurrences — they are next-finer-granularity surfaces (line-anchor brittleness; banner-prose cosmetic inconsistency) that the methodology framework correctly classified as LOW. The structural failure mode that drove R12→R21 (mechanical sweep without prose-context validation) is no longer surfacing.
>
> **Plan Staleness Sentinel post-R22:** unchanged from R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor to fix-round-21). Sentinel resets on next P4 closure (next-after-IMPL-068 work).

## End of Review Round 22
