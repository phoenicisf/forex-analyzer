# Code Review Round 09

| Field | Value |
|-------|-------|
| **Round** | 09 |
| **Target** | `services/CrossSlotCoordinator.mqh` (full 857 LOC) — landed across IMPL-053 (skeleton + RunSafePort), IMPL-055 (RunForceCutloss), IMPL-056 (ExtraCheckFunction2), IMPL-054 (RunOrderGroup2), IMPL-058 (HALTED enable-matrix audit + SelfTest C26-28). Cross-references read: `services/PortfolioState.mqh::GetTicketsForSlot` (still stubbed at line 356-366 — IMPL-007 deferred), `services/TradeJournal.mqh § JournalEvent struct` (lines 25-46), `docs/api-specs/trade-journal-schema.yaml § triggering_function enum` (line 173-181), `domain/MarketContext.mqh § DerivedSignals` (line 67-71), `domain/SlotState.mqh` (buy_count/sell_count fields). |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~857 LOC (entire new file). 5 IMPL tasks since R08 — single service surface (CrossSlotCoordinator), no slot/orchestrator/entry changes. Cumulative reviewed surface (R01..R09): ~8,160 LOC. |
| **Plan Staleness Sentinel** | 5 closures since R08 (IMPL-053/054/055/056/058) — well below 10-closure threshold; plan approval (2026-05-02) is 2 days old. No re-review of plan needed. |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **7** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | No `WebRequest` / external `#import` / hardcoded creds. EURUSD whitelist enforced inside `_AggregateWeakMetrics` (line 250). `CTrade` is service-layer (allowed per ea.md). |
| 2 | Business Logic Correctness | ⚠️ Finding | `_AggregateWeakMetrics` does not filter by magic — counts ALL EURUSD positions on terminal incl. non-PhoenicisNex magics (Finding 09.1 HIGH). Trigger fires + emits "_triggered" log even when `_CloseSlotGroup` closes 0 positions because `GetTicketsForSlot` is still a stub returning 0 (Finding 09.2 HIGH). |
| 3 | Error Handling | ⚠️ Finding | `m_trade.SetTypeFilling()` never called → close may fail on broker without default `RETURN` filling — silently logged as `*_close_fail` but no remediation (Finding 09.3 MEDIUM). NULL-guards on `m_portfolio` / `m_logger` consistent. |
| 4 | Performance | ✅ Pass | One pass over `PositionsTotal()` per call; bulk-close target table is 11 entries; no N+1 against PortfolioState (uses GetTicketsForSlot once per target). |
| 5 | Over-Engineering | ⚠️ Finding | `m_risk` (CRiskManager*) injected via Init() but never read — dead dependency (Finding 09.4 MEDIUM). `RunOrderGroup2` evaluates `ichi_active` twice — once as quick-out (line 436), again inside `_OrderGroup2Triggered` (line 416) (Finding 09.6 LOW). |
| 6 | Cross-Service Consistency | ✅ Pass | `triggering_function` strings ("OrderGroupStartWorkflow", "OrderGroupStartWorkflow2", "ForceCutloss") all present in `trade-journal-schema.yaml § triggering_function` example list (line 179). `event_type="exit"` matches schema enum. Magic enum constants (MAGIC_CD/J/H/...) consumed via EnumTypes.mqh. |
| 7 | Test Coverage Gaps | ⚠️ Finding | SelfTest 28 cases cover predicates + truth tables + NULL guards + halt round-trip — solid for unit-side. Missing: real-portfolio fixture for `_CloseSlotGroup` (cannot exercise on stub `GetTicketsForSlot`); deferred to Orchestrator IMPL-059+. `_AggregateWeakMetrics` magic-filter (Finding 09.1) untestable until SelfTest gets a `PositionsTotal`-fixture or magic-set knob. (Finding 09.5 MEDIUM) |
| 8 | Architecture Compliance | ✅ Pass | Layer 5-direction OK (services/ → domain/ + helpers/ + Logger). ADR-010 enable-matrix table verbatim in header banner; matches `docs/design-docs/04-data-flow.md § 9.1` row-for-row. ADR-002 composition-root (Init injection) used. ADR-006 journal write goes through CTradeJournal::WriteEvent (no FileWrite from this layer). |
| 9 | TD Compliance | ⚠️ Finding | TD-02 §5.11 declares `void RunSafePort(const MarketContext&)`; impl returns `int` per IMPL-053 S-AC #3 — deviation logged in header banner ✅. But the returned `slots_closed_count` semantically counts **per-ticket close calls** (incremented inside `_CloseSlotGroup` per ticket loop) — not "slot groups closed" as the variable name + S-AC text imply (Finding 09.7 LOW). |
| 10 | Test Code Quality | ✅ Pass | SelfTest cases each have explicit fail-Print + early return; no `while(true)`; no shared mutable state across cases (each rebuilds local `MarketContext bare`); per-test runtime O(1). No regex use. |
| 11 | Empirical AC Closure | ✅ Pass | Forbidden-pattern grep on `impl-plan.md` for IMPL-053..058 returns 0 hits for "deferred to operator-runtime" / "deferred to post-launch operator phase" / "structurally complete.*deferred". Each task's deferred E-ACs registered in `deferred-ac-registry.md` with ≤14d expiry + risk-if-missed (e.g., IMPL-058 row added 2026-05-04 expiry 2026-05-18 for live `[ev=overload_skipped_halted]` log assertion). Evidence artifacts present at `_session-handoff/IMPL-{053,054,055,056,058}-evidence-20260504.md` — each documents G1 PASS + SelfTest pass + G2/G3/G4 N/A justification per IMPL-018+ header-only precedent. |
| 12 | Functional CRUD Walk | ⏭ Skip | EA project — Tier 1.5 walk = headless backtest + Tester log + journal audit per CLAUDE.md §1; deferred until IMPL-059+ runnable surface (Orchestrator + entry .mq5). Per CrossSlotCoordinator's design (header-only consumer), this is the correct disposition. |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; CrossSlotCoordinator consumes no env var / secret / API key / connection string. Threshold constants (`SAFEPORT_AVG_BAD_PIP_MIN=55.0` etc.) are `#define` baked at compile per CodeWiki §5.5 baseline — not runtime config. |

