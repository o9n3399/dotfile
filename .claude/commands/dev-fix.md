---
description: "Bug fix: red test → root-cause fix → review → commit · --ask: ask approval/ship · --push: push + staging · --lite: sonnet · --no-auto: ask open questions"
argument-hint: [bug description] [--ask] [--push] [--lite] [--no-auto]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Read
---

# Dev Fix Command

Bug: $ARGUMENTS

## Execution Contract (non-negotiable)

Every step MUST be delegated via the Agent tool (or SendMessage to the existing coder). Every agent prompt and coder message MUST start with `Mode: bug-fix.` so the preloaded `bug-fix` skill applies. You are forbidden from:

- Reading source code, editing files, or running tests/git yourself
- Accepting a fix whose report lacks the regression test's failing output before the fix
- Pushing without `--push` or an explicit Ship answer (Step 7)
- Stopping or asking outside the stop points of skill `dev-pipeline-stops`, or ending a turn with a prose question — every question is an AskUserQuestion popup

Flags follow skill `dev-pipeline-stops`: by default (`--yes`) skip the Step 2 approval and answer Step 7 with `Commit only`; `--ask` asks both; `--push` answers Step 7 with `Commit + push + promote staging` (web: `Commit + push <base>`), only from the user's own message. `--no-auto` asks the planner's Open Questions instead of auto-picking the recommended answer; passing `--auto` changes nothing.

## Cost Rules

- **`--lite`** (small, low-risk changes): strip it from the task text and pass `model: sonnet` on every planner and reviewer Agent call.
- **Reuse the coder**: keep the agent ID of the first coder call. Send every later fix to it with SendMessage (still prefixed `Mode: bug-fix.`) instead of spawning a new coder — it already holds the plan and the files it changed. Spawn a new coder only if SendMessage fails.
- **Unfinished coder**: if the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." before testing — at most twice, then report the remaining steps and stop.
- **Full suite at most twice**: only the first test run and the Final Gate run the full suite. Every re-run after a fix uses `Run stages: lint, typecheck, scoped tests. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed by the fix> <failing test files>.`

## Workflow

### Step 1: Plan

Agent(subagent_type: planner, prompt: "Mode: bug-fix. Plan a fix for: <bug>"). Capture the plan path.
`<bug>` names a `.dev-plan/explore/*.md` report → append `Explore report: <path> — read it first and reuse its flow; re-open only the files you will change.` to the prompt.

**Fail-closed guardrail**: If the plan has no Reproduction or Root Cause, or the planner reports it cannot reproduce, show its output and stop.

**Open Questions**: if the planner reports blocking questions, pick the planner's recommended candidate (else the first) for each and re-run the planner with `Answers (auto-chosen; record each under ## Assumptions in the plan): <answers>` appended to the same prompt; list every auto-chosen answer in the summary. Under `--no-auto`, ask them with AskUserQuestion instead (one question each, with the planner's candidate answers as options) and re-run the planner with `Answers: <answers>`. Never approve a plan that still has blocking questions. A typed answer (the free-text "Other" option) is still a popup answer: record it as the user's decision and ask every remaining question with AskUserQuestion too — never switch to plain chat text unless the user dismisses the popup or asks to discuss.

### Step 2: Approve

Read the plan, show Summary / Symptom / Root Cause / Steps. Unless `--ask`, go straight to Branch Check. Under `--ask`, AskUserQuestion: `Approve`, `Revise` (ask again only if the revised Steps changed), `Cancel`.

### Branch Check

Before any code change, run the Branch Check of `/dev` (git-agent report only: current branch, base per `commit-convention`, dirty files per repo). The reported `base` is `<base branch>` for every later step. A repo off its base → never switch it; AskUserQuestion: `I switched it, re-check`, `Continue on <current>`, `Cancel`.

### Step 3: Red → Fix → Green

Agent(subagent_type: coder, prompt: "Mode: bug-fix. Implement <plan-path> red-first: write the regression test, run it and paste its failing output, and only then apply the root-cause fix and paste the passing output. If the test passes before the fix, stop without touching production code."). Keep its agent ID.

**Fail-closed guardrail**: If the report lacks failing output before the fix, or the coder stopped because the test passed → the bug is not reproduced — report and stop.

### Step 4: Verify (max 3 iterations)

First run: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). Every re-run is scoped (see Cost Rules). On FAIL → SendMessage to the coder: "Mode: bug-fix. Fix these failures for <plan-path>: <failures>" → repeat.

### Step 5: Review + UI Verify (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Mode: bug-fix. Review the uncommitted changes against <base branch>. Plan file: <plan-path>."), and in the same message when triggered Agent(subagent_type: ui-verifier, prompt: "Mode: bug-fix. Verify the UI Checks of <plan-path>.").

**UI verify trigger**: the plan has a `## UI Checks` section — the planner adds one whenever the change touches web UI, so a style-only change without it does not launch a browser. When triggered, launch `ui-verifier` in the same message as the reviewer — both are read-only on code. `ENV_MISSING` from ui-verifier is not a failure: show what it needs and continue.

`CHANGES_REQUESTED` or UI `FAIL` → one SendMessage to the coder with both lists → back to Step 4 → reviewer again with prompt: "Mode: bug-fix. Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>." and ui-verifier with "Mode: bug-fix. Re-verify only these failed UI Checks of <plan-path>: <failed checks>."

### Step 6: Final Gate

Only if a fix landed after the last full-suite `PASS`: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). `FAIL` → show the failures and stop.

### Docs Update

Only when the fix changes a rule or behavior that a `docs/*.md`, `CLAUDE.md` or `README.md` of the service states. Agent(subagent_type: doc-writer, prompt: "Mode: topic. Service: `<dir of each repo in the plan>`. Topic: derive it from <plan-path> and the existing `docs/*.md`. Plan: <plan-path>. Update the docs in place per the feature-docs skill; if no doc update is needed report `no doc change needed`."). Add the files it reports to the commit file list. Runs before the commit so docs ship in the same commit; the writer edits Markdown only and never commits.

### Step 7: Ship

Under `--push`, use `Commit + push + promote staging` (web: `Commit + push <base>`) without asking. Under `--ask`, AskUserQuestion: `Commit only`, `Commit + push <base>`, `Commit + push + promote staging` (service repos only), `Stop (leave uncommitted)`. Otherwise use `Commit only` without asking.
Commit → Agent(subagent_type: git-agent, prompt: "Commit the current changes as a fix (type `fix`) on the current branch `<base branch>` per `commit-convention`; never create, switch or checkout a branch (`develop` for services, `staging` for web; a `fix/<slug>` branch only if the user asked)."). A push answer → the push and promotion of `/dev` Step 7.

## Output Summary

- Root cause (file:line)
- Regression test: red → green confirmed
- Review verdict, UI verify result, commits
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
