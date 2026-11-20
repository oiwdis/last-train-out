# Three native preset/scene/shutdown stress processes

Run [44578287174](https://github.com/oiwdis/last-train-out/actions/runs/44578287174), source `7a53907840eae936f98c4a5d10344581cffe5f92`; later `31a0e4a` changes CI artifact reuse only. `raw.zip` retains the entire artifact, including all 216 entry/steady rows, logs, RSS samples, phase events and process statuses.

Godot 4.5.1, macOS 26.7.2 ARM64, 3 CPUs, Apple Paravirtual GPU, Vulkan, 960×540 windowed. Each process visits all 12 locations on Low → Medium → High; 24 samples per entry/steady window and 8 settling frames. These short runs stress lifetime and transitions; the long paired cohort is the pacing comparison.

| Attempt | Wall time through shutdown | Peak RSS MiB | High Harlow entry worst | High near-fog steady worst | Worst anywhere |
|---|---:|---:|---:|---:|---|
| 1 | 179.28 s | 537.05 | 93.952 ms | 22.076 ms | 347.615 ms, Medium cab entry |
| 2 | 76.48 s | 521.56 | 81.133 ms | 14.605 ms | 98.914 ms, Medium near-fog entry |
| 3 | 74.00 s | 555.89 | 120.907 ms | 15.176 ms | 120.907 ms, High Harlow entry |

All three processes exited zero, produced complete reports, and emitted no engine error, ObjectDB or resource-in-use warning. No fatal device loss occurred; three clean runs do **not** close the historical GPU timeout. A verbose orphan `servers` StringName remains in all three logs. MoltenVK reports 19–20 MB allocated when destroying the physical device; that driver-level message is retained and does not identify an application-owned resource. GPU-total memory is unavailable.

The first cold-cache process still has entry outliers: Medium Harlow 269.006 ms, Warehouse A 106.562 ms, cab 347.615 ms, Ashford workshop 141.067 ms; High Warehouse A 115.510 ms and near-fog 108.665 ms. The third has High Harlow 120.907 ms and Warehouse A 104.509 ms. These remain in the data. The cab outlier spent 341.774 ms in the render bracket, 0.656 ms in process callbacks and 0.394 ms in physics, with zero pipeline-counter delta. High Warehouse A added seven specialization requests in its entry window. The all-location 100 ms target is therefore **not met**.
