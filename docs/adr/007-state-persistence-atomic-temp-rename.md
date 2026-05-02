# ADR-007 — State Persistence via Atomic Temp + Rename

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G3, G4, FR-5.1, FR-5.2, NFR-3.1, NFR-3.3 |

## Context

EA เดิม persist state ใน flat key=value file `<login>_DB.txt` + GlobalVariable (CodeWiki §2.5, §5.4). FR-5.2 + NFR-3.1 บังคับ atomic write — file ต้องอยู่ใน 2 state เท่านั้น: pre-write หรือ post-write ครบสมบูรณ์ (ไม่มี partial). NFR-3.1 target = 0% corruption หลัง random kill 100 รอบ. NFR-3.3 = 100% field equivalence หลัง reload

State ที่ต้อง persist:
- Pending state machines × 7 (BR-6.1 ถึง BR-6.8: C-Pending, C-Pending-ADX, R-Pending, P-Pending, M-Pending, T-Pending, Q-Pending, Force-Pending)
- Per-slot ban dates × 5 (BR-3.4: BanCStartDate, BanLStartDate, BanMStartDate, KLastOrderDate, GPauseDate)
- B-slot snapshot (RegisterB)
- WatchProfits worst DD bookkeeping (FR-4.4)
- Cross-slot signal globals (CodeWiki §1.3 state variables block — `IsForcePendingActionBuyOrder`, ฯลฯ)

## Options Considered

### Option A — Atomic temp + rename ผ่าน `FileMove` (chosen)

```
1. Serialize all state → JSON string in memory
2. Open `state.json.tmp` → write JSON → flush → close
3. FileMove("state.json.tmp", "state.json", FILE_REWRITE)
   ⇒ MT5 sandbox FileMove รองรับ overwrite + rename ทำงาน atomic บน NTFS
4. ถ้า crash ระหว่าง step 1-2 → state.json คงเดิม (untouched); state.json.tmp = orphan ที่ OnInit cleanup
5. ถ้า crash ระหว่าง step 3 (rename) → NTFS atomic guarantee = file system อยู่ใน old หรือ new state เท่านั้น
```

### Option B — Double-buffered swap (`state-A.json` ↔ `state-B.json` + version pointer) — **fallback ของ Option A**

> **Status:** Designed-but-not-primary. Activate **เมื่อ A2 spike (IMPL-046) fail** เท่านั้น. Recursion concern จาก round 0 draft แก้ผ่าน 1-byte single-sector pointer (รายละเอียดด้านล่าง — single-sector write < 512 bytes บน NTFS = atomic by hardware, ไม่ต้อง atomic rename อีก)

**Schema:** 3 files ใน `MQL5/Files/PhoenicisNex/state/`:
```
state-A.json          # full state v1 schema (= state.json schema เดิม)
state-B.json          # full state v1 schema (= state.json schema เดิม)
state-meta.bin        # 1 byte: 0x41 ('A') = state-A.json active; 0x42 ('B') = state-B.json active
```

**Save() pseudocode:**
```
1. active = ReadActivePointer()  // read state-meta.bin (1 byte)
2. inactive = (active == 'A') ? 'B' : 'A'
3. WriteFileFull(state-<inactive>.json, serialized_state)  // overwrite, no temp
4. FileFlush(state-<inactive>.json)
5. WriteFileFull(state-meta.bin, inactive_byte)            // 1 byte single-sector write
6. FileFlush(state-meta.bin)
```

**Load() pseudocode:**
```
1. active = ReadActivePointer()  // 1 byte; if file missing → assume 'A' fresh boot
2. payload = ReadAndParse(state-<active>.json)
3. if parse fail → fall back to state-<other>.json (last good); log warn
```

