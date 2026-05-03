//+------------------------------------------------------------------+
//| slots/Slot_Q.mqh — Slot Q implementation (IMPL-032)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_Q = 212                                            |
//| Source:  CodeWiki §3 Slot Q; ADR-002; ADR-008 (OQ-A2); ADR-012   |
//|                                                                   |
//| M-size MVP — 3 of N CodeWiki §3.Q conditions:                    |
//|   1. No active Q orders (magic 212 with "Q," prefix)              |
//|   2. ADX H4 dominance: adx > InpQAdxMin                           |
//|   3. RSI H4 oversold/overbought confirmation                      |
//|   4. MACD M10 momentum histogram threshold                        |
//|   5. Q-Pending integration: EnterPending/GetState/TransitionExec  |
//| Deferred to P4 IMPL-062+: Q-advanced filters                      |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate ≥ InpQTpProfitPips (40 pip default)               |
//|                                                                   |
//| Pending integration (ADR-008 / OQ-A2):                            |
//|   - CPendingMachineRegistry PM_Q; force-clear = PMR.TickAll       |
//|   - InpForceClearQ_Bars = 100 (Inputs_Pending.mqh)                |
//|   - Slot ห้าม call TickAll directly — Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("Q", InpQSlPipsFloor, balance)       |
//| Comment: "Q,MA,N,1,SL" per CodeWiki comment format                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_Q_MQH
#define PHOENICISNEX_SLOTS_SLOT_Q_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_Q.mqh"

//+------------------------------------------------------------------+
//| CSlotQ — Slot Q derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses Q-Pending state machine (PM_Q) to gate entry:               |
//|   IDLE + base signal → EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid → place entry + TransitionExecuted      |
//|   Force-clear (100 H4 bars): handled by PMR.TickAll in Orchestr.  |
//+------------------------------------------------------------------+
class CSlotQ : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveQOrder(CPortfolioState &port) const;
   bool              _IsQBuyBaseSignal(const MarketContext &ctx) const;
   bool              _IsQSellBaseSignal(const MarketContext &ctx) const;
   bool              _IsQBuyTrigger(const MarketContext &ctx) const;
   bool              _IsQSellTrigger(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotQ() {}
   virtual ~CSlotQ() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_Q = 212
   virtual int           Magic()  const override { return MAGIC_Q; }

   //--- 2. SlotId — "Q"; used by journal slot_id field + comment prefix "Q,"
   virtual string        SlotId() const override { return "Q"; }

   //--- 3. Evaluate — entry pass with Q-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — Q is topologically independent; PMR dep is shared service
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_Q);
     }
  };

//+------------------------------------------------------------------+
//| _HasActiveQOrder — check for open Q orders via PortfolioState     |
//| Comment prefix "Q," for disambiguation                            |
//+------------------------------------------------------------------+
bool CSlotQ::_HasActiveQOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_Q, "Q,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsQBuyBaseSignal — base BUY signal for pending gate              |
//|                                                                   |
//| Conditions (MVP 3 of N CodeWiki §3.Q):                            |
//|   1. ADX H4 dominance: adx > InpQAdxMin                           |
//|   2. RSI H4 oversold: rsi < InpQRsiOversold                       |
//|   3. MACD M10 histogram > threshold (momentum BUY)               |
//+------------------------------------------------------------------+
bool CSlotQ::_IsQBuyBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok    = ctx.adx_h4.adx > InpQAdxMin;
   bool rsi_ok    = ctx.rsi_h4.rsi < InpQRsiOversold;
   bool macd_buy  = ctx.macd_m10.hist > InpQMacdSignalThresh;
   return adx_ok && rsi_ok && macd_buy;
  }

//+------------------------------------------------------------------+
//| _IsQSellBaseSignal — base SELL signal for pending gate (mirror)   |
//+------------------------------------------------------------------+
bool CSlotQ::_IsQSellBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok    = ctx.adx_h4.adx > InpQAdxMin;
   bool rsi_ok    = ctx.rsi_h4.rsi > InpQRsiOverbought;
   bool macd_sell = ctx.macd_m10.hist < -InpQMacdSignalThresh;
   return adx_ok && rsi_ok && macd_sell;
  }

