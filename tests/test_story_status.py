"""Tests for pure status-classification logic in scripts/story_status.py."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from story_status import (  # noqa: E402
    GithubStoryState,
    build_status_report,
    classify_status,
)


class ClassifyStatusTests(unittest.TestCase):
    def test_backlog_when_no_issue(self) -> None:
        status, blocking = classify_status(
            dependency_statuses={},
            dependencies=[],
            github=None,
        )
        self.assertEqual(status, "Backlog")
        self.assertEqual(blocking, [])

    def test_ready_when_deps_done_and_issue_open(self) -> None:
        status, blocking = classify_status(
            dependency_statuses={"E5-S01": "Done"},
            dependencies=["E5-S01"],
            github=GithubStoryState(
                issue_number=1,
                issue_state="open",
            ),
        )
        self.assertEqual(status, "Ready")
        self.assertEqual(blocking, [])

    def test_blocked_when_dependency_not_done(self) -> None:
        status, blocking = classify_status(
            dependency_statuses={"E5-S01": "Ready"},
            dependencies=["E5-S01"],
            github=GithubStoryState(issue_number=2, issue_state="open"),
        )
        self.assertEqual(status, "Blocked")
        self.assertEqual(blocking, ["E5-S01"])

    def test_in_review_when_open_pr(self) -> None:
        status, _ = classify_status(
            dependency_statuses={},
            dependencies=[],
            github=GithubStoryState(
                issue_number=3,
                issue_state="open",
                open_pr_number=10,
            ),
        )
        self.assertEqual(status, "In Review")

    def test_in_progress_when_assigned(self) -> None:
        status, _ = classify_status(
            dependency_statuses={},
            dependencies=[],
            github=GithubStoryState(
                issue_number=4,
                issue_state="open",
                issue_assignees=["dev"],
            ),
        )
        self.assertEqual(status, "In Progress")

    def test_done_when_issue_closed_and_pr_merged(self) -> None:
        status, blocking = classify_status(
            dependency_statuses={},
            dependencies=[],
            github=GithubStoryState(
                issue_number=5,
                issue_state="closed",
                merged_pr_number=11,
            ),
        )
        self.assertEqual(status, "Done")
        self.assertEqual(blocking, [])

    def test_build_status_report_orders_and_propagates_blocking(self) -> None:
        stories = [
            {
                "id": "E5-S01",
                "title": "A",
                "epic": 5,
                "workstream": "foundation",
                "dependencies": [],
            },
            {
                "id": "E5-S04",
                "title": "B",
                "epic": 5,
                "workstream": "foundation",
                "dependencies": ["E5-S01"],
            },
        ]
        github = {
            "E5-S01": GithubStoryState(issue_number=1, issue_state="open"),
            "E5-S04": GithubStoryState(issue_number=2, issue_state="open"),
        }
        records = build_status_report(stories, github)
        by_id = {r.id: r for r in records}
        self.assertEqual(by_id["E5-S01"].status, "Ready")
        self.assertEqual(by_id["E5-S04"].status, "Blocked")
        self.assertEqual(by_id["E5-S04"].blocking_dependencies, ["E5-S01"])


if __name__ == "__main__":
    unittest.main()
