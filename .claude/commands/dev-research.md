---
description: Research a technology choice against the current stack via the researcher agent — cited report in .dev-plan/research/
model: sonnet
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

**Clarifying questions**: if the agent returns clarifying questions instead of a report, ask them with AskUserQuestion (candidate answers as options), then re-run the agent with `Answers: <answers>` appended to the same prompt. A typed answer (the free-text "Other" option) is still a popup answer: record it as the user's decision and ask every remaining question with AskUserQuestion too — never switch to plain chat text unless the user dismisses the popup or asks to discuss.

### Step 2: Present

Read the report and show TL;DR, the Options table and Recommendation, plus the path for the full report. Suggest `/dev-plan <task> — see <report-path>` to plan the adoption.
