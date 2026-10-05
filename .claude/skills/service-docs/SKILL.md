---
name: service-docs
description: Method, template and verification rules for writing or updating a service's developer docs from its code
user-invocable: false
---

# Service Docs Skill

## Task

Document one service so a new developer can run, configure, call and operate it — every fact taken from the code, nothing invented.

## Instructions

1. **Location and language**: follow the project's existing docs (location, language, heading style). With none, write `<service>/README.md` in English.
2. **Existing docs**: update in place. Keep human-written sections that are still true; fix what the code contradicts. Replace generator boilerplate entirely (GitLab/GitHub "Getting started" template, `create-*-app`/`nest new` default README).
3. **Leads, not truth**: the project's `CLAUDE.md` and existing docs tell you where to look; confirm each fact in code before writing it.
4. **Gather in bulk** — one Grep per question across the service instead of opening files one by one:
   - Run/build/deploy: manifest scripts, Makefile, Dockerfiles, compose files, CI file
   - Modules: feature directories (e.g. `src/components/*`, `src/modules/*`) and their one-line responsibility
   - Config: every env var read in code (`process.env.X`, `os.getenv`, `@Value`, config classes) plus placeholders in config files (`${X}`, `${{ X }}`); compare with `.env.example` and flag names missing from it. Families (`<NAME>_SERVICE_HOST/PORT`, `NATS_*_SERVICE`) may share one row, but name every member — never "…" or "see file". Keep names exactly as spelled in code, typos included. Mark variables read only by disabled/commented-out modules as unused
   - Handlers: one Grep for route and message decorators with a few lines of context (`@Get|@Post|@Put|@Patch|@Delete|@MessagePattern|@EventPattern|@GrpcMethod`, `router.get(`, `@app.get(`). A handler can carry both an HTTP route and a message pattern — that is one row
   - Auth: global guards (`APP_GUARD`, `app.useGlobalGuards`, gateway config) before per-route decorators; a route without a decorator is not public if a global guard applies
   - Async messaging: topics/queues/subjects published (`emit`, `publish`, `sendToQueue`, producer `send`) and consumed
   - Data: every datastore (ORM entities, raw clients such as ClickHouse/Redis), migrations directory and count
   - Outbound: calls to other services — HTTP clients, NATS/gRPC clients, their subject/topic constants and base-URL config
   - Key flows: multi-step business operations (saga/orchestrator classes, status enums, handlers that update several entities) — at most 5
5. **Scale**: up to ~30 handlers → one API table. More → one subsection per module/controller, each with its own table, plus a link to the generated API docs (Swagger/OpenAPI URL) as the full reference. Controllers with ≤3 handlers may share one "Other controllers" table.
6. **Cite**: each section lists the files it came from (`path:line`). Anything not confirmed in code is marked `(unverified)` — never guessed.
7. **Brevity**: tables over prose; link to files instead of pasting code; drop template sections the service doesn't have.
8. **Self-check before returning**: every run command exists in the manifest/Makefile, every env var in the docs appears in code or config and every env var read in code is named in the docs (`grep -rhoE` the read pattern, diff against the table), every handler matches a decorator/route definition, every link resolves to an existing file.

## Expected Output

The service's docs file following `~/.claude/skills/service-docs/template.md`, plus a one-line purpose for the index.

## Gotchas

- Never open `.env`, `*.pem`, `*.key`, `*.p12`, `*credentials*` or cert directories — read variable names from `.env.example` and code only; never copy any secret value, even from `.env.example`
- Global prefixes (`app.setGlobalPrefix`, `server.servlet.context-path`, router mounts) change every path — resolve them before listing routes, and note which routes are excluded
- Message subjects built from constants (`${NATS_X}.action`) — resolve the constant's value or show the expression as written
- Generated files (OpenAPI output, protobuf stubs, ORM clients, `dist/`) are evidence, not things to document line by line
- Profile-specific config (`application-<profile>.yml`, `NODE_ENV` branches, multiple compose files) — say which profile a value belongs to
- A route or consumer defined but never registered in a module is not part of the API
