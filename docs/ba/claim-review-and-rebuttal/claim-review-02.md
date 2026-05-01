# BA Claim Review Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Target** | `all` (5 BA docs + `state/overview.md` post-rebuttal-01) |
| **Date** | 2026-05-01 |
| **Reviewer** | BA Reviewer (Adversarial Consultant) |
| **SKILLs** | business-analyst, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** 7 ( 🔴 CRITICAL 0 / 🟠 HIGH 1 / 🟡 MEDIUM 4 / 🔵 LOW 2 )

**Round 01 closure status:** 16/16 claims verified against current docs — 14 fully closed; 2 partial (Claim 01.10 actor-convention sweep missed 8 user stories; Claim 01.13 deterministic spec missed NFR-7.3 mirror).

### Top 3 to Fix First

1. **Claim 02.1** 🟠 — 8 user stories ใน `02` ยังใช้ non-canonical actor (`AI Agent`, `EA system`) — Claim 01.10 fix ไม่ครบ — `02 § FR-2.4, FR-4.2, FR-6.6, FR-7.1, FR-7.2, FR-7.4, FR-7.5, FR-7.6`
2. **Claim 02.2** 🟡 — MoSCoW Summary Table (lines 775-777) ยังคง pre-rebuttal terminology ("Slot interface", "PortfolioState map") ขัด FR-2.5/2.6/2.7 section titles ที่ rewrite แล้ว — Claim 01.7 incomplete — `02 § 10`
3. **Claim 02.3** 🟡 — NFR-7.3 verification ยังคง "unexpected trade" + DST transition count mismatch กับ FR-6.5 AC-6.5.2 — Claim 01.13 incomplete — `03 § NFR-7.3`

### Verdict

- [ ] ✅ **Ready for Architecture Handoff** — ไม่มี CRITICAL/HIGH หรือ handoff-blocking findings
- [x] ⚠️ **Needs Rebuttal Round** — มี 1 HIGH (incomplete fix) → run `/ba-rebuttal claim-review-02.md`
- [ ] ⛔ **Immediate Attention** — contradictory requirements ที่ block design

ภาพรวม Round 02: rebuttal-01 fix coverage **สูงมาก** (87.5% claims closed สมบูรณ์) — Round 02 finding count ลดลง 16 → 7 (56% drop) เหมือนคาด. ปัญหาหลักที่เหลือคือ **fix coverage gaps** ที่ rebuttal ลืม sweep ทั่วทั้งเอกสาร — ไม่ใช่ design defect ใหม่: actor convention ใน `02` ครอบคลุมแค่ 15 จาก 23 stories ที่มี non-canonical actor; tech-leak rephrase ของ FR-2.5/2.6/2.7 ไม่ propagate เข้า MoSCoW Summary Table; FR-6.5 AC-6.5.2 deterministic spec ไม่ mirror ลง NFR-7.3 verification field. ไม่มี CRITICAL — ก่อน TD lock schema ทุก field ตรงตามที่คาด. 1 HIGH (Claim 02.1) เป็น mechanical sweep ที่ใช้เวลา < 30 นาทีแก้ทั้งหมด.

---

