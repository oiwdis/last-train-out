# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 19.136 / 21.241 / 36.778 / 82.722 | 275.926 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.977 / 25.444 / 96.255 / 96.255 | 395.436 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.064 / 22.443 / 89.476 / 89.476 | 158.612 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 17.425 / 19.713 / 23.095 / 23.767 | 87.57 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 18.299 / 19.180 / 21.701 / 21.701 | 105.335 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 16.943 / 17.891 / 21.617 / 21.617 | 116.148 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.640 / 2.939 / 3.608 / 3.608 | 180.45 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 546.746 / 821.359 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 153.208 / 58.177 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
