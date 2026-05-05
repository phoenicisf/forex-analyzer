//+------------------------------------------------------------------+
//| PortfolioState.mqh — per-magic in-memory portfolio state        |
//| Layer:   services/ — injected into slots via Orchestrator        |
//| Source:  ADR-005, TD-02 §5.3 lines 535-575                      |
//|          BR-1.1 (17-magic invariant), BR-1.2 (comment prefix)   |
//|          ADR-012 (5-layer include discipline)                    |
//|                                                                  |
//| Key contracts:                                                   |
//|  • CHashMap<int, SlotState*> m_map — O(1) average GetByMagic    |
//|  • RegisterAll() pre-populates 17 SlotState* entries (BR-1.1)   |
//|  • GetByMagic() returns NULL + Warn for unregistered magic       |
//|  • Refresh() stub — full PositionsTotal() loop deferred to       |
//|    <closed; ref purged fix-round-18 §18.1> (orchestrator wire-up) + IMPL-018+ (entry .mq5)    |
//|  • ReleaseAll() deletes heap-allocated SlotState*               |
//|                                                                  |
//| 2-phase init: Init() called at Orchestrator OnInit step 5;       |
//|   RegisterAll() called immediately after Init() — BootstrapVal  |
//|   asserts MagicCount() == 17 (per ADR-005 + BR-1.1).            |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_SERVICES_PORTFOLIOSTATE_MQH
#define PHOENICISNEX_SERVICES_PORTFOLIOSTATE_MQH

#include <Generic\HashMap.mqh>
#include "../domain/EnumTypes.mqh"
#include "../domain/SlotState.mqh"
#include "Logger.mqh"

// CommentParser is not included here — consumed by GetTicketsForSlot
// body when it lands (IMPL-007-getticketsforslot); forward-declare is
// not needed since we only stub the method.

//+------------------------------------------------------------------+
//| CPortfolioState                                                  |
//|                                                                  |
//| Naming: m_* members, PascalCase public, _camelCase private       |
//| (per ea.md naming conventions + ADR-012)                         |
//+------------------------------------------------------------------+
class CPortfolioState
  {
private:
   //--- CHashMap: key = magic int, value = heap-allocated SlotState*
   //    (ADR-005: CHashMap for O(1) average lookup per BR-1.1)
   CHashMap<int, SlotState *> m_map;

   //--- Iteration order for Refresh / ReleaseAll (17 distinct magics)
   //    ADR-005 § BR-1.1: 21 slots − 4 shared-magic pairs = 17 magics
   int               m_magic_list[PHOENICISNEX_MAGIC_COUNT];

   //--- Count of registered magics (asserted == 17 by BootstrapValidator)
   int               m_magic_count;

   //--- Injected logger (Composition Root — no global access)
   CLogger          *m_logger;

public:
   //--- Default constructor — zero-init (CHashMap has default ctor)
   CPortfolioState() : m_magic_count(0), m_logger(NULL) {}

   //--- Phase 1 init: store logger pointer + clear map
   //    Called at Orchestrator OnInit step 5 (TD-02 §7.4)
   void              Init(CLogger *logger);

   //--- OnInit step 5 (immediately after Init): populate 17 entries
   //    Boot-time invariant: MagicCount() == 17 (ADR-005 + BR-1.1)
   void              RegisterAll();

   //--- Invariant accessor — BootstrapValidator asserts == 17
   int               MagicCount() const { return m_magic_count; }

   //--- OnTick step H: refresh aggregates from broker (~100 µs target)
   //    Per ADR-005 § Refresh contract; broker query body completed at
   //    <closed; ref purged fix-round-18 §18.1> (Orchestrator) per impl-plan.
   void              Refresh();

   //--- O(1) average slot accessor (ADR-005 — CHashMap lookup)
   //    Returns NULL + Logger Warn for unregistered magic
   SlotState        *GetByMagic(int magic);

   //--- Silent membership test — true iff `magic` was registered by
   //    RegisterAll(). Distinct from GetByMagic: no Logger Warn on miss.
   //    Use in hot loops (e.g. _AggregateWeakMetrics) that iterate
   //    PositionsTotal() and must skip foreign-EA positions without
   //    spamming the log. (Added per fix-round-09 Finding 09.1.)
   bool              IsKnownMagic(int magic);   // non-const: CHashMap.TryGetValue is non-const

   //--- Filter shared-magic positions by comment prefix (BR-1.2)
   //    Body deferred to IMPL-007-getticketsforslot (uses CommentParser)
   int               GetTicketsForSlot(int magic, string slot_prefix,
                                       ulong &out_tickets[]) const;

   //--- Aggregate accessors for cross-slot helpers (Safe-port etc.)
   int               TotalActivePositions();
   double            TotalFloatingPL();
   void              GetSlotCounts(string &slot_ids[], int &counts[]) const;

   //--- OnDeinit: release heap-allocated SlotState entries
   void              ReleaseAll();

  }; // end class CPortfolioState

