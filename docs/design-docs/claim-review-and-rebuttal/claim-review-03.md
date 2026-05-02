# System Design Claim Review Round 03

| Field | Value |
|-------|-------|
| **Round** | 03 |
| **Target** | `all` (post-rebuttal-02 verification — 6 design docs + 12 ADRs + 4 API specs) |
| **Date** | 2026-05-02 |
| **Reviewer** | System Design Reviewer (Adversarial Architect) |
| **SKILLs** | architecture, software-architecture, brainstorming, code-review, research-engineer |
| **Predecessor** | `claim-review-02.md` (6 findings — 4 MEDIUM / 2 LOW) → `rebuttal-round-02.md` (6 Accept / 0 Partial / 0 Reject) |

---

## 📊 At-a-Glance

**Total findings:** 2 (🔴 CRITICAL **0** / 🟠 HIGH **0** / 🟡 MEDIUM **1** / 🔵 LOW **1**)
**Schedule-leakage check:** ✅ Clean — grep `Sprint|Week|Q[1-4] 202X|team capacity|## Phase Plan|Schedule|Roadmap` พบ 0 hits ใน design-docs (เฉพาะ `IMPL-067 — DST regression run (10 transitions Mar 2021 → Oct 2025)` = dataset description, ไม่ใช่ schedule)
**Language check:** ✅ Pass — Thai narrative ≥ 40% ทุก doc; new edits ของ rebuttal-02 (TL;DR rewrite, mermaid Note formula, ADR Digest cell, ADR-011 throttled-counter row) เขียนเป็นไทย-led ครบ
**No-Hints Pass-Through:** Phase Hints = FULL variant ใน `08`; Evolution Sequence = 2 entries (E1+E2) ใน `07 § 6` — TL;DR sync แล้วหลัง 02.1 fix ✅
**Anti-Duplication:** Round 02's 6 fixes (02.1 TL;DR sync, 02.2 mermaid Note formula, 02.3 mermaid edge ORC→IS, 02.4 schema cumulative + ADR-011 + 03 § 5.3 cascade, 02.5 ADR Digest escalation, 02.6 IMPL-068 A6) verified **landed correctly** — ไม่ raise ซ้ำ
**Net assessment:** Round 02 cascade fix ทำได้ดี แต่ **2 location ที่ Phase 4 sweep ของ rebuttal-02 plr** — เจอ `04 § 4.1` mermaid state diagram + `05 § 7.2` monitoring table ที่ยัง frame counter เป็น "session" semantic. Cascade scope incomplete — schema + ADR-008 + ADR-011 + 03 § 5.3 ตรงกัน 4 sources, แต่ 2 sources ที่เหลือ stale → ต้องแก้ให้ครบ 6 sources

### Top 3 to Fix First

1. **Claim 03.1** 🟡 — `05 § 7.2` monitoring thresholds ยัง frame `force_clear_count > 3 per session` + `throttled_alert_count > 50 per session` — counter cumulative-survives-restart หลัง 02.4 fix; threshold framing ขัด semantic + operator threshold ไม่ทำงาน — `docs/design-docs/05-security.md`
2. **Claim 03.2** 🔵 — `04 § 4.1` mermaid state diagram note ยังเขียน *"force_clear_count (session metric)"* — cascade miss จาก 02.4 sweep — `docs/design-docs/04-data-flow.md` § 4.1

### Verdict

- [x] ✅ **Ready for Implementation Handoff** — ไม่มี CRITICAL/HIGH; 1 MEDIUM + 1 LOW = pure cascade polish จาก Round 02.4 sweep ที่ไม่ครบ; effort < 10 min
- [ ] ⚠️ **Needs Rebuttal Round** — N/A (no CRITICAL/HIGH)
- [ ] ⛔ **Immediate Attention** — N/A

> **Recommendation:** Architect ทำ light cascade pass (estimated effort: 10 min) แก้ 2 residual session-semantic stale wording; ถ้ายอมรับ residual → proceed ไป TD Phase 1D ตรง ๆ ได้ (semantic ที่ authoritative — schema + ADR-008 + ADR-011 + 03 § 5.3 — ตรงกันแล้ว; Operator threshold ใน 05 § 7.2 ที่ผิดเป็น MEDIUM ทาง functional แต่ไม่ block design)

---

## System Design Attack Vector Checklist (22 Categories)

