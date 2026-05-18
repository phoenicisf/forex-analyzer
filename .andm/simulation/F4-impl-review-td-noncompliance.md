# F4: Code Review พบ TD Non-Compliance → impl-review-fix

> Code Reviewer พบว่า code ไม่ตรงกับ TD spec — class structure ผิด, ใช้ pattern ไม่ตรง

---

## Context

- **สถานะ:** Phase 3C — Code Review หลัง sprint tasks เสร็จ
- **ปัญหา:** Engineer (AI) implement TaskService โดย inject Repository ตรงเข้า Controller แทนที่จะผ่าน Service layer ตามที่ TD `02-backend-design.md` กำหนด + ใช้ `DateTime` แทน `DateTimeOffset` ที่ `.claude/rules/api.md` กำหนด
- **Severity:** HIGH — architecture violation ที่ถ้าปล่อยไว้จะเป็น tech debt

---

## Timeline

### Code Review

```
Session: /impl-review all
```

**Agent (Code Reviewer) พบ — Dimension 9: Technical Design Compliance:**

```markdown
### Finding CR-01.2: 🟠 HIGH — Controller Bypasses Service Layer

**Location:**
- File: `services/api/src/Api/Endpoints/TaskEndpoints.cs`, line 24-31
- Reference: `docs/technical-design/02-backend-design.md`, Section: "API Layer Architecture"

**Problem:**
TD spec กำหนดว่า endpoint ต้องเรียกผ่าน MediatR handler:
  `Endpoint → MediatR Command/Query → Handler → Repository`

แต่ code เขียน:
  `Endpoint → Repository โดยตรง` (ข้าม Application layer)

```csharp
// ❌ Actual code (line 24-31)
app.MapPost("/api/tasks", async (AppDbContext db, CreateTaskRequest req) =>
{
    var task = new TaskEntity { Title = req.Title, ... };
    db.Tasks.Add(task);
    await db.SaveChangesAsync();
    return TypedResults.Created($"/api/tasks/{task.Id}", task);
});
```

TD spec ระบุ (02-backend-design.md, Section "CQRS Handlers"):
```
CreateTaskCommand → CreateTaskHandler → ITaskRepository → TaskEntity
```

**Why This Matters:**
- Business logic (validation, authorization, events) จะอยู่ใน Controller → ไม่ testable
- ไม่มี Result<T> pattern → error handling ใช้ exception flow
- ผิด Clean Architecture: Presentation layer ไม่ควร access Infrastructure โดยตรง

**Minimum Acceptable Fix:**
1. สร้าง `CreateTaskCommand` + `CreateTaskHandler` ใน Application layer
2. Endpoint เรียก `mediator.Send(new CreateTaskCommand { ... })`
3. Handler ใช้ `ITaskRepository` (ไม่ใช่ `AppDbContext` ตรง)

**Level of Effort:** Medium

---

### Finding CR-01.3: 🟡 MEDIUM — DateTime Instead of DateTimeOffset

**Location:**
- File: `services/api/src/Domain/Entities/TaskEntity.cs`, line 12-13
- Reference: `.claude/rules/api.md`, Section: "Database (EF Core + PostgreSQL)"

**Problem:**
```csharp
public DateTime CreatedAt { get; set; }  // ❌ DateTime
public DateTime? DueDate { get; set; }   // ❌ DateTime
```

Rules กำหนด: "Use `DateTimeOffset` for all timestamps (not `DateTime`)"
TD `04-database-design.md` ก็ระบุ column type เป็น `timestamptz` (= DateTimeOffset)

**Minimum Acceptable Fix:**
เปลี่ยนเป็น `DateTimeOffset` + สร้าง migration

**Level of Effort:** Low
```

### Code Review Fix

```
Session: /impl-review-fix docs/code-review/review-round-01.md
```

**Agent (Impl Engineer ใน fixing mode) แก้:**

```
Finding CR-01.2 (Controller bypasses service):
  1. สร้าง Application/Features/Tasks/Commands/CreateTask/CreateTaskCommand.cs
  2. สร้าง Application/Features/Tasks/Commands/CreateTask/CreateTaskHandler.cs
  3. สร้าง Application/Features/Tasks/Commands/CreateTask/CreateTaskValidator.cs
  4. แก้ TaskEndpoints.cs: endpoint เรียก mediator.Send()
  5. เพิ่ม unit test: CreateTaskHandlerTests.cs

Finding CR-01.3 (DateTime → DateTimeOffset):
  1. แก้ TaskEntity.cs: DateTime → DateTimeOffset
  2. สร้าง migration: AddDateTimeOffsetMigration
  3. Update existing tests ที่ใช้ DateTime
```

### Re-review

```
Session: /impl-review all
→ 0 CRITICAL/HIGH → ผ่าน ✅
```

---

## Workflow Commands Used

| Step | Command | Result |
|------|---------|--------|
| 1 | `/impl-review all` | พบ 1 HIGH + 1 MEDIUM (TD non-compliance) |
| 2 | `/impl-review-fix review-round-01.md` | Refactor to match TD spec |
| 3 | `/impl-review all` | ผ่าน ✅ |

---

## Methodology Verdict

✅ **PASS** — Code Review Dimension 9 (TD Compliance) จับ design violation ได้
- ก่อนมี TD: code review ตรวจได้แค่ "code quality" ไม่รู้ว่า design กำหนดอะไรไว้
- หลังมี TD: code review เทียบ code กับ TD spec ตรงๆ — จับ pattern violation ได้
- Fix มี clear target: "ตาม `02-backend-design.md` Section CQRS Handlers"
- Engineer ไม่ต้อง guess ว่าจะ refactor ไปทางไหน — TD เป็น blueprint
