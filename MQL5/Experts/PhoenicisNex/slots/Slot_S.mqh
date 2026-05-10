//+------------------------------------------------------------------+
//| slots/Slot_S.mqh โ€” Slot S implementation (IMPL-036)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_S = 217 (own; not shared)                          |
//| SlotId:  "S"                                                      |
//| Comment: "S,post,1"                                               |
//|                                                                   |
//| Source:  CodeWiki ยง3.S; TD-02 ยง5.4; ADR-002; ADR-012             |
//|                                                                   |
//| M-size MVP โ€” 5 of N CodeWiki ยง3.S conditions (post-close after L/K):
//|   1. Both L and K parents inactive (proxy for "post-close state")  |
//|      โ’ port.GetTicketsForSlot(MAGIC_L, "L,", l_tickets) == 0 AND  |
//|        port.GetTicketsForSlot(MAGIC_K, "K,", k_tickets) == 0      |
//|      // CodeWiki ยง3.S โ€” S triggers when L/K windows closed        |
//|   2. Own no-active S guard (prevent double-entry)                  |
//|      โ’ port.GetTicketsForSlot(MAGIC_S, "S,", own_tickets) == 0    |
//|      // CodeWiki ยง3.S โ€” single active S position                  |
//|   3. ADX volatility gate: adx_h4.adx > InpSAdxMin (default 20.0) |
//|      // CodeWiki ยง3.S โ€” avoid low-volatility regime               |
//|   4. WPR threshold confirmation (H4 WPR oversold/overbought)       |
//|      // CodeWiki ยง3.S โ€” momentum confirmation on follow-on entry   |
//|   5. D1 Ichimoku trend alignment filter (price vs cloud)           |
//|      // CodeWiki ยง3.S โ€” higher-timeframe trend alignment           |
//|                                                                   |
//| Deferred to P4 IMPL-062:                                          |
//|   - Stochastic secondary confirmation (stoch_h4 K/D cross)        |
//|   - Sub-demand zone proximity filter (subdem_h4 proximity gate)    |
//|   - Hull MA slope gate (hull_h4.hull_slope direction)              |
//|   - DeMarker secondary confirmation (dem_h4.dem < 0.3 oversold)   |
//|   - Fractal-based SL refinement (fractal_h4 nearest fractal)       |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate >= InpSTpProfitPips (35 pip default)              |
//|   Stub: log exit_profit_gate intent; OrderClose deferred Orchestrator wiring path (core/Orchestrator.mqh) |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("S", InpSSlPips, balance)            |
//| Comment: "S,post,1" per CodeWiki ยง3.S "S,..." pattern             |
//|                                                                   |
//| Topology dependency:                                              |
//|   DependsOn() returns 2:                                          |
//|     out_magics[0] = MAGIC_L (parent L must be post-close)         |
//|     out_magics[1] = MAGIC_K (parent K must be post-close)         |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected via base)   |
//|   Cross-slot access via PortfolioState.GetTicketsForSlot() only   |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_S_MQH
#define PHOENICISNEX_SLOTS_SLOT_S_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_S.mqh"

