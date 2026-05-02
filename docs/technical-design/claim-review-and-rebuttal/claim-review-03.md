# Technical Design Claim Review Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Reviewer Persona** | andm-td-reviewer (Principal Technical Architect & Code-Quality Auditor) |
| **Workflow** | `.agents/workflows/td-review.md` |
| **Input** | `claim-review-and-rebuttal/rebuttal-round-02.md` |
| **Date** | 2026-05-02 |
| **Target Documents** | TD-02 (`02-backend-design.md`), TD-03 (`03-frontend-design.md`), TD-04 (`04-database-design.md`) + cascade docs (SD-02, SD-03, ADR-005, ADR-011, api-specs/*.yaml) |

---

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 0 |
| 🟠 HIGH | 3 |
| 🟡 MEDIUM | 3 |
| 🔵 LOW | 2 |
| **Total** | **8** |

> **ภาพรวม:** Round-02 rebuttal accepted 9/9 (100%) แต่ **HIGH ↑ จาก 2 → 3** ใน round-03 — clustered ทั้งหมดอยู่ใน **§ 7.4.1 CleanupPartialInit** ที่ Claim 02.10 เพิ่งเพิ่มเข้ามา. CRITICAL = 0 (round-01: 5 → round-02: 1 → round-03: 0) = good convergence signal. 17-magic cascade tail ปิดสมบูรณ์ (regression sweep `grep -E "16 (magic|key|entr|distinct)"` over design-docs/ + technical-design/ + api-specs/ + adr/ = 0 hits, all matches อยู่ใน claim-review/rebuttal history docs only). RiskManager DI re-sync ครบ 3 sites. Helper Init phantom calls ลบ + DI map row 2.5 consolidated. Logger semantic drift fixed via gap-aware logic. **แต่** new section § 7.4.1 ที่ defender เพิ่มเพื่อ Claim 02.10 มี 3 internal inconsistencies ที่ block compile / mislead engineer copy-paste.

---

## 20-Category Attack Vector Checklist

| # | Category | Status |
|---|----------|--------|
| 1 | Compile Errors | ⚠️ Finding — § 7.4.1 CleanupPartialInit body partial (Claim 03.2) + reverse-order wrong (Claim 03.3) → engineer copy-paste won't compile clean |
| 2 | Service / Class Skeletons | ⚠️ Finding — § 8.1 class diagram drift (Claim 03.7) |
| 3 | Backend Interface Contracts | ✅ Clean — RiskManager 4-arg sig consistent across § 5.4 + § 7.3 row 10 + § 7.4 line 1626 |
| 4 | Service Container / DI Registration | ⚠️ Finding — § 7.3 DI map orphan numbering 1, 2, 2.5, [3-5 GAP], 6, 6.5, 7, 7b... (Claim 03.4) |
| 5 | Error Handling | ⚠️ Finding — § 7.4.1 CleanupPartialInit reverse-order body wrong (Claim 03.3) — null-deref protection promise broken |
| 6 | Database Schema | ✅ Clean — TD-04 § 3.6 + § 3.9 + § 10 ER + caption all "17 entries" / "× 17" |
| 7 | Cross-Cutting (logging / config / observability) | ⚠️ Finding — Logger LRU eviction reset semantics (Claim 03.6) + § 9.4 comment-vs-code drift (Claim 03.8) |
| 8 | Security / Validation | N/A — local EA, no surface area |
| 9 | Performance / Concurrency | ✅ Clean — A1 spike text now "~17 keys" |
| 10 | Test Strategy / Test Pyramid | N/A — TD scope |
| 11 | Migration / Backward Compatibility | N/A — greenfield rewrite |
| 12 | Operational Readiness | ⚠️ Finding — Cleanup spec partial blocks operational guarantee (Claim 03.2) |
| 13 | Reproducibility & Determinism | ✅ Clean — atomic write + Option A/B dispatcher honest |
| 14 | Documentation Quality | ⚠️ Finding — "5 sites" vs 8 listing (Claim 03.1); "× 18" vs 16 services (Claim 03.5) |
| 15 | Build & Deployment | ✅ Clean — Section 13 Workflow Git Bash disclaimer + PowerShell alt preserved |
| 16 | Cross-Domain Consistency (TD ↔ SD ↔ ADR ↔ schema) | ✅ Clean — 17-magic cascade complete; RiskManager DI 3-site resync; helper consolidation propagated |
| 17 | Frontend / UI / Client | N/A — headless EA per TD-03 |
| 18 | Domain / Business Logic Surface | ✅ Clean — RiskManager dispatch table + JOURNAL_HALT_THRESHOLD constants intact |
| 19 | Resource Lifecycle | ⚠️ Finding — § 7.4.1 cleanup helper specifies path but body unimplementable (Claims 03.2 + 03.3) |
| 20 | Cross-Domain Drift (regression) | ✅ Clean — sweep 0 hits |

---

## Claim Responses

### Claim 03.1: 🟠 HIGH — § 7.4.1 self-inconsistency: header "(5 sites)" ≠ 8-site listing

- **Location:** TD-02 `02-backend-design.md` § 7.4.1 line 1697 — body header text. Listing follows lines 1700-1707.
- **Quoted text (line 1697):** `**Phase C call sites** ที่ต้องใส่ cleanup ก่อน 'return INIT_FAILED' (5 sites):`
- **Listed (lines 1700-1707):** ValidateInputs, ValidateSymbol, DetectDigitMultiplier, CreateHandles, ValidateSlotRegistry, RegisterAll, ValidateTopo, Open = **8 sites**.
- **Problem:** Header claims 5; body listing has 8. Round-02 rebuttal text (line 220) confirms intent = "8 Phase C call sites updated" — defender carried over the "5" from claim-review-02 Minimum-Acceptable-Fix wording (which suggested approximately 5) but expanded the actual listing to 8 without updating the header. Self-inconsistency in newly-added section.
- **Why this matters:** Reviewer or QA reading § 7.4.1 will see the header "(5 sites)" then count 8 listed sites and not know which is authoritative. Worst case: cleanup audit checklist generates with N=5 → 3 sites get missed in Code Review verification, and Phase C path that fails at site 6/7/8 gets `return INIT_FAILED` without `CleanupPartialInit()` → silent leak survives audit.
- **Minimum acceptable fix:** Change § 7.4.1 line 1697 from `(5 sites)` to `(8 sites)` to match the listing. Or alternatively, document the 8 sites match the 8 `return INIT_FAILED` statements in § 7.4 Phase C lines 1647-1668.
- **Effort:** Low (1-line text edit)

---

### Claim 03.2: 🟠 HIGH — § 7.4.1 CleanupPartialInit body shows only 4 of 16-19 services + `// ...` placeholder

- **Location:** TD-02 `02-backend-design.md` § 7.4.1 lines 1689-1693 — `CleanupPartialInit` body.
- **Quoted text (lines 1689-1693):**
  ```mql5
  if (m_journal != NULL)     { m_journal.Close();         delete m_journal;     m_journal = NULL; }
  if (m_indicators != NULL)  { m_indicators.ReleaseHandles(); delete m_indicators; m_indicators = NULL; }
  if (m_registry != NULL)    { m_registry.ReleaseAll();   delete m_registry;    m_registry = NULL; }
  if (m_portfolio != NULL)   { m_portfolio.ReleaseAll();  delete m_portfolio;   m_portfolio = NULL; }
  // ... delete heap-allocated services in reverse Init order (ทุก pointer ที่ WireServices() new)
  ```
- **Problem:** § 7.3 DI table catalogs **16 services + 3 helpers = 19 heap-allocated pointers** (`m_logger`, `m_pip`, helpers × 3, `m_state`, `m_portfolio`, `m_indicators`, `m_ctx_builder`, `m_risk`, `m_journal`, `m_breaker`, `m_time`, `m_pending`, `m_xslot`, `m_monitor`, `m_validator`, `m_registry`, `m_ea_state`). Body shows only **4** + `// ...` placeholder. The placeholder is doc-debt that will be carried into impl: engineer copy-paste = silent leak of 12+ unreleased pointers.
- **Why this matters:** Claim 02.10's stated value proposition was "explicit cleanup path … no more silent leaks" (per rebuttal-round-02 line 246) — but the helper as-specified delivers **partial cleanup at best** because the spec itself is incomplete. NFR-3.4 transparency promise (Alert popup before MT5 displays "EA failed to initialize") is preserved (line 1686 ErrorBypassThrottle), **but** the heap-leak prevention promise is functionally unachievable from this spec alone.
- **Minimum acceptable fix:** Either (a) enumerate all 16-19 services explicitly in reverse Init order, or (b) replace `// ...` with explicit pointer-name list (`m_logger`, `m_pip`, `m_state`, ..., `m_ea_state`) so engineer reading § 7.4.1 has a checklist. Option (a) preferred since it makes the file self-contained (engineer doesn't need to cross-reference § 7.3 to fill in the gap). Pair with Claim 03.3 (correct order).
- **Effort:** Low (extend listing from 4 lines to ~16-19 lines following the pattern; 5-min edit)

---

### Claim 03.3: 🟠 HIGH — § 7.4.1 CleanupPartialInit body shows WRONG reverse-Init order — violates own comment

- **Location:** TD-02 `02-backend-design.md` § 7.4.1 lines 1688-1693 — comment claims "REVERSE Init order"; body sequence does not match.
- **Quoted comment (line 1688):** `// Release in REVERSE Init order — ป้องกัน null-deref จาก dependent that already Released`
- **Quoted body sequence (lines 1689-1693):** `m_journal` (DI step 11) → `m_indicators` (DI step 8) → `m_registry` (DI step 18) → `m_portfolio` (DI step 7).
- **Problem:** Init order per § 7.3 is monotonic by step number: Logger(1) → PipMath(2) → State(6) → Portfolio(7) → Indicators(8) → CtxBuilder(9) → Risk(10) → Journal(11) → Breaker(12) → Time(13) → Pending(14) → XSlot(15) → Monitor(16) → Validator(17) → Registry(18) → EAState(19). Reverse should monotonically descend from 19 to 1: EAState → Registry → Validator → ... → Indicators → Portfolio → State → ... → Logger. Body sequence 11→8→18→7 is **not monotonic**. Specifically: Registry (18) was init **after** Journal (11), so Registry release should come **before** Journal release in reverse order — but body releases Journal first, then Indicators, then Registry. This is the exact null-deref protection that the comment promises to prevent.
- **Why this matters:** The comment promises "ป้องกัน null-deref จาก dependent that already Released" — but the spec violates the contract. Engineer copy-pasting this into impl will get null-deref crash if any Init dependency calls back into a service that was already released. Example: if `m_registry.ReleaseAll()` internally logs through `m_logger` and the partial impl later releases m_logger, that's still ok. BUT if `m_journal.Close()` internally calls `m_state.IncrementJournalFailures()` (per § 5.6 line 803-806 metric counter pattern) and `m_state` was init at step 6 — should be released LAST in reverse order, not before journal. With wrong sequence, Journal close attempts to write to a not-yet-released State → fine; but if engineer extends the pattern and releases m_state (step 6) before m_journal (step 11) by following the broken example, journal close → null-deref crash. Worse: failure path during INIT_FAILED is not covered by tests (per ADR-002 composition root pattern), so this null-deref will only surface at first user-visible disk-full or permission-failure scenario — exactly when reliable cleanup matters most (NFR-3.4).
- **Minimum acceptable fix:** Re-sequence body to monotonically descending Init step number: `m_ea_state` (19) → `m_registry` (18) → `m_validator` (17) → `m_monitor` (16) → `m_xslot` (15) → `m_pending` (14) → `m_time` (13) → `m_breaker` (12) → `m_journal` (11) → `m_risk` (10) → `m_ctx_builder` (9) → `m_indicators` (8) → `m_portfolio` (7) → `m_state` (6) → helpers → `m_pip` (2) → `m_logger` (1). Pair with Claim 03.2 (full enumeration).
- **Effort:** Low (renumber + reorder; 10-min edit; no design change)

---

### Claim 03.4: 🟡 MEDIUM — § 7.3 DI map orphan numbering after row consolidation (rows 3-5 missing)

- **Location:** TD-02 `02-backend-design.md` § 7.3 lines 1581-1599 — DI table.
- **Quoted row sequence:** `1 → 2 → 2.5 → 6 → 6.5 → 7 → 7b → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19`
- **Problem:** Rows 3, 4, 5 do not exist (collapsed into row 2.5 per round-02 Claim 02.2 fix), but the table shows numerical gaps. Reader assumes either (a) intentional 1-based step numbering with 2.5 being a fractional "between" insertion (= unclear what 3-5 refer to), or (b) accidental row deletion. Either reading is doc smell.
- **Why this matters:** AI agents that auto-generate `WireServices()` from the DI table per § 7.3's "single source-of-truth" promise will see step numbers and assume continuity. Numeric-gap rows imply hidden dependencies that aren't there. Lower-tier impact than CRITICAL because the Init order is still inferable from the column order (top-to-bottom), but doc-quality gate fails Cat 14.
- **Minimum acceptable fix:** Renumber rows continuously from 1 to 17 (16 services + 1 helpers row + 2 setter rows split): e.g., 1 = Logger, 2 = PipMath, 3 = helpers (consolidated), 4 = State, 4.5 = Logger.SetStatePersistence, 5 = Portfolio, 5b = State.SetPortfolioState, 6-17 = remaining services. Or alternatively, replace numeric step labels with **letter-based ordinals** (a, b, c, ...) since they aren't computed indexes anyway — just doc anchors.
- **Effort:** Low (table-edit 17 rows; no semantic change)

---

### Claim 03.5: 🟡 MEDIUM — § 7.4 reviewer checklist + intro both say "× 18 services" but actual count is 16 services + 3 helpers (no Init)

- **Location:** TD-02 `02-backend-design.md` § 7.4 line 1607 (intro paragraph) + line 1676 (reviewer checklist comment).
- **Quoted text (line 1607):** `Pseudo-code นี้ลบ comma-operator/'goto' hack เก่า + surface ครบ 18 service Init calls + 2 setter calls (DI step 6.5 + 7b) ที่ § 7.3 สัญญาไว้`
- **Quoted text (line 1676):** `**Reviewer checklist:** ทุก service ใน § 7.3 (× 18) ต้องมี exactly 1 'Init(...)' call ใน Phase B; cycle setters (step 6.5 + 7b) ต้องอยู่ตรงตำแหน่ง — ห้ามย้าย ห้ามลบ.`
- **Problem:** Round-02 Claim 02.2 fix removed standalone Init rows for 3 helpers (CCommentParser, CJsonWriter, CAtomicFile) + consolidated into row 2.5 stating "no Init() declared". So actual Init() call count in OnInit Phase B = **16** (see lines 1616-1644: m_logger, m_pip, m_state, m_portfolio, m_indicators, m_ctx_builder, m_risk, m_journal, m_breaker, m_time, m_pending, m_xslot, m_monitor, m_validator, m_registry, m_ea_state). The intro + checklist still say "× 18" — off-by-2 count drift after row consolidation.
- **Why this matters:** Reviewer running checklist `count(Init calls) == 18` will fail (actual count = 16). Either reviewer fixes the count manually (= friction) or assumes 2 Init calls are missing (= false alarm in Cat 4 DI Registration). Either way, the round-02 rebuttal's own stated value ("DI map = single source-of-truth") is undermined by the intro/checklist count drift.
- **Minimum acceptable fix:** Update both lines from "× 18" to "× 16" (or "× 16 services + 3 helpers (no Init)" for explicitness). Pair with Claim 03.4 (renumber DI rows) for one-pass cleanup.
- **Effort:** Low (2-line text edit)

---

### Claim 03.6: 🟡 MEDIUM — Logger LRU eviction reset semantics undocumented for parallel arrays `m_consecutive_count` + `m_last_tick_seen`

- **Location:** TD-02 `02-backend-design.md` § 5.7 lines 826-832 (storage + eviction comment); § 9.4 line 2023 (`FindOrEvictKey` call); § 5.7 line 866 (private helper declaration).
- **Quoted text (lines 826-827):** `// Eviction policy: ที่ buffer full + new tuple → evict entry ที่ tick_count oldest (LRU) + emit Logger.Warn 'throttle_buffer_evicted' for visibility (tunable via Init param).`
- **Quoted text (line 832):** `int m_last_tick_seen[64];     // tick_counter ของ last Error() call ของ tuple (Claim 02.9 fix)`
- **Problem:** When `FindOrEvictKey(string key)` evicts an old tuple's entry and reuses idx for a new tuple, all parallel arrays at that idx must reset to default state — specifically `m_consecutive_count[idx] = 1` (new tuple = first occurrence) AND `m_last_tick_seen[idx] = m_tick_counter` (or 0). The eviction comment (lines 826-827) only specifies the LRU + emit-warn behavior + does not specify the array-reset contract. § 9.4 lines 2024-2030 ที่ implement gap-aware logic assumes `m_last_tick_seen[idx]` reflects the *current* tuple's last-seen tick — but if FindOrEvictKey's contract is silent on resetting parallel arrays during eviction-reuse, an implementation that forgets reset can produce **ghost continuation**: new tuple lands at recycled idx where stale `m_last_tick_seen[idx]` happens to equal `m_tick_counter - 1` (within 1-tick window of old tuple's last error) → counter increments instead of resetting → false escalation.
- **Why this matters:** Claim 02.9 fix's stated value was "Sporadic 10 errors over 100 ticks ≠ escalate" — but the eviction edge case can re-introduce false-escalation through a different door. Probability: low (requires recycled idx + tick-adjacency coincidence) but non-zero. Same-class issue as the round-02 reviewer's "operator inundated" concern.
- **Minimum acceptable fix:** Update § 5.7 line 866 `FindOrEvictKey` declaration comment to specify the contract: `// LRU when buffer full; on eviction-reuse, callee MUST reset m_consecutive_count[idx] = 0 + m_last_tick_seen[idx] = 0 before returning idx for new tuple`. Or alternatively, embed a reset in the `EscalateIfThresholdMet` body right after `FindOrEvictKey` call: detect "new key" via comparing `m_recent_keys[idx]` vs caller's key string + reset both arrays inline. Either approach closes the gap; option 1 cheaper.
- **Effort:** Low (1-comment-line edit on declaration)

---

### Claim 03.7: 🔵 LOW — § 8.1 Mermaid Class Diagram CIndicatorService missing `HandleCount()` + `ReleaseHandles()` accessors

- **Location:** TD-02 `02-backend-design.md` § 8.1 lines 1736-1743 — `class CIndicatorService` Mermaid block.
- **Quoted text (lines 1736-1743):**
  ```mermaid
  class CIndicatorService {
      -int m_handles[40]
      -int m_handle_count
      +CreateHandles() bool
      +Refresh() void
      +AnyHandleInvalid() bool
      +CachedScan(string,fn) double
  }
  ```
- **Problem:** § 5.1 skeleton (lines 484-507) declares public methods: `Init`, `CreateHandles`, `Refresh`, `AnyHandleInvalid`, `CachedScan`, `ReleaseHandles`, `GetHandle`, `HandleCount` (= 8 methods). Class diagram shows only 4 methods (CreateHandles, Refresh, AnyHandleInvalid, CachedScan). Missing: Init, ReleaseHandles, GetHandle, HandleCount. The newly-added (round-02 Claim 02.5 fix) `HandleCount()` accessor that § 7.4 line 1671 depends on is invisible in the diagram view.
- **Why this matters:** Mermaid class diagram is the visual spec used for onboarding + code-review check. Engineer reviewing diagram won't know HandleCount() exists; engineer building dependent code may re-add it as duplicate. Cat 14 doc-quality + Cat 2 service skeleton drift. Lower-tier impact since text spec at § 5.1 is authoritative + correct.
- **Minimum acceptable fix:** Add the 4 missing methods to § 8.1 CIndicatorService class block: `+Init(CLogger*)`, `+ReleaseHandles() void`, `+GetHandle(int) int`, `+HandleCount() int`.
- **Effort:** Low (4-line Mermaid edit)

---

### Claim 03.8: 🔵 LOW — § 9.4 EscalateIfThresholdMet comment vs code semantic drift on "consecutive ticks"

- **Location:** TD-02 `02-backend-design.md` § 9.4 lines 2018-2025.
- **Quoted comment (lines 2018-2021):**
  ```
  // ADR-011 § Escalation policy: ≥ N **consecutive ticks** of same (slot,event) → secondary Alert.
  // Implementation note (Claim 02.9 fix): "consecutive ticks" semantic = same tuple emit Error() ที่ tick
  //   N-1 และ tick N ติดต่อกัน (= delta ≤ 1). ถ้า tick gap > 1 (silent ≥ 1 tick) → reset counter to 1.
  //   Sporadic 10 errors ห่างกัน 100 ticks ≠ escalate (ตามที่ ADR-011 line 60 intended).
  ```
- **Quoted code (lines 2024-2025):**
  ```mql5
  if (m_last_tick_seen[idx] == m_tick_counter - 1 ||                // adjacent tick → continuation
      m_last_tick_seen[idx] == m_tick_counter) {                     // same tick (multiple Error() in 1 tick) → still consecutive
  ```
- **Problem:** Comment describes "tick N-1 และ tick N ติดต่อกัน (= delta ≤ 1)" — strict ADR-011 reading = 2 distinct adjacent ticks. Code accepts both delta=1 (adjacent) AND delta=0 (same tick, multiple Error calls in 1 OnTick). Edge case: 10 Error() calls in 1 tick = counter reaches 10 = escalation triggered. Comment doesn't cover this behavior. Defensible interpretation (multiple errors in same tick IS abnormal worth escalating), but creates undocumented semantic divergence from ADR-011 line 60 strict reading.
- **Why this matters:** Future maintainer reading ADR-011 + § 9.4 will see "consecutive ticks" and assume strict same-as-ADR semantic. If they later encounter a bug report ("escalation fired with only 1 tick of activity but N=10 errors"), they may assume bug + introduce a check `if (errors_in_same_tick == 1)`. ADR-011 + TD-02 + impl all need to agree on what "consecutive" means in same-tick burst case.
- **Minimum acceptable fix:** One of:
  1. Update § 9.4 comment to explicit: *"semantic = `m_tick_counter - m_last_tick_seen[idx] <= 1` — covers both same-tick burst (delta=0) AND adjacent-tick continuation (delta=1); silent gap of ≥ 2 ticks resets counter."*
  2. OR change code to delta=1 only (`m_last_tick_seen[idx] == m_tick_counter - 1`); same-tick errors don't increment beyond 1; aligns strict to ADR-011.
  3. OR amend ADR-011 line 60 "consecutive ticks" to "consecutive (or same-tick) Error emissions" if delta=0 acceptance is intentional design.
  Option 1 cheapest (preserve current code, just clarify comment).
- **Effort:** Low (3-line comment edit per option 1)

---

## Cross-Domain Issues (Summary)

| ID | Issue | Affected files | Linked claims |
|----|-------|----------------|----------------|
| Z1 | New § 7.4.1 CleanupPartialInit section internally inconsistent (5/8 site count, 4/19 service body, wrong reverse order) | TD-02 § 7.4.1 only — no SD/ADR cascade since cleanup is internal pattern | Claims 03.1, 03.2, 03.3 |
| Z2 | DI map row consolidation aftermath: orphan numbers + stale total count in Phase B intro/checklist | TD-02 § 7.3 + § 7.4 | Claims 03.4, 03.5 |
| Z3 | Logger LRU eviction reset contract gap + comment-vs-code semantic divergence | TD-02 § 5.7 + § 9.4 vs ADR-011 line 60 | Claims 03.6, 03.8 |
| Z4 | Class-diagram drift after accessor additions | TD-02 § 5.1 vs § 8.1 | Claim 03.7 |

> **None of Z1-Z4 cascade outside TD-02 internals.** No SD/ADR/api-spec edits required (unlike round-02 Y1 cross-domain). Round-03 = internal-only audit residue.

---

## Round-Over-Round Trend

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Resolved this round (rebuttal) |
|-------|----------|------|------|--------|------|-------------------------------|
| 01 | 20 | 5 | 8 | 5 | 2 | 20 (100% Accept) |
| 02 | 9 | 1 | 2 | 5 | 1 | 9 (100% Accept) |
| 03 (current) | 8 | 0 | 3 | 3 | 2 | TBD (awaiting rebuttal-round-03) |
| 04 (projected) | ≤ 2 | 0 | 0 | ≤ 1 | ≤ 1 | converge |
| 05 (projected target) | 0 | 0 | 0 | 0 | 0 | **Ready for Implementation Handoff** |

> **Convergence signal:** CRITICAL = **0** (round-01: 5 → round-02: 1 → round-03: 0). Total ลดจาก 20 → 9 → 8 (slight plateau: HIGH ↑ 2 → 3 because round-02 introduced 3 new HIGH ใน § 7.4.1 newly-added section ที่ Claim 02.10 created). Net: round-03 review covers a section that didn't exist in round-02 review scope = expected pattern (new sections often have audit residue). All 8 round-03 findings = **mechanical edits ≤ 10 min each**; no design change. Trajectory: round-04 should resolve all 8 + reach ≤ 2 findings; round-05 = 0.
>
> **Comparison to BA (3 rounds) + SD (4 rounds):** TD trending toward 4-5 rounds = slightly longer than SD because round-01 broad rewrite (3 core skeletons + OnInit 3-phase + 9-file cascade) introduced more cascade tail than typical. Acceptable; still on-track.

---

## Recommendation

- [x] **Request Re-Review (round 04)** — verify § 7.4.1 CleanupPartialInit fixes:
  - **Claim 03.1:** "(5 sites)" → "(8 sites)" header text
  - **Claim 03.2:** body enumerate all 16-19 service pointers (replace `// ...` placeholder)
  - **Claim 03.3:** monotonic reverse Init order (EAState → Registry → ... → Logger)
  - **Claim 03.4:** § 7.3 DI table row renumbering
  - **Claim 03.5:** "× 18" → "× 16" in § 7.4 intro + checklist
  - **Claim 03.6:** § 5.7 line 866 FindOrEvictKey contract comment (reset arrays on eviction-reuse)
  - **Claim 03.7:** § 8.1 CIndicatorService class diagram add 4 missing methods
  - **Claim 03.8:** § 9.4 comment clarify same-tick burst inclusion

- [ ] ~~Ready for Implementation Handoff~~ — premature; § 7.4.1 has 3 HIGH severity issues that block engineer copy-paste compile + null-deref protection. Round-04 cleanup pass required.

- [ ] **No SD/ADR cascade required** for this round — all 8 findings = TD-02 internal. No `/backtrack sd` action item.

- [ ] ~~Needs Stakeholder Input~~ — no deferred items.

> **Effort estimate:** Round-04 rebuttal cycle ~ 0.5 day (8 mechanical edits × ~10 min each + verification grep). Total path to Implementation Handoff readiness: ~ 0.5-1 day (round-04 verify + round-05 sweep with zero new findings projected).

---

## Notes for Defender (rebuttal-round-03)

- **Z1 cluster (Claims 03.1-03.3):** Single section § 7.4.1 needs cleanup pass — fix header count + enumerate all services + correct order. Suggest treat as one combined fix in rebuttal (3 claims, 1 edit pass).
- **Z2 cluster (Claims 03.4, 03.5):** § 7.3 + § 7.4 numeric drift after row consolidation. Single pass cleanup.
- **Z3 cluster (Claims 03.6, 03.8):** Logger semantic precision — choose between (1) clarify TD comment, (2) tighten code, or (3) amend ADR-011. Document the chosen interpretation in rebuttal.
- **Z4 (Claim 03.7):** Class diagram drift — straightforward mermaid edit.

> **Self-validation gate:** Before submitting rebuttal-round-03, defender should run `grep -E "(× 18|5 sites|implicit)" docs/technical-design/02-backend-design.md` to confirm zero hits = numeric residue cleared.
