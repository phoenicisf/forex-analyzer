# System Design Rebuttal Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Claim Review** | `claim-review-05.md` |
| **Date** | 2026-05-12 |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |
| **Predecessor** | rebuttal-round-03 (2026-05-02; force_clear cumulative counter cascade closure) → claim-review-04 (2026-05-02; 0 finding verify-only — no rebuttal needed) |
| **Trigger** | BT-001 (2026-05-12) BA cascade-close ที่ `ba/rebuttal-round-04.md` + `ba/claim-review-05.md` (0 finding); claim-review-05 = first SD review post-BA-cascade-close → 11 findings = SD-side propagation gap |

> **Naming note:** Filename = `rebuttal-round-04.md` (next sequential rebuttal artifact after rebuttal-round-03; Round 04 review was verify-only 0 finding so no rebuttal). Cycle counter aligns with claim review numbering: claim-review-05 → rebuttal-round-04 (since Round 04 review skipped rebuttal generation).

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 11 |
| Partial | 0 |
| Rejected | 0 |

**Accept Rate:** 100% (11/11) — mirror BA Round 04 (11 accept / 0 reject) finding-spike pattern post-BT-001 cascade work-in-progress. Justified: every claim = direct SD-vs-BA contract conflict introduced by 2026-05-12 BA re-baseline + 0 SD propagation ก่อน Round 05 (per `backtrack-log.md § BT-001 Impacted phases — SD`).

