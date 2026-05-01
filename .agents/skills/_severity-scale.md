# Severity Classification Scale

> มาตรฐาน severity กลางที่ reviewer ทุกตัวใช้อ้างอิง
> แต่ละ persona จะมี **domain-specific examples** เพิ่มเติมใน SKILL.md ของตัวเอง

---

## Universal Severity Definitions

| Severity | Icon | Universal Definition | Exit Criteria Impact |
|----------|------|---------------------|---------------------|
| **CRITICAL** | 🔴 | **Blocks the next phase** — ถ้าไม่แก้ deliverable ส่งต่อไม่ได้ มีผลกระทบร้ายแรง (data loss, security breach, core logic ผิด, fundamental design flaw) | ต้องแก้ก่อนปิด review loop — ห้ามมี CRITICAL ค้าง |
| **HIGH** | 🟠 | **Significantly degrades quality** — ถ้าไม่แก้จะเกิดปัญหาจริงใน downstream phase (performance regression, missing critical coverage, vague spec ที่ต้อง guess) | ต้องแก้ก่อนปิด review loop — ห้ามมี HIGH ค้าง |
| **MEDIUM** | 🟡 | **Incomplete at scale, workaround exists** — ไม่ block แต่จะเป็นปัญหาเมื่อ scale หรือ edge case เกิด (missing edge case, partial error handling, gaps in documentation) | ควรแก้ถ้า effort สมเหตุสมผล — accept risk ได้ถ้า document reason |
| **LOW** | 🔵 | **Best practice violation, future risk** — ไม่กระทบ immediate delivery แต่สะสมเป็น debt (formatting, naming, missing non-critical docs, minor inconsistency) | Optional — fix ถ้าเร็ว, defer ได้ โดยไม่ต้อง document reason |

---

## Classification Rules

1. **ใช้ severity ตาม impact จริง** — ห้าม inflate เพื่อให้ดูร้ายแรง, ห้าม deflate เพื่อให้ผ่านง่าย
2. **CRITICAL/HIGH ต้องมี evidence** — quote exact text/code ที่เป็นปัญหา ห้ามบอกลอยๆ
3. **เมื่อ severity อยู่ระหว่างสองระดับ** — เลือกระดับสูงกว่า แล้ว defender จะ argue ลงได้ถ้าสมเหตุสมผล
4. **Domain context matters** — "CRITICAL" สำหรับ BA reviewer (blocks architecture handoff) ≠ "CRITICAL" สำหรับ red team (data breach) — ดู domain-specific examples ใน SKILL.md ของแต่ละ persona

---

## Per-Domain Interpretation

| Domain | CRITICAL means | HIGH means |
|--------|---------------|------------|
| **BA** | Blocks Architecture handoff — missing core requirement, contradictory business rules | Significantly impacts quality — vague NFR, untestable acceptance criteria |
| **SD** | Data loss, security breach, full outage, fundamental architecture flaw | Significant degradation under load, missing fallback, security gap |
| **TD** | Missing interface for cross-service call, DB schema contradicts API contract | Implementation ambiguity, cross-domain inconsistency |
| **UX** | Blocks implementation — engineer cannot implement at all | Engineer must guess — will implement incorrectly without fix |
| **Code** | Data loss, security breach, broken core business logic | Performance degradation under load, missing critical tests |
| **QA** | Missing coverage for critical business flow or security scenario | Significant coverage gap, untestable criteria |
| **Security** | Data breach, auth bypass, RCE, full system compromise | Privilege escalation, significant data exposure, DoS |

---

## การอ้างอิง

ทุก reviewer SKILL.md ควรเพิ่มบรรทัดนี้ก่อน Severity Classification Matrix:

```markdown
> 📊 Severity Scale: ดู `.agents/skills/_severity-scale.md` สำหรับ universal definitions + classification rules
```

domain-specific examples ใน SKILL.md ของแต่ละ persona ยังคงอยู่ — ไฟล์นี้เป็น supplement ไม่ใช่ replacement
