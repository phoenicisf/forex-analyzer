# Technical Design Rebuttal Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Claim Review** | `claim-review-09.md` |
| **Date** | 2026-05-18 |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |
| **Defender** | andm-td-defender persona |
| **Scope** | 2 findings (1 MEDIUM count-cascade-arithmetic + 1 LOW count-side-drift) — both Accept; cascade-completion applied to SD-02 + ADR-012 |

## Summary

| Verdict | Count |
|---------|-------|
| Accepted | 2 |
| Partial | 0 |
| Rejected | 0 |

**Outcome:** TD-02 services count narrative corrected from "12" → "11" at all 4 cited sites (L5 audit narrative, L24 ToC, L464 § 5 header, L2490 end-of-doc footer); helpers count corrected from "4" → "5" at L2490 footer with scope qualifier dissolving the apparent disagreement with § 7.3 DI callout (3 stateful + 2 pure utility). Cascade-completion applied to SD `02-high-level-architecture.md:128` (13 services → 11 services) and ADR-012 `012-file-layout-module-split-discipline.md:100` (13 services + 4 helpers + ~52 files → 11 services + 5 helpers + ~50 files). CLAUDE.md § 3 + `.claude/rules/ea.md` are project-bootstrap surfaces — out of TD scope per reviewer's own flag (Round 07 § Remaining Gaps + Round 08 row #20) — flagged for operator `/project-init --regen` follow-up, NOT applied within this rebuttal.

---

## Claim Responses

### Claim 09.1: 🟡 MEDIUM — "12 services" count survives BT-002 cascade but disagrees with § 2 file tree + § 5 active subsections (off-by-one carry-over)

**Verdict:** Accept

