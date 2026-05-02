# Technical Design Rebuttal Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Claim Review** | `claim-review-03.md` |
| **Date** | 2026-05-02 |
| **Defender Persona** | andm-td-defender (constructive defender, evidence-based rebuttal, SD-boundary respect) |
| **SKILLs Used** | architecture, software-architecture, mql-developer |

---

## Summary

| Verdict | Count |
|---------|-------|
| Accepted | 8 |
| Partial | 0 |
| Rejected | 0 |
| **Total** | **8** |

> **ภาพรวม:** Round-03 reviewer ปล่อย 8 finding ที่ทั้งหมด **internal to TD-02** (ไม่มี SD/ADR/api-spec cascade) — สอดคล้องกับ reviewer's own Z1-Z4 cluster summary. Cluster Z1 (3 HIGH ใน § 7.4.1) = audit residue ของ section ใหม่ที่ Claim 02.10 เพิ่งเพิ่มใน round-02 — ทุก finding = **mechanical edits, no design change**. Total accept rate = 100% (round-01: 100%, round-02: 100%, round-03: 100%) — convergence pattern healthy. CRITICAL = 0 (4-round trend: 5 → 1 → 0 → projected 0).

---

## Claim Responses

### Claim 03.1: § 7.4.1 self-inconsistency: header "(5 sites)" ≠ 8-site listing

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — header "(5 sites)" เป็น carryover จาก claim-review-02 Minimum-Acceptable-Fix wording (ที่บอก "approximately 5") แต่ defender expand listing เป็น 8 sites (จริง = 8 `return INIT_FAILED` statements ใน Phase C lines 1647-1668) โดยไม่ update header. Self-inconsistency ภายใน section เดียวกัน — risk: cleanup audit checklist ที่ใช้ header count = 5 จะ miss 3 sites (sites 6, 7, 8) → silent leak survives audit.

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 line 1722
- What changed: เปลี่ยน header text จาก `(5 sites):` → `(8 sites — matches the 8 'return INIT_FAILED' statements in § 7.4 Phase C lines 1647-1668):` — เพิ่ม cross-reference ให้ reviewer/QA verify ผ่าน double-check ได้
- Evidence: `**Phase C call sites** ที่ต้องใส่ cleanup ก่อน 'return INIT_FAILED' (8 sites — matches the 8 'return INIT_FAILED' statements in § 7.4 Phase C lines 1647-1668):`

---

### Claim 03.2: § 7.4.1 CleanupPartialInit body shows only 4 of 16-19 services + `// ...` placeholder

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — `// ... delete heap-allocated services in reverse Init order` placeholder เป็น doc-debt ที่ block engineer copy-paste. Spec ที่ incomplete = NFR-3.4 transparency promise ส่วน "Alert popup ก่อน MT5 displays EA failed to initialize" ยัง preserved (line 1693-1695 `ErrorBypassThrottle`) **แต่** heap-leak prevention promise functionally unachievable เพราะ engineer reading spec จะลบ helpers + 12+ unreleased pointers เงียบ ๆ. Decision: pick **Option (a) full enumeration** — ทำให้ section self-contained, engineer ไม่ต้อง cross-reference § 7.3 ตอน implement.

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 lines 1689-1719
- What changed: ขยาย body จาก 4 lines + placeholder → 19-line full enumeration: ครบ **16 services (steps 17 → 4)** + **3 helpers (step 3: CAtomicFile, CJsonWriter, CCommentParser)** + **CPipMath (step 2)** + **CLogger (step 1)** = 19 pointers ทั้งหมด. แต่ละ line annotate ด้วย step number per § 7.3 + comment "Helpers = stateless — only delete (no Release/Close needed)" สำหรับ helpers tier
- Evidence (excerpt):
  ```mql5
  if (m_ea_state != NULL)       { delete m_ea_state;       m_ea_state       = NULL; }  // step 17
  if (m_registry != NULL)       { m_registry.ReleaseAll();      delete m_registry;       m_registry       = NULL; }  // step 16
  // ...
  if (m_atomic != NULL)         { delete m_atomic;         m_atomic         = NULL; }  // step 3 (CAtomicFile)
  if (m_json_writer != NULL)    { delete m_json_writer;    m_json_writer    = NULL; }  // step 3 (CJsonWriter)
  if (m_comment_parser != NULL) { delete m_comment_parser; m_comment_parser = NULL; }  // step 3 (CCommentParser)
  if (m_pip != NULL)            { delete m_pip;            m_pip            = NULL; }  // step 2
  if (m_logger != NULL)         { delete m_logger;         m_logger         = NULL; }  // step 1
  ```

