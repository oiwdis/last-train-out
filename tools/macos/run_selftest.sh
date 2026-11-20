#!/usr/bin/env bash
# Launches an exported "Last Train Out.app" in self-test mode and checks its report.
#
#   tools/macos/run_selftest.sh <path/to/Last Train Out.app> <label> [--headless] [--expect-arch arm64|x86_64]
#
# The app is started directly (no Godot editor involved) with its self-test
# scene. It loads the real game, drives the player and the train for a few
# seconds, writes a JSON report and quits; see scripts/main/self_test.gd.
# Without --headless the app opens its window and renders, and the report
# includes a small picture of the frame.
#
# Reports, logs and screenshots go to $SELFTEST_DIR (default: $RUNNER_TEMP/selftest
# or /tmp/selftest). Exit code 0 means the launch passed.
set -euo pipefail

APP="${1:?usage: tools/macos/run_selftest.sh <App.app> <label> [--headless] [--expect-arch ARCH]}"
LABEL="${2:?a label for this launch is required}"
shift 2
HEADLESS=0
EXPECT_ARCH=""
while [ "$#" -gt 0 ]; do
	case "$1" in
		--headless) HEADLESS=1 ;;
		--expect-arch)
			EXPECT_ARCH="${2:?--expect-arch needs a value}"
			shift
			;;
		*)
			echo "Unknown option: $1" >&2
			exit 2
			;;
	esac
	shift
done

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${SELFTEST_DIR:-${RUNNER_TEMP:-/tmp}/selftest}"
mkdir -p "$OUT"
REPORT="$OUT/selftest-$LABEL.json"
SCREENSHOT="$OUT/selftest-$LABEL.png"
LOG="$OUT/selftest-$LABEL.log"
rm -f "$REPORT" "$SCREENSHOT" "$LOG"

EXECUTABLE_NAME="$(python3 -c 'import plistlib, sys; print(plistlib.load(open(sys.argv[1], "rb"))["CFBundleExecutable"])' "$APP/Contents/Info.plist")"
BIN="$APP/Contents/MacOS/$EXECUTABLE_NAME"
if [ ! -x "$BIN" ]; then
	echo "The executable $BIN is missing or not executable." >&2
	exit 1
fi

ARGS=()
CHECK=(--label "$LABEL")
if [ "$HEADLESS" -eq 1 ]; then
	ARGS+=(--headless)
	CHECK+=(--expect-headless)
else
	CHECK+=(--expect-window)
fi
ARGS+=("res://scenes/main/self_test.tscn" "--" "--selftest-report=$REPORT")
if [ "$HEADLESS" -eq 0 ]; then
	ARGS+=("--selftest-screenshot=$SCREENSHOT")
fi
if [ -n "$EXPECT_ARCH" ]; then
	CHECK+=(--expect-arch "$EXPECT_ARCH")
fi

echo "Launching $BIN ${ARGS[*]}"
"$BIN" "${ARGS[@]}" > "$LOG" 2>&1 &
PID=$!
# The self-test has its own watchdog; this one catches an app that never gets that far.
( sleep 300; kill -9 "$PID" 2>/dev/null ) &
WATCHDOG=$!
set +e
wait "$PID"
CODE=$?
set -e
kill "$WATCHDOG" 2>/dev/null || true
echo "The app exited with code $CODE. Last lines of its output:"
tail -n 40 "$LOG" || true

python3 "$ROOT/tools/macos/check_selftest.py" "$REPORT" --exit-code "$CODE" "${CHECK[@]}"
python3 "$ROOT/tools/macos/renderer_diagnostics.py" "$LOG"
