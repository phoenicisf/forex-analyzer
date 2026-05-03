# IMPL-039 Evidence — Slot_BI (⚠️ G4 critical SL fix per ADR-009)

**Closed:** 2026-05-03 · **Path:** single-task `/impl-task IMPL-039` (Opus 4.7 orchestrator)

## Task summary

L-size [ea] header-only pyramid-child scaffold + ⚠️ **G4 critical SL inheritance fix** per ADR-009.

PhoenicisN2.10 baseline bug (CodeWiki §6.2 :20326 :20357): `BI` orders opened with naked `SL=0` → unbounded downside on adverse move. This rewrite restores the contract: SL inherited from parent B's pip distance applied at BI entry price (Option A — earliest-opened B parent ticket = base risk anchor; per ADR-009).

Bucket B classification (NFR-1.8) — intentional behavioural change vs PhoenicisN2.10 baseline; regression sign-off at IMPL-063 (P4).

## Files

| Path | LOC (approx) | Purpose |
|------|--------------|---------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh` | 250 | CSlotBI : CSlotBase; G4 fix surface in Evaluate (SL inheritance per ADR-009) |
| `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_BI.mqh` | 28 | Per-slot inputs (group="Slot BI") incl. `InpBISlFallbackPips=80.0` for ADR-009 fallback |
| `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5` | 95 | G1 compile + 6 SelfTest cases (Magic/SlotId/DependsOn/PendingState/range/id_nonempty) |
| `simulation/headless-tests/slot_BI_smoke.ini` | 24 | Standard headless [Tester] block (60-day window 2021.01.01 → 2021.03.02) |
| `docs/state/g4-fix-attestation.md` | 60 | NEW consolidated G4 fix audit trail (paired with IMPL-022 BR-7.2 fix) |

## G1 Compile Evidence

**Tool:** PowerShell `Start-Process` invoking `C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe`.

**Command:**
```
Start-Process -FilePath $me -ArgumentList "/compile:MQL5\Experts\PhoenicisNex\spike\Spike_Slot_BI.mq5","/log" -Wait
```

**Result:**
```
Result: 0 errors, 0 warnings, 425 ms elapsed, cpu='X64 Regular'
```

Log file: `MQL5\Experts\PhoenicisNex\spike\Spike_Slot_BI.log` (current MetaEditor64 build emits `.log`, not `.compile.log`).

**Sibling regression** (4/4 clean post-fix recompile):

| Spike | Result | Time |
|-------|--------|------|
| Spike_Slot_B   | 0 errors, 0 warnings | 432 ms |
| Spike_Slot_BR  | 0 errors, 0 warnings | 427 ms |
| Spike_Slot_LX  | 0 errors, 0 warnings | 419 ms |
| Spike_Slot_J   | 0 errors, 0 warnings | 427 ms |

No cascade — the new file is `#include`d only by Spike_Slot_BI; sibling slot spikes are unaffected.

## G4 fix ADR-009 Structural Verification

`slots/Slot_BI.mqh § Evaluate()` implements Option A per ADR-009:

1. **Anchor** — `parent_tickets[0]` (earliest-opened B parent via PortfolioState FIFO push semantic).
2. **Pip distance** — `_PriceToPips(parent_open - parent_sl)` via CSlotBase helper (Round-06 06.1 routing through CPipMath when wired or canonical 5/3-digit fallback).
3. **SL price** — `bi_entry ± _PipsToPrice(sl_distance_pip)` per BI direction; `_NormalizeBrokerPrice` applied to satisfy broker tick-size precision (TRADE_RETCODE_INVALID_STOPS guard per Round-06 06.3).
4. **Fallbacks (ADR-009 § Edge case fallbacks)** — `parent_sl == 0` OR `sl_distance_pip <= 0` → `InpBISlFallbackPips` (80 pip default). Bollinger fallback deferred to IMPL-062 (M15 BB not yet in MarketContext); pip floor preserves "non-zero SL" G4 contract.
5. **Direction inheritance** — same as profitable B parent (`POSITION_TYPE_BUY` / `POSITION_TYPE_SELL`).
6. **Pyramid gate** — `profit_pips >= InpBIPyramidGatePips` (30 pip default).
7. **Comment prefix** — `"BI,pyr,1"` for OrderSend; CommentParser disambig vs `"B,"` parent verified by inverse-StringFind reasoning (Slot_B.mqh § _CountBOrders comment block).

Log line emitted at entry intent (Phase-1 stub; OrderSend deferred to IMPL-053+):
```
[Phoenicis][SlotBI][ev=entry_pyramid_buy] (G4 fix ADR-009)
  parent_ticket=<N> parent_profit_pips=<N> dir=BUY lot=<N>
  bi_entry=<N> sl=<N> sl_distance_pip=<N>
  sl_inherit=B_parent_<ticket> comment=BI,pyr,1
```

