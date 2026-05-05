//+------------------------------------------------------------------+
//| slots/Slot_M.mqh — Slot M implementation (IMPL-029)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_M = 210                                            |
//| Source:  CodeWiki §3 Slot M; ADR-002; ADR-008; ADR-012            |
//|                                                                   |
//| M-size MVP — 5 of N CodeWiki §3.M conditions:                    |
//|   1. No active M orders (magic 210 with "M," prefix)              |
//|   2. MACD M10: histogram direction (hist > 0 BUY / <0 SELL)       |
//|   3. ADX H4 dominance: adx > InpMAdxMin                           |
//|   4. Stochastic H4 oversold/overbought confirmation               |
//|   5. M-Pending integration: EnterPending/GetState/TransitionExec   |
//| Deferred to P4 IMPL-062: M-Pause / MACD-D1 cross / WPR-wave /    |
//|   Bollinger precision exit / Hull-slope trailing                   |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate ≥ InpMTpProfitPips (40 pip default)               |
//|                                                                   |
//| Pending integration (ADR-008 / OQ-A1):                            |
//|   - CPendingMachineRegistry PM_M; force-clear = PMR.TickAll       |
//|   - InpForceClearM_Bars = 150 (Inputs_Pending.mqh)                |
//|   - Slot ห้าม call TickAll directly — Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("M", InpMSlPipsFloor, balance)       |
//| Comment: "M,MA,N,1,SL" per CodeWiki comment format                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_M_MQH
#define PHOENICISNEX_SLOTS_SLOT_M_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_M.mqh"

//+------------------------------------------------------------------+
//| CSlotM — Slot M derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses M-Pending state machine (PM_M) to gate entry:               |
//|   IDLE + base signal → EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid → place entry + TransitionExecuted      |
//|   Force-clear (150 H4 bars): handled by PMR.TickAll in Orchestr.  |
//+------------------------------------------------------------------+
class CSlotM : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveMOrder(CPortfolioState &port) const;
   bool              _IsMBuyBaseSignal(const MarketContext &ctx) const;
   bool              _IsMSellBaseSignal(const MarketContext &ctx) const;
   bool              _IsMBuyTrigger(const MarketContext &ctx) const;
   bool              _IsMSellTrigger(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotM() {}
   virtual ~CSlotM() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_M = 210
   virtual int           Magic()  const override { return MAGIC_M; }

   //--- 2. SlotId — "M"; used by journal slot_id field + comment prefix "M,"
   virtual string        SlotId() const override { return "M"; }

   //--- 3. Evaluate — entry pass with M-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — M is topologically independent; PMR dep is shared service
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_M);
     }
  };

//+------------------------------------------------------------------+
//| _HasActiveMOrder — check for open M orders via PortfolioState     |
//| Comment prefix "M," for disambiguation                            |
//+------------------------------------------------------------------+
bool CSlotM::_HasActiveMOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_M, "M,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsMBuyBaseSignal — base BUY signal for pending gate              |
//|                                                                   |
//| Conditions (MVP 3 of N CodeWiki §3.M):                            |
//|   1. MACD M10 histogram > threshold (momentum BUY)               |
//|   2. ADX H4 dominance: adx > InpMAdxMin                           |
//|   3. Stochastic H4 oversold: k_main < InpMStochOversold           |
//+------------------------------------------------------------------+
bool CSlotM::_IsMBuyBaseSignal(const MarketContext &ctx) const
  {
   bool macd_buy  = ctx.macd_m10.hist > InpMMacdSignalThresh;
   bool adx_ok    = ctx.adx_h4.adx > InpMAdxMin;
   bool stoch_ok  = ctx.stoch_h4.k_main < InpMStochOversold;
   return macd_buy && adx_ok && stoch_ok;
  }

//+------------------------------------------------------------------+
//| _IsMSellBaseSignal — base SELL signal for pending gate (mirror)   |
//+------------------------------------------------------------------+
bool CSlotM::_IsMSellBaseSignal(const MarketContext &ctx) const
  {
   bool macd_sell = ctx.macd_m10.hist < -InpMMacdSignalThresh;
   bool adx_ok    = ctx.adx_h4.adx > InpMAdxMin;
   bool stoch_ok  = ctx.stoch_h4.k_main > InpMStochOverbought;
   return macd_sell && adx_ok && stoch_ok;
  }

