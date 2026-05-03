# Code Review Fix Round 07

| Field | Value |
|-------|-------|
| **Round** | 07 |
| **Review File** | `docs/code-review/review-round-07.md` |
| **Date** | 2026-05-04 |
| **Fixer Persona** | Impl Engineer (Senior Full-Stack — `andm-impl-engineer`) |
| **Source code touched** | 3 files (`slots/Slot_P.mqh` + `services/PendingMachineRegistry.mqh` + `docs/api-specs/state-persistence-schema.yaml`) |
| **G1 verification** | 3/3 affected spikes (Spike_Slot_P / Spike_Slot_BI / Spike_PendingMachineRegistry) — 0 errors / 0 warnings (MetaEditor64 sequential compile) |

## Verdict Summary

| # | Finding | Severity | Verdict | Cascaded Files | Commits |
|---|---------|----------|---------|----------------|---------|
| 07.1 | Slot_P payload injects non-schema `"dir"` field | 🟠 HIGH | **Accept** (Option A) | Slot_P.mqh + state-persistence-schema.yaml | bundled with 07.2/07.3 |
| 07.2 | Slot_P bypasses `EnterPPending` canonical helper | 🟠 HIGH | **Accept** | Slot_P.mqh (2 sites — auto-resolved by 07.1 fix) | bundled with 07.1/07.3 |
| 07.3 | Sub-mode lock resets BR-6.4 70-bar legacy timeout | 🟡 MEDIUM | **Accept** | PendingMachineRegistry.mqh (+`OverwritePPayload`) + Slot_P.mqh | bundled with 07.1/07.2 |
| 07.4 | 38 LOC dead `MqlTradeRequest` scaffold at 2 sites | 🟡 MEDIUM | **Accept** | Slot_P.mqh | separate housekeeping commit |
| 07.5 | Self-contradicting comment + silent return on degenerate `_PipSize()` | 🔵 LOW | **Accept** | Slot_P.mqh | separate housekeeping commit |

**Accepted:** 5/5 (0 reject, 0 partial).

## Accepted Findings — Fixes Applied

### Fix for Findings 07.1 + 07.2 + 07.3 (bundled — single architectural drift class)

**Verdict:** Accept all three (Option A per reviewer recommendation — auto-resolves the chain).

**Approach:** P-Pending direction encoded via signed `diff_sl` (BUY ≥ 0, SELL < 0). Stays inside the canonical `PendingMachineState_PVariant` schema (no new field). Slot_P now routes through `EnterPPending(...)` for IDLE→PENDING entry and through new `OverwritePPayload(...)` for sub-mode lock — the latter preserves `pending_started_bar` so BR-6.4 70-bar legacy timeout cannot be silently extended.

**Schema change (`docs/api-specs/state-persistence-schema.yaml § PendingMachineState_PVariant.diff_sl`):**
- Description amended to document the sign convention: *"Sign convention (Slot_P only): BUY ≥ 0, SELL < 0 — absolute value carries the pip distance, sign carries direction. Slot_P uses MathAbs(diff_sl) for threshold comparisons + (diff_sl >= 0.0) for direction."*
- No structural / typing change — `type: [number, "null"]` unchanged. Round-trip safe.

**PMR change (`services/PendingMachineRegistry.mqh`):**
- New public method `OverwritePPayload(EPSubMode mode, double diff_sl, double band_ratio)` — re-builds canonical payload via `_BuildPPayload(...)` and writes to `m_machines[PM_P].pending_payload` only. Crucially does **not** touch `pending_started_bar` (vs `EnterPending` which resets it). Logs `[pending][ev=payload_overwrite]` via injected logger.

**Slot_P changes (`slots/Slot_P.mqh`):**
- Phase A (IDLE→PENDING entry, lines ~377-394): hand-rolled `StringFormat("{... \"dir\":...}")` + raw `EnterPending(PM_P, payload, bar)` replaced with:
  ```mql5
  double signed_diff_sl = buyBase ? diff_sl_pip : -diff_sl_pip;
  m_pending.EnterPPending(PSUB_N, signed_diff_sl, band_ratio, ctx.bar_index_h4);
  ```
