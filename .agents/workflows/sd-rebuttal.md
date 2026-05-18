---
description: Analyze, implement fixes, and write rebuttal for a System Design Claim Review round
---

# Workflow: Process System Design Claim Review

> **Output:** `docs/design-docs/claim-review-and-rebuttal/rebuttal-round-XX.md` + updated design docs / ADRs / API specs
> **HALT point:** หลัง Phase 1 (Analysis) — นำเสนอแผนให้ user approve ก่อนเริ่มแก้

**Claim review file:** `{{input}}`

---

## Phase 0: Onboarding

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. `.agents/skills/andm-sd-defender/SKILL.md` — **persona + 7-step execution protocol**
3. `.andm/prompt-templates/system-design-master-prompt.md` — SD quality benchmark
4. `docs/state/overview.md`
5. `docs/design-docs/` — design documents (งานที่ถูก review)
6. `docs/adr/` — Architecture Decision Records
7. `docs/design-docs/claim-review-and-rebuttal/` — previous rounds + rebuttals

---

## Phase 1: Analysis

### 1.1 Load Context (parallel)

1. **Claim review file** — อ่านละเอียดทุก claim
2. **Referenced design docs** — Grep หาไฟล์ `docs/design-docs/0X-*.md` ที่ถูก cite + อ่านทั้งหมด
3. **ADRs + API specs** — อ่านทุกไฟล์ที่ reference หรือ related
4. **BA deliverables (v1.2)** — `docs/ba/02-functional-requirements.md` + `docs/ba/03-non-functional-requirements.md` + `docs/ba/05-user-flows.md` สำหรับ traceability (BA-06 dropped — open questions/risks live ใน 02-05 ตาม domain)
5. **Previous rebuttal** — อ่าน `rebuttal-round-XX.md` ล่าสุด (ถ้ามี)

### 1.2 Engage Persona

Follow `andm-sd-defender` — activate full persona rules + 7-step execution protocol จาก SKILL.md

### 1.3 Analyze Each Claim

แต่ละ claim → determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | 1-sentence ทำไม — cite evidence จาก design doc |
| **Impact Scope** | design docs (02-08; v1.2: gaps 01/06) / ADRs / API specs ไหนต้องแก้ |
| **Cross-Doc Risk** | fix นี้จะ contradict doc/ADR อื่นไหม? |
| **Proposed Fix** | exact technical change — ไม่ใช่ vague "จะปรับปรุง" |

### 1.4 Risk Assessment

แต่ละ accept/partial claim → Grep cross-doc impact:

- Search component/term/number ที่จะแก้ข้าม **ทุก** design doc + ADR + API spec
- Identify ทุก location ที่ reference concept เดียวกัน
- Flag fix ที่จะสร้าง contradiction ใหม่

### 1.5 Phase / Sequencing Claims (Option C Handling)

SD อาจมี **Evolution Sequence** ใน `07-future-evolution.md` และ **Phase Hints + per-task metadata** ใน `08-product-breakdown.md` — เนื้อหาพวกนี้ valid ถ้าผ่าน architectural criteria

**Decision tree:**

```
Reviewer ขอ sprint numbers / calendar dates / team capacity?
├── YES → Reject: "Impl Planner concerns (docs/state/impl-plan.md). SD ให้ architectural hints เท่านั้น"
└── NO → Reviewer ขอ architectural sequencing (Evolution Sequence / Phase Hints พร้อม architectural rationale)?
         ├── YES → Accept ถ้าโปรเจคมี ordering constraints → เพิ่ม section
         └── Reviewer flag EXISTING schedule content (sprints/dates/capacity)?
                  ├── YES → Accept + strip/reformat: keep architectural "why", drop delivery "when"
                  └── Reviewer flag EXISTING Phase Hints ขาด architectural rationale?
                           ├── YES → Accept + add rationale (cite dependency/ADR/risk/MoSCoW)
                           └── Reviewer flag Phase Hints label เป็น "Plan"/"Assignment"?
                                    ├── YES → Accept + relabel "Hints (Suggested)"
                                    └── Edge case → judge on merits
```

**Accept examples (valid requests):**
- *"07 mentions auth extraction must precede payment refactor แต่ไม่อธิบาย why — เพิ่ม Evolution Sequence entry พร้อม ADR-005 citation"* → Accept
- *"08 list tasks แต่ไม่มี hint ว่าอะไร risky — เพิ่ม per-task metadata"* → Accept
- *"Phase Hint IMPL-003 in P2 ไม่มี rationale — ทำไม P2 ไม่ P1?"* → Accept + add rationale

