# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 10 | 10 | 10 | 0 | 0 | 22.130 / 26.642 / 76.970 / 76.970 | 1012.648 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 22.736 / 24.715 / 72.544 / 72.544 | 162.479 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 19.463 / 24.782 / 65.231 / 65.231 | 129.48 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 18.165 / 21.491 / 26.592 / 26.643 | 95.447 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.233 / 19.391 / 24.089 / 24.089 | 151.454 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.931 / 18.385 / 21.132 / 21.132 | 94.098 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.730 / 2.987 / 3.639 / 3.639 | 48.588 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 120.094 / 35.075 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 111.406 / 43.392 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
