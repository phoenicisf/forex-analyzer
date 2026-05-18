# Technical Design Claim Review Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Target Document** | `all` (TD-02 / TD-03 / TD-04) |
| **Date** | 2026-05-18 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |
| **Scope** | Verify-only re-walk of BT-002 cascade: TD-02 § 5.8 CCircuitBreaker skeleton DELETE + 10 cross-refs cleanup (per `backtrack-log.md § BT-002 Impacted phases TD` lines 66/854/1418/1456/1506/1599/1763/1828/1898/2099 → current 66-clean / 853 / 1394 / 1435 / 1485 / 1576 / 1805 / 1873 / 2074 / 2168) |
| **Mode** | Independent verify-only (NOT a sign-off of Round 08); re-walks the cascade against authoritative SD / ADR / api-spec / file tree |

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 0 |
| 🟠 HIGH | 0 |
| 🟡 MEDIUM | 1 |
| 🔵 LOW | 1 |
| **Total** | **2** |

> **Verdict:** ⚠️ **Cascade body clean; cascade arithmetic stale.** The 10-cross-ref cleanup itself verifies clean — § 2 file tree no longer lists `CircuitBreaker.mqh`, § 5.8 has been replaced with a one-line BT-002 audit pointer, § 7.x wire-up sites (Init / OnTick step 4 / cleanup step 10) carry audit comments not active code, § 8.1 mermaid class skeleton struck, § 10.1 trace matrix preserves the ADR-013/ADR-014 `Superseded by BT-002` audit row. **However**, the BT-002 cascade's narrative arithmetic "services count 13 → 12" is itself off-by-one against the empirical file tree (and was off-by-one pre-BT-002 too — `aebec01~1:02-backend-design.md:465` header was `## 5. Services Layer (13 services)` but file tree + § 5 subsections enumerated only 12). Post-BT-002 the doc says "12 services" but file tree + § 5 active subsections show **11**. This is a math drift, not a CB-leak; the BT-002 cleanup applied the documented `−1` op against a wrong base. Recommend rebuttal acknowledgment + cascade-completion to SD `02 § 1 line 128` ("13 services + 21 slots") + ADR-012 line 100 ("13 services + ... = ~52 files") which are now downstream-stale to BOTH the empirical truth (11) and the BT-002 narrative (12).

---

