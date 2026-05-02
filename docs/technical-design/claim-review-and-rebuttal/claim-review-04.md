# Technical Design Claim Review Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Target Document** | `rebuttal-round-03.md` (verification sweep across TD-02 + cascade sites) |
| **Date** | 2026-05-02 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, mql-developer |

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 0 |
| 🟠 HIGH | 0 |
| 🟡 MEDIUM | 0 |
| 🔵 LOW | 3 |

> **Round-over-round trajectory:** 20 → 9 → 8 → **3** (severity ceiling: CRITICAL → 0 sustained 3 rounds; HIGH → 0 first time). Z1-Z4 clusters from round-03 ทั้งหมดปิดสมบูรณ์ — defender's self-validation gates ผ่าน 100% (`× 18|5 sites|step 6\.5|step 7b` = 0 hits; Init call count = 16 verified). All 3 round-04 findings = cosmetic / documentation-quality residue, ไม่ block compile / runtime / null-deref protection. **Strong candidate for Implementation Handoff with LOW residue accepted** หรือ 1 final round-05 sweep.

---

## Round-03 Rebuttal Verification — All 8 Fixes Confirmed

| # | Claim 03.X | Verdict | Evidence | Pass |
|---|------------|---------|----------|------|
| 1 | 03.1 (HIGH) — § 7.4.1 header "(8 sites)" | Accept | Line 1722: `(8 sites — matches the 8 'return INIT_FAILED' statements in § 7.4 Phase C lines 1647-1668)` | ✅ (header ผ่าน; line range cite issue → Claim 04.1 below) |
| 2 | 03.2 (HIGH) — Body 19-pointer enumeration | Accept | Lines 1698-1718: 19 distinct pointer cleanup blocks (16 services + 3 helpers) | ✅ |
| 3 | 03.3 (HIGH) — Reverse Init order monotonic | Accept | Lines 1698-1718 step annotations: 17 → 16 → 15 → 14 → 13 → 12 → 11 → 10 → 9 → 8 → 7 → 6 → 5 → 4 → 3 (×3 helpers) → 2 → 1 (monotonic non-increasing) | ✅ |
| 4 | 03.4 (HIGH) — DI table 1-17 + 4a/5a + 5-site cascade | Accept | § 7.3 lines 1586-1606 = 19 rows (1, 2, 3, 4, 4a, 5, 5a, 6...17); Cascade verified via grep `step 4a\|step 5a` × 5 sites: § 5.6 line 769, § 5.7 line 844, § 7.4 lines 1628/1630, § 9.3 line 2001, § 9.4 line 2022 | ✅ |
| 5 | 03.5 (MEDIUM) — "× 16 services + 3 helpers" | Accept | § 7.4 line 1614 intro + line 1683 reviewer checklist updated | ✅ |
| 6 | 03.6 (MEDIUM) — § 5.7 FindOrEvictKey contract | Accept | Lines 866-871: 6-line eviction-reuse contract comment present, names exact reset variables | ✅ |
| 7 | 03.7 (LOW) — § 8.1 CIndicatorService class block | Accept | Lines 1761-1772: 8 public methods listed, matches § 5.1 skeleton (Init, CreateHandles, Refresh, AnyHandleInvalid, CachedScan, ReleaseHandles, GetHandle, HandleCount) | ✅ |
| 8 | 03.8 (MEDIUM) — § 9.4 EscalateIfThresholdMet 2-case comment | Accept | Lines 2047-2055: `(a) adjacent-tick continuation` + `(b) same-tick burst` semantic explicit; matches code at 2058-2060 | ✅ |

