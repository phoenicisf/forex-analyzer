# ADR-010 — Halted-State Semantic: Exit-Pass-Only

| Field | Value |
|-------|-------|
| **Status** | Accepted (amended 2026-05-17 per BT-002 — BR-3.6 ping-pong removed from trigger sources) |
| **Date** | 2026-05-02 (amendment: 2026-05-17 per BT-002) |
| **Deciders** | Architect (Phase 1B) ; amendment authorized by Operator (Kritsana, BT-002) |
| **Goal trace** | G2, G4, FR-7.7 (AC-7.7.3, AC-7.7.4), NFR-5.1 |

## Context

EA เดิม CircuitBreaker เรียก `ExpertRemove()` เงียบ (CodeWiki §6.2 P2.3) → user ไม่รู้ว่า EA หายไป + open positions กลายเป็น orphan exposure (no further trailing/SL/TP management). FR-7.7 บังคับ controlled halt ที่:
- Stop เปิด new orders (entry pass)
- Continue exit pass (manageExits ของทุก slot ทำงานต่อ — TP/SL/trailing/cloud-touch logic เดิมยัง manage open positions)
- Emit `Alert()` MT5 native (ไม่ใช่ silent ExpertRemove)
- Stay attached กับ chart (ไม่ unload)

Trigger sources (Phase 1, post-BT-002 2026-05-17 amendment — Must per FR-7.6 only):
1. ~~CircuitBreaker ping-pong (BR-3.6 — same position re-opens within 3000ms)~~ — **REMOVED per BT-002 2026-05-17** (legacy-parity: `PhoenicisN2.10_stable` achieves $24.27 M / 5-yr baseline without one; cap-3 iter chain ADR-013 → ADR-014 falsified 3 distinct false-positive classes — broker-driven SL same-tick at sim 2021-01-14, EA-driven SafePort mass-close at sim 2021-01-27, BI pyramiding close+open same-tick at sim 2021-01-06; matching key `(magic, dir, Δ≤3s)` structurally incompatible with EA's 16-active-slot concurrency profile)
2. Indicator handle invalid runtime (rare; OnInit fail-fast usually catches) — **Phase 1 sole automated trigger post-BT-002**
3. (Phase 2 trigger candidates) — equity-floor enforcement ถ้า user promote OQ-6 → enforce ; journal-write sustained-failure escalation per ADR-006 RPO contract (`consecutive_write_failures ≥ 10`)

ต้องตัดสินใจ: state semantic + transition rules + observability

## Options Considered

### Option A — Stop everything (entry + exit) immediately

**Rejected:** open positions ไม่ได้ exit-management → orphan exposure → ขัด G4; AC-7.7.3 บังคับ exit pass ต้องทำงานต่อ

### Option B — Exit-pass-only halted state (chosen)

State machine (post-BT-002 2026-05-17 amendment — CircuitBreaker trigger removed; remaining Phase 1 trigger = handle invalid runtime):
```
RUNNING ──(handle fail; Phase 2: + equity-floor / journal-sustained-fail)──→ HALTED
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

**OnTick guard (pseudo, post-BT-002 2026-05-17 — CircuitBreaker.CheckPingPong removed):**
```mql5
void OnTick() {
   IndicatorService.Refresh();
   MarketContext ctx = MarketContextBuilder.Build(IndicatorService);

   // CircuitBreaker.CheckPingPong removed per BT-002 2026-05-17 (legacy-parity)
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
- 2026-05-17 (BT-002 amendment) — **CircuitBreaker BR-3.6 ping-pong removed from Trigger sources** (Option 1 legacy-parity, operator-authorized 2026-05-17). Rationale: cap-3 iter chain ADR-013 → ADR-014 falsified 3 distinct false-positive classes (broker-driven SL same-tick Jan-14, EA-driven SafePort mass-close Jan-27, BI pyramiding close+open same-tick Jan-06); matching key `(magic, dir, Δ≤3s)` structurally incompatible with EA's 16-active-slot concurrency profile; legacy `PhoenicisN2.10_stable.mq5` achieves $24.27 M / 5-yr baseline without a detector. Phase 1 trigger sources reduce to `IndicatorService::AnyHandleInvalid()` runtime check only. ADR-013 + ADR-014 status flipped Accepted → Superseded by BT-002 (preserved as audit history). API spec `trade-journal-schema.yaml` drops `circuit_breaker_pingpong` from `halt_reason` enum. IMPL-051 cancelled in `08 § 1.7`. Cross-slot enable matrix table row removed in `04 § 9.1`.

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

- ถ้า Phase 2 promote OQ-6 (equity-floor enforcement) → integrate equity-floor trigger เป็น halt source #2 (post-BT-002 Phase 1 sole automated trigger = handle-invalid only)
- ถ้า user feedback ว่า dual Alert annoying → consolidate to single Alert + status indicator (input panel)
- ถ้าเพิ่ม Telegram/email notification (Phase 2) → escalation policy ใน HALTED state
- ถ้า BT-002 legacy-parity decision is reversed → re-introduce a portfolio-level loop guard with a structurally-correct matching key (NOT `(magic, dir, Δ)` — use `(position_id, Δ)` or stateful "same logical position closed-then-re-opened" detector per BT-002 § Reason analysis)