//+------------------------------------------------------------------+
//| Init — store logger pointer + clear map                          |
//| Called at Orchestrator OnInit step 5 (TD-02 §7.4)               |
//+------------------------------------------------------------------+
void CPortfolioState::Init(CLogger *logger)
  {
   // Defensive: if Init() is invoked a second time (MT5 re-init on input
   // parameter change, or CleanupPartialInit → re-attempt), the prior round
   // left 17 heap-allocated SlotState* entries in m_map. m_map.Clear()
   // alone drops references → leak (Finding 01.5 / ADR-005 lifecycle pairing).
   if(m_magic_count > 0)
      ReleaseAll();   // delete each SlotState* + Clear() map + reset count

   m_logger      = logger;
   m_magic_count = 0;
   m_map.Clear();    // no-op if ReleaseAll ran; safe on first init

   // Zero-init magic list (populated by RegisterAll)
   ArrayInitialize(m_magic_list, 0);
  }

//+------------------------------------------------------------------+
//| RegisterAll — pre-populate 17 SlotState* entries                 |
//|                                                                  |
//| BR-1.1: 21 active slots / 17 distinct magics (4 shared pairs):  |
//|   200 → ["C","D"]  (MAGIC_CD)                                    |
//|   208 → ["G","G2"] (MAGIC_G)                                     |
//|   211 → ["L","LX"] (MAGIC_L)                                     |
//|   214 → ["B","BI"] (MAGIC_B)                                     |
//|   All other 13 → single-entry slot_ids[]                         |
//|                                                                  |
//| Heap-allocates each SlotState* — released by ReleaseAll().       |
//| Magic audit list (verify vs EnumTypes.mqh):                      |
//|   200, 201, 205, 206, 207, 208, 209, 210, 211,                   |
//|   212, 213, 214, 215, 216, 217, 218, 219                         |
//+------------------------------------------------------------------+
void CPortfolioState::RegisterAll()
  {
   // --- Define 17 magics in iteration order (matches m_magic_list) ---
   // Source: domain/EnumTypes.mqh MAGIC_* constants + ADR-005 BR-1.1
   int magics[PHOENICISNEX_MAGIC_COUNT] = {
      MAGIC_CD,  // 200 — C, D shared
      MAGIC_F,   // 201 — F
      MAGIC_H,   // 205 — H
      MAGIC_J,   // 206 — J (⚠️ BR-7.2: ExtraTakeProfit_J iterates this)
      MAGIC_K,   // 207 — K
      MAGIC_G,   // 208 — G, G2 shared
      MAGIC_GO,  // 209 — GO
      MAGIC_M,   // 210 — M
      MAGIC_L,   // 211 — L, LX shared
      MAGIC_Q,   // 212 — Q
      MAGIC_R,   // 213 — R
      MAGIC_B,   // 214 — B, BI shared
      MAGIC_BR,  // 215 — BR
      MAGIC_I,   // 216 — I
      MAGIC_S,   // 217 — S
      MAGIC_P,   // 218 — P
      MAGIC_T    // 219 — T
   };

   // Copy into m_magic_list for Refresh/ReleaseAll iteration
   ArrayCopy(m_magic_list, magics, 0, 0, PHOENICISNEX_MAGIC_COUNT);

   for(int i = 0; i < PHOENICISNEX_MAGIC_COUNT; i++)
     {
      int magic = magics[i];

      // Heap-allocate SlotState — zero-initialized by MQL5
      SlotState *s = new SlotState;

      // Set magic (denormalized for O(1) reverse lookup)
      s.magic         = magic;
      s.buy_count     = 0;
      s.sell_count    = 0;
      s.total_lots    = 0.0;
      s.last_open_lot = 0.0;   // Finding 02.3 — populated by OnTradeTransaction at <closed; ref purged fix-round-18 §18.1>
      s.total_profit  = 0.0;
      s.last_open_date = 0;
      s.pending_state  = PENDING_STATE_IDLE;
      s.pending_payload = "";
      ArrayResize(s.ticket_ids, 0);
      ArrayResize(s.ticket_max_profit_pip, 0);

      // Set slot_ids[] per shared-magic mapping (ADR-005 § Decision)
      switch(magic)
        {
         case 200:  // MAGIC_CD → ["C","D"]
            ArrayResize(s.slot_ids, 2);
            s.slot_ids[0] = "C";
            s.slot_ids[1] = "D";
            break;

         case 208:  // MAGIC_G → ["G","G2"]
            ArrayResize(s.slot_ids, 2);
            s.slot_ids[0] = "G";
            s.slot_ids[1] = "G2";
            break;

         case 211:  // MAGIC_L → ["L","LX"]
            ArrayResize(s.slot_ids, 2);
            s.slot_ids[0] = "L";
            s.slot_ids[1] = "LX";
            break;

         case 214:  // MAGIC_B → ["B","BI"]
            ArrayResize(s.slot_ids, 2);
            s.slot_ids[0] = "B";
            s.slot_ids[1] = "BI";
            break;

         //--- Single-entry slots (13 unique-magic slots) ---
         case 201:  // MAGIC_F
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "F";
            break;
         case 205:  // MAGIC_H
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "H";
            break;
         case 206:  // MAGIC_J
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "J";
            break;
         case 207:  // MAGIC_K
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "K";
            break;
         case 209:  // MAGIC_GO
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "GO";
            break;
         case 210:  // MAGIC_M
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "M";
            break;
         case 212:  // MAGIC_Q
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "Q";
            break;
         case 213:  // MAGIC_R
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "R";
            break;
         case 215:  // MAGIC_BR
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "BR";
            break;
         case 216:  // MAGIC_I
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "I";
            break;
         case 217:  // MAGIC_S
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "S";
            break;
         case 218:  // MAGIC_P
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "P";
            break;
         case 219:  // MAGIC_T
            ArrayResize(s.slot_ids, 1);
            s.slot_ids[0] = "T";
            break;

         default:
            // Defensive: log unexpected magic — should never reach here
            ArrayResize(s.slot_ids, 0);
            if(m_logger != NULL)
               m_logger.Warn("portfolio", "register_unknown_magic", magic, "unexpected magic in RegisterAll");
            break;
        }

      m_map.Add(magic, s);
      m_magic_count++;
     }

   // Emit registration summary for log-assertion E-AC evidence
   //   (consumer wired at <closed; ref purged fix-round-18 §18.1> Orchestrator per impl-plan).
   // Grep pattern: grep -E '\[Phoenicis\].*\[ev=portfolio_registered\]'
   if(m_logger != NULL)
      m_logger.Info("portfolio", "portfolio_registered", 0,
                    "magics registered: " + IntegerToString(m_magic_count));
  }