| # | Category | Status | Notes |
|---|----------|--------|-------|
| 1 | Architecture Style Justification | ✅ Pass | unchanged from Round 02 |
| 2 | Service Boundaries | ✅ Pass | Claim 02.3 mermaid edge `BV --> IS` removed + `ORC --> IS` added (line 234) ✅ |
| 3 | Communication Patterns | ✅ Pass | unchanged |
| 4 | Data Consistency | ✅ Pass | unchanged |
| 5 | Database Design | ✅ Pass | unchanged |
| 6 | Caching Strategy | ✅ Pass | unchanged |
| 7 | Security Design | ✅ Pass | unchanged |
| 8 | Scalability | ✅ Pass | unchanged |
| 9 | Reliability & Fault Tolerance | ✅ Pass | unchanged |
| 10 | Performance Budgets | ✅ Pass | Claim 02.2 mermaid Note rewrite to formula `tick budget = 0.10 × measured baseline` (line 39) ✅ |
| 11 | Concrete Numbers | ✅ Pass | unchanged |
| 12 | API Contract Quality | ✅ Pass | Claim 02.4 schema descriptions rewrite (`force_clear_count` line 199-202 + `throttled_alert_count` line 176-179) cumulative semantic ✅ |
| 13 | Data Flow Completeness | ⚠️ Finding 03.2 | sequence diagram ✅; **state diagram note** `04 § 4.1` line 300 ยัง stale "session metric" |
| 14 | Observability | ⚠️ Finding 03.1 | Authoritative schema + ADR-011 + 03 § 5.3 ตรงกัน ✅; **05 § 7.2 monitoring thresholds** ยัง frame "per session" — ขัด cumulative semantic + operator threshold ผิด |
| 15 | ADR Quality | ✅ Pass | Claim 02.5 ADR-006 row trade-off escalation policy added ✅; ADR-011 throttled-counter row cumulative ✅ |
| 16 | Cross-Doc Consistency | ⚠️ Findings 03.1, 03.2 | Round 02's 6 contradictions resolved ✅; **2 cascade miss residual** — schema/ADR-011/03 § 5.3 ตรงกัน 4 sources, แต่ 04 § 4.1 + 05 § 7.2 stale |
| 17 | Requirements Traceability | ✅ Pass | unchanged |
| 18 | Failure Modes | ✅ Pass | unchanged |
| 19 | Future Evolution + Evolution Sequence | ✅ Pass | Claim 02.1 TL;DR rewrite to E1+E2 ✅; 07 TL;DR + § 6 + footer ตรงกัน 3 ที่ |
| 20 | Work Inventory + Phase Hints | ✅ Pass | Claim 02.6 IMPL-068 description (§ 1.10 line 135 + § 4 line 299) reference A6 + measurement scope ✅ |
| 21 | Readability / Reader-Empathy | ✅ Pass | TL;DR + decision rationale + glossary ครบ; mermaid narrative ครบ |
| 22 | Language Rule Compliance | ✅ Pass | bilingual ทุก doc; rebuttal-02 edits ใช้ Thai-led narrative |

---

## Findings (ordered: 🟡 MEDIUM → 🔵 LOW)

### 🟡 MEDIUM

#### Claim 03.1: 🟡 MEDIUM — `05 § 7.2` monitoring thresholds ยัง frame counter เป็น "per session" — ขัด cumulative-survives-restart semantic + operator threshold ใช้ไม่ได้จริง

**Location:** `docs/design-docs/05-security.md` § 7.2 (monitoring signals table — บรรทัด 236, 240)

**Problem:**
2 monitoring threshold rows ยัง frame counter เป็น session-scoped:

```markdown
| Pending machine `force_clear_count` per session | > 3 per slot | Pending threshold may be too tight | Tune up via input |
| `logger_metrics.throttled_alert_count` per session | > 50 | Many sustained ERRORs ที่ Alert ถูก suppress... |
```

แต่ **Claim 02.4 fix (Option A — chosen)** ได้ rewrite ทุก authoritative source ระบุ counter = **cumulative survives restart**:

- `state-persistence-schema.yaml` line 179: *"survives restart via state.json (atomic per ADR-007). User ที่ restart EA บ่อยยังเห็น cumulative throttle pattern"*
- `state-persistence-schema.yaml` line 202: *"Cumulative counter; survives restart via state.json"*
- `docs/adr/011-tagged-structured-logger.md` line 61: *"cumulative survives restart via state.json"*
- `docs/design-docs/03-deep-dive.md` line 302: *"cumulative counter; survives restart via state.json"*

**05 § 7.2 ไม่ได้ cascade ตาม** — ยังเก็บ wording "per session" + threshold ที่ calibrated สำหรับ session counter

**Why this matters:**
นี่ไม่ใช่แค่ wording — เป็น **functional contradiction**. Operator monitoring threshold = decision rule. ถ้า counter cumulative + threshold "> 3 per slot" → user ที่ run EA 6 เดือนน่าจะ accumulated 3 force-clears เป็นเรื่องปกติ → threshold trip ตลอดเวลาแบบ false-positive → user ignore signal → defeat observability intent ของ ADR-008.

`throttled_alert_count > 50` ก็แบบเดียวกัน — cumulative คงเลย 50 ภายใน 1-2 สัปดาห์ของ ERROR sustained → user ถูก spam threshold notice → ignore → miss real issue

