# Phase Backtrack — Development Guide

คู่มือการย้อนกลับไป phase ก่อนหน้า เมื่อ downstream phase พบปัญหาที่แก้ไขไม่ได้โดยไม่เปลี่ยน upstream deliverables

---

## ภาพรวม

กระบวนการพัฒนาปกติเป็น linear (BA → SD → UX → TD → Implement → Harden → Deliver) แต่ในความเป็นจริง downstream phase อาจพบปัญหาที่ต้องย้อนกลับไปแก้ upstream:

```
                    Backtrack Flows
                    ──────────────

┌─────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Phase 1  │   │   Phase 2    │   │   Phase 3    │   │   Phase 4    │
│ DESIGN   │◀──│  DESIGN QA   │◀──│  IMPLEMENT   │◀──│   HARDEN     │
│          │   │              │   │              │   │              │
│ BA ◀─────────── SD review   │   │              │   │              │
│ SD ◀─────────── Code review │◀──│── Red Team   │   │              │
│ UX ◀─────────── Impl finds  │   │              │   │              │
└─────────┘   └──────────────┘   └──────────────┘   └──────────────┘

Forward:  ────▶  (ปกติ)
Backward: ◀────  (backtrack — ต้อง human approve)
```

---

## Backtrack Triggers — เมื่อไหร่ควรย้อน

### จาก SD Review → BA

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| Requirement ขัดแย้งกัน | FR-001 บอก sync แต่ FR-005 บอก async — ไม่สามารถ design ให้ตอบทั้งคู่ | CRITICAL |
| Requirement ไม่สามารถ implement ได้ | "ต้อง real-time sync ทุก field" แต่ latency budget < 100ms ข้าม region | CRITICAL |
| Missing user flow | ไม่มี flow สำหรับ error recovery ที่ architect ต้องออกแบบ | HIGH |
| Ambiguity ที่ architect ตัดสินใจไม่ได้ | "High availability" ไม่ระบุ RTO/RPO — ต้อง BA clarify | HIGH |
| Scope creep ระหว่าง design | พบว่า BA scope ใหญ่เกินไปจนออกแบบ reasonable ไม่ได้ | MEDIUM |

### จาก UX Design → BA

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| Missing user flow | ไม่มี flow สำหรับ empty state / first-time user | HIGH |
| User story ไม่สอดคล้องกับ UI reality | "ผู้ใช้ดูข้อมูลทุกอย่างในหน้าเดียว" — แต่ data มากเกินไป | HIGH |
| Data dictionary ไม่ครบ | UI ต้องแสดงข้อมูลที่ BA ไม่ได้ระบุ | MEDIUM |

### จาก UX Design → SD

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| API ไม่รองรับ UI flow | UI ต้อง real-time update แต่ API เป็น REST polling | HIGH |
| Component ต้อง data ที่ API ไม่มี | Dashboard widget ต้อง aggregated metric ที่ไม่มี endpoint | HIGH |
| Navigation structure ขัดกับ routing architecture | Multi-step wizard vs SPA routing conflict | MEDIUM |

### จาก Implementation → TD

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| API contract ไม่ตรงกับ DB schema | Field type ใน `docs/api-specs/*.yaml` ขัดกับ column type ใน `04-database-design.md` | CRITICAL |
| Class structure implement ไม่ได้ | Interface ใน `02-backend-design.md` ขาด method ที่จำเป็น | HIGH |
| Frontend component tree ไม่ match UX | Component ใน `03-frontend-design.md` ไม่ cover state ที่ UX กำหนด | HIGH |
| Test strategy ไม่ realistic | Coverage target ใน `docs/qa/01-test-strategy.md` เกินจริง หรือ mock strategy mask integration issues | MEDIUM |
| Migration order ผิด | Migration ใน `04-database-design.md` มี dependency ที่ไม่ได้ระบุ | HIGH |

### จาก Implementation → SD

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| API design ไม่ feasible | Endpoint ออกแบบไว้ต้อง join 5 tables ใน single request — performance ไม่ผ่าน | CRITICAL |
| Architecture ไม่รองรับ requirement | Microservice boundary ผิดจุด — ทำให้ distributed transaction ทุกที่ | CRITICAL |
| Tech stack ไม่เหมาะ | Library ที่เลือกไม่รองรับ feature ที่ต้องการ | HIGH |
| Data model ไม่ถูก | Schema ที่ออกแบบไว้ไม่รองรับ query pattern จริง | HIGH |

