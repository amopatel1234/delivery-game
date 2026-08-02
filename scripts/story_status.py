#!/usr/bin/env python3
"""Report delivery status for Story Catalogue items using GitHub Issues/PRs."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.stderr.write(
        "error: PyYAML is required. Install with: pip install pyyaml\n"
    )
    sys.exit(2)

STORY_ID_RE = re.compile(r"^E\d+-S\d+$")
ISSUE_TITLE_RE = re.compile(r"^\[(E\d+-S\d+)\]\s+")

STATUSES = (
    "Backlog",
    "Ready",
    "In Progress",
    "In Review",
    "Blocked",
    "Done",
)


@dataclass
class StoryRecord:
    id: str
    title: str
    epic: int
    workstream: str
    dependencies: list[str]
    status: str
    blocking_dependencies: list[str] = field(default_factory=list)
    issue_number: int | None = None
    issue_state: str | None = None
    issue_assignees: list[str] = field(default_factory=list)
    pr_number: int | None = None
    pr_state: str | None = None
    pr_merged: bool = False
    labels: list[str] = field(default_factory=list)


@dataclass
class GithubStoryState:
    """Observed GitHub state for a single story ID."""

    issue_number: int | None = None
    issue_state: str | None = None  # open | closed
    issue_assignees: list[str] = field(default_factory=list)
    labels: list[str] = field(default_factory=list)
    has_branch_or_pr_activity: bool = False
    open_pr_number: int | None = None
    merged_pr_number: int | None = None
    any_pr_number: int | None = None
    blocked_label: bool = False


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_registry_path() -> Path:
    return repo_root() / "docs" / "planning" / "story-catalogue" / "stories.yml"


def load_stories(registry_path: Path) -> list[dict[str, Any]]:
    data = yaml.safe_load(registry_path.read_text(encoding="utf-8"))
    stories = data.get("stories", [])
    if not isinstance(stories, list):
        raise ValueError("stories.yml must contain a 'stories' list")
    return stories


def classify_status(
    *,
    dependency_statuses: dict[str, str],
    dependencies: list[str],
    github: GithubStoryState | None,
) -> tuple[str, list[str]]:
    """Classify a story status from dependencies and GitHub state.

    Priority (highest first after Done/In Review/In Progress checks):
    - Done: linked issue closed AND linked PR merged
    - In Review: open PR exists
    - Blocked: one or more dependencies are not Done
    - In Progress: issue open and assigned, or branch/PR activity, but no open PR
    - Ready: all dependencies Done and issue open
    - Backlog: no issue exists yet

    Note: Project board fields are intentionally not queried. Status is derived
    from issues, pull requests and the dependency graph only.
    """
    blocking = [
        dep
        for dep in dependencies
        if dependency_statuses.get(dep, "Backlog") != "Done"
    ]

    if github is None or github.issue_number is None:
        if blocking:
            return "Blocked", blocking
        return "Backlog", blocking

    issue_closed = github.issue_state == "closed"
    if issue_closed and github.merged_pr_number is not None:
        return "Done", []

    if github.open_pr_number is not None:
        return "In Review", blocking

    if blocking or github.blocked_label:
        return "Blocked", blocking

    assigned = bool(github.issue_assignees)
    active = assigned or github.has_branch_or_pr_activity
    if github.issue_state == "open" and active:
        return "In Progress", []

    if github.issue_state == "open" and not blocking:
        return "Ready", []

    # Closed issue without a merged PR is incomplete — treat as In Progress
    # if there is still activity, otherwise Ready/Blocked by deps already handled.
    if issue_closed and github.merged_pr_number is None:
        if active:
            return "In Progress", []
        return "Ready" if not blocking else "Blocked", blocking

    return "Backlog", blocking


def build_status_report(
    stories: list[dict[str, Any]],
    github_by_id: dict[str, GithubStoryState],
) -> list[StoryRecord]:
    """Compute statuses for all stories, resolving Done first for dependency checks."""
    by_id = {s["id"]: s for s in stories}
    # First pass: determine which stories are Done based purely on GitHub,
    # ignoring dependency blocking for the Done check.
    provisional: dict[str, str] = {}
    for story in stories:
        sid = story["id"]
        gh = github_by_id.get(sid)
        if (
            gh
            and gh.issue_number is not None
            and gh.issue_state == "closed"
            and gh.merged_pr_number is not None
        ):
            provisional[sid] = "Done"
        else:
            provisional[sid] = "Unknown"

    # Iterate to stable statuses so dependency Done checks are accurate.
    # We process in dependency order via repeated passes.
    final: dict[str, StoryRecord] = {}
    remaining = set(by_id)
    guard = 0
    while remaining and guard < len(by_id) + 5:
        guard += 1
        progressed = set()
        for sid in list(remaining):
            story = by_id[sid]
            deps = list(story.get("dependencies") or [])
            # Wait until all deps have final status, unless we can already see Done
            if any(dep not in final and provisional.get(dep) != "Done" for dep in deps):
                # Allow progress if all deps are either final or provisionally Done
                if any(dep not in final and dep in remaining for dep in deps):
                    # Check if deps are only waiting on us (shouldn't happen — acyclic)
                    if not all(
                        dep in final or provisional.get(dep) == "Done" or dep not in remaining
                        for dep in deps
                    ):
                        # Try again if all deps already finalized
                        if not all(dep in final for dep in deps):
                            continue

            dep_statuses = {
                dep: (
                    final[dep].status
                    if dep in final
                    else provisional.get(dep, "Backlog")
                )
                for dep in deps
            }
            # Prefer finalized statuses
            for dep in deps:
                if dep in final:
                    dep_statuses[dep] = final[dep].status

            gh = github_by_id.get(sid, GithubStoryState())
            status, blocking = classify_status(
                dependency_statuses=dep_statuses,
                dependencies=deps,
                github=gh if gh.issue_number is not None else (
                    None if sid not in github_by_id else gh
                ),
            )
            # If story has no github entry at all
            if sid not in github_by_id:
                status, blocking = classify_status(
                    dependency_statuses=dep_statuses,
                    dependencies=deps,
                    github=None,
                )

            pr_number = None
            pr_state = None
            pr_merged = False
            if gh:
                if gh.open_pr_number is not None:
                    pr_number = gh.open_pr_number
                    pr_state = "open"
                elif gh.merged_pr_number is not None:
                    pr_number = gh.merged_pr_number
                    pr_state = "merged"
                    pr_merged = True
                elif gh.any_pr_number is not None:
                    pr_number = gh.any_pr_number
                    pr_state = "closed"

            final[sid] = StoryRecord(
                id=sid,
                title=story["title"],
                epic=story["epic"],
                workstream=story["workstream"],
                dependencies=deps,
                status=status,
                blocking_dependencies=blocking,
                issue_number=gh.issue_number if gh else None,
                issue_state=gh.issue_state if gh else None,
                issue_assignees=list(gh.issue_assignees) if gh else [],
                pr_number=pr_number,
                pr_state=pr_state,
                pr_merged=pr_merged,
                labels=list(gh.labels) if gh else [],
            )
            progressed.add(sid)
        remaining -= progressed
        if not progressed:
            # Break cycles / unresolved — classify remaining with best-effort deps
            for sid in list(remaining):
                story = by_id[sid]
                deps = list(story.get("dependencies") or [])
                dep_statuses = {
                    dep: final[dep].status if dep in final else "Backlog"
                    for dep in deps
                }
                gh = github_by_id.get(sid)
                status, blocking = classify_status(
                    dependency_statuses=dep_statuses,
                    dependencies=deps,
                    github=gh,
                )
                final[sid] = StoryRecord(
                    id=sid,
                    title=story["title"],
                    epic=story["epic"],
                    workstream=story["workstream"],
                    dependencies=deps,
                    status=status,
                    blocking_dependencies=blocking,
                    issue_number=gh.issue_number if gh else None,
                    issue_state=gh.issue_state if gh else None,
                    issue_assignees=list(gh.issue_assignees) if gh else [],
                    labels=list(gh.labels) if gh else [],
                )
                remaining.discard(sid)

    # Preserve registry order
    return [final[s["id"]] for s in stories]


def run_gh(args: list[str], repo: str | None = None) -> Any:
    cmd = ["gh", *args]
    if repo:
        if "--repo" not in args and "-R" not in args:
            cmd = ["gh", "--repo", repo, *args]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(
            f"gh {' '.join(args)} failed: {result.stderr.strip() or result.stdout.strip()}"
        )
    if not result.stdout.strip():
        return None
    return json.loads(result.stdout)


def detect_repo() -> str | None:
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except OSError:
        return None
    return None


def fetch_github_state(repo: str | None) -> dict[str, GithubStoryState]:
    """Fetch issues and PRs whose titles begin with a story ID."""
    states: dict[str, GithubStoryState] = {}

    def ensure(sid: str) -> GithubStoryState:
        if sid not in states:
            states[sid] = GithubStoryState()
        return states[sid]

    issues = run_gh(
        [
            "issue",
            "list",
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,title,state,assignees,labels,body",
        ],
        repo=repo,
    ) or []

    for issue in issues:
        title = issue.get("title") or ""
        match = ISSUE_TITLE_RE.match(title)
        if not match:
            continue
        sid = match.group(1)
        st = ensure(sid)
        # Prefer the first match; later duplicates keep the existing record
        if st.issue_number is not None:
            continue
        st.issue_number = issue["number"]
        st.issue_state = (issue.get("state") or "").lower()
        st.issue_assignees = [
            a.get("login") for a in (issue.get("assignees") or []) if a.get("login")
        ]
        st.labels = [
            lab.get("name") for lab in (issue.get("labels") or []) if lab.get("name")
        ]
        st.blocked_label = "status: blocked" in st.labels

    prs = run_gh(
        [
            "pr",
            "list",
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,title,state,mergedAt,headRefName,body",
        ],
        repo=repo,
    ) or []

    for pr in prs:
        title = pr.get("title") or ""
        body = pr.get("body") or ""
        branch = pr.get("headRefName") or ""
        sid = None
        title_match = re.match(r"^\[(E\d+-S\d+)\]", title)
        if title_match:
            sid = title_match.group(1)
        else:
            branch_match = re.match(r"^story/(e\d+-s\d+)-", branch, re.IGNORECASE)
            if branch_match:
                sid = branch_match.group(1).upper()
            else:
                body_match = STORY_ID_RE.search(body)
                if body_match:
                    sid = body_match.group(0)
        if not sid:
            continue
        st = ensure(sid)
        st.has_branch_or_pr_activity = True
        st.any_pr_number = st.any_pr_number or pr["number"]
        merged = bool(pr.get("mergedAt"))
        state = (pr.get("state") or "").lower()
        if merged:
            st.merged_pr_number = pr["number"]
        elif state == "open":
            st.open_pr_number = pr["number"]

    return states


def format_human(records: list[StoryRecord]) -> str:
    lines = [
        "Story delivery status",
        "(Derived from issues, PRs and dependencies — Project board fields are not queried.)",
        "",
    ]
    counts: dict[str, int] = {s: 0 for s in STATUSES}
    for rec in records:
        counts[rec.status] = counts.get(rec.status, 0) + 1

    lines.append(
        "Summary: "
        + ", ".join(f"{status}={counts.get(status, 0)}" for status in STATUSES)
    )
    lines.append("")

    for rec in records:
        issue = f"#{rec.issue_number}" if rec.issue_number else "-"
        pr = f"#{rec.pr_number}" if rec.pr_number else "-"
        blocking = (
            ", ".join(rec.blocking_dependencies)
            if rec.blocking_dependencies
            else "-"
        )
        lines.append(
            f"{rec.id:7}  {rec.status:12}  issue={issue:5}  pr={pr:5}  "
            f"blocking={blocking}  {rec.title}"
        )
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Report Story Catalogue delivery status via GitHub CLI"
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--repo", help="GitHub repo (owner/name); auto-detected if omitted")
    parser.add_argument(
        "--registry",
        type=Path,
        default=None,
        help="Path to stories.yml",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Skip GitHub queries; treat all stories as Backlog/Blocked from deps only",
    )
    args = parser.parse_args(argv)

    registry_path = args.registry or default_registry_path()
    try:
        stories = load_stories(registry_path)
    except (OSError, yaml.YAMLError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    repo = args.repo or detect_repo()
    if args.offline:
        github_by_id: dict[str, GithubStoryState] = {}
    else:
        try:
            github_by_id = fetch_github_state(repo)
        except RuntimeError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            print(
                "Hint: ensure `gh` is authenticated, or pass --offline / --repo.",
                file=sys.stderr,
            )
            return 1

    records = build_status_report(stories, github_by_id)
    if args.json:
        payload = {
            "repo": repo,
            "limitation": (
                "Status is derived from GitHub Issues, Pull Requests and "
                "stories.yml dependencies. GitHub Project board fields are not queried."
            ),
            "stories": [asdict(r) for r in records],
        }
        print(json.dumps(payload, indent=2))
    else:
        if repo:
            print(f"Repository: {repo}")
        print(format_human(records), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
