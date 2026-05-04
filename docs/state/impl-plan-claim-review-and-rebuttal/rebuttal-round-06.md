# Implementation Plan Rebuttal Round 06

| Field | Value |
|-------|-------|
| **Round** | 06 |
| **Claim Review** | `claim-review-06.md` |
| **Date** | 2026-05-03 |
| **SKILLs** | andm-impl-plan-defender, code-review |
| **Trigger** | Plan Staleness Sentinel @ 48 closures since R05 (per top callout `Action ถัดไป`); first non-zero round since R04 (verify-only sweep, 2026-05-02) |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 7 |
| Partial | 0 |
| Rejected | 0 |
| Escalated | 0 |

**Files modified:**
- `docs/state/impl-plan.md` — ~12 edit clusters: 6 P1 [x] AC line rewordings + 14 closed-metadata/audit-log rewordings + P1 Phase Gate Drain row downgrade + TL;DR Active count recompute + TL;DR pending callout +IMPL-013 + Phase Status row P3 +IMPL-013 + Open Risks +R-6 + Override Log hard-stop annotation + 5 placeholder paths → `<TBD-...>` + 2 commit hash substitutions + Plan Staleness Sentinel last-review bump + new audit-log row + last-action bump
- `docs/state/deferred-ac-registry.md` — +6 P1 rows backfilled (IMPL-007/008/009/011/012/014; expires 2026-05-17)
- `docs/state/overview.md` — Impl Plan row appended R06 paragraph (status `Round 04 verify-only` → `+ R06 closure-discipline rebuttal closed`)

**Tasks split:** none (no AC-text splits required — chose Approach (A) "preserve `[x]`, strip 'deferred until IMPL-XXX' wording, cite registry row" per user-approved default)
**Phase reassignments:** none (Phase × Size matrix + Phase Dependency Graph unchanged)
**Registry rows added/closed:** 6 added (P1 IMPL-007/008/009/011/012/014); 0 moved to Resolved
**Escalations filed:** none

---

## Claim Responses

### Claim 06.1: 🔴 CRITICAL — Forbidden closure pattern hits (6 P1 [x] AC + 14 Closed metadata "deferred per <X> precedent")

**Verdict:** Accept

**Rationale:** Mechanical pre-scan grep `deferred per .* precedent` returned **20 hits** confirmed; CLAUDE.md § Empirical Closure Discipline + `deferred-ac-registry.md § PhoenicisNex-specific anti-pattern catalog` explicitly forbid the pattern. Engineer pre-authoring loophole degrades discipline ทุก rebuttal round (Shark CMS defect class). Both Type 1 (`[x]` AC + "deferred until IMPL-XXX") and Type 2 (`Closed: G2-G4 deferred per <task> precedent`) are CRITICAL per Workflow Phase 2.2.1.

**Changes Made (Type 1 — 6 P1 `[x]` AC lines):**
- File: `docs/state/impl-plan.md`, sections IMPL-007 (line 362), IMPL-008 (line 382), IMPL-009 (line 398), IMPL-011 (line 435), IMPL-012 (line 452), IMPL-014 (line 469)
- Approach (A) — preserve `[x]` mark (S-AC structural verification ผ่านจริง via grep + structural fixtures), strip "deferred until/per/to IMPL-XXX" wording, replace with explicit registry row citation: *"tracked in `deferred-ac-registry.md § Active` row IMPL-NNN expires 2026-05-17"*
- Evidence (sample updated text — IMPL-007 Refresh): *"Step 1 (aggregate zero-reset loop) shipped 2026-05-02; Step 2 (PositionsTotal() broker reconcile loop) tracked in `deferred-ac-registry.md § Active` row IMPL-007 expires 2026-05-17 (requires Orchestrator wiring + entry .mq5 + Strategy Tester run)"*
- Approach (A) chosen per user-approved default — less destructive to existing audit trail (no `[x]` mark removal); S-AC structural verification ผ่านจริงโดยที่ violation จริงคือ "editorial deferred wording" ไม่ใช่ closure decision

