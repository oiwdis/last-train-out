# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 12 | 12 | 8 | 0 | 0 | 19.444 / 23.627 / 71.633 / 71.633 | 189.143 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 16.908 / 19.411 / 58.134 / 58.134 | 188.25 | — / — |
| cold low | 10 | 10 | 9 | 9 | 1 | 0 | 0 | 16.448 / 21.727 / 108.427 / 108.427 | 232.903 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 19.050 / 22.634 / 25.215 / 25.237 | 100.789 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.862 / 16.191 / 25.091 / 25.091 | 66.352 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.080 / 16.706 / 24.804 / 24.804 | 58.621 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 1.663 / 2.474 / 3.546 / 3.546 | 96.718 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 195.750 / 85.958 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 153.439 / 100.840 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
