# System Design Rebuttal Round 05

| Field | Value |
|-------|-------|
| **Round** | 05 |
| **Claim Review** | `claim-review-07.md` |
| **Date** | 2026-05-17 |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |
| **Predecessor** | rebuttal-round-04 (2026-05-12; BT-001 cascade closure — 11 accept) → claim-review-06 (2026-05-13; 0 finding verify-only — no rebuttal needed) → BT-002 (2026-05-17 operator Option 1 legacy-parity) → claim-review-07 (2026-05-17; first adversarial sweep of post-BT-002 SD package — 7 findings) |
| **Trigger** | BT-002 cascade-completion + audit-freshness gaps surfaced by claim-review-07 — 2 HIGH (Phase Hint Summary stale + Last-updated headers stale) + 3 MEDIUM (ADR Digest count mismatch + line-anchor brittleness + STRIDE row verbosity + mermaid stranded note) + 1 LOW (Glossary duplicate entries pre-existing — surfaced opportunistically) |

> **Naming note:** Filename = `rebuttal-round-05.md` (next sequential rebuttal artifact after rebuttal-round-04; Round 06 review = 0 finding verify-only so no rebuttal generated). Cycle counter aligns with claim review numbering: claim-review-07 → rebuttal-round-05 (since Round 06 review skipped rebuttal generation; sequence mirrors Round 04 verify-only → Round 05 review pattern).

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |

**Accept Rate:** 100% (7/7) — mirror Round 04 (11/11) finding-spike pattern after BT-001 cascade work-in-progress; Round 05 = mechanical cascade-completion class (parallel-narrative sections § 5 Phase Hint Summary, Last-updated headers, ADR Digest count, line anchors, mermaid stranded note, STRIDE row verbosity, pre-existing Glossary duplicate). All 7 findings = sweep-completion/freshness/readability dimensions — no architectural defect; BT-002 cascade fundamentals (semantic invariants, halt trigger reduction 2→1, ADR amendments with audit history, API spec enum updates per `claim-review-07 § At-a-Glance Net assessment`) untouched.

**Files modified:**
- `docs/design-docs/02-high-level-architecture.md` (4 edits — header L5 BT-002 stamp, § 8 Glossary merge L447/L451 → single canonical entry, § 9 ADR Digest add ADR-013/014 superseded rows L473-474, footer L476 count "25 components / 12 active + 2 superseded")
- `docs/design-docs/03-deep-dive.md` (2 edits — header L5 BT-002 stamp, § 1.5 Validation line-anchor → `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` symbol cite per ADR-009 G4 toggle pattern)
- `docs/design-docs/04-data-flow.md` (3 edits — header L5 BT-002 stamp, § 1.1 mermaid delete stranded "CircuitBreaker.CheckPingPong removed" note L46, footer note added below diagram pointing to ADR-010 § Revision history + 02 § 4.2 removal footer + backtrack-log)
- `docs/design-docs/05-security.md` (3 edits — header L5 BT-002 stamp, § 2.5 DoS row "Infinite re-entry loop" tightened to STRIDE row format with → § 9 forward pointer, § 9 Red Team Hand-off added "BT-002 accepted residual risk — infinite re-entry loop" row with cap-3 iter chain audit trail)
- `docs/design-docs/08-product-breakdown.md` (4 edits — header L5 BT-002 stamp, § 1.10 IMPL-063 task row line-anchor → symbol cite, § 5 Phase Hint Summary P2 row IMPL-051 strikethrough + "~10 tasks" + Total "~67" recount, § footer end-of-doc recount)

**ADRs updated/created:** none — ADR-010 amendment + ADR-013/014 Status flip Accepted → Superseded by BT-002 already landed in BT-002 commit `0be2a51` (per `claim-review-07 § At-a-Glance BT-002 propagation surface coverage`). This rebuttal closes the cascade-completion gaps in SD narrative sections that BT-002 commit didn't reach.

