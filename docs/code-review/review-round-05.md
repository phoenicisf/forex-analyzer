# Code Review Round 05

| Field | Value |
|-------|-------|
| **Round** | 05 |
| **Target** | `all` — Post-Round-04 P3 slot delta (commits `b1cbc54` → `e7e0653`): IMPL-018 (`core/SlotRegistry.mqh` + `domain/CSlotBase.mqh`) + 21 slot files in `MQL5/Experts/PhoenicisNex/slots/` (Slot_C, D, F, J, H, K, G, G2, GO, M, L, LX, Q, R, I, T, S, B, BR; BI/P pending) + 21 spike harnesses |
| **Date** | 2026-05-03 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | Round-05 covers the 21-task P3 slot batch closed since fix-round-04 (IMPL-018 → IMPL-038). Cross-cuts: ADR-002 6-method contract, ADR-012 layer discipline (`slots/* ห้าม #include slots/<other>`), ea.md "no direct CTrade in slots" rule, comment-prefix shared-magic disambig (B/BI 214, C/D 200, G/G2 208, L/LX 211), G4 fix BR-7.2 attestation surface (Slot_J), pattern consistency across 19 slot files. |
| **Cumulative LOC reviewed (Round 05 delta)** | ~6,300 LOC across 21 slot files + 2 base files (CSlotBase 132 + SlotRegistry 332) |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 2 |
| HIGH     | 3 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **10** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | All slots stay in MT5 sandbox; no `WebRequest` / external `#import`; no hardcoded credentials. Symbol whitelist enforced upstream (OnInit; Slot files have no broker-API surface beyond MT5 standard headers). |
| 2 | Business Logic Correctness | ⚠️ Finding | **Slot_B / K / L `ManageExits` use `OrdersTotal()` + `OrderGetTicket(i)` — those are MT5 _pending order_ APIs, not _open position_ APIs. Once IMPL-053 wires OrderClose, exit pass will iterate the wrong list and never find market positions to close (Finding 05.2 CRITICAL).** Slot_BR `_HasActiveBROrder` returns bool from `n>0`, ignoring `InpBRMaxOrders` input (Finding 05.3 HIGH). |
| 3 | Error Handling | ✅ Pass | Standard fail-fast patterns at slot level (NULL service guards + early-return). Logger-Error → ExpertRemove for missing-override path (CSlotBase Layer 2) consistent. |
| 4 | Performance | ✅ Pass | Slot iteration is O(n) per tick with n ≤ tickets-per-symbol; comment-prefix filter is StringFind O(prefix_len) per ticket. No N+1 patterns observed. |
| 5 | Over-Engineering | ⚠️ Finding | Slot_J line 176 reads `port.GetByMagic(MAGIC_J)` into local `j_state` then never uses the result — comment claims "G4 fix marker" but it's a dead read; remove or actually consume the SlotState (Finding 05.6 MEDIUM). |
| 6 | Cross-Service Consistency | ⚠️ Finding | **17 slots use `port.GetTicketsForSlot()` + `PositionSelectByTicket` (correct pattern); Slot_H bypasses by looping `PositionsTotal()` directly** (Finding 05.4 HIGH); **Slot_B / K / L call MT5 ORDER APIs instead** (Finding 05.2 CRITICAL). Three inconsistent dialects within a single layer. |
| 7 | Test Coverage Gaps | ⚠️ Finding | **IMPL-023 (Slot_H) / IMPL-024 (Slot_K) / IMPL-025 (Slot_G) have `[ ]` E-AC marked "deferred to IMPL-053+ orchestrator wiring" but NO row in `docs/state/deferred-ac-registry.md`** — Dimension #11 violation (Finding 05.7 HIGH). 17 sibling slots (IMPL-019/020/021/022/026/027/028/029/030/031/032/033/035/036/037/038) are properly registered. |
| 8 | Architecture Compliance | ⚠️ Finding | **Slot_H instantiates `CTrade m_trade_exec` member + calls `m_trade_exec.Buy/Sell/PositionClose` — direct violation of ea.md §"MQL5/MT5-specific idioms" rule "ALL CTrade calls go through RiskManager::OpenOrder or OpenOrder<X> helper — slots ห้าม instantiate CTrade ตรง" + ADR-002 § Composition Root.** Comment at Slot_H.mqh:249 even quotes the rule while violating it (Finding 05.1 CRITICAL). |
| 9 | TD Compliance | ⚠️ Finding | CSlotBase 6-method contract honored (21/21 slots override all 6); ADR-012 layer discipline holds (no `slots/*` → `slots/*` includes; no domain → services except scoped CSlotBase Logger exception). However Slot_H `#include <Trade\Trade.mqh>` directly in slots layer = TD-02 §3.4 violation (slots should consume RiskManager only). |
| 10 | Test Quality | ⚠️ Finding | Slot_J `ManageExits` does not gate on `InpEnableSlotJ` — inconsistent with all 17 other slots (Slot_BR, B, F, etc.) which check `if(!InpEnableSlot<X>) return;` (Finding 05.5 MEDIUM). Spike SelfTests are structural-only — none exercise the Order/Position-API mismatch documented in Finding 05.2. |
| 11 | Empirical AC Closure | ⚠️ Finding | 18 slot tasks correctly registered in `deferred-ac-registry.md` Active table with bounded expiry 2026-05-17 + risk-if-missed text (✅ honors Glossary § Deferred-AC Registry rules). 3 tasks (IMPL-023 / 024 / 025) violate the registry rule (Finding 05.7). G4 fix BR-7.2 surface in Slot_J is structurally correct (3 explicit comments at GetByMagic + GetTicketsForSlot + log message) but unverified — IMPL-022 row in registry tracks this, expiry 2026-05-17. |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — no UI surface; all slot files are header-only `.mqh` consumed by entry `.mq5` at IMPL-018+ (Composition Root). |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; no env-var / secret / API-key consumer (per CLAUDE.md §6 config-audit gate note). All inputs are MT5 `input` declarations + Strategy-Tester sweep-compatible per FR-1.3. |

