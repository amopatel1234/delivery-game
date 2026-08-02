"""Tests for scripts/validate_story_catalogue.py."""

from __future__ import annotations

import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_story_catalogue import load_registry, validate_stories  # noqa: E402


def _write_catalogue(tmp: Path, stories: list[dict], source_text: str) -> Path:
    catalogue = tmp / "catalogue"
    catalogue.mkdir()
    source_name = "Epic-5-Stories.md"
    (catalogue / source_name).write_text(source_text, encoding="utf-8")
    registry = catalogue / "stories.yml"
    # Normalize sources
    for story in stories:
        story.setdefault("source", source_name)
        story.setdefault("workstream", "foundation")
        story.setdefault("dependencies", [])
    registry.write_text(
        yaml.safe_dump({"stories": stories}, sort_keys=False),
        encoding="utf-8",
    )
    return registry


def _minimal_valid_stories() -> tuple[list[dict], str]:
    """Build a tiny valid subset used only for unit tests of error paths.

    For the 'valid registry' test we use the real repository registry.
    """
    stories = [
        {
            "id": "E5-S01",
            "title": "Card Rule Definitions",
            "epic": 5,
            "workstream": "foundation",
            "source": "Epic-5-Stories.md",
            "dependencies": [],
        }
    ]
    source = "## E5-S01 — Card Rule Definitions\n\nGoal.\n"
    return stories, source


class ValidateStoryCatalogueTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo_root = Path(__file__).resolve().parents[1]
        cls.registry = (
            cls.repo_root
            / "docs"
            / "planning"
            / "story-catalogue"
            / "stories.yml"
        )
        cls.catalogue_dir = cls.registry.parent

    def test_valid_registry(self) -> None:
        stories = load_registry(self.registry)
        errors = validate_stories(stories, self.catalogue_dir)
        self.assertEqual(errors, [], msg="\n".join(errors))
        self.assertEqual(len(stories), 37)

    def test_duplicate_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            stories, source = _minimal_valid_stories()
            stories.append(dict(stories[0]))
            # Pad to avoid total-count noise dominating — we only assert duplicate
            registry = _write_catalogue(tmp_path, stories, source)
            loaded = load_registry(registry)
            errors = validate_stories(loaded, registry.parent)
            self.assertTrue(
                any("duplicate story id: E5-S01" in e for e in errors),
                errors,
            )

    def test_missing_dependency_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            stories, source = _minimal_valid_stories()
            stories[0]["dependencies"] = ["E5-S99"]
            registry = _write_catalogue(tmp_path, stories, source)
            errors = validate_stories(load_registry(registry), registry.parent)
            self.assertTrue(
                any("E5-S99" in e and "does not exist" in e for e in errors),
                errors,
            )

    def test_circular_dependency(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source = textwrap.dedent(
                """\
                ## E5-S01 — Alpha

                ## E5-S02 — Beta
                """
            )
            stories = [
                {
                    "id": "E5-S01",
                    "title": "Alpha",
                    "epic": 5,
                    "workstream": "foundation",
                    "source": "Epic-5-Stories.md",
                    "dependencies": ["E5-S02"],
                },
                {
                    "id": "E5-S02",
                    "title": "Beta",
                    "epic": 5,
                    "workstream": "foundation",
                    "source": "Epic-5-Stories.md",
                    "dependencies": ["E5-S01"],
                },
            ]
            registry = _write_catalogue(tmp_path, stories, source)
            errors = validate_stories(load_registry(registry), registry.parent)
            self.assertTrue(
                any("circular dependency" in e for e in errors),
                errors,
            )

    def test_missing_source_story_heading(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            stories, _ = _minimal_valid_stories()
            # Wrong heading title
            source = "## E5-S01 — Wrong Title\n"
            registry = _write_catalogue(tmp_path, stories, source)
            errors = validate_stories(load_registry(registry), registry.parent)
            self.assertTrue(
                any("expected heading" in e and "exactly once" in e for e in errors),
                errors,
            )


if __name__ == "__main__":
    unittest.main()
