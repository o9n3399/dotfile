---
description: Implement an approved plan via the coder agent
argument-hint: [plan-path]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Bash(/bin/ls *)
  - Bash(grep *)
  - Bash(git rev-parse *)
---

# Dev Implement Command

## Execution Contract (non-negotiable)

You MUST delegate implementation to the `coder` subagent. Do not edit code yourself.

## Workflow

### Step 1: Resolve Plan

- Argument: `$ARGUMENTS`
- Latest plan: !`/bin/ls -t .dev-plan/ 2>/dev/null | grep -m1 '\.md$'` (a file name inside `.dev-plan/`)
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`

Use the argument if given, otherwise `.dev-plan/<latest plan>`.
A bare `.dev-plan/*.md` glob errors with `no matches found` on zsh — never use it.
If the latest plan is empty and the project root differs from the cwd, run `/bin/ls -t <root>/.dev-plan/` and take the newest `.md`.
If still empty, tell the user to run `/dev-plan` first and stop. (Glob/Grep skip gitignored `.dev-plan/` — rely on the values above.)

### Step 2: Invoke Coder

Use the Agent tool:

- subagent_type: coder
- description: Implement plan
- prompt: Implement the plan at <plan-path>. Tick each completed step in the plan file. Run the Live Check for every changed route.

If the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." — at most twice.
Steps still unchecked after that are never dropped: list them by number at the top of the report and ask the user (AskUserQuestion: `Continue coder`, `Leave for later`).

### Definition of Done

Report the change as done only when every item holds; otherwise report it as `incomplete` with the failing items:
- [ ] Every plan step ticked, or the user chose `Leave for later` for it
- [ ] typecheck and the tests covering the change pass
- [ ] Service restarted and every changed route called for real (`Live API check: yes`)
- [ ] `## UI Checks` in the plan → `/dev-ui-verify` still pending, say so

### Step 3: Report

Show the Definition of Done, files changed, remaining steps, deviations and the live API check.
Suggest the next steps in order: `/dev-review` → `/dev-test` → `/dev-ui-verify` (when the plan has UI Checks).
After a fix for review findings, the next step is `/dev-review` again — a re-review of the fixed files.
