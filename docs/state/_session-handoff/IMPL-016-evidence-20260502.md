# IMPL-016 Evidence — BootstrapValidator::ValidateSymbol EURUSD whitelist

| Field | Value |
|---|---|
| Task | IMPL-016 [XS] [ea] — core/BootstrapValidator::ValidateSymbol() (EURUSD whitelist) |
| Closed | 2026-05-02 |
| Commit | dbffd5f `[feat:ea] IMPL-016 — ValidateSymbol EURUSD whitelist (FR-1.2 + BR-9.1)` |
| Phase | P1 — Foundation |
| Closure mode | Parallel batch via `/impl-task parallel` (orchestrator: Opus 4.7; subagent: Sonnet 4.6) |
| Shared-context | `docs/state/_parallel-context/impl-task-parallel-20260502-2326.md` |

## File edited

- `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh` (EDIT, +12 / -4 LOC; total now 540 LOC)
  - Lines 489-493 stub `return true;` body replaced with full EURUSD whitelist implementation
  - Header comment block lines 482-488 updated — TODO IMPL-016 line removed; replaced with concise implementation note mirroring `ValidateSlotRegistry` style

## Implemented body (verbatim)

```mql5
bool CBootstrapValidator::ValidateSymbol() const
  {
   if (_Symbol != "EURUSD")
     {
      string msg = StringFormat("symbol=%s expected=EURUSD (FR-1.2 + BR-9.1)", _Symbol);
      m_logger.ErrorBypassThrottle("system", "symbol_not_whitelist", 0, msg);
      Alert("PhoenicisNex requires EURUSD — current chart symbol is " + _Symbol);
      return false;
     }
   return true;
  }
```

## Compliance points (per shared-context §6.D.2)

- ✅ `ErrorBypassThrottle` (not regular Error) — boot-time alerts must NEVER be throttled per ADR-011; mirrors IMPL-015 ValidateInputs precedent
- ✅ `Alert()` MT5 native popup — NFR-5.1 silent-halt prohibition + security.md §Halt + Failure Surfacing
- ✅ Order: log → Alert → return false (audit trail before user surface before orchestrator INIT_FAILED)
- ✅ Event tag `ev=symbol_not_whitelist` is canonical — matches future `EAState::SetHalted("symbol_not_whitelist")` reason at journal `[ev=halt][reason=symbol_not_whitelist]` (IMPL-053+ wiring)

## Static checks (G1-G4 deferred — header-only .mqh per IMPL-015/042 precedent)

| Check | Command | Result |
|---|---|---|
| Body present | `grep -A 10 'CBootstrapValidator::ValidateSymbol' core/BootstrapValidator.mqh` | shows `_Symbol`, `ErrorBypassThrottle`, `"symbol_not_whitelist"`, `Alert(`, `return false`, `return true` ✅ |
| TODO removed | `grep -c 'TODO IMPL-016' core/BootstrapValidator.mqh` | 0 ✅ |
| Other 3 methods untouched | `grep -c 'CBootstrapValidator::ValidateInputs\|CBootstrapValidator::DetectDigitMultiplier\|CBootstrapValidator::ValidateSlotRegistry' …` | 3 ✅ (no balloon) |
| LOC parity | `wc -l core/BootstrapValidator.mqh` | 540 (was ~533) — +7 lines for body + header note ✅ |

## S-AC closure

- [x] Returns `false` ถ้า `_Symbol != "EURUSD"`; returns `true` ถ้า `_Symbol == "EURUSD"` — verified by body inspection
- [x] Logger.Error + Alert ครบทั้งคู่ก่อน return false — `ErrorBypassThrottle("system","symbol_not_whitelist",0,msg)` emits structured log; `Alert(...)` raises MT5 native popup; both fire before `return false`

## E-AC deferral (per Empirical Closure Discipline — cite blocking task)

- [ ] Attach EA on `GBPUSD` chart → OnInit returns INIT_FAILED + Alert popup + journal `[ev=halt][reason=symbol_not_whitelist]` `[probe]` + `[log-assertion]` — **deferred to IMPL-018+** (entry .mq5 + Strategy Tester run prerequisite); structurally verified vs shared-context §6.D.2 source spec

Closure citation matches IMPL-005/007/015/042 precedent (specific blocking task ID, not "deferred to operator-runtime" — Code Review Dim #11 compliant).

## Suggested next task

IMPL-006 + IMPL-010 closed in same batch → P1 Phase 17/17 reached → P1 Phase Gate becomes nominate-able. Plan Staleness Sentinel currently 14/10 (will rise to 17/10 after this batch) — recommend `/impl-plan-review all` + `/impl-review all` before P1 Phase Gate close + P2 task start.
