"""Tests for scripts/validate_pr_traceability.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_pr_traceability import validate_pr  # noqa: E402


VALID_BODY = """## Story
Story ID: E5-S01
Canonical source: docs/planning/story-catalogue/Epic-5-Stories.md
Closes #1

## Summary
Adds card rule definitions.

## Acceptance criteria
- [x] Criteria met

## Validation
- [x] Build succeeds

## Architecture and implementation notes
None.

## Deviations
None.

## Screenshots or recordings
Not applicable for non-UI work.
"""


class ValidatePrTraceabilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.registry = (
            ROOT / "docs" / "planning" / "story-catalogue" / "stories.yml"
        )

    def test_valid_pr(self) -> None:
        errors = validate_pr(
            title="[E5-S01] Add canonical card rule definitions",
            branch="story/e5-s01-card-rule-definitions",
            body=VALID_BODY,
            registry_path=self.registry,
        )
        self.assertEqual(errors, [], msg="\n".join(errors))

    def test_invalid_title(self) -> None:
        errors = validate_pr(
            title="Add card rules",
            branch="story/e5-s01-card-rule-definitions",
            body=VALID_BODY,
            registry_path=self.registry,
        )
        self.assertTrue(any("PR title must begin" in e for e in errors), errors)

    def test_invalid_branch(self) -> None:
        errors = validate_pr(
            title="[E5-S01] Add canonical card rule definitions",
            branch="feature/card-rules",
            body=VALID_BODY,
            registry_path=self.registry,
        )
        self.assertTrue(any("branch name must begin" in e for e in errors), errors)

    def test_missing_issue_link(self) -> None:
        body = VALID_BODY.replace("Closes #1", "Related to story work")
        errors = validate_pr(
            title="[E5-S01] Add canonical card rule definitions",
            branch="story/e5-s01-card-rule-definitions",
            body=body,
            registry_path=self.registry,
        )
        self.assertTrue(any("Closes #" in e for e in errors), errors)

    def test_unknown_story_id(self) -> None:
        errors = validate_pr(
            title="[E9-S99] Imaginary story",
            branch="story/e9-s99-imaginary",
            body=VALID_BODY.replace("E5-S01", "E9-S99"),
            registry_path=self.registry,
        )
        self.assertTrue(
            any("not in stories.yml" in e for e in errors),
            errors,
        )

    def test_missing_sections(self) -> None:
        body = """## Story
Story ID: E5-S01
Canonical source: docs/planning/story-catalogue/Epic-5-Stories.md
Closes #1

## Summary
Missing required sections.
"""
        errors = validate_pr(
            title="[E5-S01] Add canonical card rule definitions",
            branch="story/e5-s01-card-rule-definitions",
            body=body,
            registry_path=self.registry,
        )
        self.assertTrue(any("Acceptance criteria" in e for e in errors), errors)
        self.assertTrue(any("Validation" in e for e in errors), errors)
        self.assertTrue(any("Deviations" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
