"""TestFlight release readiness (E6-S05)."""

from __future__ import annotations

import runpy
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class TestFlightReleaseValidationTests(unittest.TestCase):
    def test_validate_testflight_release_script_passes(self) -> None:
        script = ROOT / "scripts" / "validate_testflight_release.py"
        runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    unittest.main()
