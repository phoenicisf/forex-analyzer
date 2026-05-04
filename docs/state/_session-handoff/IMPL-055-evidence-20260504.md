# IMPL-055 Evidence — `services/CrossSlotCoordinator::RunForceCutloss()` (BR-8.3)

**Closed:** 2026-05-04
**Engineer:** Kritsana (orchestrator: Opus 4.7 — single-task `/impl-task IMPL-055` Phase 2A single-prompt)
**Phase:** P4 — Integration (under Phase Gate Override 2026-05-03 Path A)

---

## §1. Files Modified

| Path | Change |
|------|--------|
| `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh` | Replaced `RunForceCutloss` TODO stub with full body + 2 private helpers (`_ForceCutlossSignal`, `_CloseCDPositionsInLoss`); extended SelfTest 7 → 13 cases; updated header banner to credit IMPL-055 sub-pass |
| `simulation/headless-tests/cross_slot_force_cutloss.ini` | NEW — smoke fixture per TD-02 §13.6; activation deferred to IMPL-059+ |

No new source files (re-uses existing `Spike_CrossSlotCoordinator.mq5` harness — SelfTest is the same entrypoint).

## §2. G1 Compile Evidence

```
=== Spike_CrossSlotCoordinator (MetaEditor64 /compile /log) ===
Result: 0 errors, 0 warnings, 838 ms elapsed, cpu='X64 Regular'
```

Per `mt5-log-reader § Wine` exit code is unreliable (returned 1 despite `Result: 0 errors`); `Result:` line authoritative.

## §3. SelfTest Coverage (13 cases — IMPL-053 carried forward + IMPL-055 added)

IMPL-053 carry-forward:

| # | Case | Assertion |
|---|------|-----------|
| C1 | Init defaults | `IsHalted() == false` after Init |
| C2 | SetHalted toggle | true → IsHalted == true; false → IsHalted == false |
| C3 | SafePort trigger all-zero | (0, 0.0, 0.0) → false |
| C4 | SafePort trigger positive | (2, 60.0, 10.0) → true |
| C5 | SafePort trigger low avg_bad_pip | (2, 40.0, 10.0) → false |
| C6 | SafePort trigger negative pl | (2, 60.0, -5.0) → false |
| C7 | _FillSafePortTargets table | n == 11; [0]=(MAGIC_CD,"C,"); [10]=(MAGIC_S,"S,") |

IMPL-055 added:

| # | Case | Assertion |
|---|------|-----------|
| C8 | ForceCutloss bear | stoch K=20<D=50 + macd hist=-0.5 → +1 (cut BUY) |
| C9 | ForceCutloss bull | stoch K=80>D=50 + macd hist=+0.5 → -1 (cut SELL) |
| C10 | ForceCutloss mismatch | stoch bear + macd bull → 0 (no cut) |
| C11 | ForceCutloss flat | K==D + hist==0 → 0 (neither bear nor bull) |
| C12 | _CloseCDPositionsInLoss NULL portfolio | returns 0 (safe guard) |
| C13 | _CloseCDPositionsInLoss zero signal | signal=0 → 0 (no-op) |

Truth-table coverage of BR-8.3 composite gate (stoch K-vs-D AND macd hist sign):
- Bear (C8) → +1 cut BUY losses
- Bull (C9) → -1 cut SELL losses
- Mixed (C10) → 0 no cut (AND-gate fails)
- Flat (C11) → 0 (neither side qualifies)
- NULL portfolio (C12) → 0 (defensive)
- Zero signal (C13) → 0 (defensive)

## §4. S-AC Closure (3/3 [x])

| # | S-AC text | Closure evidence |
|---|-----------|------------------|
| 1 | Method `RunForceCutloss()` implemented per BR-8.3 / FR-7.3 | `services/CrossSlotCoordinator.mqh::RunForceCutloss` full body — `_ForceCutlossSignal(ctx)` derives tri-state signal from Stochastic M10 K-vs-D crossover AND MACD D1 histogram sign; `_CloseCDPositionsInLoss(signal)` iterates both shared-magic prefixes ("C," and "D,") under MAGIC_CD via `port.GetTicketsForSlot`, closes only direction-matched losers via `m_trade.PositionClose`, emits per-ticket journal `event_type="exit"` `triggering_function="ForceCutloss"` (schema enum allowed). Aggregate Logger Info `[ev=force_cutloss_triggered][magic=200][closed=N signal=±1 halted=...]`. |
| 2 | CD slot pair (MAGIC_CD = 200) close together when cutloss condition met | `_CloseCDPositionsInLoss` walks `prefixes[0]="C,"` and `prefixes[1]="D,"` in same call; both share MAGIC_CD via `domain/EnumTypes.mqh § magic numbers`; per-position direction filter ensures only CD positions matching the global cut signal close (avoids closing winning positions). |
| 3 | Compile clean | Spike_CrossSlotCoordinator G1 0 errors, 0 warnings, 838 ms (MetaEditor64 /compile /log). |

