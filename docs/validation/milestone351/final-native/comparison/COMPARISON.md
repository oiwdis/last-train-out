# Matched hosted comparison

Baseline `7df2f5abee54b8adcf27b8668263fba231a79033`; candidate `cc50670c9ae70aa2de7ce92185a229d284c075f8`.

Godot 4.5.1, 960×540 windowed, Vulkan, V-sync/frame cap off. Two sequential matrices per revision, alternating order. 60 entry frames and 600 steady frames per view per run, with 120 settling frames. Separate fresh application caches, warm filesystem, shared OS/driver cache state uncontrolled. No profiler, screenshots or Movie Maker. All samples, including failures and outliers, are retained. Pooled percentiles are recomputed from raw frames, never averaged from per-run percentiles. GPU timing zero means unavailable.

## Low — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 9.24 → 8.88 | 8.44 → 8.26 | 13.96 → 12.37 | 21.48 → 16.41 | 41.80 → 30.42 | 1/0/0 → 0/0/0 |
| Warehouse A | 10.43 → 10.99 | 9.70 → 10.19 | 15.13 → 15.63 | 19.03 → 24.98 | 41.74 → 38.27 | 2/0/0 → 2/0/0 |
| Warehouse B | 9.27 → 10.82 | 8.66 → 9.69 | 13.06 → 17.13 | 20.47 → 31.34 | 36.43 → 72.72 | 1/0/0 → 7/3/0 |
| Locomotive cab | 11.78 → 13.59 | 10.83 → 11.38 | 16.08 → 23.72 | 24.39 → 39.99 | 70.19 → 115.89 | 5/3/0 → 25/7/1 |
| Passenger car | 11.53 → 12.20 | 11.02 → 11.27 | 15.09 → 17.34 | 18.67 → 24.18 | 48.83 → 72.31 | 1/0/0 → 4/1/0 |
| Curved railway | 9.56 → 8.91 | 8.55 → 8.05 | 14.97 → 13.42 | 27.49 → 21.80 | 66.34 → 60.51 | 6/1/0 → 2/1/0 |
| Ashford Depot | 7.84 → 8.26 | 7.26 → 7.42 | 11.11 → 13.19 | 16.45 → 19.53 | 26.31 → 31.31 | 0/0/0 → 0/0/0 |
| Ashford workshop | 7.70 → 9.21 | 7.49 → 8.16 | 11.11 → 15.22 | 14.27 → 29.09 | 20.87 → 83.33 | 0/0/0 → 10/3/0 |
| Blackwater Crossing | 8.21 → 8.88 | 8.27 → 8.04 | 11.90 → 14.47 | 22.41 → 24.05 | 65.82 → 99.27 | 3/1/0 → 5/3/0 |
| Near advancing fog | 8.04 → 7.87 | 7.60 → 7.56 | 11.54 → 10.71 | 17.91 → 15.16 | 25.96 → 46.00 | 0/0/0 → 2/0/0 |
| Inside dangerous fog | 8.99 → 8.54 | 7.64 → 7.84 | 11.91 → 13.38 | 17.09 → 19.81 | 652.70 → 38.59 | 4/2/2 → 3/0/0 |
| Mission completion | 8.00 → 8.11 | 7.49 → 7.51 | 11.23 → 12.34 | 19.50 → 18.11 | 25.72 → 50.13 | 0/0/0 → 2/1/0 |

## Low — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 31.50 → 54.77 | 0 → 0 |
| Warehouse A | 65.22 → 54.27 | 0 → 0 |
| Warehouse B | 14.93 → 38.45 | 0 → 0 |
| Locomotive cab | 38.81 → 45.44 | 0 → 0 |
| Passenger car | 99.38 → 93.82 | 0 → 0 |
| Curved railway | 36.72 → 38.93 | 0 → 0 |
| Ashford Depot | 15.92 → 18.54 | 0 → 0 |
| Ashford workshop | 14.90 → 14.51 | 0 → 0 |
| Blackwater Crossing | 38.03 → 18.17 | 0 → 0 |
| Near advancing fog | 97.62 → 127.53 | 0 → 1 |
| Inside dangerous fog | 16.15 → 43.96 | 0 → 0 |
| Mission completion | 40.98 → 91.20 | 0 → 0 |

