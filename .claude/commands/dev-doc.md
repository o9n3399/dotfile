---
description: "Write docs/<topic>.md for one service topic · --plan <path>: source from that plan"
model: sonnet
argument-hint: <service> [topic] [--plan <plan-path>]
allowed-tools:
  - Agent
  - AskUserQuestion
---

# Dev Doc Command

## Execution Contract (non-negotiable)

The docs MUST be written by a `doc-writer` subagent in topic mode. You are forbidden from reading source or writing docs yourself, and from committing (suggest `/dev-commit`).

## Workflow

### Step 1: Resolve

Arguments: `$ARGUMENTS`. Strip `--plan <path>`.

- Service directory: required; missing → AskUserQuestion.
- Topic: optional. Without one, the writer picks it from the plan or the uncommitted diff and the existing `docs/*.md`.

### Step 2: Write

Agent(subagent_type: doc-writer, prompt: "Mode: topic. Service: `<dir>`. Topic: `<topic or 'derive it'>`. Plan: `<plan-path or none>`. Update an existing `docs/<topic>.md` in place; create it only when no existing doc covers the topic. Follow the feature-docs skill. If the change needs no doc update, change nothing and report `no doc change needed` with the reason.")

### Step 3: Report

Show files changed (the exact list, so a commit can include them), `(unverified)` items, stale skills flagged, or `no doc change needed`. Next: review the diff, then `/dev-commit`.
