---
name: andm-next-context-distiller
description: Distill `.agents/workflows/next.md` into a runtime-only context pack for agents that implement, review, or optimize `/next`. Use this whenever the user asks to shrink `next.md`, debug wrong `/next` recommendations, extract only the rules an agent truly needs, or benchmark whether the navigation workflow can be compressed without losing blocking logic, command routing, or the mandatory output contract.
---

# ANDM `/next` Context Distiller

Turn the huge `next.md` workflow into a smaller, testable runtime packet.

The point is not "summarize nicely." The point is to preserve what changes agent behavior and throw away the ceremony.

## Read First

- `references/filtering-rubric.md`
- `references/required-anchors.json`

Read the rubric when you need to explain or tune the filtering logic.
Read the anchors file when you need the exact runtime coverage contract.

## What This Skill Produces

- `distilled-context.md`:
  - human-readable runtime context
  - only headings and rules needed to execute `/next`
- `distilled-context.json`:
  - structured sections, commands, and coverage metadata
- evaluation report:
  - heading coverage
  - command coverage
  - phrase coverage
  - compression ratio
  - banned-marker check

## Workflow

1. Confirm the source workflow path.
2. Run the distiller script.
3. Run the evaluator immediately after distillation.
4. If coverage fails, inspect missing headings or commands before using the output.
5. Present the distilled packet plus the evaluation result.
6. If the user wants a tighter pack, adjust the rules file or filtering rubric, then rerun extraction and evaluation.

## Commands

From the skill directory:

```bash
python scripts/distill_next_context.py --source ../../workflows/next.md --output-dir ./distilled
python scripts/evaluate_distillation.py --source ../../workflows/next.md --output ./distilled/evaluation.json
python -m unittest discover -s tests
```

Requires Python 3.10+ (`X | Y` union syntax in type hints).

If no `--source` is provided, the scripts default to the repo's `next.md`.

## Filtering Rules

Keep:
- executable checks
- stop conditions
- exact commands
- routing exclusions
- the one-primary-action decision layer
- the report/output contract

Compress:
- long rationale
- duplicated explanations
- examples that do not add new behavior

Drop:
- historical commentary
- reviewer attribution
- scenario-matrix detail that already exists as explicit rules or tests

## Acceptance Standard

Do not trust the distilled context unless all of these are true:

- heading coverage >= 95%
- command coverage >= 95%
- phrase coverage = 100%
- compression ratio <= 60%
- banned-marker hits = 0

If any check fails, say the packet is unsafe for runtime use and fall back to the original workflow or refine the rules first.

## Output Contract

When reporting results, always include:

```markdown
## Distillation Result
- Source:
- Output files:
- Heading coverage:
- Command coverage:
- Phrase coverage:
- Compression ratio:
- Risk:

## Kept Runtime Blocks
- ...

## Dropped Noise
- ...

## Recommendation
- Safe to use / Unsafe to use
- Next step
```

## Tests

Run these before trusting a rules change:

- `python -m unittest tests.test_distill_next_context`
- `python -m unittest discover -s tests`
- `python scripts/evaluate_distillation.py`

The tests are intentionally boring. Good. Boring is how you stop yourself from shipping a fake optimization.
