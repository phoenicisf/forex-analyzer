# Code Review Round 19

| Field | Value |
|-------|-------|
| **Round** | 19 |
| **Target** | `all` — operator invoked `/impl-review all` after fix-round-18 closure. Cumulative source tree under `MQL5/Experts/PhoenicisNex/` + `simulation/headless-tests/`. HEAD = `44ac477`. Working tree at session start: clean. |
| **Date** | 2026-05-05 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | (a) Fix-round-18 §18.1 sweep aftermath — replacement-token integrity + next-coarser-granularity recurrence check (R12→R13→R14→R16→R18→**R19**) on closed-task forward-pointer comments; (b) IMPL-FIX-003 structural pre-drain artifacts (`PhoenicisNex_TickLatencyProbe.mq5` + `tick_latency_smoke.ini`) reproducibility; (c) Cross-service consistency of fix-round-18 §18.6 ulong-counter promotion (TickLatencyProbe vs TradeJournal); (d) Dim #11 Empirical AC Closure spot-check on fix-round-18 G2-G4 deferral. |
| **Plan Staleness Sentinel** | 0 closures since R09 (no IMPL-NNN closures landed since fix-round-18; this is an immediate successor advisory). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 2 |
| LOW      | 1 |
| **Total**| **5** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | Symbol whitelist intact; wrapper `PhoenicisNex_TickLatencyProbe.mq5` delegates to `g_orchestrator.OnInit()` so symbol guard inherited. No new `WebRequest`/DLL/`#import`. Sidecar now writes UTF-8 via `FILE_BIN` (fix-round-18 §18.7 applied). Fallback `Logger.Info("journal_latency_report_inline", body)` does not leak credentials (body = NFR-2.2 metrics only). |
| 2 | Business Logic Correctness | ✅ Pass | TickLatencyProbe `_EmitOneLineSummary` periodic emit now 1 Logger.Info (not 9); `FinalEmit` unchanged at OnDeinit. TradeJournal sidecar gating, FILE_BIN encoding, inline fallback all correct. Wrapper `.mq5` delegates 5 entry points to the same Orchestrator instance — runtime-equivalent to production build except for `ENABLE_TICK_LATENCY` define. |
| 3 | Error Handling | ✅ Pass | Sidecar `FileOpen` failure now emits both Warn (path + errcode) AND Info (full JSON body) — operator can recover via `jq -R 'fromjson?'` from Experts log. NULL-logger guards present. |
| 4 | Performance | ✅ Pass | XS-17.1 hot-path rule consistently applied across both instruments post-fix-18: periodic emit = 1 Logger.Info; full report = OnDeinit / Close only. |
| 5 | Over-Engineering | ✅ Pass | Wrapper file is 62 LOC of pure delegation — no new logic. Smoke `.ini` follows TD-02 §13.3 standard block. |
| 6 | Cross-Service Consistency | ⚠️ Finding | **19.3 MEDIUM** — fix-round-18 §18.6 promoted `TickLatencyProbe::m_count` / `m_idx` / `m_tick_count` int → ulong but the same defect class survives unchanged in `services/TradeJournal.mqh`: `m_latency_count` declared `int` (line 89) accumulated by `m_latency_count++` per WriteEvent (line 535) — 5-yr Tester at ~216k entry_signal events is comfortably under INT_MAX, but multi-yr stress / dense-tick smoke runs cross the same boundary the §18.6 fix neutralised on the sister instrument. Inconsistent application of a project-wide rule across two services in the same fix-round. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **19.4 MEDIUM** — `tick_latency_smoke.ini` lacks an `[TesterInputs]` block pinning the morning-window / holiday-block / Monday-spread time-gate inputs. The structural-half assertion `n[entry_pass] < n[refresh]` (per-fix-round-18 §18.5 plan) presumes those gates fire at least once in the 3-day window, but if an operator inherits MT5 default inputs OR a stale `.set` file disables the gates (`InpUseMorningBlock=false` etc.), entry runs every tick → `n[entry_pass] == n[refresh]` → false-fail. Reproducibility contract per TD-02 §13.6 ("every test run pins to a committed `.ini`") is broken — input pinning is the missing half. |
| 8 | Architecture Compliance | ✅ Pass | Wrapper `.mq5` lives at the same level as production entry point; both are thin delegates over `COrchestrator`. ADR-001 single-process invariant preserved. |
| 9 | Technical Design Compliance | ✅ Pass | TickLatencyProbe header §Scope block enumerates 8 timed + 6 omitted steps with TD-02 §7.2 citation (R17 §17.6 closure intact post-§18 edits). |
| 10 | Test Code Quality | ✅ Pass | No regex / unbounded loop pathology. Insertion-sort 200-element bound retained. |
| 11 | Empirical AC Closure | ⚠️ Finding | **19.5 LOW** — fix-round-18 deferred G2-G4 verification of all 7 fixes despite landing two new artifacts (`PhoenicisNex_TickLatencyProbe.mq5` + `tick_latency_smoke.ini`) that exist solely to enable structural-half drain in ≤30 min. The §18.5 plan was authored to break the "deferred-to-operator-runtime" anti-pattern at IMPL-065 — but the fix-round itself then deferred running its own drain. Wrapper compile (G1) PASSED 0/0/4100 ms but no G3 evidence yet shows the wrapper actually emits `[ev=tick_latency_report]` under tick load. |
| 12 | Functional CRUD walk | ⏭ Skip | PhoenicisNex has no GUI surface; Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1 callout. The `tick_latency_smoke.ini` IS the walk-batch-3 surface — pending operator session. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret consumer. |

