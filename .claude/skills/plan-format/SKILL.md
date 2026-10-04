---
name: plan-format
description: Structure and rules for implementation plan files in .dev-plan/*.md
user-invocable: false
---

# Plan Format Skill

## Task

Define how an implementation plan is written (planner) and read (reviewer).

## Instructions

1. Copy the structure from `~/.claude/skills/plan-format/template.md`.
2. **Summary** must stand alone — a reader who stops there knows what changes and why.
3. **Current State** cites `file:line` for every claim, from files actually opened. In bug-fix mode, skip it — Symptom / Reproduction / Root Cause already cover it.
4. **Proposed Change** table: one row per behavior or module that changes, Current vs Proposed side by side.
5. **Steps are vertical slices** — each step delivers one testable behavior end-to-end, not one layer (avoid "step 1: all entities, step 2: all services").
6. Every step is a checkbox `- [ ]` with a `Verify:` line naming a concrete command or check.
7. List every affected file with a one-line reason. Mark new files with `(new)`.
8. **UI Checks** only when the change touches web UI: one line per affected screen — route, the interaction, and the visible result a user would expect. Include the screens that reuse a changed component, not just the one in the task. In bug-fix mode, the first check replays the symptom's scenario and expects the fixed behavior.
9. Keep it short: a plan a human can approve in under 2 minutes.

## Expected Output

A file at `.dev-plan/<kebab-case-slug>.md` matching `template.md`.

## Gotchas

- Don't plan against files you haven't opened — APIs you assume may not exist
- Flag DB migrations, public API changes and config/env changes under Risks
- Write non-goals explicitly — they stop the coder from expanding scope
- Recompute every concrete expected value you write into test examples — the coder must not change assertions, so a wrong value in the plan blocks implementation
