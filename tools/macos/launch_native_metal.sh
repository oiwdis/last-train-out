#!/usr/bin/env bash
# Explicit Apple Silicon launch of the existing Forward+ game using native Metal.
set -euo pipefail
app="${1:?usage: launch_native_metal.sh '/path/to/Last Train Out.app' [Godot arguments]}"
shift
if [[ "$(uname -s)" != Darwin || "$(/usr/sbin/sysctl -n hw.optional.arm64 2>/dev/null || true)" != 1 ]]; then
  echo 'This launcher requires an Apple Silicon Mac.' >&2
  exit 2
fi
if [[ -x "$app/Contents/MacOS/choose-renderer" ]]; then
  exec /usr/bin/arch -arm64 "$app/Contents/MacOS/choose-renderer" metal "$@"
fi
exe=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")
exec /usr/bin/arch -arm64 "$app/Contents/MacOS/$exe" --rendering-method forward_plus --rendering-driver metal "$@"
