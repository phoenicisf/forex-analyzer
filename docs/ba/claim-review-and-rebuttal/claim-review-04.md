# BA Claim Review Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Target** | `all` (5 BA docs post-BT-001 partial rework — focus on Bucket A/B propagation gaps) |
| **Date** | 2026-05-12 |
| **Reviewer** | BA Reviewer (Adversarial Consultant) |
| **SKILLs** | business-analyst, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** 11 ( 🔴 CRITICAL 3 / 🟠 HIGH 3 / 🟡 MEDIUM 4 / 🔵 LOW 1 )

**Trigger:** BT-001 (2026-05-12) redefined Bucket A semantic (rewrite-G4-OFF → rewrite-G4-ON vs baseline) + demoted Bucket B (Must → Should informational delta, no acceptance gate). Rework ใน `03` ลึกและ self-consistent — แต่ **cascade propagation ไป 01/02/04 ไม่ได้ทำ**: glossary, goal KPI, ACs, BR invariants, BR rule-type legend ยังคงเขียน semantic แบบเดิม (Bucket B = "separate budget", QA "2 รอบ with/without G4 fixes", drift "ไม่นับใน Bucket A"). ผลคือ NFR-1.1/1.8 ใน `03` กับ FR-3.3/3.4 + BR-7 + BR-9.5 + Glossary ใน 01/02/04 พูดคนละเรื่องกัน — QA Phase 3T จะ design gate ผิดถ้าอ่าน FR/BR ตามตัวอักษร.

### Top 3 to Fix First
1. **Claim 04.1** 🔴 — BR-9.5 Behavioral parity invariant "(a) without G4 fixes" round ถูก BT-001 ห้ามชัด — invariant doc ขัดแย้งกับ NFR-1.1 Verification — `04 § BR-9.5` line 530
2. **Claim 04.2** 🔴 — AC-3.3.3 "ไม่นับใน 25% pattern parity bucket A" สวน Bucket A re-definition (Bucket A ตอนนี้ include G4 fixes) — `02 § FR-3.3` line 300
3. **Claim 04.3** 🔴 — AC-3.4.3 "drift ของ J + F slot นับใน bucket B (intentional fix)" framing Bucket B เป็น drift-budget category ผิด BT-001 (informational only) — `02 § FR-3.4` line 321

### Verdict
- [ ] ✅ **Ready for Architecture Handoff**
- [x] ⚠️ **Needs Rebuttal Round** — 3 CRITICAL + 3 HIGH = BA package internally inconsistent post-BT-001; run `/ba-rebuttal claim-review-04.md`
- [ ] ⛔ **Immediate Attention**

ภาพรวม Round 04: BT-001 rework ใน `03` ครบ + empirical citation block solid — แต่ **partial rework** เท่านั้น. BA package ตอนนี้มี 2 voice ขัดกันใน Bucket A/B semantic: NFR contract (`03`) บอกอย่างหนึ่ง, FR ACs + BR invariants + Glossary (`01/02/04`) บอกอย่างเดิม. Reviewer round-prior (Round 03) ปิด clean **ก่อน** BT-001 — ดังนั้น findings round นี้ทั้งหมดเกิดจาก BT-001 cascade gap, ไม่ใช่ duplicate ของ Round 01-02.

---

