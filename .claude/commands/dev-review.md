---
description: Review current changes via the reviewer agent
argument-hint: [base-branch]
allowed-tools:
  - Agent
  - Bash(/bin/ls *)
---

# Dev Review Command

## Execution Contract (non-negotiable)

You MUST delegate to the `reviewer` subagent. Do not review or fix code yourself.

## Workflow

### Step 1: Invoke Reviewer

Latest plan (may be empty): !`/bin/ls -t .dev-plan/*.md 2>/dev/null | head -1`

Use the Agent tool:

- subagent_type: reviewer
- description: Review changes
- prompt: Review all changes against base branch `$ARGUMENTS` (use `main` if empty), including uncommitted changes. Plan file: <plan-path or "none">.

### Step 2: Report

Show the verdict and findings exactly as returned. Do not fix anything.
