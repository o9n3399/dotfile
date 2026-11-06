---
name: explore-report
description: Use when the user says 'explore' a flow, feature or area of existing code (e.g. 'explore luồng gửi mail ở datasync-service', 'tìm hiểu luồng X') to get its context, flow and issues noted in a file.
---

# Explore Report Skill

**Main session**: do not explore yourself. Resolve the repo (several matches, e.g. 5 `datasync-service` dirs → ask with AskUserQuestion; the current repo wins when it matches), then run the `/dev-explore` workflow: Agent(subagent_type: explorer, prompt: "Topic: <topic>. Repo: <absolute repo path>."). The rest of this skill is for the explorer.

## Method

1. **Entry points**: find every way the flow starts — HTTP route, NATS/queue `@MessagePattern`/`@EventPattern`, cron/scheduler, CLI, event listener. Grep for the topic's nouns (e.g. `mail`, `mailer`, `smtp`, `sendMail`, `template`).
2. **Trace**: follow each entry point call by call to the side effect (DB write, external call, message sent, file written). Record `file:line` per hop. Stop at library boundaries; name the library and how it is configured.
3. **Data**: entities/tables read and written, DTO shapes, statuses and their transitions.
4. **Config**: env vars, config keys and defaults the flow reads; feature flags.
5. **Integrations**: other services, queues, SMTP/APIs — direction, payload, timeout, retry.
6. **Errors**: what happens on each failure — thrown, swallowed, retried, logged, persisted.
7. **Issues**: check the trace against the `review-checklist` order (correctness, edge cases, security, performance, tests). Each issue needs a `file:line` and a concrete failing scenario; style nits do not count.
8. **Tests**: which tests cover the flow, and which hops have none.
9. **History** (optional, when it explains something odd): `git log -L` / `git blame` on the hop.

## Report Format

```markdown
# Explore: <topic>

- Repo: <absolute path> · Branch: <branch> · Commit: <short sha> · Date: <YYYY-MM-DD>

## TL;DR
<3–5 lines: what the flow does, how it is triggered, the biggest risk>

## Entry Points
| Trigger | Where (file:line) | Notes |

## Flow
1. <step> — `file:line`
2. ...

```mermaid
sequenceDiagram
  ...
```

## Data
<tables/entities, read/write, status transitions>

## Config
| Key | Default | Used at (file:line) |

## Integrations
| Target | Direction | Payload | Timeout/Retry | Where |

## Error Handling
<per failure point: what happens>

## Tests
<covering tests; uncovered hops>

## Issues
| # | Severity | Title | Where (file:line) | Scenario | Suggested fix |

## Open Questions
- <what could not be verified from code, and what would answer it>
```

## Rules

- Every claim cites `file:line`; inference is marked `(inferred)`.
- Describe the code as it is now, not as docs say it should be — record doc mismatches as `LOW` issues.
- No issues found → write `None found` with what was checked, never pad.
