# BA Rebuttal Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Claim Review** | `claim-review-04.md` |
| **Date** | 2026-05-12 |
| **SKILLs** | andm-ba-defender, business-analyst, brainstorming, research-engineer, documentation-templates |
| **Trigger** | BT-001 (2026-05-12) cascade propagation gap — `03` updated, `01/02/04 + overview.md` not |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 11 |
| Partial | 0 |
| Rejected | 0 |

**Accept rate:** 100% (all 11 claims = factual stale-framing gaps from BT-001 cascade ที่ยังไม่ propagate). Sanity check ผ่าน per `andm-ba-defender § Sanity Checks` — Accept rate > 50% **expected** เพราะ BT-001 backtrack เป็น semantic re-baseline ที่ก่อ cascade ใน 4 files; reviewer round-prior (Round 03 ปิด clean) แสดงว่า BA package เคย internally consistent → finding spike Round 04 = work-in-progress state ไม่ใช่ quality regression.

**Files modified:**
- `docs/ba/01-project-brief.md` — 5 changes (line 5 header / line 60 G4 KPI / lines 208-209-216 Glossary 3 entries / line 279 reference table)
- `docs/ba/02-functional-requirements.md` — 4 changes (line 5 header / line 288 FR-3.3 Why / lines 298-300 AC-3.3.3 / lines 319-321 AC-3.4.3)
- `docs/ba/04-business-rules.md` — 6 changes (line 5 header / line 31 rule type tag legend / line 422 BR-7 intro / line 433 BR-7.1 validation hint / line 445 BR-7.2 validation hint / line 530 BR-9.5 invariant)
- `docs/state/overview.md` — 1 change (line 10 Phase Status row: NFR count M=26 → M=25 + add rebuttal-04 entry)

**Total:** 16 edits ข้าม 4 files. ทุก edit minimum-acceptable per reviewer's specified fix.

---

## Claim Responses

### Claim 04.1: BR-9.5 invariant ขัด NFR-1.1 Verification (BT-001)
**Verdict:** Accept

