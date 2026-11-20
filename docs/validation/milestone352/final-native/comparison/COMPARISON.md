# Matched hosted comparison

Baseline `7df2f5abee54b8adcf27b8668263fba231a79033`; candidate `6038bfcd0f0c5427ae6c53435d2867282938f6e4`.

Godot 4.5.1, 960×540 windowed, Vulkan, V-sync/frame cap off. Two sequential matrices per revision, alternating order. 60 entry frames and 600 steady frames per view per run, with 120 settling frames. Separate fresh application caches, warm filesystem, shared OS/driver cache state uncontrolled. No profiler, screenshots or Movie Maker. All samples, including failures and outliers, are retained. Pooled percentiles are recomputed from raw frames, never averaged from per-run percentiles. GPU timing zero means unavailable.

## Low — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 8.03 → 16.08 | 7.30 → 21.69 | 12.27 → 25.34 | 16.82 → 32.19 | 49.00 → 56.59 | 2/0/0 → 5/1/0 |
| Warehouse A | 7.67 → 18.46 | 7.36 → 16.88 | 10.26 → 35.36 | 12.63 → 40.86 | 20.96 → 62.40 | 0/0/0 → 169/3/0 |
| Warehouse B | 8.07 → 15.60 | 7.26 → 16.89 | 12.36 → 27.80 | 18.02 → 42.67 | 49.75 → 89.36 | 2/0/0 → 23/7/0 |
| Locomotive cab | 8.53 → 18.69 | 7.96 → 14.49 | 12.10 → 34.89 | 17.11 → 41.70 | 32.93 → 63.73 | 0/0/0 → 178/4/0 |
| Passenger car | 8.82 → 19.33 | 8.54 → 18.92 | 11.09 → 34.73 | 13.73 → 41.27 | 30.40 → 130.95 | 0/0/0 → 151/4/1 |
| Curved railway | 7.53 → 16.41 | 7.21 → 16.01 | 9.79 → 31.79 | 12.04 → 33.67 | 27.68 → 47.99 | 0/0/0 → 17/0/0 |
| Ashford Depot | 6.54 → 15.44 | 6.17 → 13.83 | 8.97 → 25.10 | 12.10 → 27.02 | 22.67 → 47.86 | 0/0/0 → 3/0/0 |
| Ashford workshop | 7.79 → 16.36 | 6.98 → 19.18 | 12.36 → 25.23 | 18.39 → 31.66 | 54.67 → 38.93 | 6/1/0 → 2/0/0 |
| Blackwater Crossing | 6.85 → 16.06 | 6.67 → 21.32 | 8.63 → 25.02 | 9.99 → 28.40 | 18.29 → 46.76 | 0/0/0 → 1/0/0 |
| Near advancing fog | 7.29 → 16.27 | 6.96 → 22.71 | 10.12 → 25.05 | 13.81 → 30.34 | 18.39 → 50.29 | 0/0/0 → 5/1/0 |
| Inside dangerous fog | 6.85 → 16.59 | 6.73 → 22.74 | 9.45 → 25.07 | 13.86 → 30.93 | 20.26 → 70.36 | 0/0/0 → 5/1/0 |
| Mission completion | 5.59 → 16.32 | 5.30 → 22.28 | 7.76 → 25.05 | 10.12 → 31.92 | 15.64 → 47.26 | 0/0/0 → 7/0/0 |

## Low — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 11.79 → 25.31 | 0 → 0 |
| Warehouse A | 109.04 → 58.76 | 1 → 0 |
| Warehouse B | 11.04 → 36.46 | 0 → 0 |
| Locomotive cab | 31.40 → 77.80 | 0 → 0 |
| Passenger car | 147.85 → 106.14 | 1 → 1 |
| Curved railway | 27.81 → 73.27 | 0 → 0 |
| Ashford Depot | 56.20 → 31.89 | 0 → 0 |
| Ashford workshop | 10.17 → 32.34 | 0 → 0 |
| Blackwater Crossing | 26.31 → 32.83 | 0 → 0 |
| Near advancing fog | 111.60 → 64.44 | 1 → 0 |
| Inside dangerous fog | 11.44 → 37.95 | 0 → 0 |
| Mission completion | 25.91 → 83.50 | 0 → 0 |

