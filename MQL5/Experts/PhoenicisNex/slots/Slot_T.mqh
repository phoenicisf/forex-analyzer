//+------------------------------------------------------------------+
//| slots/Slot_T.mqh — Slot T implementation (IMPL-035)              |
//| Layer:   slots/ (inherits domain/CSlotBase; ADR-002 contract)     |
//| Magic:   MAGIC_T = 219                                            |
//| Source:  CodeWiki §3.15 Slot T; ADR-002; ADR-008 (OQ-A3); ADR-012 |
//|                                                                   |
//| IMPL-FIX-011 Session C rewrite (2026-05-10) — replaces M-size MVP |
//| (3-condition MACD/ADX/Stoch) with §3.15 4-sub-path predicate per   |
//| empirically falsified Step 4 iter-2 finding (T/entry |Δ|=3 of 4   |
//| legacy trigger varieties; 1 of 4 hit). Sub-paths:                  |
//|   1. BUY support-zone × DEM≥0.45 ("D" sub-path)                   |
//|   2. BUY support-zone × DEM<0.45 ("H" sub-path; Hull-anchored)    |
//|   3. SELL resistance-zone × DEM≥0.45 ("D" sub-path)               |
//|   4. SELL resistance-zone × DEM<0.45 ("H" sub-path)               |
//|                                                                   |
//| Entry conditions (per CodeWiki §3.15 BUY support-zone path; SELL  |
//| mirrors with BollBand% > InpTBollBandPctSell):                     |
//|   1. No active T orders (magic 219, "T," prefix)                  |
//|   2. (Phase A IDLE) base signal: zone present + BollBand% < 5%    |
//|   3. (Phase A IDLE) Price > Hull MA (BUY) / < Hull MA (SELL)      |
//|   4. (Phase A IDLE) ≥7 of last 10 bars BBTop < IchiMax (BUY)      |
//|      mirror BBBot > IchiMin (SELL)                                |
//|   5. (Phase A IDLE) ADX H4 dominance: adx > InpTAdxMin             |
//|   6. (Phase B PENDING) trigger: same conditions still hold         |
//|      + DEM gate (D sub-path: dem ≥ 0.45 / H sub-path: dem < 0.45) |
//|   7. SL = max(BBWidth, hull-distance, InpTSlPipsCodeWikiFloor=90) |
//|   8. Comment encodes sub-path: "T,<dir>,<sub>,1,<sl>"             |
//|                                                                   |
//| Deferred to P4 IMPL-062+: ZoneStrength=ZONE_PROVEN explicit gate; |
//| zone_hit ≥ 2 counter (currently proxied via subdem.has_*); _NoOpp |
//| GBR cross-slot directional check (currently no-op TRUE — Phase 1  |
//| conservative: rely on PortfolioState GetByMagic for G/B/R later); |
//| advanced ADXW dominance "A"/"B" sub-classification.                |
//|                                                                   |
//| Exit (ManageExits):                                                |
//|   - Profit gate ≥ InpTTpProfitPips (45 pip default — unchanged)    |
//|                                                                   |
//| Pending integration (ADR-008 / OQ-A3):                            |
//|   - CPendingMachineRegistry PM_T; force-clear = PMR.TickAll       |
//|   - InpForceClearT_Bars = 80 (Inputs_Pending.mqh)                 |
//|   - Slot ห้าม call TickAll directly — Orchestrator step 8 owns it  |
//|                                                                   |
//| Lot: RiskManager::ComputeLot("T", sl_pips, balance)                |
//|                                                                   |
//| ADR-012 include discipline:                                        |
//|   ห้าม #include "slots/<other>.mqh"                                |
//|   ห้าม #include "services/Logger.mqh" direct (injected)            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SLOTS_SLOT_T_MQH
#define PHOENICISNEX_SLOTS_SLOT_T_MQH

#include "../domain/CSlotBase.mqh"
#include "../domain/MarketContext.mqh"
#include "../domain/EnumTypes.mqh"
#include "../services/RiskManager.mqh"
#include "../services/PortfolioState.mqh"
#include "../services/PendingMachineRegistry.mqh"
#include "../inputs/Inputs_Slot_T.mqh"

