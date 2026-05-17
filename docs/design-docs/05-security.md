# 05 — Security & Operational Hardening

> **Phase:** Phase 1B (System Design) — Doc 4/6
> **Author:** Architect agent (`/sd` workflow)
> **Last updated:** 2026-05-17 (BT-002 cascade — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; TL;DR + § 2.5 DoS row "Infinite re-entry loop" + § 3.2 + § 3.3 + § 7.2 halt event row re-author as accepted residual risk + § 9 Red Team Hand-off cap-3 iter audit row. Prior: 2026-05-12 BT-001 cascade — § 6 Operational Risks bug-fix row detection threshold re-anchored to Bucket A rewrite-G4-ON gate per BT-001 re-baseline 2026-05-12)
> **Reads:** `02-high-level-architecture.md`, `03-deep-dive.md`, `docs/ba/03-non-functional-requirements.md § 5 Note`, `docs/ba/04-business-rules.md § 9 Invariants`
> **Audience:** Tech Lead (Phase 1D TD), QA (Phase 3T), Red Team reviewer

## TL;DR

PhoenicisNex security posture แตกต่างจาก typical web/cloud system **อย่างสำคัญ** — เป็น **local-only EA ใน MT5 sandbox** (no network listener, no external API call, no PII transit, no multi-user, no DLLs ตาม NFR-7.2). BA `03 § 5 Note` ระบุ formally ว่า Security NFR category = out-of-scope Phase 1 พร้อมเหตุผล 5 ข้อ + Phase 2 trigger ชัดเจน. เอกสารนี้ทำ **STRIDE analysis** ครบทั้ง 6 categories ในบริบท local EA + ระบุ **operational risks** + **observability strategy** ที่แทนที่ traditional AppSec defenses. **Key points:** (1) Symbol whitelist (FR-1.2) + indicator handle fail-fast (FR-7.6) + controlled halt via `core/EAState` on `IndicatorService::AnyHandleInvalid()` (FR-7.7 + ADR-010 amended BT-002 2026-05-17 — BR-3.6 ping-pong detector removed legacy-parity) เป็น primary safety controls; (2) Trade journal (G2 + ADR-006) provides repudiation defense; (3) Atomic state persistence (ADR-007) defends against tampering via crash-induced corruption.

---

## 1. Threat Model Scope

### 1.1 In-scope assets

| Asset | Storage | Sensitivity |
|-------|---------|-------------|
| `state.json` (pending state, ban dates, WatchProfits) | Local file in MT5 sandbox | Operational — corruption causes EA misbehavior |
| `journal/*.jsonl` (per-event trade audit) | Local file in MT5 sandbox | Operational — primary G2 audit trail |
| MT5 GlobalVariables (WatchProfits worst DD) | MT5-managed | Operational |
| Compiled `.ex5` binary | Local file in MT5 Experts/ | Operational — modifying = different strategy |
| MT5 broker session (FBS-Real account credentials) | MT5 client config (NOT touched by EA) | High — credentials owned + protected by MT5/user, not by EA |

### 1.2 Out-of-scope assets (per BA `03 § 5 Note`)

- Personal data / PII — no transit, no storage
- API keys / secrets — none used (no external API calls)
- Multi-user authentication — solo operator (C-9)
- Network protocols — no listener, no client
- Cloud / remote endpoints — none

### 1.3 Trust boundaries

```mermaid
flowchart LR
    subgraph user["User Boundary"]
        TR[Trader / Owner]
    end
    subgraph host["Windows Host (trusted)"]
        OS[Windows OS<br/>file ACL = user account]
        AV[Antivirus<br/>(may interfere)]
        subgraph mt5["MT5 Process (trusted)"]
            EA[PhoenicisNex EA<br/>+ state.json<br/>+ journal/*.jsonl]
        end
    end
    subgraph broker["FBS Broker (trusted external)"]
        BS[Broker server<br/>order matching]
        IND[Indicator engine<br/>price feed]
    end

    TR -->|UI: input dialog, attach EA| EA
    EA -->|file write/read| OS
    AV -.->|may scan/quarantine| OS
    EA -->|MT5 native API: OrderSend, PositionsTotal| mt5
    mt5 -->|TLS-secured session<br/>(MT5-managed)| BS
    mt5 -->|tick data, indicator| IND

    classDef trust fill:#e6ffe6
    classDef caution fill:#fff4e6
    class user,host,mt5,broker trust
    class AV caution
```

