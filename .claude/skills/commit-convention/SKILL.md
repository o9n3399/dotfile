---
name: commit-convention
description: Branching and Conventional Commits rules for creating commits
user-invocable: false
---

# Commit Convention Skill

## Task

Turn working-tree changes into small, well-described commits on a feature branch.

## Instructions

1. **Branch**: if on `main`/`master`, create `<type>/<short-kebab-slug>` (e.g. `feat/user-signup`) before committing.
2. **Group**: one commit per logical change. If the project's `CLAUDE.md` requires one commit per file, follow it.
3. **Stage explicitly**: `git add <paths>` — never `git add -A` / `git add .` blindly; never stage `.dev-plan/` or `.claude/agent-memory-local/`.
4. **Message**: `type(scope): subject`
   - `type`: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`
   - `scope`: required — the module/feature touched (e.g. `user`, `auth`, `order`)
   - `subject`: English, imperative, lowercase, no trailing period, ≤ 72 chars
   - Body (optional): the WHY, wrapped at 72 chars
5. Pass the message via heredoc to preserve formatting.

## Expected Output

```
<short-hash> feat(user): add email verification on signup
```

## Gotchas

- Never use `--no-verify` to bypass a failing pre-commit hook — report the failure
- Check `git diff --cached` for secrets before committing
