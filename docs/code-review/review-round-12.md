# Code Review Round 12

| Field | Value |
|-------|-------|
| **Round** | 12 |
| **Target** | `all` — focused on (a) post-fix-round-11 deltas in `PhoenicisNex.mq5` (`#property tester_no_cache` + global comment) + `core/Orchestrator.mqh` (`m_teardown_done` / `m_init_complete` lifecycle flags + 5-layer `OnTradeTransaction` guard chain + `OnTester` warning) + `domain/EnumTypes.mqh` (`IsPhoenicisMagic` helper) and (b) NEW closures since R11: IMPL-FIX-001 (Slot_S `percent_tp` threading), IMPL-FIX-002 (RiskManager `clamp_applied` log demotion), IMPL-061 (`simulation/scripts/parse_baseline.py` per-slot baseline parser), IMPL-064 (`simulation/scripts/atomic_write_kill_100.ps1` kill-100 harness + `docs/state/nfr-3.1-atomic-write-result.md` report skeleton), IMPL-068 (`docs/state/adr-008-force-clear-validation.md` jq pipeline + amendment template) |
| **Date** | 2026-05-04 |
| **Reviewer Persona** | Code Reviewer (Adversarial Quality Engineer) |
| **Scope** | ~70 LOC delta in EA core (R11 fixes) + ~280 LOC PowerShell harness + ~400 LOC Python parser + ~300 LOC ADR-008 analysis report + ~170 LOC NFR-3.1 report skeleton. Cumulative reviewed surface: ~9,150 LOC (R01..R11). |
| **Plan Staleness Sentinel** | 6 closures since R07 (IMPL-060 + 2 FIX + 3 QA tasks); below 10-closure threshold ✅. Last `/impl-plan-review` was R07 (2026-05-04). Counter-trigger advisory still active per impl-plan TL;DR (Mid-Phase Audit P4 counter at 6 ≥ 5). |

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 2 |
| **Total**| **8** |

---

## Code Review Checklist

| # | Dimension | Status | Notes |
|---|-----------|--------|-------|
| 1 | Security (OWASP / MQL5 boundary) | ✅ Pass | EnumTypes `IsPhoenicisMagic` + Orchestrator OnTradeTransaction symbol + magic + type filters intact (R11 fixes verified in `core/Orchestrator.mqh:720-754`). No new `#import`/`WebRequest`/credential leaks. PowerShell harness uses `Get-Random` (cryptographically weak, but only for sleep timing — not a security boundary). |
| 2 | Business Logic Correctness | ⚠️ Finding | (a) `IsPhoenicisMagic(int)` allows magics 202/203/204 (Finding 12.2 HIGH — gap in registered set; partial regression of fix-round-11 §11.2); (b) IMPL-064 harness inspects production `state.json` but `atomic_write_kill.ini` launches spike that writes to `spike/state.json` (Finding 12.1 CRITICAL — false PASS verdict for NFR-3.1); (c) IMPL-064 50-500ms kill window too tight for terminal64 startup → Strategy Tester rename window never reached (Finding 12.3 HIGH). |
| 3 | Error Handling | ⚠️ Finding | `parse_baseline.py` silently substitutes `swap=0.0` / `profit=0.0` on `ValueError` without recording a warning (Finding 12.6 MEDIUM). Orchestrator R11 lifecycle flags + Phase A NULL re-check + Phase 3T `[log-assertion]` emits intact ✅. |
| 4 | Performance | ✅ Pass | OnTradeTransaction guard chain is 5 short-circuits; O(1). PowerShell harness runs serially (~10 min for 100 trials); acceptable. Python parser is single-pass O(n) over deals; acceptable. |
| 5 | Over-Engineering | ✅ Pass | R11 fixes used 2 boolean flags instead of `ETeardownReason` enum (XS-11.1 reduction-to-essentials accepted). EnumTypes helper is a 3-line free function — appropriate density. |
| 6 | Cross-Service Consistency | ⚠️ Finding | Two parallel "is-this-our-magic" predicates exist now: `domain/EnumTypes.mqh::IsPhoenicisMagic` (literal range 200..219) AND `services/PortfolioState.mqh::IsKnownMagic` (registered-set membership). Used in different surfaces (Orchestrator vs CrossSlotCoordinator). Differ in handling of unregistered range gaps (202/203/204) — see Finding 12.2. `nfr-3.1-atomic-write-result.md` §7 references `simulation/headless-tests/atomic_write_kill.ini` `Inputs=` overrides that are NOT present in the file (Finding 12.4 MEDIUM cross-reference). |
| 7 | Test Coverage Gaps | ⚠️ Finding | IMPL-064 harness path mismatch + tight kill window (Findings 12.1 + 12.3) means NFR-3.1 100/100 verdict can be reported PASS without exercising the contract. IMPL-068 numeric verdict gated on IMPL-062 5-yr regression run that has not started; expiry 2026-05-18 may slip without explicit dependency tracking (Finding 12.7 LOW). |
| 8 | Architecture Compliance | ✅ Pass | R11 fixes preserve ADR-002 composition root, ADR-010 SetHalted-before-RunExitPass, ADR-012 5-layer dependency direction. Lifecycle flags are private + Orchestrator-internal only. `OnTradeTransaction` D-9 banner accurately documents 5-layer guard topology. |
| 9 | Technical Design Compliance | ⚠️ Finding | IMPL-061 `parse_baseline.py` schema (`schema_version`, `slots[]`, `total_net_profit`) is NOT yet defined in `docs/api-specs/*.yaml` — baseline JSON consumed by IMPL-062 lacks a written contract. Same shape as TD JSON-schema gap pattern (LOW; tracked under Finding 12.6 narrative). `Slot_S.mqh:224` comment "OrderSend deferred to IMPL-053+ orchestrator wiring" is stale post-IMPL-060 (Finding 12.8 LOW). |
| 10 | Test Code Quality | ✅ Pass | PowerShell harness uses `Set-StrictMode -Version Latest` + `$ErrorActionPreference = 'Stop'` ✅. No catastrophic regex; no unbounded loops (loop bounded by `-Trials` parameter). Python parser uses `html.parser` stdlib (no regex backtracking risk); single-pass over rows. |
| 11 | Empirical AC Closure | ⚠️ Finding | Forbidden-pattern grep on `docs/state/impl-plan.md` for "deferred to operator-runtime" / "deferred per .* precedent" / "structurally complete.*deferred" / "live verification deferred" → **0 hits** ✅. BUT — IMPL-064 E-AC closure relies on a harness whose pass criterion is satisfiable WITHOUT exercising the contract (Finding 12.1 CRITICAL Dim #11 violation by transitive defect: kind = `[boot-cold]` + `[file-blob-check]` requires live observation, but harness will report PASS even if the spike never wrote to the inspected path). IMPL-068 paired-bundle deferral (M+T+Q `force_clear_count` AND ADR-008 amendment) — both rows expire 2026-05-18 but require IMPL-062 which is unstarted. |
| 12 | Functional Walk (PhoenicisNex Tier 1.5) | ⏭ Skip — not yet executed | `bootstrap_smoke.ini` walk batch-2 has not run since FIX-001/002 + IMPL-061/064/068 landed. `tier-1.5-walk-2026-05-04/abridged-tester-log.txt` is from BEFORE these closures. Per fix-round-11 § Recommendation, the walk MUST run before P4 Phase Gate; surface this finding's blast radius will only fully appear after the walk executes (Finding 12.1's PASS-without-validate behaviour will manifest as soon as harness is invoked). |
| 13 | Configuration Completeness | ⏭ Skip | Phase 1 = local-only sandbox; PowerShell harness reads `origin.txt` (already validated by IMPL-001 + IMPL-046) + `.ini` paths (committed); no new env-var / secret consumer. `[config-audit]` not triggered. |

