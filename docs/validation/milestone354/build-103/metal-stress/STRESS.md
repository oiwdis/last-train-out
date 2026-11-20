# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 17.733 / 23.709 / 31.972 / 34.537 | 130.004 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.236 / 23.195 / 34.359 / 34.359 | 177.977 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 15.191 / 23.066 / 39.781 / 39.781 | 104.743 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.048 / 20.349 / 24.175 / 28.057 | 97.364 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.107 / 20.401 / 24.371 / 24.371 | 139.717 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.312 / 19.297 / 21.023 / 21.023 | 111.838 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.435 / 2.993 / 3.678 / 3.678 | 37.135 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 122.790 / 38.942 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 128.515 / 31.398 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
