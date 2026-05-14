# IMPL-FIX-012 Step 0 Diagnostic — Slot_H Clustering Pattern Analysis

**Date:** 2026-05-14
**Source:** `docs/state/_session-handoff/IMPL-062-bucket-a-5yr-run3-20260514.jsonl` (72 records, 14-day pre-halt window 2021-01-01 → 2021-01-14 14:59:21)
**Engineer:** Opus 4.7
**Scope:** falsify or confirm IMPL-FIX-012 originally-authored hypothesis (Slot_H pyramid clustering → ManageExits same-bar cooldown)

---

## §1 — Slot_H Entry Events (chronological)

| # | Timestamp (sim) | Ticket | Type | Price | SL | Lot | Comment |
|---|----------------|--------|------|-------|----|----|---------|
| 1 | 2021-01-07T12:24:43.107Z | 36 | SELL | 1.22549 | 1.23449 | 0.20 | H,fractal,1 |
| 2 | 2021-01-07T16:00:00.008Z | 37 | SELL | 1.22675 | 1.23575 | 0.20 | H,fractal,1 |
| 3 | 2021-01-08T03:16:13.426Z | 39 | SELL | 1.22365 | 1.23265 | 0.21 | H,fractal,1 |
| 4 | 2021-01-08T10:04:21.180Z | 41 | SELL | 1.22231 | 1.23131 | 0.22 | H,fractal,1 |
| 5 | 2021-01-08T22:33:21.560Z | 57 | SELL | 1.22218 | 1.23118 | 0.31 | H,fractal,1 |
| 6 | 2021-01-13T04:38:33.842Z | 71 | **BUY** | 1.22211 | 1.21311 | 0.30 | H,fractal,1 |
| 7 | 2021-01-13T09:29:48.077Z | 72 | **BUY** | 1.22211 | 1.21311 | 0.30 | H,fractal,1 |

**7 entries / 6 sim days = 1.17 entries per sim day.** Inter-event gaps:
- t#36 → t#37: Δ=12,917s (3h 35m)
- t#37 → t#39: Δ=40,573s (11h 16m)
- t#39 → t#41: Δ=24,488s (6h 48m)
- t#41 → t#57: Δ=44,940s (12h 29m)
- t#57 → t#71: Δ=367,512s (4d 6h 5m)
- t#71 → t#72: Δ=17,474s (4h 51m)

**No sub-second clustering at entry side.** All gaps measured in hours/days.

---

## §2 — Slot_H Exit Events (chronological)

| # | Timestamp (sim) | Ticket | Price |
|---|----------------|--------|-------|
| 1 | 2021-01-08T03:16:13.426Z | 37 | 1.22375 |
| 2 | 2021-01-08T10:04:21.180Z | 36 | 1.22240 |
| 3 | 2021-01-08T20:17:50.000Z | 41 | 1.22120 |
| 4 | 2021-01-08T20:17:50.000Z | 39 | 1.22120 |
| 5 | 2021-01-11T01:44:23.716Z | 57 | 1.21918 |

**Exit-side Δ=0s pattern detected:** tickets 41 + 39 closed at exactly `2021-01-08T20:17:50.000Z` at exactly the same price `1.22120`. Both were SELL positions; both had SL above current price (entry SLs 1.23131 and 1.23265 → not SL hit; both at 1.22120 = current bid). Same-tick close pattern indicates **EA-side ManageExits or simultaneous TP gate trigger**, NOT broker-side SL.

But wait: their SLs are 1.23131 and 1.23265 (different prices). If broker SL hit, they'd hit at different ticks. Same-tick close at 1.22120 = ManageExits profit-gate triggered simultaneously when bid reached 1.22120 (profit_pips for t#41: 1.22231-1.22120=11.1 pips < InpHTpMinPips=30 → not profit gate; for t#39: 1.22365-1.22120=24.5 pips < 30 → also not profit gate).

Re-examining: with InpHMaxAgeBars=8 H4 bars (8×4h = 32h age), tickets 41 (open 10:04 Jan-08) + 39 (open 03:16 Jan-08) at close time 20:17 Jan-08 had ages of ~10h and ~17h respectively — both under 32h age gate. Neither profit nor age gate fires. **The Δ=0s simultaneous close is unexplained by EA-side ManageExits.** Most likely **broker-side action** (e.g., margin call or end-of-day liquidation when account equity dropped, OR partial-close cascade triggered by another slot).

---

## §3 — CircuitBreaker Halt Trigger Analysis

