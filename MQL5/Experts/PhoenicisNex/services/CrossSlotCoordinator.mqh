//+------------------------------------------------------------------+
//| CrossSlotCoordinator.mqh — cross-slot bulk cleanup (BR-8.x)     |
//| Layer:   services/                                               |
//| Source:  TD-02 §5.11, BR-8.1..8.5, FR-7.1..7.5,                 |
//|          ADR-010 (HALTED enable matrix `04 § 9.1`),             |
//|          CodeWiki §5.5 (OrderGroupStartWorkflow baseline)       |
//|                                                                  |
//| IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1).   |
//| IMPL-055 sub-pass: RunForceCutloss full body (BR-8.3 CD safety).|
//| Sibling methods (RunOrderGroup2/ExtraCheckFunction2/            |
//| RunCOverload/RunEOverload/TriggerGOverload/EvaluateBR_OrphanExit|
//| ) are TODO IMPL-054/056/057 stubs; HALTED guard already in      |
//| place where matrix dictates.                                    |
//|                                                                  |
//| Spec deviation logged: TD-02 §5.11 declares                     |
//|   `void RunSafePort(const MarketContext&)`                      |
//| this implementation returns `int` (slots_closed_count) per      |
//| IMPL-053 S-AC #3 ("Returns per-call summary for journal record")|
//| Plan text > skeleton text per Plan QA precedent.                |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_CROSSSLOTCOORDINATOR_MQH
#define PHOENICISNEX_SERVICES_CROSSSLOTCOORDINATOR_MQH

#include <Trade\Trade.mqh>

#include "../domain/EnumTypes.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/SlotState.mqh"
#include "../helpers/PipMath.mqh"
#include "Logger.mqh"
#include "PortfolioState.mqh"
#include "RiskManager.mqh"
#include "TradeJournal.mqh"

//+------------------------------------------------------------------+
//| BR-8.1 trigger thresholds (CodeWiki §5.5 baseline)              |
//+------------------------------------------------------------------+
#define SAFEPORT_WEAK_ORDER_MIN     1     // weakOrderCount > 1 (strict)
#define SAFEPORT_AVG_BAD_PIP_MIN    55.0  // avg bad-PIP excursion threshold
#define SAFEPORT_PROFIT_MIN         0.0   // combined floating PL > 0

//+------------------------------------------------------------------+
//| Target slot set for BR-8.1 bulk close: {C,D,J,H,K,L,M,Q,GO,T,S} |
//| Per BA `04 § BR-8.1` literal — magics unique-set has 10 entries  |
//| (CD shared on MAGIC_CD; both slot_ids parsed via GetTicketsForSlot|
//+------------------------------------------------------------------+
struct SafePortTarget
  {
   int    magic;
   string slot_prefix;     // comment prefix for shared-magic disambig (BR-1.2)
  };

