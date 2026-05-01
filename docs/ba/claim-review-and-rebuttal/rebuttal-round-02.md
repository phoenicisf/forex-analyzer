# BA Rebuttal Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Claim Review** | `claim-review-02.md` |
| **Date** | 2026-05-01 |
| **Defender** | BA agent (`andm-ba-defender` persona, `/ba-rebuttal` workflow) |
| **SKILLs** | business-analyst, brainstorming, research-engineer, documentation-templates |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |

**Files modified:**
- `01-project-brief.md` — 3 changes (§ 4 convention scope clarification; § 5.1 cross-slot dependencies wording; § 10.1 NEW — OQ-A1/A2/A3 architecture-domain Q anchor)
- `02-functional-requirements.md` — 12 changes (FR-2.4 / FR-4.2 / FR-6.6 / FR-7.1 / FR-7.2 / FR-7.4 / FR-7.5 / FR-7.6 / FR-8.2 actor rephrase to canonical; AC-2.4.1 wording; § 10 MoSCoW Summary Table FR-2.5/2.7 titles; endnote AC count 44→45)
- `03-non-functional-requirements.md` — 4 changes (NFR-4.2 title + Metric + Verification rephrase; NFR-7.3 verification field deterministic + 10 transitions; § 10 OQ-7 line 510 lock ±2)
- `04-business-rules.md` — 2 changes (§ Rule type tag legend "slot interface"→"slot abstraction"; BR-2.1 Validation hint rephrase)
- `05-user-flows.md` — 3 changes (F5.3 Mermaid line 385 + F5.4 narrative line 395 "slot interface + MarketContext + PortfolioState" → "slot abstraction + MarketContext snapshot + Per-slot state lookup"; § 9 Doc Map line 627 FR-2.5/2.6/2.7 row)
- `docs/state/overview.md` — 1 change (Notes column: status note rebuttal-02 + AC count 45)

**Total claim coverage:** 7/7 — ทุก finding ได้ verdict + action; ไม่มี skip; ไม่มี reject

---

## Claim Responses

### Claim 02.1: 🟠 HIGH — 8 user stories ยังคงใช้ non-canonical actor (Claim 01.10 incomplete)
**Verdict:** Accept

**Rationale:** ตรงกับ evidence ที่ reviewer cite — grep `^\*\*As a\*\*` ใน `02` confirm 8 จุดที่ระบุ + พบเพิ่ม **1 จุดที่ reviewer ลืม** (FR-8.2 line 737 ใช้ `EA system`). Comprehensive sweep applied — ตอนนี้ 0 non-canonical actors เหลือใน `02`.

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § FR-2.4 (line 177): `AI Agent (implementer)` → `Trader, **I want** EA expose dependency relations (...) เป็น explicit `dependsOn(otherSlot)` field ใน slot abstraction, **so that** ผมหรือ AI agent ที่ maintain โค้ดต่อไปไม่ refactor 1 slot โดยลืมว่ามี slot อื่นอ้างถึง`
- File: `docs/ba/02-functional-requirements.md` § FR-4.2 (line 393): `AI Agent / Developer` → `Trader, **I want** EA logger ที่ prepend ... so that ผม grep log ได้แบบ slot-scoped ตอน retrospective + journal สามารถ subscribe จาก log foundation เดียวกัน`
- File: `docs/ba/02-functional-requirements.md` § FR-6.6: `EA system` → `Trader, **I want** EA detect ping-pong ... ไม่เจอ infinite loop ที่กิน balance ตอน live`
- File: `docs/ba/02-functional-requirements.md` § FR-7.1: `EA system` → `Trader, **I want** EA run "Safe port" cleanup ...`
- File: `docs/ba/02-functional-requirements.md` § FR-7.2: `EA system` → `Trader, **I want** EA run alternate cleanup ผ่าน Ichimoku ...`
- File: `docs/ba/02-functional-requirements.md` § FR-7.4: `EA system` → `Trader, **I want** EA demote `ExtraForceModeReason` ...`
- File: `docs/ba/02-functional-requirements.md` § FR-7.5: `EA system` → `Trader, **I want** EA preserve overload helpers ...`
- File: `docs/ba/02-functional-requirements.md` § FR-7.6: `EA system` → `Trader, **I want** EA validate ทุก indicator handle ...`
- File: `docs/ba/02-functional-requirements.md` § FR-8.2 (line 737, **reviewer-missed**): `EA system` → `Trader, **I want** EA cache + incremental update ของ drawdown calculation loop, ... (perf only — behavior ไม่เปลี่ยน)`
- Verified post-fix: `Grep '^\*\*As a\*\* (?!Trader|MT5 Platform|Strategy Tester|Broker)'` → 0 matches ใน `02`

