# Technical Design Claim Review Round 02

| Field | Value |
|-------|-------|
| **Round** | 02 |
| **Target Document** | rebuttal verification (`rebuttal-round-01.md` — sweep across TD-02 / TD-03 / TD-04 + cascade docs) |
| **Date** | 2026-05-02 |
| **Reviewer Persona** | Technical Design Reviewer (Adversarial Engineer) |
| **SKILLs Used** | architecture, software-architecture, api-patterns, database-design |
| **Round-01 baseline** | 20 claims, 100% Accept; 9 files modified per `rebuttal-round-01.md` |

## Severity Summary

| Severity | Count |
|----------|-------|
| 🔴 CRITICAL | 1 |
| 🟠 HIGH | 2 |
| 🟡 MEDIUM | 5 |
| 🔵 LOW | 1 |
| **Total** | **9** |

> **Verdict orientation:** ทุก finding ที่นี่เป็น **regression / cascade-incomplete จาก round-01 fix**, ไม่ใช่ duplicate ที่ rebuttal-01 ปิดไปแล้ว. Round-01 100% accept rate ทำให้ defender ทำ broad rewrite (3 core class skeletons + OnInit 3-phase rewrite + 9-file cascade); 9 finding ที่นี่ = side-effect ของ broad rewrite ที่ไม่ได้ self-validate ครบ. Severity ceiling ลดจาก 5 CRITICAL → 1 CRITICAL = **convergence** (ไม่ใช่ regression in correctness, แต่เป็น cascade tail).

---

## Technical Design Attack Vector Checklist

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | API Reference in Backend Design | ✅ Pass | TD-02 § 10.1 + § 10.2 cross-domain matrix correct; trade-journal-schema halt_reason enum updated round-01 |
| 2 | Backend Module Boundaries | ✅ Pass | 5-layer split (core/slots/services/domain/helpers) + 3 core classes added round-01 ครบ |
| 3 | Backend Interface Contracts | ⚠️ Finding | RiskManager Init signature drift in DI map (Claim 02.6); helper Init phantom calls (Claim 02.2) |
| 4 | CQRS/Command-Query Separation | ✅ N/A | No CQRS chosen by SD |
| 5 | Frontend Component Hierarchy | ✅ N/A | TD-03 N/A justified |
| 6 | Frontend State Management | ✅ N/A | TD-03 N/A justified |
| 7 | Frontend-Backend Contract Alignment | ✅ N/A | TD-03 N/A; state/journal field map → operator surface trace ✅ |
| 8 | Database Schema Completeness | ✅ Pass | TD-04 § 3 17-magic count + journal record 11-required + GV mirror 5 entries ครบ |
| 9 | Database Index Strategy | ✅ Pass | rotation policy + per-run namespace + Phase 2 SQLite migration plan ครบ |
| 10 | Database Migration Safety | ✅ Pass | § 7 backward-compat table preserves v1 read path |
| 11 | Design Pattern Justification | ✅ Pass | All patterns trace to ADR; AtomicFile dispatcher honesty correction round-01 ครบ |
| 12 | Sequence Diagram Coverage | ✅ Pass | § 12.1/12.2/12.3/12.4 cover BI SL / Save+GV / pending force-clear / Load GV-fallback |
| 13 | Sequence Diagram Accuracy | ✅ Pass | Method names match service skeletons after round-01 |
| 14 | Testability in TD-02/03/04 | ⚠️ Finding | OnInit Phase B fail-rollback path undocumented (Claim 02.10) |
| 15 | TD↔QA Alignment | ✅ Pass | DoD 4-gate ครบ; standard tester.ini library committed |
| 16 | Cross-Domain Consistency | ⚠️ Finding | Round-01 17-magic cascade incomplete: SD `02 § 1.3` line 99 + SD `03 § 7` A1 + TD-04 § 10 caption (Claims 02.3, 02.7, 02.8) |
| 17 | Security at Detail Level | ✅ Pass | No new attack surface introduced by round-01 fix |
| 18 | Error Handling Strategy | ⚠️ Finding | Logger escalation semantic drift vs ADR-011 "consecutive ticks" (Claim 02.9) |
| 19 | Implementation Readiness | ⚠️ Finding | OnInit pseudocode contains compile-blockers: phantom Init() calls + missing arg + undeclared accessors (Claims 02.1, 02.2, 02.4, 02.5) |
| 20 | (reserved) | — | — |

