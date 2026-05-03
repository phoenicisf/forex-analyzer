# G4 Fix Attestation — Bucket B Drift Audit Trail (NFR-1.8)

> **Purpose:** consolidated audit trail for the two **G4 critical fixes** to PhoenicisN2.10 baseline behaviour that intentionally drift the rewrite away from the baseline (Bucket B per NFR-1.8). Every G4 fix has its own commit + evidence path here so IMPL-063 (P4) regression sign-off can attribute drift to the correct fix.
>
> **Bucket B vs Bucket A:** Bucket A = unintended drift (≤ 25% Net Profit deviation per NFR-1.1); Bucket B = intentional behavioural change (no hard cap; documented separately per NFR-1.8). G4 fixes are Bucket B by definition.
>
> **Header status:** PRELIMINARY — evidence rows below cite structural/spike artifacts only (header-only `.mqh` per IMPL-018+ precedent). Live journal evidence paths land at IMPL-053+ Orchestrator wiring + first headless backtest run. This file is updated row-by-row as each E-AC drains from `deferred-ac-registry.md`.

---

## Fix Roster

| # | Fix tag | Spec source | Bug summary | Closure task |
|---|---------|-------------|-------------|--------------|
| 1 | **G4-BR-7.2 — Slot J Magic-J iteration** | BR-7.2; CodeWiki §6.2 P2.6 | `ExtraTakeProfit_J` iterated `MagicF` (=201) instead of `MagicJ` (=206) → J orders never had take-profit gates evaluated | IMPL-022 |
| 2 | **G4-ADR-009 — Slot BI SL inheritance** | BR-7.1; FR-3.3; ADR-009; CodeWiki §6.2 :20326 :20357 | BI orders opened with naked `SL=0` → unbounded downside on adverse move | IMPL-039 |

---

## Fix #1 — IMPL-022 (G4-BR-7.2 Slot J)

| Field | Value |
|-------|-------|
| Commit | `d386ea6` `[feat:ea] IMPL-022 Slot_J — CD-follower + ⚠️ G4 fix BR-7.2 (Bucket B)` |
| Closed | 2026-05-03 |
| Source files | `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` (3 explicit `// G4 fix BR-7.2 — was MAGIC_F` comments at GetByMagic + GetTicketsForSlot + log sites in ManageExits) |
| Spike artifact | `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_J.mq5` — G1 0err/0warn/534 ms; 6 SelfTest cases pass |
| Smoke ini | `simulation/headless-tests/slot_J_smoke.ini` (committed per TD-02 §13.6) |
| Structural evidence | `docs/state/_session-handoff/IMPL-022-evidence-20260503.md` |
| Live journal evidence | ⏳ pending IMPL-053+ Orchestrator + 60-day Tester run (deferred-ac row IMPL-022 expiry 2026-05-17) |
| Bucket B drift estimate | Take-profit gate now active for J → win rate may improve, gross profit may shrink (per ADR analysis); regression sign-off at IMPL-063 |

---

## Fix #2 — IMPL-039 (G4-ADR-009 Slot BI)

| Field | Value |
|-------|-------|
| Commit | `bc7f558` `[feat:ea] IMPL-039 Slot_BI - G4 critical SL inheritance fix per ADR-009 (Bucket B)` |
| Closed | 2026-05-04 |
| Source files | `MQL5/Experts/PhoenicisNex/slots/Slot_BI.mqh` (SL inheritance per ADR-009 Option A in `Evaluate()`; explicit `// G4 fix ADR-009` markers + `(G4 fix ADR-009)` log suffix) · `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_BI.mqh` (`InpBISlFallbackPips=80.0` for ADR-009 fallback paths) |
| Spike artifact | `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5` — G1 0err/0warn/425 ms; 6 SelfTest cases pass (Magic=MAGIC_B=214 / SlotId="BI" / DependsOn=0 / PendingState=IDLE / range / non-empty) |
| Smoke ini | `simulation/headless-tests/slot_BI_smoke.ini` (committed per TD-02 §13.6) |
| Structural evidence | `docs/state/_session-handoff/IMPL-039-evidence-20260503.md` |
| Live journal evidence | ⏳ pending IMPL-053+ Orchestrator + RiskManager OrderSend + 60-day Tester run with B+BI active. Expected journal field: `signal_context` containing `sl_inherit=B_parent_<ticket>;sl_distance_pip=<N>` (or `sl_inherit=fallback_pip_floor` on ADR-009 fallback path) |
| Bucket B drift estimate (per ADR-009 § Consequences) | BI orders previously naked → now bounded SL → win rate may decrease slightly in losing scenarios (BI now stops out), Max DD% should improve, PF should remain near-flat; regression sign-off at IMPL-063 |

### ADR-009 implementation notes

- **Anchor:** earliest-opened B parent (PortfolioState `ticket_ids[0]` per FIFO push semantic) — Option A locked in ADR-009 over latest/average/recompute.
- **Pip arithmetic:** routed through `_PriceToPips` / `_PipsToPrice` CSlotBase helpers (Round-06 06.1) — uses CPipMath when wired or canonical 5/3-digit fallback. No 19-way drift risk.
- **Fallback pathway:** `parent_sl == 0` (legacy / pre-fix) OR computed `sl_distance_pip == 0` → `InpBISlFallbackPips` (80 pip default). ADR-009's full Bollinger fallback (BBBot − 10 / BBTop + 10) deferred to IMPL-062 (P4) since M15 BB indicator not yet in MarketContext; pip floor preserves the "non-zero SL" G4 contract until then.
- **Spec deviation note:** IMPL-039 S-AC #3 reads "OrderSend SL parameter = parent B's open price ± m_pip.ToPoints(parent_sl_pip) per direction" — ADR-009 Option A locks the SL anchored at `BI.entry_price`, not `parent.open_price`. Implementation follows ADR-009 (architectural primary). Plan-text minor wording slip; reviewer acceptance recorded here.

---

## Cross-cutting

- **Verification window:** IMPL-063 (P4) — full 5-yr 2021-2025 EURUSD H4 backtest with G4 fixes ENABLED vs DISABLED via compile flag `DISABLE_G4_FIXES`; isolates Bucket B drift from Bucket A drift (NFR-1.1 baseline).
- **Bucket B budget:** no hard cap (intentional change). User re-decides escalation only if drift > 25% Net Profit per `trading-baseline.md § Validation Strategy` — at which point the fix is a "bug fix that erased baseline edge" and warrants design review.
- **Phase 2 forward-compat:** ADR-009 § Revisit-when notes that other pyramid pairs (JI / GI) added in Phase 2 should apply the same arithmetic + ADR template. Update this file with new Fix #N rows when those land.
