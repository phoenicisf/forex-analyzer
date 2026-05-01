---
description: Audit the implementation plan and generate a structured Claim Review file
---

# Workflow: Generate Implementation Plan Claim Review

> **Output:** `docs/state/impl-plan-claim-review-and-rebuttal/claim-review-XX.md` — scan-first review with Top-3 HALT highlights
> **Defect class motivating this workflow:** real-project audit (Shark CMS, 2026-04) ran `/impl-plan` once with no review pair → 53 closed tasks across two phases → 9 functional defects + 11 IMPL-FIX-* recovery tasks. Other Phase 1 deliverables (BA/SD/UX/TD) all pass through review/rebuttal pairs; impl-plan did not. This workflow closes that gap.

**Target:** `{{input}}` — usually `all` or `docs/state/impl-plan.md` (single-file plan; some projects may split per-sprint)

---

## Phase 0: Onboarding (อ่านทันที)

1. `CLAUDE.md` — project rules, tech stack, architecture constraints (especially § Glossary for Option C vocabulary)
2. `.agents/skills/andm-impl-plan-reviewer/SKILL.md` — **persona definition** (activate full Phase 0-4 process)
3. `.agents/skills/andm-impl-planner/SKILL.md` — planner quality benchmark (what the plan was supposed to deliver)
4. `.agents/skills/andm-impl-engineer/SKILL.md` § Empirical Closure Discipline — closure rules + forbidden patterns the plan must not pre-author
5. `.agents/workflows/impl-plan.md` — workflow contract the planner ran through
6. `docs/state/overview.md` — derived state view (for reconciliation check)
7. `docs/state/impl-plan.md` — **the artifact under review**
8. `docs/state/deferred-ac-registry.md` (if exists) — registry for reconciliation check
9. `docs/design-docs/07-future-evolution.md` — Evolution Sequence (verify honor)
10. `docs/design-docs/08-product-breakdown.md` — Phase Hints + Per-Task Metadata (verify honor/diverge audit trail)
11. `docs/state/impl-plan-claim-review-and-rebuttal/` — previous rounds (avoid duplicate findings)

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Glob `docs/state/impl-plan-claim-review-and-rebuttal/` หา `claim-review-XX.md` สูงสุด → new round = สูงสุด + 1 (เริ่ม 01 ถ้าไม่มี). ถ้า directory ไม่มี → create พร้อม first review.

### 1.2 Load Context (parallel reads)

ทำพร้อมกัน:

1. **Plan benchmark** — `.agents/skills/andm-impl-planner/SKILL.md`
2. **Engineer closure rules** — `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline + Forbidden Closure Patterns`
3. **Target plan** — `docs/state/impl-plan.md` (ละเอียดทุก task + Phase Gate + Phasing Rationale + audit trail)
4. **State files for reconciliation** — `docs/state/overview.md` + `docs/state/deferred-ac-registry.md` + glob `docs/state/_session-handoff/*` (latest 3-5)
5. **SD hint sources** — `docs/design-docs/07-future-evolution.md` + `docs/design-docs/08-product-breakdown.md` (re-extract Evolution Sequence + Phase Hints + Per-Task Metadata to compare against plan's audit trail)
6. **TD detail specs** — `docs/technical-design/02-backend-design.md`, `03-frontend-design.md`, `04-database-design.md` (verify task scope grounded)
7. **API contracts** — `docs/api-specs/*.yaml` (verify task input references)
8. **BA MoSCoW source** — `docs/ba/02-functional-requirements.md` + `docs/ba/03-non-functional-requirements.md` (verify MoSCoW rule applied correctly)
9. **ADRs** — `docs/adr/` (verify Evolution Sequence ADR backing)
10. **Previous rounds** — 2-3 รอบล่าสุด เพื่อ avoid duplicate + รู้ recurring weakness

> **Anti-Duplication Rule:** ถ้า issue raise รอบก่อน **และ** มี fix ใน rebuttal → **ห้าม raise ซ้ำ** เว้นแต่ fix ไม่สมบูรณ์

### 1.3 Engage Persona

Follow `andm-impl-plan-reviewer` จาก `.agents/skills/andm-impl-plan-reviewer/SKILL.md` — activate full Phase 0-4 process

---

## Phase 2: Generate Claims

### 2.1 Systematic Scan — 10 Implementation Plan Attack Vectors

Walk ผ่าน 10 dimensions (full list ใน `.agents/skills/andm-impl-plan-reviewer/SKILL.md` Phase 1).
**Summary (quick reference):**

| # | Dimension | Check |
|---|-----------|-------|
| 1 | Phase Shape & Phasing Rationale | Rationale 1-paragraph มี MoSCoW/risk/dep/value? Phase % targets reasonable? |
| 2 | SD Hint Alignment Audit Trail | E1..EN labeled (✅/⚠️/🔴)? Phase Hints labeled (✅/⚠️/◻️)? **Silent Copy** (H>5 ∧ A==H ∧ D==0) without confirmation? |
| 3 | Task Decomposition & Sizing | ทุก task มี Phase + scope tag + size? L/XL cross-layer decomposed per-slice? Per-layer with all 3 exception conditions? |
| 4 | AC — Dual-Track Compliance | Network/UI/persistence/async/security task มี ≥1 E-AC + `[evidence-kind]`? **Forbidden closure pre-authoring** ("deferred to operator-runtime" etc.) ใน AC text? |
| 5 | Phase Gates — Testable Exit | 7 rows ครบ (Structural/Empirical Demo/Live-stack health/Code review/NFR/Deferred drain/Docs)? Testable text ไม่ generic? Mid-Phase Audit Log initialized? |
| 6 | Deferred-AC Registry Init | Registry initialized? Schema ครบ? Active rows มี owner + expiry ≤14d + risk? **Hard ban**: `[x]` AC + closure note "deferred" |
| 7 | Cross-Phase Dependency | Forward reference (P_n depends on P_m, m>n) → CRITICAL. Mermaid graphs match Phase × Size matrix? |
| 8 | State-File Consistency | `impl-plan.md` ↔ `overview.md` ↔ `deferred-ac-registry.md` divergence? Handoff "next suggested" pointer dangling? |
| 9 | Schedule-Leakage (SD Boundary) | SD-hint sections copied INTO plan ห้ามมี sprint/week/Q1-Q4/month-year — leak → route MEDIUM กลับ `/sd-review`. Planner's own schedule content concrete + testable? |
| 10 | Readability — Reader Empathy | Narrative top section (Phase Status / Open Risks / Next Best Action / Last Updated)? TL;DR 3-5 บรรทัด? Phasing Rationale ไทย? Mermaid narrative? Stakeholder skim test pass? |

แต่ละ dimension ต้อง **raise finding** หรือ **note ว่า check แล้วไม่เจอปัญหา**
**ไม่มี artificial cap**

### 2.2 Mechanical Pre-Scans (run ก่อน manual review)

#### 2.2.1 Forbidden Closure Pattern Grep

```bash
grep -nE 'deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred' docs/state/impl-plan.md
```

ทุก hit บน `[x]`-marked AC line = **CRITICAL** (Dimension #4). ทุก hit บน AC text (regardless of `[x]`) = **CRITICAL** (planner pre-authoring violation).

#### 2.2.2 Forward Reference Detection

Walk every task's `**Dependencies**:` field. หา dependency จาก phase X → phase Y where Y > X → **CRITICAL** (Dimension #7).

#### 2.2.3 Silent Copy Detector

Read SD Hint Alignment audit trail. Compute:

```
H = total tasks with non-empty "SD Hint Phase"
A = tasks classified ✅ Honored / Align
D = tasks classified ⚠️ Diverged
V = tasks classified 🔴 Violation
N = tasks classified ◻️ No hint
```

ถ้า `H > 5 AND A == H AND D == 0 AND V == 0` AND plan ไม่มี explicit confirmation note ("planner ran rules independently and genuinely agreed") → **MEDIUM** finding (Dimension #2). ถ้า plan มี confirmation note → note ใน Dimension #2 ว่า trigger หายเพราะ confirmation present.

#### 2.2.4 State Reconciliation

ตรวจ 3 ทาง:

```
A. impl-plan.md ↔ overview.md
   - ทุก phase status ใน overview match impl-plan Phase Gate state ไหม?
   - ทุก task count ใน overview match plan task count ไหม?

B. impl-plan.md ↔ deferred-ac-registry.md
   - ทุก Active row ใน registry — task ID exists ใน plan ไหม?
   - ทุก task ใน plan ที่มี [x] AC พร้อม "deferred" closure note — registry มี Resolved row ตรงกันไหม?
     (ถ้าไม่มี = forbidden pattern + missing registry entry → CRITICAL)

C. impl-plan.md ↔ _session-handoff/
   - "next suggested task" ใน handoff ล่าสุด — task ID exists + ready ใน plan ไหม?
   - Evidence artifact paths cited ใน plan AC `[x]` lines — ไฟล์ exists จริงไหม?
```

ทุก divergence = **HIGH** หรือ **CRITICAL** (Dimension #8) ขึ้นกับ scope.

### 2.3 Cross-Document Consistency

Grep ข้าม `docs/state/*.md` + `docs/design-docs/07-future-evolution.md` + `docs/design-docs/08-product-breakdown.md`:

| Check | How |
|-------|-----|
| Task ID consistency | Grep IMPL-XXX ข้าม impl-plan + overview + handoffs + 08-product-breakdown |
| Evolution step references | ทุก E-step citation ใน Phasing Rationale → grep หา step ใน 07-future-evolution.md |
| Phase Hint references | ทุก Phase Hint citation → grep หา hint ใน 08-product-breakdown.md |
| Task scope grounding | Task ที่อ้าง TD section หรือ api-spec — ตรวจ section/spec มีอยู่จริง |
| ADR backing | Evolution Sequence ที่ cite ADR-XXX — ตรวจ ADR มีอยู่ + status ไม่ใช่ Superseded |

Contradictions = separate claims

### 2.4 Draft Claims

เขียน **ภาษาไทย** ด้วย ruthless reviewer tone

```markdown
### Claim XX.N: [ICON] [SEVERITY] — [Title]

**Location:** `[file]` § [section or task ID]

**Problem:**
[2-4 ประโยค — quote exact text]

**Why this matters:**
[Real-world impact: "Engineer จะ X เพราะ Y" / "`/next` จะรายงาน Z ผิด เพราะ W"]

**Minimum acceptable fix:**
[Specific — ไม่ใช่ "improve AC" → ระบุ task ID, what evidence-kind, what assertion text]

**Effort:** Low / Medium / High
```

**Severity** (ตาม SKILL.md):

| Icon | Level | When |
|------|-------|------|
| 🔴 | **CRITICAL** | Engineer ทำตามไม่ได้ / pre-authored closure violation / phase boundary violation / Evolution Sequence violation |
| 🟠 | **HIGH** | Plan executable แต่จะปิดด้วย structural-only / sizing wrong → real downstream cost |
| 🟡 | **MEDIUM** | Sub-optimal; rework at Phase Gate or Mid-Phase Audit |
| 🔵 | **LOW** | Best practice violation, future risk, polish |

### 2.5 Quality Gate (Self-Review Before Output)

- [ ] ทุก claim cite specific location + quoted text or task ID
- [ ] ไม่มี claim ซ้ำกับ fix ใน rebuttal ก่อน
- [ ] Severity match matrix (ไม่ใช่ guess)
- [ ] ทุก claim มี specific "Minimum acceptable fix"
- [ ] 10 dimensions scan ครบ (skip ต้อง note reason)
- [ ] **Mechanical pre-scans (2.2.1–2.2.4) ได้ run** + result บันทึกใน At-a-Glance section
- [ ] Total findings ≥ 3 (ถ้าน้อยกว่า = ตรวจอีกรอบ)
- [ ] **Claim review file เองเขียนเป็น bilingual** — Thai narrative + English technical terms

---

## Phase 3: Output

### 3.1 Write File

Write to `docs/state/impl-plan-claim-review-and-rebuttal/claim-review-XX.md`:

```markdown
# Implementation Plan Claim Review Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | YYYY-MM-DD |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |

---

## 📊 At-a-Glance

**Total findings:** N (🔴 CRITICAL N / 🟠 HIGH N / 🟡 MEDIUM N / 🔵 LOW N)

**Mechanical pre-scans:**
- Forbidden closure patterns: N hits (CRITICAL count: M)
- Forward reference (P_n → P_m, m>n): N edges
- Silent Copy Detector: H=N, A=N, D=N, V=N, N=N → triggered? Y/N (confirmation note present? Y/N)
- State reconciliation: impl-plan ↔ overview / registry / handoff — N divergences

### Top 3 to Fix First
1. **Claim XX.A** 🔴 — [one-line title] — `[location]`
2. **Claim XX.B** 🔴 — [one-line title] — `[location]`
3. **Claim XX.C** 🟠 — [one-line title] — `[location]`

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL หรือ HIGH → run `/impl-plan-rebuttal claim-review-XX.md`
- [ ] ⛔ **Immediate Attention** — fundamental phasing/AC flaw ที่ block engineer execution

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 3 | Task Decomposition & Sizing | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 4 | AC — Dual-Track Compliance | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 5 | Phase Gates — Testable Exit | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 6 | Deferred-AC Registry Init | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 7 | Cross-Phase Dependency | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 8 | State-File Consistency | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 10 | Readability — Reader Empathy | ✅ Pass / ⚠️ Finding XX.N | [brief note] |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

[...]

### 🟠 HIGH

[...]

### 🟡 MEDIUM

[...]

### 🔵 LOW

[...]

---

## Cross-Document Issues

[Contradictions จาก Phase 2.3 — หรือ "ไม่พบ contradictions"]

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| XX.1 | 🔴 CRITICAL | [title] | `impl-plan.md` § P3 IMPL-019 | Medium |
| [...] |
```

### 3.2 Report to User (ภาษาไทย)

- Round number + target plan file
- Findings count per severity
- Mechanical pre-scan results (4 lines)
- File path ของ claim review
- **Top 3 findings** (highlight)
- Recommendation: proceed to rebuttal หรือ needs immediate attention
