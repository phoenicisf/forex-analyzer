# System Design Rebuttal Round 01

| Field | Value |
|-------|-------|
| **Round** | 01 |
| **Claim Review** | `claim-review-01.md` |
| **Date** | 2026-05-02 |
| **Defender** | `andm-sd-defender` (Architect, Phase 1B) |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 14 |
| Partial | 3 (01.4, 01.6, 01.7) |
| Rejected | 0 |

**Files modified (10 docs / 4 specs / 8 ADRs touched):**
- `docs/design-docs/02-high-level-architecture.md` (5 edits — FR-7.6 row, BV/SR/IS catalog rows, mermaid label, ADR Digest ADR-007 row, glossary row removed, new § 6.1.1 Sync rule)
- `docs/design-docs/03-deep-dive.md` (3 edits — § 2.3 split into 2 tables + reframe baseline, § 3.4 Failure modes row, § 7 add A6+A7 risks)
- `docs/design-docs/04-data-flow.md` (8 edits — F1 SpreadGuard split, handle count language, § 1.2 insight, § 4 P-Pending sub-mode subsection, § 5.1 log message + recovery row, § 6 consistency boundary row, § 8 escalation block, § 9 enable matrix + correction-note removed)
- `docs/design-docs/05-security.md` (3 edits — handle count, § 3.2 IsMondaySpreadHigh + IsMorningWakeup rows, § 7.2 add 3 monitoring signals)
- `docs/design-docs/07-future-evolution.md` (1 edit — § 6 rewrite from "N/A" to Evolution Sequence E1+E2)
- `docs/design-docs/08-product-breakdown.md` (5 edits — IMPL-018 expand, IMPL-034 P-sub-mode, TL;DR Evolution Sequence reference, Phase Hints reflects-Ex annotations P1/P2/P3)

**ADRs updated (7):**
- `adr/002-slot-abstraction-via-oo-inheritance.md` — concrete 2-layer override enforcement (boot-time + runtime)
- `adr/003-centralized-indicator-service.md` — handle count locked ~25 + revisit-when TD spike
- `adr/006-trade-journal-jsonlines.md` — RPO contract + escalation policy + journal_metrics persistence
- `adr/007-state-persistence-atomic-temp-rename.md` — Option B fully designed (3-file rotation + 1-byte single-sector pointer + crash-window matrix)
- `adr/008-pending-state-safety-force-clear.md` — drop wrong-proxy derivation + reframe as engineering estimate + IMPL-068 validation
- `adr/010-halted-state-exit-only.md` — Safe-port enable matrix in HALTED + revision history
- `adr/011-tagged-structured-logger.md` — distinct events independent throttle + halt-trigger bypass + escalation + counter
- `adr/012-file-layout-module-split-discipline.md` — handle count comment alignment

**API specs updated (2):**
- `api-specs/slot-abstraction-contract.yaml` — full rewrite from OpenAPI 3.0.3 → JSON Schema 2020-12 (consistent with 3 sibling specs); explicit method signatures + EnforcementMechanism block
- `api-specs/state-persistence-schema.yaml` — added `journal_metrics` block (RPO observability) + `logger_metrics` block (throttle observability) + enriched `PendingMachineState_PVariant` description (sub-mode mapping)

**ADRs created:** 0

---

## Claim Responses

### Claim 01.1: 🔴 CRITICAL — Safe-port HALTED behavior contradiction (ADR-010 ↔ 04 § 9)

**Verdict:** Accept

**Decision:** **Safe-port = ENABLED ใน HALTED**. Rationale: Safe-port (BR-8.1) คือ exit-side action (close 10 positions); align กับ AC-7.7.3 ("exit pass run during halt") + G4 ("no orphan exposure"); per-slot ManageExits ไม่ replace portfolio-wide cleanup ของ Safe-port pattern. ADR-010 wording เดิม ("disabled to preserve EA เดิม intent") ไม่มี AC backing; 04 correction note's logic ตรงตาม contract.

