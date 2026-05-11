#!/usr/bin/env bash
set -euo pipefail

TERMINAL="/c/Program Files/FBS MetaTrader 5ph/terminal64.exe"
INI_PATH="${1:-simulation/headless-tests/q1_2021_paired_rewrite.ini}"
OUT_LOG="${2:-/tmp/iter3_rewrite.txt}"
TERMINAL_ID="A12EC900AF5AF5023ECB36F7FB72E396"
USER_NAME="kritsana.ye"

TESTER_LOG_DIR="/c/Users/$USER_NAME/AppData/Roaming/MetaQuotes/Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs"
TESTER_LOG="$TESTER_LOG_DIR/$(date +%Y%m%d).log"

INI_ABS=$(realpath "$INI_PATH")
# Convert /c/foo/bar -> C:\foo\bar using python (avoids sed quoting hell)
INI_WIN=$(python -c "
import sys
p=sys.argv[1]
bs=chr(92)
print('C:'+bs+p[3:].replace('/',bs))
" "$INI_ABS")

BASELINE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
echo "tester_log=$TESTER_LOG"
echo "baseline=$BASELINE bytes"
echo "ini_win=$INI_WIN"

"$TERMINAL" /config:"$INI_WIN" &
PID=$!
echo "launched PID=$PID at $(date '+%H:%M:%S')"

sleep 5
if ! kill -0 "$PID" 2>/dev/null; then
  SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
  if [[ "$SIZE" -le "$BASELINE" ]]; then
    echo "FAIL early exit (lock?)" >&2
    exit 5
  fi
fi

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  sleep 30
  if kill -0 "$PID" 2>/dev/null; then
    SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
    echo "+$((i*30))s alive log=$SIZE"
  else
    SIZE=$(stat -c%s "$TESTER_LOG" 2>/dev/null || echo 0)
    echo "+$((i*30))s exited log=$SIZE at $(date '+%H:%M:%S')"
    break
  fi
  if [[ $i -eq 20 ]]; then
    echo "TIMEOUT — killing" >&2
    kill -TERM "$PID" 2>/dev/null || true
    sleep 2
    kill -KILL "$PID" 2>/dev/null || true
    exit 6
  fi
done

dd if="$TESTER_LOG" bs=1 skip="$BASELINE" 2>/dev/null \
  | iconv -f UTF-16LE -t UTF-8 > "$OUT_LOG"
LINES=$(wc -l < "$OUT_LOG")
echo "decoded $LINES lines -> $OUT_LOG"
