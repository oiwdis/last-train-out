# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 12 | 12 | 8 | 0 | 0 | 14.406 / 26.183 / 82.616 / 82.616 | 146.471 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.689 / 23.255 / 75.942 / 75.942 | 141.99 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 13.376 / 20.465 / 57.796 / 57.796 | 105.108 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 14.065 / 22.206 / 24.100 / 24.693 | 110.784 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 14.184 / 18.852 / 21.221 / 21.221 | 66.207 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 13.039 / 18.312 / 22.643 / 22.643 | 102.263 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 1.096 / 2.696 / 3.718 / 3.718 | 64.323 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 145.848 / 47.044 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 88.931 / 18.293 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