---

### Claim 02.2: 🟡 MEDIUM — MoSCoW Summary Table tech-leak terminology residual (Claim 01.7 incomplete)
**Verdict:** Accept

**Rationale:** ตรงตาม evidence — line 775 `Slot interface` + line 777 `PortfolioState map` ขัดกับ FR-2.5/2.6/2.7 section titles ที่ rewrite แล้วใน rebuttal-01. Reviewer แยก line 776 ออก (MarketContext = concept-level term) — agree, line 776 ใช้ "MarketContext snapshot" ปกติ แต่ผมยังเปลี่ยนเป็น "Indicator snapshot per tick" ให้ตรงกับ section title rewrite (line 210) เพื่อ consistency รอบๆ MoSCoW table.

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § 10 MoSCoW Summary Table (lines 775-777)
- What changed:
  - `FR-2.5 | Slot interface | Must | G1 | §7.2` → `FR-2.5 | Slot abstraction (uniform contract) | Must | G1 | §7.2`
  - `FR-2.6 | MarketContext snapshot | Must | G1, G3 | §7.2` → `FR-2.6 | Indicator snapshot per tick | Must | G1, G3 | §7.2`
  - `FR-2.7 | PortfolioState map | Must | G1, G3 | §7.2` → `FR-2.7 | Per-slot state lookup by magic | Must | G1, G3 | §7.2`
- Cross-doc grep `Slot interface|PortfolioState map|MarketContext map` หลัง fix: ไม่มี match ใน BA docs (active) — consistency ทั้ง package
- ⚠️ **Cascade fixes** (residual ที่เจอใน sweep + ไม่ได้ cite ใน claim — ดู Cascaded Changes ข้างล่าง): NFR-4.2 title + Metric + Verification, BR rule type tag, BR-2.1 Validation hint, `01 § 5.1` cross-slot dependency wording, `02 § FR-2.4` AC-2.4.1, `05 § F5.3/F5.4` Mermaid + narrative, `05 § 9` Doc Map row

---

### Claim 02.3: 🟡 MEDIUM — NFR-7.3 verification field ยังคง vague + DST transition count ขัดกับ FR-6.5
**Verdict:** Accept

**Rationale:** ตรงกับ evidence — NFR-7.3 line 408 ใช้ "4+ DST transitions" + "ไม่พบ unexpected trade" ขัดกับ FR-6.5 AC-6.5.2 (10 transitions, deterministic 00:00–00:05 window check) ที่ rebuttal-01 fix แล้ว. Mirror NFR-7.3 ให้ตรง — point ไป AC-6.5.2/6.5.3 เพื่อให้ source-of-truth เดียว (FR-6.5 owns DST verifier spec; NFR-7.3 enforces).

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § NFR-7.3 Verification field
- What changed: รื้อ "4+ DST transitions ... unexpected trade" → "regression run period ครอบคลุม **10 DST transitions** (Mar 2021, Oct 2021, ..., Oct 2025) — verify per FR-6.5 **AC-6.5.2** (ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch) + **AC-6.5.3** (trade journal `timestamp` field สะท้อน DST shift ถูกต้อง)"
- Source field updated ให้ cite "C-10, FR-6.5 (AC-6.5.2 / AC-6.5.3)"
- Evidence (new text):
  > *"Verification | QA: regression run period ครอบคลุม **10 DST transitions** (Mar 2021, Oct 2021, Mar 2022, Oct 2022, Mar 2023, Oct 2023, Mar 2024, Oct 2024, Mar 2025, Oct 2025) — verify per FR-6.5 **AC-6.5.2** + **AC-6.5.3**"*