**Changes Made (Type 2 — 14 Closed metadata + audit-log narrative hits):**
- File: `docs/state/impl-plan.md`, multiple sections (lines 581 IMPL-040 / 654 IMPL-045 / 718 IMPL-049 / 735 IMPL-050 / 752 IMPL-051 / 906 IMPL-022 + 14 P3 audit-log rows 1593-1614)
- Reworded 3 unique forbidden-pattern variants:
  - `"deferred per IMPL-018+ header-only precedent"` → `"tracked in deferred-ac-registry.md § Active (registered to header-only .mqh rows; expires 2026-05-17)"`
  - `"deferred per IMPL-005/007/011/050/051 header-only precedent"` → cross-references P1 + P2 backfilled rows
  - `"deferred per IMPL-005/007/011 header-only precedent"` → cross-references P1 backfilled rows
  - + 2 audit-log variants (`"deferred per IMPL-052 header-only .mqh precedent"`, `"deferred per header-only .mqh precedent"`) reworded similarly
- **Verification:** `grep -cE "deferred per .* precedent"` post-fix = **0 hits** ✅

**Cascaded:** depends on Claim 06.2 backfill (6 P1 registry rows authored first to provide citation targets for AC rewordings).

---

### Claim 06.2: 🔴 CRITICAL — P1 Phase Gate "Deferred-AC drain ✅ empty for P1" contradicts 6 inline `[x]` + deferred AC closures

**Verdict:** Accept

**Rationale:** Registry `§ Active` table had **zero P1 rows** ever opened ขณะที่ 6 P1 tasks (IMPL-007/008/009/011/012/014) closed 2026-05-02 ด้วย inline `[x]` AC + "deferred until/per/to IMPL-XXX" wording. Drain check passed trivially because registry never received P1 entries; actual deferred work อยู่ฝังใน `[x]` task AC bodies. Phase Gate Hallucination defect class per CLAUDE.md §1 + § Glossary; `/deliver` block bypass risk per registry Rule #5.

**Changes Made:**
- File: `docs/state/deferred-ac-registry.md` § Active — appended **6 P1 rows** (IMPL-007/008/009/011/012/014) with same uniform expiry 2026-05-17 as existing P2/P3 batch; each row includes Owner=Kritsana, Opened=2026-05-03, Risk-if-missed paragraph, deferred_reason citing R06 backfill rationale
- File: `docs/state/impl-plan.md` § P1 Phase Gate row 239 — downgraded `[x] Deferred-AC drain ✅ empty for P1 ✅ 2026-05-02` → `[⚠️] Deferred-AC drain originally claimed empty ✅ 2026-05-02; retroactively amended post-R06 (2026-05-03) — 6 P1 rows backfilled; close on rolling basis as IMPL-053+ Orchestrator + entry .mq5 wire each downstream`. Audit trail preserved without re-opening Phase Gate (per defender SKILL § "preserves audit trail without re-opening Phase Gate")
- Cascaded: TL;DR Active count `5 P2 + 21 P3 = 26` → `6 P1 + 5 P2 + 20 P3 = 31` (Claim 06.4 cascade); registry expiry-tracking now includes all 6 P1 rows (`/impl-task` HALT trigger + `/deliver` block now enforce)

---

### Claim 06.3: 🟠 HIGH — Phase Status "P3 20/23" + TL;DR pending callout omits IMPL-013

**Verdict:** Accept (Option B)

**Rationale:** Disk verification: 19 per-slot input files exist (`ls MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_*.mqh | wc -l = 19`). IMPL-013 S-AC says "21 input files exist" — currently 19/21 (Slot_BI + Slot_P input files outstanding because IMPL-039 + IMPL-034 ยังไม่ landed). IMPL-013 ยัง legitimately `[ ]` ตามสถานะจริง; rolling-close pattern matches engineer convention "ship `Inputs_Slot_X.mqh` คู่กับ `Slot_X.mqh` ใน same commit". Option A (rolling-close 19/21 partial-tick) ไม่ถูกเพราะ S-AC text "21 input files" ไม่ตรง.

