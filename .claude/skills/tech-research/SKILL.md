---
name: tech-research
description: Method and report format for researching a technology choice (library, framework, service, approach) against the current project's stack
user-invocable: false
---

# Tech Research Skill

## Task

Answer a technology question with a recommendation the user can act on, backed by current primary sources and fitted to this project's stack — not a generic comparison.

## Instructions

1. **Frame**: restate the decision in one line and list the constraints — runtime/language versions, existing dependencies (`package.json`, `pom.xml`, `build.gradle`, `pyproject.toml`, `go.mod`), the project's `CLAUDE.md`, scale and team limits given in the prompt.
2. **Candidates**: 2–4 options, found with WebSearch ("<need> <language> library <current year>", recent comparisons, "alternatives to X") plus what you already know. Always include "use what we already have" when an existing dependency or stdlib could cover it.
3. **Sources**, in this order of trust:
   - Official docs for the current version (Context7 MCP first, then the project's site)
   - Release notes / changelog, the repo itself (last release date, open vs closed issues, maintainers)
   - Package registry metadata (`npm view <pkg> version time license`, `pip index versions`, Maven Central)
   - Benchmarks only with stated methodology; blog posts and forums lowest
4. **Verify**: every claim that drives the recommendation needs a primary source or two independent ones. Note the version and date it applies to. Your training knowledge is a lead, never a source.
5. **Evaluate** on: fit with the current stack, maturity and maintenance, performance where it matters for this use, DX and learning cost, license, security history (advisories/CVEs), migration cost and lock-in.
6. **Spike only if asked**: a short code sample showing the integration point in this codebase — written into the report, never into the source tree.
7. **Depth**: `quick` → 1–2 candidates beyond the obvious, ≤6 sources, stop once the answer is clear. `deep` → full candidate set, ≥2 sources per key claim, migration outline.

## Expected Output

`.dev-plan/research/<kebab-case-slug>.md`, following `~/.claude/skills/tech-research/template.md`.

## Gotchas

- Library APIs change between majors — check the docs for the version this project would install, not the one you remember
- Archived or deprecated packages still rank high in search; check the repo is alive (last release, archived banner, deprecation notice on the registry)
- Stars and download counts measure popularity, not fitness or maintenance
- Vendor benchmarks favor the vendor; discount them unless the methodology is reproducible
- License traps: AGPL, SSPL, BSL and "source-available" licenses can block commercial use
- Adding a dependency has a permanent cost — prefer the existing stack unless the gain is concrete
- "It depends" is not a recommendation: pick one and state the condition that would flip it
