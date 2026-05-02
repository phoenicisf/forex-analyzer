# `[Tester]` section reference

Full field map for the .ini consumed by `terminal64.exe /config:`. Only the `[Tester]` section is needed for headless backtests; other sections (`[Common]`, `[Charts]`, etc.) are optional.

## Required fields

| Field | Type | Example | Notes |
|---|---|---|---|
| `Expert` | path | `Hydra\Hydra` | Relative to `{Terminal}/MQL5/Experts/`; **backslash on Windows**, no `.ex5` extension. The `.ex5` must already exist (compile separately). |
| `Symbol` | string | `EURUSD` | Must match a symbol in MarketWatch / available history. Broker-suffixed names (e.g. `EURUSD.r`) work too. |
| `Period` | enum | `H1` | One of `M1` `M5` `M15` `M30` `H1` `H4` `D1` `W1` `MN1`. |
| `FromDate` | date | `2026.03.23` | YYYY.MM.DD with **dots**, not dashes. |
| `ToDate` | date | `2026.04.23` | Inclusive end date. |
| `Deposit` | int | `1000` | Starting equity. |
| `Currency` | string | `USD` | Account currency. Affects lot-sizing math, P&L conversion. |

## Critical-for-headless flags

| Field | Value | Why |
|---|---|---|
| `ShutdownTerminal` | `1` | **Auto-exits the terminal when the backtest finishes.** Without this, the process stays alive forever and you have to `kill` it manually. Always set to `1` for headless. |
| `Visual` | `0` | **Suppresses the chart window.** Without this, MT5 opens its GUI and may steal focus. Set to `1` only when you want to watch the run interactively. |
| `Optimization` | `0` | `0` = single backtest. `1`/`2` = parameter sweep — much slower, completely different output schema, almost never what you want for a headless smoke. |

## Tick-fidelity model

| `Model` | Meaning | Wall-clock cost |
|---|---|---|
| `0` | Every tick (interpolated from M1 OHLC) | Medium |
| `1` | 1-minute OHLC | Fastest, lowest fidelity |
| `2` | Open prices only | Even faster, mostly useless for spread-sensitive EAs |
| `4` | **Every tick based on real ticks** | Slowest, highest fidelity — what you want for production-realism HD-01d-style runs |

Use `4` unless you know you don't need real-tick fidelity.

## Forward / execution / leverage

| Field | Default | Notes |
|---|---|---|
| `ForwardMode` | `0` | `0` = no forward window. `1` = enable forward test (split window in half). Most smoke tests use `0`. |
| `ExecutionMode` | `0` | `0` = "Normal" execution (broker-default slippage model). `1` = "Random delays" — useful for stress-testing latency-sensitive EAs. |
| `Leverage` | `100` | Account leverage. Affects margin checks, not P&L. |
| `ProfitInPips` | `0` | `0` = report P&L in deposit currency; `1` = report in pips. Affects only the GUI summary, not log content. |

## Optional account override

```ini
Login=12345678
Password=...
Server=FBS-Demo
```

Skip these to use the last-active account from the GUI session. Only override when you specifically need a different login (rare for smoke tests).

## Working example (from this codebase)

`simulation/headless-tests/hd01d_tester.ini`:

```ini
[Tester]
Expert=Hydra\Hydra
Symbol=EURUSD
Period=H1
Optimization=0
Model=4
FromDate=2026.03.23
ToDate=2026.04.23
ForwardMode=0
Deposit=1000
Currency=USD
ProfitInPips=0
Leverage=100
ExecutionMode=0
ShutdownTerminal=1
Visual=0
```

This config produced 71 packs end-to-end on EURUSD H1 1-month real ticks in ~3 minutes wall-clock (commit `0b3f755`).

## Field validation gotchas

- **Date format**: Use dots (`2026.03.23`), not dashes (`2026-03-23`) or slashes. MT5 silently accepts the wrong separator and runs an empty backtest.
- **Date range vs available history**: If the symbol/period doesn't have ticks for the full window, MT5 silently truncates to whatever is available. Check `Bars(_Symbol, _Period)` if results look short.
- **Symbol naming**: Some brokers append suffixes (`.r`, `.x`, `.i`). The `Symbol=` value must match exactly what MarketWatch shows; the EA's `_Symbol` constant inside OnTick will reflect the same.
- **Period enum is case-sensitive on some MT5 builds**: `H1` works; `h1` may not. Stick to uppercase.
- **`Expert=` path resolution**: relative to `MQL5/Experts/`. To run a Script instead: `Expert=Scripts\Foo` resolves to `MQL5/Scripts/Foo.ex5`. (Untested in this codebase as of 2026-04-28.)

## What a clean run produces in the log

The agent log (`{Tester}/Agent-127.0.0.1-3000/logs/YYYYMMDD.log`) contains, in order:

1. Startup banner + symbol/period/date confirmation
2. `EA loading` + `OnInit` invocation (your EA's startup Print()s land here)
3. Tick-by-tick processing (your EA's per-tick Print()s)
4. `final balance N USD` summary line
5. `EURUSD,H1: NNN ticks, NNN bars generated. Test passed in MM:SS.SSS`
6. `OnDeinit` invocation (shutdown Print()s)
7. `prepare for shutdown` + `shutdown finished`

Step 7 only appears when `ShutdownTerminal=1`. Its presence is a useful sentinel that your run actually terminated cleanly rather than hanging.