//+------------------------------------------------------------------+
//| CSlotT — Slot T derived class (ADR-002 CSlotBase contract)        |
//|                                                                   |
//| Uses T-Pending state machine (PM_T) to gate entry per §3.15:      |
//|   IDLE + base signal → EnterPending (await retest/confirm bar)    |
//|   PENDING + trigger valid → place entry + TransitionExecuted      |
//|   Force-clear (80 H4 bars): handled by PMR.TickAll in Orchestr.   |
//+------------------------------------------------------------------+
class CSlotT : public CSlotBase
  {
private:
   //--- Private helpers (§3.15 4-sub-path predicates)
   bool              _HasActiveTOrder(CPortfolioState &port) const;
   bool              _IsTBuySupportZone(const MarketContext &ctx) const;     // §3.15:2 BUY zone+BB%
   bool              _IsTSellResistanceZone(const MarketContext &ctx) const; // §3.15:2 SELL mirror
   bool              _IsPriceAboveHull(const MarketContext &ctx) const;      // §3.15:4 BUY
   bool              _IsPriceBelowHull(const MarketContext &ctx) const;      // §3.15:4 SELL
   int               _BBTopBelowIchiMaxCount(const MarketContext &ctx) const;// §3.15:5 BUY scan
   int               _BBBotAboveIchiMinCount(const MarketContext &ctx) const;// §3.15:5 SELL mirror
   bool              _IsAdxDominant(const MarketContext &ctx) const;         // §3.15:6
   bool              _IsTBuyBaseSignal(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTSellBaseSignal(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTBuyTrigger(const MarketContext &ctx, CPortfolioState &port) const;
   bool              _IsTSellTrigger(const MarketContext &ctx, CPortfolioState &port) const;
   string            _ResolveTSubPath(const MarketContext &ctx) const;       // §3.15:7 D/H sub-path
   double            _ComputeTSlPips(const MarketContext &ctx, bool isBuy) const; // §3.15:9 SL anchor
   double            _IchiMaxH4(const MarketContext &ctx) const;
   double            _IchiMinH4(const MarketContext &ctx) const;

public:
   //--- Constructor / Destructor
   CSlotT() {}
   virtual ~CSlotT() {}

   //--- 6-method behavior contract (ADR-002; slot-abstraction-contract.yaml)

   //--- 1. Magic — MAGIC_T = 219
   virtual int           Magic()  const override { return MAGIC_T; }

   //--- 2. SlotId — "T"; used by journal slot_id field + comment prefix "T,"
   virtual string        SlotId() const override { return "T"; }

   //--- 3. Evaluate — entry pass with T-Pending integration (FR-2.3)
   //       Called only in EA_STATE_RUNNING
   virtual void          Evaluate(const MarketContext &ctx, CPortfolioState &port) override;

   //--- 4. ManageExits — exit pass; called in BOTH RUNNING + HALTED (ADR-010)
   virtual void          ManageExits(CPortfolioState &port) override;

   //--- 5. DependsOn — T is topologically independent; PMR dep is shared service
   virtual int           DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 0);
      return 0;
     }

   //--- 6. PendingState — delegate to PMR if wired; else IDLE (safe default)
   virtual EPendingState PendingState() const override
     {
      if(m_pending == NULL) return PENDING_STATE_IDLE;
      return m_pending.GetState(PM_T);
     }
  };

//+------------------------------------------------------------------+
//| _IchiMaxH4 / _IchiMinH4 — Ichimoku H4 cloud-edge max/min          |
//| max = top of (cloud_high, tenkan, kijun); min = bottom of triple  |
//+------------------------------------------------------------------+
double CSlotT::_IchiMaxH4(const MarketContext &ctx) const
  {
   double a = ctx.ichi_h4.cloud_high;
   double b = ctx.ichi_h4.tenkan[0];
   double c = ctx.ichi_h4.kijun[0];
   return MathMax(a, MathMax(b, c));
  }

double CSlotT::_IchiMinH4(const MarketContext &ctx) const
  {
   double a = ctx.ichi_h4.cloud_low;
   double b = ctx.ichi_h4.tenkan[0];
   double c = ctx.ichi_h4.kijun[0];
   return MathMin(a, MathMin(b, c));
  }

//+------------------------------------------------------------------+
//| _HasActiveTOrder — check for open T orders via PortfolioState     |
//| Comment prefix "T," for disambiguation                            |
//+------------------------------------------------------------------+
bool CSlotT::_HasActiveTOrder(CPortfolioState &port) const
  {
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_T, "T,", tickets);
   return n > 0;
  }