---

## Findings

### Finding 19.1: 🟠 HIGH — Fix-round-18 §18.1 sweep replacement token `<closed; ref purged fix-round-18 §18.1>` is itself a forward-pointer to an audit document, not a routing decision — 128 occurrences across 41 files lose all routing information that the original "wires at IMPL-NNN" comments at least intended to convey.

**Location:**
- 128 hits across 41 files; representative sites:
  - `services/PortfolioState.mqh:176` — `s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at <closed; ref purged fix-round-18 §18.1>`
  - `services/RiskManager.mqh:295` — `// last_open_lot populated by PortfolioState OnTradeTransaction handler at <closed; ref purged fix-round-18 §18.1>;`
  - `core/BootstrapValidator.mqh:102, 584` — `(Owner: <closed; ref purged fix-round-18 §18.1> / IMPL-062.)`
  - `domain/EnumTypes.mqh:118` — `<closed; ref purged fix-round-18 §18.1> / IMPL-062 owner: Orchestrator::OnInit Phase B`
  - `slots/Slot_B.mqh:267` — `m_risk.CloseOrder(ticket) wires at <closed; ref purged fix-round-18 §18.1>`
  - `slots/Slot_BI.mqh:276` (per fix-round-18 §18.1 attestation) — same pattern
  - `slots/Slot_J.mqh`, `slots/Slot_BR.mqh`, `slots/Slot_F.mqh`, ..., `spike/Spike_Slot_B.mq5`, `spike/Spike_Slot_BR.mq5`, `spike/Spike_Slot_BI.mq5` — 128 sites in total
- Service: ea (cross-cutting; 41 source files)
- Reference: review-round-18 §18.1 Suggested Fix step 2 ("for each hit, route to the correct currently-pending task: ... 'wires at IMPL-063 (Bucket B regression) OR deferred to operator-runtime per deferred-ac-registry.md row IMPL-063-broker-close' ... if handler now exists in COrchestrator, point to that file:line; if still TODO, register a Pending row in operator-action-registry.md and cite it"); CLAUDE.md §6 "comments must point to live tracked work"; `andm-impl-engineer/SKILL.md § Empirical Closure Discipline`

**Code:**
```mql5
// services/PortfolioState.mqh:176
      s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at <closed; ref purged fix-round-18 §18.1>

// services/RiskManager.mqh:295
   //    last_open_lot populated by PortfolioState OnTradeTransaction handler at <closed; ref purged fix-round-18 §18.1>;

// slots/Slot_B.mqh:267
         //--- Phase-1 stub: m_risk.CloseOrder(ticket) wires at <closed; ref purged fix-round-18 §18.1>

// core/BootstrapValidator.mqh:584
//|     before ValidateSymbol. (Owner: <closed; ref purged fix-round-18 §18.1> / IMPL-062.)     |
```

**Problem:**
Review-round-18 §18.1 was raised because comments pointing to closed tasks (IMPL-017, IMPL-053+, IMPL-062) became "lies" — a future engineer following the breadcrumb hits a dead end. The Suggested Fix prescribed three concrete routing options for every hit: (a) point to the currently-pending task that carries the work, (b) point to a Pending row in `operator-action-registry.md`, (c) annotate that no writer exists + register `IMPL-NEW-NNN`. Fix-round-18 §18.1 instead chose a fourth option not in the spec: blanket-replace with `<closed; ref purged fix-round-18 §18.1>` — a token whose only referent is the fix-round narrative itself.

This produces **strictly worse audit signal** than the pre-fix state in three ways:

1. **Lost routing information.** The original comment "broker close wires at IMPL-017 / IMPL-062" said *something specific* (even if false post-closure). The new comment says only "this used to point somewhere — fix-round-18 deleted the pointer". A future engineer reading `services/PortfolioState.mqh:176` "populated by OnTradeTransaction at `<closed; ref purged fix-round-18 §18.1>`" cannot determine: (i) where the OnTradeTransaction handler actually lives now (`COrchestrator::OnTradeTransaction` per fix-round-10 §10.3), (ii) whether the writer exists or is still TODO, (iii) which task tracks the outstanding work. They must open `docs/code-review/review-round-18.md` and back-deduce — but review-round-18 §18.1 itself just says "route to the correct currently-pending task" without listing the routings, so the trail dead-ends in audit history.

2. **Confounds the very Gate #9c "audit history preserved" exemption.** Phase 5 Gate #9c whitelists hits in audit-history files (`docs/code-review/*`, `docs/state/_session-handoff/*`) as legitimate preservation of historical decisions. By coining a new token that **embeds the fix-round name in the source comment itself**, fix-round-18 promoted 128 source-tree sites into permanent self-citations of audit history — so any future Gate #9c "intent grep" must now distinguish "real audit-history file" from "source file with audit-history-shaped token". The replacement string structurally violates the live-source-vs-audit-history boundary the gate was designed to enforce.

3. **Recurrence-chain regression.** R12→R13→R14→R16→R18 each caught the previous round's sweep being scope-narrower than the defect class (literal phrase → broader regex → repo-wide → verb-form catalog). R18 §18.1 fix is the FIRST round in the chain to introduce a *new* defect class (synthetic placeholder token in source) while purporting to clean up the old one. The recurrence chain now has a sixth iteration: R19 catches the synthetic-token class that R18-fix introduced.