---

## Findings

### Finding 12.1: 🔴 CRITICAL — IMPL-064 atomic-write kill harness ตรวจสอบ `state.json` คนละ path กับที่ Spike_AtomicWrite เขียน — verdict PASS เป็น false-positive

**Location:**
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Line: 65 + 154-155 (default `-StateDir 'MQL5/Files/PhoenicisNex/state'` + `$StateJson = .../state.json`)
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5`, Lines: 23-24 (`InpStateFile = "PhoenicisNex/spike/state.json"`, `InpTmpFile = "PhoenicisNex/spike/state.json.tmp"`)
- File: `simulation/headless-tests/atomic_write_kill.ini` (no `Inputs=` override section to redirect spike to the production path)
- Service: ea-qa (NFR-3.1 verification harness)

**Code:**
```powershell
# atomic_write_kill_100.ps1:65 + 154-155
[string] $StateDir   = 'MQL5/Files/PhoenicisNex/state',          # production state path
...
$StateJson    = Join-Path $AbsStateDir 'state.json'              # MQL5/Files/PhoenicisNex/state/state.json
$StateTmp     = Join-Path $AbsStateDir 'state.json.tmp'
```

```mql5
// Spike_AtomicWrite.mq5:23-24
input string InpStateFile   = "PhoenicisNex/spike/state.json";   // SPIKE path — different directory!
input string InpTmpFile     = "PhoenicisNex/spike/state.json.tmp";
```

```ini
; atomic_write_kill.ini (full content) — no [Inputs] override + no path redirect
[Tester]
Expert=PhoenicisNex\spike\Spike_AtomicWrite
Symbol=EURUSD
Period=H4
...
```

**Problem:**
The harness launches `terminal64.exe /config:atomic_write_kill.ini` which loads `Spike_AtomicWrite.mq5`. The spike writes its atomic-write payload to `MQL5/Files/PhoenicisNex/spike/state.json` (per `InpStateFile` default at line 23). After the random 50-500ms sleep + `Stop-Process -Force`, the harness inspects `MQL5/Files/PhoenicisNex/state/state.json` — a **completely different directory** (`spike/` vs `state/`). The production `state.json` is owned by `services/StatePersistence.mqh:108` (`m_state_path("PhoenicisNex/state/state.json")`) and is NEVER touched by the spike.

Consequence: the harness will report one of two outcomes regardless of whether the spike successfully demonstrated atomic-write integrity:
1. If a stale production `state.json` exists from a prior P3/P4 smoke run, every trial increments `parse_pass` (the file was untouched by the spike, parses cleanly because nobody was writing to it) → verdict `PASS`.
2. If no production `state.json` exists, every trial increments `state_missing_tmp_missing` (acceptable per ADR-007) → verdict `PASS` because `parse_fail == 0`.

In both branches, the harness reports `verdict=PASS` for IMPL-064's `[boot-cold]` + `[file-blob-check]` E-AC even though the kill never raced an active atomic write. The IMPL-046 spike verified the algorithm via software-simulated mid-write crashes (`.tmp` truncation). IMPL-064's stated purpose per `nfr-3.1-atomic-write-result.md` § 1 is to extend that with **real OS-level process kill**: "explicitly deferred by the spike's §Spike Result note: 'Final 100/100 validation (real PowerShell `taskkill`) deferred to IMPL-064.'" The current harness does not satisfy that contract.

This is exactly the **Dim #11 Empirical AC Closure** defect class that Code Reviewer SKILL § Common Rationalizations row 9 calls out: "E-AC evidence ก็คือ Vitest/xUnit/pytest test log ที่ engineer แนบ" — kind mismatch where the artifact shape is right (a 100-trial sidecar) but the artifact NEVER OBSERVED THE THING IT CLAIMS TO OBSERVE. NFR-3.1 ("AtomicFile.mqh write must survive simulated mid-write kill 100/100 trials") is empirically untestable by this harness as written.

**Why This Matters:**
Phase 5 closure for IMPL-064 will mark the deferred-AC row Done with sidecar JSON showing `verdict=PASS / parse_fail=0`, freeing P4 Phase Gate to advance. But the actual NFR-3.1 contract — that no real-world OS kill mid-write produces a half-written JSON — is unverified. If `helpers/AtomicFile.mqh` has a hardware/timing edge case that only manifests under live `Stop-Process`, the deploy ships with a state-corruption bomb that fires the first time MT5 crashes mid-tick during production live-trading. NFR-3.1 was specifically defined as a hard-acceptance-blocking signal for this exact failure mode.

Worse: this is the second time PhoenicisNex Phase 1 has lost a verification surface to a path-binding mistake (R10 had the analogous OnTradeTransaction wiring miss, fixed in R10 §10.3). The harness shipped without dry-run verification against the production state path; an operator running it in the Tier 1.5 walk batch-2 will see a PASS verdict and close the registry row. The defect surfaces only at production crash time.

**Suggested Fix:**
Either (a) point the harness at the spike's actual write path:
```powershell
[string] $StateDir = 'MQL5/Files/PhoenicisNex/spike',  # match Spike_AtomicWrite InpStateFile default
```
or — preferred — (b) override the spike's input parameters via the `.ini` `Inputs=` section so the spike writes to the production path the harness already inspects:
```ini
; simulation/headless-tests/atomic_write_kill.ini
[Tester]
Expert=PhoenicisNex\spike\Spike_AtomicWrite
...

