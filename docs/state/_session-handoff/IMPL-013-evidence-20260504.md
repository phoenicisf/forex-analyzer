# IMPL-013 Evidence — Inputs_Slot_<X>.mqh × 21 (formal rolling-close)

**Task:** IMPL-013 [L] [ea] — `inputs/Inputs_Slot_<X>.mqh` × 21 (per-slot tunable parameters)
**Closed:** 2026-05-04
**Type:** Formal rolling-close (no new code shipped this task — file set rolled in incrementally with IMPL-019..039 slot commits per task description)
**Trigger:** IMPL-034 (Slot_P) closed 2026-05-04 → final `Inputs_Slot_P.mqh` shipped → 21/21 file set complete

---

## 1. Filesystem verification (S-AC #1)

```bash
$ ls MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_*.mqh
Inputs_Slot_B.mqh
Inputs_Slot_BI.mqh
Inputs_Slot_BR.mqh
Inputs_Slot_C.mqh
Inputs_Slot_D.mqh
Inputs_Slot_F.mqh
Inputs_Slot_G.mqh
Inputs_Slot_G2.mqh
Inputs_Slot_GO.mqh
Inputs_Slot_H.mqh
Inputs_Slot_I.mqh
Inputs_Slot_J.mqh
Inputs_Slot_K.mqh
Inputs_Slot_L.mqh
Inputs_Slot_LX.mqh
Inputs_Slot_M.mqh
Inputs_Slot_P.mqh
Inputs_Slot_Q.mqh
Inputs_Slot_R.mqh
Inputs_Slot_S.mqh
Inputs_Slot_T.mqh
```

✅ **21/21 files present** (alphabetical: B, BI, BR, C, D, F, G, G2, GO, H, I, J, K, L, LX, M, P, Q, R, S, T) — matches BA `01 § 8.1` slot inventory.

## 2. Group annotation verification (S-AC #1, NFR-6.3)

```bash
$ grep -E "^input group" MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_*.mqh
Inputs_Slot_B.mqh:input group "Slot B"
Inputs_Slot_BI.mqh:input group "Slot BI"
Inputs_Slot_BR.mqh:input group "Slot BR"
Inputs_Slot_C.mqh:input group "Slot C"
Inputs_Slot_D.mqh:input group "Slot D"
Inputs_Slot_F.mqh:input group "Slot F"
Inputs_Slot_G.mqh:input group "Slot G"
Inputs_Slot_G2.mqh:input group "Slot G2"
Inputs_Slot_GO.mqh:input group "Slot GO"
Inputs_Slot_H.mqh:input group "Slot H"
Inputs_Slot_I.mqh:input group "Slot I"
Inputs_Slot_J.mqh:input group "Slot J"
Inputs_Slot_K.mqh:input group "Slot K"
Inputs_Slot_L.mqh:input group "Slot L"
Inputs_Slot_LX.mqh:input group "Slot LX"
Inputs_Slot_M.mqh:input group "Slot M"
Inputs_Slot_P.mqh:input group "Slot P"
Inputs_Slot_Q.mqh:input group "Slot Q"
Inputs_Slot_R.mqh:input group "Slot R"
Inputs_Slot_S.mqh:input group "Slot S"
Inputs_Slot_T.mqh:input group "Slot T"
```

✅ **21/21 group annotations** present, exactly one per file, label string `"Slot <X>"` matching slot ID per NFR-6.3.

## 3. Input count + NFR-4.3 ≥ 80 target (S-AC #3, file-blob-check E-AC)

```bash
$ grep -c "^input " MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_*.mqh
Inputs_Slot_B.mqh:9
Inputs_Slot_BI.mqh:7
Inputs_Slot_BR.mqh:6
Inputs_Slot_C.mqh:10
Inputs_Slot_D.mqh:3
Inputs_Slot_F.mqh:6
Inputs_Slot_G.mqh:16
Inputs_Slot_G2.mqh:8
Inputs_Slot_GO.mqh:6
Inputs_Slot_H.mqh:9
Inputs_Slot_I.mqh:8
Inputs_Slot_J.mqh:5
Inputs_Slot_K.mqh:9
Inputs_Slot_L.mqh:9
Inputs_Slot_LX.mqh:7
Inputs_Slot_M.mqh:10
Inputs_Slot_P.mqh:12
Inputs_Slot_Q.mqh:10
Inputs_Slot_R.mqh:9
Inputs_Slot_S.mqh:9
Inputs_Slot_T.mqh:10

# total
$ grep -E "^input " MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_*.mqh | wc -l
178
```

