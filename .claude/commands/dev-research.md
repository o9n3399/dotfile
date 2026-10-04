---
description: Research a technology choice against the current stack via the researcher agent — cited report in .dev-plan/research/
argument-hint: [question] [--deep]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Read
---

# Dev Research Command

Question: $ARGUMENTS

## Execution Contract (non-negotiable)

You MUST delegate research to the `researcher` subagent. Do not search the web or read code yourself.

## Workflow

### Step 1: Invoke Researcher

Agent(subagent_type: researcher, prompt: "Depth: <deep if the arguments contain --deep, else quick>. Research: <question without --deep>").

**Clarifying questions**: if the agent returns clarifying questions instead of a report, ask them with AskUserQuestion (candidate answers as options), then re-run the agent with `Answers: <answers>` appended to the same prompt.

### Step 2: Present

Read the report and show TL;DR, the Options table and Recommendation, plus the path for the full report. Suggest `/dev-plan <task> — see <report-path>` to plan the adoption.