## BA Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Problem Statement | ✅ Pass | `01 § 2` ไม่เปลี่ยน — ยัง pass round 01 |
| 2 | Success Metrics | ✅ Pass | G1-G4 KPI ไม่เปลี่ยน |
| 3 | Scope Boundaries | ✅ Pass | `01 § 5/6` Won't Permanent ไม่กระทบ |
| 4 | User Story Quality | ⚠️ Finding 02.1 | Format มาตรฐานครบ; แต่ 8 stories ยังใช้ actor ที่อยู่นอก convention |
| 5 | Acceptance Criteria | ⚠️ Finding 02.3, 02.5 | AC-6.5.2/6.5.3 verified; แต่ NFR-7.3 mirror field ยัง vague + endnote AC count stale |
| 6 | MoSCoW Prioritization | ⚠️ Finding 02.2 | Counts ตรง (Must 37/2/2; NFR M=26 S=4 C=0); แต่ table title fields ใช้ stale terminology |
| 7 | NFR Measurability | ✅ Pass | NFR-2.1/2.2 measurement protocol ครบหลัง rebuttal-01 ✅ |
| 8 | NFR Completeness | ✅ Pass | Security note ✅ added (line 329); 8 หมวดครบ |
| 9 | Business Rules | ✅ Pass | OQ-A1/A2/A3 routing ✅; F/GO/BR sub-call table ✅ |
| 10 | User Flow Coverage | ⚠️ Finding 02.4 | F1-F7 cover ครบ; แต่ flow Actors list ขัด `01 § 4` System actor convention |
| 11 | Traceability | ✅ Pass | `02 § 11` mapping ครบ G1-G4; FR-7.7 priority cascade reflected |
| 12 | Assumption Marking | ✅ Pass | Marker convention ✅ + 🟡 Soft markers applied to C-5/6/7 |
| 13 | Tech-Agnostic | ⚠️ Finding 02.2 | FR-2.5/2.6/2.7 sections rewrite ✅; แต่ MoSCoW table ยังใช้ "interface", "map" |
| 14 | Cross-Doc Consistency | ⚠️ Finding 02.2, 02.3, 02.4 | Tech-leak residual + DST transition count mismatch + actor scope ambiguity |
| 15 | Edge Cases | ✅ Pass | Pending timeout OQs raised; halt semantic AC ครบ |
| 16 | Open Questions Distribution | ⚠️ Finding 02.7 | New OQ-A1/A2/A3 ใน `04`; แต่ `01 § 10` ไม่ list — Architect reading `01` first จะมองข้าม |
| 17 | Ambiguity | ⚠️ Finding 02.3 | NFR-7.3 "unexpected trade" ยัง undefined |
| 18 | Conflict Detection | ⚠️ Finding 02.3 | NFR-7.3 "4+ DST transitions" vs FR-6.5 AC-6.5.2 "10 transitions" |
| 19 | Readability / Reader-Empathy | ✅ Pass | Section openers ✅ added; Glossary § 8.1/8.2 ✅; Why-line ครบ |
| 20 | Language Rule Compliance | ✅ Pass | Bilingual; TL;DR Thai; section openers Thai; actor/entity English; user story rationale Thai |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🟠 HIGH

#### Claim 02.1: 🟠 HIGH — Claim 01.10 fix incomplete: 8 user stories ยังคงใช้ non-canonical actor

**Location:**
- `02-functional-requirements.md` § FR-2.4 (line 177): `**As a** AI Agent (implementer)`
- `02-functional-requirements.md` § FR-4.2 (line 393): `**As a** AI Agent / Developer`
- `02-functional-requirements.md` § FR-6.6 (line 581): `**As a** EA system`
- `02-functional-requirements.md` § FR-7.1 (line 611): `**As a** EA system`
- `02-functional-requirements.md` § FR-7.2 (line 627): `**As a** EA system`
- `02-functional-requirements.md` § FR-7.4 (line 652): `**As a** EA system`
- `02-functional-requirements.md` § FR-7.5 (line 664): `**As a** EA system`
- `02-functional-requirements.md` § FR-7.6 (line 676): `**As a** EA system`

**Problem:**

Rebuttal-01 Claim 01.10 verdict = "Partial (Option A applied)" + เพิ่ม convention note ใน `01 § 4` (line 80):

> *"User stories ใน `02-functional-requirements.md` ใช้ `Trader`, `MT5 Platform`, `Strategy Tester`, `Broker` ตามตารางข้างบน. Internal EA components ... **ไม่ใช่ actor** — เป็น implementation detail ... user story กับ AC ที่อ้างถึง component เหล่านี้จะใช้ phrasing แบบ 'EA must...' / 'the system shall...'"*

Rebuttal-01 list rephrased actor 15 stories: FR-2.5, 2.6, 2.7, 3.1, 3.2, 3.5, 3.6, 5.2, 6.1-6.5, 6.7, 7.3, 8.1. แต่ **ลืมอีก 8 stories**:

