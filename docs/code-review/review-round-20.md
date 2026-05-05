# Code Review Round 20

| Field | Value |
|-------|-------|
| **Round** | 20 |
| **Target** | `all` — operator invoked `/impl-review` (no arg) after fix-round-19 closure. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/`. HEAD = `660c24d`. Working tree at session start: clean. |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) fix-round-19 §19.1 replacement-token integrity — does the new "Phase-2 wiring; see docs/state/deferred-ac-registry.md" pointer actually route correctly? Does it survive the same R12→R19 recurrence-chain test it claims to break? (b) fix-round-19 §19.2 Partial Accept — verify the verb-form catalog sweep against the **current** closed-task list (IMPL-060, IMPL-062 etc. closed 2026-05-04/05); (c) fix-round-19 §19.3 ulong promotion symmetry on TradeJournal::m_latency_count; (d) fix-round-19 §19.4 `[TesterInputs]` block fitness against the asserted invariant; (e) Dim #11 Empirical AC Closure spot-check on fix-round-19 G3 deferral. |
| **Plan Staleness Sentinel** | 0 closures since R09 advisory (this is the immediate successor; no IMPL-NNN closures since fix-round-19). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **5** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No new boundary surface. Symbol whitelist + atomic-write + no DLLs invariants intact. |
| 2 | Business Logic Correctness | ✅ Pass | TradeJournal latency-count promotion to ulong applied symmetrically with TickLatencyProbe per fix-round-19 §19.3. No semantic delta on hot path. |
| 3 | Error Handling | ✅ Pass | No regression vs fix-round-18 §18.7 (FILE_BIN sidecar + inline JSON fallback intact). |
| 4 | Performance | ✅ Pass | XS-17.1 hot-path rule consistently applied. |
| 5 | Over-Engineering | ✅ Pass | Replacement-token sweep is mechanical comment-only diff. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **20.3 MEDIUM** — the fix-round-19 §19.2 Partial-Accept narrative claims the verb-form catalog (`deferred to | wires? at | wired at | populated by .* at | pre- | future`) returns 0 hits against `IMPL-(006/007/018/042/043/053)` — but the catalog was again pinned to a closed-enumeration of task IDs *as of the cited fix-round-18 sites*. Two further closed-task forward-pointers survive in the source tree post-660c24d: `slots/Slot_D.mqh:21` (`deferred to IMPL-062` — closed 2026-05-05) and `spike/Spike_Orchestrator.mq5:12` (`deferred to IMPL-060` — closed 2026-05-04). This is the seventh iteration of the R12→R13→R14→R16→R18→R19→**R20** chain — exactly the failure mode fix-round-19 §19.2 claimed to break by "Gate #9d verb-form catalog". The catalog is closed-enumeration; the defect class (any closed-task forward-pointer) is open-set. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **20.4 MEDIUM** — `tick_latency_smoke.ini` `[TesterInputs]` block (added by fix-round-19 §19.4) pins **integer thresholds + window durations** for the time gates (`InpMorningWindowMinutes=5`, `InpHolidayStartMonth=12`, etc.) — these match source defaults, so they protect against operator-`.set`-file drift. But the asserted invariant `n[entry_pass] < n[refresh] AND n[entry_pass] > 0` actually depends on the **window choice** (2024.01.02–2024.01.05 crossing the holiday window AND a Monday morning AND ≥3 daily morning windows). The block does not pin **`InpEnableSlotS` / `InpEnableSlotC` / per-slot enables** — and the entry-pass branch is bypassed if NO slots are enabled (entry-pass loop iterates over enabled slots only). Operator inheriting a stale per-slot toggle could see `n[entry_pass] == 0` even under correct gate firing → false-FAIL classified as gate regression. |
| 8 | Architecture Compliance | ✅ Pass | No ADR drift introduced by fix-round-19. |
| 9 | Technical Design Compliance | ✅ Pass | TickLatencyProbe + TradeJournal field types now consistent with TD-04 §3 schema (numeric counters in `latency-report-*.json` are unsigned). |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded-loop pathology newly introduced. |
| 11 | Empirical AC Closure | ⚠️ Finding | **20.5 LOW** — fix-round-19 deferred G3 of IMPL-FIX-003 a **second time** (Verdict 19.5 = Defer "sandbox session cannot drive MT5 Strategy Tester end-to-end"). The premise of fix-round-18 §18.5 + review-round-19 §19.5 was to **break** the operator-runtime defer cycle; fix-round-19 §19.5 reproduces it for the third consecutive round. The wrapper compiles, the `.ini` pins inputs, and the rationale in fix-round-19 §19.5 is honest about the sandbox limitation — but the recurrence is structural: if operator session keeps slipping, the tick-latency instrument's correctness remains unverified at IMPL-065 paired E-AC structural half indefinitely. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface; Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1 callout. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer. |

---

## Findings

### Finding 20.1: 🟠 HIGH — fix-round-19 §19.1 replacement token `Phase-2 wiring; see docs/state/deferred-ac-registry.md` is semantically wrong (Phase-2 in PhoenicisNex = post-MVP cloud features, not Phase 1 P4 wiring) AND produces garbled prose at several sites — 158 occurrences across 64 files now embed a **mis-routing pointer** in source comments. Same defect class as the synthetic token it replaced; new token has a stable destination but the destination does not carry the routing entries that the comments now claim it does.

**Location:**
- 158 hits across 64 files (41 source + 22 test-config + 1 audit history); representative sites:
  - `services/PortfolioState.mqh:176` — `s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at Phase-2 wiring; see docs/state/deferred-ac-registry.md`
  - `domain/CSlotBase.mqh:66` — `//    Root (Phase-2 wiring; see docs/state/deferred-ac-registry.md) calls SetPipMath(); when NULL the protected`
  - `domain/CSlotBase.mqh:146` — `//    m_pip is wired (Phase-2 wiring; see docs/state/deferred-ac-registry.md Composition Root) the helpers route`
  - `domain/EnumTypes.mqh:118` — `//        Phase-2 wiring; see docs/state/deferred-ac-registry.md / IMPL-062 owner: Orchestrator::OnInit Phase B`
  - `domain/SlotState.mqh:38` — `// Populated by PortfolioState OnTradeTransaction handler at Phase-2 wiring; see docs/state/deferred-ac-registry.md.`
  - `slots/Slot_BI.mqh:276` — `//--- Phase-1 stub: logger-only milestone; broker close wires at Phase-2 wiring; see docs/state/deferred-ac-registry.md per ea.md.`
  - `spike/Spike_Slot_B.mq5:17` — `//| E-AC smoke wires at Phase-2 wiring; see docs/state/deferred-ac-registry.md (RiskManager::OpenOrder)  |`