## Technical Design Attack Vector Checklist (20 categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Contract Completeness | ✅ Pass | `docs/api-specs/*.yaml` referenced authoritatively; § 10.1 trace matrix intact; `circuit_breaker_pingpong` enum strip verified in `trade-journal-schema.yaml § halt_reason`. |
| 2 | API Contract Consistency | ✅ Pass | No naming/auth/error drift introduced by BT-002 cascade. |
| 3 | Backend Module Boundaries | ⚠️ Finding | 5-layer direction preserved; ADR-012 file-tree direction compliant; **but** services count narrative ("12") inconsistent with § 2 file tree (11 entries lines 59-69) + § 5 active subsections (5.1-5.7, 5.9-5.12 = 11) → Finding 09.1. |
| 4 | Backend Interface Contracts | ✅ Pass | Service interfaces × 11 active (post-BT-002) with method signatures + DI map intact; `m_breaker` field removed cleanly with audit comment at TD-02:1435. |
| 5 | CQRS/Command-Query Separation | ✅ N/A | EA architecture = single-process intra-MT5; CQRS not adopted per ADR-001. |
| 6 | Frontend Component Hierarchy | ✅ N/A | TD-03 § 1 documents Frontend = N/A. |
| 7 | Frontend State Management | ✅ N/A | Same as #6. |
| 8 | Frontend-Backend Contract Alignment | ✅ Pass | TD-03 § 2 Alert trigger list synced to ADR-010 amendment (former "CircuitBreaker triggered" entry removed legacy-parity at line 42); IndicatorService runtime invalid = Phase 1 sole automated halt trigger. |
| 9 | Database Schema Completeness | ✅ Pass | TD-04 § 4.3 `halt_reason` enum at line 226 = 4 values + null + authoritative reference; aligned with `trade-journal-schema.yaml § halt_reason`. |
| 10 | Database Index Strategy | ✅ N/A | File-based persistence; no RDBMS indexes. |
| 11 | Database Migration Safety | ✅ Pass | ADR-014 § Migration "no CB state ever persisted" applied; TD-04 § 9 line 500 struck CircuitBreaker row preserves audit lineage. |
| 12 | Design Pattern Justification | ✅ Pass | All 6 pattern code skeletons (composition root / repository / atomic write / tagged logger / JSON-Lines / post-exit hook) retained with ADR cites; no pattern attributable to CB removed. |
| 13 | Sequence Diagram Coverage | ✅ Pass | OnTick flow at § 7.4 step 4 — CheckPingPong call deleted, 3-line BT-002 audit comment in place; numbering gap preserved (step 4 → step 5) per Claim 07.3 rebuttal note for cite stability. |
| 14 | Sequence Diagram Accuracy | ✅ Pass | § 8.1 mermaid classDiagram + § 8.2 composition-root diagram comments out `class CCircuitBreaker` + `COrchestrator --> CCircuitBreaker` edges (lines 1805, 1873). |
| 15 | Test Strategy Adequacy | ✅ Pass | § 13 4-gate Definition of Done unchanged; out of BT-002 scope. |
| 16 | Test Case Traceability | ✅ Pass | § 10.1 traceability matrix line 2168 carries `~~CCircuitBreaker~~ (former)` struck row + `ADR-013 + ADR-014 Superseded by BT-002` annotation; api-spec authoritative cite intact. |
| 17 | Cross-Domain Consistency | ⚠️ Finding | TD-02 "12 services" disagrees with SD `02-high-level-architecture.md:128` ("13 services + 21 slots") AND ADR-012 `:100` ("13 services + ... ~52 files"). All three counts also disagree with empirical file tree (11 service files post-BT-002). See Finding 09.1 (primary) + Finding 09.2 (helpers count side-drift). |
| 18 | Security at Detail Level | ✅ Pass | No security boundary change; ADR-010 amendment (CircuitBreaker removed from halt-trigger list) consistent across TD-02 § 7.1 (line 1394) + TD-03 § 2 (line 42) + TD-04 § 4.3 (line 226). |
| 19 | Error Handling Strategy | ✅ Pass | Halt path now routes through `EAState::SetHalted(reason)` from `IndicatorService::AnyHandleInvalid()` (TD-02 § 7.4 step 5 line 1490); journal `halt_reason` enum reduced to 3 values + null; consistent across TD-02/TD-04/api-spec. |
| 20 | Implementation Readiness | ✅ Pass | No "TBD" introduced; cascade is deletion-only; impl-code cleanup tracked in BT-002 § Impacted phases → `Impl Code` row (out of TD scope). |

---

## Findings

### Claim 09.1: 🟡 MEDIUM — "12 services" count survives BT-002 cascade but disagrees with § 2 file tree + § 5 active subsections (off-by-one carry-over)

**Location:**
- File: `docs/technical-design/02-backend-design.md`
- Sites carrying the stale "12" claim:
  - Line 5 — Last-updated header: `service count statements decremented 13→12 / 16→15 across § 1 / § 5 / § 7.3 / § 7.4 / end-of-doc footer`
  - Line 24 — § 1 ToC: `| § 5 | Services × 12 (post-BT-002 2026-05-17 — former CCircuitBreaker removed)`
  - Line 464 — § 5 header: `## 5. Services Layer (12 services post-BT-002 2026-05-17; former § 5.8 CCircuitBreaker removed legacy-parity)`
  - Line 2490 — End-of-doc footer: `12 services + 21 slots + 4 helpers + 4 domain types`
- Conflicting authoritative empirical sources within the SAME file:
  - Lines 58-69 — § 2 services/ block of file tree: enumerates **11** files (IndicatorService, MarketContextBuilder, PortfolioState, RiskManager, TradeJournal, StatePersistence, Logger, TimeGate, PendingMachineRegistry, CrossSlotCoordinator, PortfolioMonitor)
  - Lines 468-1082 — § 5 active subsections: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, [5.8 struck], 5.9, 5.10, 5.11, 5.12 = **11 active** (12 numbered slots − 1 struck)

