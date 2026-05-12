# System Design Claim Review Round 05

| Field | Value |
|-------|-------|
| **Round** | 05 |
| **Target** | `all` (6 SD docs + 12 ADRs + 4 API specs — first review post-BT-001 BA cascade close) |
| **Date** | 2026-05-12 |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |
| **Predecessor** | `claim-review-04.md` (2026-05-02; 0 finding — pre-BT-001 clean verify of rebuttal-03) → no rebuttal needed |
| **Trigger** | BT-001 (2026-05-12) — BA NFR-1.1 + NFR-1.8 Bucket A/B re-baseline + BA cascade fully closed via `ba/rebuttal-round-04.md` → `ba/claim-review-05.md` (0 finding); SD package ยังไม่ propagate ใด ๆ |

---

## 📊 At-a-Glance

**Total findings:** 11 (🔴 CRITICAL **3** / 🟠 HIGH **3** / 🟡 MEDIUM **3** / 🔵 LOW **2**)
**Schedule-leakage check:** ✅ Clean — grep `Sprint|Week|Q[1-4] 202X|team capacity|## Phase Plan|Schedule|Roadmap` พบ 0 hits (เฉพาะ `IMPL-067 — DST regression run (10 transitions Mar 2021 → Oct 2025)` = dataset description, ไม่ใช่ schedule — same false-positive ตาม Round 01/03/04 audit)
**Language check:** ✅ Pass — Thai narrative ≥ 40% ทุก doc; Round 03 cascade fix wording (cumulative counter, Operator threshold) ยัง stable ในไทย
**No-Hints Pass-Through:** Phase Hints FULL variant + Evolution Sequence E1+E2 ใน `07 § 6` — vocabulary stable, ไม่กระทบ BT-001
**Anti-Duplication:** Round 03's 2 fixes (force_clear_count cumulative cascade — `04 § 4.1` mermaid + `05 § 7.2` threshold) verified ยัง **stable post-BT-001** (BT-001 ไม่กระทบ counter semantic); Round 04 (verify-only 0 finding) confirmed pre-BT-001 baseline. Round 05 findings ทั้งหมด = **BT-001 cascade gap** ที่ Round 04 ปิด clean **ก่อน** BT-001
**Net assessment:** BA package internally consistent post rebuttal-04 → `ba/claim-review-05.md` 0-finding clean closure. **SD package = 2 voices** vs BA: BA Glossary + AC + BR ใช้ post-BT-001 vocabulary ("rewrite-G4-ON vs baseline, G4 fix included" + "informational delta, no gate"); SD Glossary + ADR Digest + IMPL-062/063 task description + Phase Hint rationale + ADR-009 Validation + Revisit-when + 05 § 6 Operational Risk gate ยังเขียน pre-BT-001 framing ("unintended rewrite drift" / "separate budget" / "rewrite without G4 fixes vs baseline" / "Bucket B drift > 25% re-decide"). Mirror BA Round 04 finding-spike pattern (BT-001 cascade work-in-progress, ไม่ใช่ regression).

### Top 3 to Fix First

1. **Claim 05.1** 🔴 — IMPL-062 task description `"rewrite (without G4 fixes) vs baseline → Bucket A drift"` = exact pre-BT-001 framing ที่ BT-001 ห้าม + Run #2 empirical พิสูจน์ unmeetable — `08-product-breakdown.md` line 129
2. **Claim 05.2** 🔴 — IMPL-063 task description `"rewrite (with G4 fixes) vs baseline → Bucket B drift"` + `"user re-decide if drift > 25%"` ผิด BT-001 Bucket B axis (informational delta = `rewrite-G4-ON − rewrite-G4-OFF`, ไม่ใช่ vs baseline) + ผิด gate (no threshold) — `08-product-breakdown.md` lines 130, 294
3. **Claim 05.3** 🔴 — SD Glossary `02 § 8` "Bucket A drift" + "Bucket B drift" ขัด BA Glossary post-rebuttal-04 directly — `02-high-level-architecture.md` lines 441, 442

### Verdict

- [ ] ✅ **Ready for Implementation Handoff**
- [x] ⚠️ **Needs Rebuttal Round** — 3 CRITICAL + 3 HIGH = SD package internally inconsistent กับ BA package post-BT-001; run `/sd-rebuttal claim-review-05.md`
- [ ] ⛔ **Immediate Attention**

> **Recommendation:** Architect run `/sd-rebuttal claim-review-05.md` → apply Claims 05.1-05.11 (all Low effort, ≤ 60 min — total 6 files touched). Re-run `/sd-review all` Round 06 → expect 0 finding (mirror Round 03→04 + BA Round 04→05 clean-closure pattern after rebuttal). Then proceed `/td-review` + `/qa-review` per BT-001 downstream chain ใน `ba/claim-review-05.md § Recommended action sequence`

---

