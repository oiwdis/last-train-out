# Reproduce the physical 2020 M1 fullscreen benchmark

The development computer uses software Vulkan; hosted macOS CI uses a virtual
Apple GPU in a window. Neither result establishes the 30 FPS Low target on a
physical 2020 M1. A physical-device result is still required.

Use the final PR #4 universal ZIP, unzip it, and launch the app once using the
README's instructions for an ad-hoc-signed development build. The build is not
notarized. Record the ZIP SHA-256, commit, Mac model/year, M1 chip, RAM, macOS,
internal/external display and native pixel resolution, display scaling, power
mode and whether the Mac is connected to power. Close competing applications;
let the machine reach a stable temperature. Do not run tests or recordings at
the same time as these measurements.
Record cold-launch time until the player can move, as well as the first preset
change. The benchmark logs include elapsed stage times and pipeline-compilation
counters; retain them when reporting an initial stall.

The diagnostic is included in the app; no Godot editor/source checkout is needed.
Set the app path below to the actual unzipped app. From Terminal:

```sh
LTO_APP="$HOME/Downloads/Last Train Out.app"
LTO_REPORTS="$HOME/Desktop/last-train-out-m1"
mkdir -p "$LTO_REPORTS"
sw_vers > "$LTO_REPORTS/macos.txt"
system_profiler SPHardwareDataType SPDisplaysDataType > "$LTO_REPORTS/hardware.txt"
shasum -a 256 "$HOME/Downloads/LastTrainOut-macos-universal.zip"
"$LTO_APP/Contents/MacOS/Last Train Out" --fullscreen --audio-driver Dummy \
  --script res://scripts/diagnostics/render_benchmark.gd -- \
  --suite=presets --warmup=120 --samples=600 --out="$LTO_REPORTS/presets-1.json"
"$LTO_APP/Contents/MacOS/Last Train Out" --fullscreen --audio-driver Dummy \
  --script res://scripts/diagnostics/render_benchmark.gd -- \
  --suite=route --warmup=120 --samples=600 --out="$LTO_REPORTS/entry-pan-1.json"
```

Repeat three times, changing the output suffix to `-2` and `-3`. Keep every run.
The reports include actual viewport resolution/window mode, GPU, renderer,
render scale, median/p95/worst frame interval, render CPU/GPU time, draw calls,
primitives and texture memory. VSync is disabled; neither fixed FPS nor Movie
Maker is used. Presets are selected without persisting them. The route is a
repeatable camera pan through Warehouse B's entrance; its simulation is a render
stress comparison, not a full interactive traversal test. A shorter first run
can expose initial shader compilation; do not discard a spike without reporting it.

Compare identical app revisions and output resolutions if repeating an older
build. A 960×540 CI result cannot be compared directly to fullscreen Retina
pixels. The Low 720p and Medium 1080p internal rendering caps should be visible
in `render_scale`; UI remains at output resolution. Report Low mean FPS and p95
frame time, then Medium/High, and retain raw reports. Do not label the Low target
achieved unless this physical machine measures at least 30 FPS in both views
without severe entry/pan stalls.

Finally play for ten minutes in fullscreen: walk/sprint/jump, V switching,
Warehouse A and B, all caches, coal pickup/drop/storage, ladders, moving-car
traversal and train controls. Note sustained frame pacing, thermal changes and
any visible texture/animation issue. Save these observations alongside the JSON.