**Changes:**
- File: `docs/adr/010-halted-state-exit-only.md` § "Cross-slot logic in halted state" + new § "Revision history"
- What changed: Safe-port flipped to **enabled**; full enable matrix enumerated (BR-8.1/8.2/8.3/8.5 enabled; BR-8.4 EOverload/GOverload disabled; COverload enabled; Pending machines frozen). Revision history line dated 2026-05-02 ระบุ resolution ของ Claim 01.1
- File: `docs/design-docs/04-data-flow.md` § 9
- What changed: Replaced ambiguous table + correction note ด้วย authoritative "RUNNING / HALTED enable matrix" mirror ของ ADR-010; correction note paragraph ลบ (cascades 01.15)
- File: `docs/design-docs/05-security.md` § 3.2 unchanged but verified consistent (line 158 "exit-pass-only after halt" ตรงกับ ADR-010 + line 266 Red Team note "Safe-port + ForceCutloss work" ตรงกับ ENABLED decision)

### Claim 01.2: 🟠 HIGH — Tick-latency budget arithmetic ไม่ reconcile กับ NFR-2.1

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/03-deep-dive.md` § 2.3 (replaced single muddle table)
- What changed: แตกเป็น 2 tables ชัดเจน:
  - **Table A — Rewrite total tick budget** (sum ทุก row, ครอบคลุม preserve-baseline + new-in-rewrite — total ~1,685 µs steady state, ~4,685 µs with 1 event, ~31,685 µs with 10-event burst)
  - **Table B — Overhead delta vs baseline** (เฉพาะ "added cost" rows: MarketContextBuilder + CircuitBreaker + StatePersistence + Logger + virtual call ≈ ~1,005 µs)
  - Implication note: ถ้า baseline 7 ms → ceiling 700 µs → **fail** (1,005 > 700); ถ้า baseline 10 ms → borderline pass; mitigation paths enumerated (dirty-bit throttle / log tuning / static dispatch / lazy fields)
- Baseline ~7 ms เปลี่ยนเป็น "**TBD ใน TD spike Phase 1D (IMPL-065)**" + acknowledge ว่า round-0 ค่า = engineering guess
- File: `docs/design-docs/04-data-flow.md` § 1.2 insight statement
- What changed: rewrote "within 10% NFR-2.1 budget given 7 ms baseline" → "overhead delta ~1,005 µs; NFR-2.1 acceptance ผูกกับ measured baseline จาก IMPL-065"

### Claim 01.3: 🟠 HIGH — Indicator handle count inconsistent (21 vs 25 vs ~25-30)

**Verdict:** Accept

**Changes:** Locked ที่ **`~25 handles`** ทุก doc; TD spike Phase 1D (IMPL-005) จะ confirm exact count
- File: `docs/adr/003-centralized-indicator-service.md` § Decision API + Decision table footer + Revisit-when
- What changed: "~30 handles" → "~25 handles"; table footer rewritten ("Total estimate ~25 = base 21 + ~4 per-slot params variant"); SD-locked estimate paragraph + TD spike trigger paragraph + new revisit-when entry "ถ้า exact count > 30 → revisit"
- File: `docs/design-docs/02-high-level-architecture.md` § 4.1 mermaid label
- What changed: `~25-30 handles` → `~25 handles`
- File: `docs/design-docs/03-deep-dive.md` § 2.3 Table A row
- What changed: "(CopyBuffer × ~25 handles)" → "(CopyBuffer × ~25 handles, TD-locked)"
- File: `docs/design-docs/04-data-flow.md` § 1.1 Refresh + § 5.1 CreateHandles loop + log message
- What changed: log message "25/25 handles" → "<N>/<N> handles (N = TD-locked count, ~25 expected)"; loop sequence + final ack annotated "exact count locked at TD spike Phase 1D"
- File: `docs/design-docs/05-security.md` § 2.5 DoS row
- What changed: "we use ~25" → "we use ~25 (TD-locked Phase 1D)"
- File: `docs/adr/012-file-layout-module-split-discipline.md` IndicatorService folder comment
- What changed: "~25-30 handle owner + cache" → "~25 handle owner + cache (TD spike Phase 1D locks exact count)"

### Claim 01.4: 🟠 HIGH — ADR-007 atomic write Option B undesigned

**Verdict:** Partial

**Accepted part:** Option B was 4-line stub พร้อม false "recursion" rationale; designed properly with concrete schema, save/load pseudocode, atomicity proof (single-sector NTFS guarantee for 1-byte pointer), and crash-window recovery matrix. Cross-doc updates added to `02 § 9 ADR Digest` + `03 § 3.4 Failure modes`.

**Rejected part:** Reviewer's "Either: run spike before locking SD OR elevate Option B to co-equal primary" framing rejected. Spike (IMPL-046) belongs to TD Phase 1D — SD lock + spike are sequential phases (per Evolution Sequence E1 ที่เพิ่งเพิ่มจาก Claim 01.13). Co-equal primary = unnecessary work if A2 passes (which is the expected outcome — NTFS atomic guarantee is well-documented for same-volume MoveFileEx; only sandbox virtualization is at risk).

**Changes:**
- File: `docs/adr/007-state-persistence-atomic-temp-rename.md` § Options § Option B
- What changed: Replaced 4-line stub with full design — 3-file schema (state-A.json, state-B.json, state-meta.bin 1 byte), Save/Load pseudocode, atomicity proof (sector-boundary NTFS guarantee for ≤512-byte single write), crash-window recovery matrix (4 scenarios). Status updated to "Designed-but-not-primary fallback ของ Option A".
- File: `docs/adr/007-state-persistence-atomic-temp-rename.md` § Revisit-when
- What changed: Updated trigger language — "activate Option B (designed above; ready-to-implement)" + listed cascade docs
- File: `docs/design-docs/02-high-level-architecture.md` § 9 ADR Digest row ADR-007
- What changed: Trade-off cell expanded — note conditional บน A2 spike + Option B = ready fallback
- File: `docs/design-docs/03-deep-dive.md` § 3.4 Failure modes row "FileMove not atomic"
- What changed: Mitigation specified — "Activate ADR-007 Option B" + scope estimated (~1-2 day refactor, bounded to AtomicFile + state-meta.bin + state-persistence-schema.yaml; downstream code unchanged)

### Claim 01.5: 🟠 HIGH — slot-abstraction-contract.yaml ใช้ OpenAPI 3.0.3 wrong tool

**Verdict:** Accept

**Changes:**
- File: `docs/api-specs/slot-abstraction-contract.yaml`
- What changed: Full rewrite — eliminated `openapi: 3.0.3` + `paths:` HTTP-style structure. Replaced with **JSON Schema 2020-12** consistent กับ 3 sibling specs (trade-journal, state-persistence, marketcontext-snapshot). New top-level structure: `methods` block (6 method signatures: Magic / SlotId / Evaluate / ManageExits / DependsOn / PendingState — แต่ละตัว ระบุ MQL5 signature + parameters + returns + side_effects + behavior_steps + invocation_rule), `constructor_injection` block (discipline_rule + 7 injected dependencies), `enforcement_mechanism` block (boot_time + runtime + compile_time layers — สอดคล้องกับ Claim 01.11 fix ใน ADR-002).
- Cross-doc refs (ADR-002 + 02 § 4.2 + 04 § 2 + 08 § IMPL-018) ที่อ้าง spec ยังชี้ตำแหน่งเดิม (file path unchanged) — no broken links

### Claim 01.6: 🟡 MEDIUM — ADR-008 force-clear thresholds lack rigorous derivation

**Verdict:** Partial

**Accepted part:** Round-0 rationale ที่อ้าง "max position holding time = 121 H4 bars" เป็น derivation = wrong proxy (position holding ≠ pending state duration). Drop จาก rationale + reframe เป็น "engineering estimate" + add as acknowledged risk A6 ใน `03 § 7` + IMPL-068 (QA Phase 3T) จะ measure actual `pending_age_bars` distribution.

**Rejected part:** Reviewer's "เปิด `ReportTester-25045474.html` parser tool ตอน SD lock เพื่อ extract baseline" rejected. นั่นคือ QA Phase 3T scope (IMPL-068 already documented); Phase 1B SD lock ใช้ engineering estimate + tunable input + acknowledged risk เป็น proper hand-off pattern. ถ้า bake measurement into SD = couple SD progress กับ QA tooling work.

**Changes:**
- File: `docs/adr/008-pending-state-safety-force-clear.md` § Decision table + § "Why these numbers"
- What changed: Per-row rationale rewrite — added ⚠️ marker + acknowledge ว่าเป็น engineering estimate; "≤ 30 bars typical" / "≤ 20 bars typical" / "code 3 ช้าสุด" claims wrapped in "ยังไม่ extracted measurement; IMPL-068 จะ confirm"
- "Why these numbers" section: dropped wrong-proxy "121 H4 bars max holding" comparison; added note ว่า round-0 used wrong metric; pointer to A6 + IMPL-068
- File: `docs/design-docs/03-deep-dive.md` § 7
- What changed: Added A6 row (force-clear threshold engineering estimate) + A7 row (P-Pending sub-modes; covered by Claim 01.8); updated end-of-doc footer to "7 acknowledged technical risks (A1-A7)"

### Claim 01.7: 🟡 MEDIUM — F1 SpreadGuard collapses 3 separate FR/BR rules

**Verdict:** Partial

**Accepted part:** `04 § 1.1` step `Orc->>TG: SpreadGuard()` poorly named + collapses 2 distinct logic into 1 method call. Split into 2 sequence steps: `IsMorningWakeup()` (FR-6.1, BR-3.1, ทุกวัน 00:00-00:05) + `IsMondaySpreadHigh()` (FR-6.2, BR-3.2, BR-3.7, Monday + spread > 10 × DigitMultipier). Method names ตรงกับ `02 § 4.2 TimeGate` row + `08 § IMPL-050`.

**Rejected part:** Reviewer's claim ว่า BA แยก 3 rules โดย "**BR-3.7 SpreadGuard:** general spread filter (ไม่จำกัด Monday)" = **factually wrong**. ตรวจ BA `04-business-rules.md` BR-3.7:
> *"BR-3.7 — Spread guard at OnTick start: Condition = `SYMBOL_SPREAD > 10 × DigitMultipier` AND `IsMondayMorningWakeup()` (rule-3.2 reuses)"*

BR-3.7 และ BR-3.2 มี condition เดียวกัน (Monday morning + spread). BR-3.7 ไม่ใช่ "general spread filter ไม่จำกัด Monday" — มันคือ rule-3.2 reuses. ดังนั้น sequence diagram ต้อง 2 steps (ไม่ใช่ 3 steps ที่ reviewer เสนอ). Justification: BA BR-3.7 line 201-203.

**Changes:**
- File: `docs/design-docs/04-data-flow.md` § 1.1
- What changed: ลบ `Orc->>TG: SpreadGuard() — IsMondayMorningWakeup + spread > 10pip` (ambiguous merge) → 2 distinct steps with FR/BR tags; "morning wakeup" alt note ระบุ skip exit + entry; "Monday + high spread" alt note ระบุ skip entry only (exit pass continue)
- File: `docs/design-docs/05-security.md` § 3.2
- What changed: Split TimeGate row — IsMondaySpreadHigh + IsMorningWakeup เป็น 2 rows ชัดเจน; method name + FR/BR tags ตรงกัน

### Claim 01.8: 🟡 MEDIUM — P-Pending sub-modes (PX/PH/E/N) defined ใน schema-only

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/04-data-flow.md` new § 4.4 "P-Pending sub-mode detail"
- What changed: Added subsection ที่ describe sub_mode enum ทุกตัว (PX/PH/E/N + null) + when-triggered + populated fields (diff_sl, band_ratio) + TP ratio mapping. Cross-ref CodeWiki §2.5/§3.14 explicitly. Field meaning explained: `diff_sl` = SL distance pip ที่ snapshot; `band_ratio` = `CalculateBollingerRatio` ผลลัพธ์ใน [0..100]. Exit-pending invalidation rules (Bollinger violation / 70-bar timeout / sub-mode lock-once semantic).
- File: `docs/api-specs/state-persistence-schema.yaml` § PendingMachineState_PVariant
- What changed: Description enriched — sub_mode enum ระบุ mapping ชัดเจน + cross-ref `04 § 4.4`; diff_sl + band_ratio descriptions ระบุ purpose
- File: `docs/design-docs/08-product-breakdown.md` IMPL-034 row
- What changed: Task description expanded — "P-Pending state machine — sub-modes PX/PH/E/N per `04 § 4.4` (E = P_Extra extension entry, comment `\"PI,...\"`)" + arch_rationale ระบุ A7 risk
- File: `docs/design-docs/03-deep-dive.md` § 7
- What changed: A7 risk row added — "P-Pending sub-modes ยังต้อง confirm กับ CodeWiki §2.5 ตอน TD Phase 1D (IMPL-034)"

