# Deferred-AC Registry

> Single source of truth for E-ACs (Empirical Acceptance Criteria) ที่ exercise ตอน task closure ไม่ได้ — vendor account ยังไม่มา / hardware ไม่ถึง / upstream dep blocked
> ห้าม mark task `[x]` ใน `impl-plan.md` ด้วย closure note "deferred" — เปิด entry ที่นี่แทน
> Read by `/impl-task` (HALTs on expired entries), `/impl-review` (cross-checks closure-rule violations), `/deliver` (blocks shipping if non-empty)

> **PhoenicisNex Phase 1 baseline note (2026-05-02):** local-only sandbox; no vendor account / hardware wait / external dependency expected. Registry is initialized empty + remains empty unless Phase 2 cloud journal / Telegram / multi-account triggers added (per BA `01 § 6.2 Won't Permanent` + ADR Revisit-when entries).

---

## Active

| Phase | Task | E-AC text | Evidence-kind | Deferred reason | Owner | Opened | Expires | Risk if missed |
|-------|------|-----------|---------------|-----------------|-------|--------|---------|----------------|
| P2 | IMPL-043 | Stub `FileWriteString` to fail 10 times → Logger Error `[ev=journal_halt][reason=write_fail_sustained]` + EAState transitions HALTED `[log-assertion]` | log-assertion | Self-halt path now wired (`CTradeJournal::SetHaltSink(IHaltSink*)` + threshold check in `HandleWriteFailure` per fix-round-03 Finding 03.6); end-to-end log assertion still requires IMPL-018+ Orchestrator to compose `CEAState` ↔ `CTradeJournal` and run a Tester scenario forcing 10 write failures | Kritsana | 2026-05-03 | 2026-05-17 | Journal sustained-write-failure halt never fires; EA continues writing to broken journal silently exceeding RPO |
| P2 | IMPL-043 | TradeJournal `BuildIndicatorSnapshotSubset` emits a non-empty subset of `MarketContext` per ADR-004 (≥5 of: ichi cloud high/low, force_h4_0, adx_h4, rsi_h4) `[contract-roundtrip]` | contract-roundtrip | `CMarketContextBuilder::Build()` returns `MarketContext` by value per tick (ADR-004) and exposes no `Current()` accessor; wiring requires IMPL-018+ Orchestrator to cache the per-tick snapshot and inject it into TradeJournal at write time. Stub `BuildIndicatorSnapshotSubset` returns `"{}"` (schema-valid empty object) until wired — see Finding 03.5 | Kritsana | 2026-05-03 | 2026-05-17 | Forensic context (FR-3.4 retrospective audit) absent on every journal record; QA Phase 3T cannot reconstruct slot signal context vs baseline |
| P2 | IMPL-052 | Cold restart with `state.json` containing `state=HALTED` + `portfolio_count=0` → EA boots → in-RAM state resolves to RUNNING + reset reason `[boot-cold]` | boot-cold | Live `terminal64.exe` headless tester invocation could not attach in current environment; closure used header-only `SelfTest` with `RestoreFromState(EA_STATE_HALTED, "old_reason", 0)` exercising the same code path. Real cold-bootstrap exercise requires IMPL-018+ Orchestrator entry + AtomicFile load chain — see Finding 03.9 | Kritsana | 2026-05-03 | 2026-05-17 | HALTED-reset path silently broken at first real boot; operator restart after halt could leave EA in unintended state |
| P2 | IMPL-049 | M-Pending (or any of 8 machines) persisted as PENDING with payload + force_clear_count survives restart and routes correctly through TickAll on next bar `[boot-cold]` | boot-cold | Same precedent as IMPL-052: `SelfTest` Case 6/7 exercises the `CStatePersistence` accessor round-trip + the post-fix-03.4 cold-restart `started_bar` recovery path; live boot-cold demo blocked on IMPL-018+ Orchestrator wiring | Kritsana | 2026-05-03 | 2026-05-17 | PendingMachineRegistry recovery + force-clear timing untested under real boot; could mis-trigger on production restart |
| P2 | IMPL-049 | Force-clear journal record actually written to `journal/tester/run-*.jsonl` with schema-valid event_type/slot_id/magic/symbol/triggering_function `[file-blob-check]` | file-blob-check | `EmitForceClear` now populates schema-required fields verbatim (Findings 03.1/03.2/03.3 fix-round-03); end-to-end disk write verification requires IMPL-018+ Orchestrator `CTradeJournal.Init()` + Tester run | Kritsana | 2026-05-03 | 2026-05-17 | Journal record drift undetected until QA Phase 3T; could break IMPL-068 force-clear validation |
| P3 | IMPL-026 | Smoke 60-day backtest with G + G2 active → CommentParser correctly disambig "G2," from "G," for ≥ 1 G2 entry `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend wiring + Tester run with InpEnableSlotG=true + InpEnableSlotG2=true required to exercise CommentParser disambiguation against same-magic-208 trade flow | Kritsana | 2026-05-03 | 2026-05-17 | G/G2 wave-helper coupling untested; could mis-attribute G2 entries as G in journal records or fail `_HasActiveGOrder` filter |
| P3 | IMPL-029 | Smoke 60-day backtest with only Slot M active → M-Pending payload preserved across kill+reload `[contract-roundtrip]`; force-clear triggered after `InpForceClearM_Bars` threshold `[log-assertion]` + `[db-inspect]` | contract-roundtrip | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + StatePersistence kill+reload cycle + 150-H4-bar timeline (~25 trading days) needed to exercise M-Pending payload round-trip and force-clear emission. PMR.SelfTest already covers payload round-trip + force-clear logic structurally; live cycle awaits Orchestrator | Kritsana | 2026-05-03 | 2026-05-17 | M-Pending production behavior untested under real boot; could fail to resume PENDING state after operator restart or mis-trigger force-clear at wrong bar count |
| P3 | IMPL-030 | Smoke 60-day backtest with only Slot L active → ≥ 1 entry+exit cycle journaled `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend + 60-day Tester run with InpEnableSlotL=true required to observe entry+exit cycle journal records | Kritsana | 2026-05-03 | 2026-05-17 | Slot L production entry+exit logic untested; downstream IMPL-031 LX pyramid + IMPL-036 S post-close depend on L behavior — drift here cascades |
| P3 | IMPL-027 | Smoke: G post-exit fires GO hook → ≥ 1 GO entry journaled `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — GO is sub-call only invoked by G's BR-8.4 `TriggerGOverload` (currently stubbed `false /*IMPL-053*/` in Slot_G.mqh:392); activation requires CrossSlotCoordinator IMPL-053 P4 + entry .mq5 + Tester run | Kritsana | 2026-05-03 | 2026-05-17 | GO post-exit hook untested under real flow; could fail to fire on G overload peak detection or mis-direct (BUY parent → SELL GO inversion per BR-8.4) |
| P3 | IMPL-028 | Smoke 60-day backtest with G + I active → ≥ 1 I entry only when G has open position `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend + 60-day Tester run with InpEnableSlotG=true + InpEnableSlotI=true required to observe parasite gate exercising against real G open positions | Kritsana | 2026-05-03 | 2026-05-17 | I parasite-gate untested under real G position flow; could mis-trigger entries when G has zero positions or fail to inherit direction correctly |
| P3 | IMPL-031 | Smoke 60-day backtest with L + LX active → CommentParser correctly disambig "LX," from "L," for ≥ 1 LX pyramid entry `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend + 60-day Tester run with InpEnableSlotL=true + InpEnableSlotLX=true required to observe pyramid gate against profitable parent L + CommentParser shared-magic disambig | Kritsana | 2026-05-03 | 2026-05-17 | LX pyramid + shared-magic disambig untested; could mis-attribute LX entries as L parent in journal records or fail pyramid profit-gate on real flow |
| P3 | IMPL-032 | Smoke 60-day backtest with only Slot Q active → Q-Pending payload preserved across kill+reload `[contract-roundtrip]`; force-clear triggered after `InpForceClearQ_Bars` (100) threshold `[log-assertion]` + `[db-inspect]` | contract-roundtrip | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + StatePersistence kill+reload cycle + 100-H4-bar timeline (~17 trading days) needed to exercise PM_Q payload round-trip + force-clear emission. PMR.SelfTest already covers payload round-trip + force-clear logic structurally; live cycle awaits Orchestrator | Kritsana | 2026-05-03 | 2026-05-17 | Q-Pending production behavior untested under real boot; could fail to resume PENDING state after operator restart or mis-trigger force-clear at wrong bar count |
| P3 | IMPL-033 | Smoke 60-day backtest with only Slot R active → ≥ 1 entry+exit cycle journaled; R-Pending legacy timeout fires per `InpLegacyRBars` (40) `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend + 60-day Tester run with InpEnableSlotR=true required to observe legacy-timeout PM_R lifecycle (PMR-internal vs slot-API parity also exercised) | Kritsana | 2026-05-03 | 2026-05-17 | R-Pending legacy-timeout production behavior untested; could fail to fire timeout or mis-route through ADR-008 force-clear path (slot uses identical EnterPending/TransitionExecuted API; PMR distinguishes internally) |
| P3 | IMPL-035 | Smoke 60-day backtest with only Slot T active → T-Pending payload preserved across kill+reload `[contract-roundtrip]`; force-clear triggered after `InpForceClearT_Bars` (80) threshold `[log-assertion]` + `[db-inspect]` | contract-roundtrip | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + StatePersistence kill+reload cycle + 80-H4-bar timeline (~13 trading days) needed to exercise PM_T payload round-trip + force-clear emission. PMR.SelfTest already covers payload round-trip + force-clear logic structurally; live cycle awaits Orchestrator | Kritsana | 2026-05-03 | 2026-05-17 | T-Pending production behavior untested under real boot; could fail to resume PENDING state after operator restart or mis-trigger force-clear at wrong bar count |
| P3 | IMPL-019 | Smoke 60-day backtest with only Slot C active → ≥ 1 entry+exit cycle journaled `[log-assertion]` + `[db-inspect]`; C-Pending payload preserved across kill+reload `[contract-roundtrip]`; force-clear triggered after `InpForceClearC_Bars` (100) threshold | contract-roundtrip | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + StatePersistence kill+reload cycle + 100-H4-bar timeline (~17 trading days) needed to exercise PM_C payload round-trip + force-clear emission. PMR.SelfTest already covers payload round-trip + force-clear logic structurally; live cycle awaits Orchestrator (IMPL-053+) | Kritsana | 2026-05-03 | 2026-05-17 | C-Pending production behavior untested under real boot; CD chain root drift cascades to Slot D + Slot F + Slot J downstream |
| P3 | IMPL-036 | Smoke 60-day backtest with L + K + S active → ≥ 1 S entry triggered after L or K post-close `[log-assertion]` + `[db-inspect]` | log-assertion | Header-only `.mqh` per IMPL-018+ precedent — entry .mq5 + Composition Root + RiskManager OrderSend + 60-day Tester run with InpEnableSlotL=true + InpEnableSlotK=true + InpEnableSlotS=true required to observe both-parents-inactive gate firing against real L/K close events | Kritsana | 2026-05-03 | 2026-05-17 | S post-close gate untested under real flow; could mis-fire when L or K still active or fail to detect post-close transition |

