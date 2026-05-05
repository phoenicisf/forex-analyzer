# Implementation Plan Claim Review Round 08

| Field | Value |
|-------|-------|
| **Round** | 08 |
| **Target** | `docs/state/impl-plan.md` (post `rebuttal-round-07.md` close) |
| **Date** | 2026-05-04 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |

---

## 📊 At-a-Glance

**Total findings:** 4 (🔴 CRITICAL 1 / 🟠 HIGH 1 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- Forbidden closure patterns (impl-plan.md): **0 hits** ✅ (R07 Claim 07.1 fix verified)
- Forward reference (P_n → P_m, m>n): **0 edges** (advisory — sample of P4 dependency strings shows back-references P3/P2/P1 only; no full-table audit this round)
- Silent Copy Detector: H=68, A=67, D=1, V=0, N=0 → **not triggered** (D=1 satisfies confirmation)
- State reconciliation: **2 divergences** found — TL;DR ↔ Phase Status Snapshot P4 row Notes (Claim 08.2); Open Risks R-6 narrative ↔ closed-task reality (Claim 08.3); registry Active count = 43 rows = TL;DR claim ✅; overview.md Last Updated = 2026-05-04 ✅; Plan Staleness Sentinel = 0 closures since R07 ✅

### Top 3 to Fix First
1. **Claim 08.1** 🔴 — Trailer file corruption: 3× `## End of Plan` markers + 2 dangling content fragments (lines 1755–1767) — `impl-plan.md § End-of-file`
2. **Claim 08.2** 🟠 — Phase Status Snapshot P4 row Notes column frozen at pre-IMPL-057 state (still says `Mid-Phase Audit P4 counter = 5 — THRESHOLD CROSSED`, `Next: Phase 4 audit → THEN IMPL-057 → IMPL-059 → IMPL-060`) — contradicts TL;DR + Mid-Phase Audit Log GREEN row 1640 + IMPL-057/058/059 closures — `impl-plan.md` line 24
3. **Claim 08.3** 🟡 — Open Risks R-6 still claims "P3 still has 3 open tasks (IMPL-013/034/039 — IMPL-039 is HIGH RISK G4 fix)" although all three closed 2026-05-03..04 — `impl-plan.md § Open Risks`

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — มี CRITICAL หรือ HIGH → run `/impl-plan-rebuttal claim-review-08.md`
- [ ] ⛔ **Immediate Attention** — fundamental phasing/AC flaw ที่ block engineer execution

> **Why a CRITICAL on a "rebuttal-cleanup" round:** Claim 08.1 is a *physical-file-integrity* defect almost certainly produced by R07 sed/Edit batches — multiple `## End of Plan` headers + partial-line fragments are the classic signature of mis-scoped multi-line replace. Engineer agents reading the file via `Read` may stop at the first `## End of Plan` (line 1755) and miss the malformed tail; reviewers who jump to file-end will see the orphaned fragments. Either way, the plan no longer has a single canonical end. R07 was tasked to *clean up* state-reconciliation drift, not to *introduce* file-level corruption. Same defect class as Claim 07.1 (regression introduced 24h after the prior round closed).

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | unchanged since R03; matrix totals 17/11/23/17 = 68 still consistent |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | tally H=68/A=67/D=1/V=0/N=0; Silent-Copy-Detector not triggered |
| 3 | Task Decomposition & Sizing | ✅ Pass | unchanged structure; 9 P4 tasks remain (IMPL-060 + IMPL-017 + IMPL-061..068 QA) |
| 4 | AC — Dual-Track Compliance | ✅ Pass | forbidden-pattern grep on impl-plan.md = 0 hits ✅ (R07 fix holds) |
| 5 | Phase Gates — Testable Exit | ✅ Pass | Phase Gate sections themselves not edited this round |
| 6 | Deferred-AC Registry Init | ✅ Pass | 43 Active rows (6 P1 / 5 P2 / 24 P3 / 8 P4) = TL;DR claim ✅ |
| 7 | Cross-Phase Dependency | ✅ Pass | (advisory — R07 added no new task rows; full graph unchanged from R06) |
| 8 | State-File Consistency | ⚠️ Finding 08.2 + 08.3 | TL;DR ↔ Phase Status P4 row drift; Open Risks R-6 stale |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | sed-batch on `P4 N/11 → P4 N/17` did not introduce new schedule terms |
| 10 | Readability — Reader Empathy | ⚠️ Finding 08.1 + 08.4 | trailer corruption breaks file-end skim; Next Best Action section stale at P1 era |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

### Claim 08.1: 🔴 CRITICAL — Trailer file corruption (3× `## End of Plan` markers + 2 dangling content fragments)

**Location:** `docs/state/impl-plan.md` lines 1755–1767

**Problem:**
ปลายไฟล์มี **3 หัว `## End of Plan`** (lines 1755 / 1760 / 1767) คั่นด้วย **เศษเนื้อหา orphan** ที่ดูเหมือนเป็นชิ้นส่วน sed-replace ตกค้าง:

```
1755 ## End of Plan
1756 ew level — engineer should not raise CONFUSION block when encountering `[ea-qa]` or `[spec]` tasks.
1757
1758 ---
1759
1760 ## End of Plan
1761 not `[gui-capture]` — no GUI);
1762 - `[spec]` tasks → expect `[file-blob-check]` + `[contract-roundtrip]` E-AC kinds (no runtime evidence);
1763 - All 3 variants compile-and-test gate-equivalent at PR review level — engineer should not raise CONFUSION block when encountering `[ea-qa]` or `[spec]` tasks.
1764
1765 ---
1766
1767 ## End of Plan
```

ต้นฉบับ "Reviewer guidance" bullet list ที่ถูกต้อง อยู่ที่ lines 1748–1751 อยู่แล้ว — สามบรรทัด 1761–1763 จึงเป็น **duplicate ที่ paste ซ้ำ** บางส่วนของ list เดียวกัน แล้วถูกตัดหัวบรรทัดทิ้ง. บรรทัด 1756 (`ew level — engineer should not raise CONFUSION...`) เป็นเศษ **กลางคำว่า "review level"** จากการตัด replace ตำแหน่งผิด.

**Why this matters:**
- ไฟล์ `impl-plan.md` ไม่มี canonical end อีกต่อไป — `/next` Check 5.5 (state SoT) + `/impl-task` Phase 1.3 (phase boundary) ต่างต้อง parse plan ทั้งไฟล์; เครื่องมือ/ agents ที่ scan หา section boundary จะเห็น `## End of Plan` ครั้งแรก (line 1755) แล้ว **อาจ stop** และ miss table changes ที่อยู่ก่อนหน้า, **หรือ** เห็น 3 หัวแล้วงงว่า scope จบที่ไหน
- เนื้อหาที่หล่นกลางคำ ("ew level") = **planner / reviewer / engineer ทุกคน** ที่ skim ปลายไฟล์จะเห็น garbage; เกิดเป็น signal-noise ที่ทำให้ doubt section อื่นด้วย
- Defect class = R07 sed/Edit batch มี off-by-one (line 1751 partial replacement was applied at wrong offset) — *รอบเดียวกับ* R06 forbidden-pattern accumulation; ยืนยันว่า rebuttal workflow ยังไม่ verify ปลายไฟล์ post-fix
- R07 § Cascaded Changes #4 อ้างว่าเพิ่ม "5-marker mechanical-gate checklist" ใน workflow.md — แต่ไม่มี gate ใน checklist ที่ตรวจ **file integrity** post-fix (e.g., `tail -1 docs/state/impl-plan.md` หรือ `grep -c "^## End of Plan" docs/state/impl-plan.md`); gate ใหม่ทั้ง 5 ตัวมุ่งที่ counter/denominator/grep แต่ไม่ catch defect class ของรอบนี้

**Minimum acceptable fix:**
1. ลบบรรทัด 1756 (`ew level — engineer should not raise CONFUSION...`)
2. ลบบรรทัด 1758–1763 (เศษ `---` + duplicate "Reviewer guidance" bullets + duplicate `## End of Plan` ที่ line 1760)
3. ลบบรรทัด 1764–1766 (เศษ `---` คั่นก่อน `## End of Plan` สุดท้าย)
4. คงไว้ **เพียง** `## End of Plan` ที่ line 1755 (หรือบรรทัดสุดท้ายของไฟล์ — choose canonical)
5. Post-fix verification: `grep -c "^## End of Plan" docs/state/impl-plan.md` → **1**; `tail -3 docs/state/impl-plan.md` → ลงท้ายเรียบร้อยไม่มี orphan
6. **เพิ่ม Gate #6 ใน `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`**: `tail -3 + grep -c "## End of Plan" == 1` — file-integrity check ที่ catch sed off-by-one defect class ของรอบนี้ (ป้องกัน R08-defect-introduced-while-fixing-R07-defects pattern recurring เป็นรอบที่ 3)

**Effort:** Low (purely textual cleanup) — แต่ severity = CRITICAL เพราะ file integrity defect

---

### 🟠 HIGH

### Claim 08.2: 🟠 HIGH — Phase Status Snapshot P4 row Notes column frozen at pre-IMPL-057 state, contradicts TL;DR + Mid-Phase Audit GREEN row 1640

**Location:** `docs/state/impl-plan.md` line 24 (P4 row in Phase Status Snapshot table)

**Problem:**
P4 row's Notes column ยังคงข้อความ:

> *"...28/28 SelfTest cases pass (7 IMPL-053 + 6 IMPL-055 + 6 IMPL-056 + 6 IMPL-054 + 3 IMPL-058). 5 E-ACs deferred → expiry 2026-05-18. **🚨 Mid-Phase Audit P4 counter = 5 — THRESHOLD CROSSED. Phase 4 audit triggers BEFORE next P4 task per CLAUDE.md §6 + workflow §4.1.** Audit replay scope limited to SelfTest re-run + structural inspection until IMPL-059+ runnable surface lands (no live trading evidence to replay yet). Next: Phase 4 audit → THEN IMPL-057 (M overload helpers BR-8.4 — last business-logic method on file) → IMPL-059 (L Orchestrator) → IMPL-060 (S entry .mq5)..."*

แต่ในไฟล์เดียวกัน:
- **TL;DR (line 5):** "✅ **Mid-Phase Audit P4 GREEN (2026-05-04) — IMPL-057 unblocked.**"
- **Mid-Phase Audit Log row 1640:** "**Mid-Phase Audit GREEN — Phase 4 unblocked for next task**"
- **Tier 1 cell ของ P4 row เอง (column 2):** "🔄 7/17 [x] — IMPL-053..058 ... + IMPL-059 ... ✅ 2026-05-04 — EA core surface complete pending IMPL-060"

= 3 ที่ใน plan เดียวกันบอกว่า audit GREEN + IMPL-057/058/059 closed; **Notes column** กลับยัง threaten ว่า "audit triggers BEFORE next P4 task" + แนะ next = IMPL-057 ที่ปิดไปแล้ว.

**Why this matters:**
- Status agent / `/next` ที่ parse Phase Status Snapshot table (เพราะเป็น "snapshot" ที่ออกแบบมาให้อ่าน) จะ render สถานะ P4 ผิด — โดยเฉพาะคำเตือน 🚨 + คำว่า "THRESHOLD CROSSED" + การชี้ next task ผิด (IMPL-057 ปิดแล้ว)
- Engineer ที่ใช้ `/impl-task` แล้วเห็น Phase Status row ก่อน TL;DR (top-down read order) อาจหยิบ IMPL-057 ตามคำแนะนำ → CONFUSION block + waste prompt
- Defect class = R07 ทำ sed batch บน 16 audit-log P4 snapshot rows (Claim 07.3) แต่ **ไม่ได้** rewrite Notes column ของ Phase Status Snapshot เอง — TL;DR ถูก update, narrative rows ถูก update, แต่ table cell ที่เป็น "snapshot" หล่นจาก scope. ขัด CLAUDE.md §6 State Reconciliation Discipline 3-file rule (intra-file rule: 1 plan ↔ 4 places ที่ encode P4 status — TL;DR + Phase Status Snapshot + Audit Log narrative + Sentinel — ทั้ง 4 ต้องตรง)

**Minimum acceptable fix:**
1. Rewrite P4 row Notes column (line 24) เพื่อสะท้อน post-IMPL-059 reality:
   - ลบ "🚨 Mid-Phase Audit P4 counter = 5 — THRESHOLD CROSSED..." block ทั้งย่อหน้า
   - ลบ "Next: Phase 4 audit → THEN IMPL-057 → IMPL-059 → IMPL-060" → แทนด้วย "Mid-Phase Audit P4 ✅ GREEN 2026-05-04 (Audit Log row dated 2026-05-04 §1640); IMPL-057/058/059 closed 2026-05-04. **Next: IMPL-060 (S entry .mq5 thin wrapper) → empirical surface unblocks 43 deferred-AC rows expiring 2026-05-17/18.**"
   - Update SelfTest count narrative ให้รวม IMPL-057 (28→36 cases per IMPL-057 evidence) + IMPL-059
2. Add bullet ใน R07 5-marker workflow gate (or new Gate #6): post-closure must touch **both** TL;DR **and** Phase Status Snapshot row Notes — currently Gate #4 handles Sentinel + Gate #5 handles overview.md, but no gate enforces intra-plan Phase Status row
3. Post-fix verification: `grep -nE "Mid-Phase Audit P4 counter = 5|🚨.*THRESHOLD CROSSED" docs/state/impl-plan.md` → 0 hits (current narrative rows that legitimately recorded counter=5 historically can be moved to Audit Log entries with date timestamps; Phase Status Snapshot must reflect "now")

**Effort:** Medium (textual rewrite of one table cell + new gate row in workflow.md)

---

### 🟡 MEDIUM

### Claim 08.3: 🟡 MEDIUM — Open Risks R-6 narrative stale (claims P3 has 3 open tasks IMPL-013/034/039)

**Location:** `docs/state/impl-plan.md § Open Risks` (line 37)

**Problem:**
R-6 risk row contains:

> *"...6 P4 tasks (M+M+S+XS+XS+M) ≈ 28 days nominal **+ P3 still has 3 open tasks (IMPL-013/034/039 — IMPL-039 is HIGH RISK G4 fix)**. After R06 backfill, 6 additional P1 deferred-AC rows also expire 2026-05-17 (same renewal cycle)..."*

แต่ตาม TL;DR + Phase Status row P3:
- IMPL-013 closed 2026-05-04 ✅
- IMPL-034 closed 2026-05-04 ✅
- IMPL-039 closed 2026-05-04 ✅
- P3 = **23/23 ✅ all slots + IMPL-013**

ดังนั้น R-6 ไม่มี P3 task เปิดเหลือเลย; "3 open tasks" claim = stale 1 day.

**Why this matters:**
- R-6 narrative อ้างอิงไปทาง `/impl-task` "next task ordering" + Phase Gate retroactive close timeline + 2026-05-31 hard-stop escalation — ทุกอย่างนับ days based on "P3 still open" assumption ที่ผิดแล้ว
- `/next` Check 5.5 + Open Risks scan ที่อ่าน R-6 จะ over-report risk weight (เห็น P3 + P4 + 2 timeline gates ↔ จริง ๆ มีแค่ P4 chain 1 chain)
- Defect class เดียวกับ Claim 08.2: R07 wave updates TL;DR + Sentinel + audit-log rows + 16 snapshot rows + overview.md — แต่ **ไม่ touched** Open Risks section. Ad-hoc copy-edit scope ที่ไม่ comprehensive

**Minimum acceptable fix:**
1. Update R-6 narrative ให้สะท้อน P3 23/23 ปิด:
   - ลบ "+ P3 still has 3 open tasks (IMPL-013/034/039 — IMPL-039 is HIGH RISK G4 fix)"
   - แทนด้วย "P3 23/23 ✅ ปิด 2026-05-04 (IMPL-013/034/039 ทั้งหมดปิดในวันเดียว); P4 chain เปิดเหลือ IMPL-060 + IMPL-017 + IMPL-061..068 = 9 tasks"
2. Recompute timeline arithmetic — "≈ 28 days nominal" ตอนนี้เหลือ "≈ 8 days nominal" (IMPL-053..059 = 7 ปิดแล้ว; IMPL-060 = S → ~1-2 day estimate)
3. Recheck "Hard-stop escalation: 2026-05-31" — กับ today = 2026-05-04, เหลือ 27 days ก่อน final renewal; P4 chain นับเฉพาะ IMPL-060 fits comfortably; downgrade severity ของ R-6 จากนัยเดิม

**Effort:** Low (textual update of one risk row) — but ต้อง **recompute timeline arithmetic** เพื่อไม่สร้าง stale-by-construction ของรอบหน้า

---

### Claim 08.4: 🟡 MEDIUM — "Next Best Action" section frozen at P1-era state

**Location:** `docs/state/impl-plan.md § Next Best Action` (lines 41–51)

**Problem:**
ส่วน "Next Best Action" ทั้งบล็อกยังแนะแนวจากยุค pre-P1-Phase-Gate-close:

> *"☑ P1 17/17 closed — final parallel batch (IMPL-006 + IMPL-010 + IMPL-016) merged 2026-05-02. P1 Phase Gate now nominate-able.*
> *☑ Run `/impl-plan-review all` + `/impl-review all` — Plan Staleness Sentinel 17/10 exceeds threshold by 7; review plan + code before P1 Phase Gate close*
> *☐ Run Tier 1.5 Exploratory Walk for P1 — for headless EA: artifact = `simulation/headless-tests/<phase-gate>.ini` cold-bootstrap run...*
> *☐ P1 Phase Gate close (`IMPL-P1-GATE`) — requires Empirical Demo + Tier 1.5 walk artifact ≤14d + Deferred-AC drained (already empty) + CRITICAL/HIGH code review findings resolved*
> *☐ P2 IMPL-047 StatePersistence chain — blocked until P1 Phase Gate close*
> *☐ Run Tier 1.5 Exploratory Walk — N/A (no phase done yet)..."*

แต่ในความจริง: P1 ปิด 2026-05-02; P2 11/11 [x] + Override 2026-05-03; P3 23/23 ✅ 2026-05-04; P4 7/17 (IMPL-053..059 ปิด); **next best action = `/impl-task IMPL-060`** ตาม TL;DR line 13.

**Why this matters:**
- Section name = "Next Best Action" — operator/agents ที่ skim plan ตามชื่อ section จะอ่าน checkbox list ที่ frozen 2 days ago; ทุก action item ใน list เป็น obsolete (P1 close ✅ + P1 Phase Gate close = ไม่ใช่ next; P2 IMPL-047 = ปิดแล้วใน parallel batch P2)
- ขัดแย้งกับ TL;DR line 13: "**Next:** `/impl-task IMPL-060`" — ผู้อ่านที่เห็น 2 ที่บอก next ต่างกันจะ **ใช้ checkbox เป็นหลัก** (visually compelling format) → engineer หยิบ task ผิด
- Defect class = R03..R07 ทุกรอบ update TL;DR + Phase Status + Sentinel แต่ never re-evaluate Next Best Action checklist — section ออกแบบเป็น "frozen advice" mode by accident
- ไม่ใช่ CRITICAL/HIGH เพราะ TL;DR pivot bullet line 13 ระบุ next action ชัดเจน + Phase Status row column 1 ระบุ phase progress; แต่ **MEDIUM** เพราะ rosy-path readability fail: section ที่ชื่อ "Next Best Action" ห้าม diverge จาก TL;DR "Next" pivot

**Minimum acceptable fix:**
1. Rewrite Next Best Action checklist ให้สะท้อน 2026-05-04 reality:
   - ☑ P1/P2/P3 phases tier 1 closed; P4 7/17 closed under Override
   - ☑ Mid-Phase Audit P4 GREEN 2026-05-04
   - ☐ `/impl-task IMPL-060` (S entry .mq5 thin wrapper — gating task for empirical surface)
   - ☐ Code Review Round R09 (`/impl-review all`) — recommended before IMPL-060 per fix-round-09 surface area
   - ☐ Tier 1.5 walk: `simulation/headless-tests/bootstrap_smoke.ini` cold-bootstrap run + Tester log + journal audit — runnable after IMPL-060 lands
   - ☐ P2 + P3 Phase Gate retroactive close — blocked on IMPL-060 + Tier 1.5 walk artifact
   - ☐ P4 Phase Gate close — blocked on IMPL-060..068 chain complete
2. Add หมายเหตุที่ section header: "อัปเดตทุกครั้งที่ปิด task / fix-round / rebuttal — ห้ามคงที่ระหว่างรอบ" + เพิ่ม **Gate #7 ใน workflow.md** = "Next Best Action checkbox sweep — every closure must re-tick + re-pivot top action"

**Effort:** Low (textual rewrite of 7-line checklist + 1 gate row in workflow.md)

---

## Cross-Document Issues

ไม่พบ contradictions ข้าม `impl-plan.md` ↔ `overview.md` ↔ `deferred-ac-registry.md` (registry 43 = TL;DR claim ✅; overview Last Updated = 2026-05-04 ✅; Sentinel = 0 closures since R07 ✅).

Drift ทั้งหมดอยู่ **ภายใน** `impl-plan.md` เอง: TL;DR + Sentinel + Audit Log narrative + overview.md ตรงกัน ↔ Phase Status Snapshot row + Open Risks + Next Best Action ค้างที่ pre-R07. = ปัญหา R07 sed-batch scope ตกหล่น (ไม่กระจาย rewrite ครบทุก parallel-narrative location).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 08.1 | 🔴 CRITICAL | Trailer file corruption (3× `## End of Plan` + 2 dangling fragments) | `impl-plan.md` lines 1755–1767 | Low |
| 08.2 | 🟠 HIGH | Phase Status Snapshot P4 row Notes frozen at pre-IMPL-057 state | `impl-plan.md` line 24 | Medium |
| 08.3 | 🟡 MEDIUM | Open Risks R-6 stale (claims 3 open P3 tasks) | `impl-plan.md § Open Risks` line 37 | Low |
| 08.4 | 🟡 MEDIUM | "Next Best Action" section frozen at P1 era | `impl-plan.md § Next Best Action` lines 41–51 | Low |

---

## Reviewer Note for R08 Rebuttal

R07 was the second consecutive rebuttal that introduced new defect classes while fixing prior ones (R06: 33-task burst → 20 forbidden patterns; R07: closing R06 → 1 forbidden pattern regression at line 1636 + 3 state drifts; **R08 will catch R07's** trailer corruption + 3 narrative drifts in sections that R07 sed batch didn't touch). The 5-marker workflow checklist added in R07 catches counter/denominator/grep at *closure time*, but offers no gate that catches **rebuttal-introduced** defects — R07 rebuttal output itself was not subjected to the gates it created.

**Strong recommendation for R08 rebuttal:** add **3 new gates** to `.claude/rules/workflow.md § Phase 5 Closure mechanical gates`:
- **Gate #6** — file integrity check post-Edit-batch: `tail -3 docs/state/impl-plan.md` + `grep -c "^## End of Plan" docs/state/impl-plan.md == 1`
- **Gate #7** — Phase Status Snapshot row sweep: every closure must touch the Notes column of the relevant phase row (not just TL;DR + Sentinel + Audit Log)
- **Gate #8** — narrative-section freshness sweep: Open Risks + Next Best Action both must be re-read + re-evaluated per closure (mark stale items with strikethrough or rewrite)

Without these, R08 → R09 will likely repeat the cycle a third time.

— Implementation Plan Reviewer (Adversarial Tech Lead)
2026-05-04
