---
name: refactor
description: Behavior-preserving rules for planning, executing and reviewing a refactor
user-invocable: false
---

# Refactor Skill

## Task

Change code structure without changing observable behavior, keeping the test suite green after every step.

## Instructions

Apply only when the prompt says the mode is **refactor**.

**Planner**
1. Add `## Behavior Contract` before Steps: what must stay identical (public API, outputs, side effects, errors).
2. Split into at most 5 steps; each is one complete mechanical change that leaves the code compiling. `Verify:` for every step is typecheck plus the tests covering the touched files — the full suite runs once after the last step.
3. If existing tests don't cover the code being moved, Step 1 adds characterization tests (lock current behavior, even if odd).
4. Any public API change goes under Risks with every caller listed.

**Coder**
1. One step at a time; run the step's `Verify:` before starting the next. If it fails, undo only that step's edits and stop with a report — don't patch forward. Don't use `git restore`: earlier steps are uncommitted too and would be wiped.
2. Don't modify existing tests except for renames/import paths forced by the refactor.
3. No new features, no bug fixes mixed in — note spotted bugs in the report instead.

**Reviewer**
1. Diff behavior, not just code: same inputs → same outputs, same errors, same side effects.
2. Flag any modified assertion in existing tests as HIGH.
3. Flag leftover dead code or duplicate old/new paths.

## Gotchas

- Grep misses implicit references: DI tokens, reflection, string keys, dynamic imports, config files, serialized field names
- Renaming a serialized/DB field is a data migration, not a refactor
- "While I'm here" changes break the behavior contract — put them in a separate task
