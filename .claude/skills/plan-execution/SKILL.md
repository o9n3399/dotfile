---
name: plan-execution
description: Rules for executing a .dev-plan/*.md plan step by step
user-invocable: false
---

# Plan Execution Skill

## Task

Implement an approved plan while keeping the plan file as the single source of progress.

## Instructions

1. Work on unchecked steps `- [ ]` in order. One step at a time.
2. After finishing a step, run its `Verify:` check if it is cheap (single test file, typecheck). Leave full suites to `test-runner`.
3. Tick the step `- [x]` in the plan file only after it is implemented.
4. If you deviate from the plan, append a line under the step: `- Deviation: <what and why>`.
5. When given test failures or review findings instead of steps, fix exactly those items and nothing else.
6. Never skip a step to move on — if you can't finish it, leave it unchecked and name it under Remaining with the reason.

## Expected Output

Code changes plus an updated plan file whose checkboxes reflect reality.

## Gotchas

- Never tick a step you only partially did
- Before Write, check the path exists — overwriting an existing file (e.g. a `*.spec.ts`) loses its tests; use Edit
- New code is held to the bug-fix bar too: a route is done only after one real call returns the expected shape
- Fixing a failing test by editing the assertion is a deviation — report it, don't hide it
