#!/usr/bin/env bash
# Build the optional Metal executable. The stock universal executable retains
# Vulkan and the official Intel template. Both read the identical game pack.
set -euo pipefail
dest="${1:?usage: build_metal_template.sh OUTPUT_DIRECTORY [EXPERIMENT_PATCH ...]}"
shift
mkdir -p "$dest"
dest="$(cd "$dest" && pwd)"
if [[ "$(uname -s)-$(uname -m)" != Darwin-arm64 ]]; then
  echo 'The Metal template requires a native arm64 macOS build host.' >&2
  exit 2
fi
revision=f62fdbde15035c5576dad93e586201f4d41ef0cb
patch_dir="$(cd "$(dirname "$0")" && pwd)"
patches=("$patch_dir/viewport-metal-sampler.patch" "$patch_dir/worker-pool-shutdown.patch" "$patch_dir/bundled-metal-libraries.patch")
for extra in "$@"; do patches+=("$(cd "$(dirname "$extra")" && pwd)/$(basename "$extra")"); done
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -C "$work" init --quiet
git -C "$work" fetch --quiet --depth 1 https://github.com/godotengine/godot.git "$revision"
git -C "$work" checkout --quiet --detach FETCH_HEAD
test "$(git -C "$work" rev-parse HEAD)" = "$revision"
git -C "$work" apply --check "${patches[@]}"
git -C "$work" apply "${patches[@]}"
cd "$work"
python3 -m venv "$work/build-env"
"$work/build-env/bin/pip" -q install 'scons==4.8.1'
# Use 4.5.1's ordinary release modules, including Jolt and GLES-independent
# shader compilation. The optional arm64 process only offers native Metal.
export BUILD_NAME=lto_metal
"$work/build-env/bin/scons" -j"$(sysctl -n hw.ncpu)" platform=macos target=template_release \
  arch=arm64 metal=yes vulkan=no opengl3=no lto=none > "$dest/compile.log" 2>&1 || {
  tail -100 "$dest/compile.log"
  exit 1
}
cp bin/godot.macos.template_release.arm64 "$dest/LastTrainOutMetal"
strip -x "$dest/LastTrainOutMetal"
codesign --force --sign - "$dest/LastTrainOutMetal"
{
  echo "Godot $revision"
  shasum -a 256 "${patches[@]}" "$dest/LastTrainOutMetal"
  xcodebuild -version
  "$dest/LastTrainOutMetal" --version
} | tee "$dest/provenance.txt"
