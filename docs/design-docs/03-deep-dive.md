# 03 — Deep Dive: Critical Technical Challenges

> **Phase:** Phase 1B (System Design) — Doc 2/6
> **Author:** Architect agent (`/sd` workflow)
> **Last updated:** 2026-05-17 (BT-002 cascade + Round 08 cite sync — BR-3.6 CircuitBreaker ping-pong detector removed legacy-parity; § 1.3 outline + § 1.5 Validation re-frame post-BT-002, § 2.3 Table A/B −5 µs annotation, § 6 Decision Justification row L334 label sync to canonical "HALTED state machine (HALTED / HALTED_STABLE)" per Round 08 Claim 08.2 (mirror `02 § 8` Glossary post-rebuttal-05 merge). Prior: 2026-05-12 BT-001 cascade — Challenge 1 § 1.3 Impl outline row + § 1.5 Bucket A/B validation re-framed to rewrite-G4-ON single-pass per BT-001 re-baseline 2026-05-12)
> **Reads:** `02-high-level-architecture.md`, `docs/adr/*`, `docs/ba/03-non-functional-requirements.md`
> **Audience:** Tech Lead (Phase 1D TD), Implementation Engineer (Phase 3I), QA (Phase 3T)

## TL;DR

เอกสารนี้ลงรายละเอียด **5 critical technical challenges** ที่ architecture ของ PhoenicisNex ต้องผ่าน — แต่ละ challenge เกิดจาก hard constraint ของระบบ (single-process EA, behavioral parity, sub-tick latency budget, crash-safe persistence, pending state stuck). ทุก challenge format = **Problem → Approach → Implementation outline → Failure modes → Validation**. **Key trade-off ที่ reader ต้องรู้:** behavioral parity (G3) บีบให้ทุก architectural choice มี measurable performance budget — เปลี่ยน semantic 1 จุด อาจ cascade เป็น Bucket A drift > 25% Net Profit; ทุก deep-dive จึง pair กับ QA validation step.

---

## 1. Challenge 1 — Behavioral Parity Preservation

### 1.1 Problem

EA เดิม 22,016 LOC monolith มี **17+ slots overlap + comment-string state schema + global variable swarm + 18+ helper families** (CodeWiki §6.2 P1.6). Behavior ของแต่ละ trade decision เกิดจาก interaction ของ slot logic + RiskManager helpers + cross-slot signal globals. Rewrite ที่เปลี่ยน semantic เพียงเล็กน้อย — เช่น indicator query timing, comment parser tolerance, pending state transition order — สามารถ cascade เป็น **Bucket A drift > 25% Net Profit** ที่ NFR-1.1 จะ fail

Specifically dangerous transitions:
- Slot evaluation order (BR-2.2 lock C → D → J → ... → BI → S → T → P) — เปลี่ยน 1 swap = different `PortfolioState` visible to downstream slot
- `MarketContext` field naming/typing — slot ที่อ่าน wrong field = silent wrong-direction trade
- Comment parser regex ของ shared-magic disambiguation (BR-1.2) — tolerance drift = trade journal credit ผิด slot
- Pending state transition timing — early/late by 1 H4 bar = different EXECUTED outcome

### 1.2 Approach: Translation discipline + per-slot golden test

ใช้ **3-layer defense** เพื่อ pin behavior:

1. **Direct translation rule** — ทุก slot file เริ่มจาก CodeWiki §3 spec ของ slot นั้น + `BusinessLogic_<X>` + `ExtraTakeProfit_<X>` source ของเดิม → translate เป็น `Slot_<X>::Evaluate()` + `Slot_<X>::ManageExits()` แบบ line-by-line; ห้ามเพิ่ม optimization (ยกเว้น FR-8.1 cache, FR-8.2 incremental DD ที่ behavior preserve)
2. **Per-slot baseline trade count check** (NFR-1.6 + AC-2.1.2) — QA Phase 3T extract per-slot count จาก `ReportTester-25045474.html` (parser tool); regression run หลัง rewrite → diff ต่อ slot; flag slot ที่ drift > 30%
3. **Trade journal cross-validation** — journal entry มี `triggering_function` + `signal_context` + `indicator_snapshot` field (FR-4.1) → QA filter ว่า signal pattern ตรงกับ baseline pattern (e.g., slot G ที่เปิด trade ตอน Force ascending → snapshot field = positive force)

