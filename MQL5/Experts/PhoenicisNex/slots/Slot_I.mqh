//+------------------------------------------------------------------+
//| slots/Slot_I.mqh — Slot I implementation (IMPL-028)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_I = 216 (own; not shared)                          |
//| Source:  CodeWiki §3.I; TD-02 §5.4; ADR-002; ADR-012             |
//|                                                                   |
//| S-size MVP — 3 of N CodeWiki §3.I conditions:                     |
//|   1. Parasite gate: G must have ≥1 active "G," order              |
//|      → port.GetTicketsForSlot(MAGIC_G, "G,", g_tickets) > 0       |
//|   2. Own-no-active guard: no existing "I," order                  |
//|      → port.GetTicketsForSlot(MAGIC_I, "I,", own_tickets) == 0    |
//|   3. Direction inheritance from first G ticket + Fibonacci retrace |
//|      price gate: price retraced to InpIFibLevel (0.5 default)     |
//|      of recent InpILookbackBars range in G's direction             |
//| Deferred to P4 IMPL-062: GPause / ADX confirmation / wave-spans   |
//|                                                                    |
//| Exit (ManageExits):                                               |
//|   - Profit gate >= InpITpProfitPips (25 pip — shorter-horizon)    |
//|   Stub: if(m_xslot != NULL && false /*IMPL-053*/) {...}           |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("I", InpISlPips, balance)            |
//| Comment: "I,fib,1" per CodeWiki §3.I "I,..." pattern             |
//|                                                                   |
//| Topology dependency:                                              |
//|   DependsOn() returns 1, out_magics[0] = MAGIC_G                 |
//|   (parasite: runtime state of MAGIC_G gates entry)                |
//|   Distinct from G2/LX which return 0 (internal disambig only)    |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//|   Cross-slot access via PortfolioState.GetTicketsForSlot() only   |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_I_MQH
#define PHOENICISNEX_SLOTS_SLOT_I_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../inputs/Inputs_Slot_I.mqh"

//+------------------------------------------------------------------+
//| CSlotI — Slot I derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| G-parasite Fibonacci pattern:                                     |
//|   - Entry ONLY when G has an active open "G," position           |
//|   - Direction inherited from G's first ticket (BUY/SELL)         |
//|   - Fibonacci retracement confirmation: price has retraced to     |
//|     InpIFibLevel of the recent N-bar range in G's direction       |
//|   - Own-no-active guard prevents double-entry                     |
//|                                                                   |
//| Magic 216 own (not shared). Comment prefix "I," in all orders.   |
//| GetTicketsForSlot(MAGIC_I, "I,", tickets) filters own orders.     |
//+------------------------------------------------------------------+
class CSlotI : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActiveGOrder(CPortfolioState &port) const;
   bool              _HasActiveIOrder(CPortfolioState &port) const;
   ENUM_POSITION_TYPE _GetGDirection(CPortfolioState &port) const;
   bool              _IsFibRetraceReady(const MarketContext &ctx,
                                        ENUM_POSITION_TYPE g_dir) const;
   double            _RangeHigh(const MarketContext &ctx) const;
   double            _RangeLow(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotI() {}
   virtual ~CSlotI() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_I = 216 (own; not shared)
   virtual int      Magic() const override { return MAGIC_I; }

   //--- 2. SlotId — "I"; used by journal slot_id field + comment prefix
   virtual string   SlotId() const override { return "I"; }

   //--- 3. Evaluate — entry pass (FR-2.3); only called in EA_STATE_RUNNING
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void     ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — I is a G-parasite (topology dep on MAGIC_G)
   //       Returns 1; out_magics[0] = MAGIC_G
   //       Distinct from G2/LX (CommentParser disambig = internal, returns 0)
   virtual int      DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_G;
      return 1;
     }

   //--- 6. PendingState — I uses IDLE default (not in pending-flow list)
   virtual EPendingState PendingState() const override { return PENDING_STATE_IDLE; }
  };

