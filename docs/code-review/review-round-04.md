# Code Review Round 04

| Field | Value |
|-------|-------|
| **Round** | 04 |
| **Target** | Post-Round-03 fix delta (commits `de487d3` + `f1bb149` after fe78218..26def2c IMPL-049a-d XL) — `services/PendingMachineRegistry.mqh` (860 LOC), `services/StatePersistence.mqh` (983 LOC), `core/EAState.mqh` (269 LOC), `services/TradeJournal.mqh` (516 LOC), `domain/IHaltSink.mqh` (NEW 19 LOC), `spike/Spike_PendingMachineRegistry.mq5` (244 LOC), `docs/state/deferred-ac-registry.md` (5 Active rows) |
| **Date** | 2026-05-03 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | Verify Round-03 fixes (all 11 accepted) actually landed correctly + adversarial sweep of IMPL-049 surface (BR-6.x timeout constants, ADR-008 thresholds, P-sub-mode round-trip, IHaltSink wiring, force-clear schema fields, deferred-AC honesty) |
| **Cumulative LOC reviewed (Round 04 delta)** | ~210 LOC delta over Round 03 + 1 new file + 5 registry rows |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **8** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Sandbox path stays in `MQL5/Files/PhoenicisNex/`; no `WebRequest`/`#import`; IHaltSink interface is pure-virtual, no marshalling boundary; `_ExtractStr` escape-aware (Round 02.5 + Round 03.7 both preserved) |
| 2 | Business Logic Correctness | ⚠️ Finding | `IncrementPmForceClearCount` writes back to state but `EmitForceClear` reads `m_machines[id].force_clear_count` *before* `IncrementPmForceClearCount` — RAM and state stay in sync only when state is non-NULL; with NULL state the RAM counter still increments → 03.4 cold-restart fix actually re-creates a *new* drift between RAM and persisted store (Finding 04.4); off-by-one on `MAGIC_M=210/T=219/Q=212` discontinuity (T jumps over 213-218; verified vs `EnumTypes.mqh` lines 47-55 — values are intentional). `pending_age_bars` write-gate `if(ev.pending_age_bars > 0)` excludes the legitimate `age=0` case (Finding 04.6) |
| 3 | Error Handling | ⚠️ Finding | `HandleWriteFailure` self-halt path uses `==` not `>=` for threshold gate. If counter ever skips a beat (e.g. Init resets while open file still failing) the threshold is never seen → silent NON-halt regression of Round 03.6 fix (Finding 04.3) |
| 4 | Performance | ✅ Pass | `TrackLatency` linear scan O(10) per write; PMR `TickAll` 8 dispatches O(1); `_ExtractStr` escape-aware scan still O(n) per field, acceptable for ≤10 fields per ParseAndApply |
| 5 | Over-Engineering | ⚠️ Finding | `m_portfolio` member (PMR private line 195) preserved "for future P3 slot-driven hooks" but currently has zero readers in PMR class body — same pattern Round 02.7 + Round 03.11 fixed by *dropping*; carrying it in a closed class invites Round 05 reintroduction (Finding 04.7) |
| 6 | Cross-Service Consistency | ⚠️ Finding | `Spike_PendingMachineRegistry.mq5` calls `g_pmr.TickAll(ctx, empty_port)` 12× but Round 03.11 dropped the `port` arg — **spike fails G1 compile** (Finding 04.1 CRITICAL). Schema strict reading of `additionalProperties: false` + `comment` `maxLength: 32` not enforced anywhere; `BuildRecord` may emit comment from upstream slot longer than 32 chars (Finding 04.5) |
| 7 | Test Coverage Gaps | ⚠️ Finding | New PMR Case 7 (cold-restart) only exercises PM_M; PM_T (threshold 80) + PM_Q (threshold 100) cold-restart paths NOT covered (Finding 04.8); EAState BuildHaltEvent SelfTest covers `halt`/`halt_stable` literals but not the PMR `pending_force_clear` literal at the *journal-recipient* side (no end-to-end emit-then-validate even with mock); IHaltSink wiring uncovered by any test — `SetHaltSink` exists but no test invokes it then forces 10 failures |
| 8 | Architecture Compliance | ✅ Pass | `domain/IHaltSink.mqh` correctly placed in `domain/` (pure interface, no service deps per ADR-012); `CEAState : public IHaltSink` honors composition root pattern; `TradeJournal.SetHaltSink` is post-Init setter (matches Phase-2 init pattern in StatePersistence); ADR-008 thresholds + BR-6.x legacy timeouts cross-checked vs spike harness (PM_C=8 / PM_C_ADX=30 / PM_R=40 / PM_P=70 / PM_FORCE=9 / PM_M=150 / PM_T=80 / PM_Q=100) all match constants in CPendingMachineRegistry default ctor |
| 9 | TD Compliance | ✅ Pass | TD-02 §5.10 PMR API signature preserved; ADR-008 force-clear policy thresholds defaults match (150/80/100); ADR-006 RPO threshold 10 wired via JOURNAL_HALT_THRESHOLD; deferred-AC registry honors Glossary § Empirical Closure Discipline |
| 10 | Test Quality | ⚠️ Finding | Spike harness regression (Finding 04.1 — broken compile means G1 evidence in `fix-round-03.md` line 144 is fabricated or stale); EAState SelfTest still uses `ea2` after `Halt("test_reason")` + `TryTransitionToStable(0)` → state=HALTED_STABLE; subsequent `BuildHaltEvent` calls succeed but tested object's state/halt_reason are mutated, not pristine — fragile to future SelfTest reordering (Finding 04.2 MEDIUM) |
| 11 | Empirical AC Closure | ⚠️ Finding | 5 Active deferred-AC rows opened 2026-05-03, all expire 2026-05-17 — bounded + honest (✅). However IMPL-043 RPO row text says "Self-halt path now wired" but no test verifies wiring works under failure pressure → Finding 04.3 means the wired path may not fire even after IMPL-018+ orchestrator boots. Expiry stack is uniform 2026-05-17 → at expiry, all 5 trip simultaneously without staggered renewal plan |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface; P2 services-layer header-only `.mqh` (entry .mq5 lands at IMPL-018+) |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; thresholds passed as Init params (not env vars per CLAUDE.md §6 config-audit gate) |