**Files modified:**
- `docs/design-docs/02-high-level-architecture.md` (4 edits — § 1.2 NFR Trace L71, § 2 Pillar #1 L137, § 8 Glossary L441/L442, § 9 ADR Digest ADR-009 row L469, header L5)
- `docs/design-docs/03-deep-dive.md` (3 edits — § 1.3 Impl outline L43, § 1.5 Validation L57+L59, header L5)
- `docs/design-docs/05-security.md` (1 edit — § 6 Operational Risk row L205, header L5)
- `docs/design-docs/08-product-breakdown.md` (4 edits — § 1.10 IMPL-062 L129 + IMPL-063 L130, § 3 Phase Hint P4 L245, § 4 IMPL-062/063 metadata L293+L294, header L5)
- `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` (5 edits — Amendment header row, § Decision Validation L91, Validation step 3 L95, § Consequences L107, § Revisit-when L115)

**ADRs updated/created:** ADR-009 **amended** (Validation + Consequences + Revisit-when prose cascade-updated per BT-001; **decision arithmetic Option A unchanged**). No new ADR — semantic ของ all 12 ADRs preserved.

---

## Claim Responses

### Claim 05.1: IMPL-062 task description "rewrite (without G4 fixes) vs baseline → Bucket A drift" = pre-BT-001 framing

**Verdict:** Accept

**Rationale:** Reviewer ถูก — IMPL-062 task row บังคับ `#define DISABLE_G4_FIXES` build ที่ BA `03 § NFR-1.1 Verification` line 32 ห้ามชัด ("...ห้ามใช้ `#define DISABLE_G4_FIXES` build (Bucket A semantic ไม่รองรับ pre-G4 measurement หลัง BT-001)") + IMPL-062 ของตัวเอง (Run #2, 2026-05-12) พิสูจน์ empirical ว่า unmeetable (CircuitBreaker halt at sim 2021-01-14; drift ≈ 99.998%). Engineer ที่ read task description ตามตัวอักษร → ไป fail per Run #2 empirical = direct contract conflict ระดับ Phase 3T gate

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` § 1.10 Epic SD-QA (L129)
- What changed: IMPL-062 task row rewritten = "rewrite default build (G4 fixes ON, single-pass)" + cite BT-001 re-baseline + cite IMPL-062 Run #2 empirical evidence + explicit ห้ามใช้ DISABLE_G4_FIXES build
- Evidence (new text): *"IMPL-062 — Run regression: rewrite **default build (G4 fixes ON, single-pass)** vs baseline → Bucket A drift gate (NFR-1.1 ≤ 25%, G4 fix contribution included per BT-001 re-baseline 2026-05-12). ห้ามใช้ `#define DISABLE_G4_FIXES` build (Bucket A semantic ไม่รองรับ pre-G4 measurement post-BT-001; IMPL-062 Run #2 empirical แสดง CircuitBreaker halt at sim 2021-01-14 → drift ≈ 99.998% unmeetable) | M | acceptance signal | NFR-1.1 ถึง NFR-1.7 primary acceptance + BA `03 § NFR-1 Empirical Citation` | — |"*
- ADR updated: none (IMPL-062 = task description, ไม่ใช่ architectural decision)

---

### Claim 05.2: IMPL-063 task description "rewrite (with G4) vs baseline → Bucket B drift" + "drift > 25% re-decide" = wrong axis + stale gate

**Verdict:** Accept

**Rationale:** Reviewer ถูก — (a) Bucket B post-BT-001 = informational delta `rewrite-G4-ON − rewrite-G4-OFF` (relative ระหว่าง 2 rewrite builds), **ไม่ใช่ vs baseline**. IMPL-063 row บอก "rewrite (with G4) vs baseline" = wrong axis (= Bucket A measurement ที่ IMPL-062 ทำอยู่ → overlap + ซ้ำซ้อน). (b) "user re-decide trigger if drift > 25%" = stale gate ที่ BA `03 § NFR-1.8 Failure trigger` ลบ ("Removed BT-001 2026-05-12"); NFR-1.8 informational only, ไม่มี threshold

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` § 1.10 (L130) + § 4 Per-Task Metadata (L294)
- What changed:
  - § 1.10 L130: IMPL-063 row rewritten = "Measure Bucket B informational delta `rewrite-G4-ON − rewrite-G4-OFF`" + "No acceptance gate — informational only per NFR-1.8 (Should priority, BT-001 re-classification)" + cite IMPL-062 Run #2 evidence
  - § 4 L294: Risk **high → medium** (informational ไม่ใช่ acceptance gate); Arch rationale changed from "user re-decide trigger if drift > 25%" → "informational only (no gate, no re-decide trigger; sign + magnitude ของ G4 fix contribution ถ้า partial G4-OFF window measurable post-BT-001)"
- Evidence (new text L130): *"IMPL-063 — Measure Bucket B **informational delta** `rewrite-G4-ON − rewrite-G4-OFF` (sign + magnitude ของ G4 fix contribution — ADR-009 BI SL + BR-7.2 J magic). Record เฉพาะ partial pre-CircuitBreaker window ของ `#define DISABLE_G4_FIXES` build ที่ measurable (per BT-001 + IMPL-062 Run #2 empirical แสดง full-window unmeetable). **No acceptance gate** — informational only per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12) | M | G4 fix observability | NFR-1.8 informational delta | ADR-009 |"*

---

### Claim 05.3: SD Glossary "Bucket A drift" + "Bucket B drift" direct conflict กับ BA Glossary post-rebuttal-04

**Verdict:** Accept

**Rationale:** Reviewer ถูก — SD Glossary L441/L442 บอก "drift จาก code rewrite ที่ไม่ตั้งใจ" / "separate budget, document แยก"; BA Glossary `01 § 8` L208/L209 บอก "Includes G4 fix contribution" / "Informational delta, no acceptance gate". 2-way Glossary conflict ที่ CLAUDE.md § Glossary "Vocabulary Lookup" rule ห้ามชัด — SD ต้อง mirror BA truth (authoritative source per `02 § 1 ⚠️ Authoritative source`)

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 8 Glossary (L441/L442)
- What changed: 2 glossary cells rewritten verbatim เพื่อ mirror BA `01 § 8` L208/L209 post-rebuttal-04
- Evidence (new text L441): *"| **Bucket A drift** | Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). **Includes** intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — ดู `ba/03 § NFR-1 Empirical Citation`) |"*
- Evidence (new text L442): *"| **Bucket B drift** | Informational delta `rewrite-G4-ON − rewrite-G4-OFF` ที่บันทึก sign + magnitude ของ intentional G4 fix contribution — **no acceptance gate** per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12). `DISABLE_G4_FIXES` build อาจ measurable เฉพาะ partial pre-CircuitBreaker window |"*

---

### Claim 05.4: ADR-009 § Validation + § Consequences + § Revisit-when ใช้ "Bucket B drift > 25%" gate ที่ BT-001 ยกเลิก

**Verdict:** Accept

**Rationale:** Reviewer ถูก — ADR-009 ระบุ 4 sites pre-BT-001 framing: (a) L91 heading "Validation (NFR-1.8 bucket B)" frame validation = Bucket B scope ทั้งหมด, (b) L95 step 3 "Bucket B drift documented แยก: PF ไม่ลด, Max DD% ไม่เพิ่ม" — PF/DD ตอนนี้ portfolio-level Bucket A, (c) L107 "Bucket B drift estimate (per `trading-baseline.md § Deviation Budget`)" — Deviation Budget framing deprecated, (d) L115 Revisit-when "Bucket B drift > 25% Net Profit re-decide" — stale gate. ADR amendment required per `workflow.md § ADR Discipline` (decision arithmetic Option A unchanged → amendment, ไม่ใช่ new ADR)

**Changes:**
- File: `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` — 5 sites
  - Amendment row inserted ใน header table (Status row ต่อท้าย Goal trace)
  - § Decision Validation heading (L91): "(NFR-1.8 bucket B)" → "(NFR-1.1 Bucket A + NFR-1.8 informational delta, BT-001 re-baseline 2026-05-12)"
  - § Decision Validation step 3 (L95): "Bucket B drift documented แยก: PF ไม่ลด..." → "Bucket A measurement (rewrite-G4-ON build, NFR-1.1 ≤ 25%) absorbs BI SL fix drift; portfolio-level PF + Max DD gate at portfolio level. NFR-1.8 informational delta record sign + magnitude เฉพาะ partial pre-CircuitBreaker window measurable"
  - § Consequences (L107): "Bucket B drift estimate (per `trading-baseline.md § Deviation Budget`)" → "Bucket A measurement absorbs BI SL fix per NFR-1.1 (rewrite-G4-ON vs baseline); informational delta estimate (per BA `03 § NFR-1 Empirical Citation` post-BT-001 2026-05-12)"
  - § Revisit-when (L115): "QA regression แสดง bucket B drift > 25% Net Profit (= bug fix 'ตัดได้กำไร')" → "ถ้า QA regression แสดง Bucket A (rewrite-G4-ON vs baseline) drift > 25% Net Profit"
- Evidence (Amendment row): *"| **Amendment** | 2026-05-12 — Validation + Consequences + Revisit-when sections cascade-updated per BT-001 (BA NFR-1.1 + NFR-1.8 re-baseline 2026-05-12) — Bucket B framing demoted to informational delta, Revisit-when trigger re-anchored to Bucket A (rewrite-G4-ON build). Decision arithmetic (Option A — earliest B parent SL distance + Bollinger fallback) unchanged |"*
- ADR amended (no new ADR): ADR-009 status updated → "Accepted (Amended 2026-05-12 per BT-001)" via Amendment row + § 9 ADR Digest cascade in Claim 05.5

---

### Claim 05.5: `02 § 9` ADR Digest row ADR-009 Trade-off + Revisit-when cells stale

**Verdict:** Accept

**Rationale:** Reviewer ถูก — ADR Digest = single-page Tech Lead summary; stale row ที่ "Bucket B drift expected: PF stable..." + "Bucket B drift > 25% re-decide" บิดเบือน mental model ก่อน drill ลง ADR-009 file. Cascade ของ Claim 05.4 — แม้ ADR file ปรับ ถ้า Digest row ไม่ update reader infer stale gate from quick-scan path

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest (L469)
- What changed: ADR-009 row 3 cells rewritten — Status cell append "(Amended 2026-05-12 per BT-001)"; Trade-off cell re-anchored to Bucket A absorption + informational delta NFR-1.8; Revisit-when re-anchored to Bucket A gate
- Evidence (new text): *"| ADR-009 | BI SL inheritance pip arithmetic | Accepted (Amended 2026-05-12 per BT-001) | Earliest B parent SL distance + Bollinger fallback | Bucket A drift absorbed (NFR-1.1 rewrite-G4-ON build, G4 fix contribution included): PF stable, Max DD% ลด, Net Profit ขึ้น/ลง; informational delta per NFR-1.8 (BT-001 2026-05-12) | Bucket A (rewrite-G4-ON vs baseline) drift > 25% Net Profit (re-decide) | [009](../adr/009-bi-sl-inheritance-pip-arithmetic.md) |"*

---

### Claim 05.6: NFR Traceability "bucket B drift via ADR-009" implies Bucket B = ADR-009 deliverable budget

**Verdict:** Accept

**Rationale:** Reviewer ถูก — phrase "bucket B drift via ADR-009" บอกว่า ADR-009 deliverable = Bucket B drift (= separate-budget mental model). Post-BT-001 ADR-009 BI SL fix contribution วัดผ่าน Bucket A (NFR-1.1 rewrite-G4-ON build); Bucket B = informational measurement vehicle, ไม่ใช่ deliverable ของ ADR ใด ๆ. QA Phase 3T ที่ scan NFR Trace ก่อน design test → infer redundant 2-bucket measurement = overlap กับ Claim 05.1/05.2

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 1.2 NFR Traceability (L71)
- What changed: mapping cell rewritten — "+ bucket B drift via ADR-009" → "G4 fix (ADR-009 BI SL + BR-7.2 J magic) contribution absorbed via NFR-1.1 Bucket A measurement (rewrite-G4-ON default build, BT-001 2026-05-12); NFR-1.8 informational delta optional"
- Evidence (new text): *"| NFR-1.1 ถึง NFR-1.8 | Behavioral parity (regression contract) | architecture preserves slot/RiskManager/cross-slot logic 1:1; G4 fix (ADR-009 BI SL + BR-7.2 J magic) contribution absorbed via NFR-1.1 Bucket A measurement (rewrite-G4-ON default build, BT-001 2026-05-12); NFR-1.8 informational delta optional |"*

---

### Claim 05.7: `03 § 1` Challenge 1 Implementation outline + Validation 3 sites "Bucket B documented per case" stale

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Challenge 1 = primary "behavioral parity pin" ที่ TD/Impl/QA อ่าน. 3 sites stale framing (L43 outline "Bucket B documentation per case", L57 Bucket A target ไม่ระบุ rewrite-G4-ON build clarification, L59 Bucket B documented separately + PF/DD pre-BT-001 mental model). Mirror BA `04 § BR-7.1/7.2 Validation hints` post-rebuttal-04 ("portfolio-level drift roll up via NFR-1.1 Bucket A; NFR-1.8 informational delta optional")

**Changes:**
- File: `docs/design-docs/03-deep-dive.md` § 1.3 Implementation outline (L43) + § 1.5 Validation (L57+L59)
- What changed (L43): "Bug-fix bucket B documentation per case" → "Bucket A measurement (rewrite-G4-ON build, single-pass per BT-001) absorbs G4 fix contribution; NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable ก่อน CircuitBreaker BR-3.6 trigger per IMPL-062 Run #2)"
- What changed (L57): Bucket A target appended "บน rewrite default build (G4 fixes ON, single-pass per BT-001 2026-05-12, G4 fix contribution included)"
- What changed (L59): Bucket B re-framed = "Informational delta (NFR-1.8) `rewrite-G4-ON − rewrite-G4-OFF` — sign + magnitude... ; **no acceptance gate** (Should priority post-BT-001 2026-05-12). Portfolio-level PF (NFR-1.2 ≤ 0.2 drop) + Max DD (NFR-1.5 ≤ +10pp) gate via Bucket A measurement"

---

### Claim 05.8: `05 § 6` Operational Risk detection "Bucket B > 25%" stale gate

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Operational Risk row detection threshold = pre-BT-001 stale gate (Bucket B post-BT-001 ไม่มี threshold + คำว่า "> 25% Net Profit" axis ผิด — เดิม 25% เป็น Bucket A gate). Red Team/QA scan ก่อน design monitoring rule → false-positive หรือ never-trigger

**Changes:**
- File: `docs/design-docs/05-security.md` § 6 Operational Risks (L205)
- What changed: detection cell re-anchored to NFR-1.1 Bucket A gate (rewrite-G4-ON build); mitigation cell ระบุ NFR-1.8 informational delta optional + journal `signal_context` investigation
- Evidence (new text): *"| Bug-fix changes (ADR-009 BI SL, BR-7.2 J magic) cut profitable trades unexpectedly | NFR-1.1 Bucket A drift > 25% Net Profit บน rewrite-G4-ON build (G4 fix contribution included per BT-001 2026-05-12) | NFR-1.1 Bucket A gate; NFR-1.8 informational delta sign + magnitude record ถ้า partial G4-OFF window measurable (per BA `03 § NFR-1 Empirical Citation`) — user investigates journal `signal_context` ของ BI/J entries หากตี gate |"*

---

### Claim 05.9: `08 § 3` P4 Phase Hint rationale "baseline vs rewrite (with + without G4)" stale 2-pass

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Phase Hint rationale = Impl Planner advisory input. "baseline vs rewrite (with + without G4)" = exact 2-pass framing ที่ BA `04 § BR-9.5` rebuttal-04 rewrite เป็น single-pass; Impl Planner ที่ read literal "with + without G4" → schedule dual headless test config สำหรับ G4-OFF run ที่ IMPL-062 Run #2 พิสูจน์ unmeetable (wasted spike + scope drift)

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` § 3 Suggested P4 (L245)
- What changed: P4 bullet rationale rewritten = single-pass on rewrite-G4-ON build per NFR-1.1 Bucket A + IMPL-063 informational delta
- Evidence (new text): *"- **IMPL-061..068** (QA validation suite) — reason: regression after E2-E8 complete; **single-pass measurement บน rewrite default build (G4 fixes ON)** per NFR-1.1 Bucket A (BT-001 re-baseline 2026-05-12); IMPL-063 informational delta `rewrite-G4-ON − rewrite-G4-OFF` (NFR-1.8 no-gate) ถ้า partial G4-OFF window measurable ก่อน CircuitBreaker BR-3.6 trigger"*

---

### Claim 05.10: `02 § 2` Architectural Pillar #1 ไม่ระบุ "rewrite-G4-ON build" clarification post-BT-001

**Verdict:** Accept

**Rationale:** Reviewer ถูก — literal 25% Bucket A threshold value ถูก post-BT-001 แต่ phrase "Bucket A" ใน Pillar #1 ใน isolation = ambiguous. Reader ใหม่ post-2026-05-12 อ่าน pillar ที่ ไม่มี BT-001 cite → mental model build จาก pre-BT-001 Bucket A definition (separate-budget). Readability + audit-trail enhancement — LOW severity แต่ accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 2 Architectural Pillars (L137)
- What changed: append BT-001 clarification clause inline กับ Bucket A phrase
- Evidence (new text): *"1. **Behavioral parity (G3)** — 5-yr backtest 2021-2025 EURUSD H4 บน FBS-Real ต้องไม่ deviate Net Profit > 25% (Bucket A — **rewrite default build with G4 fixes ON, single-pass measurement per BT-001 2026-05-12**; G4 fix contribution included) จาก baseline $24.27M; PF ≥ 8.76; Max Equity DD% ≤ 16.39%. ทุก architecture decision ที่กระทบ slot logic ต้อง defendable ผ่านมุมนี้"*

---

### Claim 05.11: Last-updated headers ไม่ bump despite BT-001 cascade pending

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Last-updated metadata stale = misleading audit trail. Round 04 → Round 05 transition จะดูเหมือน "SD ไม่กระทบ" ขณะที่ 11 sites stale. Bump pro forma หลัง content fixes ของ Claims 05.1-05.10 ลงครบ

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` L5 header
- File: `docs/design-docs/03-deep-dive.md` L5 header
- File: `docs/design-docs/05-security.md` L5 header
- File: `docs/design-docs/08-product-breakdown.md` L5 header
- File: `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` Amendment row (covered ใน Claim 05.4)
- What changed: 4 SD headers bumped from `2026-05-02` → `2026-05-12 (BT-001 cascade — ...)` พร้อม inline section pointer ของ edits ที่ landed
- Evidence (02 L5): *"> **Last updated:** 2026-05-12 (BT-001 cascade — Bucket A/B propagation: Glossary § 8 + ADR Digest § 9 ADR-009 row + NFR Traceability § 1.2 NFR-1.x row + Pillar § 2 #1 clarification)"*
- Evidence (03 L5): *"> **Last updated:** 2026-05-12 (BT-001 cascade — Challenge 1 § 1.3 Impl outline row + § 1.5 Bucket A/B validation re-framed to rewrite-G4-ON single-pass per BT-001 re-baseline 2026-05-12)"*
- Evidence (05 L5): *"> **Last updated:** 2026-05-12 (BT-001 cascade — § 6 Operational Risks bug-fix row detection threshold re-anchored to Bucket A rewrite-G4-ON gate per BT-001 re-baseline 2026-05-12)"*
- Evidence (08 L5): *"> **Last updated:** 2026-05-12 (BT-001 cascade — IMPL-062/063 task description § 1.10 + Phase Hint P4 rationale § 3 + per-task metadata § 4 re-framed to rewrite-G4-ON single-pass per BT-001 re-baseline 2026-05-12)"*

---

## Cascaded Changes

ไม่มี cascade beyond Claims 05.1-05.11 — reviewer enumerate 11 sites ครบ. Phase 4 tree-wide grep verification:

- `grep "Bucket B drift > 25\|re-decide if drift > 25\|user re-decide trigger\|without G4 fixes\|with G4 fixes — ADR-009\|baseline vs rewrite (with + without\|documented separately per fix\|documented แยก\|separate budget\|bucket B drift via ADR"` against `docs/design-docs/ + docs/adr/` → **0 hits** (all stale patterns purged)
- Remaining "Bucket A drift" generic references survived (semantically valid post-BT-001 because Bucket A now includes G4 fix contribution):
  - `03-deep-dive.md` L11 TL;DR, L19 Problem statement, L308 Failure mode, L319 Bucket A budget
  - `05-security.md` L267 Pending force-clear
  - `07-future-evolution.md` L120 QA regression bullet
  - `adr/008-pending-state-safety-force-clear.md` L22 / L71 / L83 force-clear drift mentions
  - All correctly use "Bucket A drift" to mean "any rewrite deviation > 25%" — semantic preserved
- Schedule-leakage check: clean — "2026-05-12" = BT-001 cite (audit-trail metadata), "single-pass" = measurement methodology not delivery time
- Language Rule check: bilingual code-switched style preserved across 5 modified files (Thai narrative + English tech terms; tables remain table-heavy English consistent with pre-fix baseline)

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (11/11) | 🟠 warning range — justified โดย post-BT-001 cascade work-in-progress (BA-only re-baseline 2026-05-12, SD package 0 propagation ก่อน Round 05); mirror BA Round 04 finding-spike pattern. Not defensive bias |
| Critical Fixes | 3 (Claims 05.1, 05.2, 05.3) | direct contract conflict กับ BA truth post-rebuttal-04; reject = defending bad design |
| ADRs Amended | 1 (ADR-009) | Validation + Consequences + Revisit-when prose cascade; decision arithmetic Option A unchanged |
| Net Improvement | สูง — SD package now mirror BA single-voice ใน 11 sites; vocabulary lookup discipline (CLAUDE.md § Glossary) restored — Tech Lead/Impl Planner/QA Phase 3T สามารถ scan SD top-down (Pillar → Glossary → NFR Trace → ADR Digest → ADR-009 → 03 Challenge 1 → 05 Operational Risk → 08 IMPL-062/063 + Phase Hint) แล้วได้ post-BT-001 vocabulary consistently | |
| Remaining Gaps | 0 items | Phase 4 sweep 0 hit; downstream chain (TD `02 § 13` Strategy Tester audit contract, QA Plan, Impl Plan IMPL-062/063 rows) ready for `/td-review` + `/qa-review` + `/impl-plan-review` |

## Recommendation

- [x] ✅ **Ready for Implementation Handoff** — Round 05 fix ครบ; SD package internally consistent กับ BA package post-BT-001; Tech Lead drill path top-to-bottom verified; ADR-009 amendment landed per `workflow.md § ADR Discipline`; no new contradictions
- [ ] 🔁 **Request Re-Review** — N/A (mirror BA Round 04 → Round 05 clean-closure trajectory expected: re-run `/sd-review all` Round 06 → 0 finding)
- [ ] ⛔ **Needs Stakeholder Input** — N/A

### Next steps per `claim-review-05 § Recommended action sequence`

1. ✅ This rebuttal (rebuttal-round-04.md) closes 11 findings
2. Re-run **`/sd-review all`** as Round 06 → expect 0 finding (clean closure)
3. Update `docs/state/overview.md` Phase Status row **Design (SD)**: append `+ Round 06 (post-BT-001 cascade clean)` after Round 06 pass
4. Proceed `/td-review all` + `/qa-review all` per BT-001 downstream chain (`ba/claim-review-05.md § Recommended action sequence`) — TD `02 § 13` Strategy Tester audit contract + QA Plan ต้อง verify Bucket A measurement = single-pass G4-ON (ไม่ใช่ 2-pass with/without G4)
5. After SD Round 06 + downstream pass → close BT-001 entry ใน `backtrack-log.md § BT-001` (Resolution column populated)

> **End of Round 04 rebuttal** — 11 cascade fixes landed across 5 files (4 SD docs + ADR-009); BA-SD voice unified post-BT-001 2026-05-12; ADR-009 amended (decision arithmetic preserved); ready for Round 06 verify-only review
