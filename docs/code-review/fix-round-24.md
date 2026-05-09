# Code Review Fix Round 24

| Field | Value |
|-------|-------|
| **Round** | 24 |
| **Review File** | `docs/code-review/review-round-24.md` |
| **Date** | 2026-05-09 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |
| **Scope** | Methodology-only (no source code changes). Extend Gate #9 clause (h) exemption regex + author clause (i) per Finding 24.1 MEDIUM. Finding 24.2 LOW = methodology note only (already self-corrected in fix-round-23 verdict table). |
| **Working tree at session start** | clean (HEAD = `6201d63`). |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 24.1 | Gate #9 clause (h) exemption regex scope-narrower than hand-classification (5 surviving non-exempt-by-regex hits) | 🟡 MEDIUM | Accept | `.claude/rules/workflow.md` (rule body + footer) | (this round) |
| 24.2 | R23 §23.1 site #3 over-classified text-violation as drift | 🔵 LOW | Accept (no action) | None | — |

**Accepted:** 2 (1 actioned, 1 narrative-only)
**Rejected:** 0
**Partial:** 0

---

## §24.1 — Fix for Finding 24.1 (MEDIUM): Gate #9 clause (h) exemption regex extended + clause (i) authored

**Verdict:** Accept
**Scope:** `.claude/rules/workflow.md` — Gate #9 clause (h) body (table row at line 104) + "Why this is here" footer paragraph (line 108).

### Reproduction (independent re-run this round, before fix)

```bash
$ grep -rnE "\b(line [0-9]+(-[0-9]+)?|\.(mqh|mq5):[0-9]+(-[0-9]+)?)\b" \
       MQL5/Experts/PhoenicisNex/ \
    | grep -vE "(TD-02 §|ADR-[0-9]+ §|TD-02 line|ADR-[0-9]+ line)"

MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:81:   //    Called from Orchestrator::Init Phase C (TD-02 §7.4 line 1654):
MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh:339:   // state.json load — degrade-but-continue on corrupt (per § 7.4 line 1659).
MQL5/Experts/PhoenicisNex/helpers/Timestamp.mqh:7://|         trade-journal-schema.yaml line 36                         |
MQL5/Experts/PhoenicisNex/helpers/Timestamp.mqh:26://|   • "Z" suffix per trade-journal-schema.yaml line 36 + ADR-006   |
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:693://| (state-persistence-schema.yaml § cross_slot_state line 119-121)  |
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:359://| buffer_index: 0=MACD line 1=Signal line                          |
# 6 hits — confirms reviewer's count
```

### Changes

**1. Extended exemption regex** in clause (h) Combined sweep regex.

| Class | Pattern added | Covers |
|-------|---------------|--------|
| (α) abbreviated TD-02/ADR anchor | `TD-02 (§\|line)` + `ADR-[0-9]+ (§\|line)` | merges 4 prior alternations into 2 (no functional change for original sites) |
| (β) bare-§ doc anchor | ` § [0-9]+(\.[0-9]+)? line ` | catches `(per § 7.4 line 1659)` form (covers `core/Orchestrator.mqh:339`) |
| (γ) spec-yaml anchors | `(trade-journal-schema\|state-persistence-schema\|slot-abstraction-contract)\.yaml` | covers `helpers/Timestamp.mqh:7,26` + `services/CrossSlotCoordinator.mqh:693` |
| (δ) TA-indicator false-positive filter | `MACD\|Signal\|EMA\|SMA\|RSI line` | covers `services/MarketContextBuilder.mqh:359` |

Final extended exemption regex:

```
(TD-02 (§|line)|ADR-[0-9]+ (§|line)| § [0-9]+(\.[0-9]+)? line |(trade-journal-schema|state-persistence-schema|slot-abstraction-contract)\.yaml |MACD line|Signal line|EMA line|SMA line|RSI line)
```

**2. Authored clause (i)** — exemption-regex tree-wide verifiability meta-rule. Inline within Gate #9 row (not a deferred footnote) per R23 methodology-scope discipline. Forces engineer running clause (h) to verify the documented combined regex returns 0 hits tree-wide WITHOUT further hand-classification — surviving hits force regex extension or scope-out enumeration in the fix-round narrative.

**3. Updated "Why this is here" footer** with R24 paragraph documenting the 4th axis (exemption-regex) and the chain's complete axis set {catalog (R20), destination (R21), anchor (R22-R23), exemption-regex (R24)}.

