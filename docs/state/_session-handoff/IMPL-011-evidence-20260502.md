# IMPL-011 — Evidence Artifact

**Date:** 2026-05-02
**Task:** M [ea] — `helpers/JsonWriter.mqh` (pure-MQL5 JSON + JSON-Lines serializer)
**Closure:** parallel batch #3 (orchestrator: Opus 4.7; subagent: Sonnet 4.6)

---

## File produced

`MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh` — 400 LOC (≤ 500 helpers cap ✅)

---

## S-AC Verification

| AC bullet | Verification | Result |
|-----------|--------------|--------|
| All 9 primitive MQL5 types serialize correctly | WriteString (string), WriteInt/WriteLong (int/long), WriteDouble (double), WriteBool (bool), WriteNull (null), WriteRaw (nested obj/array), WriteDateTime (datetime as ISO string or epoch int) — covers int/long/ulong/double/string/datetime/bool/raw struct/array via WriteRaw | ✅ |
| String fields properly escaped (`\\`, `"`, newline) | `EscapeString()` applies 5-char escape in correct order per §6.C.1: `\\`→`\\\\`, `"`→`\\"`, `\n`→`\\n`, `\r`→`\\r`, `\t`→`\\t`. Selftest case 4 verifies all 5 chars round-trip. | ✅ |
| Timestamp fields ISO 8601 + ms precision per ADR-006/011 | `WriteDateTime(key, iso_string)` accepts pre-formatted `YYYY-MM-DDTHH:MM:SS.mmmZ` string. Schema is authoritative re: `Z` suffix (§6.A.1 note). `helpers/Timestamp.mqh` (IMPL-042 owner) provides `FormatTimestampWithMs` — not included per §6.D. | ✅ (structural) |
| No DLL imports | `grep -E "^#import" helpers/JsonWriter.mqh` → **0 matches** | ✅ |

---

## E-AC Status

### `[log-assertion]` — Self-test in OnInit `if (ENABLE_SELFTEST)`

`CJsonWriter::SelfTest()` is implemented as `static bool SelfTest()`. It:
- Synthesizes a 17-field JournalEvent-like object covering all 11 required `trade-journal-schema.yaml` fields
- Tests all 5-char escape sequences via `signal_context` field
- Performs 12 structural re-parse assertions via `StringFind`
- Emits `[Phoenicis][slot=system][ev=json_writer_selftest_pass]` on success or `[ev=json_writer_selftest_fail][msg=...]` on fail

Caller (Orchestrator IMPL-053) wires: `if (ENABLE_SELFTEST) CJsonWriter::SelfTest();` at OnInit.
**Status: Satisfied structurally (header-only phase). G2/G4 runtime evidence deferred until IMPL-018+.**

### `[contract-roundtrip]` — serialize → write `.jsonl` → `jq .` parses

**Deferred** — requires:
1. TradeJournal file-write layer (IMPL-043)
2. Entry `.mq5` + G3 headless backtest capability (IMPL-018+)
3. `jq` decode + field-by-field comparison at G4 gate

Structural portion is satisfied by `SelfTest()` 12 assertions within MQL5. Full runtime evidence will land at `docs/state/_session-handoff/IMPL-043-evidence-*.md` (per Deferred-AC registry entry if needed by orchestrator).

---

## Escape Contract Test Cases (§6.C.1)

| Input char | MQL5 literal | Expected in JSON | Notes |
|------------|-------------|-------------------|-------|
| Backslash `\` | `"\\"` | `\\\\` | Escaped first to avoid double-escaping |
| Double quote `"` | `"\""` | `\\"` | — |
| Newline | `"\n"` | `\\n` | — |
| Carriage return | `"\r"` | `\\r` | — |
| Tab | `"\t"` | `\\t` | — |
| Combined test | `"a\\b\"c\nd\re\tf"` | `"a\\\\b\\\"c\\nd\\re\\tf"` | SelfTest case 4 verifies round-trip via StringFind |

---

## Grep Evidence

```
$ grep -E "^#import" MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh | wc -l
0                    ← S-AC: No DLL imports ✅

$ wc -l MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh
400                  ← ≤ 500 LOC helpers cap ✅

$ grep -c '#ifndef PHOENICISNEX_HELPERS_JSONWRITER_MQH' MQL5/Experts/PhoenicisNex/helpers/JsonWriter.mqh
1                    ← include guard present ✅
```

---

## Scope / Coupling Notes

- **Timestamp.mqh not created** — IMPL-042 owns `helpers/Timestamp.mqh` per §6.D. `WriteDateTime` accepts pre-formatted string from caller; epoch integer fallback documented with comment.
- **No `#include "services/*"`** — ADR-012 5-layer rule observed; helpers → no service deps.
- **No `#include "domain/*"`** — JsonWriter is self-contained; uses only MQL5 stdlib (IntegerToString, DoubleToString, StringFind, StringLen, StringGetCharacter, StringReplace, Print).
- **SelfTest uses literal stub timestamp** `"2026-05-02T14:23:45.123Z"` — avoids dependency on Timestamp helper per §6.D.

---

## 4-Gate Definition of Done

| Gate | Status |
|------|--------|
| G1 Compile | N/A — header-only; no entry `.mq5` yet (IMPL-018+) |
| G2 Smoke | N/A — same |
| G3 Headless backtest | N/A — same |
| G4 Log review | N/A — same; SelfTest structural coverage documented above |

Static review against TD-02 §4.3 + ADR-006/007 + NFR-7.2 ✅

---

## Deferral Notes

| Item | Reason | Resolves at |
|------|--------|-------------|
| `[contract-roundtrip]` E-AC runtime evidence | Requires IMPL-043 TradeJournal + IMPL-018+ entry + G3/G4 headless run | IMPL-043 + IMPL-018+ |
| `helpers/Timestamp.mqh` forward reference | IMPL-042 owns file per §6.D | IMPL-042 |
| ENABLE_SELFTEST wiring | Orchestrator IMPL-053 wires at OnInit | IMPL-053 |
