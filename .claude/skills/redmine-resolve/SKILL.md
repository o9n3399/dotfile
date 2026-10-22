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
3. Assign back to the issue author: `assigned_to_id = author.id`. For feedback with a question, still the author unless the user names someone else.
4. Fill the custom fields that the workflow requires on Resolved (ids from project 37; a missing one makes the PUT fail with a 422 listing the field):
   - 4 `Root Causal Category`: `RC99_Others` by default; `RC05_Lack of sharing information` when the cause is missing info or handover. Reuse values seen on other issues (`GET /issues.json?project_id=<p>&status_id=*&limit=100`); the full option list needs admin and returns 403.
   - 13 `Root Causal Process`: `Coding` for a code defect, `Unit Test` for a missed test, `Integration Test` otherwise.
   - 38 `Root Causal Analysis 根本原因分析`: one or two sentences on why it happened.
   - 19 ` Correct Actions 対策` (the name has a leading space): what was changed, with the commit hash and service.
   - `due_date` (standard field): Resolved fails with 422 "Due date cannot be blank" when empty. Set it to today (`YYYY-MM-DD`) if the issue has none.
5. Add a note (`notes`) with root cause, action, files or commit, and how it was verified, in the language the issue uses (Vietnamese for WMSx).
6. Send one PUT:

```bash
curl -s -X PUT -H "X-Redmine-API-Key: $KEY" -H "Content-Type: application/json" \
  "$URL/issues/<id>.json" -d '{"issue":{"status_id":3,"assigned_to_id":<author_id>,
  "notes":"...","custom_fields":[{"id":4,"value":"RC99_Others"},{"id":13,"value":"Coding"},
  {"id":38,"value":"..."},{"id":19,"value":"..."}]}}'
```

   A successful PUT returns HTTP 204 with an empty body. A 422 body lists the missing required fields: fill them and retry once.
7. Read the issue again and confirm status, assignee and the four fields.

## Rules

- Never set `Closed`; closing belongs to the tester.
- Never put the API key, passwords or internal hostnames in a note.
- Report the final status and assignee to the user.
