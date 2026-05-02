# IMPL-015 Evidence Artifact — 2026-05-02

**Task:** IMPL-015 — `core/BootstrapValidator::ValidateInputs()` (range checks per FR-1.4)
**Phase:** P1 Foundation
**Status:** Completed — structural implementation done; E-ACs deferred per precedent

---

## 1. Files Created

| File | Line Count | Description |
|------|-----------|-------------|
| `MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh` | ~290 | CBootstrapValidator class — 4 methods: ValidateInputs (full body, 39 guards), ValidateSymbol (stub), DetectDigitMultiplier (stub), ValidateSlotRegistry (body) |
| `docs/state/_session-handoff/IMPL-015-evidence-20260502.md` | this file | Evidence artifact |

---

## 2. Guard Count Audit — ValidateInputs()

> S-AC requires ≥ 30 `if (...) { ...; return false; }` blocks.

**SECTION 1 — Inputs_General.mqh (Guards 1–17)**

| # | Input | Condition | Rule |
|---|-------|-----------|------|
| 1 | `InpInteruptRatioDecrease` | `<= 0.0 \|\| > 100.0` | Ratio denominator (FR-1.4) |
| 2 | `InpMainOverloadRatioDecrease` | `<= 0.0 \|\| > 100.0` | Ratio denominator (FR-1.4) |
| 3 | `InpFIDValue` | `<= 0 \|\| > 10000` | Period must be positive (FR-1.4) |
| 4 | `InpLADXMLevel` | `<= 0.0 \|\| > 100.0` | ADX threshold (FR-1.4) |
| 5 | `InpLADXMLevelMin` | `<= 0.0 \|\| > 100.0` | ADX floor (FR-1.4) |
| 6 | `InpLADXMLevelMin >= InpLADXMLevel` | cross-input | Floor must be < threshold |
| 7 | `InpJPip1StBetweenC` | `< -1000 \|\| > 10000` | Relaxed lower (may be negative; default=-10) |
| 8 | `InpJPip1StBetweenD` | `< -1000 \|\| > 10000` | Relaxed lower (may be negative; default=-13) |
| 9 | `InpFRatioDecrease` | `<= 0.0 \|\| > 100.0` | Lot scale (BR-4.3) |
| 10 | `InpJRatioDecrease` | `<= 0.0 \|\| > 100.0` | Lot scale (BR-4.3) |
| 11 | `InpGRatioDecrease` | `<= 0.0 \|\| > 100.0` | Lot scale (BR-4.3) |
| 12 | `InpGORatioDecrease` | `<= 0.0 \|\| > 100.0` | Lot scale (BR-4.3) |
| 13 | `InpHRatioDecrease` | `<= 0.0 \|\| > 100.0` | Lot scale (BR-4.3) |
| 14 | `InpGRisk` | `<= 0 \|\| > 10000` | Risk percent (FR-1.4) |
| 15 | `InpMainRiskRatio` | `<= 0.0 \|\| > 10.0` | BR-4.1 special range |
| 16 | `InpLimitMaxLotSizeRatio` | `<= 0.0 \|\| > 100.0` | BR-4.2 special range |
| 17 | `InpNormalTakeProfitPIP` | `<= 0 \|\| > 10000` | TP baseline (FR-1.4) |

Inputs skipped (bool/enum): `InpUseCOverload`, `InpUseOverloadAutoRange`, `InpOverLoadUseLastLot`, `InpTradeOnHNN`, `InpZigZagPeriod` — 5 inputs, 0 guards.

**SECTION 2 — Inputs_TimeGates.mqh (Guards 18–28)**

| # | Input | Condition | Rule |
|---|-------|-----------|------|
| 18 | `InpMorningWindowMinutes` | `<= 0 \|\| > 10000` | BR-3.1 |
| 19 | `InpMondaySpreadThreshold` | `<= 0 \|\| > 10000` | BR-3.2/3.7 |
| 20 | `InpHolidayStartMonth` | `< 1 \|\| > 12` | BR-3.3 calendar month |
| 21 | `InpHolidayStartDay` | `< 1 \|\| > 31` | BR-3.3 calendar day |
| 22 | `InpHolidayEndMonth` | `< 1 \|\| > 12` | BR-3.3 calendar month |
| 23 | `InpHolidayEndDay` | `< 1 \|\| > 31` | BR-3.3 calendar day |
| 24 | `InpBanCCooldownBars` | `<= 0 \|\| > 10000` | BR-3.4 |
| 25 | `InpBanLCooldownBars` | `<= 0 \|\| > 10000` | BR-3.4 |
| 26 | `InpBanMCooldownBars` | `<= 0 \|\| > 10000` | BR-3.4 |
| 27 | `InpKLastOrderCooldownBars` | `<= 0 \|\| > 10000` | BR-3.4 |
| 28 | `InpGPauseCooldownBars` | `<= 0 \|\| > 10000` | BR-3.4 |

**SECTION 3 — Inputs_Pending.mqh (Guards 29–36)**

| # | Input | Condition | Rule |
|---|-------|-----------|------|
| 29 | `InpForceClearM_Bars` | `<= 0 \|\| > 10000` | ADR-008 |
| 30 | `InpForceClearT_Bars` | `<= 0 \|\| > 10000` | ADR-008 |
| 31 | `InpForceClearQ_Bars` | `<= 0 \|\| > 10000` | ADR-008 |
| 32 | `InpLegacyCBars` | `<= 0 \|\| > 10000` | BR-6.1 |
| 33 | `InpLegacyCAdxBars` | `<= 0 \|\| > 10000` | BR-6.2 |
| 34 | `InpLegacyRBars` | `<= 0 \|\| > 10000` | BR-6.3 |
| 35 | `InpLegacyPBars` | `<= 0 \|\| > 10000` | BR-6.4 |
| 36 | `InpLegacyForceBars` | `<= 0 \|\| > 10000` | BR-6.8 |

