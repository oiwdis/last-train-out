# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 19.554 / 22.025 / 29.667 / 114.683 | 127.219 | — / — |
| cold medium | 10 | 10 | 10 | 0 | 0 | 10 | 0 | 18.123 / 20.806 / 122.811 / 122.811 | 109.693 | — / — |
| cold low | 10 | 10 | 10 | 0 | 0 | 10 | 0 | 18.648 / 21.091 / 126.599 / 126.599 | 103.309 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.324 / 16.755 / 20.265 / 25.005 | 96.794 | — / — |
| warm medium | 10 | 10 | 10 | 0 | 0 | 10 | 0 | 14.215 / 16.523 / 18.474 / 18.474 | 129.904 | — / — |
| warm low | 10 | 10 | 10 | 0 | 0 | 10 | 0 | 13.411 / 15.492 / 22.076 / 22.076 | 151.805 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.622 / 2.974 / 3.589 / 3.589 | 79.541 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 0 | 0 | 3 | 0 | — | — | 218.034 / 50.875 |
| cycles | 3 | 3 | 3 | 0 | 0 | 3 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 0 | 0 | 3 | 0 | — | — | 196.643 / 32.095 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