## Medium — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 13.41 → 20.46 | 14.36 → 20.64 | 18.17 → 28.48 | 24.74 → 35.19 | 44.60 → 48.98 | 3/0/0 → 32/0/0 |
| Warehouse A | 16.13 → 22.64 | 14.13 → 21.91 | 29.15 → 32.62 | 42.84 → 35.61 | 86.99 → 102.99 | 32/6/0 → 44/1/1 |
| Warehouse B | 13.09 → 21.84 | 13.91 → 22.03 | 17.28 → 32.16 | 22.34 → 34.08 | 24.69 → 50.94 | 0/0/0 → 19/1/0 |
| Locomotive cab | 14.42 → 22.23 | 15.05 → 20.95 | 17.92 → 32.26 | 22.56 → 40.87 | 35.15 → 55.67 | 1/0/0 → 50/2/0 |
| Passenger car | 14.54 → 24.36 | 15.32 → 23.92 | 19.67 → 32.46 | 25.02 → 41.18 | 60.04 → 56.25 | 7/2/0 → 40/1/0 |
| Curved railway | 11.78 → 20.86 | 10.55 → 20.83 | 17.01 → 32.18 | 17.91 → 35.56 | 26.64 → 50.13 | 0/0/0 → 41/1/0 |
| Ashford Depot | 11.75 → 19.68 | 10.01 → 21.94 | 17.13 → 25.02 | 20.07 → 26.71 | 41.33 → 33.07 | 1/0/0 → 0/0/0 |
| Ashford workshop | 13.24 → 20.25 | 14.74 → 20.93 | 17.27 → 25.30 | 22.64 → 31.97 | 38.99 → 47.23 | 1/0/0 → 4/0/0 |
| Blackwater Crossing | 12.44 → 19.92 | 11.53 → 22.44 | 18.21 → 25.09 | 24.14 → 31.33 | 57.68 → 60.25 | 4/2/0 → 5/1/0 |
| Near advancing fog | 13.84 → 20.95 | 15.19 → 21.50 | 19.23 → 32.33 | 24.52 → 39.98 | 49.22 → 76.00 | 4/0/0 → 53/3/0 |
| Inside dangerous fog | 13.23 → 21.37 | 14.59 → 21.50 | 17.14 → 32.46 | 21.38 → 40.82 | 35.30 → 389.66 | 2/0/0 → 54/7/1 |
| Mission completion | 11.87 → 20.63 | 10.84 → 21.24 | 17.11 → 25.73 | 18.05 → 45.99 | 26.00 → 72.03 | 0/0/0 → 26/10/0 |

## Medium — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 1221.97 → 62.32 | 2 → 0 |
| Warehouse A | 145.12 → 91.71 | 1 → 0 |
| Warehouse B | 63.06 → 47.03 | 0 → 0 |
| Locomotive cab | 42.38 → 51.17 | 0 → 0 |
| Passenger car | 67.98 → 122.58 | 0 → 1 |
| Curved railway | 40.62 → 72.26 | 0 → 0 |
| Ashford Depot | 23.83 → 46.52 | 0 → 0 |
| Ashford workshop | 23.26 → 38.78 | 0 → 0 |
| Blackwater Crossing | 59.02 → 46.65 | 0 → 0 |
| Near advancing fog | 66.51 → 164.59 | 0 → 1 |
| Inside dangerous fog | 17.81 → 72.27 | 0 → 0 |
| Mission completion | 60.17 → 131.20 | 0 → 1 |

## High — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 15.38 → 26.31 | 15.45 → 24.74 | 21.36 → 46.13 | 23.86 → 54.73 | 32.85 → 72.21 | 0/0/0 → 176/13/0 |
| Warehouse A | 20.61 → 29.98 | 20.84 → 28.45 | 29.35 → 47.01 | 39.24 → 55.29 | 61.99 → 286.62 | 19/4/0 → 375/21/2 |
| Warehouse B | 21.09 → 26.94 | 20.95 → 28.53 | 28.24 → 43.05 | 39.59 → 49.00 | 63.33 → 103.78 | 22/1/0 → 244/12/1 |
| Locomotive cab | 21.12 → 28.59 | 20.54 → 27.82 | 30.27 → 42.82 | 40.31 → 50.28 | 89.25 → 58.19 | 34/6/0 → 391/14/0 |
| Passenger car | 21.88 → 33.51 | 20.12 → 28.88 | 26.03 → 49.90 | 34.51 → 58.11 | 1061.51 → 68.22 | 14/5/2 → 582/60/0 |
| Curved railway | 14.80 → 22.35 | 15.42 → 20.78 | 22.02 → 33.16 | 30.37 → 40.59 | 65.89 → 71.11 | 6/3/0 → 60/1/0 |
| Ashford Depot | 12.94 → 22.66 | 12.80 → 22.90 | 17.35 → 32.26 | 23.66 → 34.31 | 40.45 → 60.73 | 2/0/0 → 22/1/0 |
| Ashford workshop | 13.63 → 23.34 | 14.86 → 21.22 | 17.58 → 34.12 | 24.85 → 39.36 | 44.62 → 49.28 | 6/0/0 → 87/0/0 |
| Blackwater Crossing | 14.20 → 22.83 | 14.28 → 21.48 | 22.01 → 34.12 | 30.00 → 39.89 | 74.52 → 60.42 | 10/5/0 → 74/3/0 |
| Near advancing fog | 15.78 → 22.62 | 15.82 → 21.03 | 22.06 → 34.60 | 27.12 → 42.41 | 50.13 → 56.55 | 6/1/0 → 144/3/0 |
| Inside dangerous fog | 14.82 → 22.01 | 15.02 → 21.03 | 21.06 → 34.03 | 23.77 → 38.80 | 34.11 → 51.33 | 1/0/0 → 79/2/0 |
| Mission completion | 13.46 → 23.55 | 14.48 → 20.92 | 17.39 → 33.95 | 23.26 → 35.16 | 37.90 → 53.93 | 1/0/0 → 75/1/0 |

