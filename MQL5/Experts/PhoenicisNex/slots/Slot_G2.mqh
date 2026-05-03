//+------------------------------------------------------------------+
//| slots/Slot_G2.mqh — Slot G2 implementation (IMPL-026)            |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_G = 208, shared with G (IMPL-025)                  |
//|          CommentParser disambiguates "G2," vs "G," per BR-1.2     |
//| Source:  CodeWiki §3.G2; TD-02 §5.4; ADR-002; ADR-012            |
//|                                                                   |
//| M-size MVP — 3 of CodeWiki §3.G2 conditions:                     |
//|   1. No active G2 orders (magic 208 with "G2," prefix)            |
//|   2. Force crossover in continuation range:                       |
//|        BUY  = F[1]>0 ∧ F[2]>-0.2 (in range, not exhausted)       |
//|        SELL = F[1]<0 ∧ F[2]<+0.2 (mirror)                         |
//|   3. Price outside Ichimoku cloud (or near retest — bid/cloud edge)|
//| Deferred to P4 IMPL-062: GPause / WPR-sanity / DeMarker /        |
//|   Force-wave-span exhaustion / lot scaling when G already open    |
//|                                                                   |
//| Exit (ManageExits):                                               |
//|   - Profit gate ≥ 30 pip (lighter than G's 50)                   |
//|   Stub: if(m_xslot != NULL && false /*IMPL-053*/) {...}           |
//|   Real CCrossSlotCoordinator coupling = IMPL-053                  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G2", InpG2SlPipsFloor, balance)    |
//| Comment: "G2,F1,N,1,SL" per CodeWiki §3.G2 format                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//|                                                                   |
//| Shared-magic note: PortfolioState.GetByMagic(208) returns G+G2    |
//| aggregate. GetTicketsForSlot(208, "G2,", tickets) filters own G2. |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_G2_MQH
#define PHOENICISNEX_SLOTS_SLOT_G2_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_G2.mqh"

