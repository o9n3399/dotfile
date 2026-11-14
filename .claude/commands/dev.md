---
description: "Plan → code → review → test → UI → commit · --ask: ask approval/ship · --push: push + staging · --lite: sonnet · --no-auto: ask open questions"
argument-hint: [task description | .dev-plan/<slug>.md] [--lite] [--ask] [--push] [--no-auto]
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
- Stopping or asking outside the stop points of skill `dev-pipeline-stops`, or ending a turn with a prose question — every question is an AskUserQuestion popup
- Pushing without `--push` or an explicit Ship answer (Step 7)
- Creating, switching or checking out any branch — work stays on each repo's base branch (`develop` for service repos, `staging` for web, per `commit-convention`); a `feat/`/`fix/` branch only when the user's own message asks for one

## Flags

Strip every flag from the task text; `<task>` below means the text without flags. Flags follow skill `dev-pipeline-stops`:

- **Default (`--yes`)**: skip the Step 2 approval (still show the plan summary) and answer Step 7 with `Commit only`. Passing `--yes` changes nothing.
- **`--ask`**: ask the Step 2 approval and the Step 7 Ship question.
- **`--push`**: answer Step 7 with `Commit + push + promote staging` (web: `Commit + push <base>`). Only from the user's own message.
- **Given plan**: if `<task>` names an existing plan file (a `.dev-plan/*.md` path, or `--plan <path>`), that is `<plan-path>` — skip Step 1 (see Step 0). Any other text in `<task>` is extra context for the coder.
- **`--no-auto`**: asks the planner's Open Questions instead of auto-picking the recommended answer; passing `--auto` changes nothing.

## Cost Rules

- **`--lite`** (small, low-risk changes): strip it from the task text and pass `model: sonnet` on every planner and reviewer Agent call.
- **Reuse the coder**: keep the agent ID of the first coder call. Send every later fix to it with SendMessage instead of spawning a new coder — it already holds the plan and the files it changed. Spawn a new coder only if SendMessage fails.
- **Unfinished coder**: if the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." before reviewing — at most twice, then list the remaining steps by number and AskUserQuestion: `Continue coder`, `Leave for later`; record the choice in the summary.
- **Full suite at most twice**: only the first test run and the Final Gate run the full suite. Every re-run after a fix uses `Run stages: lint, typecheck, scoped tests. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed by the fix> <failing test files>.`

## Workflow

### Step 0: Given Plan

Only when a plan path was given. Read it (fail-closed: file missing → report and stop, never fall back to planning silently).
- Unanswered blocking Open Questions → handle them as in Step 1's **Open Questions**, re-running the planner with `Answers: <answers>` on that plan path, then Step 2.
- Otherwise → Step 2. Naming the plan counts as approval: show the summary and go straight to Branch Check, as under `--yes`.
- Some steps already checked → the Step 3 coder prompt becomes "Continue <plan-path> from the first unchecked step."

### Step 1: Plan

Agent(subagent_type: planner, prompt: "Write an implementation plan for: <task>"). Capture the plan path.
`<task>` names a `.dev-plan/explore/*.md` report → append `Explore report: <path> — read it first and reuse its flow; re-open only the files you will change.` to the prompt.

**Fail-closed guardrail**: No plan path → report and stop.

**Open Questions**: if the planner reports blocking questions, pick the planner's recommended candidate (else the first) for each and re-run the planner with `Answers (auto-chosen; record each under ## Assumptions in the plan): <answers>` appended to the same prompt; list every auto-chosen answer in the summary. Under `--no-auto`, ask them with AskUserQuestion instead (one question each, with the planner's candidate answers as options) and re-run the planner with `Answers: <answers>`. Never approve a plan that still has blocking questions. A typed answer (the free-text "Other" option) is still a popup answer: record it as the user's decision and ask every remaining question with AskUserQuestion too — never switch to plain chat text unless the user dismisses the popup or asks to discuss.

### Step 2: Approve

Read the plan file, show Summary / Proposed Change / Steps / Risks (plus the path for the full plan). Unless `--ask`, go straight to Branch Check. Under `--ask`, AskUserQuestion: `Approve`, `Revise` (collect feedback → back to Step 1 with it; ask again only if the revised Steps or Risks changed), `Cancel`. `Approve` → Branch Check.

### Branch Check

Before any code change, Agent(subagent_type: git-agent, model: haiku, prompt: "Report only — do not commit, stage, switch or checkout. For each repo: <absolute repo paths from the plan>, run `git -C <repo> branch --show-current` and `git -C <repo> status --short`, and report `<repo>: current=<branch> base=<develop for service repos, staging for web, per commit-convention> dirty=<files or none>`."). The reported `base` of each repo is `<base branch>` for every later step.
- Every repo on its base → Step 3
- A repo off its base (e.g. service on `staging`, or on a `feat/*` branch) → never switch it yourself or via an agent (the dev container mounts the live tree). AskUserQuestion: `I switched it, re-check`, `Continue on <current>` (record it in the summary), `Cancel`
- Dirty files outside the plan → show them; the coder and git-agent must leave them out

### Step 3: Implement

