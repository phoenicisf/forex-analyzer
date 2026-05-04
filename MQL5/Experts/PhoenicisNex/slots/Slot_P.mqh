//+------------------------------------------------------------------+
//| slots/Slot_P.mqh — Slot P implementation (IMPL-034)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_P = 218                                            |
//| Source:  CodeWiki §3.14 Slot P + §2.5 P_Extra; `04 § 4.4`;        |
//|          BR-6.4 (P legacy timeout); ADR-002; ADR-012.             |
//|                                                                   |
//| ⚠️ A7 risk note: E/N sub-mode semantic + transition rules verified|
//|    against `04 § 4.4` (`docs/design-docs/04-data-flow.md`):       |
//|       PSUB_N  = transient — mode-decision branch unresolved       |
//|       PSUB_PX = Force fast-path (Force[1] > 0.1 AND diff_sl ≥ 200)|
//|       PSUB_PH = Hull/Bollinger default (diff_sl < 200)            |
//|       PSUB_E  = Pyramid extension (P_Extra; comment "PI,...")     |
//|    Lock-once semantic: once sub_mode in {PX,PH,E}, ห้าม flip.      |
//|    Advanced trigger filters (CodeWiki §3.14 Hull structure /      |
//|    recent-bar trigger lookback / band gating extremes / Fibonacci |
//|    pyramid lot calc) deferred to P4 IMPL-062.                     |
//|                                                                   |
//| P-Pending uses legacy timeout (InpLegacyPBars = 70 H4 bars; BR-6.4)|
//|   no ADR-008 force-clear — PMR.TickAll (Orchestrator step 8) owns |
//|   timeout logic.                                                  |
//|                                                                   |
//| L-size MVP — 4 of N CodeWiki §3.14 entry conditions:              |
//|   1. No active P orders ("P," prefix excluding "PI,")             |
//|   2. ADX H4 dominance: adx > InpPAdxMin                           |
//|   3. Bollinger boundary touch: BUY if bb_ratio ≤ 20, SELL if ≥ 80 |
//|   4. DI directional bias: di_plus > di_minus (BUY) or vice-versa  |
//|                                                                   |
//| Sub-mode decision branch (PENDING phase, sub_mode == N):          |
//|   PX  if (force_h4.f1 magnitude > InpPForcePxGate                 |
//|             AND diff_sl_pip   ≥ InpPDiffSlPxThreshold)            |
//|   PH  otherwise                                                   |
//|                                                                   |
//| Pyramid E path (own P active + parent profit gate met):           |
//|   IDLE + own_P_active + parent profit_pips ≥ InpPPyramidGatePips  |
//|     → direct OrderSend with comment "PI,MA,E,1,SL" (bypass PMR)   |
//|                                                                   |
//| Comment format per `04 § 4.4`:                                    |
//|   "P,MA,PX,1,SL"  — PX entry                                       |
//|   "P,MA,PH,1,SL"  — PH entry                                       |
//|   "PI,MA,E,1,SL"  — E pyramid extension entry                     |
//|                                                                   |
//| Lot: m_risk.ComputeLot("P", sl_pips, balance) — sub-mode-agnostic |
//|       (per-extension Fibonacci formula deferred to P4 IMPL-062)   |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                               |
//|   ห้าม #include "services/Logger.mqh" direct (injected)           |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_P_MQH
#define PHOENICISNEX_SLOTS_SLOT_P_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_P.mqh"

//+------------------------------------------------------------------+
//| CSlotP — Slot P derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses P-Pending state machine (PM_P) with legacy timeout to gate   |
//| primary entries; pyramid extension (E) bypasses PMR (depends on   |
//| existing parent P position). Sub-mode decision branch resolves    |
//| during PENDING phase using lock-once semantic.                    |
//+------------------------------------------------------------------+
class CSlotP : public CSlotBase
  {
private:
   //--- Private helpers
   bool              _HasActivePOrder(CPortfolioState &port, ulong &out_tickets[]) const;
   bool              _HasActivePIOrder(CPortfolioState &port) const;
   bool              _IsPBuyBaseSignal(const MarketContext &ctx) const;
   bool              _IsPSellBaseSignal(const MarketContext &ctx) const;
   bool              _IsPTriggerValid(const MarketContext &ctx, bool isBuy) const;
   bool              _ParentProfitPipsAtLeast(CPortfolioState &port, double gate_pips,
                                              bool &out_isBuy, double &out_parent_open) const;
   double            _ComputeDiffSlPip(const MarketContext &ctx) const;
   EPSubMode         _ResolvePSubMode(const MarketContext &ctx, double diff_sl_pip) const;
   double            _TpPipsForSubMode(const string &comment) const;

public:
   //--- Constructor / Destructor
   CSlotP() {}
   virtual ~CSlotP() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_P = 218
   virtual int           Magic()  const override { return MAGIC_P; }

   //--- 2. SlotId — "P"; used by journal slot_id field + comment prefix "P," / "PI,"
   virtual string        SlotId() const override { return "P"; }

   //--- 3. Evaluate — entry pass with P-Pending sub-mode resolution
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — P is topologically independent; PMR dep is shared service.
   //       Pyramid path consumes own portfolio state at runtime (not topology).
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_P);
     }
  };

