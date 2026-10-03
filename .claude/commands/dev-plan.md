---
description: Explore the codebase and write an implementation plan via the planner agent
argument-hint: [task description]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
---

# Dev Plan Command

Task: $ARGUMENTS

## Execution Contract (non-negotiable)

You MUST delegate planning to the `planner` subagent. Do not explore the codebase or write the plan yourself.

## Workflow

### Step 1: Invoke Planner

Use the Agent tool:

- subagent_type: planner
- description: Plan implementation
- prompt: Write an implementation plan for this task: $ARGUMENTS

**Fail-closed guardrail**: If the agent returns no plan path, report its output and stop.

**Open Questions**: if the planner reports blocking questions, ask them with AskUserQuestion (one question each, with the planner's candidate answers as options), then re-run the planner with `Answers: <answers>` appended to the same prompt. Then present the updated plan.

### Step 2: Present Plan

Read the plan file and show Summary / Current State / Proposed Change / Steps / Risks and the open questions, plus the path for the full plan. Tell the user to run `/dev-implement <plan-path>` once approved.