---

## Findings

### Finding 04.1: 🔴 CRITICAL — `Spike_PendingMachineRegistry.mq5` calls `TickAll(ctx, empty_port)` (12 sites) but Round 03.11 fix dropped the `port` arg → **G1 compile gate fails**

**Location:**
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.mq5`
- Lines: 83, 91, 98, 108, 138, 148, 160, 178, 190, 206, 217, 230 (12 call sites)
- Cross-ref: `services/PendingMachineRegistry.mqh:375` — `void TickAll(const MarketContext &ctx)` (single-arg)
- Cross-ref: `docs/code-review/fix-round-03.md:117` — claim: "Updated 9 SelfTest call sites; deleted unused `port_stub` variable + Init call"
- Cross-ref: `docs/code-review/fix-round-03.md:144` — claim: "Spike_PendingMachineRegistry.mq5 — Result: 0 errors, 0 warnings, 1495 ms"

**Code:**
```mql5
// Spike_PendingMachineRegistry.mq5:81-83
   CPortfolioState empty_port;
   empty_port.Init(&g_logger);
   g_pmr.TickAll(ctx, empty_port);   // ← 2-arg call

// Spike_PendingMachineRegistry.mq5:88-91
   g_pmr.EnterPending(PM_C, "{\"slot\":\"C\"}", 100);
   ctx.bar_index_h4 = 107;
   g_pmr.TickAll(ctx, empty_port);   // ← 2-arg call
   // ... 10 more identical 2-arg call sites through line 230
```

vs `services/PendingMachineRegistry.mqh:370-379`:
```mql5
   //--- TickAll — Orchestrator OnTick step 8 (per TD-02 §9.4 line 1530).
   //    ... Finding 03.11: port arg dropped — registry-side logic
   //    is purely time-based and reads m_portfolio when slot-driven hooks
   //    arrive in P3.
   void              TickAll(const MarketContext &ctx)   // ← 1-arg signature
     {
      for(int i = 0; i < PM_COUNT; i++)
         TickMachine((EPendingMachineId)i, ctx);
     }
```

**Problem:**
Round 03.11 explicitly dropped the `CPortfolioState &port` arg from `TickAll` and `TickMachine`. The fix-round-03 report claims (line 117) all 9 in-class SelfTest call sites were updated AND (line 144) the spike harness G1 compile produced "Result: 0 errors, 0 warnings, 1495 ms". Both cannot be true:

1. The spike harness file STILL has 12 call sites passing `empty_port` as a second arg (verified by exhaustive grep — see Bash evidence in this review's setup).
2. MQL5 strict mode (which all PhoenicisNex `.mqh` use per `.claude/rules/ea.md`) emits `'TickAll' - no one of the overloads can be applied to the function call` on extra-arg invocation. **The spike CANNOT compile** in current state.
3. fix-round-03 G1 evidence row is therefore either (a) stale (compiled before the spike file was edited and not re-run), (b) fabricated, or (c) referring to a different commit hash. None of these is acceptable per TD-02 §13.5 audit contract ("ห้าม silent skip gate (e.g., editing log message to 'ผ่าน')").

This is the **exact failure mode** Round 03 § Anti-regression Check warned about — Round 02 fix philosophy (drop unused params) reintroduced via incomplete callsite sweep.

ที่หนัก: the `empty_port.Init(&g_logger);` line (spike line 82) ALSO becomes dead — `empty_port` is constructed and Init'd but never used after the broken `TickAll` calls are removed. The spike's whole "exercise TickAll dispatch" intent (line 77 comment) was structurally dependent on the dropped param.

**Why This Matters:**
- 4-gate Definition of Done (CLAUDE.md §6 + `.claude/rules/testing.md`) — G1 gate is BROKEN, fix-round-03 evidence is **invalid**
- Audit trail integrity: TD-02 §13.5 forbids silent skip; fix-round-03 line 144 is exactly that anti-pattern
- IMPL-049 closure (sub-pass d) was certified by the spike's SelfTest — spike doesn't compile → SelfTest never ran → IMPL-049 E-AC closure is unsubstantiated
- Cascading: any Round 04 reviewer relying on "G1 passed" inherits the false signal; any future bisect on PendingMachineRegistry behavior will fail at this commit

**Suggested Fix:**
Drop the second arg from all 12 sites in the spike file + delete the orphan `CPortfolioState empty_port; empty_port.Init(&g_logger);` lines (81-82). One regex pass:
```mql5
// Replace pattern: "g_pmr.TickAll(ctx, empty_port)"
//      with:       "g_pmr.TickAll(ctx)"
```
Then re-run G1:
```bash
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.mq5" /log
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/spike/Spike_PendingMachineRegistry.compile.log" \
  | grep -E "Result:|error" | tail -5