### จาก TD Review → SD

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| SD architecture ไม่รองรับ detail design | Service boundary ใน SD ทำให้ class structure ใน 2 service ซ้อนกัน | CRITICAL |
| ADR ขัดกับ detail design | ADR เลือก monolith แต่ feature ต้อง async processing — class design ทำไม่ได้ | CRITICAL |
| API spec ไม่สอดคล้องกับ data flow | SD data flow ระบุ POST แต่ API spec เขียน PUT | HIGH |

### จาก Implementation → UX

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| UX ขาด state ที่ต้อง implement | ไม่มี empty state สำหรับ kanban board — engineer ไม่รู้จะ design อะไร | HIGH |
| UX ขาด error state | Form ไม่มี validation error design — ไม่รู้จะแสดง error ยังไง | HIGH |
| UX component ไม่ cover responsive | Desktop layout มีแต่ mobile ไม่มี — frontend implement mobile ไม่ได้ | MEDIUM |
| UX interaction pattern ขัดกับ tech constraint | UX ออกแบบ drag & drop ซับซ้อน แต่ library ที่ใช้ไม่รองรับ | MEDIUM |

### จาก Implementation → BA

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| Business rule ขัดแย้งเมื่อ implement | Rule A + Rule B ไม่สามารถ true พร้อมกันได้ | CRITICAL |
| NFR ไม่ realistic | "Response time < 50ms" สำหรับ complex calculation — ไม่ feasible | HIGH |

### จาก Red Team → SD

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| Fundamental architecture flaw | Auth design มี inherent vulnerability ที่ patch ไม่ได้ | CRITICAL |
| Security model ไม่เพียงพอ | Multi-tenant isolation ออกแบบผิด ต้อง redesign | CRITICAL |

### จาก Red Team → BA

| Trigger | ตัวอย่าง | Severity |
|---------|---------|----------|
| Requirement สร้าง security risk | "ผู้ใช้เข้าถึงข้อมูลทุกคน" ขัดกับ data privacy regulation | CRITICAL |
| Missing security requirement | ไม่มี requirement เรื่อง audit trail ที่ compliance ต้องการ | HIGH |

---

## Invalidation Matrix

เมื่อ backtrack ไป phase ใด phase ถัดไปทั้งหมดถูก impact:

```
If CHANGED →     BA        SD        UX        TD        Impl Plan   Impl Code   Code Review   Red Team
──────────────────────────────────────────────────────────────────────────────────────────────────────────
BA                 —        ⚠️         ⚠️         ⚠️          ❌            ❌           ❌            ❌
SD                 —         —         ⚠️         ❌          ❌            ❌           ❌            ❌
UX                 —         —          —         ⚠️          ⚠️            ⚠️           ❌            ❌
TD                 —         —          —          —          ❌            ❌           ❌            ❌
Impl Plan          —         —          —           —            ⚠️           ❌            ❌
```

**Legend:**
- ⚠️ **Needs re-validation** — อาจจะยังถูกอยู่ ต้องตรวจสอบ ไม่ต้อง redo ทั้งหมด
- ❌ **Invalidated** — ต้อง re-run phase นั้น (อย่างน้อย partial)

### ตัวอย่าง:

**BA เปลี่ยน** → SD ต้อง re-validate, UX ต้อง re-validate, TD ต้อง re-validate, Impl/Review/Red Team ต้อง re-run

**SD เปลี่ยน** → UX ต้อง re-validate, TD ต้อง re-run (architecture constraint เปลี่ยน), Impl ต้อง re-run

**TD เปลี่ยน** → Impl Plan/Code/Review/Red Team ต้อง re-run (implementation blueprint เปลี่ยน)

### Project Bootstrap Invalidation (Phase 2.5)

เมื่อ backtrack เสร็จและ TD/SD/ADR เปลี่ยน → **`.claude/stack.json` + `.claude/rules/*` ก็ stale ตาม** (engineer subagents อ่าน rules ตอน runtime จึง pick up การเปลี่ยนแปลงได้ทันทีโดยไม่ต้อง regen):

| Backtrack Target | Affects `.claude/rules/*` + stack.json? | Action |
|------------------|------------------------------------------|--------|
| BA | ⚠️ อาจ affect (ถ้า domain glossary เปลี่ยน) | Re-review หลัง TD update + `/project-init --regen` |
| SD | ⚠️ อาจ affect (ถ้า architecture pattern เปลี่ยน) | Re-review หลัง TD update + `/project-init --regen` |
| UX | ⚠️ อาจ affect (ถ้า `.claude/rules/web.md` reference tokens/components) | `/project-init --regen` หลัง UX rework + TD update |
| **TD** | ❌ **Always invalidated** — stack facts มาจาก TD โดยตรง | **Must run `/project-init --regen` หลัง TD rework** |