## System Design Attack Vector Checklist (22 Categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass | ADR-001 + `02 § 3.2` trade-off unchanged; BT-001 ไม่กระทบ architecture style |
| 2 | Service Boundaries | ✅ Pass | unchanged from Round 04 |
| 3 | Communication Patterns | ✅ Pass | unchanged |
| 4 | Data Consistency | ✅ Pass | unchanged |
| 5 | Database Design | ✅ Pass | unchanged (no DB; file-based) |
| 6 | Caching Strategy | ✅ Pass | unchanged |
| 7 | Security Design | ⚠️ Finding 05.8 | STRIDE สมบูรณ์; `§ 6` Operational Risk row "Bucket B drift > 25%" detection threshold stale |
| 8 | Scalability | ✅ Pass | unchanged |
| 9 | Reliability & Fault Tolerance | ✅ Pass | unchanged |
| 10 | Performance Budgets | ✅ Pass | NFR-2.1 + NFR-2.2 timing budgets ไม่กระทบ BT-001 |
| 11 | Concrete Numbers | ✅ Pass | unchanged |
| 12 | API Contract Quality | ✅ Pass | 4 schemas ไม่กระทบ BT-001 (regression contract = doc-level, not schema) |
| 13 | Data Flow Completeness | ✅ Pass | `04` flows ไม่อ้าง Bucket A/B framing — pass-through (verified via grep) |
| 14 | Observability | ✅ Pass | Round 03 cumulative counter cascade ยัง stable |
| 15 | ADR Quality | ⚠️ Finding 05.4 | ADR-009 § Validation + § Consequences + § Revisit-when ใช้ "Bucket B drift > 25%" gate ที่ BT-001 ยกเลิก; needs amendment |
| 16 | Cross-Doc Consistency | ⚠️ Findings 05.1, 05.2, 05.3, 05.5, 05.6, 05.7, 05.8, 05.9 | **8 sites stale vs BA post-BT-001 cascade** — primary failure dimension ของ Round 05 |
| 17 | Requirements Traceability | ⚠️ Finding 05.6 | NFR Traceability row "bucket B drift via ADR-009" implies Bucket B = ADR-009 deliverable (pre-BT-001 framing) |
| 18 | Failure Modes | ✅ Pass | unchanged |
| 19 | Future Evolution + Evolution Sequence | ✅ Pass | `07 § 6` E1+E2 unchanged; BT-001 ไม่กระทบ |
| 20 | Work Inventory + Phase Hints | ⚠️ Findings 05.1, 05.2, 05.9 | IMPL-062/063 task description + Phase Hint P4 rationale ใช้ pre-BT-001 framing |
| 21 | Readability / Reader-Empathy | ⚠️ Finding 05.10 | TL;DR + Why-line scaffold ยังครบ; `02 § 2 Pillar #1` ไม่ระบุ "rewrite-G4-ON build" clarification post-BT-001 |
| 22 | Language Rule Compliance | ✅ Pass | bilingual ทุก doc unchanged; ratio preserved |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

---

### Claim 05.1: 🔴 CRITICAL — IMPL-062 task description "rewrite (without G4 fixes) vs baseline → Bucket A drift" คือ exact pre-BT-001 framing ที่ BT-001 ห้าม

**Location:** `docs/design-docs/08-product-breakdown.md` § 1.10 Epic SD-QA (line 129)

**Problem:**
IMPL-062 task row ระบุชัด:

> *"IMPL-062 — Run regression: rewrite (without G4 fixes) vs baseline → Bucket A drift | M | acceptance signal | NFR-1.1 ถึง NFR-1.7 primary acceptance | —"*

หลัง BT-001 (2026-05-12) NFR-1.1 ได้ redefine **Bucket A = "rewrite-G4-ON vs baseline"** (single-pass, G4 fixes ON default build, G4 fix contribution **included**). BA `03 § NFR-1.1 Verification` line 32 ระบุชัด:

> *"...ห้ามใช้ `#define DISABLE_G4_FIXES` build (Bucket A semantic ไม่รองรับ pre-G4 measurement หลัง BT-001)"*

