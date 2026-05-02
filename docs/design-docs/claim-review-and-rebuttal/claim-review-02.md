# System Design Claim Review Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Target** | `all` (post-rebuttal-01 verification — 6 design docs + 12 ADRs + 4 API specs) |
| **Date** | 2026-05-02 |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |
| **Predecessor** | `claim-review-01.md` (17 findings) → `rebuttal-round-01.md` (14 Accept / 3 Partial / 0 Reject) |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL **0** / 🟠 HIGH **0** / 🟡 MEDIUM **4** / 🔵 LOW **2**)
**Schedule-leakage check:** ✅ Clean — grep `Sprint|Week|Q[1-4] 202X|team capacity|## Phase Plan|Schedule|Roadmap` พบ 0 hits ใน design-docs
**Language check:** ✅ Pass — Thai narrative ≥ 40% ทุก doc; TL;DR/section openers/decision rationale เป็นไทย; tech term English
**No-Hints Pass-Through:** Phase Hints = FULL variant ใน `08`; Evolution Sequence = 2 entries (E1+E2) ใน `07 § 6` (newly added by rebuttal-01) — ทั้งคู่ legitimate
**Anti-Duplication:** Round 01 fixes (01.1 Safe-port, 01.2 latency math, 01.3 handle count, 01.4 Option B design, 01.5 spec format, 01.7 SpreadGuard split, 01.9 BV/IS ownership, 01.11 override enforcement, 01.13 Evolution Sequence, 01.14 Sync rule) verified **landed correctly** ใน ADR + cross-doc — ไม่ raise ซ้ำ
**Net assessment:** Rebuttal Round 01 = high-quality fix coverage. Round 02 พบเฉพาะ **residual cascade misses** จาก fix ที่ใหญ่ — primarily diagram/TL;DR ที่ไม่ sync กับ section body ที่ rewrite

### Top 3 to Fix First

1. **Claim 02.1** 🟡 — `07 § TL;DR` contradicts `07 § 6` — TL;DR ยังบอก *"Evolution Sequence ไม่จำเป็น (skip)"* แม้ § 6 จะมี E1+E2 แล้ว — `docs/design-docs/07-future-evolution.md`
2. **Claim 02.2** 🟡 — `04 § 1.1` mermaid Note hardcodes *"tick budget 7000 µs (10% over baseline)"* — ขัด Claim 01.2 fix ที่ระบุ baseline = TBD pending IMPL-065
3. **Claim 02.3** 🟡 — `02 § 4.1` mermaid ยังมี edge `BV --> IS` — ขัด Claim 01.9 fix (FR-7.6 ownership ย้ายจาก BV → IS)

### Verdict

- [x] ✅ **Ready for Implementation Handoff** — ไม่มี CRITICAL/HIGH; remaining 4 MEDIUM + 2 LOW = readability/cascade polish ที่ optional fix ได้ก่อน TD lock
- [ ] ⚠️ **Needs Rebuttal Round** — N/A (no CRITICAL/HIGH)
- [ ] ⛔ **Immediate Attention** — N/A

> **Recommendation:** Architect ทำ light cascade pass (estimated effort: 30 min) แก้ 4 MEDIUM ที่เป็น residual diagram/TL;DR drift; ถ้ายอมรับ residual → proceed ไป TD Phase 1D ตรง ๆ ได้

---

