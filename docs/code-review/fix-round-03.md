# Code Review Fix Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Review File** | `docs/code-review/review-round-03.md` |
| **Date** | 2026-05-03 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack) |
| **Scope** | 4 source files (`core/EAState.mqh` 224→~280 LOC, `services/PendingMachineRegistry.mqh` 772→~860 LOC, `services/TradeJournal.mqh` 480→~510 LOC, `services/StatePersistence.mqh` +6 LOC) + 1 new domain file (`domain/IHaltSink.mqh`) + 1 spec/registry update (`docs/state/deferred-ac-registry.md`) |
| **Cumulative LOC delta** | +200 / −35 across 5 files (+ 1 new file 18 LOC + 5 registry rows) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Bundle |
|---|---------|----------|---------|----------------|--------|
| 03.1 | EmitForceClear `event_type="force_clear"` ≠ schema enum | 🔴 CRITICAL | Accept | 0 | G1 |
| 03.2 | EAState.Halt + TryTransitionToStable: required JournalEvent fields ZeroMemory'd | 🔴 CRITICAL | Accept | 0 | G1 |
| 03.3 | EmitForceClear: magic=0 + symbol="" + triggering_function="" | 🟠 HIGH | Accept | 0 (uses domain MAGIC_M/T/Q) | G1 |
| 03.4 | LoadFromState resets pending_started_bar=0 → cold-restart force-clear flood | 🟠 HIGH | Accept | 1 (StatePersistence — new getter) | G1 |
| 03.5 | BuildIndicatorSnapshotSubset hard-codes `"{}"` | 🟠 HIGH | Accept (Option B — Deferred-AC) | 0 | G2 |
| 03.6 | TradeJournal.WriteEvent never self-halts at threshold | 🟠 HIGH | Accept | 1 (new `domain/IHaltSink.mqh` interface) | G1 |
| 03.7 | CPendingForce::_ExtractStr replicates Round 02.5 unescape bug | 🟡 MEDIUM | Accept (Option B — inline fix) | 0 | G3 |
| 03.8 | EAState.SelfTest cannot exercise journal/Logger paths | 🟡 MEDIUM | Accept (testable extract) | 0 | G3 |
| 03.9 | IMPL-052 `[boot-cold]` E-AC closed via SelfTest precedent | 🟡 MEDIUM | Accept (Option A — promote to Deferred-AC) | 1 (registry) | G3 |
| 03.10 | TradeJournal m_overshoot_window populated but never read | 🔵 LOW | Accept | 0 | G4 |
| 03.11 | TickMachine line 691 dead branch | 🔵 LOW | Accept (drop unused port arg) | 0 | G4 |

**Accepted:** 11 / 11 — **Rejected:** 0 — **Partial:** 0

**Pattern detection sweep:** Round 02 anti-regression patterns checked — `_ExtractStr` naive matcher now appears only in `CPendingForce` (post-fix, escape-aware) + `CStatePersistence` (Round 02.5 fix). `ZeroMemory(JournalEvent)` callsites remaining: only inside `CEAState::BuildHaltEvent` and `CPendingMachineRegistry::EmitForceClear` — both now populate schema-required fields immediately after.

---

## Accepted Findings — Fixes Applied

### Fix 03.1 + 03.3 — EmitForceClear schema-required fields

**File:** `services/PendingMachineRegistry.mqh`
**Changes:**
- Added private `_IdToMagic(EPendingMachineId)` helper resolving PM_M/T/Q → MAGIC_M/T/Q (210/219/212; others → 0).
- `EmitForceClear` now writes:
  - `event_type = "pending_force_clear"` (matches `trade-journal-schema.yaml` enum verbatim — was `"force_clear"`)
  - `magic = _IdToMagic(id)` (was 0)
  - `symbol = _Symbol` (was "")
  - `triggering_function = StringFormat("PendingMachine_%s_ForceClear", code)` matching schema example line 181 (was "")
**Why:** Round-02 IMPL-044 just locked schema v1; the literal mismatch + empty-required-field combination would make every M/T/Q force-clear record fail JSON Schema validation (jq + yamale strict reading), breaking IMPL-068 force-clear validation downstream.

### Fix 03.2 + 03.8 — EAState halt event payload + testability

