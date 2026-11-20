# Experimental exported stress — mobile-vulkan

Each hosted ARM runner used the universal development ZIP and its original PCK. Completed means the process produced a valid report on the requested backend and exited successfully. Clean additionally requires zero engine diagnostics, including severity markers embedded mid-line. Timings include completed launches. Every failed or skipped process stays in the CSV. The first-frame column gives the worst of the 30 intervals recorded after readiness across the group.

| Group | Scheduled | Started | Completed | Clean | Device losses | Other strict failures | Skipped | Ready min / median / p95 / max (s) | Worst first frames (ms) | Worst matrix entry / steady (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---:|---|
| cold high | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 14.150 / 16.678 / 17.370 / 17.370 | 68.293 | — / — |
| cold medium | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 13.833 / 19.917 / 24.293 / 24.293 | 95.442 | — / — |
| cold low | 4 | 4 | 4 | 4 | 0 | 0 | 0 | 17.850 / 20.998 / 59.586 / 59.586 | 90.028 | — / — |
| warm high | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 12.735 / 13.131 / 13.348 / 13.348 | 63.77 | — / — |
| warm medium | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 13.203 / 13.847 / 14.145 / 14.145 | 62.112 | — / — |
| warm low | 4 | 4 | 4 | 4 | 0 | 0 | 0 | 11.839 / 12.700 / 12.961 / 12.961 | 61.146 | — / — |
| isolation-preflight | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 2.996 / 2.996 / 2.996 / 2.996 | 71.121 | — / — |
| warm-seed-matrix | 1 | 1 | 1 | 1 | 0 | 0 | 0 | — | — | 706.836 / 28.141 |
| cycles | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| exit-preparing | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | — / — |
| station-entries | 3 | 3 | 3 | 3 | 0 | 0 | 0 | — | — | 729.391 / 14.582 |

[Every process, startup stage, resident-memory peak and measured worst frame](every-process.csv)
