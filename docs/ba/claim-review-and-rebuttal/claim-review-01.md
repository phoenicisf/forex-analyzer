# BA Claim Review Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Target** | `all` (5 BA docs: 01-project-brief, 02-functional-requirements, 03-non-functional-requirements, 04-business-rules, 05-user-flows) |
| **Date** | 2026-05-01 |
| **Reviewer** | BA Reviewer (Adversarial Consultant) |
| **SKILLs** | business-analyst, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** 16 ( 🔴 CRITICAL 1 / 🟠 HIGH 3 / 🟡 MEDIUM 9 / 🔵 LOW 3 )

### Top 3 to Fix First

1. **Claim 01.1** 🔴 — Trade journal `slot_id` schema enum ใส่ Slot U (deleted) + ขาด Slot F — `05-user-flows.md § 8 F7.5`
2. **Claim 01.2** 🟠 — Slot F หายจาก topo-sort entry pass ทุก doc — TD/Architect ออกแบบ orchestrator ไม่ได้ — `02 § FR-2.4 AC-2.4.2`, `04 § BR-2.2`, `05 § F1.3`
3. **Claim 01.3** 🟠 — FR-7.7 controlled halt semantic ไม่ชัด — open positions ตอน halt ใครจัดการ — `02 § FR-7.7`

### Verdict

- [ ] ✅ **Ready for Architecture Handoff** — ไม่มี CRITICAL/HIGH หรือ handoff-blocking findings
- [x] ⚠️ **Needs Rebuttal Round** — มี 1 CRITICAL + 3 HIGH → run `/ba-rebuttal claim-review-01.md`
- [ ] ⛔ **Immediate Attention** — contradictory requirements ที่ block design

ภาพรวมเอกสารทั้ง 5 ไฟล์มีคุณภาพดีในด้าน Thai-bilingual narrative, TL;DR, Why-line coverage, traceability, และ Mermaid flow diagrams. ปัญหาหลักอยู่ที่ **internal consistency** (โดยเฉพาะ slot scaffold หลังจากการลบ Slot U) และ **MoSCoW count accuracy** ที่ TL;DR/footer/state-overview ไม่ตรงกันและไม่ตรงกับตารางจริง. CRITICAL finding (Claim 01.1) จะถูก propagate เข้า TD lock schema ถ้าไม่จัดการก่อน — Architect จะเขียน journal field set ผิด.

---

## BA Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Problem Statement | ✅ Pass | `01 § 2` 6 ข้อ ชัด + cite CodeWiki line; root cause ของ rewrite อธิบายครบ |
| 2 | Success Metrics | ✅ Pass | G1-G4 มี measurable KPI + baseline จาก `trading-baseline.md` |
| 3 | Scope Boundaries | ✅ Pass | `01 § 5/6` แบ่ง In-Scope + Won't-Phase1 + Won't-Permanent ชัดเจน |
| 4 | User Story Quality | ⚠️ Finding 01.10 | Format มาตรฐาน; แต่มี internal-component actors (RiskManager, TradeJournal, MarketContext, EA logger) ที่ไม่อยู่ใน `01 § 4` |
| 5 | Acceptance Criteria | ⚠️ Finding 01.5, 01.7, 01.13 | Given/When/Then ครบ; แต่มี AC ที่ vague (DST "unexpected") + AC-2.1.1 strict-mode bug + halt mechanism กำกวม |
| 6 | MoSCoW Prioritization | ⚠️ Finding 01.4 | ทุก FR/NFR มี priority; แต่ count ใน TL;DR/footer/state-overview ผิดและไม่ตรงกัน |
| 7 | NFR Measurability | ✅ Pass | ทุก NFR มีตัวเลข; ไม่มีคำว่า "เร็ว" ลอยๆ |
| 8 | NFR Completeness | ⚠️ Finding 01.14 | 8 หมวด แต่ไม่มี Security category อย่างเป็นทางการ — ควร note ว่า out-of-scope เพราะ local-only |
| 9 | Business Rules | ⚠️ Finding 01.6 | 9 categories + decision tables; แต่ M-Pending/T-Pending/Q-Pending ขาด explicit timeout |
| 10 | User Flow Coverage | ✅ Pass | 7 flows + 7 Mermaid diagrams + happy/alt/error path ครบ |
| 11 | Traceability | ✅ Pass | `02 § 11` map G1-G4 → FRs ครบ |
| 12 | Assumption Marking | ⚠️ Finding 01.15 | ⚠️ ใช้ใน FR-3.3 (G4 fix) สมเหตุสมผล แต่ในตาราง C-5/C-6/C-7 ⚠️ ใช้แทนคำว่า "negotiable" — re-purpose ของ marker |
| 13 | Tech-Agnostic | ⚠️ Finding 01.7 | FR-2.5 abstract class signature, FR-2.7 `Map<int magic, SlotState>`, FR-5.2 AC `temp + rename` pattern = HOW-leak |
| 14 | Cross-Doc Consistency | ⚠️ Finding 01.1, 01.2, 01.4, 01.16 | Slot U/F schema bug, topo-sort F-gap, MoSCoW count drift, state/overview stale |
| 15 | Edge Cases | ⚠️ Finding 01.6, 01.8, 01.9, 01.13 | Pending timeout gaps; latency overshoot undefined; per-slot baseline deferred; halt position ownership |
| 16 | Open Questions Distribution | ✅ Pass | ทุก 5 OQs resolved 2026-05-01; v1.2 distributed in 02-05 — ไม่มี orphan |
| 17 | Ambiguity | ⚠️ Finding 01.3, 01.5, 01.13 | Halt semantic, DST "unexpected", NFR-2.1 measurement protocol |
| 18 | Conflict Detection | ⚠️ Finding 01.1, 01.2 | Slot U schema vs FR-2.2; Slot F missing from topo-sort vs FR-2.1 |
| 19 | Readability / Reader-Empathy | ⚠️ Finding 01.11, 01.12 | TL;DR + Why ครบส่วนใหญ่; section opener ขาดใน 03 § 6/7/8, 04 § 5/9; glossary ขาด indicator + helper terms |
| 20 | Language Rule Compliance | ✅ Pass | ทุก doc bilingual; TL;DR + ส่วนใหญ่ section opener Thai; actor/entity ภาษาอังกฤษไม่แปล; user story/AC/BR rationale Thai. ไม่ raise category-level finding (sub-issue ที่ Section opener ขาด ไป raise ใน category 19) |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 01.1: 🔴 CRITICAL — Trade journal `slot_id` enum ผิดทั้งสอง slot สำคัญ (รวม Slot U ที่ถูกลบ + ขาด Slot F)

**Location:** `05-user-flows.md` § 8 F7.5 (line 564)

**Problem:**

