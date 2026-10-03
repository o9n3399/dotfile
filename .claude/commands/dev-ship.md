---
description: Verify, commit, then push and open a PR after user confirmation
argument-hint: [base-branch]
allowed-tools:
  - Agent
  - AskUserQuestion
---

# Dev Ship Command

Base branch: `$ARGUMENTS` (use `main` if empty)

## Execution Contract (non-negotiable)

You are forbidden from:

- Pushing when tests fail or the user has not confirmed in Step 3
- Running git or test commands yourself — delegate to the agents

## Workflow

### Step 1: Verify

Use the Agent tool with subagent_type `test-runner`, prompt: Run stages: lint, typecheck, full test suite.

**Fail-closed guardrail**: If the result is not `PASS`, show the failures and stop.

### Step 2: Commit

Use the Agent tool with subagent_type `git-agent`, prompt: Commit the current changes.

### Step 3: Confirm

Use AskUserQuestion: "Push and open a PR against <base>?" with options `Push + PR`, `Push only`, `Stop here`.

### Step 4: Ship

If confirmed, use the Agent tool with subagent_type `git-agent`, prompt: `ALLOW_PUSH=true` Push the current branch. Add `OPEN_PR=true` and "base branch: <base>" only if the user chose `Push + PR`.

Report the commits and PR URL.
