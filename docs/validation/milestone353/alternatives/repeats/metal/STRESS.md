# Experimental exported stress — forward-metal

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 22.056 / 24.617 / 29.591 / 144.937 | 111.405 | — / — |
| cold medium | 3 | 3 | 3 | 0 | 0 | 3 | 0 | 25.585 / 32.306 / 33.583 / 33.583 | 114.222 | — / — |
| cold low | 4 | 4 | 4 | 0 | 0 | 4 | 0 | 21.365 / 29.959 / 169.565 / 169.565 | 250.236 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 17.104 / 23.511 / 26.875 / 27.955 | 118.566 | — / — |
| warm medium | 3 | 3 | 3 | 0 | 0 | 3 | 0 | 17.209 / 20.213 / 22.895 / 22.895 | 46.391 | — / — |
| warm low | 4 | 4 | 4 | 0 | 0 | 4 | 0 | 15.816 / 17.057 / 23.755 / 23.755 | 144.8 | — / — |
| isolation-preflight | 2 | 2 | 2 | 2 | 0 | 0 | 0 | 2.294 / 3.920 / 5.547 / 5.547 | 58.904 | — / — |
| warm-seed-matrix | 2 | 2 | 2 | 0 | 0 | 2 | 0 | — | — | 172.677 / 46.531 |
| cycles | 3 | 3 | 3 | 0 | 0 | 3 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 0 | 0 | 3 | 0 | — | — | 191.648 / 32.355 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