---

### Claim 02.4: 🟡 MEDIUM — Flow Actors lists ใน `05` ขัดกับ System actor convention (Option A applied)
**Verdict:** Accept (Option A — narrow convention scope)

**Rationale:** Reviewer's analysis ถูก — `01 § 4` convention statement absolute ขัดกับ practical BA pattern ที่ flow Actors lists ระบุ system internals (เป็น participant naming). Option A (narrow scope) ดีกว่า Option B (rephrase 4 flow Actors lists) เพราะ:
- BA practice: flow diagram Actors = "ตัวที่ flow นี้ touch" (รวม system internals); user story Actor = stakeholder
- Less effort + reflects valid BA convention
- รักษา semantic ของ `01 § 4` convention (user story actor = stakeholder)

**Changes:**
- File: `docs/ba/01-project-brief.md` § 4 Stakeholders / Actors — System actor convention note
- What changed: 
  - Title ของ note ขยาย: "System actor convention" → "System actor convention **(scope = user stories ใน 02-functional-requirements.md เท่านั้น)**"
  - เพิ่ม paragraph ที่ explicit ว่า flow Actors lists ใน `05` (F1.2/F2.2/F3.2/F7.2 ฯลฯ) เป็น "**participant naming**" ของ component ที่ flow แตะ — รวม system internals (Slot orchestrator, MarketContext, PortfolioState, RiskManager, TradeJournal, Cross-slot helpers, MT5 file system) ตาม BA practice; ไม่ใช่การเลื่อนพวกมันเป็น stakeholder actor
- Evidence (new text):
  > *"**Out of scope of this convention:** Flow diagrams ใน `05-user-flows.md` (sections F1.2/F2.2/F3.2/F7.2 ฯลฯ) ระบุ "Actors involved" ของแต่ละ flow เป็น **participant naming** ของ component ที่ flow แตะ — รวม system internals (Slot orchestrator, MarketContext, PortfolioState, RiskManager, TradeJournal, Cross-slot helpers, MT5 file system) ตาม BA practice ของ flow documentation. การ list system internals ในตาราง flow Actors **ไม่ใช่** การเลื่อนพวกมันเป็น stakeholder actor — เป็นแค่ "ตัวที่ flow นี้ touch" สำหรับ Architect Phase 1B ใช้ extract participant relationships ตอน design component boundaries."*

---

### Claim 02.5: 🟡 MEDIUM — `02` endnote AC count stale (ขาด AC-6.5.3 จาก rebuttal-01 Claim 01.13)
**Verdict:** Accept

**Rationale:** Math ตรง — rebuttal-01 Claim 01.13 เพิ่ม AC-6.5.3 แต่ endnote ไม่ update count. นับใหม่: original 41 + FR-2.2 (1) + FR-7.7 (2) + FR-6.5 (1) = **45**.

**Changes:**
- File: `docs/ba/02-functional-requirements.md` line 858 (endnote)
- What changed: "44 acceptance criteria (FR-2.2 added 1 AC; FR-7.7 added 2 AC for halt semantic)" → "**45 acceptance criteria** (FR-2.2 added 1 AC; FR-6.5 added 1 AC for DST deterministic; FR-7.7 added 2 AC for halt semantic)"
- Evidence (new text):
  > *"**End of 02 — Functional Requirements** — 41 user stories, **45 acceptance criteria** (FR-2.2 added 1 AC; FR-6.5 added 1 AC for DST deterministic; FR-7.7 added 2 AC for halt semantic), MoSCoW (Must 37 / Should 2 / Could 2)"*
- Cross-doc cascade: `state/overview.md` Notes column ต้องเพิ่ม "45 ACs" — applied ในการ update overview

---

