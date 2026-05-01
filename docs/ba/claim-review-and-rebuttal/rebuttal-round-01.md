# BA Rebuttal Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Claim Review** | `claim-review-01.md` |
| **Date** | 2026-05-01 |
| **Defender** | BA agent (`andm-ba-defender` persona, `/ba-rebuttal` workflow) |
| **SKILLs** | business-analyst, brainstorming, research-engineer, documentation-templates |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 13 |
| Partial | 3 |
| Rejected | 0 |

**Files modified:**
- `01-project-brief.md` — 6 changes (§ 4 actor convention note, § 5.5 architecture phrasing, § 7 marker convention + soft markers, § 8 Glossary edits + new § 8.1/8.2, § 5.4 Won't permanent — n/a)
- `02-functional-requirements.md` — 16 changes (TL;DR + footer + endnote counts; FR-2.1 AC, FR-2.5/2.6/2.7 rewrite, FR-3.1/3.2/3.5/3.6/6.1-6.5/6.7/7.3/8.1 actor rephrase, FR-5.2 atomic-write rephrase, FR-6.5 AC-6.5.2 + new AC-6.5.3, FR-7.7 priority Must + new AC-7.7.3/7.7.4 + Phase 2 known gap, FR-7.7 row in MoSCoW table)
- `03-non-functional-requirements.md` — 9 changes (TL;DR + footer + endnote counts; NFR-1.6 architecture note, NFR-2.1 measurement protocol, NFR-2.2 measurement protocol + overshoot, NFR-5.1 priority Must + summary table row, § 5 Security out-of-scope note, § 6/7/8 openers)
- `04-business-rules.md` — 4 changes (§ 5/9 openers, BR-2.2 F/GO/BR sub-call table, BR-6.5/6/7 invalidation conditions + OQ-A1/A2/A3)
- `05-user-flows.md` — 4 changes (F1.3 Mermaid F/GO/BR note, F4.5 timeout/invalidation table, F4.6 stuck-pending error path, F7.5 slot_id enum)
- `docs/state/overview.md` — 1 change (Notes column rewrite + count update)

**Total claim coverage:** 16/16 — ทุก finding ได้ verdict + action; ไม่มี skip

---

## Claim Responses

### Claim 01.1: 🔴 CRITICAL — Trade journal `slot_id` enum has Slot U + missing Slot F
**Verdict:** Accept

**Rationale:** ตรงกับ evidence ที่ reviewer cite — schema ใน `05 § F7.5` มี `U` (ขัด FR-2.2 + BR-1.1 strikethrough) + ขาด `F` (ขัด FR-2.1 21 slots + BR-1.1 row 48 MagicF=201). 1-line copy-paste bug ที่จะ propagate เข้า TD lock schema → fix ก่อน handoff.

**Changes:**
- File: `docs/ba/05-user-flows.md` § 8 F7.5 record schema (line 564)
- What changed: เปลี่ยน enum จาก `"C|D|J|H|K|G|G2|GO|M|L|LX|Q|R|I|P|T|S|B|BR|BI|U"` (21 ค่า, มี U, ไม่มี F) เป็น `"C|D|F|J|H|K|G|G2|GO|M|L|LX|Q|R|I|P|T|S|B|BR|BI"` (21 ค่า, ไม่มี U, มี F, sorted ตาม topo-sort C/D/F first per BR-2.2)
- Evidence (new text): *"`"slot_id": "C|D|F|J|H|K|G|G2|GO|M|L|LX|Q|R|I|P|T|S|B|BR|BI"`,"*
- Verified cross-doc: ไม่มี enum list อื่นที่ขัดกัน (grep `slot_id|MagicU` แสดงเฉพาะ refs ที่ describe deletion อย่างเป็นทางการ)

---

### Claim 01.2: 🟠 HIGH — Slot F missing from topo-sort + entry pass list
**Verdict:** Accept

**Rationale:** F chain semantic อยู่ใน BR-2.1 (`F → C/D pool — chain`) อยู่แล้ว แต่ topo-sort 3 จุดไม่ใส่ explicit note → Architect ต้องเดาว่า F คือ standalone step หรือ sub-call ของ C/D. รับ + เพิ่ม sub-call table ใน BR-2.2 (F + GO + BR) เพื่อให้ design topo-sort + verify AC-2.4.2 ทำได้

**Changes:**
- File: `docs/ba/04-business-rules.md` § BR-2.2
- What changed: เพิ่มตาราง "Slots ไม่อยู่ใน main topo-sort" ที่ระบุ F = chained ใน C/D's evaluate (เมื่อ `isFOff==false`), GO = post-exit hook ของ G (จาก `ExtraTakeProfit_G`), BR = orphan exit-trigger ของ B (จาก `ExtraTakeProfit_B`) + Validation hint ใหม่ที่ tell QA ว่า F/GO/BR ปรากฏใน trade journal โดย `triggering_function` แทน standalone log
- Evidence (new text): *"F = sub-strategy ของ CD pool — chain semantic ตาม BR-2.1; GO = exit-trigger only — ไม่มี standalone signal; BR = orphan slot ตาม CodeWiki §6.2 P2.2"*
- File: `docs/ba/02-functional-requirements.md` § FR-2.4 AC-2.4.2
- What changed: ขยาย AC ให้รวม note ว่า F/GO/BR ไม่อยู่ใน main topo-sort เพราะ chain/triggered จาก slot อื่น + cross-ref `04 § BR-2.1/BR-2.2`
- File: `docs/ba/05-user-flows.md` § F1.3 Mermaid diagram (entry pass node)
- What changed: เพิ่ม note ใน entry pass node ว่า F chained inside C/D evaluate; GO post-exit hook; BR orphan-exit — see BR-2.2 sub-call table

---

### Claim 01.3: 🟠 HIGH — FR-7.7 controlled halt: open positions ownership undefined
**Verdict:** Partial

**Accepted part:** Reviewer ถูก — AC-7.7.2 "ไม่ trade ต่อ" ขัดกับ "EA ยัง attached"; ไม่มี clarity ว่า OnTick callback ถูก skip ทั้งหมดหรือ exit pass ทำงานต่อ → ผลคือ open positions อาจ orphan. ยอมรับ + เพิ่ม AC ที่ระบุ exit-pass-continues semantic + upgrade priority ของ FR-7.7 + NFR-5.1 จาก Should → Must เพราะ trigger sources priority = Must (ทำให้ Should notification = inconsistent priority)

**Rejected part (deferred):** AC-7.7.4 escalation alert ของ reviewer ที่เสนอ "second alert หลัง 1 hour ถ้า user ไม่ acknowledge" ถูก **deferred ไป Phase 2** (document เป็น known gap) — เหตุผล:
- MVP signal 2026-05-01 ห้าม Telegram/email/webhook (ดู `01 § 6.2 Won't Permanent` row "Telegram / email / webhook notifications")
- MT5 native `Alert()` popup เพียงทางเดียวที่ MVP มี — ไม่มี way "second alert" ที่ user mute ครั้งแรกแล้วยังจะ ack ได้
- Solo operator ที่ไปจากเครื่อง = manual halt (detach EA) อยู่นอก MVP scope; auto-close-after-N-hours จะเป็น Phase 2 feature ที่ต้อง design ใหม่
- ทดแทน — เพิ่ม AC-7.7.4 ที่ describe ภาวะ "halted + portfolio empty" (positions ปิดหมดผ่าน exit pass) → emit `halt-stable` journal + Alert; ครอบคลุม happy path ของ stuck-halt scenario

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § FR-7.7
- What changed: 
  - User story rewrite — actor "Trader", goal เพิ่ม "manage exits ต่อ, ไม่เปิด entry"
  - Priority: Should → **Must** + Why ขยายอ้าง G4 + trigger consistency
  - **AC-7.7.3 (NEW):** Given EA halted, When OnTick events arrive, Then exit pass อย่างเดียว (manageExits ของทุก slot) + skip entry pass + ไม่มี new orders
  - **AC-7.7.4 (NEW):** Given halted + portfolio empty, Then emit `halt-stable` journal + second Alert
  - **Known gap (Phase 2):** Long-running halt + user away — defer escalation policy
- File: `docs/ba/02-functional-requirements.md` § 10 MoSCoW Summary Table — FR-7.7 row priority Must
- File: `docs/ba/03-non-functional-requirements.md` § NFR-5.1 — priority Should → **Must** + Why ขยายอ้าง trigger sources
- File: `docs/ba/03-non-functional-requirements.md` § 9 NFR Summary Table — NFR-5.1 row priority Must
- Evidence (new text):
  > *"AC-7.7.3: Given EA in halted state, When OnTick events arrive, Then EA execute exit pass อย่างเดียว (manageExits ของทุก slot ทำงานต่อ — TP/SL/trailing/cloud-touch logic ของ EA เดิมยังจัดการ open positions) + skip entry pass (ไม่มี slot เปิด new market order, ไม่มี pending state machine fire) — เพื่อให้ open positions ปิดตาม strategy เดิมและไม่กลายเป็น orphan exposure"*

---

### Claim 01.4: 🟠 HIGH — MoSCoW counts wrong + drift across 7 statements
**Verdict:** Accept

**Rationale:** Verified counts ตรงกับ reviewer — FR table 41 rows + NFR table 30 rows; recompute หลัง 01.3 cascade upgrade FR-7.7 + NFR-5.1 → ใช้ตัวเลขใหม่: FR Must 37 / Should 2 / Could 2; NFR Must 26 / Should 4 / Could 0

**Changes:**
- File: `docs/ba/02-functional-requirements.md` line 11 (TL;DR), line ~800 (footer), line ~849 (endnote)
- What changed: TL;DR "8 epics + 38 user stories" → "8 epics + 41 user stories"; "Must 30/Should 5/Could 3/Won't 0" → "Must 37/Should 2/Could 2/Won't 0"; footer + endnote counts ตรงกัน
- File: `docs/ba/03-non-functional-requirements.md` line 13 (TL;DR), line ~470 (footer), line ~509 (endnote)
- What changed: "Must 22/Should 3/Could 0" + "Must 22/Should 5/Could 0" → "Must 26/Should 4/Could 0" ทุกจุด
- File: `docs/state/overview.md` line 10
- What changed: Notes column rewrite — "M=34 S=3 C=2 W=0" → "M=37 S=2 C=2 W=0 (41 user stories, 8 epics); NFR M=26 S=4 C=0"; ตัด stale "Next: /ba-review" + ตัด redundant OQ list (ย้ายไป 02 § 12 / 03 § 10 / 04 § 12 / 05 § 10)
- Evidence (new text):
  > *"Distribution count: Must 37 / Should 2 / Could 2 / Won't 0 (Won't อยู่ใน 01-project-brief.md § 6)"*

---

### Claim 01.5: 🟡 MEDIUM — FR-2.1 AC-2.1.1 too strict ("≥1 trade ทุก slot")
**Verdict:** Accept

**Rationale:** Reviewer ถูก — AC-2.1.1 strict "≥1 trade ทุก slot" จะ false-positive fail ถ้า baseline มี slot ที่ trade=0 (เช่น BR orphan); ขัดกับ NFR-1.6 OQ-7 absolute fallback rule (`slot baseline < 5 trades = absolute tolerance`). Align AC กับ NFR-1.6

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § FR-2.1 AC-2.1.1
- What changed: "ทุก slot ใน CodeWiki §1.5 ยกเว้น U ปรากฏใน trade list อย่างน้อย 1 trade" → "ทุก slot ที่ baseline มี ≥ 1 trade ใน 5-yr period ปรากฏใน rewrite trade list อย่างน้อย 1 trade; slot ที่ baseline = 0 trades ไม่บังคับ + reuse tolerance rule ของ NFR-1.6 (absolute fallback ±2 trades สำหรับ slot ที่ baseline < 5 trades)"
- Evidence (new text): *"Then ทุก slot ที่ baseline มี ≥ 1 trade ใน 5-yr period ปรากฏใน rewrite trade list อย่างน้อย 1 trade; slot ที่ baseline = 0 trades (per per-slot extraction ใน NFR-1.6) ไม่บังคับ"*

---

### Claim 01.6: 🟡 MEDIUM — Pending state machines lack explicit timeout
**Verdict:** Partial

**Accepted part:** Reviewer ถูก — M-Pending/T-Pending/Q-Pending ขาด explicit timeout/invalidation specification ใน BR; F4.6 stuck-pending error path อ้างถึง "expected timeout × 2" ที่ undefined → ทำ design ไม่ได้. ยอมรับ + document invalidation conditions ที่ EA เดิม **มีจริง** (จาก CodeWiki §2.5)

**Rejected part:** Reviewer's recommendation "propose default safe timeout (เช่น 100 H4 bars สำหรับ M-Pending; 24 H4 bars สำหรับ T-Pending)" ถูก **rejected** — เหตุผล:
- BA ห้ามเดา HOW; force-clear safety policy = state cleaner design (Architecture concern)
- "Default safe timeout" จะ contradict CodeWiki §2.5 ที่ระบุชัดว่า EA เดิมไม่มี hard timeout — เพิ่ม timeout 100 bars ใน rewrite = behavioral drift (G3 violation)
- ทดแทน — flag เป็น **Architecture-domain Open Question (OQ-A1/A2/A3)** ให้ Architect Phase 1B resolve ตอน design state cleaner; Architect จะตัดสินใจ trade-off ระหว่าง "no force-clear" (preserve baseline) vs "safety force-clear with state file growth bound" + document reasoning

**Changes:**
- File: `docs/ba/04-business-rules.md` § BR-6.5 (M-Pending)
- What changed: เพิ่ม invalidation arrow ใน state diagram ("M signal flip overwrites snapshot") + Timeout/invalidation row ที่ระบุว่า "EA เดิมไม่มี hard timeout — invalidation มี 2 แบบเท่านั้น: trigger condition met หรือ signal flip" + raise OQ-A1
- File: `docs/ba/04-business-rules.md` § BR-6.6 (T-Pending) — Timeout/invalidation row + raise OQ-A2 + cross-ref CodeWiki §3 Slot T section ให้ Architect
- File: `docs/ba/04-business-rules.md` § BR-6.7 (Q-Pending) — diagram ขยาย + Timeout/invalidation row + raise OQ-A3
- File: `docs/ba/05-user-flows.md` § F4.5 — alternative paths table ที่อ้างถึง "(no fixed timeout in CodeWiki)" → "(no hard timeout — see OQ-A1/A2/A3)"
- File: `docs/ba/05-user-flows.md` § F4.6 — stuck-pending error path rewrite จาก "expected timeout × 2 → Force clear" เป็น "Architecture-domain force-clear policy (OQ-A1/A2/A3) — Architect resolve"
- Evidence (new text):
  > *"Architecture-domain Open Question (OQ-A1): ถ้า price stuck ใน range + signal ไม่ flip → state อาจค้าง PENDING ตลอด session. Architect (Phase 1B) ต้องตัดสินใจ safety force-clear (เช่น 100 H4 bar fallback) เพื่อป้องกัน state file โต — BA flag เป็น OQ-A1 ไม่ propose ตัวเลขเพราะเกี่ยวกับ state-cleaner design (HOW)"*

---

### Claim 01.7: 🟡 MEDIUM — Tech-leak: `Map<>`, abstract class signature, `temp + rename` pattern
**Verdict:** Accept

**Rationale:** ตรงตาม BA Tech-Agnostic Rule violation. 3 จุด leak HOW: (1) FR-2.5 abstract class method signature, (2) FR-2.7 generic `Map<int, SlotState>`, (3) FR-5.2 AC-5.2.1 `temp + rename` algorithm. Rewrite เป็น behavior contract — concrete API + data structure + persistence pattern → TD decide

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § FR-2.5
- What changed: Title "Slot interface (`Slot` abstract)" → "Slot abstraction (uniform behavior contract)"; user story actor "AI Agent" → "Trader"; method signature lock removed; AC-2.5.1 rewrite ระบุ behaviors (get magic, get name, evaluate, manageExits, get pending state, get dependencies) ผ่าน contract เดียวกัน — concrete API = TD decide
- File: `docs/ba/02-functional-requirements.md` § FR-2.6 — remove `MarketContext` struct/field naming + lock; rephrase เป็น "centralized indicator snapshot per tick" + add "concrete struct/class shape, field naming, immutability model = TD decide"
- File: `docs/ba/02-functional-requirements.md` § FR-2.7 — remove `Map<int magic, SlotState>` + lock; rephrase เป็น "per-slot state lookup by magic identifier in O(1)" + add "data structure (associative container, hash table, struct array) = TD decide ตาม MQL5 native facilities"
- File: `docs/ba/02-functional-requirements.md` § FR-5.2
- What changed: Title + user story rewrite — "atomic state write (replace flat write)" → "atomic state write (crash-safe persistence)"; AC-5.2.1 rewrite จาก specific pattern ("`<file>.tmp` → `FileFlush` → rename") เป็น invariant ("file บนดิสก์อยู่ใน 2 state เท่านั้น: ก่อน write หรือหลัง write — ห้าม partial"); add "implementation pattern (temp+rename, journaling, double-buffered swap, ฯลฯ) = TD decide"
- File: `docs/ba/01-project-brief.md` § 5.4 — `temp + rename` parenthetical removed ("write ต้อง atomic — รายละเอียด invariant ใน FR-5.2")
- File: `docs/ba/01-project-brief.md` § 5.5 — Architecture Refactor list rewrite as behavior contract; "Slot interface" → "Slot abstraction"; "MarketContext snapshot — รวม indicator values" preserved (concept-level term ไม่ใช่ HOW); "PortfolioState map — `Map<>` ..." → "Per-slot state lookup — slot อ่าน state ของตัวเองผ่าน magic identifier ใน O(1)"
- File: `docs/ba/01-project-brief.md` § 8 Glossary — `MarketContext snapshot` + `PortfolioState` entries rewrite ลบ `Map<int magic, SlotState>` + add "concrete data structure = TD decide"
- Evidence (new text):
  > *"FR-5.2 AC-5.2.1: Given EA persist state, When write operation completes, Then file บนดิสก์อยู่ใน 2 state เท่านั้น: (a) เนื้อหาก่อน write นี้ครบสมบูรณ์, หรือ (b) เนื้อหาหลัง write นี้ครบสมบูรณ์ — ห้าม state ระหว่าง partial-write"*

---

### Claim 01.8: 🟡 MEDIUM — NFR-2.1 / NFR-2.2 missing measurement protocol
**Verdict:** Accept

**Rationale:** Verification field เดิม "Strategy Tester profiler หรือ timestamp diff" มี ambiguity 3 ระดับ — ไม่มี sample size, aggregation level, instrumentation strategy, overshoot behavior. Add explicit measurement protocol โดยเก็บ requirement-level (sample count, percentile aggregation, overshoot policy) — **ไม่ prescribe `GetMicrosecondCount()` API** (= HOW; conflict กับ 01.7 Tech-Agnostic fix); ระบุแค่ "QA insert timestamp capture" + "method = TD decide"

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § NFR-2.1
- What changed: 
  - Target ขยาย: "≤ 10%" → "≤ 10% average + ≤ 20% at p95 + ≤ 30% at p99"
  - Verification field split เป็น Verification + Measurement protocol
  - Measurement protocol ระบุ: (a) Instrumentation strategy (QA insert timestamp; method = TD decide), (b) Sample size ≥ 5,000 ticks ต่อ run, (c) Aggregation avg + p95 + p99, (d) Environment parity (เครื่องเดียวกัน, MT5 build เดียวกัน, no other CPU-heavy process), (e) Original instrumentation = QA temporary, ไม่ commit
- File: `docs/ba/03-non-functional-requirements.md` § NFR-2.2
- What changed:
  - Target ขยาย: "≤ 5 ms/tick average" → "≤ 5 ms/tick average + ≤ 10 ms/tick at p95"
  - Measurement protocol: sample ≥ 200 events จาก regression run, avg + p95 aggregation
  - **Overshoot behavior:** "ถ้า journal write > 5ms ติดต่อกัน N ครั้งใน window M ticks → emit tagged warning + continue trade flow (degrade-but-continue — ห้าม block tick หรือ drop journal record)"
- Evidence (new text):
  > *"Measurement protocol: (a) Instrumentation: QA insert timestamp capture ที่ OnTick start + end ของทั้ง original EA และ rewrite (เพิ่ม-ลบ instrumentation = QA work; method = TD decide). (b) Sample size: ≥ 5,000 ticks ต่อ run ของ regression period. (c) Aggregation: report avg + p95 + p99 ของ tick latency distribution"*

---

### Claim 01.9: 🟡 MEDIUM — NFR-1.6 per-slot baseline distribution deferred to QA
**Verdict:** Partial

**Accepted part:** Reviewer ถูกที่ "Architect blocks until QA extract" เป็น schedule risk จริง. Architect ต้อง design regression check function ใน Phase 1B แต่ baseline data extraction = QA Phase 3T → schedule conflict. ยอมรับ + เพิ่ม Architecture note ที่ unblock SD: "Architect design function แบบ parameterized; baseline table loaded at QA time"

**Rejected part:** Reviewer's recommendation "BA ทำ extraction เองตอนนี้ — Run regex/grep บน comment field, นับ trade per slot, ใส่ตารางใน NFR-1.6" ถูก **rejected** — เหตุผล:
- BA Phase 1A scope = requirements discovery + specification, **ไม่ใช่** baseline data extraction (= QA's deliverable + responsibility)
- `ReportTester-25045474.html` เป็น Strategy Tester binary report — extraction ต้อง QA tooling ที่ Phase 3T สร้างขึ้นใน QA harness ที่จะ reuse ตอน rerun regression. ทำใน BA = duplicate effort + QA ต้องสร้างใหม่อยู่ดีตอน rerun
- NFR-1.6 ของ BA quantified ครบที่ rule-level (±15% / >30% / absolute fallback ±2 trades) — quantification ของ baseline data **ไม่ใช่** BA's job; rule + threshold = BA, baseline data = QA artifact
- ทดแทน — เพิ่ม Architecture note ที่ระบุ regression check parameterization (Architect ออกแบบ function ตอนนี้ได้; QA load table ตอน Phase 3T) → schedule unblocked

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § NFR-1.6
- What changed: เพิ่ม "Target" ขยายอย่างชัดเจน — absolute fallback ±2 trades สำหรับ slot ที่ baseline < 5 trades; เพิ่ม **Architecture note (unblock SD)** row ที่บอก "Architect/TD design regression check function parameterized over a per-slot baseline table — table loaded at QA time จาก ReportTester extraction"; spec table schema `(slot_id, baseline_count, tolerance_mode ∈ {percentage, absolute}, threshold)` (TD lock final shape)
- Evidence (new text):
  > *"Architecture note (unblock SD): Architect/TD design regression check function (or QA harness) parameterized over a per-slot baseline table — table loaded at QA time จาก ReportTester-25045474.html extraction. Architect ไม่ blocked รอ baseline data; QA Phase 3T จะ populate table ก่อน rerun regression"*

---

### Claim 01.10: 🟡 MEDIUM — Internal-component actors not in `01 § 4`
**Verdict:** Partial (Option A applied)

**Accepted part:** Reviewer ถูก — internal components (RiskManager, Slot, Time-filter logic, Force-Pending state, CD slot, Slot signal helper) ใช้เป็น user-story actor = ขัด BA convention (actor ควรอยู่ใน `01 § 4`). User stories 11 จุดใน `02` ใช้ internal-component actors. รับ Option A (rephrase actors) — combined fix กับ 01.7

**Rejected part:** Reviewer's Option B (เพิ่ม `01 § 4.2 — System internals`) ถูก **rejected** — เหตุผล:
- เพิ่ม internal components เป็น "actors" จะ recreate Tech-Agnostic Rule violation (Claim 01.7) — internal component = TD design decision, ไม่ใช่ business actor
- BA convention ของ actor list = stakeholder/user-facing perspective; internal component = "the system" ผ่าน Trader's user story
- Reviewer's note ที่ Option A เหนือกว่า "เพราะ aligned กับ Claim 01.7 fix" → ใช้ Option A
- ทดแทน — เพิ่ม "System actor convention" note ใน `01 § 4` ที่ explicit ว่า user stories ใช้ Trader/MT5 Platform/Strategy Tester/Broker actors เท่านั้น; internal components = "EA must..." subject ของ requirement

**Changes:**
- File: `docs/ba/01-project-brief.md` § 4 Stakeholders / Actors
- What changed: เพิ่ม callout box ปลายตาราง "System actor convention" ที่อธิบายว่า internal EA components (slot logic, risk-management helper, pending-state machine, market-context bundle, per-slot state lookup) ไม่ใช่ actor — เป็น implementation detail; user story ใช้ "Trader"/"MT5 Platform"/"Strategy Tester"/"Broker"; behavioral requirement ใช้ "EA must..."
- File: `docs/ba/02-functional-requirements.md` — actor rephrase ใน 11 user stories:
  - FR-2.5: AI Agent → Trader (also Tech-Agnostic fix per 01.7)
  - FR-2.6: Slot (system actor) → Trader
  - FR-2.7: Slot → Trader
  - FR-3.1: Slot → Trader
  - FR-3.2: Slot → Trader
  - FR-3.5: Slot (G/GO/M/S) → Trader
  - FR-3.6: RiskManager → Trader
  - FR-5.2: MT5 Platform (kept — MT5 Platform เป็น actor ใน `01 § 4`)
  - FR-6.1: Slot → Trader
  - FR-6.2: Slot → Trader
  - FR-6.3: Slot → Trader
  - FR-6.4: Slot → Trader
  - FR-6.5: Time-filter logic → Trader
  - FR-6.7: Force-Pending state → Trader
  - FR-7.3: CD slot → Trader
  - FR-8.1: Slot signal helper → Trader
- Evidence (new text):
  > *"System actor convention: User stories ใน 02-functional-requirements.md ใช้ Trader, MT5 Platform, Strategy Tester, Broker. Internal EA components (slot logic, risk-management helper, pending-state machine, market-context bundle, per-slot state lookup) ไม่ใช่ actor — เป็น implementation detail ที่ Architect/TD design ขึ้นมา; user story ใช้ Trader = subject + 'EA must...' / 'the system shall...' phrasing"*

---

### Claim 01.11: 🟡 MEDIUM — Section openers missing
**Verdict:** Accept

**Rationale:** Verifiable rule violation — ทุก H2 ของ `03 § 6/7/8` + `04 § 5/9` กระโดดเข้า sub-section H3 ทันที ไม่มี Thai narrative bridge. ขัด LANGUAGE RULE "ทุก H2/H3 with content: ≥ 1 Thai sentence ก่อน first table/code/diagram"

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § 6 (Configurability) — เพิ่ม Thai opener "หมวดนี้คือ G1 enabler ตรง — ถ้า user tune parameter ไม่สะดวก = rewrite เสียจุดประสงค์หลัก..."
- File: `docs/ba/03-non-functional-requirements.md` § 7 (Compatibility) — Thai opener อธิบาย MT5 build floor + ห้าม external DLL + DST handling
- File: `docs/ba/03-non-functional-requirements.md` § 8 (Usability) — Thai opener อธิบาย solo operator + MT5 native dialog
- File: `docs/ba/04-business-rules.md` § 5 (BR-4 Position Sizing & Lot Cap) — Thai opener อธิบาย formula กระจายใน CodeWiki §4.1 + lock 1:1 + cap/floor
- File: `docs/ba/04-business-rules.md` § 9 (BR-8 Cross-slot Bulk Cleanup) — Thai opener อธิบาย Safe-port + Ichimoku double-bounce + ForceCutloss + overload helpers + ExtraCheckFunction2
- Evidence (new text):
  > *"§ 6 Configurability: หมวดนี้คือ G1 enabler ตรง — ถ้า user tune parameter ไม่สะดวก = rewrite เสียจุดประสงค์หลัก. กำหนด measurable target ของ MT5 native input dialog (≥ 80 inputs ทุนได้, reattach ≤ 30s), Strategy Tester optimization compatibility, และ slot-grouping ของ input UI"*

---

### Claim 01.12: 🟡 MEDIUM — Glossary missing trading indicators + helper function names
**Verdict:** Accept

**Rationale:** Onboarding cost จริง — PM ใหม่ / Architect ที่ไม่ได้เคยเทรด forex stuck ที่ "WPRWaveSignal", "ForcePeak3=ascending", "cloud-touch", "BusinessLogic_C", "ExtraTakeProfit_J" ฯลฯ ที่ใช้ตลอด FR/BR/Flow แต่ไม่ define. รับ + เพิ่ม sub-sections + Hypothesis tags

**Changes:**
- File: `docs/ba/01-project-brief.md` § 8 Glossary
- What changed:
  - Main glossary: เพิ่ม 3 entries (H1, H2, H3 — Hypothesis tags)
  - **§ 8.1 Trading Indicators (NEW):** ตาราง 13 indicators (Ichimoku, Force, ADX, WPR, Bollinger, DeMarker, Stochastic, MACD, RSI, Hull, Fractal, ZigZag, SubDem) พร้อม "Used by slot" + Timeframe + 1-line meaning. Note ว่า definition โดย MetaQuotes; CodeWiki §1.4 list parameter set + timeframes ที่ EA เดิมใช้
  - **§ 8.2 EA Helper Function Naming (NEW):** ตาราง pattern (BusinessLogic_X, ExtraTakeProfit_X, OpenOrder_X, Calculate_X, Ban_State, Cross-slot helpers) — list 7 cross-slot helpers + comment ว่า TD จะ refactor naming ใน slot abstraction
- Evidence (new text):
  > *"§ 8.1: Ichimoku (iIchimoku) | C, D, F, J, H, K, G, GO, M, L, LX, Q, R, B, BR, BI, P, T, S | H4, D1 | Cloud (Senkou A/B) ใช้เป็น dynamic SR; Tenkan/Kijun = momentum lines; Chikou = lagging confirm"*

---

### Claim 01.13: 🟡 MEDIUM — FR-6.5 AC-6.5.2 vague ("unexpected" undefined)
**Verdict:** Accept

**Rationale:** "Unexpected" ไม่ define = QA pass/fail = judgment call ทุกครั้ง. NFR-7.3 (DST switch 100% correct) Must — แต่ไม่มี deterministic verifier. รับ + replace กับ verifiable spec (00:00–00:05 server-time window check on DST switch days)

**Changes:**
- File: `docs/ba/02-functional-requirements.md` § FR-6.5
- What changed: AC-6.5.2 rewrite จาก "ไม่พบ unexpected trade pattern ใน 1-hour window" → "ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch (last Sunday Mar/Oct, 10 transitions ตลอด 5-yr period)" + new AC-6.5.3 ที่ตรวจ trade journal `timestamp` field สะท้อน DST shift ถูกต้อง (ตัวอย่าง Sunday Mar 26 2023)
- Evidence (new text):
  > *"AC-6.5.2: Given QA regression run ครอบคลุม DST transitions ทุกปี (Mar 2021 + Oct 2021 + ... + Oct 2025 = 10 transitions), When QA inspect trade list ของวันที่ DST switch, Then ไม่มี order ใหม่เปิดใน window 00:00–00:05 broker server-time ของวัน DST switch — ตรวจ IsMorningWakeup ทำงานถูก ภายใต้ DST shift; ถ้ามี trade ใน window นี้ = DST handling ผิด → fail"*

---

### Claim 01.14: 🔵 LOW — NFR Security category not explicitly acknowledged
**Verdict:** Accept

**Rationale:** Reviewer ถูก — silent skip ของ Security category = best practice violation; Sponsor / Reviewer ไม่มีคำตอบเป็นเอกสารว่าทำไม out-of-scope. รับ + เพิ่ม note (ไม่ใช่ NFR-X.Y entry) เพื่อไม่กระทบ NFR count

**Changes:**
- File: `docs/ba/03-non-functional-requirements.md` § 5 (Safety) — เพิ่ม callout note "Security NFR category (out-of-scope, Phase 1)" หลัง NFR-5.3 พร้อม 5 reasons (local-only EA, no PII transit, no external DLLs, single-user, no remote sync) + Phase 2 re-evaluation trigger (ถ้า Phase 2 เพิ่ม cloud journal/Telegram/multi-account/dashboard → Security category ต้อง added พร้อม authentication/transport encryption/key management)
- ไม่ใช้ NFR-5.4 ID เพราะ note ไม่มี measurable target → ไม่กระทบ NFR count = 30
- Evidence (new text):
  > *"Note — Security NFR category (out-of-scope, Phase 1): หมวด Security NFR ถูก out-of-scope อย่างเป็นทางการ — ไม่ใช่ silent skip. เหตุผล: (a) Local-only EA ... (e) No remote sync. Phase 2 re-evaluation trigger: ถ้าเพิ่ม cloud journal, Telegram/email notification, multi-account, หรือ remote dashboard → Security NFR category ต้อง added พร้อม authentication, transport encryption, key management"*

---

### Claim 01.15: 🔵 LOW — ⚠️ marker re-purposed in Constraint table
**Verdict:** Accept

**Rationale:** Marker convention violation — ⚠️ ใช้ใน assumption/bug-fix flag ตลอด BR/AC แต่ใน C-5/C-6/C-7 ใช้แทน "negotiable yes" → ambiguous; AI agent / human reviewer grep ⚠️ จะเจอ false-positive

**Changes:**
- File: `docs/ba/01-project-brief.md` § 7 Constraints
- What changed: เพิ่ม Marker convention callout ก่อนตาราง ("❌ No = hard; 🟡 Soft = negotiable Phase 2; ⚠️ marker สงวนไว้สำหรับ assumption / bug-fix flag เท่านั้น"); แทนที่ ⚠️ ใน C-5/C-6/C-7 rows ด้วย 🟡 Soft (พร้อม descriptive text ของ C-5)
- Evidence (new text):
  > *"Marker convention: ❌ No = hard constraint (Phase 1 + Phase 2 ห้ามเปลี่ยน); 🟡 Soft = negotiable Phase 2 พร้อม impact assessment (Phase 1 lock); ⚠️ marker สงวนไว้สำหรับ assumption / bug-fix flag ใน FR/BR/AC เท่านั้น — ไม่ ใช้ใน constraint table"*

---

### Claim 01.16: 🔵 LOW — `state/overview.md` notes line stale + cluttered
**Verdict:** Accept

**Rationale:** Cell ยาว ~600 chars + count stale (M=34) + ผสม informational กับ actionable. รับ + restructure (combined fix กับ 01.4 count update + 01.3 priority change)

**Changes:**
- File: `docs/state/overview.md` line 10
- What changed: 
  - Status: "✅ Complete" → "✅ Complete + Rebuttal Round 01" (clarifies state)
  - Count: "M=34 S=3 C=2 W=0; 30 NFRs" → "FR MoSCoW: M=37 S=2 C=2 W=0 (41 user stories, 8 epics); NFR: 30 (M=26 S=4 C=0)" (correct + accounts for 01.3 cascade)
  - ตัด redundant OQ list (live ใน 02 § 12 / 03 § 10 / 04 § 12 / 05 § 10)
  - ตัด stale "Next: /ba-review" (rebuttal-01 done; live next-action ควรมาจาก workflow state)
  - เพิ่ม pointer to rebuttal-round-01.md + raise OQ-A1/A2/A3 architecture domain
- Evidence (new text):
  > *"Design (BA) | ✅ Complete + Rebuttal Round 01 | 2026-05-01 | 5 docs in docs/ba/. FR MoSCoW: M=37 S=2 C=2 W=0 (41 user stories, 8 epics). NFR: 30 (M=26 S=4 C=0). 9 BR categories; 7 user flows. All 5 OQs ✅ resolved. Rebuttal-01 (2026-05-01) accepted 13 + partial 3 + 0 reject of 16 claims — see claim-review-and-rebuttal/rebuttal-round-01.md. New architecture-domain OQ-A1/A2/A3 (M/T/Q-Pending force-clear) raised for SD."*

---

## Cascaded Changes

(Changes ใน BA docs ที่ **ไม่ได้** cite ใน claims โดยตรง — เกิดจาก cross-doc consistency fix หลัง claim-driven changes)

1. **FR-7.7 priority cascade → MoSCoW counts** — Upgrade FR-7.7 Should → Must (จาก Claim 01.3) ทำให้ FR Must count เพิ่มจาก 36 → 37 + Should ลดจาก 3 → 2; ต้อง update endnote ของ 02 ที่ระบุ "44 acceptance criteria" (FR-7.7 เพิ่ม 2 AC: AC-7.7.3, AC-7.7.4)
2. **NFR-5.1 priority cascade → MoSCoW counts** — Upgrade NFR-5.1 Should → Must (จาก Claim 01.3) ทำให้ NFR Must count เพิ่มจาก 25 → 26 + Should ลดจาก 5 → 4
3. **Tech-leak rephrase cascade — `01 § 5.5` Architecture Refactor** — list rewrite ใน `01 § 5.5` ที่ไม่ใช่ Claim 01.7's primary location (claim cite line 117 + 110 + 206) แต่ list bullets ก็ใช้ "Slot interface" + "MarketContext snapshot" + "PortfolioState map" terminology — rewrite ให้สอดคล้องกับ FR-2.5/2.6/2.7 ใหม่
4. **Slot abstraction terminology cascade — `04 § BR-2.1`** — Dependency Edge Table มี comment "MarketContext + PortfolioState" ในส่วน "All slots" data dep — preserved (concept-level term, ไม่ใช่ HOW)
5. **Hypothesis tag in Glossary cascade** — H1/H2/H3 ใน Glossary main + § 8.1 indicators (Hypothesis cross-ref) — additive; ไม่ break existing references
6. **F1.3 Mermaid + F4.5 table + F4.6 error path** — Cascade จาก Claim 01.2 (F note) + Claim 01.6 (timeout/invalidation) + Claim 01.16 (state cleanup) — ต้อง update Mermaid + ตารางใน flows ให้สอดคล้อง

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | **81%** (13/16) | สูงพอเหมาะ — reviewer's findings ส่วนใหญ่ valid; ไม่ defensive (Accept rate < 50% = red flag per persona) แต่ยังต่ำกว่า 50% ก็ไม่ใช่ — ที่จริงสูง 81% บ่งว่า BA deliverables มี quality issue ที่ควรเจอตั้งแต่ self-check |
| Partial Rate | **19%** (3/16) | Healthy — reviewer มี recommendations ที่ส่วนหนึ่งดี ส่วนหนึ่งเกิน scope/violate guardrail; Partial = nuanced response ที่รับสิ่งที่ valid + reject สิ่งที่ขัด BA scope |
| Reject Rate | **0%** (0/16) | ไม่ red flag — reviewer's findings มี evidence ครบทุกข้อ; ไม่มี case ที่ reviewer miss text ที่ BA ไม่ได้แก้ |
| Critical Fixes | **1** (Claim 01.1) | slot_id enum corruption — fix ก่อน TD lock schema |
| HIGH Fixes | **3** (Claims 01.2, 01.3, 01.4) | Slot F topo-sort + halt semantic + count drift — Architect blocker ก่อนจะ start Phase 1B |
| Net Improvement | **Significant** | (a) tech-agnostic compliance — 3 leaks removed; (b) priority consistency — halt notification = trigger priority; (c) measurement protocol — NFR-2.1/2.2 verifiable; (d) onboarding — Glossary +13 indicators + 7 helper patterns; (e) section openers + actor convention; (f) raise 3 architecture-domain OQ-A1/A2/A3 ที่ Architect ต้อง resolve |
| Remaining Gaps | **4 items** | (a) **Phase 2 known gap** in FR-7.7 — long-running halt + user away (escalation alert deferred); (b) **OQ-A1/A2/A3** (M/T/Q-Pending force-clear) — architecture-domain, Architect Phase 1B resolves; (c) **Per-slot baseline data** — QA Phase 3T extracts; (d) **Phase 2 re-evaluation trigger** for Security NFR category — documented |

---

## Recommendation

- [x] ✅ **Ready for Architecture Handoff** — all Critical/HIGH claims resolved + clear OQ-A1/A2/A3 routing to Architect; tech-leak removed enabling clean SD/TD design space
- [ ] 🔁 Request Re-Review
- [ ] ⛔ Needs Stakeholder Input

**Notes for Architect (Phase 1B = `/sd`):**

1. **OQ-A1/A2/A3** (M/T/Q-Pending force-clear safety policy) ใน `04 § BR-6.5/6/7` — design state cleaner ต้อง resolve; document trade-off ระหว่าง "no force-clear" (preserve baseline) vs "safety force-clear with state file growth bound"
2. **Per-slot baseline parameterization** ใน `03 § NFR-1.6` — design regression check function ที่ parameterized over baseline table (loaded at QA time) — Architect ไม่ blocked รอ baseline data
3. **FR-7.7 + NFR-5.1 priority Must** — halt notification = G4 safety contract; ไม่ใช่ Should
4. **Slot abstraction (FR-2.5)** — concrete API method signature, struct shape, inheritance model, container choice = SD/TD's design space ที่ห้าม BA ลงรายละเอียด; behavior contract ระบุไว้แล้ว
5. **Atomic state write (FR-5.2)** — implementation pattern (temp+rename, journaling, double-buffered swap) = TD decide; BA ระบุ invariant อย่างเดียว
6. **Phase 2 known gap (FR-7.7)** — long-running halt + escalation alert defer Phase 2; Architect Phase 1B ไม่ต้อง design escalation policy

**OQ Routing summary:**

| OQ | Domain | Doc | Resolver |
|----|--------|-----|----------|
| OQ-A1 (M-Pending force-clear) | Architecture | `04 § BR-6.5` | Architect Phase 1B |
| OQ-A2 (T-Pending force-clear) | Architecture | `04 § BR-6.6` | Architect Phase 1B |
| OQ-A3 (Q-Pending force-clear) | Architecture | `04 § BR-6.7` | Architect Phase 1B |
| Phase 2 escalation alert | Phase 2 | `02 § FR-7.7` known gap | Phase 2 BA |
| Phase 2 Security NFR | Phase 2 | `03 § 5 Security note` | Phase 2 BA |

> **End of Rebuttal Round 01** — 16/16 claims processed, 13 accept + 3 partial + 0 reject; ready for Architecture handoff (Phase 1B).
