#!/usr/bin/env python3
"""Validate Conventional Commits subject lines (commits and PR titles)."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Keep in sync with hooks/commit-msg and docs/planning/Delivery-Workflow.md.
CONVENTIONAL_TYPES = (
    "build",
    "chore",
    "ci",
    "docs",
    "feat",
    "fix",
    "perf",
    "refactor",
    "revert",
    "style",
    "test",
)

TYPES_PATTERN = "|".join(CONVENTIONAL_TYPES)
CONVENTIONAL_COMMIT_RE = re.compile(
    rf"^(?:{TYPES_PATTERN})"
    r"(?:\([^)]+\))?"
    r"!?"
    r": "
    r"\S.+$"
)

STORY_TITLE_RE = re.compile(
    rf"^(?:{TYPES_PATTERN})"
    r"\((E\d+-S\d+)\)"
    r"!?"
    r": "
    r"\S.+$"
)


def validate_conventional_commit(message: str) -> list[str]:
    """Return errors if the first line is not a Conventional Commit subject."""
    subject = message.strip().splitlines()[0] if message.strip() else ""
    if not subject:
        return ["commit/PR subject must not be empty"]
    if not CONVENTIONAL_COMMIT_RE.match(subject):
        types = ", ".join(CONVENTIONAL_TYPES)
        return [
            "subject must follow Conventional Commits: "
            f"<type>(optional-scope)!: description (types: {types}). "
            f"Got {subject!r}. "
            "See https://www.conventionalcommits.org/en/v1.0.0/"
        ]
    return []


def parse_story_id_from_conventional_title(title: str) -> str | None:
    """Return story ID from titles like feat(E5-S01): description."""
    match = STORY_TITLE_RE.match(title.strip())
    if not match:
        return None
    return match.group(1)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate a Conventional Commits subject line"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--message", help="Subject line to validate")
    group.add_argument(
        "--message-file",
        type=Path,
        help="Path to a file whose first line is the subject",
    )
    parser.add_argument(
        "--require-story-scope",
        action="store_true",
        help="Require type(E#-S##): description form",
    )
    args = parser.parse_args(argv)

    if args.message is not None:
        message = args.message
    else:
        message = args.message_file.read_text(encoding="utf-8")

    if args.require_story_scope:
        subject = message.strip().splitlines()[0] if message.strip() else ""
        if parse_story_id_from_conventional_title(subject) is None:
            print(
                "ERROR: subject must look like "
                "'feat(E5-S01): short description' "
                f"(got {subject!r})",
                file=sys.stderr,
            )
            return 1
        print("OK: conventional commit with story scope")
        return 0

    errors = validate_conventional_commit(message)
    if errors:
        print("ERROR: Conventional Commit validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("OK: Conventional Commit subject")
    return 0


if __name__ == "__main__":
    sys.exit(main())
