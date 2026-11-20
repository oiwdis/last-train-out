# Matched hosted comparison

Baseline `7df2f5abee54b8adcf27b8668263fba231a79033`; candidate `5534cf82c2e6e494cbf54add169e6ab4e8101b46`.

Godot 4.5.1, 960×540 windowed, Vulkan, V-sync/frame cap off. Two sequential matrices per revision, alternating order. 60 entry frames and 600 steady frames per view per run, with 120 settling frames. Separate fresh application caches, warm filesystem, shared OS/driver cache state uncontrolled. No profiler, screenshots or Movie Maker. All samples, including failures and outliers, are retained. Pooled percentiles are recomputed from raw frames, never averaged from per-run percentiles. GPU timing zero means unavailable.

## Low — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 9.03 → 7.44 | 8.17 → 6.85 | 13.87 → 11.12 | 19.93 → 14.90 | 52.35 → 51.40 | 4/1/0 → 2/1/0 |
| Warehouse A | 9.70 → 8.24 | 8.96 → 7.76 | 13.96 → 10.57 | 20.60 → 13.24 | 38.51 → 18.36 | 3/0/0 → 0/0/0 |
| Warehouse B | 9.27 → 7.85 | 8.50 → 7.38 | 13.85 → 10.46 | 23.38 → 13.65 | 38.49 → 40.63 | 1/0/0 → 2/0/0 |
| Locomotive cab | 11.20 → 9.07 | 9.94 → 8.92 | 17.19 → 10.46 | 26.97 → 11.99 | 80.29 → 17.65 | 5/2/0 → 0/0/0 |
| Passenger car | 10.75 → 9.39 | 9.85 → 9.07 | 15.55 → 11.33 | 22.42 → 13.65 | 47.17 → 17.04 | 3/0/0 → 0/0/0 |
| Curved railway | 6.99 → 6.74 | 6.13 → 6.41 | 10.65 → 9.28 | 15.34 → 12.44 | 22.50 → 26.15 | 0/0/0 → 0/0/0 |
| Ashford Depot | 5.59 → 5.36 | 5.18 → 4.91 | 7.97 → 7.13 | 10.67 → 9.25 | 15.24 → 14.66 | 0/0/0 → 0/0/0 |
| Ashford workshop | 6.54 → 6.15 | 5.96 → 5.07 | 10.23 → 9.14 | 14.56 → 12.74 | 26.18 → 32.94 | 0/0/0 → 0/0/0 |
| Blackwater Crossing | 8.44 → 5.85 | 7.50 → 5.81 | 14.42 → 7.59 | 28.95 → 9.40 | 76.18 → 16.26 | 8/2/0 → 0/0/0 |
| Near advancing fog | 8.04 → 6.64 | 7.41 → 6.05 | 11.81 → 9.31 | 15.70 → 11.25 | 55.91 → 21.35 | 1/1/0 → 0/0/0 |
| Inside dangerous fog | 7.56 → 6.26 | 7.13 → 5.81 | 11.11 → 8.12 | 15.52 → 11.75 | 24.38 → 18.99 | 0/0/0 → 0/0/0 |
| Mission completion | 5.61 → 6.64 | 5.17 → 5.72 | 8.20 → 11.07 | 11.74 → 22.42 | 16.24 → 40.84 | 0/0/0 → 3/0/0 |

## Low — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 11.33 → 9.91 | 0 → 0 |
| Warehouse A | 53.60 → 40.31 | 0 → 0 |
| Warehouse B | 58.51 → 12.31 | 0 → 0 |
| Locomotive cab | 42.35 → 39.53 | 0 → 0 |
| Passenger car | 103.22 → 45.42 | 1 → 0 |
| Curved railway | 38.71 → 27.78 | 0 → 0 |
| Ashford Depot | 11.42 → 21.35 | 0 → 0 |
| Ashford workshop | 15.90 → 8.75 | 0 → 0 |
| Blackwater Crossing | 31.70 → 17.07 | 0 → 0 |
| Near advancing fog | 39.21 → 44.49 | 0 → 0 |
| Inside dangerous fog | 17.42 → 9.18 | 0 → 0 |
| Mission completion | 37.89 → 31.32 | 0 → 0 |