//+------------------------------------------------------------------+
//| Refresh — reset aggregates + TODO broker position loop           |
//|                                                                  |
//| ADR-005 § Refresh contract:                                      |
//|   Step 1: Reset per-entry aggregates (buy/sell count, lots, PL,  |
//|            ticket arrays)                                         |
//|   Step 2: PositionsTotal() loop — completed at <closed; ref purged fix-round-18 §18.1>     |
//|            (Orchestrator owner) per impl-plan.                    |
//+------------------------------------------------------------------+
void CPortfolioState::Refresh()
  {
   // Step 1 — Reset aggregates per ADR-005 § Refresh contract step 1
   for(int i = 0; i < m_magic_count; i++)
     {
      SlotState *s = NULL;
      if(m_map.TryGetValue(m_magic_list[i], s) && s != NULL)
        {
         s.buy_count     = 0;
         s.sell_count    = 0;
         s.total_lots    = 0.0;
         s.last_open_lot = 0.0;   // Finding 02.3 — reset; re-populated by step 2 broker loop
         s.total_profit  = 0.0;
         ArrayResize(s.ticket_ids, 0);
         ArrayResize(s.ticket_max_profit_pip, 0);
        }
     }

   // TODO IMPL-007-refresh: full PositionsTotal() loop per ADR-005 § Refresh contract step 2
   //   Deferred: requires entry .mq5 (IMPL-018+) + orchestrator wire-up (<closed; ref purged fix-round-18 §18.1>)
   //
   //   Implementation sketch (to land at <closed; ref purged fix-round-18 §18.1>):
   //   for(int i = 0; i < PositionsTotal(); i++) {
   //      ulong ticket = PositionGetTicket(i);
   //      if(!PositionSelectByTicket(ticket)) continue;
   //      int magic = (int)PositionGetInteger(POSITION_MAGIC);
   //      SlotState *s = NULL;
   //      if(!m_map.TryGetValue(magic, s) || s == NULL) continue;
   //      ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   //      if(ptype == POSITION_TYPE_BUY) s.buy_count++;
   //      else s.sell_count++;
   //      double vol = PositionGetDouble(POSITION_VOLUME);
   //      datetime open_t = (datetime)PositionGetInteger(POSITION_TIME);
   //      s.total_lots   += vol;
   //      s.total_profit += PositionGetDouble(POSITION_PROFIT);
   //      // Finding 02.3 — last_open_lot = lot of latest-opened position in pool
   //      if(open_t >= s.last_open_date) { s.last_open_date = open_t; s.last_open_lot = vol; }
   //      int n = ArraySize(s.ticket_ids);
   //      ArrayResize(s.ticket_ids, n + 1);
   //      s.ticket_ids[n] = ticket;
   //      ArrayResize(s.ticket_max_profit_pip, n + 1);
   //      s.ticket_max_profit_pip[n] = 0.0; // trailing tracker init
   //   }
  }