## BA Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Problem Statement | ✅ Pass | `01 § 2` ไม่ได้แตะใน BT-001 |
| 2 | Success Metrics | ⚠️ Finding 04.5 | G4 KPI row `01 § 3` ยังเขียน "bucket B ของ regression budget" |
| 3 | Scope Boundaries | ✅ Pass | `01 § 5/6` ไม่กระทบ |
| 4 | User Story Quality | ✅ Pass | Story format ไม่กระทบ (G4 stories actor/goal/benefit ไม่เปลี่ยน) |
| 5 | Acceptance Criteria | ⚠️ Findings 04.2, 04.3, 04.7 | AC-3.3.3 / AC-3.4.3 / FR-3.3 Why ทั้งหมดใช้ pre-BT-001 framing |
| 6 | MoSCoW Prioritization | ⚠️ Finding 04.10 | NFR-1.8 Must→Should ถูก reflect ใน `03` แล้ว แต่ `overview.md` ยัง "M=26 S=4" |
| 7 | NFR Measurability | ✅ Pass | NFR-1.1 / NFR-1.8 ตอนนี้ measurable ตามการ redefine |
| 8 | NFR Completeness | ✅ Pass | NFR-1.x summary table ครบ |
| 9 | Business Rules | ⚠️ Findings 04.1, 04.6, 04.8 | BR-9.5 invariant + BR-7 intro + BR-7.1/7.2 Validation hints ยังใช้ pre-BT-001 framing |
| 10 | User Flow Coverage | ✅ Pass | `05` ไม่อ้าง Bucket A/B โดยตรง — pass-through |
| 11 | Traceability | ✅ Pass | FR↔NFR trace ยังครบ; แค่ wording trace stale |
| 12 | Assumption Marking | ✅ Pass | ไม่กระทบ |
| 13 | Tech-Agnostic | ✅ Pass | BT-001 rework เป็น semantic — no tech leak ใหม่ |
| 14 | Cross-Doc Consistency | ⚠️ Findings 04.4, 04.9 | Glossary `01 § 8` + reference table `01 § 9` stale Bucket A/B definitions |
| 15 | Edge Cases | ✅ Pass | Empirical citation block ใน `03` ครอบคลุม edge case CircuitBreaker→HALTED |
| 16 | Open Questions Distribution | ✅ Pass | ไม่มี OQ ใหม่จาก BT-001; archive trail ครบ (backtrack-log.md) |
| 17 | Ambiguity | ⚠️ Finding 04.2/04.3 (covered) | AC-3.3.3 / AC-3.4.3 ambiguity ระหว่าง 2 voice = dev 2 คนจะตีความต่างกัน |
| 18 | Conflict Detection | ⚠️ Finding 04.1 (covered) | BR-9.5 invariant vs NFR-1.1 Verification = direct conflict |
| 19 | Readability / Reader-Empathy | ✅ Pass | TL;DR / Why-line scaffold preserved; BT-001 didn't break readability |
| 20 | Language Rule Compliance | ✅ Pass | TL;DR + section openers + AC narrative คงเป็นไทย; actor/entity/AC keyword English; bilingual ratio ไม่ regress (mechanical char ratio ต่ำเหมือนเดิมเพราะ Thai glyph density — qualitative pass) |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

---

### Claim 04.1: 🔴 CRITICAL — BR-9.5 Behavioral parity invariant ขัดแย้งกับ NFR-1.1 Verification (BT-001)

**Location:** `04-business-rules.md` § BR-9.5 (line 530)

**Problem:**
BR-9.5 ระบุ invariant verification protocol ว่า:

> *"Backtest 2021-2025 EURUSD H4 ของ rewrite อยู่ใน regression budget (NFR-1.1 ถึง NFR-1.7) — ตรวจ 2 รอบ: (a) without G4 fixes (verify Bucket A only), (b) with G4 fixes (Bucket A + Bucket B documented)"*

แต่ `03 § NFR-1.1` Verification (line 32) ระบุชัดเจน:

> *"...ห้ามใช้ `#define DISABLE_G4_FIXES` build (Bucket A semantic ไม่รองรับ pre-G4 measurement หลัง BT-001)"*

และ `03 § NFR-1.8` Failure trigger (line 132) ระบุ empirical evidence ว่า `DISABLE_G4_FIXES` build "ไม่สามารถรัน end-to-end concurrently กับ rewrite's 16-active-slot architecture ได้โดยไม่ trigger CircuitBreaker BR-3.6 → HALTED ก่อน complete window".

BR-9.5 round (a) "without G4 fixes" round = **BT-001 ห้ามชัด + structurally unmeetable per Run #2 empirical**.