## High — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 2404.75 → 96.79 | 3 → 0 |
| Warehouse A | 123.22 → 160.75 | 2 → 4 |
| Warehouse B | 85.47 → 55.65 | 0 → 0 |
| Locomotive cab | 86.40 → 114.88 | 0 → 1 |
| Passenger car | 111.18 → 135.71 | 1 → 2 |
| Curved railway | 66.97 → 69.61 | 0 → 0 |
| Ashford Depot | 25.32 → 48.13 | 0 → 0 |
| Ashford workshop | 43.53 → 48.21 | 0 → 0 |
| Blackwater Crossing | 38.73 → 54.67 | 0 → 0 |
| Near advancing fog | 64.85 → 72.73 | 0 → 0 |
| Inside dangerous fog | 24.77 → 56.31 | 0 → 0 |
| Mission completion | 135.53 → 56.09 | 1 → 0 |

## Every startup attempt

Times are seconds since engine process initialization. The first boundary combines OS/engine/driver startup and built-in shader preparation; the load boundary includes script/resources/decompression; activation includes `_ready`, geometry, physics registration and gameplay wiring. These aggregates cannot isolate every internal engine stage. Readiness follows destination-GPU preparation and physics synchronization.

| Revision / attempt | Engine to script | Script to load | Load | Instantiate | Activate | Render preparation + readiness | Total ready |
|---|---:|---:|---:|---:|---:|---:|---:|
| baseline-startup-1 | 8.440 | 0.382 | 5.204 | 0.014 | 10.477 | 15.181 | 39.698 |
| optimized-startup-1 | 4.987 | 0.163 | 3.012 | 0.016 | 2.216 | 13.792 | 24.186 |
| optimized-startup-2 | 4.596 | 0.081 | 1.277 | 0.007 | 1.026 | 12.145 | 19.132 |
| baseline-startup-2 | 5.298 | 0.152 | 2.501 | 0.013 | 8.653 | 14.368 | 30.985 |
| baseline-startup-3 | 4.415 | 0.107 | 1.661 | 0.007 | 6.175 | 11.480 | 23.845 |
| optimized-startup-3 | 4.035 | 0.104 | 1.217 | 0.007 | 1.458 | 10.514 | 17.335 |

## Process memory and failures

RSS is sampled every 0.5 seconds; it is not total GPU memory and can miss short peaks. Texture/static-memory monitors and per-location CPU timings are in the CSV. Retained frame/timeline arrays contribute to static-memory growth; identical instrumentation is used for both revisions.

| Process | Seconds to exit | Peak RSS MiB | Exit | Diagnostics |
|---|---:|---:|---:|---:|
| baseline-startup-1 | 41.56 | 525.89 | 0 | 1 |
| optimized-startup-1 | 26.15 | 529.83 | 0 | 0 |
| optimized-startup-2 | 20.78 | 504.73 | 0 | 0 |
| baseline-startup-2 | 33.31 | 497.17 | 0 | 0 |
| baseline-startup-3 | 25.32 | 497.44 | 0 | 0 |
| optimized-startup-3 | 18.82 | 504.25 | 0 | 0 |
| baseline-matrix-1 | 464.34 | 627.33 | 0 | 1 |
| optimized-matrix-1 | 855.00 | 630.34 | 0 | 0 |
| optimized-matrix-2 | 444.11 | 613.02 | 0 | 0 |
| baseline-matrix-2 | 352.21 | 602.70 | 0 | 0 |

