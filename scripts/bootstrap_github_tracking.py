#!/usr/bin/env python3
"""Idempotently create Story Catalogue GitHub labels and issues via `gh`.

The cloud-agent GitHub token is often read-only for Issues/Labels/Projects.
Run this script locally (or in CI with a classic PAT that has `repo` scope)
after the delivery workflow harness is merged:

    python3 scripts/bootstrap_github_tracking.py

It will:
- create missing labels listed in Delivery-Workflow / task requirements;
- create one issue per stories.yml entry if no issue title already starts
  with that story ID;
- print Project board setup commands (Projects API often needs extra scopes).

Does not delete or rename existing labels. Does not copy full story scope
into issue bodies.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    sys.stderr.write("error: PyYAML is required. Install with: pip install pyyaml\n")
    sys.exit(2)

ISSUE_TITLE_RE = re.compile(r"^\[(E\d+-S\d+)\]\s+")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def run_gh(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    cmd = ["gh", *args]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        raise RuntimeError(
            f"gh {' '.join(args)} failed ({result.returncode}): "
            f"{result.stderr.strip() or result.stdout.strip()}"
        )
    return result


def slugify_heading(story_id: str, title: str) -> str:
    """Approximate GitHub Markdown heading anchors."""
    raw = f"{story_id} — {title}".lower()
    # GitHub: lowercase, spaces to -, strip most punctuation, keep unicode letters
    out = []
    for ch in raw:
        if ch.isalnum() or ch in ("-", " "):
            out.append(ch)
        elif ch in ("—", "–"):
            out.append("")
    anchor = "".join(out)
    anchor = re.sub(r"\s+", "-", anchor.strip())
    anchor = re.sub(r"-{2,}", "--", anchor)  # keep double hyphen from em dash removal gap
    # Standard GitHub: em dash becomes nothing, leaving double hyphen between id and title words?
    # Actually "E5-S01 — Card" -> "e5-s01--card-rule-definitions" (em dash removed, spaces to -)
    # Our removal of em dash leaves "e5-s01  card" -> "e5-s01-card" after whitespace collapse.
    # GitHub keeps a blank that becomes extra hyphen: e5-s01--card-rule-definitions
    # Recreate properly:
    text = f"{story_id} — {title}".lower()
    # Replace em/en dashes with nothing (GitHub leaves adjacent hyphens from spaces)
    text = text.replace("—", "").replace("–", "")
    cleaned = []
    for ch in text:
        if ch.isalnum() or ch == " " or ch == "-":
            cleaned.append(ch)
    collapsed = "".join(cleaned)
    collapsed = re.sub(r" +", "-", collapsed.strip())
    collapsed = re.sub(r"-{3,}", "--", collapsed)
    return collapsed


def heading_anchor(story_id: str, title: str) -> str:
    # GitHub flavoured: "E5-S01 — Card Rule Definitions" -> e5-s01--card-rule-definitions
    s = f"{story_id} — {title}".lower()
    s = s.replace("—", "")
    chars = []
    for ch in s:
        if ch.isalnum() or ch == "-" or ch == " ":
            chars.append(ch)
        # drop other punctuation
    s = "".join(chars)
    s = re.sub(r"\s+", "-", s.strip())
    # After removing em dash, we had "e5-s01 " + " card..." -> "e5-s01--card..."
    # because there were spaces on both sides of the dash.
    # Our replace removed dash but left both spaces: "e5-s01  card" -> with \s+ -> single -
    # Fix: replace " — " with "--" semantics by using explicit pattern.
    s = f"{story_id.lower()}--{re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')}"
    return s


def load_stories(path: Path) -> list[dict[str, Any]]:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return list(data["stories"])


def ensure_labels(dry_run: bool) -> list[str]:
    labels = [
        ("type: story", "Implementation story from the Story Catalogue", "0E8A16"),
        ("status: blocked", "Story is blocked by dependencies or an unresolved decision", "D93F0B"),
        ("epic: 1", "Epic 1 Story Catalogue work", "1D76DB"),
        ("epic: 2", "Epic 2 Story Catalogue work", "1D76DB"),
        ("epic: 3", "Epic 3 Story Catalogue work", "1D76DB"),
        ("epic: 4", "Epic 4 Story Catalogue work", "1D76DB"),
        ("epic: 5", "Epic 5 Story Catalogue work", "1D76DB"),
        ("epic: 6", "Epic 6 Story Catalogue work", "1D76DB"),
        ("workstream: foundation", "Foundation / deck and generation workstream", "5319E7"),
        ("workstream: grid", "Grid and route construction workstream", "5319E7"),
        ("workstream: planning", "Route planning and analysis workstream", "5319E7"),
        ("workstream: execution", "Execution and hazard resolution workstream", "5319E7"),
        ("workstream: outcome", "Economy and outcome workstream", "5319E7"),
        ("workstream: polish", "Polish, validation and TestFlight workstream", "5319E7"),
    ]
    existing = run_gh(["label", "list", "--limit", "200", "--json", "name"])
    names = {item["name"] for item in json.loads(existing.stdout or "[]")}
    created: list[str] = []
    for name, description, color in labels:
        if name in names:
            print(f"label exists: {name}")
            continue
        if dry_run:
            print(f"dry-run create label: {name}")
            created.append(name)
            continue
        run_gh(
            [
                "label",
                "create",
                name,
                "--description",
                description,
                "--color",
                color,
            ]
        )
        print(f"created label: {name}")
        created.append(name)
    return created


def existing_story_issues() -> dict[str, int]:
    result = run_gh(
        [
            "issue",
            "list",
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,title",
        ]
    )
    found: dict[str, int] = {}
    for issue in json.loads(result.stdout or "[]"):
        match = ISSUE_TITLE_RE.match(issue.get("title") or "")
        if match and match.group(1) not in found:
            found[match.group(1)] = issue["number"]
    return found


def issue_body(story: dict[str, Any]) -> str:
    sid = story["id"]
    title = story["title"]
    source = story["source"]
    anchor = heading_anchor(sid, title)
    deps = story.get("dependencies") or []
    if deps:
        dep_lines = "\n".join(f"- {d}" for d in deps)
    else:
        dep_lines = "- None"
    path = f"docs/planning/story-catalogue/{source}#{anchor}"
    return f"""## Canonical story
