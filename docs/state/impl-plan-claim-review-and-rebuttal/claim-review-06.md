# Implementation Plan Claim Review Round 06

| Field | Value |
|-------|-------|
| **Round** | 06 |
| **Target** | `docs/state/impl-plan.md` |
| **Date** | 2026-05-03 |
| **Reviewer** | Implementation Plan Reviewer (Adversarial Tech Lead) |
| **SKILLs** | andm-impl-plan-reviewer, code-review |
| **Trigger** | Plan Staleness Sentinel @ 48 closures since R05 (well above threshold of 10) — invoked by engineer per top callout `Action ถัดไป` ก่อน IMPL-039 BI SL fix (second G4 fix per ADR-009) |

---

## 📊 At-a-Glance

**Total findings:** 7 (🔴 CRITICAL 2 / 🟠 HIGH 3 / 🟡 MEDIUM 2 / 🔵 LOW 0)

**Mechanical pre-scans:**
- **Forbidden closure patterns:** `deferred to operator-runtime\|deferred to post-launch\|deferred per .* precedent\|structurally complete.*deferred\|live verification deferred` on `impl-plan.md` — **20 hits** on pattern `deferred per .* precedent` (CRITICAL count: 6 hits on `[x]` AC lines + 14 hits in `**Closed**:` metadata). Round 05 reported 0 hits — regression introduced during P2/P3 parallel batches #7-#12 (2026-05-03). 🔴
- **Forward reference (P_n → P_m, m>n):** **0 edges** ✅ (Phase Dependency Graph + per-task Deps walked; no P1→P2/P3/P4, no P2→P3/P4, no P3→P4 edges)
- **Silent Copy Detector:** H=68, A=67, D=1 (IMPL-013), V=0, N=0 → triggered? **N** (D≠0; explicit confirmation note also present at line 80-81) ✅
- **State reconciliation:** impl-plan ↔ overview ↔ registry ↔ handoff — **3 divergences detected** (Active count 25 vs TL;DR 26; P3 pending list omits IMPL-013; "commit pending" marker on closed tasks IMPL-018/IMPL-052) ⚠️

### Top 3 to Fix First
1. **Claim 06.1** 🔴 CRITICAL — 6 P1 `[x]` AC lines pre-author forbidden closure pattern "deferred to/until IMPL-XXX" + 14 `**Closed**:` metadata hits "deferred per <X> precedent" — `impl-plan.md` lines 362, 382, 398, 435, 452, 469 + closure metadata
2. **Claim 06.2** 🔴 CRITICAL — P1 Phase Gate "Deferred-AC drain ✅ empty for Phase=P1" contradicts 6 P1 inline `[x]` + deferred AC closures (registry never received P1 entries) — `impl-plan.md` line 239
3. **Claim 06.3** 🟠 HIGH — Phase Status Snapshot "P3 20/23" implies 3 pending; TL;DR mentions only IMPL-034 + IMPL-039; **IMPL-013 (per-slot inputs × 21) is open with all S-AC/E-AC `[ ]`** but missing from pending callout — `impl-plan.md` lines 7, 19, 792-810

### Verdict
- [ ] ✅ **Ready for Implementation Execution** — ไม่มี CRITICAL/HIGH
- [x] ⚠️ **Needs Rebuttal Round** — 2 CRITICAL + 3 HIGH → run `/impl-plan-rebuttal claim-review-06.md`
- [ ] ⛔ **Immediate Attention** — แม้ CRITICAL findings เป็น closure-discipline + state-reconciliation defects (recoverable via registry backfill + AC text rewording) ไม่ใช่ phase-shape blocker; rebuttal ควร resolve ครบในหนึ่ง round

---

