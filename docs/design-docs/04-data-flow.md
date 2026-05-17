# 04 — Data Flow & Major Sequences

> **Phase:** Phase 1B (System Design) — Doc 3/6
> **Author:** Architect agent (`/sd` workflow)
> **Last updated:** 2026-05-17 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; § 1.1 mermaid CB participant + ping-pong alt-branch removed, § 9.1 cross-slot enable matrix row removed. Initial publish: 2026-05-02)
> **Reads:** `02-high-level-architecture.md`, `03-deep-dive.md`, `docs/ba/05-user-flows.md` (BA F1-F7 baseline flows), `docs/adr/*`
> **Audience:** Tech Lead (Phase 1D TD), Implementation Engineer (Phase 3I), QA (Phase 3T)

## TL;DR

เอกสารนี้ map **major flows** ของ PhoenicisNex → SD-level sequence diagrams + **timing budgets ต่อ step** + consistency boundaries + idempotency rules. BA `05-user-flows.md` ระบุ end-to-end behavior (F1 OnTick / F2 Slot Entry / F3 Slot Exit / F4 Pending / F5 Boot / F6 Cross-slot Safety / F7 Trade Journal); SD doc นี้ **เพิ่ม timing/consistency dimensions** ที่ Tech Lead ต้องอ่านก่อน implement. **Key invariants** — MarketContext immutable per tick (no slot can corrupt it), PortfolioState refreshed exactly 1× per tick before exit pass (BR-2.2 ordering), trade journal write is sync best-effort with degrade-warn-but-continue (NFR-2.2 overshoot path). All consistency boundaries listed ใน § 6.

---

## 1. F1 — OnTick Pipeline (Detailed Timing)

ระบุ pipeline หลัก พร้อม per-step budget ตาม `03 § 2.3` table. State HALTED skips entry pass แต่ exit + housekeeping ยังทำ (ADR-010)

### 1.1 Sequence

```mermaid
sequenceDiagram
    autonumber
    participant MT5 as MT5 Platform
    participant Orc as Orchestrator
    participant IS as IndicatorService
    participant MCB as MarketContextBuilder
    participant PS as PortfolioState
    participant TG as TimeGate
    participant Slots as Slots_21_CSlotBase
    participant CSC as CrossSlotCoordinator
    participant PMR as PendingMachineRegistry
    participant PM as PortfolioMonitor
    participant SP as StatePersistence
    participant TJ as TradeJournal

    MT5->>Orc: OnTick()
    Note over Orc: t = 0 us - tick budget 0.10x baseline - baseline TBD per IMPL-065

    Orc->>IS: Refresh() - CopyBuffer x ~25 handles (exact count locked at TD spike Phase 1D)
    Note right of IS: ~200 us

    Orc->>MCB: Build(IS) -> MarketContext (immutable struct)
    Note right of MCB: ~50 us<br/>incl. wpr_wave_signal + adx_force_peak_valid precompute

    Orc->>IS: AnyHandleInvalid()
    alt handle invalid runtime (rare)
        Orc->>Orc: EAState = HALTED
        Orc->>TJ: WriteEvent({event_type: "halt", reason: "handle_invalid_runtime"})
    end

    Orc->>TG: IsMorningWakeup() - block 00:00-00:05 broker server time, FR-6.1 BR-3.1 daily
    alt morning wakeup window
        Note over Orc: skip exit + entry pass, housekeeping only
    end

    Orc->>TG: IsMondaySpreadHigh() - Monday morning + SYMBOL_SPREAD gt 10 x DigitMultipier (FR-6.2, BR-3.2 + BR-3.7)
    alt Monday + high spread
        Note over Orc: skip entry pass, exit pass + housekeeping continue
    end

    Orc->>PS: Refresh() - PositionsTotal loop (single)
    Note right of PS: ~100 us

    Orc->>PMR: TickAll(ctx, PS) - process pending state machines incl. force-clear (ADR-008)

    Note over Orc,Slots: EXIT PASS (always runs even in HALTED)
    loop For each slot in topo-sort order
        Orc->>Slots: slot.ManageExits(PS)
        alt position exists + exit condition met
            Slots->>MT5: PositionClose(ticket)
            Slots->>TJ: WriteEvent({event_type: "exit", ...})
            Slots->>PS: PS will refresh next tick, in-memory hint update
        end
    end
    Note right of Slots: total ~200 us at typical position load (3-5 active)

    Orc->>CSC: RunExitOnly() - ForceCutloss (BR-8.3) + Safe-port check (BR-8.1) + OrderGroup#2 (BR-8.2) + ExtraCheckFunction2 (BR-8.5)
    Note right of CSC: bulk close events -> multiple TJ writes, degrade-warn-but-continue (NFR-2.2)

    alt EAState == RUNNING
        Orc->>TG: HolidayBlock() - IsNewYearSeason2 + CD count
        alt holiday + no CD
            Note over Orc: skip entry pass
        else proceed
            Note over Orc,Slots: ENTRY PASS
            loop For each slot in topo-sort order
                Orc->>Slots: slot.Evaluate(ctx, PS)
                alt signal valid + dependency satisfied + lot >= MIN
                    Slots->>MT5: OrderSend(magic, lot, sl, tp, comment)
                    alt broker ack
                        MT5-->>Slots: ticket
                        Slots->>TJ: WriteEvent({event_type: "entry", ...})
                    else broker reject
                        Slots->>TJ: WriteEvent({event_type: "reject", ...})
                    end
                end
            end
            Note right of Slots: ~100 us typical (most slots fast-path early return)
            Orc->>CSC: RunEntryOnly() - EOverload (BR-8.4) - disabled in HALTED
        end
    end

    Orc->>PM: Update() - WatchProfits worst DD (FR-4.4)
    Note right of PM: ~30 us incremental

    Orc->>SP: Save() - atomic temp+rename (ADR-007)
    Note right of SP: ~800 us

    alt HALTED && PS.TotalActivePositions() == 0
        Orc->>Orc: EAState = HALTED_STABLE (ADR-010)
        Orc->>TJ: WriteEvent({event_type: "halt_stable"})
    end

    Note over Orc: t approx 1685 us steady state - 4685 us with 1 entry event
    Orc-->>MT5: return - wait next tick
```