### Verification (post-fix re-run)

```bash
$ grep -rnE "\b(line [0-9]+(-[0-9]+)?|\.(mqh|mq5):[0-9]+(-[0-9]+)?)\b" \
       MQL5/Experts/PhoenicisNex/ \
    | grep -vE "(TD-02 (§|line)|ADR-[0-9]+ (§|line)| § [0-9]+(\.[0-9]+)? line |(trade-journal-schema|state-persistence-schema|slot-abstraction-contract)\.yaml |MACD line|Signal line|EMA line|SMA line|RSI line)"

MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:81:   //    Called from Orchestrator::Init Phase C (TD-02 [mojibake]7.4 line 1654):
# 1 surviving hit — scope-out per clause (i)(b)
```

### Scope-out enumeration (per new clause (i)(b))

**Site:** `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:81`
**Cite text (intent):** `Called from Orchestrator::Init Phase C (TD-02 §7.4 line 1654)` — semantically a TD-02 § anchor (would match exemption class α).
**Why surviving:** the file's `§` byte sequence is mojibake — `od -c` shows `340 271 200 340 270 230 340 270 202 340 271 200 340 270 230 302 207` (Thai characters U+0E40 + control char U+0087) instead of the expected UTF-8 `\xc2\xa7` for `§`. The exemption regex correctly does not match the corrupted byte sequence. **Reviewer's review-round-24 §24.1 footnote claim ("on UTF-8 terminal this site IS exempt") is incorrect** — the corruption is in the file content itself, not the terminal rendering.

**Latent issue surfaced (out of scope for fix-round-24):** the same mojibake'd § byte sequence appears in 5 files: `core/BootstrapValidator.mqh`, `inputs/Inputs_Slot_BI.mqh`, `inputs/Inputs_Slot_BR.mqh`, `inputs/Inputs_Slot_GO.mqh`, `services/CircuitBreaker.mqh`. This is a pre-existing file-transcoding defect predating fix-round-24. Flagged here for follow-up — not actioned in this round to keep methodology-only scope.

**Scope-out reason (per clause (i)):** transcoding artifact, separate from clause (h)'s line-anchor brittleness intent. Each surviving hit corresponds to text that the engineer can semantically verify is a TD-02 doc anchor (not a load-bearing source-line cite). Extending the exemption regex to match mojibake byte sequences would mask the latent file-corruption issue rather than fixing it; the right action is a separate cleanup ticket.

### Termination test — clauses (a)-(i) tree-wide