IMPL-062 task description = **exact pre-BT-001 framing** ที่:
- (a) BT-001 backtrack ห้ามชัด
- (b) IMPL-062 ของตัวเอง (Run #2, 2026-05-12) **พิสูจน์ empirical** ว่า unmeetable — DISABLE_G4_FIXES build halts at sim 2021-01-14 via CircuitBreaker BR-3.6 ping-pong (drift ≈ 99.998%, ไม่ใช่ ≤ 25%); ดู `docs/state/regression-bucket-a.md § 4a Run #2` + commit `e75dc2c`

**Why this matters:**
IMPL-062 = primary regression acceptance signal ของ Phase 3T QA gate. Impl Planner / QA agent อ่าน SD task description ตามตัวอักษร → จะ:
1. ปั้น new headless test config ที่ใช้ `#define DISABLE_G4_FIXES` build → fail per Run #2 empirical (CircuitBreaker halt at sim 2021-01-14)
2. หรือเข้าใจผิดว่า "Bucket A = G4-OFF measurement" → cross-doc inconsistency กับ BA AC-3.3.3/3.4.3 + BR-9.5 (ที่ตอนนี้ระบุ "rewrite-G4-ON default build single-pass")
3. หรือ block sign-off เพราะ NFR-1.1 Verification ห้าม DISABLE_G4_FIXES build แต่ task description บังคับ

นี่คือ **direct contract conflict ระดับ Phase 3T gate** — IMPL-062 เป็น actual deliverable ที่ engineer execute → wrong task description = wrong execution. BA cascade ปิดแล้วผ่าน rebuttal-04 (BR-9.5 invariant rewritten "single-pass measurement บน rewrite-G4-ON build"); SD ต้อง mirror

**Minimum acceptable fix:**
Rewrite IMPL-062 task row:

```markdown
| IMPL-062 — Run regression: rewrite **default build (G4 fixes ON, single-pass)** vs baseline → Bucket A drift gate (NFR-1.1 ≤ 25%, G4 fix contribution included per BT-001 2026-05-12 re-baseline). ห้ามใช้ `#define DISABLE_G4_FIXES` build (Bucket A semantic ไม่รองรับ pre-G4 measurement post-BT-001 + IMPL-062 Run #2 empirical แสดง CircuitBreaker halt at sim 2021-01-14) | M | acceptance signal | NFR-1.1 ถึง NFR-1.7 primary acceptance + `ba/03 § NFR-1 Empirical Citation` | — |
```

**Effort:** Low (single row rewrite + BT-001 cite + Run #2 evidence anchor)

---

### Claim 05.2: 🔴 CRITICAL — IMPL-063 task description "rewrite (with G4 fixes) vs baseline → Bucket B drift" ผิด BT-001 Bucket B axis + stale gate "drift > 25%"

**Location:** `docs/design-docs/08-product-breakdown.md` § 1.10 Epic SD-QA (line 130) + § 4 Per-Task Metadata (line 294)

**Problem:**
2 SD sites ระบุ pre-BT-001 Bucket B framing:

(a) § 1.10 line 130:
> *"IMPL-063 — Run regression: rewrite (with G4 fixes — ADR-009 + BR-7.2) vs baseline → Bucket B drift | M | G4 acceptance signal | NFR-1.8; user re-decide trigger | ADR-009"*

(b) § 4 line 294 metadata:
> *"**IMPL-063** | **high** | acceptance | Bucket B regression sign-off | NFR-1.8; user re-decide trigger if drift > 25% | ADR-009"*

หลัง BT-001:
- **Bucket B = informational delta** `rewrite-G4-ON − rewrite-G4-OFF` — **relative comparison ระหว่าง 2 rewrite builds**, ไม่ใช่ vs baseline
- **No acceptance gate** (NFR-1.8 informational only, Should priority — re-classified 2026-05-12)
- "drift > 25% → re-decide" trigger = **stale** (ไม่มี threshold/gate post-BT-001)

(a) wrong axis: "rewrite (with G4) vs baseline" = Bucket A measurement (ที่ IMPL-062 ทำ), ไม่ใช่ Bucket B
(b) wrong gate: "user re-decide if drift > 25%" = pre-BT-001 NFR-1.8 trigger ที่ BA `03 § NFR-1.8` ลบ + reclassify เป็น informational only

**Why this matters:**
IMPL-063 = G4 fix sign-off task ที่ Impl Planner schedule หลัง E2-E8 complete. Engineer reads task → designs measurement against baseline (wrong) แทนการเทียบ G4-ON vs G4-OFF delta (correct). หรือ block sign-off รอ "user re-decide trigger" ที่ไม่มีจริง. BA `02 § FR-3.3 AC-3.3.3` + `04 § BR-7.1/7.2 Validation hints` ตอนนี้ระบุ "NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable)" — SD task description ขัดทั้ง 3 BA sites

นอกจากนี้ Bucket B axis ที่ผิด (vs baseline แทน rewrite-G4-ON − rewrite-G4-OFF) ทำให้ Phase 3T attempts จะ overlap กับ IMPL-062 measurement (ซ้ำซ้อน + ไม่ relevant)

**Minimum acceptable fix:**
Rewrite both sites:

```markdown
# § 1.10 line 130:
| IMPL-063 — Measure Bucket B **informational delta** `rewrite-G4-ON − rewrite-G4-OFF` (sign + magnitude ของ G4 fix contribution — ADR-009 BI SL + BR-7.2 J magic). Record เฉพาะ partial pre-CircuitBreaker window ของ `#define DISABLE_G4_FIXES` build ที่ measurable (per BT-001 + IMPL-062 Run #2 empirical แสดง full-window unmeetable). **No acceptance gate** — informational only per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12) | M | G4 fix observability | NFR-1.8 informational delta | ADR-009 |

# § 4 line 294:
| **IMPL-063** | **medium** | acceptance | Bucket B informational delta sign-off | NFR-1.8 informational only (no gate, no re-decide trigger; sign + magnitude of G4 fix contribution measurable per partial G4-OFF window) | ADR-009 |
```

**Effort:** Low (2 row rewrites + cite BT-001 + cite empirical anchor)

---

### Claim 05.3: 🔴 CRITICAL — SD Glossary "Bucket A drift" + "Bucket B drift" ขัด BA Glossary post-rebuttal-04 (direct cross-doc inconsistency)

**Location:** `docs/design-docs/02-high-level-architecture.md` § 8 Glossary (lines 441, 442)

**Problem:**
2 SD Glossary entries ติดกันยังเขียน pre-BT-001 semantic:

> *"| **Bucket A drift** | Behavioral deviation จาก code rewrite ที่ไม่ตั้งใจ (ต้อง ≤ 25% Net Profit per NFR-1.1) |"*
> *"| **Bucket B drift** | Behavioral deviation จาก intentional bug fix (BI SL + ExtraTakeProfit_J magic per NFR-1.8) — separate budget, document แยก |"*

BA Glossary `01 § 8` post rebuttal-04 (verified ใน `ba/claim-review-05.md § Rebuttal-04 Fix Verification Matrix`) ระบุ:

> *"| **Bucket A drift** | Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). **Includes** intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`) |"*
> *"| **Bucket B drift** | Informational delta `rewrite-G4-ON − rewrite-G4-OFF` ที่บันทึก sign + magnitude ของ intentional G4 fix contribution — **no acceptance gate** per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12). `DISABLE_G4_FIXES` build อาจ measurable เฉพาะ partial pre-CircuitBreaker window |"*

**Direct cross-doc conflict:**
- (a) Bucket A: BA "Includes intentional G4 fix" vs SD "ที่ไม่ตั้งใจ (unintended)" — opposite semantic
- (b) Bucket B: BA "Informational delta, no acceptance gate" vs SD "separate budget, document แยก" — opposite framing

**Why this matters:**
Glossary `02 § 8` = SD architecture vocabulary single source of truth (per `02 § 1 ⚠️ Authoritative source` rule); Tech Lead / Impl Engineer / QA Phase 3T อ่าน `02` ก่อน drill ลง ADRs. SD Glossary ขัด BA Glossary = **2 voices ระหว่าง design package** ที่ downstream agent ต้อง reconcile เอง. CLAUDE.md § Glossary "Vocabulary Lookup" rule ระบุ "ห้าม paraphrase หรือนิยามใหม่ในเอกสารอื่น" — SD glossary ไม่ใช่ paraphrase บริสุทธิ์ แต่กำลัง contradict authoritative BA semantic

Impact ตัวอย่าง:
1. TD Phase 1D อ่าน SD Glossary "unintended drift" → infer "intentional G4 fix อยู่นอก Bucket A" → design TD audit contract ตาม pre-BT-001 mental model (= ขัด NFR-1.1 ที่ตอนนี้ G4 fix included)
2. QA Phase 3T อ่าน SD Glossary "separate budget" → over-engineer Bucket B per-fix documentation step (= ขัด `ba/04 § BR-7.1/7.2` post-rebuttal-04 ที่ระบุ "NFR-1.8 informational delta optional")
3. Reader cross-check vocabulary → confused; defeats CLAUDE.md § Glossary discipline

**Minimum acceptable fix:**
Mirror BA `01 § 8` definitions ลง SD `02 § 8`:

```markdown
| **Bucket A drift** | Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). **Includes** intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — ดู `ba/03 § NFR-1 Empirical Citation`) |
| **Bucket B drift** | Informational delta `rewrite-G4-ON − rewrite-G4-OFF` ที่บันทึก sign + magnitude ของ intentional G4 fix contribution — **no acceptance gate** per NFR-1.8 (Should priority, BT-001 re-classification 2026-05-12). `DISABLE_G4_FIXES` build อาจ measurable เฉพาะ partial pre-CircuitBreaker window |
```

**Effort:** Low (2 glossary cell rewrites — copy verbatim จาก BA Glossary)

---

### 🟠 HIGH

---

### Claim 05.4: 🟠 HIGH — ADR-009 § Validation + § Consequences + § Revisit-when ใช้ "Bucket B drift > 25%" gate ที่ BT-001 ยกเลิก

**Location:** `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` lines 91, 95, 107, 115

**Problem:**
ADR-009 (locked Accepted 2026-05-02) มี 4 sites ใช้ pre-BT-001 framing:

(a) Line 91 § Decision: *"**Validation (NFR-1.8 bucket B):**"* — heading frame validation step เป็น Bucket B scope (= ขัด post-BT-001 ที่ Bucket A measurement subsume validation)

(b) Line 95 § Decision validation step 3: *"Bucket B drift documented แยก: PF ไม่ลด, Max DD% ไม่เพิ่ม"* — "documented แยก" + PF/DD thresholds = pre-BT-001 "separate budget" framing; ตอนนี้ PF/DD อยู่ใต้ NFR-1.2/1.5 Bucket A (รวม G4 fix)

(c) Line 107 § Consequences: *"Bucket B drift estimate (per `trading-baseline.md § Deviation Budget`):"* — references "Deviation Budget" framing ที่ BA Glossary `01 § 8` line 216 mark "(deprecated post-BT-001 2026-05-12)"

(d) Line 115 § Revisit-when: *"QA regression แสดง bucket B drift > 25% Net Profit (= bug fix "ตัดได้กำไร") → user re-decide per `trading-baseline.md § Validation Strategy`"* — "Bucket B drift > 25%" gate = stale (no threshold/gate post-BT-001)

**Why this matters:**
ADR-009 = locked architectural decision ที่ TD Phase 1D + Impl Engineer + QA Phase 3T ใช้เป็น reference. ADR ผิด framing = decision audit trail สับสน. Specifically:
- Revisit-when trigger ที่ stale = ทำให้ "เมื่อไรต้อง re-decide ADR-009" คลุมเครือ post-BT-001 → Phase 2 architect อ่าน Revisit-when จะ trigger criteria ผิด
- Validation section ระบุ PF/DD checks ใต้ Bucket B → QA Phase 3T schedule per-fix validation ที่ BA rebuttal-04 ลด priority ลงเป็น optional (per BR-7.1/7.2 hints)
- Consequences references "trading-baseline.md § Deviation Budget" = deprecated section

ทั้ง 4 sites ใน 1 ADR file — needs single rebuttal pass

**Minimum acceptable fix:**
Apply 4 edits (ADR amendment per `.claude/rules/workflow.md § ADR Discipline` — log amendment ใน ADR header + cite BT-001):

```markdown
# Line 91 heading rewrite:
**Validation (NFR-1.1 Bucket A + NFR-1.8 informational delta, BT-001 re-baseline 2026-05-12):**

# Line 95 step 3 rewrite:
- Bucket A measurement (rewrite-G4-ON build, NFR-1.1 ≤ 25%) absorbs BI SL fix drift; portfolio-level PF (NFR-1.2 ≤ 0.2 drop) + Max DD (NFR-1.5 ≤ +10pp) gate at portfolio level. NFR-1.8 informational delta (G4-ON − G4-OFF) record sign+magnitude เฉพาะ partial pre-CircuitBreaker window measurable

# Line 107 framing rewrite:
- Bucket A measurement absorbs BI SL fix per NFR-1.1 (rewrite-G4-ON vs baseline); informational delta estimate (per BA `03 § NFR-1 Empirical Citation` post-BT-001):

# Line 115 Revisit-when rewrite:
- ถ้า QA regression แสดง Bucket A (rewrite-G4-ON vs baseline) drift > 25% Net Profit → user re-decide per BA `03 § NFR-1.1 Verification` + `01 § 10` resolved OQs (BT-001 re-baseline subsumes G4 fix contribution into Bucket A)
- Phase 2 ถ้าเพิ่ม slot pyramid pattern อื่น (เช่น JI, GI) → apply same arithmetic + ADR template
```

เพิ่ม amendment note ใน ADR header table:

```markdown
| **Amendment** | 2026-05-12 — Validation + Consequences + Revisit-when sections cascade-updated per BT-001 (BA NFR-1.1 + NFR-1.8 re-baseline) — Bucket B framing demoted, Revisit-when trigger re-anchored to Bucket A |
```

**Effort:** Low (4 in-place edits + 1 amendment note)

---

### Claim 05.5: 🟠 HIGH — `02 § 9` ADR Digest row ADR-009 stale Bucket B framing + Revisit-when invalid

**Location:** `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest (line 469)

**Problem:**
ADR Digest table row สำหรับ ADR-009:

> *"| ADR-009 | BI SL inheritance pip arithmetic | Accepted | Earliest B parent SL distance + Bollinger fallback | **Bucket B drift expected: PF stable, Max DD% ลด, Net Profit ขึ้น/ลง** | **Bucket B drift > 25% Net Profit (re-decide)** | [009](../adr/009-bi-sl-inheritance-pip-arithmetic.md) |"*

2 cells stale:
- "Trade-off (1-line)" cell: "Bucket B drift expected: PF stable, Max DD% ลด..." — Bucket B framing pre-BT-001 (separate-budget mental model)
- "Revisit-when" cell: "Bucket B drift > 25% Net Profit (re-decide)" — stale gate (Bucket B has no threshold post-BT-001)

นี่คือ surface บางที่สุดที่ TD/Tech Lead อ่านก่อน drill ลง ADR-009 — primary visibility = primary risk surface

**Why this matters:**
`02 § 9` ADR Digest = single-page summary ของ 12 ADRs ที่ Tech Lead scan first (per `02 § 9` intro "ตารางนี้ summary หาเร็ว"). Row ที่ stale = บิดเบือน mental model ก่อน drill ลง ADR file. Compounds Claim 05.4 — แม้ ADR-009 ปรับแล้ว ถ้า digest row ไม่ update reader will still infer stale Bucket B gate from quick-scan path.

**Minimum acceptable fix:**
Rewrite row 2 cells:

```markdown
| ADR-009 | BI SL inheritance pip arithmetic | Accepted | Earliest B parent SL distance + Bollinger fallback | Bucket A drift absorbed (NFR-1.1 G4-ON build): PF stable, Max DD% ลด, Net Profit ขึ้น/ลง; informational delta per NFR-1.8 (BT-001 2026-05-12) | Bucket A (rewrite-G4-ON vs baseline) drift > 25% Net Profit (re-decide) | [009](../adr/009-bi-sl-inheritance-pip-arithmetic.md) |
```

**Effort:** Low (single row 2-cell rewrite)

---

### Claim 05.6: 🟠 HIGH — `02 § 1.2` NFR Traceability row "bucket B drift via ADR-009" framing implies Bucket B = ADR-009 deliverable budget

**Location:** `docs/design-docs/02-high-level-architecture.md` § 1.2 NFR Traceability (line 71)

**Problem:**
NFR traceability row สำหรับ NFR-1.1 ถึง NFR-1.8:

> *"| NFR-1.1 ถึง NFR-1.8 | Behavioral parity (regression contract) | architecture preserves slot/RiskManager/cross-slot logic 1:1 + **bucket B drift via ADR-009** |"*

Trailing phrase "bucket B drift via ADR-009" — pre-BT-001 framing ที่ frame Bucket B drift เป็น architectural deliverable ของ ADR-009 (= separate-budget mental model). Post-BT-001:
- ADR-009 BI SL fix contribution วัดผ่าน **NFR-1.1 Bucket A** (rewrite-G4-ON build) — รวมอยู่ใน 25% gate, ไม่ใช่ "via ADR-009 separate budget"
- Bucket B = informational delta `rewrite-G4-ON − rewrite-G4-OFF` — ไม่ใช่ "deliverable" ของ ADR ใด ๆ; เป็น measurement vehicle

**Why this matters:**
NFR Traceability matrix = mapping ที่ Tech Lead + QA Phase 3T scan ก่อน design test gate. Row ที่ frame ADR-009 เป็น "Bucket B deliverable" → QA agent infer ว่า ADR-009 implementation = Bucket B sign-off path → design redundant 2-bucket measurement (= overlap กับ Claim 05.1 IMPL-062 + Claim 05.2 IMPL-063 wrong-axis problem)

**Minimum acceptable fix:**
Rewrite row mapping cell:

```markdown
| NFR-1.1 ถึง NFR-1.8 | Behavioral parity (regression contract) | architecture preserves slot/RiskManager/cross-slot logic 1:1; G4 fix (ADR-009 BI SL + BR-7.2 J magic) contribution absorbed via NFR-1.1 Bucket A measurement (rewrite-G4-ON default build, BT-001 2026-05-12); NFR-1.8 informational delta optional |
```

**Effort:** Low (single cell rewrite)

---

### 🟡 MEDIUM

---

### Claim 05.7: 🟡 MEDIUM — `03 § 1` Implementation outline + Validation rows ใช้ Bucket B "documented per case" framing stale

**Location:** `docs/design-docs/03-deep-dive.md` § 1.3 Implementation outline (line 43) + § 1.5 Validation (lines 57, 59)

**Problem:**
3 sites ใน Challenge 1 ("Behavioral Parity Preservation"):

(a) Line 43 — Implementation outline row:
> *"| Bug-fix bucket B documentation per case | QA Phase 3T | per-fix |"*

(b) Line 57 — Validation:
> *"- **Bucket A target:** ≤ 25% Net Profit drift (NFR-1.1) — primary acceptance"*

(c) Line 59 — Validation:
> *"- **Bucket B:** documented separately per fix; PF ไม่ลด, Max DD% ไม่เพิ่ม (NFR-1.8)"*

(a) frames "Bucket B documentation per case" เป็น QA deliverable — มิรเรอร์ pre-BT-001 BR-7.1/7.2 validation hints ที่ BA rebuttal-04 รื้อแล้ว ("portfolio-level drift roll up via NFR-1.1 Bucket A; NFR-1.8 informational delta optional")

(c) ระบุ "Bucket B: documented separately per fix; PF ไม่ลด, Max DD% ไม่เพิ่ม" — PF/DD thresholds ตอนนี้อยู่ใต้ NFR-1.2/1.5 Bucket A (portfolio-level บน G4-ON build); Bucket B ไม่ require per-fix doc unless partial G4-OFF window runnable

(b) basically correct (25% Bucket A gate), แต่ลาก context ของ (a)(c) ที่ผิด → reader build mental model "2-track contract" → QA over-engineer

**Why this matters:**
`03` Challenge 1 = primary "behavioral parity" pin ที่ TD Phase 1D + Impl Engineer + QA Phase 3T ใช้เป็น single source of "ทำอย่างไรไม่ให้ drift". Stale Bucket B framing ที่ 3 sites = full-column drift mental model (Implementation outline row + Validation list ติดกัน 2 sites). Compared to BA `04 § BR-7.1/7.2 Validation hints` ที่ rebuttal-04 ระบุชัด "NFR-1.8 informational delta optional" — `03` ที่ stale = SD voice ขัด BA voice ทั้ง pillar

**Minimum acceptable fix:**
Rewrite 3 sites:

```markdown
# Line 43 — Implementation outline row:
| Bucket A measurement (rewrite-G4-ON build) absorbs G4 fix contribution; NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable per BT-001 + IMPL-062 Run #2) | QA Phase 3T | per-fix observability (informational) |

# Line 57 — Validation (clarify G4-ON build):
- **Bucket A target:** ≤ 25% Net Profit drift (NFR-1.1) บน rewrite default build (G4 fixes ON, single-pass per BT-001 2026-05-12) — primary acceptance

# Line 59 — Validation rewrite:
- **Bucket B:** Informational delta (NFR-1.8) `rewrite-G4-ON − rewrite-G4-OFF` — sign + magnitude ของ G4 fix contribution ถ้า partial G4-OFF window measurable; **no acceptance gate** (Should priority post-BT-001). Portfolio-level PF (NFR-1.2 ≤ 0.2 drop) + Max DD (NFR-1.5 ≤ +10pp) gate via Bucket A measurement
```

**Effort:** Low (3 site rewrites — same paragraph)

---

### Claim 05.8: 🟡 MEDIUM — `05 § 6` Operational Risks detection threshold "Bucket B drift > 25% Net Profit" stale gate

**Location:** `docs/design-docs/05-security.md` § 6 Operational Risks (line 205)

**Problem:**
Operational Risks table row:

> *"| Bug-fix changes (ADR-009 BI SL, BR-7.2 J magic) cut profitable trades unexpectedly | **Bucket B drift > 25% Net Profit** | NFR-1.8 + `trading-baseline.md § Validation` — user re-decides if so |"*

Detection threshold "Bucket B drift > 25% Net Profit" = pre-BT-001 gate ที่:
1. **ไม่มี gate post-BT-001** — NFR-1.8 informational only, ไม่มี 25% trigger
2. **Wrong axis** — แม้ pre-BT-001 25% threshold คือ Bucket A gate, ไม่ใช่ Bucket B
3. **Stale cross-ref** — `trading-baseline.md § Validation` framing พึ่ง 2-bucket deviation budget ที่ BA Glossary `01 § 8 line 216` deprecate

Mitigation cell "user re-decides if so" = stale trigger (depend on missing 25% gate)

**Why this matters:**
`05 § 6` = operational risk catalogue ที่ Red Team reviewer + QA Phase 3T scan สำหรับ detection rules. Detection threshold ที่ผิด → Red Team finding gap; QA monitoring rule design ตาม stale threshold → false-positive หรือ never-trigger (ขัดเจตนาเดิม). Mirror BA rebuttal-04 Claim 04.6 ที่ rewrite BR rule-type-tag legend + BR-7 intro

**Minimum acceptable fix:**
Rewrite row:

```markdown
| Bug-fix changes (ADR-009 BI SL, BR-7.2 J magic) cut profitable trades unexpectedly | NFR-1.1 Bucket A drift > 25% Net Profit บน rewrite-G4-ON build (G4 fix contribution included per BT-001) | NFR-1.1 Bucket A gate; NFR-1.8 informational delta sign+magnitude record ถ้า partial G4-OFF window measurable — user investigates journal `signal_context` of BI/J entries หากตี gate |
```

**Effort:** Low (single row rewrite)

---

### Claim 05.9: 🟡 MEDIUM — `08 § 3` Phase Hints P4 rationale "baseline vs rewrite (with + without G4)" stale 2-pass framing

**Location:** `docs/design-docs/08-product-breakdown.md` § 3 Suggested P4 (line 245)

**Problem:**
P4 bullet item:

> *"- **IMPL-061..068** (QA validation suite) — reason: regression after E2-E8 complete; **baseline vs rewrite (with + without G4)**"*

"baseline vs rewrite (with + without G4)" = exact 2-pass verification framing ที่ BA `04 § BR-9.5` invariant เคยใช้ + rebuttal-04 Claim 04.1 rewrite เป็น "single-pass measurement บน rewrite-G4-ON build เท่านั้น"

SD Phase Hint rationale = guidance ที่ Impl Planner consume → ถ้า read literal "with + without G4" 2-pass mental model → schedule dual headless test config + reserve compute budget สำหรับ G4-OFF run ที่ IMPL-062 Run #2 พิสูจน์ unmeetable

**Why this matters:**
Phase Hint rationale = Impl Planner advisory input. Stale rationale = Impl Planner over-scope P4 with dual-build matrix → wasted spike + cross-doc drift กับ BR-9.5 (BA single-voice ตั้งแต่ rebuttal-04). Compounds IMPL-062/063 Claims 05.1/05.2 ที่ task description ผิด — รวมแล้ว 3 sites ใน 08 ที่ Phase 3T scope ไหลผิด direction

**Minimum acceptable fix:**
Rewrite P4 rationale:

```markdown
- **IMPL-061..068** (QA validation suite) — reason: regression after E2-E8 complete; **single-pass measurement บน rewrite default build (G4 fixes ON)** per NFR-1.1 Bucket A (BT-001 re-baseline 2026-05-12); IMPL-063 informational delta `rewrite-G4-ON − rewrite-G4-OFF` ถ้า partial G4-OFF window measurable
```

**Effort:** Low (single bullet rewrite)

---

### 🔵 LOW

---

### Claim 05.10: 🔵 LOW — `02 § 2` Architectural Pillar #1 "Behavioral parity (G3)" ไม่ระบุ "rewrite-G4-ON build" clarification post-BT-001

**Location:** `docs/design-docs/02-high-level-architecture.md` § 2 Architectural Pillars (line 137)

**Problem:**
Pillar #1:

> *"1. **Behavioral parity (G3)** — 5-yr backtest 2021-2025 EURUSD H4 บน FBS-Real ต้องไม่ deviate Net Profit > 25% (Bucket A) จาก baseline $24.27M; PF ≥ 8.76; Max Equity DD% ≤ 16.39%. ทุก architecture decision ที่กระทบ slot logic ต้อง defendable ผ่านมุมนี้"*

Literal 25% Bucket A gate ยังถูก post-BT-001 (semantic redefine ไม่กระทบ threshold value); แต่ phrase "Bucket A" ใน isolation = ambiguous post-BT-001:
- Reader ที่ไม่ทราบ BT-001 → infer "unintended rewrite drift" (pre-BT-001 framing) → assume separate Bucket B budget exists
- Cite "rewrite default build (G4 fixes ON)" + BT-001 = primary architectural pillar pin จะ unambiguous

LOW เพราะ literal threshold value ถูก + ADR-009 + Glossary cascade fix subsume — pillar ไม่ functional defect; ปรับเพื่อ readability post-cascade

**Why this matters:**
`02 § 2` "Architectural Pillars" = ระดับสูงสุดของ ห้ามพัง list ที่ Architect/TD/QA อ่านก่อน drill. Reader ใหม่ post-2026-05-12 อ่าน pillar ที่ ไม่มี BT-001 cite → mental model build จาก pre-BT-001 Bucket A definition → ลด confidence ของ post-cascade single voice. Pure readability + audit-trail enhancement

**Minimum acceptable fix:**
Append clarification clause:

```markdown
1. **Behavioral parity (G3)** — 5-yr backtest 2021-2025 EURUSD H4 บน FBS-Real ต้องไม่ deviate Net Profit > 25% (Bucket A — **rewrite default build with G4 fixes ON, single-pass measurement per BT-001 2026-05-12**) จาก baseline $24.27M; PF ≥ 8.76; Max Equity DD% ≤ 16.39%. ทุก architecture decision ที่กระทบ slot logic ต้อง defendable ผ่านมุมนี้
```

**Effort:** Low (single clause insertion)

---

### Claim 05.11: 🔵 LOW — Last-updated headers ไม่ bump despite BT-001 cascade pending (mirror BA Claim 04.11)

**Location:** `02-high-level-architecture.md` line 5, `03-deep-dive.md` line 5, `05-security.md` line 5, `08-product-breakdown.md` line 5, `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` Date row

**Problem:**
5 docs ที่ Round 05 cascade scope ยังคง:

```
> **Last updated:** 2026-05-02
```

(ADR-009 ใช้ Date row `| **Date** | 2026-05-02 |` — equivalent metadata)

ขณะที่ BA `01/02/04` headers bumped เป็น `2026-05-12 (BT-001 cascade — ...)` ตาม rebuttal-04 ทั้งหมด. SD-side propagation pending. Reader scan SD headers จะ infer BT-001 = BA-only rework + SD ไม่กระทบ — ขัดความจริง (`backtrack-log.md § Impacted phases — SD` enumerate SD lines explicit)

**Why this matters:**
Last-updated = audit trail metadata. Stale dates ที่ 5 SD files ที่มี content drift จาก BT-001 = misleading audit trail; Round 04 → Round 05 transition จะดูเหมือน "SD ไม่กระทบ" ขณะที่ในความจริง 11 sites stale. Low severity เพราะหลังจาก rebuttal applies fixes header bumps pro forma. ไม่ block downstream แต่ damage discoverability

**Minimum acceptable fix:**
หลังจาก rebuttal applies Claims 05.1-05.10, bump 5 headers:

```markdown
# 02/03/05/08 line 5:
> **Last updated:** 2026-05-12 (BT-001 cascade — Bucket A/B propagation: Glossary `02 § 8` + ADR Digest `02 § 9` + NFR traceability `02 § 1.2` + Pillar `02 § 2` + Challenge 1 `03 § 1` + Operational Risk `05 § 6` + IMPL-062/063 + Phase Hint P4 `08 § 1.10 + 3 + 4`)

# ADR-009 add Amendment row:
| **Amendment** | 2026-05-12 — Validation + Consequences + Revisit-when sections cascade-updated per BT-001 (BA NFR-1.1 + NFR-1.8 re-baseline) — Bucket B framing demoted, Revisit-when trigger re-anchored to Bucket A |
```

**Effort:** Low (5 header bumps ทำพร้อมกับ rebuttal content edits)

---

## Cross-Document Issues

| Check | Result |
|-------|--------|
| Bucket A semantic ระหว่าง BA `01 § 8 Glossary` (post rebuttal-04) vs SD `02 § 8 Glossary` | ❌ **Direct conflict** — BA "Includes G4 fix" / SD "unintended drift only" |
| Bucket B semantic ระหว่าง BA `01 § 8 Glossary` vs SD `02 § 8 Glossary` vs ADR-009 § Consequences | ❌ **3-way conflict** — BA "informational delta no gate" / SD "separate budget document แยก" / ADR-009 "drift > 25% re-decide" |
| Bucket A measurement contract ระหว่าง BA `03 § NFR-1.1 Verification` vs SD `08 IMPL-062 task` | ❌ **Direct conflict + empirical-unmeetable** — BA ห้าม DISABLE_G4_FIXES build / SD IMPL-062 บังคับ "rewrite without G4 fixes vs baseline" (Run #2 proves unmeetable) |
| Bucket B measurement contract ระหว่าง BA `02 § FR-3.3/3.4 AC` + `04 § BR-7.1/7.2 Validation hints` vs SD `08 IMPL-063 task` | ❌ **Wrong axis + stale gate** — BA "informational delta optional, G4-ON − G4-OFF partial window" / SD "rewrite (with G4) vs baseline + re-decide if drift > 25%" |
| NFR-1.8 priority (Must vs Should) ระหว่าง BA `03 § TL;DR + § 9 Summary + overview.md` vs SD `08 IMPL-063 metadata risk` | ❌ **Conflict** — BA "Should informational" / SD "high risk + user re-decide trigger" |
| ADR-009 Revisit-when trigger vs BA `03 § NFR-1.8` post-BT-001 | ❌ **Stale trigger** — ADR-009 "Bucket B > 25% re-decide" / NFR-1.8 ไม่มี 25% threshold |
| BR-9.5 invariant alignment (1-pass vs 2-pass) ระหว่าง BA `04 § BR-9.5` (post rebuttal-04) vs SD `08 § 3 P4 Phase Hint rationale` | ❌ **Conflict** — BA "single-pass บน G4-ON" / SD "baseline vs rewrite (with + without G4)" |
| Round 03 cascade (cumulative counter cumulative-survives-restart) — verified post-BT-001 stability | ✅ Stable — `04 § 4.1` mermaid note + `05 § 7.2` 2 threshold rows ยังคง post-rebuttal-03 wording |
| Schedule-leakage check | ✅ Clean — single false-positive (`IMPL-067 — DST regression run 10 transitions Mar 2021 → Oct 2025` = dataset description) |
| BI SL semantic "same SL distance" (OQ-3.3) | ✅ Consistent — ADR-009 arithmetic + `02 § 1.4` OQ resolution map + BA `04 BR-7.1` unchanged across BT-001 |
| Slot U deletion (OQ-8) | ✅ Consistent — `08 § 1.3` + ADR-005 + BA `02 FR-2.2` aligned |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 05.1 | 🔴 CRITICAL | IMPL-062 task description "rewrite (without G4 fixes) vs baseline" = pre-BT-001 framing + Run #2 unmeetable | `08-product-breakdown.md` line 129 | Low |
| 05.2 | 🔴 CRITICAL | IMPL-063 task description "rewrite (with G4) vs baseline → Bucket B drift" + "re-decide if drift > 25%" wrong axis + stale gate | `08-product-breakdown.md` lines 130, 294 | Low |
| 05.3 | 🔴 CRITICAL | SD Glossary "Bucket A drift" + "Bucket B drift" direct conflict กับ BA Glossary post-rebuttal-04 | `02-high-level-architecture.md` lines 441, 442 | Low |
| 05.4 | 🟠 HIGH | ADR-009 § Validation + § Consequences + § Revisit-when ใช้ Bucket B "> 25% re-decide" gate ที่ BT-001 ยกเลิก | `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md` lines 91, 95, 107, 115 | Low |
| 05.5 | 🟠 HIGH | `02 § 9` ADR Digest row ADR-009 Trade-off + Revisit-when cells stale | `02-high-level-architecture.md` line 469 | Low |
| 05.6 | 🟠 HIGH | `02 § 1.2` NFR Traceability row "bucket B drift via ADR-009" implies budget deliverable | `02-high-level-architecture.md` line 71 | Low |
| 05.7 | 🟡 MEDIUM | `03 § 1` Implementation outline + Validation 3 sites ใช้ Bucket B "documented per case" stale | `03-deep-dive.md` lines 43, 57, 59 | Low |
| 05.8 | 🟡 MEDIUM | `05 § 6` Operational Risks detection "Bucket B > 25%" stale gate | `05-security.md` line 205 | Low |
| 05.9 | 🟡 MEDIUM | `08 § 3` Phase Hint P4 rationale "baseline vs rewrite (with + without G4)" stale 2-pass framing | `08-product-breakdown.md` line 245 | Low |
| 05.10 | 🔵 LOW | `02 § 2` Architectural Pillar #1 ไม่ระบุ "rewrite-G4-ON build" post-BT-001 readability | `02-high-level-architecture.md` line 137 | Low |
| 05.11 | 🔵 LOW | 5 SD docs Last-updated ไม่ bump despite BT-001 cascade pending | `02/03/05/08` line 5 + ADR-009 Date row | Low |

---

## Closure Statement

**SD Phase 1B — REWORK NEEDED post-BT-001 cascade.**

Round 04 → Round 05 transition:
- Round 04 (2026-05-02) closed clean (0 finding — verify-only sweep post rebuttal-03; ไม่ต้อง rebuttal-04) — SD package was internally consistent pre-BT-001
- BT-001 (2026-05-12) rebaseline applied **only to BA `03` + cascade ผ่าน rebuttal-04 ลง BA `01/02/04 + overview.md`** — BA package ปิด clean ที่ `ba/claim-review-05.md` (0 finding)
- BT-001 explicit ระบุ SD impacted lines ใน `docs/state/backtrack-log.md § Impacted phases — SD` (HLA lines 71/137/441/442/469; deep-dive lines 11/19/57/59/308; product-breakdown IMPL-062/063 + Phase Hint)
- Round 05 = first SD review post-BA-cascade-close → caught **11 cascade propagation gaps** (3 CRITICAL contract conflicts + 3 HIGH primary references + 3 MEDIUM doc-detail drift + 2 LOW readability + audit-trail metadata)

**Trajectory caveat (mirror BA Round 04 framing):** Round 05 finding count (11) is NOT a regression of Round 04's clean closure — it is the first scan that surfaces post-BT-001 SD work-in-progress state. SD cascade discipline (state reconciliation per CLAUDE.md § 6 + ADR amendment per `workflow.md § ADR Discipline`) requires BT-001 → SD propagation; **0 SD doc bumped + 0 ADR amended** ก่อน Round 05.

**Recommended action sequence:**

1. **`/sd-rebuttal claim-review-05.md`** — apply Claims 05.1-05.11 (all Low effort, single-paragraph or single-row edits; total estimated ≤ 60 min across 6 files: `02-high-level-architecture.md`, `03-deep-dive.md`, `05-security.md`, `08-product-breakdown.md`, `docs/adr/009-bi-sl-inheritance-pip-arithmetic.md`, `docs/state/overview.md` row)
2. Re-run **`/sd-review all`** as Round 06 → expect 0 findings (clean closure mirroring Round 03 → Round 04 pattern after rebuttal + mirroring BA Round 04 → Round 05 pattern at the BA cascade)
3. Update `docs/state/overview.md` Phase Status row **Design (SD)**: append `+ Round 06 (post-BT-001 cascade clean)` after Round 06 pass
4. Then proceed to `/td-review all` + `/qa-review all` per BT-001 downstream chain (`ba/claim-review-05.md § Recommended action sequence`) — TD `02-backend-design § 13` Strategy Tester audit contract + QA Plan ต้อง verify Bucket A measurement = single-pass G4-ON (ไม่ใช่ 2-pass with/without G4)
5. After SD Round 06 + downstream pass → close BT-001 entry ใน `backtrack-log.md` (Resolution column populated)

**TD/QA risk if NOT remediated:**
- TD Phase 1D อ่าน ADR-009 Validation section + ADR Digest Revisit-when → design TD audit contract สำหรับ Bucket B per-fix documentation step → over-engineered dual-build matrix
- TD `02-backend-design § 13.6` Strategy Tester audit contract มี likelihood ที่ require `simulation/headless-tests/regression_5yr_no_g4.ini` config (DISABLE_G4_FIXES) → committed config ที่ Run #2 พิสูจน์ unmeetable
- QA Phase 3T อ่าน IMPL-062 task description ตามตัวอักษร → run DISABLE_G4_FIXES headless backtest → HALTED at sim 2021-01-14 via CircuitBreaker → false-failure cascade (deja vu ของ Run #2 finding)
- Impl Engineer (Phase 3I) อ่าน Phase Hint P4 rationale + SD Glossary → infer pre-BT-001 Bucket B separate budget mental model → Phase 3T gate design ผิด

> **End of Claim Review Round 05** — 11 findings (3 🔴 / 3 🟠 / 3 🟡 / 2 🔵), all post-BT-001 cascade propagation gaps. Run `/sd-rebuttal claim-review-05.md` to apply cascade fixes. Mirror BA Round 04 (11) → Round 05 (0) convergence trajectory expected.
