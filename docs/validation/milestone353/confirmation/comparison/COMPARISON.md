# Matched hosted comparison

Baseline `7df2f5abee54b8adcf27b8668263fba231a79033`; candidate `0697621649a1493b2a341343d3da7a3b987ff9ab`.

Godot 4.5.1, 960×540 windowed, Vulkan, V-sync/frame cap off. Two sequential matrices per revision, alternating order. 60 entry frames and 600 steady frames per view per run, with 120 settling frames. Separate fresh application caches, warm filesystem, shared OS/driver cache state uncontrolled. No profiler, screenshots or Movie Maker. All samples, including failures and outliers, are retained. Pooled percentiles are recomputed from raw frames, never averaged from per-run percentiles. GPU timing zero means unavailable.

## Low — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 7.49 → 7.32 | 7.37 → 7.22 | 9.20 → 8.94 | 10.85 → 10.58 | 21.29 → 15.71 | 0/0/0 → 0/0/0 |
| Warehouse A | 9.18 → 8.56 | 8.86 → 8.42 | 11.62 → 9.99 | 14.60 → 12.32 | 22.84 → 20.16 | 0/0/0 → 0/0/0 |
| Warehouse B | 8.42 → 9.17 | 8.13 → 8.01 | 12.48 → 10.17 | 15.79 → 12.57 | 25.35 → 976.26 | 0/0/0 → 3/2/2 |
| Locomotive cab | 11.33 → 9.96 | 10.70 → 9.71 | 15.68 → 11.48 | 22.07 → 13.56 | 34.59 → 29.62 | 1/0/0 → 0/0/0 |
| Passenger car | 11.63 → 11.19 | 10.90 → 10.34 | 16.02 → 15.80 | 23.63 → 21.05 | 36.87 → 49.91 | 2/0/0 → 3/0/0 |
| Curved railway | 8.41 → 9.02 | 7.75 → 8.18 | 12.53 → 14.92 | 16.96 → 22.43 | 32.12 → 33.34 | 0/0/0 → 1/0/0 |
| Ashford Depot | 6.20 → 6.71 | 6.26 → 6.31 | 8.04 → 9.51 | 10.06 → 11.63 | 13.92 → 28.78 | 0/0/0 → 0/0/0 |
| Ashford workshop | 7.37 → 7.06 | 6.61 → 6.70 | 12.48 → 9.55 | 18.98 → 12.18 | 52.38 → 29.08 | 3/1/0 → 0/0/0 |
| Blackwater Crossing | 6.93 → 7.23 | 6.72 → 6.62 | 9.57 → 10.93 | 13.02 → 16.36 | 27.28 → 33.20 | 0/0/0 → 0/0/0 |
| Near advancing fog | 7.07 → 6.64 | 6.85 → 6.48 | 8.73 → 8.19 | 11.36 → 10.03 | 22.35 → 12.85 | 0/0/0 → 0/0/0 |
| Inside dangerous fog | 7.52 → 6.72 | 6.99 → 6.52 | 10.81 → 8.42 | 14.21 → 11.17 | 32.12 → 22.18 | 0/0/0 → 0/0/0 |
| Mission completion | 6.05 → 6.32 | 5.97 → 6.07 | 7.87 → 8.69 | 9.39 → 11.79 | 13.84 → 18.16 | 0/0/0 → 0/0/0 |

## Low — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 10.99 → 23.92 | 0 → 0 |
| Warehouse A | 41.26 → 55.46 | 0 → 0 |
| Warehouse B | 18.60 → 10.86 | 0 → 0 |
| Locomotive cab | 36.32 → 33.30 | 0 → 0 |
| Passenger car | 91.47 → 87.94 | 0 → 0 |
| Curved railway | 26.39 → 36.35 | 0 → 0 |
| Ashford Depot | 13.09 → 24.25 | 0 → 0 |
| Ashford workshop | 11.65 → 27.81 | 0 → 0 |
| Blackwater Crossing | 16.86 → 23.24 | 0 → 0 |
| Near advancing fog | 70.46 → 103.19 | 0 → 1 |
| Inside dangerous fog | 8.80 → 9.79 | 0 → 0 |
| Mission completion | 30.31 → 41.87 | 0 → 0 |