## Implementation Plan Attack Vector Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Phase Shape & Phasing Rationale | ✅ Pass | 4-phase shape + Phasing Rationale paragraph + % targets table + `Net interpretation` paragraph อยู่ครบ; MoSCoW + risk + dep + value drivers cited; deviation P2 −24%/−34% และ P4 +15%/+25% มี architectural justification (ไม่ใช่ scope omission). ไม่พบ finding |
| 2 | SD Hint Alignment Audit Trail | ✅ Pass | E1..E2 = 5 ✅ Honored / 0 deferred / 0 violated. Phase Hints H=68: A=67 ✅ / D=1 ⚠️ (IMPL-013 P4→P3) / V=0 / ◻️=0. Silent Copy NOT triggered (D≠0; confirmation note at line 80-81 present). Audit trail at lines 78-104 well-formed. ไม่พบ finding |
| 3 | Task Decomposition & Sizing | ✅ Pass | ทุก task มี Phase + scope tag (`[ea]` / `[spec]`) + size (XS/S/M/L/XL); Task Summary matrix 7/23/29/8/1 = 68 ✅. IMPL-049 XL has Decomposition hint + per-sub-pass guidance (a/b/c/d). ไม่พบ finding |
| 4 | AC — Dual-Track Compliance | ⚠️ Finding 06.1 (CRITICAL) | **6 P1 `[x]` AC lines pre-author forbidden closure pattern** + 14 hits in `**Closed**:` metadata. ดู Claim 06.1 |
| 5 | Phase Gates — Testable Exit | ⚠️ Finding 06.6 (MEDIUM) + 06.5 (HIGH) | P1 Gate ปิดครบ 9 rows ✅; P2 Gate Override Log entry well-formed (named operator, scope, closure condition, expiry); P3/P4 Gate rows complete; placeholder evidence path "2026-MM-DD-phase2/4-evidence.md" still in plan (Claim 06.6); P2 Override closure depends on IMPL-053+ chain (Claim 06.5) |
| 6 | Deferred-AC Registry Init | ⚠️ Finding 06.2 (CRITICAL) | Registry initialized + Schema ครบ; Active table = 25 rows (5 P2 + 20 P3); Resolved table empty. **6 P1 tasks closed with inline deferred AC notes are NOT in registry** (see Claim 06.2 — drain row line 239 says "empty for Phase=P1 ✅" yet [x] AC lines 362/382/398/435/452/469 contain deferred clauses) |
| 7 | Cross-Phase Dependency | ✅ Pass | Walked all 68 task `Deps` fields + Mermaid Phase Dependency Graph: zero forward references. Evolution Sequence ordering preserved (E1 IMPL-046 P1 → E1a IMPL-047 P2 → E1b IMPL-048 P2 → E1c IMPL-049 P2 → E2 IMPL-018 P3) ✅ |
| 8 | State-File Consistency | ⚠️ Finding 06.3 (HIGH) + 06.4 (HIGH) + 06.7 (MEDIUM) | TL;DR claim "P3 20/23" omits IMPL-013 from pending list (Claim 06.3); Active count text "26" mismatches actual 25 rows (Claim 06.4); IMPL-018 / IMPL-052 closed with "commit pending" placeholder despite real commits (Claim 06.7) |
| 9 | Schedule-Leakage (SD Boundary) | ✅ Pass | Plan ใช้ ISO dates + audit-log timestamps (2026-05-02/03) เท่านั้น; ไม่พบ sprint number / Q1-Q4 / week-N labels. Deferred-AC expiry ใช้ ISO date 2026-05-17 (per registry rule ≤14 days). ไม่พบ leakage |
| 10 | Readability — Reader Empathy | ✅ Pass | TL;DR / At-a-Glance + Phase Status Snapshot + Open Risks + Next Best Action + Last Updated ครบ; bilingual ไทย-อังกฤษ; Phasing Rationale paragraph ไทย; Mermaid 2 graphs (Phase + Task Dependency) มี narrative; Stakeholder skim test pass ✅ |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

---

### Claim 06.1: 🔴 CRITICAL — Forbidden closure pattern hits — 6 P1 `[x]` AC lines + 14 `**Closed**:` metadata hits "deferred per <X> precedent"

**Location:**
- File: `docs/state/impl-plan.md`
- 6 `[x]` AC lines: 362 (IMPL-007), 382 (IMPL-008), 398 (IMPL-009), 435 (IMPL-011), 452 (IMPL-012), 469 (IMPL-014)
- 14 `**Closed**:` metadata hits: 581 (IMPL-040), 654 (IMPL-045), 718 (IMPL-049), 735 (IMPL-050), 752 (IMPL-051), 770 (IMPL-052), + 8 P3 slot tasks

**Problem:**

Mechanical pre-scan grep `deferred per .* precedent` returned 20 hits — Round 05 reported 0 hits ✅, ดังนั้น regression introduced during parallel batches #7-#12 (2026-05-03).

**Type 1: P1 `[x]` AC lines pre-authoring forbidden closure (6 hits) — verbatim quotes:**

- Line 362 (IMPL-007 Refresh): `[x] Refresh() queries PositionSelectByTicket per m_map[*].ticket_ids[] ... — Step 1 ... shipped; Step 2 (PositionsTotal() broker reconcile loop) TODO IMPL-007-refresh **deferred to IMPL-053+ + IMPL-018+** (no entry .mq5 yet)`
- Line 382 (IMPL-008 SelfTest): `[x] Unit-style test inside OnInit ถ้า ENABLE_SELFTEST flag = on → emit Print log ... — ... live OnInit wiring deferred to IMPL-040+ orchestrator`
- Line 398 (IMPL-009 PipMath Logger): `[x] OnInit Logger Info "pip_math digit_multiplier=10" on FBS-Real [log-assertion] — Print stub at lines 32-33 emits ... live Logger assertion deferred until IMPL-042 wires Logger`
- Line 435 (IMPL-011 JsonWriter SelfTest): `[x] Self-test in OnInit if (ENABLE_SELFTEST) → Print "json_writer_self_test pass" [log-assertion] — ... live emission deferred until orchestrator IMPL-053`
- Line 452 (IMPL-012 input dialog probe): `[x] MT5 attach EA → input dialog renders 20+ entries grouped under "General" section [probe] — structurally verified via grep ... live MT5 dialog probe deferred until entry .mq5 exists at IMPL-018+ (mirrors IMPL-014 precedent)`
- Line 469 (IMPL-014 input dialog probe): `[x] MT5 attach EA → input dialog has 3 distinct groups (TimeGates / Pending / Logging) ... live MT5 dialog probe deferred until entry .mq5 exists at IMPL-018+ + IMPL-042 Logger wiring`

ทุกบรรทัดข้างบน **`[x]`-marked AC** + closure note **"deferred until/per/to IMPL-XXX"** = forbidden pattern per CLAUDE.md § Empirical Closure Discipline + `deferred-ac-registry.md § PhoenicisNex-specific anti-pattern catalog`:

> ❌ `[x]` + `<!-- live verification deferred per IMPL-XXX precedent -->`

**Type 2: 14 `**Closed**:` metadata hits "deferred per <X> precedent" — verbatim quotes:**

