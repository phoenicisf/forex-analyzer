# ANDM Full Track Simulation Scenarios

> Methodology-level documentation — จำลองสถานการณ์จริงเพื่อทดสอบว่า Full Track รองรับทุก workflow case

## Purpose

Simulation files อยู่ภายใต้ methodology folder เพราะเป็น **methodology documentation** — แสดงว่า commands + workflows ของ Full Track จัดการ situation ต่างๆ อย่างไร ไม่ใช่ project deliverable

## Reference System

**TaskFlow** — ระบบจัดการงานสำหรับทีม (Jira/Linear ย่อส่วน)
- Tech stack: Next.js 15 + C# .NET 9 API + PostgreSQL + Redis + Python Worker

## Index

### Success Flows (Happy Path)

| ID | Title | Commands Demonstrated |
|----|-------|----------------------|
| S1 | Full lifecycle — BA → SD → UX → TD → Impl → Harden → Deliver | All 22 commands |
| S2 | Mid-design amendment — เพิ่ม feature หลังทำ BA เสร็จ | `/amend ba` |
| S3 | UX Stitch greenfield (SD-only) — prototype UI โดยไม่มี BA | `/ux-design stitch` |
| S4 | Multi-agent implementation — 3 agents ทำ parallel | `/impl-task` × parallel |
| S5 | Stitch + DESIGN.md reference | `/ux-design reference` |
| **S6** | **Post-MVP Continuous Improvement — major epic หลัง MVP ship** | `/amend` cascade + `/impl-plan` delta + narrow `/red-team` |

### Failure Flows (Recovery Path)

| ID | Title | Commands Demonstrated |
|----|-------|----------------------|
| F1 | BA Review พบ requirement ขัดแย้ง → rebuttal loop | `/ba-review`, `/ba-rebuttal` |
| F2 | TD Review พบ API↔DB inconsistency → cross-domain fix | `/td-review`, `/td-rebuttal` |
| F3 | Implementation พบ SD architecture infeasible → `/backtrack sd` | `/backtrack` |
| F4 | Code Review พบ TD non-compliance → `/impl-review-fix` | `/impl-review-fix` |
| F5 | Red Team พบ critical vulnerability → `/backtrack td` | `/backtrack td` |
| F6 | UX missing state → `/backtrack ux` แล้ว `/amend td` ตาม | `/backtrack ux`, `/amend td` |
| F7 | Client เปลี่ยน requirement กลางทาง → `/amend ba` cascade | `/amend` chain |
| F8 | Stitch generate เจอ API gap → `/backtrack sd` เพิ่ม endpoint | `/backtrack sd` |
| **F9** | **Cap-3 Decision Gate + IMPL-FIX Sibling Ban + Sample-Walk** (2026-05-17 retro additions) | `/impl-task` Phase 1.3.3, `/impl-plan-review`, `/next` Check 5.8/5.9 |

## File Layout

```
.andm/simulation/
├── README.md                              ← this file
├── 00-scenario-overview.md                ← scenario map + reading guide
├── S1-full-lifecycle-success.md
├── S2-mid-design-amendment.md
├── S3-ux-stitch-greenfield-sd-only.md
├── S5-stitch-with-design-md-reference.md
├── S6-post-mvp-continuous-improvement.md
├── F1-ba-review-conflict.md
├── F2-td-cross-domain-inconsistency.md
├── F3-backtrack-sd-from-impl.md
├── F4-impl-review-td-noncompliance.md
├── F5-redteam-backtrack-td.md
├── F6-ux-missing-state-cascade.md
├── F7-client-change-requirement.md
└── F8-stitch-api-gap-backtrack-sd.md
```

## Adding a New Scenario

1. เขียนไฟล์ใหม่ในนี้ (`.andm/simulation/`) — canonical location
2. Update index ใน README นี้ + `00-scenario-overview.md`
3. Follow existing format: Context → Timeline → Methodology Verdict + Gaps