- Service: ea (cross-cutting; 41 source files + 22 `.ini` files)
- Reference: review-round-19 §19.1 Suggested Fix (three explicit bins: live ref / Pending OAR / explicit no-writer note); BA `01 § 6.2 Won't Permanent` + `docs/state/deferred-ac-registry.md` baseline note line 7 ("Registry is initialized empty + remains empty unless **Phase 2 cloud journal / Telegram / multi-account triggers added**"); fix-round-19 §19.1 narrative ("an outward pointer to the canonical live-tracked-work surface")

**Code:**
```mql5
// services/PortfolioState.mqh:176
      s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at Phase-2 wiring; see docs/state/deferred-ac-registry.md

// domain/CSlotBase.mqh:65-68 (sentence runs across the substituted token)
   //--- Round-06 06.1: pip-arithmetic helper (ea.md mandate). Composition
   //    Root (Phase-2 wiring; see docs/state/deferred-ac-registry.md) calls SetPipMath(); when NULL the protected
   //    helpers fall back to inline 5/3-digit detection (single fallback
   //    site eliminates the 19-way drift Finding 06.1 reported).

// domain/EnumTypes.mqh:117-119 (sentence runs across the substituted token)
//      • Phase 2 — production wire on live attach is deferred to
//        Phase-2 wiring; see docs/state/deferred-ac-registry.md / IMPL-062 owner: Orchestrator::OnInit Phase B
//        step 1 should call m_validator.RunDomainSelfTests() BEFORE
```

**Problem:**
fix-round-19 §19.1 chose the new replacement string `Phase-2 wiring; see docs/state/deferred-ac-registry.md` as "an outward pointer to the canonical live-tracked-work surface" — but this is wrong on **three independent axes**:

1. **"Phase-2" is the wrong namespace.** In PhoenicisNex vocabulary, "Phase 2" = post-MVP cloud features (cloud journal sync / Telegram / multi-account) per BA `01 § 6.2 Won't Permanent` + the deferred-ac-registry baseline note line 7. The actual content these comments referred to was **Phase 1 P4 work** (IMPL-053+ Orchestrator wiring, OnTradeTransaction handler, RiskManager::OpenOrder wiring) — and that work is now **landed and closed** as of 2026-05-04/05 (IMPL-053..060 closed; OnTradeTransaction wired at `core/Orchestrator.mqh:218` per fix-round-10 §10.3, confirmed by header banner line 51 `WIRED (fix-round-10 § 10.3 + IMPL-060 entry .mq5)`). The comment is now telling the reader "this wires at the Phase-2 (cloud) milestone" when in fact the writer **already exists in Phase 1**.

2. **The destination does not carry the routing.** `docs/state/deferred-ac-registry.md` is structured as an Active table of E-AC residue: `Phase | Task | E-AC text | Evidence-kind | Deferred reason | Owner | Opened | Expires | Risk if missed`. It tracks **deferred Acceptance Criteria** (e.g., "Smoke 60-day backtest with G + G2 active → CommentParser correctly disambig…"), not "where does the writer for `last_open_lot` live". A reader following the new pointer for `services/PortfolioState.mqh:176` arrives at the registry and finds **no entry** about `last_open_lot` writers. The pointer is a dangling link to a real-but-irrelevant document.