---

## Findings

### Claim 02.1: 🟠 HIGH — `m_risk.Init(...)` ใน OnInit pseudocode ขาด `m_portfolio` parameter

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase B (line 1620)
- Cross-reference: § 5.4 RiskManager class (line 586-587)

**Problem:**
Round-01 Claim 01.10 fix updated § 5.4 RiskManager `Init` signature to `Init(double main_risk_ratio, double limit_max_lot_size_ratio, CPortfolioState *port, CLogger *logger)` (4 args; เพิ่ม `port` เพราะ J/BI/I formulas require parent slot read). แต่ § 7.4 OnInit Phase B line 1620 ยังเรียก `m_risk.Init(InpFIDValue / InpMainRiskRatio, InpLimitMaxLotSizeRatio, m_logger);` = **3 args** (ขาด `m_portfolio`). DI map row 10 ก็ระบุ `(Logger)` only — ไม่มี PortfolioState (Claim 02.6 cascade). Round-01 rebuttal text ระบุ "RiskManager Init dependencies updated — DI map § 7.3 row 10 implicitly updated to add PortfolioState" แต่ explicit edit ไม่ได้เกิดขึ้น.

**Why This Matters:**
Engineer copy OnInit pseudocode → MetaEditor compile fail with `'Init' - cannot determine function. CRiskManager::Init(double,double,CLogger*) has no overload`. G1 gate (compile) ไม่ผ่าน. นี่คือ **regression introduced by round-01 fix** — ไม่ใช่ pre-existing bug. Engineer ต้องเดาว่า port มาจากไหน (m_portfolio) + ทำไมถึงต้องการ → defeats "engineer หยิบไป code ได้ทันที" purpose.

**Minimum Acceptable Fix:**
1. § 7.4 line 1620 — เพิ่ม `m_portfolio` argument: `m_risk.Init(InpFIDValue / InpMainRiskRatio, InpLimitMaxLotSizeRatio, m_portfolio, m_logger);`
2. ตรวจ Init order: line 1620 อยู่หลัง `m_portfolio.Init(m_logger)` (line 1616) แล้ว ✅ — ไม่ต้องย้าย
3. Update § 7.3 row 10 — `(Logger)` → `(PortfolioState, Logger)` per Claim 02.6

**Level of Effort:** Low

---

### Claim 02.2: 🟠 HIGH — OnInit pseudocode เรียก `Init()` ที่ helper class skeleton ไม่ได้ declare (3 instances)

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase B (lines 1611-1613)
- Cross-references:
  - § 4.2 CCommentParser class (lines 384-397)
  - § 4.3 CJsonWriter class (lines 404-422)
  - § 4.4 CAtomicFile class (lines 431-455)

**Problem:**
Round-01 Claim 01.7 OnInit 3-phase rewrite added explicit Init calls สำหรับทุก service. แต่ helper class skeletons § 4.2, § 4.3, § 4.4 **ไม่ declare `Init()` method** — เป็น stateless utility class ที่ยังไม่มี Init contract:

```mql5
// Line 1611: m_comment.Init();    // CCommentParser § 4.2 ไม่มี Init()
// Line 1612: m_json.Init();       // CJsonWriter § 4.3 ไม่มี Init()
// Line 1613: m_atomic.Init(m_logger);  // CAtomicFile § 4.4 ไม่มี Init()
```

`CCommentParser` declared methods: `Build` / `ExtractSlotPrefix` / `FilterTicketsByPrefix` (3 stateless methods). `CJsonWriter` declared: `Begin` / `End` / `Write*` (per-use builder pattern, stateless across instances). `CAtomicFile` declared: `WriteAtomic_TempRename` / `CleanupOrphanTmp` / `WriteAtomic_DoubleBuffered` / `ReadActiveBuffered` / `WriteAtomic` (5 stateless dispatcher methods, each takes logger as parameter — ไม่ต้อง store).