### 1.3 Implementation outline

| Discipline element | Owner | When |
|--------------------|-------|------|
| Per-slot CodeWiki §3 → `Slot_<X>.mqh` translation rubric | TD Phase 1D | per-slot doc |
| `wpr_wave_signal` + `adx_force_peak_valid` precomputed in MarketContextBuilder (avoid timing drift) | ADR-004 | Implementation phase |
| Comment parser unit-style spike (Strategy Tester scenario) | TD Phase 1D | spike before lock |
| Per-slot regression tolerance table | QA Phase 3T | extract from baseline |
| Bucket A measurement (rewrite-G4-ON build, single-pass per BT-001 2026-05-12) absorbs G4 fix contribution; NFR-1.8 informational delta optional. Post-BT-002 (2026-05-17, BR-3.6 detector removed) `DISABLE_G4_FIXES` build runs to natural-end of measurement window — no early halt artifact constrains the delta sample. | QA Phase 3T | per-fix observability (informational) |

### 1.4 Failure modes

| Failure mode | Detection | Mitigation |
|--------------|-----------|------------|
| Slot evaluation order shuffled (e.g., reviewer swap C and D) | Topo-sort assertion in `SlotRegistry::ValidateTopo()` (boot-time fail) + per-slot count drift | Lock literal order in `SlotRegistry::RegisterAll()` source; reviewer checklist |
| MarketContext field renamed mid-translation | Compile-time fail (slot reads `ctx.field_X` that ไม่ exist) | Schema lock at `docs/api-specs/marketcontext-snapshot-schema.yaml` — TD update YAML before code change |
| Comment parser tolerance drift (e.g., trim whitespace differently) | Per-slot trade journal credit disagrees with baseline order list | Centralize in `helpers/CommentParser` + spike vs baseline comment samples |
| Pending state transition order drift (e.g., evaluate price first vs check timeout first) | Regression run shows slot trade count drift | Per-machine class explicit `OnTick(SlotState&)` method with documented step order matching CodeWiki §2.5 |
| Indicator query during slot evaluate gets newer data than during MarketContextBuilder | ADR-004 const ref enforce; `MarketContext` is value-typed (copy on pass) — impossible after build | N/A by design |

### 1.5 Validation

- **Bucket A target:** ≤ 25% Net Profit drift (NFR-1.1) บน rewrite default build (G4 fixes ON, single-pass per BT-001 2026-05-12, G4 fix contribution included) — primary acceptance
- **Per-slot:** ≤ ±15% trade count drift, > 30% = investigate (NFR-1.6)
- **Bucket B:** Informational delta (NFR-1.8) `rewrite-G4-ON − rewrite-G4-OFF` — sign + magnitude ของ G4 fix contribution; **no acceptance gate** (Should priority post-BT-001 2026-05-12). Post-BT-002 (2026-05-17, BR-3.6 detector removed) the `DISABLE_G4_FIXES` build runs to natural-end of measurement window — full-window G4 contribution measurable if forensic toggle retained at `#ifdef DISABLE_G4_FIXES` guards inside `Slot_J::ManageExits()` + `Slot_BI::ComputeSL()` (per ADR-009 G4 fix toggle pattern). Portfolio-level PF (NFR-1.2 ≤ 0.2 drop) + Max DD (NFR-1.5 ≤ +10pp) gate via Bucket A measurement
- **Test environment:** FBS-Real Build ≥ 5833, $1k init, 1:500 leverage, 1-min OHLC tick model 0% real (per `trading-baseline.md`); 5-yr period 2021.01.03 → 2025.12.30