//+------------------------------------------------------------------+
//| _HasActivePOrder — own primary "P," tickets (excludes "PI,")      |
//|                                                                   |
//| StringFind("P,", "PI,...") → matches at i=0 then mismatches at    |
//| i=1 (',' vs 'I'); GetTicketsForSlot uses startsWith semantic so   |
//| we must filter "PI," explicitly post-call to avoid double-counting|
//| in pyramid scenario (precedent: Slot_BI.mqh line 89-95).          |
//+------------------------------------------------------------------+
bool CSlotP::_HasActivePOrder(CPortfolioState &port, ulong &out_tickets[]) const
  {
   ulong all_tickets[];
   int n = port.GetTicketsForSlot(MAGIC_P, "P,", all_tickets);
   ArrayResize(out_tickets, 0);
   if(n <= 0) return false;
   //--- Filter out "PI," tickets — match against position comment via Select
   int kept = 0;
   for(int i = 0; i < n; i++)
     {
      if(!PositionSelectByTicket(all_tickets[i])) continue;
      string c = PositionGetString(POSITION_COMMENT);
      if(StringFind(c, "PI,") == 0) continue;        // pyramid extension — skip
      ArrayResize(out_tickets, kept + 1);
      out_tickets[kept] = all_tickets[i];
      kept++;
     }
   return (kept > 0);
  }

//+------------------------------------------------------------------+
//| _HasActivePIOrder — own pyramid "PI," tickets only                |
//+------------------------------------------------------------------+
bool CSlotP::_HasActivePIOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_P, "PI,", tickets);
   return (n > 0);
  }

//+------------------------------------------------------------------+
//| _IsPBuyBaseSignal — base BUY pending signal                       |
//|   ADX dominance + bb_ratio low (price near lower band) + DI bull  |
//+------------------------------------------------------------------+
bool CSlotP::_IsPBuyBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok = ctx.adx_h4.adx > InpPAdxMin;
   bool bb_ok  = ctx.bb_h4.bb_ratio <= 20.0;          // near lower band
   bool di_ok  = ctx.adx_h4.di_plus > ctx.adx_h4.di_minus;
   return adx_ok && bb_ok && di_ok;
  }

//+------------------------------------------------------------------+
//| _IsPSellBaseSignal — mirror BUY                                   |
//+------------------------------------------------------------------+
bool CSlotP::_IsPSellBaseSignal(const MarketContext &ctx) const
  {
   bool adx_ok = ctx.adx_h4.adx > InpPAdxMin;
   bool bb_ok  = ctx.bb_h4.bb_ratio >= 80.0;          // near upper band
   bool di_ok  = ctx.adx_h4.di_minus > ctx.adx_h4.di_plus;
   return adx_ok && bb_ok && di_ok;
  }

//+------------------------------------------------------------------+
//| _IsPTriggerValid — pending trigger: price retraced toward bb_mid  |
//|                                                                   |
//| Phase B trigger: after IDLE→PENDING (price was near band edge),   |
//| trigger fires when bb_ratio crosses back toward middle band       |
//| (BUY: ratio ≥ 30; SELL: ratio ≤ 70) confirming retracement.       |
//+------------------------------------------------------------------+
bool CSlotP::_IsPTriggerValid(const MarketContext &ctx, bool isBuy) const
  {
   if(ctx.adx_h4.adx <= InpPAdxMin) return false;
   if(isBuy) return (ctx.bb_h4.bb_ratio >= 30.0 &&
                     ctx.adx_h4.di_plus > ctx.adx_h4.di_minus);
   return (ctx.bb_h4.bb_ratio <= 70.0 &&
           ctx.adx_h4.di_minus > ctx.adx_h4.di_plus);
  }

