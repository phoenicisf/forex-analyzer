# System Design Rebuttal Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Claim Review** | `claim-review-03.md` |
| **Date** | 2026-05-02 |
| **SKILLs** | architecture, software-architecture, brainstorming, research-engineer |

---

## 📊 Summary

| Verdict | Count |
|---------|-------|
| Accepted | 2 |
| Partial | 0 |
| Rejected | 0 |

**Files modified:**
- `docs/design-docs/04-data-flow.md` (1 change — § 4.1 mermaid note)
- `docs/design-docs/05-security.md` (2 changes — § 7.2 monitoring threshold rows)

**ADRs updated/created:** none (semantic ของ ADR-007 / ADR-008 / ADR-011 unchanged — Round 03 เป็น cascade-only fix wording ใน design docs ที่ rebuttal-02 § Phase 4 sweep miss)

---

## Claim Responses

### Claim 03.1: `05 § 7.2` monitoring thresholds ยัง frame counter เป็น "per session"

**Verdict:** Accept

**Rationale:** Reviewer ถูก — Round 02.4 chose Option A (cumulative-survives-restart) เป็น authoritative semantic; schema + ADR-008 + ADR-011 + 03 § 5.3 ตรงกันแล้ว แต่ 05 § 7.2 monitoring thresholds 2 rows (force_clear_count + throttled_alert_count) ยังเก็บ wording "per session" → operator threshold ใช้ไม่ได้จริง (cumulative + "> N per session" = false-positive ถาวรหลัง EA run นาน). เลือก **Option A1** (recommended) — rewrite threshold ให้ cumulative-aware + ระบุ delta-since-last-review framing; ไม่ขยาย schema

**Changes:**
- File: `docs/design-docs/05-security.md` § 7.2 (Key signals to watch)
- Row 1 (`force_clear_count`): เปลี่ยน "per session" → "per slot (cumulative — survives restart per ADR-007)"; threshold เปลี่ยน "> 3 per slot" → "+ 3 new force-clears since last review window"; user action ขยายเป็น *"Inspect journal `pending_force_clear` events since last incident; tune `InpForceClearX_Bars` if pattern persists"*
- Row 2 (`throttled_alert_count`): เปลี่ยน "per session" → "(cumulative across restarts per ADR-011)"; threshold เปลี่ยน "> 50" → "+ 50 new throttle events since last review window"; user action wording คงเดิม
- Evidence (new text row 1): *"Pending machine `force_clear_count` per slot (cumulative — survives restart per ADR-007) | + 3 new force-clears since last review window | Pending threshold may be too tight | Inspect journal `pending_force_clear` events since last incident; tune `InpForceClearX_Bars` if pattern persists"*
- Evidence (new text row 2): *"`logger_metrics.throttled_alert_count` (cumulative across restarts per ADR-011) | + 50 new throttle events since last review window | Many sustained ERRORs ที่ Alert ถูก suppress ..."*

---

### Claim 03.2: `04 § 4.1` mermaid state diagram note "force_clear_count (session metric)" stale

**Verdict:** Accept

**Rationale:** Reviewer ถูก — rebuttal-02 § Phase 4 sweep จับ `03 § 5.3` ได้แต่ miss mermaid note ใน `04 § 4.1`. แม้เป็น label drift ไม่กระทบ functional behavior แต่ขัด authoritative semantic 4 sources → reader build mental model ผิดได้

**Changes:**
- File: `docs/design-docs/04-data-flow.md` § 4.1 (Pending state machine mermaid `note right of PENDING` block)
- เปลี่ยน `- force_clear_count (session metric)` → `- force_clear_count (cumulative; survives restart per ADR-007)`
- Evidence (new text): *"Persisted fields: - pending_started_bar - pending_payload (JSON string) - force_clear_count (cumulative; survives restart per ADR-007) Atomic write via ADR-007"*

---

## Cascaded Changes

ไม่มี — Round 03 fix ทั้งสอง confined ใน 2 ไฟล์ที่ reviewer ระบุตรง ๆ. เพิ่ม Phase 4 sweep ขยายขอบเขต grep:

- `Grep "session metric|per session|session-scoped"` ทั้ง `docs/` → ไม่พบ residual ที่อ้างถึง `force_clear_count` หรือ `throttled_alert_count` cumulative counter อีก
- "per session" ที่เหลือ (02 line 412, 03 line 293/311, ADR-008 line 51) อ้างถึง **Alert anti-spam window** (`≤ 1 Alert per slot per session`) — เป็น Alert popup throttling concept ที่ session-scoped โดยถูกต้อง (different concept จาก persisted counter); ไม่ต้อง cascade

---

## Strength Assessment

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Accept Rate | 100% (2/2) | Reviewer cascade audit ตรงประเด็น — 2 location ที่ rebuttal-02 sweep miss จริง |
| Critical Fixes | 0 | ไม่มี CRITICAL/HIGH ใน Round 03 |
| ADRs Updated | 0 | semantic ADR cumulative ตั้งขึ้น Round 02 แล้ว — Round 03 เป็น label cascade ล้วน |
| Net Improvement | สูง — ทั้ง 6 authoritative sources (schema + ADR-008 + ADR-011 + 03 § 5.3 + 04 § 4.1 + 05 § 7.2) ตรงกัน cumulative-survives-restart; operator threshold ใช้ delta-aware framing ที่ทำงานจริง | |
| Remaining Gaps | 0 items | ไม่มี residual cascade ที่ค้นเจอ |

## Recommendation

- [x] ✅ **Ready for Implementation Handoff** — Round 03 fix ครบ; ทุก authoritative source ตรงกัน semantic; operator threshold actionable
- [ ] 🔁 **Request Re-Review** — N/A
- [ ] ⛔ **Needs Stakeholder Input** — N/A

> **End of Round 03 rebuttal** — 2 cascade fixes landed; 6 sources consistent; proceed ไป TD Phase 1D
