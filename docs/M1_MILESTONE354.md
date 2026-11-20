# Physical 2020 M1 renderer test

Use a native Terminal on the 2020 M1, connect power and quit demanding applications. Record the macOS version, display mode, refresh rate, desktop scaling, external displays and Low Power Mode. The hosted Apple Paravirtual GPU has a different device and driver. The downloaded app includes the engine. Python and Godot are optional for play.

Download the development ZIP linked in the [release report](PERFORMANCE_MILESTONE354.md). Compare the complete result from `shasum -a 256 LastTrainOut-macos-universal.zip` with its receipt before unzipping. The Finder application starts the default Vulkan player. The commands below select one backend for a single launch.

## Choose and identify the renderer

Unzip the development build and follow the repository’s macOS first-open instructions. In Terminal, set the app path and choose a driver for one launch. Quit before running the second command. Metal requires Apple Silicon. The primary executable remains universal. An ordinary double-click uses the project default, Forward+ on Vulkan.

```bash
app="/Applications/Last Train Out.app"
out="$HOME/Desktop/LastTrainOut-M1-$(date +%Y%m%d-%H%M%S)"
mkdir "$out"
"$app/Contents/MacOS/choose-renderer" --device-profile > "$out/metal-device-profile.json"
"$app/Contents/MacOS/choose-renderer" metal --fullscreen --verbose > "$out/metal-play.log" 2>&1
"$app/Contents/MacOS/choose-renderer" vulkan --fullscreen --verbose > "$out/vulkan-play.log" 2>&1
```

Look for both the engine banner and `[renderer] active forward_plus/metal` or `[renderer] active forward_plus/vulkan`. Keep the shader-cache selection line. On an incompatible source-cache profile Metal compiles locally. An unavailable requested backend ends the explicit launch. The chooser never relaunches an interrupted mission. Preserve the original log and macOS crash report before starting another game.

On a compatible M1 running macOS 26 or later, the Metal selector logs the number of read-only library groups. Keep the device-profile JSON and the group count with the ZIP hash so the result identifies the GPU family, language version and argument-buffer tier. With `--verbose` the engine logs `Loaded bundled Metal library group` when it uses one. An older OS or a different shader profile can take the source path. For a paired source-only diagnostic, place `LTO_METAL_LIBRARIES=0` before the same Metal selector command and record that override alongside the results.

## Collect startup and frame distributions

From this revision of the repository, run the owner benchmark and keep the output directory. It copies the shipped pack into a temporary test directory and selects private writable user data. Existing saves and shader caches are preserved. Each cold process gets an empty application cache. The warm process reuses it. The harness samples the process RSS once per second. If a benchmark stays alive for 12 seconds after writing its report, the harness takes a macOS thread sample. It marks a launch still running after five minutes, or a full matrix after 30 minutes, as a timeout and stops that benchmark process. Keep the original timeout, observer and RSS files. OS and driver caches may survive a reboot. Record whether this was the first launch after boot and the first install of this build.

```bash
tools/macos/benchmark_m1_renderers.sh "$app" "$out/measurements"
```

The script runs both renderers, fullscreen and 1280×720 windowed, through Low, Medium and High. Startup JSON includes the normal loading scene, actual first playable time and subsequent 30 frames. The uncapped matrix records separate entry and steady intervals for all 12 locations, including Warehouse B, both train interiors, fog and mission results. Compare like-for-like resolution and preset. Record the worst frame, p95/p99, counts above 33.3/50/100 ms, and process RSS. A nonzero process exit, missing JSON, wrong backend, device loss or rendering warning is a failed attempt. Keep its log even if a retry succeeds. An offline movie’s 12 fps is its encoding rate.

If Xcode is installed, use Instruments → Metal System Trace for an additional launch on a separate recording pass. Select the shipped `LastTrainOutMetal` process for native Metal or `Last Train Out` for Vulkan. Save the trace with the preset, cache condition and display mode. Pipeline creation, command-buffer execution and texture transfers on a physical GPU can help explain long intervals in the unprofiled JSON.

For a Warehouse A hitch, the repository also includes a targeted 960×540 diagnostic. It samples the first Warehouse A entry at each preset and the steady Low locomotive cab, then repeats the full matrix without an observer. The resulting native stacks, phase markers and Metal pipeline signposts help identify where the process waited. Use its output alongside the fullscreen measurements.

```bash
python3 tools/macos/profile_metal_entry.py "$app" "$out/warehouse-profile"
```

## Play and inspect

On each renderer use Tab → Graphics or F2 to apply Low, Medium and High fullscreen. Use V to switch first and third person. Check the worker’s skin, coat, hair, shadows and hands during a carry. Walk into Warehouse B with the fog visible, board the cab, look through its windows, inspect the gauges and move into the passenger car. Ride the curve, reach Ashford, refuel and watch fog progress through all four states. Check nearby brickwork, rails, foliage and the fog boundary for shimmer, missing detail or flicker while moving.

Save at Blackwater with the rider aboard and cargo assigned, use Continue and check the platform, car-local player position, cargo, fuel and fog state. Complete the escape and retain the results screen. Use a separate macOS test account for a fresh manual journey if your ordinary save matters. Collect microphone-free screen recordings or screenshots if a visual issue occurs. Note the preset, camera, location and elapsed time for each fault.

A release recommendation needs the real display resolution, framerate distributions, cold and warm launches, warning/crash counts and the manual observations above. The targets are cold below 30 s, warm below 15 s, responsive loading, and entry under 100 ms. Send the measurements directory and relevant files from `~/Library/Logs/DiagnosticReports`, including `LastTrainOutMetal*.ips` and `Last Train Out*.ips`.
