#!/usr/bin/env python3
"""Validate TestFlight release readiness artefacts for E6-S05."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    testing_notes = ROOT / "fastlane" / "testing_notes.txt"
    fastfile = ROOT / "fastlane" / "Fastfile"
    release_doc = ROOT / "docs" / "planning" / "validation" / "TestFlight-Release.md"
    tester_doc = (
        ROOT / "docs" / "planning" / "validation" / "TestFlight-Tester-Instructions.md"
    )
    pbxproj = ROOT / "delivery-game.xcodeproj" / "project.pbxproj"
    merged = ROOT / ".github" / "workflows" / "merged.yml"

    for path in (testing_notes, fastfile, release_doc, tester_doc, pbxproj, merged):
        if not path.is_file():
            fail(f"missing required file: {path.relative_to(ROOT)}")

    notes = testing_notes.read_text(encoding="utf-8").strip()
    if not notes:
        fail("fastlane/testing_notes.txt is empty")
    if "Couriers Gambit" not in notes and "MVP" not in notes and "Job" not in notes:
        fail("fastlane/testing_notes.txt should mention MVP play focus")

    fastfile_text = fastfile.read_text(encoding="utf-8")
    if 'TESTFLIGHT_EXTERNAL_GROUP = "External"' not in fastfile_text:
        fail("Fastfile must define TESTFLIGHT_EXTERNAL_GROUP = \"External\"")
    if "distribute_external: true" not in fastfile_text:
        fail("Fastfile deploy must set distribute_external: true")
    if "groups: [TESTFLIGHT_EXTERNAL_GROUP]" not in fastfile_text:
        fail("Fastfile deploy must assign the External group")

    pbx = pbxproj.read_text(encoding="utf-8")
    versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", pbx))
    if "1.0" not in versions:
        fail(f"expected MARKETING_VERSION 1.0 in Xcode project, found {sorted(versions)}")

    release_text = release_doc.read_text(encoding="utf-8")
    for needle in (
        "Couriers Gambit App Store Profile",
        "External",
        "Internal",
        "testing_notes.txt",
        "Known limitations",
    ):
        if needle not in release_text:
            fail(f"TestFlight-Release.md missing required section/mention: {needle}")

    tester_text = tester_doc.read_text(encoding="utf-8")
    for needle in (
        "Jobs 1",
        "Direct but Risky",
        "Fast Lane Temptation",
        "Deadline Pressure",
        "Known limitations",
    ):
        if needle not in tester_text:
            fail(f"TestFlight-Tester-Instructions.md missing required mention: {needle}")

    merged_text = merged.read_text(encoding="utf-8")
    if "bundle exec fastlane deploy" not in merged_text:
        fail("merged.yml must invoke fastlane deploy")

    print("OK: TestFlight release readiness checks passed")


if __name__ == "__main__":
    main()
