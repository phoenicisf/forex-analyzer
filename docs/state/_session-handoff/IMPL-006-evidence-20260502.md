# IMPL-006 Evidence — MarketContextBuilder per-tick snapshot

| Field | Value |
|---|---|
| Task | IMPL-006 [M] [ea] — services/MarketContextBuilder::Build() per-tick snapshot |
| Closed | 2026-05-02 |
| Commit | 2a3a3ff `[feat:ea] IMPL-006 — MarketContextBuilder per-tick snapshot (ADR-004)` |
| Phase | P1 — Foundation |
| Closure mode | Parallel batch via `/impl-task parallel` (orchestrator: Opus 4.7; subagent: Sonnet 4.6) |
| Shared-context | `docs/state/_parallel-context/impl-task-parallel-20260502-2326.md` |

## File created

- `MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh` (NEW, 584 LOC)
  - `class CMarketContextBuilder` per TD-02 §5.2 skeleton
  - 24 `IDX_*` constants mirrored at top per shared-context §6.B.3 option 3 (IndicatorService's IDX_* are private)
  - `Init(CIndicatorService *ind, CLogger *lg)` — DI per ADR-002 (Logger added beyond TD-02 §5.2 skeleton, per shared-context §6.B.1 note)
  - `Build() const → MarketContext` — populates all 25 top-level fields (5 primitives + 19 sub-structs + 1 derived)
  - 13 PopulateX private helpers (Ichimoku, Force, Adx, Wpr, BB, Dem, Stoch, Macd, Rsi, Hull, Fractal, ZigZag, SubDem) — each calls `ArraySetAsSeries(buf, true)` before `CopyBuffer` with degrade-but-continue on short copies
  - 4 derived helpers (`ComputeWprWaveSignal` / `ComputeAdxForcePeakValid` / `ComputeIchiDoubleBounce` / `ClassifyForcePeak`) — placeholder heuristics tagged `// PLACEHOLDER IMPL-006 — refine in P3 slot integration` per shared-context §6.B.6

## Static checks (G1-G4 deferred — header-only .mqh per IMPL-005/007/015/042 precedent)

| Check | Command | Result |
|---|---|---|
| Class declaration | `grep -E '^class CMarketContextBuilder' services/MarketContextBuilder.mqh` | 1 line ✅ |
| No #import | `grep -c '#import' services/MarketContextBuilder.mqh` | 0 ✅ (NFR-7.2) |
| Include guard | `grep -E '^#ifndef PHOENICISNEX_SERVICES_MARKETCONTEXTBUILDER_MQH' …` | 1 line ✅ |
| Method skeleton | `grep -E 'public:\|MarketContext Build\|ComputeWprWaveSignal\|ComputeAdxForcePeakValid\|ComputeIchiDoubleBounce\|ClassifyForcePeak' …` | matches TD-02 §5.2 ✅ |
| LOC budget | `wc -l services/MarketContextBuilder.mqh` | 584 ≤ 800 services budget ✅ |

## S-AC closure

- [x] `Build()` returns `MarketContext` by value (copy semantics; ADR-004 ~720 bytes acceptable) — method signature `MarketContext Build() const` confirmed by grep
- [x] All struct fields populated (none left default-zero) — all 25 top-level fields assigned in Build(); sub-struct helpers populate every member with degrade-but-continue on CopyBuffer short
- [x] `derived` block computed from raw fields (no DRY violation) — Compute* helpers read `ctx.*` fields after primary populate; no duplicate CopyBuffer calls in derived path

## E-AC deferral (per Empirical Closure Discipline — cite blocking task)

- [ ] Stub indicator fail (`Symbol="INVALID"`) → Build returns sentinel + Logger Warn `[log-assertion]` — **deferred to IMPL-018+ + IMPL-053+** (entry .mq5 prerequisite for G2 Smoke + Strategy Tester; AnyHandleInvalid guard branch present in Build())
- [ ] Run smoke test → log emit one tick's `MarketContext` shape via Logger Debug → assert all fields non-default `[log-assertion]` — **deferred to IMPL-018+ + IMPL-053+** (entry .mq5 + Orchestrator OnTick wiring prerequisite)

Closure citation matches IMPL-005/007/015/042 precedent (specific blocking task ID, not "deferred to operator-runtime" — Code Review Dim #11 compliant).

## Risk note

- Placeholder derived signal heuristics are intentional and budget-bounded — slot tasks IMPL-019..039 own the runtime correctness validation via their own E-ACs.
- Logger pointer additional to TD-02 §5.2 skeleton — extension justified by ADR-002 + ea.md DI rule (services that emit logs must receive CLogger* via constructor); engineer follow-up not needed.

## Suggested next task

IMPL-010 (closed in same batch); P1 17/17 reached → P1 Phase Gate becomes nominate-able.
