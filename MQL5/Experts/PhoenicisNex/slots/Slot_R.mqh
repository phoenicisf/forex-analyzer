//+------------------------------------------------------------------+
//| slots/Slot_R.mqh โ€” Slot R implementation (IMPL-033)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_R = 213                                            |
//| Source:  CodeWiki ยง3 Slot R; ADR-002; ADR-012                     |
//|                                                                   |
//| R-Pending uses legacy timeout (InpLegacyRBars = 40); no ADR-008  |
//| force-clear โ€” internal PMR behavior, slot-side API identical to   |
//| M/Q/T (slot calls EnterPending/GetState/TransitionExecuted with   |
//| PM_R; PMR.TickAll in Orchestrator step 8 owns timeout logic).     |
//|                                                                   |
//| M-size MVP โ€” 3 of N CodeWiki ยง3.R conditions:                    |
//|   1. No active R orders (magic 213 with "R," prefix)              |
//|   2. ADX H4 dominance: adx > InpRAdxMin (trend filter)            |
//|   3. RSI H4 retracement gate: oversold/overbought confirmation    |
//| Deferred to P4 IMPL-063+: RSI-D1 divergence / WPR wave confirm / |
//|   Ichimoku cloud boundary / Fractal breakout precision exit        |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate โฅ InpRTpProfitPips (40 pip default)               |
//|                                                                   |
//| Pending integration (BR-6.3 โ€” legacy timeout, no ADR-008):        |
//|   - CPendingMachineRegistry PM_R; legacy timeout = PMR.TickAll    |
//|   - InpLegacyRBars = 40 (Inputs_Pending.mqh)                      |
//|   - Slot เธซเนเธฒเธก call TickAll directly โ€” Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("R", InpRSlPipsFloor, balance)       |
//| Comment: "R,MA,N,1,SL" per CodeWiki comment format                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   เธซเนเธฒเธก #include "slots/<other>.mqh"                               |
//|   เธซเนเธฒเธก #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_R_MQH
#define PHOENICISNEX_SLOTS_SLOT_R_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_R.mqh"

//+------------------------------------------------------------------+
//| CSlotR โ€” Slot R derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses R-Pending state machine (PM_R) with legacy timeout to gate   |
//| entry:                                                            |
//|   IDLE + base signal โ’ EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid โ’ place entry + TransitionExecuted      |
//|   Legacy timeout (40 H4 bars): handled by PMR.TickAll in Orchestr.|
//+------------------------------------------------------------------+
class CSlotR : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveROrder(CPortfolioState &port) const;
   bool              _IsRBuyBaseSignal(const MarketContext &ctx) const;
   bool              _IsRSellBaseSignal(const MarketContext &ctx) const;
   bool              _IsRBuyTrigger(const MarketContext &ctx) const;
   bool              _IsRSellTrigger(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotR() {}
   virtual ~CSlotR() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic โ€” MAGIC_R = 213
   virtual int           Magic()  const override { return MAGIC_R; }

   //--- 2. SlotId โ€” "R"; used by journal slot_id field + comment prefix "R,"
   virtual string        SlotId() const override { return "R"; }

   //--- 3. Evaluate โ€” entry pass with R-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits โ€” exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn โ€” R is topologically independent; PMR dep is shared service
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState โ€” delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_R);
     }
  };

//+------------------------------------------------------------------+
//| _HasActiveROrder โ€” check for open R orders via PortfolioState     |
//| Comment prefix "R," for disambiguation                            |
//+------------------------------------------------------------------+
bool CSlotR::_HasActiveROrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_R, "R,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsRBuyBaseSignal โ€” base BUY signal for pending gate              |
//|                                                                   |
//| Conditions (MVP 3 of N CodeWiki ยง3.R):                            |
//|   1. ADX H4 dominance: adx > InpRAdxMin (trend filter)            |
//|   2. RSI H4 oversold: rsi < InpRRsiOversold (retracement BUY)     |
//|   3. DI+ > DI- (bullish directional bias)                         |
//+------------------------------------------------------------------+
bool CSlotR::_IsRBuyBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok    = ctx.adx_h4.adx > InpRAdxMin;
   bool rsi_ok    = ctx.rsi_h4.rsi < InpRRsiOversold;
   bool di_ok     = ctx.adx_h4.di_plus > ctx.adx_h4.di_minus;
   return adx_ok && rsi_ok && di_ok;
  }

//+------------------------------------------------------------------+
//| _IsRSellBaseSignal โ€” base SELL signal for pending gate (mirror)   |
//+------------------------------------------------------------------+
bool CSlotR::_IsRSellBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok    = ctx.adx_h4.adx > InpRAdxMin;
   bool rsi_ok    = ctx.rsi_h4.rsi > InpRRsiOverbought;
   bool di_ok     = ctx.adx_h4.di_minus > ctx.adx_h4.di_plus;
   return adx_ok && rsi_ok && di_ok;
  }

