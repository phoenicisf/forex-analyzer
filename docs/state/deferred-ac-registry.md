# Deferred-AC Registry

> Single source of truth for E-ACs (Empirical Acceptance Criteria) ที่ exercise ตอน task closure ไม่ได้ — vendor account ยังไม่มา / hardware ไม่ถึง / upstream dep blocked
> ห้าม mark task `[x]` ใน `impl-plan.md` ด้วย closure note "deferred" — เปิด entry ที่นี่แทน
> Read by `/impl-task` (HALTs on expired entries), `/impl-review` (cross-checks closure-rule violations), `/deliver` (blocks shipping if non-empty)

> **PhoenicisNex Phase 1 baseline note (2026-05-02):** local-only sandbox; no vendor account / hardware wait / external dependency expected. Registry is initialized empty + remains empty unless Phase 2 cloud journal / Telegram / multi-account triggers added (per BA `01 § 6.2 Won't Permanent` + ADR Revisit-when entries).

---

## Active

| Phase | Task | E-AC text | Evidence-kind | Deferred reason | Owner | Opened | Expires | Risk if missed |
|-------|------|-----------|---------------|-----------------|-------|--------|---------|----------------|
| _empty — registry initialized 2026-05-02_ | | | | | | | | |

---

## Resolved

| Phase | Task | E-AC text | Resolved on | Evidence artifact path |
|-------|------|-----------|-------------|------------------------|
| _empty_ | | | | |

---

## Rules

1. **Every defer requires an entry here** — engineer cannot mark task `[x]` without entry; reviewer raises Dimension #11 CRITICAL otherwise
2. **Expiry ≤ 14 days from `Opened`** (absolute date, not relative). Phase boundaries ไม่ extend expiry
3. **On expiry**: `/impl-task` next invocation HALTs and surfaces the expired entry. Options:
   - (a) resolve now (run the empirical step + move row to Resolved)
   - (b) renew once with rationale (max 2 renewals per row total)
   - (c) escalate via `/backtrack`
4. **Phase Gate drain**: phase ปิดไม่ได้ while any registry row's `Phase` matches the closing phase
5. **`/deliver` block**: `/deliver` ห้าม ship project ขณะที่ Active table มี row ใดอยู่

---

## PhoenicisNex-specific anti-pattern catalog (avoid)

> ห้ามใช้ closure pattern เหล่านี้ใน `impl-plan.md`:
>
> - ❌ `[x]` + `<!-- deferred to operator-runtime -->`
> - ❌ `[x]` + `<!-- live verification deferred per IMPL-XXX precedent -->`
> - ❌ `[x]` + `<!-- structural test pass; empirical N/A -->` ถ้า task touches network / persistence / user-visible / async / security
>
> ถ้าจริงๆ ต้อง defer (เช่น Phase 2 cloud journal vendor account ยังไม่ provision) → **เปิด row ที่นี่** + split task เป็น S-AC subtask (ปิดได้ตอนนี้) + E-AC subtask (track ที่นี่)

---

## Schema reference

```yaml
phase: P1 | P2 | P3 | P4
task: IMPL-NNN
e_ac_text: "verbatim AC text from impl-plan.md"
evidence_kind: probe | gui-capture | log-assertion | queue-inspect | db-inspect | file-blob-check | boot-cold | contract-roundtrip | config-audit
deferred_reason: "single-sentence why exercise-now is impossible"
owner: human-or-agent-name
opened: YYYY-MM-DD
expires: YYYY-MM-DD  # ≤ 14 days from opened
risk_if_missed: "what breaks if this E-AC never runs (≤25 words)"
```