**Key insights:**
- EA does NOT cross any external network boundary directly — MT5 handles broker session; EA only calls MT5 native API
- AV is a "near-trusted" interferer (may lock files / quarantine `.ex5`) — operational concern, not adversary
- All file operations stay within `MQL5/Files/` sandbox enforced by MT5

---

## 2. STRIDE Analysis

ตารางทำ threat enumeration ตาม Microsoft STRIDE framework (Spoofing / Tampering / Repudiation / Information Disclosure / Denial of Service / Elevation of Privilege) ในบริบท PhoenicisNex local EA

### 2.1 Spoofing (impersonating identity)

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| **Attacker copies `.ex5` to victim's MT5 + impersonates strategy** | Low — requires local file system access (= attacker already owns machine) | High in lost-laptop scenario | MT5 broker session credentials separate from EA; EA สามารถ run บน wrong account = trade ขาดทุนได้ แต่ไม่ steal funds (broker withdrawal needs user-side OTP) |
| Attacker spoofs broker server endpoint | N/A — handled by MT5 client TLS pinning | — | — |
| Magic number collision with another EA on same MT5 | Low — magic 200..220 unlikely overlap | Medium — would corrupt PortfolioState | BR-9.4 magic range invariant; user discipline of single-EA-per-account; could add OnInit warning if foreign positions with EA-range magic exist (Phase 2 nice-to-have) |

### 2.2 Tampering (unauthorized modification)

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| **`state.json` corruption mid-write (crash, BSOD)** | Med — ของเดิม EA fragile (CodeWiki §6.2 P2.4) | High — EA misbehaves on reload | **ADR-007 atomic temp+rename** + NFR-3.1 100% kill-100 test |
| `journal/*.jsonl` lines deleted/edited by user/AV | Low — user has no incentive; AV unlikely | Low — journal = audit only, not driver of EA behavior | File ACL inheritance from MT5 sandbox; per-record schema_version + future signed records (Phase 2) |
| Input parameter set to malicious value (e.g., MainRiskRatio = 9999) | High likelihood (typo) | High — could blow account | **FR-1.4 input validation** in OnInit; BootstrapValidator rejects with field/range error |
| Compiled `.ex5` replaced by malware | Low — requires file system access | Critical (= attacker controls trades) | OS-level: user account ACL + AV + Windows Defender; EA-level: nothing (out of scope) |
| Indicator buffer return manipulated by another process | N/A — MT5 sandbox isolates | — | — |

### 2.3 Repudiation (deny action took place)

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| User claims "EA opened wrong order" | High | Medium — operator confidence | **G2 trade journal (FR-4.1, ADR-006)** records every entry/exit with signal_context + indicator_snapshot + triggering_function + parent_ticket_id → full audit trail per-event |
| EA claims order placed but broker has no record | Low | Medium | MT5 ack via OrderSend return; journal `event_type=reject` if broker reject; cross-check via `PositionsTotal` next tick |
| Slot misattribution (e.g., G2 trade credited to G) | Med — shared magic risk | Med | **BR-1.2 comment-prefix disambiguation** + journal `slot_id` field independent of magic |

