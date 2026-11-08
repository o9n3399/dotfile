---
name: dev-pipeline-stops
description: Use when running a /dev* command (dev, dev-fix, dev-refactor, dev-redmine, dev-implement, dev-plan, dev-explore, dev-review, dev-test, dev-ui-verify) and deciding whether to stop and ask the user or go on, or which flags apply.
---

# Dev pipeline stops

A `/dev*` run goes end to end. It stops only at the points below, and every stop is an AskUserQuestion popup. Never end a turn with a prose question or a "next step: `/dev-x`" suggestion — run the next step of the flow instead.

## Stop points

1. Plan approval — only under `--ask` and in `/dev-plan`; at most once per plan. After `Revise`, ask again only if the plan's Steps or Risks changed.
2. Blocking Open Questions from the planner or explorer (under `--auto`, auto-answered).
3. Ship — only under `--ask`.
4. Branch Check: a repo off its base branch.
5. Migration, DB delete or write, a write on synced live data, a real secret in the diff.
6. A loop ran out of iterations with CRITICAL/HIGH findings that change behavior, `NEW` test failures, or UI `FAIL`.
7. `ENV_MISSING` / `NO_TESTS_DETECTED` from test-runner.

Not stop points — list them in the summary and go on: format- or doc-only findings left after the loop, LOW findings, `PRE-EXISTING` failures, ui-verifier `ENV_MISSING`, the next step of the flow.

## Flags (same meaning in every command)

- **default = `--yes`**: skip plan approval (still show the plan summary) and ship as `Commit only`. Passing `--yes` changes nothing. `/dev-plan` and `/dev-explore` are excluded — they always end with a popup.
- **`--ask`**: ask plan approval and Ship.
- **`--auto`**: also auto-pick the recommended answer to Open Questions and record them under `## Assumptions`.
- **`--push`**: ship as `Commit + push + promote staging` (service repos; web: `Commit + push <base>`). In `/dev-redmine` it means push + resolve. Never inferred from anything but the user's own message.

## Standard options

| Stop | Options |
|---|---|
| Plan approval | `Approve` / `Revise` / `Cancel` |
| Ship (`/dev`, `/dev-fix`) | `Commit only` / `Commit + push <base>` / `Commit + push + promote staging` / `Stop (leave uncommitted)` |
| Ship (`/dev-redmine`) | `Push + resolve` / `Push only` / `Stop here (commit stays local)` |
| Loop out of iterations | `Keep fixing` / `Accept and continue` / `Stop` |
| Repo off its base | `I switched it, re-check` / `Continue on <current>` / `Cancel` |
| Standalone check failed (`/dev-review`, `/dev-test`, `/dev-ui-verify`) | `Send to coder + re-run` / `Stop` |
