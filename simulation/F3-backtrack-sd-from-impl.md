# F3: Implementation พบ SD Architecture Infeasible → /backtrack sd

> ระหว่าง implement WebSocket สำหรับ kanban real-time พบว่า architecture ที่ออกแบบไว้ไม่รองรับ

---

## Context

- **สถานะ:** Phase 3 กำลัง implement — ทำ IMPL-005 (Kanban WebSocket) อยู่
- **ปัญหา:** SD ออกแบบให้ Web เรียก API ผ่าน REST แล้ว API broadcast ผ่าน WebSocket แต่ตอน implement พบว่า C# .NET Minimal API + SignalR ต้อง share state กับ Redis pub/sub ซึ่ง SD ไม่ได้ออกแบบ Redis pub/sub topology ไว้ — ใช้ Redis แค่เป็น cache
- **ทำไมแก้ local ไม่ได้:** เพิ่ม Redis pub/sub เป็น architecture decision ที่กระทบ ADR-002 (Redis usage) + infra design + cost estimation

---

## Timeline

### ระหว่าง impl-task IMPL-005

```
Session: /impl-task IMPL-005
Agent:   กำลัง implement SignalR hub สำหรับ kanban board
Problem: SignalR needs Redis backplane for multi-instance scaling
         แต่ ADR-002 ระบุ Redis ใช้แค่ cache (TTL-based)
         ถ้าเพิ่ม pub/sub จะเปลี่ยน Redis role → architecture decision

Agent report:
  "⚠️ ไม่สามารถ implement IMPL-005 ต่อได้ — ต้องเปลี่ยน Redis role จาก cache-only 
   เป็น cache + pub/sub ซึ่งเป็น architecture decision ที่อยู่นอก scope ของ andm-impl-engineer
   แนะนำ: /backtrack sd"
```

### User สั่ง /backtrack sd

```
Session: /backtrack sd
```

**Agent (Backtrack) ทำ Impact Analysis:**

```markdown
## 🔄 Backtrack Impact Analysis

**Trigger:** IMPL-005 ต้องใช้ Redis pub/sub สำหรับ SignalR backplane แต่ ADR-002 กำหนด Redis เป็น cache-only
**Current Phase:** Phase 3 (Implement) — IMPL-005 in progress
**Backtrack Target:** Phase 1B (System Design)
**Source:** andm-impl-engineer report during IMPL-005

### Scope of Change
- ADR-002: เปลี่ยน Redis role จาก "cache only" → "cache + message broker (pub/sub)"
- 02-high-level-architecture.md: update infra diagram — Redis มี 2 roles
- 03-deep-dive.md: เพิ่ม section SignalR + Redis backplane configuration
- 05-security.md: เพิ่ม Redis pub/sub channel security (ถ้ามี sensitive data)

### Impacted Deliverables

| Phase | Deliverable | Exists? | Impact | Action Needed |
|-------|-------------|---------|--------|---------------|
| SD | docs/design-docs/02-high-level-architecture.md | ✅ | ❌ Re-run | Update infra diagram |
| SD | docs/design-docs/03-deep-dive.md | ✅ | ❌ Re-run | Add SignalR backplane section |
| SD | docs/adr/002-redis-usage.md | ✅ | ❌ Re-run | Update decision: cache + pub/sub |
| TD | docs/api-specs/*.yaml | ✅ | ⚠️ Re-validate | WebSocket contract อาจเปลี่ยน |
| TD | docs/technical-design/02-backend-design.md | ✅ | ❌ Re-run | SignalR hub + Redis backplane config |
| Impl | docs/state/impl-plan.md | ✅ | ⚠️ Re-validate | IMPL-005 scope อาจเปลี่ยน |
| Impl | services/api/ | ✅ | ⚠️ Re-validate | Code ที่ทำไปแล้ว (IMPL-001 ถึง IMPL-004) น่าจะ OK |

### Risk of NOT Backtracking
- ถ้า hardcode Redis pub/sub โดยไม่ update ADR → future developer จะสับสนว่า Redis ใช้ทำอะไร
- ถ้า single-instance deploy ก่อนแล้วค่อยเพิ่ม pub/sub → ต้อง refactor SignalR hub ทีหลัง
- Production scaling จะพัง ถ้า 2+ API instances ไม่มี shared Redis backplane
```

### ⏸️ HALT — User approve

> User: "approve — แก้ SD + ADR แล้ว cascade ไป TD"

### Backtrack Execution

```
Step 1: Record — สร้าง BT-001 ใน docs/state/backtrack-log.md
Step 2: Update overview — SD = 🔄 BACKTRACK, TD = ⚠️ Pending re-validation

แนะนำ:
1. เปิด session ใหม่ → /amend sd "เปลี่ยน Redis role จาก cache-only เป็น cache + pub/sub สำหรับ SignalR backplane, update ADR-002, เพิ่ม Redis backplane config ใน 03-deep-dive"
2. Re-run: /sd-review all
3. Re-run: /sd-rebuttal [latest]
4. จากนั้น: /amend td "update 02-backend-design SignalR hub config ให้ใช้ Redis backplane"
5. Re-run: /td-review all
6. กลับมา: /impl-task IMPL-005 (resume)
```

### Execute Recovery

```
Session A: /amend sd "เปลี่ยน Redis role เป็น cache + pub/sub, update ADR-002, เพิ่ม SignalR backplane ใน 03-deep-dive"
  → แก้ 3 ไฟล์: ADR-002, 02-high-level, 03-deep-dive

Session B: /sd-review all
  → 1 finding (LOW: missing Redis pub/sub channel naming convention) → ผ่าน

Session C: /amend td "update 02-backend-design: เพิ่ม SignalR hub class + Redis backplane DI config, update 06-sequence-diagrams: เพิ่ม pub/sub flow"
  → แก้ 2 ไฟล์: 02-backend-design, 06-sequence-diagrams

Session D: /td-review all
  → 0 CRITICAL/HIGH → ผ่าน

Session E: /impl-task IMPL-005 (resume)
  → implement SignalR + Redis backplane ตาม TD ที่ update แล้ว ✅
```

### Close Backtrack

```
Update docs/state/backtrack-log.md:
  BT-001 Status: ✅ Resolved
  Resolution: Redis role expanded, ADR-002 updated, TD updated, IMPL-005 resumed
```

---

## Workflow Commands Used

| Step | Command | Result |
|------|---------|--------|
| 1 | `/impl-task IMPL-005` | พบปัญหา architecture → แนะนำ backtrack |
| 2 | `/backtrack sd` | Impact analysis + record BT-001 |
| 3 | `/amend sd "..."` | แก้ SD docs + ADR |
| 4 | `/sd-review all` | Verify SD changes |
| 5 | `/amend td "..."` | Cascade fix ไป TD |
| 6 | `/td-review all` | Verify TD changes |
| 7 | `/impl-task IMPL-005` | Resume implementation ✅ |
| **Total** | **7 sessions** | **Recovery ~0.5 day** |

---

## Methodology Verdict

✅ **PASS** — Backtrack + Amend + Resume workflow รองรับเคสนี้ครบ
- andm-impl-engineer ตรวจจับได้ว่าปัญหาอยู่นอก scope (architecture decision)
- `/backtrack sd` ทำ impact analysis อัตโนมัติ + HALT ให้ human approve
- `/amend sd` แก้เฉพาะจุดที่กระทบ (ไม่ rewrite ทั้ง SD)
- Cascade ไป TD ผ่าน `/amend td`
- Resume impl-task ได้ทันทีหลัง fix
- Backtrack log เป็น audit trail
