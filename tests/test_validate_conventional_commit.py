"""Tests for scripts/validate_conventional_commit.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_conventional_commit import (  # noqa: E402
    parse_story_id_from_conventional_title,
    validate_conventional_commit,
)


class ValidateConventionalCommitTests(unittest.TestCase):
    def test_valid_subjects(self) -> None:
        for subject in (
            "feat: add grid rendering",
            "feat(E5-S01): add canonical card definitions",
            "fix(ui)!: break layout API",
            "docs: update delivery workflow",
            "chore: bootstrap fastlane",
        ):
            with self.subTest(subject=subject):
                self.assertEqual(validate_conventional_commit(subject), [])

    def test_invalid_subjects(self) -> None:
        for subject in (
            "",
            "Add grid rendering",
            "feat add grid",
            "feat: ",
            "[E5-S01] Add cards",
        ):
            with self.subTest(subject=subject):
                errors = validate_conventional_commit(subject)
                self.assertTrue(errors, subject)

    def test_story_scope_parser(self) -> None:
        self.assertEqual(
            parse_story_id_from_conventional_title(
                "feat(E5-S01): add canonical card definitions"
            ),
            "E5-S01",
        )
        self.assertIsNone(
            parse_story_id_from_conventional_title("feat: add something")
        )
        self.assertIsNone(
            parse_story_id_from_conventional_title(
                "[E5-S01] Add canonical card definitions"
            )
        )


if __name__ == "__main__":
    unittest.main()
