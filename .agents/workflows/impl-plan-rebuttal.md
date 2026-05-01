---
description: Analyze, implement fixes, and write rebuttal for an Implementation Plan Claim Review round
---

# Workflow: Process Implementation Plan Claim Review

> **Output:** `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-XX.md` + updated `docs/state/impl-plan.md` (and possibly `deferred-ac-registry.md` / `overview.md`)
> **HALT point:** หลัง Phase 1 (Analysis) — นำเสนอแผนให้ user approve ก่อนเริ่มแก้

**Claim review file:** `{{input}}`

---

## Phase 0: Onboarding

1. `CLAUDE.md` — project rules, tech stack, architecture constraints (especially § Glossary)
2. `.agents/skills/andm-impl-plan-defender/SKILL.md` — **persona + 7-step execution protocol**
3. `.agents/skills/andm-impl-planner/SKILL.md` — planner quality benchmark (your primary reference)
4. `.agents/skills/andm-impl-engineer/SKILL.md` § Empirical Closure Discipline — engineer-side closure rules + forbidden patterns (your fixes must not pre-author violations)
5. `.agents/workflows/impl-plan.md` — workflow contract you ran originally
6. `docs/state/overview.md` — derived state view
7. `docs/state/impl-plan.md` — **the artifact you own and will modify**
8. `docs/state/deferred-ac-registry.md` (if exists) — registry that you may need to seed/update
9. `docs/design-docs/07-future-evolution.md` + `08-product-breakdown.md` — SD hints (defend honor/diverge claims)
10. `docs/state/impl-plan-claim-review-and-rebuttal/` — previous rounds + rebuttals

---

## Phase 1: Analysis

### 1.1 Load Context (parallel)

1. **Claim review file** — อ่านละเอียดทุก claim
2. **Target plan** — `docs/state/impl-plan.md` (อ่านทั้งไฟล์ — section จะเปลี่ยนตอน fix)
3. **Sibling state files** — `docs/state/overview.md` + `docs/state/deferred-ac-registry.md` + glob `docs/state/_session-handoff/*` (ถ้า claim raise reconciliation issue)
4. **SD hint sources** — `docs/design-docs/07-future-evolution.md` + `docs/design-docs/08-product-breakdown.md` (defend Silent Copy / Honor / Diverge claims)
5. **TD detail specs** — `docs/technical-design/02/03/04` (defend task scope grounding)
6. **API contracts** — `docs/api-specs/*.yaml`
7. **BA MoSCoW source** — `docs/ba/02-functional-requirements.md` + `docs/ba/03-non-functional-requirements.md`
8. **ADRs** — `docs/adr/` (defend Evolution Sequence honor)
9. **Previous rebuttal** — ล่าสุด (ถ้ามี)

### 1.2 Engage Persona

Follow `andm-impl-plan-defender` — activate full persona rules + 7-step execution protocol จาก SKILL.md

### 1.3 Analyze Each Claim

แต่ละ claim → determine:

| Field | Description |
|-------|-------------|
| **Verdict** | `Accept` / `Reject` / `Partial` |
| **Rationale** | 1-sentence ทำไม — cite evidence จาก SD hint / ADR / planner SKILL |
| **Impact Scope** | `impl-plan.md` section / `deferred-ac-registry.md` row / `overview.md` count |
| **Cross-State Risk** | fix นี้จะ contradict overview.md หรือ registry หรือ handoff ไหม? |
| **Proposed Fix** | exact change — ไม่ใช่ vague "จะปรับปรุง AC" |

### 1.4 Risk Assessment

แต่ละ accept/partial claim → ตรวจ cross-state impact:

- ถ้า fix แก้ phase assignment → ตรวจ Phase × Size matrix + Phase Dependency Graph + SD Hint Alignment audit trail ที่ต้อง update
- ถ้า fix แก้ AC → ตรวจ task ID consistency กับ overview / handoff
- ถ้า fix initialize / update registry → ตรวจ Active rows มี owner + expiry + risk-if-missed
- ถ้า fix แก้ Phase Gate → ตรวจ Phase Gate Override Log entries ที่อ้าง gate text เดิม
- Flag fix ที่จะสร้าง forward reference ใหม่

