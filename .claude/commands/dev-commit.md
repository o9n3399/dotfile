---
description: Commit current changes via the git-agent (no push)
argument-hint: [hint for scope or message]
allowed-tools:
  - Agent
---

# Dev Commit Command

## Execution Contract (non-negotiable)

You MUST delegate to the `git-agent` subagent and MUST NOT include `ALLOW_PUSH=true` in the prompt.

## Workflow

### Step 1: Invoke Git Agent

Use the Agent tool:

- subagent_type: git-agent
- description: Commit changes
- prompt: Commit the current changes. Hint from user: $ARGUMENTS

### Step 2: Report

Show the branch and commits created.