//+------------------------------------------------------------------+
//| _HasActiveGOrder — check for open G parent orders via PortfolioState|
//| Uses GetTicketsForSlot(MAGIC_G, "G,", tickets) — "G," prefix only  |
//| (not "G2," or other G-pool prefix)                                 |
//+------------------------------------------------------------------+
bool CSlotI::_HasActiveGOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _HasActiveIOrder — check for own open I orders via PortfolioState  |
//| Uses GetTicketsForSlot(MAGIC_I, "I,", tickets) — own "I," prefix  |
//+------------------------------------------------------------------+
bool CSlotI::_HasActiveIOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_I, "I,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _GetGDirection — retrieve direction of first active G order        |
//| Returns POSITION_TYPE_BUY or POSITION_TYPE_SELL.                  |
//| Caller must ensure _HasActiveGOrder() is true before calling.     |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE CSlotI::_GetGDirection(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_G, "G,", tickets);
   if(n <= 0) return POSITION_TYPE_BUY;   // fallback (caller guards _HasActiveGOrder)

   if(!PositionSelectByTicket(tickets[0]))
      return POSITION_TYPE_BUY;           // fallback on select failure

   return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
  }

//+------------------------------------------------------------------+
//| _RangeHigh — highest high over InpILookbackBars bars              |
//| Uses iHigh() series (MarketContext snapshot: fallback to live)    |
//+------------------------------------------------------------------+
double CSlotI::_RangeHigh(const MarketContext &ctx) const
  {
   //--- Use iHigh series to find the high over lookback window
   double range_high = DBL_MIN;
   for(int i = 1; i <= InpILookbackBars; i++)
     {
      double bar_high = iHigh(_Symbol, PERIOD_H4, i);
      if(bar_high > range_high)
         range_high = bar_high;
     }
   return range_high;
  }

//+------------------------------------------------------------------+
//| _RangeLow — lowest low over InpILookbackBars bars                 |
//+------------------------------------------------------------------+
double CSlotI::_RangeLow(const MarketContext &ctx) const
  {
   //--- Use iLow series to find the low over lookback window
   double range_low = DBL_MAX;
   for(int i = 1; i <= InpILookbackBars; i++)
     {
      double bar_low = iLow(_Symbol, PERIOD_H4, i);
      if(bar_low < range_low)
         range_low = bar_low;
     }
   return range_low;
  }