**Why This Matters:**
Compile fail × 3 ที่ G1 gate. Engineer ต้องตัดสินใจ: (1) เพิ่ม Init() เปล่า ลง skeleton (false consistency), หรือ (2) ลบ 3 calls ออกจาก OnInit (correct path). ไม่มี doc guidance. นี่คือ **regression introduced by round-01 fix** — Phase B 3-phase rewrite assumed all services have uniform `Init(...)` contract แต่ helpers จงใจไม่มี (logger/state ไม่เก็บ field; pass-through pattern). Implementation Readiness G19 ผิดจริงจังเพราะ engineer ไม่รู้ว่า helpers ต้อง init หรือไม่.

**Minimum Acceptable Fix:**
- **Option A (recommended):** Remove 3 phantom calls from § 7.4 — helpers stateless ไม่ต้อง Init:
  ```mql5
  // ลบ: m_comment.Init();    m_json.Init();    m_atomic.Init(m_logger);
  // เพิ่ม comment ระบุ: "// Helpers (CommentParser, JsonWriter, AtomicFile) = stateless utility — no Init needed per § 4 § Helpers"
  ```
- **Option B:** เพิ่ม `Init()` no-op declaration ลง helper skeletons (false uniformity but mechanical)
- ทั้งสอง option ต้อง update § 7.3 DI map ที่ row 3-5 (CCommentParser/CJsonWriter/AtomicFile) หรือลบ row ออกถ้าเลือก Option A

**Level of Effort:** Low

---

### Claim 02.3: 🔴 CRITICAL — Round-01 17-magic cascade ไม่ครอบคลุม SD `02-high-level-architecture.md` § 1.3 BR Traceability table

**Location:**
- File: `docs/design-docs/02-high-level-architecture.md`, Section: § 1.3 BR Traceability (line 99)
- Quoted text: `| BR-1.1 | Magic Number Pool (16 magic, 21 slots, shared G/G2 + B/BI + C/D + L/LX) | 'domain/EnumTypes::MagicByEnum()' constants |`

**Problem:**
Round-01 Claim 01.1 cascade ตั้งใจครอบคลุม **5 docs** (TD-02 § 5.3 + § 10.1, TD-04 § 3.2/3.6/3.9/§10, ADR-005, state-persistence-schema.yaml, + BootstrapValidator skeleton). แต่ SD `02-high-level-architecture.md` line 99 ยังคง **"16 magic"** — เป็น BR Traceability matrix ของ SD-as-Master document (per `state/overview.md` line 11: "v1.2: gaps 01/06 — merged into 02 as Top Traceability"). คาดว่า defender มอง TD-04 § 3 + ADR-005 + schema.yaml เป็น "downstream" ของ SD แต่ลืม update ต้นทาง SD line นี้.

**Cross-domain leak evidence:**
1. `docs/design-docs/02-high-level-architecture.md:99` ระบุ "16 magic"
2. `docs/design-docs/03-deep-dive.md:346` ระบุ A1 risk "~16 keys" (Claim 02.7 cascade)
3. `docs/technical-design/02-backend-design.md` § 5.3 line 542 + § 7.4 line 1658 + § 10.1 line 2085 ระบุ **17** ✅ (round-01 fixed)
4. `docs/api-specs/state-persistence-schema.yaml` line 129 ระบุ **17** ✅ (round-01 fixed)
5. `docs/adr/005-portfoliostate-via-chashmap.md:67` ระบุ **17** ✅ (round-01 fixed)
6. `docs/technical-design/04-database-design.md:521` ระบุ **17** ✅ + line 651 caption "× 16" ❌ (Claim 02.8 cascade)

= **3 docs ยังผิด** (SD-02 / SD-03 / TD-04 caption) vs **5 docs ถูก** ใน round-01 fix. **Cascade incomplete by 3/8 = 37%.**

**Why This Matters:**
SD `02 § 1.3 BR Traceability` คือ **Top Traceability matrix** ที่ Impl Planner + Code Reviewer + QA reads first per `state/overview.md` line 11 ("Top: Requirements Traceability for requirement coverage"). Engineer reading SD-02 ก่อน TD-02 จะ assume 16 magic + เริ่ม code BootstrapValidator ที่ assert `expected=16` → INIT_FAILED runtime (because PortfolioState.MagicCount() returns 17 per fixed BR-1.1). Worst case: engineer "fix" PortfolioState ให้ skip 1 magic ตามที่ SD บอก = ทำลาย BR-1.1 invariant. **CRITICAL** เพราะเป็น cross-domain cascade leak ที่หลงเหลือใน authoritative source-of-truth doc.