//+------------------------------------------------------------------+
//| _ComputeDiffSlPip — proxy for `_diffSL` per `04 § 4.4`             |
//|                                                                   |
//| MVP proxy: Bollinger band width in pip units.                     |
//| Wide band (≥ InpPDiffSlPxThreshold pip) → PX express path; tight  |
//| band → PH default. CodeWiki §3.14 advanced calc deferred IMPL-062.|
//+------------------------------------------------------------------+
double CSlotP::_ComputeDiffSlPip(const MarketContext &ctx) const
  {
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return 0.0;
   double width = ctx.bb_h4.bb_top - ctx.bb_h4.bb_bot;
   if(width < 0.0) width = 0.0;
   return width / pip_size;
  }

//+------------------------------------------------------------------+
//| _ResolvePSubMode — sub-mode decision branch (lock-once semantic) |
//|                                                                   |
//| PX  if (|f1| > InpPForcePxGate AND diff_sl_pip ≥ InpPDiffSlPxThreshold) |
//| PH  otherwise                                                     |
//| (E is decided up-front by caller, never resolved here.)           |
//+------------------------------------------------------------------+
EPSubMode CSlotP::_ResolvePSubMode(const MarketContext &ctx, double diff_sl_pip) const
  {
   double f1_abs = MathAbs(ctx.force_h4.f1);
   if(f1_abs > InpPForcePxGate && diff_sl_pip >= InpPDiffSlPxThreshold)
      return PSUB_PX;
   return PSUB_PH;
  }

//+------------------------------------------------------------------+
//| _ParentProfitPipsAtLeast — check own primary P parent profit gate |
//|                                                                   |
//| Used by E (pyramid extension) path. Selects earliest-opened "P,"  |
//| ticket (FIFO via PortfolioState.parent_tickets order) and returns |
//| true iff its unrealized profit ≥ gate_pips. Direction inherits    |
//| from parent (BUY parent → BUY pyramid).                           |
//+------------------------------------------------------------------+
bool CSlotP::_ParentProfitPipsAtLeast(CPortfolioState &port, double gate_pips,
                                      bool &out_isBuy, double &out_parent_open) const
  {
   out_isBuy       = true;
   out_parent_open = 0.0;
   ulong parents[];
   if(!_HasActivePOrder(port, parents)) return false;
   if(ArraySize(parents) <= 0)         return false;

   ulong parent_ticket = parents[0];
   if(!PositionSelectByTicket(parent_ticket)) return false;

   ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
   double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                   SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                   SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double pip_size    = _PipSize();
   if(pip_size <= 0.0) return false;
   double profit_pips = (pos_type == POSITION_TYPE_BUY)
                        ? (cur_price - open_price) / pip_size
                        : (open_price - cur_price) / pip_size;

   out_isBuy       = (pos_type == POSITION_TYPE_BUY);
   out_parent_open = open_price;
   return (profit_pips >= gate_pips);
  }