---

## Findings

### Finding 05.1: 🔴 CRITICAL — Slot_H instantiates `CTrade m_trade_exec` directly, violating ea.md "ALL CTrade calls through RiskManager" + ADR-002 Composition Root

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh`, Lines: 30, 46, 171, 255-257
- Cross-ref rule: `.claude/rules/ea.md` § "MQL5/MT5-specific idioms" — "ALL CTrade calls go through `RiskManager::OpenOrder` or `OpenOrder<X>` helper — slots ห้าม instantiate CTrade ตรง"
- Cross-ref rule: `CLAUDE.md` § 3 Architecture Rules — "ห้าม call MT5 trade API ตรงจาก slot — ต้องผ่าน CTrade wrapper ใน RiskManager หรือ `OpenOrder<X>` helper"
- Cross-ref ADR: `docs/adr/002-...md` Composition Root pattern

**Code:**
```mql5
// Slot_H.mqh:30
#include <Trade\Trade.mqh>             // ← slots layer should not include CTrade directly

// Slot_H.mqh:43-46
class CSlotH : public CSlotBase
  {
private:
   int               m_last_bar_entered;
   CTrade            m_trade_exec;     // ← slot owns its own CTrade — forbidden

// Slot_H.mqh:171 (ManageExits → _TryExit)
   if(!m_trade_exec.PositionClose(ticket))   // ← slot calls CTrade directly

// Slot_H.mqh:249-257 (Evaluate → entry)
   //--- Submit order via CTrade member (not base m_risk CTrade — ea.md: ห้าม instantiate CTrade ตรง)
   //                                              ↑ comment quotes the rule then violates it
   ENUM_ORDER_TYPE order_type = is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   string comment_str = "H,fractal,1";

   bool sent = false;
   if(order_type == ORDER_TYPE_BUY)
      sent = m_trade_exec.Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment_str);   // ← naked Buy
   else
      sent = m_trade_exec.Sell(lot, _Symbol, 0.0, 0.0, 0.0, comment_str);
```

vs sibling pattern in 17 other slots (e.g. Slot_C.mqh:262-263, Slot_G.mqh:285-286, Slot_M.mqh:240-241, Slot_T.mqh:239-240):
```mql5
//--- Submit order through RiskManager CTrade wrapper
//    ห้าม instantiate CTrade direct (ea.md + ADR-002)
```

**Problem:**
Slot_H is the only slot in 21 that instantiates a CTrade member and dispatches `Buy / Sell / PositionClose` directly — sidestepping the `RiskManager` choke point that owns retry policy, retcode handling, comment normalization, fill-policy detection (`SymbolInfoInteger(SYMBOL_FILLING_MODE)`), and journal hooks. The comment at line 249 explicitly cites the rule ("ห้าม instantiate CTrade ตรง") while doing exactly what the rule forbids — false-documentation pattern. This was masked through review rounds because Spike_Slot_H SelfTest is structural (Magic/SlotId/etc.) and never exercises the order-send path. Additionally, the `Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment)` call passes SL=0 + TP=0 — Slot_H is the ONLY slot that opens positions without a stop-loss (other slots compute `sl_price` from `InpXSlPips` before submission), and `InpHSlPips` is read for `RiskManager::ComputeLot` but not threaded into the actual order.

**Why This Matters:**
1. **Architecture-rot precedent.** If Slot_H ships, the next slot author will clone the pattern. The "ALL CTrade through RiskManager" rule becomes nominal.
2. **No retry / retcode policy.** RiskManager owns broker-error handling (filling mode, requote, partial fill). `m_trade_exec.Buy()` returns a bool with retcode buried in `m_trade_exec.ResultRetcode()` — the Warn log at line 273 surfaces it but no retry occurs.
3. **No SL → unbounded drawdown.** `Buy(lot, _Symbol, 0.0, 0.0, 0.0, ...)` opens with broker default (typically no SL). For an H4 EA running unattended, an adverse 200-pip move on a 0.20-lot trade can wipe 40% of a $1000 account before ManageExits catches up. Other slots set `sl_price = price - _PipsToPrice(InpSlPips)` before submission.
4. **Journal-hook bypass.** RiskManager is the planned write-site for entry-event journal records (per TD-02 §5.4); a direct CTrade call won't trigger that hook when wired at IMPL-053+.

**Suggested Fix:**
Remove the CTrade member entirely. Either (a) defer the OrderSend to IMPL-053+ Composition Root the way 17 sibling slots do (log-intent + RiskManager-wrapped close call), or (b) add a `RiskManager::OpenOrderH(direction, lot, sl_pips, comment)` helper now and route through it.

```mql5
// Slot_H.mqh — remove these
- #include <Trade\Trade.mqh>
- CTrade            m_trade_exec;

// Slot_H.mqh:_TryExit — replace direct close
- if(!m_trade_exec.PositionClose(ticket))
+ // ManageExits close: Phase-1 stub log-intent only — IMPL-053+ wires
+ // m_risk.CloseOrder(ticket) per ea.md "ALL CTrade calls through RiskManager"
+ if(m_logger != NULL)
+    m_logger.Info("Slot_H", "exit_profit_gate", MAGIC_H,
+                  StringFormat("ticket=%llu profit_pips=%.1f age=%d", ticket, profit_pips, age_bars));