### 2.4 Information Disclosure

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| Trade strategy revealed to attacker reading source/binary | Low | Low — strategy already in CodeWiki (user's own design) | Code = MQL5 readable; no IP protection by design (user owns strategy) |
| `journal/*.jsonl` reveals account performance to disk reader | Low — local-only | Low — user's own data | NFR file ACL (Windows user account); no PII; no remote exfil path |
| MT5 GlobalVariable readable by other EA on same install | Low — single-EA setup expected | Low | Naming convention prefix `PhoenicisNex_*` (TD lock) to avoid namespace collision |
| Backtest history file (.gz) reveals strategy via reverse-engineering | N/A — user-controlled artifact | — | Not applicable to EA |

### 2.5 Denial of Service

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| **Tick latency overflow → EA misses ticks** | Med — bulk-close burst (ADR-006), slow disk | Med — missed entries / late exits | NFR-2.1/2.2 budgets + degrade-warn-but-continue; `03 § 2 + 4` deep dives |
| Disk full → state/journal write fails | Low | Med — EA enters degraded mode | Logger.Error + Alert; Trade flow continues (in-memory state only); user must free disk |
| Indicator handle exhaustion (MT5 limit ~512) | Low — we use ~25 (TD-locked Phase 1D) | None | Within MT5 native limit |
| **Infinite re-entry loop** (no automated portfolio-level loop guard Phase 1) | Low (legacy `PhoenicisN2.10_stable` 5-yr backtest demonstrates safe operation without one) | High (could blow account; no automated detector) | **Accepted residual risk per BT-002 2026-05-17** (legacy-parity) — operator monitoring + manual EA detach are Phase 1 mitigations; per-slot SL/TP + cross-slot SafePort + RiskManager.ClampLot + force-pending timeouts cap individual exposure. Phase 2 trigger candidates per ADR-010 Revisit-when. → ดู § 9 Red Team Hand-off Notes สำหรับ cap-3 iter chain ADR-013 → ADR-014 audit trail. |
| Pending state file growth → memory exhaustion | Low — bounded by force-clear (ADR-008) | Low | ADR-008 force-clear caps unbounded growth |
| Antivirus locks `state.json` during write | Med | Low-Med — write fails, retry next tick | Logger.Error + retry pattern; user adds MT5 folder to AV exclusion |

### 2.6 Elevation of Privilege

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| EA escapes MT5 sandbox to access OS | N/A — no DLL (NFR-7.2), no `#import` of OS API | — | NFR-7.2 enforces |
| EA opens trade on different account | N/A — bound to MT5 logged-in account | — | MT5 design |
| EA modifies MT5 config | N/A — no `WindowSettings` / `TerminalSetting` write | — | MT5 design |

---

## 3. Defensive Controls Summary

### 3.1 Boot-time defenses (OnInit)

| Control | FR/NFR | Implementation |
|---------|--------|----------------|
| Symbol whitelist | FR-1.2, NFR-5.3 | `BootstrapValidator::ValidateSymbol()` rejects load if `_Symbol != "EURUSD"` (or input list) |
| Input validation | FR-1.4 | `BootstrapValidator::ValidateInputs()` checks ranges, returns INIT_FAILED on bad value |
| Indicator handle fail-fast | FR-7.6, NFR-3.2 | `IndicatorService::CreateHandles()` returns false on any INVALID_HANDLE; orchestrator → INIT_FAILED |
| Topo-sort assertion | BR-2.2 | `SlotRegistry::ValidateTopo()` asserts dependency order at boot |
| State.json integrity | NFR-3.1 | `StatePersistence::Load()` parse + recover orphan tmp; defaults if corrupt |
| Reconcile state vs broker | (recovery) | Compare `SlotState.ticket_ids` vs `PositionsTotal` actual; remove ghosts; log warn |

### 3.2 Runtime defenses (OnTick)

| Control | FR/NFR | Implementation |
|---------|--------|----------------|
| ~~CircuitBreaker ping-pong~~ | ~~FR-6.6~~ | **Removed per BT-002 2026-05-17** — legacy-parity (no automated portfolio-level loop guard Phase 1). HALTED state machine retained via ADR-010 for `IndicatorService::AnyHandleInvalid()` runtime trigger + Phase 2 candidates (equity-floor, journal-sustained-failure). Infinite re-entry loop now accepted residual risk (see § 2.5 DoS row). |
| Time gate spread guard | FR-6.2, BR-3.2, BR-3.7 | `TimeGate::IsMondaySpreadHigh()` blocks entry on Monday morning if `SYMBOL_SPREAD > 10 × DigitMultipier` |
| Morning wakeup gate | FR-6.1, BR-3.1 | `TimeGate::IsMorningWakeup()` blocks entry 00:00–00:05 broker server time (ทุกวัน) |
| Holiday block | FR-6.3 | `TimeGate::IsNewYearSeason2()` blocks entry Dec 21–Jan 3 (no CD active) |
| Per-slot ban cooldown | FR-6.4, BR-3.4 | `SlotState.ban_date` field; `TimeGate::IsBanned(slot)` check |
| Lot cap (LimitMaxLotSizeRatio) | FR-3.6, BR-4.2 | `RiskManager::ClampLot()` caps at `default 2.9 × SYMBOL_VOLUME_MAX`; logs warn |
| Lot floor (SYMBOL_VOLUME_MIN) | BR-4.3 | `RiskManager::ClampLot()` floors at min volume |
| Pending state force-clear | ADR-008 | bounded state growth; `Logger.Warn` on each clear |
| Halted-state semantic | FR-7.7, ADR-010 (amended BT-002) | exit-pass-only after halt; positions managed to closure; no new orders. Phase 1 trigger source = `IndicatorService::AnyHandleInvalid()` runtime check only (BR-3.6 ping-pong detector removed per BT-002 2026-05-17). |

### 3.3 Failure-mode defenses

| Control | FR/NFR | Implementation |
|---------|--------|----------------|
| Atomic state write | NFR-3.1 | ADR-007 temp+rename |
| Tagged structured logger | FR-4.2, ADR-011 | `Logger` central; all errors → Print + Alert (throttled) |
| Trade journal degrade-warn-but-continue | NFR-2.2 | sync write best-effort; warn if slow; never block trade |
| Halt + Alert on any boot fail | NFR-5.1 | INIT_FAILED logged + popup |
| HALTED_STABLE secondary alert | AC-7.7.4, ADR-010 | second Alert when portfolio.count drops to 0 in halted |

---

## 4. Authentication / Authorization

> **Verdict:** Not applicable Phase 1.

EA = single-process, single-user, no network listener — no AuthN/AuthZ surface. MT5 broker session (login, password, server URL) ถูก manage โดย MT5 client + user manual setup. EA inherits authenticated session → any order EA submits = authorized at broker level by MT5 credentials

**Phase 2 trigger** (per BA `03 § 5 Note`): if user adds cloud journal sync, Telegram notifications, multi-account, or remote dashboard → AuthN/AuthZ + transport encryption + key management ต้อง added. Currently 0 attack surface in this category

---

## 5. Encryption / Secret Management

> **Verdict:** Not applicable Phase 1.

- No secrets in EA code (no API keys, no service URLs)
- No PII transit (everything local)
- `state.json` + `journal/*.jsonl` = unencrypted plaintext (operational data only; user owns disk)
- MT5 stores broker password encrypted (out of EA scope)

**Phase 2 trigger:** same as § 4

---

## 6. Operational Risks (non-AppSec)

ความเสี่ยง operational ที่ tradition security framework ไม่จับ — แต่ critical ใน live trading context:

| Risk | Detection | Mitigation |
|------|-----------|------------|
| User leaves PC unattended in HALTED state with open positions | None — solo operator no monitoring service | FR-7.7 known gap (Phase 2 escalation policy: auto-close after N hours, Telegram notification) — documented in `02-functional-requirements.md § FR-7.7` |
| Live spread widens beyond modeled range (FBS event-driven) | EA continues with degraded fills | NFR considers; user accepts at C-8 risk profile |
| User changes input mid-session via input dialog | EA reinit (per MT5 behavior) | NFR-6.1 reattach ≤ 30s; state.json persists across reinit |
| Bug-fix changes (ADR-009 BI SL, BR-7.2 J magic) cut profitable trades unexpectedly | NFR-1.1 Bucket A drift > 25% Net Profit บน rewrite-G4-ON build (G4 fix contribution included per BT-001 2026-05-12) | NFR-1.1 Bucket A gate; NFR-1.8 informational delta sign + magnitude record ถ้า partial G4-OFF window measurable (per BA `03 § NFR-1 Empirical Citation`) — user investigates journal `signal_context` ของ BI/J entries หากตี gate |
| Strategy Tester results diverge from live (slippage / spread) | User compares regression vs live equity | Beyond NFR scope — solo operator manages |
| Long-running EA reveals memory leak / handle leak | MT5 process memory growth observable | OnDeinit `IndicatorService.ReleaseHandles()` + `TradeJournal.Close()` + `StatePersistence.Save()`; reviewer checklist |
| Broker maintenance window mid-tick | EA ack timeout; positions might be in-flight | MT5 retries at platform layer; EA logs reject events; reconcile next tick |

---

## 7. Observability Strategy

### 7.1 Layers

ทุก observable surface visible **เฉพาะ user solo** (no remote monitoring per Won't permanent):

| Layer | What it shows | Source |
|-------|---------------|--------|
| **MT5 Experts log tab** | Tagged messages (DEBUG/INFO/WARN/ERROR) per slot/event/magic | `services/Logger` (ADR-011) |
| **MT5 Alert popup + sound** | Critical events: halt triggers, init failures, force-clear (anti-spam) | `Logger.Error` + AlertWrapper |
| **Trade journal** (`journal/*.jsonl`) | Per-event audit: entry/exit/modify/reject/halt + signal_context + indicator_snapshot | `services/TradeJournal` (ADR-006) |
| **MT5 Strategy Tester report** | Aggregate regression: Net Profit, PF, DD, Sharpe, per-trade list | MT5 native after backtest run |
| **`state.json`** | Live snapshot of pending machines + ban dates + WatchProfits | `services/StatePersistence` (ADR-007) |
| **MT5 GlobalVariable inspector** | Worst DD persisted counters (legacy WatchProfits) | MT5 menu Tools→GlobalVariables |

### 7.2 Key signals to watch

| Signal | Threshold | What it means | User action |
|--------|-----------|---------------|-------------|
| Logger ERROR rate | > 10/min sustained | EA in distress (broker reject, disk error) | Inspect log + Alert popups |
| Journal `event_type=reject` count | > 5/day | Broker rejecting orders (margin, spread, market closed) | Check FBS account margin + market schedule |
| Journal `event_type=halt` | any | Indicator handle invalid runtime (Phase 1 sole trigger source post-BT-002 2026-05-17; CB ping-pong removed). Phase 2 trigger candidates per ADR-010 Revisit-when: equity-floor, journal-sustained-failure | Inspect halt_reason field; restart EA after diagnosis |
| Journal `event_type=pending_force_clear` | any | Pending machine timed out (ADR-008) | Inspect signal_context; if pattern → tune `InpForceClearX_Bars` |
| `WatchProfits.worst_dd` GlobalVariable | > -50% (C-8 risk profile) | Account at user's max DD | Manual halt (detach EA) per OQ-6 monitor-only decision |
| Pending machine `force_clear_count` per slot (cumulative — survives restart per ADR-007) | + 3 new force-clears since last review window | Pending threshold may be too tight | Inspect journal `pending_force_clear` events since last incident; tune `InpForceClearX_Bars` if pattern persists |
| State.json size growth | > 50 KB | State explosion (force-clear not catching) | Inspect pending_payload field; debug |
| `journal_metrics.write_failures` count | > 0/day sustained | Disk health issue / AV interference / permission problem (ADR-006 § Failure handling) | Add MT5 folder to AV exclusion; check disk space; verify file ACL |
| `journal_metrics.consecutive_write_failures` | ≥ 10 | Sustained failure → EA escalates to HALT (ADR-006 RPO contract) | Inspect halt event + journal_metrics fields; resolve disk/permission; restart EA |
| `logger_metrics.throttled_alert_count` (cumulative across restarts per ADR-011) | + 50 new throttle events since last review window | Many sustained ERRORs ที่ Alert ถูก suppress (ADR-011 § Throttle); user อาจ miss critical events | Inspect Experts log tab for throttled (slot,event) patterns; tune `InpAlertOnError` หรือ throttle window if needed |

### 7.3 No-go signals (out of scope per Won't permanent)

- Real-time dashboard (Phase 2)
- Telegram/email/webhook notifications (Phase 2)
- Cloud aggregation / multi-account view (Phase 2)
- APM (Application Performance Monitoring) like New Relic / Datadog (out of MQL5 ecosystem)

---

## 8. Compliance Posture

> **No regulatory compliance in scope.** PhoenicisNex = personal trading tool, single user, single account. No GDPR (no PII), no SOC2 (no service offered), no PCI (no card data), no MiFID (user not licensed financial advisor; trades own account)

If user hosts EA on rented VPS Phase 2 → VPS provider's compliance applies (out of EA scope)

---

## 9. Red Team Hand-off Notes

> **Recommended Red Team focus areas for Phase 1B post-implementation:**

| Focus area | Why investigate | Tool / Approach |
|------------|------------------|------------------|
| Atomic state persistence (NFR-3.1) | Critical safety net; assumption A2 of ADR-007 unverified | Kill MT5.exe × 100 mid-Save; verify state.json integrity |
| Bug fix edge cases (ADR-009) | New SL inheritance code path; unverified vs all market scenarios | Trade journal review of BI events; verify SL distance accuracy |
| Pending force-clear (ADR-008) | New behavior = potential Bucket A drift | Regression QA: count force_clear events; classify true-stuck vs premature |
| Comment parser disambiguation (BR-1.2) | Shared-magic slot misattribution risk | Synthetic test: open positions with edge-case comments; verify parse |
| Input validation completeness (FR-1.4) | Easy place for missing range check | Fuzz-style: try negative, zero, very large values for each input |
| Halted state side effects (ADR-010) | Disabled cross-slot logic might miss valid trigger | Trace HALTED tick: verify exit pass + Safe-port + ForceCutloss work; entry pass + EOverload + GOverload disabled |
| Journal rotation race | Month boundary mid-tick edge | Synthetic: set MT5 clock to month-end + tick across boundary; verify file rotation + no record loss |
| **BT-002 accepted residual risk — infinite re-entry loop** | Phase 1 has no automated portfolio-level loop guard (BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity per BT-002 2026-05-17); per-slot SL/TP + cross-slot SafePort + RiskManager.ClampLot + force-pending timeouts cap individual exposure but cannot detect rapid open/close oscillation across slots. Cap-3 iter chain audit: ADR-013 (iter-1 DEAL_REASON_EXPERT filter — closed broker-driven SL false-positive class) → ADR-014 (iter-2 position_id + event_type dedup — falsified by iter-3 Slot_BI pyramid same-tick close+open class at sim 2021-01-06 Run #5) → BT-002 operator escalation to Option 1 detector removal. Phase 2 escalation candidates per ADR-010 Revisit-when: equity-floor enforcement (OQ-6 promotion) or journal-write sustained-failure escalation | Red Team: synthetic pathological scenario (e.g., bad indicator + tight SL/TP) → verify per-slot caps + SafePort + force-pending bound exposure; calibrate equity-floor threshold if Phase 2 promotion required |

> **End of 05 — Security** — STRIDE 6 categories, defensive controls inventory (boot-time + runtime + failure-mode), operational risks (non-AppSec), observability strategy, no-AuthN/AuthZ + no-encryption rationale, Red Team hand-off (incl. BT-002 accepted residual risk audit trail)
