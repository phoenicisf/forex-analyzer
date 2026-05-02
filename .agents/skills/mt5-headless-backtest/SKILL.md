---
name: mt5-headless-backtest
description: Run MetaTrader 5 Strategy Tester programmatically (headless, no GUI) via terminal64.exe /config:tester.ini, then parse the resulting Tester agent log for milestone counts and runtime evidence. Use this skill whenever the user wants to validate an EA end-to-end without manually clicking through the GUI — phrases like "run a backtest headless", "Strategy Tester smoke", "1-month backtest", "validate Hydra in tester", "headless run", "run a tester for EA X", "verify pack write at scale", or HD-01d-style runtime Prove-It checkpoints. Especially valuable when you need quantitative milestone counts (how many packs written, how many TIMED_OUT, etc.) for impl-plan acceptance criteria, or when re-running after a fix to confirm the change unblocks a previously broken flow. Trigger even when the user just says "let's run a backtest" — the skill knows the data-dir lock dance, the log-baseline trick, and the milestone-count parse pattern that you'd otherwise have to reinvent. (project)
---

# MT5 Headless Backtest Runner

Runs Strategy Tester programmatically without a GUI session and parses the agent log to verify EA runtime behavior end-to-end. Built for MQL5 EAs in this codebase (Hydra-style orchestrators with `[Hydra] / [PackOrchestrator] / [PricesBuilder]` Print() output) but the workflow generalizes to any EA whose Print() lines have a stable prefix.

## Why this skill exists

Manual Strategy Tester runs are GUI-bound: open MT5, Ctrl+R, configure form, F5, watch the spinner, eyeball the Experts tab. That's fine for ad-hoc work but it's expensive when you need to:

- **Quantify** — "how many packs were written?" can't be answered by scrolling
- **Re-run after a fix** — bisecting a regression needs cheap, repeatable runs
- **Capture for handoff** — impl-plan AC like "≥ 1 pack written end-to-end" needs the count, not a screenshot
- **Catch silent failures** — an EA that emits no signals over a 1-month window will look "fine" in the GUI summary; only line-by-line log parsing reveals which gate is rejecting

The skill captures the gotchas (data-dir lock, UTF-16LE encoding, log-baseline trick) so future invocations don't re-discover them.

## When to use

Activate this skill when:

- The user asks for a backtest, Strategy Tester run, or "tester smoke" — even casually
- An EA has just landed code+compile and needs runtime Prove-It (HD-01d-style)
- A fix to an existing EA needs verification that it unblocks the previously broken path (count-based regression)
- The user wants impl-plan AC like "1-month BACKTEST produces ≥ N packs"
- Capturing concrete numbers (heartbeat count, pack count, lot-reject count, verdict TIMED_OUT count) for handoff/overview docs

When NOT to use:

- Compile-only checks → use MetaEditor /compile directly (faster, no tester overhead)
- Reading existing logs without running anything new → `mt5-log-reader` skill
- Unit-test scripts (CAssert harness) — those have their own GUI F5 path; the headless equivalent (`Expert=Scripts\TestFoo`) is plausible but unproven in this project as of 2026-04-28

## Core constraints (read first — these bite)

1. **Data-dir lock.** MT5 locks `Terminal/{terminal-id}/` while the foreground GUI is open. A second `terminal64.exe` pointing at the same data dir exits within ~5 seconds with no useful error. **Close the foreground terminal before launching headless.** Confirm with the user first — closing their session loses chart state they may be working with.

2. **/portable mode is a trap.** The MT5 install (path in `origin.txt`) typically ships with NO `MQL5/` tree colocated with `terminal64.exe` — all data lives in user data dir. `/portable` therefore finds no expert to load. Use the regular data dir with the GUI closed instead.

3. **Tester log lives in a different tree from runtime log.** Runtime: `Terminal/{id}/MQL5/Logs/YYYYMMDD.log`. Tester: `Tester/{id}/Agent-127.0.0.1-3000/logs/YYYYMMDD.log`. Always use the Tester path for backtest runs.

4. **All MT5 logs are UTF-16LE.** Plain `cat` shows garbage spaces between every char. Always pipe through `iconv -f UTF-16LE -t UTF-8`.

5. **Tester log is append-only across runs.** Multiple backtests in the same calendar day all extend the same `YYYYMMDD.log`. Always capture the byte-baseline before launching so you can extract just *your* run's entries.

6. **MetaEditor compile exit code is unreliable** (returns 1 even on success — same WINE/CrossOver gotcha noted in `mt5-log-reader`). Check the `.log` file for `Result: 0 errors, 0 warnings` instead.

