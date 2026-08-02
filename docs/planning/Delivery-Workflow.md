# Delivery Workflow

**Version:** 1.0  
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

Status for agents is derived primarily from Issues, PRs and `stories.yml` dependencies via `scripts/story_status.py`. GitHub Project board fields are optional mirrors and may lag; do not treat the board as the only source of completion.

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

**Issue**

```text
[E5-S01] Card Rule Definitions
```

**Branch**

```text
story/e5-s01-card-rule-definitions
```

**PR**

```text
[E5-S01] Add canonical card rule definitions
```

**Commit**

```text
feat(E5-S01): add canonical card definitions
```

---

## Responsibilities

| Artifact | Responsibility |
|---|---|
| Story Catalogue | Defines the work, dependencies and acceptance criteria. |
| GitHub Issues | Track execution status, assignees and blockers. |
| Pull requests | Provide implementation evidence, AC checklist and validation commands. |
| CI | Validates catalogue integrity and PR story traceability. |
| Project board | Reflects live status for humans; may mirror derived status. |

---

## CI enforcement

- `story-catalogue-validation.yml` validates `stories.yml` on catalogue-related changes and pull requests.
- `pr-traceability.yml` requires story ID naming on branches that start with `story/`. Planning and harness branches (for example `planning/*`) are skipped so meta-delivery work can land without a catalogue story ID.

---

## Local validation

```text
pip install pyyaml
python -m unittest discover -s tests -v
python scripts/validate_story_catalogue.py
python scripts/validate_pr_traceability.py \
  --title "[E5-S01] Example" \
  --branch "story/e5-s01-example" \
  --body-file /path/to/body.md
python scripts/story_status.py
python scripts/story_status.py --json
```

---

## Status reporting limitation

`scripts/story_status.py` uses the GitHub CLI (`gh`) plus `stories.yml`. It classifies status from issues, pull requests and dependencies.

It does **not** query GitHub Project custom fields. If the Project board disagrees with derived status, prefer Issues/PRs/dependencies and update the board.

---

## Related documents

- [Story Catalogue README](story-catalogue/README.md)
- [Cross-Epic Dependencies](story-catalogue/Cross-Epic-Dependencies.md)
- [GitHub Tracking Bootstrap](GitHub-Tracking-Bootstrap.md)
- [Documentation index](../README.md)
