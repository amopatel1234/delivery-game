# Delivery Workflow

**Version:** 1.2  
**Status:** Active  
**Owner:** Delivery

This document defines how Story Catalogue items move from backlog to completion using GitHub Issues, branches, pull requests and CI.

Gameplay behaviour is **not** defined here. Scope and acceptance criteria remain in the Story Catalogue Markdown files.

---

## Sources of truth

1. **PRD** — product goals, MVP scope and player experience.
2. **Gameplay Rules** — authoritative mechanics and calculations.
3. **Decision Log** — accepted product decisions and rationale.
4. **Epics** — implementation-focused epic acceptance criteria.
5. **Story Catalogue** — implementation stories, dependencies and acceptance criteria (canonical for delivery scope).
6. **GitHub Issue** — execution tracking for one catalogue story (status, assignees, links). Issues must not redefine gameplay behaviour.
7. **Implementation and tests** — merged code and automated evidence that acceptance criteria are met.

Machine-readable registry: `docs/planning/story-catalogue/stories.yml`  
Dependency graph: `docs/planning/story-catalogue/Cross-Epic-Dependencies.md`

---

## Story lifecycle

| Status | Meaning |
|---|---|
| **Backlog** | Catalogue story exists; no GitHub Issue yet. |
| **Ready** | Dependencies are Done; issue is open; work can start. |
| **In Progress** | Issue is assigned or implementation activity exists; no open PR ready for review. |
| **In Review** | An open pull request exists for the story. |
| **Blocked** | One or more dependencies are not Done, or a blocker label/decision applies. |
| **Done** | Implementation PR is merged into `main` and the linked issue is closed. |

Status for agents is derived primarily from Issues, PRs and `stories.yml` dependencies via `scripts/story_status.py`. The GitHub Project board is a human progress mirror — keep it updated, but do not treat it as the source of completion.

### Project board sync (agents)

Project: **Delivery Game MVP** — https://github.com/users/amopatel1234/projects/2 (`amopatel1234`, project number `2`).

When an agent picks up catalogue work, update the board in the same turn:

| Moment | Board Status |
|---|---|
| Start implementing a story | **In Progress** (assign the issue when possible) |
| Open the implementation PR | **In Review** |
| PR merges and linked issue closes | **Done** |
| Dependencies or a decision block the story | **Blocked** |

Local docs remain the scope source of truth. If the board disagrees with Issues/PRs/`story_status.py`, prefer Issues/PRs/dependencies and correct the board.

---

## Ready definition

A story is **Ready** only when:

- all dependencies are **Done**;
- no unresolved product decision blocks it;
- the canonical source exists in the Story Catalogue;
- the implementation environment supports the work.

---

## Done definition

A story is **Done** only when:

- the implementation PR is merged into `main`;
- the linked issue is closed;
- acceptance criteria are checked on the PR;
- required automated tests pass;
- CI passes;
- no unresolved review findings remain;
- affected documentation is updated.

---

## Naming conventions

**Issue** (unchanged — not a commit subject)

```text
[E5-S01] Card Rule Definitions
```

**Branch**

```text
story/e5-s01-card-rule-definitions
```

