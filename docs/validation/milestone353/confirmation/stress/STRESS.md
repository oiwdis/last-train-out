# Default Vulkan release stress

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 20 | 20 | 14 | 14 | 6 | 0 | 0 | 19.312 / 23.832 / 63.513 / 63.513 | 196.999 | — / — |
| cold medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 18.143 / 23.367 / 68.573 / 68.573 | 157.061 | — / — |
| cold low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 17.346 / 22.155 / 82.426 / 82.426 | 246.45 | — / — |
| warm high | 20 | 20 | 20 | 20 | 0 | 0 | 0 | 16.341 / 18.084 / 22.040 / 25.806 | 96.556 | — / — |
| warm medium | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 16.441 / 18.054 / 21.764 / 21.764 | 112.012 | — / — |
| warm low | 10 | 10 | 10 | 10 | 0 | 0 | 0 | 16.257 / 18.928 / 21.461 / 21.461 | 108.973 | — / — |
| isolation-preflight | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 2.901 / 3.146 / 5.193 / 5.193 | 56.719 | — / — |
| warm-seed-matrix | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 185.697 / 32.781 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 112.415 / 36.060 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