**Halt event (per Run #3 Tester log):**
```
2021.01.14 14:59:21   [Phoenicis][2021-01-14 14:59:21.335][ERROR][slot=CircuitBreaker]
  [ev=ping_pong][magic=205] ping_pong detected: magic=205 dir=1 delta=0s (threshold=3s)
```

`magic=205 dir=1 delta=0s` — Slot_H (MAGIC_H=205), direction=1 (= ENUM_POSITION_TYPE_SELL, which is the broker-deal direction when CLOSING a BUY position per Orchestrator hedging-mode mapping at line 842: `direction = (dt == DEAL_TYPE_SELL) ? 1 : 0`).

**Reverse-engineering the halt trigger:**
- `direction=1` = broker SELL deal = closing a BUY position
- The only open BUY positions on 2021-01-14 14:59:21 per journal: tickets **71 + 72** (both opened 2021-01-13)
- Both have **identical SL=1.21311** (same `bid - InpHSlPips × pip_size` formula at the same fill price 1.22211)
- When EURUSD price falls to 1.21311 on 2021-01-14 14:59:21, **both broker SLs trigger on the same tick** → 2 broker close deals at Δ=0s with same magic=205 + same direction=1
- CircuitBreaker.RecordClose called twice in same tick → CheckPingPong returns true → halt

**Note:** Journal does NOT contain explicit close events for tickets 71+72 (the journal records 5 exits stopping at ticket 57). The halt event at 2021-01-14 14:59:21 fires BEFORE the close events would be journaled (CircuitBreaker.CheckPingPong runs in OnTick at line 594 of Orchestrator before TradeJournal.WriteEvent for the close). After halt, ManageExits continues to drain remaining open positions per ADR-010 exit-pass-only — these closes are journaled later but not visible in pre-halt window.

---

## §4 — Hypothesis Falsification

**Originally-authored IMPL-FIX-012 hypothesis (per task block 2026-05-14):**
> "Slot_H pyramid clustering (7 H entries in 14 sim days, sub-second windows) triggers ping_pong threshold; same-bar cooldown in ManageExits prevents multiple closes within one tick."

**Empirical falsification:**

1. **Slot_H entries are NOT sub-second clustered** (§1 above — all gaps measured in hours/days).
2. **Slot_H::Evaluate already enforces same-H4-bar cooldown** at line 211: `if(ctx.bar_index_h4 == m_last_bar_entered) return;`. Plus `_CountHOrders >= InpHMaxOrders` (max 2) at line 208.
3. **The Δ=0s pattern is at EXIT timestamp** (tickets 41+39 simultaneously closed at 2021-01-08T20:17:50.000Z; tickets 71+72 likely simultaneously closed at 2021-01-14T14:59:21Z).
4. **Broker-side SL fills do NOT traverse Slot_H::ManageExits** — they go through MT5's broker engine → OnTradeTransaction (DEAL_TYPE_BUY closing a SELL or DEAL_TYPE_SELL closing a BUY) → Orchestrator routes to CircuitBreaker.RecordClose. ManageExits is only invoked for EA-side close decisions (RiskManager.CloseOrder calls).
5. **Therefore: ManageExits same-bar cooldown cannot prevent broker-side simultaneous SL fills.** The originally-authored Step 1 patch would be a no-op.

**Revised hypothesis (per ADR-013):**
> CircuitBreaker BR-3.6 false-positives on legitimate concurrent broker-driven SL fills of independent positions sharing identical SL prices. The detector's intent (per BR-3.6 + ADR-010) is to catch EA-driven ping-pong (same magic+dir within 3s from EA's own close calls), NOT to halt on broker-driven mass SL events.

---

## §5 — Revised Intervention (ADR-013)

**Patch surface:** `core/Orchestrator.mqh::OnTradeTransaction` between line 835 (DEAL_TYPE filter) and line 842 (direction derivation):

```mql5
ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(deal, DEAL_REASON);
if(reason != DEAL_REASON_EXPERT) return;
```

**Filter behavior:** only deals with `DEAL_REASON_EXPERT` (deals initiated by EA via RiskManager) feed CircuitBreaker.RecordClose. Broker-driven closes (`DEAL_REASON_SL`, `DEAL_REASON_TP`, `DEAL_REASON_SO`, `DEAL_REASON_ROLLOVER`, etc.) are skipped. Manual closes (`DEAL_REASON_CLIENT`/`MOBILE`/`WEB`) also skipped per intent (also not EA ping-pong).

**Threshold preserved:** PING_PONG_THRESHOLD_S stays at 3 (unchanged from BR-3.6 spec). The 3s window remains tight enough to catch true EA ping-pong, which always operates via DEAL_REASON_EXPERT.

**Why this is a 3-LOC fix not a slot-side fix:** the false-positive class is at the **producer-side filter** in Orchestrator.OnTradeTransaction. The detector itself (CircuitBreaker.CheckPingPong) is correct — it just needs less noise fed to it. Filtering at the producer keeps CircuitBreaker semantically pure (it still detects ping-pong on whatever events it receives) while cleaning up the input stream.

