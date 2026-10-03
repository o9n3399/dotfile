---
description: Fix a bug reproduce-first — failing regression test, minimal root-cause fix, review, commit
argument-hint: [bug description] [--yes]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
---

# Dev Fix Command

Bug: $ARGUMENTS

## Execution Contract (non-negotiable)

Every step MUST be delegated via the Agent tool. Every agent prompt MUST start with `Mode: bug-fix.` so the preloaded `bug-fix` skill applies. You are forbidden from:

- Reading source code, editing files, or running tests/git yourself
- Accepting a fix whose report lacks the regression test's failing output before the fix
- Pushing — this command only commits

If the arguments contain `--yes`, skip the approval questions in Step 2 and Step 6 (approve plan, commit).

## Workflow

### Step 1: Plan

Agent(subagent_type: planner, prompt: "Mode: bug-fix. Plan a fix for: <bug>"). Capture the plan path.

**Fail-closed guardrail**: If the plan has no Reproduction or Root Cause, or the planner reports it cannot reproduce, show its output and stop.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run the planner with `Answers: <answers>` appended to the same prompt. Never approve a plan that still has blocking questions.

### Step 2: Approve

Read the plan, show Summary / Symptom / Root Cause / Steps, then AskUserQuestion: `Approve`, `Revise`, `Cancel`.

### Step 3: Red → Fix → Green

Agent(subagent_type: coder, prompt: "Mode: bug-fix. Implement <plan-path> red-first: write the regression test, run it and paste its failing output, and only then apply the root-cause fix and paste the passing output. If the test passes before the fix, stop without touching production code.").

**Fail-closed guardrail**: If the report lacks failing output before the fix, or the coder stopped because the test passed → the bug is not reproduced — report and stop.

### Step 4: Full Verify (max 3 iterations)

Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite."). On FAIL → Agent(subagent_type: coder, prompt: "Mode: bug-fix. Fix these failures for <plan-path>: <failures>") → repeat.

### Step 5: Review (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Mode: bug-fix. Review changes against main. Plan file: <plan-path>."). `CHANGES_REQUESTED` → coder fixes → back to Step 4 → review again with prompt: "Mode: bug-fix. Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."

### Step 6: Commit

AskUserQuestion: `Commit`, `Stop`. On commit → Agent(subagent_type: git-agent, prompt: "Commit the current changes as a fix (type `fix`) on a new `fix/<slug>` branch.").

## Output Summary

- Root cause (file:line)
- Regression test: red → green confirmed
- Review verdict, commits
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
