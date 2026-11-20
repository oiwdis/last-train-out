# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.143 / 19.571 / 22.622 / 48.350 | 171.33 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.783 / 23.122 / 78.202 / 78.202 | 193.807 | — / — |
| cold low | 10 | 10 | 9 | 9 | 1 | 0 | 0 | 15.161 / 24.705 / 52.913 / 52.913 | 157.852 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 15.712 / 17.005 / 17.480 / 17.699 | 49.581 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 14.994 / 18.566 / 22.277 / 22.277 | 135.101 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 14.202 / 17.816 / 23.721 / 23.721 | 110.47 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 1.341 / 1.772 / 3.344 / 3.344 | 42.732 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 89.657 / 57.795 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 77.765 / 11.457 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