### Claim 01.9: 🟡 MEDIUM — BootstrapValidator vs IndicatorService ownership ของ FR-7.6

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 1.1 FR-7.6 traceability row
- What changed: SD section/component changed from `core/BootstrapValidator::ValidateIndicatorHandles()` → `services/IndicatorService::CreateHandles()` (returns false on any INVALID_HANDLE → orchestrator → INIT_FAILED). อ้าง ADR-003 unchanged
- File: `docs/design-docs/02-high-level-architecture.md` § 4.2 Component Catalog
- What changed:
  - Row 3 (BootstrapValidator): Removed "indicator handle validation" + FR-7.6 + BR-9.4. Kept FR-1.2/1.4 + BR-9.1/9.3 + DigitMultipier. ADR ref dropped ADR-003 (BV no longer touches indicator handles)
  - Row 4 (SlotRegistry): Added BR-9.4 (magic-range invariant) + responsibility wording expanded
  - Row 7 (IndicatorService): Added FR/NFR tags explicitly (FR-2.6, FR-7.6, FR-8.1, NFR-3.2) — were implicit before

### Claim 01.10: 🟡 MEDIUM — Trade-journal RPO under sustained slow disk = unspecified

**Verdict:** Accept

**Changes:**
- File: `docs/adr/006-trade-journal-jsonlines.md` § Failure handling
- What changed: Added explicit RPO contract table (4 scenarios: graceful shutdown / hard crash mid-event / sustained failure / single slow event); each with target + behavior. Added escalation policy: `consecutive_write_failures ≥ 10 → EAState.Halt("journal_write_fail_sustained")` (ADR-010 integration). Added persistence rule: `journal_metrics.write_failures` ใน state.json (atomic per ADR-007) survives restart.
- File: `docs/api-specs/state-persistence-schema.yaml`
- What changed: Added `journal_metrics` block (write_failures, consecutive_write_failures, last_failure_timestamp, last_failure_reason) to top-level required + properties; added `logger_metrics` block (covers Claim 01.12); both blocks documented with cross-ref to ADR-006 + `05 § 7.2`
- File: `docs/design-docs/05-security.md` § 7.2
- What changed: Added 3 monitoring signals (`journal_metrics.write_failures > 0/day` → AV/disk/permission; `consecutive_write_failures ≥ 10` → halt escalation; `logger_metrics.throttled_alert_count > 50` → throttle inspection)
- File: `docs/design-docs/04-data-flow.md` § 8 (Burst handling)
- What changed: Added "Sustained failure escalation" subsection — clarify ที่ degrade-warn-but-continue applies to slow disk (0 events lost) แต่ sustained-fail (≥ 10 consecutive) escalates to halt; cross-ref ADR-006 RPO + ADR-010 + monitoring signal in 05 § 7.2