[TesterInputs]
InpStateFile=PhoenicisNex/state/state.json
InpTmpFile=PhoenicisNex/state/state.json.tmp
InpTotalWrites=100000           ; large enough that 50-500ms kill races a write window
InpKillTrials=0                 ; harness owns the kill — disable spike's internal Phase 2
```
Approach (b) is preferred because it co-locates the contract (production path == path the harness inspects). Then add a SelfTest to the harness: `-DryRun` mode should also assert that the spike's write path matches the harness's inspect path by parsing `Spike_AtomicWrite.mq5` for `InpStateFile=` and the `.ini` for the override — fail-loud if mismatched. LoE: Low (~10 LOC `.ini` + ~15 LOC harness assertion).

After the path is wired correctly, also address Finding 12.3 (kill window too tight) before claiming the harness validates NFR-3.1.

**Level of Effort:** Low

---

### Finding 12.2: 🟠 HIGH — `IsPhoenicisMagic` ใช้ literal range `[200..219]` ที่รวม magic 202/203/204 ที่ไม่ได้ register — foreign-EA ที่ใช้ magic ใน gap จะหลุด filter เข้าไป pollute BR-3.6 ring buffer (partial regression of fix-round-11 §11.2)

**Location:**
- File: `MQL5/Experts/PhoenicisNex/domain/EnumTypes.mqh`, Lines: 39-55 (MAGIC constants — non-contiguous), 68-71 (helper definition)
- File: `MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh`, Line: 739 (caller in OnTradeTransaction)
- Service: ea (domain + Orchestrator)

**Code:**
```mql5
// EnumTypes.mqh:39-55 — magic constants (NOT contiguous: 202/203/204 absent)
static const int MAGIC_CD = 200;  // C, D shared
static const int MAGIC_F  = 201;
// gap: 202, 203, 204 NOT assigned to any slot
static const int MAGIC_H  = 205;
static const int MAGIC_J  = 206;
static const int MAGIC_K  = 207;
static const int MAGIC_G  = 208;  // G, G2 shared
...
static const int MAGIC_T  = 219;
// Slot U (magic 220) deleted per OQ-8 (2026-05-01)

// EnumTypes.mqh:68-71 — helper too permissive
bool IsPhoenicisMagic(int magic)
  {
   return magic >= 200 && magic <= 219;     // accepts 202/203/204 (no slot owns these)
  }

// Orchestrator.mqh:739 — sole caller (in OnTradeTransaction)
if(!IsPhoenicisMagic(magic)) return;
```

**Problem:**
`MAGIC_*` constants in `EnumTypes.mqh:39-55` enumerate **17 distinct registered magics** in the range 200..219 with **3 gaps** (202, 203, 204 are not assigned to any slot per BR-1.1 + ADR-005). The `IsPhoenicisMagic` helper (added in fix-round-11 § XS-11.3 to centralize the NFR-5.3 boundary) uses a **range check** rather than a **set membership** check, so a foreign EA running on the same multi-EA terminal that happens to use magic 202, 203, or 204 will pass the OnTradeTransaction filter and feed BR-3.6's ring buffer with foreign close events.

This is a **partial regression of Finding 11.2's fix**. The review-round-11 finding stated the threat surface is "the operator runs another EA on GBPUSD that uses magic 207 (which collides with PhoenicisNex's MAGIC_K=207)". That collision case is now filtered ✅. But the broader threat — any foreign EA on EURUSD using a magic in [200..219] that happens to fall in the unused slots — is NOT filtered. A foreign EA's magic 202 close event will:
1. Pass `IsPhoenicisMagic(202)` → true (range check)
2. Reach `m_breaker.RecordClose(202, dir, t)` → enters BR-3.6 ring
3. CheckPingPong scan compares (202, dir) tuples — only foreign events present, but they trigger ping-pong false-positive halt of PhoenicisNex.

Worse: contrast with `services/CrossSlotCoordinator.mqh:314` which uses the **stricter** check `m_portfolio.IsKnownMagic((int)mg)` — set membership against the registered hash map. The two surfaces now have inconsistent foreign-magic semantics: CrossSlotCoordinator correctly rejects 202/203/204; OnTradeTransaction accepts them. This is a **cross-service consistency** defect (Dim #6) introduced by the helper definition rather than the call site.

This also means the comment at `EnumTypes.mqh:67` ("Range = [200..219] inclusive (Slot U=220 deleted per OQ-8 — kept out)") is misleading — the *range* is correct as written, but the *intent* (filter to PhoenicisNex slots) is broken because the slot-magic set is non-contiguous.

**Why This Matters:**
BR-3.6 is a primary safety mechanism per ADR-010 + NFR-5.1. False-positive halt = revenue loss + operator confusion. The vulnerability surface is small (only 3 magics) but it is the *gap* an adversarial-minded attacker (or just a careless operator running multiple EAs) hits, exactly the case fix-round-11 §11.2 was designed to close. The contract was tightened from "no filter" → "range filter"; it should have been tightened to "registered-set filter" because that's what BR-1.1 + ADR-005 actually mandate.

Same defect class as Finding 09.1 (CrossSlotCoordinator weak-metric magic-filter regression) which was caught earlier by demanding `IsKnownMagic`-style membership over range; the lesson did not propagate to the domain helper.

**Suggested Fix:**
Tighten `IsPhoenicisMagic` to enumerate the registered magics explicitly (single source of truth):

```mql5
// EnumTypes.mqh — replace range check with set membership.
//   Backed by MAGIC_* constants above; updates here MUST mirror any
//   future MAGIC_* addition/removal (PHOENICISNEX_MAGIC_COUNT also bumps).
bool IsPhoenicisMagic(int magic)
  {
   switch(magic)
     {
      case MAGIC_CD:  // 200
      case MAGIC_F:   // 201
      case MAGIC_H:   // 205
      case MAGIC_J:   // 206
      case MAGIC_K:   // 207
      case MAGIC_G:   // 208
      case MAGIC_GO:  // 209
      case MAGIC_M:   // 210
      case MAGIC_L:   // 211
      case MAGIC_Q:   // 212
      case MAGIC_R:   // 213
      case MAGIC_B:   // 214
      case MAGIC_BR:  // 215
      case MAGIC_I:   // 216
      case MAGIC_S:   // 217
      case MAGIC_P:   // 218
      case MAGIC_T:   // 219
         return true;
      default:
         return false;
     }
  }