**Minimum Acceptable Fix:**
1. SD `02-high-level-architecture.md:99` — แก้ `(16 magic, 21 slots, ...)` → `(17 magic, 21 slots, shared groups: C/D + G/G2 + B/BI + L/LX merge 4 groups, magic pool: 200, 201, 205-219)` พร้อม cross-reference ADR-005
2. SD `03-deep-dive.md:346` — แก้ A1 risk `~16 keys` → `~17 keys` (Claim 02.7 cascade)
3. TD-04 § 10 caption (line 651) — แก้ `SLOT_STATE × 16` → `SLOT_STATE × 17` (Claim 02.8 cascade)
4. Run **regression grep:** `grep -rn "16 (magic|key|entr|distinct)" docs/` — ต้องคืน 0 hits ใน design-docs / technical-design / api-specs / adr (BA + foundation-input-sources ยกเว้น)
5. Escalate ผ่าน `/backtrack sd` ทำ formal SD cascade fix per Phase Contract (TD ไม่มี authority แก้ SD docs ทาง direct edit)

**Level of Effort:** Low (3 line edits) แต่ requires `/backtrack sd` workflow per Phase Contract

---

### Claim 02.4: 🟡 MEDIUM — `m_state.StatePath()` accessor undeclared ใน CStatePersistence skeleton

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase C (line 1643)
- Cross-reference: § 5.6 CStatePersistence class (lines 748-803)

**Problem:**
§ 7.4 line 1643 เรียก `m_atomic.CleanupOrphanTmp(m_state.StatePath(), m_logger);` — ใช้ `StatePath()` accessor ที่ § 5.6 CStatePersistence class **ไม่ declare**. § 5.6 มี private fields `m_state_dir` + `m_state_path` แต่ไม่ expose ผ่าน public accessor. Round-01 Claim 01.7 OnInit rewrite assumed accessor exists.

**Why This Matters:**
Compile fail ที่ Phase C (orphan tmp cleanup ของ ADR-007 § Recovery contract). G1 gate fail. Engineer อาจ work around โดย hardcode path string → break encapsulation (StatePersistence owns path; AtomicFile only consumes). NFR-3.4 transparency ที่ Recovery flow ผิดเพราะ CleanupOrphanTmp ไม่ได้ call จริง = orphan .tmp file เก่าอยู่ตลอด → eventually disk fill + journal write fail (ADR-006 RPO escalation chain).

**Minimum Acceptable Fix:**
§ 5.6 — เพิ่ม public accessor:
```mql5
// Path accessor — used by Orchestrator Phase C orphan tmp cleanup (ADR-007 § Recovery)
string StatePath() const { return m_state_path; }
string StateDir() const { return m_state_dir; }
```

**Level of Effort:** Low

---

### Claim 02.5: 🟡 MEDIUM — `m_indicators.HandleCount()` accessor undeclared ใน CIndicatorService skeleton

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase C (line 1664)
- Cross-reference: § 5.1 CIndicatorService class (lines 474-505)

**Problem:**
§ 7.4 line 1664 ใช้ `m_indicators.HandleCount()` ใน `init_ok` log message:
```mql5
m_logger.Info("system", "init_ok", 0,
              StringFormat("handles=%d slots=21 magics=17 state=%s",
                           m_indicators.HandleCount(), EnumToString(m_state_enum)));
```
แต่ § 5.1 CIndicatorService class declares: `Init / CreateHandles / Refresh / AnyHandleInvalid / CachedScan / ReleaseHandles / GetHandle(int)` — **ไม่มี HandleCount() accessor**. Private field `m_handle_count` อยู่แต่ไม่ expose.

**Why This Matters:**
Compile fail ที่ Phase C end (final init_ok log line). Engineer copy → workaround โดย hardcode "25" ที่ comment "// ~25 used per ADR-003" — but ที่จริงแล้ว ADR-003 + TD spike Phase 1D lock count exact, ค่า hardcode ผิด = log message misleading. Observability degraded (NFR-3.4 transparency for boot status). G2 gate (smoke check) ไม่ Pass strictly per § 13.1.

