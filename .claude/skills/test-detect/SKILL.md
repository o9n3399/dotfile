---
name: test-detect
description: Detect and run a project's lint, typecheck and test commands, reporting only failures
user-invocable: false
---

# Test Detect Skill

## Task

Find the right verification commands for the current project and run them in a fixed order.

## Instructions

1. **Detect**: run `bash ~/.claude/skills/test-detect/script/detect.sh` from the repo root. Commands in the project's `CLAUDE.md` override detected ones.
   - `container: <name> ...` line → run every command inside that container exactly as the line says (`docker exec -u <uid>:<gid> -w <dest> <name> ...`). Never run host `node_modules` binaries for that repo.
   - Lint line saying the script has `--fix` → never run the lint script; run the linter check-only on the changed files.
2. **Run the stages** the prompt names (e.g. `Run stages: typecheck, full test suite`), else all, in this order:
   1. lint
   2. typecheck
   3. tests scoped to changed files (prompt's `Changed files`, else `git diff --name-only <base>`)
   4. full test suite
   Run every requested stage even when an earlier one fails; skip test stages only when typecheck has `NEW` errors (say so under `Not run`).
3. **One Bash call per stage**: run, keep the full log in the scratchpad, and print only the exit code and a filtered excerpt in the same call:
   ```bash
   log=<scratchpad>/<repo>-<stage>.log; <cmd> >"$log" 2>&1; echo "EXIT=$?"; grep -nE 'error|Error|FAIL|✕|failed' "$log" | head -40
   ```
   Read more of the log only when the excerpt lacks a file:line.
4. **Always run once**: add run-once flags so nothing hangs (e.g. `CI=true`, `--watchAll=false`, `vitest run`).

## Expected Output

```
Result: PASS | FAIL
Ran: <command list>
Scope: <unit | mocked | e2e | live API — list each that ran>; Not run: <the rest, with reason>

Failures:
- Command: <command>
  Location: <file:line>
  Origin: NEW | PRE-EXISTING
  Error: <≤20 lines excerpt>
```

`Result: FAIL` only when a `NEW` failure exists; only `PRE-EXISTING` failures → `PASS`, still listed.

**Origin**: a failure is `PRE-EXISTING` when its file:line is outside the diff (`git diff -U0 <base> -- <file>` shows no hunk covering it), else `NEW`.
Base: the branch in the prompt, else `origin/develop` if it exists, else `origin/HEAD`.
Never use `git stash` or checkout to compare — the working tree holds uncommitted work.

## Gotchas

- `PASS` without e2e or a live API call only proves the mocks agree with the code — say so via `Scope`
- Watch mode (`jest --watch`, bare `vitest`) never exits — always use run-once mode
- Tests needing DB/docker/network that fail on connection: report `ENV_MISSING`, don't start services
- Monorepos: run commands in the package that changed, not the root, unless root scripts exist
- Worktree or copy without `node_modules`: reuse the live repo's install (same container, symlink `node_modules` from the live repo inside a scratch copy) — never install
