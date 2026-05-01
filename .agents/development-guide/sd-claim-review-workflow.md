# System Design Claim Review & Rebuttal — Development Guide

คู่มือการใช้งาน workflow สำหรับกรองคุณภาพ System Design deliverables ผ่าน multi-agent review/rebuttal cycle

---

## ภาพรวม Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│  Architect Agent สร้าง docs/design-docs/02-08 + docs/adr/ (v1.2)      │
│  (ใช้ prompt: .agents/prompt-templates/system-design-master-*.md)    │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  /sd-review  →  Reviewer Agent ตรวจ → claim-review-01.md            │
│  Persona: .agents/skills/andm-sd-reviewer/SKILL.md                       │
│  (Adversarial Architect — หาจุดอ่อนในการออกแบบ)                       │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  /sd-rebuttal  →  Defender Agent แก้/โต้ → rebuttal-round-01.md     │
│  Persona: .agents/skills/andm-sd-defender/SKILL.md                       │
│  + แก้ไข design-docs/02-08 + ADRs + API specs ตาม accepted findings │
└──────────────────────┬───────────────────────────────────────────────┘
                       ▼
              ┌─────────────────────┐
              │ ผ่าน? พร้อม handoff  │──Yes──▶  Implementation Handoff
              │ ให้ทีม implement?   │          (Backend, Frontend, QA)
              └───────┬─────────────┘
                      │ No
                      ▼
              ทำซ้ำ Round 02, 03...
```

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สร้าง System Design Documents (ก่อนเริ่ม review)

Architect ใช้ prompt template สร้างเอกสาร 6 ไฟล์ใน `docs/design-docs/` (v1.2: gaps ที่ 01/06 — merged into 02):

```
docs/design-docs/                 ← v1.2: 6 docs, gaps ที่ 01/06 (merged into 02)
  02-high-level-architecture.md   ← Requirements Traceability + Components/services/communication + Glossary + ADR Digest
  03-deep-dive.md                 ← Critical technical challenges
  04-data-flow.md                 ← Sequence diagrams, timing budgets
  05-security.md                  ← Defense layers, threat model
  07-future-evolution.md          ← Scaling triggers + migration paths + Evolution Sequence (E1/E2/... with ADR rationale)
  08-product-breakdown.md         ← Work inventory + Phase Hints (Suggested P1-P4 with architectural rationale) + Per-Task Metadata (risk, must_precede, unlocks)