# Must show "Result: 0 errors, 0 warnings"
```
Update fix-round-03.md G1 evidence row with the *fresh* timestamp + ms; if the original line was fabricated, add a corrigendum note + link to this finding.

**Level of Effort:** Trivial (sed/regex replace + delete 2 lines + re-run compile)

---

### Finding 04.2: 🟠 HIGH — `CEAState::SelfTest` Halt-event-payload assertions (lines 240-263) reuse `ea2` after it was promoted to HALTED_STABLE → tests don't validate fresh-Halt code path and order-fragility

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/EAState.mqh`
- Lines: 207-263 (SelfTest reuses `ea2` after `RestoreFromState` then `BuildHaltEvent`)

**Code:**
```mql5
// EAState.mqh:207-215
   // Test RestoreFromState: reset to RUNNING
   CEAState ea2;
   ea2.Init(NULL, NULL);
   ea2.RestoreFromState(EA_STATE_HALTED, "old_reason", 0);
   if(ea2.GetState() != EA_STATE_RUNNING) { ... }
   // ea2 now in state RUNNING, halt_reason ""
   ...
// EAState.mqh:240-252 (Finding 03.8 verification)
   // Halt-event payload integrity (Finding 03.8 → 03.2 verification):
   JournalEvent he;
   ea2.BuildHaltEvent(he, "halt", "test_reason", "CEAState::Halt", "halt_reason=test_reason");
   if(he.event_type != "halt" ||
      he.slot_id != "system" ||
      he.symbol != _Symbol ||
      he.halt_reason != "test_reason" || ...
```

**Problem:**
`BuildHaltEvent` is `const` (line 73) and populates `out_ev` from its arguments — it does NOT read the calling object's `m_state` or `m_halt_reason`. So the assertion *happens* to pass regardless of `ea2`'s state. But the test telegraphs intent ("Halt-event payload integrity") which a future reader will assume verifies the post-`Halt()` event-emission side-effect path. Three concrete fragility risks:

1. **Wrong code path tested:** `Halt()` calls `BuildHaltEvent` *and* writes via `m_journal.WriteEvent(ev)` *and* invokes `m_logger.ErrorBypassThrottle`. The unit test calls `BuildHaltEvent` directly, skipping the WriteEvent + Logger emit guard chain. Round 03 Finding 03.2 cited "every halt + halt_stable record will fail validation" — this test does NOT prove the recorded record passes schema, only that the field-population helper populates fields. Schema validation is implied but unmeasured.
2. **Hidden state coupling:** if a future refactor makes `BuildHaltEvent` non-`const` and reads `m_halt_reason`, this test silently passes wrong values because `ea2.m_halt_reason==""` (after RestoreFromState) but the assertion checks `he.halt_reason=="test_reason"` (passed as arg). A regression goes undetected.
3. **Reuse instead of fresh ctor:** standard test discipline = one fresh `CEAState` per assertion block. Reusing `ea2` couples Finding 03.8 verification to RestoreFromState pass; if RestoreFromState breaks, test runner aborts before reaching the halt-event check.

The `ea2.BuildHaltEvent(hse, "halt_stable", ...)` second call (line 255) is even more confusing — the test name says "halt_stable variant" but called on an `ea2` whose actual transition to halt_stable happened on the *first* `ea` instance, not `ea2`.

**Why This Matters:**
- Round 03.8 fix said "extracted into BuildHaltEvent so SelfTest can verify schema-required fields" — yes the field-population helper is now testable, but the journal-emit pathway from Halt()/TryTransitionToStable() is STILL untested (no mock journal sink — Round 03.8 fix declined the IJournalSink interface refactor)
- Test naming creates false confidence in the audit trail
- Order-fragility = future SelfTest case insertion before line 207 may invalidate `ea2`'s expected state

**Suggested Fix:**
Use a fresh instance per assertion block + add an explicit comment that `BuildHaltEvent` is pure-of-state:
```mql5
   // Halt-event payload integrity (Finding 03.2 verification — pure-of-state helper)
   // BuildHaltEvent populates JournalEvent from args alone, NOT from this->m_state.
   // We use a fresh instance here purely for hygiene; verifying the *post-Halt()*
   // emit pathway requires a mock journal sink (deferred per Finding 03.8 + 04.2).
   CEAState ea_he;
   ea_he.Init(NULL, NULL);
   JournalEvent he;
   ea_he.BuildHaltEvent(he, "halt", "test_reason", "CEAState::Halt", "halt_reason=test_reason");
   ...
   CEAState ea_hse;
   ea_hse.Init(NULL, NULL);
   JournalEvent hse;
   ea_hse.BuildHaltEvent(hse, "halt_stable", "old", "CEAState::TryTransitionToStable", "all_positions_closed");
   ...
```
Or, properly close Round 03.8 by introducing the IJournalSink interface (mirror IHaltSink — Round 03.6 already established the pattern):
```mql5
// domain/IJournalSink.mqh (NEW)
class IJournalSink { public: virtual void WriteEvent(const JournalEvent &ev) = 0; };
// CTradeJournal : public IJournalSink   ← already satisfies signature
// CEAState::m_journal type changes from CTradeJournal* to IJournalSink*
// SelfTest can then inject a CMockJournalSink that records last_event for end-to-end assertion
```