**Changes Made:**
- File: `docs/state/impl-plan.md` § TL;DR `Action ถัดไป` line 7 — pending callout updated: *"P3 pending after R06: IMPL-013 (per-slot inputs × 21; rolling-close — 19/21 input files shipped paired with each closed slot; remaining 2 ship paired with IMPL-034 + IMPL-039) + IMPL-034 (Slot_P) + IMPL-039 (Slot_BI G4 SL fix)"*
- File: `docs/state/impl-plan.md` § Phase Status Snapshot row P3 line 19 — appended explicit pending list: *"pending: IMPL-013 (per-slot inputs × 21; rolling-close 19/21 — Slot_BI + Slot_P input files outstanding) + IMPL-034 + IMPL-039"*
- IMPL-013 task body lines 792-810 unchanged (already correctly `[ ]` + correct dependency notes)

---

### Claim 06.4: 🟠 HIGH — TL;DR Active count "5 P2 + 21 P3 = 26" mismatches actual registry (5 P2 + 20 P3 = 25)

**Verdict:** Accept

**Rationale:** Registry actual count: 5 P2 (IMPL-043×2, IMPL-049×2, IMPL-052) + 20 P3 (IMPL-019/020/021/022×2/023..028/029/030/031/032/033/035/036/037/038) = **25 rows** confirmed via manual table walk. TL;DR text "21 P3" was off-by-one (counted IMPL-022 G4 attestation as separate slot row but listed 19 distinct slot IDs + 1 extra IMPL-022 row = 20 P3 total). After R06 backfill (Claim 06.2 cascade), total now **6 P1 + 5 P2 + 20 P3 = 31 Active rows**.

**Changes Made:**
- File: `docs/state/impl-plan.md` § TL;DR line 8 — rewrite: *"Deferred-AC Active: **6 P1 rows (backfilled 2026-05-03 post-R06 Claim 06.2)** + 5 P2 rows + 20 P3 E-AC deferrals = **31 Active rows total** · uniform expiry 2026-05-17 · all blocked on IMPL-053+ Orchestrator + entry .mq5 (IMPL-060)"*
- Defender 10-marker sweep convention extension: marker #8 TL;DR Active count vs `wc -l docs/state/deferred-ac-registry.md § Active` table actual count (recommended automated grep check ใน `/impl-task` Phase 5 closure)

---

### Claim 06.5: 🟠 HIGH — P2 Phase Gate Override timeline risk (5 P2 deferred-AC rows expire 2026-05-17 → 2026-05-31 hard-stop)

**Verdict:** Accept

**Rationale:** Timeline arithmetic ถูก: 5 P2 rows opened 2026-05-03 + 14d expiry = **2026-05-17** (first hard deadline) + single renewal +14d = **2026-05-31** (final hard-stop). 6 P4 tasks (IMPL-053..060; M+M+S+XS+XS+M ≈ 28 days nominal) ต้องลงให้เสร็จก่อน P2 Gate retroactive close + Tier 1.5 walk produces evidence. P3 ยังเหลือ 3 task (IMPL-013/034/039 — IMPL-039 HIGH RISK G4 fix). Override row well-formed structurally but timeline arithmetic = fragile chain. After R06 backfill, 6 additional P1 rows also expire 2026-05-17 (compounds renewal pressure).

**Changes Made:**
- File: `docs/state/impl-plan.md` § Open Risks — appended new R-6: *"P2 Phase Gate retroactive-close timeline risk — Phase Gate Override Log row defers P2 close until IMPL-018+ ✅ + IMPL-053..060 chain (6 P4 tasks) lands + Tier 1.5 walk + drain 5 P2 deferred-AC rows... Hard-stop escalation: ถ้า P2/P1 rows hit final renewal expiry 2026-05-31 without retroactive close → escalate via /backtrack sd to revisit P2 boundary."*
- File: `docs/state/impl-plan.md` § Phase Gate Override Log row 1571 — appended hard-stop annotation: *"Hard-stop: if 5 P2 rows hit final renewal expiry 2026-05-31 without retroactive close → escalate via /backtrack sd to revisit P2 boundary (per Open Risk R-6 added 2026-05-03 in rebuttal-round-06 Claim 06.5)"*

---

### Claim 06.6: 🟡 MEDIUM — Placeholder evidence paths "2026-MM-DD-phase{2,4}-{evidence,exploratory-walk}.md" risk being committed unsubstituted

