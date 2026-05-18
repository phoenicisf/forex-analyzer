---
description: Analyze, implement fixes, and write rebuttal for a BA Claim Review round
---

# Workflow: Process BA Claim Review

> **Output:** `docs/ba/claim-review-and-rebuttal/rebuttal-round-XX.md` + updated BA docs
> **HALT point:** หลัง Phase 1 (Analysis) — นำเสนอแผนให้ user approve ก่อนเริ่มแก้

**Claim review file:** `{{input}}`

---

## Phase 0: Onboarding

1. `CLAUDE.md` — project rules
2. `.agents/skills/andm-ba-defender/SKILL.md` — **persona + 7-step execution protocol**
3. `.andm/prompt-templates/ba-requirements-prompt.md` — BA quality benchmark
4. `docs/state/overview.md`
5. `docs/ba/` — BA deliverables (งานที่ถูก review)
6. `docs/ba/claim-review-and-rebuttal/` — previous rounds + rebuttals

---

## Phase 1: Analysis

### 1.1 Load Context (parallel)

1. **Claim review file** — อ่านละเอียดทุก claim
2. **Referenced BA docs** — Grep หาไฟล์ `docs/ba/0X-*.md` ที่ถูก cite + อ่านทั้งหมด
3. **Previous rebuttal** — อ่าน `rebuttal-round-XX.md` ล่าสุด (ถ้ามี) เพื่อ fix history

### 1.2 Engage Persona

Follow `andm-ba-defender` — activate full persona rules + 7-step execution protocol จาก SKILL.md

### 1.3 Analyze Each Claim

แต่ละ claim → determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | 1-sentence ทำไม — cite evidence จาก BA doc |
| **Impact Scope** | BA docs `01`-`06` ไหนที่ต้องแก้ |
| **Cross-Doc Risk** | fix นี้จะ contradict doc อื่นไหม? |
| **Proposed Fix** | การเปลี่ยนแปลงจริง ๆ — ไม่ใช่ vague "จะปรับปรุง" |

### 1.4 Risk Assessment

แต่ละ accept/partial claim → Grep cross-doc impact:

- Search entity/term/actor ที่จะแก้ข้าม **ทุก** BA doc
- Identify ทุก location ที่ reference concept เดียวกัน
- Flag fix ที่จะสร้าง contradiction ใหม่

---

### 1.5 HALT — Present Analysis to User

แสดง summary ใน chat (ภาษาไทย, scan-first):

```markdown
## 🛑 HALT — Rebuttal Plan for Round XX

**Total claims:** N (🔴 N / 🟠 N / 🟡 N / 🔵 N)
**Verdicts:** N Accept · N Partial · N Reject

### Will Modify (Accept + Partial)

| # | Severity | Title | Files to Modify | Cross-Doc Risk |
|---|----------|-------|-----------------|----------------|
| XX.1 | 🔴 CRITICAL | [title] | `02-functional-requirements.md`, `05-user-flows.md` | ⚠️ FR-005 ref ใน 03 ต้อง update ด้วย |
| XX.2 | 🟠 HIGH | [title] | `03-non-functional-requirements.md` | ไม่มี |

**Verdict rationale (1 บรรทัดต่อ claim):**
- **XX.1 Accept** — FR-005 กับ FR-012 ขัดแย้งกันจริง ต้องตัดสินใจ assignment model
- **XX.2 Accept** — NFR "fast response" ไม่มีตัวเลข; จะเพิ่ม p95 target

### Will Reject (Evidence Provided)

| # | Severity | Title | Reason (1-line) |
|---|----------|-------|-----------------|
| XX.3 | 🔵 LOW | [title] | section 3.2 มี glossary definition แล้ว; reviewer miss |

### Cross-Doc Risks Flagged

- Claim XX.1: แก้ FR-005 → ต้อง cascade update ใน `03-non-functional-requirements.md` (NFR-007 reference) + `05-user-flows.md` (Flow-03)

### Questions for You (ถ้ามี)

1. Claim XX.1 เสนอ 3 options (A/B/C) — เลือกข้อไหน?
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
Step 1: Announce — "Fixing Claim XX.3: HIGH — Missing measurable NFR target"
Step 2: Fresh Read — read target section (ไฟล์อาจเปลี่ยนจาก fix ก่อนหน้า)
Step 3: Cross-Doc Check — Grep related terms ใน BA docs อื่น
Step 4: Apply Fix — Edit minimal + focused
Step 5: Verify — re-read ว่า fix ถูก
Step 6: Cascade Check — ถ้า fix เปลี่ยน entity/actor/requirement ID/priority:
         - Grep old value ข้ามทุก BA doc
         - Update references
         - Document what cascaded
Step 7: Mark Complete
```