**Recommended sequence after TD backtrack:**
1. Resolve backtrack (Steps 1-7 ข้างบน)
2. Run `bash scripts/validate-rules-sync.sh` → confirm drift detected
3. Run `/project-init --regen` → regenerate CLAUDE.md + rules
4. Review 2-3 HALTs + approve
5. Commit regenerated rules
6. Resume forward flow (Impl Plan / Impl Tasks)

---

## Backtrack Process — ขั้นตอนการย้อน

### Step 1: Identify & Escalate

เมื่อ downstream phase พบปัญหาที่แก้ locally ไม่ได้:

1. Agent/Human ระบุปัญหาอย่างชัดเจน
2. อ้างอิง source ที่ขัดแย้ง (file + line + quote)
3. อธิบายว่าทำไม fix ใน phase ปัจจุบันไม่ได้
4. เสนอ backtrack target (ย้อนไป phase ไหน)

### Step 2: Impact Analysis (Mandatory)

ก่อน backtrack จริง ต้องวิเคราะห์ impact:

```markdown
## Backtrack Impact Analysis

**Trigger:** [อธิบายปัญหา]
**Current Phase:** [Phase ปัจจุบัน]
**Backtrack Target:** [Phase ที่ต้องย้อนไป]
**Source:** [ไฟล์/finding ที่เป็นต้นเหตุ]

### Scope of Change
- [อะไรที่ต้องเปลี่ยนใน target phase]

### Invalidated Deliverables
| Phase | Deliverable | Impact | Action Needed |
|-------|-------------|--------|---------------|
| [phase] | [file] | ⚠️ Re-validate / ❌ Re-run | [คำอธิบาย] |

### Effort Estimate
- Rework: [S/M/L]
- Re-validation: [S/M/L]
- Total: [estimate]

### Risk of NOT Backtracking
- [อะไรจะเกิดขึ้นถ้าไม่ย้อน — e.g., technical debt, broken feature]
```

### Step 3: HALT — User Approval

⏸️ **ห้าม backtrack โดยไม่มี human approve เด็ดขาด**

แสดง impact analysis → รอ user ตัดสินใจ:

- **Approve backtrack** → ดำเนินการ Step 4
- **Reject** → หาทาง workaround ใน phase ปัจจุบัน
- **Modify scope** → ปรับ scope ของ backtrack ให้เล็กลง

### Step 4: Record Backtrack

เขียน entry ใน `docs/state/backtrack-log.md`:

```markdown
## BT-001 — [Short Title]

- **Date:** YYYY-MM-DD
- **Triggered by:** [Agent/Phase ที่พบปัญหา]
- **Source:** [finding file/reference]
- **Backtrack from:** Phase [N] → Phase [M]
- **Reason:** [สาเหตุ]
- **Impact:** [จำนวน deliverables ที่ invalidated]
- **Status:** 🔄 Open / ✅ Resolved
- **Resolution:** [อะไรที่ทำเพื่อแก้ — filled after resolved]
```

### Step 5: Mark Invalidated Phases

Update `docs/state/overview.md` — mark phases ที่ถูก invalidate:

```markdown
## Phase Status

| Phase | Status | Note |
|-------|--------|------|
| BA | ✅ Complete | |
| SD | 🔄 **BACKTRACK** — rework in progress (BT-001) | |
| UX | ⚠️ Pending re-validation (BT-001) | |
| Impl Plan | ❌ Invalidated (BT-001) | |
```

### Step 6: Rework

ย้อนกลับไปทำ phase ที่ต้องแก้:

- ใช้ prompt template / workflow เดิม แต่ focus เฉพาะจุดที่ต้องเปลี่ยน
- **ไม่ต้อง redo ทั้งหมด** — แก้เฉพาะ scope ที่ระบุใน impact analysis
- Commit ทุกการแก้ไขด้วย prefix `[BACKTRACK BT-XXX]`

### Step 7: Re-validate Downstream

หลัง rework เสร็จ ต้อง re-validate downstream phases:

1. **⚠️ phases** — อ่านและตรวจว่ายัง valid อยู่ไหม (อาจไม่ต้องแก้)
2. **❌ phases** — re-run (อย่างน้อย partial review/rebuild)
3. Update `docs/state/overview.md` เมื่อแต่ละ phase ผ่าน re-validation

### Step 8: Close Backtrack

เมื่อทุก downstream phase ผ่าน re-validation:

1. Update backtrack log → `Status: ✅ Closed` (เปลี่ยนจาก 🔄 Open) + set `Resolution:` field
2. Update overview.md → **remove backtrack markers ทั้งหมดที่ reference BT-NNN** (🔄 BACKTRACK / ⚠️ Pending re-validation / ❌ Invalidated)
3. Resume normal forward flow

> ⚠️ **Drift guard:** ถ้าปิด log แต่ลืมลบ markers (หรือกลับกัน) `/next` Check 0.7 (Backtrack/Overview Reconciliation) จะ flag drift advisory. ทั้งสอง direction:
> - **Direction A** — log Closed แต่ overview ยังมี marker → `/next` รายงาน "stale markers" (advisory, ไม่ block)
> - **Direction B** — log Open แต่ overview ไม่มี marker → `/next` รายงาน "missing markers" (advisory; downstream re-validation อาจ proceed silently)
>
> Always update both files together when closing.

---

## `/backtrack` Command

```
/backtrack ba       ← ย้อนไปแก้ BA requirements
/backtrack sd       ← ย้อนไปแก้ System Design
/backtrack ux       ← ย้อนไปแก้ UX/UI Design
/backtrack td       ← ย้อนไปแก้ Technical Design
```

> ⚠️ **Valid targets only:** `/backtrack` validates target ∈ `{ba, sd, ux, td}`. Other targets (`impl`, `impl-plan`, `impl-task`, `code`, etc.) **are rejected** by the workflow. Route by concern instead:
> - Task / AC decomposition / Phase Gate criteria → `/impl-plan-review all` (Plan QA loop)
> - Code defect in closed phase → `/impl-review all` + `IMPL-FIX-*` ticket + Tier 1.5 walk re-run
> - Upstream design root cause → `/backtrack ba|sd|ux|td` (this workflow)
>
> ดู `/next` §1.9.5 Scenario H + Glossary "Backtrack/Overview Reconciliation"

Workflow จะ:
1. อ่าน project state
2. วิเคราะห์ impact (invalidation matrix)
3. สร้าง impact analysis report
4. HALT — รอ user approve
5. บันทึก backtrack log
6. Mark invalidated phases
7. แนะนำ commands ที่ต้อง run ถัดไป

---

## Best Practices

### ✅ ควรทำ

- **Backtrack เร็ว** — ยิ่งพบเร็วยิ่งถูก (cost of change curve)
- **Scope ให้เล็กที่สุด** — แก้เฉพาะจุด ไม่ต้อง redo ทั้ง phase
- **บันทึกเหตุผล** — backtrack log เป็น learning สำหรับ future projects
- **Re-validate ทุก downstream** — อย่าข้าม แม้คิดว่า "น่าจะ OK"

### ❌ ไม่ควรทำ

- **อย่า backtrack โดยไม่ analyze impact** — อาจทำให้ rework มากเกินจำเป็น
- **อย่า patch downstream แทน backtrack** — เมื่อ root cause อยู่ upstream, downstream fix = technical debt
- **อย่า skip human approval** — backtrack มี cost สูง ต้องให้คนตัดสินใจ
- **อย่าแก้ upstream แล้วลืม downstream** — invalidated phases ต้อง re-validate เสมอ

---

## Backtrack vs. Workaround — ตัดสินใจอย่างไร

| เกณฑ์ | Backtrack | Workaround |
|-------|-----------|------------|
| Root cause อยู่ upstream | ✅ ใช่ | ❌ ไม่ควร |
| Fix ได้ใน phase ปัจจุบัน | ❌ ไม่ได้ | ✅ ได้ |
| Impact กว้าง (หลาย feature) | ✅ backtrack | ⚠️ อาจ backtrack |
| Impact แคบ (1 endpoint) | ⚠️ พิจารณา | ✅ workaround ได้ |
| เป็น architecture concern | ✅ backtrack | ❌ ไม่ควร patch |
| เป็น wording/clarification | ❌ ไม่ต้อง | ✅ clarify in-place |
| มี deadline กดดัน | ⚠️ scope down | ⚠️ document as tech debt |

**Rule of thumb:** ถ้าต้อง "assume" อะไรที่ upstream ควรระบุไว้ → backtrack

---

## File Structure

```
docs/state/
  overview.md            ← Phase status (updated with backtrack markers)
  backtrack-log.md       ← Append-only log of all backtrack events

.andm/development-guide/
  backtrack-workflow.md  ← This file

.agents/workflows/
  backtrack.md           ← /backtrack command workflow

.windsurf/workflows/
  backtrack.md           ← Windsurf slash command bridge
```