`{sid} — {title}`

Source:
`{path}`

## Dependencies
{dep_lines}

## Completion requirements
- [ ] Canonical acceptance criteria are satisfied.
- [ ] Relevant automated tests pass.
- [ ] Implementation PR is merged.
- [ ] No unresolved review findings remain.
- [ ] Affected documentation is updated.

## Implementation notes
To be added during delivery.
"""


def ensure_issues(stories: list[dict[str, Any]], dry_run: bool) -> tuple[list[str], list[str]]:
    if dry_run:
        for story in stories:
            print(f"dry-run create issue: [{story['id']}] {story['title']}")
        return [s["id"] for s in stories], []

    existing = existing_story_issues()
    created: list[str] = []
    skipped: list[str] = []
    for story in stories:
        sid = story["id"]
        if sid in existing:
            print(f"issue exists: [{sid}] #{existing[sid]}")
            skipped.append(sid)
            continue
        title = f"[{sid}] {story['title']}"
        labels = [
            "type: story",
            f"epic: {story['epic']}",
            f"workstream: {story['workstream']}",
        ]
        body = issue_body(story)
        result = run_gh(
            [
                "issue",
                "create",
                "--title",
                title,
                "--body",
                body,
                "--label",
                labels[0],
                "--label",
                labels[1],
                "--label",
                labels[2],
            ]
        )
        print(f"created issue: {title} -> {result.stdout.strip()}")
        created.append(sid)
    return created, skipped


def print_project_instructions() -> None:
    print(
        """
# GitHub Project board (manual / elevated token)

The installed agent token cannot create Projects or Issues (HTTP 403).
With a PAT that has `repo` + `project` scopes, run:

  gh project create --owner amopatel1234 --title "Delivery Game MVP"

Then open the project in the GitHub UI and:

1. Add Status options: Backlog, Ready, In Progress, In Review, Blocked, Done
2. Add fields: Story ID (text), Epic (number), Workstream (single select),
   Priority (single select), Implementation PR (text)
3. Add all story issues to the project
4. Set initial Status:
   - no dependencies → Ready
   - has dependencies → Blocked
   - none → Done

Example (after noting the project number from create output):

  gh project item-add <project-number> --owner amopatel1234 --url <issue-url>
""".rstrip()
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--registry",
        type=Path,
        default=repo_root() / "docs" / "planning" / "story-catalogue" / "stories.yml",
    )
    parser.add_argument(
        "--skip-issues",
        action="store_true",
        help="Only ensure labels",
    )
    parser.add_argument(
        "--print-project-help",
        action="store_true",
        help="Print Project board setup commands and exit",
    )
    args = parser.parse_args(argv)

    if args.print_project_help:
        print_project_instructions()
        return 0

    stories = load_stories(args.registry)
    print(f"Loaded {len(stories)} stories from {args.registry}")

    try:
        ensure_labels(args.dry_run)
        if not args.skip_issues:
            created, skipped = ensure_issues(stories, args.dry_run)
            print(f"issues created={len(created)} skipped_existing={len(skipped)}")
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        print(
            "\nThe current `gh` token cannot write Issues/Labels "
            "(typical for GitHub App installation tokens used by cloud agents).",
            file=sys.stderr,
        )
        print(
            "Re-run locally with a PAT that has `repo` scope:\n"
            "  python3 scripts/bootstrap_github_tracking.py",
            file=sys.stderr,
        )
        print_project_instructions()
        return 1

    print_project_instructions()
    return 0


if __name__ == "__main__":
    sys.exit(main())
