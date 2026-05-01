---
description: Audit system design documents and generate a structured Claim Review file
---

# Workflow: Generate System Design Claim Review

> **Output:** `docs/design-docs/claim-review-and-rebuttal/claim-review-XX.md` — scan-first review พร้อม Top-3 HALT highlights

**Target:** `{{input}}` (ไฟล์เดียว เช่น `02-high-level-architecture.md` หรือ `"all"` สำหรับ audit ทั้ง 6 docs; v1.2: gaps 01/06 — merged into 02)

---

## Phase 0: Onboarding (อ่านทันที)

1. `CLAUDE.md` — project rules, tech stack, architecture constraints
2. `.agents/skills/andm-sd-reviewer/SKILL.md` — **persona definition** (activate full Phase 0-4 process)
3. `.agents/prompt-templates/system-design-master-prompt.md` — SD quality benchmark
4. `docs/state/overview.md`
5. `docs/design-docs/` — existing design documents (02-08; v1.2: gaps 01/06 — merged into 02)
6. `docs/adr/` — existing ADRs
7. `docs/api-specs/` — existing API contracts
8. `docs/design-docs/claim-review-and-rebuttal/` — previous rounds

---

## Phase 1: Preparation

### 1.1 Determine Round Number

Glob `docs/design-docs/claim-review-and-rebuttal/` หา `claim-review-XX.md` สูงสุด → new round = สูงสุด + 1 (เริ่ม 01 ถ้าไม่มี)

### 1.2 Load Context (parallel reads)

ทำพร้อมกัน:

1. **SD benchmark** — `.agents/prompt-templates/system-design-master-prompt.md`
2. **Target doc(s)** — อ่านละเอียด; ถ้า `{{input}}` = "all" → อ่าน `02-*.md` ถึง `08-*.md` (v1.2: gaps ที่ 01, 06)
3. **Related design docs** — identify dependencies:
   - target `03-deep-dive.md` → อ่าน `02-high-level-architecture.md` (incl. ADR Digest section), `05-security.md`
   - target `04-data-flow.md` → อ่าน `02`, `03`
   - target `05-security.md` → อ่าน `02`, `03`, `04`
   - target `08-product-breakdown.md` → อ่าน **ALL** 02-07 (ต้อง consistent ทั้ง design)
   - Grep cross-refs เพื่อหา deps เพิ่ม
4. **ADRs + API specs** — อ่านทุกไฟล์ใน `docs/adr/` + `docs/api-specs/` สำหรับ consistency check
5. **BA deliverables (v1.2)** — `docs/ba/02-functional-requirements.md` + `docs/ba/03-non-functional-requirements.md` + `docs/ba/05-user-flows.md` สำหรับ traceability + open questions/risks (BA-06 dropped — open questions live ใน 02-05 ตาม domain)
6. **Previous rounds** — 2-3 รอบล่าสุด เพื่อ avoid duplicate + รู้ recurring weakness

> **Anti-Duplication Rule:** ถ้า issue raise รอบก่อน **และ** มี fix ใน rebuttal → **ห้าม raise ซ้ำ** เว้นแต่ fix ไม่สมบูรณ์

### 1.3 Engage Persona

Follow `andm-sd-reviewer` จาก `.agents/skills/andm-sd-reviewer/SKILL.md` — activate full Phase 0-4 process

---

## Phase 2: Generate Claims

### 2.1 Systematic Scan — 21 System Design Attack Vectors

Walk ผ่าน 21 categories (full list ใน `.agents/skills/andm-sd-reviewer/SKILL.md` Phase 1).
**Summary (quick reference):**

