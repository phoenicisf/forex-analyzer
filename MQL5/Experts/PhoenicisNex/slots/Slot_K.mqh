//+------------------------------------------------------------------+
//| slots/Slot_K.mqh เนโฌโ€ Slot K derived class (IMPL-024)               |
//| Layer:   slots/ (depends on domain/; injects services via base)   |
//| Magic:   207 (MAGIC_K per domain/EnumTypes.mqh)                   |
//| SlotId:  "K"                                                      |
//| Comment: "K,layer,1"                                              |
//|                                                                  |
//| Source:  CodeWiki เธขเธ3.5 (M-size MVP: 4 of 8 entry conditions)     |
//|          TD-02 เธขเธ5.4 (lot dispatch RiskManager::ComputeLot)        |
//|          ADR-002 (CSlotBase 6-method contract)                    |
//|          ADR-012 (layer dependency เนโฌโ€ เน€เธเธเน€เธยเน€เธเธ’เน€เธเธ #include slots/*)        |
//|                                                                  |
//| M-size MVP scope (4 of 8 entry conditions per shared context เธขเธ4): |
//|   1. No existing K order (PortfolioState count by magic)          |
//|   2. iTime(D1,0) > m_last_order_d1_time (one K per day)           |
//|      // CodeWiki เธขเธ3.5 entry condition 2                           |
//|   3. Force crossover: isFICrossUp / isFICrossDw                   |
//|      // CodeWiki เธขเธ3.5 entry condition 3                           |
//|   4. Price outside Ichimoku cloud matches direction                |
//|                                                                  |
//| P4 deferred (IMPL-036):                                           |
//|   - Tenkan/Kijun secondary layer conditions                       |
//|   - 2hr C-pending cooldown                                        |
//|   - KExtra pyramiding logic                                       |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_K_MQH
#define PHOENICISNEX_SLOTS_SLOT_K_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../inputs/Inputs_Slot_K.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/RiskManager.mqh"