**Problem:**
The BT-002 cascade arithmetic "13 → 12" was applied verbatim from the pre-BT-002 § 5 header (verified via `git show aebec01~1:docs/technical-design/02-backend-design.md` → line 465 `## 5. Services Layer (13 services)`), but that pre-BT-002 "13" was itself off-by-one against the pre-BT-002 file tree (which enumerated 12 service files including CircuitBreaker.mqh) and pre-BT-002 § 5 subsections (5.1-5.12 = 12 active). The `−1` op landed the post-BT-002 count at "12" when the empirical truth post-removal is **11**. Round 07 rebuttal accepted all 14 findings as cite-against-authoritative, but the authoritative source for service count is the § 2 file tree + § 5 subsection enumeration — both of which now show 11 — not the narrative header that the cascade decremented. Round 08's own checklist row #3 even said "services/ block now lists 11 files post-CB removal" while row #4 said "Service interfaces × 12 (post-BT-002)" — internal inconsistency in the verify itself.

**Why This Matters:**
Impl Engineer reading § 5 header expects to find 12 service `.mqh` files. The Composition Root in § 7.4 wires the empirical 11 (verified: § 7.4 line 1561 numbering convention says "15 services + 1 helpers row" but DI rows count Init steps not service classes — separate axis). Cross-doc cascade-completion is also blocked: SD `02-high-level-architecture.md:128` and ADR-012 line 100 still carry the **pre-cascade** "13 services" — they were missed by the BT-002 SD R07-R09 sweep. If TD-02 fixes "12 → 11", the cascade-completion must propagate down to SD-02 line 128 (13 → 11) and ADR-012 line 100 (13 → 11; `~52 files` → `~50`). Leaving the off-by-one in place perpetuates count drift across the BT-002 audit footer (line 2170: `Active ADR count = 12 + Superseded = 2 (total = 14)` — this ADR count is independent and verifies clean) and through `CLAUDE.md § 3` (which also carries "**12 services**" per the regen).

**Minimum Acceptable Fix:**
1. Edit TD-02 lines 5 / 24 / 464 / 2490 from "12 services" → "11 services"; rewrite the Last-Updated narrative: `service count statements decremented 13→12 / 16→15` → `service count statements decremented 12→11 (corrects pre-BT-002 off-by-one — pre-cascade header said "13 services" but pre-cascade § 2 file tree + § 5 subsections enumerated 12; post-cascade authoritative count = 11)` (or equivalent attestation that preserves the audit lineage).
2. Cascade-completion ticket OR rebuttal-side `Cascaded Changes` block fixing SD `02-high-level-architecture.md:128` ("13 services + 21 slots" → "11 services + 21 slots") and ADR-012 line 100 ("13 services + 4 domain + 4 helpers + entry = **~52 files**" → "11 services + 4 domain + 5 helpers + entry = **~51 files**"; note Finding 09.2 helpers side-drift if applied jointly).
3. Optional: `CLAUDE.md § 3` ("**12 services**" + "(services count dropped 13→12 per BT-002 cascade)") → "**11 services**" + "(services count dropped 12→11 per BT-002 cascade; pre-BT-002 narrative "13" was off-by-one against file tree)". This is methodology-level, not TD scope — but flag for operator via `/project-init --regen` follow-up.
4. Anti-regression gate: add a `Phase 5 mechanical-gate` style grep for the TD claim-review pipeline that asserts `(grep -cE "^### 5\.[0-9]+" 02-backend-design.md) − (grep -cE "(removed per BT-002|struck post-BT-002)" 02-backend-design.md § 5) == (header-claimed-services-count)` so future cascade arithmetic is caught at rebuttal-time.

**Level of Effort:** Low (textual edits + one cross-doc cascade-completion edit at SD-02 line 128 + ADR-012 line 100; no schema / interface / diagram change)

---

### Claim 09.2: 🔵 LOW — "4 helpers" count in TD-02 footer (and CLAUDE.md) disagrees with § 2 helpers/ block (5 files)

**Location:**
- File: `docs/technical-design/02-backend-design.md`
- Line 2490 — End-of-doc footer: `12 services + 21 slots + 4 helpers + 4 domain types`
- Line 1561 — Numbering convention callout: `1 helpers row (consolidating 3 helper classes: CCommentParser, CJsonWriter, CAtomicFile per § 4)`
- Conflicting authoritative empirical source within the SAME file:
  - Lines 75-80 — § 2 helpers/ block of file tree: enumerates **5** files (CommentParser, PipMath, JsonWriter, AtomicFile, Timestamp); Timestamp.mqh annotated `# FormatTimestampWithMs() — ADR-006/011 ms precision`