## Medium — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 13.89 → 11.81 | 12.57 → 11.18 | 20.35 → 16.36 | 32.58 → 23.46 | 62.82 → 51.30 | 11/3/0 → 4/1/0 |
| Warehouse A | 16.68 → 13.92 | 14.59 → 12.76 | 28.97 → 21.03 | 45.30 → 32.42 | 91.32 → 74.64 | 38/10/0 → 10/5/0 |
| Warehouse B | 14.02 → 12.02 | 13.02 → 11.11 | 21.22 → 18.25 | 28.55 → 26.50 | 47.09 → 63.07 | 6/0/0 → 6/3/0 |
| Locomotive cab | 15.05 → 14.29 | 14.02 → 13.24 | 20.77 → 20.06 | 35.46 → 28.66 | 72.00 → 62.62 | 15/6/0 → 7/3/0 |
| Passenger car | 14.74 → 16.06 | 14.30 → 14.99 | 20.14 → 22.36 | 24.30 → 32.51 | 49.03 → 52.72 | 1/0/0 → 11/1/0 |
| Curved railway | 10.82 → 12.45 | 9.90 → 10.55 | 16.03 → 20.99 | 25.75 → 36.59 | 46.74 → 84.44 | 4/0/0 → 17/6/0 |
| Ashford Depot | 9.33 → 12.96 | 8.74 → 10.71 | 13.52 → 23.21 | 21.48 → 51.21 | 31.56 → 110.44 | 0/0/0 → 24/13/1 |
| Ashford workshop | 10.31 → 11.54 | 9.47 → 10.28 | 15.37 → 18.99 | 20.64 → 28.63 | 53.28 → 87.67 | 3/1/0 → 7/1/0 |
| Blackwater Crossing | 9.71 → 9.87 | 8.90 → 8.93 | 14.52 → 15.71 | 18.55 → 23.67 | 65.08 → 64.98 | 5/1/0 → 2/1/0 |
| Near advancing fog | 11.68 → 11.75 | 10.81 → 10.52 | 17.09 → 18.72 | 26.40 → 34.12 | 48.43 → 80.33 | 8/0/0 → 13/3/0 |
| Inside dangerous fog | 11.35 → 11.68 | 10.40 → 10.69 | 16.03 → 18.39 | 26.30 → 30.64 | 75.86 → 57.52 | 7/3/0 → 11/3/0 |
| Mission completion | 9.55 → 9.10 | 8.91 → 8.54 | 13.21 → 13.87 | 24.32 → 19.70 | 85.78 → 29.59 | 3/2/0 → 0/0/0 |

## Medium — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 1866.18 → 65.72 | 2 → 0 |
| Warehouse A | 97.96 → 90.19 | 0 → 0 |
| Warehouse B | 22.82 → 23.18 | 0 → 0 |
| Locomotive cab | 46.74 → 33.75 | 0 → 0 |
| Passenger car | 92.62 → 88.17 | 0 → 0 |
| Curved railway | 59.25 → 71.22 | 0 → 0 |
| Ashford Depot | 38.62 → 47.74 | 0 → 0 |
| Ashford workshop | 34.98 → 33.98 | 0 → 0 |
| Blackwater Crossing | 25.52 → 36.75 | 0 → 0 |
| Near advancing fog | 75.50 → 61.68 | 0 → 0 |
| Inside dangerous fog | 27.21 → 33.34 | 0 → 0 |
| Mission completion | 102.54 → 125.48 | 1 → 1 |

## High — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 13.85 → 15.62 | 13.23 → 14.30 | 18.33 → 23.08 | 23.99 → 38.56 | 38.15 → 84.21 | 1/0/0 → 17/4/0 |
| Warehouse A | 18.43 → 20.16 | 17.59 → 18.51 | 24.59 → 30.67 | 33.88 → 46.39 | 62.38 → 105.92 | 13/3/0 → 39/9/1 |
| Warehouse B | 17.69 → 21.38 | 16.44 → 18.41 | 25.41 → 36.22 | 34.91 → 63.72 | 65.46 → 115.28 | 18/2/0 → 82/24/1 |
| Locomotive cab | 17.79 → 16.94 | 16.80 → 16.26 | 22.79 → 21.23 | 35.80 → 26.65 | 104.48 → 42.88 | 14/3/1 → 6/0/0 |
| Passenger car | 17.95 → 17.81 | 17.27 → 17.02 | 22.44 → 21.89 | 29.96 → 28.94 | 46.44 → 74.71 | 4/0/0 → 11/3/0 |
| Curved railway | 12.07 → 12.79 | 11.61 → 11.80 | 16.73 → 18.18 | 20.48 → 27.77 | 33.44 → 46.81 | 1/0/0 → 8/0/0 |
| Ashford Depot | 10.67 → 11.37 | 10.00 → 10.59 | 14.51 → 16.48 | 18.93 → 26.01 | 40.19 → 40.63 | 2/0/0 → 2/0/0 |
| Ashford workshop | 11.78 → 12.11 | 11.21 → 11.34 | 15.42 → 16.70 | 21.98 → 21.53 | 46.16 → 96.12 | 3/0/0 → 2/2/0 |
| Blackwater Crossing | 10.90 → 11.68 | 10.34 → 10.56 | 14.30 → 18.33 | 20.78 → 25.93 | 38.45 → 49.56 | 1/0/0 → 3/0/0 |
| Near advancing fog | 15.46 → 14.06 | 14.31 → 13.23 | 22.42 → 20.23 | 32.85 → 27.38 | 108.67 → 80.47 | 10/4/1 → 4/1/0 |
| Inside dangerous fog | 14.37 → 13.87 | 13.43 → 13.02 | 20.32 → 19.06 | 29.34 → 27.46 | 108.41 → 44.37 | 6/4/1 → 5/0/0 |
| Mission completion | 11.49 → 12.76 | 11.01 → 11.40 | 15.80 → 18.00 | 19.29 → 35.94 | 30.44 → 133.36 | 0/0/0 → 14/6/3 |

