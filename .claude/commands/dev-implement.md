---
description: Implement an approved plan via the coder agent
argument-hint: [plan-path]
allowed-tools:
  - Agent
  - SendMessage
  - Bash(/bin/ls *)
---

# Dev Implement Command

## Execution Contract (non-negotiable)

You MUST delegate implementation to the `coder` subagent. Do not edit code yourself.

## Workflow

### Step 1: Resolve Plan

- Argument: `$ARGUMENTS`
- Latest plan: !`/bin/ls -t .dev-plan/*.md 2>/dev/null | head -1`

Use the argument if given, otherwise the latest plan. If both are empty, tell the user to run `/dev-plan` first and stop. (Glob/Grep skip gitignored `.dev-plan/` — rely on the values above.)

### Step 2: Invoke Coder

Use the Agent tool:

- subagent_type: coder
- description: Implement plan
- prompt: Implement the plan at <plan-path>. Tick each completed step in the plan file.

If the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." — at most twice.

### Step 3: Report

Show the files changed, remaining steps, and deviations. Suggest `/dev-test` next.
