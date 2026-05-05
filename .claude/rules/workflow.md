# PhoenicisNex Workflow Rules

> Stack-agnostic methodology baseline (git/PR/handoff/ADR/Phase Gate) + PhoenicisNex cold-bootstrap recipe.

## Git + PR Workflow
- Branch convention: `feat/<task-id>-<slug>` / `fix/<task-id>-<slug>` / `refactor/<scope>` / `chore/<scope>`
- Commit format: `[type:<service-slug>] short description` + `Why:` line — see CLAUDE.md §5
- Types: feat, fix, refactor, test, docs, chore
- **ห้าม** force push ไป main/develop
- **ห้าม** skip pre-commit hooks (`--no-verify`) unless explicitly authorized
- Every PR MUST include the `simulation/headless-tests/<task>.ini` if task is slot/orchestrator/cross-slot (TD-02 §13.6)
- Compile artifacts (`.ex5`, `.compile.log`) NOT committed (UTF-16LE binary noise)

## Handoff Discipline
- Single project (no monorepo): use `docs/state/current_handoff.md` (created on first task)
- Update handoff: end of feature / session change / cross-day boundary — NOT every micro-step
- Evidence artifacts: `docs/state/_session-handoff/<task-id>-evidence-*.{log,json,jsonl,md}`
- 3-file propagation rule: `impl-plan.md` → `overview.md` → `current_handoff.md` (CLAUDE.md §6 State Reconciliation)

## ADR Discipline
- 12 ADRs locked (001-012) — design QA certified 2026-05-02
- New architectural decision → `docs/adr/NNN-<kebab-title>.md` (NNN = next sequential)
- ADR amendment (e.g., adding "Revisit-when" trigger) → log in ADR + cite in commit
- ADR conflict resolution: `/backtrack sd` (changes the decision) vs `/amend td` (changes implementation skeleton only)

## Phase Gate Discipline
- 5-Phase methodology (DESIGN → DESIGN QA → IMPLEMENT → HARDEN → DELIVER) per CLAUDE.md §7 Glossary
- Three-Tier Closure (Task / Walk / Phase Gate) per CLAUDE.md §1 — never conflate
- For PhoenicisNex specifically: Tier 1.5 walk artifact = headless backtest + Tester log + journal audit (no GUI walk)
- Phase Gate ปิดไม่ได้จนกว่า: all `[x]` task ACs + Tier 1.5 walk artifact ≤14d + `IMPL-Pn-GATE` task `[x]`

## Cold-Bootstrap Recipe (PhoenicisNex)

> Per user remark 2026-05-02: developer MUST be able to bootstrap from a clean state and run G1-G4 reproducibly. Derived from 3 MT5 SKILLs.

### Bootstrap from cold (assumes MT5 installed per `origin.txt`)

```bash
# 1. Resolve install + data dirs
ORIGIN=$(cat origin.txt | tr -d '\r')                     # e.g. "C:\Program Files\FBS MetaTrader 5ph"
TERMINAL_ID=$(basename "$(pwd)")                          # 32-char hex
DATA_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Terminal/$TERMINAL_ID"
TESTER_LOG_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs"

# 2. Compile entry .mq5 (G1)
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"$DATA_DIR/MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log

# 3. Verify compile log (G1 pass)
iconv -f UTF-16LE -t UTF-8 "$DATA_DIR/MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" \
  | grep -E "Result:|error" | tail -5
# Expect: "Result: 0 errors, 0 warnings, NNNN ms elapsed"

# 4. Confirm foreground MT5 is closed (data-dir lock prevents headless launch)
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle

# 5. Smoke run (G3) — uses standard bootstrap_smoke.ini per TD-02 §13.6
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/bootstrap_smoke.ini /tmp/bootstrap_run.txt

# 6. Inspect bootstrap log (G2 + G4 combined — init_ok + no [ERROR])
grep -nE "\[Phoenicis\]|init_ok|\[ERROR\]" /tmp/bootstrap_run.txt | head -30

# 7. Inspect journal (G4) — sample 5 records vs schema
head -5 MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl | jq .
```

### Teardown (between iterations)

```bash
# Reset state for fresh boot test (DESTRUCTIVE — confirms cold-bootstrap path)
rm -f MQL5/Files/PhoenicisNex/state/state.json
rm -f MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl
# Then re-run Step 5-7 of bootstrap above; expect log:
# [system][ev=state_corrupt_starting_fresh] + state restored to defaults per NFR-3.1
```

### Smoke spec invocation (single command)

```bash
# Per-task smoke ini lives at simulation/headless-tests/<task>.ini
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/<task>.ini /tmp/<task>_run.txt
```

