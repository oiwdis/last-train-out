# Milestone 3.5.2: physical 2020 M1 acceptance remains pending

No physical M1 is connected here. Hosted Apple Paravirtual results do not satisfy
this gate. Use the final development ZIP and SHA linked in
[the performance report](PERFORMANCE_MILESTONE352.md). The app includes Godot;
the development build is ad-hoc signed and is not claimed notarized. The current
artifact reproduced Vulkan device loss in the fresh ARM windowed self-test, so
it is an investigation build, not an accepted release. Preserve any failure;
do not rerun until a pass and omit the earlier attempt.

1. Record the build SHA, Mac model/chip, RAM, macOS version (`sw_vers`), display
   resolution/scaling, power settings and external displays. Omit serial numbers
   and hardware UUIDs. Keep power/display settings and background apps consistent.
2. Time a normal launch from process start to responsive movement, after a Mac
   restart and on five subsequent launches. Record any frozen window or stuck
   progress display. Restarting macOS does not clear persistent shader caches.
3. Run the traces below for all three presets, retaining every failed attempt.
   JSON mission-ready time excludes the diagnostic's settling/cleanup time;
   `/usr/bin/time` includes both. This game has no startup menu.
4. Run two fullscreen matrices and two windowed matrices. Each includes all
   twelve locations at Low, Medium and High, separate entry/steady samples,
   mean FPS, median/p95/p99/worst milliseconds and >33.3/50/100 ms counts.
5. Play the complete route normally: Warehouse B, cab, passenger car, Ashford,
   Blackwater, approaching/dangerous fog, Save/Continue with rider and cargo,
   and mission completion. Use V for both perspectives. Test one failure/restart
   separately. F1/backtick shows the existing live FPS diagnostic; avoid debug
   action buttons. Record each hitch, preset, place and approximate time.

```sh
LTO_APP="$HOME/Downloads/Last Train Out.app"
LTO_EXE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$LTO_APP/Contents/Info.plist")
LTO_BIN="$LTO_APP/Contents/MacOS/$LTO_EXE"
LTO_RESULTS="$HOME/Desktop/LastTrainOut-M352-M1"
mkdir -p "$LTO_RESULTS"
sw_vers > "$LTO_RESULTS/macos.txt"
for preset in low medium high; do
  for run in 1 2 3; do
    /usr/bin/time -l "$LTO_BIN" --verbose --fullscreen --audio-driver Dummy \
      --script res://scripts/diagnostics/startup_probe.gd -- \
      --graphics="$preset" --profile-phases \
      --out="$LTO_RESULTS/startup-$preset-$run.json" \
      > "$LTO_RESULTS/startup-$preset-$run.log" 2>&1
    printf '%s %s exit=%s\n' "$preset" "$run" "$?" >> "$LTO_RESULTS/status.txt"
  done
done
for run in 1 2; do
  "$LTO_BIN" --verbose --fullscreen --audio-driver Dummy \
    --script res://scripts/diagnostics/integration_benchmark.gd -- \
    --suite=matrix --samples=600 --warmup=120 --graphics=low \
    --out="$LTO_RESULTS/fullscreen-$run.json" > "$LTO_RESULTS/fullscreen-$run.log" 2>&1
  printf 'fullscreen %s exit=%s\n' "$run" "$?" >> "$LTO_RESULTS/status.txt"
  "$LTO_BIN" --verbose --windowed --resolution 1280x720 --audio-driver Dummy \
    --script res://scripts/diagnostics/integration_benchmark.gd -- \
    --suite=matrix --samples=600 --warmup=120 --graphics=low \
    --out="$LTO_RESULTS/windowed-$run.json" > "$LTO_RESULTS/windowed-$run.log" 2>&1
  printf 'windowed %s exit=%s\n' "$run" "$?" >> "$LTO_RESULTS/status.txt"
done
```

To reproduce the specific failed CI gate once, use the same exported windowed
self-test and keep its report, log and any macOS crash report. This fixture uses
scripted controls and snapshots; it is separate from the uninterrupted owner-play
acceptance above. Native audio is left enabled, matching that failed self-test.

```sh
"$LTO_BIN" --verbose res://scenes/main/self_test.tscn -- \
  --selftest-report="$LTO_RESULTS/windowed-selftest.json" \
  --selftest-screenshot="$LTO_RESULTS/windowed-selftest.png" \
  > "$LTO_RESULTS/windowed-selftest.log" 2>&1
printf 'windowed selftest exit=%s\n' "$?" >> "$LTO_RESULTS/status.txt"
```

Do not add `--fixed-fps` or Movie Maker flags to timing runs. Confirm actual
resolution/window mode in each report. The fixture repositions cameras and
freezes most simulation; it does not replace the interactive route. A zero GPU
timer is unavailable data, not zero GPU cost. Keep partial `.jsonl` files,
complete logs, macOS crash reports and unfavorable samples.

For the optional 10-cold/10-warm stability series, use
`python3 tools/macos/stress_release.py "/path/Last Train Out.app" "/new/results/directory"`
from this repository on a test account. It preserves the app's signed bytes,
uses private `LTO-352-stress-*` save/cache directories, retains every attempt and
stops within 40 minutes. This series is **960×540 windowed**, not fullscreen
acceptance. “Cold” means new writable application caches; baked shaders and
OS/driver caches remain. The normal save is not deleted or moved.

Acceptance goals are cold startup below 30 s, warm below 15 s, a responsive
loading window, no gameplay-entry frame above 100 ms, and no device loss or
resource-lifetime errors. Any unmet goal requires an explicit owner decision;
neither a successful retry nor a good mean FPS erases a failed attempt. Return
the raw evidence plus normal-play observations before recommending merge.