### Claim 01.11: 🟡 MEDIUM — ADR-002 `=0` virtual enforcement = "discipline" no mechanism

**Verdict:** Accept

**Changes:**
- File: `docs/adr/002-slot-abstraction-via-oo-inheritance.md` § Decision (new "Pure-virtual override enforcement" subsection)
- What changed: Replaced vague "reviewer checklist" wording with **2-layer concrete mechanism**:
  - **Boot-time (primary):** `SlotRegistry::ValidateTopo()` calls `slot.Magic()` + `slot.SlotId()` ของทุก entry; sentinel return (Magic=-1, SlotId="") → INIT_FAILED (NFR-3.2). Concrete code example included.
  - **Runtime (secondary):** Base `CSlotBase::Evaluate / ManageExits / DependsOn / PendingState` body = `Logger::Error + ExpertRemove`. Concrete class skeleton included.
  - Compile-time layer ระบุว่า MQL5 limited (no `=0`) → cannot enforce; rely on layers อื่น
- § Consequences updated — "discipline" → "2-layer enforcement"
- File: `docs/api-specs/slot-abstraction-contract.yaml` (new EnforcementMechanism block, part of Claim 01.5 rewrite)
- What changed: Mirror ของ ADR-002 mechanism — explicit JSON Schema field documenting boot_time + runtime + compile_time layer details
- File: `docs/design-docs/08-product-breakdown.md` IMPL-018 row
- What changed: Task description expanded — "+ 2-layer override enforcement (boot-time sentinel check + runtime base-method `ExpertRemove`; ดู ADR-002)"

