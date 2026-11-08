---
description: Run lint, typecheck and tests via the test-runner agent
model: sonnet
argument-hint: [path] [--full]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
---

# Dev Test Command

## Execution Contract (non-negotiable)

You MUST delegate to the `test-runner` subagent. Do not run test commands yourself.

## Workflow

### Step 1: Invoke Test Runner

Use the Agent tool:

- subagent_type: test-runner
- description: Run project checks
- prompt: If `$ARGUMENTS` contains `--full`: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo root>." Otherwise: "Run stages: lint, typecheck, scoped tests. Repos: <absolute repo root>. Changed files: <path from arguments, or `git diff --name-only HEAD` if none>."

### Step 2: Report

Show the result as returned; never end with a prose question or a "next step" suggestion.

`FAIL` with `NEW` failures → AskUserQuestion: `Send to coder + re-run`, `Stop`. Send → SendMessage the coder of this conversation (else Agent(subagent_type: coder)) "Fix these failures: <failures>", then Step 1 scoped to the fixed and failing files and this step again. Only `PRE-EXISTING` failures → list them and end. `ENV_MISSING` / `NO_TESTS_DETECTED` → show what is missing and end.
