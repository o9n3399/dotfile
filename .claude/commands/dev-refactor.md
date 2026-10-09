---
description: Behavior-preserving refactor — green baseline, small steps each kept green, review, commit
argument-hint: [scope and goal] [--yes]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Read
---

# Dev Refactor Command

Refactor: $ARGUMENTS

## Execution Contract (non-negotiable)

Every step MUST be delegated via the Agent tool. Every planner/coder/reviewer prompt and coder message MUST start with `Mode: refactor.` so the preloaded `refactor` skill applies. You are forbidden from:

- Reading source code, editing files, or running tests/git yourself
- Starting implementation on a red baseline
- Pushing — this command only commits

If the arguments contain `--yes`, skip the approval questions in Step 2 and Step 7.

## Cost Rules

- **Reuse the coder**: keep the agent ID of the first coder call. Send every later fix to it with SendMessage (still prefixed `Mode: refactor.`) instead of spawning a new coder — it already holds the plan and the files it changed. Spawn a new coder only if SendMessage fails.
- **Unfinished coder**: if the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." before testing — at most twice, then report the remaining steps and stop.
- **Full suite only at checkpoints**: the Step 1 baseline, the first Step 4 run and the Final Gate run the full suite. Every re-run after a fix uses `Run stages: lint, typecheck, scoped tests. Scope to: <files changed by the fix> <failing test files>.`

## Workflow

### Step 1: Baseline + Plan (parallel)

Launch both agents in the same message — they are independent:
- Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite.")
- Agent(subagent_type: planner, prompt: "Mode: refactor. Plan this refactor: <scope and goal>"). Capture the plan path.

**Fail-closed guardrail**: If the baseline is not PASS, show failures and stop — refactoring on red hides regressions.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run only the planner with `Answers: <answers>` appended to the same prompt. Never approve a plan that still has blocking questions.

### Step 2: Approve

Read the plan, show Summary / Proposed Change / Behavior Contract / Steps / Risks, then AskUserQuestion: `Approve`, `Revise` (re-run planner with feedback), `Cancel`.

### Step 3: Implement

Agent(subagent_type: coder, prompt: "Mode: refactor. Implement all unchecked steps of <plan-path> in order, running each step's Verify before the next."). Keep its agent ID.

If the coder reports a step it had to undo → show why and stop.

### Step 4: Final Verify (max 2 fix iterations)

First run: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite."). Every re-run is scoped (see Cost Rules).
- `PASS` → Step 5
- `FAIL` → SendMessage to the coder: "Mode: refactor. The refactor of <plan-path> broke these tests: <failures>. Fix the refactored code to restore the original behavior." → repeat Step 4
- Still `FAIL` after 2 fixes → show failures and stop

### Step 5: Review (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Mode: refactor. Review changes against main for behavior changes. Plan file: <plan-path>."). `CHANGES_REQUESTED` → SendMessage to the coder with the findings → Step 4 → review again with prompt: "Mode: refactor. Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."

### Step 6: Final Gate

Only if a fix landed after the last full-suite `PASS`: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite."). `FAIL` → show the failures and stop.

### Step 7: Commit

AskUserQuestion: `Commit`, `Stop`. On commit → Agent(subagent_type: git-agent, prompt: "Commit the current changes as a refactor (type `refactor`) on a new `refactor/<slug>` branch.").

## Output Summary

- Steps completed / undone
- Final test status, review verdict, commits
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
