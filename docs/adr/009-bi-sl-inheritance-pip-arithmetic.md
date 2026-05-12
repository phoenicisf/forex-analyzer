# ADR-009 — BI SL Inheritance: Same SL Distance (Concrete Pip Arithmetic)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-05-02 |
| **Deciders** | Architect (Phase 1B) |
| **Goal trace** | G4, FR-3.3, BR-7.1, OQ-3.3 (✅ resolved 2026-05-01 — semantic locked, this ADR locks arithmetic) |
| **Amendment** | 2026-05-12 — Validation + Consequences + Revisit-when sections cascade-updated per BT-001 (BA NFR-1.1 + NFR-1.8 re-baseline 2026-05-12) — Bucket B framing demoted to informational delta, Revisit-when trigger re-anchored to Bucket A (rewrite-G4-ON build). Decision arithmetic (Option A — earliest B parent SL distance + Bollinger fallback) unchanged |

## Context

BR-7.1 / FR-3.3 = **CRITICAL fix** ของ EA เดิม: BI orders เปิดด้วย `SL=0` (CodeWiki §6.2 `:20326 :20357`) → naked exposure. User decision 2026-05-01 = FIX ด้วย semantic **(a) same SL distance** — BI ใช้ pip distance เดียวกับ B parent's SL วัดจาก BI entry price (preserve risk model ที่ EA เดิมใช้กับ slot G/R/P)

BA ระบุว่า "SD agent (Phase 1B) ลงรายละเอียด exact pip arithmetic; TD lock implementation ใน Phase 1D" (`04 § BR-7.1` resolution path)

Edge cases ต้องตัดสิน:
1. B parent มี > 1 active position ที่ SL ต่างกัน — ใช้ SL ของ position ไหนเป็น reference?
2. B parent ไม่มี SL (legacy position ก่อน fix deploy) — fall back อย่างไร?
3. BI entry direction ตรงข้าม B parent (rare) — invert sign ไหม?
4. Pip vs point precision ตอน 5-digit broker (FBS Standard ใช้ 5-digit) — DigitMultipier = 10

## Options Considered

### Option A — Use B parent's earliest position SL distance (chosen)

```mql5
// Pseudo-code (TD lock final)
double ComputeBI_SL(double bi_entry_price, ENUM_ORDER_TYPE bi_dir,
                   const SlotState &b_state) {
   if (b_state.ticket_ids[].Count() == 0) {
      // Edge: no B parent active → cannot inherit; fall back to BBBot/BBTop ± 10 pip ของ Slot R formula
      return ComputeFallbackSL_Bollinger(bi_entry_price, bi_dir);
   }
   // Pick earliest-opened B parent (oldest ticket = first pyramid base)
   ulong parent_ticket = FindEarliestTicket(b_state.ticket_ids);
   PositionInfo p; p.SelectByTicket(parent_ticket);
   double parent_open = p.PriceOpen();
   double parent_sl = p.StopLoss();
   if (parent_sl == 0) {
      // Edge: legacy B without SL → fall back
      return ComputeFallbackSL_Bollinger(bi_entry_price, bi_dir);
   }
   double sl_distance_pip = MathAbs(parent_open - parent_sl) / (_Point * DigitMultipier);
   double sl_distance_price = sl_distance_pip * _Point * DigitMultipier;
   if (bi_dir == ORDER_TYPE_BUY) {
      return bi_entry_price - sl_distance_price;
   } else {
      return bi_entry_price + sl_distance_price;
   }
}
```

### Option B — Use B parent's latest position SL

**Rejected:** Latest = most recent pyramid layer; SL distance ของ pyramid layers อาจ tighten ตาม trail → BI inherit tight SL = high stop-out risk; ของเดิมใช้ semantic "BI = additional pyramid ของ B base risk" — earliest = base risk (consistent)

### Option C — Average SL distance ข้ามทุก B position

**Rejected:** Average + position count varying = behavior nondeterministic ตอน QA replay; preserve "single anchor" semantic

### Option D — Use B-slot's signal-time SL formula (recompute fresh)

**Rejected:** B's SL formula = `min(wave low, BBBot, lowMain)` (BR-5.1) — recompute ตอน BI fires อาจต่าง market context → BI SL ไม่ใช่ "inherited" จาก parent อีก; ขัด OQ-3.3 semantic (a)

## Decision

เลือก **Option A — earliest-opened B parent SL distance + fallback to Bollinger formula**

**Concrete arithmetic locked:**