### Claim 02.6: 🔵 LOW — NFR-1.6 absolute fallback "lock" vs "example" ambiguity
**Verdict:** Accept

**Rationale:** Reviewer ถูก — NFR-1.6 line 98 ระบุ "±2 trades" lock; OQ-7 line 510 ใช้ "(เช่น ±2 trades)" = example. NFR ต้อง measurable/lock — เลือก option "ลบ เช่น" ตาม reviewer recommendation.

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § 10 OQ-7 resolution (line 510)
- What changed: "tolerance ต้อง absolute (เช่น ±2 trades) ไม่ใช่ percentage" → "tolerance ต้อง absolute **±2 trades** (locked, ตรงกับ NFR-1.6 line 98) ไม่ใช่ percentage — QA agent ใช้ ±2 ตรงๆ ตอน per-slot extraction; ห้ามตีความเป็น 'approximately' หรือ 'example'"
- Evidence (new text):
  > *"**Edge case to revisit ใน QA Phase:** ถ้า baseline per-slot stats extracted แล้วพบ slot ที่ trade น้อยกว่า 5 ครั้งใน 5 ปี = tolerance ต้อง absolute **±2 trades** (locked, ตรงกับ NFR-1.6 line 98) ไม่ใช่ percentage — QA agent ใช้ ±2 ตรงๆ"*

---

### Claim 02.7: 🔵 LOW — `01 § 10` ไม่ list architecture-domain OQ-A1/A2/A3
**Verdict:** Accept

**Rationale:** Reviewer ถูก — `01 § 10` เป็น anchor doc ที่ Architect อ่านก่อน; ถ้า OQ-A1/A2/A3 inline เฉพาะใน `04 § BR-6.5/6/7` → Architect ที่ scan-read ผ่าน TOC อาจมองข้าม. เพิ่ม sub-section 10.1 ให้ single-stop list.

**Changes:**
- File: `docs/ba/01-project-brief.md` § 10 — เพิ่ม sub-section 10.1 NEW
- What changed: เพิ่ม "Open Questions Raised for Architect (post-rebuttal-01)" sub-section ที่ list OQ-A1/A2/A3 พร้อม domain + doc + resolver + status; เพิ่ม "Phase 2 deferred items" cross-ref (FR-7.7 escalation alert + Security NFR category)
- Evidence (new text):
  > *"### 10.1 Open Questions Raised for Architect (post-rebuttal-01)*
  >
  > *⚠️ **Architecture-domain Open Questions** — Phase 1B Architect ต้อง resolve ตอน design state cleaner / pending state machines ... | OQ-A1 (M-Pending force-clear safety policy) | Architecture | `04 § BR-6.5` | Architect Phase 1B | ⏸ pending | ..."*

---

## Cascaded Changes

(Changes ใน BA docs ที่ **ไม่ได้** cite ใน claims โดยตรง — เกิดจาก Phase 4 consistency sweep หลัง claim-driven changes; ส่วนใหญ่เป็น residual ของ Claim 02.2 tech-leak rewrite ที่ rebuttal-01 ตามไม่ครบ)

