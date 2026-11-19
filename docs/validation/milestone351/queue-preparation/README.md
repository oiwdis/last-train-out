# Queue-aware preparation probe — 038033e

Hosted Apple Silicon / Apple Paravirtual device, Godot 4.5.1 Vulkan, 960×540 windowed. Not physical M1 evidence.

- `quick.zip`: run [44573438078](https://github.com/oiwdis/last-train-out/actions/runs/44573438078), all 12 locations × 3 presets, only 24 entry/steady samples and 8 settling frames. Diagnostic, not final pacing acceptance. Exit 0, no engine diagnostics, peak RSS 534,347,776 bytes. High Harlow entry worst 86.753 ms versus 2,773.443 ms in the previous long warm baseline. Medium Harlow still 334.389 ms; High Warehouse A 149.937 ms; Medium near-fog 179.644 ms. Different hosted runs/sample lengths: provisional, not a matched comparison.
- `startup.zip`: run [44573438825](https://github.com/oiwdis/last-train-out/actions/runs/44573438825), readiness 73.558 / 21.602 / 19.805 seconds. All three clean. First launch remains much slower than the target. CPU scene activation 1.826 / 1.687 / 1.342 seconds. No claim of 15-second physical M1 readiness.
- `stress.zip`: same run, all four lifecycle tests passed with Vulkan rendering, including all danger states/presets, repeated scenes, cancellation and rider/cargo Continue during preparation. Fixed FPS is used for functional determinism, not performance measurement. No ObjectDB/resource-in-use diagnostics.

Changes under test: CPU mesh sources, scene-owned preparation, queued draw rotation, 128 MiB PSO serialization threshold. HUD redraw fix is **not** included in these measurements. No fatal device loss here; this does not establish that the historical GPU timeout is fixed.
