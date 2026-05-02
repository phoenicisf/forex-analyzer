# ADR-010 — Halted-State Semantic: Exit-Pass-Only

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G2, G4, FR-7.7 (AC-7.7.3, AC-7.7.4), NFR-5.1 |

## Context

EA เดิม CircuitBreaker เรียก `ExpertRemove()` เงียบ (CodeWiki §6.2 P2.3) → user ไม่รู้ว่า EA หายไป + open positions กลายเป็น orphan exposure (no further trailing/SL/TP management). FR-7.7 บังคับ controlled halt ที่:
- Stop เปิด new orders (entry pass)
- Continue exit pass (manageExits ของทุก slot ทำงานต่อ — TP/SL/trailing/cloud-touch logic เดิมยัง manage open positions)
- Emit `Alert()` MT5 native (ไม่ใช่ silent ExpertRemove)
- Stay attached กับ chart (ไม่ unload)

Trigger sources (Must per FR-6.6 + FR-7.6):
1. CircuitBreaker ping-pong (BR-3.6 — same position re-opens within 3000ms)
2. Indicator handle invalid runtime (rare; OnInit fail-fast usually catches)
3. (Phase 2 trigger candidates) — equity-floor enforcement ถ้า user promote OQ-6 → enforce

ต้องตัดสินใจ: state semantic + transition rules + observability

## Options Considered

### Option A — Stop everything (entry + exit) immediately

**Rejected:** open positions ไม่ได้ exit-management → orphan exposure → ขัด G4; AC-7.7.3 บังคับ exit pass ต้องทำงานต่อ

### Option B — Exit-pass-only halted state (chosen)

State machine:
```
RUNNING ──(CircuitBreaker triggered or handle fail)──→ HALTED
HALTED ──(portfolio[*].count == 0)──→ HALTED_STABLE
RUNNING / HALTED / HALTED_STABLE ──(EA reattach by user)──→ RUNNING
```

ทุก state:
- **RUNNING:** F1 OnTick pipeline เต็ม (exit + entry passes)
- **HALTED:** F1 ทำเฉพาะ exit pass + housekeeping (`WatchProfits`, `SaveFileDatabase`, journal); skip entry pass (Step T ใน F1) + skip cross-slot bulk close logic ที่อาจเปิด new orders (EOverload, GOverload — เพราะเปิด new order ขัด halted semantic)
- **HALTED_STABLE:** ปิดหมดแล้ว — emit second Alert "halted, all positions closed" + remain attached + idle

### Option C — Hybrid with operator un-halt input

ให้ user click "resume" ผ่าน input change

**Rejected:** ต้องการ external trigger (UI click) ที่ MT5 input dialog ทำได้แต่ workflow ค่อนข้าง manual; Option B รองรับ "user reattach EA" เป็น natural reset แล้ว

## Decision

เลือก **Option B — Exit-pass-only halted state พร้อม HALTED_STABLE sub-state**

**Concrete contract:**

| Field | Value |
|-------|-------|
| **State enum** | `enum EEAState { RUNNING, HALTED, HALTED_STABLE }` |
| **Persistence** | `state.json § ea_state` field — ผ่าน ADR-007 (state survives restart; user reattach reset to RUNNING) |
| **Reset trigger** | EA OnInit เริ่มใหม่ → state = RUNNING (preserve user MT5 native restart workflow); option ของ "remember halt across restart" = OFF Phase 1 (TD decide config) |
| **Transition observability** | journal `event_type=halt` + `halt_reason` field; journal `event_type=halt_stable` ตอนเข้า HALTED_STABLE |

