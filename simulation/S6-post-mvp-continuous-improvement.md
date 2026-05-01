# S6: Post-MVP Continuous Improvement — Major Epic เพิ่มเติมหลัง MVP Ship

> TaskFlow MVP ship ไปแล้ว 2 เดือน — business ขอ "Payment & Billing" epic ใหม่ (subscription SaaS model)

---

## Context

- **สถานะ:** MVP v1.0 ship production แล้ว 2 เดือน
  - `docs/ba/01-05` (v1.2: 06-handoff dropped) ✅
  - `docs/design-docs/02-08` (v1.2: 6 docs, gaps 01/06 — merged into 02) + `docs/adr/001-003` + `docs/api-specs/taskflow-api.yaml` ✅
  - `docs/ux/01-05` ✅
  - `docs/technical-design/02-04` ✅
  - `docs/state/{web,api}/handoff.md` + `overview.md` ✅
  - `docs/state/backtrack-log.md` (BT-001, BT-002 closed) ✅
- **Business request:** รองรับ paid plan — subscription tier (Free/Pro/Team), Stripe integration, invoice PDF, billing admin dashboard
- **Scope estimate:** 10+ user stories, 4 new entities (Subscription, Invoice, Payment, Plan), cross-service (API + Web + Worker cron)
- **ตัดสินใจเลือก pattern:** **Append-in-place** (pattern A) เพราะ payment เป็น core module ของ SaaS ใน architecture เดิม ไม่ได้เป็น product ใหม่แยก

---

## Timeline

### Day 1 (Morning): Onboarding + Decision

```
Session 1: เปิด session ใหม่ (fresh persona)
Action:    อ่าน foundation + scope
  - CLAUDE.md
  - docs/design-docs/02-architecture.md (บังคับ — ต้องรู้ bounded context เดิม)
  - docs/state/overview.md (status ปัจจุบัน)
  - docs/state/backtrack-log.md (ของเดิมที่ต้องระวัง)
  - docs/design-docs/07-future-evolution.md (เช็คว่า Payment อยู่ใน Evolution Sequence หรือยัง)

User note: Payment อยู่ใน SD-07 เป็น E2 (next evolution step) → honor hint
Decision: Append-in-place, ไม่ต้องแตก epic-folder
```

### Day 1 (Afternoon): /amend ba

```
Session 2: /amend ba "เพิ่ม epic: Payment & Billing — 3 tiers (Free/Pro/Team), monthly/yearly billing, Stripe checkout, invoice PDF, admin dashboard สำหรับ billing ops"
```

**Impact Analysis:**

| # | File | Change |
|---|------|--------|
| 1 | `02-functional-requirements.md` | + Epic-05: Billing (US-024..US-033), entities: Plan, Subscription, Invoice, Payment |
| 2 | `03-non-functional-requirements.md` | + NFR: PCI compliance (SAQ-A), 99.95% uptime for payment endpoints |
| 3 | `04-business-rules.md` | + BR-020..025: plan limits, pro-rata, grace period, dunning retry |
| 4 | `05-user-flows.md` | + Flow-09 Checkout, Flow-10 Plan upgrade, Flow-11 Invoice download, Flow-12 Admin refund |
| 5 | `01-project-brief.md` | Scope section: note "v1.1 Payment epic added" |

> **v1.2 note:** open questions (Stripe vs Omise, webhook reliability, invoice storage) ไปอยู่ใน relevant doc ตาม domain — Stripe vs Omise ไปตัดสินใจใน SD/ADR (architectural), webhook reliability ไปอยู่ 03-NFR (reliability), invoice storage ไปอยู่ 04-business-rules (BA-06 dropped)

→ proceed → 5 files modified → `/ba-review all` → 3 findings (2 MEDIUM, 1 LOW) → `/ba-rebuttal` → ผ่าน ✅

### Day 2: /amend sd + new ADR + update Evolution

```
Session 3: /amend sd "extend architecture for Payment & Billing — Stripe provider, subscription lifecycle (trialing/active/past_due/canceled), Worker cron สำหรับ billing retry + invoice generation"
```