## Medium — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 11.27 → 10.86 | 10.90 → 10.58 | 14.67 → 13.62 | 18.49 → 17.91 | 26.61 → 33.31 | 0/0/0 → 1/0/0 |
| Warehouse A | 11.20 → 10.78 | 10.60 → 10.47 | 13.92 → 13.92 | 20.19 → 16.17 | 49.41 → 20.77 | 3/0/0 → 0/0/0 |
| Warehouse B | 12.01 → 9.44 | 11.46 → 9.24 | 15.92 → 11.34 | 20.19 → 12.82 | 35.58 → 17.17 | 1/0/0 → 0/0/0 |
| Locomotive cab | 12.24 → 12.60 | 11.85 → 11.97 | 16.21 → 17.25 | 21.14 → 21.95 | 31.70 → 29.32 | 0/0/0 → 0/0/0 |
| Passenger car | 13.26 → 14.86 | 13.00 → 14.35 | 16.32 → 20.08 | 20.36 → 24.41 | 32.45 → 32.33 | 0/0/0 → 0/0/0 |
| Curved railway | 10.07 → 9.45 | 9.42 → 8.70 | 13.84 → 14.71 | 18.98 → 19.07 | 41.12 → 36.28 | 1/0/0 → 1/0/0 |
| Ashford Depot | 8.83 → 8.33 | 8.37 → 7.56 | 12.05 → 14.16 | 16.60 → 19.65 | 28.36 → 35.00 | 0/0/0 → 1/0/0 |
| Ashford workshop | 10.11 → 9.63 | 9.11 → 8.93 | 14.50 → 13.24 | 20.41 → 21.83 | 107.56 → 45.82 | 5/2/1 → 1/0/0 |
| Blackwater Crossing | 9.45 → 9.31 | 8.51 → 8.47 | 14.40 → 13.78 | 22.29 → 22.47 | 41.95 → 41.88 | 3/0/0 → 6/0/0 |
| Near advancing fog | 11.07 → 10.38 | 10.32 → 9.94 | 14.79 → 13.54 | 23.05 → 17.45 | 45.17 → 23.23 | 3/0/0 → 0/0/0 |
| Inside dangerous fog | 10.33 → 10.46 | 10.00 → 9.66 | 12.96 → 15.47 | 17.66 → 20.92 | 31.53 → 42.28 | 0/0/0 → 1/0/0 |
| Mission completion | 8.13 → 8.96 | 7.98 → 8.15 | 9.82 → 14.47 | 11.83 → 24.93 | 18.29 → 44.37 | 0/0/0 → 7/0/0 |

## Medium — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 1236.95 → 86.25 | 3 → 0 |
| Warehouse A | 864.32 → 94.10 | 1 → 0 |
| Warehouse B | 15.00 → 20.37 | 0 → 0 |
| Locomotive cab | 37.10 → 31.28 | 0 → 0 |
| Passenger car | 91.15 → 83.41 | 0 → 0 |
| Curved railway | 35.32 → 57.40 | 0 → 0 |
| Ashford Depot | 27.43 → 21.84 | 0 → 0 |
| Ashford workshop | 25.83 → 21.84 | 0 → 0 |
| Blackwater Crossing | 41.62 → 26.63 | 0 → 0 |
| Near advancing fog | 162.85 → 148.23 | 1 → 1 |
| Inside dangerous fog | 14.60 → 11.80 | 0 → 0 |
| Mission completion | 81.72 → 57.81 | 0 → 0 |

## High — steady rendering

Values are baseline → candidate milliseconds. Counts pool both attempts.

