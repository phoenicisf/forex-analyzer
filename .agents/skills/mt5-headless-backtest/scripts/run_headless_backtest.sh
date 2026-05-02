#!/usr/bin/env bash
# run_headless_backtest.sh — launch MT5 Strategy Tester headlessly + decode new log entries
#
# Usage:
#   bash run_headless_backtest.sh <tester-ini-path> <output-decoded-log>
#
# Example:
#   bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
#        simulation/headless-tests/hd01d_tester.ini \
#        /tmp/headless_run.txt
#
# Assumptions:
#   - origin.txt at project root contains the MT5 install path (e.g. C:\Program Files\MetaTrader 5)
#   - Project working directory's basename is the 32-char-hex terminal-id
#     (true when the codebase lives under {AppData}/MetaQuotes/Terminal/{id}/)
#   - The .ex5 corresponding to the Expert= line in the .ini is already built
#     (run MetaEditor /compile separately if you've edited .mq5)
#   - The foreground MT5 terminal is CLOSED — this script does not close it
#     (closing the user's session is destructive and requires explicit consent)
#
# Exit codes:
#   0  — backtest completed cleanly, decoded log written to $2
#   1  — wrong arg count
#   2  — terminal binary missing
#   3  — input .ini missing
#   4  — terminal-id couldn't be derived (cwd basename isn't 32 hex chars)
#   5  — backtest process exited within 5s (likely lock conflict — close GUI first)
#   6  — backtest didn't finish within timeout

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <tester-ini-path> <output-decoded-log>" >&2
    exit 1
fi

INI_PATH="$1"
OUT_LOG="$2"

# Read MT5 install path from origin.txt (one line, Windows path)
if [[ ! -f "origin.txt" ]]; then
    echo "ERROR: origin.txt not found in $(pwd). Expected a file containing the MT5 install path." >&2
    exit 2
fi
ORIGIN=$(cat origin.txt | tr -d '\r')
TERMINAL=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/terminal64.exe
[[ -x "$TERMINAL" ]] || { echo "ERROR: terminal binary not found at $TERMINAL (origin.txt=$ORIGIN)" >&2; exit 2; }
[[ -f "$INI_PATH" ]] || { echo "ERROR: tester ini not found: $INI_PATH" >&2; exit 3; }

# Derive terminal-id from cwd basename (32-char hex when under MetaQuotes/Terminal/{id}/).
TERMINAL_ID=$(basename "$(pwd)")
if [[ ! "$TERMINAL_ID" =~ ^[0-9A-F]{32}$ ]]; then
    echo "ERROR: cwd basename '$TERMINAL_ID' does not look like a 32-char hex terminal-id." >&2
    echo "       Run this script from a project that lives directly under" >&2
    echo "       {AppData}/MetaQuotes/Terminal/{32-hex}/ — or hard-code TERMINAL_ID below." >&2
    exit 4
fi

TESTER_LOG_DIR="/c/Users/$USER/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs"
TESTER_LOG="$TESTER_LOG_DIR/$(date +%Y%m%d).log"

# Convert ini path → Windows-style absolute path with double-backslash escapes.
INI_ABS=$(realpath "$INI_PATH")
INI_WIN=$(echo "$INI_ABS" | sed 's|^/c/|C:\\|; s|/|\\|g')

# Capture baseline so we extract only THIS run's entries.
BASELINE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
echo "[run_headless] tester_log=$TESTER_LOG"
echo "[run_headless] baseline=$BASELINE bytes"
echo "[run_headless] ini=$INI_WIN"

# Launch in background.
"$TERMINAL" /config:"$INI_WIN" &
PID=$!
echo "[run_headless] launched PID=$PID"

# +5s sanity check — if the process exited that fast, we hit a data-dir lock.
sleep 5
if ! kill -0 "$PID" 2>/dev/null; then
    SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
    if [[ "$SIZE" -le "$BASELINE" ]]; then
        echo "[run_headless] FAIL: process exited within 5s and tester log did not grow." >&2
        echo "                    Likely cause: foreground terminal still has data-dir lock." >&2
        echo "                    Close terminal64.exe (with user's consent) and retry." >&2
        exit 5
    fi
fi

# Wait until the process exits, polling every 30s up to a 10-minute budget.
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    sleep 30
    if kill -0 "$PID" 2>/dev/null; then
        SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
        echo "[run_headless] +$((i*30))s: alive ; log=$SIZE bytes"
    else
        SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
        echo "[run_headless] +$((i*30))s: exited ; log=$SIZE bytes"
        break
    fi
    if [[ $i -eq 20 ]]; then
        echo "[run_headless] FAIL: still alive at 10 min — killing." >&2
        kill -TERM "$PID" 2>/dev/null || true
        sleep 2
        kill -KILL "$PID" 2>/dev/null || true
        exit 6
    fi
done

# Decode new entries (everything past the baseline) to the output path.
dd if="$TESTER_LOG" bs=1 skip="$BASELINE" 2>/dev/null \
  | iconv -f UTF-16LE -t UTF-8 > "$OUT_LOG"

LINES=$(wc -l < "$OUT_LOG")
echo "[run_headless] decoded $LINES lines → $OUT_LOG"
echo "[run_headless] OK"