- Line 581 (IMPL-040): `Closed: ... G2-G4 deferred per header-only precedent`
- Line 654 (IMPL-045): `Closed: ... G2-G4 deferred per header-only precedent`
- Line 718 (IMPL-049): `Closed: ... G2-G4 deferred per IMPL-052 header-only .mqh precedent`
- Line 735 (IMPL-050): `Closed: ... G2-G4 deferred per IMPL-005/007/011 header-only precedent`
- Line 752 (IMPL-051): `Closed: ... G2-G4 deferred per IMPL-005/007/011 header-only precedent`
- Line 770 (IMPL-052): `Closed: ... G2-G4 deferred per IMPL-005/007/011 header-only precedent`
- + 8 P3 slot Closed: lines that share the "G2-G4 deferred per IMPL-018+ precedent" idiom

ทุกบรรทัด **`[x]`-marked task closure** + "G2-G4 deferred per <task> precedent" = forbidden pattern per Workflow Phase 2.2.1: "ทุก hit บน `[x]`-marked AC line = CRITICAL. ทุก hit บน AC text (regardless of `[x]`) = CRITICAL (planner pre-authoring violation)."

**Why This Matters:**

1. **Engineer pre-authoring loophole** — closure pattern "G2-G4 deferred per header-only precedent" allows future tasks (IMPL-039 BI SL fix, IMPL-034 Slot P) to ปิด `[x]` ด้วย structural-only test pass + reuse precedent label. Empirical Closure Discipline ถูก degraded ทุกรอบ; 2 CRITICAL fixes (G4 SL + Magic-J) อาจปิดด้วย structural test เท่านั้น.
2. **Registry bypass** — 6 P1 deferred E-ACs ไม่อยู่ใน registry (see Claim 06.2 separate issue) ทำให้ไม่มี 14-day expiry, ไม่มี `/impl-task` HALT, ไม่มี `/deliver` block.
3. **Audit gap (Shark CMS defect class)** — exact pattern that motivated SKILL: "structurally complete ... deferred to operator-runtime / deferred per X precedent" — engineer ปิด task structurally, expects future task to verify, future task ปิดด้วย precedent reference ทำให้ chain unverifiable.
4. **Round 05 false-clean** — R05 reviewer reported "0 hits ✅" (claim-review-05.md line 19). ระหว่าง R05 → R06 (2 days, 33 task closures) มี 20 hits introduced. Indicates the mechanical scan must be re-run *before each phase gate close* ไม่ใช่ at-review-time only.

**Minimum Acceptable Fix:**

**For Type 1 (6 [x] AC lines):** ทุกบรรทัดเลือกได้ 1 ใน 3:
1. **Reword** — ลบคำว่า "deferred until/per/to IMPL-XXX" + เปลี่ยน AC text ให้เป็น structural-verifiable เลย (e.g., "Print stub matches ADR-011 stable prefix `[Phoenicis][slot=system][ev=pip_math_init]`" — ไม่อ้างถึง future task)
2. **Split AC** — แยกเป็น (a) S-AC structural ที่ปิดได้ตอนนี้ + (b) E-AC empirical — เปิด registry row สำหรับ E-AC พร้อม 14-day expiry
3. **Open registry row** — ถ้า task มี genuinely deferrable E-AC → ลบ `[x]` + เปิด row ที่ `deferred-ac-registry.md § Active` พร้อม owner + Opened + Expires + Risk-if-missed

**For Type 2 (14 Closed: metadata hits):** เปลี่ยน "G2-G4 deferred per header-only precedent" เป็น explicit registry citation, e.g., "G2-G4 tracked in `deferred-ac-registry.md § Active` row IMPL-NNN expiry 2026-05-17". ลบ "precedent" wording ทั้งหมด.

**For prevention:** เพิ่ม `grep` step ใน `/impl-task` Phase 5 Closure (engineer side) เป็น new gate — ถ้า new `[x]` AC line ตรงกับ forbidden pattern → HALT พร้อม remediation prompt.

**Level of Effort:** Medium — 6 AC line rewrites + 14 closure metadata rewrites + 1 grep gate addition; ไม่กระทบ scope, sizing, dependency, หรือ Phase Gate.

---

### Claim 06.2: 🔴 CRITICAL — P1 Phase Gate "Deferred-AC drain ✅ empty for Phase=P1" contradicts 6 inline `[x]` + deferred AC closures (registry never received P1 entries)

**Location:**
- File: `docs/state/impl-plan.md`, line 239 (P1 Phase Gate row)
- Cross-ref: `docs/state/deferred-ac-registry.md § Active` table (no P1 rows ever)
- Affected tasks: IMPL-007, IMPL-008, IMPL-009, IMPL-011, IMPL-012, IMPL-014 (all closed `[x]` 2026-05-02 with deferred E-AC inline)

**Problem:**

P1 Phase Gate Drain row line 239 verbatim:

> `[x] **Deferred-AC drain:** docs/state/deferred-ac-registry.md § Active empty for Phase=P1 ✅ 2026-05-02`

Yet `deferred-ac-registry.md § Active` table has **zero P1 rows** ever opened (only 5 P2 + 20 P3 rows currently). The drain check passes trivially because registry never received P1 entries — but the actual deferred work เคย exist + still exists at lines 362, 382, 398, 435, 452, 469 inside P1 task `[x]` AC bodies.

**Examples (already cited in Claim 06.1):**

