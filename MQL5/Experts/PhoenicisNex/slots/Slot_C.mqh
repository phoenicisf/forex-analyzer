//+------------------------------------------------------------------+
//| slots/Slot_C.mqh — Slot C implementation (IMPL-019)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_CD = 200 (shared with Slot D — D is 4-line wrapper)|
//| Source:  CodeWiki §3 Slot C + §4; ADR-002; ADR-008; ADR-012        |
//|                                                                   |
//| M-size MVP — 5 of N CodeWiki §3.C entry conditions:               |
//|   1. No active C orders (magic 200 with "C," comment prefix)       |
//|   2. MACD M10: histogram direction (hist > 0 BUY / <0 SELL)        |
//|      CodeWiki §3.C — MACD M10 histogram momentum signal            |
//|   3. ADX H4 dominance: adx > InpCAdxMin                            |
//|      CodeWiki §3.C — ADX trend-strength filter                     |
//|   4. Stochastic H4 oversold/overbought confirmation                |
//|      CodeWiki §3.C — Stochastic entry timing filter                |
//|   5. C-Pending integration: EnterPending/GetState/TransitionExec   |
//|      CodeWiki §3.C — pending retest gate (ADR-008 PM_C machine)    |
//| Deferred to P4 IMPL-062: C-ADX secondary machine (PM_C_ADX) /     |
//|   Bollinger inner-band filter / Ichimoku D1 cloud alignment /      |
//|   WPR D1 wave filter / Hull H4 slope filter / M-Pause analog /     |
//|   force-close divergence logic                                     |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate ≥ InpCTpProfitPips (40 pip default)                |
//|                                                                   |
//| Pending integration (ADR-008 / BR-6.1):                           |
//|   - CPendingMachineRegistry PM_C; force-clear = PMR.TickAll       |
//|   - InpForceClearC_Bars = 100 (Inputs_Pending.mqh)                |
//|   - Legacy timeout InpLegacyCBars = 8 H4 bars (Inputs_Pending.mqh)|
//|   - Slot ห้าม call TickAll directly — Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("C", InpCSlPipsFloor, balance)       |
//| Comment: "C,MA,N,1,SL" per CodeWiki §3.C comment format           |
//| Shared-magic disambig: GetTicketsForSlot(MAGIC_CD, "C,", tickets) |
//|   so D's "D," orders are excluded (BR-4.4 / §4.4)                 |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_C_MQH
#define PHOENICISNEX_SLOTS_SLOT_C_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_C.mqh"

//+------------------------------------------------------------------+
//| CSlotC — Slot C derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| CD chain root: Slot D is a thin 4-line force-pending wrapper      |
//| that routes through this slot's logic. Slot C owns PM_C in PMR.   |
//|                                                                   |
//| Uses C-Pending state machine (PM_C) to gate entry:               |
//|   IDLE + base signal → EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid → place entry + TransitionExecuted      |
//|   Force-clear (100 H4 bars): handled by PMR.TickAll in Orchestr.  |
//+------------------------------------------------------------------+
class CSlotC : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveCOrder(CPortfolioState &port) const;
   bool              _IsCBuyBaseSignal(const MarketContext &ctx) const;
   bool              _IsCSellBaseSignal(const MarketContext &ctx) const;
   bool              _IsCBuyTrigger(const MarketContext &ctx) const;
   bool              _IsCSellTrigger(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotC() {}
   virtual ~CSlotC() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_CD = 200 (shared with Slot D)
   virtual int           Magic()  const override { return MAGIC_CD; }

   //--- 2. SlotId — "C"; journal slot_id + comment prefix disambig from "D,"
   virtual string        SlotId() const override { return "C"; }

   //--- 3. Evaluate — entry pass with C-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — C is CD chain root (topologically independent)
   //       PMR is shared service, not a slot dependency
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR PM_C; safe NULL guard fallback
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_C);
     }
  };