Agent(subagent_type: coder, prompt: "Implement the plan at <plan-path>. Run the Live Check for every changed route."). Keep its agent ID.
Order from here: code → restart + live API check (coder) → review → tests → UI. The coder owns the restart.
`Live API check: no` with a reason other than "no HTTP route changed" → show it and AskUserQuestion: `Continue`, `Stop`.

### Step 4: Review Loop (max 2 iterations)

Agent(subagent_type: reviewer, prompt: "Review the uncommitted changes against <base branch>. Plan file: <plan-path>").
- `APPROVE` → Step 5
- Otherwise → SendMessage to the coder: "Fix these findings for plan <plan-path>, then re-run the Live Check for the touched routes: <CRITICAL/HIGH findings>" → re-review
- Every review after a fix is a re-review: "Re-review. Previous findings: <findings>. Files changed by the fix: <coder's file list>. Plan file: <plan-path>."
- Still failing after 2 iterations → CRITICAL/HIGH findings that change behavior: AskUserQuestion `Keep fixing`, `Accept and continue`, `Stop`; format- or doc-only findings: list them in the summary and go on

### Step 5: Test Loop (max 3 iterations)

First run: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). Every re-run is scoped (see Cost Rules).
- `PASS` → Step 6
- `FAIL` with only `PRE-EXISTING` failures → list them in the summary, continue to Step 6
- `FAIL` with `NEW` failures → SendMessage to the coder: "Fix these failures for plan <plan-path>: <failures>" → repeat Step 5
- After 3 failed iterations, or `ENV_MISSING` / `NO_TESTS_DETECTED` → show the result and AskUserQuestion: `Keep fixing`, `Accept and continue`, `Stop`

A fix in this loop changes code the reviewer already approved: re-review the fixed files once (Step 4 re-review prompt) before Step 6.

### Step 6: UI Verify Loop (max 2 iterations)

Only when the plan has a `## UI Checks` section — the planner adds one whenever the change touches web UI.
Agent(subagent_type: ui-verifier, prompt: "Verify the UI Checks of <plan-path>.").
- `Not checked:` items → re-invoke once with "Verify only these checks of <plan-path>: <items>." and merge the reports
- `PASS` / `ENV_MISSING` (show what it needs) → Final Gate
- `FLAKY` items → show them, not a failure
- `FAIL` → SendMessage to the coder with the failures → Step 4 re-review of the fixed files → "Re-verify only these failed UI Checks of <plan-path>: <failed checks>."
- Still failing after 2 iterations → show remaining failures and AskUserQuestion: `Keep fixing`, `Accept and continue`, `Stop`

### Final Gate

Only if a fix landed after the last full-suite `PASS`: Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>."). `FAIL` with `NEW` failures → show them and AskUserQuestion: `Keep fixing`, `Accept and continue`, `Stop`.

### Docs Update

Only when the plan changes behavior, a rule, an endpoint, config, the data model or an error key of a service (skip pure typo, style or test-only changes). Agent(subagent_type: doc-writer, prompt: "Mode: topic. Service: `<dir of each repo in the plan>`. Topic: derive it from <plan-path> and the existing `docs/*.md`. Plan: <plan-path>. Update the docs in place per the feature-docs skill; if no doc update is needed report `no doc change needed`."). Add the files it reports to the commit file list. Runs before the commit so docs ship in the same commit; the writer edits Markdown only and never commits.

### Step 7: Ship

Under `--push`, use `Commit + push + promote staging` (web: `Commit + push <base>`) without asking. Under `--ask`, AskUserQuestion: `Commit only`, `Commit + push <base>`, `Commit + push + promote staging` (service repos only), `Stop (leave uncommitted)`. Otherwise use `Commit only` without asking.
Then, per repo, Agent(subagent_type: git-agent) — every prompt starts with "Commit on the current branch `<base branch>`; never create, switch or checkout a branch. Stage only: <files changed in this task>.":
- `Commit only` → "… Do NOT push."
- `Commit + push <base>` → "ALLOW_PUSH=true … Then `git fetch -q origin` and `git log origin/<base>..<base> --oneline`; if any commit is not this task's, return the list instead of pushing. Otherwise plain push `<base>`."
- `Commit + push + promote staging` → the push above, then the promotion of `/dev-redmine` Step 7 (Skill git-branch-promotion: cherry-pick onto a temporary worktree of `origin/staging`, conflict → abort and report, test-runner on the worktree, push staging only on `PASS`). A conflict means staging and develop diverged — show the files and stop; never resolve it by branching.

No PR option: the remotes are GitLab without `gh`. Open a PR/MR only when the user's own message asks for one, and then still commit on `<base>` unless they name a branch.

## Output Summary

- Plan path and steps completed
- Every auto-chosen Open Question answer, so the user can check the assumptions
- Live API check, review verdict (with remaining LOW findings), test result with `Scope` and pre-existing failures, UI verify result
- `Created data:` from ui-verifier, so the user can clean it up
- Branch Check result (any repo kept off its base)
- Commits per repo and branch, staging sha if promoted
- If the change affects runtime behavior a test can't fully show (UI, HTTP API, CLI output), suggest `/verify` to run the app and confirm it