- IMPL-007 Step 2 PositionsTotal reconcile loop = TODO + "deferred to IMPL-053+ + IMPL-018+"
- IMPL-008 OnInit SelfTest live emission = "deferred to IMPL-040+ orchestrator"
- IMPL-009 Logger Info live assertion = "deferred until IMPL-042 wires Logger"
- IMPL-011 JsonWriter SelfTest live emission = "deferred until orchestrator IMPL-053"
- IMPL-012 + IMPL-014 MT5 input dialog probes = "deferred until entry .mq5 exists at IMPL-018+"

**Why This Matters:**

1. **Phase Gate Hallucination** — P1 Gate technically `[x]` ครบ 9 rows + Drain ✅; `/next` reports "P1 closed 2026-05-02" + recommends P2. แต่ deferred work จริง ๆ ฝังอยู่ใน [x] task AC ไม่ได้ tracked. ซ้ำรอย Shark CMS defect class.
2. **Registry not enforcing 14-day expiry on P1 work** — 6 P1 deferred E-ACs ผ่านมา 1+ วันแล้ว แต่ไม่มี registry row → ไม่มี HALT trigger ใน `/impl-task`, ไม่มี renewal prompt, ไม่มี `/deliver` block.
3. **`/deliver` block bypass risk** — Rule #5 ของ registry: "`/deliver` ห้าม ship project ขณะที่ Active table มี row ใดอยู่". ถ้า engineer ลืม backfill registry, `/deliver` จะปล่อย ship แม้ 6 deferred items ยังไม่ exercise.
4. **Forensic regression: เมื่อ IMPL-018+/IMPL-053+ ลง orchestrator แต่ไม่ revisit P1 deferred E-ACs**, ความเสียหายไม่ปรากฏจนกว่า QA Phase 3T (IMPL-061..068) — late-detection multiplier ของ Bucket A drift.

**Minimum Acceptable Fix:**

1. **Backfill registry** — เปิด 6 Active rows ใน `deferred-ac-registry.md § Active` ก่อนปิด review:
   ```
   | P1 | IMPL-007 | "magics registered: 17" Logger.Debug + GetByMagic.total_profit broker reconcile [log-assertion]+[db-inspect] | log-assertion | Orchestrator wires Init→RegisterAll + entry .mq5 + Strategy Tester run | Kritsana | 2026-05-03 | 2026-05-17 | PortfolioState reconcile path untested under real flow; CHashMap consistency drift undetected until QA Phase 3T |
   | P1 | IMPL-008 | comment_parser_self_test pass live emission via Logger [log-assertion] | log-assertion | Orchestrator wires SelfTest in OnInit + Tester run | Kritsana | 2026-05-03 | 2026-05-17 | ... |
   | P1 | IMPL-009 | pip_math digit_multiplier=10 Logger Info live emission [log-assertion] | log-assertion | IMPL-042 Logger wiring + Tester run | Kritsana | 2026-05-03 | 2026-05-17 | ... |
   | P1 | IMPL-011 | json_writer_self_test pass live emission + JournalEvent round-trip [log-assertion]+[contract-roundtrip] | contract-roundtrip | IMPL-018+/IMPL-053+ Orchestrator + IMPL-043 file-write | Kritsana | 2026-05-03 | 2026-05-17 | ... |
   | P1 | IMPL-012 | MT5 input dialog renders 20+ entries grouped "General" [probe] | probe | entry .mq5 + IMPL-053+ Orchestrator | Kritsana | 2026-05-03 | 2026-05-17 | ... |
   | P1 | IMPL-014 | MT5 input dialog 3 groups (TimeGates/Pending/Logging) [probe] | probe | entry .mq5 + IMPL-053+ + IMPL-042 Logger | Kritsana | 2026-05-03 | 2026-05-17 | ... |
   ```
2. **Update P1 Phase Gate row 239** — change from ✅ to ⚠️ retroactive: "Deferred-AC drain: 6 P1 rows backfilled to registry post-R06 (originally inline-deferred at task closure 2026-05-02; expiry 2026-05-17)" — preserves audit trail without re-opening Phase Gate.
3. **Update P1 Phase Gate row 6 (Code review)** — ratify that this CRITICAL was found during R06 (post-close); cite claim-review-06 + rebuttal-06.
4. **Reword AC lines per Claim 06.1 fix** — coupling: AC lines lose "deferred to IMPL-XXX" wording; replace with registry-row citation.

**Level of Effort:** Medium — registry backfill + Phase Gate row update + cross-reference grep verification.

---

### 🟠 HIGH

---

### Claim 06.3: 🟠 HIGH — Phase Status Snapshot "P3 20/23" implies 3 pending; TL;DR mentions only 2 (IMPL-034 + IMPL-039); IMPL-013 is open but missing from pending callout

**Location:**
- File: `docs/state/impl-plan.md`
- Top callout TL;DR (line 7): `... Slot_BI (IMPL-039 = second G4 fix per ADR-009) + Slot_P (IMPL-034) still pending`
- Phase Status Snapshot row P3 (line 19): `🔄 20/23 — IMPL-018/019/020/021/022/023/024/025/026/027/028/029/030/031/032/033/035/036/037/038 ✅`
- IMPL-013 task body (lines 792-810): all S-AC `[ ]` + all E-AC `[ ]`

**Problem:**