3. **Several substitutions produce ungrammatical prose.** The fix was a binary-safe Perl one-liner per fix-round-19 narrative — and it landed mid-sentence at multiple sites:
   - `domain/CSlotBase.mqh:66` reads literally "Composition Root (Phase-2 wiring; see docs/state/deferred-ac-registry.md) calls SetPipMath()" — the parenthetical was originally identifying the writer (`Orchestrator/Composition Root`), but the substitution now injects routing instructions inside the parenthetical that was naming the writer.
   - `domain/CSlotBase.mqh:146` reads "When m_pip is wired (Phase-2 wiring; see docs/state/deferred-ac-registry.md Composition Root) the helpers route" — token-plus-stale-tail concatenation produces unparseable English.
   - `domain/SlotState.mqh:38` reads "Populated by PortfolioState OnTradeTransaction handler at Phase-2 wiring; see docs/state/deferred-ac-registry.md." — the OnTradeTransaction handler **already exists** at `core/Orchestrator.mqh::OnTradeTransaction` (line 218); bin-1 routing was prescribed by review-round-19 §19.1 Suggested Fix. The replacement misroutes.
   - `spike/Spike_Slot_B.mq5:17` reads "E-AC smoke wires at Phase-2 wiring; see docs/state/deferred-ac-registry.md (RiskManager::OpenOrder)" — "wires at Phase-2 wiring" is a doubled-up noun phrase; **and** RiskManager::OpenOrder already exists in Phase 1 (P2 closure).

This produces strictly worse audit signal than the synthetic-token fix-round-19 just purged: the synthetic token at least said "this comment used to point somewhere; we deleted the pointer". The new token says "this comment points to Phase-2 wiring at the deferred-ac-registry" which is **factually false** in two ways: there is no Phase-2 wiring (the wiring is Phase 1; landed), and the registry does not contain the routing.

**Why This Matters:**
The R12→R19 chain claimed to be broken at the **destination-stability** level by fix-round-19 ("an outward pointer that survives any future fix-round renumbering"). What broke is destination *naming*; what survives is the original audit-trail-integrity defect that review-round-18 §18.1 raised — a future engineer reading any of the 158 sites still cannot determine: (i) where the actual writer lives now, (ii) whether the writer exists or is still TODO, (iii) which task tracks the outstanding work. They follow the pointer to `deferred-ac-registry.md`, search for `last_open_lot` (or `m_pip` or `OnTradeTransaction`), find nothing, and back-deduce from fix-round-19 §19.1 narrative — the same dead-end trail the synthetic token produced.

The chain has now had **eight iterations** (R12→R13→R14→R16→R18→R19→**R20**) — every iteration the catalog of token strings expands but the underlying defect class (comment routing destroyed during sweep instead of pointing to live writers per the original Suggested Fix bin-1) survives.

**Suggested Fix:**
Re-execute the §18.1/§19.1 sweep with the original three-bin routing per review-round-18 §18.1 Suggested Fix (NOT a fourth blanket-replacement bin). Concrete plan per representative site:

```bash
# bin 1 — writer exists at a known site (most of the 158 sites; Phase 1 wiring landed):
#   replace with file-and-line pointer to the actual writer.
#
#   E.g., services/PortfolioState.mqh:176 → "// last_open_lot populated by
#         core/Orchestrator.mqh::OnTradeTransaction (fix-round-10 §10.3) calling
#         CPortfolioState::OnTradeTransaction"
#
#   E.g., slots/Slot_BI.mqh:276 → "// Phase-1 stub: logger-only milestone;
#         broker close handled by services/RiskManager.mqh::CloseOrder (P2 IMPL-041)"
#
#   E.g., domain/CSlotBase.mqh:66 → "// Composition Root (core/Orchestrator.mqh
#         WireSlots step 4) calls SetPipMath()"
#
# bin 2 — operator action required (env-var / set-file / out-of-band step):
#   register Pending row in docs/state/operator-action-registry.md (NB: this
#   registry currently has zero rows; create if first occurrence).
#
# bin 3 — no writer + no Pending action; default-zero-forever Phase 1:
#   delete the misleading provenance comment + add explicit "default zero;
#   no writer in Phase 1; will be wired at Phase 2 cloud journal extension"
#   (one line — only when the comment is literally about a Phase 2 trigger,
#   which is the case for ZERO of the 158 sites at the moment).
```

Then update `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` with a forbidden-pattern grep targeting **routing-by-pointer-only**:

```bash
# Must return 0 hits in source tree (audit-history files excluded per Gate #9c):
grep -rcnE "Phase-2 wiring; see docs/state/deferred-ac-registry\.md" \
     MQL5/Experts/PhoenicisNex/  simulation/headless-tests/   # → 0
```

And add the meta-rule: "Comment-routing replacements MUST point to a **specific file:line** (or `<class>::<method>`) where the writer/wiring lives, not to a registry/audit document. A registry pointer is a routing instruction OF LAST RESORT used only when (a) the writer genuinely does not exist yet AND (b) a Pending OAR row tracks it."

**Level of Effort:** Medium (~3-4 hours wall-clock for 158 sites; per-site bin-1/2/3 routing decision + rule update; no compile risk — comments only).

---

