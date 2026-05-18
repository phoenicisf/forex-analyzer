# Workflow Simulation Scenarios — Overview

> จำลองสถานการณ์จริงในวงการพัฒนาซอฟต์แวร์ เพื่อทดสอบว่า methodology รองรับทุกเคสหรือไม่

## ระบบที่ใช้จำลอง

**ระบบ:** TaskFlow — ระบบจัดการงานสำหรับทีม (เหมือน Jira/Linear ย่อส่วน)
**Tech Stack:** Next.js 15 + C# .NET 9 API + PostgreSQL + Redis

---

## Scenario Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SUCCESS FLOWS (Happy Path)                       │
├─────────────────────────────────────────────────────────────────────┤
│ S1: Full lifecycle — BA → SD → UX → TD → Impl → Red Team          │
│ S2: Mid-design amendment — เพิ่ม feature หลังทำ BA เสร็จ             │
│ S3: UX Stitch greenfield (SD-only) — prototype UI โดยไม่มี BA       │
│ S4: Multi-agent implementation — 3 agents ทำ parallel               │
│ S5: Stitch + DESIGN.md reference — augment Stitch ด้วย user-supplied DESIGN.md │
│ S6: Post-MVP Continuous Improvement — major epic หลัง MVP ship      │
├─────────────────────────────────────────────────────────────────────┤
│                    FAILURE FLOWS (Recovery Path)                    │
├─────────────────────────────────────────────────────────────────────┤
│ F1: BA Review พบ requirement ขัดแย้ง → rebuttal loop               │
│ F2: TD Review พบ API↔DB inconsistency → cross-domain fix           │
│ F3: Implementation พบ SD architecture infeasible → /backtrack sd    │
│ F4: Code Review พบ TD non-compliance → impl-review-fix             │
│ F5: Red Team พบ critical vulnerability → /backtrack td             │
│ F6: UX missing state → /backtrack ux แล้ว /amend td ตาม           │
│ F7: Client เปลี่ยน requirement กลางทาง → /amend ba cascade         │
│ F8: Stitch generate เจอ API gap → /backtrack sd เพิ่ม endpoint    │
└─────────────────────────────────────────────────────────────────────┘
```

## วิธีอ่าน

แต่ละ scenario มี:
1. **Context** — สถานการณ์ที่เกิด
2. **Timeline** — ลำดับเหตุการณ์
3. **Workflow Commands** — คำสั่งที่ใช้แก้ปัญหา
4. **Expected Outcome** — ผลลัพธ์ที่ควรได้
5. **Methodology Verdict** — workflow รองรับหรือไม่

---

## Canonical Location

Simulation เป็น **methodology documentation** ไม่ใช่ project output — อยู่ภายใต้ methodology folder โดยตรง:

- **Full Track scenarios** → `.andm/simulation/` (this folder, in the Full Track methodology)
- **Ship Track scenarios** → `.andm/simulation/` in the Ship Track methodology
- ~~**Lean Track scenarios**~~ → Lean Track retired 2026-05-10 (recoverable via git history)

> **Migration note (2026-04):** ไฟล์ทั้งหมดย้ายมาจาก `docs/.andm/simulation/` เดิม — `docs/` เป็น project output dir ไม่เหมาะเก็บ methodology docs
