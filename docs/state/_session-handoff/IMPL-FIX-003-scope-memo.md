# IMPL-FIX-003 — RiskManager.OpenOrder + 21-Slot OrderSend Wiring

| Field | Value |
|-------|-------|
| **Discovered** | 2026-05-09 via Tier 1.5 walk batch-3 |
| **Severity** | 🔴 CRITICAL — blocks MVP NFR-1.1 acceptance signal |
| **Size** | L–XL (21 slots + RiskManager service + TradeJournal hookup) |
| **Phase span** | P3 (slot bodies) + P4 (RiskManager body + journal hookup) |

## Empirical evidence

DST 2021-Mar smoke (commit `aca6585` post-R25; bootstrap_smoke equiv with Model=4 real ticks):

```
Test passed 0:07:06.961
Final balance 1000.00 USD          ← initial deposit, never moved
ev=entry_signal events: 214,985    ← slots logging intent
ev=order_sent events:        0
ev=order_failed events:      0
journal/tester/run-*.jsonl: 0 bytes
```

Aggregate across 5 DST batch legs (dst_2021_mar smoke + dst_2021_oct + dst_2022_mar + dst_2022_oct + dst_2023_mar):

```
ev=entry_signal      322,125  ← evaluation logic working correctly
ev=pending_entered         4
ev=transition_executed     4
ev=init_ok                 4  (RiskManager + CircuitBreaker + TimeGate + system)
ev=order_sent              0  ← entry-side broker dispatch path absent
```

## Root cause analysis

### `services/RiskManager.mqh` interface (verified 2026-05-09)

```mql5
class CRiskManager {
public:
    void Init(...);                    ✅ init params + dependency injection
    double ComputeLot(slot_id, ...);   ✅ per-slot lot calc (BR-4.1 BR-4.2)
    double ClampLot(raw_lot, ...);     ✅ floor/cap clamp
    static bool SelfTest();            ✅ unit test
    // OpenOrder(...)                  ❌ DOES NOT EXIST
};
```

### Slot-side comments referencing nonexistent method

- `slots/Slot_C.mqh:259-260` — *"observable milestone; actual OrderSend wiring lives in `RiskManager::OpenOrder`"*
- `slots/Slot_C.mqh:340` — *"Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md"*
- `slots/Slot_H.mqh:241` — *"Phase-1 stub: log intent only; m_risk.OpenOrderH(...) wires through core/Orchestrator.mqh"*
- `slots/Slot_B.mqh:208-209` — *"Submit order via RiskManager (which wraps CTrade per ea.md)"*
- `slots/Slot_BI.mqh:230-231` — *"the observable milestone; actual OrderSend lives in `RiskManager::OpenOrder` per `.claude/rules/ea.md`"*

### Architectural directive (`.claude/rules/ea.md`)

> *"ALL CTrade calls go through `RiskManager::OpenOrder` or `OpenOrder<X>` helper — slots ห้าม instantiate CTrade ตรง"*

### CTrade actually used in the codebase

`services/CrossSlotCoordinator.mqh:131` — `CTrade m_trade;` member, but **only used for exit-side `PositionClose()` / `PositionClosePartial()`** (lines 389, 612). Zero `PositionOpen()` invocations anywhere in the source tree.

### Why R12→R25 review chain didn't catch this

The chain (13 review/fix rounds, terminated at R25) revealed a 4-axis structure for comment-routing methodology precision: catalog (R20), destination (R21), anchor (R22-R23), exemption-regex (R24). However:

- R21 §21.2 **destination-existence verification** applied only to **comment routing pointers** (e.g., a comment that cites `Orchestrator::WireSlots step 4` must be greppable as a real method — not a banner-only hit).
- It did NOT apply to **functional call sites in code bodies** (e.g., a slot body that calls `m_risk.OpenOrder(...)` was never grep-verified that `CRiskManager::OpenOrder` actually exists as a declared method).
- 4-gate G1 (compile) didn't catch because **slot bodies don't call `m_risk.OpenOrder(...)`** — they stop at `EmitEntrySignal()`. So no compile error from missing method.
- 4-gate G2 (smoke) + G3 (backtest) didn't catch because Print-log entry_signal events look healthy. The structural test passes empty.
- Only Tier 1.5 walk's empirical "observe real trade flow + final balance moved" check exposes it.

This is a **new defect class** — comment-claimed-method-never-implemented. R26 (when triggered) should consider adding a Gate #9 clause for this.

## Proposed fix scope

### 1. New method in `services/RiskManager.mqh`

```mql5
// header
public:
   bool OpenOrder(string slot_id,
                  int magic,
                  ENUM_ORDER_TYPE dir,         // ORDER_TYPE_BUY | ORDER_TYPE_SELL
                  double lot,                  // already clamped via ClampLot()
                  double sl_price,             // 0.0 = no SL; else absolute price
                  string comment);             // "C,MA,N,1,SL" etc per slot prefix contract

private:
   CTrade            m_trade;                  // parallel to CrossSlotCoordinator.mqh:131
   ENUM_ORDER_TYPE_FILLING _DetectFillingMode(); // detect once, cache; mirror CrossSlotCoordinator:254-260
```

### 2. Body sketch

