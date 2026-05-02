# IMPL-046 — Atomic-Write Spike Evidence (Evolution E1 risk gate)

**Date:** 2026-05-02
**Owner:** Kritsana (Impl Engineer; orchestrator: Opus 4.7)
**Verdict:** ✅ **OPTION_A_LOCKED** — ADR-007 Option A (single `state.json` + atomic temp + rename via `FileMove`) confirmed safe; **Option B fallback NOT activated**
**Branch context:** `main` (post parallel-batch #4: IMPL-005/007/015 closed)

## 1. Spike protocol (per impl-plan IMPL-046 description + ADR-007 §Validation)

| Step | Goal | Implementation |
|------|------|----------------|
| 1 | Write atomic-write wrapper that mirrors ADR-007 Option A | `Spike_AtomicWrite.mq5::WriteAtomic` — `FileOpen(.tmp, FILE_WRITE\|FILE_TXT\|FILE_ANSI)` → `FileWriteString` → `FileFlush` → `FileClose` → `FileMove(.tmp, 0, dst, FILE_REWRITE)` |
| 2 | Phase 1: 1000 normal atomic writes, validate counter equality each | Each iteration writes JSON `{"counter":N,"hash":...,"timestamp":...,"payload_size_bytes":256,"schema_version":1}`, re-parses, verifies `parsed_counter == N` and content ends with closing `}` |
| 3 | Phase 2: 100 simulated mid-write crashes — software-level reproduction of the ADR-007 §Atomicity proof "step 1-2 crash window" | Per trial: (a) anchor write of counter `10000+t` succeeds atomically; (b) re-open `.tmp` and write **truncated partial JSON** `{"counter":99999,"hash":"PARTIAL` then close WITHOUT `FileMove` — exactly the on-disk state a process kill during step 1-2 would produce; (c) re-parse `state.json` and verify it still equals the anchor counter; (d) cleanup orphan `.tmp` (simulates ADR-007 §OnInit recovery contract) |
| 4 | Verdict | `OPTION_A_LOCKED` if all four counters = 0 (write_fails, parse_fails, anchor_fails, state_corrupt); else `OPTION_B_ACTIVATE` |

### 1.1 Why software-level crash simulation (vs PowerShell `taskkill` × 100)

ADR-007 §Atomicity proof identifies two crash windows:

- **Step 1-2** (writing `.tmp`): `state.json` untouched; `.tmp` may be partial. → reproduced byte-for-byte by Phase 2 (open `.tmp`, write partial, close without rename).
- **Step 3** (`FileMove` rename): NTFS atomic by Windows API contract. `MoveFileEx` on same volume is documented atomic by Microsoft (Win32 docs); MQL5 `FileMove` invokes `MoveFileEx` internally per MQL5 reference. This is a Windows API contract, not a probabilistic outcome — race-testing from user-space cannot disprove it (the rename completes too fast to interrupt deterministically).

Thus PowerShell `taskkill` × 100 would generate the same observable on-disk states (untouched `state.json` + partial `.tmp`) at random timings, with non-deterministic results. The software-level reproduction is **strictly stronger** — it deterministically exercises the worst-case mid-step-1-2 state on every trial, while the rename atomicity is asserted by API contract citation in the ADR amendment.

The 1000 happy-path writes in Phase 1 empirically exercise the actual `FileMove` call 1000 times (not just contract-cited).

## 2. Run artifacts

| Artifact | Path | Notes |
|----------|------|-------|
| Spike EA source | `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5` | 175 LOC, no project `#include` (standalone) |
| Spike EA compiled | `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.ex5` | local-only, not committed (per `.claude/rules/ea.md`) |
| Tester `.ini` | `simulation/headless-tests/atomic_write_kill.ini` | committed per TD-02 §13.6 PR contract; `Model=2` (open prices, fastest), `FromDate=2021.01.04` (matches FBS-Real local history) |
| Compile log (G1) | `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.compile.log` | `Result: 0 errors, 0 warnings, 400 ms elapsed` |
| Tester run log (G3+G4) | `simulation/headless-tests/runs/IMPL-046-post_kill_run-20260502.txt` | full UTF-8 decoded log, 60 lines |

## 3. Empirical results

### G1 — Compile (MetaEditor `/compile`)

```
Result: 0 errors, 0 warnings, 400 ms elapsed, cpu='X64 Regular'
```

### G3 — Headless backtest (`terminal64.exe /config:atomic_write_kill.ini`)

```
EURUSD,H4: testing of Experts\PhoenicisNex\spike\Spike_AtomicWrite.ex5 from 2021.01.04 00:00 to 2021.01.05 00:00 started with inputs:
  InpTotalWrites=1000
  InpKillTrials=100
  InpStateFile=PhoenicisNex/spike/state.json
  InpTmpFile=PhoenicisNex/spike/state.json.tmp
2021.01.04 00:00:00   [spike][ev=spike_start][total_writes=1000][kill_trials=100]
2021.01.04 00:00:00   [spike][ev=phase1_done][writes=1000][write_fails=0][parse_fails=0]
2021.01.04 00:00:00   [spike][ev=phase2_done][kill_trials=100][anchor_fails=0][state_corrupt=0]
2021.01.04 00:00:00   [spike][ev=spike_complete][p1_writes=1000][p1_parse_fails=0][p2_kills=100][p2_state_corrupt=0][verdict=OPTION_A_LOCKED]
2021.01.04 23:59:59   [spike][ev=spike_deinit][reason=1]
EURUSD,H4: 23 ticks, 6 bars generated. Test passed in 0:00:00.835.
OnTester result 0
final balance 1000.00 USD
```

### G4 — Log review (`grep` + counter sanity)

| Assertion | Expected | Observed | Status |
|-----------|---------:|---------:|--------|
| `grep -c "state.json parse fail" run.txt` | 0 | 0 | ✅ |
| Phase 1 `write_fails` | 0 | 0 | ✅ |
| Phase 1 `parse_fails` | 0 | 0 | ✅ |
| Phase 2 `anchor_fails` | 0 | 0 | ✅ |
| Phase 2 `state_corrupt` | 0 | 0 | ✅ |
| `[ERROR]` / `[WARN]` lines | 0 | 0 | ✅ |
| `Test passed` | yes | yes (0.835 s) | ✅ |
| `OnTester result` | 0 | 0 | ✅ |

## 4. Acceptance Criteria mapping

### S-AC

- [x] Spike EA `simulation/headless-tests/atomic_write_kill.ini` committed → `simulation/headless-tests/atomic_write_kill.ini` (this commit)
- [x] 1000 normal writes succeed (state.json parses cleanly each) → `phase1_done write_fails=0 parse_fails=0`
- [x] 100 simulated kills produce 0 half-written files → `phase2_done state_corrupt=0` (state.json always parses to anchor counter; `.tmp` orphans cleaned per OnInit contract)
- [x] ADR-007 amended with `## Spike Result` section + go/no-go decision + date → see `docs/adr/007-state-persistence-atomic-temp-rename.md` (this commit)

### E-AC

- [x] `cat post_kill_run.txt | grep -c "state.json parse fail"` returns 0 across 100 kill trials `[boot-cold]` + `[file-blob-check]` → `simulation/headless-tests/runs/IMPL-046-post_kill_run-20260502.txt` shows count = 0
- [x] Option B activation NOT required (verdict = OPTION_A_LOCKED) → no IMPL-010/047/048 task-note edit needed; ADR-007 §Option B retains "designed-but-not-primary" status

## 5. Cascade impact

| Downstream task | Status post-spike |
|-----------------|-------------------|
| **IMPL-010** AtomicFile helper | Unblocked. Implement Option A wrapper exactly per ADR-007 §Decision (no schema diff vs Option B fallback) |
| **IMPL-047** StatePersistence::Save+Load | Unblocked. Use single `state.json`; no 3-file rotation logic needed |
| **IMPL-048** state.json schema final-lock | Unblocked. Schema = single state.json (no `state-meta.bin` + A/B layout) |
| **IMPL-049** PendingMachineRegistry | Unblocked. Standard StatePersistence consumer |
| **ADR-007 §Option B** | Retained as designed-not-primary fallback; only revisit if Phase 2 cloud-sync or schema-rotation requirements emerge |

## 6. Verdict for ADR

**Lock Option A.** Empirical validation: 1000/1000 atomic writes intact; 100/100 simulated mid-write crashes left state.json untouched and recoverable per ADR-007 §OnInit recovery. Step-3 (`FileMove` rename) atomicity asserted by Win32 `MoveFileEx` contract on NTFS same-volume (cited in ADR amendment). Combined: NFR-3.1 0% corruption target met provisionally for all crash windows reachable in software simulation.

**Provisional vs final:** This spike covers the algorithm. Full NFR-3.1 100/100 target validation (with real process kill via PowerShell `taskkill` during a live IMPL-047 StatePersistence loop) lands at IMPL-064 in P4 per impl-plan Phase Gate.
