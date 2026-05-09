# Comment History Exemptions Manifest

> Single source of truth for source-comment sites that reference closed task IDs (`IMPL-NNN`) for **historical / banner-attribution purposes** rather than as forward-pointers to outstanding wiring work.
>
> Created 2026-05-05 per fix-round-20 §20.3 (review-round-20 Finding 20.3 MEDIUM — Gate #9c "audit history" exemption ambiguity).

## Purpose

Gate #9d sweeps (`.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)`) flag every `IMPL-NNN` reference in source files. Many of these are NOT forward-pointers — they are historical banner annotations describing what task originally added the file or sub-pass (e.g., `// IMPL-053 sub-pass: skeleton + RunSafePort full body (BR-8.1)`). Without a disambiguating mechanism, every Gate #9d sweep re-evaluates these manually.

This manifest **subtracts these sites from the sweep**. The Gate #9d post-condition becomes:

```bash
grep -rE "<dynamic-closed-task-pattern>" MQL5/ simulation/ \
  | grep -vFf <(awk -F: '{print $1":"$2}' docs/state/comment-history-exemptions.md)
# → 0 hits
```

## Discipline

- Adding a row REQUIRES an attestation by the engineer in the fix-round narrative that introduced (or re-confirmed) the row.
- Rows MUST be `<file>:<line>:<one-line-justification>` format (machine-parseable).
- A row's justification MUST explain WHY this is historical (file/sub-pass attribution) and NOT a forward-pointer to outstanding work.
- If a future code change converts a historical site INTO a forward-pointer (e.g., a banner that named the task is now describing pending wiring), DELETE the row + reroute the comment per bin-1/2/3 routing in review-round-19 §19.1.

## Exemptions (cumulative; line numbers may drift — `make verify` recomputes)

> **Format:** `<repo-relative-path>:<line>:<task-id>:<justification>` — one row per site.
>
> **First-pass population (2026-05-05):** the ~86 banner-style sites cited in fix-round-19 §19.2 Partial-Accept — historical sub-pass attribution comments. **Tracked under IMPL-FIX-004** (per fix-round-21 §21.3 / review-round-21 Finding 21.3 MEDIUM Option B) — `docs/state/deferred-ac-registry.md` Active row, owner Kritsana, opened 2026-05-05, expires 2026-05-19. Until populated, Gate #9d falls back to the manual narrative-justification path used in fix-round-19 §19.2 (this fallback path is now an explicitly-tracked deferral, not a silent placeholder).

| File | Line | Task ref | Justification |
|------|------|----------|---------------|
| _(populate work tracked under IMPL-FIX-004; deferred-ac-registry row Active until 2026-05-19)_ | | | |

## Cross-references

- `.claude/rules/workflow.md § Phase 5 Gate #9 clause (c)` — Gate #9c "audit history" exemption (origin)
- `.claude/rules/workflow.md § Phase 5 Gate #9 clause (d)` — Gate #9d sweep regex
- `docs/code-review/review-round-20.md § 20.3` — defect motivating the manifest
- `docs/code-review/fix-round-19.md § 19.2` — Partial-Accept narrative that conflated banner-history with forward-pointer

## End of Manifest