> **Note (post-BT-002 2026-05-17):** Former `CircuitBreaker::CheckPingPong()` call ที่เคยอยู่ระหว่าง `MarketContextBuilder.Build()` และ `AnyHandleInvalid()` check ถูกลบเป็น legacy-parity. ดู `ADR-010 § Revision history` + `02 § 4.2` Component Catalog removal footer + `backtrack-log.md § BT-002` สำหรับ cap-3 iter chain rationale.

### 1.2 Key insights

- **Pipeline order locks BR-2.2:** exit pass before entry pass; slot evaluate order = SlotRegistry literal order
- **HALTED short-circuit:** entry pass + EOverload skip in HALTED; exit pass + ForceCutloss + Safe-port + ExtraCheckFunction2 + WatchProfits ยังทำ — open positions managed to closure
- **Idempotency surface:** see § 5; key concern = re-process tick data after MT5 restart mid-OnTick (rare; handled by state.json reload + broker as source of truth)
- **Estimated rewrite total ~1.7 ms steady state; ~4.7 ms with 1 event** — overhead delta vs baseline ~1,005 µs (ดู `03 § 2.3` Table B); NFR-2.1 acceptance ผูกกับ measured baseline จาก IMPL-065 — ถ้า baseline ≤ 7 ms → ต้อง mitigate (dirty-bit throttle + log tuning); ถ้า ≥ 10 ms → borderline pass

---

## 2. F2 — Slot Entry Lifecycle

Slot.Evaluate() ลำดับ ตามที่ BA F2.3 ระบุ + SD pin BI special-case (ADR-009) timing