//+------------------------------------------------------------------+
//| _IsFibRetraceReady — check if price retraced to InpIFibLevel      |
//|                                                                   |
//| For BUY (G is long, I Fibonacci continuation BUY):                |
//|   fib_price = range_high - InpIFibLevel * (range_high - range_low)|
//|   → I enters BUY when ask <= fib_price (price retraced to level)  |
//|                                                                   |
//| For SELL (G is short, I Fibonacci continuation SELL):             |
//|   fib_price = range_low + InpIFibLevel * (range_high - range_low) |
//|   → I enters SELL when bid >= fib_price                           |
//+------------------------------------------------------------------+
bool CSlotI::_IsFibRetraceReady(const MarketContext &ctx,
                                 ENUM_POSITION_TYPE g_dir) const
  {
   double range_high = _RangeHigh(ctx);
   double range_low  = _RangeLow(ctx);

   //--- Insufficient range (flat / data not available) → skip
   if(range_high <= range_low) return false;

   double range_span = range_high - range_low;
   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   //--- Require at least 10 pips of range to be meaningful (Round-06 06.1)
   if(range_span < _PipsToPrice(10.0)) return false;

   if(g_dir == POSITION_TYPE_BUY)
     {
      //--- Fib retrace level below range_high: ask <= fib_price means price retraced
      double fib_price = range_high - InpIFibLevel * range_span;
      return ctx.ask <= fib_price;
     }
   else
     {
      //--- Fib retrace level above range_low: bid >= fib_price means price retraced up
      double fib_price = range_low + InpIFibLevel * range_span;
      return ctx.bid >= fib_price;
     }
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot I entry pass (CodeWiki §3.I MVP)                  |
//|                                                                   |
//| Entry conditions (3 of N for S-size MVP):                         |
//|   1. InpEnableSlotI == true                                       |
//|   2. G has ≥1 active "G," order (parasite gate)                   |
//|   3. No active I orders (own-no-active guard)                     |
//|   4. Direction inherited from G's first ticket                    |
//|   5. Fibonacci retracement confirmation at InpIFibLevel           |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("I", InpISlPips, balance)            |
//| Comment: "I,fib,1" per CodeWiki §3.I                             |
//+------------------------------------------------------------------+
void CSlotI::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotI) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1 (parasite gate): G must have ≥1 active "G," order
   //    Cross-slot access via PortfolioState.GetTicketsForSlot (ADR-012)
   if(!_HasActiveGOrder(port)) return;

   //--- Condition 2 (own-no-active guard): I must have no open "I," orders
   if(_HasActiveIOrder(port)) return;

   //--- Condition 3: get G direction (BUY or SELL) from first G ticket
   ENUM_POSITION_TYPE g_dir = _GetGDirection(port);

   //--- Condition 4: Fibonacci retracement at InpIFibLevel of N-bar range
   if(!_IsFibRetraceReady(ctx, g_dir)) return;

   //--- Pip size via base-class helper (Round-06 06.1)
   double pip_size = _PipSize();

   //--- SL: use InpISlPips as floor (Fibonacci-based SL; shorter horizon)
   double sl_pips = InpISlPips;

   //--- Compute lot
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot     = m_risk.ComputeLot("I", sl_pips, balance);

   if(lot <= 0.0)
     {
      m_logger.Warn("SlotI", "zero_lot_skip", MAGIC_I,
                    "ComputeLot returned 0 — skipping I entry");
      return;
     }

   //--- Compute prices (broker-bound — base-class _NormalizeBrokerPrice)
   bool   isBuy    = (g_dir == POSITION_TYPE_BUY);
   double price    = isBuy ? ctx.ask : ctx.bid;
   double sl_price = isBuy
                     ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                     : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

   //--- Comment: "I,fib,1" per CodeWiki §3.I "I,..." pattern
   string comment = "I,fib,1";

   //--- fix-round-12 § 12.8 — Phase 1 emits entry_signal Logger.Info as
   //    the observable milestone; actual OrderSend lives in
   //    `RiskManager::OpenOrder` per `.claude/rules/ea.md` (IMPL-017 +
   //    IMPL-062 5-yr regression).
   //    Observable milestone for E-AC [log-assertion]:
   m_logger.Info("SlotI", "entry_signal", MAGIC_I,
                 StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s fib_level=%.2f g_dir=%s",
                              (isBuy ? "BUY" : "SELL"), lot, sl_pips, price, sl_price, comment,
                              InpIFibLevel, (g_dir == POSITION_TYPE_BUY ? "G_BUY" : "G_SELL")));

   //--- CrossSlotCoordinator stub
   if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (Phase-2 wiring; see docs/state/deferred-ac-registry.md) */)
     {
      //--- Stub: Fibonacci parasite coupling
      //    wires at Phase-2 wiring; see docs/state/deferred-ac-registry.md (cross-slot coupling per ea.md).
     }
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot I exit pass (shorter profit gate; 25 pip MVP)  |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate I positions via GetTicketsForSlot(MAGIC_I, "I,")    |
//|   2. For each: compute unrealized profit in pips                  |
//|   3. Profit gate >= InpITpProfitPips (25 pip) → log close intent  |
//|                                                                   |
//| Additional exit logic (P4 IMPL-062):                             |
//|   - Close I when parent G position closes (orphan-guard)          |
//|   - Trailing stop on Fibonacci extension                          |
//+------------------------------------------------------------------+
void CSlotI::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve I tickets (own comment prefix "I,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_I, "I,", tickets);
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

      //--- Profit gate: >= InpITpProfitPips (25 pip — shorter-horizon Fibonacci target)
      if(profit_pips >= InpITpProfitPips)
        {
         m_logger.Info("SlotI", "exit_profit_gate", MAGIC_I,
                       StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
                                    ticket, profit_pips, InpITpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Phase-2 wiring; see docs/state/deferred-ac-registry.md (RiskManager::OpenOrder) per ea.md.
         //    Evidence for E-AC [log-assertion]: above Info log is the observable milestone.
        }

      //--- CrossSlotCoordinator stub
      if(m_xslot != NULL && false /* enable when CrossSlotCoordinator declared (Phase-2 wiring; see docs/state/deferred-ac-registry.md) */)
        {
         //--- Stub: orphan-guard coupling (close I when parent G closes)
         //    wires at Phase-2 wiring; see docs/state/deferred-ac-registry.md (cross-slot coupling per ea.md).
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_I_MQH