`services/PortfolioState.mqh:176` `s.last_open_lot = 0.0` is the canonical example. The original comment claimed a writer at IMPL-053+; that was false post-closure. The replacement now says the comment's pointer was "purged" — but `last_open_lot` is still zero-initialised here and **still has no writer in the codebase**. The defect (no writer) is not addressed; only the breadcrumb is destroyed.

**Why This Matters:**
The whole point of review-round-18 §18.1 was to restore the audit-trail integrity claim of `andm-impl-engineer/SKILL.md § Empirical Closure Discipline`. Engineers must be able to trust that "deferred to <task>" comments point to the task carrying the work. The replacement token does the opposite: it explicitly tells the reader "this comment used to point somewhere; we deleted the destination". 128 instances permanently embed a self-defeating audit message in the source tree.

Gate #9 clause (c) "PASS under 'preserved as audit history' exemption" was the closure rationale — but that exemption is for files **that are themselves audit history** (review-round-NN.md, fix-round-NN.md, _session-handoff/*). Live `.mqh` source files are **not** audit history; they are the artifact under audit. By landing the audit token *into* the artifact, fix-round-18 conflated the two domains.

**Suggested Fix:**
Re-execute the §18.1 sweep with the proper routing per the original Suggested Fix. For each of the 128 sites, classify into one of three bins:

```bash
# bin 1 — writer exists at a known site (e.g. COrchestrator::OnTradeTransaction post-fix-round-10):
#   replace token with "see core/Orchestrator.mqh::OnTradeTransaction (fix-round-10 §10.3)"
#
# bin 2 — operator action required (env-var / set-file / out-of-band step):
#   register a Pending row in docs/state/operator-action-registry.md;
#   replace token with "Pending: see operator-action-registry.md row OAR-NNN"
#
# bin 3 — no writer + no Pending action; field is genuinely zero-initialised forever:
#   delete the misleading provenance comment entirely + add explicit "default zero; no writer in Phase 1"
#   note (one line) so the reader does not search for a phantom writer
```

Then run Gate #9 verification with the replacement-token regex itself as a forbidden pattern:

```bash
# Must return 0 hits in source tree (audit-history files excluded per Gate #9c):
grep -rcnE "<closed; ref purged" MQL5/Experts/PhoenicisNex/  # → 0
```

Also extend `.claude/rules/workflow.md § Phase 5 Gate #9` clause (d) verb-form catalog with an explicit ban: "fix-round sweeps that reference closed tasks MUST NOT introduce a synthetic placeholder token in source files; replacement must route to either (a) live tracked work, (b) Pending OAR row, or (c) explicit 'no writer' note. Token containing a fix-round-NN reference embedded in source = automatic Gate #9 fail."

**Level of Effort:** Medium (mechanical re-sweep + per-site routing decision; ~2-3 hours wall-clock for 128 sites; per-site choice between bin 1/2/3 is the bulk of the time; no compile risk — comments only).

---

### Finding 19.2: 🟠 HIGH — Bare `IMPL-053` (without `+`/`/IMPL-062`/`..060` suffix) and other closed-task references survive the fix-round-18 §18.1 sweep — 94 occurrences across 31 files. Same R12→R18 next-coarser-granularity recurrence pattern: token catalog enumerated 5 specific variants and missed the bare-token variant.

**Location:**
- 94 hits across 31 files; representative sites:
  - `services/CrossSlotCoordinator.mqh:8` — `// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1).`
  - `services/CrossSlotCoordinator.mqh:53,281,679` — bare `IMPL-053`
  - `services/CircuitBreaker.mqh:15,91,194` — `(IMPL-053) wires the actual EAState::SetHalted(reason)`
  - `services/Logger.mqh:148-149` — `Full orchestrator init_ok emitted by Orchestrator (IMPL-053) which calls Logger.Info("system","init_ok",0,"...") — deferred until IMPL-053.`
  - `core/Orchestrator.mqh:22` — `IMPL-053 banner pattern):`
  - `core/SlotRegistry.mqh:16,78` — `pre-IMPL-053 Orchestrator harness` / `future IMPL-053 Orchestrator wiring`
  - `core/BootstrapValidator.mqh:12` — `G1 deferred to IMPL-018+ per IMPL-042` (TWO closed-task refs in one comment)
  - `helpers/JsonWriter.mqh:242` — `is deferred to orchestrator/journal-write runtime (IMPL-043+)`
  - `services/IndicatorService.mqh:300` — `Full implementation deferred to IMPL-006 (MarketContextBuilder)`
  - `services/PortfolioState.mqh:87` — `Body deferred to IMPL-007-getticketsforslot (uses CommentParser)`
  - `services/PortfolioMonitor.mqh:206` — `Full [db-inspect] E-AC deferred to IMPL-018+ orchestrator wiring`
  - `slots/Slot_B.mqh:107,271`, `slots/Slot_BR.mqh`, `slots/Slot_GO.mqh`, `slots/Slot_G2.mqh`, `slots/Slot_G.mqh` — bare `IMPL-053` / `IMPL-062` / `IMPL-018+` references
- Service: ea (cross-cutting; 31 source files)
- Reference: `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` — closed-task forward-pointer verb catalog must cover EVERY verb form × separator form × parenthetical form; fix-round-18 attestation table listed only 5 token variants; impl-plan.md TL;DR confirms IMPL-053..060, IMPL-006, IMPL-007, IMPL-018, IMPL-042, IMPL-043 ALL CLOSED 2026-05-02..05