## Medium — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 10.86 → 9.63 | 10.62 → 9.24 | 14.29 → 12.70 | 20.73 → 16.05 | 33.84 → 27.02 | 1/0/0 → 0/0/0 |
| Warehouse A | 11.41 → 10.68 | 10.47 → 10.62 | 16.34 → 13.96 | 19.99 → 17.68 | 29.02 → 26.14 | 0/0/0 → 0/0/0 |
| Warehouse B | 11.24 → 9.74 | 10.50 → 9.23 | 15.15 → 12.62 | 19.79 → 14.73 | 36.06 → 19.10 | 1/0/0 → 0/0/0 |
| Locomotive cab | 11.45 → 10.86 | 10.20 → 10.18 | 16.57 → 14.39 | 22.40 → 22.48 | 33.55 → 72.87 | 1/0/0 → 3/1/0 |
| Passenger car | 12.45 → 10.99 | 11.65 → 10.94 | 17.71 → 13.22 | 21.39 → 15.04 | 34.20 → 23.38 | 1/0/0 → 0/0/0 |
| Curved railway | 8.85 → 7.88 | 8.50 → 7.67 | 10.96 → 9.48 | 16.21 → 12.25 | 26.58 → 18.96 | 0/0/0 → 0/0/0 |
| Ashford Depot | 7.32 → 6.76 | 6.51 → 6.35 | 11.17 → 9.48 | 16.99 → 11.23 | 24.17 → 20.36 | 0/0/0 → 0/0/0 |
| Ashford workshop | 8.31 → 7.66 | 7.82 → 7.37 | 11.09 → 9.62 | 15.50 → 12.17 | 31.66 → 18.34 | 0/0/0 → 0/0/0 |
| Blackwater Crossing | 7.28 → 6.95 | 6.86 → 6.72 | 9.86 → 8.98 | 13.91 → 10.26 | 28.35 → 22.68 | 0/0/0 → 0/0/0 |
| Near advancing fog | 9.19 → 8.62 | 8.51 → 8.56 | 11.77 → 10.00 | 15.67 → 10.64 | 35.69 → 12.66 | 1/0/0 → 0/0/0 |
| Inside dangerous fog | 9.20 → 9.25 | 8.59 → 8.94 | 11.58 → 11.75 | 14.37 → 15.95 | 33.39 → 28.32 | 1/0/0 → 0/0/0 |
| Mission completion | 7.77 → 8.19 | 7.30 → 7.22 | 10.56 → 8.88 | 15.16 → 10.72 | 24.20 → 952.58 | 0/0/0 → 1/1/1 |

## Medium — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 1115.95 → 66.63 | 4 → 0 |
| Warehouse A | 91.40 → 69.43 | 0 → 0 |
| Warehouse B | 18.34 → 12.22 | 0 → 0 |
| Locomotive cab | 46.00 → 39.33 | 0 → 0 |
| Passenger car | 62.39 → 62.85 | 0 → 0 |
| Curved railway | 45.17 → 44.46 | 0 → 0 |
| Ashford Depot | 25.33 → 29.38 | 0 → 0 |
| Ashford workshop | 17.36 → 16.74 | 0 → 0 |
| Blackwater Crossing | 30.33 → 30.12 | 0 → 0 |
| Near advancing fog | 138.60 → 159.23 | 1 → 2 |
| Inside dangerous fog | 9.89 → 10.62 | 0 → 0 |
| Mission completion | 37.58 → 41.28 | 0 → 0 |

## High — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 11.46 → 11.34 | 11.33 → 11.18 | 12.90 → 13.27 | 14.21 → 15.20 | 15.20 → 17.03 | 0/0/0 → 0/0/0 |
| Warehouse A | 15.16 → 15.44 | 14.74 → 14.93 | 18.27 → 18.58 | 21.75 → 23.98 | 26.80 → 61.57 | 0/0/0 → 1/1/0 |
| Warehouse B | 13.60 → 14.88 | 13.02 → 14.04 | 16.66 → 19.56 | 20.72 → 24.77 | 30.86 → 35.88 | 0/0/0 → 1/0/0 |
| Locomotive cab | 14.55 → 16.18 | 14.30 → 15.69 | 15.77 → 19.23 | 16.75 → 24.11 | 22.66 → 41.77 | 0/0/0 → 4/0/0 |
| Passenger car | 15.28 → 15.95 | 15.01 → 15.69 | 16.65 → 17.87 | 17.94 → 19.88 | 27.14 → 24.99 | 0/0/0 → 0/0/0 |
| Curved railway | 9.54 → 10.99 | 9.33 → 10.70 | 11.22 → 14.40 | 12.33 → 19.25 | 14.21 → 65.38 | 0/0/0 → 2/1/0 |
| Ashford Depot | 8.79 → 9.25 | 8.70 → 8.99 | 9.86 → 12.65 | 10.93 → 18.09 | 12.61 → 25.23 | 0/0/0 → 0/0/0 |
| Ashford workshop | 9.52 → 10.11 | 9.40 → 9.81 | 10.91 → 13.01 | 11.71 → 17.20 | 13.19 → 23.93 | 0/0/0 → 0/0/0 |
| Blackwater Crossing | 8.99 → 9.94 | 8.77 → 9.61 | 10.33 → 11.88 | 11.57 → 17.81 | 15.08 → 28.39 | 0/0/0 → 0/0/0 |
| Near advancing fog | 9.92 → 12.87 | 9.59 → 12.30 | 11.74 → 16.37 | 13.11 → 25.94 | 16.71 → 39.63 | 0/0/0 → 2/0/0 |
| Inside dangerous fog | 11.58 → 13.27 | 10.81 → 12.61 | 16.66 → 18.04 | 21.95 → 24.21 | 34.44 → 40.42 | 1/0/0 → 3/0/0 |
| Mission completion | 9.05 → 13.07 | 8.79 → 11.29 | 11.56 → 22.01 | 14.56 → 33.40 | 25.21 → 116.86 | 0/0/0 → 13/4/2 |