The raw process logs retain every diagnostic and cache event. A complete JSON or zero exit does not override engine errors. Loading/preset preparation and fixture-transition times remain in the raw reports, separately from entry and steady samples. Fixtures deliberately reposition the player and freeze most simulation; the uninterrupted controls-driven recording is separate evidence.

## Worst-frame callback evidence

Twenty largest per-view worst frames from all attempts. Callback brackets are CPU elapsed intervals, including waits; they are not GPU timestamps. Full per-view records are in `worst-frames.csv`.

| Run | Preset / location / stage | Frame ms | Process ms | Physics ms | Render bracket ms |
|---|---|---:|---:|---:|---:|
| baseline-matrix-2 | High / Harlow platform / entry | 2404.751 | 0.527 | 0.108 | 2403.056 |
| baseline-matrix-1 | Medium / Harlow platform / entry | 1221.968 | 0.604 | 0.063 | 1220.397 |
| baseline-matrix-1 | High / Harlow platform / entry | 1205.030 | 0.629 | 0.065 | 1203.562 |
| baseline-matrix-1 | High / Passenger car / steady | 1061.507 | 2.973 | 1.003 | 498.719 |
| baseline-matrix-2 | Medium / Harlow platform / entry | 747.083 | 0.630 | 0.000 | 745.672 |
| optimized-matrix-1 | Medium / Inside dangerous fog / steady | 389.657 | 0.284 | 0.104 | 382.899 |
| optimized-matrix-1 | High / Warehouse A / steady | 286.625 | 0.439 | 0.392 | 283.803 |
| optimized-matrix-2 | Medium / Near advancing fog / entry | 164.593 | 0.323 | 0.144 | 162.851 |
| optimized-matrix-1 | High / Warehouse A / entry | 160.749 | 0.335 | 0.180 | 158.986 |
| baseline-matrix-1 | Low / Passenger car / entry | 147.852 | 0.410 | 0.078 | 146.079 |
| baseline-matrix-1 | Medium / Warehouse A / entry | 145.124 | 1.003 | 0.268 | 142.113 |
| optimized-matrix-1 | High / Passenger car / entry | 135.709 | 0.596 | 0.115 | 134.036 |
| baseline-matrix-1 | High / Mission completion / entry | 135.529 | 0.237 | 0.004 | 134.528 |
| optimized-matrix-1 | Medium / Mission completion / entry | 131.201 | 0.009 | 0.008 | 130.359 |
| optimized-matrix-1 | Low / Passenger car / steady | 130.952 | 0.398 | 0.100 | 129.923 |
| baseline-matrix-1 | High / Warehouse A / entry | 123.215 | 2.298 | 0.166 | 116.197 |
| optimized-matrix-2 | Medium / Passenger car / entry | 122.575 | 0.274 | 0.056 | 121.566 |
| optimized-matrix-2 | High / Warehouse A / entry | 121.658 | 0.325 | 0.085 | 120.087 |
| optimized-matrix-2 | High / Passenger car / entry | 119.891 | 0.265 | 0.114 | 118.603 |
| baseline-matrix-2 | High / Warehouse A / entry | 118.725 | 0.790 | 0.202 | 116.835 |

## Matrix preparation, separate from gameplay samples

Each process constructs the scene and prepares its initial Low view before measurement. Later preset changes prepare the existing scene. All time remains reported here; moving work into preparation does not make startup free.

| Run | Scene construction ms | Initial render-ready ms from construction start | Low / Medium / High preset preparation ms |
|---|---:|---:|---|
| baseline-matrix-1 | 10565 | 24971 | 190 / 4972 / 8177 |
| optimized-matrix-1 | 3038 | 17581 | 1217 / 8320 / 16485 |
| optimized-matrix-2 | 2080 | 12416 | 361 / 8553 / 13546 |
| baseline-matrix-2 | 11276 | 22788 | 211 / 4562 / 7867 |

## Shader-cache diagnostics

The process logs preserve every PSO load/save event. Shader-code hit/miss messages are engine diagnostics, not a count of every pipeline or texture upload.

| Process | Shader hits | Shader misses | PSO events |
|---|---:|---:|---|
| baseline-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (3.0 MiB); Updated PSO cache (6.2 MiB); Updated PSO cache (9.2 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| optimized-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (13.5 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
| baseline-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