//+------------------------------------------------------------------+
//| _TpPipsForSubMode — pick exit profit gate from comment sub-mode   |
//|                                                                   |
//| Comment format per `04 § 4.4`:                                    |
//|   "P,MA,PX,..." → InpPTpPipsPx                                    |
//|   "P,MA,PH,..." → InpPTpPipsPh                                    |
//|   "PI,MA,E,..." → InpPTpPipsE                                     |
//| Default (legacy/unknown comment) → InpPTpPipsPh (PH baseline).    |
//+------------------------------------------------------------------+
double CSlotP::_TpPipsForSubMode(const string &comment) const
  {
   if(StringFind(comment, "PI,") == 0)        return InpPTpPipsE;
   if(StringFind(comment, ",PX,") >= 0)       return InpPTpPipsPx;
   if(StringFind(comment, ",PH,") >= 0)       return InpPTpPipsPh;
   return InpPTpPipsPh;                       // safe default
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot P entry pass with sub-mode resolution             |
//|                                                                   |
//| Path A — Pyramid extension (E sub-mode, bypass PMR):              |
//|   IDLE + own_P_active + parent profit_pips ≥ InpPPyramidGatePips  |
//|     → direct OrderSend "PI,MA,E,1,SL" (Slot_LX/Slot_BI precedent) |
//|                                                                   |
//| Path B — Primary P-Pending lifecycle:                             |
//|   IDLE + base signal (no own P) → EnterPPending(PSUB_N, ...)      |
//|   PENDING + sub_mode == N      → resolve PX/PH (lock-once)        |
//|   PENDING + sub_mode in {PX,PH} + trigger valid → OrderSend       |
//|                                  + TransitionExecuted             |
//|   Legacy timeout (70 H4 bars; BR-6.4): handled by PMR.TickAll     |
//|                                  in Orchestrator step 8.          |
//|                                                                   |
//| NOTE: All OrderSend submissions are Phase-1 stubs — actual        |
//|       broker call deferred to IMPL-053+ Orchestrator wiring per   |
//|       slot precedent (Slot_R IMPL-033 + sibling slots).           |
//+------------------------------------------------------------------+
void CSlotP::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotP) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Path A: Pyramid extension (PSUB_E) — bypass PMR
   //    Triggered when own primary P parent profit gate is met. One pyramid
   //    at a time (own "PI," guard).
   if(!_HasActivePIOrder(port))
     {
      bool   parent_isBuy = true;
      double parent_open  = 0.0;
      if(_ParentProfitPipsAtLeast(port, InpPPyramidGatePips, parent_isBuy, parent_open))
        {
         //--- Compute pyramid SL: parent open ± fallback floor.
         //    Use canonical _PipsToPrice helper (Round 06 06.1 collapse) so
         //    pip arithmetic stays at one site; guard ≤ 0 per NFR-5.1
         //    surfacing — symmetric with ManageExits guard (review-round-07
         //    Finding 07.5; review-round-08 Finding 08.1 + 08.2).
         double sl_pips = InpPSlPipsFloor;
         double sl_dist = _PipsToPrice(sl_pips);
         if(sl_dist <= 0.0)
           {
            m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                           "Path A pyramid aborted — _PipsToPrice returned ≤ 0 (NFR-5.1 surfacing)");
            return;   // Don't fall through to Path B; symbol metric corrupt this tick.
           }
         double price    = parent_isBuy ? ctx.ask : ctx.bid;
         double sl_price = parent_isBuy
                           ? _NormalizeBrokerPrice(price - sl_dist)
                           : _NormalizeBrokerPrice(price + sl_dist);

         double balance = AccountInfoDouble(ACCOUNT_BALANCE);
         double lot     = m_risk.ComputeLot("P", sl_pips, balance);
         if(lot <= 0.0)
           {
            m_logger.Warn("SlotP", "zero_lot_skip_pyramid", MAGIC_P,
                          "ComputeLot returned 0 — skipping E pyramid entry");
           }
         else
           {
            //--- fix-round-12 § 12.8 — Phase 1 emits entry_signal_pyramid
            //    Logger.Info as the observable milestone; actual OrderSend
            //    lives in `RiskManager::OpenOrder` per `.claude/rules/ea.md`
            //    (IMPL-017 + IMPL-062 5-yr regression). Slot_BI / Slot_R
            //    follow the same pattern. (review-round-07 Finding 07.4)
            string comment = "PI,MA,E,1,SL";
            string dir_str = parent_isBuy ? "BUY" : "SELL";
            m_logger.Info("SlotP", "entry_signal_pyramid", MAGIC_P,
                          StringFormat("sub_mode=E dir=%s lot=%.2f sl_pips=%.1f "
                                       "price=%.5f sl=%.5f comment=%s parent_open=%.5f "
                                       "(Phase 1 logger-only; OrderSend at IMPL-017/IMPL-062)",
                                       dir_str, lot, sl_pips, price, sl_price,
                                       comment, parent_open));
           }
         //--- Pyramid path complete this tick — primary lifecycle still runs below
        }
     }

   //--- Path B: Primary P-Pending lifecycle (only when no own primary P)
   ulong own_p[];
   if(_HasActivePOrder(port, own_p)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   EPendingState st = m_pending.GetState(PM_P);

   //--- Phase A: IDLE — check base signal, enter pending with PSUB_N
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsPBuyBaseSignal(ctx);
      bool sellBase = _IsPSellBaseSignal(ctx);
      if(!buyBase && !sellBase) return;

      double diff_sl_pip = _ComputeDiffSlPip(ctx);
      double band_ratio  = ctx.bb_h4.bb_ratio;

      //--- Reject degenerate diff_sl_pip (≤ 0): the signed-diff_sl encoding
      //    cannot disambiguate +0.0 vs −0.0 (IEEE 754 `(-0.0 >= 0.0)` is
      //    true), so SELL with diff_sl_pip == 0 would round-trip as BUY.
      //    Skip pending entry this tick instead of corrupting direction.
      //    (review-round-08 Finding 08.4)
      if(diff_sl_pip <= 0.0)
        {
         m_logger.Warn("SlotP", "skip_idle_zero_diff_sl", MAGIC_P,
                       StringFormat("diff_sl_pip=%.4f bb_top=%.5f bb_bot=%.5f — pending skipped",
                                    diff_sl_pip, ctx.bb_h4.bb_top, ctx.bb_h4.bb_bot));
         return;
        }

      //--- Direction encoded via signed diff_sl (BUY ≥ 0, SELL < 0) per
      //    state-persistence-schema.yaml § PendingMachineState_PVariant
      //    diff_sl sign convention. Stays within canonical 3-field payload.
      //    (review-round-07 Finding 07.1 Option A + 07.2 EnterPPending helper)
      double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
      m_pending.EnterPPending(PSUB_N, signed_diff_sl, band_ratio, ctx.bar_index_h4);

      m_logger.Info("SlotP", "pending_entered", MAGIC_P,
                    StringFormat("dir=%s sub_mode=N diff_sl_pip=%.1f band_ratio=%.1f bar=%d",
                                 (buyBase ? "BUY" : "SELL"),
                                 diff_sl_pip, band_ratio, ctx.bar_index_h4));
      return;
     }

   //--- Phase B: PENDING — resolve sub-mode if N, then check trigger
   if(st == PENDING_STATE_PENDING)
     {
      EPSubMode sub          = m_pending.GetPSubMode();
      double    signed_ds    = m_pending.GetPDiffSL();
      double    diff_sl_abs  = MathAbs(signed_ds);
      bool      isBuy        = (signed_ds >= 0.0);
      double    band_rat     = m_pending.GetPBandRatio();

      //--- Sub-mode resolution (lock-once): N → PX or PH
      if(sub == PSUB_N || sub == PSUB_NONE)
        {
         EPSubMode resolved = _ResolvePSubMode(ctx, diff_sl_abs);
         string mode_str    = (resolved == PSUB_PX) ? "PX" : "PH";

         //--- Mutate payload only — must NOT reset pending_started_bar:
         //    BR-6.4 70-bar legacy timeout window keeps ticking from the
         //    original IDLE→PENDING bar. Sub-mode lock is an internal
         //    payload mutation, not a timeout-relevant transition.
         //    (review-round-07 Finding 07.3 + canonical helper per 07.2)
         m_pending.OverwritePPayload(resolved, signed_ds, band_rat);
         sub = resolved;

         m_logger.Info("SlotP", "submode_locked", MAGIC_P,
                       StringFormat("sub_mode=%s diff_sl_pip=%.1f band_ratio=%.1f",
                                    mode_str, diff_sl_abs, band_rat));
         //--- Continue this tick to evaluate trigger with new sub-mode.
        }

      //--- Trigger gate
      if(!_IsPTriggerValid(ctx, isBuy)) return;

      //--- Compute SL distance: PX uses |diff_sl| from payload (snapshot at IDLE);
      //    PH uses input floor (default conservative).
      //    Use canonical _PipsToPrice helper (Round 06 06.1 collapse); guard
      //    ≤ 0 per NFR-5.1 surfacing — symmetric with ManageExits guard
      //    (review-round-07 Finding 07.5; review-round-08 Finding 08.1 + 08.2).
      double sl_pips = (sub == PSUB_PX) ? diff_sl_abs : InpPSlPipsFloor;
      if(sl_pips < InpPSlPipsFloor) sl_pips = InpPSlPipsFloor;   // floor guard
      double sl_dist = _PipsToPrice(sl_pips);
      if(sl_dist <= 0.0)
        {
         m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                        StringFormat("_PipsToPrice(%.1f) returned %.10f — primary entry "
                                     "aborted; symbol metric corrupt (NFR-5.1 surfacing)",
                                     sl_pips, sl_dist));
         Alert("[PhoenicisNex] Slot_P degenerate _PipSize() — primary entry aborted");
         return;
        }

      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("P", sl_pips, balance);
      if(lot <= 0.0)
        {
         m_logger.Warn("SlotP", "zero_lot_skip", MAGIC_P,
                       "ComputeLot returned 0 — skipping P entry");
         return;
        }

      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(price - sl_dist)
                        : _NormalizeBrokerPrice(price + sl_dist);

      string sub_str = (sub == PSUB_PX) ? "PX" : "PH";
      string comment = StringFormat("P,MA,%s,1,SL", sub_str);

      //--- fix-round-12 § 12.8 — Phase 1 emits entry_signal Logger.Info as
      //    the observable milestone; actual OrderSend lives in
      //    `RiskManager::OpenOrder` per `.claude/rules/ea.md` (IMPL-017 +
      //    IMPL-062 5-yr regression). Slot_BI / Slot_R follow the same
      //    pattern. (review-round-07 Finding 07.4)
      m_logger.Info("SlotP", "entry_signal", MAGIC_P,
                    StringFormat("sub_mode=%s dir=%s lot=%.2f sl_pips=%.1f "
                                 "price=%.5f sl=%.5f comment=%s "
                                 "(Phase 1 logger-only; OrderSend at IMPL-017/IMPL-062)",
                                 sub_str, (isBuy ? "BUY" : "SELL"), lot, sl_pips,
                                 price, sl_price, comment));

      m_pending.TransitionExecuted(PM_P);
     }

   //--- Phase C: EXECUTED — entry placed; PMR.TickAll resets to IDLE.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot P exit pass with sub-mode-aware profit gate    |
