#!/usr/bin/env python3
"""Run Godot regression tests without touching the player's saved preferences."""

import argparse
import os
import subprocess
import tempfile
from pathlib import Path

SUITES = ("fox", "platform", "boss", "arrow", "game", "equipment", "route", "campaign")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "suite", nargs="*", help=f"Optional suites: {', '.join(SUITES)}"
    )
    args = parser.parse_args()
    suites = args.suite or SUITES
    for suite in suites:
        if suite not in SUITES:
            parser.error(f"unknown suite: {suite}")
    project = Path(__file__).resolve().parents[1]
    for suite in suites:
        with tempfile.TemporaryDirectory(prefix="emberwood-tests-") as test_dir:
            environment = dict(
                os.environ,
                XDG_DATA_HOME=test_dir,
                EMBERWOOD_TEST_DATA_DIR=test_dir,
            )
            print(f"Running {suite} tests with isolated saved data...", flush=True)
            try:
                result = subprocess.run(
                    [
                        str(project / "start-game.sh"),
                        "--headless",
                        "--script",
                        f"res://tests/test_{suite}.gd",
                    ],
                    cwd=project,
                    env=environment,
                    timeout=150,
                    check=False,
                )
            except subprocess.TimeoutExpired:
                print(f"The {suite} test suite exceeded its 150-second timeout.")
                return 1
            if result.returncode:
                return result.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