**Rationale:** BR-9.5 invariant clause `"ตรวจ 2 รอบ: (a) without G4 fixes, (b) with G4 fixes"` ขัดตรง ๆ กับ NFR-1.1 Verification ที่ระบุ `"ห้ามใช้ #define DISABLE_G4_FIXES build"` (BT-001 ห้ามชัด + IMPL-062 Run #2 empirical แสดง DISABLE_G4_FIXES build halt ก่อน complete window). Invariant ที่ contradict NFR contract = block downstream design — เกณฑ์ Accept ชัดเจน.

**Changes Made:**
- File: `docs/ba/04-business-rules.md`, Section: § 10 BR-9.5 (line 528-531)
- What changed: Rewrite invariant clause จาก "2-pass verification" → "single-pass measurement บน rewrite-G4-ON build เท่านั้น"; Bucket B reframed เป็น informational delta (no acceptance gate); เพิ่ม cite BT-001 + IMPL-062 Run #2 evidence + cross-ref `03 § NFR-1 Empirical Citation`.
- Evidence (new text): *"**Invariant:** Backtest 2021-2025 EURUSD H4 ของ rewrite default build (G4 fixes ON) อยู่ใน regression budget (NFR-1.1 ถึง NFR-1.7) — **single-pass measurement บน rewrite-G4-ON build เท่านั้น** (BT-001 re-baseline 2026-05-12; `DISABLE_G4_FIXES` build halts pre-window per IMPL-062 Run #2 → ห้ามใช้เป็น verification vehicle ต่อ NFR-1.1). Bucket B (NFR-1.8) = **informational delta** ที่ record sign + magnitude ถ้า `DISABLE_G4_FIXES` build รัน partial pre-CircuitBreaker window ได้ — ไม่ใช่ acceptance gate."*

---

### Claim 04.2: AC-3.3.3 framing "ไม่นับใน Bucket A" ขัด BT-001
**Verdict:** Accept

**Rationale:** Post-BT-001 Bucket A semantic = `rewrite-G4-ON vs baseline` (G4 fix contribution **included**). AC-3.3.3 clause "ไม่นับใน 25% pattern parity bucket A" + "bucket B drift documented" ใช้ pre-BT-001 framing ที่แยก G4 fix contribution ออกจาก Bucket A. QA agent อ่าน AC ตามตัวอักษรจะ design 2 measurements ที่ NFR-1.1 Verification ห้าม. Direct internal contradiction → AC untestable.

**Changes Made:**
- File: `docs/ba/02-functional-requirements.md`, Section: § FR-3.3 AC-3.3.3 (line 298-300)
- What changed: Rewrite AC ทั้ง paragraph จาก "bucket B drift documented; ไม่นับใน Bucket A" → "NFR-1.1 Bucket A gate (rewrite-G4-ON, G4 fix included) + NFR-1.2 PF + NFR-1.5 DD + NFR-1.8 informational delta (optional partial G4-OFF window)".
- Evidence (new text): *"**AC-3.3.3:** Given QA regression run บน rewrite default build (G4 fixes ON) / When เปรียบเทียบ Net Profit + PF + DD กับ baseline / Then NFR-1.1 Bucket A gate ใช้ได้ (|ΔNet Profit| ≤ 25% บน rewrite-G4-ON build, G4 fix contribution included); NFR-1.2 PF ลดลง ≤ 0.2 จุด; NFR-1.5 Max Equity DD% ไม่เพิ่ม > +10pp; NFR-1.8 informational delta (G4-ON − G4-OFF) บันทึก sign + magnitude ถ้า partial G4-OFF window measurable ก่อน CircuitBreaker BR-3.6 trigger (BT-001 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`)"*

---

### Claim 04.3: AC-3.4.3 "drift นับใน bucket B" ผิด BT-001 informational reframing
**Verdict:** Accept

**Rationale:** AC-3.4.3 ตอนเดิม restate Bucket B framing ผิด layer — ExtraTakeProfit_J magic fix เป็น single intentional change ที่ contribute เข้า Bucket A overall (post-BT-001 G4-ON default), per-slot J/F distribution check ควรอยู่ที่ NFR-1.6 framework (±15% / >30% investigation flag), portfolio-level อยู่ที่ NFR-1.2/1.5. AC restate Bucket B framing ผิด layer ทั้งคู่.

**Changes Made:**
- File: `docs/ba/02-functional-requirements.md`, Section: § FR-3.4 AC-3.4.3 (line 319-321)
- What changed: Rewrite AC paragraph จาก "drift นับใน bucket B (intentional fix); portfolio-level: PF ไม่ลด, Max DD% ไม่เพิ่ม" → "per-slot drift NFR-1.6 tolerance + portfolio-level NFR-1.2/1.5 + NFR-1.8 informational delta optional".
- Evidence (new text): *"**AC-3.4.3:** Given regression result บน rewrite default build (G4 fixes ON) / When เปรียบเทียบ J slot + F slot trade count + win rate + Net Profit กับ baseline / Then per-slot drift J/F อยู่ใน NFR-1.6 tolerance (±15% / >30% investigation flag / ±2 absolute ถ้า baseline < 5 trades); portfolio-level NFR-1.2 PF ลดลง ≤ 0.2 จุด, NFR-1.5 Max Equity DD% ไม่เพิ่ม > +10pp; NFR-1.8 informational delta (G4-ON − G4-OFF) บันทึก J/F contribution sign + magnitude ถ้า partial G4-OFF window measurable (BT-001 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`)"*

---

### Claim 04.4: Glossary 3 entries (Bucket A drift / Bucket B drift / Bug-fix bucket) stale
**Verdict:** Accept

**Rationale:** Glossary `01 § 8` = single source of truth สำหรับ BA package terminology — `04` BR section ระบุ "Reads: `01-project-brief.md (glossary)`". Stale Glossary = single point of corruption ที่ contaminate ทุก reader downstream (Architect/TD/QA). 3 entries ติดกัน ใช้ pre-BT-001 framing ทุกตัว (Bucket A "unintended drift" / Bucket B "separate budget" / Bug-fix bucket "2-bucket deviation budget").

**Changes Made:**
- File: `docs/ba/01-project-brief.md`, Section: § 8 Glossary (lines 208, 209, 216)
- What changed: 
  - Line 208 "Bucket A drift" — เปลี่ยน "unintended rewrite drift" → "rewrite default build (G4 fixes ON) เทียบ legacy baseline... **Includes** intentional G4 fix contribution"
  - Line 209 "Bucket B drift" — เปลี่ยน "separate budget, document แยกแต่ละ case" → "Informational delta `rewrite-G4-ON − rewrite-G4-OFF`... **no acceptance gate** per NFR-1.8 (Should priority)"
  - Line 216 "Bug-fix bucket" — mark "(deprecated post-BT-001 2026-05-12)" + redirect ไปยัง NFR-1.8 + `03 § NFR-1 Empirical Citation`
- Evidence (new text — Bucket A drift): *"Behavioral deviation ของ rewrite default build (G4 fixes ON) เทียบ legacy baseline — ต้อง ≤ 25% Net Profit per NFR-1.1 (regression contract). **Includes** intentional G4 fix contribution (BT-001 re-baseline 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`)"*

---

### Claim 04.5: Goal G4 KPI row stale "bucket B ของ regression budget" — primary contract
**Verdict:** Accept

**Rationale:** G4 row Success KPI = primary success contract ของ goal ที่ 4 ที่ stakeholder + Architect อ่านก่อน drill ลง NFR/BR. Stale KPI ที่ contract level → ทุก reader ที่ไม่ drill ลง `03` empirical citation block จะ infer Bucket B budget mental model ผิด.

**Changes Made:**
- File: `docs/ba/01-project-brief.md`, Section: § 3 Goals & Success KPIs (line 60, G4 row Success KPI column)
- What changed: Rewrite KPI cell trailer "Drift จาก fix นี้นับใน bucket B ของ regression budget (แยกจาก 25% pattern parity)" → "G4 fix contribution วัดผ่าน **NFR-1.1 Bucket A** (rewrite-G4-ON vs baseline ≤ 25%, default build, fix contribution included) + **NFR-1.8 informational delta** (no acceptance gate, post-BT-001 re-baseline 2026-05-12)". เพิ่ม cite OQ-3.3 lock + BR-7.1 cross-ref.
- Evidence (new text): *"(a) `BI` orders ต้องมี SL อิง parent `B` slot (semantic locked "same SL distance" per OQ-3.3 — `04 § BR-7.1`); (b) `ExtraTakeProfit_J` iterate `MagicJ` (=206), ไม่ใช่ `MagicF` (=201). G4 fix contribution วัดผ่าน **NFR-1.1 Bucket A** (rewrite-G4-ON vs baseline ≤ 25%, default build, fix contribution included) + **NFR-1.8 informational delta** (no acceptance gate, post-BT-001 re-baseline 2026-05-12)"*

---

### Claim 04.6: Rule type tag legend + BR-7 intro framing Bucket B ผิด (2 structural sites)
**Verdict:** Accept

**Rationale:** Rule type tag legend (line 31) = vocabulary ของทั้ง `04` doc — ผิดที่ legend = ผิดทั้ง doc transit ทุก ⚠️ BR. BR-7 intro (line 422) = mental model ของผู้อ่าน BR-7 section. ทั้งคู่ propagation ที่ structural level (not single rule).

**Changes Made:**
- File: `docs/ba/04-business-rules.md`, Section: § 1 Rule type tag (line 31) + § 8 BR-7 intro (line 422)
- What changed:
  - Line 31 — เปลี่ยน "drift นับใน Bucket B" → "drift รวมอยู่ใน NFR-1.1 Bucket A measurement บน rewrite-G4-ON default build; NFR-1.8 Bucket B = informational delta only"
  - Line 422 — ลบ phrase "drift นับใน Bucket B ของ regression budget" + rewrite เป็น "G4 fix contribution วัดผ่าน NFR-1.1 Bucket A... + NFR-1.8 informational delta"; เพิ่ม cite `03 § NFR-1 Empirical Citation`
- Evidence (new text — line 31): *"⚠️ **Bug-fix** — intentional change per G4 (drift รวมอยู่ใน NFR-1.1 Bucket A measurement บน rewrite-G4-ON default build; NFR-1.8 Bucket B = informational delta only, post-BT-001 re-baseline 2026-05-12)"*

---

### Claim 04.7: FR-3.3 Why-line "แยกจาก 25% ceiling" stale
**Verdict:** Accept

**Rationale:** Why-line = rationale ที่ Architect ใช้ตัดสินใจ trade-off (e.g., "ควรเก็บ DISABLE_G4_FIXES build target?"). Stale framing → Architect infer DISABLE_G4_FIXES first-class build จาก rationale → wasted spike investigation.

**Changes Made:**
- File: `docs/ba/02-functional-requirements.md`, Section: § FR-3.3 Why (line 288)
- What changed: Rewrite Why clause tail (after "user decision 2026-05-01 = FIX (G4);") จาก "drift จาก fix นี้นับใน bucket B ของ regression budget แยกจาก 25% ceiling" → "G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (≤ 25% บน rewrite-G4-ON default build) + NFR-1.8 informational delta".
- Evidence (new text): *"...user decision 2026-05-01 = **FIX** (G4); G4 fix contribution วัดผ่าน NFR-1.1 Bucket A (≤ 25% บน rewrite-G4-ON default build) + NFR-1.8 informational delta (BT-001 re-baseline 2026-05-12 — ดู `03 § NFR-1 Empirical Citation`)"*

---

### Claim 04.8: BR-7.1/7.2 Validation hints "bucket B drift documented" stale (2 sites)
**Verdict:** Accept

**Rationale:** Validation hint = QA recipe ที่ agent อ่านแล้ว implement check. Stale framing → QA over-engineer Bucket B documentation step ที่ BT-001 ลด priority ลงเป็น optional. Compounding effect ทั้ง BR-7.1 + BR-7.2.

**Changes Made:**
- File: `docs/ba/04-business-rules.md`, Section: § 8 BR-7.1 (line 433) + § 8 BR-7.2 (line 445)
- What changed:
  - BR-7.1 — เปลี่ยน "bucket B drift documented" → "portfolio-level drift roll up via NFR-1.1 Bucket A (rewrite-G4-ON build); NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable)"
  - BR-7.2 — เปลี่ยน "bucket B drift documented" → "per-slot J/F drift check via NFR-1.6 (rewrite-G4-ON build); NFR-1.8 informational delta optional"
- Evidence (new text — BR-7.1): *"QA inspect BI trade journal entries — `sl > 0` ทุกราย; verify `(BI_entry - BI_sl)` ≈ `(B_entry - B_sl)` ใน pip distance; portfolio-level drift roll up via NFR-1.1 Bucket A (rewrite-G4-ON build); NFR-1.8 informational delta optional (record เฉพาะ partial G4-OFF window measurable)"*

---

### Claim 04.9: Reference Materials description "2-bucket deviation budget" stale
**Verdict:** Accept

**Rationale:** `01 § 9` Reference Materials = canonical entry-point ที่ sponsor/PM browse ก่อนรู้จะอ่าน source ไหน. Stale description ที่ entry-point → user infer 2-bucket budget mental model ก่อนเปิด NFR-1.x.

**Changes Made:**
- File: `docs/ba/01-project-brief.md`, Section: § 9 Reference Materials (line 279, `trading-baseline.md` row)
- What changed: Rewrite description cell จาก "Regression contract + 2-bucket deviation budget (Bucket A pattern parity, Bucket B intentional bug-fix)" → "Regression contract + Bucket A (rewrite-G4-ON vs baseline per NFR-1.1) + Bucket B (informational delta per NFR-1.8 — no acceptance gate, post-BT-001 re-baseline 2026-05-12)".
- Evidence (new text): *"Regression contract + Bucket A (rewrite-G4-ON vs baseline per NFR-1.1) + Bucket B (informational delta per NFR-1.8 — no acceptance gate, post-BT-001 re-baseline 2026-05-12)"*

---

### Claim 04.10: overview.md NFR count M=26 stale post-BT-001 demote
**Verdict:** Accept

**Rationale:** overview.md = derived view ที่ status agents + `/next` รัน scan first; per CLAUDE.md § 6 State Reconciliation Discipline 3-file rule, BT-001 rework ใน `03` (NFR-1.8 Must→Should) ต้อง propagate ไป overview.md. Reviewer scope note ที่ระบุว่า `overview.md` อยู่นอก `docs/ba/` แต่ Cross-Doc Consistency category #14 บังคับให้ตรวจ derived views ที่อ้าง BA package state — accept ตามเหตุผลนั้น.

**Changes Made:**
- File: `docs/state/overview.md`, Section: Phase Status row "Design (BA)" (line 10)
- What changed: 
  - Row notes "NFR: **30 (M=26 S=4 C=0)**" → "NFR: **30 (M=25 S=5 C=0)** — post-BT-001 NFR-1.8 demote Must → Should"
  - Last Updated bumped: "2026-05-12 (BT-001 + rebuttal-04 cascade)"
  - Status string: "🔄 **BACKTRACK — rework in progress (BT-001)**" → "🔄 **BACKTRACK — rework in progress (BT-001 cascade applied via rebuttal-round-04)**"
  - Notes ต่อท้าย: เพิ่ม row entry "**Rebuttal-04 (2026-05-12)** accepted 11 + 0 reject of 11 claims — BT-001 Bucket A/B cascade propagation..." + cite รายชื่อ sites ที่แก้
- Evidence (new text — count): *"NFR: **30 (M=25 S=5 C=0)** — post-BT-001 NFR-1.8 demote Must → Should"*

---

### Claim 04.11: `01/02/04` Last-updated headers ไม่ bump despite BT-001 cascade pending
**Verdict:** Accept

**Rationale:** Last-updated = audit trail metadata. หลัง Claims 04.1-04.10 apply, headers ต้อง bump pro forma เพื่อ reflect actual content drift. Low severity แต่ accept เพราะ trivial discoverability win + ทำพร้อมกับ content edits.

**Changes Made:**
- File: `docs/ba/01-project-brief.md` (line 5) — bumped พร้อม cascade tag เฉพาะ
- File: `docs/ba/02-functional-requirements.md` (line 5) — bumped พร้อม cascade tag เฉพาะ
- File: `docs/ba/04-business-rules.md` (line 5) — bumped พร้อม cascade tag เฉพาะ
- Evidence (new text — `01` example): *"> **Last updated:** 2026-05-12 (BT-001 cascade — Bucket A/B propagation: glossary `§ 8` + Goal G4 KPI `§ 3` + reference table `§ 9`)"*

---

## Cascaded Changes

ไม่มี cascaded change นอก scope ของ claims ที่ระบุ — reviewer enumerated ครบทุก site (Cross-Document Issues table ใน claim-review-04.md § Cross-Document Issues ระบุ 7 inconsistency rows ที่แมป 1:1 กับ Claims 04.1-04.11).

**Verification — post-fix consistency sweep (Phase 4):**
- Grep `bucket [AB]|Bucket [AB] drift|2-bucket|2 buckets|regression budget|Bug-fix bucket|separate budget` ข้าม `docs/ba/01..05.md` → ทุก hit เป็น (a) BT-001-aware content ใน `03` (canonical source), (b) BT-001-aware content ที่ rebuttal-04 เพิ่งเขียน, หรือ (c) `02 line 265` "lot deviation ใน bucket A" ซึ่งยัง consistent กับ post-BT-001 semantic (unintentional rewrite drift ยังอยู่ใน Bucket A definitionally — ไม่ใช่ stale framing).
- ห้ามมี "separate budget" / "2-bucket" / "นับใน bucket B" residual ใน `01/02/04` → verified ✅ ไม่มี
- BR-9.5 invariant ↔ NFR-1.1 Verification ↔ FR-3.3/3.4 ACs — vocabulary ตรงกันทั้ง 3 site (rewrite-G4-ON build single-pass; G4 fix contribution included in Bucket A; NFR-1.8 informational only)
- Language Rule compliance — ทุก fix preserve Thai narrative + English tech term pattern (ratio unchanged, qualitative pass)

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| **Accept Rate** | 11/11 = 100% | Cascade gap, ไม่ใช่ defensive miss — Round 03 ปิด clean ก่อน BT-001 ดังนั้นทุก finding Round 04 เป็น post-BT-001 propagation gap (expected). Reviewer ถูกทุก claim. |
| **Critical Fixes** | 3/3 closed | BR-9.5 invariant (ขัด NFR-1.1) + AC-3.3.3 (untestable) + AC-3.4.3 (Bucket B layer error) — ทั้งสามเป็น downstream-blocker (QA Phase 3T จะ design gate ผิดถ้าไม่แก้). Resolved. |
| **High Fixes** | 3/3 closed | Glossary (single point of truth) + G4 KPI (primary contract) + Rule legend (cascade to all ⚠️ BR) — wide-blast-radius sites. Resolved. |
| **Medium Fixes** | 4/4 closed | FR-3.3 Why + BR-7.1/7.2 hints + Reference table + overview.md count — narrative + state-reconciliation drift. Resolved. |
| **Low Fixes** | 1/1 closed | Header date bumps × 3 files — metadata hygiene. Resolved. |
| **Net Improvement** | BA package internally consistent post-BT-001 cascade | Bucket A/B semantic 1 voice ทั้ง package (was: 2 voices `03` vs `01/02/04`) — Architect/TD/QA อ่าน BR/AC/Glossary ตามตัวอักษรแล้วจะ infer same mental model. State reconciliation gap closed (overview.md row aligned). |
| **Remaining Gaps** | 0 items | Reviewer-flagged Open Risks ทั้ง 7 cross-doc inconsistency rows = ✅ resolved. ไม่มี deferred work. |

---

## Recommendation

- [x] ✅ **Ready for Architecture Handoff (post Round 05 re-review)** — all CRITICAL/HIGH/MEDIUM/LOW claims resolved; recommend `/ba-review all` Round 05 verify 0 findings (expected clean closure mirroring Round 03 pattern after rebuttal); หลัง Round 05 pass แล้วก็ proceed `/sd-review all` per claim-review-04 § Closure Statement recommended action sequence (BT-001 ยัง impact SD per `backtrack-log.md § Impacted phases — SD`).
- [ ] 🔁 Request Re-Review — N/A (Round 05 ไม่ใช่ request, แต่เป็น mandatory verify cycle ตาม BT-001 backtrack workflow)
- [ ] ⛔ Needs Stakeholder Input — N/A (ไม่มี deferred decision; BT-001 user-approved + IMPL-062 Run #2 empirical evidence solid)

**Architect/TD/QA risk post-rebuttal-04:** RESOLVED — pre-rebuttal risks ที่ reviewer flagged (Architect infer DISABLE_G4_FIXES first-class build; TD over-engineer dual build matrix; QA design 2-pass regression gate ที่ fail reproducibly) ทุกอันมาจาก stale BR-9.5 invariant + AC + glossary; ทั้งสามแก้แล้ว reviewer สามารถ verify ใน Round 05.

---

> **End of Rebuttal Round 04** — 11 claims accepted, 0 partial, 0 rejected; 16 edits ข้าม 4 files (3 BA docs + overview.md); BT-001 cascade propagation closed. Recommend `/ba-review all` Round 05 → expect 0 findings.