### 2.1 Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Orc as Orchestrator
    participant Slot as Slot_X_CSlotBase
    participant PS as PortfolioState
    participant MC as MarketContext_const_ref
    participant PMR as PendingMachineRegistry
    participant TG as TimeGate
    participant RM as RiskManager
    participant MT5 as MT5 CTrade
    participant TJ as TradeJournal
    participant LOG as Logger

    Orc->>Slot: Evaluate(MC, PS)
    Slot->>Slot: PendingState() check
    alt pending state == PENDING
        Slot->>PMR: delegate to F4 sub-flow (pending machine logic)
        Note over Slot: skip normal evaluate
    else IDLE
        Slot->>TG: IsBanned(slot_ban_date_field)
        alt in cooldown (BR-3.4)
            Slot-->>Orc: return — no order
        end

        Slot->>MC: read indicator fields per slot's signal AND chain (CodeWiki §3)
        alt signal condition fail
            Slot-->>Orc: return — no order
        end

        Slot->>PS: GetByMagic(MagicCD) for J/dependency check (BR-2.1)
        alt dependency missing
            Slot-->>Orc: return — no order
        end

        Slot->>RM: ComputeLot(slot_ctx, account_balance, risk_pct)
        RM-->>Slot: raw_lot
        Slot->>RM: ClampLot(raw_lot, SYMBOL_VOLUME_MAX, SYMBOL_VOLUME_MIN)
        RM-->>Slot: final_lot

        alt slot is BI (FR-3.3 / ADR-009)
            Slot->>PS: GetByMagic(MagicB) → B parent's earliest ticket SL
            alt B parent active + has SL
                Slot->>Slot: ComputeSL = bi_entry ± sl_distance_pip (ADR-009)
            else fallback
                Slot->>Slot: ComputeSL = Bollinger formula (BBBot/BBTop ± 10 pip)
            end
        else
            Slot->>Slot: ComputeSL/TP per BR-5.1
        end

        Slot->>MT5: OrderSend(magic, lot, sl, tp, comment)
        alt broker ack
            MT5-->>Slot: ticket_id
            Slot->>TJ: WriteEvent({entry, slot, magic, ticket, lot, sl, tp, signal_context, indicator_snapshot, parent_ticket_id})
            Slot->>LOG: Info("slot=X", "entry", magic, summary)
            Slot->>PS: in-memory hint update (next Refresh() will reconcile from broker)
            Slot->>Slot: SetBanDate() if applicable (BR-3.4)
        else reject
            MT5-->>Slot: error code
            Slot->>TJ: WriteEvent({reject, slot, magic, error})
            Slot->>LOG: Error("slot=X", "broker_reject", magic, error_msg)
        end
    end
    Slot-->>Orc: return
```

### 2.2 Idempotency considerations

- `OrderSend` is broker-side; if MT5 crashes between send + ack → broker may have placed order ที่ EA ไม่รู้. Recovery: next `PortfolioState.Refresh()` reads `PositionsTotal()` from broker → sees the order; journal will log it as "discovered" event (event_type added to schema for this case)
- BI parent ticket lookup uses `earliest_open` selection — deterministic across restarts (broker-side ticket order persistent)

### 2.3 Timing budget (per slot, average)
- Pending check + signal evaluate fast-path (most common): ~5-10 µs
- Full path with order send: ~500-1500 µs (broker latency dominates)
- 21 slots × 10 µs (no-op) = 210 µs total entry pass — within budget

---

## 3. F3 — Slot Exit Lifecycle

### 3.1 Sequence

```mermaid
sequenceDiagram
    autonumber
    participant Orc as Orchestrator
    participant Slot as Slot_X
    participant PS as PortfolioState
    participant MC as MarketContext_const_ref
    participant MT5 as MT5 CTrade
    participant TJ as TradeJournal
    participant CSC as CrossSlotCoordinator

    Orc->>Slot: ManageExits(PS)
    Slot->>PS: GetByMagic(slot.Magic())
    alt slot is J (BR-7.2 G4 fix)
        Note over Slot: Iterate MagicJ (=206) — NOT MagicF (=201)
    end
    alt active positions exist
        loop For each ticket in slot_state.ticket_ids[]
            Slot->>Slot: filter by comment prefix (BR-1.2 shared-magic disambig)
            Slot->>Slot: check exit condition per CodeWiki §4.2 / BR-5.1
            alt exit condition met (TP / SL / trailing / cloud-touch / wave-peak)
                Slot->>MT5: PositionClose(ticket)
                alt broker ack
                    MT5-->>Slot: closed
                    Slot->>TJ: WriteEvent({exit, slot, magic, ticket, close_reason, triggering_function, indicator_snapshot})
                    alt slot has post-exit hook (BR-2.1)
                        alt slot is G — trigger GOverload (BR-8.4)
                            Slot->>CSC: TriggerGOverload(closing_lot, direction)
                            Note over CSC: GOverload disabled in HALTED (ADR-010)
                        else slot is B — possibly trigger BR (orphan exit per CodeWiki §6.2 P2.2)
                            Slot->>CSC: EvaluateBR_OrphanExit()
                        end
                    end
                else reject
                    Slot->>TJ: WriteEvent({close_reject, slot, magic, ticket, error})
                end
            end
        end
    end
    Slot-->>Orc: return