- FR-2.4: `AI Agent (implementer)` — `AI Agent` อยู่ใน `01 § 4` table แต่ convention note explicit จำกัดเฉพาะ Trader/MT5 Platform/Strategy Tester/Broker
- FR-4.2: `AI Agent / Developer` — `Developer` ไม่อยู่ใน actor table เลย
- FR-6.6, 7.1, 7.2, 7.4, 7.5, 7.6: `EA system` — ตามที่ convention note บอกว่า "EA system = subject ของ behavioral requirement, **ไม่ใช่** subject ของ user story"; correct phrasing คือ "**As a** Trader, **I want** EA system จะ detect ping-pong..."

**Why this matters:**

- **Convention violation visibility:** PM/Architect reading `02` จะเห็น user stories 8 รูปแบบ + `01 § 4` ที่บอก "แค่ 4 actor" → ส่งสัญญาณ inconsistent BA convention
- **Cascade for Architect:** Architect Phase 1B reads `02` user stories เพื่อ extract behavioral requirements; ถ้า actor ไม่ตรง convention, Architect อาจตีความ "EA system = standalone component ที่ต้อง design" แทน "the EA itself shall do X"
- **Mechanical sweep miss = process risk:** Round 01 reviewer cited specific examples (FR-2.7, FR-3.6, FR-6.x, FR-7.x); rebuttal applied fix only ที่ cited locations + บางส่วน — ไม่มี grep ทั่วทั้ง file. Same pattern อาจเกิดอีกใน future rounds ถ้า rebuttal ไม่ทำ comprehensive sweep

**Minimum acceptable fix:**

Grep `^\*\*As a\*\*` ใน `02-functional-requirements.md` → ทุก match ที่ actor ∉ {Trader, MT5 Platform, Strategy Tester, Broker} ต้อง rephrase. Specific changes:

- FR-2.4 line 177: `AI Agent (implementer)` → `Trader, **I want** EA expose dependency relations (...) เป็น `dependsOn(otherSlot)` field, **so that** ผมไม่ต้องกังวลว่า refactor 1 slot จะทำให้ slot อื่นพังเงียบ`
- FR-4.2 line 393: `AI Agent / Developer` → `Trader, **I want** EA logger ที่ prepend ... `
- FR-6.6 line 581: `EA system` → `Trader, **I want** EA detect ping-pong ...`
- FR-7.1 line 611: `EA system` → `Trader, **I want** EA's "Safe port" cleanup: ถ้า ...`
- FR-7.2 line 627: `EA system` → `Trader, **I want** EA's alternate cleanup ผ่าน Ichimoku ...`
- FR-7.4, 7.5, 7.6: similarly rephrase to `Trader` with `EA must...` body

(Optional alternative: ขยาย convention note ใน `01 § 4` ให้ allow `EA system` ใน user story — แต่จะ contradict statement ปัจจุบันที่บอกว่า "EA system = subject ของ behavioral requirement, ไม่ใช่ subject ของ user story". Pick one).

**Effort:** Low

---

### 🟡 MEDIUM

#### Claim 02.2: 🟡 MEDIUM — MoSCoW Summary Table tech-leak terminology residual (Claim 01.7 incomplete)

**Location:** `02-functional-requirements.md` § 10 MoSCoW Summary Table (lines 775-777)

**Problem:**

Section titles ใน FR-2.5/2.6/2.7 ถูก rewrite เพื่อลบ tech-leak ตาม Claim 01.7:
- Line 191: `FR-2.5 — Slot abstraction (uniform behavior contract)` ✅
- Line 210: `FR-2.6 — Centralized indicator snapshot per tick` ✅
- Line 229: `FR-2.7 — Per-slot state lookup by magic identifier` ✅

แต่ MoSCoW Summary Table ยังคงเขียน:

| Line | ตาราง | ปัญหา |
|------|------|-------|
| 775 | `FR-2.5 \| Slot interface \| Must \| G1 \| §7.2` | "Slot interface" = ABI-style term ที่ Claim 01.7 รื้อแล้ว |
| 776 | `FR-2.6 \| MarketContext snapshot \| Must \| G1, G3 \| §7.2` | OK (MarketContext เป็น concept-level term, glossary entry) |
| 777 | `FR-2.7 \| PortfolioState map \| Must \| G1, G3 \| §7.2` | **"map" = Claim 01.7 tech-leak word ที่ระบุชัดว่าให้ลบ** — TD เลือก data structure อื่น (struct array) ก็ขัด |

**Why this matters:**

- **Architect/PM scan-read pattern:** Summary table ถูกอ่านเป็น quick-reference; ถ้า terminology ขัด section title = trust ของ doc ลด
- **`map` ใน line 777 specifically problematic:** TD อาจ implement ผ่าน struct array (faster ใน MQL5 native) — table title ที่ lock "map" จะ confuse
- **Mechanical sweep miss:** Same pattern เป็น Claim 02.1 — rebuttal fix locations ที่ cited (FR section bodies) แต่ไม่ sweep ทั่วเอกสาร (table titles, glossary cross-refs, traceability mentions)

**Minimum acceptable fix:**

Update lines 775-777 ของ MoSCoW Summary Table:

```
| FR-2.5 | Slot abstraction (uniform contract) | Must | G1 | §7.2 |
| FR-2.6 | Indicator snapshot per tick | Must | G1, G3 | §7.2 |
| FR-2.7 | Per-slot state lookup by magic | Must | G1, G3 | §7.2 |
```

Cross-check: ตาราง `02 § 11 Traceability` (line 813-820) อ้าง FR-2.5/2.6/2.7 IDs ไม่ใช่ titles → ไม่กระทบ.

**Effort:** Low

---

#### Claim 02.3: 🟡 MEDIUM — NFR-7.3 verification field ยังคง vague + DST transition count ขัดกับ FR-6.5

**Location:** `03-non-functional-requirements.md` § NFR-7.3 (line 408)

**Problem:**

NFR-7.3 verification field เขียน:

> *"QA: regression run period must include **4+ DST transitions** (Mar 2021, Oct 2021, ..., Mar 2025) → trade pattern around switch ตรวจ**ไม่พบ unexpected trade**"*

แต่ Claim 01.13 rebuttal fix เปลี่ยน FR-6.5 AC-6.5.2 ให้ deterministic:

> *"AC-6.5.2: ... `Mar 2021 + Oct 2021 + Mar 2022 + Oct 2022 + ... + Oct 2025` = **10 transitions** ... ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch ..."*

**ความขัดแย้ง 2 จุด:**

1. **Transition count:** NFR-7.3 = "4+ transitions"; FR-6.5 AC-6.5.2 = "10 transitions". Same baseline period (Mar 2021 - Oct 2025) → 10 ✅; "4+" stale (น่าจะค่าเก่าก่อน period ขยาย)
2. **Verification deterministic-ness:** NFR-7.3 ยังคง "unexpected trade" ที่ Claim 01.13 ระบุชัดว่า vague → contradict rebuttal-01 fix; FR-6.5 AC-6.5.2 deterministic spec ไม่ mirror

**Why this matters:**

- **NFR-7.3 priority = Must, FR-6.5 priority = Must** — ทั้งคู่ Must แต่ verification ฝั่ง NFR ยัง subjective ↑ QA judgment call
- **Cross-doc inconsistency** — Architect/QA reading `02 + 03` จะเจอ 2 spec ที่ขัดกัน → ตัดสินใจไม่ได้ว่าอันไหน source-of-truth
- **Pattern same as Claim 02.1, 02.2:** rebuttal sweep coverage gap

**Minimum acceptable fix:**

Update NFR-7.3 verification field ให้ mirror FR-6.5 AC-6.5.2 spec:

```
Verification | QA: regression run period ครอบคลุม 10 DST transitions
             | (Mar 2021, Oct 2021, Mar 2022, ..., Oct 2025) — verify
             | per FR-6.5 AC-6.5.2 (no order in 00:00–00:05 server-time
             | window on DST switch days) + AC-6.5.3 (timestamp shift
             | reflected correctly)
```

**Effort:** Low

---