//|                                                                   |
//| Iterates own P + PI tickets, picks profit-gate pip threshold via  |
//| comment 3rd CSV field ("PX"/"PH"/"E"), emits exit_profit_gate     |
//| log-intent on threshold breach. Real OrderClose deferred to       |
//| Orchestrator wiring (IMPL-053+).                                  |
//+------------------------------------------------------------------+
void CSlotP::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- "P," and "PI," need separate GetTicketsForSlot calls — startsWith
   //    semantic excludes "PI," from "P," prefix-match (comment[1]='I'≠',').
   ulong tickets_p[];
   int n_p = port.GetTicketsForSlot(MAGIC_P, "P,", tickets_p);
   ulong tickets_pi[];
   int n_pi = port.GetTicketsForSlot(MAGIC_P, "PI,", tickets_pi);

   //--- Loud failure on degenerate symbol metric — exit pass aborted while
   //    open positions remain unmanaged is a halt-class condition per NFR-5.1.
   //    (review-round-07 Finding 07.5)
   double pip_size = _PipSize();
   if(pip_size <= 0.0)
     {
      m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                     StringFormat("_PipSize() returned %.10f — exit pass aborted; "
                                  "symbol metric corrupt (NFR-5.1 surfacing)", pip_size));
      Alert("[PhoenicisNex] Slot_P degenerate _PipSize() — exit pass aborted");
      return;
     }

   //--- Process "P," tickets (PX/PH primary entries)
   for(int i = 0; i < n_p; i++)
     {
      ulong ticket = tickets_p[i];
      if(!PositionSelectByTicket(ticket)) continue;

      string c = PositionGetString(POSITION_COMMENT);

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double profit_pips = (pos_type == POSITION_TYPE_BUY)
                           ? (cur_price - open_price) / pip_size
                           : (open_price - cur_price) / pip_size;

      double gate = _TpPipsForSubMode(c);
      if(profit_pips >= gate)
        {
         m_logger.Info("SlotP", "exit_profit_gate", MAGIC_P,
                       StringFormat("ticket=%I64u comment=%s profit_pips=%.1f "
                                    ">= gate=%.1f → close",
                                    ticket, c, profit_pips, gate));
         //--- Phase-1 stub: OrderClose deferred to Orchestrator wiring.
        }
     }

   //--- Process "PI," tickets (E pyramid extensions) — separate gate
   for(int i = 0; i < n_pi; i++)
     {
      ulong ticket = tickets_pi[i];
      if(!PositionSelectByTicket(ticket)) continue;

      ENUM_POSITION_TYPE pos_type   = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double             open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double             cur_price  = (pos_type == POSITION_TYPE_BUY) ?
                                      SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                      SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double profit_pips = (pos_type == POSITION_TYPE_BUY)
                           ? (cur_price - open_price) / pip_size
                           : (open_price - cur_price) / pip_size;

      if(profit_pips >= InpPTpPipsE)
        {
         m_logger.Info("SlotP", "exit_profit_gate_pyramid", MAGIC_P,
                       StringFormat("ticket=%I64u sub_mode=E profit_pips=%.1f "
                                    ">= gate=%.1f → close",
                                    ticket, profit_pips, InpPTpPipsE));
         //--- Phase-1 stub: OrderClose deferred to Orchestrator wiring.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_P_MQH