## Workflow

### Step 1: Resolve paths

The terminal-id is a 32-char hex hash. When the project lives directly under the data dir (this codebase does), the working directory ends in that hash.

The MT5 install path is stored in `origin.txt` at the project root (one line, e.g. `C:\Program Files\FBS MetaTrader 5`). **Always read it dynamically** instead of hardcoding a broker name:

```bash
# Read origin.txt to resolve the MT5 install directory
ORIGIN=$(cat origin.txt | tr -d '\r')                    # e.g. "C:\Program Files\FBS MetaTrader 5"
TERMINAL=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/terminal64.exe

TERMINAL_ID=$(basename "$(pwd)")        # 776D2ACDFA4F66FAF3C8985F75FA9FF6 here
DATA_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Terminal/$TERMINAL_ID"
TESTER_LOG_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs"
```

If the project lives elsewhere, the user can tell you the terminal-id, or you can grep an existing log path from `docs/` to derive it.

### Step 2: Recompile if .mq5 changed since last .ex5

```bash
# $ORIGIN from Step 1 (read from origin.txt)
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"MQL5/Experts/Hydra/Hydra.mq5" /log
sleep 1
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/Hydra/Hydra.compile.log" 2>/dev/null \
  | grep -E "Result:|error" | tail -3
# Expect: "Result: 0 errors, 0 warnings, NNNN ms elapsed"
```

If errors → fix and re-run; do not proceed to backtest with stale .ex5.

### Step 3: Close the foreground terminal (with user confirmation)

```powershell
Get-Process -Name terminal64 -ErrorAction SilentlyContinue \
  | Select-Object Id, MainWindowTitle | Format-Table -AutoSize
```

If a terminal is running, ask the user before closing — chart state may be unsaved. Then graceful close:

```powershell
$p = Get-Process -Id <PID> -ErrorAction SilentlyContinue
if ($p) {
  $p.CloseMainWindow() | Out-Null
  Start-Sleep -Seconds 2
  $still = Get-Process -Id <PID> -ErrorAction SilentlyContinue
  if ($still) { Stop-Process -Id <PID> -Force }
}
```

### Step 4: Write `simulation/headless-tests/{name}.ini`

Commit the ini file so future re-runs are reproducible. Minimum fields (Strategy Tester [Tester] section):

```ini
[Tester]
Expert=Hydra\Hydra              ; relative to MQL5/Experts/, no .ex5 extension, BACKSLASH on Windows
Symbol=EURUSD
Period=H1                       ; M1/M5/M15/M30/H1/H4/D1
Optimization=0                  ; 0 = single backtest, not parameter sweep
Model=4                         ; 4 = every tick based on real ticks (highest fidelity)
FromDate=2026.03.23
ToDate=2026.04.23
ForwardMode=0
Deposit=1000
Currency=USD
ProfitInPips=0
Leverage=100
ExecutionMode=0
ShutdownTerminal=1              ; CRITICAL — auto-exit when backtest finishes
Visual=0                        ; CRITICAL — headless, no chart window
```

Without `ShutdownTerminal=1`, the terminal stays alive after the run and you have to kill it manually. Without `Visual=0`, the GUI opens and may steal focus.

For the `Expert=` line, use Windows backslash. The path resolves under `Terminal/{id}/MQL5/Experts/`. The .ex5 must already exist there (Step 2 produced it).

### Step 5: Capture log baseline + launch headless

Use `run_in_background: true` on the launch so the harness doesn't block:

```bash
LOG="$TESTER_LOG_DIR/$(date +%Y%m%d).log"
BASELINE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
echo "$BASELINE" > /tmp/headless_baseline

# Use absolute Windows-style path with double-backslash escapes for /config:
CONFIG_WIN=$(echo "$DATA_DIR/simulation/headless-tests/{name}.ini" \
  | sed 's|/c/|C:\\\\|; s|/|\\\\|g')

"$TERMINAL" /config:"$CONFIG_WIN"
```

If launching as a foreground bash command (not via `run_in_background`), append `&` and capture `$!` for the polling loop.

### Step 6: Monitor until completion

Wall-clock for a 1-month H1 backtest on this codebase is ~3 minutes. Use a polling loop with timeout:

```bash
PID=$!
for i in 1 2 3 4 5 6 7 8 9 10; do
  sleep 30
  if kill -0 $PID 2>/dev/null; then
    SIZE=$(stat -c%s "$LOG")
    echo "+$((i*30))s: alive ; log=$SIZE"
  else
    SIZE=$(stat -c%s "$LOG")
    echo "+$((i*30))s: exited ; log=$SIZE"
    break
  fi
done
```