Schema example สำหรับ `slot_id` field ของ trade journal record เขียนว่า:

```
"slot_id": "C|D|J|H|K|G|G2|GO|M|L|LX|Q|R|I|P|T|S|B|BR|BI|U",
```

นับได้ 21 ค่า แต่มี 2 ปัญหาร้ายแรง:

1. **มี `U` รวมอยู่ในรายการ** — แต่ FR-2.2 ของ `02-functional-requirements.md` ระบุชัดว่า Slot U **ลบทิ้งจาก rewrite** (per OQ-8 user decision 2026-05-01); BR-1.1 ใน `04` ก็ทำ ~~strikethrough~~ แล้ว
2. **ขาด `F`** — Slot F อยู่ใน 21 active slots ของ `01 § 5.1` + มี MagicF=201 ใน BR-1.1 + มี dependency edge `F → C/D pool` ใน BR-2.1 — แต่ enum ของ schema กลับไม่มี

**Why this matters:**

Trade journal schema คือ **contract ระหว่าง BA → TD → Implementation**; TD agent (Phase 1D) จะ lock schema ตาม `05 § F7.5` ตามที่ BA เขียนไว้. ถ้า propagate ตามนี้:

- Code จะ refuse `slot_id="F"` (validation error) → F orders จะ write fail → ขาด observability ของ slot F → ละเมิด FR-4.1 (per-event journal) + FR-2.1 (preserve all 21 slots)
- Code อาจเขียน `slot_id="U"` ได้ (validation pass) → ถ้า bug ใดทำให้ U code ไหลเข้า rewrite, journal จะ silently log → contradicts FR-2.2 AC-2.2.1 (`BusinessLogic_U` ต้องไม่ปรากฏ)

ปัญหานี้เกิดจากการ copy-paste ผิดตอนแก้ Slot U disposition — copy ของเดิม 22 slot แล้วลบ 1 ตัว แต่ดูเหมือนตอนเซ็นเซอร์ผิด slot.

**Minimum acceptable fix:**

แก้ enum ใน `05 § F7.5` ให้ตรงกับ 21 active slots ตาม BR-1.1 (ลำดับให้ตรงกับ topo-sort):

```
"slot_id": "C|D|F|J|H|K|G|G2|GO|M|L|LX|Q|R|I|P|T|S|B|BR|BI",
```

(เอา `U` ออก, ใส่ `F` กลับ; F เคย `:15004` ตาม BR-1.1 row 48 และ MagicF=201)

เพิ่ม cross-check ใน checklist ของ BA self-review: enum/list/diagram ใดที่ enumerate slot ต้องตรงกับ `01 § 5.1` (21 active slots) เป๊ะๆ และไม่มี `U`.

**Effort:** Low

---

### 🟠 HIGH

#### Claim 01.2: 🟠 HIGH — Slot F หายจาก topo-sort + entry pass list ทุกเอกสาร แต่ยังเป็น 1 ใน 21 active slots

**Location:**
- `02-functional-requirements.md` § FR-2.4 AC-2.4.2 (line 189)
- `04-business-rules.md` § BR-2.2 (line 116)
- `05-user-flows.md` § F1.3 entry pass node (line 72)

**Problem:**

ทั้ง 3 จุด list slot evaluation order ของ entry pass เหมือนกัน:

```
C → D → J → H → K → G → G2 → I → M → L → LX → Q → R → B → BI
จากนั้น → S → T → P (→ P_Pending → P_Extra)
```

นับได้ **18 slots** (15 + 3) — ขาด **F, GO, BR** จากรายชื่อ 21 active slots.

- `GO` และ `BR` เป็น exit-trigger / orphan ตาม BR-2.1 — เข้าใจได้ว่าไม่อยู่ใน entry pass
- แต่ **`F` ใน BR-2.1 ระบุ "F → C/D pool — chain — F เปิดต่อจาก CD เมื่อ `isFOff==false`"** — F เป็น entry slot ที่ถูก chained เข้า OpenOrderCD ภายใน C/D's evaluate path

ปัญหาคือ **ไม่มี doc ใดบอก Architect ชัดๆ ว่า F evaluate ถูกเรียกที่ไหน** — เป็น standalone topo-sort step? เป็น sub-call ภายใน C/D evaluate? FR-2.5 (slot interface) บอกแค่ว่าทุก slot มี `evaluate()` แต่ orchestrator topo-sort ใน BR-2.2 ไม่มี F เลย.

**Why this matters:**

- Architect จะออกแบบ orchestrator ไม่ได้ — ถ้าเลือก "F = standalone step ใน topo-sort" จะ contradict BR-2.1 (chain semantics); ถ้าเลือก "F = sub-call ใน C/D's evaluate" จะ contradict FR-2.5 (slot interface ที่ทุก slot มี method ชุดเดียว) เพราะ F จะถูก hidden dependency
- AC-2.4.2 ที่บอก "topo-sort สอดคล้องกับ EA เดิม CodeWiki §2.2 OnTick order" — แต่ topo-sort ในเอกสารกลับขาด F → ทำ verification ไม่ได้
- FR-2.1 AC-2.1.1 บอก "ทุก slot ใน CodeWiki §1.5 ยกเว้น U ปรากฏใน trade list อย่างน้อย 1 trade" — F ถูกคาดหวังให้เปิด trade แต่ไม่ระบุ caller

**Minimum acceptable fix:**

อย่างน้อยใน BR-2.2 (และ mirror ใน FR-2.4 AC-2.4.2 + 05 § F1.3) เพิ่ม note บรรทัดเดียวที่บอก:

> "Slot F, GO, BR ไม่อยู่ใน main topo-sort เพราะ:
> - **F**: chained ภายใน Slot C/D's evaluate (ผ่าน `BusinessLogic_F` ที่เรียกจาก `OpenOrderCD` เมื่อ `isFOff==false`) — F's `evaluate()` ทำงาน synchronously ภายใน C/D's evaluate
> - **GO**: exit-trigger; เปิดจาก `ExtraTakeProfit_G` (post-exit hook ใน F3 § BR-2.1)
> - **BR**: orphan; เปิดจาก `ExtraTakeProfit_B` (exit-only)"

หรือถ้า decision คือ F **ต้อง** เป็น standalone topo-sort step → เพิ่ม F เข้าไปในทุก list ที่ตำแหน่งหลัง `D` (sorted ตาม dependency).

**Effort:** Low

---

#### Claim 01.3: 🟠 HIGH — FR-7.7 "controlled halt + Alert" ไม่ระบุชะตา open positions + halt mechanism

**Location:** `02-functional-requirements.md` § FR-7.7 (line 685–698)

**Problem:**

AC-7.7.2 เขียนว่า:

> "Given EA in halted state, When user inspect, Then EA ยัง attached กับ chart (ไม่ ExpertRemove) + ไม่ trade ต่อ + journal entry "halted" written"

ทำให้คำถามหลายข้อยัง dangling:

1. **"ไม่ trade ต่อ" หมายถึงอะไร?** Skip OnTick ทั้งหมด? Skip เฉพาะ entry pass? Skip exit pass ด้วย? Set global flag?
2. **Open positions ที่มี ณ moment ที่ halt — ใครจัดการ?** ถ้า skip OnTick ทั้งหมด → ไม่มี exit pass → SL/TP ของ broker จะปิดได้ (server-side) แต่ trailing stops + SL/TP ที่ EA แก้ภายหลัง (เช่น G/GO/M/S trailing) จะหยุด → ความเสี่ยงเปิดจน DD ลึกขึ้น
3. **CircuitBreaker (FR-6.6) trigger เมื่อ ping-pong 3000ms** — ตอนนั้น position ที่เพิ่งเปิดจะอยู่ในตลาดต่อ; ถ้า halt = no-op + alert เท่านั้น → user solo ที่ขณะนั้นไม่ออนไลน์ = position ไหลต่อ
4. NFR-5.1 priority = **Should** — แต่ทุก trigger ของ halt (CircuitBreaker FR-6.6, indicator handle invalid FR-7.6) priority = **Must**. Trigger Must แต่ notification Should = inconsistent priority; ทำให้ user ไม่รู้ว่า safety event เกิด

**Why this matters:**

- ความปลอดภัยตอน halt คือ G4 — ถ้า BA ไม่ระบุ Architect จะเลือกพฤติกรรมแบบใดก็ได้ (ปิดทุก position หรือทิ้งไว้) ซึ่งทั้งสองทางมี risk ที่ user ควรตัดสินใจ ไม่ใช่ Architect
- Solo operator ที่อาจไม่ได้นั่งหน้าจอ → ถ้า halt = passive (ไม่ปิด position) + Alert ที่ user ไม่ได้ยิน (PC mute / ไม่อยู่) = naked exposure
- AC-7.7.2 "EA ยัง attached" ขัดแย้งกับ "ไม่ trade ต่อ" — ถ้ายังรับ tick events ตามปกติแต่ skip logic = passive halt; ถ้า skip OnTick callback = ไม่มี audit trail ของ tick ระหว่าง halt

**Minimum acceptable fix:**

เพิ่ม AC ใน FR-7.7:

- **AC-7.7.3:** Given EA in halted state, When OnTick events มา, Then EA execute exit pass อย่างเดียว (manageExits ของทุก slot ทำต่อ) + skip entry pass + ไม่มี new orders เปิด — เพื่อให้ open positions ปิดตาม TP/SL/trailing rule ตามปกติ ไม่ orphan
- **AC-7.7.4:** Given EA halted, When 1 hour ผ่านไปโดย user ไม่ acknowledge alert, Then trigger second alert (escalation) + persistent journal "halt-extended" entry

อัพเกรด NFR-5.1 priority จาก Should → **Must** (สอดคล้องกับ FR-6.6 Must และ G4 priority).

**Effort:** Medium

---

#### Claim 01.4: 🟠 HIGH — MoSCoW counts ผิดและไม่ตรงกัน 7 จุด ข้าม 3 ไฟล์

**Location:**
- `02-functional-requirements.md` line 13 (TL;DR), line 797 (footer), line 846 (endnote)
- `03-non-functional-requirements.md` line 13 (TL;DR), line 467 (footer), line 505 (endnote)
- `docs/state/overview.md` line 10

**Problem:**

| จุด | เขียนว่า | นับจริง |
|-----|---------|--------|
| `02` TL;DR | Must 30 / Should 5 / Could 3 / Won't 0 | (ไม่ตรงกับใครเลย) |
| `02` footer (line 797) | Must 34 / Should 3 / Could 2 / Won't 0 | **Must 36** / Should 3 / Could 2 / Won't 0 |
| `02` endnote (line 846) | "38 user stories ... Must 34 / Should 3 / Could 2" | **41 user stories** / Must 36 / Should 3 / Could 2 |
| `03` TL;DR | Must 22 / Should 3 / Could 0 | (ไม่ตรงกับ footer) |
| `03` footer (line 467) | Must 22 / Should 5 / Could 0 | **Must 25** / Should 5 / Could 0 |
| `03` endnote (line 505) | "30 NFRs (Must 22 / Should 5 / Could 0)" | 30 NFRs / **Must 25** / Should 5 |
| `state/overview.md` | M=34 S=3 C=2 W=0 | M=36 / S=3 / C=2 / W=0 |

นับ FR ใน MoSCoW Summary Table (lines 755-795 ของ `02`): 41 rows; Must = 36 (FR-1.1, 1.2, 1.3, 1.4, 2.1-2.7 = 7, 3.1-3.6 = 6, 4.1-4.4 = 4, 5.1-5.2 = 2, 6.1-6.7 = 7, 7.1-7.6 = 6 = รวม 36); Should = 3 (FR-5.3, 7.7, 8.1); Could = 2 (FR-8.2, 8.3).

นับ NFR ใน Summary Table (lines 436-465 ของ `03`): 30 rows; Must = 25; Should = 5; Could = 0.

**Why this matters:**

- TL;DR เป็นจุดที่ stakeholder/sponsor อ่านก่อน sign-off — ถ้าเลขผิด = trust ของเอกสารหาย
- Architect/PM ใช้ count วาง schedule (Must 36 vs Must 30 = 20% scope เพิ่ม) → estimate งาน + capacity allocation ผิด
- `state/overview.md` ถูก consume โดย `/next` workflow — count ผิดที่นี่จะ propagate ไป QA + Impl phase

**Minimum acceptable fix:**

1. นับใหม่ทุก count จาก MoSCoW Summary Table (source-of-truth)
2. Update **เฉพาะ 3 จุดที่เป็น count statement** ใน `02` (TL;DR + footer + endnote) ให้ตรงกัน = **Must 36 / Should 3 / Could 2 / Won't 0; 41 user stories; 8 epics**
3. Update **3 จุดใน `03`** = **Must 25 / Should 5 / Could 0; 30 NFRs**
4. Update `state/overview.md` line 10 (BA agent owns เฉพาะแถว Design (BA) — แก้ field "Notes" ใน row นั้น)

**Effort:** Low

---

### 🟡 MEDIUM

#### Claim 01.5: 🟡 MEDIUM — FR-2.1 AC-2.1.1 บังคับ "ทุก slot ≥ 1 trade" ขัดกับ baseline reality

**Location:** `02-functional-requirements.md` § FR-2.1 AC-2.1.1 (line 130–131)

**Problem:**