//+------------------------------------------------------------------+
//| CSlotG2 — Slot G2 derived class (ADR-002 CSlotBase contract)      |
//|                                                                   |
//| Wave-helper role: lighter entry conditions + smaller lot factor   |
//| than G. Both share MAGIC_G (208); comment prefix "G2," used in   |
//| all OrderSend calls to disambiguate from G's "G," prefix.        |
//|                                                                   |
//| GetTicketsForSlot(208, "G2,", tickets) filters own orders.        |
//+------------------------------------------------------------------+
class CSlotG2 : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _IsG2BuySignal(const MarketContext &ctx) const;
   bool              _IsG2SellSignal(const MarketContext &ctx) const;
   bool              _IsPriceAboveCloud(const MarketContext &ctx) const;
   bool              _IsPriceBelowCloud(const MarketContext &ctx) const;
   bool              _HasActiveG2Order(CPortfolioState &port) const;
   double            _CloudHigh(const MarketContext &ctx) const;
   double            _CloudLow(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotG2() {}
   virtual ~CSlotG2() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_G = 208; shared with G (CommentParser disambig "G2,")
   virtual int      Magic() const override { return MAGIC_G; }

   //--- 2. SlotId — "G2"; used by journal slot_id field + comment prefix
   virtual string   SlotId() const override { return "G2"; }

   //--- 3. Evaluate — entry pass (FR-2.3); only called in EA_STATE_RUNNING
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void     ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — G2 is independent (CommentParser disambig is internal, not topo dep)
   virtual int      DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — G2 uses IDLE default (not in pending-flow list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _CloudHigh / _CloudLow — H4 Ichimoku cloud edge helpers           |
//+------------------------------------------------------------------+
double CSlotG2::_CloudHigh(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_high;
  }

double CSlotG2::_CloudLow(const MarketContext &ctx) const
  {
   return ctx.ichi_h4.cloud_low;
  }

//+------------------------------------------------------------------+
//| _IsPriceAboveCloud — bid > cloud_high                             |
//+------------------------------------------------------------------+
bool CSlotG2::_IsPriceAboveCloud(const MarketContext &ctx) const
  {
   return ctx.bid > _CloudHigh(ctx);
  }

//+------------------------------------------------------------------+
//| _IsPriceBelowCloud — ask < cloud_low                              |
//+------------------------------------------------------------------+
bool CSlotG2::_IsPriceBelowCloud(const MarketContext &ctx) const
  {
   return ctx.ask < _CloudLow(ctx);
  }

//+------------------------------------------------------------------+
//| _HasActiveG2Order — check for open G2 orders via PortfolioState   |
//| Uses GetTicketsForSlot(MAGIC_G, "G2,", tickets[]) — comment-disambig|
//+------------------------------------------------------------------+
bool CSlotG2::_HasActiveG2Order(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G2,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsG2BuySignal — Force continuation range BUY (CodeWiki §3.G2)   |
//|                                                                   |
//| Lighter condition than G (wave-helper role):                      |
//|   F[1] > InpG2FIContinuationMin (> 0.0)                          |
//|   F[2] > InpG2FIContinuationLow (> -0.2, in continuation range)  |
//|                                                                   |
//| Meaning: Force is still positive but not exhausted — wave helper  |
//| enters after G has fired (continuation into the same wave).       |
//+------------------------------------------------------------------+
bool CSlotG2::_IsG2BuySignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;

   //--- Continuation range: F[1]>0 ∧ F[2]>-0.2 (still in wave, not reversed)
   return (f1 > InpG2FIContinuationMin && f2 > InpG2FIContinuationLow);
  }

//+------------------------------------------------------------------+
//| _IsG2SellSignal — Force continuation range SELL (mirror of BUY)  |
//|   F[1] < -InpG2FIContinuationMin (< 0.0)                         |
//|   F[2] < -InpG2FIContinuationLow (< +0.2)                        |
//+------------------------------------------------------------------+
bool CSlotG2::_IsG2SellSignal(const MarketContext &ctx) const
  {
   double f1 = ctx.force_h4.f1;
   double f2 = ctx.force_h4.f2;

   //--- Mirror of BUY (negated thresholds)
   return (f1 < -InpG2FIContinuationMin && f2 < -InpG2FIContinuationLow);
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot G2 entry pass (CodeWiki §3.G2 MVP)                |
//|                                                                   |
//| Entry conditions (3 of N for M-size MVP):                         |
//|   1. InpEnableSlotG2 == true                                      |
//|   2. No active G2 orders (magic 208 "G2," prefix)                 |
//|   3. Force crossover in continuation range (BUY or SELL)          |
//|   4. Price outside Ichimoku cloud (confirms direction)            |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("G2", InpG2SlPipsFloor, balance)    |
//| Comment: "G2,F1,N,1,SL"                                          |
//+------------------------------------------------------------------+
void CSlotG2::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotG2) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active G2 (own "G2," prefix orders)
   if(_HasActiveG2Order(port)) return;

   //--- Determine direction
   bool buySignal  = _IsG2BuySignal(ctx);
   bool sellSignal = _IsG2SellSignal(ctx);
   if(!buySignal && !sellSignal) return;

   //--- Condition 3: price outside cloud + matches direction
   bool priceOk = false;
   if(buySignal)  priceOk = _IsPriceAboveCloud(ctx);
   if(sellSignal) priceOk = _IsPriceBelowCloud(ctx);
   if(!priceOk) return;

   //--- Compute SL: max(cloud-edge distance, InpG2SlPipsFloor)
   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pip_factor = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10.0 : 1.0;
   double pip_size   = point * pip_factor;

   double cloud_edge_pips = 0.0;
   if(buySignal)
      cloud_edge_pips = (ctx.bid - _CloudLow(ctx)) / pip_size;
   else
      cloud_edge_pips = (_CloudHigh(ctx) - ctx.ask) / pip_size;

   double sl_pips = MathMax(cloud_edge_pips, InpG2SlPipsFloor);

   //--- Compute lot (lighter base factor than G)
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("G2", sl_pips, balance);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotG2", "zero_lot_skip", MAGIC_G,
                    "ComputeLot returned 0 — skipping G2 entry");
      return;
     }

   //--- Compute SL price (TP = 0; profit-gate exit in ManageExits)
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double sl_price = 0.0;
   double tp_price = 0.0;

   if(buySignal)
      sl_price = NormalizeDouble(ctx.ask - sl_pips * pip_size, digits);
   else
      sl_price = NormalizeDouble(ctx.bid + sl_pips * pip_size, digits);

   //--- Comment: "G2,F1,N,1,SL" per CodeWiki §3.G2 — disambig from "G,"
   string comment = "G2,F1,N,1,SL";

   //--- Build order request (route through RiskManager — ea.md: ห้าม instantiate CTrade direct)
   ENUM_ORDER_TYPE order_type = buySignal ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = buySignal ? ctx.ask : ctx.bid;

   MqlTradeRequest req = {};
   MqlTradeResult  res = {};

   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = lot;
   req.type         = order_type;
   req.price        = NormalizeDouble(price, digits);
   req.sl           = sl_price;
   req.tp           = tp_price;
   req.comment      = comment;
   req.magic        = MAGIC_G;
   req.type_filling = ORDER_FILLING_FOK;   // filling mode set per broker detection at IMPL-053+

   //--- Phase-1 stub: OrderSend deferred to IMPL-053+ orchestrator wiring.
   //    Observable milestone for E-AC [log-assertion]:
   m_logger.Info("SlotG2", "entry_signal", MAGIC_G,
                 StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
                              (buySignal ? "BUY" : "SELL"), lot, sl_pips, price, sl_price, comment));

   //--- CrossSlotCoordinator stub (IMPL-053)
   if(m_xslot != NULL && false /*IMPL-053: enable when CrossSlotCoordinator declared*/)
     {
      //--- Stub: coupling to G-overload signal deferred to IMPL-053
     }
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot G2 exit pass (lighter profit gate; 30 pip MVP) |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate G2 positions via GetTicketsForSlot(MAGIC_G, "G2,")  |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate ≥ InpG2TpProfitPips (30 pip default) → close    |
//+------------------------------------------------------------------+
void CSlotG2::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve G2 tickets (comment prefix "G2," — disambig from "G,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G2,", tickets);
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

      //--- Profit gate: ≥ InpG2TpProfitPips (30 pip default — lighter than G's 50)
      if(profit_pips >= InpG2TpProfitPips)
        {
         m_logger.Info("SlotG2", "exit_profit_gate", MAGIC_G,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpG2TpProfitPips));

         //--- Phase-1 stub: OrderSend close deferred to IMPL-053+ orchestrator wiring.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub — deferred (IMPL-053)
      if(m_xslot != NULL && false /*IMPL-053*/)
        {
         //--- Stub: any G2 peak-based cross-slot coupling goes here (IMPL-053)
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_G2_MQH
