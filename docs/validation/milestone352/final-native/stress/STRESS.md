# Exported Vulkan stress: every attempt

Source `6038bfcd0f0c5427ae6c53435d2867282938f6e4`; pack SHA-256 `7950f615a9ec2a91e0a3e2ba0fd71b76732a4d8b1b5346a663494b8acd656703`.

exported runtime rendering/lifetime fixtures, not physical M1 acceptance. fresh writable app caches; baked shaders retained; OS/driver/filesystem shared.

This is a predetermined bounded series. No failed run is replaced by a retry. Process lifetime includes settling and shutdown; mission-ready time does not. RSS is sampled, not a complete GPU-memory measurement.

| Attempt | Exit | Complete | Ready seconds | Process seconds | Peak RSS MiB | Diagnostics | Device loss |
|---|---:|---|---:|---:|---:|---:|---|
| isolation-preflight | 0 | True | 2.490 | 3.904 | 514.42 | 0 | False |
| cold-1 | 0 | True | 89.107 | 92.027 | 414.45 | 0 | False |
| cold-2 | 0 | True | 35.234 | 36.924 | 477.84 | 0 | False |
| cold-3 | -5 | False | — | 27.489 | 482.27 | 5 | True |
| cold-4 | 0 | True | 37.484 | 39.879 | 419.42 | 0 | False |
| cold-5 | 0 | True | 34.265 | 37.338 | 477.47 | 0 | False |
| cold-6 | -5 | False | — | 30.971 | 480.19 | 5 | True |
| cold-7 | 0 | True | 34.627 | 37.091 | 482.84 | 0 | False |
| cold-8 | 0 | True | 26.130 | 28.243 | 478.69 | 0 | False |
| cold-9 | 0 | True | 21.875 | 23.667 | 487.14 | 0 | False |
| cold-10 | 0 | True | 22.396 | 23.968 | 483.08 | 0 | False |
| warm-seed-matrix | 0 | True | — | 76.156 | 529.08 | 0 | False |
| warm-1 | 0 | True | 20.461 | 22.022 | 479.92 | 0 | False |
| warm-2 | 0 | True | 20.188 | 21.884 | 474.17 | 0 | False |
| warm-3 | 0 | True | 20.564 | 22.328 | 480.12 | 0 | False |
| warm-4 | 0 | True | 20.243 | 21.750 | 479.17 | 0 | False |
| warm-5 | 0 | True | 19.587 | 20.930 | 473.36 | 0 | False |
| warm-6 | 0 | True | 20.194 | 21.802 | 480.48 | 0 | False |
| warm-7 | 0 | True | 18.647 | 20.466 | 479.98 | 0 | False |
| warm-8 | 0 | True | 19.536 | 20.935 | 471.81 | 0 | False |
| warm-9 | 0 | True | 19.137 | 20.481 | 479.42 | 0 | False |
| warm-10 | 0 | True | 16.466 | 17.637 | 479.16 | 0 | False |
| cycles-1 | 0 | True | — | 89.149 | 584.67 | 0 | False |
| exit-preparing-1 | 0 | True | — | 9.043 | 457.20 | 0 | False |
| station-entries-1 | 0 | True | — | 57.912 | 516.91 | 0 | False |
| cycles-2 | 0 | True | — | 85.754 | 585.59 | 0 | False |
| exit-preparing-2 | 0 | True | — | 8.600 | 456.58 | 0 | False |
| station-entries-2 | 0 | True | — | 88.689 | 514.48 | 0 | False |
| cycles-3 | 0 | True | — | 106.927 | 585.88 | 0 | False |
| exit-preparing-3 | 0 | True | — | 10.880 | 458.95 | 0 | False |
| station-entries-3 | 0 | True | — | 67.048 | 513.83 | 0 | False |

Series passed: **False**. Missing/skipped attempts remain incomplete. Detailed stages, cache inventories and check counts are in `every-attempt.csv`; raw files retain each diagnostic and frame.
