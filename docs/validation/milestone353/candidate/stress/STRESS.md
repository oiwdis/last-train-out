# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 12 | 12 | 8 | 0 | 0 | 23.461 / 29.252 / 77.058 / 77.058 | 169.121 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 18.842 / 25.402 / 67.719 / 67.719 | 158.3 | — / — |
| cold low | 10 | 10 | 9 | 9 | 1 | 0 | 0 | 18.292 / 21.659 / 79.312 / 79.312 | 130.436 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 19.093 / 21.078 / 23.371 / 24.886 | 100.833 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.412 / 17.076 / 21.253 / 21.253 | 114.025 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 14.781 / 17.380 / 22.888 / 22.888 | 83.493 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.577 / 2.729 / 3.153 / 3.153 | 36.595 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 177.084 / 41.669 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 137.214 / 40.078 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