---

## Findings

### Finding 09.1: 🟠 HIGH — `_AggregateWeakMetrics` ไม่ filter ตาม magic — นับ position ของ EA อื่น / manual trade รวมเข้าใน BR-8.1 trigger

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 229-272
- Service: ea (CrossSlotCoordinator)

**Code:**
```mql5
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
   ...
   total_pl += pl;
   if(signed_pip < 0.0) { weak_count++; sum_bad_pip += MathAbs(signed_pip); }
  }
```

**Problem:**
Loop filters เฉพาะ `_Symbol == "EURUSD"` แต่ไม่มี `if(magic ∉ PhoenicisMagics) continue;`. ถ้าเครื่องเดียวกันมี EA อื่น (e.g., second-instance PhoenicisNex บน MAGIC ต่าง / manual broker order / FBS social-trading copy) เปิด position EURUSD ค้างไว้ → position พวกนั้นจะถูก ทำให้ `weak_count` + `sum_bad_pip` + `total_pl` เพิ่มและ trigger BR-8.1 SafePort + BR-8.2 OrderGroup2 + (ทาง BR-8.3) ForceCutloss-CD ผิดบริบท. ถ้า aggregate ทำให้ `_SafePortTriggered(weak,avg,pl)=true` แล้ว `_CloseSlotGroup` ก็จะ enumerate เฉพาะ PhoenicisNex magic ของตัวเอง ทำให้ trigger ของ BR-8.1 ถูก fire **โดย position ที่ไม่ใช่ของ EA นี้เลย** — false-positive bulk close.

