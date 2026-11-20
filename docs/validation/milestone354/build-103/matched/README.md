# Matched frame times at all 36 views

Each cell gives native Metal and Vulkan in that order. Within a renderer the two values are p99 and worst frame time, in milliseconds. Two timing passes reverse driver order and use the same pack, 960×540 window, positions, preset, fog state and disabled V-sync. Screenshot readback happens in separate processes. The underlying tables retain each threshold count, frame distribution, process memory peak, CPU time, draw calls and texture allocation.

[Global frame distributions](global.csv) · [All per-view statistics](pooled.csv) · [Per-attempt rendering counters and RSS](frames.csv) · [Attempt status and diagnostics](attempts.csv) · [Original logs, reports and 72 PNGs](../raw/metal-drivers.zip)

## Entry intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 17.7, 21.9 / 15.0, 17.5 | 17.2, 17.6 / 61.1, 67.4 | 36.0, 45.2 / 73.8, 88.5 |
| Warehouse A | 23.4, 53.9 / 41.7, 64.1 | 39.5, 135.2 / 84.7, 100.6 | 142.6, 179.7 / 114.0, 128.7 |
| Warehouse B | 14.6, 16.5 / 44.9, 53.6 | 10.9, 12.1 / 19.9, 22.0 | 17.1, 18.8 / 51.1, 54.0 |
| Locomotive cab | 35.3, 50.2 / 76.9, 86.5 | 35.8, 36.3 / 41.9, 69.2 | 49.6, 52.4 / 63.9, 64.9 |
| Passenger car | 16.7, 17.9 / 92.0, 154.3 | 22.6, 26.1 / 53.2, 114.6 | 36.1, 44.3 / 69.7, 123.8 |
| Curved railway | 27.8, 36.4 / 39.3, 44.6 | 49.3, 63.9 / 52.4, 59.9 | 42.5, 59.6 / 45.5, 49.3 |
| Ashford Depot | 10.2, 12.4 / 28.2, 34.7 | 10.7, 16.1 / 19.2, 21.0 | 17.0, 18.3 / 19.5, 22.9 |
| Ashford workshop | 10.5, 12.7 / 40.1, 41.6 | 12.3, 14.8 / 36.2, 55.0 | 14.1, 21.8 / 34.0, 38.9 |
| Blackwater Crossing | 12.4, 20.6 / 19.6, 23.4 | 20.6, 49.4 / 17.6, 35.9 | 21.9, 31.6 / 23.5, 31.0 |
| Near advancing fog | 32.0, 155.3 / 73.5, 130.2 | 50.8, 234.7 / 63.6, 155.4 | 48.1, 237.2 / 67.3, 67.8 |
| Inside dangerous fog | 12.8, 15.1 / 11.2, 17.7 | 9.5, 9.7 / 14.5, 16.7 | 10.9, 12.2 / 25.8, 28.2 |
| Mission completion | 40.8, 63.5 / 45.8, 48.1 | 40.6, 59.1 / 43.7, 58.7 | 36.1, 47.9 / 51.3, 125.0 |

## Steady intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 11.7, 14.5 / 21.5, 36.1 | 11.9, 15.5 / 31.2, 79.8 | 22.7, 26.8 / 24.1, 35.2 |
| Warehouse A | 19.7, 38.1 / 29.6, 78.4 | 16.2, 21.4 / 59.6, 87.2 | 27.8, 48.9 / 63.7, 77.8 |
| Warehouse B | 10.5, 12.4 / 93.8, 131.2 | 12.3, 14.7 / 49.0, 74.9 | 17.6, 31.8 / 50.3, 86.7 |
| Locomotive cab | 13.2, 15.1 / 79.3, 86.7 | 25.8, 45.1 / 33.8, 66.8 | 22.9, 27.3 / 23.1, 27.6 |
| Passenger car | 11.3, 14.4 / 48.9, 64.1 | 20.1, 25.6 / 34.3, 58.7 | 23.6, 49.8 / 19.8, 24.9 |
| Curved railway | 11.9, 25.2 / 40.7, 67.1 | 11.9, 14.2 / 22.5, 78.9 | 13.4, 15.1 / 22.1, 34.3 |
| Ashford Depot | 10.5, 17.0 / 39.4, 63.1 | 7.7, 8.7 / 16.1, 30.5 | 12.8, 24.5 / 20.8, 34.2 |
| Ashford workshop | 8.1, 9.2 / 58.6, 74.3 | 10.9, 11.9 / 22.1, 142.5 | 10.5, 17.3 / 22.9, 28.0 |
| Blackwater Crossing | 15.1, 58.8 / 33.2, 57.5 | 11.6, 15.4 / 26.1, 34.5 | 10.2, 12.0 / 16.7, 19.6 |
| Near advancing fog | 11.5, 15.1 / 33.7, 50.6 | 12.8, 31.7 / 19.3, 23.6 | 16.2, 17.3 / 16.8, 23.0 |
| Inside dangerous fog | 8.8, 9.6 / 24.6, 57.7 | 15.7, 18.7 / 37.7, 51.8 | 15.1, 20.9 / 33.8, 49.9 |
| Mission completion | 11.7, 14.2 / 75.7, 125.7 | 8.3, 13.5 / 17.3, 24.3 | 12.4, 13.9 / 16.5, 33.3 |