**SECTION 4 — Inputs_Logging.mqh (Guards 37–39)**

| # | Input | Condition | Rule |
|---|-------|-----------|------|
| 37 | `InpLogLevel` (lower) | `< (int)LOG_DEBUG` i.e. `< 0` | ADR-011 ESeverity range |
| 38 | `InpLogLevel` (upper) | `> (int)LOG_ERROR` i.e. `> 3` | ADR-011 ESeverity range |
| 39 | `InpErrorEscalationN` | `< 1` | ADR-011 escalation threshold |

Inputs skipped: `InpAlertOnError` (bool) — 1 input, 0 guards.

**Total guard count: 39 individual `if (...) { return false; }` blocks — PASS (required ≥ 30)**

---

## 3. S-AC Binding (impl-plan.md lines 477–480)

| S-AC | Requirement | Satisfied at |
|------|-------------|-------------|
| S-AC-1 | ≥ 30 checks across cross-slot + per-slot critical inputs | `core/BootstrapValidator.mqh` lines — 39 guards across 4 input files |
| S-AC-2 | Each violation: Logger Error with `slot=system, ev=invalid_input` via `ErrorBypassThrottle` (per ADR-011 boot-time) | Every guard block calls `m_logger.ErrorBypassThrottle("system", "invalid_input", 0, StringFormat(...))` |
| S-AC-3 | Fail-fast on first violation (no batch; first false `return false`) | `ValidateInputs()` has `return false` inside every guard; no accumulation loop |

---

## 4. E-AC Defer Reasons (mirror IMPL-042 pattern)

| E-AC | Kind | Defer reason |
|------|------|-------------|
| `[log-assertion]` smoke: set `InpFIDValue=-1` → `INIT_FAILED` + `[ev=invalid_input]` log assertion | `[log-assertion]` | Deferred to **IMPL-018+ + IMPL-053+** — requires entry `.mq5` to exist (IMPL-018+ ships entry point) AND Orchestrator `Init()` Phase C to call `if (!m_validator.ValidateInputs()) return INIT_FAILED;` (TD-02 §7.4 line 1654, IMPL-053+ wires it). Without the Orchestrator wiring, `ValidateInputs()` is never called during the backtest run. |
| `CleanupPartialInit` verification after `ValidateInputs()` returns false | `[log-assertion]` | Deferred to **IMPL-053+** — `CleanupPartialInit(failed_step)` is an Orchestrator responsibility (TD-02 §7.4.1 8 sites in OnInit Phase C). IMPL-015 implements the validator only; the orchestrator's cleanup call chain belongs to IMPL-053+. |

---

## 5. Self-Review Checklist (shared-context §6.G)

| # | Item | Result |
|---|------|--------|
| 1 | Security: no hardcoded secrets, no string concat for paths, `_Symbol` not used in this header | PASS — no secrets, no paths, no `_Symbol` reference. `_Symbol` reserved for `ValidateSymbol()` stub (IMPL-016). |
| 2 | Business logic: all 3 S-ACs satisfied | PASS — 39 guards (≥30), every guard uses `ErrorBypassThrottle`, fail-fast `return false` on first violation. |
| 3 | Error handling: fail-fast booleans, no silent swallow | PASS — every guard emits log + returns false; no swallowed errors. |
| 4 | Performance: no allocation in hot path | PASS — `ValidateInputs()` is called once at boot (OnInit Phase C), not in OnTick. No dynamic allocation. `StringFormat` calls are boot-time only. |
| 5 | Over-engineering: header-only, no extra utility classes | PASS — single class, no new utilities, no unnecessary abstractions. |
| 6 | Tests: G1–G4 deferred | PASS — `.mqh` header-only; G1 deferred to IMPL-018+ per IMPL-042 precedent. No tests to author this round. |
| 7 | Naming: `m_*` member, PascalCase public, include-guard correct | PASS — `m_logger`, `m_indicators`, `m_portfolio`; methods `Init`, `ValidateInputs`, `ValidateSymbol`, `DetectDigitMultiplier`, `ValidateSlotRegistry`; guard = `PHOENICISNEX_CORE_BOOTSTRAPVALIDATOR_MQH`. |

All 7 self-review checks: **PASS**

---

## 6. IMPL-016 Follow-up Note

`ValidateSymbol()` is currently a stub returning `true` with TODO comment:
```
// TODO IMPL-016: EURUSD whitelist per FR-1.2 + BR-9.1
```

IMPL-016 (XS) will implement the body:
```mql5
if (_Symbol != "EURUSD") {
   m_logger.ErrorBypassThrottle("system", "symbol_rejected", 0,
      StringFormat("symbol=%s (expected EURUSD per FR-1.2 + BR-9.1)", _Symbol));
   return false;
}
return true;
```
This is a serial-bundle candidate with IMPL-015 — same file already created.

---

## 7. Test Loop Result

- **G1 Compile:** Deferred — no entry `.mq5` yet (IMPL-018+)
- **G2 Smoke:** Deferred — no entry `.mq5` yet
- **G3 Headless backtest:** Deferred — requires orchestrator wiring (IMPL-053+)
- **G4 Log review:** Deferred — requires G3 run
- **Self-review:** PASS (all 7 items above)
- **Final full-suite run:** skipped
- **Filtered iteration count:** 0
