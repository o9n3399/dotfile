---
description: Review current changes via the reviewer agent
model: sonnet
argument-hint: [base-branch]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Bash(/bin/ls *)
  - Bash(grep *)
  - Bash(git rev-parse *)
  - Bash(pwd)
---

# Dev Review Command

## Execution Contract (non-negotiable)

You MUST delegate to the `reviewer` subagent. Do not review or fix code yourself.

## Workflow

### Step 1: Invoke Reviewer

Latest plan (may be empty): !`/bin/ls -t .dev-plan/ 2>/dev/null | grep -m1 '\.md$'` (a file name inside `.dev-plan/`)
- Project root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`

Use the Agent tool:

- subagent_type: reviewer
- description: Review changes
- prompt: Review all changes against base branch `$ARGUMENTS` (if empty: `develop` for service repos, `staging` for web, per `commit-convention`), including uncommitted changes. Plan file: <plan-path or "none">.

If the coder just fixed findings from an earlier review in this conversation, use the re-review prompt instead:
"Re-review. Previous findings: <findings>. Files changed by the fix: <files>. Plan file: <plan-path>."

### Step 2: Report

Show the verdict and findings exactly as returned. Do not fix anything yourself, and never end with a prose question or a "next step" suggestion.

`CHANGES_REQUESTED` with CRITICAL/HIGH findings → AskUserQuestion: `Send to coder + re-run`, `Stop`. Send → SendMessage the coder of this conversation (else Agent(subagent_type: coder)) "Fix these findings for plan <plan-path or "none">: <CRITICAL/HIGH findings>", then Step 1 with the re-review prompt and this step again. Only LOW or format/doc findings → list them and end.