**Architectural rationale:** documented in ADR-013 § Decision Validation. Cross-references BR-3.6 spec, ADR-010 halted-state semantics, fix-round-10/11 producer-side wiring history.

---

## §6 — Verification Plan (Step 2 + Step 3)

**Step 2 (this session):** G1 PASS (`Result: 0 errors, 0 warnings, 4705 ms`); G2 bootstrap_smoke 3-day PASS (`final balance 502.66 USD`; 0 halt + 0 ERROR in run; behavioral parity with pre-patch smoke since 3-day window has no multi-position SL collision).

**Step 3 (next operator session):** G3 5-yr Bucket A retry (Run #4) via `terminal64.exe /config:simulation/headless-tests/regression_5yr_g4.ini` (default G4-ON build per BT-001 single-pass methodology). Wall-clock ~30-60 min per IMPL-FIX-009 perf restoration.

**Pass criteria (Run #4):**
1. Simulation reaches **at least sim 2021-04-30** (≥ 3 sim months past Slot_H Jan-14 storm point) without `circuit_breaker_pingpong` halt → ADR-013 confirmed effective at eliminating the false-positive class
2. **If Run #4 reaches 2025-12-31:** parse final equity → compute `|drift| = |Net Profit - $24,271,276.63| / $24,271,276.63` → assert ≤ 25% per NFR-1.1 → **IMPL-062 E-AC #1 + #2 close**, IMPL-068 force-clear validation drains alongside, P2/P3/P4 Tier 2 Phase Gate close path opens
3. **If Run #4 reaches 2025-12-31 BUT drift > 25%:** ADR-013 fixed the halt class but R-13 long-tail has another slot causing drift → next IMPL-FIX-013 iteration
4. **If Run #4 still halts via different class** (e.g., journal sustained-write failure NFR-2.2 / margin-call NFR-7.1 / different ping_pong tickets): diagnose new class via ADR-014 or further IMPL-FIX-NNN

**Cap-3 iteration budget per IMPL-FIX-012 task block:** this Step 0 diagnostic + Step 1 patch + Step 2 G1+G2 = iter-1 of 3. Step 3 Run #4 = iter-1 verification. If Run #4 surfaces a different halt class → iter-2 patch; if iter-3 also fails, escalate to `/impl-plan-review all` or `/backtrack sd`.

---

## §7 — Cap-3 Iteration Sequencing

| Iter | Status | Surface | Outcome |
|------|--------|---------|---------|
| iter-1 (this session) | ✅ Step 0 + Step 1 + Step 2 PASS | ADR-013 + Orchestrator.mqh 3-LOC + G1+G2 verify | DEAL_REASON_EXPERT filter applied; G1 0err/0warn; G2 smoke clean. **Step 3 Run #4 deferred to next operator session.** |
| iter-2 (conditional) | pending Run #4 outcome | TBD if Run #4 surfaces new halt class | — |
| iter-3 (conditional) | pending iter-2 outcome | TBD; escalation gate at iter-3 fail → /impl-plan-review all or /backtrack sd | — |

---

## §8 — Closure Statement (Step 0 + Step 1 + Step 2)

**Step 0 ✅ Diagnostic complete:** ManageExits same-bar cooldown hypothesis FALSIFIED (Slot_H entries not clustered; broker-side SL fills don't traverse ManageExits). Revised intervention identified: DEAL_REASON_EXPERT filter at Orchestrator.OnTradeTransaction producer side.

**Step 1 ✅ Patch applied (ADR-013):** 3-LOC + comment in `core/Orchestrator.mqh::OnTradeTransaction` (between DEAL_TYPE and direction derivation). ADR-013 authored at `docs/adr/013-circuitbreaker-pingpong-deal-reason-filter.md` documenting context, decision, alternatives considered (A/B/C/D), consequences, validation, revisit-when, references.

**Step 2 ✅ G1 + G2 PASS:** G1 `Result: 0 errors, 0 warnings, 4705 ms`; G2 bootstrap_smoke 3-day final balance $502.66 (identical to pre-patch); 0 halt + 0 [ERROR] in run.

**Step 3 ⏸ Deferred to next operator session:** G3 5-yr Bucket A retry (Run #4) via `regression_5yr_g4.ini` (~30-60 min wall-clock).

**S-AC closure (this session):** S-AC #1 ✅ (this artifact); S-AC #2 ✅ (G1 0err/0warn — note: original S-AC text described Slot_H::ManageExits patch which was empirically falsified; revised implementation per ADR-013 covers the same intent at correct surface); S-AC #3 ✅ (G2 smoke PASS).

**E-AC closure (deferred):** E-AC #1 + E-AC #2 stay `[ ]` deferred to Step 3 Run #4 (registry expiry 2026-05-28).
