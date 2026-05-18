# andm-project-init-engineer

> Generates project-specific CLAUDE.md + `.claude/rules/*.md` + IDE adapter mirrors — all derived from approved Technical Design docs. Engineer subagents stay stack-agnostic and read `.claude/rules/*.md` at runtime.
>
> Invoked by `/project-init` — a Phase 2.5 bridge between Design QA (Phase 2) and Implement (Phase 3).

See [`SKILL.md`](./SKILL.md) for full persona definition, scope, HALT protocol, and quality gates.

## When to Use

- After `/td-review` approves Technical Design docs (no CRITICAL/HIGH pending)
- Before `/impl-plan` begins implementation planning
- As `--regen` after `/amend td` or `/backtrack td` changes tech stack
- As `--amend "<description>"` for targeted edits (add rule, tighten config, remove obsolete rule)

## Why It Exists

**Problem:** If CLAUDE.md / `.claude/rules/` are written before Phase 1D (TD), they bias architect/engineer decisions toward template defaults. A sample "API: C# .NET 9" rule would nudge the architect away from Go or Rust even when NFR requirements point elsewhere.

**Solution:** Derive CLAUDE.md + rules *from* TD, not the other way around. Lock stack bias to the TD decision-making process.

## Outputs

| Tier | File | Purpose |
|------|------|---------|
| T1 | Root `CLAUDE.md` | Project rules (methodology + actual stack + domain glossary) |
| T1b | Root `AGENTS.md` | Slim multi-IDE entry point pointer |
| T2 | `.claude/rules/*.md` | Claude Code per-service + cross-cutting rules |
| T2 | `.claude/stack.json` | Machine-readable fingerprint (TD commit, ADRs, service facts) |
| T3 | `.windsurf/rules/*.md` | Windsurf IDE mirror |
| T4 | `.trae/rules/*.md` | TRAE IDE mirror |

## What It Does NOT Do

- Does not modify methodology source (`methodologies/`, `.agents/skills/`, `.agents/workflows/`)
- Does not touch production code (`services/*/src/`)
- Does not modify design docs (`docs/ba/`, `docs/design-docs/`, `docs/technical-design/`, `docs/ux/`, `docs/adr/`, `docs/api-specs/`)
- Does not decide phasing, sprint assignment, calendar dates (Impl Planner owns that — Option C)
- Does not invent tech facts absent from TD (gap-warns instead; user must amend TD or override)
- Does not auto-commit changes (user decides)
- Does not skip HALT points (2-3 HALTs per run)
- Does not retrofit engineer subagents — they stay generic + read `.claude/rules/*.md` at runtime

## Safety Contract

- Hard-fails if TD not approved (fresh/regen modes)
- Hard-fails if required facts missing (project.name, service language+framework, database.engine, auth_flow)
- Backups existing files before overwrite (`.bak-<ISO-8601>`)
- Preserves `*.local.md` override files untouched
- Every generated stack-specific rule cites its TD/ADR source

## Related

- Workflow: `.agents/workflows/project-init.md`
- Development guide: `.andm/development-guide/project-init-workflow.md`
- Drift validator: `scripts/validate-rules-sync.sh`
- Glossary reference: `CLAUDE.md § Glossary (Option C Canonical Terms)`