---

### Claim 03.3: § 7.4.1 CleanupPartialInit body shows WRONG reverse-Init order

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — body sequence เก่า (m_journal step 11 → m_indicators step 8 → m_registry step 18 → m_portfolio step 7) ไม่ monotonic ใน reverse direction ตามที่ comment "REVERSE Init order" สัญญาไว้. Engineer copy-paste จะ violate the "ป้องกัน null-deref จาก dependent that already Released" contract ที่ comment promise. Edge case ที่ไหวมากคือ engineer extend pattern ผิดทาง (เช่น release m_state step 6 ก่อน m_journal step 11) → null-deref crash ที่ปรากฏเฉพาะ INIT_FAILED scenario (= disk full / permission failure / corrupt state.json) — exact moment ที่ reliable cleanup matters most (NFR-3.4).

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4.1 lines 1696-1719
- What changed: re-sequence body ให้ monotonic descending: step 17 → 16 → 15 → 14 → 13 → 12 → 11 → 10 → 9 → 8 → 7 → 6 → 5 → 4 → 3 (helpers) → 2 → 1. Updated comment ก่อน body ระบุ explicitly "Monotonic descent: 17 → 16 → ... → 1"
- Evidence: ทุก line ใน enumeration มี `// step N` comment ที่ลด monotonic จาก 17 → 1 — ตรวจสอบได้ visually
- **Cascaded:** Numbering ทั้งหมดอ้างอิง renumbered DI table จาก Claim 03.4 (steps 17 = EAState, 16 = SlotRegistry, ... ตาม § 7.3 ใหม่)

---

### Claim 03.4: § 7.3 DI map orphan numbering after row consolidation

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — round-02 consolidation ที่ลบ rows 3, 4, 5 (helpers หลายแถว) เป็น row 2.5 ทำให้ table มี gap (1 → 2 → 2.5 → 6 → 6.5 → 7 → 7b → 8...). Reader/AI agent ที่ generate `WireServices()` จาก DI table per "single source-of-truth" promise จะ confused — assume hidden dependency ที่ไม่มี. Decision: pick **Option B (continuous renumbering 1-17 + letter suffixes 4a/5a สำหรับ cycle setters)** — eliminates gap + keeps cycle-setter rows visually distinct (suffix = "ไม่นับเป็น service Init step").

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.3 DI table (lines 1581-1599) + intro paragraph (lines 1576-1577) + 2-phase init recap (line 1603)
- What changed:
  - Renumber rows: `1 → 2 → 3 (helpers) → 4 (StatePersistence) → 4a (Logger.SetSP setter) → 5 (PortfolioState) → 5a (SP.SetPort setter) → 6 → 7 → ... → 17`
  - เพิ่ม callout box อธิบาย numbering convention: "16 services + 1 helpers row + 2 setter rows = 19 total table rows; 16 Init() calls in Phase B"
  - Update intro paragraph references: "step 6.5" → "step 4a"; "step 7b" → "step 5a"
  - Update 2-phase init recap: "step 6.5 + step 7b" → "step 4a + step 5a"
  - Header column rename: `Service` → `Service / Setter` ให้สะท้อน mixed content
- **Cascaded:**
  - § 5.6 line 769 skeleton comment: `(DI step 7b per § 7.3)` → `(DI step 5a per § 7.3)` — StatePersistence::SetPortfolioState
  - § 5.7 line 844 skeleton comment: `(DI step 6.5 per § 7.3)` → `(DI step 4a per § 7.3)` — Logger::SetStatePersistence
  - § 7.4 Phase B inline comments (lines 1620-1623): `step 6.5` → `step 4a`; `step 7b` → `step 5a`
  - § 9.3 runtime error message (line 2001): `"Orchestrator missed step 7b"` → `"Orchestrator missed step 5a"` — engineer-debugging string ที่ defender's defensive guard prints ตอน Cycle 2 setter ไม่ถูกเรียก
  - § 9.4 prose paragraph (line 2022): `หลัง DI step 6.5` → `หลัง DI step 4a`

---