CodeWiki §5.5 baseline (อ้างใน `_OrderGroup2Triggered` comment) นับเฉพาะ "weakOrderCount ของ portfolio ตัวเอง" ไม่ใช่ของแพลตฟอร์ม.

**Why This Matters:**
NFR-5.3 ("Symbol whitelist") กับ "portfolio ownership" เป็นสองเรื่อง — `_Symbol` filter ป้องกันแค่ cross-pair leakage แต่ไม่ป้องกัน cross-EA leakage. ใน solo-operator + single-EA = no real impact วันนี้, แต่ FBS-Real บางครั้ง operator เปิดทดสอบ second-instance / copy-trade signal ค้างไว้ — และ BR-8.1 ออกแบบมาให้ trigger เฉพาะ "weak order ของ EA นี้". Worst case = SafePort ปิด BR-8.1 target slots (C/D/J/H/K/L/M/Q/GO/T/S) ทั้งกลุ่มเพราะ position ของ EA อื่นทำให้ avg_bad_pip > 55.

**Suggested Fix:**
```mql5
// Add magic-set filter — only PhoenicisNex own magics count toward weak_count/total_pl
long mg = PositionGetInteger(POSITION_MAGIC);
if(m_portfolio != NULL && m_portfolio.GetByMagic((int)mg) == NULL) continue;  // not our magic
```
Or pull canonical magic-set from `PortfolioState::IsKnownMagic(int)` (helper to add). Update SelfTest C7 to add a "foreign magic position" fixture once `IsKnownMagic` lands.

**Level of Effort:** Low (3 lines + 1 PortfolioState accessor + 1 SelfTest case)

---

### Finding 09.2: 🟠 HIGH — RunSafePort/RunOrderGroup2/RunForceCutloss emit "_triggered" log แต่ปิด 0 ticket เพราะ `GetTicketsForSlot` ยัง stub return 0

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 305-359 (`_CloseSlotGroup`), 493-555 (`_CloseCDPositionsInLoss`), 367-401 (`RunSafePort`), 430-460 (`RunOrderGroup2`), 564-578 (`RunForceCutloss`)
- Cross-reference: `services/PortfolioState.mqh:356-366` (`GetTicketsForSlot` stub returns 0, IMPL-007 deferred)
- Service: ea

**Code:**
```mql5
// _CloseSlotGroup line 312-316
ulong tickets[];
int n = m_portfolio.GetTicketsForSlot(magic, slot_prefix, tickets);
if(n <= 0) return 0;   // <- always 0 today (stub)

// RunSafePort line 388-398
int slots_closed_count = 0;
for(int i = 0; i < target_n; i++)
   slots_closed_count += _CloseSlotGroup(targets[i].magic, ...);  // = 0 every call

m_logger.Info("xslot", "safe_port_triggered", 0,
              StringFormat("slots_closed=%d weak=%d ...", slots_closed_count, ...));
```

**Problem:**
`PortfolioState::GetTicketsForSlot` is the canonical SoT for ticket enumeration but currently returns `0` (stub, IMPL-007 deferred to IMPL-053+). All three bulk-close methods route closure through it → `_CloseSlotGroup` short-circuits at line 314 → no `m_trade.PositionClose` ever issued → no journal `event_type=exit` ever written. Yet **the `Info` log "safe_port_triggered" / "order_group_2_triggered" / "force_cutloss_triggered" still fires** with `slots_closed=0` claiming an event happened.

This is an observability lie: under any G3 headless backtest where `_AggregateWeakMetrics` legitimately counts > 1 weak position with avg_pip > 55 + pl > 0 (which Finding 09.1 above also makes more likely), the Tester log will record "safe_port_triggered slots_closed=0" — readers will interpret "trigger fired = bulk close happened" but **no positions were actually closed**. The header banner of `_AggregateWeakMetrics` (lines 222-228) acknowledges the stub gap but the `Run*` callers do not — they emit the same triumphant log either way.