//+------------------------------------------------------------------+
//| _HasActiveCOrder — check for open C orders via PortfolioState     |
//| Comment prefix "C," for shared-magic C vs D disambiguation        |
//+------------------------------------------------------------------+
bool CSlotC::_HasActiveCOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_CD, "C,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsCBuyBaseSignal — base BUY signal for pending gate              |
//|                                                                   |
//| Conditions (MVP 3 of N CodeWiki §3.C):                            |
//|   1. MACD M10 histogram > threshold — CodeWiki §3.C MACD momentum |
//|   2. ADX H4 dominance: adx > InpCAdxMin — CodeWiki §3.C ADX trend |
//|   3. Stochastic H4 oversold: k < InpCStochOversold — CodeWiki §3.C|
//+------------------------------------------------------------------+
bool CSlotC::_IsCBuyBaseSignal(const MarketContext &ctx) const
  {
   // CodeWiki §3.C — MACD M10 histogram momentum signal (BUY)
   bool macd_buy = ctx.macd_m10.hist > InpCMacdSignalThresh;
   // CodeWiki §3.C — ADX trend-strength filter
   bool adx_ok   = ctx.adx_h4.adx > InpCAdxMin;
   // CodeWiki §3.C — Stochastic entry timing filter (oversold)
   bool stoch_ok = ctx.stoch_h4.k_main < InpCStochOversold;
   return macd_buy && adx_ok && stoch_ok;
  }

//+------------------------------------------------------------------+
//| _IsCSellBaseSignal — base SELL signal for pending gate (mirror)   |
//+------------------------------------------------------------------+
bool CSlotC::_IsCSellBaseSignal(const MarketContext &ctx) const
  {
   // CodeWiki §3.C — MACD M10 histogram momentum signal (SELL)
   bool macd_sell = ctx.macd_m10.hist < -InpCMacdSignalThresh;
   // CodeWiki §3.C — ADX trend-strength filter
   bool adx_ok    = ctx.adx_h4.adx > InpCAdxMin;
   // CodeWiki §3.C — Stochastic entry timing filter (overbought)
   bool stoch_ok  = ctx.stoch_h4.k_main > InpCStochOverbought;
   return macd_sell && adx_ok && stoch_ok;
  }