### Claim 03.5: § 7.4 reviewer checklist + intro both say "× 18 services" but actual count is 16 services + 3 helpers (no Init)

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — round-02 Claim 02.2 fix ลบ standalone Init rows สำหรับ 3 helpers + consolidate เป็น row 2.5 "no Init() declared" ส่งผลให้ actual Init() call count ใน Phase B = **16** (ไม่ใช่ 18). intro line 1607 + reviewer checklist line 1676 ยังระบุ "× 18" — off-by-2 drift. Reviewer running checklist `count(Init calls) == 18` จะ fail (actual = 16) → friction หรือ false alarm Cat 4.

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 intro line 1607 + reviewer checklist line 1683
- What changed:
  - Intro: `surface ครบ 18 service Init calls + 2 setter calls (DI step 6.5 + 7b)` → `surface ครบ **16 service Init calls + 3 helpers (no Init) + 2 setter calls** (DI step 4a + 5a)`
  - Reviewer checklist: `(× 18) ต้องมี exactly 1 Init(...) call` → `(× 16 services + 3 helpers (no Init)) ต้องมี exactly 1 Init(...) call ใน Phase B (= 16 Init calls)` + appended sentence อธิบาย helpers = stateless utilities, skip Init
- Evidence (line 1683): `> **Reviewer checklist:** ทุก service ใน § 7.3 (× 16 services + 3 helpers (no Init)) ต้องมี exactly 1 Init(...) call ใน Phase B (= 16 Init calls); cycle setters (step 4a + 5a) ต้องอยู่ตรงตำแหน่ง — ห้ามย้าย ห้ามลบ. Helpers (CCommentParser, CJsonWriter, CAtomicFile) = stateless utilities — construct on heap ใน Phase A แล้ว skip Init.`

---

### Claim 03.6: Logger LRU eviction reset semantics undocumented for parallel arrays

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — eviction comment (lines 826-827) ระบุ LRU + emit-warn behavior แต่ไม่ระบุ array-reset contract สำหรับ parallel arrays `m_consecutive_count[]` + `m_last_tick_seen[]`. Edge case: new tuple lands at recycled idx ที่ stale `m_last_tick_seen[idx]` happens to equal `m_tick_counter - 1` → ghost continuation → false escalation. Probability ต่ำแต่ non-zero. Decision: pick **Option 1 (declaration-comment update)** — cheapest, contract location-correct (declaration where method is defined).

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 5.7 line 866 (now expanded to lines 866-871) — `FindOrEvictKey` declaration
- What changed: เพิ่ม inline contract comment ก่อน method declaration:
  ```mql5
  // LRU when buffer full. **Eviction-reuse contract (Claim 03.6):** เมื่อ idx ถูก reuse
  //   สำหรับ tuple ใหม่ (existing slot ถูก evict), callee MUST reset parallel arrays ที่ idx
  //   นั้น ก่อน return: `m_consecutive_count[idx] = 0` + `m_last_tick_seen[idx] = 0`
  //   (= ป้องกัน ghost continuation จาก stale state ของ tuple เก่าทำให้ false-escalate
  //   เมื่อ recycled idx coincidence กับ tick adjacency ของ tuple ใหม่).
  int    FindOrEvictKey(string key);
  ```
- Evidence: contract กำกับชัดเจนใน skeleton — engineer implementing FindOrEvictKey จะเห็น reset requirement immediately

---

### Claim 03.7: § 8.1 Mermaid Class Diagram CIndicatorService missing 4 accessors

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — § 5.1 skeleton declares 8 public methods แต่ § 8.1 class diagram show เพียง 4. Missing: `Init`, `ReleaseHandles`, `GetHandle`, `HandleCount`. `HandleCount()` (เพิ่งเพิ่ม round-02 Claim 02.5) + `ReleaseHandles()` (used ใน CleanupPartialInit Claim 02.10 + 03.2) ที่ไม่ปรากฏใน diagram = engineer reading diagram จะไม่ทราบ method exists → duplicate re-add risk.

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 8.1 lines 1736-1746 — `class CIndicatorService` Mermaid block
- What changed: เพิ่ม 4 missing methods:
  ```mermaid
  +Init(CLogger*) void
  +ReleaseHandles() void
  +GetHandle(int) int
  +HandleCount() int
  ```
- Evidence: class block ตอนนี้ระบุครบ 8 public methods ตรงกับ § 5.1 skeleton — visual spec + text spec aligned

---

### Claim 03.8: § 9.4 EscalateIfThresholdMet comment vs code semantic drift on "consecutive ticks"

**Verdict:** Accept

**Rationale:** Reviewer ถูกต้อง — comment เก่าระบุ "tick N-1 และ tick N ติดต่อกัน (= delta ≤ 1)" ที่ strict interpretation = 2 distinct adjacent ticks. แต่ code accept ทั้ง delta=1 (adjacent) **AND** delta=0 (same tick, multiple Error calls in 1 OnTick). Comment ไม่ครอบคลุม same-tick burst case → future maintainer reading ADR-011 strict reading จะคิดว่าเป็น bug. Defensible interpretation = same-tick burst เป็น abnormal pattern worth escalating per ADR-011 spirit. Decision: pick **Option 1 (clarify TD comment)** — preserve current code (which is correct per design intent), update comment ให้สะท้อน 2-case semantic explicitly.

