# Matched frame times at all 36 views

Each cell gives native Metal and Vulkan in that order. Within a renderer the two values are p99 and worst frame time, in milliseconds. Two timing passes reverse driver order and use the same pack, 960×540 window, positions, preset, fog state and disabled V-sync. Screenshot readback happens in separate processes. The underlying tables retain each threshold count, frame distribution, process memory peak, CPU time, draw calls and texture allocation.

[Global frame distributions](global.csv) · [All per-view statistics](pooled.csv) · [Per-attempt rendering counters and RSS](frames.csv) · [Attempt status and diagnostics](attempts.csv) · [Original logs, reports and 72 PNGs](../raw/metal-drivers.zip)

## Entry intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 5.1, 5.2 / 6.2, 6.7 | 7.1, 7.2 / 11.1, 11.8 | 9.9, 13.6 / 10.8, 33.4 |
| Warehouse A | 8.3, 15.4 / 8.0, 9.6 | 11.2, 18.8 / 13.7, 14.1 | 68.9, 99.1 / 73.3, 79.8 |
| Warehouse B | 6.4, 6.8 / 7.0, 7.1 | 5.5, 5.6 / 9.9, 10.0 | 9.1, 10.7 / 14.9, 15.5 |
| Locomotive cab | 10.4, 10.5 / 8.7, 8.7 | 9.0, 9.7 / 12.5, 14.1 | 14.7, 15.3 / 12.9, 13.3 |
| Passenger car | 7.0, 7.2 / 26.0, 29.3 | 7.9, 8.9 / 30.5, 46.6 | 11.5, 12.5 / 28.4, 29.9 |
| Curved railway | 8.6, 9.2 / 9.2, 9.7 | 42.8, 44.2 / 8.1, 19.9 | 7.6, 8.2 / 8.3, 16.5 |
| Ashford Depot | 5.6, 6.0 / 6.9, 7.0 | 18.1, 19.1 / 5.6, 5.7 | 8.3, 8.8 / 6.5, 7.1 |
| Ashford workshop | 5.7, 5.8 / 5.7, 6.6 | 17.1, 31.1 / 9.3, 10.5 | 6.5, 6.9 / 6.9, 7.0 |
| Blackwater Crossing | 7.4, 7.7 / 5.5, 8.7 | 33.8, 34.1 / 6.8, 6.9 | 8.3, 8.8 / 5.7, 5.9 |
| Near advancing fog | 28.9, 29.1 / 5.8, 8.9 | 22.2, 36.4 / 10.0, 10.1 | 12.7, 41.7 / 7.3, 12.9 |
| Inside dangerous fog | 5.0, 6.1 / 5.7, 5.7 | 6.4, 6.9 / 8.2, 8.8 | 9.5, 9.8 / 7.4, 7.5 |
| Mission completion | 13.6, 15.9 / 17.1, 20.7 | 11.6, 21.1 / 21.6, 37.5 | 10.5, 12.6 / 17.1, 17.2 |

## Steady intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 6.2, 6.6 / 7.4, 11.0 | 6.9, 7.3 / 10.7, 11.9 | 9.8, 11.4 / 10.1, 11.1 |
| Warehouse A | 6.0, 7.6 / 8.2, 9.1 | 6.9, 7.1 / 11.6, 13.7 | 11.5, 13.4 / 11.4, 12.4 |
| Warehouse B | 5.2, 5.6 / 7.1, 9.5 | 5.8, 7.5 / 10.3, 12.9 | 15.4, 20.9 / 11.7, 13.0 |
| Locomotive cab | 6.1, 6.4 / 8.6, 10.2 | 8.7, 9.9 / 15.9, 21.3 | 9.3, 9.8 / 9.9, 10.8 |
| Passenger car | 6.6, 7.6 / 8.6, 9.0 | 20.0, 33.8 / 11.5, 14.2 | 9.4, 10.5 / 12.2, 13.4 |
| Curved railway | 5.0, 6.2 / 7.8, 11.1 | 38.3, 42.6 / 7.7, 9.4 | 7.1, 7.9 / 9.1, 9.8 |
| Ashford Depot | 4.8, 5.0 / 6.8, 7.4 | 16.8, 34.7 / 5.9, 6.1 | 5.9, 6.4 / 7.5, 8.2 |
| Ashford workshop | 4.5, 4.9 / 5.6, 8.0 | 15.2, 37.2 / 7.3, 9.5 | 7.1, 8.5 / 7.0, 7.1 |
| Blackwater Crossing | 4.4, 5.5 / 4.9, 5.0 | 20.0, 35.8 / 7.3, 8.0 | 7.4, 8.7 / 5.8, 6.1 |
| Near advancing fog | 4.6, 12.1 / 6.2, 6.7 | 33.6, 38.7 / 7.3, 7.4 | 8.2, 9.0 / 8.5, 8.8 |
| Inside dangerous fog | 4.5, 5.9 / 6.0, 6.1 | 7.8, 8.6 / 7.5, 8.6 | 11.3, 13.9 / 8.5, 8.8 |
| Mission completion | 4.5, 5.3 / 5.2, 5.6 | 10.4, 13.5 / 7.6, 7.8 | 9.2, 14.6 / 8.8, 11.4 |