CLAUDE.md §1 + `andm-impl-engineer/SKILL.md § Empirical Closure Discipline` require evidence text to match AC text; emitting `_triggered` events that did not actually trigger any close violates the empirical contract for IMPL-053/054/055 deferred E-ACs (`[log-assertion]` + `[db-inspect]` rows in registry).

**Why This Matters:**
QA Phase 3T (IMPL-061..068) will assert on these `_triggered` events as proof of BR-8.1/8.2/8.3 — false-positive log = silent regression that can only be caught by also asserting on actual broker-side close events (which currently are absent). Worse: when IMPL-007 lands GetTicketsForSlot fully, the same trigger condition will suddenly start closing real positions while operator (reading recent history) thought the trigger was already producing closes. Surprise behavior = NFR-5.1 violation (no silent surprises).

**Suggested Fix:**
Either guard the log on actual close count, or fail loud:
```mql5
// RunSafePort
if(slots_closed_count <= 0)
  {
   // Either short-circuit silently, or log at Warn so the gap is visible
   m_logger.Warn("xslot", "safe_port_no_op", 0,
                 StringFormat("triggered_but_zero_close weak=%d avg_bad_pip=%.1f pl=%.2f stub=GetTicketsForSlot",
                              weak_count, avg_bad_pip, total_pl));
   return 0;
  }
m_logger.Info("xslot", "safe_port_triggered", 0, /* existing message */);
```
Apply same pattern to `RunOrderGroup2` + `RunForceCutloss`. Drop the Warn once IMPL-007 lands and SelfTest fixture asserts a real close > 0.

**Level of Effort:** Low (3 × 5-line guard insertion)

---

### Finding 09.3: 🟡 MEDIUM — `m_trade.SetTypeFilling()` never called — `PositionClose` may fail under FBS broker filling-policy that rejects default `RETURN`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 102 (`CTrade m_trade;` member), 191-204 (`Init` — only Init() body, no `m_trade.SetTypeFilling*` call), 325 (`m_trade.PositionClose(tk)` first use)
- Service: ea

**Code:**
```mql5
//--- Init body (line 191-204) — no m_trade configuration
void CCrossSlotCoordinator::Init(...)
  {
   m_portfolio = port;
   ...
   // CTrade defaults are sufficient (filling-policy detected per-call inside MT5)
  }

// _CloseSlotGroup line 325
bool ok = m_trade.PositionClose(tk);
if(!ok && m_logger != NULL)
   m_logger.Warn("xslot", comment_tag + "_close_fail", magic, ...);
```

**Problem:**
The header comment claims "filling-policy detected per-call inside MT5" — that is **incorrect for `<Trade\Trade.mqh>`**. `CTrade` defaults `m_type_filling = ORDER_FILLING_FOK` (or `RETURN` on some MT5 builds) and uses it verbatim in every `OrderSend` it builds (incl. for `PositionClose`). MT5 does not auto-detect from `SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)` — that detection is the **caller's** responsibility (per `mql-developer` SKILL § "Filling policy: detect via `SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)`" and per `.claude/rules/ea.md` MQL5/MT5-specific idiom #4).

FBS-Real (per CLAUDE.md §2 — broker baseline) supports IOC + RETURN + FOK depending on symbol mode; if SYMBOL_FILLING_MODE for EURUSD on a given account/server combination doesn't include FOK, every PositionClose will return `TRADE_RETCODE_INVALID_FILL` → `Warn` log fires + position stays open → BR-8.1 SafePort trigger fires but **achieves nothing**.

Pairs poorly with Finding 09.2 — even after IMPL-007 lands `GetTicketsForSlot`, this filling-policy gap will be the next failure layer.