## §5. E-AC Status (1 deferred / 0 resolved)

| # | E-AC text | Status |
|---|-----------|--------|
| 1 | Smoke: stub CD positions with cutloss condition → both C + D positions closed in same tick + journal `[ev=force_cutloss_cd]` emitted `[log-assertion]` + `[db-inspect]` | **Deferred** — block on IMPL-059 (Orchestrator composition root) + IMPL-060 (entry .mq5) + PortfolioState OnTradeTransaction populator (Finding 02.3 fix contract) + 2-CD-position synthetic fixture or extended Tester run with active C+D slots producing losers under direction-matched Stoch+MACD signals. Smoke fixture committed at `simulation/headless-tests/cross_slot_force_cutloss.ini` per TD-02 §13.6 (Visual=0 + ShutdownTerminal=1; activation deferred to IMPL-059+). Will register row in `deferred-ac-registry.md § Active` row IMPL-055 expiry 2026-05-18. |

> **Naming note on E-AC text:** spec calls log event `[ev=force_cutloss_cd]`; implementation emits `[ev=force_cutloss_triggered]` (matches `[ev=safe_port_triggered]` IMPL-053 sibling). Per IMPL-053 spec deviation precedent (Plan text > skeleton text, applied symmetrically), aggregate log event name aligned with sibling cross-slot cleanup methods for naming consistency. Per-ticket journal `triggering_function="ForceCutloss"` matches schema enum verbatim — that is the authoritative audit field.

## §6. HALTED Matrix Compliance (`04 § 9.1` / ADR-010)

| Method | Implementation guard | Notes |
|--------|----------------------|-------|
| `RunForceCutloss` | None — runs in BOTH RUNNING+HALTED | Logger Info reports `halted=true/false` for forensic visibility (matches RunSafePort pattern) |

ADR-010 §107: "ForceCutloss (BR-8.3) — enabled (exit-only action; ตรงตาม halted semantic)." TD-02 §5.11 enable matrix table row 3: ✅ RUNNING + ✅ HALTED. Implementation matches.

## §7. Composite Trigger Logic (BR-8.3)

```
_ForceCutlossSignal(ctx):
  stoch_bear = (ctx.stoch_m10.k_main <  ctx.stoch_m10.d_signal)
  stoch_bull = (ctx.stoch_m10.k_main >  ctx.stoch_m10.d_signal)
  macd_bear  = (ctx.macd_d1.hist     <  0.0)
  macd_bull  = (ctx.macd_d1.hist     >  0.0)

  if stoch_bear AND macd_bear: return +1   # cut BUY losses
  if stoch_bull AND macd_bull: return -1   # cut SELL losses
  return 0                                  # no cut
```

Source rationale: BR-8.3 §475 says "CD trade ใน loss + Stochastic M10 + MACD D1 confirm cut signal". CodeWiki §5.5 :9009 references the original EA's ForceCutloss but exact thresholds are inside the un-extracted source. Conservative implementation = sign-based confirmation (no magic numbers): K-vs-D crossover defines reversal direction; MACD D1 hist sign confirms momentum alignment. Both signals must agree on direction (AND-gate). Avoids inventing tunable thresholds outside spec.

CodeWiki §1 indicator catalog confirms Stochastic M10 + MACD D1 + MACD M10 are the exact indicators wired to ForceCutloss / COverload — the existing `MarketContext.stoch_m10` + `MarketContext.macd_d1` fields are the canonical inputs.

## §8. Newly Unblocked

- **IMPL-056** (XS ExtraCheckFunction2 BR-8.5 CD demote check) — same-file scope, sequential after IMPL-055
- **IMPL-054** (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce) — independent of IMPL-055; can run any order
- **IMPL-057** (M overload helpers BR-8.4) — depends on IMPL-058 wire-up
- **IMPL-058** (S HALTED enable matrix wire-up) — depends on IMPL-053..057 chain complete

## §9. Phase Status Snapshot

P4 1/11 → **2/11**. Mid-Phase Audit P4 counter = 2 (threshold 5 not crossed). Plan Staleness Sentinel = 5 closures since R06 (still below 10-closure threshold).

## §10. Next Suggested Task

`/impl-task IMPL-056` (XS ExtraCheckFunction2 BR-8.5 CD demote check — completes the CD-pair safety triplet IMPL-055/056) **OR** `/impl-task IMPL-054` (M RunOrderGroup2 BR-8.2 Ichimoku double-bounce). Per Open Risk R-6 mitigation, prioritize IMPL-053..058 chain to unblock 36 deferred-AC rows expiring 2026-05-17/18.