**Code:**
```mql5
// services/CrossSlotCoordinator.mqh:8 — file header
// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1).

// services/CircuitBreaker.mqh:15
//|    (IMPL-053) wires the actual EAState::SetHalted(reason) call.  |

// services/Logger.mqh:148-149
   // Full orchestrator init_ok emitted by Orchestrator (IMPL-053) which
   // calls Logger.Info("system","init_ok",0,"...") — deferred until IMPL-053.

// core/BootstrapValidator.mqh:12
//|          isolation — G1 deferred to IMPL-018+ per IMPL-042        |

// helpers/JsonWriter.mqh:242
   //|   is deferred to orchestrator/journal-write runtime (IMPL-043+) |

// services/IndicatorService.mqh:300
//|   Full implementation deferred to IMPL-006 (MarketContextBuilder) |

// services/PortfolioMonitor.mqh:206
//| Full [db-inspect] E-AC deferred to IMPL-018+ orchestrator wiring |
```

**Problem:**
Per `docs/state/impl-plan.md` TL;DR + Phase Status Snapshot, the following tasks are ALL CLOSED:
- **IMPL-006** MarketContextBuilder (P1; closed 2026-05-02)
- **IMPL-007** GetTicketsForSlot (P2; closed)
- **IMPL-018** CSlotBase (P3; closed 2026-05-03)
- **IMPL-042** PortfolioMonitor stub (P1; closed)
- **IMPL-043+** journal-write runtime (P2 IMPL-043; closed)
- **IMPL-053** CrossSlotCoordinator::RunSafePort (P4; closed 2026-05-04)
- **IMPL-062** Bucket A regression (P4; closed 2026-05-05)

Yet the source tree carries 94 stale forward-pointer comments to these closed tasks. Fix-round-18 §18.1 applied a 5-token catalog (`IMPL-017 / IMPL-062`, `IMPL-017/IMPL-062`, `IMPL-017 + IMPL-062`, `IMPL-053..060`, `IMPL-053+`) and verified Gate #9a/b/c/d returned 0 hits — but the Gate #9d catalog never included:

- bare `IMPL-053` without `+` (CrossSlotCoordinator.mqh, CircuitBreaker.mqh, Logger.mqh, Orchestrator.mqh, SlotRegistry.mqh — 18+ sites)
- `IMPL-006` (IndicatorService.mqh)
- `IMPL-007-getticketsforslot` (PortfolioState.mqh)
- `IMPL-018+` (BootstrapValidator.mqh, PortfolioMonitor.mqh, CSlotBase.mqh)
- `IMPL-042` (BootstrapValidator.mqh)
- `IMPL-043+` (JsonWriter.mqh)

The fix-round-18 attestation grep `IMPL-053\+\|IMPL-053\.\.060` literally cannot match `IMPL-053` (no suffix) or `IMPL-006` etc. — the regex was written to match the cited sites in review-round-18 §18.1, not the defect class "any closed-task forward-pointer".

This is the **sixth iteration** of the recurrence chain — exactly the failure mode `.claude/rules/workflow.md § Phase 5 Gate #9 clause (b)/(c)/(d)` was added to detect (R14, R16, R18 each strengthened the catalog after a narrower-than-class miss). Fix-round-18 added clause (d) but populated it with an enumeration of FIVE specific tokens — not a regex matching the defect class. Today's miss = the "verb-form × separator-form × parenthetical-form catalog" advertised in `.claude/rules/workflow.md` is a closed enumeration in practice; in 24 hours the next-coarser variant always emerges (`IMPL-NNN` bare, or `(IMPL-NNN)`, or `IMPL-NNN+` for a NEW closed task).

**Why This Matters:**
This is not a one-off cleanup miss — it is a structural failure of the fix-round-18 sweep approach (token catalog) to enforce the Gate #9 promise (defect class). Every future task closure will reintroduce the defect: when IMPL-063 closes, every comment "deferred to IMPL-063" instantly becomes stale, and the catalog-based sweep cannot anticipate the new token.

The proper enforcement pattern is a **dynamic regex** parameterised by `git log --all --grep='\[feat:\|fix:\|refactor:' --pretty=format:'%H'` or by a closed-task list synthesised from `impl-plan.md` Phase Status Snapshot. fix-round-18 §18.1 narrative claimed the chain was "broken at the defect-class level" — but the chain is broken only insofar as the literal phrases R12-R18 cited; the defect class (any closed-task forward-pointer) survives.

**Suggested Fix:**

Two-stage repair:

```bash
# Stage 1 — derive the closed-task list from impl-plan.md (currently 30+ closed):
grep -oE 'IMPL-0[0-9]{2}' docs/state/impl-plan.md \
  | sort -u > /tmp/closed-impl-tasks.txt

# Stage 2 — for each closed task, grep the source tree:
for task in $(cat /tmp/closed-impl-tasks.txt); do
  grep -rnE "(deferred to|wires at|wired at|wire at|populated by .*at|future|pre-) ?\(?${task}\b" \
    MQL5/Experts/PhoenicisNex/
done

# Stage 3 — for each hit, apply the routing decision per Finding 19.1 fix
#   (live ref / Pending OAR / explicit 'no writer' note).
```

Replace fix-round-18's token-catalog approach in `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` with the dynamic-regex approach: "Gate #9d MUST run against the **current** closed-task list as derived from `impl-plan.md` Phase Status Snapshot — not against a hand-enumerated token catalog. After every task closure, the closure commit MUST sweep its task ID's forward-pointer comments using the broader-class regex `(deferred to|wires? at|wired at|populated by .* at|pre-|future|gated on|until|tracked at) ?\(?<TASK-ID>\b`."

**Level of Effort:** Medium (~2 hours; bin-3 routing for most sites; rule update).

