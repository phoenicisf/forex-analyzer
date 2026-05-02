# IMPL-001 — Evidence Artifact

**Task:** IMPL-001 [XS] [ea] — Folder structure scaffold + bootstrap_smoke.ini stub
**Date:** 2026-05-02
**Engineer:** Kritsana (via Claude Code · andm-impl-engineer)
**Phase:** P1 — Foundation

## E-AC #1 — `[file-blob-check]` directory count

Command:
```bash
find MQL5/Experts/PhoenicisNex -type d | wc -l
```

Output (verbatim):
```
8
```

Listing (`find MQL5/Experts/PhoenicisNex -type d`):
```
MQL5/Experts/PhoenicisNex
MQL5/Experts/PhoenicisNex/core
MQL5/Experts/PhoenicisNex/domain
MQL5/Experts/PhoenicisNex/helpers
MQL5/Experts/PhoenicisNex/inputs
MQL5/Experts/PhoenicisNex/libs
MQL5/Experts/PhoenicisNex/services
MQL5/Experts/PhoenicisNex/slots
```

**Result:** 8 ≥ 7 → ✅ pass (per AC threshold; root + 7 layered subdirs per ADR-012 + TD-02 §2).

## E-AC #2 — `[file-blob-check]` ini key/value match

Command:
```bash
grep -E "^(Symbol|Period|Visual|ShutdownTerminal)=" simulation/headless-tests/bootstrap_smoke.ini
```

Output (verbatim):
```
Symbol=EURUSD
Period=H4
ShutdownTerminal=1
Visual=0
```

Expected per TD-02 §13.3 + `.claude/rules/testing.md` G3:
- `Symbol=EURUSD` ✅
- `Period=H4` ✅
- `Visual=0` ✅ (CRITICAL — headless)
- `ShutdownTerminal=1` ✅ (CRITICAL — auto-exit)

Plus full `[Tester]` block contains `Expert=PhoenicisNex\PhoenicisNex` placeholder (S-AC #2 satisfied) — placeholder targets `MQL5/Experts/PhoenicisNex/PhoenicisNex.mq5` which lands in IMPL-018+ (entry-point .mq5 scaffold).

**Result:** ✅ pass.

## S-AC summary

| AC | Result | Notes |
|----|--------|-------|
| 7 layered folders exist | ✅ | core/, slots/, services/, domain/, helpers/, inputs/, libs/ all present |
| `bootstrap_smoke.ini` has `[Tester]` + `Visual=0` + `ShutdownTerminal=1` + `Expert=PhoenicisNex\PhoenicisNex` | ✅ | full block at `simulation/headless-tests/bootstrap_smoke.ini` |
| `.gitkeep` files committed for empty folders | ✅ | one `.gitkeep` per of the 7 layered subdirs |

## 4-Gate Definition of Done — applicability

IMPL-001 has zero MQL5 source — gates G1 (compile) / G2 (smoke) / G3 (headless backtest) / G4 (log review) **not applicable yet** (no `.mq5`/`.mqh` to compile; first compilable artifact lands at IMPL-002 + IMPL-018). Bootstrap-smoke ini scaffold is consumed by G3 starting IMPL-018+.

## Closure verdict

All 3 S-AC + 2 E-AC pass. Ready for Phase 3 commit + state propagation.