> **Safety Rule:** ถ้า fix จะ contradict BA doc อื่น → **STOP + report user** ห้าม silently create new contradiction

### 2.2 Handle Rejected Claims

แต่ละ rejected claim → เตรียม justification ละเอียด:

- Cite specific section ที่ address reviewer concern
- Quote exact text ที่ reviewer miss/misread
- อธิบายว่าทำไม current content ถูก/พอ
- ถ้า reviewer miss context → ชี้ว่า context อยู่ที่ไหน

---

## Phase 3: Write Rebuttal

### 3.1 Create Rebuttal File

Write `docs/ba/claim-review-and-rebuttal/rebuttal-round-XX.md`:

```markdown
# BA Rebuttal Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Claim Review** | `claim-review-XX.md` |
| **Date** | YYYY-MM-DD |
| **SKILLs** | business-analyst, brainstorming, research-engineer, documentation-templates |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | N |
| Partial | N |
| Rejected | N |

**Files modified:** `02-functional-requirements.md` (3 changes), `05-user-flows.md` (1 change), ...

---

## Claim Responses

### Claim XX.1: [Title]
**Verdict:** Accept
**Changes:**
- File: `docs/ba/02-functional-requirements.md` § Epic-03
- What changed: [ภาษาไทย specific]
- Evidence (new text): *"[quote updated text]"*

### Claim XX.2: [Title]
**Verdict:** Reject
**Justification:**
[ภาษาไทย พร้อม doc citation — quote exact text ที่ address concern]

### Claim XX.3: [Title]
**Verdict:** Partial
**Accepted part:** [ภาษาไทย — ส่วนที่ fix]
**Rejected part:** [ภาษาไทย — ส่วนที่ถูกแล้ว + evidence]
**Changes:**
- File: `[filename]` § [section]
- What changed: [description]

---

## Cascaded Changes

[List changes ใน BA docs ที่ **ไม่ได้** cite ใน claims โดยตรง — เกิดจาก cross-doc consistency fix]

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | N% | [ภาษาไทย] |
| Critical Fixes | N | [ภาษาไทย] |
| Net Improvement | [ภาษาไทย] | |
| Remaining Gaps | N items | [ภาษาไทย] |

## Recommendation

- [ ] ✅ **Ready for Architecture Handoff** — all Critical/Major claims resolved
- [ ] 🔁 **Request Re-Review** — significant changes, reviewer should verify
- [ ] ⛔ **Needs Stakeholder Input** — deferred items block further progress
```

---

## Phase 4: Final Consistency Sweep

หลัง fix ทั้งหมด → parallel checks:

1. **Entity consistency** — Grep key entity names ข้าม modified BA docs
2. **Actor consistency** — Grep stakeholder/actor names → verify match
3. **Priority consistency** — Grep MoSCoW priority references
4. **New contradictions** — compare modified sections กับ related BA docs
5. **Diagram alignment** — ถ้า user flow descriptions เปลี่ยน → verify Mermaid match
6. **Requirement traceability** — verify ไม่มี orphan / broken ref ใหม่
7. **Language Rule compliance (MANDATORY)** — re-scan modified sections:
   - ถ้า fix เพิ่ม/แก้ไข rationale / user story Why / business rule description → ต้องเป็น **ไทย** (code-switched กับ English tech term)
   - ถ้า fix แค่ edit ข้อความ English ที่ violate LANGUAGE RULE อยู่เดิม → **rewrite ให้ bilingual ด้วย** ห้าม preserve violation
   - ถ้าเจอ H2/H3 section ที่ opener ไม่มี Thai narrative (จาก cascade grep) → เพิ่ม Thai lead-in + flag ใน "Cascaded Changes"
   - ถ้า actor/entity ถูกแปลเป็นไทย (เช่น "ผู้ดูแลระบบ" แทน `Admin`) → แก้เป็น English ตาม LANGUAGE RULE
   - Mechanical check: `grep -o '[ก-๏]' <file> | wc -l` เทียบกับ total char count — ratio ≥ 40% ถือว่า pass
   - Benchmark: `ba-requirements-prompt.md § LANGUAGE RULE`

ถ้าเจอ inconsistency จาก fix:
- Fix ทันที
- เพิ่มใน **"Cascaded Changes"** section ของ rebuttal

---

## Phase 5: Report (ภาษาไทย)

- Claims processed: N accepted / N rejected / N partial
- List of BA files modified (พร้อม change count per file)
- Path ของ new `rebuttal-round-XX.md`
- Cross-doc issues ที่เจอ + resolve ใน consistency sweep
- Highlight claims ที่ cascade หลาย docs
- Recommendation: ready for Architecture handoff / needs another review cycle