**Changes Made:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 9.4 lines 2024-2032 (formerly 2018-2021)
- What changed: comment expansion จาก 4 lines → 9 lines แยก 2 cases ที่ counter increments:
  - **(a) adjacent-tick continuation:** delta = 1
  - **(b) same-tick burst:** delta = 0 (multiple Error in single OnTick)
  - **gap > 1:** reset counter to 1
- Evidence:
  ```
  // Implementation note (Claims 02.9 + 03.8 fix): "consecutive" semantic =
  //   `m_tick_counter - m_last_tick_seen[idx] <= 1` — ครอบคลุม **2 cases**:
  //     (a) **adjacent-tick** continuation: tuple emit Error() ที่ tick N-1 และ tick N (delta = 1)
  //     (b) **same-tick burst**: tuple emit Error() หลายครั้งภายใน OnTick เดียว (delta = 0)
  //         — same-tick burst นับเป็น continuation ตาม design intent (multiple errors within
  //         a single tick is itself an abnormal pattern worth escalating per ADR-011 spirit).
  ```
- **Note:** ADR-011 line 60 wording "consecutive ticks" ยังคงไว้ — TD-02 implementation note clarify scope (same-tick burst = abnormal burst pattern, count ตาม spirit). ถ้า future-maintainer ต้องการ formalize ADR-011, run `/backtrack sd` แยกต่างหาก (ไม่ใช่ TD scope).

---

## Cascaded Changes

> ทั้งหมด 8 claims อยู่ใน TD-02 internal — ไม่มี SD/ADR/api-spec cascade ตามที่ reviewer Z1-Z4 summary บอก. แต่ภายใน TD-02 มี cascade chain ผ่าน Claim 03.4 (DI numbering rename) ที่ propagate ลงไปยัง:

1. **§ 5.6 line 769** — `CStatePersistence::SetPortfolioState` skeleton comment: `DI step 7b` → `DI step 5a`
2. **§ 5.7 line 844** — `CLogger::SetStatePersistence` skeleton comment: `DI step 6.5` → `DI step 4a`
3. **§ 7.4 Phase B inline comments (lines 1620-1623)** — `step 6.5` → `step 4a`; `step 7b` → `step 5a`
4. **§ 9.3 runtime error message (line 2001)** — `Orchestrator missed step 7b` → `Orchestrator missed step 5a` (engineer-facing diagnostic string)
5. **§ 9.4 prose paragraph (line 2022)** — `หลัง DI step 6.5` → `หลัง DI step 4a`