### Finding 20.2: 🟠 HIGH — fix-round-19 §19.2 Partial-Accept narrative claims the verb-form catalog returns 0 hits against `IMPL-(006/007/018/042/043/053)` — but the catalog is closed-enumeration of task IDs cited at fix-round-18 sites; two further closed-task forward-pointers survive at `slots/Slot_D.mqh:21` (`deferred to IMPL-062`) and `spike/Spike_Orchestrator.mq5:12` (`deferred to IMPL-060`). Both target tasks were closed 2026-05-04/05; the sweep was scope-narrower than the defect class for the **eighth consecutive iteration**.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_D.mqh`, Line: 21 — `//|     (real ForcePendingActionOrder logic deferred to IMPL-062     |`
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_Orchestrator.mq5`, Line: 12 — `//| Therefore live OnInit/OnTick exercise is deferred to IMPL-060     |`
- Service: ea (cross-cutting)
- Reference: `docs/state/impl-plan.md` TL;DR confirms IMPL-060 closed 2026-05-04 (commit `277cdb2` parallel batch), IMPL-062 closed 2026-05-05 (commit `277cdb2`); fix-round-19 §19.2 attestation grep `(deferred to|wires? at|wired at|populated by .* at|future ) ?\(?IMPL-(006|007|018|042|043|053)\b` returned 0 hits — but the regex literal task-ID alternation `IMPL-(006|007|018|042|043|053)` does not match `IMPL-060` or `IMPL-062`.

**Code:**
```mql5
// slots/Slot_D.mqh:18-22 — file header
//| BR-7.1 force-pending wrapper (D as 4-line wrapper of C's force-      |
//| pending workflow; shares MagicCD=200; deferred-call helper for       |
//| Slot C's `ForcePendingDirection` workflow).                          |
//|     (real ForcePendingActionOrder logic deferred to IMPL-062     |
//|      per IMPL-019 Cdeferral chain).                                  |

// spike/Spike_Orchestrator.mq5:10-14 — file header
//| Spike harness for COrchestrator. Phase 1 is a header-only spike     |
//| that exercises the WireServices NULL-check on heap allocs.          |
//| Therefore live OnInit/OnTick exercise is deferred to IMPL-060     |
//| (entry .mq5 thin wrapper) when COrchestrator goes from spike to     |
//| production wiring path.                                              |
```

**Problem:**
Per `docs/state/impl-plan.md` TL;DR + Phase Status Snapshot:
- **IMPL-060** (P4 entry .mq5 thin wrapper) — **CLOSED 2026-05-04** (`PhoenicisNex.mq5` 87 LOC; G1 PASS; 3/3 S-AC + 2/2 E-AC `[x]`)
- **IMPL-062** (P4 Bucket A regression authoring) — **CLOSED 2026-05-05** (commit `277cdb2`; G1 PASS both branches; 3/3 S-AC `[x]` + 2 E-AC deferred paired bundle)

Yet the source tree carries forward-pointer comments to these closed tasks. The fix-round-19 §19.2 attestation grep (line 70-73 of `fix-round-19.md`) was:

```
grep -rE "(deferred to|wires? at|wired at|populated by .* at|future ) ?\(?IMPL-(006|007|018|042|043|053)\b" \
     MQL5/Experts/PhoenicisNex/  simulation/headless-tests/
→ 0 hits
```

The regex literally cannot match `IMPL-060` or `IMPL-062` because the task-ID alternation is hand-enumerated to the six tasks cited at fix-round-18 sites. The defect class — "any closed-task forward-pointer comment" — survives.

This is the **eighth iteration** of the R12→R20 chain, and the **second time within fix-round-19 itself** the same root cause has been pointed out: review-round-19 §19.2 Suggested Fix prescribed:

> "Stage 1 — derive the closed-task list from impl-plan.md (currently 30+ closed):
>   `grep -oE 'IMPL-0[0-9]{2}' docs/state/impl-plan.md | sort -u > /tmp/closed-impl-tasks.txt`
> Stage 2 — for each closed task, grep the source tree…"

fix-round-19 did not adopt this dynamic-regex approach; instead the engineer hand-extended the literal alternation to six task IDs (the ones the prior reviewer had cited as examples). The closed-task list as of 2026-05-05 is **30+**. Every closure since IMPL-053 (1.5 days of P4 closures) introduces new forward-pointer surface that the closed-enumeration sweep cannot anticipate.

**Why This Matters:**
This is a structural failure of the fix-round-19 §19.2 sweep approach (token catalog) to enforce the Gate #9d promise (defect class). When IMPL-063 closes (next P4 task), every comment "gated on IMPL-063" / "deferred to IMPL-063" instantly becomes stale — and the catalog-based sweep cannot anticipate the new token without another fix-round.

**Suggested Fix:**
Adopt the dynamic-regex Stage-1/Stage-2 approach from review-round-19 §19.2 Suggested Fix. Then immediately fix the two surviving sites:

```bash
# Stage 1 — derive closed-task list from impl-plan.md (currently 30+):
grep -oE 'IMPL-0[0-9]{2}' docs/state/impl-plan.md \
  | sort -u > /tmp/closed-impl-tasks.txt

# Stage 2 — for each closed task, grep the source tree:
for task in $(cat /tmp/closed-impl-tasks.txt); do
  grep -rnE "(deferred to|wires? at|wired at|populated by .* at|gated on|until|tracked at|pre-|future ) ?\(?${task}\b" \
    MQL5/Experts/PhoenicisNex/  simulation/headless-tests/
done

# Stage 3 — fix the two surviving sites per Finding 20.1 bin-1/2/3:
#
#   slots/Slot_D.mqh:21 → "(real ForcePendingActionOrder logic landed
#                          at IMPL-062 commit 277cdb2 — see docs/state/
#                          regression-bucket-a.md § Slot_D notes)"
#
#   spike/Spike_Orchestrator.mq5:12 → "Therefore live OnInit/OnTick
#                          exercise is delegated to PhoenicisNex.mq5
#                          (IMPL-060 thin wrapper, commit 277cdb2)"
```

