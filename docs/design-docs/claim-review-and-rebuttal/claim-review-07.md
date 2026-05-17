# System Design Claim Review Round 07

| Field | Value |
|-------|-------|
| **Round** | 07 |
| **Target** | `all` (6 SD docs 02-08, gaps 01/06 + 14 ADRs incl. ADR-013/014 superseded + 4 API specs) |
| **Date** | 2026-05-17 |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |
| **Predecessor** | `claim-review-06.md` (2026-05-13; 0 findings — BT-001 cascade clean closure) → no rebuttal needed |
| **Trigger** | BT-002 (2026-05-17) — operator Option 1 selected (remove BR-3.6 CircuitBreaker ping-pong detector, legacy-parity). Cap-3 iter chain ADR-013 → ADR-014 falsified by IMPL-FIX-012 Run #5 (sim 2021-01-06 Slot_BI pyramiding false-positive). SD edits applied unilaterally ahead of chained `/backtrack ba` per engineer recommendation in `backtrack-log.md § BT-002`. First adversarial sweep ของ post-BT-002 SD package. |

---

## 📊 At-a-Glance

**Total findings:** 7 (🔴 CRITICAL **0** / 🟠 HIGH **2** / 🟡 MEDIUM **3** / 🔵 LOW **2**)
**Schedule-leakage check:** ✅ Clean — grep `Sprint [0-9]+|Week [0-9]+|Q[1-4] 202[0-9]|[0-9]+ weeks?|team of [0-9]+|## Phase (Plan|Assignment|Schedule|Roadmap)|Sprint Plan|Release Timeline|Rollout Wave` = **0 hits** in `docs/design-docs/0*.md`
**Invalid label check:** ✅ Clean — grep `^## (Phase (Plan|Assignment|Assignments|Schedule)|Delivery Schedule|Implementation Roadmap|Sprint Plan|Release Timeline|Rollout Wave|Milestone M[0-9]+)` = **0 hits**
**Language check:** ✅ Pass (qualitative) — bilingual code-switched style preserved; Thai narrative in TL;DR + Pillars + Glossary + Phase Hints rationale + BT-002 commentary blocks; English tech terms (STRIDE/CircuitBreaker/Mermaid/halt_reason/CHashMap) untranslated per LANGUAGE RULE
**BT-002 propagation surface coverage** (cross-check vs `backtrack-log.md § BT-002 Proposed change`):
- ✅ `02-high-level-architecture.md` — FR-6.6 strikethrough L54, FR-7.7 rewrite L62, Component Catalog row #14 removal note L302, Communication Matrix § 5.1 L325 updated, Glossary § 8 Bucket B re-author L442
- ✅ `03-deep-dive.md` — Bucket A/B § 1.3 outline + § 1.5 Validation updated; Table A/B perf-budget −5 µs annotation
- ✅ `04-data-flow.md` — § 1.1 mermaid CB participant + ping-pong alt-branch removed; § 9.1 cross-slot enable matrix row removed
- ✅ `05-security.md` — TL;DR rewrite, § 2.5 DoS row "Infinite re-entry loop" re-authored as accepted residual risk, § 3.2 runtime defenses row strikethrough, § 7.2 halt observability row updated
- ✅ `08-product-breakdown.md` — IMPL-051 CANCELLED in § 1.7 + § 4 metadata + § 3 P2 hint
- ✅ `ADR-010` — Status amended + Trigger sources + OnTick guard + Revision history
- ✅ `ADR-013 + ADR-014` — Status flipped Accepted → Superseded by BT-002 (preserved as audit history)
- ✅ `ADR-001` services list, `ADR-009` Validation/Consequences prose, `ADR-011` halt-trigger bypass, `ADR-012` file layout tree — all cite BT-002
- ✅ `trade-journal-schema.yaml` — `circuit_breaker_pingpong` removed from `halt_reason` enum + `CircuitBreakerOrder` removed from `triggering_function` enum

**Anti-Duplication sweep:** Round 06 cumulative-counter cascade + Round 05 Bucket A/B BT-001 framing — both verified untouched + still semantically valid post-BT-002. Round 06's "Reliability ✅ Pass — CircuitBreaker BR-3.6 + ADR-010 HALTED state machine ✅" is now superseded by BT-002 — but that was the verdict of the prior decision regime, not a contradicted finding.

**Net assessment:** BT-002 cascade landed across the documented surface with high fidelity. Internal mechanical integrity solid — strikethroughs preserve audit history, ADR amendments cite operator + date + iter chain. Remaining findings cluster on **(a)** Phase Hint Summary table § 5 not propagated alongside § 1.7/§ 3/§ 4 cancellation; **(b)** Last-updated header staleness ใน 5/6 SD docs (header still cites BT-001 2026-05-12 despite massive BT-002 edits); **(c)** ADR Digest § 9 in `02` still narrates "12 ADRs" but 14 .md files exist in `docs/adr/` post BT-002 (013/014 superseded but file-present). No CRITICAL — the surfaces BT-002 was designed to touch are mostly aligned; gaps are residual cascade-completion + audit-trail freshness.

### Top 3 to Fix First

1. **Claim 07.1** 🟠 HIGH — `08 § 5 Phase Hint Summary` table P2 row + Total task count not propagated post IMPL-051 cancellation — `08-product-breakdown.md` lines 308, 312
2. **Claim 07.2** 🟠 HIGH — Last-updated header stale in 5 of 6 SD docs (02/03/04/05/08 cite BT-001 2026-05-12 despite BT-002 edits applied 2026-05-17) — multi-file
3. **Claim 07.3** 🟡 MEDIUM — ADR Digest § 9 narrates "12 ADRs" but 14 .md files exist; ADR-013/014 superseded-but-present require explicit acknowledgment row — `02-high-level-architecture.md` § 9 + L474 footer

