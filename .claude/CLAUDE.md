# Global Claude Instructions

## Language

- Code comments, variable/function names, commit messages: English only
- Commit messages: Conventional Commits, scope required (e.g. `feat(user): ...`)
- Conversation with me: Vietnamese is fine

## Code Style

- No comments unless the WHY is non-obvious — never comment what the code already says
- One service/class per file — never combine multiple services into one file
- Folder names must be singular, never plural (e.g. `constant/`, `component/`, `entity/`, `repository/`)

## Working Rules

- Before saying a code change is done, run the project's typecheck and the tests covering it, and show the result; if you couldn't run them, say so
- Bugs: reproduce first (failing test or exact repro), fix the root cause, not the symptom
- When I correct a mistake you could repeat, propose a one-line rule for this file

## Response Style

- No trailing summaries after completing a task
- Keep responses concise

## Git

- Never push after committing unless explicitly asked
