# PhoenicisNex EA Service Rules (MQL5 + MetaTrader 5 platform)

## Project Structure

```
MQL5/Experts/PhoenicisNex/
├── PhoenicisNex.mq5         # entry point ≤ 500 LOC — OnInit/OnTick/OnDeinit/OnTester thin wrapper
├── inputs/                  # 5 files; ≥ 80 input declarations (NFR-4.3)
│   ├── Inputs_General.mqh
│   ├── Inputs_TimeGates.mqh
│   ├── Inputs_Slot_<X>.mqh  # × 21 (1 per slot; group="Slot X" annotation per NFR-6.3)
│   ├── Inputs_Logging.mqh
│   └── Inputs_Pending.mqh
├── core/                    # Orchestrator, BootstrapValidator, SlotRegistry, EAState
├── slots/Slot_<X>.mqh       # × 21 (1 file per slot per NFR-4.2)
├── services/                # 11 services (IndicatorService, MarketContextBuilder, PortfolioState, ...) — post-BT-002 + TD Round 09 Finding 09.1 count correction 2026-05-18 (12→11; pre-BT-002 narrative was off-by-one): CircuitBreaker.mqh deletion pending impl-code cleanup; ADR-013/014 reverted
├── domain/                  # Pure types (MarketContext, SlotState, EnumTypes, CSlotBase) — no service deps
├── helpers/                 # CommentParser, PipMath, JsonWriter, AtomicFile, Timestamp — pure utility
└── libs/                    # Legacy lib re-use (TD assess per file)
```

LOC budget per file (NFR-4.1 ≤ 5,000): slots 800-2,000 (max 5,000 → split `Slot_X_Entry.mqh` + `Slot_X_Exit.mqh`); services 200-800; core/domain/helpers ≤ 500; inputs ≤ 200; entry ≤ 500.

## Naming Conventions
- **Member vars:** `m_*` (e.g., `m_logger`, `m_portfolio`)
- **Globals:** `g_*` — avoid in slots (use injected constructor params instead)
- **Inputs:** `Inp<SlotId><Param>` with `group="Slot <X>"` annotation (NFR-6.3)
- **Files:** `PascalCase.mqh` (e.g., `Slot_BI.mqh`, `RiskManager.mqh`)
- **Methods:** PascalCase public, `_camelCase` private; getters omit `Get` prefix when noun-style
- **Enums:** `E<Name>` prefix (e.g., `EEAState`, `EPendingState`, `ESeverity`)

## Architecture Rules (per CLAUDE.md §3)
- 5-layer dependency direction: `core/` → `slots/` → `services/` → `domain/` → `helpers/` (top depends on bottom)
- Slot-to-slot communication ONLY via `PortfolioState.GetByMagic()` — `slots/*` ห้าม `#include "slots/<other>"` <!-- source: ADR-012 -->
- All slots inherit `CSlotBase` abstract — pure-virtual methods enforce contract <!-- source: ADR-002 -->
- Service injection via constructor (Composition Root in `core/Orchestrator.mqh`) — no service locator <!-- source: TD-02 §9.1 -->
- 2-phase init for circular deps (Logger ↔ StatePersistence step 4a; StatePersistence ↔ PortfolioState step 5a) <!-- source: TD-02 §7.4 -->
- Every Init() returning `false` → orchestrator MUST call `CleanupPartialInit(failed_step)` and return `INIT_FAILED` (8 sites in OnInit Phase C per TD-02 §7.4.1)

## MQL5/MT5-specific idioms
- **Double comparison:** never `==` with doubles — use `NormalizeDouble(x, _Digits)` or tolerance per `mql-developer § Critical Gotchas`
- **Pip arithmetic:** use `helpers/PipMath.mqh::ToPoints(pips)` — handles 4-digit vs 5-digit broker per `mql-developer`
- **Filling policy:** detect via `SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE)` — never hardcode FOK/IOC
- **Indicator handles:** create in `IndicatorService::Init`; release in `ReleaseHandles()` on OnDeinit; validate `INVALID_HANDLE` 100% (NFR-3.2)
- **Trade API:** ALL CTrade calls go through `RiskManager::OpenOrder` or `OpenOrder<X>` helper — slots ห้าม instantiate CTrade ตรง
- **Series arrays:** explicit `ArraySetAsSeries(arr, true)` — never assume default
- **Strict mode:** every `.mqh` opens with `#ifndef PHOENICISNEX_<LAYER>_<NAME>_MQH` include guard

