# Improvement Targets — Ranked Pain Inventory

> User-perspective ranking ของ pain points ที่ rewrite ต้อง address
> Cross-references CodeWiki §6 (Known Issues) + §7 (Improvement Roadmap) + Q4.1 user input
> Last updated: 2026-05-01

## How to read this

- **Priority** ใช้ MoSCoW (Must / Should / Could / Won't) — BA จะ map ตรงเข้า `02-functional-requirements.md`
- **CodeWiki ref** = section + line reference ของ source code (ผ่าน `MQL5\Experts\PhoenicisN2.10_stable.mq5`)
- **Why** = business rationale ในมุมของ user (ไม่ใช่ technical reason — BA = WHAT ไม่ใช่ HOW)
- **Acceptance** = สิ่งที่ rewrite ต้องส่งมอบ — ใช้เป็น hint ของ acceptance criteria ใน BA

## Priority 1 — MUST address ใน Phase 1 (rewrite scope)

| # | Pain | CodeWiki ref | Severity | Why (user pain) | Acceptance hint |
|---|------|--------------|----------|-----------------|-----------------|
| **P1.1** | Zero `input` declarations — ปรับ parameter ต้อง edit code + recompile | §1.3, §6.1, §6.2 | HIGH | Tune parameter ทีไรเสียเวลา, recompile แล้ว state อาจ corrupt, optimization sweep ผ่าน Strategy Tester ทำไม่ได้ | ≥ 80 magic numbers จาก §6.1 → `input`/`sinput`; default value = current global 1:1 (เพื่อ backtest reproducibility); UI grouping ตาม slot |
| **P1.2** | ไม่มี trade journal / audit trail | (gap — Q4.1 user-added; CodeWiki §6.3 "no structured logging") | HIGH | "ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด" — ดู trade ขาดทุนเก่าไม่ออกว่า slot ไหน, signal context อะไร, indicator value เท่าไรตอนเปิด/ปิด | ทุก order entry/exit/modification → log record (slot, magic, signal context, indicator snapshot, lot, SL, TP, comment, timestamp). Schema/format ตัดสินใจใน BA Phase (OQ-3) |
| **P1.3** | Bug: BI orders เปิดด้วย SL=0 (naked exposure) | §6.2 `:20326 :20357` | **CRITICAL** | Pyramid-child ของ B วิ่งโดยไม่มี stop-loss → live ขาดทุนได้ไม่จำกัดถ้า trend reverse หนัก | ✅ **DECIDED 2026-05-01: FIX** — เพิ่ม SL อิง B parent (รายละเอียด SL distance pending SD/TD). Drift จาก fix นี้นับใน **bucket B** (intentional) ของ regression budget — ดู `trading-baseline.md` |
| **P1.4** | Bug: ExtraTakeProfit_J iterates magic ผิด | §6.2 `:10897` | HIGH | Function process `MagicF` (=201) แทน `MagicJ` (=206) → J orders ไม่ถูกจัดการโดย exit function ของตัวเอง; F โดน double-managed | ✅ **DECIDED 2026-05-01: FIX** — change `MagicF` → `MagicJ`. Drift จาก fix นี้นับใน **bucket B** (intentional). คาดว่า J win rate จะลดลงเล็กน้อย (เพราะ exit จะเข้มงวดกว่าเดิม) แต่ portfolio-level อาจดีขึ้น |
| **P1.5** | 22,016 LOC ในไฟล์เดียว — debug / onboarding ไม่ไหว | §7.2 (Split the file) | High | "code แย่มากๆ" (user) — แก้ตรงนี้ทำพังตรงโน้น; AI agent ก็มี context limit ทำงาน slot-by-slot ลำบาก | Split เป็น 1 file/slot + libs; target: ทุกไฟล์ ≤ 5,000 LOC |
| **P1.6** | 17+ slots overlap, ไม่มี explicit dependency model + shared magic | §2.5, §6.2 (G/G2 shared `MagicG`, B/BI shared `MagicB`) | High | "จัดการ 17+ slots ไม่ได้" — slot อาจ fire พร้อมกันโดยไม่มี mutex; comment-string parsing เป็น state schema → fragile to format drift | Slot interface (entry + exit + magic + dependsOn) + dependency graph (G→GO, B→BR/BI, J→C/D, S→L/K, LX→L pyramid) per §7.2 |
| **P1.7** | No symbol whitelist — ติดผิด chart = วิ่งเลย | §6.3 | High | EA wired กับ EURUSD H4 — attach กับ chart อื่นไม่ปฏิเสธ → เสี่ยงเปิด trade บน symbol ผิด | `OnInit()` reject ถ้า `_Symbol != "EURUSD"`; configurable list ผ่าน input array |
| **P1.8** | Indicator handles ไม่ validate ใน `OnInit` | §6.2 `:86..:113` | High | ถ้า `iCustom` คืน INVALID_HANDLE → CopyBuffer ใช้ buffer เก่า → signal logic ใช้ stale data → trade เปิดผิด (silent failure) | OnInit ตรวจ handle ทุกตัว (~30 handles), log + fail-fast ถ้า invalid |

## Priority 2 — SHOULD address ใน Phase 1 (ถ้า capacity เหลือ)

| # | Pain | CodeWiki ref | Severity | Why | Acceptance hint |
|---|------|--------------|----------|-----|-----------------|
| **P2.1** | 300-bar scan ทุก tick (no cache) | §6.2 `:4164 :7115 :13157`, §7.1 | Med | CPU usage สูงเกินจำเป็น; backtest 5 ปีช้า; live tick latency เพิ่ม | Cache ผลใน OnTick จนถึง bar close ถัดไป (per §7.1) |
| **P2.2** | Slot D / BR / BI invisible (orphan / shared magic / wrapper) | §6.2 (D=4-line wrapper, BR=orphan, BI=B's pyramid) | Med | Onboarding/audit ทำไม่ได้; AI agent งง; ส่งให้คนอื่นดูแลต่อไม่ได้ | Refactor เป็น slot subclass ที่ visible ใน registry per P1.6 |
| **P2.3** | `CircuitBreakerOrder` calls `ExpertRemove()` เงียบๆ | §6.2 `:15796` | Med | EA หายไปจาก chart โดยไม่มี alert → user ไม่รู้ว่าเกิดอะไรในขณะ live | Replace ExpertRemove → controlled halt + Alert + log entry |
| **P2.4** | Pending state ใน flat key=value text file (ไม่มี atomicity) | §6.2 (`<login>_DB.txt`) | Med | crash ระหว่าง write = state corrupt → EA boot กลับมาผิด | atomic write (temp + rename) หรือเปลี่ยน schema → JSON / SQLite |
| **P2.5** | `Print()` log ไม่มี structured tag | §6.2, §7.1 | Med | grep log ไม่เจออะไร — slot ไหน event อะไร; ไม่ link กับ P1.2 trade journal | Tagged logger `[slot=X][ev=...][magic=...]` (foundation ของ P1.2) |
| **P2.6** | `OrderGroupStartWorkflow` bulk-closes 10 slots ไม่มี per-slot opt-out | §6.2 `:328` | Med | "Safe port" ปิดหมดเมื่อ avg badPIP > 55 — slot บางตัวอาจไม่ควรปิด | Per-slot opt-out flag เป็น input |
| **P2.7** | `hasCPendingOrder` global ขาด visible setter | §6.2 `:2664` | Low-Med | H slot อ่าน global นี้แต่ search ไม่เจอ writer → maintenance hazard | Convert เป็น property ของ slot state (P1.6 architecture) |
| **P2.8** | Drawdown-from-orderIndex loops ช้าตามอายุ order | §6.2 `:10998` | Low | Inner loop iterate จาก order's open bar ถึง bar 0 — ยิ่ง order เก่ายิ่งช้า | Cache + incremental update |

## Priority 3 — COULD (defer Phase 2 — ตาม "Out-of-Scope" ของ Phase 1)

| # | Pain | CodeWiki ref | Why deferred |
|---|------|--------------|--------------|
| P3.1 | No news filter | §6.3, §7.3 | User Q4.2 = "ยังไม่มี" — defer Phase 2; NotebookLM #2 (calendar API) + #5 (news trading) มีข้อมูลพร้อมใช้เมื่อต้องการ |
| P3.2 | No equity-floor circuit breaker | §6.3 | OQ-6 — open question; user max DD 50% acceptable แต่ "monitor without enforce" ก็เสี่ยง |
| P3.3 | No partial-close | §6.3 | กลยุทธ์เดิมไม่ใช้ — Q4.2 ไม่มี feature ใหม่ |
| P3.4 | No slippage control parameter | §6.3 | Live performance อาจ drift จาก backtest แต่ user ใช้ FBS standard, default เพียงพอ |
| P3.5 | Real-time dashboard panel | §7.3 | UX feature — Phase 2 |
| P3.6 | Webhook / Telegram notifications | §7.3 | Q3.4 = ไม่มี; defer |
| P3.7 | Walk-forward optimization interface | §7.3 | nice-to-have; Phase 2 |
| P3.8 | sqlite persistence (replace text DB) | §7.3 | P2.4 จะ partial-cover; full sqlite = Phase 2 |

## Priority 4 — WON'T (out of project scope ทั้ง Phase 1 + Phase 2)

| # | Item | Why |
|---|------|-----|
| P4.1 | Multi-symbol portfolio | Constraint C-3 (EURUSD only) |
| P4.2 | Cross-broker support | Constraint C-5 (FBS only) |
| P4.3 | Strategy alteration / new signal logic | Direction D1 — strategy locked |
| P4.4 | Port platform อื่น (cTrader / Python / NinjaTrader) | Constraint C-1, C-2 |
| P4.5 | Web dashboard / mobile app | Solo operator; out of scope |
| P4.6 | ML / AI overlay บน signal logic | Strategy locked (D1) |
| P4.7 | Re-entrancy / mutex protection | §6.3 — relies on single-threaded broker tick (acceptable) |
| P4.8 | Unit tests | §6.3 — MQL5 ecosystem ไม่ค่อย support; QA Phase ใช้ Strategy Tester regression แทน |

## How priorities map to BA deliverables (ใน `docs/ba/`)

| Priority Set | Maps to | Notes |
|--------------|---------|-------|
| P1 | `02-functional-requirements.md` (Must) | + `04-business-rules.md` for safety logic (P1.3 SL rule, P1.4 magic mapping) |
| P2 | `02-functional-requirements.md` (Should) | + `03-non-functional-requirements.md` for P2.1 (perf), P2.4 (durability) |
| P3 | `01-project-brief.md § Out-of-Scope` (Could / Won't ใน Phase 1) | + Open Questions ใน relevant doc per BA workflow Phase 4.2 |
| P4 | `01-project-brief.md § Out-of-Scope` (Won't permanent) | locked |

## Open Questions (cross-ref `ideation-brief.md`)

✅ **Resolved 2026-05-01:**
- **OQ-1** — P1.3 + P1.4 = **FIX** safety bugs (drift นับใน bucket B)

⚠️ **Still open:**
- **OQ-3** — Trade journal schema (P1.2) → CSV / JSON-lines / SQLite / GlobalVariable
- **OQ-6** — Equity-floor switch (P3.2) → keep deferred หรือ promote เป็น Should?
- **OQ-7** — Per-slot trade-count tolerance (P1.6 regression check) → ±15%? ±20%?
- **OQ-8** — Slot U disposition (P4.x?) → preserve disabled, revive, หรือ delete?