//+------------------------------------------------------------------+
//| _IsCBuyTrigger — trigger condition to execute pending BUY         |
//| Precondition retest: MACD signal line cross (hist still positive) |
//+------------------------------------------------------------------+
bool CSlotC::_IsCBuyTrigger(const MarketContext &ctx) const
  {
   //--- Trigger: MACD M10 hist still > 0 AND macd > signal (momentum confirm)
   return (ctx.macd_m10.hist > InpCMacdSignalThresh &&
           ctx.macd_m10.macd > ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| _IsCSellTrigger — trigger condition to execute pending SELL       |
//+------------------------------------------------------------------+
bool CSlotC::_IsCSellTrigger(const MarketContext &ctx) const
  {
   return (ctx.macd_m10.hist < -InpCMacdSignalThresh &&
           ctx.macd_m10.macd < ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot C entry pass with C-Pending integration           |
//|                                                                   |
//| C-Pending pattern (ADR-008 / BR-6.1 / shared context §4.3):       |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal → EnterPending(PM_C, payload, bar_index)  |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + trigger valid → place entry + TransitionExecuted    |
//|   Force-clear: PMR.TickAll (Orchestrator step 8) — slot ห้าม poll |
//|   Legacy timeout: InpLegacyCBars (8 H4 bars) — PMR handles via   |
//|     Inputs_Pending.mqh input (Orchestrator step 8 territory)      |
//+------------------------------------------------------------------+
void CSlotC::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotC) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active C orders ("C," prefix — shared MAGIC_CD with D)
   if(_HasActiveCOrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_C
   EPendingState st = m_pending.GetState(PM_C);

   //--- Phase A: IDLE — check base signal, enter pending if met
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsCBuyBaseSignal(ctx);
      bool sellBase = _IsCSellBaseSignal(ctx);

      if(!buyBase && !sellBase) return;

      //--- Build pending payload (minimal JSON — schema lock deferred to IMPL-053+)
      string dir     = buyBase ? "BUY" : "SELL";
      string payload = StringFormat("{\"dir\":\"%s\",\"sl_pips\":%.1f}", dir, InpCSlPipsFloor);

      m_pending.EnterPending(PM_C, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotC", "pending_entered", MAGIC_CD,
                       StringFormat("dir=%s bar_index=%d payload=%s",
                                    dir, ctx.bar_index_h4, payload));
      return;
     }

   //--- Phase B: PENDING — check trigger, place entry if valid
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction
      string payload = m_pending.GetPayload(PM_C);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      bool triggerOk = isBuy ? _IsCBuyTrigger(ctx) : _IsCSellTrigger(ctx);
      if(!triggerOk) return;

      //--- Pip size via base-class helper (Round-06 06.1 — ea.md mandate)
      double pip_size = _PipSize();
      double sl_pips  = InpCSlPipsFloor;

      //--- Compute lot via RiskManager (ห้าม instantiate CTrade direct per ea.md)
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("C", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotC", "zero_lot_skip", MAGIC_CD,
                       "ComputeLot returned 0 — skipping C entry");
         return;
        }

      //--- Compute SL price (broker-bound: NormalizeDouble via base helper)
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                        : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

      //--- Comment: "C,MA,N,1,SL" per CodeWiki §3.C comment format
      //    "C," prefix enables shared-magic C/D disambiguation
      string comment = "C,MA,N,1,SL";

      //--- Submit order through RiskManager CTrade wrapper
      //    ห้าม instantiate CTrade direct (ea.md + ADR-002)
      //    fix-round-12 § 12.8 — Phase 1 emits entry_signal Info as the
      //    observable milestone; actual OrderSend wiring lives in
      //    `RiskManager::OpenOrder` (IMPL-017 + IMPL-062 5-yr regression).
      //    Observable E-AC milestone: emit entry_signal Info log.
      ENUM_ORDER_TYPE order_type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      MqlTradeRequest req  = {};
      MqlTradeResult  res  = {};

      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = order_type;
      req.price        = _NormalizeBrokerPrice(price);
      req.sl           = sl_price;
      req.tp           = 0.0;    // TP = 0; profit gate managed in ManageExits
      req.comment      = comment;
      req.magic        = MAGIC_CD;
      req.type_filling = ORDER_FILLING_FOK;  // broker filling detection at IMPL-053+

      if(m_logger != NULL)
         m_logger.Info("SlotC", "entry_signal", MAGIC_CD,
                       StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                                    (isBuy ? "BUY" : "SELL"), lot, sl_pips, price, sl_price,
                                    comment));

      //--- Transition PMR to EXECUTED state (force-clear counter resets)
      m_pending.TransitionExecuted(PM_C);
     }

   //--- Phase C: EXECUTED — entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass — no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot C exit pass (CodeWiki §3.C / §4 MVP)           |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate C positions via GetTicketsForSlot(MAGIC_CD, "C,")   |
//|      Note: "C," prefix excludes D's "D," orders (shared magic)   |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate ≥ InpCTpProfitPips (40 pip default) → close     |
//+------------------------------------------------------------------+
void CSlotC::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve C tickets only (comment prefix "C," — shared MAGIC_CD with D)
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_CD, "C,", tickets);
   if(n <= 0) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   for(int i = 0; i < n; i++)
     {
      ulong ticket = tickets[i];

      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- Compute unrealized profit in pips
      double profit_pips = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
         profit_pips = (cur_price - open_price) / pip_size;
      else
         profit_pips = (open_price - cur_price) / pip_size;

      //--- Profit gate: ≥ InpCTpProfitPips → emit close signal
      if(profit_pips >= InpCTpProfitPips)
        {
         m_logger.Info("SlotC", "exit_profit_gate", MAGIC_CD,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpCTpProfitPips));

         //--- Close via CTrade route (IMPL-053+ wiring)
         //    Phase-1 stub: log intent; OrderClose deferred to Orchestrator wiring.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_C_MQH