//+------------------------------------------------------------------+
//| CCrossSlotCoordinator                                            |
//|                                                                  |
//| Naming: m_* members, PascalCase public, _camelCase private       |
//| (per ea.md naming conventions + ADR-012)                         |
//+------------------------------------------------------------------+
class CCrossSlotCoordinator
  {
private:
   CPortfolioState  *m_portfolio;
   CTradeJournal    *m_journal;
   CLogger          *m_logger;
   CRiskManager     *m_risk;
   CPipMath         *m_pip;
   bool              m_halted;     // updated each tick from EAState (per `02 § 7.2 step 5b`)
   CTrade            m_trade;       // service-layer CTrade allowed (ea.md restricts only slots/*)

public:
                     CCrossSlotCoordinator()
      : m_portfolio(NULL),
        m_journal(NULL),
        m_logger(NULL),
        m_risk(NULL),
        m_pip(NULL),
        m_halted(false) {}

   //--- Composition Root injection (Orchestrator OnInit step 6+ per TD-02 §7.4)
   void              Init(CPortfolioState *port,
                          CTradeJournal *tj,
                          CLogger *lg,
                          CRiskManager *rm,
                          CPipMath *pip);

   //--- Called by Orchestrator OnTick step 5b BEFORE RunExitPass (Claim 01.3)
   void              SetHalted(bool halted) { m_halted = halted; }
   bool              IsHalted() const { return m_halted; }

   //--- Exit-side helpers — RUN in both RUNNING and HALTED (per ADR-010 / `04 § 9.1`)
   int               RunSafePort(const MarketContext &ctx);              // BR-8.1 (returns slots_closed_count)
   void              RunOrderGroup2(const MarketContext &ctx);            // BR-8.2 — TODO IMPL-054
   void              RunForceCutloss(const MarketContext &ctx);           // BR-8.3 — TODO IMPL-055
   void              ExtraCheckFunction2();                                // BR-8.5 — TODO IMPL-056
   void              RunCOverload(const MarketContext &ctx);               // BR-8.4 exit-side — TODO IMPL-057

   //--- Entry-side helpers — RUN only in RUNNING (per ADR-010 enable matrix)
   void              RunEOverload(const MarketContext &ctx);               // BR-8.4 entry-side — TODO IMPL-057

   //--- Post-exit hooks — invoked by slot ManageExits via injection
   void              TriggerGOverload(double closing_lot, int direction);  // BR-8.4 — TODO IMPL-057
   void              EvaluateBR_OrphanExit();                              // BR-2.1 (B → BR) — TODO IMPL-038/057

   //--- Inline SelfTest (G1 spike harness)
   bool              SelfTest(CLogger *logger);

private:
   //--- Composite trigger evaluation (BR-8.1)
   bool              _SafePortTriggered(int weak_count,
                                        double avg_bad_pip,
                                        double combined_pl) const;

   //--- Aggregate weak-order metrics across all 17 magics
   //    Out: weak_count + sum_bad_pip + total_pl. badPip is positive
   //    excursion magnitude (i.e., abs of a losing position's pip distance
   //    from open price). avg_bad_pip = sum_bad_pip / weak_count.
   void              _AggregateWeakMetrics(int &weak_count,
                                           double &sum_bad_pip,
                                           double &total_pl) const;

   //--- Build the per-tick target slot table (BR-8.1 spec literal)
   int               _FillSafePortTargets(SafePortTarget &out[]) const;

   //--- Close all positions for one (magic, slot_prefix) pair via CTrade
   //    Returns count of close calls issued (regardless of MT5 ack).
   int               _CloseSlotGroup(int magic, string slot_prefix);

   //--- BR-8.3 ForceCutloss composite signal (Stoch M10 + MACD D1 confirm)
   //    Returns +1 to cut BUY losses, -1 to cut SELL losses, 0 otherwise
   //    (CodeWiki §5.5 :9009 baseline — Stochastic K vs D + MACD hist sign)
   int               _ForceCutlossSignal(const MarketContext &ctx) const;

   //--- Close every CD position whose direction matches `signal` and PL<0
   //    Emits per-ticket exit journal with triggering_function="ForceCutloss"
   //    Returns count of close calls issued.
   int               _CloseCDPositionsInLoss(int signal);
  };

//+------------------------------------------------------------------+
//| Init — store dependencies + reset halted flag                    |
//+------------------------------------------------------------------+
void CCrossSlotCoordinator::Init(CPortfolioState *port,
                                 CTradeJournal *tj,
                                 CLogger *lg,
                                 CRiskManager *rm,
                                 CPipMath *pip)
  {
   m_portfolio = port;
   m_journal   = tj;
   m_logger    = lg;
   m_risk      = rm;
   m_pip       = pip;
   m_halted    = false;
   // CTrade defaults are sufficient (filling-policy detected per-call inside MT5)
  }

//+------------------------------------------------------------------+
//| _SafePortTriggered — composite gate per BR-8.1                   |
//|   weakOrderCount > 1 AND avg_bad_pip > 55 AND combined_pl > 0    |
//+------------------------------------------------------------------+
bool CCrossSlotCoordinator::_SafePortTriggered(int weak_count,
                                               double avg_bad_pip,
                                               double combined_pl) const
  {
   if(weak_count <= SAFEPORT_WEAK_ORDER_MIN)        return false;
   if(avg_bad_pip <= SAFEPORT_AVG_BAD_PIP_MIN)      return false;
   if(combined_pl <= SAFEPORT_PROFIT_MIN)           return false;
   return true;
  }