#### Claim 02.4: 🟡 MEDIUM — Flow Actors lists ใน `05` ขัดกับ System actor convention

**Location:**
- `05-user-flows.md` § F1.2 (line 44): `Slot orchestrator, 21 active slots, TradeJournal, MarketContext, PortfolioState`
- `05-user-flows.md` § F2.2 (line 126): `Slot, MarketContext (read), PortfolioState (read), RiskManager (lot calc), MT5 CTrade (broker submission), TradeJournal (write)`
- `05-user-flows.md` § F3.2 (line 199): `Slot, PortfolioState (read), MT5 CTrade (close submission), TradeJournal`
- `05-user-flows.md` § F7.2 (line 514): `Slot, Cross-slot helpers, TradeJournal (write), MarketContext (read for snapshot), MT5 file system`

**Problem:**

`01 § 4` System actor convention (rebuttal-01 added line 80) ระบุ **absolute statement**:

> *"Internal EA components (slot logic, risk-management helper, pending-state machine, **market-context bundle**, **per-slot state lookup**) **ไม่ใช่ actor** — เป็น implementation detail"*

แต่ flow Actors lists ใน F1.2/F2.2/F3.2/F7.2 ระบุ `Slot orchestrator, MarketContext, PortfolioState, RiskManager, TradeJournal, Slot, Cross-slot helpers` — ทั้งหมดเป็น internal components. Convention scope ambiguity:

- **Strict reading:** Convention statement absolute ("ไม่ใช่ actor" ทั่ว BA package) → flow Actors lists violate
- **Lenient reading:** Convention preamble เริ่มด้วย "User stories ใน `02-functional-requirements.md` ใช้ ..." → จำกัด scope แค่ 02 → flow Actors free to use components

Round 01 Claim 01.10 location field cite `05-user-flows.md` Actors explicitly ว่าเป็นปัญหา; rebuttal เลือก "Option A applied" + convention note + rephrase 02 user stories — แต่**ไม่แตะ flow Actors ใน 05**

**Why this matters:**

- **Convention scope ambiguity = onboarding friction** — Architect ที่อ่าน `01 § 4` convention แล้วไปเจอ flow Actors ขัด → งงว่าต้อง follow convention ไหน
- **Architect Phase 1B uses flow diagrams เพื่อ extract participant relationships** — ถ้า "actor" ใน flow คือ component design hint, BA กำลัง overlap กับ Architect's job (Claim 01.10's original concern)

**Minimum acceptable fix:**

เลือก 1 จาก 2 options:

- **Option A (narrow convention):** เพิ่มประโยคใน `01 § 4` convention note ให้ explicit ว่า scope = "user stories ใน 02 เท่านั้น"; flow Actors ใน 05 อนุญาตให้ใช้ system components (เป็น participant naming, ไม่ใช่ stakeholder actor)
- **Option B (extend fix):** Rephrase F1.2/F2.2/F3.2/F7.2 actors lists เพื่อแยก "external participants" (Trader, MT5 Platform, Broker) จาก "system internals (referenced)" — รักษา semantic ของ convention

แนะนำ Option A เพราะมีค่า less effort + convention reflects practical BA pattern ที่ flow diagrams typically include system components as participants

**Effort:** Low

---

#### Claim 02.5: 🟡 MEDIUM — `02` endnote AC count stale (ขาด AC-6.5.3 จาก rebuttal-01 Claim 01.13)

**Location:** `02-functional-requirements.md` line 858 (endnote)

**Problem:**

Endnote เขียน:

> *"41 user stories, **44 acceptance criteria** (FR-2.2 added 1 AC; FR-7.7 added 2 AC for halt semantic), MoSCoW (Must 37 / Should 2 / Could 2)"*

แต่ rebuttal-01 Claim 01.13 fix เพิ่ม **AC-6.5.3** ใน FR-6.5 (line 575-577) — ไม่ถูก count

นับใหม่:
- Original baseline (pre-rebuttal-01): ~41 ACs
- FR-2.2 added 1 AC (per endnote) → 42
- FR-7.7 added 2 ACs (AC-7.7.3, 7.7.4) → 44
- FR-6.5 added 1 AC (AC-6.5.3, จาก Claim 01.13) → **45** (endnote ไม่อัพเดต)