## High — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 2393.06 → 89.19 | 2 → 0 |
| Warehouse A | 143.45 → 168.37 | 4 → 4 |
| Warehouse B | 29.39 → 48.74 | 0 → 0 |
| Locomotive cab | 88.31 → 75.33 | 0 → 0 |
| Passenger car | 133.98 → 88.15 | 1 → 0 |
| Curved railway | 55.24 → 61.12 | 0 → 0 |
| Ashford Depot | 21.65 → 37.30 | 0 → 0 |
| Ashford workshop | 26.85 → 37.85 | 0 → 0 |
| Blackwater Crossing | 38.04 → 36.32 | 0 → 0 |
| Near advancing fog | 161.79 → 80.68 | 1 → 0 |
| Inside dangerous fog | 49.98 → 31.19 | 0 → 0 |
| Mission completion | 112.45 → 47.75 | 1 → 0 |

## Every startup attempt

Times are seconds since engine process initialization. The first boundary combines OS/engine/driver startup and built-in shader preparation; the load boundary includes script/resources/decompression; activation includes `_ready`, geometry, physics registration and gameplay wiring. These aggregates cannot isolate every internal engine stage. Readiness follows destination-GPU preparation and physics synchronization.

| Revision / attempt | Engine to script | Load | Instantiate | Activate | Render preparation + readiness | Total ready |
|---|---:|---:|---:|---:|---:|---:|
| baseline-startup-1 | 6.361 | 3.237 | 0.013 | 12.050 | 20.245 | 42.104 |
| optimized-startup-1 | 6.510 | 2.885 | 0.008 | 2.062 | 14.365 | 25.999 |
| optimized-startup-2 | 4.568 | 1.241 | 0.007 | 1.230 | 11.436 | 18.579 |
| baseline-startup-2 | 4.300 | 1.239 | 0.006 | 8.377 | 15.629 | 29.651 |
| baseline-startup-3 | 6.510 | 2.405 | 0.018 | 10.130 | 12.197 | 31.441 |
| optimized-startup-3 | 4.567 | 1.700 | 0.009 | 1.133 | 11.495 | 19.052 |

## Process memory and failures

RSS is sampled every 0.5 seconds; it is not total GPU memory and can miss short peaks. Texture/static-memory monitors and per-location CPU timings are in the CSV. Retained frame/timeline arrays contribute to static-memory growth; identical instrumentation is used for both revisions.

| Process | Seconds to exit | Peak RSS MiB | Exit | Diagnostics |
|---|---:|---:|---:|---:|
| baseline-startup-1 | 44.20 | 528.48 | 0 | 1 |
| optimized-startup-1 | 27.72 | 525.44 | 0 | 0 |
| optimized-startup-2 | 20.56 | 503.98 | 0 | 0 |
| baseline-startup-2 | 31.55 | 497.50 | 0 | 0 |
| baseline-startup-3 | 33.54 | 498.02 | 0 | 0 |
| optimized-startup-3 | 20.62 | 504.19 | 0 | 0 |
| baseline-matrix-1 | 382.99 | 618.80 | 0 | 1 |
| optimized-matrix-1 | 384.15 | 632.03 | 0 | 0 |
| optimized-matrix-2 | 412.98 | 608.92 | 0 | 0 |
| baseline-matrix-2 | 408.74 | 604.05 | 0 | 0 |

The raw process logs retain every diagnostic and cache event. A complete JSON or zero exit does not override engine errors. Loading/preset preparation and fixture-transition times remain in the raw reports, separately from entry and steady samples. Fixtures deliberately reposition the player and freeze most simulation; the uninterrupted controls-driven recording is separate evidence.

