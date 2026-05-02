# ADR-006 — Trade Journal Format = JSON-Lines, Append-Only, Monthly Rotation

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G2, FR-4.1, FR-4.3, NFR-2.2, OQ-3 (✅ resolved 2026-05-01) |

## Context

User pain point #2: *"ไม่ค่อยมีหลักฐานการเทรดให้ไปเรียนรู้จากความผิดพลาด"* (Q4.1). FR-4.1 บังคับ per-event journal record (entry / exit / modify / reject / halt) ที่มี signal context + indicator snapshot + portfolio summary. FR-4.3 บังคับ local-only `MQL5/Files/` (ไม่มี cloud sync). OQ-3 ✅ resolved = **JSON-lines** (BA default ที่ user accept). NFR-2.2 = write latency ≤ 5 ms/tick avg + ≤ 10 ms p95

ต้องตัดสินใจ: file naming + rotation policy + write path + concurrency / atomicity / failure handling

## Options Considered

### Option A — Single growing JSON-lines file (rejected)

`MQL5/Files/PhoenicisNex/journal.jsonl` ที่ append ตลอดอายุ EA

**Rejected:** Live trade ปีละ ~50 events ขนาด ~25 KB/year — ดี; **แต่** Strategy Tester regression run = 231 trades × 5 yr × 2 events/trade × 500 bytes ≈ 1.15 MB ต่อ run. หลายรอบ optimization sweep = หลาย MB; ไม่มี separator → search ลำบาก. หลัก: ต้องการ**แยก backtest run** จาก live + ต้องการ rotation เพื่อให้ user เปิดใน text editor ได้ไม่ค้าง

### Option B — Monthly rotation `journal-YYYYMM.jsonl` + tester namespace (chosen)

```
MQL5/Files/PhoenicisNex/
├── journal/
│   ├── live/
│   │   ├── journal-202601.jsonl
│   │   ├── journal-202602.jsonl
│   │   └── ...
│   └── tester/
│       ├── run-20260502T143012Z.jsonl   # 1 file per Strategy Tester run
│       └── ...
└── state/
    ├── state.json
    └── state.json.tmp                    # atomic write staging
```

- **Live mode:** rotate by broker server month (`MN1` boundary detected via `TimeCurrent()` month change); appends ตลอดเดือน
- **Tester mode:** new file per run, named by tester start time (`MQLInfoInteger(MQL_TESTER) == true` → use tester namespace)
- File size estimate live: 50 trades × 12 months ≈ ปีละ 600 events × 500 bytes ≈ 300 KB/year/12 = **25 KB/month** — เปิด Notepad++ ได้สบาย

### Option C — SQLite via DLL

**Rejected:** ขัด NFR-7.2 (0 DLLs); user MVP signal "ไม่ต้อง install"

### Option D — MT5 GlobalVariable

**Rejected:** GlobalVariable เก็บได้แค่ double + name; structured record + indicator snapshot ใส่ไม่ได้; persist size limit

## Decision

เลือก **Option B — JSON-Lines + monthly rotation + tester namespace separation**