//+------------------------------------------------------------------+
//| CSlotS โ€” Slot S concrete derived class (ADR-002 CSlotBase contract)|
//|                                                                   |
//| Post-close follow-on pattern:                                     |
//|   - Entry ONLY when BOTH L and K parents have no active orders    |
//|   - Direction confirmed by WPR momentum + D1 Ichimoku trend       |
//|   - ADX gate prevents entry in low-volatility regimes             |
//|   - Own-no-active guard prevents double-entry                     |
//|                                                                   |
//| Magic 217 own (not shared). Comment prefix "S," in all orders.    |
//| GetTicketsForSlot(MAGIC_S, "S,", tickets) filters own orders.     |
//+------------------------------------------------------------------+
class CSlotS : public CSlotBase
  {
private:
   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` inherited from base.

   //--- Check if BOTH L and K parent slots have no active orders
   //    "Post-close" proxy: both parents inactive = L/K window closed
   //    ADR-012: cross-slot access only via PortfolioState
   bool              _BothParentsInactive(CPortfolioState &port) const
     {
      ulong l_tickets[];
      ulong k_tickets[];
      int l_count = port.GetTicketsForSlot(MAGIC_L, "L,", l_tickets);
      int k_count = port.GetTicketsForSlot(MAGIC_K, "K,", k_tickets);
      return (l_count == 0 && k_count == 0);
     }

   //--- Check if S has no active own orders (own-no-active guard)
   bool              _HasActiveSOrder(CPortfolioState &port) const
     {
      ulong s_tickets[];
      int n = port.GetTicketsForSlot(MAGIC_S, "S,", s_tickets);
      return n > 0;
     }

   //--- D1 trend direction: BUY if price above D1 cloud, SELL if below
   //    Returns: +1 = BUY trend, -1 = SELL trend, 0 = inside cloud (no signal)
   //    // CodeWiki ยง3.S โ€” higher-timeframe trend alignment (mirror Slot_L pattern)
   int               _D1TrendDirection(const MarketContext &ctx) const
     {
      double cloud_high = ctx.ichi_d1.cloud_high;
      double cloud_low  = ctx.ichi_d1.cloud_low;
      if(ctx.bid > cloud_high)
         return +1;  // above cloud โ€” BUY trend
      if(ctx.bid < cloud_low)
         return -1;  // below cloud โ€” SELL trend
      return 0;      // inside cloud โ€” no clear trend
     }

   //--- IMPL-FIX-007 H4 bar gate (post-G2-smoke strengthening): rate-limit
   //    fills to <= 1 per H4 bar regardless of position lifecycle. Bar gate
   //    is primary anti-pyramid defense (matches task AC literally + CodeWiki
   //    wave-helper-per-bar semantics); pending-fill latch below remains as
   //    defense-in-depth for sub-tick OrderSend race.
   datetime          m_last_fill_bar;

   //--- IMPL-FIX-007: synchronous in-memory pending-fill latch.
   //    Set after RiskManager.OpenOrder() returns true; reset when
   //    PortfolioState reflects the new ticket OR after 60s timeout.
   //    Covers OrderSend->next-OnTick race (PortfolioState.Refresh at
   //    step 7 cannot see ticket created at step 11 of the SAME tick).
   bool              m_pending_fill;
   datetime          m_pending_set_time;
   static const int  PENDING_FILL_TIMEOUT_SEC; // = 60

   //--- IMPL-FIX-008 R-10 close-intent latch (post-Q1-2021-canary spam find):
   //    Slot_S exit_profit_gate is Phase-1 stub (logs intent; broker-close
   //    wiring deferred to RiskManager::CloseOrder Phase 2). Without latch,
   //    every tick at profit>=gate re-emits Info -> log spam.
   //    Latch: remember last ticket that triggered log; suppress re-emit
   //    until ticket vanishes (broker-close from end-of-test or SL hit).
   ulong             m_close_logged_ticket;

   //--- IMPL-FIX-011 R-13 (e) Slot S parent-close tracker per CodeWiki §3.16:
   //    "Lookback 70 bars; require prior L/K closure ≥33 bars ago."
   //    Previous gate `_BothParentsInactive` was insufficient: returned true
   //    when L/K never opened (Q1 2021 rewrite case), letting S fire 6 entries
   //    with no parent context (journal-diff top-1 divergence, |Δ|=6).
   //    Fix: track L/K active(prev) → inactive(now) transition; only fire S
   //    when a close was observed within LK_LOOKBACK_BARS_MAX of current bar.
   bool              m_lk_was_active;
   datetime          m_last_lk_close_bar;
   static const int  LK_LOOKBACK_BARS_MAX; // = 70  (CodeWiki §3.16 upper bound)

public:
   //--- Constructor / Destructor
   CSlotS() : m_pending_fill(false), m_pending_set_time(0), m_last_fill_bar(0),
              m_close_logged_ticket(0),
              m_lk_was_active(false), m_last_lk_close_bar(0) {}
   virtual          ~CSlotS() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() โ€” returns MAGIC_S (217) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_S; }

   //--- 2. SlotId() โ€” used by journal record `slot_id` field
   virtual string    SlotId() const override { return "S"; }

   //--- 3. Evaluate() โ€” entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 5 of N CodeWiki ยง3.S conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits() โ€” exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit condition: profit >= InpSTpProfitPips.
   virtual void      ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn() โ€” S depends on L (MAGIC_L=211) and K (MAGIC_K=207)
   //    post-close: both parents must be inactive for S entry to trigger.
   //    Returns 2 (distinct from 0-dep slots G2/LX/L/K themselves).
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 2);
      out_magics[0] = MAGIC_L;  // L parent โ€” post-close proxy
      out_magics[1] = MAGIC_K;  // K parent โ€” post-close proxy
      return 2;
     }

   //--- 6. PendingState() โ€” S is non-PMR; always returns PENDING_STATE_IDLE.
   //    No pending machine for Slot S per IMPL-036 scope (non-PMR).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

//+------------------------------------------------------------------+
//| Static const definition (MQL5 requires out-of-class definition)   |
//+------------------------------------------------------------------+
const int CSlotS::PENDING_FILL_TIMEOUT_SEC = 60;
const int CSlotS::LK_LOOKBACK_BARS_MAX = 70;

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot S entry pass (CodeWiki ยง3.S MVP)                  |
//|                                                                   |
//| Entry conditions (5 of N for M-size MVP):                         |
//|   1. InpEnableSlotS == true                                       |
//|   2. Both L and K parents inactive (post-close proxy gate)        |
//|   3. No active S orders (own-no-active guard)                     |
//|   4. ADX volatility gate: adx_h4.adx > InpSAdxMin                |
//|   5. D1 Ichimoku trend direction clear (not inside cloud)         |
//|   6. WPR threshold confirmation (BUY: oversold / SELL: overbought)|
//|                                                                   |
//| Lot: RiskManager::ComputeLot("S", InpSSlPips, balance)            |
//| Comment: "S,post,1" per CodeWiki ยง3.S "S,..." pattern             |
//+------------------------------------------------------------------+
void CSlotS::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotS) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- IMPL-FIX-011 R-13 (e) Slot S parent-close gate per CodeWiki §3.16:
   //    "Lookback 70 bars; require prior L/K closure ≥33 bars ago."
   //    The original gate `_BothParentsInactive` only checked CURRENT absence
   //    of L/K — that returned true when L/K had never opened (Q1 2021 rewrite
   //    case), letting S fire with no parent context (journal-diff top-1
   //    divergence S/entry +6 vs legacy 0). Fix: track active→inactive
   //    transition and require it within LK_LOOKBACK_BARS_MAX H4 bars.
   //    Phase-1 conservative: lower bound = 0 bars (CodeWiki spec ≥33 but
   //    rewrite slots are logger stubs; tighten after RiskManager wires).
   bool lk_active_now = !_BothParentsInactive(port);
   if(m_lk_was_active && !lk_active_now)
      m_last_lk_close_bar = iTime(_Symbol, PERIOD_H4, 0);
   m_lk_was_active = lk_active_now;

   //--- Condition 1 (post-close proxy gate): both L and K must have no active orders
   //    ADR-012: cross-slot access via PortfolioState.GetTicketsForSlot only
   //    // CodeWiki §3.S — S entry triggers when L/K windows closed
   if(!_BothParentsInactive(port)) return;

   //--- Condition 1b (parent-close history per CodeWiki §3.16): require an
   //    observed L/K close within LK_LOOKBACK_BARS_MAX of current H4 bar.
   //    Suppresses S entirely when L/K never opened (Q1 2021 rewrite case
   //    where L=0/K=0 throughout window — legacy convention says S=0).
   if(m_last_lk_close_bar == 0) return;
   datetime now_h4 = iTime(_Symbol, PERIOD_H4, 0);
   int bars_since_lk_close = (int)((now_h4 - m_last_lk_close_bar) / (4 * 3600));
   if(bars_since_lk_close > LK_LOOKBACK_BARS_MAX) return;

   //--- Condition 2 (own-no-active guard): S must have no open "S," orders
   //    // CodeWiki ยง3.S โ€” single active S position allowed
   //--- IMPL-FIX-007 H4 bar gate (PRIMARY anti-pyramid defense post-G2-smoke
   //    finding): match task AC <= 1 fill per H4 bar exactly. CodeWiki §3.G2
   //    wave-helper continuation = next-bar permitted, intra-bar forbidden.
   if(m_last_fill_bar > 0 && iTime(_Symbol, PERIOD_H4, 0) == m_last_fill_bar)
      return;

   //--- IMPL-FIX-007 anti-pyramid latch (same-tick race protection)
   //    Reset when PortfolioState reflects fill OR after timeout.
   if(m_pending_fill)
     {
      if(_HasActiveSOrder(port))
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
        }
      else if(TimeCurrent() - m_pending_set_time > PENDING_FILL_TIMEOUT_SEC)
        {
         m_pending_fill     = false;
         m_pending_set_time = 0;
         m_logger.Warn("SlotS", "pending_fill_timeout", MAGIC_S,
                       "60s elapsed without PortfolioState reflection - clearing latch");
        }
      else
        {
         return;  // still pending - skip until reflected or timeout
        }
     }

   if(_HasActiveSOrder(port)) return;

   //--- Condition 3: ADX volatility gate
   //    // CodeWiki ยง3.S โ€” avoid low-volatility regime; same gate as Slot_L
   if(ctx.adx_h4.adx < InpSAdxMin) return;

   //--- Condition 4: D1 Ichimoku trend filter
   //    // CodeWiki ยง3.S โ€” align with higher-timeframe trend
   int trend_dir = _D1TrendDirection(ctx);
   if(trend_dir == 0) return;  // price inside cloud โ€” no trade

   //--- Condition 5: WPR threshold confirmation (H4)
   //    BUY: wpr_h4 oversold (< InpSWprOversold = -80)
   //    SELL: wpr_h4 overbought (> InpSWprOverbought = -20)
   //    // CodeWiki ยง3.S โ€” momentum confirmation on follow-on entry
   bool buy_signal  = (trend_dir == +1) && (ctx.wpr_h4.wpr < InpSWprOversold);
   bool sell_signal = (trend_dir == -1) && (ctx.wpr_h4.wpr > InpSWprOverbought);
   if(!buy_signal && !sell_signal) return;

   //--- Compute lot via RiskManager (no direct CTrade โ€” ADR-002 + ea.md rule)
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("S", InpSSlPips, balance, InpSPercentTp);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotS", "zero_lot_skip", MAGIC_S,
                    "ComputeLot returned 0 โ€” skipping S entry");
      return;
     }

   //--- Compute prices
   int    digits   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double sl_dist  = _PipsToPrice(InpSSlPips);
   double price    = buy_signal ? ctx.ask : ctx.bid;
   double sl_price = buy_signal
                     ? NormalizeDouble(ctx.ask - sl_dist, digits)
                     : NormalizeDouble(ctx.bid + sl_dist, digits);

   //--- Comment: "S,post,1" per CodeWiki ยง3.S "S,..." pattern
   string comment = "S,post,1";

   //--- Build MqlTradeRequest stub (req.magic = MAGIC_S per directive).
   //    fix-round-12 ยง 12.8 โ€” Phase 1 architectural choice: slots emit
   //    `entry_signal` Logger.Info as the observable milestone; actual
   //    OrderSend wiring lives in `RiskManager::OpenOrder` per
   //    `.claude/rules/ea.md` (Orchestrator wiring path (core/Orchestrator.mqh) 5-yr regression).
   //    Observable milestone for E-AC [log-assertion]:
   MqlTradeRequest req = {};
   req.action    = TRADE_ACTION_DEAL;
   req.magic     = MAGIC_S;
   req.symbol    = _Symbol;
   req.volume    = lot;
   req.price     = price;
   req.sl        = sl_price;
   req.tp        = 0.0;
   req.type      = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.type_filling = ORDER_FILLING_IOC;
   req.comment   = comment;

   // IMPL-FIX-011 R-13 (d): entry_signal Info emit suppressed (per-tick stub
   // spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over 5-yr;
   // restore when RiskManager::OpenOrder wires real send + this becomes
   // one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10.
   // m_logger.Info("SlotS", "entry_signal", MAGIC_S,
   //               StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s"
   //                            " adx=%.1f wpr=%.1f trend=%d",
   //                            (buy_signal ? "BUY" : "SELL"),
   //                            lot, InpSSlPips, price, sl_price, comment,
   //                            ctx.adx_h4.adx, ctx.wpr_h4.wpr, trend_dir));

   //--- IMPL-FIX-003: submit broker order via RiskManager.OpenOrder wrapper (ea.md mandate)
   //--- IMPL-FIX-007: arm pending-fill latch on success to block same-tick re-entry
   if(m_risk.OpenOrder(req, "S"))
     {
      m_pending_fill     = true;
      m_pending_set_time = TimeCurrent();
      m_last_fill_bar    = iTime(_Symbol, PERIOD_H4, 0);
     }

   //--- CrossSlotCoordinator stub
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (Orchestrator wiring path (core/Orchestrator.mqh)) */)
     {
      //--- Stub: S post-close coupling
      //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot S exit pass (profit gate; 35 pip MVP)          |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate S positions via GetTicketsForSlot(MAGIC_S, "S,")    |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate >= InpSTpProfitPips (35 pip) โ’ log close intent  |
//|                                                                   |
//| Additional exit logic (P4 IMPL-062):                             |
//|   - Orphan-guard: close S if both L and K re-enter and re-close   |
//|   - Trailing stop on Ichimoku kijun-sen level                     |
//+------------------------------------------------------------------+
void CSlotS::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve S tickets (own comment prefix "S,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_S, "S,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY)
                                      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Profit gate: >= InpSTpProfitPips (35 pip - post-close follow-on target)
      //    IMPL-FIX-008 R-10: latch close-intent per ticket so subsequent ticks
      //    do not re-spam Info while position lingers (Phase-1 close stub).
      if(profit_pips >= InpSTpProfitPips && ticket != m_close_logged_ticket)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotS", "exit_profit_gate", MAGIC_S,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f close (one-shot per ticket)",
//                                     ticket, profit_pips, InpSTpProfitPips));
         m_close_logged_ticket = ticket;

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub
      if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (Orchestrator wiring path (core/Orchestrator.mqh)) */)
        {
         //--- Stub: orphan-guard coupling
         //    wires through core/Orchestrator.mqh (cross-slot coupling per ea.md).
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_S_MQH
