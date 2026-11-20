# Matched frame times at all 36 views

Each cell gives native Metal and Vulkan in that order. Within a renderer the two values are p99 and worst frame time, in milliseconds. Two timing passes reverse driver order and use the same pack, 960×540 window, positions, preset, fog state and disabled V-sync. Screenshot readback happens in separate processes. The underlying tables retain each threshold count, frame distribution, process memory peak, CPU time, draw calls and texture allocation.

[Global frame distributions](global.csv) · [All per-view statistics](pooled.csv) · [Per-attempt rendering counters and RSS](frames.csv) · [Attempt status and diagnostics](attempts.csv) · [Original logs, reports and 72 PNGs](../raw/metal-drivers.zip)

## Entry intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 9.7, 23.3 / 17.4, 26.2 | 15.6, 16.8 / 57.3, 62.5 | 16.3, 18.7 / 16.8, 68.4 |
| Warehouse A | 20.9, 145.8 / 43.8, 146.1 | 190.5, 393.8 / 55.4, 77.8 | 110.6, 118.7 / 88.5, 89.6 |
| Warehouse B | 9.1, 9.1 / 16.4, 23.5 | 10.4, 10.8 / 11.3, 11.5 | 11.8, 16.0 / 17.7, 19.7 |
| Locomotive cab | 23.5, 524.4 / 42.9, 46.1 | 131.4, 304.4 / 25.2, 25.6 | 24.0, 30.1 / 41.7, 54.7 |
| Passenger car | 139.6, 272.5 / 42.5, 49.3 | 166.1, 175.3 / 39.6, 52.7 | 17.4, 23.6 / 47.4, 48.4 |
| Curved railway | 23.1, 249.3 / 24.7, 36.3 | 36.8, 50.4 / 21.3, 53.5 | 35.4, 53.1 / 37.6, 38.8 |
| Ashford Depot | 9.8, 10.7 / 26.7, 32.1 | 8.4, 9.1 / 13.0, 14.6 | 16.3, 17.1 / 12.3, 16.3 |
| Ashford workshop | 15.1, 32.0 / 6.6, 9.2 | 8.7, 21.7 / 11.4, 11.7 | 12.7, 14.8 / 19.9, 34.4 |
| Blackwater Crossing | 12.4, 17.5 / 11.0, 11.5 | 14.2, 16.1 / 14.9, 17.2 | 11.5, 15.9 / 61.8, 61.9 |
| Near advancing fog | 52.9, 144.0 / 113.3, 130.8 | 48.8, 53.1 / 36.9, 42.1 | 53.8, 59.2 / 66.5, 66.7 |
| Inside dangerous fog | 7.2, 7.7 / 7.3, 7.6 | 8.9, 10.7 / 14.6, 14.6 | 8.3, 9.2 / 40.6, 47.6 |
| Mission completion | 32.9, 84.0 / 19.0, 34.5 | 22.3, 30.6 / 20.2, 45.5 | 15.1, 26.5 / 33.0, 45.9 |

## Steady intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 17.5, 226.8 / 26.3, 43.6 | 15.8, 130.8 / 22.1, 29.3 | 18.6, 21.3 / 13.5, 15.7 |
| Warehouse A | 14.4, 137.1 / 27.0, 60.8 | 17.7, 277.6 / 12.0, 14.4 | 17.1, 26.2 / 21.1, 35.7 |
| Warehouse B | 221.4, 401.0 / 28.0, 48.4 | 9.1, 9.7 / 11.6, 12.8 | 17.4, 25.8 / 24.7, 31.7 |
| Locomotive cab | 14.0, 133.2 / 28.2, 50.0 | 11.3, 12.4 / 15.2, 36.9 | 17.6, 26.1 / 17.5, 19.5 |
| Passenger car | 45.3, 658.2 / 30.4, 32.8 | 20.0, 22.3 / 21.7, 31.6 | 15.4, 19.0 / 21.1, 23.7 |
| Curved railway | 8.4, 10.9 / 8.8, 10.1 | 8.3, 9.4 / 10.6, 11.4 | 12.7, 13.6 / 14.3, 15.4 |
| Ashford Depot | 5.8, 6.2 / 13.1, 17.7 | 7.8, 8.7 / 9.6, 10.9 | 8.0, 9.9 / 16.9, 24.8 |
| Ashford workshop | 6.6, 8.0 / 7.1, 10.3 | 7.9, 9.3 / 11.7, 14.2 | 8.1, 8.4 / 25.9, 49.1 |
| Blackwater Crossing | 9.0, 11.2 / 8.3, 26.1 | 7.2, 9.0 / 8.1, 8.4 | 8.2, 8.8 / 53.9, 85.3 |
| Near advancing fog | 13.3, 21.0 / 14.7, 17.5 | 15.2, 26.2 / 15.5, 127.4 | 9.6, 11.6 / 46.2, 62.0 |
| Inside dangerous fog | 6.1, 6.6 / 6.9, 8.7 | 8.4, 8.7 / 32.6, 115.8 | 11.0, 12.1 / 46.4, 65.2 |
| Mission completion | 14.2, 16.8 / 8.5, 8.8 | 9.2, 10.7 / 15.5, 20.8 | 8.4, 8.8 / 49.5, 61.3 |
