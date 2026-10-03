---
name: bug-fix
description: Reproduce-first rules for planning, fixing and reviewing a bug fix
user-invocable: false
---

# Bug Fix Skill

## Task

Fix a bug at its root cause, proven by a regression test that fails before the fix and passes after.

## Instructions

Apply only when the prompt says the mode is **bug-fix**.

**Planner**
1. Add these sections to the top of the plan (before Steps):
   - `## Symptom` — observed vs expected behavior
   - `## Reproduction` — exact input/state that triggers it
   - `## Root Cause` — file:line and why it happens (not just where it crashes)
2. Steps are always:
   - Step 1: add a regression test that reproduces the bug — `Verify:` the test FAILS
   - Step 2: minimal fix at the root cause — `Verify:` the test PASSES and the full suite is green
3. Grep for the same faulty pattern elsewhere and list hits under Risks.

**Coder**
1. Step 1 writes only the test, then run it and include the failing output in the report. If it passes, stop — do not touch production code.
2. Step 2 changes the fewest lines that fix the root cause, then rerun the test and include the passing output.

**Reviewer**
1. Confirm the fix addresses the root cause, not the symptom.
2. Confirm the regression test would fail if the fix were reverted.
3. Check other call sites with the same pattern.

## Gotchas

- Never "fix" by swallowing errors (`try/catch` that ignores, `?.` sprinkled to hide undefined)
- Never raise timeouts or add retries to make a flaky test pass — find the race
- If the bug can't be reproduced, stop and report — don't fix blind
