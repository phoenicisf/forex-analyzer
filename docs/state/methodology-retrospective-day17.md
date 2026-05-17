# ANDM Methodology Retrospective — PhoenicisNex, Day 17

> **Author:** Claude (Opus 4.7, working session 2026-05-17)
> **Audience:** ANDM methodology owner (review + iterate)
> **Scope:** 2026-05-02 → 2026-05-17 (17 calendar days; 11 active working days)
> **Source data:** `git log`, `docs/state/{overview,impl-plan,deferred-ac-registry,operator-action-registry,backtrack-log,current_handoff}.md`, `docs/code-review/*`, `docs/state/_session-handoff/*`

---

## 1. Project Context (for the methodology owner)

**Stack & shape.** PhoenicisNex คือ greenfield rewrite ของ MQL5 Expert Advisor `PhoenicisN2.10_stable.mq5` (22k LOC legacy single-file) → modular monolith 21 slots + 13 services + 12 ADRs ใน MetaTrader 5 sandbox. Single instrument (EURUSD H4), solo operator, no GUI, no network listener, no external DLLs. Storage = file-based (`state.json` atomic + JSON-Lines `journal/*.jsonl`).

**Why the project is unusual relative to other ANDM projects:**
- **No web UI** — Tier 1.5 "Exploratory Walk" คือ headless backtest + Tester log parse แทน operator-clicks-through-screens. `mt5-headless-backtest` + `mt5-log-reader` SKILLs ทำหน้าที่นี้.
- **No env vars / secrets / config-audit triggers** — Phase 1 = local sandbox; `operator-action-registry.md` initialized empty + ส่วนใหญ่ stays empty (เพิ่งมี OPS-001/OPS-002 ครั้งแรกใน day 16-17 จาก tick-cache freshness).
- **No unit-test framework** — MQL5 ecosystem ไม่มี; empirical verification = compile log (G1) + smoke (G2) + Strategy Tester (G3) + log+journal review (G4).
- **Hard parity contract** — NFR-1.1 บังคับว่า rewrite ต้องเทรดด้วย behavioral parity ≤ 25% drift vs 5-yr legacy baseline ($24.27M Net Profit). มี deterministic ground-truth (legacy `.mq5` source + ReportTester HTML) ให้เทียบ — แตกต่างจากโปรเจค SaaS ทั่วไป.

**Methodology fit:** ANDM ออกแบบมาให้ครอบคลุม web SaaS แต่ทีมตั้งใจใช้บน EA single-binary เพื่อทดสอบว่าวินัย Phase Gate + Three-Tier Closure + Empirical Closure Discipline จะ generalize ลง stack ที่ไม่มี HTTP/DB/queue ได้แค่ไหน. คำตอบสั้นๆ = ส่วนใหญ่ generalize ได้ดี แต่มี edge case เฉพาะ (ดู §4.7).

---

## 2. Methodology Footprint (raw numbers)

| Metric | Count | Note |
|---|---|---|
| Calendar days | 17 | 2026-05-02 → 2026-05-17 |
| Active working days | 11 | 6-day gap 2026-05-05 → 2026-05-09 (methodology meta-work elsewhere) |
| Total commits | 240+ | peak 74 commits on 2026-05-03 (P3 parallel slot batches) |
| `[feat:ea]` commits | 64 | actual production code |
| `[fix:ea]` commits | 76 | code-review + IMPL-FIX-NNN remediations |
| `[docs/chore/state]` commits | 83 | state reconciliation + audit trail |
| ADRs locked | 13 | started at 12 (Design QA cert 2026-05-02); ADR-013 added 2026-05-14 (CircuitBreaker DEAL_REASON filter) |
| Main IMPL-NNN tasks | ~68 | spanning P1-P4 |
| IMPL-FIX-NNN remediation tickets | 12 | 001-012 + 5-variant chain IMPL-FIX-011{a,b,c,d,FORCE-PERIOD} |
| Code review-rounds | 26 | `docs/code-review/review-round-{01..26}.md` |
| Code fix-rounds | 25 | `fix-round-{01..24,26}.md` (no fix-round-25 — R25 verify-only) |
| Plan claim-reviews | 14 | `docs/state/impl-plan-claim-review-and-rebuttal/claim-review-{01..14}.md` |
| Plan rebuttal-rounds | 13 | 01-03 + 06-14 (04/05 numbers skipped per BA cascade) |
| BACKTRACK events | 1 | BT-001 (NFR-1.1 Bucket A re-baseline) — full BA→SD→Impl-Plan cascade closed in 5 days |
| Session-handoff artifacts | 128 | concentrated in IMPL-FIX-011 chain (~80) + IMPL-FIX-012 chain (~6) |
| Phase Gate status (today) | P1 ✅ · P2 ✅ · P3 ✅ · P4 ⚠️ open | P4 blocker = IMPL-FIX-012 iter-2 ping_pong false-positive class #2 |

