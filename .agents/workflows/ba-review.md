---
description: Audit BA deliverables and generate a structured Claim Review file
---

# Workflow: Generate BA Claim Review

> **Output:** `docs/ba/claim-review-and-rebuttal/claim-review-XX.md` — scan-first review พร้อม Top-3 HALT highlights เพื่อให้คน review เร็วได้

**Target:** `{{input}}` (ไฟล์เดียว เช่น `02-functional-requirements.md` หรือ `"all"` สำหรับ audit ทั้ง package)

---

## Phase 0: Onboarding (อ่านไฟล์เหล่านี้ทันที)

1. `CLAUDE.md` — project rules, architecture constraints
2. `.agents/skills/andm-ba-reviewer/SKILL.md` — **persona definition** (activate full Phase 0-4 process)
3. `.agents/prompt-templates/ba-requirements-prompt.md` — BA quality benchmark
4. `docs/state/overview.md` — project phase status
5. `docs/ba/` — existing BA deliverables ที่จะ review
6. `docs/ba/claim-review-and-rebuttal/` — previous rounds (เพื่อ avoid duplicate)

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Glob `docs/ba/claim-review-and-rebuttal/` หา `claim-review-XX.md` ที่ number สูงสุด → new round = สูงสุด + 1 (เริ่ม 01 ถ้ายังไม่มี)

### 1.2 Load Context (parallel reads)

ทำพร้อมกัน:

1. **BA benchmark** — `.agents/prompt-templates/ba-requirements-prompt.md`
2. **Target doc(s)** — อ่านละเอียด; ถ้า `{{input}}` = "all" → อ่าน `docs/ba/01-*.md` ถึง `06-*.md`
3. **Related BA docs** — identify dependencies:
   - target `02-functional-requirements.md` → อ่าน `01-project-brief.md` (goals), `03-non-functional-requirements.md` (NFR cross-check), `05-user-flows.md` (flow coverage)
   - target `04-business-rules.md` → อ่าน `02-functional-requirements.md` (rule↔story alignment)
   - (v1.2: BA `06-handoff-to-architecture.md` removed — open questions/risks live ใน 02-05 ตาม domain. Reviewer ตรวจ open questions ชิ้นอยู่ใน doc ที่ถูกต้องตาม domain)
   - Grep cross-references (`see 0X-`, `ref:`, `described in`, `ดูเพิ่มเติมที่`) เพื่อหา deps เพิ่ม
4. **Previous rounds** — อ่าน 2-3 รอบล่าสุด (`claim-review-XX.md` + `rebuttal-round-XX.md`) เพื่อ:
   - Avoid duplicate findings
   - รู้ pattern ของ recurring weakness

> **Anti-Duplication Rule:** ถ้า issue ถูก raise รอบก่อน **และ** มี fix ใน rebuttal → **ห้าม raise ซ้ำ** เว้นแต่ fix ไม่สมบูรณ์ (ระบุว่าไม่สมบูรณ์ยังไง)

### 1.3 Engage Persona

Follow `andm-ba-reviewer` persona จาก `.agents/skills/andm-ba-reviewer/SKILL.md` — activate full Phase 0-4 process

---

## Phase 2: Generate Claims

### 2.1 Systematic Scan — 19 BA Attack Vectors

Walk ผ่าน 19 categories ต่อ target (full list ใน `.agents/skills/andm-ba-reviewer/SKILL.md` Phase 1).
**Summary (quick reference):**