**Why this matters:**
BR-9.x = invariant ที่ต้อง true ตลอด (per `04 § 10` intro line 502). QA Phase 3T agent อ่าน BR-9.5 จะ design regression gate ผิด: รัน 2-pass with/without G4 fixes แล้ว fail เพราะ G4-OFF build halt ก่อนจบ window (Run #2 empirical). หรือ Architect (Phase 1B) อ่าน BR-9.5 จะ infer ว่าต้อง maintain `DISABLE_G4_FIXES` compile flag เป็น first-class build target — ขัด BT-001 explicit guidance. Invariant ที่ contradict NFR contract = block downstream design.

**Minimum acceptable fix:**
Rewrite BR-9.5 invariant clause:

```
**Invariant:** Backtest 2021-2025 EURUSD H4 ของ rewrite default build (G4 fixes ON) อยู่ใน regression budget (NFR-1.1 ถึง NFR-1.7) — single-pass measurement บน rewrite-G4-ON build เท่านั้น. Bucket B (NFR-1.8) = informational delta ที่ record sign+magnitude ถ้า DISABLE_G4_FIXES build รัน partial window ได้ก่อน CircuitBreaker BR-3.6 trigger; ไม่ใช่ acceptance gate.
- **Source:** `trading-baseline.md`, NFR-1.x, BT-001 (2026-05-12) re-baseline
```

**Effort:** Low (single paragraph rewrite + cite BT-001 reference)

---

### Claim 04.2: 🔴 CRITICAL — AC-3.3.3 framing "ไม่นับใน Bucket A" ขัด BT-001 (Bucket A ตอนนี้ include G4 fixes)

**Location:** `02-functional-requirements.md` § FR-3.3 AC-3.3.3 (line 298-300)

**Problem:**
AC-3.3.3 เขียนว่า:

> *"Given QA regression run พร้อม bug fix
> When เปรียบเทียบ Net Profit + PF + DD กับ baseline
> Then bucket B drift documented (ไม่นับใน 25% pattern parity bucket A); PF ลดลง ≤ 0.2 จุด, Max DD% ไม่เพิ่ม"*

หลัง BT-001:
- **Bucket A** = `rewrite-G4-ON vs baseline` (G4 fixes ON, **G4 fix contribution included**)
- **Bucket B** = informational delta `rewrite-G4-ON − rewrite-G4-OFF`, **ไม่ใช่ acceptance gate**

AC clause "ไม่นับใน 25% pattern parity bucket A" = **ผิด** เพราะ G4 fix contribution **อยู่ใน** Bucket A measurement หลัง BT-001 (default build = G4-ON). Clause "bucket B drift documented" = **stale framing** ที่ implies Bucket B เป็น drift category ที่มี budget — แต่ NFR-1.8 ตอนนี้ Should/informational only (`03` line 130-131: *"informational delta...no pass/fail threshold"*).

**Why this matters:**
AC คือ testable contract — QA agent อ่าน AC-3.3.3 ตามตัวอักษรแล้วจะ design 2 measurements (Bucket A excluding G4 + Bucket B with G4) ตาม pre-BT-001 contract. Dev 2 คน implement BI SL fix แล้ว validate AC ผ่าน journal field check (3.3.2) — แต่ stuck ที่ 3.3.3 เพราะ "bucket B drift documented" requires measurement vehicle (DISABLE_G4_FIXES build) ที่ BT-001 ห้าม. Direct internal contradiction = AC ไม่ testable.

**Minimum acceptable fix:**
Rewrite AC-3.3.3 paragraph:

```
- **AC-3.3.3:** Given QA regression run บน rewrite default build (G4 fixes ON)
    When เปรียบเทียบ Net Profit + PF + DD กับ baseline
    Then NFR-1.1 Bucket A gate ใช้ได้ (|ΔNet Profit| ≤ 25% บน rewrite-G4-ON build); NFR-1.2 PF ลดลง ≤ 0.2 จุด; NFR-1.5 Max Equity DD% ไม่เพิ่ม > +10pp; NFR-1.8 informational delta (G4-ON − G4-OFF) บันทึก sign+magnitude ถ้า partial G4-OFF window measurable ก่อน CircuitBreaker trigger (BT-001 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`)
```

**Effort:** Low (AC paragraph rewrite + cross-ref BT-001 evidence anchor)

---

### Claim 04.3: 🔴 CRITICAL — AC-3.4.3 "drift ของ J + F นับใน bucket B (intentional fix)" framing Bucket B ผิด BT-001

**Location:** `02-functional-requirements.md` § FR-3.4 AC-3.4.3 (line 319-321)

**Problem:**
AC-3.4.3 เขียนว่า:

> *"Given regression result
> When เปรียบเทียบ J slot trade count + win rate + Net Profit กับ baseline
> Then drift ของ J + F slot นับใน bucket B (intentional fix); portfolio-level: PF ไม่ลด, Max DD% ไม่เพิ่ม"*

หลัง BT-001:
- Bucket B = **informational delta** (no gate, Should priority)
- "drift นับใน bucket B (intentional fix)" = pre-BT-001 budget framing
- Per-slot J trade count drift ตอนนี้อยู่ใต้ **NFR-1.6** (per-slot ±15% / >30% / ±2 absolute fallback), measure ที่ rewrite-G4-ON build เดียวกัน
- Portfolio-level PF/DD gates อยู่ใต้ NFR-1.2 + NFR-1.5 บน rewrite-G4-ON build (BT-001 line 131)

**Why this matters:**
AC-3.4.3 testability layer breaks เหมือน 04.2: QA จะหาวิธี isolate "J + F drift in bucket B" ที่ไม่ตรงกับ NFR-1.6 per-slot framework. ExtraTakeProfit_J magic fix = single intentional change ที่ contribute เข้า Bucket A overall measurement (since Bucket A = G4-ON default). Per-slot J distribution check belongs to NFR-1.6. AC restate Bucket B framing ผิด layer.

**Minimum acceptable fix:**
Rewrite AC-3.4.3 paragraph:

```
- **AC-3.4.3:** Given regression result บน rewrite default build (G4 fixes ON)
    When เปรียบเทียบ J slot + F slot trade count + win rate + Net Profit กับ baseline
    Then per-slot drift J/F อยู่ใน NFR-1.6 tolerance (±15% / >30% flag / ±2 absolute ถ้า baseline < 5 trades); portfolio-level NFR-1.2 PF ไม่ลด > 0.2 จุด; NFR-1.5 Max DD% ไม่เพิ่ม > +10pp; NFR-1.8 informational delta (G4-ON − G4-OFF) บันทึก J/F contribution sign ถ้า partial G4-OFF window measurable (BT-001 2026-05-12)
