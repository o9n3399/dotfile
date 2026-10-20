---
description: Full workflow — plan, implement, test, review, commit — using the dev agents
argument-hint: [task description] [--lite] [--yes] [--auto]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Read
---

# Dev Orchestrator Command

Task: $ARGUMENTS

## Execution Contract (non-negotiable)

You are an orchestrator. Every step MUST be delegated via the Agent tool to its subagent. You are forbidden from:

- Reading source code, editing files, or running tests/git yourself
- Skipping user approval of the plan (Step 2), unless `--yes` or `--auto` is given
- Pushing without explicit user confirmation (Step 7)

## Flags

Strip every flag from the task text; `<task>` below means the text without flags.

- **`--yes`**: skip the Step 2 approval (still show the plan summary) and answer Step 7 with `Commit only`. Never push.
- **`--auto`**: implies `--yes`, and nothing asks the user:
  - Open Questions → pick the planner's recommended candidate (else the first) for each and re-run the planner with `Answers (auto-chosen; record each under ## Assumptions in the plan): <answers>`.
  - Every "ask the user whether to continue" point → stop there instead, leave the changes uncommitted and report why.

## Cost Rules

- **`--lite`** (small, low-risk changes): strip it from the task text and pass `model: sonnet` on every planner and reviewer Agent call.
- **Reuse the coder**: keep the agent ID of the first coder call. Send every later fix to it with SendMessage instead of spawning a new coder — it already holds the plan and the files it changed. Spawn a new coder only if SendMessage fails.
- **Unfinished coder**: if the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." before reviewing — at most twice, then list the remaining steps by number, ask the user whether to continue the coder or leave them, and record the choice in the summary.
- **Full suite at most twice**: only the first test run and the Final Gate run the full suite. Every re-run after a fix uses `Run stages: lint, typecheck, scoped tests. Scope to: <files changed by the fix> <failing test files>.`

## Workflow

### Step 1: Plan

Agent(subagent_type: planner, prompt: "Write an implementation plan for: <task>"). Capture the plan path.

**Fail-closed guardrail**: No plan path → report and stop.

**Open Questions**: if the planner reports blocking questions (under `--auto`, see Flags), ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run the planner with `Answers: <answers>` appended to the same prompt. Never approve a plan that still has blocking questions.

### Step 2: Approve

Read the plan file, show Summary / Proposed Change / Steps / Risks (plus the path for the full plan). Under `--yes`/`--auto`, go straight to Step 3; otherwise AskUserQuestion: `Approve`, `Revise` (collect feedback → back to Step 1 with it), `Cancel`.

### Step 3: Implement

Agent(subagent_type: coder, prompt: "Implement the plan at <plan-path>. Run the Live Check for every changed route."). Keep its agent ID.
Order from here: code → restart + live API check (coder) → review → tests → UI. The coder owns the restart.
`Live API check: no` with a reason other than "no HTTP route changed" → show it and ask the user whether to continue.

### Step 4: Review Loop (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Review changes against main. Plan file: <plan-path>").
- `APPROVE` → Step 5
- Otherwise → SendMessage to the coder: "Fix these findings for plan <plan-path>, then re-run the Live Check for the touched routes: <CRITICAL/HIGH findings>" → re-review
- Every review after a fix is a re-review: "Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."
- Still failing after 2 iterations → show remaining findings and ask the user whether to continue

### Step 5: Test Loop (max 3 iterations)

First run: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite."). Every re-run is scoped (see Cost Rules).
- `PASS` → Step 6
- `FAIL` with only `PRE-EXISTING` failures → list them in the summary, continue to Step 6
- `FAIL` with `NEW` failures → SendMessage to the coder: "Fix these failures for plan <plan-path>: <failures>" → repeat Step 5
- After 3 failed iterations, or `ENV_MISSING` / `NO_TESTS_DETECTED` → show the result and ask the user whether to continue

A fix in this loop changes code the reviewer already approved: re-review the fixed files once (Step 4 re-review prompt) before Step 6.

### Step 6: UI Verify Loop (max 2 iterations)

Only when the plan has a `## UI Checks` section — the planner adds one whenever the change touches web UI.
Agent(subagent_type: ui-verifier, prompt: "Verify the UI Checks of <plan-path>.").
- `Not checked:` items → re-invoke once with "Verify only these checks of <plan-path>: <items>." and merge the reports
- `PASS` / `ENV_MISSING` (show what it needs) → Final Gate
- `FLAKY` items → show them, not a failure
- `FAIL` → SendMessage to the coder with the failures → Step 4 re-review of the fixed files → "Re-verify only these failed UI Checks of <plan-path>: <failed checks>."
- Still failing after 2 iterations → show remaining failures and ask the user whether to continue

### Final Gate

Only if a fix landed after the last full-suite `PASS`: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite."). `FAIL` with `NEW` failures → show them and ask the user whether to continue.

### Step 7: Ship

Under `--yes`/`--auto`, use `Commit only` without asking. Otherwise AskUserQuestion: `Commit only`, `Commit + push + PR`, `Stop (leave uncommitted)`.
Then Agent(subagent_type: git-agent):
- `Commit only` → prompt: "Commit the current changes."
- `Commit + push + PR` → prompt: "ALLOW_PUSH=true OPEN_PR=true Commit the current changes, push, and open a PR against main."

## Output Summary

- Plan path and steps completed
- Under `--auto`: every auto-chosen answer, so the user can check the assumptions
- Live API check, review verdict (with remaining LOW findings), test result with `Scope` and pre-existing failures, UI verify result
- `Created data:` from ui-verifier, so the user can clean it up
- Commits and PR URL (if any)
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
