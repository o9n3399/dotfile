---
description: "Cherry-pick issue commits onto staging|demo|uat|main in a worktree · -p tst|bchh: one project · --push: push after pick (default no push)"
model: sonnet
argument-hint: <issue-id>... <branch> [-p project] [--push]
allowed-tools:
  - Bash
  - Agent
  - Skill
---

# Dev Pick Command

Arguments: $ARGUMENTS

## Usage

`/dev-pick <issue-id>... <branch> [-p <project>] [--push]`

| Argument | Meaning |
|----------|---------|
| `<issue-id>...` | One or more Redmine ids (`20626`, `#20626`). Commits are matched by `#<id>` in the message. Required. |
| `<branch>` | Target: `staging`, `demo`, `uat` or `main`. Required. |
| `-p <project>` | Scan only `tst` or `bchh`. Default: both. |
| `--push` | Push the target branch after a clean pick, with the skill's ahead-list check. Default: no push. |

Examples:

- `/dev-pick 20626 staging`: pick, no push.
- `/dev-pick 20626 20627 demo -p tst`: two issues, tst only.
- `/dev-pick 20626 staging --push`: pick and push.
- `/dev-pick 20626 main -p tst --push`: pick onto main and push.

## Execution Contract (non-negotiable)

- Never `git switch`/`checkout` a live tree and never tell the git-agent to; all picking happens in a worktree from `origin/<branch>`.
- Never include `ALLOW_PUSH=true` unless `--push` is in the arguments.
- Never resolve a cherry-pick conflict: `cherry-pick --abort`, list the files, stop.
- Target branch must be one of `staging`, `demo`, `uat`, `main`. Anything else (including `develop`, `master`): stop and say so.

## Workflow

### Step 1: Parse

Issue ids are the numeric tokens, the branch is the one of `staging|demo|uat|main`, `-p <project>` is optional, `--push` is optional. If the ids or the branch are missing, stop and say what is missing.

### Step 2: Find what is missing

Run once: `"$HOME/script/issue-branch" --fetch --missing <branch> --pick <ids> [-p <project>]`.

- A repo whose develop cell is `local` has unpushed commits; list it as skipped, do not pick it.
- If nothing is missing, report that and stop.

### Step 3: Brief the git-agent

Invoke the `git-branch-promotion` skill first, then use the Agent tool (one call per repo, sequential):

- subagent_type: git-agent
- prompt: repo path, branch, the `cherry-pick` shas from Step 2 (oldest first), the worktree recipe from the skill (`git cherry origin/<branch> <sha>` check first, worktree from `origin/<branch>`, one pick per commit), the verbatim no-pull block from the skill, and the conflict rule above. Without `--push`, stop after the picks and report the worktree path and `git log origin/<branch>..HEAD --oneline`. With `--push`, also add the skill's ahead-list stop-and-ask step and the staging push skeleton. For `main`, also state that the user named `main` in `/dev-pick`, so these worktree cherry-picks are the git-agent's allowed `main` exception.

### Step 4: Report

Per repo: picked shas, skipped (already applied or local-only), conflicts, worktree path. Remind the user that typecheck and tests on the worktree are not run by this command.
