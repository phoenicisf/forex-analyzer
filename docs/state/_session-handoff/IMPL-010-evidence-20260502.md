# IMPL-010 Evidence — AtomicFile helper (Option A 1:1 per ADR-007 §Spike Result)

| Field | Value |
|---|---|
| Task | IMPL-010 [S] [ea] — helpers/AtomicFile (FileMove temp+rename wrapper) |
| Closed | 2026-05-02 |
| Commit | 5f8b769 `[feat:ea] IMPL-010 — AtomicFile helper Option A (ADR-007 §Decision 1:1)` |
| Phase | P1 — Foundation |
| Closure mode | Parallel batch via `/impl-task parallel` (orchestrator: Opus 4.7; subagent: Sonnet 4.6) |
| Shared-context | `docs/state/_parallel-context/impl-task-parallel-20260502-2326.md` |

## File created

- `MQL5/Experts/PhoenicisNex/helpers/AtomicFile.mqh` (NEW, 164 LOC)
  - `class CAtomicFile` — stateless utility per TD-02 §4 + §7.3 row 3 (no Init, no member fields)
  - `WriteAtomic_TempRename(string path, string content, CLogger *logger) → bool` — Option A primary, ADR-007 §Decision pseudocode 1:1
  - `CleanupOrphanTmp(string path, CLogger *logger) → void` — ADR-007 §Recovery (boot-time orphan cleanup)
  - `WriteAtomic(string path, string content, CLogger *logger) → bool` — dispatcher (always delegates to TempRename per IMPL-046 OPTION_A_LOCKED verdict)
  - Option B (`WriteAtomic_DoubleBuffered` / `ReadActiveBuffered`) **NOT implemented** — designed-not-primary, gated behind ADR-007 §Revisit-when triggers

## ADR-007 §Decision pseudocode mapping (1:1)

| Spec step | Implementation |
|---|---|
| 1. Serialize state → JSON (caller responsibility) | n/a — caller owns |
| 2. Open `<path>.tmp` → write → flush → close | `FileOpen(tmp, FILE_WRITE\|FILE_TXT\|FILE_ANSI)` → `FileWriteString` (verify written = StringLen) → `FileFlush` → `FileClose` |
| 3. `FileMove(tmp, dst, FILE_REWRITE)` atomic rename | `FileMove(tmp, 0, dst, FILE_REWRITE)` — Win32 MoveFileEx on NTFS same-volume guarantees atomicity per ADR-007 + Microsoft docs |
| 4. Crash mid step 1-2 → state.json untouched + orphan tmp cleanup at boot | `CleanupOrphanTmp` deletes orphan; non-fatal on failure (Logger.Warn) |
| 5. Crash mid step 3 → NTFS atomic rename | inherited from FileMove contract; not exercised programmatically here |

## Static checks (G1-G4 deferred — header-only .mqh per precedent)

| Check | Command | Result |
|---|---|---|
| Class declaration | `grep -E '^class CAtomicFile' helpers/AtomicFile.mqh` | 1 line ✅ |
| No #import | `grep -c '#import' helpers/AtomicFile.mqh` | 1 match — comment only ✅ (line 16: `// ห้าม #import`) |
| Include guard | `grep -E '^#ifndef PHOENICISNEX_HELPERS_ATOMICFILE_MQH' …` | 1 line ✅ |
| 3 methods present | `grep -E 'WriteAtomic_TempRename\|CleanupOrphanTmp\|WriteAtomic\(' …` | 9 matches (decl + impl + dispatcher delegate) ✅ |
| Option B NOT impl | `grep -c 'WriteAtomic_DoubleBuffered\|ReadActiveBuffered' …` | 1 match — comment only ✅ (forward-compat note, no impl) |
| Sandbox-relative | `grep -E 'TerminalInfoString\(TERMINAL_DATA_PATH\)' …` | 1 match — comment only ✅ (anti-pattern documented, not used) |
| LOC budget | `wc -l helpers/AtomicFile.mqh` | 164 ≤ 300 helper budget ✅ |

## S-AC closure

- [x] `WriteAtomic(string path, string content)` returns bool (false ถ้า any step fail) — dispatcher delegates to TempRename; returns false on FileOpen=INVALID_HANDLE / FileWriteString short / FileMove fail
- [x] `CleanupOrphanTmp(string path, CLogger*)` deletes orphan `<path>.tmp` files from prior failed write — `FileIsExist + FileDelete` with Logger.Warn on success / Logger.Error on fail-to-delete
- [x] No exception path; degrade-but-continue on failure (return false + Logger Error) — verified by grep — every error path emits Logger.Error then returns false; best-effort cleanup of partial tmp before return

## E-AC deferral (per Empirical Closure Discipline — cite blocking task)

- [ ] Smoke: write `state.json` 100 times → `cat state.json | jq .` parses cleanly each iteration `[file-blob-check]` — **deferred to IMPL-047** (StatePersistence consumer wires AtomicFile + serializes real state)
- [ ] Manual interrupt (SIGTERM mid-write) ผ่าน Strategy Tester run + check no half-written `state.json` after restart `[boot-cold]` — **deferred to IMPL-047 + IMPL-018+** (Strategy Tester run prerequisite); IMPL-046 spike already empirically validated the algorithm with 100/100 simulated mid-write reproductions (verdict OPTION_A_LOCKED)

Closure citation matches IMPL-005/007/015/042 precedent (specific blocking task ID, not "deferred to operator-runtime" — Code Review Dim #11 compliant).

## Risk note

- Option B body intentionally omitted per ADR-007 §Spike Result + shared-context §6.C.1 option (a). Revival requires `## Revisit-when` triggers in ADR-007 + StatePersistence + state-persistence-schema.yaml v2 fork (1-2 day rework per ADR-007 §Revisit-when).
- Stateless contract preserved — caller (StatePersistence at IMPL-047) owns Logger lifecycle; AtomicFile pass-through pattern matches `helpers/CommentParser.mqh` precedent.

## Suggested next task

IMPL-047 (P2) blocked until P1 Phase Gate close. Within P1: IMPL-006 + IMPL-016 closed in same batch → P1 reaches 17/17 → P1 Phase Gate nominate-able.
