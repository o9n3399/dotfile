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
   A step that changes an HTTP route verifies with a real call (`curl ... → <status>, <field>`), not only a unit test.
7. List every affected file with a one-line reason. Mark new files with `(new)`.
8. **UI Checks** only when the change touches web UI: one line per affected screen — route, the interaction, and the visible result a user would expect. Include the screens that reuse a changed component, not just the one in the task. In bug-fix mode, the first check replays the symptom's scenario and expects the fixed behavior.
9. **API Contract** whenever the change merges, replaces or reshapes an API a client reads:
   - One row per field any client screen reads (list, detail, edit, export) — grep the web code for it: old path → new path and type.
   - Flag every type change (e.g. `currency.code` object → `currencyCode` string) and every field the new API drops.
   - `Not round-tripped:` the fields that can be read but not written back (absent from the write schema).
   - Each dropped or changed field gets either a step that adapts the client or a non-goal.
10. Keep it short: a plan a human can approve in under 2 minutes.
11. **Line layout** — the plan is reviewed in split panes ~110 columns wide:
    - One sentence per line; break a long sentence at a comma, `→` or before a clause. Markdown still renders one paragraph, and diffs show only the edited sentence.
    - Max 100 characters per line. Indent a bullet's continuation 2 spaces under its text. Never break inside inline code, a link or `file:line`; a line holding only one long path or URL may exceed the limit.
    - A list of 3+ items becomes nested bullets, not a comma- or slash-joined line.
    - Tables only for short comparisons: cells ≤ ~50 characters, rows ≤ ~120. Longer content goes under a `### <Area>` heading as `- Current:` / `- Proposed:` bullets.
    - Status, dependency and related-plan notes are a bullet list, one item per line — never one long `>` line.

## Expected Output

A file at `.dev-plan/<kebab-case-slug>.md` matching `template.md`.

## Gotchas

- Don't plan against files you haven't opened — APIs you assume may not exist
- A merged API that type-checks can still break screens — client reads only show up in the API Contract table or in UI testing
- Flag DB migrations, public API changes and config/env changes under Risks
- Write non-goals explicitly — they stop the coder from expanding scope
- Recompute every concrete expected value you write into test examples — the coder must not change assertions, so a wrong value in the plan blocks implementation
