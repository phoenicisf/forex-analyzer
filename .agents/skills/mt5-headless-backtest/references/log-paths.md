# MT5 Log File Locations

Quick reference for where MT5 writes logs across its three subsystems.

## Three log trees, three purposes

| Subsystem | Path template | When written |
|---|---|---|
| **Runtime (live charts)** | `{Terminal}/MQL5/Logs/YYYYMMDD.log` | EA `Print()` while attached to a chart in the foreground GUI; also `Alert()` |
| **Strategy Tester** | `{Tester}/Agent-127.0.0.1-3000/logs/YYYYMMDD.log` | Backtest runs (GUI Ctrl+R or headless `/config:`) |
| **MetaEditor compile** | `{src-dir}/{file}.compile.log` (.mq5 → file.compile.log; expert subdir scripts: `{file}.log`) | Every `MetaEditor64.exe /compile:` invocation |

Where:

- `{Terminal}` = `C:\Users\{user}\AppData\Roaming\MetaQuotes\Terminal\{terminal-id}\`
- `{Tester}` = `C:\Users\{user}\AppData\Roaming\MetaQuotes\Tester\{terminal-id}\`
- `{terminal-id}` = 32-char hex hash; same value in both trees, derived from the install/login

## Common terminal-id (this codebase)

`776D2ACDFA4F66FAF3C8985F75FA9FF6` — FBS-Demo terminal. The project working directory IS this path's `{Terminal}/` subdir, so `basename $(pwd)` returns the id directly.

## Encoding gotcha

All three log types are **UTF-16LE** (Little Endian). Plain `cat` shows garbage spaces between every char. Always:

```bash
iconv -f UTF-16LE -t UTF-8 path/to/file.log
```

Compile logs (`*.compile.log` / `*.log` next to .mq5) are sometimes UTF-16LE-with-BOM; the `iconv -f UTF-16LE` handles both BOM-present and BOM-absent.

## Log rotation

- **Runtime + Tester**: rotate by **calendar date**. `20260428.log` covers all activity on April 28. Multiple sessions in the same day all append to the same file.
- **MetaEditor compile**: overwritten every compile. The `.log` file always reflects the most recent run only.

## Implications for the headless workflow

1. **Always capture log byte-baseline before launching** — append-only across runs means you'll re-parse old entries otherwise:

   ```bash
   BASELINE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
   # ... launch backtest ...
   dd if="$LOG" bs=1 skip=$BASELINE 2>/dev/null | iconv -f UTF-16LE -t UTF-8 > /tmp/new
   ```

2. **Compile output is one-shot** — if you `/compile:` then run a Strategy Tester, the compile.log is gone by the time you check; check `Result: 0 errors, 0 warnings` immediately after compile.

3. **Don't grep the entire 50+ MB Tester log** — extract just the slice for your run first; otherwise grep-counts include every backtest from every session today.

## Script vs Expert vs Indicator placement

The `Expert=` line in tester.ini resolves under `{Terminal}/MQL5/Experts/`. To run a Script via Strategy Tester:

```ini
Expert=Scripts\TestPricesBuilder    ; resolves to {Terminal}/MQL5/Scripts/TestPricesBuilder.ex5
```

Note: As of 2026-04-28, this codebase has only confirmed headless EA backtesting works (Hydra HD-01d). Script-mode headless was untested. The CAssert harness scripts (`MQL5/Scripts/EDarts/Test*.mq5`) ran via GUI F5 only. The headless Script equivalent is plausible but unverified — falsification welcome.