P3 has 23 tasks (IMPL-013 + IMPL-018 + IMPL-019..039 = 1 + 1 + 21 = 23). TL;DR + Phase Status both report 20 closed. 23 − 20 = 3 pending. But TL;DR pending list mentions เพียง IMPL-034 (Slot P) + IMPL-039 (Slot BI). **IMPL-013 (per-slot inputs × 21) is open** — task body lines 800-805 show all 3 S-AC + 2 E-AC checkboxes `[ ]` — แต่หายไปจาก pending list.

**Examples (verbatim quotes):**

- Line 7 (TL;DR Action ถัดไป): `... then IMPL-039 (L Slot_BI — ⚠️ G4 SL fix per ADR-009, HIGH RISK Bucket B drift NFR-1.8) **OR** IMPL-034 (L Slot_P — A7 risk).`
- Line 800 (IMPL-013 S-AC): `[ ] 21 input files exist + each has group="Slot X" annotation`
- Line 801 (IMPL-013 S-AC): `[ ] Default values match CodeWiki §3 baseline per slot`
- Line 802 (IMPL-013 S-AC): `[ ] Total cross-file input count contributes to ≥ 80 (NFR-4.3 with IMPL-012 + IMPL-014)`

**Why This Matters:**

1. **`/next` mis-recommendation** — operator runs `/next` หลัง R06; reads top callout; sees "IMPL-039 OR IMPL-034 still pending"; chooses IMPL-039 (HIGH RISK Bucket B drift, second G4 fix). Engineer ทำ IMPL-039 → G1 compile fail เพราะ `Slot_BI.mqh` references `Inp<BI>...` symbols ไม่ exist (per IMPL-013 description: "ship `Inputs_Slot_X.mqh` คู่กับ `Slot_X.mqh` ใน same commit"). Cascades: G2/G3/G4 also fail.
2. **Effective state** — IMPL-013 description says "may complete as 21 sub-tasks bundled with IMPL-019..039 OR as one batch landing". 20 P3 slot tasks already ✅ closed; ทุก slot has `Inputs_Slot_<X>.mqh` ที่ commit คู่ — meaning IMPL-013 is **effectively done structurally**, but top-level [ ] AC checkboxes never updated. State drift.
3. **Phase Gate readiness false-positive** — when P3 attempts close, Phase Gate row "Structural Acceptance: all 23 P3 tasks ปิด `[x]` ครบ" จะ fail because IMPL-013 still `[ ]`. Engineer may either (a) bulk-tick `[x]` without re-verification (audit gap) or (b) realize 21 sub-tasks were never tracked in IMPL-013 (rework cost).

**Minimum Acceptable Fix:**

1. **Resolve IMPL-013 closure status** — engineer/defender ตัดสินใจ:
   - **Option A:** ถ้า 21 per-slot input files ลงคู่กับแต่ละ slot ที่ ✅ closed แล้ว (likely, per IMPL-013 description) → tick `[x]` ทุก S-AC + E-AC ของ IMPL-013 + add `**Closed**: 2026-05-03 (effective rolling-close across batches #8/#9/#10/#11/#12 — per-slot Inputs_Slot_<X>.mqh shipped paired with each Slot_<X>.mqh per IMPL-013 description "ship คู่กัน in same commit"); evidence: cite 20 prior IMPL-NNN evidence files + grep verification ` `grep -c '^input ' inputs/Inputs_Slot_*.mqh` ` ≥ target count`
   - **Option B:** ถ้า 21 input files ยังไม่ landing → keep `[ ]`; update TL;DR pending list to "IMPL-013 + IMPL-034 + IMPL-039"; engineer ship IMPL-013 ก่อน IMPL-034/039
2. **Update Phase Status Snapshot row P3** — change "20/23" to "21/23" (Option A) or keep "20/23" (Option B) + reflect IMPL-013 status explicitly
3. **Update TL;DR top callout** — Action ถัดไป + pending callout reflect chosen option

**Level of Effort:** Low — 1 task body checkbox sweep + 2 narrative updates + grep verification.

---

### Claim 06.4: 🟠 HIGH — TL;DR Active count "5 P2 + 21 P3 = 26" mismatches actual registry (5 P2 + 20 P3 = 25)

**Location:**
- File: `docs/state/impl-plan.md`, top callout TL;DR line 8
- Cross-ref: `docs/state/deferred-ac-registry.md § Active` (actual count)

**Problem:**

TL;DR line 8 verbatim:

> `**Deferred-AC Active:** 5 P2 rows + 21 P3 E-AC deferrals (IMPL-019/020/021/022/023/024/025/026/027/028/029/030/031/032/033/035/036/037/038 smoke 60-day backtest + IMPL-022 G4 attestation — block on IMPL-053+ Orchestrator)`

นับ unique IMPL-NNN ใน list: IMPL-019/020/021/022/023/024/025/026/027/028/029/030/031/032/033/035/036/037/038 = **19 entries**. Plus "IMPL-022 G4 attestation" (second row for IMPL-022) = 20 P3 rows total. แต่ text says "21 P3 E-AC deferrals".

Registry actual `§ Active` table mark-up: 20 P3 rows (IMPL-026, IMPL-029, IMPL-030, IMPL-027, IMPL-028, IMPL-031, IMPL-032, IMPL-033, IMPL-035, IMPL-019, IMPL-036, IMPL-020, IMPL-021, IMPL-022 row 1, IMPL-022 row 2, IMPL-038, IMPL-037, IMPL-023, IMPL-024, IMPL-025) = 20 ✓.