```

### 3.2 Trailing semantics (BR-5.2)

Slot ∈ {G, GO, M, S} ใช้ "max profit reached + cloud touch" pattern:
- Track `max_profit_pip` per ticket in `SlotState.ticket_max_profit[]` (extension to SlotState struct)
- Each ManageExits pass: update max_profit; if `current_profit_pip ≥ trailing_threshold` AND price touches cloud edge → close
- Persist `ticket_max_profit[]` ใน state.json (FR-5.1) — survives restart

### 3.3 Idempotency considerations

- `PositionClose` ack delivers; if MT5 crashes between close + ack → next refresh reads `PositionsTotal()` → ticket gone → `ticket_id` removed from SlotState; journal `exit_inferred` event added Phase 1 if mismatch detected
- Bulk close from Safe-port (CrossSlotCoordinator) — see F6

---

## 4. F4 — Pending State Machine (with Force-Clear)

ADR-008 lock force-clear thresholds; flow ขยาย BA F4 เพื่อ include force-clear path

### 4.1 State diagram

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> PENDING : signal trigger<br/>(per BR-6.x)<br/>+ pending_started_bar set
    PENDING --> EXECUTED : trigger condition met<br/>(price/Force/band/code)
    PENDING --> IDLE : timeout (legacy: 8/30/40/70 H4 bars per machine)<br/>OR signal flip overwrite
    PENDING --> IDLE : ⚠️ FORCE-CLEAR<br/>m_age_bars >= threshold<br/>(M=150 / T=80 / Q=100)<br/>+ journal pending_force_clear<br/>+ Logger.Warn (anti-spam Alert)
    EXECUTED --> [*] : machine resets to IDLE for next signal
    
    note right of PENDING
        Persisted fields:
        - pending_started_bar
        - pending_payload (JSON string)
        - force_clear_count (cumulative; survives restart per ADR-007)
        Atomic write via ADR-007
    end note
```

### 4.2 Per-machine summary

| Machine | Legacy timeout (bars) | Legacy invalidation | Force-clear (ADR-008) | Storage path |
|---------|----------------------|---------------------|------------------------|--------------|
| C-Pending (BR-6.1) | 8 H4 | none | (no force-clear; legacy timeout enough) | state.json § c_pending |
| C-Pending-ADX (BR-6.2) | 30 H4 | none | (no force-clear) | state.json § c_pending_adx |
| R-Pending (BR-6.3) | 40 H4 | price returns to cloud | (no force-clear) | state.json § r_pending |
| P-Pending (BR-6.4) | 70 H4 | Bollinger violation | (no force-clear; legacy bounded) | state.json § p_pending |
| **M-Pending (BR-6.5)** | **none** legacy | M signal flip | **150 H4 bars** | state.json § m_pending |
| **T-Pending (BR-6.6)** | **none** legacy | confirmation tick | **80 H4 bars** | state.json § t_pending |
| **Q-Pending (BR-6.7)** | **none** legacy | per QPendingCode | **100 H4 bars** | state.json § q_pending |
| Force-Pending (BR-6.8) | 9 H4 | none | (legacy only) | state.json § force_pending |

### 4.3 Consistency boundary

- Pending state mutation = atomic via state.json write (end of OnTick)
- Read = once per tick during `PendingMachineRegistry.TickAll()` invoked from F1 step 6
- ⚠️ Window: between tick boundaries, pending state in RAM is canonical; state.json reflects last-tick value. Crash mid-tick = revert to last-tick state (acceptable per FR-5.2)

### 4.4 P-Pending sub-mode detail (BR-6.4 + CodeWiki §2.5/§3.14)

