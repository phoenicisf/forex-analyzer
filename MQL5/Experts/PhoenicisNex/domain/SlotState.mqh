//+------------------------------------------------------------------+
//| SlotState.mqh — per-magic state record (ADR-005)                 |
//| Schema: docs/api-specs/state-persistence-schema.yaml § slot_states|
//| 11 fields; pure data record — no methods                         |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_DOMAIN_SLOTSTATE_MQH
#define PHOENICISNEX_DOMAIN_SLOTSTATE_MQH

#include "EnumTypes.mqh"

//+------------------------------------------------------------------+
//| SlotState — per-magic in-memory state record                     |
//|                                                                  |
//| Owned by PortfolioState (CHashMap keyed by magic per ADR-005).  |
//| `magic` is denormalized here for O(1) reverse lookup;           |
//| in state-persistence-schema.yaml it is the parent map key       |
//| (not a property). See IMPL-004-evidence-20260502.md § Delta.    |
//|                                                                  |
//| `slot_ids[]` holds single entry for unique-magic slots and      |
//| multiple entries for shared-magic slots:                        |
//|   magic 200 → ["C","D"]                                         |
//|   magic 208 → ["G","G2"]                                        |
//|   magic 211 → ["L","LX"]                                        |
//|   magic 214 → ["B","BI"]                                        |
//|                                                                  |
//| `ticket_ids[]` and `ticket_max_profit_pip[]` are parallel       |
//| arrays (BR-5.2 trailing per ticket). Always keep lengths equal. |
//+------------------------------------------------------------------+
class SlotState {
public:
   int           magic;                   // 200..219 per BR-1.1; denormalized in-memory field
   string        slot_ids[];              // ["C","D"] shared; single entry otherwise
   int           buy_count;
   int           sell_count;
   double        total_lots;
   double        total_profit;            // floating P/L
   datetime      last_open_date;
   ulong         ticket_ids[];            // active position tickets
   double        ticket_max_profit_pip[]; // parallel array to ticket_ids — BR-5.2 trailing per ticket
   EPendingState pending_state;
   string        pending_payload;         // serialized pending machine (CPendingComment / MPendingAtPrice JSON)
};

#endif // PHOENICISNEX_DOMAIN_SLOTSTATE_MQH