**Why This Matters:**
BR-8.1 ("emergency safe-port bulk close") existing for risk-mitigation purposes — silent failure under specific broker filling-mode is exactly the failure class we cannot afford. Production NFR-5.1 ("no silent halt / no silent failure") requires either successful close OR an Alert escalation, not a `Warn` lost in Tester log.

**Suggested Fix:**
```mql5
void CCrossSlotCoordinator::Init(...)
  {
   ...
   //--- Detect filling policy per BR-1.5 + ea.md MQL5 idiom
   long fm = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fm & SYMBOL_FILLING_IOC) != 0)      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else if((fm & SYMBOL_FILLING_FOK) != 0) m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else                                     m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   m_trade.SetExpertMagicNumber(0);  // we identify by ticket, not magic
  }
```
Long-term: extract to shared `helpers/TradeFactory.mqh` so RiskManager + CrossSlotCoordinator share the same detection. Consider escalating `*_close_fail` to `Error` (which triggers Alert per ADR-011) instead of `Warn`.

**Level of Effort:** Low (5 lines in Init)

---

### Finding 09.4: 🟡 MEDIUM — `m_risk` (CRiskManager*) member injected via Init but never read — dead dependency expanding API surface

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 60 (`#include "RiskManager.mqh"`), 98 (`CRiskManager *m_risk;`), 108 (`m_risk(NULL)` ctor), 113-117 (`Init` signature), 200 (`m_risk = rm;`)
- Service: ea

**Code:**
```mql5
#include "RiskManager.mqh"   // line 60 — only consumer below is dead-write to m_risk

class CCrossSlotCoordinator
  {
private:
   CRiskManager     *m_risk;     // line 98 — never read

public:
   void Init(CPortfolioState *port,
             CTradeJournal *tj,
             CLogger *lg,
             CRiskManager *rm,    // line 116 — accepted but unused
             CPipMath *pip);
  };

void CCrossSlotCoordinator::Init(..., CRiskManager *rm, ...)
  {
   ...
   m_risk = rm;   // line 200 — written, never read
  }
```

**Problem:**
`grep -n "m_risk\." services/CrossSlotCoordinator.mqh` returns 0 hits — the field is set but never dereferenced. The bulk-close paths instantiate `CTrade m_trade` directly (line 102) and call `m_trade.PositionClose` (lines 325, 521), bypassing RiskManager entirely. This is consistent with TD-02 §5.11 (CrossSlotCoordinator owns its own CTrade for bulk-close primitives), so RiskManager is a true non-dependency.

ea.md § Architecture Rules: "no dead code / no premature abstraction"; root CLAUDE.md "Don't add features … beyond what the task requires." Leaving `m_risk` as dead injection (a) wastes the Composition Root injection slot, (b) lies about CrossSlotCoordinator's dependency graph (Orchestrator IMPL-059 will think it must wire RiskManager *first* to construct CrossSlotCoordinator), and (c) adds a mandatory `#include "RiskManager.mqh"` that compiles in ~600 LOC of unrelated header.

**Why This Matters:**
ADR-002 Composition Root pattern relies on the Init() signature documenting **actual** dependencies — IMPL-059 Orchestrator wiring will read this signature as truth. A dead `CRiskManager*` parameter forces IMPL-059 to construct/pass RiskManager before CrossSlotCoordinator even when no functional reason exists, adding 1 layer of init-ordering coupling that is purely fictional. When IMPL-059 lands and the team "finds" it doesn't need RiskManager here, they will either delete the param (creating a fix-round task) or keep the dead injection forever (codifying technical debt).

**Suggested Fix:**
Drop the param + member + include:
```mql5
// Remove from class:
//   CRiskManager *m_risk;
// Remove from ctor init list:
//   m_risk(NULL),
// Remove from Init signature:
//   CRiskManager *rm,
// Remove from Init body:
//   m_risk = rm;
// Remove #include "RiskManager.mqh"
```
Update `spike/Spike_CrossSlotCoordinator.mq5` Init() call site (1 line) to drop the now-unused arg. If a future BR-8.x sub-task genuinely needs lot-sizing through RiskManager, re-introduce as part of *that* task.