**File:** `core/EAState.mqh`
**Changes:**
- Extracted halt-event population into `BuildHaltEvent(JournalEvent &out, event_type, reason, triggering_function, signal_context)` so SelfTest can exercise field population without needing a mock CTradeJournal.
- Both `Halt(reason)` and `TryTransitionToStable(active)` delegate to `BuildHaltEvent`. Required fields populated: `slot_id="system"`, `magic=0`, `symbol=_Symbol`, `event_type ∈ {halt, halt_stable}`, `halt_reason`, `signal_context`, `triggering_function`.
- Extended `SelfTest`: 2 new assertions confirm `BuildHaltEvent("halt", ...)` and `BuildHaltEvent("halt_stable", ...)` populate every schema-required field.
**Why:** ZeroMemory'd records would have written `slot_id=""` + `symbol=""` to every halt/halt_stable record → schema validation reject + NFR-1.6 audit chain broken. SelfTest extension makes Finding 03.2 regression-detectable without violating ADR-002 DI rules.

### Fix 03.4 — Cold-restart `pending_started_bar` recovery

**Files:** `services/StatePersistence.mqh`, `services/PendingMachineRegistry.mqh`
**Changes:**
- Added `int CStatePersistence::GetPmStartedBar(EPendingMachineId id) const` accessor exposing the persisted bar (was Set-only — fix-round-02 added the Set side via SetPendingPayload's `started_bar` arg).
- `CPendingMachineRegistry::LoadFromState` now restores `m_machines[i].pending_started_bar = m_state.GetPmStartedBar(id)` (was hard-zeroed).
- Comment rewritten to reflect actual ADR-008 soft-timeout semantics (was misdescribing the broken behavior as desired).
- Added SelfTest Case 7 — persists PM_M with `started_bar=2000`; fresh registry at bar 2050 (age=50 < 150) must remain PENDING; at bar 2151 (age=151) must force-clear exactly once. Pre-fix: instant force-clear at bar 2050.
**Why:** Pre-fix bug: `age = current_bar - 0 = ~850000` → instant force-clear of every M/T/Q PENDING machine on every cold restart, with bogus `pending_force_clear` journal flood. NFR-3.3 (100% field restore) was being violated indirectly.

### Fix 03.6 — TradeJournal sustained-failure self-halt

**Files:** `domain/IHaltSink.mqh` (NEW), `core/EAState.mqh`, `services/TradeJournal.mqh`
**Changes:**
- New `domain/IHaltSink.mqh`: pure abstract interface with `virtual void Halt(string reason) = 0` — breaks circular include (EAState already includes TradeJournal).
- `CEAState : public IHaltSink` (existing `Halt(string)` method satisfies the contract).
- `CTradeJournal` gains `IHaltSink *m_halt_sink` member + `SetHaltSink(IHaltSink*)` setter (pre/post `Init()` order both work; NULL-safe).
- `HandleWriteFailure` now invokes `m_halt_sink.Halt("journal_write_fail_sustained")` exactly when `m_consecutive_failures == JOURNAL_HALT_THRESHOLD` (== check prevents repeated firing once threshold crossed).
**Why:** ADR-006 RPO contract says ≥10 consecutive failures → halt EA. Pre-fix path counted but never escalated; the deferred-ac-registry row for IMPL-043 noted this gap — now self-halt path is wired and the registry row is updated to reflect that only the live Tester end-to-end demo remains deferred.

### Fix 03.5 — indicator_snapshot Deferred-AC promotion

**Files:** `services/TradeJournal.mqh` (comment only), `docs/state/deferred-ac-registry.md`
**Changes:**
- Replaced misleading "valid empty object for scaffold" header with explicit pointer to the new Deferred-AC row + ADR-004 rationale (CMarketContextBuilder::Build returns by value per tick; Orchestrator must cache snapshot before TradeJournal can read it).
- New registry row: `IMPL-043 / indicator_snapshot subset / [contract-roundtrip]` (expires 2026-05-17 alongside the existing IMPL-043 RPO row).
**Why:** Option B (Deferred-AC) is more honest than Option A (Current() accessor). Adding `MarketContextBuilder::Current()` would change ADR-004 single-tick snapshot semantics; correct fix is at Composition Root (IMPL-018+). Stub returns `"{}"` — schema-valid, no parse error — until then.

### Fix 03.7 — CPendingForce escape-aware ExtractStr

**File:** `services/PendingMachineRegistry.mqh`
**Changes:**
- Inlined Round-02.5 fix verbatim into `CPendingForce::_ExtractStr`: backslash-aware terminator scan (closing `"` must NOT be preceded by an odd number of `\`), then full unescape pass for `\" \\ \n \r \t \uXXXX`.
- Comment now explicitly notes the duplication is intentional (per ADR-012 self-contained helper rule) AND mirrors StatePersistence's algorithm.
**Why:** Forward-compat hazard: if a future schema extension allows escape sequences in the `origin` field, the naive matcher would silently truncate. Option A (shared `helpers/JsonReader.mqh`) was rejected in favor of Option B (inline copy) to honor the existing "self-contained" comment intent and avoid introducing a new helper file for a single string-extract pattern; comment cross-references StatePersistence so future readers find both.

### Fix 03.9 — IMPL-052 / IMPL-049 boot-cold E-AC promotion

**File:** `docs/state/deferred-ac-registry.md`
**Changes:**
- 3 new registry rows opened (all expire 2026-05-17, owner: Kritsana):
  - `IMPL-052 / cold restart with HALTED + 0 portfolio / [boot-cold]`
  - `IMPL-049 / 8 machines survive restart with payload + force_clear_count / [boot-cold]`
  - `IMPL-049 / pending_force_clear journal record schema-valid on disk / [file-blob-check]`
**Why:** Aligns IMPL-052 + IMPL-049 closure with the Empirical Closure Discipline glossary entry. Pragmatic per Round 02 standing rule (header-only `.mqh` precedent allows SelfTest as proxy). All three rows retire when IMPL-018+ Orchestrator wires the AtomicFile/journal chain end-to-end.

### Fix 03.10 — Journal latency p99 ratio

**File:** `services/TradeJournal.mqh`
**Changes:**
- `TrackLatency` now scans the 10-write ring after each insert; warns only when `overshoot_count >= 2` (~>10% tail) so single transient overshoots don't spam the Logger.
- Warn message now reports `overshoots=N/10` along with latest latency.
**Why:** Pre-fix path warned on every single >5ms write — opposite of NFR-2.2's "p99 within 5 ms over 10-write window" semantic. Antivirus or disk-cache hiccups would flood the Logger.

### Fix 03.11 — Drop dead `port` arg from TickMachine/TickAll

**File:** `services/PendingMachineRegistry.mqh`
**Changes:**
- Dropped `CPortfolioState &port` from `TickMachine` and `TickAll` signatures.
- Removed dead branch `if(port.GetByMagic(0) == NULL && id == PM_COUNT) return;` (the `id == PM_COUNT` predicate was structurally impossible per the bounded loop).
- Updated 9 SelfTest call sites; deleted unused `port_stub` variable + Init call.
- `m_portfolio` member preserved for future P3 slot-driven hooks (set via Init only).
**Why:** Round 02 Finding 02.7 fix philosophy (drop unused params) re-applied. Orchestrator wiring at IMPL-018+ now has one fewer arg to pass.

---

## State Reconciliation

### Layer 1 — `docs/state/impl-plan.md`
- IMPL-043 / IMPL-049 / IMPL-052 task ACs unchanged at the `[x]` level (closure was already structural per Round 02 precedent); 3 new Deferred-AC rows formalize the boot-cold gap that fix-round-03 Finding 03.9 surfaced.

### Layer 2 — `docs/state/overview.md`
- Code Review row updated to reflect Round 03 + Fix Round 03 closure.

### Layer 3 — `docs/state/current_handoff.md`
- New "Last completed action" entry pointing to `fix-round-03.md` + `deferred-ac-registry.md` deltas.

### Layer 4 — `docs/state/deferred-ac-registry.md`
- IMPL-043 RPO row text updated (self-halt now wired in TradeJournal; only end-to-end demo deferred).
- 3 new Active rows: IMPL-043 indicator_snapshot, IMPL-052 cold-restart, IMPL-049 boot-cold + file-blob-check.

---

## Compile Evidence (G1 — all 4 spike harnesses)

| Spike target                          | Result                                       |
|---------------------------------------|----------------------------------------------|
| `Spike_PendingMachineRegistry.mq5`    | `Result: 0 errors, 0 warnings, 1495 ms`     |
| `Spike_StatePersistence.mq5`          | `Result: 0 errors, 0 warnings, 1331 ms`     |
| `Spike_EAState.mq5`                   | `Result: 0 errors, 0 warnings, 879 ms`      |
| `Spike_TradeJournal.mq5`              | `Result: 0 errors, 0 warnings, 1288 ms`     |

G2/G3/G4 deferred per header-only `.mqh` precedent (entry `.mq5` lands at IMPL-018+; gates activate then).

---

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 11 |
| Accepted | 11 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 4 source + 1 registry |
| New Files | 1 (`domain/IHaltSink.mqh`) |
| Tests Added | 1 SelfTest case (PMR Case 7 cold-restart) + 2 SelfTest assertions (EAState BuildHaltEvent halt/halt_stable variants) |
| Deferred-AC rows opened | 4 (all expire 2026-05-17) |

**Recommendation:** Ready for next Code Review round trigger (after IMPL-018+ Orchestrator lands and exercises the new IHaltSink wire). Fixes do not block P2 Phase Gate — they retire schema-contract drift that would have blocked IMPL-068 and operator-restart safety; the 4 Deferred-AC rows formalize the structural-vs-empirical gap so the registry surfaces them during Phase Gate drain.
