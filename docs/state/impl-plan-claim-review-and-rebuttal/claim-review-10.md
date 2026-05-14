# Implementation Plan Claim Review Round 10

| Field | Value |
|-------|-------|
| **Round** | 10 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-13 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Previous round** | R09 (2026-05-11) — 7/7 Accept; IMPL-FIX-011 re-decomposition into 011a/b/c/d |

---

## 📊 At-a-Glance

**Total findings:** 6 (🔴 CRITICAL 1 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- **Forbidden closure pattern grep:** 0 hits ✅ on canonical regex set (`deferred to operator-runtime|deferred to post-launch operator phase|deferred per .* precedent|structurally complete.*deferred|live verification deferred`). Note: คำว่า `deferred` ปรากฏ 100+ ครั้งใน sanctioned contexts (registry pointers, "deferred to IMPL-XXX", "deferred to operator paired-bundle session") — all OK.
- **Forward refs (P_n → P_m, m>n):** 0 edges ✅. R09 09.5 fix (parent P4 / sub-tickets P3 with explicit P4 drain ownership) holds.
- **Silent Copy Detector:** H=67, A=66, D=1 (IMPL-013 P4→P3 with Service-coupling rationale), V=0, N=0. Detector **NOT triggered** ✅ (D > 0 + confirmation note present).
- **State reconciliation (3-way):** 🔴 **1 direct contradiction** (TL;DR boilerplate vs § Plan Staleness Sentinel) + 🟠 **5 stale narrative-parallel sections** (Open Risks R-3/R-8/R-13, Phase Status P4 Notes, Next Best Action). Evidence-artifact spot-checks (3/3) PASS.

### Top 3 to Fix First
1. **Claim 10.1** 🔴 — Plan Staleness Sentinel contradicts itself ระหว่าง TL;DR (`0 closures since R25`) กับ § Sentinel (`11 closures THRESHOLD CROSSED`); ผสม impl-review (R25) กับ impl-plan-review (R09) chain — `docs/state/impl-plan.md` TL;DR lines 5/9/11/13/15/17/19/21/23/25 vs § Plan Staleness Sentinel ~line 2258
2. **Claim 10.2** 🟠 — Open Risks R-3/R-8/R-13 + Phase Status P4 Notes + Next Best Action ทั้งหมด stale หลัง 6 TL;DR closure entries ใน 2 วัน — Phase 5 mechanical Gate #7+#8 ไม่ถูก invoke
3. **Claim 10.4** 🟠 — P4 Phase Gate "Empirical Demo" + NFR check rows ไม่สะท้อน Run #1 + Run #2 empirical falsification ของ NFR-1.1 contract feasibility — engineer ปิด gate ไม่ได้แต่ text ไม่บอก

### Verdict
- [ ] ✅ **Ready for Implementation Execution**
- [x] ⚠️ **Needs Rebuttal Round** — 1 CRITICAL + 3 HIGH block `/next` orchestrator + Phase Gate close decisions → run `/impl-plan-rebuttal claim-review-10.md`
- [ ] ⛔ **Immediate Attention**

> Rebuttal scope: prose / state-reconciliation only — ไม่กระทบ AC content; expected single-cycle close.

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | Unchanged since R01; rationale + Phase % targets ครบ |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | Silent Copy clean; D=1 IMPL-013 documented |
| 3 | Task Decomposition & Sizing | ✅ Pass | R09 re-decomposition resolved IMPL-FIX-011 size/scope issue |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 10.5 | IMPL-FIX-003 Phase 1B closure G2/G3/G4 deferred without registry row |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 10.4 | P4 Empirical Demo + NFR check rows empirically falsified แต่ text unchanged |
| 6 | Deferred-AC Registry Init | ✅ Pass | R09 parent row added; sub-ticket S-ACs ตามออกแบบ |
| 7 | Cross-Phase Dependency | ✅ Pass | No forward refs |
| 8 | State-File Consistency | ⚠️ Findings 10.1 + 10.2 + 10.3 | Sentinel contradiction + narrative drift + IMPL-FIX-011 parent text superseded |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | No sprint/week/Q1-Q4 schedule leakage (Q1 2021 = test-window date) |
| 10 | Readability — Reader Empathy | ⚠️ Finding 10.6 | TL;DR 10 entries deep + ~60 lines repeating boilerplate; skim test fail |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

#### Claim 10.1: 🔴 CRITICAL — Plan Staleness Sentinel direct contradiction: TL;DR ระบุ "0 closures since R25", § Sentinel ระบุ "11 — THRESHOLD CROSSED"; ผสม impl-review chain (R25) กับ impl-plan-review chain (R09)

**Location:** `docs/state/impl-plan.md` TL;DR lines 5, 9, 11, 13, 15, 17, 19, 21, 23, 25 (10× repetition of `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25"`) vs § Plan Staleness Sentinel ~lines 2258-2262.

**Problem:**
TL;DR repeats 10 ครั้งว่า `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25"` (newest 2026-05-12 + 2026-05-11 entries). § Plan Staleness Sentinel section line 2260 อ้างค่าตรงข้าม: `"Closures since last review: 11 — 🚨 THRESHOLD CROSSED (≥ 10) → /impl-review all R09 MANDATORY before next IMPL-NNN closure"`. Paragraph ใต้ table line 2262 self-contradicts อีกครั้ง: `"9 closures since R07 ... within 10-closure threshold ✅ (1 closure shy of trigger)"`. นอกจากนี้ `"R25"` ใน TL;DR คือ impl-**review** numbering (code review chain) — แต่ Plan Staleness Sentinel (per CLAUDE.md § Glossary) ติดตาม impl-**plan-review** chain (R01-R09 ปัจจุบัน); การผสมสอง chain เป็นเรื่องของ semantics ไม่ใช่แค่ตัวเลข.

**Why this matters:**
`/next` Check 5.8 + status agents อ่าน Sentinel เพื่อตัดสินใจว่าต้อง force `/impl-plan-review` หรือไม่ — readers ที่อ่าน TL;DR ก่อนจะรายงาน "no review needed" (counter 0); readers ที่อ่าน § Sentinel จะรายงาน "MANDATORY review" (counter 11). Race condition between two readers — exactly Phase Gate Hallucination class per CLAUDE.md § Glossary. FIX-ticket closures (per workflow.md Gate #4 + fix-round-10 precedent) ไม่เพิ่ม counter — แต่ TL;DR ก็ยังต้องอ้าง impl-plan-review chain (max R09) ไม่ใช่ R25.

**Minimum acceptable fix:**
1. § Plan Staleness Sentinel block rewrite — header → `"Last review on: 2026-05-11 — claim-review-09 / rebuttal-round-09 (R09 7/7 Accept; IMPL-FIX-011 re-decomposition into 011a/b/c/d). Closures since R09: <N>. Threshold ≤10 ✅/⚠️."` + delete contradictory `"9 closures since R07 ... THRESHOLD CROSSED 11"` paragraph.
2. Every TL;DR entry replace `"unchanged at 0 IMPL-NNN closures since R25"` → `"unchanged at <N> IMPL-NNN closures since R09 (impl-plan-review chain)"` — numerator + denominator ต้องตรงกันทั้ง 10 entries.
3. Add 1-line note ที่ top ของ Sentinel: `"FIX-ticket closures (IMPL-FIX-NNN) ไม่ increment counter per workflow.md Gate #4 + fix-round-10 precedent — counter ติดตามเฉพาะ IMPL-NNN main task closures."`

**Effort:** Low (1 section rewrite + 10 TL;DR find-replace; ~15 LOC across 2 sites).

---

### 🟠 HIGH

#### Claim 10.2: 🟠 HIGH — Open Risks R-3 / R-8 / R-13 + Phase Status P4 Notes + Next Best Action checklist ทั้งหมด stale หลัง 6 TL;DR closure entries ใน 2 วัน; Phase 5 mechanical Gate #7+#8 ไม่ถูก invoke

**Location:** `docs/state/impl-plan.md` § Open Risks lines 24 (R-3), 32 (R-8), 29 (R-13) + § Phase Status Snapshot line 14 (P4 row Notes) + § Next Best Action lines 73-83 (Option A/B/C checklist).

**Problem:**
- **R-3** (line 24): `"Earliest mitigation: IMPL-061 baseline parser + IMPL-062 regression run ใน P4"` — IMPL-061 closed 2026-05-04; IMPL-062 รันแล้วสองครั้ง (Run #1 2026-05-10 day-1 stop-out / Run #2 2026-05-12 99.998% catastrophic drift); TL;DR line 5 recommend `/backtrack ba` re-baseline NFR-1.1. R-3 mitigation path empirically defunct.
- **R-8** (line 32): `"Mitigation: IMPL-FIX-006 task block authored at line 1544 ... Blocks: IMPL-062 + IMPL-066 + IMPL-068 numeric drain"` — IMPL-FIX-006 ✅ closed 2026-05-10 (commit `bd2a075`); chain FIX-007/008/009/010/011 ทั้งหมดปิดแล้ว; R-8 ควร RESOLVED หรือ pivot to Run #2 finding.
- **R-13** (line 29): `"Mitigation: IMPL-FIX-011 Step 3 (current session target) — Session A ... Session B ... Session C ... Step 4 re-canary at ≥75% divergence reduction gate"` — narrative ทั้งหมดเป็น pre-R09 framing; R09 decompose Step 4 ลงเป็นแต่ละ slot enumerated-bucket ACs ใน 011a/b/c/d; 011a entry-parity, 011b/c, 011d iter-17/18/19 CLOSED; IMPL-FIX-003 Phase 1B CLOSED 2026-05-12 wires 11 slots. R-13 อ่านเหมือน iter-3 เพิ่งล้มเหลว.
- **Phase Status P4 Notes** (line 14): `"Remaining work = operator paired-bundle 5-yr drain (IMPL-062 numeric Bucket A + ...)"` — IMPL-062 ถูก drain แล้วสองครั้งและ FAIL ทั้งสอง; remaining work ตอนนี้คือ **contract re-baseline** ไม่ใช่ drain.
- **Next Best Action** (lines 73-83): `☐ NEXT — operator decision on Option A / B / C ... engineer recommends Option A`. R09 (2026-05-11) resolved this question แล้ว (operator picked Option B; sub-tickets created and partially closed). Six intervening TL;DR entries dated 2026-05-11+2026-05-12 reference closures past this decision.

**Why this matters:**
Phase 5 mechanical gates #7 (Phase Status Notes sweep) + #8 (Narrative-section freshness sweep) ใน `.claude/rules/workflow.md` ระบุชัดว่าทุก task closure ต้อง re-read Phase Status row + Open Risks + Next Best Action และ rewrite/strikethrough invalidated rows. Engineer-side ผ่าน 6+ TL;DR closure entries ใน 2 วัน (2026-05-11/12) ไม่ run gates #7/#8 — exactly the regression class R08 introduced gates #7/#8 to prevent. `/next` ที่อ่าน Next Best Action จะ recommend operator pick Option A/B/C — operator งงเพราะ TL;DR newest entry บอกว่า `/backtrack ba` คือ next action.

**Minimum acceptable fix:**
1. R-3 strikethrough + new line: `"~~R-3 Bucket A drift exceeds NFR-1.1~~ ⚠️ **CONTRACT RE-BASELINE REQUIRED 2026-05-12** — IMPL-062 Run #2 demonstrated 99.998% drift = catastrophic; root cause = DISABLE_G4_FIXES measurement contract incompatible with 16-active-slot rewrite under $1k deposit (not Phase 1B regression). **Earliest mitigation:** /backtrack ba to update NFR-1.1 threshold OR re-interpret Bucket A = 'rewrite-G4-ON vs baseline'. See TL;DR 2026-05-12 + regression-bucket-a.md § 5."`
2. R-8 → `~~R-8~~` strikethrough; move to Resolved-Risks section with closure note `"RESOLVED 2026-05-10 via IMPL-FIX-006/007/008/009/010/011 chain; superseded by 2026-05-12 Run #2 finding (R-3)."`
3. R-13 rewrite: `"R-13 (UPDATED 2026-05-12) — Sub-ticket chain CLOSED: 011a entry-parity (followup row); 011b + 011c + 011d Phase 2 iter-19; IMPL-FIX-003 Phase 1B 11 slots wired. **Remaining:** parent paired-bundle drain blocked by R-3 contract re-baseline."`
4. Phase Status P4 Notes column append: `"**2026-05-12:** IMPL-062 Run #2 catastrophic fail; mitigation pivoted from numeric-drain to contract re-baseline per TL;DR + R-3."`
5. Next Best Action strikethrough lines 73-83 Option A/B/C + replace: `~~Operator pick Option A/B/C~~ ✅ Resolved at R09 (Option B accepted). New top-level next: ☐ **operator decision on /backtrack ba scope** per TL;DR 2026-05-12 recommendation.`

**Effort:** Medium (~30-50 LOC rewrite across 5 narrative sections; pure prose, no AC change).

---

#### Claim 10.3: 🟠 HIGH — IMPL-FIX-011 parent task block E-AC footnote ยัง cite "extend FIX-006/007/009 expiry to absorb IMPL-FIX-011 closure window" — R09 09.7 superseded ด้วย dedicated parent registry row 2026-06-30

**Location:** `docs/state/impl-plan.md` § IMPL-FIX-011 parent block E-AC #1 footnote (~line 1827): `"deferred to operator paired-bundle session (registered in deferred-ac-registry.md paired bundle with IMPL-062 numeric drain — extend FIX-006/007/009 expiry to absorb IMPL-FIX-011 closure window)"`.

**Problem:**
R09 Claim 09.7 + rebuttal-round-09 accept response ระบุชัดว่าสร้าง `"new Active row IMPL-FIX-011 ... Expires: 2026-06-30 (~7 weeks; supersedes prior FIX-006/007/009 absorb-window of 2026-05-19)"`. R09 rebuttal เลือก keep old wording ใน **FIX-006/007/009 registry rows** เป็น audit trail — แต่ wording เดิมใน **IMPL-FIX-011 parent task block** ยังคงอยู่โดยไม่มี DEPRECATED marker ทั้ง 4 E-AC footnote bullets. Engineer reading IMPL-FIX-011 parent block ได้ conflicting signals: footnote say "absorb FIX-006/007/009 expiry"; registry row say "supersedes prior FIX-006/007/009 absorb-window".

**Why this matters:**
Engineer dispatching `/impl-task IMPL-FIX-011` (parent paired-bundle drain) อ่าน E-AC footnote แล้วไป update FIX-006/007/009 rows extending expiry — ตามเดิม pre-R09 — แต่ R09 fix แล้วว่ามี parent row standalone. Same defect class as R09 09.6 (TL;DR-vs-diagnostic drift) แต่อยู่ในใจกลาง task block. Phase 5 mechanical Gate #7+#8 should have caught this at R09 rebuttal commit — appears missed.

**Minimum acceptable fix:** Annotate ทั้ง 4 E-AC footnote bullets ใน IMPL-FIX-011 parent block ด้วย `[SUPERSEDED post-R09 — paired-bundle drain tracked via dedicated registry row 2026-06-30, ไม่ใช่ FIX-006/007/009 absorb-window]`. หรือ rewrite footnote to: `"deferred to operator paired-bundle session (tracked in deferred-ac-registry.md § Active row IMPL-FIX-011 parent, expiry 2026-06-30, per R09 Finding 09.7)"`.

**Effort:** Low (4 footnote edits, ~10 LOC).

---

#### Claim 10.4: 🟠 HIGH — P4 Phase Gate "Empirical Demo" + NFR-1.1 check rows ไม่สะท้อน Run #1 + Run #2 empirical falsification ของ contract feasibility; engineer reading checkbox จะ rerun drain ไม่จบ

**Location:** `docs/state/impl-plan.md` § P4 Phase Gate "Empirical Demo" bullet (~line 1396): `"full 5-yr Strategy Tester regression 2021-Jan-01 → 2025-Dec-31 ... Bucket A drift ≤ 25% Net Profit deviation per NFR-1.1 ..."` + Phase Gate NFR check `[ ] NFR-1.1 Bucket A Net Profit deviation ≤ 25% (IMPL-062)` (~line 1404).

**Problem:**
Phase Gate row assert NFR-1.1 ≤25% เป็น closure criterion — แต่ IMPL-062 รันแล้วสองครั้ง (2026-05-10 Run #1 day-1 stop-out / 2026-05-12 Run #2 99.998% drift) และ TL;DR line 5 explicit question ว่า NFR-1.1 contract achievable หรือไม่ภายใต้ measurement methodology ปัจจุบัน (recommend `/backtrack ba`). Phase Gate row text ไม่พูดถึง Run #1/Run #2 และไม่พูดถึง pending contract re-baseline. Engineer dispatching P4 Phase Gate close จะอ่าน row + run regression + report "FAIL drift > 25%" — แต่ blocker คือ contract design ไม่ใช่ achievement gap. Phase Gate `[ ]` ปิดไม่ได้แบบสุจริตจนกว่า `/backtrack ba` outcome resolves.

**Why this matters:**
Per CLAUDE.md § Glossary "Phase Gate Hallucination" — Phase Gate text ที่ไม่ reflect empirical state of feasibility = `/next` orchestrator + status agents จะ recommend "run IMPL-062 again, close P4 Gate" loop infinitely. NFR check sub-bullet `[ ] NFR-1.1 ≤ 25% (IMPL-062)` ไม่ flag "blocked on contract re-baseline" — engineer ที่อ่าน checkboxes ตรงๆ จะ rerun 5-yr drain ครั้งที่สาม.

**Minimum acceptable fix:** Insert `⚠️ **BLOCKED 2026-05-12 — pending /backtrack ba re-baseline**` annotation บน:
- Phase Gate § Empirical Demo bullet (cite TL;DR 2026-05-12 + `regression-bucket-a.md § 5`)
- Phase Gate § NFR check `NFR-1.1 ≤ 25% (IMPL-062)` sub-bullet
- IMPL-062 task block Status entry — append paragraph: `"Run #1 (2026-05-10): day-1 stop-out per bucket-a-5yr-partial-20260510. Run #2 (2026-05-12): 99.998% drift per regression-bucket-a.md § 5 — measurement contract incompatible; re-baseline pending /backtrack ba."`

**Effort:** Low (3 annotations, ~15 LOC).

---

### 🟡 MEDIUM

#### Claim 10.5: 🟡 MEDIUM — IMPL-FIX-003 Phase 1B closure (+465 LOC, 11 slots) ปิดด้วย G2/G3/G4 "deferred to operator session" โดยไม่มี Active row ใน deferred-ac-registry; ใกล้เคียง forbidden pattern

**Location:** `docs/state/impl-plan.md` TL;DR line 9 (2026-05-12 IMPL-FIX-003 Phase 1B closure): `"G2/G3/G4 deferred to operator session — foreground MT5 lock during closure session; pattern byte-identical to known-clean Slot_K iter-18 + Slot_B iter-19 compiles per mt5-log-reader § Compile semantics"` + Next Best Action line 90: `"☑ IMPL-FIX-003 Phase 1B follow-up CLOSED 2026-05-12"`.

**Problem:**
Phase 1B ลง 14 files + ~465 LOC + wires 11 new slots + new `CRiskManager::CloseOrder` method + new BR pending one-shot latch. ผ่าน G1 compile + structurally claims correctness via byte-identical pattern argument — แต่ **G2 (smoke EA attach 5-tick init_ok), G3 (headless backtest), G4 (log review + journal validate)** ทั้ง 3 gates explicit deferred to "operator session" โดยไม่มี:
- Active row ใน `deferred-ac-registry.md` (registry มี parent IMPL-FIX-011 row + IMPL-FIX-003 Phase 1A historical row แต่ **ไม่มี IMPL-FIX-003 Phase 1B row**)
- Operator Action Registry pending row
- Cross-reference ว่า deferred-AC bundle ไหน absorbs งานนี้

Per CLAUDE.md § Glossary "Empirical Closure Discipline" + Code Review Dim #11: task ที่มี E-AC ต้องมี evidence artifact หรือ deferred-AC row — `[x]` + "G2/G3/G4 deferred to operator session" บน TL;DR entry ที่ไม่ลง registry = ใกล้เคียง forbidden pattern `[x]` + "deferred to operator-runtime" (text ต่างที่คำเดียว "session" vs "runtime"). Pattern byte-identical claim mitigates risk แต่ไม่ satisfy registry contract.

**Why this matters:**
`/deliver` Block check (CLAUDE.md § Glossary "Deferred-AC Registry") fires only if Active table not empty — uncatalogued deferred verifications **escape** gate. ~465 LOC across 14 files + new service method ปล่อยพร้อม G2/G3/G4 unverified, byte-identical-to-Slot_K-iter-18 pattern argument คือ engineer assertion ไม่ใช่ empirical evidence (Slot_K iter-18 ran verify canary; Phase 1B ไม่ได้รัน). Bucket A Run #2 (TL;DR line 5) รันบน Phase 1B build และแสดง Phase 1B wiring fired ถูก (40 entries / 30 exits / 72 records) — แต่นั่นเป็น side-effect attestation; explicit EA-attach + smoke + log validate gates ไม่ได้รันเป็น discrete checks.

**Minimum acceptable fix:**
1. เพิ่ม Active row ใน `deferred-ac-registry.md`:
   ```
   | P4 | IMPL-FIX-003 Phase 1B | G2 smoke EA attach 5-tick [ev=init_ok] [probe] + G3 headless bootstrap_smoke.ini 3-day run [log-assertion] + G4 journal-record schema validate sample 5 [file-blob-check] | probe + log-assertion + file-blob-check | Closure 2026-05-12 deferred operator session per foreground MT5 lock; pattern byte-identical to Slot_K iter-18 + Slot_B iter-19 (G1 PASS attests no syntax error) — empirical attach/smoke/log verification deferred to Tier 1.5 walk batch-4 OR next IMPL-062 Run #3 retry | Kritsana | 2026-05-12 | 2026-05-26 | If Phase 1B wiring has runtime defect not caught by G1 (e.g., null-deref in 11 new OpenOrder sites, BR-trigger latch race), Bucket A Run #3 day-1 cascade reappearance possible. Mitigation: Run #2 evidence already shows 40 entries + 30 exits + 72 schema-valid records — strong indirect attestation
   ```
2. Update TL;DR line 9 footnote: `"... deferred to operator session ✅ tracked at deferred-ac-registry.md § IMPL-FIX-003 Phase 1B row (expiry 2026-05-26)"`.

**Effort:** Low (1 registry row + 1 TL;DR sentence; ~5 LOC).

---

#### Claim 10.6: 🟡 MEDIUM — TL;DR section ตอนนี้ 10 stacked entries ลึก ครอบ ~25+ บรรทัด + ~60 บรรทัด boilerplate ซ้ำ; stakeholder skim test ล้มเหลว + amplifies Finding 10.1 contradiction

**Location:** `docs/state/impl-plan.md` TL;DR lines 3-25 (10 closure entries 2026-05-11 + 2026-05-12).

**Problem:**
TL;DR section เริ่มต้นเป็น "3-5 line executive summary" per Readability Dimension #10 + R03 fix; ตอนนี้บรรจุ 10 entries (newest top) — entries 2026-05-11/12 ครอบ ~80% ของ TL;DR. Stakeholder skim test: Tech Lead/PM อ่านรอบเดียวเพื่อเข้าใจสถานะปัจจุบัน เจอ:
- Entry 1: 🔴 IMPL-062 Run #2 catastrophic fail; recommend `/backtrack ba`
- Entry 2: 🟢 IMPL-FIX-003 Phase 1B closed (+465 LOC)
- Entry 3: 🟢 IMPL-FIX-011d Phase 2 iter-19 closed
- Entry 4: 🟢 IMPL-FIX-011d Phase 2 iter-17 + iter-18 closed
- Entry 5-10: iter-15/16, FORCE-PERIOD, Step 0, IMPL-FIX-011c closures from 2026-05-11

Reader ต้องอนุมาน chronological dependency จากลำดับ entry. Worse: ทุก entry duplicate `"Plan Staleness Sentinel unchanged at 0 IMPL-NNN closures since R25"` + `"Phase 5 mechanical gates 1+6+11 verified post-commit"` + `"State Reconciliation 3-file rule honored"` boilerplate — ~3 lines/entry × 10 entries = ~30 บรรทัด boilerplate ซ้ำ, plus Finding 10.1 contradiction ฝังในทุก entry. Signal-to-noise ratio พัง.

**Why this matters:**
Per CLAUDE.md Readability "stakeholder skim test" — junior dev / PM ควรอ่านสถานะ plan ได้ภายใน <2 นาที. ด้วย 10-entry TL;DR + 60+ boilerplate lines, test ล้มเหลว. การซ้ำ `"unchanged at 0 since R25"` boilerplate amplify Finding 10.1 — ทุก TL;DR entry ซ้ำ contradictory claim เดียวกัน 10 ครั้ง.

**Minimum acceptable fix:**
1. Cap TL;DR ที่ top 3 entries (most recent + most material). Older entries (≥4) → move to dedicated `## TL;DR Audit Trail` section ใต้ `## Plan Staleness Sentinel`.
2. Top entry ควรเป็น *current decision-pending action* — entry 1 (IMPL-062 Run #2 + `/backtrack ba` recommendation).
3. Remove duplicate Sentinel + mechanical-gate + State-Reconciliation boilerplate จากแต่ละ entry; consolidate ไปที่ `## Closure Hygiene Status` 3-line block ระดับเดียวกับ Plan Staleness Sentinel: `"Plan Staleness Sentinel: <N> closures since R09 (impl-plan-review chain). Phase 5 mechanical gates 1-11: last verified <date>. State Reconciliation 3-file rule: honored."`

**Effort:** Medium (~50-80 LOC refactor; pure prose reorganization).

---

## Cross-Document Issues

ไม่พบ contradictions ใหม่ข้าม `docs/design-docs/07-future-evolution.md` ↔ `08-product-breakdown.md` ↔ `impl-plan.md` (Evolution Sequence + Phase Hint citations ยังคง grounded). Cross-document issues ที่พบทั้งหมดเป็น **intra-plan parallel-narrative drift** (Findings 10.1-10.4 + 10.6) — ตรงกับ recurring weakness pattern R06→R07→R08→R09 (next-coarser-granularity drift each round).

---

## Recurring Weaknesses (rounds 06-09)

1. **Intra-plan parallel-narrative drift** recurs ที่ next-coarser granularity ทุกรอบ: R06/R07 caught TL;DR-vs-registry drift → R08 added Gate #7 (Phase Status Notes sweep) + Gate #8 (Open Risks + Next Best Action sweep) → R09 caught TL;DR-vs-diagnostic drift (one external artifact). **R10 (this round)** catches the same defect class at the **TL;DR-vs-Sentinel** layer (Finding 10.1 — 10× repetition of contradictory boilerplate) plus R-3/R-8/R-13 + Phase Status P4 + Next Best Action stale simultaneously (Finding 10.2). Gates #7/#8 มี documented แต่ engineer ไม่ invoke ใน 2026-05-11/12 closure burst (6 TL;DR entries ใน 2 วันโดยไม่มี full sweep).
2. **Closure narrative inflation** — ทุก TL;DR entry ตอนนี้มี ~3-line mechanical-gate / State Reconciliation boilerplate; เปลี่ยน canonical stakeholder-skim surface เป็น audit-log-of-audit-logs.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 10.1 | 🔴 CRITICAL | Plan Staleness Sentinel contradiction (TL;DR `0 since R25` vs § Sentinel `11 THRESHOLD`); ผสม impl-review/impl-plan-review chain | `impl-plan.md` TL;DR lines 5-25 + § Sentinel ~2258 | Low |
| 10.2 | 🟠 HIGH | Open Risks R-3/R-8/R-13 + Phase Status P4 Notes + Next Best Action ทั้งหมด stale; Gate #7+#8 ไม่ invoke | `impl-plan.md` § Open Risks + § Phase Status + § Next Best Action | Medium |
| 10.3 | 🟠 HIGH | IMPL-FIX-011 parent E-AC footnote ยัง cite "extend FIX-006/007/009 absorb expiry" (R09 09.7 superseded) | `impl-plan.md` § IMPL-FIX-011 parent ~line 1827 | Low |
| 10.4 | 🟠 HIGH | P4 Phase Gate "Empirical Demo" + NFR-1.1 check rows ไม่ flag Run #1/Run #2 falsification + pending /backtrack ba | `impl-plan.md` § P4 Phase Gate ~lines 1396, 1404 + IMPL-062 task | Low |
| 10.5 | 🟡 MEDIUM | IMPL-FIX-003 Phase 1B closure G2/G3/G4 deferred โดยไม่มี deferred-ac-registry row | `impl-plan.md` TL;DR line 9 + deferred-ac-registry.md | Low |
| 10.6 | 🟡 MEDIUM | TL;DR 10 stacked entries + ~60 boilerplate lines; skim test fail + amplifies 10.1 | `impl-plan.md` TL;DR lines 3-25 | Medium |

---

## End of Review
