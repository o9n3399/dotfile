---
description: Resolve several Redmine issues end to end — read, plan, fix, test, commit develop, cherry-pick staging, resolve on Redmine
argument-hint: <issue id or URL> [<id> ...] [--yes] [--push] [--lite] [--no-resolve]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Read
---

# Dev Redmine Command

Issues: $ARGUMENTS

## Execution Contract (non-negotiable)

You are an orchestrator. Every step MUST be delegated via the Agent tool (or SendMessage to the issue's coder). You are forbidden from:

- Reading source code, editing files, or running tests, git or curl yourself
- Working on two issues at once: issues run strictly one after another, so each commit holds only that issue's files
- Pushing or resolving on Redmine without `--push` or an explicit `Push + resolve` answer in Step 7
- Setting a Redmine issue to `Closed` (the tester closes it)

## Flags

Strip every flag from the arguments. Each remaining token is an issue id (a number, or `…/issues/<id>` URL); drop duplicates and keep the given order.

- **`--yes`**: skip the plan approval (Step 3), still show the plan summary.
- **`--push`**: counts as the explicit push instruction; Step 7 does not ask. Without it, Step 7 asks.
- **`--lite`**: pass `model: sonnet` on every planner and reviewer Agent call.
- **`--no-resolve`**: stop after the push, skip Step 8.

## Cost Rules

Same as `/dev-fix`: reuse the issue's first coder via SendMessage, at most two "Continue <plan-path>" nudges, full suite only on the first run and the Final Gate, scoped re-runs after fixes.

## Per-issue workflow

Run Steps 1–8 for issue 1, then for issue 2, and so on. An issue that stops (blocked, cannot reproduce, tests fail, user declines) is recorded as `skipped: <reason>`, its changes are left uncommitted, and the **whole batch stops there** because the next issue would share the dirty working tree. Report the remaining issues as not started.

### Step 1: Read the issue

Agent(subagent_type: general-purpose, prompt: "Read Redmine issue <id> with `GET /issues/<id>.json?include=journals,attachments,children,relations` (URL and API key are in the project CLAUDE.md, header `X-Redmine-API-Key` only). Download image attachments you need to look at into the scratchpad. Return: subject, tracker, status, author id and name, assignee, description, the latest journals that change the requirement, attachments (name + what the mock-up or screenshot shows), related issues, and the service(s) the text points at. Do not change the issue.").

**Fail-closed guardrail**: issue not found, `Closed`, or already `Resolved` → skip it and stop the batch for the user to decide. Never put the API key in a prompt that gets echoed into a plan file.

### Step 2: Plan

Agent(subagent_type: planner, prompt: "<Mode: bug-fix. if the tracker is Bug> Plan a fix for Redmine #<id>: <digest from Step 1>. Name the repo(s) and service(s) touched."). Capture the plan path.

**Fail-closed guardrail**: no plan path, or (Bug) no Reproduction or Root Cause → skip as in the workflow rule above.

**Open Questions**: ask each with AskUserQuestion (candidates as options), re-run the planner with `Answers: <answers>`. Never approve a plan with blocking questions.

### Step 3: Approve

Read the plan, show Summary / Root Cause / Steps / Risks and the repos it touches. Under `--yes` go straight on; otherwise AskUserQuestion: `Approve`, `Revise`, `Skip this issue`, `Stop the batch`.

### Step 4: Implement

Agent(subagent_type: coder, prompt: "<Mode: bug-fix. for a Bug: write the regression test first, paste its failing output, then fix.> Implement <plan-path>. Run the Live Check for every changed route."). Keep its agent ID. Handle the reported remaining steps per the Cost Rules.

### Step 5: Review and test

1. Agent(subagent_type: reviewer, prompt: "Review changes against the base branch. Plan file: <plan-path>."). On findings → SendMessage to the coder → re-review once; still failing → skip the issue.
2. Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, full test suite. Repos: <repos from the plan>."). `NEW` failures → SendMessage to the coder → scoped re-run, max 3 iterations, then skip the issue. `PRE-EXISTING` failures are listed, not blocking.
3. Only when the plan has `## UI Checks`: Agent(subagent_type: ui-verifier, prompt: "Verify the UI Checks of <plan-path>."). `FAIL` → coder → re-verify, max 2 iterations.

Fixes after the reviewer's approval are re-reviewed once before Step 6.

### Docs Update

Per issue, only when the plan changes behavior, a rule, an endpoint, config, the data model or an error key. Agent(subagent_type: doc-writer, prompt: "Mode: topic. Service: `<dir of each repo in the plan>`. Topic: derive it from <plan-path> and the existing `docs/*.md`. Plan: <plan-path>. Update the docs in place per the feature-docs skill; if no doc update is needed report `no doc change needed`."). Add the files it reports to the commit file list. Runs before the commit so docs ship in the same commit; the writer edits Markdown only and never commits.

### Step 6: Commit on develop

Agent(subagent_type: git-agent, prompt: "Skill git-branch-promotion applies. Commit only these files: <exact file list from the coder plus the files from Docs Update>. Branch: `develop` in every backend repo, `staging` in the web repo; run `git branch --show-current` in each repo first and stop if it differs. Message: `<type>(<module>) #<id>: <English summary of the issue>`, type `bugfix` for a Bug else `feat` or `chore`. Do not push. Report the commit sha and branch per repo.").

**Fail-closed guardrail**: the report shows files outside the list, or a branch other than expected → stop the batch.

### Step 7: Promote to staging

Skip for the web repo (it already committed on `staging`).

Under `--push` go straight to the push; otherwise AskUserQuestion: `Push + resolve`, `Push only`, `Stop here (commit stays local)`.

On a push answer, per backend repo, Agent(subagent_type: git-agent, prompt: "ALLOW_PUSH=true Skill git-branch-promotion applies. Push `develop` (plain push). Then cherry-pick <sha> onto a temporary worktree of `origin/staging` (never merge develop into staging, never checkout staging in the live tree). If the cherry-pick conflicts, abort it and report. Report the worktree path and the new staging sha, but do not push staging yet."). Then Agent(subagent_type: test-runner, prompt: "Run stages: typecheck, scoped tests on the cherry-picked worktree <path>. Scope to: <files of the commit>.") — `FAIL` → stop the batch, leave the worktree unpushed. `PASS` → Agent(subagent_type: git-agent, prompt: "ALLOW_PUSH=true Push the worktree HEAD to origin/staging (plain push, never forced), then remove and prune the worktree.").

Web: Agent(subagent_type: git-agent, prompt: "ALLOW_PUSH=true Push `staging` (plain push).").

`Push only` and `--no-resolve` skip Step 8. `Stop here` records the issue as `committed, not pushed` and continues with the next issue.

### Step 8: Resolve on Redmine

Only after Step 7 pushed both develop and staging. Agent(subagent_type: general-purpose, prompt: "Follow the redmine-resolve skill for issue <id>: status Resolved, assign back to the author, fill root cause category/process, root cause analysis and correct actions from the plan and commit shas, set due_date if empty, add a note in Vietnamese with root cause, action, commit shas per repo and how it was verified. Never put the API key, passwords or internal hostnames in the note. Read the issue again afterwards and report status, assignee and the four fields.").

A failed PUT (422 etc.) → one retry with the missing fields, then report the error and continue; the code is already pushed.

## Output Summary

A table, one row per issue: `#id | repo(s) | develop sha | staging sha | tests | review | Redmine status`, then:

- Skipped or not-started issues with the reason
- Assumptions the user approved or `--yes` auto-accepted, plan paths
- Pre-existing test failures
- `Created data:` from ui-verifier, if any
