# P2 Phase Gate — Nomination + IMPL-049 Closure Attestation

| Field | Value |
|-------|-------|
| Date | 2026-05-03 |
| Phase | P2 — Core Services + EAState + Pending |
| Tier 1 status | ✅ 11/11 tasks `[x]` |
| Tier 1.5 status | ⏸ blocked on IMPL-018+ runnable surface |
| Tier 2 status | 🟡 **Nominated** — see Row-by-Row Assessment below |
| Code review | ✅ Round 04 closed — 0 CRITICAL / 0 HIGH (fix-round-04.md, 2026-05-03) |
| Operator | Kritsana |

---

## Row-by-Row Phase Gate Assessment

> Source: `docs/state/impl-plan.md` § P2 Phase Gate (lines 553-561). 8 mandatory rows.

| # | Phase Gate Row | Status | Evidence / Blocker |
|---|----------------|--------|--------------------|
| 1 | **Structural Acceptance** — 11 P2 tasks `[x]` + G1 = 0/0 ทุก service file + 17-magic invariant `BootstrapValidator.ValidateSlotRegistry(observed=17, expected=17)` returns true on dry-run | ✅ **Ready** | All 11 P2 tasks `[x]` (TL;DR line 5). G1 = 0/0 verified post-Round-04 fix on 4 spike harnesses (PMR 1495 / SP 1331 / EAState 879 / TJ 1288 ms — see `fix-round-04.md` § Compile Evidence). 17-magic dry-run = inherited from IMPL-016 ValidateSymbol body (header-only verification — full Validate runs at IMPL-018+) |
| 2 | **Empirical Demo** — smoke EA attaches; OnInit Phase B 16 Init() + 2 setter; `[ev=init_ok]`; sample journal `init_ok` validates schema; state.json round-trip preserves cached fields. Evidence: `_session-handoff/2026-MM-DD-phase2-evidence.md` | ❌ **Blocked** | No entry `PhoenicisNex.mq5` exists (`ls MQL5/Experts/PhoenicisNex/` = 8 dirs, 0 .mq5). Composition Root + Orchestrator wiring delivered by **IMPL-018+** (P3). Header-only `.mqh` files cannot self-attach. Round-trip primitives **structurally** verified via spike SelfTest (StatePersistence Spike + PMR Case 6 round-trip) |
| 3 | **Tier 1.5 Exploratory Walk** — 30-min headless walk via `simulation/headless-tests/p2_services_smoke.ini` (60-day, no slots active). Artifact: `_session-handoff/2026-MM-DD-phase2-exploratory-walk.md` | ❌ **Blocked** | `p2_services_smoke.ini` does not exist (only bootstrap/atomic-kill/eastate/state-persistence/tradejournal/timegate spike inis present). Walk requires runnable EA with full Init Phase B chain → IMPL-018+ |
| 4 | **Live-stack health** — kill EA mid-write → restart → `state.json` loads cleanly + `[ev=state_loaded]` `[boot-cold]`; manual journal monthly rotation triggered + new file `[file-blob-check]` | ❌ **Blocked** | Same root cause as #2 — no attachable EA. Algorithm itself proven 100/100 in IMPL-046 atomic-write spike (`OPTION_A_LOCKED` per ADR-007 § Spike Result); rotation logic verified in IMPL-043 G3 (`run-20210104-000000-000.jsonl` 200 records). Live boot-cold demo deferred to IMPL-018+ |
| 5 | **Code review** — no CRITICAL/HIGH open | ✅ **Ready** | Round 04 closed 2026-05-03 — 8/8 accept; 0 CRITICAL / 0 HIGH residual; anti-regression sweep all 0 hits (`fix-round-04.md`). Round 03 corrigendum embedded |
| 6 | **NFR check** — NFR-3.1 atomic write provisional ≥ 99/100; NFR-2.2 journal write p95 ≤ 5 ms (200 events) | ✅ **Provisional Pass** | NFR-3.1 = **100/100** anchor_fails=0 in IMPL-046 spike Phase 2 (full 100/100 rerun in P4 IMPL-064 per plan). NFR-2.2 = 200/200 < 5 ms in IMPL-043 G3 (zero `journal_write_slow` events, latency ratio gate <2/10 per Round 03.10 fix) |
| 7 | **Deferred-AC drain** — `deferred-ac-registry.md § Active` empty for Phase=P2 | ❌ **Blocker (5 rows)** | 5 Active P2 rows opened 2026-05-03, all expire 2026-05-17 — IMPL-043 self-halt log assertion + IMPL-043 indicator_snapshot subset; IMPL-052 cold-restart `[boot-cold]`; IMPL-049 PMR cold-restart `[boot-cold]` + IMPL-049 force-clear journal `[file-blob-check]`. **Every row's "Deferred reason" cites IMPL-018+ Orchestrator wiring** — circular dep with #2/#3/#4 above |
| 8 | **Rollback plan** — revert P2 commits → P1 EA still attaches; `state.json` from P2 testing kept under `state.json.p2backup`; manual MT5 restart + clear state file before P1 retry. Operator: Kritsana | ✅ **Ready** | Already documented in P2 Phase Gate row text (line 560). Revert order: P2 commits in reverse chronological starting `26def2c` → backup any `state.json` → fresh boot. Named operator: Kritsana |
| 9 | **Docs updated** — ADR-007 spike resolution, ADR-008 force-clear thresholds, per-service handoff `_session-handoff/`, `state-persistence-schema.yaml` + `trade-journal-schema.yaml` final-locked | ✅ **Ready** | ADR-007 § Spike Result amended 2026-05-02 (`OPTION_A_LOCKED`); ADR-008 thresholds locked (M=150/T=80/Q=100). Schemas final-locked: state-persistence-schema.yaml v1 (IMPL-048) + trade-journal-schema.yaml v1 (IMPL-044). Per-service evidence: IMPL-{006,010,016,043,044,046,049}-evidence-* present |