**Why this matters:**

- **Same pattern as original Claim 01.4** (count drift across multiple statements) → suggests rebuttal-01 ปรับ count statement หลัก แต่ลืม endnote tail
- **TL;DR + footer + endnote เป็น 3 จุดที่ stakeholder อ่าน TL;DR ก่อน sign-off** — count ไม่ตรง = trust impact

**Minimum acceptable fix:**

Update endnote line 858:

```
> **End of 02 — Functional Requirements** — 41 user stories, 45 acceptance criteria
> (FR-2.2 added 1 AC; FR-6.5 added 1 AC for DST deterministic; FR-7.7 added 2 AC
> for halt semantic), MoSCoW (Must 37 / Should 2 / Could 2), all FR-domain
> open questions ✅ resolved 2026-05-01
```

**Effort:** Low

---

### 🔵 LOW

#### Claim 02.6: 🔵 LOW — NFR-1.6 absolute fallback "lock" vs "example" ambiguity

**Location:**
- `03-non-functional-requirements.md` § NFR-1.6 (line 98): `absolute fallback **±2 trades** สำหรับ slot ที่ baseline < 5 trades`
- `03-non-functional-requirements.md` § 10 OQ-7 resolution (line 510): `tolerance ต้อง absolute (**เช่น ±2 trades**) ไม่ใช่ percentage`

**Problem:**

NFR-1.6 ระบุ "**±2 trades**" เป็น locked threshold (ไม่มี hedge word); แต่ OQ-7 resolution ใช้ "**(เช่น ±2 trades)**" = example. Ambiguity: ค่า ±2 lock แล้วหรือยัง?

- ถ้า lock: QA Phase 3T ใช้ ±2 ตรงๆ
- ถ้า example: QA decide actual threshold ระหว่าง extraction → schedule risk

**Why this matters:**

- QA Phase 3T agent อ่าน NFR-1.6 + OQ-7 → ตีความ ±2 ต่างกัน 2 way
- ถ้า threshold 2 vs (e.g.) 3 → trigger investigation flag ไม่เท่ากัน

**Minimum acceptable fix:**

เลือก 1: ลบ "เช่น" ใน OQ-7 resolution (line 510) ให้ตรงกับ NFR-1.6; หรือเพิ่ม "(target ลอง — QA confirm ตอน per-slot extraction)" ใน NFR-1.6 line 98

แนะนำ: ลบ "เช่น" — ±2 lock ตรงๆ เพราะ NFR ต้อง measurable (ห้าม "approximately")

**Effort:** Low

---

#### Claim 02.7: 🔵 LOW — `01 § 10` Resolved Questions list ไม่ list new architecture-domain OQ-A1/A2/A3

**Location:** `01-project-brief.md` § 10 (line 284-294)

**Problem:**

Section 10 ตั้งชื่อ "Resolved Questions for Architect (Phase 1B)" + list 5 OQs ✅ resolved. แต่ rebuttal-01 raise **3 architecture-domain OQs ใหม่** (OQ-A1/A2/A3 ใน `04 § BR-6.5/6/7`) ที่ Architect Phase 1B ต้อง resolve. Section 10 ไม่ mention.

State/overview.md มี mention ("New architecture-domain OQ-A1/A2/A3 ... raised for SD"); rebuttal-01 Recommendation section มี OQ Routing summary table — แต่ `01 § 10` ที่ Architect อ่านก่อน (anchor doc) silent

**Why this matters:**

- **Architect onboarding pattern:** Phase 1B agent อ่าน `01-project-brief.md` ก่อนเพื่อ orient → § 10 ควรเป็น single-stop list ของทุก OQ ที่ต้อง resolve
- **OQ-A1/A2/A3 routing inline ใน BR-6.5/6/7** — Architect ที่ scan `04` ทั้งไฟล์เจอ; แต่ scan-read ผ่าน TOC + section title อาจมองข้าม

**Minimum acceptable fix:**

