---
description: Analyze UX review findings, fix UX deliverables, and write rebuttal report
---

# Workflow: UX Design Rebuttal

Analyze findings from a UX claim review, apply fixes to UX deliverables, and produce a structured rebuttal report.

**Input:** `{{input}}` — path to claim-review file (e.g., `claim-review-01.md` or full path `docs/ux/claim-review-and-rebuttal/claim-review-01.md`)

---

## Phase 0: Onboarding (Read These Files NOW)

Read the following files immediately before doing anything else:

1. `CLAUDE.md` — project rules, tech stack, constraints
2. `.agents/skills/andm-ux-defender/SKILL.md` — **your persona definition** (activate the full 7-step claim processing protocol)
3. `.andm/development-guide/ux-design-workflow.md` — UX quality benchmark
4. `docs/state/overview.md` — current project status (if exists)

Once read, proceed to Phase 1.

---

## Phase 1: Load Context (MANDATORY — All reads in parallel)

### 1.1 Resolve Input Path

If `{{input}}` is a filename only (e.g., `claim-review-01.md`):
→ Resolve to `docs/ux/claim-review-and-rebuttal/claim-review-01.md`

If `{{input}}` is a full path:
→ Use as-is

### 1.2 Read All Context (in parallel)

1. **Claim Review** — Read the target claim-review file
2. **UX Deliverables** — Read all `docs/ux/01-05` + `00-design-vision.md` **if exists** (optional for Modes A/B/C, required for Mode D). UX-06 dropped in SD-as-Master consolidation.
3. **Previous Rebuttals** — Read any existing `rebuttal-round-*.md` files in `docs/ux/claim-review-and-rebuttal/`
4. **BA User Flows** — Read `docs/ba/05-user-flows.md` (if exists) or `docs/design-docs/08-product-breakdown.md` (Path B fallback)
5. **API Contracts** — Read all files in `docs/api-specs/`
6. **Web Rules** — Read `.claude/rules/web.md`

### 1.3 Determine Round Number

Count existing `rebuttal-round-*.md` files → next round = count + 1

### 1.4 Engage Persona

Follow the andm-ux-defender persona defined in `.agents/skills/andm-ux-defender/SKILL.md`. Activate the full 7-step claim processing protocol.

---

## Phase 2: Analyze Claims

For each claim in the claim-review file:

1. **Read** the cited file + section
2. **Assess** whether the finding is valid
3. **Determine** verdict: Accept / Partial / Reject
4. **Draft** the response (changes needed or rejection evidence)

Present a summary table:

```markdown
## Analysis Summary

| Claim | Severity | Proposed Verdict | Reason (brief) |
|-------|----------|-----------------|----------------|
| XX.1 | 🔴 CRITICAL | Accept | [short reason] |
| XX.2 | 🟠 HIGH | Partial | [short reason] |
| XX.3 | 🟡 MEDIUM | Reject | [short reason] |
```

---

## Phase 3: ⏸️ HALT — User Approval

Present the analysis summary and wait for user decision:

- `proceed` → execute all fixes as analyzed
- `ปรับ verdict` → user overrides specific verdicts
- `cancel` → abort rebuttal

> ⚠️ **CRITICAL: ห้าม proceed โดยไม่ได้ user approve**

---

## Phase 4: Execute Fixes

Upon user approval, process each claim following the 7-step protocol from SKILL.md:

```
For each claim (in dependency order — foundational fixes first):
  Step 1: Announce — "Processing Claim XX.N: [title]"
  Step 2: Fresh Read — Read the cited file
  Step 3: Cross-Doc Check — Read related docs/ux/ files
  Step 4: Apply Fix (Accept/Partial) or Document Rejection
  Step 5: Verify — Re-read modified section
  Step 6: Cascade Check — Update related files:
           - Token changes → check component specs
           - Component changes → check page layouts + handoff
           - Page layout changes → check navigation + interactions
           - Navigation changes → check handoff
  Step 7: Mark Complete
```

**Dependency order:**
```
00-design-vision → 01-design-tokens → 02-component-inventory → 03-page-layouts → 04-navigation → 05-interaction-patterns
```

---

## Phase 5: Write Rebuttal Report

Write to `docs/ux/claim-review-and-rebuttal/rebuttal-round-XX.md` following the output format in SKILL.md.

Present a concise summary in Thai:
- Verdict counts (Accept/Partial/Reject)
- Files modified with specific changes
- Cascaded changes
- Recommended next step (`/ux-review` or stakeholder approval)