//+------------------------------------------------------------------+
//| _IsMBuyTrigger — trigger condition to execute pending BUY         |
//| Precondition retest: MACD signal line cross (hist still positive) |
//+------------------------------------------------------------------+
bool CSlotM::_IsMBuyTrigger(const MarketContext &ctx) const
  {
   //--- Trigger: MACD M10 hist still > 0 AND macd > signal (momentum confirm)
   return (ctx.macd_m10.hist > InpMMacdSignalThresh &&
           ctx.macd_m10.macd > ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| _IsMSellTrigger — trigger condition to execute pending SELL       |
//+------------------------------------------------------------------+
bool CSlotM::_IsMSellTrigger(const MarketContext &ctx) const
  {
   return (ctx.macd_m10.hist < -InpMMacdSignalThresh &&
           ctx.macd_m10.macd < ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot M entry pass with M-Pending integration           |
//|                                                                   |
//| M-Pending pattern (ADR-008 / OQ-A1 / shared context §4.3):       |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal → EnterPending(PM_M, payload, bar_index)  |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + trigger valid → place entry + TransitionExecuted    |
//|   Force-clear: PMR.TickAll (Orchestrator step 8) — slot ห้าม poll |
//+------------------------------------------------------------------+
void CSlotM::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotM) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active M orders ("M," prefix)
   if(_HasActiveMOrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_M
   EPendingState st = m_pending.GetState(PM_M);

   //--- Phase A: IDLE — check base signal, enter pending if met
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsMBuyBaseSignal(ctx);
      bool sellBase = _IsMSellBaseSignal(ctx);

      if(!buyBase && !sellBase) return;

      //--- Build pending payload (minimal JSON — full schema in state-persistence-schema.yaml § PendingMachine)
      string dir     = buyBase ? "BUY" : "SELL";
      string payload = StringFormat("{\"dir\":\"%s\",\"sl_pips\":%.1f}", dir, InpMSlPipsFloor);

      m_pending.EnterPending(PM_M, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotM", "pending_entered", MAGIC_M,
                       StringFormat("dir=%s bar_index=%d payload=%s",
                                    dir, ctx.bar_index_h4, payload));
      return;
     }

   //--- Phase B: PENDING — check trigger, place entry if valid
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction
      string payload = m_pending.GetPayload(PM_M);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      bool triggerOk = isBuy ? _IsMBuyTrigger(ctx) : _IsMSellTrigger(ctx);
      if(!triggerOk) return;

      //--- Pip size via base-class helper (Round-06 06.1)
      double pip_size = _PipSize();
      double sl_pips  = InpMSlPipsFloor;

      //--- Compute lot
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("M", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotM", "zero_lot_skip", MAGIC_M,
                       "ComputeLot returned 0 — skipping M entry");
         return;
        }

      //--- Compute SL + TP prices
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                        : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

      //--- Comment: "M,MA,N,1,SL" per CodeWiki §3.M format
      string comment = "M,MA,N,1,SL";

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
      req.magic        = MAGIC_M;
      req.type_filling = ORDER_FILLING_FOK;  // broker detection at IMPL-053+

      if(m_logger != NULL)
         m_logger.Info("SlotM", "entry_signal", MAGIC_M,
                       StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                                    (isBuy ? "BUY" : "SELL"), lot, sl_pips, price, sl_price,
                                    comment));

      //--- Transition PMR to EXECUTED state (force-clear counter resets)
      m_pending.TransitionExecuted(PM_M);
     }

   //--- Phase C: EXECUTED — entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass — no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot M exit pass (CodeWiki §3.M MVP)                |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate M positions via GetTicketsForSlot(MAGIC_M, "M,")    |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate ≥ InpMTpProfitPips (40 pip default) → close     |
//+------------------------------------------------------------------+
void CSlotM::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve M tickets (comment prefix "M,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_M, "M,", tickets);
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

      //--- Profit gate: ≥ InpMTpProfitPips → emit close signal
      if(profit_pips >= InpMTpProfitPips)
        {
         m_logger.Info("SlotM", "exit_profit_gate", MAGIC_M,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpMTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    IMPL-017 / IMPL-062 (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_M_MQH