//+------------------------------------------------------------------+
//| _IsRBuyTrigger โ€” trigger condition to execute pending BUY         |
//| Retracement confirm: RSI recovered from oversold                  |
//+------------------------------------------------------------------+
bool CSlotR::_IsRBuyTrigger(const MarketContext &ctx) const
  {
   //--- Trigger: RSI recovered above oversold floor (retracement confirm)
   //    + ADX still dominant
   return (ctx.rsi_h4.rsi >= InpRRsiOversold &&
           ctx.adx_h4.adx > InpRAdxMin &&
           ctx.adx_h4.di_plus > ctx.adx_h4.di_minus);
  }

//+------------------------------------------------------------------+
//| _IsRSellTrigger โ€” trigger condition to execute pending SELL       |
//+------------------------------------------------------------------+
bool CSlotR::_IsRSellTrigger(const MarketContext &ctx) const
  {
   return (ctx.rsi_h4.rsi <= InpRRsiOverbought &&
           ctx.adx_h4.adx > InpRAdxMin &&
           ctx.adx_h4.di_minus > ctx.adx_h4.di_plus);
  }

//+------------------------------------------------------------------+
//| Evaluate โ€” Slot R entry pass with R-Pending integration           |
//|                                                                   |
//| R-Pending pattern (BR-6.3 legacy timeout / shared context ยง4.3): |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal โ’ EnterPending(PM_R, payload, bar_index)  |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + trigger valid โ’ place entry + TransitionExecuted    |
//|   Legacy timeout: PMR.TickAll (Orchestrator step 8) โ€” slot เธซเนเธฒเธก poll|
//|   NOTE: No ADR-008 force-clear for slot R โ€” legacy timeout only.  |
//+------------------------------------------------------------------+
void CSlotR::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotR) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active R orders ("R," prefix)
   if(_HasActiveROrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_R
   EPendingState st = m_pending.GetState(PM_R);

   //--- Phase A: IDLE โ€” check base signal, enter pending if met
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsRBuyBaseSignal(ctx);
      bool sellBase = _IsRSellBaseSignal(ctx);

      if(!buyBase && !sellBase) return;

      //--- Build pending payload (minimal JSON โ€” full schema in state-persistence-schema.yaml ยง PendingMachine)
      string dir     = buyBase ? "BUY" : "SELL";
      string payload = StringFormat("{\"dir\":\"%s\",\"sl_pips\":%.1f}", dir, InpRSlPipsFloor);

      m_pending.EnterPending(PM_R, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotR", "pending_entered", MAGIC_R,
                       StringFormat("dir=%s bar_index=%d payload=%s",
                                    dir, ctx.bar_index_h4, payload));
      return;
     }

   //--- Phase B: PENDING โ€” check trigger, place entry if valid
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction
      string payload = m_pending.GetPayload(PM_R);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      bool triggerOk = isBuy ? _IsRBuyTrigger(ctx) : _IsRSellTrigger(ctx);
      if(!triggerOk) return;

      //--- Pip size via base-class helper (Round-06 06.1)
      double pip_size = _PipSize();
      double sl_pips  = InpRSlPipsFloor;

      //--- Compute lot
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("R", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotR", "zero_lot_skip", MAGIC_R,
                       "ComputeLot returned 0 โ€” skipping R entry");
         return;
        }

      //--- Compute SL + TP prices
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                        : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

      //--- Comment: "R,MA,N,1,SL" per CodeWiki ยง3.R format
      string comment = "R,MA,N,1,SL";

      //--- Submit order through RiskManager CTrade wrapper
      //    เธซเนเธฒเธก instantiate CTrade direct (ea.md + ADR-002)
      //    fix-round-12 ยง 12.8 โ€” Phase 1 emits entry_signal Info as the
      //    observable milestone; actual OrderSend wiring lives in
      //    `RiskManager::OpenOrder` (Orchestrator wiring path (core/Orchestrator.mqh) 5-yr regression).
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
      req.magic        = MAGIC_R;
      req.type_filling = ORDER_FILLING_FOK;  // broker detection at Orchestrator wiring path (core/Orchestrator.mqh)

      if(m_logger != NULL)
         m_logger.Info("SlotR", "entry_signal", MAGIC_R,
                       StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                                    (isBuy ? "BUY" : "SELL"), lot, sl_pips, price, sl_price,
                                    comment));

      //--- IMPL-FIX-003: submit broker order via RiskManager.OpenOrder wrapper (ea.md mandate)
      m_risk.OpenOrder(req, "R");

      //--- Transition PMR to EXECUTED state (legacy timeout counter resets)
      m_pending.TransitionExecuted(PM_R);
     }

   //--- Phase C: EXECUTED โ€” entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass โ€” no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits โ€” Slot R exit pass (CodeWiki ยง3.R MVP)                |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate R positions via GetTicketsForSlot(MAGIC_R, "R,")    |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate โฅ InpRTpProfitPips (40 pip default) โ’ close     |
//+------------------------------------------------------------------+
void CSlotR::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve R tickets (comment prefix "R,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_R, "R,", tickets);
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

      //--- Profit gate: โฅ InpRTpProfitPips โ’ emit close signal
      if(profit_pips >= InpRTpProfitPips)
        {
         m_logger.Info("SlotR", "exit_profit_gate", MAGIC_R,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f โ’ close",
                                    ticket, profit_pips, InpRTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_R_MQH