```

Alternatively, route the call through `m_portfolio.IsKnownMagic(magic)` from the OnTradeTransaction call site (which is what CrossSlotCoordinator already does) — that approach avoids duplicating the magic enumeration but introduces a service dependency at the trade-transaction surface (PortfolioState must exist, which is already gated by `m_init_complete`). Either is acceptable.

Add a SelfTest case in `Spike_CircuitBreaker` (or the new harness): `OnTradeTransaction` simulated event with magic=202 → assert ring buffer NOT mutated. LoE: Low (~17 LOC switch + 1 SelfTest case).

**Level of Effort:** Low

---

### Finding 12.3: 🟠 HIGH — `atomic_write_kill_100.ps1` 50-500ms kill window สั้นเกินกว่า terminal64.exe จะ start + Strategy Tester จะ initialize EA + reach atomic-write loop — kill ทุกครั้งจะมาถึงก่อน spike จะเขียน .tmp แม้แก้ path mismatch แล้ว (Finding 12.1)

**Location:**
- File: `simulation/scripts/atomic_write_kill_100.ps1`, Lines: 178-179 (`Get-Random -Min 50 -Max 501` then `Start-Sleep -Milliseconds $sleepMs`)
- File: `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5` (writes occur in `OnInit` body, after MT5 cold-bootstrap)
- Service: ea-qa (NFR-3.1 verification harness)

**Code:**
```powershell
# atomic_write_kill_100.ps1:163-189 (per-trial loop)
$proc = Start-Process -FilePath $Terminal64 `
                      -ArgumentList "/config:`"$AbsIniPath`"" `
                      -PassThru
# ...
$sleepMs = Get-Random -Minimum 50 -Maximum 501       # 50-500 ms
Start-Sleep -Milliseconds $sleepMs
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
```

**Problem:**
MT5's `terminal64.exe` cold-bootstrap (load + initialize chart + connect to broker history + spawn `MetaTester64.exe` agent for Strategy Tester) takes **several seconds** on a typical Windows host even with `Visual=0 + ShutdownTerminal=1` — anecdotally 3-15 seconds depending on system load + whether MT5 was previously closed cleanly. The spike's `OnInit` body (which is where `WriteAtomic` runs in a 1000+100 loop per `Spike_AtomicWrite.mq5:96-100`) cannot execute until the agent has loaded the EA.

A 50-500ms kill arrives during MT5 startup, before the spike's first `WriteAtomic` call, and almost certainly before any `state.json` or `state.json.tmp` has been created. Combined with Finding 12.1 (wrong inspect path), every trial will report `state_missing_tmp_missing` (acceptable per ADR-007). Total accounting: `100 == Trials` ✅ + `parse_fail == 0` ✅ → **`verdict=PASS`** despite zero atomic writes ever being raced.

The expected counter table in `nfr-3.1-atomic-write-result.md § 4` claims:
| Counter | Expected |
|---|---|
| `parse_pass` | 50-100 (kill arrives after rename completes → valid `state.json` present) |
| `state_missing_tmp_present` | 0-50 (kill arrives during `.tmp` write phase → rename not reached) |

Neither bucket can be populated under a 50-500ms window because the spike never reaches its write loop. The expected counters reflect an attack window inside the spike's `OnInit` write loop, which would require waiting **at least until the EA has initialised** before launching the kill timer — i.e., poll for `state.json` existence first, then start the 50-500ms random offset.

This compounds Finding 12.1: even if the path mismatch were fixed (e.g., spike writes to production path), the timing window guarantees the kill never races an active atomic write. The harness produces a 100-trial PASS verdict that empirically validates nothing.

**Why This Matters:**
Same Dim #11 defect class as Finding 12.1 — closure-rule kind mismatch with extra weight. Even after Finding 12.1 is fixed by overriding spike's `InpStateFile` to the production path, Finding 12.3 remains: the harness's kill timing is structurally incapable of reaching the rename window. Without both fixes, NFR-3.1's "100/100 trials" hard-acceptance signal is an empty assertion — Phase 5 deliver-gate sees green, production gets the bomb.

**Suggested Fix:**
Replace the unconditional sleep with a poll-then-attack pattern:

```powershell
# 5b'. Wait for spike to start writing (state.json appears) — bounded poll.
$pollDeadline = (Get-Date).AddSeconds(60)         # 60 s upper bound for MT5 startup
$writeStarted = $false
while((Get-Date) -lt $pollDeadline) {
    if(Test-Path $StateJson -or Test-Path $StateTmp) {
        $writeStarted = $true
        break
    }
    Start-Sleep -Milliseconds 100
}
if(-not $writeStarted) {
    Write-Warning "[atomic-write-kill] Trial $i: spike never wrote — startup timeout. Skipping."
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    continue
}

# 5c'. Now apply the random 50-500ms offset INTO the spike's write loop.
$sleepMs = Get-Random -Minimum 50 -Maximum 501
Start-Sleep -Milliseconds $sleepMs

# 5d. Kill the process — now the 50-500ms window genuinely races atomic writes.
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
```

Also bump `Spike_AtomicWrite.mq5 InpTotalWrites` (default 1000) via `.ini` `[TesterInputs]` to ~100000 so the spike's write loop runs long enough for the random 50-500ms attack window to land inside an active iteration. Add a counter to the harness sidecar JSON: `startup_timeout_count` so an operator can tell "n/100 trials never even started writing". A successful test should have all 100 trials with `writeStarted == true` AND `Total == 100`. LoE: Medium (~30 LOC harness changes + `.ini` input override).

**Level of Effort:** Medium

---

### Finding 12.4: 🟡 MEDIUM — `atomic_write_kill.ini` ไม่มี `[TesterInputs]` section ที่ override `Spike_AtomicWrite` defaults — harness assume operator จะรู้แต่ contract ไม่ enforced ที่ `.ini` layer (cross-reference of 12.1)

**Location:**
- File: `simulation/headless-tests/atomic_write_kill.ini` (full file — 21 lines, only `[Tester]` block)
- File: `docs/state/nfr-3.1-atomic-write-result.md` § 2.3 ("`.ini` is **present** and reused as-is — no modification required")
- Service: ea-qa

**Code:**
```ini
; atomic_write_kill.ini — full content
[Tester]
Expert=PhoenicisNex\spike\Spike_AtomicWrite
Symbol=EURUSD
Period=H4
Model=2
Optimization=0
FromDate=2021.01.04
ToDate=2021.01.05
Deposit=1000
Leverage=500
ShutdownTerminal=1
Visual=0
; <-- no [TesterInputs] section; spike uses defaults from Spike_AtomicWrite.mq5:23-24
```

**Problem:**
`nfr-3.1-atomic-write-result.md` § 2.3 makes the explicit claim: "**`.ini` is present and reused as-is — no modification required**". This claim is wrong in two ways:
1. The `.ini` was originally authored for IMPL-046 spike's *internal* phase 1+2 simulation (which writes to `spike/state.json` deliberately because it's testing the algorithm in a sandbox). Reusing it for IMPL-064's *external* PowerShell-driven kill harness requires either changing the harness's inspect path OR overriding the spike's input parameters — but the document asserts neither is needed.
2. There is no `[TesterInputs]` section to pin `InpStateFile` / `InpTmpFile` / `InpTotalWrites` / `InpKillTrials` to harness-aware values. Without the section, the spike defaults to (a) writing under `spike/` (Finding 12.1 path mismatch) and (b) running its own internal Phase 2 (100 simulated kill trials) which COMPETES with the harness's external kill (the spike's Phase 2 closes with `OPTION_A_LOCKED` Print and exits cleanly long before the random 50-500ms harness kill arrives).

This makes the harness's "atomic write under live taskkill" claim doubly broken: wrong path AND the spike auto-completes its own simulation before the operator-side kill happens.

The doc claim and the harness/spike actual behaviour disagree. Either the doc is stale (and the engineer's intent was to add a `[TesterInputs]` section that was forgotten), or the doc is wishful (the spike was never re-purposed for live taskkill). Either way, the contract is broken at the `.ini` layer.

**Why This Matters:**
Cross-references the same Dim #11 defect as Finding 12.1 from a different angle — the **document → artifact divergence** that misleads any operator reading `nfr-3.1-atomic-write-result.md` to believe the harness will "just work". This is the precise pattern called out by R11 § 10.8 cascade-drain plan: when 30+ deferred-AC rows are gated on a single artifact, ANY divergence between the doc + the artifact contaminates 30+ closure decisions.

**Suggested Fix:**
Add `[TesterInputs]` to the `.ini` per Finding 12.1's preferred approach, AND amend `nfr-3.1-atomic-write-result.md § 2.3` to document the override:

```ini
; atomic_write_kill.ini — add this section