**Problem:**
Helpers count has at least three values circulating in the same document — "4 helpers" (footer + CLAUDE.md), "3 helper classes" (DI numbering convention, scoped to stateful helpers with Init), and "5 files" (file tree). The "4" likely predates the addition of `helpers/Timestamp.mqh` (which exists in current code per `IMPL-FIX-009`-era ADR-011 ms-precision wiring) but wasn't refreshed. The "3" is defensible IF the callout text scopes it to "stateful helpers consolidated in DI rows" (CCommentParser, CJsonWriter, CAtomicFile — the ones with Init) — PipMath and Timestamp are pure utility (no Init). This finding flags the FOOTER number, not the DI callout (DI callout is internally consistent with its "consolidating ... per § 4" scope qualifier).

**Why This Matters:**
Pre-existing drift, NOT BT-002-introduced — but exposed by the same cross-domain consistency sweep that surfaced Finding 09.1. Round 08 verify-only didn't catch it because Round 08 narrative scoped to the BT-002 cascade. Out-of-scope leakage from a count-discipline weakness has compounding risk: the next `/project-init --regen` will read the footer + DI callout + file tree and produce a CLAUDE.md that picks one of the three at random, repeating drift downstream.

**Minimum Acceptable Fix:**
- Edit line 2490 footer "4 helpers" → "5 helpers" (matching file tree empirical count). Add a one-clause qualifier in parentheses: `5 helpers (3 stateful via DI per § 7.4 + 2 pure utility — CPipMath, CTimestamp)` so the apparent disagreement with the DI callout is dissolved into a scope-qualified narrative.
- Optional: cascade-completion to `CLAUDE.md § 3` ("4 helpers" → "5 helpers"); flag for operator via `/project-init --regen` follow-up if changes to root CLAUDE.md are gated separately.

**Level of Effort:** Low (single-line edit + optional CLAUDE.md follow-up)

---

## Cross-Domain Issues

| # | Surface | TD-02 claim | SD/ADR claim | Empirical (file tree / § 5) | Status |
|---|---------|-------------|--------------|------------------------------|--------|
| C-1 | Services count | `12` (lines 5/24/464/2490) | `13` (SD `02:128`, ADR-012 `:100`) | `11` (TD-02 § 2 lines 58-69 + § 5 subsections 5.1-5.12 minus struck 5.8) | ⚠️ Finding 09.1 — three-way disagreement (TD ahead of SD by 1, but both behind reality by 1-2) |
| C-2 | Helpers count | `4` (line 2490) ↔ `3 helper classes` (line 1561 DI callout) | `4 helpers` (ADR-012 `:100`) | `5` (TD-02 § 2 lines 75-80) | ⚠️ Finding 09.2 — pre-existing drift exposed by sweep |
| C-3 | `halt_reason` enum | `[handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null]` (TD-04 `:226`) | `trade-journal-schema.yaml § halt_reason` = same 4 values + null | matches | ✅ Pass |
| C-4 | Alert trigger list | `IndicatorService runtime invalid` Phase 1 sole + 4 Phase 2 candidates (TD-03 `:42`) | ADR-010 § Revision history same enumeration | matches | ✅ Pass |
| C-5 | § 7.4 OnTick step 4 | Removed — 3-line BT-002 audit comment (lines 1485-1487) | SD `04 § 1.1` mermaid alt-branch `CircuitBreaker → halt` already removed (commit `0be2a51`) | matches | ✅ Pass |
| C-6 | DI struck row #10 | `~~10~~ ~~CCircuitBreaker~~` preserved with audit narrative (line 1576) | SD `02 § 4.2` Component Catalog row #14 same struck-with-audit pattern | matches | ✅ Pass |
| C-7 | § 8.1 mermaid class | `class CCircuitBreaker` commented out (line 1805) + `COrchestrator --> CCircuitBreaker` edge commented (line 1873) | SD `04 § 1.1` mermaid same removal | matches | ✅ Pass |
| C-8 | § 10.1 trace matrix | `~~CCircuitBreaker~~` struck row with `ADR-013 + ADR-014 Superseded by BT-002` (line 2168) + footer audit (line 2170 `Active ADR count = 12 + Superseded = 2 (total = 14)`) | ADR-013 + ADR-014 file headers carry `Status: Superseded by BT-002 2026-05-17` (verified) | matches | ✅ Pass |