## CI Hook (advisory — not auto-written)

> Suggested CI step (e.g., GitHub Actions on Windows runner with MT5 installed): run `bootstrap_smoke.ini` against a clean clone on every PR. PhoenicisNex CI infrastructure is NOT YET established — when added, file would land at `.github/workflows/mt5-smoke.yml` and call the same `run_headless_backtest.sh` script.

## Phase 5 Closure mechanical gates (engineer-side, per-task)

> Added 2026-05-04 per impl-plan rebuttal-round-07 §07.1/07.2/07.3/07.4/07.5 recommendations; expanded 2026-05-05 to 11 gates after R16 caught build-integrity + commit-hygiene defect classes. Run **all 11** before TL;DR `Last updated:` rewrite + commit. Catches R06/R07 defect classes at task-3 (per-closure) instead of task-33 (per-review-cycle).

| # | Gate | Command | Pass criteria |
|---|------|---------|---------------|
| 1 | **Forbidden-pattern grep** | `grep -cnE "deferred per .* precedent\|deferred to operator-runtime\|structurally complete.*deferred\|live verification deferred" docs/state/impl-plan.md` | `0` hits — if non-zero, reword AC text + register E-AC in `deferred-ac-registry.md` instead of inline `[x]` defer |
| 2 | **TL;DR ↔ registry recount** | `awk -F'\|' 'NR>13 && /^\| P[0-9]/ {gsub(/ /,"",$2); print $2}' docs/state/deferred-ac-registry.md \| sort \| uniq -c` then compare with `impl-plan.md` line ~8 `Deferred-AC Active:` row counts | per-phase counts + total match TL;DR claim exactly |
| 3 | **TL;DR ↔ matrix denominator** | Verify TL;DR `Phase N x/y` denominator `y` matches `Phase × Size matrix § Total` for that phase (e.g., P4=17 not P4=11) | denominator equals matrix Total column |
| 4 | **Sentinel counter increment** | After closing task, bump `Plan Staleness Sentinel § Closures since last review` by +1 atomically with TL;DR `Last updated:` rewrite | counter = (post-review closures); section + TL;DR self-flag agree |
| 5 | **overview.md sync** | Update `docs/state/overview.md § Impl Plan` row Last Updated date + status string append (per CLAUDE.md §6 State Reconciliation Discipline 3-file rule) | overview.md Last Updated == today; status string mentions latest closure |
| 6 | **File integrity (post-Edit-batch)** | `grep -c "^## End of Plan" docs/state/impl-plan.md` then `tail -3 docs/state/impl-plan.md` | exactly `1` `## End of Plan` marker; tail shows clean closure with no orphan fragments / partial words / dangling `---` |
| 7 | **Phase Status Snapshot Notes sweep** | Re-read `## Phase Status Snapshot` table row of the relevant phase; verify Notes column reflects post-closure reality (Mid-Phase Audit status, next-task pointer, threshold flags) | Notes column does NOT contradict TL;DR / Audit Log narrative / Sentinel; no stale "🚨 THRESHOLD CROSSED" or stale "Next:" pointing to a closed task |
| 8 | **Narrative-section freshness sweep** | Re-read `## Open Risks` (each R-N row) + `## Next Best Action` checklist; rewrite or strikethrough rows whose claims are invalidated by this closure | no Open Risks row references closed tasks as still-open; Next Best Action top unchecked item == TL;DR `Next:` pivot |
| 9 | **Post-fix grep verification (impl-review-fix only)** | After a fix-round commits land: (a) re-run the originating R-finding's pattern grep with `--count` against the touched dir(s); (b) ALSO run a broadest-class grep that matches the *intent* of the finding (e.g., if the finding is "remove references to closed task X", use `grep -rcE "deferred to <task-id>(\+\| \|\.\|$)"` against the whole `MQL5/Experts/PhoenicisNex` tree, not just literal `<task-id>+` against one subdir); **(c) R16 strengthening — repo-wide intent grep:** ALSO run the same broader-class regex against the *entire repo* `grep -rcE <pattern> .` (or equivalent `docs/ MQL5/ .claude/ scripts/ simulation/`) — state-doc + audit-doc surface MUST track the source-tree narrative; "whole repo tree" means the repo root literally (`.`), NOT a chosen subdir; narrowing to `MQL5/...` alone is the same regression class fix-round-15 § 9b accidentally introduced (caught by R16 § 16.3 + 16.7); record ALL THREE post-conditions in the fix-round report | (a) exit code 1 of the originating grep AND (b) zero matches of the broadest-class grep on the source tree AND (c) zero matches repo-wide OR each surviving hit annotated "preserved as audit history (commit log of round NN closure)" — any non-zero hit on (b) or (c) means the finding's intent was wider than the executed sweep; force the engineer to either expand the sweep or explicitly scope-out the non-target sites in the fix-round narrative |
| 10 | **Stash-clean G1 (R16 addition)** | After commit, run `git stash --include-untracked && "$METAEDITOR" /compile:MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5 /log` → inspect `.compile.log` → `git stash pop`; verify post-stash compile = `0 errors, 0 warnings`. Catches HEAD-vs-working-tree drift (R16 § 16.1 build-integrity defect class — caller in HEAD, callee body uncommitted in working tree → fresh clone fails) | exit code 0 + log shows clean compile against the committed surface only |
| 11 | **Working-tree clean post-closure (R16 addition)** | `git status --porcelain \| wc -l` after fix-round / task closure | exit count `0` (all artefacts referenced in fix-round narrative + closure tables — code, evidence sidecars, walk-batch logs, review/fix-round docs — are committed). Untracked review-round / fix-round / evidence files explicitly disallowed (R16 § 16.2 audit-trail gap) |