---

## 2. Challenge 2 — Tick Latency Budget (NFR-2.1)

### 2.1 Problem

NFR-2.1 = **avg tick latency overhead ≤ 10%** vs original EA + ≤ 20% at p95 + ≤ 30% at p99. ที่ FBS server tick rate (volatile market 5-20 ticks/sec EURUSD), budget เข้มงวดมาก

Architecture overhead sources ที่ rewrite **เพิ่มขึ้น** vs EA เดิม:
- 21 virtual call (`slot.Evaluate()`) × 2 passes/tick = 42 virtual calls
- MarketContext struct copy ~720 bytes × 21 slots = ~15 KB/tick
- CHashMap lookup overhead per slot (`PortfolioState.GetByMagic()`)
- JSON-Lines journal serialization per event
- Atomic state file write per tick
- Tagged logger string construction per log message

ถ้าทุกอย่างซ้อนกัน อาจเกิน 10% budget → NFR-2.1 fail

### 2.2 Approach: Quantified budget per pipeline stage

แตก budget เป็น stage-level allowance + measured baseline ของ stage นั้น (ผ่าน TD spike); ถ้า stage ใดเกิน budget → re-architect stage นั้นโดยเฉพาะ

### 2.3 Implementation outline — Pipeline budget tables

> **Original EA tick latency baseline:** ⚠️ **TBD ใน TD spike Phase 1D (IMPL-065 measurement protocol)** — `~7 ms` ที่อ้างใน round 0 draft = engineering guess (ตาม "5-10 ms/tick avg ใน Strategy Tester 1-min OHLC model" rough estimate) ที่ยังไม่ได้วัด. NFR-2.1 acceptance gate ผูกกับ **measured baseline** — ตารางด้านล่างให้ engineering estimate ของ rewrite cost; reconcile กับ baseline หลัง IMPL-065 จริง

#### Table A — Rewrite total tick budget (steady state, 0 events)

| Pipeline stage (F1) | Estimated cost | Source category |
|----------------------|----------------|-----------------|
| `IndicatorService::Refresh()` (CopyBuffer × ~25 handles, TD-locked) | 200 µs | preserve EA เดิม `iCustom`+`CopyBuffer` cost (~150-200 µs) |
| `PortfolioState::Refresh()` (PositionsTotal loop) | 100 µs | preserve EA เดิม `ReadTradeData` cost (~80-100 µs) |
| Exit pass — 21 slots × ManageExits (no-op fast path) | 200 µs | preserve baseline (slot exit logic + 21 × 50 ns virtual call ≈ 1 µs trivial) |
| Cross-slot exit-side cleanup (ForceCutloss, Safe-port check, ExtraCheckFunction2) | 50 µs | preserve EA เดิม cost |
| Entry pass — 21 slots × Evaluate (fast-path early return) | 100 µs | preserve baseline (most slot Evaluate ~5 µs no-signal early return; 21 × 5 = 105 µs) |
| `WatchProfits::Update()` (PortfolioMonitor) | 30 µs | preserve baseline + FR-8.2 incremental savings |
| `MarketContextBuilder::Build()` (~50 field struct populate + 2 precompute) | 50 µs | **new in rewrite** — pure assignment + `wpr_wave_signal` + `adx_force_peak_valid` precompute |
| `StatePersistence::Save()` (serialize ~5 KB JSON + atomic temp+rename) | 800 µs | **new explicit cost** — estimated ~500-1000 µs Windows local SSD |
| Logger overhead (15 messages/tick avg) | 150 µs | **new in rewrite** — tagged structured logger (ADR-011) |
| **Rewrite total (steady state, 0 events)** | **~1,680 µs** | sum ของทุก row (post-BT-002: −5 µs from former `CircuitBreaker::CheckPingPong()` removal) |
| **Rewrite total (1 entry event tick)** | **~4,680 µs** | + 1 × ~3 ms journal write + Logger.Info |
| **Rewrite total (10-event bulk close tick)** | **~31,680 µs** | over budget — degrade-warn-but-continue (NFR-2.2) |