For longer windows (multi-month, M1 period, slower hardware) extend the loop. If the loop exhausts without the process exiting, something hung — kill the PID and inspect the log for clues.

### Step 7: Decode only the new entries

```bash
NEW_LOG=/tmp/headless_run.txt
BASELINE=$(cat /tmp/headless_baseline)
dd if="$LOG" bs=1 skip=$BASELINE 2>/dev/null \
  | iconv -f UTF-16LE -t UTF-8 > "$NEW_LOG"
wc -l "$NEW_LOG"
```

`dd` is the simplest way to skip a byte offset in a binary file. The decoded output goes to UTF-8 so subsequent `grep`s work on plain text.

### Step 8: Milestone-count parse

The pattern is: `grep -c "<stable Print prefix>"` for each milestone you want quantified. The stable prefixes for Hydra-style EAs in this codebase:

```bash
echo "=== Hydra orchestrator milestones ==="
echo "OnInit                    : $(grep -c "\[Hydra\] OnInit OK" $NEW_LOG)"
echo "Heartbeats                : $(grep -c "WriteFileAtomic ok path='edarts/heartbeat" $NEW_LOG)"
echo "regime UNKNOWN bootstrap  : $(grep -c "regime UNKNOWN (bootstrap)" $NEW_LOG)"
echo "no active strategies      : $(grep -c "no active strategies" $NEW_LOG)"
echo "aggregator no-winner      : $(grep -c "aggregator no-winner" $NEW_LOG)"
echo "risk gate fail            : $(grep -c "risk gate: CanOpenNew=false" $NEW_LOG)"
echo "lot reject                : $(grep -c "\[Hydra\] lot reject" $NEW_LOG)"
echo "pattern blocked           : $(grep -c "pattern blocked" $NEW_LOG)"
echo ""
echo "=== Pack write pipeline ==="
echo "begin WritePack           : $(grep -c "PackOrchestrator\] ok begin WritePack" $NEW_LOG)"
echo "step1 meta.json           : $(grep -c "PackOrchestrator\] ok step1 meta" $NEW_LOG)"
echo "step2 prices.csv          : $(grep -c "PackOrchestrator\] ok step2 prices" $NEW_LOG)"
echo "step3a indicators csv     : $(grep -c "PackOrchestrator\] ok step3a" $NEW_LOG)"
echo "step3b manifest.json      : $(grep -c "PackOrchestrator\] ok step3b" $NEW_LOG)"
echo "step4 news_context.json   : $(grep -c "PackOrchestrator\] ok step4" $NEW_LOG)"
echo "step5 decision.md         : $(grep -c "PackOrchestrator\] ok step5" $NEW_LOG)"
echo "step7 _READY.flag LAST    : $(grep -c "PackOrchestrator\] ok step7" $NEW_LOG)"
echo "WritePack complete        : $(grep -c "WritePack complete" $NEW_LOG)"
echo ""
echo "=== Failure paths (should be 0 on a clean run) ==="
echo "PricesBuilder ANY reject  : $(grep -c "\[PricesBuilder\] reject" $NEW_LOG)"
echo "WritePack failed          : $(grep -c "\[Hydra\] WritePack failed" $NEW_LOG)"
echo ""
echo "=== Verdict drain ==="
echo "ENQUEUED                  : $(grep -c "pack ENQUEUED" $NEW_LOG)"
echo "TIMED_OUT (150 s budget)  : $(grep -c "verdict TIMED_OUT" $NEW_LOG)"
echo "DispatchApprove/Filter    : $(grep -c "DispatchApprove\|DispatchFilter" $NEW_LOG)"
echo ""
echo "=== Lifecycle close ==="
echo "OnDeinit                  : $(grep -c "\[Hydra\] OnDeinit" $NEW_LOG)"
```

If any count is unexpected (zero where positive expected, or vice versa), pull representative lines for context:

```bash
grep -E "\[Hydra\]" "$NEW_LOG" | grep -v "WriteFileAtomic" | head -30
grep -E "\[PackOrchestrator\]" "$NEW_LOG" | head -20
grep -E "\[PricesBuilder\] reject" "$NEW_LOG" | head -5
```

For non-Hydra EAs, swap the pattern to whatever Print prefix the target EA uses. The trick is that EAs in this codebase emit structured `[ClassName] ...` prefixes precisely so milestone counting stays cheap.

