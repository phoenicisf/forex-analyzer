# Red Team Security Audit — Development Guide

คู่มือการใช้งาน workflow สำหรับ Harden Phase: ตรวจสอบความปลอดภัยของ code ด้วย Red Team / Defense cycle

---

## ภาพรวม Flow

```
┌────────────────────────────────────────────────────────────────┐
│  ผ่าน Implementation Phase แล้ว                                │
│  มี working code ใน services/api/, services/web/, services/worker/ │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /red-team  →  Attacker Agent ตรวจ code → red-team-round-01.md │
│  Persona: .agents/skills/andm-red-team-attacker/SKILL.md            │
│  (OWASP Top 10 + STRIDE — code-level security audit)           │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
┌────────────────────────────────────────────────────────────────┐
│  /red-team-rebuttal  →  Defender Agent แก้/โต้                 │
│  Persona: .agents/skills/andm-red-team-defender/SKILL.md            │
│  + แก้ code + เพิ่ม tests + update security rules & docs       │
│  Output: defense-round-01.md                                   │
└──────────────────────┬─────────────────────────────────────────┘
                       ▼
              ┌──────────────────────┐
              │ ผ่าน? พร้อม deploy?   │──Yes──▶  Production / Deliver Phase
              └───────┬──────────────┘
                      │ No
                      ▼
              ทำซ้ำ Round 02, 03...
```

---

## ความแตกต่างจาก SD Review

| Aspect | SD Review (`/sd-review`) | Red Team (`/red-team`) |
|--------|------------------------|----------------------|
| **Target** | `docs/design-docs/` (เอกสาร) | `services/` (code จริง) |
| **เมื่อไร** | หลัง design, ก่อน implement | หลัง implement, ก่อน deploy |
| **Methodology** | Architecture quality checklist | OWASP Top 10 + STRIDE |
| **Output** | Design flaws | Exploitable vulnerabilities + PoC |
| **Fix** | แก้เอกสาร design | แก้ code + เพิ่ม tests + update security rules |

---

## Step-by-Step: ต้องทำอะไร พิมพ์อะไร

### Step 1: สั่ง Red Team Audit (เปิด session ใหม่)

#### Audit ทั้งหมด:
```
/red-team all
```

#### Audit ทีละ service:
```
/red-team services/api/
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → security rules → `05-security.md`
2. **Phase 1 — Preparation:** หา round number, อ่าน code + security baseline + previous rounds
3. **Phase 2 — Attack:** Scan 20 security categories + cross-service check + draft findings with PoC
4. **Phase 3 — Output:** สร้างไฟล์ red-team report + สรุปเป็นภาษาไทย

#### Output:
```
docs/security/red-team-round-01.md
```

ประกอบด้วย:
- Severity summary (CRITICAL / HIGH / MEDIUM / LOW)
- Code Security Attack Vector Checklist (20 categories — Clean/Finding)
- Findings เรียงตาม severity พร้อม:
  - **Exact file + line number**
  - **Vulnerable code snippet**
  - **Attack scenario** (step-by-step exploit)
  - **Proof of Concept** (curl/payload)
  - **OWASP category reference**
- Cross-service issues
- Summary table

---

### Step 2: สั่ง Defense Rebuttal (เปิด session ใหม่)

```
/red-team-rebuttal docs/security/red-team-round-01.md
```

#### สิ่งที่เกิดขึ้นเบื้องหลัง:

1. **Phase 0 — Onboarding:** Agent อ่าน `CLAUDE.md` → `SKILL.md` → security rules
2. **Phase 1 — Analysis:** วิเคราะห์ทุก finding → ตัดสิน Accept / Reject / Partial → pattern detection

3. **⏸️ HALT — รอ user approve**

   Agent จะแสดงตาราง:
   ```
   | # | Severity | Title                        | Verdict | Files to Fix     | Pattern Scope     |
   |---|----------|------------------------------|---------|------------------|-------------------|
   | 1 | CRITICAL | SQL Injection in search      | Accept  | content.repo.ts  | 3 files same pattern |
   | 2 | HIGH     | Missing rate limit on login  | Accept  | auth.controller   | 1 file            |
   | 3 | HIGH     | IDOR in user profile         | Partial | user.controller   | 2 endpoints       |
   | 4 | MEDIUM   | Verbose error messages       | Accept  | error.handler.ts  | global            |
   | 5 | LOW      | Missing CSP header           | Accept  | middleware.ts     | 1 file            |
   ```

   **User ตอบ:**
   - `proceed` → ดำเนินการตาม verdict
   - `reject finding 3, ที่เหลือ proceed` → ปรับเฉพาะจุด

4. **Phase 2 — Execution:** แก้ code ทีละ finding (7-step protocol) + cascade fixes
5. **Phase 3 — Update Docs:** อัปเดต `.claude/rules/security.md` + `05-security.md`
6. **Phase 4 — Write Defense Report**
7. **Phase 5 — Verification:** run tests ทั้งหมด
8. **Phase 6 — Report:** สรุปเป็นภาษาไทย

#### Output:
```
docs/security/defense-round-01.md
```

ประกอบด้วย:
- Summary (Accepted / Partial / Rejected counts)
- Security rules updated (new rules added to `.claude/rules/security.md`)
- Finding responses ทุก finding พร้อม evidence
- Cascaded fixes (same pattern fixed across multiple files)
- Strength assessment
- Recommendation (Ready for Production / Re-Audit / Needs Hotfix)

---

### Step 3: ทำซ้ำ (ถ้ายังไม่ผ่าน)

```
/red-team all
/red-team-rebuttal docs/security/red-team-round-02.md
```

- Round number auto-detect
- Anti-duplication rule — ไม่ raise finding ซ้ำที่ fix แล้ว
- แต่ถ้า fix ไม่สมบูรณ์จะ raise ใหม่

---

### Step 4: Production Ready

เมื่อ defense report ระบุ **"Ready for Production ✅"**:

- Code ผ่าน security audit แล้ว
- `.claude/rules/security.md` ถูก update ด้วย rules ใหม่
- `docs/design-docs/05-security.md` ถูก update ด้วย mitigations ใหม่
- Tests ครอบคลุม security regression

---

## OWASP Top 10 Quick Reference

| # | Category | ตรวจอะไร |
|---|----------|----------|
| A01 | Broken Access Control | IDOR, missing role checks, CORS misconfiguration |
| A02 | Cryptographic Failures | Weak hashing, missing encryption, hardcoded secrets |
| A03 | Injection | SQL injection, XSS, command injection |
| A04 | Insecure Design | Missing rate limiting, no abuse case handling |
| A05 | Security Misconfiguration | Default credentials, unnecessary features, verbose errors |
| A06 | Vulnerable Components | Outdated dependencies with known CVEs |
| A07 | Auth Failures | Weak passwords, missing MFA, session fixation |
| A08 | Data Integrity Failures | Missing integrity checks, insecure deserialization |
| A09 | Logging Failures | PII in logs, missing audit trail |
| A10 | SSRF | Unvalidated URLs, internal service access |

---

## File Structure

```
.claude/commands/
  red-team.md                       ← /red-team command definition
  red-team-rebuttal.md              ← /red-team-rebuttal command definition

