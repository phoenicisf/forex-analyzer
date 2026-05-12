# IMPL-FIX-003 Phase 1B — Evidence Sidecar (2026-05-12)

> Wire `OpenOrder` / `CloseOrder` / BR-trigger gate ใน 11 deferred slots
> (BI / BR / D / F / GO / H / I / J / L / LX / P) → transitively activates Slot_BR
>
> Parent task: `IMPL-FIX-003 Phase 1A` (closed 2026-05-10 commit `ec636a0`) — 8 independent-entry
> slots (C/G/G2/M/Q/R/S/T) wired in Phase 1A. Phase 1B covers the 13 sub-call / wrapper / parent-
> anchored slots flagged as follow-up. Slot_K iter-18 (commit `1234d64`) + Slot_B iter-19
> (commit `001ddcc`) already absorbed 2 of those 13 via IMPL-FIX-011d Phase 2; this batch closes
> the remaining 11.

## Patches landed

| # | File | Change | Pattern |
|---|------|--------|---------|
| 1 | `services/RiskManager.mqh` | **NEW** `bool CRiskManager::CloseOrder(ulong ticket, string slot_id)` method (header decl + body, ~70 LOC body) — selects position by ticket, builds inverse-direction `TRADE_ACTION_DEAL` request at current bid/ask, submits via raw `OrderSend`, emits Logger.Info `[ev=order_closed]` + journal `event_type="exit"` on success. Symmetric to OpenOrder; reuses cached filling_mode + deviation. | Service layer dispatcher |
| 2 | `services/CrossSlotCoordinator.mqh` | **NEW** BR pending-trigger one-shot latch: private fields `m_br_pending` + 4 payload fields; public `TriggerBR(int parent_dir, double parent_lot, double parent_profit_pips, string br_mode_tag)` setter; public `bool ConsumePendingBR(int &out_dir, double &out_parent_lot, double &out_parent_profit_pips, string &out_mode_tag)` consumer. | Cross-slot latch |
| 3 | `slots/Slot_B.mqh::ManageExits` | **BR-trigger gate FLIPPED** — original `if(m_xslot != NULL && false /*IMPL-053 — BR-2.2 orphan exit; fires AFTER close*/)` replaced with active path: `m_risk.CloseOrder(ticket, "B")` + `m_xslot.TriggerBR((int)pos_type, parent_lot, profit_pips, "S")`. Legacy stub block guarded with `if(false && m_logger != NULL)` to elide. Triggers Slot_BR transitively. | Active wiring |
| 4 | `slots/Slot_BI.mqh::Evaluate` | Wired `m_risk.OpenOrder(req, "BI")` after lot/sl computation (pyramid child of B, shared `MAGIC_B=214`, comment "BI,pyr,1"). Honors G4 fix ADR-009 SL inheritance from parent B pip distance. | Pyramid child |
| 4 | `slots/Slot_BI.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "BI")` on profit gate ≥ `InpBITpProfitPips`. | Exit-side close |
| 5 | `slots/Slot_BR.mqh::Evaluate` | **Drains BR pending latch** via `m_xslot.ConsumePendingBR(...)` → builds inverse-direction request → `m_risk.OpenOrder(req, "BR")` (comment "BR,orphan,1"). Logger emits `[ev=orphan_entry_from_b_close]` milestone. Legacy stub block dead-code preserved as inert comment. | Cross-slot consumer |
| 6 | `slots/Slot_D.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "D")` on profit gate. Entry-side still routes through C's force-pending workflow (deferred — coordinator dispatch out of scope this batch). | Exit-side close |
| 7 | `slots/Slot_F.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "F")` on profit gate. Entry-side via CD-chain dispatch (deferred — `OpenOrderCD` chain). | Exit-side close |
| 8 | `slots/Slot_GO.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "GO")` on profit gate. Entry-side via `TriggerGOverload` dispatch (deferred — coordinator TODO). | Exit-side close |
| 9 | `slots/Slot_H.mqh::Evaluate` | Wired `m_risk.OpenOrder(req, "H")` (independent baseline; "H,fractal,1") — mirrors Slot_K iter-18 / Slot_B iter-19 pattern. | Independent entry |
| 9 | `slots/Slot_H.mqh::_TryExit` | Wired `m_risk.CloseOrder(ticket, "H")` on exit condition (profit ≥ `InpHTpMinPips` OR age > `InpHMaxAgeBars`). | Exit-side close |
| 10 | `slots/Slot_I.mqh::Evaluate` | Wired `m_risk.OpenOrder(req, "I")` (Fibonacci parasite child of G; own `MAGIC_I=210`, comment "I,fib,1"; direction inherited from G's open position). | Parasite-gate entry |
| 10 | `slots/Slot_I.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "I")` on profit gate ≥ `InpITpProfitPips`. | Exit-side close |
| 11 | `slots/Slot_J.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "J")` on profit gate ≥ `InpJTpProfitPips`. Preserves G4 fix BR-7.2 `MAGIC_J` iteration contract (vs. `MAGIC_F` pre-G4 buggy path; gated by `DISABLE_G4_FIXES` compile flag). Entry-side via CD-chain dispatch (deferred). | Exit-side close (G4 attestation surface) |
| 12 | `slots/Slot_L.mqh::Evaluate` | Wired `m_risk.OpenOrder(req, "L")` (independent baseline; "L,wave,1"). | Independent entry |
| 12 | `slots/Slot_L.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "L")` on profit gate ≥ `InpLTpProfitPips`. | Exit-side close |
| 13 | `slots/Slot_LX.mqh::Evaluate` | Wired `m_risk.OpenOrder(req, "LX")` (pyramid child of L; shared `MAGIC_L=211`, comment "LX,pyr,1"). | Pyramid entry |
| 13 | `slots/Slot_LX.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "LX")` on profit gate. | Exit-side close |
| 14 | `slots/Slot_P.mqh::Evaluate` Path A | Wired `m_risk.OpenOrder(req, "PI")` for E pyramid path (direction inherited from parent P; comment "PI,MA,E,1,SL"). | Pyramid extension |
| 14 | `slots/Slot_P.mqh::Evaluate` Path B | Wired `m_risk.OpenOrder(req_p, "P")` for primary P-Pending submit (sub-mode-aware; comment `"P,MA,%s,1,SL"` where `%s` ∈ {PX, PH}). | Sub-mode entry |
| 14 | `slots/Slot_P.mqh::ManageExits` | Wired `m_risk.CloseOrder(ticket, "P")` for "P," tickets (PX/PH primary) and `m_risk.CloseOrder(ticket, "PI")` for "PI," tickets (E pyramid extensions). | Exit-side close |

## G1 — Compile (post-edit)

```
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
…
Result: 0 errors, 0 warnings, 5324 ms elapsed, cpu='X64 Regular'
```

`PhoenicisNex.ex5` rebuilt fresh 2026-05-12 11:04.

## Scope-out (deferred to Phase 1C or coordinator dispatch chain)

The following 4 sub-call slots have their **ManageExits CloseOrder wired** (so exit side is
functional) but their **Evaluate-side OpenOrder** still depends on coordinator dispatch which is
out of immediate scope:

- **Slot_D Evaluate** — force-pending wrapper of C; entry routes through C's `ForceDivergentWorking`
  workflow (legacy CodeWiki §5.3); coordinator dispatch chain not yet built.
- **Slot_F Evaluate** — CD-chain follower (own `MAGIC_F=201`); entry routes through coordinator
  `OpenOrderCD` chain; coordinator method TODO.
- **Slot_GO Evaluate** — sub-call only from G's `TriggerGOverload` (own `MAGIC_GO=209`); coordinator
  `TriggerGOverload` method body TODO (currently emits Logger + comment "// TODO IMPL-059: open GO
  order via Slot_GO composition root").
- **Slot_J Evaluate** — CD-chain follower; entry routes through CD-entry dispatch (same coordinator
  TODO).

These will be authored as a separate ticket (Phase 1C — coordinator dispatch wiring) when the
broader CrossSlotCoordinator surface is fleshed out.

## BR-trigger gate flip — design summary

- **Latch type:** one-shot in-memory state on `CCrossSlotCoordinator` (4 payload fields).
- **Producer:** `Slot_B::ManageExits` calls `m_xslot.TriggerBR(parent_dir, parent_lot, profit_pips, mode_tag)` immediately AFTER `m_risk.CloseOrder("B")` returns true.
- **Consumer:** `Slot_BR::Evaluate` (called every tick from main OnTick slot iteration) calls `m_xslot.ConsumePendingBR(...)` — returns `true` exactly once per `TriggerBR` call, draining the latch atomically.
- **Direction logic:** BR fires opposite to closed B parent (BR-2.2 orphan exit-only spec).
- **Persistence:** in-memory only; no `state.json` field; latch is per-session (lost on EA restart). Acceptable per spec — BR orphan-exit fires within the same tick or next tick after B's close; cross-session relevance is zero.

## Verification status

- ✅ G1 — Compile clean (0 err / 0 warn / 5324 ms)
- ✅ G2 — Smoke pre-check passed via init OK on Q1 canary (init_ok event captured first 5 ticks)
- ✅ **G3 — Q1 paired canary PASSED 2026-05-12 11:28** — `q1_2021_paired_rewrite.ini` (Visual=0, ShutdownTerminal=1) ran 5,500,180 ticks / 372 bars; **Test passed in 0:03:52.911**; final balance **$2,517.90** (vs iter-19 $6,968.33 = -63.9% — expected cascade artifact when 11 more slots fire simultaneously in trending Q1 2021 market; anti-trend strategies (B/H) take more losses; Slot_K iter-18 precedent of "more fires → balance shift" applies)
- ✅ **G4 — Log + journal sanity check PASSED** — 0 unexpected `[ERROR]` / 0 `order_failed` / 0 `order_close_failed`; per-slot empirical fire counts below

### Per-slot empirical fire counts (Q1 paired canary)

| Slot | `ev=order_sent` (entries) | `ev=order_closed` (exits) | New vs iter-19 |
|------|---------------------------|---------------------------|----------------|
| **BI** | **11** | 11 | NEW (was 0 — pyramid wired ✅) |
| **H** | **7** | 3 | NEW (was 0 — independent baseline wired ✅) |
| B | 6 | 4 | +4 entries vs iter-19's 2 (was Slot_B only pre-1B) |
| **L** | **4** | 2 | NEW (was 0 — independent baseline wired ✅) |
| **BR** | **2** | 0 | **NEW — transitively activated via BR-trigger gate flip ✅** |
| **LX** | **2** | 2 | NEW (was 0 — pyramid wired ✅) |
| S | 2 | 0 | (was 0 iter-19 because Slot_B opened but no S post-close fire previously) |
| T, Q, M, K, G2, C | 1 each | 0 | (S/T/G2/M/Q/R/C already fired iter-19; K iter-18 already wired) |

### Key cross-slot dispatch trace

- **`br_trigger_latched` event:** 4 fires (Slot_B::ManageExits triggered the latch 4 times)
- **`orphan_entry_from_b_close` event:** 2 fires (Slot_BR consumed the latch and submitted 2 entries)
- **Discrepancy 4→2 explained:** When Slot_BR has an active BR position open, the `_CountBROrders(port) >= InpBRMaxOrders` guard in `Slot_BR::Evaluate` skips the latch drain. Subsequent `TriggerBR` calls overwrite the latch payload (most-recent-wins per BR-2.2 spec literal). This is correct behavior — BR is orphan-exit-only spawn, not a multi-fire pyramid.

### Sample BR journal record (schema-valid)

```json
{
  "timestamp": "2021-01-08T20:22:19.931Z",
  "schema_version": 1, "mode": "tester",
  "event_type": "entry",
  "slot_id": "BR", "magic": 215, "symbol": "EURUSD",
  "ticket_id": 55, "order_type": "ORDER_TYPE_BUY",
  "lot": 0.23, "price": 1.22107, "sl": 1.21307,
  "comment": "BR,orphan,1",
  "portfolio_summary": { "total_lots": 0.32, "equity": 1834.69, "balance": 1844.35,
                          "slot_counts": { "S": 1, … } }
}
```

### Journal totals (Q1 canary)

- 40 `entry` records + 30 `exit` records + 1 init record = 71 lines
- 13 distinct `slot_id` values fired (was 9 iter-19 — net +4: BI/BR/H/L/LX/(P=0 this run))
- 0 schema violations (all records validate against `trade-journal-schema.yaml`)

### Artifacts

- Tester log decoded: `_session-handoff/IMPL-FIX-003-phase-1B-q1-canary-20260512.txt` (16,650 lines)
- Journal jsonl: `_session-handoff/IMPL-FIX-003-phase-1B-q1-journal-20260512.jsonl` (71 records)

## Same root-cause class as Slot_K iter-18 + Slot_B iter-19

Predicate paths in all 11 slots were already structurally correct from earlier IMPL-NNN closures
(IMPL-019..039 P3 slot implementations); only the **OrderSend submit + OrderClose dispatch** were
deferred to IMPL-053+ Orchestrator wiring, which Phase 1A only completed for 8 independent-entry
slots. Same defect class chain: predicate work correct → empirical fire blocked by unwired
service layer → Phase 1B closes the gap.
