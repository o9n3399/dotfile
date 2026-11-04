---
name: feature-docs
description: Use when documenting or updating one feature or topic of a service (e.g. item tree, document flow) - detail goes in docs/<topic>.md, CLAUDE.md only links to it
user-invocable: false
---

# Feature Docs Skill

## Task

Document one feature of one service so the next developer finds the rules fast, without bloating `CLAUDE.md` or `README.md`.

## Instructions

1. **Layout** (per service repo):
   - `docs/<topic>.md` - full detail, one file per topic, singular kebab-case name (`item-tree.md`). Folder is `docs/`.
   - `CLAUDE.md` - at most 10-15 lines for the topic: key rules plus a link to `docs/<topic>.md`. Never the full contract.
   - `README.md` - at most a 2-3 line pointer to `docs/<topic>.md`.
   - Plans stay in `.dev-plan/`; link them, do not copy them.
2. **Create vs update**: list `docs/*.md` first. A doc already covers the topic → edit it in place (keep true human-written text, fix what the code or the change contradicts). Create only when none does. Never make a second file for the same topic.
3. **Scope the change**: from the plan and diff, update only the sections the change touches. A change that alters no behavior, rule, endpoint, config, data model, error key or filter needs no doc: report `no doc change needed`.
4. **Facts from code only**: use the `service-docs` method. Cite `path:line`; mark anything unconfirmed `(unverified)`. Behaviour owned by another service (e.g. web) is stated as such, not as enforced here.
5. **Doc sections** (drop what does not apply): Purpose, Data model, Endpoints/contract, Behaviour and rules, Error keys, Filters, Removed or rejected rules (say "do not re-add" and why), Related plans. Tables over prose; link files, do not paste code.
6. **Single source**: a rule lives in `docs/<topic>.md`; CLAUDE.md and README repeat at most the headline. When a rule is removed in code, edit all three.
7. **Self-check**: every link resolves (`test -e` on each relative target), every error key and endpoint named exists in code, CLAUDE.md topic section ≤ 15 lines, no secrets.
8. **Report**: exact list of files changed, `(unverified)` items, and stale entries in `<service>/.claude/skills` that describe a rule the doc now contradicts (report them, do not edit them).

## Gotchas

- A topic doc written into CLAUDE.md or README is the mistake this skill exists to prevent.
- Do not document a rule the change did not touch just to look thorough.