//+------------------------------------------------------------------+
//| _IsTBuySupportZone — §3.15:2 BUY: zone present + BB% < InpTBoll   |
//| BollBand% = bb_ratio * 100 (0-100 scale; bb_ratio is fraction).   |
//| has_support proxy stands in for ZoneStrength=ZONE_PROVEN gate     |
//| (Phase 1 conservative; full strength sub-classification = P4).    |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuySupportZone(const MarketContext &ctx) const
  {
   if(!ctx.subdem_h4.has_support) return false;
   double bb_pct = ctx.bb_h4.bb_ratio * 100.0;
   return (bb_pct < InpTBollBandPctBuy);
  }

//+------------------------------------------------------------------+
//| _IsTSellResistanceZone — SELL mirror per §3.15                    |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellResistanceZone(const MarketContext &ctx) const
  {
   if(!ctx.subdem_h4.has_demand) return false;
   double bb_pct = ctx.bb_h4.bb_ratio * 100.0;
   return (bb_pct > InpTBollBandPctSell);
  }

//+------------------------------------------------------------------+
//| _IsPriceAboveHull / _IsPriceBelowHull — §3.15:1 Hull gate         |
//| IMPL-FIX-011a R-13 (gap A) Hull direction per CodeWiki §3.15:1 +  |
//| diagnostic § 3: legacy `BusinessLogic_T` line 18449 (BUY) /       |
//| line 18644 (SELL) uses MEAN-REVERSION semantics —                 |
//|   BUY  outer gate: `Hull[0] < H4Support.hi` ⇒ price PULLED BACK   |
//|        to Hull at oversold support → entry expects `bid <= Hull`  |
//|   SELL outer gate: mirror with Resist → `ask >= Hull`             |
//| Pre-fix predicates `bid > Hull` / `ask < Hull` were trend-        |
//| following (opposite signal); falsified at iter-3 (T/entry |Δ|=3   |
//| spurious 2021-03-11 BUY + silent at all 4 legacy buckets).        |
//| Helper names retained for §3.15 spec-mapping; semantics now       |
//| mean-reversion per legacy decode. Hull MA H4 proxied via          |
//| IDX_MA_FAST_H4 SMA-50 (IMPL-006); true Hull deferred to P4        |
//| IMPL-062 if Bucket A drift remains.                               |
//+------------------------------------------------------------------+
bool CSlotT::_IsPriceAboveHull(const MarketContext &ctx) const
  {
   if(ctx.hull_h4.hull <= 0.0) return false;  // unwired; degrade-but-continue
   return (ctx.bid <= ctx.hull_h4.hull);       // BUY mean-reversion: bid pulled back to Hull
  }

bool CSlotT::_IsPriceBelowHull(const MarketContext &ctx) const
  {
   if(ctx.hull_h4.hull <= 0.0) return false;
   return (ctx.ask >= ctx.hull_h4.hull);       // SELL mean-reversion: ask pulled up to Hull
  }