Update `.claude/rules/workflow.md § Phase 5 Gate #9d` to mandate the dynamic regex (parameterised by `impl-plan.md` Phase Status Snapshot closed-task list) — replace the hand-enumeration approach.

**Level of Effort:** Low (~30 min to fix the 2 sites + update rule; no compile risk — comments only).

---

### Finding 20.3: 🟡 MEDIUM — fix-round-19 §19.2 Partial-Accept rationale "the remaining ~86 hits are historical banner comments exempt under Gate #9c" conflates two distinct comment classes — file-header banners describing **what task originally added the file** (truly historical; exempt) vs body comments describing **future wiring plans** (forward-pointer; NOT exempt). Sample inspection finds at least one banner row in the 86-hit cohort that is actually a forward-pointer wearing banner clothing.

**Location:**
- Representative ambiguous site: `services/CrossSlotCoordinator.mqh:8` — `// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1).` — this reads as historical (IMPL-053 is what added the file's body), but the same file at line 53 / 281 / 679 also has `IMPL-053` as references to the *same task*; without disambiguating it's unclear whether each is "history" or "forward-pointer".
- Reference: fix-round-19 §19.2 Sites-rerouted table claims 8 verb-form sites + ~86 banner-history sites; Gate #9c "preserved as audit history" exemption per `.claude/rules/workflow.md § Phase 5 Gate #9 clause (c)`

**Problem:**
The fix-round-19 §19.2 narrative draws a binary line:
- "8 verb-form forward-pointers" → rerouted
- "~86 banner-history sites" → preserved per Gate #9c exemption

But Gate #9c was originally written for **audit-history files** (review-round-NN.md, fix-round-NN.md, _session-handoff/*) — files that exist *for the purpose* of being history. Live `.mqh` source files contain a mix of (a) one-time historical banners ("this file was added by IMPL-053") and (b) forward-pointers wearing banner syntax ("IMPL-053 sub-pass: skeleton + RunSafePort full body" — describes what IMPL-053 added but functionally tells the reader "go look at IMPL-053 narrative for the why").

For a fresh reader at 2026-05-10, the two classes are indistinguishable by syntax. The historicity of any given line depends on context (is the cited task closed? does the comment describe completed work or pending work?).

The Partial-Accept verdict means **86 lines of "IMPL-NNN" references in source comments** are now in a permanent grey zone: not rerouted to live code, not deleted as stale, not annotated as audit history. Future Gate #9 sweeps will keep finding them and either re-classify them every round (high churn) or leave them for the next reviewer.

**Why This Matters:**
This is not a fixable-now defect, but a methodology gap in the Gate #9c exemption rule. Without a disambiguating syntax (e.g., explicit `[history]` tag in source comments, or a CSV mapping `file:line → exempt-reason`), Gate #9c becomes a self-claimed exemption that any sweep can invoke to stop iterating.

**Suggested Fix:**
Two options:

```bash
# Option A — explicit history tag (low-effort but verbose):
#   Re-sweep the 86 sites and prefix each with "[history]" so future
#   greps can exclude them mechanically:
#     "// IMPL-053 sub-pass: ..."
#   becomes
#     "// [history] IMPL-053 sub-pass: ..."
#
#   Then Gate #9d regex appends "[^[]" lookahead to skip history-tagged
#   lines:
#     grep -rE "(?<!\[history\] )(deferred to|wires? at|...) ?\(?IMPL-..."
#
# Option B — exemption manifest (one-time annotation):
#   Create docs/state/comment-history-exemptions.md with the 86 sites
#   listed by file:line + 1-line justification each. Gate #9 sweep
#   subtracts this list before scoring hits. Fix-round narratives
#   that add to this list MUST attest each new exemption.
```

Either option fixes the ambiguity. Option B is closer to existing methodology (registry-as-SoT pattern); Option A is closer to existing source-comment pattern (in-file annotation).

**Level of Effort:** Low (Option A: ~30 min mechanical sweep + rule update; Option B: ~1 hour to enumerate + commit manifest).

---

### Finding 20.4: 🟡 MEDIUM — fix-round-19 §19.4 `tick_latency_smoke.ini [TesterInputs]` block pins **threshold integers + window durations** for the time-gate inputs, but does NOT pin the **per-slot enable inputs** (`InpEnableSlotS=true` etc.) that are required for the `n[entry_pass] > 0` clause of the asserted invariant — the entry-pass loop iterates over enabled slots only, so an operator inheriting a stale `.set` file with all slots disabled would see `n[entry_pass] == 0` → false-FAIL classified as gate regression.

**Location:**
- File: `simulation/headless-tests/tick_latency_smoke.ini`, Lines 56-67 (the `[TesterInputs]` block landed by fix-round-19 §19.4)
- File: `core/Orchestrator.mqh::OnTick` — entry-pass loop (step 11 per TD-02 §7.2)
- Reference: TD-02 §13.6 reproducibility contract; review-round-19 §19.4 assertion contract `n[entry_pass] < n[refresh] AND n[entry_pass] > 0`; fix-round-19 §19.4 narrative ("the assertion contract `n[entry_pass] < n[refresh] AND n[entry_pass] > 0` follows from the **window choice** plus the **threshold values** (now pinned)")

**Code:**
```ini
; simulation/headless-tests/tick_latency_smoke.ini:56-67
[TesterInputs]
InpMorningWindowMinutes=5
InpMondaySpreadThreshold=10
InpHolidayStartMonth=12
InpHolidayStartDay=21
InpHolidayEndMonth=1
InpHolidayEndDay=3
InpBanCCooldownBars=5
InpBanLCooldownBars=5
InpBanMCooldownBars=5
InpKLastOrderCooldownBars=4
InpGPauseCooldownBars=3
;
; ← NO per-slot enable inputs pinned (InpEnableSlotC, InpEnableSlotS, ...)
; ← NO logging level pinned (InpLogLevel)
```

**Problem:**
The fix-round-19 §19.4 narrative correctly noted that the original review-round-19 §19.4 Suggested Fix referenced non-existent toggle inputs (`InpUseMorningBlock` etc. — these don't exist in the source tree). The engineer pivoted to pinning the actual existing TimeGate inputs, which are integer thresholds + window durations.

But the asserted invariant has TWO conjuncts:
- `n[entry_pass] < n[refresh]` — verifies entry-pass is *sometimes* skipped (gate fires)
- `n[entry_pass] > 0` — verifies entry-pass is *sometimes* hit (entry loop iterates)

The second conjunct depends on the **per-slot enable toggles**: if no slots are enabled, the entry loop iterates zero times per tick → `n[entry_pass] == 0` regardless of gate firing. The TickLatencyProbe `STAGE_ENTRY` increment (per fix-round-17 §17.2) sits inside the entry-pass branch *after* the time-gate check but *before* the per-slot enable filter — so an empty slot set means the stage probe never increments.

`Inputs_General.mqh` declares `InpEnableSlotC`, `InpEnableSlotS`, etc. as `input bool` with default `true` — but operator can override via Tester `.set` file. fix-round-19's stated rationale ("Pinning the actual existing inputs locks the contract per the TD-02 §13.6 reproducibility principle") is half-applied: it locks the *threshold* drift but not the *enable-toggle* drift.

**Why This Matters:**
The same operator-stale-`.set`-file failure mode that fix-round-19 §19.4 was authored to prevent now applies on a different axis: an operator with a `.set` containing `InpEnableSlotS=false` (perhaps from a prior optimization run) sees `n[entry_pass] == 0` → false-FAIL → reclassifies as a regression in fix-round-17 §17.2 instrument-correctness fix → next debugging round opens fix-round-21.

**Suggested Fix:**

```ini
; simulation/headless-tests/tick_latency_smoke.ini — append to [TesterInputs] block

; fix-round-20 §20.4 — pin per-slot enables so n[entry_pass] > 0 holds.
; Without these, a stale .set file with disabled slots short-circuits
; the entry-pass loop and produces a false-FAIL.
InpEnableSlotC=true
InpEnableSlotD=true
InpEnableSlotF=true
InpEnableSlotJ=true
InpEnableSlotH=true
InpEnableSlotK=true
InpEnableSlotG=true
InpEnableSlotG2=true
InpEnableSlotGO=true
InpEnableSlotI=true
InpEnableSlotM=true
InpEnableSlotL=true
InpEnableSlotLX=true
InpEnableSlotQ=true
InpEnableSlotR=true
InpEnableSlotP=true
InpEnableSlotT=true
InpEnableSlotS=true
InpEnableSlotB=true
InpEnableSlotBR=true
InpEnableSlotBI=true
;
; And pin logging level so [ev=tick_latency_report] is emitted:
InpLogLevel=2     ; INFO
```

**Level of Effort:** Low (~22 lines append + grep `Inputs_General.mqh` for full enable-toggle list to verify exact names + 1-line note in `nfr-2.1-tick-latency.md`).

---

### Finding 20.5: 🔵 LOW — fix-round-19 §19.5 deferred IMPL-FIX-003 G3 structural pre-drain a **second consecutive round** despite landing the `[TesterInputs]` pin (§19.4) that hardens reproducibility. The recurrence reproduces exactly the anti-pattern fix-round-18 §18.5 was raised to break; same root cause as Finding 19.5, now compounded by one more cycle of slip.

**Location:**
- File: `docs/code-review/fix-round-19.md`, Lines 122-130 (Verdict 19.5 Defer; "sandbox session cannot drive MT5 Strategy Tester end-to-end")
- File: `simulation/headless-tests/tick_latency_smoke.ini` — now `[TesterInputs]`-hardened per §19.4
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5` — G1 PASS 0/0/3960 ms per fix-round-19 §19.4 G1-G4 verification table
- Reference: review-round-18 §18.5 + fix-round-18 §18.5 (structural pre-drain plan); review-round-19 §19.5 + fix-round-19 §19.5 (first defer); CLAUDE.md §1 Three-Tier Closure Convention; `andm-impl-engineer/SKILL.md § Empirical Closure Discipline`

**Problem:**
The defer chain now reads:
- **fix-round-17 §17.2** (2026-05-05) — instrument-correctness fix; G2-G4 deferred to operator-runtime
- **review-round-18 §18.5** (2026-05-05) — opened IMPL-FIX-003 to break the defer cycle by landing wrapper + `.ini`
- **fix-round-18 §18.5** (2026-05-05) — landed wrapper (G1 PASS) + `.ini` but did NOT run G3
- **review-round-19 §19.5** (2026-05-05) — flagged as LOW: fix-round-18 deferred its own drain
- **fix-round-19 §19.5** (2026-05-05) — Verdict: Defer ("sandbox cannot drive MT5 Strategy Tester")
- **review-round-20 §20.5** (this finding) — eighth defer iteration of an instrument-correctness fix

Each round adds a layer of artifact (wrapper, `.ini`, `[TesterInputs]` block) that improves operator self-service to ≤30 min wall-clock. The instrument's correctness remains unverified; the assertion contract `n[entry_pass] < n[refresh] AND n[entry_pass] > 0` against a real Tester run has not been observed even once since fix-round-17 §17.2 landed the STAGE_ENTRY relocation.

LOW (not MEDIUM) because (a) fix-round-19 §19.5 is honest about the sandbox limitation (the engineer cannot drive an interactive Windows GUI from a headless agent session), (b) operator session can absorb the drain in a single ~10-min run, (c) the registry IMPL-065 row carries the structural-half plan, (d) compile gate (G1) keeps the wrapper in a runnable state across every round.

**Why This Matters:**
The closure-discipline argument R18 §18.5 made was that the operator-runtime defer cycle should be broken at the **artifact-readiness** level — wrapper + `.ini` + `[TesterInputs]` all exist and are battle-tested. But the cycle is broken only insofar as the artifacts are ready; the actual *run* has slipped three consecutive rounds (fix-18 → fix-19 → fix-20). At each step the operator session is "scheduled imminently"; if it slips a fourth round, the structural-half assertion becomes part of the persistent E-AC residue and stops being treated as a fix-round closure obligation.

**Suggested Fix:**
Either:

```bash
# Option A — execute the drain pre-fix-round-20-close (operator session bound):
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/tick_latency_smoke.ini /tmp/tick_latency_run.txt
# (~10 min wall-clock + 1 jq + 1 registry edit)

# Option B — formally accept the defer as registry residue, NOT as a fix-round
#    obligation. Move the IMPL-065 structural-half AC out of "currently being
#    closed by fix-round NN" status into the standard E-AC paired-bundle Active
#    row that resolves at Tier 1.5 walk batch-3.
```

Option B is the methodology-correct outcome: stop spawning fix-rounds whose closure depends on operator-runtime drain. Once the artifacts are landed and the assertion is documented, further "this fix-round did not run G3" findings should be silenced per the Deferred-AC Registry policy.

**Level of Effort:** Low (Option A: ~10 min if operator available; Option B: ~5 min registry edit + impl-plan TL;DR note).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-20.1 | 🟠 HIGH | Replacement-token semantic mismatch — "Phase-2 wiring; see docs/state/deferred-ac-registry.md" misrepresents Phase-1-now-landed work as Phase-2 future work + misroutes readers to a registry that does not carry the relevant entries | 41 source + 22 test-config files; 158 occurrences | Eighth iteration of R12→R20 chain. Token catalog approach defeats itself: every fix-round picks a new placeholder string that becomes the next round's defect. Requires bin-1/2/3 routing per review-round-19 §19.1 Suggested Fix (specific file:line pointers, not registry pointer). |
| XS-20.2 | 🟠 HIGH | fix-round-19 §19.2 verb-form catalog still hand-enumerated to the six task IDs cited at fix-round-18 sites; misses IMPL-060 / IMPL-062 (closed 2026-05-04/05) | `slots/Slot_D.mqh:21` + `spike/Spike_Orchestrator.mq5:12` | Recurrence-chain failure. Adopt dynamic regex parameterised by closed-task list from `impl-plan.md` Phase Status Snapshot per review-round-19 §19.2 Suggested Fix Stage-1/Stage-2. |
| XS-20.3 | 🟡 MEDIUM | Gate #9c "audit history" exemption is self-claimed; live source files contain a mix of historical banners + forward-pointers wearing banner syntax — no disambiguating mechanism | 31 source files, ~86 banner-style sites cited in fix-round-19 §19.2 Partial-Accept | Add explicit `[history]` tag in source OR exemption manifest at `docs/state/comment-history-exemptions.md`. |
| XS-20.4 | 🟡 MEDIUM | Assertion-bearing `.ini` files MUST pin every input that affects the asserted invariant — `tick_latency_smoke.ini` pins thresholds but not per-slot enables required for `n[entry_pass] > 0` clause | `simulation/headless-tests/tick_latency_smoke.ini` | Append `InpEnableSlot{C..BI}=true` (21 toggles) + `InpLogLevel=2`. |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 20.1 | fix-round-19 §19.1 replacement token "Phase-2 wiring; see docs/state/deferred-ac-registry.md" — semantic mismatch (Phase-2 = post-MVP cloud, not Phase-1 P4) + garbled prose at several sites + misroute (registry doesn't carry entries) | 🟠 HIGH | repo-wide; representative: `services/PortfolioState.mqh:176`, `domain/CSlotBase.mqh:66,146`, `domain/EnumTypes.mqh:118`, `domain/SlotState.mqh:38`, `slots/Slot_BI.mqh:276`, `spike/Spike_Slot_B.mq5:17` | ea (cross-cutting) | M (~3-4h; per-site bin-1/2/3 routing) |
| 20.2 | fix-round-19 §19.2 verb-form catalog hand-enumeration misses IMPL-060 + IMPL-062 forward-pointers | 🟠 HIGH | `slots/Slot_D.mqh:21`, `spike/Spike_Orchestrator.mq5:12` | ea (cross-cutting) | Low (~30 min — fix 2 sites + adopt dynamic-regex Gate #9d) |
| 20.3 | Gate #9c exemption ambiguity — historical banners vs forward-pointers wearing banner syntax indistinguishable in 86 surviving sites | 🟡 MEDIUM | 31 source files; representative: `services/CrossSlotCoordinator.mqh:8`, `services/CircuitBreaker.mqh:15`, `services/Logger.mqh:148-149`, `core/Orchestrator.mqh:22`, `core/SlotRegistry.mqh:16,78` | ea (cross-cutting) | Low (~30-60 min — `[history]` tag OR exemption manifest) |
| 20.4 | tick_latency_smoke.ini `[TesterInputs]` block missing per-slot enable toggles required for `n[entry_pass] > 0` clause | 🟡 MEDIUM | `simulation/headless-tests/tick_latency_smoke.ini:56-67` | ea-qa | Low (~22-line `.ini` append) |
| 20.5 | fix-round-19 §19.5 deferred IMPL-FIX-003 G3 a second consecutive round despite §19.4 hardening; instrument-correctness verification slipped 3 rounds | 🔵 LOW | `docs/code-review/fix-round-19.md:122-130` + `simulation/headless-tests/tick_latency_smoke.ini` + `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5` | ea-qa | Low (Option A operator drain ~10 min OR Option B registry residue acceptance ~5 min) |
| **Cross-Service Total** | | | | | |
| XS-20.1 | Replacement-token semantic mismatch defect class | 🟠 HIGH | 41 + 22 files, 158 sites | ea | (covered by 20.1) |
| XS-20.2 | Closed-task forward-pointer next-coarser variant survival | 🟠 HIGH | 2 sites (Slot_D + Spike_Orchestrator) | ea | (covered by 20.2) |
| XS-20.3 | Gate #9c exemption ambiguity | 🟡 MEDIUM | 31 files, ~86 sites | ea | (covered by 20.3) |
| XS-20.4 | Assertion-bearing .ini missing per-slot enable pins | 🟡 MEDIUM | tick_latency_smoke.ini | ea-qa | (covered by 20.4) |

**Recommendation:** Ready for **fix-round-20**. Priority order:

1. **Finding 20.1 (HIGH)** — re-sweep the 158 "Phase-2 wiring" tokens with proper bin-1/2/3 routing per the original review-round-18 §18.1 / review-round-19 §19.1 Suggested Fix. Most sites land in bin-1 (live writer exists; e.g., OnTradeTransaction at `core/Orchestrator.mqh:218`, RiskManager::CloseOrder at P2 closure). Block IMPL-063 closure until clean.
2. **Finding 20.2 (HIGH)** — fix the 2 surviving sites (`Slot_D.mqh:21`, `Spike_Orchestrator.mq5:12`) and adopt dynamic-regex Gate #9d (review-round-19 §19.2 Suggested Fix Stage-1/Stage-2 — was deferred by fix-round-19).
3. **Findings 20.3 + 20.4 (MEDIUM)** — Gate #9c disambiguation + tick_latency_smoke.ini per-slot pin. Both small.
4. **Finding 20.5 (LOW)** — either run G3 of IMPL-FIX-003 or formally accept the structural-half as Tier 1.5 walk batch-3 residue (stop spawning fix-rounds whose closure depends on operator-runtime).

> **Reviewer note (R12→R20 recurrence chain summary):**
> Eight consecutive review rounds have caught a different surface manifestation of the same defect class: "comment routing destroyed during sweep instead of pointing to live writers". Each round's fix-round either narrows the catalog (R12-R18) or picks a fourth-bin replacement that becomes the next round's defect (R18 synthetic-token; R19 Phase-2-wiring-pointer). The chain will iterate to R21+ until fix-round-NN adopts the dynamic-regex enforcement (review-round-19 §19.2 Stage-1/Stage-2) AND the bin-1/2/3 routing discipline (review-round-18 §18.1 Suggested Fix). Rule update target: `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` — replace closed-enumeration token catalog with closed-task-list-derived dynamic regex; replace blanket-replacement bin with mandatory bin-1/2/3 per-site routing.

> **Plan Staleness Sentinel post-R20:** unchanged from R09 advisory (no IMPL-NNN closures since fix-round-19; this is the immediate successor). Sentinel resets on next P4 closure (IMPL-063).

## End of Review Round 20