---

## Resolved

| Phase | Task | E-AC text | Resolved on | Evidence artifact path |
|-------|------|-----------|-------------|------------------------|
| _empty_ | | | | |

---

## Rules

1. **Every defer requires an entry here** — engineer cannot mark task `[x]` without entry; reviewer raises Dimension #11 CRITICAL otherwise
2. **Expiry ≤ 14 days from `Opened`** (absolute date, not relative). Phase boundaries ไม่ extend expiry
3. **On expiry**: `/impl-task` next invocation HALTs and surfaces the expired entry. Options:
   - (a) resolve now (run the empirical step + move row to Resolved)
   - (b) renew once with rationale (max 2 renewals per row total)
   - (c) escalate via `/backtrack`
4. **Phase Gate drain**: phase ปิดไม่ได้ while any registry row's `Phase` matches the closing phase
5. **`/deliver` block**: `/deliver` ห้าม ship project ขณะที่ Active table มี row ใดอยู่

---

## PhoenicisNex-specific anti-pattern catalog (avoid)

> ห้ามใช้ closure pattern เหล่านี้ใน `impl-plan.md`:
>
> - ❌ `[x]` + `<!-- deferred to operator-runtime -->`
> - ❌ `[x]` + `<!-- live verification deferred per IMPL-XXX precedent -->`
> - ❌ `[x]` + `<!-- structural test pass; empirical N/A -->` ถ้า task touches network / persistence / user-visible / async / security
>
> ถ้าจริงๆ ต้อง defer (เช่น Phase 2 cloud journal vendor account ยังไม่ provision) → **เปิด row ที่นี่** + split task เป็น S-AC subtask (ปิดได้ตอนนี้) + E-AC subtask (track ที่นี่)

---

## Schema reference

```yaml
phase: P1 | P2 | P3 | P4
task: IMPL-NNN
e_ac_text: "verbatim AC text from impl-plan.md"
evidence_kind: probe | gui-capture | log-assertion | queue-inspect | db-inspect | file-blob-check | boot-cold | contract-roundtrip | config-audit
deferred_reason: "single-sentence why exercise-now is impossible"
owner: human-or-agent-name
opened: YYYY-MM-DD
expires: YYYY-MM-DD  # ≤ 14 days from opened
risk_if_missed: "what breaks if this E-AC never runs (≤25 words)"
```