### Step 9: On-disk verification (where applicable)

For pack-writing EAs, confirm files actually landed and ADR-001 ordering held:

```bash
PACKS_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Terminal/Common/Files/edarts/packs"
echo "Total pack directories: $(ls "$PACKS_DIR" | wc -l)"

# Pick a sample from your run window and inspect:
SAMPLE=$(ls "$PACKS_DIR" | grep "^260323" | head -1)
ls -la "$PACKS_DIR/$SAMPLE/"

# _READY.flag should be the newest mtime in the directory (ADR-001 contract):
ls -t "$PACKS_DIR/$SAMPLE" | head -1
# Expect: "_READY.flag"
```

If `_READY.flag` is NOT the newest, ADR-001's "flag last" invariant was violated — that's a real bug, not a parse error.

### Step 10: Report to user (Thai-friendly summary)

Present the milestone counts in a table with ✅ / ❌ status. Include:

- The scope of the run (symbol + period + date window + tick model)
- Per-EA milestone counts that were the user's question
- Pre-fix vs post-fix delta when re-running after a fix
- Path to the committed `simulation/headless-tests/{name}.ini` for reproducibility
- Anything that was untested and why (e.g., no fake-CLI seed → APPROVE/DENY/FILTER/HOLD dispatch matrix not directly exercised; only TIMED_OUT path)

Don't bury the lede — if the run was clean, lead with "✅ N packs written, 0 failures." If something failed, lead with the failure and where in the pipeline it bailed.

## Pitfalls

### Backslash vs forward slash in the .ini

`Expert=Hydra\Hydra` works. `Expert=Hydra/Hydra` is silently ignored on some MT5 builds — the EA never loads and the agent log just shows "no expert assigned". When in doubt, copy the path style from a working .ini.

### /config: arg path style

The `/config:` argument expects Windows-style absolute path. Backslashes inside the bash string need double-escaping:

```bash
"$TERMINAL" /config:"C:\\Users\\foo\\config.ini"  # ✅ works
"$TERMINAL" /config:"/c/Users/foo/config.ini"     # ❌ MT5 doesn't grok bash paths
"$TERMINAL" /config:"$DATA_DIR/x.ini"             # ❌ usually breaks too
```

### Tester log byte offset must be captured BEFORE launch

If you launch first and then `stat -c%s "$LOG"`, you've already mixed your run's bytes with whatever was there before. Capture the baseline first, ALWAYS.

### Tester log path is per terminal-id

The terminal-id (32-char hex) is in the path twice — once in `Terminal/` and once in `Tester/`. When troubleshooting "where did my log go?", verify both paths share the same hex.

### Multiple terminals on the same data dir

Don't try. The lock check is by data-dir, not by process. Even `terminal64.exe /portable` against the same data dir collides. Either close the foreground or wait until the user is free.

### What if the user refuses to close their terminal?

Realistic fallbacks:
1. **GUI re-trigger** — have them press Ctrl+R → F5 in their open terminal. You read the log after they signal done.
2. **Defer** — code+compile is sufficient evidence for many checkpoints (most EA work in this codebase shipped on code+compile alone before HD-01 made runtime Prove-It mandatory).
3. **Schedule** — circle back when their session naturally ends.

Don't reach for `/portable` against the broker install — it has no MQL5 tree adjacent to the .exe.

## Helper script

`scripts/run_headless_backtest.sh` bundles Steps 5-7 (capture baseline, launch, wait, decode new entries) into a single invocation. The script reads `origin.txt` to resolve the MT5 install path dynamically. It also derives the 32-char-hex terminal-id from `cwd`.

```bash
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
  simulation/headless-tests/hd01d_tester.ini \
  /tmp/headless_run.txt
```

The script returns 0 on tester process clean exit, non-zero on timeout / lock conflict / launch failure. Stdout has progress ticks; the parsed log lands at the second arg.

## References

- `references/log-paths.md` — Full breakdown of MT5 log file locations (Terminal vs Tester vs MetaEditor)
- `references/tester-ini-schema.md` — Full `[Tester]` section field reference + Model/ForwardMode/ExecutionMode enum values
- `simulation/headless-tests/hd01d_tester.ini` (in repo root) — Working example from HD-01d Strategy Tester smoke (commit `0b3f755`); 71-pack run on EURUSD H1 1-month real ticks

## Related skills

- `mt5-log-reader` — for reading MT5 logs without running anything new (Experts pane, MetaEditor compile output)
- `skill-creator` — used to author this skill from the HD-01d session conversation history (commit context: 2026-04-28)