**Level of Effort:** Low (5 line deletions across 1 file + 1 spike)

---

### Finding 09.5: 🟡 MEDIUM — SelfTest `_AggregateWeakMetrics` + `_CloseSlotGroup` + `_CloseCDPositionsInLoss` have zero coverage of the close-path

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 660-855 (SelfTest)
- Service: ea

**Code:**
```mql5
// SelfTest covers:
//   C3-C7   — _SafePortTriggered truth table + target table
//   C8-C13  — _ForceCutlossSignal truth table + NULL/zero guards
//   C14-C19 — _IsCDDemoteCondition truth table + NULL guard
//   C20-C25 — _OrderGroup2Triggered truth table + NULL guard
//   C26-C28 — halted toggle reach-without-crash
// Uncovered:
//   _AggregateWeakMetrics  — no fixture for PositionsTotal()
//   _CloseSlotGroup        — no fixture for GetTicketsForSlot return
//   _CloseCDPositionsInLoss — only NULL/zero-signal coverage (C12, C13);
//                              real signal=+1 path with non-empty fixture untested
```

**Problem:**
SelfTest is rigorous on *predicates* (12 truth-table cases between SafePort/ForceCutloss/Demote/OrderGroup2 gates) but the **actual close path** — where the real bugs of Finding 09.1 (magic filter), 09.2 (stub return), 09.3 (filling policy) live — has zero structural coverage. C12/C13 only verify NULL-portfolio + zero-signal early-returns, not the real iteration loop.

`andm-code-reviewer/SKILL.md § Phase 0 Code Review Attack Vector Checklist` Dimension 7 ("Test Coverage Gaps") + Dimension 11 ("Empirical AC Closure Verification") both demand: where E-AC is structurally deferred, structural test must exercise *what can be exercised today* — including loop-path behaviour against an in-memory fixture that simulates GetTicketsForSlot returning ≥1 ticket.

This gap is what allowed Finding 09.2 to slip past 5 task closures.

**Why This Matters:**
Each `IMPL-053..056-evidence-20260504.md` cites SelfTest pass as primary structural evidence; when IMPL-007 lands and the close-path actually runs, any defect there will be caught only by IMPL-061..068 QA Phase 3T — i.e., 7+ tasks downstream. Closer-to-source defect detection is the cheaper path.

**Suggested Fix:**
Add a SelfTest fixture pattern: introduce a `CPortfolioStateFake` (or temporary friend-class hook) that lets SelfTest stub `GetTicketsForSlot` to return a fixed array `{1001, 1002}` without needing a real broker. Then add:
- C29: `_CloseSlotGroup(MAGIC_C, "C,", "OrderGroupStartWorkflow", "safe_port")` against fake → expect `closed == 2` even if actual `PositionSelectByTicket` fails (count `closed++` is unconditional per current code).
- C30: `_CloseCDPositionsInLoss(+1)` against fake CD pool → expect counter increment matches in-loss BUY-direction fixture entries.
Alternatively, register this gap in `deferred-ac-registry.md` as P4 row "CrossSlotCoordinator close-path empirical exercise" expiry tied to IMPL-007 landing.

**Level of Effort:** Medium (fake portfolio class + 2 SelfTest cases — ~80 LOC)

---

### Finding 09.6: 🔵 LOW — `RunOrderGroup2` evaluates `ichi_active` twice (quick-out at line 436 + inside `_OrderGroup2Triggered` at line 416)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 430-443
- Service: ea