**Verdict:** Accept

**Rationale:** 5 placeholder paths still in plan (P2 Empirical Demo line 554 + Tier 1.5 Walk 555 + P4 Empirical Demo 1251 + Tier 1.5 Walk 1252 + Override Log row 1571). Same defect class as rebuttal-round-03 stale "review pending" markers — engineer might forget to substitute concrete date at Phase Gate close, leaving literal `2026-MM-DD-` in `[x]` row → `/next` Check 6 might surface "evidence file does not exist" warning or validate placeholder as real path (file system race condition).

**Changes Made:**
- File: `docs/state/impl-plan.md` lines 554, 555, 1251, 1252, 1571 — replaced 5 placeholder paths with `<TBD-phaseN-...>` non-date markers + parenthetical instruction *"(placeholder — engineer substitutes concrete `<YYYYMMDD>-phaseN-evidence.md` filename at Phase Gate close per defender 10-marker sweep)"*
- Verification: `grep -cE "2026-MM-DD-phase[24]"` post-fix = **0 hits** ✅
- Defender 10-marker sweep convention extension: marker #9 Phase Gate evidence/walk placeholder paths — converts at-review-time scan into per-closure check

---

### Claim 06.7: 🟡 MEDIUM — "commit pending" stale on IMPL-018 + IMPL-052 despite real commits in git log

**Verdict:** Accept

**Rationale:** `git log --grep` confirmed: IMPL-018 = `b1cbc54` ([feat:ea] IMPL-018 — CSlotBase abstract + SlotRegistry ValidateTopo Evolution E2); IMPL-052 = `01b66c1` ([ea] IMPL-052 — implement core/EAState.mqh machine). Other closed tasks use pattern `(commit fe78218)` / `(commit 1ece5ae)` so substitution restores audit-trail consistency. Lower severity than 06.4/06.6 because git is authoritative SoT for commit hashes; plan metadata is derived. ไม่ block downstream tasks.

**Changes Made:**
- File: `docs/state/impl-plan.md` IMPL-018 Closed line 827 — substituted `(commit pending)` → `(commit b1cbc54)`
- File: `docs/state/impl-plan.md` IMPL-052 Closed line 770 — substituted `(commit pending)` → `(commit 01b66c1)`
- Defender 10-marker sweep convention extension: marker #10 `Closed: (commit pending)` substitution check

---

## Cascaded Changes

ส่วน fix ทั้ง 7 claim cascade ไปที่ readiness markers + sibling state files:

1. **TL;DR `Last updated` last-action line 9** — bumped `Code Review Round 05 + Fix Round 05 applied` → `rebuttal-round-06.md closed (claim-review-06: 7/7 Accept; ...)`. Prior action preserved in suffix.
2. **Plan Staleness Sentinel § lines 1701-1705** — `Last review on` 2026-05-02 → 2026-05-03 (claim-review-06); `Closures since last review` 48 → 0 (R06 closed); 7-marker sweep convention extended to 10-marker (markers #8/#9/#10 documented).
3. **Mid-Phase Audit Log § (new row appended after line 1615)** — registers R06 closure with full 7-claim summary + cross-state checks.
4. **`docs/state/overview.md § Impl Plan row 19`** — status `R04 verify-only sweep` → `+ R06 closure-discipline rebuttal closed`; Last Updated 2026-05-02 → 2026-05-03; appended R06 paragraph documenting 7-claim summary, 6-round convergence trajectory (R01=7 → R02=3 → R03=3 → R04=0 → R05 skipped → **R06=7 regression**), recommendation to add forbidden-pattern grep ใน `/impl-task` Phase 5 closure.
5. **Action ถัดไป line 7** — pivoted `/impl-plan-review all` from pending checked-box to **R06 closed** ✅ marker; pending callout extended to include IMPL-013 + IMPL-034 + IMPL-039.
6. **`docs/state/deferred-ac-registry.md § Active`** — table grew from 25 rows to 31 rows (5 P2 + 20 P3 → 6 P1 + 5 P2 + 20 P3); Resolved table still empty.

**Cross-state checks post-fix:**
- Forbidden-pattern grep `deferred per .* precedent|deferred to operator-runtime|deferred to post-launch|structurally complete.*deferred|live verification deferred` = **0 hits** ✅ (down from 20)
- Forward reference scan `P_n → P_m, m > n` = **0 edges** ✅ (no phase reassignments made)
- Phase × Size matrix unchanged: XS=7 / S=23 / M=29 / L=8 / XL=1 = 68 total
- Phase Dependency Graph (Mermaid) unchanged
- SD Hint Alignment audit trail tally unchanged: 67 ✅ Honored / 1 ⚠️ Diverged (IMPL-013) / 0 🔴 Violation / 0 ◻️ No-hint
- Silent Copy Detector unchanged: H=68, A=67, D=1, V=0, N=0 (D≠0; not triggered)
- Placeholder evidence paths grep `2026-MM-DD-phase[24]` = **0 hits** ✅
- Registry hygiene: 6 new P1 rows have owner=Kritsana + expiry 2026-05-17 (≤14d from Opened 2026-05-03) + risk-if-missed paragraph each ✅
- IMPL-018 / IMPL-052 commit hashes: substituted with real `b1cbc54` / `01b66c1` (validated against `git log --grep`) ✅

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (7/7) | ทุก finding ที่ reviewer raise valid + actionable; sustained Accept rate × 6 rounds = signal ว่า reviewer + defender alignment สูง (no Partial/Reject hedging) |
| Critical Fixes | 2 (06.1 + 06.2) | First CRITICAL surface since R01-cumulative; cause = empirical-closure-discipline pattern leaked during 33-task closure burst between R04 (2026-05-02) และ R06 (2026-05-03) — engineer-side `/impl-task` Phase 5 closure ขาด forbidden-pattern grep ก่อนปิด task |
| Tasks Split | 0 | Approach (A) "preserve `[x]` + cite registry row" chosen per user — less destructive vs split. AC-text rewordings ไม่ disturb existing audit trail |
| Phase Reassignments | 0 | No phase reassignments — Phase × Size matrix + Phase Dependency Graph + SD Hint Alignment tally all unchanged |
| Registry Rows Added | 6 (all P1) | First-ever P1 entries in registry; backfill restores reconciliation between Phase Gate Drain check + actual deferred work; `/deliver` block + `/impl-task` HALT trigger now enforce |
| Net Improvement | Closure-discipline restored + state reconciliation restored + 10-marker sweep convention codified — single rebuttal round resolved 6 propagation defect classes (forbidden-pattern + Phase Gate Hallucination + IMPL-013 omission + Active count off-by-one + placeholder paths + commit-hash substitution) | |
| Escalations | 0 | ไม่มี Evolution Sequence violation request หรือ work-inventory expansion request — ทุก fix อยู่ใน rebuttal scope (no SD/TD/ADR/BA edits) |
| Remaining Gaps | 0 | All 7 claims resolved with explicit fix evidence; defender 10-marker sweep convention codified for future rounds |

## Recommendation

- [x] ✅ **Ready for Implementation Execution** — all CRITICAL/HIGH claims resolved with verifiable mechanical evidence (forbidden-pattern grep 0; registry actual count 31; IMPL-013 explicit in pending list; placeholder paths 0; commit hashes substituted)
- [ ] 🔁 Request Re-Review — not necessary; reviewer's 10/10 dimension scan + mechanical pre-scans give high confidence ว่า no remaining gaps
- [ ] ⛔ Needs Stakeholder Input — no escalations

**Suggested process improvement** (out-of-scope for this rebuttal — flagged as recommendation only):
- Add `grep -cE "deferred per .* precedent|deferred to operator-runtime|deferred to post-launch|structurally complete.*deferred|live verification deferred"` step to `/impl-task` Phase 5 Closure as new mechanical gate — converts at-review-time scan into **per-closure** scan; would have caught 33-task burst regression at task-3 instead of task-33. This is engineer-side workflow change (not plan content) — flagged here for engineer to consider (not implemented in this rebuttal).

— Implementation Plan Defender (Constructive Defense)
2026-05-03