**Concrete contract:**
- Path: `<MT5 data>/MQL5/Files/PhoenicisNex/journal/{live|tester}/{filename}.jsonl`
- File mode: open with `FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ` flags; seek to end; append; flush
- Open strategy: keep file handle open across ticks (open ใน OnInit, close ใน OnDeinit) — avoid `FileOpen/FileClose` overhead per tick (~1-2ms each)
- Rotation check: ที่จุดเริ่ม `TradeJournal::WriteEvent()` — ถ้า month เปลี่ยน → close handle + open new monthly-named file. **No rename** เพราะแต่ละเดือนมี dedicated filename (`journal-YYYYMM.jsonl`) อยู่แล้ว — old file พร้อม archived as-is. (Aligned with TD-04 § 6.3 + SD `04 § 8` per Claim 01.14)
- One JSON object per line ตาม JSON-Lines spec (https://jsonlines.org/)
- Schema: ดู `docs/api-specs/trade-journal-schema.yaml` (lock ใน Phase 1B; TD เพิ่ม field ห้าม remove/rename)

**Sample record:**
```json
{"timestamp":"2026-03-15T14:23:45.123Z","schema_version":1,"mode":"live","event_type":"entry","slot_id":"C","magic":200,"ticket_id":123456789,"symbol":"EURUSD","order_type":"buy","lot":0.05,"price":1.0875,"sl":1.0850,"tp":1.0920,"comment":"C,...","signal_context":"WPRWaveSignal=Yes,CheckIchiBarForC=true","indicator_snapshot":{"ichi_h4_cloudHigh":1.0890,"force_h4_0":12.3,"adx_h4":28.5},"portfolio_summary":{"total_lots":0.32,"total_floating_pl":1234.56,"equity":51234.56,"slot_counts":{"C":1,"G":2}},"triggering_function":"BusinessLogic_C","parent_ticket_id":null}
```

**Latency strategy (NFR-2.2):**
- Synchronous write (no buffer queue) — `FileWrite` + `FileFlush` ทุก event
- Estimated latency: append-only seek-to-end + write 500 bytes + flush ≈ 1-3 ms/event บน Windows local disk + MT5 sandbox
- Burst tolerance: peak event count per tick ≈ 5 (bulk close from Safe-port closes 10 positions ใน 1 tick = 10 events × 3 ms = 30 ms — **exceeds 5 ms target**)
- **Mitigation:** per FR-4.1's NFR-2.2 measurement protocol — ถ้า measured > 5 ms ติดต่อกัน N ครั้งใน window M ticks (TD lock N/M) → emit tagged warning ผ่าน Logger (FR-4.2) + **continue trade flow** (degrade-but-continue per NFR-2.2 overshoot behavior); ไม่ block trade, ไม่ drop record

**Failure handling (per FR-4.1, NFR-3.4) + RPO contract:**

| Scenario | RPO target | Behavior |
|----------|------------|----------|
| Graceful shutdown (`OnDeinit`) | **0 events lost** | Final `TradeJournal.Flush() + Close()` ใน OnDeinit; ทุก buffered event flushed |
| Hard crash mid-write of single event | **≤ 1 event lost** (the one in flight) | Sync write per event = atomic at `FileWriteString + FileFlush`; previous events already on disk |
| Sustained disk failure (disk full / AV lock / permission) | **bounded loss + escalation** | Write fail → record dropped + `journal_metrics.write_failures` counter increment + `Logger::Error()` (ADR-011 throttled). **Escalation policy:** ถ้า `consecutive_write_failures ≥ 10` → `EAState.Halt("journal_write_fail_sustained")` (ADR-010) → Alert + halt entry pass + user inspect |
| Single event > 5 ms (slow disk; not failure) | **0 events lost** | Degrade-warn-but-continue: emit Warn but write completes (eventually) |

**Failure handling implementation:**
- Write fail (disk full / permission) → drop event + increment `journal_metrics.write_failures` ใน state.json + `Logger::Error()` + `Alert()` ถ้า ≥ N ครั้งใน 100 ticks (anti-spam per ADR-011) — ไม่ block trade flow
- Consecutive write failures ≥ 10 → halt EA (escalation per RPO contract above) → preserve G2 by alerting user before more events lost silently
- File handle invalid (disk unmount) → attempt reopen at next event; ถ้า fail → continue + log per event + counter increment
- `journal_metrics.write_failures` persists ใน state.json (atomic per ADR-007) — survives restart; user sees累積 count ใน MT5 GlobalVariable inspector + log monitoring signal (`05 § 7.2`)

## Consequences

**Positive**
- User เปิด `journal-202604.jsonl` ใน VS Code / Notepad++ ได้; jq filter ได้
- Backtest journal แยกชัดเจน — ไม่ปนกับ live
- Schema-versioned — Phase 2 เพิ่ม field ได้ (schema_version bump) โดย old parser ไม่ break (extra field policy: ignore unknown)
- File handle keep-open → low latency burst write

**Negative / trade-off**
- File handle keep-open หลายเดือน — ถ้า MT5 crash = handle leak ที่ OS recover (acceptable)
- Bulk-close burst (Safe-port → 10 events ใน 1 tick) อาจ over budget; mitigated ผ่าน degrade-warn-but-continue + measurement protocol
- Schema lock ที่ YAML = discipline burden (TD ต้อง update YAML ก่อนเพิ่ม field ใน code)
- ไม่มี indexing/search — user ต้อง grep/jq เอง; acceptable เพราะ ~25 KB/month

## Revisit-when

- ถ้า measured write latency p95 > 10 ms ต่อเนื่อง → revisit async write queue (background thread? — แต่ MQL5 ไม่มี thread; ทำผ่าน timer event แทน)
- ถ้า user request search/filter UI → revisit SQLite (Phase 2 — NFR-7.2 อาจอนุญาต DLL)
- ถ้า monthly file > 1 MB (live เพิ่ม slot ใน Phase 2) → revisit rotation = weekly/daily
