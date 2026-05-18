---
description: Lightweight UX fix — apply review feedback directly without adversarial rebuttal loop
---

# Workflow: UX Fix (Lightweight)

Apply UX review feedback directly to UX deliverables. Use this when `/ux-rebuttal` (Option A) is too token-heavy, or when feedback is straightforward and doesn't need adversarial analysis.

**Input:** `{{input}}` — path to claim-review file or free-text feedback description

**When to use `/ux-fix` instead of `/ux-rebuttal`:**
- Feedback is mostly LOW/MEDIUM severity (no CRITICAL)
- Findings are straightforward fixes (add missing state, fix token reference)
- Token budget is limited — `/ux-fix` uses ~50% fewer tokens than `/ux-rebuttal`
- Round 2+ where most issues are already resolved

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, constraints
2. `.andm/development-guide/ux-design-workflow.md` — UX quality benchmark
3. `docs/state/overview.md` — current project status (if exists)

---

## Phase 1: Load Feedback

### If input is a claim-review file path:

Read the claim-review file and extract all findings into a fix list:

```markdown
| # | File | Issue | Severity | Fix Action |
|---|------|-------|----------|------------|
| 1 | 03-page-layouts.md | Missing empty state for ProjectList | 🟠 HIGH | Add empty state section |
| 2 | 01-design-tokens.md | Missing CSS variable for border-radius | 🟡 MEDIUM | Add --radius-* tokens |
```

### If input is free-text feedback:

Parse the feedback into actionable items with affected files.

### Load Context (in parallel)

Read all `docs/ux/01-05` files + `00-design-vision.md` **if exists** (optional for Modes A/B/C, required for Mode D). UX-06 dropped in SD-as-Master consolidation.

---

## Phase 2: ⏸️ HALT — Confirm Fix List

Present the fix list and wait:

- `proceed` → execute all fixes
- `ปรับ scope` → user narrows/expands
- `cancel` → abort

---

## Phase 3: Execute Fixes

For each item in the fix list (in dependency order):

```
00-design-vision → 01-design-tokens → 02-component-inventory → 03-page-layouts
→ 04-navigation → 05-interaction-patterns
```

Per item:
1. **Announce** — what file and what fix
2. **Read** — fresh read of target file
3. **Fix** — apply minimal change with Edit tool
4. **Cascade** — check related files for consistency
5. **Done** — mark complete

### Special: Fixing `00-design-vision.md`

- Edit only the customized vision in `docs/ux/00-design-vision.md`
- **DO NOT modify** files in `design-reference/` — those are pristine reference originals (kept for traceability/diff)
- After editing vision, cascade-check `01-design-tokens.md` (color roles, depth/elevation) and `02-component-inventory.md` (Do's/Don'ts compliance) — flag violations as follow-up fixes
- If vision changes affect Agent Prompt Guide, also update root `DESIGN.md` if it was copied for AI coding agents

---

## Phase 4: Report

```markdown
## UX Fix Report

**Source:** [claim-review file or free-text]
**Files Modified:** N

| # | File | Fix Applied |
|---|------|-------------|
| 1 | [file] | [what was fixed] |

### Consistency Check
- ✅ / ⚠️ Cross-references between docs/ux/ files
- ✅ / ⚠️ Design vision alignment (Do’s/Don’ts not violated)

### Next Step
- `/ux-review` — re-run review to verify fixes
```

Present summary in Thai.

---

## Phase 5: Optional Post-Fix Enhancements

### Design System Regeneration (if token/component fixes were applied)

If fixes touched `01-design-tokens.md` or `02-component-inventory.md`, suggest:
- `/design-system generate` — regenerate `design-tokens.json` + `design-preview.html` to reflect updated tokens
- `/design-system audit` — verify visual consistency after fixes

### Demo Video (if UI implementation exists)

If fixes were applied to actual code in `services/web/`, suggest:
- `/ui-demo <url>` — record a demo video showing the fixed UI flow
- Use `.agents/skills/ui-demo/SKILL.md` for professional recording with cursor overlay + storytelling
