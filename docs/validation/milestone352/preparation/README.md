# Preparation coverage and rejected isolation experiment

Commit `1cbd924` added exact Warehouse A interior, cab and passenger views to
preparation, and experimentally isolated the fog proxy on a temporary render
layer. No geometry, texture, fog difficulty or gameplay camera was changed.

The isolation experiment is **rejected**. Native Vulkan device loss reproduced
in five of six consecutive attempts on two independent runners:

| Run | Attempt | Result | Process lifetime | Peak RSS |
|---|---:|---|---:|---:|
| [44602970934](https://github.com/oiwdis/last-train-out/actions/runs/44602970934) | 1 | Device lost, no readiness | 90.148 s | 503.66 MiB |
| same | 2 | Device lost, no readiness | 40.127 s | 433.66 MiB |
| same | 3 | Ready at 33.132 s; clean exit | 35.597 s | 496.16 MiB |
| [44602598542](https://github.com/oiwdis/last-train-out/actions/runs/44602598542) | 1 | Device lost, no readiness | 85.063 s | 470.58 MiB |
| same | 2 | Device lost, no readiness | 36.442 s | 434.22 MiB |
| same | 3 | Device lost, no readiness | 24.647 s | 490.70 MiB |

Both complete raw artifacts are retained unchanged. These were the predefined
three-launch diagnostic series, not retries chosen until success. The workflow
failed and correctly skipped release export. The successful third attempt is
not evidence of a fix. Both runs used source projects, Godot 4.5.1, 960×540 Low,
Vulkan on the hosted Apple Paravirtual device; imported textures were reused.

Every failure follows `warmup_fog_material`, before `warmup_view_Platform`
finishes. The fog-only pass had created one draw pipeline; the successful full
platform pass jumped to 46 draw pipelines / 50 specializations and took 11.914 s.
The original pass also prepared surrounding geometry, spreading that work
over the earlier pass. The new logs contain Metal command-buffer timeout,
`VK_TIMEOUT`, failed fence wait, `Vulkan device was lost`, and a crash backtrace
through `command_queue_execute_and_present`. This associates the experiment
with the preparation burst; it does not identify the exact failing GPU command.
`VK_EXT_device_fault` is unavailable and the engine's breadcrumbs are empty.
RSS and texture memory alone do not establish GPU memory pressure or exclude it.

Restoring the original initial view is a rollback of an unaccepted experiment,
not a claim that the historical driver failure is fixed. The additional interior
views remain for native measurement. The new experiment-specific test now
checks the restored view/material/camera contract; none of the original 300 tests
was removed or weakened. The earlier 301-test Linux logs remain as experiment
evidence, not validation of a final candidate.
