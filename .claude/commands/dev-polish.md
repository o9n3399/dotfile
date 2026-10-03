---
description: Tighten code syntax without changing behavior — modern idioms, less nesting, dead code removal
argument-hint: [path...] [--review]
allowed-tools:
  - Agent
  - Bash(git status *)
  - Bash(echo *)
---

# Dev Polish Command

## Execution Contract (non-negotiable)

Every step MUST be delegated via the Agent tool. Every coder/reviewer prompt MUST start with `Mode: polish.` so the preloaded `syntax-optimize` skill applies. You are forbidden from:

- Editing files or running tests yourself
- Polishing files outside the resolved scope
- Committing — suggest `/dev-commit` instead

## Workflow

### Step 1: Resolve Scope

- Arguments: `$ARGUMENTS`
- Changed files: !`git status --porcelain --untracked-files=all 2>/dev/null || echo NOT_A_GIT_REPO`

Use the paths from the arguments if given, otherwise the changed files (strip the 2-char status prefix, drop deleted `D` entries). Drop non-code files (lockfiles, docs, generated). No paths, or `NOT_A_GIT_REPO` without arguments → tell the user to pass a path and stop.

### Step 2: Polish

Agent(subagent_type: coder, prompt: "Mode: polish. Apply syntax-optimize to these files only: <files>.").

### Step 3: Verify (max 2 fix iterations)

Agent(subagent_type: test-runner, prompt: "Run stages: lint, typecheck, scoped tests. Scope to: <files>.").
- `PASS` → Step 4
- `FAIL` → Agent(subagent_type: coder, prompt: "Mode: polish. Your rewrites broke: <failures>. Revert the offending rewrites to the original form.") → repeat
- Still `FAIL` → show failures and stop

### Step 4: Review (only with `--review`)

Agent(subagent_type: reviewer, prompt: "Mode: polish. Review the uncommitted changes in <files> for behavior changes.").

## Output Summary

- Changes per file (grouped by type) and skipped candidates
- Test result, review verdict if run
- Next: `/dev-commit`