## System Design Attack Vector Checklist (22 Categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass | ADR-001 unchanged from Round 01 ✅ |
| 2 | Service Boundaries | ✅ Pass (mostly) | Claim 01.9 BV/IS ownership fixed in `§ 4.2` table; **mermaid edge stale** → 02.3 |
| 3 | Communication Patterns | ✅ Pass | unchanged |
| 4 | Data Consistency | ✅ Pass | Claim 01.14 Sync rule landed ใน `02 § 6.1.1` — comprehensive 6-row table ✅ |
| 5 | Database Design | ✅ Pass | unchanged |
| 6 | Caching Strategy | ✅ Pass | unchanged |
| 7 | Security Design | ✅ Pass | Claim 01.10 monitoring signals added ใน `05 § 7.2` ✅ |
| 8 | Scalability | ✅ Pass | unchanged |
| 9 | Reliability & Fault Tolerance | ✅ Pass | Claim 01.4 Option B fully designed ✅; Claim 01.10 RPO contract + escalation policy added ✅ |
| 10 | Performance Budgets | ⚠️ Finding 02.2 | Tables A+B reconcile properly; **mermaid Note** ใน `04 § 1.1` ยัง hardcode 7000 µs |
| 11 | Concrete Numbers | ✅ Pass (with caveats) | Claim 01.3 handle count locked ~25; Claim 01.6 force-clear engineering estimate flagged + A6 added ✅ |
| 12 | API Contract Quality | ✅ Pass | Claim 01.5 slot-abstraction-contract.yaml rewritten to JSON Schema 2020-12 ✅ |
| 13 | Data Flow Completeness | ✅ Pass | Claim 01.7 SpreadGuard split + 01.8 P-Pending sub-mode subsection added ✅ |
| 14 | Observability | ⚠️ Finding 02.4 | Claim 01.12 throttle policy + escalation/halt-bypass landed ใน ADR-011 ✅; **schema description** ของ `force_clear_count` "reset on EA reload" ขัดกับ persistence behavior |
| 15 | ADR Quality | ✅ Pass | 7 ADRs updated cleanly per rebuttal; ADR-007 Option B = full design (3-file + 1-byte pointer + crash matrix) ✅ |
| 16 | Cross-Doc Consistency | ⚠️ Findings 02.1, 02.2, 02.3 | Round 01's 4 contradictions resolved ✅; new residual drift = TL;DR vs section body in `07`, mermaid Note vs Table B in `04`, mermaid edge in `02` |
| 17 | Requirements Traceability | ✅ Pass | unchanged |
| 18 | Failure Modes | ✅ Pass | A6+A7 added ใน `03 § 7` ✅ |
| 19 | Future Evolution + Evolution Sequence | ⚠️ Finding 02.1 | E1+E2 added cleanly ใน `07 § 6.1`; **TL;DR ไม่ update** |
| 20 | Work Inventory + Phase Hints | ⚠️ Finding 02.6 | Claim 01.13 cross-link added ใน `08 § TL;DR` ✅; Claim 01.11 IMPL-018 expanded ✅; **IMPL-068 metadata** ไม่ reference A6 risk |
| 21 | Readability / Reader-Empathy | ⚠️ Finding 02.5 | Claim 01.15 correction-note removed ✅; Claim 01.16 glossary noise removed ✅; **02 § 9 ADR Digest ADR-006 row** trade-off ไม่ surface escalation policy |
| 22 | Language Rule Compliance | ✅ Pass | bilingual ทุก doc; new content (P-Pending sub-mode subsection, Sync rule, Evolution Sequence) เขียนเป็นไทย-led ครบ |

---

## Findings (ordered: 🟡 MEDIUM → 🔵 LOW)

### 🟡 MEDIUM

#### Claim 02.1: 🟡 MEDIUM — `07 § TL;DR` ขัด `07 § 6` (Evolution Sequence "ไม่จำเป็น" vs E1+E2 มีอยู่จริง)

**Location:** `docs/design-docs/07-future-evolution.md` § TL;DR (บรรทัด 11) vs § 6 "Evolution Sequence (Phase 1 internal — hard architectural ordering)"

**Problem:**
TL;DR (บรรทัด 11) ยัง quote round-0 wording เดิม:

> *"ดังนั้น **Evolution Sequence ของ multi-step ordered architectural rollout = ไม่จำเป็น** (skip per `sd.md § 1.3 Phase Contract` — missing ≠ defect)."*

แต่ § 6 ตอนนี้มี Evolution Sequence จริง — 2 entries (E1 atomic-write spike chain + E2 CSlotBase contract chain) — ที่เพิ่มจาก Claim 01.13 fix. End-of-doc footer (บรรทัด 244) ก็ตรงกับ § 6 ("Evolution Sequence = 2 entries"). **TL;DR ไม่ update ตาม § 6 rewrite**.

**Why this matters:**
TL;DR คือ first impression — Tech Lead / Impl Planner อ่าน TL;DR เพื่อเลือกว่าต้อง dive deep ไหน. ถ้า TL;DR บอก "ไม่จำเป็น" reader จะ skip § 6 → miss E1+E2 hard ordering ที่ Phase Hints ผูกอยู่ → ผิด phasing decision (e.g., schedule IMPL-047 ก่อน IMPL-046 spike). Round 01 rebuttal § Cross-doc ระบุ "08 TL;DR cross-link added" แต่ลืม update doc ที่ Evolution Sequence อยู่ (07 TL;DR เอง).

**Minimum acceptable fix:**
แก้ `07 § TL;DR` ประโยคที่ระบุ "ไม่จำเป็น (skip)" เป็น:

> *"Evolution Sequence ของ Phase 1 internal sequencing = **2 entries (E1 atomic-write spike chain + E2 CSlotBase contract chain)** — ดู § 6. Multi-service / migration / external API ordering = ไม่อยู่ใน Phase 1 (greenfield monolith)."*