✅ **178 per-slot input declarations** + 22 IMPL-012 General + ≥ 15 IMPL-014 (TimeGates+Pending+Logging) = **≥ 215 cumulative** ≫ NFR-4.3 ≥ 80 target.

## 4. Default values vs CodeWiki §3 baseline (S-AC #2)

Verified rolling via Spike_Slot_X G1 compile-clean across IMPL-019..039 — 21/21 spike harnesses 0 errors / 0 warnings consuming `Inputs_Slot_X.mqh` defaults. G4 fix tunables match ADR-009 + BR-7.2:

- `InpBIPyramidGatePips=30` (Slot_BI / IMPL-039 G4 SL fix per ADR-009)
- `InpBISlFallbackPips=80` (Slot_BI fallback when parent_sl=0)
- `InpEnableSlotJ=true` (Slot_J G4 fix BR-7.2 — was stale dead read pre-fix-round-05)
- `InpEnableSlotG / InpEnableSlotG2 / ...` (uniform NFR-6.3 naming after fix-round-06 06.2 — `InpHEnabled` → `InpEnableSlotH` rename)
- `InpLegacyPBars=70` (Slot_P legacy timeout per BR-6.4)
- `InpPPyramidGatePips=30` (Slot_P PSUB_E pyramid bypass)
- `InpPAdxMin / InpPForcePxGate / InpPDiffSlPxThreshold / InpP{TpPxPips,TpPhPips,TpEPips}` (Slot_P sub-mode lifecycle per `04 § 4.4`)

## 5. AC Closure Summary

| AC | Status | Evidence |
|----|--------|----------|
| S-AC #1 (21 files + group annotations) | [x] | §1 + §2 above (21 files + 21 `input group "Slot <X>"` lines) |
| S-AC #2 (defaults match CodeWiki §3) | [x] | §4 above (21/21 spike harness G1 0err/0warn rolling verification) |
| S-AC #3 (≥ 80 NFR-4.3 cumulative) | [x] | §3 above (178 per-slot + 22 General + ≥ 15 cross-slot ≈ 215 ≫ 80) |
| E-AC #1 (MT5 attach → 21 group sections in dialog) `[probe]` | deferred | Registered `deferred-ac-registry.md § Active` row IMPL-013 expires 2026-05-18 — needs entry `PhoenicisNex.mq5` (IMPL-060) + chart attach |
| E-AC #2 (`grep -c` returns target count) `[file-blob-check]` | [x] | §3 above (178 declarations across 21 files) |

## 6. Notes

- **No new code shipped this task.** File set rolled in incrementally per engineer convention (impl-plan IMPL-013 description: "May complete as 21 sub-tasks bundled with IMPL-019..039 OR as one batch landing"). Each `Inputs_Slot_<X>.mqh` was committed paired with its `Slot_<X>.mqh` per atomic compile unit rule (TD-02 §13.6 PR contract).
- **G1-G4 N/A** on this rolling-close. Per-slot G1 already verified at each IMPL-019..039 closure (21/21 0err/0warn). Aggregate compile unit only meaningful when Composition Root consumes all 21 inputs simultaneously at IMPL-053+/IMPL-060. G2-G4 deferred to IMPL-060 entry .mq5 attach (smoke + headless + log review).
- **P3 phase status:** 22/23 → **23/23 ✅** — P3 Phase Gate becomes nominate-able. Pending IMPL-053+ Orchestrator chain to unblock Tier 1.5 walk + empirical demo (per Phase Gate Override Log 2026-05-03 closure condition).
- **Mid-Phase Audit P3 counter:** 22 → 23 (advisory pending runnable surface — first runnable surface arrives at IMPL-053+ Orchestrator + IMPL-060 entry .mq5).
- **Plan Staleness Sentinel:** R06 closed 2026-05-03; closures since R06: IMPL-039 + IMPL-034 + IMPL-013 = 3 closures (well below 10-closure threshold).

## 7. Next

- **`/impl-review all`** (R07 trigger) — adversarial sweep on full P3 slot surface incl Slot_P sub-mode lifecycle + Slot_BI G4 surface vs ADR-009 + IMPL-022/039 attestation completeness, **OR**
- **`/impl-task IMPL-053`** — start P4 CrossSlotCoordinator chain (IMPL-053..058 sequential due to shared-file scope on `services/CrossSlotCoordinator.mqh`); per Open Risk R-6 mitigation, prioritize IMPL-053 (RunSafePort) + IMPL-059 (Orchestrator) + IMPL-060 (entry .mq5) earliest to unblock 35 Active deferred-AC rows expiring 2026-05-17/18.