```

**Effort:** Low (AC paragraph rewrite + NFR layer cross-ref)

---

### 🟠 HIGH

---

### Claim 04.4: 🟠 HIGH — Glossary "Bucket A drift" / "Bucket B drift" / "Bug-fix bucket" definitions stale ทั้ง 3 entries

**Location:** `01-project-brief.md` § 8 Glossary (lines 208, 209, 216)

**Problem:**
Glossary entries 3 รายการต่อเนื่องกันยังเขียน pre-BT-001 semantic:

- Line 208: *"**Bucket A drift** — Behavioral deviation ที่เกิดจาก code rewrite ไม่ตั้งใจ — ต้อง ≤ 25% Net Profit (regression contract)"* — definition "unintended rewrite drift" = pre-BT-001 framing ที่ separate Bucket A จาก G4 fix contribution; post-BT-001 Bucket A includes G4 fixes
- Line 209: *"**Bucket B drift** — Behavioral deviation ที่เกิดจาก intentional bug fix (BI SL + Magic-J) — **separate budget**, document แยกแต่ละ case"* — phrase "separate budget" ขัด BT-001 (NFR-1.8 ตอนนี้ informational, ไม่มี budget)
- Line 216: *"**Bug-fix bucket** — Regression accounting category — ดู `trading-baseline.md § Validation Strategy → Deviation Budget — 2 Buckets`"* — entry name + cross-ref ยังคง "2-bucket deviation budget" framing

**Why this matters:**
Glossary `01 § 8` = single source of truth สำหรับ BA package terminology (per `04 § Reads:` ที่ระบุ "Reads `01-project-brief.md (glossary)`"). Architect / TD / QA อ่าน BR-7.x หรือ NFR-1.x แล้ว lookup glossary จะได้ stale definitions → BT-001 cascade ไม่ jam ผ่าน docs ที่อ้าง Glossary. Glossary stale = single point of corruption ที่ contaminate ทุก reader.

**Minimum acceptable fix:**
Rewrite 3 entries:

```markdown
| **Bucket A drift** | Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). Include intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — see `03 § NFR-1 Empirical Citation`) |
| **Bucket B drift** | Informational delta `rewrite-G4-ON − rewrite-G4-OFF` ที่บันทึก sign + magnitude ของ intentional G4 fix contribution — **no acceptance gate** per NFR-1.8 (Should priority, BT-001 re-classification). DISABLE_G4_FIXES build อาจ measurable เฉพาะ partial pre-CircuitBreaker window |
| **Bug-fix bucket** | (deprecated post-BT-001) — เดิมหมายถึง 2-bucket deviation budget; ตอนนี้ Bucket B ไม่เป็น budget. ดู NFR-1.8 + `03 § NFR-1 Empirical Citation` แทน |
```

**Effort:** Low (3 glossary entries rewrite)

---

### Claim 04.5: 🟠 HIGH — Goal G4 KPI row stale framing "drift นับใน bucket B ของ regression budget" — primary success contract

**Location:** `01-project-brief.md` § 3 Goals & Success Metrics (line 60, G4 row)

**Problem:**
G4 row Success KPI column:

> *"(a) `BI` orders ต้องมี SL อิง parent `B` slot...(b) `ExtraTakeProfit_J` iterate `MagicJ` (=206)...Drift จาก fix นี้นับใน **bucket B** ของ regression budget (แยกจาก 25% pattern parity)"*

หลัง BT-001:
- "bucket B ของ regression budget" = wrong framing (Bucket B ไม่เป็น budget แล้ว)
- "แยกจาก 25% pattern parity" = wrong (G4 fix drift ตอนนี้ part of Bucket A 25% measurement)

**Why this matters:**
G4 row Success KPI = primary success contract ของ goal ที่ 4 — top-level statement ที่ stakeholder + Architect อ่านก่อน drill ลง NFR/BR. Stale KPI framing ที่ contract level = ทุก reader ที่ไม่ drill ลง `03` empirical citation block จะ infer Bucket B budget mental model ผิด. Primary contract = primary risk.

**Minimum acceptable fix:**
Rewrite G4 KPI column:

```
(a) `BI` orders ต้องมี SL อิง parent `B` slot (รายละเอียด distance vs absolute = locked "same SL distance" per OQ-3.3); (b) `ExtraTakeProfit_J` iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201). G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (rewrite-G4-ON vs baseline ≤ 25%, default build) + NFR-1.8 informational delta (post-BT-001 re-baseline 2026-05-12)
```

**Effort:** Low (KPI cell rewrite + BT-001 cite)

---

### Claim 04.6: 🟠 HIGH — Rule type tag legend + BR-7 intro paragraph framing Bucket B ผิด — cascade ไปทุก ⚠️ BR

**Location:** `04-business-rules.md` § 1 Rule type tag (line 31) + § 8 BR-7 intro (line 422)

**Problem:**
Two structural sites ใช้ pre-BT-001 Bucket B framing:

(a) Line 31 — Rule type tag legend:
> *"⚠️ **Bug-fix** — intentional change per G4 (drift นับใน Bucket B)"*

(b) Line 422 — BR-7 section intro:
> *"หมวดนี้คือ 2 intentional rule changes ที่ user decision 2026-05-01 = **FIX** (drift นับใน Bucket B ของ regression budget — `trading-baseline.md`)"*

Site (a) เป็น legend ที่ define ความหมายของ ⚠️ tag → ทุก BR ที่มี ⚠️ tag (BR-7.1, BR-7.2 อย่างน้อย) inherit นิยามนี้. Site (b) เป็น intro ที่ frame ทั้ง BR-7 section.

Per BT-001:
- Bucket B = informational delta (no gate, no budget)
- G4 fix drift = part of Bucket A measurement (rewrite-G4-ON default build)

**Why this matters:**
Legend (a) = vocabulary ของทั้งเอกสาร — ผิดที่ legend = ผิดทั้ง doc transit. Intro (b) = mental model ของผู้อ่าน BR-7 — Architect/TD/QA อ่านแล้วเข้าใจว่า BR-7.x rules ต้อง track drift contribution ใน Bucket B (เดิม). ทั้งคู่ propagation ที่ structural level (not single rule).

**Minimum acceptable fix:**
Rewrite both:

```markdown
# Line 31:
- ⚠️ **Bug-fix** — intentional change per G4 (drift รวมอยู่ใน Bucket A measurement บน rewrite-G4-ON default build per NFR-1.1; Bucket B = informational delta per NFR-1.8 post-BT-001)