### Verdict

- [ ] ✅ **Ready for Implementation Handoff**
- [x] ⚠️ **Needs Rebuttal Round** — 2 HIGH + 3 MEDIUM = downstream `/impl-plan-review` + chained `/backtrack ba` jobs จะ ingest stale Phase-Hint-Summary + stale Last-updated headers + ADR count mismatch; run `/sd-rebuttal claim-review-07.md`
- [ ] ⛔ **Immediate Attention**

> **Recommendation:** Architect run `/sd-rebuttal claim-review-07.md` → apply Claims 07.1-07.7 (all Low effort, ≤ 45 min total — 2 files primary, 4 minor). Re-run `/sd-review all` Round 08 → expect 0 finding (mirror Round 03→04 + BA Round 04→05 clean-closure pattern). หลังจาก SD-side clean closure → operator authorize chained `/backtrack ba` (BR-3.6 + FR-6.6 demotion at BA layer per `backtrack-log.md § BT-002 Proposed change`).

---

## System Design Attack Vector Checklist (22 Categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass | ADR-001 + `02 § 3.2` modular-monolith trade-off ไม่กระทบ BT-002 (architecture style ไม่เปลี่ยน); CircuitBreaker เคยเป็น service ภายใน monolith — ลบออก ≠ style change |
| 2 | Service Boundaries | ✅ Pass | 5-layer split (`02 § 4`, ADR-012) unchanged; ADR-012 file layout tree L81 ระบุ CircuitBreaker.mqh REMOVED ผ่าน comment ✅ |
| 3 | Communication Patterns | ✅ Pass | `02 § 5.1` Caller→Callee table แก้ row "Orchestrator → EAState.Halt" — direct `AnyHandleInvalid()` path now sole automated trigger; sync intra-process invariant preserved |
| 4 | Data Consistency | ✅ Pass | Atomic temp+rename (ADR-007) + JSON-Lines (ADR-006) consistency unchanged; halt path mutation invariant ลดลง 1 source (CB) |
| 5 | Database Design | ✅ Pass | File-based persistence unchanged; `state-persistence-schema.yaml § ea_halt_reason` mirrors trade journal enum (no longer references ping-pong) |
| 6 | Caching Strategy | ✅ Pass | unchanged |
| 7 | Security Design | ⚠️ Finding 07.5 | STRIDE 6 categories scanned; `05 § 2.5` DoS row "Infinite re-entry loop" re-authored ✅ as accepted residual risk; verbose multi-paragraph mitigation language could be tightened |
| 8 | Scalability | ✅ Pass | unchanged |
| 9 | Reliability & Fault Tolerance | ✅ Pass | HALTED state machine (ADR-010 amended BT-002) retained สำหรับ `IndicatorService::AnyHandleInvalid()` + Phase 2 trigger candidates; CB ping-pong removed reduces automated halt sources from 2 → 1 — design accepts trade-off explicitly via `05 § 2.5` BT-002 row |
| 10 | Performance Budgets | ✅ Pass | NFR-2.1/2.2 budgets unchanged; `03 § 2.3` Tables A + B post-BT-002 −5 µs annotation accurate (1,685 → 1,680 µs steady; sum-of-added 1,007 → 1,002 µs) |
| 11 | Concrete Numbers | ✅ Pass | ทุก threshold (25% Bucket A, $24.27M baseline, 150/80/100 H4 force-clear) ยังมี formula/derivation |
| 12 | API Contract Quality | ✅ Pass | `trade-journal-schema.yaml` halt_reason enum + triggering_function enum updated ✅; breaking change ตรง Phase 1 (no external consumers per ADR-006) |
| 13 | Data Flow Completeness | ⚠️ Finding 07.6 | `04 § 1.1` mermaid sequence diagram บรรยายลำดับ OnTick post-BT-002 ครบ; stranded "Note over Orc: CircuitBreaker.CheckPingPong removed per BT-002" L46 = transient audit annotation inside current-state diagram |
| 14 | Observability | ✅ Pass | `05 § 7.2` halt event row updated; cumulative-counter cascade (Round 03 fix) ไม่กระทบ BT-002 |
| 15 | ADR Quality | ⚠️ Finding 07.3 | ADR-010 amendment well-formed (Revision history line 109 + Trigger sources line 18-21 + OnTick guard line 64-95 + Revisit-when line 130-134) ✅; ADR-013/014 Status `Superseded by BT-002` ✅ ; **but** `02 § 9 ADR Digest` table only enumerates 12 active ADRs without acknowledging 013/014 are intentionally preserved-as-superseded |
| 16 | Cross-Doc Consistency | ⚠️ Findings 07.1, 07.2, 07.3, 07.4 | 4 cascade-completion gaps surfaced: Phase Hint Summary (08 § 5), Last-updated headers (5/6 SD docs), ADR Digest count, line-anchor brittleness (`Slot_J.mqh:180` cite) |
| 17 | Requirements Traceability | ✅ Pass | `02 § 1.1` FR-6.6 strikethrough ✅; FR-7.7 row "(handle-invalid runtime; CB ping-pong removed per BT-002 2026-05-17)" ✅; BA FR-6.6 + BR-3.6 still active ณ BA layer per pending chained `/backtrack ba` — but `backtrack-log.md § BT-002` explicitly documents this sequencing (SD ก่อน BA) เพื่อ feed BA rebuttal cycle a concrete SD proposal |
| 18 | Failure Modes | ✅ Pass | `03 § 1.4` Challenge 1 failure mode table unchanged; `05 § 6` Operational Risks row "Bug-fix changes" unchanged from BT-001 baseline (no BT-002 amendment needed) |
| 19 | Future Evolution + Evolution Sequence | ✅ Pass | `07 § 6` E1+E2 Evolution Sequence unchanged; BT-002 ไม่กระทบ; `07 § 4` Tech Debt list ไม่เพิ่ม BT-002 row (เพราะ CB removal ≠ tech debt, intentional design simplification) |
| 20 | Work Inventory + Phase Hints | ⚠️ Finding 07.1 | `08 § 1.7` IMPL-051 cancellation ✅; `08 § 3` Suggested P2 strikethrough ✅; `08 § 4` per-task metadata IMPL-051 row cancellation ✅; **but** `08 § 5 Phase Hint Summary` P2 row task list **still contains IMPL-051 without strikethrough** + "~11 tasks" count + "Total task count: ~68" not propagated |
| 21 | Readability / Reader-Empathy | ⚠️ Finding 07.7 | TL;DR + Why-lines + Glossary scaffolding preserved ทั้ง 6 docs; `02 § 8` Glossary มี duplicate semantic entry "Halted state semantic" + "HALT vs HALT_STABLE" (pre-existing — not BT-002 introduced) |
| 22 | Language Rule Compliance | ✅ Pass | bilingual code-switched style unchanged; BT-002 edit prose เป็น Thai-led narrative + English tech terms (BT-002/legacy-parity/ping-pong/CircuitBreaker/halt_reason) untranslated correctly; ทุก ADR amendment Thai prose สอดคล้องเดิม |