- Phase B (PENDING re-read + sub-mode lock, lines ~398-427): direction read via `bool isBuy = (m_pending.GetPDiffSL() >= 0.0)` (was brittle `StringFind(payload, "\"dir\":\"BUY\"")`); `diff_sl_abs = MathAbs(signed_ds)` introduced for threshold/SL distance use; sub-mode lock branch swaps `EnterPending(PM_P, ...)` → `OverwritePPayload(resolved, signed_ds, band_rat)`. `_ResolvePSubMode(ctx, diff_sl_abs)` invoked with absolute value.

**Architectural assertion post-fix:**
- `grep -nE 'EnterPending\(PM_P,' MQL5/Experts/PhoenicisNex/slots/` → **0 hits** ✅ (only PMR's own `EnterPPending` / `OverwritePPayload` invoke the canonical builder).
- `grep -n '\\"dir\\":' MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` → **0 hits** ✅.

**Files modified:**
- `MQL5/Experts/PhoenicisNex/slots/Slot_P.mqh` — Phase A/B refactor (~25 LOC delta net).
- `MQL5/Experts/PhoenicisNex/services/PendingMachineRegistry.mqh` — +`OverwritePPayload(...)` (16 LOC).
- `docs/api-specs/state-persistence-schema.yaml` — sign-convention amendment to `diff_sl` description (PVariant only; +6 LOC).

**Why Option A over Option B:** Option B (amend schema to add `dir` field + add `GetPDir()` getter + extend `_BuildPPayload` signature) would have touched PMR API surface, PMR SelfTest case 4 (`_BuildPPayload` round-trip), and all schema consumers. Option A is a 1-bit channel through an existing field — zero PMR API surface change, zero SelfTest update needed, and follows the same "collapse drift to a single canonical site" pattern that fix-round-06 06.1 used for pip arithmetic.

### Fix for Finding 07.4: Strip dead `MqlTradeRequest`/`MqlTradeResult` scaffold

**Verdict:** Accept.
**Scope:** 2 sites in `slots/Slot_P.mqh` — pyramid path (lines 338-349) + primary path (lines 456-467). 38 LOC of dead struct-init + 2 unused `MqlTradeResult res` declarations.
**Changes:**
- Replaced `MqlTradeRequest req = {}; MqlTradeResult res = {}; req.action = ...; req.symbol = _Symbol; req.volume = ...; req.type = ot; req.price = ...; req.sl = ...; req.tp = 0.0; req.comment = ...; req.magic = MAGIC_P; req.type_filling = ORDER_FILLING_FOK;` (12 fields × 2 sites = 24 assignments + 2 decls + 12 comment lines) with single-call log-intent (`m_logger.Info("SlotP", "entry_signal[_pyramid]", ...)`), matching the Slot_BI / Slot_R Phase-1-stub precedent.
- Comment string preserved verbatim (`"P,MA,PX,1,SL"` / `"P,MA,PH,1,SL"` / `"PI,MA,E,1,SL"`) so the G4 log-assertion E-AC remains observable on the same Info line at IMPL-053+ runtime.
- Removed unreferenced `ENUM_ORDER_TYPE ot = ...` lines that were only consumed by the dead `req.type` assignment (auto-DCE-able but explicit removal keeps the file readable).

**Net delta:** −36 LOC across the two sites. No new logic, no test impact, no compile dependency churn. Slot_P now consistent with the 20 sibling slots' Phase-1-stub shape.

### Fix for Finding 07.5: Loud failure on degenerate `_PipSize()` + comment cleanup

**Verdict:** Accept.
**Scope:** `slots/Slot_P.mqh::ManageExits` lines 494-505 + line 517.
**Changes:**
- Replaced 5-line self-contradicting comment block (the *"actually NO — startsWith ... we use both calls below"* mid-thought correction) with a single-line explanation: `"P," and "PI," need separate GetTicketsForSlot calls — startsWith semantic excludes "PI," from "P," prefix-match (comment[1]='I'≠',').`
- Replaced silent `if(pip_size <= 0.0) return;` with loud-failure branch per NFR-5.1 + CodeWiki §6.2 P2.3:
  ```mql5
  if(pip_size <= 0.0)
    {
     m_logger.Error("SlotP", "degenerate_pip_size", MAGIC_P,
                    StringFormat("_PipSize() returned %.10f — exit pass aborted; "
                                 "symbol metric corrupt (NFR-5.1 surfacing)", pip_size));
     Alert("[PhoenicisNex] Slot_P degenerate _PipSize() — exit pass aborted");
     return;
    }
  ```
- Dropped dead defensive `if(StringFind(c, "PI,") == 0) continue;` filter inside the `tickets_p[]` loop (line 517 pre-fix). `PortfolioState::GetTicketsForSlot(MAGIC_P, "P,", ...)` already excludes `"PI,"` tickets via startsWith semantic at the source — the secondary filter was reachable only on broker-mutated comments, and broker-mutation would equally subvert `GetTicketsForSlot` itself, so the filter is no longer load-bearing.
- The defensive same-shape check inside private helper `_HasActivePOrder` (line ~140) is preserved — its post-`PositionSelectByTicket` filter rebuilds an output array that the caller `_ParentProfitPipsAtLeast` indexes by position; that's a structurally distinct call path and was not flagged by the reviewer.

**Why kept LOW:** `_PipSize() <= 0.0` is essentially impossible on EURUSD; the change is anticipatory hardening for the future Phase-2 multi-symbol trigger (per BA `03 § 5 Note`).

## Rejected Findings — Evidence

None. All 5 findings accepted with concrete fixes.

## Anti-Regression Sweep

| Pattern | Pre-fix hits | Post-fix hits | Rationale |
|---------|--------------|---------------|-----------|
| `EnterPending\(PM_P,` in `slots/` | 3 | **0** ✅ | Forbidden — only PMR's own `EnterPPending`/`OverwritePPayload` may build the canonical P payload. |
| `\\"dir\\":` in `slots/Slot_P.mqh` | 3 | **0** ✅ | Schema-foreign field eliminated. |
| `MqlTradeRequest req` in `slots/Slot_P.mqh` | 2 | **0** ✅ | Phase-1 stub uniform with 20 sibling slots (Slot_BI / Slot_R precedent). |
| `_PipSize() <= 0.0` silent return in `slots/Slot_P.mqh::ManageExits` | 1 | **0** ✅ | Replaced with `Logger.Error` + `Alert` per NFR-5.1. |

## G1 Compile Evidence

```
=== Spike_Slot_P ===
Result: 0 errors, 0 warnings, 435 ms elapsed, cpu='X64 Regular'
=== Spike_Slot_BI ===
Result: 0 errors, 0 warnings, 424 ms elapsed, cpu='X64 Regular'
=== Spike_PendingMachineRegistry ===
Result: 0 errors, 0 warnings, 1495 ms elapsed, cpu='X64 Regular'
```

G2–G4 deferred per header-only `.mqh` precedent — gates activate at IMPL-053+ Composition Root (Orchestrator wiring of CSlotP into the registry + RiskManager `OrderSend` plumbing).

## Summary

| Metric | Value |
|--------|-------|
| Total Findings | 5 |
| Accepted | 5 |
| Rejected | 0 |
| Partial | 0 |
| Files Modified | 3 (`slots/Slot_P.mqh` + `services/PendingMachineRegistry.mqh` + `docs/api-specs/state-persistence-schema.yaml`) |
| Tests Added/Updated | 0 (no PMR SelfTest amendment needed — `OverwritePPayload` re-uses tested `_BuildPPayload`; round-trip already covered by SelfTest Case 4. SelfTest extension for `pending_started_bar` invariance under `OverwritePPayload` is reasonable follow-up but out of scope for this round per reviewer-noted Low effort.) |
| Commits | 1 (all 5 fixes touch `slots/Slot_P.mqh`; bundling to a single commit avoids splitting in-file hunks; reviewer's "bundle 07.1+07.2+07.3 / separate 07.4+07.5" suggestion was a logical grouping that maps to one physical commit here) |

**Recommendation:** Ready for next code review round when IMPL-053+ Orchestrator wiring lands (will exercise `OverwritePPayload` end-to-end alongside RiskManager `OrderSend` plumbing). IMPL-039 + IMPL-034 attestation surface stable; no Tier-1 task ACs reopened, no Deferred-AC registry rows affected.