> "Given EA ใหม่ run ด้วย default input set, When QA รัน Strategy Tester regression, Then ทุก slot ใน CodeWiki §1.5 ยกเว้น `U` ปรากฏใน trade list ของ output report **อย่างน้อย 1 trade** ตลอด 5-yr period"

แต่ baseline 5-yr มี 231 trades / 21 slots = avg ~11/slot — และ NFR-1.6 OQ-7 ระบุชัดว่า "ถ้า slot ใดมี baseline trade < 5 ครั้งใน 5 ปี = tolerance ต้อง absolute (เช่น ±2 trades)". แสดงว่า BA รู้ว่า**บาง slot อาจมี 0 trade ใน baseline** (เช่น orphan helpers, edge-case slot).

ถ้า baseline มี slot ที่ trade = 0 (เช่น BR ที่ "orphan — เรียกจาก ExtraTakeProfit_B exit only" — อาจไม่เคยเปิด order ตลอด 5 ปี) → AC-2.1.1 บังคับว่า rewrite ต้อง ≥ 1 trade = strict กว่า baseline = false-positive failure

**Why this matters:**

QA จะ fail regression เพราะ "BR ไม่มี trade" ทั้งที่ baseline ก็ไม่มี — จะกลายเป็น false alarm ที่ block handoff

**Minimum acceptable fix:**

แก้ AC-2.1.1 เป็น:

> "Then **ทุก slot ที่ baseline มี ≥ 1 trade ใน 5-yr period** ปรากฏใน rewrite trade list อย่างน้อย 1 trade; slot ที่ baseline = 0 trades (per per-slot extraction ใน NFR-1.6) ไม่บังคับ + reuse tolerance rule ของ NFR-1.6"

**Effort:** Low

---

#### Claim 01.6: 🟡 MEDIUM — Pending state machines 3 ตัว (M, T, Q) ขาด explicit timeout

**Location:**
- `04-business-rules.md` § BR-6.5 M-Pending (line 348–356)
- `04-business-rules.md` § BR-6.6 T-Pending (line 359–366)
- `04-business-rules.md` § BR-6.7 Q-Pending (line 369–375)
- `05-user-flows.md` § F4.5 (line 304–306)

**Problem:**

ตาราง F4.5 ระบุยอมรับว่า:

| Machine | Timeout |
|---------|---------|
| **M-Pending** | (no fixed timeout in CodeWiki) |
| **T-Pending** | (BusinessLogic_PendingT confirms) |
| **Q-Pending** | per QPendingCode logic per slot |

ไม่มี explicit timeout = state machine อาจ stuck PENDING ตลอดไป (forever) ถ้า trigger condition ไม่เคยมา. F4.6 error path เขียน "Pending state stuck (timeout logic broken) → Bar count > expected timeout × 2 → Force clear" — แต่ "expected timeout" ของ M/T/Q = undefined → force-clear logic เขียนไม่ได้

**Why this matters:**

- Stuck pending = state file โต + GlobalVariable namespace pollution + Strategy Tester result ไม่ deterministic เพราะ pending ของ run เก่ายังค้าง
- Architect ออกแบบ state cleaner ไม่ได้เพราะไม่รู้ว่า M/T/Q ควร timeout เมื่อไร
- BR-6.9 persistence invariant บอก "ทุก state field ต้อง persist" แต่ไม่กำหนด lifetime

**Minimum acceptable fix:**

ตรวจ CodeWiki §2.5 + §3 (Slot M/T/Q sections) + ideation-brief แล้วเขียน timeout ที่จริงของ EA เดิม (อาจเป็น "until trigger" + invalidation condition). ถ้าไม่มี timeout จริงๆ → mark เป็น **Open Question (NFR-domain)** + propose default safe timeout (เช่น 100 H4 bars สำหรับ M-Pending; 24 H4 bars สำหรับ T-Pending) + ขอ user resolve ก่อน Architect handoff. อย่าง T-Pending ที่ "BusinessLogic_PendingT confirms" — ระบุ trigger condition ที่แน่นอน (ใน CodeWiki §3 Slot T section) เพื่อให้ Architect ออกแบบ confirmation logic ได้

**Effort:** Medium

---

#### Claim 01.7: 🟡 MEDIUM — Tech-leak: abstract class signature, `Map<>` data type, `temp + rename` pattern

**Location:**
- `02-functional-requirements.md` § FR-2.5 (line 193): "abstract class `Slot` กับ `magic()`, `name()`, `evaluate(MarketContext, PortfolioState)`, `manageExits(...)`, `pendingState()`, `dependsOn()`"
- `02-functional-requirements.md` § FR-2.7 (line 228, 231): "`Map<int magic, SlotState>`"
- `02-functional-requirements.md` § FR-5.2 AC-5.2.1 (line 469): "ใช้ pattern: เขียนลง `<file>.tmp` → `FileFlush` → rename `<file>.tmp` → `<file>` atomically"
- `01-project-brief.md` line 110 + line 117 + line 206 (Glossary): repeats `Map<int magic, SlotState>` + `temp + rename`

**Problem:**

BA benchmark `ba-requirements-prompt.md § GUARDRAILS § Tech-Agnostic Rule` บอกชัด:

> "**No technical hints in any BA doc** — Architect owns all tech decisions; BA documents WHAT/WHY only"
> "**Describe WHAT, not HOW** — *"ส่ง notification ภายใน 5 นาที"* ✅ vs *"ใช้ Firebase Cloud Messaging"* ❌"

3 จุดข้างต้นเป็น HOW:

1. **Class signature** — `magic()`/`evaluate(ctx, portfolio)` คือ method API design = TD's job
2. **`Map<int magic, SlotState>`** — programming language data type ที่ระบุทั้ง key/value generic = SD/TD's choice (อาจเป็น array, hash table, BTree, ฯลฯ)
3. **`temp + rename` pattern** — file I/O implementation algorithm

ที่ใช้ได้: "EA ต้องมี slot interface ที่ทุก slot ใช้ ABI เดียวกัน" + "EA ต้องเก็บ portfolio state ที่ index ผ่าน magic" + "state file write ต้อง atomic — ถ้า process kill กลางคัน ไฟล์ไม่ corrupt" — เลือก HOW ใน SD/TD

**Why this matters:**

- Architect phase ไม่มีพื้นที่ให้คิด — ถูก lock pattern ไว้แล้ว → ไม่สามารถ propose alternative (เช่น ใช้ struct array แทน Map สำหรับ MQL5 performance)
- ถ้า MQL5 native ไม่มี generic `Map<>` → TD ต้อง hack เอง = friction
- ขัด v1.2 BA rule ที่บอก "BA ห้ามเสนอ tech"

**Minimum acceptable fix:**

