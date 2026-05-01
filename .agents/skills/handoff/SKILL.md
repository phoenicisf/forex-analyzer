---
name: handoff
description: Generate a handoff document from git diff summarizing what changed, files modified, pending items, and next steps. Use this skill at the end of a task, end of day, before context switches, or when another agent/developer will pick up the work. Also use when the user says "summarize progress", "write handoff", "update status", or "what did I change". Writes to docs/state/{module}/handoff.md and updates overview.md.
---

# Skill: Handoff

## Steps

1. **Run git diff**
   - `git diff --stat` to get a summary of all changed files
   - `git diff` for the full patch (used for detailed summary)
   - `git log --oneline -10` for recent commit context
2. **Summarize changes per module**
   - Group changed files by module/service (web, api, worker, shared, infra)
   - Write 1-3 sentences per module describing what changed and why
3. **List files changed**
   - Provide the full list of added, modified, and deleted files
4. **Identify pending items**
   - List anything that is not yet complete (TODOs, known bugs, next steps)
   - Note any blockers or decisions that need to be made
5. **Write handoff file**
   - Create or update `docs/state/{module}/handoff.md` with the content from steps 2-4
   - Update `docs/state/overview.md` with a one-line status entry for the module

## Output Format

```markdown
# Handoff: {module} - {date}

## Summary
{1-3 sentence overview of what was done}

## Changes by Module
### {module-name}
- {description of changes}

## Files Changed
- `path/to/file1` (added)
- `path/to/file2` (modified)
- `path/to/file3` (deleted)

## Pending Items
- [ ] {item 1}
- [ ] {item 2}

## Blockers / Decisions Needed
- {blocker or open question, if any}
```

## Rules

- Always run `git diff` fresh; do not rely on memory of what changed
- The handoff file must be self-contained -- a new reader should understand the state without extra context
- Never leave pending items undocumented
- Update `docs/state/overview.md` every time a module handoff is written
- Use ISO date format (YYYY-MM-DD) in the handoff heading
