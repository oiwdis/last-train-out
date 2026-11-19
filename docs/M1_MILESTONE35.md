# Physical 2020 M1 fullscreen acceptance

No physical 2020 M1 result is available from this task. Hosted Apple Silicon has a different GPU, display and thermal environment. The Low 30+ FPS target remains a hardware acceptance goal.

Use the integration universal app linked from [the review](MILESTONE35_REVIEW.md). Unzip once and open it normally first. It includes its own Godot 4.5.1 runtime. The development build is ad-hoc signed, not notarized; follow the existing [macOS launch instructions](../README.md#play-on-macos).

Record Mac model, memory, chip, macOS version, display resolution/scaling, external displays, power source and Low Power Mode. For comparable runs, use AC power with Low Power Mode off, close other demanding apps, and allow temperature to settle. The user’s target is **fullscreen on a 2020 M1**; do not substitute a small window for that acceptance run.

In Terminal, adjust the app path and run three separate processes:

```bash
LTO_APP="$HOME/Downloads/Last Train Out.app"
LTO_EXE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$LTO_APP/Contents/Info.plist")
LTO_RESULTS="$HOME/Desktop/LastTrainOut-M35-M1"
mkdir -p "$LTO_RESULTS"
sw_vers > "$LTO_RESULTS/macos.txt"
system_profiler SPHardwareDataType SPDisplaysDataType > "$LTO_RESULTS/hardware.txt"
for run in 1 2 3; do
  /usr/bin/time -l "$LTO_APP/Contents/MacOS/$LTO_EXE" \
    --fullscreen --audio-driver Dummy \
    --script res://scripts/diagnostics/integration_benchmark.gd -- \
    --suite=matrix --samples=600 --warmup=120 --graphics=low \
    --out="$LTO_RESULTS/fullscreen-$run.json" \
    > "$LTO_RESULTS/fullscreen-$run.log" 2> "$LTO_RESULTS/fullscreen-$run-memory.log"
done
```

Do **not** add `--fixed-fps`, `--write-movie` or a frame cap: those invalidate real-time measurements. The benchmark disables V-sync, reports the actual window mode and size, and visits all twelve required locations in Low/Medium/High. These are deliberate rendering fixtures, separate from the continuous gameplay recording. The curved-track case includes moving train simulation.

Each case records initial entry frames separately from steady frames. Keep both. The JSON includes mean FPS, p50/p95/p99/worst frame times, raw intervals, draw calls, CPU process/physics and viewport render times, GPU render time when supplied by the driver, texture memory and static memory. Zero GPU timing means unavailable, not zero cost. The `time -l` log supplies peak process resident memory; Godot static memory alone is not total app memory. Startup and each preset’s preparation time/pipeline counts are separate from steady measurements.

Compare every Low location against 33.3 ms/frame, including p99 and isolated worst frames. A good average does not excuse repeated entry freezes. Record whether Medium feels usable during real play. High has no claimed physical-M1 target. Low and Medium cap internal 3D height; check each row’s `render_scale` alongside the fullscreen window size. Keep default framebuffer resolution rather than forcing a small size.

Repeat with `--suite=ablations` for fog and animation overhead. It compares the same views with idle rigs frozen or danger visuals disabled; these diagnostic controls do not change shipped gameplay. Report measurement variability and the exact preset/location. For a matched hosted-run comparison, make a separate windowed run using `--resolution 960x540` in place of `--fullscreen`, and label it windowed.

Finally play the actual mission: explore Harlow, collect/store coal, use the regulator, switch V in the moving cab, reach Ashford, collect workshop supplies under approaching fog, return/refuel, reach Blackwater, save/continue, and finish. Check the first warehouse entry and first dense-fog encounter for stutters. Benchmark fixtures cannot establish route, collision or save usability by themselves. Keep the JSON/logs and report any stall with station, graphics preset and approximate route distance.