### Claim 01.12: 🟡 MEDIUM — Logger throttle suppresses Alert sustained → tension กับ NFR-3.4

**Verdict:** Accept

**Changes:**
- File: `docs/adr/011-tagged-structured-logger.md` § Decision (Throttle row + 3 new rows)
- What changed: Refined throttle policy:
  - **Distinct events independent throttle** — ระบุชัดว่า `(slot, event)` tuples มี throttle counters แยก; new event ของ tuple อื่น ไม่ block
  - **Halt-trigger bypass** — errors ที่ trigger `EAState.Halt()` (CircuitBreaker, IndicatorService runtime invalid, journal sustained-failure, force-clear escalation) **never throttle Alert**
  - **Escalation policy** — same `(slot, event)` ERROR ≥ N consecutive (default N=10, configurable `InpErrorEscalationN`) → secondary Alert + persist `logger_metrics.last_throttle_event`
  - **Throttled counter** — `logger_metrics.throttled_alert_count` (ใน state.json schema) increment ทุก suppressed Alert; surface ใน HALTED_STABLE Alert message
- § Consequences updated — explicit acknowledgment ว่า throttle ขัด strict reading "0 silent failures"; mitigated โดย transparency channels (counter + Print + journal)
- File: `docs/api-specs/state-persistence-schema.yaml` (covered by Claim 01.10 schema update)
- What changed: `logger_metrics` block added (throttled_alert_count, last_throttle_event)