---

## Anti-Regression Gates Re-Run (per `rebuttal-round-07.md § Anti-Regression Gate Results` extension)

| Gate | Check | Status |
|------|-------|--------|
| G1 | `grep -cE "^class CCircuitBreaker" docs/technical-design/02-backend-design.md` | ✅ 0 (skeleton deleted) |
| G2 | `grep -cE "CheckPingPong\(" docs/technical-design/02-backend-design.md` | ✅ 0 (call site deleted in step 4) |
| G3 | `grep -cE "m_breaker\." docs/technical-design/02-backend-design.md` | ✅ 0 (DI field deleted) |
| G4 | `grep -nE "circuit_breaker_pingpong" docs/technical-design/04-database-design.md docs/api-specs/trade-journal-schema.yaml` | ✅ 0 in TD-04 § 4.3 enum; 0 in api-spec authoritative enum |
| G5 | `grep -nE "CircuitBreaker triggered" docs/technical-design/03-frontend-design.md` | ✅ 0 (Alert trigger list cleaned) |
| G6 | ADR-013 + ADR-014 status field | ✅ both = `Superseded by BT-002 2026-05-17` |
| G7 | TD-02 audit-trail preservation (struck rows, commented mermaid, audit comments) | ✅ 7 audit-trail markers preserved across lines 853, 874, 1394, 1435, 1485-1487, 1576, 1805, 1873, 2074, 2168, 2170 |
| **G8** *(new)* | Service-count internal consistency: header narrative vs § 2 file tree vs § 5 active subsections | ❌ **3-way mismatch (12 / 11 / 11) — Finding 09.1** |
| **G9** *(new)* | Helper-count internal consistency: footer vs § 2 file tree vs DI callout scope qualifier | ❌ **3-way drift (4 / 5 / 3-with-scope-qualifier) — Finding 09.2** |
| **G10** *(new)* | Cross-doc count consistency: TD-02 services count vs SD `02:128` vs ADR-012 `:100` | ❌ **TD = 12, SD = 13, ADR-012 = 13 — Finding 09.1 cascade-completion** |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 09.1 | 🟡 MEDIUM | "12 services" count survives BT-002 cascade but off-by-one vs file tree + § 5 active subsections (cascade arithmetic applied to wrong base) | TD-02 lines 5/24/464/2490 + SD `02:128` + ADR-012 `:100` | Low |
| 09.2 | 🔵 LOW | "4 helpers" footer disagrees with § 2 file tree (5 files: + Timestamp.mqh ADR-006/011 ms precision) | TD-02 line 2490 (+ optional CLAUDE.md `§ 3` cascade) | Low |

---

## Recommendation

- **Cascade body:** ✅ Clean. The 10 cross-refs cited in `backtrack-log § BT-002 Impacted phases TD` are all empirically verified deleted / replaced with audit comments / struck-with-preserved-narrative. Round 07 rebuttal applied verbatim; Round 08 verify recorded clean on the cascade itself.
- **Cascade arithmetic:** ⚠️ Off-by-one. The `−1` op (CircuitBreaker removal) was applied against a pre-BT-002 base of "13 services" that was already off-by-one — empirically pre-BT-002 = 12, post-BT-002 = 11, but doc says 12.
- **Action:** Run `/td-rebuttal claim-review-09.md` to acknowledge Finding 09.1 (apply correction TD-02 4 sites + Cascaded Changes block fixing SD `02:128` + ADR-012 `:100`) and Finding 09.2 (single-line footer edit + flag CLAUDE.md follow-up). Expected outcome: Round 09 rebuttal will close 2/2 Accept; Round 10 verify-only re-certification expected 0 findings.
- **Project-init follow-up:** Operator should re-trigger `/project-init --regen` after TD-02 / SD-02 / ADR-012 land their count fix so `CLAUDE.md § 3` "**12 services**" + "**4 helpers**" is regenerated against the corrected upstream truth.

---

## End of Claim Review Round 09
