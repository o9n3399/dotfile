---
name: redmine-resolve
description: Use when finishing a Redmine issue fix and handing it back: resolve, feedback, reassign to author, fill root cause and action fields.
---

# Hand a Redmine issue back (resolve / feedback)

Redmine URL and API key are in the project `CLAUDE.md` (section Redmine). Send the key only in the `X-Redmine-API-Key` header, never in a URL or a note.

Do this only after the fix is committed and verified, and only when the user asked to update the issue. Updating an issue is visible to other people.

## Steps

1. Read the issue: `GET /issues/<id>.json?include=journals,allowed_statuses`. Note `author.id`, `status`, and the `allowed_statuses` ids (the target status must be in that list).
2. Pick the target status by the user's word: `resolve` → Resolved (id 3), `feedback` → Feedback (id 4), also `In_Review` 7, `Pending` 9. Other ids: `GET /issue_statuses.json`.
3. Assign to a tester, never ask the user:
   - Testers come from the cache `<project root>/.claude/redmine/project-<project_id>-members.json` (project root = the dir holding the `CLAUDE.md` with the Redmine section). Missing, older than 7 days, or the chosen id is rejected → refresh it from `GET /projects/<project_id>/memberships.json?limit=100` (the Overview tab's Members box) and write `{"fetched_at":"<YYYY-MM-DD>","testers":[{"id":..,"name":".."}],"members":[{"id":..,"name":"..","roles":[".."]}]}`.
   - Author (`author.id`) holds the `Tester` role → assign the author.
   - Otherwise → the tester who already appears in the issue's journals, else the one named by the user, else the first in `testers`. Say which rule picked them in the report.
   - Feedback with a question: still the author unless the user names someone else.
4. Fill the custom fields that the workflow requires on Resolved (ids from project 37; a missing one makes the PUT fail with a 422 listing the field):
   - 4 `Root Causal Category`: `RC99_Others` by default; `RC05_Lack of sharing information` when the cause is missing info or handover. Reuse values seen on other issues (`GET /issues.json?project_id=<p>&status_id=*&limit=100`); the full option list needs admin and returns 403.
   - 13 `Root Causal Process`: `Coding` for a code defect, `Unit Test` for a missed test, `Integration Test` otherwise.
   - 38 `Root Causal Analysis 根本原因分析`: one or two sentences on why it happened.
   - 19 ` Correct Actions 対策` (the name has a leading space): what was changed, with the commit hash and service.
   - `due_date` (standard field): Resolved fails with 422 "Due date cannot be blank" when empty. Set it to today (`YYYY-MM-DD`) if the issue has none.
   - `estimated_hours` (standard field): Resolved fails with 422 "Estimated time cannot be blank" when empty. If the issue has none, estimate it from the work done (plan steps, files and repos changed) and never ask the user: at least `1` for a Defect/Bug, at least `2` for a Task or any other tracker. Put the estimate and its basis in the report.
   - Parent issue: Redmine derives due date and estimate from children, so a 422 on the parent can come from a child. Fill only the empty `due_date` / `estimated_hours` of those children with the same rules (no status or other change), retry the parent, and list the touched children in the report and the note.
5. Add a note (`notes`) with root cause, action, files or commit, and how it was verified, in the language the issue uses (Vietnamese for WMSx).
6. Send one PUT:

```bash
curl -s -X PUT -H "X-Redmine-API-Key: $KEY" -H "Content-Type: application/json" \
  "$URL/issues/<id>.json" -d '{"issue":{"status_id":3,"assigned_to_id":<tester_id>,
  "due_date":"<today>","estimated_hours":<estimate>,"notes":"...","custom_fields":[{"id":4,"value":"RC99_Others"},{"id":13,"value":"Coding"},
  {"id":38,"value":"..."},{"id":19,"value":"..."}]}}'
```

   A successful PUT returns HTTP 204 with an empty body. A 422 body lists the missing required fields: fill them and retry once.
7. Read the issue again and confirm status, assignee and the four fields.

## Rules

- Never set `Closed`; closing belongs to the tester.
- Never put the API key, passwords or internal hostnames in a note.
- Report the final status and assignee to the user.