> **Defender self-validation gates re-run:**
> - `grep -nE "× 18\|5 sites\|step 6\.5\|step 7b\|DI step 6\.5\|DI step 7b" docs/technical-design/02-backend-design.md` → **0 hits** ✅
> - Init call count gate: 16 `m_<service>.Init(...)` calls in Phase B (lines 1623-1651) — matches "× 16 services" claim ✅
> - 17-magic regression sweep across `docs/`: `step 6.5\|step 7b` only appears in `state/overview.md` (history note) + claim-review/rebuttal history docs — **0 hits in active design** ✅

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Reference in Backend Design | ✅ Pass | api-specs/* references unchanged; no schema restate |
| 2 | Backend Module Boundaries | ✅ Pass | 16 services + 3 helpers structure stable; ADR-002 + ADR-012 honored |
| 3 | Backend Interface Contracts | ✅ Pass | All Init/Setter signatures + cycle-resolver pattern fully documented |
| 4 | CQRS/Command-Query Separation | ⏭️ N/A | EA architecture (no CQRS) |
| 5 | Frontend Component Hierarchy | ⏭️ N/A | TD-03 frontend = N/A (UX skipped per state/overview) |
| 6 | Frontend State Management | ⏭️ N/A | TD-03 frontend = N/A |
| 7 | Frontend-Backend Contract Alignment | ⏭️ N/A | TD-03 frontend = N/A |
| 8 | Database Schema Completeness | ✅ Pass | 17-entry slot_states stable; clean across TD-04 + schema YAML |
| 9 | Database Index Strategy | ✅ Pass | Monthly rotation + per-run namespace unchanged |
| 10 | Database Migration Safety | ✅ Pass | ADR-006/007 § Revisit-when stable |
| 11 | Design Pattern Justification | ✅ Pass | ADR references intact; no new patterns introduced |
| 12 | Sequence Diagram Coverage | ✅ Pass | Flow Appendix unchanged round-over-round |
| 13 | Sequence Diagram Accuracy | ✅ Pass | Method names match skeletons after round-03 alignment |
| 14 | Testability in TD-02/03/04 | ✅ Pass | Seam points stable; no test-impact changes round-03 |
| 15 | TD↔QA Alignment | ✅ Pass | TD readability unchanged; QA-01 still references same surfaces |
| 16 | Cross-Domain Consistency | ⚠️ Finding | Claim 04.3 — § 7.3 vs § 7.4 helper-count framing inconsistent ("1 row" vs "3 classes") |
| 17 | Security at Detail Level | ✅ Pass | No surface changes |
| 18 | Error Handling Strategy | ✅ Pass | CleanupPartialInit + ErrorBypassThrottle + Logger escalate ทั้งหมด aligned |
| 19 | Implementation Readiness | ⚠️ Finding | Claims 04.1 + 04.2 — minor doc-quality gaps that don't block code generation but may confuse reviewer/auditor |

---

## Findings

### Claim 04.1: 🔵 LOW — § 7.4.1 line range citation off-by-7 to off-by-7

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 line 1722

**Problem:**

Round-03 Claim 03.1 fix changed header text เป็น `**Phase C call sites** ที่ต้องใส่ cleanup ก่อน `return INIT_FAILED` (8 sites — matches the 8 `return INIT_FAILED` statements in § 7.4 Phase C lines 1647-1668):` แต่ actual line range ของ 8 `return INIT_FAILED` statements ใน § 7.4 อยู่ที่ลำดับ **1654, 1655, 1656, 1658, 1672, 1673, 1674, 1675** (range 1654-1675) — **ไม่ใช่ 1647-1668**. Defender ใช้ outdated line numbers (น่าจะค้างจากก่อนที่ Phase C จะเพิ่ม `m_atomic.CleanupOrphanTmp` + `m_state.Load` + `m_portfolio.RegisterAll/Refresh` + `m_ea_state.RestoreFromState` ที่ลามให้ Phase C ขยายตัวประมาณ 7 บรรทัด).

**Why This Matters:**

Reviewer / QA / Impl Planner ที่ verify "8 sites" claim ตามที่ header แนะนำจะ jump ไปยัง lines 1647-1668 — แต่บรรทัดนั้นอยู่กลาง Phase B Init code (CTimeGate Init args + CPendingMachineRegistry Init args) ที่ไม่มี `return INIT_FAILED` เลย. Reviewer จะคิดว่า claim ผิด หรือ section misorganized → false-positive review friction. Engineer เริ่ม implement ก็จะ confused. มิฉะนั้น "self-checking" cross-reference ที่ defender ตั้งใจให้ใช้เป็น verification anchor กลับกลายเป็น misdirection signal.

**Minimum Acceptable Fix:**

แก้ line range ใน header line 1722 จาก `lines 1647-1668` → `lines 1654-1675` (หรือ semantic alternative `the 4 Phase C return INIT_FAILED guards before m_state.Load + the 4 after m_ea_state.RestoreFromState` ที่ไม่ depend on line numbers ที่ shift ตาม edit).

**Level of Effort:** Low (1-line edit; mechanical)

---

### Claim 04.2: 🔵 LOW — § 8.1 COrchestrator class block shows 7 fields, but skeleton owns 19 pointers (parallel to Claim 03.7 — same pattern, missed in round-03)

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 8.1 Mermaid Class Diagram lines 1748-1759 (`class COrchestrator`)

**Problem:**

§ 8.1 COrchestrator block แสดง private fields เพียง 7 ตัว: `m_logger, m_indicators, m_ctx_builder, m_portfolio, m_journal, m_state, m_registry`. แต่ § 7.4.1 CleanupPartialInit body (lines 1698-1718, ที่เพิ่งเพิ่มจาก round-03 Claim 03.2) reference **19 pointers** ที่ Orchestrator owns: เพิ่ม `m_breaker, m_time, m_pending, m_xslot, m_risk, m_monitor, m_validator, m_ea_state, m_pip, m_atomic, m_json_writer, m_comment_parser` (12 fields hidden). Pattern เดียวกับ Claim 03.7 ที่ flag CIndicatorService missing 4 methods — แต่ scope ใหญ่กว่า (12 missing fields vs 4 missing methods).

**Why This Matters:**

นี่เป็น issue เดียวกับ Claim 03.7 ที่ defender accept ว่า "engineer reading diagram จะไม่ทราบ method exists → duplicate re-add risk". By same logic: engineer reading § 8.1 COrchestrator block จะไม่ทราบว่า Orchestrator owns m_ea_state / m_validator / m_pip / 3 helpers → อาจจะเขียน OnInit() WireServices() ที่ลืม `new` 12 ตัวหรือ duplicate construct. Code review ที่ใช้ class diagram เป็น verification anchor (FR-1.4 BootstrapValidator + ADR-002 composition root) จะไม่ catch missing field. Pre-existing miss (round-03 reviewer caught CIndicatorService แต่ไม่ scan parallel issue ใน Orchestrator); valid finding ใน round-04 ตาม anti-duplication rule (different class = not duplicate).

**Minimum Acceptable Fix:**

ใน § 8.1 line 1748-1759 `class COrchestrator` Mermaid block — เพิ่ม 12 missing private fields ให้ตรงกับ § 7.4.1 CleanupPartialInit enumeration. Order: ใส่ตามลำดับ DI table § 7.3 (CCircuitBreaker/m_breaker, CTimeGate/m_time, CPendingMachineRegistry/m_pending, CCrossSlotCoordinator/m_xslot, CRiskManager/m_risk, CPortfolioMonitor/m_monitor, CBootstrapValidator/m_validator, CEAState/m_ea_state, CPipMath/m_pip, CAtomicFile/m_atomic, CJsonWriter/m_json_writer, CCommentParser/m_comment_parser).

ตัวอย่าง:
```mermaid
class COrchestrator {
    -CLogger* m_logger
    -CPipMath* m_pip
    -CAtomicFile* m_atomic
    -CJsonWriter* m_json_writer
    -CCommentParser* m_comment_parser
    -CStatePersistence* m_state
    -CPortfolioState* m_portfolio
    -CIndicatorService* m_indicators
    -CMarketContextBuilder* m_ctx_builder
    -CRiskManager* m_risk
    -CTradeJournal* m_journal
    -CCircuitBreaker* m_breaker
    -CTimeGate* m_time
    -CPendingMachineRegistry* m_pending
    -CCrossSlotCoordinator* m_xslot
    -CPortfolioMonitor* m_monitor
    -CBootstrapValidator* m_validator
    -CSlotRegistry* m_registry
    -CEAState* m_ea_state
    +OnInit() int
    +OnTick() void
    +OnDeinit(int) void
    +CleanupPartialInit(string) void
}
```
หมายเหตุ: เพิ่ม `+CleanupPartialInit(string) void` ด้วย — public method ที่ § 7.4.1 declared แต่ไม่ปรากฏใน class diagram (parallel issue: missing method).

**Level of Effort:** Low (~12-line Mermaid edit; mechanical)

---

### Claim 04.3: 🔵 LOW — § 7.3 vs § 7.4 helpers count framing inconsistent ("1 row" vs "3 classes")

**Location:**
- File: `docs/technical-design/02-backend-design.md`
- § 7.3 line 1584 (Numbering convention callout) + § 7.4 line 1614 (intro) + § 7.4 line 1683 (reviewer checklist)

**Problem:**

Round-03 Claim 03.5 fix updated 3 spots ที่ count helpers แต่ใช้ framing ต่างกัน:
- § 7.3 line 1584: `**16 services + 1 helpers row**` + `Total table rows = 19 (16 services + 1 helpers + 2 setters)` — counts **rows in DI table** (3 classes consolidated → 1 row)
- § 7.4 line 1614: `**16 service Init calls + 3 helpers (no Init) + 2 setter calls**` — counts **classes** (CCommentParser, CJsonWriter, CAtomicFile = 3 classes)
- § 7.4 line 1683: `× 16 services + 3 helpers (no Init)` + qualifier `(= 16 Init calls)` — counts **classes** with disambiguator

Reader ที่ scan ทั้งสอง section ติดต่อกันจะเห็น "1 helpers" ใน § 7.3 และ "3 helpers" ใน § 7.4 → cognitive friction หรือ false alarm ว่ามี contradiction. ทั้งสอง framing technically ถูกต้องแต่ describe คนละมิติ (rows vs classes).

**Why This Matters:**

Reviewer / Impl Planner ที่ใช้ DI table เป็น "single source-of-truth" (per Claim 02.2 framing) จะ confuse — § 7.3 callout says 1 helpers, § 7.4 says 3 helpers. Engineer might wonder ว่า DI table missed 2 helpers entries หรือ § 7.4 over-counts. Friction ขนาด minor แต่ valid documentation-clarity gap.

**Minimum Acceptable Fix:**

เลือกอย่างใดอย่างหนึ่ง — recommend Option A:

**Option A (preferred):** ใน § 7.3 line 1584 callout ขยาย wording ให้ explicit ว่า row 3 consolidates 3 classes:
```
> **Numbering convention (Claim 03.4):** rows ใช้ step 1-17 ต่อเนื่อง = **16 services + 1 helpers row (consolidating 3 helper classes: CCommentParser, CJsonWriter, CAtomicFile per § 4)** ...
```

**Option B:** ใน § 7.4 lines 1614 + 1683 ลด wording จาก "3 helpers" → "1 helpers row (3 classes: CCommentParser, CJsonWriter, CAtomicFile)" — verbose แต่ consistent with § 7.3.

**Level of Effort:** Low (1-line callout expansion in § 7.3 OR rewording in § 7.4)

---

## Cross-Domain Issues

| ID | Cluster | Domain | Issue | Status |
|----|---------|--------|-------|--------|
| W1 | Documentation | TD-02 § 7.4.1 internal | Line range cite (Claim 04.1) | LOW residue |
| W2 | Documentation | TD-02 § 8.1 visual diagram | COrchestrator class block (Claim 04.2) | LOW residue |
| W3 | Documentation | TD-02 § 7.3 ↔ § 7.4 wording | Helpers count framing (Claim 04.3) | LOW residue |

> **No SD/ADR/api-spec cascade required** — all 3 findings = TD-02 internal documentation polish. ไม่ต้อง `/backtrack sd`.

---

## Round-Over-Round Trend

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Verdict pattern |
|-------|----------|------|------|--------|------|---|
| 01 | 20 | 5 | 8 | 5 | 2 | 100% Accept |
| 02 | 9 | 1 | 2 | 5 | 1 | 100% Accept |
| 03 | 8 | 0 | 3 | 3 | 2 | 100% Accept |
| **04 (current)** | **3** | **0** | **0** | **0** | **3** | (pending rebuttal) |
| 05 (projected) | 0 | 0 | 0 | 0 | 0 | **Implementation Handoff Ready** |

> **Severity ceiling collapse achieved this round:** ลด HIGH 3 → 0 + MEDIUM 3 → 0 (first time ทั้งคู่ = 0). เหลือเพียง 3 LOW = cosmetic / documentation polish ที่ optional fix หรือ accept-as-residue ก็ได้. Defender's projected round-04 ≤ 2 = close (off by 1; reality = 3). Comparison to BA (3 rounds) + SD (4 rounds): TD ปิดที่ round-04 หรือ round-05 = on-track. **CRITICAL = 0 sustained 3 rounds + HIGH = 0 first time** = strong convergence signal.

---

## Recommendation

- [x] **Path A — Request Re-Review (round 05)** [recommended]: Defender แก้ 3 LOW ใน 1 cycle (~0.5 hr — 14-line Mermaid edit + 1-line range cite + 1-callout expansion). Round-05 sweep = expected 0 findings = **formal Implementation Handoff certification**.

- [ ] **Path B — Accept LOW residue + Implementation Handoff now** [acceptable alternative]: 3 findings = pure documentation polish, ไม่ block code generation, ไม่ block compile/runtime/test. Engineer reading TD-02 ยังสามารถ implement ครบ 21 slots + 16 services + 3 helpers ได้ตาม § 5/§ 7 skeletons + § 7.3 DI table + § 7.4 OnInit pseudo-code; § 8.1 class diagram drift ไม่ block (engineer reads skeletons ก่อน diagram). LOW residue tracked เป็น TD-cleanup ticket post-handoff.

- [ ] ~~Needs Stakeholder Input~~ — no deferred items; all findings = self-resolvable doc edits.

- [ ] ~~No SD/ADR cascade required~~ — confirmed all internal to TD-02.

> **Effort estimate:**
> - **Path A:** 0.5 hr defender + 0.5 hr reviewer round-05 = ~1 hr to certified handoff
> - **Path B:** 0 hr to handoff + 0.5 hr post-handoff cleanup ticket
>
> **My preference: Path A** — cleanest signal for downstream Impl Planner; final round-05 = 0 findings = formal certification mirrors SD's 4-round convergence pattern + BA's 3-round pattern.

---

## Notes for Defender (round-04)

- **Single combined edit pass possible:** all 3 LOW findings touch § 7.3 + § 7.4.1 + § 8.1 (4 spots total: lines 1584, 1722, 1748-1759, optionally 1614/1683). Defender สามารถทำเป็น 1 commit edit pass ได้.
- **Anti-regression check:** หลัง edit ให้ rerun grep gates:
  ```
  grep -nE "× 18|5 sites|step 6\.5|step 7b" docs/technical-design/02-backend-design.md   # expect 0 hits
  grep -c "^\s\+m_\w*\.Init(" docs/technical-design/02-backend-design.md                  # expect 16 (only Phase B)
  ```
  Plus new gate สำหรับ Claim 04.2:
  ```
  awk '/class COrchestrator \{/,/\}/' docs/technical-design/02-backend-design.md | grep -c "^\s*-C"  # expect 19 fields
  ```
- **Z1 cluster (round-03) confirmed closed** — no regression; § 7.4.1 body monotonic descending verified per-line `// step N`.
- **Z2 cluster (round-03) confirmed closed** — DI table 1-17 + 4a/5a + 5-site cascade verified; "× 16 services + 3 helpers" wording present (just framing inconsistency = Claim 04.3).
- **Z3 cluster (round-03) confirmed closed** — § 5.7 FindOrEvictKey contract present; § 9.4 EscalateIfThresholdMet 2-case comment matches code logic.
- **Z4 cluster (round-03) partially closed** — § 8.1 CIndicatorService fixed (Claim 03.7 ✅) but parallel COrchestrator visual gap was missed (= Claim 04.2 this round). Suggest defender scan all class blocks ใน § 8.1 + § 8.2 ครั้งเดียว to catch any other hidden field-list / method-list gaps before round-05.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 04.1 | 🔵 LOW | § 7.4.1 line range cite off-by-7 | TD-02 § 7.4.1 line 1722 | Low |
| 04.2 | 🔵 LOW | § 8.1 COrchestrator class block missing 12 fields + 1 method (parallel to Claim 03.7) | TD-02 § 8.1 lines 1748-1759 | Low |
| 04.3 | 🔵 LOW | § 7.3 vs § 7.4 helpers count framing inconsistent | TD-02 § 7.3 line 1584 ↔ § 7.4 lines 1614/1683 | Low |