#### Table B — Overhead delta vs baseline (NFR-2.1 ≤ 10% gate)

> NFR-2.1 ceiling = **0.1 × measured baseline**. Sum ของ "added cost" rows ต้อง ≤ ceiling

| Stage (added by rewrite) | Added cost | Notes |
|--------------------------|------------|-------|
| `MarketContextBuilder::Build()` | 50 µs | new struct copy + precompute |
| `StatePersistence::Save()` (per-tick) | 800 µs | new atomic write (EA เดิม flat write ~100-200 µs → delta ~600-700 µs) |
| Logger overhead (15 msgs/tick) | 150 µs | new tagged logger |
| Slot virtual call overhead (21 × 50 ns × 2 passes/tick) | ~2 µs | ADR-002; trivial |
| **Sum of added overhead (steady state)** | **~1,002 µs** | ⚠️ **เกือบหมด NFR-2.1 budget headroom ของ 7 ms baseline (~700 µs ceiling)** — ต้อง measure ใน IMPL-065 ก่อนยืนยัน (post-BT-002: −5 µs from former CB safety helper removal) |

> **Implication ของ Table B math:** ถ้า measured baseline = 7 ms → ceiling 700 µs → **fail** (1,002 µs > 700 µs); ถ้า baseline = 10 ms → ceiling 1,000 µs → **borderline pass**. Mitigation paths ที่จะ activate ถ้า fail:
>
> 1. **Dirty-bit throttle** ของ `StatePersistence::Save()` — write เฉพาะตอน state เปลี่ยน (estimated savings ~500-700 µs ในตอน steady state)
> 2. **Log-level tuning** — default `InpLogLevel = INFO`; ถ้า over budget → INFO sampling หรือ DEBUG suppress
> 3. **Virtual dispatch → static dispatch** — switch-on-enum ของ slot iterate ลด virtual call overhead (revisit ADR-002)
> 4. **MarketContextBuilder lazy fields** — populate เฉพาะ field ที่ slot ใน topo iterate ใช้

### 2.4 Failure modes

| Failure mode | Detection | Mitigation |
|--------------|-----------|------------|
| `StatePersistence::Save()` exceeds 800 µs (slow disk / antivirus scan) | NFR-2.1 measurement (TD spike) | Throttle: write only if state changed (dirty bit); fall back to write every N ticks if dirty rate low |
| Bulk-close burst (Safe-port closes 10 positions) > 30 ms | NFR-2.2 monitoring | Already designed: degrade-warn-but-continue; emit Logger warn if N consecutive overshoots |
| `MarketContextBuilder` add field doubles copy size | Code review + ADR-004 5 KB ceiling | Schema review at YAML; if > 5 KB → switch to pointer pass |
| Virtual call inlining fails in MQL5 compiler | Spike measurement of 42 virtual calls | If measured > 100 µs total → revisit ADR-002 (use static dispatch via switch on enum) |
| Logger emit > 50 messages/tick (developer over-log) | Code review of `Logger::Debug` usage | `InpLogLevel` default = INFO; Debug suppressed unless explicitly enabled |

### 2.5 Validation

Per NFR-2.1 measurement protocol (BA-locked):
- Instrumentation: timestamp at OnTick start + end ของทั้ง EA เดิมและ rewrite
- Sample size: ≥ 5,000 ticks in regression period
- Aggregation: avg + p95 + p99
- Pass/fail: rewrite avg ≤ 110% of original avg, p95 ≤ 120%, p99 ≤ 130%

---