แก้ phrasing ให้เป็น behavior contract:

- **FR-2.5**: "ระบบต้องมี slot abstraction ที่ orchestrator interact ได้ผ่าน method ชุดเดียวกัน (ดู FR-2.3 = exit-before-entry, FR-2.4 = dependency, BR-6.x = pending state, BR-2.2 = topo-sort order). ชื่อ method, structure ของ context object, และ inheritance model = TD decide"
- **FR-2.7**: "ระบบต้องเก็บ per-slot state ที่ slot อ่านได้ผ่าน magic ตัวเดียว (อ่าน buyCount/sellCount/totalLots/totalProfit/lastOpenDate/pendingState ของ slot ตัวเองได้ใน O(1)). ใช้ data structure อะไร = TD decide"
- **FR-5.2 AC-5.2.1**: "ระบบต้อง atomic write — invariant: ถ้า process kill ระหว่าง write 100 ครั้ง, EA boot กลับมา parse state file สำเร็จ 100% (NFR-3.1). Implementation pattern (temp+rename, journaling, swap, ฯลฯ) = TD decide"

ลบหรือเขียนใหม่ Glossary entries ใน `01 § 8` ที่อ้าง `Map<int magic, SlotState>` ให้เป็น behavior description.

**Effort:** Medium

---

#### Claim 01.8: 🟡 MEDIUM — NFR-2.1 / NFR-2.2 ขาด measurement protocol

**Location:**
- `03-non-functional-requirements.md` § NFR-2.1 (line 142–152)
- `03-non-functional-requirements.md` § NFR-2.2 (line 154–164)

**Problem:**

NFR-2.1 บอก "Tick latency overhead ≤ 10% vs **original**" — แต่ `original` คือ EA เดิม `PhoenicisN2.10_stable.mq5`. Verification field พูดสั้นๆ "Strategy Tester profiler หรือ timestamp diff ระหว่าง OnTick enter/exit; วัดทั้ง original + rewrite บนเครื่องเดียวกัน same period sample" — แต่:

1. EA เดิม **ไม่มี timestamp instrumentation** ใน OnTick (CodeWiki §6.2 P2.5 พูดถึง bare `Print()` — ไม่มี profiler hook). QA จะ inject instrumentation ที่ไหน? ในไฟล์ original?
2. "Strategy Tester profiler" ของ MT5 มี granularity ระดับ tick หรือไม่? (MT5 profiler ปกติ profile MQL5 function level ไม่ใช่ tick-level)
3. "Same period sample" — sample size? ที่ confidence level เท่าไร?

NFR-2.2 บอก "≤ 5 ms/tick average" — verification "profiler trace OnTick → journal write block; วัด distribution (avg + p95)". ถ้าเกิน 5 ms ในบาง tick — drop record? buffer? abort tick? = undefined edge case

**Why this matters:**

- QA Phase ไม่มี way ที่ deterministic จะ pass/fail NFR — judgment call ต่อรอบ regression = inconsistent gate
- Architect phase ออกแบบ profiler harness ไม่ได้เพราะไม่รู้ measurement contract
- Live drift > 5ms อาจเกิดบ่อยใน volatile market (Hypothesis H2 risk) — ถ้าไม่ระบุ behavior on overshoot, code อาจ silently lose journal records

**Minimum acceptable fix:**

NFR-2.1: ระบุ:
- Measurement tool: เช่น `GetMicrosecondCount()` MQL5 native API (เป็น WHAT, ไม่ใช่ HOW เพราะ measurement protocol = part of testability)
- Sample size: ≥ 5,000 ticks ของ regression run
- Aggregation: avg + p95 + p99
- Original instrumentation strategy: BA ระบุว่า QA ต้อง add temporary timestamp เข้า EA เดิม (1 line `Print()` ที่ OnTick start/end) — ลบหลังวัดเสร็จ; หรือใช้ Strategy Tester export กับ analyze offline

NFR-2.2: เพิ่ม overshoot behavior — เช่น "ถ้า journal write > 5 ms ติดต่อกัน N ครั้งใน window M ticks → emit tagged warning + ไม่ block trade flow (degrade-but-continue)"

**Effort:** Medium

---

#### Claim 01.9: 🟡 MEDIUM — NFR-1.6 per-slot baseline distribution ถูก defer ไปยัง QA — Architect ออกแบบ regression check ไม่ได้

**Location:** `03-non-functional-requirements.md` § NFR-1.6 (line 92–104)

**Problem:**

> "**Baseline source** | Extract จาก `ReportTester-25045474.html` order list (regex on Comment field) — extraction จะทำใน QA Phase"

NFR-1.6 lock ค่า tolerance ที่ ±15% / >30% (per OQ-7 resolved) แต่ **baseline trade count ของแต่ละ slot ยังไม่มี** จนกว่า QA Phase 3T extract. Architect / TD จะออกแบบ regression check function ตอนนี้ไม่ได้เพราะ:

- ไม่รู้ว่า slot ใดเทรดบ่อย / slot ใดเทรดน้อย — config + UI grouping ของ regression report จะตัดสินใจไม่ได้
- ไม่รู้ว่ามี slot ไหนที่ 0 trades ใน baseline (กระทบ Claim 01.5 + AC-2.1.1)
- "absolute fallback ถ้า baseline trade < 5" → exact threshold ที่จะ flip จาก percentage → absolute = TBD

**Why this matters:**

- BA Phase ต้องส่งมอบ "ทุก requirement quantified" — แต่ NFR-1.6 quantified incomplete (rule ครบ, baseline ขาด)
- Schedule risk: Architect blocks until QA extract → Phase 1B กระทบ
- Architect อาจ over-engineer regression check (เผื่อกรณีร้ายแรงสุด) เพราะไม่รู้ distribution

**Minimum acceptable fix:**

BA ทำ extraction เองตอนนี้ — `ReportTester-25045474.html` มีอยู่ใน `docs/foundation-input-sources/` แล้ว. Run regex/grep บน comment field, นับ trade per slot, ใส่ตารางใน NFR-1.6 หรือ appendix:

| Slot | Baseline Trade Count (5-yr) | Tolerance Mode | ±15% range |
|------|----------------------------|----------------|------------|
| C | 45 | percentage | 38–52 |
| ... | ... | ... | ... |

ถ้า extraction ใช้เวลา > 1 hour → mark เป็น TODO + raise เป็น open question รอ user/QA confirm. ห้าม defer ทั้งก้อนไป QA โดยไม่มี placeholder baseline

**Effort:** Medium

---

#### Claim 01.10: 🟡 MEDIUM — Internal-component actors ไม่อยู่ใน `01 § 4` — Stakeholder list ไม่ตรงกับ user stories