**Empirical re-verification (Defender's independent count):**
- TD-02 § 2 `services/` block L58-69 = **11 files** (IndicatorService, MarketContextBuilder, PortfolioState, RiskManager, TradeJournal, StatePersistence, Logger, TimeGate, PendingMachineRegistry, CrossSlotCoordinator, PortfolioMonitor) — verified line-by-line
- TD-02 § 5 active subsections = **11** (5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, [5.8 struck per BT-002], 5.9, 5.10, 5.11, 5.12 = 12 numbered minus 1 struck = 11)
- pre-BT-002 commit `aebec01~1` § 5 header `## 5. Services Layer (13 services)` vs pre-BT-002 file tree (12 files incl. CircuitBreaker.mqh) vs pre-BT-002 § 5 subsections (12 active, 5.1-5.12) — confirms reviewer's chain: pre-BT-002 narrative "13" was already off-by-one against the pre-cascade empirical truth of 12; BT-002 cascade applied `−1` to "13" → "12" instead of the empirical "12" → "11".

**Reviewer's chain holds.** The cascade-arithmetic defect is real, not a narrative artefact. Accept.

**Changes Made:**

1. **File:** `docs/technical-design/02-backend-design.md`, **Line 5** (Last-updated header)
   - **What changed:** Rewrote Last-updated narrative to lead with Round 09 correction (services 12→11 + helpers 4→5) with attestation `correction acknowledges pre-BT-002 narrative "13 services" was already off-by-one against pre-BT-002 § 2 file tree + § 5 subsections (both 12); post-BT-002 authoritative empirical count = 11 services + 5 helpers. Cascade-completion applied to SD ... L128 + ADR-012 L100.` Prior BT-002 cascade entry preserved as "Prior 2026-05-18 entry" audit lineage.

2. **File:** `docs/technical-design/02-backend-design.md`, **Line 24** (§ 1 ToC row)
   - **Before:** `| § 5 | Services × 12 (post-BT-002 2026-05-17 — former CCircuitBreaker removed) — interface + key methods + DI dependencies |`
   - **After:** `| § 5 | Services × 11 (post-BT-002 2026-05-17 — former CCircuitBreaker removed; count corrected per Round 09 Finding 09.1) — interface + key methods + DI dependencies |`

3. **File:** `docs/technical-design/02-backend-design.md`, **Line 464** (§ 5 header)
   - **Before:** `## 5. Services Layer (12 services post-BT-002 2026-05-17; former § 5.8 CCircuitBreaker removed legacy-parity)`
   - **After:** `## 5. Services Layer (11 services post-BT-002 2026-05-17; former § 5.8 CCircuitBreaker removed legacy-parity; count corrected from "12" per Round 09 Finding 09.1 — pre-BT-002 narrative "13" was already off-by-one vs § 2 file tree + § 5.1-5.12 enumeration, post-BT-002 authoritative empirical count = 11)`

4. **File:** `docs/technical-design/02-backend-design.md`, **Line 2490** (End-of-doc footer)
   - **What changed (services portion):** `12 services + 21 slots + 4 helpers + 4 domain types` → `11 services + 21 slots + 5 helpers (3 stateful via DI per § 7.4 — CCommentParser, CJsonWriter, CAtomicFile + 2 pure utility — CPipMath, CTimestamp) + 4 domain types` with footer audit `services count corrected from "12" + helpers count corrected from "4" per Round 09 Findings 09.1/09.2` (joint with Claim 09.2 — see below).

**Cascaded to (SD/ADR cascade-completion per Finding 09.1 § Minimum Acceptable Fix item 2):**

5. **File:** `docs/design-docs/02-high-level-architecture.md`, **Line 128** (Summary stats row)
   - **Before:** `- 9 BR categories → mapped to 13 services + 21 slots`
   - **After:** `- 9 BR categories → mapped to 11 services + 21 slots` + HTML comment `<!-- TD Round 09 Finding 09.1 cascade-completion 2026-05-18: corrected from "13 services" (pre-BT-002 narrative was off-by-one vs file tree even pre-cascade; post-BT-002 authoritative empirical count = 11 per TD-02 § 2 file tree L58-69 + § 5.1-5.12 minus struck 5.8) -->`

6. **File:** `docs/adr/012-file-layout-module-split-discipline.md`, **Line 100** (Total file count estimate)
   - **Before:** `**Total file count estimate:** 21 slot + 5 inputs + 4 core + 13 services + 4 domain + 4 helpers + entry = **~52 files**`
   - **After:** `**Total file count estimate:** 21 slot + 5 inputs + 4 core + 11 services + 4 domain + 5 helpers + entry = **~50 files**` + HTML comment `<!-- TD Round 09 Finding 09.1/09.2 cascade-completion 2026-05-18: services 13→11 ... + helpers 4→5 (Timestamp.mqh ADR-006/011 ms-precision wiring per IMPL-FIX-009 not previously counted) ... -->`

**Defender notes on rejected scope (preserved as out-of-scope per claim review's own flag):**
- § 7.3 row callout L1561 "15 services + 1 helpers row" — reviewer EXPLICITLY scoped OUT (claim text: *"§ 7.4 line 1561 numbering convention says '15 services + 1 helpers row' but DI rows count Init steps not service classes — separate axis"*); DI map indexes Init invocations including 4a/5a cycle setters + struck step #10, not service class count. Out-of-scope retained.
- § 7.4 reviewer-checklist L1660 "× 15 services + 3 helpers (no Init)" — same axis as L1561 (Init-step count, not class count); out-of-scope retained.
- Last-updated narrative L5 mentions pre-BT-002 `16 services / 16 Init calls / 19 rows` only as audit lineage of the BT-002 cascade — preserved as historical attestation per Round 07 rebuttal § Audit Trail Preservation discipline.
- `CLAUDE.md § 3` "12 services" + "4 helpers" — project-bootstrap surface, not TD package; flagged for operator `/project-init --regen` follow-up per Round 07 § Remaining Gaps + Round 08 row #20 (consistent precedent — TD rebuttals do NOT touch CLAUDE.md directly; methodology mandates `/project-init --regen` regen-from-corrected-upstream).
- `.claude/rules/ea.md § Project Structure` "12 services" — same out-of-scope class as CLAUDE.md per Round 07 / Round 08 precedent.

---

### Claim 09.2: 🔵 LOW — "4 helpers" count in TD-02 footer disagrees with § 2 helpers/ block (5 files)

**Verdict:** Accept

**Empirical re-verification:**
- TD-02 § 2 `helpers/` block L75-80 = **5 files** (CommentParser, PipMath, JsonWriter, AtomicFile, Timestamp) — Timestamp.mqh annotated `# FormatTimestampWithMs() — ADR-006/011 ms precision` (pre-existing in current TD-02; landed during IMPL-FIX-009-era ADR-011 ms-precision wiring; file tree was updated but the footer narrative + ADR-012 enumeration were not).
- § 7.3 DI callout L1561 "3 helper classes" = scope-qualified to *stateful helpers consolidated in DI rows (CCommentParser, CJsonWriter, CAtomicFile — the ones with Init)*; PipMath + Timestamp = pure utility (no Init, construct on heap, pass-through pattern). Reviewer's classification "DI callout is internally consistent with its 'consolidating ... per § 4' scope qualifier" confirmed independently — leave DI callout untouched.

**Reviewer's chain holds.** Pre-existing drift (NOT BT-002-introduced) but exposed by Round 09's count-discipline sweep. Accept.

**Changes Made:**

1. **File:** `docs/technical-design/02-backend-design.md`, **Line 2490** (End-of-doc footer — joint edit with Claim 09.1 Change #4 above)
   - **What changed (helpers portion):** `4 helpers` → `5 helpers (3 stateful via DI per § 7.4 — CCommentParser, CJsonWriter, CAtomicFile + 2 pure utility — CPipMath, CTimestamp)` — scope qualifier dissolves the apparent disagreement with § 7.3 DI callout per Finding 09.2 § Minimum Acceptable Fix.

**Cascaded to (joint with Claim 09.1):**

2. **File:** `docs/adr/012-file-layout-module-split-discipline.md`, **Line 100** (joint with Claim 09.1 Cascade #6 above)
   - **What changed (helpers portion):** `4 helpers + entry = **~52 files**` → `5 helpers + entry = **~50 files**` (both cascade-completions joint in one edit). HTML comment cites both Finding 09.1 + 09.2.

**Out-of-scope retained (per claim text):**
- `CLAUDE.md § 3` "4 helpers" — project-bootstrap surface, operator `/project-init --regen` follow-up (same class as Claim 09.1 CLAUDE.md exemption).
- § 7.3 L1561 DI callout "3 helper classes" — internally consistent with its scope qualifier per reviewer's own note (*"defensible IF the callout text scopes it to 'stateful helpers consolidated in DI rows'... — PipMath and Timestamp are pure utility (no Init)"*); footer scope qualifier (`3 stateful via DI ... + 2 pure utility`) bridges the two axes.

---

## Cascaded Changes

The Cascaded Changes table lists modifications applied to docs **outside** the directly-cited TD-02 sites, per the Defender's cross-domain consistency sweep:

| # | File | Line | Change | Reason |
|---|------|------|--------|--------|
| C-1 | `docs/design-docs/02-high-level-architecture.md` | L128 | "13 services" → "11 services" + HTML audit comment | SD-side cascade-completion of Claim 09.1 (reviewer flagged as required minimum fix #2) |
| C-2 | `docs/adr/012-file-layout-module-split-discipline.md` | L100 | "13 services + 4 helpers + ~52 files" → "11 services + 5 helpers + ~50 files" + HTML audit comment | ADR-side cascade-completion of Claims 09.1 + 09.2 jointly (reviewer flagged as required minimum fix #2) |

**Anti-regression note:** Defender ran post-fix repo-wide grep `grep -rE "13 services|services × 12|services × 13" docs/` — all remaining hits are confined to:
- `docs/technical-design/claim-review-and-rebuttal/{claim-review-01,07,08,09,rebuttal-round-01,07}.md` — historical audit records (preserved as audit history of count drift across rounds 01→07→08→09)
- `docs/state/methodology-retrospective-day17.md:12` — frozen retrospective snapshot dated 2026-05-04 era (drift exists at write-time of retrospective; preserved as audit history per `methodology-retrospective` write-once discipline)
- `docs/state/overview.md:13` — derived snapshot; flagged for operator state-reconciliation update via `/next` Check 5.5 (per CLAUDE.md § 6 State Reconciliation Discipline — derived views update on next status sweep, not within this TD rebuttal)
- `docs/code-review/review-round-10.md:82` — frozen code-review snapshot (preserved as audit history)

No active design surface retains stale "13 services" / "4 helpers" claims post-rebuttal. Reviewer's expected Round 10 verify-only re-certification: **0 findings**.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (2/2) | ทั้ง MEDIUM + LOW finding ผ่าน Defender independent re-verification ครบ; ไม่มี reject เพราะ empirical evidence (file tree + § 5 subsection enumeration + git show pre-BT-002 base) แข็งกว่า narrative count ที่ cascade-arithmetic ใช้ผิด |
| Critical Fixes | 0 | ไม่มี CRITICAL/HIGH — round นี้เป็น count-discipline cleanup ของ off-by-one ที่ลากยาวข้าม pre-BT-002 → BT-002 cascade → Round 07/08 verify; ไม่มี architecture / API / DB / pattern หรือ behavioral drift |
| Cross-Domain Fixes | 2 (cascade-completion) | TD-02 ↔ SD-02 ↔ ADR-012 count alignment; ทั้ง 3 surface ตอนนี้สื่อ "11 services + 5 helpers" ตรงกัน + reference TD-02 § 2 file tree เป็น authoritative empirical source |
| Net Improvement | High | จาก 3-way disagreement (TD=12 / SD=13 / ADR=13 / empirical=11) → single-source-of-truth = 11 services + 5 helpers ทุก doc; anti-regression gates G8/G9/G10 ใน Round 09 review จะ pass clean ที่ Round 10 verify |
| Remaining Gaps | 2 out-of-scope pointers (preserved per Round 07/08 precedent) | (i) `CLAUDE.md § 3` "12 services + 4 helpers"; (ii) `.claude/rules/ea.md § Project Structure` "12 services" — ทั้งคู่ project-bootstrap surfaces; resolved via mandatory `/project-init --regen` per `backtrack-workflow.md § Project Bootstrap Invalidation` row "TD = Always invalidated" (operator action, not TD-scope) |

## Recommendation

- [x] **Ready for Implementation Handoff** — all Critical/High claims resolved (none surfaced Round 09); MEDIUM + LOW count-cascade-completion applied across TD-02 + SD-02 + ADR-012; cross-domain consistency verified empirically (post-fix repo-wide grep clean on active design surfaces; remaining hits confined to frozen audit history)
- [ ] **Request Re-Review** — Round 10 verify-only re-certification will close to 0 findings per reviewer's own stated expected outcome (`claim-review-09.md § Recommendation`: *"Round 10 verify-only re-certification expected 0 findings"*); not strictly required by methodology, but consistent with Round 07 → 08 verify-after-substantive-rebuttal precedent
- [ ] **Needs SD Backtrack** — N/A; this round's SD cascade-completion is count-correction (number drift), not architecture-decision drift; ADR-012 file-layout-module-split-discipline preserves all 4 rationales (R1-R4) + counts updated as derived-fact, not new ADR
- [ ] **Needs Stakeholder Input** — N/A

## Follow-up Operator Actions (out-of-scope reminders, NOT applied in this rebuttal)

1. **`/project-init --regen`** — mandatory per `backtrack-workflow.md § Project Bootstrap Invalidation` row ("TD = Always invalidated"). Will refresh `CLAUDE.md § 3` "12 services + 4 helpers" → "11 services + 5 helpers" + `.claude/rules/ea.md § Project Structure` services list against post-Round-09 corrected TD-02 + ADR-012. Same precedent as Round 07 close → Round 08 `/project-init --regen` (deferred until Round 10 verify-only re-cert closes, to avoid double-regen churn).
2. **`docs/state/overview.md` snapshot refresh** — derived-view update via `/next` Check 5.5 (CLAUDE.md § 6 State Reconciliation Discipline) on next status sweep; no rebuttal-side write per discipline.

---

## End of Rebuttal Round 09
