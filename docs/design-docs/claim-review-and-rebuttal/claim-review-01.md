# System Design Claim Review Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Target** | `all` (02-high-level-architecture, 03-deep-dive, 04-data-flow, 05-security, 07-future-evolution, 08-product-breakdown + 12 ADRs + 4 API specs) |
| **Date** | 2026-05-02 |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** 17 (🔴 CRITICAL **1** / 🟠 HIGH **4** / 🟡 MEDIUM **9** / 🔵 LOW **3**)
**Schedule-leakage check:** ✅ Clean — grep ไม่พบ Sprint/Week/Q[1-4]/team capacity/Phase Plan|Schedule|Roadmap label ใดๆ. 1 false-positive ที่ scan ขึ้น (`IMPL-067` "10 transitions Mar 2021 → Oct 2025") = **historical regression test scope** ของ DST verification (NFR-7.3 + AC-6.5.3) ไม่ใช่ delivery schedule → ผ่าน
**Language check:** ✅ Pass — ทุก doc มี Thai narrative ≥ 40%; TL;DR + section openers + decision rationale เป็นไทย; tech term English (ตาม LANGUAGE RULE)
**No-Hints Pass-Through:** Phase Hints = FULL variant ใน `08`, Evolution Sequence = skipped ใน `07` (greenfield monolith, no cross-service deps) — ทั้งคู่ legitimate ตาม sd.md § Phase Contract
**Previous rounds:** ไม่มี (round 01 = first review)

### Top 3 to Fix First

1. **Claim 01.1** 🔴 — Safe-port HALTED behavior: ADR-010 ขัดแย้งกับ `04 § 9` flow doc; "correction note" แทนที่จะ fix ADR — `docs/design-docs/05-security.md` impl trail ก็จะ inherit confusion
2. **Claim 01.2** 🟠 — Tick-latency budget arithmetic ใน `03 § 2.3` ไม่สมเหตุสมผลกับ NFR-2.1 baseline (1,685 µs ไม่ใช่ "within +700 µs of 7 ms")
3. **Claim 01.3** 🟠 — Indicator handle count inconsistent (21 vs 25 vs 25-30) ระหว่าง ADR-003 / `02 § 4.1` / `04 § 1.1` / `04 § 5.1`

### Verdict

- [ ] ✅ **Ready for Implementation Handoff** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL (01.1) + 4 HIGH → run `/sd-rebuttal claim-review-01.md`
- [ ] ⛔ **Immediate Attention** — fundamental architecture flaw ที่ block implementation

---

## System Design Attack Vector Checklist (22 Categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass | ADR-001 enumerate 3 options + concrete reason (NFR-7.2 + C-12 + FR-2.3 ผูก → only viable) |
| 2 | Service Boundaries | ⚠️ Finding 01.9 | BV vs IndicatorService ownership of FR-7.6 fail-fast — `02 § 4.2` กับ `04 § 5.1` พูดคนละเรื่อง |
| 3 | Communication Patterns | ✅ Pass | Intra-process method calls; no SPOF; 04 § 5.2 ระบุ ban-list ของ wrong-direction calls |
| 4 | Data Consistency | ⚠️ Finding 01.14 | MarketContext immutable + atomic state ✅; **dual-source-of-truth** state.json vs GlobalVariable rule อยู่ใน ADR-007 เท่านั้น ไม่ surface ใน 02 § 6 |
| 5 | Database Design | ✅ Pass | No DB by design; flat files + GlobalVariable + JSON-Lines all justified |
| 6 | Caching Strategy | ✅ Pass | FR-8.1 cache invalidation บน bar close + concrete sizing (~80 KB peak, ~10 µs hit, ~1-2 ms miss) |
| 7 | Security Design | ✅ Pass | STRIDE 6 categories ครบ; AuthN/AuthZ N/A justified พร้อม Phase 2 trigger |
| 8 | Scalability | ✅ Pass | 07 § 1 มี 4 trigger categories; ADR-001 revisit-when concrete |
| 9 | Reliability & Fault Tolerance | ⚠️ Finding 01.4 | Atomic write design รองรับ assumption A2 ที่ยังไม่ verify; ระบบ commit single-file path เป็น primary |
| 10 | Performance Budgets | ⚠️ Findings 01.2, 01.10 | Tick-latency arithmetic ไม่ตรงกับ NFR-2.1 baseline; journal RPO under sustained slow disk = unspecified |
| 11 | Concrete Numbers | ⚠️ Findings 01.3, 01.6 | Most numbers มี derivation; handle count fuzz + ADR-008 thresholds (150/80/100) hand-wavy |
| 12 | API Contract Quality | ⚠️ Finding 01.5 | 4 specs cover major contracts; **slot-abstraction-contract.yaml** ใช้ OpenAPI 3.0.3 format ผิด tool |
| 13 | Data Flow Completeness | ⚠️ Findings 01.1, 01.7, 01.8 | F1-F7 cover; SpreadGuard collapse 3 rules; P-Pending sub-modes ไม่มี narrative |
| 14 | Observability | ⚠️ Finding 01.12 | 05 § 7 ครอบคลุม; **Logger throttle** ตึงกับ NFR-3.4 (0 silent failures) เมื่อ sustained slow disk |
| 15 | ADR Quality | ✅ Pass | 12 ADRs ตาม Title/Status/Context/Options/Decision/Consequences/Revisit-when ทุกตัว; ADR-010 contradiction tracked แยกใน 01.1 |
| 16 | Cross-Doc Consistency | ⚠️ Findings 01.1, 01.3, 01.9, 01.14 | 4 contradictions ระหว่าง doc/ADR/spec |
| 17 | Requirements Traceability | ⚠️ Finding 01.17 | 41 FR + 30 NFR + 9 BR + 8 OQ map ครบ; minor mis-tag ใน BV row ของ `02 § 4.2` |
| 18 | Failure Modes | ✅ Pass | ทุก challenge ใน `03 §§ 1-5` มี Failure modes table + 5 acknowledged risks A1-A5 |
| 19 | Future Evolution + Evolution Sequence | ⚠️ Finding 01.13 | Greenfield skip = legitimate; แต่ 08 Phase Hints carry hard ordering ที่จะ promote เป็น Evolution Sequence ก็ได้ |
| 20 | Work Inventory + Phase Hints | ⚠️ Findings 01.11, 01.13 | 68 tasks sized + per-task metadata ครบ; ADR-002 `=0` enforcement weak |
| 21 | Readability / Reader-Empathy | ⚠️ Findings 01.15, 01.16 | TL;DR + Why-line + Mermaid narrative ครบ; correction-note + glossary noise = blemishes |
| 22 | Language Rule Compliance | ✅ Pass | Thai prose ≥ 40% ทุก doc, TL;DR Thai-led, decision rationale Thai, tech term English |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 01.1: 🔴 CRITICAL — Safe-port HALTED behavior contradicting between ADR-010 and 04-data-flow.md

**Location:** `docs/adr/010-halted-state-exit-only.md` § "Cross-slot logic in halted state" + `docs/design-docs/04-data-flow.md` § 9 "Cross-slot Safety Flow"

**Problem:**
ADR-010 ระบุชัดเจนว่า: *"`OrderGroupStartWorkflow` (Safe port BR-8.1) — **disabled** ใน HALTED (closes ของ Safe port = bulk close ที่ EA ไม่ควรทำเพราะ exit logic ของแต่ละ slot จัดการอยู่ — preserve EA เดิม intent ใน normal-only)"*

