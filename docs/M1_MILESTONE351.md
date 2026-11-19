# Physical 2020 M1 validation — pending

No physical 2020 M1 is connected to this workspace. Hosted Apple Paravirtual
results are separate evidence. They do not establish M1 fullscreen frame pacing
or the 15-second startup target. The owner's previous configuration was a 2020
M1 in fullscreen; macOS version, RAM and display resolution still need recording.

Use the final ZIP linked from [PR #6](https://github.com/oiwdis/last-train-out/pull/6).
Unzip `LastTrainOut-macos-universal.zip` to obtain `Last Train Out.app`. Godot is
included. Follow the README's macOS opening instructions for an ad-hoc-signed
development build; it is not claimed notarized.

Record `sw_vers`, chip, RAM, display resolution and scaling, power connection,
window mode, build commit/ZIP SHA, and whether caches were already populated.
Avoid recording serial numbers or hardware UUIDs. Keep other GPU-heavy apps
closed and use the same display and power settings for every comparison.

## Startup and cache behavior

First measure a normal launch with a stopwatch, from starting the application
to responsive movement. Repeat five times, retaining all results. Also test
after a Mac restart. A restart is a cold filesystem/OS condition; it does not
automatically clear Godot's persistent shader/pipeline caches.

For a repeatable trace, adjust the application location below:

```sh
app="$HOME/Downloads/Last Train Out.app/Contents/MacOS/Last Train Out"
out="$HOME/Desktop/LastTrainOut-M1-351"
mkdir -p "$out"
for run in 1 2 3 4 5; do
  /usr/bin/time -l "$app" --verbose --fullscreen --audio-driver Dummy \
    --script res://scripts/diagnostics/startup_probe.gd -- \
    --graphics=low --profile-phases --out="$out/startup-$run.json" \
    > "$out/startup-$run.log" 2>&1
done
```

The JSON reports engine-tick phases, mission readiness and the actual user-data
directory. The external time includes settling and teardown; do not label that
whole duration mission-ready time. Keep the normal-launch stopwatch result too.

To test a genuinely empty application shader cache, quit the game, back up and
temporarily move only `shader_cache` and `vulkan` from the reported user-data
directory, then run once and repeat warm. Keep saves and settings intact. Label
this condition explicitly; do not silently mix it with warm results. Driver/OS
caches can still differ. Restore the backed-up cache directories only while the
application is closed. After each successful exit, verify that the pipeline
cache exists and that a subsequent warm launch reuses it. Abrupt termination can
lose the latest pipeline-cache additions because serialization is deferred.

## All locations and presets

```sh
"$app" --verbose --fullscreen --audio-driver Dummy \
  --script res://scripts/diagnostics/integration_benchmark.gd -- \
  --suite=matrix --graphics=low --samples=1800 --warmup=120 \
  --out="$out/fullscreen-matrix.json" > "$out/fullscreen-matrix.log" 2>&1

"$app" --verbose --resolution 1280x720 --audio-driver Dummy \
  --script res://scripts/diagnostics/integration_benchmark.gd -- \
  --suite=matrix --graphics=low --samples=1800 --warmup=120 \
  --out="$out/windowed-matrix.json" > "$out/windowed-matrix.log" 2>&1
```

Repeat both commands at least twice with warm caches. Confirm the reported
resolution and window mode. Each run visits all twelve locations at Low,
Medium and High. Entry and steady frames are separate, with raw frame times,
mean/median/p95/p99/worst, counts above 33.3/50/100 ms, memory monitors, draw
calls, triangles and available renderer timing. GPU timing of zero means
unavailable, not zero GPU cost. Keep `.jsonl` partial results if a run fails.

These are rendering fixtures, including deliberate repositioning and frozen
survival outside the moving-train case. They are not a continuous gameplay
journey or a measurement of the full active simulation. Do not add `--fixed-fps`,
`--write-movie` or a frame cap to these timing commands. Offline recording frame
rate is not real-time FPS.

## Interactive checks

In normal play, test fullscreen Low, Medium and High, then windowed mode. Walk
into Warehouse B, the locomotive cab and passenger car. Use V to switch first-
and third-person views, including while carrying cargo. Depart, cross a curved
section, approach the fog and remain briefly in dangerous fog. Exercise all
three presets while standing safely, then Save/Continue with rider and cargo
on the train. Complete Harlow → Ashford → Blackwater → final escape, and test
one mission failure separately. Note every visible hitch, its location and the
wall-clock time so it can be related to logs.

For every failure, retain the complete log, partial JSON/JSONL and any macOS
crash report. A successful retry does not erase the failed attempt. Report
ObjectDB/resource-in-use warnings even when the process exits zero. Return the
raw files with hardware/display details and the normal-launch timings. Mark
the M1 gate complete only after these measurements actually exist.
