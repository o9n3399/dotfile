---
description: Behavior-preserving refactor — green baseline, small steps each kept green, review, commit
argument-hint: [scope and goal] [--ask] [--lite]
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
- Stopping or asking outside the stop points of skill `dev-pipeline-stops`, or ending a turn with a prose question — every question is an AskUserQuestion popup

Flags follow skill `dev-pipeline-stops`: by default (`--yes`) skip the approval questions in Step 2 and Step 7; `--ask` asks both.

If the arguments contain `--lite` (small, low-risk refactors), strip it from the task text and pass `model: sonnet` on every planner and reviewer Agent call.

## Cost Rules

- **Reuse the coder**: keep the agent ID of the first coder call. Send every later fix to it with SendMessage (still prefixed `Mode: refactor.`) instead of spawning a new coder — it already holds the plan and the files it changed. Spawn a new coder only if SendMessage fails.
- **Unfinished coder**: if the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." before testing — at most twice, then report the remaining steps and stop.
- **Full suite only at checkpoints**: the Step 1 baseline, the first Step 4 run and the Final Gate run the full suite. Every re-run after a fix uses `Run stages: lint, typecheck, scoped tests. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed by the fix> <failing test files>.`

## Workflow

### Step 1: Baseline + Plan (parallel)

Launch both agents in the same message — they are independent:
- Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>.")
- Agent(subagent_type: planner, prompt: "Mode: refactor. Plan this refactor: <scope and goal>"). Capture the plan path.

**Fail-closed guardrail**: If the baseline is not PASS, show failures and stop — refactoring on red hides regressions.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run only the planner with `Answers: <answers>` appended to the same prompt. Never approve a plan that still has blocking questions. A typed answer (the free-text "Other" option) is still a popup answer: record it as the user's decision and ask every remaining question with AskUserQuestion too — never switch to plain chat text unless the user dismisses the popup or asks to discuss.

### Step 2: Approve

Read the plan, show Summary / Proposed Change / Behavior Contract / Steps / Risks. Unless `--ask`, go straight to Step 3. Under `--ask`, AskUserQuestion: `Approve`, `Revise` (re-run planner with feedback; ask again only if the revised Steps or Risks changed), `Cancel`.

### Step 3: Implement

Agent(subagent_type: coder, prompt: "Mode: refactor. Implement all unchecked steps of <plan-path> in order, running each step's Verify before the next."). Keep its agent ID.

If the coder reports a step it had to undo → show why and stop.

### Step 4: Final Verify (max 2 fix iterations)

First run: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). Every re-run is scoped (see Cost Rules).
- `PASS` → Step 5
- `FAIL` → SendMessage to the coder: "Mode: refactor. The refactor of <plan-path> broke these tests: <failures>. Fix the refactored code to restore the original behavior." → repeat Step 4
- Still `FAIL` after 2 fixes → show failures and stop

### Step 5: Review (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Mode: refactor. Review the uncommitted changes against <base branch> (`develop` for service repos, `staging` for web, per `commit-convention`) for behavior changes. Plan file: <plan-path>."). `CHANGES_REQUESTED` → SendMessage to the coder with the findings → Step 4 → review again with prompt: "Mode: refactor. Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."

### Step 6: Final Gate

Only if a fix landed after the last full-suite `PASS`: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). `FAIL` → show the failures and stop.

### Docs Update

Only when the refactor moved or renamed files, components or endpoints that the service docs reference (update paths and links; no behavior text changes). Agent(subagent_type: doc-writer, prompt: "Mode: topic. Service: `<dir of each repo in the plan>`. Topic: derive it from <plan-path> and the existing `docs/*.md`. Plan: <plan-path>. Update the docs in place per the feature-docs skill; if no doc update is needed report `no doc change needed`."). Add the files it reports to the commit file list. Runs before the commit so docs ship in the same commit; the writer edits Markdown only and never commits.

### Step 7: Commit

Under `--ask`, AskUserQuestion: `Commit`, `Stop`; otherwise commit without asking. Commit → Agent(subagent_type: git-agent, prompt: "Commit the current changes as a refactor (type `refactor`) on the current branch `<base branch>` per `commit-convention`; never create, switch or checkout a branch (`develop` for services, `staging` for web; a `refactor/<slug>` branch only if the user asked).").

## Output Summary

- Steps completed / undone
- Final test status, review verdict, commits
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