P-Pending = ที่สุดของ pending complexity ในระบบ — ใช้ multi-stage state machine ที่แตกตาม **decision branch ของ entry calculation** (ไม่ใช่ post-entry timing เหมือน Q-Pending sub-codes). Schema enum `sub_mode: [PX, PH, E, N, null]` map กับ CodeWiki §3.14 ดังนี้:

| `sub_mode` | Trigger / meaning | Schema fields populated | TP ratio | Notes |
|------------|-------------------|--------------------------|----------|-------|
| **`PX`** | Force trigger fast-path: `Force[1]>0.1` AND (recent bar trigger ≤ 8 bars OR `_diffSL ≥ 200` OR `_diffSL ≥ 250` + band gating) | `diff_sl` (entry SL distance pip) | 7 | "X" = Force-driven express path; usually closes faster |
| **`PH`** | Hull/Bollinger default path: `_diffSL < 200` (no Force express) | `diff_sl`, `band_ratio` (Bollinger band ratio) | 15 | "H" = Hull MA + Bollinger structure; standard duration |
| **`E`** | Pyramid extension entry (P_Extra; CodeWiki §3.14 line 640 — comment `"PI,..."`) | `diff_sl` (extension SL) | per-extension formula | "E" = Extra/Extension; second-order Fibonacci pyramid lot calc |
| **`N`** | None / no sub-mode locked yet (transient; pending entered but mode-decision branch ยังไม่ resolve) | none — both null | — | "N" = None; should resolve to PX/PH/E ภายใน ≤ 1 bar; ถ้า stuck = state machine bug → A7 risk |
| `null` | IDLE state (no pending active) | — | — | only valid when `state == IDLE` |

**Field meaning:**
- **`diff_sl`** (number) — SL distance in pip ที่ snapshot ตอน enter pending; ใช้ branch decision (`< 200` → PH; `≥ 200` → PX) + ใช้ตอน execute pending → set actual SL
- **`band_ratio`** (number) — `CalculateBollingerRatio(bid, BBTop, BBBot)` ผลลัพธ์ใน [0..100]; ใช้ band-gating rule (PX requires > 75 ตอน `_diffSL ≥ 250`); PH ใช้ตอน calc TP threshold

**Exit-pending invalidation (BR-6.4):**
- Bollinger violation (price zone breach) → IDLE
- 70 H4 bar legacy timeout (BR-6.4) → IDLE — **no force-clear ใน ADR-008** (legacy timeout sufficient); ถ้า future บ่งชี้ stuck pattern → revisit
- Sub-mode transition: ใน 1 pending lifecycle, sub_mode อาจ flip (เช่น `N` → `PH`) ตาม branch decision; แต่หลัง lock sub-mode แล้ว ห้าม flip (lock-once semantic)

**Acknowledged risk:** A7 (`03 § 7`) — `E`/`N` semantic naming + transition rules ยังต้อง confirm กับ CodeWiki §2.5 ตอน TD Phase 1D (IMPL-034 = XL slot impl). ถ้า discover ว่า schema enum ไม่ครบ → extend `state-persistence-schema.yaml § PendingMachineState_PVariant`

---

## 5. F5 — Boot/OnInit Lifecycle

ขยาย BA F5 เพื่อ include EAState init + IndicatorService validation timing