**Effort:** Low (5 minutes — single TL;DR sentence rewrite)

---

#### Claim 02.2: 🟡 MEDIUM — `04 § 1.1` mermaid Note hardcodes "tick budget 7000 µs (10% over baseline)" ขัด Claim 01.2 baseline-TBD stance

**Location:** `docs/design-docs/04-data-flow.md` § 1.1 (mermaid sequence diagram — Note over Orc บรรทัด 39)

**Problem:**
Mermaid Note ใน sequence diagram ระบุ:

> *`Note over Orc: t = 0 µs<br/>tick budget 7000 µs (10% over baseline)`*

ค่า "7000 µs" บ่งชี้ว่า assume baseline = 7 ms × 10% NFR-2.1 budget. แต่ Claim 01.2 fix เพิ่ง rewrite `03 § 2.3` ระบุ:

> *"Original EA tick latency baseline: ⚠️ TBD ใน TD spike Phase 1D (IMPL-065 measurement protocol) — `~7 ms` ที่อ้างใน round 0 draft = engineering guess"*

และ `04 § 1.2 Key insights` (บรรทัด 132) update ให้ "NFR-2.1 acceptance ผูกกับ measured baseline จาก IMPL-065 — ถ้า baseline ≤ 7 ms → ต้อง mitigate; ถ้า ≥ 10 ms → borderline pass". **mermaid Note ใน § 1.1 ยังตอกเลข 7000 µs hardcoded** — เป็น residual จาก round-0 ที่ Claim 01.2 fix ลืม cascade ไป mermaid

**Why this matters:**
Tech Lead / QA อ่าน sequence diagram เป็น first reference (ภาพ > prose). Hardcoded "tick budget 7000 µs" ทำให้ reader คิดว่า budget ผ่าน NFR-2.1 ที่ 7 ms baseline = locked decision; ที่จริง baseline ยังไม่ measure → budget = TBD. Cascade risk: TD spike (IMPL-065) วัด baseline = 5 ms → mermaid Note ผิดทันที, แต่ reader ที่อ่าน 04 ก่อน 03 อาจไม่เจอ caveat

**Minimum acceptable fix:**
แก้ Note ใน mermaid (line 39) เป็น:

```
Note over Orc: t = 0 µs<br/>tick budget = 0.10 × measured baseline<br/>(baseline TBD per IMPL-065; ดู 03 § 2.3 Table B)
```

**Effort:** Low (2 minutes — single mermaid Note edit)

---

#### Claim 02.3: 🟡 MEDIUM — `02 § 4.1` Component Inventory mermaid ยังมี edge `BV --> IS` ที่ stale หลัง Claim 01.9 fix

**Location:** `docs/design-docs/02-high-level-architecture.md` § 4.1 (mermaid graph — line 233)

**Problem:**
Layer-summary mermaid ยังมี edge:

```
BV --> IS
BV --> ENUM
```

แต่ Claim 01.9 fix (rebuttal ระบุ) ย้าย indicator handle validation ownership ออกจาก `BootstrapValidator` ไป `IndicatorService::CreateHandles()`. § 4.2 Component Catalog row 3 (BV) ก็ลบ "indicator handle validation" + FR-7.6 + ADR-003 ออกแล้ว. § 4.2 row 7 (IS) เพิ่ม FR-7.6 + ADR-003 ตามที่ควร. **Mermaid diagram บรรทัด 233 ยังเก็บ edge `BV --> IS`** ที่บ่งชี้ว่า BV เรียก IS — contradiction กับ § 4.2 ที่ระบุว่า BV ไม่ touch indicator handles อีก

**Why this matters:**
`04 § 5.1` boot sequence แสดงชัดว่า Orchestrator เรียก BV (ValidateInputs/ValidateSymbol/DetectDigitMultipier) **แยกออก** จากการเรียก IS.CreateHandles() — i.e., Orchestrator → BV และ Orchestrator → IS เป็น 2 calls ไม่เกี่ยวกัน. Mermaid edge `BV --> IS` ขัด architecture จริง — reader คิดว่า BV ยัง orchestrate IS handle creation = false mental model

**Minimum acceptable fix:**
ลบ edge `BV --> IS` (line 233) จาก mermaid. แทนด้วย `ORC --> IS` (Orchestrator owns IS lifecycle directly) ถ้าต้องการ explicit; หรือลบไปเฉย ๆ เพราะ `ORC --> services` ครอบคลุมทุก service อยู่แล้ว (IS อยู่ใน services subgraph)

**Effort:** Low (1 minute — single line removal)