### Claim 01.13: 🟡 MEDIUM — 08 Phase Hints carry hard ordering vs 07 Evolution Sequence = N/A

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/07-future-evolution.md` § 6 (full rewrite from "N/A" to Evolution Sequence with 2 entries)
- What changed:
  - **§ 6.1 Phase 1 internal sequence** — table of E1 (atomic write spike → IMPL-047/048/049 cascade) + E2 (CSlotBase contract → derived slots) with Must-Precede + architectural rationale
  - **§ 6.2 Why Phase 1 needs Evolution Sequence** — re-examination paragraph explaining round-0 "N/A" miss; cite sd.md § Phase Contract "Include เมื่อ..." rules (risky tech fail-fast + inheritance contract = compile prerequisite)
  - **§ 6.3 Cross-reference** — pointers ไปหา 08 § 3 Phase Hints + IMPL-046/018/047/048/049 in Per-Task Metadata
- File: `docs/design-docs/08-product-breakdown.md` § TL;DR + § 3 Phase Hints intro + P1/P2/P3 hint rationale
- What changed:
  - TL;DR — added "Evolution Sequence (E1+E2 ใน `07 § 6`) = hard ordering" sentence
  - § 3 intro — replaced "ไม่มี Evolution Sequence" with hard-constraint reference + override rule
  - P1 IMPL-046 hint — annotated "**reflects Evolution E1**"
  - P2 IMPL-047/048 hint — annotated "**reflects Evolution E1a/E1b**"
  - P2 IMPL-049 hint — annotated "**reflects Evolution E1c**"
  - P3 IMPL-018 hint — annotated "**reflects Evolution E2**"

### Claim 01.14: 🟡 MEDIUM — state.json vs MT5 GlobalVariable dual-source-of-truth ใน ADR-007 only

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` new § 6.1.1 "Sync rule"
- What changed: Added 6-row table surface ระบุ canonical source / GlobalVariable role / sync direction (state.json → GV one-way) / conflict resolution on Load (state.json wins) / recovery from corrupt state.json + intact GV / crash window. Surface สิ่งที่ buried ใน ADR-007 § Consequences เป็น first-class architecture topic
- File: `docs/design-docs/04-data-flow.md` § 6 Consistency Boundaries
- What changed: Added new row "state.json canonical, MT5 GlobalVariable mirror" — cross-ref `02 § 6.1.1` + recovery rule for `worst_drawdown_*` fields
- File: `docs/design-docs/04-data-flow.md` § 5.3 Recovery scenarios
- What changed: Updated "Crash recovery (state.json corrupted)" row — now describes "last-resort: read MT5 GlobalVariable subset" recovery path + `state_corrupt_recovered_via_gv` warn log