## 3. Challenge 3 — Atomic State Persistence (NFR-3.1)

### 3.1 Problem

NFR-3.1 = **0% corruption หลัง random kill 100 รอบ** ระหว่าง state write. EA crash mid-write จาก:
- MT5 client crash (rare)
- Windows BSOD / power loss
- User force-quit MT5
- Antivirus quarantine

EA เดิมใช้ flat write (CodeWiki §6.2 P2.4) — high corrupt risk. Rewrite ต้อง guarantee `state.json` อยู่ใน 2 state เท่านั้น: ก่อน-write หรือ หลัง-write ครบ (ไม่มี partial)

State coverage: 7 pending state machines + 5 ban dates + B-snapshot + WatchProfits worst DD + cross-slot signal globals (~5 KB JSON serialize)

### 3.2 Approach: Atomic temp+rename ผ่าน NTFS guarantee

Per ADR-007: write ลง `state.json.tmp` → flush → `FileMove(tmp, target, FILE_REWRITE)` ที่ MT5 sandbox map ไป Windows `MoveFileEx` ที่ NTFS atomic guarantee

### 3.3 Implementation outline

```
StatePersistence::Save() pseudocode:
1. snapshot = SerializeAllState() → string (JSON)
2. handle = FileOpen("state/state.json.tmp", FILE_WRITE | FILE_TXT | FILE_ANSI)
3. FileWriteString(handle, snapshot)
4. FileFlush(handle)
5. FileClose(handle)
6. FileMove("state/state.json.tmp", "state/state.json", FILE_REWRITE)
   → Windows MoveFileEx atomic on same volume
7. If any step fails → log Error + alert; do not corrupt existing state.json
```

Recovery path (OnInit):
```
1. If state/state.json.tmp exists → orphan from prior crash; delete + log warn
2. If state/state.json exists → parse; if parse error → log error, fall back to defaults, mark state.invalid for QA
3. Else → start fresh; log "first boot or state cleared"
```

### 3.4 Failure modes

| Failure mode | Detection | Mitigation |
|--------------|-----------|------------|
| ⚠️ MT5 sandbox `FileMove` is **not** atomic (e.g., implements as copy+delete) — assumption A2 of ADR-007 | TD spike (IMPL-046): kill MT5 mid-FileMove × 20; check state.json integrity | **Activate ADR-007 Option B** (3-file double-buffered swap; designed-but-not-primary in ADR-007). Effort scope = bounded: replace `helpers/AtomicFile` API + add 1-byte `state-meta.bin` pointer logic + update `state-persistence-schema.yaml` 3-file layout; downstream slot/orchestrator code unchanged (StatePersistence interface preserved). Estimated ~1-2 day refactor |
| Disk full during write | FileWriteString returns error | Logger.Error + Alert; existing state.json unchanged (atomic = pre-write state preserved); user must free disk |
| `state.json` parse error after restart (corruption claimed prevented) | OnInit Load fails | Log warn + start fresh; mark `state.invalid_at = TimeCurrent()` for diagnostic; continue with defaults |
| Antivirus locks `state.json` during FileMove | FileMove returns error | Retry once (200ms delay); if still fail → keep tmp file + log error + Alert; user investigates AV |
| Schema version mismatch (Phase 2 upgrade) | Load detects `schema_version != 1` | Migration logic per version; for downgrade case → log error + abort load |

### 3.5 Validation

- **Test:** kill `MT5.exe` (Process Explorer "Kill Process Tree") at random within 1-tick of `Save()` × 100 trials → reattach EA → verify load succeeds + state matches expected
- **Pass:** 100/100 success (NFR-3.1)
- **Spike priority:** Verify A2 assumption ก่อน Phase 1D TD lock (high risk if false)

---

## 4. Challenge 4 — Trade Journal Write Latency (NFR-2.2)

### 4.1 Problem

