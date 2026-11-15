---
description: Run a shell alias from ~/aliases/claude by name (e.g. /cmd csw, /cmd ib 20483)
model: sonnet
argument-hint: <alias-name> [extra args]
allowed-tools:
  - Bash
---

# Cmd Command

Arguments: $ARGUMENTS

The Bash tool does not expand aliases, so resolve the alias yourself from `$HOME/aliases/claude` and run the real command.

## Rules (non-negotiable)

1. The first token of the arguments is the alias name. It must match `^[A-Za-z0-9_-]+$`; otherwise stop and say so.
2. Find the definition with `grep -E "^alias <name>=" "$HOME/aliases/claude"`. Read only that file. If there is no match, list the alias names found in the file and stop. Never run anything that is not defined there.
3. Take the value between the quotes, replace a leading `~` with `$HOME`, and append the remaining arguments, shell-quoted.
4. If the resolved command starts with `claude`, do not run it: it would start a nested interactive session. Tell the user to run the alias in a terminal.
5. Print the exact resolved command on one line, then run it once with the Bash tool. Do not retry on failure; show the output and the exit code.
6. Do not edit any file, and do not run extra commands beyond the grep and the resolved command.

## Output

The resolved command, then its output. No summary.
