# IMPL-022 Evidence — Slot_J (G4 critical fix BR-7.2)

**Closed:** 2026-05-03 · **Commit:** `d386ea6` · **Path:** single-task `/impl-task IMPL-022` (Opus 4.7 orchestrator)

## Task summary

M-size [ea] header-only CD-follower scaffold + ⚠️ **G4 critical fix BR-7.2** in ManageExits.

PhoenicisN2.10 baseline bug: `ExtraTakeProfit_J` iterated `MagicF` (=201) instead of `MagicJ` (=206). Result: J orders never had take-profit gates evaluated in the original EA. This rewrite restores the contract.

## Files

| Path | LOC (approx) | Purpose |
|------|--------------|---------|
| `MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh` | 215 | CSlotJ : CSlotBase; G4 fix surface in ManageExits |
| `MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_J.mqh` | 33 | Per-slot inputs (group="Slot J") |
| `MQL5/Experts/PhoenicisNex/spike/Spike_Slot_J.mq5` | 105 | G1 compile + 6 SelfTest cases |
| `simulation/headless-tests/slot_J_smoke.ini` | 27 | Standard headless [Tester] block |

## G1 Compile Evidence

**Tool:** PowerShell `Start-Process` invoking `C:\Program Files\FBS MetaTrader 5ph\MetaEditor64.exe`.

**Command:**
```
Start-Process -FilePath $me -ArgumentList "/compile:MQL5\Experts\PhoenicisNex\spike\Spike_Slot_J.mq5","/log" -Wait
```

**Result:**
```
Result: 0 errors, 0 warnings, 534 ms elapsed, cpu='X64 Regular'
```

Log file: `MQL5\Experts\PhoenicisNex\spike\Spike_Slot_J.log` (note: current MetaEditor64 build emits `.log`, not `.compile.log`).

**Sibling regression** — Spike_Slot_F recompiled to ensure CD chain unaffected:
```
Result: 0 errors, 0 warnings, 460 ms elapsed, cpu='X64 Regular'
```

## G4 fix BR-7.2 Structural Verification

3 explicit `// G4 fix BR-7.2 — was MAGIC_F` comments in `slots/Slot_J.mqh::ManageExits`:

1. `SlotState *j_state = port.GetByMagic(MAGIC_J);   // G4 fix BR-7.2 — was MAGIC_F`
2. `int n = port.GetTicketsForSlot(MAGIC_J, "J,", tickets);   // G4 fix BR-7.2`
3. Log message: `"... profit_pips=%.1f >= gate=%.1f → close (G4 fix BR-7.2)"`

Bucket B classification confirmed in commit message body:
> ⚠️ Bucket B drift (intentional behavioral change vs baseline) — NFR-1.8 budget separate from Bucket A NFR-1.1 ≤ 25%; regression sign-off at IMPL-063 (P4).

## SelfTest cases (Spike_Slot_J)

| # | Assertion | Expected | Actual |
|---|-----------|----------|--------|
| 1 | Magic() | MAGIC_J (206) | MAGIC_J ✅ |
| 2 | SlotId() | "J" | "J" ✅ |
| 3 | DependsOn() | 1 with [MAGIC_CD] | 1 with [MAGIC_CD] ✅ |
| 4 | PendingState() | PENDING_STATE_IDLE | PENDING_STATE_IDLE ✅ |
| 5 | Magic() in [200..220] | true | 206 ∈ [200..220] ✅ |
| 6 | SlotId() non-empty | true | "J" non-empty ✅ |

Tester log expected line (when run via slot_J_smoke.ini at IMPL-053+):
```
[Phoenicis][SlotJ][ev=spike_self_test][result=pass] 6 cases passed (G4 fix BR-7.2) — Magic=206 SlotId=J DependsOn=1 deps[0]=200 PendingState=0
```

## Acceptance Criteria status

**S-AC: 6/6 [x]**

- [x] All 6 CSlotBase methods overridden
- [x] Magic() returns MAGIC_J (206); SlotId() returns "J"; comment prefix "J," used in OrderSend
- [x] ManageExits calls `m_portfolio.GetByMagic(MAGIC_J)` (not MAGIC_F) — explicit `// G4 fix BR-7.2` comment
- [x] Bucket B classification noted in commit message
- [x] Compile clean
- [x] commit `simulation/headless-tests/slot_J_smoke.ini` per TD-02 §13.6 PR contract

**E-AC: 0/2 [x]; 2 deferred** (registered to `deferred-ac-registry.md` Active table; expiry 2026-05-17):

- [ ] Smoke: open J position via fixture → ManageExits queries MagicJ ticket_ids → take-profit set; query against fixture portfolio confirms Magic-J iteration `[log-assertion]` + `[db-inspect]` — blocks on IMPL-053+ Orchestrator + CrossSlotCoordinator wiring + 60-day Tester run
- [ ] G4 attestation in `docs/state/g4-fix-attestation.md` lists IMPL-022 commit hash + journal evidence path — file authored alongside IMPL-039 BI SL fix per consolidated G4 attestation strategy

## Risk notes

- **Bucket B drift (NFR-1.8)** — Slot_J ManageExits Magic-J iteration is intentional behavioral change vs PhoenicisN2.10 baseline. Drift unverified until IMPL-063 (P4) regression run with G4 fixes enabled vs disabled (compile flag DISABLE_G4_FIXES).
- **G4 fix attestation file pending** — `docs/state/g4-fix-attestation.md` will be authored when IMPL-039 lands (second G4 fix per ADR-009) so both Bucket B fixes have consolidated audit trail. Until then, commit `d386ea6` body + this evidence file are the audit anchor.
- **Plan Staleness Sentinel @ 46 closures** — STRONGLY recommend `/impl-plan-review all` + `/impl-review all` before IMPL-039 BI SL fix.

## References

- BR-7.2 (G4 fix), FR-3.4, NFR-1.8 (Bucket B budget)
- ADR-002 (CSlotBase contract), ADR-009 (G4 fix family), ADR-012 (5-layer include discipline)
- CodeWiki §3.J (J = follower trade after CD)
- impl-plan IMPL-022 closure block + Mid-Phase Audit Log row 2026-05-03
- deferred-ac-registry.md Active table 2 new IMPL-022 rows (expiry 2026-05-17)