NFR-2.2 = **≤ 5 ms/tick avg + ≤ 10 ms p95** สำหรับ journal write. แต่ FR-4.1 บังคับ same-tick write + ครบ schema fields (timestamp, slot, magic, ticket, lot, price, sl, tp, comment, signal_context, indicator_snapshot, portfolio_summary, triggering_function, parent_ticket_id) ≈ ~500 bytes/record

Burst scenario (BR-8.1 Safe-port closes 10 positions) = 10 events × 1-3 ms/event = 10-30 ms ใน 1 tick → exceeds budget. Naive sync write = budget violation; async queue = MQL5 ไม่มี thread

### 4.2 Approach: Sync write + degrade-warn-but-continue (per NFR-2.2 overshoot behavior)

ADR-006 lock:
- Sync write (no buffer queue)
- Keep file handle open across ticks (avoid FileOpen/Close ~1-2 ms overhead per event)
- Bulk burst tolerance: write ทุก event sync; ถ้า measured > 5 ms ติดต่อกัน N ครั้งใน window M ticks (TD lock N/M, default N=3, M=10) → emit Logger.Warn — **continue trade flow** (degrade-warn-but-continue per BA NFR-2.2)
- Anti-spam: Logger throttle Alert (ADR-011) ป้องกัน popup overflow ตอน sustained slow disk

### 4.3 Implementation outline

```
TradeJournal::WriteEvent(event) pseudocode:
1. now = TimeCurrent() (microsecond precision via GetMicrosecondCount)
2. record = BuildRecord(event)  // ~50 µs JSON construct
3. line = JsonWriter.Serialize(record) + "\n"  // ~100 µs
4. RotateIfNeeded()  // monthly check, returns fast on no-op
5. FileWriteString(m_handle, line)  // ~500-2000 µs
6. FileFlush(m_handle)  // ~500-2000 µs (Windows write-through to disk)
7. elapsed = GetMicrosecondCount() - now
8. if elapsed > 5000 µs (= 5 ms):
       m_overshoot_window.Add(elapsed)
       if m_overshoot_window.RecentOvershoots(N=3, M=10):
           Logger.Warn("system", "journal_slow", 0, "p95 > 5ms — disk slow")
9. return  // never block trade flow
```

Burst handling (Safe-port 10 events):
- Each event handled separately; total tick time = sum
- If total > 5 ms — emit warn but proceed; tick continues
- Trade flow not blocked: orchestrator pipeline runs to completion

### 4.4 Failure modes

| Failure mode | Detection | Mitigation |
|--------------|-----------|------------|
| Disk full → FileWriteString fails | Return value check | Logger.Error (throttled); journal dropped for this event; tick continues; user must free disk |
| File handle invalidated (e.g., disk unmount) | Detect on FileWriteString error | Attempt FileOpen reattempt next event; if persistent fail → degrade to MT5 native Print() fallback + Alert |
| Sustained > 5 ms write (slow disk / heavy AV scan) | Overshoot window monitor | Warn user via Logger; suggest user check disk; **do not block trade** |
| Schema version mismatch (Phase 2) | Reader (off-line tool) detects | Per-record `schema_version` field for forward compat |
| Rotation race (month boundary mid-tick) | Single-thread MQL5 — N/A by design | — |

### 4.5 Validation

Per NFR-2.2 measurement protocol (BA-locked):
- Instrumentation: timestamp around journal write block
- Sample size: ≥ 200 events from regression run
- Aggregation: avg + p95
- Pass/fail at avg ≤ 5 ms + p95 ≤ 10 ms thresholds
- Bulk-close burst: separately documented; expected to overshoot — verify degrade-warn-but-continue trigger ทำงานถูก

---

## 5. Challenge 5 — Pending State Stuck Without Hard Timeout (resolves OQ-A1/A2/A3)

### 5.1 Problem