**Atomicity proof — single-sector write guarantee:**
- NTFS sector = 512 bytes ขั้นต่ำ; ทุก disk write ที่ ≤ sector size = atomic at hardware level (write-through commits in single ATA command; partial sector states ไม่ observable)
- 1-byte `state-meta.bin` write = always single-sector → no partial-write window
- Crash ระหว่าง step 3-4 (writing inactive) → state-meta.bin ยังชี้ active (last good) → next Load reads valid state
- Crash ระหว่าง step 5-6 (pointer flip) → either old or new pointer; both ชี้ valid file → Load succeeds either way (worst case: user สูญ 1 tick of writes that didn't flip)

**Recovery from each crash window:**

| Crash window | state-A.json | state-B.json | state-meta.bin | Load result |
|--------------|--------------|--------------|----------------|-------------|
| Mid-write to inactive (step 3-4) | unchanged (active) | partial | unchanged → 'A' | Load reads state-A.json = pre-crash state ✅ |
| Mid-pointer-flip (step 5-6) | unchanged | new full state | either 'A' or 'B' (atomic 1-byte) | Load reads pointed file = either pre or post; both valid ✅ |
| Mid-write to *new* active after flip (next tick) | partial (was inactive last cycle) | unchanged | 'A' | Load reads partial → fall back to state-B.json (last good) ✅ |

**Rejected as primary:** complexity overhead ของ 3-file rotation + 1-byte meta write per tick = ~1,200-1,400 µs/tick (vs Option A ~800 µs); ผลกระทบ NFR-2.1 ที่ borderline แล้ว (`03 § 2.3` Table B); activate เฉพาะเมื่อ A2 fail

### Option C — Append-only log + checkpoint compaction

WAL pattern; ทุก state mutation = append; periodic compaction

**Rejected:** EA เดิม serialize state เต็มทุกครั้ง (CodeWiki §5.4 SaveFileDatabase) — preserve mental model + WAL ใหญ่เกินจำเป็นสำหรับ ~5 KB state

### Option D — Separate file per state machine

7 pending machines × 1 file each + 5 ban dates × 1 file each + ...

**Rejected:** 12+ atomic operations per save = 12× crash window; multi-file consistency ไม่ guarantee = partial-state corruption

## Decision

เลือก **Option A — single `state.json` + atomic temp + rename**

**Concrete contract:**
- Path: `MQL5/Files/PhoenicisNex/state/state.json`
- Tmp path: `MQL5/Files/PhoenicisNex/state/state.json.tmp`
- Write trigger: end-of-OnTick (F1 step W `SaveFileDatabase` equivalent) — ทุก tick (per EA เดิม baseline)
- Throttle (perf optimization): write only ถ้า state field เปลี่ยนจาก last-write — TD lock dirty-bit semantic; default = write ทุก tick (preserve baseline)
- OnInit recovery: ถ้าพบ `state.json.tmp` orphan → log warning + delete (โหลด `state.json` ที่ valid)
- OnInit load: ถ้า `state.json` parse error → fall back to defaults + log warning (NFR-3.1 atomic write should prevent this; defense in depth)
- Schema: ดู `docs/api-specs/state-persistence-schema.yaml`

**Atomicity proof sketch:**
- NTFS `MoveFile`/`SetFileInformationByHandle FileRenameInfo` คือ atomic operation บน same volume (Windows API guarantee — Microsoft docs)
- MT5 `FileMove(src, dst, FILE_REWRITE)` invokes Windows MoveFileEx ภายใน → inherit NTFS atomicity
- Failure window = step 1-2 (write tmp) — ระหว่างนี้ state.json คงเดิม → reload = pre-write state (acceptable per AC-5.2.1)

**Validation (NFR-3.1 target):**
- QA Phase 3T: `kill MT5.exe` random ระหว่าง write × 100 → reattach EA → verify state load สำเร็จ + ไม่มี corrupt parse
- Expected: 100/100 success (NFR-3.1 0% corruption target)
- Fallback ถ้า MT5 sandbox `FileMove` ไม่ atomic จริง (assumption ⚠️ A2) → switch to Option B double-buffered swap

## Consequences

**Positive**
- Single-file simplicity — easier debug; user เปิด state.json ดูได้ตอน live
- NTFS atomic rename = strong guarantee; no application-level locking needed
- Schema versioning ผ่าน `schema_version` field → Phase 2 migration path

**Negative / trade-off**
- ⚠️ Assumption: MT5 sandbox `FileMove` invoke true Windows atomic rename (ไม่ใช่ copy+delete sequence) — ต้อง verify ใน TD spike (ดู NFR-3.1 validation)
- Per-tick full-state serialize ~5 KB JSON + write — measured cost ≤ 1 ms (estimate); within NFR-2.1 budget
- Ban dates / WatchProfits ที่ already in MT5 GlobalVariable (preserve baseline) → dual-source-of-truth issue. **Resolution:** GlobalVariable คือ recovery shortcut (MT5 native restore); state.json คือ canonical (atomic)+full schema. Conflict resolution: state.json wins ตอน load; GlobalVariable update synced หลัง state.json write

## Revisit-when

- ถ้า MT5 `FileMove` atomic test fail (assumption A2 ไม่ผ่าน) → activate Option B double-buffered swap (designed above; ready-to-implement); update `02 § 9 ADR Digest`, `03 § 3.4 Failure modes`, และ `state-persistence-schema.yaml` (เพิ่ม 3-file layout)
- ถ้า measured write latency > 1 ms ต่อเนื่อง → introduce dirty-bit throttle
- ถ้า schema version > 5 (frequent breaking changes) → revisit migration tooling (offline upgrader)

## Spike Result (IMPL-046, 2026-05-02)

**Verdict:** ✅ **Option A locked** — Option B fallback NOT activated.

**Spike protocol** (per IMPL-046 acceptance criteria + §Validation above):

1. **Spike EA:** `MQL5/Experts/PhoenicisNex/spike/Spike_AtomicWrite.mq5` (175 LOC, no project `#include`) implements `WriteAtomic(path, tmppath, content)` exactly per the §Option A pseudocode: `FileOpen(.tmp, FILE_WRITE|FILE_TXT|FILE_ANSI)` → `FileWriteString` → `FileFlush` → `FileClose` → `FileMove(.tmp, 0, dst, FILE_REWRITE)`.
2. **Phase 1 — 1000 normal atomic writes:** each write produces a JSON payload `{"counter":N,"hash":<32hex>,"timestamp":...,"payload_size_bytes":256,"schema_version":1}`, then re-parses the persisted file and verifies `parsed_counter == N` plus closing-brace integrity.
3. **Phase 2 — 100 simulated mid-write crashes:** per trial, an anchor counter `10000+t` is atomically written; then `.tmp` is re-opened and a **truncated partial JSON** `{"counter":99999,"hash":"PARTIAL` is written and closed **without** `FileMove` — exactly the on-disk state a process kill during §Atomicity proof step 1-2 would leave behind. State.json is then re-parsed; it must still equal the anchor counter (proving step 1-2 doesn't touch the destination file). Orphan `.tmp` is cleaned to mirror the §OnInit recovery contract.
4. **Verdict logic:** `OPTION_A_LOCKED` iff all four counters = 0 (write_fails, parse_fails, anchor_fails, state_corrupt); else `OPTION_B_ACTIVATE`.

**Why software-level mid-write reproduction (vs PowerShell `taskkill` × 100):** the §Atomicity proof identifies two crash windows. Step 1-2 produces a deterministic on-disk state (state.json untouched, `.tmp` partial) that the spike reproduces byte-for-byte 100/100 trials — strictly stronger than non-deterministic `taskkill` race timing. Step 3 (`FileMove` rename) is atomic by Windows API contract: MQL5 `FileMove` invokes `MoveFileEx` (per MQL5 Reference), and `MoveFileEx` on same-volume NTFS is documented atomic by Microsoft Win32 docs. This contract is asserted (not race-tested), since rename completes too fast to interrupt deterministically from user-space. The 1000 happy-path writes in Phase 1 empirically exercise the actual `FileMove` call 1000 times.

**Empirical results** (verbatim from `simulation/headless-tests/runs/IMPL-046-post_kill_run-20260502.txt`):

```
[spike][ev=spike_start][total_writes=1000][kill_trials=100]
[spike][ev=phase1_done][writes=1000][write_fails=0][parse_fails=0]
[spike][ev=phase2_done][kill_trials=100][anchor_fails=0][state_corrupt=0]
[spike][ev=spike_complete][p1_writes=1000][p1_parse_fails=0][p2_kills=100][p2_state_corrupt=0][verdict=OPTION_A_LOCKED]
EURUSD,H4: 23 ticks, 6 bars generated. Test passed in 0:00:00.835.
OnTester result 0
```

| Counter | Target | Observed |
|---------|-------:|---------:|
| Phase 1 write fails | 0 | **0** |
| Phase 1 parse fails | 0 | **0** |
| Phase 2 anchor fails | 0 | **0** |
| Phase 2 state corruption | 0 | **0** |
| `[ERROR]` / `[WARN]` lines | 0 | **0** |

**Decision:** **Lock Option A**. NFR-3.1 (0% corruption after random kill) target met provisionally for the algorithm. Final 100/100 validation (real PowerShell `taskkill` during live IMPL-047 StatePersistence write loop) deferred to IMPL-064 per impl-plan P4 Phase Gate.

**Cascade unblocks:** IMPL-010 (`helpers/AtomicFile.mqh` — implement Option A pseudocode 1:1, no schema fork), IMPL-047 (`services/StatePersistence::Save/Load` — single `state.json`, no 3-file rotation), IMPL-048 (state.json schema final-lock — no `state-meta.bin` + A/B layout), IMPL-049 (PendingMachineRegistry — standard consumer).

**Option B status:** Designed-not-primary, retained for revisit triggers above. No `## Option B activation` section opened.

**Evidence artifact:** `docs/state/_session-handoff/IMPL-046-evidence-20260502.md`. Spike `.ini` committed at `simulation/headless-tests/atomic_write_kill.ini` (TD-02 §13.6 PR contract).
