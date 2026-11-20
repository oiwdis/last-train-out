#!/usr/bin/env bash
# Collect paired startup/matrix evidence without changing the player's saves or cache.
set -eu
app="${1:?usage: benchmark_m1_renderers.sh '/path/to/Last Train Out.app' NEW_OUTPUT_DIRECTORY}"
out="${2:?provide a new output directory}"
if [[ "$(uname -s)-$(uname -m)" != Darwin-arm64 ]]; then
  echo 'Use an Apple Silicon Mac in a native Terminal.' >&2
  exit 2
fi
mkdir "$out"
out="$(cd "$out" && pwd)"
app="$(cd "$app" && pwd)"
selector="$app/Contents/MacOS/choose-renderer"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
packs=("$app"/Contents/Resources/*.pck)
test "${#packs[@]}" -eq 1
pack="$work/game.pck"
cp "${packs[0]}" "$pack"
token="LTO-M1-$(uuidgen)"
{
  sw_vers
  system_profiler SPHardwareDataType | grep -E 'Model (Name|Identifier)|Chip:|Memory:'
  system_profiler SPDisplaysDataType | grep -E 'Chipset Model|Metal Support|Resolution|UI Looks like|Refresh Rate'
  shasum -a 256 "$pack"
  /usr/libexec/PlistBuddy -c 'Print :LTOBuildCommit' "$app/Contents/Info.plist"
} > "$out/hardware.txt"
failed=0
run() {
  local name="$1"
  shift
  code=0
  /usr/bin/time -l "$selector" "$@" > "$out/$name.log" 2>&1 || code=$?
  echo "$name $code" >> "$out/exits.txt"
  if [[ "$code" != 0 || ! -s "$out/$name.json" ]] ||
      grep -Eq 'SCRIPT ERROR:|ERROR:|WARNING:|ObjectDB instances leaked|resources still in use|\[mvk-error\]|VK_ERROR_DEVICE_LOST' "$out/$name.log"; then
    failed=1
  fi
}
select_user() {
  printf '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="%s"\n' "$1" > "$work/override.cfg"
}
for mode in fullscreen windowed; do
  window=(--fullscreen)
  drivers=(metal vulkan)
  if [[ "$mode" == windowed ]]; then window=(--windowed --resolution 1280x720); drivers=(vulkan metal); fi
  for preset in low medium high; do
    for driver in "${drivers[@]}"; do
      select_user "$token-$mode-$preset-$driver"
      for state in cold warm; do
        name="$mode-$preset-$driver-$state"
        run "$name" "$driver" --main-pack "$pack" "${window[@]}" --verbose --audio-driver Dummy \
          res://scenes/main/journey_loading.tscn -- --graphics="$preset" --profile-phases --lto-launch-report="$out/$name.json"
      done
    done
  done
  for driver in "${drivers[@]}"; do
    select_user "$token-$mode-high-$driver"
    name="$mode-$driver-matrix"
    run "$name" "$driver" --main-pack "$pack" "${window[@]}" --verbose --audio-driver Dummy \
      --script res://scripts/diagnostics/integration_benchmark.gd -- \
      --graphics=low --suite=matrix --warmup=120 --samples=600 --out="$out/$name.json"
  done
done
mkdir -p "$out/crashes"
if [[ -d "$HOME/Library/Logs/DiagnosticReports" ]]; then
  find "$HOME/Library/Logs/DiagnosticReports" -type f \
    \( -iname 'Last Train Out*.ips' -o -iname 'LastTrainOut*.ips' -o -iname 'choose-renderer*.ips' \) \
    -newer "$out/hardware.txt" -exec cp -p {} "$out/crashes/" \;
fi
echo "Results: $out"
exit "$failed"
