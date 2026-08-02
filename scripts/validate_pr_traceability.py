#!/usr/bin/env python3
"""Validate that a pull request traces to a Story Catalogue item."""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.stderr.write(
        "error: PyYAML is required. Install with: pip install pyyaml\n"
    )
    sys.exit(2)

_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))

from validate_conventional_commit import (  # noqa: E402
    parse_story_id_from_conventional_title,
    validate_conventional_commit,
)

BRANCH_RE = re.compile(r"^story/(e\d+-s\d+)-")
CLOSES_RE = re.compile(r"Closes\s+#\d+", re.IGNORECASE)
REQUIRED_SECTIONS = (
    "## Acceptance criteria",
    "## Validation",
    "## Deviations",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_registry_path() -> Path:
    return repo_root() / "docs" / "planning" / "story-catalogue" / "stories.yml"


def load_story_ids(registry_path: Path) -> set[str]:
    data = yaml.safe_load(registry_path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "stories" not in data:
        raise ValueError("stories.yml must contain a top-level 'stories' list")
    ids: set[str] = set()
    for story in data["stories"]:
        if isinstance(story, dict) and isinstance(story.get("id"), str):
            ids.add(story["id"])
    return ids


def story_source_path(story: dict[str, Any]) -> str:
    return f"docs/planning/story-catalogue/{story['source']}"


def load_stories_by_id(registry_path: Path) -> dict[str, dict[str, Any]]:
    data = yaml.safe_load(registry_path.read_text(encoding="utf-8"))
    by_id: dict[str, dict[str, Any]] = {}
    for story in data.get("stories", []):
        if isinstance(story, dict) and isinstance(story.get("id"), str):
            by_id[story["id"]] = story
    return by_id


def validate_pr(
    *,
    title: str,
    branch: str,
    body: str,
    registry_path: Path,
) -> list[str]:
    errors: list[str] = []

    try:
        by_id = load_stories_by_id(registry_path)
    except OSError as exc:
        return [f"unable to read registry {registry_path}: {exc}"]
    except yaml.YAMLError as exc:
        return [f"stories.yml failed to parse: {exc}"]

    title = title.strip()
    errors.extend(validate_conventional_commit(title))
    title_story_id = parse_story_id_from_conventional_title(title)
    if title_story_id is None:
        errors.append(
            "PR title must use Conventional Commits with story scope, "
            "e.g. 'feat(E5-S01): add canonical card definitions', "
            f"got {title!r}"
        )
    elif title_story_id not in by_id:
        errors.append(
            f"PR title story ID {title_story_id} is not in stories.yml"
        )

    branch_match = BRANCH_RE.match(branch.strip())
    if not branch_match:
        errors.append(
            "branch name must begin with story/<lowercase-story-id>-, "
            f"got {branch!r}"
        )
        branch_story_id = None
    else:
        branch_story_id = branch_match.group(1).upper()
        if branch_story_id not in by_id:
            errors.append(
                f"branch story ID {branch_story_id} is not in stories.yml"
            )

    if title_story_id and branch_story_id and title_story_id != branch_story_id:
        errors.append(
            f"title story ID {title_story_id} does not match "
            f"branch story ID {branch_story_id}"
        )

    story_id = title_story_id or branch_story_id
    if story_id and story_id not in body:
        errors.append(f"PR body must contain story ID {story_id}")

    if not CLOSES_RE.search(body):
        errors.append("PR body must contain 'Closes #<number>'")

    for section in REQUIRED_SECTIONS:
        if section not in body:
            errors.append(f"PR body must contain section heading {section!r}")

    if story_id and story_id in by_id:
        source = story_source_path(by_id[story_id])
        source_mentioned = (
            source in body
            or by_id[story_id]["source"] in body
            or "docs/planning/story-catalogue/" in body
        )
        if not source_mentioned:
            errors.append(
                f"PR body must mention canonical source "
                f"(expected reference to {source} or story-catalogue path)"
            )

    return errors


def resolve_inputs(args: argparse.Namespace) -> tuple[str, str, str]:
    title = args.title or os.environ.get("PR_TITLE") or os.environ.get("GITHUB_PR_TITLE")
    branch = (
        args.branch
        or os.environ.get("PR_BRANCH")
        or os.environ.get("GITHUB_HEAD_REF")
    )
    body = args.body
    if body is None and args.body_file:
        body = Path(args.body_file).read_text(encoding="utf-8")
    if body is None:
        body = os.environ.get("PR_BODY") or os.environ.get("GITHUB_PR_BODY")

    missing = []
    if not title:
        missing.append("PR title (--title or PR_TITLE)")
    if not branch:
        missing.append("branch (--branch or PR_BRANCH / GITHUB_HEAD_REF)")
    if body is None:
        missing.append("PR body (--body / --body-file or PR_BODY)")
    if missing:
        raise ValueError("missing required inputs: " + ", ".join(missing))
    return title, branch, body


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate PR title/branch/body story traceability"
    )
    parser.add_argument("--title", help="Pull request title")
    parser.add_argument("--branch", help="Pull request head branch name")
    parser.add_argument("--body", help="Pull request body text")
    parser.add_argument("--body-file", help="Path to a file containing the PR body")
    parser.add_argument(
        "--registry",
        type=Path,
        default=None,
        help="Path to stories.yml",
    )
    args = parser.parse_args(argv)

    try:
        title, branch, body = resolve_inputs(args)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    registry_path = args.registry or default_registry_path()
    errors = validate_pr(
        title=title,
        branch=branch,
        body=body,
        registry_path=registry_path,
    )
    if errors:
        print(
            f"PR traceability validation failed with {len(errors)} error(s):",
            file=sys.stderr,
        )
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("OK: PR traceability checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