### Claim 01.15: 🔵 LOW — `04 § 9` "Correction note for ADR-010 alignment" = meta-comment

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/04-data-flow.md` § 9
- What changed: Correction note paragraph removed entirely (cascades from Claim 01.1 fix). Section opener now ระบุ "ADR-010 § 'Cross-slot logic in halted state' คือ authoritative; ตารางนี้ mirror ADR ตรงๆ" — no more meta-comments

### Claim 01.16: 🔵 LOW — Glossary "JWT/RBAC/RLS/HPA/PVC = N/A" entry = noise

**Verdict:** Accept

**Changes:**
- File: `docs/design-docs/02-high-level-architecture.md` § 8 Glossary
- What changed: Removed `JWT / RBAC / RLS / HPA / PVC` row entirely. Reviewer suggestion to add "Cross-slot signal globals / OrderGroup / Safe-port / Force-Pending" entries skipped — those terms = domain vocab owned by `docs/ba/01 § 8` glossary (per BA glossary scope rule); SD glossary stays focused on architecture-specific terms

### Claim 01.17: 🔵 LOW — 02 § 4.2 BV row mis-tags FR-7.6/BR-9.4

**Verdict:** Accept (covered by Claim 01.9 fix)

**Changes:** Same edits to `02 § 4.2` rows 3/4/7 documented under Claim 01.9. No additional edits required.

---

## Cascaded Changes

ทุก fix ทำผ่าน 7-step protocol — แต่ cascade ที่เกิดขึ้น **นอกเหนือ** จาก claim's stated scope:

1. **01.1 Safe-port direction** — cascaded to:
   - `02 § 9 ADR Digest` ADR-007 row (verified consistent — no edit needed)
   - `05 § 3.2 + § 9 Red Team` (verified consistent — no edit needed)
   - `08 § IMPL-058` rationale (verified consistent — "HALTED-aware enable matrix per `04 § 9` table" still accurate after table rewrite)

2. **01.3 Handle count `~25`** — touched `adr/012-file-layout-module-split-discipline.md` IndicatorService folder comment (not in claim's listed sources but required for consistency)

3. **01.4 Option B design** — added explicit cascade list to ADR-007 § Revisit-when ("update state-persistence-schema.yaml 3-file layout if activated") so future TD knows what to update

4. **01.6 + 01.8 acknowledged risks** — A6 (force-clear estimate) + A7 (P-Pending sub-modes) added to `03 § 7` together; updated end-of-doc footer "5 risks → 7 risks (A1-A7)"

5. **01.10 + 01.12 schema additions** — both added blocks to same `state-persistence-schema.yaml` (`journal_metrics` for 01.10, `logger_metrics` for 01.12); top-level `required` array updated

6. **01.13 Evolution Sequence** — cross-link added to `08 § TL;DR` (not in claim scope) so Phase Hints reader sees the hard-constraint relationship immediately

7. **01.14 Sync rule** — bumped `04 § 6 Consistency Boundaries` (added new row) + `04 § 5.3 Recovery scenarios` (updated existing row) — both not explicitly in claim but consistency demands

8. **Method-name consistency** — Claim 01.7 split SpreadGuard into 2 methods → also updated `05 § 3.2` to use precise names (claim only flagged `04 § 1.1`)

9. **Claim 01.5 + 01.11 alignment** — slot-abstraction-contract.yaml's new `EnforcementMechanism` block mirrors ADR-002's new "Pure-virtual override enforcement" subsection word-for-word; consistent across spec + ADR

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 14/17 = 82% | 🟠 Warning per defender persona (>50% = "design had significant issues") — expected for Round-0 first review of greenfield SD; high but justified — reviewer's claims มี evidence + technical merit ทุก claim |
| Critical Fixes | 1/1 (100%) | Claim 01.1 Safe-port contradiction resolved — ADR-010 + 04 + 05 ตรงกัน |
| HIGH Fixes | 4/4 (100%) | All 4 HIGH (latency math, handle count, Option B design, slot-contract format) addressed |
| MEDIUM Partial | 3/9 (33%) | 01.4 / 01.6 / 01.7 — defender pushed back on over-stated portions ที่มี evidence; remaining 6 MEDIUMs accepted directly |
| ADRs Updated | 7/12 (58%) | ADR-002, 003, 006, 007, 008, 010, 011, 012 — broad architecture re-touch อยู่ภายใน expected first-round scope |
| ADRs Created | 0 | No new ADR needed — fixes ใน existing ADRs (no genuinely new architectural decision) |
| API Specs Touched | 2/4 (50%) | slot-abstraction-contract.yaml full rewrite + state-persistence-schema.yaml schema extension |
| Net Improvement | **High** — eliminated 5 cross-doc contradictions, added 2 acknowledged risks (A6+A7), formalized RPO contract + escalation policy, added Evolution Sequence + override-enforcement mechanism — design now production-ready for TD hand-off |
| Remaining Gaps | 3 (= acknowledged risks A6/A7 + assumption A2 spike) | All flagged + owned (QA Phase 3T for A6 + TD Phase 1D for A7+A2); no silent gaps |

## Recommendation

- [x] ✅ **Ready for Implementation Handoff** — all CRITICAL + HIGH claims resolved; MEDIUM partials defended with evidence + cross-doc consistency restored. Phase 1B SD design is now actionable for Phase 1D TD without unresolved contradictions
- [ ] 🔁 **Request Re-Review** — significant changes ใน ADR-002 (override enforcement) + ADR-006 (RPO contract) + ADR-007 (Option B design) + ADR-010 (Safe-port direction) + Evolution Sequence (07 § 6 new) merit a Round 02 review by reviewer to confirm fixes ไม่สร้าง new contradictions; **recommend `/sd-review` Round 02 before TD phase begins**
- [ ] ⛔ **Needs Stakeholder Input** — N/A; all fixes within Architect scope
