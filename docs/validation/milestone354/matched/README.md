# Matched frame times at all 36 views

Each cell gives native Metal and Vulkan in that order. Within a renderer the two values are p99 and worst frame time, in milliseconds. Two timing passes reverse driver order and use the same pack, 960×540 window, positions, preset, fog state and disabled V-sync. Screenshot readback happens in separate processes. The underlying tables retain each threshold count, frame distribution, process memory peak, CPU time, draw calls and texture allocation.

[Global frame distributions](global.csv) · [All per-view statistics](pooled.csv) · [Per-attempt rendering counters and RSS](frames.csv) · [Attempt status and diagnostics](attempts.csv) · [Original logs, reports and 72 PNGs](../raw/metal-drivers.zip)

## Entry intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 33.9, 35.4 / 32.1, 34.1 | 148.0, 151.1 / 68.4, 70.1 | 18.6, 34.8 / 57.5, 280.4 |
| Warehouse A | 143.2, 201.1 / 49.9, 52.8 | 360.7, 1083.6 / 63.8, 64.8 | 154.2, 181.7 / 156.8, 160.4 |
| Warehouse B | 34.5, 50.9 / 20.0, 26.0 | 18.2, 21.8 / 23.8, 26.1 | 22.4, 23.3 / 47.1, 48.3 |
| Locomotive cab | 170.1, 633.3 / 34.7, 40.7 | 46.8, 416.4 / 52.7, 56.8 | 30.1, 42.8 / 48.2, 52.0 |
| Passenger car | 12.0, 245.0 / 57.1, 126.6 | 128.2, 139.4 / 112.1, 131.7 | 21.3, 42.5 / 89.5, 120.8 |
| Curved railway | 19.1, 254.1 / 29.6, 30.2 | 32.1, 46.0 / 133.4, 184.8 | 53.1, 57.1 / 84.1, 85.0 |
| Ashford Depot | 12.4, 12.6 / 58.8, 62.7 | 10.7, 14.5 / 68.6, 79.4 | 24.7, 29.6 / 41.0, 50.3 |
| Ashford workshop | 10.7, 10.8 / 22.8, 29.1 | 12.3, 12.5 / 23.2, 37.4 | 27.7, 30.6 / 24.8, 40.9 |
| Blackwater Crossing | 14.0, 17.5 / 28.0, 32.6 | 10.1, 21.3 / 20.4, 23.5 | 25.8, 33.1 / 27.3, 37.3 |
| Near advancing fog | 46.7, 118.7 / 29.4, 45.9 | 67.9, 164.5 / 32.5, 66.2 | 41.6, 149.9 / 119.3, 261.2 |
| Inside dangerous fog | 8.4, 8.8 / 12.9, 14.3 | 10.9, 10.9 / 19.6, 53.1 | 15.9, 18.1 / 17.9, 18.5 |
| Mission completion | 23.8, 73.9 / 35.5, 52.9 | 79.7, 94.7 / 52.5, 146.3 | 36.9, 155.2 / 45.0, 173.6 |

## Steady intervals

| Location | Low, Metal / Vulkan | Medium, Metal / Vulkan | High, Metal / Vulkan |
|---|---:|---:|---:|
| Harlow platform | 71.7, 204.2 / 70.8, 156.3 | 40.1, 162.4 / 24.4, 46.8 | 16.9, 20.5 / 33.7, 44.4 |
| Warehouse A | 49.6, 309.4 / 32.3, 56.2 | 27.1, 131.3 / 48.1, 52.8 | 20.3, 38.1 / 77.4, 88.2 |
| Warehouse B | 17.2, 142.5 / 29.5, 70.6 | 14.6, 15.7 / 48.1, 80.0 | 24.6, 27.3 / 29.9, 47.0 |
| Locomotive cab | 127.3, 437.0 / 61.7, 78.8 | 12.2, 12.7 / 58.9, 86.5 | 34.1, 47.4 / 39.9, 56.7 |
| Passenger car | 13.8, 21.1 / 67.1, 168.3 | 15.0, 18.5 / 100.4, 122.3 | 20.5, 22.2 / 45.1, 59.9 |
| Curved railway | 8.8, 9.2 / 35.8, 45.7 | 11.9, 13.0 / 61.3, 70.0 | 20.2, 28.6 / 42.2, 72.0 |
| Ashford Depot | 8.9, 10.4 / 38.3, 54.0 | 12.1, 16.5 / 60.0, 83.7 | 14.8, 37.2 / 33.0, 74.6 |
| Ashford workshop | 13.8, 19.2 / 38.6, 78.5 | 11.8, 15.8 / 24.0, 47.9 | 20.4, 31.6 / 16.9, 30.4 |
| Blackwater Crossing | 15.2, 21.3 / 20.2, 66.5 | 8.2, 8.9 / 23.4, 64.6 | 14.4, 20.3 / 28.6, 35.3 |
| Near advancing fog | 10.3, 32.9 / 24.4, 38.9 | 10.5, 12.4 / 24.9, 46.0 | 13.8, 16.8 / 19.0, 32.2 |
| Inside dangerous fog | 7.6, 10.7 / 26.4, 36.8 | 11.0, 13.9 / 24.9, 76.1 | 21.1, 50.8 / 20.2, 23.4 |
| Mission completion | 7.6, 10.6 / 17.8, 48.2 | 13.6, 19.0 / 19.7, 47.0 | 15.6, 26.1 / 14.4, 16.8 |
