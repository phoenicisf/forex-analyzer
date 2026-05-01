# ANDM Full Track Methodology

> Full QA-gated AI-Native Development Methodology (ANDM) lifecycle — designed for large projects that need strong governance, auditable decisions, and adversarial review at every phase.

## When to Use This Methodology

| Use it when... | Don't use it when... |
|---------------|---------------------|
| Project spans multiple modules/services | Single-file POC or throwaway prototype |
| Compliance/audit trail is required | Solo developer exploring an idea |
| 3+ engineers coordinate deliverables | Time budget measured in hours |
| Design decisions have long-term cost | Spec is still being discovered |
| Stakeholders need formal sign-off | You need to ship end-of-day |

For small/fast work, use **[ANDM Lean Track](../lean-track/README.md)** instead. Decision help: [../README.md](../README.md).

## What's Inside

| Folder | Purpose |
|--------|---------|
| `constitution/` | Runbook (source of truth for the 5-phase lifecycle) + slim CLAUDE.md template for downstream projects |
| `development-guide/` | Step-by-step guides per phase (BA, SD, UX, TD, impl, QA, red-team, backtrack) |
| `skills/` | 46 agent personas (reviewers, defenders, engineers) + `_core-behaviors.md` |
| `workflows/` | 22 platform-agnostic workflow definitions + `manifest.json` registry |
| `prompt-templates/` | Direct-use prompts for BA, System Design, UX, TD |
| `agents/` | 11 Claude Code subagents (name/description frontmatter + runbook body) — auto-discoverable when assembled to `.claude/agents/` via `scripts/assemble-agents.sh` |
| `npx-skills-reference.txt` | External skill install reference |

## 5-Phase Lifecycle

```
Phase 0: IDEATION   → Optional — refine a vague idea into a spec
Phase 1: DESIGN     → BA + System Design + UX/UI + Technical Design
Phase 2: DESIGN QA  → Adversarial review + rebuttal loops (BA, SD, UX, TD)
Phase 3: IMPLEMENT  → Impl plan (P1→P2→P3→P4) + task execution + code review
Phase 4: HARDEN     → Red team security audit + defense
Phase 5: DELIVER    → Knowledge base + final handoff + metrics
```

Full details: [`constitution/ai-native-development-runbook.md`](constitution/ai-native-development-runbook.md) · [`development-guide/full-journey.md`](development-guide/full-journey.md)

## IDE Setup

Commands are surfaced through IDE-specific adapters at the repo root. Both adapters delegate to the source workflows in `workflows/`.

- **Claude Code** — slash commands live in `.claude/commands/` at repo root. Invoke with `/ba`, `/sd`, `/td`, `/ba-review`, `/sd-review`, `/td-review`, `/impl-plan`, etc.
- **Windsurf** — workflows live in `.windsurf/workflows/` at repo root. Same command names.
- **Gemini CLI** — workflows live in `.gemini/workflows/` at repo root. Load via `@.gemini/workflows/<name>.md` or point your runner at the file directly.
- **Other IDEs (Cursor, Antigravity, etc.)** — point your workflow runner at `.agents/workflows/<name>.md` directly, or mirror the `.claude/commands/` pattern.

## Command Reference

See the root [`CLAUDE.md`](../../CLAUDE.md) § Workflow Commands for the full 29-command table, or [`workflows/manifest.json`](workflows/manifest.json) for the machine-readable registry.

## Core Behaviors

Every agent in this methodology adheres to [`skills/_core-behaviors.md`](skills/_core-behaviors.md) — 6 behavioral rules (surface assumptions, manage confusion, push back, enforce simplicity, maintain scope, verify don't assume).
