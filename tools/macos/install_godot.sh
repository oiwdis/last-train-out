#!/usr/bin/env bash
# Installs the official Godot editor and macOS export template used to build the app.
#
#   tools/macos/install_godot.sh
#
# Written for the GitHub Actions macOS runner; it also works on a Mac. Both
# downloads come from the official Godot release and are checked against the
# SHA-512 checksums pinned below, so a changed or corrupted file stops the build.
#
# Everything is kept in $GODOT_CI_DIR (default ~/godot-ci), which the workflow
# caches. The export template is copied to where Godot looks for templates.
# On GitHub Actions the editor's path is exported as $GODOT for later steps.
set -euo pipefail

GODOT_VERSION="4.5.1-stable"
RELEASE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"

EDITOR_ZIP="Godot_v${GODOT_VERSION}_macos.universal.zip"
EDITOR_SHA512="a91a7c3bb2faefafef41624fbd75705b91aec509823d41db595a38b79819e0f2e9c85eecdc7429c3159d8070604a3f4b4425aaa6094d7bcac147f52c89181ce9"
TEMPLATES_TPZ="Godot_v${GODOT_VERSION}_export_templates.tpz"
TEMPLATES_SHA512="8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5"

# Godot names its template folder "4.5.1.stable" for the release "4.5.1-stable".
TEMPLATE_VERSION="${GODOT_VERSION/-/.}"
INSTALL_DIR="${GODOT_CI_DIR:-$HOME/godot-ci}"
GODOT_BIN="$INSTALL_DIR/Godot.app/Contents/MacOS/Godot"
TEMPLATE_ZIP="$INSTALL_DIR/templates/macos.zip"
MARKER="$INSTALL_DIR/.installed-${GODOT_VERSION}"
TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/$TEMPLATE_VERSION"

if [ "$(uname -s)" != "Darwin" ]; then
	echo "This script installs the macOS build of Godot and must run on macOS." >&2
	exit 2
fi

download() { # <file name> <expected sha512>
	local file="$1" expected="$2"
	echo "Downloading $file"
	curl --fail --location --silent --show-error --retry 3 --retry-delay 5 \
		--output "$INSTALL_DIR/$file" "$RELEASE_URL/$file"
	echo "$expected  $INSTALL_DIR/$file" | shasum -a 512 -c - >/dev/null || {
		echo "Checksum mismatch for $file: refusing to use it." >&2
		rm -f "$INSTALL_DIR/$file"
		exit 1
	}
	echo "Checksum verified: $file"
}

if [ -f "$MARKER" ] && [ -x "$GODOT_BIN" ] && [ -f "$TEMPLATE_ZIP" ]; then
	echo "Godot $GODOT_VERSION is already installed in $INSTALL_DIR (restored from cache)."
else
	rm -rf "$INSTALL_DIR"
	mkdir -p "$INSTALL_DIR/templates"

	download "$EDITOR_ZIP" "$EDITOR_SHA512"
	ditto -x -k "$INSTALL_DIR/$EDITOR_ZIP" "$INSTALL_DIR"
	rm -f "$INSTALL_DIR/$EDITOR_ZIP"

	# The template archive holds every platform (about 1.3 GB); only macos.zip is kept.
	download "$TEMPLATES_TPZ" "$TEMPLATES_SHA512"
	unzip -q -j -o "$INSTALL_DIR/$TEMPLATES_TPZ" "templates/macos.zip" -d "$INSTALL_DIR/templates"
	rm -f "$INSTALL_DIR/$TEMPLATES_TPZ"

	touch "$MARKER"
fi

mkdir -p "$TEMPLATE_DIR"
cp -f "$TEMPLATE_ZIP" "$TEMPLATE_DIR/macos.zip"

INSTALLED_VERSION="$("$GODOT_BIN" --version)"
echo "Godot editor: $GODOT_BIN ($INSTALLED_VERSION)"
echo "Export template: $TEMPLATE_DIR/macos.zip"
case "$INSTALLED_VERSION" in
	"$TEMPLATE_VERSION"*) ;;
	*)
		echo "Expected Godot $TEMPLATE_VERSION but found $INSTALLED_VERSION." >&2
		exit 1
		;;
esac

if [ -n "${GITHUB_ENV:-}" ]; then
	echo "GODOT=$GODOT_BIN" >> "$GITHUB_ENV"
fi