1. **NFR-4.2 title + Metric + Verification rephrase** — `03-non-functional-requirements.md § NFR-4.2` ใช้ "Slot interface compliance: 1 file per slot" + Metric "Slot subclass count ÷ slot interface file count" + Verification "grep `class Slot.* :`" ทั้ง 3 จุดใช้ tech-leak terms (interface, subclass, class signature). Rewrite เป็น "Slot abstraction compliance: 1 file per slot" + Metric "Slot count ÷ slot file count" + Verification "count slot files vs slot list ใน 01 § 5.1"; เพิ่ม "concrete naming + structure = TD decide" — ตรงกับ FR-2.5 rewrite + Tech-Agnostic rule
2. **BR rule type tag legend** — `04-business-rules.md` § Rule type tag: "🔧 Refactor-safe — semantic เหมือนเดิมแต่ implementation อาจเปลี่ยน (ผ่าน slot interface)" → "ผ่าน slot abstraction; concrete API = TD decide"
3. **BR-2.1 Validation hint** — `04-business-rules.md` BR-2.1 dependency edge table: "QA inspect slot interface — ทุก subclass มี `dependsOn()`" → "QA inspect slot abstraction (FR-2.5) — ทุก slot expose `dependsOn()` ... (concrete name/return shape = TD decide)"
4. **`01 § 5.1` cross-slot dependency wording** — "explicit ใน slot interface" → "explicit ใน slot abstraction (FR-2.5; concrete representation = TD decide)"
5. **`02 § FR-2.4` AC-2.4.1** — "Given slot interface definition (จาก SD/TD)" → "Given slot abstraction definition (จาก SD/TD)"
6. **`05 § F5.3` Mermaid + § F5.4 narrative** — "Initialize slot interface + MarketContext + PortfolioState" → "Initialize slot abstraction + MarketContext snapshot + Per-slot state lookup"
7. **`05 § 9` Doc Map line 627** — "FR-2.5/2.6/2.7 (Slot interface, MarketContext, PortfolioState)" → "FR-2.5/2.6/2.7 (Slot abstraction, MarketContext snapshot, Per-slot state lookup)"
8. **`state/overview.md` Notes column** — Status "Complete + Rebuttal Round 01" → "Complete + Rebuttal Round 02"; เพิ่ม AC count 45 + rebuttal-02 line + OQ-A1/A2/A3 routing พึ่ง `01 § 10.1` แทน inline ใน `04 § BR-6.5/6/7` เท่านั้น