**Minimum Acceptable Fix:**
§ 5.1 — เพิ่ม public accessor:
```mql5
// Handle count accessor — used by Orchestrator init_ok log message
int HandleCount() const { return m_handle_count; }
```

**Level of Effort:** Low

---

### Claim 02.6: 🟡 MEDIUM — DI map § 7.3 row 10 (RiskManager) ไม่ sync กับ § 5.4 Init signature

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.3 DI wire-up map (line 1583 row 10)
- Cross-reference: § 5.4 CRiskManager class (lines 586-587), § 7.4 line 1620

**Problem:**
Round-01 Claim 01.10 fix added `CPortfolioState *m_portfolio` field + `port` parameter ลง § 5.4 RiskManager Init. § 7.3 row 10 ยังคง `| 10 | 'CRiskManager' | (Logger) | |` — ไม่ระบุ PortfolioState dep. Round-01 rebuttal text ระบุ "DI map § 7.3 row 10 implicitly updated to add PortfolioState" แต่ implicit ≠ explicit + reviewer ที่อ่าน DI map standalone จะ assume Logger only.

**Why This Matters:**
DI map = single source-of-truth สำหรับ Init order ของ Orchestrator. ถ้า map ผิด — engineer/AI agent ที่ generate composition root code automatically (per § 7.3 explicit table contract) จะ generate `m_risk.Init(InpFIDValue/InpMainRiskRatio, InpLimitMaxLotSizeRatio, m_logger)` (3 args) = compile fail (= Claim 02.1 root cause). Two-source drift ที่ ห้ามมี per `td.md § Phase 3.5 Quality Gate § Cross-Domain Consistency`.

**Minimum Acceptable Fix:**
§ 7.3 row 10 — แก้ `(Logger)` → `(PortfolioState, Logger)`. + Add note "see § 5.4 line 586: RiskManager dispatches J/BI/I formulas via PortfolioState parent slot read".

**Level of Effort:** Low

---

### Claim 02.7: 🟡 MEDIUM — SD `03-deep-dive.md` § 7 A1 risk text ระบุ "~16 keys" (Claim 01.1 cascade incomplete)

**Location:**
- File: `docs/design-docs/03-deep-dive.md`, Section: § 7 Open technical risks (line 346)
- Quoted text: `⚠️ A1 — 'CHashMap' perf at ~16 keys per OnTick frequency | TD spike Phase 1D | ...`

**Problem:**
A1 risk row ระบุ "~16 keys" แต่ ADR-005 + TD-04 + state-persistence-schema lock 17 magics. Performance spike per IMPL ที่ test CHashMap ที่ N=16 ≠ N=17 (1 entry difference negligible แต่ cascade text ผิด).

**Why This Matters:**
QA Phase 3T spike (per ADR-005 § Revisit-when) reads SD-03 § 7 A1 row → run benchmark with N=16 → finishing finding "perf OK at 16" → engineer ship → runtime hit 17 entries → 1 extra hash bucket lookup + 1 collision — likely irrelevant แต่ contract drift remains. Cross-domain consistency gate fail (Cat 16). MEDIUM severity เพราะ runtime impact = negligible (1 entry); doc drift remain.

**Minimum Acceptable Fix:**
SD `03-deep-dive.md:346` — แก้ `~16 keys` → `~17 keys` + cross-reference Claim 02.3 cascade. ทำผ่าน `/backtrack sd` workflow (TD ไม่ direct edit SD).

**Level of Effort:** Low

---

### Claim 02.8: 🔵 LOW — TD-04 § 10 ER diagram caption ระบุ "SLOT_STATE × 16" (stale text)

**Location:**
- File: `docs/technical-design/04-database-design.md`, Section: § 10 Mermaid erDiagram caption text (line 651)
- Quoted text: `STATE_ROOT (= state.json) มี 6 sub-object 1:1 + 2 collections (PENDING_MACHINE × 8, **SLOT_STATE × 16**).`

