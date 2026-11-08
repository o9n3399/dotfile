---
description: Implement an approved plan — runs the full /dev flow on it (review, test, UI verify, commit); --only for coder alone
argument-hint: [plan-path] [--only] [--lite] [--ask] [--push] [--auto]
allowed-tools:
  - Agent
  - SendMessage
  - AskUserQuestion
  - Skill
  - Bash(/bin/ls *)
  - Bash(grep *)
  - Bash(git rev-parse *)
  - Bash(pwd)
---

# Dev Implement Command

## Execution Contract (non-negotiable)

You MUST delegate implementation to the `coder` subagent (directly or through `/dev`). Do not edit code yourself. Never stop or ask outside the stop points of skill `dev-pipeline-stops`, and never end a turn with a prose question or a "next step: `/dev-x`" suggestion.

## Workflow

### Step 1: Resolve Plan

- Argument: `$ARGUMENTS`
- Latest plan: !`/bin/ls -t .dev-plan/ 2>/dev/null | grep -m1 '\.md$'` (a file name inside `.dev-plan/`)
- Project root: !`git rev-parse --show-toplevel 2>/dev/null || pwd`

Strip the flags. Use the remaining path if given, otherwise `.dev-plan/<latest plan>`.
A bare `.dev-plan/*.md` glob errors with `no matches found` on zsh — never use it.
If the latest plan is empty and the project root differs from the cwd, run `/bin/ls -t <root>/.dev-plan/` and take the newest `.md`.
If still empty, tell the user to run `/dev-plan` first and stop. (Glob/Grep skip gitignored `.dev-plan/` — rely on the values above.)

### Step 2: Run

Without `--only`: invoke Skill `dev` with args `<plan-path>` plus every flag given except `--only` (`--lite`, `--ask`, `--push`, `--auto`), and follow it to the end. Stop here — the rest of this file is for `--only`.

### Step 3 (`--only`): Invoke Coder

Agent(subagent_type: coder, description: Implement plan, prompt: "Implement the plan at <plan-path>. Tick each completed step in the plan file. Run the Live Check for every changed route.").

If the coder reports remaining steps or stops at its turn limit, SendMessage it "Continue <plan-path> from the first unchecked step." — at most twice.
Steps still unchecked after that are never dropped: list them by number at the top of the report and AskUserQuestion: `Continue coder`, `Leave for later`.

Report as done only when every item holds; otherwise report `incomplete` with the failing items:
- [ ] Every plan step ticked, or the user chose `Leave for later` for it
- [ ] typecheck and the tests covering the change pass
- [ ] Service restarted and every changed route called for real (`Live API check: yes`)

Show files changed, remaining steps, deviations and the live API check. `--only` skips review, tests beyond the coder's own, UI verify and commit — say so in one line.