**OnTick guard (pseudo):**
```mql5
void OnTick() {
   IndicatorService.Refresh();
   MarketContext ctx = MarketContextBuilder.Build(IndicatorService);

   if (CircuitBreaker.CheckPingPong(...)) {
      Halt("circuit_breaker_pingpong");
      // fall through to exit pass below
   }
   if (IndicatorService.AnyHandleInvalid()) {
      Halt("handle_invalid_runtime");
      // fall through to exit pass below
   }

   // Always run exit pass + housekeeping
   PortfolioState.Refresh();
   for each slot in topo_order: slot.ManageExits(PortfolioState);
   CrossSlotCleanup.RunExitOnly(PortfolioState);  // ForceCutloss, Safe-port — exits only
   WatchProfits.Update();

   // Conditionally skip entry pass
   if (eaState == RUNNING) {
      EntryPipeline.Run(ctx, PortfolioState);   // F1 step T
   }

   // Detect HALTED → HALTED_STABLE transition
   if (eaState == HALTED && PortfolioState.TotalActivePositions() == 0) {
      eaState = HALTED_STABLE;
      Alert("PhoenicisNex halted, all positions closed");
      Journal.Write({event_type: "halt_stable", ...});
   }

   StatePersistence.Save();
}
```

**Cross-slot logic in halted state:**
- `OrderGroupStartWorkflow` (Safe port BR-8.1) — **enabled** ใน HALTED (Safe-port = bulk close ของ 10 slots = exit-side action; align กับ AC-7.7.3 "exit pass run" + G4 "no orphan exposure"; per-slot ManageExits ไม่ replace portfolio-wide cleanup ของ Safe-port)
- `OrderGroup#2` (Ichimoku double-bounce BR-8.2) — **enabled** ใน HALTED (close action only)
- `ExtraCheckFunction2` (BR-8.5) — **enabled** ใน HALTED (demote signal — no order)
- `COverload` (BR-8.4) — **enabled** ใน HALTED (cuts CD = exit-side action)
- `EOverload` / `GOverload` (BR-8.4) — **disabled** ใน HALTED (เปิด new order = ขัด halted semantic)
- `ForceCutloss` (BR-8.3) — **enabled** (exit-only action; ตรงตาม halted semantic)
- Pending state machines — **frozen** (ไม่ transition PENDING → EXECUTED ใน HALTED — เพราะ EXECUTED = open new order)

**Revision history:**
- 2026-05-02 (round-01 rebuttal) — Updated Safe-port HALTED behavior to **ENABLED** + enumerated full cross-slot enable matrix (BR-8.1/8.2/8.3/8.5 enabled; BR-8.4 EOverload/GOverload disabled; COverload enabled). Aligns กับ `04 § 9.1` table; resolves ADR-010 ↔ `04 § 9` contradiction (Claim 01.1).

**HALTED_STABLE → user action:**
- User detach EA + reattach = OnInit reset state to RUNNING (current decision)
- Future: input `InpResumeFromHaltOnReattach` (default true) → user toggle ได้ Phase 2

## Consequences

**Positive**
- Open positions never become orphan (G4 contract)
- User aware via Alert (NFR-5.1 — 0 silent shutdowns)
- Restartable via natural MT5 workflow (detach + reattach)
- Journal entries `halt` + `halt_stable` = clear audit trail

**Negative / trade-off**
- Adds 3-state machine + cross-slot enable/disable logic — code complexity moderate
- `EOverload/GOverload disabled in halted` may mean some recovery patterns (ที่ของเดิมจะ trigger) ไม่ทำงาน → OK เพราะ user already in trouble = no new exposure desired
- HALTED_STABLE Alert = สอง popups (halt + halt_stable) — acceptable; user สามารถปิด popup
- Long-running halt + open positions ที่ไม่ปิดเอง + user away = naked window (FR-7.7 known gap line 710); Phase 2 เพิ่ม escalation policy

## Revisit-when

- ถ้า Phase 2 promote OQ-6 (equity-floor enforcement) → integrate equity-floor trigger เป็น halt source #3
- ถ้า user feedback ว่า dual Alert annoying → consolidate to single Alert + status indicator (input panel)
- ถ้าเพิ่ม Telegram/email notification (Phase 2) → escalation policy ใน HALTED state