# Line 422:
หมวดนี้คือ 2 intentional rule changes ที่ user decision 2026-05-01 = **FIX**. G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (rewrite-G4-ON vs baseline) + NFR-1.8 informational delta (BT-001 re-baseline 2026-05-12) — ดู `03 § NFR-1 Empirical Citation`.
```

**Effort:** Low (2 prose sites rewrite)

---

### 🟡 MEDIUM

---

### Claim 04.7: 🟡 MEDIUM — FR-3.3 Why-line "drift ... แยกจาก 25% ceiling" framing stale

**Location:** `02-functional-requirements.md` § FR-3.3 Why (line 288)

**Problem:**
FR-3.3 Why narrative:

> *"...user decision 2026-05-01 = **FIX** (G4); drift จาก fix นี้นับใน **bucket B** ของ regression budget แยกจาก 25% ceiling"*

Same pre-BT-001 framing as Claim 04.5 — frames G4 fix drift as separate from 25% Bucket A ceiling. Post-BT-001, the drift IS subsumed into the 25% measurement (since Bucket A = G4-ON default).

**Why this matters:**
Why-line = rationale ที่ explain "ถ้าไม่มี requirement นี้ business เจ็บตรงไหน" — reader ใช้ตัดสินใจ trade-off. Stale framing here กระทบ Architect's trade-off design (e.g., "ควรเก็บ DISABLE_G4_FIXES build target?") ในขั้น Phase 1B.

**Minimum acceptable fix:**
Rewrite Why clause tail (after "decision 2026-05-01 = FIX (G4);"):

```
...G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (≤ 25% บน rewrite-G4-ON default build) + NFR-1.8 informational delta (BT-001 re-baseline 2026-05-12)
```

**Effort:** Low (single clause rewrite)

---

### Claim 04.8: 🟡 MEDIUM — BR-7.1/7.2 Validation hints "bucket B drift documented" stale framing (2 sites)

**Location:** `04-business-rules.md` § BR-7.1 (line 433) + § BR-7.2 (line 445)

**Problem:**
BR-7.1 Validation hint:

> *"QA inspect BI trade journal entries — `sl > 0` ทุกราย; verify `(BI_entry - BI_sl)` ≈ `(B_entry - B_sl)` ใน pip distance; **bucket B drift documented**"*

BR-7.2 Validation hint:

> *"QA inspect trade journal — ทุก J close event มี `triggering_function = "ExtraTakeProfit_J"` (ไม่ใช่ "_F"); F close ไม่อ้างถึง J; **bucket B drift documented**"*

ทั้ง 2 hints trail clause "bucket B drift documented" — implies Bucket B เป็น measurement contract ที่ QA ต้องเก็บ. Per BT-001 NFR-1.8: Bucket B = informational only, no required output unless partial G4-OFF window runnable.

**Why this matters:**
Validation hints = QA recipe — agent อ่านแล้ว implement check. Stale framing → QA agent จะ over-engineer Bucket B documentation step ที่ BT-001 ลด priority ลงเป็น optional. Compounding effect across both BR-7 rules.

**Minimum acceptable fix:**
Rewrite trailing clauses:

```
# BR-7.1 line 433 (end):
...verify `(BI_entry - BI_sl)` ≈ `(B_entry - B_sl)` ใน pip distance; portfolio-level drift roll up via NFR-1.1 Bucket A (rewrite-G4-ON build); NFR-1.8 informational delta optional