```
sl_distance_pip = |B_parent.open_price − B_parent.sl| / (_Point × DigitMultipier)
sl_distance_price = sl_distance_pip × _Point × DigitMultipier

if BI direction == BUY:
    BI.sl = BI.entry_price − sl_distance_price
else (SELL):
    BI.sl = BI.entry_price + sl_distance_price
```

**Edge case fallbacks:**
1. **No active B parent:** fall back to **Slot R Bollinger formula** (BBBot − 10 pip สำหรับ buy, BBTop + 10 pip สำหรับ sell). Reason: BI = Bollinger-context slot per BR-5.1 → R formula = closest semantic peer; preserve safety
2. **B parent SL == 0** (legacy position pre-fix): fall back to Bollinger formula (same as #1)
3. **BI direction ตรงข้าม B parent:** computation ใช้ `MathAbs` + sign flip ตาม BI direction → no special case
4. **Precision:** `DigitMultipier = 10` สำหรับ 5-digit broker (BR-9.3) → ทุก pip arithmetic คูณด้วย `DigitMultipier`; FBS Standard 5-digit ตาม baseline

**Trade journal observability:**
- Field `parent_ticket_id` (FR-4.1 schema) populate ด้วย `B_parent_ticket` ตอน BI entry event
- Field `signal_context` ใส่ `"sl_inherit=B_parent_<ticket>;sl_distance_pip=<N>"` หรือ `"sl_inherit=fallback_bollinger"` ตอน fallback ทำงาน — สำหรับ retrospective audit

**Validation (NFR-1.1 Bucket A + NFR-1.8 informational delta, BT-001 re-baseline 2026-05-12):**
- QA Phase: รัน regression บน rewrite default build (G4 fixes ON, single-pass per BT-001) → inspect BI trade journal entries
- ตรวจ `sl > 0` ทุกราย (AC-3.3.2)
- ตรวจ `(BI_entry − BI_sl)` pip distance = `(B_entry − B_sl)` pip distance ของ parent ticket เดียวกัน
- Bucket A measurement (rewrite-G4-ON build, NFR-1.1 ≤ 25%) absorbs BI SL fix drift; portfolio-level PF (NFR-1.2 ≤ 0.2 drop) + Max DD (NFR-1.5 ≤ +10pp) gate at portfolio level. NFR-1.8 informational delta (`rewrite-G4-ON − rewrite-G4-OFF`) record sign + magnitude เฉพาะ partial pre-CircuitBreaker window measurable (ดู BA `03 § NFR-1 Empirical Citation`)

## Consequences

**Positive**
- Deterministic — replay regression ครั้งไหนก็ได้ผลเดียวกัน (oldest ticket = stable anchor)
- Observable — `parent_ticket_id` + `signal_context` field ใน journal บอก audit trail ครบ
- Fallback safe — ไม่มีกรณี SL=0 ใหม่หลัง fix (G4 contract)

**Negative / trade-off**
- ต้องเก็บ `ticket_ids[]` array ใน `SlotState` (PortfolioState ADR-005 ครอบคลุมแล้ว)
- ⚠️ Assumption: oldest-ticket selection = correct anchor (vs newest, average) — ผ่าน semantic argument ของ "base risk" — ถ้า QA แสดง drift > expected → revisit
- Bucket A measurement absorbs BI SL fix per NFR-1.1 (rewrite-G4-ON vs baseline); informational delta estimate (per BA `03 § NFR-1 Empirical Citation` post-BT-001 2026-05-12):
  - Win rate: BI ที่เคย naked = ตอนนี้มี SL → อาจถูก stop out บ้างใน losing scenario → win rate ลดเล็กน้อย
  - Net Profit: ลดลงได้ใน bear scenario (BI โดน stop), เพิ่มขึ้นได้ใน trend reversal scenario (BI หลีก deep DD)
  - PF: ควรนิ่ง (ทั้ง gross profit + gross loss ลดลง proportional)
  - Max DD%: ควรลดลง (G4 ของ fix นี้ตรงๆ)

## Revisit-when

- ถ้า QA regression แสดง Bucket A (rewrite-G4-ON vs baseline) drift > 25% Net Profit → user re-decide per BA `03 § NFR-1.1 Verification` + `01 § 10` resolved OQs (BT-001 re-baseline 2026-05-12 subsumes G4 fix contribution into Bucket A; ไม่มี Bucket B threshold trigger)
- Phase 2 ถ้าเพิ่ม slot pyramid pattern อื่น (เช่น JI, GI) → apply same arithmetic + ADR template