---

#### Claim 02.4: 🟡 MEDIUM — Schema description ของ `force_clear_count` "reset on EA reload" ขัด state.json persistence behavior

**Location:** `docs/api-specs/state-persistence-schema.yaml` § `definitions/PendingMachineState_Bounded.force_clear_count` (บรรทัด 199-202) — และ `logger_metrics.throttled_alert_count` (บรรทัด 174-178)

**Problem:**
Schema description ระบุ:

```yaml
force_clear_count:
  type: integer
  description: "Cumulative session counter; reset on EA reload (observability metric)"
```

```yaml
throttled_alert_count:
  description: "...Reset on EA reload"
```

**ขัดกับ behavior** — ทั้ง 2 fields เป็น `required` หรือ persisted properties ของ state.json (เขียน atomic per ADR-007 ทุก tick). `StatePersistence::Load()` ที่ OnInit (= EA reload) จะ restore field values จากไฟล์ → effectively **NOT** reset. ถ้าจะ reset on reload ต้อง explicit logic ใน `Load()` ที่จะ overwrite field เป็น 0 — แต่ behavior นี้ไม่ระบุที่ไหน (ไม่อยู่ใน ADR-007 Load pseudocode, ไม่อยู่ใน `04 § 5.3 Recovery scenarios`)

ADR-008 § Decision (บรรทัด 51-52) ก็ระบุว่า force_clear_count คือ "per-slot counter ใน WatchProfits (FR-4.4) — observability metric" — WatchProfits = persisted via state.json + GlobalVariable. **2 sources บอกตรงข้าม:** schema = "session-only reset on reload"; ADR-008 + persistence layer = "cumulative across restarts"

**Why this matters:**
QA Phase 3T ใช้ `force_clear_count` validate ADR-008 (IMPL-068) — ถ้า counter reset ทุก restart → QA วัดได้แค่ session counts → miss long-running stuck pattern ที่ครอบคลุมหลาย restart. Likewise `throttled_alert_count` reset ทุก reload → user ที่ restart EA ทุกวันจะไม่เห็น cumulative throttle pattern → ขัด NFR-3.4 transparency intent ของ Claim 01.12 fix

**Minimum acceptable fix:**
เลือก 1 ใน 2 paths และ align ทุก source:

**Option A (recommended):** counter = cumulative across restarts (ตรงกับ ADR-008 intent + atomic persistence semantic)
- แก้ schema description: `force_clear_count` → `"Cumulative counter; survives restart via state.json (atomic per ADR-007); reset only via manual delete state.json"`
- แก้ schema description: `throttled_alert_count` → `"Cumulative counter; survives restart"`
- ADR-011 § Throttled counter description ก็ update คล้ายกัน

**Option B:** counter = session-only (ตรงกับ schema description ปัจจุบัน)
- เพิ่ม explicit reset logic ใน ADR-007 § Load pseudocode: `force_clear_count := 0` + `throttled_alert_count := 0` หลัง parse
- ใน `04 § 5.3 Recovery scenarios` row "Reboot after clean shutdown" เพิ่ม note "force_clear_count + throttled_alert_count reset to 0"

**Effort:** Low (10 minutes — 3-5 doc edits)

---

### 🔵 LOW

#### Claim 02.5: 🔵 LOW — `02 § 9 ADR Digest` ADR-006 row trade-off ไม่ surface escalation policy ที่ Claim 01.10 เพิ่ม

