#!/usr/bin/env python3
"""Reads the report written by a self-test launch of the exported app and fails if the
launch did not prove the game works.

    python3 tools/macos/check_selftest.py report.json --label arm64-window --exit-code 0 \
        --expect-window --expect-arch arm64

See scripts/main/self_test.gd for what the app checks about itself. A missing report means
the app did not start, crashed or hung. Uses only the Python standard library.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("report")
    parser.add_argument("--label", default="self-test")
    parser.add_argument("--exit-code", type=int, default=0, help="exit code of the launched app")
    parser.add_argument("--expect-arch", default="", help="architecture the app must have run as (arm64 or x86_64)")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--expect-window", action="store_true", help="the app must have opened a window and drawn the game")
    mode.add_argument("--expect-headless", action="store_true", help="the app must have run without a window")
    args = parser.parse_args()

    failures: list[str] = []
    print(f"\n=== self-test: {args.label} ===")
    path = Path(args.report)
    report: dict = {}
    if not path.is_file():
        failures.append("the launch produced no report: the app did not start, crashed or hung")
    else:
        try:
            report = json.loads(path.read_text(encoding="utf-8"))
        except ValueError as error:
            failures.append(f"the report is not valid JSON: {error}")

    thumbnail = report.pop("thumbnail", "")
    checks: dict = report.get("checks", {})
    details: dict = report.get("details", {})
    if report:
        for key in sorted(k for k in report if k not in ("checks", "details")):
            print(f"  {key}: {report[key]}")
        for name, ok in checks.items():
            detail = details.get(name, "")
            print(f"{'ok  ' if ok else 'FAIL'}  {name}{f'  ({detail})' if detail else ''}")
            if not ok:
                failures.append(f"check failed: {name}{f' ({detail})' if detail else ''}")
        if report.get("fatal"):
            failures.append(f"self-test aborted: {report['fatal']}")
        if not checks:
            failures.append("the report contains no checks")
        if not report.get("exported_build") or report.get("editor_build"):
            failures.append("the game was not running as an exported build (it must not need the Godot editor)")
        if args.expect_arch and report.get("architecture") != args.expect_arch:
            failures.append(f"expected the {args.expect_arch} half of the app to run, got {report.get('architecture')}")
        if args.expect_window:
            if report.get("headless"):
                failures.append("expected a windowed launch, but the app ran without a display")
            for required in ("frames_are_produced", "frame_is_not_blank"):
                if required not in checks:
                    failures.append(f"the windowed launch did not get as far as the '{required}' check")
        if args.expect_headless and not report.get("headless"):
            failures.append("expected a launch without a window")
    if args.exit_code != 0:
        failures.append(f"the app exited with code {args.exit_code}")

    # A small picture of what the app drew, so the log shows the frame and not only numbers.
    if thumbnail:
        print(f"THUMBNAIL-{args.label} {thumbnail}")

    for failure in failures:
        print(f"FAIL  {failure}")
    print("SELF-TEST FAILED" if failures else "SELF-TEST PASSED")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            status = ":x: failed" if failures else ":white_check_mark: passed"
            where = "no window" if report.get("headless") else f"window, {report.get('rendering_method', '?')} / {report.get('rendering_driver', '?')} on {report.get('video_adapter', '?')}"
            handle.write(f"- **Launch `{args.label}`**: {status} - {len(checks)} checks, {report.get('architecture', '?')}, "
                         f"{report.get('os', '?')}, {where}\n")
            for failure in failures:
                handle.write(f"  - {failure}\n")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
