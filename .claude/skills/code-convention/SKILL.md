---
name: code-convention
description: Language-agnostic coding conventions for writing code that fits the existing codebase
user-invocable: false
---

# Code Convention Skill

## Task

Write code that reads like it was written by the codebase's existing authors.

## Instructions

1. **Project rules win**: the project's `CLAUDE.md` / `.claude/rules/` override everything below.
2. **Mirror neighbors**: before creating a file, open a sibling of the same kind and copy its structure, naming, imports and error handling.
3. **Reuse before writing**: grep for an existing helper/util before adding a new one.
4. **Tests**: new behavior gets a test next to existing tests, using the same framework and style.

## Gotchas

- Don't add a dependency when the stdlib or an existing dependency covers it
- Don't leave debug logs, commented-out code, or TODOs without context
- Match the existing error-handling style (exceptions vs result types) — never mix
