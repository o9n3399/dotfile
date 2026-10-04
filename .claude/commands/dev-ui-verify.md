---
description: Verify web screens in a real browser via the ui-verifier agent (Playwright MCP)
argument-hint: [route... | plan-path]
allowed-tools:
  - Agent
  - Bash(/bin/ls *)
---

# Dev UI Verify Command

## Execution Contract (non-negotiable)

You MUST delegate to the `ui-verifier` subagent. Do not drive the browser or fix code yourself.

## Workflow

### Step 1: Resolve Checks

- Arguments: `$ARGUMENTS`
- Latest plan: !`/bin/ls -t .dev-plan/*.md 2>/dev/null | head -1`

Routes in the arguments → verify those. A plan path in the arguments, else the latest plan → verify its `## UI Checks`. Neither → let the agent derive routes from changed frontend files.

### Step 2: Invoke UI Verifier

Agent(subagent_type: ui-verifier, prompt: "Verify <routes | the UI Checks of <plan-path> | the screens affected by the uncommitted frontend changes>.").

### Step 3: Report

Show the result as returned. On `FAIL`, suggest passing the failures to `coder`; on `ENV_MISSING`, show what the project's `CLAUDE.md` needs (base URL, start command, credential env vars).