**Problem:**
ER diagram itself (line 521) ระบุ `STATE_ROOT ||--o{ SLOT_STATE : "17 entries by magic"` — round-01 fixed ✅. แต่ caption text **ใต้** diagram ที่ describe diagram ระบุ "× 16" — text ลืม update.

**Why This Matters:**
Diagram + caption mismatch ทำให้ reviewer สงสัย: ตกลงเป็น 16 หรือ 17? Drift trivial แต่ violation ของ Cat 16 cross-domain consistency gate. LOW severity เพราะ engineer follow diagram (not caption) + main pool table § 3.6 ระบุ 17 ครบ.

**Minimum Acceptable Fix:**
TD-04 line 651 — แก้ `SLOT_STATE × 16` → `SLOT_STATE × 17`.

**Level of Effort:** Low

---

### Claim 02.9: 🟡 MEDIUM — Logger.EscalateIfThresholdMet semantic drift vs ADR-011 "consecutive ticks"

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 9.4 Tagged Logger Pattern (lines 1978-1992)
- Cross-reference: ADR-011 § Decision § Escalation policy (line 60)

**Problem:**
ADR-011 line 60 lock: *"Same `(slot, event)` ERROR ≥ N **consecutive ticks** (default N=10) → upgrade severity"*. Implementation skeleton ใน § 9.4:
```mql5
void CLogger::EscalateIfThresholdMet(string slot, string ev) {
   int idx = FindOrEvictKey(slot + ":" + ev);
   m_consecutive_count[idx]++;     // increments per Error() call
   if (m_consecutive_count[idx] >= m_escalation_n) { Alert(...); reset; }
}
```
Counter increments **ทุก Error() call** — ไม่ track tick boundary, ไม่มี reset path เมื่อ tuple silent ≥ 1 tick. ADR-011 "consecutive ticks" ต้องการ:
1. Increment เฉพาะถ้า same (slot, event) ที่ tick ต่อกัน (กระโดดข้าม tick = reset)
2. Reset เมื่อ tick boundary ผ่านโดยไม่มี Error() ของ tuple นั้น

ที่ skeleton ทำคือ **cumulative count of Error() calls** — sporadic 10 errors over 100 ticks = false escalate.

**Why This Matters:**
ADR-011 contract violated. False positive escalation: ทุก 10 errors ของ same tuple = Alert แม้ห่างกัน 100 ticks (impl) แทน "10 ticks ติดต่อกัน" (intent). Operator inundated with false-alarm Alerts → ignore real Alerts → NFR-5.1 user pain point amplified. Counter reset ก็ไม่ช่วยถ้า next 10 Error sporadic เกิดขึ้นอีก. Real fix ต้องใช้ `OnTickBoundary()` ที่ § 5.7 line 851 (already declared) → loop ทุก tracked key + reset ที่ key ที่ไม่มี Error() ที่ tick ปัจจุบัน.

**Minimum Acceptable Fix:**
1. § 5.7 — เพิ่ม field `int m_last_tick_seen[64];` (parallel to `m_recent_keys`)
2. § 9.4 EscalateIfThresholdMet — ตรวจ `if (m_last_tick_seen[idx] != m_tick_counter - 1) m_consecutive_count[idx] = 1; else m_consecutive_count[idx]++;`
3. § 9.4 OnTickBoundary — bump `m_tick_counter` (already implicit per round-01)
4. หรือ alternative: Update ADR-011 line 60 ลด strict semantic จาก "consecutive ticks" เป็น "consecutive errors within window" (be honest ว่า impl easier to track per-call count) — escalate ผ่าน `/backtrack sd` ถ้าเลือก path นี้

**Level of Effort:** Medium (per-tick tracking adds bookkeeping)

---

### Claim 02.10: 🔵 LOW — OnInit Phase B ไม่มี rollback path documented เมื่อ service Init(...) คืน failure

**Location:**
- File: `docs/technical-design/02-backend-design.md`, Section: § 7.4 OnInit Phase B + Phase C (lines 1602-1666)