> **Why this is here:** R06 (2026-05-03) caught 20 forbidden-pattern hits accumulated across 33-task closure burst; R07 (2026-05-04) caught 1 forbidden-pattern regression introduced 24h after R06 closure + 3 state-reconciliation drifts; **R08 (2026-05-04) caught trailer file corruption (3× `## End of Plan` + dangling fragments) + Phase Status Notes column frozen at pre-IMPL-057 state + Open Risks R-6 stale + Next Best Action checklist frozen at P1 era** — all rebuttal-introduced or rebuttal-missed defects in narrative-parallel sections that gates #1-#5 don't cover. Gates #6-#8 push enforcement to **rebuttal-output verification** + **intra-plan parallel-narrative sweep** (TL;DR ≠ only canonical source — Phase Status Snapshot + Open Risks + Next Best Action are also reader-facing snapshots). **R13 (2026-05-04)** added gate #9 after fix-round-12 § 12.8 advertised "all 11 slot files" updated with stale "deferred to IMPL-053+" wording, but actual grep showed 21 sites in 17 slot files survived the sweep (Finding 13.2 HIGH); a single `grep -c "deferred to IMPL-053"` post-condition in the fix-round body would have caught the under-delivered scope at commit time. Same gate would have surfaced R12 § Finding 12.6 / 12.2 SelfTest omissions (R13 Findings 13.5 / 13.6) as scope-narrower-than-narrative. **R14 (2026-05-04)** strengthened gate #9 with clause (b) after fix-round-13 § 13.2 closed "17 slot files / 23 sites" with grep `IMPL-053\+` returning 0 hits — but the broader regex `deferred to IMPL-053` (no literal `+`, repo-wide, not just `slots/`) showed 23 OTHER stale sites still extant (10 in `slots/` without `+`, 13 in `services/`/`core/`/`spike/` with `+`). Same root cause as R12 § 12.8 → R13 § 13.2 (the originating grep is scope-narrower than the defect class). Clause (b) forces the engineer to verify against the **defect class**, not just the **literal pattern from cited sites**, breaking the next-coarser-granularity recurrence chain. **R16 (2026-05-05)** added clause (c) + Gates #10/#11 after fix-round-15 § 9b narrowed the broader-class sweep to `MQL5/...` only — `docs/state/impl-plan.md` accumulated 25 stale `deferred to IMPL-053+` rows that the source-tree-only sweep missed. Same root cause as R12 → R13 → R14 chain (next-coarser-granularity scope narrowing). Clause (c) forces literal repo-root `.` for the intent grep. Gate #10 (stash-clean G1) catches HEAD-vs-working-tree drift (caller committed, callee body uncommitted = fresh-clone build fail — Finding 16.1 CRITICAL). Gate #11 (working-tree clean post-closure) catches commit-hygiene gaps where fix-round narratives advertise "applied + verified" but ~500 LOC of edits + evidence sidecars + review docs sit uncommitted (Finding 16.2 HIGH).

## Failure escalation
- G1-G4 failure → log in task notes + ≤30-line snippet → fix locally OR escalate via `/backtrack sd` / `/amend td`
- Phase 5 mechanical-gate failure → fix the artifact (reword AC / recount registry / fix denominator / bump Sentinel / sync overview.md / clean trailer / sweep Phase Status Notes / refresh Open Risks + Next Best Action / re-run post-fix grep / stash-clean G1 / commit untracked artefacts) — do NOT mark task complete with `[x]` until all 11 gates pass
- ห้าม silent skip — TD-02 §13.5 audit contract
