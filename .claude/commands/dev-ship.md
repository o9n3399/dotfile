---
description: Verify, commit on the base branch, then push (and optionally promote to staging) after user confirmation
model: sonnet
argument-hint: [base-branch]
allowed-tools:
  - Agent
  - AskUserQuestion
---

# Dev Ship Command

Base branch: `$ARGUMENTS` (if empty: `develop` for service repos, `staging` for web, per `commit-convention`)

## Execution Contract (non-negotiable)

You are forbidden from:

- Pushing when tests fail or the user has not confirmed in Step 3
- Running git or test commands yourself — delegate to the agents
- Creating, switching or checking out any branch — a `feat/`/`fix/` branch or a PR/MR only when the user's own message asks for one

## Workflow

### Step 1: Verify

Skip this step if this conversation already has a full-suite `PASS` from test-runner and no agent changed files after it — say so in the report.

Use the Agent tool with subagent_type `test-runner`, prompt: Run stages: lint, typecheck, full test suite. Repos: <absolute repo paths>. Base: <base branch>. Changed files: <files changed in this task>.

**Fail-closed guardrail**: If the result is not `PASS`, show the failures and stop.

### Step 2: Commit

Use the Agent tool with subagent_type `git-agent`, prompt: Commit the current changes on the current branch; never create, switch or checkout a branch. If the current branch is not `<base branch>`, do not commit — report the branch.

A repo off its base → show it and AskUserQuestion: `I switched it, re-commit`, `Commit on <current>`, `Stop`. Never switch it yourself (the dev container mounts the live tree).

### Step 3: Confirm

Use AskUserQuestion: "Push <base>?" with options `Push <base>`, `Push + promote staging` (service repos only), `Stop here`.

If Step 2 reported `Pulled: <n> new commits` with n > 0, say so in the question — the pulled code was not covered by the Step 1 checks.

### Step 4: Ship

- `Push <base>` → git-agent: `ALLOW_PUSH=true` Run `git fetch -q origin` and `git log origin/<base>..<base> --oneline`; if any commit is not this task's, return the list instead of pushing. Otherwise plain push `<base>`; never create a branch.
- `Push + promote staging` → the push above, then the promotion of `/dev-redmine` Step 7 (Skill git-branch-promotion: cherry-pick onto a temporary worktree of `origin/staging`, conflict → abort and report, test-runner on the worktree, push staging only on `PASS`). A conflict means staging and develop diverged — show the files and stop; never resolve it by branching.

Report the commits per repo and branch, and the staging sha if promoted.
