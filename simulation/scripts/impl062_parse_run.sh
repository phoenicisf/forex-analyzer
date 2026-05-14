#!/usr/bin/env bash
# impl062_parse_run.sh — post-run parse for IMPL-062 5-yr Bucket A regression
# Computes: final balance, drawdown, halt event, per-slot entry/exit count, drift vs $24.27M baseline
#
# Usage: bash impl062_parse_run.sh
# Output: stdout summary + /tmp/impl062_summary.json sidecar

set -uo pipefail

DATA_DIR="/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Terminal/A12EC900AF5AF5023ECB36F7FB72E396"
TID=$(basename "$DATA_DIR")
TLOG="/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Tester/$TID/Agent-127.0.0.1-3000/logs/$(date +%Y%m%d).log"
JDIR="/c/Users/kritsana.ye/AppData/Roaming/MetaQuotes/Tester/$TID/Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/journal/tester"
BASELINE_NP=24271276.63
DEPOSIT=1000

echo "=== IMPL-062 Bucket A 5-yr Regression Run #3 (rewrite-G4-ON, BT-001 single-pass methodology) ==="
echo "Data dir : $DATA_DIR"
echo "Tester log: $TLOG ($(stat -c%s "$TLOG" 2>/dev/null) bytes)"

JFILE=$(ls -t "$JDIR"/run-*.jsonl 2>/dev/null | head -1)
echo "Journal  : $JFILE ($(wc -l < "$JFILE" 2>/dev/null) records)"

# === DECODE TESTER LOG ===
DECODED=/tmp/impl062_tester.txt
iconv -f UTF-16LE -t UTF-8 "$TLOG" 2>/dev/null > "$DECODED"
echo "Decoded  : $DECODED ($(wc -l < "$DECODED") lines)"
echo ""

# === FINAL BALANCE + Tester verdict ===
echo "--- Tester final lines (balance / OnTester / passed) ---"
grep -E "Tester\s+(final balance|OnTester|.*ticks.*bars generated|.*test passed|test on EURUSD|tester forced|stopped)" "$DECODED" | tail -10
echo ""

# === HALT EVENTS ===
echo "--- Halt events (ev=halt / ev=halt_stable) ---"
grep -cE "ev=halt[^_]|ev=halt_stable|circuit_breaker_pingpong|HALTED" "$DECODED" 2>/dev/null
grep -E "ev=halt|circuit_breaker|HALTED" "$DECODED" 2>/dev/null | head -10
echo ""

# === ERROR markers ===
echo "--- ERROR / WARN counts (excluding ev= prefix patterns) ---"
echo "ERROR: $(grep -cE "\[ERROR\]|order_failed" "$DECODED" 2>/dev/null)"
echo "WARN : $(grep -cE "\[WARN\]" "$DECODED" 2>/dev/null)"
grep -E "\[ERROR\]" "$DECODED" 2>/dev/null | head -3
echo ""

# === JOURNAL summary ===
if [ -f "$JFILE" ] && [ -r "$JFILE" ]; then
  echo "--- Event type distribution ---"
  jq -r '.event_type' "$JFILE" 2>/dev/null | sort | uniq -c | sort -rn

  echo ""
  echo "--- Per-slot entry count ---"
  jq -r 'select(.event_type=="entry") | .slot_id' "$JFILE" 2>/dev/null | sort | uniq -c | sort -rn

  echo ""
  echo "--- Per-slot exit count ---"
  jq -r 'select(.event_type=="exit") | .slot_id' "$JFILE" 2>/dev/null | sort | uniq -c | sort -rn

  echo ""
  echo "--- G4 fix verification (IMPL-063 E-AC #2: BI entries with sl != 0) ---"
  jq -r 'select(.event_type=="entry" and .slot_id=="BI") | "ticket=\(.ticket_id) sl=\(.sl)"' "$JFILE" 2>/dev/null | head -5
  echo "  BI entries with sl != 0 count: $(jq -r 'select(.event_type=="entry" and .slot_id=="BI" and (.sl != 0.0 // false)) | 1' "$JFILE" 2>/dev/null | wc -l)"

  echo ""
  echo "--- G4 fix verification (IMPL-063 E-AC #1: J exits at MAGIC_J=206) ---"
  jq -r 'select(.event_type=="exit" and .slot_id=="J") | "ticket=\(.ticket_id) magic=\(.magic)"' "$JFILE" 2>/dev/null | head -5
  echo "  J exits with magic=206 count: $(jq -r 'select(.event_type=="exit" and .slot_id=="J" and .magic==206) | 1' "$JFILE" 2>/dev/null | wc -l)"

  echo ""
  echo "--- Total PnL from journal exits ---"
  TOTAL_PNL=$(jq -r 'select(.event_type=="exit") | .pnl // 0' "$JFILE" 2>/dev/null | awk '{s+=$1} END {printf "%.2f", s}')
  echo "  Sum exit pnl: $TOTAL_PNL USD"
fi

# === BUCKET A DRIFT COMPUTE ===
echo ""
echo "--- BUCKET A DRIFT COMPUTE (NFR-1.1 ≤ 25%) ---"
FINAL_BAL=$(grep -oE "final balance [0-9.\-]+ USD" "$DECODED" 2>/dev/null | tail -1 | grep -oE "[0-9.\-]+" | head -1)
echo "  Initial deposit  : \$${DEPOSIT}.00"
echo "  Baseline Net Profit: \$$BASELINE_NP"
if [ -n "$FINAL_BAL" ]; then
  REWRITE_NP=$(awk -v b="$FINAL_BAL" -v d="$DEPOSIT" 'BEGIN { printf "%.2f", b - d }')
  DRIFT=$(awk -v r="$REWRITE_NP" -v base="$BASELINE_NP" 'BEGIN { printf "%.4f", (r - base) / base * 100 }')
  ABSDRIFT=$(awk -v d="$DRIFT" 'BEGIN { printf "%.4f", (d < 0 ? -d : d) }')
  echo "  Rewrite final bal: \$$FINAL_BAL"
  echo "  Rewrite Net Profit: \$$REWRITE_NP"
  echo "  Drift            : ${DRIFT}%  (|drift| = ${ABSDRIFT}%)"
  PASS=$(awk -v ad="$ABSDRIFT" 'BEGIN { print (ad <= 25 ? "✅ PASS" : "🔴 FAIL") }')
  echo "  NFR-1.1 verdict  : $PASS  (gate ≤ 25%)"
else
  echo "  ⚠️ Final balance NOT FOUND in tester log — test may not have completed cleanly"
fi
