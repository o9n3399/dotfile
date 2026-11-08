---
description: Explore a flow or area of existing code via the explorer agent — context, flow, issues — noted in .dev-plan/explore/
model: sonnet
argument-hint: [topic] [repo path]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
  - Skill
  - Bash(ls *)
---

# Dev Explore Command

Topic: $ARGUMENTS

## Execution Contract (non-negotiable)

You MUST delegate exploration to the `explorer` subagent. Do not read source code yourself.

## Workflow

### Step 1: Resolve Repo

Use the repo path in the arguments; else the repo named in the topic (e.g. `datasync-service`), preferring the current directory when it matches. Several matches → AskUserQuestion with each absolute path as an option. No match → ask for the path.

### Step 2: Invoke Explorer

Agent(subagent_type: explorer, prompt: "Topic: <topic without the path>. Repo: <absolute repo path>.").

**Clarifying questions**: if the agent returns clarifying questions instead of a report, ask them with AskUserQuestion (candidate answers as options), then re-run it with `Answers: <answers>` appended to the same prompt. A typed answer (the free-text "Other" option) is still a popup answer: keep asking the remaining questions with AskUserQuestion.

### Step 3: Present

Read the report and show TL;DR, Flow (steps only) and the Issues table, plus the report path.

Then AskUserQuestion (never a prose question) with up to 3 options from the report, most severe first, plus `Stop`:
- an issue to fix → `Fix: <issue>` → invoke Skill `dev-fix` with args `<issue> — see <report-path>`
- a change to plan → `Plan: <task>` → invoke Skill `dev` with args `<task> — see <report-path>`

Follow the invoked command to the end. `Stop` → end with the report path. No issue or change in the report → skip the question.