**Location:**
- `01-project-brief.md` § 4 Stakeholders (line 66–78)
- `02-functional-requirements.md` user stories ที่ใช้ `RiskManager`, `EA system`, `Slot`, `Time-filter logic`, `Force-Pending state`, `MT5 Platform (system actor)` (FR-2.3, FR-3.6, FR-5.1, FR-6.x, FR-7.x)
- `05-user-flows.md` Actors ที่ใช้ `RiskManager`, `TradeJournal`, `MarketContext`, `PortfolioState`, `EA logger`, `Slot orchestrator`, `MT5 CTrade`, `MT5 Alert`, `Indicator engine`

**Problem:**

`01 § 4` list stakeholders/actors แค่ 5: Trader, AI Agent, MT5 Platform, Broker, Strategy Tester. แต่ใน 02/05 มี actors อีก ≥ 9 ชนิดที่ไม่ enroll ใน 01: RiskManager, TradeJournal, MarketContext, PortfolioState, EA logger, Slot orchestrator, MT5 CTrade, MT5 Alert, Indicator engine, Time-filter logic, Force-Pending state.

บาง actors เป็น **internal components ที่ออกแบบในตัว BA เอง** (RiskManager, TradeJournal, MarketContext, PortfolioState — ดู Claim 01.7) — ใช้เป็น `As a [actor]` ใน user story ทำให้:

- BA "design" component แทน "specify behavior" — overlap กับ Architect's job
- Reader (PM, sponsor) ไม่รู้ว่า component เหล่านี้คืออะไร — ขาด definition ใน Glossary (Claim 01.12)
- `01 § 4` เป็น single source สำหรับ actor list — ถ้าไม่ครบ = onboarding gap

**Why this matters:**

- AC ทุก story ใช้ actor name ที่ undefined → developer 2 คนอ่านอาจตีความต่างกัน (เช่น "RiskManager" = class? service? helper function?)
- Reduce traceability: ถ้า PM ถาม "ทำไม MT5 CTrade เป็น actor ของ FR-2.3" — ไม่มีคำตอบใน BA package

**Minimum acceptable fix:**

Option A (พร้อมกับ Claim 01.7): rephrase user story ที่ใช้ internal component เป็น Trader / EA system / MT5 Platform แทน. เช่น:

- ❌ "As a Slot, I want `Map<int magic, SlotState>` ..." (FR-2.7)
- ✅ "As a Trader, I want EA เก็บ per-slot state ที่ใช้ตรวจ slot ตัวเองได้ใน O(1) ..."

Option B: เพิ่ม sub-section `01 § 4.2 — System internals (referenced as actors in 02/05)` พร้อม brief description ของแต่ละ component (RiskManager, TradeJournal, etc.) + flag เป็น "Architect ออกแบบ implementation, BA define responsibility เท่านั้น"

แนะนำ Option A เพราะ aligned กับ Claim 01.7 fix

**Effort:** Medium

---

#### Claim 01.11: 🟡 MEDIUM — Section openers ขาดใน 03 § 6/7/8 + 04 § 5/9 — กระโดดเข้า list/table โดยไม่มี Thai narrative

**Location:**
- `03-non-functional-requirements.md` § 6 (line 328 — heading "## 6. NFR-6 — Configurability" ตามด้วย "### NFR-6.1" ทันที)
- `03-non-functional-requirements.md` § 7 (line 366)
- `03-non-functional-requirements.md` § 8 (line 404)
- `04-business-rules.md` § 5 (line 202)
- `04-business-rules.md` § 9 (line 426)

**Problem:**

Benchmark `ba-requirements-prompt.md § LANGUAGE RULE`:

> "**ทุก H2/H3 with content:** ≥ 1 Thai sentence ก่อน first table/code/diagram"
> "Section opener กระโดดเข้า table/code ไม่มี Thai lead-in → reader ต้องเดาว่า section นี้เล่าอะไร"

5 sections ใน `03/04` กระโดดเข้า sub-section ทันทีหลัง heading H2. เปรียบเทียบกับ § 1-5 ของ `03` ที่มี opener ครบ ("หมวดนี้คือ acceptance contract หลัก..." ฯลฯ) — แสดงว่า BA รู้ pattern แต่ skip บาง section

**Why this matters:**

- PM/Architect ที่ scan-read ผ่าน TOC + heading จะไม่รู้ว่า § 6/7/8 ของ `03` เล่าอะไร นอกจากชื่อ "Configurability/Compatibility/Usability"
- Wall-of-table (ตารางถี่ๆ ติดกัน) อ่านยาก ถ้าไม่มี narrative bridge

**Minimum acceptable fix:**

เพิ่ม 1-2 ประโยค Thai opener ก่อน sub-section แรก. ตัวอย่าง:

- `03 § 6`: "Configurability เป็น G1 enabler ตรง — ถ้า user tune ไม่สะดวก = rewrite เสียจุดประสงค์. หมวดนี้ระบุข้อบังคับของ MT5 input dialog + Strategy Tester optimization compatibility."
- `04 § 5`: "EA เดิมใช้ formula ของ lot ต่อ slot กระจายใน CodeWiki §4.1 — หมวดนี้ lock formula ทุก row + เพิ่ม cap/floor เพื่อกัน broker reject."

**Effort:** Low

---

#### Claim 01.12: 🟡 MEDIUM — Glossary `01 § 8` ขาด trading indicators + helper function names ที่ใช้ตลอด BA package

**Location:** `01-project-brief.md` § 8 Glossary (line 186–219)

**Problem:**

Benchmark § Readability Contract:

> "ศัพท์โดเมน (SKU, reconciliation, cut-off D-1), acronym (AR/AP, OEM), ชื่อระบบภายใน — **define ครั้งแรกที่ใช้** หรือรวมไว้ที่ `01-project-brief.md § Glossary`"
> "Rule of thumb: ถ้า junior dev / PM ใหม่อาจงง → define"

ตรวจ glossary ของ `01 § 8` (~25 entries) — ครอบคลุม Slot/Magic/MarketContext/PortfolioState/PendingState ฯลฯ แต่**ขาด** terms ต่อไปนี้ที่ใช้ตลอด FR/BR/Flow:

- **Trading indicators**: WPR, ADX, Force, Bollinger (BB, BBBot, BBTop), DeMarker, Stochastic, MACD, Hull, Fractal, ZigZag, SubDem, Ichimoku (cloud, edges, Tenkan/Kijun) — ใช้ในแทบทุก slot signal description
- **Helper function names**: WatchProfits, ReadTradeData, LoadGlobal, SaveFileDatabase, OpenOrderCD, OpenOrderH/J/K/G/M/Q/L/LX/B/BR/BI/I/P/T/S, CalculateLotSize, ExtraTakeProfit_X, BusinessLogic_X — ใช้ใน FR-3.x, FR-5.x, FR-7.x, F1-F7
- **Hypothesis tags**: H1 (default value 1:1), H2 (perf overhead), H3 (journal latency) — `01 § 5.2` mention H1, `03` mention H2/H3 ใน "Why" lines แต่ไม่อยู่ใน Glossary
- **EA terms**: `_pendingPrice`, `pip distance`, `cloud-touch`, `spread spike`, `weakOrderCount`, `badPIP`, `currentProfit`, `peak-reversion`, `bug-fix bucket A/B`