**Impact:**
- `02-high-level-architecture.md` → + Billing bounded context, + Stripe external system
- `03-deep-dive.md` → + subscription state machine, + webhook handler design
- `05-security.md` → + PCI compliance section (use Stripe Elements, ไม่เก็บ card data)
- `02-high-level-architecture.md § ADR Digest` (bottom section; v1.2: was SD-06) → + Stripe vs Omise decision matrix entry
- **NEW** `docs/adr/005-payment-provider-stripe.md` (Context → Decision → Consequences)
- `07-future-evolution.md` → **ขยับ E2 Payment → Done, เพิ่ม E4 Reporting Dashboard** (next evolution step)
- `08-product-breakdown.md` → + 12 new tasks + Phase Hints (P1: entities+schema, P2: Stripe integration, P3: UI, P4: admin refund)
- `docs/api-specs/taskflow-api.yaml` → + 8 endpoints (plans, subscriptions, invoices, webhooks)

→ `/sd-review all` → 5 findings (1 HIGH ว่า webhook idempotency ไม่ชัด, 3 MEDIUM, 1 LOW) → `/sd-rebuttal` → accept 4, partial 1 → re-review → ผ่าน ✅

### Day 3: /ux-design + /ux-review

```
Session 4: /ux-design auto
Scope:     เฉพาะ new surface — pricing page, checkout, billing settings, invoice list, admin refund modal
```

**Impact (UX append-in-place):**
- `02-component-inventory.md` → + PlanCard, PriceToggle, InvoiceRow, BillingStatusBadge
- `03-page-layouts.md` → + /pricing, /settings/billing, /admin/billing
- `04-navigation-structure.md` → + billing entries ใน user menu + admin sidebar
- `05-interaction-patterns.md` → + checkout flow, invoice download pattern

→ `/ux-review` → 2 findings (LOW) → fix ด้วย `/ux-fix` → ผ่าน ✅

### Day 4: /amend td

```
Session 5: /amend td "Payment epic — backend (Stripe service, webhook handler, billing worker task), frontend (checkout components, billing settings page), DB (4 new tables + migrations)"
```

**Impact:**
- `02-backend-design.md` → + BillingModule (CQRS handlers), + Stripe adapter interface, + webhook signature verification
- `03-frontend-design.md` → + Billing feature folder, + Stripe Elements integration
- `04-database-design.md` → + 4 tables (plans, subscriptions, invoices, payments) + indexes + migration order
- `docs/api-specs/taskflow-api.yaml` → finalize request/response schemas
- `docs/qa/01-test-execution-plan.md` → + webhook idempotency test matrix, + Stripe test mode coverage

→ `/td-review all` → 4 findings (1 HIGH: retry policy missing, 3 MEDIUM) → `/td-rebuttal` → ผ่าน ✅

### Day 5: /impl-plan

```
Session 6: /impl-plan "epic-02-payment"
```

**Planner อ่าน SD hints (E2 + SD-08) + ADR-005 + TD → produce delta plan:**

```markdown
## Implementation Plan — Payment Epic (delta)

### SD Hint Alignment
| Task | SD-08 Hint | Impl Plan | Classification |
|------|-----------|-----------|----------------|
| IMPL-020 DB migration (4 tables) | P1 | P1 | ✅ Align |
| IMPL-021 Plan repository + seed | P1 | P1 | ✅ Align |
| IMPL-022 Stripe adapter + config | P2 | P2 | ✅ Align |
| IMPL-023 Webhook handler + idempotency | P2 | P2 | ✅ Align |
| IMPL-024 Checkout API endpoint | P2 | P2 | ✅ Align |
| IMPL-025 Subscription state machine | P2 | P2 | ✅ Align |
| IMPL-026 Worker: dunning retry task | P2 | P2 | ✅ Align |
| IMPL-027 Worker: invoice PDF gen | P3 | P3 | ✅ Align |
| IMPL-028 Pricing page UI | P3 | P3 | ✅ Align |
| IMPL-029 Billing settings UI | P3 | P3 | ✅ Align |
| IMPL-030 Admin refund UI | — (no hint) | P4 | ◻️ No hint → P4 Polish |
| IMPL-031 Invoice download UX | P3 | P3 | ✅ Align |

Phasing Rationale: Foundation (DB+plans) → Core integration (Stripe+webhook) →
Customer UI → Admin tools. Honor SD-08 hints 11/12; 1 task without hint → default P4.
```

### Day 6-12: /impl-task loop

```
/impl-task IMPL-020..IMPL-031 (12 tasks)
  ↳ แต่ละ task: plan → implement → test (Prove-It for webhook) → commit
/impl-review round-02 (เฉพาะ task ใหม่)
  → 3 findings (1 HIGH: webhook retry race condition, 2 MEDIUM)
  → /impl-review-fix → ผ่าน ✅
```