### 1.5 Phase / Sequencing Claims (Option C Handling)

> **Reference:** `andm-impl-plan-defender/SKILL.md § Phase Gate / Phasing Decisions (Option C Handling)`

**Decision tree:**

```
Reviewer ขอ Evolution Sequence violation?
├── YES → Reject + escalate via /backtrack sd (HARD constraint, ไม่ใช่ rebuttal scope)
└── NO → Reviewer ขอ phase reassignment?
         ├── Forward reference detected → Accept + re-phase (always valid)
         ├── Per-Task Metadata missed → Accept + re-phase + cite metadata source
         ├── MoSCoW mismatch → Accept + re-phase + cite BA-02/03
         └── Soft Phase Hint divergence → re-read original divergence reason:
                  ├── Reason still stands → Reject + cite Phasing Rationale
                  └── Reviewer caught a gap → Accept + add stronger rationale
```

**Accept examples (valid requests):**
- *"IMPL-019 ขาด `[evidence-kind]` — AC text 'component renders' จะปิดด้วย Vitest snapshot pass"* → Accept + add `[gui-capture]` with concrete assertion
- *"`[x]` AC พร้อม 'deferred to operator-runtime' — Dimension #11 violation"* → Accept + split task: S-AC subtask close now; E-AC subtask register in deferred-ac-registry
- *"P3 IMPL-008 depends on P4 IMPL-025 — forward reference"* → Accept + re-phase (move IMPL-025 to P3 OR extract Foundation Stub)

**Reject examples:**
- *"E2 ordering wrong — should swap E1/E2"* → Reject + escalate `/backtrack sd` (Evolution Sequence is HARD constraint backed by ADR; impl-plan rebuttal cannot edit upstream architecture)
- *"IMPL-005 should be P3 not P1"* (after divergence with documented TD-04 reason) → Reject + cite Phasing Rationale: *"TD-04 revealed migration must happen first"*

**Strip-and-fix examples:**
- *"AC text มี 'deferred per IMPL-049 precedent'"* → Accept + rewrite AC + register in deferred-ac-registry (no forbidden synonym substitution allowed)
- *"Phase Gate row 'all tests pass' — generic"* → Accept + rewrite testable: *"`npm run test:e2e -- smoke` exits 0 with all 23 specs reported"*

---

### 1.6 HALT — Present Analysis to User

แสดง summary ใน chat (ภาษาไทย, scan-first):

```markdown
## 🛑 HALT — Rebuttal Plan for Round XX

**Total claims:** N (🔴 N / 🟠 N / 🟡 N / 🔵 N)
**Verdicts:** N Accept · N Partial · N Reject

### Will Modify (Accept + Partial)

| # | Severity | Title | Files to Modify | Cross-State Risk |
|---|----------|-------|-----------------|------------------|
| XX.1 | 🔴 CRITICAL | [title] | `impl-plan.md § P3 IMPL-019`, `deferred-ac-registry.md § Active` | ⚠️ overview.md task-count update |
| XX.2 | 🟠 HIGH | [title] | `impl-plan.md § Phase Gate P2` | ไม่มี |

**Verdict rationale (1 บรรทัดต่อ claim):**
- **XX.1 Accept** — IMPL-019 AC pre-authored "deferred to post-launch" บน `[x]`; จะ split + register in registry
- **XX.2 Accept** — Phase Gate P2 row generic "all tests pass"; จะแก้เป็น testable command + exit code

### Will Reject (Evidence Provided)

| # | Severity | Title | Reason (1-line) |
|---|----------|-------|-----------------|
| XX.3 | 🔵 LOW | [title] | Phasing Rationale § Diverged ระบุ TD-04 reason แล้ว — reviewer miss |

### Cross-State Risks Flagged

- Claim XX.1: split IMPL-019 → IMPL-019a (S-AC close now) + IMPL-019b (E-AC) → registry Active row + Phase × Size matrix +1 in M column + Phase Dependency Graph re-render
- Claim XX.5: re-phase IMPL-008 P3 → P2 → walk dep edges, no new forward reference

### Will Escalate (Out of Rebuttal Scope)

- Claim XX.7 (Evolution Sequence E1/E2 swap request) — escalating via `/backtrack sd` (HARD constraint, upstream architecture)

### Questions for You (ถ้ามี)

1. Claim XX.1 — split IMPL-019 ตามที่เสนอ หรือ defer ทั้ง task พร้อม BLOCKED status?
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
Step 1: Announce — "Fixing Claim XX.3: HIGH — Phase Gate P2 row generic"
Step 2: Fresh Read — read target section ใน impl-plan.md (file may have changed from previous fixes)
Step 3: Cross-State Check — Grep references ใน overview.md / deferred-ac-registry.md / handoffs
Step 4: Apply Fix — Edit minimal + focused
Step 5: Verify — re-read ว่า fix ถูก
Step 6: Cascade Check — ถ้า fix เปลี่ยน phase assignment / task ID / AC text / Phase Gate row:
         - Update Phase × Size matrix counts
         - Update Phase Dependency Graph (Mermaid)
         - Update SD Hint Alignment audit trail (classification ✅ → ⚠️ if phase moved)
         - Update overview.md task-count + phase status
         - Update deferred-ac-registry Active/Resolved rows
         - Re-walk dependency edges to verify no new forward reference
         - Document what cascaded
Step 7: Mark Complete
```