Total Active: TL;DR text claims 5 + 21 = **26**; registry actual 5 + 20 = **25**. Off-by-one.

**Why This Matters:**

1. **`/next` Check 5.5 (State Single Source of Truth)** — TL;DR derived view diverges from primary SoT (registry). Per CLAUDE.md §6 State Reconciliation Discipline: "ห้าม update เพียงไฟล์เดียว — drift ระหว่างไฟล์ทำให้ `/next` รายงานผิด, `/impl-task` หยิบ task ผิด, status agents hallucinate phase complete".
2. **`/deliver` block enumeration** — `/deliver` Rule #5 reads registry Active count ก่อน ship. ถ้า engineer trust TL;DR "26" + manually drains 26 rows, registry has 25 (1 ghost drain) — minor but indicates state hygiene gap.
3. **Same defect class as rebuttal-round-03** — readiness-marker propagation; defender's 7-marker sweep convention should have caught this but didn't (TL;DR Active count is not in the 7-marker checklist).

**Minimum Acceptable Fix:**

1. **Fix TL;DR line 8** — change "21 P3 E-AC deferrals" → "20 P3 E-AC deferrals" + total `5 + 20 = 25 Active rows`
2. **Extend defender's 7-marker sweep** to 8 markers — add "TL;DR Active count" as marker #8 (verify against `wc -l docs/state/deferred-ac-registry.md` + manual table count)
3. **Optional — add automated grep check** in `/impl-task` Phase 5 closure: `python -c "import yaml ..."` or similar to count registry rows + diff vs TL;DR text

**Level of Effort:** Low — text edit + convention extension.

---

### Claim 06.5: 🟠 HIGH — P2 Phase Gate Override closure condition encodes circular dependency on IMPL-053+ Orchestrator chain (P4); 5 P2 deferred-AC rows expire 2026-05-17, single renewal allowed → hard deadline 2026-05-31 for 6 P4 tasks (IMPL-053..060)

**Location:**
- File: `docs/state/impl-plan.md`, § Phase Gate Override Log (line ~1571)
- Cross-ref: `docs/state/deferred-ac-registry.md § Active` 5 P2 rows (IMPL-043×2, IMPL-049×2, IMPL-052×1) all "Expires: 2026-05-17"

**Problem:**

Phase Gate Override Log row 2026-05-03 (verbatim):

> `Override scope: P3 IMPL-018 + IMPL-053..058 Orchestrator chain only. Closure condition: when IMPL-018 + Orchestrator skeleton can attach EA + run simulation/headless-tests/p2_services_smoke.ini (no slots active), produce evidence artifact at _session-handoff/2026-MM-DD-phase2-evidence.md + run Tier 1.5 walk, then drain 5 Active P2 rows + tick IMPL-P2-GATE rows. 5 Active P2 rows expire 2026-05-17; renewal once allowed if needed.`

P2 Phase Gate retroactive close depends on:
1. IMPL-018 ✅ (P3, closed 2026-05-03)
2. IMPL-019..039 (P3, 20/23 closed; IMPL-013/034/039 pending)
3. IMPL-053..058 (P4 cross-slot coordinator, **all `[ ]`**)
4. IMPL-059 Orchestrator composition root (P4, `[ ]`)
5. IMPL-060 PhoenicisNex.mq5 entry point (P4, `[ ]`)
6. Tier 1.5 walk via `p2_services_smoke.ini` requires entry .mq5 + Orchestrator wiring

Effective dependency: **6 P4 tasks (IMPL-053..060)** ต้องลงให้เสร็จก่อน P2 Gate retroactive close.

