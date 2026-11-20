# Supplemental Linux CPU update probe

Godot 4.5.1 headless on Intel Xeon Platinum 8573C, one sequential cohort with 300 warm ticks then 1,200 measured ticks per case. Godot uses fixed 60 Hz simulation steps without a real-time frame cap. The samples are actual wall milliseconds between complete physics ticks, with gameplay and animation updates active; they are **not real-time FPS, GPU time or physical-M1 evidence**. No rendered-view claim is made.

Sources: PR #4 `a8f58ec57c218c3944d038a9d1640e78597042be`, PR #5 `9c4f0de49e104ca95ccb57c88cf535ab96202dac`, integration `45c3b338a694f587b5290af0e8ce19208d0a702e`. Each retains its original defaults; the source-art train cruises at 12 m/s, the survival/integration trains at 8 m/s. The player stays on the station platform. The departing case starts the real train, without route-position edits; it ends before the source-art track ends. These are whole-build comparisons, not isolated fog or animation costs.

JSON retains all 1,200 raw intervals, means, p99 and worst values. This short supplemental cohort includes scheduling noise and is not a hardware acceptance run. Copy `probe.gd.txt` to `/tmp/lto-m35-cpu-probe.gd`, then run Godot with `--headless --path <checkout> --fixed-fps 60 --script /tmp/lto-m35-cpu-probe.gd -- --out=<report.json>` against each source in sequence. Do not run competing benchmarks on that machine.
