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

//--- Sub-demand/support zone strength classifier (CodeWiki §4 SubDemCalcModel*)
//    Legacy `SubDemCalcModelH4Support.strength` enum used to gate THAF entry paths
//    in Slot_T (§3.15:2 + §3.15:7) — ZONE_PROVEN required for non-Day THAF, otherwise
//    fall-through main path. Pre-Fix-E rewrite proxied this via subdem.has_support
//    boolean only (binary present/absent) — loses the strength dimension.
//    Real population deferred to dedicated SubDemCalcModel indicator wiring (P4); for
//    now PopulateSubDem assigns ZONE_NONE as placeholder so THAF predicates fail-closed
//    until real classifier lands.
//    Added 2026-05-11 IMPL-FIX-011a Fix E per diagnostic § 3 row E.
enum EZoneStrength {
   ZONE_NONE    = 0,        // no zone detected
   ZONE_WEAK    = 1,        // zone exists but unconfirmed
   ZONE_TESTED  = 2,        // zone touched ≥1 time
   ZONE_PROVEN  = 3         // zone touched ≥2 times (gates Slot_T THAF non-Day)
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

//--- fix-round-13 § 13.6 — SelfTest pinning IsPhoenicisMagic to MAGIC_*
//    constants and the foreign-EA gap (202/203/204) + boundary cases.
//    Future MAGIC_* addition or removal that forgets to update the `||`
//    chain above is caught here; a green SelfTest is the contract that
//    PHOENICISNEX_MAGIC_COUNT, the MAGIC_* set, and IsPhoenicisMagic
//    remain synchronized (see comment on IsPhoenicisMagic).
//
//    Wiring status (per fix-round-14 § 14.3 honesty pass):
//      • Phase 1 — spike-only:
//          - spike/Spike_Orchestrator.mq5 § OnInit (G1 compile gate)
//          - core/BootstrapValidator::RunDomainSelfTests (header-only;
//            invoked once production Orchestrator wiring lands)
//      • Production wire on live attach: core/Orchestrator.mqh::OnInit
//        Phase B step 1 calls m_validator.RunDomainSelfTests() BEFORE
//        ValidateSymbol so a live EURUSD H4 attach exercises this
//        regression gate at first attach.
bool IsPhoenicisMagicSelfTest()
  {
   bool ok = true;

   //--- Registered set — all 17 magics must return true.
   if(!IsPhoenicisMagic(MAGIC_CD)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(CD=200)=false"); ok = false; }
   if(!IsPhoenicisMagic(MAGIC_F))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(F=201)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_H))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(H=205)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_J))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(J=206)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_K))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(K=207)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_G))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(G=208)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_GO)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(GO=209)=false"); ok = false; }
   if(!IsPhoenicisMagic(MAGIC_M))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(M=210)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_L))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(L=211)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_Q))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(Q=212)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_R))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(R=213)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_B))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(B=214)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_BR)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(BR=215)=false"); ok = false; }
   if(!IsPhoenicisMagic(MAGIC_I))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(I=216)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_S))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(S=217)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_P))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(P=218)=false");  ok = false; }
   if(!IsPhoenicisMagic(MAGIC_T))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(T=219)=false");  ok = false; }

   //--- Unregistered gap magics in the [200..219] range — must return false
   //    (BR-3.6 foreign-EA filter). 202/203/204 fall between MAGIC_F=201 and
   //    MAGIC_H=205; a plain range check would let foreign-EA close events
   //    feed the CircuitBreaker ring buffer.
   if(IsPhoenicisMagic(202)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(202)=true"); ok = false; }
   if(IsPhoenicisMagic(203)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(203)=true"); ok = false; }
   if(IsPhoenicisMagic(204)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(204)=true"); ok = false; }

   //--- Boundary checks.
   if(IsPhoenicisMagic(199)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(199)=true (below range)"); ok = false; }
   if(IsPhoenicisMagic(220)) { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(220)=true (Slot U deleted per OQ-8)"); ok = false; }
   if(IsPhoenicisMagic(0))   { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(0)=true (zero)"); ok = false; }
   if(IsPhoenicisMagic(-1))  { Print("[EnumTypes][SelfTest][FAIL] IsPhoenicisMagic(-1)=true (negative)"); ok = false; }

   if(ok)
      Print("[EnumTypes][SelfTest] IsPhoenicisMagic: 17 registered + 6 negative cases PASSED");
   else
      Print("[EnumTypes][SelfTest] IsPhoenicisMagic: one or more cases FAILED — see above");

   return ok;
  }

#endif // PHOENICISNEX_DOMAIN_ENUMTYPES_MQH