**Code:**
```mql5
void CCrossSlotCoordinator::RunOrderGroup2(const MarketContext &ctx)
  {
   if(m_portfolio == NULL || m_logger == NULL) return;

   //--- Quick out: derived ichi flag is the dominant gate
   bool ichi_active = ctx.derived.ichi_double_bounce_active;
   if(!ichi_active) return;                          // <-- first eval

   int weak_count = 0; double sum_bad_pip = 0.0; double total_pl = 0.0;
   _AggregateWeakMetrics(weak_count, sum_bad_pip, total_pl);

   if(!_OrderGroup2Triggered(ichi_active, weak_count)) return;  // <-- ichi re-checked inside
  }

bool CCrossSlotCoordinator::_OrderGroup2Triggered(bool ichi_active, int weak_count) const
  {
   if(!ichi_active) return false;                                // <-- second eval (dead given the quick-out)
   if(weak_count <= ORDER_GROUP_2_WEAK_ORDER_MIN) return false;
   return true;
  }
```

**Problem:**
The quick-out at line 436 already guarantees `ichi_active == true` by the time `_OrderGroup2Triggered` is called → the `if(!ichi_active)` branch inside the predicate is dead under the only call site. The predicate's `ichi_active` parameter exists only so the SelfTest cases C20/C21/C22/C23/C24 can exercise the truth-table without a MarketContext fixture (good design intent) — but the production path now duplicates the gate. Tiny over-engineering.

**Why This Matters:**
Two truths to keep in sync ≠ better than one. If a future caller adds `RunOrderGroup2_VariantB` that wants to skip the quick-out and rely on the predicate alone, the call sites diverge silently.

**Suggested Fix:**
Drop the quick-out + always pass through `_OrderGroup2Triggered`:
```mql5
void CCrossSlotCoordinator::RunOrderGroup2(const MarketContext &ctx)
  {
   if(m_portfolio == NULL || m_logger == NULL) return;

   int weak_count = 0; double sum_bad_pip = 0.0; double total_pl = 0.0;
   _AggregateWeakMetrics(weak_count, sum_bad_pip, total_pl);

   if(!_OrderGroup2Triggered(ctx.derived.ichi_double_bounce_active, weak_count)) return;
   ...
  }
```
The single extra `_AggregateWeakMetrics` call when `ichi_active=false` is negligible (single position-loop pass) and consolidates the gate to one place. Or keep the quick-out and assert internally; either is fine — *both* in current form is the smell.

**Level of Effort:** Low (3 line deletion)

---

### Finding 09.7: 🔵 LOW — `slots_closed_count` semantically counts per-ticket close calls, not "slot groups closed" as the variable name + S-AC #3 imply

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh`, Lines: 305-359 (`_CloseSlotGroup` returns close-call count), 388-393 + 446-453 (callers accumulate as `slots_closed_count`)
- Service: ea

**Code:**
```mql5
// _CloseSlotGroup line 316-331
int closed = 0;
for(int i = 0; i < n; i++)
  {
   ...
   bool ok = m_trade.PositionClose(tk);
   ...
   closed++;     // <-- incremented per ticket regardless of ok
  }
return closed;

// RunSafePort line 388-393
int slots_closed_count = 0;
for(int i = 0; i < target_n; i++)
   slots_closed_count += _CloseSlotGroup(...);   // sums tickets across 11 targets
```

**Problem:**
IMPL-053 S-AC #3 ("Returns per-call summary for journal record") + the variable name `slots_closed_count` both suggest the return value is "how many of the 11 target slot-groups had ≥1 close issued". Actual implementation sums ticket-close calls — so a SafePort firing on a portfolio with `{C: 3 tickets, J: 2 tickets, M: 1 ticket}` returns `6` not `3`. The header banner (line 47 "S-AC #3 Returns per-call summary") doesn't disambiguate.

The Logger line `slots_closed=%d` (line 396) reinforces the misreading.

**Why This Matters:**
Downstream operator dashboards / journal aggregation (FR-3.4 retrospective audit) will read `slots_closed=6` and report "SafePort closed 6 slot-groups" — when actually it closed 6 *tickets* across 3 groups. Not catastrophic but exactly the audit-vs-reality drift NFR-1.6 (per-slot trade count baseline) is supposed to prevent.

**Suggested Fix:**
Either (a) rename the variable + log key to `tickets_closed_count` / `tickets_closed=%d` to match semantics, or (b) change `_CloseSlotGroup` to return `1` when ≥1 ticket closed, `0` otherwise, to match the name. Option (a) is less invasive:
```mql5
int tickets_closed_count = 0;
for(int i = 0; i < target_n; i++)
   tickets_closed_count += _CloseSlotGroup(targets[i].magic, ...);