### Day 13: /red-team (narrow scope)

```
Session: /red-team "payment surface — endpoints /billing/*, webhook handler, Stripe integration"
```

**Scope ระบุชัด — ไม่ full re-audit:**
- Endpoints ที่ scope: POST /billing/checkout, POST /billing/webhook, GET /billing/invoices/:id, DELETE /admin/subscriptions/:id
- Out of scope: endpoint เดิม (task/project/comment) — MVP security audit ของเดิมยังใช้ได้

**Findings:** 4 findings (1 CRITICAL: webhook signature verification bypass possible ถ้า HTTP header case-sensitivity, 2 HIGH, 1 MEDIUM)
→ `/red-team-rebuttal` → patch ทั้งหมด → re-audit → ผ่าน ✅

### Day 14: /deliver + update overview

```
Session: /deliver "Payment Epic v1.1"
```

**Updates:**
- `docs/state/overview.md` → row ใหม่ "Payment Epic v1.1 — 2026-05-02 shipped"
- `docs/design-docs/07-future-evolution.md` → E2 marked ✅ Done, E4 Reporting เลื่อนเป็น next
- Release notes + migration guide

---

## Total Effort

| Phase | Command | Sessions | Time |
|-------|---------|----------|------|
| Onboarding + decision | — | 1 | 1 hr |
| /amend ba + review | `/amend ba`, `/ba-review`, `/ba-rebuttal` | 3 | 3 hr |
| /amend sd + ADR + SD-07 update | `/amend sd`, `/sd-review`, `/sd-rebuttal` | 4 | 6 hr |
| /ux-design + review | `/ux-design`, `/ux-review`, `/ux-fix` | 3 | 3 hr |
| /amend td + review | `/amend td`, `/td-review`, `/td-rebuttal` | 3 | 4 hr |
| /impl-plan | `/impl-plan` | 1 | 1 hr |
| /impl-task × 12 | `/impl-task` | 12 | 5 day |
| /impl-review | `/impl-review`, `/impl-review-fix` | 2 | 1 day |
| /red-team (narrow) | `/red-team`, `/red-team-rebuttal` | 2 | 0.5 day |
| /deliver | `/deliver` | 1 | 2 hr |
| **Total** | | **~32 sessions** | **~2 weeks** |

---

## Methodology Verdict

✅ **PASS** — `/amend` cascade + `/impl-plan` delta + narrow-scope red-team รองรับ post-MVP major epic ได้ครบ

### What Works
- **`/amend` รองรับทุก phase** (ba/sd/ux/td) — ไม่ต้อง redo ทั้ง phase
- **Evolution Sequence (SD-07) เป็น roadmap จริง** — E2 Payment ถูก honor เป็น Phase Hint, Planner align 11/12 tasks อัตโนมัติ
- **Foundation reuse เยอะ** — ADR-001 (Modular Monolith), ADR-002 (Redis+Postgres), UX-01 (design tokens) ไม่ต้องแตะ
- **Red Team narrow scope ได้** — audit เฉพาะ payment surface ประหยัด 60%+ ของ effort
- **`/impl-plan` รับ delta** — output เฉพาะ task ใหม่ ไม่ re-list MVP tasks

### ⚠️ Gaps / สิ่งที่ต้องทำเอง

1. **ไม่มี `/epic-start` command** — ต้องจำ sequence 9 ขั้นเอง (ดู `methodologies/full-track/simulation/S6` นี้เป็น template ได้)
2. **Update SD-07 Evolution Sequence** ไม่ auto — ต้องสั่ง `/amend sd "update 07-future-evolution.md"` เพิ่ม step
3. **ต้องตัดสินใจ pattern (append-in-place vs sub-folder) ตั้งแต่ epic แรก** — retrofit ยาก
4. **Claim review rounds ต้องนับรอบใหม่** — เช่น BA round-02, SD round-02 (ต่อจาก MVP rounds)

### Recommended Next

- ถ้า epic ≥ 3 แล้วยังใช้ pattern append-in-place ไหว → ไม่ต้องทำ `/epic-start`
- ถ้า BA/SD docs ยาวจนหาไม่เจอ → พิจารณาแตก `docs/ba/epic-02-payment/` (pattern B) ใน epic ถัดไป
- Update `CLAUDE.md` § "Post-MVP Iteration Checklist" ด้วย 9-step จาก S6 นี้เพื่อให้ session ถัดไปมี reference