**Commit and PR title** — [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

Story work uses the story ID as the scope:

```text
feat(E5-S01): add canonical card definitions
```

Planning / harness / tooling PRs omit the story scope:

```text
chore: add TestFlight merged workflow
docs: clarify branch protection rules
```

Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.

Prefer **squash merge** so the squash commit subject is the PR title (one conventional commit on `main`).

---

## Local git hooks

Install once per clone:

```text
git config core.hooksPath hooks
```

`hooks/commit-msg` rejects non-conventional subjects via `scripts/validate_conventional_commit.py`.

---

## Responsibilities

| Artifact | Responsibility |
|---|---|
| Story Catalogue | Defines the work, dependencies and acceptance criteria. |
| GitHub Issues | Track execution status, assignees and blockers. |
| Pull requests | Provide implementation evidence, AC checklist and validation commands. |
| CI | Validates catalogue integrity, conventional PR titles, story traceability, iOS build/tests, and TestFlight upload on merge. |
| Project board | Human progress mirror; agents update Status on start / PR / merge. |

---

## CI enforcement

| Workflow | When | What |
|---|---|---|
| `story-catalogue-validation.yml` | Catalogue-related changes / PRs | Validates `stories.yml`. |
| `pr-traceability.yml` | Every PR | Conventional Commit PR title for all branches; full story traceability for `story/*`. |
| `pull-request.yml` | Non-draft PRs to `main` | iOS unit tests when `delivery-game.xcodeproj` is present. |
| `merged.yml` | Push to `main` (app/fastlane paths) or `workflow_dispatch` | Sign, archive, upload to TestFlight. No GitHub Releases. |

Versioning / GitHub Release automation is intentionally **not** used. Marketing version lives in Xcode; TestFlight build numbers increment from the latest uploaded build for that version.

### TestFlight secrets (repository)

Set these Actions secrets (same pattern as `what-to-make` / `Orbital-Drift`):

| Secret | Purpose |
|---|---|
| `DISTRIBUTION_CERTIFICATE` | Base64-encoded Apple Distribution `.p12` |
| `DISTRIBUTION_PASSWORD` | Password for that `.p12` |
| `KEY_VALUE` | App Store Connect API `.p8` key contents (mapped to Fastlane `APP_STORE_CONNECT_API_KEY_KEY`) |

Both Fastlane workflows set a UTF-8 locale (`LC_ALL=en_US.UTF-8`, `LANG=en_US.UTF-8`) as required by Fastlane setup docs.

`merged.yml` also passes Fastlane’s official ASC env vars:

| Env var | Value |
|---|---|
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | API Key ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_KEY` | from `KEY_VALUE` secret |
| `APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64` | `false` |
| `APP_STORE_CONNECT_API_KEY_IN_HOUSE` | `false` (App Store team; needed for sigh clarity) |

Provisioning profile name: `Couriers Gambit App Store Profile`  
Bundle ID: `com.amishpatel.couriesgambit.game`

Update `fastlane/testing_notes.txt` before merges that should ship a meaningful What to Test note.

After upload, Fastlane waits for processing and sets the What to Test changelog. It does **not** assign TestFlight groups via the API (ASC rejects assigning the **`Internal`** group). Enable **Automatic distribution** on **`Internal`** in App Store Connect so new builds reach testers.

### Testing policy

CI and story validation rely on **unit tests only**. UI test targets are not used.

---

## GitHub branch rules (manual)

Apply a **ruleset** (or classic branch protection) on `main`. Suggested settings:

1. **Require a pull request before merging**
   - Require at least one approval when you have a reviewer; otherwise leave at 0 until then.
   - Dismiss stale approvals on new commits (optional).
2. **Require status checks to pass**
   - `Validate PR title and story traceability`
   - `Validate story catalogue` (when that workflow runs)
   - `Build and unit tests` once the Xcode project is on `main`
3. **Block force pushes** and **block deletions** on `main`.
4. **Restrict commit metadata** → commit message must match Conventional Commits, e.g.

   ```text
   ^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([A-Za-z0-9._/-]+\))?(!)?: .+
   ```

   This catches odd direct pushes and bad squash subjects. PR titles are still enforced by `pr-traceability.yml` (rulesets do not replace that check).
5. **Merge strategy:** allow **squash merge** only (Settings → General → Pull Requests). That keeps `main` history aligned with conventional PR titles.

Optional later: restrict who can push to `main` to the empty set (PR-only).

---

## Local validation

```text
pip install -r requirements-dev.txt
git config core.hooksPath hooks
python3 -m unittest discover -s tests -v
python3 scripts/validate_story_catalogue.py
python3 scripts/validate_conventional_commit.py --message "feat(E5-S01): example"
python3 scripts/validate_pr_traceability.py \
  --title "feat(E5-S01): example" \
  --branch "story/e5-s01-example" \
  --body-file /path/to/body.md
python3 scripts/story_status.py
python3 scripts/story_status.py --json
```

---

## Status reporting limitation

`scripts/story_status.py` uses the GitHub CLI (`gh`) plus `stories.yml`. It classifies status from issues, pull requests and dependencies.

It does **not** query GitHub Project custom fields. Agents still update the Project board Status at lifecycle moments (see [Project board sync](#project-board-sync-agents)). If the board disagrees with derived status, prefer Issues/PRs/dependencies and correct the board.

---

## Related documents

- [Story Catalogue README](story-catalogue/README.md)
- [Cross-Epic Dependencies](story-catalogue/Cross-Epic-Dependencies.md)
- [GitHub Tracking Bootstrap](GitHub-Tracking-Bootstrap.md)
- [Documentation index](../README.md)
