# BA Claim Review & Rebuttal — Development Guide

คู่มือการใช้งาน workflow สำหรับกรองคุณภาพ BA deliverables ผ่าน multi-agent review/rebuttal cycle

---

## ภาพรวม Flow

```
┌─────────────────────────────────────────────────────────────┐
│  BA Agent สร้าง docs/ba/01-05 (v1.2: 06-handoff dropped)        │
│  (ใช้ prompt: .andm/prompt-templates/ba-requirements-*.md) │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  /ba-review  →  Reviewer Agent ตรวจ → claim-review-01.md     │
│  Persona: .agents/skills/andm-ba-reviewer/SKILL.md                │
└──────────────────────┬───────────────────────────────────────┘
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  /ba-rebuttal  →  Defender Agent แก้/โต้ → rebuttal-round-01 │
│  Persona: .agents/skills/andm-ba-defender/SKILL.md                │
│  + แก้ไข docs/ba/01-05 ตาม accepted findings                 │
└──────────────────────┬───────────────────────────────────────┘
                       ▼
              ┌────────────────┐
              │ ผ่าน? พร้อม     │──Yes──▶  Handoff to Architect
              │ handoff ไหม?   │
              └───────┬────────┘
                      │ No
                      ▼
              ทำซ้ำ Round 02, 03...
```

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สร้าง BA Deliverables (ก่อนเริ่ม review)

ใช้ prompt template สร้างเอกสาร 5 ไฟล์ใน `docs/ba/` (v1.2):

```
docs/ba/
  01-project-brief.md
  02-functional-requirements.md
  03-non-functional-requirements.md
  04-business-rules.md
  05-user-flows.md
```

> **v1.2 change:** `06-handoff-to-architecture.md` removed — open questions / risks live ใน relevant doc ตาม domain (FR→02, NFR→03, rule→04, flow→05)

Prompt template อยู่ที่:
- `.andm/prompt-templates/ba-requirements-prompt.md`

---

### Step 2: สั่ง Review (เปิด session ใหม่)

#### Review ทั้งหมด:
```
/ba-review all
```

#### Review ทีละไฟล์:
```
/ba-review docs/ba/02-functional-requirements.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → BA benchmark template
2. **Phase 1 — Preparation:** หา round number, อ่าน target + related docs, อ่าน previous rounds
3. **Phase 2 — Generate Claims:** Scan 18 BA attack vector categories + Grep cross-document consistency
4. **Phase 3 — Output:** สร้างไฟล์ claim review + รายงานสรุปเป็นภาษาไทย

#### Output:
```
docs/ba/claim-review-and-rebuttal/claim-review-01.md
```

ประกอบด้วย:
- Severity summary (CRITICAL / HIGH / MEDIUM / LOW)
- BA Attack Vector Checklist (18 categories — Pass/Finding)
- Findings เรียงตาม severity
- Cross-document issues
- Summary table

---

### Step 3: สั่ง Rebuttal (เปิด session ใหม่)

```
/ba-rebuttal docs/ba/claim-review-and-rebuttal/claim-review-01.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → BA benchmark template
2. **Phase 1 — Analysis:** วิเคราะห์ทุก claim → ตัดสิน Accept / Reject / Partial → แสดงตาราง summary

3. **⏸️ HALT — รอ user approve**

   Agent จะแสดงตารางสรุปแล้วหยุดรอ user:
   ```
   | # | Severity | Title                    | Verdict | Files to Modify |
   |---|----------|--------------------------|---------|-----------------|
   | 1 | CRITICAL | Missing core user story   | Accept  | 02, 05          |
   | 2 | HIGH     | NFR ไม่มี measurable target | Partial | 03              |
   | 3 | MEDIUM   | Edge case ขาด             | Accept  | 04              |
   | 4 | LOW      | Mermaid diagram missing   | Reject  | -               |
   ```

   **User ตอบ:**
   - `proceed` → ดำเนินการตาม verdict ที่เสนอ
   - `ปรับ claim 4 เป็น accept` → แก้ verdict แล้วดำเนินการ
   - `reject claim 1, ที่เหลือ proceed` → ปรับเฉพาะจุด

4. **Phase 2 — Execution:** แก้ไข BA docs ทีละ claim (7-step protocol)
5. **Phase 3 — Write Rebuttal:** สร้างไฟล์ rebuttal report
6. **Phase 4 — Consistency Sweep:** ตรวจ entity/actor/priority/diagram consistency
7. **Phase 5 — Report:** สรุปผลเป็นภาษาไทย

