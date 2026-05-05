# Code Review Round 15

| Field | Value |
|-------|-------|
| **Round** | 15 |
| **Target** | `all` — focused on post-fix-round-14 deltas: (a) FIX-001 source (`Inputs_Slot_S.mqh:33` + `Slot_S.mqh:203`), (b) FIX-002 source (`RiskManager.mqh:256-262`), (c) Tier 1.5 walk batch-2 evidence (`docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` + `abridged-tester-log.txt`), (d) walk-driven state propagation (5 state files: `impl-plan.md` TL;DR + Phase Status + Open Risks + Next Best Action; `deferred-ac-registry.md` 4 strikethrough'd Active rows + 4 new Resolved entries; `overview.md` Impl Tasks row; `current_handoff.md` prepended closure; `nfr-3.1-atomic-write-result.md § 5` placeholder→filled), (e) IMPL-064 sidecar `nfr-3.1-atomic-write-result.json`. Cumulative reviewed surface: ~9,570 LOC (R01..R14). |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~3 LOC source delta (FIX-001 + FIX-002 — 1 input add + 1 caller-arg edit + 1 log-level demote) + ~10,732 bytes walk artifact (walk-summary.md + abridged log) + ~1,030 bytes JSON sidecar + 5 state file edits + § 5 Result Table fill in NFR-3.1 doc. Cumulative reviewed surface: ~9,570 LOC (R01..R14). Self-review surface — engineer + reviewer is the same operator; adversarial sweep includes own walk batch-2 deliverables. |
| **Plan Staleness Sentinel** | TL;DR-stated 7 closures since R07; **R15 raises Finding 15.3 LOW that this should be 6** (walk drain ≠ task closure per workflow.md gate #4 + fix-round-10 precedent "fix-rounds are review-loop artifacts, not task closures"). Below 10-closure threshold either way ✅. Last `/impl-plan-review` was R07 (2026-05-04). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 1 |
| MEDIUM   | 1 |
| LOW      | 2 |
| **Total**| **4** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | FIX-001 + FIX-002 both touch lot-sizing path only; no new `#import` / `WebRequest` / DLL / file-system surface. Walk batch-2 harness writes to existing `nfr-3.1-atomic-write-result.json` sidecar (not committed by tracking; harness owns the write). No credential / connection-string introduction. Symbol whitelist + atomic-write contract intact. |
| 2 | Business Logic Correctness | ⚠️ Finding | **Finding 15.1 HIGH** — `InpSPercentTp` (default 10.0, range {5, 10, 15} per BR-4.1) added to `Inputs_Slot_S.mqh` by FIX-001, but no validation exists in `BootstrapValidator` or `Slot_S::Init` to enforce the discrete set membership. Operator who tweaks the input to e.g. `8.0` or `12.0` via MT5 input dialog re-triggers the EXACT FIX-001 defect class (per-tick `[ERROR][ev=s_pct_tp_invalid]` + zero-lot Slot S orders). Defense-in-depth missing. |
| 3 | Error Handling | ✅ Pass | FIX-002 demotion `Warn → Debug` preserves the diagnostic message verbatim; investigation flow (`LOG_DEBUG`) keeps full forensic visibility per inline comment at lines 260-262. RiskManager `_ComputeLotForS` still emits `[ERROR][ev=s_pct_tp_invalid]` on invalid `percent_tp` (not silenced by the FIX) — operator-driven regression would still surface in logs at INFO level. |
| 4 | Performance | ✅ Pass | Walk batch-2 G3 wall-clock 0:09:05 vs batch-1 0:06:50 (+33%) is system-load variance, not regression — same Tester deterministic seed; raw log volume −64% (629 MB → 224 MB) confirms FIX-001/FIX-002 per-tick string churn correctly eliminated. Atomic-write kill harness 34.3s wall-clock (≈340ms/trial) well within budget. |
| 5 | Over-Engineering | ✅ Pass | FIX-001 = 1 input + 1 caller arg = minimum-viable correction. FIX-002 = 1 log-level swap = minimum-viable demotion. Walk-summary.md content lengths reasonable for evidence weight (~7 KB walk-summary + 6.5 KB abridged log + 1 KB sidecar). |
| 6 | Cross-Service Consistency | ⚠️ Finding | **Finding 15.2 MEDIUM** — Walk batch-2 explicitly identifies log-assertion partial drains for IMPL-007 (`magics registered: 17` captured) + IMPL-049 (5 `enter_pending` + 4 `transition_executed` events fired for C/M/T/Q/P) + IMPL-052 (`state_corrupt_starting_fresh` first-run path drained). The walk-summary correctly classifies these as "partial drain — keeps Active", but the registry's IMPL-007 / IMPL-049 / IMPL-052 narrative was NOT updated to (a) reference the new walk artifact as live-evidence-of-log-assertion-clause, (b) note that only the `[db-inspect]` / `[boot-cold]` / `[contract-roundtrip]` half remains pending, (c) update the "Deferred reason" column to reflect the partial-drain status. Drift between walk-summary intent and registry state. |
| 7 | Test Coverage Gaps | ✅ Pass | No new test code in scope; walk batch-2 evidence IS the runtime proof. Dim #14 R14 SelfTest wiring gaps (`Spike_CircuitBreaker.mq5` + `RunDomainSelfTests` umbrella) closed by fix-round-14 — verified via `Spike_CircuitBreaker.ex5` + `Spike_Orchestrator.ex5` newly produced (mtime 2026-05-04 19:39). |
| 8 | Architecture Compliance | ✅ Pass | RiskManager surface preserves "lot sizing only" contract per `services/RiskManager.mqh:34` ("All lot sizing is channelled here — slots ห้าม call CTrade ตรง"). FIX-002 doesn't introduce any CTrade calls. ADR-007 atomic-write contract verified empirically by IMPL-064 100/100 PASS — Option A (write-temp + NTFS rename) survives live `Stop-Process -Force` mid-write kill. ADR-002 composition root unchanged. |
| 9 | Technical Design Compliance | ✅ Pass | NFR-3.1 § 5 Result Table fill matches sidecar JSON exactly (parse_pass=100, parse_fail=0, state_missing_*=0, startup_timeout=0, failed_fast=false, Verdict=PASS). NFR-3.1 hard requirement (`parse_fail == 0`) empirically satisfied. Walk artifact paths cited in registry Resolved table all exist on disk. |
| 10 | Test Code Quality | ✅ Pass | `atomic_write_kill_100.ps1` doc fixes from R14 § 14.4 verified active in this run — the param-binding error trap that R14 anticipated did NOT block this session's `-Trials 100` invocation; harness ran clean. |
| 11 | Empirical AC Closure | ⚠️ Finding (advisory) | Dim #11 verification PASSES for all 4 newly-resolved rows (IMPL-009 / IMPL-FIX-001 / IMPL-FIX-002 / IMPL-064): walk artifact exists ✅, evidence-kind matches `[log-assertion]` / `[boot-cold]+[file-blob-check]` per AC declaration ✅, no forbidden closure pattern ("deferred to operator-runtime" / "deferred per <task> precedent" / "structurally complete deferred" / "live verification deferred") in `impl-plan.md` (gate #1 grep = 0 hits ✅). Forbidden-pattern grep on `docs/state/impl-plan.md` clean. ALL 4 Resolved row cite paths verified to exist on disk (`tier-1.5-walk-2026-05-04/` + `tier-1.5-walk-2026-05-05/` + sidecar JSON). **Advisory:** see Finding 15.2 for partial-drain registry narrative gap. |
| 12 | Functional Walk (PhoenicisNex Tier 1.5) | ✅ Walk batch-2 executed | `bootstrap_smoke.ini` + `atomic_write_kill_100.ps1 -Trials 100` both completed successfully today (2026-05-05). Walk artifact at `_session-handoff/tier-1.5-walk-2026-05-05/` includes execution metrics + per-row drain evidence + verdict. ≤14d validity → expires 2026-05-19. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; PowerShell harness reads `origin.txt` (already validated) + `.ini` paths (committed); no env-var / secret consumer. `[config-audit]` not triggered. |

---

## Findings

### Finding 15.1: 🟠 HIGH — `InpSPercentTp` ที่ FIX-001 เพิ่มเข้ามาไม่มี input validation; operator สามารถ set ค่านอก {5, 10, 15} ผ่าน MT5 input dialog แล้ว re-trigger FIX-001 defect class ทุกตัว (per-tick `[ERROR][ev=s_pct_tp_invalid]` + zero-lot Slot S orders) — defense-in-depth ขาด

**Location:**
- File: `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_S.mqh`, Line: 33 (input declaration without validation)
- File: `MQL5/Experts/PhoenicisNex/services/RiskManager.mqh`, Lines: 402-415 (`_ComputeLotForS` invalid-percent_tp branch)
- File: `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh` (no validation function added; grep confirms `InpSPercentTp` absent from this file)
- Reference: `docs/code-review/review-round-14.md` clean for this surface (FIX-001 was applied AFTER R12 + before R13/R14; R15 is the first review of this code path); Tier 1.5 walk batch-1 finding 2026-05-04 originating evidence
- Service: ea (P3 IMPL-036 follow-up FIX-001)

**Code:**
```mql5
// inputs/Inputs_Slot_S.mqh:33  (FIX-001 commit `4110a78` — added)
input double InpSPercentTp           = 10.0;    // percent_tp ∈ {5, 10, 15} per BR-4.1; default 10 per CodeWiki §3.S
```

```mql5
// services/RiskManager.mqh:402-415 (the brittle consumer)
double CRiskManager::_ComputeLotForS(double percent_tp)
{
   double factor = 0.0;
   if(MathAbs(percent_tp - 5.0)  < 0.001) factor = 0.05;
   else if(MathAbs(percent_tp - 10.0) < 0.001) factor = 0.10;
   else if(MathAbs(percent_tp - 15.0) < 0.001) factor = 0.15;
   else
     {
      if(m_logger != NULL)
         m_logger.Error("RiskManager", "s_pct_tp_invalid", MAGIC_S,
                        StringFormat("percent_tp=%.4f not in {5,10,15}; "
                                     "S lot = 0.0 (no order)", percent_tp));
      return 0.0;          // ← regression of FIX-001 defect class
     }
   ...
}
```

```bash
# Verification — InpSPercentTp absent from BootstrapValidator
$ grep -n "InpSPercentTp" MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh
(no output — InpSPercentTp not validated at boot)
```

**Problem:**
FIX-001 (commit `4110a78`) ที่ปิด HIGH defect ของ Tier 1.5 walk batch-1 ทำงานบน assumption ว่า operator จะใช้ default value 10.0 ตลอด — ซึ่งเป็นค่าหนึ่งใน valid set {5, 10, 15} per BR-4.1. แต่ `input double InpSPercentTp` ใน MQL5 = exposed ใน MT5 input dialog ตอน chart attach + ใน Strategy Tester input panel ตอน optimization sweep. Operator (รวมถึง engineer ที่อ่าน docs ผิด หรือ optimization sweep ที่ random-step ค่าด้วย Stepping) สามารถ set ค่าเป็น `8.0` (intuition: "8% TP") หรือ `12.0` ("between 10 and 15") หรือ `7.5` (mid-range) — ทุกค่านี้จะ:

1. Pass MQL5 type check (just a `double`)
2. Compile pass (G1 ผ่าน — no static check enforces range)
3. Run-time hit `_ComputeLotForS` → `MathAbs(percent_tp - X) < 0.001` ทั้ง 3 case fail → factor = 0.0 → return 0.0
4. Per tick emit `[ERROR][ev=s_pct_tp_invalid]` + Slot S lot=0 (no order)
5. **Identical regression** ของ FIX-001 defect class — กลับมา DDoS-level ERROR spam + Slot S non-functional

ที่สำคัญ — IMPL-017 (Strategy Tester optimization sweep) เป็น P4 task ที่ใช้ optimization mode ซึ่ง intent = sweep input values. ถ้า operator configure sweep range เป็น `5..15` step `1.0` (เพื่อทดลองว่า X% TP ที่ optimal), 11 จาก 11 sweep values จะ regress FIX-001 (เฉพาะ 5/10/15 = 3 values ที่ valid; 8 invalid values ทำให้ Slot S non-functional ตลอด sweep run) — sweep result = noise.

`.claude/rules/ea.md § Naming Conventions` ระบุ `Inputs: Inp<SlotId><Param> with group="Slot <X>" annotation (NFR-6.3)` — naming ถูก ✅. แต่ rules ไม่ได้ enforce validation. NFR-7.6 (FR-7.6 indicator handle 100% validation) เป็น precedent: structural-only declarations ที่ caller-side ทำ validation. ที่นี่ caller-side validation ขาด.

ที่ `BootstrapValidator.mqh` (ทำหน้าที่ validation gate ที่ OnInit step 1) — ไม่มี method ที่ validate `InpSPercentTp ∈ {5, 10, 15}`. `ValidateInputs` (4 public methods) ไม่ครอบ. `RunDomainSelfTests` (R14 § 14.3 fix) เป็น domain-level SelfTest umbrella, ไม่ใช่ input validation umbrella.

**Why This Matters:**
3am-operator scenario: operator พบ Slot S เปิด zero orders ใน production → ดู log, เห็น `s_pct_tp_invalid percent_tp=8.0 not in {5,10,15}` → ตามไปดู input → "อ้าว ตั้ง 8 เพราะคิดว่า %TP" → fix ตอนนั้น = 1-2 hour downtime + missed signals. แย่กว่า: ถ้า operator ไม่ดู log (เพราะ DEBUG-demoted ที่ FIX-002 ลด WARN noise), ก็จะ silent until เลขขาดทุนเริ่มผิดปกติ.

แย่ที่สุด: IMPL-017 sweep run ใช้ wall-clock ~5-30+ ชม.; ถ้า sweep range รวมค่า invalid, ทั้ง sweep result = invalid → 30 hours ของ Tester compute หายไป + operator ต้อง recompute เมื่อรู้ว่า range ผิด. NFR-1.6 + NFR-1.1 acceptance signals จะถูก contaminated.

แย่ที่สุด-2: IMPL-062 / IMPL-063 (Bucket A/B regression run) เป็น 5-yr Tester runs ที่ใช้ Strategy Tester. ถ้า operator setup invalid `InpSPercentTp` ใน .ini fixture (เช่น copy-paste จาก dev test ที่ใช้ 8.0 เพื่อ debug) → 5-yr regression run = invalid → Bucket A/B drift attestation = noise. NFR-1.1 acceptance signal = uncapturable.

defect class นี้คือ exact **Empirical Closure Discipline** trap (Dim #11 motivating defect) — FIX-001 closure narrative ระบุ "S entries fire with non-zero lot post-fix" + walk batch-2 เห็น 216,671 SlotS entry_signal events with `lot=2.90`, แต่ lot=2.90 เกิดเฉพาะตอน `InpSPercentTp = 10.0` (default + walk batch-2 ใช้ default). Walk batch-2 walked the happy path; defense-in-depth สำหรับ off-default operator action ไม่ได้ verify.

**Suggested Fix:**
2-part fix mirroring R14 § 14.3 pattern (BootstrapValidator umbrella + honest comment in input file):

**Part 1 — add `ValidateSlotInputs()` method to BootstrapValidator** (~25 LOC):

```mql5
// core/BootstrapValidator.mqh — add 5th umbrella method, called from Orchestrator::OnInit Phase B step 1.5
// Verifies all per-slot input value ranges per BR-4.1 / CodeWiki §3.X.
bool ValidateSlotInputs()
{
   bool all_pass = true;

   // FIX-001 defense — InpSPercentTp must be one of {5, 10, 15} per BR-4.1
   if(MathAbs(InpSPercentTp - 5.0)  >= 0.001 &&
      MathAbs(InpSPercentTp - 10.0) >= 0.001 &&
      MathAbs(InpSPercentTp - 15.0) >= 0.001)
     {
      m_logger.ErrorBypassThrottle("system", "input_validation_fail", 0,
         StringFormat("InpSPercentTp=%.4f outside valid set {5,10,15} per BR-4.1; "
                      "Slot S would emit s_pct_tp_invalid every tick + non-functional",
                      InpSPercentTp));
      all_pass = false;
     }

   // (Future: extend to other slot inputs with discrete-set semantics —
   //  e.g., InpKMode ∈ {NONE, AGGRESSIVE, DEFENSIVE} — when those land.)

   return all_pass;
}
```

Wire from `core/Orchestrator::OnInit` Phase B (between current ValidateSymbol and ValidateSlotRegistry calls):
```mql5
   if(!m_validator.ValidateSlotInputs()) return INIT_FAILED;
```

**Part 2 — update `Inputs_Slot_S.mqh:33` comment to be self-documenting about the discrete set + reference the validator** (~1 LOC change):

```mql5
input double InpSPercentTp = 10.0;    // percent_tp MUST be one of {5, 10, 15} per BR-4.1
                                       // ; BootstrapValidator::ValidateSlotInputs fails INIT_FAILED on violation
                                       // ; default 10 per CodeWiki §3.S
```

Optional Part 3 (alternative — auto-snap to nearest valid value):
```mql5
// In Slot_S::Init(): snap InpSPercentTp to nearest valid value with Warn
double effective_pct_tp = ...; // snap logic here
```

แต่ Part 3 ไม่แนะนำ — masking operator typo ด้วย silent snap ทำให้ debug ยากกว่า fail-fast.

**Level of Effort:** Low (~25 LOC validator + 1 wire site + 1 comment edit; G1 + spike SelfTest case for invalid percent_tp boundary).

---

### Finding 15.2: 🟡 MEDIUM — Walk batch-2 ระบุ "partial drain — log-assertion side captured" สำหรับ IMPL-007 + IMPL-049 + IMPL-052 ใน walk-summary.md narrative แต่ `deferred-ac-registry.md` Active table ของ 3 rows นี้ ยังคง original "Deferred reason" + "Risk if missed" wording ไม่ได้ update เพื่อ reference walk artifact หรือ note partial-drain status — registry state drift จาก walk-summary intent

**Location:**
- File: `docs/state/deferred-ac-registry.md`, Active table rows for IMPL-007 (line 15), IMPL-049 (lines 24-25 — both rows), IMPL-052 (line 23)
- File: `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md`, Lines 81-87 ("Partially drained" section)
- Service: ea (state reconciliation discipline)

**Code:**
```markdown
# walk-summary.md:81-87 (claims partial drain for 3 rows)

## ⚠️ Rows NOT drained (gating remains)

[... non-drainable rows ...]

# walk-summary.md:69-79 — actual partial drain claims
### IMPL-007 (P1 PortfolioState OnInit register-all + 17-magic invariant)
**AC text:** "OnInit smoke → Logger Debug 'magics registered: 17' `[log-assertion]`"
**Drained:** line 252 `[ev=portfolio_registered][magic=0] magics registered: 17` ✅
- `[db-inspect]` half (`GetByMagic(MAGIC_X).total_profit` matches MT5 native) — partially drained: ...
```

```markdown
# deferred-ac-registry.md:15 (current state — IMPL-007 row, NO partial-drain narrative)
| P1 | IMPL-007 | OnInit smoke → Logger Debug "magics registered: 17" `[log-assertion]`; `Refresh()` Step 2 ... |
log-assertion + db-inspect | Backfilled retroactively post-R06 — task closed 2026-05-02 with inline `[x]` AC + "deferred to IMPL-053+ + IMPL-018+" wording (forbidden closure pattern fixed in rebuttal-round-06 Claim 06.1). Step 1 (aggregate zero-reset loop) shipped; Step 2 broker reconcile + live Logger Debug emission require Orchestrator Init→RegisterAll wiring (IMPL-053+) + entry .mq5 + Strategy Tester run | Kritsana | 2026-05-03 | 2026-05-17 | ... |
```

**Problem:**
Walk batch-2 closure produces structured evidence per-row:
- **Fully drained** (4 rows: IMPL-009 / IMPL-FIX-001 / IMPL-FIX-002 / IMPL-064) → strikethrough'd in Active + appended to Resolved table ✅
- **Partially drained** (3 rows: IMPL-007 / IMPL-049 / IMPL-052) → walk-summary correctly notes the log-assertion clause is now empirically captured but the second clause (`[db-inspect]` / `[boot-cold]` / `[contract-roundtrip]`) still requires real broker fills (gated on IMPL-062 5-yr regression chain).
- **Not drained** (NULL drainable from this walk) → flagged in walk-summary § "Rows NOT drained".

The fully-drained handling is correct. The partially-drained rows have a state drift gap:

1. **IMPL-007** (line 15): Active row narrative still says "Step 2 broker reconcile + live Logger Debug emission require Orchestrator Init→RegisterAll wiring (IMPL-053+) + entry .mq5 + Strategy Tester run" — but IMPL-053..060 ALL closed AND a Strategy Tester run was just executed AND `magics registered: 17` was empirically captured. The narrative is stale.
2. **IMPL-049** (lines 24-25, two rows): Both Active rows still cite "Same precedent as IMPL-052: SelfTest Case 6/7 exercises..." without referencing walk batch-2's 5 enter_pending + 4 transition_executed events captured in abridged-tester-log.txt as evidence of `[ev=enter_pending][machine=C|M|T|Q|P]` + `[ev=transition_executed][machine=C|M|T|Q]`.
3. **IMPL-052** (line 23): Active row narrative still says "Live `terminal64.exe` headless tester invocation could not attach in current environment" — outdated; the bootstrap_smoke.ini Tester DID attach successfully today + emitted `[ev=state_corrupt_starting_fresh]` (the very signal IMPL-052 AC partially asks for). Narrative is wrong-by-fact.

State Reconciliation Discipline per CLAUDE.md §6 + Glossary § State Single Source of Truth:
> "ทุกครั้งที่ปิด task / fix-round / impl-plan rebuttal ต้อง update **ทั้ง 3 ชั้น**: (1) `impl-plan.md` (primary SoT), (2) `overview.md` (derived), (3) `{module}/handoff.md` + `_session-handoff/<task-id>-evidence-*` (transient pointer + artifact). ห้าม update เพียงไฟล์เดียว — drift ระหว่างไฟล์ทำให้ `/next` รายงานผิด, `/impl-task` หยิบ task ผิด, status agents hallucinate phase complete"

The walk-summary IS the artifact (✅), the impl-plan TL;DR mentions partial drains generally (✅), but the registry rows themselves (which `/impl-task` HALT logic + `/deliver` block + `/impl-review` Dim #11 inspect) still have stale narratives that don't reflect partial-drain status. A future status agent reading IMPL-007 row will see "Step 2 ... requires IMPL-053+ + entry .mq5" and miss that those prereqs are now met + the log-assertion clause has empirical evidence.

This is also a Dim #11 EAC-closure trace gap: the registry row is the load-bearing pointer for E-AC closure verification. If the Active row narrative is stale, future R-cycles (e.g., R16) will Dim #11-flag the row as "still pending all preconditions" when in fact the log-assertion preconditions are now satisfied.

**Why This Matters:**
Phase Gate close (P2 retroactive close per impl-plan TL;DR) blocks on "drain N P2 deferred-AC rows". If the registry rows say "needs IMPL-053+ + entry .mq5" (= pre-walk-batch-2 narrative), a future operator running `/next` or `/impl-task` will see "still blocked on prereqs done last week" + may not realize the partial-drain progress. The closure path becomes opaque.

Operator scenario: 1 week from now, operator runs `/next` to plan IMPL-062 start. `/next` reads registry rows. IMPL-007/049/052 Active rows look like they need a separate operator session to drain Logger emission paths — but actually walk batch-2 already captured those. Operator either (a) runs a redundant Tier 1.5 walk session, OR (b) trusts the registry and starts IMPL-062 without realizing the partial-drain progress could shorten the path. Either way, the walk-summary artifact's value is partially lost because the registry didn't propagate it.

**Suggested Fix:**
Update 3 Active rows in `docs/state/deferred-ac-registry.md` with annotation block at end of "Deferred reason" column, mirroring the format used for IMPL-022 G4 attestation row (which already has a "Partially resolved 2026-05-04" annotation):

**IMPL-007** Deferred reason — append:
```
**Partially resolved 2026-05-05 via Tier 1.5 walk batch-2** — log-assertion clause empirically captured: `_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md` cites Tester log line at 2024.01.02 00:00:00 emitting `[Phoenicis][slot=portfolio][ev=portfolio_registered][magic=0] magics registered: 17`. Remaining `[db-inspect]` half (`GetByMagic(MAGIC_X).total_profit` matches MT5 native broker reconcile) requires real position flow → still gated on IMPL-062 5-yr regression with RiskManager::OpenOrder wired. Row stays Active until db-inspect clause drained; Active handles partial-drain correctly per Dim #11.
```

**IMPL-049** (both rows) Deferred reason — append similar annotations citing the 5 enter_pending + 4 transition_executed events; note that boot-cold half + force-clear journal record schema half remain pending IMPL-062.

**IMPL-052** Deferred reason — replace stale "Live `terminal64.exe` headless tester invocation could not attach in current environment" with:
```
**Partially resolved 2026-05-05 via Tier 1.5 walk batch-2** — first-run path empirically captured: `[ev=state_corrupt_starting_fresh]` fired at OnInit when `state.json` absent (per walk artifact line — abridged Tester log Init phase). Remaining HALTED-restart specific path (state.json contains state=HALTED + portfolio_count=0 → restart resolves to RUNNING + reset reason) requires synthetic state.json fixture; still gated on IMPL-062 / dedicated synthetic boot-cold spike. Row stays Active until HALTED-restart clause drained.
```

LoE: Low (~3 narrative annotations × 50 LOC each = ~150 LOC of registry text edits; no source code touched; G1 not affected).

**Level of Effort:** Low

---

### Finding 15.3: 🔵 LOW — Plan Staleness Sentinel ใน `impl-plan.md` TL;DR เพิ่มจาก 6 → 7 closures by counting Tier 1.5 walk batch-2 drain เป็น `+1 walk drain` — ขัด workflow.md gate #4 + fix-round-10 precedent ("fix-rounds are review-loop artifacts, not task closures") เพราะ walk drains เป็น E-AC residue cleanup ของ task ที่ already-closed-with-`[x]` ไม่ใช่ task closure ใหม่; ทำให้ Sentinel inflated และ inline narrative contradiction (TL;DR header = "7" + inline detail row = "6")

**Location:**
- File: `docs/state/impl-plan.md`, Line: 9 (TL;DR `Last updated:` block — claims "Plan Staleness Sentinel: 7 closures since R07 review (+1 walk drain)" then later in same line: "Plan Staleness Sentinel: 6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068)")
- File: `docs/state/impl-plan.md`, Line: 55 (Next Best Action checklist row says "7 closures since R07 within threshold")
- File: `docs/state/current_handoff.md`, Line ~38 (also says "7 closures since R07 review (was 6 + 1 walk drain) — within 10-closure threshold")
- File: `docs/state/overview.md`, Line 20 (Impl Tasks status string — "Plan Staleness Sentinel = 7 closures since R07 within 10-closure threshold; ... + 1 walk drain landed 2026-05-05")
- Reference: `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4 (Sentinel counter increment "After closing task"); fix-round-10 § Plan Staleness Sentinel ("Plan Staleness Sentinel: 10 closures since R07 review unchanged — fix-rounds are review-loop artifacts, not task closures")
- Service: ea-state (process discipline)

**Code:**
```markdown
# impl-plan.md:9 — TL;DR (HEAD says 7, INLINE says 6 — internal contradiction)

> **Last updated:** 2026-05-05 · last action: ... **Plan Staleness Sentinel: 7 closures since R07 review (+1 walk drain)** — within threshold but `/impl-review all` R09 still recommended ...
>
> ... Prior action: IMPL-061 + IMPL-064 + IMPL-068 closed via parallel batch ...
> **Plan Staleness Sentinel: 6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068) — within 10-closure threshold ✅**
```

**Problem:**
Walk batch-2 drained 4 deferred-AC rows from Active table to Resolved. None of these drains involved closing a NEW task (IMPL-NNN ticked `[x]` for the first time). All 4 source tasks were already-closed (IMPL-009 closed 2026-05-02; IMPL-FIX-001/002 closed 2026-05-04; IMPL-064 closed 2026-05-04). The walk session merely produced empirical evidence to satisfy E-AC residue that the task closures had explicitly deferred to a later operator session.

Plan Staleness Sentinel discipline per `.claude/rules/workflow.md § Phase 5 Closure mechanical gates` Gate #4:
> "After closing task, bump `Plan Staleness Sentinel § Closures since last review` by +1 atomically with TL;DR `Last updated:` rewrite"
> "counter = (post-review closures); section + TL;DR self-flag agree"

The gate triggers on "closing task". A walk drain is not a task closure — it's E-AC residue drainage of already-closed tasks. fix-round-10 § Plan Staleness Sentinel set the precedent for non-task-closure events:
> "Plan Staleness Sentinel: 10 closures since R07 review unchanged (fix-rounds are review-loop artifacts, not task closures)"

By the same reasoning, walks are operator-session artifacts, not task closures. So the Sentinel should remain at 6 (the count just before this walk).

The current state contains an explicit internal contradiction in the SAME paragraph (impl-plan.md line 9 TL;DR):
- **TL;DR header sentence**: "Plan Staleness Sentinel: 7 closures since R07 review (+1 walk drain)"
- **Inline narrative 4 sentences later**: "Plan Staleness Sentinel: 6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068) — within 10-closure threshold ✅"

The list of 6 named closures is correct; the bumped 7 is inconsistent with that enumeration. Same contradiction propagates to `current_handoff.md` + `overview.md` (status string says 7 + 1 walk drain).

**Why This Matters:**
Plan Staleness Sentinel is the trigger for `/impl-plan-review` re-validation per CLAUDE.md §6 + workflow.md. A wrong count toward the 10-closure threshold:
- Inflates: 7/10 (stated) vs 6/10 (actual) — closer to triggering review than necessary
- Currently within threshold either way → no immediate impact
- BUT — when the count crosses 10, threshold trigger semantics matter. If walk drains keep getting +1'd, the Sentinel could trigger spurious `/impl-plan-review` runs that don't reflect actual task-closure velocity.

This is also a state reconciliation discipline issue: TL;DR + inline narrative + overview status string + handoff section all should agree. They don't — the "7 (+1 walk drain)" claim contradicts the enumerated "6 (IMPL-060 + ...)" inline list.

**Why LOW not MEDIUM:** Within threshold regardless (6 or 7 < 10); semantic ambiguity rather than functional defect; no `/next` or `/impl-task` decision currently affected. But LOW = "best practice violation, minor improvement" matches exactly per severity matrix.

**Suggested Fix:**
3-file synchronized edit (matches the State Reconciliation Discipline 3-file rule):

**`docs/state/impl-plan.md` line 9 — revert TL;DR header sentence + remove "+1 walk drain" annotation:**
```diff
-Plan Staleness Sentinel: 7 closures since R07 review (+1 walk drain) — within threshold
+Plan Staleness Sentinel: 6 closures since R07 review (IMPL-060 + IMPL-FIX-001 + IMPL-FIX-002 + IMPL-061 + IMPL-064 + IMPL-068; walk batch-2 drain ≠ task closure per workflow.md gate #4 + fix-round-10 precedent) — within threshold
```

**`docs/state/impl-plan.md` line 55 (Next Best Action) — same correction:**
```diff
-7 closures since R07 within threshold
+6 closures since R07 within threshold (walk drain not counted per workflow.md gate #4)
```

**`docs/state/current_handoff.md` Plan Staleness Sentinel block — revert:**
```diff
-Plan Staleness Sentinel: 7 closures since R07 review (was 6 + 1 walk drain) — within 10-closure threshold ✅
+Plan Staleness Sentinel: 6 closures since R07 review unchanged (walk batch-2 drains 4 E-AC residues but no new IMPL-NNN closure; per workflow.md gate #4 + fix-round-10 precedent fix-rounds + walks are not counted) — within 10-closure threshold ✅
```

**`docs/state/overview.md` Impl Tasks status string — revert:**
```diff
-Plan Staleness Sentinel = 7 closures since R07 within 10-closure threshold; 14 closures landed 2026-05-04 = ... + 1 walk drain landed 2026-05-05
+Plan Staleness Sentinel = 6 closures since R07 within 10-closure threshold; 14 closures landed 2026-05-04 = ...; walk batch-2 2026-05-05 drained 4 deferred-AC rows but no IMPL-NNN closure (Sentinel rule per workflow.md gate #4)
```

LoE: Low (~5 lines of state-file edits across 3 files; no source code; no G1).

**Level of Effort:** Low

---

### Finding 15.4: 🔵 LOW — `walk-summary.md § Execution` G3 wall-clock variance row claims "+2:15 (variance; same fixture)" สำหรับ batch-2 (9:05.786) vs batch-1 (6:50.521) — 33% slower — แต่ walk-summary attribution เป็น "variance" without root-cause investigation; deterministic Strategy Tester (`Model=0` non-tick OHLC + same date range + same deposit) ควร reproducible to seconds, ไม่ใช่ 33% variance — flag for root-cause before relying on wall-clock metrics ใน NFR-2.x latency E-ACs

**Location:**
- File: `docs/state/_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md`, Lines 22-24 (Execution table — "Wall-clock duration | 0:06:50.521 | 0:09:05.786 | +2:15 (variance; same fixture)")
- File: `simulation/headless-tests/bootstrap_smoke.ini` (the deterministic-Tester fixture being claimed reproducible)
- Service: ea-qa (Tier 1.5 walk methodology)

**Code:**
```markdown
# walk-summary.md:22-24 (Execution table excerpt)
| Metric | batch-1 (2026-05-04) | batch-2 (2026-05-05) | Delta |
|---|---|---|---|
| Wall-clock duration | 0:06:50.521 | 0:09:05.786 | +2:15 (variance; same fixture) |
| Tick count | 304,418 / 18 bars | 304,418 / 18 bars | identical (deterministic) |
| Memory | 97 MB | 83 MB | −14 MB (less per-tick string churn) |
| Final balance | $1000.00 | $1000.00 | unchanged (no positions closed in 3-day window) |
```

```ini
# bootstrap_smoke.ini — deterministic Tester config
[Tester]
Expert=PhoenicisNex\PhoenicisNex
Symbol=EURUSD
Period=H4
Model=0                      # ← non-tick OHLC = deterministic, no random tick generation
Optimization=0
FromDate=2024.01.02
ToDate=2024.01.05
Deposit=1000
Leverage=500
ShutdownTerminal=1
Visual=0
```

**Problem:**
Strategy Tester `Model=0` (OHLC-only, non-tick) + fixed FromDate/ToDate + fixed Deposit/Leverage = fully deterministic over the same `.mq5` source. Tick count identical (304,418) confirms determinism on the data side. So the 33% wall-clock variance is **not** test methodology variance — it's CPU-load variance from the host OS:
- batch-1 ran at 14:08-14:15 (per Tester log timestamp) — possibly with other workloads
- batch-2 ran at 08:36-08:45 (per the log timestamp) — possibly with different workloads

The walk-summary attribution "(variance; same fixture)" is correct as a label but lacks root-cause specificity. A reviewer can't tell from the artifact whether:
1. Host CPU was busy during batch-2 (CPU contention)
2. MT5 internal optimization changed (e.g., cache invalidation between days)
3. Disk I/O (state.json + journal write throughput) varied
4. Thread scheduling (single-threaded EA tick may interleave differently with OS scheduler)

This becomes a real concern when NFR-2.x latency E-ACs (IMPL-065 tick latency / IMPL-066 journal latency) start running — those metrics use `GetMicrosecondCount()` instrumented timing. If the wall-clock baseline is unreliable, those latency caps (e.g., NFR-2.1 ≤ X ms p99) can't be empirically attested.

The walk-summary doesn't note any system-load context (CPU usage, free memory, concurrent processes) at run time. This is a data-quality issue for any subsequent latency-related work.

**Why This Matters:**
- IMPL-065 (tick latency NFR-2.1) wants p99 ≤ 1.5× original baseline. If batch-1 vs batch-2 wall-clock varies 33% on the same fixture, the p99 cap is fragile to which session ran the regression.
- IMPL-066 (journal write latency p99 ≤ 5ms per NFR-2.2) — same concern. Wall-clock floor varies between sessions.
- Subagent-driven sessions in the future (e.g., parallel `/impl-task parallel`) may have wildly different host conditions; baseline reproducibility erodes.

This is **LOW** because it doesn't break any current AC — it's a methodology gap that would compound when NFR-2.x ACs activate.

**Suggested Fix:**
Add a "System Load Context" subsection to walk-summary.md template (used for both batch-1 and batch-2 retrospectively + future walks):

```markdown
## System Load Context (informational — for wall-clock interpretation)

| Metric | batch-1 | batch-2 |
|---|---|---|
| Run start (local time) | 2026-05-04 14:08 | 2026-05-05 08:36 |
| Concurrent processes (top 5 by CPU during run) | (capture via `Get-Process | Sort-Object CPU -Descending | Select-Object -First 5`) | (capture via same) |
| Free RAM at run start | (capture via `Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory`) | (capture via same) |
| MT5 cold/warm cache | cold (first headless run on this dataset today) | warm (history+symbols cached from batch-1) |
| Notes | (operator) | (operator) |
```

Even partial fill (just operator notes "running fresh terminal vs warm cache; no other heavy processes") gives reviewer a basis to interpret the variance.

For NFR-2.x AC work specifically — IMPL-065/066 should explicitly require multiple sessions (e.g., 3 runs) and use the median, not single-session wall-clock, as the basis for p99 attestation.

LoE: Low (~10 LOC walk-summary template addition; no source code; advisory for IMPL-065/066 methodology design).

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-15.1 — Pattern: validators ของ inputs/ ถูก declared แต่ไม่มี boot-time validation for any input range/set membership; same defect class as Finding 15.1 ใน scope ของ entire `inputs/` directory (not just Slot S)

`Inputs_Slot_S.mqh` มี discrete-set semantic ที่ FIX-001 expose. Other input files อาจมี similar discrete sets that operator can break:
- `Inputs_Slot_K.mqh` — `InpKMode` (if defined as enum-as-int)
- `Inputs_Slot_P.mqh` — `InpPSubMode` selectors per IMPL-034 A7 risk slot
- `Inputs_Pending.mqh` — `InpForceClearM_Bars` / `InpForceClearT_Bars` / `InpForceClearQ_Bars` (must be > 0 OR semantic = disabled)
- `Inputs_General.mqh` — various risk ratios (must be > 0; `InpMainRiskPct` valid range probably 0.1..5.0)

Recommend a Phase-2 IMPL-NNN ticket to systematically audit `inputs/` directory + add discrete/range validation for all inputs with semantic constraints. Same pattern as XS-14.2 (bulk SelfTest wiring backlog) and XS-13.3 (schema yaml in api-specs).

LoE: Medium (~50-80 LOC validator code across 5+ input categories; G1 + spike for invalid-input boundary cases).

### XS-15.2 — `walk-summary.md` template + nfr-3.1-atomic-write-result.md § 5 fill pattern is precedent for future NFR-X.Y result-table fills (NFR-2.1 latency / NFR-1.6 per-slot deviation / etc.) — recommend extracting the "Result table placeholder → filled" workflow into `.claude/rules/testing.md` or `andm-impl-engineer/SKILL.md` so future operator sessions follow the same Result-table fill pattern + sidecar JSON cross-check semantic

Currently the pattern is implicit ใน walk-summary.md authoring + nfr-3.1 fill. R15 verified the fill matches the sidecar JSON exactly (8/8 fields). This is a good pattern; should be canonicalized so IMPL-065 / IMPL-066 / IMPL-067 result tables follow the same shape (sidecar JSON co-located + cross-checked at fill time + `Status: PENDING NUMERIC RUN → ✅ PASS|FAIL` toggle).

LoE: Low (~30 LOC rules update + 1 example reference to nfr-3.1 fill).

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 15.1 | 🟠 HIGH | Business Logic Correctness | `InpSPercentTp` ขาด input validation; operator set ค่านอก {5,10,15} ผ่าน MT5 input dialog → re-trigger FIX-001 defect class (per-tick s_pct_tp_invalid ERROR + zero-lot Slot S); IMPL-017 sweep + IMPL-062 5-yr regression risk | `inputs/Inputs_Slot_S.mqh:33` + `services/RiskManager.mqh:402-415` + `core/BootstrapValidator.mqh` (no validation) | Low |
| 15.2 | 🟡 MEDIUM | Cross-Service Consistency / State Reconciliation | Walk batch-2 partial drains for IMPL-007 + IMPL-049 (×2 rows) + IMPL-052 not propagated to registry Active row narratives — registry stale vs walk-summary intent; future status agents may miss the partial-drain progress | `docs/state/deferred-ac-registry.md:15, 23-25` + `_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md:69-87` | Low |
| 15.3 | 🔵 LOW | Process Discipline | Plan Staleness Sentinel +1 increment for walk drain violates workflow.md gate #4 + fix-round-10 precedent ("walks/fix-rounds = review-loop artifacts, not task closures"); TL;DR header (7) contradicts inline narrative (6) | `docs/state/impl-plan.md:9, 55` + `current_handoff.md` + `overview.md:20` | Low |
| 15.4 | 🔵 LOW | Test Code Quality / Methodology | Walk-summary G3 wall-clock variance batch-1 vs batch-2 = 33% on deterministic fixture (`Model=0`) — labeled "variance" without root-cause; methodology gap for NFR-2.x latency E-ACs (IMPL-065/066) which depend on reproducible wall-clock baselines | `_session-handoff/tier-1.5-walk-2026-05-05/walk-summary.md:22-24` + future IMPL-065/066 dependency | Low |

---

## Recommendation

**Ready for fix-round-15 with no blockers.** Post-R14 surface is structurally sound — FIX-001 + FIX-002 source edits are minimal and correct on the happy-path; walk batch-2 evidence verified for all 4 newly-resolved deferred-AC rows; nfr-3.1 § 5 Result Table fill matches sidecar exactly; gate #1 forbidden-pattern grep clean; gate #9 (a)+(b) broader-class grep clean (R14 strengthened gate holding).

**R15 surface is dominantly defense-in-depth + state reconciliation:**

1. **15.1 (HIGH)** — InpSPercentTp validator: BootstrapValidator umbrella method (~25 LOC) + Orchestrator wire (~1 line) + comment update (~1 line). Closes operator-driven regression of the FIX-001 defect class. Highest priority.
2. **15.2 (MEDIUM)** — registry partial-drain narrative propagation for IMPL-007 + IMPL-049 (×2) + IMPL-052: ~150 LOC of registry text edits + 0 source code. Closes state reconciliation drift between walk-summary and registry.
3. **15.3 (LOW)** — Plan Staleness Sentinel revert 7→6 across impl-plan + current_handoff + overview (~5 LOC). Removes internal contradiction.
4. **15.4 (LOW)** — walk-summary template addition (~10 LOC) + advisory for IMPL-065/066 methodology design. Fills methodology gap before NFR-2.x ACs activate.

**Cross-cutting observation — XS-15.1:**
The InpSPercentTp gap is illustrative of a broader pattern: input validation in `inputs/` directory is currently structural-only (declarations + comments specifying valid ranges) without runtime enforcement. As Phase-1 → Phase-2 transitions activate optimization sweeps + regression runs, operator-driven-regression risk compounds. Recommend a Phase-2 IMPL-NNN ticket to systematically audit + harden `inputs/` validation across all 5+ input files.

**Cross-cutting observation — XS-15.2:**
Walk-summary.md + nfr-3.1 § 5 fill pattern is a good precedent for IMPL-065/066/067 result tables. Should be canonicalized in `.claude/rules/testing.md` + `andm-impl-engineer/SKILL.md` to ensure future NFR-X.Y result fills follow the same sidecar-JSON cross-check + status-toggle semantic.

**Plan Staleness Sentinel:** R15 surfaces Finding 15.3 that the count is 7 (per current TL;DR) but should be 6 (per workflow.md gate #4 + fix-round-10 precedent). Either way, well below 10-closure threshold; `/impl-plan-review all` not yet triggered. Mid-Phase Audit P4 counter at 6 ≥ 5 trigger remains advisory; can wait until after IMPL-062 starts so the review captures the next P4 task batch in one pass.

**On fix-round-14 closure verification (carryover):**
- Spike_CircuitBreaker.mq5 NEW exists ✅ (R14 § 14.2 fix delivered).
- BootstrapValidator::RunDomainSelfTests umbrella exists ✅ (R14 § 14.3 Part 2 fallback).
- Workflow gate #9 (a)+(b) clauses both pass on this turn's edits ✅.
- atomic_write_kill_100.ps1 doc surface no longer trips operator paste-error in this session's `-Trials 100` invocation ✅.

**Recommended next sequence:**
1. `/impl-review-fix review-round-15.md` — apply 4 findings + 2 XS resolutions (LoE: Low across the board; 1 source edit + 4 doc edits).
2. **THEN** start IMPL-062 (Bucket A regression — IMPL-061 baseline ✅ unblocked) to begin draining IMPL-068 5-yr regression bundle + 24 P3 slot 60-day deferrals before 2026-05-17/18 expiry cycle. Note: IMPL-062 will require RiskManager::OpenOrder/CloseOrder wiring (currently absent — comment-only stubs in 21 slot files); that is the substantial Phase-2 work item that gates P2/P3 retroactive Phase Gate close.
3. **OR** if operator prefers minimal blocking: defer fix-round-15 to a batch with future IMPL-NNN refactors and proceed directly to IMPL-062 — accept that operator-driven InpSPercentTp regression is a known risk for the 5-yr regression run (mitigated by walk batch-2 evidence that default 10.0 works correctly).

**Closure narrative-vs-actual sweep verification (R14 § 14.1 strengthened gate #9):**
- Originating R15 finding pattern grep — Finding 15.1 (`InpSPercentTp` not validated): grep `InpSPercentTp` in BootstrapValidator → 0 hits ✅ confirms gap is real (no validation logic).
- Broader-class grep — same defect class for other inputs (XS-15.1 scope): would require scanning all `inputs/Inputs_*.mqh` for discrete-set / range-bounded inputs without `BootstrapValidator::Validate*` callers. Deferred to fix-round-15 / Phase-2 IMPL-NNN per XS-15.1.