**Location:** `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest — row ADR-006

**Problem:**
ADR Digest row ADR-006 trade-off cell ยังระบุเฉพาะ:

> *"Sync write ~1-3 ms/event; bulk-close burst exceeds 5ms — degrade-warn-but-continue"*

แต่ Claim 01.10 fix เพิ่ม **escalation policy** ที่ ADR-006 § Failure handling: `consecutive_write_failures ≥ 10 → EAState.Halt("journal_write_fail_sustained")`. นี่เป็น **behavior change ที่ user-facing** (EA halts ในกรณี sustained disk failure) — controlled by counter ใน state.json ที่ user monitor ผ่าน `05 § 7.2`. ADR Digest ที่ summary "หาเร็ว" ไม่ surface = reader ที่อ่าน ADR Digest อย่างเดียวจะ miss

**Why this matters:**
ADR Digest = condensed architectural summary; missing escalation policy = reader (Tech Lead, QA) ที่ relate ใน 1 row ไม่เห็นว่า ADR-006 ตอนนี้ trigger halt ได้ → mental model ผิด (คิดว่า journal ไม่มีทาง halt EA, แต่ที่จริง sustained fail → halt). LOW เพราะ ADR-006 ตัวเต็ม + `04 § 8 Sustained failure escalation` section + `05 § 7.2` monitoring signals บอกครบแล้ว — เฉพาะ Digest row ที่ stale

**Minimum acceptable fix:**
อัพเดท trade-off cell:

> *"Sync write ~1-3 ms/event; bulk-close burst exceeds 5ms — degrade-warn-but-continue. **Sustained fail (≥ 10 consecutive) → halt EA via ADR-010**"*

**Effort:** Low (1 minute — single cell edit)

---

#### Claim 02.6: 🔵 LOW — `08 § IMPL-068` description ไม่ reference A6 risk ที่ Claim 01.6 เพิ่ม

**Location:** `docs/design-docs/08-product-breakdown.md` § 1.10 IMPL-068 + § 4 Per-Task Metadata IMPL-068 row

**Problem:**
IMPL-068 description ปัจจุบัน:

> *"Force-clear validation (`force_clear_count` per slot in baseline = 0 expected)"*

แต่ Claim 01.6 fix เพิ่ม **risk A6** ใน `03 § 7`:

> *"⚠️ A6 — ADR-008 force-clear thresholds (M=150, T=80, Q=100) คือ engineering estimate ไม่ใช่ measured derivation — QA Phase 3T (IMPL-068) ... measure `pending_age_bars` distribution; if force_clear > 0 หรือ max bars > 70% threshold → tune via input + re-validate"*

A6 expanded scope ของ IMPL-068 จาก single-shot "verify count == 0" → **distribution measurement + threshold tuning loop** — ใน `08` task description ไม่ reflect

**Why this matters:**
Impl Planner / QA pickup IMPL-068 จาก `08` work inventory — ถ้า scope ที่อ่านคือแค่ "verify count == 0", QA จะวางแผน 1-day task; แต่ A6 บ่งชี้ measurement + tuning loop ที่ scope larger. LOW เพราะ `03 § 7` A6 ครอบคลุมแล้ว — เฉพาะ `08` cross-link ที่ขาด

**Minimum acceptable fix:**
อัพเดท IMPL-068 description (§ 1.10 + § 4):

> *"Force-clear validation per A6 (`03 § 7`) — measure `pending_age_bars` distribution per machine + `force_clear_count` ≈ 0 expected; tune `InpForceClearX_Bars` if max bars > 70% threshold"*

**Effort:** Low (2 minutes — 2 row edits)

---

## Cross-Document Issues

| Issue | Files affected | Finding |
|-------|----------------|---------|
| TL;DR / mermaid Note / mermaid edge ไม่ cascade ตาม section body rewrite | `07 § TL;DR`, `04 § 1.1` mermaid, `02 § 4.1` mermaid | 02.1, 02.2, 02.3 |
| Schema description vs persistence behavior contradict | `state-persistence-schema.yaml`, ADR-008, ADR-011 | 02.4 |
| ADR Digest row + work-inventory description ไม่ surface fix ที่ landed ใน body | `02 § 9`, `08 IMPL-068` | 02.5, 02.6 |

ไม่พบ contradictions ระดับ architectural — Round 01's 4 cross-doc contradictions (Safe-port, handle count, BV/IS ownership, dual-source-of-truth) ทั้งหมด resolved ✅

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 02.1 | 🟡 MEDIUM | `07 TL;DR` ขัด `§ 6` Evolution Sequence | `07-future-evolution.md` § TL;DR | Low |
| 02.2 | 🟡 MEDIUM | mermaid Note hardcode 7000 µs ขัด baseline-TBD | `04-data-flow.md` § 1.1 | Low |
| 02.3 | 🟡 MEDIUM | mermaid edge `BV --> IS` stale | `02-high-level-architecture.md` § 4.1 | Low |
| 02.4 | 🟡 MEDIUM | schema "reset on EA reload" ขัด persistence | `state-persistence-schema.yaml` | Low |
| 02.5 | 🔵 LOW | ADR-006 Digest trade-off ไม่ surface escalation | `02-high-level-architecture.md` § 9 | Low |
| 02.6 | 🔵 LOW | IMPL-068 description ไม่ reference A6 | `08-product-breakdown.md` § 1.10, § 4 | Low |

> **End of Round 02 review** — Round 01 fixes verified solid; 6 residual cascade misses (4 MEDIUM + 2 LOW) ที่เป็น diagram/TL;DR drift จาก section body rewrite. Total fix effort < 30 minutes. Recommend light cascade pass (no rebuttal needed; lightweight `/amend sd` หรือ direct edit) → proceed ไป TD Phase 1D