[TesterInputs]
InpStateFile=PhoenicisNex/state/state.json
InpTmpFile=PhoenicisNex/state/state.json.tmp
InpTotalWrites=100000        ; large enough that random 50-500ms always lands inside loop
InpKillTrials=0              ; disable spike's internal Phase 2; harness owns external kill
```

```markdown
### 2.3 .ini Reuse — UPDATED 2026-05-04

`simulation/headless-tests/atomic_write_kill.ini` now ships with a
`[TesterInputs]` section that redirects `Spike_AtomicWrite` to write
to the production `state.json` path (matching the harness inspect target)
and disables the spike's internal Phase 2 (which would otherwise
auto-complete before the harness kill).
```

LoE: Low (~6 LOC `.ini` + ~6 LOC doc).

**Level of Effort:** Low

---

### Finding 12.5: 🟡 MEDIUM — `parse_baseline.py` silently swallows `ValueError` on swap/profit field parsing — malformed MT5 HTML row produces wrong per-slot `net_pnl` without warning

**Location:**
- File: `simulation/scripts/parse_baseline.py`, Lines: 239-247 (try/except around `float(profit_raw)` + `float(swap_raw)` defaults to `0.0`)
- Service: ea-qa (IMPL-061 baseline parser)

**Code:**
```python
# parse_baseline.py:237-247
profit_raw = row[10].replace("\xa0", "").replace(" ", "")
swap_raw = row[9].replace("\xa0", "").replace(" ", "")
try:
    profit = float(profit_raw)
except ValueError:
    profit = 0.0           # <-- silent fallback
try:
    swap = float(swap_raw)
except ValueError:
    swap = 0.0             # <-- silent fallback
net_pnl = profit + swap
```

**Problem:**
The parser wraps both `float()` conversions in `try/except ValueError` and falls back to `0.0` without recording a warning to stderr. A future MT5 build that changes the report format (e.g., introduces a thousands-separator the parser doesn't strip, or emits `n/a` in commission/swap columns), or a malformed `<td>` cell from an interrupted Strategy Tester run, will silently undercount per-slot net_pnl with no operator-visible signal.

Worse: the parser DOES emit warnings for `unmatched_out_count` and unclosed positions (lines 259-273) — so the `_parse_deals` function knows how to surface anomalies — but the per-row parse failures bypass that channel. The current 21-slot baseline JSON happens to validate because the IMPL-061 closure log shows `sum=$24.27M exact match to total_net_profit (delta=0.00)`. That validation only catches *systematic* per-row failures; a sparse failure (e.g., 5/30,000 deals with malformed swap) would still show `delta < 0.01` and pass the contract-roundtrip E-AC.

The exact-match validation in `parse_baseline.py:371-376` (sum check vs `total_net_profit`) protects against most defects but not against this one — `total_net_profit` from `_extract_total_net_profit` reads the summary header which uses different fields than the deals table; a sparse deals-table parse fail could leak through.

**Why This Matters:**
IMPL-062 Bucket A regression depends on `baseline-per-slot.json` as the gold standard for ≤25% NFR-1.1 deviation calculation. If silent parse failures undercount the baseline (e.g., per-slot count or net_pnl underreported), the regression check inverts: a clean rewrite that matches behaviour would appear to *exceed* the baseline (because baseline is depressed) and trigger a false drift alarm. Operator wastes time chasing a phantom regression.

**Suggested Fix:**
Replace the silent fallback with an explicit stderr warning + counter:

```python
# parse_baseline.py — top of _parse_deals
parse_anomaly_count = 0
# ...
try:
    profit = float(profit_raw)
except ValueError:
    profit = 0.0
    parse_anomaly_count += 1
    print(f"[parse_baseline] WARNING: row at deal {row[1]!r} has unparseable profit "
          f"{row[10]!r}; defaulting to 0.0", file=sys.stderr)
try:
    swap = float(swap_raw)
except ValueError:
    swap = 0.0
    parse_anomaly_count += 1
    print(f"[parse_baseline] WARNING: row at deal {row[1]!r} has unparseable swap "
          f"{row[9]!r}; defaulting to 0.0", file=sys.stderr)
```

Also add `parse_anomaly_count` to the output JSON (top-level) so downstream IMPL-062 regression logic can refuse to compute drift if the baseline's anomaly count is non-zero. LoE: Low (~10 LOC).

**Level of Effort:** Low

---

### Finding 12.6: 🟡 MEDIUM — fix-round-11 §11.3 implemented orchestrator-side gate (`m_init_complete`) only — `CCircuitBreaker::RecordOpen` / `RecordClose` lack defense-in-depth NULL-init guard for any future caller bypassing Orchestrator

**Location:**
- File: `MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh`, Lines: 137-156 (RecordOpen + RecordClose bodies — no `m_logger == NULL || m_buffer-uninitialized` early return)
- File: `docs/code-review/review-round-11.md` § Finding 11.3 Suggested Fix Option B
- File: `docs/code-review/fix-round-11.md` § Fix for Finding 11.3 (chose Option A only)
- Service: ea (CircuitBreaker service)

**Code:**
```mql5
// CircuitBreaker.mqh:149-156 — RecordClose has no init-state assertion
void CCircuitBreaker::RecordClose(int magic, int direction, datetime now_s)
  {
   _WriteEvent(magic, direction, now_s);             // writes m_buffer[m_idx] regardless
   if(m_logger != NULL)                              // only logger is guarded
      m_logger.Debug("CircuitBreaker", "record_close", magic,
                     "dir=" + IntegerToString(direction) +
                     " t=" + IntegerToString((int)now_s));
  }
