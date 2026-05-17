# ADR-013 — CircuitBreaker BR-3.6 ping-pong scope refinement: DEAL_REASON_EXPERT filter

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-14 |
| **Deciders** | Engineer (IMPL-FIX-012 Step 1) |
| **Goal trace** | G2, BR-3.6, NFR-5.1 (controlled halt), Open Risks R-3 (NFR-1.1 acceptance signal blocker) |

## Context

CircuitBreaker BR-3.6 detects "EA ping-pong" (rapid open + close + open + close cycles on same magic + same direction) and signals halt. The implementation lives at `services/CircuitBreaker.mqh` and is fed via `core/Orchestrator.mqh::OnTradeTransaction` per fix-round-10 §10.3 / D-8 wiring.

**Empirical finding (IMPL-062 Run #3 2026-05-14):** the detector fires false-positives on **legitimate concurrent broker-driven SL fills** of independent positions. Specifically:

- IMPL-062 5-yr Bucket A regression Run #3 (rewrite-G4-ON, BT-001 single-pass methodology) HALTED at sim 2021-01-14 14:59:21 via `circuit_breaker_pingpong` (Slot_H magic=205, dir=1, delta=0s, threshold=3s).
- Run #2 (DISABLE_G4_FIXES build, 2026-05-12) halted at the **byte-identical** sim timestamp with the same halt class.
- Journal evidence (`_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.jsonl`) shows Slot_H entries spaced hours/days apart (NOT sub-second clustered) — Slot_H::Evaluate already enforces same-H4-bar cooldown at line 211.
- Two H BUY positions (tickets 71 + 72 at sim 2021-01-13) with **identical SL=1.21311** (same `bid - InpHSlPips × pip_size` formula) hit the broker SL on the same tick on 2021-01-14 14:59:21 → 2 close deals at Δ=0s with same magic + same dir → CircuitBreaker.RecordClose called twice → CheckPingPong returns true → halt.
- This is **legitimate market behavior**, not pathological EA behavior. Multiple independent positions sharing the same SL price will hit the broker SL simultaneously when price reaches that level.
- Same-timestamp exit pattern empirically observed earlier in same run: tickets 41 + 39 (both SELL) closed at exactly `2021-01-08T20:17:50.000Z` (Δ=0s) per journal records.

**The detector's intent** (per BR-3.6 + ADR-010 + TD-02 §5.8 origin) is to catch **EA-driven runaway loops** — code paths that repeatedly open and close positions on its own initiative (e.g., a broken predicate flapping every tick). It is **not** intended to halt on broker-driven mass SL events that happen to occur on the same tick.

## Decision

**Filter `OnTradeTransaction` → `RecordClose` to only forward deals with `DEAL_REASON_EXPERT`.** Skip broker-driven closures (`DEAL_REASON_SL`, `DEAL_REASON_TP`, `DEAL_REASON_SO`, `DEAL_REASON_ROLLOVER`, `DEAL_REASON_VMARGIN`, `DEAL_REASON_SPLIT`, `DEAL_REASON_CLIENT`/`MOBILE`/`WEB` manual closes).

**Patch surface (~3 LOC):** add one filter line in `core/Orchestrator.mqh::OnTradeTransaction` between the `DEAL_TYPE_BUY/SELL` guard (line 835) and the `direction` derivation (line 842):

```mql5
ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(deal, DEAL_REASON);
// ADR-013: only EA-driven closes feed BR-3.6. Broker-driven SL/TP/SO/rollover/etc.
//   are legitimate market events on independent positions; CircuitBreaker's intent
//   per BR-3.6 + ADR-010 is to detect EA runaway loops, not concurrent SL fills.
if(reason != DEAL_REASON_EXPERT) return;
```

**Threshold preserved:** PING_PONG_THRESHOLD_S stays at 3 (unchanged from BR-3.6 spec). The fix is a scope refinement, not a threshold tune. The 3s window remains tight enough to catch true EA ping-pong (which always operates via DEAL_REASON_EXPERT).

**SelfTest update:** add Case F to `CCircuitBreaker::SelfTest()` documenting the DEAL_REASON_EXPERT filter requirement at the producer side (Orchestrator owns the filter, not CircuitBreaker — CircuitBreaker.RecordClose itself remains agnostic so direct unit tests via SelfTest still work). The SelfTest update is documentation-only inside CircuitBreaker.mqh; the runtime filter lives in Orchestrator.

## Alternatives Considered

### Option A — Threshold tune `3s → 5-10s` (originally documented as IMPL-FIX-012 fallback)
- **Rejected.** Doesn't address the false-positive class; just shifts the window. Still false-positives on >5s gaps if multiple positions stagger their SL hits during a fast price move. Weakens the safety net for true ping-pong (a real ping-pong loop at 4s cadence would now go undetected).

### Option B — Slot_H ManageExits same-bar cooldown (originally documented as IMPL-FIX-012 Step 1)
- **Rejected.** Empirically wrong hypothesis — Slot_H entries are NOT clustered (Run #3 journal shows hour/day gaps); the Δ=0s signal is at exit timestamp from broker-side concurrent SL fills, NOT from EA-side close calls. ManageExits cooldown wouldn't affect broker-side SL triggers.

### Option C — Ticket-deduplication in CircuitBreaker.CheckPingPong
- **Rejected as more complex than needed.** Would require adding `ulong position_id` to CloseEvent struct + threading through RecordClose API + skipping pairs where `position_id_i != position_id_j`. Achieves same semantic outcome as Option D (this ADR's chosen path) but requires schema change to CloseEvent + larger surface. The DEAL_REASON filter at the producer side is more surgical.

### Option D — Slot_H entry-side SL jitter (vary SL across pyramid entries)
- **Rejected.** Would mask the symptom (SLs no longer identical) but doesn't address the underlying false-positive class. Other slots with similar entry patterns would still trigger false-positives. Also non-trivial: which slots get jitter? How much? This is a band-aid, not a fix.

## Consequences

**Positive:**
- ✅ Eliminates the false-positive halt class confirmed in IMPL-062 Run #2 + Run #3.
- ✅ Preserves BR-3.6 ping-pong detection for EA-driven runaway loops (the actual intent).
- ✅ Surgical 3-LOC patch in producer-side filter (no schema change, no API change).
- ✅ Aligns CircuitBreaker scope with BR-3.6 spec wording ("EA repeatedly opening + closing same magic+dir").
- ✅ Preserves existing fix-round-11 §11.2/11.3/11.4/11.5 multi-layer guards (own-symbol, own-magic, init-complete, RUNNING-state, deal-type-buy-or-sell).

**Negative:**
- ⚠️ A pathological broker (e.g., one that aggressively triggers SL/TP fills as a denial-of-service attack on the EA) would no longer trip the breaker. **Mitigation:** Such a scenario is out-of-scope for Phase 1 (single-broker FBS-Real per C-5/C-10). If multi-broker support lands in Phase 2, revisit this ADR.
- ⚠️ Edge case: if a slot's ManageExits fires CloseOrder erroneously on the same position multiple times within 3s (e.g., a stub bug in `_TryExit` retry logic), those would be DEAL_REASON_EXPERT and would still trigger — which is correct behavior (true EA ping-pong).

**Neutral:**
- The PING_PONG_THRESHOLD_S = 3 constant in CircuitBreaker.mqh is unchanged.
- CircuitBreaker.RecordClose API is unchanged.
- CircuitBreaker SelfTest cases A-E remain valid (they exercise CircuitBreaker.CheckPingPong directly with synthetic events; the producer-side filter lives in Orchestrator and is not exercised by CircuitBreaker SelfTest).
- Existing CircuitBreaker tests (Cases A-E in `services/CircuitBreaker.mqh::SelfTest`) continue to pass — they call RecordClose directly without DEAL_REASON, simulating EA-driven closes (Case A's 1s-apart events represent the true ping-pong scenario the breaker is designed for).

## Decision Validation

**Empirical evidence:**
- IMPL-062 Run #2 (2026-05-12 G4-OFF) + Run #3 (2026-05-14 G4-ON) byte-identical halt class confirmed false-positive scope (`_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514{.jsonl,-tester.txt}`).
- Slot_H::Evaluate (line 211) already enforces same-H4-bar cooldown — Slot_H entries are not clustered in journal evidence.
- Identical SL across pyramid entries is a structural consequence of `bid ± InpHSlPips × pip_size` formula at the same H4 bar; this would replicate across other slots with similar SL formulas (Slot_K, Slot_M, Slot_T, etc.) and would surface as additional false-positives at 5-yr scale without ADR-013.

**Verification protocol (IMPL-FIX-012 Step 2 + Step 3):**
1. **Step 2 G1 + G2 smoke:** rebuild .ex5 with ADR-013 patch; bootstrap_smoke 3-day verify no DEAL_REASON_EXPERT-driven ping-pong false-positive (smoke window has only 3 days; false-positive class requires multi-position SL collision so likely won't surface in smoke — but G1 PASS + smoke completing without halt suffices).
2. **Step 3 G3 5-yr Bucket A retry (Run #4):** launch `regression_5yr_g4.ini`; verify simulation reaches ≥ 3 sim months past Slot_H Jan-14 storm point without `circuit_breaker_pingpong` halt. **If reaches 5-yr completion AND drift ≤ 25% → IMPL-062 E-AC #1 + #2 close.** **If reaches 5-yr completion BUT drift > 25% → next R-13 long-tail iteration on different slot.** **If still halts via different class (e.g., journal sustained-write failure or other halt path) → diagnose new class.**

## Revisit-when

- Phase 2 multi-broker support added (re-examine pathological-broker DoS scenario)
- New IMPL-FIX-NNN ticket surfaces a true EA ping-pong loop that DEAL_REASON_EXPERT filter incorrectly suppresses (extend filter logic)
- CircuitBreaker SelfTest expanded to cover producer-side filter (currently filter is unit-tested via Orchestrator-side OnTradeTransaction integration, not CircuitBreaker.SelfTest)
- Run #4 (post-IMPL-FIX-012) FAILS with same halt class (would falsify this ADR — re-evaluate root cause)

## References

- BR-3.6 — Business Rule for ping-pong detection (`docs/ba/04-business-rules.md § BR-3.6`)
- ADR-010 — Halted-state exit-only semantic (`docs/adr/010-halted-state-exit-only.md`)
- ADR-011 — ErrorBypassThrottle for halt-signal emission (`docs/adr/011-tagged-structured-logger.md`)
- TD-02 §5.8 — CircuitBreaker skeleton (`docs/technical-design/02-backend-design.md`)
- fix-round-10 §10.3 / D-8 — Producer-side wiring for CircuitBreaker (`docs/code-review/fix-round-10.md`)
- fix-round-11 §11.2-11.5 — Multi-layer guards in OnTradeTransaction (`docs/code-review/fix-round-11.md`)
- IMPL-062 Run #3 evidence — `_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514{.jsonl,-tester.txt}`
- IMPL-062 Run #2 evidence — `_session-handoff/IMPL-FIX-003-bucket-a-5yr-partial-20260512.{txt,jsonl}`
- regression-bucket-a.md § Run #3 root-cause analysis (2026-05-14)
- IMPL-FIX-012 task block in `docs/state/impl-plan.md` (authored 2026-05-14)