> **Note:** Cascade 1-7 เป็น tech-leak residual ที่ Claim 02.2 cite **เฉพาะ MoSCoW table** แต่ pattern เดียวกันกระจายใน 5 BA docs. Phase 4 sweep พบ + fix ทั้งหมด — ปิด rebuttal coverage gap pattern ที่ reviewer flag เป็น process risk

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | **100%** (7/7) | สูง — แต่ไม่ใช่ red flag (per persona "Accept rate > 50% = warning"; 100% ที่ Round 02 = expected เพราะ findings ทั้งหมดเป็น **mechanical sweep gap** ไม่ใช่ design defect ใหม่; reviewer's findings มี evidence ครบทุกข้อ + ตรงกับ source-of-truth ที่ rebuttal-01 set แล้ว) |
| Partial Rate | **0%** (0/7) | ไม่ hedge — ทุก finding มี clear fix path; ไม่มี case ที่ต้อง split accepted/rejected portion |
| Reject Rate | **0%** (0/7) | ไม่ red flag — ไม่มี finding ที่ reviewer miss text หรือ over-extend scope |
| Critical Fixes | **0** | ไม่มี CRITICAL ใน Round 02 (เป็น expected — handoff-blocking issues ปิดที่ Round 01) |
| HIGH Fixes | **1** (Claim 02.1) | actor sweep — mechanical แต่ blocking ใน sense ที่ ส่งต่อ Architect ที่อ่าน user stories ของ `02` ก่อน |
| Net Improvement | **Significant** | (a) Actor convention ทั้ง package consistent (0 non-canonical actors ใน `02`); (b) tech-leak terminology fully removed (Slot interface / PortfolioState map / MarketContext map = 0 hits ใน BA active docs); (c) NFR-7.3 deterministic — point ที่ FR-6.5 source-of-truth; (d) AC count 44→45 ตรงกัน 3 จุด (TL;DR, footer, endnote); (e) ±2 trades absolute fallback locked ระหว่าง NFR-1.6 + OQ-7 resolution; (f) Architecture-domain OQ-A1/A2/A3 anchor ใน `01 § 10.1` ที่ Architect onboarding scan first; (g) Convention scope ambiguity ระหว่าง user-story actor + flow-participant naming resolved |
| Remaining Gaps | **0 finding-driven gaps** | Round 02 = 7 → Round 02 close 7 → Round 03 expected 0 findings (handoff-blocking residual = none); known long-tail gaps (Phase 2 escalation alert, Phase 2 Security NFR category, OQ-A1/A2/A3 architecture-domain) ทั้งหมดมี anchor + routing ผ่าน rebuttal-02 § 10.1 |
| Reviewer-missed coverage extensions | **+2 fixes** | (a) FR-8.2 actor (reviewer cite 8 stories — actually 9); (b) NFR-4.2 title + Metric + Verification + 5 cascade tech-leak residuals (Claim 02.2 cite MoSCoW table only, sweep พบ 6 จุดเพิ่ม) |

---

## Recommendation

- [x] ✅ **Ready for Architecture Handoff** — all CRITICAL/HIGH/MEDIUM/LOW claims resolved + comprehensive sweep done; rebuttal coverage gap pattern (ที่ reviewer flag เป็น process risk) ปิดแล้ว — Round 03 expected 0 findings
- [ ] 🔁 Request Re-Review
- [ ] ⛔ Needs Stakeholder Input

**Notes for Architect (Phase 1B = `/sd`):**

(Same as Rebuttal Round 01 — ไม่มี new architecture-domain item เพิ่มจาก Round 02; ทุกอย่างเป็น BA hygiene)

1. **OQ-A1/A2/A3** (M/T/Q-Pending force-clear safety policy) — ดู `01 § 10.1` (NEW anchor) + `04 § BR-6.5/6/7` (inline rule + invalidation conditions); design state cleaner ต้อง resolve trade-off "no force-clear vs safety force-clear with state file growth bound"
2. **Per-slot baseline parameterization** ใน `03 § NFR-1.6` — Architect design regression check function parameterized over baseline table (loaded at QA time); absolute fallback ±2 trades locked (Claim 02.6)
3. **DST verifier source-of-truth** — `02 § FR-6.5 AC-6.5.2/6.5.3` is source; NFR-7.3 verification ตอนนี้ mirror — Architect ไม่ต้อง resolve ambiguity (Claim 02.3)
4. **Actor convention scope** — `01 § 4` convention เน้น user stories ใน `02` เท่านั้น; flow Actors lists ใน `05` = participant naming — Architect ใช้ flow Actors lists เพื่อ extract component participants ได้ตามปกติ ไม่ contradict convention (Claim 02.4)
5. **Slot abstraction terminology lock** — ทุก BA doc ตอนนี้ใช้ "slot abstraction" + "MarketContext snapshot" + "Per-slot state lookup" (concept-level terms); concrete API/struct/data structure = TD decide (Claim 02.2 cascade)
6. **Phase 2 deferred items** — `01 § 10.1` cross-ref FR-7.7 escalation alert + Security NFR category (ทั้งคู่ Phase 2 BA, ไม่ใช่ Phase 1B Architect work)

**OQ Routing summary (unchanged from Rebuttal Round 01):**

| OQ | Domain | Doc | Resolver | Status |
|----|--------|-----|----------|--------|
| OQ-A1 (M-Pending force-clear) | Architecture | `04 § BR-6.5` (anchor: `01 § 10.1`) | Architect Phase 1B | ⏸ pending |
| OQ-A2 (T-Pending force-clear) | Architecture | `04 § BR-6.6` (anchor: `01 § 10.1`) | Architect Phase 1B | ⏸ pending |
| OQ-A3 (Q-Pending force-clear) | Architecture | `04 § BR-6.7` (anchor: `01 § 10.1`) | Architect Phase 1B | ⏸ pending |
| Phase 2 escalation alert | Phase 2 | `02 § FR-7.7` known gap (anchor: `01 § 10.1`) | Phase 2 BA | ⏸ deferred |
| Phase 2 Security NFR | Phase 2 | `03 § 5 Security note` (anchor: `01 § 10.1`) | Phase 2 BA | ⏸ deferred |

> **End of Rebuttal Round 02** — 7/7 claims processed, 7 accept + 0 partial + 0 reject; ready for Architecture handoff (Phase 1B). Comprehensive sweep done — pattern ของ "rebuttal coverage gap" ที่ Round 02 reviewer flag = closed (verified ผ่าน Phase 4 grep checks).
