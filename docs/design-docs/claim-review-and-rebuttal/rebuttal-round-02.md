# System Design Rebuttal Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Claim Review** | `claim-review-02.md` |
| **Date** | 2026-05-02 |
| **Defender** | `andm-sd-defender` (Architect, Phase 1B) |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 6 |
| Partial | 0 |
| Rejected | 0 |

**Files modified (4 design docs / 1 spec / 1 ADR touched):**
- `docs/design-docs/02-high-level-architecture.md` (2 edits — § 4.1 mermaid edge `BV-->IS` → `ORC-->IS`, § 9 ADR-006 trade-off cell add escalation)
- `docs/design-docs/03-deep-dive.md` (1 edit — § 5.3 `force_clear_count` description align cumulative-survives-restart)
- `docs/design-docs/04-data-flow.md` (1 edit — § 1.1 mermaid Note tick-budget formula + cross-ref IMPL-065)
- `docs/design-docs/07-future-evolution.md` (1 edit — § TL;DR rewrite "Evolution Sequence ไม่จำเป็น" → 2 entries E1+E2)
- `docs/design-docs/08-product-breakdown.md` (2 edits — § 1.10 IMPL-068 description + § 4 IMPL-068 metadata row reference A6)
- `docs/api-specs/state-persistence-schema.yaml` (2 edits — `force_clear_count` + `throttled_alert_count` descriptions align cumulative-survives-restart per Option A)

**ADRs updated (1):**
- `adr/011-tagged-structured-logger.md` — Throttled-counter row updated: "Per-session" → "cumulative survives restart" (cascade ของ 02.4 Option A)

**ADRs created:** 0
**API specs created:** 0

Net: 6 residual cascade misses จาก Round 01 fix landed cleanly; ไม่มี architectural pushback; ไม่มี rejected claim; total fix effort < 30 minutes ตามที่ reviewer ประเมิน.

---

## Claim Responses

### Claim 02.1: 🟡 MEDIUM — `07 § TL;DR` ขัด `07 § 6` Evolution Sequence

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/07-future-evolution.md` § TL;DR (บรรทัด 11)
- What changed: ลบ wording เดิม *"Evolution Sequence ของ multi-step ordered architectural rollout = ไม่จำเป็น (skip per sd.md § 1.3 Phase Contract — missing ≠ defect)"* → แทนด้วย *"Evolution Sequence ของ Phase 1 internal sequencing = 2 entries (E1 atomic-write spike chain + E2 CSlotBase contract chain — ดู § 6); multi-service / migration / external API ordering = ไม่อยู่ใน Phase 1 (greenfield monolith)"*. TL;DR + § 6 + end-of-doc footer (บรรทัด 244) ตรงกันครบ 3 ที่
- Evidence (new text — บรรทัด 11): *"...**Evolution Sequence ของ Phase 1 internal sequencing = 2 entries** (E1 atomic-write spike chain + E2 CSlotBase contract chain — ดู § 6); multi-service / migration / external API ordering = ไม่อยู่ใน Phase 1 (greenfield monolith)..."*

### Claim 02.2: 🟡 MEDIUM — `04 § 1.1` mermaid Note hardcode 7000 µs ขัด baseline-TBD

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/04-data-flow.md` § 1.1 mermaid sequence diagram (บรรทัด 39)
- What changed: ลบ hardcoded *"tick budget 7000 µs (10% over baseline)"* → แทนด้วย formula `tick budget = 0.10 × measured baseline` พร้อม cross-ref *"baseline TBD per IMPL-065; ดู 03 § 2.3 Table B"*. ตรงกับ Claim 01.2 fix ที่ระบุ baseline = TBD ผ่าน TD spike Phase 1D
- Evidence (new mermaid Note): *`Note over Orc: t = 0 µs<br/>tick budget = 0.10 × measured baseline<br/>(baseline TBD per IMPL-065; ดู 03 § 2.3 Table B)`*

### Claim 02.3: 🟡 MEDIUM — `02 § 4.1` Component Inventory mermaid edge `BV --> IS` stale

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 4.1 mermaid graph (บรรทัด 233)
- What changed: ลบ edge `BV --> IS` → แทนด้วย `ORC --> IS` (Orchestrator owns IS lifecycle directly, อ้าง Claim 01.9 fix ที่ย้าย FR-7.6 ownership จาก BV → IS). เก็บ edge `BV --> ENUM` (BootstrapValidator ใช้ EnumTypes สำหรับ DigitMultipier auto-detect) ไว้
- Evidence (new mermaid edges):
  ```
  EP --> ORC
  EP --> BV
  BV --> ENUM
  ORC --> IS
  ```
- Cross-doc consistency: § 4.2 Component Catalog row 3 (BV) ไม่มี FR-7.6 + ADR-003 ตั้งแต่ Claim 01.9 fix; row 7 (IS) มี FR-7.6 + ADR-003. mermaid + catalog ตรงกัน.