---

### Finding 19.3: 🟡 MEDIUM — `services/TradeJournal.mqh::m_latency_count` retains `int` typing while sister instrument `services/TickLatencyProbe.mqh::m_count[]` was promoted to `ulong` in the same fix-round (§18.6) — same defect class, two services, fix applied to one. Inconsistent project-wide rule application.

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`, Lines: 87-89 (field declarations), 535 (increment), 594 (modulo periodic trigger), 608, 631, 661, 663, 664 (StringFormat / WriteInt sites)
- File: `MQL5/Experts/PhoenicisNex/services/TickLatencyProbe.mqh`, Lines: 70-87 (post-§18.6 ulong promotion)
- Service: ea (journal + instrumentation)
- Reference: review-round-18 §18.6 + fix-round-18 §18.6 narrative ("Defensive typing is cheap and removes a long-tail measurement-corruption risk that would only surface on a stress run no one tests for"); CLAUDE.md §6 "consistency across services"

**Code:**
```mql5
// services/TradeJournal.mqh:87-89 — UNCHANGED by fix-round-18 §18.6
   ulong                  m_latency_total_us;   // ← ulong
   ulong                  m_latency_max_us;     // ← ulong
   int                    m_latency_count;      // ← int (overflow surface)

// services/TradeJournal.mqh:535 — increment
   m_latency_count++;

// services/TradeJournal.mqh:594 — periodic trigger
   if(m_latency_count % 1000 == 0)
      EmitLatencyReport();

// services/TradeJournal.mqh:612 — divide path uses ulong cast
   ulong avg_us = m_latency_total_us / (ulong)m_latency_count;
   //                                  ^^^^^^^                  ← cast hides overflow

// Compare services/TickLatencyProbe.mqh:81 (POST-§18.6 fix):
   ulong   m_count[TLPROBE_STAGE_COUNT];   // ← promoted by fix-round-18 §18.6