---

## Findings (ordered: 🔴 CRITICAL → 🟠 HIGH → 🟡 MEDIUM → 🔵 LOW)

### 🔴 CRITICAL

*N/A — BT-002 cascade fundamentals (semantic invariants, halt trigger reduction, ADR amendments) landed coherently. ไม่มี architecture-level defect.*

---

### 🟠 HIGH

---

### Claim 07.1: 🟠 HIGH — Phase Hint Summary table § 5 ใน `08` not propagated alongside IMPL-051 cancellation in § 1.7 / § 3 / § 4

**Location:** `docs/design-docs/08-product-breakdown.md` § 5 lines 305-312

**Problem:**

§ 5 Phase Hint Summary table contains P2 row:

> *"| **P2 — Core Services + EAState + Pending** | IMPL-040, 041, 043, 044, 045, 047, 048, 049, 050, **051**, 052 | XS-XL, **~11 tasks** | medium overall, IMPL-049 XL |"*

และ footer:

> *"**Total task count: ~68 implementation tasks**"*

BT-002 cancelled IMPL-051 ที่ § 1.7 line 103 (CANCELLED-BT-002 strikethrough), § 3 Suggested P2 line 226 (strikethrough mention), § 4 Per-Task Metadata line 286 (cancelled row). แต่ § 5 Phase Hint Summary table (= Impl Planner's primary lookup for phase breakdown) ยังคงระบุ IMPL-051 ใน task list **โดยไม่มี strikethrough** + task count "~11 tasks" + total "~68" stale.

**Why this matters:**

§ 5 Phase Hint Summary คือ table ที่ Impl Planner หยิบไปสร้าง `docs/state/impl-plan.md` Phase status snapshot + Phase × Size matrix. Phase × Size denominator (gate #3 ของ Phase 5 mechanical gates ใน `.claude/rules/workflow.md`) ผูกกับ task count ใน § 5. ถ้า impl plan readers ใช้ § 5 ตามตัวอักษร:

1. Impl Planner จะ register IMPL-051 ใน P2 Phase Status Snapshot → `/impl-task` จะ HALT เพราะ IMPL-051 ไม่อยู่ใน work tree (no spec ใน 08 § 1.7 — cancelled)
2. Phase × Size denominator P2 = "10 of 11" จะตี gate #3 mismatch
3. TL;DR `Phase 2 x/y` denominator ของ impl-plan.md จะ stale ตั้งแต่ปั้น
4. Total task count "~68" จะใช้เป็น baseline ของ deferred-ac-registry / overview phase status — เริ่มต้นจาก wrong baseline

Same root cause class เป็น "rebuttal-output verification gap" ที่ Round 03→04 cascade (cumulative counter) เคยเผชิญ — single sweep + multiple parallel-narrative sections; if one section misses, impl downstream consumes stale count.

**Minimum acceptable fix:**

Edit `08-product-breakdown.md` § 5:

Line 308:
```
| **P2 — Core Services + EAState + Pending** | IMPL-040, 041, 043, 044, 045, 047, 048, 049, 050, ~~051~~, 052 | XS-XL, ~10 tasks (post-BT-002 IMPL-051 cancellation) | medium overall, IMPL-049 XL |
```

Line 312:
```
**Total task count: ~67 implementation tasks** (post-BT-002 — was ~68; IMPL-051 CircuitBreaker::CheckPingPong cancelled per BT-002 2026-05-17)
```

**Level of Effort:** Low (2-line edit, single file)

---

### Claim 07.2: 🟠 HIGH — Last-updated header stale ใน 5/6 SD docs — header cites BT-001 (2026-05-12) แต่ BT-002 edits applied 2026-05-17

**Location:** Multi-file —
- `02-high-level-architecture.md` line 5
- `03-deep-dive.md` line 5
- `04-data-flow.md` line 5
- `05-security.md` line 5
- `08-product-breakdown.md` line 5
- (`07-future-evolution.md` line 5 untouched by BT-002 = correct → cite 2026-05-02)

**Problem:**

ทั้ง 5 SD docs ที่ BT-002 แก้ไข (per `backtrack-log.md § BT-002 Proposed change` enumeration ตรงกับ grep evidence) ยังคงระบุ Last updated เป็นวันที่ของ BT-001 cascade:

| Doc | Header L5 (current) | BT-002 edits applied? |
|-----|----------------------|------------------------|
| `02-high-level-architecture.md` | `2026-05-12 (BT-001 cascade — Bucket A/B propagation...)` | ✅ ใช่ — FR-6.6 strike L54, FR-7.7 rewrite L62, § 4.2 footer note L302, § 5.1 row L325, § 8 Bucket B re-author L442 |
| `03-deep-dive.md` | `2026-05-12 (BT-001 cascade — Challenge 1 § 1.3 outline...)` | ✅ ใช่ — § 1.3 + § 1.5 post-BT-002 prose, § 2.3 Tables A/B −5 µs annotation L101/L115 |
| `04-data-flow.md` | `2026-05-02` | ✅ ใช่ — § 1.1 mermaid L46 + § 9.1 row L545 |
| `05-security.md` | `2026-05-12 (BT-001 cascade — § 6 Operational Risks bug-fix row...)` | ✅ ใช่ — TL;DR L11, § 2.5 DoS row L120, § 3.2 row L151, § 3.3 row L159, § 7.2 halt row L233 |
| `08-product-breakdown.md` | `2026-05-12 (BT-001 cascade — IMPL-062/063 task description...)` | ✅ ใช่ — § 1.7 IMPL-051 cancellation L103, § 1.7 IMPL-052 amend L104, § 1.10 IMPL-062 post-BT-002 prose L129, § 3 P2 strikethrough L226, § 4 metadata L286, § 3 P4 final paragraph L245 |

**Why this matters:**

Last-updated header is **the only structured freshness signal** สำหรับ downstream readers (TD agent, QA agent, Impl Planner) ที่ scan SD docs without diffing commit log. Per `workflow.md § Handoff Discipline`:

> *"Update handoff: end of feature / session change / cross-day boundary"*

แม้ rule นั้นเป็น handoff scope แต่หลักการเหมือนกัน — agent reading the doc must trust the header. Round 06 closure recommendation step 2 ระบุชัด:

> *"Operator update `docs/state/overview.md` Design (SD) row → append `+ Round 06 (post-BT-001 cascade clean — 0 findings 2026-05-13)`; Last Updated bump to 2026-05-13"*

แต่ BT-002 edits applied 2026-05-17 (commit `0be2a51`) ไม่ได้ propagate Last-updated header field ใน SD docs เอง. Result: TD reviewer ใน Phase 1D อ่าน `02 § 1.1` FR-6.6 strikethrough + Last-updated `2026-05-12 (BT-001 cascade...)` → mental model conflict (BT-001 doesn't touch FR-6.6 — that's a BT-002 surface).

Same defect class as gate #4 ของ Phase 5 mechanical gates (`Sentinel counter increment`) — atomic update ของ TL;DR rewrite + state-doc surface. SD doc Last-updated headers are SD-layer equivalents.

**Minimum acceptable fix:**

Edit Last-updated header of 5 docs to reflect BT-002 application:

```markdown
> **Last updated:** 2026-05-17 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; cap-3 iter ADR-013 → ADR-014 superseded; <doc-specific surface list>)
```

Per-doc surface list:
- `02`: "FR-6.6 strikethrough § 1.1, FR-7.7 rewrite § 1.1, Component Catalog row #14 removal § 4.2, Communication Matrix § 5.1 update, Glossary § 8 Bucket B re-author"
- `03`: "§ 1.3 outline + § 1.5 Validation re-frame, § 2.3 Table A/B −5 µs annotation"
- `04`: "§ 1.1 mermaid CB participant + ping-pong alt-branch removed, § 9.1 cross-slot enable matrix row removed"
- `05`: "TL;DR + § 2.5 DoS row + § 3.2 + § 3.3 + § 7.2 halt event row re-author (accepted residual risk)"
- `08`: "IMPL-051 CANCELLED § 1.7, IMPL-052 amend § 1.7, P2/P4 Phase Hint § 3, per-task metadata § 4, IMPL-062/063 narrative § 1.10"

**Level of Effort:** Low (5 single-line edits)

---

### 🟡 MEDIUM

---

### Claim 07.3: 🟡 MEDIUM — `02 § 9 ADR Digest` narrates "12 ADRs" but 14 .md files exist in `docs/adr/` post-BT-002

**Location:** `docs/design-docs/02-high-level-architecture.md` § 9 (table lines 460-472, footer line 474)

**Problem:**

`02 § 9` ADR Digest table enumerates 12 active ADRs (ADR-001 ถึง ADR-012). Footer line 474 ระบุ:

> *"**End of 02 — High-Level Architecture** — Traceability matrix (41 FR + 30 NFR + 9 BR + 8 OQ), 26 components across 5 layers, **12 ADRs** covering all major architectural decisions"*

ปัจจุบัน `docs/adr/` มี **14 .md files** — ADR-013 + ADR-014 ถูก author ระหว่าง IMPL-FIX-012 iter-1/iter-2 (2026-05-14/2026-05-17) แล้วถูก supersede โดย BT-002 in-place same day. Status field ของทั้ง 2 ระบุ "Superseded by BT-002 2026-05-17 (preserved as audit history)".

Reader ของ `02 § 9` (= TD reviewer, QA, Impl Planner) ที่ navigate ไป `docs/adr/` ผ่าน path เห็น 14 files แต่ § 9 table only mentions 12 → confusion: "ADR-013/014 คืออะไร? ทำไม Digest ไม่ mention?"

Same defect class as cross-doc consistency category — ADR file count vs SD doc enumeration mismatch.

**Why this matters:**

1. **ADR discipline expects 1:1 file:row** per `.claude/rules/workflow.md § ADR Discipline`: *"new architectural decision → `docs/adr/NNN-<kebab-title>.md` (NNN = next sequential)"* + *"ADR amendment (e.g., adding 'Revisit-when' trigger) → log in ADR + cite in commit"*
2. **Superseded ADRs are valid historical decisions** ที่ implementers อาจ reference สำหรับ "why was this path tried?" — see BA `01 § 8` Glossary discipline of preserving audit trail
3. **Methodology trace** — BT-002 cap-3 iter chain (iter-1 ADR-013 + iter-2 ADR-014 + iter-3 escalation) เป็น empirical proof ที่ supports the Option 1 legacy-parity decision; suppressing 013/014 ใน Digest = losing the "why we tried + falsified" audit trail
4. Cross-doc consistency: `ADR-010 § Revision history` line 109 explicitly cites "ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (preserved audit history)" — `02 § 9` should mirror

**Minimum acceptable fix:**

Add 2 superseded-status rows to ADR Digest table after ADR-012 row (lines 472):

```markdown
| ADR-013 | CircuitBreaker BR-3.6 ping-pong DEAL_REASON_EXPERT filter | **Superseded by BT-002** | (iter-1 surgical filter — closed broker-driven SL false-positive class; preserved as audit history) | n/a — superseded | [013](../adr/013-circuitbreaker-pingpong-deal-reason-filter.md) |
| ADR-014 | CircuitBreaker BR-3.6 ping-pong position_id + event_type dedup | **Superseded by BT-002** | (iter-2 schema-extending dedup — falsified by iter-3 Slot_BI pyramiding same-tick class; preserved as audit history) | n/a — superseded | [014](../adr/014-circuitbreaker-pingpong-position-event-dedup.md) |
```

Update footer line 474:
```markdown
> **End of 02 — High-Level Architecture** — Traceability matrix (41 FR + 30 NFR + 9 BR + 8 OQ), 25 components across 5 layers (CircuitBreaker row removed per BT-002), **12 active ADRs + 2 superseded** (ADR-013/014 preserved as BT-002 cap-3 iter audit history)
```

**Level of Effort:** Low (2-row table addition + 1-line footer)

---

### Claim 07.4: 🟡 MEDIUM — Line-anchor brittleness ของ `Slot_J.mqh:180` + `Slot_BI.mqh:212` ที่ cited ใน `03 § 1.5` + `08 § 1.10` ขัด workflow gate #9 (h)

**Location:**
- `docs/design-docs/03-deep-dive.md` § 1.5 line 59
- `docs/design-docs/08-product-breakdown.md` § 1.10 line 130

**Problem:**

Bucket B validation prose ใน 03 line 59:

> *"...Post-BT-002 (2026-05-17, BR-3.6 detector removed) the `DISABLE_G4_FIXES` build runs to natural-end of measurement window — full-window G4 contribution measurable if forensic toggle retained at **`slots/Slot_J.mqh:180`** + **`slots/Slot_BI.mqh:212`**..."*

Same string ใน 08 line 130 (IMPL-063 task description).

ปัญหา:
1. **ไฟล์ยังไม่ถูกเขียน** — `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` + `Slot_BI.mqh` คือ deliverables ของ IMPL-022 (Slot_J) + IMPL-039 (Slot_BI) — Phase 3I tasks ที่ยังไม่เริ่ม. Line numbers 180 + 212 = engineering guess
2. **Line-anchor brittleness** — แม้หลังเขียนเสร็จ, line numbers จะ drift ทุกครั้ง refactor; cite สลายเงียบ
3. **Workflow gate #9 clause (h)** (`.claude/rules/workflow.md`) ระบุชัด: *"bin-1 routing comments MUST cite the destination by grep-stable anchor (symbol name, comment marker, or function definition), NOT by physical line number. Line numbers MAY appear as ancillary navigation aids but MUST NOT be the load-bearing anchor"*. แม้ rule นั้นเป็น code-comment scope, แต่ SD docs ที่ cite ไม่ใช่ doc anchors (TD-02 § X line N) = same brittleness class

**Why this matters:**

IMPL-022 + IMPL-039 engineer reading 03/08 จะ:
1. ตี physical line 180 ใน Slot_J.mqh ที่กำลังเขียน — ไม่ตรง = mismatch confusion
2. แม้ตรง — refactor 6 เดือนข้างหน้า ทำให้ line drift; cite stale

R23 ใน workflow.md ระบุ "Methodology-scope axis surfaced: every newly-authored Gate #9 clause MUST be verified tree-wide on its first verify pass". BT-002 cascade was the first time these line anchors were introduced; the verify pass (this review) is the proper time to surface.

**Minimum acceptable fix:**

แทน physical line cite ด้วย grep-stable symbolic anchor:

Edit `03 § 1.5` line 59:
```
...forensic toggle retained at `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` (per ADR-009 G4 fix toggle pattern)...
```

Edit `08 § 1.10` IMPL-063 line 130:
```
...forensic toggle retained at `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` per ADR-009 G4 fix toggle pattern...
```

หรือถ้า engineer ต้องการ specific call-site marker — cite stable comment marker เช่น `// ADR-009 G4 toggle (DISABLE_G4_FIXES forensic build)` แทน physical line.

**Level of Effort:** Low (2 single-line edits)

---

### Claim 07.5: 🟡 MEDIUM — `05 § 2.5` DoS row "Infinite re-entry loop" — mitigation prose verbose; collapse to STRIDE-row format

**Location:** `docs/design-docs/05-security.md` § 2.5 line 120

**Problem:**

DoS table row "Infinite re-entry loop" Mitigation column ยาว 2 paragraphs:

> *"**Accepted residual risk per BT-002 2026-05-17** (legacy-parity). Operator monitoring + manual EA detach are the Phase 1 mitigations. Phase 2 candidates per ADR-010 Revisit-when: equity-floor enforcement (OQ-6 promotion) or journal-write sustained-failure escalation. Former FR-6.6 CircuitBreaker ping-pong removed (cap-3 iter chain ADR-013 → ADR-014 falsified 3 false-positive classes)."*

Likelihood + Impact columns เป็น free-prose ยาว ๆ เช่นกัน:

> *"Low — `PhoenicisN2.10_stable` legacy run-to-end of 5-yr backtest without one was the empirical proof per BT-002 2026-05-17; per-slot SL/TP + cross-slot SafePort + RiskManager.ClampLot + force-pending timeouts cap individual exposure even without a portfolio-level loop guard"*

ผิด format ของ STRIDE table (row = scan-friendly summary). Reader ทำ scan-first review เห็น row ใหญ่นี้ใน table → จับใจความช้า.

**Why this matters:**

STRIDE table = quick reference สำหรับ threat enumeration + mitigation. Multi-paragraph row prose:
1. ลด scan-ability
2. Mix "threat description" + "mitigation rationale" + "audit history" — สามมิติใน 1 cell
3. BT-002 audit annotation ("Former FR-6.6 CircuitBreaker ping-pong removed") = transient cite ที่ tax current-state security model

**Minimum acceptable fix:**

แตก row ที่ครอบคลุม 3 มิติ ออกเป็น compact form + push detailed rationale ออกไป § 6 หรือ § 9:

```markdown
| **Infinite re-entry loop (no automated portfolio-level loop guard Phase 1)** | Low (legacy `PhoenicisN2.10_stable` 5-yr backtest demonstrates safe operation without one) | High (could blow account; no automated detector) | **Accepted residual risk per BT-002 2026-05-17** — operator monitoring + manual EA detach are Phase 1 mitigations; per-slot SL/TP + cross-slot SafePort + RiskManager.ClampLot + force-pending timeouts cap individual exposure. Phase 2 trigger candidates per ADR-010 Revisit-when. → See § 9 Red Team Hand-off Notes for cap-3 iter chain ADR-013 → ADR-014 audit trail. |
```

Move cap-3 iter chain audit history ไป § 9 Red Team Hand-off Notes table หรือ separate § "Decision History" appendix.

**Level of Effort:** Low (1 row tighten + add § 9 reference)

---

### Claim 07.6: 🟡 MEDIUM — `04 § 1.1` mermaid stranded "Note over Orc: CircuitBreaker.CheckPingPong removed per BT-002" inside current-state sequence

**Location:** `docs/design-docs/04-data-flow.md` § 1.1 line 46

**Problem:**

OnTick sequence diagram (line 21-119) บรรยายลำดับ post-BT-002 ของ OnTick pipeline. ระหว่าง MarketContext Build (line 43-44) และ AnyHandleInvalid check (line 48-52) มี stranded note:

```
    Note over Orc: CircuitBreaker.CheckPingPong removed per BT-002 2026-05-17 (legacy-parity)
```

Mermaid renders note นี้ as inline annotation บน Orchestrator participant. Diagram ของ current-state OnTick pipeline ไม่ควรอ้างถึง code path ที่ถูกลบ — audit trail ของการลบอยู่ใน commit history + ADR-010 § Revision history แล้ว.

**Why this matters:**

`04 § 1.1` mermaid sequence = "first-time reader" visual reference สำหรับ OnTick pipeline. Reader (Tech Lead, QA, junior dev) ดู diagram ครั้งแรกหลัง BT-002:

1. เห็น "CircuitBreaker.CheckPingPong removed per BT-002" annotation
2. Mental model conflict: "CB ยังอยู่ในระบบหรือเปล่า? ทำไมต้องประกาศการลบใน flow diagram?"
3. Audit annotation belongs ใน revision history / commit message — ไม่ใช่ inside a current-state operational diagram

Compare: `02 § 4.2` Component Catalog footer line 302 ทำถูก — "**Removed per BT-002 2026-05-17**: `CircuitBreaker` service (former row #14)..." ใส่ใต้ table เป็น **explicit audit footnote** ไม่ใช่ in-place inside the inventory diagram. `04 § 1.1` mermaid ทำตรงข้าม.

**Minimum acceptable fix:**

ลบ line 46 ออกจาก mermaid diagram. Audit trail of CB removal:
1. `02 § 4.2` footer L302 ✅ already documents
2. `ADR-010 § Revision history` L107-109 ✅ already documents
3. `backtrack-log.md § BT-002` ✅ already documents
4. Git commit `0be2a51` ✅ already records

ไม่จำเป็นต้อง stranded note ในtransient diagram.

Optionally — add inline `04 §` footer note (parallel to `02 § 4.2` pattern):

```markdown
> **Note (post-BT-002 2026-05-17):** Former `CircuitBreaker::CheckPingPong()` call ที่เคยอยู่ระหว่าง `MarketContextBuilder.Build()` และ `AnyHandleInvalid()` check ถูกลบ. ดู ADR-010 § Revision history + `backtrack-log.md § BT-002` สำหรับ rationale.
```

**Level of Effort:** Low (delete 1 mermaid line + add 1 prose note)

---

### 🔵 LOW

---

### Claim 07.7: 🔵 LOW — `02 § 8 Glossary` duplicate semantic entries "Halted state semantic" + "HALT vs HALT_STABLE"

**Location:** `docs/design-docs/02-high-level-architecture.md` § 8 lines 447, 451

**Problem:**

§ 8 Glossary มี 2 entries ที่ define ทับซ้อนกัน:

Line 447:
> *"**Halted state semantic** | EA สถานะ HALTED = exit pass run + entry pass skip; HALTED_STABLE = portfolio empty + waiting (ADR-010)"*

Line 451:
> *"**HALT vs HALT_STABLE** | HALT = ตัด entry pass; HALT_STABLE = HALT + portfolio.count == 0 (ADR-010)"*

ทั้ง 2 entries point กลับมา ADR-010 + define semantic เดียวกันด้วย wording slightly different. Reader ที่ scan glossary alphabetically สับสนว่าใช้ entry ไหน.

Pre-existing — ไม่ใช่ BT-002 introduced — แต่ BT-002 review เป็นโอกาสที่จะ surface.

**Why this matters:**

Glossary discipline (per `system-design-master-prompt.md § Readability Contract`) = single canonical definition per term. Duplicate entries:
1. Reader trust ลดลง — "which definition is authoritative?"
2. Maintenance burden — future amendment ต้อง edit ทั้ง 2 places
3. Cross-doc cite drift — `05 § 1.1` cite "Halted state semantic" but `03 § 1.1` cite "HALT vs HALT_STABLE" → split linkage

**Minimum acceptable fix:**

Merge เป็น single entry. Suggested:

```markdown
| **HALTED state machine (HALTED / HALTED_STABLE)** | EA state per ADR-010 (amended BT-002). **HALTED** = exit pass run + entry pass skip + cross-slot EOverload/GOverload disabled. **HALTED_STABLE** = HALTED + `PortfolioState.TotalActivePositions() == 0` (second Alert emitted). Both states persist via `state.json § ea_state`; OnInit reset to RUNNING |
```

ลบ entry "HALT vs HALT_STABLE" L451; replace "Halted state semantic" L447.

**Level of Effort:** Low (1 entry merge + 1 entry deletion)

---

## Cross-Document Issues

ไม่พบ contradictions ระดับ semantic ใหม่ post-BT-002 — verify-sweep ของ BT-002 cascade surface แสดง grep-stable evidence:

| Cross-doc surface | Layer 1 (SD doc) | Layer 2 (ADR) | Layer 3 (API spec) | Status |
|---|---|---|---|---|
| HALTED trigger source = `AnyHandleInvalid()` runtime | `02 § 1.1 FR-7.7 L62` + `05 § 3.2 L159` + `04 § 9.1 L545 (n/a row)` | `ADR-010 § Trigger sources L18-21` | `trade-journal-schema.yaml § halt_reason L188-196` enum drops `circuit_breaker_pingpong` | ✅ Single-voice |
| FR-6.6 status | `02 § 1.1 L54` strikethrough | (BA layer pending chained `/backtrack ba`) | n/a | ⚠️ Documented intentional sequencing (SD ก่อน BA per `backtrack-log.md § BT-002`) |
| ADR-013/014 status | (not enumerated ใน `02 § 9` — Finding 07.3) | `ADR-013 + ADR-014 Status: Superseded by BT-002` L5 | n/a | ⚠️ Cascade gap (Finding 07.3) |
| Component Catalog count | `02 § 4.2` (25 active components — CircuitBreaker row removed L302) | ADR-012 file layout L81 cites removal | n/a | ✅ Aligned |
| `Orchestrator → EAState.Halt` call site | `02 § 5.1 L325` direct path | `ADR-011 § Halt-trigger bypass L59 + § Logger emit sites L75` | n/a | ✅ Aligned |
| Perf budget post-CB removal | `03 § 2.3 Table A L101 (~1,680 µs)` + `Table B L115 (~1,002 µs)` | (ADR-002 perf annotation unchanged) | n/a | ✅ Math consistent |

**BA ↔ SD active layer contradiction (intentional — sequencing flag):**

ตอนนี้:
- BA `02 § FR-6.6` + BA `04 § BR-3.6` ยัง active (per `backtrack-log.md § BT-002 Impacted phases BA cascade pending`)
- SD `02 § FR-6.6` strikethrough + SD docs prose ทั้ง 5 docs ระบุ "removed per BT-002"

นี่คือ **intentional sequencing** — `backtrack-log.md § BT-002 Proposed change` ระบุชัด: *"Engineer recommends BA demotion order: `/backtrack ba` chained AFTER SD lock so the BA rebuttal cycle has a concrete SD proposal to align against."* ไม่ใช่ defect; ไม่ raise finding.

> **Post-Round 07 sequencing flag:** หลังจาก SD-side findings (07.1-07.7) clean closure + Round 08 = 0 finding → operator authorize chained `/backtrack ba` to demote BR-3.6 + FR-6.6 to `Won't` (or removal) at BA layer per `backtrack-log.md § BT-002 Proposed change § Chained /backtrack ba`. หลังจาก BA cascade clean → BT-002 Status flip `🔄 Open` → `✅ Closed` ใน `backtrack-log.md`.

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 07.1 | 🟠 HIGH | Phase Hint Summary § 5 stale (IMPL-051 still listed in P2 task list + ~11 tasks + Total ~68) | `08-product-breakdown.md` § 5 L308, L312 | Low |
| 07.2 | 🟠 HIGH | Last-updated header stale 5/6 SD docs (still cite BT-001 2026-05-12 despite BT-002 edits applied 2026-05-17) | `02/03/04/05/08` L5 each | Low |
| 07.3 | 🟡 MEDIUM | ADR Digest § 9 narrates "12 ADRs" but 14 .md files exist; ADR-013/014 superseded-but-present require explicit row | `02-high-level-architecture.md` § 9 L460-472, L474 | Low |
| 07.4 | 🟡 MEDIUM | Line-anchor brittleness `Slot_J.mqh:180` + `Slot_BI.mqh:212` cite (workflow gate #9 (h)) | `03 § 1.5 L59` + `08 § 1.10 L130` | Low |
| 07.5 | 🟡 MEDIUM | `05 § 2.5` DoS row "Infinite re-entry loop" multi-paragraph mitigation prose breaks STRIDE row format | `05-security.md` § 2.5 L120 | Low |
| 07.6 | 🟡 MEDIUM | `04 § 1.1` mermaid stranded "CircuitBreaker.CheckPingPong removed" note inside current-state sequence | `04-data-flow.md` § 1.1 L46 | Low |
| 07.7 | 🔵 LOW | `02 § 8` Glossary duplicate entries "Halted state semantic" + "HALT vs HALT_STABLE" | `02-high-level-architecture.md` § 8 L447, L451 | Low |

---

## Round 07 Closure Notes

- **Methodology fingerprint:** Round 07 trajectory mirrors Round 05 (post-BT-001 first-sweep) pattern — cascade-completion gaps in parallel-narrative sections (§ 5 Phase Hint Summary, header fields, ADR Digest table) ที่ primary surfaces (§ 1.7/§ 3/§ 4 task descriptions) ปิดแล้ว. ไม่ใช่ architectural defect; เป็น cascade discipline gap class ที่ Round 03→04 + Round 05→06 เคยจัดการได้ใน 1 rebuttal round
- **No CRITICAL pattern:** BT-002 cascade fundamentals (semantic invariants, halt trigger reduction from 2→1, ADR amendments with audit history, API spec enum updates) landed coherently. The 7 findings เป็น **completion + freshness + readability** dimensions ไม่ใช่ design integrity
- **Anti-Duplication trail:** Round 06's `claim-review-06.md § Cross-Document Issues` table 8 surfaces ของ BT-001 cascade single-voice — ทุก surface verify-only ✅ Pass post-BT-002. Round 03's cumulative-counter cascade (force_clear_count + throttled_alert_count) — ✅ untouched + stable
- **Sequencing acknowledgment:** SD-first cascade (SD edits ก่อน BA cascade) เป็น intentional per `backtrack-log.md § BT-002` — not flagged as finding; documented inline ใน Cross-Document Issues
- **Empirical Closure Discipline:** SD layer ไม่มี E-AC scope; ทุก finding verify ผ่าน grep ของ literal text + cross-reference checking — no operator-runtime evidence required
- **State Reconciliation hint:** `docs/state/overview.md` Phase Status row **Design (SD)** ตอนนี้ระบุ "BACKTRACK — SD rework APPLIED 2026-05-17 (BT-002 Option 1 legacy-parity...); Status: ready for `/sd-review all` re-validation" — operator update หลัง close Round 07 + rebuttal-07: append `+ Round 07 (post-BT-002 first-sweep — 2 HIGH + 3 MEDIUM + 2 LOW; awaiting rebuttal-07)`

### Recommended action sequence

1. ✅ Round 07 (this file) — closes first adversarial sweep of post-BT-002 SD package
2. Operator update `docs/state/overview.md` Design (SD) row → append `+ Round 07 (post-BT-002 first-sweep — 2 HIGH + 3 MEDIUM + 2 LOW)`; Last Updated bump to 2026-05-17
3. Next: `/sd-rebuttal claim-review-07.md` — Architect applies Claims 07.1-07.7 (≤ 45 min total; primary file `08` + freshness sweep 5 docs + minor cleanup `02/03/04/05`)
4. Re-run `/sd-review all` Round 08 → expect 0 finding (mirror Round 03→04 + Round 05→06 clean-closure pattern)
5. หลัง Round 08 clean → operator authorize chained `/backtrack ba` (BR-3.6 + FR-6.6 demotion at BA layer per `backtrack-log.md § BT-002 Proposed change § Chained /backtrack ba`)
6. หลัง BA cascade clean → operator populate `backtrack-log.md § BT-002 Resolution` cell + flip Status `🔄 Open` → `✅ Closed`; trim `docs/state/overview.md` "🔄 BACKTRACK — SD rework APPLIED" markers per Check 0.7 Direction A discipline
7. Optional parallel after Step 4: `/td-review all` re-validate (TD package may need BT-002 cascade — `backtrack-log.md § BT-002 Impacted phases — TD` flags `02-backend-design.md § 5.8` CCircuitBreaker skeleton DELETE + 10 cross-refs)

> **End of Round 07 review** — 7 findings (0 CRITICAL / 2 HIGH / 3 MEDIUM / 2 LOW); BT-002 cascade fundamentals coherent; gaps are cascade-completion + freshness + readability. Run `/sd-rebuttal claim-review-07.md` next.