**Problem:**
Phase B = 18 sequential `Init(...)` calls + 2 setter calls + 5 inputs. ทุก Init ที่ฉลาดควร return bool (success/fail) แต่ skeleton declare ไว้เป็น `void Init(...)` (e.g., § 5.1 IndicatorService.Init / § 5.6 StatePersistence.Init / § 5.7 Logger.Init / etc. ทั้งหมด void). ถ้า Init() fail ภายใน (เช่น Logger พบ invalid input level + assertion fail) — Phase B ดำเนินต่อ จนถึง Phase C `CreateHandles()` ที่ return bool. แต่ตอนนั้น 17 services ถูก Init แล้ว half-initialized → Phase C `return INIT_FAILED` ทำให้ heap-allocated services orphan; OnDeinit ไม่ถูกเรียก (per MT5: INIT_FAILED → no OnDeinit). Memory leak + handle leak (indicator handles, file handles, GV writes).

**Why This Matters:**
LOW เพราะ MT5 process restart ลบ memory เมื่อ user reattach (acceptable boot-time loss); NFR-3.4 transparency partially affected (engineer ไม่รู้ว่า INIT_FAILED แปลว่าอะไร). แต่ best-practice ของ composition root pattern (ADR-002) ควรมี explicit cleanup path. Round-01 ไม่ raise issue นี้ — fresh finding.

**Minimum Acceptable Fix:**
§ 7.4 — เพิ่ม **§ 7.4.1 Cleanup-on-INIT_FAILED** sub-section:
```mql5
// Helper called ก่อน return INIT_FAILED จาก Phase C
void COrchestrator::CleanupPartialInit() {
   if (m_journal != NULL)     m_journal.Close();
   if (m_indicators != NULL)  m_indicators.ReleaseHandles();
   if (m_portfolio != NULL)   m_portfolio.ReleaseAll();
   if (m_registry != NULL)    m_registry.ReleaseAll();
   // ... delete heap-allocated services in reverse Init order
}
```
+ Update Phase C `return INIT_FAILED` paths → `{ CleanupPartialInit(); return INIT_FAILED; }` (5 sites). Optional เพิ่ม `Logger.ErrorBypassThrottle("system","init_failed_cleanup",...)` ก่อน return.

**Level of Effort:** Medium (cleanup logic + 5 site updates)

---

## Cross-Domain Issues

| # | Issue | Affected docs | Triggered by |
|---|-------|----------------|---------------|
| Y1 | 17-magic cascade incomplete: SD `02 § 1.3` line 99 + SD `03 § 7` A1 line 346 + TD-04 § 10 caption line 651 ยังคง "16" | SD-02, SD-03, TD-04 | Claims 02.3, 02.7, 02.8 (round-01 Claim 01.1 cascade tail) |
| Y2 | RiskManager DI signature drift: § 5.4 Init takes 4 args (incl. PortfolioState) แต่ DI map § 7.3 row 10 ระบุ "(Logger)" + OnInit § 7.4 line 1620 pass 3 args | TD-02 internal × 3 sites | Claims 02.1, 02.6 (round-01 Claim 01.10 cascade tail) |
| Y3 | OnInit pseudocode compile blockers (helper Init phantom × 3 + StatePath + HandleCount) | TD-02 internal × 5 sites | Claims 02.2, 02.4, 02.5 (round-01 Claim 01.7 OnInit rewrite regression) |
| Y4 | Logger escalation impl drift vs ADR-011 "consecutive ticks" semantic | TD-02 § 9.4 vs ADR-011 line 60 | Claim 02.9 (latent — exists since round-01; may have existed pre-round-01 too) |

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 02.1 | 🟠 HIGH | RiskManager.Init missing m_portfolio arg | TD-02 § 7.4 line 1620 | Low |
| 02.2 | 🟠 HIGH | OnInit เรียก Init() ที่ helper class ไม่ declare (× 3) | TD-02 § 7.4 lines 1611-1613 vs § 4.2/4.3/4.4 | Low |
| 02.3 | 🔴 CRITICAL | SD § 1.3 BR Traceability ระบุ "16 magic" (round-01 cascade leak) | SD-02 § 1.3 line 99 | Low |
| 02.4 | 🟡 MEDIUM | m_state.StatePath() accessor undeclared | TD-02 § 7.4 line 1643 vs § 5.6 | Low |
| 02.5 | 🟡 MEDIUM | m_indicators.HandleCount() accessor undeclared | TD-02 § 7.4 line 1664 vs § 5.1 | Low |
| 02.6 | 🟡 MEDIUM | DI map row 10 RiskManager dep "(Logger)" out of sync | TD-02 § 7.3 row 10 vs § 5.4 | Low |
| 02.7 | 🟡 MEDIUM | SD § 7 A1 risk "~16 keys" (cascade incomplete) | SD-03 § 7 line 346 | Low |
| 02.8 | 🔵 LOW | TD-04 § 10 caption "SLOT_STATE × 16" stale | TD-04 § 10 line 651 | Low |
| 02.9 | 🟡 MEDIUM | Logger escalation count drift vs ADR-011 "consecutive ticks" | TD-02 § 9.4 vs ADR-011 § Escalation | Medium |
| 02.10 | 🔵 LOW | OnInit Phase B ขาด rollback path on Init failure | TD-02 § 7.4 | Medium |