แต่ `04 § 9.1` table ของ "RUNNING/HALTED enable matrix" รวมถึง self-correction note ระบุตรงข้าม: *"Re-reading ADR-010 — Safe-port (BR-8.1) closes positions = exit-side action; **we enable in HALTED**. EOverload + GOverload (BR-8.4) = open new orders → disable in HALTED. Updated table reflects this. ADR-010 § 'Cross-slot logic in halted state' should show Safe-port = enabled (correction tracked for TD)."*

ADR-010 ไม่ถูก amend; correction-note ใน 04 ก็ไม่ได้ propagate ออกไปแก้ ADR. ผลลัพธ์ = **2 docs สำคัญพูดคนละเรื่อง** เกี่ยวกับ FR-7.7 / ADR-010 semantic critical (G4 contract).

**Why this matters:**
ADR เป็น authoritative source ของ design decision. TD Phase 1D + Implementation phase อ่าน ADR-010 → จะ disable Safe-port ใน HALTED. แต่ QA Phase 3T อ่าน 04-data-flow.md → จะ verify Safe-port enabled ใน HALTED. Implementation จะ ship ผิดข้างใดข้างหนึ่ง = G4 violation.

นอกจากนี้ semantic ที่ถูกต้องเองยังถกกันได้: ถ้า Safe-port = exit-only action (close 10 positions) — เปิดใน HALTED ก็ make sense (preserve user's intent ของ "control halt"); ถ้า Safe-port = bulk-pattern ที่เกิดจาก signal pattern ที่ slot-level exit logic ไม่ยอม — disable ใน HALTED ก็ make sense (let slot-level exit handle). การเลือก = architectural decision ที่ต้อง explicitly resolve.

**Minimum acceptable fix:**
1. **เลือกข้างก่อน:** Architect ตัดสิน Safe-port ใน HALTED = enabled หรือ disabled พร้อม rationale (อ้าง G4 + AC-7.7.3 ซึ่ง require "exit pass run")
2. **Update ADR-010 § "Cross-slot logic in halted state"** ให้ตรงกับ decision; เพิ่ม revision history line: *"2026-05-XX — Updated Safe-port HALTED behavior to <ENABLED/DISABLED> per round-01 rebuttal"*
3. **Update `04 § 9.1` table** + ลบ "Correction note" meta-comment (ดู 01.15)
4. **Update `08 § IMPL-058`** Per-Task Metadata ถ้าทำให้ HALTED-aware enable matrix logic เปลี่ยน
5. **Update `05 § Defensive Controls Summary § Runtime defenses § Halted-state semantic`** ถ้ามี side-effect

**Effort:** Low (1-2 hour: choose direction + 4 doc edits + 1 ADR amendment)

---

### 🟠 HIGH

#### Claim 01.2: 🟠 HIGH — Tick-latency budget arithmetic ไม่ reconcile กับ NFR-2.1 baseline assumption

**Location:** `docs/design-docs/03-deep-dive.md` § 2.3 "Pipeline budget table"

**Problem:**
Table มี "Total budget (steady state, 0 events)" = **~1,685 µs** พร้อม comment *"within 10% of ~7 ms baseline = +700 µs target"*. แต่ 1,685 µs **ไม่อยู่ภายใน "+700 µs of 7 ms"** ตามคณิตศาสตร์ตรงไปตรงมา:

- ถ้า 1,685 µs = **total rewrite tick time** (steady state) → เทียบกับ baseline 7,000 µs → rewrite **เร็วกว่า** baseline 76% → ขัด common sense (rewrite ที่ใส่ 21 virtual call + struct copy + atomic state write จะเร็วกว่า monolith เดิมที่ทำงานเดียวกัน?)
- ถ้า 1,685 µs = **overhead delta** เท่านั้น → 1,685 µs > 700 µs allowance → fail NFR-2.1 (≤ 10% overhead)
- ถ้า budget table นับเฉพาะ "new in rewrite" rows + ignore "preserve baseline" rows → คำตอบไม่ใช่ 1,685 (sum ของทุก row) — ต้องคำนวณใหม่

ต้นเหตุ: row `IndicatorService::Refresh` 200 µs ระบุ *"preserve EA เดิม cost (~150-200 µs) + 0 added"* — แสดงว่า 200 µs คือ **shared cost** ระหว่าง original กับ rewrite, **ไม่ใช่ added overhead**. Total ของ "added overhead" จริง = MarketContextBuilder 50 + StatePersistence 800 + Logger 150 + virtual call 1 = ~**1,000 µs** = ยัง > 700 µs allowance

นอกจากนี้ "~7 ms baseline" ตัวเองไม่มี derivation — table หัวข้อระบุ *"Original EA tick latency baseline (estimate): ~5-10 ms/tick avg ใน Strategy Tester 1-min OHLC model"* = guess range ไม่ใช่ measurement

**Why this matters:**
NFR-2.1 = primary acceptance gate (Must, G1+G3). ถ้า budget table หลอก reader ว่า rewrite "พอดี" budget แต่ความจริงเกิน → Implementation phase จะ ship rewrite ที่ fail QA `IMPL-065` perf measurement → re-architect cost สูง (revisit ADR-002 virtual call → static dispatch ผ่าน switch-on-enum, revisit ADR-005 CHashMap → sparse array).

**Minimum acceptable fix:**
1. **Separate two tables:** (a) **Rewrite total** = sum ของทุก row (tick budget เต็ม); (b) **Overhead delta** = sum ของ "new in rewrite" rows เท่านั้น (เทียบกับ NFR-2.1 10% ceiling)
2. **Lock baseline number**: replace "~7 ms estimate" ด้วย measurement protocol ที่ TD spike จะวัด (e.g., *"Baseline TBD ใน TD spike Phase 1D — re-do this table หลังจาก measurement"*) หรือ commit "7 ms" + acknowledge ว่าเป็น assumption ที่ต้อง verify ใน IMPL-065
3. **Re-do arithmetic**: ถ้า overhead 1,000 µs > 700 µs allowance → flag ว่า design ใช้ **NFR-2.1 budget headroom เกือบหมด**; suggest mitigation paths (dirty-bit throttle ของ StatePersistence, log-level tuning, virtual call → static dispatch)
4. Cross-check `04 § 1.2` insight statement (*"within 10% NFR-2.1 budget given 7 ms baseline"*) ให้ตรงกับ corrected math

**Effort:** Medium (~3-4 hours: math review + 2 doc updates + add measurement protocol clarification)

---

#### Claim 01.3: 🟠 HIGH — Indicator handle count inconsistent (21 vs 25 vs ~25-30) ระหว่าง 4 sources

**Location:** `docs/adr/003-centralized-indicator-service.md` § Decision (table) + § Note + `02-high-level-architecture.md` § 4.1 (Mermaid label) + `04-data-flow.md` § 1.1 + § 5.1

**Problem:**
- **ADR-003 § Decision table:** Total = **~21 handles** (sum ของ 13 indicator entries)
- **ADR-003 § Note immediately after table:** *"จำนวน handle จริงอาจ **~25-30** ขึ้นกับว่า slot ต้องการ different param ของ indicator เดียวกันไหม"*
- **02 § 4.1 Mermaid:** `IS[IndicatorService<br/>~25-30 handles]`
- **04 § 1.1 sequence:** *"`Refresh()` — CopyBuffer × **~25 handles**"*
- **04 § 5.1 OnInit log:** *"Info('system', 'init_ok', 0, '**25/25 handles**, 21 slots, ...')"*
- **05 § 2.5 DoS row:** *"Indicator handle exhaustion (MT5 limit ~512) | Low — **we use ~25** | None"*

มี 3 ตัวเลขสับสน: 21 (ADR table), 25 (04 + 05), 25-30 (ADR note + 02 mermaid). 04 § 5.1 hardcode "25/25" ใน log message ที่ Implementation phase จะ implement ตามตัวอักษร = TD ไม่รู้ว่าจะ instantiate เท่าไหร่.

**Why this matters:**
- TD Phase 1D ต้อง lock final list — design doc ที่ wave hand "21 ~ 25 ~ 30" บังคับ TD เดาเอง
- ADR-003 Revisit-when clause: *"ถ้า measured handle creation time > 500 ms"* — measurement depends on actual count. ไม่มี baseline = ไม่มี trigger
- NFR-3.2 fail-fast verification (`QA IMPL-064` adjacent) ต้อง verify "EA reject load 100% ของ INVALID_HANDLE case" — ถ้า count ≠ what test expects = false negative
- "Every concrete number must have formula/derivation" guardrail violation — handle count = the most enumerable quantity ของ system

**Minimum acceptable fix:**
1. **Lock single number ใน ADR-003:** sum table แล้ว commit (= 21 handles ตาม ADR table) หรือ expand table ให้ครบ 25-30 entries (ถ้า slot ต้องการ different params จริง)
2. **Update 02 § 4.1 Mermaid label** + 04 § 1.1 + 04 § 5.1 + 05 § 2.5 ให้อ้างตัวเลขเดียวกัน
3. **Remove "may be ~25-30" caveat** ของ ADR-003 หรือ promote เป็น Revisit-when trigger ที่ TD spike จะตอบ
4. **Document derivation** = expand table ให้แต่ละ handle list (indicator, params, used_by_slots) ขึ้นเป็น ground-truth

**Effort:** Medium (1-2 hours review เลือก count + 4 doc edits + ADR table expansion)

---

#### Claim 01.4: 🟠 HIGH — ADR-007 atomic write commit primary path บน assumption A2 ที่ยังไม่ verify; fall-back ไม่ design-locked

**Location:** `docs/adr/007-state-persistence-atomic-temp-rename.md` § "Atomicity proof sketch" + § Revisit-when + `docs/design-docs/03-deep-dive.md` § 3.4 (Failure modes)

**Problem:**
ADR-007 commit *Option A — single state.json + atomic temp+rename* เป็น primary path. Atomicity rests on assumption: *"⚠️ Assumption: MT5 sandbox `FileMove` invoke true Windows atomic rename (ไม่ใช่ copy+delete sequence) — ต้อง verify ใน TD spike"* — ระบุเป็น A2 ใน `03 § 7` acknowledged risks.

แต่ design ทุก downstream artifact (state-persistence-schema.yaml, IMPL-047 in 08, F1 step W) ใช้ Option A เป็น base; Option B (double-buffered swap) มีแค่ 4-line description ใน ADR § Options:

> *"### Option B — Double-buffered swap (`state-A.json` ↔ `state-B.json` + version pointer): 1. Determine inactive slot... 2. Write to inactive 3. Update state-meta.json pointer to new active. **Rejected:** state-meta.json update ก็ต้อง atomic เหมือนเดิม → recursion problem"*

Option B rationale (recursion problem) ตัวเองไม่ถูกต้อง: state-meta.json pointer = single 4-byte int "A" หรือ "B" — write atomic ผ่าน sector boundary ของ NTFS (single-sector write < 512 bytes = atomic by hardware). แต่นั่นไม่ใช่ประเด็น — ประเด็นคือ **Option B ไม่มี implementation outline ใน design** แต่ ADR-007 ระบุว่าเป็น fallback; ถ้า A2 fail ใน TD spike = team จะ design Option B ใน Implementation phase = late re-architecture cost

**Why this matters:**
- NFR-3.1 = Must (G4): 0% corruption หลัง random kill 100 รอบ. Primary mitigation = Option A. Fallback = Option B แต่ undesigned
- IMPL-046 (Suggested P1) = TD spike ที่ verify A2. Spike fail = block IMPL-047, IMPL-049 (cascading per `08 § 2 Dependency Map`)
- Cost ของ late Option B design = re-do state-persistence-schema.yaml + StatePersistence::Save/Load impl + reconcile of GlobalVariable mirror + new tmp files
- Reading guarantee carefully: NTFS guarantees `MoveFileEx` atomic for **same volume**, but MT5 sandbox virtualizes paths — sandbox shim อาจ implement FileMove ผ่าน FileCopy + FileDelete (ไม่ atomic). Without spike data, this is unverified

**Minimum acceptable fix:**
1. **Either:** Run IMPL-046 spike before locking SD (preferred — confirms primary path) **or** elevate Option B to **co-equal primary** with explicit selection criterion ใน TD spike
2. **Design Option B ครบ ใน ADR-007:** schema for state-meta.json (1-byte pointer is sufficient — single-sector atomic), 2-file rotation logic, recovery from each crash window (mid-write A→B, mid-pointer-update, mid-write B→A)
3. **Update `02 § 9 ADR Digest` row:** add note ที่ "Trade-off" cell ว่า primary path conditional บน A2 spike
4. **Update `03 § 3.4` Failure modes**: row "MT5 sandbox FileMove is not atomic" — ระบุ effort/scope ของ Option B switch (currently "larger refactor" = vague)

**Effort:** Medium (3-4 hours: design Option B properly + update 3 doc sections); High ถ้าเลือก option (1) = run spike first

---

#### Claim 01.5: 🟠 HIGH — `slot-abstraction-contract.yaml` ใช้ OpenAPI 3.0.3 format ผิดเครื่องมือ — เป็น intra-process method contract, ไม่ใช่ network API

**Location:** `docs/api-specs/slot-abstraction-contract.yaml`

**Problem:**
File เริ่มด้วย `openapi: 3.0.3` พร้อม `paths:` block ที่ define HTTP-style endpoints (`/slot/{slot_id}/Magic`, `/slot/{slot_id}/Evaluate`, ฯลฯ) ที่ "return responses 200" + body schema, etc. — แต่ comment ที่หัวไฟล์ disclaim: *"Format note: We use OpenAPI-like structure to express the method contract for clarity, but each 'endpoint' is an MQL5 method on `CSlotBase*` (constructor-injected)"*

OpenAPI = network API spec — มี HTTP method, response code, request body, etc. ที่ all are wrong abstraction สำหรับ method-on-class. คนอ่าน spec ครั้งแรกจะ assume endpoint จริง — ก่อนอ่าน comment ก็ generate fake REST client แล้ว

นอกจากนี้:
- `paths: /slot/{slot_id}/Magic` แทน method `Magic()` ของ class → mistakenly "GET" semantic (vs `int Magic() const` getter)
- `requestBody: schema` ของ Evaluate ระบุ JSON body แต่จริงคือ MQL5 const reference (ไม่ใช่ serialized JSON)
- **3 อื่น API specs ใช้ JSON Schema 2020-12** (`trade-journal-schema.yaml`, `state-persistence-schema.yaml`, `marketcontext-snapshot-schema.yaml`) — consistent + ตรง tool. slot-contract.yaml = outlier

**Why this matters:**
- TD Phase 1D อ่าน 4 specs เป็น authoritative — slot-contract.yaml ใช้ wrong tool = TD generate boilerplate ผิด (HTTP framework imports) หรือ confused
- API spec linting tools (Spectral, openapi-validator) จะ pass ตรง syntax แต่ semantic ผิด
- Cross-doc refs in ADR-002, 02 § 4.2, 04 § 2 ทุกที่อ้าง spec — ยิ่ง spec ผิด format ยิ่ง propagate confusion

**Minimum acceptable fix:**
- **Rewrite as JSON Schema** สำหรับ:
  - `CSlotBase` method signature (method name + Thai/English description + param schema + return type + side effect notes)
  - Constructor injection contract (object schema ของ services injected)
- ใช้ format consistency กับ 3 อื่น YAML specs (`$schema: "https://json-schema.org/draft/2020-12/schema"`)
- หรือ alternative: เก็บเป็น **Markdown file** `docs/api-specs/slot-abstraction-contract.md` ที่ describe contract เป็น prose + table — ไม่ pretend ว่าเป็น machine-readable API spec
- เลิก `paths:` + HTTP-style structure ทั้งหมด; พูดตรงว่าเป็น method-on-MQL5-class contract

**Effort:** Medium (2-3 hours: rewrite spec; cross-doc refs ของ "slot-abstraction-contract.yaml" ยังคงชี้ตำแหน่งเดิม OK)

---

### 🟡 MEDIUM

#### Claim 01.6: 🟡 MEDIUM — ADR-008 force-clear thresholds (M=150, T=80, Q=100 H4 bars) lack rigorous derivation

**Location:** `docs/adr/008-pending-state-safety-force-clear.md` § "Decision" + table

**Problem:**
Justification ของแต่ละ threshold:
- **M-Pending = 150 H4 bars:** *"ของเดิม trigger ส่วนใหญ่ resolve ภายใน ≤ 30 bars ผ่าน price move หรือ signal flip — 150 bars = 5× headroom"* — "ของเดิม trigger ส่วนใหญ่ resolve ภายใน ≤ 30 bars" = **claim ที่ไม่มี source citation** (ไม่อ้าง CodeWiki หรือ baseline measurement)
- **T-Pending = 80 H4 bars:** *"T confirmation pattern ปกติเกิดภายใน ≤ 20 bars หลัง snapshot; 80 bars = 4× headroom"* — same issue: no measurement source
- **Q-Pending = 100 H4 bars:** *"Q มี 4 codes (0/1/2/3) — code 3 เป็น code resolve ช้าสุด (multi-bar wait pattern); 100 bars = headroom ครอบคลุมทุก code variant"* — "code 3 ช้าสุด" ไม่มี evidence; coverage claim ไม่มี derivation

§ Decision § "Why these numbers" cites baseline holding time *"max position holding time = 483:30:00 ≈ 121 H4 bars"* — แต่ position holding time ≠ pending state duration. Pending state duration คือ "time spent in PENDING before EXECUTED/IDLE transition" (per BR-6.x logic). การใช้ holding time เป็น proxy = false comparison.

**Why this matters:**
- ADR-008 = primary resolution ของ OQ-A1/A2/A3 (architecture-domain OQ raised by BA)
- Bucket A drift risk: ถ้า threshold ตัด valid trigger window → > 25% Net Profit deviation → fail NFR-1.1
- Validation rule (ADR-008 § Validation strategy): *"Expected: 0 force-clear events ใน 5-yr baseline"* — baseline assumption ที่ Architect ตั้งเอง ไม่มี measurement
- "Configurable per input" = mitigation path that punts decision; ปัญหาคือ default ตอน user ไม่แตะ input

**Minimum acceptable fix:**
1. **Derivation source:** อ้าง CodeWiki §2.5 (state machine docs) หรือ baseline `ReportTester-25045474.html` measurement (ถ้า extractable) ของ actual longest-resolved pending duration per machine
2. หรือ **acknowledge** ว่า threshold = **engineering guess** + documented as assumption ⚠️ A6 (เพิ่มใน `03 § 7`) → IMPL-068 (force-clear validation in QA) verify; tune via Bucket A drift sensitivity
3. แก้ "Why these numbers" ให้อ้าง position holding time ตรง (= unrelated proxy ปัจจุบัน) — ใช้ bar-counting ของ pending state จริงจาก baseline ถ้าทำได้
4. Q-Pending: explain code 0/1/2/3 sub-machines + identify slowest one with evidence

**Effort:** Medium (2-3 hours: review CodeWiki §2.5, attempt baseline extraction, restate derivation)

---

#### Claim 01.7: 🟡 MEDIUM — F1 SpreadGuard collapses 3 separate FR/BR rules ambiguously

**Location:** `docs/design-docs/04-data-flow.md` § 1.1 (sequence) — step `Orc->>TG: SpreadGuard()`

**Problem:**
Sequence diagram ระบุ: *"Orc->>TG: SpreadGuard() — IsMondayMorningWakeup + spread > 10pip"* — ใช้ method name `SpreadGuard` แต่ describe ว่ารวม 2 logic. ในความเป็นจริง BA แยก 3 rules:
- **FR-6.1 + BR-3.x IsMorningWakeup:** block 00:00-00:05 broker server time (ทุกวัน, ไม่ใช่แค่ Monday)
- **FR-6.2 + BR-3.x IsMondaySpreadHigh:** Monday spread > 10 pip ห้าม entry
- **BR-3.7 SpreadGuard:** general spread filter (ไม่จำกัด Monday)

`04 § 1.1` collapse ของทั้ง 3 → 1 method = ambiguous. `02 § 4.2` component table item 15 แสดงตรง: *"`TimeGate` | services | IsMorningWakeup + IsMondaySpreadHigh + IsNewYearSeason2 + per-slot ban (BR-3.x)"* — ระบุ 4 method แยก ไม่มี `SpreadGuard` ที่ merge.

`08 § IMPL-050` ก็ระบุ separate methods: *"`services/TimeGate` (IsMorningWakeup + IsMondaySpreadHigh + IsNewYearSeason2 + IsBanned per BR-3.x)"*

**Why this matters:**
- TD Phase 1D อ่าน `04 § 1.1` sequence + `02 § 4.2` + `08 § IMPL-050` → 3 mismatched method namings → unsure ว่าจะ implement กี่ method
- Logic ก็ต่างกัน: SpreadGuard ตามคำอธิบาย "IsMondayMorningWakeup + spread > 10pip" = **AND** ทั้งสอง (Monday morning AND high spread) ซึ่ง wrong: BA F1 step "spread guard" = check spread regardless of day; "IsMorningWakeup" = block ทุกวันแม้ spread ต่ำ
- QA Phase 3T ทดสอบ AC ของ FR-6.1 + FR-6.2 แยก — implementation ที่ collapse 2 rules into 1 condition จะ fail แยกๆ

**Minimum acceptable fix:**
1. **แตก SpreadGuard เป็น 2 sequence steps ใน `04 § 1.1`:**
   - Step A: `Orc->>TG: IsMorningWakeup()` (FR-6.1, block 00:00-00:05 ทุกวัน)
   - Step B: `Orc->>TG: IsMondaySpreadHigh()` (FR-6.2 + BR-3.7, Monday + spread > 10 pip)
2. หรือ rename ที่ใช้ `SpreadGuard` ให้สื่อความว่า merge ของหลาย rule + clarify boolean logic (AND/OR)
3. Cross-check `04 § 1.1` sequence vs `02 § 4.2` (TimeGate row) vs `08 § IMPL-050` ใหฺ้ method list ตรงกัน

**Effort:** Low (~1 hour: 1 sequence diagram update + cross-doc verify)

---

#### Claim 01.8: 🟡 MEDIUM — P-Pending sub-modes (PX/PH/E/N) defined ใน schema-only, ไม่มี narrative ใน design docs

**Location:** `docs/api-specs/state-persistence-schema.yaml` (definitions § `PendingMachineState_PVariant`) + `04-data-flow.md` § 4.2 (P-Pending row)

**Problem:**
Schema มี `sub_mode: enum [PX, PH, E, N, null]` พร้อม description *"P-Pending sub-variant per CodeWiki §2.5"* — but:
- `04 § 4.2` table P-Pending row ระบุ legacy invalidation = *"Bollinger violation"* ไม่กล่าวถึง 4 sub-modes
- `08 § IMPL-034` (Slot_P) note: *"P-Pending state machine (P_Extra variant)"* — "P_Extra" คือ sub-mode 1 ใน 4 หรือ alias?
- ADR-008 only mentions Q-Pending sub-codes (0/1/2/3); ไม่ mention P sub-modes
- 02-08 ไม่ define what PX / PH / E / N stand for

`PendingMachineState_PVariant` schema ก็มี `diff_sl: number | null`, `band_ratio: number | null` — fields ไม่ explained ใน text

**Why this matters:**
- P-Pending = สิ่งที่ legacy timeout = 70 H4 bars (longest amongst non-force-clear machines)
- Slot P = `IMPL-034` ระดับ Size XL (largest impl task) — TD Phase 1D ต้อง translate CodeWiki §2.5 → P-Pending sub-modes; SD ไม่ provide context
- ⚠️ Risk pattern: schema defines fields ที่ behavior ไม่ defined elsewhere → TD interpret ผิด → Bucket A drift in regression
- BA-domain OQs สำหรับ M/T/Q resolved (OQ-A1/A2/A3) แต่ P-Pending ไม่ flagged สำหรับ design clarification despite ที่ slot P = largest impl

**Minimum acceptable fix:**
1. เพิ่ม `04 § 4` subsection "P-Pending Sub-Mode Detail" ที่ describe 4 sub-modes (PX, PH, E, N) — what triggers each, how transitions, what `diff_sl` + `band_ratio` represent
2. Cross-ref CodeWiki §2.5 explicitly ใน schema description (อ้าง section + line range)
3. หรือ ถ้า "P_Extra" = 1 sub-mode พิเศษ, separate การ wording ของ `08 § IMPL-034` ให้ตรงกับ schema sub_mode enum
4. Mark P-Pending = acknowledged risk A6 (extension ของ A1-A5) ใน `03 § 7` ถ้า TD lock ต้อง spike

**Effort:** Medium (2 hours: research CodeWiki §2.5 + write subsection + 3 cross-doc updates)

---

#### Claim 01.9: 🟡 MEDIUM — BootstrapValidator vs IndicatorService ownership ของ FR-7.6 fail-fast unclear

**Location:** `docs/design-docs/02-high-level-architecture.md` § 4.2 (Component catalog item 3) + `04-data-flow.md` § 5.1 (OnInit sequence)

**Problem:**
- **02 § 4.2 item 3:** *"`BootstrapValidator` | core | Symbol whitelist + input validation + **indicator handle validation** (FR-1.2/1.4/7.6, BR-9.1/9.3/9.4) | ADR-003"* — ระบุ BV does indicator handle validation
- **04 § 5.1 OnInit sequence:** Orchestrator calls `BV.ValidateInputs()` → `BV.ValidateSymbol()` → `BV.DetectDigitMultipier()` → **`IS.CreateHandles()`** (Orc → IS direct, ไม่ผ่าน BV) → loop validation per handle ใน IS — ระบุ IndicatorService does handle validation
- **ADR-003 § Decision:** *"`bool CreateHandles()` — call จาก OnInit; return false ถ้ามี INVALID_HANDLE → orchestrator return INIT_FAILED"* — agrees with 04 (IS does it, returns to Orc)
- **08 § IMPL-005, IMPL-015, IMPL-016:** IMPL-005 = IndicatorService impl (handle creation + validation); IMPL-015 = BV input validation; IMPL-016 = BV symbol whitelist — agrees with 04 (BV does NOT do indicator validation)

So 02 § 4.2 catalog row = wrong. BV does inputs + symbol + DigitMultipier; IS does handle creation/validation; Orchestrator wires both.

**Why this matters:**
- 02 = primary architecture overview; component catalog row = canonical responsibility
- 02 row ระบุว่า BV owns FR-7.6 + BR-9.4 (magic range) — neither true: FR-7.6 = IS's job; BR-9.4 magic range = ไม่มี code path ใน BV (BR-9.4 = SlotRegistry domain)
- TD reading 02 first → may design BV class with handle validation method → conflict กับ 04 + ADR-003

**Minimum acceptable fix:**
1. Update 02 § 4.2 item 3 BV row:
   - Remove "indicator handle validation" from responsibility
   - Remove FR-7.6 + BR-9.3 + BR-9.4 from FR/BR tags
   - Keep only FR-1.2, FR-1.4, BR-9.1
2. Add FR-7.6 to 02 § 4.2 item 7 (`IndicatorService`) responsibility list explicitly
3. BR-9.3 (DigitMultipier auto-detect) คงไว้ใน BV (BR row); but link via separate `DetectDigitMultipier()` method (ตาม 04 § 5.1)

**Effort:** Low (~30 min: 1-2 cell edits ใน 02 catalog table)

---

#### Claim 01.10: 🟡 MEDIUM — Trade-journal RPO under sustained slow disk = unspecified; G2 contract silent break possible

**Location:** `docs/adr/006-trade-journal-jsonlines.md` § "Failure handling" + `docs/design-docs/04-data-flow.md` § 8 (Burst handling)

**Problem:**
ADR-006 + 04 § 8 ระบุ "degrade-warn-but-continue" pattern: ถ้า journal write > 5ms → warn, **never block trade**. Failure handling: *"Write fail (disk full / permission) → log via `Logger::Error()` + `Alert()` ถ้า ≥ N ครั้งใน 100 ticks (anti-spam) — ไม่ block trade flow"*

03 § 4.4 Failure modes table elaborates: *"Disk full → FileWriteString fails | Logger.Error (throttled); **journal dropped for this event**; tick continues"*

ดังนั้น ภายใต้ sustained slow disk + AV interference + disk-full scenario: Journal records จริง **drop**. แต่ G2 = "auditability" + FR-4.3 = local-only journal storage (no cloud backup) → drop = no recovery.

**Recovery Point Objective (RPO)** ไม่ ระบุ:
- 0 events lost = G2 strictest (atomic = lose ≤ 1 tick of writes if crash mid-flush)
- ≤ N events lost = degraded mode
- Unbounded loss under sustained disk fail = current implicit answer

**Why this matters:**
- G2 = primary improvement target ของ MVP (user pain #2: "ไม่มีหลักฐานการเทรด")
- ถ้า user discover post-incident ว่า journal มี gap (records dropped during disk-full) → "degraded mode" failure mode = silent break ของ G2 contract
- NFR-3.4 = 0 silent failures — log error + Alert (throttled) = **partially silent** (Alert throttle suppresses repeats; Print emits but user must watch log tab)
- 05 § 7.2 monitoring signals ไม่ list "journal write fail rate" — user signal = absent

**Minimum acceptable fix:**
1. **Define RPO target explicitly:**
   - "0 events lost on graceful shutdown (OnDeinit)"
   - "≤ 1 event lost on hard crash (event-in-flight)"
   - "Sustained disk failure: events dropped + journal counter increment + Alert per N drops + escalation policy" (e.g., HALT EA after 10 sustained drops?)
2. **Add `journal_drop_count` field** ใน state.json (state-persistence-schema.yaml) เป็น session counter — preserve across restart
3. **Add monitoring signal** ใน 05 § 7.2 row: "Journal `write_failures` count > N/day → check disk health"
4. **ADR-006 § Failure handling**: explicitly enumerate "Bounded vs unbounded loss scenarios + RPO target"
5. Optionally: introduce **journal "intent" log** (smaller, separate file written before main journal write) ที่ guarantee atomic ของ "tried-to-write" event — main journal lost = intent log records gap

**Effort:** Medium (2-3 hours: define RPO + add field + 3 doc updates + monitoring signal)

---

#### Claim 01.11: 🟡 MEDIUM — ADR-002 `=0` virtual enforcement = "discipline" without concrete mechanism; FR-2.5 contract weak

**Location:** `docs/adr/002-slot-abstraction-via-oo-inheritance.md` § Consequences (Negative section)

**Problem:**
ADR-002 § Consequences: *"MQL5 ไม่มี `=0` pure virtual — ต้องใช้ override discipline + base class throw error ถ้า base method called (compile-time can't enforce); mitigated ผ่าน reviewer checklist"*

"Throw error if base method called" + "reviewer checklist" = no automated enforcement. Concrete มาตรการที่ commit:
- Compile-time: not possible per ADR
- Runtime: base method "throw error" — but what does "throw" do in MQL5? `Print` + return? `Alert` + return? `ExpertRemove`? Not specified
- Boot-time: SlotRegistry::ValidateTopo asserts dependency order — but doesn't assert that derived class overrode each method

`docs/api-specs/slot-abstraction-contract.yaml` § notes: *"MQL5 `=0` pure virtual NOT supported; use override discipline + base class throws / asserts if base method called (= reviewer + boot-time check)"* — same vague wording

**Why this matters:**
- FR-2.5 = "Slot abstraction (uniform contract)" Must — เป้าหมาย = orchestrator ไม่ต้องรู้ slot-specific
- หาก derived class ลืม override (e.g., new slot Phase 2 = `Slot_U.mqh` revived per `07 § 2.5`) → base CSlotBase method runs → silent no-op (Evaluate = no signal check, ManageExits = no exit) = ทุก position ของ slot ใหม่ orphan
- 21 slots Phase 1 = TD จะ implement override discipline manually; ใน Phase 2 expansion = bug surface

**Minimum acceptable fix:**
1. **Specify enforcement mechanism explicitly ใน ADR-002 § Decision:**
   - Option A: Base virtual methods call `Logger::Error("CSlotBase", "missing_override", magic, "...")` + `ExpertRemove()` — guaranteed loud at runtime
   - Option B: SlotRegistry::ValidateTopo() during OnInit calls `slot.Magic()` + `slot.SlotId()` ของแต่ละ entry → if returns sentinel value (`-1`, `""`) → INIT_FAILED
   - Option C: Compile-time guard via `static_assert` (MQL5 limited) — likely not feasible
2. Include base method body example: `void Evaluate(...) { Logger::Error(...); /* never reached if override correct */ }`
3. **08 § IMPL-018** (CSlotBase contract): expand task to include "boot-time override-validation logic"

**Effort:** Low (~1 hour: concrete enforcement design + ADR + slot contract + IMPL-018 update)

---

#### Claim 01.12: 🟡 MEDIUM — Logger throttle suppresses Alert for sustained errors → tension กับ NFR-3.4 (0 silent failures)

**Location:** `docs/adr/011-tagged-structured-logger.md` § Decision (Throttle row) + Negative consequences

**Problem:**
ADR-011 throttle: *"ERROR + same `(slot, event)` tuple ภายใน 100 ticks → suppress Alert (still Print); reset throttle ทุก 100 ticks"*

ในกรณี sustained problem (e.g., slow disk → journal write fail every tick):
- Tick 1: `Logger::Error("system", "journal_write_fail", 0, "disk slow")` → Print + Alert popup
- Tick 2-99: same `(system, journal_write_fail)` → Print + Alert **suppressed**
- Tick 100: throttle reset → Alert again
- Tick 100-199: Alert suppressed again

User experience: **1 popup ทุก 100 ticks**. Print ไป MT5 Experts log tab ทุก tick, but user ที่ไม่เปิด log tab จะเห็น Alert popup เท่านั้น = **99 ticks ของ silent error** per cycle

NFR-3.4 = "0 silent failure paths ใน OnInit + OnTick critical sections (order open/close, state persist, indicator handle)". Throttle behavior = silent for 99% of sustained-error ticks.

ADR-011 § Negative consequences acknowledges: *"ERROR + Alert throttle อาจ suppress real consecutive errors → mitigated โดย Print ยัง emit + journal record ทุกครั้ง (Alert คือ user-attention layer; journal คือ ground truth)"*. แต่ NFR-3.4 wording = "0 silent failures" — Print ที่ user ไม่เห็น = silent in user UX terms.

**Why this matters:**
- Solo operator (C-9) ไม่มี monitoring service; Alert popup = primary attention layer
- Sustained problem (disk slow / antivirus interference / circuit-breaker firing repeatedly) = exactly when user ต้องรู้ทุก event
- 100 ticks ใน volatile FBS market = ~100 seconds at 1 tick/sec = **almost 2 minutes ของ silent operation** per throttle cycle

**Minimum acceptable fix:**
1. **Differentiate throttle policy per event severity:**
   - Distinct events (`journal_write_fail` vs `circuit_breaker_pingpong` vs `handle_invalid_runtime`) = throttle independently
   - "Halt-trigger" errors (= those that lead to `ExpertRemove` / `EAState.Halt`) = **never throttle** Alert
2. **Escalation policy:** ถ้า same `(slot, event)` ERROR ≥ N ติดต่อกัน → upgrade severity (Logger.Error → "halt EA" หรือ "secondary Alert mode") — not silent
3. **Operator visible counter:** เก็บ `throttled_alert_count` per session ใน WatchProfits; surface ใน HALTED_STABLE Alert message: *"halt_stable + 47 throttled alerts ใน session"*
4. Update NFR-3.4 description ใน BA หรือ ADR-011 ให้ acknowledge "throttle window" semantic — ถ้า user ตกลงรับ throttled-silent-window ภายใน N ticks ก็ shall make explicit

**Effort:** Low-Medium (~2 hours: refine throttle policy + escalation + 2 doc updates)

---

#### Claim 01.13: 🟡 MEDIUM — 08 Phase Hints carry hard architectural ordering แต่ 07 ระบุ Evolution Sequence = N/A — categorization inconsistency

**Location:** `docs/design-docs/07-future-evolution.md` § 6 + `08-product-breakdown.md` § 3 (Suggested P1-P4)

**Problem:**
- **07 § 6:** *"Evolution Sequence — N/A. PhoenicisNex Phase 1 = single-process greenfield rewrite, no cross-service dependency, no migration from legacy production"* + 4 reasons → skip per `sd.md § Phase 3.4`
- **08 § 3 Phase Hints (Suggested P1):** rationale ระบุ HARD architectural ordering: *"IMPL-046 atomic write spike — risk=high; ADR-007 design depends on result; fail-early signal"* + *"all subsequent depends on foundation"*

Per sd.md § Phase Contract: Evolution Sequence = "ordering constraints แบบ hard, backed by ADR" (e.g., *"E1: extract auth service ก่อน E3: payment refactor — ADR-005 บังคับให้ใช้ unified JWT"*). Phase Hints = "soft suggestion".

`08 § 2 Dependency Map` ระบุ: *"IMPL-046 (atomic write spike) is risk gate — ถ้า fail → ADR-007 Option B; cascades to IMPL-047 + IMPL-049 design"* = hard architectural sequencing (run spike before locking design).

ดังนั้น มี hard ordering constraint (IMPL-046 → IMPL-047 → IMPL-049) ที่ qualify เป็น Evolution Sequence; แต่ 07 ระบุ skip. ไม่ใช่ "missing ≠ defect" case จริง — มี constraint ที่ขาดการ document เป็น hard sequence.

**Why this matters:**
- Impl Planner per `01 § Phase Contract` rule: "Evolution Sequence = hard, override only via /backtrack sd; Phase Hints = soft, override with documented reason"
- IMPL-046 = high-risk spike. ถ้า Impl Planner ตัดสิน override (e.g., move IMPL-046 ไป P2) — ปัจจุบัน = "soft override" (Phase Hint) → IMPL-047 design lock proceeds → if spike fails late → re-architect cost
- ถ้าตำแหน่ง IMPL-046 = Evolution Sequence E1 → Impl Planner cannot override silently
- Ambiguity ใน category = governance failure

**Minimum acceptable fix:**
1. **Reclassify hard-ordering items as Evolution Sequence:**
   - E1: IMPL-046 (atomic write spike) → must precede IMPL-047 (StatePersistence impl) + IMPL-049 (PendingMachineRegistry) — rationale: ADR-007 fall-back design depends on spike result
   - Possibly E2: IMPL-018 (CSlotBase contract) → must precede IMPL-019..039 — rationale: contract = compile prerequisite for derived classes
2. Update 07 § 6 from "N/A" → small Evolution Sequence section พร้อม 1-2 entries
3. Reduce 08 § 3 Phase Hints → keep soft P1-P4 grouping, แต่ remove items that are now Evolution Sequence (or mark them explicitly *"reflects E1"*)
4. Cross-link: Phase Hints rationale อ้าง Evolution Sequence step number

**Effort:** Low-Medium (~1.5 hours: identify hard-ordering items + add E1/E2 section + cross-doc cleanup)

---

#### Claim 01.14: 🟡 MEDIUM — state.json vs MT5 GlobalVariable dual-source-of-truth rule ใน ADR-007 only; ไม่ surface ใน 02 § 6 หรือ 04

**Location:** `docs/adr/007-state-persistence-atomic-temp-rename.md` § Consequences (Negative section, last point) + `docs/design-docs/02-high-level-architecture.md` § 6.1 (Persistence inventory) + `04-data-flow.md` § 5.1 (Boot sequence)

**Problem:**
ADR-007 § Consequences: *"Ban dates / WatchProfits ที่ already in MT5 GlobalVariable (preserve baseline) → dual-source-of-truth issue. **Resolution:** GlobalVariable คือ recovery shortcut (MT5 native restore); state.json คือ canonical (atomic)+full schema. Conflict resolution: state.json wins ตอน load; GlobalVariable update synced หลัง state.json write"*

แต่ **02 § 6.1 Persistence inventory** ระบุ 2 แยก rows — *"Worst DD persistent counters | MT5 GlobalVariable | preserve baseline `WatchProfits` | none — survives restart natively | ~50 keys | —"* (no ADR ref) + *"Pending state machines + ban dates + WatchProfits + cross-slot signal globals | state.json"* — สอง rows ระบุ WatchProfits store **at both places** แต่ไม่ระบุ conflict resolution rule

**04 § 5.1 OnInit sequence** ไม่กล่าวถึง: load order ระหว่าง state.json + GlobalVariable; ใครชนะถ้าค่าต่างกัน

`state-persistence-schema.yaml` watch_profits มี comment: *"mirrored to MT5 GlobalVariable for restart parity"* — แต่ "mirror" = direction unspecified

**Why this matters:**
- WatchProfits = G4 (worst DD bookkeeping) + NFR-5.2 monitor signal
- ถ้า state.json ผ่าน atomic write success แต่ subsequent GlobalVariable mirror ขาด (e.g., MT5 crash before sync) → state.json + GV diverge → next OnInit = which wins?
- ADR-007 ระบุ "state.json wins" แต่ TD reading 02 + 04 only = ไม่รู้
- ถ้า state.json corrupt + parse fall-back to defaults (per 04 § 5.3 recovery) → GV = canonical → ADR-007 rule ตรงข้าม

**Minimum acceptable fix:**
1. Add **§ "Sync rule"** ใต้ 02 § 6.1: state.json = canonical for all persisted state; GlobalVariable = mirror ของ subset (worst_drawdown_pct, worst_drawdown_at, equity_high_water_mark) สำหรับ MT5 native UI inspection; sync direction = state.json → GV after each Save; conflict resolution = state.json wins
2. Update 04 § 5.1 sequence (or 04 § 6 Consistency Boundaries): add row "WatchProfits mirror" + describe sync timing + crash window
3. Specifically address state.json corrupt + GV intact recovery path: should EA fall back to GV value ของ worst DD + start fresh on rest? Document explicitly

**Effort:** Low (~1 hour: 2 doc edits + 1 consistency boundary row)

---

### 🔵 LOW

#### Claim 01.15: 🔵 LOW — `04 § 9` "Correction note for ADR-010 alignment" = meta-comment instead of doc fix

**Location:** `docs/design-docs/04-data-flow.md` § 9 (last paragraph)

**Problem:**
04 § 9 ลงท้ายด้วย: *"> **Correction note for ADR-010 alignment:** Re-reading ADR-010 — Safe-port (BR-8.1) closes positions = exit-side action; we **enable** in HALTED. EOverload + GOverload (BR-8.4) = open new orders → disable in HALTED. Updated table reflects this. ADR-010 § 'Cross-slot logic in halted state' should show Safe-port = enabled (correction tracked for TD)."*

= author leaving in-line "TODO" / "self-correction" ใน design doc final draft. Pattern แสดง:
- **Drafting workflow leak** — should have been resolved before publish
- **Inconsistent doc state** — table reflects updated version, ADR-010 doesn't (per Claim 01.1)
- **TD inheritance issue** — TD จะ inherit confusion เพราะอ่าน comment + ADR-010 + table = 3 sources

**Why this matters:**
- Design docs = canonical authoritative artifact, ไม่ใช่ workspace
- Reader (Tech Lead, QA, future Architect) อ่าน "correction note" = unsure of which version to trust
- Note ตัวมัน *says* "correction tracked for TD" → ทำให้ TD เป็น owner ของ ADR fix = inappropriate; ADR fix = Architect job (round-rebuttal scope ไม่ใช่ TD)

**Minimum acceptable fix:**
1. Resolve Claim 01.1 (decide enable vs disable + fix ADR-010)
2. Remove "correction note" paragraph จาก 04 § 9 entirely
3. ถ้าต้องการ track decision history → use commit message + ADR revision history line

**Effort:** Low (5 min: delete paragraph after 01.1 resolved)

---

#### Claim 01.16: 🔵 LOW — Glossary ใน 02 § 8 includes "JWT/RBAC/RLS/HPA/PVC = N/A" entry — noise

**Location:** `docs/design-docs/02-high-level-architecture.md` § 8 Glossary (last row)

**Problem:**
Last glossary entry: *"JWT / RBAC / RLS / HPA / PVC | NOT applicable to PhoenicisNex — local-only EA, no AuthN/AuthZ, no Kubernetes (mentioned only เพื่อ disambiguate ที่นี่ไม่ใช้)"*

ไม่มี term เหล่านี้ใช้ใน 02-08 design docs (verified via grep). Glossary purpose = define term used; "term not used" entries = noise + signal *"author preempting unsubstantial criticism"* ที่ไม่ helpful

**Why this matters:**
- Glossary noise dilutes signal — junior reader ที่ค้นหา "Force-clear" หรือ "Saga" ใน glossary จะเจอ "JWT" entry = irrelevant
- 5 acronyms ที่ N/A อาจเข้าใจผิดว่ามี relation; reader ไม่จำเป็นต้องรู้ JWT/RBAC concept สำหรับ understand PhoenicisNex
- Pattern อาจเกิดจาก script template — `system-design-master-prompt.md § READABILITY § Glossary` doesn't suggest "preempt unused terms"

**Minimum acceptable fix:**
1. Remove `JWT / RBAC / RLS / HPA / PVC` row จาก § 8
2. Cross-check ทุก glossary entry vs grep ของ docs — entries ที่ไม่ปรากฏใน body = remove
3. Optionally add missing terms: "Cross-slot signal globals", "OrderGroup", "Safe-port", "Force-Pending" — used in body but not in glossary

**Effort:** Low (~30 min: remove + grep verify + add missing terms)

---

#### Claim 01.17: 🔵 LOW — 02 § 4.2 BV row mis-tags FR-1.2/BR-9.1/9.3/9.4 to indicator handle validation row

**Location:** `docs/design-docs/02-high-level-architecture.md` § 4.2 Component catalog (item 3)

**Problem:**
Row 3 ของ Component Catalog: *"`BootstrapValidator` | core | Symbol whitelist + input validation + indicator handle validation (FR-1.2/1.4/7.6, BR-9.1/9.3/9.4) | ADR-003"*

FR/BR tags คลาดเคลื่อน:
- **FR-1.2** = Symbol whitelist guard ✅ (correct)
- **FR-1.4** = Input validation OnInit ✅ (correct)
- **FR-7.6** = Indicator handle validation = **wrong** (per Claim 01.9, IS owns it)
- **BR-9.1** = Symbol whitelist invariant ✅ (correct, paired with FR-1.2)
- **BR-9.3** = DigitMultipier auto-detect ✅ (correct, BV does it via DetectDigitMultipier)
- **BR-9.4** = Magic range invariant = **wrong** (SlotRegistry domain — ไม่มี code path ใน BV)

**Why this matters:**
- Component catalog = first-pass reference สำหรับ TD; TD จะ implement BV กับ list ที่ระบุ
- FR-7.6 + BR-9.4 mis-tag = TD เพิ่ม method ใน BV ที่ไม่ควรอยู่ → violate ADR-012 layering (BV ไม่ควร know about IndicatorService internals หรือ magic numbers)

**Minimum acceptable fix:**
1. Remove FR-7.6 จาก BV row
2. Remove BR-9.4 จาก BV row
3. Add FR-7.6 ลง row 7 (`IndicatorService`)
4. Add BR-9.4 ลง row 4 (`SlotRegistry`)

**Effort:** Low (5 min: 1 cell edit)

---

## Cross-Document Issues

ตารางสรุป contradictions ที่ pulled out as cross-doc claims (also referenced under category 16 ของ checklist):

| Issue | Sources | Claim |
|-------|---------|-------|
| Safe-port HALTED enable/disable | ADR-010 (disabled) ↔ 04 § 9 (enabled per correction note) | 01.1 (CRITICAL) |
| Indicator handle count | ADR-003 (~21) ↔ 02 § 4.1 (~25-30) ↔ 04 § 1.1+5.1 (~25, "25/25") ↔ 05 § 2.5 (~25) | 01.3 (HIGH) |
| FR-7.6 ownership | 02 § 4.2 (BootstrapValidator) ↔ 04 § 5.1 + ADR-003 + 08 § IMPL-005 (IndicatorService) | 01.9 (MEDIUM) |
| state.json vs GlobalVariable conflict resolution | ADR-007 § Consequences (state.json wins) ↔ 02 § 6.1 + 04 § 5.1 (silent on rule) | 01.14 (MEDIUM) |
| TimeGate method names ใน F1 SpreadGuard | 04 § 1.1 (`SpreadGuard()` collapsed) ↔ 02 § 4.2 + 08 § IMPL-050 (3 separate methods) | 01.7 (MEDIUM) |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 01.1 | 🔴 CRITICAL | Safe-port HALTED behavior contradiction | `adr/010-*.md` § Cross-slot + `04 § 9` | Low |
| 01.2 | 🟠 HIGH | Tick-latency budget arithmetic muddle | `03 § 2.3` | Medium |
| 01.3 | 🟠 HIGH | Indicator handle count inconsistent (21 vs 25 vs 25-30) | `adr/003-*.md` + `02 § 4.1` + `04 § 1.1/5.1` + `05 § 2.5` | Medium |
| 01.4 | 🟠 HIGH | ADR-007 atomic write rests on unverified A2; Option B undesigned | `adr/007-*.md` | Medium-High |
| 01.5 | 🟠 HIGH | slot-abstraction-contract.yaml uses OpenAPI 3.0.3 wrong tool | `api-specs/slot-abstraction-contract.yaml` | Medium |
| 01.6 | 🟡 MEDIUM | ADR-008 force-clear thresholds lack rigorous derivation | `adr/008-*.md` | Medium |
| 01.7 | 🟡 MEDIUM | F1 SpreadGuard collapses 3 separate FR/BR rules | `04 § 1.1` | Low |
| 01.8 | 🟡 MEDIUM | P-Pending sub-modes (PX/PH/E/N) defined ใน schema-only | `04 § 4.2` + `state-persistence-schema.yaml` | Medium |
| 01.9 | 🟡 MEDIUM | BV vs IS ownership of FR-7.6 fail-fast unclear | `02 § 4.2` + `04 § 5.1` | Low |
| 01.10 | 🟡 MEDIUM | Trade-journal RPO unspecified for sustained slow disk | `adr/006-*.md` + `04 § 8` | Medium |
| 01.11 | 🟡 MEDIUM | ADR-002 `=0` virtual enforcement = "discipline" no mechanism | `adr/002-*.md` | Low |
| 01.12 | 🟡 MEDIUM | Logger throttle suppresses Alert sustained → tension NFR-3.4 | `adr/011-*.md` | Low-Medium |
| 01.13 | 🟡 MEDIUM | 08 Phase Hints carry hard ordering vs 07 Evolution Sequence = N/A | `07 § 6` + `08 § 3` | Low-Medium |
| 01.14 | 🟡 MEDIUM | state.json vs GlobalVariable dual-source-of-truth rule ADR-only | `adr/007-*.md` + `02 § 6.1` | Low |
| 01.15 | 🔵 LOW | "Correction note for ADR-010 alignment" = meta-comment | `04 § 9` | Low |
| 01.16 | 🔵 LOW | Glossary "JWT/RBAC/RLS/HPA/PVC = N/A" entry = noise | `02 § 8` | Low |
| 01.17 | 🔵 LOW | BV row mis-tags FR-7.6/BR-9.4 in component catalog | `02 § 4.2` | Low |

**Total findings:** 17 (1 CRITICAL / 4 HIGH / 9 MEDIUM / 3 LOW)

---

> **Reminder for Architect Phase 1B (rebuttal):**
> - Claim 01.1 (CRITICAL) ต้อง resolve ก่อน Implementation Handoff — ADR amendment + 04 fix
> - Claims 01.2-01.5 (HIGH) จะกระทบ TD Phase 1D + QA Phase 3T — ปลอด-block ก่อน proceed
> - Claims 01.6-01.14 (MEDIUM) acceptable to address ใน rebuttal round 02 หรือ partial fix + acknowledged risk
> - Claims 01.15-01.17 (LOW) = polish; can batch fix
> - Run `/sd-rebuttal claim-review-01.md` to generate fix plan + Defender response