**Tally:** 5/9 Ready · 4/9 Blocked (#2, #3, #4 inter-related; #7 separate but circularly-dep on the same root cause).

---

## IMPL-049 Closure Attestation

> Per CLAUDE.md §1 Three-Tier Closure: Tier 1 ✅ + Tier 1.5 deferred + Tier 2 row 7 deferred. This section attests **structural correctness** of IMPL-049 work product as the foundation for empirical closure once IMPL-018+ ships.

### Tier 1 — Task Closure (Structural)

| Aspect | Evidence |
|--------|----------|
| All 4 sub-passes committed | `fe78218` (a) skeleton+payload · `edb3477` (b) legacy timeouts · `8aaaa5b` (c) force-clear · `26def2c` (d) SelfTest 6 cases |
| 4 S-AC `[x]` | impl-plan.md IMPL-049 — 8 machines + dispatch / M/T/Q thresholds = inputs / 5 P-sub-modes / journal event emission proxy via counter |
| 2 E-AC | E-AC #1 stub-M-payload-past-threshold ✅ via SelfTest Case 5 + 7; E-AC #2 round-trip ✅ via SelfTest Case 6 |
| G1 compile | Spike `Result: 0 errors, 0 warnings, 1495 ms` (post-Round-04 fix, 2026-05-03 14:27, mtime confirmed fresh) |
| Code review residual | Round 03 (11 findings) → `fix-round-03.md` 11/11 accept · Round 04 (8 findings) → `fix-round-04.md` 8/8 accept. **0 CRITICAL / 0 HIGH open** as of 2026-05-03 |
| OQ resolution | OQ-A1/A2/A3 (M/T/Q-Pending force-clear) closed via ADR-008 thresholds + EmitForceClear journal record |
| BR coverage | BR-6.1..6.4 + 6.8 legacy timeouts (PM_C/C_ADX/R/P/FORCE) + ADR-008 force-clear (PM_M/T/Q) + P-sub-mode encoding per `state-persistence-schema.yaml § PendingMachineState_PVariant` |

### Tier 1.5 — Exploratory Walk (Deferred — formally tracked)

The Round-04 fix delta strengthened SelfTest coverage:
- **Case 6** +1 RAM/state symmetry assertion (Finding 04.4)
- **Case 7** extended PM_M-only → PM_M (150) + PM_T (80) + PM_Q (100) at-boundary scenarios (Finding 04.8)

These exercise the persisted-side cold-restart path that real Tier 1.5 walks would re-verify when IMPL-018+ entry .mq5 ships. SelfTest is empirically run **at OnInit of each spike** — not a substitute for Tester-driven walk, but provides upstream empirical signal.

### Tier 2 — Phase Gate (Pending)

2 of the 5 Active P2 deferred-AC rows are IMPL-049-specific:

| Active row | E-AC kind | Resolves at | Risk if missed |
|-----------|-----------|-------------|----------------|
| IMPL-049 PMR cold-restart | `[boot-cold]` | IMPL-018+ Orchestrator + Tester boot-cold scenario | PendingMachineRegistry recovery + force-clear timing untested under real boot |
| IMPL-049 force-clear journal record | `[file-blob-check]` | IMPL-018+ `CTradeJournal.Init()` + Tester force-clear scenario | IMPL-068 force-clear validation could break in QA Phase 3T |

Both rows expire **2026-05-17**. Round-04 fixes (04.4 RAM/state symmetry + 04.6 event-driven `pending_age_bars` gate + 04.5 comment maxLength clamp) reduce the surface area on which a real Tester run could fail — but cannot substitute for the run itself.

---

## Recommendation — 3 Paths Forward

### Path A — Phase Gate Override (recommended given circularity)

Log a row in `Phase Gate Override Log` justifying advance to P3 IMPL-018 because the 4 blocked Phase Gate rows (Empirical Demo + Tier 1.5 Walk + Live-stack + Deferred-AC drain) are **all gated by IMPL-018+ itself** — the very task P3 starts with. This is exactly the override scenario CLAUDE.md §6 + Glossary §Phase Gate Blocking permit, with documented operator sign-off.

- **Pros:** unblocks P3; respects audit trail (Override row + Active deferred-AC rows preserved + this nomination doc); P2 Phase Gate **closes** *after* IMPL-018 lands and runs the 4 blocked items in one sweep
- **Cons:** P2 Phase Gate is "open + bypassed" from 2026-05-03 until IMPL-018 ships — registry rows expire 2026-05-17 (renewal once allowed per registry Rule 3b)
- **Operator action required:** sign-off statement + Override row entry

### Path B — Build minimal entry .mq5 stub now (NOT recommended)

Pre-build a thin `PhoenicisNex.mq5` that wires only the 11 P2 services (no slots) and run `p2_services_smoke.ini` against it. This **front-loads IMPL-018** into P2 → violates SD Hint Alignment audit trail (IMPL-018 = P3 = E2 CSlotBase compile prereq).

- **Pros:** Phase Gate closes properly without override
- **Cons:** scope-creep; entry .mq5 then needs rewrite at IMPL-018; bypasses CSlotBase contract sequencing; risks Bucket A behavioral drift via untested orchestrator skeleton

### Path C — Defer Phase Gate decision; renew Active rows on 2026-05-17

Continue building P3 tasks under override implicitly; renew the 5 Active rows once on 2026-05-17 if IMPL-018 hasn't landed. Effectively Path A but without explicit Override row.

- **Pros:** zero docs work today
- **Cons:** silent override violates Phase Gate Blocking discipline (CLAUDE.md §6); Code Review Dimension #11 risk on next sweep; Phase Gate Hallucination risk

---

## Verdict

**Tier 2 = 🟡 Nominated, awaiting operator decision on Path A vs B vs C.**

Engineer side has done all the structural work it can (Tier 1 + Round-03/04 review hygiene + post-fix G1 evidence + nomination doc). **The remaining choice is operator-owned** because:

1. Path A requires explicit Override row authorship (named operator: Kritsana)
2. Path B requires explicit scope expansion authorization
3. Path C is the implicit no-action default but creates audit drift

Defaulting (no operator action) → Path C by attrition, which is the worst outcome. **Recommend Path A.**