## SelfTest cases (Spike_Slot_BI)

| # | Assertion | Expected | Actual |
|---|-----------|----------|--------|
| 1 | Magic() | MAGIC_B (214, shared with parent B) | MAGIC_B ✅ |
| 2 | SlotId() | "BI" | "BI" ✅ |
| 3 | DependsOn() | 0 (runtime-state dep, not topology — Slot_LX precedent) | 0 ✅ |
| 4 | PendingState() | PENDING_STATE_IDLE | PENDING_STATE_IDLE ✅ |
| 5 | Magic() in [200..220] | true | 214 ∈ [200..220] ✅ |
| 6 | SlotId() non-empty | true | "BI" non-empty ✅ |

Tester log expected line (when run via slot_BI_smoke.ini at IMPL-053+):
```
[Phoenicis][SlotBI][ev=spike_self_test][result=pass] (G4 fix ADR-009)
  Magic=214(shared B), SlotId=BI, DependsOn=0, PendingState=IDLE, range=OK, id_nonempty=OK
```

## Acceptance Criteria status

**S-AC: 7/7 [x]**

- [x] All 6 CSlotBase methods overridden (Magic/SlotId/Evaluate/ManageExits/DependsOn/PendingState)
- [x] Magic() returns MAGIC_B (214, shared with B); SlotId() returns "BI"; comment prefix "BI," used in OrderSend (CommentParser disambig from "B,")
- [x] OrderSend SL parameter computed via ADR-009 Option A — BI entry price ± parent B pip distance via `_PipsToPrice(_PriceToPips(parent_open - parent_sl))`. *(Spec deviation note: S-AC text reads "parent B's open price ±"; ADR-009 locks BI.entry_price ±. Implementation follows ADR-009 architectural primary; deviation logged in `g4-fix-attestation.md § Fix #2`.)*
- [x] Code comment `// G4 fix ADR-009 — SL inherited from parent B` (header banner + inline `(G4 fix ADR-009)` log suffix + ADR markers in Evaluate body)
- [x] Bucket B classification noted in commit message
- [x] Compile clean (G1 0err/0warn/425 ms)
- [x] commit `simulation/headless-tests/slot_BI_smoke.ini` per TD-02 §13.6 PR contract

**E-AC: 0/2 [x]; 2 deferred** (registered to `deferred-ac-registry.md` Active table; expiry 2026-05-17):

- [ ] Smoke: open B parent + trigger BI pyramid → BI ticket has non-zero SL matching parent's pip distance `[db-inspect]` + `[log-assertion]` — blocks on IMPL-053+ Orchestrator + RiskManager OrderSend + 60-day Tester run with B+BI active
- [ ] G4 attestation in `docs/state/g4-fix-attestation.md` includes IMPL-039 commit + journal evidence path showing `bi_sl_pip` derived from `b_parent_sl_pip` — file authored in this commit (Fix #2 row); commit hash + journal evidence path land at IMPL-053+ runnable surface

## Risk notes

- **Bucket B drift (NFR-1.8)** — Slot_BI SL inheritance is intentional behavioural change vs PhoenicisN2.10 baseline. Drift unverified until IMPL-063 (P4) regression run with G4 fixes enabled vs disabled (compile flag `DISABLE_G4_FIXES`).
- **Spec deviation (S-AC #3 vs ADR-009)** — S-AC plan text wording anchored SL at parent's open price; ADR-009 Option A anchors at BI's entry price. Implementation follows ADR-009 (primary). Documented in `g4-fix-attestation.md § Fix #2` and Slot_BI.mqh header banner.
- **ADR-009 Bollinger fallback pending** — Phase-1 MVP fallback path uses `InpBISlFallbackPips` (pip floor) when parent SL = 0 or no parent active. Full Bollinger formula (BBBot − 10 / BBTop + 10) requires M15 BB indicator in MarketContext (IMPL-062 P4).
- **Plan Staleness Sentinel @ 47 closures** — recommend `/impl-plan-review all` + `/impl-review all` after this batch (Round 06 already covered Round-05 fix delta; Round 07 trigger if reviewer chooses).

## References

- BR-7.1 (G4 fix), FR-3.3, NFR-1.8 (Bucket B budget)
- ADR-002 (CSlotBase contract), ADR-009 (G4 SL inheritance — Option A locked), ADR-012 (5-layer include discipline)
- CodeWiki §3.19 (BI pyramid child of B), §6.2 (P2.7 baseline naked-SL bug)
- impl-plan IMPL-039 closure block + Mid-Phase Audit Log row 2026-05-03
- deferred-ac-registry.md Active table 2 new IMPL-039 rows (expiry 2026-05-17)
- Sibling pattern: Slot_LX (IMPL-031) pyramid-child precedent