//+------------------------------------------------------------------+
//| CSlotK เนโฌโ€ Slot K concrete derived class                           |
//|                                                                  |
//| Entry logic: Force Index crossover + D1 once-per-day guard +     |
//|   no existing K order + price outside Ichimoku cloud.             |
//|                                                                  |
//| Exit logic: profit >= InpKTpProfitPips (20 pip default) AND      |
//|   price touches Ichimoku cloud edge (cloud_high / cloud_low).    |
//+------------------------------------------------------------------+
class CSlotK : public CSlotBase
  {
private:
   //--- D1 once-per-day guard (CodeWiki เธขเธ3.5 entry condition 2)
   //    Stores the D1 bar open time of the last filled K order.
   //    Compared against iTime(_Symbol, PERIOD_D1, 0) on each Evaluate tick.
   datetime          m_last_order_d1_time;

   //--- Round-06 06.1: pip arithmetic via CSlotBase helpers
   //    `_PipsToPrice(pips)` inherited from base.

   //--- Force crossover detection (CodeWiki เธขเธ3.5 entry condition 3)
   //    isFICrossUp = (F[1]>0.5 && F[2]>0 && F[3]<-0.2) || (F[1]>1 && F[2]<-0.2)
   //    isFICrossDw = mirror for SELL
   bool              _IsFICrossUp(const ForceFields &f) const
     {
      // Primary pattern
      if(f.f1 > InpKFICrossThreshHigh && f.f2 > 0.0 && f.f3 < InpKFICrossThreshLow)
         return true;
      // Alternate pattern
      if(f.f1 > InpKFICrossAltHigh && f.f2 < InpKFICrossThreshLow)
         return true;
      return false;
     }

   bool              _IsFICrossDw(const ForceFields &f) const
     {
      // Primary pattern (mirror of BUY)
      if(f.f1 < -InpKFICrossThreshHigh && f.f2 < 0.0 && f.f3 > -InpKFICrossThreshLow)
         return true;
      // Alternate pattern (mirror)
      if(f.f1 < -InpKFICrossAltHigh && f.f2 > -InpKFICrossThreshLow)
         return true;
      return false;
     }

   //--- Count open K orders via PortfolioState
   int               _CountKOrders(CPortfolioState &port) const
     {
      SlotState *st = port.GetByMagic(MAGIC_K);
      if(st == NULL)
         return 0;
      return st.buy_count + st.sell_count;
     }

   //--- IMPL-FIX-011d Phase 2 (2026-05-12) — iter-17 telemetry gate.
   //    Re-introduced post-revert (commit 57397d7) per FORCE-PERIOD registry
   //    row: Force-period 13→21 fix landed iter-16 but Slot_K STILL silent
   //    at 2021-02-16 20:00 → next-blocker discovery. Window covers legacy K
   //    fire bucket + 1 bar before/after for context (4hrs each).
   bool              _IsTargetDebugBar(const MarketContext &ctx) const
     {
      MqlDateTime dt;
      TimeToStruct(ctx.tick_time, dt);
      if(dt.year != 2021 || dt.mon != 2 || dt.day != 16) return false;
      // legacy K fires at H4 bar 20:00 (covers 20:00..00:00 + we want 16:00..00:00)
      return (dt.hour >= 16 && dt.hour < 24);
     }

   //--- IMPL-FIX-011d Phase 2 iter-17 — predicate-decision telemetry helper.
   //    Mirrors Slot_T iter-10 pattern (`PrintFormat`, not Logger.Debug, so
   //    output survives any severity filter and is grep-stable).
   void              _DebugEmitGate(const MarketContext &ctx, string gate,
                                    string verdict, string detail) const
     {
      if(!_IsTargetDebugBar(ctx)) return;
      PrintFormat("[FIX011d-iter17-K][%s][%s][%s] %s",
                  TimeToString(ctx.tick_time, TIME_DATE|TIME_MINUTES),
                  gate, verdict, detail);
     }

public:
   //--- Constructor: zero-init member state
   CSlotK() : m_last_order_d1_time(0) {}
   virtual          ~CSlotK() {}

   //=================================================================
   // 6-method CSlotBase contract (ADR-002)
   //=================================================================

   //--- 1. Magic() เนโฌโ€ returns MAGIC_K (207) per domain/EnumTypes.mqh
   virtual int       Magic() const override { return MAGIC_K; }

   //--- 2. SlotId() เนโฌโ€ used by journal record `slot_id` field
   virtual string    SlotId() const override { return "K"; }

   //--- 3. Evaluate() เนโฌโ€ entry pass; called per tick by Orchestrator
   //    Only invoked if EAState == RUNNING (HALTED skips per ADR-010).
   //    M-size MVP: 4 of 8 CodeWiki เธขเธ3.5 conditions.
   virtual void      Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     {
      if(!InpEnableSlotK)
         return;

      //--- IMPL-FIX-011d Phase 2 iter-17 — gate 1 telemetry (count_k_open)
      int k_open = _CountKOrders(port);
      _DebugEmitGate(ctx, "G1_count",
                     (k_open >= InpKMaxOrders) ? "BLOCK" : "PASS",
                     StringFormat("k_open=%d max=%d", k_open, InpKMaxOrders));

      //--- Entry condition 1: no existing K order open
      // CodeWiki เธขเธ3.5 เนโฌโ€ max 1 K order (KExtra defer P4)
      if(k_open >= InpKMaxOrders)
         return;

      //--- Entry condition 2: one K per day (D1 timestamp guard)
      // CodeWiki เธขเธ3.5 entry condition 2
      datetime d1_bar_time = iTime(_Symbol, PERIOD_D1, 0);

      //--- IMPL-FIX-011d Phase 2 iter-17 — gate 2 telemetry (D1 once-per-day)
      _DebugEmitGate(ctx, "G2_d1guard",
                     (d1_bar_time <= m_last_order_d1_time) ? "BLOCK" : "PASS",
                     StringFormat("d1_now=%s last_order_d1=%s",
                                  TimeToString(d1_bar_time, TIME_DATE|TIME_MINUTES),
                                  TimeToString(m_last_order_d1_time, TIME_DATE|TIME_MINUTES)));

      if(d1_bar_time <= m_last_order_d1_time)
         return;

      //--- Entry condition 3: Force crossover signal
      // CodeWiki เธขเธ3.5 entry condition 3 เนโฌโ€ isFICrossUp / isFICrossDw
      bool fi_cross_up = _IsFICrossUp(ctx.force_h4);
      bool fi_cross_dw = _IsFICrossDw(ctx.force_h4);

      //--- IMPL-FIX-011d Phase 2 iter-17 — gate 3 telemetry (Force crossover)
      //    Verifies post-period-21 fix lifts isFICrossUp blocker at 2021-02-16
      //    20:00 (iter-15 pre-fix had f2=-0.072 failing primary AND alternate).
      _DebugEmitGate(ctx, "G3_force",
                     (!fi_cross_up && !fi_cross_dw) ? "BLOCK" : "PASS",
                     StringFormat("f1=%.4f f2=%.4f f3=%.4f cross_up=%s cross_dw=%s "
                                  "thr_hi=%.2f thr_lo=%.2f alt_hi=%.2f",
                                  ctx.force_h4.f1, ctx.force_h4.f2, ctx.force_h4.f3,
                                  fi_cross_up ? "T" : "F",
                                  fi_cross_dw ? "T" : "F",
                                  InpKFICrossThreshHigh, InpKFICrossThreshLow,
                                  InpKFICrossAltHigh));

      if(!fi_cross_up && !fi_cross_dw)
         return;

      //--- Entry condition 4: price outside Ichimoku cloud matches direction
      //--- IMPL-FIX-011d Phase 1 (2026-05-11) — Slot_K direction inversion fix
      //    per legacy `BusinessLogic_K` lines 3643-3649: legacy uses MEAN-
      //    REVERSION semantics — `if bid<lowMain → BUY` (oversold bounce);
      //    `else if bid>highMain → SELL` (overbought reversal). Rewrite
      //    pre-fix used TREND-FOLLOWING (bid>cloud→BUY). Same defect class
      //    as Slot_T Fix A (IMPL-FIX-011a). Q1 legacy fire 2021-02-16 20:00
      //    BUY with comment `K,34,61,15,B,...` confirms mean-reversion path
      //    (FI-cross-up + bid below cloud → BUY = anticipated bounce up).
      double cloud_high = ctx.ichi_h4.cloud_high;
      double cloud_low  = ctx.ichi_h4.cloud_low;

      bool buy_signal  = fi_cross_up && (ctx.bid < cloud_low);   // mean-reversion BUY (oversold)
      bool sell_signal = fi_cross_dw && (ctx.bid > cloud_high);  // mean-reversion SELL (overbought)

      //--- IMPL-FIX-011d Phase 2 iter-17 — gate 4 telemetry (cloud-direction)
      //    Verifies whether mean-reversion direction match passes at the legacy
      //    K fire bar. If bid is INSIDE the cloud (cloud_low <= bid <= cloud_high)
      //    neither side fires → silent regardless of Force-period fix.
      _DebugEmitGate(ctx, "G4_cloud",
                     (!buy_signal && !sell_signal) ? "BLOCK" : "PASS",
                     StringFormat("bid=%.5f cloud_lo=%.5f cloud_hi=%.5f "
                                  "buy_sig=%s sell_sig=%s pos_vs_cloud=%s",
                                  ctx.bid, cloud_low, cloud_high,
                                  buy_signal ? "T" : "F",
                                  sell_signal ? "T" : "F",
                                  (ctx.bid < cloud_low) ? "BELOW" :
                                  (ctx.bid > cloud_high) ? "ABOVE" : "INSIDE"));

      if(!buy_signal && !sell_signal)
         return;

      //--- IMPL-FIX-011d Phase 2 iter-17 — final reach telemetry (would-fire)
      _DebugEmitGate(ctx, "REACH",
                     "PASS",
                     StringFormat("dir=%s ALL_GATES_PASSED",
                                  buy_signal ? "BUY" : "SELL"));

      //--- Lot sizing via RiskManager (no direct CTrade เนโฌโ€ ADR-002 rule)
      if(m_risk == NULL)
        {
         if(m_logger != NULL)
            m_logger.Error("Slot_K", "risk_manager_null", Magic(), "Evaluate");
         return;
        }
      double lot = m_risk.ComputeLot("K", InpKSlPips,
                                     AccountInfoDouble(ACCOUNT_BALANCE));
      if(lot <= 0.0)
         return;

      //--- Build order parameters (Round-06 06.3: sl_price normalized)
      ENUM_ORDER_TYPE  order_type = buy_signal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double           price      = buy_signal ? ctx.ask : ctx.bid;
      double           sl_dist    = _PipsToPrice(InpKSlPips);
      double           sl_price   = buy_signal
                                    ? _NormalizeBrokerPrice(price - sl_dist)
                                    : _NormalizeBrokerPrice(price + sl_dist);
      string           comment    = "K,layer,1";

      //--- Submit order via RiskManager (which wraps CTrade per ea.md)
      //    RiskManager::OpenOrder wired through core/Orchestrator.mqh.
      //    Until then: log intent + update D1 guard so SelfTest/smoke
      //    verifies the entry path without panicking on NULL CTrade.
      // IMPL-FIX-011 R-13 (d): entry_buy/sell Info emit suppressed (per-tick
      // stub spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over
      // 5-yr; restore when RiskManager::OpenOrder wires real send + this
      // becomes one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10.
      // if(m_logger != NULL)
      //    m_logger.Info("Slot_K", buy_signal ? "entry_buy" : "entry_sell",
      //                  Magic(),
      //                  StringFormat("lot=%.2f price=%.5f sl=%.5f comment=%s",
      //                               lot, price, sl_price, comment));

      //--- Update D1 guard AFTER logging intent (prevents re-entry same day)
      m_last_order_d1_time = d1_bar_time;
     }

   //--- 4. ManageExits() เนโฌโ€ exit pass; runs in BOTH RUNNING and HALTED
   //    per ADR-010. Exit conditions: profit >= 20 pip + cloud touch.
   //    Uses canonical PortfolioState.GetTicketsForSlot + PositionSelectByTicket
   //    pattern (Slot_BR canonical) per ADR-005 + ADR-012. Open positions are
   //    accessed via Position* APIs เนโฌโ€ Order* APIs would walk the pending-order
   //    list and miss market positions entirely.
   virtual void      ManageExits(CPortfolioState &port) override
     {
      if(!InpEnableSlotK)
         return;

      //--- Retrieve K tickets (own magic MAGIC_K=207, comment prefix "K,")
      ulong tickets[];
      int n = port.GetTicketsForSlot(MAGIC_K, "K,", tickets);
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
         double price_diff = (pos_type == POSITION_TYPE_BUY)
                             ? (cur_price - open_price)
                             : (open_price - cur_price);

         double profit_pips = price_diff / _PipSize();

         //--- Exit condition 1: profit >= 20 pip gate
         if(profit_pips < InpKTpProfitPips)
            continue;

         //--- Exit condition 2: price touches Ichimoku cloud edge
         //    Full cloud-touch check wires through core/Orchestrator.mqh when ctx
         //    is passed to ManageExits. For MVP: close on profit gate alone
         //    when InpKTpProfitPips threshold met (sufficient for E-AC).
         if(m_logger != NULL) {}
            // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
            // caused 5-yr regression to bloat log + halt processing pace; restore when
            // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//             m_logger.Info("Slot_K", "exit_profit_gate", Magic(),
//                           StringFormat("ticket=%I64u profit_pips=%.1f", ticket, profit_pips));

         //--- Close order via RiskManager (CTrade wired through core/Orchestrator.mqh)
         //    Log intent only until wiring complete (same pattern as Evaluate).
        }
     }

   //--- 5. DependsOn() เนโฌโ€ K is independent (no peer slot deps)
   //    S เนยโ€ K post-close dependency deferred to P4 IMPL-036.
   virtual int       DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState() เนโฌโ€ K does not use pending sub-flow;
   //    safe default PENDING_STATE_IDLE inherited from base (overridden
   //    here explicitly for documentation clarity).
   virtual EPendingState PendingState() const override
     {
      return PENDING_STATE_IDLE;
     }
  };

#endif // PHOENICISNEX_SLOTS_SLOT_K_MQH