PM ใหม่ / Architect ที่ไม่ได้เคยเทรด forex จะ stuck ที่ "WPRWaveSignal", "ForcePeak3=ascending", "cloud-touch" ฯลฯ

**Why this matters:**

- Onboarding cost สูง — Architect ใช้เวลา query CodeWiki แทนที่จะ design
- Reader ไม่ได้อยู่ในทีม trading จะรู้สึก wall-of-jargon ใน FR-2.6 / FR-4.1 / BR-5.x

**Minimum acceptable fix:**

เพิ่ม 2 sub-sections ใน `01 § 8`:

- **§ 8.1 Trading Indicators**: list ทุก indicator + 1-line definition + timeframe ที่ใช้ (H4/M10/D1/M15/M5)
- **§ 8.2 EA Helper Functions**: list naming pattern (`BusinessLogic_X` = entry function ของ slot X; `ExtraTakeProfit_X` = exit/management function ของ slot X; `OpenOrder_X` = lot calculation + broker submission helper; etc.)
- เพิ่ม Hypothesis H1/H2/H3 ใน main glossary

ไม่ต้อง define ทุกตัวแบบละเอียด — link ไป CodeWiki ก็พอ ถ้า definition ยาว

**Effort:** Medium

---

#### Claim 01.13: 🟡 MEDIUM — FR-6.5 AC-6.5.2 vague — "unexpected trade pattern" ไม่ define

**Location:** `02-functional-requirements.md` § FR-6.5 AC-6.5.2 (line 569–571)

**Problem:**

> "Given QA regression test มี DST transitions ใน period (March + October ในแต่ละปี), When เปรียบเทียบ trade pattern around DST switch, Then **ไม่พบ unexpected trade pattern** ใน 1-hour window รอบ DST switch"

"Unexpected" คืออะไร? ไม่มี baseline pattern ระบุ. QA จะตัดสินยังไงว่า trade ที่เปิดใน window นั้นเป็น expected หรือ unexpected?

**Why this matters:**

- QA pass/fail ขึ้นกับ judgment call ของผู้ตรวจ ทุกครั้งจะอ่านเหมือนกันไม่ได้
- DST handling เป็นเหตุที่ ban C-10 + FR-6.5 ถูกเขียน — ถ้า AC verify ไม่ได้ deterministic = NFR-7.3 (DST switch 100% correct) ก็ verify ไม่ได้
- FR-6.5 priority = Must, NFR-7.3 ก็ Must — แต่ถ้า test ไม่ deterministic, Must ก็ไม่มีความหมาย

**Minimum acceptable fix:**

เปลี่ยน AC-6.5.2 เป็น verifiable spec:

> "Given QA regression test period ครอบคลุม DST switch ทุกปี (Mar 2021 - Oct 2025 = 10 transitions), When QA inspect trade list for the 4-hour window centered ที่ DST switch (broker server time), Then trade ที่เปิดในช่วง 00:00–00:05 server-time **ในวันที่ DST switch** ต้อง = 0 (เหมือน FR-6.1 IsMorningWakeup ทำงานที่ 00:00 server-time หลัง DST shift) — ถ้ามี trade ใน window นี้ = DST handling ผิด"

**Effort:** Low

---

### 🔵 LOW

#### Claim 01.14: 🔵 LOW — NFR Security category ขาดการ explicit acknowledge

**Location:** `03-non-functional-requirements.md` § 1-8 (overall)

**Problem:**

Benchmark `ba-requirements-prompt.md § Phase 1 ANALYZE`: "Define NFRs (ต้องมี measurable targets)" — implied ครบ Performance, Security, Availability, Usability, Scalability. `03` ครอบคลุม 8 หมวด แต่**ไม่มี Security category** เลย

จริงอยู่ว่า project นี้ local-only EA, no network, solo operator → security surface น้อย — แต่ ห้าม **silent skip**. Best practice: explicitly note category พร้อม justification ว่าทำไม out-of-scope

**Why this matters:**

- Reviewer / Sponsor อ่าน `03` แล้วถามว่า "ทำไมไม่มี Security" → BA ไม่มีคำตอบเป็นเอกสาร
- ในอนาคต Phase 2 ถ้าเพิ่ม cloud sync (defer per `01 § 6.1`) → Security category จะถูกรื้อ; ถ้ามี explicit "out-of-scope rationale" ตั้งแต่ Phase 1 = baseline easier

**Minimum acceptable fix:**

เพิ่ม sub-section สั้น ใน `03 § 5 (Safety)` หรือ `03 § 7 (Compatibility)` หรือใหม่ `§ 9 — Security (out-of-scope rationale)`:

> "Security NFR category ถูก out-of-scope ใน Phase 1 เพราะ: (1) EA run local ใน MT5 sandbox — ไม่มี network, ไม่มี external API, ไม่มี multi-user; (2) Trade journal เก็บ local-only (FR-4.3) — ไม่มี PII transit; (3) No external DLLs (NFR-7.2) — ไม่มี supply-chain risk จาก imported binaries; (4) Single-user (C-9) — no auth/authz needed. Phase 2 ถ้าเพิ่ม cloud sync = re-evaluate."

**Effort:** Low

---

#### Claim 01.15: 🔵 LOW — ⚠️ marker ถูก re-purpose ใน Constraints C-5/C-6/C-7 — ขัดกับ assumption-marking convention

**Location:** `01-project-brief.md` § 7 Constraints (line 174–176)

**Problem:**

ตาราง Constraints ใช้ ⚠️ ใน column "Negotiable?" ของ row C-5, C-6, C-7:

| # | Constraint | Negotiable? |
|---|-----------|-------------|
| C-5 | Broker FBS ... | **⚠️** ผลกระทบ spread/swap แต่ไม่เปลี่ยน |
| C-6 | Capital tier USD 500–1,000 | **⚠️** |
| C-7 | Leverage 1:500 | **⚠️** |

แต่ benchmark + 04 BR-7.1/7.2 + AC ของ FR-3.3/3.4 ใช้ ⚠️ เพื่อ mark **assumptions / bug-fix flag** (เช่น "BI = naked exposure ⚠️"). ผสม semantic ของ marker เดียวกันใน 2 บริบท = ambiguous

**Why this matters:**