EA เดิมไม่มี hard wallclock/bar timeout สำหรับ M-Pending (BR-6.5), T-Pending (BR-6.6), Q-Pending (BR-6.7). Invalidation มี 2 แบบ: trigger condition met หรือ M signal flip overwrites snapshot. **Edge case:** price stuck ใน range + signal ไม่ flip → state ค้าง PENDING ตลอด session → state.json โต + GlobalVariable namespace pollution + slot ไม่ fire signal ใหม่ขณะ pending

BA flag เป็น OQ-A1/A2/A3 ที่ Architect resolve (HOW = state cleaner design)

### 5.2 Approach: Per-machine adaptive force-clear (ADR-008)

| Machine | Force-clear at | Headroom over baseline max holding |
|---------|----------------|-------------------------------------|
| M-Pending | 150 H4 bars | 5× baseline max (~30 bars typical) |
| T-Pending | 80 H4 bars | 4× baseline max |
| Q-Pending | 100 H4 bars | covers all 4 sub-codes |

Configurable per input (`InpForceClearM_Bars`, etc.) → tunable in Strategy Tester optimization sweep

### 5.3 Implementation outline

```
PendingMachineRegistry::TickAll(MarketContext, PortfolioState) pseudocode:
For each pending machine M_i:
  1. Update m_age_bars = CurrentBarIndex - m_pending_started_bar
  2. If m_state == PENDING:
     a. Check trigger condition (per machine-specific logic, BR-6.x)
        → if met: transition EXECUTED; reset
     b. Else if m_age_bars >= force_clear_threshold:
        → transition IDLE (force-clear)
        → emit Journal event: pending_force_clear
        → emit Logger.Warn (anti-spam: ≤ 1 Alert per slot per session)
        → increment m_force_clear_count metric
        → continue (no order opened)
  3. Else if m_state == IDLE:
     → check enter-pending trigger (per BR-6.x)
```

Per-slot persisted fields (added to SlotState struct):
- `pending_started_bar`: int (H4 bar index when machine entered PENDING)
- `force_clear_count`: int (cumulative counter; survives restart via state.json per ADR-007; reset only via manual delete state.json — for QA Phase 3T / IMPL-068 long-running stuck pattern measurement per A6)

### 5.4 Failure modes

| Failure mode | Detection | Mitigation |
|--------------|-----------|------------|
| Force-clear cuts a valid trigger window (Bucket A drift) | QA per-slot trade count drift > 30% (NFR-1.6 investigation flag) | Tune up `InpForceClearX_Bars`; re-run regression; revisit ADR-008 numbers |
| `pending_started_bar` corruption (atomic write fails) | Force-clear fires immediately on restart (state.json missing field) | Default to current bar index on missing field load; log warn; treat as fresh PENDING |
| Concurrent EXECUTED transition + force-clear in same tick | Single-thread guarantee → not possible | N/A by design |
| Force-clear log spam (machine cycles fast) | Multiple force-clear per session | Anti-spam Alert throttle in Logger (ADR-011); journal still records all; user inspects journal for pattern |

### 5.5 Validation

- **Baseline regression:** rerun 5-yr backtest with default thresholds → verify `force_clear_count == 0` (or minimal) per machine
- **If force_clear_count > 0:** inspect `signal_context` of force-clear journal entries; classify each as:
  - True stuck (would have stayed PENDING forever) → force-clear correct
  - Premature clear (valid trigger would have come later) → tune threshold up
- **Bucket A budget:** force-clear-induced drift counted in Bucket A 25% Net Profit ceiling

---

## 6. Comparison Matrix — Sync vs Async, SQL vs File, Etc.

ตารางสรุป architectural alternatives ที่ rejected ใน ADRs — central reference เพื่อ Tech Lead เห็น "ทำไมไม่ใช่ X"

