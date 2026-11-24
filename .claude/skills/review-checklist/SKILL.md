---
name: review-checklist
description: Severity-ranked checklist and output format for reviewing a git diff
user-invocable: false
---

# Review Checklist Skill

## Task

Find real defects in a diff and report them so they can be fixed without further investigation.

## Instructions

Check in this order, reading surrounding code for context:

1. **Correctness** — logic errors, off-by-one, null/undefined, wrong condition, race conditions, unhandled async
2. **Edge cases** — empty input, large input, concurrent calls, partial failure, retries
3. **Error handling** — see `~/.claude/skills/review-checklist/reference/error-handling.md`
4. **Security** — see `~/.claude/skills/review-checklist/reference/security.md`
5. **Performance** — see `~/.claude/skills/review-checklist/reference/performance.md`
6. **Database** — only when entities, migrations or queries changed: see `~/.claude/skills/review-checklist/reference/database.md`
7. **Tests** — new behavior without a test, tests that can't fail, deleted/weakened assertions
8. **Plan conformance** — unchecked steps claimed done, scope creep, undocumented deviations

Severity:
- `CRITICAL` — bug, data loss, or security hole reachable in production
- `HIGH` — missing error handling, missing test for new behavior, plan deviation
- `LOW` — maintainability issue a future change will trip on

## Expected Output

```
Verdict: APPROVE | CHANGES_REQUESTED

- [CRITICAL] path/file.ts:42 — <defect>
  Scenario: <concrete input/state → wrong result>
  Fix: <concrete change>
```

Findings sorted by severity. `CHANGES_REQUESTED` if any CRITICAL or HIGH.

## Gotchas

- Skip formatting/naming nits a linter catches
- "Could be cleaner" is not a finding — only report what breaks or will break