| # | Category | Check |
|---|----------|-------|
| 1 | Architecture Style Justification | trade-off ≥ 2 options + เหตุผลเฉพาะกับระบบนี้ (ไม่ใช่ "industry standard")? |
| 2 | Service Boundaries | ชัดเจน + ไม่มี tight coupling ซ่อน? |
| 3 | Communication Patterns | sync/async เหมาะสม + ไม่มี SPOF? |
| 4 | Data Consistency | consistency model match requirement + มี compensation? |
| 5 | Database Design | DB choice มี justification + indexing strategy? |
| 6 | Caching Strategy | invalidation + TTL concrete + cache stampede mitigation? |
| 7 | Security Design | AuthN/AuthZ + STRIDE + OWASP + secret management? |
| 8 | Scalability | horizontal scaling + bottleneck identified + 10x plan? |
| 9 | Reliability & Fault Tolerance | circuit breaker + retry/backoff + fallback? |
| 10 | Performance Budgets | timing budget per step + p95/p99 match NFR? |
| 11 | Concrete Numbers | ทุกตัวเลขมี formula/derivation (ไม่ใช่ "configure as needed")? |
| 12 | API Contract Quality | contracts ครบ + schema ชัด + error codes? |
| 13 | Data Flow Completeness | sequence diagram + happy/error path + idempotency? |
| 14 | Observability | logging/metrics/tracing + alert thresholds มี concrete values? |
| 15 | ADR Quality | major decision มี ADR + Options/Decision/Consequences/Revisit ครบ? |
| 16 | Cross-Doc Consistency | names/numbers/tech ตรงกันข้ามเอกสาร? |
| 17 | Requirements Traceability | design trace กลับ BA requirement ได้? ไม่มี orphan? |
| 18 | Failure Modes | critical components มี failure analysis + RTO/RPO? |
| 19 | Future Evolution + Evolution Sequence | scaling triggers concrete? migration path ชัด? (ถ้ามี Evolution Sequence) ทุก step มี ADR-backed rationale? **ห้าม schedule leakage** |
| 20 | Work Inventory + Phase Hints | tasks sized + deps + service assignment? (ถ้ามี Phase Hints) label เป็น "Hints (Suggested)" + architectural rationale? **ห้าม schedule leakage** |
| 21 | **Readability / Reader-Empathy** | ทุก doc มี **TL;DR** 3-5 บรรทัด ตอบ "ปัญหา / architectural choice / key trade-off"? ทุก decision มี `**Why:**` ระบุ quality attribute/NFR (ไม่ใช่ "industry standard")? Pattern + acronym (Saga, CQRS, JWT, RBAC, HPA) define-on-first-use หรือ `§ Glossary`? Component/pattern section ขึ้นด้วย plain-language 1-sentence ก่อน dive technical? Mermaid diagram มี narrative (ก่อน + หลัง)? Tech Lead/BA/junior dev อ่านเข้าใจโดยไม่ต้องถาม Slack? → Benchmark: `system-design-master-prompt.md § Readability Contract` |
| 22 | **Language Rule Compliance** | **Target SD doc** bilingual ถูกไหม? TL;DR + ทุก H2/H3 opener มี Thai narrative? Prose Thai coverage ≥ 40%? Architectural decision/trade-off rationale เป็นไทย? Component/pattern section เริ่มด้วย Thai 1-sentence? Mermaid narrative ภาษาไทย? Tech term (Saga/CQRS/Redis/JWT) ยังเป็น English (ไม่ประแปล)? → Benchmark: `system-design-master-prompt.md § LANGUAGE RULE`. English-only ทั้ง doc → HIGH (1 ไฟล์) หรือ CRITICAL (ทั้ง design package); English TL;DR/section บางส่วน → MEDIUM |

แต่ละ category ต้อง **raise finding** หรือ **note ว่า check แล้วไม่เจอปัญหา**
**ไม่มี artificial cap**

**Language scan (mechanical)** ก่อน category 22:

```bash
# Estimate Thai coverage per doc (rough): Thai chars vs total non-code-block chars
for f in docs/design-docs/0*.md; do
  total=$(sed 's/```[^`]*```//g' "$f" | wc -m)
  thai=$(sed 's/```[^`]*```//g' "$f" | grep -o '[ก-๏]' | wc -l)
  echo "$f: thai=$thai total=$total ratio=$(awk "BEGIN {print $thai/$total*100}")%"
done
```

- Ratio < 20% → CRITICAL (design doc English-only)
- Ratio 20-40% → HIGH (ขาด Thai narrative ส่วนสำคัญ)
- Ratio ≥ 40% → ตรวจ qualitative (TL;DR ไทย? Section openers ไทย? Decision rationale ไทย? Mermaid narrative ไทย?)
- ตรวจอีกว่า tech term ถูกแปล (เช่น "ตัวกลาง queue" แทน `Redis queue`) → MEDIUM

### 2.2 Cross-Document Consistency

Grep ข้าม `docs/design-docs/*.md` + `docs/adr/*.md` + `docs/api-specs/*.yaml`:

| Check | How |
|-------|-----|
| Component names | Grep component names จาก target ข้ามทุก doc |
| Concrete numbers | Grep timeout, pool_size, rate_limit, TTL — flag mismatches |
| Architecture alignment | data flow descriptions vs `02-high-level-architecture.md` diagrams |
| Tech stack references | tech names match ข้าม docs + ADRs |
| ADR alignment | design choices match ADR decisions |
| NFR alignment | performance targets match `docs/ba/03-non-functional-requirements.md` |

Contradictions = separate claims

### 2.3 Schedule-Leakage Quick Check (Option C)

> **No-Hints Pass-Through:** ถ้าไม่มี Evolution Sequence และไม่มี Phase Hints → record *"No hints present"* + proceed 2.4. **Missing ≠ finding**

**Mechanical grep one-liner** (run ก่อน manual scan):

```bash
grep -nE '\b(Sprint [0-9]+|Week [0-9]+|Q[1-4] 202[0-9]|(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* 202[0-9]|[0-9]+ dev[- ]weeks?|[0-9]+ weeks?|team of [0-9]+|capacity of|by launch|before GA|## Phase (Plan|Assignment|Schedule|Roadmap))' docs/design-docs/*.md
```

**Empty output** = ไม่มี schedule leakage. **Any hit** → classify ด้วย 4-class table:

| Class | Icon | Meaning | Example | Action |
|-------|------|---------|---------|--------|
| **Hint OK** | ✅ | Architectural rationale + correct label | *"IMPL-003 in P1 — reason: ADR-005 requires unified JWT"* | No finding |
| **Missing rationale** | 🟡 MEDIUM | Hint present, rationale absent/non-architectural | *"IMPL-003 in P1 — reason: easier for team"* | Finding #20: *"Phase Hints missing architectural rationale"* |
| **Schedule leakage** | 🟡 MEDIUM | Sprint/week/date/capacity words present | *"Sprint 2"*, *"Week 3"*, *"Q2 2026"*, *"2 devs × 2 weeks"* | Finding #19 หรือ #20: *"Schedule content leaked into System Design"* |
| **Invalid label** | 🟡 MEDIUM | Section titled *"Plan"/"Assignment"/"Schedule"/"Roadmap"* | `## Phase Plan` | Finding #20: *"Phase Hints mislabeled — must be 'Hints (Suggested)'"* |

**Fix suggestion ใน findings:**
> *"SD provides architectural hints only — sprint numbers, calendar dates, team capacity are Impl Planner concerns (`docs/state/impl-plan.md`). Strip schedule content และ (a) reformat เป็น architectural Phase Hint พร้อม dependency/risk/MoSCoW rationale หรือ (b) remove + ให้ `/impl-plan` ตัดสิน. Keep architectural 'why', drop delivery 'when'"*

**Exception:** 5-Phase lifecycle references (*"Phase 1: DESIGN"*, *"Phase 3: IMPLEMENT"*) เป็น methodology — allowed ทุกที่

### 2.4 Draft Claims

เขียน **ภาษาไทย** ด้วย ruthless reviewer tone

```markdown
### Claim XX.N: [ICON] [SEVERITY] — [Title]

**Location:** `[file]` § [section]

**Problem:**
[2-4 ประโยค — quote exact text]

**Why this matters:**
[Real-world impact: "Under X load, Y will happen เพราะ Z" / "Attacker สามารถ X ได้เพราะ Y"]

**Minimum acceptable fix:**
[Specific — ไม่ใช่ "add rate limiting" → ระบุ where, what limits, what algorithm]

**Effort:** Low / Medium / High
```

**Severity** (ตาม SKILL.md):

| Icon | Level | When |
|------|-------|------|
| 🔴 | **CRITICAL** | Data loss, security breach, full outage under normal load, fundamental architecture flaw |
| 🟠 | **HIGH** | Significant degradation under moderate load, missing fallback, security gap, doc ทั้งไฟล์อ่านไม่รู้เรื่อง |
| 🟡 | **MEDIUM** | Problems at scale, workaround exists, incomplete design, ขาด TL;DR/Why/glossary เป็นบางจุด |
| 🔵 | **LOW** | Best practice violation, future risk, documentation gap, readability glitch |

### 2.5 Quality Gate (Self-Review Before Output)

- [ ] ทุก claim cite specific location + quoted text
- [ ] ไม่มี claim ซ้ำกับ fix ใน rebuttal ก่อน
- [ ] Severity match matrix (ไม่ใช่ guess)
- [ ] ทุก claim มี specific "Minimum acceptable fix"
- [ ] 22 categories scan ครบ (skip ต้อง note reason)
- [ ] Schedule-Leakage check (2.3) ได้ run — Evolution Sequence / Phase Hints มี architectural rationale; ไม่มี sprint/date/capacity หลงเหลือ
- [ ] **Language scan (category 22) ได้ run** — ถ้า target SD doc English-only หรือ prose Thai < 40% → raise เป็น finding (ไม่ซ่อนใน category 21)
- [ ] Total findings ≥ 3 (ถ้าน้อยกว่า = ตรวจอีกรอบ)
- [ ] **Claim review file เองเขียนเป็น bilingual** — Thai narrative + English technical terms
- [ ] Concrete numbers verify ว่ามี formula/derivation

---

## Phase 3: Output

### 3.1 Write File

Write to `docs/design-docs/claim-review-and-rebuttal/claim-review-XX.md`:

```markdown
# System Design Claim Review Round XX

| Field | Value |
|-------|-------|
| **Round** | XX |
| **Target** | `[filename or "all"]` |
| **Date** | YYYY-MM-DD |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |

---

## 📊 At-a-Glance

**Total findings:** N ({{🔴 CRITICAL N}} / {{🟠 HIGH N}} / {{🟡 MEDIUM N}} / {{🔵 LOW N}})
**Schedule-leakage check:** ✅ Clean / ⚠️ N findings raised

### Top 3 to Fix First
1. **Claim XX.A** 🔴 — [one-line title] — `[file]`
2. **Claim XX.B** 🔴 — [one-line title] — `[file]`
3. **Claim XX.C** 🟠 — [one-line title] — `[file]`

### Verdict
- [ ] ✅ **Ready for Implementation Handoff** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL หรือ HIGH → run `/sd-rebuttal claim-review-XX.md`
- [ ] ⛔ **Immediate Attention** — fundamental architecture flaw ที่ block implementation

---

## System Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| 2 | Service Boundaries | ✅ Pass / ⚠️ Finding XX.N | [brief note] |
| [... ครบทั้ง 22 categories (21 เดิม + Language Rule Compliance อันที่ 22) ...] |

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

[Contradictions จาก Phase 2.2 — หรือ "ไม่พบ contradictions"]

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| XX.1 | 🔴 CRITICAL | [title] | `03-deep-dive.md` § Saga | Medium |
| [...] |
```

### 3.2 Report to User (ภาษาไทย)

- Round number + target doc
- Findings count per severity
- Schedule-leakage check result
- File path ของ claim review
- **Top 3 findings** (highlight)
- Recommendation: proceed to rebuttal หรือ needs immediate attention