| Decision | Chosen | Alternative considered | Why rejected |
|----------|--------|------------------------|---------------|
| Trade journal write | Sync write to JSON-Lines (ADR-006) | Async queue + background writer | MQL5 ไม่มี thread; timer-based async = complex + tick-event coupling fragile |
| Trade journal storage | JSON-Lines flat file (ADR-006) | SQLite via DLL | NFR-7.2 = 0 DLLs; no installer signal |
| State persistence | Atomic temp+rename (ADR-007) | WAL + checkpoint compaction | EA เดิม serialize full state per tick = pattern preserve; WAL = over-engineered for ~5 KB |
| Slot abstraction | OO inheritance (ADR-002) | Function-pointer table | MQL5 ไม่ support free function pointer |
| Indicator handle ownership | Centralized service (ADR-003) | Per-slot ownership | Duplication + no fail-fast point + ขัด FR-2.6 snapshot consistency |
| MarketContext mutability | Immutable per-tick (ADR-004) | Mutable shared object | Cross-slot interference; ขัด AC-2.6.2 |
| PortfolioState lookup | CHashMap<int, SlotState*> (ADR-005) | Sparse array indexed by magic-200 | Tightly coupled to magic range; Phase 2 expansion painful |
| HALTED state machine (HALTED / HALTED_STABLE) | Exit-pass-only + HALTED_STABLE (ADR-010 amended BT-002) | Stop everything immediately (legacy approach) | Open positions become orphan = G4 violation; ADR-010 entry-pass-skip + exit-pass-continue invariant preserves G4 |
| File layout | Layered tree (ADR-012) | Flat single-file | NFR-4.1 (5,000 LOC) + NFR-4.2 (1 file/slot) hard fail |
| Config delivery | MT5 native `input` only (NFR-8.2) | External JSON/YAML config + DLL parser | NFR-7.2; user MVP signal "no install" |

---

## 7. Open technical risks (acknowledged + mitigation owner)

| Risk | Owner | Mitigation |
|------|-------|------------|
| ⚠️ A1 — `CHashMap` perf at ~17 keys per OnTick frequency (per ADR-005 magic pool count) | TD spike Phase 1D | Measure; fallback = sparse array if CHashMap > 100 µs/lookup |
| ⚠️ A2 — MT5 sandbox `FileMove` atomic guarantee | TD spike Phase 1D | If fail → ADR-007 Option B double-buffered swap |
| ⚠️ A3 — ADR-008 pending force-clear thresholds appropriate | QA Phase 3T | Validate via regression; tune via input if needed |
| ⚠️ A4 — JSON-Lines write latency p95 ≤ 10 ms in MT5 sandbox + Windows AV | TD spike + QA | Measure; degrade-warn-but-continue safety net in place |
| ⚠️ A5 — 21 indicator buffer refresh ≤ 200 µs sustained | TD spike | Measure baseline; if exceed → batch CopyBuffer into single call per indicator |
| ⚠️ A6 — ADR-008 force-clear thresholds (M=150, T=80, Q=100) คือ engineering estimate ไม่ใช่ measured derivation | QA Phase 3T (IMPL-068) | Run regression → measure `force_clear_count` per machine + `pending_age_bars` distribution; if force_clear > 0 หรือ max bars > 70% threshold → tune via input + re-validate |
| ⚠️ A7 — P-Pending sub-modes (PX/PH/E/N) defined ใน schema-only; per-mode behavior + transition logic ยังไม่ surfaced ใน design doc text (ดู `04 § 4.4`) | TD Phase 1D | Read CodeWiki §2.5; ถ้า sub-mode behavior แตกต่างจาก legacy 70-bar timeout → update P-Pending row ใน `04 § 4.2` + extend `state-persistence-schema.yaml § PendingMachineState_PVariant` |

> **End of 03 — Deep Dive** — 5 critical challenges, per-challenge Problem→Approach→Implementation→Failure modes→Validation, comparison matrix of 10 architectural alternatives, 7 acknowledged technical risks (A1-A7)