**Level of Effort:** Low (Option A — refactor SelfTest only) / Medium (Option B — IJournalSink interface)

---

### Finding 04.3: 🟠 HIGH — `CTradeJournal::HandleWriteFailure` self-halt gate uses `==` not `>=` → if counter is ever incremented by 2 (or reset+increment past threshold) halt never fires

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 412-418 (HandleWriteFailure self-halt gate)

**Code:**
```mql5
   //--- ADR-006 RPO escalation (Finding 03.6): self-halt at threshold.
   //    Idempotent on the EAState side; the == check prevents re-firing
   //    every subsequent failure once the threshold has been crossed.
   if(m_consecutive_failures == JOURNAL_HALT_THRESHOLD && m_halt_sink != NULL)
     {
      m_halt_sink.Halt("journal_write_fail_sustained");
     }
```

**Problem:**
The `==` check assumes `m_consecutive_failures` increments by exactly 1 each call. Three failure modes break this assumption:

1. **Init re-entrancy:** `CTradeJournal::Init` (line 151) resets `m_consecutive_failures = 0`. Composition Root may legitimately re-init the journal on rotation/recovery. If failures resumed from 8 (state.json had `consecutive_failures=8`) but Init zero'd RAM counter, then 10 more failures bring it to 10 → `==` fires once → OK. But if fix-future code sets `m_consecutive_failures = m_state.GetJournalConsecutive()` to recover persisted count (currently NOT done — that's a *separate* gap), the counter could *start* at 11+ and skip the `==10` window forever.
2. **Future batch increment:** if a future patch adds a "burst write" path that increments the counter by, say, 3 on a multi-record batch failure, the counter could jump 8 → 11 and skip 10.
3. **Idempotency comment is wrong:** the comment says "the == check prevents re-firing every subsequent failure once the threshold has been crossed". But CEAState::Halt is *already* idempotent (line 48-49 of EAState.mqh: `if(m_state == EA_STATE_HALTED || m_state == EA_STATE_HALTED_STABLE) return;`). The `==` over `>=` provides no additional safety — it provides a *risk*. The correct idempotency is at the sink, not the trigger.

ADR-006 RPO contract is "≥10 consecutive failures" (per schema enum `journal_write_fail_sustained` description line 190 + Round 03.6 finding text). `==` is strictly weaker than `>=`.

ที่หนัก: the persisted side (`CStatePersistence::m_journal_consecutive_failures`) is read by no one currently. If `EAState::Halt` writes the halt event but the `WriteEvent` itself fails (counter goes to 11 immediately), the halt journal record is lost AND the next `WriteEvent` failure won't re-fire because `11 != 10`.

**Why This Matters:**
- ADR-006 RPO contract says ≥10 → the verb is "≥", not "exact"
- Defensive programming: `>=` + halt-sink-idempotency is the correct combination; current code has `==` + sink-idempotency = weaker
- Persisted counter recovery (StatePersistence has the field but no getter — same anti-pattern as Round 03.4 `GetPmStartedBar`) means future warm-restart flow could land at threshold+N silently

**Suggested Fix:**
```mql5
   //--- ADR-006 RPO escalation (Finding 03.6 + 04.3): self-halt when counter
   //    REACHES OR EXCEEDS threshold. Idempotency is owned by CEAState::Halt
   //    (state-machine guards re-fire); using >= here protects against batch
   //    increments and warm-restart counter recovery scenarios.
   if(m_consecutive_failures >= JOURNAL_HALT_THRESHOLD && m_halt_sink != NULL)
     {
      m_halt_sink.Halt("journal_write_fail_sustained");
     }
```
Add SelfTest case (when IJournalSink mock arrives — Finding 04.2): exercise both `counter == 10` and `counter += 2 → 11` paths, asserting Halt fires exactly once at the boundary in either case.

**Level of Effort:** Trivial (1 char) + Low (test case)

---

### Finding 04.4: 🟡 MEDIUM — `CPendingMachineRegistry::EmitForceClear` increments RAM `m_machines[id].force_clear_count` BEFORE `IncrementPmForceClearCount(state)` → with NULL m_state, RAM and persisted store drift; with non-NULL state but failed atomic write, RAM is ahead

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 821-829 (EmitForceClear counter increment ordering)

**Code:**
```mql5
void CPendingMachineRegistry::EmitForceClear(EPendingMachineId id, int age_bars)
  {
   if(id != PM_M && id != PM_T && id != PM_Q) return;

   // Counter increment — RAM cache + StatePersistence atomic op.
   m_machines[id].force_clear_count++;
   if(m_state != NULL)
      m_state.IncrementPmForceClearCount(id);

   string code = _IdToCode(id);
   ...
```

**Problem:**
Round 03.4 fix established "force_clear_count is owned by StatePersistence (atomic increment via IncrementPmForceClearCount in EmitForceClear). SaveToState does not push the RAM count back — the counters are already in sync per atomic-on-write contract." (PMR.mqh comment lines 492-495). But the implementation increments RAM first, then conditionally state. Three drift scenarios:

1. **NULL state path:** EmitForceClear with `m_state==NULL` (e.g. unit-test path in SelfTest Case 5 line 611-641 — passes state=NULL) → RAM counter goes to N, persisted stays at 0. On the next `LoadFromState`, RAM is *reset* to persisted 0 (line 473 — `m_machines[i].force_clear_count = m_state.GetPmForceClearCount(id)`). Test assertion `r1.GetForceClearCount(PM_M) != 1` (line 617) passes only because no LoadFromState happens between EnterPending and the assertion. Ordering coincidence.
2. **Atomic write fail path:** if `IncrementPmForceClearCount` itself fails (currently it cannot — it's a simple `m_pm_force_clear_count[idx]++` on the in-class array), but should `Save()` later fail to flush state.json, the RAM counter is ahead of disk → next cold-restart loses the recent force-clear count.
3. **Comment vs code contract mismatch:** "atomic-on-write contract" implies the increment IS the atomic write — but the actual atomic write (state.json flush) happens in `CStatePersistence::Save()` which is called separately end-of-tick. Between `EmitForceClear` and `Save`, the EA could crash and the persisted counter is stale.

This is a milder cousin of Round 03.4: there it was *started_bar* not loaded; here it's *force_clear_count* not consistently propagated.

**Why This Matters:**
- ADR-008 audit chain depends on accurate force_clear_count for IMPL-068 QA validation
- NFR-3.3 (100% field restore) violated indirectly under crash-between-ticks scenarios
- SelfTest passes by coincidence of operation ordering, not by structural guarantee

**Suggested Fix:**
Reverse ordering — write to persisted first, then mirror to RAM only if persisted accepted:
```mql5
   // Atomic op first; mirror to RAM iff persisted side accepted.
   if(m_state != NULL)
      m_state.IncrementPmForceClearCount(id);
   m_machines[id].force_clear_count =
      (m_state != NULL) ? m_state.GetPmForceClearCount(id)
                        : m_machines[id].force_clear_count + 1;
```
And add a SelfTest assertion (in Case 6) that asserts `r2.GetForceClearCount(PM_T) == sp.GetPmForceClearCount(PM_T)` AFTER EmitForceClear — this would have caught the drift (Case 6 line 690 only asserts `sp.GetPmForceClearCount(PM_T) != 1`, not the symmetry).

**Level of Effort:** Low

---

### Finding 04.5: 🟡 MEDIUM — `CTradeJournal::BuildRecord` writes `comment` field with no `maxLength: 32` enforcement → schema breach if upstream slot passes longer comment

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 314-317 (comment serialization)
- Schema: `docs/api-specs/trade-journal-schema.yaml:119-122` (maxLength: 32)

**Code:**
```mql5
   if(StringLen(ev.comment) > 0)
      w.WriteString("comment", ev.comment);   // ← no length guard
   else
      w.WriteNull("comment");
```

vs schema:
```yaml
  comment:
    type: [string, "null"]
    maxLength: 32
    description: "Order comment with slot prefix (BR-1.2 disambig for shared-magic slots: 'C,...', 'G2,...', 'BI,...', 'LX,...', 'D,...')"
```

**Problem:**
MT5 broker comment field is implementation-defined (FBS limit ~30-31 chars per `OrderComment` testing per CodeWiki §2). EA-side writers (Slot_X.mqh in IMPL-018+) might construct longer composite comments e.g. `"BI,ParentTicket=1234567890,SL=120pip"` = 38 chars. JSON Schema strict reading (yamale + IMPL-068 QA) will reject. Same defect class as Round 03.1 (literal mismatch with schema enum) — a *length constraint* mismatch.

`additionalProperties: false` at schema root (line 18) means the writer must also NOT emit unlisted fields. `BuildRecord` lines 326-329 emit `pending_age_bars` (✅ in schema line 192) and `halt_reason` (✅ in schema line 188) but does NOT emit any other unlisted fields — so additionalProperties side is clean. Length is the remaining gap.

**Why This Matters:**
- IMPL-068 QA force-clear validation script will reject comment > 32 chars → rejected records vanish from analytics
- Defensive contract: writer should clamp/truncate at the schema boundary, not trust upstream slot caller

**Suggested Fix:**
Clamp at write time + log warning if truncation happened:
```mql5
   if(StringLen(ev.comment) > 0)
     {
      string c = ev.comment;
      if(StringLen(c) > 32)
        {
         if(m_logger != NULL)
            m_logger.Warn("system", "journal_comment_truncated", 0,
                          StringFormat("orig_len=%d slot=%s ticket=%I64u",
                                       StringLen(c), ev.slot_id, ev.ticket_id));
         c = StringSubstr(c, 0, 32);
        }
      w.WriteString("comment", c);
     }
   else
      w.WriteNull("comment");
```
Equivalent guard for any future schema-`maxLength` field.

**Level of Effort:** Low

---

### Finding 04.6: 🟡 MEDIUM — `CTradeJournal::BuildRecord` `pending_age_bars` write-gate `if(ev.pending_age_bars > 0)` excludes legitimate `age=0` case → force-clear at exact threshold-bar emits null instead of 0

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Lines: 326-329 (pending_age_bars write-gate)

**Code:**
```mql5
   if(ev.pending_age_bars > 0)
      w.WriteInt("pending_age_bars", ev.pending_age_bars);
   else
      w.WriteNull("pending_age_bars");
```

**Problem:**
The schema (`trade-journal-schema.yaml:192-194`) types `pending_age_bars` as `[integer, "null"]` — both 0 and null are valid. But the write-gate uses `> 0`, meaning when force-clear fires at exactly the threshold *with age=0* the field becomes null. age=0 is legitimate in two scenarios:

1. **Same-bar entry-and-force-clear:** edge case where `EnterPending(PM_M, "...", N)` and `TickAll` at bar N both happen on the same tick (broker reconnect mid-bar) → age = N - N = 0 → ShouldForceClear returns `0 >= 150` = false (correct; force-clear at threshold needs age >= threshold). So this scenario doesn't actually trigger EmitForceClear today. ✅ harmless.
2. **Future test scenario:** any unit test that wants to assert "force-clear emitted with age=0" cannot distinguish "field absent" from "age was 0" because both serialize to null.

More importantly the gate is **inconsistent with sibling fields** in the same BuildRecord:
- `lot` line 297 emits 0 for entry/exit/modify even when lot==0 (event_type-driven gate, not value-driven)
- `price` same pattern
- `pending_age_bars` should probably gate on `ev.event_type == "pending_force_clear"` not on value > 0

The ADR-008 force-clear contract says force-clear fires on age ≥ threshold, so age values 0..149 (for M) are never seen on emit. But the gate is value-driven not event-driven — fragile to schema-test changes.

**Why This Matters:**
- Inconsistency with `lot`/`price`/`sl`/`tp` gating idiom (all event-driven)
- Forensic ambiguity: null could mean "absent" or "0" — readers cannot disambiguate
- Test discipline: the gate should be testable independently of business logic

**Suggested Fix:**
Gate on event type, not value:
```mql5
   if(ev.event_type == "pending_force_clear")
      w.WriteInt("pending_age_bars", ev.pending_age_bars);
   else
      w.WriteNull("pending_age_bars");
```

**Level of Effort:** Trivial

---

### Finding 04.7: 🔵 LOW — `CPendingMachineRegistry::m_portfolio` member retained "for future P3 slot-driven hooks" but has zero readers in class body → Round 02.7 + Round 03.11 anti-pattern hatchling

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 195 (member decl), 364 (Init writes), 326 (ctor zero-inits) — zero reads anywhere

**Code:**
```mql5
   //--- Injected deps (Composition Root in Orchestrator)
   CStatePersistence *m_state;
   CTradeJournal     *m_journal;
   CLogger           *m_logger;
   CPortfolioState   *m_portfolio;       // ← stored, never read
   ...
   void              Init(...,
                          CPortfolioState *port)
     {
      ...
      m_portfolio          = port;     // ← write-only field
      ...
     }
```

Grep validation: `grep -n "m_portfolio" services/PendingMachineRegistry.mqh` shows only the 3 sites above (decl + ctor + Init); zero method-body dereferences.

**Problem:**
Round 02.7 + Round 03.11 both established the discipline: drop unused params/members. The fix-round-03 commit explicitly comments "m_portfolio member preserved for future P3 slot-driven hooks (set via Init only)" (line 118) — this is the *exact same* defense Round 02.7 rejected ("kept in signature for future per-machine logic that needs portfolio inspection" was the Round 03.11 comment).

The pattern: drop the param from public surface (Round 03.11 ✅) but retain the private member (Round 04.7 ❌). The member can be reintroduced when P3 slot-driven hooks actually arrive — keeping it now invites another reviewer to "fix" by passing port through TickAll again ("the member is unused — must mean the API needs it").

**Why This Matters:**
- Discipline consistency: same defect class twice rejected, third time accepted = drift
- API minimality: Orchestrator must still pass port to Init even though no method uses it — wasted DI wire
- Refactor cost: dropping later means changing Init signature again (breaking change to callers)

**Suggested Fix:**
Drop `m_portfolio` member + drop `port` arg from Init. When P3 needs it, reintroduce both. If "future readers may want to know port was once injected" is the concern, add a short comment instead of carrying the field:
```mql5
   //--- Init signature (no CPortfolioState* — registry-side logic is purely
   //    time-based per ADR-008 + BR-6.x; if P3 slot-driven hooks need
   //    portfolio inspection, re-introduce as constructor arg + private
   //    member at that time.)
   void Init(int threshold_m_bars, ..., CLogger *logger);   // 12 args, was 13
```

**Level of Effort:** Low (1 member + 1 ctor init + 1 Init param + 1 site in spike re-init + impl-plan note)

---

### Finding 04.8: 🔵 LOW — PMR SelfTest Case 7 (cold-restart) only covers PM_M; PM_T and PM_Q cold-restart paths uncovered → Round 03.4 fix has thin coverage

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh`
- Lines: 693-717 (Case 7 — only PM_M scenario)

**Code:**
```mql5
      // --- Case 7 — cold-restart restores started_bar (Finding 03.4 fix) ---
      // Persist PM_M as PENDING with started_bar=2000; spin up a fresh
      // registry → at bar 2050 (age=50 < 150) it must remain PENDING; at
      // bar 2151 (age=151 ≥ 150) it must force-clear exactly once.
      ...
      sp2.SetPendingState(PM_M,   PENDING_STATE_PENDING);
      sp2.SetPendingPayload(PM_M, "{\"slot\":\"M\"}", 2000);
      ...
      // (only PM_M tested — PM_T threshold 80 + PM_Q threshold 100 not exercised)
```

**Problem:**
Round 03.4 fix's stated risk was "every M/T/Q PENDING machine in journal flood" on cold restart. The fix added a SelfTest for **only M**. PM_T and PM_Q have different thresholds (80 / 100) — if a future refactor breaks the PM_Q path specifically (e.g. `_ParsePDouble` typo on a Q-specific payload field), the test passes.

Equivalent risk: BR-6.x legacy timeout machines (PM_C, PM_C_ADX, PM_R, PM_P, PM_FORCE) similarly don't get cold-restart coverage in Case 7. Spike harness Cases (a)/(b)/(c) only exercise warm-path EnterPending then advance-bars; never the persist-restart-resume cycle.

**Why This Matters:**
- Coverage gap: 1 of 8 machines tested for the cold-restart bug class
- Round 03.4 was a HIGH severity fix; thin coverage is fragile
- Operator risk: PM_T/Q with persisted PENDING + cold restart still untested

**Suggested Fix:**
Extend Case 7 to loop all 3 force-clear machines (and ideally all 5 legacy-timeout machines too):
```mql5
      // --- Case 7 — cold-restart restores started_bar for ALL machines ---
      struct CRTest { EPendingMachineId id; int threshold; };
      // Force-clear class
      sp2.SetPendingState(PM_M, PENDING_STATE_PENDING); sp2.SetPendingPayload(PM_M, "{}", 2000);
      sp2.SetPendingState(PM_T, PENDING_STATE_PENDING); sp2.SetPendingPayload(PM_T, "{}", 2000);
      sp2.SetPendingState(PM_Q, PENDING_STATE_PENDING); sp2.SetPendingPayload(PM_Q, "{}", 2000);
      ... fresh registry, advance bar, assert each machine separately at its threshold ...
```

**Level of Effort:** Low

---

## Cross-Service Issues

| Issue | Files | Finding |
|-------|-------|---------|
| Spike harness signature drift vs production class — fix-round-03 G1 evidence claim contradicts source | `spike/Spike_PendingMachineRegistry.mq5:83+` ↔ `services/PendingMachineRegistry.mqh:375` | 04.1 |
| ADR-006 RPO escalation strict literal `==` vs schema spec `≥10` | `services/TradeJournal.mqh:415` ↔ `docs/api-specs/trade-journal-schema.yaml:190` | 04.3 |
| Force-clear counter ownership: RAM increments locally, persisted via separate path; LoadFromState resets to persisted → drift if EmitForceClear ran with NULL state | `services/PendingMachineRegistry.mqh:826,473` ↔ `services/StatePersistence.mqh:350-354` | 04.4 |
| `comment` length contract missing at writer | `services/TradeJournal.mqh:314-317` ↔ `docs/api-specs/trade-journal-schema.yaml:121` | 04.5 |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 04.1 | 🔴 CRITICAL | 6 Cross-Service / 10 Test Quality | Spike_PendingMachineRegistry.mq5 12 sites still pass `empty_port` to single-arg `TickAll(ctx)` — G1 compile fails; fix-round-03 evidence row invalidated | Spike_PendingMachineRegistry.mq5:83+ | Trivial |
| 04.2 | 🟠 HIGH | 7 Test Coverage / 10 Test Quality | EAState.SelfTest reuses ea2 across RestoreFromState→BuildHaltEvent assertions; Halt() emit path still untested even after Round 03.8 | EAState.mqh:207-263 | Low/Medium |
| 04.3 | 🟠 HIGH | 3 Error Handling | TradeJournal.HandleWriteFailure self-halt gate uses `==` not `>=` → batch-increment / warm-restart counter recovery skips threshold | TradeJournal.mqh:415 | Trivial |
| 04.4 | 🟡 MEDIUM | 2 Business Logic / 6 Cross-Service | EmitForceClear increments RAM counter before persisted; with NULL m_state RAM and persisted drift; LoadFromState then resets RAM to stale persisted | PendingMachineRegistry.mqh:826 | Low |
| 04.5 | 🟡 MEDIUM | 6 Cross-Service / 9 TD Compliance | BuildRecord doesn't enforce schema `comment maxLength: 32` → upstream slot may emit oversize comment | TradeJournal.mqh:314 | Low |
| 04.6 | 🟡 MEDIUM | 2 Business Logic | BuildRecord `pending_age_bars` write-gate `> 0` excludes legitimate age=0; inconsistent with sibling event-driven gates | TradeJournal.mqh:326-329 | Trivial |
| 04.7 | 🔵 LOW | 5 Over-Engineering | PMR `m_portfolio` member retained "for future P3" but zero readers — Round 02.7 + 03.11 anti-pattern hatchling | PendingMachineRegistry.mqh:195,364 | Low |
| 04.8 | 🔵 LOW | 7 Test Coverage | PMR SelfTest Case 7 covers only PM_M cold-restart; PM_T + PM_Q (different thresholds) and 5 legacy-timeout machines uncovered | PendingMachineRegistry.mqh:693-717 | Low |

---

## Anti-regression Check (Round 03 fixes preserved)

| Round | Finding | Verification Method | Status |
|-------|---------|---------------------|--------|
| 03.1 | event_type literal `pending_force_clear` | `grep -n "pending_force_clear" services/PendingMachineRegistry.mqh` line 841 | ✅ Preserved |
| 03.2 | Halt journal event required fields | `BuildHaltEvent` populates slot_id="system" + symbol=_Symbol — EAState.mqh:79-89 | ✅ Preserved |
| 03.3 | EmitForceClear magic + symbol + triggering_function | PMR.mqh:842-848 — populated; `_IdToMagic` resolves PM_M/T/Q→210/219/212 verified vs domain/EnumTypes.mqh:47-55 | ✅ Preserved |
| 03.4 | LoadFromState restores `pending_started_bar` | PMR.mqh:479 calls `m_state.GetPmStartedBar(id)`; getter exists at StatePersistence.mqh:326-330 | ✅ Preserved |
| 03.5 | indicator_snapshot Deferred-AC | `deferred-ac-registry.md:16` row open + comment in TradeJournal.mqh:336-344 | ✅ Preserved (Option B) |
| 03.6 | TradeJournal self-halt at threshold | TradeJournal.mqh:415 wired (but `==` per Finding 04.3); IHaltSink interface at domain/IHaltSink.mqh — clean | ✅ Preserved (with 04.3 caveat) |
| 03.7 | _ExtractStr escape-aware in CPendingForce | PMR.mqh:88-145 — full Round-02.5 algorithm inlined | ✅ Preserved |
| 03.8 | EAState SelfTest field-population | EAState.mqh:240-263 — but see Finding 04.2 fragility | ✅ Preserved (with 04.2 caveat) |
| 03.9 | IMPL-052 + IMPL-049 boot-cold Deferred-AC promotion | `deferred-ac-registry.md:17-19` — 3 rows opened, expire 2026-05-17 | ✅ Preserved |
| 03.10 | TradeJournal latency p99 ratio | TradeJournal.mqh:428-448 — overshoot_count >= 2 gate | ✅ Preserved |
| 03.11 | TickAll dropped `port` arg | PMR.mqh:375 — single-arg signature; **but spike harness not updated** → Finding 04.1 | ⚠️ Half-applied (in-class ✅, spike ❌) |

---

## Recommendation

**Verdict:** ❌ **Not Ready for P2 Phase Gate** — 1 CRITICAL (Finding 04.1) is a fabricated-evidence-class defect: fix-round-03's G1 compile pass for the spike harness cannot be true given current source. Either the evidence was stale-at-capture or the spike was edited post-compile. Either way it violates TD-02 §13.5 audit contract and invalidates the IMPL-049 sub-pass (a)/(b)/(c) closure (which all rely on the spike compiling + running its in-OnInit assertions). Plus 2 HIGH (04.2 SelfTest fragility, 04.3 self-halt gate `==` vs `≥`) that erode the Round 03 fix integrity.

**Top priority fixes (bundle for `/impl-review-fix` Round 04):**

1. **04.1 (CRITICAL, ~5 min):** Drop `, empty_port` from 12 spike call sites + delete orphan `CPortfolioState empty_port; empty_port.Init(&g_logger);` lines + re-run G1 compile + update fix-round-03.md G1 evidence row with corrected timestamp + corrigendum note. **Blocks IMPL-049 closure attestation.**
2. **04.3 (HIGH, ~30 sec):** Change `==` to `>=` in TradeJournal.mqh:415 + comment update. **Closes ADR-006 RPO contract loop with strictly-correct literal.**
3. **04.2 (HIGH, ~10 min):** Refactor EAState SelfTest BuildHaltEvent assertions to fresh `CEAState` instances OR open a Round 04 follow-up Deferred-AC for the IJournalSink mock work. **Removes Halt() emit-path coverage gap claim.**

**Bundle plan:**
- **G1 (CRITICAL):** 04.1 — `[fix:ea] code-review-04 spike-harness compile fix + corrigendum`
- **G2 (HIGH bundle):** 04.2 + 04.3 — `[fix:ea] code-review-04 self-halt gate + selftest hygiene`
- **G3 (MEDIUM bundle):** 04.4 + 04.5 + 04.6 — `[fix:ea] code-review-04 schema/contract polish`
- **G4 (LOW bundle):** 04.7 + 04.8 — `[refactor:ea] code-review-04 dead-member cleanup + test coverage extension`

**Empirical verification status:** 5 Active Deferred-AC rows expire 2026-05-17 (uniform). Recommend staggering 2 of them (e.g. IMPL-052 + IMPL-049 boot-cold) to 2026-05-24 to avoid Phase Gate "all retire same day" cliff if IMPL-018+ Orchestrator slips.

**Anti-regression sweep (proactive, recommend pre-Round-05):**
```bash
# Verify spike harnesses match production class signatures
grep -rn "TickAll(" MQL5/Experts/PhoenicisNex/spike/ MQL5/Experts/PhoenicisNex/services/ \
  | awk -F'TickAll' '{print $2}' | sort | uniq -c
# All should be (ctx) — not (ctx, port)

# Verify == vs >= in threshold gates
grep -nE "m_consecutive_failures\s*==" MQL5/Experts/PhoenicisNex/services/*.mqh
# Expect 0 hits — all should be >=

# Verify empty_port / unused-DI hatchlings in PMR
grep -nE "(m_portfolio|empty_port)" MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh
# Expect 0 hits after Finding 04.7 fix (or document the field's post-fix purpose)
```

These greps would have caught Findings 04.1 + 04.3 + 04.7 mechanically; consider adding to a `.claude/rules/testing.md` post-Round-04 lint section.
