//+------------------------------------------------------------------+
//| EnumTypes.mqh — shared enum types (no #include dependencies)     |
//+------------------------------------------------------------------+
#ifndef PHOENICISNEX_DOMAIN_ENUMTYPES_MQH
#define PHOENICISNEX_DOMAIN_ENUMTYPES_MQH

enum EEAState {
   EA_STATE_RUNNING       = 0,
   EA_STATE_HALTED        = 1,
   EA_STATE_HALTED_STABLE = 2
};

enum EPendingState {
   PENDING_STATE_IDLE     = 0,
   PENDING_STATE_PENDING  = 1,
   PENDING_STATE_EXECUTED = 2
};

enum ESeverity {
   LOG_DEBUG = 0,
   LOG_INFO  = 1,
   LOG_WARN  = 2,
   LOG_ERROR = 3
};

enum EPendingMachineId {
   PM_C, PM_C_ADX, PM_R, PM_P,
   PM_M, PM_T, PM_Q, PM_FORCE
};

enum EPSubMode {           // P-Pending sub-mode per `04-data-flow.md § 4.4` + ADR schema
   PSUB_NONE = 0,           // null / IDLE
   PSUB_N    = 1,           // transient — mode-decision branch unresolved
   PSUB_PX   = 2,           // Force fast-path
   PSUB_PH   = 3,           // Hull/Bollinger default
   PSUB_E    = 4            // P_Extra extension entry
};

static const int MAGIC_CD = 200;  // C, D shared
static const int MAGIC_F  = 201;
static const int MAGIC_H  = 205;
static const int MAGIC_J  = 206;  // ⚠️ BR-7.2 fix — ExtraTakeProfit_J iterates this
static const int MAGIC_K  = 207;
static const int MAGIC_G  = 208;  // G, G2 shared
static const int MAGIC_L  = 211;  // L, LX shared
static const int MAGIC_GO = 209;
static const int MAGIC_M  = 210;
static const int MAGIC_Q  = 212;
static const int MAGIC_R  = 213;
static const int MAGIC_B  = 214;  // B, BI shared
static const int MAGIC_BR = 215;
static const int MAGIC_I  = 216;
static const int MAGIC_S  = 217;
static const int MAGIC_P  = 218;
static const int MAGIC_T  = 219;
// Slot U (magic 220) deleted per OQ-8 (2026-05-01)

//--- BR-1.1 + ADR-005: 21 active slots − 4 shared-magic pairs = 17 distinct magics.
//    Single source of truth — replaces literal `17` across PortfolioState /
//    StatePersistence / TradeJournal / Orchestrator (see fix-round-10 § 10.7).
#define PHOENICISNEX_MAGIC_COUNT 17

//--- PhoenicisNex magic-number membership gate (per BR-1.1 + ADR-005).
//    Used by trade-transaction surface (Orchestrator::OnTradeTransaction)
//    to reject foreign-EA close events on multi-EA terminals before they
//    reach CircuitBreaker BR-3.6 ring buffer. See fix-round-11 § 11.2,
//    fix-round-12 § 12.2.
//
//    fix-round-12 § 12.2 — switched from literal range [200..219] to
//    explicit set membership over MAGIC_* constants. The MAGIC_* set is
//    NOT contiguous: 202, 203, 204 fall in the gap between MAGIC_F=201 and
//    MAGIC_H=205 with no slot owning them. A range check would let a
//    foreign EA running with magic 202/203/204 feed BR-3.6 and trigger
//    false-positive ping-pong halts (partial regression of fix-round-11
//    § 11.2). Updates here MUST mirror any future MAGIC_* addition or
//    removal (also bump PHOENICISNEX_MAGIC_COUNT).
bool IsPhoenicisMagic(int magic)
  {
   //--- if/else over MAGIC_* ladder rather than `switch` because MQL5
   //    switch labels require literal constant expressions, and the
   //    `static const int MAGIC_*` declarations above are runtime-initialised
   //    objects (`error 188: constant expression required`).
   //    PHOENICISNEX_MAGIC_COUNT (=17) and the MAGIC_* set above are the
   //    single source of truth — keep this list in sync with any future
   //    addition or removal.
   return magic == MAGIC_CD     // 200 (C, D shared)
       || magic == MAGIC_F      // 201
       || magic == MAGIC_H      // 205
       || magic == MAGIC_J      // 206
       || magic == MAGIC_K      // 207
       || magic == MAGIC_G      // 208 (G, G2 shared)
       || magic == MAGIC_GO     // 209
       || magic == MAGIC_M      // 210
       || magic == MAGIC_L      // 211 (L, LX shared)
       || magic == MAGIC_Q      // 212
       || magic == MAGIC_R      // 213
       || magic == MAGIC_B      // 214 (B, BI shared)
       || magic == MAGIC_BR     // 215
       || magic == MAGIC_I      // 216
       || magic == MAGIC_S      // 217
       || magic == MAGIC_P      // 218
       || magic == MAGIC_T;     // 219
  }

#endif // PHOENICISNEX_DOMAIN_ENUMTYPES_MQH
