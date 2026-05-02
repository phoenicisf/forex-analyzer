# PhoenicisNex Testing Rules

> Methodology source: `.agents/skills/andm-impl-engineer/SKILL.md § Empirical Closure Discipline`
> Stack source: TD-02 §13 (4-gate Definition of Done) + 3 MT5 SKILLs (`mt5-headless-backtest`, `mql-developer`, `mt5-log-reader`)

## 4-Gate Definition of Done (every IMPL-NNN task)

| Gate | Action | Tool / SKILL | Pass criteria |
|------|--------|--------------|---------------|
| **G1 Compile** | `MetaEditor64.exe /compile:<file.mq5> /log` | `mql-developer` (syntax) + `mt5-log-reader` (parse `.compile.log`) | `Result: 0 errors, 0 warnings` (exit code unreliable per `mt5-log-reader § Wine`) |
| **G2 Smoke** | Attach EA on EURUSD H4 chart → check Experts first 5 ticks | `mt5-log-reader` | OnInit → INIT_SUCCEEDED + `[system][ev=init_ok]` + 0 `[ERROR]` |
| **G3 Headless backtest** | `terminal64.exe /config:simulation/headless-tests/<task>.ini` (`Visual=0` + `ShutdownTerminal=1`) | `mt5-headless-backtest` (10-step flow) | EA runs full window + ≥1 milestone count for key event (entry/exit/journal write) |
| **G4 Log review** | iconv UTF-16LE→UTF-8 → grep + jq | `mt5-log-reader` (Experts log) + jq (journal) | 0 unexpected `[ERROR]`; sample 5 journal records validate vs `trade-journal-schema.yaml` |

> **ห้าม** silent skip gate (e.g., editing log message to "ผ่าน") = ขัด TD-02 §13.5 audit contract.

## Concrete Commands

### G1 — Compile (every task)

```bash
ORIGIN=$(cat origin.txt | tr -d '\r')
METAEDITOR=$(echo "$ORIGIN" | sed 's|^\([A-Z]\):|/\L\1|; s|\\|/|g')/MetaEditor64.exe
"$METAEDITOR" /compile:"MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5" /log
sleep 1
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/PhoenicisNex/PhoenicisNex.compile.log" 2>/dev/null \
  | grep -E "Result:|error" | tail -5
# Pass: "Result: 0 errors, 0 warnings, NNNN ms elapsed"
```

### G3 — Headless backtest

```bash
# Reference: full flow in mt5-headless-backtest SKILL § Steps 1-10
bash .agents/skills/mt5-headless-backtest/scripts/run_headless_backtest.sh \
     simulation/headless-tests/<task>.ini /tmp/run.txt
```

Standard `[Tester]` block per TD-02 §13.3:

```ini
[Tester]
Expert=PhoenicisNex\PhoenicisNex
Symbol=EURUSD
Period=H4
Model=4               ; every tick based on real ticks (NFR-2.3 fidelity)
Optimization=0
Deposit=1000          ; per C-6
Leverage=500          ; per C-7
ShutdownTerminal=1    ; CRITICAL — auto-exit after backtest
Visual=0              ; CRITICAL — headless
```

### G4 — Log review (Tester log + journal)

```bash
# Tester log decode (UTF-16LE → UTF-8) and grep
TODAY=$(date +"%Y%m%d")
TESTER_LOG="$DATA_DIR/../../Tester/$TERMINAL_ID/Agent-127.0.0.1-3000/logs/$TODAY.log"
iconv -f UTF-16LE -t UTF-8 "$TESTER_LOG" \
  | grep -nE "\[Phoenicis\]|\[ERROR\]|\[WARN\]|init_ok|halt|missing_override"

# Journal record sanity check (Git Bash + jq)
head -5 MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl | jq .
jq -r .event_type MQL5/Files/PhoenicisNex/journal/tester/run-*.jsonl | sort | uniq -c

# Per-slot trade count (NFR-1.6 baseline check)
jq -r 'select(.event_type=="entry") | .slot_id' run-*.jsonl | sort | uniq -c

# G4 BI SL audit (ADR-009 verification)
jq 'select(.slot_id=="BI" and .event_type=="entry") | {ticket_id, sl, signal_context, parent_ticket_id}' run-*.jsonl
```

PowerShell-native fallback (no jq/Git Bash) — see TD-02 §13.4 for full equivalent commands.

## Per-Service-Kind Prove-It Evidence Table

> Materialized from `.claude/stack.json` services + 3 MT5 SKILLs. The PhoenicisNex stack has **one service kind** (`ea` — MQL5/MT5 intra-process EA). Each abstract evidence-kind maps to concrete MT5 toolchain commands; n/a kinds explicitly marked.

| Evidence-kind | `ea` service (MQL5 + MT5 platform) | Source |
|---------------|------------------------------------|--------|
| **`[probe]`** | MetaEditor compile + EA attach + grep `[ev=init_ok]` in Experts log | TD-02 §13.2 + `mt5-log-reader` |
| **`[gui-capture]`** | n/a — no custom UI; MT5 native UI = input dialog + Experts log + Alert popup (TD-03 §2) | TD-03 §1 N/A justification |
| **`[log-assertion]`** | iconv UTF-16LE → UTF-8 Tester log + grep stable Print prefix `[slot=<X>][ev=<E>]` (e.g., `grep -c "\[Phoenicis\] OnInit OK"`) | `mt5-log-reader` + `mt5-headless-backtest § Step 8` |
| **`[queue-inspect]`** | n/a — no queue / messaging in Phase 1 | NFR-7.2 + BA `01 § 6` |
| **`[db-inspect]`** | `cat MQL5/Files/PhoenicisNex/state/state.json \| jq .` + jq filter on `journal/*.jsonl` | TD-02 §13.4 + state-persistence-schema.yaml |
| **`[file-blob-check]`** | `state.json` schema validation (vs `state-persistence-schema.yaml`) + journal record sample (vs `trade-journal-schema.yaml`) — `jq -e` schema check | TD-04 §3 + api-specs |
| **`[boot-cold]`** | Delete `state.json` + restart EA → assert `state_corrupt_starting_fresh` log + state restored to defaults | NFR-3.1 + TD-02 §12.4 |
| **`[contract-roundtrip]`** | journal record `WriteFileAtomic` → `jq` decode → re-construct → byte-equal compare | ADR-006 + trade-journal-schema.yaml |
| **`[config-audit]`** | n/a — Phase 1 has no env var / secret / API key consumer (local-only sandbox); promotes if Phase 2 cloud journal added | BA `01 § 6.2 Won't Permanent` |

## Failure Escalation (per TD-02 §13.5)

1. ห้าม mark task complete if any G1-G4 fails
2. Engineer logs issue in task notes + log snippet (≤ 30 lines)
3. Compile error → fix locally + rerun G1
4. Test/runtime error → check vs ADR (decision drift?)
5. Behavioral drift > expected → escalate via `/backtrack sd` (ADR change) or `/amend td` (skeleton change)
6. ห้าม silent skip gate — audit contract violation
