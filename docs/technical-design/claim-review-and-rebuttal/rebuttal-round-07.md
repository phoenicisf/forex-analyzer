# Technical Design Rebuttal Round 07 — BT-002 Cascade Application

| Field | Value |
|-------|-------|
| **Round** | 07 |
| **Claim Review** | `claim-review-07.md` |
| **Date** | 2026-05-18 |
| **Defender Persona** | andm-td-defender (Intellectually-honest TD architect) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design, mql-developer |
| **Outcome** | ✅ **All 14 findings accepted + cascade applied** — TD package now single-voice with SD/ADR/BA/api-spec post-BT-002. No SD/ADR/yaml touched (already locked at BT-002 SD R09 + BA R06 closure). |

## Summary

| Verdict | Count |
|---------|-------|
| Accepted | 14 |
| Partial | 0 |
| Rejected | 0 |

> **Single root cause:** Reviewer correctly identified all 14 surfaces as un-propagated BT-002 cascade from upstream backtrack (commits `e385ad0` SD R09 final + `863493e` BA cascade + commit `538e990` BA rebuttal-round-05 closure). No design judgment required — all edits are deletion/sync-to-authoritative-source. Defender accepts reviewer's prescribed minimum fixes verbatim with two minor enhancements (audit-trail strikethrough preservation in DI table + class diagram instead of silent row delete, to keep Round 03/04 Claim cite labels stable).

---

## Claim Responses

### Claim 07.1: 🔴 CRITICAL — § 5.8 CCircuitBreaker skeleton + § 2 file tree
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.8 (former lines 875-898)
- What changed: ลบ class skeleton block ทั้งหมด (header + Responsibility line + `class CCircuitBreaker { ... }` declaration with CloseEvent struct + buffer + Init/CheckPingPong/RecordOpen/RecordClose methods); แทนด้วย one-line BT-002 audit pointer ที่ link ไปยัง ADR-010 § Revision history + backtrack-log § BT-002
- File: `docs/technical-design/02-backend-design.md`, Section: § 2 Project File Layout (former line 66)
- What changed: ลบ `│   ├── CircuitBreaker.mqh` row จาก `services/` block (file tree now lists 11 service files, matching post-BT-002 source tree)
- Evidence: `grep -cE "^class CCircuitBreaker" docs/technical-design/02-backend-design.md` → 0
- Cascaded to: § 5 header count (Claim 07.10), § 7.1/7.3/7.4/7.4.1 wire-up sites (Claim 07.4/07.6), § 8.1 diagram (Claim 07.5)

