#!/usr/bin/env python3
"""Diagnose another driver after a failed default launch; never replace its gate."""
import json
import plistlib
import subprocess
import sys
import time
from pathlib import Path

app, destination = map(Path, sys.argv[1:3])
driver = sys.argv[3]
if driver not in ("metal", "vulkan"):
    raise SystemExit("Expected metal or vulkan")
destination.mkdir(parents=True, exist_ok=True)
with (app / "Contents/Info.plist").open("rb") as handle:
    executable = plistlib.load(handle)["CFBundleExecutable"]
stem = destination / ("probe-" + driver)
report = stem.with_suffix(".json").resolve()
command = [str((app / "Contents/MacOS" / executable).resolve()),
           "--rendering-driver", driver, "--audio-driver", "Dummy",
           "res://scenes/main/self_test.tscn", "--",
           "--selftest-report=" + str(report),
           "--selftest-screenshot=" + str(stem.with_suffix(".png").resolve())]
started = time.monotonic()
with stem.with_suffix(".log").open("w") as log:
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
    try:
        code = process.wait(timeout=300)
        status = {"exit_code": code, "external_timeout": False}
    except subprocess.TimeoutExpired:
        try:
            subprocess.run(["sample", str(process.pid), "3", "-file",
                            str(stem.with_suffix(".stack.txt"))],
                           stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT,
                           timeout=12)
        except (OSError, subprocess.TimeoutExpired):
            pass
        process.kill()
        process.wait()
        code = -9
        status = {"exit_code": code, "external_timeout": True}
status.update(driver=driver, elapsed_seconds=time.monotonic() - started,
              scope="Diagnostic only; the failed default-driver gate stays failed.")
if report.exists():
    result = json.loads(report.read_text())
    status.update(selftest_passed=result.get("passed", False),
                  fatal=result.get("fatal"),
                  actual_driver=result.get("rendering_driver"))
stem.with_suffix(".status.json").write_text(json.dumps(status, indent=2) + "\n")
print(json.dumps(status))
check = Path(__file__).with_name("check_selftest.py")
raise SystemExit(subprocess.run([sys.executable, str(check), str(report),
                                "--exit-code", str(code), "--expect-window",
                                "--expect-arch", "arm64",
                                "--label", "diagnostic-" + driver]).returncode)