**API specs updated:** none — `trade-journal-schema.yaml` halt_reason + triggering_function enums already drop ping-pong entries per BT-002 commit `0be2a51` (verified in `claim-review-07 § Cross-Document Issues table`).

---

## Claim Responses

### Claim 07.1: 🟠 HIGH — Phase Hint Summary § 5 ใน `08` not propagated alongside IMPL-051 cancellation in § 1.7 / § 3 / § 4

**Verdict:** Accept

**Rationale:** Reviewer ถูก — § 5 Phase Hint Summary คือ table ที่ Impl Planner หยิบไปสร้าง `docs/state/impl-plan.md` Phase status snapshot + Phase × Size matrix (per Phase 5 mechanical gate #3 ใน `.claude/rules/workflow.md`). ก่อน fix นี้ § 5 P2 row ยังคงระบุ `IMPL-051` ไม่มี strikethrough + task count "~11 tasks" + total "~68" — ทั้งที่ § 1.7 line 103 + § 3 line 226 + § 4 line 286 ปิด IMPL-051 ด้วย CANCELLED-BT-002 strikethrough แล้ว. ถ้า Impl Planner consume § 5 ตามตัวอักษร → register IMPL-051 ใน P2 → `/impl-task` HALT ทันที (work tree ไม่มี IMPL-051 spec) + denominator P2 = "10 of 11" trip gate #3 + TL;DR `Phase 2 x/y` denominator stale ตั้งแต่ปั้น. Same defect class เป็น "rebuttal-output verification gap" ที่ Round 03→04 cumulative-counter cascade เคยจัดการ.

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` § 5 Phase Hint Summary (L308) + § 5 Total footer (L312) + § End-of-doc footer (L320)
- What changed:
  - P2 row task list: IMPL-051 ใส่ strikethrough `~~051~~`; "~11 tasks" → "~10 tasks (post-BT-002 IMPL-051 cancellation)"
  - Total: "~68 implementation tasks" → "~67 implementation tasks (post-BT-002 — was ~68; IMPL-051 `CircuitBreaker::CheckPingPong` cancelled per BT-002 2026-05-17 legacy-parity)"
  - End-of-doc footer: "68 implementation tasks across 9 epics" → "67 implementation tasks across 9 epics (post-BT-002 IMPL-051 cancelled)"
- Evidence (new text — § 5 P2 row): *"| **P2 — Core Services + EAState + Pending** | IMPL-040, 041, 043, 044, 045, 047, 048, 049, 050, ~~051~~, 052 | XS-XL, ~10 tasks (post-BT-002 IMPL-051 cancellation) | medium overall, IMPL-049 XL |"*
- ADR updated: none (Phase Hint Summary = work-inventory derived view, ไม่ใช่ architectural decision)

---

### Claim 07.2: 🟠 HIGH — Last-updated header stale ใน 5/6 SD docs

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Last-updated header เป็น "the only structured freshness signal" สำหรับ downstream readers (TD agent, QA agent, Impl Planner) ที่ scan SD docs without diffing commit log. BT-002 commit `0be2a51` applied massive prose edits to 5 docs (FR-6.6/FR-7.7 in `02`, § 1.5 Validation + § 2.3 perf tables in `03`, mermaid + § 9.1 row in `04`, TL;DR + § 2.5 + § 3.2 + § 3.3 + § 7.2 in `05`, IMPL-051/IMPL-052/Phase Hint/per-task metadata in `08`) แต่ไม่ได้ propagate header field. Result: TD reviewer Phase 1D อ่าน `02 § 1.1` FR-6.6 strikethrough + Last-updated `2026-05-12 (BT-001 cascade...)` → mental model conflict (BT-001 ไม่แตะ FR-6.6 — เป็น BT-002 surface). Same defect class as Phase 5 mechanical gate #4 (Sentinel counter increment) — atomic update ของ rewrite + state-doc surface.

**Changes:**
- 5 files, each L5 header rewrite to `2026-05-17 (BT-002 cascade — ...)` พร้อม doc-specific surface enumeration + "Prior:" tail preserving the BT-001 (or initial publish) cite for audit chain:
  - `02-high-level-architecture.md` L5 → BT-002 surface = FR-6.6 strikethrough § 1.1, FR-7.7 rewrite § 1.1, Component Catalog row #14 removal § 4.2, Communication Matrix § 5.1 update, Glossary § 8 Bucket B re-author
  - `03-deep-dive.md` L5 → BT-002 surface = § 1.3 outline + § 1.5 Validation re-frame post-BT-002, § 2.3 Table A/B −5 µs annotation
  - `04-data-flow.md` L5 → BT-002 surface = § 1.1 mermaid CB participant + ping-pong alt-branch removed, § 9.1 cross-slot enable matrix row removed (Initial publish: 2026-05-02 tail preserved)
  - `05-security.md` L5 → BT-002 surface = TL;DR + § 2.5 DoS row "Infinite re-entry loop" + § 3.2 + § 3.3 + § 7.2 halt event row re-author + § 9 Red Team Hand-off cap-3 iter audit row
  - `08-product-breakdown.md` L5 → BT-002 surface = IMPL-051 CANCELLED § 1.7, IMPL-052 amend § 1.7, P2/P4 Phase Hint § 3, per-task metadata § 4, IMPL-062/063 narrative § 1.10, Phase Hint Summary § 5 task count + total recount (incorporating Claim 07.1 follow-up)
- `07-future-evolution.md` L5 = `2026-05-02` untouched (correctly — BT-002 ไม่กระทบ E1/E2 Evolution Sequence; `claim-review-07 § 19` ✅ Pass confirmed)
- Evidence (new text — `02` L5): *"> **Last updated:** 2026-05-17 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; cap-3 iter ADR-013 → ADR-014 superseded; FR-6.6 strikethrough § 1.1, FR-7.7 rewrite § 1.1, Component Catalog row #14 removal § 4.2, Communication Matrix § 5.1 update, Glossary § 8 Bucket B re-author. Prior: 2026-05-12 BT-001 cascade — ...)"*
- ADR updated: none

---

### Claim 07.3: 🟡 MEDIUM — `02 § 9 ADR Digest` narrates "12 ADRs" but 14 .md files exist post-BT-002

**Verdict:** Accept

**Rationale:** Reviewer ถูก — `docs/adr/` มี 14 .md files (`001.md` ถึง `014.md`); ADR-013/014 ถูก author ระหว่าง IMPL-FIX-012 iter-1/iter-2 (2026-05-14/2026-05-17) แล้วถูก supersede โดย BT-002 in-place same day พร้อม Status `Superseded by BT-002 2026-05-17 (preserved as audit history)` (verified Read of both ADR files at L5). § 9 ADR Digest table + L474 footer "12 ADRs" ไม่ propagate. Reader (TD reviewer, QA, Impl Planner) navigate ไป `docs/adr/` เห็น 14 files แต่ § 9 enumerates 12 → "ADR-013/014 คืออะไร? ทำไม Digest ไม่ mention?" confusion. ADR discipline ใน `.claude/rules/workflow.md § ADR Discipline` กำหนด 1:1 file:row + superseded ADRs เป็น valid historical decisions ที่ implementers อาจ reference สำหรับ "why was this path tried?". Methodology trace ของ BT-002 cap-3 iter chain (iter-1 ADR-013 + iter-2 ADR-014 + iter-3 escalation) = empirical proof ที่ supports Option 1 legacy-parity decision; suppressing 013/014 ใน Digest = losing audit trail. Cross-doc consistency: `ADR-010 § Revision history` explicitly cites both ADR-013/014 superseded — `02 § 9` ควร mirror.

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest (after L472 ADR-012 row) + footer (L474)
- What changed:
  - Added 2 rows after ADR-012 = ADR-013 row (DEAL_REASON_EXPERT filter — Status "Superseded by BT-002 2026-05-17" + 1-line audit trail) + ADR-014 row (position_id + event_type dedup — Status "Superseded by BT-002 2026-05-17" + 1-line audit trail). Trade-off column quotes the iter chain failure reason (preserved as audit history); Link column points to `../adr/013-*.md` + `../adr/014-*.md`
  - Footer: "26 components across 5 layers, 12 ADRs covering all major architectural decisions" → "25 components across 5 layers (CircuitBreaker row removed per BT-002), **12 active ADRs + 2 superseded** (ADR-013/014 preserved as BT-002 cap-3 iter audit history)"
- Evidence (new ADR-013 row): *"| ADR-013 | CircuitBreaker BR-3.6 ping-pong DEAL_REASON_EXPERT filter | **Superseded by BT-002 2026-05-17** | (iter-1 surgical filter — closed broker-driven SL false-positive class; preserved as audit history of cap-3 iter chain) | n/a — superseded | [013](../adr/013-circuitbreaker-pingpong-deal-reason-filter.md) |"*
- ADR updated: none (ADR-013/014 Status flip = already-landed BT-002 cascade work — this rebuttal closes the SD-side digest gap only)

---

### Claim 07.4: 🟡 MEDIUM — Line-anchor brittleness ของ `Slot_J.mqh:180` + `Slot_BI.mqh:212` ที่ cited ใน `03 § 1.5` + `08 § 1.10` ขัด workflow gate #9 (h)

**Verdict:** Accept

**Rationale:** Reviewer ถูก — files `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` + `Slot_BI.mqh` ยังไม่ถูกเขียน (IMPL-022 + IMPL-039 = Phase 3I tasks ที่ยังไม่เริ่ม per impl-plan); line numbers 180 + 212 = engineering guess. แม้หลังเขียนเสร็จ, line numbers จะ drift ทุกครั้ง refactor — cite สลายเงียบ. `.claude/rules/workflow.md § Gate #9 clause (h)` กำหนดชัด: *"bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor"*. แม้ rule นั้นเป็น code-comment scope, SD doc cite ของ engineering toggle อยู่ใน same brittleness class (same R23 "Methodology-scope axis surfaced" — tree-wide verification ของ newly-authored guidance). BT-002 cascade เป็น first time line anchors ถูก introduced; verify-sweep นี้ = proper time to surface.

**Changes:**
- File 1: `docs/design-docs/03-deep-dive.md` § 1.5 Validation (L59)
- File 2: `docs/design-docs/08-product-breakdown.md` § 1.10 IMPL-063 task row (L130)
- What changed: แทนที่ `slots/Slot_J.mqh:180` + `slots/Slot_BI.mqh:212` ด้วย `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` (per ADR-009 G4 fix toggle pattern). Symbol cite = grep-stable (function definitions); `#ifdef DISABLE_G4_FIXES` = grep-stable comment/preprocessor marker. ADR-009 G4 fix toggle pattern citation = stable cross-doc reference (ADR file owns the toggle semantic).
- Evidence (`03 § 1.5` new text): *"...full-window G4 contribution measurable if forensic toggle retained at `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` (per ADR-009 G4 fix toggle pattern)..."*
- Evidence (`08 § 1.10` new text): *"...full-window G4 contribution measurable if forensic toggle retained at `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` per ADR-009 G4 fix toggle pattern..."*
- ADR updated: none (ADR-009 G4 toggle pattern unchanged — referenced as stable anchor)
- Out-of-scope notes: `docs/state/impl-plan.md` + `docs/state/deferred-ac-registry.md` + `docs/state/backtrack-log.md` + `docs/state/impl-plan-claim-review-and-rebuttal/claim-review-11.md` + `docs/state/_parallel-context/impl-task-parallel-20260505-1144.md` ยังคง cite `Slot_J.mqh:180` หรือ `Slot_BI.mqh:212` — เหล่านี้อยู่นอก SD scope (impl-plan + state-doc domain ของ Impl Planner / Engineer roles). Recommend: chained `/impl-plan-review` หรือ `/impl-task` ถัดไป propagate symbol-cite pattern เป็น cascade-completion task ที่ impl layer. (sd-defender SKILL ห้ามแก้ `services/` + `docs/state/` ตาม ownership matrix.)

---

### Claim 07.5: 🟡 MEDIUM — `05 § 2.5` DoS row "Infinite re-entry loop" — mitigation prose verbose; collapse to STRIDE-row format

**Verdict:** Accept

**Rationale:** Reviewer ถูก — STRIDE table = quick reference สำหรับ threat enumeration + mitigation; row format ควร scan-friendly. ก่อน fix row Mitigation column ยาว 2 paragraphs + Likelihood/Impact columns เป็น free-prose ยาว; ผสม "threat description" + "mitigation rationale" + "audit history" สามมิติใน 1 cell → reduce scan-ability + BT-002 audit annotation ("Former FR-6.6 CircuitBreaker ping-pong removed") = transient cite ที่ tax current-state security model.

**Changes:**
- File: `docs/design-docs/05-security.md` § 2.5 Denial of Service (L120) + § 9 Red Team Hand-off Notes (new row before End-of-doc)
- What changed:
  - § 2.5 row "Infinite re-entry loop" tightened: Threat column = bold name + 1-line scope qualifier; Likelihood + Impact compact parenthetical; Mitigation = 1 paragraph compact, ends with "→ ดู § 9 Red Team Hand-off Notes สำหรับ cap-3 iter chain ADR-013 → ADR-014 audit trail" (forward pointer to destination ที่ defined ใน same doc)
  - § 9 Red Team Hand-off Notes table — added new row "BT-002 accepted residual risk — infinite re-entry loop" ที่ enumerate cap-3 iter chain audit (ADR-013 iter-1 → ADR-014 iter-2 → BT-002 escalation) + Phase 2 escalation candidates + Red Team-actionable approach (synthetic pathological scenario + equity-floor calibration if Phase 2 promoted)
  - § 9 End-of-doc footer updated: "..., Red Team hand-off" → "..., Red Team hand-off (incl. BT-002 accepted residual risk audit trail)"
- Evidence (new § 2.5 row): *"| **Infinite re-entry loop** (no automated portfolio-level loop guard Phase 1) | Low (legacy `PhoenicisN2.10_stable` 5-yr backtest demonstrates safe operation without one) | High (could blow account; no automated detector) | **Accepted residual risk per BT-002 2026-05-17** (legacy-parity) — operator monitoring + manual EA detach are Phase 1 mitigations; per-slot SL/TP + cross-slot SafePort + RiskManager.ClampLot + force-pending timeouts cap individual exposure. Phase 2 trigger candidates per ADR-010 Revisit-when. → ดู § 9 Red Team Hand-off Notes สำหรับ cap-3 iter chain ADR-013 → ADR-014 audit trail. |"*
- ADR updated: none

---

### Claim 07.6: 🟡 MEDIUM — `04 § 1.1` mermaid stranded "Note over Orc: CircuitBreaker.CheckPingPong removed per BT-002" inside current-state sequence

**Verdict:** Accept

**Rationale:** Reviewer ถูก — `04 § 1.1` mermaid sequence diagram = "first-time reader" visual reference สำหรับ OnTick pipeline ที่ปัจจุบัน. Diagram of current-state OnTick pipeline ไม่ควรอ้างถึง code path ที่ถูกลบ — audit trail ของการลบอยู่ใน commit history + ADR-010 § Revision history + `02 § 4.2` Component Catalog footer แล้ว. Inline "removed" note ใน operational diagram = reader (Tech Lead, QA, junior dev) เห็น annotation แล้วเกิด mental model conflict ("CB ยังอยู่ในระบบหรือเปล่า? ทำไมต้องประกาศการลบใน flow diagram?"). Compare: `02 § 4.2` Component Catalog footer ทำถูก (audit footnote ใต้ table); `04 § 1.1` mermaid ทำตรงข้าม.

**Changes:**
- File: `docs/design-docs/04-data-flow.md` § 1.1 OnTick mermaid (L46 delete + footer note added after diagram fence L120)
- What changed:
  - Deleted L46 `Note over Orc: CircuitBreaker.CheckPingPong removed per BT-002 2026-05-17 (legacy-parity)` from mermaid body
  - Added prose footer note **below** mermaid (parallel to `02 § 4.2` removal-footer pattern): *"> **Note (post-BT-002 2026-05-17):** Former `CircuitBreaker::CheckPingPong()` call ที่เคยอยู่ระหว่าง `MarketContextBuilder.Build()` และ `AnyHandleInvalid()` check ถูกลบเป็น legacy-parity. ดู `ADR-010 § Revision history` + `02 § 4.2` Component Catalog removal footer + `backtrack-log.md § BT-002` สำหรับ cap-3 iter chain rationale."*
  - 4 existing audit-trail destinations preserved: (a) `02 § 4.2` footer ✅, (b) `ADR-010 § Revision history` ✅, (c) `backtrack-log.md § BT-002` ✅, (d) Git commit `0be2a51` ✅
- Evidence: see "What changed" above
- ADR updated: none

---

### Claim 07.7: 🔵 LOW — `02 § 8 Glossary` duplicate semantic entries "Halted state semantic" + "HALT vs HALT_STABLE"

**Verdict:** Accept

**Rationale:** Reviewer ถูก — 2 entries (L447 "Halted state semantic" + L451 "HALT vs HALT_STABLE") define semantic เดียวกัน — ทั้งคู่ cite ADR-010, ใช้ wording slightly different. Glossary discipline (per `system-design-master-prompt.md § Readability Contract`) = single canonical definition per term. Duplicate = reader trust ลดลง + maintenance burden (amendment ต้องแก้ทั้ง 2 places) + cross-doc cite drift risk. Pre-existing — ไม่ใช่ BT-002 introduced — แต่ BT-002 review = โอกาส surface (Anti-Duplication sweep โอกาสเดียวกับ cumulative-counter cascade Round 03→04 pattern).

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 8 Glossary (L447 + L451)
- What changed:
  - Replaced L447 "Halted state semantic" with merged canonical entry "**HALTED state machine (HALTED / HALTED_STABLE)**" ที่ unify ทั้ง 2 semantics + cite ADR-010 (amended BT-002) + cross-slot disable + persistence pointer
  - Deleted L451 duplicate "HALT vs HALT_STABLE" entry entirely
- Evidence (new merged entry): *"| **HALTED state machine (HALTED / HALTED_STABLE)** | EA state per ADR-010 (amended BT-002). **HALTED** = exit pass run + entry pass skip + cross-slot EOverload/GOverload disabled. **HALTED_STABLE** = HALTED + `PortfolioState.TotalActivePositions() == 0` (second Alert emitted). Both states persist via `state.json § ea_state`; OnInit reset to RUNNING |"*
- ADR updated: none (ADR-010 amendment-by-BT-002 already landed in commit `0be2a51`; this rebuttal closes the Glossary discipline gap only)

---

## Cascaded Changes

ทุก fix Round 05 อยู่ใน scope ของ claim citations ตรง — ไม่มี hidden cascade เพิ่ม. Verify-sweep ของ Phase 4 consistency check (เห็น `claim-review-07 § At-a-Glance BT-002 propagation surface coverage` ที่ enumerate 7 cross-doc surfaces): grep ของ pre-fix patterns post-rebuttal:

| Pattern grepped | Pre-rebuttal hits in SD docs | Post-rebuttal hits in SD docs | Status |
|---|---|---|---|
| `~68 implementation` | 2 (`08` § 5 Total L312 + End-of-doc L320) | 0 | ✅ |
| `~11 tasks` | 1 (`08` § 5 P2 row L308) | 0 | ✅ |
| `IMPL-051` without strikethrough/CANCELLED-context | 1 (`08` § 5 P2 row L308) | 0 | ✅ |
| `Halted state semantic` Glossary entry | 1 (`02` § 8 L447) | 0 | ✅ |
| `HALT vs HALT_STABLE` Glossary entry | 1 (`02` § 8 L451) | 0 | ✅ |
| `Slot_J.mqh:180` (in SD docs only) | 2 (`03` § 1.5 L59 + `08` § 1.10 L130) | 0 | ✅ |
| `Slot_BI.mqh:212` (in SD docs only) | 2 (`03` § 1.5 L59 + `08` § 1.10 L130) | 0 | ✅ |
| `CircuitBreaker.CheckPingPong removed per BT-002` (in mermaid body) | 1 (`04` § 1.1 mermaid L46) | 0 | ✅ |
| `12 ADRs covering all major architectural decisions` (`02` footer) | 1 (L474) | 0 (replaced w/ "12 active + 2 superseded") | ✅ |
| `26 components` (`02` footer) | 1 (L474) | 0 (replaced w/ "25 components") | ✅ |
| Last-updated `2026-05-12 (BT-001` in BT-002-touched docs | 4 (`02/03/05/08`) | 0 (all bumped to 2026-05-17 BT-002) | ✅ |
| Last-updated `2026-05-02` in `04` (no BT-002 stamp) | 1 (`04` L5) | 0 (bumped to 2026-05-17 BT-002) | ✅ |

ทุก residual hit ของ patterns เหล่านี้อยู่ใน `docs/design-docs/claim-review-and-rebuttal/claim-review-*.md` (read-only per sd-defender SKILL ownership matrix) — preserved as review audit history per Phase 5 mechanical gate #9 clause (c) discipline.

**Language Rule compliance:** ทุก edit ใช้ bilingual code-switched style (Thai narrative + English tech terms). 5 header rewrites — Thai prose preserved (BT-002 cascade descriptor + surface enumeration + Prior tail). § 8 Glossary merged entry — Thai narrative preserved (cross-slot disable + persistence note in Thai), tech terms (HALTED / HALTED_STABLE / `state.json § ea_state` / `PortfolioState.TotalActivePositions()`) untranslated. § 9 Red Team Hand-off new row — Thai narrative for accepted-risk + mitigation context, English for ADR-013/014 / BR-3.6 / Slot_BI / OQ-6 / DEAL_REASON_EXPERT tech terms. ✅ Mechanical Thai-ratio check unnecessary — all new prose substantial Thai content.

**Anti-Duplication trail:** Round 03 cumulative-counter cascade (force_clear_count + throttled_alert_count) — untouched ✅ Pass. Round 04/05 Bucket A/B BT-001 framing — untouched + still semantically valid post-BT-002 ✅ Pass (verify per `claim-review-07 § Anti-Duplication sweep`). BT-002 reduces halt trigger sources 2→1 — design accepts trade-off explicitly via `05 § 2.5` BT-002 row + new § 9 audit row.

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (7/7) | สูงเหมือน Round 04 (11/11) — สะท้อนว่า BT-002 cascade ผ่าน first-pass commit ปิดได้แค่ primary surfaces; parallel-narrative sections (Phase Hint Summary, headers, ADR Digest, Glossary, mermaid body) เป็น "next-finer-granularity" sweep work ที่ R12→R24 chain เคย document. Reviewer scoping ถูกแม่นทุก claim — เป็น sweep-completion class, ไม่ใช่ defensive judgment call |
| Critical Fixes | 0 (none of the 7 = CRITICAL) | BT-002 cascade fundamentals (semantic invariants, halt trigger reduction 2→1, ADR amendments + audit history, API spec enum updates) landed coherently per Round 07 § At-a-Glance Net assessment ✅; 7 findings = completion + freshness + readability dimensions |
| ADRs Updated | 0 | ADR-010 amendment + ADR-013/014 superseded status flips landed ใน BT-002 commit `0be2a51` ก่อนหน้านี้แล้ว — Round 05 rebuttal = SD-narrative-only cascade closure |
| Net Improvement | +1 ADR Digest discoverability (013/014 audit trail enumerated), +1 cap-3 iter audit trail destination ใน `05 § 9`, −2 redundant Glossary entries → +1 canonical, −2 line-anchor brittleness sites → +1 grep-stable symbolic anchor pattern, −1 mermaid stranded annotation → +1 prose footer parallel to `02 § 4.2` removal pattern, 5 stale Last-updated headers → 5 BT-002 stamps with surface-list, 3 stale task counts → 3 BT-002-correct counts | สาย R-3 (NFR-1.1 acceptance signal blocker) ของ Open Risks ใน impl-plan ปิดทาง root cause ที่ BT-002 + post-BT-002 SD package narrative ตอนนี้ self-consistent |
| Remaining Gaps | 0 SD-internal | ภายใน SD scope: 0 finding คาดหวังจาก Round 06 re-review (mirror Round 03→04 + Round 05→06 clean-closure pattern). Cross-layer flagged sequencing: chained `/backtrack ba` (BR-3.6 + FR-6.6 demotion at BA layer per `backtrack-log.md § BT-002 Proposed change`) — intentional per backtrack-log § BT-002 (SD-first cascade ordering). Cross-layer flagged scope-out: 5 state-doc cites ของ `Slot_J.mqh:180` + `Slot_BI.mqh:212` ใน `docs/state/*` + `docs/state/impl-plan-claim-review-and-rebuttal/*` — Impl Planner / Engineer domain (sd-defender SKILL ห้ามแก้); recommend cascade-completion ที่ chained `/impl-plan-review` หรือ `/impl-task` next round |

## Recommendation

- [x] ✅ **Ready for next adversarial sweep (Round 08)** — all 7 Round 07 findings resolved with mechanical edits + cross-doc consistency verified. Expect 0 finding from Round 08 verify-only sweep (mirror Round 03→04 + Round 05→06 clean-closure pattern).
- [ ] 🔁 **Request Re-Review** — N/A; mechanical fixes only, no architectural decision change. Round 08 = standard verify-only re-review per BT-002 closure sequence.
- [ ] ⛔ **Needs Stakeholder Input** — N/A within SD scope. Cross-layer sequencing (chained `/backtrack ba` + state-doc cascade-completion) เป็น intentional per `backtrack-log.md § BT-002 Proposed change § Chained /backtrack ba` — operator-driven next steps, ไม่ block SD closure.

### Post-Rebuttal Sequencing (per `claim-review-07 § Recommended action sequence`)

1. ✅ Rebuttal Round 05 (this file) — closes Round 07 findings (7 accept / 0 partial / 0 reject)
2. Operator update `docs/state/overview.md` Design (SD) row → append `+ rebuttal-round-05 (post-BT-002 cascade-completion — 7 accept; ready for Round 08)`; Last Updated bump to 2026-05-17
3. Next: `/sd-review all` Round 08 → expect 0 finding verify-only (mirror Round 03→04 + Round 05→06 clean-closure pattern)
4. หลัง Round 08 clean → operator authorize chained `/backtrack ba` (BR-3.6 + FR-6.6 demotion at BA layer per `backtrack-log.md § BT-002 Proposed change § Chained /backtrack ba`)
5. หลัง BA cascade clean → operator populate `backtrack-log.md § BT-002 Resolution` cell + flip Status `🔄 Open` → `✅ Closed`; trim `docs/state/overview.md` "🔄 BACKTRACK — SD rework APPLIED" markers per Check 0.7 Direction A discipline
6. Optional parallel after Step 3: `/td-review all` re-validate (TD package may need BT-002 cascade — `backtrack-log.md § BT-002 Impacted phases — TD` flags `02-backend-design.md § 5.8` CCircuitBreaker skeleton DELETE + 10 cross-refs)
7. Cascade-completion ที่ impl layer: `/impl-plan-review` หรือ `/impl-task` next round to propagate symbol-anchor pattern from Claim 07.4 ลงไปยัง state-doc cites (5 sites in `docs/state/*` per Claim 07.4 out-of-scope notes)

> **End of Rebuttal Round 05** — 7 findings closed (0 CRITICAL / 2 HIGH / 3 MEDIUM / 2 LOW); BT-002 cascade-completion in SD narrative sections done; ready for Round 08 verify-only re-review.