| # | Category | Check |
|---|----------|-------|
| 1 | Problem Statement | ชัด + วัดได้ + ตอบ "ทำไมต้องมีระบบนี้"? |
| 2 | Success Metrics | KPIs วัดจริงได้ + มี baseline? |
| 3 | Scope Boundaries | In/Out ชัด + ไม่มี scope creep ซ่อน? |
| 4 | User Story Quality | format "As a...I want...so that"; actor ครบ (external systems, schedulers, admins)? |
| 5 | Acceptance Criteria | Given/When/Then ที่ testable? |
| 6 | MoSCoW Prioritization | FR ทุกข้อมี priority ที่สมเหตุสมผล? |
| 7 | NFR Measurability | "เร็ว" ไม่ผ่าน — ต้องเป็น "<200ms p95"? |
| 8 | NFR Completeness | ครบ Performance, Security, Availability, Usability, Scalability? |
| 9 | Business Rules | มี decision table สำหรับ complex logic + edge case? |
| 10 | User Flow Coverage | Mermaid ≥ 1 + happy/alternative/error paths? |
| 11 | Traceability | trace กลับ business goal ได้ทุกข้อ? มี orphan? |
| 12 | Assumption Marking | ⚠️ ครบ + อยู่ใน open questions? |
| 13 | Tech-Agnostic | อธิบาย WHAT ไม่ใช่ HOW; ไม่มี technical hints ใน BA doc ไหนเลย? (v1.2: tech decisions เป็นของ Architect; BA raise เฉพาะ open questions ใน relevant doc 02-05) |
| 14 | Cross-Doc Consistency | entity/actor/flow names ตรงกันข้ามเอกสาร? |
| 15 | Edge Cases | boundary + failure scenarios ครบ? |
| 16 | Open Questions Distribution | open questions/risks อยู่ใน relevant doc ตาม domain (FR→02, NFR→03, rule→04, flow→05) ไหม? actionable + NO tech hints? (v1.2: was doc 06 — dropped) |
| 17 | Ambiguity | developer 2 คนอ่านแล้วเข้าใจเหมือนกัน? |
| 18 | Conflict Detection | requirements ขัดแย้งกัน + priority ไม่สอดคล้อง? |
| 19 | **Readability / Reader-Empathy** | ทุก doc มี **TL;DR**? ทุก requirement/story/rule/NFR มี `**Why:**` line? ศัพท์โดเมน + acronym define-on-first-use หรือใน `§ Glossary`? Wall-of-text > 10 บรรทัด ไม่มี structure? PM/Architect ที่ไม่ได้อยู่ meeting อ่านเข้าใจโดยไม่ต้องถาม Slack? → Benchmark: `ba-requirements-prompt.md § Readability Contract` |
| 20 | **Language Rule Compliance** | **Target BA doc** bilingual ถูกไหม? TL;DR + ทุก H2/H3 opener มี Thai narrative? Prose Thai coverage ≥ 40%? User story/business rule rationale เป็นไทย? Actor/entity ชื่อยังเป็น English (ไม่แปล)? → Benchmark: `ba-requirements-prompt.md § LANGUAGE RULE`. ถ้า English-only ทั้งไฟล์ → raise เป็น HIGH (1 ไฟล์) หรือ CRITICAL (หลายไฟล์ / ทั้ง package); English TL;DR หรือ section บางส่วน → MEDIUM; แปล actor/entity เป็นไทย → MEDIUM |

แต่ละ category ต้อง **raise finding** หรือ **note explicitly ว่า check แล้วไม่เจอปัญหา**.
**ไม่มี artificial cap** ของจำนวน findings — raise เท่าที่เจอ

**Language scan (mechanical)** ก่อน category 20:

```bash
# Estimate Thai coverage (rough): count Thai chars vs total non-code chars
for f in docs/ba/0*.md; do
  total=$(sed 's/```[^`]*```//g' "$f" | wc -m)
  thai=$(sed 's/```[^`]*```//g' "$f" | grep -o '[ก-๏]' | wc -l)
  echo "$f: thai=$thai total=$total ratio=$(awk "BEGIN {print $thai/$total*100}")%"
done
```

- Ratio < 20% → CRITICAL (ไฟล์ English-only เกือบทั้ง doc)
- Ratio 20-40% → HIGH (ขาด Thai narrative ส่วนสำคัญ)
- Ratio ≥ 40% → ตรวจ qualitative (TL;DR มี Thai? Section openers มี Thai? User story rationale ไทย?)
- ตรวจอีกว่า actor/entity ถูกแปลเป็นไทยหรือไม่ (เช่น "ผู้ดูแลระบบ" แทน `Admin`) → MEDIUM

### 2.2 Cross-Document Consistency

Grep ข้าม `docs/ba/*.md` ทั้งหมด:

| Check | How |
|-------|-----|
| Actor/stakeholder names | Grep actor names จาก target ข้ามทุก BA doc |
| Entity names | Grep entity names ข้าม user stories + flows + business rules |
| Priority alignment | MoSCoW ใน FR doc match priority hints ใน doc อื่น |
| Requirement IDs | Grep requirement references — check existence + ไม่มี orphan |
| Scope alignment | Out-of-Scope items ใน doc 01 ไม่ accidentally include ใน doc อื่น |

Contradictions = separate claims

### 2.3 Draft Claims

เขียนเป็น **ภาษาไทย** ด้วย adversarial reviewer tone (ดู SKILL.md)

```markdown
### Claim XX.N: [ICON] [SEVERITY] — [Title ภาษาไทยสั้นๆ]

**Location:** `[file]` § [section name]

**Problem:**
[2-4 ประโยค — quote exact text ที่เป็นปัญหา จาก BA doc]

**Why this matters:**
[Real-world impact: "Architect จะ X ไม่ได้เพราะ Y" / "Dev 2 คนจะตีความต่างกัน เพราะ Z"]

**Minimum acceptable fix:**
[Specific action — ไม่ใช่ vague "ปรับปรุงให้ชัดเจนขึ้น"]

**Effort:** Low / Medium / High
```

**Severity** (ตาม SKILL.md):

| Icon | Level | When |
|------|-------|------|
| 🔴 | **CRITICAL** | Blocks Architecture handoff — missing core requirement, contradictory business rules |
| 🟠 | **HIGH** | Significantly impacts quality — vague NFR, untestable acceptance criteria, missing key actor, doc ทั้ง section อ่านไม่รู้เรื่อง |
| 🟡 | **MEDIUM** | Incomplete at scale — missing edge case, workaround exists, ขาด TL;DR/Why เป็นบางจุด |
| 🔵 | **LOW** | Best practice violation — formatting, future risk, readability glitch เล็กน้อย |

### 2.4 Quality Gate (Self-Review Before Output)

- [ ] ทุก claim cite specific location + quoted text
- [ ] ไม่มี claim ซ้ำกับ rebuttal ที่ fix แล้ว
- [ ] Severity match criteria (ไม่ใช่ guess)
- [ ] ทุก claim มี specific, actionable "Minimum acceptable fix"
- [ ] 20 categories scan ครบ (skip ต้อง note reason)
- [ ] **Language scan (category 20) ได้ run** — ถ้า target BA doc English-only หรือ prose Thai < 40% → raise เป็น finding
- [ ] Total findings ≥ 3 (ถ้าน้อยกว่านี้ = กลับไปตรวจอีกรอบ)
- [ ] **Claim review file เองเขียนเป็น bilingual** — Thai narrative + English technical terms (ไม่ใช่แค่ technical terms เป็น English แล้ว claim prose เป็นไทย)

---

## Phase 3: Output

### 3.1 Write File

Write to `docs/ba/claim-review-and-rebuttal/claim-review-XX.md`:

```markdown
# BA Claim Review Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target** | `[filename or "all"]` |
| **Date** | YYYY-MM-DD |
| **Reviewer** | BA Reviewer (Adversarial Consultant) |
| **SKILLs** | business-analyst, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** N ({{🔴 CRITICAL N}} / {{🟠 HIGH N}} / {{🟡 MEDIUM N}} / {{🔵 LOW N}})

### Top 3 to Fix First
1. **Claim XX.A** 🔴 — [one-line title] — `[file]`
2. **Claim XX.B** 🔴 — [one-line title] — `[file]`
3. **Claim XX.C** 🟠 — [one-line title] — `[file]`

### Verdict
- [ ] ✅ **Ready for Architecture Handoff** — ไม่มี CRITICAL/HIGH หรือ handoff-blocking findings
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL หรือ HIGH → run `/ba-rebuttal claim-review-XX.md`
- [ ] ⛔ **Immediate Attention** — contradictory requirements ที่ block design

---

## BA Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Problem Statement | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 2 | Success Metrics | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| [... ครบทั้ง 20 categories (19 เดิม + Language Rule Compliance อันที่ 20) ...] |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

[Claim XX.1, XX.2, ... ถ้ามี]

### 🟠 HIGH

[...]

### 🟡 MEDIUM

[...]

### 🔵 LOW

[...]

---

## Cross-Document Issues

[Contradictions จาก Phase 2.2 — ถ้าไม่มี เขียน "ไม่พบ contradictions ข้าม BA docs"]

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| XX.1 | 🔴 CRITICAL | [title] | `02-functional-requirements.md` § Epic-03 | Medium |
| XX.2 | 🟠 HIGH | [title] | `03-non-functional-requirements.md` | Low |
| [...] |
```

### 3.2 Report to User (ภาษาไทย)

สรุปสั้นใน chat:

- Round number + target doc
- Findings count per severity
- File path ของ claim review ที่ generate
- **Top 3 findings** (highlight)
- Recommendation: proceed to rebuttal หรือ needs immediate attention