## High — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 2166.52 → 99.06 | 2 → 0 |
| Warehouse A | 95.36 → 105.82 | 0 → 1 |
| Warehouse B | 17.64 → 36.76 | 0 → 0 |
| Locomotive cab | 56.47 → 46.59 | 0 → 0 |
| Passenger car | 81.83 → 95.00 | 0 → 0 |
| Curved railway | 41.30 → 51.09 | 0 → 0 |
| Ashford Depot | 26.33 → 23.64 | 0 → 0 |
| Ashford workshop | 15.51 → 21.41 | 0 → 0 |
| Blackwater Crossing | 24.38 → 27.83 | 0 → 0 |
| Near advancing fog | 46.60 → 179.03 | 0 → 1 |
| Inside dangerous fog | 10.20 → 24.23 | 0 → 0 |
| Mission completion | 70.47 → 137.37 | 0 → 1 |

## Every startup attempt

Times are seconds since engine process initialization. The first boundary combines OS/engine/driver startup and built-in shader preparation; the load boundary includes script/resources/decompression; activation includes `_ready`, geometry, physics registration and gameplay wiring. These aggregates cannot isolate every internal engine stage. Readiness follows destination-GPU preparation and physics synchronization.

| Revision / attempt | Engine to script | Script to load | Load | Instantiate | Activate | Render preparation + readiness | Total ready |
|---|---:|---:|---:|---:|---:|---:|---:|
| baseline-startup-1 | 40.458 | 0.887 | 14.202 | 0.043 | 13.086 | 44.251 | 112.927 |
| optimized-startup-1 | 5.836 | 0.144 | 2.981 | 0.007 | 2.223 | 16.742 | 27.933 |
| optimized-startup-2 | 4.363 | 0.089 | 1.632 | 0.009 | 1.402 | 13.084 | 20.579 |
| baseline-startup-2 | 5.376 | 0.089 | 1.922 | 0.013 | 6.576 | 11.470 | 25.446 |
| baseline-startup-3 | 4.123 | 0.119 | 1.164 | 0.006 | 6.476 | 10.297 | 22.185 |
| optimized-startup-3 | 3.930 | 0.070 | 1.281 | 0.008 | 0.930 | 10.193 | 16.412 |

## Process memory and failures

RSS is sampled every 0.5 seconds; it is not total GPU memory and can miss short peaks. Texture/static-memory monitors and per-location CPU timings are in the CSV. Retained frame/timeline arrays contribute to static-memory growth; identical instrumentation is used for both revisions.

| Process | Seconds to exit | Peak RSS MiB | Exit | Diagnostics |
|---|---:|---:|---:|---:|
| baseline-startup-1 | 115.63 | 513.83 | 0 | 2 |
| optimized-startup-1 | 29.71 | 534.33 | 0 | 0 |
| optimized-startup-2 | 22.19 | 504.80 | 0 | 0 |
| baseline-startup-2 | 26.93 | 498.02 | 0 | 0 |
| baseline-startup-3 | 23.57 | 497.91 | 0 | 0 |
| optimized-startup-3 | 17.95 | 505.08 | 0 | 0 |
| baseline-matrix-1 | 309.07 | 629.73 | 0 | 1 |
| optimized-matrix-1 | 296.27 | 630.06 | 0 | 0 |
| optimized-matrix-2 | 337.46 | 612.03 | 0 | 0 |
| baseline-matrix-2 | 352.25 | 612.69 | 0 | 0 |