**Reject examples (schedule leakage):**
- *"08 should assign each task to Sprint 1 or Sprint 2"* → Reject: *"sprint assignment เป็น Impl Planner territory"*
- *"Add delivery timeline พร้อม Q1/Q2 dates"* → Reject: *"timeline เป็น delivery ไม่ใช่ architecture"*
- *"Phase 1 ควรเสร็จใน 2 weeks"* → Reject: *"team capacity เป็น Impl Planner concern"*

**Strip-and-reformat examples (existing schedule content):**
- *"07 เขียน 'migrate users by March 2026'"* → Strip "by March 2026", keep "migrate users" เป็น E2 พร้อม architectural reason
- *"08 assign IMPL-005 to Sprint 2"* → Strip "Sprint 2", ย้ายเป็น P2 Phase Hint พร้อม architectural reason

**ADR Rule for Sequencing:**
- Evolution Sequence reflect NEW architectural constraint → create/update ADR
- Phase Hints ปกติไม่ต้องมี ADR ของตัวเอง (derive จาก deps + MoSCoW ที่ document แล้ว)

---

### 1.6 HALT — Present Analysis to User

แสดง summary ใน chat (ภาษาไทย, scan-first):

```markdown
## 🛑 HALT — Rebuttal Plan for Round XX

**Total claims:** N (🔴 N / 🟠 N / 🟡 N / 🔵 N)
**Verdicts:** N Accept · N Partial · N Reject

### Will Modify (Accept + Partial)

| # | Severity | Title | Files to Modify | Cross-Doc Risk |
|---|----------|-------|-----------------|----------------|
| XX.1 | 🔴 CRITICAL | [title] | `03-deep-dive.md`, `docs/adr/007-...md` | ⚠️ ADR-007 เปลี่ยน → cascade `02-high-level-architecture.md § ADR Digest` |
| XX.2 | 🟠 HIGH | [title] | `04-data-flow.md`, `api-specs/orders.yaml` | ไม่มี |

**Verdict rationale (1 บรรทัดต่อ claim):**
- **XX.1 Accept** — Saga pattern ขาด compensation mechanism จริง; จะเพิ่ม compensation events
- **XX.2 Accept** — API contract ขาด error schema; จะเพิ่ม 400/409/422 schemas

### Will Reject (Evidence Provided)

| # | Severity | Title | Reason (1-line) |
|---|----------|-------|-----------------|
| XX.3 | 🔵 LOW | [title] | ADR-003 มี formula แล้ว; reviewer miss |

### Cross-Doc Risks Flagged

- Claim XX.1: แก้ Saga ใน `03` → cascade update ADR-007 + `02-high-level-architecture.md § ADR Digest` + `04-data-flow.md` sequence diagram

### ADR Changes Required

- Update ADR-007 (Payment Service Consistency Model)
- Create new ADR-015 (Saga Compensation Strategy) [if needed]

### Questions for You (ถ้ามี)

1. Claim XX.1 เสนอ 2 compensation strategies — เลือก event-driven หรือ orchestration?
2. [...]

---

**⏸ รอคำตอบจากคุณก่อนเริ่มแก้**
```

**หลัง user approve** → proceed Phase 2

---

## Phase 2: Execution

### 2.1 Process Claims One at a Time

แต่ละ accept/partial claim ตาม 7-step sequence (strict):

```
Step 1: Announce — "Fixing Claim XX.3: HIGH — Missing circuit breaker for Web→API calls"
Step 2: Fresh Read — read target section (ไฟล์อาจเปลี่ยนจาก fix ก่อนหน้า)
Step 3: Cross-Doc Check — Grep related terms ใน design docs + ADRs + API specs
Step 4: Apply Fix — Edit minimal + focused
Step 5: Verify — re-read ว่า fix ถูก
Step 6: Cascade Check — ถ้า fix เปลี่ยน component name / number / tech choice / pattern:
         - Grep old value ข้ามทุก design doc + ADR + API spec
         - Update references
         - ถ้า architecture decision เปลี่ยน → update/create ADR
         - Document what cascaded
Step 7: Mark Complete
```

> **Safety Rule:** ถ้า fix จะ contradict design doc หรือ ADR อื่น → **STOP + report user** ห้าม silently create new contradiction

> **ADR Rule:** ถ้า fix เปลี่ยน architecture decision → update/create ADR ใน `docs/adr/` พร้อม format: Title → Status → Context → Options → Decision → Consequences → Revisit-when

### 2.2 Handle Rejected Claims

แต่ละ rejected claim → เตรียม technical justification ละเอียด:

- Cite specific design doc section ที่ address concern
- Quote exact text ที่ reviewer miss/misread
- แสดง formula/derivation ถ้า reviewer question concrete numbers
- อธิบายว่าทำไม current design ถูก/พอ
- ถ้า reviewer miss context → ชี้ว่า context อยู่ที่ไหน