//+------------------------------------------------------------------+
//| _AggregateWeakMetrics — iterate live positions, derive metrics    |
//|                                                                  |
//| Phase-1 wiring note: PortfolioState.GetByMagic() returns the     |
//| per-magic SlotState; ticket_ids[] is populated by                |
//| OnTradeTransaction once Orchestrator is wired (IMPL-059). For    |
//| pre-wired runs (spike harness, today) the loop is a no-op and    |
//| returns zeros — _SafePortTriggered then short-circuits.          |
//+------------------------------------------------------------------+
void CCrossSlotCoordinator::_AggregateWeakMetrics(int &weak_count,
                                                  double &sum_bad_pip,
                                                  double &total_pl) const
  {
   weak_count  = 0;
   sum_bad_pip = 0.0;
   total_pl    = 0.0;

   if(m_portfolio == NULL || m_pip == NULL) return;

   //--- Iterate active platform positions directly (authoritative source)
   //    PortfolioState.ticket_ids[] mirrors this set once OnTradeTransaction
   //    is wired; until then the platform-side loop is the canonical path.
   int total_positions = PositionsTotal();
   for(int i = 0; i < total_positions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      if(sym != _Symbol) continue;            // EURUSD whitelist (NFR-5.3)

      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double pl         = PositionGetDouble(POSITION_PROFIT);
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double cur_price  = (pt == POSITION_TYPE_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                          : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      total_pl += pl;

      //--- pip excursion (signed: positive = in-profit, negative = bad)
      double signed_pip = (pt == POSITION_TYPE_BUY)
                          ? (cur_price - open_price) / m_pip.PipToPrice(1.0)
                          : (open_price - cur_price) / m_pip.PipToPrice(1.0);

      if(signed_pip < 0.0)
        {
         weak_count++;
         sum_bad_pip += MathAbs(signed_pip);
        }
     }
  }

//+------------------------------------------------------------------+
//| _FillSafePortTargets — populate {magic, slot_prefix} table       |
//|   per BA `04 § BR-8.1` literal: {C,D,J,H,K,L,M,Q,GO,T,S}         |
//|   CD shared MAGIC_CD; both prefixes "C," and "D," yield distinct |
//|   ticket sets via PortfolioState.GetTicketsForSlot.              |
//+------------------------------------------------------------------+
int CCrossSlotCoordinator::_FillSafePortTargets(SafePortTarget &out[]) const
  {
   ArrayResize(out, 11);
   int n = 0;
   out[n].magic = MAGIC_CD; out[n].slot_prefix = "C,";  n++;
   out[n].magic = MAGIC_CD; out[n].slot_prefix = "D,";  n++;
   out[n].magic = MAGIC_J;  out[n].slot_prefix = "J,";  n++;
   out[n].magic = MAGIC_H;  out[n].slot_prefix = "H,";  n++;
   out[n].magic = MAGIC_K;  out[n].slot_prefix = "K,";  n++;
   out[n].magic = MAGIC_L;  out[n].slot_prefix = "L,";  n++;
   out[n].magic = MAGIC_M;  out[n].slot_prefix = "M,";  n++;
   out[n].magic = MAGIC_Q;  out[n].slot_prefix = "Q,";  n++;
   out[n].magic = MAGIC_GO; out[n].slot_prefix = "GO,"; n++;
   out[n].magic = MAGIC_T;  out[n].slot_prefix = "T,";  n++;
   out[n].magic = MAGIC_S;  out[n].slot_prefix = "S,";  n++;
   return n;
  }

//+------------------------------------------------------------------+
//| _CloseSlotGroup — close every ticket matching (magic, prefix)    |
//|                                                                  |
//| Returns count of close calls issued (CTrade.PositionClose may    |
//| still ack-fail; broker ack accounting belongs in Orchestrator's  |
//| OnTradeTransaction handler, not here).                           |
//+------------------------------------------------------------------+
int CCrossSlotCoordinator::_CloseSlotGroup(int magic, string slot_prefix)
  {
   if(m_portfolio == NULL) return 0;

   ulong tickets[];
   int n = m_portfolio.GetTicketsForSlot(magic, slot_prefix, tickets);
   if(n <= 0) return 0;

   int closed = 0;
   for(int i = 0; i < n; i++)
     {
      ulong tk = tickets[i];
      if(!PositionSelectByTicket(tk)) continue;

      double pl  = PositionGetDouble(POSITION_PROFIT);
      double lot = PositionGetDouble(POSITION_VOLUME);

      bool ok = m_trade.PositionClose(tk);
      if(!ok && m_logger != NULL)
        {
         m_logger.Warn("xslot", "safe_port_close_fail", magic,
                       StringFormat("ticket=%I64u rc=%u", tk, m_trade.ResultRetcode()));
        }
      closed++;

      //--- Per-ticket exit journal entry (triggering_function = OrderGroupStartWorkflow)
      if(m_journal != NULL)
        {
         JournalEvent ev;
         ev.timestamp_seconds      = TimeCurrent();
         ev.timestamp_microseconds = 0;
         ev.event_type             = "exit";
         ev.slot_id                = StringSubstr(slot_prefix, 0, StringLen(slot_prefix) - 1); // strip ","
         ev.magic                  = magic;
         ev.ticket_id              = tk;
         ev.symbol                 = _Symbol;
         ev.order_type             = "close";
         ev.lot                    = lot;
         ev.price                  = PositionGetDouble(POSITION_PRICE_CURRENT);
         ev.sl                     = 0.0;
         ev.tp                     = 0.0;
         ev.comment                = "safe_port";
         ev.signal_context         = StringFormat("pl=%.2f", pl);
         ev.triggering_function    = "OrderGroupStartWorkflow";
         ev.parent_ticket_id       = 0;
         ev.halt_reason            = "";
         ev.pending_age_bars       = 0;
         m_journal.WriteEvent(ev);
        }
     }
   return closed;
  }

//+------------------------------------------------------------------+
//| RunSafePort — BR-8.1 OrderGroupStartWorkflow                     |
//|                                                                  |
//| Returns slots_closed_count (S-AC #3). HALTED-allowed per         |
//| `04 § 9.1` matrix.                                               |
//+------------------------------------------------------------------+
int CCrossSlotCoordinator::RunSafePort(const MarketContext &ctx)
  {
   // Suppress unused-parameter warning under MQL5 strict mode — ctx will
   // be consumed when force_pattern derived signals land (P4 hardening).
   datetime t = ctx.tick_time; t = t;

   if(m_portfolio == NULL || m_logger == NULL) return 0;

   int    weak_count  = 0;
   double sum_bad_pip = 0.0;
   double total_pl    = 0.0;
   _AggregateWeakMetrics(weak_count, sum_bad_pip, total_pl);

   double avg_bad_pip = (weak_count > 0) ? (sum_bad_pip / weak_count) : 0.0;

   if(!_SafePortTriggered(weak_count, avg_bad_pip, total_pl))
      return 0;

   //--- Triggered — bulk close target slot set
   SafePortTarget targets[];
   int target_n = _FillSafePortTargets(targets);
   int slots_closed_count = 0;
   for(int i = 0; i < target_n; i++)
      slots_closed_count += _CloseSlotGroup(targets[i].magic, targets[i].slot_prefix);

   m_logger.Info("xslot", "safe_port_triggered", 0,
                 StringFormat("slots_closed=%d weak=%d avg_bad_pip=%.1f pl=%.2f halted=%s",
                              slots_closed_count, weak_count, avg_bad_pip, total_pl,
                              (m_halted ? "true" : "false")));

   return slots_closed_count;
  }

//+------------------------------------------------------------------+
//| Sibling stubs (TODO IMPL-054..057)                               |
//+------------------------------------------------------------------+
void CCrossSlotCoordinator::RunOrderGroup2(const MarketContext &ctx)
  {
   datetime t = ctx.tick_time; t = t;
   // TODO IMPL-054: BR-8.2 Ichimoku double-bounce close-all
  }

//+------------------------------------------------------------------+
//| _ForceCutlossSignal — BR-8.3 composite trigger                   |
//|                                                                  |
//| Per CodeWiki §5.5 :9009 baseline: Stochastic M10 K-vs-D cross    |
//| confirms reversal direction; MACD D1 histogram sign confirms     |
//| momentum alignment. AND-gate produces a tri-state signal that     |
//| dictates which directional CD positions to cut:                  |
//|   stoch_bear (K<D) AND macd_bear (hist<0) → +1 (cut BUY losses)  |
//|   stoch_bull (K>D) AND macd_bull (hist>0) → -1 (cut SELL losses) |
//|   anything else                          →  0 (no cut)           |
//+------------------------------------------------------------------+
int CCrossSlotCoordinator::_ForceCutlossSignal(const MarketContext &ctx) const
  {
   bool stoch_bear = (ctx.stoch_m10.k_main < ctx.stoch_m10.d_signal);
   bool stoch_bull = (ctx.stoch_m10.k_main > ctx.stoch_m10.d_signal);
   bool macd_bear  = (ctx.macd_d1.hist < 0.0);
   bool macd_bull  = (ctx.macd_d1.hist > 0.0);

   if(stoch_bear && macd_bear) return +1;
   if(stoch_bull && macd_bull) return -1;
   return 0;
  }

//+------------------------------------------------------------------+
//| _CloseCDPositionsInLoss — close direction-matched CD losers       |
//|                                                                  |
//| Iterates both shared-magic prefixes ("C," and "D,") under        |
//| MAGIC_CD; for each ticket: if in loss AND direction matches      |
//| signal → CTrade.PositionClose + journal "exit" with              |
//| triggering_function="ForceCutloss" (schema enum allowed).        |
//+------------------------------------------------------------------+
int CCrossSlotCoordinator::_CloseCDPositionsInLoss(int signal)
  {
   if(m_portfolio == NULL) return 0;
   if(signal != +1 && signal != -1) return 0;

   string prefixes[2];
   prefixes[0] = "C,";
   prefixes[1] = "D,";

   int closed = 0;
   for(int p = 0; p < 2; p++)
     {
      ulong tickets[];
      int n = m_portfolio.GetTicketsForSlot(MAGIC_CD, prefixes[p], tickets);
      for(int i = 0; i < n; i++)
        {
         ulong tk = tickets[i];
         if(!PositionSelectByTicket(tk)) continue;

         double pl = PositionGetDouble(POSITION_PROFIT);
         if(pl >= 0.0) continue;          // BR-8.3: only positions in loss

         ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         bool is_buy = (pt == POSITION_TYPE_BUY);
         if(is_buy  && signal != +1) continue;
         if(!is_buy && signal != -1) continue;

         double lot = PositionGetDouble(POSITION_VOLUME);
         bool ok = m_trade.PositionClose(tk);
         if(!ok && m_logger != NULL)
           {
            m_logger.Warn("xslot", "force_cutloss_close_fail", MAGIC_CD,
                          StringFormat("ticket=%I64u rc=%u", tk, m_trade.ResultRetcode()));
           }
         closed++;

         if(m_journal != NULL)
           {
            JournalEvent ev;
            ev.timestamp_seconds      = TimeCurrent();
            ev.timestamp_microseconds = 0;
            ev.event_type             = "exit";
            ev.slot_id                = StringSubstr(prefixes[p], 0, StringLen(prefixes[p]) - 1);
            ev.magic                  = MAGIC_CD;
            ev.ticket_id              = tk;
            ev.symbol                 = _Symbol;
            ev.order_type             = "close";
            ev.lot                    = lot;
            ev.price                  = PositionGetDouble(POSITION_PRICE_CURRENT);
            ev.sl                     = 0.0;
            ev.tp                     = 0.0;
            ev.comment                = "force_cutloss";
            ev.signal_context         = StringFormat("pl=%.2f signal=%d", pl, signal);
            ev.triggering_function    = "ForceCutloss";
            ev.parent_ticket_id       = 0;
            ev.halt_reason            = "";
            ev.pending_age_bars       = 0;
            m_journal.WriteEvent(ev);
           }
        }
     }
   return closed;
  }

//+------------------------------------------------------------------+
//| RunForceCutloss — BR-8.3 CD-only loss-cap                        |
//|                                                                  |
//| HALTED-allowed per `04 § 9.1` matrix (exit-side helper).         |
//| Pipeline order (TD-02 §7.2 step 9): runs BEFORE Safe-port so     |
//| direction-aware tactical close happens before bulk cleanup.      |
//+------------------------------------------------------------------+
void CCrossSlotCoordinator::RunForceCutloss(const MarketContext &ctx)
  {
   if(m_portfolio == NULL || m_logger == NULL) return;

   int signal = _ForceCutlossSignal(ctx);
   if(signal == 0) return;

   int closed = _CloseCDPositionsInLoss(signal);
   if(closed <= 0) return;

   m_logger.Info("xslot", "force_cutloss_triggered", MAGIC_CD,
                 StringFormat("closed=%d signal=%d halted=%s",
                              closed, signal,
                              (m_halted ? "true" : "false")));
  }

void CCrossSlotCoordinator::ExtraCheckFunction2()
  {
   // TODO IMPL-056: BR-8.5 CD demote check
  }

void CCrossSlotCoordinator::RunCOverload(const MarketContext &ctx)
  {
   datetime t = ctx.tick_time; t = t;
   // TODO IMPL-057: BR-8.4 COverload exit-side (allowed in HALTED per `04 § 9.1`)
  }

void CCrossSlotCoordinator::RunEOverload(const MarketContext &ctx)
  {
   if(m_halted)
     {
      if(m_logger != NULL)
         m_logger.Info("xslot", "overload_skipped_halted", 0, "helper=E");
      return;
     }
   datetime t = ctx.tick_time; t = t;
   // TODO IMPL-057: BR-8.4 EOverload entry-side
  }

void CCrossSlotCoordinator::TriggerGOverload(double closing_lot, int direction)
  {
   if(m_halted)
     {
      if(m_logger != NULL)
         m_logger.Info("xslot", "overload_skipped_halted", 0, "helper=G");
      return;
     }
   closing_lot = closing_lot; direction = direction;
   // TODO IMPL-057: BR-8.4 GOverload post-exit hook
  }

void CCrossSlotCoordinator::EvaluateBR_OrphanExit()
  {
   // TODO IMPL-038/057: BR-2.1 B → BR orphan-exit hook
  }

//+------------------------------------------------------------------+
//| SelfTest — inline G1 spike harness                               |
//+------------------------------------------------------------------+
bool CCrossSlotCoordinator::SelfTest(CLogger *logger)
  {
   //--- Case 1: Init() defaults
   if(m_halted != false) { Print("[xslot] SelfTest C1 FAIL halted default"); return false; }

   //--- Case 2: SetHalted toggle round-trip
   SetHalted(true);
   if(!IsHalted()) { Print("[xslot] SelfTest C2 FAIL halted setter"); return false; }
   SetHalted(false);
   if(IsHalted())  { Print("[xslot] SelfTest C2 FAIL halted unsetter"); return false; }

   //--- Case 3: _SafePortTriggered all-zero → false
   if(_SafePortTriggered(0, 0.0, 0.0))
     { Print("[xslot] SelfTest C3 FAIL trigger zero"); return false; }

   //--- Case 4: _SafePortTriggered weak=2 avg=60 pl=10 → true
   if(!_SafePortTriggered(2, 60.0, 10.0))
     { Print("[xslot] SelfTest C4 FAIL trigger pos"); return false; }

   //--- Case 5: _SafePortTriggered weak=2 avg=40 pl=10 → false (gate fail)
   if(_SafePortTriggered(2, 40.0, 10.0))
     { Print("[xslot] SelfTest C5 FAIL low pip"); return false; }

   //--- Case 6: _SafePortTriggered weak=2 avg=60 pl=-5 → false (negative pl)
   if(_SafePortTriggered(2, 60.0, -5.0))
     { Print("[xslot] SelfTest C6 FAIL neg pl"); return false; }

   //--- Case 7: _FillSafePortTargets returns 11 entries (CD x2 + 9 unique)
   SafePortTarget targets[];
   int n = _FillSafePortTargets(targets);
   if(n != 11) { Print("[xslot] SelfTest C7 FAIL target count=" + IntegerToString(n)); return false; }
   if(targets[0].magic != MAGIC_CD || targets[0].slot_prefix != "C,")
     { Print("[xslot] SelfTest C7 FAIL slot[0]"); return false; }
   if(targets[10].magic != MAGIC_S || targets[10].slot_prefix != "S,")
     { Print("[xslot] SelfTest C7 FAIL slot[10]"); return false; }

   //--- BR-8.3 ForceCutloss signal truth-table (IMPL-055)
   //    stoch_bear (K<D) + macd_bear (hist<0) → +1 cut BUY
   //    stoch_bull (K>D) + macd_bull (hist>0) → -1 cut SELL
   //    mismatch / flat                       →  0 no cut
   MarketContext ctx;
   ctx.tick_time = 0; ctx.bid = 0; ctx.ask = 0; ctx.spread_pip = 0; ctx.bar_index_h4 = 0;

   //--- Case 8: stoch K<D + macd hist<0 → +1 (cut BUY losses)
   ctx.stoch_m10.k_main = 20.0; ctx.stoch_m10.d_signal = 50.0;
   ctx.macd_d1.hist = -0.5;
   if(_ForceCutlossSignal(ctx) != +1)
     { Print("[xslot] SelfTest C8 FAIL force_cut bear"); return false; }

   //--- Case 9: stoch K>D + macd hist>0 → -1 (cut SELL losses)
   ctx.stoch_m10.k_main = 80.0; ctx.stoch_m10.d_signal = 50.0;
   ctx.macd_d1.hist = 0.5;
   if(_ForceCutlossSignal(ctx) != -1)
     { Print("[xslot] SelfTest C9 FAIL force_cut bull"); return false; }

   //--- Case 10: mismatch (stoch bear + macd bull) → 0
   ctx.stoch_m10.k_main = 20.0; ctx.stoch_m10.d_signal = 50.0;
   ctx.macd_d1.hist = 0.5;
   if(_ForceCutlossSignal(ctx) != 0)
     { Print("[xslot] SelfTest C10 FAIL force_cut mismatch"); return false; }

   //--- Case 11: K==D + hist==0 → 0 (neither bear nor bull qualifies)
   ctx.stoch_m10.k_main = 50.0; ctx.stoch_m10.d_signal = 50.0;
   ctx.macd_d1.hist = 0.0;
   if(_ForceCutlossSignal(ctx) != 0)
     { Print("[xslot] SelfTest C11 FAIL force_cut flat"); return false; }

   //--- Case 12: _CloseCDPositionsInLoss with NULL portfolio → 0 (safe guard)
   if(_CloseCDPositionsInLoss(+1) != 0)
     { Print("[xslot] SelfTest C12 FAIL close_cd null_portfolio"); return false; }

   //--- Case 13: _CloseCDPositionsInLoss with signal=0 → 0 (no-op)
   if(_CloseCDPositionsInLoss(0) != 0)
     { Print("[xslot] SelfTest C13 FAIL close_cd zero_signal"); return false; }

   if(logger != NULL)
      logger.Info("xslot", "selftest_ok", 0, "13/13 cases pass");
   Print("[xslot] SelfTest 13/13 PASS");
   return true;
  }

#endif // PHOENICISNEX_SERVICES_CROSSSLOTCOORDINATOR_MQH
