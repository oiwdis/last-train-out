# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 19.128 / 20.619 / 34.459 / 94.275 | 111.058 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 13.543 / 14.896 / 53.154 / 53.154 | 62.047 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 12.705 / 16.200 / 92.587 / 92.587 | 198.556 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.046 / 16.592 / 19.993 / 25.021 | 82.191 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 12.956 / 13.590 / 18.591 / 18.591 | 105.802 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 12.395 / 12.697 / 19.476 / 19.476 | 123.739 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 1.290 / 2.055 / 2.198 / 2.198 | 36.806 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 842.012 / 773.624 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 173.037 / 32.375 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