เพิ่ม sub-section `01 § 10.1 — Open Questions Raised for Architect (rebuttal-01)`:

```markdown
### 10.1 Open Questions Raised for Architect (post-rebuttal-01)

| Open Q | Domain | Doc | Resolver |
|--------|--------|-----|----------|
| OQ-A1 (M-Pending force-clear safety) | Architecture | `04 § BR-6.5` | Architect Phase 1B |
| OQ-A2 (T-Pending force-clear safety) | Architecture | `04 § BR-6.6` | Architect Phase 1B |
| OQ-A3 (Q-Pending force-clear safety) | Architecture | `04 § BR-6.7` | Architect Phase 1B |
```

**Effort:** Low

---

## Cross-Document Issues

| # | Issue | Docs | Severity |
|---|-------|------|----------|
| X1 | Actor convention scope (8 user stories ใน `02` ขัด `01 § 4`) | `02 § FR-2.4/4.2/6.6/7.1/7.2/7.4/7.5/7.6` ⊥ `01 § 4` convention | 🟠 (Claim 02.1) |
| X2 | Tech-leak terminology ใน MoSCoW table ขัด rewrite section title | `02 § 10 lines 775/777` ⊥ `02 § FR-2.5/2.7` titles | 🟡 (Claim 02.2) |
| X3 | DST transition count + verifier wording mismatch | `03 § NFR-7.3` ⊥ `02 § FR-6.5 AC-6.5.2` | 🟡 (Claim 02.3) |
| X4 | Flow Actors list ใน `05` ขัด `01 § 4` System actor convention | `05 § F1.2/F2.2/F3.2/F7.2` ⊥ `01 § 4` | 🟡 (Claim 02.4) |
| X5 | NFR-1.6 lock vs example ambiguity (cross-doc within `03`) | `03 § NFR-1.6` ⊥ `03 § 10 OQ-7` | 🔵 (Claim 02.6) |

ไม่พบ contradictions อื่นๆ. Counts ทั้ง 7 จุด (`02` TL;DR/footer/endnote, `03` TL;DR/footer/endnote, `state/overview`) ตรงกันแล้ว ยกเว้น `02` endnote AC count (Claim 02.5).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 02.1 | 🟠 HIGH | 8 user stories ยังคง non-canonical actor (Claim 01.10 incomplete) | `02 § FR-2.4/4.2/6.6/7.1/7.2/7.4/7.5/7.6` | Low |
| 02.2 | 🟡 MEDIUM | MoSCoW table tech-leak terminology ("Slot interface", "PortfolioState map") | `02 § 10 lines 775-777` | Low |
| 02.3 | 🟡 MEDIUM | NFR-7.3 verifier ยัง vague + transition count mismatch กับ FR-6.5 | `03 § NFR-7.3` ⊥ `02 § FR-6.5` | Low |
| 02.4 | 🟡 MEDIUM | Flow Actors lists ขัด System actor convention | `05 § F1.2/F2.2/F3.2/F7.2` ⊥ `01 § 4` | Low |
| 02.5 | 🟡 MEDIUM | `02` endnote AC count stale (45, ไม่ใช่ 44 — AC-6.5.3 ขาด) | `02` line 858 | Low |
| 02.6 | 🔵 LOW | NFR-1.6 absolute fallback "lock" vs "example" wording | `03 § NFR-1.6` line 98 ⊥ line 510 | Low |
| 02.7 | 🔵 LOW | `01 § 10` ไม่ list architecture-domain OQ-A1/A2/A3 | `01 § 10` | Low |

**Priority for `/ba-rebuttal`:** ทุก 7 finding effort = Low; รวมเวลาแก้ < 30 นาที. แนะนำ run `/ba-rebuttal claim-review-02.md` ทันที — ทำ comprehensive grep sweep รอบนี้ (FR `As a` actors, MoSCoW table titles, NFR mirror fields, flow Actors lists) เพื่อปิด rebuttal coverage gap pattern. หลังรอบนี้คาดว่า Round 03 = 0 findings → ✅ ready for Architecture Handoff.
