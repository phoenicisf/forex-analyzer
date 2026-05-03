//+------------------------------------------------------------------+
//|                                              Spike_CSlotBase.mq5 |
//|                                      Copyright 2026, PhoenicisNex|
//| G1 compile + SelfTest harness for IMPL-018 (CSlotBase abstract +  |
//| 2-layer override enforcement per ADR-002, Evolution E2 compile    |
//| prereq for IMPL-019..039).                                         |
//|                                                                  |
//| Coverage:                                                         |
//|   - CSlotBase 6-method contract instantiable + sentinel returns   |
//|   - CSlotRegistry::ValidateTopo() Layer-1 sentinel detection      |
//|   - 4 stub slot shapes (good x2, bad-Magic, empty-SlotId)          |
//|   - 6 SelfTest cases (empty, bad, good-pair, empty-id, overflow, |
//|     PendingState default)                                          |
//|   - Schema match: 6 method signatures vs slot-abstraction-        |
//|     contract.yaml (verified by compile + SelfTest invocation)     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, PhoenicisNex"
#property link      "https://phoenicisnex.com"
#property version   "1.00"

#include "../core/SlotRegistry.mqh"
#include "../services/Logger.mqh"
#include "../services/StatePersistence.mqh"   // resolves CLogger::_SyncThrottle deferred body (IMPL-047 circular-dep bridge — same pattern as Spike_EAState)

CLogger        g_logger;

//+------------------------------------------------------------------+
//| Stub slot shapes — exercise CSlotBase contract surface           |
//+------------------------------------------------------------------+

//--- Good slot A: properly overrides Magic + SlotId; uses CD pool magic
class CGoodStubSlotA : public CSlotBase
  {
public:
   virtual int      Magic()  const override { return MAGIC_CD; }   // 200
   virtual string   SlotId() const override { return "C"; }
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     { /* stub — no real logic; layer-2 enforcement bypassed */ }
   virtual void     ManageExits(CPortfolioState &port) override
     { /* stub */ }
   virtual int      DependsOn(int &out_magics[]) override
     { ArrayResize(out_magics, 0); return 0; }
   //--- PendingState() inherited (default PENDING_STATE_IDLE — verified Case 6)
  };

//--- Good slot B: different magic + SlotId, depends on slot A
class CGoodStubSlotB : public CSlotBase
  {
public:
   virtual int      Magic()  const override { return MAGIC_F; }    // 201
   virtual string   SlotId() const override { return "F"; }
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override
     { /* stub */ }
   virtual void     ManageExits(CPortfolioState &port) override
     { /* stub */ }
   virtual int      DependsOn(int &out_magics[]) override
     {
      ArrayResize(out_magics, 1);
      out_magics[0] = MAGIC_CD;   // F depends on CD pool per BR-2.1
      return 1;
     }
  };

//--- Bad slot: forgets to override Magic() — sentinel -1 must trip Layer 1
class CBadStubSlot : public CSlotBase
  {
public:
   //--- Magic() NOT overridden → CSlotBase default returns -1 (sentinel)
   virtual string   SlotId() const override { return "BAD"; }
   //--- Evaluate / ManageExits / DependsOn NOT overridden either —
   //    layer-2 runtime body would call ExpertRemove(); SelfTest does
   //    not invoke them so the spike completes.
  };

//--- Empty-SlotId slot: overrides Magic but leaves SlotId at sentinel
class CEmptyIdStubSlot : public CSlotBase
  {
public:
   virtual int      Magic()  const override { return MAGIC_M; }    // 210
   //--- SlotId() NOT overridden → CSlotBase default returns ""
   virtual void     Evaluate(const MarketContext &ctx, CPortfolioState &port) override {}
   virtual void     ManageExits(CPortfolioState &port) override {}
   virtual int      DependsOn(int &out_magics[]) override
     { ArrayResize(out_magics, 0); return 0; }
  };

//+------------------------------------------------------------------+
//| OnInit — runs SelfTest then exits via INIT_SUCCEEDED              |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_logger.Init(LOG_DEBUG, false, 0);

   //--- Stack-allocated stubs (caller-owned; SelfTest registries
   //    use SetOwnsSlots(false) so destructors don't double-free).
   CGoodStubSlotA  good_a;
   CGoodStubSlotB  good_b;
   CBadStubSlot    bad;
   CEmptyIdStubSlot empty_id;

   //--- Inject minimum deps (only Logger needed for runtime layer-2
   //    body to log; other 7 service ptrs stay NULL — stub overrides
   //    don't dereference them).
   good_a.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);
   good_b.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);
   bad.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);
   empty_id.Init(NULL, NULL, NULL, &g_logger, NULL, NULL, NULL, NULL);

   //--- 6-method contract spot-check vs slot-abstraction-contract.yaml.
   //    Each call must return without crashing; signature shape
   //    verified at compile time by virtual override resolution.
   if(good_a.Magic() != MAGIC_CD)
     {
      Print("Spike_CSlotBase: good_a.Magic() unexpected = ", good_a.Magic());
      return INIT_FAILED;
     }
   if(good_a.SlotId() != "C")
     {
      Print("Spike_CSlotBase: good_a.SlotId() unexpected = ", good_a.SlotId());
      return INIT_FAILED;
     }
   if(good_a.PendingState() != PENDING_STATE_IDLE)
     {
      Print("Spike_CSlotBase: good_a.PendingState() default broken");
      return INIT_FAILED;
     }
   int deps[];
   if(good_b.DependsOn(deps) != 1 || deps[0] != MAGIC_CD)
     {
      Print("Spike_CSlotBase: good_b.DependsOn() should return [MAGIC_CD]");
      return INIT_FAILED;
     }
   if(bad.Magic() != -1)
     {
      Print("Spike_CSlotBase: bad.Magic() must remain sentinel -1");
      return INIT_FAILED;
     }
   if(empty_id.SlotId() != "")
     {
      Print("Spike_CSlotBase: empty_id.SlotId() must remain sentinel \"\"");
      return INIT_FAILED;
     }

   //--- Run CSlotRegistry SelfTest with the 4 stub shapes
   if(!CSlotRegistry::SelfTest(&g_logger, &bad, &good_a, &good_b, &empty_id))
     {
      Print("Spike_CSlotBase: CSlotRegistry::SelfTest FAILED");
      return INIT_FAILED;
     }

   Print("Spike_CSlotBase: 6-method contract + ValidateTopo Layer-1 OK");
   return INIT_SUCCEEDED;
  }

void OnTick() {}
void OnDeinit(const int reason) {}
