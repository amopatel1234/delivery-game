#!/usr/bin/env python3
"""Validate the machine-readable Story Catalogue registry."""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover - exercised in environments without PyYAML
    sys.stderr.write(
        "error: PyYAML is required. Install with: pip install pyyaml\n"
    )
    sys.exit(2)

STORY_ID_RE = re.compile(r"^E(\d+)-S(\d+)$")
EXPECTED_TOTAL = 37
EXPECTED_EPIC_COUNTS = {
    1: 6,
    2: 6,
    3: 7,
    4: 6,
    5: 6,
    6: 6,
}
VALID_WORKSTREAMS = {
    "foundation",
    "grid",
    "planning",
    "execution",
    "outcome",
    "polish",
}
REQUIRED_FIELDS = ("id", "title", "epic", "workstream", "source", "dependencies")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_registry_path() -> Path:
    return repo_root() / "docs" / "planning" / "story-catalogue" / "stories.yml"


def default_catalogue_dir() -> Path:
    return repo_root() / "docs" / "planning" / "story-catalogue"


def load_registry(path: Path) -> list[dict[str, Any]]:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ValueError(f"unable to read registry: {path}: {exc}") from exc

    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        raise ValueError(f"stories.yml failed to parse: {exc}") from exc

    if not isinstance(data, dict) or "stories" not in data:
        raise ValueError("stories.yml must contain a top-level 'stories' list")
    stories = data["stories"]
    if not isinstance(stories, list):
        raise ValueError("'stories' must be a list")
    return stories


def story_heading(story_id: str, title: str) -> str:
    return f"## {story_id} — {title}"


def detect_cycles(adjacency: dict[str, list[str]]) -> list[list[str]]:
    """Return one or more cycles as lists of story IDs."""
    visiting: set[str] = set()
    visited: set[str] = set()
    stack: list[str] = []
    cycles: list[list[str]] = []

    def dfs(node: str) -> None:
        visiting.add(node)
        stack.append(node)
        for dep in adjacency.get(node, []):
            if dep in visiting:
                if dep in stack:
                    idx = stack.index(dep)
                    cycles.append(stack[idx:] + [dep])
                continue
            if dep not in visited:
                dfs(dep)
        stack.pop()
        visiting.remove(node)
        visited.add(node)

    for node in adjacency:
        if node not in visited:
            dfs(node)
    return cycles


def validate_stories(
    stories: list[dict[str, Any]],
    catalogue_dir: Path,
) -> list[str]:
    errors: list[str] = []

    if len(stories) != EXPECTED_TOTAL:
        errors.append(
            f"expected exactly {EXPECTED_TOTAL} stories, found {len(stories)}"
        )

    ids: list[str] = []
    by_id: dict[str, dict[str, Any]] = {}
    epic_counts: dict[int, int] = defaultdict(int)

    for index, story in enumerate(stories):
        loc = f"stories[{index}]"
        if not isinstance(story, dict):
            errors.append(f"{loc}: each story must be a mapping")
            continue

        for field in REQUIRED_FIELDS:
            if field not in story:
                errors.append(f"{loc}: missing required field '{field}'")

        story_id = story.get("id")
        if not isinstance(story_id, str) or not STORY_ID_RE.match(story_id):
            errors.append(
                f"{loc}: id must match E<number>-S<number>, got {story_id!r}"
            )
            continue

        ids.append(story_id)
        if story_id in by_id:
            errors.append(f"duplicate story id: {story_id}")
        else:
            by_id[story_id] = story

        title = story.get("title")
        if not isinstance(title, str) or not title.strip():
            errors.append(f"{story_id}: title must be a non-empty string")

        epic = story.get("epic")
        if not isinstance(epic, int):
            errors.append(f"{story_id}: epic must be an integer")
        else:
            epic_counts[epic] += 1
            match = STORY_ID_RE.match(story_id)
            if match and int(match.group(1)) != epic:
                errors.append(
                    f"{story_id}: epic field {epic} does not match id epic number"
                )

        workstream = story.get("workstream")
        if workstream not in VALID_WORKSTREAMS:
            errors.append(
                f"{story_id}: workstream must be one of "
                f"{sorted(VALID_WORKSTREAMS)}, got {workstream!r}"
            )

        source = story.get("source")
        if not isinstance(source, str) or not source.endswith(".md"):
            errors.append(f"{story_id}: source must be a Markdown filename")
        else:
            source_path = catalogue_dir / source
            if not source_path.is_file():
                errors.append(
                    f"{story_id}: source file does not exist: {source_path}"
                )

        deps = story.get("dependencies")
        if not isinstance(deps, list):
            errors.append(f"{story_id}: dependencies must be a list")
        else:
            for dep in deps:
                if not isinstance(dep, str):
                    errors.append(f"{story_id}: dependency must be a string: {dep!r}")
                elif dep == story_id:
                    errors.append(f"{story_id}: must not depend on itself")

    for epic, expected in EXPECTED_EPIC_COUNTS.items():
        actual = epic_counts.get(epic, 0)
        if actual != expected:
            errors.append(
                f"Epic {epic}: expected {expected} stories, found {actual}"
            )

    # Dependency target validation (after all IDs are known)
    adjacency: dict[str, list[str]] = {sid: [] for sid in by_id}
    for story_id, story in by_id.items():
        deps = story.get("dependencies")
        if not isinstance(deps, list):
            continue
        for dep in deps:
            if not isinstance(dep, str):
                continue
            if dep not in by_id:
                errors.append(
                    f"{story_id}: dependency {dep} does not exist in the registry"
                )
            else:
                adjacency[story_id].append(dep)

    for cycle in detect_cycles(adjacency):
        errors.append("circular dependency: " + " -> ".join(cycle))

    # Source heading validation
    for story_id, story in by_id.items():
        source = story.get("source")
        title = story.get("title")
        if not isinstance(source, str) or not isinstance(title, str):
            continue
        source_path = catalogue_dir / source
        if not source_path.is_file():
            continue
        text = source_path.read_text(encoding="utf-8")
        heading = story_heading(story_id, title)
        count = text.count(heading)
        if count != 1:
            errors.append(
                f"{story_id}: expected heading {heading!r} exactly once in "
                f"{source}, found {count}"
            )

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate docs/planning/story-catalogue/stories.yml"
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=None,
        help="Path to stories.yml (default: catalogue stories.yml)",
    )
    parser.add_argument(
        "--catalogue-dir",
        type=Path,
        default=None,
        help="Directory containing Epic-*-Stories.md files",
    )
    args = parser.parse_args(argv)

    registry_path = args.registry or default_registry_path()
    catalogue_dir = args.catalogue_dir or default_catalogue_dir()

    try:
        stories = load_registry(registry_path)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    errors = validate_stories(stories, catalogue_dir)
    if errors:
        print(f"Story catalogue validation failed with {len(errors)} error(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(f"OK: validated {len(stories)} stories in {registry_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
