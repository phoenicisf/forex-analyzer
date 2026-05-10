# Comment History Exemptions Manifest

> Single source of truth for source-comment sites that reference closed task IDs (`IMPL-NNN`) for **historical / banner-attribution purposes** rather than as forward-pointers to outstanding wiring work.
>
> Created 2026-05-05 per fix-round-20 §20.3 (review-round-20 Finding 20.3 MEDIUM — Gate #9c "audit history" exemption ambiguity).
> Populated 2026-05-10 per IMPL-FIX-004 closure (deferred-ac-registry P5 row).

## Purpose

Gate #9d sweeps (`.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)`) flag every `IMPL-NNN` reference in source files. Many of these are NOT forward-pointers — they are historical banner annotations describing what task originally added the file or sub-pass (e.g., `// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1)`). Without a disambiguating mechanism, every Gate #9d sweep re-evaluates these manually.

This manifest **subtracts these sites from the sweep**. The Gate #9d post-condition becomes:

```bash
grep -rnE "IMPL-(006|007|018|042|043|053)\b" MQL5/Experts/PhoenicisNex/ simulation/headless-tests/ \
  | awk -F: '{print $1":"$2}' \
  | sort -u \
  | comm -23 - <(grep -E "^(MQL5|simulation)" docs/state/comment-history-exemptions.md \
                  | awk -F: '{print $1":"$2}' \
                  | sort -u)
# → 0 hits expected (all sweep sites are banner-history exempt)
```

## Discipline

- Adding a row REQUIRES an attestation by the engineer in the fix-round / closure narrative that introduced (or re-confirmed) the row.
- Rows MUST be `<file>:<line>:<task-id>:<justification>` format (machine-parseable, colon-delimited 4 fields). Embedded inside a fenced ``` ` ``text``` ` `` block to prevent prose lines from poisoning the awk extraction.
- A row's justification MUST explain WHY this is historical (file/sub-pass attribution) and NOT a forward-pointer to outstanding work.
- If a future code change converts a historical site INTO a forward-pointer (e.g., a banner that named the task is now describing pending wiring), DELETE the row + reroute the comment per bin-1/2/3 routing in review-round-19 §19.1.
- **Line-number drift:** when the cited file is edited, line numbers shift. Re-run the population script (Gate #9d sweep regex, see Population History below) to refresh; mismatched rows surface as unmatched-key warnings.

## Exemptions (cumulative; 111 rows as of 2026-05-10)

> **Format:** `<repo-relative-path>:<line>:<task-id>:<justification>` — one row per site, colon-delimited.
>
> **Population script (Gate #9 clause (h) verb-form sweep returns 0 hits at population time):**
>
> ```bash
> grep -rnE "IMPL-(006|007|018|042|043|053)\b" MQL5/Experts/PhoenicisNex/ simulation/headless-tests/ \
>   | awk -F: 'BEGIN{OFS=":"} {file=$1; line=$2; rest=""; for(i=3;i<=NF;i++) rest=rest (i>3?":":"") $i;
>              match(rest, /IMPL-(006|007|018|042|043|053)/); task=substr(rest,RSTART,RLENGTH);
>              print file, line, task, "historical banner"}' \
>   | LC_ALL=C sort -u
> ```
>
> Tag suffixes (sub-pass / SelfTest / owner / wiring-landed / etc.) refine the base "historical banner" tag for human readers; they do NOT affect Gate #9d's awk extraction (which uses fields 1+2 only).

```text
MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:24:IMPL-042:historical banner
MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:42:IMPL-007:historical banner
MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:541:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/core/BootstrapValidator.mqh:545:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh:22:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/core/Orchestrator.mqh:42:IMPL-018:historical banner
MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh:298:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh:65:IMPL-018:historical banner - sub-pass / S-AC attribution
MQL5/Experts/PhoenicisNex/core/SlotRegistry.mqh:7:IMPL-018:historical banner
MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh:191:IMPL-042:historical banner
MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh:248:IMPL-042:historical banner - owner attribution
MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh:261:IMPL-042:historical banner - owner attribution
MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh:40:IMPL-042:historical banner
MQL5/Experts/PhoenicisNex/helpers/Timestamp.mqh:30:IMPL-042:historical banner - owner attribution
MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_BR.mqh:12:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/inputs/Inputs_Slot_G.mqh:16:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh:15:IMPL-053:historical banner - wiring landed marker
MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh:194:IMPL-053:historical banner - wiring landed marker
MQL5/Experts/PhoenicisNex/services/CircuitBreaker.mqh:91:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:464:IMPL-007:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:53:IMPL-053:historical banner - sub-pass / S-AC attribution
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:537:IMPL-007:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:679:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:691:IMPL-018:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/services/CrossSlotCoordinator.mqh:8:IMPL-053:historical banner - sub-pass / S-AC attribution
MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh:319:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh:348:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh:364:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/IndicatorService.mqh:68:IMPL-006:historical banner - wiring landed marker
MQL5/Experts/PhoenicisNex/services/Logger.mqh:148:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/services/Logger.mqh:149:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/services/Logger.mqh:22:IMPL-042:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:383:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:509:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:517:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:529:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:550:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:555:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:562:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:567:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:575:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/MarketContextBuilder.mqh:579:IMPL-006:historical banner
MQL5/Experts/PhoenicisNex/services/PortfolioMonitor.mqh:68:IMPL-018:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:13:IMPL-018:historical banner
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:29:IMPL-007:historical banner
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:312:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:313:IMPL-018:historical banner - wiring landed marker
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:371:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:379:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:422:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/services/PortfolioState.mqh:427:IMPL-007:historical banner - pre-IMPL-007 TODO (landed; PipMath wires here)
MQL5/Experts/PhoenicisNex/services/StatePersistence.mqh:179:IMPL-043:historical banner
MQL5/Experts/PhoenicisNex/services/StatePersistence.mqh:183:IMPL-042:historical banner - wiring landed marker
MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:143:IMPL-018:historical banner
MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:423:IMPL-018:historical banner
MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh:426:IMPL-043:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:27:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_B.mqh:271:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:112:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:114:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:117:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_BR.mqh:17:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/slots/Slot_F.mqh:118:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:21:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:22:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:326:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:327:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:328:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:386:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:387:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:388:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:390:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G.mqh:49:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:19:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:20:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:319:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:320:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_G2.mqh:322:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:101:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:103:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:105:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:15:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:189:IMPL-053:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:190:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:192:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_GO.mqh:20:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_I.mqh:19:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/slots/Slot_J.mqh:120:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5:11:IMPL-053:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_CrossSlotCoordinator.mq5:4:IMPL-053:historical banner
MQL5/Experts/PhoenicisNex/spike/Spike_CSlotBase.mq5:4:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_B.mq5:16:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BI.mq5:20:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_BR.mq5:16:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_G.mq5:15:IMPL-018:historical banner - header-only / stub marker (now wired)
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_H.mq5:14:IMPL-018:historical banner - spike harness marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_K.mq5:15:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_Slot_L.mq5:16:IMPL-018:historical banner - SelfTest scope marker
MQL5/Experts/PhoenicisNex/spike/Spike_TradeJournal.mq5:2:IMPL-043:historical banner - spike harness marker
simulation/headless-tests/cross_slot_extra_check.ini:5:IMPL-053:historical banner
simulation/headless-tests/cross_slot_force_cutloss.ini:5:IMPL-053:historical banner
simulation/headless-tests/cross_slot_order_group_2.ini:5:IMPL-053:historical banner
simulation/headless-tests/cross_slot_overload_helpers.ini:5:IMPL-053:historical banner
simulation/headless-tests/cross_slot_safe_port.ini:1:IMPL-053:historical banner
simulation/headless-tests/cross_slot_safe_port.ini:15:IMPL-053:historical banner
simulation/headless-tests/impl043_tradejournal_smoke.ini:1:IMPL-043:historical banner
simulation/headless-tests/slot_G2_smoke.ini:10:IMPL-018:historical banner
simulation/headless-tests/slot_GO_smoke.ini:11:IMPL-018:historical banner
simulation/headless-tests/slot_H_smoke.ini:4:IMPL-018:historical banner - spike harness marker
simulation/headless-tests/slot_I_smoke.ini:10:IMPL-018:historical banner
simulation/headless-tests/slot_LX_smoke.ini:10:IMPL-018:historical banner
```

## Cross-references

- `.claude/rules/workflow.md § Phase 5 Gate #9 clause (c)` — Gate #9c "audit history" exemption (origin)
- `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` — Gate #9d sweep regex
- `docs/code-review/review-round-20.md § 20.3` — defect motivating the manifest
- `docs/code-review/fix-round-19.md § 19.2` — Partial-Accept narrative that conflated banner-history with forward-pointer
- `docs/state/deferred-ac-registry.md § Active row P5 IMPL-FIX-004` — manifest-populate tracking row (Resolved on 2026-05-10 closure)

## Population History

| Date | Rows | Source | Notes |
|------|------|--------|-------|
| 2026-05-05 | 0 (placeholder) | fix-round-20 §20.3 + fix-round-21 §21.3 | Manifest framework + discipline rules + Gate #9d hook landed; population deferred via IMPL-FIX-004 |
| 2026-05-10 | 111 | IMPL-FIX-004 closure | First-pass enumeration via `grep -rnE "IMPL-(006|007|018|042|043|053)\b" MQL5/ simulation/headless-tests/`. Verb-form forward-pointer sweep returned 0 hits at this time → all 111 surviving sites are banner-history exempt. |

## End of Manifest
