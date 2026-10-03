---
name: test-detect
description: Detect and run a project's lint, typecheck and test commands, reporting only failures
user-invocable: false
---

# Test Detect Skill

## Task

Find the right verification commands for the current project and run them in a fixed order.

## Instructions

1. **Detect**: run `bash ~/.claude/skills/test-detect/script/detect.sh` from the project root. Commands listed in the project's `CLAUDE.md` override detected ones.
2. **Run in order**, stopping at the first stage that fails. If the prompt names stages (e.g. `Run stages: typecheck, full test suite`), run only those:
   1. lint
   2. typecheck
   3. tests scoped to changed files (`git diff --name-only`)
   4. full test suite
3. **Always run once**: add run-once flags so nothing hangs (e.g. `CI=true`, `--watchAll=false`, `vitest run`).

## Expected Output

```
Result: PASS | FAIL
Ran: <command list>

Failures:
- Command: <command>
  Location: <file:line>
  Error: <≤20 lines excerpt>
```

## Gotchas

- Watch mode (`jest --watch`, bare `vitest`) never exits — always use run-once mode
- Tests needing DB/docker/network that fail on connection: report `ENV_MISSING`, don't start services
- Monorepos: run commands in the package that changed, not the root, unless root scripts exist
