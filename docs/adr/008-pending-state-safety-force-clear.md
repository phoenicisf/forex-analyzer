# ADR-008 — M / T / Q-Pending Safety Force-Clear Policy (resolves OQ-A1/A2/A3)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Resolves** | OQ-A1 (M-Pending), OQ-A2 (T-Pending), OQ-A3 (Q-Pending) — anchored ที่ `01 § 10.1`, BR-6.5/6/7 |
| **Goal trace** | G3, G4, FR-5.1, NFR-5.1 |

## Context

EA เดิม **ไม่มี hard wallclock/bar timeout** สำหรับ M-Pending (BR-6.5), T-Pending (BR-6.6), Q-Pending (BR-6.7) — invalidation มี 2 รูปแบบเท่านั้น:
- M-Pending: trigger condition met หรือ M signal flip overwrites snapshot
- T-Pending: `BusinessLogic_PendingT` confirmation tick
- Q-Pending: code-specific resolution per `QPendingCode` value (0/1/2/3)

BA flag risk pattern: ถ้า price stuck ใน range + signal ไม่ flip → state อาจค้าง PENDING ตลอด session → state file โต + GlobalVariable namespace pollution + slot ไม่ fire signal ใหม่ขณะ pending. BA route OQ-A1/A2/A3 ให้ Architect resolve เพราะเป็น HOW (state cleaner design)

Trade-off ที่ต้องชั่ง:
- **Preserve baseline strict** (no force-clear) → behavioral parity 100% แต่ risk state pollution
- **Add safety force-clear** → bound state file growth แต่อาจ trigger early invalidation ที่ EA เดิมไม่มี → bucket A drift

## Options Considered

### Option A — No force-clear (preserve baseline strict)

**Pros:** 0% drift จาก baseline; matches EA เดิม semantic ตรง

**Cons:** State file unbounded growth ใน edge case; long-stuck pending = invisible bug

### Option B — Hard force-clear ทุก machine (uniform 100 H4 bar timeout)

**Pros:** Simple uniform policy

**Cons:** ไม่สอดคล้องกับ semantic ของแต่ละ machine; Q-Pending มี 4 sub-codes ที่ resolve timing ต่างกัน → uniform timeout อาจตัด valid transition

### Option C — Per-machine adaptive force-clear (chosen)

ใช้ timeout ที่อิง longest realistic resolution ของแต่ละ machine + 2× safety margin:

| Machine | Hard force-clear | Rationale |
|---------|------------------|-----------|
| **M-Pending** (BR-6.5) | **150 H4 bars** (~25 trading days) | engineering estimate — M signal flip คือ baseline invalidation path (resolves "fast" cases); 150 bars = generous headroom เพื่อไม่ตัด valid trigger window. ⚠️ Claimed "≤ 30 bars typical resolve" ของ baseline ยังไม่ extracted measurement — `IMPL-068` (force-clear validation in QA Phase 3T) จะวัด actual `force_clear_count` หลัง regression run |
| **T-Pending** (BR-6.6) | **80 H4 bars** (~13 trading days) | engineering estimate — T confirmation tick = baseline path; 80 bars เลือก lower กว่า M เพราะ T pattern (ตาม CodeWiki §2.5 narrative) สั้นกว่า. ⚠️ Numerical "≤ 20 bars typical" ยังไม่ extracted; IMPL-068 จะ confirm |
| **Q-Pending** (BR-6.7) | **100 H4 bars** (~17 trading days) | engineering estimate — Q มี 4 sub-codes (`QPendingCode` 0/1/2/3) ที่ resolve timing ต่างกันตาม CodeWiki §2.5; 100 bars = compromise threshold ครอบคลุม slow cases. ⚠️ "code 3 ช้าสุด" assertion ยังไม่ verify; IMPL-068 จะวัด per-code force_clear pattern |

Force-clear behavior:
- Transition to IDLE
- Emit journal entry `event_type=pending_force_clear` พร้อม `slot_id`, `pending_age_bars`, `pending_payload` (สำหรับ retrospective)
- Emit `Logger::Warn()` tagged log + emit `Alert()` ครั้งแรกของ session (anti-spam: ≤ 1 Alert per slot per session)
- เพิ่ม per-slot counter `force_clear_count` ใน WatchProfits (FR-4.4) — observability metric

## Decision

เลือก **Option C — per-machine adaptive force-clear**

**Concrete numbers locked:**
- M-Pending: 150 H4 bars
- T-Pending: 80 H4 bars
- Q-Pending: 100 H4 bars

**Why these numbers — engineering estimate, not measured derivation:**
- ⚠️ **Numbers ที่เลือก = SD engineering judgment** ที่ยังไม่ผ่าน baseline measurement. Round-0 draft อ้าง "max position holding time = 121 H4 bars" จาก `ReportTester-25045474.html` — แต่ position holding time ≠ pending state duration (BR-6.x logic แยก machine PENDING duration จาก position holding); การใช้ holding time เป็น proxy = false comparison → drop จาก rationale
- **Acknowledged as risk A6** ใน `03 § 7` — IMPL-068 (QA Phase 3T) ต้อง measure actual `pending_age_bars` distribution per machine จาก 5-yr regression run; ถ้า max bars baseline > 70% ของ threshold → tune up + re-validate
- Configurable ผ่าน input `InpForceClearM_Bars` / `InpForceClearT_Bars` / `InpForceClearQ_Bars` (default = ค่าด้านบน) → user / QA ปรับได้ใน Strategy Tester optimization sweep โดยไม่ต้อง code change
- Q-Pending sub-code analysis (per-code resolve timing pattern) = TD Phase 1D ต้อง read CodeWiki §2.5 + per-code logic; ถ้า discover sub-code pattern แตกต่างมาก → revisit threshold per code

**Validation strategy (post-decision):**
- QA Phase 3T: รัน regression baseline (with force-clear enabled at default values) → check `force_clear_count` counter ทุก slot ใน trade journal
- ถ้า `force_clear_count > 0` ใน 5-yr run → ตรวจ pending payload ว่า trigger ใน window valid scenario ไหม (ถ้าใช่ = baseline ไม่กระทบ; ถ้าตัด valid trigger = bucket A drift)
- Expected: 0 force-clear events ใน 5-yr baseline (force-clear = safety net, ไม่ trigger ใน normal operation)

## Consequences

**Positive**
- State file size bounded ทุก scenario
- Observability gain — `force_clear_count` metric บอก stuck pending pattern ที่ user ไม่เคยเห็น
- Configurable → ถ้า force-clear ตัด valid trigger ใน QA → tune ขึ้นได้โดยไม่ต้อง code change
- Behavioral parity preserved ตราบใดที่ baseline ไม่ trigger force-clear (validate ใน QA)

**Negative / trade-off**
- **Risk:** ถ้า bar count ที่เลือกตัด valid pending → bucket A drift > 0 (small) — mitigated โดย QA validation + tunable input
- Adds complexity vs Option A — 3 new inputs + 3 force-clear paths + journal event type
- Requires per-slot `pending_age_bars` tracking ใน SlotState (BR-1.1's SlotState struct ขยาย)

## Revisit-when

- ถ้า QA regression แสดงว่า `force_clear_count > 0` ใน baseline → revisit threshold (เพิ่มขึ้น 50%) หรือ disable for affected machine
- ถ้า user รายงาน live behavior ที่บ่งชี้ pending stuck ก่อนถึง threshold → revisit lower threshold per affected machine
- Phase 2: ถ้าเพิ่ม slot ใหม่ที่ใช้ pending pattern → apply Option C policy ตรงๆ