### 5.1 Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Trader
    participant MT5 as MT5 Platform
    participant EP as Entry_PhoenicisNex_mq5
    participant Orc as Orchestrator
    participant BV as BootstrapValidator
    participant IS as IndicatorService
    participant SR as SlotRegistry
    participant SP as StatePersistence
    participant TJ as TradeJournal
    participant LOG as Logger

    Trader->>MT5: Attach EA to EURUSD H4 chart
    MT5->>EP: OnInit()
    EP->>Orc: instantiate Orchestrator (composition root)
    Orc->>LOG: Initialize Logger (severity: InpLogLevel)
    Orc->>BV: ValidateInputs() - FR-1.4
    alt invalid input (e.g., MainRiskRatio < 0)
        BV->>LOG: Error(field, value, expected_range)
        BV-->>Orc: false
        Orc-->>EP: INIT_FAILED
        EP-->>MT5: INIT_FAILED
        MT5-->>Trader: dialog "EA failed to load"
    end

    Orc->>BV: ValidateSymbol() - FR-1.2 / BR-9.1
    alt _Symbol != "EURUSD"
        BV->>LOG: Error("symbol_mismatch", _Symbol)
        BV-->>Orc: false
        Orc-->>EP: INIT_FAILED
    end

    Orc->>BV: DetectDigitMultipier() - BR-9.3
    BV-->>Orc: ok (typically 10 for FBS)

    Orc->>IS: CreateHandles() - ~25 indicator handles (exact count locked at TD spike Phase 1D)
    loop For each handle
        IS->>MT5: iIchimoku / iForce / iADX / ... return handle
        alt INVALID_HANDLE
            IS->>LOG: Error("handle_invalid", indicator_name, params)
            IS-->>Orc: false
            Orc-->>EP: INIT_FAILED - NFR-3.2 fail-fast
        end
    end
    IS-->>Orc: ok, all N handles valid, N = TD-locked count

    Orc->>SP: Load() - read state.json (or start fresh)
    alt state.json.tmp orphan exists
        SP->>SP: delete orphan + log warn
    end
    alt state.json parse error
        SP->>LOG: Warn("state_corrupt_starting_fresh")
        SP-->>Orc: defaults
    else success
        SP-->>Orc: state populated (pending machines, ban dates, WatchProfits)
    end

    Orc->>SR: RegisterAll() - instantiate 21 CSlotBase derived
    SR->>SR: ValidateTopo() per BR-2.2 - assert evaluation order matches
    alt topo invalid
        SR->>LOG: Error("topo_invalid")
        SR-->>Orc: false
        Orc-->>EP: INIT_FAILED
    end

    Orc->>TJ: Open() - open journal live-or-tester journal-YYYYMM jsonl handle
    TJ-->>Orc: handle ready

    Orc->>Orc: EAState = RUNNING, default ADR-010

    Orc->>LOG: Info system init_ok, N handles, 21 slots, state loaded, EURUSD whitelisted - N = TD-locked indicator handle count
    Orc-->>EP: INIT_SUCCEEDED
    EP-->>MT5: INIT_SUCCEEDED

    MT5->>EP: First OnTick -> F1 begins
