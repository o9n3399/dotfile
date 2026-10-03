---
name: syntax-optimize
description: Behavior-preserving rules for tightening code syntax — modern idioms, less nesting, less noise
user-invocable: false
---

# Syntax Optimize Skill

## Task

Make code shorter and clearer at the syntax level without changing behavior, public API, or dependencies. Structural changes (extracting helpers, moving code) belong to a refactor, not here.

## Instructions

**Coder — every mode** (dev, bug-fix, refactor, polish)
1. Write every new or modified line in its tightest correct form from the start, using the idioms below.
2. Only lines you are already changing — outside polish mode never rewrite untouched code (bug-fix keeps the fewest lines, refactor keeps its step scope).
3. Leave no dead code behind from your own change (imports, locals, branches it made unused).
4. Detect the target language version (`tsconfig` target, `engines`, `requires-python`, `go.mod`, Java release in `pom.xml`/`build.gradle`) — never use syntax newer than it.
5. Follow `code-convention`: if the codebase consistently uses a pattern, keep it even if a newer one exists.
6. Comments: don't add any, don't remove ones explaining a WHY.

Idioms:
- Flat control flow: guard clauses / early return, no `else` after `return`/`throw`
- Simple expressions: `return c` instead of `if (c) return true; else return false`, no redundant ternaries or double negation
- Target-version idioms: destructuring, template strings, `const` over `let`, comprehensions, `switch`/`match` expressions
- File-local dead code removed: unused imports, local variables, private members

**Coder — polish mode only** (rewrite existing code in the given files)
1. Touch only the files given in the prompt. Skip generated, vendored and lock files.
2. Run the project's linter autofix on those files first (`eslint --fix`, `ruff check --fix`, …) using only its existing config — it is deterministic and cheaper than hand edits.
3. Then apply the idioms above by hand across each file.
4. Test files: same rules, but never change an assertion or expected value.
5. Run the project's formatter on a file only if it was already formatter-clean before your edits — otherwise the diff drowns in reformatting.
6. Report per file in the format below, including candidates skipped because of a Gotcha.

**Reviewer** (every mode)
1. Check changed lines against the Gotchas — any semantic change is HIGH.
2. In polish mode, also flag changes outside the given files, to public signatures, or to assertions as HIGH.

## Expected Output

Polish mode report:

```
path/to/file.ts
  - dead code: 3 unused imports, 1 unused local
  - nesting: 2 early returns
  - idioms: 4 destructurings
  - skipped: line 42 `||` → `??` (value may be 0)
```

## Gotchas

- `||` → `??` changes behavior for `0`, `''`, `false`; `?.` can hide a bug that should throw
- `==` ↔ `===`, truthiness checks on numbers/strings — not equivalent
- `a + b + 'x'` → template string changes the result when `a`, `b` are numbers
- Destructuring a method (`const { fn } = obj`) loses `this`; destructuring a getter reads it eagerly
- Hoisting a condition into a variable can lose TypeScript type narrowing
- `forEach(async …)` ↔ `for…of` changes sequential vs concurrent execution
- Dropping `return await` inside `try` stops the `catch` from seeing the rejection
- Arrow ↔ `function` changes `this` / `arguments`
- Reordering expressions with side effects (calls, getters, `i++`) changes results
- Python: mutable default args, comprehension replacing a loop with side effects, `is` vs `==`
- Java: streams with checked exceptions or `null` elements; `var` hiding a widened type
- Exported or public members that look unused may be reached via reflection, DI, string keys, templates, or other packages — never remove them here
