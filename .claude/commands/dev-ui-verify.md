---
description: Verify web screens in a real browser via the ui-verifier agent (Playwright MCP)
argument-hint: [route... | plan-path]
allowed-tools:
  - Agent
  - Bash(/bin/ls *)
  - Bash(grep *)
  - Bash(git rev-parse *)
---

# Dev UI Verify Command

## Execution Contract (non-negotiable)

You MUST delegate to the `ui-verifier` subagent. Do not drive the browser or fix code yourself.

## Workflow

### Step 1: Resolve Checks

- Arguments: `$ARGUMENTS`
- Latest plan: !`/bin/ls -t .dev-plan/ 2>/dev/null | grep -m1 '\.md$'` (a file name inside `.dev-plan/`)
- Project root: !`git rev-parse --show-toplevel 2>/dev/null`

Routes in the arguments → verify those. A plan path in the arguments, else the latest plan → verify its `## UI Checks`. Neither → let the agent derive routes from changed frontend files.

### Step 2: Invoke UI Verifier

Agent(subagent_type: ui-verifier, prompt: "Verify <routes | the UI Checks of <plan-path> | the screens affected by the uncommitted frontend changes>.").

### Step 3: Report

If the result has `Not checked:` items, re-invoke the agent once with "Verify only these checks of <plan-path>: <items>." and merge both reports.
Show the result, including `Created data:` so the user can clean it up. On `FAIL`, suggest passing the failures to `coder`; on `ENV_MISSING`, show what the project's `CLAUDE.md` needs (base URL, start command, credential env vars).