//+------------------------------------------------------------------+
//| _IsQBuyTrigger — trigger condition to execute pending BUY         |
//| Precondition retest: MACD signal line cross (hist still positive) |
//+------------------------------------------------------------------+
bool CSlotQ::_IsQBuyTrigger(const MarketContext &ctx) const
  {
   //--- Trigger: MACD M10 hist still > 0 AND macd > signal (momentum confirm)
   return (ctx.macd_m10.hist > InpQMacdSignalThresh &&
           ctx.macd_m10.macd > ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| _IsQSellTrigger — trigger condition to execute pending SELL       |
//+------------------------------------------------------------------+
bool CSlotQ::_IsQSellTrigger(const MarketContext &ctx) const
  {
   return (ctx.macd_m10.hist < -InpQMacdSignalThresh &&
           ctx.macd_m10.macd < ctx.macd_m10.signal);
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot Q entry pass with Q-Pending integration           |
//|                                                                   |
//| Q-Pending pattern (ADR-008 / OQ-A2 / shared context §4.3):       |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal → EnterPending(PM_Q, payload, bar_index)  |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + trigger valid → place entry + TransitionExecuted    |
//|   Force-clear: PMR.TickAll (Orchestrator step 8) — slot ห้าม poll |
//+------------------------------------------------------------------+
void CSlotQ::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotQ) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active Q orders ("Q," prefix)
   if(_HasActiveQOrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_Q
   EPendingState st = m_pending.GetState(PM_Q);

   //--- Phase A: IDLE — check base signal, enter pending if met
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsQBuyBaseSignal(ctx);
      bool sellBase = _IsQSellBaseSignal(ctx);

      if(!buyBase && !sellBase) return;

      //--- Build pending payload (minimal JSON — schema lock deferred to IMPL-053+)
      string dir     = buyBase ? "BUY" : "SELL";
      string payload = StringFormat("{\"dir\":\"%s\",\"sl_pips\":%.1f}", dir, InpQSlPipsFloor);

      m_pending.EnterPending(PM_Q, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotQ", "pending_entered", MAGIC_Q,
                       StringFormat("dir=%s bar_index=%d payload=%s",
                                    dir, ctx.bar_index_h4, payload));
      return;
     }

   //--- Phase B: PENDING — check trigger, place entry if valid
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction
      string payload = m_pending.GetPayload(PM_Q);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      bool triggerOk = isBuy ? _IsQBuyTrigger(ctx) : _IsQSellTrigger(ctx);
      if(!triggerOk) return;

      //--- Compute SL
      double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double pip_factor = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10.0 : 1.0;
      double pip_size   = point * pip_factor;
      double sl_pips    = InpQSlPipsFloor;

      //--- Compute lot
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("Q", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotQ", "zero_lot_skip", MAGIC_Q,
                       "ComputeLot returned 0 — skipping Q entry");
         return;
        }

      //--- Compute SL + TP prices
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = 0.0;
      if(isBuy)
         sl_price = NormalizeDouble(ctx.ask - sl_pips * pip_size,
                                    (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
      else
         sl_price = NormalizeDouble(ctx.bid + sl_pips * pip_size,
                                    (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));

      //--- Comment: "Q,MA,N,1,SL" per CodeWiki §3.Q format
      string comment = "Q,MA,N,1,SL";

      //--- Submit order through RiskManager CTrade wrapper
      //    ห้าม instantiate CTrade direct (ea.md + ADR-002)
      //    Phase-1 stub: OrderSend deferred to Orchestrator wiring (IMPL-053+).
      //    Observable E-AC milestone: emit entry_signal Info log.
      ENUM_ORDER_TYPE order_type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

      MqlTradeRequest req  = {};
      MqlTradeResult  res  = {};

      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = order_type;
      req.price        = NormalizeDouble(price,
                                         (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
      req.sl           = sl_price;
      req.tp           = 0.0;    // TP = 0; profit gate managed in ManageExits
      req.comment      = comment;
      req.magic        = MAGIC_Q;
      req.type_filling = ORDER_FILLING_FOK;  // broker detection at IMPL-053+

      if(m_logger != NULL)
         m_logger.Info("SlotQ", "entry_signal", MAGIC_Q,
                       StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                                    (isBuy ? "BUY" : "SELL"), lot, sl_pips, price, sl_price,
                                    comment));

      //--- Transition PMR to EXECUTED state (force-clear counter resets)
      m_pending.TransitionExecuted(PM_Q);
     }

   //--- Phase C: EXECUTED — entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass — no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot Q exit pass (CodeWiki §3.Q MVP)                |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate Q positions via GetTicketsForSlot(MAGIC_Q, "Q,")    |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate ≥ InpQTpProfitPips (40 pip default) → close     |
//+------------------------------------------------------------------+
void CSlotQ::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve Q tickets (comment prefix "Q,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_Q, "Q,", tickets);
   if(n <= 0) return;

   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pip_factor = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10.0 : 1.0;
   double pip_size   = point * pip_factor;

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

      //--- Profit gate: ≥ InpQTpProfitPips → emit close signal
      if(profit_pips >= InpQTpProfitPips)
        {
         m_logger.Info("SlotQ", "exit_profit_gate", MAGIC_Q,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpQTpProfitPips));

         //--- Close via CTrade route (IMPL-053+ wiring)
         //    Phase-1 stub: log intent; OrderClose deferred to Orchestrator wiring.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_Q_MQH