**Commit cadence shape:** burst-then-rest. 33+74+32+20 commits across 2026-05-02..05 (foundation + P3 slot fan-out), then 6-day gap, then 5+31+30+10+3+1+3 commits across 2026-05-09..17 (long-tail debugging of behavioral parity). The 6-day gap is methodology meta-work ( workflow.md Gate #9 clauses (c) through (i) authored).

---

## 3. What Worked — Keep These

### 3.1 The 4-Gate Definition of Done (G1/G2/G3/G4)

ทุก task ที่แตะ `.mq5`/`.mqh` ผ่าน Compile → Smoke → Headless backtest → Log/journal review. คาตช์ defect ที่ unit-test คาดไม่ถึง — เช่น IMPL-FIX-006 (RiskManager dimensional formula day-1 stop-out), IMPL-FIX-008 (CircuitBreaker storm), IMPL-FIX-009 (state.json bar-throttle gap in HALTED). ในโปรเจคที่ไม่มี xUnit framework, นี่คือ load-bearing discipline ที่สุด.

### 3.2 Three-Tier Closure (Task / Walk / Phase Gate)

ตั้งใจไม่ให้ Phase complete ปลอม. ตัวอย่างจริง: 2026-05-04 Tier 1.5 walk batch-1 ก่อน P2 Phase Gate caught **2 defects** ที่ทุก G1-G4 scripted gate ผ่านหมด → spawn IMPL-FIX-001 (HIGH) + IMPL-FIX-002 (MEDIUM). ถ้าไม่มี Tier 1.5 ทั้งคู่หลุดเข้า P3.

### 3.3 BACKTRACK protocol (BT-001 cascade)

2026-05-12 IMPL-062 Bucket A 5-yr Run #2 พบว่า NFR-1.1 measurement contract **structurally unmeetable** (DISABLE_G4_FIXES build รวมกับ 16-slot concurrency → CircuitBreaker halt at sim 2021-01-14). BACKTRACK ไป BA Phase 1A → ratified ใหม่ผ่าน BA Rebuttal Round 04 + SD Rebuttal Round 04 + Impl-Plan Review Round 11/12 → ปิด 5 ขั้นใน 1 day. ไม่มี code rollback ใหญ่; เปลี่ยน measurement contract แทน ซึ่งเป็น scope ที่ถูกต้องที่สุด. backtrack-log.md format อ่านง่าย, audit traceable.

### 3.4 State Reconciliation 3-file rule

`impl-plan.md` (primary SoT) → `overview.md` (derived) → `current_handoff.md` (transient). 240+ commits ที่ไม่มี state drift ที่ surface ออกมา. `/next` ทำงานถูกในทุก session reentry.

### 3.5 Deferred-AC Registry + Operator-Action Registry

แยก concern ชัดเจน: Deferred-AC = "wait for external dependency ≤14d" (ทั้งโปรเจค Phase 1 ไม่มีเลย ตามคาด); Operator-Action = "operator do session-scoped thing now". ตัวอย่าง OPS-002 (2026-05-17): operator ต้องเปิด 5ph GUI MT5 + run Strategy Tester เพื่อ refresh `.tkc` tick cache ก่อน headless backtest จะรันได้. Engineer-side ไม่มีทาง detect/perform — registry pattern จับได้แม่นยำ.

### 3.6 Cap-3 iteration budget (introduced via IMPL-FIX-011 chain)

ที่ออกแบบมาเพื่อกัน "fix sprawl" — ทำงาน. IMPL-FIX-012 iter-1 ปิดด้วย empirical falsification ของ original hypothesis (Slot_H ManageExits cooldown) + pivot ไป ADR-013 (DEAL_REASON_EXPERT filter). ถ้าไม่มี cap จะกระจายต่อ.

### 3.7 Phase 5 Mechanical Gates (1-11)

`workflow.md` 11 gates เป็น automation-friendly checklist (grep + wc + git status). Gates 1+6+11 เห็นชัดในทุก closure note. Gate #11 (working-tree clean post-closure) caught fix-round narratives ที่ advertise "applied + verified" แต่มี untracked review docs ที่ R16 §16.2 จับ.

---

## 4. Pain Points & Surprising Friction

### 4.1 The Gate #9 clause-explosion (**LARGEST methodology defect class**)

`workflow.md` Phase 5 Gate #9 ("Post-fix grep verification") เริ่มต้นมีแค่ 1 ประโยค. ภายใน 7 review-rounds (R20→R26) มันงอกเป็น **9 clauses (a)→(i)** ครอบคลุม **5 axes**:

| Axis | Introduced | Surfaced because |
|---|---|---|
| (a/b/c) catalog regex | R14, R16 | originating grep was scope-narrower than defect class (`IMPL-053+` literal vs `IMPL-053` class) |
| (d/e) dynamic catalog | R20 | hand-enumerated `IMPL-(006\|007\|...)` missed newer closures |
| (f/g) destination + token-collision | R21 | bulk-substitution introduced grammatical doubling (`wires at wiring path`) + cited non-existent `WireSlots` method |
| (h) line-anchor brittleness | R22-R23 | physical line numbers as load-bearing pointers silently desync |
| (i) exemption-regex tree-wide verifiability | R24 | hand-classified exemptions that the documented regex didn't reproduce |
| 5th meta-axis "reviewer-authoring contract" | R26 | verify-only review-round (R25) claimed 1 hit when documented mechanism returned 22 |

**Per-clause body length is now ~3,000 words.** อ่านไม่ทันจริง. การ "fix the rule to fix the fix that fixed the rule" loop เป็น recursive — แต่ละ axis ที่ surface ใหม่ก็คือ "the documented mechanism didn't catch its own intent at the next meta-level above". R26 ระบุชัดว่า 5th axis เปิดอยู่ → คาดได้ว่ามี clause (j) มาในอนาคต.

**ต้นทุนจริง:** 14 review-rounds (R12→R26) ส่วนใหญ่ใช้กับ defect class เดียว. ~10-15 hours engineer time/round (estimate). พวกนี้ไม่ได้ flip [ ] → [x] บน production tasks เลย — เป็น methodology overhead 100%.

### 4.2 Review-round vs feature-commit ratio

| Bucket | Count |
|---|---|
| `[feat:ea]` (new production code) | 64 |
| `[fix:ea]` (remediation + review fixes) | 76 |
| Review+fix-round commits | ~51 |

Roughly 1:1 review-vs-feature ratio. สำหรับ greenfield project นี่สูง. เปรียบเทียบ: ใน mature codebase review/feat ~0.3:1 ถือว่าหนัก. คำถามที่ควรตอบ: **methodology over-indexes on textual audit-trail vs functional code?**

### 4.3 IMPL-FIX-011 sprawl (the biggest single ticket)

หนึ่ง remediation ticket → **5 sibling tickets** (`011`, `011a`, `011b`, `011c`, `011d`, `011-FORCE-PERIOD`) → **19 iterations** → **~80 session-handoff artifacts** → **46 commits across 3 days**. แต่ละ sibling ใช้ cap-3 ของตัวเอง = effectively cap-15 รวม. Methodology อนุญาตให้ "scope-pivot post-NNNb closure" → next sibling ticket = bypass cap. ผลลัพธ์: empirical falsifications ซ้ำซ้อน (`d5b8608` Step 4 iter-2 falsifies Session B; `6822c4e` Step 4 iter-3 falsifies Session C; `287db57` Step 4 iter-5 EMPIRICALLY FALSIFIED). Eventually closed `[x]` ภายใต้ "operator option c — entry-parity-complete, exit-deferred" — i.e., scope-narrowed at exit ไม่ใช่ root-cause.

**Root cause analysis ที่ขาด:** 1 ticket → 5 siblings = ticket decomposition ไม่ถูกตั้งแต่แรก. Methodology ไม่บังคับ "stop + re-decompose" หลัง iter-3 fail.

### 4.4 `impl-plan.md` ขนาดเกิน Read-tool single call

ไฟล์โต **106,067 tokens** (Read max 25,000). ทุก agent ที่อ่าน plan ต้อง offset/limit หรือใช้ grep. TL;DR section เองหลายหมื่น tokens — มี explicit comment `boilerplate intentionally retained inline for audit traceability per fix-round-10 precedent` ที่บ่งชี้ว่า methodology กำลังต่อสู้กับ audit-trail discipline ของตัวเอง.

**Reader empathy section ที่ R10 §10.6 เพิ่มมา** (`Top 3 most-material entries below = current decision-pending state`) เป็น band-aid ที่ดี แต่ไม่แก้ root cause. Plan Staleness Sentinel มีอยู่แต่เป็น advisory เท่านั้น.

### 4.5 Empirical hypotheses ผิดบ่อยกว่าถูก (good signal, structural cost)

จาก commit log:
- IMPL-FIX-011 Session B → falsified iter-2
- IMPL-FIX-011 Session C → falsified iter-3
- IMPL-FIX-011a Step 4 iter-4 → FALSIFIES S-AC #3
- IMPL-FIX-011a Step 4 iter-5 → EMPIRICALLY FALSIFIED
- IMPL-FIX-012 iter-1 → falsifies original ManageExits cooldown hypothesis
- IMPL-FIX-012 iter-2 → ADR-013 partial fix; **new false-positive class surfaces 13 sim days later**

นี่เป็น **healthy** signal — methodology บังคับให้ falsify ก่อนปิด. แต่ต้นทุนเชิงโครงสร้างหนัก: ทุก iter = full G3 5-yr backtest cycle (~30-60 min wall-clock) + journal/log parsing + state reconciliation 3-file propagation. ใช้เวลา/พลังงาน operator มาก ระหว่างที่ Plan Staleness Sentinel อยู่กับที่ (counter ไม่ขึ้นเพราะ "FIX-ticket sub-iter ไม่ increment").

### 4.6 Operator Action Registry: anticipation vs reality mismatch

Phase 1 baseline note (2026-05-02) ทำนายว่า UIR triggers จะมีแค่ "Strategy Tester data download (first-time)" + "MetaEditor warning suppression" + "MT5 build update". จริงๆ trigger แรกที่เกิด (2026-05-17) คือ **"tick cache freshness — operator must open GUI + run backtest to refresh `.tkc`"** — class ที่ไม่ได้คาด. OPS-001 ถูก register แล้ว revert ภายในชั่วโมง (mis-diagnosis: PID 6916 จาก separate 5ph install). OPS-002 (จริง) resolved by accident — operator รัน GUI backtest แล้ว engineer headless launch สำเร็จในรอบที่ 4.

**Methodology lesson:** UIR trigger catalog เป็น speculative ก่อน operator hit edge case. Registry รองรับ ad-hoc additions ดี แต่ทำนายล่วงหน้าไม่ได้.

### 4.7 The "no native Phase 1.5 walk" reality (stack-specific note)

CLAUDE.md §1 อธิบายชัดว่า "For PhoenicisNex specifically (no GUI): Tier 1.5 walk = headless backtest + log + journal." ทำงานได้ — IMPL-067 walk batch-3 caught 10/10 PASS. แต่ feedback loop ช้ากว่า web UI click-through มาก (30-60 min per G3 run vs seconds for a click). Methodology ไม่มี "fast Tier 1.5" สำหรับ slow-runtime stacks.

### 4.8 Encoding tax (MQL5/MT5 specific แต่อาจ generalize)

ทุก G1+G4 ต้อง `iconv -f UTF-16LE -t UTF-8` บน Tester/compile log. `mt5-log-reader` SKILL อธิบายไว้ดี แต่ไม่มี wrapper script ใน `.agents/skills/.../scripts/` — ทุก agent re-implement command. Minor friction แต่ผูกกับทุก G1/G4 invocation = ความถี่สูง.

---

## 5. Concrete Improvement Suggestions

### Priority 1: Cap meta-loop depth on rule mutations

หลัง gate clause ที่ N+1 ถูกเพิ่มเพราะ clause N's intent กว้างกว่าที่ execute, methodology ควร**บังคับ stop + re-design** แทนการเพิ่ม clause N+2. ตัวอย่าง trigger: "ถ้า review-round N+2 surface defect class เดียวกับ N → halt + spawn new METHODOLOGY-REDESIGN-NNN ticket; ห้าม add clause."

R26 §5th-axis เห็นปัญหาแล้วแต่ไม่บังคับ stop. ปัจจุบัน trigger = engineer judgment; ควรเป็น mechanical.

### Priority 2: Mandatory `impl-plan` compaction

เมื่อ `impl-plan.md` ทะลุ token threshold (e.g., 50k) — บังคับ `/impl-plan-amend compact`:
- เก็บ TL;DR top-3 (R10 §10.6 pattern แล้ว)
- ย้าย closure history > 7 days → `impl-plan-archive-YYYY-MM.md`
- เก็บ Phase Gate + Sentinel + Open Risks ไว้ใน primary

ปัจจุบัน plan boilerplate (Plan Staleness Sentinel per-entry) ถูก "intentionally retained inline" — discipline ดี แต่ทำให้ไฟล์ unreadable.

### Priority 3: Hard cap on IMPL-FIX sibling spawning

Methodology อนุญาตให้ "scope-pivot post-NNNa closure → NNNb" — โดย design ไม่จำกัด. ควรกำหนด: **"no more than 2 sibling fixes (a, b) per parent ticket"**. ถ้าต้องการ NNNc → บังคับ pause + spawn fresh IMPL-FIX-MMM พร้อม re-decomposition รวม root-cause analysis. IMPL-FIX-011{a,b,c,d,FORCE-PERIOD} = ตัวอย่างที่ไม่ควรเกิด.

### Priority 4: "Class root-cause" gate before bulk-substitution

R20-R23 ทั้งหมดเกิดจาก bulk-substitute pattern ที่ engineer ไม่ได้ verify ว่า substitute string ไม่ collide กับ surrounding prose / ว่า destination มีอยู่จริง. เพิ่ม Gate #N: **"Bulk-substitution requires N ≥ 5 representative call-sites manually inspected + grep-verify token doesn't collide + grep-verify destination exists, before any sed/replace runs."** ป้องกัน Gate #9 (f)+(g) recurrence.

### Priority 5: Differentiate "FIX-iter counter" vs "main-task counter" semantics

ปัจจุบัน Plan Staleness Sentinel ไม่ tick เมื่อ IMPL-FIX-NNN sub-iter ปิด (per `workflow.md` Gate #4 + fix-round-10 precedent). ผลคือ Sentinel = 0 closures since R09 ทั้งที่มี 19 iterations จริงๆ. ควรมี **two counters**:
- `main_task_closures_since_review` (current)
- `fix_iter_closures_since_review` (new) — ทริก review-round ที่ threshold สูงกว่า (e.g., 20)

ป้องกัน situation ที่ผ่าน 19 iter ไม่มี plan review.

### Priority 6: Headless walk batch automation

PhoenicisNex Tier 1.5 = headless backtest + log review. Repeatable workflow — ควรมี SKILL `walk-batch` (`/walk-batch P3 IMPL-067` style) ที่ launch N ini files + parse logs + auto-generate walk artifact. ปัจจุบัน manual setup ทุกครั้ง.

### Priority 7: `mt5-headless-backtest` wrapper for tick-cache freshness check

OPS-002 (tick cache freshness) จับยาก — engineer launch สำเร็จเฉพาะหลัง operator GUI backtest. เพิ่ม pre-flight check ใน `run_headless_backtest.sh`: ถ้า `.tkc` mtime > 30 day → emit warning + suggest OPS row. ป้องกัน 3-attempt-fail-then-register cycle.

### Priority 8: Session-handoff retention policy

128 files ใน `_session-handoff/` — ส่วนใหญ่จาก IMPL-FIX-011 iterations. Methodology ควร formalize: **เมื่อ parent ticket ปิด `[x]` → archive sibling iter artifacts ลง `_session-handoff/archive/<ticket>.tar.gz`**. ปัจจุบันไม่มี policy → grep cost โต linearly.

---

## 6. Open Questions for the Methodology Owner

1. **Is the 1:1 review-vs-feature commit ratio acceptable for greenfield?** ถ้า "yes for safety-critical financial code" → ยอมรับ. ถ้า "expected to drop in mature phase" → trigger จะลด overhead ตอนไหน?

2. **5th-axis "reviewer-authoring contract" (R26):** ปล่อยเปิดไว้ หรือ spawn `/update-config` ticket แก้ก่อน review-round 27? เจอ R14 §14.4 precedent ที่ปฏิเสธ methodology-evolution ใน fix-round → controlled silo discipline. แต่ R26 surface ว่า discipline นี้กำลังกลายเป็น "punt forever".

3. **IMPL-FIX sibling spawning:** มีกรณี legitimately ต้องแยกหรือไม่ (e.g., independent root causes)? ถ้ามี → criteria แยก legitimate-split vs sprawl คืออะไร?

4. **Plan staleness threshold:** ปัจจุบัน `/next` Check 5.8 ใช้ "30 day OR 10 closures". ในโปรเจคที่ closure rate สูง (33 commits 2026-05-02 + 74 2026-05-03) → threshold ถึงเร็วเกิน. ในโปรเจค slow-iter (วันละ 1-3 commit ช่วง 2026-05-12..17) → threshold ไม่เคยถึง. ควร dynamic per project velocity?

5. **Empirical falsification budget:** cap-3 iter budget มี implicit assumption ว่า 3 iters น่าจะเพียงพอ. PhoenicisNex data: IMPL-FIX-011 chain ใช้ 19 iter; IMPL-FIX-012 อยู่ที่ iter-2 และยังไม่จบ. ถ้า real falsification rate > 3 → cap-3 บังคับให้ "scope-narrow แล้วปิด" แทน "root-cause ถูก". เห็นใน IMPL-FIX-011a ที่ปิด "entry-parity-complete, exit-deferred".

6. **Three-Tier Closure ใน slow-runtime stack:** Tier 1.5 walk บน UI = 30 min; บน 5-yr Tester run = 30-60 min wall-clock + ต้องการ operator session (data-dir lock). ค่าใช้จ่ายต่อ walk สูง → ทีมหลีกเลี่ยง walk batch บ่อยกว่าที่ควร. Methodology ควรมี "fast-walk" variant สำหรับ slow stack หรือไม่?

---

## 7. Bottom Line

**Methodology works.** ใน 17 วัน, project:
- ปิด P1+P2+P3 phase gates สะอาด
- จับ 1 measurement-contract structural flaw (BT-001) + ย้อนแก้สำเร็จ
- จับ 2 functional defects ที่ scripted gates หลุด (Tier 1.5 walk batch-1)
- รักษา zero state-drift ข้าม 240+ commits
- บังคับ falsify-before-close → empirically corrected 5+ wrong hypotheses

**ต้นทุนหลัก:** methodology meta-loop (Gate #9 explosion) ใช้ engineer time ~10-15% ในช่วง 2026-05-05 → 2026-05-09 ไปกับ rule-mutation แทน production code. รวมกับ IMPL-FIX-011 sprawl (3 days, ~80 artifacts) = ~30% ของ 17-day budget ไปกับ "fixing the fix" หรือ "tightening the rule that caught the fix". มีของจริงที่ปิดบน 11 working days แต่ overhead ratio สูง.

**Top 3 ที่ควรแก้ก่อนใช้ next project:**
1. Mandatory stop-and-redesign trigger บน gate clause-explosion (จะตัด R20-R26 effort 80%)
2. Hard cap บน IMPL-FIX sibling spawning (จะป้องกัน IMPL-FIX-011-style sprawl)
3. `impl-plan.md` mandatory compaction at token threshold (จะกู้ readability + reduce per-session context cost)

ส่วนที่ดี (Three-Tier Closure, 4-Gate G1-G4, BACKTRACK protocol, State Reconciliation, Deferred-AC + Operator Action Registry) — keep all. นั่นคือ load-bearing structure ของ project นี้.

---

**File location:** `docs/state/methodology-retrospective-day17.md`
**Suggested next actions for methodology owner:**
- Read §4 (pain points) for failure modes
- Read §5 (priorities 1-3 are highest-leverage)
- Answer §6 questions to inform v-next methodology spec
- Optional: spot-check `docs/code-review/review-round-{20..26}.md` to see Gate #9 clause-explosion in raw form
