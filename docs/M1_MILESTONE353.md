# Physical 2020 M1 test

Use the universal development ZIP and SHA-256 in the [3.5.3 report](PERFORMANCE_MILESTONE353.md). Reserve approximately 60–90 minutes for the interactive route, repeated launches and four full matrices. The optional expanded launch stress can take another two hours. Keep the Mac plugged in, disable Low Power Mode and close applications that use the GPU. Record the actual model, RAM, macOS version, display resolution/scaling and window mode. Exclude serial numbers and hardware UUIDs.

1. Run `shasum -a 256 LastTrainOut-macos-universal.zip` and compare the digest. Expand the ZIP once. Move **Last Train Out.app** to Downloads. The app includes Godot. Use macOS **Open Anyway** in Privacy & Security if prompted for the ad-hoc development signature.
2. On a test account, launch normally after restarting the Mac. Time from launching to the first responsive camera turn and movement at Harlow. Record the time to the first visible frame, progress behavior, readiness, and any freeze. Repeat five times. A restart preserves disk shader caches.
3. Use the commands below to record actual frame intervals and renderer information. Run in Terminal using an unused results directory. They leave your existing saves in place. A matrix repositions its diagnostic camera between 12 locations on each preset. It spends 120 frames settling and measures 600 steady frames at each view. The JSON contains the entry and steady intervals, p95, p99, worst frames, CPU monitors and the resolved backend.
4. Play fullscreen at the display's normal resolution. Use Low, Medium and High. Walk into Warehouse B, the cab and the passenger car in both perspectives (V). Drive the route, recover fuel at Ashford, approach and enter dangerous fog, save with a rider and loose cargo, Continue at Blackwater and escape. On a separate save, confirm fog death and restart. Record noticeable hitches, the place and the current preset.
5. Preserve each exit status, partial JSONL, stderr/stdout and corresponding native crash report. A failed process without a JSON file counts as a failure. Save DiagnosticReports listed below. If macOS recorded a GPU restart or a Console message at the same time, include that timestamp. Share only the game reports and redact personal identifiers.

```bash
app="$HOME/Downloads/Last Train Out.app"
exe=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")
bin="$app/Contents/MacOS/$exe"
out="$HOME/Desktop/LastTrainOut-353-$(date +%Y%m%d-%H%M%S)"
mkdir "$out" || exit 1
sw_vers > "$out/os.txt"
sysctl -n machdep.cpu.brand_string hw.memsize > "$out/hardware.txt"
for mode in fullscreen windowed; do
  flags=(--fullscreen)
  if [ "$mode" = windowed ]; then flags=(--windowed --resolution 1280x720); fi
  for preset in low medium high; do
    for n in 1 2 3; do
      name="$out/$mode-$preset-$n"
      /usr/bin/time -l "$bin" --verbose "${flags[@]}" --audio-driver Dummy \
        --script res://scripts/diagnostics/startup_probe.gd -- --graphics="$preset" \
        --profile-phases --out="$name.json" > "$name.log" 2>&1
      echo "$name $?" >> "$out/status.txt"
    done
  done
  for n in 1 2; do
    name="$out/matrix-$mode-$n"
    "$bin" --verbose "${flags[@]}" --audio-driver Dummy \
      --script res://scripts/diagnostics/integration_benchmark.gd -- \
      --graphics=low --suite=matrix --warmup=120 --samples=600 \
      --out="$name.json" > "$name.log" 2>&1
    echo "$name $?" >> "$out/status.txt"
  done
done
"$bin" --verbose --windowed res://scenes/main/self_test.tscn -- \
  --selftest-report="$out/native-audio.json" > "$out/native-audio.log" 2>&1
echo "native-audio $?" >> "$out/status.txt"
find "$HOME/Library/Logs/DiagnosticReports" -type f \
  \( -iname 'Last Train Out*.ips' -o -iname 'LastTrainOut*.ips' \) \
  -newer "$out/os.txt" -exec cp -p {} "$out/" \;
```

The optional stress harness in this checkout makes a byte-identical copy of the exported pack, selects a private user directory beside that copy and verifies the override before rendered launches. Run one series at a time in a fresh directory. The three series together request 20 High, 10 Medium and 10 Low launches in **each** cache condition. Only the writable application cache starts empty on a cold attempt. Driver and OS caches remain shared. The runner retains every attempt and returns failure for device loss, timeout, missing data, renderer fallback or cleanup errors.

```bash
for series in mixed high low-medium; do
  python3 tools/macos/stress_release.py "$app" "$out/stress-$series" --series "$series"
  echo "stress-$series $?" >> "$out/status.txt"
done
```

For release acceptance, require zero device losses and complete rendered, save/restore and shutdown checks. Compare every distribution and retain every frame over 100 ms. The existing targets are responsive cold startup under 30 s, warm under 15 s and entries within 100 ms. Report 3D resolution and displayed resolution independently when scaling is active. Physical-M1 acceptance remains pending until these data and the normal fullscreen playthrough are available.
