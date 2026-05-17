# ADR-014 — CircuitBreaker BR-3.6 ping-pong dedup by position_id + event_type

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-17 |
| **Deciders** | Engineer (IMPL-FIX-012 iter-3) |
| **Supersedes** | n/a — extends ADR-013 (ADR-013 stays in force; this ADR adds two more defense layers at the detector) |
| **Related** | ADR-010 (HALTED matrix), ADR-011 (ErrorBypassThrottle), ADR-013 (DEAL_REASON_EXPERT filter), BR-3.6 (ping-pong spec) |
| **Goal trace** | G2, BR-3.6, NFR-5.1, Open Risks R-3 (NFR-1.1 acceptance signal blocker) |

## Context

ADR-013 (IMPL-FIX-012 iter-1, 2026-05-14) added a `DEAL_REASON_EXPERT` filter at `core/Orchestrator.mqh::OnTradeTransaction` to skip broker-driven closures (`DEAL_REASON_SL/TP/SO/ROLLOVER/etc.`) so they no longer feed `CircuitBreaker.RecordClose`. This eliminated the false-positive halt class observed in IMPL-062 Run #2 (2026-05-12) and Run #3 (2026-05-14) — two H BUY positions with identical SL=1.21311 hitting the broker SL on the same tick at sim 2021-01-14 14:59:21 (two close deals at Δ=0s, same magic=205, same direction=1 → CircuitBreaker fired ping-pong on broker-driven action).

**IMPL-FIX-012 iter-2 Run #4 (2026-05-17) reached past the Jan-14 storm point but halted 13 sim days later at sim 2021-01-27 15:45:07 via a NEW ping-pong false-positive class**:

- Same Slot_H magic=205, but **dir=0 (was-SELL)** (vs Run #2/#3 dir=1)
- All close deals carried `DEAL_REASON_EXPERT` (so ADR-013's filter passed them)
- Journal evidence (`_session-handoff/IMPL-FIX-012-iter2-run4-20260517.jsonl`): the exit record immediately after the halt cites `triggering_function:"OrderGroupStartWorkflow", comment:"safe_port"`. SafePort is a cross-slot mass-close helper that batch-closes 2+ positions on the same tick when avg_bad_pip > 55 + currentProfit > 0 (per BR-8.1 / `services/CrossSlotCoordinator.mqh::RunSafePort`).
- 11 of 56 exits in Run #4's 27-sim-day window were `triggering_function:"OrderGroupStartWorkflow"` + 1 was `"ForceCutloss"` — these xslot helpers legitimately close multiple same-magic-same-direction positions on the same tick.

**Two false-positive classes confirmed empirically:**

| Class | Trigger | Sim timestamp | DEAL_REASON | ADR-013 filter result | ADR-014 detector result |
|-------|---------|---------------|-------------|------------------------|--------------------------|
| **Broker-driven SL same-tick** (Run #2/#3) | EURUSD hits 1.21311 → tickets 71+72 BUY both stop out same tick | 2021-01-14 14:59:21 | `DEAL_REASON_SL` | ✅ filtered at producer (never reaches RecordClose) | n/a (already filtered) |
| **EA-driven mass-close same-tick** (Run #4) | SafePort closes 2+ Slot_H SELL positions same tick | 2021-01-27 15:45:07 | `DEAL_REASON_EXPERT` (EA-side close via RiskManager.CloseOrder) | ❌ passes filter (EA-driven) | ✅ skipped by ADR-014 rule (b) (same event_type) |

**ADR-013's Alternatives § Option C ("ticket-deduplication via position_id") was rejected during iter-1** with rationale "more complex than needed; DEAL_REASON filter is more surgical." Run #4 empirically falsifies that rejection: the surgical filter is necessary but not sufficient. Option C (extended to also track event_type) is the structurally correct fix.

**Additional discovery during iter-3 design**: `RecordOpen` was never invoked by any caller in the production codebase (grep confirms: `m_breaker.RecordClose` is called at `Orchestrator.OnTradeTransaction:858`; `m_breaker.RecordOpen` has zero call sites). The ring buffer therefore only ever contained close events, and the detector's "rapid same-magic-same-dir events" heuristic was unable to distinguish (close A, close B) — mass-close — from any other pattern. True ping-pong detection (rapid close+reopen alternation) was structurally impossible.

## Decision

**Extend the BR-3.6 detector with two new dedup rules + wire `RecordOpen`** at the same producer-side surface that already feeds `RecordClose`.

### Schema change (CircuitBreaker.mqh)

The ring buffer struct gains two fields:

```mql5
struct TradeEvent {              // was CloseEvent (renamed for semantic clarity)
   int      magic;
   int      direction;           // position direction: 1=was-BUY / 0=was-SELL
   datetime time_s;              // was close_time_s (renamed since opens write here too)
   ulong    position_id;         // NEW (ADR-014) — MT5 position id
   int      event_type;          // NEW (ADR-014) — EVT_OPEN (0) / EVT_CLOSE (1)
};
```

`CCircuitBreaker::RecordOpen(magic, direction, time, position_id)` and `RecordClose(magic, direction, time, position_id)` both now take `position_id` and write `event_type = EVT_OPEN` / `EVT_CLOSE` respectively.

### Detector rule change (CheckPingPong)

`CheckPingPong()` adds two skip conditions BEFORE the delta-threshold check:

```mql5
// Rule (b) — skip same-event_type pairs
//   close+close = mass-close helper batch (false positive class Run #4)
//   open+open   = legitimate pyramid/scaling
if(m_buffer[i].event_type == m_buffer[j].event_type)
   continue;

// Rule (c) — skip same-position pairs
//   open A + close A = legitimate intraday scalp / quick exit
//   not ping-pong even at delta=0s
if(m_buffer[i].position_id == m_buffer[j].position_id)
   continue;
```

Combined with the pre-existing rule (a) "same (magic, direction)" and rule (d) "delta ≤ 3 s", the detector now fires halt **only** when:
- Same (magic, direction)
- **Different event_type** (one EVT_OPEN, one EVT_CLOSE)
- **Different position_id** (different MT5 position)
- |delta| ≤ 3 s

This is the canonical "rapid close+reopen on same magic+dir but different position" pattern that BR-3.6 was originally designed to catch.

### Producer-side change (Orchestrator.mqh::OnTradeTransaction)

The DEAL_ENTRY filter is broadened from `DEAL_ENTRY_OUT` only to `DEAL_ENTRY_IN || DEAL_ENTRY_OUT`. Opens dispatch to `RecordOpen`, closes dispatch to `RecordClose`. Both extract `position_id` from `HistoryDealGetInteger(deal, DEAL_POSITION_ID)`. Direction mapping inverts for closes (DEAL_TYPE_SELL closes a BUY) but is direct for opens (DEAL_TYPE_BUY opens a BUY) so the in-ring `direction` field consistently encodes position direction.

The ADR-013 `DEAL_REASON_EXPERT` filter is preserved as a defense-in-depth: it ensures broker-driven deals never reach the ring at all, so ADR-014's detector logic only deals with EA-driven events.

### SelfTest extension (Case G + Case H)

Two new SelfTest cases validate the dedup rules:

- **Case G**: 2 close events on same `(magic=205, dir=0)` at delta=0s but DIFFERENT position_ids ⇒ NO fire (mass-close false-positive class regression test; would fire pre-ADR-014).
- **Case H**: 1 open + 1 close on SAME `position_id` at delta=0s ⇒ NO fire (intraday scalp false-positive class regression test).

Existing Cases A-E are rewritten to use realistic open+close patterns (Case A: close A + open B same magic+dir within 1s = canonical ping-pong; was: 3 closes 1s apart pre-ADR-014).

## Alternatives Considered

### Option α — Producer-side filter by triggering_function

Filter at `OnTradeTransaction` based on which xslot helper drove the close (`SafePort` / `OrderGroupStartWorkflow` / `ForceCutloss` / `ExtraCheckFunction2`).

**Rejected.** Requires plumbing internal `triggering_function` metadata from `CrossSlotCoordinator` through `RiskManager.CloseOrder` → MT5 `OrderSend` → into `OnTradeTransaction`'s deal lookup. MT5 deal metadata doesn't carry our internal triggering_function string. A workaround would be setting a per-tick latch in CrossSlotCoordinator ("if last close on (magic,dir) was via mass-close helper") and checking it in OnTradeTransaction — but this is racy (multiple xslot helpers fire in sequence within one tick) and fragile (silently breaks if a new helper is added without updating the denylist). Also fails as a future-proofing concept: in production live trading, mass-close scenarios could happen via paths outside our enumerated helper list (broker margin call, weekend gap stop-out cascade, manual operator close from GUI) — position_id-based dedup catches all of them; triggering_function denylist catches only what we know about.

### Option β — Disable BR-3.6 detector entirely

Comment out the `CheckPingPong` call from `Orchestrator.OnTick` and accept loss of the safety net.

**Rejected.** Loses the legitimate detection capability for true EA ping-pong (a real malfunction class that BR-3.6 was designed to catch per spec). Better to fix the detector than abandon it.

### Option γ — Tighten threshold to delta=0s exact + mass-close-tag

Halt only when delta = exactly 0 (sub-second simultaneous) AND we can identify the cluster as not coming from a mass-close helper.

**Rejected.** Same plumbing complexity as Option α. Also weakens the detector for true ping-pong scenarios that operate at 1-3s cadence (a malfunctioning strategy doesn't have to ping-pong at exactly 0s; 2s cadence is also pathological).

### Option δ — Per-magic latch in CircuitBreaker that absorbs the second-and-subsequent close of a same-tick batch

When close N+1 arrives on (magic, dir) within tick of close N, silently drop close N+1.

**Rejected.** Same problem as Option α (need to identify "batch" vs "ping-pong"). Also conflicts with the genuine ping-pong signature where rapid close N + close N+1 is exactly what we want to detect (if they're on DIFFERENT positions and there was an OPEN between them).

## Consequences

**Positive:**
- ✅ Eliminates the EA-driven mass-close false-positive halt class (IMPL-FIX-012 iter-2 Run #4 Jan-27 regression).
- ✅ Preserves ADR-013 broker-driven SL false-positive elimination (Run #2/#3 Jan-14 class).
- ✅ Enables true ping-pong detection that was structurally impossible pre-ADR-014 (RecordOpen wiring activated).
- ✅ Eliminates legitimate-scalp false-positive class (open+close on same position at delta=0s no longer fires).
- ✅ Position_id-based dedup is future-proof: works for ALL mass-close paths (xslot helpers, broker actions, manual ops) without enumerating helper list.
- ✅ Schema bump is internal — no downstream contract change (CircuitBreaker is intra-process, no external consumers).

**Negative / risk:**
- ⚠️ Ring buffer event volume doubles (now includes opens) — 16-slot ring fills faster; oldest events may be evicted before pairing. Mitigation: 16 events at H4 cadence covers ≥ 64 H4 bars of history (months of sim time), still ample for the 3-5s ping-pong detection window.
- ⚠️ `RecordOpen` is now wired for the first time in production — pre-ADR-014 it was dormant; opening flows now have a new logging surface emit (Debug level, low noise).
- ⚠️ SelfTest schema change requires all 8 cases to be re-validated on first G1 compile. Compile error in any case = pre-deploy block.

**Migration / backward compatibility:**
- `state.json` schema unchanged (CircuitBreaker state is in-memory only).
- Journal records schema unchanged.
- No ADR rollback path needed — ADR-013 stays in force; ADR-014 is additive.

**Falsification triggers (would force ADR-014 revisit):**
- iter-3 G3 5-yr Run #5 reaches sim 2025-12-31 + drift > 25% on a DIFFERENT halt class → ping-pong was not the blocker.
- iter-3 G3 5-yr Run #5 still fires `circuit_breaker_pingpong` at some later sim point → the dedup rule has another gap (cap-3 escalation: `/impl-plan-review all` or `/backtrack sd`).
- True ping-pong scenario (e.g., predicate bug causing rapid close+reopen) silently passes the new dedup → rule (b)/(c) are too lax; revisit threshold or add a 4th rule on event-count-in-window.

## Validation Plan

1. **G1 compile** — `MetaEditor64.exe /compile:PhoenicisNex.mq5 /log` → expect `0 errors, 0 warnings`. Schema change to TradeEvent + new constants must compile clean.
2. **G2 bootstrap_smoke 3-day** — `terminal64.exe /config:bootstrap_smoke.ini` → expect `successfully finished` + no `ping_pong` events in Tester log + behavioral parity vs iter-1 G2 baseline (final balance, slot counts).
3. **G2 SelfTest exercise** — OnInit SelfTest sequence (if ENABLE_SELFTEST) should emit Case A-H pass/fail markers; expect 8/8 PASS.
4. **G3 5-yr Run #5** — `terminal64.exe /config:regression_5yr_g4.ini` → expect EA reaches ≥ 3 sim months past 2021-01-14 (= past 2021-04-14) without any `circuit_breaker_pingpong` halt. If reaches 2025-12-31 → check Bucket A drift ≤ 25% (NFR-1.1). Deferred to next operator session (~40 min wall-clock per IMPL-FIX-009 perf baseline).

## References

- ADR-013 § Alternatives § Option C — rejected rationale that this ADR falsifies
- IMPL-FIX-012 task block in `docs/state/impl-plan.md` (iter-1 + iter-2 + iter-3 status)
- `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-20260517.jsonl` — Run #4 journal (127 records)
- `docs/state/_session-handoff/IMPL-FIX-012-iter2-run4-blocked-20260517.md` — Run #4 narrative + falsification analysis
- BR-3.6 spec — `docs/ba/04 § BR-3.6 ping-pong detector` (3000 ms threshold; near-miss 5 s)
- `services/CrossSlotCoordinator.mqh::RunSafePort` — BR-8.1 mass-close helper that produced the iter-2 false-positive
- `services/CircuitBreaker.mqh` — current detector implementation (ADR-014 schema)
- `core/Orchestrator.mqh::OnTradeTransaction` — producer-side filter chain (NFR-5.3 symbol + magic-range + ADR-013 reason + ADR-014 DEAL_ENTRY_IN/OUT branching)

## Revisit-when

- iter-3 G3 Run #5 reveals a third false-positive halt class → revisit detector design (consider 4-event minimum, time-bucketed counting, or BR-3.6 spec amendment via `/backtrack ba`).
- Phase 2 multi-symbol / multi-account / netting-mode broker support → DEAL_ENTRY_INOUT (netting partial close + reverse) handling needed; current OUT-or-IN branching is hedging-mode-only per C-5.
- If True ping-pong is observed in production live trading and ADR-014 dedup catches it correctly → harvest as a sanity check; if it MISSES a true case → add 4th rule (event-count-in-window minimum).