```

### 5.2 Tester mode branch

If `MQLInfoInteger(MQL_TESTER) == true`:
- Skip MT5 GlobalVariable network calls (CodeWiki §5.4 — preserve baseline)
- Tester journal namespace: `journal/tester/run-<ISO>.jsonl` (ADR-006)
- Skip Alert (popup ใน tester ไม่มีผล); Logger still emits via Print

### 5.3 Recovery scenarios

| Scenario | OnInit behavior |
|----------|------------------|
| Fresh boot (no state.json) | StatePersistence.Load() returns defaults; first tick begins normal |
| Reboot after clean shutdown | Load state.json; pending machines + ban dates + WatchProfits restored fully |
| Crash recovery (state.json.tmp orphan) | Delete orphan; load state.json (= pre-crash state per ADR-007 atomic guarantee) |
| Crash recovery (state.json corrupted — defense-in-depth fail) | Log error + warn `state_corrupt_recovered_via_gv`; start fresh ของ pending machines + ban dates; **last-resort: read MT5 GlobalVariable subset** (`worst_drawdown_*`, `equity_high_water_mark`) เพื่อ recover WatchProfits (per `02 § 6.1.1` Sync rule); user inspects journal for context |

---

## 6. Consistency Boundaries

ตารางรวบ invariants ของ data consistency ที่ Tech Lead ต้อง enforce:

| Invariant | Scope | Enforcement |
|-----------|-------|-------------|
| `MarketContext` immutable per tick | All slots same tick | `const MarketContext &ctx` ใน slot Evaluate/ManageExits signature; struct value semantic (copy on pass) |
| `PortfolioState` refreshed exactly 1× per tick before exit pass | Pipeline ordering | F1 step `H` (PortfolioState.Refresh) calls `PositionsTotal()` once; subsequent slot reads use cached SlotState |
| Slot evaluation order = literal SlotRegistry order = topo-sort | Per-tick across slots | `SlotRegistry::ValidateTopo()` boot-time assertion; reviewer enforces literal order match BR-2.2 |
| Trade journal record sequence = call order ใน same tick | Single-tick burst | Single-thread MQL5 + sync write — guaranteed by design |
| `state.json` aligned with broker truth | EA reload | Reconcile at OnInit Load: compare loaded `SlotState.ticket_ids` vs `PositionsTotal` actual; remove tickets ที่ broker ไม่มี (closed during downtime) — log warn for each |
| Comment prefix discipline (BR-1.2) | Shared-magic slots (G/G2, B/BI, C/D, L/LX) | `helpers/CommentParser` central module; per-slot `BuildComment()` enforces prefix |
| Pending state transition atomic to file | Cross-tick crash window | End-of-tick `StatePersistence.Save()` is atomic (ADR-007); intra-tick changes in RAM only |
| `state.json` canonical, `MT5 GlobalVariable` mirror | Dual-source-of-truth (WatchProfits subset) | Sync direction = state.json → GV (one-way push หลัง Save); state.json wins on Load (per `02 § 6.1.1` Sync rule); recovery from corrupt state.json + intact GV → defaults + GV last-resort hint for `worst_drawdown_*` fields only |

---

## 7. Idempotency Rules

| Operation | Idempotency strategy |
|-----------|----------------------|
| `OrderSend` retry after timeout | NOT idempotent at broker — EA does not retry on send fail; logs reject + moves on. If MT5 crash between send+ack → broker may have placed order; recovery reads `PositionsTotal` next tick |
| `PositionClose` retry after timeout | NOT idempotent at broker — same as above; recovery via PositionsTotal scan |
| State persistence write (per-tick) | Idempotent — atomic temp+rename overwrites prior; no log of state mutations needed (state.json IS the canonical truth) |
| Trade journal append | NOT idempotent (append-only); strictly forward-only; if same tick re-runs (impossible in single-thread MQL5) → duplicate event |
| Pending machine transition | Idempotent within tick (re-evaluation gives same result); cross-tick = guarded by `pending_started_bar` field (force-clear deterministic) |
| EAState transition | Latest-write-wins; HALT triggers OR-merge (any source can halt); HALTED_STABLE detection only when count == 0 |
| Indicator handle creation in OnInit | Idempotent — if handle exists from prior `OnInit` call (e.g., parameter change), reuse; release on OnDeinit |

---

## 8. Trade Journal Write Sequence (FR-4.1 + ADR-006)

```mermaid
sequenceDiagram
    autonumber
    participant Caller as Slot / CrossSlot / Halt logic
    participant TJ as TradeJournal
    participant MC as MarketContext_const_ref
    participant PS as PortfolioState_const_ref
    participant LOG as Logger
    participant FS as MQL5/Files/PhoenicisNex/journal/

    Caller->>TJ: WriteEvent(event_type, slot_id, magic, ticket, lot, price, sl, tp, comment, signal_context, parent_ticket_id)
    Note right of TJ: t = 0 µs

    TJ->>MC: read indicator subset relevant to slot
    MC-->>TJ: snapshot fields

    TJ->>PS: read portfolio summary (total_lots, equity, slot_counts)
    PS-->>TJ: summary

    TJ->>TJ: BuildRecord(...) — ~50 µs<br/>incl. timestamp (broker server ms precision)

    TJ->>TJ: SerializeJson(record) → "{...}\n" — ~100 µs

    TJ->>TJ: RotateIfNeeded() — month boundary check (live mode only)
    alt rotation needed
        TJ->>FS: FileClose(old) + FileOpen(new monthly-named) — no rename per ADR-006/Claim 01.14
    end

    TJ->>FS: FileWriteString(handle, line)
    Note right of FS: ~500-2000 µs Windows local SSD

    TJ->>FS: FileFlush(handle)
    Note right of FS: ~500-2000 µs disk write-through

    TJ->>TJ: elapsed = now - t_start
    alt elapsed > 5000 µs
        TJ->>TJ: m_overshoot_window.Add(elapsed)
        alt overshoot pattern (≥ N in M ticks)
            TJ->>LOG: Warn("system", "journal_slow", 0, "p95 > 5ms")
        end
    end

    TJ-->>Caller: return — non-blocking
    Note over TJ,Caller: degrade-warn-but-continue per NFR-2.2
