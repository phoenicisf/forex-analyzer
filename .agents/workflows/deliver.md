---
description: Generate final delivery handoff — readiness assessment, documentation finalization, and delivery summary
---

# Workflow: Deliver Handoff

Assess delivery readiness, finalize all handoff documentation, and produce a delivery summary report.

**Input:** `{{input}}` — optional target scope (e.g., `all`, `api`, `web`)
- Default: `all` (full project delivery)
- Specific module: generates handoff for that module only

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules (REQUIRED)
2. `.agents/skills/andm-deliver-handoff/SKILL.md` — **your persona definition** (activate full delivery protocol)
3. `docs/state/overview.md` — current module status (if exists)
4. `docs/state/impl-plan.md` — implementation plan (if exists)

Once read, proceed to Phase 1.

---

## Phase 1: Assess Delivery Readiness

Follow SKILL.md Phase 1 — scan all project deliverables and produce a readiness checklist:

1. **Design Completeness** — check all 4 design phases have full deliverables
2. **QA Status** — verify all review/rebuttal loops passed (no CRITICAL/HIGH remaining)
3. **Implementation Status** — count completed vs deferred tasks from impl-plan
4. **Code Health** — check git status, test results, uncommitted work
5. **Deferred-AC Registry Drain** — read `docs/state/deferred-ac-registry.md`; **block delivery** if `## Active` table has any row (every entry must be moved to `## Resolved` with evidence artifact path before shipping)
6. **Phase Gate Closure** — verify every Phase Gate in `impl-plan.md` has all rows `[x]` (no `[ ]` remaining); any open row → block delivery

Present the readiness checklist as a table:

```
## Delivery Readiness

| Area | Status | Details |
|------|--------|---------|
| BA Docs (8) | ✅/⚠️/❌ | [count] files, review [status] |
| SD Docs (8) | ✅/⚠️/❌ | [count] files, review [status] |
| UX Docs (6) | ✅/⚠️/❌ | [count] files, review [status] |
| TD Docs (8) | ✅/⚠️/❌ | [count] files, review [status] |
| ADRs | ✅/⚠️/❌ | [count] decisions |
| API Specs | ✅/⚠️/❌ | [count] specs |
| Impl Plan | ✅/⚠️/❌ | [done]/[total] tasks |
| Phase Gates | ✅/❌ | All gates closed `[x]`? Open `[ ]` rows = blocker |
| Deferred-AC Registry | ✅/❌ | Active table empty? Any active row = blocker |
| Code Review | ✅/⚠️/❌ | [status] (incl. Dimension #11 Empirical AC Closure + Dimension #12 Functional CRUD walk + Dimension #13 Configuration Completeness findings) |
| Red Team | ✅/⚠️/❌ | [status] |
| QA Plan | ✅/⚠️/❌ | [status] |
```

**Hard blockers (cannot ship):**
- Any `## Active` row in `deferred-ac-registry.md`
- Any `## Pending` row in `operator-action-registry.md`
- Any `[ ]` row in any Phase Gate within scope (incl. Tier 1.5 Exploratory Walk row + Rollback plan row)
- Any open CRITICAL/HIGH from code review or red team (including Dimension #11 closure-rule violations + Dimension #13 config-completeness violations)

---

## Phase 2: Generate Handoff Documentation

Follow SKILL.md Phase 2:

1. Update `docs/state/overview.md` with final module statuses
2. Update or create per-module `docs/state/*/handoff.md` files
3. Generate delivery summary report

---

## Phase 3: ⏸️ HALT — Human Review

Present the complete delivery summary and wait for approval:

- `approve` → finalize and commit
- `revise` → address specific feedback
- `block` → list what must be fixed first

> ⚠️ **CRITICAL: ห้าม finalize โดยไม่ได้ human approve**

---

## Phase 4: Finalize

Upon approval:
1. Commit all updated `docs/state/` files with contextual commit message
2. Report final status and recommended next steps:
   - Deploy preparation
   - Knowledge base setup (NotebookLM / wiki)
   - Monitoring dashboard setup
   - Handoff to maintenance team
