# Technical Design Claim Review Round 05

| Field | Value |
|-------|-------|
| **Round** | 05 |
| **Target Document** | `rebuttal-round-04.md` (verification sweep + holistic class-block scan per defender's invitation) |
| **Date** | 2026-05-02 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, mql-developer |

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 0 |
| 🟠 HIGH | 0 |
| 🟡 MEDIUM | 0 |
| 🔵 LOW | 1 |

> **Round-over-round trajectory:** 20 → 9 → 8 → 3 → **1**. Severity ceiling = 0 across CRITICAL/HIGH/MEDIUM sustained. Round-04 fixes ทั้ง 3/3 ผ่านสมบูรณ์. Single round-05 finding = systematic § 8.1 class-block drift ที่ defender's Note for Reviewer round-05 invited การตรวจ — pre-existing pattern ขยายผลจาก Claims 03.7 + 04.2 ไปยัง 7 classes ที่เหลือ.

---

## Round-04 Rebuttal Verification — All 3 Fixes Confirmed

| # | Claim 04.X | Verdict | Evidence (line) | Pass |
|---|------------|---------|------------------|------|
| 1 | 04.1 (LOW) — § 7.4.1 line range cite | Accept | Line 1722: replaced brittle line range ด้วย semantic anchor `4 guards before m_state.Load + 4 guards after m_ea_state.RestoreFromState` (8 method names = stable anchors) | ✅ |
| 2 | 04.2 (LOW) — § 8.1 COrchestrator block | Accept | Lines 1748-1772: 19 fields (counted) + 4 public methods (OnInit, OnTick, OnDeinit, CleanupPartialInit). Order matches DI table § 7.3 step 1 → 17 | ✅ |
| 3 | 04.3 (LOW) — § 7.3 vs § 7.4 helpers framing | Accept | Line 1584: callout expanded ด้วย `1 helpers row (consolidating 3 helper classes: CCommentParser, CJsonWriter, CAtomicFile per § 4)` + math-consistency footer | ✅ |

### Anti-Regression Gates (per defender's § Anti-Regression Gates)

| Gate | Command | Expected | Actual | Status |
|------|---------|----------|--------|--------|
| G1 | `grep -nE "× 18\|5 sites\|step 6\.5\|step 7b\|lines 1647-1668" 02-backend-design.md` | 0 hits | 0 hits | ✅ Pass |
| G2 | Init() call count in Phase B (lines 1622-1651) | 16 | 16 (m_logger, m_pip, m_state, m_portfolio, m_indicators, m_ctx_builder, m_risk, m_journal, m_breaker, m_time, m_pending, m_xslot, m_monitor, m_validator, m_registry, m_ea_state) | ✅ Pass |
| G3 | COrchestrator class block field count | 19 | 19 (lines 1749-1767) | ✅ Pass |
| G4 | COrchestrator class block public method count | 4 | 4 (OnInit, OnTick, OnDeinit, CleanupPartialInit) | ✅ Pass |
| G5 (new) | Brittle `lines \d+-\d+` cites in TD-02 | 0 internal cites | 1 hit at line 2120: `yaml line 19-31` (external schema cite — non-brittle since YAML is owned externally + has its own line stability) | ✅ Pass (acceptable external cite) |

> **Z1-Z4 cluster (round-03) regression:** confirmed all 4 closed; round-04 edits did not touch § 7.4.1 body, § 5.7 FindOrEvictKey contract, § 9.4 EscalateIfThresholdMet semantic, or § 8.1 CIndicatorService block.

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Reference in Backend Design | ✅ Pass | api-specs/* references stable |
| 2 | Backend Module Boundaries | ✅ Pass | 16 services + 3 helpers + 21 slots structure stable |
| 3 | Backend Interface Contracts | ✅ Pass | All Init/Setter signatures + cycle-resolver pattern fully documented |
| 4 | CQRS/Command-Query Separation | ⏭️ N/A | EA architecture |
| 5 | Frontend Component Hierarchy | ⏭️ N/A | UX skipped |
| 6 | Frontend State Management | ⏭️ N/A | UX skipped |
| 7 | Frontend-Backend Contract Alignment | ⏭️ N/A | UX skipped |
| 8 | Database Schema Completeness | ✅ Pass | 17-entry slot_states stable |
| 9 | Database Index Strategy | ✅ Pass | Monthly rotation + per-run namespace |
| 10 | Database Migration Safety | ✅ Pass | ADR-006/007 § Revisit-when stable |
| 11 | Design Pattern Justification | ✅ Pass | ADR refs intact |
| 12 | Sequence Diagram Coverage | ✅ Pass | Flow Appendix unchanged |
| 13 | Sequence Diagram Accuracy | ✅ Pass | Method names match skeletons |
| 14 | Testability in TD-02/03/04 | ✅ Pass | Seam points stable |
| 15 | TD↔QA Alignment | ✅ Pass | TD readability unchanged |
| 16 | Cross-Domain Consistency | ✅ Pass | API↔DB↔Skeleton ทุก layer aligned |
| 17 | Security at Detail Level | ✅ Pass | No surface change |
| 18 | Error Handling Strategy | ✅ Pass | CleanupPartialInit + ErrorBypassThrottle + escalate aligned |
| 19 | Implementation Readiness | ⚠️ Minor | Claim 05.1 — § 8.1 class-block summary view drift across 7 classes (pre-existing; non-blocking; doc polish) |

---

## Findings

### Claim 05.1: 🔵 LOW — § 8.1 Mermaid Class Diagram systematic drift across 7 classes (parallel to Claims 03.7 + 04.2)

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 8.1 Mermaid Class Diagram lines 1786-1878 (CMarketContextBuilder, CPortfolioState, CTradeJournal, CStatePersistence, CLogger, CCircuitBreaker, CSlotRegistry, CEAState — note: not all 13 classes have drift, only those listed below)

**Problem:**

Defender's "Notes for Reviewer (round-05)" บอกชัด: "**§ 8 Mermaid Class Diagrams cross-block scan** — Defender did NOT proactively scan § 8.2 this round (would expand scope beyond reviewer's 3 specific findings); reviewer ควรทำ holistic class-block sweep to confirm no parallel gaps exist beyond COrchestrator + CIndicatorService." Holistic sweep พบ **same field/method-list gap pattern** (parallel to Claims 03.7 + 04.2 ที่ defender accept) ใน 7 classes:

| Class | § 8.1 shows | Skeleton public methods | Missing in § 8.1 |
|-------|-------------|--------------------------|-------------------|
| `CLogger` (line 1817) | 4: Debug/Info/Warn/Error | 8: + Init, SetStatePersistence, ErrorBypassThrottle, OnTickBoundary | **4 missing** (incl. SetStatePersistence = Cycle 1 setter step 4a — KEY method) |
| `CStatePersistence` (line 1809) | 3: Load/Save/SyncToGlobalVariable | ~12: + Init, SetPortfolioState, TryRecoverFromGV, GetLoggerThrottledCount, StatePath, StateDir, GetPendingPayload, SetPendingPayload + ban accessors | **9+ missing** (incl. SetPortfolioState = Cycle 2 setter step 5a — KEY method recently renamed in Claim 03.4) |
| `CPortfolioState` (line 1792) | 4: RegisterAll/Refresh/GetByMagic/TotalActivePositions | 10: + Init, MagicCount, GetTicketsForSlot, TotalFloatingPL, GetSlotCounts, ReleaseAll | **6 missing** (incl. ReleaseAll = used in CleanupPartialInit) |
| `CTradeJournal` (line 1800) | 4: Open/WriteEvent/RotateIfNeeded/Close | 6: + Init, ShouldHaltSustained | **2 missing** (incl. ShouldHaltSustained = ADR-006 RPO contract) |
| `CCircuitBreaker` (line 1825) | 1: CheckPingPong | 4: + Init, RecordOpen, RecordClose | **3 missing** |
| `CSlotRegistry` (line 1859) | 3: m_slots[21]/RegisterAll/ValidateTopo | 6: + Init, Count, Get, ReleaseAll | **3 missing** (incl. ReleaseAll = used in CleanupPartialInit) |
| `CEAState` (line 1872) | 3: Halt/TryTransitionToStable/RestoreFromState | 6: + Init, GetState, GetHaltReason | **3 missing** (incl. Init = used in OnInit step 17) |

**ภาพรวม:** ทุก 7 classes ขาด `Init()` (consistent omission) + cycle setters (CLogger.SetStatePersistence + CStatePersistence.SetPortfolioState — both KEY 2-phase resolvers) + accessor methods + cleanup methods (ReleaseAll). Pre-existing pattern; ไม่ใช่ regression จาก round-04 edits.

**Why This Matters:**

Anti-duplication-rule reference: Claims 03.7 + 04.2 ทั้งคู่ flag *same pattern* (visual gap → engineer/reviewer miss methods → duplicate re-add risk) + defender accepted both. By consistency principle หลังจาก setting precedent 2 rounds ติด, ไม่ flag กรณีนี้ = ขัดแย้งกับ precedent. Specific concrete risks:

1. **CLogger.SetStatePersistence + CStatePersistence.SetPortfolioState invisibility** — เป็น 2 methods สำคัญที่สุดของ design (2-phase init Cycle 1 + Cycle 2 resolvers; recently renamed step 6.5 → 4a + 7b → 5a ใน round-03 Claim 03.4). Engineer reading § 8.1 alone ไม่เห็นว่ามี setter-pattern → อาจเขียน OnInit ที่ลืมเรียก ทั้ง ๆ ที่เป็น blocker ของ Save() runtime.
2. **ReleaseAll() invisibility** ใน CPortfolioState + CSlotRegistry → engineer extending CleanupPartialInit (Claim 03.2) อาจ skip จาก § 8.1 baseline → leak heap entries.
3. **Init() invisibility ทุกตัว** → contradicts DI table § 7.3 ที่ระบุ explicit Init() per service.

**Minimum Acceptable Fix:** เลือก **Path B** (preferred — minimal effort, permanent closure):

Path B (recommended — 1-line edit): เพิ่ม **intent statement** ที่ top ของ § 8.1 (after line 1741 heading) ระบุชัดว่า class blocks เป็น summary view:

> **Diagram intent (Claim 05.1):** § 8.1 + § 8.2 class blocks เป็น **summary view** ที่แสดงเฉพาะ "primary" public methods ของแต่ละ class — สำหรับ complete public surface (Init, accessors, cycle setters, cleanup helpers ฯลฯ) อ่าน skeletons ใน § 5 + § 7. Diagram primary purpose = visual dependency arrows + ownership relationships, ไม่ใช่ method enumeration. (Exception: `COrchestrator` + `CIndicatorService` blocks shown ครบเพราะมี methods ที่ engineer ต้องใช้ตอน init/cleanup verification per Claims 03.7 + 04.2.)

Path A (alternative — heavier edit): ขยาย 7 class blocks ครบทุก method/field ตามตาราง problem. Effort ~30 lines Mermaid edit.

**Level of Effort:** Low (Path B = ~5-line intent statement; Path A = ~30 lines)

---

## Cross-Domain Issues

ไม่มี cross-domain contradictions ใน round 05. Single finding (Claim 05.1) = TD-02 internal documentation polish.

---

## Round-Over-Round Trend

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Verdict pattern |
|-------|----------|------|------|--------|------|---|
| 01 | 20 | 5 | 8 | 5 | 2 | 100% Accept |
| 02 | 9 | 1 | 2 | 5 | 1 | 100% Accept |
| 03 | 8 | 0 | 3 | 3 | 2 | 100% Accept |
| 04 | 3 | 0 | 0 | 0 | 3 | 100% Accept |
| **05 (current)** | **1** | **0** | **0** | **0** | **1** | (pending rebuttal) |
| 06 (projected) | 0 | 0 | 0 | 0 | 0 | **Implementation Handoff Ready** |

> **Severity ceiling sustained:** CRITICAL = 0 (4 rounds running); HIGH = 0 (2 rounds running); MEDIUM = 0 (2 rounds running). Trajectory ลด อย่างต่อเนื่อง 20 → 9 → 8 → 3 → 1. Comparison: BA = 3 rounds, SD = 4 rounds, TD = projected 6 rounds — 1 round ขยายมาจาก 22k LOC complexity + 2 cycles 2-phase init + 19-pointer Orchestrator = expected.

---

## Recommendation

- [x] **Path B — Implementation Handoff Certified with LOW residue + post-handoff cleanup ticket** [recommended]:
  - Round-04 fixes ทั้งหมด ✅ + anti-regression gates ทั้ง G1-G5 ✅
  - Severity ceiling = 0 sustained 2+ rounds (CRITICAL = 0 × 4 rounds; HIGH = 0 × 2 rounds; MEDIUM = 0 × 2 rounds)
  - Single LOW residue (Claim 05.1) = pre-existing summary-view drift, **non-blocking**: engineer reads skeletons § 5 + § 7 (authoritative) + DI table § 7.3 (authoritative) for implementation; § 8.1 diagram = navigation aid
  - Defender adds 5-line intent statement ใน Claim 05.1 Path B → close rabbit hole + handoff certified ใน same round
  - **Effort estimate:** ~10 min defender + ~10 min reviewer round-06 verify-only = under 0.5 hr total to certified handoff

- [ ] **Path A — Request Re-Review (round 06)** [acceptable alternative]:
  - Defender expands 7 class blocks ครบทุก method/field per Path A (~30-line Mermaid edit)
  - Round-06 sweep = expected 0 findings = full visual completeness + handoff certification
  - **Effort estimate:** ~1 hr defender + ~0.5 hr reviewer = 1.5 hr total

- [ ] ~~Needs SD/ADR Backtrack~~ — confirmed all internal to TD-02 documentation
- [ ] ~~Needs Stakeholder Input~~ — no deferred items

> **My recommendation: Path B.** Diagram intent statement closes the "any class block could have summary-view drift" rabbit hole permanently — single targeted disambiguation > exhaustive method enumeration. Future reviewers reading § 8.1 with intent statement won't re-flag drift; engineer reading § 8.1 + skeletons knows precise scope of each.

---

## Notes for Defender (round-05)

- **Pre-edit verify pre-existing nature of Claim 05.1:** drift across 7 classes อยู่ตั้งแต่ round-01 (พิสูจน์ผ่าน git blame ของ § 8.1 = lines unchanged round-04→round-05). ไม่ใช่ defender's mistake; just collective reviewer-defender oversight ทั้ง 4 รอบที่ผ่านมา
- **Path B minimal edit recipe:** insert ก่อน line 1742 (heading "### 8.1 Services + domain layer") — เพิ่ม block:
  ```
  > **Diagram intent (Claim 05.1):** § 8.1 + § 8.2 class blocks เป็น summary view ...
  ```
  Total edit ~5 lines markdown
- **Optional bonus:** ถ้าต้องการ extra clarity, เพิ่ม comment ที่ top ของ classDiagram block: `%% Summary view — see § 5/§ 7 for complete surface` (Mermaid comment syntax = `%%`)
- **Anti-regression check post-edit:** rerun G1-G5 + verify intent statement renders properly (markdown blockquote ก่อน mermaid block จะไม่ break diagram)

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 05.1 | 🔵 LOW | § 8.1 class block summary-view drift across 7 classes (CLogger/CStatePersistence/CPortfolioState/CTradeJournal/CCircuitBreaker/CSlotRegistry/CEAState) | TD-02 § 8.1 lines 1786-1878 | Low (Path B = 5-line intent statement) |