| Clause | Result |
|--------|--------|
| (a) Originating literal (R13) | 0 hits ✅ |
| (b) Broader-class verb catalog (R14) | 0 hits ✅ |
| (c) Repo-wide intent (R16) | 0 hits ✅ |
| (d) Closed-task verb-form catalog (R18) | 0 hits ✅ |
| (e) Dynamic closed-task list (R20) | 0 hits ✅ |
| (f) Destination-existence (R21) | all cited symbols exist outside banner blocks ✅ |
| (g) Token-collision pre-check (R21) | 0 hits ✅ |
| (h) Line-anchor brittleness (R22-R23 + R24 extended exemption) | 1 surviving hit (mojibake'd §) — scope-out per (i)(b); 5 prior hits now exempt by extended regex ✅ |
| (i) **Exemption-regex tree-wide verifiability (NEW R24)** | exemption regex itself runs tree-wide; 1 hit individually scope-justified above ✅ |

**Termination verdict:** chain CLOSED at 4 axes (catalog + destination + anchor + exemption-regex). Documented mechanism reproduces the pass count without hand-classification (1 hit individually scope-justified, no narrative-only "hand-classified as exempt"). R25 verify-only sweep can confirm.

---

## §24.2 — Fix for Finding 24.2 (LOW): R23 §23.1 site #3 enumeration narrative-precision

**Verdict:** Accept (no action — already self-corrected in fix-round-23 verdict-table cell)
**Evidence:** fix-round-23 §23.1 verdict-table corrective note ("function actually IS at line 791 today") accepted the reroute on (h)-text-violation rationale. The source tree is unaffected — site #3 was rerouted on the correct rationale; only R23's sub-classification (drift vs text-violation) was off-by-one. Methodology note recorded for future rounds: when running clause (h) tree-wide intent grep, classify each surviving hit as {realized-drift / text-violation / compliant} with explicit per-category counts to keep audit narrative precise.

**Why no rule edit:** the methodology distinction is already implicit in clause (h) text ("sites failing verification are realized drift and MUST be re-anchored ... regardless of accuracy"). Reviewer agrees no source code change. Adopting the per-category count discipline as soft methodology going forward.

---

## Phase 5 Mechanical Gate Compliance (fix-round-24)

| # | Gate | Status | Note |
|---|------|--------|------|
| 1 | Forbidden-pattern grep on `impl-plan.md` | ✅ Pass | 0 hits (no plan changes this round). |
| 2 | TL;DR ↔ registry recount | n/a | no plan change. |
| 3 | TL;DR ↔ matrix denominator | n/a | no plan change. |
| 4 | Sentinel counter increment | n/a | fix-round, not IMPL-NNN closure. |
| 5 | overview.md sync | ✅ Pass | fix-round-24 paragraph appended to Impl Plan row status. |
| 6 | File integrity (impl-plan.md) | ✅ Pass | not touched this round. |
| 7-8 | Phase Status / Open Risks sweeps | n/a | no IMPL-NNN closure. |
| 9a | Originating literal grep | ✅ Pass | 0 hits. |
| 9b | Broader-class doubling regex | ✅ Pass | 0 hits. |
| 9c | Repo-wide intent grep | ✅ Pass | 0 hits. |
| 9d | Closed-task verb-form catalog (dynamic) | ✅ Pass | 0 hits. |
| 9e | Closed-task list dynamic derivation | ✅ Pass | n/a (no closed-task pointer changes). |
| 9f | Destination-existence verification | ✅ Pass | no new bin-1 routing comments authored. |
| 9g | Token-collision pre-check | ✅ Pass | no bulk token substitution. |
| 9h-text | Line-anchor brittleness rule | ✅ Pass | 0 source-tree changes; rule body strengthened. |
| 9h-tree | Tree-wide scope post-condition | ✅ Pass | tree-wide verification re-run. |
| **9h-exempt** | **Exemption regex literal verifiability (NEW R24)** | ✅ **Pass** | extended exemption regex returns 1 surviving hit, individually scope-justified per clause (i)(b). |
| **9i** | **NEW R24 — exemption-regex tree-wide verifiability** | ✅ Pass | combined regex (intent + extended exemption) executed tree-wide; 1 hit enumerated with stated reason. |
| 10 | Stash-clean G1 | n/a | no source code changes; rule edit only in `.claude/rules/workflow.md` (not compiled). |
| 11 | Working-tree clean post-closure | ✅ Pass (post-commit). |

---

## State Reconciliation (3-File Propagation)

| Layer | File | Action |
|-------|------|--------|
| 1 — primary SoT | `docs/state/impl-plan.md` | n/a — no AC re-tick (methodology-only round; no Deferred-AC resolved; no closed-task flip) |
| 2 — derived view | `docs/state/overview.md` | append fix-round-24 paragraph to Impl Plan row Last Updated/status string |
| 3 — handoff | `docs/state/current_handoff.md` (or per-module if exists) | record review-round-24 → fix-round-24 entry + new Gate #9 clause (i) + extended (h) exemption regex |

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 2 |
| Accepted (actioned) | 1 (24.1 MEDIUM) |
| Accepted (narrative only) | 1 (24.2 LOW) |
| Rejected | 0 |
| Files Modified | 1 (`.claude/rules/workflow.md`) |
| Source Code Changes | 0 |
| Tests Added/Updated | 0 (n/a — methodology-only) |
| Commits | 1 (this fix-round) |

**Recommendation:** Ready for **review-round-25** (verify-only sweep). R25 should re-run the full meta-grep over Gate #9 clauses (a)-(i); chain termination declared if all 9 clauses verify clean simultaneously WITH documented mechanisms (no hand-classification). If R25 surfaces a 5th axis, the chain hasn't yet fully revealed its structure (predicted location: rule-authoring contract — new Gate #9 clauses must include their own exemption regex AND tree-wide verification recipe in the clause body).

**Latent follow-up (out of scope for R24):** mojibake'd `§` byte sequences in 5 files (`core/BootstrapValidator.mqh`, `inputs/Inputs_Slot_BI.mqh`, `inputs/Inputs_Slot_BR.mqh`, `inputs/Inputs_Slot_GO.mqh`, `services/CircuitBreaker.mqh`) — pre-existing file-transcoding defect; cleanup ticket recommended.

## End of Fix Round 24