## Worst-frame callback evidence

Twenty largest per-view worst frames from all attempts. Callback brackets are CPU elapsed intervals, including waits; they are not GPU timestamps. Full per-view records are in `worst-frames.csv`.

| Run | Preset / location / stage | Frame ms | Process ms | Physics ms | Render bracket ms |
|---|---|---:|---:|---:|---:|
| baseline-matrix-1 | High / Harlow platform / entry | 2393.057 | 0.787 | 0.000 | 2391.309 |
| baseline-matrix-2 | High / Harlow platform / entry | 2022.887 | 1.257 | 0.134 | 2019.646 |
| baseline-matrix-1 | Medium / Harlow platform / entry | 1866.183 | 0.517 | 0.140 | 1863.341 |
| baseline-matrix-1 | Low / Inside dangerous fog / steady | 652.695 | 1.359 | 0.260 | 22.225 |
| baseline-matrix-2 | Medium / Harlow platform / entry | 382.995 | 0.600 | 0.079 | 380.541 |
| optimized-matrix-1 | High / Warehouse A / entry | 168.372 | 1.253 | 0.000 | 166.069 |
| baseline-matrix-2 | High / Near advancing fog / entry | 161.795 | 0.329 | 0.063 | 160.198 |
| baseline-matrix-2 | High / Warehouse A / entry | 143.454 | 1.260 | 1.166 | 137.647 |
| baseline-matrix-1 | High / Warehouse A / entry | 138.435 | 1.222 | 0.089 | 136.248 |
| optimized-matrix-2 | High / Warehouse A / entry | 136.030 | 0.499 | 0.075 | 134.891 |
| baseline-matrix-2 | High / Passenger car / entry | 133.977 | 0.648 | 0.066 | 131.931 |
| optimized-matrix-2 | High / Mission completion / steady | 133.360 | 0.326 | 0.003 | 132.480 |
| optimized-matrix-1 | Low / Near advancing fog / entry | 127.533 | 0.398 | 0.268 | 125.720 |
| optimized-matrix-1 | Medium / Mission completion / entry | 125.479 | 0.020 | 0.008 | 124.224 |
| optimized-matrix-1 | Low / Locomotive cab / steady | 115.885 | 0.367 | 0.089 | 114.943 |
| optimized-matrix-2 | High / Warehouse B / steady | 115.285 | 0.469 | 0.213 | 114.072 |
| baseline-matrix-2 | High / Mission completion / entry | 112.450 | 0.007 | 0.003 | 112.047 |
| optimized-matrix-1 | Medium / Ashford Depot / steady | 110.437 | 0.692 | 0.252 | 108.614 |
| baseline-matrix-2 | High / Near advancing fog / steady | 108.670 | 0.313 | 0.080 | 100.123 |
| baseline-matrix-2 | High / Inside dangerous fog / steady | 108.414 | 0.969 | 0.079 | 83.361 |

## Matrix preparation, separate from gameplay samples

Each process constructs the scene and prepares its initial Low view before measurement. Later preset changes prepare the existing scene. All time remains reported here; moving work into preparation does not make startup free.

| Run | Scene construction ms | Initial render-ready ms from construction start | Low / Medium / High preset preparation ms |
|---|---:|---:|---|
| baseline-matrix-1 | 9084 | 21141 | 217 / 6358 / 7378 |
| optimized-matrix-1 | 3138 | 14065 | 368 / 9924 / 13199 |
| optimized-matrix-2 | 3167 | 18805 | 444 / 8519 / 13970 |
| baseline-matrix-2 | 13449 | 26901 | 271 / 5152 / 7482 |

## Shader-cache diagnostics

The process logs preserve every PSO load/save event. Shader-code hit/miss messages are engine diagnostics, not a count of every pipeline or texture upload.

| Process | Shader hits | Shader misses | PSO events |
|---|---:|---:|---|
| baseline-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (3.0 MiB); Updated PSO cache (6.3 MiB); Updated PSO cache (9.4 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-1 | 0 | 94 | Startup PSO cache (0.0 MiB); Updated PSO cache (10.4 MiB) |
| optimized-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-2 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| optimized-startup-3 | 0 | 0 | Startup PSO cache (10.4 MiB) |
| baseline-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (13.5 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-1 | 0 | 0 | Startup PSO cache (10.4 MiB); Updated PSO cache (15.3 MiB) |
| optimized-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
| baseline-matrix-2 | 0 | 0 | Startup PSO cache (15.3 MiB) |