```mql5
bool CRiskManager::OpenOrder(string slot_id, int magic, ENUM_ORDER_TYPE dir,
                             double lot, double sl_price, string comment)
{
   if(m_logger == NULL) return false;
   if(lot <= 0.0) {
      m_logger.Warn(slot_id, "ev=order_skipped", "magic=" + IntegerToString(magic),
                    StringFormat("reason=zero_lot lot=%.4f", lot));
      return false;
   }

   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetTypeFilling(_DetectFillingMode());
   m_trade.SetDeviationInPoints(20);  // fbs broker tolerance

   double price = (dir == ORDER_TYPE_BUY)
                  ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool ok = m_trade.PositionOpen(_Symbol, dir, lot, price, sl_price, 0.0, comment);

   if(ok) {
      ulong ticket = m_trade.ResultOrder();
      m_logger.Info(slot_id, "ev=order_sent",
                    StringFormat("magic=%d ticket=%I64u dir=%s lot=%.2f price=%.5f sl=%.5f comment=%s",
                                 magic, ticket, EnumToString(dir), lot, price, sl_price, comment));
      // TradeJournal write hook — see decision §3 below
      return true;
   }
   else {
      uint rc = m_trade.ResultRetcode();
      m_logger.Error(slot_id, "ev=order_failed",
                     StringFormat("magic=%d rc=%u reason=%s lot=%.2f price=%.5f",
                                  magic, rc, m_trade.ResultRetcodeDescription(), lot, price));
      return false;
   }
}
```

### 3. Slot body extension (× 21 files)

For each slot's `Evaluate()`, after the existing `EmitEntrySignal()` Logger call, add:

```mql5
// Existing pattern (every slot, e.g. Slot_C.mqh:256-260):
m_logger.Info("Slot" + SlotId(), "ev=entry_signal",
              StringFormat("magic=%d", Magic()),
              StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                           ...));
//--- NEW: actually submit the order
ENUM_ORDER_TYPE dir = (decision.is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
if(m_risk.OpenOrder(SlotId(), Magic(), dir, lot, sl_price, comment)) {
   // PortfolioState population happens via OnTradeTransaction handler (IMPL-007 contract)
   // TradeJournal entry write — see §3 decision
}
```

### 4. TradeJournal hook decision

Two viable patterns:

- **(a) RiskManager owns TradeJournal pointer** — Composition Root injects `m_journal` into RiskManager.Init(); OpenOrder writes entry record on success. Pro: single ownership of order-emission write. Con: extra dependency edge in Init wiring.
- **(b) Slot writes TradeJournal after RiskManager.OpenOrder() returns true** — slot already has m_journal pointer. Pro: no Init signature change. Con: 21 slots each need the write call duplicated.

Recommend **(a)** — single source of truth for entry record format, avoids slot-side TradeJournal coupling drift across 21 slots.

### 5. Per-slot OpenOrder<X> helpers (CodeWiki §5.3 architecture)

Comments reference `OpenOrderCD`, `OpenOrderG`, `OpenOrderH`, `OpenOrderGO`, `OpenOrderC` (CrossSlotCoordinator:837 + CodeWiki §5.3). These are **legacy CodeWiki concepts** — Phase-1 MVP can defer them to **direct `RiskManager.OpenOrder()`** without per-slot helpers. Per-slot helpers (lot reduction tier, F-flag chain) become P5 enhancement post-MVP if needed. **Phase-1 scope: single OpenOrder() entry point only.**

## Acceptance criteria (S-AC + E-AC in impl-plan.md task block)

See task block at `docs/state/impl-plan.md` § IMPL-FIX-003 for full S-AC/E-AC list. Summary:

- **S-AC**: OpenOrder method declared + body + 21 slots updated + G1 0err/0warn + G2 init_ok + first 5 ticks emit order_sent
- **E-AC**: G3 bootstrap_smoke run produces order_sent events + non-zero journal jsonl + final balance ≠ $1000 + IMPL-062 5-yr re-run produces non-zero P&L within ±10% per-slot of baseline-per-slot.json

## Cascade unblock

Closing IMPL-FIX-003 unblocks (in dependency order):
1. **IMPL-066** — journal latency capture (now has entry write events to measure)
2. **IMPL-062** — 5-yr Bucket A regression (now produces real Net Profit vs baseline $24.27M)
3. **IMPL-068** — force-clear validation (auto-drains from IMPL-062 5-yr journal records)
4. **IMPL-063** — Bucket B paired regression (depends on IMPL-062 numeric drain)
5. **P4 Phase Gate** — empirical demo passes (Tier 2 close)
6. **P2 + P3 Phase Gate retroactive** — 29 P2/P3 deferred-AC rows mostly gated on IMPL-062 chain

## Risk if NOT fixed

- MVP NFR-1.1 (≤ 25% Bucket A drift) acceptance signal **cannot empirically close**
- IMPL-062/063/066/068 deferred-AC rows expire 2026-05-19 — registry will block `/deliver`
- Phase Gate Hallucination risk: 4-gate structural pass might tempt a "P4 done" claim despite EA never trading

## References

- `.claude/rules/ea.md` § "ALL CTrade calls go through RiskManager::OpenOrder"
- ADR-002 Composition Root (RiskManager-owns-CTrade is permitted; service-layer dispatcher)
- `services/CrossSlotCoordinator.mqh:131,254-260,389,612` — CTrade pattern reference
- `services/RiskManager.mqh:38-92` — current class declaration (no OpenOrder)
- DST 2021-Mar Tester log: `Tester/.../Agent-127.0.0.1-3000/logs/20260509.log` lines 52030+ (decoded UTF-16LE → UTF-8)

## Next session

Run `/impl-task IMPL-FIX-003` once DST sequencer finishes. Sequencer state file: `simulation/headless-tests/runs/dst_batch_progress.txt`.