### Claim 02.4: 🟡 MEDIUM — Schema description `force_clear_count` + `throttled_alert_count` "reset on EA reload" ขัด state.json persistence behavior

**Verdict:** Accept (Option A — cumulative across restarts)

**Decision rationale:** เลือก **Option A** ตาม reviewer recommendation เพราะ:
1. Align ADR-008 § Decision intent (force_clear_count = "per-slot counter ใน WatchProfits — observability metric" — WatchProfits = persisted via state.json + GV)
2. Consistent กับ `journal_metrics` block ที่ Claim 01.10 fix ระบุ explicit *"Cumulative count... Survives restart"*
3. ตรง intent ของ A6 risk (`03 § 7`) ที่ต้อง measure long-running stuck pattern ครอบคลุมหลาย restart
4. ตรง intent ของ NFR-3.4 transparency ที่ Claim 01.12 fix add — user ที่ restart EA ทุกวันต้องเห็น cumulative throttle pattern

**Changes:**
- File: `docs/api-specs/state-persistence-schema.yaml` § `definitions/PendingMachineState_Bounded.force_clear_count` (บรรทัด 199-202)
- What changed: description rewrite จาก *"Cumulative session counter; reset on EA reload"* → *"Cumulative counter; survives restart via state.json (atomic per ADR-007); reset only via manual delete state.json. Used by IMPL-068 / A6 to measure long-running stuck pattern across restarts (observability metric)"*
- File: `docs/api-specs/state-persistence-schema.yaml` § `properties/logger_metrics.throttled_alert_count` (บรรทัด 174-179)
- What changed: description rewrite จาก *"Cumulative session count... Reset on EA reload"* → *"Cumulative counter ของ Alert ที่ถูก throttle...; survives restart via state.json (atomic per ADR-007). User ที่ restart EA บ่อยยังเห็น cumulative throttle pattern (NFR-3.4 transparency)"*
- File: `docs/adr/011-tagged-structured-logger.md` § Decision (Throttled counter row, บรรทัด 61) — **cascade**
- What changed: row text rewrite จาก *"Per-session `logger_metrics.throttled_alert_count` increment...surface ใน HALTED_STABLE Alert message (47 throttled alerts ใน session)"* → *"`logger_metrics.throttled_alert_count` increment...; **cumulative survives restart** via state.json (atomic per ADR-007); reset only via manual delete state.json. Surface ใน HALTED_STABLE Alert message (47 throttled alerts cumulative) → user transparent ว่ามี Alert ถูก suppress รวม cross-restart pattern (NFR-3.4 visibility)"*
- File: `docs/design-docs/03-deep-dive.md` § 5.3 (บรรทัด 302) — **cascade ที่เจอตอน Phase 4 sweep**
- What changed: per-slot field description rewrite จาก *"`force_clear_count`: int (cumulative session counter; reset on EA reload — for QA observability)"* → *"`force_clear_count`: int (cumulative counter; survives restart via state.json per ADR-007; reset only via manual delete state.json — for QA Phase 3T / IMPL-068 long-running stuck pattern measurement per A6)"*

### Claim 02.5: 🔵 LOW — `02 § 9 ADR Digest` ADR-006 row trade-off ไม่ surface escalation policy

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest — row ADR-006 (บรรทัด 466)
- What changed: trade-off cell expand จาก *"Sync write ~1-3 ms/event; bulk-close burst exceeds 5ms — degrade-warn-but-continue"* → *"Sync write ~1-3 ms/event; bulk-close burst exceeds 5ms — degrade-warn-but-continue. **Sustained fail (≥ 10 consecutive) → halt EA via ADR-010**"*
- ADR-006 § Failure handling + `04 § 8` Sustained failure escalation + `05 § 7.2` monitoring signals ไม่ต้องแตะ — ครบแล้วตั้งแต่ Claim 01.10