```

**Problem:**
Fix-round-18 §18.6 explicitly raised the int-overflow surface on `TickLatencyProbe::m_count[]` and promoted it to `ulong` with the rationale "5-yr Model=4 every-tick backtest ≈ 100-300M ticks × 8 stages ≈ 1.6B per stage". The exact same arithmetic applies to `TradeJournal::m_latency_count`: every `WriteEvent` invocation calls `TrackLatency` which increments the counter once. Walk-batch-2 captured ~216,671 `entry_signal` events alone in a 3-day window; a 5-yr regression scaled linearly is ~130M `entry_signal` events plus equal volume of exit/halt/init events ≈ 250M+ writes. Within an order of magnitude of INT_MAX (~2.1B); 10-yr stress crosses the boundary.

Once `m_latency_count` overflows to negative, line 612 `m_latency_total_us / (ulong)m_latency_count` casts negative to a near-`ULONG_MAX` divisor — exactly the defect that fix-round-18 §18.6 narrated as the reason to promote in TickLatencyProbe. Promoting one and not the other is inconsistent application of a project-wide rule across two services that landed in the same fix-round.

The fix is mechanically identical to §18.6: promote the field + the increment + the modulo + the StringFormat specifier (`%d` → `%llu`). 5-line diff at most.

**Why This Matters:**
The same audit-trail-integrity argument that justified fix-round-18 §18.6 ("defensive typing is cheap and removes a long-tail measurement-corruption risk") applies symmetrically. Asymmetric application means the "cheap defense" is now a half-defense, and a future stress run will surface the bug in TradeJournal where it doesn't surface in TickLatencyProbe — leaving the operator to debug a measurement-instrument bug in the very instrument they thought fix-round-18 hardened.

This is also a Gate #9-class miss: fix-round-18 §18.6's Suggested Fix said "≈10 type changes + format-string fixes" *for TickLatencyProbe*; the engineer applied to TickLatencyProbe alone and did not extend the rule. A Gate #9 broader-class verification ("for every `int m_*_count` field in `services/*Latency*.mqh` OR `services/*Probe*.mqh` OR `services/TradeJournal.mqh`, verify ulong typing") would have caught it at fix-round-18 commit time.

**Suggested Fix:**

```mql5
// services/TradeJournal.mqh:87-89 — promote
   ulong                  m_latency_total_us;
   ulong                  m_latency_max_us;
   ulong                  m_latency_count;   // was int

// services/TradeJournal.mqh:122-124 — initializer list update
   m_latency_total_us(0),
   m_latency_max_us(0),
   m_latency_count((ulong)0),

// services/TradeJournal.mqh:608, 612 — comparisons / divides
   if(m_latency_count == 0)
      return;
   ulong avg_us = m_latency_total_us / m_latency_count;  // cast no longer needed

// services/TradeJournal.mqh:594 — periodic
   if(m_latency_count % 1000 == 0)   // (ulong % int = ulong; OK)

// services/TradeJournal.mqh:630-631, 661 — format specifiers
   m_logger.Info(..., StringFormat("writes=%llu avg_us=%llu p95_us=%llu max_us=%llu",
                                    m_latency_count, avg_us, p95_us, m_latency_max_us));
   w.WriteInt("writes", (long)m_latency_count);   // CJsonWriter.WriteInt takes long

// services/TradeJournal.mqh:639-641 — per-event-type rows (m_evtype_counts[] also int)
//   Optional: extend ulong promotion to m_evtype_counts[], m_evtype_total_us[] for symmetry.
```

Then update `.claude/rules/workflow.md § Phase 5 Gate #9` with a sub-clause: "type-promotion fixes in instrumentation (latency probes / journals / metrics) MUST be applied to all peer instruments in the same fix-round; a peer-instrument grep is part of the post-fix verification."

**Level of Effort:** Low (~10 LOC + format-string updates; G1 catches missed sites).

---

### Finding 19.4: 🟡 MEDIUM — `simulation/headless-tests/tick_latency_smoke.ini` lacks an `[TesterInputs]` block pinning the morning-window / holiday-block / Monday-spread time-gate inputs — the fix-round-18 §18.5 structural-half assertion `n[entry_pass] < n[refresh] AND n[entry_pass] > 0` is non-reproducible if the operator inherits MT5 default inputs or a stale `.set` file.

**Location:**
- File: `simulation/headless-tests/tick_latency_smoke.ini` (NEW; commit `44ac477`)
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5:30` — `#define ENABLE_TICK_LATENCY 1` (correct)
- Reference: TD-02 §13.6 reproducibility contract ("every test run pins to a committed `simulation/headless-tests/<name>.ini`"); fix-round-18 §18.5 plan step 5 ("Confirm n[entry_pass] < n[refresh] AND n[entry_pass] > 0")

**Code:**
```ini
; simulation/headless-tests/tick_latency_smoke.ini — full body
[Tester]
Expert=PhoenicisNex\PhoenicisNex_TickLatencyProbe
Symbol=EURUSD
Period=H4
Model=4
Optimization=0
FromDate=2024.01.02
ToDate=2024.01.05
Deposit=1000
Leverage=500
ShutdownTerminal=1
Visual=0
;
; ← NO [TesterInputs] BLOCK
;   No InpUseMorningBlock, InpUseHolidayBlock, InpUseMondaySpreadGate pinning.
;   Operator inherits whatever .set file is most-recently active in MT5.
```

**Problem:**
The structural-half assertion specifically requires the morning-window / holiday-block / Monday-spread gates to FIRE during the 3-day window — that's the entire point of the assertion `n[entry_pass] < n[refresh]`. The `.ini` doesn't pin the gating inputs, so the assertion contract is operator-environment-dependent:

- If operator's `Inputs_TimeGates.mqh` defaults have `InpUseMorningBlock = true` (likely default per CodeWiki §3) → assertion fires → PASS
- If operator has a stale `.set` file with `InpUseMorningBlock = false` → entry runs every tick → `n[entry_pass] == n[refresh]` → false-FAIL
- If operator runs on a fresh-clone where MT5 has never persisted defaults → MT5 may inject zero/null inputs → undefined behaviour

TD-02 §13.6 reproducibility contract says: "every test run pins to a committed `simulation/headless-tests/<name>.ini`; never invoke ad-hoc Tester params". The pin must include the inputs that determine the assertion outcome.

Compare to existing pinned `.ini` files in the repo: `simulation/headless-tests/regression_5yr_no_g4.ini` (IMPL-062) does NOT pin inputs either — but its assertion is "compare aggregate Net Profit", not "exercise a specific gate". `bootstrap_smoke.ini` pins via the operator's known-good runtime defaults — but bootstrap is a smoke test for `[ev=init_ok]`, not a per-gate observation.

`tick_latency_smoke.ini` is the only `.ini` in the repo whose **PASS criterion depends on a specific input being a specific value**. That input must be in `[TesterInputs]`.

**Why This Matters:**
Fix-round-18 §18.5 was authored *specifically* to break the operator-runtime defer cycle on IMPL-065 — the wrapper + `.ini` are supposed to land a 30-min reproducible drain. If the drain is non-reproducible (different `.set` file → different result), the §18.5 promise is broken: an operator who runs the `.ini` and sees `n[entry_pass] == n[refresh]` will conclude the post-fix-17.2 code has a regression, when in fact the test config is at fault. The next debugging round adds another fix-round, not a closure.

**Suggested Fix:**

```ini
; simulation/headless-tests/tick_latency_smoke.ini — append at bottom
[TesterInputs]
;
; Pin time-gate inputs to ensure morning_block fires at least once
; (post-fix-round-17 §17.2 invariant n[entry_pass] < n[refresh]).
;
InpUseMorningBlock=true      ; gate must fire per nfr-2.1-tick-latency.md
InpMorningBlockStartHour=0
InpMorningBlockEndHour=3
InpUseHolidayBlock=true
InpUseMondaySpreadGate=true
InpUseStateRestore=false     ; force cold-bootstrap so first OnInit produces baseline
;
; Pin the symbol whitelist (NFR-5.3) — also the magic numbers if any
; downstream invariants test specific magic values.
```

Operator doc update: `nfr-2.1-tick-latency.md § Verification Protocol` should reference this `.ini` and note "all time-gate inputs are pinned in `[TesterInputs]`; the operator MUST NOT override via the Tester GUI". Also commit a `tick_latency_smoke.set` companion if MT5 supports per-`.ini` `.set` chaining.

**Level of Effort:** Low (~15 lines `.ini` append + 3-line note in `nfr-2.1-tick-latency.md`).

---

### Finding 19.5: 🔵 LOW — fix-round-18 deferred G2-G4 of all 7 fixes despite landing two new artifacts (`PhoenicisNex_TickLatencyProbe.mq5` + `tick_latency_smoke.ini`) whose entire purpose is to enable a 30-min structural-half drain — the fix-round did not run its own drain, leaving IMPL-065 paired E-AC structural half empirically unverified.

**Location:**
- File: `docs/code-review/fix-round-18.md`, Lines: 178-186 (G1-G4 verification table; G2-G4 deferred)
- File: `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5` (NEW; G1 PASS 0/0/4100 ms)
- File: `simulation/headless-tests/tick_latency_smoke.ini` (NEW)
- File: `docs/state/deferred-ac-registry.md` IMPL-065 row (updated with structural-half plan; row Active)
- Reference: review-round-18 §18.5 ("the structural pre-drain SHOULD execute pre-operator-session, not be itself deferred"); CLAUDE.md §1 Three-Tier Closure Convention

**Problem:**
Review-round-18 §18.5 was raised because fix-round-17 deferred G2-G4 with a "no production-runtime change" rationale that left an instrument-correctness fix (17.2 STAGE_ENTRY moved inside entry-gate) empirically unverified. R18 §18.5 prescribed IMPL-FIX-003 as the structural pre-drain that breaks the defer cycle.

Fix-round-18 then:
- ✅ Authored the wrapper `.mq5` (G1 PASS 0/0/4100 ms)
- ✅ Authored the smoke `.ini`
- ✅ Updated the deferred-AC registry row with the drain plan
- ❌ **Did not run G3** — the plan stays a plan; the wrapper + `.ini` exist but no `[ev=tick_latency_report]` log line yet exists post-fix-17.2

Per `andm-impl-engineer/SKILL.md § Empirical Closure Discipline`, the structural-half drain CAN close in 30 min via the assets fix-round-18 just authored — the time-cost argument that justified deferring G2-G4 of *the other 6 findings* (no production-runtime change) does not apply to the IMPL-FIX-003 artifacts whose purpose IS empirical exercise. Deferring G3 of IMPL-FIX-003 specifically reproduces exactly the anti-pattern review-round-18 §18.5 was raised to break.

LOW (not MEDIUM) because (a) the wrapper compiles cleanly so the structural-instrument contract is half-validated, (b) the operator session can absorb the drain in batch-3, (c) the registry row honestly carries the "structural pre-drained YYYY-MM-DD" placeholder reminding the operator to land the drain. But the "compresses operator drain from ~3h to ~10min" promise of §18.5 is half-realised: the wrapper + `.ini` exist but the 10-min drain was not executed.

**Why This Matters:**
The closure-discipline argument R18 §18.5 made was "fix-round-17 deferred verification of an instrument-correctness fix to operator session" — fix-round-18 has now landed the assets to break that defer but has not actually broken the defer. If the operator session further slips, the instrument's correctness remains unverified for an additional cycle.

**Suggested Fix:**
Run G3 + grep + jq on `tick_latency_smoke.ini` BEFORE closing review-round-19. Concrete commands per `tick_latency_smoke.ini` step 1-5:

```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/tick_latency_smoke.ini /tmp/tick_latency_run.txt

iconv -f UTF-16LE -t UTF-8 \
  "$DATA_DIR/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$(date +%Y%m%d).log" \
  | grep -E "tick_latency_(report|periodic)" \
  > /tmp/tick_latency_grep.txt

# Assert ≥1 final_deinit emit:
grep -c "trigger=final_deinit" /tmp/tick_latency_grep.txt   # expect >= 1

# Parse per-stage table:
grep tick_latency_report /tmp/tick_latency_grep.txt \
  | grep -oE "stage=[a-z_]+ n=[0-9]+" | sort -u

# Assert n[entry_pass] < n[refresh] AND n[entry_pass] > 0 (the §17.2 contract):
N_REFRESH=$(grep "stage=refresh" /tmp/tick_latency_grep.txt | grep -oE "n=[0-9]+" | head -1 | cut -d= -f2)
N_ENTRY=$(grep "stage=entry_pass" /tmp/tick_latency_grep.txt | grep -oE "n=[0-9]+" | head -1 | cut -d= -f2)
[[ $N_ENTRY -lt $N_REFRESH && $N_ENTRY -gt 0 ]] && echo PASS || echo FAIL
```

Then close the structural half of IMPL-065 paired E-AC `[x]` and update the registry Active row to "structurally pre-drained 2026-05-05; numeric drain pending operator session".

**Level of Effort:** Low (~10 min wall-clock + 1 jq + 1 registry edit).

---

## Cross-Service Issues

| ID | Severity | Pattern | Affected Files | Note |
|----|----------|---------|----------------|------|
| XS-19.1 | 🟠 HIGH | Synthetic-placeholder-token in source comments — fix-round-18 §18.1 sweep introduced a NEW defect class (audit-history token embedded in source) while purporting to clean up the OLD class | 41 source files; 128 occurrences of `<closed; ref purged fix-round-18 §18.1>` | Sixth iteration of the R12→R18 chain. Token-catalog approach in `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` is closed-enumeration; defect class is open-set. Suggest replacing with dynamic regex parameterised by closed-task list from `impl-plan.md` Phase Status Snapshot. |
| XS-19.2 | 🟠 HIGH | Bare closed-task forward-pointer comments — fix-round-18 §18.1 token catalog enumerated 5 specific variants, missed bare `IMPL-053` / `IMPL-006` / `IMPL-007-getticketsforslot` / `IMPL-018+` / `IMPL-042` / `IMPL-043+` | 31 source files; 94 occurrences | Same root cause as XS-19.1. Catalog-vs-class scope drift. |
| XS-19.3 | 🟡 MEDIUM | Asymmetric type-promotion of int counters across peer instrumentation services in the SAME fix-round | `services/TickLatencyProbe.mqh` (promoted by §18.6) vs `services/TradeJournal.mqh::m_latency_count` (left as int) | Add Phase 5 Gate sub-clause: "type-promotion fixes in instrumentation MUST sweep peer instruments in the same fix-round". |
| XS-19.4 | 🟡 MEDIUM | Test-config reproducibility — assertion-bearing `.ini` files MUST pin the inputs that determine the assertion outcome | `simulation/headless-tests/tick_latency_smoke.ini` lacks `[TesterInputs]` block | Add `.claude/rules/testing.md § Test Execution Safety` rule: "assertion-bearing `.ini` files MUST contain `[TesterInputs]` block pinning every input that affects the asserted invariant". |

---

## Summary Table

| # | Finding | Severity | File:Line | Service | Fix size |
|---|---------|----------|-----------|---------|----------|
| 19.1 | Fix-round-18 §18.1 synthetic-placeholder token `<closed; ref purged fix-round-18 §18.1>` loses routing information; 128 occurrences across 41 files | 🟠 HIGH | repo-wide; representative: `services/PortfolioState.mqh:176`, `services/RiskManager.mqh:295`, `core/BootstrapValidator.mqh:102,584`, `domain/EnumTypes.mqh:118`, `slots/Slot_B.mqh:267`, `slots/Slot_BI.mqh:276` | ea (cross-cutting) | M (mechanical re-sweep + per-site bin-1/2/3 routing; ~2-3h) |
| 19.2 | Bare `IMPL-053` / `IMPL-006` / `IMPL-007` / `IMPL-018+` / `IMPL-042` / `IMPL-043+` forward-pointer comments survive §18.1 sweep; 94 occurrences across 31 files | 🟠 HIGH | repo-wide; representative: `services/CrossSlotCoordinator.mqh:8,53,281,679`, `services/CircuitBreaker.mqh:15,91,194`, `services/Logger.mqh:148-149`, `core/BootstrapValidator.mqh:12`, `helpers/JsonWriter.mqh:242`, `services/IndicatorService.mqh:300`, `services/PortfolioMonitor.mqh:206` | ea (cross-cutting) | M (dynamic-regex sweep + rule update; ~2h) |
| 19.3 | `services/TradeJournal.mqh::m_latency_count` retains int while sister `TickLatencyProbe::m_count[]` was promoted ulong by §18.6 — asymmetric application | 🟡 MEDIUM | `services/TradeJournal.mqh:87-89, 535, 594, 612, 630-631, 661` | ea | Low (~10 LOC + format-string updates) |
| 19.4 | `tick_latency_smoke.ini` lacks `[TesterInputs]` block pinning time-gate inputs — fix-round-18 §18.5 assertion non-reproducible across operator environments | 🟡 MEDIUM | `simulation/headless-tests/tick_latency_smoke.ini` | ea-qa | Low (~15-line `.ini` append) |
| 19.5 | fix-round-18 deferred G3 of its own IMPL-FIX-003 artifacts despite the artifacts existing solely for 30-min structural-half drain | 🔵 LOW | `docs/code-review/fix-round-18.md:178-186` + `simulation/headless-tests/tick_latency_smoke.ini` + `MQL5/Experts/PhoenicisNex/PhoenicisNex_TickLatencyProbe.mq5` | ea-qa | Low (1 G3 + 1 jq + 1 registry edit; ~10 min) |
| **Cross-Service Total** | | | | | |
| XS-19.1 | Synthetic-placeholder-token defect class | 🟠 HIGH | 41 files, 128 sites | ea | (covered by 19.1) |
| XS-19.2 | Bare closed-task forward-pointer next-coarser variant | 🟠 HIGH | 31 files, 94 sites | ea | (covered by 19.2) |
| XS-19.3 | Asymmetric type-promotion across peer instrumentation services | 🟡 MEDIUM | TradeJournal vs TickLatencyProbe | ea | (covered by 19.3) |
| XS-19.4 | Assertion-bearing `.ini` files missing `[TesterInputs]` pin | 🟡 MEDIUM | tick_latency_smoke.ini | ea-qa | (covered by 19.4) |

**Recommendation:** Ready for **fix-round-19**. Priority order:

1. **Finding 19.1 (HIGH)** — re-sweep the 128 synthetic-placeholder tokens with proper routing per the original review-round-18 §18.1 Suggested Fix; the fix-round-18 §18.1 closure shortcut (blanket-replacement) introduced a worse defect class than it cleaned up. Block IMPL-063 closure until clean.
2. **Finding 19.2 (HIGH)** — extend Gate #9d from token catalog to dynamic regex parameterised by closed-task list from `impl-plan.md`; sweep the 94 bare-token sites.
3. **Findings 19.3 + 19.4 (MEDIUM)** — surgical: TradeJournal int→ulong + tick_latency_smoke.ini `[TesterInputs]` block. Both small.
4. **Finding 19.5 (LOW)** — execute the IMPL-FIX-003 G3 drain that fix-round-18 authored but did not run.

> **Reviewer note (Dim #11 Empirical AC Closure spot-check):** Findings 19.1 + 19.2 themselves expose the audit-trail-integrity argument that `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` rests on. The R12→R18 chain claimed to be "broken at the defect-class level" by fix-round-18 §18.1 narrative; R19 demonstrates that the chain was broken only at the literal-token level. The defect-class-level break requires the dynamic-regex enforcement proposed in Finding 19.2 Suggested Fix. Until that lands, the chain will iterate to R20+.

> **Plan Staleness Sentinel post-R19:** unchanged from R09 (no IMPL-NNN closures since fix-round-18; this is the immediate successor advisory). Sentinel resets on next P4 closure (IMPL-063).

## End of Review Round 19