# BR-7.2 line 445 (end):
...F close ไม่อ้างถึง J; per-slot J/F drift check via NFR-1.6 (rewrite-G4-ON build); NFR-1.8 informational delta optional
```

**Effort:** Low (2 trailing clause rewrites)

---

### Claim 04.9: 🟡 MEDIUM — Reference Materials table description "2-bucket deviation budget" stale

**Location:** `01-project-brief.md` § 9 Reference Materials (line 279)

**Problem:**
Row for `trading-baseline.md` describes role as:

> *"Regression contract + 2-bucket deviation budget (Bucket A pattern parity, Bucket B intentional bug-fix)"*

หลัง BT-001 NFR-1.8 line 132 ตัด failure trigger ออก + แสดงว่า DISABLE_G4_FIXES build halts at sim 2021-01-14 → 2-bucket budget framing ไม่ valid อีก. Bucket B ไม่ใช่ budget; เป็น informational delta. `trading-baseline.md` itself ตามตัวอักษร might still ใช้ "deviation budget" terminology (out-of-BA-scope to verify), but the `01 § 9` description that summarizes its role to BA reader needs update.

**Why this matters:**
`01 § 9` = canonical "what does each foundation doc contain" table — sponsor/PM browses ก่อนรู้จะอ่าน source ไหน. Stale description ที่ entry-point ระบบ navigation ทำให้ผู้ใช้ infer 2-bucket budget mental model ก่อนเปิด NFR-1.x.

**Minimum acceptable fix:**
Rewrite description cell:

```
Regression contract + Bucket A (rewrite-G4-ON vs baseline, NFR-1.1) + Bucket B (informational delta per NFR-1.8 post-BT-001 re-baseline 2026-05-12)
```

**Effort:** Low (single table cell rewrite)

---

### Claim 04.10: 🟡 MEDIUM — `docs/state/overview.md` row stale "NFR: 30 (M=26 S=4 C=0)" — state reconciliation drift

**Location:** `docs/state/overview.md` Phase Status row "Design (BA)" (line 10)

**Problem:**
Phase Status row notes still record pre-BT-001 NFR counts:

> *"...NFR: **30 (M=26 S=4 C=0)**..."*

Post-BT-001, NFR-1.8 demoted Must → Should → counts ตอนนี้:
- `03 § TL;DR` (line 13): *"Must **25** / Should **5** / Could **0**"*
- `03 § 9 NFR Summary Table` total counts (line 505): *"Must **25** / Should **5** / Could **0**"*

State reconciliation per CLAUDE.md § 6 ระบุ 3-file propagation rule: ปิด task / fix-round / impl-plan rebuttal → propagate state ผ่าน impl-plan.md → overview.md → handoff. BT-001 rework ใน `03` finished แต่ overview.md ไม่ได้รับ propagation. Row metadata description disagree กับ underlying doc.

**Why this matters:**
overview.md = derived view ที่ status agents + `/next` รัน scan first. M=26 vs M=25 difference เล็กแต่ Phase Status row ทำงานเป็น signal ว่า "Design (BA) state is what". status agent + future reviewer อ่าน row notes แล้ว infer NFR-1.8 Must (ขัด `03`). Tier 1 / Tier 1.5 / Tier 2 reconciliation gap.

> **Reviewer scope note:** `overview.md` อยู่นอก `docs/ba/` แต่ Cross-Doc Consistency category (#14) บังคับให้ตรวจ derived views ที่อ้าง BA package state. Reviewer raise เพื่อให้ rebuttal cycle ปิด full state propagation พร้อมกับ glossary/AC fixes.

**Minimum acceptable fix:**
Update row notes "NFR: 30 (M=26 S=4 C=0)" → "NFR: 30 (M=25 S=5 C=0) — post-BT-001 NFR-1.8 demote". Bump Last Updated date or add BT-001 note phrase if not already.

**Effort:** Low (single line update)

---

### 🔵 LOW

---

### Claim 04.11: 🔵 LOW — `01/02/04` headers "Last updated: 2026-05-01" ไม่ bump despite BT-001 cascade content changes required

**Location:** `01-project-brief.md` line 5, `02-functional-requirements.md` line 5, `04-business-rules.md` line 5

**Problem:**
3 BA docs ยังคง:

```
> **Last updated:** 2026-05-01
```

ขณะที่ `03` bump เป็น `2026-05-12 (BT-001 — ...)`. แม้ Claims 04.1-04.9 ยังไม่ apply, doc headers ไม่ reflect ว่ามี deferred propagation. Reader scanning headers จะ infer BT-001 = isolated NFR doc rework — แต่ใน reality glossary/AC/invariant ใน 01/02/04 carry stale framing.

**Why this matters:**
Last-updated = audit trail metadata. Stale dates ใน 3 docs ที่ มี content drift จาก BT-001 = misleading audit trail. Low severity เพราะหลังจาก rebuttal fix applied, headers จะ bump pro forma. ไม่ block downstream แต่ damage discoverability.

**Minimum acceptable fix:**
หลังจาก rebuttal applies Claims 04.1-04.9, bump headers ของ 3 docs:

```
> **Last updated:** 2026-05-12 (BT-001 cascade — Bucket A/B propagation: glossary + ACs + BR invariants + rule legend)
```

**Effort:** Low (3 header updates ทำพร้อมกับ rebuttal content edits)

---

## Cross-Document Issues

| Check | Result |
|-------|--------|
| Bucket A semantic ระหว่าง `03 § NFR-1.1` vs `01 § 8 Glossary` vs `02 § FR-3.3/3.4 ACs` vs `04 § BR-7 + BR-9.5` | ❌ **Inconsistent** — `03` redefined "rewrite-G4-ON vs baseline" (BT-001); `01` Glossary still "unintended drift" framing; `02` ACs still "ไม่นับใน 25% bucket A"; `04` invariant still "2-pass with/without G4" |
| Bucket B semantic ระหว่าง `03 § NFR-1.8` vs `01 § 8 Glossary line 209/216` vs `02 § FR-3.3/3.4 ACs` vs `04 § 1 legend + § 8 BR-7 intro + BR-7.1/7.2 hints` | ❌ **Inconsistent** — `03` informational delta (no gate); 7 other sites still "separate budget" / "drift documented" / "regression accounting category" |
| NFR-1.8 priority Must→Should ระหว่าง `03 § TL;DR + § 9 Summary` vs `docs/state/overview.md` row | ❌ **Inconsistent** — `03` ชี้ M=25 S=5; overview.md row notes ยัง M=26 S=4 |
| FR-3.3/3.4 AC testability vs NFR-1.1/1.8 Verification | ❌ **Untestable** — ACs require Bucket B drift measurement; NFR-1.1 Verification forbids DISABLE_G4_FIXES build (the only vehicle for Bucket B isolation) |
| BR-9.5 invariant verification protocol vs NFR-1.1 Verification | ❌ **Direct conflict** — BR-9.5 mandates "2 รอบ with/without G4"; NFR-1.1 forbids "without G4" build |
| Last-updated header propagation | ❌ **Stale** — `03` bumped 2026-05-12; `01/02/04` still 2026-05-01 despite carrying content needing BT-001 rework |
| BT-001 audit trail (`backtrack-log.md`) | ✅ Solid — BT-001 row + Impacted phases enumeration + evidence sources ครบ; failure mode คือ propagation not applied, not trail missing |
| BI SL semantic "same SL distance" (OQ-3.3) | ✅ Unchanged + consistent across `02 FR-3.3 AC-3.3.1`, `04 BR-7.1`, `01 § 10 resolved OQs` |
| Slot U deletion (OQ-8) | ✅ Unchanged + consistent |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 04.1 | 🔴 CRITICAL | BR-9.5 invariant "2-pass with/without G4" ขัด NFR-1.1 Verification (BT-001 ห้าม DISABLE_G4_FIXES) | `04 § BR-9.5` line 530 | Low |
| 04.2 | 🔴 CRITICAL | AC-3.3.3 "ไม่นับใน Bucket A" ขัด BT-001 Bucket A re-definition | `02 § FR-3.3` line 300 | Low |
| 04.3 | 🔴 CRITICAL | AC-3.4.3 "drift นับใน Bucket B (intentional fix)" ผิด BT-001 informational reframing | `02 § FR-3.4` line 321 | Low |
| 04.4 | 🟠 HIGH | Glossary 3 entries (Bucket A drift / Bucket B drift / Bug-fix bucket) stale | `01 § 8` lines 208/209/216 | Low |
| 04.5 | 🟠 HIGH | Goal G4 KPI row stale "bucket B ของ regression budget" — primary contract | `01 § 3` line 60 | Low |
| 04.6 | 🟠 HIGH | Rule type tag legend + BR-7 intro stale (2 structural sites) | `04 § 1` line 31 + `§ 8` line 422 | Low |
| 04.7 | 🟡 MEDIUM | FR-3.3 Why-line stale "แยกจาก 25% ceiling" | `02 § FR-3.3` line 288 | Low |
| 04.8 | 🟡 MEDIUM | BR-7.1/7.2 Validation hints "bucket B drift documented" (2 sites) | `04 § BR-7.1/7.2` lines 433/445 | Low |
| 04.9 | 🟡 MEDIUM | Reference Materials description "2-bucket deviation budget" stale | `01 § 9` line 279 | Low |
| 04.10 | 🟡 MEDIUM | `overview.md` NFR count M=26 stale post-BT-001 demote | `docs/state/overview.md` line 10 | Low |
| 04.11 | 🔵 LOW | `01/02/04` Last-updated headers ไม่ bump despite BT-001 cascade pending | `01/02/04` line 5 each | Low |

---

## Closure Statement

**BA Phase 1A — REWORK NEEDED post-BT-001 cascade.**

Round 03 → Round 04 transition:
- Round 03 (2026-05-02) closed clean (0 findings) — package was internally consistent pre-BT-001
- BT-001 (2026-05-12) rebaseline applied **only to `03`** + empirical citation block
- Round 04 = first review post-BT-001 → caught 11 cascade propagation gaps (3 CRITICAL contract conflicts + 3 HIGH primary references + 4 MEDIUM doc-detail drift + 1 LOW audit-trail metadata)

**Trajectory caveat:** Round 04 finding count (11) is NOT a regression of Round 03's clean closure — it is the first scan that surfaces post-BT-001 work-in-progress state. Rework discipline (state reconciliation per CLAUDE.md § 6) requires BT-001 → 3-file propagation; only 1 doc was updated.

**Recommended action sequence:**

1. **`/ba-rebuttal claim-review-04.md`** — apply Claims 04.1-04.11 (all Low effort, single-paragraph or single-line edits; total estimated ≤ 60 min)
2. Re-run **`/ba-review all`** as Round 05 → expect 0 findings (clean closure mirroring Round 03 pattern after rebuttal)
3. Update `docs/state/overview.md` Phase Status row: `🔄 BACKTRACK` → `✅ Complete post-BT-001 cascade` (with new count M=25 S=5 C=0)
4. Then proceed to `/sd-review all` (BT-001 also impacts SD per `backtrack-log.md § Impacted phases — SD`)

**Architect/TD/QA risk if NOT remediated:**
- Architect (Phase 1B) infers DISABLE_G4_FIXES first-class build target from BR-9.5 → wasted spike investigation
- TD (Phase 1D) creates compile-flag dual build paths assuming Bucket B is a budget category → over-engineered build matrix
- QA (Phase 3T) designs 2-pass regression gate (with/without G4) → fails reproducibly at sim 2021-01-14 (Run #2 empirical) → false-failure cascade

> **End of Claim Review Round 04** — 11 findings (3 🔴 / 3 🟠 / 4 🟡 / 1 🔵), all post-BT-001 propagation gaps. Run `/ba-rebuttal claim-review-04.md` to apply cascade fixes.
