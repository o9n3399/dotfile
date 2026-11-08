---
description: "Write a plan, then Approve + run /dev · --lite: sonnet · --push: /dev pushes + staging"
model: sonnet
argument-hint: [task description] [--lite] [--push]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
  - Skill
---

# Dev Plan Command

Task: $ARGUMENTS

## Execution Contract (non-negotiable)

You MUST delegate planning to the `planner` subagent. Do not explore the codebase or write the plan yourself.

## Workflow

### Step 0: Check Task

The task is only the text after `Task:` above — never a task from earlier in the conversation, memory or an old plan.
If it is empty, ask the user for it with AskUserQuestion and stop until they answer.

### Step 1: Invoke Planner

Use the Agent tool:

- subagent_type: planner
- description: Plan implementation
- prompt: Write an implementation plan for this task: <task without `--lite` / `--push`>

**Fail-closed guardrail**: If the agent returns no plan path, report its output and stop.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run the planner with `Answers: <answers>` appended to the same prompt. Then present the updated plan. A typed answer (the free-text "Other" option) is still a popup answer: record it as the user's decision and ask every remaining question with AskUserQuestion too — never switch to plain chat text unless the user dismisses the popup or asks to discuss.

### Step 2: Present Plan

Read the plan file and show Summary / Current State / Proposed Change / Steps / Risks and the open questions, plus the path for the full plan.

Then AskUserQuestion (never a prose question): `Approve + run`, `Revise`, `Stop`.
- `Approve + run` → invoke Skill `dev` with args `<plan-path>` plus `--lite` / `--push` if the user's arguments had them, and follow it to the end
- `Revise` → collect the feedback, re-run Step 1 with it appended, then this step again
- `Stop` → show the plan path and end