#### Output:
```
docs/ba/claim-review-and-rebuttal/rebuttal-round-01.md
```

ประกอบด้วย:
- Summary (Accepted / Partial / Rejected counts)
- Claim responses ทุก claim พร้อม evidence
- Cascaded changes (ถ้ามีการแก้ข้าม doc)
- Strength assessment
- Recommendation (Ready / Re-Review / Needs Stakeholder Input)

---

### Step 4: ทำซ้ำ (ถ้ายังไม่ผ่าน)

```
/ba-review all
/ba-rebuttal docs/ba/claim-review-and-rebuttal/claim-review-02.md
```

- Round number จะ auto-detect (02, 03, ...)
- Agent จะ **ไม่ raise finding ซ้ำ** ที่ fix แล้วใน round ก่อน (anti-duplication rule)
- แต่ถ้า fix ไม่สมบูรณ์ จะ raise ใหม่พร้อมอ้างอิง round ก่อน

---

### Step 5: Handoff to Architect

เมื่อ rebuttal report ระบุ **"Ready for Architecture Handoff ✅"**:

- BA deliverables (`docs/ba/01-05`; v1.2) พร้อมส่งต่อ
- Architect อ่าน BA 01-05 ตรงๆ (open questions อยู่ใน relevant doc ตาม domain)
- รัน `/sd` (workflow wraps `.andm/prompt-templates/system-design-master-prompt.md`) — agent โหลด BA + foundation-input-sources อัตโนมัติ

---

## File Structure

```
.claude/commands/
  ba-review.md                      ← /ba-review command definition
  ba-rebuttal.md                    ← /ba-rebuttal command definition

.agents/skills/
  andm-ba-reviewer/SKILL.md            ← Reviewer persona (adversarial consultant)
  andm-ba-defender/SKILL.md            ← Defender persona (constructive defender)

.andm/prompt-templates/
  ba-requirements-prompt.md            ← BA master prompt

docs/ba/
  01-project-brief.md              ← BA deliverables
  02-functional-requirements.md
  03-non-functional-requirements.md
  04-business-rules.md
  05-user-flows.md
  claim-review-and-rebuttal/
    claim-review-01.md              ← Round 1 findings
    rebuttal-round-01.md            ← Round 1 responses + fixes
    claim-review-02.md              ← Round 2 findings (ถ้ามี)
    rebuttal-round-02.md            ← Round 2 responses + fixes
```

---

## Agent Personas

### BA Reviewer (`.agents/skills/andm-ba-reviewer/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior BA Reviewer / Adversarial Consultant |
| **Mindset** | หาปัญหา ไม่ใช่ชม — เป็นด่านสุดท้ายก่อน handoff |
| **Owns** | `claim-review-XX.md` |
| **Cannot modify** | BA deliverables (01-05; v1.2: 06-handoff dropped) |
| **Key tool** | BA Attack Vector Checklist (18 categories) |
| **Language** | Thai (findings) + English (technical terms) |

### BA Defender (`.agents/skills/andm-ba-defender/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior BA & Requirements Defense Specialist |
| **Mindset** | ยอมรับคำวิจารณ์ที่ถูกต้อง โต้แย้งสิ่งที่ไม่ถูกต้องด้วยหลักฐาน |
| **Owns** | `rebuttal-round-XX.md` |
| **Can modify** | BA deliverables (01-05; v1.2: 06-handoff dropped) ตาม accepted findings |
| **Key tool** | 7-step claim processing protocol |
| **Language** | Thai (arguments) + English (technical terms) |

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/ba-review` หรือ `/ba-rebuttal` เพื่อให้ agent onboard ใหม่ด้วย persona ที่ถูกต้อง
- **Review ทีละไฟล์** ถ้าต้องการ feedback ละเอียด หรือ **review all** ถ้าต้องการ comprehensive scan
- **ตรวจ HALT point** ใน rebuttal — agent จะหยุดรอ approve ก่อนแก้ไข BA docs
- **Anti-duplication** ทำงานอัตโนมัติ — agent จะอ่าน previous rounds ก่อนเริ่ม review ใหม่
- **ปกติ 2-3 rounds** เพียงพอสำหรับ BA deliverables ที่มีคุณภาพดี
