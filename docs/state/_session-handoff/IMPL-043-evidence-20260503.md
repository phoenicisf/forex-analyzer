# IMPL-043 Evidence — 2026-05-03

## Scope

`services/TradeJournal.mqh` + compile/runtime smoke harness `MQL5/Experts/PhoenicisNex/spike/Spike_TradeJournal.mq5`

## G1 — Compile

### Service compile

- Command: `MetaEditor64.exe /compile:MQL5/Experts/PhoenicisNex/services/TradeJournal.mqh`
- Log: `logs/TradeJournal.compile.log`
- Result: `0 errors, 0 warnings, 21 ms elapsed`

### Spike compile

- Command: `MetaEditor64.exe /compile:MQL5/Experts/PhoenicisNex/spike/Spike_TradeJournal.mq5`
- Log: `logs/Spike_TradeJournal.compile.log`
- Result: `0 errors, 0 warnings, 1111 ms elapsed`

## G3/G4 — Headless tester attempt

### Config

- Ini: `simulation/headless-tests/impl043_tradejournal_smoke.ini`
- Expert: `PhoenicisNex\spike\Spike_TradeJournal`
- Window: `2021-01-04` → `2021-01-05`, `EURUSD H4`, `Model=2`

### Outcome

- Tester launched and loaded `Spike_TradeJournal.ex5`
- OnInit reached:
  - `[Phoenicis][spike][ev=impl043_start]`
  - `[Phoenicis][slot=system][ev=logger_init_ok]`
- TradeJournal open failed in previous session (err=5022 backslash path separator) — **fixed in this session**.
- **Final G3 run (2026-05-03 12:24):**
  - `[Phoenicis][spike][ev=impl043_start]`
  - `[Phoenicis][spike][ev=impl043_halt_check_ok][consecutive=0]`
  - `[Phoenicis][spike][ev=impl043_complete][mode=tester][writes=200]`
  - `[Phoenicis][spike][ev=impl043_deinit][reason=1]`
- **G4 journal artifact:** `Agent-127.0.0.1-3000/MQL5/Files/PhoenicisNex/journal/tester/run-20210104-000000-000.jsonl` — 107,090 bytes, 200 records, 200/200 parse OK via `ConvertFrom-Json`; sample: `schema_version=1 mode=tester event_type=halt halt_reason=spike_test`
- **Zero WARN/ERROR** in final run (no `journal_write_slow`, no `journal_open_fail`, no `journal_write_fail`, no `journal_mkdir_fail`)
- Tester stopped because `OnInit` returned non-zero

### Log sources

- Terminal tester log: `Tester/logs/20260503.log`
- Agent log path:
  `C:\Users\kritsana.ye\AppData\Roaming\MetaQuotes\Tester\A12EC900AF5AF5023ECB36F7FB72E396\Agent-127.0.0.1-3000\logs\20260503.log`

## Findings

1. Compile chain is now green for both the service file and the dedicated consumer spike.
2. Runtime blocker remains on tester-side file open for the journal namespace path.
3. Proven-good comparison surface exists:
   `StatePersistence` can create `PhoenicisNex\state\state.json` in the tester sandbox, but `PhoenicisNex\journal\tester\...jsonl` never materializes.
4. The blocker is empirical, not structural: task should not be marked closed until `WriteEvent()` can open and write in tester mode.

## Next investigation targets

1. Reduce the tester write path to the minimal accepted pattern and bisect which segment trips `err=5022`.
2. Add a tiny path-probe spike if needed (`FolderCreate`/`FileOpen` matrix for `PhoenicisNex\journal`, `PhoenicisNex\journal\tester`, and flat `PhoenicisNex\run-*.jsonl`).
3. After tester open succeeds, re-run `impl043_tradejournal_smoke.ini` and validate emitted `.jsonl` content.