| Location | Mean | Median | p95 | p99 | Worst | >33.3 / >50 / >100 ms |
|---|---:|---:|---:|---:|---:|---|
| Harlow platform | 13.54 → 11.90 | 12.90 → 11.57 | 17.22 → 14.50 | 21.29 → 16.97 | 29.97 → 26.38 | 0/0/0 → 0/0/0 |
| Warehouse A | 15.79 → 16.37 | 15.49 → 15.53 | 18.52 → 21.39 | 22.49 → 28.71 | 32.11 → 72.56 | 0/0/0 → 9/5/0 |
| Warehouse B | 14.81 → 14.01 | 14.65 → 13.73 | 17.12 → 16.52 | 19.36 → 19.47 | 28.45 → 25.92 | 0/0/0 → 0/0/0 |
| Locomotive cab | 16.07 → 15.33 | 15.91 → 15.22 | 17.94 → 16.98 | 19.94 → 18.21 | 27.24 → 23.92 | 0/0/0 → 0/0/0 |
| Passenger car | 16.66 → 15.74 | 16.49 → 15.46 | 18.52 → 17.86 | 20.59 → 20.30 | 43.27 → 36.69 | 1/0/0 → 1/0/0 |
| Curved railway | 11.90 → 10.28 | 11.43 → 10.29 | 15.20 → 12.88 | 22.68 → 17.03 | 39.78 → 20.97 | 2/0/0 → 0/0/0 |
| Ashford Depot | 11.01 → 8.50 | 9.91 → 8.59 | 16.34 → 10.07 | 26.83 → 11.66 | 83.07 → 24.40 | 8/3/0 → 0/0/0 |
| Ashford workshop | 14.48 → 9.36 | 11.62 → 9.12 | 25.59 → 11.33 | 47.28 → 14.36 | 603.40 → 21.34 | 27/11/2 → 0/0/0 |
| Blackwater Crossing | 11.75 → 9.56 | 10.45 → 9.37 | 17.20 → 12.72 | 31.79 → 15.22 | 90.96 → 20.18 | 11/3/0 → 0/0/0 |
| Near advancing fog | 13.20 → 10.39 | 12.34 → 10.32 | 17.93 → 12.41 | 26.54 → 14.54 | 52.76 → 26.96 | 6/1/0 → 0/0/0 |
| Inside dangerous fog | 12.73 → 10.49 | 12.12 → 10.09 | 16.30 → 13.95 | 24.25 → 16.64 | 32.11 → 21.90 | 0/0/0 → 0/0/0 |
| Mission completion | 12.22 → 10.17 | 10.92 → 9.87 | 19.25 → 13.80 | 28.81 → 19.56 | 91.77 → 57.02 | 9/2/0 → 2/1/0 |

## High — entry and view preparation

| Location | Worst entry, ms | Entry >100 ms |
|---|---:|---:|
| Harlow platform | 2510.91 → 81.93 | 2 → 0 |
| Warehouse A | 121.50 → 108.71 | 3 → 1 |
| Warehouse B | 21.04 → 30.16 | 0 → 0 |
| Locomotive cab | 56.16 → 62.73 | 0 → 0 |
| Passenger car | 129.64 → 110.83 | 1 → 1 |
| Curved railway | 68.02 → 46.30 | 0 → 0 |
| Ashford Depot | 38.68 → 21.30 | 0 → 0 |
| Ashford workshop | 32.72 → 23.77 | 0 → 0 |
| Blackwater Crossing | 56.98 → 43.27 | 0 → 0 |
| Near advancing fog | 81.90 → 120.22 | 0 → 2 |
| Inside dangerous fog | 32.76 → 15.23 | 0 → 0 |
| Mission completion | 48.37 → 75.88 | 0 → 0 |

## Every startup attempt

Times are seconds since engine process initialization. The first boundary combines OS/engine/driver startup and built-in shader preparation; the load boundary includes script/resources/decompression; activation includes `_ready`, geometry, physics registration and gameplay wiring. These aggregates cannot isolate every internal engine stage. Readiness follows destination-GPU preparation and physics synchronization.

| Revision / attempt | Engine to script | Script to load | Load | Instantiate | Activate | Render preparation + readiness | Total ready |
|---|---:|---:|---:|---:|---:|---:|---:|
| baseline-startup-1 | 27.398 | 1.361 | 14.002 | 0.020 | 12.804 | 45.478 | 101.063 |
| optimized-startup-1 | 6.418 | 0.162 | 3.048 | 0.021 | 1.944 | 17.013 | 28.606 |
| optimized-startup-2 | 5.346 | 0.139 | 2.472 | 0.015 | 1.663 | 14.065 | 23.700 |
| baseline-startup-2 | 5.647 | 0.157 | 1.792 | 0.011 | 11.362 | 14.002 | 32.971 |
| baseline-startup-3 | 6.004 | 0.139 | 2.100 | 0.015 | 10.280 | 12.069 | 30.607 |
| optimized-startup-3 | 4.966 | 0.134 | 2.051 | 0.013 | 1.407 | 13.020 | 21.591 |

## Process memory and failures

RSS is sampled every 0.5 seconds; it is not total GPU memory and can miss short peaks. Texture/static-memory monitors and per-location CPU timings are in the CSV. Retained frame/timeline arrays contribute to static-memory growth; identical instrumentation is used for both revisions.