### Claim 07.2: 🔴 CRITICAL — TD-04 § 4.3 halt_reason enum drift
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/04-database-design.md`, Section: § 4.3 line 226
- What changed: เปลี่ยน enum value list จาก 5 ค่า → 4 ค่า (`[handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null]`); append authoritative-source annotation pointing back ที่ `trade-journal-schema.yaml § halt_reason` + BT-002 audit cite + cap-3 iter chain ADR-013→ADR-014 falsified note
- Evidence: line 226 now reads `halt_reason ... [handle_invalid_runtime, equity_floor_phase2, journal_write_fail_sustained, null] (see trade-journal-schema.yaml § halt_reason authoritative; circuit_breaker_pingpong removed per BT-002 ...)`
- Cascaded to: TD-04 Last-Updated header (Claim 07.13), TD-04 § 9 access matrix (Claim 07.7)

### Claim 07.3: 🟠 HIGH — § 7.4 OnTick step 4 CheckPingPong call
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnTick flow (former lines 1506-1510 / now lines ~1482-1486)
- What changed: ลบ 4-line if-block (`if (m_breaker.CheckPingPong(...)) { Halt("circuit_breaker_pingpong"); ...}`) + replace ด้วย 3-line BT-002 audit comment ระบุ "step 4 removed; handle_invalid_runtime = Phase 1 sole automated halt trigger per ADR-010 amendment; Phase 2 candidates"; **leave step numbering gap (skip 4)** เพื่อลด churn ที่ step-label cites
- Evidence: `grep -nE "CheckPingPong\("` → 0 hits ใน TD-02
- Cascaded to: SD `04 § 1.1` mermaid alt-branch already removed pre-BT-002 SD R07-R09 closure

### Claim 07.4: 🟠 HIGH — § 7.1 field + § 7.3 DI row + § 7.4 Phase B Init
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.1 Orchestrator skeleton line 1432
- What changed: เปลี่ยน `CCircuitBreaker *m_breaker;` → BT-002 removal comment line (preserves field-position ใน source for visual diff readability)
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.3 DI wire-up map line 1575 (row 10)
- What changed: เปลี่ยน row entry เป็น strikethrough audit-trail (`| ~~10~~ | ~~CCircuitBreaker~~ | (removed per BT-002...) | |`); **preserved row** (not deleted) ตาม Defender choice เพื่อเก็บ Round 03/04 Claim 03.4 + 04.3 numbering convention cite ที่ stable (เลข 10 ใน table = audit reference; subsequent step numbers unchanged)
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase B line 1612
- What changed: เปลี่ยน `m_breaker.Init(m_logger);` → BT-002 removal comment line (preserves Phase B ordering visual)
- Evidence: `grep -nE "m_breaker\."` → 0 hits ใน TD-02 (only audit comments remain)
- Cascaded to: § 7.4.1 step 10 deletion (Claim 07.6), § 7.3 numbering convention paragraph count update (Claim 07.10), § 8.1 classDiagram (Claim 07.5)

### Claim 07.5: 🟠 HIGH — § 8.1 classDiagram CCircuitBreaker block + edge + field
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 8.1 classDiagram
- What changed:
  - Line 1738 (former 1763) — ลบ `-CCircuitBreaker* m_breaker` field จาก COrchestrator class block (field count drops 19→18 per Round 04 G3 gate update)
  - Lines 1802-1804 (former 1828-1830) — replace `class CCircuitBreaker { +CheckPingPong(port,now) bool }` block ด้วย Mermaid comment (`%%`) BT-002 removal audit line
  - Line 1873 (former 1898) — replace `COrchestrator --> CCircuitBreaker` edge ด้วย Mermaid comment audit line
- Evidence: `grep -cE "^class CCircuitBreaker"` → 0; class diagram now renders 17 service classes (was 18)
- Cascaded to: Round 04/05 G3 anti-regression gate value updated implicitly (19→18); Claim 07.13 Last-Updated stamp logs the cascade explicitly

### Claim 07.6: 🟠 HIGH — § 7.4.1 CleanupPartialInit step 10
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 line 1679 (former 1705)
- What changed: เปลี่ยน `if (m_breaker != NULL) { delete m_breaker; ... } // step 10` → 2-line BT-002 audit comment ระบุ "step 10 removed; step gap intentionally preserved to keep Round 03 Claim 03.2 monotonic-descent cite stable (17→16→...→11→9→...→1)"
- Evidence: post-fix grep `m_breaker !=` → 0 hits
- Cascaded to: Round 03 Claim 03.2 monotonic-descent narrative unchanged (gap preserved by design); 8-sites CleanupPartialInit semantic anchor at § 7.4.1 line ~1697 still correct (CB never had INIT_FAILED gate per reviewer's own analysis)

### Claim 07.7: 🟡 MEDIUM — TD-04 § 9 access matrix CircuitBreaker row
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/04-database-design.md`, Section: § 9 Access Pattern Matrix line 500
- What changed: เปลี่ยน row `| CircuitBreaker | — | — | (writes halt event via TJ) | ...|` → strikethrough audit row ระบุ "halt event writes now routed via `Orchestrator → CEAState.Halt()` direct path on `IndicatorService::AnyHandleInvalid()` per ADR-010 amendment + SD `02 § 5.1` Communication Matrix"
- Evidence: Single-writer property claim ที่ line 505 still valid post-BT-002 (no writer conflict introduced)
- Cascaded to: TD-04 Last-Updated header (Claim 07.13)

### Claim 07.8: 🟡 MEDIUM — § 7.0.3 CEAState skeleton comment
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.0.3 CEAState skeleton line 1394
- What changed: เปลี่ยน 2-line comment `// Entry point ของ all halt triggers: CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure (ADR-006), force-clear escalation (ADR-008 — future)` → 5-line comment listing post-BT-002 trigger taxonomy: "IndicatorService runtime invalid (Phase 1 sole automated trigger), journal sustained-failure (Phase 2 candidate per ADR-006), equity-floor (Phase 2 candidate per ADR-010 Revisit-when), force-clear escalation (Phase 2 candidate per ADR-008 — future)"; explicit cite ADR-010 amendment + BT-002 date
- Evidence: comment now consistent with ADR-010 § Revision history post-amendment
- Cascaded to: Claim 07.9 (Logger ErrorBypassThrottle caller list mirror)

### Claim 07.9: 🟡 MEDIUM — § 5.7 + § 9.4 Logger ErrorBypassThrottle comments
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 Logger interface line 853
- What changed: เปลี่ยน `(CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure)` → `(IndicatorService runtime invalid Phase 1; Phase 2 candidates: equity-floor, journal sustained-failure; CircuitBreaker removed per BT-002 2026-05-17 ADR-010 amendment)`
- File: `docs/technical-design/02-backend-design.md`, Section: § 9.4 Logger ErrorBypassThrottle line 2071
- What changed: เปลี่ยน `(CircuitBreaker / handle_invalid / journal_sustained / force-clear)` → `(handle_invalid Phase 1 sole / journal_sustained Phase 2 / equity_floor Phase 2 / force-clear Phase 2 future; CircuitBreaker removed per BT-002 2026-05-17)`
- Evidence: ADR-011 § Halt-trigger bypass scope unchanged (bypass mechanism intact; caller list shrinks only)
- Cascaded to: aligned with Claim 07.8 trigger taxonomy

### Claim 07.10: 🟡 MEDIUM — Service count statements 5 spots
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, all 5 spots:
  - Line 24 (§ 1 section index): `Services × 13` → `Services × 12 (post-BT-002 2026-05-17 — former CCircuitBreaker removed)`
  - Line 464 (§ 5 header): `## 5. Services Layer (13 services)` → `## 5. Services Layer (12 services post-BT-002 2026-05-17; former § 5.8 CCircuitBreaker removed legacy-parity)`
  - Line 1558 (§ 7.3 numbering convention paragraph): `16 services + 1 helpers row` → `15 services + 1 helpers row` + `16 × Init()` → `15 × Init()` + `Total table rows = 19` → `Total table rows = 18 (... + 1 struck row preserved for audit)` + `16 services + 3 helper classes` → `15 services + 3 helper classes` + `total Phase B Init() calls = 16` → `15` + `× 16 services + 3 helpers` → `× 15 services + 3 helpers`; appended "Pre-BT-002 values (16/16/19) preserved in this note for audit lineage" sentence
  - Line 1657 (§ 7.4 reviewer checklist): `× 16 services + 3 helpers ... = 16 Init calls` → `× 15 services + 3 helpers ... = 15 Init calls`
  - Line 2490 (end-of-doc footer): `13 services + 21 slots + 4 helpers + 4 domain types` → `12 services + 21 slots + 4 helpers + 4 domain types (post-BT-002 2026-05-17 — former CCircuitBreaker removed legacy-parity)`
- Evidence: All 5 spots now read 12/15/15 consistently; audit lineage preserved at line 1558 narrative
- Cascaded to: CLAUDE.md § 2 Tech Stack row "13 services" — out-of-scope for TD review per reviewer's own flag (Project-level); flagged for awareness for next `/project-init --regen` cycle (mandatory per backtrack-workflow.md § Project Bootstrap Invalidation row)

### Claim 07.11: 🟡 MEDIUM — § 2 file tree CircuitBreaker.mqh
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 2 file tree line 66
- What changed: ลบ `│   ├── CircuitBreaker.mqh` row จาก `services/` block (combined edit with Claim 07.1 — single Edit() call covered both surfaces)
- Evidence: `services/` block now lists 11 files; reviewer's pre-existing discrepancy (file tree=12 vs § 5 header=13) note correctly preserved post-fix as 11 vs 12 (off-by-one historical drift unchanged — flagged separately for future tightening pass, not in scope of BT-002 cascade)
- Cascaded to: `.claude/rules/ea.md § Project Structure` mirror — out-of-scope for TD review (project-level rules file); flagged for next `/project-init --regen`

### Claim 07.12: 🟡 MEDIUM — TD-03 § 2 Alert popup trigger list
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/03-frontend-design.md`, Section: § 2 Operator Surface Inventory line 42 (trigger column)
- What changed: เปลี่ยน `CircuitBreaker triggered, IndicatorService runtime invalid, journal sustained-failure, force-clear, HALTED_STABLE transition` → `IndicatorService runtime invalid (Phase 1 sole automated halt trigger post-BT-002 2026-05-17 per ADR-010 amendment — former CircuitBreaker trigger removed legacy-parity), journal sustained-failure (Phase 2 candidate), equity-floor (Phase 2 candidate per OQ-6), force-clear, HALTED_STABLE transition`
- Evidence: `grep -cE "CircuitBreaker triggered" docs/technical-design/03-frontend-design.md` → 1 hit (only Last-Updated header audit text)
- Cascaded to: TD-03 Last-Updated header (Claim 07.13)

### Claim 07.13: 🔵 LOW — Last-Updated stamps all 3 docs
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md` line 5 — bumped to 2026-05-18 with full cascade breadcrumb (BR-3.6 removal + ADR-013/014 superseded + 8 section cascade surfaces enumerated + count decrement note + "Prior: 2026-05-02 Round 06 handoff certification" historical breadcrumb mirroring SD post-cascade format)
- File: `docs/technical-design/03-frontend-design.md` line 6 — bumped to 2026-05-18 with § 2 Alert trigger update breadcrumb
- File: `docs/technical-design/04-database-design.md` line 5 — bumped to 2026-05-18 with § 4.3 enum sync + § 9 access matrix struck breadcrumb
- Evidence: `grep "Last updated:" docs/technical-design/*.md` → all 3 show 2026-05-18 + BT-002 cascade note
- Cascaded to: mirrored SD post-cascade stamp format exactly per reviewer's prescription

### Claim 07.14: 🔵 LOW — § 10.1 trace matrix ADR-013/014 audit row
**Verdict:** Accept
**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 10.1 Class ↔ ADR ↔ API spec (after row `File layout` line 2167)
- What changed: append strikethrough audit row `| ~~CCircuitBreaker~~ (former) | ADR-013 + ADR-014 — Superseded by BT-002 2026-05-17 (preserved as audit history of cap-3 iter chain: iter-1 ✅ → iter-2 ❌ → iter-3 ❌ → escalation gate → operator approved Option 1 detector removal) | ~~trade-journal-schema.yaml § halt_reason~~ — circuit_breaker_pingpong enum value REMOVED per BT-002 (breaking change OK Phase 1) | — (no CB state ever persisted per ADR-014 § Migration) |` + footer note ระบุ active ADR count = 12 + Superseded = 2 (total = 14) + backtrack-log § BT-002 pointer
- Evidence: Phase 3 Quality Gate ใช้ § 10.1 ที่จะมี audit row สำหรับ ADR-013/014 — no longer "blind" to BT-002 falsification narrative
- Cascaded to: implicit BT-002 cascade footer at § 10 header — captures the SD `02 § 9 ADR Digest` lines 472-473 mirror requirement

---

## Cascaded Changes (beyond reviewer's enumeration)

None — Defender adhered strictly to reviewer's prescribed 23 edit sites. No additional surfaces touched in TD package. No SD/ADR/api-spec/BA changes (all already locked post-BT-002 SD R09 + BA R06 closure per reviewer's "Defender SHOULD NOT propose changes to SD/ADR/yaml" directive).

