#!/usr/bin/env bash
# Validates the project and runs the automated tests, headless.
#
#   tools/run_tests.sh [path-to-godot]
#
# The Godot binary is taken from the first argument, then $GODOT, then "godot".
# On macOS that is usually: /Applications/Godot.app/Contents/MacOS/Godot
# Set MIN_TESTS to also require at least that many passing tests (the build
# uses it so that tests cannot silently go missing).
# Exit code is 0 only if every step succeeds.
set -u

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.." || exit 1
mkdir -p tests/_output
status=0

if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
	echo "Godot binary not found: $GODOT" >&2
	echo "Pass its path as the first argument or set \$GODOT." >&2
	exit 2
fi

echo "== 1/3  Import project (resources, script classes) =="
"$GODOT" --headless --path . --import >tests/_output/import.log 2>&1
if grep -nE "^(ERROR|SCRIPT ERROR)|Parse Error" tests/_output/import.log; then
	echo "FAILED: errors while importing (see tests/_output/import.log)"
	status=1
else
	echo "ok"
fi

echo "== 2/3  Main scene smoke test (600 frames, headless) =="
"$GODOT" --headless --path . --fixed-fps 60 --quit-after 600 >tests/_output/main_scene.log 2>&1
if grep -nE "ERROR|Parse Error" tests/_output/main_scene.log; then
	echo "FAILED: errors while running the main scene (see tests/_output/main_scene.log)"
	status=1
else
	echo "ok"
fi

echo "== 3/3  Automated tests =="
"$GODOT" --headless --path . --fixed-fps 60 tests/test_runner.tscn -- --report=tests/_output/results.json \
	| tee tests/_output/tests.log
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
	status=1
fi

if [ -n "${MIN_TESTS:-}" ]; then
	PASSED="$(sed -n 's/^=== \([0-9][0-9]*\) passed, .*/\1/p' tests/_output/tests.log | tail -n 1)"
	if [ -z "$PASSED" ] || [ "$PASSED" -lt "$MIN_TESTS" ]; then
		echo "FAILED: expected at least $MIN_TESTS passing tests, found ${PASSED:-none}"
		status=1
	fi
fi

if [ "$status" -eq 0 ]; then
	echo "ALL CHECKS PASSED"
else
	echo "SOME CHECKS FAILED"
fi
exit "$status"
