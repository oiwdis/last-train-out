#!/usr/bin/env bash
# Exports "Last Train Out.app" with the "macOS" preset in export_presets.cfg:
# one universal build (Apple Silicon + Intel) that contains the Godot runtime
# and all game data, so nothing else has to be installed to play it.
#
#   tools/macos/export_app.sh <godot-binary> [output.app]
#
# The matching export template must be installed (tools/macos/install_godot.sh).
# Optional environment, recorded in the app's Info.plist:
#   BUILD_NUMBER  CFBundleVersion (default 0)
#   BUILD_COMMIT  git commit of the build (default: the current HEAD)
#   BUILD_KIND    "development" or "distribution" (default: development)
set -euo pipefail

GODOT="${1:?usage: tools/macos/export_app.sh <godot-binary> [output.app]}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="${2:-$ROOT/build/macos/Last Train Out.app}"
case "$APP" in
	/*) ;;
	*) APP="$PWD/$APP" ;;
esac

BUILD_NUMBER="${BUILD_NUMBER:-0}"
BUILD_COMMIT="${BUILD_COMMIT:-$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)}"
BUILD_KIND="${BUILD_KIND:-development}"

case "$BUILD_NUMBER" in
	'' | *[!0-9]*)
		echo "BUILD_NUMBER must be a whole number, got '$BUILD_NUMBER'." >&2
		exit 2
		;;
esac
case "$BUILD_COMMIT$BUILD_KIND" in
	*[!A-Za-z0-9._-]*)
		echo "BUILD_COMMIT and BUILD_KIND may only contain letters, digits, '.', '_' and '-'." >&2
		exit 2
		;;
esac

cd "$ROOT"
PRESET="export_presets.cfg"
BACKUP="$(mktemp)"
cp "$PRESET" "$BACKUP"
restore_preset() {
	cp "$BACKUP" "$PRESET"
	rm -f "$BACKUP"
}
trap restore_preset EXIT

# Stamp the build into the preset for this export only; the committed file is restored afterwards.
PLIST_EXTRA="<key>LTOBuildNumber</key><string>${BUILD_NUMBER}</string><key>LTOBuildCommit</key><string>${BUILD_COMMIT}</string><key>LTOBuildKind</key><string>${BUILD_KIND}</string>"
sed \
	-e "s|^application/version=.*|application/version=\"${BUILD_NUMBER}\"|" \
	-e "s|^application/additional_plist_content=.*|application/additional_plist_content=\"${PLIST_EXTRA}\"|" \
	"$BACKUP" > "$PRESET"

rm -rf "$APP"
mkdir -p "$(dirname "$APP")"
# The graphical editor keeps scanning while shaders bake. Do not import the
# bundle being written inside this project's build directory (including .icns).
mkdir -p "$ROOT/build"
touch "$ROOT/build/.gdignore"
LOG="$(dirname "$APP")/export.log"

echo "Exporting build $BUILD_NUMBER ($BUILD_KIND, commit $BUILD_COMMIT) to $APP"
# Refresh the export-only inventory from the actual generated game materials.
# Its one-pixel maps preserve shader features without duplicating source images.
"$GODOT" --headless --path "$ROOT" --script tools/assets/bake_runtime_materials.gd > "$(dirname "$APP")/shader-inventory.log" 2>&1
# Godot 4.5 silently skips shader baking with the dummy/headless renderer.
# Native Mac exports need the configured real renderer, even without an editor UI.
EXPORT_RENDERER=(--headless)
if [ "$(uname -s)" = Darwin ]; then
	MAC_DRIVER="$(python3 -c 'from tools.macos.verify_app import project_setting; print(project_setting("rendering_device/driver.macos") or "metal")')"
	case "$MAC_DRIVER" in metal|vulkan) ;; *) echo "Unsupported Mac rendering driver: $MAC_DRIVER" >&2; exit 1 ;; esac
	EXPORT_RENDERER=(--rendering-method forward_plus --rendering-driver "$MAC_DRIVER" --audio-driver Dummy)
fi
set +e
"$GODOT" "${EXPORT_RENDERER[@]}" --path "$ROOT" --export-release "macOS" "$APP" > "$LOG" 2>&1
CODE=$?
set -e

# Show the interesting part of Godot's log (the per-file progress lines are noise).
grep -vE 'savepack|reimport|first_scan_filesystem|update_scripts_classes|loading_editor_layout|^[[:space:]]*$' "$LOG" | tail -n 40 || true

if [ "$CODE" -ne 0 ]; then
	echo "Godot exited with code $CODE: the export failed (full log: $LOG)." >&2
	exit 1
fi
if grep -q "Project export for preset .* failed" "$LOG"; then
	echo "Godot reported that the export failed (full log: $LOG)." >&2
	exit 1
fi
if [ ! -d "$APP" ]; then
	echo "The export finished but $APP does not exist (full log: $LOG)." >&2
	exit 1
fi
if [ "$(uname -s)" = Darwin ] && ! grep -qi "$MAC_DRIVER.*Forward+" "$LOG"; then
	echo "The native export did not initialize the $MAC_DRIVER shader-baking backend (full log: $LOG)." >&2
	exit 1
fi
if [ "$(uname -s)" = Darwin ]; then
	# Keep the stock Godot executable and its single PCK untouched. The optional
	# selector is a second universal executable, signed inside the same bundle.
	METAL_TEMPLATE="${LTO_METAL_TEMPLATE:-}"
	if [ -z "$METAL_TEMPLATE" ]; then
		tools/macos/engine/build_metal_template.sh "$(dirname "$APP")/metal-template"
		METAL_TEMPLATE="$(dirname "$APP")/metal-template/LastTrainOutMetal"
	fi
	install -m 755 "$METAL_TEMPLATE" "$APP/Contents/MacOS/LastTrainOutMetal"
	codesign --force --sign - "$APP/Contents/MacOS/LastTrainOutMetal"
	CHOOSER="$APP/Contents/MacOS/choose-renderer"
	xcrun clang -fobjc-arc -O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
		-framework Metal -framework Foundation tools/macos/choose_renderer.m -o "$CHOOSER"
	codesign --force --sign - "$CHOOSER"
	cp tools/macos/notices/Godot-*.txt "$APP/Contents/Resources/"
	python3 tools/macos/prepare_metal_shaders.py "$APP" "$(dirname "$APP")/metal-inventory"
	codesign --force --sign - "$APP"
fi
echo "Exported $APP ($(du -sh "$APP" | cut -f1))"
