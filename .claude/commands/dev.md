---
description: Full workflow — plan, implement, test, review, commit — using the dev agents
argument-hint: [task description]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
---

# Dev Orchestrator Command

Task: $ARGUMENTS

## Execution Contract (non-negotiable)

You are an orchestrator. Every step MUST be delegated via the Agent tool to its subagent. You are forbidden from:

- Reading source code, editing files, or running tests/git yourself
- Skipping user approval of the plan (Step 2)
- Pushing without explicit user confirmation (Step 6)

## Workflow

### Step 1: Plan

Agent(subagent_type: planner, prompt: "Write an implementation plan for: $ARGUMENTS"). Capture the plan path.

**Fail-closed guardrail**: No plan path → report and stop.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run the planner with `Answers: <answers>` appended to the same prompt. Never approve a plan that still has blocking questions.

### Step 2: Approve

Read the plan file, show Summary / Proposed Change / Steps / Risks (plus the path for the full plan), then AskUserQuestion: `Approve`, `Revise` (collect feedback → back to Step 1 with it), `Cancel`.

### Step 3: Implement

Agent(subagent_type: coder, prompt: "Implement the plan at <plan-path>").

### Step 4: Test Loop (max 3 iterations)

Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite.").
- `PASS` → Step 5
- `FAIL` → Agent(subagent_type: coder, prompt: "Fix these failures for plan <plan-path>: <failures>") → repeat Step 4
- After 3 failed iterations, or `ENV_MISSING` / `NO_TESTS_DETECTED` → show the result and ask the user whether to continue

### Step 5: Review + UI Verify Loop (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Review changes against main. Plan file: <plan-path>").
In parallel when triggered: Agent(subagent_type: ui-verifier, prompt: "Verify the UI Checks of <plan-path>.").

**UI verify trigger**: the plan has a `## UI Checks` section, or the coder's changed files include `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.html`, `*.css`, `*.scss`. When triggered, launch `ui-verifier` in the same message as the reviewer — both are read-only on code. `ENV_MISSING` from ui-verifier is not a failure: show what it needs and continue.

- Reviewer `APPROVE` and ui-verifier `PASS`/`ENV_MISSING`/not triggered → Step 6
- Otherwise → one Agent(subagent_type: coder, prompt: "Fix these findings for plan <plan-path>: <CRITICAL/HIGH review findings> <UI failures>") → back to Step 4
- Second iteration: reviewer prompt "Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."; ui-verifier prompt "Re-verify only these failed UI Checks of <plan-path>: <failed checks>."
- Still failing after 2 iterations → show remaining findings and ask the user whether to continue

### Step 6: Ship

AskUserQuestion: `Commit only`, `Commit + push + PR`, `Stop (leave uncommitted)`.
Then Agent(subagent_type: git-agent):
- `Commit only` → prompt: "Commit the current changes."
- `Commit + push + PR` → prompt: "ALLOW_PUSH=true OPEN_PR=true Commit the current changes, push, and open a PR against main."

## Output Summary

- Plan path and steps completed
- Test result, review verdict (with remaining LOW findings), UI verify result
- Commits and PR URL (if any)
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