```

> ⚠️ **SD ให้ architectural HINTS ได้ แต่ไม่ทำ delivery schedule (Option C)**
>
> **SD CAN include:**
> - `07-future-evolution.md` → **Evolution Sequence** (architectural ordering with ADR rationale)
> - `08-product-breakdown.md` → **Phase Hints (Suggested)** + **Per-Task Metadata**
>
> **SD CANNOT include:**
> - Sprint numbers, calendar dates, team capacity, release timelines
> - Phase Hints labeled as "Plan"/"Assignment" (must be "Hints (Suggested)")
> - Phase Hints without architectural rationale
>
> **Impl Planner owns the final phasing** — reads SD hints as input, honors or overrides with documented rationale in `docs/state/impl-plan.md`
>
> ดู: `.agents/development-guide/impl-workflow.md` สำหรับรายละเอียดการแบ่ง Implementation Phases และ SD hint honor/override protocol

พร้อม artifacts เพิ่มเติม:
```
docs/adr/NNN-title.md              ← Architecture Decision Records
docs/api-specs/*.yaml              ← OpenAPI contracts
docs/diagrams/*.md                 ← Mermaid diagrams
```

Prompt template อยู่ที่:
- `.agents/prompt-templates/system-design-master-prompt.md`

---

### Step 2: สั่ง Review (เปิด session ใหม่)

#### Review ทั้งหมด:
```
/sd-review all
```

#### Review ทีละไฟล์:
```
/sd-review docs/design-docs/03-deep-dive.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → design quality benchmark
2. **Phase 1 — Preparation:** หา round number, อ่าน target + related docs + ADRs + API specs + BA NFRs
3. **Phase 2 — Generate Claims:** Scan 20 system design attack vector categories + Grep cross-document consistency
4. **Phase 3 — Output:** สร้างไฟล์ claim review + รายงานสรุปเป็นภาษาไทย

#### Output:
```
docs/design-docs/claim-review-and-rebuttal/claim-review-01.md
```

ประกอบด้วย:
- Severity summary (CRITICAL / HIGH / MEDIUM / LOW)
- System Design Attack Vector Checklist (20 categories — Pass/Finding)
  - Category #19: **Future Evolution + Evolution Sequence** — scaling triggers + migration paths + optional Evolution Sequence (E1/E2/... with ADR rationale). Flag ถ้ามี schedule content (dates/sprints/capacity)
  - Category #20: **Work Inventory + Phase Hints** — work list + optional Phase Hints (Suggested P1-P4 with architectural rationale) + Per-Task Metadata. Flag ถ้ามี schedule content หรือ Hints ไม่มี rationale
- Findings เรียงตาม severity พร้อม citations
- Cross-document issues (ระหว่าง design docs, ADRs, API specs)
- **Schedule-leakage findings** — sprint numbers, calendar dates, team capacity ที่หลุดเข้ามาใน design docs (ต้องย้ายไป impl-plan หรือ reformat เป็น architectural hints)
- **Hint-quality findings** — Phase Hints ที่ไม่มี architectural rationale, หรือ label ผิด (เช่น "Plan" แทน "Hints")
- Summary table

---

### Step 3: สั่ง Rebuttal (เปิด session ใหม่)

```
/sd-rebuttal docs/design-docs/claim-review-and-rebuttal/claim-review-01.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → design quality benchmark
2. **Phase 1 — Analysis:** วิเคราะห์ทุก claim → ตัดสิน Accept / Reject / Partial → แสดงตาราง summary

3. **⏸️ HALT — รอ user approve**

   Agent จะแสดงตารางสรุปแล้วหยุดรอ user:
   ```
   | # | Severity | Title                         | Verdict | Files to Modify          | Cross-Doc Risk |
   |---|----------|-------------------------------|---------|--------------------------|----------------|
   | 1 | CRITICAL | No compensation for saga      | Accept  | 03, 04, ADR-005          | High           |
   | 2 | HIGH     | Missing circuit breaker        | Accept  | 03                       | Low            |
   | 3 | HIGH     | Cache TTL = "configure later" | Accept  | 03, 02                   | Medium         |
   | 4 | MEDIUM   | No 10x scaling plan           | Partial | 07                       | Low            |
   | 5 | LOW      | Missing ADR for DB choice     | Accept  | ADR-new                  | Low            |
   ```

   **User ตอบ:**
   - `proceed` → ดำเนินการตาม verdict ที่เสนอ
   - `ปรับ claim 4 เป็น accept` → แก้ verdict แล้วดำเนินการ
   - `reject claim 3, ที่เหลือ proceed` → ปรับเฉพาะจุด

4. **Phase 2 — Execution:** แก้ไข design docs ทีละ claim (7-step protocol) + update ADRs ถ้า architecture decision เปลี่ยน
5. **Phase 3 — Write Rebuttal:** สร้างไฟล์ rebuttal report
6. **Phase 4 — Consistency Sweep:** ตรวจ component names, numbers, tech stack, ADR alignment, API contract alignment, NFR alignment
7. **Phase 5 — Report:** สรุปผลเป็นภาษาไทย

#### Output:
```
docs/design-docs/claim-review-and-rebuttal/rebuttal-round-01.md
```

ประกอบด้วย:
- Summary (Accepted / Partial / Rejected counts)
- Claim responses ทุก claim พร้อม evidence
- Cascaded changes (รวม ADR updates)
- Strength assessment
- Recommendation (Ready / Re-Review / Needs Stakeholder Input)

---

### Step 4: ทำซ้ำ (ถ้ายังไม่ผ่าน)

```
/sd-review all
/sd-rebuttal docs/design-docs/claim-review-and-rebuttal/claim-review-02.md
```

- Round number จะ auto-detect (02, 03, ...)
- Agent จะ **ไม่ raise finding ซ้ำ** ที่ fix แล้วใน round ก่อน (anti-duplication rule)
- แต่ถ้า fix ไม่สมบูรณ์ จะ raise ใหม่พร้อมอ้างอิง round ก่อน

---

### Step 5: Handoff to Implementation

เมื่อ rebuttal report ระบุ **"Ready for Implementation Handoff ✅"**:

- Design documents (`docs/design-docs/02-08`; v1.2) พร้อมส่งต่อ — **architecture + hints, ไม่มี schedule**
- ADRs (`docs/adr/`) เป็นข้อตกลง architecture ที่ผ่านการ review แล้ว
- API contracts (`docs/api-specs/`) พร้อมให้ Backend/Frontend implement
- `07-future-evolution.md` อาจมี **Evolution Sequence** (hard architectural constraints)
- `08-product-breakdown.md` มี **Work Inventory + Phase Hints (Suggested) + Per-Task Metadata**
- ใช้ `/impl-plan` เพื่อ:
  1. อ่าน work inventory + SD Phase Hints + Evolution Sequence + per-task metadata
  2. รัน phase assignment rules ของตัวเอง (independent)
  3. เปรียบเทียบกับ SD hints — align หรือ diverge? (Evolution Sequence ห้าม violate)
  4. **Document honor/override ใน Phasing Rationale** (mandatory audit trail)
  5. จัด tasks เข้า Implementation Phases (Foundation → Core → Polish → Stretch) พร้อม phase gates
  6. สร้าง plan ที่พร้อม execute → `/impl-task` implement ทีละ task

---

## File Structure

```
.claude/commands/
  sd-review.md                      ← /sd-review command definition
  sd-rebuttal.md                    ← /sd-rebuttal command definition

methodologies/full-track/
  skills/
    andm-sd-reviewer/SKILL.md            ← Reviewer persona (adversarial architect)
    andm-sd-defender/SKILL.md            ← Defender persona (constructive architect)
  prompt-templates/
    system-design-master-prompt.md         ← Design master prompt

docs/design-docs/                  ← v1.2: 6 docs (gaps 01/06)
  02-high-level-architecture.md   ← Design deliverables (แก้ไขแล้วผ่าน review; incl. Traceability + ADR Digest)
  03-deep-dive.md
  04-data-flow.md
  05-security.md
  07-future-evolution.md
  08-product-breakdown.md
  claim-review-and-rebuttal/
    claim-review-01.md              ← Round 1 findings
    rebuttal-round-01.md            ← Round 1 responses + fixes
    claim-review-02.md              ← Round 2 findings (ถ้ามี)
    rebuttal-round-02.md            ← Round 2 responses + fixes

docs/adr/                           ← Architecture Decision Records (updated during rebuttal)
docs/api-specs/                     ← OpenAPI contracts (updated during rebuttal)
```

---

## Agent Personas

### SD Reviewer (`.agents/skills/andm-sd-reviewer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Principal System Design Reviewer / Adversarial Architect |
| **Mindset** | break the design before production breaks it |
| **Owns** | `claim-review-XX.md` |
| **Cannot modify** | Design deliverables (02-08; v1.2: gaps 01/06), ADRs, API specs |
| **Key tool** | System Design Attack Vector Checklist (20 categories) |
| **Language** | Thai (findings) + English (technical terms) |

### SD Defender (`.agents/skills/andm-sd-defender/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Principal System Architect & Design Defense Specialist |
| **Mindset** | ยอมรับคำวิจารณ์ที่ถูกต้อง โต้แย้งด้วยหลักฐาน technical |
| **Owns** | `rebuttal-round-XX.md` |
| **Can modify** | Design deliverables (02-08; v1.2: gaps 01/06), ADRs, API specs |
| **Key tool** | 7-step claim processing protocol + ADR update rule |
| **Language** | Thai (arguments) + English (technical terms) |

---

## ความแตกต่างจาก BA Workflow

| Aspect | BA Workflow | SD Workflow |
|--------|------------|-------------|
| **Target docs** | `docs/ba/01-05` (v1.2) | `docs/design-docs/02-08` (v1.2: gaps 01/06) |
| **Additional targets** | — | `docs/adr/`, `docs/api-specs/` |
| **Attack vectors** | 18 BA categories (requirements quality) | 20 SD categories (architecture quality) |
| **Cross-doc scope** | BA docs only | Design docs + ADRs + API specs + BA NFRs |
| **ADR rule** | N/A | ต้อง update ADR ถ้า architecture decision เปลี่ยน |
| **Handoff to** | Architect | Backend, Frontend, QA (implementation) |
| **Commands** | `/ba-review`, `/ba-rebuttal` | `/sd-review`, `/sd-rebuttal` |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้า SD review/rebuttal พบปัญหาเหล่านี้ที่แก้ใน SD ไม่ได้ → ต้อง backtrack ไป BA:

| Trigger | ตัวอย่าง | Action |
|---------|---------|--------|
| **BA requirement ขัดแย้งกัน** | FR-001 ต้อง sync แต่ FR-005 ต้อง async — ออกแบบไม่ได้ | `/backtrack ba` |
| **Requirement infeasible** | "Real-time sync ทุก field" แต่ latency budget < 100ms | `/backtrack ba` |
| **Missing user flow** | ไม่มี error recovery flow ที่ architect ต้องออกแบบ | `/backtrack ba` |
| **Ambiguity ตัดสินใจไม่ได้** | "High availability" ไม่ระบุ RTO/RPO | `/backtrack ba` |

> ⚠️ อย่า patch SD ด้วย assumptions — ถ้า root cause อยู่ที่ BA → backtrack ก่อน
> **📖 Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/sd-review` หรือ `/sd-rebuttal` เพื่อให้ agent onboard ใหม่ด้วย persona ที่ถูกต้อง
- **Review ทีละไฟล์** สำหรับ deep dive (เช่น `03-deep-dive.md`, `05-security.md`) หรือ **review all** สำหรับ comprehensive scan
- **ตรวจ HALT point** ใน rebuttal — agent จะหยุดรอ approve ก่อนแก้ไข design docs
- **ADR updates** จะเกิดขึ้นอัตโนมัติเมื่อ architecture decision เปลี่ยน — ตรวจ `docs/adr/` หลัง rebuttal
- **ปกติ 2-3 rounds** เพียงพอสำหรับ design documents ที่มีคุณภาพดี
- **ใช้ร่วมกับ BA workflow** — run BA review/rebuttal ก่อน แล้วค่อย run SD review/rebuttal เพื่อกรองคุณภาพตั้งแต่ requirements จนถึง architecture