> **Self-validation grep gate (per reviewer's Notes for Defender line 239):**
> ```
> grep -nE "× 18|5 sites|step 6\.5|step 7b|DI step 6\.5|DI step 7b" docs/technical-design/02-backend-design.md
> ```
> Result: **ZERO HITS** — numeric residue cleared, no orphan references to old DI step numbering or stale counts remain in TD-02.
>
> **Init count gate:** `grep -cE "m_<service>\.Init"` returns **16** Init calls in Phase B (matches "× 16 services" claim). Verified via per-pointer regex sweep.

---

## SD Boundary Check

> All 8 claims ปฏิบัติได้ภายใน TD-02 — ไม่ต้องแตะ SD-02, SD-03, ADR-005, ADR-011, หรือ api-specs ใด ๆ. Reviewer's own Recommendation line 224 ระบุชัด: "No SD/ADR cascade required for this round — all 8 findings = TD-02 internal. No `/backtrack sd` action item." Defender concur.
>
> **Note on ADR-011 reading (Claim 03.8):** TD-02 § 9.4 implementation note clarify "consecutive" semantic ภายใน TD scope; ไม่แตะ ADR-011 line 60 wording. ถ้า future review ต้องการ formal ADR-011 amendment สำหรับ same-tick burst handling, นั่น is `/backtrack sd` work — defer.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (8/8) | Defender concurs across the board — round-03 findings ทั้งหมด valid mechanical edits, ไม่ต้อง dispute |
| Critical Fixes | 0 | CRITICAL = 0 (round-01: 5 → round-02: 1 → round-03: 0); 4-round trend แข็งแรง |
| HIGH Fixes | 3 | ทั้ง 3 อยู่ใน Z1 cluster § 7.4.1 — single-section cleanup pass; pair-fix Claims 03.1+03.2+03.3 ใน 1 edit |
| Cross-Domain Fixes | 5 (cascade chain) | DI numbering rename propagated ผ่าน 5 sites ใน TD-02 (§ 5.6 + § 5.7 + § 7.4 + § 9.3 + § 9.4) — caught via self-validation grep, would have been silent residue otherwise |
| Net Improvement | High | Cleanup helper ตอนนี้ engineer copy-paste compile-clean + null-deref-safe + reviewer checklist count-correct + DI table self-consistent |
| Remaining Gaps | 0 known | Self-validation grep 0 hits; 16-Init count verified; class-diagram aligned with skeleton |

---

## Round-Over-Round Trend

| Round | Findings | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | 🔵 LOW | Resolved this round |
|-------|----------|------|------|--------|------|---------------------|
| 01 | 20 | 5 | 8 | 5 | 2 | 20 (100% Accept) |
| 02 | 9 | 1 | 2 | 5 | 1 | 9 (100% Accept) |
| 03 (current) | 8 | 0 | 3 | 3 | 2 | 8 (100% Accept) |
| 04 (projected) | ≤ 2 | 0 | 0 | ≤ 1 | ≤ 1 | converge |
| 05 (projected target) | 0 | 0 | 0 | 0 | 0 | **Ready for Implementation Handoff** |

> **Convergence signal:** CRITICAL = 0 sustained ทั้ง round-02 + round-03. HIGH spike จาก 2 → 3 = audit residue ของ section ใหม่ § 7.4.1 (Claim 02.10 created round-02). หลังจาก § 7.4.1 cleanup pass round-03 — Z1 cluster fully resolved + reviewer's projected round-04 ≤ 2 findings + projected round-05 = 0 = realistic.
>
> **Comparison to BA (3 rounds) + SD (4 rounds):** TD trending toward 4-5 rounds = on-track ตาม reviewer note. Round-01 broad rewrite (3 core skeletons + OnInit 3-phase + 9-file cascade) introduced more cascade tail than typical, but each successive round shrinks; momentum healthy.

---

## Recommendation

- [x] **Request Re-Review (round 04)** — verify Z1-Z4 cluster closure:
  - **Claim 03.1:** "(8 sites)" header confirmed
  - **Claim 03.2:** body enumerate ครบ 19 pointers (16 services + 3 helpers) — verify ผ่าน Read § 7.4.1
  - **Claim 03.3:** monotonic reverse Init order (step 17 → 1) — verify per-line `// step N` annotations descend
  - **Claim 03.4:** § 7.3 DI table renumbered 1-17 + suffix 4a/5a; cascade verified ผ่าน 5 sites
  - **Claim 03.5:** "× 16 services + 3 helpers" updated in § 7.4 intro + reviewer checklist
  - **Claim 03.6:** § 5.7 FindOrEvictKey contract comment added
  - **Claim 03.7:** § 8.1 CIndicatorService class block now มี 8 methods (matches § 5.1 skeleton)
  - **Claim 03.8:** § 9.4 comment ตอนนี้ระบุ same-tick burst case explicitly

- [ ] ~~Ready for Implementation Handoff~~ — premature; round-04 verification needed before handoff. Round-04 expected ≤ 2 findings (mostly grep residue if any); round-05 = 0 = handoff-ready.

- [ ] **No SD/ADR cascade required** for this round — confirmed per reviewer's own assessment.

- [ ] ~~Needs Stakeholder Input~~ — no deferred items.

> **Effort estimate:** Round-04 cycle ≈ 0.5 day (verification-only — defender expects all 8 fixes to pass). Total path to Implementation Handoff readiness: **≈ 0.5-1 day** (round-04 verify + round-05 zero-finding sweep).

---

## Notes for Reviewer (round-04)

- **Z1 closure:** § 7.4.1 ทั้ง section ผ่าน combined edit pass (header count + full enumeration + correct order). Verify ผ่าน 1 read + spot-check ของ step numbering.
- **Z2 closure:** § 7.3 DI table renumber + § 7.4 intro/checklist count อาจ test ด้วย grep `× 18|5 sites|step 6\.5|step 7b` = expect 0 hits (ผ่าน defender's self-validation gate)
- **Z3 closure:** § 5.7 contract + § 9.4 comment ทั้งคู่ = comment-only edits; verify text quality + scope clarity
- **Z4 closure:** § 8.1 CIndicatorService class block — verify 8 methods present + match § 5.1 skeleton text exactly
- **Cascade integrity:** 5 sites updated under Claim 03.4 (§ 5.6 + § 5.7 + § 7.4 + § 9.3 + § 9.4); reviewer can spot-check by greping `step 4a|step 5a|DI step 4a|DI step 5a` — should find consistent usage; old terms zero hits