**Severity totals:** CRITICAL=1, HIGH=2, MEDIUM=5, LOW=2 → **9 findings**

---

## Recommendation

- [x] **Request Re-Review (round 03)** — 9 findings, 8/9 = compile-blocker / cross-domain leak (low effort to fix; high payoff). Reviewer should verify after rebuttal-02:
  - 17-magic cascade extended ครบ ทั้ง SD-02 § 1.3 + SD-03 § 7 + TD-04 § 10 caption (Claims 02.3 + 02.7 + 02.8 → done via `/backtrack sd` for SD docs, direct edit for TD-04)
  - RiskManager DI fix consistent: § 5.4 ↔ § 7.3 row 10 ↔ § 7.4 line 1620 (Claims 02.1 + 02.6)
  - Helper Init phantom calls resolved: ลบจาก § 7.4 หรือเพิ่มลง helper skeletons (Claim 02.2)
  - StatePath() + HandleCount() accessors declared in respective service classes (Claims 02.4 + 02.5)
  - Logger escalation per-tick semantic implemented or ADR-011 contract relaxed (Claim 02.9)
  - OnInit Phase B cleanup path documented (Claim 02.10)
- [ ] ~~Ready for Implementation Handoff~~ — **NOT yet**; 5 compile-blockers (Claims 02.1, 02.2 × 3 instances, 02.4, 02.5) ทำให้ G1 gate fail ตั้งแต่ IMPL-001 (Orchestrator skeleton). ต้อง round-03 verify cascade tail + compile blockers ก่อน lock TD.
- [x] **Needs SD Backtrack** for 17-magic cascade (Claims 02.3 + 02.7 only) — 2 SD doc edits ต้องผ่าน `/backtrack sd` workflow per Phase Contract; TD ไม่มี authority direct-edit SD/ADR
- [ ] ~~Needs Stakeholder Input~~ — no deferred items; A1-A7 risks unaffected (Claim 02.7 affects A1 wording only ไม่ใช่ semantic)

> **Effort estimate:** Round-02 rebuttal window ~ 1 day (8/9 = mechanical edits ≤ 5 lines each; Claim 02.9 = 1-day refactor; Claim 02.10 = ~ 4-hr cleanup helper). Round-03 verification ~ 0.5 day grep + diff. Total to Implementation handoff readiness: ~ 2 days.

### Round-over-round trend

| Round | Findings | Critical | High | Medium | Low | Resolved this round |
|-------|----------|----------|------|--------|-----|----------------------|
| 01 | 20 | 5 | 8 | 5 | 2 | 20 (100% Accept per rebuttal-01) |
| 02 (current) | 9 | 1 | 2 | 5 | 1 | TBD by rebuttal-02 |
| 03 (projected) | ≤ 3 | 0 | 0 | ≤ 2 | ≤ 1 | converge to handoff |
| 04 (projected target) | 0 | 0 | 0 | 0 | 0 | Ready for Implementation |

**Convergence signal:** CRITICAL ลดจาก 5 → 1; HIGH ลดจาก 8 → 2; total ลดจาก 20 → 9. Round 03 ควรเข้า ≤ 3 findings ถ้า rebuttal-02 ทำได้ thorough cascade tail sweep. Parallel กับ BA (3 rounds) + SD (4 rounds) trajectory — TD on track for 3-4 round convergence.