Timeline math:
- 5 P2 rows opened 2026-05-03 + 14d expiry = **2026-05-17** (first hard deadline)
- Single renewal (per registry rule #3): +14d = **2026-05-31** (second/final deadline)
- 6 P4 tasks (M+M+S+XS+XS+M sizes per matrix) = 28 days nominal
- P3 still has 3 open tasks (IMPL-013, IMPL-034, IMPL-039 — IMPL-039 is HIGH RISK G4 fix)

**Why This Matters:**

1. **Hard deadline cascading** — ถ้า IMPL-039 + IMPL-053..060 ใด ๆ slip ผ่าน 2026-05-31, registry rule #3(c) triggers `/backtrack` escalation; P2 Gate stays open indefinitely; `/deliver` blocked.
2. **Renewal + Phase Gate Override = bypass risk** — ทั้งสอง mechanisms ออกแบบเป็น exception escape. ใช้ทั้งคู่ใน same window = compounding bypass risk per defender SKILL § Anti-pattern catalog.
3. **Closure condition placeholder evidence path** — "produce evidence artifact at _session-handoff/2026-MM-DD-phase2-evidence.md" still has placeholder date (Claim 06.6 separate finding). Engineer might forget to substitute at close.
4. **Override row well-formed but fragile** — named operator (Kritsana) ✓, scope ✓, closure condition ✓, expiry ✓, reference to nomination doc ✓. Issue is timeline arithmetic, not Override structure.

**Minimum Acceptable Fix:**

1. **Add timeline risk note to Open Risks (line 24-32)** — new R-6: "P2 Phase Gate retroactive close blocked on 6 P4 tasks IMPL-053..060; 5 P2 deferred-AC rows expire 2026-05-17 (single renewal to 2026-05-31). Earliest mitigation: prioritize IMPL-053+/IMPL-059/IMPL-060 in next P4 batch; consider re-scoping IMPL-053 RunSafePort fully fixturable without RunOrderGroup2/RunForceCutloss to unblock walk earlier."
2. **Update Phase Gate Override row** to add explicit hard-stop date — append "Hard-stop: if 5 P2 rows hit final renewal expiry 2026-05-31 without retroactive close → escalate via `/backtrack sd` to revisit P2 boundary."
3. **Substitute placeholder evidence path** at close (Claim 06.6 — see below).

**Level of Effort:** Low — narrative update + timeline annotation.

---

### 🟡 MEDIUM

---

### Claim 06.6: 🟡 MEDIUM — Phase Gate placeholder evidence paths "2026-MM-DD-phase{2,4}-{evidence,exploratory-walk}.md" still in plan; risk being committed unsubstituted at gate close

**Location:**
- File: `docs/state/impl-plan.md`
- P2 Phase Gate Empirical Demo (line 554): `Evidence: docs/state/_session-handoff/2026-MM-DD-phase2-evidence.md`
- P2 Tier 1.5 Walk (line 555): `Artifact: docs/state/_session-handoff/2026-MM-DD-phase2-exploratory-walk.md`
- P4 Phase Gate Empirical Demo (line 1251): `Evidence: docs/state/_session-handoff/2026-MM-DD-phase4-evidence.md + linked HTML report`
- P4 Tier 1.5 Walk (line 1252): `Artifact: docs/state/_session-handoff/2026-MM-DD-phase4-exploratory-walk.md`

**Problem:**

4 placeholder paths still in plan. Engineer must substitute concrete date + filename ก่อน Phase Gate close. Same defect class as rebuttal-round-03 caught with stale "review pending" markers — once Phase Gate closes, engineer might forget to substitute, leaving `2026-MM-DD-` literal in `[x]` Phase Gate row → derived `/next` reads dangling path.

P1 Phase Gate (closed 2026-05-02) + Override Log (line 1571) ก็มี literal "2026-MM-DD-phase2-evidence.md" reference — confirming this is recurring placeholder pattern not yet swept.

**Why This Matters:**

1. **Defender 7-marker sweep convention extends here** — per rebuttal-round-03 § Defender Self-Correction, "When closing any rebuttal round, defender MUST update ALL of the following markers". Placeholder evidence paths are not in the 7-marker checklist but exhibit the same propagation defect class.
2. **`/next` reads Phase Gate evidence path** — if `[x]` Phase Gate row still has literal "2026-MM-DD-..." path, `/next` Check 6 (Three-Tier Closure scan) might surface "evidence file does not exist" warning incorrectly OR validate the literal placeholder as a real path (file system race condition).

**Minimum Acceptable Fix:**

1. **Substitute concrete placeholders for closed Phase Gates** — P1 Phase Gate closed 2026-05-02; P1 evidence path should already be `_session-handoff/IMPL-046-evidence-20260502.md` (which is what P1 Empirical Demo row 234 actually says). Override Log row line 1571 references `_session-handoff/2026-MM-DD-phase2-evidence.md` — substitute with eventual concrete path on close.
2. **Replace remaining placeholders with TBD-marker** — for P2/P4 (still open), replace `2026-MM-DD-phase2-evidence.md` → `<TBD-phase2-evidence>` or similar non-date placeholder ที่ engineer แน่ใจว่า not-a-real-path during interim.
3. **Extend defender sweep to marker #9** — add "Phase Gate evidence/walk placeholder paths" to defender's 7-marker checklist (now 9-marker with Claim 06.4 + 06.6).

**Level of Effort:** Low — 4 path substitutions + convention extension.

---

### Claim 06.7: 🟡 MEDIUM — Closed task metadata "commit pending" stale on IMPL-018 + IMPL-052 despite real commits existing in git log

**Location:**
- File: `docs/state/impl-plan.md`
- IMPL-018 Closed (line 827): `**Closed**: 2026-05-03 (commit pending); G1 Spike_CSlotBase.mq5 = 0 errors / 0 warnings / 605 ms ...`
- IMPL-052 Closed (line 770): `**Closed**: 2026-05-03 (commit pending); S-AC 2/2 [x]; E-AC 2/2 [x] via SelfTest bypass ...`

**Problem:**

Both task closures have placeholder "commit pending" text where commit hash should appear (other closed tasks use pattern `(commit fe78218)` or `(commit 1ece5ae)`). Git log shows recent commits 1ff3b3d, dca5e98, 3266fd7, 7e62dbe, 8a44ca2 — engineer likely committed but didn't substitute the hash back into Closed metadata.

Same defect class as rebuttal-round-03 Claim 03.3 caught with "round 01 = ✅" stale references — propagation gap between commit creation + plan metadata update.

**Why This Matters:**

1. **Audit trail gap** — Code review reviewer / `/impl-review` reads Closed metadata to identify which commit introduced what. "commit pending" = manual git-blame required.
2. **Round 03 cleanup convention extends here** — defender 7-marker sweep doesn't cover this; another extension needed.
3. **Lower severity than 06.4/06.6** because git is the authoritative SoT for commit hashes; plan metadata is derived. ไม่ block downstream tasks.

**Minimum Acceptable Fix:**

1. **Substitute commit hashes** — `git log --oneline --grep=IMPL-018` + `git log --oneline --grep=IMPL-052` to find hashes; replace "commit pending" verbatim
2. **Extend defender sweep to marker #10** — add "Closed: (commit pending) substitution check" to defender's 9-marker (after Claims 06.4 + 06.6 add markers #8 + #9)

**Level of Effort:** Low — 2 git log lookups + 2 text substitutions.

---

### 🔵 LOW

_ไม่มี — ทุก finding ที่ต่ำกว่า MEDIUM threshold (sub-optimal but executable) จัด MEDIUM แล้ว เพราะ recurring nature (3 of 4 = same propagation defect class as rebuttal-round-03) elevates them above LOW polish_

---

## Cross-Document Issues

ไม่พบ contradictions ระหว่าง `docs/design-docs/07-future-evolution.md` Evolution Sequence + `docs/design-docs/08-product-breakdown.md` Phase Hints + `docs/state/impl-plan.md` SD Hint Alignment audit trail. 5/5 Evolution steps ✅ honored; 67/68 Phase Hints ✅ honored + 1/68 ⚠️ diverged (IMPL-013) with documented Service-coupling rule justification.

ADR citations (ADR-001 through ADR-012) all valid — `docs/adr/` มีไฟล์ครบ + status ไม่มี Superseded ในที่ plan อ้างอิง.

API spec citations valid — `docs/api-specs/{trade-journal-schema,state-persistence-schema,market-context-schema,slot-state-schema}.yaml` referenced + locked at IMPL-044 + IMPL-048 (R05 sweep).

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 06.1 | 🔴 CRITICAL | Forbidden closure pattern — 6 P1 [x] AC + 14 Closed: metadata hits "deferred per <X> precedent" | `impl-plan.md` lines 362/382/398/435/452/469 + 14 Closed: lines | Medium |
| 06.2 | 🔴 CRITICAL | P1 Phase Gate "Drain ✅ empty for P1" contradicts 6 inline [x]+deferred AC closures (registry never received P1 entries) | `impl-plan.md` line 239 + `deferred-ac-registry.md § Active` | Medium |
| 06.3 | 🟠 HIGH | Phase Status "P3 20/23" + TL;DR pending callout omits IMPL-013 (open, all S-AC/E-AC `[ ]`) | `impl-plan.md` lines 7, 19, 792-810 | Low |
| 06.4 | 🟠 HIGH | TL;DR Active count "5 P2 + 21 P3 = 26" mismatches registry actual (5 P2 + 20 P3 = 25) | `impl-plan.md` line 8 | Low |
| 06.5 | 🟠 HIGH | P2 Phase Gate Override closure condition encodes circular dep on IMPL-053..060 P4 chain; 14d+14d hard-stop 2026-05-31 | `impl-plan.md` § Phase Gate Override Log + Open Risks | Low |
| 06.6 | 🟡 MEDIUM | Placeholder evidence paths "2026-MM-DD-phase{2,4}-{evidence,exploratory-walk}.md" risk being committed unsubstituted | `impl-plan.md` lines 554, 555, 1251, 1252, 1571 | Low |
| 06.7 | 🟡 MEDIUM | "commit pending" stale on IMPL-018 (line 827) + IMPL-052 (line 770) despite real commits in git log | `impl-plan.md` lines 770, 827 | Low |

---

## Reviewer's Closing Note

R06 differs จาก R01-R05 sharply:

**R01-R03** focused on plan-quality defects (sizing, AC dimensionality, Phasing Rationale narrative, readiness markers).
**R04-R05** were sentinel-triggered sweeps (post parallel batches #5/#6) ที่หา drift หลังการ closure burst — both 0-finding rounds (clean propagation).

**R06** caught 2 CRITICAL findings ที่ R05 ไม่เห็น เพราะ R05 grep pattern `deferred per .* precedent` returned 0 hits at that time. ระหว่าง R05 (2026-05-02) → R06 (2026-05-03), parallel batches #7-#12 ปิด 33 tasks + introduced 20 forbidden-pattern hits (6 in `[x]` AC + 14 in Closed: metadata). **Mechanical pre-scan must run before each phase gate close, ไม่ใช่ at-review-time only** — กล่าวอีกอัตว่า Plan Staleness Sentinel @ 48 closures since R05 = correct trigger, แต่ engineer-side `/impl-task` Phase 5 closure should also run forbidden-pattern grep ทุก task close (proposed gate addition, see Claim 06.1 fix).

CRITICAL findings ทั้ง 2 เป็น recoverable closure-discipline + state-reconciliation defects (registry backfill + AC text rewording + Phase Gate row update); ไม่ block phase-shape architecture หรือ Evolution Sequence ordering. 1 round rebuttal ควร resolve ครบ.

HIGH findings 06.3/06.4/06.7 เป็น propagation defects ใน same defect class as rebuttal-round-03 — defender's 7-marker sweep convention covered subset แต่ไม่ครอบคลุม TL;DR Active count, IMPL-013 pending status, "commit pending" substitution. **Convention should extend to 10 markers post-R06** (per Claims 06.4 + 06.6 + 06.7).

HIGH finding 06.5 (Phase Gate Override timeline) เป็น risk-warning ไม่ใช่ defect — Override row well-formed; แต่ 28-day cumulative deadline ขณะ P3 ยังเหลือ 3 task + P4 ยังไม่เริ่ม = fragile chain. Mitigation = open R-6 line + hard-stop annotation.

**Verdict:** ⚠️ **Needs Rebuttal Round** — proceed to `/impl-plan-rebuttal claim-review-06.md`.

— Implementation Plan Reviewer (Adversarial Tech Lead)
2026-05-03
