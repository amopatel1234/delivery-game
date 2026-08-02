# GitHub Tracking Bootstrap

**Status:** Manual step required for this environment

## Limitation

The Cursor cloud-agent `gh` token is a GitHub App installation token with **read-only** access to Issues, Labels and Projects. Attempts to create labels, issues or a Project return:

```text
HTTP 403: Resource not accessible by integration
```

Repository files, CI workflows and validators were still added on branch `planning/delivery-workflow-harness`. Issue/label/project seeding must be run with a personal access token (classic) that has `repo` and `project` scopes, or via the GitHub UI.

## Labels to create

```bash
gh label create "type: story" --description "Implementation story from the Story Catalogue" --color "0E8A16"
gh label create "status: blocked" --description "Story is blocked by dependencies or an unresolved decision" --color "D93F0B"
for n in 1 2 3 4 5 6; do
  gh label create "epic: $n" --description "Epic $n Story Catalogue work" --color "1D76DB"
done
for ws in foundation grid planning execution outcome polish; do
  gh label create "workstream: $ws" --description "Workstream: $ws" --color "5319E7"
done
```

Or run the idempotent bootstrap script:

```bash
pip install -r requirements-dev.txt
python3 scripts/bootstrap_github_tracking.py
```

## Issues

The bootstrap script creates one issue per `stories.yml` entry (37 total), skipping any title that already begins with `[E#-S##]`. Issue bodies link the canonical catalogue heading and list dependencies only — they do not copy acceptance criteria.

## Project board: Delivery Game MVP

```bash
gh project create --owner amopatel1234 --title "Delivery Game MVP"
```

Then in the GitHub Project UI:

1. Configure **Status** options: `Backlog`, `Ready`, `In Progress`, `In Review`, `Blocked`, `Done`
2. Add fields: **Story ID**, **Epic**, **Workstream**, **Priority**, **Implementation PR**
3. Add all 37 story issues
4. Initial status:
   - stories with **no** dependencies → **Ready**
   - stories **with** dependencies → **Blocked**
   - none → **Done**

```bash
# After noting the project number from create output:
gh project item-add <project-number> --owner amopatel1234 --url <issue-url>
```

## Verify

```bash
python3 scripts/story_status.py
gh issue list --search '"[E"' --limit 50
gh label list
```

Expected: exactly one open issue per story ID; derived status Ready or Blocked based on dependencies.