// Slot_H.mqh:Evaluate — replace direct submit + add SL
- bool sent = (order_type == ORDER_TYPE_BUY)
-    ? m_trade_exec.Buy(lot, _Symbol, 0.0, 0.0, 0.0, comment_str)
-    : m_trade_exec.Sell(lot, _Symbol, 0.0, 0.0, 0.0, comment_str);
+ // Phase-1 stub log-intent only — IMPL-053+ wires
+ // m_risk.OpenOrderH(order_type, lot, InpHSlPips, comment_str) per ea.md
+ double pip_size = _Point * (_Digits == 5 || _Digits == 3 ? 10.0 : 1.0);
+ double price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
+                                               : SymbolInfoDouble(_Symbol, SYMBOL_BID);
+ double sl_price = (order_type == ORDER_TYPE_BUY) ? price - InpHSlPips * pip_size
+                                                  : price + InpHSlPips * pip_size;
+ if(m_logger != NULL)
+    m_logger.Info("Slot_H", "entry_intent", MAGIC_H,
+                  StringFormat("dir=%s lot=%.2f sl_pips=%.1f sl=%.5f comment=%s",
+                               order_type == ORDER_TYPE_BUY ? "BUY" : "SELL",
+                               lot, InpHSlPips, sl_price, comment_str));
+ m_last_bar_entered = ctx.bar_index_h4;
```

**Level of Effort:** Low (mechanical strip + log-intent replace; mirrors 17 sibling slots).

---

### Finding 05.2: 🔴 CRITICAL — Slot_B / Slot_K / Slot_L `ManageExits` use MT5 ORDER APIs (`OrdersTotal()` + `OrderGetTicket(i)` + `OrderGetInteger(ORDER_MAGIC)`) instead of POSITION APIs — will silently iterate wrong list when wired

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh`, Lines: 234-261
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_K.mqh`, Lines: 186-208
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_L.mqh`, Lines: 178-205
- Cross-ref MQL5 docs: `OrdersTotal()` returns count of pending orders (limit/stop); `PositionsTotal()` returns open market positions
- Sibling correct pattern: 17 of 21 slots use `port.GetTicketsForSlot(magic, prefix, tickets)` then `PositionSelectByTicket(ticket)` — see Slot_BR.mqh:170-184, Slot_M.mqh:289-310, Slot_T.mqh:287-309

**Code:**
```mql5
// Slot_B.mqh:234-244 — wrong API family
   //--- Iterate open orders for magic MAGIC_B, comment prefix "B,"
   for(int i = OrdersTotal() - 1; i >= 0; i--)         // ← pending orders, not positions
     {
      ulong ticket = OrderGetTicket(i);                // ← pending-order ticket
      if(ticket == 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) != MAGIC_B)      // ← reads pending-order magic
         continue;
      string order_comment = OrderGetString(ORDER_COMMENT);
      if(StringFind(order_comment, "B,") != 0)
         continue;
      ...
      double open_price  = OrderGetDouble(ORDER_PRICE_OPEN);
      ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
```

vs Slot_BR.mqh:170-184 (correct sibling):
```mql5
   //--- Retrieve BR tickets (own magic MAGIC_BR=215, comment prefix "BR,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
   if(n <= 0) return;

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];
      if(!PositionSelectByTicket(ticket)) continue;
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
```

vs Slot_H.mqh:193-204 (sibling using direct PositionsTotal — also non-canonical, see 05.4):
```mql5
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) != MAGIC_H) continue;
```