### Claim 02.6: 🔵 LOW — `08 § IMPL-068` description ไม่ reference A6 risk

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/08-product-breakdown.md` § 1.10 IMPL-068 row (บรรทัด 135)
- What changed: description expand จาก *"Force-clear validation (`force_clear_count` per slot in baseline = 0 expected)"* → *"Force-clear validation per A6 (`03 § 7`) — measure `pending_age_bars` distribution per machine + `force_clear_count` ≈ 0 expected; tune `InpForceClearX_Bars` if max bars > 70% threshold"*. arch_rationale column ก็ expand ระบุ "expanded scope per A6 risk"
- File: `docs/design-docs/08-product-breakdown.md` § 4 Per-Task Metadata Table — IMPL-068 row (บรรทัด 299)
- What changed: arch_rationale rewrite จาก *"force_clear_count ≈ 0 expected"* → *"measure `pending_age_bars` distribution + `force_clear_count` ≈ 0 expected; tune thresholds if max bars > 70% (per A6 in `03 § 7`)"*; unlocks column expand เป็น "ADR-008 validation per A6"
- A6 ใน `03 § 7` ไม่ต้องแตะ — Claim 01.6 fix ระบุ scope ครบแล้ว; เฉพาะ 08 cross-link ที่ขาด

---

## Cascaded Changes

ทุก fix ทำผ่าน 7-step protocol — cascade ที่เกิดขึ้น **นอกเหนือ** จาก claim's stated scope:

1. **02.3 mermaid edge** — แก้ `BV --> IS` ลบ + เพิ่ม `ORC --> IS` แทน (reviewer เสนอ 2 options: ลบเฉย ๆ vs ลบ + เพิ่ม `ORC --> IS`). เลือก option หลังเพื่อ preserve diagram explicitness ของ "Orchestrator owns IS lifecycle" — สอดคล้องกับ `04 § 5.1` boot sequence ที่แสดง `Orc->>IS: CreateHandles()`

2. **02.4 ADR-011 cascade** — claim flag เฉพาะ schema description (state-persistence-schema.yaml) แต่ ADR-011 § Decision row "Throttled counter" ก็ระบุ "Per-session" + Alert message "47 throttled alerts ใน session" ที่ขัด Option A semantics. แก้ ADR-011 ให้ตรง schema (cumulative-survives-restart) เพื่อไม่สร้าง 2 sources ขัดกันใหม่

3. **02.4 cascade เจอตอน Phase 4 sweep** — `03 § 5.3` per-slot field list (บรรทัด 302) ก็มี wording เดิม "cumulative session counter; reset on EA reload" — แก้ให้ตรง schema + ADR-011 (3 sources ตรงกันครบ)

4. **02.5 + 02.6 cross-link verified** — ADR Digest row update (02.5) + IMPL-068 description update (02.6) ไม่ต้อง cascade ที่อื่น เพราะเอา Round 01 fixes (ADR-006 escalation policy + A6 risk) ที่ landed แล้วมา surface ใน high-traffic summary location เท่านั้น

5. **mermaid edge `BV --> ENUM` preserve** — ตรวจ `02 § 4.2` แล้วยืนยันว่า BV ใช้ EnumTypes สำหรับ DigitMultipier auto-detect (BR-9.3) — เก็บ edge ไว้ ไม่ลบ

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 6/6 = 100% | ✅ ทุก claim เป็น residual cascade miss ที่ reviewer flag ถูกต้อง — ไม่มี false positive จาก reviewer; defender ไม่ต้องพิสูจน์ counter-evidence |
| CRITICAL/HIGH Fixes | 0/0 (N/A) | Round 02 ไม่มี CRITICAL/HIGH — Round 01 fixes solid (no regression) |
| MEDIUM Fixes | 4/4 (100%) | TL;DR contradiction (02.1) + mermaid Note (02.2) + mermaid edge (02.3) + schema description Option A (02.4) ครบ |
| LOW Fixes | 2/2 (100%) | ADR Digest escalation (02.5) + IMPL-068 A6 reference (02.6) ครบ |
| ADRs Updated | 1/12 | ADR-011 throttled-counter row align กับ Option A semantics |
| ADRs Created | 0 | ไม่มี architectural change — ทุก fix = wording/diagram alignment |
| API Specs Touched | 1/4 | state-persistence-schema.yaml (2 fields) Option A semantics |
| Net Improvement | **Cascade-polish** — 6 residual diagram/TL;DR/description drifts จาก section body rewrite ของ Round 01 ทั้งหมดถูก resolve. Design now fully self-consistent ทุก high-traffic summary location (TL;DR / mermaid / ADR Digest) match section body |
| Remaining Gaps | 3 (= acknowledged risks A6/A7 + assumption A2 spike — ไม่เปลี่ยนจาก Round 01) | ทุก gap flagged + owned (QA Phase 3T for A6 + TD Phase 1D for A7+A2); ไม่มี silent gap |

## Recommendation

- [x] ✅ **Ready for Implementation Handoff** — Round 02 confirmed Round 01 fixes solid; 6 residual cascade misses resolved; ไม่มี contradiction ใหม่; ไม่มี CRITICAL/HIGH ใน round นี้. Phase 1B SD design = production-ready for TD Phase 1D
- [ ] 🔁 **Request Re-Review** — N/A; fixes ทั้งหมด = wording/diagram polish (no architectural change ใหม่ที่ต้อง verify); reviewer's `claim-review-02.md` Verdict checkbox ✅ "Ready for Implementation Handoff" already ticked
- [ ] ⛔ **Needs Stakeholder Input** — N/A
