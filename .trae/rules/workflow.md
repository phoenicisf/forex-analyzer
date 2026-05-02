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
ORIGIN=$(cat origin.txt | tr -d '\r')                     # e.g. "C:\Program Files\FBS MetaTrader 5"
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

## Failure escalation
- G1-G4 failure → log in task notes + ≤30-line snippet → fix locally OR escalate via `/backtrack sd` / `/amend td`
- ห้าม silent skip — TD-02 §13.5 audit contract