```

**Problem:**
Review-round-11 §11.3 explicitly recommended Option B (RecordClose-side gate) as the more robust defense:
> Option B is more robust (defends in depth, doesn't require the caller to know CB's init state).

Fix-round-11 chose Option A (orchestrator-side `m_init_complete` flag) only, citing centralization. This is a defensible trade-off for the *current* call topology (only Orchestrator::OnTradeTransaction calls RecordClose). But:
1. `services/CircuitBreaker.mqh:95` documents `RecordOpen` as "Called by slot post-OrderSend ack to record open events" — TD-02 §5.8 wiring is for slots to call directly into CB. The current 21-slot implementations don't call it (they emit `entry_signal` Logger.Info, OrderSend deferred to RiskManager wiring). But once IMPL-062 / IMPL-017 wire actual OrderSend through `RiskManager::OpenOrder`, slots WILL feed RecordOpen — and slots have no `m_init_complete` knowledge. The CB pre-Init guard is then absent.
2. Spike harnesses (`Spike_CircuitBreaker.mq5` if it existed; current SelfTest is in-class) call RecordClose directly during the SelfTest body; the SelfTest path bypasses any orchestrator-level init gate. Future Spike_OrderRouter or similar would too.
3. Defense-in-depth is a Phase 1 security/safety NFR per CLAUDE.md §4 Security Rules ("ห้าม `INVALID_HANDLE` ผ่านไป OnTick — fail-fast 100%"). The Logger init gate inside RecordClose (3 LOC) is the same posture for CB.

This is a smaller-scale concern than Findings 12.1-12.4 because the current call topology is closed. But the CircuitBreaker contract documents future caller surfaces that would re-open it.

**Why This Matters:**
Phase 2 RiskManager::OpenOrder wiring will likely route post-OrderSend acks into `m_breaker.RecordOpen` per the documented contract. A pre-OnInit broker-recovery dispatch (per MT5 docs note that OnTradeTransaction can fire pre-OnInit) could trigger a slot-side RecordOpen attempt before `m_breaker.Init` runs. With Option B in place, this is a cheap no-op + Print fallback. Without it, `_WriteEvent` writes garbage into a zero-initialized buffer (technically safe — the ctor sets m_idx=m_count=0 — but the event remains in the buffer post-Init and could trigger CheckPingPong false positives if the early event happens to share (magic, dir) with a real later event within 3 s).

**Suggested Fix:**
Add the Option B guard as a 1-line early-return + Print fallback:

```mql5
void CCircuitBreaker::RecordOpen(int magic, int direction, datetime now_s)
  {
   if(m_logger == NULL)         // pre-Init defense in depth (R12 §12.6)
     {
      Print("[CircuitBreaker][WARN] RecordOpen pre-Init dropped: magic=", magic,
            " dir=", direction, " t=", (int)now_s);
      return;
     }
   _WriteEvent(magic, direction, now_s);
   m_logger.Debug("CircuitBreaker", "record_open", magic,
                  "dir=" + IntegerToString(direction) +
                  " t=" + IntegerToString((int)now_s));
  }

