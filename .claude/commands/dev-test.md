---
description: Run lint, typecheck and tests via the test-runner agent
argument-hint: [path] [--full]
allowed-tools:
  - Agent
---

# Dev Test Command

## Execution Contract (non-negotiable)

You MUST delegate to the `test-runner` subagent. Do not run test commands yourself.

## Workflow

### Step 1: Invoke Test Runner

Use the Agent tool:

- subagent_type: test-runner
- description: Run project checks
- prompt: If `$ARGUMENTS` contains `--full`: "Run stages: lint, typecheck, full test suite." Otherwise: "Run stages: lint, typecheck, scoped tests. Scope to: <path from arguments, or files changed in git diff if none>."

### Step 2: Report

Show the result as returned. On failure, suggest passing the failures to `coder`.