```

**Burst handling (Safe-port closes 10 positions in 1 tick):**
- 10 sequential `WriteEvent` calls; each ~1-3 ms = 10-30 ms total
- Exceeds 5 ms NFR-2.2 budget per tick → degrade-warn-but-continue triggered
- Logger emits warn; tick continues; no record dropped, no order operation blocked (per ADR-006 RPO contract: 0 events lost on slow disk; only sustained-failure scenario drops events)

**Sustained failure escalation (per ADR-006 § Failure handling RPO contract):**
- Per-event write fail (disk full / permission / handle invalid) → drop event + increment `journal_metrics.write_failures` ใน state.json
- ถ้า `consecutive_write_failures ≥ 10` → `EAState.Halt("journal_write_fail_sustained")` (ADR-010) → entry pass disabled, exit pass continue (managed-to-closure preserves G4)
- Monitoring signal ใน `05 § 7.2`: `journal_metrics.write_failures > 0/day sustained` → user investigate disk health / AV exclusion

---

## 9. Cross-slot Safety Flow (F6)

ขยาย BA F6 เพื่อ pin HALTED behavior. ADR-010 § "Cross-slot logic in halted state" คือ authoritative; ตารางนี้ mirror ADR ตรงๆ

### 9.1 RUNNING / HALTED enable matrix

| Helper (BR ref) | RUNNING | HALTED | Reason |
|-----------------|---------|--------|--------|
| ~~CircuitBreaker check~~ | n/a | n/a | **Removed per BT-002 2026-05-17** — BR-3.6 ping-pong detector deleted (legacy-parity; cap-3 iter chain ADR-013 → ADR-014 falsified 3 false-positive classes; `PhoenicisN2.10_stable` achieves $24.27 M / 5-yr baseline without a detector). Halt trigger now reduces to `IndicatorService::AnyHandleInvalid()` runtime guard (always evaluated, both RUNNING + HALTED) + Phase 2 candidates per ADR-010 Revisit-when. |
| ForceCutloss CD (BR-8.3) | ✅ | ✅ | exit-side action; ตรง halted semantic |
| ExtraCheckFunction2 (BR-8.5) | ✅ | ✅ | demote signal — no order |
| Safe-port (BR-8.1) bulk close 10 slots | ✅ | ✅ | bulk close = exit-side action; per-slot ManageExits ไม่ replace portfolio-wide cleanup; align AC-7.7.3 + G4 |
| OrderGroup#2 (BR-8.2) bulk close | ✅ | ✅ | close action only |
| COverload (BR-8.4) — cuts CD | ✅ | ✅ | exit-side cut |
| EOverload (BR-8.4) — adds CD order | ✅ | ❌ | open new order = ขัด halted semantic |
| GOverload (BR-8.4) — opens GO inverse | ✅ post-exit hook | ❌ | open new order = ขัด halted semantic |
| Pending machines transition PENDING → EXECUTED | ✅ | ❌ frozen | EXECUTED = open new order |

---

## 10. Flow Coverage vs BA F1-F7

| BA flow | SD coverage | Additional dimension added in SD |
|---------|-------------|-----------------------------------|
| F1 OnTick pipeline | § 1 | per-step timing budget (200 µs / 50 µs / 800 µs / etc.); HALTED state machine integration |
| F2 Slot entry | § 2 | BI ADR-009 SL pip arithmetic timing; idempotency for OrderSend retry semantics |
| F3 Slot exit | § 3 | trailing state persistence (ticket_max_profit[]); J slot magic-fix call site |
| F4 Pending state | § 4 | force-clear path (ADR-008); per-machine threshold table; force_clear_count metric |
| F5 OnInit boot | § 5 | tester mode branch; reconcile state.json vs broker truth on Load |
| F6 Cross-slot safety | § 9 | per-step RUNNING/HALTED enable matrix; ADR-010 alignment |
| F7 Trade journal | § 8 | timing breakdown (50/100/500-2000/500-2000 µs); rotation handling; degrade-warn-but-continue trigger |

> **End of 04 — Data Flow** — 5 detailed flows + consistency boundaries (7) + idempotency rules (7) + cross-flow timing budgets aligned with NFR-2.1/2.2