//+------------------------------------------------------------------+
//| GetByMagic — O(1) average slot accessor (ADR-005 CHashMap)       |
//| Returns: pointer to SlotState or NULL if not registered           |
//| On NULL: Logger Warn "magic_not_registered" (S-AC requirement)   |
//+------------------------------------------------------------------+
SlotState *CPortfolioState::GetByMagic(int magic)
  {
   SlotState *s = NULL;
   if(!m_map.TryGetValue(magic, s))
     {
      if(m_logger != NULL)
         m_logger.Warn("portfolio", "magic_not_registered", magic, "");
      return NULL;
     }
   return s;
  }

//+------------------------------------------------------------------+
//| IsKnownMagic — silent membership test (no Logger Warn on miss)   |
//| Used by hot loops that must filter foreign-EA positions out of   |
//| PositionsTotal() iteration without log spam (Finding 09.1).      |
//+------------------------------------------------------------------+
bool CPortfolioState::IsKnownMagic(int magic)
  {
   SlotState *s = NULL;
   return m_map.TryGetValue(magic, s);
  }

//+------------------------------------------------------------------+
//| GetTicketsForSlot — filter shared-magic positions by prefix       |
//| Uses CCommentParser per BR-1.2 (longest-prefix match)            |
//|                                                                  |
//| TODO IMPL-007-getticketsforslot: implement body using            |
//|   helpers/CommentParser.mqh::FilterTicketsByPrefix()             |
//|   Deferred to <closed; ref purged fix-round-18 §18.1> (needs position ticket_ids[] from        |
//|   Refresh() which is deferred + entry .mq5)                      |
//+------------------------------------------------------------------+
int CPortfolioState::GetTicketsForSlot(int magic, string slot_prefix,
                                       ulong &out_tickets[]) const
  {
   // TODO IMPL-007-getticketsforslot: filter via CommentParser per BR-1.2
   //   Example body (to land at <closed; ref purged fix-round-18 §18.1>):
   //   SlotState *s = NULL;
   //   if(!m_map.TryGetValue(magic, s) || s == NULL) return 0;
   //   CCommentParser parser;
   //   return parser.FilterTicketsByPrefix(s.ticket_ids, slot_prefix, out_tickets);
   return 0;
  }

//+------------------------------------------------------------------+
//| TotalActivePositions — sum (buy_count + sell_count) across map   |
//+------------------------------------------------------------------+
int CPortfolioState::TotalActivePositions()
  {
   int total = 0;
   for(int i = 0; i < m_magic_count; i++)
     {
      SlotState *s = NULL;
      if(m_map.TryGetValue(m_magic_list[i], s) && s != NULL)
         total += s.buy_count + s.sell_count;
     }
   return total;
  }

//+------------------------------------------------------------------+
//| TotalFloatingPL — sum total_profit across all entries             |
//+------------------------------------------------------------------+
double CPortfolioState::TotalFloatingPL()
  {
   double total = 0.0;
   for(int i = 0; i < m_magic_count; i++)
     {
      SlotState *s = NULL;
      if(m_map.TryGetValue(m_magic_list[i], s) && s != NULL)
         total += s.total_profit;
     }
   return total;
  }

//+------------------------------------------------------------------+
//| GetSlotCounts — populate slot_ids[] + counts[] for cross-slot    |
//| helpers (Safe-port etc.)                                         |
//|                                                                  |
//| TODO IMPL-007-getslotcounts: implement slot_ids / count arrays   |
//|   Deferred to <closed; ref purged fix-round-18 §18.1> (Safe-port orchestration)                |
//+------------------------------------------------------------------+
void CPortfolioState::GetSlotCounts(string &slot_ids[], int &counts[]) const
  {
   // TODO IMPL-007-getslotcounts: populate parallel arrays per entry
   ArrayResize(slot_ids, 0);
   ArrayResize(counts, 0);
  }

//+------------------------------------------------------------------+
//| ReleaseAll — delete heap-allocated SlotState entries              |
//| Called at Orchestrator OnDeinit (CleanupPartialInit / normal)    |
//| ADR-005: each SlotState* is new'd in RegisterAll → must delete    |
//+------------------------------------------------------------------+
void CPortfolioState::ReleaseAll()
  {
   for(int i = 0; i < m_magic_count; i++)
     {
      SlotState *s = NULL;
      if(m_map.TryGetValue(m_magic_list[i], s) && s != NULL)
        {
         delete s;
        }
     }
   m_map.Clear();
   m_magic_count = 0;
  }

#endif // PHOENICISNEX_SERVICES_PORTFOLIOSTATE_MQH