**Problem:**
In MT5, **open market positions** are accessed through `PositionsTotal() / PositionGetTicket(i) / PositionGetInteger(POSITION_*)`; **pending orders** (limits and stops) live on a separate list accessed through `OrdersTotal() / OrderGetTicket(i) / OrderGetInteger(ORDER_*)`. Slot_B / K / L's `ManageExits` walks the pending-order list — which is empty for slots that only open market orders (B's `Evaluate` ends at `ORDER_TYPE_BUY/SELL`, not `ORDER_TYPE_BUY_LIMIT`). **The exit gate body never executes.** This is masked today because all three slots are stubbed to "log intent only — IMPL-053+ wiring", so today the body is a no-op anyway. But once IMPL-053 wires the close call, the loop will still walk the wrong list and the slot's exit pass becomes non-functional. The bug is invisible to compile-gate G1 (it's well-formed MQL5) and invisible to spike SelfTest (it doesn't open positions). It will surface as silent regression at the IMPL-053 + Strategy-Tester smoke run — *after* the deferred E-AC trips.

**Why This Matters:**
1. **Three slots can never close their own positions once wired.** Slot_B is parent of BR/BI cascade (IMPL-037→038→039); a non-firing exit gate cascades into the entire B/BR/BI chain.
2. **Slot_K is a dependency of Slot_S** (post-close trigger per IMPL-036). Broken K exit ⇒ S never sees post-close transition.
3. **Bucket A regression risk (NFR-1.1).** Net-Profit deviation ≤ 25% can blow up if 3 of 21 slots silently never close trades.
4. **Inconsistent dialect.** Three different patterns in 21 files (Order*, Position*, port.GetTicketsForSlot) — pick one for the sane choice (port.GetTicketsForSlot per ADR-005 + ADR-012).

**Suggested Fix:**
Replace the Order* family with the canonical `port.GetTicketsForSlot()` + `PositionSelectByTicket()` pattern from Slot_BR / 16 other slots:

```mql5
// Slot_B.mqh:228-294 ManageExits — replace inner loop
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotB) return;
      if(m_logger == NULL) return;

      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_B, "B,", tickets);   // shared-magic + prefix disambig
      if(n <= 0) return;

      for(int i = 0; i < n; i++)
        {
         ulong ticket = tickets[i];
         if(!PositionSelectByTicket(ticket)) continue;

         ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double             cur_price  = (pos_type == POSITION_TYPE_BUY)
                                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double price_diff = (pos_type == POSITION_TYPE_BUY) ? (cur_price - open_price)
                                                             : (open_price - cur_price);
         double profit_pips = _PriceDiffToPips(price_diff);

         //--- BR-trigger hook stub (IMPL-053 — BR-2.2 orphan exit) preserved as-is

         if(profit_pips < InpBTpProfitPips) continue;
         m_logger.Info("Slot_B", "exit_profit_gate", Magic(),
                       StringFormat("ticket=%I64u profit_pips=%.1f", ticket, profit_pips));
         //--- Phase-1 stub: close via m_risk at IMPL-053+
        }
     }
```

Apply identical replacement to Slot_K.mqh:180-227 and Slot_L.mqh:172-219.

**Level of Effort:** Low (3 files × ~30 LOC each; copy from Slot_BR template).

---

### Finding 05.3: 🟠 HIGH — Slot_BR `_HasActiveBROrder` returns bool from `n>0`, ignoring `InpBRMaxOrders` input

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh`, Lines: 74-79, 137
- Cross-ref input declaration: `inputs/Inputs_Slot_BR.mqh:22` — `input int InpBRMaxOrders = 1;`
- Sibling pattern: Slot_B.mqh:87-94 `_CountBOrders` returns count; Slot_B.mqh:170 compares `>= InpBMaxOrders`
- Cross-ref task scope: IMPL-038 § "S-AC: Magic() returns MAGIC_BR (215); SlotId() returns "BR"; comment prefix "BR," used in OrderSend"

**Code:**
```mql5
// Slot_BR.mqh:74-79
   bool              _HasActiveBROrder(CPortfolioState &port) const
     {
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
      return n > 0;     // ← collapses count → bool; ignores InpBRMaxOrders
     }

// Slot_BR.mqh:135-137 (Evaluate)
   //--- Own-active guard: max InpBRMaxOrders BR orders simultaneously    ← comment lies
   if(_HasActiveBROrder(port)) return;                                    ← actually max=1
```

vs Slot_B.mqh:87-94 + 170:
```mql5
   int               _CountBOrders(CPortfolioState &port) const
     {
      ulong tickets[];
      return port.GetTicketsForSlot(MAGIC_B, "B,", tickets);
     }
   ...
   if(_CountBOrders(port) >= InpBMaxOrders) return;
```

**Problem:**
The header comment in Inputs_Slot_BR.mqh:22 declares `InpBRMaxOrders = 1` and the slot comment at 136 says "max InpBRMaxOrders BR orders simultaneously", but the actual gate is `n > 0` — i.e. always max 1, regardless of operator-tuned input. Default value 1 makes this work coincidentally; if an operator raises `InpBRMaxOrders` to 2 in the Strategy-Tester sweep (FR-1.3 optimization compatibility) or in a live scenario where multiple orphan-exit BR positions are intended, the input is silently ignored. The comment becomes false-documentation — same anti-pattern as Slot_H Finding 05.1.

**Why This Matters:**
1. **Strategy-Tester sweep ineffective on `InpBRMaxOrders`** — FR-1.3 guarantees ≥80 inputs are sweep-compatible, but a sweep on this input produces identical results, masking optimization signal.
2. **Operator surprise.** A user who tunes `InpBRMaxOrders = 3` expects 3 simultaneous BR orders; the EA silently caps at 1.
3. **Inconsistent with Slot_B precedent** — pattern drift inside the same B/BR/BI chain.

**Suggested Fix:**
```mql5
// Slot_BR.mqh:74-79 — return count, compare at call site
-   bool              _HasActiveBROrder(CPortfolioState &port) const
-     {
-      ulong tickets[];
-      int n = port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
-      return n > 0;
-     }
+   int               _CountBROrders(CPortfolioState &port) const
+     {
+      ulong tickets[];
+      return port.GetTicketsForSlot(MAGIC_BR, "BR,", tickets);
+     }

// Slot_BR.mqh:135-137 — gate against InpBRMaxOrders
-   if(_HasActiveBROrder(port)) return;
+   if(_CountBROrders(port) >= InpBRMaxOrders) return;
```

**Level of Effort:** Low (rename helper + change predicate).

---

### Finding 05.4: 🟠 HIGH — Slot_H bypasses `port.GetTicketsForSlot` and loops `PositionsTotal()` directly — third inconsistent dialect across the slots layer

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh`, Lines: 130-145, 190-204
- Cross-ref ADR: ADR-005 (PortfolioState owns CHashMap-by-magic; centralized ticket retrieval); ADR-012 (slot-to-slot data only via PortfolioState)
- 16 sibling slots use `port.GetTicketsForSlot(...)` (see Slot_C.mqh:115, Slot_BR.mqh:171, etc.)

**Code:**
```mql5
// Slot_H.mqh:130-145 _CountHOrders
int CSlotH::_CountHOrders() const
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) == MAGIC_H)
        {
         string cmt = PositionGetString(POSITION_COMMENT);
         if(StringFind(cmt, "H,") == 0)
            count++;
        }
     }
   return count;
  }

// Slot_H.mqh:190-204 ManageExits also iterates PositionsTotal directly
```

**Problem:**
Slot_H bypasses `PortfolioState.GetTicketsForSlot()` and walks the global position list each call. While the API used (`Position*`) is *correct* (unlike Finding 05.2's Order* misuse), it bypasses the central choke point that ADR-005 + ADR-012 mandate for ticket retrieval — the same data path that owns CHashMap-by-magic O(1) state lookup, comment-prefix disambig, and (future) cross-slot dependency reads. Three dialects now exist: (a) `port.GetTicketsForSlot` + `PositionSelectByTicket` (17 slots — canonical); (b) raw `PositionsTotal` + `PositionGetTicket` (Slot_H — partial bypass); (c) raw `OrdersTotal` + `OrderGetTicket` (Slot_B/K/L — wrong API, Finding 05.2). Three dialects in 21 files = 14% drift — code-review gate must converge.

**Why This Matters:**
1. **ADR-012 drift.** "Slot-to-slot data via `PortfolioState.GetByMagic()` only" — Slot_H *technically* doesn't read other slots, but reading own positions through PositionsTotal sets the precedent that the central choke is optional.
2. **Future shared-magic regressions.** When MAGIC_H = 205 stays unique in P3, the bypass is benign; if a future shared-magic slot copies the pattern (as Slot_B partly did), comment-prefix disambig is implemented per-slot inconsistently.
3. **Performance under fragmentation.** `PortfolioState` is the planned hot-path cache (CHashMap); each `PositionsTotal()` loop is O(n) live-query against MT5 broker state.

**Suggested Fix:**
Same template as Finding 05.2:
```mql5
// Slot_H.mqh:130-145 _CountHOrders → use PortfolioState
int CSlotH::_CountHOrders(CPortfolioState &port) const   // ← add port param
  {
   ulong tickets[];
   return port.GetTicketsForSlot(MAGIC_H, "H,", tickets);
  }

// Slot_H.mqh:190+ ManageExits → use PortfolioState
void CSlotH::ManageExits(CPortfolioState &port)
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_H, "H,", tickets);
   if(n <= 0) return;
   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];
      if(!PositionSelectByTicket(ticket)) continue;
      // ... existing profit / age computation
     }
  }
```

**Level of Effort:** Low (~2 helpers + 1 method body).

---

### Finding 05.5: 🟡 MEDIUM — Slot_J `ManageExits` does not gate on `InpEnableSlotJ` — inconsistent with all 17 other slots; dead code pattern

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh`, Lines: 169-172
- Sibling pattern (17 slots all gate): Slot_BR.mqh:166, Slot_B.mqh:230, Slot_C.mqh:309, Slot_F.mqh:166, etc.

**Code:**
```mql5
// Slot_J.mqh:169-172
void CSlotJ::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;          // ← only checks logger, not enable flag
   //--- ⚠️ G4 fix BR-7.2 — iterate MAGIC_J ...
```

vs Slot_BR.mqh:164-167:
```mql5
void CSlotBR::ManageExits(CPortfolioState &port)
  {
   if(!InpEnableSlotBR) return;          // ← canonical guard
   if(m_logger == NULL) return;
```

**Problem:**
17 sibling slots gate `ManageExits` on `InpEnableSlot<X>`; Slot_J does not. If an operator disables Slot_J via `InpEnableSlotJ = false`, Slot_J's `Evaluate` is gated (line 130) but `ManageExits` still iterates J tickets every tick. Two interpretations: (a) intentional — disabled slot must still close existing positions to avoid orphan tickets; (b) bug — operator expects "disabled = no-op". Neither is documented. The pattern drift makes the contract ambiguous. Same scenario in 17 other slots resolves the ambiguity by full disable = full no-op.

Combined with line 176-181 `j_state` dead read (also raised in Finding 05.6), Slot_J accumulates two anomalies on the G4-attestation surface — exactly the file that should be tightest given Bucket B / NFR-1.8 risk attribution.

**Why This Matters:**
1. Operator confusion about disable semantics on the highest-risk slot in P3.
2. If "disabled = still managing exits" is the desired semantic, *every* slot needs the same exception (otherwise Slot_J's behavior diverges). Document and apply uniformly.
3. G4 attestation surface should be the cleanest code in the slots layer; pattern drift here weakens audit confidence.

**Suggested Fix:**
Pick one and apply uniformly. Recommended: gate at the same line 169 as siblings:
```mql5
void CSlotJ::ManageExits(CPortfolioState &port)
  {
+   if(!InpEnableSlotJ) return;
   if(m_logger == NULL) return;
```

If the divergence is intentional (manage-exits-while-disabled), document it in CSlotBase or in BR-2.2/ADR-002 and apply the same exemption to all slots that own positions — not just Slot_J.

**Level of Effort:** Low (1 line + handoff note).

---

### Finding 05.6: 🟡 MEDIUM — Slot_J `ManageExits` reads `port.GetByMagic(MAGIC_J)` into local `j_state` then never uses the result — dead code masquerading as G4 fix marker

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh`, Lines: 173-181

**Code:**
```mql5
// Slot_J.mqh:173-181
   //--- ⚠️ G4 fix BR-7.2 — iterate MAGIC_J (was MAGIC_F bug in PhoenicisN2.10).
   //    GetByMagic(MAGIC_J) returns SlotState for J; NULL is tolerated (warns
   //    via PortfolioState if magic unregistered, per ADR-005 contract).
   SlotState *j_state = port.GetByMagic(MAGIC_J);   // G4 fix BR-7.2 — was MAGIC_F
   if(j_state == NULL)
     {
      //--- SlotState not registered yet (pre-Orchestrator wiring); benign in
      //    Phase 1 MVP — fall through to direct ticket iteration.
     }
   //--- Retrieve J tickets ...
```

**Problem:**
`j_state` is assigned, NULL-checked, and then unused. The empty `if(j_state == NULL)` body has no fall-through behavior — execution proceeds identically whether `j_state` is NULL or not. The comment claims this is a "G4 fix BR-7.2" anchor but the actual G4 fix is in the *next* line (`GetTicketsForSlot(MAGIC_J, "J,", tickets)` at line 186). The dead read does no work and inflates the audit surface — a future engineer reading this expects `j_state` to drive a check (e.g., reading lot ratio or sub-mode); they'll add the check, then the empty `if(NULL)` branch becomes a real bug-vector when SlotState really is unregistered post-MVP.

**Why This Matters:**
1. Round 04 already cited a similar case (`m_portfolio` member dead in PMR — Finding 04.7) and accepted it as anti-pattern carry-forward. Same pattern now appearing in Slot_J despite being on the highest-risk task in P3.
2. G4 fix attestation file (`g4-fix-attestation.md` — pending IMPL-039 BI fix per registry row) will cite Slot_J's commit as the BR-7.2 source of truth; auditors hitting this dead read will doubt the rest of the surface.

**Suggested Fix:**
Either remove the dead read or actually consume `j_state`:
```mql5
// Option A — remove (recommended for Phase-1 MVP)
-   SlotState *j_state = port.GetByMagic(MAGIC_J);   // G4 fix BR-7.2 — was MAGIC_F
-   if(j_state == NULL)
-     {
-      //--- SlotState not registered yet (pre-Orchestrator wiring); benign in
-      //    Phase 1 MVP — fall through to direct ticket iteration.
-     }

// Option B — use it for PendingState gate (when relevant)
+   SlotState *j_state = port.GetByMagic(MAGIC_J);
+   // No-op when state unregistered (pre-Orchestrator); explicit branch.
+   if(j_state != NULL && j_state.pending_state == PENDING_STATE_PENDING)
+      return;   // J is mid-pending; skip exit pass per BR-6.x
```

**Level of Effort:** Low (1 block).

---

### Finding 05.7: 🟠 HIGH — IMPL-023 / IMPL-024 / IMPL-025 closed with deferred E-AC but no row in `deferred-ac-registry.md` — Dimension #11 violation

**Location:**
- File: `docs/state/impl-plan.md`, IMPL-023 (Slot_H) E-AC line ~915, IMPL-024 (Slot_K) E-AC line ~932, IMPL-025 (Slot_G) E-AC ~944
- File: `docs/state/deferred-ac-registry.md` — Active table missing entries for IMPL-023, IMPL-024, IMPL-025
- Cross-ref rule: `deferred-ac-registry.md` § Rules #1 — "Every defer requires an entry here"
- Cross-ref persona: `andm-code-reviewer/SKILL.md` Dimension #11 — "AC checkbox `[x]` พร้อม 'deferred' note → CRITICAL closure-rule violation"

**Code:**
```markdown
# impl-plan.md — IMPL-023 Slot_H
- **E-AC**:
  - [ ] Smoke 60-day backtest with only Slot H active → ≥ 1 entry+exit cycle journaled
        `[log-assertion]` + `[db-inspect]` — **deferred to IMPL-053+ orchestrator wiring**
        (G2-G4 reactivate per IMPL-018 precedent — Slot file is header-only `.mqh` until
        entry `.mq5` consumes via Composition Root); follow-up via IMPL-P3-GATE Empirical Demo
- **Closed**: 2026-05-03 (commit `467b20e`); ...

# deferred-ac-registry.md § Active — IMPL-023 row absent (no IMPL-023, IMPL-024, IMPL-025)
```

vs canonical sibling — IMPL-026 / 029 / 030 / 027 / 028 / 031 / 019..038 all have explicit registry rows with `Opened: 2026-05-03 / Expires: 2026-05-17 / Risk if missed: <text>`.

**Problem:**
The text "deferred to IMPL-053+ orchestrator wiring" appears 18 times in `impl-plan.md` (one per P3 slot E-AC). 18 of those tasks are properly registered with bounded expiry + risk-if-missed in the Active table per Glossary § Deferred-AC Registry. Three (IMPL-023 / 024 / 025) are not — the word "deferred" appears in the AC body but no Active row exists. Two interpretations: (a) the AC is `[ ]` open and counts as not-yet-closed → registry row optional, but task closure with open `[ ]` E-AC is itself an anomaly; (b) the engineer treated "header-only `.mqh` deferred to IMPL-053+" as an exception that doesn't need registration. Neither is sanctioned by the Glossary. Dimension #11 says "engineer cannot mark task `[x]` without entry" — the task is "Closed: 2026-05-03" while AC is `[ ]` and not-registered. 18 sibling tasks proved the registration is the correct pattern; 3 outliers are a discipline gap.

A corollary observation: this gap proves the value of Dimension #11. If 3 of 21 slot tasks miss the registry, expiry tracking is incomplete — at expiry 2026-05-17, `/impl-task` HALTs on the 18 registered rows but cannot detect the 3 unregistered ones. Operators believe the deferred set is fully tracked; the 3 are silently overdue.

**Why This Matters:**
1. **Three tasks fall through expiry-trip.** No HALT at 2026-05-17 → if IMPL-053 slips, IMPL-023/024/025's deferred E-ACs go unverified indefinitely.
2. **Phase Gate drain false-positive.** Glossary rule: "Phase Gate drain blocks if any registry row's Phase matches the closing phase". P3 Phase Gate would believe drain is complete (registered rows resolved) while 3 silent-deferred tasks remain.
3. **Audit weakness.** Code review *did not* catch this in rounds 02/03 because the "Closed" status + non-`[x]` AC combination is novel; Round 05 is the first batch to surface the gap.

**Suggested Fix:**
Add 3 rows to `docs/state/deferred-ac-registry.md` Active table — same format as the 18 sibling rows. Use `Opened: <commit-date>`, `Expires: 2026-05-17`, evidence-kind `log-assertion`, risk-text per slot (Slot_H: independent baseline; Slot_K: S post-close dep; Slot_G: G2/I/GO multi-slot fanout root):

```markdown
| P3 | IMPL-023 | Smoke 60-day backtest with only Slot H active → ≥ 1 entry+exit cycle journaled `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager wiring + 60-day Tester run with InpEnableSlotH=true required. Spike_Slot_H 5 SelfTest cases pass structurally | Kritsana | 2026-05-03 | 2026-05-17 | Slot H independent-baseline production behavior untested |
| P3 | IMPL-024 | Smoke 60-day backtest with only Slot K active → ≥ 1 entry+exit cycle journaled `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent ... | Kritsana | 2026-05-03 | 2026-05-17 | Slot K production untested; downstream IMPL-036 S post-close depends on K close events |
| P3 | IMPL-025 | Smoke 60-day backtest with only Slot G active → ≥ 1 entry+exit cycle journaled + GOverload BR-8.4 stub trace `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent ... | Kritsana | 2026-05-03 | 2026-05-17 | Slot G production untested; G2/I/GO fanout root — drift cascades |
```

**Level of Effort:** Low (3 registry rows + verify the `[ ]` AC text matches verbatim).

---

### Finding 05.8: 🟡 MEDIUM — Slot_B `ManageExits` BR-trigger comment claims "pre-close trigger: emit hook before OrderClose returns" but no OrderClose is wired

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh`, Lines: 265-275

**Code:**
```mql5
// Slot_B.mqh:265-275
   //--- BR-trigger hook (BR-2.2 orphan exit-only spawn)
   //    CodeWiki §3.18 — BusinessLogic_BR called from inside
   //    ExtraTakeProfit_B when a B order closes. Real wiring lands
   //    at IMPL-053 CrossSlotCoordinator; gated `false` keeps G1
   //    compile clean and intent visible per Slot_G precedent.
   //    Pre-close trigger: emit hook before OrderClose returns.
   if(m_xslot != NULL && false /*IMPL-053 — BR-2.2 orphan exit*/)
     {
      // m_xslot.TriggerBR(MAGIC_BR, otype, OrderGetDouble(ORDER_VOLUME_CURRENT),
      //                   profit_pips, "S" /*br_mode placeholder*/);
     }
```

**Problem:**
The comment says "pre-close trigger: emit hook **before** OrderClose returns" but the loop never calls OrderClose (Phase-1 stub log-only). When IMPL-053 wires CrossSlotCoordinator + RiskManager.CloseOrder, the hook position relative to the close call matters: emitting *before* close means BR sees a still-open B parent; *after* close means BR sees a closed B (orphan-exit semantics per BR-2.2). The current placement (BEFORE the profit-gate check at line 283) means the hook fires every tick that a B position is open (regardless of whether the close fires) — that's neither "pre-close" nor "post-close"; it's "every-tick-while-open". The future maintainer will read the comment, expect the gated body to fire on close, and either move it or add `m_risk.CloseOrder()` and end up firing TriggerBR twice (once every tick + once at the actual close).

Additionally, the commented-out body at line 273-274 references `OrderGetDouble(ORDER_VOLUME_CURRENT)` — same Order* family as Finding 05.2. When uncommented, it walks pending-order data for what should be a position close.

**Why This Matters:**
1. **Wiring-time confusion.** IMPL-053 author reads the comment, places the hook wrong.
2. **BR-2.2 semantic ambiguity.** The CodeWiki §3.18 contract specifies orphan-exit spawn happens *because* B closed, not while B is open.
3. Same Order* misuse pattern as Finding 05.2 in the commented body — auditor cannot rule out the bug will be reintroduced when uncommented.

**Suggested Fix:**
Move the hook stub *after* the profit-gate close (which itself doesn't exist yet — preserve as comment) and switch the commented body to Position* APIs:

```mql5
// Slot_B.mqh:282-294 — re-order
         if(profit_pips < InpBTpProfitPips) continue;
         if(m_logger != NULL)
            m_logger.Info("Slot_B", "exit_profit_gate", Magic(),
                          StringFormat("ticket=%I64u profit_pips=%.1f", ticket, profit_pips));
         //--- Phase-1 stub: m_risk.CloseOrder(ticket) at IMPL-053+
         //    Post-close BR-trigger hook (orphan-exit spawn per BR-2.2):
         if(m_xslot != NULL && false /*IMPL-053 — BR-2.2 orphan exit; fires AFTER close*/)
           {
            // m_xslot.TriggerBR(MAGIC_BR, pos_type, PositionGetDouble(POSITION_VOLUME),
            //                   profit_pips, "S" /*br_mode placeholder*/);
           }
```

**Level of Effort:** Low.

---

### Finding 05.9: 🔵 LOW — Slot_H.mqh:249 comment "ห้าม instantiate CTrade ตรง" while doing exactly that — false-documentation pattern

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_H.mqh`, Line: 249

**Code:**
```mql5
   //--- Submit order via CTrade member (not base m_risk CTrade — ea.md: ห้าม instantiate CTrade ตรง)
```

**Problem:**
The comment quotes the project rule ("ห้าม instantiate CTrade ตรง") in the same line as the code that violates it. False-documentation slows future code review (reader must verify the comment's claim vs the code) and proves Finding 05.1's violation was *aware* (engineer knew the rule), not accidental. Already covered structurally by Finding 05.1, but the comment itself deserves explicit removal.

**Why This Matters:**
False-documentation patterns degrade trust in all comments. Future reviewers must distrust every CTrade-related comment in slots/ as a result.

**Suggested Fix:**
Resolve via Finding 05.1 fix; if the m_trade_exec member is removed, this comment goes with it. If for any reason the member is preserved (it should not be), at minimum rewrite the comment to admit the deviation and cite the ADR exemption — but no such exemption exists, so the comment must go.

**Level of Effort:** Trivial (resolved as part of 05.1).

---

### Finding 05.10: 🔵 LOW — `CSlotRegistry::Init()` does not check for re-init; second call leaks `m_slots[]` if `m_owns_slots == true`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh`, Lines: 104-110

**Code:**
```mql5
   void              Init(CLogger *lg)
     {
      m_logger = lg;
      m_count = 0;                                  // ← reset count without releasing
      for(int i = 0; i < PHOENICISNEX_SLOT_CAPACITY; i++)
         m_slots[i] = NULL;                         // ← NULLs pointers without delete
     }
```

**Problem:**
`Init()` clears `m_slots[]` and resets `m_count = 0` without checking whether the registry was already populated. If a caller invokes `RegisterAll() → Init() → ReleaseAll()` (e.g. re-init cycle on OnInit re-entry per CleanupPartialInit per TD-02 §7.4.1), the first `Init` zeros pointers without `delete` — heap leak when `m_owns_slots == true`. ReleaseAll *would* have done it correctly, but Init bypasses ReleaseAll. Today the test harnesses set `SetOwnsSlots(false)` before Add, so SelfTest doesn't leak; production wiring at IMPL-053+ will set `m_owns_slots = true` (heap allocation in RegisterAll) and the leak surfaces on re-init.

**Why This Matters:**
1. OnInit re-entry leaks 21 CSlotBase derivatives every cycle (~21 × 200 bytes vtable + members).
2. Doesn't trip on Phase 1 sub-pass (RegisterAll stub returns false, m_count stays 0), but lurks until IMPL-053.

**Suggested Fix:**
```mql5
   void              Init(CLogger *lg)
     {
+     ReleaseAll();          // safe re-init: respects m_owns_slots
      m_logger = lg;
-     m_count = 0;
-     for(int i = 0; i < PHOENICISNEX_SLOT_CAPACITY; i++)
-        m_slots[i] = NULL;
     }
```

**Level of Effort:** Trivial (1 line).

---

## Cross-Service Issues

| # | Issue | Affected Files | Severity |
|---|-------|----------------|----------|
| X1 | Three different ticket-iteration dialects (port.GetTicketsForSlot / raw PositionsTotal / raw OrdersTotal) within a single layer | Slot_B, Slot_K, Slot_L (Order*) ; Slot_H (PositionsTotal) ; 17 others (port.GetTicketsForSlot) | Captured under Findings 05.2 + 05.4 |
| X2 | Comment-prefix shared-magic disambig logic encoded ad hoc in each slot rather than centralized in PortfolioState.GetTicketsForSlot's StringFind | Slot_B.mqh:88, Slot_H.mqh:140, Slot_LX.mqh:85-92 | Documented; LOW (centralization is a Phase 2 refactor) |
| X3 | `simulation/headless-tests/slot_<X>_smoke.ini` files committed per task per TD-02 §13.6 — verified present for all 21 slot tasks (B, BR, C, D, F, G, G2, GO, H, I, J, K, L, LX, M, Q, R, S, T) | All `.ini` files in `simulation/headless-tests/` | ✅ Pass |

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 05.1 | 🔴 CRITICAL | 8 Architecture | Slot_H instantiates CTrade directly + opens with SL=0 | `slots/Slot_H.mqh:30,46,171,255-257` | Low |
| 05.2 | 🔴 CRITICAL | 2 Logic / 6 Cross-svc | Slot_B/K/L use MT5 ORDER APIs instead of POSITION APIs | `slots/Slot_B.mqh:234-261`, `Slot_K.mqh:186-208`, `Slot_L.mqh:178-205` | Low |
| 05.3 | 🟠 HIGH | 2 Logic | Slot_BR `_HasActiveBROrder` ignores `InpBRMaxOrders` | `slots/Slot_BR.mqh:74-79,137` | Low |
| 05.4 | 🟠 HIGH | 6 Cross-svc / 8 Arch | Slot_H bypasses PortfolioState.GetTicketsForSlot via raw PositionsTotal | `slots/Slot_H.mqh:130-145,190-204` | Low |
| 05.5 | 🟡 MEDIUM | 10 Test Quality | Slot_J ManageExits missing `InpEnableSlotJ` gate | `slots/Slot_J.mqh:169-172` | Low |
| 05.6 | 🟡 MEDIUM | 5 Over-engineering | Slot_J dead `j_state` read masquerading as G4 marker | `slots/Slot_J.mqh:173-181` | Low |
| 05.7 | 🟠 HIGH | 11 E-AC Closure | IMPL-023/024/025 deferred E-AC missing from registry | `docs/state/deferred-ac-registry.md` | Low |
| 05.8 | 🟡 MEDIUM | 2 Logic | Slot_B BR-trigger comment claims "pre-close" but fires every tick | `slots/Slot_B.mqh:265-275` | Low |
| 05.9 | 🔵 LOW | 9 TD Compliance | Slot_H comment "ห้าม instantiate CTrade ตรง" while violating | `slots/Slot_H.mqh:249` | Trivial |
| 05.10 | 🔵 LOW | 3 Error Handling | `CSlotRegistry::Init()` re-init heap leak risk | `core/SlotRegistry.mqh:104-110` | Trivial |