.agents/skills/
  andm-red-team-attacker/SKILL.md        ← Attacker persona (Security Auditor)
  andm-red-team-defender/SKILL.md        ← Defender persona (Security Engineer)

.claude/rules/
  security.md                       ← Security rules (updated during defense)

docs/design-docs/
  05-security.md                    ← Security design doc (updated during defense)

docs/security/
  red-team-round-01.md              ← Round 1 findings
  defense-round-01.md               ← Round 1 fixes + responses
  red-team-round-02.md              ← Round 2 (ถ้ามี)
  defense-round-02.md               ← Round 2 fixes
```

---

## Agent Personas

### Red Team Attacker (`.agents/skills/andm-red-team-attacker/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Security Auditor / Penetration Tester |
| **Mindset** | break the code before attackers do |
| **Owns** | `docs/security/red-team-round-XX.md` |
| **Cannot modify** | source code — ผลิตแค่ report |
| **Key tool** | Code Security Attack Vector Checklist (20 categories) + PoC |

### Red Team Defender (`.agents/skills/andm-red-team-defender/SKILL.md`)

| Attribute | Value |
|-----------|-------|
| **Role** | Senior Security Engineer / Defense Specialist |
| **Mindset** | fix properly, not superficially — defense in depth |
| **Owns** | `docs/security/defense-round-XX.md` |
| **Can modify** | source code + `.claude/rules/security.md` + `05-security.md` |
| **Key tool** | 7-step vulnerability fix protocol + pattern detection |

---

## Escalation Triggers — เมื่อไหร่ควร Backtrack

ถ้า Red Team พบปัญหา security ที่ patch ใน code ไม่ได้เพราะเป็น fundamental design flaw:

| Trigger | ตัวอย่าง | Backtrack To | Action |
|---------|---------|-------------|--------|
| **Architecture flaw** | Auth design มี inherent vulnerability ที่ patch ไม่ได้ | SD | `/backtrack sd` |
| **Security model ไม่เพียงพอ** | Multi-tenant isolation ออกแบบผิด ต้อง redesign | SD | `/backtrack sd` |
| **Requirement สร้าง risk** | "เข้าถึงข้อมูลทุกคน" ขัดกับ data privacy regulation | BA | `/backtrack ba` |
| **Missing security requirement** | ไม่มี requirement เรื่อง audit trail ที่ compliance ต้องการ | BA | `/backtrack ba` |

> ⚠️ ถ้า vulnerability เกิดจาก design decision ที่ผิด → อย่าแค่ patch code, ต้อง backtrack แก้ design
> **📖 Guide:** `.agents/development-guide/backtrack-workflow.md`

---

## Tips

- **เปิด session ใหม่ทุกครั้ง** ที่สั่ง `/red-team` หรือ `/red-team-rebuttal`
- **Audit ทีละ service** สำหรับ deep scan (เช่น `services/api/`) หรือ **audit all** สำหรับ comprehensive
- **ตรวจ HALT point** ใน rebuttal — agent หยุดรอ approve ก่อนแก้ code
- **Pattern detection สำคัญมาก** — ถ้า agent พบ SQL injection 1 จุด จะ scan ทั้ง codebase หา pattern เดียวกัน
- **Security rules จะ grow** — ทุก round จะเพิ่ม rules ใน `.claude/rules/security.md` ป้องกันไม่ให้เกิดซ้ำ
- **ปกติ 2-3 rounds** เพียงพอสำหรับ code ที่เขียนตาม security rules ตั้งแต่แรก
- **Human review สำคัญ** — อย่าให้ loop จบโดย AI อนุมัติ AI กันเอง