//+------------------------------------------------------------------+
//| _BBTopBelowIchiMaxCount — §3.15:5 BUY scan                        |
//| IMPL-FIX-011a R-13 (gap B) Ichi cloud-edge per CodeWiki §3.15:5 + |
//| diagnostic § 3 row B: legacy `BollBTop[z] < MathMin(SenkouA[z],   |
//| SenkouB[z])` per-bar (strict cloud-LOW edge, not current-bar      |
//| derived `max(cloud_high, tenkan[0], kijun[0])` which mixed        |
//| tenkan/kijun into cloud gate). Helper name retained for §3.15:5   |
//| spec-mapping; semantics now per-bar `bb_top[i] < cloud_low[i]`.   |
//+------------------------------------------------------------------+
int CSlotT::_BBTopBelowIchiMaxCount(const MarketContext &ctx) const
  {
   if(!ctx.bb_h4_history.has_data || !ctx.ichi_h4_history.has_data) return 0;
   int n = (InpTBBHistWindow < 15) ? InpTBBHistWindow : 15;
   int count = 0;
   for(int i = 0; i < n; i++)
      if(ctx.bb_h4_history.bb_top[i] < ctx.ichi_h4_history.cloud_low[i]) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _BBBotAboveIchiMinCount — §3.15:5 SELL mirror                     |
//| IMPL-FIX-011a R-13 (gap B) SELL completion: now uses proper       |
//| per-bar `bb_bot[i] > cloud_high[i]` matching legacy line 18644    |
//| `BollBBot[z] > MathMax(SenkouA[z], SenkouB[z])`. Pre-Fix-B was a  |
//| symmetric proxy reusing BUY scan because bb_bot history + per-bar |
//| cloud_high didn't exist — both added 2026-05-11 (BBHistoryFields  |
//| bb_bot[15] + IchimokuHistoryFields cloud_high[15]).               |
//+------------------------------------------------------------------+
int CSlotT::_BBBotAboveIchiMinCount(const MarketContext &ctx) const
  {
   if(!ctx.bb_h4_history.has_data || !ctx.ichi_h4_history.has_data) return 0;
   int n = (InpTBBHistWindow < 15) ? InpTBBHistWindow : 15;
   int count = 0;
   for(int i = 0; i < n; i++)
      if(ctx.bb_h4_history.bb_bot[i] > ctx.ichi_h4_history.cloud_high[i]) count++;
   return count;
  }

//+------------------------------------------------------------------+
//| _IsAdxDominant — §3.15:6 ADX > InpTAdxMin                         |
//+------------------------------------------------------------------+
bool CSlotT::_IsAdxDominant(const MarketContext &ctx) const
  {
   return (ctx.adx_h4.adx > InpTAdxMin);
  }

//+------------------------------------------------------------------+
//| _IsTBuyBaseSignal — composite (Phase A IDLE → EnterPending gate)  |
//| All §3.15 BUY conditions except DEM trigger (D/H differentiation  |
//| happens at Phase B trigger time, not Phase A enter time).         |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuyBaseSignal(const MarketContext &ctx, CPortfolioState &port) const
  {
   //--- §3.15:1 (no active T) — caller already checks; redundant guard skipped
   //--- §3.15:2 — zone + BB%
   if(!_IsTBuySupportZone(ctx)) return false;
   //--- §3.15:3 — no opposing G/B/R sells (Phase 1 no-op TRUE; defer to P4)
   //              full impl: PortfolioState.GetByMagic(MAGIC_G/B/R).total_lots_sell == 0
   //--- §3.15:4 — Price > Hull MA
   if(!_IsPriceAboveHull(ctx)) return false;
   //--- §3.15:5 — ≥InpTBBHistMinAboveCount (default 7) of last InpTBBHistWindow (default 10) bars
   if(_BBTopBelowIchiMaxCount(ctx) < InpTBBHistMinAboveCount) return false;
   //--- §3.15:6 — ADX dominance
   if(!_IsAdxDominant(ctx)) return false;
   return true;
  }

//+------------------------------------------------------------------+
//| _IsTSellBaseSignal — SELL mirror per §3.15                        |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellBaseSignal(const MarketContext &ctx, CPortfolioState &port) const
  {
   if(!_IsTSellResistanceZone(ctx)) return false;
   if(!_IsPriceBelowHull(ctx)) return false;
   if(_BBBotAboveIchiMinCount(ctx) < InpTBBHistMinAboveCount) return false;
   if(!_IsAdxDominant(ctx)) return false;
   return true;
  }

//+------------------------------------------------------------------+
//| _IsTBuyTrigger — Phase B PENDING execute gate                     |
//| Re-check base conditions still hold + zone hasn't disappeared.    |
//| DEM differentiation goes into the comment sub-path (D/H), not the |
//| trigger gate itself — both sub-paths execute when base+zone OK.   |
//+------------------------------------------------------------------+
bool CSlotT::_IsTBuyTrigger(const MarketContext &ctx, CPortfolioState &port) const
  {
   return _IsTBuyBaseSignal(ctx, port);
  }

//+------------------------------------------------------------------+
//| _IsTSellTrigger — SELL mirror                                     |
//+------------------------------------------------------------------+
bool CSlotT::_IsTSellTrigger(const MarketContext &ctx, CPortfolioState &port) const
  {
   return _IsTSellBaseSignal(ctx, port);
  }

//+------------------------------------------------------------------+
//| _ResolveTSubPath — §3.15:7 DEM ≥ 0.45 → "D" else "H"              |
//+------------------------------------------------------------------+
string CSlotT::_ResolveTSubPath(const MarketContext &ctx) const
  {
   return (ctx.dem_h4.dem >= InpTDemThreshD) ? "D" : "H";
  }

//+------------------------------------------------------------------+
//| _ComputeTSlPips — §3.15:9 SL = max(hull-distance, BBWidth pips,   |
//|                                    InpTSlPipsCodeWikiFloor=90)    |
//+------------------------------------------------------------------+
double CSlotT::_ComputeTSlPips(const MarketContext &ctx, bool isBuy) const
  {
   double pip_size = _PipSize();
   if(pip_size <= 0.0) return InpTSlPipsCodeWikiFloor;

   //--- Hull-distance component
   double hull_pips = 0.0;
   if(ctx.hull_h4.hull > 0.0)
     {
      double hull_dist_price = isBuy ? (ctx.bid - ctx.hull_h4.hull)
                                     : (ctx.hull_h4.hull - ctx.ask);
      hull_pips = MathMax(0.0, hull_dist_price / pip_size);
     }

   //--- BBWidth component
   double bb_width_pips = (ctx.bb_h4.bb_width > 0.0)
                          ? (ctx.bb_h4.bb_width / pip_size)
                          : 0.0;

   //--- §3.15:9 max of three components
   double sl_pips = MathMax(hull_pips, MathMax(bb_width_pips, InpTSlPipsCodeWikiFloor));
   return sl_pips;
  }

//+------------------------------------------------------------------+
//| Evaluate — Slot T entry pass with T-Pending integration           |
//|                                                                   |
//| T-Pending pattern (ADR-008 / OQ-A3 / shared context §4.3):        |
//|   Phase A (base signal, not yet in pending):                      |
//|     IDLE + base signal → EnterPending(PM_T, payload, bar_index)  |
//|   Phase B (pending, trigger now valid):                           |
//|     PENDING + trigger valid → place entry + TransitionExecuted    |
//|   Force-clear: PMR.TickAll (Orchestrator step 8) — slot ห้าม poll  |
//|                                                                   |
//| IMPL-FIX-011 Session C — predicates now history-based per §3.15.   |
//+------------------------------------------------------------------+
void CSlotT::Evaluate(const MarketContext &ctx, CPortfolioState &port)
  {
   if(!InpEnableSlotT) return;

   //--- Guard: service pointers must be wired (Composition Root via Init)
   if(m_risk == NULL || m_logger == NULL) return;

   //--- Condition 1: no active T orders ("T," prefix)
   if(_HasActiveTOrder(port)) return;

   //--- Guard: PMR must be wired for pending state machine
   if(m_pending == NULL) return;

   //--- Retrieve current pending state for PM_T
   EPendingState st = m_pending.GetState(PM_T);

   //--- Phase A: IDLE — check base signal, enter pending if met
   if(st == PENDING_STATE_IDLE)
     {
      bool buyBase  = _IsTBuyBaseSignal(ctx, port);
      bool sellBase = _IsTSellBaseSignal(ctx, port);

      if(!buyBase && !sellBase) return;

      //--- §3.15:9 SL anchor (max of Hull/BBWidth/floor)
      double sl_pips = _ComputeTSlPips(ctx, buyBase);

      //--- Build pending payload (minimal JSON — full schema in
      //    state-persistence-schema.yaml § PendingMachine; sub_path
      //    deferred to Phase B trigger time so DEM can update inside
      //    the pending window without invalidating the gate).
      string dir     = buyBase ? "BUY" : "SELL";
      string payload = StringFormat("{\"dir\":\"%s\",\"sl_pips\":%.1f}", dir, sl_pips);

      m_pending.EnterPending(PM_T, payload, ctx.bar_index_h4);

      if(m_logger != NULL)
         m_logger.Info("SlotT", "pending_entered", MAGIC_T,
                       StringFormat("dir=%s bar_index=%d sl_pips=%.1f payload=%s",
                                    dir, ctx.bar_index_h4, sl_pips, payload));
      return;
     }

   //--- Phase B: PENDING — check trigger, place entry if valid
   if(st == PENDING_STATE_PENDING)
     {
      //--- Read payload to recover direction
      string payload = m_pending.GetPayload(PM_T);
      bool   isBuy   = (StringFind(payload, "\"dir\":\"BUY\"") >= 0);

      bool triggerOk = isBuy ? _IsTBuyTrigger(ctx, port) : _IsTSellTrigger(ctx, port);
      if(!triggerOk) return;

      //--- Pip size via base-class helper (Round-06 06.1)
      double pip_size = _PipSize();
      double sl_pips  = _ComputeTSlPips(ctx, isBuy);

      //--- Compute lot
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double lot     = m_risk.ComputeLot("T", sl_pips, balance);

      if(lot <= 0.0)
        {
         m_logger.Warn("SlotT", "zero_lot_skip", MAGIC_T,
                       "ComputeLot returned 0 — skipping T entry");
         return;
        }

      //--- §3.15:7 sub-path resolution at trigger time
      string sub_path = _ResolveTSubPath(ctx);

      //--- Compute SL + TP prices
      double price    = isBuy ? ctx.ask : ctx.bid;
      double sl_price = isBuy
                        ? _NormalizeBrokerPrice(ctx.ask - sl_pips * pip_size)
                        : _NormalizeBrokerPrice(ctx.bid + sl_pips * pip_size);

      //--- §3.15 comment encodes sub-path: "T,<dir>,<sub>,1,<sl_pips>"
      string comment = StringFormat("T,%s,%s,1,%.0f",
                                    (isBuy ? "B" : "S"), sub_path, sl_pips);

      //--- Submit order through RiskManager CTrade wrapper
      //    ห้าม instantiate CTrade direct (ea.md + ADR-002)
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
      req.magic        = MAGIC_T;
      req.type_filling = ORDER_FILLING_FOK;  // broker detection at Orchestrator wiring path

      // IMPL-FIX-011 R-13 (d): entry_signal Info emit suppressed (per-tick stub
      // spam bloated Q1 canary log to 1.41 GB / ~30 GB extrapolated over 5-yr;
      // restore when RiskManager::OpenOrder wires real send + this becomes
      // one-shot post-fill milestone). Mirrors IMPL-FIX-008 R-10 stub-suppress.
      // if(m_logger != NULL)
      //    m_logger.Info("SlotT", "entry_signal", MAGIC_T,
      //                  StringFormat("dir=%s sub=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s",
      //                               (isBuy ? "BUY" : "SELL"), sub_path, lot, sl_pips, price, sl_price,
      //                               comment));

      //--- IMPL-FIX-003: submit broker order via RiskManager.OpenOrder wrapper (ea.md mandate)
      m_risk.OpenOrder(req, "T");

      //--- Transition PMR to EXECUTED state (force-clear counter resets)
      m_pending.TransitionExecuted(PM_T);
     }

   //--- Phase C: EXECUTED — entry placed; pending machine will reset to IDLE
   //    on next PMR.TickAll pass — no action needed in slot.
  }

//+------------------------------------------------------------------+
//| ManageExits — Slot T exit pass (CodeWiki §3.T MVP — UNCHANGED)     |
//|                                                                   |
//| Exit logic (MVP):                                                 |
//|   1. Iterate T positions via GetTicketsForSlot(MAGIC_T, "T,")    |
//|   2. Compute unrealized profit in pips                            |
//|   3. Profit gate ≥ InpTTpProfitPips (45 pip default) → close     |
//+------------------------------------------------------------------+
void CSlotT::ManageExits(CPortfolioState &port)
  {
   if(m_logger == NULL) return;

   //--- Retrieve T tickets (comment prefix "T,")
   ulong tickets[];
   int n = port.GetTicketsForSlot(MAGIC_T, "T,", tickets);
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

      //--- Profit gate: ≥ InpTTpProfitPips → emit close signal
      if(profit_pips >= InpTTpProfitPips)
        {
         // IMPL-FIX-008 R-10: exit_profit_gate Info emit suppressed (Phase-1 stub spam
         // caused 5-yr regression to bloat log + halt processing pace; restore when
         // RiskManager::CloseOrder wires + this becomes one-shot post-close milestone)
//          m_logger.Info("SlotT", "exit_profit_gate", MAGIC_T,
//                        StringFormat("ticket=%I64u profit_pips=%.1f >= gate=%.1f → close",
//                                     ticket, profit_pips, InpTTpProfitPips));

         //--- Phase-1 stub: logger-only milestone; broker close wires at
         //    Orchestrator wiring path (core/Orchestrator.mqh) (RiskManager::OpenOrder) per ea.md.
        }
     }
  }

#endif // PHOENICISNEX_SLOTS_SLOT_T_MQH