**Defender enhancement (not Cascade — Editorial choice):** at Claim 07.4 + 07.6 + 07.5, chose **strikethrough preservation** (struck row / `%%` mermaid comment) instead of silent deletion. Rationale: preserves Round 03/04 Claim cite labels (row "10" / "step 10" / classDiagram block) so future reviewers reading rebuttal-round-03/04/05 narratives can grep + locate the audit context. Tradeoff: 1 extra audit line per surface vs Round 27+ Code Reviewer back-traceability. Mirror of SD `02 § 4.2` footer pattern (Component Catalog row #14 "Removed per BT-002 2026-05-17" footnote).

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (14/14) | Single-cause cascade — no design judgment contests; all reviewer claims validated by upstream BT-002 authority |
| Critical Fixes | 2 | § 5.8 skeleton DELETE + TD-04 § 4.3 enum sync — primary blocker surfaces removed |
| Cross-Domain Fixes | 13 | All cross-domain consistency issues X1-X13 (per reviewer's table) resolved single-pass |
| Net Improvement | TD package single-voice with SD/ADR/BA/api-spec post-BT-002 | Engineer can now derive valid implementation directly from TD-02/03/04 without first reconciling 14 drift sites |
| Remaining Gaps | 0 in scope | Two out-of-scope pointers logged: (i) CLAUDE.md § 2 "13 services" + `.claude/rules/ea.md § Project Structure` `CircuitBreaker.mqh` — both project-bootstrap surfaces, will resolve via mandatory `/project-init --regen` next step per backtrack-workflow row "TD = Always invalidated"; (ii) pre-existing § 2 file tree (12) vs § 5 header (13) off-by-one drift preserved (now 11 vs 12 post-fix) — flagged as historical-drift cleanup candidate, not BT-002 scope |

## Recommendation

- [x] **Ready for Implementation Handoff (post Round 08 verify-only)** — all 14 findings resolved; cross-domain consistency verified via G1-G7 anti-regression gates (all green or only audit-text hits)
- [x] **Request Re-Review (Round 08 verify-only sweep)** — confirms reviewer's projected "Round 08 = 0 findings re-certification" outcome
- [ ] Needs SD Backtrack — N/A (SD + BA + ADR + api-spec already locked at BT-002 closure)
- [ ] Needs Stakeholder Input — N/A

### Anti-Regression Gate Results

| Gate | Command | Expected | Actual |
|------|---------|----------|--------|
| G1 (CB skeleton DELETE) | `grep -cE "^class CCircuitBreaker" docs/technical-design/02-backend-design.md` | 0 | **0** ✅ |
| G2 (CheckPingPong/m_breaker code positions) | `grep -nE "CheckPingPong\(\|m_breaker\." docs/technical-design/02-backend-design.md` | 0 code hits | **0 code hits** (1 audit-comment hit at line 1613) ✅ |
| G3 (TD-04 halt_reason value) | `grep -cE "halt_reason.*circuit_breaker_pingpong" docs/technical-design/04-database-design.md` | 0 hits as enum value | **2 hits** — both audit-text (line 6 Last-Updated stamp + line 226 enum-annotation note); 0 hits as enum value ✅ |
| G4 (TD-03 Alert trigger) | `grep -cE "CircuitBreaker triggered" docs/technical-design/03-frontend-design.md` | 0 hits as trigger | **1 hit** — audit-text only (line 6 Last-Updated stamp); 0 hits as live trigger ✅ |
| G5 (service count consistency) | `grep -nE "13 services\|16 services\|16 Init calls" docs/technical-design/02-backend-design.md` | 0 stale hits | **0 stale hits** (all 5 spots show 12/15/15 + audit-lineage note) ✅ |
| G6 (Last Updated stamps) | `grep "Last updated:" docs/technical-design/*.md` | All 3 = 2026-05-18 + BT-002 note | **All 3 = 2026-05-18 + BT-002 cascade breadcrumb** ✅ |
| G7 (cross-doc CB scan) | `grep -rcE "CircuitBreaker\|CheckPingPong" docs/technical-design/*.md` | TD = 0 code-position hits; only historical annotation hits | **TD-02 = 18 audit-text hits (all strikethrough/comments/stamps); TD-03 = 2 hits (header stamp + audit text); TD-04 = 3 hits (header + struck row + enum annotation)** ✅ |

> **All gates pass** — no live code/spec/diagram surface references CircuitBreaker as an active service. All remaining mentions are intentional audit-trail preservation (strikethrough rows, `%%` Mermaid comments, BT-002 stamp text, "removed per BT-002" annotation notes). Round 08 verify-only sweep should produce 0 findings per reviewer's projection.

### Round-Over-Round Trend (updated)

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Phase context |
|-------|----------|------|------|--------|------|----|
| 01 | 20 | 5 | 8 | 5 | 2 | Initial scan |
| 02 | 9 | 1 | 2 | 5 | 1 | Convergence pass-1 |
| 03 | 8 | 0 | 3 | 3 | 2 | Convergence pass-2 |
| 04 | 3 | 0 | 0 | 0 | 3 | Polish |
| 05 | 1 | 0 | 0 | 0 | 1 | Path B intent statement |
| 06 | 0 | 0 | 0 | 0 | 0 | ✅ Handoff Certification (2026-05-02) |
| 07 (this) — accepted | **14 → 0** | **2 → 0** | **4 → 0** | **6 → 0** | **2 → 0** | BT-002 cascade applied |
| 08 (projected) | 0 | 0 | 0 | 0 | 0 | Verify-only re-certification expected |

---

## Next Suggested Actions (post-Round 07 closure)

1. **`/td-review all`** (Round 08 verify-only sweep) — confirm 0-findings re-certification per reviewer's projection
2. After ✅ → **`/project-init --regen`** (mandatory per `backtrack-workflow.md § Project Bootstrap Invalidation` row "TD = Always invalidated") — resolves CLAUDE.md § 2 "13 services" + `.claude/rules/ea.md § Project Structure` CircuitBreaker.mqh stale references via fresh derivation from updated TD
3. After ✅ → **`/impl-plan-review all`** — Plan QA pair (IMPL-051 cancellation + IMPL-FIX-012 closure pivot from BT-002 § Impacted phases — Impl Plan)
4. After ✅ → **impl-code cleanup** (one or more `IMPL-FIX-*` tickets to DELETE `services/CircuitBreaker.mqh` + strip `Record{Open,Close}` dispatch + ADR-013 DEAL_REASON filter + ADR-014 DEAL_ENTRY branching from `core/Orchestrator.mqh::OnTradeTransaction` + remove `CheckPingPong` call from `OnTick` + DELETE `spike/Spike_CircuitBreaker.mq5` + verify `domain/EnumTypes.mqh` for `HALT_PINGPONG` constant removal)
5. After ✅ → **IMPL-062/063 Bucket A 5-yr re-run** (gated on full BT-002 cascade closure + impl-code delete completion per backtrack-log § BT-002 § Impacted phases — Impl Code)

**Blocks unblocked by this closure:** TD-side rework (Round 08 can now run); subsequent gates `/project-init --regen` → `/impl-plan-review all` → impl-code cleanup → IMPL-062/063 re-run unlocked sequentially.
