# Milestone 3.5 rendering performance

Native measurements are pending. No physical 2020 M1 fullscreen result is available. This report will distinguish integration measurements from the earlier source reports.

## Measurement method

`tools/macos/benchmark_integration.py` runs four sequential processes on the same hosted Apple Silicon runner: the integrated twelve-location matrix, integrated fog/animation ablations, and matched Harlow views from the exact PR #4 and PR #5 source heads. Godot 4.5.1 runs at 960×540 windowed with V-sync and the frame cap disabled. There is no fixed timestep, Movie Maker or competing render job during timing. Each view retains its first 60 entry frames, then warms for 120 frames and samples 600 steady frames. Raw frame intervals, mean, p50/p95/p99 and worst time remain in the JSON.

The required matrix covers Harlow platform, both warehouses, locomotive cab, passenger car, a moving curved railway section, Ashford Depot and workshop, Blackwater, near and inside danger fog, and the results screen, in Low/Medium/High. These are deliberately positioned rendering fixtures; they do not prove mission progression. The independently recorded controls-driven journey supplies gameplay evidence. Curve placement waits for physics synchronization before reading car positions and updates the surrounding route visibility. Static fixtures establish real floor/car support before freezing physics, while the measurement camera remains at the previous view. Cab and passenger views use the normal first-person body-visibility rule; the other views retain the full worker. The new-station views face the occupied yards and entrances, including props and signs.

Startup construction and destination-GPU preparation, and each preset's preparation, are reported separately. Export and app launch precede these source-project benchmarks, so the runs are cache-conditioned, not cold-start measurements. Pipeline counter deltas identify first-use work during each sampled view; zero steady compilation does not mean preparation was free.

CPU process/physics counters are periodically refreshed engine snapshots and may retain earlier work. Viewport CPU time measures render submission, not total frame CPU cost. Frame intervals are the end-to-end pacing measure. A zero GPU-time counter means unavailable. Texture/static memory is not total process memory; the wrapper separately samples resident memory every 0.5 seconds and retains those samples and the observed peak.

The five source comparison views share camera coordinates, field of view, resolution and sampling. Each source retains its actual art, graphics presets, renderer and worker settings. PR #4 and the integration use Vulkan/MoltenVK; PR #5 retains its original backend. This compares complete builds, not an isolated optimization or equal visual workload.

Ablations repeat the same Harlow/fog views with idle worker animation disabled, then with the danger sheets and observer haze disabled. They restore each feature before the next case. Animation removal can also permit shadow-map reuse, so its timing difference is not isolated skeleton CPU cost. Small one-run differences are subject to host and ordering variability. None of these diagnostic omissions changes shipped presets or fog simulation.

## Target hardware

The physical target is a 2020 M1 Mac in fullscreen, with a Low goal of 30+ FPS. Hosted Apple Silicon and software-rendered Linux do not establish this target. Follow the [repeatable physical-M1 procedure](M1_MILESTONE35.md), retain p99 and worst entry frames alongside averages, and record actual display size, internal render scale, power and thermal conditions.
