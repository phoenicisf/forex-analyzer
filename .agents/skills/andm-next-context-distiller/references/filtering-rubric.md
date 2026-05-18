# Filtering Rubric

Use this rubric when distilling `next.md` into a runtime context pack for an agent.

## Goal

Preserve only the context that changes the agent's decision, command recommendation, stopping behavior, confidence, or report contract.

## Keep

- Operational checks the agent must execute in order:
  - onboarding reads
  - pre-checks
  - numbered checks
  - phase gates
  - the navigation decision layer
  - the output/report contract
- Deterministic tie-breakers and priority tables that decide one primary action.
- Output templates the agent must follow exactly.
- Stop conditions, override rules, and "do not progress" rules.
- Concrete commands, registries, file paths, and command-routing constraints.
- Short rationale only when removing it would make the rule ambiguous.

## Compress

- Long explanations of why a check exists.
- Repeated examples after the rule is already unambiguous.
- Duplicate phrasing across sequential sections.
- Expanded scenario prose that can be reduced to a one-line regression case.
- Redundant advisory text if the same instruction appears in a stronger normative block.

## Drop

- Historical storytelling that does not change runtime behavior.
- Reviewer attribution such as `review-from-gptX`.
- Editorial flourish, repetition, and motivational prose.
- Scenario matrix details after the expected behavior has been converted into explicit rules or tests.
- Explanations of things already encoded by a table, checklist, or deterministic algorithm.

## Do Not Damage

- Do not remove a heading that represents a real executable check.
- Do not remove a command the workflow can recommend.
- Do not remove a `STOP` gate, a "do not progress" rule, or a route exclusion like "NOT `/backtrack impl`".
- Do not weaken the "one primary action" contract.
- Do not convert blocking logic into advisory language.
- Do not preserve examples if they crowd out mandatory runtime rules.

## Quality Heuristics

- Heading coverage: keep at least 95% of runtime headings.
- Command coverage: keep at least 95% of recommendable commands.
- Compression target: 35-60% of original lines.
- Narrative tax: if a paragraph explains history only, it should be first on the chopping block.
- Ambiguity check: if a reviewer cannot tell what to do next from the distilled output, the distillation failed.