---

## Phase 3: Write Rebuttal

### 3.1 Create Rebuttal File

Write `docs/design-docs/claim-review-and-rebuttal/rebuttal-round-XX.md`:

```markdown
# System Design Rebuttal Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Claim Review** | `claim-review-XX.md` |
| **Date** | YYYY-MM-DD |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | N |
| Partial | N |
| Rejected | N |

**Files modified:** `03-deep-dive.md` (2 changes), `docs/adr/007-...md` (updated), `docs/api-specs/orders.yaml` (1 change)
**ADRs updated/created:** ADR-007 updated, ADR-015 created

---

## Claim Responses

### Claim XX.1: [Title]
**Verdict:** Accept
**Changes:**
- File: `docs/design-docs/03-deep-dive.md` § Saga Compensation
- What changed: [ภาษาไทย specific]
- Evidence (new text): *"[quote updated text]"*
- ADR updated: `docs/adr/007-...md` (status / consequences updated)

### Claim XX.2: [Title]
**Verdict:** Reject
**Justification:**
[ภาษาไทย พร้อม doc citation — quote exact text ที่ address concern; ถ้า reviewer question concrete number ให้แสดง formula]

### Claim XX.3: [Title]
**Verdict:** Partial
**Accepted part:** [ภาษาไทย — ส่วนที่ fix]
**Rejected part:** [ภาษาไทย — ส่วนที่ถูกแล้ว + evidence]
**Changes:**
- File: `[filename]` § [section]
- What changed: [description]

---

## Cascaded Changes

[List changes ใน docs ที่ **ไม่ได้** cite ใน claims โดยตรง — รวม ADR updates]

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | N% | [ภาษาไทย] |
| Critical Fixes | N | [ภาษาไทย] |
| ADRs Updated | N | [ภาษาไทย] |
| Net Improvement | [ภาษาไทย] | |
| Remaining Gaps | N items | [ภาษาไทย] |

## Recommendation

- [ ] ✅ **Ready for Implementation Handoff** — all Critical/Major claims resolved
- [ ] 🔁 **Request Re-Review** — significant changes, reviewer should verify
- [ ] ⛔ **Needs Stakeholder Input** — deferred items block further progress
```

---

## Phase 4: Final Consistency Sweep

หลัง fix ทั้งหมด → parallel checks:

1. **Component name consistency** — Grep ข้าม modified design docs
2. **Number consistency** — Grep timeout, pool_size, rate_limit, TTL → verify match
3. **Tech stack consistency** — tech names match ข้าม docs + ADRs
4. **New contradictions** — compare modified sections กับ related docs
5. **Diagram alignment** — ถ้า architecture descriptions เปลี่ยน → verify Mermaid match
6. **ADR alignment** — design choices match ADR decisions
7. **API contract alignment** — ถ้า data flow/endpoints เปลี่ยน → verify `docs/api-specs/` match
8. **NFR alignment** — performance targets match BA deliverables
9. **Language Rule compliance (MANDATORY)** — re-scan modified sections:
   - ถ้า fix เพิ่ม/แก้ไข architectural decision / `Why:` / trade-off prose → ต้องเป็น **ไทย** (code-switched กับ English tech term)
   - ถ้า fix แค่ edit ข้อความ English ที่ violate LANGUAGE RULE อยู่เดิม → **rewrite ให้ bilingual ด้วย** ห้าม preserve violation
   - ถ้าเจอ H2/H3 section หรือ Mermaid diagram ที่ไม่มี Thai narrative (ก่อน/หลัง) → เพิ่ม + flag ใน "Cascaded Changes"
   - ถ้า tech term ถูกแปลเป็นไทย (เช่น "ตัวกลาง queue" แทน `Redis queue`) → แก้กลับเป็น English
   - ADR ที่ update: Context/Decision/Consequences prose ต้องเป็นไทย (Status/Revisit-when labels คง English)
   - Mechanical check: `grep -o '[ก-๏]' <file> | wc -l` เทียบกับ total char count — ratio ≥ 40% ถือว่า pass
   - Benchmark: `system-design-master-prompt.md § LANGUAGE RULE`

ถ้าเจอ inconsistency จาก fix:
- Fix ทันที
- เพิ่มใน **"Cascaded Changes"** section

---

## Phase 5: Report (ภาษาไทย)

- Claims processed: N accepted / N rejected / N partial
- List of files modified (พร้อม change count per file)
- List of ADRs updated หรือ created
- Path ของ new `rebuttal-round-XX.md`
- Cross-doc issues ที่เจอ + resolve
- Highlight claims ที่ cascade หลาย docs
- Recommendation: ready for implementation handoff / needs another review cycle