- AI agent / human reviewer grep `⚠️` เพื่อหา assumption — จะเจอ negotiable constraints ปนเข้ามา → false-positive in audit list
- Reader ไม่รู้ว่า ⚠️ ใน constraint หมายความว่า "assumption" หรือ "negotiation possible"

**Minimum acceptable fix:**

เปลี่ยน ⚠️ ใน constraint table เป็น 🟡 (yellow circle) หรือ "yes (with caveat)" หรือ "soft" — สงวน ⚠️ ไว้สำหรับ assumption / bug-fix tag เท่านั้น. Update Glossary entry "Bug-for-bug compatibility" + "Bucket B drift" ก็ใช้ ⚠️ ปกติ; แค่ table นี้แก้

**Effort:** Low

---

#### Claim 01.16: 🔵 LOW — `state/overview.md` notes line ยาวเกิน + ผสม count ที่ stale

**Location:** `docs/state/overview.md` line 10

**Problem:**

Notes cell มีความยาว ~600 chars ใน 1 cell — รวม MoSCoW count, NFR count, BR count, flow count, OQs resolution, MVP signal, next action. cell แบบนี้:

1. อ่านยาก (ไม่มี newline ใน table cell ของ markdown standard)
2. M=34 ไม่ตรงกับจริง (Claim 01.4) — propagate stale number
3. ผสม informational (count) + actionable (next action) ใน cell เดียว

**Why this matters:**

- `/next` workflow query line นี้เพื่อ orient → ถ้า count ผิด, `/next` แนะนำผิด
- Sponsor scan state-overview แล้วงงว่า "5 OQs resolved" + "MVP signal applied" + "next /ba-review" คือ status เดียวกันหรือ history

**Minimum acceptable fix:**

แยก cell เป็น sub-bullet ใน "Notes" หรือ split ออกเป็น 2-3 columns. อย่างน้อย:

- Update count ตาม Claim 01.4 (M=36 ไม่ใช่ 34)
- ตัด "Next: /ba-review" ออก (จะ stale หลัง claim review เสร็จ; live next-action ควรอยู่ใน workflow state)

**Effort:** Low

---

## Cross-Document Issues

| # | Issue | Docs | Severity |
|---|-------|------|----------|
| X1 | Slot U included in journal schema; Slot F missing | `05 § F7.5` ⊥ `02 § FR-2.2` ⊥ `04 § BR-1.1` ⊥ `01 § 5.1` | 🔴 (Claim 01.1) |
| X2 | Slot F absent from topo-sort across 3 docs | `02 § FR-2.4 AC-2.4.2` + `04 § BR-2.2` + `05 § F1.3` | 🟠 (Claim 01.2) |
| X3 | MoSCoW count drift across TL;DR / footer / endnote / state-overview | `02` 3 จุด + `03` 3 จุด + `state/overview.md` 1 จุด | 🟠 (Claim 01.4) |
| X4 | Internal-component actors (RiskManager, TradeJournal, etc.) ใช้ใน 02/05 แต่ไม่อยู่ใน `01 § 4` | `01 § 4` ⊥ `02` user stories ⊥ `05 § F2.2/F3.2/F7.2` | 🟡 (Claim 01.10) |
| X5 | Tech-leak (Map<>, abstract class signature, temp+rename) — repeated identical across 01 + 02 | `01 § 5/8` + `02 § FR-2.5/2.7/5.2` | 🟡 (Claim 01.7) |
| X6 | Glossary missing trading indicators + helper function names referenced ทุก doc | `01 § 8` ⊥ `02/03/04/05` everywhere | 🟡 (Claim 01.12) |

ไม่พบ contradictions อื่นข้าม BA docs นอกเหนือจากข้างต้น (entity/actor/flow naming conventions consistent for the actors that DO appear in `01 § 4`).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 01.1 | 🔴 CRITICAL | Trade journal `slot_id` enum has Slot U + missing Slot F | `05 § F7.5 line 564` | Low |
| 01.2 | 🟠 HIGH | Slot F missing from topo-sort + entry pass list | `02 AC-2.4.2`, `04 BR-2.2`, `05 F1.3` | Low |
| 01.3 | 🟠 HIGH | FR-7.7 controlled halt: open positions ownership undefined | `02 § FR-7.7` | Medium |
| 01.4 | 🟠 HIGH | MoSCoW counts wrong + drift across 7 statements | `02` x3 + `03` x3 + `state/overview` | Low |
| 01.5 | 🟡 MEDIUM | FR-2.1 AC-2.1.1 too strict ("≥1 trade ทุก slot") | `02 § FR-2.1` | Low |
| 01.6 | 🟡 MEDIUM | M-Pending / T-Pending / Q-Pending lack explicit timeout | `04 § BR-6.5/6/7`, `05 § F4.5` | Medium |
| 01.7 | 🟡 MEDIUM | Tech-leak: Map<>, abstract class, temp+rename | `01 § 5/8`, `02 § FR-2.5/2.7/5.2` | Medium |
| 01.8 | 🟡 MEDIUM | NFR-2.1 / NFR-2.2 missing measurement protocol | `03 § NFR-2.1/2.2` | Medium |
| 01.9 | 🟡 MEDIUM | NFR-1.6 per-slot baseline distribution deferred to QA | `03 § NFR-1.6` | Medium |
| 01.10 | 🟡 MEDIUM | Internal-component actors not in `01 § 4` stakeholder list | `01 § 4` ⊥ `02/05` | Medium |
| 01.11 | 🟡 MEDIUM | Section openers missing in 03 § 6/7/8 + 04 § 5/9 | `03 § 6/7/8`, `04 § 5/9` | Low |
| 01.12 | 🟡 MEDIUM | Glossary missing indicators + helper function names | `01 § 8` | Medium |
| 01.13 | 🟡 MEDIUM | FR-6.5 AC-6.5.2 vague ("unexpected" undefined) | `02 § FR-6.5` | Low |
| 01.14 | 🔵 LOW | NFR Security category not explicitly acknowledged | `03 § overall` | Low |
| 01.15 | 🔵 LOW | ⚠️ marker re-purposed in Constraint table | `01 § 7` | Low |
| 01.16 | 🔵 LOW | `state/overview.md` notes line stale + cluttered | `state/overview.md line 10` | Low |

**Priority for `/ba-rebuttal`:** Claim 01.1 (CRITICAL) ก่อน — fix ใช้เวลาเพียง 1 line edit แต่ block TD lock; Claim 01.2 + 01.4 เป็น Low-effort HIGH ที่ทำพร้อมกันได้; Claim 01.3 (Medium effort, HIGH severity) ต้อง user input เรื่อง halt mechanism — ถ้า user มี capacity ในรอบ rebuttal นี้.