// Mirror in RecordClose.
```

Add a SelfTest case: pre-Init RecordOpen call → assert ring buffer NOT mutated + Print fallback emitted. Document the dual-gate rationale in the CircuitBreaker header banner. LoE: Low (~10 LOC + 1 SelfTest).

**Level of Effort:** Low

---

### Finding 12.7: 🔵 LOW — IMPL-068 deferred-AC bundle (force_clear_count + ADR-008 amendment) expires 2026-05-18 but depends on IMPL-062 5-yr regression run that has not been started — registry expiry may slip without explicit dependency tracking

**Location:**
- File: `docs/state/deferred-ac-registry.md`, Line: 60 (IMPL-068 row)
- File: `docs/state/adr-008-force-clear-validation.md` § 9 Operator Runbook (cites IMPL-061 ✅ → IMPL-062 → run jq pipeline)
- File: `docs/state/impl-plan.md` § Next Best Action (lists IMPL-062 as ☐)
- Service: ea-qa (IMPL-068)

**Problem:**
The IMPL-068 deferred-AC registry row states:
> 5-yr regression journal records prerequisite — depends on IMPL-062 (Bucket A regression) producing `MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl` over 2021-2025 backtest.

Both rows (IMPL-068 numeric `force_clear_count` AND ADR-008 amendment) carry expiry 2026-05-18 (14 days). However, IMPL-062 itself is unstarted (per impl-plan.md § Next Best Action — "P4 tail: IMPL-017 + IMPL-062 ... + IMPL-063 ..."). IMPL-062 is an L-sized task that requires:
1. IMPL-061 baseline ✅ done
2. A clean 5-yr backtest run on EURUSD H4 — which itself takes hours of MT5 wall-clock time
3. Journal record analysis + per-slot deviation comparison
4. Operator session to invoke + supervise

Realistic timeline to drain IMPL-068 is closer to IMPL-062 close + 1 walk session = ~1 week minimum from when IMPL-062 starts. With IMPL-062 unstarted today (2026-05-04), the 2026-05-18 expiry is feasible only if IMPL-062 starts within the next 2-3 days.

Per CLAUDE.md §7 Glossary ("Deferred-AC Registry — Schema: owner + expiry ≤14 วัน"), expiry slip is treated as a process violation. The current registry single-renewal cap = 14d → final hard-stop 2026-06-01.

**Why This Matters:**
If the deferred-AC row is not drained by 2026-05-18 + IMPL-062 hasn't started, the registry status switches to overdue + blocks `/deliver` per registry contract. Operator must either (a) explicitly extend with single-renewal (2026-06-01) and accept that as the hard-stop, or (b) escalate via `/backtrack sd` to revisit the IMPL-068 acceptance criterion. Better to flag the dependency NOW (2 weeks ahead of expiry) than discover it at deliver-gate.

**Suggested Fix:**
Either (a) add an explicit `Blocks` column to the registry row pointing at IMPL-062 so `/next` Check 5.7 surfaces "IMPL-068 row depends on IMPL-062 which hasn't started", or (b) extend IMPL-068 expiry to 2026-06-01 NOW with documented reason "blocked on IMPL-062 timing; not vendor wait". Option (a) is more honest (preserves the 14d guideline + makes the prereq visible); option (b) is operationally simpler.

Also add to `impl-plan.md § Open Risks` a new R-7 row: "IMPL-068 + IMPL-064 numeric drain timeline coupled to IMPL-062 5-yr regression schedule; if IMPL-062 slips past 2026-05-11, deferred-AC registry expiry reset cycle begins."

LoE: Low (~3 LOC registry + ~2 LOC plan).

**Level of Effort:** Low

---

### Finding 12.8: 🔵 LOW — `Slot_S.mqh:224` "OrderSend deferred to IMPL-053+ orchestrator wiring" comment is stale post-IMPL-060 — IMPL-053..060 chain is closed but slot still emits `entry_signal` Logger.Info instead of routing through `RiskManager::OpenOrder`

**Location:**
- File: `MQL5/Experts/PhoenicisNex/slots/Slot_S.mqh`, Lines: 222-238 (`req` struct built but never sent + comment block claiming "OrderSend deferred to IMPL-053+")
- Cross-reference: `docs/state/impl-plan.md` shows IMPL-053..060 all `[x]` complete + `.claude/rules/ea.md` "ALL CTrade calls go through `RiskManager::OpenOrder`"
- Service: ea (Slot_S — representative; pattern likely applies to all 21 slots)

**Code:**
```mql5
// Slot_S.mqh:222-238
   //--- Build MqlTradeRequest stub (req.magic = MAGIC_S per directive)
   //    OrderSend deferred to IMPL-053+ orchestrator wiring.
   //    Observable milestone for E-AC [log-assertion]:
   MqlTradeRequest req = {};
   req.action    = TRADE_ACTION_DEAL;
   ...
   m_logger.Info("SlotS", "entry_signal", MAGIC_S,
                 StringFormat("dir=%s lot=%.2f sl_pips=%.1f price=%.5f sl=%.5f comment=%s"
```

**Problem:**
IMPL-053 (RunSafePort) through IMPL-060 (entry .mq5) are all `[x]` complete per impl-plan.md. The comment in Slot_S asserts OrderSend is deferred to that chain — but no IMPL-053..060 task wired Slot_S → RiskManager.OpenOrder. The req struct is built every entry signal + discarded. Slot_S only emits `entry_signal` Logger.Info; no actual order is sent.

Tier 1.5 walk batch-1 (per impl-plan TL;DR) ran `bootstrap_smoke.ini` + saw `[ev=s_pct_tp_invalid]` and `[ev=clamp_applied]` defects — both stem from the lot computation path. Neither a SUCCESS path entry was observed at the broker layer because no OrderSend ever fires. The walk's deferred-AC row IMPL-FIX-001 expects "at least one `[ev=entry_signal][slot=SlotS]` with `lot > 0.01` (not floor-clamped) `[log-assertion]`" — not an actual broker-side entry. So the smoke contract is satisfied without OrderSend.

This is consistent with all 21 slots (each emits `entry_signal` Logger.Info instead of calling `m_risk.OpenOrder`). The architectural intent per `.claude/rules/ea.md` is clear: "ALL CTrade calls go through `RiskManager::OpenOrder` or `OpenOrder<X>` helper — slots ห้าม instantiate CTrade ตรง". But the actual `RiskManager::OpenOrder` wrapper is not yet implemented in any slot's path. So Phase 1 architecturally has an "OrderSend gap" that is intentional but not registered in the deferred-AC registry or Open Risks.

The Slot_S comment misleads a reader into thinking the gap was closed by IMPL-053..060 (it wasn't — IMPL-053..056 are CrossSlotCoordinator close-path; IMPL-057..058 are HALTED matrix; IMPL-059 is Orchestrator composition root; IMPL-060 is entry .mq5). The actual OrderSend wiring lives in IMPL-017 + IMPL-062/063 regression Phase 4 tail.

**Why This Matters:**
Audit clarity. New engineer reading Slot_S sees the comment, believes OrderSend works, runs G3, sees NO trades land in journal records, opens a defect ticket — wasted cycle. The comment should either (a) cite the actual task wiring OrderSend (IMPL-017 / IMPL-062 / TBD), or (b) remove the "deferred" framing and document the architectural choice ("Phase 1 emits entry_signal Logger only; OrderSend wiring lives in IMPL-017 / RiskManager.OpenOrder per ea.md rule").

**Suggested Fix:**
Update Slot_S comment block + propagate the same correction to all 21 slot files (grep for "OrderSend deferred to IMPL-053+"):

```mql5
   //--- Build MqlTradeRequest stub (req.magic = MAGIC_S per directive).
   //    Phase 1 architectural choice: slots emit `entry_signal` Logger.Info
   //    as the observable milestone; actual OrderSend lives in
   //    `RiskManager::OpenOrder` wrapper (per .claude/rules/ea.md +
   //    IMPL-017 / IMPL-062 5-yr regression integration tasks).
   //    Observable milestone for E-AC [log-assertion]:
   MqlTradeRequest req = {};
   ...
```

Add a new Open Risks row R-7: "Phase 1 OrderSend gap — slots emit entry_signal Logger only; broker-side order delivery wires at IMPL-017 / IMPL-062 regression tasks. NFR-2.3 backtest fidelity verifiable only at that point."

LoE: Low (~3 LOC per slot × 21 + 1 plan row).

**Level of Effort:** Low

---

## Cross-Service Issues

### XS-12.1 — Two parallel `is-this-our-magic` predicates with different semantics
- `domain/EnumTypes.mqh::IsPhoenicisMagic(int)` — literal range `[200..219]` (admits 202/203/204 unregistered gaps)
- `services/PortfolioState.mqh::IsKnownMagic(int)` — registered-set membership (correct)

Used in different surfaces (Orchestrator OnTradeTransaction vs CrossSlotCoordinator weak-metric). Discrepancy first noted in Finding 12.2; cross-cutting recommendation = make `IsPhoenicisMagic` a forwarder to `IsKnownMagic` once a portfolio reference is available, OR enumerate magics explicitly in EnumTypes (per Finding 12.2 fix). Either way, both surfaces must agree on the same answer.

### XS-12.2 — `nfr-3.1-atomic-write-result.md` § 1 + § 2.3 + § 4 expected-counter table contradict the actual harness behaviour
The doc claims (a) 100/100 will exercise live taskkill against the production state path (§ 1), (b) `.ini` is reused as-is (§ 2.3), and (c) parse_pass 50-100 + state_missing_tmp_present 0-50 (§ 4 expected counters). All three are simultaneously consistent only if (i) the spike writes to production path AND (ii) the kill window lands inside an active write loop. Findings 12.1 + 12.3 + 12.4 collectively say neither holds. The doc must be updated AND the harness/ini must be fixed; doc-only fix or harness-only fix leaves the divergence.

### XS-12.3 — `Slot_S.mqh:224` stale-comment defect class likely propagates to all 20 other slot files
A grep for "OrderSend deferred to IMPL-053+" or "OrderSend deferred to IMPL-040+" across `slots/` would surface the full propagation surface. Finding 12.8 documents Slot_S as the sample; a fix-round must touch all 21 slots OR define a single shared helper comment in `domain/CSlotBase.mqh` that future slots inherit by convention.

---

## Summary Table

| # | Severity | Dimension | Title | Location | Effort |
|---|----------|-----------|-------|----------|--------|
| 12.1 | 🔴 CRITICAL | Test Coverage / E-AC Closure | IMPL-064 harness inspects `state/state.json` but spike writes to `spike/state.json` → false PASS verdict for NFR-3.1 | `simulation/scripts/atomic_write_kill_100.ps1:65,154` + `Spike_AtomicWrite.mq5:23-24` + `atomic_write_kill.ini` | Low |
| 12.2 | 🟠 HIGH | Security / Cross-Service Consistency | `IsPhoenicisMagic` literal range admits unregistered magics 202/203/204 → foreign-EA close events feed BR-3.6 (partial regression of fix-round-11 §11.2) | `EnumTypes.mqh:68-71` + `Orchestrator.mqh:739` | Low |
| 12.3 | 🟠 HIGH | Test Coverage / Performance | `atomic_write_kill_100.ps1` 50-500ms kill window pre-empts terminal64 startup → spike never reaches write loop even if path is fixed | `atomic_write_kill_100.ps1:178-179` | Medium |
| 12.4 | 🟡 MEDIUM | Cross-Service Consistency / Doc | `atomic_write_kill.ini` lacks `[TesterInputs]` override; `nfr-3.1-atomic-write-result.md` § 2.3 claim "no modification required" is wrong | `simulation/headless-tests/atomic_write_kill.ini` + `nfr-3.1-atomic-write-result.md § 2.3` | Low |
| 12.5 | 🟡 MEDIUM | Error Handling | `parse_baseline.py` silently swallows `ValueError` on swap/profit parse → undercount per-slot net_pnl with no warning | `parse_baseline.py:239-247` | Low |
| 12.6 | 🟡 MEDIUM | Defense in Depth | fix-round-11 §11.3 chose Option A only (orchestrator-side gate); CircuitBreaker `RecordOpen`/`RecordClose` lack pre-Init guard for future direct callers | `CircuitBreaker.mqh:137-156` | Low |
| 12.7 | 🔵 LOW | State Reconciliation / Registry | IMPL-068 expiry 2026-05-18 depends on IMPL-062 which is unstarted → likely registry-renewal cycle | `deferred-ac-registry.md:60` + `impl-plan.md § Open Risks` | Low |
| 12.8 | 🔵 LOW | Doc / Architecture | `Slot_S.mqh:224` "OrderSend deferred to IMPL-053+" comment stale post-IMPL-060; pattern likely on all 21 slots | `slots/Slot_S.mqh:222-238` (+ XS-12.3) | Low |

---

## Recommendation

**Needs immediate attention before Tier 1.5 walk batch-2 runs.** Findings 12.1 + 12.3 + 12.4 form a closure-rule trap: if the operator runs `atomic_write_kill_100.ps1` as-is, the harness will report `verdict=PASS` and the IMPL-064 deferred-AC row will be marked Done — but NFR-3.1 ("AtomicFile.mqh write must survive simulated mid-write kill 100/100 trials") will be **empirically untested**. This is the exact Dim #11 defect class (71% defect rate in deferred-AC pool per Shark CMS 2026-04 dogfood) that the closure-rule discipline was added to prevent.

**Fix priority:**
1. **12.1 (CRITICAL)** — `.ini` `[TesterInputs]` override OR harness `-StateDir` change so spike write path == harness inspect path (~10 LOC).
2. **12.3 (HIGH)** — replace fixed 50-500ms sleep with poll-then-attack pattern + bump `InpTotalWrites` so attack window lands inside an active loop (~30 LOC).
3. **12.4 (MEDIUM)** — same `.ini` edit as 12.1 + amend `nfr-3.1-atomic-write-result.md § 2.3` claim (~6 LOC each).
4. **12.2 (HIGH)** — switch `IsPhoenicisMagic` to set-membership enumeration OR forward to `IsKnownMagic` (~17 LOC + 1 SelfTest).
5. **12.5 (MEDIUM)** — `parse_baseline.py` stderr warning + anomaly counter (~10 LOC).
6. **12.6 (MEDIUM)** — `CCircuitBreaker::RecordOpen/Close` pre-Init NULL-logger guard + Print fallback (~10 LOC + SelfTest).
7. **12.7 (LOW)** — explicit `Blocks: IMPL-062` column in registry row OR proactive expiry extension (~3 LOC).
8. **12.8 (LOW)** — comment cleanup across all 21 slots + Open Risks R-7 row (~70 LOC mechanical).

**Plan Staleness Sentinel:** 6 closures since R07 — within 10-closure threshold ✅ but Mid-Phase Audit P4 counter at 6 ≥ 5 trigger. R12 + Tier 1.5 walk batch-2 collectively satisfy that audit semantic. `/impl-plan-review all` can wait until after IMPL-062 closes (so the review captures the full P4 tail in one pass).

**Cross-cutting observation:** Findings 12.1 + 12.3 + 12.4 share a root cause — the IMPL-064 task closed in parallel with IMPL-061 + IMPL-068 in a 3-subagent fan-out (commit `d681cc4`). Under parallel batch closure, no single subagent had end-to-end ownership of "harness writes to + harness inspects + .ini configures" the same path. Recommend that future parallel batches that touch a multi-file contract (here: 1 spike + 1 .ini + 1 PowerShell harness + 1 report) include a final consolidation step that runs the full chain headless (even with `-DryRun` for the live taskkill bit) before commit. The rebuttal-round-08 § Phase 5 mechanical gate #6 (file integrity) catches doc trailer corruption; an analogous "artifact contract roundtrip" gate would have caught this.

**On the structural quality of new closures:**
- IMPL-FIX-001 + FIX-002 are surgical (~5 LOC total) and correctly scoped ✅.
- IMPL-061 `parse_baseline.py` is a clean 400-LOC stdlib parser with sum=$24.27M exact match ✅ (modulo Finding 12.5 silent fallback).
- IMPL-068 `adr-008-force-clear-validation.md` is a thorough 295-LOC pipeline doc + amendment template — well-structured + the only concern is timing dependency on IMPL-062 (Finding 12.7).
- IMPL-064 is structurally complete (PowerShell + report skeleton present) but its **test contract is broken** (Findings 12.1/12.3/12.4) — this is the heaviest finding cluster of the round.

The R11 fix surface (lifecycle flags + 5-layer guard topology) verified clean ✅ — no regression detected in `core/Orchestrator.mqh` or `domain/EnumTypes.mqh` beyond the IsPhoenicisMagic semantic gap noted in 12.2.