ถ้าจะรักษา "per session" semantic ของ threshold (สมเหตุสมผลกว่า — bursty pattern detection) ต้อง compute delta:
- `delta = current - last_session_baseline` snapshot ตอน OnInit
- หรือ reset counter ทุก reload (= Option B ที่ 02.4 reject)

**ปัจจุบัน:** schema/ADR cumulative + 05 threshold "per session" → operator ทำตามไม่ได้

**Minimum acceptable fix:**
เลือก 1 ใน 2 paths:

**Option A1 (recommended — match cumulative semantic):** rewrite threshold เป็น cumulative-aware:
```markdown
| `force_clear_count` per slot (cumulative — see ADR-007) | new force-clear since last review | Pending threshold may be too tight | Inspect journal `pending_force_clear` events since last incident; tune `InpForceClearX_Bars` if pattern persists |
| `logger_metrics.throttled_alert_count` (cumulative across restarts) | + 50 since last review | Many sustained ERRORs... | Inspect Experts log... |
```
+ ระบุ explicitly ว่า user track *delta* ระหว่าง review windows

**Option A2 (delta tracking field):** เพิ่ม `force_clear_count_delta_since_init` (computed at OnInit) ใน schema; threshold ของ A2 = "delta > 3 per slot per session"

Strongly recommend A1 — ไม่ขยาย schema; เพียง update ภาษา

**Effort:** Low (5-10 minutes — 2 row edits + 1-2 sentence note above table อธิบาย cumulative tracking)

---

### 🔵 LOW

#### Claim 03.2: 🔵 LOW — `04 § 4.1` mermaid state diagram note "force_clear_count (session metric)" stale หลัง 02.4 cascade

**Location:** `docs/design-docs/04-data-flow.md` § 4.1 (Pending state machine mermaid — `note right of PENDING` block, บรรทัด 300)

**Problem:**
mermaid `note right of PENDING` ระบุ persisted fields:

```
note right of PENDING
    Persisted fields:
    - pending_started_bar
    - pending_payload (JSON string)
    - force_clear_count (session metric)
    Atomic write via ADR-007
end note
```

ค่า **"(session metric)"** ขัดกับ Claim 02.4 fix ที่ระบุ counter = cumulative-survives-restart. Rebuttal-02 § Cascaded Changes บอก "Phase 4 sweep" จับ `03 § 5.3` ได้, แต่ **04 § 4.1 mermaid note** หลุด

**Why this matters:**
LOW เพราะ:
1. authoritative source (schema + ADR-008 + ADR-011 + 03 § 5.3) ตรงกัน 4 sources — single mermaid label ไม่เปลี่ยน semantic
2. mermaid note อยู่ใน state diagram ที่ focus คือ state transition ไม่ใช่ persistence semantic
3. ไม่เป็น functional contradiction (ไม่กระทบ implementation)

แต่ก็คือ **drift** — reader ที่อ่าน 04 ก่อน 03/schema จะ build mental model ผิด

**Minimum acceptable fix:**
แก้ note (line 300) เป็น:

```
note right of PENDING
    Persisted fields:
    - pending_started_bar
    - pending_payload (JSON string)
    - force_clear_count (cumulative; survives restart per ADR-007)
    Atomic write via ADR-007
end note
```

**Effort:** Low (1 minute — single line edit)

---

## Cross-Document Issues

| Issue | Files affected | Finding |
|-------|----------------|---------|
| `force_clear_count` + `throttled_alert_count` cumulative semantic ตรงกัน 4/6 sources — `04 § 4.1` mermaid + `05 § 7.2` thresholds ยัง stale | `04 § 4.1` (line 300), `05 § 7.2` (lines 236, 240) | 03.1, 03.2 |

ไม่พบ contradictions ระดับ architectural — Round 02's 6 cascade contradictions ทั้งหมด resolved ✅; Round 03 พบเฉพาะ 2 residual cascade ที่ rebuttal-02 § Phase 4 sweep miss

---

## Summary Table

| # | Severity | Title | Location | Effort |
|---|----------|-------|----------|--------|
| 03.1 | 🟡 MEDIUM | `05 § 7.2` thresholds "per session" ขัด cumulative semantic | `05-security.md` § 7.2 lines 236, 240 | Low |
| 03.2 | 🔵 LOW | `04 § 4.1` mermaid note "session metric" stale | `04-data-flow.md` § 4.1 line 300 | Low |

> **End of Round 03 review** — Round 02 fixes verified solid (6/6 landed clean ใน authoritative sources). 2 residual cascade misses (1 MEDIUM functional + 1 LOW label drift) ที่ rebuttal-02 § Phase 4 sweep ไม่ครอบคลุม. Total fix effort < 10 minutes. Recommend lightweight `/amend sd` หรือ direct edit → proceed ไป TD Phase 1D