## Error Handling
- **Result pattern:** services return `bool` + populate `ESeverity` log; orchestrator logs + escalates (no exception in MQL5)
- **Fail-fast on OnInit:** any service Init() returning false → `CleanupPartialInit` → `INIT_FAILED` (no recovery in OnInit Phase B/C)
- **Degrade-but-continue on OnTick:** journal write fail → log warn + continue trade (NFR-2.2 overshoot policy); state save fail → log error + retry next tick (do not block trade)
- **Halt path:** ⚠️ **post-BT-002 (2026-05-17)** CircuitBreaker mechanism reverted (3 false-positive classes); replacement detector TBD. Until then, halt triggers reduce to: (1) sustained journal failure / (2) state.json corruption / (3) symbol whitelist breach in OnInit → `EAState::SetHalted(reason)` BEFORE next exit pass (per ADR-010 + Claim 01.3). Once `services/CircuitBreaker.mqh` is deleted in impl-code cleanup, `core/Orchestrator.mqh::OnTradeTransaction` ping-pong dispatch + `OnTick CheckPingPong` call site MUST also be stripped (BT-002 cascade).

## Testing
> Full 4-gate Definition of Done in `.claude/rules/testing.md`. Per-task workflow:

🔴 **Recompile-after-edit rule (per user remark 2026-05-18 — CLAUDE.md §6):** ทุก `.mq5` / `.mqh` edit MUST trigger G1 immediately — ห้าม batch-then-compile-at-end (silent drift per fix-round-15 R16 §16.1). MT5 install path = `origin.txt` (UTF-16LE, decode required); MQL5 tasks MUST read SKILLs first.

- **G1 Compile:** `"$METAEDITOR" /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log` (resolve `$METAEDITOR` from `origin.txt`) → check `.compile.log` for `Result: 0 errors, 0 warnings`. Use `mql-developer` SKILL for syntax patterns + `mt5-log-reader` SKILL for `.compile.log` UTF-16LE decode.
- **G2 Smoke:** headless attach via test .ini (NOT GUI chart-drop) → grep `[system][ev=init_ok]` in Experts log first 5 ticks. `mt5-log-reader` SKILL.
- **G3 Headless backtest:** `"$TERMINAL64" /config:simulation/headless-tests/<task>.ini` with `Visual=0` + `ShutdownTerminal=1` (commit `.ini` per TD-02 §13.6); follow `mt5-headless-backtest` SKILL 10-step flow.
- **G4 Log review:** parse Tester log (iconv UTF-16LE → UTF-8 → grep) + journal records via jq filters against `trade-journal-schema.yaml`; reference `mt5-log-reader` SKILL.

### Test Execution Safety (MQL5-specific)
- **No native unit-test framework** in MQL5 ecosystem (per BA `01 § 6.2 Won't Permanent`) — empirical verification = compile log + Strategy Tester log + journal artifact
- **Hang protection:** Strategy Tester window has 1-hour wall-clock cap by default; for long backtests use `mt5-headless-backtest § Step 6` polling loop with explicit timeout
- **Process hygiene:** `mt5-headless-backtest § Step 3` — close foreground `terminal64.exe` before headless launch (data-dir lock); `Get-Process -Name terminal64` to detect orphans
- **Reproducibility:** every test run pins to a committed `simulation/headless-tests/<name>.ini`; never invoke ad-hoc Tester params

## Commit Format
- `[feat:ea] short description` (or `fix:ea`, `refactor:ea`, etc.)
- Include `Why:` line + ADR citation if architectural
- ⚠️ Compile artifacts (`.ex5`, `.compile.log`) are local — do NOT commit
