---
description: "Progress of recent .dev-plan plans · [days]: window, default 3"
argument-hint: "[days]"
model: sonnet
allowed-tools:
  - Read
  - Bash(git status *)
  - Bash(git log *)
---

# Dev Progress Command

Plans changed recently (`file | done/total steps | last edit | status | next step`):

!`python3 ~/.claude/hooks/script/plan-progress.py $ARGUMENTS`

Report progress to the user from this output only, one line per plan: issue/slug, done/total, next unchecked step. Group into `Xong`, `Đang làm`, `Chưa bắt đầu`. For an unfinished plan, name the command that resumes it (`/dev-implement .dev-plan/<file>`). Do not run checks, edit files or resume work.