m_logger.Info("xslot", "safe_port_triggered", 0,
              StringFormat("tickets_closed=%d weak=%d ...", tickets_closed_count, ...));
```
Apply same renaming to `RunOrderGroup2`.

**Level of Effort:** Low (4 line renames + 1 log key change × 2 callers)

---

## Cross-Service Issues

None new — `triggering_function` enum strings cross-checked against `docs/api-specs/trade-journal-schema.yaml § triggering_function` (line 173-181), all three new values ("OrderGroupStartWorkflow", "OrderGroupStartWorkflow2", "ForceCutloss") present. `event_type="exit"` matches schema.

ADR-010 enable-matrix in code header banner (lines 29-40) is a row-for-row copy of `docs/design-docs/04-data-flow.md § 9.1` — verified consistent.

`MAGIC_*` constants consumed via `EnumTypes.mqh` (no hardcoded magics on file).

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 09.1 | 🟠 HIGH | Business Logic | `_AggregateWeakMetrics` ไม่ filter by magic — นับ position EA อื่น | CrossSlotCoordinator.mqh:229-272 | Low |
| 09.2 | 🟠 HIGH | Business Logic | `Run*` emit "_triggered" log แต่ปิด 0 ticket เพราะ GetTicketsForSlot stub | CrossSlotCoordinator.mqh:367-578 | Low |
| 09.3 | 🟡 MEDIUM | Error Handling | `m_trade.SetTypeFilling()` never called — close may fail under FBS filling-mode | CrossSlotCoordinator.mqh:191-204, 325, 521 | Low |
| 09.4 | 🟡 MEDIUM | Over-Engineering | `m_risk` injected but never used — dead Composition Root dependency | CrossSlotCoordinator.mqh:60, 98, 116, 200 | Low |
| 09.5 | 🟡 MEDIUM | Test Coverage | SelfTest covers predicates but zero close-path coverage | CrossSlotCoordinator.mqh:660-855 | Medium |
| 09.6 | 🔵 LOW | Over-Engineering | `RunOrderGroup2` evaluates `ichi_active` twice (quick-out + predicate) | CrossSlotCoordinator.mqh:430-443 | Low |
| 09.7 | 🔵 LOW | TD Compliance | `slots_closed_count` counts tickets not slot-groups (semantic mismatch) | CrossSlotCoordinator.mqh:388-401, 446-460 | Low |

---

## Recommendation

**Ready for fix-round-09.** No CRITICAL findings — IMPL-053..058 surface is structurally sound and matches ADR-010 enable matrix verbatim. The 2 HIGH findings (09.1 + 09.2) are both **observability/correctness traps** that will materialize into real defects the moment IMPL-007 lands `GetTicketsForSlot` body and IMPL-059 wires Orchestrator + entry .mq5; fixing them now (combined ~15 LOC) prevents both from surfacing as latent QA Phase 3T failures.

**Fix priority order:** 09.2 (log lies — 5 min, blocks no-op observability) → 09.1 (magic filter — 5 min, prevents false-positive trigger) → 09.3 (filling policy — 5 min, prevents broker reject) → 09.4 (dead m_risk — 5 min, simplifies IMPL-059 wiring) → 09.5 (SelfTest fixture — register as deferred-AC tied to IMPL-007 landing instead of fixing inline) → 09.6, 09.7 (cosmetic).