> **Safety Rule:** ถ้า fix จะ contradict SD/TD/ADR/BA → **STOP + report user** ห้าม silently edit upstream artifact. Recommend `/backtrack sd|td|ba` instead.

> **Phase Boundary Rule:** ถ้า fix ย้าย task ระหว่าง phase → walk every dependency edge ของ task นั้น verify no new forward reference. ถ้าจะสร้าง new forward reference → STOP, surface to user, propose Foundation Stub pattern.

### 2.2 Handle Rejected Claims

แต่ละ rejected claim → เตรียม technical justification ละเอียด:

- Cite specific impl-plan section ที่ address concern
- Quote exact text จาก Phasing Rationale audit trail
- ถ้า reject เพราะ Evolution Sequence — cite ADR-XXX backing the E-step
- ถ้า reject เพราะ Phase Hint divergence อยู่แล้ว — quote SD Hint Alignment row + reason
- ถ้า reviewer miss SD hint context — ชี้ section ใน 07/08 ที่ relevant

### 2.3 Handle Escalated Claims

แต่ละ escalated claim (Evolution Sequence violation request, work-inventory expansion) → write referral note:

```markdown
### Claim XX.N: [Title]
**Verdict:** Escalate
**Reason:** [why this is out of impl-plan rebuttal scope]
**Recommended action:** /backtrack sd  (or /sd-rebuttal / /td-rebuttal / /ba-rebuttal)
**No change to impl-plan.md until upstream fix lands.**
```

---

## Phase 3: Write Rebuttal

### 3.1 Create Rebuttal File

Write `docs/state/impl-plan-claim-review-and-rebuttal/rebuttal-round-XX.md`:

```markdown
# Implementation Plan Rebuttal Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Claim Review** | `claim-review-XX.md` |
| **Date** | YYYY-MM-DD |
| **SKILLs** | andm-impl-plan-defender, code-review |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | N |
| Partial | N |
| Rejected | N |
| Escalated | N |

**Files modified:** `impl-plan.md` (X changes), `deferred-ac-registry.md` (Y changes), `overview.md` (Z changes)
**Tasks split:** [list, e.g., IMPL-019 → IMPL-019a + IMPL-019b]
**Phase reassignments:** [list, e.g., IMPL-008 P3 → P2]
**Registry rows added/closed:** N added, M moved to Resolved
**Escalations filed:** [list of /backtrack referrals]

---

## Claim Responses

### Claim XX.1: [Title]
**Verdict:** Accept
**Changes:**
- File: `docs/state/impl-plan.md` § P3 IMPL-019 → split into IMPL-019a + IMPL-019b
- File: `docs/state/deferred-ac-registry.md` § Active → new row for IMPL-019b
- What changed: [ภาษาไทย specific]
- Evidence (new text): *"[quote updated text]"*
- Cascaded: Phase × Size matrix M+1, Phase Dependency Graph re-rendered, overview.md task count 24 → 25

### Claim XX.2: [Title]
**Verdict:** Reject
**Justification:**
[ภาษาไทย พร้อม Phasing Rationale citation — quote exact text ที่ address concern]

### Claim XX.3: [Title]
**Verdict:** Partial
**Accepted part:** [ภาษาไทย — ส่วนที่ fix]
**Rejected part:** [ภาษาไทย — ส่วนที่ถูกแล้ว + evidence]
**Changes:**
- File: `[filename]` § [section]
- What changed: [description]

### Claim XX.7: [Title]
**Verdict:** Escalate
**Reason:** Evolution Sequence E1/E2 swap is HARD constraint backed by ADR-005. Out of impl-plan rebuttal scope.
**Recommended action:** /backtrack sd

---

## Cascaded Changes

[List changes ใน plan / sibling state files ที่ **ไม่ได้** cite ใน claims โดยตรง — รวม Phase × Size matrix updates, graph re-renders, registry seeding, overview reconciliation]

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | N% | [ภาษาไทย] |
| Critical Fixes | N | [ภาษาไทย] |
| Tasks Split | N | [ภาษาไทย] |
| Phase Reassignments | N | [ภาษาไทย] |
| Net Improvement | [ภาษาไทย] | |
| Escalations | N items | [ภาษาไทย] |
| Remaining Gaps | N items | [ภาษาไทย] |

## Recommendation

- [ ] ✅ **Ready for Implementation Execution** — all Critical/Major claims resolved
- [ ] 🔁 **Request Re-Review** — significant changes, reviewer should verify
- [ ] ⛔ **Needs Stakeholder Input** — escalated items block further progress
```

---

## Phase 4: Final Consistency Sweep

หลัง fix ทั้งหมด → parallel checks:

1. **Task ID consistency** — Grep IMPL-XXX ข้าม impl-plan + overview + handoffs + 08-product-breakdown
2. **Phase × Size matrix** — manually count tasks per phase × size column → match table
3. **Phase Dependency Graph (Mermaid)** — match Phase × Size matrix + dependency edges
4. **SD Hint Alignment audit trail** — count ✅ + ⚠️ + 🔴 + ◻️ → match total task count
5. **Forward reference scan** — walk every `**Dependencies**:` field, verify no P_n → P_m where m > n
6. **State reconciliation** — impl-plan ↔ overview ↔ deferred-ac-registry ↔ handoff "next suggested" pointer
7. **Forbidden closure pattern grep** — re-run grep from review § 2.2.1 → must return zero hits on `[x]` AC lines
8. **Registry hygiene** — every Active row มี owner + expiry ≤14d (absolute date) + risk-if-missed; every Resolved row มี artifact path
9. **Mermaid alignment** — Phase Gate count = phase count; node colors match phase classes
10. **Language Rule compliance** — re-scan modified sections:
    - Phasing Rationale paragraph เป็นไทย? Task description เป็นไทย? File paths + task IDs + phase labels คง English?
    - Mechanical: `grep -o '[ก-๏]' docs/state/impl-plan.md | wc -l` vs total → Thai narrative coverage in prose sections (excluding tables/code blocks)

ถ้าเจอ inconsistency จาก fix:
- Fix ทันที
- เพิ่มใน **"Cascaded Changes"** section

---

## Phase 5: Report (ภาษาไทย)

- Claims processed: N accepted / N rejected / N partial / N escalated
- List of files modified (พร้อม change count per file)
- Tasks split / re-phased / registry rows added
- Path ของ new `rebuttal-round-XX.md`
- Cross-state issues ที่เจอ + resolve
- Highlight claims ที่ cascade หลาย state files
- Escalations filed (with /backtrack target)
- Recommendation: ready for implementation execution / needs another review cycle / awaiting upstream backtrack
