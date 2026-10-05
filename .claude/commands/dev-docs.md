---
description: Write or update developer docs for the repo's services via parallel doc-writer agents, then refresh the service index
argument-hint: [service...] [--all]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Bash(bash ~/.claude/skills/service-docs/script/list-services.sh)
  - Bash(git rev-parse *)
---

# Dev Docs Command

## Execution Contract (non-negotiable)

Every docs file MUST be written by a `doc-writer` subagent. You are forbidden from:

- Reading source code or writing docs yourself
- Running more than 8 doc-writers at once
- Committing — suggest `/dev-commit` instead

## Workflow

### Step 1: Resolve Services

- Arguments: `$ARGUMENTS`
- Services found: !`bash ~/.claude/skills/service-docs/script/list-services.sh`
- Root is a git repo: !`git rev-parse --is-inside-work-tree 2>/dev/null || echo false`

Service names in the arguments → those (must be in the list). `--all` → every service found. Neither → AskUserQuestion: `All services` / `Let me name them`. Empty list → tell the user no service manifest was found and stop.

### Step 2: Write Docs (parallel)

Launch one Agent(subagent_type: doc-writer, prompt: "Document the service in `<dir>` (repo root if `.`).") per service in the same message, at most 8 per batch; wait for a batch to finish before the next.

A writer that fails or hits its turn limit → note it and continue with the rest.

### Step 3: Index (only for 2+ services in one git repo)

Skip when the root is not a git repo (each service is its own repo) — tell the user to commit inside each service instead.

Agent(subagent_type: doc-writer, prompt: "Mode: index. Update the services section of the root `README.md` with: <service — purpose — docs path per writer report>.").

## Output Summary

- Per service: docs path, created/updated, `(unverified)` count
- Services that failed, if any
- Next: review the diff, then `/dev-commit`