The raw process logs retain every diagnostic and cache event. A complete JSON or zero exit does not override engine errors. Loading/preset preparation and fixture-transition times remain in the raw reports, separately from entry and steady samples. Fixtures deliberately reposition the player and freeze most simulation; the uninterrupted controls-driven recording is separate evidence.

## Worst-frame callback evidence

Twenty largest per-view worst frames from all attempts. Callback brackets are CPU elapsed intervals, including waits; they are not GPU timestamps. Full per-view records are in `worst-frames.csv`.

| Run | Preset / location / stage | Frame ms | Process ms | Physics ms | Render bracket ms |
|---|---|---:|---:|---:|---:|
| baseline-matrix-1 | High / Harlow platform / entry | 2166.518 | 0.369 | 0.000 | 2165.566 |
| baseline-matrix-2 | Medium / Harlow platform / entry | 1115.949 | 0.590 | 0.000 | 1114.636 |
| optimized-matrix-2 | Medium / Mission completion / steady | 952.577 | 0.008 | 0.008 | 951.724 |
| baseline-matrix-1 | Medium / Harlow platform / entry | 870.792 | 0.497 | 0.145 | 868.944 |
| baseline-matrix-2 | High / Harlow platform / entry | 849.779 | 0.396 | 0.128 | 848.170 |
| optimized-matrix-2 | High / Near advancing fog / entry | 179.033 | 0.759 | 0.075 | 177.167 |
| optimized-matrix-2 | Medium / Near advancing fog / entry | 159.230 | 0.253 | 0.082 | 157.556 |
| baseline-matrix-1 | Medium / Near advancing fog / entry | 138.597 | 0.493 | 0.084 | 137.212 |
| optimized-matrix-1 | High / Mission completion / entry | 137.368 | 0.006 | 0.003 | 136.840 |
| optimized-matrix-1 | Medium / Near advancing fog / entry | 122.487 | 0.310 | 0.082 | 120.928 |
| optimized-matrix-1 | High / Mission completion / steady | 116.860 | 0.014 | 0.011 | 116.015 |
| optimized-matrix-2 | High / Warehouse A / entry | 105.824 | 0.420 | 0.487 | 102.993 |
| baseline-matrix-2 | Low / Passenger car / entry | 103.220 | 0.321 | 0.075 | 101.816 |
| optimized-matrix-2 | High / Harlow platform / entry | 99.056 | 0.329 | 0.130 | 97.580 |
| optimized-matrix-1 | High / Warehouse A / entry | 98.446 | 0.764 | 0.308 | 95.747 |
| baseline-matrix-2 | High / Warehouse A / entry | 95.364 | 0.452 | 0.224 | 93.573 |
| optimized-matrix-1 | High / Passenger car / entry | 95.004 | 0.408 | 0.079 | 92.827 |
| baseline-matrix-2 | Medium / Warehouse A / entry | 91.396 | 0.605 | 0.161 | 88.765 |
| baseline-matrix-1 | High / Warehouse A / entry | 88.961 | 0.574 | 0.116 | 87.304 |
| baseline-matrix-2 | High / Passenger car / entry | 81.834 | 0.296 | 0.141 | 80.555 |

## Matrix preparation, separate from gameplay samples

Each process constructs the scene and prepares its initial Low view before measurement. Later preset changes prepare the existing scene. All time remains reported here; moving work into preparation does not make startup free.

| Run | Scene construction ms | Initial render-ready ms from construction start | Low / Medium / High preset preparation ms |
|---|---:|---:|---|
| baseline-matrix-1 | 8075 | 17689 | 251 / 10671 / 9684 |
| optimized-matrix-1 | 2435 | 12169 | 318 / 7128 / 10656 |
| optimized-matrix-2 | 3428 | 15361 | 416 / 7759 / 11293 |
| baseline-matrix-2 | 11341 | 22705 | 296 / 4494 / 7074 |

## Shader-cache diagnostics

The process logs preserve every PSO load/save event. Shader-code hit/miss messages are engine diagnostics, not a count of every pipeline or texture upload.

| Process | Shader hits | Shader misses | PSO events |
|---|---:|---:|---|
| baseline-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (3.0 MiB); Updated PSO cache (6.0 MiB); Updated PSO cache (9.1 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| optimized-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (13.5 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
| baseline-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