| Process | Seconds to exit | Peak RSS MiB | Exit | Diagnostics |
|---|---:|---:|---:|---:|
| baseline-startup-1 | 104.20 | 492.12 | 0 | 2 |
| optimized-startup-1 | 30.97 | 526.59 | 0 | 0 |
| optimized-startup-2 | 25.43 | 505.47 | 0 | 0 |
| baseline-startup-2 | 35.10 | 498.67 | 0 | 0 |
| baseline-startup-3 | 32.03 | 499.05 | 0 | 0 |
| optimized-startup-3 | 23.64 | 506.41 | 0 | 0 |
| baseline-matrix-1 | 375.65 | 630.70 | 0 | 1 |
| optimized-matrix-1 | 334.81 | 632.19 | 0 | 0 |
| optimized-matrix-2 | 333.68 | 610.62 | 0 | 0 |
| baseline-matrix-2 | 352.20 | 627.80 | 0 | 0 |

The raw process logs retain every diagnostic and cache event. A complete JSON or zero exit does not override engine errors. Loading/preset preparation and fixture-transition times remain in the raw reports, separately from entry and steady samples. Fixtures deliberately reposition the player and freeze most simulation; the uninterrupted controls-driven recording is separate evidence.

## Worst-frame callback evidence

Twenty largest per-view worst frames from all attempts. Callback brackets are CPU elapsed intervals, including waits; they are not GPU timestamps. Full per-view records are in `worst-frames.csv`.

| Run | Preset / location / stage | Frame ms | Process ms | Physics ms | Render bracket ms |
|---|---|---:|---:|---:|---:|
| baseline-matrix-1 | High / Harlow platform / entry | 2510.907 | 0.459 | 0.000 | 2509.308 |
| baseline-matrix-2 | Medium / Harlow platform / entry | 1236.953 | 0.606 | 0.000 | 1235.729 |
| baseline-matrix-1 | Medium / Harlow platform / entry | 1021.853 | 0.556 | 0.069 | 1020.447 |
| optimized-matrix-2 | Low / Warehouse B / steady | 976.263 | 0.938 | 0.154 | 931.360 |
| baseline-matrix-1 | Medium / Warehouse A / entry | 864.316 | 0.605 | 0.386 | 861.374 |
| baseline-matrix-2 | High / Harlow platform / entry | 731.586 | 0.663 | 0.285 | 729.148 |
| baseline-matrix-2 | High / Ashford workshop / steady | 603.403 | 1.290 | 0.416 | 37.530 |
| baseline-matrix-1 | Medium / Near advancing fog / entry | 162.851 | 0.455 | 0.194 | 160.743 |
| optimized-matrix-1 | Medium / Near advancing fog / entry | 148.226 | 0.355 | 0.135 | 146.141 |
| baseline-matrix-1 | High / Passenger car / entry | 129.638 | 0.287 | 0.068 | 128.398 |
| baseline-matrix-1 | High / Warehouse A / entry | 121.501 | 4.370 | 0.185 | 115.068 |
| optimized-matrix-1 | High / Near advancing fog / entry | 120.223 | 0.177 | 0.066 | 118.551 |
| baseline-matrix-2 | High / Warehouse A / entry | 115.311 | 0.341 | 0.160 | 113.458 |
| optimized-matrix-1 | High / Passenger car / entry | 110.829 | 0.347 | 0.112 | 108.800 |
| optimized-matrix-1 | High / Warehouse A / entry | 108.706 | 0.444 | 0.464 | 105.782 |
| baseline-matrix-2 | Medium / Ashford workshop / steady | 107.558 | 0.268 | 0.089 | 86.699 |
| optimized-matrix-1 | Low / Near advancing fog / entry | 103.190 | 0.296 | 0.157 | 101.562 |
| optimized-matrix-2 | High / Near advancing fog / entry | 100.018 | 0.418 | 0.102 | 98.029 |
| optimized-matrix-2 | Medium / Warehouse A / entry | 94.104 | 0.185 | 0.134 | 92.214 |
| baseline-matrix-2 | High / Mission completion / steady | 91.765 | 0.007 | 0.003 | 91.503 |

## Matrix preparation, separate from gameplay samples

Each process constructs the scene and prepares its initial Low view before measurement. Later preset changes prepare the existing scene. All time remains reported here; moving work into preparation does not make startup free.

| Run | Scene construction ms | Initial render-ready ms from construction start | Low / Medium / High preset preparation ms |
|---|---:|---:|---|
| baseline-matrix-1 | 11234 | 25427 | 189 / 9955 / 10996 |
| optimized-matrix-1 | 3256 | 15378 | 421 / 7626 / 13436 |
| optimized-matrix-2 | 3433 | 15276 | 461 / 7455 / 11371 |
| baseline-matrix-2 | 7583 | 17227 | 180 / 4242 / 7383 |

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
