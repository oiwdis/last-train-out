# Controlled full-game workload on hosted ARM

All 28 processes used temporary 6038bfcd source trees, High, Forward+/Vulkan, 960×540 and fresh writable caches. The runner reversed case order in round two. OS and driver caches were shared. Each row changes one factor relative to control. The final run added validation. Readiness below is in seconds on the engine clock. A trap or abort stays in the denominator.

| Change | Outcomes in order | Peak RSS MiB, each attempt |
|---|---|---|
| control | 61.826 / 21.294 / 19.534 | 535.6 / 535.3 / 534.5 |
| quarter-pixels | device loss (exit -6) / 21.643 / 19.501 | 525.2 / 531.5 / 537.8 |
| no-views | device loss (exit -6) / 13.390 / 14.430 | 474.7 / 532.5 / 534.9 |
| one-draw | 26.215 / 20.886 / 21.754 | 541.3 / 530.6 / 530.0 |
| no-proxy | 27.664 / 19.286 / 20.510 | 531.7 / 531.3 / 531.5 |
| no-local-shadows | 27.832 / 19.583 / 20.839 | 527.6 / 527.8 / 527.4 |
| no-msaa | 27.679 / 19.588 / 23.060 | 530.9 / 531.5 / 537.9 |
| no-ssao | 24.649 / 19.303 / 21.087 | 526.5 / 525.2 / 525.3 |
| pso-off | 21.152 / 20.802 / device loss (exit -6) | 542.3 / 537.7 / 533.5 |
| Metal API validation | 37.765 | 562.5 |

The “quarter-pixels” experimental label uses 0.35 of the linear resolution during covered draws (12.25% of High pixels), then restores the full gameplay scale. That process still lost the device after the Platform phase. Removing the preparation views also lost the device, after the script had printed readiness. The process never wrote a successful report. A third crash occurred with PSO persistence disabled. All three native reports are included. These reproduce the failure without requiring warmup-camera teardown or a PSO write. None of the three clean control runs establishes that a separate feature removal cures it.

Godot registers textures, buffers and pipelines for disposal on their owning frame, then waits on the frame fence before draining those lists. There is no game-level evidence of an unguarded GPU free. Shader specialization counts and CPU callback boundaries cannot identify the Metal command causing a hardware timeout.

[Raw logs, one-factor diffs and native crash reports](workload-native.zip) · [Full-game experiment source](../../../../tools/macos/renderer_lab.py)
