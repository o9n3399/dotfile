---
name: pr-template
description: Title and body format for opening pull requests with gh
user-invocable: false
---

# PR Template Skill

## Task

Open a pull request that a reviewer can understand in under a minute.

## Instructions

1. **Title**: same format as the main commit — `type(scope): subject`.
2. **Body**: fill `~/.claude/skills/pr-template/template.md`. Summarize from `git log <base>..HEAD` and the plan file in `.dev-plan/` if present.
3. **Create**: `gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`.
4. Keep PRs small — if the diff exceeds ~400 changed lines, mention it and suggest a split in the report.

## Expected Output

The PR URL.

## Gotchas

- Don't paste the whole plan into the PR — summarize
- Link the issue if the branch name or plan references one (`Closes #123`)
